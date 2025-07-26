#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
萌芽农场服务器控制台命令API模块
作者: AI Assistant
功能: 提供服务器控制台命令处理功能
"""

import os
import json
import sys
from typing import Dict, Any, List, Optional
from datetime import datetime
from SMYMongoDBAPI import SMYMongoDBAPI

class ConsoleCommandsAPI:
    """控制台命令处理类"""
    
    def __init__(self, server):
        """
        初始化控制台命令API
        
        Args:
            server: 游戏服务器实例
        """
        self.server = server
        self.commands = {
            "addmoney": self.cmd_add_money, # 给玩家添加金币
            "addxp": self.cmd_add_experience, # 给玩家添加经验值
            "addlevel": self.cmd_add_level, # 给玩家添加等级
            "addseed": self.cmd_add_seed, # 给玩家添加种子
            "lsplayer": self.cmd_list_players, # 列出所有玩家
            "playerinfo": self.cmd_player_info, # 查看玩家信息
            "resetland": self.cmd_reset_land, # 重置玩家土地
            "weather": self.cmd_weather, # 设置天气
            "help": self.cmd_help, # 显示帮助信息
            "stop": self.cmd_stop, # 停止服务器
            "save": self.cmd_save_all, # 保存所有玩家数据
            "reload": self.cmd_reload_config, # 重新加载配置文件
            # MongoDB管理命令
            "dbtest": self.cmd_db_test, # 测试MongoDB连接
            "dbconfig": self.cmd_db_config, # 配置MongoDB连接
            "dbchat": self.cmd_db_chat, # 管理聊天数据
            "dbclean": self.cmd_db_clean, # 清理数据库
            "dbbackup": self.cmd_db_backup # 备份数据库
        }
        
        # 初始化MongoDB API
        self.mongo_api = None
        self._init_mongodb_api()
    
    def process_command(self, command_line: str) -> bool:
        """
        处理控制台命令
        
        Args:
            command_line: 命令行字符串
            
        Returns:
            bool: 命令是否执行成功
        """
        if not command_line.strip():
            return False
            
        parts = command_line.strip().split()
        if not parts:
            return False
            
        # 移除命令前的斜杠（如果有）
        command = parts[0].lstrip('/')
        args = parts[1:] if len(parts) > 1 else []
        
        if command in self.commands:
            try:
                self.commands[command](args)
                return True
            except Exception as e:
                print(f"❌ 执行命令 '{command}' 时出错: {str(e)}")
                return False
        else:
            print(f"❌ 未知命令: {command}")
            print("💡 输入 'help' 查看可用命令")
            return False
    
    def get_available_commands(self) -> List[str]:
        """
        获取可用命令列表
        
        Returns:
            List[str]: 可用命令列表
        """
        return list(self.commands.keys())
    
    def cmd_add_money(self, args: List[str]):
        """添加金币命令: /addmoney QQ号 数量"""
        if len(args) != 2:
            print("❌ 用法: /addmoney <QQ号> <数量>")
            return
            
        qq_number, amount_str = args
        try:
            amount = int(amount_str)
        except ValueError:
            print("❌ 金币数量必须是整数")
            return
            
        # 加载玩家数据
        player_data = self.server.load_player_data(qq_number)
        if not player_data:
            print(f"❌ 玩家 {qq_number} 不存在")
            return
            
        # 修改金币
        old_money = player_data.get("钱币", 0)
        player_data["钱币"] = old_money + amount
        
        # 保存数据
        self.server.save_player_data(qq_number, player_data)
        
        print(f"✅ 已为玩家 {qq_number} 添加 {amount} 金币")
        print(f"   原金币: {old_money} → 新金币: {player_data['钱币']}")
    
    def cmd_add_experience(self, args: List[str]):
        """添加经验命令: /addxp QQ号 数量"""
        if len(args) != 2:
            print("❌ 用法: /addxp <QQ号> <数量>")
            return
            
        qq_number, amount_str = args
        try:
            amount = int(amount_str)
        except ValueError:
            print("❌ 经验数量必须是整数")
            return
            
        # 加载玩家数据
        player_data = self.server.load_player_data(qq_number)
        if not player_data:
            print(f"❌ 玩家 {qq_number} 不存在")
            return
            
        # 修改经验
        old_exp = player_data.get("经验值", 0)
        player_data["经验值"] = old_exp + amount
        
        # 检查是否升级
        old_level = player_data.get("等级", 1)
        self.server._check_level_up(player_data)
        new_level = player_data.get("等级", 1)
        
        # 保存数据
        self.server.save_player_data(qq_number, player_data)
        
        print(f"✅ 已为玩家 {qq_number} 添加 {amount} 经验")
        print(f"   原经验: {old_exp} → 新经验: {player_data['经验值']}")
        if new_level > old_level:
            print(f"🎉 玩家升级了! {old_level} → {new_level}")
    
    def cmd_add_level(self, args: List[str]):
        """添加等级命令: /addlevel QQ号 数量"""
        if len(args) != 2:
            print("❌ 用法: /addlevel <QQ号> <数量>")
            return
            
        qq_number, amount_str = args
        try:
            amount = int(amount_str)
        except ValueError:
            print("❌ 等级数量必须是整数")
            return
            
        # 加载玩家数据
        player_data = self.server.load_player_data(qq_number)
        if not player_data:
            print(f"❌ 玩家 {qq_number} 不存在")
            return
            
        # 修改等级
        old_level = player_data.get("等级", 1)
        new_level = max(1, old_level + amount)  # 确保等级不小于1
        player_data["等级"] = new_level
        
        # 保存数据
        self.server.save_player_data(qq_number, player_data)
        
        print(f"✅ 已为玩家 {qq_number} 添加 {amount} 等级")
        print(f"   原等级: {old_level} → 新等级: {new_level}")
    
    def cmd_add_seed(self, args: List[str]):
        """添加种子命令: /addseed QQ号 作物名称 数量"""
        if len(args) != 3:
            print("❌ 用法: /addseed <QQ号> <作物名称> <数量>")
            return
            
        qq_number, crop_name, amount_str = args
        try:
            amount = int(amount_str)
        except ValueError:
            print("❌ 种子数量必须是整数")
            return
            
        # 加载玩家数据
        player_data = self.server.load_player_data(qq_number)
        if not player_data:
            print(f"❌ 玩家 {qq_number} 不存在")
            return
            
        # 检查作物是否存在
        crop_data = self.server._load_crop_data()
        if crop_name not in crop_data:
            print(f"❌ 作物 '{crop_name}' 不存在")
            print(f"💡 可用作物: {', '.join(list(crop_data.keys())[:10])}...")
            return
            
        # 添加种子到背包
        if "seeds" not in player_data:
            player_data["seeds"] = {}
            
        old_count = player_data["seeds"].get(crop_name, 0)
        player_data["seeds"][crop_name] = old_count + amount
        
        # 保存数据
        self.server.save_player_data(qq_number, player_data)
        
        print(f"✅ 已为玩家 {qq_number} 添加 {amount} 个 {crop_name} 种子")
        print(f"   原数量: {old_count} → 新数量: {player_data['seeds'][crop_name]}")
    
    def cmd_list_players(self, args: List[str]):
        """列出所有玩家命令: /lsplayer"""
        try:
            # 使用MongoDB获取玩家数据
            if hasattr(self.server, 'mongo_api') and self.server.mongo_api:
                players_data = self.server.mongo_api.get_all_players_basic_info()
                
                if not players_data:
                    print("📭 暂无已注册玩家")
                    return
                
                print(f"📋 已注册玩家列表 (共 {len(players_data)} 人):")
                print("-" * 80)
                print(f"{'QQ号':<12} {'昵称':<15} {'等级':<6} {'金币':<10} {'最后登录':<20}")
                print("-" * 80)
                
                for player in players_data:
                    qq_number = player.get("玩家账号", "未知")
                    nickname = player.get("玩家昵称", "未设置")
                    level = player.get("等级", 1)
                    money = player.get("钱币", 0)
                    last_login = player.get("最后登录时间", "从未登录")
                    
                    print(f"{qq_number:<12} {nickname:<15} {level:<6} {money:<10} {last_login:<20}")
                
                print("-" * 80)
            else:
                print("❌ 未配置MongoDB连接")
                
        except Exception as e:
            print(f"❌ 列出玩家时出错: {str(e)}")
    
    
    def cmd_player_info(self, args: List[str]):
        """查看玩家信息命令: /playerinfo QQ号"""
        if len(args) != 1:
            print("❌ 用法: /playerinfo <QQ号>")
            return
            
        qq_number = args[0]
        player_data = self.server.load_player_data(qq_number)
        if not player_data:
            print(f"❌ 玩家 {qq_number} 不存在")
            return
            
        print(f"👤 玩家信息: {qq_number}")
        print("=" * 50)
        print(f"昵称: {player_data.get('玩家昵称', '未设置')}")
        print(f"农场名: {player_data.get('农场名称', '未设置')}")
        print(f"等级: {player_data.get('等级', 1)}")
        print(f"经验: {player_data.get('经验值', 0)}")
        print(f"金币: {player_data.get('钱币', 0)}")
        print(f"体力: {player_data.get('体力值', 20)}")
        print(f"注册时间: {player_data.get('注册时间', '未知')}")
        print(f"最后登录: {player_data.get('最后登录时间', '从未登录')}")
        print(f"总在线时长: {player_data.get('总游玩时间', '0时0分0秒')}")
        
        # 显示土地信息
        farm_lots = player_data.get("农场土地", [])
        planted_count = sum(1 for lot in farm_lots if lot.get("is_planted", False))
        digged_count = sum(1 for lot in farm_lots if lot.get("is_diged", False))
        print(f"土地状态: 总共{len(farm_lots)}块，已开垦{digged_count}块，已种植{planted_count}块")
        
        # 显示种子信息
        seeds = player_data.get("seeds", {})
        if seeds:
            print(f"种子背包: {len(seeds)}种作物，总计{sum(seeds.values())}个种子")
        else:
            print("种子背包: 空")
            
        print("=" * 50)
    
    def cmd_reset_land(self, args: List[str]):
        """重置玩家土地命令: /resetland QQ号"""
        if len(args) != 1:
            print("❌ 用法: /resetland <QQ号>")
            return
            
        qq_number = args[0]
        player_data = self.server.load_player_data(qq_number)
        if not player_data:
            print(f"❌ 玩家 {qq_number} 不存在")
            return
            
        # 加载初始化模板（优先从MongoDB）
        template_data = None
        if hasattr(self.server, 'use_mongodb') and self.server.use_mongodb and hasattr(self.server, 'mongo_api') and self.server.mongo_api:
            try:
                template_data = self.server.mongo_api.get_initial_player_data_template()
                if template_data:
                    print("✅ 成功从MongoDB加载初始玩家数据模板")
                else:
                    print("⚠️ MongoDB中未找到初始玩家数据模板，尝试从JSON文件加载")
            except Exception as e:
                print(f"⚠️ 从MongoDB加载初始玩家数据模板失败: {str(e)}，尝试从JSON文件加载")
        
        # MongoDB加载失败或不可用，从JSON文件加载
        if not template_data:
            try:
                with open("config/initial_player_data_template.json", 'r', encoding='utf-8') as f:
                    template_data = json.load(f)
                print("✅ 成功从JSON文件加载初始玩家数据模板")
            except Exception as e:
                print(f"❌ 无法加载初始化模板: {str(e)}")
                return
            
        # 重置土地状态
        if "农场土地" in template_data:
            old_lots_count = len(player_data.get("农场土地", []))
            player_data["农场土地"] = template_data["农场土地"]
            new_lots_count = len(player_data["农场土地"])
            
            # 保存数据
            self.server.save_player_data(qq_number, player_data)
            
            print(f"✅ 已重置玩家 {qq_number} 的土地状态")
            print(f"   土地数量: {old_lots_count} → {new_lots_count}")
            print(f"   所有作物和状态已清除，恢复为初始状态")
        else:
            print("❌ 初始化模板中没有找到土地数据")
    
    def cmd_weather(self, args: List[str]):
        """天气控制命令: /weather <天气类型>"""
        if len(args) != 1:
            print("❌ 用法: /weather <天气类型>")
            print("   可用天气: clear, rain, snow, cherry, gardenia, willow")
            return
            
        weather_type = args[0].lower()
        
        # 定义可用的天气类型映射
        weather_map = {
            "clear": "晴天",
            "rain": "下雨", 
            "snow": "下雪",
            "cherry": "樱花雨",
            "gardenia": "栀子花雨", 
            "willow": "柳叶雨",
            "stop": "停止天气"
        }
        
        if weather_type not in weather_map:
            print("❌ 无效的天气类型")
            print("   可用天气: clear, rain, snow, cherry, gardenia, willow, stop")
            return
            
        # 广播天气变更消息给所有在线客户端
        weather_message = {
            "type": "weather_change",
            "weather_type": weather_type,
            "weather_name": weather_map[weather_type]
        }
        
        # 发送给所有连接的客户端
        if hasattr(self.server, 'clients'):
            for client_id in list(self.server.clients.keys()):
                try:
                    self.server.send_data(client_id, weather_message)
                except Exception as e:
                    print(f"⚠️  向客户端 {client_id} 发送天气消息失败: {str(e)}")
        
        print(f"🌤️  已将天气切换为: {weather_map[weather_type]}")
        if hasattr(self.server, 'clients') and len(self.server.clients) > 0:
            print(f"   已通知 {len(self.server.clients)} 个在线客户端")
        else:
            print("   当前无在线客户端")
    
    def cmd_help(self, args: List[str]):
        """显示帮助信息"""
        print("🌱 萌芽农场服务器控制台命令帮助")
        print("=" * 60)
        print("玩家管理命令:")
        print("  /addmoney <QQ号> <数量>     - 为玩家添加金币")
        print("  /addxp <QQ号> <数量>        - 为玩家添加经验")
        print("  /addlevel <QQ号> <数量>     - 为玩家添加等级")
        print("  /addseed <QQ号> <作物> <数量> - 为玩家添加种子")
        print("  /lsplayer                   - 列出所有已注册玩家")
        print("  /playerinfo <QQ号>          - 查看玩家详细信息")
        print("  /resetland <QQ号>           - 重置玩家土地状态")
        print("")
        print("游戏控制命令:")
        print("  /weather <类型>             - 控制全服天气")
        print("     可用类型: clear, rain, snow, cherry, gardenia, willow, stop")
        print("")
        print("服务器管理命令:")
        print("  /save                       - 立即保存所有玩家数据")
        print("  /reload                     - 重新加载配置文件")
        print("  /stop                       - 停止服务器")
        print("  /help                       - 显示此帮助信息")
        print("=" * 60)
        print("💡 提示: 命令前的斜杠(/)是可选的")
        print("")
        print("数据库管理命令:")
        print("  /dbtest                     - 测试数据库连接")
        print("  /dbconfig <操作> [参数]     - 数据库配置管理")
        print("  /dbchat <操作> [参数]       - 聊天消息管理")
        print("  /dbclean <类型>             - 数据库清理")
        print("  /dbbackup [类型]            - 数据库备份")
    
    def cmd_save_all(self, args: List[str]):
        """保存所有数据命令"""
        try:
            # 保存所有在线玩家数据
            saved_count = 0
            if hasattr(self.server, 'user_data'):
                for client_id, user_info in self.server.user_data.items():
                    if user_info.get("logged_in", False):
                        username = user_info.get("username")
                        if username:
                            player_data = self.server.load_player_data(username)
                            if player_data:
                                self.server.save_player_data(username, player_data)
                                saved_count += 1
            print(f"✅ 已保存 {saved_count} 个在线玩家的数据")
        except Exception as e:
            print(f"❌ 保存数据时出错: {str(e)}")
    
    def cmd_reload_config(self, args: List[str]):
        """重新加载配置命令"""
        try:
            # 重新加载作物数据
            if hasattr(self.server, '_load_crop_data'):
                self.server._load_crop_data()
            print("✅ 已重新加载配置文件")
        except Exception as e:
            print(f"❌ 重新加载配置时出错: {str(e)}")
    
    def cmd_stop(self, args: List[str]):
        """停止服务器命令"""
        print("⚠️  正在停止服务器...")
        try:
            # 保存所有在线玩家数据
            if hasattr(self.server, 'user_data'):
                for client_id, user_info in self.server.user_data.items():
                    if user_info.get("logged_in", False):
                        username = user_info.get("username")
                        if username:
                            player_data = self.server.load_player_data(username)
                            if player_data:
                                self.server.save_player_data(username, player_data)
            print("💾 数据保存完成")
        except:
            pass
        
        if hasattr(self.server, 'stop'):
            self.server.stop()
        print("✅ 服务器已停止")
        sys.exit(0)
    
    def _init_mongodb_api(self):
        """初始化MongoDB API"""
        try:
            # 检查服务器是否使用MongoDB
            if hasattr(self.server, 'use_mongodb') and self.server.use_mongodb:
                environment = "production" if hasattr(self.server, 'environment') and self.server.environment == "production" else "test"
                self.mongo_api = SMYMongoDBAPI(environment)
                if self.mongo_api.is_connected():
                    print(f"✅ MongoDB API 初始化成功 [{environment}]")
                else:
                    print(f"⚠️ MongoDB API 连接失败 [{environment}]")
                    self.mongo_api = None
            else:
                print("💡 服务器未启用MongoDB，数据库命令将不可用")
        except Exception as e:
            print(f"❌ MongoDB API 初始化失败: {str(e)}")
            self.mongo_api = None
    
    # ========================= MongoDB管理命令 =========================
    
    def cmd_db_test(self, args):
        """测试数据库连接命令: /dbtest"""
        if not self.mongo_api:
            print("❌ MongoDB API 未初始化或连接失败")
            return
            
        try:
            if self.mongo_api.is_connected():
                # 测试基本操作
                config = self.mongo_api.get_daily_checkin_config()
                if config:
                    print("✅ 数据库连接正常，可以正常读取配置")
                    print(f"   环境: {self.mongo_api.environment}")
                    print(f"   数据库: {self.mongo_api.config[self.mongo_api.environment]['database']}")
                    print(f"   主机: {self.mongo_api.config[self.mongo_api.environment]['host']}:{self.mongo_api.config[self.mongo_api.environment]['port']}")
                else:
                    print("⚠️ 数据库连接正常，但无法读取配置数据")
            else:
                print("❌ 数据库连接失败")
        except Exception as e:
            print(f"❌ 数据库测试失败: {str(e)}")
    
    def cmd_db_config(self, args):
        """数据库配置管理命令: /dbconfig <操作> [参数]"""
        if not self.mongo_api:
            print("❌ MongoDB API 未初始化")
            return
            
        if len(args) == 0:
            print("❌ 用法: /dbconfig <操作> [参数]")
            print("   可用操作:")
            print("     list                    - 列出所有配置类型")
            print("     get <配置类型>          - 获取指定配置")
            print("     reload <配置类型>       - 重新加载指定配置到服务器")
            print("   配置类型: daily_checkin, lucky_draw, new_player, wisdom_tree, online_gift, scare_crow, item, pet, stamina, crop_data, initial_player_data")
            return
            
        operation = args[0].lower()
        
        if operation == "list":
            print("📋 可用的配置类型:")
            print("-" * 50)
            config_types = [
                ("daily_checkin", "每日签到配置"),
                ("lucky_draw", "幸运抽奖配置"),
                ("new_player", "新手大礼包配置"),
                ("wisdom_tree", "智慧树配置"),
                ("online_gift", "在线礼包配置"),
                ("scare_crow", "稻草人配置"),
                ("item", "道具配置"),
                ("pet", "宠物配置"),
                ("stamina", "体力系统配置"),
                ("crop_data", "作物数据配置"),
                ("initial_player_data", "初始玩家数据模板")
            ]
            for config_type, description in config_types:
                print(f"  {config_type:<20} - {description}")
            print("-" * 50)
            
        elif operation == "get":
            if len(args) < 2:
                print("❌ 用法: /dbconfig get <配置类型>")
                return
                
            config_type = args[1]
            try:
                config_methods = {
                    "daily_checkin": self.mongo_api.get_daily_checkin_config,
                    "lucky_draw": self.mongo_api.get_lucky_draw_config,
                    "new_player": self.mongo_api.get_new_player_config,
                    "wisdom_tree": self.mongo_api.get_wisdom_tree_config,
                    "online_gift": self.mongo_api.get_online_gift_config,
                    "scare_crow": self.mongo_api.get_scare_crow_config,
                    "item": self.mongo_api.get_item_config,
                    "pet": self.mongo_api.get_pet_config,
                    "stamina": self.mongo_api.get_stamina_config,
                    "crop_data": self.mongo_api.get_crop_data_config,
                    "initial_player_data": self.mongo_api.get_initial_player_data_template
                }
                
                if config_type not in config_methods:
                    print(f"❌ 未知的配置类型: {config_type}")
                    return
                    
                config = config_methods[config_type]()
                if config:
                    print(f"✅ {config_type} 配置:")
                    print(json.dumps(config, ensure_ascii=False, indent=2))
                else:
                    print(f"❌ 无法获取 {config_type} 配置")
                    
            except Exception as e:
                print(f"❌ 获取配置失败: {str(e)}")
                
        elif operation == "reload":
            if len(args) < 2:
                print("❌ 用法: /dbconfig reload <配置类型>")
                return
                
            config_type = args[1]
            print(f"🔄 正在重新加载 {config_type} 配置到服务器...")
            
            try:
                # 这里可以添加重新加载配置到服务器的逻辑
                # 例如重新加载作物数据等
                if config_type == "crop_data":
                    if hasattr(self.server, '_load_crop_data'):
                        self.server._load_crop_data()
                        print(f"✅ 已重新加载 {config_type} 配置到服务器")
                    else:
                        print(f"⚠️ 服务器不支持重新加载 {config_type} 配置")
                else:
                    print(f"💡 {config_type} 配置重新加载功能暂未实现")
                    
            except Exception as e:
                print(f"❌ 重新加载配置失败: {str(e)}")
                
        else:
            print(f"❌ 未知操作: {operation}")
    
    def cmd_db_chat(self, args):
        """聊天消息管理命令: /dbchat <操作> [参数]"""
        if not self.mongo_api:
            print("❌ MongoDB API 未初始化")
            return
            
        if len(args) == 0:
            print("❌ 用法: /dbchat <操作> [参数]")
            print("   可用操作:")
            print("     latest                  - 获取最新聊天消息")
            print("     history [天数] [数量]   - 获取聊天历史 (默认3天，最多500条)")
            print("     clean [保留天数]        - 清理旧聊天消息 (默认保留30天)")
            return
            
        operation = args[0].lower()
        
        if operation == "latest":
            try:
                message = self.mongo_api.get_latest_chat_message()
                if message:
                    print("💬 最新聊天消息:")
                    print(f"   玩家: {message.get('player_name', 'N/A')} (QQ: {message.get('username', 'N/A')})")
                    print(f"   内容: {message.get('content', '')}")
                    print(f"   时间: {message.get('time_str', 'N/A')}")
                else:
                    print("📭 暂无聊天消息")
            except Exception as e:
                print(f"❌ 获取最新聊天消息失败: {str(e)}")
                
        elif operation == "history":
            days = 3
            limit = 500
            
            if len(args) > 1:
                try:
                    days = int(args[1])
                except ValueError:
                    print("❌ 天数必须是整数")
                    return
                    
            if len(args) > 2:
                try:
                    limit = int(args[2])
                except ValueError:
                    print("❌ 数量必须是整数")
                    return
                    
            try:
                messages = self.mongo_api.get_chat_history(days, limit)
                if messages:
                    print(f"💬 聊天历史 (最近{days}天，共{len(messages)}条):")
                    print("-" * 80)
                    for msg in messages[-10:]:  # 只显示最后10条
                        print(f"[{msg.get('time_str', 'N/A')}] {msg.get('player_name', 'N/A')}: {msg.get('content', '')}")
                    if len(messages) > 10:
                        print(f"... 还有 {len(messages) - 10} 条历史消息")
                    print("-" * 80)
                else:
                    print("📭 暂无聊天历史")
            except Exception as e:
                print(f"❌ 获取聊天历史失败: {str(e)}")
                
        elif operation == "clean":
            keep_days = 30
            
            if len(args) > 1:
                try:
                    keep_days = int(args[1])
                except ValueError:
                    print("❌ 保留天数必须是整数")
                    return
                    
            try:
                deleted_count = self.mongo_api.clean_old_chat_messages(keep_days)
                print(f"🧹 清理完成: 删除了 {deleted_count} 个文档 ({keep_days}天前的消息)")
            except Exception as e:
                print(f"❌ 清理聊天消息失败: {str(e)}")
                
        else:
            print(f"❌ 未知操作: {operation}")
    
    def cmd_db_clean(self, args):
        """数据库清理命令: /dbclean <类型>"""
        if not self.mongo_api:
            print("❌ MongoDB API 未初始化")
            return
            
        if len(args) == 0:
            print("❌ 用法: /dbclean <类型>")
            print("   可用类型:")
            print("     codes                   - 清理过期验证码")
            print("     chat [保留天数]         - 清理旧聊天消息 (默认保留30天)")
            print("     all                     - 清理所有过期数据")
            return
            
        clean_type = args[0].lower()
        
        if clean_type == "codes":
            try:
                removed_count = self.mongo_api.clean_expired_verification_codes()
                print(f"🧹 验证码清理完成: 清理了 {removed_count} 个过期验证码")
            except Exception as e:
                print(f"❌ 清理验证码失败: {str(e)}")
                
        elif clean_type == "chat":
            keep_days = 30
            if len(args) > 1:
                try:
                    keep_days = int(args[1])
                except ValueError:
                    print("❌ 保留天数必须是整数")
                    return
                    
            try:
                deleted_count = self.mongo_api.clean_old_chat_messages(keep_days)
                print(f"🧹 聊天消息清理完成: 删除了 {deleted_count} 个文档 ({keep_days}天前的消息)")
            except Exception as e:
                print(f"❌ 清理聊天消息失败: {str(e)}")
                
        elif clean_type == "all":
            print("🧹 开始清理所有过期数据...")
            total_cleaned = 0
            
            # 清理验证码
            try:
                codes_count = self.mongo_api.clean_expired_verification_codes()
                print(f"   验证码: 清理了 {codes_count} 个")
                total_cleaned += codes_count
            except Exception as e:
                print(f"   验证码清理失败: {str(e)}")
                
            # 清理聊天消息
            try:
                chat_count = self.mongo_api.clean_old_chat_messages(30)
                print(f"   聊天消息: 删除了 {chat_count} 个文档")
                total_cleaned += chat_count
            except Exception as e:
                print(f"   聊天消息清理失败: {str(e)}")
                
            print(f"✅ 清理完成，总计处理 {total_cleaned} 项")
            
        else:
            print(f"❌ 未知清理类型: {clean_type}")
    
    def cmd_db_backup(self, args):
        """数据库备份命令: /dbbackup [类型]"""
        if not self.mongo_api:
            print("❌ MongoDB API 未初始化")
            return
            
        backup_type = "config" if len(args) == 0 else args[0].lower()
        
        if backup_type == "config":
            try:
                # 备份所有游戏配置
                configs = self.mongo_api.find_documents("gameconfig")
                if configs:
                    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                    backup_file = f"backup/gameconfig_backup_{timestamp}.json"
                    
                    # 确保备份目录存在
                    os.makedirs("backup", exist_ok=True)
                    
                    with open(backup_file, 'w', encoding='utf-8') as f:
                        json.dump(configs, f, ensure_ascii=False, indent=2)
                    
                    print(f"✅ 游戏配置备份完成: {backup_file}")
                    print(f"   备份了 {len(configs)} 个配置文档")
                else:
                    print("❌ 没有找到配置数据")
            except Exception as e:
                print(f"❌ 配置备份失败: {str(e)}")
                
        elif backup_type == "chat":
            try:
                # 备份聊天消息
                chat_docs = self.mongo_api.find_documents("chat")
                if chat_docs:
                    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                    backup_file = f"backup/chat_backup_{timestamp}.json"
                    
                    # 确保备份目录存在
                    os.makedirs("backup", exist_ok=True)
                    
                    with open(backup_file, 'w', encoding='utf-8') as f:
                        json.dump(chat_docs, f, ensure_ascii=False, indent=2)
                    
                    print(f"✅ 聊天消息备份完成: {backup_file}")
                    print(f"   备份了 {len(chat_docs)} 个聊天文档")
                else:
                    print("❌ 没有找到聊天数据")
            except Exception as e:
                print(f"❌ 聊天备份失败: {str(e)}")
                
        else:
            print("❌ 用法: /dbbackup [类型]")
            print("   可用类型:")
            print("     config                  - 备份游戏配置 (默认)")
            print("     chat                    - 备份聊天消息")
    
    # ===================== 扩展功能方法 =====================
    
    def add_custom_command(self, command_name: str, command_func):
        """
        添加自定义命令
        
        Args:
            command_name: 命令名称
            command_func: 命令处理函数
        """
        self.commands[command_name] = command_func
        print(f"✅ 已添加自定义命令: {command_name}")
    
    def remove_command(self, command_name: str) -> bool:
        """
        移除命令
        
        Args:
            command_name: 命令名称
            
        Returns:
            bool: 是否成功移除
        """
        if command_name in self.commands:
            del self.commands[command_name]
            print(f"✅ 已移除命令: {command_name}")
            return True
        else:
            print(f"❌ 命令不存在: {command_name}")
            return False
    
    def get_command_info(self, command_name: str) -> Optional[str]:
        """
        获取命令信息
        
        Args:
            command_name: 命令名称
            
        Returns:
            Optional[str]: 命令文档字符串
        """
        if command_name in self.commands:
            func = self.commands[command_name]
            return func.__doc__ if func.__doc__ else "无描述"
        return None
    
    def execute_batch_commands(self, commands: List[str]) -> Dict[str, bool]:
        """
        批量执行命令
        
        Args:
            commands: 命令列表
            
        Returns:
            Dict[str, bool]: 每个命令的执行结果
        """
        results = {}
        for cmd in commands:
            print(f"\n执行命令: {cmd}")
            results[cmd] = self.process_command(cmd)
        return results