#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
作物数据MongoDB迁移测试脚本
作者: AI Assistant
功能: 测试作物数据从JSON到MongoDB的迁移功能
"""

import json
import sys
import os
from SMYMongoDBAPI import SMYMongoDBAPI

def load_crop_data_from_json():
    """从JSON文件加载作物数据"""
    try:
        with open("config/crop_data.json", 'r', encoding='utf-8') as file:
            return json.load(file)
    except Exception as e:
        print(f"❌ 加载JSON文件失败: {e}")
        return None

def test_crop_data_migration():
    """测试作物数据迁移"""
    print("=== 作物数据MongoDB迁移测试 ===")
    
    # 1. 连接MongoDB
    print("\n1. 连接MongoDB...")
    try:
        api = SMYMongoDBAPI("test")
        if not api.is_connected():
            print("❌ MongoDB连接失败")
            return False
        print("✅ MongoDB连接成功")
    except Exception as e:
        print(f"❌ MongoDB连接异常: {e}")
        return False
    
    # 2. 从JSON文件加载作物数据
    print("\n2. 从JSON文件加载作物数据...")
    json_data = load_crop_data_from_json()
    if not json_data:
        print("❌ JSON数据加载失败")
        return False
    print(f"✅ JSON数据加载成功，包含 {len(json_data)} 种作物")
    
    # 3. 测试从MongoDB获取作物数据
    print("\n3. 从MongoDB获取作物数据...")
    try:
        mongo_data = api.get_crop_data_config()
        if mongo_data:
            print(f"✅ MongoDB数据获取成功，包含 {len(mongo_data)} 种作物")
            
            # 4. 比较数据一致性
            print("\n4. 比较数据一致性...")
            if len(json_data) == len(mongo_data):
                print("✅ 作物数量一致")
            else:
                print(f"⚠️ 作物数量不一致: JSON({len(json_data)}) vs MongoDB({len(mongo_data)})")
            
            # 检查几个关键作物
            test_crops = ["小麦", "胡萝卜", "苹果", "松露"]
            for crop_name in test_crops:
                if crop_name in json_data and crop_name in mongo_data:
                    json_crop = json_data[crop_name]
                    mongo_crop = mongo_data[crop_name]
                    if json_crop == mongo_crop:
                        print(f"✅ {crop_name} 数据一致")
                    else:
                        print(f"⚠️ {crop_name} 数据不一致")
                        print(f"   JSON: {json_crop.get('花费', 'N/A')}元, {json_crop.get('生长时间', 'N/A')}秒")
                        print(f"   MongoDB: {mongo_crop.get('花费', 'N/A')}元, {mongo_crop.get('生长时间', 'N/A')}秒")
                else:
                    print(f"❌ {crop_name} 在某个数据源中缺失")
        else:
            print("❌ MongoDB中未找到作物数据")
            
            # 5. 如果MongoDB中没有数据，尝试更新
            print("\n5. 尝试更新MongoDB中的作物数据...")
            try:
                success = api.update_crop_data_config(json_data)
                if success:
                    print("✅ 作物数据更新到MongoDB成功")
                    
                    # 再次验证
                    print("\n6. 验证更新后的数据...")
                    updated_data = api.get_crop_data_config()
                    if updated_data and len(updated_data) == len(json_data):
                        print("✅ 数据更新验证成功")
                    else:
                        print("❌ 数据更新验证失败")
                else:
                    print("❌ 作物数据更新到MongoDB失败")
            except Exception as e:
                print(f"❌ 更新MongoDB数据时异常: {e}")
                
    except Exception as e:
        print(f"❌ 从MongoDB获取数据时异常: {e}")
        return False
    
    # 7. 测试服务器加载逻辑
    print("\n7. 测试服务器加载逻辑...")
    try:
        # 模拟服务器的加载逻辑
        from TCPGameServer import TCPGameServer
        
        # 创建服务器实例（不启动网络服务）
        server = TCPGameServer()
        
        # 测试加载作物数据
        crop_data = server._load_crop_data()
        if crop_data and len(crop_data) > 0:
            print(f"✅ 服务器成功加载作物数据，包含 {len(crop_data)} 种作物")
            
            # 测试几个关键作物
            test_crops = ["小麦", "胡萝卜"]
            for crop_name in test_crops:
                if crop_name in crop_data:
                    crop = crop_data[crop_name]
                    print(f"✅ {crop_name}: {crop.get('花费', 'N/A')}元, {crop.get('生长时间', 'N/A')}秒, {crop.get('品质', 'N/A')}")
                else:
                    print(f"❌ 服务器数据中缺少 {crop_name}")
        else:
            print("❌ 服务器加载作物数据失败")
            
    except Exception as e:
        print(f"❌ 测试服务器加载逻辑时异常: {e}")
    
    print("\n=== 测试完成 ===")
    return True

def main():
    """主函数"""
    try:
        test_crop_data_migration()
    except KeyboardInterrupt:
        print("\n测试被用户中断")
    except Exception as e:
        print(f"测试过程中发生异常: {e}")

if __name__ == "__main__":
    main()