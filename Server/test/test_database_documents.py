#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
数据库文档结构测试脚本
用于检查MongoDB中gameconfig集合的文档结构
"""

import json
from SMYMongoDBAPI import SMYMongoDBAPI

def test_database_documents():
    """测试数据库文档结构"""
    print("=== 数据库文档结构测试 ===")
    
    try:
        # 初始化MongoDB API
        mongo_api = SMYMongoDBAPI("test")
        
        if not mongo_api.is_connected():
            print("❌ MongoDB连接失败")
            return
        
        print("✅ MongoDB连接成功")
        
        # 获取gameconfig集合
        collection = mongo_api.get_collection("gameconfig")
        
        print("\n=== 检查gameconfig集合中的所有文档 ===")
        
        # 查找所有文档
        documents = list(collection.find({}))
        
        print(f"找到 {len(documents)} 个文档")
        
        for i, doc in enumerate(documents):
            print(f"\n--- 文档 {i+1} ---")
            print(f"_id: {doc.get('_id')}")
            print(f"config_type: {doc.get('config_type', '未找到')}")
            
            # 检查是否有config_type字段
            if 'config_type' in doc:
                print(f"⚠️  发现config_type字段: {doc['config_type']}")
            else:
                print("✅ 没有config_type字段")
            
            # 显示文档的所有键
            print(f"文档键: {list(doc.keys())}")
            
            # 如果是作物配置，检查具体内容
            if doc.get('config_type') == '作物数据配置':
                print("\n=== 作物数据配置详细检查 ===")
                
                # 检查作物数据结构
                for key, value in doc.items():
                    if key not in ['_id', 'config_type']:
                        print(f"作物 {key}: {type(value)}")
                        
                        if isinstance(value, dict):
                            # 检查作物的具体字段
                            crop_keys = list(value.keys())
                            print(f"  作物字段: {crop_keys}")
                            
                            # 检查是否有字符串类型的字段被误认为是字典
                            for crop_key, crop_value in value.items():
                                if isinstance(crop_value, str) and crop_key in ['能否购买', '品质', '等级']:
                                    print(f"  ⚠️  字段 {crop_key} 是字符串类型: '{crop_value}'")
                        elif isinstance(value, str):
                            print(f"  ⚠️  整个作物数据是字符串: '{value[:100]}...'")
        
        print("\n=== 测试API方法返回的数据 ===")
        
        # 测试get_crop_data_config方法
        print("\n--- 测试get_crop_data_config ---")
        crop_data = mongo_api.get_crop_data_config()
        if crop_data:
            print(f"返回数据类型: {type(crop_data)}")
            print(f"返回数据键: {list(crop_data.keys()) if isinstance(crop_data, dict) else 'N/A'}")
            
            # 检查是否还有config_type字段
            if 'config_type' in crop_data:
                print(f"⚠️  API返回的数据仍包含config_type: {crop_data['config_type']}")
            else:
                print("✅ API返回的数据不包含config_type字段")
            
            # 检查第一个作物的数据结构
            for crop_name, crop_info in crop_data.items():
                if crop_name not in ['_id', 'config_type']:
                    print(f"\n作物 {crop_name}:")
                    print(f"  类型: {type(crop_info)}")
                    
                    if isinstance(crop_info, dict):
                        print(f"  字段: {list(crop_info.keys())}")
                        
                        # 检查关键字段
                        for key in ['能否购买', '品质', '等级']:
                            if key in crop_info:
                                value = crop_info[key]
                                print(f"  {key}: {value} (类型: {type(value)})")
                    elif isinstance(crop_info, str):
                        print(f"  ⚠️  作物数据是字符串: '{crop_info[:50]}...'")
                    
                    break  # 只检查第一个作物
        else:
            print("❌ get_crop_data_config返回空数据")
        
        # 测试get_item_config方法
        print("\n--- 测试get_item_config ---")
        item_data = mongo_api.get_item_config()
        if item_data:
            print(f"道具配置数据类型: {type(item_data)}")
            if 'config_type' in item_data:
                print(f"⚠️  道具配置仍包含config_type: {item_data['config_type']}")
            else:
                print("✅ 道具配置不包含config_type字段")
        
        # 测试find_documents方法
        print("\n--- 测试find_documents方法 ---")
        all_configs = mongo_api.find_documents("gameconfig", {})
        if all_configs:
            print(f"find_documents返回 {len(all_configs)} 个文档")
            for doc in all_configs:
                if 'config_type' in doc:
                    print(f"⚠️  find_documents返回的文档仍包含config_type: {doc['config_type']}")
                else:
                    print(f"✅ 文档ID {doc.get('_id')} 不包含config_type字段")
        
    except Exception as e:
        print(f"❌ 测试过程中出错: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        if 'mongo_api' in locals():
            mongo_api.disconnect()
            print("\n✅ 数据库连接已关闭")

if __name__ == "__main__":
    test_database_documents()