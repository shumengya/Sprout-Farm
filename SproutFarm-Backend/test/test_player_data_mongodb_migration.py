#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
玩家数据MongoDB迁移测试脚本
作者: AI Assistant
功能: 测试玩家数据从JSON文件到MongoDB的迁移和操作功能
"""

import json
import sys
import os
import time
from SMYMongoDBAPI import SMYMongoDBAPI

def test_player_data_operations():
    """测试玩家数据操作"""
    print("=== 玩家数据MongoDB操作测试 ===")
    
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
    
    # 2. 测试获取玩家数据
    print("\n2. 测试获取玩家数据...")
    test_accounts = ["2143323382", "2804775686", "3205788256"]
    
    for account_id in test_accounts:
        try:
            player_data = api.get_player_data(account_id)
            if player_data:
                print(f"✅ 成功获取玩家 {account_id} 的数据")
                print(f"   昵称: {player_data.get('玩家昵称', 'N/A')}")
                print(f"   等级: {player_data.get('等级', 'N/A')}")
                print(f"   金币: {player_data.get('钱币', 'N/A')}")
                print(f"   农场土地数量: {len(player_data.get('农场土地', []))}")
            else:
                print(f"⚠️ 未找到玩家 {account_id} 的数据")
        except Exception as e:
            print(f"❌ 获取玩家 {account_id} 数据时异常: {e}")
    
    # 3. 测试获取所有玩家基本信息
    print("\n3. 测试获取所有玩家基本信息...")
    try:
        players_info = api.get_all_players_basic_info()
        print(f"✅ 成功获取 {len(players_info)} 个玩家的基本信息")
        
        for i, player in enumerate(players_info[:3]):  # 只显示前3个
            print(f"   玩家{i+1}: {player.get('玩家账号')} - {player.get('玩家昵称')} (等级{player.get('等级')})")
        
        if len(players_info) > 3:
            print(f"   ... 还有 {len(players_info) - 3} 个玩家")
            
    except Exception as e:
        print(f"❌ 获取玩家基本信息时异常: {e}")
    
    # 4. 测试统计玩家总数
    print("\n4. 测试统计玩家总数...")
    try:
        total_count = api.count_total_players()
        print(f"✅ 玩家总数: {total_count}")
    except Exception as e:
        print(f"❌ 统计玩家总数时异常: {e}")
    
    # 5. 测试获取离线玩家
    print("\n5. 测试获取离线玩家...")
    try:
        offline_players = api.get_offline_players(offline_days=1)  # 1天内未登录
        print(f"✅ 找到 {len(offline_players)} 个离线超过1天的玩家")
        
        for player in offline_players[:3]:  # 只显示前3个
            account_id = player.get('玩家账号')
            last_login = player.get('最后登录时间', 'N/A')
            print(f"   {account_id}: 最后登录 {last_login}")
            
    except Exception as e:
        print(f"❌ 获取离线玩家时异常: {e}")
    
    # 6. 测试更新玩家字段
    print("\n6. 测试更新玩家字段...")
    if test_accounts:
        test_account = test_accounts[0]
        try:
            # 更新测试字段
            update_fields = {
                "测试字段": f"测试时间_{int(time.time())}",
                "测试更新": True
            }
            
            success = api.update_player_field(test_account, update_fields)
            if success:
                print(f"✅ 成功更新玩家 {test_account} 的字段")
                
                # 验证更新
                updated_data = api.get_player_data(test_account)
                if updated_data and "测试字段" in updated_data:
                    print(f"   验证成功: 测试字段 = {updated_data['测试字段']}")
                else:
                    print("⚠️ 更新验证失败")
            else:
                print(f"❌ 更新玩家 {test_account} 字段失败")
                
        except Exception as e:
            print(f"❌ 更新玩家字段时异常: {e}")
    
    # 7. 测试条件查询
    print("\n7. 测试条件查询...")
    try:
        # 查询等级大于等于5的玩家
        condition = {"等级": {"$gte": 5}}
        projection = {"玩家账号": 1, "玩家昵称": 1, "等级": 1, "钱币": 1}
        
        high_level_players = api.get_players_by_condition(condition, projection, limit=5)
        print(f"✅ 找到 {len(high_level_players)} 个等级≥5的玩家")
        
        for player in high_level_players:
            print(f"   {player.get('玩家账号')}: {player.get('玩家昵称')} (等级{player.get('等级')}, 金币{player.get('钱币')})")
            
    except Exception as e:
        print(f"❌ 条件查询时异常: {e}")
    
    # 8. 性能测试
    print("\n8. 性能测试...")
    try:
        start_time = time.time()
        
        # 批量获取玩家基本信息
        players_info = api.get_all_players_basic_info()
        
        end_time = time.time()
        duration = end_time - start_time
        
        print(f"✅ 获取 {len(players_info)} 个玩家基本信息耗时: {duration:.3f} 秒")
        
        if duration < 1.0:
            print("   性能良好 ✅")
        elif duration < 3.0:
            print("   性能一般 ⚠️")
        else:
            print("   性能较差，建议优化 ❌")
            
    except Exception as e:
        print(f"❌ 性能测试时异常: {e}")
    
    print("\n=== 测试完成 ===")
    return True

def test_compatibility_with_file_system():
    """测试与文件系统的兼容性"""
    print("\n=== 文件系统兼容性测试 ===")
    
    try:
        # 模拟服务器环境
        from TCPGameServer import TCPGameServer
        
        # 创建服务器实例（不启动网络服务）
        server = TCPGameServer()
        
        # 测试加载玩家数据
        test_account = "2143323382"
        
        print(f"\n测试加载玩家数据: {test_account}")
        player_data = server.load_player_data(test_account)
        
        if player_data:
            print("✅ 成功加载玩家数据")
            print(f"   数据源: {'MongoDB' if server.use_mongodb else '文件系统'}")
            print(f"   玩家昵称: {player_data.get('玩家昵称', 'N/A')}")
            print(f"   等级: {player_data.get('等级', 'N/A')}")
            
            # 测试保存玩家数据
            print("\n测试保存玩家数据...")
            player_data["测试兼容性"] = f"测试时间_{int(time.time())}"
            
            success = server.save_player_data(test_account, player_data)
            if success:
                print("✅ 成功保存玩家数据")
                
                # 验证保存
                reloaded_data = server.load_player_data(test_account)
                if reloaded_data and "测试兼容性" in reloaded_data:
                    print("✅ 保存验证成功")
                else:
                    print("❌ 保存验证失败")
            else:
                print("❌ 保存玩家数据失败")
        else:
            print("❌ 加载玩家数据失败")
            
    except Exception as e:
        print(f"❌ 兼容性测试异常: {e}")
        import traceback
        traceback.print_exc()

def main():
    """主函数"""
    try:
        # 基本操作测试
        test_player_data_operations()
        
        # 兼容性测试
        test_compatibility_with_file_system()
        
    except KeyboardInterrupt:
        print("\n测试被用户中断")
    except Exception as e:
        print(f"测试过程中发生异常: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()