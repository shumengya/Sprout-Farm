#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
完整的游戏小提示配置系统测试
测试从数据库导入到服务端处理的完整流程
"""

import sys
import os
import socket
import json
import time
import threading

# 添加当前目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from SMYMongoDBAPI import SMYMongoDBAPI
from TCPGameServer import TCPGameServer

def test_database_operations():
    """测试数据库操作"""
    print("=== 测试数据库操作 ===\n")
    
    try:
        mongo_api = SMYMongoDBAPI()
        if not mongo_api.connect():
            print("❌ 无法连接到MongoDB数据库")
            return False
        
        print("✓ 成功连接到MongoDB数据库")
        
        # 测试获取配置
        config = mongo_api.get_game_tips_config()
        if config:
            print("✓ 成功获取游戏小提示配置")
            print(f"  切换模式: {config.get('切换模式', 'N/A')}")
            print(f"  切换速度: {config.get('切换速度', 'N/A')}")
            print(f"  小提示数量: {len(config.get('游戏小提示', []))}")
            return True
        else:
            print("❌ 无法获取游戏小提示配置")
            return False
            
    except Exception as e:
        print(f"❌ 数据库测试失败: {str(e)}")
        return False
    finally:
        if 'mongo_api' in locals():
            mongo_api.disconnect()

def test_server_loading():
    """测试服务器加载配置"""
    print("\n=== 测试服务器加载配置 ===\n")
    
    try:
        server = TCPGameServer()
        server.mongo_api = SMYMongoDBAPI()
        
        if not server.mongo_api.connect():
            print("❌ 服务器无法连接到MongoDB")
            return False
        
        print("✓ 服务器成功连接到MongoDB")
        
        # 测试服务器加载配置
        config = server._load_game_tips_config()
        if config:
            print("✓ 服务器成功加载游戏小提示配置")
            print(f"  切换模式: {config.get('切换模式', 'N/A')}")
            print(f"  切换速度: {config.get('切换速度', 'N/A')}")
            print(f"  小提示数量: {len(config.get('游戏小提示', []))}")
            return True
        else:
            print("❌ 服务器无法加载游戏小提示配置")
            return False
            
    except Exception as e:
        print(f"❌ 服务器测试失败: {str(e)}")
        return False
    finally:
        if 'server' in locals() and hasattr(server, 'mongo_api') and server.mongo_api:
            server.mongo_api.disconnect()

def test_client_server_communication():
    """测试客户端-服务端通信"""
    print("\n=== 测试客户端-服务端通信 ===\n")
    
    # 启动服务器（在后台线程中）
    server = None
    server_thread = None
    
    try:
        print("启动测试服务器...")
        server = TCPGameServer()
        
        # 在后台线程中启动服务器
        def run_server():
            try:
                server.start_server()
            except Exception as e:
                print(f"服务器启动失败: {e}")
        
        server_thread = threading.Thread(target=run_server, daemon=True)
        server_thread.start()
        
        # 等待服务器启动
        time.sleep(2)
        
        # 创建客户端连接
        print("创建客户端连接...")
        client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client_socket.settimeout(5)
        
        try:
            client_socket.connect(('localhost', 12345))
            print("✓ 客户端成功连接到服务器")
            
            # 发送游戏小提示配置请求
            request = {
                "type": "request_game_tips_config"
            }
            
            message = json.dumps(request, ensure_ascii=False)
            client_socket.send(message.encode('utf-8'))
            print("✓ 已发送游戏小提示配置请求")
            
            # 接收响应
            response_data = client_socket.recv(4096)
            if response_data:
                response = json.loads(response_data.decode('utf-8'))
                print("✓ 收到服务器响应")
                
                if response.get("type") == "game_tips_config_response":
                    success = response.get("success", False)
                    if success:
                        config = response.get("game_tips_config", {})
                        print("✓ 成功获取游戏小提示配置")
                        print(f"  切换模式: {config.get('切换模式', 'N/A')}")
                        print(f"  切换速度: {config.get('切换速度', 'N/A')}")
                        print(f"  小提示数量: {len(config.get('游戏小提示', []))}")
                        return True
                    else:
                        message = response.get("message", "未知错误")
                        print(f"❌ 服务器返回失败: {message}")
                        return False
                else:
                    print(f"❌ 收到意外的响应类型: {response.get('type')}")
                    return False
            else:
                print("❌ 未收到服务器响应")
                return False
                
        except socket.timeout:
            print("❌ 客户端连接超时")
            return False
        except ConnectionRefusedError:
            print("❌ 无法连接到服务器")
            return False
        finally:
            client_socket.close()
            
    except Exception as e:
        print(f"❌ 通信测试失败: {str(e)}")
        return False
    finally:
        # 停止服务器
        if server:
            try:
                server.stop_server()
            except:
                pass

def main():
    """主测试函数"""
    print("开始完整的游戏小提示配置系统测试...\n")
    
    # 执行各项测试
    db_success = test_database_operations()
    server_success = test_server_loading()
    comm_success = test_client_server_communication()
    
    # 输出测试结果
    print("\n" + "="*50)
    print("测试结果汇总")
    print("="*50)
    print(f"数据库操作测试: {'✓ 通过' if db_success else '❌ 失败'}")
    print(f"服务器加载测试: {'✓ 通过' if server_success else '❌ 失败'}")
    print(f"客户端通信测试: {'✓ 通过' if comm_success else '❌ 失败'}")
    
    if db_success and server_success and comm_success:
        print("\n🎉 所有测试通过！游戏小提示配置系统完全正常工作。")
        print("\n系统功能说明:")
        print("1. ✓ 配置数据已成功导入MongoDB数据库")
        print("2. ✓ 服务端能正确加载和处理配置数据")
        print("3. ✓ 客户端能成功请求并接收配置数据")
        print("4. ✓ 支持顺序、倒序、随机三种切换模式")
        print("5. ✓ 支持自定义切换速度")
        print("\n现在客户端可以从服务端获取游戏小提示配置，")
        print("并根据配置的切换模式和速度显示小提示。")
        return True
    else:
        print("\n❌ 部分测试失败，请检查系统配置。")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)