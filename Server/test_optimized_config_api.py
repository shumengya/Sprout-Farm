#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试优化后的配置API
验证所有配置方法是否正常工作
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from SMYMongoDBAPI import SMYMongoDBAPI

def test_all_config_methods():
    """测试所有配置方法"""
    print("=== 测试优化后的配置API ===")
    
    try:
        # 创建API实例（测试环境）
        api = SMYMongoDBAPI("test")
        
        if not api.is_connected():
            print("❌ 数据库连接失败，请检查MongoDB服务")
            return False
        
        print("✅ 数据库连接成功")
        
        # 测试所有配置方法
        config_tests = [
            ("每日签到配置", api.get_daily_checkin_config),
            ("幸运抽奖配置", api.get_lucky_draw_config),
            ("新手大礼包配置", api.get_new_player_config),
            ("智慧树配置", api.get_wisdom_tree_config),
            ("稻草人配置", api.get_scare_crow_config),
            ("在线礼包配置", api.get_online_gift_config),
            ("道具配置", api.get_item_config),
            ("宠物配置", api.get_pet_config),
            ("体力系统配置", api.get_stamina_config),
            ("作物数据配置", api.get_crop_data_config),
            ("初始玩家数据模板", api.get_initial_player_data_template)
        ]
        
        success_count = 0
        total_count = len(config_tests)
        
        for config_name, get_method in config_tests:
            try:
                config = get_method()
                if config:
                    print(f"✅ {config_name}: 获取成功 ({len(config)} 个字段)")
                    success_count += 1
                else:
                    print(f"❌ {config_name}: 获取失败 (返回None)")
            except Exception as e:
                print(f"❌ {config_name}: 获取异常 - {e}")
        
        print(f"\n=== 测试结果 ===")
        print(f"成功: {success_count}/{total_count}")
        print(f"成功率: {success_count/total_count*100:.1f}%")
        
        # 测试CONFIG_IDS字典
        print(f"\n=== CONFIG_IDS字典验证 ===")
        print(f"配置ID数量: {len(api.CONFIG_IDS)}")
        for key, value in api.CONFIG_IDS.items():
            print(f"  {key}: {value}")
        
        # 断开连接
        api.disconnect()
        print("\n✅ 测试完成，数据库连接已断开")
        
        return success_count == total_count
        
    except Exception as e:
        print(f"❌ 测试过程中出现异常: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_code_optimization():
    """测试代码优化效果"""
    print("\n=== 代码优化验证 ===")
    
    # 读取SMYMongoDBAPI.py文件
    try:
        with open('SMYMongoDBAPI.py', 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 统计代码行数
        lines = content.split('\n')
        total_lines = len(lines)
        
        # 统计方法数量
        method_count = content.count('def ')
        
        # 统计通用方法使用次数
        generic_get_usage = content.count('_get_config_by_id')
        generic_update_usage = content.count('_update_config_by_id')
        
        print(f"✅ 代码文件总行数: {total_lines}")
        print(f"✅ 方法总数: {method_count}")
        print(f"✅ 通用获取方法使用次数: {generic_get_usage}")
        print(f"✅ 通用更新方法使用次数: {generic_update_usage}")
        
        # 检查是否还有重复代码
        duplicate_patterns = [
            'collection.find_one({"_id": object_id})',
            'collection.replace_one({"_id": object_id}, update_data)',
            'if "_id" in result:',
            'del result["_id"]'
        ]
        
        print(f"\n=== 重复代码检查 ===")
        for pattern in duplicate_patterns:
            count = content.count(pattern)
            if count > 2:  # 允许在通用方法中出现
                print(f"⚠️  发现重复代码: '{pattern}' 出现 {count} 次")
            else:
                print(f"✅ 代码模式 '{pattern}' 已优化")
        
        return True
        
    except Exception as e:
        print(f"❌ 代码优化验证失败: {e}")
        return False

if __name__ == "__main__":
    print("开始测试优化后的配置API...\n")
    
    # 测试所有配置方法
    api_test_success = test_all_config_methods()
    
    # 测试代码优化效果
    optimization_test_success = test_code_optimization()
    
    print(f"\n=== 最终结果 ===")
    if api_test_success and optimization_test_success:
        print("🎉 所有测试通过！代码优化成功！")
    else:
        print("❌ 部分测试失败，请检查相关问题")