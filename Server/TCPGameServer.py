from TCPServer import TCPServer
import time
import json

server_host: str = "0.0.0.0"
server_port: int = 4040
buffer_size: int = 4096

#由于方法数量众多，所以将方法分组
#1.服务端对本地的操作
#2.服务端对客户端的操作

class TCPGameServer(TCPServer):
    #初始化TCP游戏服务器
    def __init__(self, server_host=server_host, server_port=server_port, buffer_size=buffer_size):
        super().__init__(server_host, server_port, buffer_size)
        self.user_data = {}  # 存储用户相关数据
        self.crop_timer = None  # 作物生长计时器
        self.log('INFO', "TCP游戏服务器初始化", 'SERVER')
        
        # 启动作物生长计时器
        self.start_crop_growth_timer()
    

    #检查用户是否已登录的通用方法
    def _check_user_logged_in(self, client_id, action_name, action_type=None):
        """
        检查用户是否已登录的通用方法
        
        参数:
            client_id (str): 客户端ID
            action_name (str): 操作名称，用于日志记录
            action_type (str, optional): 操作类型，用于响应消息
            
        返回:
            tuple: (bool, response)
                - bool: True表示已登录，False表示未登录
                - response: 如果未登录，返回发送给客户端的错误响应，否则为None
        """
        if client_id not in self.user_data or not self.user_data[client_id].get("logged_in", False):
            self.log('WARNING', f"未登录用户 {client_id} 尝试{action_name}", 'SERVER')
            
            # 构建响应
            response = {
                "success": False,
                "message": "您需要先登录才能执行此操作"
            }
            
            # 如果提供了action_type，添加到响应中
            if action_type:
                response["type"] = "action_response"
                response["action_type"] = action_type
            else:
                # 否则使用通用的响应类型
                response["type"] = f"{action_name}_response"
            
            return False, response
        
        # 用户已登录
        return True, None



    #从JSON文件加载玩家数据
    def load_player_data(self, account_id):
        """
        从game_saves文件夹加载玩家数据
        
        参数:
            account_id (str): 玩家账号ID
        
        返回:
            dict: 玩家数据字典，如果文件不存在则返回None
        """
        import os
        
        file_path = os.path.join("game_saves", f"{account_id}.json")
        
        try:
            if os.path.exists(file_path):
                with open(file_path, 'r', encoding='utf-8') as file:
                    player_data = json.load(file)
                #self.log('INFO', f"已加载玩家 {account_id} 的数据", 'SERVER')
                return player_data
            else:
                #self.log('WARNING', f"玩家 {account_id} 的数据文件不存在", 'SERVER')
                return None
        except Exception as e:
            #self.log('ERROR', f"读取玩家 {account_id} 的数据时出错: {str(e)}", 'SERVER')
            return None
        
    #通用加载玩家数据方法，带错误处理
    def _load_player_data_with_check(self, client_id, action_type=None):
        """
        加载玩家数据并进行错误检查的通用方法
        
        参数:
            client_id (str): 客户端ID
            action_type (str, optional): 操作类型，用于错误响应
            
        返回:
            tuple: (player_data, username, response)
                - player_data: 成功加载的玩家数据，如果加载失败则为None
                - username: 玩家用户名
                - response: 如果加载失败，返回发送给客户端的错误响应，否则为None
        """
        username = self.user_data[client_id]["username"]
        player_data = self.load_player_data(username)
        
        if not player_data:
            self.log('ERROR', f"无法加载玩家 {username} 的数据", 'SERVER')
            
            # 构建错误响应
            response = {
                "success": False,
                "message": "无法加载玩家数据"
            }
            
            # 如果提供了action_type，添加到响应中
            if action_type:
                response["type"] = "action_response"
                response["action_type"] = action_type
            else:
                # 否则使用通用的响应类型
                response["type"] = "data_response"
            
            return None, username, response
        
        # 成功加载玩家数据
        return player_data, username, None


    #保存玩家数据到JSON文件
    def save_player_data(self, account_id, player_data):
        """
        保存玩家数据到game_saves文件夹
        
        参数:
            account_id (str): 玩家账号ID
            player_data (dict): 玩家数据字典
        
        返回:
            bool: 保存成功返回True，否则返回False
        """
        import os
        
        file_path = os.path.join("game_saves", f"{account_id}.json")
        
        try:
            with open(file_path, 'w', encoding='utf-8') as file:
                json.dump(player_data, file, indent=2, ensure_ascii=False)
            #self.log('INFO', f"已保存玩家 {account_id} 的数据", 'SERVER')
            return True
        except Exception as e:
            self.log('ERROR', f"保存玩家 {account_id} 的数据时出错: {str(e)}", 'SERVER')
            return False


    #更新作物生长状态
    def update_crops_growth(self):
        """
        更新所有玩家的作物生长状态
        每秒钟对有作物的地块增加生长时间
        并向在线玩家推送更新
        """
        import os
        import glob
        
        # 获取所有玩家存档文件
        save_files = glob.glob(os.path.join("game_saves", "*.json"))
        
        for save_file in save_files:
            try:
                # 从文件名提取账号ID
                account_id = os.path.basename(save_file).split('.')[0]
                
                # 加载玩家数据
                player_data = self.load_player_data(account_id)
                if not player_data:
                    continue
                
                # 检查是否有作物需要更新
                growth_updated = False
                
                # 遍历每个农场地块
                for farm_lot in player_data.get("farm_lots", []):
                    # 如果地块有作物且未死亡
                    if farm_lot.get("crop_type") and farm_lot.get("is_planted") and not farm_lot.get("is_dead") and farm_lot["grow_time"] < farm_lot["max_grow_time"]:
                        # 增加生长时间
                        farm_lot["grow_time"] += 1
                        growth_updated = True
                
                # 如果有作物更新，保存玩家数据
                if growth_updated:
                    self.save_player_data(account_id, player_data)
                    
                    # 向在线玩家推送更新
                    self._push_crop_update_to_player(account_id, player_data)
                    
            except Exception as e:
                self.log('ERROR', f"更新作物生长状态时出错: {str(e)}", 'SERVER')
                
    
    #向在线玩家推送作物更新
    def _push_crop_update_to_player(self, account_id, player_data):
        """
        向在线玩家推送作物生长更新
        
        参数:
            account_id (str): 玩家账号ID
            player_data (dict): 玩家数据
        """
        # 查找对应的客户端ID
        client_id = None
        for cid, user_info in self.user_data.items():
            if user_info.get("username") == account_id and user_info.get("logged_in", False):
                client_id = cid
                break
        
        # 如果玩家在线，检查是否处于访问模式
        if client_id:
            # 检查玩家是否处于访问模式
            visiting_mode = self.user_data[client_id].get("visiting_mode", False)
            visiting_target = self.user_data[client_id].get("visiting_target", "")
            
            if visiting_mode and visiting_target:
                # 如果处于访问模式，发送被访问玩家的更新数据
                target_player_data = self.load_player_data(visiting_target)
                if target_player_data:
                    update_message = {
                        "type": "crop_update",
                        "farm_lots": target_player_data.get("farm_lots", []),
                        "timestamp": time.time(),
                        "is_visiting": True,
                        "visited_player": visiting_target
                    }
                    self.send_data(client_id, update_message)
                    self.log('DEBUG', f"已向访问模式中的玩家 {account_id} 推送被访问玩家 {visiting_target} 的作物更新", 'SERVER')
            else:
                # 正常模式，发送自己的农场更新
                update_message = {
                    "type": "crop_update",
                    "farm_lots": player_data.get("farm_lots", []),
                    "timestamp": time.time(),
                    "is_visiting": False
                }
                self.send_data(client_id, update_message)
                self.log('DEBUG', f"已向玩家 {account_id} 推送作物更新", 'SERVER')


    #设置一个计时器，每秒更新一次作物生长状态
    def start_crop_growth_timer(self):
        """
        启动作物生长计时器，每秒更新一次
        """
        import threading
        
        # 更新作物生长状态
        self.update_crops_growth()
        
        # 创建下一个计时器
        self.crop_timer = threading.Timer(1.0, self.start_crop_growth_timer)
        self.crop_timer.daemon = True
        self.crop_timer.start()


    #覆盖客户端移除方法，添加用户离开通知
    def _remove_client(self, client_id):
        # 通知其他用户
        if client_id in self.clients:
            # 获取用户名以便记录日志
            username = self.user_data.get(client_id, {}).get("username", client_id)
            
            # 如果用户已登录，更新总游玩时间并标记其登出
            if client_id in self.user_data and self.user_data[client_id].get("logged_in", False):
                login_timestamp = self.user_data[client_id].get("login_timestamp", time.time())
                play_time_seconds = int(time.time() - login_timestamp)
                
                # 清除访问状态
                self.user_data[client_id]["visiting_mode"] = False
                self.user_data[client_id]["visiting_target"] = ""
                
                # 加载玩家数据
                player_data = self.load_player_data(username)
                if player_data:
                    import datetime
                    import re
                    
                    # 解析现有的总游玩时间
                    total_time_str = player_data.get("total_login_time", "0时0分0秒")
                    time_parts = re.match(r"(?:(\d+)时)?(?:(\d+)分)?(?:(\d+)秒)?", total_time_str)
                    
                    if time_parts:
                        hours = int(time_parts.group(1) or 0)
                        minutes = int(time_parts.group(2) or 0)
                        seconds = int(time_parts.group(3) or 0)
                        
                        # 计算新的总游玩时间
                        total_seconds = hours * 3600 + minutes * 60 + seconds + play_time_seconds
                        new_hours = total_seconds // 3600
                        new_minutes = (total_seconds % 3600) // 60
                        new_seconds = total_seconds % 60
                        
                        # 更新总游玩时间
                        player_data["total_login_time"] = f"{new_hours}时{new_minutes}分{new_seconds}秒"
                        
                        # 保存玩家数据
                        self.save_player_data(username, player_data)
                        
                        self.log('INFO', f"用户 {username} 本次游玩时间: {play_time_seconds} 秒，总游玩时间: {player_data['total_login_time']}", 'SERVER')
                
                self.log('INFO', f"用户 {username} 登出", 'SERVER')
            
            self.broadcast(
                {
                    "type": "user_left",
                    "user_id": client_id,
                    "timestamp": time.time(),
                    "remaining_users": len(self.clients) - 1
                },
                exclude=[client_id]
            )
            
            # 清理用户数据
            if client_id in self.user_data:
                del self.user_data[client_id]
                
            self.log('INFO', f"用户 {username} 已离开游戏", 'SERVER')
        
        # 调用父类方法完成实际断开
        super()._remove_client(client_id)


    #覆盖停止方法，停止作物生长计时器
    def stop(self):
        # 停止作物生长计时器
        if self.crop_timer:
            self.crop_timer.cancel()
            self.crop_timer = None
            self.log('INFO', "作物生长计时器已停止", 'SERVER')
        
        # 调用父类方法完成实际停止
        super().stop()


    #接收客户端消息并处理
    def _handle_message(self, client_id, message):
        message_type = message.get("type", "")
        match message_type:
            case "greeting":
                return self._handle_greeting(client_id, message)
            case "message":
                return self._handle_chat_message(client_id, message)
            case "login":
                return self._handle_login(client_id, message)
            case "register":
                return self._handle_register(client_id, message)
            case "request_verification_code":
                return self._handle_verification_code_request(client_id, message)
            case "verify_code":
                return self._handle_verify_code(client_id, message)
            #玩家基本游戏操作
            case "harvest_crop":
                return self._handle_harvest_crop(client_id, message)
            case "plant_crop":
                return self._handle_plant_crop(client_id, message)
            case "buy_seed":
                return self._handle_buy_seed(client_id, message)
            case "dig_ground":
                return self._handle_dig_ground(client_id, message)
            #玩家基本游戏操作
            case "get_play_time":
                return self._handle_get_play_time(client_id)
            case "update_play_time":
                return self._handle_update_play_time(client_id)
            case "request_player_rankings":
                return self._handle_player_rankings_request(client_id)
            case "request_crop_data":
                return self._handle_crop_data_request(client_id)
            case "visit_player":
                return self._handle_visit_player_request(client_id, message)
            case "return_my_farm":
                return self._handle_return_my_farm_request(client_id, message)
            case _:
                # 未知类型，使用默认处理
                return super()._handle_message(client_id, message)
    

    #处理登录消息
    def _handle_login(self, client_id, message):
        username = message.get("username", "")
        password = message.get("password", "")
        
        # 读取玩家数据
        player_data = self.load_player_data(username)
        
        if player_data and player_data.get("user_password") == password:
            # 登录成功
            self.log('INFO', f"用户 {username} 登录成功", 'SERVER')
            
            # 更新最后登录时间
            import datetime
            current_time = datetime.datetime.now()
            player_data["last_login_time"] = current_time.strftime("%Y年%m月%d日%H时%M分%S秒")
            
            # 保存用户会话信息
            self.user_data[client_id] = {
                "username": username,
                "last_active": time.time(),
                "messages_count": 0,
                "logged_in": True,
                "login_timestamp": time.time()  # 记录登录时间戳用于计算游玩时间
            }
            
            # 保存更新后的玩家数据
            self.save_player_data(username, player_data)
            
            # 立即向客户端发送一次作物状态
            farm_lots = player_data.get("farm_lots", [])
            initial_crop_update = {
                "type": "crop_update",
                "farm_lots": farm_lots,
                "timestamp": time.time()
            }
            self.send_data(client_id, initial_crop_update)
            
            # 发送最新的作物数据配置
            try:
                with open("config/crop_data.json", 'r', encoding='utf-8') as file:
                    crop_data = json.load(file)
                
                crop_data_message = {
                    "type": "crop_data_response",
                    "success": True,
                    "crop_data": crop_data
                }
                self.send_data(client_id, crop_data_message)
                self.log('INFO', f"已向登录用户 {username} 发送作物数据配置", 'SERVER')
            except Exception as e:
                self.log('ERROR', f"无法向登录用户发送作物数据: {str(e)}", 'SERVER')
            
            # 返回登录成功消息
            response = {
                "type": "login_response",
                "status": "success",
                "message": "登录成功",
                "player_data": player_data
            }
        else:
            # 登录失败
            self.log('WARNING', f"用户 {username} 登录失败: 账号或密码错误", 'SERVER')
            response = {
                "type": "login_response",
                "status": "failed",
                "message": "账号或密码错误"
            }
            
        return self.send_data(client_id, response)


    #处理注册消息
    def _handle_register(self, client_id, message):
        username = message.get("username", "")
        password = message.get("password", "")
        farm_name = message.get("farm_name", "")
        player_name = message.get("player_name", "")
        verification_code = message.get("verification_code", "")
        
        # 验证必填字段
        if not username or not password:
            self.log('WARNING', f"注册失败: 用户名或密码为空", 'SERVER')
            return self.send_data(client_id, {
                "type": "register_response",
                "status": "failed",
                "message": "用户名或密码不能为空"
            })
        
        # 验证用户名是否是QQ号 (5-12位数字)
        import re
        if not re.match(r'^\d{5,12}$', username):
            self.log('WARNING', f"注册失败: 用户名 {username} 不是有效的QQ号码", 'SERVER')
            return self.send_data(client_id, {
                "type": "register_response",
                "status": "failed",
                "message": "用户名必须是5-12位的QQ号码"
            })
        
        # 验证验证码
        if verification_code:
            from QQEmailSend import EmailVerification
            success, verify_message = EmailVerification.verify_code(username, verification_code)
            if not success:
                self.log('WARNING', f"注册失败: 验证码错误 - {verify_message}", 'SERVER')
                return self.send_data(client_id, {
                    "type": "register_response",
                    "status": "failed",
                    "message": f"验证码错误: {verify_message}"
                })
        
        # 检查用户是否已存在
        import os
        file_path = os.path.join("game_saves", f"{username}.json")
        if os.path.exists(file_path):
            self.log('WARNING', f"注册失败: 用户 {username} 已存在", 'SERVER')
            return self.send_data(client_id, {
                "type": "register_response",
                "status": "failed",
                "message": "该用户名已被注册"
            })
        
        try:
            # 从模板加载初始玩家数据
            template_path = os.path.join("config", "initial_player_data_template.json")
            if not os.path.exists(template_path):
                self.log('ERROR', f"无法找到玩家数据模板文件", 'SERVER')
                return self.send_data(client_id, {
                    "type": "register_response",
                    "status": "failed",
                    "message": "服务器配置错误，无法注册新用户"
                })
                
            with open(template_path, 'r', encoding='utf-8') as file:
                player_data = json.load(file)
                
            # 更新玩家数据
            player_data["user_name"] = username
            player_data["user_password"] = password
            
            # 设置农场名称，如果没有提供则使用默认名称
            if farm_name:
                player_data["farm_name"] = farm_name
            
            # 设置玩家昵称，如果没有提供则使用QQ号或默认昵称
            if player_name:
                player_data["player_name"] = player_name
            else:
                player_data["player_name"] = username
            
            # 确保所有必要的字段都存在
            if "experience" not in player_data:
                player_data["experience"] = 0
            if "level" not in player_data:
                player_data["level"] = 1
            if "money" not in player_data:
                player_data["money"] = 1000
            if "farm_lots" not in player_data:
                # 创建空的农场地块
                player_data["farm_lots"] = []
                for i in range(40):
                    player_data["farm_lots"].append({
                        "crop_type": "",
                        "grow_time": 0,
                        "is_dead": False,
                        "is_diged": i < 5, # 默认开垦前5块地
                        "is_planted": False,
                        "max_grow_time": 5 if i >= 5 else 3
                    })
            if "player_bag" not in player_data:
                player_data["player_bag"] = []
            
            # 更新注册时间和登录时间
            import datetime
            current_time = datetime.datetime.now()
            time_str = current_time.strftime("%Y年%m月%d日%H时%M分%S秒")
            player_data["last_login_time"] = time_str
            
            if "total_login_time" not in player_data:
                player_data["total_login_time"] = "0时0分0秒"
            
            # 保存新用户数据
            with open(file_path, 'w', encoding='utf-8') as file:
                json.dump(player_data, file, indent=2, ensure_ascii=False)
                
            self.log('INFO', f"用户 {username} 注册成功", 'SERVER')
            
            # 返回成功响应
            return self.send_data(client_id, {
                "type": "register_response",
                "status": "success",
                "message": "注册成功，请登录游戏"
            })
            
        except Exception as e:
            self.log('ERROR', f"注册用户 {username} 时出错: {str(e)}", 'SERVER')
            return self.send_data(client_id, {
                "type": "register_response",
                "status": "failed",
                "message": f"注册过程中出现错误: {str(e)}"
            })




    #处理问候消息
    def _handle_greeting(self, client_id, message):
        content = message.get("content", "")
        self.log('INFO', f"收到来自客户端 {client_id} 的问候: {content}", 'CLIENT')
        
        # 保存用户会话信息
        self.user_data[client_id] = {
            "last_active": time.time(),
            "messages_count": 0
        }
        
        # 回复欢迎消息
        response = {
            "type": "greeting_response",
            "content": f"欢迎 {client_id}!",
            "server_time": time.time(),
            "active_users": len(self.clients)
        }
        
        # 通知其他用户有新用户加入
        self.broadcast(
            {
                "type": "user_joined",
                "user_id": client_id,
                "timestamp": time.time(),
                "active_users": len(self.clients)
            },
            exclude=[client_id]
        )
        
        self.log('INFO', f"用户 {client_id} 已加入游戏", 'SERVER')
        return self.send_data(client_id, response)




    #处理收获作物请求
    def _handle_harvest_crop(self, client_id, message):
        """
        处理玩家收获作物的请求
        
        参数:
            client_id (str): 客户端ID
            message (dict): 消息内容
        """
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "收获作物", "harvest_crop")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "harvest_crop")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 获取地块索引
        lot_index = message.get("lot_index", -1)
        
        # 验证地块索引
        if lot_index < 0 or lot_index >= len(player_data.get("farm_lots", [])):
            self.log('WARNING', f"玩家 {username} 请求收获无效地块 {lot_index}", 'SERVER')
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "harvest_crop",
                "success": False,
                "message": "无效的地块索引"
            })
        
        # 获取地块数据
        lot = player_data["farm_lots"][lot_index]
        
        # 检查地块是否有作物且已成熟
        if not lot.get("is_planted", False) or not lot.get("crop_type", ""):
            self.log('WARNING', f"玩家 {username} 尝试收获空地块 {lot_index}", 'SERVER')
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "harvest_crop",
                "success": False,
                "message": "此地块没有种植作物"
            })
        
        if lot.get("is_dead", False):
            # 处理已死亡的作物
            self.log('INFO', f"玩家 {username} 铲除了地块 {lot_index} 上已死亡的作物", 'SERVER')
            
            # 清理地块
            lot["is_planted"] = False
            lot["crop_type"] = ""
            lot["grow_time"] = 0
            
            # 保存玩家数据
            self.save_player_data(username, player_data)
            
            # 发送作物更新
            self._push_crop_update_to_player(username, player_data)
            
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "harvest_crop",
                "success": True,
                "message": f"已铲除死亡的作物",
                "updated_data": {
                    "money": player_data["money"],
                    "experience": player_data["experience"],
                    "level": player_data["level"]
                }
            })
        
        if lot["grow_time"] < lot["max_grow_time"]:
            self.log('WARNING', f"玩家 {username} 尝试收获未成熟的作物 {lot_index}", 'SERVER')
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "harvest_crop",
                "success": False,
                "message": "作物尚未成熟"
            })
        
        # 读取作物配置 (假设在服务器上也有作物配置)
        import json
        crop_data = {}
        try:
            with open("config/crop_data.json", 'r', encoding='utf-8') as file:
                crop_data = json.load(file)
        except Exception as e:
            self.log('ERROR', f"无法加载作物数据: {str(e)}", 'SERVER')
            # 使用默认收益
            crop_income = 100
            crop_exp = 10
        
        # 获取作物收益和经验
        crop_type = lot["crop_type"]
        if crop_type in crop_data:
            crop_income = crop_data[crop_type].get("收益", 100) + crop_data[crop_type].get("花费", 0)
            crop_exp = crop_data[crop_type].get("经验", 10)
        else:
            # 默认收益
            crop_income = 100
            crop_exp = 10
        
        # 更新玩家数据
        player_data["money"] += crop_income
        player_data["experience"] += crop_exp
        
        # 检查升级
        level_up_experience = 100 * player_data["level"]
        if player_data["experience"] >= level_up_experience:
            player_data["level"] += 1
            player_data["experience"] -= level_up_experience
            self.log('INFO', f"玩家 {username} 升级到 {player_data['level']} 级", 'SERVER')
        
        # 清理地块
        lot["is_planted"] = False
        lot["crop_type"] = ""
        lot["grow_time"] = 0
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        self.log('INFO', f"玩家 {username} 从地块 {lot_index} 收获了作物，获得 {crop_income} 金钱和 {crop_exp} 经验", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "harvest_crop",
            "success": True,
            "message": f"收获成功，获得 {crop_income} 金钱和 {crop_exp} 经验",
            "updated_data": {
                "money": player_data["money"],
                "experience": player_data["experience"],
                "level": player_data["level"]
            }
        })
    
    
    #处理种植作物请求
    def _handle_plant_crop(self, client_id, message):
        """
        处理玩家种植作物的请求
        
        参数:
            client_id (str): 客户端ID
            message (dict): 消息内容
        """
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "种植作物", "plant_crop")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "plant_crop")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 获取地块索引和作物名称
        lot_index = message.get("lot_index", -1)
        crop_name = message.get("crop_name", "")
        
        # 验证地块索引
        if lot_index < 0 or lot_index >= len(player_data.get("farm_lots", [])):
            self.log('WARNING', f"玩家 {username} 请求种植无效地块 {lot_index}", 'SERVER')
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "plant_crop",
                "success": False,
                "message": "无效的地块索引"
            })
        
        # 获取地块数据
        lot = player_data["farm_lots"][lot_index]
        
        # 检查地块是否已开垦且未种植
        if not lot.get("is_diged", False):
            self.log('WARNING', f"玩家 {username} 尝试在未开垦的地块 {lot_index} 种植", 'SERVER')
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "plant_crop",
                "success": False,
                "message": "此地块尚未开垦"
            })
        
        if lot.get("is_planted", False):
            self.log('WARNING', f"玩家 {username} 尝试在已种植的地块 {lot_index} 种植", 'SERVER')
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "plant_crop",
                "success": False,
                "message": "此地块已经种植了作物"
            })
        
        # 读取作物配置 (假设在服务器上也有作物配置)
        import json
        crop_data = {}
        try:
            with open("config/crop_data.json", 'r', encoding='utf-8') as file:
                crop_data = json.load(file)
        except Exception as e:
            self.log('ERROR', f"无法加载作物数据: {str(e)}", 'SERVER')
            # 如果无法加载作物数据，使用默认生长时间
            grow_time = 600
        
        # 检查玩家背包中是否有此种子
        seed_found = False
        seed_index = -1
        
        for i, item in enumerate(player_data.get("player_bag", [])):
            if item.get("name") == crop_name:
                seed_found = True
                seed_index = i
                break
        
        if not seed_found:
            self.log('WARNING', f"玩家 {username} 尝试种植背包中没有的种子 {crop_name}", 'SERVER')
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "plant_crop",
                "success": False,
                "message": "背包中没有此种子"
            })
        
        # 获取作物生长时间
        if crop_name in crop_data:
            grow_time = crop_data[crop_name].get("生长时间", 600)
        else:
            # 默认生长时间
            grow_time = 600
        
        # 从背包中减少种子数量
        player_data["player_bag"][seed_index]["count"] -= 1
        
        # 如果种子用完，从背包中移除
        if player_data["player_bag"][seed_index]["count"] <= 0:
            player_data["player_bag"].pop(seed_index)
        
        # 更新地块数据
        lot["is_planted"] = True
        lot["crop_type"] = crop_name
        lot["grow_time"] = 0
        lot["max_grow_time"] = grow_time
        lot["is_dead"] = False
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        self.log('INFO', f"玩家 {username} 在地块 {lot_index} 种植了 {crop_name}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "plant_crop",
            "success": True,
            "message": f"成功种植 {crop_name}",
            "updated_data": {
                "player_bag": player_data["player_bag"]
            }
        })
     

    #处理购买种子请求
    def _handle_buy_seed(self, client_id, message):
        """
        处理玩家购买种子的请求
        
        参数:
            client_id (str): 客户端ID
            message (dict): 消息内容
        """
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "购买种子", "buy_seed")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "buy_seed")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 获取作物名称
        crop_name = message.get("crop_name", "")
        
        # 读取作物配置 (假设在服务器上也有作物配置)
        import json
        crop_data = {}
        try:
            with open("config/crop_data.json", 'r', encoding='utf-8') as file:
                crop_data = json.load(file)
        except Exception as e:
            self.log('ERROR', f"无法加载作物数据: {str(e)}", 'SERVER')
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "buy_seed",
                "success": False,
                "message": "服务器无法加载作物数据"
            })
        
        # 检查作物是否存在
        if crop_name not in crop_data:
            self.log('WARNING', f"玩家 {username} 尝试购买不存在的种子 {crop_name}", 'SERVER')
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "buy_seed",
                "success": False,
                "message": "该种子不存在"
            })
        
        # 获取作物数据
        crop = crop_data[crop_name]
        
        # 检查玩家等级
        if player_data["level"] < crop.get("等级", 1):
            self.log('WARNING', f"玩家 {username} 等级不足，无法购买种子 {crop_name}", 'SERVER')
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "buy_seed",
                "success": False,
                "message": "等级不足，无法购买此种子"
            })
        
        # 检查玩家金钱
        if player_data["money"] < crop.get("花费", 0):
            self.log('WARNING', f"玩家 {username} 金钱不足，无法购买种子 {crop_name}", 'SERVER')
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "buy_seed",
                "success": False,
                "message": "金钱不足，无法购买此种子"
            })
        
        # 扣除金钱
        player_data["money"] -= crop.get("花费", 0)
        
        # 将种子添加到背包
        seed_found = False
        
        for item in player_data.get("player_bag", []):
            if item.get("name") == crop_name:
                item["count"] += 1
                seed_found = True
                break
        
        if not seed_found:
            if "player_bag" not in player_data:
                player_data["player_bag"] = []
                
            player_data["player_bag"].append({
                "name": crop_name,
                "quality": crop.get("品质", "普通"),
                "count": 1
            })
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 购买了种子 {crop_name}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "buy_seed",
            "success": True,
            "message": f"成功购买 {crop_name} 种子",
            "updated_data": {
                "money": player_data["money"],
                "player_bag": player_data["player_bag"]
            }
        })


    #处理开垦土地请求
    def _handle_dig_ground(self, client_id, message):
        """
        处理玩家开垦土地的请求
        
        参数:
            client_id (str): 客户端ID
            message (dict): 消息内容
        """
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "开垦土地", "dig_ground")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "dig_ground")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 获取地块索引
        lot_index = message.get("lot_index", -1)
        
        # 验证地块索引
        if lot_index < 0 or lot_index >= len(player_data.get("farm_lots", [])):
            self.log('WARNING', f"玩家 {username} 请求开垦无效地块 {lot_index}", 'SERVER')
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "dig_ground",
                "success": False,
                "message": "无效的地块索引"
            })
        
        # 获取地块数据
        lot = player_data["farm_lots"][lot_index]
        
        # 检查地块是否已开垦
        if lot.get("is_diged", False):
            self.log('WARNING', f"玩家 {username} 尝试开垦已开垦的地块 {lot_index}", 'SERVER')
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "dig_ground",
                "success": False,
                "message": "此地块已经开垦过了"
            })
        
        # 计算开垦费用 - 基于已开垦地块数量
        digged_count = sum(1 for l in player_data["farm_lots"] if l.get("is_diged", False))
        dig_money = digged_count * 1000
        
        # 检查玩家金钱是否足够
        if player_data["money"] < dig_money:
            self.log('WARNING', f"玩家 {username} 金钱不足，无法开垦地块 {lot_index}", 'SERVER')
            return self.send_data(client_id, {
                "type": "action_response",
                "action_type": "dig_ground",
                "success": False,
                "message": f"金钱不足，开垦此地块需要 {dig_money} 金钱"
            })
        
        # 执行开垦操作
        player_data["money"] -= dig_money
        lot["is_diged"] = True
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        self.log('INFO', f"玩家 {username} 成功开垦地块 {lot_index}，花费 {dig_money} 金钱", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "dig_ground",
            "success": True,
            "message": f"成功开垦地块，花费 {dig_money} 金钱",
            "updated_data": {
                "money": player_data["money"],
                "farm_lots": player_data["farm_lots"]
            }
        })


    #处理获取游玩时间请求
    def _handle_get_play_time(self, client_id):
        """
        处理玩家获取游玩时间的请求
        
        参数:
            client_id (str): 客户端ID
        """
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "获取游玩时间")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "play_time")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 计算当前会话的游玩时间
        login_timestamp = self.user_data[client_id].get("login_timestamp", time.time())
        current_session_seconds = int(time.time() - login_timestamp)
        
        # 格式化当前会话时间
        current_hours = current_session_seconds // 3600
        current_minutes = (current_session_seconds % 3600) // 60
        current_seconds = current_session_seconds % 60
        current_session_time = f"{current_hours}时{current_minutes}分{current_seconds}秒"
        
        # 获取最后登录时间和总游玩时间
        last_login_time = player_data.get("last_login_time", "未知")
        total_login_time = player_data.get("total_login_time", "0时0分0秒")
        
        self.log('INFO', f"玩家 {username} 请求游玩时间统计", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "play_time_response",
            "success": True,
            "last_login_time": last_login_time,
            "total_login_time": total_login_time,
            "current_session_time": current_session_time
        })
    
    
    #处理更新游玩时间请求
    def _handle_update_play_time(self, client_id):
        """
        处理玩家手动更新游玩时间的请求
        用于客户端不关闭而希望更新游玩时间的情况
        
        参数:
            client_id (str): 客户端ID
        """
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "更新游玩时间", "update_time")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "update_time")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 计算当前会话的游玩时间
        login_timestamp = self.user_data[client_id].get("login_timestamp", time.time())
        play_time_seconds = int(time.time() - login_timestamp)
        
        # 解析现有的总游玩时间
        import re
        total_time_str = player_data.get("total_login_time", "0时0分0秒")
        time_parts = re.match(r"(?:(\d+)时)?(?:(\d+)分)?(?:(\d+)秒)?", total_time_str)
        
        if time_parts:
            hours = int(time_parts.group(1) or 0)
            minutes = int(time_parts.group(2) or 0)
            seconds = int(time_parts.group(3) or 0)
            
            # 计算新的总游玩时间
            total_seconds = hours * 3600 + minutes * 60 + seconds + play_time_seconds
            new_hours = total_seconds // 3600
            new_minutes = (total_seconds % 3600) // 60
            new_seconds = total_seconds % 60
            
            # 更新总游玩时间
            player_data["total_login_time"] = f"{new_hours}时{new_minutes}分{new_seconds}秒"
            
            # 保存玩家数据
            self.save_player_data(username, player_data)
            
            # 重置登录时间戳，以便下次计算
            self.user_data[client_id]["login_timestamp"] = time.time()
            
            self.log('INFO', f"已更新玩家 {username} 的游玩时间，当前游玩时间: {play_time_seconds} 秒，总游玩时间: {player_data['total_login_time']}", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "update_time_response",
                "success": True,
                "message": "游玩时间已更新",
                "total_login_time": player_data["total_login_time"]
            })
        else:
            self.log('ERROR', f"解析玩家 {username} 的游玩时间失败", 'SERVER')
            return self.send_data(client_id, {
                "type": "update_time_response",
                "success": False,
                "message": "更新游玩时间失败，格式错误"
            })


    #处理玩家排行榜请求
    def _handle_player_rankings_request(self, client_id):
        """
        处理获取玩家排行榜的请求
        返回所有玩家的数据（按等级排序）
        
        参数:
            client_id (str): 客户端ID
        """
        import os
        import glob
        import json
        
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "获取玩家排行榜", "player_rankings")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取所有玩家存档文件
        save_files = glob.glob(os.path.join("game_saves", "*.json"))
        players_data = []
        
        for save_file in save_files:
            try:
                # 从文件名提取账号ID
                account_id = os.path.basename(save_file).split('.')[0]
                
                # 加载玩家数据
                with open(save_file, 'r', encoding='utf-8') as file:
                    player_data = json.load(file)
                
                if player_data:
                    # 统计背包中的种子数量
                    seed_count = 0
                    for item in player_data.get("player_bag", []):
                        seed_count += item.get("count", 0)
                    
                    # 获取所需的玩家信息
                    player_info = {
                        "user_name": player_data.get("user_name", account_id),
                        "player_name": player_data.get("player_name", player_data.get("user_name", account_id)),
                        "farm_name": player_data.get("farm_name", ""),
                        "level": player_data.get("level", 1),
                        "money": player_data.get("money", 0),
                        "experience": player_data.get("experience", 0),
                        "seed_count": seed_count,
                        "last_login_time": player_data.get("last_login_time", "未知"),
                        "total_login_time": player_data.get("total_login_time", "0时0分0秒")
                    }
                    
                    players_data.append(player_info)
            except Exception as e:
                self.log('ERROR', f"读取玩家 {account_id} 的数据时出错: {str(e)}", 'SERVER')
        
        # 按等级降序排序
        players_data.sort(key=lambda x: x["level"], reverse=True)
        
        self.log('INFO', f"玩家 {self.user_data[client_id].get('username')} 请求玩家排行榜，返回 {len(players_data)} 个玩家数据", 'SERVER')
        
        # 返回排行榜数据
        return self.send_data(client_id, {
            "type": "player_rankings_response",
            "success": True,
            "players": players_data
        })


    #处理作物数据请求
    def _handle_crop_data_request(self, client_id):
        """
        处理客户端请求作物数据
        
        参数:
            client_id (str): 客户端ID
        """
        import json
        
        try:
            # 读取服务器上的作物数据
            with open("config/crop_data.json", 'r', encoding='utf-8') as file:
                crop_data = json.load(file)
            
            self.log('INFO', f"向客户端 {client_id} 发送作物数据", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "crop_data_response",
                "success": True,
                "crop_data": crop_data
            })
        except Exception as e:
            self.log('ERROR', f"读取作物数据时出错: {str(e)}", 'SERVER')
            return self.send_data(client_id, {
                "type": "crop_data_response",
                "success": False,
                "message": f"无法读取作物数据: {str(e)}"
            })


    #处理验证码请求
    def _handle_verification_code_request(self, client_id, message):
        """
        处理验证码请求，向指定QQ号对应的邮箱发送验证码
        
        参数:
            client_id (str): 客户端ID
            message (dict): 消息内容
        """
        from QQEmailSend import EmailVerification
        
        # 获取QQ号
        qq_number = message.get("qq_number", "")
        
        # 验证QQ号
        import re
        if not re.match(r'^\d{5,12}$', qq_number):
            self.log('WARNING', f"验证码请求错误: QQ号 {qq_number} 格式无效", 'SERVER')
            return self.send_data(client_id, {
                "type": "verification_code_response",
                "success": False,
                "message": "QQ号格式无效，请输入5-12位数字"
            })
        
        # 生成验证码
        verification_code = EmailVerification.generate_verification_code()
        
        # 发送验证码邮件
        success, send_message = EmailVerification.send_verification_email(qq_number, verification_code)
        
        if success:
            # 保存验证码
            EmailVerification.save_verification_code(qq_number, verification_code)
            self.log('INFO', f"已向QQ号 {qq_number} 发送验证码", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "verification_code_response",
                "success": True,
                "message": "验证码已发送到您的QQ邮箱，请查收"
            })
        else:
            self.log('ERROR', f"发送验证码失败: {send_message}", 'SERVER')
            return self.send_data(client_id, {
                "type": "verification_code_response",
                "success": False,
                "message": f"发送验证码失败: {send_message}"
            })
    
    
    #处理验证码验证
    def _handle_verify_code(self, client_id, message):
        """
        处理验证码验证请求
        
        参数:
            client_id (str): 客户端ID
            message (dict): 消息内容
        """
        from QQEmailSend import EmailVerification
        
        # 获取QQ号和验证码
        qq_number = message.get("qq_number", "")
        input_code = message.get("code", "")
        
        # 验证码不能为空
        if not input_code:
            return self.send_data(client_id, {
                "type": "verify_code_response",
                "success": False,
                "message": "验证码不能为空"
            })
        
        # 验证验证码
        success, verify_message = EmailVerification.verify_code(qq_number, input_code)
        
        if success:
            self.log('INFO', f"QQ号 {qq_number} 的验证码验证成功", 'SERVER')
            return self.send_data(client_id, {
                "type": "verify_code_response",
                "success": True,
                "message": "验证成功"
            })
        else:
            self.log('WARNING', f"QQ号 {qq_number} 的验证码验证失败: {verify_message}", 'SERVER')
            return self.send_data(client_id, {
                "type": "verify_code_response",
                "success": False,
                "message": verify_message
            })


    #处理访问玩家请求
    def _handle_visit_player_request(self, client_id, message):
        """
        处理访问其他玩家农场的请求
        
        参数:
            client_id (str): 客户端ID
            message (dict): 消息内容
        """
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "访问玩家农场", "visit_player")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取要访问的玩家用户名
        target_username = message.get("target_username", "")
        
        if not target_username:
            self.log('WARNING', f"访问玩家请求缺少目标用户名", 'SERVER')
            return self.send_data(client_id, {
                "type": "visit_player_response",
                "success": False,
                "message": "缺少目标用户名"
            })
        
        # 加载目标玩家数据
        target_player_data = self.load_player_data(target_username)
        
        if not target_player_data:
            self.log('WARNING', f"无法找到玩家 {target_username} 的数据", 'SERVER')
            return self.send_data(client_id, {
                "type": "visit_player_response",
                "success": False,
                "message": f"无法找到玩家 {target_username} 的数据"
            })
        
        # 返回目标玩家的农场数据（只返回可见的数据，不包含敏感信息如密码）
        safe_player_data = {
            "user_name": target_player_data.get("user_name", target_username),
            "player_name": target_player_data.get("player_name", target_username),
            "farm_name": target_player_data.get("farm_name", ""),
            "level": target_player_data.get("level", 1),
            "money": target_player_data.get("money", 0),
            "experience": target_player_data.get("experience", 0),
            "farm_lots": target_player_data.get("farm_lots", []),
            "player_bag": target_player_data.get("player_bag", []),
            "last_login_time": target_player_data.get("last_login_time", "未知"),
            "total_login_time": target_player_data.get("total_login_time", "0时0分0秒")
        }
        
        current_username = self.user_data[client_id]["username"]
        self.log('INFO', f"玩家 {current_username} 访问了玩家 {target_username} 的农场", 'SERVER')
        
        # 记录玩家的访问状态
        self.user_data[client_id]["visiting_mode"] = True
        self.user_data[client_id]["visiting_target"] = target_username
        
        return self.send_data(client_id, {
            "type": "visit_player_response",
            "success": True,
            "message": f"成功获取玩家 {target_username} 的农场数据",
            "player_data": safe_player_data,
            "is_visiting": True
        })


    #处理返回自己农场请求
    def _handle_return_my_farm_request(self, client_id, message):
        """
        处理玩家返回自己农场的请求
        
        参数:
            client_id (str): 客户端ID
            message (dict): 消息内容
        """
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "返回自己农场", "return_my_farm")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "return_my_farm")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 清除访问状态
        self.user_data[client_id]["visiting_mode"] = False
        self.user_data[client_id]["visiting_target"] = ""
        
        self.log('INFO', f"玩家 {username} 返回了自己的农场", 'SERVER')
        
        # 返回玩家自己的农场数据
        return self.send_data(client_id, {
            "type": "return_my_farm_response",
            "success": True,
            "message": "已返回自己的农场",
            "player_data": {
                "user_name": player_data.get("user_name", username),
                "player_name": player_data.get("player_name", username),
                "farm_name": player_data.get("farm_name", ""),
                "level": player_data.get("level", 1),
                "money": player_data.get("money", 0),
                "experience": player_data.get("experience", 0),
                "farm_lots": player_data.get("farm_lots", []),
                "player_bag": player_data.get("player_bag", [])
            },
            "is_visiting": False
        })





# 使用示例
if __name__ == "__main__":
    import threading
    import sys
    
    try:
        # 创建自定义服务器
        server = TCPGameServer()
        
        # 以阻塞方式启动服务器
        server_thread = threading.Thread(target=server.start)
        server_thread.daemon = True
        server_thread.start()
        
        # 运行直到按Ctrl+C
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n程序被用户中断")
        if 'server' in locals():
            server.stop()
        sys.exit(0) 