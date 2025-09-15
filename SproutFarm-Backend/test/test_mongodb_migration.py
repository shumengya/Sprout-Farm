#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
测试MongoDB迁移功能
作者: AI Assistant
功能: 测试每日签到配置从JSON迁移到MongoDB的功能
"""

import sys
import os
import json

# 添加当前目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from SMYMongoDBAPI import SMYMongoDBAPI

def test_mongodb_migration():
    """测试MongoDB迁移功能"""
    print("=== 测试MongoDB迁移功能 ===")
    
    # 1. 测试MongoDB API连接
    print("\n1. 测试MongoDB API连接:")
    try:
        api = SMYMongoDBAPI("test")
        if api.is_connected():
            print("✓ MongoDB连接成功")
        else:
            print("✗ MongoDB连接失败")
            return False
    except Exception as e:
        print(f"✗ MongoDB连接异常: {e}")
        return False
    
    # 2. 测试获取每日签到配置
    print("\n2. 测试获取每日签到配置:")
    try:
        config = api.get_daily_checkin_config()
        if config:
            print("✓ 成功获取每日签到配置")
            print(f"  基础奖励金币范围: {config.get('基础奖励', {}).get('金币', {})}")
            print(f"  种子奖励类型数量: {len(config.get('种子奖励', {}))}")
            print(f"  连续签到奖励天数: {len(config.get('连续签到奖励', {}))}")
        else:
            print("✗ 获取每日签到配置失败")
            return False
    except Exception as e:
        print(f"✗ 获取每日签到配置异常: {e}")
        return False
    
    # 3. 测试更新配置
    print("\n3. 测试更新每日签到配置:")
    try:
        # 创建一个测试配置
        test_config = {
            "基础奖励": {
                "金币": {"最小值": 300, "最大值": 600, "图标": "💰", "颜色": "#FFD700"},
                "经验": {"最小值": 75, "最大值": 150, "图标": "⭐", "颜色": "#00BFFF"}
            },
            "种子奖励": {
                "普通": {"概率": 0.6, "数量范围": [2, 5], "种子池": ["小麦", "胡萝卜", "土豆", "稻谷"]},
                "优良": {"概率": 0.25, "数量范围": [2, 4], "种子池": ["玉米", "番茄", "洋葱", "大豆", "豌豆", "黄瓜", "大白菜"]},
                "稀有": {"概率": 0.12, "数量范围": [1, 3], "种子池": ["草莓", "花椰菜", "柿子", "蓝莓", "树莓"]},
                "史诗": {"概率": 0.025, "数量范围": [1, 2], "种子池": ["葡萄", "南瓜", "芦笋", "茄子", "向日葵", "蕨菜"]},
                "传奇": {"概率": 0.005, "数量范围": [1, 1], "种子池": ["西瓜", "甘蔗", "香草", "甜菜", "人参", "富贵竹", "芦荟", "哈密瓜"]}
            },
            "连续签到奖励": {
                "第3天": {"额外金币": 150, "额外经验": 75, "描述": "连续签到奖励"},
                "第7天": {"额外金币": 300, "额外经验": 150, "描述": "一周连击奖励"},
                "第14天": {"额外金币": 600, "额外经验": 250, "描述": "半月连击奖励"},
                "第21天": {"额外金币": 1000, "额外经验": 400, "描述": "三周连击奖励"},
                "第30天": {"额外金币": 2000, "额外经验": 600, "描述": "满月连击奖励"}
            }
        }
        
        success = api.update_daily_checkin_config(test_config)
        if success:
            print("✓ 成功更新测试配置到MongoDB")
        else:
            print("✗ 更新测试配置失败")
            return False
    except Exception as e:
        print(f"✗ 更新测试配置异常: {e}")
        return False
    
    # 4. 验证更新后的配置
    print("\n4. 验证更新后的配置:")
    try:
        updated_config = api.get_daily_checkin_config()
        if updated_config:
            print("✓ 成功获取更新后的配置")
            print(f"  更新后金币范围: {updated_config.get('基础奖励', {}).get('金币', {})}")
            print(f"  更新后第3天奖励: {updated_config.get('连续签到奖励', {}).get('第3天', {})}")
            
            # 验证更新是否生效
            if updated_config.get('基础奖励', {}).get('金币', {}).get('最小值') == 300:
                print("✓ 配置更新验证成功")
            else:
                print("✗ 配置更新验证失败")
                return False
        else:
            print("✗ 获取更新后的配置失败")
            return False
    except Exception as e:
        print(f"✗ 验证更新后配置异常: {e}")
        return False
    
    # 5. 恢复原始配置
    print("\n5. 恢复原始配置:")
    try:
        original_config = {
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
        
        success = api.update_daily_checkin_config(original_config)
        if success:
            print("✓ 成功恢复原始配置")
        else:
            print("✗ 恢复原始配置失败")
            return False
    except Exception as e:
        print(f"✗ 恢复原始配置异常: {e}")
        return False
    
    # 6. 测试配置数据完整性
    print("\n6. 测试配置数据完整性:")
    try:
        final_config = api.get_daily_checkin_config()
        if final_config:
            # 检查必要字段是否存在
            required_fields = ["基础奖励", "种子奖励", "连续签到奖励"]
            missing_fields = [field for field in required_fields if field not in final_config]
            
            if not missing_fields:
                print("✓ 配置数据完整性检查通过")
                print(f"  包含字段: {', '.join(required_fields)}")
            else:
                print(f"✗ 配置数据缺少字段: {missing_fields}")
                return False
        else:
            print("✗ 无法获取最终配置进行完整性检查")
            return False
            
    except Exception as e:
        print(f"✗ 配置数据完整性检查异常: {e}")
        return False
    
    # 清理资源
    api.disconnect()
    
    print("\n=== 所有测试通过！MongoDB迁移功能正常 ===")
    return True

if __name__ == "__main__":
    success = test_mongodb_migration()
    if success:
        print("\n🎉 MongoDB迁移测试成功完成！")
        sys.exit(0)
    else:
        print("\n❌ MongoDB迁移测试失败！")
        sys.exit(1) 