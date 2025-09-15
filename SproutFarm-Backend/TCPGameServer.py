from TCPServer import TCPServer

import time
import json
import os
import glob
import threading
import datetime
import re
import random
#导入服务器外置插件模块
from SMYMongoDBAPI import SMYMongoDBAPI #导入MongoDB数据库模块
from QQEmailSendAPI import EmailVerification#导入QQ邮箱发送模块
from ConsoleCommandsAPI import ConsoleCommandsAPI #导入控制台命令API模块
from SpecialFarm import SpecialFarmManager #导入特殊农场管理系统
from WSRemoteCmdApi import WSRemoteCmdApi #导入WebSocket远程命令API

"""
萌芽农场TCP游戏服务器
====================================================================
- 协议：TCP长连接
- 数据格式：JSON消息
- 消息类型：请求/响应模式
====================================================================
"""
server_host: str = "0.0.0.0"
server_port: int = 7070
buffer_size: int = 4096
server_version: str = "2.2.0"

class TCPGameServer(TCPServer):

    """
    萌芽农场TCP游戏服务器
    """
    
#==========================初始化和生命周期管理==========================
    #初始化操作
    def __init__(self, server_host=server_host, server_port=server_port, buffer_size=buffer_size):
        """初始化TCP游戏服务器"""
        super().__init__(server_host, server_port, buffer_size)
        
        # 基础数据存储
        self.user_data = {}  # 存储用户相关数据
        self.crop_timer = None  # 作物生长计时器
        self.weed_timer = None  # 杂草生长计时器
        
        # 配置文件目录
        self.config_dir = "config"  # 配置文件存储目录
        
        # 初始化MongoDB API（优先使用MongoDB，失败则使用JSON文件）
        self._init_mongodb_api()
        
        # 初始化杂草系统配置
        self._init_weed_settings()
        
        # 禁用父类的日志输出，避免重复
        self._setup_game_server_logging()
        
        # 数据缓存
        self.crop_data_cache = None
        self.crop_data_cache_time = 0
        self.cache_expire_duration = 300  # 缓存过期时间5分钟
        
        # 偷菜免被发现临时计数器 {玩家名: {目标玩家名: 剩余免被发现次数}}
        self.steal_immunity_counters = {}
        
        self.log('INFO', f"萌芽农场TCP游戏服务器初始化完成 - 版本: {server_version}", 'SERVER')
        
        # 清理配置缓存，确保使用最新的配置数据
        self._clear_config_cache()
        
        # 初始化特殊农场管理系统
        self._init_special_farm_manager()
        
        # 初始化WebSocket远程命令API
        self._init_websocket_remote_api()
        
        # 启动定时器
        self.start_crop_growth_timer()
        self.start_weed_growth_timer()
        self.start_wisdom_tree_health_decay_timer()
        self.start_verification_code_cleanup_timer()
        self.start_offline_crop_update_timer()
    
    #初始化MongoDB API
    def _init_mongodb_api(self):
        """初始化MongoDB API连接"""
        try:
            # 根据配置决定使用测试环境还是生产环境
            # 检查是否在Docker容器中或生产环境
            import os
            if os.path.exists('/.dockerenv') or os.environ.get('PRODUCTION', '').lower() == 'true':
                environment = "production"
            else:
                environment = "test"
            
            # 保存环境信息供其他组件使用
            self.environment = environment
            
            self.mongo_api = SMYMongoDBAPI(environment)
            if self.mongo_api.is_connected():
                self.use_mongodb = True
                self.log('INFO', f"MongoDB API初始化成功 [{environment}]", 'SERVER')
            else:
                self.use_mongodb = False
                self.mongo_api = None
                self.log('WARNING', "MongoDB连接失败，将使用JSON配置文件", 'SERVER')
                
        except Exception as e:
            self.use_mongodb = False
            self.mongo_api = None
            self.log('ERROR', f"MongoDB API初始化异常: {e}，将使用JSON配置文件", 'SERVER')
    
    #初始化杂草系统配置
    def _init_weed_settings(self):
        """初始化杂草生长配置"""
        # 杂草生长相关配置
        self.weed_check_interval = 86400  # 杂草检查间隔（24小时）
        self.offline_threshold_days = 3  # 离线多少天后开始长杂草
        self.max_weeds_per_check = 3  # 每次检查时最多长多少个杂草
        self.weed_growth_probability = 0.3  # 每个空地长杂草的概率（30%）
        self.last_weed_check_time = time.time()  # 上次检查杂草的时间
    
    #初始化特殊农场管理系统
    def _init_special_farm_manager(self):
        """初始化特殊农场管理系统"""
        try:
            # 使用自动环境检测，确保与游戏服务器环境一致
            self.special_farm_manager = SpecialFarmManager()
            
            # 启动特殊农场定时任务
            self.special_farm_manager.start_scheduler()
            
            self.log('INFO', f"特殊农场管理系统初始化完成 - 环境: {self.special_farm_manager.environment}", 'SERVER')
            
        except Exception as e:
            self.log('ERROR', f"特殊农场管理系统初始化失败: {str(e)}", 'SERVER')
            self.special_farm_manager = None
    
    #初始化WebSocket远程命令API
    def _init_websocket_remote_api(self):
        """初始化WebSocket远程命令API服务器"""
        try:
            # 创建WebSocket远程命令API实例
            ws_host = "0.0.0.0"
            ws_port = 7071
            auth_key = "mengya2024"  # 可以从配置文件读取
            
            self.ws_remote_api = WSRemoteCmdApi(
                game_server=self,
                host=ws_host,
                port=ws_port,
                auth_key=auth_key
            )
            
            # 启动WebSocket服务器
            self.ws_remote_api.start_server()
            
            self.log('INFO', f"WebSocket远程命令API初始化完成 - ws://{ws_host}:{ws_port}", 'SERVER')
            
        except Exception as e:
            self.log('ERROR', f"WebSocket远程命令API初始化失败: {str(e)}", 'SERVER')
            self.ws_remote_api = None
    
    #设置游戏服务器日志配置
    def _setup_game_server_logging(self):
        """设置游戏服务器日志配置，禁用父类重复输出"""
        # 禁用父类logger的传播，避免重复输出
        if hasattr(self, 'logger') and self.logger:
            self.logger.propagate = False
    
    #启动作物生长计时器
    def start_crop_growth_timer(self):
        """启动作物生长计时器，每秒更新一次"""
        try:
            self.update_crops_growth()
        except Exception as e:
            self.log('ERROR', f"作物生长更新时出错: {str(e)}", 'SERVER')
        
        # 创建下一个计时器
        self.crop_timer = threading.Timer(1.0, self.start_crop_growth_timer)
        self.crop_timer.daemon = True
        self.crop_timer.start()
    
    #启动杂草生长计时器
    def start_weed_growth_timer(self):
        """启动杂草生长计时器，每天检查一次"""
        try:
            current_time = time.time()
            # 检查是否到了杂草检查时间
            if current_time - self.last_weed_check_time >= self.weed_check_interval:
                self.check_and_grow_weeds()
                self.last_weed_check_time = current_time
        except Exception as e:
            self.log('ERROR', f"杂草生长检查时出错: {str(e)}", 'SERVER')
        
        # 创建下一个杂草检查计时器（每小时检查一次是否到时间）
        self.weed_timer = threading.Timer(3600, self.start_weed_growth_timer)  # 每小时检查一次
        self.weed_timer.daemon = True
        self.weed_timer.start()
    
    def start_wisdom_tree_health_decay_timer(self):
        """启动智慧树生命值衰减定时器"""
        try:
            self.check_wisdom_tree_health_decay()
        except Exception as e:
            self.log('ERROR', f"智慧树生命值衰减检查时出错: {str(e)}", 'SERVER')
        
        # 创建下一个智慧树衰减检查计时器（每天检查一次）
        self.wisdom_tree_decay_timer = threading.Timer(86400, self.start_wisdom_tree_health_decay_timer)  # 每24小时检查一次
        self.wisdom_tree_decay_timer.daemon = True
        self.wisdom_tree_decay_timer.start()
    
    def start_verification_code_cleanup_timer(self):
        """启动验证码清理定时器"""
        try:

            EmailVerification.clean_expired_codes()
            self.log('INFO', "验证码清理完成", 'SERVER')
        except Exception as e:
            self.log('ERROR', f"验证码清理时出错: {str(e)}", 'SERVER')
        
        # 创建下一个验证码清理计时器（每30分钟检查一次）
        self.verification_cleanup_timer = threading.Timer(1800, self.start_verification_code_cleanup_timer)  # 每30分钟清理一次
        self.verification_cleanup_timer.daemon = True
        self.verification_cleanup_timer.start()
    
    def start_offline_crop_update_timer(self):
        """启动离线玩家作物更新定时器"""
        try:
            self.update_offline_players_crops()
        except Exception as e:
            self.log('ERROR', f"离线玩家作物更新时出错: {str(e)}", 'SERVER')
        
        # 创建下一个离线作物更新计时器（每1分钟检查一次）
        self.offline_crop_timer = threading.Timer(60, self.start_offline_crop_update_timer)  # 每1分钟更新一次
        self.offline_crop_timer.daemon = True
        self.offline_crop_timer.start()
    
    #获取服务器统计信息
    def get_server_stats(self):
        """获取服务器统计信息"""
        online_players = len([cid for cid in self.user_data if self.user_data[cid].get("logged_in", False)])
        return {
            "online_players": online_players,
            "total_connections": len(self.clients)
        }
    
    #停止服务器
    def stop(self):
        """停止服务器"""
        self.log('INFO', "正在停止服务器...", 'SERVER')
        
        # 停止作物生长计时器
        if self.crop_timer:
            self.crop_timer.cancel()
            self.crop_timer = None
            self.log('INFO', "作物生长计时器已停止", 'SERVER')
        
        # 停止杂草生长计时器
        if hasattr(self, 'weed_timer') and self.weed_timer:
            self.weed_timer.cancel()
            self.weed_timer = None
            self.log('INFO', "杂草生长计时器已停止", 'SERVER')
        
        # 停止智慧树生命值衰减计时器
        if hasattr(self, 'wisdom_tree_decay_timer') and self.wisdom_tree_decay_timer:
            self.wisdom_tree_decay_timer.cancel()
            self.wisdom_tree_decay_timer = None
            self.log('INFO', "智慧树生命值衰减计时器已停止", 'SERVER')
        
        # 停止验证码清理定时器
        if hasattr(self, 'verification_cleanup_timer') and self.verification_cleanup_timer:
            self.verification_cleanup_timer.cancel()
            self.verification_cleanup_timer = None
            self.log('INFO', "验证码清理定时器已停止", 'SERVER')
        
        # 停止离线作物更新定时器
        if hasattr(self, 'offline_crop_timer') and self.offline_crop_timer:
            self.offline_crop_timer.cancel()
            self.offline_crop_timer = None
            self.log('INFO', "离线作物更新定时器已停止", 'SERVER')
        
        # 停止特殊农场管理系统
        if hasattr(self, 'special_farm_manager') and self.special_farm_manager:
            try:
                # 停止特殊农场定时任务
                self.special_farm_manager.stop_scheduler()
                
                # 清理特殊农场管理器引用
                self.special_farm_manager = None
                
                self.log('INFO', "特殊农场管理系统已停止", 'SERVER')
            except Exception as e:
                self.log('ERROR', f"停止特殊农场管理系统时出错: {str(e)}", 'SERVER')
        
        # 停止WebSocket远程命令API服务器
        if hasattr(self, 'ws_remote_api') and self.ws_remote_api:
            try:
                self.ws_remote_api.stop_server()
                self.ws_remote_api = None
                self.log('INFO', "WebSocket远程命令API服务器已停止", 'SERVER')
            except Exception as e:
                self.log('ERROR', f"停止WebSocket远程命令API服务器时出错: {str(e)}", 'SERVER')
        
        # 显示服务器统计信息
        stats = self.get_server_stats()
        self.log('INFO', f"服务器统计 - 在线玩家: {stats['online_players']}, 总连接: {stats['total_connections']}", 'SERVER')
        
        # 调用父类方法完成实际停止
        super().stop()
#==========================初始化和生命周期管理==========================



#==========================客户端连接管理==========================
    #移除客户端
    def _remove_client(self, client_id):
        """覆盖客户端移除方法，添加用户离开通知和数据保存"""
        if client_id in self.clients:
            username = self.user_data.get(client_id, {}).get("username", client_id)
            
            # 处理已登录用户的离开
            if client_id in self.user_data and self.user_data[client_id].get("logged_in", False):
                self._update_player_logout_time(client_id, username)
                self.log('INFO', f"用户 {username} 登出", 'SERVER')
            
            # 清理用户数据
            if client_id in self.user_data:
                # 清理偷菜免被发现计数器
                self._clear_player_steal_immunity(username)
                del self.user_data[client_id]
                
            self.log('INFO', f"用户 {username} 已离开游戏", 'SERVER')
            
            # 先调用父类方法移除客户端，避免递归调用
            super()._remove_client(client_id)
            
            # 在客户端已移除后再广播用户离开消息，避免向已断开的客户端发送消息
            self.broadcast({
                "type": "user_left",
                "user_id": client_id,
                "timestamp": time.time(),
                "remaining_users": len(self.clients)
            })
        else:
            # 如果客户端不在列表中，直接调用父类方法
            super()._remove_client(client_id)
#==========================客户端连接管理==========================




#==========================验证和检查方法==========================
    #检查用户是否已登录的通用方法
    def _check_user_logged_in(self, client_id, action_name, action_type=None):
        """检查用户是否已登录的通用方法"""
        if client_id not in self.user_data or not self.user_data[client_id].get("logged_in", False):
            self.log('WARNING', f"未登录用户 {client_id} 尝试{action_name}", 'SERVER')
            
            response = {
                "success": False,
                "message": "您需要先登录才能执行此操作"
            }
            
            if action_type:
                response["type"] = "action_response"
                response["action_type"] = action_type
            else:
                response["type"] = f"{action_name}_response"
            
            return False, response
        
        return True, None
    
#==========================验证和检查方法==========================



#=================================数据管理方法====================================
    #加载玩家数据
    def load_player_data(self, account_id):
        """从MongoDB加载玩家数据"""
        try:
            if not self.use_mongodb or not self.mongo_api:
                self.log('ERROR', 'MongoDB未配置或不可用，无法加载玩家数据', 'SERVER')
                return None
                
            player_data = self.mongo_api.get_player_data(account_id)
            if player_data:
                return player_data
            else:
                self.log('DEBUG', f"MongoDB中未找到玩家 {account_id} 的数据", 'SERVER')
                return None
            
        except Exception as e:
            self.log('ERROR', f"读取玩家 {account_id} 的数据时出错: {str(e)}", 'SERVER')
            return None
    
    #保存玩家数据
    def save_player_data(self, account_id, player_data):
        """保存玩家数据到MongoDB"""
        try:
            if not self.use_mongodb or not self.mongo_api:
                self.log('ERROR', 'MongoDB未配置或不可用，无法保存玩家数据', 'SERVER')
                return False
                
            success = self.mongo_api.save_player_data(account_id, player_data)
            if success:
                return True
            else:
                self.log('ERROR', f"MongoDB保存失败: {account_id}", 'SERVER')
                return False
            
        except Exception as e:
            self.log('ERROR', f"保存玩家 {account_id} 的数据时出错: {str(e)}", 'SERVER')
            return False
        
    #加载玩家数据
    def _load_player_data_with_check(self, client_id, action_type=None):
        """加载玩家数据并进行错误检查的通用方法"""
        username = self.user_data[client_id]["username"]
        player_data = self.load_player_data(username)
        
        if not player_data:
            self.log('ERROR', f"无法加载玩家 {username} 的数据", 'SERVER')
            
            response = {
                "success": False,
                "message": "无法加载玩家数据"
            }
            
            if action_type:
                response["type"] = "action_response"
                response["action_type"] = action_type
            else:
                response["type"] = "data_response"
            
            return None, username, response
        
        return player_data, username, None
    
    #加载作物配置数据（优化版本）
    def _clear_config_cache(self):
        """清理配置缓存，强制重新加载"""
        self.crop_data_cache = None
        self.crop_data_cache_time = 0
        self.log('INFO', "配置缓存已清理", 'SERVER')
    
    def _load_crop_data(self):
        """加载作物配置数据（从MongoDB，带缓存优化）"""
        current_time = time.time()
        
        # 检查缓存是否有效
        if (self.crop_data_cache is not None and 
            current_time - self.crop_data_cache_time < self.cache_expire_duration):
            return self.crop_data_cache
        
        # 缓存过期或不存在，重新加载
        if not self.use_mongodb or not self.mongo_api:
            self.log('ERROR', 'MongoDB未配置或不可用，无法加载作物配置数据', 'SERVER')
            return {}
            
        try:
            crop_data = self.mongo_api.get_crop_data_config()
            if crop_data:
                self.crop_data_cache = crop_data
                self.crop_data_cache_time = current_time
                self.log('INFO', "成功从MongoDB加载作物数据配置", 'SERVER')
                return self.crop_data_cache
            else:
                self.log('ERROR', "MongoDB中未找到作物数据配置", 'SERVER')
                return {}
        except Exception as e:
            self.log('ERROR', f"从MongoDB加载作物数据失败: {str(e)}", 'SERVER')
            return {}
    
    #更新玩家登录时间
    def _update_player_logout_time(self, client_id, username):
        """更新玩家登出时间和总游玩时间"""
        login_timestamp = self.user_data[client_id].get("login_timestamp", time.time())
        play_time_seconds = int(time.time() - login_timestamp)
        
        # 清除访问状态
        self.user_data[client_id]["visiting_mode"] = False
        self.user_data[client_id]["visiting_target"] = ""
        
        # 加载和更新玩家数据
        player_data = self.load_player_data(username)
        if player_data:
            # 更新总游玩时间
            self._update_total_play_time(player_data, play_time_seconds)
            
            # 注意：在线礼包时间累计现在由新系统管理，此处不再需要更新旧格式
            
            self.save_player_data(username, player_data)
            self.log('INFO', f"用户 {username} 本次游玩时间: {play_time_seconds} 秒，总游玩时间: {player_data['总游玩时间']}", 'SERVER')
    
    #更新总游玩时间
    def _update_total_play_time(self, player_data, play_time_seconds):
        """更新总游玩时间"""
        total_time_str = player_data.get("总游玩时间", "0时0分0秒")
        time_parts = re.match(r"(?:(\d+)时)?(?:(\d+)分)?(?:(\d+)秒)?", total_time_str)
        
        if time_parts:
            hours = int(time_parts.group(1) or 0)
            minutes = int(time_parts.group(2) or 0)
            seconds = int(time_parts.group(3) or 0)
            
            # 计算新的总游玩时间
            total_seconds = hours * 3600 + minutes * 60 + seconds + play_time_seconds
            new_hours = total_seconds // 3600
            new_minutes = (total_seconds % 3600) // 60
            new_seconds = total_seconds % 60
            
            # 更新总游玩时间
            player_data["总游玩时间"] = f"{new_hours}时{new_minutes}分{new_seconds}秒"
    
    # 检查玩家是否享受新玩家注册奖励
    def _is_new_player_bonus_active(self, player_data):
        """检查玩家是否在新玩家奖励期内（注册后3天内享受10倍生长速度）"""
        register_time_str = player_data.get("注册时间", "")
        
        # 如果没有注册时间或者是默认的老玩家时间，则不享受奖励
        if not register_time_str or register_time_str == "2025年05月21日15时00分00秒":
            return False
        
        try:
            # 解析注册时间
            register_time = datetime.datetime.strptime(register_time_str, "%Y年%m月%d日%H时%M分%S秒")
            current_time = datetime.datetime.now()
            
            # 计算注册天数
            time_diff = current_time - register_time
            days_since_register = time_diff.total_seconds() / 86400  # 转换为天数
            
            # 3天内享受新玩家奖励
            if days_since_register <= 3:
                return True
            else:
                return False
                
        except ValueError as e:
            self.log('WARNING', f"解析注册时间格式错误: {register_time_str}, 错误: {str(e)}", 'SERVER')
            return False
    
    def update_offline_players_crops(self):
        """更新离线玩家的作物生长"""
        try:
            if not self.use_mongodb or not self.mongo_api:
                self.log('WARNING', 'MongoDB未配置或不可用，无法更新离线玩家作物', 'SERVER')
                return
            
            # 获取需要排除的玩家列表（在线玩家 + 被访问的玩家）
            exclude_players = []
            
            # 添加在线玩家
            for client_id, user_info in self.user_data.items():
                if user_info.get("logged_in", False) and user_info.get("username"):
                    exclude_players.append(user_info["username"])
            
            # 添加被访问的玩家（避免访问模式下的重复更新）
            visited_players = set()
            for client_id, user_info in self.user_data.items():
                if (user_info.get("logged_in", False) and 
                    user_info.get("visiting_mode", False) and 
                    user_info.get("visiting_target")):
                    visited_players.add(user_info["visiting_target"])
            
            # 将被访问的玩家也加入排除列表
            exclude_players.extend(list(visited_players))
            
            # 直接调用优化后的批量更新方法，传入排除玩家列表
            # 离线更新间隔为60秒，所以每次更新应该增长60秒
            updated_count = self.mongo_api.batch_update_offline_players_crops(
                growth_multiplier=60.0, 
                exclude_online_players=exclude_players
            )
            
            if updated_count > 0:
                self.log('INFO', f"成功更新了 {updated_count} 个离线玩家的作物生长（排除了 {len(exclude_players)} 个在线/被访问玩家）", 'SERVER')
            else:
                self.log('DEBUG', "没有离线玩家的作物需要更新", 'SERVER')
                
        except Exception as e:
            self.log('ERROR', f"更新离线玩家作物时出错: {str(e)}", 'SERVER')

#=================================数据管理方法====================================



#================================作物系统管理=========================================
    #作物生长更新系统
    def update_crops_growth(self):
        """更新所有玩家的作物生长"""
        # 收集所有需要更新的玩家（在线玩家 + 被访问的玩家）
        players_to_update = set()
        
        # 添加在线玩家
        for client_id, user_info in self.user_data.items():
            if user_info.get("logged_in", False) and user_info.get("username"):
                players_to_update.add(user_info.get("username"))
        
        # 添加被访问的玩家（即使他们不在线）
        for client_id, user_info in self.user_data.items():
            if user_info.get("logged_in", False) and user_info.get("visiting_mode", False):
                visiting_target = user_info.get("visiting_target", "")
                if visiting_target:
                    players_to_update.add(visiting_target)
        
        # 更新所有需要更新的玩家的作物
        for username in players_to_update:
            try:
                player_data = self.load_player_data(username)
                if not player_data:
                    continue
                
                if self.update_player_crops(player_data, username):
                    # 确保数据保存成功后才推送更新
                    if self.save_player_data(username, player_data):
                        self._push_crop_update_to_player(username, player_data)
                    else:
                        self.log('ERROR', f"保存玩家 {username} 数据失败，跳过推送更新", 'SERVER')
                    
            except Exception as e:
                self.log('ERROR', f"更新玩家 {username} 作物时出错: {str(e)}", 'SERVER')
    
    #更新单个玩家的作物
    def update_player_crops(self, player_data, account_id):
        """更新单个玩家的作物"""
        growth_updated = False
        
        for farm_lot in player_data.get("农场土地", []):
            if (farm_lot.get("crop_type") and farm_lot.get("is_planted") and 
                not farm_lot.get("is_dead") and farm_lot["grow_time"] < farm_lot["max_grow_time"]):
                
                # 计算生长速度增量（累加方式）
                growth_increase = 1  # 基础生长速度：每次更新增长1秒
                
                # 新玩家注册奖励：注册后3天内额外增加9秒（总共10倍速度）
                if self._is_new_player_bonus_active(player_data):
                    growth_increase += 9
                    
                # 土地等级影响 - 根据不同等级额外增加生长速度
                land_level = farm_lot.get("土地等级", 0)
                land_speed_bonus = {
                    0: 0,   # 默认土地：无额外加成
                    1: 1,   # 黄土地：额外+1秒（总共2倍速）
                    2: 3,   # 红土地：额外+3秒（总共4倍速）
                    3: 5,   # 紫土地：额外+5秒（总共6倍速）
                    4: 9    # 黑土地：额外+9秒（总共10倍速）
                }
                growth_increase += land_speed_bonus.get(land_level, 0)
                
                # 施肥影响 - 支持不同类型的道具施肥
                if farm_lot.get("已施肥", False) and "施肥时间" in farm_lot:
                    fertilize_time = farm_lot.get("施肥时间", 0)
                    current_time = time.time()
                    
                    # 获取施肥类型和对应的持续时间、倍数
                    fertilize_type = farm_lot.get("施肥类型", "普通施肥")
                    fertilize_duration = farm_lot.get("施肥持续时间", 600)  # 默认10分钟
                    fertilize_bonus = farm_lot.get("施肥加成", 1)  # 默认额外+1秒
                    
                    if current_time - fertilize_time <= fertilize_duration:
                        # 施肥效果仍在有效期内，累加施肥加成
                        growth_increase += fertilize_bonus
                    else:
                        # 施肥效果过期，清除施肥状态
                        farm_lot["已施肥"] = False
                        if "施肥时间" in farm_lot:
                            del farm_lot["施肥时间"]
                        if "施肥类型" in farm_lot:
                            del farm_lot["施肥类型"]
                        if "施肥倍数" in farm_lot:
                            del farm_lot["施肥倍数"]
                        if "施肥持续时间" in farm_lot:
                            del farm_lot["施肥持续时间"]
                        if "施肥加成" in farm_lot:
                            del farm_lot["施肥加成"]
                
                # 确保最小增长量为1
                if growth_increase < 1:
                    growth_increase = 1
                
                farm_lot["grow_time"] += growth_increase
                growth_updated = True
        
        return growth_updated
    
    #向在线玩家推送作物生长更新
    def _push_crop_update_to_player(self, account_id, player_data):
        """向在线玩家推送作物生长更新"""
        client_id = self._find_client_by_username(account_id)
        
        if client_id:
            visiting_mode = self.user_data[client_id].get("visiting_mode", False)
            visiting_target = self.user_data[client_id].get("visiting_target", "")
            
            if visiting_mode and visiting_target:
                self._send_visiting_update(client_id, visiting_target)
            else:
                self._send_normal_update(client_id, player_data)
        
        # 检查是否有其他玩家正在访问这个玩家的农场
        self._push_update_to_visitors(account_id, player_data)
    
    #根据用户名查找客户端ID
    def _find_client_by_username(self, username):
        """根据用户名查找客户端ID"""
        for cid, user_info in self.user_data.items():
            if user_info.get("username") == username and user_info.get("logged_in", False):
                return cid
        return None
    
    #发送访问模式的更新
    def _send_visiting_update(self, client_id, visiting_target):
        """发送访问模式的更新"""
        target_player_data = self.load_player_data(visiting_target)
        if target_player_data:
            target_client_id = self._find_client_by_username(visiting_target)
            
            update_message = {
                "type": "crop_update",
                "农场土地": target_player_data.get("农场土地", []),
                "timestamp": time.time(),
                "is_visiting": True,
                "visited_player": visiting_target,
                "target_online": target_client_id is not None
            }
            self.send_data(client_id, update_message)
    
    #发送正常模式的更新
    def _send_normal_update(self, client_id, player_data):
        """发送正常模式的更新"""
        update_message = {
            "type": "crop_update",
            "农场土地": player_data.get("农场土地", []),
            "timestamp": time.time(),
            "is_visiting": False
        }
        self.send_data(client_id, update_message)
    
    #向正在访问某个玩家农场的其他玩家推送更新
    def _push_update_to_visitors(self, target_username, target_player_data):
        """向正在访问某个玩家农场的其他玩家推送更新"""
        for visitor_client_id, visitor_info in self.user_data.items():
            if not visitor_info.get("logged_in", False):
                continue
                
            visiting_mode = visitor_info.get("visiting_mode", False)
            visiting_target = visitor_info.get("visiting_target", "")
            
            # 如果这个玩家正在访问目标玩家的农场，发送更新
            if visiting_mode and visiting_target == target_username:
                target_client_id = self._find_client_by_username(target_username)
                
                update_message = {
                    "type": "crop_update",
                    "农场土地": target_player_data.get("农场土地", []),
                    "timestamp": time.time(),
                    "is_visiting": True,
                    "visited_player": target_username,
                    "target_online": target_client_id is not None
                }
                self.send_data(visitor_client_id, update_message)
                self.log('DEBUG', f"向访问者 {visitor_info.get('username', 'unknown')} 推送 {target_username} 的农场更新", 'SERVER')
#================================作物系统管理=========================================





# =======================服务端与客户端通信注册==========================================
    #服务端与客户端通用消息处理-这个是服务端与客户端通信的核心中的核心
    def _handle_message(self, client_id, message):
        """接收客户端消息并路由到对应处理函数"""
        message_type = message.get("type", "")
        
        # 用户认证相关
        if message_type == "greeting":#默认欢迎
            return self._handle_greeting(client_id, message)
        elif message_type == "login":#玩家登录
            return self._handle_login(client_id, message)
        elif message_type == "register":#玩家注册
            return self._handle_register(client_id, message)
        elif message_type == "request_verification_code":#验证码请求
            return self._handle_verification_code_request(client_id, message)
        elif message_type == "request_forget_password_verification_code":#忘记密码验证码请求
            return self._handle_forget_password_verification_code_request(client_id, message)
        elif message_type == "reset_password":#重置密码
            return self._handle_reset_password_request(client_id, message)
        elif message_type == "verify_code":#验证码
            return self._handle_verify_code(client_id, message)
        
        #---------------------------------------------------------------------------
        # 游戏操作相关 
        elif message_type == "harvest_crop":#收获作物
            return self._handle_harvest_crop(client_id, message)
        elif message_type == "plant_crop":#种植作物
            return self._handle_plant_crop(client_id, message)
        elif message_type == "buy_seed":#购买种子
            return self._handle_buy_seed(client_id, message)
        elif message_type == "buy_item":#购买道具
            return self._handle_buy_item(client_id, message)
        elif message_type == "buy_pet":#购买宠物
            return self._handle_buy_pet(client_id, message)
        elif message_type == "rename_pet":#重命名宠物
            return self._handle_rename_pet(client_id, message)
        elif message_type == "set_patrol_pet":#设置巡逻宠物
            return self._handle_set_patrol_pet(client_id, message)
        elif message_type == "set_battle_pet":#设置出战宠物
            return self._handle_set_battle_pet(client_id, message)
        elif message_type == "update_battle_pet_data":#更新宠物对战数据
            return self._handle_update_battle_pet_data(client_id, message)
        elif message_type == "feed_pet":#喂食宠物
            return self._handle_feed_pet(client_id, message)
        elif message_type == "dig_ground":#开垦土地
            return self._handle_dig_ground(client_id, message)
        elif message_type == "remove_crop":#铲除作物
            return self._handle_remove_crop(client_id, message)
        elif message_type == "water_crop":#浇水
            return self._handle_water_crop(client_id, message)
        elif message_type == "fertilize_crop":#施肥
            return self._handle_fertilize_crop(client_id, message)
        elif message_type == "use_item":#使用道具
            return self._handle_use_item(client_id, message)
        elif message_type == "upgrade_land":#升级土地
            return self._handle_upgrade_land(client_id, message)
        elif message_type == "buy_new_ground":#添加新的土地
            return self._handle_buy_new_ground(client_id, message)
        elif message_type == "like_player":#点赞玩家
            return self._handle_like_player(client_id, message)
        elif message_type == "request_online_players":#请求在线玩家
            return self._handle_online_players_request(client_id, message)
        elif message_type == "get_play_time":#获取游玩时间
            return self._handle_get_play_time(client_id)
        elif message_type == "update_play_time":#更新游玩时间
            return self._handle_update_play_time(client_id)
        elif message_type == "request_player_rankings":#请求玩家排行榜
            return self._handle_player_rankings_request(client_id, message)
        elif message_type == "request_crop_data":#请求作物数据
            return self._handle_crop_data_request(client_id)
        elif message_type == "request_item_config":#请求道具配置数据
            return self._handle_item_config_request(client_id)
        elif message_type == "request_pet_config":#请求宠物配置数据
            return self._handle_pet_config_request(client_id)
        elif message_type == "request_game_tips_config":#请求游戏小提示配置数据
            return self._handle_game_tips_config_request(client_id)
        elif message_type == "visit_player":#拜访其他玩家农场
            return self._handle_visit_player_request(client_id, message)
        elif message_type == "return_my_farm":#返回我的农场
            return self._handle_return_my_farm_request(client_id, message)
        elif message_type == "daily_check_in":#每日签到
            return self._handle_daily_check_in_request(client_id, message)
        elif message_type == "get_check_in_data":#获取签到数据
            return self._handle_get_check_in_data_request(client_id, message)
        elif message_type == "lucky_draw":#幸运抽奖
            return self._handle_lucky_draw_request(client_id, message)
        elif message_type == "claim_new_player_gift":#领取新手大礼包
            return self._handle_new_player_gift_request(client_id, message)
        elif message_type == "get_online_gift_data":#获取在线礼包数据
            return self._handle_get_online_gift_data_request(client_id, message)
        elif message_type == "claim_online_gift":#领取在线礼包
            return self._handle_claim_online_gift_request(client_id, message)
        elif message_type == "ping":#客户端ping请求
            return self._handle_ping_request(client_id, message)
        elif message_type == "modify_account_info":#修改账号信息
            return self._handle_modify_account_info_request(client_id, message)
        elif message_type == "delete_account":#删除账号
            return self._handle_delete_account_request(client_id, message)
        elif message_type == "refresh_player_info":#刷新玩家信息
            return self._handle_refresh_player_info_request(client_id, message)
        elif message_type == "global_broadcast":#全服大喇叭消息
            return self._handle_global_broadcast_message(client_id, message)
        elif message_type == "request_broadcast_history":#请求全服大喇叭历史消息
            return self._handle_request_broadcast_history(client_id, message)
        elif message_type == "use_pet_item":#宠物使用道具
            return self._handle_use_pet_item(client_id, message)
        elif message_type == "use_farm_item":#农场道具使用
            return self._handle_use_farm_item(client_id, message)
        elif message_type == "buy_scare_crow":#购买稻草人
            return self._handle_buy_scare_crow(client_id, message)
        elif message_type == "modify_scare_crow_config":#修改稻草人配置
            return self._handle_modify_scare_crow_config(client_id, message)
        elif message_type == "get_scare_crow_config":#获取稻草人配置
            return self._handle_get_scare_crow_config(client_id, message)
        elif message_type == "wisdom_tree_operation":#智慧树操作
            return self._handle_wisdom_tree_operation(client_id, message)
        elif message_type == "wisdom_tree_message":#智慧树消息
            return self._handle_wisdom_tree_message(client_id, message)
        elif message_type == "get_wisdom_tree_config":#获取智慧树配置
            return self._handle_get_wisdom_tree_config(client_id, message)
        elif message_type == "sell_crop":#出售作物
            return self._handle_sell_crop(client_id, message)
        elif message_type == "add_product_to_store":#添加商品到小卖部
            return self._handle_add_product_to_store(client_id, message)
        elif message_type == "remove_store_product":#下架小卖部商品
            return self._handle_remove_store_product(client_id, message)
        elif message_type == "buy_store_product":#购买小卖部商品
            return self._handle_buy_store_product(client_id, message)
        elif message_type == "buy_store_booth":#购买小卖部格子
            return self._handle_buy_store_booth(client_id, message)
        elif message_type == "save_game_settings":#保存游戏设置
            return self._handle_save_game_settings(client_id, message)
        elif message_type == "pet_battle_result":#宠物对战结果
            return self._handle_pet_battle_result(client_id, message)
        elif message_type == "today_divination":#今日占卜
            return self._handle_today_divination(client_id, message)
        elif message_type == "give_money":#送金币
            return self._handle_give_money_request(client_id, message)
        elif message_type == "sync_bag_data":#同步背包数据
            return self._handle_sync_bag_data(client_id, message)
        #---------------------------------------------------------------------------
        
        # 管理员操作相关
        elif message_type == "kick_player":#踢出玩家
            return self._handle_kick_player(client_id, message)

        elif message_type == "message":#处理聊天消息（暂未实现）
            return self._handle_chat_message(client_id, message)
        else:
            return super()._handle_message(client_id, message)
# =======================服务端与客户端通信注册==========================================




#==========================用户认证相关==========================
    #处理问候消息
    def _handle_greeting(self, client_id, message):
        """处理问候消息"""
        content = message.get("content", "")
        self.log('INFO', f"收到来自客户端 {client_id} 的问候: {content}", 'CLIENT')
        
        # 保存用户会话信息
        self.user_data[client_id] = {
            "last_active": time.time(),
            "messages_count": 0
        }
        
        # 回复欢迎消息
        response = {
            "type": "greeting_response",
            "content": f"欢迎 {client_id}!",
            "server_time": time.time(),
            "active_users": len(self.clients)
        }
        
        # 通知其他用户有新用户加入
        self.broadcast(
            {
                "type": "user_joined",
                "user_id": client_id,
                "timestamp": time.time(),
                "active_users": len(self.clients)
            },
            exclude=[client_id]
        )
        
        self.log('INFO', f"用户 {client_id} 已加入游戏", 'SERVER')
        return self.send_data(client_id, response)
    
    #处理玩家登录
    def _handle_login(self, client_id, message):
        """处理登录消息"""
        username = message.get("username", "")
        password = message.get("password", "")
        client_version = message.get("client_version", "")
        
        # 验证客户端版本
        version_valid, version_response = self._check_client_version(client_version, f"用户 {username} 登录")
        if not version_valid:
            version_response["type"] = "login_response"
            version_response["status"] = "failed"
            return self.send_data(client_id, version_response)
        
        # 读取玩家数据
        player_data = self.load_player_data(username)
        
        if player_data and player_data.get("玩家密码") == password:
            # 检查禁用系统
            ban_system = player_data.get("禁用系统", {})
            is_banned = ban_system.get("是否被禁止登录", False)
            
            if is_banned:
                # 检查禁止登录是否已过期
                ban_end_time = ban_system.get("禁止登录截止", "")
                if ban_end_time:
                    try:
                        end_datetime = datetime.datetime.strptime(ban_end_time, "%Y-%m-%d %H:%M:%S")
                        current_datetime = datetime.datetime.now()
                        
                        if current_datetime >= end_datetime:
                            # 禁止登录已过期，解除禁止
                            player_data["禁用系统"] = {
                                "是否被禁止登录": False,
                                "禁止登录原因": "",
                                "禁止登录开始": "",
                                "禁止登录截止": ""
                            }
                            self.save_player_data(username, player_data)
                            self.log('INFO', f"用户 {username} 禁止登录已过期，自动解除", 'SERVER')
                        else:
                            # 仍在禁止期内
                            ban_reason = ban_system.get("禁止登录原因", "您已被管理员禁止登录")
                            self.log('WARNING', f"用户 {username} 登录失败: 账号被禁止登录", 'SERVER')
                            response = {
                                "type": "login_response",
                                "status": "banned",
                                "message": ban_reason,
                                "ban_end_time": ban_end_time
                            }
                            return self.send_data(client_id, response)
                    except Exception as e:
                        self.log('ERROR', f"解析禁止登录时间出错: {e}", 'SERVER')
                        # 如果解析出错，仍然禁止登录
                        ban_reason = ban_system.get("禁止登录原因", "您已被管理员禁止登录")
                        response = {
                            "type": "login_response",
                            "status": "banned",
                            "message": ban_reason
                        }
                        return self.send_data(client_id, response)
                else:
                    # 永久禁止或没有截止时间
                    ban_reason = ban_system.get("禁止登录原因", "您已被管理员禁止登录")
                    self.log('WARNING', f"用户 {username} 登录失败: 账号被永久禁止登录", 'SERVER')
                    response = {
                        "type": "login_response",
                        "status": "banned",
                        "message": ban_reason
                    }
                    return self.send_data(client_id, response)
            
            # 登录成功
            self.log('INFO', f"用户 {username} 登录成功", 'SERVER')
            
            # 更新最后登录时间
            current_time = datetime.datetime.now()
            player_data["最后登录时间"] = current_time.strftime("%Y年%m月%d日%H时%M分%S秒")
            
            # 检查并更新体力值
            stamina_updated = self._check_and_update_stamina(player_data)
            if stamina_updated:
                stamina_system = player_data.get("体力系统", {})
                current_stamina = stamina_system.get("当前体力值", 20)
                self.log('INFO', f"玩家 {username} 体力值已更新：{current_stamina}", 'SERVER')
            
            # 检查并更新每日点赞次数
            likes_updated = self._check_and_update_daily_likes(player_data)
            if likes_updated:
                like_system = player_data.get("点赞系统", {})
                remaining_likes = like_system.get("今日剩余点赞次数", 10)
                self.log('INFO', f"玩家 {username} 每日点赞次数已重置：{remaining_likes}", 'SERVER')
            
            # 检查并清理在线礼包历史数据
            self._cleanup_online_gift_history(player_data)
            
            # 检查并清理新手礼包历史数据
            self._cleanup_new_player_gift_history(player_data)
            
            # 检查并清理体力系统历史数据
            self._cleanup_stamina_system_history(player_data)
            
            # 检查并更新已存在玩家的注册时间
            self._check_and_update_register_time(player_data, username)
            
            # 检查并修复智慧树配置
            self._check_and_fix_wisdom_tree_config(player_data, username)
            
            # 注意：在线礼包数据已改为中文系统管理，不再需要初始化英文格式数据
            
            # 保存用户会话信息
            self.user_data[client_id] = {
                "username": username,
                "last_active": time.time(),
                "messages_count": 0,
                "logged_in": True,
                "login_timestamp": time.time()
            }
            
            # 保存更新后的玩家数据
            self.save_player_data(username, player_data)
            
            # 发送初始数据
            self._send_initial_login_data(client_id, player_data)
            
            # 返回登录成功消息，转换巡逻宠物和出战宠物数据
            response_player_data = player_data.copy()
            response_player_data["巡逻宠物"] = self._convert_patrol_pets_to_full_data(player_data)
            response_player_data["出战宠物"] = self._convert_battle_pets_to_full_data(player_data)
            
            # 获取点赞系统信息
            like_system = player_data.get("点赞系统", {})
            remaining_likes = like_system.get("今日剩余点赞次数", 10)
            
            response = {
                "type": "login_response",
                "status": "success",
                "message": "登录成功",
                "player_data": response_player_data,
                "remaining_likes": remaining_likes
            }
        else:
            # 登录失败
            self.log('WARNING', f"用户 {username} 登录失败: 账号或密码错误", 'SERVER')
            response = {
                "type": "login_response",
                "status": "failed",
                "message": "账号或密码错误"
            }
            
        return self.send_data(client_id, response)
    
    #辅助函数-发送登录后初始数据
    def _send_initial_login_data(self, client_id, player_data):
        """发送登录后的初始数据"""
        # 立即向客户端发送一次作物状态
        farm_lots = player_data.get("农场土地", [])
        initial_crop_update = {
            "type": "crop_update",
            "农场土地": farm_lots,
            "timestamp": time.time()
        }
        self.send_data(client_id, initial_crop_update)
        
        # 发送最新的作物数据配置
        crop_data = self._load_crop_data()
        if crop_data:
            crop_data_message = {
                "type": "crop_data_response",
                "success": True,
                "crop_data": crop_data
            }
            self.send_data(client_id, crop_data_message)
            self.log('INFO', f"已向登录用户发送作物数据配置", 'SERVER')
        
        # 发送最新的道具配置数据
        item_config = self._load_item_config()
        if item_config:
            item_config_message = {
                "type": "item_config_response",
                "success": True,
                "item_config": item_config
            }
            self.send_data(client_id, item_config_message)
            self.log('INFO', f"已向登录用户发送道具配置数据，道具种类：{len(item_config)}", 'SERVER')
    

    #处理注册消息
    def _handle_register(self, client_id, message):
        """处理注册消息"""
        username = message.get("username", "")
        password = message.get("password", "")
        farm_name = message.get("农场名称", "")
        player_name = message.get("玩家昵称", "")
        verification_code = message.get("verification_code", "")
        client_version = message.get("client_version", "")
        
        # 验证客户端版本
        version_valid, version_response = self._check_client_version(client_version, f"用户 {username} 注册")
        if not version_valid:
            version_response["type"] = "register_response"
            version_response["status"] = "failed"
            return self.send_data(client_id, version_response)
        
        # 验证必填字段
        if not username or not password:
            return self._send_register_error(client_id, "用户名或密码不能为空")
        
        # 验证用户名是否是QQ号
        if not self._validate_qq_number(username):
            return self._send_register_error(client_id, "用户名必须是5-12位的QQ号码")
        
        # 验证验证码
        if verification_code:

            success, verify_message = EmailVerification.verify_code(username, verification_code, "register")
            if not success:
                self.log('WARNING', f"QQ号 {username} 注册验证码验证失败: {verify_message}", 'SERVER')
                return self._send_register_error(client_id, f"验证码错误: {verify_message}")
            else:
                self.log('INFO', f"QQ号 {username} 注册验证码验证成功", 'SERVER')
        
        # 检查用户是否已存在
        file_path = os.path.join("game_saves", f"{username}.json")
        if os.path.exists(file_path):
            return self._send_register_error(client_id, "该用户名已被注册")
        
        # 创建新用户
        return self._create_new_user(client_id, username, password, farm_name, player_name)
    
        #检查客户端版本是否与服务端匹配
    
        #创建新用户
   
    #辅助函数-发送注册错误处理
    def _send_register_error(self, client_id, message):
        """发送注册错误响应"""
        self.log('WARNING', f"注册失败: {message}", 'SERVER')
        return self.send_data(client_id, {
            "type": "register_response",
            "status": "failed",
            "message": message
        })
    

    #辅助函数-创建新用户
    def _create_new_user(self, client_id, username, password, farm_name, player_name):
        """创建新用户（从MongoDB加载模板）"""
        try:
            # 从MongoDB加载初始玩家数据模板
            if not self.use_mongodb or not self.mongo_api:
                return self._send_register_error(client_id, "MongoDB未配置或不可用，无法注册新用户")
                
            try:
                player_data = self.mongo_api.get_initial_player_data_template()
                if not player_data:
                    return self._send_register_error(client_id, "MongoDB中未找到初始玩家数据模板，无法注册新用户")
                self.log('INFO', "成功从MongoDB加载初始玩家数据模板", 'SERVER')
            except Exception as e:
                self.log('ERROR', f"从MongoDB加载初始玩家数据模板失败: {str(e)}", 'SERVER')
                return self._send_register_error(client_id, f"加载初始玩家数据模板失败: {str(e)}")
            
            # 更新玩家基本信息
            current_time = datetime.datetime.now()
            time_str = current_time.strftime("%Y年%m月%d日%H时%M分%S秒")
            
            player_data.update({
                "玩家账号": username,
                "玩家密码": password,
                "农场名称": farm_name or "我的农场",
                "玩家昵称": player_name or username,
                "个人简介": "",
                "最后登录时间": time_str,
                "注册时间": time_str,
                "总游玩时间": player_data.get("总游玩时间", "0时0分0秒")
            })
            
            # 确保必要字段存在
            self._ensure_player_data_fields(player_data)
            
            # 保存新用户数据到MongoDB
            if not self.save_player_data(username, player_data):
                return self._send_register_error(client_id, "保存用户数据失败，注册失败")
                
            self.log('INFO', f"用户 {username} 注册成功，注册时间: {time_str}，享受3天新玩家10倍生长速度奖励", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "register_response",
                "status": "success",
                "message": "注册成功，请登录游戏！新玩家享受3天10倍作物生长速度奖励"
            })
            
        except Exception as e:
            self.log('ERROR', f"注册用户 {username} 时出错: {str(e)}", 'SERVER')
            return self._send_register_error(client_id, f"注册过程中出现错误: {str(e)}")
    
    def _ensure_player_data_fields(self, player_data):
        """确保玩家数据包含所有必要字段"""
        # 确保农场地块存在
        if "农场土地" not in player_data:
            player_data["农场土地"] = []
            for i in range(40):
                player_data["农场土地"].append({
                    "crop_type": "",
                    "grow_time": 0,
                    "is_dead": False,
                    "is_diged": i < 20,  # 默认开垦前20块地
                    "is_planted": False,
                    "max_grow_time": 5 if i >= 20 else 3,
                    "已浇水": False,
                    "已施肥": False,
                    "土地等级": 0
                })
        
        # 确保基本仓库存在
        for field in ["种子仓库", "作物仓库", "道具背包", "宠物背包", "巡逻宠物", "出战宠物"]:
            if field not in player_data:
                player_data[field] = []
    
    #辅助函数-客户端版本检查
    def _check_client_version(self, client_version, action_name="操作"):
        """检查客户端版本是否与服务端匹配"""
        if client_version != server_version:
            self.log('WARNING', f"{action_name}失败: 版本不匹配 (客户端: {client_version}, 服务端: {server_version})", 'SERVER')
            
            response = {
                "success": False,
                "message": f"版本不匹配！客户端版本: {client_version},\n 服务端版本: {server_version}，请更新客户端"
            }
            return False, response
        
        return True, None
    
    #处理验证码请求
    def _handle_verification_code_request(self, client_id, message):
        """处理验证码请求"""
        
        qq_number = message.get("qq_number", "")
        
        # 验证QQ号
        if not self._validate_qq_number(qq_number):
            return self.send_data(client_id, {
                "type": "verification_code_response",
                "success": False,
                "message": "QQ号格式无效，请输入5-12位数字"
            })
        
        # 生成验证码
        verification_code = EmailVerification.generate_verification_code()
        
        # 发送验证码邮件
        success, send_message = EmailVerification.send_verification_email(qq_number, verification_code)
        
        if success:
            # 保存验证码（注册类型）
            EmailVerification.save_verification_code(qq_number, verification_code, 300, "register")
            self.log('INFO', f"已向QQ号 {qq_number} 发送注册验证码: {verification_code}", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "verification_code_response",
                "success": True,
                "message": "验证码已发送到您的QQ邮箱，请查收"
            })
        else:
            self.log('ERROR', f"发送验证码失败: {send_message}", 'SERVER')
            return self.send_data(client_id, {
                "type": "verification_code_response",
                "success": False,
                "message": f"发送验证码失败: {send_message}"
            })
    
    #处理验证码验证
    def _handle_verify_code(self, client_id, message):
        """处理验证码验证"""
        
        qq_number = message.get("qq_number", "")
        input_code = message.get("code", "")
        
        if not input_code:
            return self.send_data(client_id, {
                "type": "verify_code_response",
                "success": False,
                "message": "验证码不能为空"
            })
        
        # 验证验证码
        success, verify_message = EmailVerification.verify_code(qq_number, input_code)
        
        if success:
            self.log('INFO', f"QQ号 {qq_number} 的验证码验证成功", 'SERVER')
            return self.send_data(client_id, {
                "type": "verify_code_response",
                "success": True,
                "message": "验证成功"
            })
        else:
            self.log('WARNING', f"QQ号 {qq_number} 的验证码验证失败: {verify_message}", 'SERVER')
            return self.send_data(client_id, {
                "type": "verify_code_response",
                "success": False,
                "message": verify_message
            })
    
        #验证QQ号格式
    
    #处理忘记密码验证码请求
    def _handle_forget_password_verification_code_request(self, client_id, message):
        """处理忘记密码验证码请求"""
        
        qq_number = message.get("qq_number", "")
        
        # 验证QQ号
        if not self._validate_qq_number(qq_number):
            return self.send_data(client_id, {
                "type": "forget_password_verification_code_response",
                "success": False,
                "message": "QQ号格式无效，请输入5-12位数字"
            })
        
        # 检查账号是否存在
        player_data = self.load_player_data(qq_number)
        if not player_data:
            return self.send_data(client_id, {
                "type": "forget_password_verification_code_response",
                "success": False,
                "message": "该账号不存在，请检查QQ号是否正确"
            })
        
        # 生成验证码
        verification_code = EmailVerification.generate_verification_code()
        
        # 发送验证码邮件（专门用于密码重置）
        success, send_message = EmailVerification.send_verification_email(qq_number, verification_code, "reset_password")
        
        if success:
            # 保存验证码（密码重置类型）
            EmailVerification.save_verification_code(qq_number, verification_code, 300, "reset_password")
            self.log('INFO', f"已向QQ号 {qq_number} 发送密码重置验证码: {verification_code}", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "forget_password_verification_code_response",
                "success": True,
                "message": "密码重置验证码已发送到您的QQ邮箱，请查收"
            })
        else:
            self.log('ERROR', f"发送密码重置验证码失败: {send_message}", 'SERVER')
            return self.send_data(client_id, {
                "type": "forget_password_verification_code_response",
                "success": False,
                "message": f"发送验证码失败: {send_message}"
            })

    #处理重置密码请求
    def _handle_reset_password_request(self, client_id, message):
        """处理重置密码请求"""
        
        username = message.get("username", "")
        new_password = message.get("new_password", "")
        verification_code = message.get("verification_code", "")
        
        # 验证必填字段
        if not username or not new_password or not verification_code:
            return self.send_data(client_id, {
                "type": "reset_password_response",
                "success": False,
                "message": "用户名、新密码或验证码不能为空"
            })
        
        # 验证QQ号格式
        if not self._validate_qq_number(username):
            return self.send_data(client_id, {
                "type": "reset_password_response",
                "success": False,
                "message": "用户名必须是5-12位的QQ号码"
            })
        
        # 检查账号是否存在
        player_data = self.load_player_data(username)
        if not player_data:
            return self.send_data(client_id, {
                "type": "reset_password_response",
                "success": False,
                "message": "该账号不存在，请检查QQ号是否正确"
            })
        
        # 验证验证码（密码重置类型）
        success, verify_message = EmailVerification.verify_code(username, verification_code, "reset_password")
        if not success:
            self.log('WARNING', f"QQ号 {username} 密码重置验证码验证失败: {verify_message}", 'SERVER')
            return self.send_data(client_id, {
                "type": "reset_password_response",
                "success": False,
                "message": f"验证码错误: {verify_message}"
            })
        else:
            self.log('INFO', f"QQ号 {username} 密码重置验证码验证成功", 'SERVER')
        
        # 更新密码
        try:
            player_data["玩家密码"] = new_password
            
            # 保存到文件
            self.save_player_data(username, player_data)
            
            self.log('INFO', f"用户 {username} 密码重置成功", 'ACCOUNT')
            
            return self.send_data(client_id, {
                "type": "reset_password_response",
                "success": True,
                "message": "密码重置成功，请使用新密码登录"
            })
            
        except Exception as e:
            self.log('ERROR', f"重置密码时出错: {str(e)}", 'ACCOUNT')
            return self.send_data(client_id, {
                "type": "reset_password_response",
                "success": False,
                "message": "密码重置失败，请稍后重试"
            })

    #辅助函数-验证QQ号格式
    def _validate_qq_number(self, qq_number):
        """验证QQ号格式"""
        return re.match(r'^\d{5,12}$', qq_number) is not None
    
#==========================用户认证相关==========================






#==========================收获作物处理==========================
    #处理收获作物请求
    def _handle_harvest_crop(self, client_id, message):
        """处理收获作物请求（优化版本）"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "收获作物", "harvest_crop")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取当前操作用户的数据
        current_player_data, current_username, response = self._load_player_data_with_check(client_id, "harvest_crop")
        if not current_player_data:
            return self.send_data(client_id, response)
        
        lot_index = message.get("lot_index", -1)
        target_username = message.get("target_username", "")
        
        # 预加载作物配置数据（只加载一次）
        crop_data = self._load_crop_data()
        if not crop_data:
            return self._send_action_error(client_id, "harvest_crop", "无法加载作物配置数据")
        
        # 确定操作目标：如果有target_username就是访问模式（偷菜），否则是自己的农场
        if target_username and target_username != current_username:
            # 访问模式：偷菜（收益给自己，清空目标玩家的作物）
            target_player_data = self.load_player_data(target_username)
            if not target_player_data:
                return self._send_action_error(client_id, "harvest_crop", f"无法找到玩家 {target_username} 的数据")
            
            # 验证地块索引
            if lot_index < 0 or lot_index >= len(target_player_data.get("农场土地", [])):
                return self._send_action_error(client_id, "harvest_crop", "无效的地块索引")
            
            target_lot = target_player_data["农场土地"][lot_index]
            
            # 检查地块状态
            if not target_lot.get("is_planted", False) or not target_lot.get("crop_type", ""):
                return self._send_action_error(client_id, "harvest_crop", "此地块没有种植作物")
            
            if target_lot.get("is_dead", False):
                # 处理已死亡的作物（只清理，不给收益）
                target_lot["is_planted"] = False
                target_lot["crop_type"] = ""
                target_lot["grow_time"] = 0
                
                self.save_player_data(target_username, target_player_data)
                self._push_crop_update_to_player(target_username, target_player_data)
                
                return self.send_data(client_id, {
                    "type": "action_response",
                    "action_type": "harvest_crop",
                    "success": True,
                    "message": f"已帮助 {target_username} 清理死亡的作物",
                    "updated_data": {
                        "钱币": current_player_data["钱币"],
                        "经验值": current_player_data["经验值"],
                        "等级": current_player_data["等级"]
                    }
                })
            
            if target_lot["grow_time"] < target_lot["max_grow_time"]:
                return self._send_action_error(client_id, "harvest_crop", "作物尚未成熟，无法偷菜")
            
            # 处理偷菜
            return self._process_steal_crop_optimized(client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index, crop_data)
        else:
            # 正常模式：收获自己的作物
            # 验证地块索引
            if lot_index < 0 or lot_index >= len(current_player_data.get("农场土地", [])):
                return self._send_action_error(client_id, "harvest_crop", "无效的地块索引")
            
            lot = current_player_data["农场土地"][lot_index]
            
            # 检查地块状态
            if not lot.get("is_planted", False) or not lot.get("crop_type", ""):
                return self._send_action_error(client_id, "harvest_crop", "此地块没有种植作物")
            
            if lot.get("is_dead", False):
                # 处理已死亡的作物
                lot["is_planted"] = False
                lot["crop_type"] = ""
                lot["grow_time"] = 0
                
                self.save_player_data(current_username, current_player_data)
                self._push_crop_update_to_player(current_username, current_player_data)
                
                return self.send_data(client_id, {
                    "type": "action_response",
                    "action_type": "harvest_crop",
                    "success": True,
                    "message": "已铲除死亡的作物",
                    "updated_data": {
                        "钱币": current_player_data["钱币"],
                        "经验值": current_player_data["经验值"],
                        "等级": current_player_data["等级"]
                    }
                })
            
            if lot["grow_time"] < lot["max_grow_time"]:
                return self._send_action_error(client_id, "harvest_crop", "作物尚未成熟")
            
            # 处理正常收获
            return self._process_harvest_optimized(client_id, current_player_data, current_username, lot, lot_index, crop_data)

    #辅助函数-处理作物收获（优化版本）
    def _process_harvest_optimized(self, client_id, player_data, username, lot, lot_index, crop_data):
        """处理作物收获逻辑（优化版本）"""
        # 获取作物类型和基本信息
        crop_type = lot["crop_type"]
        crop_info = crop_data.get(crop_type, {})
        
        # 检查是否为杂草类型（杂草不能收获，只能铲除）
        is_weed = crop_info.get("是否杂草", False)
        if is_weed:
            return self._send_action_error(client_id, "harvest_crop", f"{crop_type}不能收获，只能铲除！请使用铲除功能清理杂草。")
        
        # 额外检查：如果作物收益为负数，也视为杂草
        crop_income = crop_info.get("收益", 100) + crop_info.get("花费", 0)
        if crop_income < 0:
            return self._send_action_error(client_id, "harvest_crop", f"{crop_type}不能收获，只能铲除！请使用铲除功能清理杂草。")
        
        # 获取作物经验
        crop_exp = crop_info.get("经验", 10)
        
        # 生成成熟物收获（1-5个）
        import random
        harvest_count = random.randint(1, 5)
        
        # 10%概率获得1-2个该作物的种子
        seed_reward = None
        if random.random() <= 0.1:
            seed_reward = {
                "name": crop_type,
                "count": random.randint(1, 2)
            }
        
        # 更新玩家经验
        player_data["经验值"] += crop_exp
        
        # 检查是否会获得成熟物
        mature_name = crop_info.get("成熟物名称")
        will_get_mature_item = mature_name is not None
        mature_item_name = mature_name if mature_name and mature_name.strip() else crop_type
        
        # 添加成熟物到作物仓库（如果允许）
        if will_get_mature_item:
            self._add_crop_to_warehouse_optimized(player_data, {"name": crop_type, "count": harvest_count}, crop_type, crop_info.get("品质", "普通"))
        
        # 添加种子奖励到背包
        if seed_reward:
            self._add_seeds_to_bag_optimized(player_data, seed_reward, crop_info.get("品质", "普通"))
        
        # 检查升级
        level_up_experience = 100 * player_data["等级"]
        if player_data["经验值"] >= level_up_experience:
            player_data["等级"] += 1
            player_data["经验值"] -= level_up_experience
            self.log('INFO', f"玩家 {username} 升级到 {player_data['等级']} 级", 'SERVER')
        
        # 清理地块（批量更新）
        lot.update({
            "is_planted": False,
            "crop_type": "",
            "grow_time": 0,
            "已浇水": False,
            "已施肥": False
        })
        
        # 清除施肥时间戳
        if "施肥时间" in lot:
            del lot["施肥时间"]
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        # 构建消息
        if will_get_mature_item:
            message = f"收获成功，获得 {mature_item_name} x{harvest_count} 和 {crop_exp} 经验"
        else:
            message = f"收获成功，获得 {crop_exp} 经验（{crop_type}无成熟物产出）"
        
        if seed_reward:
            message += f"，额外获得 {seed_reward['name']} 种子 x{seed_reward['count']}"
        
        self.log('INFO', f"玩家 {username} 从地块 {lot_index} 收获了作物，获得 {crop_type} x{harvest_count} 和 {crop_exp} 经验" + (f"，额外获得 {seed_reward['name']} 种子 x{seed_reward['count']}" if seed_reward else ""), 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "harvest_crop",
            "success": True,
            "message": message,
            "updated_data": {
                "钱币": player_data["钱币"],
                "经验值": player_data["经验值"],
                "等级": player_data["等级"],
                "种子仓库": player_data.get("种子仓库", []),
                "作物仓库": player_data.get("作物仓库", [])
            }
        })
    
    #辅助函数-处理偷菜逻辑（访问模式下收获其他玩家作物的操作）
    def _process_steal_crop_optimized(self, client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index, crop_data):
        """处理偷菜逻辑（收益给当前玩家，清空目标玩家的作物）"""
        # 偷菜体力值消耗
        stamina_cost = 1
        
        # 检查并更新当前玩家的体力值
        self._check_and_update_stamina(current_player_data)
        
        # 检查体力值是否足够
        if not self._check_stamina_sufficient(current_player_data, stamina_cost):
            return self._send_action_error(client_id, "harvest_crop", f"体力值不足，偷菜需要 {stamina_cost} 点体力，当前体力：{current_player_data.get('体力值', 0)}")
        
        # 检查是否被巡逻宠物发现（30%概率）
        patrol_pets = target_player_data.get("巡逻宠物", [])
        if patrol_pets and len(patrol_pets) > 0:
            # 先检查是否有免被发现次数
            immunity_count = self._get_steal_immunity_count(current_username, target_username)
            if immunity_count > 0:
                # 有免被发现次数，消耗一次
                self._consume_steal_immunity(current_username, target_username)
                self.log('INFO', f"玩家 {current_username} 使用免被发现次数偷菜 {target_username}，剩余次数：{immunity_count - 1}", 'SERVER')
            else:
                # 30%概率被发现
                import random
                if random.random() <= 0.3:
                    # 被巡逻宠物发现了！
                    return self._handle_steal_caught_by_patrol(
                        client_id, current_player_data, current_username, 
                        target_player_data, target_username, patrol_pets[0]
                    )
        
        # 获取作物类型和基本信息
        crop_type = target_lot["crop_type"]
        crop_info = crop_data.get(crop_type, {})
        
        # 检查是否为杂草类型（杂草不能偷取，只能铲除）
        is_weed = crop_info.get("是否杂草", False)
        if is_weed:
            return self._send_action_error(client_id, "harvest_crop", f"{crop_type}不能偷取，只能铲除！这是杂草，没有收益价值。")
        
        # 额外检查：如果作物收益为负数，也视为杂草
        crop_income = crop_info.get("收益", 100) + crop_info.get("花费", 0)
        if crop_income < 0:
            return self._send_action_error(client_id, "harvest_crop", f"{crop_type}不能偷取，只能铲除！这是杂草，没有收益价值。")
        
        # 获取作物经验（偷菜获得50%经验）
        crop_exp = int(crop_info.get("经验", 10) * 0.5)
        
        # 生成成熟物收获（偷菜获得较少，1-3个）
        import random
        harvest_count = random.randint(1, 3)
        
        # 10%概率获得1-2个该作物的种子（偷菜也有机会获得种子）
        seed_reward = None
        if random.random() <= 0.1:
            seed_reward = {
                "name": crop_type,
                "count": random.randint(1, 2)
            }
        
        # 消耗当前玩家的体力值
        stamina_success, stamina_message = self._consume_stamina(current_player_data, stamina_cost, "偷菜")
        if not stamina_success:
            return self._send_action_error(client_id, "harvest_crop", stamina_message)
        
        # 更新当前玩家数据（获得经验）
        current_player_data["经验值"] += crop_exp
        
        # 检查是否会获得成熟物
        mature_name = crop_info.get("成熟物名称")
        will_get_mature_item = mature_name is not None
        mature_item_name = mature_name if mature_name and mature_name.strip() else crop_type
        
        # 添加成熟物到作物仓库（如果允许）
        if will_get_mature_item:
            self._add_crop_to_warehouse_optimized(current_player_data, {"name": crop_type, "count": harvest_count}, crop_type, crop_info.get("品质", "普通"))
        
        # 添加种子奖励到背包
        if seed_reward:
            self._add_seeds_to_bag_optimized(current_player_data, seed_reward, crop_info.get("品质", "普通"))
        
        # 检查当前玩家升级
        level_up_experience = 100 * current_player_data["等级"]
        if current_player_data["经验值"] >= level_up_experience:
            current_player_data["等级"] += 1
            current_player_data["经验值"] -= level_up_experience
            self.log('INFO', f"玩家 {current_username} 升级到 {current_player_data['等级']} 级", 'SERVER')
        
        # 清理目标玩家的地块（批量更新）
        target_lot.update({
            "is_planted": False,
            "crop_type": "",
            "grow_time": 0,
            "已浇水": False,
            "已施肥": False
        })
        
        # 清除施肥时间戳
        if "施肥时间" in target_lot:
            del target_lot["施肥时间"]
        
        # 保存两个玩家的数据
        self.save_player_data(current_username, current_player_data)
        self.save_player_data(target_username, target_player_data)
        
        # 向目标玩家推送作物更新（如果在线）
        self._push_crop_update_to_player(target_username, target_player_data)
        
        # 构建消息
        if will_get_mature_item:
            message = f"偷菜成功！从 {target_username} 那里获得 {mature_item_name} x{harvest_count} 和 {crop_exp} 经验，{stamina_message}"
        else:
            message = f"偷菜成功！从 {target_username} 那里获得 {crop_exp} 经验，{stamina_message}（{crop_type}无成熟物产出）"
        
        if seed_reward:
            message += f"，额外获得 {seed_reward['name']} 种子 x{seed_reward['count']}"
        
        self.log('INFO', f"玩家 {current_username} 偷了玩家 {target_username} 地块 {lot_index} 的作物，获得 {crop_type} x{harvest_count} 和 {crop_exp} 经验" + (f"，额外获得 {seed_reward['name']} 种子 x{seed_reward['count']}" if seed_reward else ""), 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "harvest_crop",
            "success": True,
            "message": message,
            "updated_data": {
                "钱币": current_player_data["钱币"],
                "经验值": current_player_data["经验值"],
                "等级": current_player_data["等级"],
                "体力值": current_player_data.get("体力系统", {}).get("当前体力值", 20),
                "种子仓库": current_player_data.get("种子仓库", []),
                "作物仓库": current_player_data.get("作物仓库", [])
            }
        })
    
    # 处理偷菜被巡逻宠物发现的情况
    def _handle_steal_caught_by_patrol(self, client_id, current_player_data, current_username, target_player_data, target_username, patrol_pet_id):
        """处理偷菜被巡逻宠物发现的情况"""
        # 检查当前玩家是否有出战宠物
        battle_pets = current_player_data.get("出战宠物", [])
        
        if len(battle_pets) == 0:
            # 没有出战宠物，只能逃跑，支付1000金币
            escape_cost = 1000
            if current_player_data.get("钱币", 0) < escape_cost:
                # 金币不足，偷菜失败
                self.log('INFO', f"玩家 {current_username} 偷菜被发现，金币不足逃跑，偷菜失败", 'SERVER')
                return self.send_data(client_id, {
                    "type": "steal_caught",
                    "success": False,
                    "message": f"偷菜被 {target_username} 的巡逻宠物发现！金币不足支付逃跑费用（需要{escape_cost}金币），偷菜失败！",
                    "patrol_pet_data": self._get_patrol_pet_data(target_player_data, patrol_pet_id),
                    "has_battle_pet": False,
                    "escape_cost": escape_cost,
                    "current_money": current_player_data.get("钱币", 0)
                })
            else:
                # 自动逃跑，扣除金币
                current_player_data["钱币"] -= escape_cost
                target_player_data["钱币"] += escape_cost
                
                # 保存数据
                self.save_player_data(current_username, current_player_data)
                self.save_player_data(target_username, target_player_data)
                
                self.log('INFO', f"玩家 {current_username} 偷菜被发现，支付 {escape_cost} 金币逃跑", 'SERVER')
                return self.send_data(client_id, {
                    "type": "steal_caught",
                    "success": False,
                    "message": f"偷菜被 {target_username} 的巡逻宠物发现！支付了 {escape_cost} 金币逃跑",
                    "patrol_pet_data": self._get_patrol_pet_data(target_player_data, patrol_pet_id),
                    "has_battle_pet": False,
                    "escape_cost": escape_cost,
                    "updated_data": {
                        "钱币": current_player_data["钱币"]
                    }
                })
        else:
            # 有出战宠物，可以选择战斗或逃跑
            battle_pet_id = battle_pets[0]  # 取第一个出战宠物
            
            # 检查出战宠物是否与巡逻宠物是同一个（不应该发生，但保险起见）
            if battle_pet_id == patrol_pet_id:
                self.log('WARNING', f"玩家 {current_username} 的出战宠物与 {target_username} 的巡逻宠物是同一个，这不应该发生", 'SERVER')
                return self._send_action_error(client_id, "harvest_crop", "系统错误：宠物冲突")
            
            self.log('INFO', f"玩家 {current_username} 偷菜被发现，可以选择战斗或逃跑", 'SERVER')
            return self.send_data(client_id, {
                "type": "steal_caught",
                "success": False,
                "message": f"偷菜被 {target_username} 的巡逻宠物发现！",
                "patrol_pet_data": self._get_patrol_pet_data(target_player_data, patrol_pet_id),
                "battle_pet_data": self._get_battle_pet_data(current_player_data, battle_pet_id),
                "has_battle_pet": True,
                "escape_cost": 1000,
                "battle_cost": 1300,
                "target_username": target_username,
                "current_username": current_username
            })
    
    # 获取巡逻宠物数据
    def _get_patrol_pet_data(self, player_data, patrol_pet_id):
        """根据巡逻宠物ID获取完整宠物数据"""
        pet_bag = player_data.get("宠物背包", [])
        for pet in pet_bag:
            if pet.get("pet_id", "") == patrol_pet_id:
                # 添加场景路径
                import copy
                pet_data = copy.deepcopy(pet)
                # 直接从pet_image字段获取场景路径
                scene_path = pet.get("pet_image", "res://Scene/Pet/PetBase.tscn")
                pet_data["场景路径"] = scene_path
                return pet_data
        return None
    
    # 获取出战宠物数据
    def _get_battle_pet_data(self, player_data, battle_pet_id):
        """根据出战宠物ID获取完整宠物数据"""
        pet_bag = player_data.get("宠物背包", [])
        for pet in pet_bag:
            if pet.get("pet_id", "") == battle_pet_id:
                # 添加场景路径
                import copy
                pet_data = copy.deepcopy(pet)
                # 直接从pet_image字段获取场景路径
                scene_path = pet.get("pet_image", "res://Scene/Pet/PetBase.tscn")
                pet_data["场景路径"] = scene_path
                return pet_data
        return None
    
    # 生成收获种子奖励（10%概率获得1-2个种子）
    def _generate_harvest_seed_reward(self, crop_type):
        """生成收获作物时的种子奖励"""
        # 10%概率获得种子
        if random.random() > 0.1:
            return None
        
        # 随机获得1-2个种子
        seed_count = random.randint(1, 2)
        
        return {
            "name": crop_type,
            "count": seed_count
        }
    
    # 添加种子到玩家背包
    def _add_seeds_to_bag(self, player_data, seed_reward):
        """将种子奖励添加到玩家背包"""
        if not seed_reward:
            return
        
        seed_name = seed_reward["name"]
        seed_count = seed_reward["count"]
        
        # 确保背包存在
        if "种子仓库" not in player_data:
            player_data["种子仓库"] = []
        
        # 查找背包中是否已有该种子
        seed_found = False
        for item in player_data["种子仓库"]:
            if item.get("name") == seed_name:
                item["count"] += seed_count
                seed_found = True
                break
        
        # 如果背包中没有该种子，添加新条目
        if not seed_found:
            # 从作物数据获取品质信息
            crop_data = self._load_crop_data()
            quality = "普通"
            if crop_data and seed_name in crop_data:
                quality = crop_data[seed_name].get("品质", "普通")
            
            player_data["种子仓库"].append({
                "name": seed_name,
                "quality": quality,
                "count": seed_count
            })
    
    def _add_crop_to_warehouse(self, player_data, crop_harvest):
        """将成熟物添加到玩家作物仓库"""
        if not crop_harvest:
            return
        
        crop_name = crop_harvest["name"]
        crop_count = crop_harvest["count"]
        
        # 从作物数据检查"成熟物名称"字段
        crop_data = self._load_crop_data()
        if crop_data and crop_name in crop_data:
            mature_name = crop_data[crop_name].get("成熟物名称")
            # 如果成熟物名称为null，则不添加成熟物到仓库
            if mature_name is None:
                self.log('DEBUG', f"作物 {crop_name} 的成熟物名称为null，跳过添加到作物仓库", 'SERVER')
                return
            
            # 如果有指定的成熟物名称，使用它作为仓库中的名称
            if mature_name and mature_name.strip():
                warehouse_item_name = mature_name
            else:
                warehouse_item_name = crop_name
        else:
            # 如果作物数据中没有该作物，使用原名称
            warehouse_item_name = crop_name
        
        # 确保作物仓库存在
        if "作物仓库" not in player_data:
            player_data["作物仓库"] = []
        
        # 查找仓库中是否已有该成熟物
        crop_found = False
        for item in player_data["作物仓库"]:
            if item.get("name") == warehouse_item_name:
                item["count"] += crop_count
                crop_found = True
                break
        
        # 如果仓库中没有该成熟物，添加新条目
        if not crop_found:
            # 从作物数据获取品质信息
            quality = "普通"
            if crop_data and crop_name in crop_data:
                quality = crop_data[crop_name].get("品质", "普通")
            
            player_data["作物仓库"].append({
                "name": warehouse_item_name,
                "quality": quality,
                "count": crop_count
            })
    
    # 添加种子到玩家背包（优化版本）
    def _add_seeds_to_bag_optimized(self, player_data, seed_reward, quality="普通"):
        """将种子奖励添加到玩家背包（优化版本）"""
        if not seed_reward:
            return
        
        seed_name = seed_reward["name"]
        seed_count = seed_reward["count"]
        
        # 确保背包存在
        if "种子仓库" not in player_data:
            player_data["种子仓库"] = []
        
        # 查找背包中是否已有该种子
        for item in player_data["种子仓库"]:
            if item.get("name") == seed_name:
                item["count"] += seed_count
                return
        
        # 如果背包中没有该种子，添加新条目
        player_data["种子仓库"].append({
            "name": seed_name,
            "quality": quality,
            "count": seed_count
        })
    
    def _add_crop_to_warehouse_optimized(self, player_data, crop_harvest, warehouse_item_name, quality="普通"):
        """将成熟物添加到玩家作物仓库（优化版本）"""
        if not crop_harvest:
            return
        
        crop_count = crop_harvest["count"]
        
        # 确保作物仓库存在
        if "作物仓库" not in player_data:
            player_data["作物仓库"] = []
        
        # 查找仓库中是否已有该成熟物
        for item in player_data["作物仓库"]:
            if item.get("name") == warehouse_item_name:
                item["count"] += crop_count
                return
        
        # 如果仓库中没有该成熟物，添加新条目
        player_data["作物仓库"].append({
            "name": warehouse_item_name,
            "quality": quality,
            "count": crop_count
        })

#==========================收获作物处理==========================



#==========================杂草生长处理==========================
    def check_and_grow_weeds(self):
        """检查所有玩家的离线时间，并在长时间离线玩家的空地上随机生长杂草"""
        try:
            self.log('INFO', "开始检查杂草生长...", 'SERVER')
            current_time = time.time()
            affected_players = 0
            total_weeds_added = 0
            
            # 获取作物数据以验证杂草类型
            crop_data = self._load_crop_data()
            if not crop_data:
                self.log('ERROR', "无法加载作物数据，跳过杂草检查", 'SERVER')
                return
            
            # 可用的杂草类型（从作物数据中筛选标记为杂草的作物）
            available_weeds = []
            for crop_name, crop_info in crop_data.items():
                if crop_info.get("是否杂草", False):
                    available_weeds.append(crop_name)
            
            if not available_weeds:
                self.log('WARNING', "没有找到可用的杂草类型，跳过杂草检查", 'SERVER')
                return
            
            # 优先使用MongoDB获取离线玩家
            if self.use_mongodb and self.mongo_api:
                offline_players = self.mongo_api.get_offline_players(self.offline_threshold_days)
                
                for player_data in offline_players:
                    account_id = player_data.get("玩家账号")
                    if not account_id:
                        continue
                    
                    try:
                        # 获取完整玩家数据
                        full_player_data = self.mongo_api.get_player_data(account_id)
                        if not full_player_data:
                            continue
                        
                        # 为该玩家的空地生长杂草
                        weeds_added = self._grow_weeds_for_player(full_player_data, account_id, available_weeds)
                        if weeds_added > 0:
                            affected_players += 1
                            total_weeds_added += weeds_added
                            # 保存玩家数据
                            self.mongo_api.save_player_data(account_id, full_player_data)
                            
                    except Exception as e:
                        self.log('ERROR', f"处理玩家 {account_id} 的杂草生长时出错: {str(e)}", 'SERVER')
                        continue
            else:
                # 降级到文件系统
                game_saves_dir = "game_saves"
                if not os.path.exists(game_saves_dir):
                    return
                
                # 遍历所有玩家文件
                for filename in os.listdir(game_saves_dir):
                    if not filename.endswith('.json'):
                        continue
                    
                    account_id = filename[:-5]  # 移除.json后缀
                    
                    try:
                        # 加载玩家数据
                        player_data = self.load_player_data(account_id)
                        if not player_data:
                            continue
                        
                        # 检查玩家是否长时间离线
                        if self._is_player_long_offline(player_data, current_time):
                            # 为该玩家的空地生长杂草
                            weeds_added = self._grow_weeds_for_player(player_data, account_id, available_weeds)
                            if weeds_added > 0:
                                affected_players += 1
                                total_weeds_added += weeds_added
                                # 保存玩家数据
                                self.save_player_data(account_id, player_data)
                                
                    except Exception as e:
                        self.log('ERROR', f"处理玩家 {account_id} 的杂草生长时出错: {str(e)}", 'SERVER')
                        continue
            
            self.log('INFO', f"杂草检查完成，共为 {affected_players} 个玩家的农场添加了 {total_weeds_added} 个杂草", 'SERVER')
            
        except Exception as e:
            self.log('ERROR', f"杂草生长检查过程中出错: {str(e)}", 'SERVER')
    
    def _is_player_long_offline(self, player_data, current_time):
        """检查玩家是否长时间离线"""
        # 获取玩家最后登录时间
        last_login_time_str = player_data.get("最后登录时间", "")
        if not last_login_time_str:
            return False
        
        try:
            # 解析最后登录时间戳
            last_login_timestamp = self._parse_login_time_to_timestamp(last_login_time_str)
            if last_login_timestamp is None:
                return False
            
            # 计算离线天数
            offline_seconds = current_time - last_login_timestamp
            offline_days = offline_seconds / 86400  # 转换为天数
            
            return offline_days >= self.offline_threshold_days
            
        except Exception as e:
            self.log('ERROR', f"解析玩家登录时间时出错: {str(e)}", 'SERVER')
            return False
    
    def _grow_weeds_for_player(self, player_data, account_id, available_weeds):
        """为指定玩家的空地生长杂草"""
        import random
        
        farm_lots = player_data.get("农场土地", [])
        if not farm_lots:
            return 0
        
        # 找到所有空的已开垦地块
        empty_lots = []
        for i, lot in enumerate(farm_lots):
            if (lot.get("is_diged", False) and 
                not lot.get("is_planted", False) and 
                lot.get("crop_type", "") == ""):
                empty_lots.append(i)
        
        if not empty_lots:
            return 0
        
        # 随机选择要长杂草的地块数量
        max_weeds = min(self.max_weeds_per_check, len(empty_lots))
        weeds_to_add = random.randint(1, max_weeds)
        
        # 随机选择地块
        selected_lots = random.sample(empty_lots, weeds_to_add)
        weeds_added = 0
        
        crop_data = self._load_crop_data()
        
        for lot_index in selected_lots:
            # 按概率决定是否在这个地块长杂草
            if random.random() < self.weed_growth_probability:
                # 随机选择杂草类型
                weed_type = random.choice(available_weeds)
                weed_info = crop_data.get(weed_type, {})
                
                # 在地块上种植杂草
                lot = farm_lots[lot_index]
                lot["is_planted"] = True
                lot["crop_type"] = weed_type
                lot["grow_time"] = weed_info.get("生长时间", 5)  # 杂草立即成熟
                lot["max_grow_time"] = weed_info.get("生长时间", 5)
                lot["已浇水"] = False
                lot["已施肥"] = False
                
                weeds_added += 1
        
        if weeds_added > 0:
            self.log('INFO', f"为玩家 {account_id} 的农场添加了 {weeds_added} 个杂草", 'SERVER')
        
        return weeds_added

#==========================杂草生长处理==========================



#==========================偷菜免被发现计数器管理==========================
    def _get_steal_immunity_count(self, player_name, target_player_name):
        """获取玩家对目标玩家的免被发现次数"""
        return self.steal_immunity_counters.get(player_name, {}).get(target_player_name, 0)
    
    def _consume_steal_immunity(self, player_name, target_player_name):
        """消耗一次免被发现次数"""
        if player_name not in self.steal_immunity_counters:
            return False
        
        if target_player_name not in self.steal_immunity_counters[player_name]:
            return False
        
        if self.steal_immunity_counters[player_name][target_player_name] > 0:
            self.steal_immunity_counters[player_name][target_player_name] -= 1
            
            # 如果计数器归零，清理该条目
            if self.steal_immunity_counters[player_name][target_player_name] == 0:
                del self.steal_immunity_counters[player_name][target_player_name]
                
                # 如果该玩家没有其他计数器，清理玩家条目
                if not self.steal_immunity_counters[player_name]:
                    del self.steal_immunity_counters[player_name]
            
            return True
        
        return False
    
    def _set_steal_immunity(self, player_name, target_player_name, count=3):
        """设置玩家对目标玩家的免被发现次数"""
        if player_name not in self.steal_immunity_counters:
            self.steal_immunity_counters[player_name] = {}
        
        self.steal_immunity_counters[player_name][target_player_name] = count
        self.log('INFO', f"为玩家 {player_name} 设置对 {target_player_name} 的免被发现次数: {count}", 'SERVER')
    
    def _clear_player_steal_immunity(self, player_name):
        """清理玩家的所有免被发现计数器"""
        if player_name in self.steal_immunity_counters:
            del self.steal_immunity_counters[player_name]
            self.log('INFO', f"清理玩家 {player_name} 的所有免被发现计数器", 'SERVER')
    
    def _clear_target_steal_immunity(self, player_name, target_player_name):
        """清理玩家对特定目标的免被发现计数器"""
        if player_name in self.steal_immunity_counters:
            if target_player_name in self.steal_immunity_counters[player_name]:
                del self.steal_immunity_counters[player_name][target_player_name]
                
                # 如果该玩家没有其他计数器，清理玩家条目
                if not self.steal_immunity_counters[player_name]:
                    del self.steal_immunity_counters[player_name]
                
                self.log('INFO', f"清理玩家 {player_name} 对 {target_player_name} 的免被发现计数器", 'SERVER')

#==========================偷菜免被发现计数器管理==========================



#==========================种植作物处理==========================
    #处理种植作物请求 
    def _handle_plant_crop(self, client_id, message):
        """处理种植作物请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "种植作物", "plant_crop")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "plant_crop")
        if not player_data:
            return self.send_data(client_id, response)
        
        lot_index = message.get("lot_index", -1)
        crop_name = message.get("crop_name", "")
        
        # 验证参数
        if lot_index < 0 or lot_index >= len(player_data.get("农场土地", [])):
            return self._send_action_error(client_id, "plant_crop", "无效的地块索引")
        
        lot = player_data["农场土地"][lot_index]
        
        # 检查地块状态
        if not lot.get("is_diged", False):
            return self._send_action_error(client_id, "plant_crop", "此地块尚未开垦")
        
        if lot.get("is_planted", False):
            return self._send_action_error(client_id, "plant_crop", "此地块已经种植了作物")
        
        # 处理种植
        return self._process_planting(client_id, player_data, username, lot, crop_name)
    
    #辅助函数-处理作物种植逻辑
    def _process_planting(self, client_id, player_data, username, lot, crop_name):
        """处理作物种植逻辑"""
        # 读取作物配置
        crop_data = self._load_crop_data()
        
        # 检查玩家背包中是否有此种子
        seed_found = False
        seed_index = -1
        
        for i, item in enumerate(player_data.get("种子仓库", [])):
            if item.get("name") == crop_name:
                seed_found = True
                seed_index = i
                break
        
        if not seed_found:
            return self._send_action_error(client_id, "plant_crop", "背包中没有此种子")
        
        # 获取作物生长时间
        if crop_name in crop_data:
            grow_time = crop_data[crop_name].get("生长时间", 600)
        else:
            grow_time = 600
        
        # 从背包中减少种子数量
        player_data["种子仓库"][seed_index]["count"] -= 1
        
        # 如果种子用完，从背包中移除
        if player_data["种子仓库"][seed_index]["count"] <= 0:
            player_data["种子仓库"].pop(seed_index)
        
        # 更新地块数据
        lot.update({
            "is_planted": True,
            "crop_type": crop_name,
            "grow_time": 0,
            "max_grow_time": grow_time,
            "is_dead": False,
            "已浇水": False,
            "已施肥": False
        })
        
        # 清除施肥时间戳
        if "施肥时间" in lot:
            del lot["施肥时间"]
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        self.log('INFO', f"玩家 {username} 种植了 {crop_name}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "plant_crop",
            "success": True,
            "message": f"成功种植 {crop_name}",
            "updated_data": {
                "种子仓库": player_data["种子仓库"]
            }
        })
#==========================种植作物处理==========================




#==========================购买种子处理==========================
    #处理购买种子请求
    def _handle_buy_seed(self, client_id, message):
        """处理购买种子请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "购买种子", "buy_seed")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "buy_seed")
        if not player_data:
            return self.send_data(client_id, response)
        
        crop_name = message.get("crop_name", "")
        quantity = max(1, int(message.get("quantity", 1)))  # 确保购买数量为正整数
        
        # 加载作物配置
        crop_data = self._load_crop_data()
        if not crop_data:
            return self._send_action_error(client_id, "buy_seed", "服务器无法加载作物数据")
        
        # 检查作物是否存在
        if crop_name not in crop_data:
            return self._send_action_error(client_id, "buy_seed", "该种子不存在")
        
        # 处理批量购买
        return self._process_seed_purchase(client_id, player_data, username, crop_name, crop_data[crop_name], quantity)
    
    #处理种子购买逻辑
    def _process_seed_purchase(self, client_id, player_data, username, crop_name, crop, quantity=1):
        """处理种子购买逻辑"""
        # 检查玩家等级
        player_level = int(player_data.get("等级", 1))
        required_level = int(crop.get("等级", 1))
        if player_level < required_level:
            return self._send_action_error(client_id, "buy_seed", "等级不足，无法购买此种子")
        
        # 计算总花费
        unit_cost = crop.get("花费", 0)
        total_cost = unit_cost * quantity
        
        # 检查玩家金钱
        if player_data["钱币"] < total_cost:
            return self._send_action_error(client_id, "buy_seed", f"金钱不足，无法购买此种子。需要{total_cost}元，当前只有{player_data['钱币']}元")
        
        # 扣除金钱
        player_data["钱币"] -= total_cost
        
        # 将种子添加到背包
        seed_found = False
        
        for item in player_data.get("种子仓库", []):
            if item.get("name") == crop_name:
                item["count"] += quantity
                seed_found = True
                break
        
        if not seed_found:
            if "种子仓库" not in player_data:
                player_data["种子仓库"] = []
                
            player_data["种子仓库"].append({
                "name": crop_name,
                "quality": crop.get("品质", "普通"),
                "count": quantity
            })
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 购买了 {quantity} 个种子 {crop_name}，花费 {total_cost} 元", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "buy_seed",
            "success": True,
            "message": f"成功购买 {quantity} 个 {crop_name} 种子",
            "updated_data": {
                "钱币": player_data["钱币"],
                "种子仓库": player_data["种子仓库"]
            }
        })
    
#==========================购买种子处理==========================



#==========================购买宠物处理==========================
    #处理购买宠物请求
    def _handle_buy_pet(self, client_id, message):
        """处理购买宠物请求"""
        # 检查用户登录状态
        logged_in, response = self._check_user_logged_in(client_id, "购买宠物", "buy_pet")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "buy_pet")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 获取请求参数
        pet_name = message.get("pet_name", "")
        pet_cost = message.get("pet_cost", 0)
        
        # 验证宠物购买条件
        validation_result = self._validate_pet_purchase(pet_name, pet_cost, player_data)
        if not validation_result["success"]:
            return self._send_action_error(client_id, "buy_pet", validation_result["message"])
        
        # 处理宠物购买
        return self._process_pet_purchase(client_id, player_data, username, pet_name, validation_result["pet_info"])
    
    def _validate_pet_purchase(self, pet_name, pet_cost, player_data):
        """验证宠物购买条件"""
        # 加载宠物配置
        pet_config = self._load_pet_config()
        if not pet_config:
            return {"success": False, "message": "服务器无法加载宠物数据"}
        
        # 检查宠物是否存在
        if pet_name not in pet_config:
            return {"success": False, "message": "该宠物不存在"}
        
        pet_info = pet_config[pet_name]
        
        # 从配置中获取宠物价格
        actual_cost = pet_info.get("cost", 1000)  # 默认价格1000
        if pet_cost != actual_cost:
            return {"success": False, "message": f"宠物价格验证失败，实际价格为{actual_cost}元"}
        
        # 检查玩家是否已拥有该宠物
        if self._player_has_pet(player_data, pet_name):
            return {"success": False, "message": f"你已经拥有 {pet_name} 了！"}
        
        return {"success": True, "pet_info": pet_info}
    
    #处理宠物购买逻辑
    def _process_pet_purchase(self, client_id, player_data, username, pet_name, pet_info):
        """处理宠物购买逻辑"""
        pet_cost = pet_info.get("cost", 1000)  # 从配置中获取价格，默认1000
        
        # 检查玩家金钱
        if player_data["钱币"] < pet_cost:
            return self._send_action_error(client_id, "buy_pet", 
                f"金钱不足，无法购买此宠物。需要{pet_cost}元，当前只有{player_data['钱币']}元")
        
        # 扣除金钱并添加宠物
        player_data["钱币"] -= pet_cost
        pet_instance = self._create_pet_instance(pet_info, username, pet_name)
        
        # 确保宠物背包存在并添加宠物
        if "宠物背包" not in player_data:
            player_data["宠物背包"] = []
        player_data["宠物背包"].append(pet_instance)
        
        # 保存数据并返回响应
        self.save_player_data(username, player_data)
        self.log('INFO', f"玩家 {username} 购买了宠物 {pet_name}，花费 {pet_cost} 元", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "buy_pet",
            "success": True,
            "message": f"成功购买宠物 {pet_name}！",
            "updated_data": {
                "钱币": player_data["钱币"],
                "宠物背包": player_data["宠物背包"]
            }
        })
    
    def _create_pet_instance(self, pet_info, username, pet_name):
        """创建宠物实例"""
        import copy
        import time
        import datetime
        
        # 复制宠物配置数据
        pet_instance = copy.deepcopy(pet_info)
        
        # 生成唯一ID和设置基本信息
        unique_id = str(int(time.time() * 1000))
        now = datetime.datetime.now()
        birthday = f"{now.year}-{now.month:02d}-{now.day:02d}"
        
        # 新格式：直接在根级别设置属性
        pet_instance.update({
            "pet_id": unique_id,
            "pet_name": f"{username}的{pet_name}",
            "pet_birthday": birthday,
            "pet_owner": username
        })
        
        # 初始化当前生命值为最大生命值
        max_health = pet_instance.get("max_health", 100)
        pet_instance["pet_current_health"] = max_health
        
        return pet_instance
    
    #检查玩家是否已拥有某种宠物
    def _player_has_pet(self, player_data, pet_name):
        """检查玩家是否已拥有指定类型的宠物"""
        pet_bag = player_data.get("宠物背包", [])
        for pet in pet_bag:
            pet_type = pet.get("pet_type", "")
            if pet_type == pet_name:
                return True
        return False
    
    #加载宠物配置数据
    def _load_pet_config(self):
        """从MongoDB加载宠物配置数据"""
        try:
            if not hasattr(self, 'mongo_api') or not self.mongo_api:
                self.log('ERROR', 'MongoDB未配置或不可用，无法加载宠物配置数据', 'SERVER')
                return {}
                
            config = self.mongo_api.get_pet_config()
            if config:
                self.log('INFO', "成功从MongoDB加载宠物配置", 'SERVER')
                return config
            else:
                self.log('ERROR', "MongoDB中未找到宠物配置", 'SERVER')
                return {}
                
        except Exception as e:
            self.log('ERROR', f"从MongoDB加载宠物配置失败: {str(e)}", 'SERVER')
            return {}
    
    def _load_game_tips_config(self):
        """从MongoDB加载游戏小提示配置数据"""
        try:
            if not hasattr(self, 'mongo_api') or not self.mongo_api:
                self.log('ERROR', 'MongoDB未配置或不可用，无法加载游戏小提示配置数据', 'SERVER')
                return {}
                
            config = self.mongo_api.get_game_tips_config()
            if config:
                self.log('INFO', "成功从MongoDB加载游戏小提示配置", 'SERVER')
                return config
            else:
                self.log('ERROR', "MongoDB中未找到游戏小提示配置", 'SERVER')
                return {}
                
        except Exception as e:
            self.log('ERROR', f"从MongoDB加载游戏小提示配置失败: {str(e)}", 'SERVER')
            return {}
    
    # 将巡逻宠物ID转换为完整宠物数据
    def _convert_patrol_pets_to_full_data(self, player_data):
        """将存储的巡逻宠物ID转换为完整的宠物数据"""
        patrol_pets_data = []
        patrol_pets_ids = player_data.get("巡逻宠物", [])
        pet_bag = player_data.get("宠物背包", [])
        
        for patrol_pet_id in patrol_pets_ids:
            for pet in pet_bag:
                if pet.get("pet_id", "") == patrol_pet_id:
                    # 为巡逻宠物添加场景路径
                    import copy
                    patrol_pet_data = copy.deepcopy(pet)
                    
                    # 直接从pet_image字段获取场景路径
                    scene_path = pet.get("pet_image", "")
                    patrol_pet_data["场景路径"] = scene_path
                    
                    patrol_pets_data.append(patrol_pet_data)
                    break
        
        return patrol_pets_data
    
    # 将出战宠物ID转换为完整宠物数据
    def _convert_battle_pets_to_full_data(self, player_data):
        """将存储的出战宠物ID转换为完整的宠物数据"""
        battle_pets_data = []
        battle_pets_ids = player_data.get("出战宠物", [])
        pet_bag = player_data.get("宠物背包", [])
        
        for battle_pet_id in battle_pets_ids:
            for pet in pet_bag:
                if pet.get("pet_id", "") == battle_pet_id:
                    # 为出战宠物添加场景路径
                    import copy
                    battle_pet_data = copy.deepcopy(pet)
                    
                    # 直接从pet_image字段获取场景路径
                    scene_path = pet.get("pet_image", "")
                    battle_pet_data["场景路径"] = scene_path
                    
                    battle_pets_data.append(battle_pet_data)
                    break
        
        return battle_pets_data
#==========================购买宠物处理==========================


#==========================重命名宠物处理==========================
    #处理重命名宠物请求
    def _handle_rename_pet(self, client_id, message):
        """处理重命名宠物请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "重命名宠物", "rename_pet")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "rename_pet")
        if not player_data:
            return self.send_data(client_id, response)
        
        pet_id = message.get("pet_id", "")
        new_name = message.get("new_name", "")
        
        # 验证参数
        if not pet_id:
            return self._send_action_error(client_id, "rename_pet", "宠物ID不能为空")
        
        if not new_name:
            return self._send_action_error(client_id, "rename_pet", "宠物名字不能为空")
        
        # 验证名字长度
        if len(new_name) > 20:
            return self._send_action_error(client_id, "rename_pet", "宠物名字太长，最多20个字符")
        
        # 检查宠物是否存在
        pet_bag = player_data.get("宠物背包", [])
        pet_found = False
        
        for pet in pet_bag:
            if pet.get("pet_id", "") == pet_id:
                # 检查宠物主人是否正确
                if pet.get("pet_owner", "") != username:
                    return self._send_action_error(client_id, "rename_pet", "你不是该宠物的主人")
                
                # 更新宠物名字
                pet["pet_name"] = new_name
                pet_found = True
                break
        
        if not pet_found:
            return self._send_action_error(client_id, "rename_pet", "未找到指定ID的宠物")
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 重命名宠物 {pet_id} 为 {new_name}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "rename_pet",
            "success": True,
            "message": f"宠物名字已成功修改为 {new_name}",
            "pet_id": pet_id,
            "new_name": new_name,
            "updated_data": {
                "宠物背包": player_data["宠物背包"]
            }
        })
#==========================重命名宠物处理==========================


#==========================设置巡逻宠物处理==========================
    #处理设置巡逻宠物请求
    def _handle_set_patrol_pet(self, client_id, message):
        """处理设置或取消巡逻宠物的请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "设置巡逻宠物", "set_patrol_pet")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "set_patrol_pet")
        if not player_data:
            return self.send_data(client_id, response)
        
        pet_id = message.get("pet_id", "")
        is_patrolling = message.get("is_patrolling", False)
        
        self.log('INFO', f"处理巡逻宠物请求: pet_id={pet_id}, is_patrolling={is_patrolling}", client_id)
        
        # 验证参数
        if not pet_id:
            return self._send_action_error(client_id, "set_patrol_pet", "宠物ID不能为空")
        
        # 获取宠物背包和巡逻宠物列表
        pet_bag = player_data.get("宠物背包", [])
        patrol_pets = player_data.get("巡逻宠物", [])
        
        # 查找目标宠物
        target_pet = None
        for pet in pet_bag:
            if pet.get("pet_id", "") == pet_id:
                target_pet = pet
                break
        
        if not target_pet:
            return self._send_action_error(client_id, "set_patrol_pet", "未找到指定的宠物")
        
        # 检查宠物主人是否正确
        if target_pet.get("pet_owner", "") != username:
            return self._send_action_error(client_id, "set_patrol_pet", "你不是该宠物的主人")
        
        pet_name = target_pet.get("pet_name", target_pet.get("pet_type", "未知宠物"))
        
        if is_patrolling:
            # 添加到巡逻列表
            # 检查巡逻宠物数量限制（最多4个）
            if len(patrol_pets) >= 4:
                return self._send_action_error(client_id, "set_patrol_pet", "最多只能设置4个巡逻宠物")
            
            # 检查是否已在巡逻列表中（现在只检查ID）
            for patrol_pet_id in patrol_pets:
                if patrol_pet_id == pet_id:
                    return self._send_action_error(client_id, "set_patrol_pet", f"{pet_name} 已在巡逻列表中")
            
            # 添加到巡逻列表（只保存宠物ID）
            patrol_pets.append(pet_id)
            message_text = f"{pet_name} 已设置为巡逻宠物"
            self.log('INFO', f"玩家 {username} 设置宠物 {pet_name} 为巡逻宠物", 'SERVER')
            
        else:
            # 从巡逻列表移除
            original_count = len(patrol_pets)
            patrol_pets = [pid for pid in patrol_pets if pid != pet_id]
            
            if len(patrol_pets) == original_count:
                return self._send_action_error(client_id, "set_patrol_pet", f"{pet_name} 不在巡逻列表中")
            
            message_text = f"{pet_name} 已取消巡逻"
            self.log('INFO', f"玩家 {username} 取消宠物 {pet_name} 的巡逻", 'SERVER')
        
        # 更新玩家数据
        player_data["巡逻宠物"] = patrol_pets
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 构建返回给客户端的巡逻宠物数据（完整宠物数据）
        patrol_pets_data = []
        for patrol_pet_id in patrol_pets:
            for pet in pet_bag:
                if pet.get("pet_id", "") == patrol_pet_id:
                    # 为巡逻宠物添加场景路径
                    import copy
                    patrol_pet_data = copy.deepcopy(pet)
                    
                    # 新格式中场景路径已经在pet_image字段中
                    if "pet_image" in pet:
                        patrol_pet_data["scene_path"] = pet["pet_image"]
                    
                    patrol_pets_data.append(patrol_pet_data)
                    break
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "set_patrol_pet",
            "success": True,
            "message": message_text,
            "pet_id": pet_id,
            "is_patrolling": is_patrolling,
            "updated_data": {
                "巡逻宠物": patrol_pets_data
            }
        })
#==========================设置巡逻宠物处理==========================


#==========================设置出战宠物处理==========================
    #处理设置出战宠物请求
    def _handle_set_battle_pet(self, client_id, message):
        """处理设置出战宠物请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "设置出战宠物", "set_battle_pet")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "set_battle_pet")
        if not player_data:
            return self.send_data(client_id, response)
        
        pet_id = message.get("pet_id", "")
        is_battle = message.get("is_battle", True)  # 默认为设置出战
        
        if not pet_id:
            return self._send_action_error(client_id, "set_battle_pet", "宠物ID不能为空")
        
        # 获取宠物背包和出战宠物列表
        pet_bag = player_data.get("宠物背包", [])
        battle_pets = player_data.get("出战宠物", [])
        patrol_pets = player_data.get("巡逻宠物", [])
        
        # 查找宠物是否在背包中
        target_pet = None
        for pet in pet_bag:
            if pet.get("pet_id", "") == pet_id:
                target_pet = pet
                break
        
        if not target_pet:
            return self._send_action_error(client_id, "set_battle_pet", f"宠物背包中找不到ID为 {pet_id} 的宠物")
        
        pet_name = target_pet.get("pet_name", "未知宠物")
        
        if is_battle:
            # 添加到出战列表
            # 检查是否已在出战列表中
            if pet_id in battle_pets:
                return self._send_action_error(client_id, "set_battle_pet", f"{pet_name} 已在出战列表中")
            
            # 检查是否在巡逻列表中（出战宠物不能是巡逻宠物）
            if pet_id in patrol_pets:
                return self._send_action_error(client_id, "set_battle_pet", f"{pet_name} 正在巡逻，不能同时设置为出战宠物")
            
            # 检查出战宠物数量限制（最多4个）
            if len(battle_pets) >= 4:
                return self._send_action_error(client_id, "set_battle_pet", "最多只能设置4个出战宠物")
            
            # 添加到出战列表
            battle_pets.append(pet_id)
            message_text = f"{pet_name} 已设置为出战宠物"
            self.log('INFO', f"玩家 {username} 设置宠物 {pet_name} 为出战宠物", 'SERVER')
            
        else:
            # 从出战列表移除
            if pet_id not in battle_pets:
                return self._send_action_error(client_id, "set_battle_pet", f"{pet_name} 不在出战列表中")
            
            battle_pets.remove(pet_id)
            message_text = f"{pet_name} 已移除出战状态"
            self.log('INFO', f"玩家 {username} 移除宠物 {pet_name} 的出战状态", 'SERVER')
        
        # 更新玩家数据
        player_data["出战宠物"] = battle_pets
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 构建返回给客户端的出战宠物数据（完整宠物数据）
        battle_pets_data = []
        for battle_pet_id in battle_pets:
            for pet in pet_bag:
                if pet.get("pet_id", "") == battle_pet_id:
                    # 为出战宠物添加场景路径
                    import copy
                    battle_pet_data = copy.deepcopy(pet)
                    
                    # 新格式中场景路径已经在pet_image字段中
                    if "pet_image" in pet:
                        battle_pet_data["scene_path"] = pet["pet_image"]
                    
                    battle_pets_data.append(battle_pet_data)
                    break
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "set_battle_pet",
            "success": True,
            "message": message_text,
            "pet_id": pet_id,
            "is_battle": is_battle,
            "updated_data": {
                "出战宠物": battle_pets_data
            }
        })
#==========================设置出战宠物处理==========================


#==========================更新宠物对战数据处理==========================
    #处理更新宠物对战数据请求
    def _handle_update_battle_pet_data(self, client_id, message):
        """处理更新宠物对战数据请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "更新宠物对战数据", "update_battle_pet_data")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取请求参数
        pet_id = message.get("pet_id", "")
        attacker_name = message.get("attacker_name", "")
        exp_gained = message.get("exp_gained", 0)
        intimacy_gained = message.get("intimacy_gained", 0)
        new_level = message.get("new_level", 1)
        new_experience = message.get("new_experience", 0)
        new_max_experience = message.get("new_max_experience", 100)
        new_intimacy = message.get("new_intimacy", 0)
        level_ups = message.get("level_ups", 0)
        level_bonus_multiplier = message.get("level_bonus_multiplier", 1.0)
        is_steal_battle = message.get("is_steal_battle", False)
        battle_winner = message.get("battle_winner", "")
        
        if not pet_id or not attacker_name:
            return self._send_action_error(client_id, "update_battle_pet_data", "无效的宠物ID或进攻者名称")
        
        # 获取进攻者玩家数据
        player_data = self.load_player_data(attacker_name)
        if not player_data:
            return self._send_action_error(client_id, "update_battle_pet_data", "无法找到进攻者数据")
        
        # 更新宠物数据
        success = self._update_pet_battle_data(player_data, pet_id, exp_gained, intimacy_gained, 
                                               new_level, new_experience, new_max_experience, 
                                               new_intimacy, level_ups, level_bonus_multiplier)
        
        if success:
            # 检查是否是偷菜对战且玩家获胜，如果是则设置免被发现计数器
            if is_steal_battle and battle_winner == "team1":
                # 获取当前访问的目标玩家名称（从客户端连接信息中获取）
                target_player_name = self.user_data.get(client_id, {}).get("visiting_target", "")
                if target_player_name:
                    self._set_steal_immunity(attacker_name, target_player_name, 3)
                    self.log('INFO', f"玩家 {attacker_name} 战胜巡逻宠物，获得对 {target_player_name} 的3次免被发现机会", 'SERVER')
            
            # 保存玩家数据
            self.save_player_data(attacker_name, player_data)
            
            self.log('INFO', f"成功更新玩家 {attacker_name} 的宠物 {pet_id} 对战数据：经验+{exp_gained}，亲密度+{intimacy_gained}，升级{level_ups}级", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "update_battle_pet_data",
                "success": True,
                "message": f"成功更新宠物对战数据",
                "pet_id": pet_id,
                "exp_gained": exp_gained,
                "intimacy_gained": intimacy_gained,
                "level_ups": level_ups
            })
        else:
            return self._send_action_error(client_id, "update_battle_pet_data", f"无法找到宠物ID为 {pet_id} 的宠物")

    #辅助函数-更新宠物对战数据
    def _update_pet_battle_data(self, player_data, pet_id, exp_gained, intimacy_gained, 
                                new_level, new_experience, new_max_experience, 
                                new_intimacy, level_ups, level_bonus_multiplier):
        """更新宠物对战数据"""
        
        # 确保宠物背包存在
        if "宠物背包" not in player_data:
            player_data["宠物背包"] = []
        
        # 查找指定宠物
        target_pet = None
        for pet in player_data["宠物背包"]:
            if pet.get("pet_id") == pet_id:
                target_pet = pet
                break
        
        if not target_pet:
            return False
        
        # 更新等级经验数据
        target_pet["pet_level"] = new_level
        target_pet["pet_experience"] = new_experience
        target_pet["pet_max_experience"] = new_max_experience
        target_pet["pet_intimacy"] = new_intimacy
        
        # 如果有升级，更新属性
        if level_ups > 0:
            # 计算升级后的属性（每级10%加成）
            old_max_health = target_pet.get("pet_max_health", 100.0)
            old_max_armor = target_pet.get("pet_max_armor", 100.0)
            old_attack_damage = target_pet.get("pet_attack_damage", 20.0)
            
            # 应用升级加成
            new_max_health = old_max_health * level_bonus_multiplier
            new_max_armor = old_max_armor * level_bonus_multiplier
            new_attack_damage = old_attack_damage * level_bonus_multiplier
            
            target_pet["pet_max_health"] = new_max_health
            target_pet["pet_current_health"] = new_max_health  # 升级回满血
            target_pet["pet_max_armor"] = new_max_armor
            target_pet["pet_current_armor"] = new_max_armor  # 升级回满护甲
            target_pet["pet_attack_damage"] = new_attack_damage
        
        return True
#==========================更新宠物对战数据处理==========================


#==========================宠物喂食处理==========================
    #处理宠物喂食请求
    def _handle_feed_pet(self, client_id, message):
        """处理宠物喂食请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "宠物喂食", "feed_pet")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "feed_pet")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 获取请求参数
        pet_id = message.get("pet_id", "")
        crop_name = message.get("crop_name", "")
        feed_effects = message.get("feed_effects", {})
        
        # 验证参数
        if not pet_id:
            return self._send_action_error(client_id, "feed_pet", "宠物ID不能为空")
        
        if not crop_name:
            return self._send_action_error(client_id, "feed_pet", "作物名称不能为空")
        
        # 检查玩家是否有该作物
        crop_warehouse = player_data.get("作物仓库", [])
        crop_found = False
        crop_index = -1
        
        for i, crop_item in enumerate(crop_warehouse):
            if crop_item.get("name") == crop_name:
                if crop_item.get("count", 0) > 0:
                    crop_found = True
                    crop_index = i
                    break
        
        if not crop_found:
            return self._send_action_error(client_id, "feed_pet", f"没有足够的{crop_name}用于喂食")
        
        # 检查宠物是否存在
        pet_bag = player_data.get("宠物背包", [])
        target_pet = None
        
        for pet in pet_bag:
            if pet.get("pet_id", "") == pet_id:
                # 检查宠物主人是否正确
                if pet.get("pet_owner", "") != username:
                    return self._send_action_error(client_id, "feed_pet", "你不是该宠物的主人")
                target_pet = pet
                break
        
        if not target_pet:
            return self._send_action_error(client_id, "feed_pet", "未找到指定的宠物")
        
        # 验证作物是否有喂养效果
        crop_data = self._load_crop_data()
        if crop_name not in crop_data or "喂养效果" not in crop_data[crop_name]:
            return self._send_action_error(client_id, "feed_pet", f"{crop_name}没有喂养效果")
        
        # 获取作物的喂养效果
        crop_feed_effects = crop_data[crop_name]["喂养效果"]
        
        # 执行喂食
        success, applied_effects = self._process_pet_feeding(player_data, target_pet, crop_name, crop_index, crop_feed_effects)
        
        if success:
            # 保存玩家数据
            self.save_player_data(username, player_data)
            
            pet_name = target_pet.get("pet_name", "未知宠物")
            
            # 构建效果描述
            effect_descriptions = []
            for effect_name, effect_value in applied_effects.items():
                if effect_value > 0:
                    effect_descriptions.append(f"{effect_name}+{effect_value}")
            
            effect_text = "，".join(effect_descriptions) if effect_descriptions else "无效果"
            self.log('INFO', f"玩家 {username} 用{crop_name}喂食宠物 {pet_name}，获得：{effect_text}", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "feed_pet",
                "success": True,
                "message": f"成功喂食{pet_name}！获得：{effect_text}",
                "pet_id": pet_id,
                "crop_name": crop_name,
                "applied_effects": applied_effects,
                "updated_data": {
                    "宠物背包": player_data["宠物背包"],
                    "作物仓库": player_data["作物仓库"]
                }
            })
        else:
            return self._send_action_error(client_id, "feed_pet", "喂食失败")
    
    #辅助函数-处理宠物喂食逻辑
    def _process_pet_feeding(self, player_data, target_pet, crop_name, crop_index, feed_effects):
        """处理宠物喂食逻辑，支持多种属性提升"""
        try:
            # 消耗作物
            crop_warehouse = player_data.get("作物仓库", [])
            if crop_index >= 0 and crop_index < len(crop_warehouse):
                crop_warehouse[crop_index]["count"] -= 1
                # 如果数量为0，移除该作物
                if crop_warehouse[crop_index]["count"] <= 0:
                    crop_warehouse.pop(crop_index)
            
            # 记录实际应用的效果
            applied_effects = {}
            
            # 处理经验效果
            if "经验" in feed_effects:
                exp_gain = feed_effects["经验"]
                current_exp = target_pet.get("pet_experience", 0)
                max_exp = target_pet.get("pet_max_experience", 100)
                current_level = target_pet.get("pet_level", 1)
                
                new_exp = current_exp + exp_gain
                applied_effects["经验"] = exp_gain
                
                # 检查是否升级
                level_ups = 0
                while new_exp >= max_exp and current_level < 100:  # 假设最大等级为100
                    level_ups += 1
                    new_exp -= max_exp
                    current_level += 1
                    # 每升一级，最大经验增加20%
                    max_exp = int(max_exp * 1.2)
                
                # 更新经验数据
                target_pet["pet_experience"] = new_exp
                target_pet["pet_max_experience"] = max_exp
                target_pet["pet_level"] = current_level
                
                # 如果升级了，记录升级次数
                if level_ups > 0:
                    applied_effects["升级"] = level_ups
                    # 升级时应用属性加成
                    self._apply_level_up_bonus(target_pet, level_ups)
            
            # 处理生命值效果（增加最大生命值）
            if "生命值" in feed_effects:
                max_hp_gain = feed_effects["生命值"]
                # 增加最大生命值
                current_max_hp = target_pet.get("max_health", 100)
                new_max_hp = current_max_hp + max_hp_gain
                target_pet["max_health"] = new_max_hp
                
                # 同时恢复相应的当前生命值
                current_hp = target_pet.get("pet_current_health", current_max_hp)
                target_pet["pet_current_health"] = current_hp + max_hp_gain
                
                applied_effects["生命值"] = max_hp_gain
            
            # 处理攻击力效果
            if "攻击力" in feed_effects:
                attack_gain = feed_effects["攻击力"]
                current_attack = target_pet.get("base_attack_damage", 20)
                new_attack = current_attack + attack_gain
                target_pet["base_attack_damage"] = new_attack
                applied_effects["攻击力"] = attack_gain
            
            # 处理移动速度效果
            if "移动速度" in feed_effects:
                speed_gain = feed_effects["移动速度"]
                current_speed = target_pet.get("move_speed", 100)
                new_speed = current_speed + speed_gain
                target_pet["move_speed"] = new_speed
                applied_effects["移动速度"] = speed_gain
            
            # 处理亲密度效果
            if "亲密度" in feed_effects:
                intimacy_gain = feed_effects["亲密度"]
                current_intimacy = target_pet.get("pet_intimacy", 0)
                max_intimacy = target_pet.get("pet_max_intimacy", 1000)
                
                actual_intimacy_gain = min(intimacy_gain, max_intimacy - current_intimacy)
                if actual_intimacy_gain > 0:
                    target_pet["pet_intimacy"] = current_intimacy + actual_intimacy_gain
                    applied_effects["亲密度"] = actual_intimacy_gain
            
            # 处理护甲值效果
            if "护甲值" in feed_effects:
                armor_gain = feed_effects["护甲值"]
                current_armor = target_pet.get("current_armor", target_pet.get("max_armor", 10))
                max_armor = target_pet.get("max_armor", 10)
                
                actual_armor_gain = min(armor_gain, max_armor - current_armor)
                if actual_armor_gain > 0:
                    target_pet["current_armor"] = current_armor + actual_armor_gain
                    applied_effects["护甲值"] = actual_armor_gain
            
            # 处理暴击率效果
            if "暴击率" in feed_effects:
                crit_gain = feed_effects["暴击率"] / 100.0  # 转换为小数
                current_crit = target_pet.get("crit_rate", 0.1)
                new_crit = min(current_crit + crit_gain, 1.0)  # 最大100%
                target_pet["crit_rate"] = new_crit
                applied_effects["暴击率"] = feed_effects["暴击率"]
            
            # 处理闪避率效果
            if "闪避率" in feed_effects:
                dodge_gain = feed_effects["闪避率"] / 100.0  # 转换为小数
                current_dodge = target_pet.get("dodge_rate", 0.05)
                new_dodge = min(current_dodge + dodge_gain, 1.0)  # 最大100%
                target_pet["dodge_rate"] = new_dodge
                applied_effects["闪避率"] = feed_effects["闪避率"]
            
            # 处理护盾值效果
            if "护盾值" in feed_effects:
                shield_gain = feed_effects["护盾值"]
                current_shield = target_pet.get("current_shield", target_pet.get("max_shield", 0))
                max_shield = target_pet.get("max_shield", 0)
                
                actual_shield_gain = min(shield_gain, max_shield - current_shield)
                if actual_shield_gain > 0:
                    target_pet["current_shield"] = current_shield + actual_shield_gain
                    applied_effects["护盾值"] = actual_shield_gain
            
            return True, applied_effects
            
        except Exception as e:
            self.log('ERROR', f"宠物喂食处理失败: {str(e)}", 'SERVER')
            return False, {}
    
    #辅助函数-应用升级加成
    def _apply_level_up_bonus(self, target_pet, level_ups):
        """应用升级时的属性加成"""
        # 每升一级，属性增加10%
        level_bonus_multiplier = 1.1 ** level_ups
        
        # 更新生命和防御属性
        old_max_hp = target_pet.get("max_health", 100)
        old_max_armor = target_pet.get("max_armor", 10)
        old_max_shield = target_pet.get("max_shield", 0)
        
        new_max_hp = int(old_max_hp * level_bonus_multiplier)
        new_max_armor = int(old_max_armor * level_bonus_multiplier)
        new_max_shield = int(old_max_shield * level_bonus_multiplier)
        
        target_pet["max_health"] = new_max_hp
        target_pet["pet_current_health"] = new_max_hp  # 升级回满血
        target_pet["max_armor"] = new_max_armor
        target_pet["current_armor"] = new_max_armor  # 升级回满护甲
        
        # 如果有护盾系统，也更新护盾
        if old_max_shield > 0:
            target_pet["max_shield"] = new_max_shield
            target_pet["current_shield"] = new_max_shield  # 升级回满护盾
        
        # 更新攻击属性
        old_attack = target_pet.get("base_attack_damage", 20)
        new_attack = int(old_attack * level_bonus_multiplier)
        target_pet["base_attack_damage"] = new_attack
        
        # 更新移动速度
        old_speed = target_pet.get("move_speed", 100)
        new_speed = int(old_speed * level_bonus_multiplier)
        target_pet["move_speed"] = new_speed
#==========================宠物喂食处理==========================


#==========================宠物对战结果处理==========================
    def _handle_pet_battle_result(self, client_id, message):
        """处理宠物对战结果"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "提交宠物对战结果", "pet_battle_result")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "pet_battle_result")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 获取对战结果数据
        battle_data = message.get("battle_data", {})
        winner = battle_data.get("winner", "")
        attacker_name = battle_data.get("attacker_name", "")
        defender_name = battle_data.get("defender_name", "")
        battle_type = battle_data.get("battle_type", "")
        attacker_pets = battle_data.get("attacker_pets", [])
        defender_pets = battle_data.get("defender_pets", [])
        duration = battle_data.get("duration", 0)
        timestamp = battle_data.get("timestamp", time.time())
        
        # 验证必要参数
        if not winner or not attacker_name or not defender_name:
            return self._send_action_error(client_id, "pet_battle_result", "对战结果数据不完整")
        
        # 记录对战结果到日志
        self.log('INFO', f"宠物对战结果 - 获胜方: {winner}, 攻击方: {attacker_name}, 防守方: {defender_name}, 类型: {battle_type}, 持续时间: {duration}秒", 'BATTLE')
        
        # 初始化对战历史记录
        if "对战历史" not in player_data:
            player_data["对战历史"] = []
        
        # 添加对战记录
        battle_record = {
            "获胜方": winner,
            "攻击方": attacker_name,
            "防守方": defender_name,
            "对战类型": battle_type,
            "攻击方宠物": attacker_pets,
            "防守方宠物": defender_pets,
            "持续时间": duration,
            "时间戳": timestamp,
            "日期": datetime.datetime.fromtimestamp(timestamp).strftime("%Y年%m月%d日%H时%M分%S秒")
        }
        
        player_data["对战历史"].append(battle_record)
        
        # 限制历史记录数量（保留最近100条）
        if len(player_data["对战历史"]) > 100:
            player_data["对战历史"] = player_data["对战历史"][-100:]
        
        # 更新对战统计
        if "对战统计" not in player_data:
            player_data["对战统计"] = {
                "总对战次数": 0,
                "胜利次数": 0,
                "失败次数": 0,
                "胜率": 0.0
            }
        
        stats = player_data["对战统计"]
        stats["总对战次数"] += 1
        
        if winner == username:
            stats["胜利次数"] += 1
        else:
            stats["失败次数"] += 1
        
        # 计算胜率
        if stats["总对战次数"] > 0:
            stats["胜率"] = round(stats["胜利次数"] / stats["总对战次数"] * 100, 2)
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 如果是与其他玩家的对战，也更新对方的记录
        if defender_name != username and defender_name != "系统":
            defender_data = self.load_player_data(defender_name)
            if defender_data:
                # 初始化对方的对战历史和统计
                if "对战历史" not in defender_data:
                    defender_data["对战历史"] = []
                if "对战统计" not in defender_data:
                    defender_data["对战统计"] = {
                        "总对战次数": 0,
                        "胜利次数": 0,
                        "失败次数": 0,
                        "胜率": 0.0
                    }
                
                # 添加对战记录
                defender_data["对战历史"].append(battle_record)
                
                # 限制历史记录数量
                if len(defender_data["对战历史"]) > 100:
                    defender_data["对战历史"] = defender_data["对战历史"][-100:]
                
                # 更新对战统计
                defender_stats = defender_data["对战统计"]
                defender_stats["总对战次数"] += 1
                
                if winner == defender_name:
                    defender_stats["胜利次数"] += 1
                else:
                    defender_stats["失败次数"] += 1
                
                # 计算胜率
                if defender_stats["总对战次数"] > 0:
                    defender_stats["胜率"] = round(defender_stats["胜利次数"] / defender_stats["总对战次数"] * 100, 2)
                
                # 保存对方数据
                self.save_player_data(defender_name, defender_data)
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "pet_battle_result",
            "success": True,
            "message": "对战结果已记录",
            "updated_data": {
                "对战统计": player_data["对战统计"]
            }
        })
#==========================宠物对战结果处理==========================




#==========================开垦土地处理==========================
    #处理开垦土地请求
    def _handle_dig_ground(self, client_id, message):
        """处理开垦土地请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "开垦土地", "dig_ground")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "dig_ground")
        if not player_data:
            return self.send_data(client_id, response)
        
        lot_index = message.get("lot_index", -1)
        
        # 验证地块索引
        if lot_index < 0 or lot_index >= len(player_data.get("农场土地", [])):
            return self._send_action_error(client_id, "dig_ground", "无效的地块索引")
        
        lot = player_data["农场土地"][lot_index]
        
        # 检查地块是否已开垦
        if lot.get("is_diged", False):
            return self._send_action_error(client_id, "dig_ground", "此地块已经开垦过了")
        
        # 处理开垦
        return self._process_digging(client_id, player_data, username, lot, lot_index)
    
    #辅助函数-处理土地开垦逻辑
    def _process_digging(self, client_id, player_data, username, lot, lot_index):
        """处理土地开垦逻辑"""
        
        # 计算开垦费用 - 基于已开垦地块数量
        digged_count = sum(1 for l in player_data.get("农场土地", []) if l.get("is_diged", False))
        dig_money = digged_count * 1000
        
        # 检查玩家金钱是否足够
        if player_data["钱币"] < dig_money:
            return self._send_action_error(client_id, "dig_ground", f"金钱不足，开垦此地块需要 {dig_money} 金钱")
        
        # 执行开垦操作
        player_data["钱币"] -= dig_money
        lot["is_diged"] = True
        
        # 生成开垦随机奖励
        rewards = self._generate_dig_rewards()
        
        # 应用奖励
        player_data["钱币"] += rewards["钱币"]
        player_data["经验值"] += rewards["经验值"]
        
        # 添加种子到背包
        if "种子仓库" not in player_data:
            player_data["种子仓库"] = []
        
        for seed_name, quantity in rewards["seeds"].items():
            # 查找是否已有该种子
            found = False
            for item in player_data["种子仓库"]:
                if item.get("name") == seed_name:
                    item["count"] += quantity
                    found = True
                    break
            
            # 如果没有找到，添加新种子
            if not found:
                player_data["种子仓库"].append({
                    "name": seed_name,
                    "count": quantity
                })
        
        # 检查是否升级
        self._check_level_up(player_data)
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        # 构建奖励消息
        reward_message = f"获得 {rewards['钱币']} 金钱、{rewards['经验值']} 经验"
        if rewards["seeds"]:
            seed_list = [f"{name} x{qty}" for name, qty in rewards["seeds"].items()]
            reward_message += f"、种子：{', '.join(seed_list)}"
        
        self.log('INFO', f"玩家 {username} 成功开垦地块 {lot_index}，花费 {dig_money} 金钱，{reward_message}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "dig_ground",
            "success": True,
            "message": f"成功开垦地块，花费 {dig_money} 金钱！{reward_message}",
            "updated_data": {
                "钱币": player_data["钱币"],
                "经验值": player_data["经验值"],
                "等级": player_data["等级"],
                "农场土地": player_data["农场土地"],
                "种子仓库": player_data["种子仓库"]
            }
        })
    
    #辅助函数-生成开垦土地随机奖励
    def _generate_dig_rewards(self):
        """生成开垦土地的随机奖励"""
        
        rewards = {
            "钱币": 0,
            "经验值": 0,
            "seeds": {}
        }
        
        # 随机金钱：200-500元
        rewards["钱币"] = random.randint(200, 500)
        
        # 随机经验：300-600经验
        rewards["经验值"] = random.randint(300, 600)
        
        # 随机种子：0-3种种子
        seed_types_count = random.randint(0, 3)
        
        if seed_types_count > 0:
            # 获取作物数据
            crop_data = self._load_crop_data()
            if crop_data:
                # 获取所有可购买的种子
                all_seeds = []
                for crop_name, crop_info in crop_data.items():
                    if crop_info.get("能否购买", False):
                        all_seeds.append(crop_name)
                
                if all_seeds:
                    # 随机选择种子类型
                    selected_seeds = random.sample(all_seeds, min(seed_types_count, len(all_seeds)))
                    
                    for seed_name in selected_seeds:
                        # 每种种子1-3个
                        quantity = random.randint(1, 3)
                        rewards["seeds"][seed_name] = quantity
        
        return rewards

#==========================开垦土地处理==========================




#==========================铲除作物处理==========================
    #处理铲除作物请求
    def _handle_remove_crop(self, client_id, message):
        """处理铲除作物请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "铲除作物", "remove_crop")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "remove_crop")
        if not player_data:
            return self.send_data(client_id, response)
        
        lot_index = message.get("lot_index", -1)
        
        # 验证地块索引
        if lot_index < 0 or lot_index >= len(player_data.get("农场土地", [])):
            return self._send_action_error(client_id, "remove_crop", "无效的地块索引")
        
        lot = player_data["农场土地"][lot_index]
        
        # 检查地块状态
        if not lot.get("is_planted", False) or not lot.get("crop_type", ""):
            return self._send_action_error(client_id, "remove_crop", "此地块没有种植作物")
        
        # 处理铲除
        return self._process_crop_removal(client_id, player_data, username, lot, lot_index)
    
    #辅助函数-处理铲除作物逻辑
    def _process_crop_removal(self, client_id, player_data, username, lot, lot_index):
        """处理铲除作物逻辑"""
        # 铲除费用
        removal_cost = 500
        
        # 检查玩家金钱是否足够
        if player_data["钱币"] < removal_cost:
            return self._send_action_error(client_id, "remove_crop", f"金钱不足，铲除作物需要 {removal_cost} 金钱")
        
        # 获取作物名称用于日志
        crop_type = lot.get("crop_type", "未知作物")
        
        # 执行铲除操作
        player_data["钱币"] -= removal_cost
        lot["is_planted"] = False
        lot["crop_type"] = ""
        lot["grow_time"] = 0
        lot["is_dead"] = False  # 重置死亡状态
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        self.log('INFO', f"玩家 {username} 铲除了地块 {lot_index} 的作物 {crop_type}，花费 {removal_cost} 金钱", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "remove_crop",
            "success": True,
            "message": f"成功铲除作物 {crop_type}，花费 {removal_cost} 金钱",
            "updated_data": {
                "钱币": player_data["钱币"],
                "农场土地": player_data["农场土地"]
            }
        })
    
#==========================铲除作物处理==========================




#==========================浇水作物处理==========================
    #处理浇水请求
    def _handle_water_crop(self, client_id, message):
        """处理浇水作物请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "浇水作物", "water_crop")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取当前操作用户的数据
        current_player_data, current_username, response = self._load_player_data_with_check(client_id, "water_crop")
        if not current_player_data:
            return self.send_data(client_id, response)
        
        lot_index = message.get("lot_index", -1)
        target_username = message.get("target_username", "")
        
        # 确定操作目标：如果有target_username就是访问模式，否则是自己的农场
        if target_username and target_username != current_username:
            # 访问模式：浇水别人的作物，但花自己的钱
            target_player_data = self.load_player_data(target_username)
            if not target_player_data:
                return self._send_action_error(client_id, "water_crop", f"无法找到玩家 {target_username} 的数据")
            
            # 验证地块索引
            if lot_index < 0 or lot_index >= len(target_player_data.get("农场土地", [])):
                return self._send_action_error(client_id, "water_crop", "无效的地块索引")
            
            target_lot = target_player_data["农场土地"][lot_index]
            
            # 检查地块状态
            if not target_lot.get("is_planted", False) or not target_lot.get("crop_type", ""):
                return self._send_action_error(client_id, "water_crop", "此地块没有种植作物")
            
            # 处理访问模式浇水（花自己的钱，效果作用在目标玩家作物上）
            return self._process_visiting_watering(client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index)
        else:
            # 正常模式：浇水自己的作物
            # 验证地块索引
            if lot_index < 0 or lot_index >= len(current_player_data.get("农场土地", [])):
                return self._send_action_error(client_id, "water_crop", "无效的地块索引")
            
            lot = current_player_data["农场土地"][lot_index]
            
            # 检查地块状态
            if not lot.get("is_planted", False) or not lot.get("crop_type", ""):
                return self._send_action_error(client_id, "water_crop", "此地块没有种植作物")
            
            # 处理正常浇水
            return self._process_watering(client_id, current_player_data, current_username, lot, lot_index)
    
    #辅助函数-处理浇水逻辑
    def _process_watering(self, client_id, player_data, username, lot, lot_index):
        """处理浇水逻辑"""
        # 浇水费用
        water_cost = 50
        
        # 检查玩家金钱是否足够
        if player_data["钱币"] < water_cost:
            return self._send_action_error(client_id, "water_crop", f"金钱不足，浇水需要 {water_cost} 金钱")
        
        # 检查作物是否已死亡
        if lot.get("is_dead", False):
            return self._send_action_error(client_id, "water_crop", "死亡的作物无法浇水")
        
        # 检查是否已经成熟
        if lot["grow_time"] >= lot["max_grow_time"]:
            return self._send_action_error(client_id, "water_crop", "作物已经成熟，无需浇水")
        
        # 检查是否在1小时内已经浇过水（3600秒 = 1小时）
        current_time = time.time()
        last_water_time = lot.get("浇水时间", 0)
        water_cooldown = 3600  # 1小时冷却时间
        
        if current_time - last_water_time < water_cooldown:
            remaining_time = water_cooldown - (current_time - last_water_time)
            remaining_minutes = int(remaining_time // 60)
            remaining_seconds = int(remaining_time % 60)
            return self._send_action_error(client_id, "water_crop", f"浇水冷却中，还需等待 {remaining_minutes} 分钟 {remaining_seconds} 秒")
        
        # 执行浇水操作
        player_data["钱币"] -= water_cost
        
        # 生成随机经验奖励（100-300）
        experience_reward = random.randint(100, 300)
        player_data["经验值"] += experience_reward
        
        # 检查是否升级
        self._check_level_up(player_data)
        
        # 计算浇水效果：增加1%的生长进度
        growth_increase = int(lot["max_grow_time"] * 0.01)  # 1%的生长时间
        if growth_increase < 1:
            growth_increase = 1  # 至少增加1秒
        
        lot["grow_time"] += growth_increase
        
        # 确保不超过最大生长时间
        if lot["grow_time"] > lot["max_grow_time"]:
            lot["grow_time"] = lot["max_grow_time"]
        
        # 记录浇水时间戳
        lot["浇水时间"] = current_time
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        crop_type = lot.get("crop_type", "未知作物")
        progress = (lot["grow_time"] / lot["max_grow_time"]) * 100
        
        self.log('INFO', f"玩家 {username} 给地块 {lot_index} 的 {crop_type} 浇水，花费 {water_cost} 金钱，获得 {experience_reward} 经验，生长进度: {progress:.1f}%", 'SERVER')
        
        message = f"浇水成功！{crop_type} 生长了 {growth_increase} 秒，当前进度: {progress:.1f}%，获得 {experience_reward} 经验"
        if lot["grow_time"] >= lot["max_grow_time"]:
            message += "，作物已成熟！"
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "water_crop",
            "success": True,
            "message": message,
            "updated_data": {
                "钱币": player_data["钱币"],
                "经验值": player_data["经验值"],
                "等级": player_data["等级"],
                "农场土地": player_data["农场土地"]
            }
        })
    
    #处理访问模式浇水逻辑
    def _process_visiting_watering(self, client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index):
        """处理访问模式浇水逻辑（花自己的钱，效果作用在目标玩家作物上）"""
        # 浇水费用
        water_cost = 50
        
        # 检查当前玩家金钱是否足够
        if current_player_data["钱币"] < water_cost:
            return self._send_action_error(client_id, "water_crop", f"金钱不足，帮助浇水需要 {water_cost} 金钱")
        
        # 检查目标作物是否已死亡
        if target_lot.get("is_dead", False):
            return self._send_action_error(client_id, "water_crop", "死亡的作物无法浇水")
        
        # 检查是否已经成熟
        if target_lot["grow_time"] >= target_lot["max_grow_time"]:
            return self._send_action_error(client_id, "water_crop", "作物已经成熟，无需浇水")
        
        # 检查是否在1小时内已经浇过水
        current_time = time.time()
        last_water_time = target_lot.get("浇水时间", 0)
        water_cooldown = 3600  # 1小时冷却时间
        
        if current_time - last_water_time < water_cooldown:
            remaining_time = water_cooldown - (current_time - last_water_time)
            remaining_minutes = int(remaining_time // 60)
            remaining_seconds = int(remaining_time % 60)
            return self._send_action_error(client_id, "water_crop", f"浇水冷却中，还需等待 {remaining_minutes} 分钟 {remaining_seconds} 秒")
        
        # 执行浇水操作：扣除当前玩家的钱
        current_player_data["钱币"] -= water_cost
        
        # 生成随机经验奖励（100-300）给当前玩家
        experience_reward = random.randint(100, 300)
        current_player_data["经验值"] += experience_reward
        
        # 检查当前玩家是否升级
        self._check_level_up(current_player_data)
        
        # 计算浇水效果：增加目标作物的生长进度
        growth_increase = int(target_lot["max_grow_time"] * 0.01)  # 1%的生长时间
        if growth_increase < 1:
            growth_increase = 1  # 至少增加1秒
        
        target_lot["grow_time"] += growth_increase
        
        # 确保不超过最大生长时间
        if target_lot["grow_time"] > target_lot["max_grow_time"]:
            target_lot["grow_time"] = target_lot["max_grow_time"]
        
        # 记录浇水时间戳
        target_lot["浇水时间"] = current_time
        
        # 保存两个玩家的数据
        self.save_player_data(current_username, current_player_data)
        self.save_player_data(target_username, target_player_data)
        
        # 向目标玩家推送作物更新（如果在线）
        self._push_crop_update_to_player(target_username, target_player_data)
        
        crop_type = target_lot.get("crop_type", "未知作物")
        progress = (target_lot["grow_time"] / target_lot["max_grow_time"]) * 100
        
        self.log('INFO', f"玩家 {current_username} 帮助玩家 {target_username} 给地块 {lot_index} 的 {crop_type} 浇水，花费 {water_cost} 金钱，获得 {experience_reward} 经验，生长进度: {progress:.1f}%", 'SERVER')
        
        message = f"帮助浇水成功！{target_username} 的 {crop_type} 生长了 {growth_increase} 秒，当前进度: {progress:.1f}%，获得 {experience_reward} 经验"
        if target_lot["grow_time"] >= target_lot["max_grow_time"]:
            message += "，作物已成熟！"
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "water_crop",
            "success": True,
            "message": message,
            "updated_data": {
                "钱币": current_player_data["钱币"],
                "经验值": current_player_data["经验值"],
                "等级": current_player_data["等级"]
            }
        })
    
#==========================浇水作物处理==========================



#==========================施肥作物处理==========================
    #处理施肥请求
    def _handle_fertilize_crop(self, client_id, message):
        """处理施肥作物请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "施肥作物", "fertilize_crop")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取当前操作用户的数据
        current_player_data, current_username, response = self._load_player_data_with_check(client_id, "fertilize_crop")
        if not current_player_data:
            return self.send_data(client_id, response)
        
        lot_index = message.get("lot_index", -1)
        target_username = message.get("target_username", "")
        
        # 确定操作目标：如果有target_username就是访问模式，否则是自己的农场
        if target_username and target_username != current_username:
            # 访问模式：施肥别人的作物，但花自己的钱
            target_player_data = self.load_player_data(target_username)
            if not target_player_data:
                return self._send_action_error(client_id, "fertilize_crop", f"无法找到玩家 {target_username} 的数据")
            
            # 验证地块索引
            if lot_index < 0 or lot_index >= len(target_player_data.get("农场土地", [])):
                return self._send_action_error(client_id, "fertilize_crop", "无效的地块索引")
            
            target_lot = target_player_data["农场土地"][lot_index]
            
            # 检查地块状态
            if not target_lot.get("is_planted", False) or not target_lot.get("crop_type", ""):
                return self._send_action_error(client_id, "fertilize_crop", "此地块没有种植作物")
            
            # 处理访问模式施肥
            return self._process_visiting_fertilizing(client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index)
        else:
            # 正常模式：施肥自己的作物
            # 验证地块索引
            if lot_index < 0 or lot_index >= len(current_player_data.get("农场土地", [])):
                return self._send_action_error(client_id, "fertilize_crop", "无效的地块索引")
            
            lot = current_player_data["农场土地"][lot_index]
            
            # 检查地块状态
            if not lot.get("is_planted", False) or not lot.get("crop_type", ""):
                return self._send_action_error(client_id, "fertilize_crop", "此地块没有种植作物")
            
            # 处理正常施肥
            return self._process_fertilizing(client_id, current_player_data, current_username, lot, lot_index)

    #辅助函数-处理访问模式施肥逻辑
    def _process_visiting_fertilizing(self, client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index):
        """处理访问模式施肥逻辑（花自己的钱，效果作用在目标玩家作物上）"""
        # 施肥费用
        fertilize_cost = 150
        
        # 检查当前玩家金钱是否足够
        if current_player_data["钱币"] < fertilize_cost:
            return self._send_action_error(client_id, "fertilize_crop", f"金钱不足，帮助施肥需要 {fertilize_cost} 金钱")
        
        # 检查目标作物是否已死亡
        if target_lot.get("is_dead", False):
            return self._send_action_error(client_id, "fertilize_crop", "死亡的作物无法施肥")
        
        # 检查是否已经成熟
        if target_lot["grow_time"] >= target_lot["max_grow_time"]:
            return self._send_action_error(client_id, "fertilize_crop", "作物已经成熟，无需施肥")
        
        # 检查是否已经施过肥
        if target_lot.get("已施肥", False):
            return self._send_action_error(client_id, "fertilize_crop", "此作物已经施过肥了")
        
        # 执行施肥操作：扣除当前玩家的钱
        current_player_data["钱币"] -= fertilize_cost
        
        # 生成随机经验奖励（100-300）给当前玩家
        experience_reward = random.randint(100, 300)
        current_player_data["经验值"] += experience_reward
        
        # 检查当前玩家是否升级
        self._check_level_up(current_player_data)
        
        # 标记目标作物已施肥，施肥效果会在作物生长更新时生效
        target_lot["已施肥"] = True
        
        # 记录施肥时间戳，用于计算10分钟的双倍生长效果
        target_lot["施肥时间"] = time.time()
        
        # 保存两个玩家的数据
        self.save_player_data(current_username, current_player_data)
        self.save_player_data(target_username, target_player_data)
        
        # 向目标玩家推送作物更新（如果在线）
        self._push_crop_update_to_player(target_username, target_player_data)
        
        crop_type = target_lot.get("crop_type", "未知作物")
        
        self.log('INFO', f"玩家 {current_username} 帮助玩家 {target_username} 给地块 {lot_index} 的 {crop_type} 施肥，花费 {fertilize_cost} 金钱，获得 {experience_reward} 经验", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "fertilize_crop",
            "success": True,
            "message": f"帮助施肥成功！{target_username} 的 {crop_type} 将在10分钟内以双倍速度生长，获得 {experience_reward} 经验",
            "updated_data": {
                "钱币": current_player_data["钱币"],
                "经验值": current_player_data["经验值"],
                "等级": current_player_data["等级"]
            }
        })
    
    #辅助函数-处理施肥逻辑
    def _process_fertilizing(self, client_id, player_data, username, lot, lot_index):
        """处理施肥逻辑"""
        # 施肥费用
        fertilize_cost = 150
        
        # 检查玩家金钱是否足够
        if player_data["钱币"] < fertilize_cost:
            return self._send_action_error(client_id, "fertilize_crop", f"金钱不足，施肥需要 {fertilize_cost} 金钱")
        
        # 检查作物是否已死亡
        if lot.get("is_dead", False):
            return self._send_action_error(client_id, "fertilize_crop", "死亡的作物无法施肥")
        
        # 检查是否已经成熟
        if lot["grow_time"] >= lot["max_grow_time"]:
            return self._send_action_error(client_id, "fertilize_crop", "作物已经成熟，无需施肥")
        
        # 检查是否已经施过肥
        if lot.get("已施肥", False):
            return self._send_action_error(client_id, "fertilize_crop", "此作物已经施过肥了")
        
        # 执行施肥操作
        player_data["钱币"] -= fertilize_cost
        
        # 生成随机经验奖励（100-300）
        experience_reward = random.randint(100, 300)
        player_data["经验值"] += experience_reward
        
        # 检查是否升级
        self._check_level_up(player_data)
        
        # 标记已施肥，施肥效果会在作物生长更新时生效
        lot["已施肥"] = True
        
        # 记录施肥时间戳，用于计算10分钟的双倍生长效果
        lot["施肥时间"] = time.time()
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        crop_type = lot.get("crop_type", "未知作物")
        
        self.log('INFO', f"玩家 {username} 给地块 {lot_index} 的 {crop_type} 施肥，花费 {fertilize_cost} 金钱，获得 {experience_reward} 经验", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "fertilize_crop",
            "success": True,
            "message": f"施肥成功！{crop_type} 将在10分钟内以双倍速度生长，获得 {experience_reward} 经验",
            "updated_data": {
                "钱币": player_data["钱币"],
                "经验值": player_data["经验值"],
                "等级": player_data["等级"],
                "农场土地": player_data["农场土地"]
            }
        })
    
#==========================施肥作物处理==========================



#==========================购买道具处理==========================
    #处理购买道具请求
    def _handle_buy_item(self, client_id, message):
        """处理购买道具请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "购买道具", "buy_item")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "buy_item")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 解析请求参数
        item_name = message.get("item_name", "")
        item_cost = message.get("item_cost", 0)
        quantity = max(1, int(message.get("quantity", 1)))  # 确保购买数量为正整数
        
        # 验证道具配置
        item_config = self._load_item_config()
        if not item_config:
            return self._send_action_error(client_id, "buy_item", "服务器无法加载道具数据")
        
        if item_name not in item_config:
            return self._send_action_error(client_id, "buy_item", "该道具不存在")
        
        # 验证价格
        actual_cost = item_config[item_name].get("花费", 0)
        if item_cost != actual_cost:
            return self._send_action_error(client_id, "buy_item", f"道具价格验证失败，实际价格为{actual_cost}元")
        
        # 处理购买
        return self._process_item_purchase(client_id, player_data, username, item_name, item_config[item_name], quantity)
    
    #处理道具购买逻辑
    def _process_item_purchase(self, client_id, player_data, username, item_name, item_info, quantity=1):
        """处理道具购买逻辑"""
        unit_cost = item_info.get("花费", 0)
        total_cost = unit_cost * quantity
        
        # 检查金钱是否足够
        if player_data["钱币"] < total_cost:
            return self._send_action_error(client_id, "buy_item", 
                f"金钱不足，需要{total_cost}元，当前只有{player_data['money']}元")
        
        # 扣除金钱并添加道具
        player_data["钱币"] -= total_cost
        self._add_item_to_inventory(player_data, item_name, quantity)
        
        # 保存数据并记录日志
        self.save_player_data(username, player_data)
        self.log('INFO', f"玩家 {username} 购买了 {quantity} 个道具 {item_name}，花费 {total_cost} 元", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "buy_item",
            "success": True,
            "message": f"成功购买 {quantity} 个 {item_name}",
            "updated_data": {
                "钱币": player_data["钱币"],
                "道具背包": player_data["道具背包"]
            }
        })
    
    def _add_item_to_inventory(self, player_data, item_name, quantity):
        """将道具添加到玩家背包"""
        if "道具背包" not in player_data:
            player_data["道具背包"] = []
        
        # 查找是否已有该道具
        for item in player_data["道具背包"]:
            if item.get("name") == item_name:
                item["count"] += quantity
                return
        
        # 添加新道具
        player_data["道具背包"].append({
            "name": item_name,
            "count": quantity
        })
    
    #加载道具配置数据
    def _load_item_config(self):
        """从MongoDB加载道具配置数据"""
        if not self.mongo_api or not self.mongo_api.is_connected():
            self.log('ERROR', 'MongoDB未配置或不可用，无法加载道具配置数据', 'SERVER')
            return {}
            
        try:
            config = self.mongo_api.get_item_config()
            if config:
                self.log('INFO', '成功从MongoDB加载道具配置', 'SERVER')
                return config
            else:
                self.log('ERROR', 'MongoDB中未找到道具配置', 'SERVER')
                return {}
        except Exception as e:
            self.log('ERROR', f'从MongoDB加载道具配置失败: {e}', 'SERVER')
            return {}
#==========================购买道具处理==========================



#==========================道具使用处理==========================
    def _handle_use_item(self, client_id, message):
        """处理使用道具请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "使用道具", "use_item")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "use_item")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 解析请求参数
        lot_index = message.get("lot_index", -1)
        item_name = message.get("item_name", "")
        use_type = message.get("use_type", "")
        target_username = message.get("target_username", "")
        
        # 验证参数
        if not item_name or not use_type:
            return self._send_action_error(client_id, "use_item", "道具名称和使用类型不能为空")
        
        # 检查玩家是否拥有该道具
        if not self._has_item_in_inventory(player_data, item_name):
            return self._send_action_error(client_id, "use_item", f"您没有 {item_name}")
        
        # 确定操作目标并处理
        if target_username and target_username != username:
            # 访问模式：对别人的作物使用道具
            return self._handle_visiting_item_use(client_id, player_data, username, target_username, lot_index, item_name, use_type)
        else:
            # 正常模式：对自己的作物使用道具
            return self._handle_normal_item_use(client_id, player_data, username, lot_index, item_name, use_type)
    
    def _handle_normal_item_use(self, client_id, player_data, username, lot_index, item_name, use_type):
        """处理正常模式下的道具使用"""
        if lot_index < 0 or lot_index >= len(player_data.get("农场土地", [])):
            return self._send_action_error(client_id, "use_item", "无效的地块索引")
        
        lot = player_data["农场土地"][lot_index]
        return self._process_item_use_normal(client_id, player_data, username, lot, lot_index, item_name, use_type)
    
    def _handle_visiting_item_use(self, client_id, player_data, username, target_username, lot_index, item_name, use_type):
        """处理访问模式下的道具使用"""
        target_player_data = self.load_player_data(target_username)
        if not target_player_data:
            return self._send_action_error(client_id, "use_item", f"无法找到玩家 {target_username} 的数据")
        
        if lot_index < 0 or lot_index >= len(target_player_data.get("农场土地", [])):
            return self._send_action_error(client_id, "use_item", "无效的地块索引")
        
        target_lot = target_player_data["农场土地"][lot_index]
        return self._process_item_use_visiting(client_id, player_data, username, target_player_data, target_username, target_lot, lot_index, item_name, use_type)
    
    def _has_item_in_inventory(self, player_data, item_name):
        """检查玩家是否拥有指定道具"""
        item_bag = player_data.get("道具背包", [])
        for item in item_bag:
            if item.get("name", "") == item_name and item.get("count", 0) > 0:
                return True
        return False
    
    def _remove_item_from_inventory(self, player_data, item_name, count=1):
        """从玩家道具背包中移除指定数量的道具"""
        item_bag = player_data.get("道具背包", [])
        for i, item in enumerate(item_bag):
            if item.get("name", "") == item_name and item.get("count", 0) >= count:
                item["count"] -= count
                if item["count"] <= 0:
                    item_bag.pop(i)
                return True
        return False
    
    def _process_item_use_normal(self, client_id, player_data, username, lot, lot_index, item_name, use_type):
        """处理正常模式下的道具使用"""
        # 检查地块状态
        if not lot.get("is_planted", False) or not lot.get("crop_type", ""):
            return self._send_action_error(client_id, "use_item", "此地块没有种植作物")
        
        # 检查作物是否已死亡
        if lot.get("is_dead", False):
            return self._send_action_error(client_id, "use_item", "死亡的作物无法使用道具")
        
        # 根据使用类型和道具名称执行不同逻辑
        if use_type == "fertilize":
            # 检查是否已经成熟（施肥道具需要检查）
            if lot.get("grow_time", 0) >= lot.get("max_grow_time", 1):
                return self._send_action_error(client_id, "use_item", "作物已经成熟，无需施肥")
            return self._use_fertilizer_item(client_id, player_data, username, lot, lot_index, item_name)
        elif use_type == "water":
            # 检查是否已经成熟（浇水道具需要检查）
            if lot.get("grow_time", 0) >= lot.get("max_grow_time", 1):
                return self._send_action_error(client_id, "use_item", "作物已经成熟，无需浇水")
            return self._use_watering_item(client_id, player_data, username, lot, lot_index, item_name)
        elif use_type == "remove":
            # 铲子可以清除任何作物，包括成熟的
            return self._use_removal_item(client_id, player_data, username, lot, lot_index, item_name)
        elif use_type == "weed_killer":
            # 除草剂可以清除任何杂草，包括成熟的
            return self._use_weed_killer_item(client_id, player_data, username, lot, lot_index, item_name)
        elif use_type == "harvest":
            # 采集道具只能对成熟的作物使用
            if lot.get("grow_time", 0) < lot.get("max_grow_time", 1):
                return self._send_action_error(client_id, "use_item", "作物还未成熟，无法使用采集道具")
            return self._use_harvest_item(client_id, player_data, username, lot, lot_index, item_name)
        else:
            return self._send_action_error(client_id, "use_item", f"不支持的使用类型: {use_type}")
    
    def _process_item_use_visiting(self, client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index, item_name, use_type):
        """处理访问模式下的道具使用"""
        # 检查地块状态
        if not target_lot.get("is_planted", False) or not target_lot.get("crop_type", ""):
            return self._send_action_error(client_id, "use_item", "此地块没有种植作物")
        
        # 检查作物是否已死亡
        if target_lot.get("is_dead", False):
            return self._send_action_error(client_id, "use_item", "死亡的作物无法使用道具")
        
        # 根据使用类型和道具名称执行不同逻辑
        if use_type == "fertilize":
            # 检查是否已经成熟（施肥道具需要检查）
            if target_lot.get("grow_time", 0) >= target_lot.get("max_grow_time", 1):
                return self._send_action_error(client_id, "use_item", "作物已经成熟，无需施肥")
            return self._use_fertilizer_item_visiting(client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index, item_name)
        elif use_type == "water":
            # 检查是否已经成熟（浇水道具需要检查）
            if target_lot.get("grow_time", 0) >= target_lot.get("max_grow_time", 1):
                return self._send_action_error(client_id, "use_item", "作物已经成熟，无需浇水")
            return self._use_watering_item_visiting(client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index, item_name)
        elif use_type == "remove":
            # 铲子可以清除任何作物，包括成熟的
            return self._use_removal_item_visiting(client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index, item_name)
        elif use_type == "weed_killer":
            # 除草剂可以清除任何杂草，包括成熟的
            return self._use_weed_killer_item_visiting(client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index, item_name)
        elif use_type == "harvest":
            # 采集道具只能对成熟的作物使用
            if target_lot.get("grow_time", 0) < target_lot.get("max_grow_time", 1):
                return self._send_action_error(client_id, "use_item", "作物还未成熟，无法使用采集道具")
            return self._use_harvest_item_visiting(client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index, item_name)
        else:
            return self._send_action_error(client_id, "use_item", f"不支持的使用类型: {use_type}")
    
    def _use_fertilizer_item(self, client_id, player_data, username, lot, lot_index, item_name):
        """使用施肥类道具"""
        # 检查是否已经施过肥
        if lot.get("已施肥", False):
            return self._send_action_error(client_id, "use_item", "此作物已经施过肥了")
        
        # 移除道具
        if not self._remove_item_from_inventory(player_data, item_name, 1):
            return self._send_action_error(client_id, "use_item", f"移除道具 {item_name} 失败")
        
        # 生成随机经验奖励
        experience_reward = random.randint(50, 150)
        player_data["经验值"] += experience_reward
        
        # 检查是否升级
        self._check_level_up(player_data)
        
        # 根据道具类型设置不同的施肥效果
        current_time = time.time()
        
        if item_name == "农家肥":
            # 30分钟内额外+1秒/次生长
            lot["已施肥"] = True
            lot["施肥时间"] = current_time
            lot["施肥类型"] = "农家肥"
            lot["施肥加成"] = 1
            lot["施肥持续时间"] = 1800  # 30分钟
            message = f"使用 {item_name} 成功！作物将在30分钟内获得额外生长加成"
        elif item_name == "金坷垃":
            # 5分钟内额外+4秒/次生长
            lot["已施肥"] = True
            lot["施肥时间"] = current_time
            lot["施肥类型"] = "金坷垃"
            lot["施肥加成"] = 4
            lot["施肥持续时间"] = 300  # 5分钟
            message = f"使用 {item_name} 成功！作物将在5分钟内获得强力生长加成"
        elif item_name == "生长素":
            # 10分钟内额外+2秒/次生长
            lot["已施肥"] = True
            lot["施肥时间"] = current_time
            lot["施肥类型"] = "生长素"
            lot["施肥加成"] = 2
            lot["施肥持续时间"] = 600  # 10分钟
            message = f"使用 {item_name} 成功！作物将在10分钟内获得中等生长加成"
        else:
            return self._send_action_error(client_id, "use_item", f"不支持的施肥道具: {item_name}")
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        crop_type = lot.get("crop_type", "未知作物")
        self.log('INFO', f"玩家 {username} 对地块 {lot_index} 的 {crop_type} 使用了 {item_name}，获得 {experience_reward} 经验", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "use_item",
            "success": True,
            "message": f"{message}，获得 {experience_reward} 经验",
            "updated_data": {
                "经验值": player_data["经验值"],
                "等级": player_data["等级"],
                "农场土地": player_data["农场土地"],
                "道具背包": player_data["道具背包"]
            }
        })
    
    def _use_watering_item(self, client_id, player_data, username, lot, lot_index, item_name):
        """使用浇水类道具"""
        # 移除道具
        if not self._remove_item_from_inventory(player_data, item_name, 1):
            return self._send_action_error(client_id, "use_item", f"移除道具 {item_name} 失败")
        
        # 生成随机经验奖励
        experience_reward = random.randint(30, 100)
        player_data["经验值"] += experience_reward
        
        # 检查是否升级
        self._check_level_up(player_data)
        
        # 根据道具类型计算浇水效果
        if item_name == "水壶":
            # 增加1%的生长进度
            growth_increase = int(lot["max_grow_time"] * 0.01)
            message = f"使用 {item_name} 成功！作物生长进度增加了1%"
        elif item_name == "水桶":
            # 增加2%的生长进度
            growth_increase = int(lot["max_grow_time"] * 0.02)
            message = f"使用 {item_name} 成功！作物生长进度增加了2%"
        else:
            return self._send_action_error(client_id, "use_item", f"不支持的浇水道具: {item_name}")
        
        if growth_increase < 1:
            growth_increase = 1  # 至少增加1秒
        
        lot["grow_time"] += growth_increase
        
        # 确保不超过最大生长时间
        if lot["grow_time"] > lot["max_grow_time"]:
            lot["grow_time"] = lot["max_grow_time"]
        
        # 记录浇水时间戳
        lot["浇水时间"] = time.time()
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        crop_type = lot.get("crop_type", "未知作物")
        progress = (lot["grow_time"] / lot["max_grow_time"]) * 100
        
        self.log('INFO', f"玩家 {username} 对地块 {lot_index} 的 {crop_type} 使用了 {item_name}，生长进度: {progress:.1f}%，获得 {experience_reward} 经验", 'SERVER')
        
        final_message = f"{message}，当前进度: {progress:.1f}%，获得 {experience_reward} 经验"
        if lot["grow_time"] >= lot["max_grow_time"]:
            final_message += "，作物已成熟！"
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "use_item",
            "success": True,
            "message": final_message,
            "updated_data": {
                "经验值": player_data["经验值"],
                "等级": player_data["等级"],
                "农场土地": player_data["农场土地"],
                "道具背包": player_data["道具背包"]
            }
        })
    
    def _use_fertilizer_item_visiting(self, client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index, item_name):
        """访问模式下使用施肥类道具"""
        # 检查是否已经施过肥
        if target_lot.get("已施肥", False):
            return self._send_action_error(client_id, "use_item", "此作物已经施过肥了")
        
        # 移除当前玩家的道具
        if not self._remove_item_from_inventory(current_player_data, item_name, 1):
            return self._send_action_error(client_id, "use_item", f"移除道具 {item_name} 失败")
        
        # 生成随机经验奖励给当前玩家
        experience_reward = random.randint(50, 150)
        current_player_data["经验值"] += experience_reward
        
        # 检查当前玩家是否升级
        self._check_level_up(current_player_data)
        
        # 根据道具类型设置不同的施肥效果
        current_time = time.time()
        
        if item_name == "农家肥":
            # 30分钟内额外+1秒/次生长
            target_lot["已施肥"] = True
            target_lot["施肥时间"] = current_time
            target_lot["施肥类型"] = "农家肥"
            target_lot["施肥加成"] = 1
            target_lot["施肥持续时间"] = 1800  # 30分钟
            message = f"帮助施肥成功！{target_username} 的作物将在30分钟内获得额外生长加成"
        elif item_name == "金坷垃":
            # 5分钟内额外+4秒/次生长
            target_lot["已施肥"] = True
            target_lot["施肥时间"] = current_time
            target_lot["施肥类型"] = "金坷垃"
            target_lot["施肥加成"] = 4
            target_lot["施肥持续时间"] = 300  # 5分钟
            message = f"帮助施肥成功！{target_username} 的作物将在5分钟内获得强力生长加成"
        elif item_name == "生长素":
            # 10分钟内额外+2秒/次生长
            target_lot["已施肥"] = True
            target_lot["施肥时间"] = current_time
            target_lot["施肥类型"] = "生长素"
            target_lot["施肥加成"] = 2
            target_lot["施肥持续时间"] = 600  # 10分钟
            message = f"帮助施肥成功！{target_username} 的作物将在10分钟内获得中等生长加成"
        else:
            return self._send_action_error(client_id, "use_item", f"不支持的施肥道具: {item_name}")
        
        # 保存两个玩家的数据
        self.save_player_data(current_username, current_player_data)
        self.save_player_data(target_username, target_player_data)
        
        # 向目标玩家推送作物更新
        self._push_crop_update_to_player(target_username, target_player_data)
        
        crop_type = target_lot.get("crop_type", "未知作物")
        self.log('INFO', f"玩家 {current_username} 帮助玩家 {target_username} 对地块 {lot_index} 的 {crop_type} 使用了 {item_name}，获得 {experience_reward} 经验", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "use_item",
            "success": True,
            "message": f"{message}，获得 {experience_reward} 经验",
            "updated_data": {
                "经验值": current_player_data["经验值"],
                "等级": current_player_data["等级"],
                "道具背包": current_player_data["道具背包"]
            }
        })
    
    def _use_watering_item_visiting(self, client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index, item_name):
        """访问模式下使用浇水类道具"""
        # 移除当前玩家的道具
        if not self._remove_item_from_inventory(current_player_data, item_name, 1):
            return self._send_action_error(client_id, "use_item", f"移除道具 {item_name} 失败")
        
        # 生成随机经验奖励给当前玩家
        experience_reward = random.randint(30, 100)
        current_player_data["经验值"] += experience_reward
        
        # 检查当前玩家是否升级
        self._check_level_up(current_player_data)
        
        # 根据道具类型计算浇水效果
        if item_name == "水壶":
            # 增加1%的生长进度
            growth_increase = int(target_lot["max_grow_time"] * 0.01)
            message = f"帮助浇水成功！{target_username} 的作物生长进度增加了1%"
        elif item_name == "水桶":
            # 增加2%的生长进度
            growth_increase = int(target_lot["max_grow_time"] * 0.02)
            message = f"帮助浇水成功！{target_username} 的作物生长进度增加了2%"
        else:
            return self._send_action_error(client_id, "use_item", f"不支持的浇水道具: {item_name}")
        
        if growth_increase < 1:
            growth_increase = 1  # 至少增加1秒
        
        target_lot["grow_time"] += growth_increase
        
        # 确保不超过最大生长时间
        if target_lot["grow_time"] > target_lot["max_grow_time"]:
            target_lot["grow_time"] = target_lot["max_grow_time"]
        
        # 记录浇水时间戳
        target_lot["浇水时间"] = time.time()
        
        # 保存两个玩家的数据
        self.save_player_data(current_username, current_player_data)
        self.save_player_data(target_username, target_player_data)
        
        # 向目标玩家推送作物更新
        self._push_crop_update_to_player(target_username, target_player_data)
        
        crop_type = target_lot.get("crop_type", "未知作物")
        progress = (target_lot["grow_time"] / target_lot["max_grow_time"]) * 100
        
        self.log('INFO', f"玩家 {current_username} 帮助玩家 {target_username} 对地块 {lot_index} 的 {crop_type} 使用了 {item_name}，生长进度: {progress:.1f}%，获得 {experience_reward} 经验", 'SERVER')
        
        final_message = f"{message}，当前进度: {progress:.1f}%，获得 {experience_reward} 经验"
        if target_lot["grow_time"] >= target_lot["max_grow_time"]:
            final_message += "，作物已成熟！"
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "use_item",
            "success": True,
            "message": final_message,
            "updated_data": {
                "经验值": current_player_data["经验值"],
                "等级": current_player_data["等级"],
                "道具背包": current_player_data["道具背包"]
            }
        })
    
    def _use_removal_item(self, client_id, player_data, username, lot, lot_index, item_name):
        """使用铲除类道具（铲子）"""
        # 检查玩家是否有这个道具
        if not self._has_item_in_inventory(player_data, item_name):
            return self._send_action_error(client_id, "use_item", f"您没有 {item_name}")
        
        # 移除道具
        if not self._remove_item_from_inventory(player_data, item_name, 1):
            return self._send_action_error(client_id, "use_item", f"移除道具 {item_name} 失败")
        
        # 生成随机经验奖励
        experience_reward = random.randint(20, 60)
        player_data["经验值"] += experience_reward
        
        # 检查是否升级
        self._check_level_up(player_data)
        
        # 获取作物名称用于日志
        crop_type = lot.get("crop_type", "未知作物")
        
        # 执行铲除操作
        lot["is_planted"] = False
        lot["crop_type"] = ""
        lot["grow_time"] = 0
        lot["is_dead"] = False  # 重置死亡状态
        lot["已浇水"] = False  # 重置浇水状态
        lot["已施肥"] = False  # 重置施肥状态
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        self.log('INFO', f"玩家 {username} 使用 {item_name} 铲除了地块 {lot_index} 的作物 {crop_type}，获得 {experience_reward} 经验", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "use_item",
            "success": True,
            "message": f"使用 {item_name} 成功铲除作物 {crop_type}，获得 {experience_reward} 经验",
            "updated_data": {
                "经验值": player_data["经验值"],
                "等级": player_data["等级"],
                "农场土地": player_data["农场土地"],
                "道具背包": player_data["道具背包"]
            }
        })
    
    def _use_weed_killer_item(self, client_id, player_data, username, lot, lot_index, item_name):
        """使用除草剂"""
        # 检查是否为杂草
        crop_type = lot.get("crop_type", "")
        crop_data = self._load_crop_data()
        
        if not crop_data or crop_type not in crop_data:
            return self._send_action_error(client_id, "use_item", f"未知的作物类型: {crop_type}")
        
        is_weed = crop_data[crop_type].get("是否杂草", False)
        if not is_weed:
            return self._send_action_error(client_id, "use_item", "除草剂只能用于清除杂草，此作物不是杂草")
        
        # 检查玩家是否有这个道具
        if not self._has_item_in_inventory(player_data, item_name):
            return self._send_action_error(client_id, "use_item", f"您没有 {item_name}")
        
        # 移除道具
        if not self._remove_item_from_inventory(player_data, item_name, 1):
            return self._send_action_error(client_id, "use_item", f"移除道具 {item_name} 失败")
        
        # 生成随机经验奖励
        experience_reward = random.randint(15, 50)
        player_data["经验值"] += experience_reward
        
        # 检查是否升级
        self._check_level_up(player_data)
        
        # 执行除草操作
        lot["is_planted"] = False
        lot["crop_type"] = ""
        lot["grow_time"] = 0
        lot["is_dead"] = False  # 重置死亡状态
        lot["已浇水"] = False  # 重置浇水状态
        lot["已施肥"] = False  # 重置施肥状态
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        self.log('INFO', f"玩家 {username} 使用 {item_name} 清除了地块 {lot_index} 的杂草 {crop_type}，获得 {experience_reward} 经验", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "use_item",
            "success": True,
            "message": f"使用 {item_name} 成功清除杂草 {crop_type}，获得 {experience_reward} 经验",
            "updated_data": {
                "经验值": player_data["经验值"],
                "等级": player_data["等级"],
                "农场土地": player_data["农场土地"],
                "道具背包": player_data["道具背包"]
            }
        })
    
    def _use_removal_item_visiting(self, client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index, item_name):
        """访问模式下使用铲除道具"""
        # 检查当前玩家是否有这个道具
        if not self._has_item_in_inventory(current_player_data, item_name):
            return self._send_action_error(client_id, "use_item", f"您没有 {item_name}")
        
        # 移除当前玩家的道具
        if not self._remove_item_from_inventory(current_player_data, item_name, 1):
            return self._send_action_error(client_id, "use_item", f"移除道具 {item_name} 失败")
        
        # 生成随机经验奖励给当前玩家
        experience_reward = random.randint(20, 60)
        current_player_data["经验值"] += experience_reward
        
        # 检查当前玩家是否升级
        self._check_level_up(current_player_data)
        
        # 获取作物名称用于日志
        crop_type = target_lot.get("crop_type", "未知作物")
        
        # 执行铲除操作
        target_lot["is_planted"] = False
        target_lot["crop_type"] = ""
        target_lot["grow_time"] = 0
        target_lot["is_dead"] = False  # 重置死亡状态
        target_lot["已浇水"] = False  # 重置浇水状态
        target_lot["已施肥"] = False  # 重置施肥状态
        
        # 保存两个玩家的数据
        self.save_player_data(current_username, current_player_data)
        self.save_player_data(target_username, target_player_data)
        
        # 向目标玩家推送作物更新
        self._push_crop_update_to_player(target_username, target_player_data)
        
        self.log('INFO', f"玩家 {current_username} 帮助玩家 {target_username} 使用 {item_name} 铲除了地块 {lot_index} 的作物 {crop_type}，获得 {experience_reward} 经验", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "use_item",
            "success": True,
            "message": f"帮助 {target_username} 铲除作物 {crop_type} 成功，获得 {experience_reward} 经验",
            "updated_data": {
                "经验值": current_player_data["经验值"],
                "等级": current_player_data["等级"],
                "道具背包": current_player_data["道具背包"]
            }
        })
    
    def _use_weed_killer_item_visiting(self, client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index, item_name):
        """访问模式下使用除草剂"""
        # 检查是否为杂草
        crop_type = target_lot.get("crop_type", "")
        crop_data = self._load_crop_data()
        
        if not crop_data or crop_type not in crop_data:
            return self._send_action_error(client_id, "use_item", f"未知的作物类型: {crop_type}")
        
        is_weed = crop_data[crop_type].get("是否杂草", False)
        if not is_weed:
            return self._send_action_error(client_id, "use_item", "除草剂只能用于清除杂草，此作物不是杂草")
        
        # 检查当前玩家是否有这个道具
        if not self._has_item_in_inventory(current_player_data, item_name):
            return self._send_action_error(client_id, "use_item", f"您没有 {item_name}")
        
        # 移除当前玩家的道具
        if not self._remove_item_from_inventory(current_player_data, item_name, 1):
            return self._send_action_error(client_id, "use_item", f"移除道具 {item_name} 失败")
        
        # 生成随机经验奖励给当前玩家
        experience_reward = random.randint(15, 50)
        current_player_data["经验值"] += experience_reward
        
        # 检查当前玩家是否升级
        self._check_level_up(current_player_data)
        
        # 执行除草操作
        target_lot["is_planted"] = False
        target_lot["crop_type"] = ""
        target_lot["grow_time"] = 0
        target_lot["is_dead"] = False  # 重置死亡状态
        target_lot["已浇水"] = False  # 重置浇水状态
        target_lot["已施肥"] = False  # 重置施肥状态
        
        # 保存两个玩家的数据
        self.save_player_data(current_username, current_player_data)
        self.save_player_data(target_username, target_player_data)
        
        # 向目标玩家推送作物更新
        self._push_crop_update_to_player(target_username, target_player_data)
        
        self.log('INFO', f"玩家 {current_username} 帮助玩家 {target_username} 使用 {item_name} 清除了地块 {lot_index} 的杂草 {crop_type}，获得 {experience_reward} 经验", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "use_item",
            "success": True,
            "message": f"帮助 {target_username} 清除杂草 {crop_type} 成功，获得 {experience_reward} 经验",
            "updated_data": {
                "经验值": current_player_data["经验值"],
                "等级": current_player_data["等级"],
                "道具背包": current_player_data["道具背包"]
            }
        })
    
    def _use_harvest_item(self, client_id, player_data, username, lot, lot_index, item_name):
        """使用采集道具（精准采集锄、时运锄）"""
        # 移除道具
        if not self._remove_item_from_inventory(player_data, item_name, 1):
            return self._send_action_error(client_id, "use_item", f"移除道具 {item_name} 失败")
        
        # 读取作物配置
        crop_data = self._load_crop_data()
        
        # 获取作物类型
        crop_type = lot["crop_type"]
        
        # 检查是否为杂草类型（杂草不能用采集道具收获）
        if crop_type in crop_data:
            crop_info = crop_data[crop_type]
            is_weed = crop_info.get("是否杂草", False)
            
            if is_weed:
                return self._send_action_error(client_id, "use_item", f"{crop_type}不能使用采集道具收获，只能铲除！")
            
            crop_exp = crop_info.get("经验", 10)
            
            # 额外检查：如果作物收益为负数，也视为杂草
            crop_income = crop_info.get("收益", 100) + crop_info.get("花费", 0)
            if crop_income < 0:
                return self._send_action_error(client_id, "use_item", f"{crop_type}不能使用采集道具收获，只能铲除！")
        else:
            # 默认经验
            crop_exp = 10
        
        # 道具特殊效果
        import random
        
        if item_name == "精准采集锄":
            # 精准采集锄：收获数量正常（1-5个），但必定掉落种子
            harvest_count = random.randint(1, 5)
            # 100%概率获得2-4个该作物的种子
            seed_reward = {
                "name": crop_type + "种子",
                "count": random.randint(2, 4)
            }
            message_suffix = "，精准采集锄确保了种子的获得"
            
        elif item_name == "时运锄":
            # 时运锄：收获数量更多（3-8个），种子掉落率正常
            harvest_count = random.randint(3, 8)
            # 15%概率获得1-3个该作物的种子（稍微提高）
            seed_reward = None
            if random.random() < 0.15:
                seed_reward = {
                    "name": crop_type + "种子",
                    "count": random.randint(1, 3)
                }
            message_suffix = "，时运锄增加了收获数量"
            
        else:
            return self._send_action_error(client_id, "use_item", f"不支持的采集道具: {item_name}")
        
        # 生成采集奖励经验
        experience_reward = random.randint(30, 80)
        crop_exp += experience_reward
        
        # 创建收获物
        crop_harvest = {
            "name": crop_type,
            "count": harvest_count
        }
        
        # 更新玩家经验
        player_data["经验值"] += crop_exp
        
        # 检查是否升级
        self._check_level_up(player_data)
        
        # 检查是否会获得成熟物
        crop_data = self._load_crop_data()
        will_get_mature_item = True
        mature_item_name = crop_type
        
        if crop_data and crop_type in crop_data:
            mature_name = crop_data[crop_type].get("成熟物名称")
            if mature_name is None:
                will_get_mature_item = False
            elif mature_name and mature_name.strip():
                mature_item_name = mature_name
        
        # 添加成熟物到作物仓库（如果允许）
        if will_get_mature_item:
            self._add_crop_to_warehouse(player_data, crop_harvest)
        
        # 添加种子奖励到背包
        if seed_reward:
            self._add_seeds_to_bag(player_data, seed_reward)
        
        # 清理地块
        lot["is_planted"] = False
        lot["crop_type"] = ""
        lot["grow_time"] = 0
        lot["已浇水"] = False
        lot["已施肥"] = False
        
        # 清除施肥时间戳
        if "施肥时间" in lot:
            del lot["施肥时间"]
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        # 构建消息
        if will_get_mature_item:
            message = f"使用 {item_name} 收获成功，获得 {mature_item_name} x{harvest_count} 和 {crop_exp} 经验{message_suffix}"
        else:
            message = f"使用 {item_name} 收获成功，获得 {crop_exp} 经验{message_suffix}（{crop_type}无成熟物产出）"
        
        if seed_reward:
            message += f"，额外获得 {seed_reward['name']} x{seed_reward['count']}"
        
        self.log('INFO', f"玩家 {username} 使用 {item_name} 从地块 {lot_index} 收获了作物，获得 {crop_type} x{harvest_count} 和 {crop_exp} 经验" + (f"，额外获得 {seed_reward['name']} x{seed_reward['count']}" if seed_reward else ""), 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "use_item",
            "success": True,
            "message": message,
            "updated_data": {
                "经验值": player_data["经验值"],
                "等级": player_data["等级"],
                "种子仓库": player_data.get("种子仓库", []),
                "作物仓库": player_data.get("作物仓库", []),
                "道具背包": player_data.get("道具背包", [])
            }
        })
    
    def _use_harvest_item_visiting(self, client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index, item_name):
        """访问模式下使用采集道具"""
        # 移除当前玩家的道具
        if not self._remove_item_from_inventory(current_player_data, item_name, 1):
            return self._send_action_error(client_id, "use_item", f"移除道具 {item_name} 失败")
        
        # 读取作物配置
        crop_data = self._load_crop_data()
        
        # 获取作物类型
        crop_type = target_lot["crop_type"]
        
        # 检查是否为杂草类型（杂草不能用采集道具收获）
        if crop_type in crop_data:
            crop_info = crop_data[crop_type]
            is_weed = crop_info.get("是否杂草", False)
            
            if is_weed:
                return self._send_action_error(client_id, "use_item", f"{crop_type}不能使用采集道具收获，只能铲除！")
            
            crop_exp = int(crop_info.get("经验", 10) * 0.7)  # 访问模式获得70%经验
            
            # 额外检查：如果作物收益为负数，也视为杂草
            crop_income = crop_info.get("收益", 100) + crop_info.get("花费", 0)
            if crop_income < 0:
                return self._send_action_error(client_id, "use_item", f"{crop_type}不能使用采集道具收获，只能铲除！")
        else:
            # 默认经验
            crop_exp = 7
        
        # 道具特殊效果（访问模式稍微降低效果）
        import random
        
        if item_name == "精准采集锄":
            # 精准采集锄：收获数量稍少（1-4个），但必定掉落种子
            harvest_count = random.randint(1, 4)
            # 100%概率获得1-3个该作物的种子
            seed_reward = {
                "name": crop_type + "种子",
                "count": random.randint(1, 3)
            }
            message_suffix = "，精准采集锄确保了种子的获得"
            
        elif item_name == "时运锄":
            # 时运锄：收获数量较多（2-6个），种子掉落率正常
            harvest_count = random.randint(2, 6)
            # 10%概率获得1-2个该作物的种子
            seed_reward = None
            if random.random() < 0.10:
                seed_reward = {
                    "name": crop_type + "种子",
                    "count": random.randint(1, 2)
                }
            message_suffix = "，时运锄增加了收获数量"
            
        else:
            return self._send_action_error(client_id, "use_item", f"不支持的采集道具: {item_name}")
        
        # 生成帮助采集奖励经验
        experience_reward = random.randint(20, 60)
        crop_exp += experience_reward
        
        # 创建收获物
        crop_harvest = {
            "name": crop_type,
            "count": harvest_count
        }
        
        # 更新当前玩家经验
        current_player_data["经验值"] += crop_exp
        
        # 检查当前玩家是否升级
        self._check_level_up(current_player_data)
        
        # 检查是否会获得成熟物
        crop_data = self._load_crop_data()
        will_get_mature_item = True
        mature_item_name = crop_type
        
        if crop_data and crop_type in crop_data:
            mature_name = crop_data[crop_type].get("成熟物名称")
            if mature_name is None:
                will_get_mature_item = False
            elif mature_name and mature_name.strip():
                mature_item_name = mature_name
        
        # 收获物给当前玩家（如果允许）
        if will_get_mature_item:
            self._add_crop_to_warehouse(current_player_data, crop_harvest)
        
        # 种子奖励给当前玩家
        if seed_reward:
            self._add_seeds_to_bag(current_player_data, seed_reward)
        
        # 清理目标玩家的地块
        target_lot["is_planted"] = False
        target_lot["crop_type"] = ""
        target_lot["grow_time"] = 0
        target_lot["已浇水"] = False
        target_lot["已施肥"] = False
        
        # 清除施肥时间戳
        if "施肥时间" in target_lot:
            del target_lot["施肥时间"]
        
        # 保存两个玩家的数据
        self.save_player_data(current_username, current_player_data)
        self.save_player_data(target_username, target_player_data)
        
        # 向目标玩家推送作物更新（如果在线）
        self._push_crop_update_to_player(target_username, target_player_data)
        
        # 构建消息
        if will_get_mature_item:
            message = f"使用 {item_name} 帮助收获成功！从 {target_username} 那里获得 {mature_item_name} x{harvest_count} 和 {crop_exp} 经验{message_suffix}"
        else:
            message = f"使用 {item_name} 帮助收获成功！从 {target_username} 那里获得 {crop_exp} 经验{message_suffix}（{crop_type}无成熟物产出）"
        
        if seed_reward:
            message += f"，额外获得 {seed_reward['name']} x{seed_reward['count']}"
        
        self.log('INFO', f"玩家 {current_username} 使用 {item_name} 帮助玩家 {target_username} 收获地块 {lot_index} 的作物，获得 {crop_type} x{harvest_count} 和 {crop_exp} 经验" + (f"，额外获得 {seed_reward['name']} x{seed_reward['count']}" if seed_reward else ""), 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "use_item",
            "success": True,
            "message": message,
            "updated_data": {
                "经验值": current_player_data["经验值"],
                "等级": current_player_data["等级"],
                "种子仓库": current_player_data.get("种子仓库", []),
                "作物仓库": current_player_data.get("作物仓库", []),
                "道具背包": current_player_data.get("道具背包", [])
            }
        })
#==========================道具使用处理==========================



#==========================宠物使用道具处理==========================
    def _handle_use_pet_item(self, client_id, message):
        """处理宠物使用道具请求"""
        # 检查用户登录状态
        logged_in, response = self._check_user_logged_in(client_id, "宠物使用道具", "use_pet_item")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 验证请求参数
        item_name = message.get("item_name", "")
        pet_id = message.get("pet_id", "")
        if not item_name or not pet_id:
            return self._send_pet_item_error(client_id, "缺少必要参数")
        
        # 获取玩家数据
        username = self.user_data[client_id]["username"]
        player_data = self.load_player_data(username)
        if not player_data:
            return self._send_pet_item_error(client_id, "玩家数据加载失败")
        
        # 验证道具和宠物
        validation_result = self._validate_pet_item_use(player_data, item_name, pet_id)
        if not validation_result["success"]:
            return self._send_pet_item_error(client_id, validation_result["message"])
        
        # 处理道具使用
        return self._execute_pet_item_use(client_id, player_data, username, 
                                        validation_result["item_index"], 
                                        validation_result["pet_index"], 
                                        item_name, pet_id)
    
    def _validate_pet_item_use(self, player_data, item_name, pet_id):
        """验证宠物道具使用条件"""
        # 检查道具
        item_bag = player_data.get("道具背包", [])
        item_index = -1
        for i, item in enumerate(item_bag):
            if item.get("name") == item_name and item.get("count", 0) > 0:
                item_index = i
                break
        
        if item_index == -1:
            return {"success": False, "message": f"道具 {item_name} 不足"}
        
        # 检查宠物
        pet_bag = player_data.get("宠物背包", [])
        pet_index = -1
        for i, pet in enumerate(pet_bag):
            if pet.get("pet_id") == pet_id:
                pet_index = i
                break
        
        if pet_index == -1:
            return {"success": False, "message": "找不到指定的宠物"}
        
        return {"success": True, "item_index": item_index, "pet_index": pet_index}
    
    def _execute_pet_item_use(self, client_id, player_data, username, item_index, pet_index, item_name, pet_id):
        """执行宠物道具使用"""
        try:
            item_bag = player_data["道具背包"]
            pet_bag = player_data["宠物背包"]
            
            # 处理道具效果
            success, result_message, updated_pet = self._process_pet_item_use(item_name, pet_bag[pet_index])
            
            if success:
                # 更新数据
                pet_bag[pet_index] = updated_pet
                item_bag[item_index]["count"] -= 1
                if item_bag[item_index]["count"] <= 0:
                    item_bag.pop(item_index)
                
                # 保存并记录
                self.save_player_data(username, player_data)
                self.log('INFO', f"用户 {username} 对宠物 {pet_id} 使用道具 {item_name} 成功", 'PET_ITEM')
                
                return self.send_data(client_id, {
                    "type": "use_pet_item_response",
                    "success": True,
                    "message": result_message,
                    "updated_data": {"宠物背包": pet_bag, "道具背包": item_bag}
                })
            else:
                return self._send_pet_item_error(client_id, result_message)
                
        except Exception as e:
            self.log('ERROR', f"宠物使用道具处理失败: {str(e)}", 'PET_ITEM')
            return self._send_pet_item_error(client_id, "道具使用处理失败")
    
    def _send_pet_item_error(self, client_id, message):
        """发送宠物道具使用错误响应"""
        return self.send_data(client_id, {
            "type": "use_pet_item_response",
            "success": False,
            "message": message
        })
    
    def _process_pet_item_use(self, item_name, pet_data):
        """处理具体的宠物道具使用逻辑"""
        try:
            # 根据道具类型应用不同的效果
            if item_name == "不死图腾":
                # 启用死亡重生技能
                if "enable_death_respawn_skill" not in pet_data:
                    pet_data["enable_death_respawn_skill"] = True
                else:
                    pet_data["enable_death_respawn_skill"] = True
                if "respawn_health_percentage" not in pet_data:
                    pet_data["respawn_health_percentage"] = 0.5  # 重生时50%血量
                return True, f"宠物 {pet_data['pet_name']} 获得了死亡重生能力！", pet_data
                
            elif item_name == "荆棘护甲":
                # 启用反伤机制
                if "enable_damage_reflection_skill" not in pet_data:
                    pet_data["enable_damage_reflection_skill"] = True
                else:
                    pet_data["enable_damage_reflection_skill"] = True
                return True, f"宠物 {pet_data['pet_name']} 获得了荆棘护甲！", pet_data
                
            elif item_name == "狂暴药水":
                # 启用狂暴技能
                if "enable_berserker_skill" not in pet_data:
                    pet_data["enable_berserker_skill"] = True
                else:
                    pet_data["enable_berserker_skill"] = True
                return True, f"宠物 {pet_data['pet_name']} 获得了狂暴能力！", pet_data
                
            elif item_name == "援军令牌":
                # 启用召唤宠物技能
                if "enable_summon_pet_skill" not in pet_data:
                    pet_data["enable_summon_pet_skill"] = True
                else:
                    pet_data["enable_summon_pet_skill"] = True
                return True, f"宠物 {pet_data['pet_name']} 获得了援军召唤能力！", pet_data
                
            elif item_name in ["金刚图腾", "灵木图腾", "潮汐图腾", "烈焰图腾", "敦岩图腾"]:
                # 改变宠物元素
                element_map = {
                    "金刚图腾": "METAL",
                    "灵木图腾": "WOOD", 
                    "潮汐图腾": "WATER",
                    "烈焰图腾": "FIRE",
                    "敦岩图腾": "EARTH"
                }
                
                element_name_map = {
                    "金刚图腾": "金",
                    "灵木图腾": "木",
                    "潮汐图腾": "水", 
                    "烈焰图腾": "火",
                    "敦岩图腾": "土"
                }
                
                new_element = element_map[item_name]
                element_name = element_name_map[item_name]
                
                # 根据实际宠物数据结构更新元素类型
                pet_data["element_type"] = new_element
                # 如果没有元素伤害加成字段，则添加
                if "element_damage_bonus" not in pet_data:
                    pet_data["element_damage_bonus"] = 100.0
                
                return True, f"宠物 {pet_data['pet_name']} 的元素属性已改变为{element_name}元素！", pet_data
            
            else:
                return False, f"未知的宠物道具: {item_name}", None
                
        except Exception as e:
            self.log('ERROR', f"处理宠物道具效果失败: {str(e)}", 'PET_ITEM')
            return False, "道具效果处理失败", None
    
#==========================宠物使用道具处理==========================



#==========================农场道具使用处理==========================
    def _handle_use_farm_item(self, client_id, message):
        """处理农场道具使用请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "农场道具使用", "use_farm_item")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取请求参数
        item_name = message.get("item_name", "")
        
        if not item_name:
            return self.send_data(client_id, {
                "type": "use_farm_item_response",
                "success": False,
                "message": "缺少必要参数"
            })
        
        # 获取玩家数据
        username = self.user_data[client_id]["username"]
        player_data = self.load_player_data(username)
        
        if not player_data:
            return self.send_data(client_id, {
                "type": "use_farm_item_response",
                "success": False,
                "message": "玩家数据加载失败"
            })
        
        # 检查道具是否存在
        item_bag = player_data.get("道具背包", [])
        item_found = False
        item_index = -1
        
        for i, item in enumerate(item_bag):
            if item.get("name") == item_name:
                if item.get("count", 0) > 0:
                    item_found = True
                    item_index = i
                    break
        
        if not item_found:
            return self.send_data(client_id, {
                "type": "use_farm_item_response",
                "success": False,
                "message": f"道具 {item_name} 不足"
            })
        
        # 处理道具使用
        try:
            success, result_message, rewards = self._process_farm_item_use(item_name, player_data)
            
            if success:
                # 减少道具数量
                item_bag[item_index]["count"] -= 1
                if item_bag[item_index]["count"] <= 0:
                    item_bag.pop(item_index)
                
                # 应用奖励
                if "钱币" in rewards:
                    player_data["钱币"] += rewards["钱币"]
                if "经验值" in rewards:
                    player_data["经验值"] += rewards["经验值"]
                
                # 检查是否升级
                self._check_level_up(player_data)
                
                # 保存玩家数据
                self.save_player_data(username, player_data)
                
                # 发送成功响应
                response = {
                    "type": "use_farm_item_response",
                    "success": True,
                    "message": result_message,
                    "updated_data": {
                        "钱币": player_data["钱币"],
                        "经验值": player_data["经验值"],
                        "等级": player_data["等级"],
                        "道具背包": item_bag
                    }
                }
                
                self.log('INFO', f"用户 {username} 使用农场道具 {item_name} 成功", 'FARM_ITEM')
                
            else:
                # 发送失败响应
                response = {
                    "type": "use_farm_item_response",
                    "success": False,
                    "message": result_message
                }
            
            return self.send_data(client_id, response)
            
        except Exception as e:
            self.log('ERROR', f"农场道具使用处理失败: {str(e)}", 'FARM_ITEM')
            return self.send_data(client_id, {
                "type": "use_farm_item_response",
                "success": False,
                "message": "道具使用处理失败"
            })
    
    def _process_farm_item_use(self, item_name, player_data):
        """处理具体的农场道具使用逻辑"""
        try:
            rewards = {}
            
            if item_name == "小额经验卡":
                # 给玩家增加500经验
                rewards["经验值"] = 500
                return True, f"使用 {item_name} 成功！获得了500经验值", rewards
                
            elif item_name == "小额金币卡":
                # 给玩家增加500金币
                rewards["钱币"] = 500
                return True, f"使用 {item_name} 成功！获得了500金币", rewards
            
            else:
                return False, f"未知的农场道具: {item_name}", {}
                
        except Exception as e:
            self.log('ERROR', f"处理农场道具效果失败: {str(e)}", 'FARM_ITEM')
            return False, "道具效果处理失败", {}
    
#==========================农场道具使用处理==========================



#==========================道具配置数据处理==========================
    #处理客户端请求道具配置数据
    def _handle_item_config_request(self, client_id):
        """处理客户端请求道具配置数据"""
        item_config = self._load_item_config()
        
        if item_config:
            self.log('INFO', f"向客户端 {client_id} 发送道具配置数据，道具种类：{len(item_config)}", 'SERVER')
            return self.send_data(client_id, {
                "type": "item_config_response",
                "success": True,
                "item_config": item_config
            })
        else:
            return self.send_data(client_id, {
                "type": "item_config_response",
                "success": False,
                "message": "无法读取道具配置数据"
            })
    
    def _handle_pet_config_request(self, client_id):
        """处理客户端请求宠物配置数据"""
        pet_config = self._load_pet_config()
        
        if pet_config:
            self.log('INFO', f"向客户端 {client_id} 发送宠物配置数据，宠物种类：{len(pet_config)}", 'SERVER')
            return self.send_data(client_id, {
                "type": "pet_config_response",
                "success": True,
                "pet_config": pet_config
            })
        else:
            return self.send_data(client_id, {
                "type": "pet_config_response",
                "success": False,
                "message": "无法读取宠物配置数据"
            })
    
#==========================道具配置数据处理==========================

    #处理客户端请求游戏小提示配置数据
    def _handle_game_tips_config_request(self, client_id):
        """处理客户端请求游戏小提示配置数据"""
        game_tips_config = self._load_game_tips_config()
        
        if game_tips_config:
            self.log('INFO', f"向客户端 {client_id} 发送游戏小提示配置数据", 'SERVER')
            return self.send_data(client_id, {
                "type": "game_tips_config_response",
                "success": True,
                "game_tips_config": game_tips_config
            })
        else:
            return self.send_data(client_id, {
                "type": "game_tips_config_response",
                "success": False,
                "message": "无法读取游戏小提示配置数据"
            })


#==========================升级土地处理==========================
    #处理升级土地请求
    def _handle_upgrade_land(self, client_id, message):
        """处理升级土地请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "升级土地", "upgrade_land")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "upgrade_land")
        if not player_data:
            return self.send_data(client_id, response)
        
        lot_index = message.get("lot_index", -1)
        
        # 验证地块索引
        if lot_index < 0 or lot_index >= len(player_data.get("农场土地", [])):
            return self._send_action_error(client_id, "upgrade_land", "无效的地块索引")
        
        lot = player_data["农场土地"][lot_index]
        
        # 检查地块是否已开垦
        if not lot.get("is_diged", False):
            return self._send_action_error(client_id, "upgrade_land", "此地块尚未开垦")
        
        # 处理升级
        return self._process_land_upgrade(client_id, player_data, username, lot, lot_index)
    
    #辅助函数-处理土地升级逻辑
    def _process_land_upgrade(self, client_id, player_data, username, lot, lot_index):
        """处理土地升级逻辑"""
        # 土地升级配置
        upgrade_config = {
            0: {"cost": 1000, "name": "黄土地", "speed": 2.0},   # 0级->1级：1000元，2倍速
            1: {"cost": 2000, "name": "红土地", "speed": 4.0},   # 1级->2级：2000元，4倍速
            2: {"cost": 4000, "name": "紫土地", "speed": 6.0},   # 2级->3级：4000元，6倍速
            3: {"cost": 8000, "name": "黑土地", "speed": 10.0}   # 3级->4级：8000元，10倍速
        }
        
        # 获取当前土地等级
        current_level = lot.get("土地等级", 0)
        
        # 检查是否已达到最高等级
        if current_level >= 4:
            return self._send_action_error(client_id, "upgrade_land", "此土地已达到最高等级（黑土地）")
        
        # 检查升级配置是否存在
        if current_level not in upgrade_config:
            return self._send_action_error(client_id, "upgrade_land", f"土地等级数据异常，当前等级: {current_level}")
        
        # 获取升级配置
        config = upgrade_config[current_level]
        upgrade_cost = config["cost"]
        next_name = config["name"]
        next_level = current_level + 1
        speed_multiplier = config["speed"]
        
        # 检查玩家金钱是否足够
        if player_data["钱币"] < upgrade_cost:
            return self._send_action_error(client_id, "upgrade_land", f"金钱不足，升级到{next_name}需要 {upgrade_cost} 金钱")
        
        # 执行升级操作
        player_data["钱币"] -= upgrade_cost
        lot["土地等级"] = next_level
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        self.log('INFO', f"玩家 {username} 将地块 {lot_index} 升级到{next_level}级{next_name}，花费 {upgrade_cost} 金钱", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "upgrade_land",
            "success": True,
            "message": f"土地升级成功！升级到{next_level}级{next_name}，作物将以{speed_multiplier}倍速度生长",
            "updated_data": {
                "钱币": player_data["钱币"],
                "农场土地": player_data["农场土地"]
            }
        })
#==========================升级土地处理==========================



#==========================购买新地块处理==========================
    #处理购买新地块请求
    def _handle_buy_new_ground(self, client_id, message):
        """处理购买新地块请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "购买新地块", "buy_new_ground")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "buy_new_ground")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 处理购买新地块
        return self._process_buy_new_ground(client_id, player_data, username)
    
    #辅助函数-处理购买新地块逻辑
    def _process_buy_new_ground(self, client_id, player_data, username):
        """处理购买新地块逻辑"""
        # 购买新地块费用
        new_ground_cost = 2000
        
        # 检查玩家金钱是否足够
        if player_data["钱币"] < new_ground_cost:
            return self._send_action_error(client_id, "buy_new_ground", f"金钱不足，购买新地块需要 {new_ground_cost} 金钱")
        
        # 检查地块数量限制
        max_lots = 1000  # 最大地块数量限制
        current_lots = len(player_data.get("农场土地", []))
        if current_lots >= max_lots:
            return self._send_action_error(client_id, "buy_new_ground", f"已达到最大地块数量限制（{max_lots}个）")
        
        # 执行购买操作
        player_data["钱币"] -= new_ground_cost
        
        # 创建新的未开垦地块
        new_lot = {
            "crop_type": "",
            "grow_time": 0,
            "is_dead": False,
            "is_diged": False,  # 新购买的地块默认未开垦
            "is_planted": False,
            "max_grow_time": 5,
            "已浇水": False,
            "已施肥": False,
            "土地等级": 0
        }
        
        # 添加到农场地块数组
        if "农场土地" not in player_data:
            player_data["农场土地"] = []
        player_data["农场土地"].append(new_lot)
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        new_lot_index = len(player_data["农场土地"])
        self.log('INFO', f"玩家 {username} 成功购买新地块，花费 {new_ground_cost} 金钱，新地块位置：{new_lot_index}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "buy_new_ground",
            "success": True,
            "message": f"购买新地块成功！花费 {new_ground_cost} 元，新地块位置：{new_lot_index}",
            "updated_data": {
                "钱币": player_data["钱币"],
                "农场土地": player_data["农场土地"]
            }
        })
    
#==========================购买新地块处理==========================



#==========================点赞玩家处理==========================
    #处理玩家点赞请求
    def _handle_like_player(self, client_id, message):
        """处理点赞请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "点赞玩家", "like_player")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "like_player")
        if not player_data:
            return self.send_data(client_id, response)
        
        target_username = message.get("target_username", "")
        
        if not target_username:
            return self.send_data(client_id, {
                "type": "like_player_response",
                "success": False,
                "message": "缺少目标用户名"
            })
        
        # 不能给自己点赞
        if target_username == username:
            return self.send_data(client_id, {
                "type": "like_player_response",
                "success": False,
                "message": "不能给自己点赞"
            })
        
        # 检查并更新每日点赞次数
        self._check_and_update_daily_likes(player_data)
        
        # 检查今日剩余点赞次数
        like_system = player_data.get("点赞系统", {})
        remaining_likes = like_system.get("今日剩余点赞次数", 10)
        if remaining_likes <= 0:
            return self.send_data(client_id, {
                "type": "like_player_response",
                "success": False,
                "message": "今日点赞次数已用完，明天再来吧！"
            })
        
        # 加载目标玩家数据
        target_player_data = self.load_player_data(target_username)
        
        if not target_player_data:
            return self.send_data(client_id, {
                "type": "like_player_response",
                "success": False,
                "message": f"无法找到玩家 {target_username} 的数据"
            })
        
        # 扣除点赞次数
        player_data["点赞系统"]["今日剩余点赞次数"] = remaining_likes - 1
        
        # 初始化目标玩家的点赞系统（如果不存在）
        if "点赞系统" not in target_player_data:
            target_player_data["点赞系统"] = {
                "今日剩余点赞次数": 10,
                "点赞上次刷新时间": datetime.datetime.now().strftime("%Y-%m-%d"),
                "总点赞数": 0
            }
        
        # 更新目标玩家的点赞数量
        target_player_data["点赞系统"]["总点赞数"] = target_player_data["点赞系统"].get("总点赞数", 0) + 1
        
        # 保存两个玩家的数据
        self.save_player_data(username, player_data)
        self.save_player_data(target_username, target_player_data)
        
        self.log('INFO', f"玩家 {username} 点赞了玩家 {target_username}，目标玩家点赞数：{target_player_data['点赞系统']['总点赞数']}，剩余点赞次数：{player_data['点赞系统']['今日剩余点赞次数']}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "like_player_response",
            "success": True,
            "message": f"成功点赞玩家 {target_username}！剩余点赞次数：{player_data['点赞系统']['今日剩余点赞次数']}",
            "target_likes": target_player_data["点赞系统"]["总点赞数"],
            "remaining_likes": player_data["点赞系统"]["今日剩余点赞次数"]
        })
    #检查并更新每日点赞次数
    def _check_and_update_daily_likes(self, player_data):
        """检查并更新每日点赞次数（每天重置为10次）"""
        import datetime
        
        current_date = datetime.datetime.now().strftime("%Y-%m-%d")
        
        # 初始化点赞系统
        if "点赞系统" not in player_data:
            player_data["点赞系统"] = {
                "今日剩余点赞次数": 10,
                "点赞上次刷新时间": current_date,
                "总点赞数": 0
            }
            return True  # 发生了初始化
        
        like_system = player_data["点赞系统"]
        
        # 确保必要字段存在
        if "今日剩余点赞次数" not in like_system:
            like_system["今日剩余点赞次数"] = 10
        if "点赞上次刷新时间" not in like_system:
            like_system["点赞上次刷新时间"] = current_date
        if "总点赞数" not in like_system:
            like_system["总点赞数"] = 0
        
        # 检查是否需要每日重置
        last_refresh_date = like_system.get("点赞上次刷新时间", "")
        if last_refresh_date != current_date:
            # 新的一天，重置点赞次数
            like_system["今日剩余点赞次数"] = 10
            like_system["点赞上次刷新时间"] = current_date
            return True  # 发生了重置
        
        return False  # 没有重置

    #清理在线礼包历史数据
    def _cleanup_online_gift_history(self, player_data):
        """清理过期的在线礼包数据（只保留当天的数据）并删除旧的英文格式"""
        import datetime
        
        current_date = datetime.datetime.now().strftime("%Y-%m-%d")
        
        # 清理旧的英文格式数据
        if "online_gift" in player_data:
            del player_data["online_gift"]
            self.log('INFO', f"已清理玩家数据中的旧英文在线礼包格式", 'SERVER')
        
        # 初始化在线礼包数据
        if "在线礼包" not in player_data:
            player_data["在线礼包"] = {
                "当前日期": current_date,
                "今日在线时长": 0.0,
                "已领取礼包": [],
                "登录时间": time.time()
            }
            return
        
        online_gift_data = player_data["在线礼包"]
        
        # 检查是否是新的一天
        last_date = online_gift_data.get("当前日期", "")
        if last_date != current_date:
            # 新的一天，重置所有数据
            player_data["在线礼包"] = {
                "当前日期": current_date,
                "今日在线时长": 0.0,
                "已领取礼包": [],
                "登录时间": time.time()
            }
            self.log('INFO', f"在线礼包数据已重置到新日期：{current_date}", 'SERVER')
    
    #清理新手礼包历史数据
    def _cleanup_new_player_gift_history(self, player_data):
        """清理旧的英文新手礼包数据并转换为中文格式"""
        import datetime
        
        # 检查是否有旧的英文数据
        old_claimed = player_data.get("new_player_gift_claimed", False)
        old_time = player_data.get("new_player_gift_time", "")
        
        if old_claimed or old_time:
            # 转换为中文格式
            if "新手礼包" not in player_data:
                player_data["新手礼包"] = {}
            
            if old_claimed:
                player_data["新手礼包"]["已领取"] = True
                player_data["新手礼包"]["领取时间"] = old_time if old_time else datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            
            # 删除旧的英文字段
            if "new_player_gift_claimed" in player_data:
                del player_data["new_player_gift_claimed"]
            if "new_player_gift_time" in player_data:
                del player_data["new_player_gift_time"]
            
            self.log('INFO', f"已清理玩家数据中的旧英文新手礼包格式", 'SERVER')

    def _cleanup_stamina_system_history(self, player_data):
        """清理旧的体力系统数据，迁移到新的"体力系统"对象"""
        if "体力值" in player_data or "体力上次刷新时间" in player_data or "体力上次恢复时间" in player_data:
            # 加载体力系统配置
            stamina_config = self._load_stamina_config()
            max_stamina = stamina_config.get("最大体力值", 20)
            
            # 保存旧的体力数据
            old_stamina = player_data.get("体力值", 20)
            old_refresh_time = player_data.get("体力上次刷新时间", "")
            old_recovery_time = player_data.get("体力上次恢复时间", 0)
            
            # 创建新的体力系统对象
            if "体力系统" not in player_data:
                player_data["体力系统"] = {}
            
            stamina_system = player_data["体力系统"]
            
            # 迁移数据到新格式
            stamina_system["当前体力值"] = old_stamina
            stamina_system["最大体力值"] = max_stamina
            stamina_system["上次刷新时间"] = old_refresh_time
            stamina_system["上次恢复时间"] = old_recovery_time
            
            # 移除旧的体力数据
            if "体力值" in player_data:
                del player_data["体力值"]
            if "体力上次刷新时间" in player_data:
                del player_data["体力上次刷新时间"]
            if "体力上次恢复时间" in player_data:
                del player_data["体力上次恢复时间"]
                
            self.log('INFO', f"已清理玩家数据中的旧体力系统格式，迁移到新的体力系统对象", 'SERVER')

    def _load_stamina_config(self):
        """加载体力系统配置"""
        # 优先从MongoDB加载配置
        if self.use_mongodb and self.mongo_api and self.mongo_api.is_connected():
            try:
                config_data = self.mongo_api.get_stamina_config()
                if config_data:
                    self.log('INFO', '成功从MongoDB加载体力系统配置', 'SERVER')
                    return config_data.get("体力系统配置", {})
                else:
                    self.log('WARNING', '从MongoDB获取体力系统配置失败，回退到JSON文件', 'SERVER')
            except Exception as e:
                self.log('ERROR', f'从MongoDB加载体力系统配置时发生错误: {e}，回退到JSON文件', 'SERVER')
        
        # 回退到JSON文件
        try:
            config_path = os.path.join(os.path.dirname(__file__), "config", "stamina_config.json")
            with open(config_path, 'r', encoding='utf-8') as file:
                config_data = json.load(file)
                self.log('INFO', '从JSON文件加载体力系统配置', 'SERVER')
                return config_data.get("体力系统配置", {})
        except FileNotFoundError:
            self.log('WARNING', f"体力系统配置文件未找到，使用默认配置", 'SERVER')
            return {
                "最大体力值": 20,
                "每小时恢复体力": 1,
                "恢复间隔秒数": 3600,
                "新玩家初始体力": 20
            }
        except json.JSONDecodeError as e:
            self.log('ERROR', f"体力系统配置文件格式错误: {e}", 'SERVER')
            return {
                "最大体力值": 20,
                "每小时恢复体力": 1,
                "恢复间隔秒数": 3600,
                "新玩家初始体力": 20
            }
        except Exception as e:
            self.log('ERROR', f"加载体力系统配置时发生错误: {e}", 'SERVER')
            return {
                "最大体力值": 20,
                "每小时恢复体力": 1,
                "恢复间隔秒数": 3600,
                "新玩家初始体力": 20
            }

#==========================点赞玩家处理==========================



#==========================在线玩家处理==========================
    #处理请求在线玩家请求
    def _handle_online_players_request(self, client_id, message):
        """处理获取在线玩家数量的请求"""
        online_players = len([cid for cid in self.user_data if self.user_data[cid].get("logged_in", False)])
        return self.send_data(client_id, {
            "type": "online_players_response",
            "success": True,
            "online_players": online_players
        })
    
#==========================在线玩家处理==========================



#==========================玩家体力值处理==========================
    #检查并更新体力值
    def _check_and_update_stamina(self, player_data):
        """检查并更新体力值（每小时恢复1点，每天重置）"""
        import datetime
        
        current_time = time.time()
        current_date = datetime.datetime.now().strftime("%Y-%m-%d")
        
        # 加载体力系统配置
        stamina_config = self._load_stamina_config()
        max_stamina = stamina_config.get("最大体力值", 20)
        recovery_amount = stamina_config.get("每小时恢复体力", 1)
        recovery_interval = stamina_config.get("恢复间隔秒数", 3600)
        initial_stamina = stamina_config.get("新玩家初始体力", 20)
        
        # 获取或创建体力系统对象
        if "体力系统" not in player_data:
            player_data["体力系统"] = {
                "当前体力值": initial_stamina,
                "最大体力值": max_stamina,
                "上次刷新时间": current_date,
                "上次恢复时间": current_time
            }
        
        stamina_system = player_data["体力系统"]
        
        # 确保最大体力值与配置同步
        stamina_system["最大体力值"] = max_stamina
        
        # 检查是否需要每日重置
        last_refresh_date = stamina_system.get("上次刷新时间", "")
        if last_refresh_date != current_date:
            # 新的一天，重置体力值
            stamina_system["当前体力值"] = max_stamina
            stamina_system["上次刷新时间"] = current_date
            stamina_system["上次恢复时间"] = current_time
            return True  # 发生了重置
        
        # 检查每小时恢复
        last_recovery_time = stamina_system.get("上次恢复时间", current_time)
        time_diff = current_time - last_recovery_time
        
        # 如果超过恢复间隔时间，恢复体力值
        if time_diff >= recovery_interval:
            recovery_cycles = int(time_diff // recovery_interval)
            current_stamina = stamina_system.get("当前体力值", 0)
            
            # 体力值恢复，但不能超过最大值
            new_stamina = min(max_stamina, current_stamina + (recovery_cycles * recovery_amount))
            if new_stamina > current_stamina:
                stamina_system["当前体力值"] = new_stamina
                stamina_system["上次恢复时间"] = current_time
                return True  # 发生了恢复
        
        return False  # 没有变化
    
    #消耗体力值
    def _consume_stamina(self, player_data, amount, action_name):
        """消耗体力值"""
        stamina_system = player_data.get("体力系统", {})
        current_stamina = stamina_system.get("当前体力值", 20)
        
        if current_stamina < amount:
            return False, f"体力值不足！{action_name}需要 {amount} 点体力，当前体力：{current_stamina}"
        
        stamina_system["当前体力值"] = current_stamina - amount
        return True, f"消耗 {amount} 点体力，剩余体力：{stamina_system['当前体力值']}"
    
    #检查体力值是否足够
    def _check_stamina_sufficient(self, player_data, amount):
        """检查体力值是否足够"""
        stamina_system = player_data.get("体力系统", {})
        current_stamina = stamina_system.get("当前体力值", 20)
        return current_stamina >= amount


    def _check_and_update_register_time(self, player_data, username):
        """检查并更新已存在玩家的注册时间"""
        default_register_time = "2025年05月21日15时00分00秒"
        
        # 如果玩家没有注册时间字段，设为默认值（老玩家）
        if "注册时间" not in player_data:
            player_data["注册时间"] = default_register_time
            self.save_player_data(username, player_data)
            self.log('INFO', f"为已存在玩家 {username} 设置默认注册时间", 'SERVER')
    
    def _check_and_fix_wisdom_tree_config(self, player_data, username):
        """检查并修复智慧树配置"""
        import time
        current_time = int(time.time())
        
        # 初始化智慧树配置（如果不存在）
        if "智慧树配置" not in player_data:
            player_data["智慧树配置"] = {
                "距离上一次杀虫时间": current_time,
                "距离上一次除草时间": current_time,
                "智慧树显示的话": "",
                "等级": 1,
                "当前经验值": 0,
                "最大经验值": 100,
                "最大生命值": 100,
                "当前生命值": 100,
                "高度": 20
            }
            self.log('INFO', f"为玩家 {username} 初始化智慧树配置", 'SERVER')
        else:
            # 检查并修复已存在的智慧树配置
            wisdom_tree_config = player_data["智慧树配置"]
            config_fixed = False
            
            # 修复空字符串或无效的时间戳
            if "距离上一次除草时间" not in wisdom_tree_config or not wisdom_tree_config["距离上一次除草时间"] or wisdom_tree_config["距离上一次除草时间"] == "":
                wisdom_tree_config["距离上一次除草时间"] = current_time
                config_fixed = True
                
            if "距离上一次杀虫时间" not in wisdom_tree_config or not wisdom_tree_config["距离上一次杀虫时间"] or wisdom_tree_config["距离上一次杀虫时间"] == "":
                wisdom_tree_config["距离上一次杀虫时间"] = current_time
                config_fixed = True
                
            if "上次护理时间" not in wisdom_tree_config or not wisdom_tree_config["上次护理时间"]:
                wisdom_tree_config["上次护理时间"] = current_time
                config_fixed = True
                
            # 确保其他必需字段存在并转换旧格式
            if "等级" not in wisdom_tree_config:
                wisdom_tree_config["等级"] = 1
                config_fixed = True
            if "当前经验值" not in wisdom_tree_config:
                # 兼容旧的"经验"字段
                old_exp = wisdom_tree_config.get("经验", 0)
                wisdom_tree_config["当前经验值"] = old_exp
                if "经验" in wisdom_tree_config:
                    del wisdom_tree_config["经验"]
                config_fixed = True
            if "最大经验值" not in wisdom_tree_config:
                wisdom_tree_config["最大经验值"] = self._calculate_wisdom_tree_max_exp(wisdom_tree_config.get("等级", 1))
                config_fixed = True
            if "当前生命值" not in wisdom_tree_config:
                # 兼容旧的"生命值"字段
                old_health = wisdom_tree_config.get("生命值", 100)
                wisdom_tree_config["当前生命值"] = old_health
                if "生命值" in wisdom_tree_config:
                    del wisdom_tree_config["生命值"]  # 删除旧字段
                config_fixed = True
            if "最大生命值" not in wisdom_tree_config:
                wisdom_tree_config["最大生命值"] = 100
                config_fixed = True
            if "高度" not in wisdom_tree_config:
                wisdom_tree_config["高度"] = 20
                config_fixed = True
            if "智慧树显示的话" not in wisdom_tree_config:
                wisdom_tree_config["智慧树显示的话"] = ""
                config_fixed = True
                
            if config_fixed:
                self.log('INFO', f"为玩家 {username} 修复智慧树配置", 'SERVER')
    
    def _calculate_wisdom_tree_max_exp(self, level):
        """计算智慧树指定等级的最大经验值
        使用前期升级快，后期愈来愈慢的公式
        """
        if level <= 1:
            return 100
        # 使用指数增长公式：基础经验 * (等级^1.5) * 1.2
        base_exp = 50
        exp_multiplier = 1.2
        level_factor = pow(level, 1.5)
        max_exp = int(base_exp * level_factor * exp_multiplier)
        return max_exp
    
#==========================玩家体力值处理==========================



#==========================游戏设置处理==========================
    def _handle_save_game_settings(self, client_id, message):
        """处理保存游戏设置请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "保存游戏设置", "save_game_settings")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "save_game_settings")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 获取设置数据
        settings = message.get("settings", {})
        if not settings:
            return self.send_data(client_id, {
                "type": "save_game_settings_response",
                "success": False,
                "message": "设置数据为空"
            })
        
        # 验证设置数据格式
        valid_settings = {}
        
        # 验证背景音乐音量 (0.0-1.0)
        if "背景音乐音量" in settings:
            volume = settings["背景音乐音量"]
            if isinstance(volume, (int, float)) and 0.0 <= volume <= 1.0:
                valid_settings["背景音乐音量"] = float(volume)
            else:
                return self.send_data(client_id, {
                    "type": "save_game_settings_response",
                    "success": False,
                    "message": "背景音乐音量值无效，应在0.0-1.0之间"
                })
        
        # 验证天气显示设置
        if "天气显示" in settings:
            weather_display = settings["天气显示"]
            if isinstance(weather_display, bool):
                valid_settings["天气显示"] = weather_display
            else:
                return self.send_data(client_id, {
                    "type": "save_game_settings_response",
                    "success": False,
                    "message": "天气显示设置值无效，应为布尔值"
                })
        
        # 保存设置到玩家数据
        if "游戏设置" not in player_data:
            player_data["游戏设置"] = {}
        
        player_data["游戏设置"].update(valid_settings)
        
        # 保存到数据库
        if self.save_player_data(username, player_data):
            self.log('INFO', f"用户 {username} 保存游戏设置: {valid_settings}", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "save_game_settings_response",
                "success": True,
                "message": "游戏设置保存成功",
                "settings": valid_settings
            })
        else:
            return self.send_data(client_id, {
                "type": "save_game_settings_response",
                "success": False,
                "message": "保存游戏设置失败"
            })
#==========================游戏设置处理==========================
    


#==========================玩家游玩时间处理==========================
    #处理获取玩家游玩时间请求
    def _handle_get_play_time(self, client_id):
        """处理获取游玩时间请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "获取游玩时间")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "play_time")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 计算当前会话的游玩时间
        login_timestamp = self.user_data[client_id].get("login_timestamp", time.time())
        current_session_seconds = int(time.time() - login_timestamp)
        
        # 格式化当前会话时间
        current_hours = current_session_seconds // 3600
        current_minutes = (current_session_seconds % 3600) // 60
        current_seconds = current_session_seconds % 60
        current_session_time = f"{current_hours}时{current_minutes}分{current_seconds}秒"
        
        # 获取最后登录时间和总游玩时间
        last_login_time = player_data.get("最后登录时间", "未知")
        total_login_time = player_data.get("总游玩时间", "0时0分0秒")
        
        self.log('INFO', f"玩家 {username} 请求游玩时间统计", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "play_time_response",
            "success": True,
            "最后登录时间": last_login_time,
            "总游玩时间": total_login_time,
            "current_session_time": current_session_time
        })
    
    #处理更新游玩时间请求
    def _handle_update_play_time(self, client_id):
        """处理更新游玩时间请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "更新游玩时间", "update_time")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "update_time")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 计算当前会话的游玩时间
        login_timestamp = self.user_data[client_id].get("login_timestamp", time.time())
        play_time_seconds = int(time.time() - login_timestamp)
        
        # 解析现有的总游玩时间
        total_time_str = player_data.get("总游玩时间", "0时0分0秒")
        time_parts = re.match(r"(?:(\d+)时)?(?:(\d+)分)?(?:(\d+)秒)?", total_time_str)
        
        if time_parts:
            hours = int(time_parts.group(1) or 0)
            minutes = int(time_parts.group(2) or 0)
            seconds = int(time_parts.group(3) or 0)
            
            # 计算新的总游玩时间
            total_seconds = hours * 3600 + minutes * 60 + seconds + play_time_seconds
            new_hours = total_seconds // 3600
            new_minutes = (total_seconds % 3600) // 60
            new_seconds = total_seconds % 60
            
            # 更新总游玩时间
            player_data["总游玩时间"] = f"{new_hours}时{new_minutes}分{new_seconds}秒"
            
            # 保存玩家数据
            self.save_player_data(username, player_data)
            
            # 重置登录时间戳，以便下次计算
            self.user_data[client_id]["login_timestamp"] = time.time()
            
            self.log('INFO', f"已更新玩家 {username} 的游玩时间，当前游玩时间: {play_time_seconds} 秒，总游玩时间: {player_data['总游玩时间']}", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "update_time_response",
                "success": True,
                "message": "游玩时间已更新",
                "总游玩时间": player_data["总游玩时间"]
            })
        else:
            self.log('ERROR', f"解析玩家 {username} 的游玩时间失败", 'SERVER')
            return self.send_data(client_id, {
                "type": "update_time_response",
                "success": False,
                "message": "更新游玩时间失败，格式错误"
            })
#==========================玩家游玩时间处理==========================



#==========================玩家排行榜处理==========================
    #处理获取玩家排行榜请求
    def _handle_player_rankings_request(self, client_id, message):
        """处理获取玩家排行榜的请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "获取玩家排行榜", "player_rankings")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取排序和筛选参数
        sort_by = message.get("sort_by", "等级")  # 排序字段
        sort_order = message.get("sort_order", "desc")  # 排序顺序
        filter_online = message.get("filter_online", False)  # 是否只显示在线玩家
        search_qq = message.get("search_qq", "")  # 搜索的QQ号
        
        try:
            players_data = []
            total_registered_players = 0
            
            # 优先使用MongoDB
            if self.use_mongodb and self.mongo_api:
                # 获取所有玩家基本信息
                all_players = self.mongo_api.get_all_players_basic_info()
                total_registered_players = len(all_players)
                
                for player_data in all_players:
                    account_id = player_data.get("玩家账号", "")
                    
                    # 如果有搜索条件，先检查是否匹配
                    if search_qq and search_qq not in account_id:
                        continue
                    
                    # 统计背包中的种子数量
                    seed_count = sum(item.get("count", 0) for item in player_data.get("种子仓库", []))
                    
                    # 检查玩家是否在线
                    is_online = any(
                        user_info.get("username") == account_id and user_info.get("logged_in", False) 
                        for user_info in self.user_data.values()
                    )
                    
                    # 如果筛选在线玩家，跳过离线玩家
                    if filter_online and not is_online:
                        continue
                    
                    # 解析总游玩时间为秒数（用于排序）
                    total_time_str = player_data.get("总游玩时间", "0时0分0秒")
                    total_time_seconds = self._parse_time_to_seconds(total_time_str)
                    
                    # 解析最后登录时间为时间戳（用于排序）
                    last_login_str = player_data.get("最后登录时间", "未知")
                    last_login_timestamp = self._parse_login_time_to_timestamp(last_login_str)
                    
                    # 获取体力值
                    stamina_system = player_data.get("体力系统", {})
                    current_stamina = stamina_system.get("当前体力值", 20)
                    
                    player_info = {
                        "玩家账号": account_id,
                        "玩家昵称": player_data.get("玩家昵称", account_id),
                        "农场名称": player_data.get("农场名称", ""),
                        "等级": player_data.get("等级", 1),
                        "钱币": player_data.get("钱币", 0),
                        "经验值": player_data.get("经验值", 0),
                        "体力值": current_stamina,
                        "seed_count": seed_count,
                        "最后登录时间": last_login_str,
                        "last_login_timestamp": last_login_timestamp,
                        "总游玩时间": total_time_str,
                        "total_time_seconds": total_time_seconds,
                        "like_num": player_data.get("点赞系统", {}).get("总点赞数", 0),
                        "is_online": is_online
                    }
                    
                    players_data.append(player_info)
            else:
                # 降级到文件系统
                save_files = glob.glob(os.path.join("game_saves", "*.json"))
                total_registered_players = len(save_files)
                
                for save_file in save_files:
                    try:
                        # 从文件名提取账号ID
                        account_id = os.path.basename(save_file).split('.')[0]
                        
                        # 如果有搜索条件，先检查是否匹配
                        if search_qq and search_qq not in account_id:
                            continue
                        
                        # 加载玩家数据
                        with open(save_file, 'r', encoding='utf-8') as file:
                            player_data = json.load(file)
                        
                        if player_data:
                            # 统计背包中的种子数量
                            seed_count = sum(item.get("count", 0) for item in player_data.get("种子仓库", []))
                            
                            # 检查玩家是否在线
                            is_online = any(
                                user_info.get("username") == account_id and user_info.get("logged_in", False) 
                                for user_info in self.user_data.values()
                            )
                            
                            # 如果筛选在线玩家，跳过离线玩家
                            if filter_online and not is_online:
                                continue
                            
                            # 解析总游玩时间为秒数（用于排序）
                            total_time_str = player_data.get("总游玩时间", "0时0分0秒")
                            total_time_seconds = self._parse_time_to_seconds(total_time_str)
                            
                            # 解析最后登录时间为时间戳（用于排序）
                            last_login_str = player_data.get("最后登录时间", "未知")
                            last_login_timestamp = self._parse_login_time_to_timestamp(last_login_str)
                            
                            # 获取所需的玩家信息
                            stamina_system = player_data.get("体力系统", {})
                            current_stamina = stamina_system.get("当前体力值", 20)
                            
                            player_info = {
                                "玩家账号": player_data.get("玩家账号", account_id),
                                "玩家昵称": player_data.get("玩家昵称", player_data.get("玩家账号", account_id)),
                                "农场名称": player_data.get("农场名称", ""),
                                "等级": player_data.get("等级", 1),
                                "钱币": player_data.get("钱币", 0),
                                "经验值": player_data.get("经验值", 0),
                                "体力值": current_stamina,
                                "seed_count": seed_count,
                                "最后登录时间": last_login_str,
                                "last_login_timestamp": last_login_timestamp,
                                "总游玩时间": total_time_str,
                                "total_time_seconds": total_time_seconds,
                                "like_num": player_data.get("点赞系统", {}).get("总点赞数", 0),
                                "is_online": is_online
                            }
                            
                            players_data.append(player_info)
                    except Exception as e:
                        self.log('ERROR', f"读取玩家 {account_id} 的数据时出错: {str(e)}", 'SERVER')
            
            # 根据排序参数进行排序
            reverse_order = (sort_order == "desc")
            
            if sort_by == "seed_count":
                players_data.sort(key=lambda x: x["seed_count"], reverse=reverse_order)
            elif sort_by == "等级":
                players_data.sort(key=lambda x: x["等级"], reverse=reverse_order)
            elif sort_by == "online_time":
                players_data.sort(key=lambda x: x["total_time_seconds"], reverse=reverse_order)
            elif sort_by == "login_time":
                players_data.sort(key=lambda x: x["last_login_timestamp"], reverse=reverse_order)
            elif sort_by == "like_num":
                players_data.sort(key=lambda x: x["like_num"], reverse=reverse_order)
            elif sort_by == "钱币":
                players_data.sort(key=lambda x: x["钱币"], reverse=reverse_order)
            else:
                # 默认按等级排序
                players_data.sort(key=lambda x: x["等级"], reverse=True)
            
            # 统计在线玩家数量
            online_count = sum(1 for player in players_data if player.get("is_online", False))
            
            # 记录日志
            search_info = f"，搜索QQ：{search_qq}" if search_qq else ""
            filter_info = "，仅在线玩家" if filter_online else ""
            sort_info = f"，按{sort_by}{'降序' if reverse_order else '升序'}排序"
            
            self.log('INFO', f"玩家 {self.user_data[client_id].get('username')} 请求玩家排行榜{search_info}{filter_info}{sort_info}，返回 {len(players_data)} 个玩家数据，注册总人数：{total_registered_players}，在线人数：{online_count}", 'SERVER')
            
            # 返回排行榜数据（包含注册总人数）
            return self.send_data(client_id, {
                "type": "player_rankings_response",
                "success": True,
                "players": players_data,
                "total_registered_players": total_registered_players,
                "sort_by": sort_by,
                "sort_order": sort_order,
                "filter_online": filter_online,
                "search_qq": search_qq
            })
            
        except Exception as e:
            self.log('ERROR', f"处理玩家排行榜请求时出错: {str(e)}", 'SERVER')
            return self.send_data(client_id, {
                "type": "player_rankings_response",
                "success": False,
                "message": "获取排行榜数据失败"
            })
    
    # 辅助函数：将时间字符串转换为秒数
    def _parse_time_to_seconds(self, time_str):
        """将时间字符串（如'1时30分45秒'）转换为总秒数"""
        try:
            import re
            # 使用正则表达式提取时、分、秒
            pattern = r'(\d+)时(\d+)分(\d+)秒'
            match = re.match(pattern, time_str)
            if match:
                hours = int(match.group(1))
                minutes = int(match.group(2))
                seconds = int(match.group(3))
                return hours * 3600 + minutes * 60 + seconds
            return 0
        except:
            return 0
    
    # 辅助函数：将登录时间字符串转换为时间戳
    def _parse_login_time_to_timestamp(self, login_time_str):
        """将登录时间字符串转换为时间戳用于排序"""
        try:
            if login_time_str == "未知":
                return 0
            # 解析格式：2024年01月01日12时30分45秒
            import datetime
            dt = datetime.datetime.strptime(login_time_str, "%Y年%m月%d日%H时%M分%S秒")
            return dt.timestamp()
        except:
            return 0
#==========================玩家排行榜处理==========================



#==========================作物数据处理==========================
    #处理客户端请求作物数据
    def _handle_crop_data_request(self, client_id):
        """处理客户端请求作物数据"""
        crop_data = self._load_crop_data()
        
        if crop_data:
            self.log('INFO', f"向客户端 {client_id} 发送作物数据", 'SERVER')
            return self.send_data(client_id, {
                "type": "crop_data_response",
                "success": True,
                "crop_data": crop_data
            })
        else:
            return self.send_data(client_id, {
                "type": "crop_data_response",
                "success": False,
                "message": "无法读取作物数据"
            })
#==========================作物数据处理==========================


#==========================访问其他玩家农场处理==========================
    #处理访问其他玩家农场的请求
    def _handle_visit_player_request(self, client_id, message):
        """处理访问其他玩家农场的请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "访问玩家农场", "visit_player")
        if not logged_in:
            return self.send_data(client_id, response)
        
        target_username = message.get("target_username", "")
        
        if not target_username:
            return self.send_data(client_id, {
                "type": "visit_player_response",
                "success": False,
                "message": "缺少目标用户名"
            })
        
        # 加载目标玩家数据
        target_player_data = self.load_player_data(target_username)
        
        if not target_player_data:
            return self.send_data(client_id, {
                "type": "visit_player_response",
                "success": False,
                "message": f"无法找到玩家 {target_username} 的数据"
            })
        
        # 检查并修复目标玩家的智慧树配置格式
        self._check_and_fix_wisdom_tree_config(target_player_data, target_username)
        
        # 返回目标玩家的农场数据（只返回可见的数据，不包含敏感信息如密码）
        target_stamina_system = target_player_data.get("体力系统", {})
        target_current_stamina = target_stamina_system.get("当前体力值", 20)
        
        safe_player_data = {
            "玩家账号": target_player_data.get("玩家账号", target_username),
            "username": target_username,  # 添加username字段，用于购买商品时标识卖家
            "玩家昵称": target_player_data.get("玩家昵称", target_username),
            "农场名称": target_player_data.get("农场名称", ""),
            "等级": target_player_data.get("等级", 1),
            "钱币": target_player_data.get("钱币", 0),
            "经验值": target_player_data.get("经验值", 0),
            "体力值": target_current_stamina,
            "农场土地": target_player_data.get("农场土地", []),
            "种子仓库": target_player_data.get("种子仓库", []),
            "作物仓库": target_player_data.get("作物仓库", []),
            "道具背包": target_player_data.get("道具背包", []),
            "宠物背包": target_player_data.get("宠物背包", []),
            "巡逻宠物": self._convert_patrol_pets_to_full_data(target_player_data),
            "出战宠物": self._convert_battle_pets_to_full_data(target_player_data),
            "稻草人配置": target_player_data.get("稻草人配置", {}),
            "智慧树配置": target_player_data.get("智慧树配置", {}),
            "小卖部配置": target_player_data.get("小卖部配置", {"商品列表": [], "格子数": 10}),  # 添加小卖部配置
            "点赞数": target_player_data.get("点赞系统", {}).get("总点赞数", 0),  # 添加点赞数
            "最后登录时间": target_player_data.get("最后登录时间", "未知"),
            "总游玩时间": target_player_data.get("总游玩时间", "0时0分0秒"),
            "total_likes": target_player_data.get("total_likes", 0),
            "访问系统": target_player_data.get("访问系统", {
                "总访问人数": 0,
                "今日访问人数": 0,
                "访问记录": {}
            })  # 添加访问系统数据
        }
        
        current_username = self.user_data[client_id]["username"]
        
        # 更新被访问玩家的访问系统数据
        self._update_visit_system(target_username, current_username)
        
        self.log('INFO', f"玩家 {current_username} 访问了玩家 {target_username} 的农场", 'SERVER')
        
        # 记录玩家的访问状态
        self.user_data[client_id]["visiting_mode"] = True
        self.user_data[client_id]["visiting_target"] = target_username
        
        return self.send_data(client_id, {
            "type": "visit_player_response",
            "success": True,
            "message": f"成功获取玩家 {target_username} 的农场数据",
            "player_data": safe_player_data,
            "is_visiting": True
        })
#==========================访问其他玩家农场处理==========================

    #==========================访问系统处理==========================
    def _update_visit_system(self, target_username, visitor_username):
        """更新被访问玩家的访问系统数据"""
        try:
            # 加载被访问玩家的数据
            target_player_data = self.load_player_data(target_username)
            if not target_player_data:
                self.log('ERROR', f"无法加载被访问玩家 {target_username} 的数据", 'SERVER')
                return
            
            # 获取访问者的昵称
            visitor_player_data = self.load_player_data(visitor_username)
            visitor_nickname = visitor_player_data.get("玩家昵称", visitor_username) if visitor_player_data else visitor_username
            
            # 初始化访问系统（如果不存在）
            if "访问系统" not in target_player_data:
                target_player_data["访问系统"] = {
                    "总访问人数": 0,
                    "今日访问人数": 0,
                    "访问记录": {}
                }
            
            visit_system = target_player_data["访问系统"]
            
            # 获取今日日期
            from datetime import datetime
            today = datetime.now().strftime("%Y-%m-%d")
            
            # 更新总访问人数
            visit_system["总访问人数"] = visit_system.get("总访问人数", 0) + 1
            
            # 检查是否需要重置今日访问人数（新的一天）
            last_visit_date = visit_system.get("最后访问日期", "")
            if last_visit_date != today:
                visit_system["今日访问人数"] = 0
                visit_system["最后访问日期"] = today
            
            # 更新今日访问人数
            visit_system["今日访问人数"] = visit_system.get("今日访问人数", 0) + 1
            
            # 更新访问记录
            if "访问记录" not in visit_system:
                visit_system["访问记录"] = {}
            
            if today not in visit_system["访问记录"]:
                visit_system["访问记录"][today] = []
            
            # 添加访问者昵称到今日访问记录（避免重复）
            if visitor_nickname not in visit_system["访问记录"][today]:
                visit_system["访问记录"][today].append(visitor_nickname)
            
            # 保存更新后的数据
            if self.save_player_data(target_username, target_player_data):
                self.log('INFO', f"成功更新玩家 {target_username} 的访问系统数据，访问者: {visitor_nickname}", 'SERVER')
            else:
                self.log('ERROR', f"保存玩家 {target_username} 的访问系统数据失败", 'SERVER')
                
        except Exception as e:
            self.log('ERROR', f"更新访问系统数据时出错: {e}", 'SERVER')
    
    def _reset_daily_visit_count(self):
        """重置所有玩家的今日访问人数（凌晨调用）"""
        try:
            # 获取所有玩家的基本信息
            if hasattr(self, 'mongo_api') and self.mongo_api:
                players_info = self.mongo_api.get_all_players_basic_info()
                
                from datetime import datetime
                today = datetime.now().strftime("%Y-%m-%d")
                
                reset_count = 0
                for player_info in players_info:
                    username = player_info.get("玩家账号")
                    if username:
                        player_data = self.load_player_data(username)
                        if player_data and "访问系统" in player_data:
                            visit_system = player_data["访问系统"]
                            last_visit_date = visit_system.get("最后访问日期", "")
                            
                            # 如果不是今天，重置今日访问人数
                            if last_visit_date != today:
                                visit_system["今日访问人数"] = 0
                                visit_system["最后访问日期"] = today
                                
                                if self.save_player_data(username, player_data):
                                    reset_count += 1
                
                self.log('INFO', f"成功重置了 {reset_count} 个玩家的今日访问人数", 'SERVER')
            
        except Exception as e:
            self.log('ERROR', f"重置今日访问人数时出错: {e}", 'SERVER')
    
    def _handle_give_money_request(self, client_id, message):
        """处理送金币请求"""
        try:
            # 获取发送者信息
            sender_info = self.user_data.get(client_id)
            if not sender_info or not sender_info.get("logged_in", False):
                self.send_data(client_id, {
                    "type": "give_money_response",
                    "success": False,
                    "message": "请先登录"
                })
                return
            
            sender_username = sender_info.get("username")
            target_username = message.get("target_username", "")
            amount = message.get("amount", 0)
            
            # 验证参数
            if not target_username:
                self.send_data(client_id, {
                    "type": "give_money_response",
                    "success": False,
                    "message": "目标玩家用户名不能为空"
                })
                return
            
            if amount != 500:
                self.send_data(client_id, {
                    "type": "give_money_response",
                    "success": False,
                    "message": "每次只能送500金币"
                })
                return
            
            if sender_username == target_username:
                self.send_data(client_id, {
                    "type": "give_money_response",
                    "success": False,
                    "message": "不能给自己送金币"
                })
                return
            
            # 加载发送者数据
            sender_data = self.load_player_data(sender_username)
            if not sender_data:
                self.send_data(client_id, {
                    "type": "give_money_response",
                    "success": False,
                    "message": "无法加载发送者数据"
                })
                return
            
            # 检查发送者金币是否足够
            sender_money = sender_data.get("钱币", 0)
            if sender_money < amount:
                self.send_data(client_id, {
                    "type": "give_money_response",
                    "success": False,
                    "message": f"您的金币不足，当前拥有{sender_money}金币"
                })
                return
            
            # 加载接收者数据
            target_data = self.load_player_data(target_username)
            if not target_data:
                self.send_data(client_id, {
                    "type": "give_money_response",
                    "success": False,
                    "message": "目标玩家不存在"
                })
                return
            
            # 执行金币转移
            sender_data["钱币"] = sender_money - amount
            target_data["钱币"] = target_data.get("钱币", 0) + amount
            
            # 记录送金币日志
            from datetime import datetime
            current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            log_message = f"[{current_time}] {sender_username} 送给 {target_username} {amount}金币"
            self.log('INFO', log_message, 'GIVE_MONEY')
            
            # 保存数据
            if self.save_player_data(sender_username, sender_data) and self.save_player_data(target_username, target_data):
                # 获取目标玩家昵称
                target_nickname = target_data.get("玩家昵称", target_username)
                
                # 发送成功响应
                self.send_data(client_id, {
                    "type": "give_money_response",
                    "success": True,
                    "message": f"成功送给 {target_nickname} {amount}金币！",
                    "updated_data": {
                        "钱币": sender_data["钱币"]
                    },
                    "target_updated_data": {
                        "钱币": target_data["钱币"]
                    }
                })
                
                # 如果目标玩家在线，通知他们收到金币
                target_client_id = None
                for cid, user_info in self.user_data.items():
                    if user_info.get("username") == target_username and user_info.get("logged_in", False):
                        target_client_id = cid
                        break
                
                if target_client_id:
                    sender_nickname = sender_data.get("玩家昵称", sender_username)
                    self.send_data(target_client_id, {
                        "type": "money_received_notification",
                        "sender_nickname": sender_nickname,
                        "amount": amount,
                        "new_money": target_data["钱币"]
                    })
            else:
                self.send_data(client_id, {
                    "type": "give_money_response",
                    "success": False,
                    "message": "数据保存失败，请重试"
                })
                
        except Exception as e:
            self.log('ERROR', f"处理送金币请求失败: {str(e)}", 'GIVE_MONEY')
            self.send_data(client_id, {
                "type": "give_money_response",
                "success": False,
                "message": "服务器内部错误"
            })
    #==========================访问系统处理==========================




#==========================返回自己农场处理==========================
    #处理玩家返回自己农场的请求
    def _handle_return_my_farm_request(self, client_id, message):
        """处理玩家返回自己农场的请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "返回自己农场", "return_my_farm")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "return_my_farm")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 清除访问状态
        self.user_data[client_id]["visiting_mode"] = False
        self.user_data[client_id]["visiting_target"] = ""
        
        # 清理偷菜免被发现计数器
        self._clear_player_steal_immunity(username)
        
        self.log('INFO', f"玩家 {username} 返回了自己的农场", 'SERVER')
        
        # 返回玩家自己的农场数据
        my_stamina_system = player_data.get("体力系统", {})
        my_current_stamina = my_stamina_system.get("当前体力值", 20)
        
        return self.send_data(client_id, {
            "type": "return_my_farm_response",
            "success": True,
            "message": "已返回自己的农场",
            "player_data": {
                "玩家账号": player_data.get("玩家账号", username),
                "玩家昵称": player_data.get("玩家昵称", username),
                "农场名称": player_data.get("农场名称", ""),
                "等级": player_data.get("等级", 1),
                "钱币": player_data.get("钱币", 0),
                "经验值": player_data.get("经验值", 0),
                "体力值": my_current_stamina,
                "农场土地": player_data.get("农场土地", []),
                "种子仓库": player_data.get("种子仓库", []),
                "宠物背包": player_data.get("宠物背包", []),
                "巡逻宠物": self._convert_patrol_pets_to_full_data(player_data),
                "出战宠物": self._convert_battle_pets_to_full_data(player_data),
                "稻草人配置": player_data.get("稻草人配置", {}),
                "total_likes": player_data.get("total_likes", 0)
            },
            "is_visiting": False
        })
#==========================返回自己农场处理==========================




#==========================在线礼包处理==========================
    #处理获取在线礼包数据请求
    def _handle_get_online_gift_data_request(self, client_id, message):
        """处理获取在线礼包数据请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "获取在线礼包数据", "get_online_gift_data")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "get_online_gift_data")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 确保在线礼包数据已初始化
        self._cleanup_online_gift_history(player_data)
        
        online_gift_data = player_data["在线礼包"]
        
        # 更新在线时间
        current_time = time.time()
        login_time = online_gift_data.get("登录时间", current_time)
        
        # 计算本次登录的在线时间并累加
        if client_id in self.user_data and self.user_data[client_id].get("logged_in", False):
            session_online_time = current_time - self.user_data[client_id].get("login_timestamp", current_time)
            online_gift_data["今日在线时长"] += session_online_time
            # 重置登录时间戳
            self.user_data[client_id]["login_timestamp"] = current_time
        
        # 保存数据
        self.save_player_data(username, player_data)
        
        return self.send_data(client_id, {
            "type": "online_gift_data_response",
            "success": True,
            "current_online_duration": online_gift_data["今日在线时长"],
            "claimed_gifts": {gift: True for gift in online_gift_data["已领取礼包"]}
        })
    
    #处理领取在线礼包请求
    def _handle_claim_online_gift_request(self, client_id, message):
        """处理领取在线礼包请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "领取在线礼包", "claim_online_gift")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "claim_online_gift")
        if not player_data:
            return self.send_data(client_id, response)
        
        gift_name = message.get("gift_name", "")
        if not gift_name:
            return self.send_data(client_id, {
                "type": "claim_online_gift_response",
                "success": False,
                "message": "礼包名称不能为空"
            })
        
        # 加载在线礼包配置
        config = self._load_online_gift_config()
        gift_config = config.get("在线礼包配置", {})
        
        if gift_name not in gift_config:
            return self.send_data(client_id, {
                "type": "claim_online_gift_response",
                "success": False,
                "message": "无效的礼包名称"
            })
        
        # 确保在线礼包数据已初始化
        self._cleanup_online_gift_history(player_data)
        online_gift_data = player_data["在线礼包"]
        
        # 检查是否已领取
        if gift_name in online_gift_data["已领取礼包"]:
            return self.send_data(client_id, {
                "type": "claim_online_gift_response",
                "success": False,
                "message": "该礼包今日已领取"
            })
        
        # 更新在线时间
        current_time = time.time()
        if client_id in self.user_data and self.user_data[client_id].get("logged_in", False):
            session_online_time = current_time - self.user_data[client_id].get("login_timestamp", current_time)
            online_gift_data["今日在线时长"] += session_online_time
            # 重置登录时间戳
            self.user_data[client_id]["login_timestamp"] = current_time
        
        # 检查在线时长是否满足条件
        gift_info = gift_config[gift_name]
        required_time = gift_info["时长秒数"]
        current_duration = online_gift_data["今日在线时长"]
        
        if current_duration < required_time:
            return self.send_data(client_id, {
                "type": "claim_online_gift_response",
                "success": False,
                "message": f"在线时间不足，还需要 {self._format_time(required_time - current_duration)}"
            })
        
        # 发放奖励
        rewards = gift_info["奖励"]
        self._apply_online_gift_rewards_new(player_data, rewards)
        
        # 记录领取状态
        online_gift_data["已领取礼包"].append(gift_name)
        
        # 保存数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 领取在线礼包 {gift_name}，获得奖励: {rewards}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "claim_online_gift_response",
            "success": True,
            "message": f"成功领取 {gift_name} 礼包！",
            "gift_name": gift_name,
            "rewards": rewards,
            "updated_data": {
                "钱币": player_data["钱币"],
                "经验值": player_data["经验值"],
                "等级": player_data["等级"],
                "种子仓库": player_data.get("种子仓库", [])
            }
        })
    
    #发放在线礼包奖励（新版本 - 支持中文配置）
    def _apply_online_gift_rewards_new(self, player_data, rewards):
        """发放在线礼包奖励（中文配置格式）"""
        # 发放金币
        if "金币" in rewards:
            player_data["钱币"] = player_data.get("钱币", 0) + rewards["金币"]
        
        # 发放经验
        if "经验" in rewards:
            old_experience = player_data.get("经验值", 0)
            player_data["经验值"] = old_experience + rewards["经验"]
            
            # 检查是否升级
            self._check_level_up(player_data)
        
        # 发放种子
        if "种子" in rewards:
            player_bag = player_data.get("种子仓库", [])
            crop_data = self._load_crop_data()
            
            for seed_info in rewards["种子"]:
                seed_name = seed_info["名称"]
                seed_count = seed_info["数量"]
                
                # 从作物数据中获取品质信息
                quality = "普通"  # 默认品质
                if crop_data and seed_name in crop_data:
                    quality = crop_data[seed_name].get("品质", "普通")
                
                # 查找是否已有该种子
                found = False
                for item in player_bag:
                    if item.get("name") == seed_name:
                        item["count"] += seed_count
                        found = True
                        break
                
                # 如果没有找到，添加新种子
                if not found:
                    player_bag.append({
                        "name": seed_name,
                        "quality": quality,
                        "count": seed_count
                    })
            
            player_data["种子仓库"] = player_bag

    #发放在线礼包奖励（旧版本）
    def _apply_online_gift_rewards(self, player_data, rewards):
        """发放在线礼包奖励"""
        # 发放金币
        if "钱币" in rewards:
            player_data["钱币"] = player_data.get("钱币", 0) + rewards["钱币"]
        
        # 发放经验
        if "经验值" in rewards:
            old_experience = player_data.get("经验值", 0)
            player_data["经验值"] = old_experience + rewards["经验值"]
            
            # 检查是否升级
            self._check_level_up(player_data)
        
        # 发放种子
        if "seeds" in rewards:
            player_bag = player_data.get("种子仓库", [])
            crop_data = self._load_crop_data()
            
            for seed_info in rewards["seeds"]:
                seed_name = seed_info["name"]
                seed_count = seed_info["count"]
                
                # 从作物数据中获取品质信息
                quality = "普通"  # 默认品质
                if crop_data and seed_name in crop_data:
                    quality = crop_data[seed_name].get("品质", "普通")
                
                # 查找是否已有该种子
                found = False
                for item in player_bag:
                    if item["name"] == seed_name:
                        item["count"] += seed_count
                        found = True
                        break
                
                # 如果没有找到，添加新物品
                if not found:
                    player_bag.append({
                        "name": seed_name,
                        "count": seed_count,
                        "type": "seed",
                        "quality": quality
                    })
            
            player_data["种子仓库"] = player_bag
    
    #检查玩家是否升级
    def _check_level_up(self, player_data):
        """检查玩家是否升级"""
        current_level = player_data.get("等级", 1)
        current_experience = player_data.get("经验值", 0)
        
        # 计算升级所需经验 (每级需要的经验递增)
        experience_needed = current_level * 100
        
        # 检查是否可以升级
        while current_experience >= experience_needed:
            current_level += 1
            current_experience -= experience_needed
            experience_needed = current_level * 100
        
        player_data["等级"] = current_level
        player_data["经验值"] = current_experience
    
    #更新玩家今日在线时间
    def _update_daily_online_time(self, client_id, player_data):
        """更新玩家今日在线时间（现在由中文在线礼包系统管理）"""
        if client_id not in self.user_data or not self.user_data[client_id].get("logged_in", False):
            return 0
        
        # 使用新的中文在线礼包系统
        current_time = time.time()
        login_time = self.user_data[client_id].get("login_timestamp", current_time)
        session_online_time = current_time - login_time
        
        # 重置用户登录时间戳
        self.user_data[client_id]["login_timestamp"] = current_time
        
        # 确保在线礼包数据存在
        self._cleanup_online_gift_history(player_data)
        online_gift_data = player_data.get("在线礼包", {})
        
        if online_gift_data:
            # 更新中文在线礼包系统的在线时长
            online_gift_data["今日在线时长"] = online_gift_data.get("今日在线时长", 0.0) + session_online_time
            return online_gift_data["今日在线时长"]
        
        return session_online_time

    #格式化时间显示
    def _format_time(self, seconds):
        """格式化时间显示"""
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        secs = int(seconds % 60)
        
        if hours > 0:
            return f"{hours}小时{minutes}分钟{secs}秒"
        elif minutes > 0:
            return f"{minutes}分钟{secs}秒"
        else:
            return f"{secs}秒"

#==========================在线礼包处理==========================


#==========================PING延迟检测处理==========================
    #处理ping请求
    def _handle_ping_request(self, client_id, message):
        """处理客户端ping请求，立即返回pong响应"""
        timestamp = message.get("timestamp", time.time())
        
        # 立即返回pong响应
        pong_response = {
            "type": "pong",
            "timestamp": timestamp,
            "server_time": time.time()
        }
        
        return self.send_data(client_id, pong_response)

#==========================PING延迟检测处理==========================



#==========================全服大喇叭消息处理==========================
    #处理全服大喇叭消息
    def _handle_global_broadcast_message(self, client_id, message):
        """处理全服大喇叭消息"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "发送全服大喇叭消息", "global_broadcast")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取消息内容
        content = message.get("content", "").strip()
        if not content:
            return self.send_data(client_id, {
                "type": "global_broadcast_response",
                "success": False,
                "message": "消息内容不能为空"
            })
        
        # 检查消息长度
        if len(content) > 200:
            return self.send_data(client_id, {
                "type": "global_broadcast_response",
                "success": False,
                "message": "消息长度不能超过200字符"
            })
        
        # 获取发送者信息
        username = self.user_data[client_id]["username"]
        
        # 获取玩家数据以获取昵称
        player_data = self.load_player_data(username)
        player_name = ""
        if player_data:
            player_name = player_data.get("玩家昵称", "")
        
        # 获取当前时间戳
        current_timestamp = time.time()
        
        # 创建广播消息
        broadcast_message = {
            "type": "global_broadcast_message",
            "username": username,
            "玩家昵称": player_name,
            "content": content,
            "timestamp": current_timestamp
        }
        
        # 广播给所有在线用户
        self.broadcast(broadcast_message)
        
        # 保存消息到MongoDB
        if self.mongo_api and self.mongo_api.is_connected():
            success = self.mongo_api.save_chat_message(username, player_name, content)
            if not success:
                self.log('WARNING', f"保存聊天消息到MongoDB失败，尝试保存到本地文件", 'BROADCAST')
                self._save_broadcast_message_to_log(username, player_name, content)
        else:
            # 如果MongoDB不可用，保存到本地文件作为备份
            self.log('WARNING', f"MongoDB不可用，保存聊天消息到本地文件", 'BROADCAST')
            self._save_broadcast_message_to_log(username, player_name, content)
        
        # 发送成功响应给发送者
        self.send_data(client_id, {
            "type": "global_broadcast_response",
            "success": True,
            "message": "大喇叭消息发送成功"
        })
        
        self.log('INFO', f"用户 {username}({player_name}) 发送全服大喇叭消息: {content}", 'BROADCAST')
        
        return True
    
    #保存大喇叭消息到日志文件
    def _save_broadcast_message_to_log(self, username, player_name, content):
        """保存大喇叭消息到日志文件"""
        try:
            # 创建chat文件夹（如果不存在）
            import os
            chat_dir = os.path.join(os.path.dirname(__file__), "chat")
            if not os.path.exists(chat_dir):
                os.makedirs(chat_dir)
            
            # 获取当前日期作为文件名
            current_date = datetime.datetime.now().strftime("%Y-%m-%d")
            log_file_path = os.path.join(chat_dir, f"{current_date}.log")
            
            # 格式化时间戳
            timestamp = datetime.datetime.now().strftime("%Y年%m月%d日 %H:%M:%S")
            
            # 创建日志条目
            display_name = player_name if player_name else username
            log_entry = f"[{timestamp}] {display_name}({username}): {content}\n"
            
            # 追加到日志文件
            with open(log_file_path, 'a', encoding='utf-8') as f:
                f.write(log_entry)
                
        except Exception as e:
            self.log('ERROR', f"保存大喇叭消息到日志文件时出错: {str(e)}", 'BROADCAST')
    
    def _handle_request_broadcast_history(self, client_id, message):
        """处理请求全服大喇叭历史消息"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "请求全服大喇叭历史消息", "request_broadcast_history")
        if not logged_in:
            return self.send_data(client_id, response)
        
        try:
            days = message.get("days", 3)  # 默认加载3天
            limit = message.get("limit", 500)  # 默认限制500条
            if days > 30:  # 限制最多30天
                days = 30
            
            # 优先从MongoDB获取历史消息
            messages = []
            if self.mongo_api and self.mongo_api.is_connected():
                try:
                    messages = self.mongo_api.get_chat_history(days, limit)
                    # 转换数据格式以兼容客户端
                    for msg in messages:
                        msg["玩家昵称"] = msg.get("player_name", "")
                        msg["display_name"] = msg.get("player_name", "") if msg.get("player_name") else msg.get("username", "匿名")
                    self.log('INFO', f"从MongoDB获取了 {len(messages)} 条历史消息", 'SERVER')
                except Exception as e:
                    self.log('ERROR', f"从MongoDB获取历史消息失败: {str(e)}", 'SERVER')
                    messages = []
            
            # 如果MongoDB获取失败或没有数据，尝试从本地文件获取
            if not messages:
                self.log('INFO', f"尝试从本地文件获取历史消息", 'SERVER')
                messages = self._load_broadcast_history(days)
            
            # 发送历史消息响应
            response = {
                "type": "broadcast_history_response",
                "success": True,
                "messages": messages,
                "days": days
            }
            
            self.log('INFO', f"向客户端 {client_id} 发送了 {len(messages)} 条历史消息（最近{days}天）", 'SERVER')
            return self.send_data(client_id, response)
            
        except Exception as e:
            self.log('ERROR', f"处理全服大喇叭历史消息请求失败: {str(e)}", 'SERVER')
            error_response = {
                "type": "broadcast_history_response",
                "success": False,
                "message": "加载历史消息失败"
            }
            return self.send_data(client_id, error_response)
    
    def _load_broadcast_history(self, days):
        """从日志文件加载历史消息"""
        messages = []
        chat_dir = os.path.join(os.path.dirname(__file__), "chat")
        
        if not os.path.exists(chat_dir):
            return messages
        
        try:
            # 获取需要加载的日期范围
            end_date = datetime.datetime.now()
            start_date = end_date - datetime.timedelta(days=days-1)
            
            self.log('INFO', f"查找历史消息，日期范围: {start_date.strftime('%Y-%m-%d')} 到 {end_date.strftime('%Y-%m-%d')}", 'SERVER')
            
            # 遍历日期范围内的所有日志文件
            current_date = start_date
            while current_date <= end_date:
                date_str = current_date.strftime("%Y-%m-%d")
                log_file = os.path.join(chat_dir, f"{date_str}.log")
                
                self.log('INFO', f"检查日志文件: {log_file}", 'SERVER')
                
                if os.path.exists(log_file):
                    self.log('INFO', f"找到日志文件: {log_file}", 'SERVER')
                    with open(log_file, "r", encoding="utf-8") as f:
                        lines = f.readlines()
                        
                    self.log('INFO', f"日志文件 {date_str}.log 包含 {len(lines)} 行", 'SERVER')
                    
                    # 解析每一行消息
                    for line in lines:
                        line = line.strip()
                        if line:
                            parsed_message = self._parse_log_message(line)
                            if parsed_message:
                                messages.append(parsed_message)
                                self.log('INFO', f"解析消息成功: {parsed_message['content'][:20]}...", 'SERVER')
                            else:
                                self.log('WARNING', f"解析消息失败: {line[:50]}...", 'SERVER')
                else:
                    self.log('INFO', f"日志文件不存在: {log_file}", 'SERVER')
                
                current_date += datetime.timedelta(days=1)
            
            # 按时间戳排序
            messages.sort(key=lambda x: x.get("timestamp", 0))
            
            # 限制消息数量，最多返回500条
            if len(messages) > 500:
                messages = messages[-500:]
            
            return messages
            
        except Exception as e:
            self.log('ERROR', f"加载全服大喇叭历史消息失败: {str(e)}", 'SERVER')
            return []
    
    def _parse_log_message(self, line):
        """解析日志消息行"""
        try:
            # 消息格式: [时间] 昵称(QQ号): 消息内容
            import re
            
            # 匹配时间部分
            time_match = re.match(r'\[([^\]]+)\]', line)
            if not time_match:
                return None
            
            time_str = time_match.group(1)
            
            # 匹配用户名和消息内容
            # 格式: 昵称(QQ号): 消息内容
            content_part = line[len(time_match.group(0)):].strip()
            
            # 查找用户名和消息内容
            user_match = re.match(r'([^(]+)\(([^)]+)\):\s*(.+)', content_part)
            if not user_match:
                return None
            
            player_name = user_match.group(1).strip()
            username = user_match.group(2).strip()
            content = user_match.group(3).strip()
            
            # 解析时间戳
            try:
                # 时间格式: 2024年01月01日 12:00:00
                time_obj = datetime.datetime.strptime(time_str, "%Y年%m月%d日 %H:%M:%S")
                timestamp = time_obj.timestamp()
            except:
                timestamp = time.time()
            
            return {
                "username": username,
                "玩家昵称": player_name,
                "display_name": player_name if player_name else username,
                "content": content,
                "timestamp": timestamp,
                "time_str": time_str
            }
            
        except Exception as e:
            self.log('ERROR', f"解析日志消息失败: {line}, 错误: {str(e)}", 'SERVER')
            return None

#==========================全服大喇叭消息处理==========================
 
 



#==========================聊天消息处理==========================
    #处理聊天消息（暂未完成）
    def _handle_chat_message(self, client_id, message):
        """处理聊天消息"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "发送聊天消息")
        if not logged_in:
            return self.send_data(client_id, response)
        
        content = message.get("content", "")
        if not content.strip():
            return self.send_data(client_id, {
                "type": "chat_response",
                "success": False,
                "message": "消息内容不能为空"
            })
        
        username = self.user_data[client_id]["username"]
        
        # 广播聊天消息给所有在线用户
        chat_message = {
            "type": "chat_message",
            "username": username,
            "content": content,
            "timestamp": time.time()
        }
        
        self.broadcast(chat_message)
        self.log('INFO', f"用户 {username} 发送聊天消息: {content}", 'SERVER')
        
        return True
    
#==========================聊天消息处理==========================




#==========================每日签到处理==========================
    #加载每日签到配置
    def _load_daily_check_in_config(self):
        """加载每日签到配置 - 优先使用MongoDB，失败则回退到JSON文件"""
        # 优先尝试从MongoDB获取配置
        if hasattr(self, 'use_mongodb') and self.use_mongodb and self.mongo_api:
            try:
                config = self.mongo_api.get_daily_checkin_config()
                if config:
                    self.log('INFO', "从MongoDB成功加载每日签到配置", 'SERVER')
                    return config
                else:
                    self.log('WARNING', "MongoDB中未找到每日签到配置，尝试使用JSON文件", 'SERVER')
            except Exception as e:
                self.log('ERROR', f"从MongoDB加载每日签到配置失败: {e}，回退到JSON文件", 'SERVER')
        
        # 回退到JSON文件
        try:
            config_path = os.path.join(self.config_dir, "daily_checkin_config.json")
            if os.path.exists(config_path):
                with open(config_path, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    self.log('INFO', "从JSON文件成功加载每日签到配置", 'SERVER')
                    return config
        except Exception as e:
            self.log('ERROR', f"从JSON文件加载每日签到配置失败: {e}", 'SERVER')
        
        # 默认配置
        self.log('WARNING', "使用默认每日签到配置", 'SERVER')
        return {
            "基础奖励": {
                "金币": {"最小值": 200, "最大值": 500, "图标": "💰", "颜色": "#FFD700"},
                "经验": {"最小值": 50, "最大值": 120, "图标": "⭐", "颜色": "#00BFFF"}
            },
            "种子奖励": {
                "普通": {"概率": 0.6, "数量范围": [2, 5], "种子池": ["小麦", "胡萝卜", "土豆", "稻谷"]},
                "优良": {"概率": 0.25, "数量范围": [2, 4], "种子池": ["玉米", "番茄", "洋葱", "大豆", "豌豆", "黄瓜", "大白菜"]},
                "稀有": {"概率": 0.12, "数量范围": [1, 3], "种子池": ["草莓", "花椰菜", "柿子", "蓝莓", "树莓"]},
                "史诗": {"概率": 0.025, "数量范围": [1, 2], "种子池": ["葡萄", "南瓜", "芦笋", "茄子", "向日葵", "蕨菜"]},
                "传奇": {"概率": 0.005, "数量范围": [1, 1], "种子池": ["西瓜", "甘蔗", "香草", "甜菜", "人参", "富贵竹", "芦荟", "哈密瓜"]}
            },
            "连续签到奖励": {
                "第3天": {"额外金币": 100, "额外经验": 50, "描述": "连续签到奖励"},
                "第7天": {"额外金币": 200, "额外经验": 100, "描述": "一周连击奖励"},
                "第14天": {"额外金币": 500, "额外经验": 200, "描述": "半月连击奖励"},
                "第21天": {"额外金币": 800, "额外经验": 300, "描述": "三周连击奖励"},
                "第30天": {"额外金币": 1500, "额外经验": 500, "描述": "满月连击奖励"}
            }
        }
    
    #更新每日签到配置到MongoDB
    def _update_daily_checkin_config_to_mongodb(self, config_data):
        """更新每日签到配置到MongoDB"""
        if hasattr(self, 'use_mongodb') and self.use_mongodb and self.mongo_api:
            try:
                success = self.mongo_api.update_daily_checkin_config(config_data)
                if success:
                    self.log('INFO', "成功更新每日签到配置到MongoDB", 'SERVER')
                    return True
                else:
                    self.log('ERROR', "更新每日签到配置到MongoDB失败", 'SERVER')
                    return False
            except Exception as e:
                self.log('ERROR', f"更新每日签到配置到MongoDB异常: {e}", 'SERVER')
                return False
        else:
            self.log('WARNING', "MongoDB未连接，无法更新配置", 'SERVER')
            return False
    
    #处理每日签到请求
    def _handle_daily_check_in_request(self, client_id, message):
        """处理每日签到请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "每日签到", "daily_check_in")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "daily_check_in")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 清理过期签到记录并使用新格式
        self._cleanup_check_in_history(player_data)
        
        # 检查今日是否已签到
        current_time = datetime.datetime.now()
        today_key = current_time.strftime("%Y年%m月%d日")
        check_in_history = player_data.get("签到历史", {})
        
        # 检查今日是否已签到
        for time_key in check_in_history.keys():
            if time_key.startswith(today_key):
                return self.send_data(client_id, {
                    "type": "daily_check_in_response",
                    "success": False,
                    "message": "今日已签到，请明日再来",
                    "has_checked_in": True
                })
        
        # 计算连续签到天数
        consecutive_days = self._calculate_consecutive_check_in_days_new(check_in_history)
        
        # 生成签到奖励
        config = self._load_daily_check_in_config()
        rewards = self._generate_check_in_rewards_new(consecutive_days, config)
        
        # 发放奖励
        self._apply_check_in_rewards(player_data, rewards)
        
        # 保存签到记录 - 使用新格式
        if "签到历史" not in player_data:
            player_data["签到历史"] = {}
        
        time_key = current_time.strftime("%Y年%m月%d日%H时%M分%S秒")
        reward_text = self._format_reward_text_simple(rewards)
        player_data["签到历史"][time_key] = reward_text
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 完成每日签到，连续 {consecutive_days} 天，获得奖励: {rewards}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "daily_check_in_response",
            "success": True,
            "message": f"签到成功！连续签到 {consecutive_days} 天",
            "rewards": rewards,
            "consecutive_days": consecutive_days,
            "updated_data": {
                "钱币": player_data["钱币"],
                "经验值": player_data["经验值"],
                "等级": player_data["等级"],
                "种子仓库": player_data.get("种子仓库", [])
            }
        })
    
    #处理客户端获取签到数据请求
    def _handle_get_check_in_data_request(self, client_id, message):
        """处理获取签到数据请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "获取签到数据", "get_check_in_data")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "get_check_in_data")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 清理过期签到记录
        self._cleanup_check_in_history(player_data)
        
        check_in_history = player_data.get("签到历史", {})
        
        # 计算连续签到天数
        consecutive_days = self._calculate_consecutive_check_in_days_new(check_in_history)
        
        # 检查今日是否已签到
        current_time = datetime.datetime.now()
        today_key = current_time.strftime("%Y年%m月%d日")
        has_checked_in_today = any(time_key.startswith(today_key) for time_key in check_in_history.keys())
        
        return self.send_data(client_id, {
            "type": "check_in_data_response",
            "success": True,
            "check_in_data": check_in_history,
            "consecutive_days": consecutive_days,
            "has_checked_in_today": has_checked_in_today,
            "current_date": current_time.strftime("%Y年%m月%d日")
        })
    
    #清理过期签到记录
    def _cleanup_check_in_history(self, player_data):
        """清理过期签到记录，只保留最近30天的记录"""
        if "签到历史" not in player_data:
            return
        
        current_time = datetime.datetime.now()
        cutoff_time = current_time - datetime.timedelta(days=30)
        
        # 清理过期记录
        history = player_data["签到历史"]
        keys_to_remove = []
        
        for time_key in history.keys():
            try:
                # 解析时间字符串
                check_time = datetime.datetime.strptime(time_key, "%Y年%m月%d日%H时%M分%S秒")
                if check_time < cutoff_time:
                    keys_to_remove.append(time_key)
            except:
                # 如果解析失败，删除这条记录
                keys_to_remove.append(time_key)
        
        for key in keys_to_remove:
            del history[key]
    
    #计算连续签到天数（新版本）
    def _calculate_consecutive_check_in_days_new(self, check_in_history):
        """计算连续签到天数（新版本）"""
        if not check_in_history:
            return 0
        
        # 提取所有签到日期（只取日期部分）
        check_dates = set()
        for time_key in check_in_history.keys():
            try:
                check_time = datetime.datetime.strptime(time_key, "%Y年%m月%d日%H时%M分%S秒")
                date_str = check_time.strftime("%Y-%m-%d")
                check_dates.add(date_str)
            except:
                continue
        
        if not check_dates:
            return 0
        
        # 从今天开始向前计算连续天数
        consecutive_days = 0
        current_date = datetime.datetime.now()
        
        # 检查今天是否已签到
        today_str = current_date.strftime("%Y-%m-%d")
        if today_str in check_dates:
            consecutive_days += 1
            check_date = current_date - datetime.timedelta(days=1)
        else:
            check_date = current_date - datetime.timedelta(days=1)
        
        # 向前查找连续签到天数
        while True:
            date_str = check_date.strftime("%Y-%m-%d")
            if date_str in check_dates:
                consecutive_days += 1
                check_date -= datetime.timedelta(days=1)
            else:
                break
            
            # 限制最大连续天数为30天
            if consecutive_days >= 30:
                break
        
        return consecutive_days
    
    #生成签到奖励（新版本）
    def _generate_check_in_rewards_new(self, consecutive_days, config):
        """生成签到奖励（新版本）"""
        import random
        
        rewards = {}
        
        # 基础奖励倍数
        base_multiplier = 1.0 + (consecutive_days - 1) * 0.1
        max_multiplier = 3.0
        multiplier = min(base_multiplier, max_multiplier)
        
        # 基础金币奖励
        coin_config = config.get("基础奖励", {}).get("金币", {})
        base_coins = random.randint(coin_config.get("最小值", 200), coin_config.get("最大值", 500))
        rewards["coins"] = int(base_coins * multiplier)
        
        # 基础经验奖励
        exp_config = config.get("基础奖励", {}).get("经验", {})
        base_exp = random.randint(exp_config.get("最小值", 50), exp_config.get("最大值", 120))
        rewards["exp"] = int(base_exp * multiplier)
        
        # 种子奖励
        seeds = self._generate_check_in_seeds_new(consecutive_days, config)
        if seeds:
            rewards["seeds"] = seeds
        
        # 连续签到特殊奖励
        consecutive_rewards = config.get("连续签到奖励", {})
        for milestone, bonus in consecutive_rewards.items():
            milestone_days = int(milestone.replace("第", "").replace("天", ""))
            if consecutive_days >= milestone_days:
                if "额外金币" in bonus:
                    rewards["bonus_coins"] = bonus["额外金币"]
                if "额外经验" in bonus:
                    rewards["bonus_exp"] = bonus["额外经验"]
        
        return rewards
    
    #生成签到种子奖励（新版本）
    def _generate_check_in_seeds_new(self, consecutive_days, config):
        """生成签到种子奖励（新版本）"""
        import random
        
        seeds = []
        seed_configs = config.get("种子奖励", {})
        
        # 根据连续签到天数确定种子稀有度
        if consecutive_days <= 2:
            rarity = "普通"
        elif consecutive_days <= 5:
            rarity = "优良"
        elif consecutive_days <= 10:
            rarity = "稀有"
        elif consecutive_days <= 15:
            rarity = "史诗"
        else:
            rarity = "传奇"
        
        # 获取对应稀有度的种子池
        rarity_config = seed_configs.get(rarity, {})
        seed_pool = rarity_config.get("种子池", [])
        quantity_range = rarity_config.get("数量范围", [1, 2])
        
        if not seed_pool:
            return seeds
        
        # 生成1-3个种子
        seed_count = random.randint(1, min(3, len(seed_pool)))
        selected_seeds = random.sample(seed_pool, seed_count)
        
        for seed_name in selected_seeds:
            quantity = random.randint(quantity_range[0], quantity_range[1])
            seeds.append({
                "name": seed_name,
                "quantity": quantity,
                "quality": rarity
            })
        
        return seeds
    
    #格式化奖励文本（简单版本）
    def _format_reward_text_simple(self, rewards):
        """格式化奖励文本（简单版本）"""
        parts = []
        
        if "coins" in rewards:
            parts.append(f"金币{rewards['coins']}")
        if "exp" in rewards:
            parts.append(f"经验{rewards['exp']}")
        if "bonus_coins" in rewards:
            parts.append(f"额外金币{rewards['bonus_coins']}")
        if "bonus_exp" in rewards:
            parts.append(f"额外经验{rewards['bonus_exp']}")
        
        if "seeds" in rewards:
            for seed in rewards["seeds"]:
                parts.append(f"{seed['name']}x{seed['quantity']}")
        
        return " ".join(parts)
    
    #应用签到奖励到玩家数据
    def _apply_check_in_rewards(self, player_data, rewards):
        """应用签到奖励到玩家数据"""
        # 应用钱币奖励
        if "coins" in rewards:
            player_data["钱币"] = player_data.get("钱币", 0) + rewards["coins"]
        
        if "bonus_coins" in rewards:
            player_data["钱币"] = player_data.get("钱币", 0) + rewards["bonus_coins"]
        
        # 应用经验奖励
        if "exp" in rewards:
            player_data["经验值"] = player_data.get("经验值", 0) + rewards["exp"]
        
        if "bonus_exp" in rewards:
            player_data["经验值"] = player_data.get("经验值", 0) + rewards["bonus_exp"]
        
        # 检查升级
        level_up_experience = 100 * player_data.get("等级", 1)
        while player_data.get("经验值", 0) >= level_up_experience:
            player_data["等级"] = player_data.get("等级", 1) + 1
            player_data["经验值"] -= level_up_experience
            level_up_experience = 100 * player_data["等级"]
        
        # 应用种子奖励
        if "seeds" in rewards:
            if "种子仓库" not in player_data:
                player_data["种子仓库"] = []
            
            for seed_reward in rewards["seeds"]:
                seed_name = seed_reward["name"]
                quantity = seed_reward["quantity"]
                quality = seed_reward["quality"]
                
                # 查找背包中是否已有该种子
                found = False
                for item in player_data["种子仓库"]:
                    if item.get("name") == seed_name:
                        item["count"] += quantity
                        found = True
                        break
                
                # 如果背包中没有，添加新条目
                if not found:
                    player_data["种子仓库"].append({
                        "name": seed_name,
                        "quality": quality,
                        "count": quantity
                    })
    
#==========================每日签到处理==========================




#==========================新手大礼包处理==========================

    #处理新手大礼包请求
    def _handle_new_player_gift_request(self, client_id, message):
        """处理新手大礼包请求"""
        try:
            # 检查用户是否已登录
            logged_in, response = self._check_user_logged_in(client_id, "领取新手大礼包", "new_player_gift")
            if not logged_in:
                return self.send_data(client_id, response)
            
            # 获取玩家数据
            player_data, username, response = self._load_player_data_with_check(client_id, "new_player_gift")
            if not player_data:
                return self.send_data(client_id, response)
            
            # 加载新手礼包配置
            config = self._load_new_player_config()
            gift_config = config.get("新手礼包配置", {})
            
            # 检查是否已经领取过新手大礼包
            new_player_gift_data = player_data.get("新手礼包", {})
            if new_player_gift_data.get("已领取", False):
                return self.send_data(client_id, {
                    "type": "new_player_gift_response",
                    "success": False,
                    "message": gift_config.get("提示消息", {}).get("已领取", "新手大礼包已经领取过了")
                })
            
            # 获取新手大礼包内容
            reward_content = gift_config.get("奖励内容", {})
            
            # 应用奖励
            self._apply_new_player_gift_rewards_new(player_data, reward_content)
            
            # 标记已领取
            player_data["新手礼包"] = {
                "已领取": True,
                "领取时间": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }
            
            # 保存玩家数据
            self.save_player_data(username, player_data)
            
            self.log('INFO', f"玩家 {username} 成功领取新手大礼包", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "new_player_gift_response",
                "success": True,
                "message": gift_config.get("提示消息", {}).get("成功", "新手大礼包领取成功！"),
                "gift_contents": reward_content,
                "updated_data": {
                    "钱币": player_data["钱币"],
                    "经验值": player_data["经验值"],
                    "等级": player_data["等级"],
                    "种子仓库": player_data.get("种子仓库", []),
                    "宠物背包": player_data.get("宠物背包", []),
                    "新手礼包": player_data["新手礼包"]
                }
            })
            
        except Exception as e:
            # 捕获所有异常，防止服务器崩溃
            self.log('ERROR', f"处理新手大礼包请求时出错: {str(e)}", 'SERVER')
            
            # 发送错误响应
            return self.send_data(client_id, {
                "type": "new_player_gift_response",
                "success": False,
                "message": "服务器处理新手大礼包时出现错误，请稍后重试"
            })
    
    #应用新手大礼包奖励到玩家数据
    def _apply_new_player_gift_rewards(self, player_data, gift_contents):
        """应用新手大礼包奖励到玩家数据（旧格式，保留兼容性）"""
        # 应用金币奖励
        if "coins" in gift_contents:
            player_data["钱币"] = player_data.get("钱币", 0) + gift_contents["coins"]
        
        # 应用经验奖励
        if "经验值" in gift_contents:
            player_data["经验值"] = player_data.get("经验值", 0) + gift_contents["经验值"]
            
            # 检查升级
            level_up_experience = 100 * player_data.get("等级", 1)
            while player_data.get("经验值", 0) >= level_up_experience:
                player_data["等级"] = player_data.get("等级", 1) + 1
                player_data["经验值"] -= level_up_experience
                level_up_experience = 100 * player_data["等级"]
        
        # 应用种子奖励
        if "seeds" in gift_contents:
            if "种子仓库" not in player_data:
                player_data["种子仓库"] = []
            
            for seed_reward in gift_contents["seeds"]:
                seed_name = seed_reward["name"]
                quantity = seed_reward["count"]
                quality = seed_reward["quality"]
                
                # 查找背包中是否已有该种子
                found = False
                for item in player_data["种子仓库"]:
                    if item.get("name") == seed_name:
                        item["count"] += quantity
                        found = True
                        break
                
                # 如果背包中没有，添加新条目
                if not found:
                    player_data["种子仓库"].append({
                        "name": seed_name,
                        "quality": quality,
                        "count": quantity
                    })
    
    #应用新手大礼包奖励到玩家数据（新中文格式）
    def _apply_new_player_gift_rewards_new(self, player_data, reward_content):
        """应用新手大礼包奖励到玩家数据（新中文格式）"""
        # 应用金币奖励
        if "金币" in reward_content:
            player_data["钱币"] = player_data.get("钱币", 0) + reward_content["金币"]
        
        # 应用经验奖励
        if "经验" in reward_content:
            player_data["经验值"] = player_data.get("经验值", 0) + reward_content["经验"]
            
            # 检查升级
            while True:
                level_up_experience = 100 * player_data.get("等级", 1)
                if player_data.get("经验值", 0) >= level_up_experience:
                    player_data["等级"] = player_data.get("等级", 1) + 1
                    player_data["经验值"] -= level_up_experience
                else:
                    break
        
        # 应用种子奖励
        if "种子" in reward_content:
            if "种子仓库" not in player_data:
                player_data["种子仓库"] = []
            
            for seed_reward in reward_content["种子"]:
                seed_name = seed_reward["名称"]
                quantity = seed_reward["数量"]
                quality = seed_reward["品质"]
                
                # 查找背包中是否已有该种子
                found = False
                for item in player_data["种子仓库"]:
                    if item.get("name") == seed_name:
                        item["count"] += quantity
                        found = True
                        break
                
                # 如果背包中没有，添加新条目
                if not found:
                    player_data["种子仓库"].append({
                        "name": seed_name,
                        "quality": quality,
                        "count": quantity
                    })

#==========================新手大礼包处理==========================



#==========================幸运抽奖处理==========================

    #处理幸运抽奖请求
    def _handle_lucky_draw_request(self, client_id, message):
        """处理幸运抽奖请求"""
        try:
            # 检查用户是否已登录
            logged_in, response = self._check_user_logged_in(client_id, "幸运抽奖", "lucky_draw")
            if not logged_in:
                return self.send_data(client_id, response)
            
            # 获取玩家数据
            player_data, username, response = self._load_player_data_with_check(client_id, "lucky_draw")
            if not player_data:
                return self.send_data(client_id, response)
            
            # 删除历史记录（如果存在）
            if "lucky_draw_history" in player_data:
                del player_data["lucky_draw_history"]
            
            draw_type = message.get("draw_type", "single")  # single, five, ten
            
            # 从配置文件获取费用
            config = self._load_lucky_draw_config()
            costs = config.get("抽奖费用", {"单抽": 800, "五连抽": 3600, "十连抽": 6400})
            
            # 计算抽奖费用和数量
            if draw_type == "single":
                draw_count = 1
                total_cost = costs.get("单抽", 800)
            elif draw_type == "five":
                draw_count = 5
                total_cost = costs.get("五连抽", 3600)
            elif draw_type == "ten":
                draw_count = 10
                total_cost = costs.get("十连抽", 6400)
            else:
                return self.send_data(client_id, {
                    "type": "lucky_draw_response",
                    "success": False,
                    "message": "无效的抽奖类型"
                })
            
            # 检查玩家金钱是否足够
            if player_data.get("钱币", 0) < total_cost:
                return self.send_data(client_id, {
                    "type": "lucky_draw_response",
                    "success": False,
                    "message": f"金钱不足，需要 {total_cost} 金币"
                })
            
            # 扣除金钱
            player_data["钱币"] -= total_cost
            
            # 生成奖励
            rewards = self._generate_lucky_draw_rewards(draw_count, draw_type, config)
            
            # 应用奖励到玩家数据
            self._apply_lucky_draw_rewards(player_data, rewards)
            
            # 保存玩家数据
            self.save_player_data(username, player_data)
            
            self.log('INFO', f"玩家 {username} 进行{draw_type}抽奖，花费 {total_cost} 金币，获得 {len(rewards)} 个奖励", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "lucky_draw_response",
                "success": True,
                "message": f"{draw_type}抽奖成功！",
                "draw_type": draw_type,
                "cost": total_cost,
                "rewards": rewards,
                "updated_data": {
                    "钱币": player_data["钱币"],
                    "经验值": player_data["经验值"],
                    "等级": player_data["等级"],
                    "种子仓库": player_data.get("种子仓库", [])
                }
            })
            
        except Exception as e:
            self.log('ERROR', f"处理玩家抽奖请求时出错: {str(e)}", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "lucky_draw_response",
                "success": False,
                "message": "服务器处理抽奖时出现错误，请稍后重试"
            })
    
    #加载抽奖配置
    def _load_lucky_draw_config(self):
        """加载抽奖配置（优先从MongoDB读取）"""
        # 优先尝试从MongoDB读取
        if self.use_mongodb and self.mongo_api:
            try:
                config = self.mongo_api.get_lucky_draw_config()
                if config:
                    self.log('INFO', "成功从MongoDB加载幸运抽奖配置", 'SERVER')
                    return config
                else:
                    self.log('WARNING', "MongoDB中未找到幸运抽奖配置，尝试从JSON文件读取", 'SERVER')
            except Exception as e:
                self.log('ERROR', f"从MongoDB读取幸运抽奖配置失败: {e}，尝试从JSON文件读取", 'SERVER')
        
        # 回退到JSON文件
        try:
            config_path = os.path.join(self.config_dir, "lucky_draw_config.json")
            if os.path.exists(config_path):
                with open(config_path, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    self.log('INFO', "成功从JSON文件加载幸运抽奖配置", 'SERVER')
                    return config
        except Exception as e:
            self.log('ERROR', f"从JSON文件读取幸运抽奖配置失败: {e}，使用默认配置", 'SERVER')
        
        # 默认配置
        self.log('WARNING', "使用默认幸运抽奖配置", 'SERVER')
        return {
            "抽奖费用": {"单抽": 800, "五连抽": 3600, "十连抽": 6400},
            "概率配置": {
                "普通": {"概率": 0.45, "金币范围": [100, 300], "经验范围": [50, 150], "种子数量": [2, 4]},
                "优良": {"概率": 0.25, "金币范围": [300, 600], "经验范围": [150, 300], "种子数量": [1, 3]},
                "稀有": {"概率": 0.12, "金币范围": [600, 1000], "经验范围": [300, 500], "种子数量": [1, 2]},
                "史诗": {"概率": 0.025, "金币范围": [1000, 1500], "经验范围": [500, 800], "种子数量": [1, 1]},
                "传奇": {"概率": 0.005, "金币范围": [1500, 2500], "经验范围": [800, 1200], "种子数量": [1, 1]},
                "空奖": {"概率": 0.15, "提示语": ["谢谢惠顾", "下次再来", "再试一次", "继续努力"]}
            }
        }

    #加载在线礼包配置
    def _load_online_gift_config(self):
        """加载在线礼包配置"""
        # 优先从MongoDB读取配置
        if hasattr(self, 'mongo_api') and self.mongo_api and self.mongo_api.is_connected():
            try:
                config = self.mongo_api.get_online_gift_config()
                if config:
                    self.log('INFO', '成功从MongoDB加载在线礼包配置', 'SERVER')
                    return config
                else:
                    self.log('WARNING', '从MongoDB未找到在线礼包配置，尝试从JSON文件加载', 'SERVER')
            except Exception as e:
                self.log('ERROR', f'从MongoDB加载在线礼包配置失败: {str(e)}，尝试从JSON文件加载', 'SERVER')
        
        # 回退到JSON文件
        try:
            config_path = os.path.join(self.config_dir, "online_gift_config.json")
            if os.path.exists(config_path):
                with open(config_path, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    self.log('INFO', '成功从JSON文件加载在线礼包配置', 'SERVER')
                    return config
        except Exception as e:
            self.log('ERROR', f"从JSON文件加载在线礼包配置失败: {str(e)}", 'SERVER')
        
        # 默认配置
        self.log('WARNING', '使用默认在线礼包配置', 'SERVER')
        return {
            "在线礼包配置": {
                "1分钟": {"时长秒数": 60, "奖励": {"金币": 100, "经验": 50, "种子": [{"名称": "小麦", "数量": 5}]}},
                "5分钟": {"时长秒数": 300, "奖励": {"金币": 500, "经验": 250, "种子": [{"名称": "玉米", "数量": 3}]}},
                "30分钟": {"时长秒数": 1800, "奖励": {"金币": 1500, "经验": 750, "种子": [{"名称": "草莓", "数量": 2}]}},
                "1小时": {"时长秒数": 3600, "奖励": {"金币": 3000, "经验": 1500, "种子": [{"名称": "葡萄", "数量": 2}]}}
            },
            "每日重置": True
        }
    
    #加载新手礼包配置
    def _load_new_player_config(self):
        """加载新手礼包配置"""
        # 优先从MongoDB读取配置
        if hasattr(self, 'mongo_api') and self.mongo_api and self.mongo_api.is_connected():
            try:
                config = self.mongo_api.get_new_player_config()
                if config:
                    self.log('INFO', '成功从MongoDB加载新手大礼包配置', 'SERVER')
                    return config
                else:
                    self.log('WARNING', '从MongoDB未找到新手大礼包配置，尝试从JSON文件加载', 'SERVER')
            except Exception as e:
                self.log('ERROR', f'从MongoDB加载新手大礼包配置失败: {str(e)}，尝试从JSON文件加载', 'SERVER')
        
        # 回退到JSON文件
        try:
            config_path = os.path.join(self.config_dir, "new_player_config.json")
            if os.path.exists(config_path):
                with open(config_path, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    self.log('INFO', '成功从JSON文件加载新手大礼包配置', 'SERVER')
                    return config
        except Exception as e:
            self.log('ERROR', f"从JSON文件加载新手礼包配置失败: {str(e)}", 'SERVER')
        
        # 默认配置
        self.log('WARNING', '使用默认新手大礼包配置', 'SERVER')
        return {
            "新手礼包配置": {
                "奖励内容": {
                    "金币": 6000,
                    "经验": 1000,
                    "种子": [
                        {"名称": "龙果", "品质": "传奇", "数量": 1},
                        {"名称": "杂交树1", "品质": "传奇", "数量": 1},
                        {"名称": "杂交树2", "品质": "传奇", "数量": 1}
                    ]
                },
                "提示消息": {
                    "成功": "新手大礼包领取成功！获得6000金币、1000经验和3个传奇种子",
                    "已领取": "新手大礼包已经领取过了"
                }
            }
        }
    
    #生成幸运抽奖奖励
    def _generate_lucky_draw_rewards(self, count: int, draw_type: str, config: dict):
        """生成幸运抽奖奖励"""
        import random
        
        # 加载作物配置
        crop_data = self._load_crop_data()
        
        rewards = []
        
        # 根据 crop_data.json 构建奖励池
        seed_pools = {"普通": [], "优良": [], "稀有": [], "史诗": [], "传奇": []}
        
        for crop_name, crop_info in crop_data.items():
            if not crop_info.get("能否购买", True):
                continue
                
            quality = crop_info.get("品质", "普通")
            if quality in seed_pools:
                seed_pools[quality].append(crop_name)
        
        # 十连抽保底机制
        guaranteed_rare = (draw_type == "ten")
        rare_given = False
        
        for i in range(count):
            # 生成单个奖励
            reward = self._generate_single_lucky_reward(
                seed_pools, config, guaranteed_rare and i == count - 1 and not rare_given
            )
            
            # 检查是否给出了稀有奖励
            if reward.get("rarity", "普通") in ["稀有", "史诗", "传奇"]:
                rare_given = True
            
            rewards.append(reward)
        
        return rewards
    
    #生成单个抽奖奖励
    def _generate_single_lucky_reward(self, seed_pools: dict, config: dict, force_rare=False):
        """生成单个幸运抽奖奖励"""
        import random
        
        prob_config = config.get("概率配置", {})
        
        # 决定稀有度
        if force_rare:
            # 强制稀有：33%稀有，33%史诗，34%传奇
            rand = random.random()
            if rand < 0.33:
                rarity = "稀有"
            elif rand < 0.66:
                rarity = "史诗"
            else:
                rarity = "传奇"
        else:
            # 正常概率
            rand = random.random()
            cumulative = 0
            rarity = "普通"
            
            for r, config_data in prob_config.items():
                prob = config_data.get("概率", 0)
                cumulative += prob
                if rand < cumulative:
                    rarity = r
                    break
        
        # 根据稀有度生成奖励
        if rarity == "空奖":
            empty_messages = prob_config.get("空奖", {}).get("提示语", ["谢谢惠顾"])
            return {
                "type": "empty",
                "name": random.choice(empty_messages),
                "rarity": "空奖",
                "amount": 0
            }
        
        # 获取稀有度配置
        rarity_config = prob_config.get(rarity, {})
        
        # 根据奖励类型权重选择奖励类型
        type_weights = config.get("奖励类型权重", {}).get(rarity, {"金币": 0.5, "经验": 0.3, "种子": 0.2})
        
        # 随机选择奖励类型
        rand = random.random()
        cumulative = 0
        reward_type = "金币"
        
        for r_type, weight in type_weights.items():
            cumulative += weight
            if rand < cumulative:
                reward_type = r_type
                break
        
        # 生成具体奖励
        if reward_type == "金币":
            coin_range = rarity_config.get("金币范围", [100, 300])
            return {
                "type": "coins",
                "name": "金币",
                "rarity": rarity,
                "amount": random.randint(coin_range[0], coin_range[1])
            }
        
        elif reward_type == "经验":
            exp_range = rarity_config.get("经验范围", [50, 150])
            return {
                "type": "exp",
                "name": "经验",
                "rarity": rarity,
                "amount": random.randint(exp_range[0], exp_range[1])
            }
        
        elif reward_type == "种子":
            seeds = seed_pools.get(rarity, [])
            if not seeds:
                # 如果没有对应稀有度的种子，给金币
                coin_range = rarity_config.get("金币范围", [100, 300])
                return {
                    "type": "coins",
                    "name": "金币",
                    "rarity": rarity,
                    "amount": random.randint(coin_range[0], coin_range[1])
                }
            
            seed_count_range = rarity_config.get("种子数量", [1, 2])
            return {
                "type": "seed",
                "name": random.choice(seeds),
                "rarity": rarity,
                "amount": random.randint(seed_count_range[0], seed_count_range[1])
            }
        
        elif reward_type == "礼包":
            package_config = config.get("礼包配置", {})
            package_names = [name for name, info in package_config.items() if info.get("稀有度") == rarity]
            
            if not package_names:
                # 如果没有对应稀有度的礼包，给金币
                coin_range = rarity_config.get("金币范围", [100, 300])
                return {
                    "type": "coins",
                    "name": "金币",
                    "rarity": rarity,
                    "amount": random.randint(coin_range[0], coin_range[1])
                }
            
            package_name = random.choice(package_names)
            package_info = package_config[package_name]
            contents = []
            
            # 生成礼包内容
            content_config = package_info.get("内容", {})
            
            if "金币" in content_config:
                coin_range = content_config["金币"]
                contents.append({
                    "type": "coins",
                    "amount": random.randint(coin_range[0], coin_range[1]),
                    "rarity": rarity
                })
            
            if "经验" in content_config:
                exp_range = content_config["经验"]
                contents.append({
                    "type": "exp",
                    "amount": random.randint(exp_range[0], exp_range[1]),
                    "rarity": rarity
                })
            
            if "种子数量" in content_config:
                seed_count_range = content_config["种子数量"]
                lower_rarity = {"优良": "普通", "稀有": "优良", "史诗": "稀有", "传奇": "史诗"}.get(rarity, "普通")
                seeds = seed_pools.get(lower_rarity, [])
                if seeds:
                    contents.append({
                        "type": "seed",
                        "name": random.choice(seeds),
                        "amount": random.randint(seed_count_range[0], seed_count_range[1]),
                        "rarity": rarity
                    })
            
            return {
                "type": "package",
                "name": package_name,
                "rarity": rarity,
                "amount": 1,
                "contents": contents
            }
        
        # 默认给金币
        coin_range = rarity_config.get("金币范围", [100, 300])
        return {
            "type": "coins",
            "name": "金币",
            "rarity": rarity,
            "amount": random.randint(coin_range[0], coin_range[1])
        }
    
    #应用幸运抽奖奖励到玩家数据
    def _apply_lucky_draw_rewards(self, player_data, rewards):
        """应用幸运抽奖奖励到玩家数据"""
        for reward in rewards:
            reward_type = reward.get("type", "empty")
            
            if reward_type == "empty":
                continue  # 空奖励不处理
            
            elif reward_type == "coins":
                player_data["钱币"] = player_data.get("钱币", 0) + reward.get("amount", 0)
            
            elif reward_type == "exp":
                player_data["经验值"] = player_data.get("经验值", 0) + reward.get("amount", 0)
                
                # 检查升级
                level_up_experience = 100 * player_data.get("等级", 1)
                while player_data.get("经验值", 0) >= level_up_experience:
                    player_data["等级"] = player_data.get("等级", 1) + 1
                    player_data["经验值"] -= level_up_experience
                    level_up_experience = 100 * player_data["等级"]
            
            elif reward_type == "seed":
                if "种子仓库" not in player_data:
                    player_data["种子仓库"] = []
                
                # 查找背包中是否已有该种子
                found = False
                for item in player_data["种子仓库"]:
                    if item.get("name") == reward.get("name", ""):
                        item["count"] += reward.get("amount", 0)
                        found = True
                        break
                
                # 如果背包中没有，添加新条目
                if not found:
                    player_data["种子仓库"].append({
                        "name": reward.get("name", "未知种子"),
                        "quality": reward.get("rarity", "普通"),
                        "count": reward.get("amount", 0)
                    })
            
            elif reward_type == "package":
                # 递归处理礼包内容
                contents = reward.get("contents", [])
                if contents:
                    # 为礼包内容添加默认的rarity字段
                    for content in contents:
                        if not content.get("rarity"):
                            content["rarity"] = reward.get("rarity", "普通")
                    
                    # 递归处理礼包内容
                    self._apply_lucky_draw_rewards(player_data, contents)
    
#==========================幸运抽奖处理==========================


#==========================发送游戏操作错误处理==========================
    #发送游戏操作错误
    def _send_action_error(self, client_id, action_type, message):
        """发送游戏操作错误响应"""
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": action_type,
            "success": False,
            "message": message
        })
#==========================发送游戏操作错误处理==========================   


# ================================账户设置处理方法================================
    def _handle_modify_account_info_request(self, client_id, message):
        """处理修改账号信息请求"""
        # 检查用户是否已登录
        is_logged_in, error_response = self._check_user_logged_in(client_id, "修改账号信息")
        if not is_logged_in:
            return self._send_modify_account_error(client_id, error_response["message"])
        
        # 加载玩家数据
        player_data, username, error_response = self._load_player_data_with_check(client_id, "modify_account_info")
        if not player_data:
            return self.send_data(client_id, error_response)
        
        # 获取新的信息
        new_password = message.get("new_password", "").strip()
        new_player_name = message.get("new_player_name", "").strip()
        new_farm_name = message.get("new_farm_name", "").strip()
        new_personal_profile = message.get("new_personal_profile", "").strip()
        
        # 验证输入
        if not new_password:
            return self._send_modify_account_error(client_id, "密码不能为空")
        
        if not new_player_name:
            return self._send_modify_account_error(client_id, "玩家昵称不能为空")
        
        if not new_farm_name:
            return self._send_modify_account_error(client_id, "农场名称不能为空")

        if len(new_player_name) > 20:
            return self._send_modify_account_error(client_id, "玩家昵称不能超过20个字符")
        
        if len(new_farm_name) > 20:
            return self._send_modify_account_error(client_id, "农场名称不能超过20个字符")
        
        if len(new_personal_profile) > 100:
            return self._send_modify_account_error(client_id, "个人简介不能超过100个字符")
        
        try:
            # 更新玩家数据
            player_data["玩家密码"] = new_password
            player_data["玩家昵称"] = new_player_name
            player_data["农场名称"] = new_farm_name
            player_data["个人简介"] = new_personal_profile
            
            # 保存到文件
            self.save_player_data(username, player_data)
            
            # 发送成功响应
            self.send_data(client_id, {
                "type": "modify_account_info_response",
                "success": True,
                "message": "账号信息修改成功",
                "updated_data": {
                    "玩家密码": new_password,
                    "玩家昵称": new_player_name,
                    "农场名称": new_farm_name,
                    "个人简介": new_personal_profile
                }
            })
            
            self.log('INFO', f"用户 {username} 修改账号信息成功", 'ACCOUNT')
            
        except Exception as e:
            self.log('ERROR', f"修改账号信息时出错: {str(e)}", 'ACCOUNT')
            return self._send_modify_account_error(client_id, "修改账号信息失败，请稍后重试")

    def _handle_delete_account_request(self, client_id, message):
        """处理删除账号请求"""
        # 检查用户是否已登录
        is_logged_in, error_response = self._check_user_logged_in(client_id, "删除账号")
        if not is_logged_in:
            return self._send_delete_account_error(client_id, error_response["message"])
        
        # 获取用户名
        username = self.user_data[client_id]["username"]
        
        try:
            # 优先从MongoDB删除
            if self.use_mongodb and self.mongo_api:
                success = self.mongo_api.delete_player_data(username)
                if not success:
                    self.log('WARNING', f"MongoDB删除失败，尝试删除文件: {username}", 'ACCOUNT')
            
            # 清理用户数据
            if client_id in self.user_data:
                del self.user_data[client_id]
            
            # 发送成功响应
            self.send_data(client_id, {
                "type": "delete_account_response",
                "success": True,
                "message": "账号删除成功，即将返回主菜单"
            })
            
            self.log('INFO', f"用户 {username} 账号删除成功", 'ACCOUNT')
            
            # 稍后断开连接
            import threading
            def delayed_disconnect():
                import time
                time.sleep(2)
                self._remove_client(client_id)
            
            disconnect_thread = threading.Thread(target=delayed_disconnect)
            disconnect_thread.daemon = True
            disconnect_thread.start()
            
        except Exception as e:
            self.log('ERROR', f"删除账号时出错: {str(e)}", 'ACCOUNT')
            return self._send_delete_account_error(client_id, "删除账号失败，请稍后重试")

    def _handle_refresh_player_info_request(self, client_id, message):
        """处理刷新玩家信息请求"""
        # 检查用户是否已登录
        is_logged_in, error_response = self._check_user_logged_in(client_id, "刷新玩家信息")
        if not is_logged_in:
            return self._send_refresh_info_error(client_id, error_response["message"])
        
        # 获取用户名
        username = self.user_data[client_id]["username"]
        
        try:
            # 强制从数据库重新加载最新数据
            player_data = self.load_player_data(username)
            if not player_data:
                return self._send_refresh_info_error(client_id, "无法加载玩家数据")
            
            # 只发送账户相关信息，不发送农场数据等
            account_info = {
                "玩家账号": player_data.get("玩家账号", ""),
                "玩家密码": player_data.get("玩家密码", ""),
                "玩家昵称": player_data.get("玩家昵称", ""),
                "农场名称": player_data.get("农场名称", ""),
                "个人简介": player_data.get("个人简介", ""),
                "等级": player_data.get("等级", 1),
                "经验值": player_data.get("经验值", 0),
                "钱币": player_data.get("钱币", 0)
            }
            
            # 发送刷新后的账户信息
            self.send_data(client_id, {
                "type": "refresh_player_info_response",
                "success": True,
                "message": "玩家信息已刷新",
                "account_info": account_info
            })
            
            self.log('INFO', f"用户 {username} 刷新玩家信息成功", 'ACCOUNT')
            
        except Exception as e:
            self.log('ERROR', f"刷新玩家信息时出错: {str(e)}", 'ACCOUNT')
            return self._send_refresh_info_error(client_id, "刷新玩家信息失败，请稍后重试")

    def _send_modify_account_error(self, client_id, message):
        """发送修改账号信息错误响应"""
        self.send_data(client_id, {
            "type": "modify_account_info_response",
            "success": False,
            "message": message
        })

    def _send_delete_account_error(self, client_id, message):
        """发送删除账号错误响应"""
        self.send_data(client_id, {
            "type": "delete_account_response",
            "success": False,
            "message": message
        })

    def _send_refresh_info_error(self, client_id, message):
        """发送刷新信息错误响应"""
        self.send_data(client_id, {
            "type": "refresh_player_info_response",
            "success": False,
            "message": message
        })

    #处理背包数据同步消息
    def _handle_sync_bag_data(self, client_id, message):
        """处理背包数据同步请求"""
        username = self.user_data.get(client_id, {}).get("username")
        
        if not username:
            return self.send_data(client_id, {
                "type": "sync_bag_data_response",
                "success": False,
                "message": "用户未登录"
            })
        
        # 从数据库加载最新的玩家数据
        player_data = self.load_player_data(username)
        if not player_data:
            return self.send_data(client_id, {
                "type": "sync_bag_data_response",
                "success": False,
                "message": "玩家数据加载失败"
            })
        
        # 提取所有背包数据
        bag_data = {
            "道具背包": player_data.get("道具背包", []),
            "宠物背包": player_data.get("宠物背包", []),
            "种子仓库": player_data.get("种子仓库", []),
            "作物仓库": player_data.get("作物仓库", [])
        }
        
        self.log('INFO', f"用户 {username} 请求同步背包数据", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "sync_bag_data_response",
            "success": True,
            "message": "背包数据同步成功",
            "bag_data": bag_data
        })
    
    def _handle_kick_player(self, client_id, message):
        """处理踢出玩家消息（服务器内部使用）"""
        # 这个函数主要用于接收来自控制台命令的踢出消息
        # 实际的踢出逻辑在 ConsoleCommandsAPI 中处理
        reason = message.get("reason", "您已被管理员踢出服务器")
        duration = message.get("duration", 0)
        
        # 发送踢出通知给客户端
        response = {
            "type": "kick_notification",
            "reason": reason,
            "duration": duration,
            "message": reason
        }
        
        self.log('INFO', f"向客户端 {client_id} 发送踢出通知: {reason}", 'SERVER')
        return self.send_data(client_id, response)

# ================================账户设置处理方法================================


#==========================稻草人系统处理==========================
    def _handle_buy_scare_crow(self, client_id, message):
        """处理购买稻草人请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "购买稻草人", "buy_scare_crow")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "buy_scare_crow")
        if not player_data:
            return self.send_data(client_id, response)
        
        scare_crow_type = message.get("scare_crow_type", "")
        price = message.get("price", 0)
        
        # 加载稻草人配置
        scare_crow_config = self._load_scare_crow_config()
        if not scare_crow_config:
            return self._send_buy_scare_crow_error(client_id, "服务器无法加载稻草人配置")
        
        # 检查稻草人类型是否存在
        if scare_crow_type not in scare_crow_config.get("稻草人类型", {}):
            return self._send_buy_scare_crow_error(client_id, "该稻草人类型不存在")
        
        # 验证价格是否正确
        actual_price = scare_crow_config["稻草人类型"][scare_crow_type]["价格"]
        if price != actual_price:
            return self._send_buy_scare_crow_error(client_id, f"稻草人价格验证失败，实际价格为{actual_price}金币")
        
        # 检查玩家金钱
        if player_data["钱币"] < price:
            return self._send_buy_scare_crow_error(client_id, f"金币不足，需要{price}金币，当前只有{player_data['money']}金币")
        
        # 确保稻草人配置存在
        if "稻草人配置" not in player_data:
            player_data["稻草人配置"] = {
                "已拥有稻草人类型": ["稻草人1"],
                "稻草人展示类型": "",
                "稻草人昵称": "我的稻草人",
                "稻草人昵称颜色": "#ffffff",
                "稻草人说的话": {
                    "第一句话": {"内容": "", "颜色": "#000000"},
                    "第二句话": {"内容": "", "颜色": "#000000"},
                    "第三句话": {"内容": "", "颜色": "#000000"},
                    "第四句话": {"内容": "", "颜色": "#000000"}
                }
            }
        
        # 检查是否已拥有该稻草人
        if scare_crow_type in player_data["稻草人配置"]["已拥有稻草人类型"]:
            return self._send_buy_scare_crow_error(client_id, f"你已经拥有{scare_crow_type}了")
        
        # 扣除金钱
        player_data["钱币"] -= price
        
        # 添加稻草人到已拥有列表
        player_data["稻草人配置"]["已拥有稻草人类型"].append(scare_crow_type)
        
        # 如果是第一个稻草人，设置为展示类型
        if player_data["稻草人配置"]["稻草人展示类型"] == "":
            player_data["稻草人配置"]["稻草人展示类型"] = scare_crow_type
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 购买了稻草人 {scare_crow_type}，花费 {price} 金币", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "buy_scare_crow_response",
            "success": True,
            "message": f"成功购买{scare_crow_type}！",
            "updated_data": {
                "钱币": player_data["钱币"],
                "稻草人配置": player_data["稻草人配置"]
            }
        })
    
    def _handle_modify_scare_crow_config(self, client_id, message):
        """处理修改稻草人配置请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "修改稻草人配置", "modify_scare_crow_config")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "modify_scare_crow_config")
        if not player_data:
            return self.send_data(client_id, response)
        
        config_data = message.get("config_data", {})
        modify_cost = message.get("modify_cost", 300)
        
        # 加载稻草人配置
        scare_crow_config = self._load_scare_crow_config()
        if not scare_crow_config:
            return self._send_modify_scare_crow_config_error(client_id, "服务器无法加载稻草人配置")
        
        # 检查是否只是切换展示类型（不收费）
        is_only_changing_display = (
            len(config_data) == 1 and 
            "稻草人展示类型" in config_data and 
            modify_cost == 0
        )
        
        if not is_only_changing_display:
            # 验证修改费用
            actual_cost = scare_crow_config.get("修改稻草人配置花费", 300)
            if modify_cost != actual_cost:
                return self._send_modify_scare_crow_config_error(client_id, f"修改费用验证失败，实际费用为{actual_cost}金币")
            
            # 检查玩家金钱
            if player_data["钱币"] < modify_cost:
                return self._send_modify_scare_crow_config_error(client_id, f"金币不足，需要{modify_cost}金币，当前只有{player_data['money']}金币")
        
        # 确保稻草人配置存在
        if "稻草人配置" not in player_data:
            return self._send_modify_scare_crow_config_error(client_id, "你还没有稻草人，请先购买稻草人")
        
        # 只在非切换展示类型时扣除金钱
        if not is_only_changing_display:
            player_data["钱币"] -= modify_cost
        
        # 更新稻草人配置
        if "稻草人展示类型" in config_data:
            # 检查展示类型是否已拥有
            owned_types = player_data["稻草人配置"].get("已拥有稻草人类型", [])
            if config_data["稻草人展示类型"] in owned_types:
                player_data["稻草人配置"]["稻草人展示类型"] = config_data["稻草人展示类型"]
            else:
                return self._send_modify_scare_crow_config_error(client_id, "你没有拥有该稻草人类型")
        
        if "稻草人昵称" in config_data:
            player_data["稻草人配置"]["稻草人昵称"] = config_data["稻草人昵称"]
        
        if "稻草人昵称颜色" in config_data:
            player_data["稻草人配置"]["稻草人昵称颜色"] = config_data["稻草人昵称颜色"]
        
        if "稻草人说的话" in config_data:
            player_data["稻草人配置"]["稻草人说的话"] = config_data["稻草人说的话"]
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        if is_only_changing_display:
            self.log('INFO', f"玩家 {username} 切换了稻草人展示类型到 {config_data['稻草人展示类型']}", 'SERVER')
            message = f"成功切换到{config_data['稻草人展示类型']}！"
        else:
            self.log('INFO', f"玩家 {username} 修改了稻草人配置，花费 {modify_cost} 金币", 'SERVER')
            message = f"稻草人配置修改成功！花费{modify_cost}金币"
        
        return self.send_data(client_id, {
            "type": "modify_scare_crow_config_response",
            "success": True,
            "message": message,
            "updated_data": {
                "钱币": player_data["钱币"],
                "稻草人配置": player_data["稻草人配置"]
            }
        })
    
    def _handle_get_scare_crow_config(self, client_id, message):
        """处理获取稻草人配置请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "获取稻草人配置", "get_scare_crow_config")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "get_scare_crow_config")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 确保稻草人配置存在
        if "稻草人配置" not in player_data:
            player_data["稻草人配置"] = {
                "已拥有稻草人类型": [],
                "稻草人展示类型": "",
                "稻草人昵称": "我的稻草人",
                "稻草人昵称颜色": "#ffffff",
                "稻草人说的话": {
                    "第一句话": {"内容": "", "颜色": "#000000"},
                    "第二句话": {"内容": "", "颜色": "#000000"},
                    "第三句话": {"内容": "", "颜色": "#000000"},
                    "第四句话": {"内容": "", "颜色": "#000000"}
                }
            }
            # 保存默认配置
            self.save_player_data(username, player_data)
        
        return self.send_data(client_id, {
            "type": "get_scare_crow_config_response",
            "success": True,
            "message": "获取稻草人配置成功",
            "scare_crow_config": player_data["稻草人配置"]
        })
    
    def _load_scare_crow_config(self):
        """加载稻草人配置"""
        try:
            if hasattr(self, 'mongo_api') and self.mongo_api and self.mongo_api.is_connected():
                config = self.mongo_api.get_scare_crow_config()
                if config:
                    self.log('INFO', "成功从MongoDB加载稻草人配置", 'SERVER')
                    return config
                else:
                    self.log('WARNING', "MongoDB中未找到稻草人配置，使用默认配置", 'SERVER')
            else:
                self.log('WARNING', "MongoDB未连接，使用默认稻草人配置", 'SERVER')
        except Exception as e:
            self.log('ERROR', f"从MongoDB加载稻草人配置失败: {str(e)}，使用默认配置", 'SERVER')
        
        # 返回默认配置
        return {
            "稻草人类型": {
                "稻草人1": {"图片": "res://assets/道具图片/稻草人1.webp", "价格": 1000},
                "稻草人2": {"图片": "res://assets/道具图片/稻草人2.webp", "价格": 1000},
                "稻草人3": {"图片": "res://assets/道具图片/稻草人3.webp", "价格": 1000}
            },
            "修改稻草人配置花费": 300
        }
    
    def _send_buy_scare_crow_error(self, client_id, message):
        """发送购买稻草人错误响应"""
        return self.send_data(client_id, {
            "type": "buy_scare_crow_response",
            "success": False,
            "message": message
        })
    
    def _send_modify_scare_crow_config_error(self, client_id, message):
        """发送修改稻草人配置错误响应"""
        return self.send_data(client_id, {
            "type": "modify_scare_crow_config_response",
            "success": False,
            "message": message
        })
#==========================稻草人系统处理==========================


#==========================智慧树系统处理==========================
    def _handle_wisdom_tree_operation(self, client_id, message):
        """处理智慧树操作请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "智慧树操作", "wisdom_tree_operation")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "wisdom_tree_operation")
        if not player_data:
            return self.send_data(client_id, response)
        
        operation_type = message.get("operation_type", "")
        
        # 检查并修复智慧树配置格式
        self._check_and_fix_wisdom_tree_config(player_data, username)
        
        # 获取修复后的智慧树配置
        wisdom_tree_config = player_data["智慧树配置"]
        
        # 处理不同的操作类型
        if operation_type == "water":
            return self._process_wisdom_tree_water(client_id, player_data, username, wisdom_tree_config)
        elif operation_type == "fertilize":
            return self._process_wisdom_tree_fertilize(client_id, player_data, username, wisdom_tree_config)
        elif operation_type == "kill_grass":
            return self._process_wisdom_tree_kill_grass(client_id, player_data, username, wisdom_tree_config)
        elif operation_type == "kill_bug":
            return self._process_wisdom_tree_kill_bug(client_id, player_data, username, wisdom_tree_config)
        elif operation_type == "play_music":
            return self._process_wisdom_tree_play_music(client_id, player_data, username, wisdom_tree_config)
        elif operation_type == "revive":
            return self._process_wisdom_tree_revive(client_id, player_data, username, wisdom_tree_config)
        elif operation_type == "get_random_message":
            return self._process_wisdom_tree_get_random_message(client_id, player_data, username, wisdom_tree_config)
        else:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "未知的智慧树操作类型",
                "operation_type": operation_type
            })
    
    def _process_wisdom_tree_water(self, client_id, player_data, username, wisdom_tree_config):
        """处理智慧树浇水"""
        # 检查智慧树是否死亡
        if wisdom_tree_config["当前生命值"] <= 0:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "智慧树已死亡，请先复活！",
                "operation_type": "water"
            })
        
        # 浇水费用
        water_cost = 100
        
        # 检查金钱是否足够
        if player_data["钱币"] < water_cost:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": f"金钱不足，浇水需要 {water_cost} 金币",
                "operation_type": "water"
            })
        
        # 执行浇水
        player_data["钱币"] -= water_cost
        
        # 浇水经验：50-150随机
        import random
        exp_gained = random.randint(50, 150)
        wisdom_tree_config["当前经验值"] += exp_gained
        
        # 浇水高度：40%概率增加1-2高度
        height_gained = 0
        if random.random() < 0.4:  # 40%概率
            height_gained = random.randint(1, 2)
            wisdom_tree_config["高度"] = min(100, wisdom_tree_config["高度"] + height_gained)
        
        # 检查等级提升
        level_up_occurred = self._check_wisdom_tree_level_up(wisdom_tree_config)
        
        # 保存数据
        self.save_player_data(username, player_data)
        
        height_msg = f"，高度+{height_gained}" if height_gained > 0 else ""
        self.log('INFO', f"玩家 {username} 给智慧树浇水，花费 {water_cost} 金币，经验+{exp_gained}{height_msg}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "wisdom_tree_operation_response",
            "success": True,
            "message": f"浇水成功！经验+{exp_gained}{height_msg}",
            "operation_type": "water",
            "updated_data": {
                "钱币": player_data["钱币"],
                "智慧树配置": wisdom_tree_config
            }
        })
    
    def _process_wisdom_tree_fertilize(self, client_id, player_data, username, wisdom_tree_config):
        """处理智慧树施肥"""
        # 检查智慧树是否死亡
        if wisdom_tree_config["当前生命值"] <= 0:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "智慧树已死亡，请先复活！",
                "operation_type": "fertilize"
            })
        
        # 施肥费用
        fertilize_cost = 200
        
        # 检查金钱是否足够
        if player_data["钱币"] < fertilize_cost:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": f"金钱不足，施肥需要 {fertilize_cost} 金币",
                "operation_type": "fertilize"
            })
        
        # 执行施肥
        player_data["钱币"] -= fertilize_cost
        
        # 施肥经验：10-40随机
        import random
        exp_gained = random.randint(10, 40)
        wisdom_tree_config["当前经验值"] += exp_gained
        
        # 施肥高度：80%概率增加1-7高度
        height_gained = 0
        if random.random() < 0.8:  # 80%概率
            height_gained = random.randint(1, 7)
            wisdom_tree_config["高度"] = min(100, wisdom_tree_config["高度"] + height_gained)
        
        # 检查等级提升
        level_up_occurred = self._check_wisdom_tree_level_up(wisdom_tree_config)
        
        # 保存数据
        self.save_player_data(username, player_data)
        
        height_msg = f"，高度+{height_gained}" if height_gained > 0 else ""
        self.log('INFO', f"玩家 {username} 给智慧树施肥，花费 {fertilize_cost} 金币，经验+{exp_gained}{height_msg}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "wisdom_tree_operation_response",
            "success": True,
            "message": f"施肥成功！经验+{exp_gained}{height_msg}",
            "operation_type": "fertilize",
            "updated_data": {
                "钱币": player_data["钱币"],
                "智慧树配置": wisdom_tree_config
            }
        })
    
    def _process_wisdom_tree_kill_grass(self, client_id, player_data, username, wisdom_tree_config):
        """处理智慧树除草"""
        # 检查智慧树是否死亡
        if wisdom_tree_config["当前生命值"] <= 0:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "智慧树已死亡，请先复活！",
                "operation_type": "kill_grass"
            })
        
        # 除草费用
        kill_grass_cost = 150
        
        # 检查金钱是否足够
        if player_data["钱币"] < kill_grass_cost:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": f"金钱不足，除草需要 {kill_grass_cost} 金币",
                "operation_type": "kill_grass"
            })
        
        # 执行除草
        import time
        player_data["钱币"] -= kill_grass_cost
        max_health = wisdom_tree_config["最大生命值"]
        wisdom_tree_config["当前生命值"] = min(max_health, wisdom_tree_config["当前生命值"] + 10)
        wisdom_tree_config["距离上一次除草时间"] = int(time.time())
        
        # 保存数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 给智慧树除草，花费 {kill_grass_cost} 金币，生命值+10", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "wisdom_tree_operation_response",
            "success": True,
            "message": "除草成功！生命值+10",
            "operation_type": "kill_grass",
            "updated_data": {
                "钱币": player_data["钱币"],
                "智慧树配置": wisdom_tree_config
            }
        })
    
    def _process_wisdom_tree_kill_bug(self, client_id, player_data, username, wisdom_tree_config):
        """处理智慧树杀虫"""
        # 检查智慧树是否死亡
        if wisdom_tree_config["当前生命值"] <= 0:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "智慧树已死亡，请先复活！",
                "operation_type": "kill_bug"
            })
        
        # 杀虫费用
        kill_bug_cost = 150
        
        # 检查金钱是否足够
        if player_data["钱币"] < kill_bug_cost:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": f"金钱不足，杀虫需要 {kill_bug_cost} 金币",
                "operation_type": "kill_bug"
            })
        
                # 执行杀虫
        player_data["钱币"] -= kill_bug_cost
        max_health = wisdom_tree_config["最大生命值"]
        wisdom_tree_config["当前生命值"] = min(max_health, wisdom_tree_config["当前生命值"] + 15)
        wisdom_tree_config["距离上一次杀虫时间"] = int(time.time())
        
        # 保存数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 给智慧树杀虫，花费 {kill_bug_cost} 金币，生命值+15", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "wisdom_tree_operation_response",
            "success": True,
            "message": "杀虫成功！生命值+15",
            "operation_type": "kill_bug",
            "updated_data": {
                "钱币": player_data["钱币"],
                "智慧树配置": wisdom_tree_config
            }
        })
    
    def _process_wisdom_tree_play_music(self, client_id, player_data, username, wisdom_tree_config):
        """处理智慧树放音乐"""
        # 检查智慧树是否死亡
        if wisdom_tree_config["当前生命值"] <= 0:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "智慧树已死亡，请先复活！",
                "operation_type": "play_music"
            })
        
        # 放音乐费用
        play_music_cost = 100
        
        # 检查金钱是否足够
        if player_data["钱币"] < play_music_cost:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": f"金钱不足，放音乐需要 {play_music_cost} 金币",
                "operation_type": "play_music"
            })
        
        # 执行放音乐
        player_data["钱币"] -= play_music_cost
        
        # 从智慧树消息库中随机获取一条消息
        random_message = self._get_random_wisdom_tree_message()
        if random_message:
            wisdom_tree_config["智慧树显示的话"] = random_message.get("content", "")
        
        # 保存数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 给智慧树放音乐，花费 {play_music_cost} 金币，获得随机消息", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "wisdom_tree_operation_response",
            "success": True,
            "message": "放音乐成功！获得了一条神秘消息",
            "operation_type": "play_music",
            "random_message": random_message,
            "updated_data": {
                "钱币": player_data["钱币"],
                "智慧树配置": wisdom_tree_config
            }
        })
    
    def _process_wisdom_tree_revive(self, client_id, player_data, username, wisdom_tree_config):
        """处理智慧树复活"""
        # 检查智慧树是否真的死亡
        if wisdom_tree_config["当前生命值"] > 0:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "智慧树还活着，不需要复活！",
                "operation_type": "revive"
            })
        
        # 复活费用
        revive_cost = 1000
        
        # 检查金钱是否足够
        if player_data["钱币"] < revive_cost:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": f"金钱不足，复活智慧树需要 {revive_cost} 金币",
                "operation_type": "revive"
            })
        
        # 执行复活
        player_data["钱币"] -= revive_cost
        wisdom_tree_config["当前生命值"] = wisdom_tree_config["最大生命值"]
        
        # 保存数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 复活了智慧树，花费 {revive_cost} 金币", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "wisdom_tree_operation_response",
            "success": True,
            "message": "智慧树复活成功！",
            "operation_type": "revive",
            "updated_data": {
                "钱币": player_data["钱币"],
                "智慧树配置": wisdom_tree_config
            }
        })
    
    def _process_wisdom_tree_get_random_message(self, client_id, player_data, username, wisdom_tree_config):
        """处理获取随机智慧树消息"""
        # 从智慧树消息库中随机获取一条消息
        random_message = self._get_random_wisdom_tree_message()
        
        if random_message:
            wisdom_tree_config["智慧树显示的话"] = random_message.get("content", "")
            
            # 保存数据
            self.save_player_data(username, player_data)
            
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": True,
                "message": "获得了一条神秘消息",
                "operation_type": "get_random_message",
                "random_message": random_message,
                "updated_data": {
                    "智慧树配置": wisdom_tree_config
                }
            })
        else:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "暂时没有新消息",
                "operation_type": "get_random_message"
            })
    
    def _handle_wisdom_tree_message(self, client_id, message):
        """处理智慧树消息发送请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "发送智慧树消息", "wisdom_tree_message")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "wisdom_tree_message")
        if not player_data:
            return self.send_data(client_id, response)
        
        message_content = message.get("message", "").strip()
        
        # 验证消息内容
        if not message_content:
            return self.send_data(client_id, {
                "type": "wisdom_tree_message_response",
                "success": False,
                "message": "消息内容不能为空"
            })
        
        if len(message_content) > 100:
            return self.send_data(client_id, {
                "type": "wisdom_tree_message_response",
                "success": False,
                "message": "消息长度不能超过100个字符"
            })
        
        # 发送消息费用
        send_cost = 50
        
        # 检查金钱是否足够
        if player_data["钱币"] < send_cost:
            return self.send_data(client_id, {
                "type": "wisdom_tree_message_response",
                "success": False,
                "message": f"金钱不足，发送消息需要 {send_cost} 金币"
            })
        
        # 扣除费用
        player_data["钱币"] -= send_cost
        
        # 保存消息到智慧树消息库
        success = self._save_wisdom_tree_message(username, message_content)
        
        if success:
            # 保存玩家数据
            self.save_player_data(username, player_data)
            
            self.log('INFO', f"玩家 {username} 发送智慧树消息，花费 {send_cost} 金币：{message_content}", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "wisdom_tree_message_response",
                "success": True,
                "message": "消息发送成功！",
                "updated_data": {
                    "钱币": player_data["钱币"]
                }
            })
        else:
            return self.send_data(client_id, {
                "type": "wisdom_tree_message_response",
                "success": False,
                "message": "消息发送失败，请重试"
            })
    
    def _handle_get_wisdom_tree_config(self, client_id, message):
        """处理获取智慧树配置请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "获取智慧树配置", "get_wisdom_tree_config")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "get_wisdom_tree_config")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 检查并修复智慧树配置
        self._check_and_fix_wisdom_tree_config(player_data, username)
        
        # 保存修复后的数据
        self.save_player_data(username, player_data)
        
        # 返回智慧树配置
        wisdom_tree_config = player_data.get("智慧树配置", {})
        
        self.log('INFO', f"玩家 {username} 请求智慧树配置", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "wisdom_tree_config_response",
            "success": True,
            "config": wisdom_tree_config
        })
    
    def _check_wisdom_tree_level_up(self, wisdom_tree_config):
        """检查智慧树等级提升"""
        current_level = wisdom_tree_config["等级"]
        current_experience = wisdom_tree_config["当前经验值"]
        max_experience = wisdom_tree_config["最大经验值"]
        level_ups = 0
        
        # 检查是否可以升级（最高等级20）
        while current_level < 20 and current_experience >= max_experience:
            # 升级
            current_level += 1
            current_experience -= max_experience  # 扣除升级所需经验
            level_ups += 1
            
            # 计算新等级的最大经验值
            max_experience = self._calculate_wisdom_tree_max_exp(current_level)
            
            self.log('INFO', f"智慧树等级提升到 {current_level} 级，新的最大经验值: {max_experience}", 'SERVER')
        
        # 每升一级，最大生命值+2，当前生命值也+2
        if level_ups > 0:
            health_bonus = level_ups * 2
            wisdom_tree_config["最大生命值"] = min(200, wisdom_tree_config["最大生命值"] + health_bonus)
            wisdom_tree_config["当前生命值"] = min(wisdom_tree_config["最大生命值"], wisdom_tree_config["当前生命值"] + health_bonus)
            self.log('INFO', f"智慧树升级 {level_ups} 级，最大生命值+{health_bonus}", 'SERVER')
        
        # 更新配置
        wisdom_tree_config["等级"] = current_level
        wisdom_tree_config["当前经验值"] = current_experience
        wisdom_tree_config["最大经验值"] = max_experience
        
        return level_ups > 0
    
    def _get_random_wisdom_tree_message(self):
        """从智慧树消息库中随机获取一条消息"""
        import os
        import json
        import random
        
        # 优先从MongoDB读取
        if hasattr(self, 'mongo_api') and self.mongo_api and self.mongo_api.is_connected():
            try:
                wisdom_tree_data = self.mongo_api.get_wisdom_tree_config()
                if wisdom_tree_data:
                    messages = wisdom_tree_data.get("messages", [])
                    if messages:
                        selected_message = random.choice(messages)
                        self.log('INFO', f"成功从MongoDB获取智慧树消息", 'SERVER')
                        return selected_message
                    else:
                        return None
            except Exception as e:
                self.log('ERROR', f"从MongoDB读取智慧树消息失败: {e}", 'SERVER')
        
        # 回退到JSON文件
        wisdom_tree_data_path = os.path.join(os.path.dirname(__file__), "config", "wisdom_tree_data.json")
        
        try:
            with open(wisdom_tree_data_path, 'r', encoding='utf-8') as f:
                wisdom_tree_data = json.load(f)
            
            messages = wisdom_tree_data.get("messages", [])
            if messages:
                selected_message = random.choice(messages)
                self.log('INFO', f"成功从JSON文件获取智慧树消息", 'SERVER')
                return selected_message
            else:
                return None
        except Exception as e:
            self.log('ERROR', f"从JSON文件读取智慧树消息失败: {e}", 'SERVER')
            return None
    
    def _save_wisdom_tree_message(self, username, message_content):
        """保存智慧树消息到消息库"""
        import os
        import json
        import time
        import uuid
        
        # 创建新消息
        new_message = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
            "sender": username,
            "content": message_content,
            "id": str(uuid.uuid4())
        }
        
        # 优先保存到MongoDB
        if hasattr(self, 'mongo_api') and self.mongo_api and self.mongo_api.is_connected():
            try:
                # 获取现有数据
                wisdom_tree_data = self.mongo_api.get_wisdom_tree_config()
                if not wisdom_tree_data:
                    wisdom_tree_data = {
                        "messages": [],
                        "total_messages": 0,
                        "last_update": ""
                    }
                
                # 添加新消息
                wisdom_tree_data["messages"].append(new_message)
                wisdom_tree_data["total_messages"] = len(wisdom_tree_data["messages"])
                wisdom_tree_data["last_update"] = new_message["timestamp"]
                
                # 保持最多1000条消息
                if len(wisdom_tree_data["messages"]) > 1000:
                    wisdom_tree_data["messages"] = wisdom_tree_data["messages"][-1000:]
                    wisdom_tree_data["total_messages"] = len(wisdom_tree_data["messages"])
                
                # 保存到MongoDB
                if self.mongo_api.update_wisdom_tree_config(wisdom_tree_data):
                    self.log('INFO', f"成功保存智慧树消息到MongoDB: {username}", 'SERVER')
                    return True
                else:
                    self.log('ERROR', f"保存智慧树消息到MongoDB失败: {username}", 'SERVER')
            except Exception as e:
                self.log('ERROR', f"MongoDB保存智慧树消息异常: {e}", 'SERVER')
        
        # 回退到JSON文件
        wisdom_tree_data_path = os.path.join(os.path.dirname(__file__), "config", "wisdom_tree_data.json")
        
        try:
            # 读取现有数据
            if os.path.exists(wisdom_tree_data_path):
                with open(wisdom_tree_data_path, 'r', encoding='utf-8') as f:
                    wisdom_tree_data = json.load(f)
            else:
                wisdom_tree_data = {
                    "messages": [],
                    "total_messages": 0,
                    "last_update": ""
                }
            
            # 添加到消息列表
            wisdom_tree_data["messages"].append(new_message)
            wisdom_tree_data["total_messages"] = len(wisdom_tree_data["messages"])
            wisdom_tree_data["last_update"] = new_message["timestamp"]
            
            # 保持最多1000条消息
            if len(wisdom_tree_data["messages"]) > 1000:
                wisdom_tree_data["messages"] = wisdom_tree_data["messages"][-1000:]
                wisdom_tree_data["total_messages"] = len(wisdom_tree_data["messages"])
            
            # 保存数据
            with open(wisdom_tree_data_path, 'w', encoding='utf-8') as f:
                json.dump(wisdom_tree_data, f, ensure_ascii=False, indent=4)
            
            self.log('INFO', f"成功保存智慧树消息到JSON文件: {username}", 'SERVER')
            return True
        except Exception as e:
            self.log('ERROR', f"保存智慧树消息到JSON文件失败: {e}", 'SERVER')
            return False
    
    def check_wisdom_tree_health_decay(self):
        """检查智慧树生命值衰减"""
        import time
        import random
        
        current_time = int(time.time())
        processed_count = 0
        
        # 检查所有在线玩家
        for client_id in self.user_data:
            if self.user_data[client_id].get("logged_in", False):
                username = self.user_data[client_id]["username"]
                player_data = self.load_player_data(username)
                if player_data and "智慧树配置" in player_data:
                    self._process_wisdom_tree_decay(player_data["智慧树配置"], username)
                    self.save_player_data(username, player_data)
                    processed_count += 1
        
        # 注释：缓存机制已移除，只处理在线玩家的智慧树衰减
        
        if processed_count > 0:
            self.log('INFO', f"已处理 {processed_count} 个玩家的智慧树生命值衰减", 'SERVER')
    
    def _process_wisdom_tree_decay(self, wisdom_tree_config, username):
        """处理单个玩家的智慧树生命值衰减"""
        import time
        import random
        
        current_time = int(time.time())
        
        # 获取上次除草和杀虫时间，处理空字符串和无效值
        last_grass_time_raw = wisdom_tree_config.get("距离上一次除草时间", current_time)
        last_bug_time_raw = wisdom_tree_config.get("距离上一次杀虫时间", current_time)
        
        # 处理空字符串和无效时间戳
        try:
            last_grass_time = int(last_grass_time_raw) if last_grass_time_raw and str(last_grass_time_raw).strip() else current_time
        except (ValueError, TypeError):
            last_grass_time = current_time
            
        try:
            last_bug_time = int(last_bug_time_raw) if last_bug_time_raw and str(last_bug_time_raw).strip() else current_time
        except (ValueError, TypeError):
            last_bug_time = current_time
        
        # 如果时间戳无效（为0或负数），设置为当前时间
        if last_grass_time <= 0:
            last_grass_time = current_time
        if last_bug_time <= 0:
            last_bug_time = current_time
        
        # 检查是否3天没有除草
        days_since_grass = (current_time - last_grass_time) / 86400  # 转换为天数
        if days_since_grass >= 3:
            # 计算应该衰减的天数
            decay_days = int(days_since_grass)
            if decay_days > 0:
                # 每天减少1-3血量
                total_decay = 0
                for _ in range(decay_days):
                    daily_decay = random.randint(1, 3)
                    total_decay += daily_decay
                
                wisdom_tree_config["当前生命值"] = max(0, wisdom_tree_config["当前生命值"] - total_decay)
                self.log('INFO', f"玩家 {username} 的智慧树因{decay_days}天未除草，生命值减少{total_decay}", 'SERVER')
                
                # 更新除草时间为当前时间，避免重复扣血
                wisdom_tree_config["距离上一次除草时间"] = current_time
        
        # 检查是否3天没有杀虫
        days_since_bug = (current_time - last_bug_time) / 86400  # 转换为天数
        if days_since_bug >= 3:
            # 计算应该衰减的天数
            decay_days = int(days_since_bug)
            if decay_days > 0:
                # 每天减少1-3血量
                total_decay = 0
                for _ in range(decay_days):
                    daily_decay = random.randint(1, 3)
                    total_decay += daily_decay
                
                wisdom_tree_config["当前生命值"] = max(0, wisdom_tree_config["当前生命值"] - total_decay)
                self.log('INFO', f"玩家 {username} 的智慧树因{decay_days}天未杀虫，生命值减少{total_decay}", 'SERVER')
                
                # 更新杀虫时间为当前时间，避免重复扣血
                wisdom_tree_config["距离上一次杀虫时间"] = current_time
#==========================智慧树系统处理==========================


#==========================作物出售处理==========================
    def _handle_sell_crop(self, client_id, message):
        """处理作物出售请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "出售作物", "sell_crop")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "sell_crop")
        if not player_data:
            return self.send_data(client_id, response)
        
        crop_name = message.get("crop_name", "")
        sell_count = message.get("sell_count", 1)
        unit_price = message.get("unit_price", 0)
        
        # 验证参数
        if not crop_name:
            return self._send_action_error(client_id, "sell_crop", "作物名称不能为空")
        
        if sell_count <= 0:
            return self._send_action_error(client_id, "sell_crop", "出售数量必须大于0")
        
        if unit_price <= 0:
            return self._send_action_error(client_id, "sell_crop", "单价必须大于0")
        
        # 检查作物仓库中是否有足够的作物
        crop_warehouse = player_data.get("作物仓库", [])
        crop_found = False
        crop_index = -1
        available_count = 0
        
        for i, crop_item in enumerate(crop_warehouse):
            if crop_item.get("name") == crop_name:
                crop_found = True
                crop_index = i
                available_count = crop_item.get("count", 0)
                break
        
        if not crop_found:
            return self._send_action_error(client_id, "sell_crop", f"作物仓库中没有 {crop_name}")
        
        if available_count < sell_count:
            return self._send_action_error(client_id, "sell_crop", f"作物数量不足，仓库中只有 {available_count} 个 {crop_name}")
        
        # 验证价格（防止客户端篡改价格）
        crop_data = self._load_crop_data()
        if crop_name in crop_data:
            expected_price = crop_data[crop_name].get("收益", 0)
            if unit_price != expected_price:
                return self._send_action_error(client_id, "sell_crop", f"价格验证失败，{crop_name} 的正确价格应为 {expected_price} 元/个")
        else:
            return self._send_action_error(client_id, "sell_crop", f"未知的作物类型：{crop_name}")
        
        # 计算总收入
        total_income = sell_count * unit_price
        
        # 执行出售操作
        player_data["钱币"] += total_income
        
        # 从作物仓库中减少数量
        crop_warehouse[crop_index]["count"] -= sell_count
        
        # 如果数量为0，从仓库中移除该作物
        if crop_warehouse[crop_index]["count"] <= 0:
            crop_warehouse.pop(crop_index)
        
        # 给予少量出售经验
        sell_experience = max(1, sell_count // 5)  # 每5个作物给1点经验
        player_data["经验值"] += sell_experience
        
        # 检查是否升级
        self._check_level_up(player_data)
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 获取显示名称
        display_name = crop_name
        if crop_name in crop_data:
            mature_name = crop_data[crop_name].get("成熟物名称")
            if mature_name:
                display_name = mature_name
            else:
                display_name = crop_data[crop_name].get("作物名称", crop_name)
        
        self.log('INFO', f"玩家 {username} 出售了 {sell_count} 个 {crop_name}，获得 {total_income} 金币和 {sell_experience} 经验", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "sell_crop",
            "success": True,
            "message": f"成功出售 {sell_count} 个 {display_name}，获得 {total_income} 金币和 {sell_experience} 经验",
            "updated_data": {
                "钱币": player_data["钱币"],
                "经验值": player_data["经验值"],
                "等级": player_data["等级"],
                "作物仓库": player_data["作物仓库"]
            }
        })
#==========================作物出售处理==========================


#==========================小卖部管理处理==========================
    def _handle_add_product_to_store(self, client_id, message):
        """处理添加商品到小卖部请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "添加商品到小卖部", "add_product_to_store")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "add_product_to_store")
        if not player_data:
            return self.send_data(client_id, response)
        
        product_type = message.get("product_type", "")
        product_name = message.get("product_name", "")
        product_count = message.get("product_count", 1)
        product_price = message.get("product_price", 0)
        
        # 验证参数
        if not product_type or not product_name:
            return self._send_action_error(client_id, "add_product_to_store", "商品类型或名称不能为空")
        
        if product_count <= 0:
            return self._send_action_error(client_id, "add_product_to_store", "商品数量必须大于0")
        
        if product_price <= 0:
            return self._send_action_error(client_id, "add_product_to_store", "商品价格必须大于0")
        
        # 初始化小卖部数据
        if "小卖部配置" not in player_data:
            player_data["小卖部配置"] = {
                "商品列表": [],
                "格子数": 10
            }
        
        store_config = player_data["小卖部配置"]
        player_store = store_config["商品列表"]
        max_slots = store_config["格子数"]
        
        # 检查小卖部格子是否已满
        if len(player_store) >= max_slots:
            return self._send_action_error(client_id, "add_product_to_store", f"小卖部格子已满({len(player_store)}/{max_slots})")
        
        # 检查作物仓库中是否有足够的商品
        if product_type == "作物":
            crop_warehouse = player_data.get("作物仓库", [])
            crop_found = False
            crop_index = -1
            available_count = 0
            
            for i, crop_item in enumerate(crop_warehouse):
                if crop_item.get("name") == product_name:
                    crop_found = True
                    crop_index = i
                    available_count = crop_item.get("count", 0)
                    break
            
            if not crop_found:
                return self._send_action_error(client_id, "add_product_to_store", f"作物仓库中没有 {product_name}")
            
            if available_count < product_count:
                return self._send_action_error(client_id, "add_product_to_store", f"作物数量不足，仓库中只有 {available_count} 个 {product_name}")
            
            # 从作物仓库中扣除商品
            crop_warehouse[crop_index]["count"] -= product_count
            if crop_warehouse[crop_index]["count"] <= 0:
                crop_warehouse.pop(crop_index)
        
        # 添加商品到小卖部
        new_product = {
            "商品类型": product_type,
            "商品名称": product_name,
            "商品价格": product_price,
            "商品数量": product_count
        }
        player_store.append(new_product)
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 添加商品到小卖部: {product_name} x{product_count}, 价格 {product_price}元/个", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "add_product_to_store",
            "success": True,
            "message": f"成功添加 {product_count} 个 {product_name} 到小卖部",
            "updated_data": {
                "小卖部配置": player_data["小卖部配置"],
                "作物仓库": player_data.get("作物仓库", [])
            }
        })
    
    def _handle_remove_store_product(self, client_id, message):
        """处理下架小卖部商品请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "下架小卖部商品", "remove_store_product")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "remove_store_product")
        if not player_data:
            return self.send_data(client_id, response)
        
        slot_index = message.get("slot_index", -1)
        
        # 验证参数
        if slot_index < 0:
            return self._send_action_error(client_id, "remove_store_product", "无效的商品槽位")
        
        # 检查小卖部数据
        store_config = player_data.get("小卖部配置", {"商品列表": [], "格子数": 10})
        player_store = store_config.get("商品列表", [])
        if slot_index >= len(player_store):
            return self._send_action_error(client_id, "remove_store_product", "商品槽位不存在")
        
        # 获取要下架的商品信息
        product_data = player_store[slot_index]
        product_type = product_data.get("商品类型", "")
        product_name = product_data.get("商品名称", "")
        product_count = product_data.get("商品数量", 0)
        
        # 将商品返回到对应仓库
        if product_type == "作物":
            # 返回到作物仓库
            if "作物仓库" not in player_data:
                player_data["作物仓库"] = []
            
            crop_warehouse = player_data["作物仓库"]
            # 查找是否已有该作物
            crop_found = False
            for crop_item in crop_warehouse:
                if crop_item.get("name") == product_name:
                    crop_item["count"] += product_count
                    crop_found = True
                    break
            
            if not crop_found:
                # 添加新的作物条目
                crop_data = self._load_crop_data()
                quality = "普通"
                if crop_data and product_name in crop_data:
                    quality = crop_data[product_name].get("品质", "普通")
                
                crop_warehouse.append({
                    "name": product_name,
                    "quality": quality,
                    "count": product_count
                })
        
        # 从小卖部移除商品
        player_store.pop(slot_index)
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 下架小卖部商品: {product_name} x{product_count}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "remove_store_product",
            "success": True,
            "message": f"成功下架 {product_count} 个 {product_name}，已返回仓库",
            "updated_data": {
                "小卖部配置": player_data["小卖部配置"],
                "作物仓库": player_data.get("作物仓库", [])
            }
        })
    
    def _handle_buy_store_product(self, client_id, message):
        """处理购买小卖部商品请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "购买小卖部商品", "buy_store_product")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取买家数据
        buyer_data, buyer_username, response = self._load_player_data_with_check(client_id, "buy_store_product")
        if not buyer_data:
            return self.send_data(client_id, response)
        
        seller_username = message.get("seller_username", "")
        slot_index = message.get("slot_index", -1)
        product_name = message.get("product_name", "")
        unit_price = message.get("unit_price", 0)
        quantity = message.get("quantity", 1)
        
        # 验证参数
        if not seller_username:
            return self._send_action_error(client_id, "buy_store_product", "卖家用户名不能为空")
        
        if slot_index < 0:
            return self._send_action_error(client_id, "buy_store_product", "无效的商品槽位")
        
        if quantity <= 0:
            return self._send_action_error(client_id, "buy_store_product", "购买数量必须大于0")
        
        # 检查是否是自己购买自己的商品
        if buyer_username == seller_username:
            return self._send_action_error(client_id, "buy_store_product", "不能购买自己的商品")
        
        # 加载卖家数据
        seller_data = self.load_player_data(seller_username)
        if not seller_data:
            return self._send_action_error(client_id, "buy_store_product", f"卖家 {seller_username} 不存在")
        
        # 检查卖家小卖部
        seller_store_config = seller_data.get("小卖部配置", {"商品列表": [], "格子数": 10})
        seller_store = seller_store_config.get("商品列表", [])
        if slot_index >= len(seller_store):
            return self._send_action_error(client_id, "buy_store_product", "商品不存在")
        
        product_data = seller_store[slot_index]
        product_type = product_data.get("商品类型", "")
        store_product_name = product_data.get("商品名称", "")
        store_unit_price = product_data.get("商品价格", 0)
        available_count = product_data.get("商品数量", 0)
        
        # 验证商品信息
        if store_product_name != product_name:
            return self._send_action_error(client_id, "buy_store_product", "商品名称不匹配")
        
        if store_unit_price != unit_price:
            return self._send_action_error(client_id, "buy_store_product", "商品价格已变更，请刷新重试")
        
        if available_count < quantity:
            return self._send_action_error(client_id, "buy_store_product", f"商品库存不足，仅剩 {available_count} 个")
        
        # 计算总价
        total_cost = quantity * unit_price
        
        # 检查买家金钱是否足够
        if buyer_data["钱币"] < total_cost:
            return self._send_action_error(client_id, "buy_store_product", f"金钱不足，需要 {total_cost} 元")
        
        # 执行交易
        buyer_data["钱币"] -= total_cost
        seller_data["钱币"] += total_cost
        
        # 扣除卖家商品
        seller_store[slot_index]["商品数量"] -= quantity
        if seller_store[slot_index]["商品数量"] <= 0:
            seller_store.pop(slot_index)
        
        # 给买家添加商品
        if product_type == "作物":
            if "作物仓库" not in buyer_data:
                buyer_data["作物仓库"] = []
            
            buyer_warehouse = buyer_data["作物仓库"]
            # 查找是否已有该作物
            crop_found = False
            for crop_item in buyer_warehouse:
                if crop_item.get("name") == product_name:
                    crop_item["count"] += quantity
                    crop_found = True
                    break
            
            if not crop_found:
                # 添加新的作物条目
                crop_data = self._load_crop_data()
                quality = "普通"
                if crop_data and product_name in crop_data:
                    quality = crop_data[product_name].get("品质", "普通")
                
                buyer_warehouse.append({
                    "name": product_name,
                    "quality": quality,
                    "count": quantity
                })
        
        # 保存两个玩家的数据
        self.save_player_data(buyer_username, buyer_data)
        self.save_player_data(seller_username, seller_data)
        
        self.log('INFO', f"玩家 {buyer_username} 从 {seller_username} 的小卖部购买了 {quantity} 个 {product_name}，花费 {total_cost} 元", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "buy_store_product",
            "success": True,
            "message": f"成功购买 {quantity} 个 {product_name}，花费 {total_cost} 元",
            "updated_data": {
                "钱币": buyer_data["钱币"],
                "作物仓库": buyer_data.get("作物仓库", [])
            }
        })
    
    def _handle_buy_store_booth(self, client_id, message):
        """处理购买小卖部格子请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "购买小卖部格子", "buy_store_booth")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "buy_store_booth")
        if not player_data:
            return self.send_data(client_id, response)
        
        cost = message.get("cost", 0)
        
        # 验证参数
        if cost <= 0:
            return self._send_action_error(client_id, "buy_store_booth", "无效的购买费用")
        
        # 初始化小卖部数据
        if "小卖部配置" not in player_data:
            player_data["小卖部配置"] = {
                "商品列表": [],
                "格子数": 10
            }
        
        store_config = player_data["小卖部配置"]
        current_slots = store_config["格子数"]
        
        # 检查是否已达上限
        if current_slots >= 40:
            return self._send_action_error(client_id, "buy_store_booth", "小卖部格子数已达上限(40)")
        
        # 验证费用
        expected_cost = 1000 + (current_slots - 10) * 500
        if cost != expected_cost:
            return self._send_action_error(client_id, "buy_store_booth", f"费用不正确，应为 {expected_cost} 元")
        
        # 检查玩家金钱是否足够
        if player_data["钱币"] < cost:
            return self._send_action_error(client_id, "buy_store_booth", f"金钱不足，需要 {cost} 元")
        
        # 执行购买
        player_data["钱币"] -= cost
        store_config["格子数"] += 1
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 购买小卖部格子，花费 {cost} 元，格子数：{current_slots} -> {store_config['格子数']}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "buy_store_booth",
            "success": True,
            "message": f"成功购买格子，花费 {cost} 元，当前格子数：{store_config['格子数']}",
            "updated_data": {
                "钱币": player_data["钱币"],
                "小卖部配置": player_data["小卖部配置"]
            }
        })
#==========================小卖部管理处理==========================


#==========================今日占卜处理==========================
    def _handle_today_divination(self, client_id, message):
        """处理今日占卜请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "今日占卜", "today_divination")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "today_divination")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 获取今日日期
        today = datetime.datetime.now().strftime("%Y-%m-%d")
        
        # 检查今日占卜对象是否存在
        if "今日占卜对象" not in player_data:
            player_data["今日占卜对象"] = {}
        
        divination_data = player_data["今日占卜对象"]
        
        # 检查今日是否已经占卜过
        if "占卜日期" in divination_data and divination_data["占卜日期"] == today:
            return self.send_data(client_id, {
                "type": "today_divination_response",
                "success": False,
                "message": "今日已经占卜过了，明天再来吧！",
                "divination_data": player_data
            })
        
        # 生成占卜结果
        divination_result = self._generate_divination_result()
        
        # 更新玩家占卜数据
        divination_data["占卜日期"] = today
        divination_data["占卜结果"] = divination_result["result"]
        divination_data["占卜等级"] = divination_result["level"]
        divination_data["卦象"] = divination_result["hexagram"]
        divination_data["建议"] = divination_result["advice"]
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 进行今日占卜，等级：{divination_result['level']}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "today_divination_response",
            "success": True,
            "message": "占卜完成！",
            "divination_data": player_data
        })
    
    def _generate_divination_result(self):
        """生成占卜结果"""
        import random
        
        # 占卜等级配置（权重越高，出现概率越大）
        levels = [
            {"name": "大吉", "weight": 5, "color": "#FFD700"},
            {"name": "中吉", "weight": 15, "color": "#FFA500"},
            {"name": "小吉", "weight": 25, "color": "#90EE90"},
            {"name": "平", "weight": 30, "color": "#87CEEB"},
            {"name": "小凶", "weight": 20, "color": "#DDA0DD"},
            {"name": "凶", "weight": 5, "color": "#FF6347"}
        ]
        
        # 易经八卦
        hexagrams = [
            {"name": "乾卦", "symbol": "☰", "meaning": "天行健，君子以自强不息"},
            {"name": "坤卦", "symbol": "☷", "meaning": "地势坤，君子以厚德载物"},
            {"name": "震卦", "symbol": "☳", "meaning": "雷声隆隆，万物复苏"},
            {"name": "巽卦", "symbol": "☴", "meaning": "风行天下，顺势而为"},
            {"name": "坎卦", "symbol": "☵", "meaning": "水流不息，智慧如泉"},
            {"name": "离卦", "symbol": "☲", "meaning": "火光明亮，照耀前程"},
            {"name": "艮卦", "symbol": "☶", "meaning": "山高水长，稳如磐石"},
            {"name": "兑卦", "symbol": "☱", "meaning": "泽润万物，和谐共生"}
        ]
        
        # 占卜结果文案
        results = {
            "大吉": [
                "今日运势如虹，万事皆宜，财运亨通，贵人相助！",
                "紫气东来，福星高照，今日必有喜事临门！",
                "天时地利人和，今日是您大展宏图的好日子！"
            ],
            "中吉": [
                "今日运势不错，做事顺利，宜把握机会！",
                "春风得意，今日适合开展新计划！",
                "运势上升，今日努力必有收获！"
            ],
            "小吉": [
                "今日运势平稳向好，小有收获！",
                "和风细雨，今日宜静心修身！",
                "运势渐佳，今日适合稳步前进！"
            ],
            "平": [
                "今日运势平稳，宜守不宜攻！",
                "平平淡淡才是真，今日适合休养生息！",
                "运势平和，今日宜保持现状！"
            ],
            "小凶": [
                "今日运势略有波折，宜谨慎行事！",
                "小心驶得万年船，今日宜低调处事！",
                "运势稍逊，今日宜多思而后行！"
            ],
            "凶": [
                "今日运势欠佳，宜静待时机！",
                "山雨欲来风满楼，今日宜避其锋芒！",
                "运势低迷，今日宜韬光养晦！"
            ]
        }
        
        # 建议文案
        advice_list = {
            "大吉": [
                "今日宜：投资理财、开展新业务、拜访贵人",
                "今日宜：签订合同、举办庆典、求婚表白",
                "今日宜：出行旅游、购买重要物品、做重大决定"
            ],
            "中吉": [
                "今日宜：学习进修、拓展人脉、适度投资",
                "今日宜：整理规划、健身运动、与朋友聚会",
                "今日宜：处理积压事务、改善居住环境"
            ],
            "小吉": [
                "今日宜：读书思考、轻松娱乐、关爱家人",
                "今日宜：整理物品、制定计划、适度休息",
                "今日宜：培养兴趣、与人为善、保持乐观"
            ],
            "平": [
                "今日宜：维持现状、按部就班、稳中求进",
                "今日宜：反思总结、调整心态、积蓄力量",
                "今日宜：关注健康、陪伴家人、平和处事"
            ],
            "小凶": [
                "今日忌：冲动决定、大额消费、与人争执",
                "今日忌：签重要合同、做重大变动、外出远行",
                "今日宜：谨言慎行、低调做人、耐心等待"
            ],
            "凶": [
                "今日忌：投资冒险、开展新项目、做重要决定",
                "今日忌：与人冲突、外出办事、签署文件",
                "今日宜：静心修养、反省自身、等待转机"
            ]
        }
        
        # 按权重随机选择等级
        total_weight = sum(level["weight"] for level in levels)
        rand_num = random.randint(1, total_weight)
        current_weight = 0
        
        selected_level = None
        for level in levels:
            current_weight += level["weight"]
            if rand_num <= current_weight:
                selected_level = level
                break
        
        # 随机选择卦象
        selected_hexagram = random.choice(hexagrams)
        
        # 随机选择对应等级的结果和建议
        level_name = selected_level["name"]
        selected_result = random.choice(results[level_name])
        selected_advice = random.choice(advice_list[level_name])
        
        return {
            "level": level_name,
            "level_color": selected_level["color"],
            "result": selected_result,
            "hexagram": f"{selected_hexagram['symbol']} {selected_hexagram['name']}",
            "hexagram_meaning": selected_hexagram["meaning"],
            "advice": selected_advice
        }
#==========================今日占卜处理==========================


def console_input_thread(server):
    """控制台输入处理线程"""
    import threading
    import sys
    
    # 等待服务器完全启动
    time.sleep(0.5)
    
    console = ConsoleCommandsAPI(server)
    
    # 创建输入锁，防止日志输出打乱命令输入
    input_lock = threading.Lock()
    server._console_input_lock = input_lock
    
    # 获取服务器IP地址
    server_ip = getattr(server, 'host', 'localhost')
    if server_ip == '0.0.0.0':
        server_ip = 'localhost'
    
    # 使用锁保护初始化消息输出
    with input_lock:
        print("💬 控制台已就绪，输入 'help' 查看可用命令")
    
    while True:
        try:
            # 使用自定义提示符格式，不使用锁避免阻塞
            prompt = f"mengyafarm#{server_ip}> "
            command = input(prompt).strip()
                
            if command:
                # 只在处理命令时使用锁，避免输出被打乱
                with input_lock:
                    console.process_command(command)
        except EOFError:
            break
        except KeyboardInterrupt:
            break
        except Exception as e:
            # 使用锁保护错误输出
            with input_lock:
                print(f"❌ 处理命令时出错: {str(e)}")

# 主程序启动入口
if __name__ == "__main__":
    import sys
    
    try:
        print("=" * 60)
        print(f"🌱 萌芽农场游戏服务器 v{server_version} 🌱")
        print("=" * 60)
        print(f"📡 服务器地址: {server_host}:{server_port}")
        print(f"📦 缓冲区大小: {buffer_size} bytes")
        print(f"🔧 性能优化: 已启用")
        print("=" * 60)
        
        # 创建并启动游戏服务器
        server = TCPGameServer()
        
        # 在后台线程中启动服务器
        server_thread = threading.Thread(target=server.start)
        server_thread.daemon = True
        server_thread.start()
        
        print("✅ 服务器启动成功！")
        
        # 启动控制台输入线程
        console_thread = threading.Thread(target=console_input_thread, args=(server,))
        console_thread.daemon = True
        console_thread.start()
        
        # 主循环：保持服务器运行
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n" + "=" * 60)
        print("⚠️  程序被用户中断")
        print("💾 正在保存数据并关闭服务器...")
        
        if 'server' in locals():
            try:
                # 保存所有在线玩家数据
                for client_id, user_info in server.user_data.items():
                    if user_info.get("logged_in", False):
                        username = user_info.get("username")
                        if username:
                            player_data = server.load_player_data(username)
                            if player_data:
                                server.save_player_data(username, player_data)
                print("💾 数据保存完成")
            except:
                pass
            server.stop()
            
        print("✅ 服务器已安全关闭")
        print("👋 感谢使用萌芽农场服务器！")
        print("=" * 60)
        sys.exit(0)
    
    except Exception as e:
        print(f"\n❌ 服务器启动失败: {str(e)}")
        print("🔧 请检查配置并重试")
        sys.exit(1)