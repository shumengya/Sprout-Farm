import socket
import threading
import json
import time
import sys
import logging
import colorama
from datetime import datetime

# 初始化colorama以支持跨平台彩色终端输出
colorama.init()

# 自定义日志格式化器，带有颜色和分类
class MinecraftStyleFormatter(logging.Formatter):
    """Minecraft风格的日志格式化器，带有颜色和分类"""
    
    # ANSI颜色代码
    COLORS = {
        'RESET': colorama.Fore.RESET,
        'BLACK': colorama.Fore.BLACK,
        'RED': colorama.Fore.RED,
        'GREEN': colorama.Fore.GREEN,
        'YELLOW': colorama.Fore.YELLOW,
        'BLUE': colorama.Fore.BLUE,
        'MAGENTA': colorama.Fore.MAGENTA,
        'CYAN': colorama.Fore.CYAN,
        'WHITE': colorama.Fore.WHITE,
        'BRIGHT_BLACK': colorama.Fore.LIGHTBLACK_EX,
        'BRIGHT_RED': colorama.Fore.LIGHTRED_EX,
        'BRIGHT_GREEN': colorama.Fore.LIGHTGREEN_EX,
        'BRIGHT_YELLOW': colorama.Fore.LIGHTYELLOW_EX,
        'BRIGHT_BLUE': colorama.Fore.LIGHTBLUE_EX,
        'BRIGHT_MAGENTA': colorama.Fore.LIGHTMAGENTA_EX,
        'BRIGHT_CYAN': colorama.Fore.LIGHTCYAN_EX,
        'BRIGHT_WHITE': colorama.Fore.LIGHTWHITE_EX,
    }
    
    # 日志级别颜色（类似于Minecraft）
    LEVEL_COLORS = {
        'DEBUG': COLORS['BRIGHT_BLACK'],
        'INFO': COLORS['WHITE'],
        'WARNING': COLORS['YELLOW'],
        'ERROR': COLORS['RED'],
        'CRITICAL': COLORS['BRIGHT_RED'],
    }
    
    # 类别及其颜色
    CATEGORIES = {
        'SERVER': COLORS['BRIGHT_CYAN'],
        'NETWORK': COLORS['BRIGHT_GREEN'],
        'CLIENT': COLORS['BRIGHT_YELLOW'],
        'SYSTEM': COLORS['BRIGHT_MAGENTA'],
    }
    
    def format(self, record):
        # 获取日志级别颜色
        level_color = self.LEVEL_COLORS.get(record.levelname, self.COLORS['WHITE'])
        
        # 从记录名称中确定类别，默认为SERVER
        category_name = getattr(record, 'category', 'SERVER')
        category_color = self.CATEGORIES.get(category_name, self.COLORS['WHITE'])
        
        # 格式化时间戳，类似于Minecraft：[HH:MM:SS]
        timestamp = datetime.now().strftime('%H:%M:%S')
        
        # 格式化消息
        formatted_message = f"{self.COLORS['BRIGHT_BLACK']}[{timestamp}] {category_color}[{category_name}] {level_color}{record.levelname}: {record.getMessage()}{self.COLORS['RESET']}"
        
        return formatted_message


class TCPServer:
    def __init__(self, host='127.0.0.1', port=9000, buffer_size=4096):
        """初始化TCP服务器"""
        self.host = host
        self.port = port
        self.buffer_size = buffer_size
        self.socket = None
        self.clients = {}  # 存储客户端连接 {client_id: (socket, address)}
        self.running = False
        self.client_buffers = {}  # 每个客户端的消息缓冲区
        
        # 配置日志
        self._setup_logging()
        
    def _setup_logging(self):
        """设置Minecraft风格的日志系统"""
        # 创建日志器
        self.logger = logging.getLogger('TCPServer')
        self.logger.setLevel(logging.INFO)
        
        # 清除任何现有的处理器
        if self.logger.handlers:
            self.logger.handlers.clear()
        
        # 创建控制台处理器
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        
        # 设置格式化器
        formatter = MinecraftStyleFormatter()
        console_handler.setFormatter(formatter)
        
        # 添加处理器到日志器
        self.logger.addHandler(console_handler)
    
    def log(self, level, message, category='SERVER'):
        """使用指定的分类和级别记录日志"""
        record = logging.LogRecord(
            name=self.logger.name,
            level=getattr(logging, level),
            pathname='',
            lineno=0,
            msg=message,
            args=(),
            exc_info=None
        )
        record.category = category
        
        # 检查是否存在控制台输入锁，如果存在则使用锁来避免打乱命令输入
        if hasattr(self, '_console_input_lock'):
            with self._console_input_lock:
                self.logger.handle(record)
        else:
            self.logger.handle(record)
        
    def start(self):
        """启动服务器"""
        try:
            # 创建TCP套接字
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)  # 禁用Nagle算法
            
            # 绑定地址和监听
            self.socket.bind((self.host, self.port))
            self.socket.listen(5)
            
            self.running = True
            self.log('INFO', f"服务器启动，监听 {self.host}:{self.port}", 'SERVER')
            
            # 接受客户端连接的主循环
            self._accept_clients()
            
        except Exception as e:
            self.log('ERROR', f"服务器启动错误: {e}", 'SYSTEM')
            self.stop()
    
    def _accept_clients(self):
        """接受客户端连接的循环"""
        while self.running:
            try:
                # 接受新的客户端连接
                client_socket, address = self.socket.accept()
                client_id = f"{address[0]}:{address[1]}"
                
                self.log('INFO', f"新客户端连接: {client_id}", 'NETWORK')
                
                # 存储客户端信息
                self.clients[client_id] = (client_socket, address)
                self.client_buffers[client_id] = ""
                
                # 创建处理线程
                client_thread = threading.Thread(
                    target=self._handle_client,
                    args=(client_id,)
                )
                client_thread.daemon = True
                client_thread.start()
                
                # 通知客户端连接成功
                self.send_data(client_id, {"type": "connection_status", "status": "connected"})
                
            except KeyboardInterrupt:
                self.log('INFO', "收到中断信号，服务器停止中...", 'SYSTEM')
                break
            except Exception as e:
                self.log('ERROR', f"接受连接时出错: {e}", 'NETWORK')
                time.sleep(1)  # 避免CPU过度使用
    
    def _handle_client(self, client_id):
        """处理客户端消息的线程"""
        client_socket, _ = self.clients.get(client_id, (None, None))
        if not client_socket:
            return
        
        # 设置超时，用于定期检查连接状态
        client_socket.settimeout(30)
        
        while self.running and client_id in self.clients:
            try:
                # 接收数据
                data = client_socket.recv(self.buffer_size)
                
                if not data:
                    # 客户端断开连接
                    self.log('INFO', f"客户端 {client_id} 断开连接", 'CLIENT')
                    self._remove_client(client_id)
                    break
                
                # 处理接收的数据
                self._process_data(client_id, data)
                
            except socket.timeout:
                # 发送保活消息
                try:
                    self.send_data(client_id, {"type": "ping"})
                except:
                    self.log('INFO', f"客户端 {client_id} 连接超时", 'CLIENT')
                    self._remove_client(client_id)
                    break
            except Exception as e:
                self.log('ERROR', f"处理客户端 {client_id} 数据时出错: {e}", 'CLIENT')
                self._remove_client(client_id)
                break
    
    def _process_data(self, client_id, data):
        """处理从客户端接收的数据"""
        # 将接收的字节添加到缓冲区
        try:
            decoded_data = data.decode('utf-8')
            self.client_buffers[client_id] += decoded_data
            
            # 处理可能包含多条JSON消息的缓冲区
            self._process_buffer(client_id)
            
        except UnicodeDecodeError as e:
            self.log('ERROR', f"解码客户端 {client_id} 数据出错: {e}", 'CLIENT')
    
    def _process_buffer(self, client_id):
        """处理客户端消息缓冲区"""
        buffer = self.client_buffers.get(client_id, "")
        
        # 按换行符分割消息
        while '\n' in buffer:
            message_end = buffer.find('\n')
            message_text = buffer[:message_end].strip()
            buffer = buffer[message_end + 1:]
            
            # 处理非空消息
            if message_text:
                try:
                    # 解析JSON消息
                    message = json.loads(message_text)
                    #self.log('INFO', f"从客户端 {client_id} 接收JSON: {message}", 'CLIENT')
                    
                    # 处理消息 - 实现自定义逻辑
                    self._handle_message(client_id, message)
                    
                except json.JSONDecodeError:
                    # 非JSON格式，作为原始文本处理
                    self.log('INFO', f"从客户端 {client_id} 接收文本: {message_text}", 'CLIENT')
                    self._handle_raw_message(client_id, message_text)
        
        # 更新缓冲区
        self.client_buffers[client_id] = buffer
    
    def _handle_message(self, client_id, message):
        """处理JSON消息 - 可被子类覆盖以实现自定义逻辑"""
        # 默认实现：简单回显
        response = {
            "type": "response",
            "original": message,
            "timestamp": time.time()
        }
        self.send_data(client_id, response)
    
    def _handle_raw_message(self, client_id, message):
        """处理原始文本消息 - 可被子类覆盖以实现自定义逻辑"""
        # 默认实现：简单回显
        response = {
            "type": "text_response",
            "content": f"收到: {message}",
            "timestamp": time.time()
        }
        self.send_data(client_id, response)
    
    def send_data(self, client_id, data):
        """向指定客户端发送JSON数据"""
        if client_id not in self.clients:
            self.log('WARNING', f"客户端 {client_id} 不存在，无法发送数据", 'NETWORK')
            return False
        
        client_socket, _ = self.clients[client_id]
        
        try:
            # 转换为JSON字符串，添加换行符
            if isinstance(data, (dict, list)):
                message = json.dumps(data) + '\n'
            else:
                message = str(data) + '\n'
            
            # 发送数据
            client_socket.sendall(message.encode('utf-8'))
            return True
        except Exception as e:
            self.log('ERROR', f"向客户端 {client_id} 发送数据时出错: {e}", 'NETWORK')
            self._remove_client(client_id)
            return False
    
    def broadcast(self, data, exclude=None):
        """向所有客户端广播消息，可选排除特定客户端"""
        exclude = exclude or []
        for client_id in list(self.clients.keys()):
            if client_id not in exclude:
                self.send_data(client_id, data)
    
    def _remove_client(self, client_id):
        """断开并移除客户端连接"""
        if client_id in self.clients:
            client_socket, _ = self.clients[client_id]
            try:
                client_socket.close()
            except:
                pass
            
            del self.clients[client_id]
            if client_id in self.client_buffers:
                del self.client_buffers[client_id]
            
            self.log('INFO', f"客户端 {client_id} 已移除", 'CLIENT')
    
    def stop(self):
        """停止服务器"""
        self.running = False
        
        # 关闭所有客户端连接
        for client_id in list(self.clients.keys()):
            self._remove_client(client_id)
        
        # 关闭服务器套接字
        if self.socket:
            try:
                self.socket.close()
            except:
                pass
            
        self.log('INFO', "服务器已停止", 'SERVER')


# 使用示例
if __name__ == "__main__":
    try:
        # 创建并启动服务器
        server = TCPServer()
        
        # 以阻塞方式启动服务器
        server_thread = threading.Thread(target=server.start)
        server_thread.daemon = True
        server_thread.start()
        
        # 运行直到按Ctrl+C
        print("服务器运行中，按Ctrl+C停止...")
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n程序被用户中断")
        if 'server' in locals():
            server.stop()
        sys.exit(0)