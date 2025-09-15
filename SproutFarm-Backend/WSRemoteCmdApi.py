#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
WebSocket协议的服务器远程命令API
作者: AI Assistant
功能: 提供基于WebSocket的远程控制台命令执行功能
"""

import asyncio
import websockets
import json
import threading
import time
from typing import Dict, Any, Optional
from ConsoleCommandsAPI import ConsoleCommandsAPI

class WSRemoteCmdApi:
    """WebSocket远程命令API服务器"""
    
    def __init__(self, game_server, host="0.0.0.0", port=7071, auth_key="mengya2024"):
        """
        初始化WebSocket远程命令API服务器
        
        Args:
            game_server: 游戏服务器实例
            host: WebSocket服务器监听地址
            port: WebSocket服务器监听端口
            auth_key: 认证密钥
        """
        self.game_server = game_server
        self.host = host
        self.port = port
        self.auth_key = auth_key
        self.server = None
        self.clients = {}  # 存储已连接的客户端
        self.console_api = ConsoleCommandsAPI(game_server)
        self.running = False
        
    async def register_client(self, websocket, path=None):
        """注册新的客户端连接"""
        client_id = f"{websocket.remote_address[0]}:{websocket.remote_address[1]}_{int(time.time())}"
        self.clients[client_id] = {
            "websocket": websocket,
            "authenticated": False,
            "connect_time": time.time()
        }
        
        try:
            # 发送欢迎消息
            await self.send_message(websocket, {
                "type": "welcome",
                "message": "欢迎连接到萌芽农场远程控制台",
                "server_version": getattr(self.game_server, 'server_version', '2.2.0'),
                "require_auth": True
            })
            
            # 处理客户端消息
            async for message in websocket:
                await self.handle_message(client_id, message)
                
        except websockets.exceptions.ConnectionClosed:
            pass
        except Exception as e:
            print(f"❌ 客户端 {client_id} 连接处理出错: {str(e)}")
        finally:
            # 清理客户端连接
            if client_id in self.clients:
                del self.clients[client_id]
                print(f"🔌 客户端 {client_id} 已断开连接")
    
    async def handle_message(self, client_id: str, message: str):
        """处理客户端消息"""
        try:
            data = json.loads(message)
            message_type = data.get("type", "")
            
            if message_type == "auth":
                await self.handle_auth(client_id, data)
            elif message_type == "command":
                await self.handle_command(client_id, data)
            elif message_type == "ping":
                await self.handle_ping(client_id, data)
            else:
                await self.send_error(client_id, f"未知消息类型: {message_type}")
                
        except json.JSONDecodeError:
            await self.send_error(client_id, "无效的JSON格式")
        except Exception as e:
            await self.send_error(client_id, f"处理消息时出错: {str(e)}")
    
    async def handle_auth(self, client_id: str, data: Dict[str, Any]):
        """处理客户端认证"""
        if client_id not in self.clients:
            return
            
        provided_key = data.get("auth_key", "")
        
        if provided_key == self.auth_key:
            self.clients[client_id]["authenticated"] = True
            await self.send_message(self.clients[client_id]["websocket"], {
                "type": "auth_result",
                "success": True,
                "message": "认证成功，欢迎使用远程控制台"
            })
            print(f"✅ 客户端 {client_id} 认证成功")
        else:
            await self.send_message(self.clients[client_id]["websocket"], {
                "type": "auth_result",
                "success": False,
                "message": "认证失败，密钥错误"
            })
            print(f"❌ 客户端 {client_id} 认证失败")
    
    async def handle_command(self, client_id: str, data: Dict[str, Any]):
        """处理控制台命令"""
        if client_id not in self.clients:
            return
            
        # 检查是否已认证
        if not self.clients[client_id]["authenticated"]:
            await self.send_error(client_id, "请先进行认证")
            return
            
        command = data.get("command", "").strip()
        if not command:
            await self.send_error(client_id, "命令不能为空")
            return
            
        # 执行命令并捕获输出
        try:
            # 重定向标准输出来捕获命令执行结果
            import io
            import sys
            
            old_stdout = sys.stdout
            sys.stdout = captured_output = io.StringIO()
            
            # 执行命令
            success = self.console_api.process_command(command)
            
            # 恢复标准输出
            sys.stdout = old_stdout
            output = captured_output.getvalue()
            
            # 发送执行结果
            await self.send_message(self.clients[client_id]["websocket"], {
                "type": "command_result",
                "command": command,
                "success": success,
                "output": output if output else ("命令执行成功" if success else "命令执行失败")
            })
            
            print(f"📝 客户端 {client_id} 执行命令: {command} - {'成功' if success else '失败'}")
            
        except Exception as e:
            await self.send_error(client_id, f"执行命令时出错: {str(e)}")
    
    async def handle_ping(self, client_id: str, data: Dict[str, Any]):
        """处理ping请求"""
        if client_id not in self.clients:
            return
            
        await self.send_message(self.clients[client_id]["websocket"], {
            "type": "pong",
            "timestamp": time.time()
        })
    
    async def send_message(self, websocket, data: Dict[str, Any]):
        """发送消息到客户端"""
        try:
            message = json.dumps(data, ensure_ascii=False)
            await websocket.send(message)
        except Exception as e:
            print(f"❌ 发送消息失败: {str(e)}")
    
    async def send_error(self, client_id: str, error_message: str):
        """发送错误消息到客户端"""
        if client_id in self.clients:
            await self.send_message(self.clients[client_id]["websocket"], {
                "type": "error",
                "message": error_message
            })
    
    def start_server(self):
        """启动WebSocket服务器"""
        if self.running:
            return
            
        async def run_server_async():
            try:
                self.server = await websockets.serve(
                    self.register_client,
                    self.host,
                    self.port
                )
                
                self.running = True
                print(f"🌐 WebSocket远程控制台服务器已启动: ws://{self.host}:{self.port}")
                print(f"🔑 认证密钥: {self.auth_key}")
                
                # 保持服务器运行
                await self.server.wait_closed()
                
            except Exception as e:
                print(f"❌ WebSocket服务器启动失败: {str(e)}")
                self.running = False
        
        def run_server():
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            
            try:
                loop.run_until_complete(run_server_async())
            except Exception as e:
                print(f"❌ WebSocket服务器线程异常: {str(e)}")
                self.running = False
        
        # 在新线程中运行WebSocket服务器
        server_thread = threading.Thread(target=run_server, daemon=True)
        server_thread.start()
    
    def stop_server(self):
        """停止WebSocket服务器"""
        if not self.running:
            return
            
        self.running = False
        
        # 关闭所有客户端连接
        for client_id, client_info in list(self.clients.items()):
            try:
                asyncio.create_task(client_info["websocket"].close())
            except:
                pass
        
        self.clients.clear()
        
        if self.server:
            try:
                self.server.close()
            except:
                pass
            
        print("🌐 WebSocket远程控制台服务器已停止")
    
    def get_status(self) -> Dict[str, Any]:
        """获取服务器状态"""
        return {
            "running": self.running,
            "host": self.host,
            "port": self.port,
            "connected_clients": len(self.clients),
            "authenticated_clients": len([c for c in self.clients.values() if c["authenticated"]])
        }