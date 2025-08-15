#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
游戏小提示配置系统集成测试
测试完整的配置流程：数据库 -> 服务端 -> 客户端请求 -> 配置应用
"""

import sys
import os
import time
import threading
import socket
import json

# 添加当前目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from SMYMongoDBAPI import SMYMongoDBAPI
from TCPGameServer import TCPGameServer

def test_database_config():
    """测试数据库配置"""
    print("=== 测试数据库配置 ===")
    
    try:
        # 连接数据库
        mongo_api = SMYMongoDBAPI(environment="test")
        
        if not mongo_api.is_connected():
            print("❌ 数据库连接失败")
            return False
        
        # 获取游戏小提示配置
        config = mongo_api.get_game_tips_config()
        
        if config:
            print("✓ 成功获取游戏小提示配置：")
            print(f"  切换模式: {config.get('切换模式', '未设置')}")
            print(f"  切换速度: {config.get('切换速度', '未设置')}")
            print(f"  游戏小提示数量: {len(config.get('游戏小提示', []))}")
            
            tips = config.get('游戏小提示', [])
            if tips:
                print("  前3条小提示:")
                for i, tip in enumerate(tips[:3], 1):
                    print(f"    {i}. {tip}")
            
            mongo_api.disconnect()
            return True
        else:
            print("❌ 未找到游戏小提示配置")
            mongo_api.disconnect()
            return False
            
    except Exception as e:
        print(f"❌ 数据库测试失败: {e}")
        return False

def test_server_config_loading():
    """测试服务端配置加载"""
    print("\n=== 测试服务端配置加载 ===")
    
    try:
        # 初始化游戏服务器
        server = TCPGameServer(server_host="localhost", server_port=0)
        
        if not server.mongo_api or not server.mongo_api.is_connected():
            print("❌ 服务器MongoDB连接失败")
            return False
        
        print("✓ 服务器成功连接到MongoDB数据库")
        
        # 测试配置加载
        config = server._load_game_tips_config()
        
        if config:
            print("✓ 服务器成功加载游戏小提示配置：")
            print(f"  切换模式: {config.get('切换模式', '未设置')}")
            print(f"  切换速度: {config.get('切换速度', '未设置')}")
            print(f"  游戏小提示数量: {len(config.get('游戏小提示', []))}")
            
            tips = config.get('游戏小提示', [])
            if tips:
                print("  前3条小提示:")
                for i, tip in enumerate(tips[:3], 1):
                    print(f"    {i}. {tip}")
            
            server.mongo_api.disconnect()
            print("✓ 服务器已断开MongoDB数据库连接")
            return True
        else:
            print("❌ 服务器加载游戏小提示配置失败")
            server.mongo_api.disconnect()
            return False
            
    except Exception as e:
        print(f"❌ 服务端测试失败: {e}")
        return False

def test_client_server_communication():
    """测试客户端-服务端通信"""
    print("\n=== 测试客户端-服务端通信 ===")
    
    server = None
    client_socket = None
    
    try:
        # 启动服务器（使用固定端口进行测试）
        test_port = 17070
        server = TCPGameServer(server_host="localhost", server_port=test_port)
        
        if not server.mongo_api or not server.mongo_api.is_connected():
            print("❌ 服务器MongoDB连接失败")
            return False
        
        # 在新线程中启动服务器
        server_thread = threading.Thread(target=server.start, daemon=True)
        server_thread.start()
        
        # 等待服务器启动
        time.sleep(1)
        
        # 获取服务器端口
        server_port = test_port
        print(f"✓ 服务器已启动，端口: {server_port}")
        
        # 创建客户端连接
        client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client_socket.settimeout(5)
        client_socket.connect(("localhost", server_port))
        print("✓ 客户端已连接到服务器")
        
        # 发送游戏小提示配置请求
        request = {
            "type": "request_game_tips_config"
        }
        
        request_data = json.dumps(request).encode('utf-8')
        client_socket.send(len(request_data).to_bytes(4, byteorder='big'))
        client_socket.send(request_data)
        print("✓ 已发送游戏小提示配置请求")
        
        # 接收响应
        response_length_bytes = client_socket.recv(4)
        if len(response_length_bytes) != 4:
            print("❌ 接收响应长度失败")
            return False
        
        response_length = int.from_bytes(response_length_bytes, byteorder='big')
        response_data = b''
        
        while len(response_data) < response_length:
            chunk = client_socket.recv(response_length - len(response_data))
            if not chunk:
                break
            response_data += chunk
        
        if len(response_data) != response_length:
            print("❌ 接收响应数据不完整")
            return False
        
        # 解析响应
        response = json.loads(response_data.decode('utf-8'))
        print("✓ 已接收服务器响应")
        
        # 验证响应
        if response.get("type") == "game_tips_config_response":
            if response.get("success"):
                config = response.get("game_tips_config", {})
                print("✓ 成功接收游戏小提示配置：")
                print(f"  切换模式: {config.get('切换模式', '未设置')}")
                print(f"  切换速度: {config.get('切换速度', '未设置')}")
                print(f"  游戏小提示数量: {len(config.get('游戏小提示', []))}")
                
                tips = config.get('游戏小提示', [])
                if tips:
                    print("  前3条小提示:")
                    for i, tip in enumerate(tips[:3], 1):
                        print(f"    {i}. {tip}")
                
                return True
            else:
                message = response.get("message", "未知错误")
                print(f"❌ 服务器返回失败: {message}")
                return False
        else:
            print(f"❌ 收到意外的响应类型: {response.get('type')}")
            return False
            
    except Exception as e:
        print(f"❌ 客户端-服务端通信测试失败: {e}")
        return False
    
    finally:
        # 清理资源
        if client_socket:
            try:
                client_socket.close()
            except:
                pass
        
        if server and server.mongo_api:
            try:
                server.mongo_api.disconnect()
            except:
                pass

def main():
    """主测试函数"""
    print("🚀 开始游戏小提示配置系统集成测试\n")
    
    # 测试结果
    results = {
        "数据库配置": test_database_config(),
        "服务端配置加载": test_server_config_loading(),
        "客户端-服务端通信": test_client_server_communication()
    }
    
    print("\n=== 测试结果 ===\n")
    
    all_passed = True
    for test_name, result in results.items():
        status = "✓ 通过" if result else "❌ 失败"
        print(f"{test_name}测试: {status}")
        if not result:
            all_passed = False
    
    if all_passed:
        print("\n🎉 所有测试通过！游戏小提示配置系统完全正常工作。")
        print("\n📋 系统功能确认:")
        print("  ✓ 数据库配置存储和读取正常")
        print("  ✓ 服务端配置加载正常")
        print("  ✓ 客户端-服务端通信正常")
        print("  ✓ 配置数据传输完整")
        print("\n🎮 客户端现在应该能够正确使用数据库中的游戏小提示配置！")
    else:
        print("\n❌ 部分测试失败，请检查相关组件。")
    
    return all_passed

if __name__ == "__main__":
    main()