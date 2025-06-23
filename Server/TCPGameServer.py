from TCPServer import TCPServer
import time
import json
import os
import glob
import threading
import datetime
import re

"""
萌芽农场TCP游戏服务器 - 代码结构说明
====================================================================

📁 代码组织结构：
├── 1. 初始化和生命周期管理    - 服务器启动、停止、客户端管理
├── 2. 验证和检查方法         - 版本检查、登录状态验证
├── 3. 数据管理方法          - 玩家数据读写、缓存管理
├── 4. 作物系统管理          - 作物生长、更新推送
├── 5. 消息处理路由          - 客户端消息分发处理
├── 6. 用户认证处理          - 登录、注册、验证码
├── 7. 游戏操作处理          - 种植、收获、浇水等
├── 8. 系统功能处理          - 签到、抽奖、排行榜
└── 9. 性能优化功能          - 缓存优化、批量保存

🔧 性能优化特性：
- 内存缓存系统：减少磁盘I/O操作
- 分层更新策略：在线玩家快速更新，离线玩家慢速更新
- 批量数据保存：定时批量写入，提升性能
- 智能缓存管理：LRU策略，自动清理过期数据

🎮 游戏功能模块：
- 用户系统：注册、登录、邮箱验证
- 农场系统：种植、收获、浇水、施肥
- 升级系统：经验获取、等级提升
- 社交系统：访问农场、点赞互动
- 奖励系统：每日签到、幸运抽奖
- 排行系统：玩家排行榜展示

📊 数据存储：
- 玩家数据：JSON格式存储在game_saves目录
- 配置文件：作物数据、初始模板等
- 缓存策略：内存缓存 + 定时持久化

🌐 网络通信：
- 协议：TCP长连接
- 数据格式：JSON消息
- 消息类型：请求/响应模式


====================================================================
"""

# ============================================================================
# 服务器配置参数
# ============================================================================
server_host: str = "0.0.0.0"
server_port: int = 4040
buffer_size: int = 4096
server_version: str = "1.0.3"  # 记录服务端版本


# ============================================================================
# TCP游戏服务器类
# ============================================================================
class TCPGameServer(TCPServer):
    """
    萌芽农场TCP游戏服务器
    """
    
    #==========================初始化和生命周期管理==========================
    #初始化操作
    def __init__(self, server_host=server_host, server_port=server_port, buffer_size=buffer_size):
        """初始化TCP游戏服务器"""
        super().__init__(server_host, server_port, buffer_size)
        
        # 基础数据存储
        self.user_data = {}  # 存储用户相关数据
        self.crop_timer = None  # 作物生长计时器
        
        # 性能优化相关配置
        self._init_performance_settings()
        
        self.log('INFO', f"萌芽农场TCP游戏服务器初始化完成 - 版本: {server_version}", 'SERVER')
        
        # 启动定时器
        self.start_crop_growth_timer()
        self.start_batch_save_timer()
    
    #初始化性能操作
    def _init_performance_settings(self):
        """初始化性能优化配置"""
        self.player_cache = {}  # 玩家数据内存缓存
        self.dirty_players = set()  # 需要保存到磁盘的玩家列表
        self.last_save_time = time.time()  # 上次批量保存时间
        self.save_interval = 30  # 批量保存间隔（秒）
        self.update_counter = 0  # 更新计数器
        self.slow_update_interval = 10  # 慢速更新间隔（每10秒进行一次完整更新）
        self.active_players_cache = {}  # 活跃玩家缓存
        self.cache_expire_time = 300  # 缓存过期时间（5分钟）
    
    #启动作物生长计时器
    def start_crop_growth_timer(self):
        """启动作物生长计时器，每秒更新一次"""
        try:
            self.update_crops_growth_optimized()
        except Exception as e:
            self.log('ERROR', f"作物生长更新时出错: {str(e)}", 'SERVER')
        
        # 创建下一个计时器
        self.crop_timer = threading.Timer(1.0, self.start_crop_growth_timer)
        self.crop_timer.daemon = True
        self.crop_timer.start()
    
    #启动批量报错计时器
    def start_batch_save_timer(self):
        """启动批量保存计时器"""
        try:
            self.batch_save_dirty_players()
            self.cleanup_expired_cache()
        except Exception as e:
            self.log('ERROR', f"批量保存时出错: {str(e)}", 'SERVER')
        
        # 创建下一个批量保存计时器
        batch_timer = threading.Timer(self.save_interval, self.start_batch_save_timer)
        batch_timer.daemon = True
        batch_timer.start()
    
    #获取服务器统计信息
    def get_server_stats(self):
        """获取服务器统计信息"""
        online_players = len([cid for cid in self.user_data if self.user_data[cid].get("logged_in", False)])
        return {
            "cached_players": len(self.player_cache),
            "online_players": online_players,
            "total_connections": len(self.clients)
        }
    
    #停止服务器
    def stop(self):
        """停止服务器"""
        self.log('INFO', "正在停止服务器...", 'SERVER')
        
        # 停止作物生长计时器
        if self.crop_timer:
            self.crop_timer.cancel()
            self.crop_timer = None
            self.log('INFO', "作物生长计时器已停止", 'SERVER')
        
        # 强制保存所有缓存数据
        self.log('INFO', "正在保存所有玩家数据...", 'SERVER')
        saved_count = self.force_save_all_data()
        self.log('INFO', f"已保存 {saved_count} 个玩家的数据", 'SERVER')
        
        # 显示服务器统计信息
        stats = self.get_server_stats()
        self.log('INFO', f"服务器统计 - 缓存玩家: {stats['cached_players']}, 在线玩家: {stats['online_players']}, 总连接: {stats['total_connections']}", 'SERVER')
        
        # 调用父类方法完成实际停止
        super().stop()
    
    #==========================客户端连接管理==========================
    #移除客户端
    def _remove_client(self, client_id):
        """覆盖客户端移除方法，添加用户离开通知和数据保存"""
        if client_id in self.clients:
            username = self.user_data.get(client_id, {}).get("username", client_id)
            
            # 处理已登录用户的离开
            if client_id in self.user_data and self.user_data[client_id].get("logged_in", False):
                self._update_player_logout_time(client_id, username)
                
                # 立即保存离线玩家的数据
                if username and username in self.player_cache:
                    self.save_player_data_immediate(username)
                    self.dirty_players.discard(username)
                    self.log('INFO', f"已立即保存离线玩家 {username} 的数据", 'SERVER')
                
                self.log('INFO', f"用户 {username} 登出", 'SERVER')
            
            # 广播用户离开消息
            self.broadcast({
                "type": "user_left",
                "user_id": client_id,
                "timestamp": time.time(),
                "remaining_users": len(self.clients) - 1
            }, exclude=[client_id])
            
            # 清理用户数据
            if client_id in self.user_data:
                del self.user_data[client_id]
                
            self.log('INFO', f"用户 {username} 已离开游戏", 'SERVER')
        
        super()._remove_client(client_id)
    

    #==========================验证和检查方法==========================
    #检查用户是否已登录的通用方法
    def _check_user_logged_in(self, client_id, action_name, action_type=None):
        """检查用户是否已登录的通用方法"""
        if client_id not in self.user_data or not self.user_data[client_id].get("logged_in", False):
            self.log('WARNING', f"未登录用户 {client_id} 尝试{action_name}", 'SERVER')
            
            response = {
                "success": False,
                "message": "您需要先登录才能执行此操作"
            }
            
            if action_type:
                response["type"] = "action_response"
                response["action_type"] = action_type
            else:
                response["type"] = f"{action_name}_response"
            
            return False, response
        
        return True, None
    

    #==========================数据管理方法==========================
    #加载玩家数据
    def load_player_data(self, account_id):
        """从缓存或文件加载玩家数据（优化版本）"""
        # 先检查内存缓存
        if account_id in self.player_cache:
            self._update_cache_access_time(account_id)
            return self.player_cache[account_id]
        
        # 缓存未命中，从文件读取
        return self._load_player_data_from_file(account_id)
    
    #更新缓存访问时间
    def _update_cache_access_time(self, account_id):
        """更新缓存访问时间"""
        if account_id not in self.active_players_cache:
            self.active_players_cache[account_id] = {}
        self.active_players_cache[account_id]["last_access"] = time.time()
    
    #从文件里加载玩家数据
    def _load_player_data_from_file(self, account_id):
        """从文件加载玩家数据"""
        file_path = os.path.join("game_saves", f"{account_id}.json")
        
        try:
            if os.path.exists(file_path):
                with open(file_path, 'r', encoding='utf-8') as file:
                    player_data = json.load(file)
                
                # 存入缓存
                self.player_cache[account_id] = player_data
                self.active_players_cache[account_id] = {
                    "last_access": time.time(),
                    "is_online": account_id in self.user_data and self.user_data[account_id].get("logged_in", False)
                }
                
                return player_data
            return None
        except Exception as e:
            self.log('ERROR', f"读取玩家 {account_id} 的数据时出错: {str(e)}", 'SERVER')
            return None
    
    #保存玩家数据到缓存
    def save_player_data(self, account_id, player_data):
        """保存玩家数据到缓存"""
        # 更新内存缓存
        self.player_cache[account_id] = player_data
        
        # 标记为脏数据，等待批量保存
        self.dirty_players.add(account_id)
        
        # 更新活跃缓存
        self._update_cache_access_time(account_id)
        
        return True
    
    #保存玩家数据到磁盘
    def save_player_data_immediate(self, account_id):
        """立即保存玩家数据到磁盘"""
        if account_id not in self.player_cache:
            return False
            
        file_path = os.path.join("game_saves", f"{account_id}.json")
        
        try:
            with open(file_path, 'w', encoding='utf-8') as file:
                json.dump(self.player_cache[account_id], file, indent=2, ensure_ascii=False)
            return True
        except Exception as e:
            self.log('ERROR', f"保存玩家 {account_id} 的数据时出错: {str(e)}", 'SERVER')
            return False
    
    #加载玩家数据
    def _load_player_data_with_check(self, client_id, action_type=None):
        """加载玩家数据并进行错误检查的通用方法"""
        username = self.user_data[client_id]["username"]
        player_data = self.load_player_data(username)
        
        if not player_data:
            self.log('ERROR', f"无法加载玩家 {username} 的数据", 'SERVER')
            
            response = {
                "success": False,
                "message": "无法加载玩家数据"
            }
            
            if action_type:
                response["type"] = "action_response"
                response["action_type"] = action_type
            else:
                response["type"] = "data_response"
            
            return None, username, response
        
        return player_data, username, None
    
    #加载作物配置数据
    def _load_crop_data(self):
        """加载作物配置数据"""
        try:
            with open("config/crop_data.json", 'r', encoding='utf-8') as file:
                return json.load(file)
        except Exception as e:
            self.log('ERROR', f"无法加载作物数据: {str(e)}", 'SERVER')
            return {}
    
    #更新玩家登录时间
    def _update_player_logout_time(self, client_id, username):
        """更新玩家登出时间和总游玩时间"""
        login_timestamp = self.user_data[client_id].get("login_timestamp", time.time())
        play_time_seconds = int(time.time() - login_timestamp)
        
        # 清除访问状态
        self.user_data[client_id]["visiting_mode"] = False
        self.user_data[client_id]["visiting_target"] = ""
        
        # 加载和更新玩家数据
        player_data = self.load_player_data(username)
        if player_data:
            self._update_total_play_time(player_data, play_time_seconds)
            self.save_player_data(username, player_data)
            self.log('INFO', f"用户 {username} 本次游玩时间: {play_time_seconds} 秒，总游玩时间: {player_data['total_login_time']}", 'SERVER')
    
    #更新总游玩时间
    def _update_total_play_time(self, player_data, play_time_seconds):
        """更新总游玩时间"""
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
    
    #==========================作物系统管理==========================
    #优化的作物生长更新系统
    def update_crops_growth_optimized(self):
        """优化的作物生长更新系统"""
        self.update_counter += 1
        
        # 每秒快速更新在线玩家
        self.update_online_players_crops()
        
        # 每10秒进行一次慢速更新（离线玩家和深度检查）
        if self.update_counter % self.slow_update_interval == 0:
            self.update_offline_players_crops()
    
    #快速更新在线玩家的作物
    def update_online_players_crops(self):
        """快速更新在线玩家的作物"""
        for client_id, user_info in self.user_data.items():
            if not user_info.get("logged_in", False):
                continue
                
            username = user_info.get("username")
            if not username:
                continue
            
            try:
                player_data = self.load_player_data(username)
                if not player_data:
                    continue
                
                if self.update_player_crops_fast(player_data, username):
                    self.save_player_data(username, player_data)
                    self._push_crop_update_to_player(username, player_data)
                    
            except Exception as e:
                self.log('ERROR', f"快速更新在线玩家 {username} 作物时出错: {str(e)}", 'SERVER')
    
    #慢速更新离线玩家的作物
    def update_offline_players_crops(self):
        """慢速更新离线玩家的作物（每10秒一次）"""
        import glob
        
        try:
            save_files = glob.glob(os.path.join("game_saves", "*.json"))
            offline_count = 0
            updated_count = 0
            
            for save_file in save_files:
                account_id = os.path.basename(save_file).split('.')[0]
                
                # 跳过在线玩家
                is_online = any(
                    user_info.get("username") == account_id and user_info.get("logged_in", False) 
                    for user_info in self.user_data.values()
                )
                
                if is_online:
                    continue
                
                offline_count += 1
                
                player_data = self.load_player_data(account_id)
                if not player_data:
                    continue
                
                if self.update_player_crops_slow(player_data, account_id):
                    self.save_player_data(account_id, player_data)
                    updated_count += 1
            
            if updated_count > 0:
                self.log('INFO', f"慢速更新：检查了 {offline_count} 个离线玩家，更新了 {updated_count} 个", 'SERVER')
                
        except Exception as e:
            self.log('ERROR', f"慢速更新离线玩家作物时出错: {str(e)}", 'SERVER')
    
    #快速更新单个玩家的作物
    def update_player_crops_fast(self, player_data, account_id):
        """快速更新单个玩家的作物（在线玩家用）"""
        return self.update_player_crops_common(player_data, account_id, 1)
    
    #慢速更新单个玩家的作物
    def update_player_crops_slow(self, player_data, account_id):
        """慢速更新单个玩家的作物（离线玩家用，补偿倍数）"""
        return self.update_player_crops_common(player_data, account_id, self.slow_update_interval)
    
    #通用的作物更新逻辑
    def update_player_crops_common(self, player_data, account_id, time_multiplier):
        """通用的作物更新逻辑"""
        growth_updated = False
        
        for farm_lot in player_data.get("farm_lots", []):
            if (farm_lot.get("crop_type") and farm_lot.get("is_planted") and 
                not farm_lot.get("is_dead") and farm_lot["grow_time"] < farm_lot["max_grow_time"]):
                
                # 计算生长速度倍数
                growth_multiplier = 1.0
                
                # 土地等级影响 - 根据不同等级应用不同倍数
                land_level = farm_lot.get("土地等级", 0)
                land_speed_multipliers = {
                    0: 1.0,   # 默认土地：正常生长速度
                    1: 2.0,   # 黄土地：2倍速
                    2: 4.0,   # 红土地：4倍速
                    3: 6.0,   # 紫土地：6倍速
                    4: 10.0   # 黑土地：10倍速
                }
                growth_multiplier *= land_speed_multipliers.get(land_level, 1.0)
                
                # 施肥影响
                if farm_lot.get("已施肥", False) and "施肥时间" in farm_lot:
                    fertilize_time = farm_lot.get("施肥时间", 0)
                    current_time = time.time()
                    if current_time - fertilize_time <= 600:  # 10分钟内
                        growth_multiplier *= 2.0
                    else:
                        # 施肥效果过期
                        farm_lot["已施肥"] = False
                        if "施肥时间" in farm_lot:
                            del farm_lot["施肥时间"]
                
                # 应用生长速度倍数和时间补偿
                growth_increase = int(growth_multiplier * time_multiplier)
                if growth_increase < 1:
                    growth_increase = 1
                
                farm_lot["grow_time"] += growth_increase
                growth_updated = True
        
        return growth_updated
    
    #向在线玩家推送作物生长更新
    def _push_crop_update_to_player(self, account_id, player_data):
        """向在线玩家推送作物生长更新"""
        client_id = self._find_client_by_username(account_id)
        
        if client_id:
            visiting_mode = self.user_data[client_id].get("visiting_mode", False)
            visiting_target = self.user_data[client_id].get("visiting_target", "")
            
            if visiting_mode and visiting_target:
                self._send_visiting_update(client_id, visiting_target)
            else:
                self._send_normal_update(client_id, player_data)
    
    #根据用户名查找客户端ID
    def _find_client_by_username(self, username):
        """根据用户名查找客户端ID"""
        for cid, user_info in self.user_data.items():
            if user_info.get("username") == username and user_info.get("logged_in", False):
                return cid
        return None
    
    #发送访问模式的更新
    def _send_visiting_update(self, client_id, visiting_target):
        """发送访问模式的更新"""
        target_player_data = self.load_player_data(visiting_target)
        if target_player_data:
            target_client_id = self._find_client_by_username(visiting_target)
            
            update_message = {
                "type": "crop_update",
                "farm_lots": target_player_data.get("farm_lots", []),
                "timestamp": time.time(),
                "is_visiting": True,
                "visited_player": visiting_target,
                "target_online": target_client_id is not None
            }
            self.send_data(client_id, update_message)
    
    #发送正常模式的更新
    def _send_normal_update(self, client_id, player_data):
        """发送正常模式的更新"""
        update_message = {
            "type": "crop_update",
            "farm_lots": player_data.get("farm_lots", []),
            "timestamp": time.time(),
            "is_visiting": False
        }
        self.send_data(client_id, update_message)






# =======================服务端与客户端通信注册==========================================
    #服务端与客户端通用消息处理-这个是服务端与客户端通信的核心中的核心
    def _handle_message(self, client_id, message):
        """接收客户端消息并路由到对应处理函数"""
        message_type = message.get("type", "")
        
        # 用户认证相关
        if message_type == "greeting":#默认欢迎
            return self._handle_greeting(client_id, message)
        elif message_type == "login":#玩家登录
            return self._handle_login(client_id, message)
        elif message_type == "register":#玩家注册
            return self._handle_register(client_id, message)
        elif message_type == "request_verification_code":#验证码请求
            return self._handle_verification_code_request(client_id, message)
        elif message_type == "verify_code":#验证码
            return self._handle_verify_code(client_id, message)
        
        #---------------------------------------------------------------------------
        # 游戏操作相关 
        elif message_type == "harvest_crop":#收获作物
            return self._handle_harvest_crop(client_id, message)
        elif message_type == "plant_crop":#种植作物
            return self._handle_plant_crop(client_id, message)
        elif message_type == "buy_seed":#购买种子
            return self._handle_buy_seed(client_id, message)
        elif message_type == "dig_ground":#开垦土地
            return self._handle_dig_ground(client_id, message)
        elif message_type == "remove_crop":#铲除作物
            return self._handle_remove_crop(client_id, message)
        elif message_type == "water_crop":#浇水
            return self._handle_water_crop(client_id, message)
        elif message_type == "fertilize_crop":#施肥
            return self._handle_fertilize_crop(client_id, message)
        elif message_type == "upgrade_land":#升级土地
            return self._handle_upgrade_land(client_id, message)
        elif message_type == "buy_new_ground":#添加新的土地
            return self._handle_buy_new_ground(client_id, message)
        elif message_type == "like_player":#点赞玩家
            return self._handle_like_player(client_id, message)
        elif message_type == "request_online_players":#请求在线玩家
            return self._handle_online_players_request(client_id, message)
        elif message_type == "get_play_time":#获取游玩时间
            return self._handle_get_play_time(client_id)
        elif message_type == "update_play_time":#更新游玩时间
            return self._handle_update_play_time(client_id)
        elif message_type == "request_player_rankings":#请求玩家排行榜
            return self._handle_player_rankings_request(client_id)
        elif message_type == "request_crop_data":#请求作物数据
            return self._handle_crop_data_request(client_id)
        elif message_type == "visit_player":#拜访其他玩家农场
            return self._handle_visit_player_request(client_id, message)
        elif message_type == "return_my_farm":#返回我的农场
            return self._handle_return_my_farm_request(client_id, message)
        elif message_type == "daily_check_in":#每日签到
            return self._handle_daily_check_in_request(client_id, message)
        elif message_type == "get_check_in_data":#获取签到数据
            return self._handle_get_check_in_data_request(client_id, message)
        elif message_type == "lucky_draw":#幸运抽奖
            return self._handle_lucky_draw_request(client_id, message)
        elif message_type == "claim_new_player_gift":#领取新手大礼包
            return self._handle_new_player_gift_request(client_id, message)
        elif message_type == "ping":#客户端ping请求
            return self._handle_ping_request(client_id, message)
        #---------------------------------------------------------------------------

        elif message_type == "message":#处理聊天消息（暂未实现）
            return self._handle_chat_message(client_id, message)
        else:
            return super()._handle_message(client_id, message)
# ========================================================================




#==========================用户认证相关==========================
    #处理问候消息
    def _handle_greeting(self, client_id, message):
        """处理问候消息"""
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
    
    #处理玩家登录
    def _handle_login(self, client_id, message):
        """处理登录消息"""
        username = message.get("username", "")
        password = message.get("password", "")
        client_version = message.get("client_version", "")
        
        # 验证客户端版本
        version_valid, version_response = self._check_client_version(client_version, f"用户 {username} 登录")
        if not version_valid:
            version_response["type"] = "login_response"
            version_response["status"] = "failed"
            return self.send_data(client_id, version_response)
        
        # 读取玩家数据
        player_data = self.load_player_data(username)
        
        if player_data and player_data.get("user_password") == password:
            # 登录成功
            self.log('INFO', f"用户 {username} 登录成功", 'SERVER')
            
            # 更新最后登录时间
            current_time = datetime.datetime.now()
            player_data["last_login_time"] = current_time.strftime("%Y年%m月%d日%H时%M分%S秒")
            
            # 检查并更新体力值
            stamina_updated = self._check_and_update_stamina(player_data)
            if stamina_updated:
                self.log('INFO', f"玩家 {username} 体力值已更新：{player_data.get('体力值', 20)}", 'SERVER')
            
            # 保存用户会话信息
            self.user_data[client_id] = {
                "username": username,
                "last_active": time.time(),
                "messages_count": 0,
                "logged_in": True,
                "login_timestamp": time.time()
            }
            
            # 保存更新后的玩家数据
            self.save_player_data(username, player_data)
            
            # 发送初始数据
            self._send_initial_login_data(client_id, player_data)
            
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
    
    #辅助函数-发送登录后初始数据
    def _send_initial_login_data(self, client_id, player_data):
        """发送登录后的初始数据"""
        # 立即向客户端发送一次作物状态
        farm_lots = player_data.get("farm_lots", [])
        initial_crop_update = {
            "type": "crop_update",
            "farm_lots": farm_lots,
            "timestamp": time.time()
        }
        self.send_data(client_id, initial_crop_update)
        
        # 发送最新的作物数据配置
        crop_data = self._load_crop_data()
        if crop_data:
            crop_data_message = {
                "type": "crop_data_response",
                "success": True,
                "crop_data": crop_data
            }
            self.send_data(client_id, crop_data_message)
            self.log('INFO', f"已向登录用户发送作物数据配置", 'SERVER')
    

    #处理注册消息
    def _handle_register(self, client_id, message):
        """处理注册消息"""
        username = message.get("username", "")
        password = message.get("password", "")
        farm_name = message.get("farm_name", "")
        player_name = message.get("player_name", "")
        verification_code = message.get("verification_code", "")
        client_version = message.get("client_version", "")
        
        # 验证客户端版本
        version_valid, version_response = self._check_client_version(client_version, f"用户 {username} 注册")
        if not version_valid:
            version_response["type"] = "register_response"
            version_response["status"] = "failed"
            return self.send_data(client_id, version_response)
        
        # 验证必填字段
        if not username or not password:
            return self._send_register_error(client_id, "用户名或密码不能为空")
        
        # 验证用户名是否是QQ号
        if not self._validate_qq_number(username):
            return self._send_register_error(client_id, "用户名必须是5-12位的QQ号码")
        
        # 验证验证码
        if verification_code:
            from QQEmailSend import EmailVerification
            success, verify_message = EmailVerification.verify_code(username, verification_code)
            if not success:
                return self._send_register_error(client_id, f"验证码错误: {verify_message}")
        
        # 检查用户是否已存在
        file_path = os.path.join("game_saves", f"{username}.json")
        if os.path.exists(file_path):
            return self._send_register_error(client_id, "该用户名已被注册")
        
        # 创建新用户
        return self._create_new_user(client_id, username, password, farm_name, player_name)
    
        #检查客户端版本是否与服务端匹配
    
        #创建新用户
   
    #辅助函数-发送注册错误处理
    def _send_register_error(self, client_id, message):
        """发送注册错误响应"""
        self.log('WARNING', f"注册失败: {message}", 'SERVER')
        return self.send_data(client_id, {
            "type": "register_response",
            "status": "failed",
            "message": message
        })
    

    #辅助函数-创建新用户
    def _create_new_user(self, client_id, username, password, farm_name, player_name):
        """创建新用户"""
        try:
            # 从模板加载初始玩家数据
            template_path = os.path.join("config", "initial_player_data_template.json")
            if not os.path.exists(template_path):
                return self._send_register_error(client_id, "服务器配置错误，无法注册新用户")
                
            with open(template_path, 'r', encoding='utf-8') as file:
                player_data = json.load(file)
                
            # 更新玩家数据
            player_data.update({
                "user_name": username,
                "user_password": password,
                "farm_name": farm_name or "我的农场",
                "player_name": player_name or username,
                "experience": player_data.get("experience", 0),
                "level": player_data.get("level", 1),
                "money": player_data.get("money", 1000)
            })
            
            # 确保农场地块存在
            if "farm_lots" not in player_data:
                player_data["farm_lots"] = []
                for i in range(40):
                    player_data["farm_lots"].append({
                        "crop_type": "",
                        "grow_time": 0,
                        "is_dead": False,
                        "is_diged": i < 5,  # 默认开垦前5块地
                        "is_planted": False,
                        "max_grow_time": 5 if i >= 5 else 3
                    })
            
            if "player_bag" not in player_data:
                player_data["player_bag"] = []
            
            # 更新注册时间和登录时间
            current_time = datetime.datetime.now()
            time_str = current_time.strftime("%Y年%m月%d日%H时%M分%S秒")
            player_data["last_login_time"] = time_str
            
            if "total_login_time" not in player_data:
                player_data["total_login_time"] = "0时0分0秒"
            
            # 保存新用户数据
            file_path = os.path.join("game_saves", f"{username}.json")
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
            return self._send_register_error(client_id, f"注册过程中出现错误: {str(e)}")
    
    #辅助函数-客户端版本检查
    def _check_client_version(self, client_version, action_name="操作"):
        """检查客户端版本是否与服务端匹配"""
        if client_version != server_version:
            self.log('WARNING', f"{action_name}失败: 版本不匹配 (客户端: {client_version}, 服务端: {server_version})", 'SERVER')
            
            response = {
                "success": False,
                "message": f"版本不匹配！客户端版本: {client_version},\n 服务端版本: {server_version}，请更新客户端"
            }
            return False, response
        
        return True, None
    
    #处理验证码请求
    def _handle_verification_code_request(self, client_id, message):
        """处理验证码请求"""
        from QQEmailSend import EmailVerification
        
        qq_number = message.get("qq_number", "")
        
        # 验证QQ号
        if not self._validate_qq_number(qq_number):
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
        """处理验证码验证"""
        from QQEmailSend import EmailVerification
        
        qq_number = message.get("qq_number", "")
        input_code = message.get("code", "")
        
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
    
        #验证QQ号格式
    
    #辅助函数-验证QQ号格式
    def _validate_qq_number(self, qq_number):
        """验证QQ号格式"""
        return re.match(r'^\d{5,12}$', qq_number) is not None
    
#==========================用户认证相关==========================






#==========================收获作物处理==========================
    #处理收获作物请求
    def _handle_harvest_crop(self, client_id, message):
        """处理收获作物请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "收获作物", "harvest_crop")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取当前操作用户的数据
        current_player_data, current_username, response = self._load_player_data_with_check(client_id, "harvest_crop")
        if not current_player_data:
            return self.send_data(client_id, response)
        
        lot_index = message.get("lot_index", -1)
        target_username = message.get("target_username", "")
        
        # 确定操作目标：如果有target_username就是访问模式（偷菜），否则是自己的农场
        if target_username and target_username != current_username:
            # 访问模式：偷菜（收益给自己，清空目标玩家的作物）
            target_player_data = self.load_player_data(target_username)
            if not target_player_data:
                return self._send_action_error(client_id, "harvest_crop", f"无法找到玩家 {target_username} 的数据")
            
            # 验证地块索引
            if lot_index < 0 or lot_index >= len(target_player_data.get("farm_lots", [])):
                return self._send_action_error(client_id, "harvest_crop", "无效的地块索引")
            
            target_lot = target_player_data["farm_lots"][lot_index]
            
            # 检查地块状态
            if not target_lot.get("is_planted", False) or not target_lot.get("crop_type", ""):
                return self._send_action_error(client_id, "harvest_crop", "此地块没有种植作物")
            
            if target_lot.get("is_dead", False):
                # 处理已死亡的作物（只清理，不给收益）
                target_lot["is_planted"] = False
                target_lot["crop_type"] = ""
                target_lot["grow_time"] = 0
                
                self.save_player_data(target_username, target_player_data)
                self._push_crop_update_to_player(target_username, target_player_data)
                
                return self.send_data(client_id, {
                    "type": "action_response",
                    "action_type": "harvest_crop",
                    "success": True,
                    "message": f"已帮助 {target_username} 清理死亡的作物",
                    "updated_data": {
                        "money": current_player_data["money"],
                        "experience": current_player_data["experience"],
                        "level": current_player_data["level"]
                    }
                })
            
            if target_lot["grow_time"] < target_lot["max_grow_time"]:
                return self._send_action_error(client_id, "harvest_crop", "作物尚未成熟，无法偷菜")
            
            # 处理偷菜
            return self._process_steal_crop(client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index)
        else:
            # 正常模式：收获自己的作物
            # 验证地块索引
            if lot_index < 0 or lot_index >= len(current_player_data.get("farm_lots", [])):
                return self._send_action_error(client_id, "harvest_crop", "无效的地块索引")
            
            lot = current_player_data["farm_lots"][lot_index]
            
            # 检查地块状态
            if not lot.get("is_planted", False) or not lot.get("crop_type", ""):
                return self._send_action_error(client_id, "harvest_crop", "此地块没有种植作物")
            
            if lot.get("is_dead", False):
                # 处理已死亡的作物
                lot["is_planted"] = False
                lot["crop_type"] = ""
                lot["grow_time"] = 0
                
                self.save_player_data(current_username, current_player_data)
                self._push_crop_update_to_player(current_username, current_player_data)
                
                return self.send_data(client_id, {
                    "type": "action_response",
                    "action_type": "harvest_crop",
                    "success": True,
                    "message": "已铲除死亡的作物",
                    "updated_data": {
                        "money": current_player_data["money"],
                        "experience": current_player_data["experience"],
                        "level": current_player_data["level"]
                    }
                })
            
            if lot["grow_time"] < lot["max_grow_time"]:
                return self._send_action_error(client_id, "harvest_crop", "作物尚未成熟")
            
            # 处理正常收获
            return self._process_harvest(client_id, current_player_data, current_username, lot, lot_index)

    #辅助函数-处理作物收获
    def _process_harvest(self, client_id, player_data, username, lot, lot_index):
        """处理作物收获逻辑"""
        # 读取作物配置
        crop_data = self._load_crop_data()
        
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
        lot["已浇水"] = False
        lot["已施肥"] = False
        
        # 清除施肥时间戳
        if "施肥时间" in lot:
            del lot["施肥时间"]
        
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
    
    #辅助函数-处理偷菜逻辑（访问模式下收获其他玩家作物的操作）
    def _process_steal_crop(self, client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index):
        """处理偷菜逻辑（收益给当前玩家，清空目标玩家的作物）"""
        # 偷菜体力值消耗
        stamina_cost = 2
        
        # 检查并更新当前玩家的体力值
        self._check_and_update_stamina(current_player_data)
        
        # 检查体力值是否足够
        if not self._check_stamina_sufficient(current_player_data, stamina_cost):
            return self._send_action_error(client_id, "harvest_crop", f"体力值不足，偷菜需要 {stamina_cost} 点体力，当前体力：{current_player_data.get('体力值', 0)}")
        
        # 读取作物配置
        crop_data = self._load_crop_data()
        
        # 获取作物收益和经验（偷菜获得的收益稍微少一些，比如80%）
        crop_type = target_lot["crop_type"]
        if crop_type in crop_data:
            crop_income = int((crop_data[crop_type].get("收益", 100) + crop_data[crop_type].get("花费", 0)) * 0.8)  # 偷菜获得80%收益
            crop_exp = int(crop_data[crop_type].get("经验", 10) * 0.5)  # 偷菜获得50%经验
        else:
            # 默认收益
            crop_income = 80
            crop_exp = 5
        
        # 消耗当前玩家的体力值
        stamina_success, stamina_message = self._consume_stamina(current_player_data, stamina_cost, "偷菜")
        if not stamina_success:
            return self._send_action_error(client_id, "harvest_crop", stamina_message)
        
        # 更新当前玩家数据（获得收益）
        current_player_data["money"] += crop_income
        current_player_data["experience"] += crop_exp
        
        # 检查当前玩家升级
        level_up_experience = 100 * current_player_data["level"]
        if current_player_data["experience"] >= level_up_experience:
            current_player_data["level"] += 1
            current_player_data["experience"] -= level_up_experience
            self.log('INFO', f"玩家 {current_username} 升级到 {current_player_data['level']} 级", 'SERVER')
        
        # 清理目标玩家的地块
        target_lot["is_planted"] = False
        target_lot["crop_type"] = ""
        target_lot["grow_time"] = 0
        target_lot["已浇水"] = False
        target_lot["已施肥"] = False
        
        # 清除施肥时间戳
        if "施肥时间" in target_lot:
            del target_lot["施肥时间"]
        
        # 保存两个玩家的数据
        self.save_player_data(current_username, current_player_data)
        self.save_player_data(target_username, target_player_data)
        
        # 向目标玩家推送作物更新（如果在线）
        self._push_crop_update_to_player(target_username, target_player_data)
        
        self.log('INFO', f"玩家 {current_username} 偷了玩家 {target_username} 地块 {lot_index} 的作物，获得 {crop_income} 金钱和 {crop_exp} 经验", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "harvest_crop",
            "success": True,
            "message": f"偷菜成功！从 {target_username} 那里获得 {crop_income} 金钱和 {crop_exp} 经验，{stamina_message}",
            "updated_data": {
                "money": current_player_data["money"],
                "experience": current_player_data["experience"],
                "level": current_player_data["level"],
                "体力值": current_player_data["体力值"]
            }
        })
#==========================收获作物处理==========================




#==========================种植作物处理==========================
    #处理种植作物请求 
    def _handle_plant_crop(self, client_id, message):
        """处理种植作物请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "种植作物", "plant_crop")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "plant_crop")
        if not player_data:
            return self.send_data(client_id, response)
        
        lot_index = message.get("lot_index", -1)
        crop_name = message.get("crop_name", "")
        
        # 验证参数
        if lot_index < 0 or lot_index >= len(player_data.get("farm_lots", [])):
            return self._send_action_error(client_id, "plant_crop", "无效的地块索引")
        
        lot = player_data["farm_lots"][lot_index]
        
        # 检查地块状态
        if not lot.get("is_diged", False):
            return self._send_action_error(client_id, "plant_crop", "此地块尚未开垦")
        
        if lot.get("is_planted", False):
            return self._send_action_error(client_id, "plant_crop", "此地块已经种植了作物")
        
        # 处理种植
        return self._process_planting(client_id, player_data, username, lot, crop_name)
    
    #辅助函数-处理作物种植逻辑
    def _process_planting(self, client_id, player_data, username, lot, crop_name):
        """处理作物种植逻辑"""
        # 读取作物配置
        crop_data = self._load_crop_data()
        
        # 检查玩家背包中是否有此种子
        seed_found = False
        seed_index = -1
        
        for i, item in enumerate(player_data.get("player_bag", [])):
            if item.get("name") == crop_name:
                seed_found = True
                seed_index = i
                break
        
        if not seed_found:
            return self._send_action_error(client_id, "plant_crop", "背包中没有此种子")
        
        # 获取作物生长时间
        if crop_name in crop_data:
            grow_time = crop_data[crop_name].get("生长时间", 600)
        else:
            grow_time = 600
        
        # 从背包中减少种子数量
        player_data["player_bag"][seed_index]["count"] -= 1
        
        # 如果种子用完，从背包中移除
        if player_data["player_bag"][seed_index]["count"] <= 0:
            player_data["player_bag"].pop(seed_index)
        
        # 更新地块数据
        lot.update({
            "is_planted": True,
            "crop_type": crop_name,
            "grow_time": 0,
            "max_grow_time": grow_time,
            "is_dead": False,
            "已浇水": False,
            "已施肥": False
        })
        
        # 清除施肥时间戳
        if "施肥时间" in lot:
            del lot["施肥时间"]
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        self.log('INFO', f"玩家 {username} 种植了 {crop_name}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "plant_crop",
            "success": True,
            "message": f"成功种植 {crop_name}",
            "updated_data": {
                "player_bag": player_data["player_bag"]
            }
        })
#==========================种植作物处理==========================




#==========================购买种子处理==========================
    #处理购买种子请求
    def _handle_buy_seed(self, client_id, message):
        """处理购买种子请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "购买种子", "buy_seed")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "buy_seed")
        if not player_data:
            return self.send_data(client_id, response)
        
        crop_name = message.get("crop_name", "")
        
        # 加载作物配置
        crop_data = self._load_crop_data()
        if not crop_data:
            return self._send_action_error(client_id, "buy_seed", "服务器无法加载作物数据")
        
        # 检查作物是否存在
        if crop_name not in crop_data:
            return self._send_action_error(client_id, "buy_seed", "该种子不存在")
        
        # 处理购买
        return self._process_seed_purchase(client_id, player_data, username, crop_name, crop_data[crop_name])
    
    #处理种子购买逻辑
    def _process_seed_purchase(self, client_id, player_data, username, crop_name, crop):
        """处理种子购买逻辑"""
        # 检查玩家等级
        if player_data["level"] < crop.get("等级", 1):
            return self._send_action_error(client_id, "buy_seed", "等级不足，无法购买此种子")
        
        # 检查玩家金钱
        if player_data["money"] < crop.get("花费", 0):
            return self._send_action_error(client_id, "buy_seed", "金钱不足，无法购买此种子")
        
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
    
#==========================购买种子处理==========================




#==========================开垦土地处理==========================
    #处理开垦土地请求
    def _handle_dig_ground(self, client_id, message):
        """处理开垦土地请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "开垦土地", "dig_ground")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "dig_ground")
        if not player_data:
            return self.send_data(client_id, response)
        
        lot_index = message.get("lot_index", -1)
        
        # 验证地块索引
        if lot_index < 0 or lot_index >= len(player_data.get("farm_lots", [])):
            return self._send_action_error(client_id, "dig_ground", "无效的地块索引")
        
        lot = player_data["farm_lots"][lot_index]
        
        # 检查地块是否已开垦
        if lot.get("is_diged", False):
            return self._send_action_error(client_id, "dig_ground", "此地块已经开垦过了")
        
        # 处理开垦
        return self._process_digging(client_id, player_data, username, lot, lot_index)
    
    #辅助函数-处理土地开垦逻辑
    def _process_digging(self, client_id, player_data, username, lot, lot_index):
        """处理土地开垦逻辑"""
        # 计算开垦费用 - 基于已开垦地块数量
        digged_count = sum(1 for l in player_data["farm_lots"] if l.get("is_diged", False))
        dig_money = digged_count * 1000
        
        # 检查玩家金钱是否足够
        if player_data["money"] < dig_money:
            return self._send_action_error(client_id, "dig_ground", f"金钱不足，开垦此地块需要 {dig_money} 金钱")
        
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
    
#==========================开垦土地处理==========================




#==========================铲除作物处理==========================
    #处理铲除作物请求
    def _handle_remove_crop(self, client_id, message):
        """处理铲除作物请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "铲除作物", "remove_crop")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "remove_crop")
        if not player_data:
            return self.send_data(client_id, response)
        
        lot_index = message.get("lot_index", -1)
        
        # 验证地块索引
        if lot_index < 0 or lot_index >= len(player_data.get("farm_lots", [])):
            return self._send_action_error(client_id, "remove_crop", "无效的地块索引")
        
        lot = player_data["farm_lots"][lot_index]
        
        # 检查地块状态
        if not lot.get("is_planted", False) or not lot.get("crop_type", ""):
            return self._send_action_error(client_id, "remove_crop", "此地块没有种植作物")
        
        # 处理铲除
        return self._process_crop_removal(client_id, player_data, username, lot, lot_index)
    
    #辅助函数-处理铲除作物逻辑
    def _process_crop_removal(self, client_id, player_data, username, lot, lot_index):
        """处理铲除作物逻辑"""
        # 铲除费用
        removal_cost = 500
        
        # 检查玩家金钱是否足够
        if player_data["money"] < removal_cost:
            return self._send_action_error(client_id, "remove_crop", f"金钱不足，铲除作物需要 {removal_cost} 金钱")
        
        # 获取作物名称用于日志
        crop_type = lot.get("crop_type", "未知作物")
        
        # 执行铲除操作
        player_data["money"] -= removal_cost
        lot["is_planted"] = False
        lot["crop_type"] = ""
        lot["grow_time"] = 0
        lot["is_dead"] = False  # 重置死亡状态
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        self.log('INFO', f"玩家 {username} 铲除了地块 {lot_index} 的作物 {crop_type}，花费 {removal_cost} 金钱", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "remove_crop",
            "success": True,
            "message": f"成功铲除作物 {crop_type}，花费 {removal_cost} 金钱",
            "updated_data": {
                "money": player_data["money"],
                "farm_lots": player_data["farm_lots"]
            }
        })
    
#==========================铲除作物处理==========================




#==========================浇水作物处理==========================
    #处理浇水请求
    def _handle_water_crop(self, client_id, message):
        """处理浇水作物请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "浇水作物", "water_crop")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取当前操作用户的数据
        current_player_data, current_username, response = self._load_player_data_with_check(client_id, "water_crop")
        if not current_player_data:
            return self.send_data(client_id, response)
        
        lot_index = message.get("lot_index", -1)
        target_username = message.get("target_username", "")
        
        # 确定操作目标：如果有target_username就是访问模式，否则是自己的农场
        if target_username and target_username != current_username:
            # 访问模式：浇水别人的作物，但花自己的钱
            target_player_data = self.load_player_data(target_username)
            if not target_player_data:
                return self._send_action_error(client_id, "water_crop", f"无法找到玩家 {target_username} 的数据")
            
            # 验证地块索引
            if lot_index < 0 or lot_index >= len(target_player_data.get("farm_lots", [])):
                return self._send_action_error(client_id, "water_crop", "无效的地块索引")
            
            target_lot = target_player_data["farm_lots"][lot_index]
            
            # 检查地块状态
            if not target_lot.get("is_planted", False) or not target_lot.get("crop_type", ""):
                return self._send_action_error(client_id, "water_crop", "此地块没有种植作物")
            
            # 处理访问模式浇水（花自己的钱，效果作用在目标玩家作物上）
            return self._process_visiting_watering(client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index)
        else:
            # 正常模式：浇水自己的作物
            # 验证地块索引
            if lot_index < 0 or lot_index >= len(current_player_data.get("farm_lots", [])):
                return self._send_action_error(client_id, "water_crop", "无效的地块索引")
            
            lot = current_player_data["farm_lots"][lot_index]
            
            # 检查地块状态
            if not lot.get("is_planted", False) or not lot.get("crop_type", ""):
                return self._send_action_error(client_id, "water_crop", "此地块没有种植作物")
            
            # 处理正常浇水
            return self._process_watering(client_id, current_player_data, current_username, lot, lot_index)
    
    #辅助函数-处理浇水逻辑
    def _process_watering(self, client_id, player_data, username, lot, lot_index):
        """处理浇水逻辑"""
        # 浇水费用和体力值消耗
        water_cost = 50
        stamina_cost = 1
        
        # 检查并更新体力值
        self._check_and_update_stamina(player_data)
        
        # 检查体力值是否足够
        if not self._check_stamina_sufficient(player_data, stamina_cost):
            return self._send_action_error(client_id, "water_crop", f"体力值不足，浇水需要 {stamina_cost} 点体力，当前体力：{player_data.get('体力值', 0)}")
        
        # 检查玩家金钱是否足够
        if player_data["money"] < water_cost:
            return self._send_action_error(client_id, "water_crop", f"金钱不足，浇水需要 {water_cost} 金钱")
        
        # 检查作物是否已死亡
        if lot.get("is_dead", False):
            return self._send_action_error(client_id, "water_crop", "死亡的作物无法浇水")
        
        # 检查是否已经成熟
        if lot["grow_time"] >= lot["max_grow_time"]:
            return self._send_action_error(client_id, "water_crop", "作物已经成熟，无需浇水")
        
        # 检查是否在1小时内已经浇过水（3600秒 = 1小时）
        current_time = time.time()
        last_water_time = lot.get("浇水时间", 0)
        water_cooldown = 3600  # 1小时冷却时间
        
        if current_time - last_water_time < water_cooldown:
            remaining_time = water_cooldown - (current_time - last_water_time)
            remaining_minutes = int(remaining_time // 60)
            remaining_seconds = int(remaining_time % 60)
            return self._send_action_error(client_id, "water_crop", f"浇水冷却中，还需等待 {remaining_minutes} 分钟 {remaining_seconds} 秒")
        
        # 执行浇水操作
        player_data["money"] -= water_cost
        
        # 消耗体力值
        stamina_success, stamina_message = self._consume_stamina(player_data, stamina_cost, "浇水")
        if not stamina_success:
            return self._send_action_error(client_id, "water_crop", stamina_message)
        
        # 计算浇水效果：增加1%的生长进度
        growth_increase = int(lot["max_grow_time"] * 0.01)  # 1%的生长时间
        if growth_increase < 1:
            growth_increase = 1  # 至少增加1秒
        
        lot["grow_time"] += growth_increase
        
        # 确保不超过最大生长时间
        if lot["grow_time"] > lot["max_grow_time"]:
            lot["grow_time"] = lot["max_grow_time"]
        
        # 记录浇水时间戳
        lot["浇水时间"] = current_time
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        crop_type = lot.get("crop_type", "未知作物")
        progress = (lot["grow_time"] / lot["max_grow_time"]) * 100
        
        self.log('INFO', f"玩家 {username} 给地块 {lot_index} 的 {crop_type} 浇水，花费 {water_cost} 金钱，生长进度: {progress:.1f}%", 'SERVER')
        
        message = f"浇水成功！{crop_type} 生长了 {growth_increase} 秒，当前进度: {progress:.1f}%，{stamina_message}"
        if lot["grow_time"] >= lot["max_grow_time"]:
            message += "，作物已成熟！"
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "water_crop",
            "success": True,
            "message": message,
            "updated_data": {
                "money": player_data["money"],
                "体力值": player_data["体力值"],
                "farm_lots": player_data["farm_lots"]
            }
        })
    
    #处理访问模式浇水逻辑
    def _process_visiting_watering(self, client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index):
        """处理访问模式浇水逻辑（花自己的钱，效果作用在目标玩家作物上）"""
        # 浇水费用和体力值消耗
        water_cost = 50
        stamina_cost = 1
        
        # 检查并更新当前玩家的体力值
        self._check_and_update_stamina(current_player_data)
        
        # 检查体力值是否足够
        if not self._check_stamina_sufficient(current_player_data, stamina_cost):
            return self._send_action_error(client_id, "water_crop", f"体力值不足，帮助浇水需要 {stamina_cost} 点体力，当前体力：{current_player_data.get('体力值', 0)}")
        
        # 检查当前玩家金钱是否足够
        if current_player_data["money"] < water_cost:
            return self._send_action_error(client_id, "water_crop", f"金钱不足，帮助浇水需要 {water_cost} 金钱")
        
        # 检查目标作物是否已死亡
        if target_lot.get("is_dead", False):
            return self._send_action_error(client_id, "water_crop", "死亡的作物无法浇水")
        
        # 检查是否已经成熟
        if target_lot["grow_time"] >= target_lot["max_grow_time"]:
            return self._send_action_error(client_id, "water_crop", "作物已经成熟，无需浇水")
        
        # 检查是否在1小时内已经浇过水
        current_time = time.time()
        last_water_time = target_lot.get("浇水时间", 0)
        water_cooldown = 3600  # 1小时冷却时间
        
        if current_time - last_water_time < water_cooldown:
            remaining_time = water_cooldown - (current_time - last_water_time)
            remaining_minutes = int(remaining_time // 60)
            remaining_seconds = int(remaining_time % 60)
            return self._send_action_error(client_id, "water_crop", f"浇水冷却中，还需等待 {remaining_minutes} 分钟 {remaining_seconds} 秒")
        
        # 执行浇水操作：扣除当前玩家的钱
        current_player_data["money"] -= water_cost
        
        # 消耗当前玩家的体力值
        stamina_success, stamina_message = self._consume_stamina(current_player_data, stamina_cost, "帮助浇水")
        if not stamina_success:
            return self._send_action_error(client_id, "water_crop", stamina_message)
        
        # 计算浇水效果：增加目标作物的生长进度
        growth_increase = int(target_lot["max_grow_time"] * 0.01)  # 1%的生长时间
        if growth_increase < 1:
            growth_increase = 1  # 至少增加1秒
        
        target_lot["grow_time"] += growth_increase
        
        # 确保不超过最大生长时间
        if target_lot["grow_time"] > target_lot["max_grow_time"]:
            target_lot["grow_time"] = target_lot["max_grow_time"]
        
        # 记录浇水时间戳
        target_lot["浇水时间"] = current_time
        
        # 保存两个玩家的数据
        self.save_player_data(current_username, current_player_data)
        self.save_player_data(target_username, target_player_data)
        
        # 向目标玩家推送作物更新（如果在线）
        self._push_crop_update_to_player(target_username, target_player_data)
        
        crop_type = target_lot.get("crop_type", "未知作物")
        progress = (target_lot["grow_time"] / target_lot["max_grow_time"]) * 100
        
        self.log('INFO', f"玩家 {current_username} 帮助玩家 {target_username} 给地块 {lot_index} 的 {crop_type} 浇水，花费 {water_cost} 金钱，生长进度: {progress:.1f}%", 'SERVER')
        
        message = f"帮助浇水成功！{target_username} 的 {crop_type} 生长了 {growth_increase} 秒，当前进度: {progress:.1f}%，{stamina_message}"
        if target_lot["grow_time"] >= target_lot["max_grow_time"]:
            message += "，作物已成熟！"
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "water_crop",
            "success": True,
            "message": message,
            "updated_data": {
                "money": current_player_data["money"],
                "体力值": current_player_data["体力值"]
            }
        })
    
#==========================浇水作物处理==========================



#==========================施肥作物处理==========================
    #处理施肥请求
    def _handle_fertilize_crop(self, client_id, message):
        """处理施肥作物请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "施肥作物", "fertilize_crop")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取当前操作用户的数据
        current_player_data, current_username, response = self._load_player_data_with_check(client_id, "fertilize_crop")
        if not current_player_data:
            return self.send_data(client_id, response)
        
        lot_index = message.get("lot_index", -1)
        target_username = message.get("target_username", "")
        
        # 确定操作目标：如果有target_username就是访问模式，否则是自己的农场
        if target_username and target_username != current_username:
            # 访问模式：施肥别人的作物，但花自己的钱
            target_player_data = self.load_player_data(target_username)
            if not target_player_data:
                return self._send_action_error(client_id, "fertilize_crop", f"无法找到玩家 {target_username} 的数据")
            
            # 验证地块索引
            if lot_index < 0 or lot_index >= len(target_player_data.get("farm_lots", [])):
                return self._send_action_error(client_id, "fertilize_crop", "无效的地块索引")
            
            target_lot = target_player_data["farm_lots"][lot_index]
            
            # 检查地块状态
            if not target_lot.get("is_planted", False) or not target_lot.get("crop_type", ""):
                return self._send_action_error(client_id, "fertilize_crop", "此地块没有种植作物")
            
            # 处理访问模式施肥
            return self._process_visiting_fertilizing(client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index)
        else:
            # 正常模式：施肥自己的作物
            # 验证地块索引
            if lot_index < 0 or lot_index >= len(current_player_data.get("farm_lots", [])):
                return self._send_action_error(client_id, "fertilize_crop", "无效的地块索引")
            
            lot = current_player_data["farm_lots"][lot_index]
            
            # 检查地块状态
            if not lot.get("is_planted", False) or not lot.get("crop_type", ""):
                return self._send_action_error(client_id, "fertilize_crop", "此地块没有种植作物")
            
            # 处理正常施肥
            return self._process_fertilizing(client_id, current_player_data, current_username, lot, lot_index)

    #辅助函数-处理访问模式施肥逻辑
    def _process_visiting_fertilizing(self, client_id, current_player_data, current_username, target_player_data, target_username, target_lot, lot_index):
        """处理访问模式施肥逻辑（花自己的钱，效果作用在目标玩家作物上）"""
        # 施肥费用和体力值消耗
        fertilize_cost = 150
        stamina_cost = 1
        
        # 检查并更新当前玩家的体力值
        self._check_and_update_stamina(current_player_data)
        
        # 检查体力值是否足够
        if not self._check_stamina_sufficient(current_player_data, stamina_cost):
            return self._send_action_error(client_id, "fertilize_crop", f"体力值不足，帮助施肥需要 {stamina_cost} 点体力，当前体力：{current_player_data.get('体力值', 0)}")
        
        # 检查当前玩家金钱是否足够
        if current_player_data["money"] < fertilize_cost:
            return self._send_action_error(client_id, "fertilize_crop", f"金钱不足，帮助施肥需要 {fertilize_cost} 金钱")
        
        # 检查目标作物是否已死亡
        if target_lot.get("is_dead", False):
            return self._send_action_error(client_id, "fertilize_crop", "死亡的作物无法施肥")
        
        # 检查是否已经成熟
        if target_lot["grow_time"] >= target_lot["max_grow_time"]:
            return self._send_action_error(client_id, "fertilize_crop", "作物已经成熟，无需施肥")
        
        # 检查是否已经施过肥
        if target_lot.get("已施肥", False):
            return self._send_action_error(client_id, "fertilize_crop", "此作物已经施过肥了")
        
        # 执行施肥操作：扣除当前玩家的钱
        current_player_data["money"] -= fertilize_cost
        
        # 消耗当前玩家的体力值
        stamina_success, stamina_message = self._consume_stamina(current_player_data, stamina_cost, "帮助施肥")
        if not stamina_success:
            return self._send_action_error(client_id, "fertilize_crop", stamina_message)
        
        # 标记目标作物已施肥，施肥效果会在作物生长更新时生效
        target_lot["已施肥"] = True
        
        # 记录施肥时间戳，用于计算10分钟的双倍生长效果
        target_lot["施肥时间"] = time.time()
        
        # 保存两个玩家的数据
        self.save_player_data(current_username, current_player_data)
        self.save_player_data(target_username, target_player_data)
        
        # 向目标玩家推送作物更新（如果在线）
        self._push_crop_update_to_player(target_username, target_player_data)
        
        crop_type = target_lot.get("crop_type", "未知作物")
        
        self.log('INFO', f"玩家 {current_username} 帮助玩家 {target_username} 给地块 {lot_index} 的 {crop_type} 施肥，花费 {fertilize_cost} 金钱", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "fertilize_crop",
            "success": True,
            "message": f"帮助施肥成功！{target_username} 的 {crop_type} 将在10分钟内以双倍速度生长，{stamina_message}",
            "updated_data": {
                "money": current_player_data["money"],
                "体力值": current_player_data["体力值"]
            }
        })
    
    #辅助函数-处理施肥逻辑
    def _process_fertilizing(self, client_id, player_data, username, lot, lot_index):
        """处理施肥逻辑"""
        # 施肥费用和体力值消耗
        fertilize_cost = 150
        stamina_cost = 1
        
        # 检查并更新体力值
        self._check_and_update_stamina(player_data)
        
        # 检查体力值是否足够
        if not self._check_stamina_sufficient(player_data, stamina_cost):
            return self._send_action_error(client_id, "fertilize_crop", f"体力值不足，施肥需要 {stamina_cost} 点体力，当前体力：{player_data.get('体力值', 0)}")
        
        # 检查玩家金钱是否足够
        if player_data["money"] < fertilize_cost:
            return self._send_action_error(client_id, "fertilize_crop", f"金钱不足，施肥需要 {fertilize_cost} 金钱")
        
        # 检查作物是否已死亡
        if lot.get("is_dead", False):
            return self._send_action_error(client_id, "fertilize_crop", "死亡的作物无法施肥")
        
        # 检查是否已经成熟
        if lot["grow_time"] >= lot["max_grow_time"]:
            return self._send_action_error(client_id, "fertilize_crop", "作物已经成熟，无需施肥")
        
        # 检查是否已经施过肥
        if lot.get("已施肥", False):
            return self._send_action_error(client_id, "fertilize_crop", "此作物已经施过肥了")
        
        # 执行施肥操作
        player_data["money"] -= fertilize_cost
        
        # 消耗体力值
        stamina_success, stamina_message = self._consume_stamina(player_data, stamina_cost, "施肥")
        if not stamina_success:
            return self._send_action_error(client_id, "fertilize_crop", stamina_message)
        
        # 标记已施肥，施肥效果会在作物生长更新时生效
        lot["已施肥"] = True
        
        # 记录施肥时间戳，用于计算10分钟的双倍生长效果
        lot["施肥时间"] = time.time()
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        crop_type = lot.get("crop_type", "未知作物")
        
        self.log('INFO', f"玩家 {username} 给地块 {lot_index} 的 {crop_type} 施肥，花费 {fertilize_cost} 金钱", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "fertilize_crop",
            "success": True,
            "message": f"施肥成功！{crop_type} 将在10分钟内以双倍速度生长，{stamina_message}",
            "updated_data": {
                "money": player_data["money"],
                "体力值": player_data["体力值"],
                "farm_lots": player_data["farm_lots"]
            }
        })
    
#==========================施肥作物处理==========================




#==========================升级土地处理==========================
    #处理升级土地请求
    def _handle_upgrade_land(self, client_id, message):
        """处理升级土地请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "升级土地", "upgrade_land")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "upgrade_land")
        if not player_data:
            return self.send_data(client_id, response)
        
        lot_index = message.get("lot_index", -1)
        
        # 验证地块索引
        if lot_index < 0 or lot_index >= len(player_data.get("farm_lots", [])):
            return self._send_action_error(client_id, "upgrade_land", "无效的地块索引")
        
        lot = player_data["farm_lots"][lot_index]
        
        # 检查地块是否已开垦
        if not lot.get("is_diged", False):
            return self._send_action_error(client_id, "upgrade_land", "此地块尚未开垦")
        
        # 处理升级
        return self._process_land_upgrade(client_id, player_data, username, lot, lot_index)
    
    #辅助函数-处理土地升级逻辑
    def _process_land_upgrade(self, client_id, player_data, username, lot, lot_index):
        """处理土地升级逻辑"""
        # 土地升级配置
        upgrade_config = {
            0: {"cost": 1000, "name": "黄土地", "speed": 2.0},   # 0级->1级：1000元，2倍速
            1: {"cost": 2000, "name": "红土地", "speed": 4.0},   # 1级->2级：2000元，4倍速
            2: {"cost": 4000, "name": "紫土地", "speed": 6.0},   # 2级->3级：4000元，6倍速
            3: {"cost": 8000, "name": "黑土地", "speed": 10.0}   # 3级->4级：8000元，10倍速
        }
        
        # 获取当前土地等级
        current_level = lot.get("土地等级", 0)
        
        # 检查是否已达到最高等级
        if current_level >= 4:
            return self._send_action_error(client_id, "upgrade_land", "此土地已达到最高等级（黑土地）")
        
        # 检查升级配置是否存在
        if current_level not in upgrade_config:
            return self._send_action_error(client_id, "upgrade_land", f"土地等级数据异常，当前等级: {current_level}")
        
        # 获取升级配置
        config = upgrade_config[current_level]
        upgrade_cost = config["cost"]
        next_name = config["name"]
        next_level = current_level + 1
        speed_multiplier = config["speed"]
        
        # 检查玩家金钱是否足够
        if player_data["money"] < upgrade_cost:
            return self._send_action_error(client_id, "upgrade_land", f"金钱不足，升级到{next_name}需要 {upgrade_cost} 金钱")
        
        # 执行升级操作
        player_data["money"] -= upgrade_cost
        lot["土地等级"] = next_level
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        self.log('INFO', f"玩家 {username} 将地块 {lot_index} 升级到{next_level}级{next_name}，花费 {upgrade_cost} 金钱", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "upgrade_land",
            "success": True,
            "message": f"土地升级成功！升级到{next_level}级{next_name}，作物将以{speed_multiplier}倍速度生长",
            "updated_data": {
                "money": player_data["money"],
                "farm_lots": player_data["farm_lots"]
            }
        })
#==========================升级土地处理==========================



#==========================购买新地块处理==========================
    #处理购买新地块请求
    def _handle_buy_new_ground(self, client_id, message):
        """处理购买新地块请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "购买新地块", "buy_new_ground")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "buy_new_ground")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 处理购买新地块
        return self._process_buy_new_ground(client_id, player_data, username)
    
    #辅助函数-处理购买新地块逻辑
    def _process_buy_new_ground(self, client_id, player_data, username):
        """处理购买新地块逻辑"""
        # 购买新地块费用
        new_ground_cost = 2000
        
        # 检查玩家金钱是否足够
        if player_data["money"] < new_ground_cost:
            return self._send_action_error(client_id, "buy_new_ground", f"金钱不足，购买新地块需要 {new_ground_cost} 金钱")
        
        # 检查地块数量限制
        max_lots = 1000  # 最大地块数量限制
        current_lots = len(player_data.get("farm_lots", []))
        if current_lots >= max_lots:
            return self._send_action_error(client_id, "buy_new_ground", f"已达到最大地块数量限制（{max_lots}个）")
        
        # 执行购买操作
        player_data["money"] -= new_ground_cost
        
        # 创建新的未开垦地块
        new_lot = {
            "crop_type": "",
            "grow_time": 0,
            "is_dead": False,
            "is_diged": False,  # 新购买的地块默认未开垦
            "is_planted": False,
            "max_grow_time": 5,
            "已浇水": False,
            "已施肥": False,
            "土地等级": 0
        }
        
        # 添加到农场地块数组
        if "farm_lots" not in player_data:
            player_data["farm_lots"] = []
        player_data["farm_lots"].append(new_lot)
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        # 发送作物更新
        self._push_crop_update_to_player(username, player_data)
        
        new_lot_index = len(player_data["farm_lots"])
        self.log('INFO', f"玩家 {username} 成功购买新地块，花费 {new_ground_cost} 金钱，新地块位置：{new_lot_index}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": "buy_new_ground",
            "success": True,
            "message": f"购买新地块成功！花费 {new_ground_cost} 元，新地块位置：{new_lot_index}",
            "updated_data": {
                "money": player_data["money"],
                "farm_lots": player_data["farm_lots"]
            }
        })
    
#==========================购买新地块处理==========================



#==========================点赞玩家处理==========================
    #处理玩家点赞请求
    def _handle_like_player(self, client_id, message):
        """处理点赞请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "点赞玩家", "like_player")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "like_player")
        if not player_data:
            return self.send_data(client_id, response)
        
        target_username = message.get("target_username", "")
        
        if not target_username:
            return self.send_data(client_id, {
                "type": "like_player_response",
                "success": False,
                "message": "缺少目标用户名"
            })
        
        # 不能给自己点赞
        if target_username == username:
            return self.send_data(client_id, {
                "type": "like_player_response",
                "success": False,
                "message": "不能给自己点赞"
            })
        
        # 检查今天是否已经给这个玩家点过赞
        current_date = datetime.datetime.now().strftime("%Y-%m-%d")
        
        # 初始化点赞记录
        if "daily_likes" not in player_data:
            player_data["daily_likes"] = {}
        
        # 检查今天的点赞记录
        if current_date not in player_data["daily_likes"]:
            player_data["daily_likes"][current_date] = []
        
        if target_username in player_data["daily_likes"][current_date]:
            return self.send_data(client_id, {
                "type": "like_player_response",
                "success": False,
                "message": f"今天已经给 {target_username} 点过赞了"
            })
        
        # 加载目标玩家数据
        target_player_data = self.load_player_data(target_username)
        
        if not target_player_data:
            return self.send_data(client_id, {
                "type": "like_player_response",
                "success": False,
                "message": f"无法找到玩家 {target_username} 的数据"
            })
        
        # 记录点赞
        player_data["daily_likes"][current_date].append(target_username)
        
        # 更新目标玩家的点赞数量
        target_player_data["total_likes"] = target_player_data.get("total_likes", 0) + 1
        
        # 保存两个玩家的数据
        self.save_player_data(username, player_data)
        self.save_player_data(target_username, target_player_data)
        
        self.log('INFO', f"玩家 {username} 点赞了玩家 {target_username}，目标玩家总赞数：{target_player_data['total_likes']}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "like_player_response",
            "success": True,
            "message": f"成功点赞玩家 {target_username}！",
            "target_likes": target_player_data["total_likes"]
        })
    
#==========================点赞玩家处理==========================



#==========================在线玩家处理==========================
    #处理请求在线玩家请求
    def _handle_online_players_request(self, client_id, message):
        """处理获取在线玩家数量的请求"""
        online_players = len([cid for cid in self.user_data if self.user_data[cid].get("logged_in", False)])
        return self.send_data(client_id, {
            "type": "online_players_response",
            "success": True,
            "online_players": online_players
        })
    
#==========================在线玩家处理==========================



#==========================玩家体力值处理==========================
    #检查并更新体力值
    def _check_and_update_stamina(self, player_data):
        """检查并更新体力值（每小时恢复1点，每天重置）"""
        import datetime
        
        current_time = time.time()
        current_date = datetime.datetime.now().strftime("%Y-%m-%d")
        
        # 初始化体力值相关字段
        if "体力值" not in player_data:
            player_data["体力值"] = 20
        if "体力上次刷新时间" not in player_data:
            player_data["体力上次刷新时间"] = current_date
        if "体力上次恢复时间" not in player_data:
            player_data["体力上次恢复时间"] = current_time
        
        # 检查是否需要每日重置
        last_refresh_date = player_data.get("体力上次刷新时间", "")
        if last_refresh_date != current_date:
            # 新的一天，重置体力值
            player_data["体力值"] = 20
            player_data["体力上次刷新时间"] = current_date
            player_data["体力上次恢复时间"] = current_time
            return True  # 发生了重置
        
        # 检查每小时恢复
        last_recovery_time = player_data.get("体力上次恢复时间", current_time)
        time_diff = current_time - last_recovery_time
        
        # 如果超过1小时（3600秒），恢复体力值
        if time_diff >= 3600:
            hours_passed = int(time_diff // 3600)
            current_stamina = player_data.get("体力值", 0)
            
            # 体力值恢复，但不能超过20
            new_stamina = min(20, current_stamina + hours_passed)
            if new_stamina > current_stamina:
                player_data["体力值"] = new_stamina
                player_data["体力上次恢复时间"] = current_time
                return True  # 发生了恢复
        
        return False  # 没有变化
    
    #消耗体力值
    def _consume_stamina(self, player_data, amount, action_name):
        """消耗体力值"""
        current_stamina = player_data.get("体力值", 20)
        
        if current_stamina < amount:
            return False, f"体力值不足！{action_name}需要 {amount} 点体力，当前体力：{current_stamina}"
        
        player_data["体力值"] = current_stamina - amount
        return True, f"消耗 {amount} 点体力，剩余体力：{player_data['体力值']}"
    
    #检查体力值是否足够
    def _check_stamina_sufficient(self, player_data, amount):
        """检查体力值是否足够"""
        current_stamina = player_data.get("体力值", 20)
        return current_stamina >= amount
    
#==========================玩家体力值处理==========================



#==========================玩家游玩时间处理==========================
    #处理获取玩家游玩时间请求
    def _handle_get_play_time(self, client_id):
        """处理获取游玩时间请求"""
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
        """处理更新游玩时间请求"""
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
#==========================玩家游玩时间处理==========================



#==========================玩家排行榜处理==========================
    #处理获取玩家排行榜请求
    def _handle_player_rankings_request(self, client_id):
        """处理获取玩家排行榜的请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "获取玩家排行榜", "player_rankings")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取所有玩家存档文件
        save_files = glob.glob(os.path.join("game_saves", "*.json"))
        players_data = []
        
        # 统计注册总人数
        total_registered_players = len(save_files)
        
        for save_file in save_files:
            try:
                # 从文件名提取账号ID
                account_id = os.path.basename(save_file).split('.')[0]
                
                # 加载玩家数据
                with open(save_file, 'r', encoding='utf-8') as file:
                    player_data = json.load(file)
                
                if player_data:
                    # 统计背包中的种子数量
                    seed_count = sum(item.get("count", 0) for item in player_data.get("player_bag", []))
                    
                    # 检查玩家是否在线
                    is_online = any(
                        user_info.get("username") == account_id and user_info.get("logged_in", False) 
                        for user_info in self.user_data.values()
                    )
                    
                    # 获取所需的玩家信息
                    player_info = {
                        "user_name": player_data.get("user_name", account_id),
                        "player_name": player_data.get("player_name", player_data.get("user_name", account_id)),
                        "farm_name": player_data.get("farm_name", ""),
                        "level": player_data.get("level", 1),
                        "money": player_data.get("money", 0),
                        "experience": player_data.get("experience", 0),
                        "体力值": player_data.get("体力值", 20),
                        "seed_count": seed_count,
                        "last_login_time": player_data.get("last_login_time", "未知"),
                        "total_login_time": player_data.get("total_login_time", "0时0分0秒"),
                        "is_online": is_online
                    }
                    
                    players_data.append(player_info)
            except Exception as e:
                self.log('ERROR', f"读取玩家 {account_id} 的数据时出错: {str(e)}", 'SERVER')
        
        # 按等级降序排序
        players_data.sort(key=lambda x: x["level"], reverse=True)
        
        # 统计在线玩家数量
        online_count = sum(1 for player in players_data if player.get("is_online", False))
        
        self.log('INFO', f"玩家 {self.user_data[client_id].get('username')} 请求玩家排行榜，返回 {len(players_data)} 个玩家数据，注册总人数：{total_registered_players}，在线人数：{online_count}", 'SERVER')
        
        # 返回排行榜数据（包含注册总人数）
        return self.send_data(client_id, {
            "type": "player_rankings_response",
            "success": True,
            "players": players_data,
            "total_registered_players": total_registered_players
        })
#==========================玩家排行榜处理==========================



#==========================作物数据处理==========================
    #处理客户端请求作物数据
    def _handle_crop_data_request(self, client_id):
        """处理客户端请求作物数据"""
        crop_data = self._load_crop_data()
        
        if crop_data:
            self.log('INFO', f"向客户端 {client_id} 发送作物数据", 'SERVER')
            return self.send_data(client_id, {
                "type": "crop_data_response",
                "success": True,
                "crop_data": crop_data
            })
        else:
            return self.send_data(client_id, {
                "type": "crop_data_response",
                "success": False,
                "message": "无法读取作物数据"
            })
#==========================作物数据处理==========================



#==========================访问其他玩家农场处理==========================
    #处理访问其他玩家农场的请求
    def _handle_visit_player_request(self, client_id, message):
        """处理访问其他玩家农场的请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "访问玩家农场", "visit_player")
        if not logged_in:
            return self.send_data(client_id, response)
        
        target_username = message.get("target_username", "")
        
        if not target_username:
            return self.send_data(client_id, {
                "type": "visit_player_response",
                "success": False,
                "message": "缺少目标用户名"
            })
        
        # 加载目标玩家数据
        target_player_data = self.load_player_data(target_username)
        
        if not target_player_data:
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
            "体力值": target_player_data.get("体力值", 20),
            "farm_lots": target_player_data.get("farm_lots", []),
            "player_bag": target_player_data.get("player_bag", []),
            "last_login_time": target_player_data.get("last_login_time", "未知"),
            "total_login_time": target_player_data.get("total_login_time", "0时0分0秒"),
            "total_likes": target_player_data.get("total_likes", 0)
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
#==========================访问其他玩家农场处理==========================




#==========================返回自己农场处理==========================
    #处理玩家返回自己农场的请求
    def _handle_return_my_farm_request(self, client_id, message):
        """处理玩家返回自己农场的请求"""
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
                "体力值": player_data.get("体力值", 20),
                "farm_lots": player_data.get("farm_lots", []),
                "player_bag": player_data.get("player_bag", []),
                "total_likes": player_data.get("total_likes", 0)
            },
            "is_visiting": False
        })
#==========================返回自己农场处理==========================




#==========================PING延迟检测处理==========================
    #处理ping请求
    def _handle_ping_request(self, client_id, message):
        """处理客户端ping请求，立即返回pong响应"""
        timestamp = message.get("timestamp", time.time())
        
        # 立即返回pong响应
        pong_response = {
            "type": "pong",
            "timestamp": timestamp,
            "server_time": time.time()
        }
        
        return self.send_data(client_id, pong_response)

#==========================PING延迟检测处理==========================



#==========================聊天消息处理==========================
    #处理聊天消息（暂未完成）
    def _handle_chat_message(self, client_id, message):
        """处理聊天消息"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "发送聊天消息")
        if not logged_in:
            return self.send_data(client_id, response)
        
        content = message.get("content", "")
        if not content.strip():
            return self.send_data(client_id, {
                "type": "chat_response",
                "success": False,
                "message": "消息内容不能为空"
            })
        
        username = self.user_data[client_id]["username"]
        
        # 广播聊天消息给所有在线用户
        chat_message = {
            "type": "chat_message",
            "username": username,
            "content": content,
            "timestamp": time.time()
        }
        
        self.broadcast(chat_message)
        self.log('INFO', f"用户 {username} 发送聊天消息: {content}", 'SERVER')
        
        return True
    
#==========================聊天消息处理==========================




#==========================每日签到处理==========================
    #处理每日签到请求
    def _handle_daily_check_in_request(self, client_id, message):
        """处理每日签到请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "每日签到", "daily_check_in")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "daily_check_in")
        if not player_data:
            return self.send_data(client_id, response)
        
        # 检查今日是否已签到
        current_date = datetime.datetime.now().strftime("%Y-%m-%d")
        check_in_data = player_data.get("daily_check_in", {})
        
        if current_date in check_in_data:
            return self.send_data(client_id, {
                "type": "daily_check_in_response",
                "success": False,
                "message": "今日已签到，请明日再来",
                "has_checked_in": True
            })
        
        # 计算连续签到天数
        consecutive_days = self._calculate_consecutive_check_in_days(check_in_data, current_date)
        
        # 生成签到奖励
        rewards = self._generate_check_in_rewards(consecutive_days)
        
        # 发放奖励
        self._apply_check_in_rewards(player_data, rewards)
        
        # 保存签到记录
        if "daily_check_in" not in player_data:
            player_data["daily_check_in"] = {}
        
        player_data["daily_check_in"][current_date] = {
            "rewards": rewards,
            "consecutive_days": consecutive_days,
            "timestamp": time.time()
        }
        
        # 保存玩家数据
        self.save_player_data(username, player_data)
        
        self.log('INFO', f"玩家 {username} 完成每日签到，连续 {consecutive_days} 天，获得奖励: {rewards}", 'SERVER')
        
        return self.send_data(client_id, {
            "type": "daily_check_in_response",
            "success": True,
            "message": f"签到成功！连续签到 {consecutive_days} 天",
            "rewards": rewards,
            "consecutive_days": consecutive_days,
            "updated_data": {
                "money": player_data["money"],
                "experience": player_data["experience"],
                "level": player_data["level"],
                "player_bag": player_data.get("player_bag", [])
            }
        })
    
    #处理客户端获取签到数据请求
    def _handle_get_check_in_data_request(self, client_id, message):
        """处理获取签到数据请求"""
        # 检查用户是否已登录
        logged_in, response = self._check_user_logged_in(client_id, "获取签到数据", "get_check_in_data")
        if not logged_in:
            return self.send_data(client_id, response)
        
        # 获取玩家数据
        player_data, username, response = self._load_player_data_with_check(client_id, "get_check_in_data")
        if not player_data:
            return self.send_data(client_id, response)
        
        current_date = datetime.datetime.now().strftime("%Y-%m-%d")
        check_in_data = player_data.get("daily_check_in", {})
        
        # 计算连续签到天数
        consecutive_days = self._calculate_consecutive_check_in_days(check_in_data, current_date)
        
        # 检查今日是否已签到
        has_checked_in_today = current_date in check_in_data
        
        return self.send_data(client_id, {
            "type": "check_in_data_response",
            "success": True,
            "check_in_data": check_in_data,
            "consecutive_days": consecutive_days,
            "has_checked_in_today": has_checked_in_today,
            "current_date": current_date
        })
    
    #计算连续签到天数
    def _calculate_consecutive_check_in_days(self, check_in_data, current_date):
        """计算连续签到天数"""
        if not check_in_data:
            return 0
        
        # 获取所有签到日期并排序
        sorted_dates = sorted(check_in_data.keys())
        if not sorted_dates:
            return 0
        
        # 从最新日期开始向前计算连续天数
        consecutive_days = 0
        current_datetime = datetime.datetime.strptime(current_date, "%Y-%m-%d")
        
        # 如果今天已经签到，从今天开始计算，否则从昨天开始
        if current_date in check_in_data:
            check_date = current_datetime
        else:
            check_date = current_datetime - datetime.timedelta(days=1)
        
        # 向前查找连续签到天数
        while True:
            date_string = check_date.strftime("%Y-%m-%d")
            if date_string in check_in_data:
                consecutive_days += 1
                check_date -= datetime.timedelta(days=1)
            else:
                break
            
            # 限制最大连续天数为30天，避免过度奖励
            if consecutive_days >= 30:
                break
        
        return consecutive_days
    
    #生成签到奖励
    def _generate_check_in_rewards(self, consecutive_days):
        """生成签到奖励"""
        import random
        
        # 加载作物配置
        crop_data = self._load_crop_data()
        
        rewards = {}
        
        # 基础奖励倍数（根据连续签到天数）
        base_multiplier = 1.0 + (consecutive_days - 1) * 0.1  # 每连续签到一天增加10%
        max_multiplier = 3.0  # 最大3倍奖励
        multiplier = min(base_multiplier, max_multiplier)
        
        # 钱币奖励 (基础200-500，受连续签到影响)
        base_coins = random.randint(200, 500)
        rewards["coins"] = int(base_coins * multiplier)
        
        # 经验奖励 (基础50-120，受连续签到影响)
        base_exp = random.randint(50, 120)
        rewards["exp"] = int(base_exp * multiplier)
        
        # 种子奖励 (根据连续签到天数获得更好的种子)
        seeds = self._generate_check_in_seeds(consecutive_days, crop_data)
        if seeds:
            rewards["seeds"] = seeds
        
        # 连续签到特殊奖励
        if consecutive_days >= 3:
            rewards["bonus_coins"] = int(100 * (consecutive_days // 3))
        
        if consecutive_days >= 7:
            rewards["bonus_exp"] = int(200 * (consecutive_days // 7))
        
        return rewards
    
    #生成签到种子奖励
    def _generate_check_in_seeds(self, consecutive_days, crop_data):
        """生成签到种子奖励"""
        import random
        
        seeds = []
        
        # 根据连续签到天数确定种子类型和数量
        if consecutive_days <= 2:
            # 1-2天：普通种子
            common_seeds = ["小麦", "胡萝卜", "土豆", "稻谷"]
        elif consecutive_days <= 5:
            # 3-5天：优良种子
            common_seeds = ["玉米", "番茄", "洋葱", "大豆", "豌豆", "黄瓜", "大白菜"]
        elif consecutive_days <= 10:
            # 6-10天：稀有种子
            common_seeds = ["草莓", "花椰菜", "柿子", "蓝莓", "树莓"]
        elif consecutive_days <= 15:
            # 11-15天：史诗种子
            common_seeds = ["葡萄", "南瓜", "芦笋", "茄子", "向日葵", "蕨菜"]
        else:
            # 16天以上：传奇种子
            common_seeds = ["西瓜", "甘蔗", "香草", "甜菜", "人参", "富贵竹", "芦荟", "哈密瓜"]
        
        # 生成1-3个种子
        seed_count = random.randint(1, min(3, len(common_seeds)))
        selected_seeds = random.sample(common_seeds, seed_count)
        
        for seed_name in selected_seeds:
            if seed_name in crop_data:
                # 根据种子等级确定数量
                seed_level = crop_data[seed_name].get("等级", 1)
                if seed_level <= 2:
                    quantity = random.randint(2, 5)
                elif seed_level <= 4:
                    quantity = random.randint(1, 3)
                else:
                    quantity = 1
                
                seeds.append({
                    "name": seed_name,
                    "quantity": quantity,
                    "quality": crop_data[seed_name].get("品质", "普通")
                })
        
        return seeds
    
    #应用签到奖励到玩家数据
    def _apply_check_in_rewards(self, player_data, rewards):
        """应用签到奖励到玩家数据"""
        # 应用钱币奖励
        if "coins" in rewards:
            player_data["money"] = player_data.get("money", 0) + rewards["coins"]
        
        if "bonus_coins" in rewards:
            player_data["money"] = player_data.get("money", 0) + rewards["bonus_coins"]
        
        # 应用经验奖励
        if "exp" in rewards:
            player_data["experience"] = player_data.get("experience", 0) + rewards["exp"]
        
        if "bonus_exp" in rewards:
            player_data["experience"] = player_data.get("experience", 0) + rewards["bonus_exp"]
        
        # 检查升级
        level_up_experience = 100 * player_data.get("level", 1)
        while player_data.get("experience", 0) >= level_up_experience:
            player_data["level"] = player_data.get("level", 1) + 1
            player_data["experience"] -= level_up_experience
            level_up_experience = 100 * player_data["level"]
        
        # 应用种子奖励
        if "seeds" in rewards:
            if "player_bag" not in player_data:
                player_data["player_bag"] = []
            
            for seed_reward in rewards["seeds"]:
                seed_name = seed_reward["name"]
                quantity = seed_reward["quantity"]
                quality = seed_reward["quality"]
                
                # 查找背包中是否已有该种子
                found = False
                for item in player_data["player_bag"]:
                    if item.get("name") == seed_name:
                        item["count"] += quantity
                        found = True
                        break
                
                # 如果背包中没有，添加新条目
                if not found:
                    player_data["player_bag"].append({
                        "name": seed_name,
                        "quality": quality,
                        "count": quantity
                    })
    
#==========================每日签到处理==========================




#==========================新手大礼包处理==========================

    #处理新手大礼包请求
    def _handle_new_player_gift_request(self, client_id, message):
        """处理新手大礼包请求"""
        try:
            # 检查用户是否已登录
            logged_in, response = self._check_user_logged_in(client_id, "领取新手大礼包", "new_player_gift")
            if not logged_in:
                return self.send_data(client_id, response)
            
            # 获取玩家数据
            player_data, username, response = self._load_player_data_with_check(client_id, "new_player_gift")
            if not player_data:
                return self.send_data(client_id, response)
            
            # 检查是否已经领取过新手大礼包
            if player_data.get("new_player_gift_claimed", False):
                return self.send_data(client_id, {
                    "type": "new_player_gift_response",
                    "success": False,
                    "message": "新手大礼包已经领取过了"
                })
            
            # 新手大礼包内容
            gift_contents = {
                "coins": 6000,
                "experience": 1000,
                "seeds": [
                    {"name": "龙果", "quality": "传奇", "count": 1},
                    {"name": "杂交树1", "quality": "传奇", "count": 1},
                    {"name": "杂交树2", "quality": "传奇", "count": 1}
                ]
            }
            
            # 应用奖励
            self._apply_new_player_gift_rewards(player_data, gift_contents)
            
            # 标记已领取
            player_data["new_player_gift_claimed"] = True
            
            # 记录领取时间
            player_data["new_player_gift_time"] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            
            # 保存玩家数据
            self.save_player_data(username, player_data)
            
            self.log('INFO', f"玩家 {username} 成功领取新手大礼包", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "new_player_gift_response",
                "success": True,
                "message": "新手大礼包领取成功！获得6000金币、1000经验和3个传奇种子",
                "gift_contents": gift_contents,
                "updated_data": {
                    "money": player_data["money"],
                    "experience": player_data["experience"],
                    "level": player_data["level"],
                    "player_bag": player_data.get("player_bag", []),
                    "new_player_gift_claimed": True
                }
            })
            
        except Exception as e:
            # 捕获所有异常，防止服务器崩溃
            self.log('ERROR', f"处理新手大礼包请求时出错: {str(e)}", 'SERVER')
            
            # 尝试获取用户名
            try:
                username = self.user_data[client_id].get("username", "未知用户")
            except:
                username = "未知用户"
            
            # 发送错误响应
            return self.send_data(client_id, {
                "type": "new_player_gift_response",
                "success": False,
                "message": "服务器处理新手大礼包时出现错误，请稍后重试"
            })
    
    #应用新手大礼包奖励到玩家数据
    def _apply_new_player_gift_rewards(self, player_data, gift_contents):
        """应用新手大礼包奖励到玩家数据"""
        # 应用金币奖励
        if "coins" in gift_contents:
            player_data["money"] = player_data.get("money", 0) + gift_contents["coins"]
        
        # 应用经验奖励
        if "experience" in gift_contents:
            player_data["experience"] = player_data.get("experience", 0) + gift_contents["experience"]
            
            # 检查升级
            level_up_experience = 100 * player_data.get("level", 1)
            while player_data.get("experience", 0) >= level_up_experience:
                player_data["level"] = player_data.get("level", 1) + 1
                player_data["experience"] -= level_up_experience
                level_up_experience = 100 * player_data["level"]
        
        # 应用种子奖励
        if "seeds" in gift_contents:
            if "player_bag" not in player_data:
                player_data["player_bag"] = []
            
            for seed_reward in gift_contents["seeds"]:
                seed_name = seed_reward["name"]
                quantity = seed_reward["count"]
                quality = seed_reward["quality"]
                
                # 查找背包中是否已有该种子
                found = False
                for item in player_data["player_bag"]:
                    if item.get("name") == seed_name:
                        item["count"] += quantity
                        found = True
                        break
                
                # 如果背包中没有，添加新条目
                if not found:
                    player_data["player_bag"].append({
                        "name": seed_name,
                        "quality": quality,
                        "count": quantity
                    })

#==========================新手大礼包处理==========================




#==========================幸运抽奖处理==========================

    #处理幸运抽奖请求
    def _handle_lucky_draw_request(self, client_id, message):
        """处理幸运抽奖请求"""
        try:
            # 检查用户是否已登录
            logged_in, response = self._check_user_logged_in(client_id, "幸运抽奖", "lucky_draw")
            if not logged_in:
                return self.send_data(client_id, response)
            
            # 获取玩家数据
            player_data, username, response = self._load_player_data_with_check(client_id, "lucky_draw")
            if not player_data:
                return self.send_data(client_id, response)
            
            draw_type = message.get("draw_type", "single")  # single, five, ten
            draw_count = 1
            base_cost = 800  # 基础抽奖费用
            
            # 计算抽奖费用和数量
            if draw_type == "single":
                draw_count = 1
                total_cost = base_cost
            elif draw_type == "five":
                draw_count = 5
                total_cost = int(base_cost * 5 * 0.9)  # 五连抽九折
            elif draw_type == "ten":
                draw_count = 10
                total_cost = int(base_cost * 10 * 0.8)  # 十连抽八折
            else:
                self.log('WARNING', f"玩家 {username} 使用了无效的抽奖类型: {draw_type}", 'SERVER')
                return self.send_data(client_id, {
                    "type": "lucky_draw_response",
                    "success": False,
                    "message": "无效的抽奖类型"
                })
            
            # 检查玩家金钱是否足够
            if player_data.get("money", 0) < total_cost:
                self.log('WARNING', f"玩家 {username} 金币不足进行{draw_type}抽奖，需要{total_cost}，当前{player_data.get('money', 0)}", 'SERVER')
                return self.send_data(client_id, {
                    "type": "lucky_draw_response",
                    "success": False,
                    "message": f"金钱不足，{draw_type}抽奖需要 {total_cost} 金币"
                })
            
            # 扣除金钱
            player_data["money"] -= total_cost
            
            # 生成奖励
            rewards = self._generate_lucky_draw_rewards(draw_count, draw_type)
            
            # 验证奖励格式
            for reward in rewards:
                if not reward.get("rarity"):
                    reward["rarity"] = "普通"
                    self.log('WARNING', f"奖励缺少稀有度字段，已设置为普通: {reward}", 'SERVER')
            
            # 应用奖励到玩家数据
            self._apply_lucky_draw_rewards(player_data, rewards)
            
            # 记录抽奖历史
            if "lucky_draw_history" not in player_data:
                player_data["lucky_draw_history"] = []
            
            draw_record = {
                "date": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "type": draw_type,
                "cost": total_cost,
                "rewards": rewards
            }
            player_data["lucky_draw_history"].append(draw_record)
            
            # 只保留最近100次记录
            if len(player_data["lucky_draw_history"]) > 100:
                player_data["lucky_draw_history"] = player_data["lucky_draw_history"][-100:]
            
            # 保存玩家数据
            self.save_player_data(username, player_data)
            
            self.log('INFO', f"玩家 {username} 进行{draw_type}抽奖，花费 {total_cost} 金币，获得 {len(rewards)} 个奖励", 'SERVER')
            
            return self.send_data(client_id, {
                "type": "lucky_draw_response",
                "success": True,
                "message": f"{draw_type}抽奖成功！",
                "draw_type": draw_type,
                "cost": total_cost,
                "rewards": rewards,
                "updated_data": {
                    "money": player_data["money"],
                    "experience": player_data["experience"],
                    "level": player_data["level"],
                    "player_bag": player_data.get("player_bag", [])
                }
            })
            
        except Exception as e:
            # 捕获所有异常，防止服务器崩溃
            self.log('ERROR', f"处理玩家抽奖请求时出错: {str(e)}", 'SERVER')
            
            # 尝试获取用户名
            try:
                username = self.user_data[client_id].get("username", "未知用户")
            except:
                username = "未知用户"
            
            # 发送错误响应
            return self.send_data(client_id, {
                "type": "lucky_draw_response",
                "success": False,
                "message": "服务器处理抽奖时出现错误，请稍后重试"
            })
    
    #生成幸运抽奖奖励
    def _generate_lucky_draw_rewards(self, count: int, draw_type: str):
        """生成幸运抽奖奖励"""
        import random
        
        # 加载作物配置
        crop_data = self._load_crop_data()
        
        rewards = []
        
        # 根据 crop_data.json 构建奖励池
        common_seeds = []
        good_seeds = []
        rare_seeds = []
        epic_seeds = []
        legendary_seeds = []
        
        for crop_name, crop_info in crop_data.items():
            if not crop_info.get("能否购买", True):
                continue  # 跳过不能购买的作物
                
            quality = crop_info.get("品质", "普通")
            if quality == "普通":
                common_seeds.append(crop_name)
            elif quality == "优良":
                good_seeds.append(crop_name)
            elif quality == "稀有":
                rare_seeds.append(crop_name)
            elif quality == "史诗":
                epic_seeds.append(crop_name)
            elif quality == "传奇":
                legendary_seeds.append(crop_name)
        
        # 十连抽保底机制：至少一个稀有以上
        guaranteed_rare = (draw_type == "ten")
        rare_given = False
        
        for i in range(count):
            # 生成单个奖励
            reward = self._generate_single_lucky_reward(
                common_seeds, good_seeds, rare_seeds, epic_seeds, legendary_seeds,
                guaranteed_rare and i == count - 1 and not rare_given
            )
            
            # 检查是否给出了稀有奖励（使用安全的方式访问）
            reward_rarity = reward.get("rarity", "普通")
            if reward_rarity in ["稀有", "史诗", "传奇"]:
                rare_given = True
            
            rewards.append(reward)
        
        return rewards
    
    #生成单个抽奖奖励
    def _generate_single_lucky_reward(self, common_seeds, good_seeds, rare_seeds, epic_seeds, legendary_seeds, force_rare=False):
        """生成单个幸运抽奖奖励"""
        import random
        
        # 概率配置
        if force_rare:
            # 强制稀有：33%稀有，33%史诗，34%传奇
            rand = random.random()
            if rand < 0.33:
                reward_type = "rare"
            elif rand < 0.66:
                reward_type = "epic"
            else:
                reward_type = "legendary"
        else:
            # 正常概率：45%普通，25%优良，15%空奖，12%稀有，2.5%史诗，0.5%传奇
            rand = random.random()
            if rand < 0.45:
                reward_type = "common"
            elif rand < 0.70:
                reward_type = "good"
            elif rand < 0.85:
                reward_type = "empty"
            elif rand < 0.97:
                reward_type = "rare"
            elif rand < 0.995:
                reward_type = "epic"
            else:
                reward_type = "legendary"
        
        reward = {}
        
        if reward_type == "empty":
            # 谢谢惠顾
            empty_messages = ["谢谢惠顾", "下次再来", "再试一次", "继续努力"]
            reward = {
                "type": "empty",
                "name": random.choice(empty_messages),
                "rarity": "空奖",
                "amount": 0
            }
        
        elif reward_type == "common":
            # 普通奖励：金币、经验或普通种子
            reward_choice = random.choice(["coins", "exp", "seed"])
            if reward_choice == "coins":
                reward = {
                    "type": "coins",
                    "name": "金币",
                    "rarity": "普通",
                    "amount": random.randint(100, 300)
                }
            elif reward_choice == "exp":
                reward = {
                    "type": "exp",
                    "name": "经验",
                    "rarity": "普通",
                    "amount": random.randint(50, 150)
                }
            else:  # seed
                if common_seeds:
                    seed_name = random.choice(common_seeds)
                    reward = {
                        "type": "seed",
                        "name": seed_name,
                        "rarity": "普通",
                        "amount": random.randint(2, 4)
                    }
                else:
                    reward = {
                        "type": "coins",
                        "name": "金币",
                        "rarity": "普通",
                        "amount": random.randint(100, 300)
                    }
        
        elif reward_type == "good":
            # 优良奖励：更多金币经验或优良种子
            reward_choice = random.choice(["coins", "exp", "seed", "package"])
            if reward_choice == "coins":
                reward = {
                    "type": "coins",
                    "name": "金币",
                    "rarity": "优良",
                    "amount": random.randint(300, 600)
                }
            elif reward_choice == "exp":
                reward = {
                    "type": "exp",
                    "name": "经验",
                    "rarity": "优良",
                    "amount": random.randint(150, 300)
                }
            elif reward_choice == "seed":
                if good_seeds:
                    seed_name = random.choice(good_seeds)
                    reward = {
                        "type": "seed",
                        "name": seed_name,
                        "rarity": "优良",
                        "amount": random.randint(1, 3)
                    }
                else:
                    reward = {
                        "type": "coins",
                        "name": "金币",
                        "rarity": "优良",
                        "amount": random.randint(300, 600)
                    }
            else:  # package
                reward = {
                    "type": "package",
                    "name": "成长套餐",
                    "rarity": "优良",
                    "amount": 1,
                    "contents": [
                        {"type": "coins", "amount": random.randint(200, 400)},
                        {"type": "exp", "amount": random.randint(100, 200)},
                        {"type": "seed", "name": random.choice(common_seeds) if common_seeds else "小麦", "amount": random.randint(2, 3)}
                    ]
                }
        
        elif reward_type == "rare":
            # 稀有奖励
            reward_choice = random.choice(["coins", "exp", "seed", "package"])
            if reward_choice == "coins":
                reward = {
                    "type": "coins",
                    "name": "金币",
                    "rarity": "稀有",
                    "amount": random.randint(600, 1000)
                }
            elif reward_choice == "exp":
                reward = {
                    "type": "exp",
                    "name": "经验",
                    "rarity": "稀有",
                    "amount": random.randint(300, 500)
                }
            elif reward_choice == "seed":
                if rare_seeds:
                    seed_name = random.choice(rare_seeds)
                    reward = {
                        "type": "seed",
                        "name": seed_name,
                        "rarity": "稀有",
                        "amount": random.randint(1, 2)
                    }
                else:
                    reward = {
                        "type": "coins",
                        "name": "金币",
                        "rarity": "稀有",
                        "amount": random.randint(600, 1000)
                    }
            else:  # package
                reward = {
                    "type": "package",
                    "name": "稀有礼包",
                    "rarity": "稀有",
                    "amount": 1,
                    "contents": [
                        {"type": "coins", "amount": random.randint(400, 700)},
                        {"type": "exp", "amount": random.randint(200, 350)},
                        {"type": "seed", "name": random.choice(good_seeds) if good_seeds else "番茄", "amount": random.randint(2, 3)}
                    ]
                }
        
        elif reward_type == "epic":
            # 史诗奖励
            reward_choice = random.choice(["coins", "exp", "seed", "package"])
            if reward_choice == "coins":
                reward = {
                    "type": "coins",
                    "name": "金币",
                    "rarity": "史诗",
                    "amount": random.randint(1000, 1500)
                }
            elif reward_choice == "exp":
                reward = {
                    "type": "exp",
                    "name": "经验",
                    "rarity": "史诗",
                    "amount": random.randint(500, 800)
                }
            elif reward_choice == "seed":
                if epic_seeds:
                    seed_name = random.choice(epic_seeds)
                    reward = {
                        "type": "seed",
                        "name": seed_name,
                        "rarity": "史诗",
                        "amount": 1
                    }
                else:
                    reward = {
                        "type": "coins",
                        "name": "金币",
                        "rarity": "史诗",
                        "amount": random.randint(1000, 1500)
                    }
            else:  # package
                reward = {
                    "type": "package",
                    "name": "史诗礼包",
                    "rarity": "史诗",
                    "amount": 1,
                    "contents": [
                        {"type": "coins", "amount": random.randint(700, 1200)},
                        {"type": "exp", "amount": random.randint(350, 600)},
                        {"type": "seed", "name": random.choice(rare_seeds) if rare_seeds else "草莓", "amount": random.randint(1, 2)}
                    ]
                }
        
        else:  # legendary
            # 传奇奖励
            reward_choice = random.choice(["coins", "exp", "seed", "package"])
            if reward_choice == "coins":
                reward = {
                    "type": "coins",
                    "name": "金币",
                    "rarity": "传奇",
                    "amount": random.randint(1500, 2500)
                }
            elif reward_choice == "exp":
                reward = {
                    "type": "exp",
                    "name": "经验",
                    "rarity": "传奇",
                    "amount": random.randint(800, 1200)
                }
            elif reward_choice == "seed":
                if legendary_seeds:
                    seed_name = random.choice(legendary_seeds)
                    reward = {
                        "type": "seed",
                        "name": seed_name,
                        "rarity": "传奇",
                        "amount": 1
                    }
                else:
                    reward = {
                        "type": "coins",
                        "name": "金币",
                        "rarity": "传奇",
                        "amount": random.randint(1500, 2500)
                    }
            else:  # package
                reward = {
                    "type": "package",
                    "name": "传奇大礼包",
                    "rarity": "传奇",
                    "amount": 1,
                    "contents": [
                        {"type": "coins", "amount": random.randint(1000, 2000)},
                        {"type": "exp", "amount": random.randint(600, 1000)},
                        {"type": "seed", "name": random.choice(epic_seeds) if epic_seeds else "葡萄", "amount": 1},
                        {"type": "seed", "name": random.choice(rare_seeds) if rare_seeds else "草莓", "amount": random.randint(2, 3)}
                    ]
                }
        
        # 确保所有奖励都有基本字段
        if not reward.get("rarity"):
            reward["rarity"] = "普通"
        if not reward.get("amount"):
            reward["amount"] = 0
        if not reward.get("type"):
            reward["type"] = "empty"
        if not reward.get("name"):
            reward["name"] = "未知奖励"
        
        return reward
    
    #应用幸运抽奖奖励到玩家数据
    def _apply_lucky_draw_rewards(self, player_data, rewards):
        """应用幸运抽奖奖励到玩家数据"""
        for reward in rewards:
            reward_type = reward.get("type", "empty")
            
            if reward_type == "empty":
                continue  # 空奖励不处理
            
            elif reward_type == "coins":
                player_data["money"] = player_data.get("money", 0) + reward.get("amount", 0)
            
            elif reward_type == "exp":
                player_data["experience"] = player_data.get("experience", 0) + reward.get("amount", 0)
                
                # 检查升级
                level_up_experience = 100 * player_data.get("level", 1)
                while player_data.get("experience", 0) >= level_up_experience:
                    player_data["level"] = player_data.get("level", 1) + 1
                    player_data["experience"] -= level_up_experience
                    level_up_experience = 100 * player_data["level"]
            
            elif reward_type == "seed":
                if "player_bag" not in player_data:
                    player_data["player_bag"] = []
                
                # 查找背包中是否已有该种子
                found = False
                for item in player_data["player_bag"]:
                    if item.get("name") == reward.get("name", ""):
                        item["count"] += reward.get("amount", 0)
                        found = True
                        break
                
                # 如果背包中没有，添加新条目
                if not found:
                    player_data["player_bag"].append({
                        "name": reward.get("name", "未知种子"),
                        "quality": reward.get("rarity", "普通"),
                        "count": reward.get("amount", 0)
                    })
            
            elif reward_type == "package":
                # 递归处理礼包内容
                contents = reward.get("contents", [])
                if contents:
                    # 为礼包内容添加默认的rarity字段
                    for content in contents:
                        if not content.get("rarity"):
                            content["rarity"] = reward.get("rarity", "普通")
                    
                    # 递归处理礼包内容
                    self._apply_lucky_draw_rewards(player_data, contents)
    
#==========================幸运抽奖处理==========================




#==========================发送游戏操作错误处理==========================
    #发送游戏操作错误
    def _send_action_error(self, client_id, action_type, message):
        """发送游戏操作错误响应"""
        return self.send_data(client_id, {
            "type": "action_response",
            "action_type": action_type,
            "success": False,
            "message": message
        })
#==========================发送游戏操作错误处理==========================   




#==========================缓存数据处理==========================
    #清理过期的缓存数据
    def cleanup_expired_cache(self):
        """清理过期的缓存数据"""
        current_time = time.time()
        expired_players = []
        
        for account_id, cache_data in self.active_players_cache.items():
            if current_time - cache_data.get("last_access", 0) > self.cache_expire_time:
                expired_players.append(account_id)
        
        for account_id in expired_players:
            # 如果是脏数据，先保存
            if account_id in self.dirty_players:
                self.save_player_data_immediate(account_id)
                self.dirty_players.discard(account_id)
            
            # 移除过期缓存
            self.player_cache.pop(account_id, None)
            self.active_players_cache.pop(account_id, None)
        
        if expired_players:
            self.log('INFO', f"清理了 {len(expired_players)} 个过期缓存", 'SERVER')
    
    #批量保存脏数据到磁盘
    def batch_save_dirty_players(self):
        """批量保存脏数据到磁盘"""
        if not self.dirty_players:
            return
        
        saved_count = 0
        for account_id in list(self.dirty_players):
            try:
                if self.save_player_data_immediate(account_id):
                    saved_count += 1
            except Exception as e:
                self.log('ERROR', f"保存玩家 {account_id} 数据时出错: {str(e)}", 'SERVER')
        
        self.dirty_players.clear()
        self.last_save_time = time.time()
        
        if saved_count > 0:
            self.log('INFO', f"批量保存了 {saved_count} 个玩家的数据", 'SERVER')
    
    #强制保存所有缓存数据
    def force_save_all_data(self):
        """强制保存所有缓存数据（用于服务器关闭时）"""
        saved_count = 0
        for account_id in list(self.player_cache.keys()):
            try:
                if self.save_player_data_immediate(account_id):
                    saved_count += 1
            except Exception as e:
                self.log('ERROR', f"强制保存玩家 {account_id} 数据时出错: {str(e)}", 'SERVER')
        
        self.dirty_players.clear()
        self.log('INFO', f"强制保存完成，保存了 {saved_count} 个玩家的数据", 'SERVER')
        return saved_count
    
    #优化缓存大小，移除不活跃的数据
    def optimize_cache_size(self):
        """优化缓存大小，移除不活跃的数据"""
        current_time = time.time()
        removed_count = 0
        
        # 如果缓存过大，移除最不活跃的数据
        if len(self.player_cache) > 1000:  # 缓存超过1000个玩家时进行清理
            sorted_players = sorted(
                self.active_players_cache.items(),
                key=lambda x: x[1].get("last_access", 0)
            )
            
            # 移除最不活跃的50%
            remove_count = len(sorted_players) // 2
            for account_id, _ in sorted_players[:remove_count]:
                if account_id in self.dirty_players:
                    self.save_player_data_immediate(account_id)
                    self.dirty_players.discard(account_id)
                
                self.player_cache.pop(account_id, None)
                self.active_players_cache.pop(account_id, None)
                removed_count += 1
        
        if removed_count > 0:
            self.log('INFO', f"缓存优化：移除了 {removed_count} 个不活跃的缓存数据", 'SERVER')
        
        return removed_count

    #获取缓存命中信息（用于调试）
    def get_cache_hit_info(self, account_id):
        """获取缓存命中信息（用于调试）"""
        return {
            "in_memory_cache": account_id in self.player_cache,
            "in_active_cache": account_id in self.active_players_cache,
            "is_dirty": account_id in self.dirty_players,
            "last_access": self.active_players_cache.get(account_id, {}).get("last_access", 0)
        }

#==========================缓存数据处理==========================

# 主程序启动入口
if __name__ == "__main__":
    import sys
    
    try:
        print("=" * 60)
        print(f"🌱 萌芽农场游戏服务器 v{server_version} 🌱")
        print("=" * 60)
        print(f"📡 服务器地址: {server_host}:{server_port}")
        print(f"📦 缓冲区大小: {buffer_size} bytes")
        print(f"🔧 性能优化: 已启用")
        print("=" * 60)
        
        # 创建并启动游戏服务器
        server = TCPGameServer()
        
        # 在后台线程中启动服务器
        server_thread = threading.Thread(target=server.start)
        server_thread.daemon = True
        server_thread.start()
        
        print("✅ 服务器启动成功！")
        print("📋 功能列表:")
        print("   ├── 用户注册/登录系统")
        print("   ├── 作物种植与收获")
        print("   ├── 浇水与施肥系统")
        print("   ├── 每日签到奖励")
        print("   ├── 幸运抽奖系统")
        print("   ├── 玩家互动功能")
        print("   └── 性能优化缓存")
        print("=" * 60)
        print("🔥 服务器运行中... 按 Ctrl+C 停止服务器")
        print("=" * 60)
        
        # 主循环：保持服务器运行
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n" + "=" * 60)
        print("⚠️  程序被用户中断")
        print("💾 正在保存数据并关闭服务器...")
        
        if 'server' in locals():
            server.stop()
            
        print("✅ 服务器已安全关闭")
        print("👋 感谢使用萌芽农场服务器！")
        print("=" * 60)
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ 服务器启动失败: {str(e)}")
        print("🔧 请检查配置并重试")
        sys.exit(1) 