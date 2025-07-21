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
                "database": "mengyafarm"
            },
            "production": {
                "host": "192.168.31.233", 
                "port": 27017,
                "database": "mengyafarm"
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
            current_config = self.config[self.environment]
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


    #=====================验证码系统======================
    def get_verification_codes(self) -> Optional[Dict[str, Any]]:
        """获取验证码数据"""
        return self._get_config_by_id(self.CONFIG_IDS["verification_codes"], "验证码数据")
    
    def update_verification_codes(self, codes_data: Dict[str, Any]) -> bool:
        """更新验证码数据"""
        return self._update_config_by_id(self.CONFIG_IDS["verification_codes"], codes_data, "验证码数据")
    
    #=====================聊天消息系统======================
    def save_chat_message(self, username: str, player_name: str, content: str, timestamp: float = None) -> bool:
        """保存聊天消息到MongoDB"""
        try:
            if timestamp is None:
                timestamp = datetime.now().timestamp()
            
            # 获取日期字符串作为文档标识
            date_obj = datetime.fromtimestamp(timestamp)
            date_str = date_obj.strftime("%Y-%m-%d")
            
            # 创建消息记录
            message_record = {
                "username": username,
                "player_name": player_name,
                "content": content,
                "timestamp": timestamp,
                "time_str": date_obj.strftime("%Y年%m月%d日 %H:%M:%S")
            }
            
            collection = self.get_collection("chat")
            
            # 查找当天的文档
            query = {"date": date_str}
            existing_doc = collection.find_one(query)
            
            if existing_doc:
                # 如果文档存在，添加消息到messages数组
                result = collection.update_one(
                    query,
                    {
                        "$push": {"messages": message_record},
                        "$set": {"updated_at": datetime.now()}
                    }
                )
                success = result.acknowledged and result.modified_count > 0
            else:
                # 如果文档不存在，创建新文档
                new_doc = {
                    "date": date_str,
                    "messages": [message_record],
                    "created_at": datetime.now(),
                    "updated_at": datetime.now()
                }
                result = collection.insert_one(new_doc)
                success = result.acknowledged
            
            if success:
                self.logger.info(f"成功保存聊天消息: {username}({player_name}): {content[:20]}...")
            else:
                self.logger.error(f"保存聊天消息失败: {username}({player_name}): {content[:20]}...")
            
            return success
            
        except Exception as e:
            self.logger.error(f"保存聊天消息异常: {e}")
            return False
    
    def get_chat_history(self, days: int = 3, limit: int = 500) -> List[Dict[str, Any]]:
        """获取聊天历史消息"""
        try:
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
            
            # 查询这些日期的文档
            query = {"date": {"$in": date_list}}
            docs = collection.find(query).sort("date", 1)
            
            # 收集所有消息
            all_messages = []
            for doc in docs:
                messages = doc.get("messages", [])
                all_messages.extend(messages)
            
            # 按时间戳排序
            all_messages.sort(key=lambda x: x.get("timestamp", 0))
            
            # 限制数量
            if limit > 0 and len(all_messages) > limit:
                all_messages = all_messages[-limit:]
            
            self.logger.info(f"获取聊天历史消息成功: {len(all_messages)} 条消息（最近{days}天）")
            return all_messages
            
        except Exception as e:
            self.logger.error(f"获取聊天历史消息失败: {e}")
            return []
    
    def get_latest_chat_message(self) -> Optional[Dict[str, Any]]:
        """获取最新的一条聊天消息"""
        try:
            collection = self.get_collection("chat")
            
            # 获取最近的文档
            latest_doc = collection.find().sort("date", -1).limit(1)
            
            for doc in latest_doc:
                messages = doc.get("messages", [])
                if messages:
                    # 返回最后一条消息
                    latest_message = messages[-1]
                    self.logger.info(f"获取最新聊天消息成功: {latest_message.get('username', 'N/A')}: {latest_message.get('content', '')[:20]}...")
                    return latest_message
            
            self.logger.info("没有找到聊天消息")
            return None
            
        except Exception as e:
            self.logger.error(f"获取最新聊天消息失败: {e}")
            return None
    
    def clean_old_chat_messages(self, keep_days: int = 30) -> int:
        """清理旧的聊天消息"""
        try:
            collection = self.get_collection("chat")
            
            # 计算保留的最早日期
            cutoff_date = datetime.now() - timedelta(days=keep_days)
            cutoff_date_str = cutoff_date.strftime("%Y-%m-%d")
            
            # 删除早于cutoff_date的文档
            query = {"date": {"$lt": cutoff_date_str}}
            result = collection.delete_many(query)
            
            deleted_count = result.deleted_count
            self.logger.info(f"清理旧聊天消息完成: 删除了 {deleted_count} 个文档（{keep_days}天前的消息）")
            return deleted_count
            
        except Exception as e:
            self.logger.error(f"清理旧聊天消息失败: {e}")
            return 0
    #=====================聊天消息系统======================
    
    def save_verification_code(self, qq_number: str, verification_code: str, expiry_time: int = 300, code_type: str = "register") -> bool:
        """保存单个验证码到MongoDB"""
        import time
        
        try:
            # 获取当前验证码数据
            codes_data = self.get_verification_codes() or {}
            
            # 添加新的验证码
            expire_at = time.time() + expiry_time
            current_time = time.time()
            
            codes_data[qq_number] = {
                "code": verification_code,
                "expire_at": expire_at,
                "code_type": code_type,
                "created_at": current_time,
                "used": False
            }
            
            # 更新到MongoDB
            success = self.update_verification_codes(codes_data)
            if success:
                self.logger.info(f"为QQ {qq_number} 保存{code_type}验证码: {verification_code}, 过期时间: {expire_at}")
            return success
            
        except Exception as e:
            self.logger.error(f"保存验证码失败: {e}")
            return False
    
    def verify_verification_code(self, qq_number: str, input_code: str, code_type: str = "register") -> tuple[bool, str]:
        """验证验证码"""
        import time
        
        try:
            # 获取验证码数据
            codes_data = self.get_verification_codes()
            if not codes_data:
                self.logger.warning(f"QQ {qq_number} 验证失败: 验证码数据不存在")
                return False, "验证码不存在或已过期"
            
            # 检查该QQ号是否有验证码
            if qq_number not in codes_data:
                self.logger.warning(f"QQ {qq_number} 验证失败: 没有找到验证码记录")
                return False, "验证码不存在，请重新获取"
            
            # 获取存储的验证码信息
            code_info = codes_data[qq_number]
            stored_code = code_info.get("code", "")
            expire_at = code_info.get("expire_at", 0)
            stored_code_type = code_info.get("code_type", "register")
            is_used = code_info.get("used", False)
            created_at = code_info.get("created_at", 0)
            
            self.logger.info(f"QQ {qq_number} 验证码详情: 存储码={stored_code}, 输入码={input_code}, 类型={stored_code_type}, 已使用={is_used}, 创建时间={created_at}")
            
            # 检查验证码类型是否匹配
            if stored_code_type != code_type:
                self.logger.warning(f"QQ {qq_number} 验证失败: 验证码类型不匹配，存储类型={stored_code_type}, 请求类型={code_type}")
                return False, f"验证码类型不匹配，请重新获取{code_type}验证码"
            
            # 检查验证码是否已被使用
            if is_used:
                self.logger.warning(f"QQ {qq_number} 验证失败: 验证码已被使用")
                return False, "验证码已被使用，请重新获取"
            
            # 检查验证码是否过期
            current_time = time.time()
            if current_time > expire_at:
                # 移除过期的验证码
                del codes_data[qq_number]
                self.update_verification_codes(codes_data)
                self.logger.warning(f"QQ {qq_number} 验证失败: 验证码已过期")
                return False, "验证码已过期，请重新获取"
            
            # 验证码比较（不区分大小写）
            if input_code.upper() == stored_code.upper():
                # 验证成功，标记为已使用
                codes_data[qq_number]["used"] = True
                codes_data[qq_number]["used_at"] = current_time
                
                success = self.update_verification_codes(codes_data)
                if success:
                    self.logger.info(f"QQ {qq_number} 验证成功: 验证码已标记为已使用")
                else:
                    self.logger.warning(f"标记验证码已使用时失败，但验证成功")
                return True, "验证码正确"
            else:
                self.logger.warning(f"QQ {qq_number} 验证失败: 验证码不匹配")
                return False, "验证码错误"
                
        except Exception as e:
            self.logger.error(f"验证验证码异常: {e}")
            return False, "验证码验证失败"
    
    def clean_expired_verification_codes(self) -> int:
        """清理过期的验证码和已使用的验证码"""
        import time
        
        try:
            codes_data = self.get_verification_codes()
            if not codes_data:
                return 0
            
            current_time = time.time()
            removed_keys = []
            
            # 找出过期的验证码和已使用的验证码（超过1小时）
            for qq_number, code_info in codes_data.items():
                expire_at = code_info.get("expire_at", 0)
                is_used = code_info.get("used", False)
                used_at = code_info.get("used_at", 0)
                
                should_remove = False
                
                # 过期的验证码
                if current_time > expire_at:
                    should_remove = True
                    self.logger.info(f"移除过期验证码: QQ {qq_number}")
                
                # 已使用超过1小时的验证码
                elif is_used and used_at > 0 and (current_time - used_at) > 3600:
                    should_remove = True
                    self.logger.info(f"移除已使用的验证码: QQ {qq_number}")
                
                if should_remove:
                    removed_keys.append(qq_number)
            
            # 移除标记的验证码
            for key in removed_keys:
                del codes_data[key]
            
            # 保存更新后的数据
            if removed_keys:
                self.update_verification_codes(codes_data)
                self.logger.info(f"共清理了 {len(removed_keys)} 个验证码")
            
            return len(removed_keys)
            
        except Exception as e:
            self.logger.error(f"清理验证码失败: {e}")
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
            
            # 转换ObjectId为字符串
            for doc in documents:
                if "_id" in doc:
                    doc["_id"] = str(doc["_id"])
            
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