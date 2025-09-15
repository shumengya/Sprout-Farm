#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
游戏小提示配置数据导入脚本
将游戏小提示配置数据导入到MongoDB数据库中
"""

import sys
import os

# 添加当前目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from SMYMongoDBAPI import SMYMongoDBAPI

def import_game_tips_config():
    """导入游戏小提示配置数据到MongoDB"""
    
    # 游戏小提示配置数据
    game_tips_config = {
        "切换模式": "顺序",  # 可选：顺序，随机，倒序
        "切换速度": 5,
        "游戏小提示": [
            "按住wsad可以移动游戏画面",
            "使用鼠标滚轮来缩放游戏画面",
            "移动端双指缩放游戏画面",
            "不要一上来就花光你的初始资金",
            "钱币是目前游戏唯一货币",
            "每隔一小时体力值+1",
            "不要忘记领取你的新手礼包！",
            "记得使用一键截图来分享你的农场",
            "新注册用户可享受三天10倍速作物生长",
            "偷别人菜时不要忘了给别人浇水哦",
            "你能分得清小麦和稻谷吗",
            "凌晨刷新体力值",
            "面板左上角有刷新按钮，可以刷新面板",
            "小心偷菜被巡逻宠物发现",
            "访问特殊农场来获得一些特殊的作物"
        ]
    }
    
    try:
        # 创建MongoDB API实例
        mongo_api = SMYMongoDBAPI()
        
        # 连接到数据库
        if not mongo_api.connect():
            print("错误：无法连接到MongoDB数据库")
            return False
        
        print("成功连接到MongoDB数据库")
        
        # 更新游戏小提示配置
        result = mongo_api.update_game_tips_config(game_tips_config)
        
        if result:
            print("成功导入游戏小提示配置数据到MongoDB")
            print(f"配置内容：")
            print(f"  切换模式: {game_tips_config['切换模式']}")
            print(f"  切换速度: {game_tips_config['切换速度']}")
            print(f"  游戏小提示数量: {len(game_tips_config['游戏小提示'])}")
            return True
        else:
            print("错误：导入游戏小提示配置数据失败")
            return False
            
    except Exception as e:
        print(f"导入过程中发生错误: {str(e)}")
        return False
    finally:
        # 断开数据库连接
        if 'mongo_api' in locals():
            mongo_api.disconnect()
            print("已断开MongoDB数据库连接")

if __name__ == "__main__":
    print("开始导入游戏小提示配置数据...")
    success = import_game_tips_config()
    
    if success:
        print("\n导入完成！")
    else:
        print("\n导入失败！")
        sys.exit(1)