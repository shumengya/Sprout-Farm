#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
萌芽农场 MongoDB 数据库 API
作者: AI Assistant
功能: 提供MongoDB数据库连接和游戏配置管理功能
"""

import pymongo
import json
from typing import Dict, Any, Optional, List
import logging
from datetime import datetime, timedelta
from bson import ObjectId

class SMYMongoDBAPI:
    def __init__(self, environment: str = "test"):
        """
        初始化MongoDB API
        
        Args:
            environment: 环境类型，"test" 表示测试环境，"production" 表示正式环境
        """
        self.environment = environment
        self.client = None
        self.db = None
        self.connected = False
        
        # 配置数据库连接信息
        self.config = {
            "test": {
                "host": "localhost",
                "port": 27017,
                "database": "mengyafarm",
                "username": None,
                "password": None
            },
            "production": {
                "host": "192.168.31.233", 
                "port": 27017,
                "database": "mengyafarm",
                "username": "shumengya",
                "password": "tyh@19900420"
            }
        }
        
        # 设置日志
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        
        # 连接数据库
        self.connect()
    
    def connect(self) -> bool:
        """
        连接到MongoDB数据库
        
        Returns:
            bool: 连接是否成功
        """
        try:
            from urllib.parse import quote_plus
            current_config = self.config[self.environment]
            
            # 构建连接字符串
            if current_config.get('username') and current_config.get('password'):
                # 对用户名和密码进行URL编码以处理特殊字符
                username = quote_plus(current_config['username'])
                password = quote_plus(current_config['password'])
                connection_string = f"mongodb://{username}:{password}@{current_config['host']}:{current_config['port']}/{current_config['database']}?authSource=admin"
            else:
                connection_string = f"mongodb://{current_config['host']}:{current_config['port']}/"
            
            self.client = pymongo.MongoClient(
                connection_string,
                serverSelectionTimeoutMS=5000,  # 5秒超时
                connectTimeoutMS=5000,
                socketTimeoutMS=5000
            )
            
            # 测试连接
            self.client.admin.command('ping')
            
            # 选择数据库
            self.db = self.client[current_config['database']]
            self.connected = True
            
            self.logger.info(f"成功连接到MongoDB数据库 [{self.environment}]: {connection_string}")
            return True
            
        except Exception as e:
            self.logger.error(f"连接MongoDB失败: {e}")
            self.connected = False
            return False
    
    def disconnect(self):
        """断开数据库连接"""
        if self.client:
            self.client.close()
            self.connected = False
            self.logger.info("已断开MongoDB连接")
    
    def is_connected(self) -> bool:
        """检查是否已连接到数据库"""
        return self.connected and self.client is not None
    
    def get_collection(self, collection_name: str):
        """
        获取集合对象
        
        Args:
            collection_name: 集合名称
            
        Returns:
            Collection: MongoDB集合对象
        """
        if not self.is_connected():
            raise Exception("数据库未连接")
        return self.db[collection_name]
    
    # ========================= 游戏配置管理 =========================
    
    def _get_config_by_id(self, object_id: str, config_name: str) -> Optional[Dict[str, Any]]:
        """
        通用方法：根据ObjectId获取配置
        
        Args:
            object_id: MongoDB文档ID
            config_name: 配置名称（用于日志）
            
        Returns:
            Dict: 配置数据，如果未找到返回None
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用ObjectId查找文档
            oid = ObjectId(object_id)
            result = collection.find_one({"_id": oid})
            
            if result:
                # 移除MongoDB的_id字段和updated_at字段
                if "_id" in result:
                    del result["_id"]
                if "updated_at" in result:
                    del result["updated_at"]
                    
                self.logger.info(f"成功获取{config_name}")
                return result
            else:
                self.logger.warning(f"未找到{config_name}")
                return None
                
        except Exception as e:
            self.logger.error(f"获取{config_name}失败: {e}")
            return None
    
    def _update_config_by_id(self, object_id: str, config_data: Dict[str, Any], config_name: str) -> bool:
        """
        通用方法：根据ObjectId更新配置
        
        Args:
            object_id: MongoDB文档ID
            config_data: 配置数据
            config_name: 配置名称（用于日志）
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用ObjectId更新文档
            oid = ObjectId(object_id)
            
            # 添加更新时间
            update_data = {
                "updated_at": datetime.now(),
                **config_data
            }
            
            result = collection.replace_one({"_id": oid}, update_data)
            
            if result.acknowledged and result.matched_count > 0:
                self.logger.info(f"成功更新{config_name}")
                return True
            else:
                self.logger.error(f"更新{config_name}失败")
                return False
                
        except Exception as e:
            self.logger.error(f"更新{config_name}异常: {e}")
            return False
    
    def get_game_config(self, config_type: str) -> Optional[Dict[str, Any]]:
        """
        获取游戏配置（通过config_type）
        
        Args:
            config_type: 配置类型，如 "daily_checkin"
            
        Returns:
            Dict: 配置数据，如果未找到返回None
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 根据配置类型查找文档
            query = {"config_type": config_type}
            result = collection.find_one(query)
            
            if result:
                # 移除MongoDB的_id字段，只返回配置数据
                if "_id" in result:
                    del result["_id"]
                if "config_type" in result:
                    del result["config_type"]
                    
                self.logger.info(f"成功获取游戏配置: {config_type}")
                return result
            else:
                self.logger.warning(f"未找到游戏配置: {config_type}")
                return None
                
        except Exception as e:
            self.logger.error(f"获取游戏配置失败 [{config_type}]: {e}")
            return None
    def set_game_config(self, config_type: str, config_data: Dict[str, Any]) -> bool:
        """
        设置游戏配置
        
        Args:
            config_type: 配置类型
            config_data: 配置数据
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 准备文档数据
            document = {
                "config_type": config_type,
                "updated_at": datetime.now(),
                **config_data
            }
            
            # 使用upsert更新或插入
            query = {"config_type": config_type}
            result = collection.replace_one(query, document, upsert=True)
            
            if result.acknowledged:
                self.logger.info(f"成功设置游戏配置: {config_type}")
                return True
            else:
                self.logger.error(f"设置游戏配置失败: {config_type}")
                return False
                
        except Exception as e:
            self.logger.error(f"设置游戏配置异常 [{config_type}]: {e}")
            return False


    # ===================== 配置系统常量 =====================
    CONFIG_IDS = {
        "daily_checkin": "687cce278e77ba00a7414ba2",
        "lucky_draw": "687cd52e8e77ba00a7414ba3", 
        "new_player": "687cdbd78e77ba00a7414ba4",
        "wisdom_tree": "687cdfbe8e77ba00a7414ba5",
        "online_gift": "687ce7678e77ba00a7414ba6",
        "scare_crow": "687cea258e77ba00a7414ba8",
        "item": "687cf17c8e77ba00a7414baa",
        "pet": "687cf59b8e77ba00a7414bab",
        "stamina": "687cefba8e77ba00a7414ba9",
        "crop_data": "687cfb3d8e77ba00a7414bac",
        "initial_player_data": "687e2f3f8e77ba00a7414bb0",
        "verification_codes": "687e35078e77ba00a7414bb1"
    }
    
    #=====================每日签到系统======================
    def get_daily_checkin_config(self) -> Optional[Dict[str, Any]]:
        """获取每日签到配置"""
        return self._get_config_by_id(self.CONFIG_IDS["daily_checkin"], "每日签到配置")
    
    def update_daily_checkin_config(self, config_data: Dict[str, Any]) -> bool:
        """更新每日签到配置"""
        return self._update_config_by_id(self.CONFIG_IDS["daily_checkin"], config_data, "每日签到配置")
    #=====================每日签到系统======================


    #=====================幸运抽奖系统======================
    def get_lucky_draw_config(self) -> Optional[Dict[str, Any]]:
        """获取幸运抽奖配置"""
        return self._get_config_by_id(self.CONFIG_IDS["lucky_draw"], "幸运抽奖配置")
    
    def update_lucky_draw_config(self, config_data: Dict[str, Any]) -> bool:
        """更新幸运抽奖配置"""
        return self._update_config_by_id(self.CONFIG_IDS["lucky_draw"], config_data, "幸运抽奖配置")
    #=====================幸运抽奖系统======================


    #=====================新手大礼包系统======================
    def get_new_player_config(self) -> Optional[Dict[str, Any]]:
        """获取新手大礼包配置"""
        return self._get_config_by_id(self.CONFIG_IDS["new_player"], "新手大礼包配置")
    
    def update_new_player_config(self, config_data: Dict[str, Any]) -> bool:
        """更新新手大礼包配置"""
        return self._update_config_by_id(self.CONFIG_IDS["new_player"], config_data, "新手大礼包配置")
    #=====================新手大礼包系统======================


    #=====================智慧树系统======================
    def get_wisdom_tree_config(self) -> Optional[Dict[str, Any]]:
        """获取智慧树配置"""
        return self._get_config_by_id(self.CONFIG_IDS["wisdom_tree"], "智慧树配置")
    
    def update_wisdom_tree_config(self, config_data: Dict[str, Any]) -> bool:
        """更新智慧树配置"""
        return self._update_config_by_id(self.CONFIG_IDS["wisdom_tree"], config_data, "智慧树配置")
    #=====================智慧树系统======================


    #=====================稻草人系统======================
    def get_scare_crow_config(self) -> Optional[Dict[str, Any]]:
        """获取稻草人配置"""
        return self._get_config_by_id(self.CONFIG_IDS["scare_crow"], "稻草人配置")
    
    def update_scare_crow_config(self, config_data: Dict[str, Any]) -> bool:
        """更新稻草人配置"""
        return self._update_config_by_id(self.CONFIG_IDS["scare_crow"], config_data, "稻草人配置")
    #=====================稻草人系统======================


    #=====================在线礼包系统======================
    def get_online_gift_config(self) -> Optional[Dict[str, Any]]:
        """获取在线礼包配置"""
        return self._get_config_by_id(self.CONFIG_IDS["online_gift"], "在线礼包配置")
    
    def update_online_gift_config(self, config_data: Dict[str, Any]) -> bool:
        """更新在线礼包配置"""
        return self._update_config_by_id(self.CONFIG_IDS["online_gift"], config_data, "在线礼包配置")
    #=====================在线礼包系统======================


    #=====================道具配置系统======================
    def get_item_config(self) -> Optional[Dict[str, Any]]:
        """获取道具配置"""
        return self._get_config_by_id(self.CONFIG_IDS["item"], "道具配置")
    
    def update_item_config(self, config_data: Dict[str, Any]) -> bool:
        """更新道具配置"""
        return self._update_config_by_id(self.CONFIG_IDS["item"], config_data, "道具配置")
    #=====================道具配置系统======================


    #=====================宠物配置系统======================
    def get_pet_config(self) -> Optional[Dict[str, Any]]:
        """获取宠物配置"""
        return self._get_config_by_id(self.CONFIG_IDS["pet"], "宠物配置")
    
    def update_pet_config(self, config_data: Dict[str, Any]) -> bool:
        """更新宠物配置"""
        return self._update_config_by_id(self.CONFIG_IDS["pet"], config_data, "宠物配置")
    #=====================宠物配置系统======================


    #=====================体力系统======================
    def get_stamina_config(self) -> Optional[Dict[str, Any]]:
        """获取体力系统配置"""
        return self._get_config_by_id(self.CONFIG_IDS["stamina"], "体力系统配置")
    
    def update_stamina_config(self, config_data: Dict[str, Any]) -> bool:
        """更新体力系统配置"""
        return self._update_config_by_id(self.CONFIG_IDS["stamina"], config_data, "体力系统配置")
    #=====================体力系统======================


    #=====================作物数据系统======================
    def get_crop_data_config(self) -> Optional[Dict[str, Any]]:
        """获取作物数据配置"""
        return self._get_config_by_id(self.CONFIG_IDS["crop_data"], "作物数据配置")
    
    def update_crop_data_config(self, config_data: Dict[str, Any]) -> bool:
        """更新作物数据配置"""
        return self._update_config_by_id(self.CONFIG_IDS["crop_data"], config_data, "作物数据配置")
    #=====================作物数据系统======================


    #=====================初始玩家数据模板系统======================
    def get_initial_player_data_template(self) -> Optional[Dict[str, Any]]:
        """获取初始玩家数据模板"""
        return self._get_config_by_id(self.CONFIG_IDS["initial_player_data"], "初始玩家数据模板")
    
    def update_initial_player_data_template(self, template_data: Dict[str, Any]) -> bool:
        """更新初始玩家数据模板"""
        return self._update_config_by_id(self.CONFIG_IDS["initial_player_data"], template_data, "初始玩家数据模板")
    #=====================初始玩家数据模板系统======================


    def batch_update_offline_players_crops(self, growth_multiplier: float = 1.0, exclude_online_players: List[str] = None) -> int:
        """
        批量更新离线玩家的作物生长（优化版本，支持完整的加速效果计算）
        
        Args:
            growth_multiplier: 基础生长倍数，默认1.0
            exclude_online_players: 要排除的在线玩家列表
            
        Returns:
            int: 更新的玩家数量
        """
        try:
            import time
            from datetime import datetime
            
            collection = self.get_collection("playerdata")
            
            if exclude_online_players is None:
                exclude_online_players = []
            
            # 查询符合条件的玩家（包含注册时间用于新手奖励判断）
            query = {
                "玩家账号": {"$nin": exclude_online_players},
                "农场土地": {
                    "$elemMatch": {
                        "is_diged": True,
                        "is_planted": True,
                        "is_dead": False,
                        "grow_time": {"$exists": True},
                        "max_grow_time": {"$exists": True}
                    }
                }
            }
            
            # 获取需要更新的玩家数据（包含注册时间）
            players_cursor = collection.find(query, {"玩家账号": 1, "农场土地": 1, "注册时间": 1})
            updated_count = 0
            
            for player in players_cursor:
                account_id = player.get("玩家账号")
                farm_lands = player.get("农场土地", [])
                register_time_str = player.get("注册时间", "")
                
                # 判断是否享受新手奖励
                is_new_player_bonus = self._is_new_player_bonus_active(register_time_str)
                
                # 检查是否有需要更新的土地
                has_updates = False
                current_time = time.time()
                
                for land in farm_lands:
                    if (land.get("is_diged") and land.get("is_planted") and 
                        not land.get("is_dead") and 
                        land.get("grow_time", 0) < land.get("max_grow_time", 0)):
                        
                        # 计算生长速度增量（累加方式）
                        growth_increase = growth_multiplier  # 基础生长速度：每次更新增长1秒
                        
                        # 新手奖励：注册后3天内额外增加9秒（总共10倍速度）
                        if is_new_player_bonus:
                            growth_increase += 9
                        
                        # 土地等级影响 - 根据不同等级额外增加生长速度
                        land_level = land.get("土地等级", 0)
                        land_speed_bonus = {
                            0: 0,   # 默认土地：无额外加成
                            1: 1,   # 黄土地：额外+1秒（总共2倍速）
                            2: 3,   # 红土地：额外+3秒（总共4倍速）
                            3: 5,   # 紫土地：额外+5秒（总共6倍速）
                            4: 9    # 黑土地：额外+9秒（总共10倍速）
                        }
                        growth_increase += land_speed_bonus.get(land_level, 0)
                        
                        # 施肥影响 - 支持不同类型的道具施肥
                        if land.get("已施肥", False) and "施肥时间" in land:
                            fertilize_time = land.get("施肥时间", 0)
                            
                            # 获取施肥类型和对应的持续时间、加成
                            fertilize_duration = land.get("施肥持续时间", 600)  # 默认10分钟
                            fertilize_bonus = land.get("施肥加成", 1)  # 默认额外+1秒
                            
                            if current_time - fertilize_time <= fertilize_duration:
                                # 施肥效果仍在有效期内，累加施肥加成
                                growth_increase += fertilize_bonus
                            else:
                                # 施肥效果过期，清除施肥状态
                                land["已施肥"] = False
                                if "施肥时间" in land:
                                    del land["施肥时间"]
                                if "施肥类型" in land:
                                    del land["施肥类型"]
                                if "施肥倍数" in land:
                                    del land["施肥倍数"]
                                if "施肥持续时间" in land:
                                    del land["施肥持续时间"]
                                if "施肥加成" in land:
                                    del land["施肥加成"]
                        
                        # 确保最小增长量为1
                        if growth_increase < 1:
                            growth_increase = 1
                        
                        # 更新生长时间，但不超过最大生长时间
                        new_grow_time = min(
                            land["grow_time"] + growth_increase,
                            land["max_grow_time"]
                        )
                        land["grow_time"] = new_grow_time
                        has_updates = True
                
                # 如果有更新，保存到数据库
                if has_updates:
                    update_result = collection.update_one(
                        {"玩家账号": account_id},
                        {
                            "$set": {
                                "农场土地": farm_lands,
                                "updated_at": datetime.now()
                            }
                        }
                    )
                    
                    if update_result.acknowledged and update_result.matched_count > 0:
                        updated_count += 1
            
            self.logger.info(f"批量更新了 {updated_count} 个离线玩家的作物生长（包含完整加速效果）")
            return updated_count
            
        except Exception as e:
            self.logger.error(f"批量更新离线玩家作物失败: {e}")
            return 0
    
    def _is_new_player_bonus_active(self, register_time_str: str) -> bool:
        """
        检查玩家是否在新玩家奖励期内（注册后3天内享受10倍生长速度）
        
        Args:
            register_time_str: 注册时间字符串
            
        Returns:
            bool: 是否享受新手奖励
        """
        try:
            import datetime
            
            # 如果没有注册时间或者是默认的老玩家时间，则不享受奖励
            if not register_time_str or register_time_str == "2025年05月21日15时00分00秒":
                return False
            
            # 解析注册时间
            register_time = datetime.datetime.strptime(register_time_str, "%Y年%m月%d日%H时%M分%S秒")
            current_time = datetime.datetime.now()
            
            # 计算注册天数
            time_diff = current_time - register_time
            days_since_register = time_diff.total_seconds() / 86400  # 转换为天数
            
            # 3天内享受新玩家奖励
            return days_since_register <= 3
            
        except ValueError as e:
            self.logger.warning(f"解析注册时间格式错误: {register_time_str}, 错误: {str(e)}")
            return False
    
    # 注意：get_offline_players_with_crops 方法已被移除
    # 现在使用优化的 batch_update_offline_players_crops 方法直接在 MongoDB 中处理查询和更新
    #=====================玩家数据管理======================

    # ========================= 验证码系统 =========================
    
    def save_verification_code(self, qq_number: str, verification_code: str, 
                              expiry_time: int = 300, code_type: str = "register") -> bool:
        """
        保存验证码到MongoDB
        
        Args:
            qq_number: QQ号
            verification_code: 验证码
            expiry_time: 过期时间（秒），默认5分钟
            code_type: 验证码类型，"register" 或 "reset_password"
            
        Returns:
            bool: 保存成功返回True，否则返回False
        """
        try:
            import time
            from datetime import datetime, timedelta
            
            collection = self.get_collection("verification_codes")
            
            # 计算过期时间
            expire_at = datetime.now() + timedelta(seconds=expiry_time)
            
            # 验证码文档
            verification_doc = {
                "qq_number": qq_number,
                "code": verification_code,
                "code_type": code_type,
                "created_at": datetime.now(),
                "expire_at": expire_at,
                "used": False
            }
            
            # 使用upsert更新或插入（覆盖同一QQ号的旧验证码）
            query = {"qq_number": qq_number, "code_type": code_type}
            result = collection.replace_one(query, verification_doc, upsert=True)
            
            if result.acknowledged:
                self.logger.info(f"成功保存验证码: QQ {qq_number}, 类型 {code_type}")
                return True
            else:
                self.logger.error(f"保存验证码失败: QQ {qq_number}")
                return False
                
        except Exception as e:
            self.logger.error(f"保存验证码异常 [QQ {qq_number}]: {e}")
            return False
    
    def verify_verification_code(self, qq_number: str, input_code: str, 
                                code_type: str = "register") -> tuple[bool, str]:
        """
        验证用户输入的验证码
        
        Args:
            qq_number: QQ号
            input_code: 用户输入的验证码
            code_type: 验证码类型，"register" 或 "reset_password"
            
        Returns:
            tuple: (验证成功, 消息)
        """
        try:
            from datetime import datetime
            
            collection = self.get_collection("verification_codes")
            
            # 查找验证码
            query = {"qq_number": qq_number, "code_type": code_type}
            code_doc = collection.find_one(query)
            
            if not code_doc:
                return False, "验证码不存在，请重新获取"
            
            # 检查是否已使用
            if code_doc.get("used", False):
                return False, "验证码已使用，请重新获取"
            
            # 检查是否过期
            if datetime.now() > code_doc.get("expire_at", datetime.now()):
                return False, "验证码已过期，请重新获取"
            
            # 验证码码
            if input_code.upper() != code_doc.get("code", "").upper():
                return False, "验证码错误，请重新输入"
            
            # 标记为已使用
            update_result = collection.update_one(
                query, 
                {"$set": {"used": True, "used_at": datetime.now()}}
            )
            
            if update_result.acknowledged:
                self.logger.info(f"验证码验证成功: QQ {qq_number}, 类型 {code_type}")
                return True, "验证码验证成功"
            else:
                self.logger.error(f"标记验证码已使用失败: QQ {qq_number}")
                return False, "验证码验证失败"
                
        except Exception as e:
            self.logger.error(f"验证验证码异常 [QQ {qq_number}]: {e}")
            return False, "验证码验证失败"
    
    def clean_expired_verification_codes(self) -> int:
        """
        清理过期的验证码和已使用的验证码
        
        Returns:
            int: 清理的验证码数量
        """
        try:
            from datetime import datetime, timedelta
            
            collection = self.get_collection("verification_codes")
            
            current_time = datetime.now()
            one_hour_ago = current_time - timedelta(hours=1)
            
            # 删除条件：过期的验证码 或 已使用超过1小时的验证码
            delete_query = {
                "$or": [
                    {"expire_at": {"$lt": current_time}},  # 过期的
                    {"used": True, "used_at": {"$lt": one_hour_ago}}  # 已使用超过1小时的
                ]
            }
            
            result = collection.delete_many(delete_query)
            
            if result.acknowledged:
                deleted_count = result.deleted_count
                self.logger.info(f"清理验证码完成: 删除了 {deleted_count} 个验证码")
                return deleted_count
            else:
                self.logger.error("清理验证码失败")
                return 0
                
        except Exception as e:
            self.logger.error(f"清理验证码异常: {e}")
            return 0
    
    #=====================验证码系统======================

    # ========================= 通用数据库操作 =========================
    
    def get_player_data(self, account_id: str) -> Optional[Dict[str, Any]]:
        """获取玩家数据
        
        Args:
            account_id: 玩家账号ID
            
        Returns:
            Dict: 玩家数据，如果未找到返回None
        """
        try:
            collection = self.get_collection("playerdata")
            
            # 根据玩家账号查找文档
            query = {"玩家账号": account_id}
            result = collection.find_one(query)
            
            if result:
                # 移除MongoDB的_id字段
                if "_id" in result:
                    del result["_id"]
                
                # 转换datetime对象为字符串，避免JSON序列化错误
                result = self._convert_datetime_to_string(result)
                    
                self.logger.info(f"成功获取玩家数据: {account_id}")
                return result
            else:
                self.logger.warning(f"未找到玩家数据: {account_id}")
                return None
                
        except Exception as e:
            self.logger.error(f"获取玩家数据失败 [{account_id}]: {e}")
            return None
    
    def save_player_data(self, account_id: str, player_data: Dict[str, Any]) -> bool:
        """保存玩家数据
        
        Args:
            account_id: 玩家账号ID
            player_data: 玩家数据
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection("playerdata")
            
            # 添加更新时间
            update_data = {
                "updated_at": datetime.now(),
                **player_data
            }
            
            # 使用upsert更新或插入
            query = {"玩家账号": account_id}
            result = collection.replace_one(query, update_data, upsert=True)
            
            if result.acknowledged:
                self.logger.info(f"成功保存玩家数据: {account_id}")
                return True
            else:
                self.logger.error(f"保存玩家数据失败: {account_id}")
                return False
                
        except Exception as e:
            self.logger.error(f"保存玩家数据异常 [{account_id}]: {e}")
            return False
    
    def delete_player_data(self, account_id: str) -> bool:
        """删除玩家数据
        
        Args:
            account_id: 玩家账号ID
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection("playerdata")
            
            query = {"玩家账号": account_id}
            result = collection.delete_one(query)
            
            if result.acknowledged and result.deleted_count > 0:
                self.logger.info(f"成功删除玩家数据: {account_id}")
                return True
            else:
                self.logger.warning(f"删除玩家数据失败或数据不存在: {account_id}")
                return False
                
        except Exception as e:
            self.logger.error(f"删除玩家数据异常 [{account_id}]: {e}")
            return False
    
    def get_all_players_basic_info(self, projection: Dict[str, int] = None) -> List[Dict[str, Any]]:
        """获取所有玩家的基本信息（优化版本，用于排行榜等）
        
        Args:
            projection: 字段投影，指定需要返回的字段
            
        Returns:
            List: 玩家基本信息列表
        """
        try:
            collection = self.get_collection("playerdata")
            
            # 默认投影字段（只获取必要信息）
            if projection is None:
                projection = {
                    "_id": 0,
                    "玩家账号": 1,
                    "玩家昵称": 1,
                    "农场名称": 1,
                    "等级": 1,
                    "钱币": 1,
                    "经验值": 1,
                    "最后登录时间": 1,
                    "总游玩时间": 1,
                    "种子仓库": 1,
                    "点赞系统": 1,
                    "体力系统.当前体力值": 1
                }
            
            cursor = collection.find({}, projection)
            players = list(cursor)
            
            # 转换datetime对象为字符串
            players = [self._convert_datetime_to_string(player) for player in players]
            
            self.logger.info(f"成功获取 {len(players)} 个玩家的基本信息")
            return players
            
        except Exception as e:
            self.logger.error(f"获取玩家基本信息失败: {e}")
            return []
    
    def get_players_by_condition(self, condition: Dict[str, Any], 
                                projection: Dict[str, int] = None,
                                limit: int = 0) -> List[Dict[str, Any]]:
        """根据条件获取玩家数据
        
        Args:
            condition: 查询条件
            projection: 字段投影
            limit: 限制数量
            
        Returns:
            List: 符合条件的玩家数据列表
        """
        try:
            collection = self.get_collection("playerdata")
            
            cursor = collection.find(condition, projection)
            if limit > 0:
                cursor = cursor.limit(limit)
            
            players = list(cursor)
            
            # 移除_id字段并转换datetime对象
            for player in players:
                if "_id" in player:
                    del player["_id"]
                player = self._convert_datetime_to_string(player)
            
            # 重新转换整个列表确保所有datetime都被处理
            players = [self._convert_datetime_to_string(player) for player in players]
            
            self.logger.info(f"根据条件查询到 {len(players)} 个玩家")
            return players
            
        except Exception as e:
            self.logger.error(f"根据条件获取玩家数据失败: {e}")
            return []
    
    def get_offline_players(self, offline_days: int = 3) -> List[Dict[str, Any]]:
        """获取长时间离线的玩家（用于杂草生长等）
        
        Args:
            offline_days: 离线天数阈值
            
        Returns:
            List: 离线玩家数据列表
        """
        try:
            import time
            from datetime import datetime, timedelta
            
            # 计算阈值时间戳
            threshold_time = datetime.now() - timedelta(days=offline_days)
            
            collection = self.get_collection("playerdata")
            
            # 查询条件：最后登录时间早于阈值
            # 注意：这里需要根据实际的时间格式进行调整
            cursor = collection.find({
                "最后登录时间": {"$exists": True}
            }, {
                "_id": 0,
                "玩家账号": 1,
                "最后登录时间": 1,
                "农场土地": 1
            })
            
            offline_players = []
            for player in cursor:
                last_login = player.get("最后登录时间", "")
                if self._is_player_offline_by_time(last_login, offline_days):
                    offline_players.append(player)
            
            # 转换datetime对象为字符串
            offline_players = [self._convert_datetime_to_string(player) for player in offline_players]
            
            self.logger.info(f"找到 {len(offline_players)} 个离线超过 {offline_days} 天的玩家")
            return offline_players
            
        except Exception as e:
            self.logger.error(f"获取离线玩家失败: {e}")
            return []
    
    def _is_player_offline_by_time(self, last_login_str: str, offline_days: int) -> bool:
        """检查玩家是否离线超过指定天数"""
        try:
            if not last_login_str or last_login_str == "未知":
                return False
            
            # 解析时间格式：2024年01月01日12时30分45秒
            import datetime
            dt = datetime.datetime.strptime(last_login_str, "%Y年%m月%d日%H时%M分%S秒")
            
            # 计算离线天数
            now = datetime.datetime.now()
            offline_duration = now - dt
            return offline_duration.days >= offline_days
            
        except Exception:
            return False
    
    def _convert_datetime_to_string(self, data: Any) -> Any:
        """
        递归转换数据中的datetime对象为字符串
        
        Args:
            data: 要转换的数据
            
        Returns:
            转换后的数据
        """
        from datetime import datetime
        
        if isinstance(data, datetime):
            return data.strftime("%Y年%m月%d日%H时%M分%S秒")
        elif isinstance(data, dict):
            return {key: self._convert_datetime_to_string(value) for key, value in data.items()}
        elif isinstance(data, list):
            return [self._convert_datetime_to_string(item) for item in data]
        else:
            return data
    
    def count_total_players(self) -> int:
        """统计玩家总数
        
        Returns:
            int: 玩家总数
        """
        try:
            collection = self.get_collection("playerdata")
            count = collection.count_documents({})
            
            self.logger.info(f"玩家总数: {count}")
            return count
            
        except Exception as e:
            self.logger.error(f"统计玩家总数失败: {e}")
            return 0
    
    def update_player_field(self, account_id: str, field_updates: Dict[str, Any]) -> bool:
        """更新玩家的特定字段
        
        Args:
            account_id: 玩家账号ID
            field_updates: 要更新的字段和值
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection("playerdata")
            
            # 添加更新时间
            update_data = {
                "updated_at": datetime.now(),
                **field_updates
            }
            
            query = {"玩家账号": account_id}
            result = collection.update_one(query, {"$set": update_data})
            
            if result.acknowledged and result.matched_count > 0:
                self.logger.info(f"成功更新玩家字段: {account_id}")
                return True
            else:
                self.logger.warning(f"更新玩家字段失败或玩家不存在: {account_id}")
                return False
                
        except Exception as e:
            self.logger.error(f"更新玩家字段异常 [{account_id}]: {e}")
            return False
    #=====================玩家数据管理======================

    # ========================= 验证码系统 =========================
    
    def save_verification_code(self, qq_number: str, verification_code: str, 
                              expiry_time: int = 300, code_type: str = "register") -> bool:
        """
        保存验证码到MongoDB
        
        Args:
            qq_number: QQ号
            verification_code: 验证码
            expiry_time: 过期时间（秒），默认5分钟
            code_type: 验证码类型，"register" 或 "reset_password"
            
        Returns:
            bool: 保存成功返回True，否则返回False
        """
        try:
            import time
            from datetime import datetime, timedelta
            
            collection = self.get_collection("verification_codes")
            
            # 计算过期时间
            expire_at = datetime.now() + timedelta(seconds=expiry_time)
            
            # 验证码文档
            verification_doc = {
                "qq_number": qq_number,
                "code": verification_code,
                "code_type": code_type,
                "created_at": datetime.now(),
                "expire_at": expire_at,
                "used": False
            }
            
            # 使用upsert更新或插入（覆盖同一QQ号的旧验证码）
            query = {"qq_number": qq_number, "code_type": code_type}
            result = collection.replace_one(query, verification_doc, upsert=True)
            
            if result.acknowledged:
                self.logger.info(f"成功保存验证码: QQ {qq_number}, 类型 {code_type}")
                return True
            else:
                self.logger.error(f"保存验证码失败: QQ {qq_number}")
                return False
                
        except Exception as e:
            self.logger.error(f"保存验证码异常 [QQ {qq_number}]: {e}")
            return False
    
    def verify_verification_code(self, qq_number: str, input_code: str, 
                                code_type: str = "register") -> tuple:
        """
        验证用户输入的验证码
        
        Args:
            qq_number: QQ号
            input_code: 用户输入的验证码
            code_type: 验证码类型，"register" 或 "reset_password"
            
        Returns:
            tuple: (验证成功, 消息)
        """
        try:
            from datetime import datetime
            
            collection = self.get_collection("verification_codes")
            
            # 查找验证码
            query = {"qq_number": qq_number, "code_type": code_type}
            code_doc = collection.find_one(query)
            
            if not code_doc:
                return False, "验证码不存在，请重新获取"
            
            # 检查是否已使用
            if code_doc.get("used", False):
                return False, "验证码已使用，请重新获取"
            
            # 检查是否过期
            if datetime.now() > code_doc.get("expire_at", datetime.now()):
                return False, "验证码已过期，请重新获取"
            
            # 验证码码
            if input_code.upper() != code_doc.get("code", "").upper():
                return False, "验证码错误，请重新输入"
            
            # 标记为已使用
            update_result = collection.update_one(
                query, 
                {"$set": {"used": True, "used_at": datetime.now()}}
            )
            
            if update_result.acknowledged:
                self.logger.info(f"验证码验证成功: QQ {qq_number}, 类型 {code_type}")
                return True, "验证码验证成功"
            else:
                self.logger.error(f"标记验证码已使用失败: QQ {qq_number}")
                return False, "验证码验证失败"
                
        except Exception as e:
            self.logger.error(f"验证验证码异常 [QQ {qq_number}]: {e}")
            return False, "验证码验证失败"
    
    def clean_expired_verification_codes(self) -> int:
        """
        清理过期的验证码和已使用的验证码
        
        Returns:
            int: 清理的验证码数量
        """
        try:
            from datetime import datetime, timedelta
            
            collection = self.get_collection("verification_codes")
            
            current_time = datetime.now()
            one_hour_ago = current_time - timedelta(hours=1)
            
            # 删除条件：过期的验证码 或 已使用超过1小时的验证码
            delete_query = {
                "$or": [
                    {"expire_at": {"$lt": current_time}},  # 过期的
                    {"used": True, "used_at": {"$lt": one_hour_ago}}  # 已使用超过1小时的
                ]
            }
            
            result = collection.delete_many(delete_query)
            
            if result.acknowledged:
                deleted_count = result.deleted_count
                self.logger.info(f"清理验证码完成: 删除了 {deleted_count} 个验证码")
                return deleted_count
            else:
                self.logger.error("清理验证码失败")
                return 0
                
        except Exception as e:
            self.logger.error(f"清理验证码异常: {e}")
            return 0
    
    #=====================验证码系统======================

    # ========================= 通用数据库操作 =========================
    
    def insert_document(self, collection_name: str, document: Dict[str, Any]) -> Optional[str]:
        """
        插入文档
        
        Args:
            collection_name: 集合名称
            document: 要插入的文档
            
        Returns:
            str: 插入的文档ID，失败返回None
        """
        try:
            collection = self.get_collection(collection_name)
            result = collection.insert_one(document)
            
            if result.acknowledged:
                self.logger.info(f"成功插入文档到集合 {collection_name}")
                return str(result.inserted_id)
            else:
                return None
                
        except Exception as e:
            self.logger.error(f"插入文档失败 [{collection_name}]: {e}")
            return None
    
    def find_documents(self, collection_name: str, query: Dict[str, Any] = None, 
                      limit: int = 0) -> List[Dict[str, Any]]:
        """
        查找文档
        
        Args:
            collection_name: 集合名称
            query: 查询条件
            limit: 限制返回数量，0表示不限制
            
        Returns:
            List: 文档列表
        """
        try:
            collection = self.get_collection(collection_name)
            
            if query is None:
                query = {}
            
            cursor = collection.find(query)
            if limit > 0:
                cursor = cursor.limit(limit)
            
            documents = list(cursor)
            
            # 转换ObjectId为字符串并转换datetime对象
            for doc in documents:
                if "_id" in doc:
                    doc["_id"] = str(doc["_id"])
            
            # 转换datetime对象为字符串
            documents = [self._convert_datetime_to_string(doc) for doc in documents]
            
            return documents
            
        except Exception as e:
            self.logger.error(f"查找文档失败 [{collection_name}]: {e}")
            return []
    
    def update_document(self, collection_name: str, query: Dict[str, Any], 
                       update: Dict[str, Any]) -> bool:
        """
        更新文档
        
        Args:
            collection_name: 集合名称
            query: 查询条件
            update: 更新数据
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection(collection_name)
            result = collection.update_one(query, {"$set": update})
            
            return result.acknowledged and result.matched_count > 0
            
        except Exception as e:
            self.logger.error(f"更新文档失败 [{collection_name}]: {e}")
            return False
    
    def delete_document(self, collection_name: str, query: Dict[str, Any]) -> bool:
        """
        删除文档
        
        Args:
            collection_name: 集合名称
            query: 查询条件
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection(collection_name)
            result = collection.delete_one(query)
            
            return result.acknowledged and result.deleted_count > 0
            
        except Exception as e:
            self.logger.error(f"删除文档失败 [{collection_name}]: {e}")
            return False
    
    # ========================= 聊天消息管理 =========================
    
    def save_chat_message(self, username: str, player_name: str, content: str) -> bool:
        """
        保存聊天消息到MongoDB（按天存储）
        
        Args:
            username: 用户名（QQ号）
            player_name: 玩家昵称
            content: 消息内容
            
        Returns:
            bool: 是否保存成功
        """
        try:
            import time
            from datetime import datetime
            
            collection = self.get_collection("chat")
            
            # 获取当前日期
            current_date = datetime.now().strftime("%Y-%m-%d")
            current_time = datetime.now()
            
            # 创建消息对象
            message = {
                "username": username,
                "player_name": player_name,
                "content": content,
                "timestamp": time.time(),
                "time_str": current_time.strftime("%Y年%m月%d日 %H:%M:%S")
            }
            
            # 查找当天的文档
            query = {"date": current_date}
            existing_doc = collection.find_one(query)
            
            if existing_doc:
                # 如果当天的文档已存在，添加消息到messages数组
                result = collection.update_one(
                    query,
                    {
                        "$push": {"messages": message},
                        "$set": {"updated_at": current_time}
                    }
                )
            else:
                # 如果当天的文档不存在，创建新文档
                new_doc = {
                    "date": current_date,
                    "messages": [message],
                    "created_at": current_time,
                    "updated_at": current_time
                }
                result = collection.insert_one(new_doc)
            
            if result.acknowledged:
                self.logger.info(f"成功保存聊天消息: {username} - {content[:20]}...")
                return True
            else:
                self.logger.error(f"保存聊天消息失败: {username}")
                return False
                
        except Exception as e:
            self.logger.error(f"保存聊天消息异常: {e}")
            return False
    
    def get_chat_history(self, days: int = 3, limit: int = 500) -> List[Dict[str, Any]]:
        """
        获取聊天历史消息（从按天存储的chat集合）
        
        Args:
            days: 获取最近几天的消息
            limit: 最大消息数量
            
        Returns:
            List: 聊天消息列表
        """
        try:
            from datetime import datetime, timedelta
            
            collection = self.get_collection("chat")
            
            # 计算日期范围
            end_date = datetime.now()
            start_date = end_date - timedelta(days=days-1)
            
            # 生成日期列表
            date_list = []
            current_date = start_date
            while current_date <= end_date:
                date_list.append(current_date.strftime("%Y-%m-%d"))
                current_date += timedelta(days=1)
            
            # 查询条件
            query = {"date": {"$in": date_list}}
            
            # 获取文档
            cursor = collection.find(query).sort("date", 1)
            docs = list(cursor)
            
            # 提取所有消息
            all_messages = []
            for doc in docs:
                messages = doc.get("messages", [])
                for msg in messages:
                    # 移除MongoDB的_id字段（如果存在）
                    if "_id" in msg:
                        del msg["_id"]
                    all_messages.append(msg)
            
            # 按时间戳排序
            all_messages.sort(key=lambda x: x.get("timestamp", 0))
            
            # 限制消息数量
            if len(all_messages) > limit:
                all_messages = all_messages[-limit:]
            
            self.logger.info(f"成功获取聊天历史: {len(all_messages)} 条消息（最近{days}天）")
            return all_messages
            
        except Exception as e:
            self.logger.error(f"获取聊天历史失败: {e}")
            return []
    
    def get_latest_chat_message(self) -> Optional[Dict[str, Any]]:
        """
        获取最新的聊天消息（从按天存储的chat集合）
        
        Returns:
            Dict: 最新的聊天消息，如果没有返回None
        """
        try:
            collection = self.get_collection("chat")
            
            # 按日期降序排序，获取最新的文档
            cursor = collection.find().sort("date", -1).limit(10)  # 获取最近10天的文档
            docs = list(cursor)
            
            latest_message = None
            latest_timestamp = 0
            
            # 遍历文档，找到最新的消息
            for doc in docs:
                messages = doc.get("messages", [])
                for msg in messages:
                    timestamp = msg.get("timestamp", 0)
                    if timestamp > latest_timestamp:
                        latest_timestamp = timestamp
                        latest_message = msg.copy()
                        # 移除MongoDB的_id字段（如果存在）
                        if "_id" in latest_message:
                            del latest_message["_id"]
            
            if latest_message:
                self.logger.info(f"成功获取最新聊天消息: {latest_message.get('content', '')[:20]}...")
                return latest_message
            else:
                self.logger.info("暂无聊天消息")
                return None
                
        except Exception as e:
            self.logger.error(f"获取最新聊天消息失败: {e}")
            return None
    
    def clean_old_chat_messages(self, keep_days: int = 30) -> int:
        """
        清理旧的聊天消息（从按天存储的chat集合）
        
        Args:
            keep_days: 保留最近几天的消息
            
        Returns:
            int: 删除的文档数量
        """
        try:
            from datetime import datetime, timedelta
            
            collection = self.get_collection("chat")
            
            # 计算删除日期点
            cutoff_date = datetime.now() - timedelta(days=keep_days)
            cutoff_date_str = cutoff_date.strftime("%Y-%m-%d")
            
            # 删除旧文档
            query = {"date": {"$lt": cutoff_date_str}}
            result = collection.delete_many(query)
            
            deleted_count = result.deleted_count
            self.logger.info(f"成功清理 {deleted_count} 个旧聊天文档（保留最近{keep_days}天）")
            return deleted_count
            
        except Exception as e:
            self.logger.error(f"清理旧聊天消息失败: {e}")
            return 0

# ========================= 测试和使用示例 =========================

def test_api():
    """测试API功能"""
    print("=== 测试MongoDB API ===")
    
    try:
        # 创建API实例（测试环境）
        api = SMYMongoDBAPI("test")
        
        if not api.is_connected():
            print("数据库连接失败，请检查MongoDB服务")
            return
        
        # 测试获取每日签到配置
        print("\n1. 测试获取每日签到配置:")
        config = api.get_daily_checkin_config()
        if config:
            print("✓ 成功获取每日签到配置")
            print(f"基础奖励金币范围: {config.get('基础奖励', {}).get('金币', {})}")
            print(f"种子奖励类型数量: {len(config.get('种子奖励', {}))}")
        else:
            print("✗ 获取每日签到配置失败")
        
        # 测试获取幸运抽奖配置
        print("\n2. 测试获取幸运抽奖配置:")
        lucky_config = api.get_lucky_draw_config()
        if lucky_config:
            print("✓ 成功获取幸运抽奖配置")
            print(f"抽奖费用: {lucky_config.get('抽奖费用', {})}")
            print(f"概率配置类型数量: {len(lucky_config.get('概率配置', {}))}")
        else:
            print("✗ 获取幸运抽奖配置失败")
        
        # 测试获取新手大礼包配置
        print("\n3. 测试获取新手大礼包配置:")
        new_player_config = api.get_new_player_config()
        if new_player_config:
            print("✓ 成功获取新手大礼包配置")
            gift_config = new_player_config.get('新手礼包配置', {})
            reward_content = gift_config.get('奖励内容', {})
            print(f"奖励金币: {reward_content.get('金币', 0)}")
            print(f"奖励经验: {reward_content.get('经验', 0)}")
            print(f"种子奖励数量: {len(reward_content.get('种子', []))}")
        else:
            print("✗ 获取新手大礼包配置失败")
        
        # 测试获取智慧树配置
        print("\n4. 测试获取智慧树配置:")
        wisdom_tree_config = api.get_wisdom_tree_config()
        if wisdom_tree_config:
            print("✓ 成功获取智慧树配置")
            messages = wisdom_tree_config.get('messages', [])
            print(f"消息总数: {wisdom_tree_config.get('total_messages', 0)}")
            print(f"最后更新: {wisdom_tree_config.get('last_update', 'N/A')}")
            print(f"消息列表长度: {len(messages)}")
        else:
            print("✗ 获取智慧树配置失败")
        
        # 测试获取在线礼包配置
        print("\n5. 测试获取在线礼包配置:")
        online_gift_config = api.get_online_gift_config()
        if online_gift_config:
            print("✓ 成功获取在线礼包配置")
            gifts = online_gift_config.get('gifts', [])
            print(f"礼包数量: {len(gifts)}")
            print(f"最大在线时间: {online_gift_config.get('max_online_time', 'N/A')}")
        else:
            print("✗ 获取在线礼包配置失败")
        
        # 测试获取稻草人配置
        print("\n6. 测试获取稻草人配置:")
        scare_crow_config = api.get_scare_crow_config()
        if scare_crow_config:
            print("✓ 成功获取稻草人配置")
            scare_crow_types = scare_crow_config.get("稻草人类型", {})
            modify_cost = scare_crow_config.get("修改稻草人配置花费", "N/A")
            print(f"稻草人类型数量: {len(scare_crow_types)}")
            print(f"修改费用: {modify_cost}金币")
        else:
            print("✗ 获取稻草人配置失败")
        
        # 测试获取体力系统配置
        print("\n7. 测试获取宠物配置:")
        pet_config = api.get_pet_config()
        if pet_config:
            print("✓ 成功获取宠物配置")
            pets = pet_config.get("宠物", {})
            print(f"宠物类型数量: {len(pets)}")
            if pets:
                first_pet = list(pets.values())[0]
                print(f"示例宠物属性: {list(first_pet.keys())[:3]}...")
        else:
            print("✗ 获取宠物配置失败")
        
        # 测试获取初始玩家数据模板
        print("\n8. 测试获取初始玩家数据模板:")
        template_config = api.get_initial_player_data_template()
        if template_config:
            print("✓ 成功获取初始玩家数据模板")
            print(f"模板包含字段: {list(template_config.keys())[:5]}...")
            if "基础属性" in template_config:
                basic_attrs = template_config["基础属性"]
                print(f"基础属性: 等级={basic_attrs.get('等级')}, 经验={basic_attrs.get('经验')}, 金币={basic_attrs.get('金币')}")
        else:
            print("✗ 获取初始玩家数据模板失败")
        
        # 测试查找所有游戏配置
        print("\n9. 测试查找游戏配置集合:")
        try:
            configs = api.find_documents("gameconfig")
            print(f"找到 {len(configs)} 个配置文档")
            for config in configs:
                print(f"  - 文档ID: {config.get('_id', 'N/A')}")
        except Exception as e:
            print(f"查找配置失败: {e}")
        
        # 断开连接
        api.disconnect()
        print("\n✓ 测试完成")
        
    except Exception as e:
        print(f"测试过程中出现异常: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_api()