#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
更新已存在玩家的注册时间为默认值的脚本
用于确保所有已存在的玩家都有默认的注册时间，不会享受新玩家奖励
"""

import os
import json
import datetime

def update_existing_players_register_time():
    """更新所有已存在玩家的注册时间为默认值"""
    default_register_time = "2025年05月21日15时00分00秒"
    game_saves_dir = "game_saves"
    
    if not os.path.exists(game_saves_dir):
        print("游戏存档目录不存在:", game_saves_dir)
        return
    
    updated_count = 0
    error_count = 0
    total_files = 0
    
    # 获取所有玩家存档文件
    for filename in os.listdir(game_saves_dir):
        if filename.endswith('.json'):
            total_files += 1
            file_path = os.path.join(game_saves_dir, filename)
            
            try:
                # 读取玩家数据
                with open(file_path, 'r', encoding='utf-8') as file:
                    player_data = json.load(file)
                
                # 检查是否需要更新注册时间
                current_register_time = player_data.get("注册时间", "")
                
                # 如果没有注册时间字段，或者不是默认值，则设置为默认值
                if not current_register_time:
                    player_data["注册时间"] = default_register_time
                    print(f"为玩家 {filename} 添加注册时间字段")
                    updated_count += 1
                elif current_register_time != default_register_time:
                    # 如果注册时间不是默认值，说明是新注册的玩家，保持不变
                    print(f"玩家 {filename} 注册时间: {current_register_time} (保持不变)")
                    continue
                else:
                    # 注册时间已经是默认值，无需更新
                    print(f"玩家 {filename} 注册时间已是默认值")
                    continue
                
                # 保存更新后的数据
                with open(file_path, 'w', encoding='utf-8') as file:
                    json.dump(player_data, file, indent=2, ensure_ascii=False)
                
            except Exception as e:
                print(f"处理文件 {filename} 时出错: {str(e)}")
                error_count += 1
    
    print(f"\n更新完成!")
    print(f"总文件数: {total_files}")
    print(f"已更新: {updated_count}")
    print(f"错误: {error_count}")
    print(f"默认注册时间: {default_register_time}")

if __name__ == "__main__":
    print("开始更新已存在玩家的注册时间...")
    update_existing_players_register_time()
    print("脚本执行完成!") 