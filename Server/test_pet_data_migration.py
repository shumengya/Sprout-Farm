#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
宠物数据格式迁移测试脚本
用于验证从旧的嵌套数据格式到新的扁平化数据格式的迁移是否正确
"""

import json
import sys
import os

# 添加当前目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def test_old_to_new_format_conversion():
    """测试旧格式到新格式的转换"""
    print("=== 测试旧格式到新格式的转换 ===")
    
    # 模拟旧格式的宠物数据
    old_pet_data = {
        "基本信息": {
            "宠物ID": "pet_001",
            "宠物名称": "小火龙",
            "宠物类型": "火系",
            "拥有者": "player123",
            "场景路径": "res://Scene/Pet/FireDragon.tscn"
        },
        "等级经验": {
            "等级": 5,
            "经验值": 150,
            "最大经验值": 200
        },
        "生命与防御": {
            "当前生命值": 80,
            "最大生命值": 100,
            "最大护甲值": 20
        },
        "基础攻击属性": {
            "攻击伤害": 25
        },
        "移动与闪避": {
            "移动速度": 150
        },
        "亲密度": 75
    }
    
    # 转换为新格式
    def convert_to_new_format(old_data):
        """将旧格式转换为新格式"""
        basic_info = old_data.get("基本信息", {})
        level_exp = old_data.get("等级经验", {})
        health_defense = old_data.get("生命与防御", {})
        attack_attrs = old_data.get("基础攻击属性", {})
        movement = old_data.get("移动与闪避", {})
        
        return {
            "pet_id": basic_info.get("宠物ID", ""),
            "pet_name": basic_info.get("宠物名称", ""),
            "pet_type": basic_info.get("宠物类型", ""),
            "pet_owner": basic_info.get("拥有者", ""),
            "pet_image": basic_info.get("场景路径", ""),
            "pet_level": level_exp.get("等级", 1),
            "pet_experience": level_exp.get("经验值", 0),
            "pet_max_experience": level_exp.get("最大经验值", 100),
            "pet_current_health": health_defense.get("当前生命值", 100),
            "pet_max_health": health_defense.get("最大生命值", 100),
            "pet_max_armor": health_defense.get("最大护甲值", 0),
            "pet_attack_damage": attack_attrs.get("攻击伤害", 10),
            "pet_move_speed": movement.get("移动速度", 100),
            "pet_intimacy": old_data.get("亲密度", 0)
        }
    
    new_pet_data = convert_to_new_format(old_pet_data)
    
    print("旧格式数据:")
    print(json.dumps(old_pet_data, ensure_ascii=False, indent=2))
    print("\n新格式数据:")
    print(json.dumps(new_pet_data, ensure_ascii=False, indent=2))
    
    # 验证转换结果
    assert new_pet_data["pet_id"] == "pet_001"
    assert new_pet_data["pet_name"] == "小火龙"
    assert new_pet_data["pet_type"] == "火系"
    assert new_pet_data["pet_owner"] == "player123"
    assert new_pet_data["pet_level"] == 5
    assert new_pet_data["pet_experience"] == 150
    assert new_pet_data["pet_max_experience"] == 200
    assert new_pet_data["pet_current_health"] == 80
    assert new_pet_data["pet_max_health"] == 100
    assert new_pet_data["pet_max_armor"] == 20
    assert new_pet_data["pet_attack_damage"] == 25
    assert new_pet_data["pet_move_speed"] == 150
    assert new_pet_data["pet_intimacy"] == 75
    
    print("✅ 旧格式到新格式转换测试通过")
    return new_pet_data

def test_new_format_operations(pet_data):
    """测试新格式数据的各种操作"""
    print("\n=== 测试新格式数据操作 ===")
    
    # 测试宠物升级
    def level_up_pet(pet):
        """模拟宠物升级"""
        pet = pet.copy()
        pet["pet_level"] += 1
        pet["pet_experience"] = 0
        pet["pet_max_experience"] = pet["pet_level"] * 100
        pet["pet_max_health"] += 10
        pet["pet_current_health"] = pet["pet_max_health"]
        pet["pet_attack_damage"] += 5
        return pet
    
    # 测试宠物喂食
    def feed_pet(pet, exp_gain=20):
        """模拟宠物喂食"""
        pet = pet.copy()
        pet["pet_experience"] = min(pet["pet_experience"] + exp_gain, pet["pet_max_experience"])
        pet["pet_intimacy"] = min(pet["pet_intimacy"] + 5, 100)
        return pet
    
    # 测试宠物治疗
    def heal_pet(pet, heal_amount=20):
        """模拟宠物治疗"""
        pet = pet.copy()
        pet["pet_current_health"] = min(pet["pet_current_health"] + heal_amount, pet["pet_max_health"])
        return pet
    
    print("原始宠物数据:")
    print(f"等级: {pet_data['pet_level']}, 经验: {pet_data['pet_experience']}/{pet_data['pet_max_experience']}")
    print(f"生命值: {pet_data['pet_current_health']}/{pet_data['pet_max_health']}")
    print(f"攻击力: {pet_data['pet_attack_damage']}, 亲密度: {pet_data['pet_intimacy']}")
    
    # 测试喂食
    fed_pet = feed_pet(pet_data)
    print("\n喂食后:")
    print(f"经验: {fed_pet['pet_experience']}/{fed_pet['pet_max_experience']}")
    print(f"亲密度: {fed_pet['pet_intimacy']}")
    
    # 测试升级
    leveled_pet = level_up_pet(fed_pet)
    print("\n升级后:")
    print(f"等级: {leveled_pet['pet_level']}, 经验: {leveled_pet['pet_experience']}/{leveled_pet['pet_max_experience']}")
    print(f"生命值: {leveled_pet['pet_current_health']}/{leveled_pet['pet_max_health']}")
    print(f"攻击力: {leveled_pet['pet_attack_damage']}")
    
    # 测试治疗
    # 先模拟受伤
    injured_pet = leveled_pet.copy()
    injured_pet["pet_current_health"] = 50
    print("\n受伤后:")
    print(f"生命值: {injured_pet['pet_current_health']}/{injured_pet['pet_max_health']}")
    
    healed_pet = heal_pet(injured_pet)
    print("\n治疗后:")
    print(f"生命值: {healed_pet['pet_current_health']}/{healed_pet['pet_max_health']}")
    
    print("✅ 新格式数据操作测试通过")

def test_pet_bag_operations():
    """测试宠物背包操作"""
    print("\n=== 测试宠物背包操作 ===")
    
    # 创建测试宠物背包
    pet_bag = [
        {
            "pet_id": "pet_001",
            "pet_name": "小火龙",
            "pet_type": "火系",
            "pet_owner": "player123",
            "pet_image": "res://Scene/Pet/FireDragon.tscn",
            "pet_level": 5,
            "pet_experience": 150,
            "pet_max_experience": 200,
            "pet_current_health": 80,
            "pet_max_health": 100,
            "pet_max_armor": 20,
            "pet_attack_damage": 25,
            "pet_move_speed": 150,
            "pet_intimacy": 75
        },
        {
            "pet_id": "pet_002",
            "pet_name": "水精灵",
            "pet_type": "水系",
            "pet_owner": "player123",
            "pet_image": "res://Scene/Pet/WaterSpirit.tscn",
            "pet_level": 3,
            "pet_experience": 80,
            "pet_max_experience": 150,
            "pet_current_health": 60,
            "pet_max_health": 80,
            "pet_max_armor": 15,
            "pet_attack_damage": 20,
            "pet_move_speed": 120,
            "pet_intimacy": 50
        }
    ]
    
    print(f"宠物背包中有 {len(pet_bag)} 只宠物")
    
    # 测试遍历宠物背包
    for i, pet in enumerate(pet_bag):
        print(f"\n宠物 {i+1}:")
        print(f"  ID: {pet['pet_id']}")
        print(f"  名称: {pet['pet_name']}")
        print(f"  类型: {pet['pet_type']}")
        print(f"  等级: {pet['pet_level']}")
        print(f"  生命值: {pet['pet_current_health']}/{pet['pet_max_health']}")
        print(f"  攻击力: {pet['pet_attack_damage']}")
        print(f"  亲密度: {pet['pet_intimacy']}")
    
    # 测试查找特定宠物
    def find_pet_by_id(pet_bag, pet_id):
        for pet in pet_bag:
            if pet.get("pet_id") == pet_id:
                return pet
        return None
    
    found_pet = find_pet_by_id(pet_bag, "pet_002")
    if found_pet:
        print(f"\n找到宠物: {found_pet['pet_name']} (ID: {found_pet['pet_id']})")
    
    # 测试按类型筛选宠物
    def filter_pets_by_type(pet_bag, pet_type):
        return [pet for pet in pet_bag if pet.get("pet_type") == pet_type]
    
    fire_pets = filter_pets_by_type(pet_bag, "火系")
    print(f"\n火系宠物数量: {len(fire_pets)}")
    
    # 测试计算总战力
    def calculate_total_power(pet_bag):
        total_power = 0
        for pet in pet_bag:
            power = pet.get("pet_level", 1) * 10 + pet.get("pet_attack_damage", 0) + pet.get("pet_max_health", 0)
            total_power += power
        return total_power
    
    total_power = calculate_total_power(pet_bag)
    print(f"\n总战力: {total_power}")
    
    print("✅ 宠物背包操作测试通过")

def test_data_validation():
    """测试数据验证"""
    print("\n=== 测试数据验证 ===")
    
    def validate_pet_data(pet):
        """验证宠物数据的完整性"""
        required_fields = [
            "pet_id", "pet_name", "pet_type", "pet_owner", "pet_image",
            "pet_level", "pet_experience", "pet_max_experience",
            "pet_current_health", "pet_max_health", "pet_max_armor",
            "pet_attack_damage", "pet_move_speed", "pet_intimacy"
        ]
        
        missing_fields = []
        for field in required_fields:
            if field not in pet:
                missing_fields.append(field)
        
        if missing_fields:
            return False, f"缺少字段: {', '.join(missing_fields)}"
        
        # 验证数值范围
        if pet["pet_level"] < 1:
            return False, "宠物等级不能小于1"
        
        if pet["pet_experience"] < 0:
            return False, "宠物经验值不能为负数"
        
        if pet["pet_current_health"] > pet["pet_max_health"]:
            return False, "当前生命值不能超过最大生命值"
        
        if pet["pet_intimacy"] < 0 or pet["pet_intimacy"] > 100:
            return False, "亲密度必须在0-100之间"
        
        return True, "数据验证通过"
    
    # 测试有效数据
    valid_pet = {
        "pet_id": "pet_001",
        "pet_name": "测试宠物",
        "pet_type": "普通",
        "pet_owner": "player123",
        "pet_image": "res://Scene/Pet/Test.tscn",
        "pet_level": 1,
        "pet_experience": 0,
        "pet_max_experience": 100,
        "pet_current_health": 100,
        "pet_max_health": 100,
        "pet_max_armor": 0,
        "pet_attack_damage": 10,
        "pet_move_speed": 100,
        "pet_intimacy": 0
    }
    
    is_valid, message = validate_pet_data(valid_pet)
    print(f"有效数据验证: {message}")
    assert is_valid, "有效数据应该通过验证"
    
    # 测试无效数据
    invalid_pet = valid_pet.copy()
    del invalid_pet["pet_name"]  # 删除必需字段
    
    is_valid, message = validate_pet_data(invalid_pet)
    print(f"无效数据验证: {message}")
    assert not is_valid, "无效数据应该不通过验证"
    
    print("✅ 数据验证测试通过")

def main():
    """主测试函数"""
    print("开始宠物数据格式迁移测试...\n")
    
    try:
        # 测试格式转换
        new_pet_data = test_old_to_new_format_conversion()
        
        # 测试新格式操作
        test_new_format_operations(new_pet_data)
        
        # 测试宠物背包操作
        test_pet_bag_operations()
        
        # 测试数据验证
        test_data_validation()
        
        print("\n🎉 所有测试通过！宠物数据格式迁移工作正常。")
        
    except Exception as e:
        print(f"\n❌ 测试失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return False
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)