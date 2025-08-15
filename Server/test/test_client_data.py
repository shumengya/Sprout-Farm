#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试发送给客户端的数据结构
模拟服务器发送给客户端的数据格式
"""

import json
from SMYMongoDBAPI import SMYMongoDBAPI

def test_client_data_format():
    """测试发送给客户端的数据格式"""
    print("=== 测试客户端数据格式 ===")
    
    try:
        # 初始化MongoDB API
        mongo_api = SMYMongoDBAPI("test")
        
        if not mongo_api.is_connected():
            print("❌ MongoDB连接失败")
            return
        
        print("✅ MongoDB连接成功")
        
        # 模拟_load_crop_data方法
        print("\n=== 测试作物数据 ===")
        crop_data = mongo_api.get_crop_data_config()
        
        if crop_data:
            # 模拟服务器发送的crop_data_message
            crop_data_message = {
                "type": "crop_data_response",
                "success": True,
                "crop_data": crop_data
            }
            
            print(f"作物数据类型: {type(crop_data)}")
            print(f"作物数据键数量: {len(crop_data)}")
            
            # 检查是否有config_type字段
            if 'config_type' in crop_data:
                print(f"⚠️  作物数据包含config_type: {crop_data['config_type']}")
            else:
                print("✅ 作物数据不包含config_type字段")
            
            # 检查前几个作物的数据结构
            crop_count = 0
            for crop_name, crop_info in crop_data.items():
                if crop_name not in ['_id', 'config_type'] and crop_count < 3:
                    print(f"\n作物 {crop_name}:")
                    print(f"  数据类型: {type(crop_info)}")
                    
                    if isinstance(crop_info, dict):
                        # 检查关键字段
                        key_fields = ['能否购买', '品质', '等级', '作物名称']
                        for key in key_fields:
                            if key in crop_info:
                                value = crop_info[key]
                                print(f"  {key}: {value} (类型: {type(value)})")
                                
                                # 特别检查能否购买字段
                                if key == '能否购买':
                                    if isinstance(value, str):
                                        print(f"    ⚠️  '能否购买'字段是字符串，这会导致Godot报错!")
                                    elif isinstance(value, bool):
                                        print(f"    ✅ '能否购买'字段是布尔值，正确")
                    elif isinstance(crop_info, str):
                        print(f"  ⚠️  整个作物数据是字符串: '{crop_info[:50]}...'")
                        print(f"    这会导致Godot调用.get()方法时报错!")
                    
                    crop_count += 1
            
            # 保存作物数据到文件以便检查
            with open('crop_data_debug.json', 'w', encoding='utf-8') as f:
                json.dump(crop_data_message, f, ensure_ascii=False, indent=2, default=str)
            print(f"\n✅ 作物数据已保存到 crop_data_debug.json")
        
        # 测试道具数据
        print("\n=== 测试道具数据 ===")
        item_config = mongo_api.get_item_config()
        
        if item_config:
            # 模拟服务器发送的item_config_message
            item_config_message = {
                "type": "item_config_response",
                "success": True,
                "item_config": item_config
            }
            
            print(f"道具数据类型: {type(item_config)}")
            
            # 检查是否有config_type字段
            if 'config_type' in item_config:
                print(f"⚠️  道具数据包含config_type: {item_config['config_type']}")
            else:
                print("✅ 道具数据不包含config_type字段")
            
            # 保存道具数据到文件
            with open('item_config_debug.json', 'w', encoding='utf-8') as f:
                json.dump(item_config_message, f, ensure_ascii=False, indent=2, default=str)
            print(f"✅ 道具数据已保存到 item_config_debug.json")
        
        # 检查JSON序列化后的数据
        print("\n=== 测试JSON序列化 ===")
        if crop_data:
            try:
                # 模拟服务器发送数据时的JSON序列化过程
                json_str = json.dumps(crop_data_message, ensure_ascii=False, default=str)
                
                # 模拟客户端接收数据时的JSON反序列化过程
                received_data = json.loads(json_str)
                
                print("✅ JSON序列化/反序列化成功")
                
                # 检查反序列化后的数据结构
                received_crop_data = received_data.get('crop_data', {})
                
                # 检查第一个作物的数据
                for crop_name, crop_info in received_crop_data.items():
                    if crop_name not in ['_id', 'config_type']:
                        print(f"\n反序列化后的作物 {crop_name}:")
                        print(f"  数据类型: {type(crop_info)}")
                        
                        if isinstance(crop_info, dict):
                            if '能否购买' in crop_info:
                                value = crop_info['能否购买']
                                print(f"  能否购买: {value} (类型: {type(value)})")
                        elif isinstance(crop_info, str):
                            print(f"  ⚠️  反序列化后变成字符串: '{crop_info[:50]}...'")
                        
                        break
                
            except Exception as e:
                print(f"❌ JSON序列化/反序列化失败: {e}")
        
    except Exception as e:
        print(f"❌ 测试过程中出错: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        if 'mongo_api' in locals():
            mongo_api.disconnect()
            print("\n✅ 数据库连接已关闭")

if __name__ == "__main__":
    test_client_data_format()