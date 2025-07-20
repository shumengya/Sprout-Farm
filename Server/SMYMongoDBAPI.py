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
from datetime import datetime
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
    
    def get_game_config(self, config_type: str) -> Optional[Dict[str, Any]]:
        """
        获取游戏配置
        
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


    #=====================每日签到系统======================
    def get_daily_checkin_config(self) -> Optional[Dict[str, Any]]:
        """
        获取每日签到配置
        
        Returns:
            Dict: 每日签到配置数据
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID查找
            object_id = ObjectId("687cce278e77ba00a7414ba2")
            result = collection.find_one({"_id": object_id})
            
            if result:
                # 移除MongoDB的_id字段
                if "_id" in result:
                    del result["_id"]
                    
                self.logger.info("成功获取每日签到配置")
                return result
            else:
                self.logger.warning("未找到每日签到配置")
                return None
                
        except Exception as e:
            self.logger.error(f"获取每日签到配置失败: {e}")
            return None
    
    def update_daily_checkin_config(self, config_data: Dict[str, Any]) -> bool:
        """
        更新每日签到配置
        
        Args:
            config_data: 配置数据
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID更新
            object_id = ObjectId("687cce278e77ba00a7414ba2")
            
            # 添加更新时间
            update_data = {
                "updated_at": datetime.now(),
                **config_data
            }
            
            result = collection.replace_one({"_id": object_id}, update_data)
            
            if result.acknowledged and result.matched_count > 0:
                self.logger.info("成功更新每日签到配置")
                return True
            else:
                self.logger.error("更新每日签到配置失败")
                return False
                
        except Exception as e:
            self.logger.error(f"更新每日签到配置异常: {e}")
            return False
    #=====================每日签到系统======================


    #=====================幸运抽奖系统======================
    def get_lucky_draw_config(self) -> Optional[Dict[str, Any]]:
        """
        获取幸运抽奖配置
        
        Returns:
            Dict: 幸运抽奖配置数据
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID查找
            object_id = ObjectId("687cd52e8e77ba00a7414ba3")
            result = collection.find_one({"_id": object_id})
            
            if result:
                # 移除MongoDB的_id字段和updated_at字段
                if "_id" in result:
                    del result["_id"]
                if "updated_at" in result:
                    del result["updated_at"]
                    
                self.logger.info("成功获取幸运抽奖配置")
                return result
            else:
                self.logger.warning("未找到幸运抽奖配置")
                return None
                
        except Exception as e:
            self.logger.error(f"获取幸运抽奖配置失败: {e}")
            return None
    
    def update_lucky_draw_config(self, config_data: Dict[str, Any]) -> bool:
        """
        更新幸运抽奖配置
        
        Args:
            config_data: 配置数据
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID更新
            object_id = ObjectId("687cd52e8e77ba00a7414ba3")
            
            # 添加更新时间
            update_data = {
                "updated_at": datetime.now(),
                **config_data
            }
            
            result = collection.replace_one({"_id": object_id}, update_data)
            
            if result.acknowledged and result.matched_count > 0:
                self.logger.info("成功更新幸运抽奖配置")
                return True
            else:
                self.logger.error("更新幸运抽奖配置失败")
                return False
                
        except Exception as e:
            self.logger.error(f"更新幸运抽奖配置异常: {e}")
            return False
    #=====================幸运抽奖系统======================


    #=====================新手大礼包系统======================
    def get_new_player_config(self) -> Optional[Dict[str, Any]]:
        """
        获取新手大礼包配置
        
        Returns:
            Dict: 新手大礼包配置数据
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID查找
            object_id = ObjectId("687cdbd78e77ba00a7414ba4")
            result = collection.find_one({"_id": object_id})
            
            if result:
                # 移除MongoDB的_id字段和updated_at字段
                if "_id" in result:
                    del result["_id"]
                if "updated_at" in result:
                    del result["updated_at"]
                    
                self.logger.info("成功获取新手大礼包配置")
                return result
            else:
                self.logger.warning("未找到新手大礼包配置")
                return None
                
        except Exception as e:
            self.logger.error(f"获取新手大礼包配置失败: {e}")
            return None
    
    def update_new_player_config(self, config_data: Dict[str, Any]) -> bool:
        """
        更新新手大礼包配置
        
        Args:
            config_data: 配置数据
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID更新
            object_id = ObjectId("687cdbd78e77ba00a7414ba4")
            
            # 添加更新时间
            update_data = {
                "updated_at": datetime.now(),
                **config_data
            }
            
            result = collection.replace_one({"_id": object_id}, update_data)
            
            if result.acknowledged and result.matched_count > 0:
                self.logger.info("成功更新新手大礼包配置")
                return True
            else:
                self.logger.error("更新新手大礼包配置失败")
                return False
                
        except Exception as e:
            self.logger.error(f"更新新手大礼包配置异常: {e}")
            return False
    #=====================新手大礼包系统======================


    #=====================智慧树系统======================
    def get_wisdom_tree_config(self) -> Optional[Dict[str, Any]]:
        """
        获取智慧树配置
        
        Returns:
            Dict: 智慧树配置数据
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID查找
            object_id = ObjectId("687cdfbe8e77ba00a7414ba5")
            result = collection.find_one({"_id": object_id})
            
            if result:
                # 移除MongoDB的_id字段和updated_at字段
                if "_id" in result:
                    del result["_id"]
                if "updated_at" in result:
                    del result["updated_at"]
                    
                self.logger.info("成功获取智慧树配置")
                return result
            else:
                self.logger.warning("未找到智慧树配置")
                return None
                
        except Exception as e:
            self.logger.error(f"获取智慧树配置失败: {e}")
            return None
    
    def update_wisdom_tree_config(self, config_data: Dict[str, Any]) -> bool:
        """
        更新智慧树配置
        
        Args:
            config_data: 配置数据
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID更新
            object_id = ObjectId("687cdfbe8e77ba00a7414ba5")
            
            # 添加更新时间
            update_data = {
                "updated_at": datetime.now(),
                **config_data
            }
            
            result = collection.replace_one({"_id": object_id}, update_data)
            
            if result.acknowledged and result.matched_count > 0:
                self.logger.info("成功更新智慧树配置")
                return True
            else:
                self.logger.error("更新智慧树配置失败")
                return False
                
        except Exception as e:
            self.logger.error(f"更新智慧树配置异常: {e}")
            return False
    #=====================智慧树系统======================


    #=====================稻草人系统======================
    def get_scare_crow_config(self) -> Optional[Dict[str, Any]]:
        """
        获取稻草人配置
        
        Returns:
            Dict: 稻草人配置数据
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID查找
            object_id = ObjectId("687cea258e77ba00a7414ba8")
            result = collection.find_one({"_id": object_id})
            
            if result:
                # 移除MongoDB的_id字段和updated_at字段
                if "_id" in result:
                    del result["_id"]
                if "updated_at" in result:
                    del result["updated_at"]
                    
                self.logger.info("成功获取稻草人配置")
                return result
            else:
                self.logger.warning("未找到稻草人配置")
                return None
                
        except Exception as e:
            self.logger.error(f"获取稻草人配置失败: {e}")
            return None
    
    def update_scare_crow_config(self, config_data: Dict[str, Any]) -> bool:
        """
        更新稻草人配置
        
        Args:
            config_data: 配置数据
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID更新
            object_id = ObjectId("687cea258e77ba00a7414ba8")
            
            # 添加更新时间
            update_data = {
                "updated_at": datetime.now(),
                **config_data
            }
            
            result = collection.replace_one({"_id": object_id}, update_data)
            
            if result.acknowledged and result.matched_count > 0:
                self.logger.info("成功更新稻草人配置")
                return True
            else:
                self.logger.error("更新稻草人配置失败")
                return False
                
        except Exception as e:
            self.logger.error(f"更新稻草人配置异常: {e}")
            return False
    #=====================稻草人系统======================


    #=====================在线礼包系统======================
    def get_online_gift_config(self) -> Optional[Dict[str, Any]]:
        """
        获取在线礼包配置
        
        Returns:
            Dict: 在线礼包配置数据
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID查找
            object_id = ObjectId("687ce7678e77ba00a7414ba6")
            result = collection.find_one({"_id": object_id})
            
            if result:
                # 移除MongoDB的_id字段和updated_at字段
                if "_id" in result:
                    del result["_id"]
                if "updated_at" in result:
                    del result["updated_at"]
                    
                self.logger.info("成功获取在线礼包配置")
                return result
            else:
                self.logger.warning("未找到在线礼包配置")
                return None
                
        except Exception as e:
            self.logger.error(f"获取在线礼包配置失败: {e}")
            return None
    
    def update_online_gift_config(self, config_data: Dict[str, Any]) -> bool:
        """
        更新在线礼包配置
        
        Args:
            config_data: 配置数据
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID更新
            object_id = ObjectId("687ce7678e77ba00a7414ba6")
            
            # 添加更新时间
            update_data = {
                "updated_at": datetime.now(),
                **config_data
            }
            
            result = collection.replace_one({"_id": object_id}, update_data)
            
            if result.acknowledged and result.matched_count > 0:
                self.logger.info("成功更新在线礼包配置")
                return True
            else:
                self.logger.error("更新在线礼包配置失败")
                return False
                
        except Exception as e:
            self.logger.error(f"更新在线礼包配置异常: {e}")
            return False
    #=====================在线礼包系统======================


    #=====================道具配置系统======================
    def get_item_config(self) -> Optional[Dict[str, Any]]:
        """
        获取道具配置
        
        Returns:
            Dict: 道具配置数据
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID查找
            object_id = ObjectId("687cf17c8e77ba00a7414baa")
            result = collection.find_one({"_id": object_id})
            
            if result:
                # 移除MongoDB的_id字段和updated_at字段
                if "_id" in result:
                    del result["_id"]
                if "updated_at" in result:
                    del result["updated_at"]
                    
                self.logger.info("成功获取道具配置")
                return result
            else:
                self.logger.warning("未找到道具配置")
                return None
                
        except Exception as e:
            self.logger.error(f"获取道具配置失败: {e}")
            return None
    
    def update_item_config(self, config_data: Dict[str, Any]) -> bool:
        """
        更新道具配置
        
        Args:
            config_data: 配置数据
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID更新
            object_id = ObjectId("687cf17c8e77ba00a7414baa")
            
            # 添加更新时间
            update_data = {
                "updated_at": datetime.now(),
                **config_data
            }
            
            result = collection.replace_one({"_id": object_id}, update_data)
            
            if result.acknowledged and result.matched_count > 0:
                self.logger.info("成功更新道具配置")
                return True
            else:
                self.logger.error("更新道具配置失败")
                return False
                
        except Exception as e:
            self.logger.error(f"更新道具配置异常: {e}")
            return False
    #=====================道具配置系统======================


    #=====================宠物配置系统======================
    def get_pet_config(self) -> Optional[Dict[str, Any]]:
        """
        获取宠物配置
        
        Returns:
            Dict: 宠物配置数据
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID查找
            object_id = ObjectId("687cf59b8e77ba00a7414bab")
            result = collection.find_one({"_id": object_id})
            
            if result:
                # 移除MongoDB的_id字段和updated_at字段
                if "_id" in result:
                    del result["_id"]
                if "updated_at" in result:
                    del result["updated_at"]
                    
                self.logger.info("成功获取宠物配置")
                return result
            else:
                self.logger.warning("未找到宠物配置")
                return None
                
        except Exception as e:
            self.logger.error(f"获取宠物配置失败: {e}")
            return None
    
    def update_pet_config(self, config_data: Dict[str, Any]) -> bool:
        """
        更新宠物配置
        
        Args:
            config_data: 配置数据
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID更新
            object_id = ObjectId("687cf59b8e77ba00a7414bab")
            
            # 添加更新时间
            update_data = {
                "updated_at": datetime.now(),
                **config_data
            }
            
            result = collection.replace_one({"_id": object_id}, update_data)
            
            if result.acknowledged and result.matched_count > 0:
                self.logger.info("成功更新宠物配置")
                return True
            else:
                self.logger.error("更新宠物配置失败")
                return False
                
        except Exception as e:
            self.logger.error(f"更新宠物配置异常: {e}")
            return False
    #=====================宠物配置系统======================


    #=====================体力系统======================
    def get_stamina_config(self) -> Optional[Dict[str, Any]]:
        """
        获取体力系统配置
        
        Returns:
            Dict: 体力系统配置数据
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID查找
            object_id = ObjectId("687cefba8e77ba00a7414ba9")
            result = collection.find_one({"_id": object_id})
            
            if result:
                # 移除MongoDB的_id字段和updated_at字段
                if "_id" in result:
                    del result["_id"]
                if "updated_at" in result:
                    del result["updated_at"]
                    
                self.logger.info("成功获取体力系统配置")
                return result
            else:
                self.logger.warning("未找到体力系统配置")
                return None
                
        except Exception as e:
            self.logger.error(f"获取体力系统配置失败: {e}")
            return None
    
    def update_stamina_config(self, config_data: Dict[str, Any]) -> bool:
        """
        更新体力系统配置
        
        Args:
            config_data: 配置数据
            
        Returns:
            bool: 是否成功
        """
        try:
            collection = self.get_collection("gameconfig")
            
            # 使用已知的文档ID更新
            object_id = ObjectId("687cefba8e77ba00a7414ba9")
            
            # 添加更新时间
            update_data = {
                "updated_at": datetime.now(),
                **config_data
            }
            
            result = collection.replace_one({"_id": object_id}, update_data)
            
            if result.acknowledged and result.matched_count > 0:
                self.logger.info("成功更新体力系统配置")
                return True
            else:
                self.logger.error("更新体力系统配置失败")
                return False
                
        except Exception as e:
            self.logger.error(f"更新体力系统配置异常: {e}")
            return False
    #=====================体力系统======================


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
        
        # 测试获取宠物配置
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
        
        # 测试查找所有游戏配置
        print("\n8. 测试查找游戏配置集合:")
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