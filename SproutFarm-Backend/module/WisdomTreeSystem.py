"""智慧树系统相关逻辑模块。"""
import time


class WisdomTreeMixin:
    """智慧树系统逻辑混入类。"""
    def _handle_wisdom_tree_operation(self, client_id, message):
        """处理智慧树操作请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "智慧树操作", "wisdom_tree_operation")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "wisdom_tree_operation")
        if not player_data:
            return self.send_data(client_id, response)
        
        operation_type = message.get("operation_type", "")
        
        # 检查并修复智慧树配置格式
        self._check_and_fix_wisdom_tree_config(player_data, username)
        
        # 获取修复后的智慧树配置
        wisdom_tree_config = player_data["智慧树配置"]
        
        # 处理不同的操作类型
        if operation_type == "water":
            return self._process_wisdom_tree_water(client_id, player_data, username, wisdom_tree_config)
        elif operation_type == "fertilize":
            return self._process_wisdom_tree_fertilize(client_id, player_data, username, wisdom_tree_config)
        elif operation_type == "kill_grass":
            return self._process_wisdom_tree_kill_grass(client_id, player_data, username, wisdom_tree_config)
        elif operation_type == "kill_bug":
            return self._process_wisdom_tree_kill_bug(client_id, player_data, username, wisdom_tree_config)
        elif operation_type == "play_music":
            return self._process_wisdom_tree_play_music(client_id, player_data, username, wisdom_tree_config)
        elif operation_type == "revive":
            return self._process_wisdom_tree_revive(client_id, player_data, username, wisdom_tree_config)
        elif operation_type == "get_random_message":
            return self._process_wisdom_tree_get_random_message(client_id, player_data, username, wisdom_tree_config)
        else:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "未知的智慧树操作类型",
                "operation_type": operation_type
            })
    
    def _process_wisdom_tree_water(self, client_id, player_data, username, wisdom_tree_config):
        """处理智慧树浇水"""
        # 检查智慧树是否死亡
        if wisdom_tree_config["当前生命值"] <= 0:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "智慧树已死亡，请先复活！",
                "operation_type": "water"
            })
        
        # 浇水费用
        water_cost = 100
        
        # 检查金钱是否足够
        if player_data["钱币"] < water_cost:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": f"金钱不足，浇水需要 {water_cost} 金币",
                "operation_type": "water"
            })
        
        # 执行浇水
        player_data["钱币"] -= water_cost
        
        # 浇水经验：50-150随机
        import random
        exp_gained = random.randint(50, 150)
        wisdom_tree_config["当前经验值"] += exp_gained
        
        # 浇水高度：40%概率增加1-2高度
        height_gained = 0
        if random.random() < 0.4:  # 40%概率
            height_gained = random.randint(1, 2)
            wisdom_tree_config["高度"] = min(100, wisdom_tree_config["高度"] + height_gained)
        
        # 检查等级提升
        level_up_occurred = self._check_wisdom_tree_level_up(wisdom_tree_config)
        
        # 保存数据
        self.save_player_data(username, player_data)
        
        height_msg = f"，高度+{height_gained}" if height_gained > 0 else ""
        self.log('INFO', f"玩家 {username} 给智慧树浇水，花费 {water_cost} 金币，经验+{exp_gained}{height_msg}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "wisdom_tree_operation_response",
            "success": True,
            "message": f"浇水成功！经验+{exp_gained}{height_msg}",
            "operation_type": "water",
            "updated_data": {
                "钱币": player_data["钱币"],
                "智慧树配置": wisdom_tree_config
            }
        })
    
    def _process_wisdom_tree_fertilize(self, client_id, player_data, username, wisdom_tree_config):
        """处理智慧树施肥"""
        # 检查智慧树是否死亡
        if wisdom_tree_config["当前生命值"] <= 0:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "智慧树已死亡，请先复活！",
                "operation_type": "fertilize"
            })
        
        # 施肥费用
        fertilize_cost = 200
        
        # 检查金钱是否足够
        if player_data["钱币"] < fertilize_cost:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": f"金钱不足，施肥需要 {fertilize_cost} 金币",
                "operation_type": "fertilize"
            })
        
        # 执行施肥
        player_data["钱币"] -= fertilize_cost
        
        # 施肥经验：10-40随机
        import random
        exp_gained = random.randint(10, 40)
        wisdom_tree_config["当前经验值"] += exp_gained
        
        # 施肥高度：80%概率增加1-7高度
        height_gained = 0
        if random.random() < 0.8:  # 80%概率
            height_gained = random.randint(1, 7)
            wisdom_tree_config["高度"] = min(100, wisdom_tree_config["高度"] + height_gained)
        
        # 检查等级提升
        level_up_occurred = self._check_wisdom_tree_level_up(wisdom_tree_config)
        
        # 保存数据
        self.save_player_data(username, player_data)
        
        height_msg = f"，高度+{height_gained}" if height_gained > 0 else ""
        self.log('INFO', f"玩家 {username} 给智慧树施肥，花费 {fertilize_cost} 金币，经验+{exp_gained}{height_msg}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "wisdom_tree_operation_response",
            "success": True,
            "message": f"施肥成功！经验+{exp_gained}{height_msg}",
            "operation_type": "fertilize",
            "updated_data": {
                "钱币": player_data["钱币"],
                "智慧树配置": wisdom_tree_config
            }
        })
    
    def _process_wisdom_tree_kill_grass(self, client_id, player_data, username, wisdom_tree_config):
        """处理智慧树除草"""
        # 检查智慧树是否死亡
        if wisdom_tree_config["当前生命值"] <= 0:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "智慧树已死亡，请先复活！",
                "operation_type": "kill_grass"
            })
        
        # 除草费用
        kill_grass_cost = 150
        
        # 检查金钱是否足够
        if player_data["钱币"] < kill_grass_cost:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": f"金钱不足，除草需要 {kill_grass_cost} 金币",
                "operation_type": "kill_grass"
            })
        
        # 执行除草
        import time
        player_data["钱币"] -= kill_grass_cost
        max_health = wisdom_tree_config["最大生命值"]
        wisdom_tree_config["当前生命值"] = min(max_health, wisdom_tree_config["当前生命值"] + 10)
        wisdom_tree_config["距离上一次除草时间"] = int(time.time())
        
        # 保存数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 给智慧树除草，花费 {kill_grass_cost} 金币，生命值+10", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "wisdom_tree_operation_response",
            "success": True,
            "message": "除草成功！生命值+10",
            "operation_type": "kill_grass",
            "updated_data": {
                "钱币": player_data["钱币"],
                "智慧树配置": wisdom_tree_config
            }
        })
    
    def _process_wisdom_tree_kill_bug(self, client_id, player_data, username, wisdom_tree_config):
        """处理智慧树杀虫"""
        # 检查智慧树是否死亡
        if wisdom_tree_config["当前生命值"] <= 0:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "智慧树已死亡，请先复活！",
                "operation_type": "kill_bug"
            })
        
        # 杀虫费用
        kill_bug_cost = 150
        
        # 检查金钱是否足够
        if player_data["钱币"] < kill_bug_cost:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": f"金钱不足，杀虫需要 {kill_bug_cost} 金币",
                "operation_type": "kill_bug"
            })
        
                # 执行杀虫
        player_data["钱币"] -= kill_bug_cost
        max_health = wisdom_tree_config["最大生命值"]
        wisdom_tree_config["当前生命值"] = min(max_health, wisdom_tree_config["当前生命值"] + 15)
        wisdom_tree_config["距离上一次杀虫时间"] = int(time.time())
        
        # 保存数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 给智慧树杀虫，花费 {kill_bug_cost} 金币，生命值+15", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "wisdom_tree_operation_response",
            "success": True,
            "message": "杀虫成功！生命值+15",
            "operation_type": "kill_bug",
            "updated_data": {
                "钱币": player_data["钱币"],
                "智慧树配置": wisdom_tree_config
            }
        })
    
    def _process_wisdom_tree_play_music(self, client_id, player_data, username, wisdom_tree_config):
        """处理智慧树放音乐"""
        # 检查智慧树是否死亡
        if wisdom_tree_config["当前生命值"] <= 0:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "智慧树已死亡，请先复活！",
                "operation_type": "play_music"
            })
        
        # 放音乐费用
        play_music_cost = 100
        
        # 检查金钱是否足够
        if player_data["钱币"] < play_music_cost:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": f"金钱不足，放音乐需要 {play_music_cost} 金币",
                "operation_type": "play_music"
            })
        
        # 执行放音乐
        player_data["钱币"] -= play_music_cost
        
        # 从智慧树消息库中随机获取一条消息
        random_message = self._get_random_wisdom_tree_message()
        if random_message:
            wisdom_tree_config["智慧树显示的话"] = random_message.get("content", "")
        
        # 保存数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 给智慧树放音乐，花费 {play_music_cost} 金币，获得随机消息", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "wisdom_tree_operation_response",
            "success": True,
            "message": "放音乐成功！获得了一条神秘消息",
            "operation_type": "play_music",
            "random_message": random_message,
            "updated_data": {
                "钱币": player_data["钱币"],
                "智慧树配置": wisdom_tree_config
            }
        })
    
    def _process_wisdom_tree_revive(self, client_id, player_data, username, wisdom_tree_config):
        """处理智慧树复活"""
        # 检查智慧树是否真的死亡
        if wisdom_tree_config["当前生命值"] > 0:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "智慧树还活着，不需要复活！",
                "operation_type": "revive"
            })
        
        # 复活费用
        revive_cost = 1000
        
        # 检查金钱是否足够
        if player_data["钱币"] < revive_cost:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": f"金钱不足，复活智慧树需要 {revive_cost} 金币",
                "operation_type": "revive"
            })
        
        # 执行复活
        player_data["钱币"] -= revive_cost
        wisdom_tree_config["当前生命值"] = wisdom_tree_config["最大生命值"]
        
        # 保存数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 复活了智慧树，花费 {revive_cost} 金币", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "wisdom_tree_operation_response",
            "success": True,
            "message": "智慧树复活成功！",
            "operation_type": "revive",
            "updated_data": {
                "钱币": player_data["钱币"],
                "智慧树配置": wisdom_tree_config
            }
        })
    
    def _process_wisdom_tree_get_random_message(self, client_id, player_data, username, wisdom_tree_config):
        """处理获取随机智慧树消息"""
        # 从智慧树消息库中随机获取一条消息
        random_message = self._get_random_wisdom_tree_message()
        
        if random_message:
            wisdom_tree_config["智慧树显示的话"] = random_message.get("content", "")
            
            # 保存数据
            self.save_player_data(username, player_data)
            
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": True,
                "message": "获得了一条神秘消息",
                "operation_type": "get_random_message",
                "random_message": random_message,
                "updated_data": {
                    "智慧树配置": wisdom_tree_config
                }
            })
        else:
            return self.send_data(client_id, {
                "type": "wisdom_tree_operation_response",
                "success": False,
                "message": "暂时没有新消息",
                "operation_type": "get_random_message"
            })
    
    def _handle_wisdom_tree_message(self, client_id, message):
        """处理智慧树消息发送请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "发送智慧树消息", "wisdom_tree_message")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "wisdom_tree_message")
        if not player_data:
            return self.send_data(client_id, response)
        
        message_content = message.get("message", "").strip()
        
        # 验证消息内容
        if not message_content:
            return self.send_data(client_id, {
                "type": "wisdom_tree_message_response",
                "success": False,
                "message": "消息内容不能为空"
            })
        
        if len(message_content) > 100:
            return self.send_data(client_id, {
                "type": "wisdom_tree_message_response",
                "success": False,
                "message": "消息长度不能超过100个字符"
            })
        
        # 发送消息费用
        send_cost = 50
        
        # 检查金钱是否足够
        if player_data["钱币"] < send_cost:
            return self.send_data(client_id, {
                "type": "wisdom_tree_message_response",
                "success": False,
                "message": f"金钱不足，发送消息需要 {send_cost} 金币"
            })
        
        # 扣除费用
        player_data["钱币"] -= send_cost
        
        # 保存消息到智慧树消息库
        success = self._save_wisdom_tree_message(username, message_content)
        
        if success:
            # 保存玩家数据
            self.save_player_data(username, player_data)
            
            self.log('INFO', f"玩家 {username} 发送智慧树消息，花费 {send_cost} 金币：{message_content}", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "wisdom_tree_message_response",
                "success": True,
                "message": "消息发送成功！",
                "updated_data": {
                    "钱币": player_data["钱币"]
                }
            })
        else:
            return self.send_data(client_id, {
                "type": "wisdom_tree_message_response",
                "success": False,
                "message": "消息发送失败，请重试"
            })
    
    def _handle_get_wisdom_tree_config(self, client_id, message):
        """处理获取智慧树配置请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "获取智慧树配置", "get_wisdom_tree_config")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "get_wisdom_tree_config")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 检查并修复智慧树配置
        self._check_and_fix_wisdom_tree_config(player_data, username)
        
        # 保存修复后的数据
        self.save_player_data(username, player_data)
        
        # 返回智慧树配置
        wisdom_tree_config = player_data.get("智慧树配置", {})
        
        self.log('INFO', f"玩家 {username} 请求智慧树配置", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "wisdom_tree_config_response",
            "success": True,
            "config": wisdom_tree_config
        })
    
    def _check_wisdom_tree_level_up(self, wisdom_tree_config):
        """检查智慧树等级提升"""
        current_level = wisdom_tree_config["等级"]
        current_experience = wisdom_tree_config["当前经验值"]
        max_experience = wisdom_tree_config["最大经验值"]
        level_ups = 0
        
        # 检查是否可以升级（最高等级20）
        while current_level < 20 and current_experience >= max_experience:
            # 升级
            current_level += 1
            current_experience -= max_experience  # 扣除升级所需经验
            level_ups += 1
            
            # 计算新等级的最大经验值
            max_experience = self._calculate_wisdom_tree_max_exp(current_level)
            
            self.log('INFO', f"智慧树等级提升到 {current_level} 级，新的最大经验值: {max_experience}", 'SERVER')
        
        # 每升一级，最大生命值+2，当前生命值也+2
        if level_ups > 0:
            health_bonus = level_ups * 2
            wisdom_tree_config["最大生命值"] = min(200, wisdom_tree_config["最大生命值"] + health_bonus)
            wisdom_tree_config["当前生命值"] = min(wisdom_tree_config["最大生命值"], wisdom_tree_config["当前生命值"] + health_bonus)
            self.log('INFO', f"智慧树升级 {level_ups} 级，最大生命值+{health_bonus}", 'SERVER')
        
        # 更新配置
        wisdom_tree_config["等级"] = current_level
        wisdom_tree_config["当前经验值"] = current_experience
        wisdom_tree_config["最大经验值"] = max_experience
        
        return level_ups > 0
    
    def _get_random_wisdom_tree_message(self):
        """从智慧树消息库中随机获取一条消息"""
        import os
        import json
        import random
        
        # 优先从MongoDB读取
        if hasattr(self, 'mongo_api') and self.mongo_api and self.mongo_api.is_connected():
            try:
                wisdom_tree_data = self.mongo_api.get_wisdom_tree_config()
                if wisdom_tree_data:
                    messages = wisdom_tree_data.get("messages", [])
                    if messages:
                        selected_message = random.choice(messages)
                        self.log('INFO', f"成功从MongoDB获取智慧树消息", 'SERVER')
                        return selected_message
                    else:
                        return None
            except Exception as e:
                self.log('ERROR', f"从MongoDB读取智慧树消息失败: {e}", 'SERVER')
        
        # 回退到JSON文件
        wisdom_tree_data_path = os.path.join(os.path.dirname(__file__), "config", "wisdom_tree_data.json")
        
        try:
            with open(wisdom_tree_data_path, 'r', encoding='utf-8') as f:
                wisdom_tree_data = json.load(f)
            
            messages = wisdom_tree_data.get("messages", [])
            if messages:
                selected_message = random.choice(messages)
                self.log('INFO', f"成功从JSON文件获取智慧树消息", 'SERVER')
                return selected_message
            else:
                return None
        except Exception as e:
            self.log('ERROR', f"从JSON文件读取智慧树消息失败: {e}", 'SERVER')
            return None
    
    def _save_wisdom_tree_message(self, username, message_content):
        """保存智慧树消息到消息库"""
        import os
        import json
        import time
        import uuid
        
        # 创建新消息
        new_message = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
            "sender": username,
            "content": message_content,
            "id": str(uuid.uuid4())
        }
        
        # 优先保存到MongoDB
        if hasattr(self, 'mongo_api') and self.mongo_api and self.mongo_api.is_connected():
            try:
                # 获取现有数据
                wisdom_tree_data = self.mongo_api.get_wisdom_tree_config()
                if not wisdom_tree_data:
                    wisdom_tree_data = {
                        "messages": [],
                        "total_messages": 0,
                        "last_update": ""
                    }
                
                # 添加新消息
                wisdom_tree_data["messages"].append(new_message)
                wisdom_tree_data["total_messages"] = len(wisdom_tree_data["messages"])
                wisdom_tree_data["last_update"] = new_message["timestamp"]
                
                # 保持最多1000条消息
                if len(wisdom_tree_data["messages"]) > 1000:
                    wisdom_tree_data["messages"] = wisdom_tree_data["messages"][-1000:]
                    wisdom_tree_data["total_messages"] = len(wisdom_tree_data["messages"])
                
                # 保存到MongoDB
                if self.mongo_api.update_wisdom_tree_config(wisdom_tree_data):
                    self.log('INFO', f"成功保存智慧树消息到MongoDB: {username}", 'SERVER')
                    return True
                else:
                    self.log('ERROR', f"保存智慧树消息到MongoDB失败: {username}", 'SERVER')
            except Exception as e:
                self.log('ERROR', f"MongoDB保存智慧树消息异常: {e}", 'SERVER')
        
        # 回退到JSON文件
        wisdom_tree_data_path = os.path.join(os.path.dirname(__file__), "config", "wisdom_tree_data.json")
        
        try:
            # 读取现有数据
            if os.path.exists(wisdom_tree_data_path):
                with open(wisdom_tree_data_path, 'r', encoding='utf-8') as f:
                    wisdom_tree_data = json.load(f)
            else:
                wisdom_tree_data = {
                    "messages": [],
                    "total_messages": 0,
                    "last_update": ""
                }
            
            # 添加到消息列表
            wisdom_tree_data["messages"].append(new_message)
            wisdom_tree_data["total_messages"] = len(wisdom_tree_data["messages"])
            wisdom_tree_data["last_update"] = new_message["timestamp"]
            
            # 保持最多1000条消息
            if len(wisdom_tree_data["messages"]) > 1000:
                wisdom_tree_data["messages"] = wisdom_tree_data["messages"][-1000:]
                wisdom_tree_data["total_messages"] = len(wisdom_tree_data["messages"])
            
            # 保存数据
            with open(wisdom_tree_data_path, 'w', encoding='utf-8') as f:
                json.dump(wisdom_tree_data, f, ensure_ascii=False, indent=4)
            
            self.log('INFO', f"成功保存智慧树消息到JSON文件: {username}", 'SERVER')
            return True
        except Exception as e:
            self.log('ERROR', f"保存智慧树消息到JSON文件失败: {e}", 'SERVER')
            return False
    
    def check_wisdom_tree_health_decay(self):
        """检查智慧树生命值衰减"""
        import time
        
        current_time = int(time.time())
        processed_count = 0
        
        # 检查所有在线玩家
        for client_id in self.user_data:
            if self.user_data[client_id].get("logged_in", False):
                username = self.user_data[client_id]["username"]
                player_data = self.load_player_data(username)
                if player_data and "智慧树配置" in player_data:
                    self._process_wisdom_tree_decay(player_data["智慧树配置"], username)
                    self.save_player_data(username, player_data)
                    processed_count += 1
        
        # 注释：缓存机制已移除，只处理在线玩家的智慧树衰减
        
        if processed_count > 0:
            self.log('INFO', f"已处理 {processed_count} 个玩家的智慧树生命值衰减", 'SERVER')
    
    def _process_wisdom_tree_decay(self, wisdom_tree_config, username):
        """处理单个玩家的智慧树生命值衰减"""
        import time
        import random
        
        current_time = int(time.time())
        
        # 获取上次除草和杀虫时间，处理空字符串和无效值
        last_grass_time_raw = wisdom_tree_config.get("距离上一次除草时间", current_time)
        last_bug_time_raw = wisdom_tree_config.get("距离上一次杀虫时间", current_time)
        
        # 处理空字符串和无效时间戳
        try:
            last_grass_time = int(last_grass_time_raw) if last_grass_time_raw and str(last_grass_time_raw).strip() else current_time
        except (ValueError, TypeError):
            last_grass_time = current_time
            
        try:
            last_bug_time = int(last_bug_time_raw) if last_bug_time_raw and str(last_bug_time_raw).strip() else current_time
        except (ValueError, TypeError):
            last_bug_time = current_time
        
        # 如果时间戳无效（为0或负数），设置为当前时间
        if last_grass_time <= 0:
            last_grass_time = current_time
        if last_bug_time <= 0:
            last_bug_time = current_time
        
        # 检查是否3天没有除草
        days_since_grass = (current_time - last_grass_time) / 86400  # 转换为天数
        if days_since_grass >= 3:
            # 计算应该衰减的天数
            decay_days = int(days_since_grass)
            if decay_days > 0:
                # 每天减少1-3血量
                total_decay = 0
                for _ in range(decay_days):
                    daily_decay = random.randint(1, 3)
                    total_decay += daily_decay
                
                wisdom_tree_config["当前生命值"] = max(0, wisdom_tree_config["当前生命值"] - total_decay)
                self.log('INFO', f"玩家 {username} 的智慧树因{decay_days}天未除草，生命值减少{total_decay}", 'SERVER')
                
                # 更新除草时间为当前时间，避免重复扣血
                wisdom_tree_config["距离上一次除草时间"] = current_time
        
        # 检查是否3天没有杀虫
        days_since_bug = (current_time - last_bug_time) / 86400  # 转换为天数
        if days_since_bug >= 3:
            # 计算应该衰减的天数
            decay_days = int(days_since_bug)
            if decay_days > 0:
                # 每天减少1-3血量
                total_decay = 0
                for _ in range(decay_days):
                    daily_decay = random.randint(1, 3)
                    total_decay += daily_decay
                
                wisdom_tree_config["当前生命值"] = max(0, wisdom_tree_config["当前生命值"] - total_decay)
                self.log('INFO', f"玩家 {username} 的智慧树因{decay_days}天未杀虫，生命值减少{total_decay}", 'SERVER')
                
                # 更新杀虫时间为当前时间，避免重复扣血
                wisdom_tree_config["距离上一次杀虫时间"] = current_time
