#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
作物数据MongoDB迁移脚本
作者: AI Assistant
功能: 将crop_data.json中的数据迁移到MongoDB
"""

import json
import sys
import os
from SMYMongoDBAPI import SMYMongoDBAPI

def migrate_crop_data():
    """迁移作物数据到MongoDB"""
    print("=== 作物数据MongoDB迁移脚本 ===")
    
    # 1. 连接MongoDB
    print("\n1. 连接MongoDB...")
    try:
        api = SMYMongoDBAPI("mengyafarm")  # 使用正式数据库
        if not api.is_connected():
            print("❌ MongoDB连接失败")
            return False
        print("✅ MongoDB连接成功")
    except Exception as e:
        print(f"❌ MongoDB连接异常: {e}")
        return False
    
    # 2. 从JSON文件加载作物数据
    print("\n2. 从JSON文件加载作物数据...")
    try:
        with open("config/crop_data.json", 'r', encoding='utf-8') as file:
            crop_data = json.load(file)
        print(f"✅ JSON数据加载成功，包含 {len(crop_data)} 种作物")
    except Exception as e:
        print(f"❌ 加载JSON文件失败: {e}")
        return False
    
    # 3. 检查MongoDB中是否已有数据
    print("\n3. 检查MongoDB中的现有数据...")
    try:
        existing_data = api.get_crop_data_config()
        if existing_data:
            print(f"⚠️ MongoDB中已存在作物数据，包含 {len(existing_data)} 种作物")
            choice = input("是否要覆盖现有数据？(y/N): ").strip().lower()
            if choice not in ['y', 'yes']:
                print("取消迁移")
                return False
        else:
            print("✅ MongoDB中暂无作物数据，可以进行迁移")
    except Exception as e:
        print(f"❌ 检查MongoDB数据时异常: {e}")
        return False
    
    # 4. 迁移数据到MongoDB
    print("\n4. 迁移数据到MongoDB...")
    try:
        success = api.update_crop_data_config(crop_data)
        if success:
            print("✅ 作物数据迁移成功")
        else:
            print("❌ 作物数据迁移失败")
            return False
    except Exception as e:
        print(f"❌ 迁移数据时异常: {e}")
        return False
    
    # 5. 验证迁移结果
    print("\n5. 验证迁移结果...")
    try:
        migrated_data = api.get_crop_data_config()
        if migrated_data and len(migrated_data) == len(crop_data):
            print(f"✅ 迁移验证成功，MongoDB中包含 {len(migrated_data)} 种作物")
            
            # 检查几个关键作物
            test_crops = ["小麦", "胡萝卜", "苹果", "松露"]
            print("\n验证关键作物数据:")
            for crop_name in test_crops:
                if crop_name in crop_data and crop_name in migrated_data:
                    original = crop_data[crop_name]
                    migrated = migrated_data[crop_name]
                    if original == migrated:
                        print(f"✅ {crop_name}: 数据一致")
                    else:
                        print(f"⚠️ {crop_name}: 数据不一致")
                else:
                    print(f"❌ {crop_name}: 数据缺失")
        else:
            print("❌ 迁移验证失败")
            return False
    except Exception as e:
        print(f"❌ 验证迁移结果时异常: {e}")
        return False
    
    print("\n=== 迁移完成 ===")
    print("\n📋 迁移摘要:")
    print(f"   • 源文件: config/crop_data.json")
    print(f"   • 目标数据库: mengyafarm")
    print(f"   • 目标集合: gameconfig")
    print(f"   • 文档ID: 687cfb3d8e77ba00a7414bac")
    print(f"   • 迁移作物数量: {len(crop_data)}")
    print("\n✅ 作物数据已成功迁移到MongoDB！")
    print("\n💡 提示: 服务器现在会优先从MongoDB加载作物数据，如果MongoDB不可用会自动回退到JSON文件。")
    
    return True

def main():
    """主函数"""
    try:
        migrate_crop_data()
    except KeyboardInterrupt:
        print("\n迁移被用户中断")
    except Exception as e:
        print(f"迁移过程中发生异常: {e}")

if __name__ == "__main__":
    main()