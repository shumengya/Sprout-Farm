#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
初始玩家数据模板MongoDB迁移测试脚本
作者: AI Assistant
功能: 测试初始玩家数据模板从JSON到MongoDB的迁移功能
"""

import json
import sys
import os
from SMYMongoDBAPI import SMYMongoDBAPI

def load_template_from_json():
    """从JSON文件加载初始玩家数据模板"""
    try:
        with open("config/initial_player_data_template.json", 'r', encoding='utf-8') as file:
            return json.load(file)
    except Exception as e:
        print(f"❌ 加载JSON文件失败: {e}")
        return None

def test_initial_player_template_migration():
    """测试初始玩家数据模板迁移"""
    print("=== 初始玩家数据模板MongoDB迁移测试 ===")
    
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
    
    # 2. 从JSON文件加载模板数据
    print("\n2. 从JSON文件加载初始玩家数据模板...")
    json_data = load_template_from_json()
    if not json_data:
        print("❌ JSON数据加载失败")
        return False
    print(f"✅ JSON数据加载成功，包含字段: {len(json_data)} 个")
    print(f"   主要字段: {list(json_data.keys())[:8]}...")
    
    # 3. 测试从MongoDB获取模板数据
    print("\n3. 从MongoDB获取初始玩家数据模板...")
    try:
        mongo_data = api.get_initial_player_data_template()
        if mongo_data:
            print(f"✅ MongoDB数据获取成功，包含字段: {len(mongo_data)} 个")
            
            # 4. 比较数据一致性
            print("\n4. 比较数据一致性...")
            if len(json_data) == len(mongo_data):
                print("✅ 字段数量一致")
            else:
                print(f"⚠️ 字段数量不一致: JSON({len(json_data)}) vs MongoDB({len(mongo_data)})")
            
            # 检查关键字段
            key_fields = ["经验值", "等级", "钱币", "农场土地", "种子仓库", "作物仓库", "道具背包"]
            for field in key_fields:
                if field in json_data and field in mongo_data:
                    json_value = json_data[field]
                    mongo_value = mongo_data[field]
                    if json_value == mongo_value:
                        print(f"✅ {field}: 数据一致")
                    else:
                        print(f"⚠️ {field}: 数据不一致")
                        if field in ["经验值", "等级", "钱币"]:
                            print(f"   JSON: {json_value}, MongoDB: {mongo_value}")
                        elif field == "农场土地":
                            print(f"   JSON: {len(json_value)}块地, MongoDB: {len(mongo_value)}块地")
                else:
                    print(f"❌ {field}: 字段缺失")
        else:
            print("❌ MongoDB中未找到初始玩家数据模板")
            
            # 5. 如果MongoDB中没有数据，尝试更新
            print("\n5. 尝试更新MongoDB中的初始玩家数据模板...")
            try:
                success = api.update_initial_player_data_template(json_data)
                if success:
                    print("✅ 初始玩家数据模板更新到MongoDB成功")
                    
                    # 再次验证
                    print("\n6. 验证更新后的数据...")
                    updated_data = api.get_initial_player_data_template()
                    if updated_data and len(updated_data) == len(json_data):
                        print("✅ 数据更新验证成功")
                        
                        # 验证关键字段
                        for field in ["经验值", "等级", "钱币"]:
                            if field in updated_data and updated_data[field] == json_data[field]:
                                print(f"✅ {field}: {updated_data[field]}")
                    else:
                        print("❌ 数据更新验证失败")
                else:
                    print("❌ 初始玩家数据模板更新到MongoDB失败")
            except Exception as e:
                print(f"❌ 更新MongoDB数据时异常: {e}")
                
    except Exception as e:
        print(f"❌ 从MongoDB获取数据时异常: {e}")
        return False
    
    # 7. 测试服务器创建新用户逻辑
    print("\n7. 测试服务器创建新用户逻辑...")
    try:
        # 模拟服务器的创建用户逻辑
        from TCPGameServer import TCPGameServer
        
        # 创建服务器实例（不启动网络服务）
        server = TCPGameServer()
        
        # 测试模板加载（通过_ensure_player_data_fields方法间接测试）
        test_data = {"测试": "数据"}
        server._ensure_player_data_fields(test_data)
        
        if "农场土地" in test_data and len(test_data["农场土地"]) == 40:
            print(f"✅ 服务器成功生成农场土地，共 {len(test_data['农场土地'])} 块")
            
            # 检查前20块地是否已开垦
            digged_count = sum(1 for land in test_data["农场土地"] if land.get("is_diged", False))
            print(f"✅ 已开垦土地: {digged_count} 块")
        else:
            print("❌ 服务器农场土地生成失败")
            
        # 检查基本仓库
        required_fields = ["种子仓库", "作物仓库", "道具背包", "宠物背包", "巡逻宠物", "出战宠物"]
        missing_fields = [field for field in required_fields if field not in test_data]
        if not missing_fields:
            print(f"✅ 所有必要仓库字段已创建: {required_fields}")
        else:
            print(f"❌ 缺少仓库字段: {missing_fields}")
            
    except Exception as e:
        print(f"❌ 测试服务器逻辑时异常: {e}")
    
    print("\n=== 测试完成 ===")
    return True

def main():
    """主函数"""
    try:
        test_initial_player_template_migration()
    except KeyboardInterrupt:
        print("\n测试被用户中断")
    except Exception as e:
        print(f"测试过程中发生异常: {e}")

if __name__ == "__main__":
    main()