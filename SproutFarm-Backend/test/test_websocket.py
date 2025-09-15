#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
测试WebSocket远程命令API
"""

import asyncio
import websockets
import json

async def test_client():
    """测试WebSocket客户端"""
    uri = "ws://localhost:7071"
    
    try:
        async with websockets.connect(uri) as websocket:
            print(f"✅ 已连接到 {uri}")
            
            # 接收欢迎消息
            welcome_msg = await websocket.recv()
            print(f"收到欢迎消息: {welcome_msg}")
            
            # 发送认证请求
            auth_data = {
                "type": "auth",
                "auth_key": "mengya2024"
            }
            await websocket.send(json.dumps(auth_data))
            print("已发送认证请求")
            
            # 接收认证结果
            auth_result = await websocket.recv()
            print(f"认证结果: {auth_result}")
            
            # 发送测试命令
            command_data = {
                "type": "command",
                "command": "help"
            }
            await websocket.send(json.dumps(command_data))
            print("已发送help命令")
            
            # 接收命令结果
            command_result = await websocket.recv()
            print(f"命令结果: {command_result}")
            
    except Exception as e:
        print(f"❌ 连接失败: {e}")

if __name__ == "__main__":
    print("开始测试WebSocket连接...")
    asyncio.run(test_client())