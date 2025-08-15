#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
萌芽农场服务器控制台命令演示
展示各种控制台命令的使用方法和效果
"""

def show_console_demo():
    """展示控制台命令使用示例"""
    print("🌱 萌芽农场服务器控制台命令演示")
    print("=" * 60)
    
    print("\n📋 可用命令列表:")
    commands = [
        ("help", "显示帮助信息"),
        ("lsplayer", "列出所有已注册玩家"),
        ("playerinfo <QQ号>", "查看玩家详细信息"),
        ("addmoney <QQ号> <数量>", "为玩家添加金币"),
        ("addxp <QQ号> <数量>", "为玩家添加经验"),
        ("addlevel <QQ号> <数量>", "为玩家添加等级"),
        ("addseed <QQ号> <作物> <数量>", "为玩家添加种子"),
        ("resetland <QQ号>", "重置玩家土地状态"),
        ("save", "立即保存所有数据"),
        ("reload", "重新加载配置"),
        ("stop", "停止服务器")
    ]
    
    for cmd, desc in commands:
        print(f"  {cmd:<30} - {desc}")
    
    print("\n" + "=" * 60)
    print("🎯 使用示例:")
    
    examples = [
        {
            "title": "查看玩家信息",
            "commands": [
                "lsplayer",
                "playerinfo 2143323382"
            ],
            "description": "首先列出所有玩家，然后查看特定玩家的详细信息"
        },
        {
            "title": "发放新手福利",
            "commands": [
                "addmoney 2143323382 5000",
                "addxp 2143323382 1000", 
                "addseed 2143323382 番茄 50",
                "addseed 2143323382 胡萝卜 30"
            ],
            "description": "为新玩家发放启动资金、经验和种子"
        },
        {
            "title": "活动奖励发放",
            "commands": [
                "addlevel 2143323382 3",
                "addmoney 2143323382 10000",
                "addseed 2143323382 龙果 5"
            ],
            "description": "为参与活动的玩家发放等级、金币和稀有种子奖励"
        },
        {
            "title": "问题处理",
            "commands": [
                "playerinfo 2143323382",
                "resetland 2143323382",
                "save"
            ],
            "description": "查看玩家状态，重置有问题的土地，保存数据"
        }
    ]
    
    for i, example in enumerate(examples, 1):
        print(f"\n{i}. {example['title']}")
        print(f"   说明: {example['description']}")
        print("   命令序列:")
        for cmd in example['commands']:
            print(f"   > {cmd}")
    
    print("\n" + "=" * 60)
    print("⚠️  注意事项:")
    notices = [
        "命令前的斜杠(/)是可选的，'addmoney' 和 '/addmoney' 效果相同",
        "QQ号必须是已注册的玩家账号",
        "数量参数必须是正整数",
        "作物名称必须在游戏配置中存在",
        "resetland 命令会清除玩家所有农场进度，请谨慎使用",
        "对在线玩家的修改会立即生效并推送到客户端",
        "所有修改都会自动保存到磁盘"
    ]
    
    for notice in notices:
        print(f"  • {notice}")
    
    print("\n" + "=" * 60)
    print("🔧 常见作物名称参考:")
    crops = [
        "基础作物: 小麦、胡萝卜、土豆、稻谷、玉米、番茄",
        "花卉类: 玫瑰花、向日葵、郁金香、百合花、康乃馨",
        "水果类: 草莓、蓝莓、苹果、香蕉、橘子、葡萄、西瓜",
        "高级作物: 人参、藏红花、松露、龙果、冬虫夏草",
        "特殊作物: 摇钱树、糖果树、月光草、凤凰木"
    ]
    
    for crop_group in crops:
        print(f"  • {crop_group}")
    
    print("\n" + "=" * 60)
    print("🚀 快速开始:")
    print("1. 启动服务器: python TCPGameServer.py")
    print("2. 等待看到控制台提示符: >")
    print("3. 输入命令，例如: help")
    print("4. 查看命令执行结果")
    print("5. 继续输入其他命令进行管理")
    
    print("\n💡 提示: 输入 'help' 可以随时查看完整的命令帮助信息")
    print("=" * 60)

if __name__ == "__main__":
    show_console_demo() 