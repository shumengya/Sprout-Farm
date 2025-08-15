#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试游戏小提示配置功能
验证服务端能否正确加载和返回游戏小提示配置数据
"""

import sys
import os

# 添加当前目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from SMYMongoDBAPI import SMYMongoDBAPI
from TCPGameServer import TCPGameServer

def test_mongo_api():
    """测试MongoDB API的游戏小提示配置功能"""
    print("=== 测试MongoDB API ===\n")
    
    try:
        # 创建MongoDB API实例
        mongo_api = SMYMongoDBAPI()
        
        # 连接到数据库
        if not mongo_api.connect():
            print("错误：无法连接到MongoDB数据库")
            return False
        
        print("成功连接到MongoDB数据库")
        
        # 获取游戏小提示配置
        config = mongo_api.get_game_tips_config()
        
        if config:
            print("成功获取游戏小提示配置：")
            print(f"  切换模式: {config.get('切换模式', 'N/A')}")
            print(f"  切换速度: {config.get('切换速度', 'N/A')}")
            tips = config.get('游戏小提示', [])
            print(f"  游戏小提示数量: {len(tips)}")
            print("  前3条小提示:")
            for i, tip in enumerate(tips[:3]):
                print(f"    {i+1}. {tip}")
            return True
        else:
            print("错误：无法获取游戏小提示配置")
            return False
            
    except Exception as e:
        print(f"测试过程中发生错误: {str(e)}")
        return False
    finally:
        # 断开数据库连接
        if 'mongo_api' in locals():
            mongo_api.disconnect()
            print("已断开MongoDB数据库连接")

def test_game_server():
    """测试游戏服务器的游戏小提示配置加载功能"""
    print("\n=== 测试游戏服务器 ===\n")
    
    try:
        # 创建游戏服务器实例（不启动网络服务）
        server = TCPGameServer()
        
        # 初始化MongoDB连接
        server.mongo_api = SMYMongoDBAPI()
        if not server.mongo_api.connect():
            print("错误：服务器无法连接到MongoDB数据库")
            return False
        
        print("服务器成功连接到MongoDB数据库")
        
        # 测试加载游戏小提示配置
        config = server._load_game_tips_config()
        
        if config:
            print("服务器成功加载游戏小提示配置：")
            print(f"  切换模式: {config.get('切换模式', 'N/A')}")
            print(f"  切换速度: {config.get('切换速度', 'N/A')}")
            tips = config.get('游戏小提示', [])
            print(f"  游戏小提示数量: {len(tips)}")
            print("  前3条小提示:")
            for i, tip in enumerate(tips[:3]):
                print(f"    {i+1}. {tip}")
            return True
        else:
            print("错误：服务器无法加载游戏小提示配置")
            return False
            
    except Exception as e:
        print(f"测试过程中发生错误: {str(e)}")
        return False
    finally:
        # 断开数据库连接
        if 'server' in locals() and hasattr(server, 'mongo_api') and server.mongo_api:
            server.mongo_api.disconnect()
            print("服务器已断开MongoDB数据库连接")

if __name__ == "__main__":
    print("开始测试游戏小提示配置功能...\n")
    
    # 测试MongoDB API
    mongo_success = test_mongo_api()
    
    # 测试游戏服务器
    server_success = test_game_server()
    
    print("\n=== 测试结果 ===\n")
    print(f"MongoDB API测试: {'✓ 通过' if mongo_success else '✗ 失败'}")
    print(f"游戏服务器测试: {'✓ 通过' if server_success else '✗ 失败'}")
    
    if mongo_success and server_success:
        print("\n🎉 所有测试通过！游戏小提示配置功能正常工作。")
    else:
        print("\n❌ 部分测试失败，请检查配置。")
        sys.exit(1)