#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
特殊农场管理系统测试脚本
作者: AI Assistant
功能: 测试特殊农场的种植功能
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from SpecialFarm import SpecialFarmManager

def test_special_farm():
    """
    测试特殊农场功能
    """
    print("=" * 50)
    print("特殊农场管理系统测试")
    print("=" * 50)
    
    try:
        # 创建管理器（使用测试环境）
        print("1. 初始化特殊农场管理器...")
        manager = SpecialFarmManager("test")
        print("✓ 管理器初始化成功")
        
        # 测试数据库连接
        print("\n2. 测试数据库连接...")
        if manager.mongo_api.is_connected():
            print("✓ 数据库连接成功")
        else:
            print("✗ 数据库连接失败")
            return False
        
        # 测试获取作物配置
        print("\n3. 测试获取作物配置...")
        crop_data = manager.get_crop_data()
        if crop_data:
            print(f"✓ 成功获取作物配置，共 {len(crop_data)} 种作物")
            
            # 检查杂交树是否存在
            if "杂交树1" in crop_data and "杂交树2" in crop_data:
                print("✓ 杂交树1和杂交树2配置存在")
                print(f"  - 杂交树1: {crop_data['杂交树1']['作物名称']}")
                print(f"  - 杂交树2: {crop_data['杂交树2']['作物名称']}")
            else:
                print("✗ 杂交树配置不存在")
                return False
        else:
            print("✗ 获取作物配置失败")
            return False
        
        # 测试获取杂交农场数据
        print("\n4. 测试获取杂交农场数据...")
        farm_config = manager.special_farms["杂交农场"]
        object_id = farm_config["object_id"]
        
        player_data = manager.get_player_data_by_object_id(object_id)
        if player_data:
            print(f"✓ 成功获取杂交农场数据")
            print(f"  - 农场名称: {player_data.get('农场名称', 'Unknown')}")
            print(f"  - 玩家昵称: {player_data.get('玩家昵称', 'Unknown')}")
            print(f"  - 土地数量: {len(player_data.get('农场土地', []))}")
            
            # 统计土地状态
            farm_lands = player_data.get("农场土地", [])
            digged_count = sum(1 for land in farm_lands if land.get("is_diged", False))
            planted_count = sum(1 for land in farm_lands if land.get("is_planted", False))
            
            print(f"  - 已开垦土地: {digged_count}")
            print(f"  - 已种植土地: {planted_count}")
        else:
            print("✗ 获取杂交农场数据失败")
            return False
        
        # 测试种植功能
        print("\n5. 测试杂交农场种植功能...")
        if manager.plant_crops_in_farm("杂交农场"):
            print("✓ 杂交农场种植成功")
            
            # 重新获取数据验证种植结果
            updated_data = manager.get_player_data_by_object_id(object_id)
            if updated_data:
                farm_lands = updated_data.get("农场土地", [])
                planted_count = sum(1 for land in farm_lands if land.get("is_planted", False))
                
                # 统计种植的作物类型
                crop_types = {}
                for land in farm_lands:
                    if land.get("is_planted", False):
                        crop_type = land.get("crop_type", "")
                        crop_types[crop_type] = crop_types.get(crop_type, 0) + 1
                
                print(f"  - 种植后已种植土地: {planted_count}")
                print(f"  - 作物分布:")
                for crop_type, count in crop_types.items():
                    print(f"    * {crop_type}: {count} 块")
        else:
            print("✗ 杂交农场种植失败")
            return False
        
        print("\n" + "=" * 50)
        print("✓ 所有测试通过！特殊农场管理系统工作正常")
        print("=" * 50)
        return True
        
    except Exception as e:
        print(f"\n✗ 测试过程中出错: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def test_manual_maintenance():
    """
    测试手动维护功能
    """
    print("\n" + "=" * 50)
    print("测试手动维护功能")
    print("=" * 50)
    
    try:
        manager = SpecialFarmManager("test")
        
        print("执行手动维护...")
        if manager.manual_maintenance("杂交农场"):
            print("✓ 手动维护成功")
        else:
            print("✗ 手动维护失败")
            
    except Exception as e:
        print(f"✗ 手动维护测试出错: {str(e)}")

if __name__ == "__main__":
    # 运行基础测试
    success = test_special_farm()
    
    if success:
        # 运行手动维护测试
        test_manual_maintenance()
        
        print("\n" + "=" * 50)
        print("使用说明:")
        print("1. 自动模式: python SpecialFarm.py [test|production]")
        print("2. 手动模式: python SpecialFarm.py [test|production] manual [农场名称]")
        print("3. 日志文件: special_farm.log")
        print("=" * 50)
    else:
        print("\n测试失败，请检查配置和数据库连接")
        sys.exit(1)