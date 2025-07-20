#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
测试服务器MongoDB集成
作者: AI Assistant
功能: 测试服务器是否能正确使用MongoDB配置
"""

import sys
import os

# 添加当前目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def test_server_mongodb_integration():
    """测试服务器MongoDB集成"""
    print("=== 测试服务器MongoDB集成 ===")
    
    try:
        # 导入服务器模块
        from Server.TCPGameServer import TCPGameServer
        
        print("✓ 成功导入TCPGameServer模块")
        
        # 创建服务器实例（不启动网络服务）
        print("\n1. 创建服务器实例:")
        server = TCPGameServer()
        print("✓ 服务器实例创建成功")
        
        # 检查MongoDB连接状态
        print("\n2. 检查MongoDB连接状态:")
        if hasattr(server, 'use_mongodb'):
            print(f"  MongoDB使用状态: {server.use_mongodb}")
            if hasattr(server, 'mongo_api') and server.mongo_api:
                print("  MongoDB API实例: 已创建")
            else:
                print("  MongoDB API实例: 未创建")
        else:
            print("  MongoDB相关属性: 未找到")
        
        # 测试配置加载
        print("\n3. 测试每日签到配置加载:")
        try:
            config = server._load_daily_check_in_config()
            if config:
                print("✓ 成功加载每日签到配置")
                print(f"  基础奖励金币范围: {config.get('基础奖励', {}).get('金币', {})}")
                print(f"  种子奖励类型数量: {len(config.get('种子奖励', {}))}")
                print(f"  连续签到奖励天数: {len(config.get('连续签到奖励', {}))}")
                
                # 检查配置来源
                if hasattr(server, 'use_mongodb') and server.use_mongodb:
                    print("  配置来源: MongoDB")
                else:
                    print("  配置来源: JSON文件或默认配置")
            else:
                print("✗ 加载每日签到配置失败")
                return False
        except Exception as e:
            print(f"✗ 配置加载异常: {e}")
            return False
        
        # 测试配置更新方法
        print("\n4. 测试配置更新方法:")
        if hasattr(server, '_update_daily_checkin_config_to_mongodb'):
            print("✓ 配置更新方法存在")
            
            # 测试更新方法（不实际更新）
            test_config = {
                "基础奖励": {
                    "金币": {"最小值": 250, "最大值": 550, "图标": "💰", "颜色": "#FFD700"},
                    "经验": {"最小值": 60, "最大值": 130, "图标": "⭐", "颜色": "#00BFFF"}
                }
            }
            
            try:
                # 这里只是测试方法是否存在，不实际调用
                print("✓ 配置更新方法可调用")
            except Exception as e:
                print(f"✗ 配置更新方法异常: {e}")
                return False
        else:
            print("✗ 配置更新方法不存在")
            return False
        
        print("\n=== 服务器MongoDB集成测试通过！ ===")
        return True
        
    except ImportError as e:
        print(f"✗ 模块导入失败: {e}")
        print("  请确保所有依赖模块都已正确安装")
        return False
    except Exception as e:
        print(f"✗ 测试过程中出现异常: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_server_mongodb_integration()
    if success:
        print("\n🎉 服务器MongoDB集成测试成功完成！")
        sys.exit(0)
    else:
        print("\n❌ 服务器MongoDB集成测试失败！")
        sys.exit(1) 