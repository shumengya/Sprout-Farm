"""
网络通信核心模块
====================================================================
- 负责处理客户端与服务端之间的消息路由
- 将消息类型映射到对应的处理函数
- 提供统一的消息处理接口
====================================================================
"""

class MessageHandler:
    """
    消息处理器类
    负责将客户端消息路由到对应的处理函数
    """
    
    def __init__(self, server_instance):
        """
        初始化消息处理器
        
        Args:
            server_instance: 服务器实例，用于调用具体的处理方法
        """
        self.server = server_instance
    
    def handle_message(self, client_id, message):
        """
        接收客户端消息并路由到对应处理函数
        这是服务端与客户端通信的核心中的核心
        
        Args:
            client_id: 客户端ID
            message: 消息内容（字典格式）
            
        Returns:
            处理结果
        """
        message_type = message.get("type", "")
        
        # 用户认证相关
        if message_type == "greeting":  # 默认欢迎
            return self.server._handle_greeting(client_id, message)
        elif message_type == "login":  # 玩家登录
            return self.server._handle_login(client_id, message)
        elif message_type == "register":  # 玩家注册
            return self.server._handle_register(client_id, message)
        elif message_type == "request_verification_code":  # 验证码请求
            return self.server._handle_verification_code_request(client_id, message)
        elif message_type == "request_forget_password_verification_code":  # 忘记密码验证码请求
            return self.server._handle_forget_password_verification_code_request(client_id, message)
        elif message_type == "reset_password":  # 重置密码
            return self.server._handle_reset_password_request(client_id, message)
        elif message_type == "verify_code":  # 验证码
            return self.server._handle_verify_code(client_id, message)
        
        # ---------------------------------------------------------------------------
        # 游戏操作相关 
        elif message_type == "harvest_crop":  # 收获作物
            return self.server._handle_harvest_crop(client_id, message)
        elif message_type == "plant_crop":  # 种植作物
            return self.server._handle_plant_crop(client_id, message)
        elif message_type == "buy_seed":  # 购买种子
            return self.server._handle_buy_seed(client_id, message)
        elif message_type == "buy_item":  # 购买道具
            return self.server._handle_buy_item(client_id, message)
        elif message_type == "buy_pet":  # 购买宠物
            return self.server._handle_buy_pet(client_id, message)
        elif message_type == "rename_pet":  # 重命名宠物
            return self.server._handle_rename_pet(client_id, message)
        elif message_type == "set_patrol_pet":  # 设置巡逻宠物
            return self.server._handle_set_patrol_pet(client_id, message)
        elif message_type == "set_battle_pet":  # 设置出战宠物
            return self.server._handle_set_battle_pet(client_id, message)
        elif message_type == "update_battle_pet_data":  # 更新宠物对战数据
            return self.server._handle_update_battle_pet_data(client_id, message)
        elif message_type == "feed_pet":  # 喂食宠物
            return self.server._handle_feed_pet(client_id, message)
        elif message_type == "dig_ground":  # 开垦土地
            return self.server._handle_dig_ground(client_id, message)
        elif message_type == "remove_crop":  # 铲除作物
            return self.server._handle_remove_crop(client_id, message)
        elif message_type == "water_crop":  # 浇水
            return self.server._handle_water_crop(client_id, message)
        elif message_type == "fertilize_crop":  # 施肥
            return self.server._handle_fertilize_crop(client_id, message)
        elif message_type == "use_item":  # 使用道具
            return self.server._handle_use_item(client_id, message)
        elif message_type == "upgrade_land":  # 升级土地
            return self.server._handle_upgrade_land(client_id, message)
        elif message_type == "buy_new_ground":  # 添加新的土地
            return self.server._handle_buy_new_ground(client_id, message)
        elif message_type == "like_player":  # 点赞玩家
            return self.server._handle_like_player(client_id, message)
        elif message_type == "request_online_players":  # 请求在线玩家
            return self.server._handle_online_players_request(client_id, message)
        elif message_type == "get_play_time":  # 获取游玩时间
            return self.server._handle_get_play_time(client_id)
        elif message_type == "update_play_time":  # 更新游玩时间
            return self.server._handle_update_play_time(client_id)
        elif message_type == "request_player_rankings":  # 请求玩家排行榜
            return self.server._handle_player_rankings_request(client_id, message)
        elif message_type == "request_crop_data":  # 请求作物数据
            return self.server._handle_crop_data_request(client_id)
        elif message_type == "request_item_config":  # 请求道具配置数据
            return self.server._handle_item_config_request(client_id)
        elif message_type == "request_pet_config":  # 请求宠物配置数据
            return self.server._handle_pet_config_request(client_id)
        elif message_type == "request_game_tips_config":  # 请求游戏小提示配置数据
            return self.server._handle_game_tips_config_request(client_id)
        elif message_type == "visit_player":  # 拜访其他玩家农场
            return self.server._handle_visit_player_request(client_id, message)
        elif message_type == "return_my_farm":  # 返回我的农场
            return self.server._handle_return_my_farm_request(client_id, message)
        elif message_type == "daily_check_in":  # 每日签到
            return self.server._handle_daily_check_in_request(client_id, message)
        elif message_type == "get_check_in_data":  # 获取签到数据
            return self.server._handle_get_check_in_data_request(client_id, message)
        elif message_type == "lucky_draw":  # 幸运抽奖
            return self.server._handle_lucky_draw_request(client_id, message)
        elif message_type == "claim_new_player_gift":  # 领取新手大礼包
            return self.server._handle_new_player_gift_request(client_id, message)
        elif message_type == "get_online_gift_data":  # 获取在线礼包数据
            return self.server._handle_get_online_gift_data_request(client_id, message)
        elif message_type == "claim_online_gift":  # 领取在线礼包
            return self.server._handle_claim_online_gift_request(client_id, message)
        elif message_type == "ping":  # 客户端ping请求
            return self.server._handle_ping_request(client_id, message)
        elif message_type == "modify_account_info":  # 修改账号信息
            return self.server._handle_modify_account_info_request(client_id, message)
        elif message_type == "delete_account":  # 删除账号
            return self.server._handle_delete_account_request(client_id, message)
        elif message_type == "refresh_player_info":  # 刷新玩家信息
            return self.server._handle_refresh_player_info_request(client_id, message)
        elif message_type == "global_broadcast":  # 全服大喇叭消息
            return self.server._handle_global_broadcast_message(client_id, message)
        elif message_type == "request_broadcast_history":  # 请求全服大喇叭历史消息
            return self.server._handle_request_broadcast_history(client_id, message)
        elif message_type == "use_pet_item":  # 宠物使用道具
            return self.server._handle_use_pet_item(client_id, message)
        elif message_type == "use_farm_item":  # 农场道具使用
            return self.server._handle_use_farm_item(client_id, message)
        elif message_type == "buy_scare_crow":  # 购买稻草人
            return self.server._handle_buy_scare_crow(client_id, message)
        elif message_type == "modify_scare_crow_config":  # 修改稻草人配置
            return self.server._handle_modify_scare_crow_config(client_id, message)
        elif message_type == "get_scare_crow_config":  # 获取稻草人配置
            return self.server._handle_get_scare_crow_config(client_id, message)
        elif message_type == "wisdom_tree_operation":  # 智慧树操作
            return self.server._handle_wisdom_tree_operation(client_id, message)
        elif message_type == "wisdom_tree_message":  # 智慧树消息
            return self.server._handle_wisdom_tree_message(client_id, message)
        elif message_type == "get_wisdom_tree_config":  # 获取智慧树配置
            return self.server._handle_get_wisdom_tree_config(client_id, message)
        elif message_type == "sell_crop":  # 出售作物
            return self.server._handle_sell_crop(client_id, message)
        elif message_type == "add_product_to_store":  # 添加商品到小卖部
            return self.server._handle_add_product_to_store(client_id, message)
        elif message_type == "remove_store_product":  # 下架小卖部商品
            return self.server._handle_remove_store_product(client_id, message)
        elif message_type == "buy_store_product":  # 购买小卖部商品
            return self.server._handle_buy_store_product(client_id, message)
        elif message_type == "buy_store_booth":  # 购买小卖部格子
            return self.server._handle_buy_store_booth(client_id, message)
        elif message_type == "save_game_settings":  # 保存游戏设置
            return self.server._handle_save_game_settings(client_id, message)
        elif message_type == "pet_battle_result":  # 宠物对战结果
            return self.server._handle_pet_battle_result(client_id, message)
        elif message_type == "today_divination":  # 今日占卜
            return self.server._handle_today_divination(client_id, message)
        elif message_type == "give_money":  # 送金币
            return self.server._handle_give_money_request(client_id, message)
        elif message_type == "sync_bag_data":  # 同步背包数据
            return self.server._handle_sync_bag_data(client_id, message)
        # ---------------------------------------------------------------------------
        
        # 管理员操作相关
        elif message_type == "kick_player":  # 踢出玩家
            return self.server._handle_kick_player(client_id, message)

        # elif message_type == "message":  # 处理聊天消息（暂未实现）
        #     return self.server._handle_chat_message(client_id, message)
        else:
            # 调用父类的默认处理方法
            return super(type(self.server), self.server)._handle_message(client_id, message)