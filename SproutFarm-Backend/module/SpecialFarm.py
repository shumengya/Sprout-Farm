#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
特殊农场管理系统
作者: AI Assistant
功能: 管理特殊农场的自动种植和维护
"""

import time
import random
import logging
from datetime import datetime
from bson import ObjectId
#自定义包
from .SMYMongoDBAPI import SMYMongoDBAPI

#杂交农场666-种植杂交树1，杂交树2-每天0点种植
#花卉农场520-随机种植各种花卉-星期一，星期三，星期五，星期日零点种植
#瓜果农场333-随机种植各种瓜果-星期二，星期四，星期六零点种植
#小麦谷222-全屏种植小麦-每天0点种植
#稻香111-全屏种植稻谷-每天0点种植
#幸运农场888-随机种植1-80个幸运草和幸运花-星期一零点种植



class SpecialFarmManager:
    #初始化特殊农场管理器
    def __init__(self, environment=None):
        """
        初始化特殊农场管理器
        
        Args:
            environment: 环境类型，"test" 或 "production"，如果为None则自动检测
        """
        # 如果没有指定环境，使用与TCPGameServer相同的环境检测逻辑
        if environment is None:
            import os
            if os.path.exists('/.dockerenv') or os.environ.get('PRODUCTION', '').lower() == 'true':
                environment = "production"
            else:
                environment = "test"
        
        self.environment = environment
        self.mongo_api = SMYMongoDBAPI(environment)
        
        # 设置日志
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('special_farm.log', encoding='utf-8'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
        # 特殊农场配置
        self.special_farms = {
            "杂交农场": {
                "object_id": "689b4b9286cf953f2f4e56ee",
                "crops": ["杂交树1", "杂交树2"],
                "description": "专门种植杂交树的特殊农场"
            },
            "花卉农场": {
                "object_id": "689bec6286cf953f2f4e56f1",
                "crops": ["郁金香", "牵牛花", "百合花", "栀子花", "玫瑰花", "向日葵", "藏红花", "幸运花"],
                "description": "盛产各种美丽花卉的特殊农场",
                "plant_type": "random_flowers"  # 标记为随机花卉种植类型
            },
            "瓜果农场": {
                "object_id": "689bf73886cf953f2f4e56fa",
                "crops": ["西瓜", "南瓜", "哈密瓜", "葫芦", "黄瓜", "龙果", "菠萝", "芒果"],
                "description": "盛产各种瓜果的农场",
                "plant_type": "random_fruits"  # 标记为随机瓜果种植类型
            },
            "小麦谷": {
                "object_id": "689bf9a886cf953f2f4e56fd",
                "crops": ["小麦"],
                "description": "盛产小麦的农场",
                "plant_type": "single_wheat"  # 标记为单一小麦种植类型
            },
            "稻香": {
                "object_id": "689bf9ac86cf953f2f4e56fe",
                "crops": ["稻谷"],
                "description": "盛产稻谷的农场",
                "plant_type": "single_rice"  # 标记为单一稻谷种植类型
            },
            "幸运农场": {
                "object_id": "689c027886cf953f2f4e56ff",
                "crops": ["幸运草", "幸运花"],
                "description": "盛产幸运草和幸运花的农场",
                "plant_type": "random_lucky"  # 标记为随机幸运植物种植类型
            }
        }
        
        self.logger.info(f"特殊农场管理器初始化完成 - 环境: {environment}")
    
    #获取作物系统数据
    def get_crop_data(self):
        """
        获取作物配置数据
        
        Returns:
            dict: 作物配置数据
        """
        try:
            crop_config = self.mongo_api.get_crop_data_config()
            if crop_config:
                # 移除MongoDB相关字段
                if "_id" in crop_config:
                    del crop_config["_id"]
                if "config_type" in crop_config:
                    del crop_config["config_type"]
                if "updated_at" in crop_config:
                    del crop_config["updated_at"]
                return crop_config
            else:
                self.logger.error("无法获取作物配置数据")
                return {}
        except Exception as e:
            self.logger.error(f"获取作物配置数据时出错: {str(e)}")
            return {}
    
    #通过文档ID获取农场数据
    def get_player_data_by_object_id(self, object_id):
        """
        通过ObjectId获取玩家数据
        
        Args:
            object_id: MongoDB文档ID
            
        Returns:
            dict: 玩家数据，如果未找到返回None
        """
        try:
            collection = self.mongo_api.get_collection("playerdata")
            oid = ObjectId(object_id)
            player_data = collection.find_one({"_id": oid})
            
            if player_data:
                self.logger.info(f"成功获取玩家数据: {player_data.get('玩家昵称', 'Unknown')}")
                return player_data
            else:
                self.logger.warning(f"未找到ObjectId为 {object_id} 的玩家数据")
                return None
                
        except Exception as e:
            self.logger.error(f"获取玩家数据时出错: {str(e)}")
            return None
    
    #通过文档ID保存农场数据
    def save_player_data_by_object_id(self, object_id, player_data):
        """
        通过ObjectId保存玩家数据
        
        Args:
            object_id: MongoDB文档ID
            player_data: 玩家数据
            
        Returns:
            bool: 是否保存成功
        """
        try:
            collection = self.mongo_api.get_collection("playerdata")
            oid = ObjectId(object_id)
            
            # 更新最后登录时间
            player_data["最后登录时间"] = datetime.now().strftime("%Y年%m月%d日%H时%M分%S秒")
            
            result = collection.replace_one({"_id": oid}, player_data)
            
            if result.acknowledged and result.matched_count > 0:
                self.logger.info(f"成功保存玩家数据: {player_data.get('玩家昵称', 'Unknown')}")
                return True
            else:
                self.logger.error(f"保存玩家数据失败: ObjectId {object_id}")
                return False
                
        except Exception as e:
            self.logger.error(f"保存玩家数据时出错: {str(e)}")
            return False
    
    #在指定农场种植作物
    def plant_crops_in_farm(self, farm_name):
        """
        为指定特殊农场种植作物
        
        Args:
            farm_name: 农场名称
            
        Returns:
            bool: 是否种植成功
        """
        if farm_name not in self.special_farms:
            self.logger.error(f"未知的特殊农场: {farm_name}")
            return False
        
        farm_config = self.special_farms[farm_name]
        object_id = farm_config["object_id"]
        available_crops = farm_config["crops"]
        
        # 获取玩家数据
        player_data = self.get_player_data_by_object_id(object_id)
        if not player_data:
            return False
        
        # 获取作物配置
        crop_data = self.get_crop_data()
        if not crop_data:
            self.logger.error("无法获取作物配置，跳过种植")
            return False
        
        # 检查作物是否存在
        for crop_name in available_crops:
            if crop_name not in crop_data:
                self.logger.error(f"作物 {crop_name} 不存在于作物配置中")
                return False
        
        # 获取农场土地
        farm_lands = player_data.get("农场土地", [])
        if not farm_lands:
            self.logger.error(f"农场 {farm_name} 没有土地数据")
            return False
        
        planted_count = 0
        plant_type = farm_config.get("plant_type", "normal")
        
        # 遍历所有土地，先开垦再种植作物
        for i, land in enumerate(farm_lands):
            # 根据农场类型选择作物
            if plant_type == "random_flowers":
                # 花卉农场：随机种植各种花卉，种满所有土地
                crop_name = random.choice(available_crops)
                should_plant = True  # 100%种植率，种满所有土地
            elif plant_type == "random_fruits":
                # 瓜果农场：随机种植各种瓜果，种满所有土地
                crop_name = random.choice(available_crops)
                should_plant = True  # 100%种植率，种满所有土地
            elif plant_type == "single_wheat":
                # 小麦谷：全屏种植小麦，种满所有土地
                crop_name = "小麦"
                should_plant = True  # 100%种植率，种满所有土地
            elif plant_type == "single_rice":
                # 稻香：全屏种植稻谷，种满所有土地
                crop_name = "稻谷"
                should_plant = True  # 100%种植率，种满所有土地
            elif plant_type == "random_lucky":
                # 幸运农场：随机种植1-80个幸运草和幸运花
                crop_name = random.choice(available_crops)
                # 随机决定是否种植，确保总数在1-80之间
                target_plants = random.randint(1, min(80, len(farm_lands)))
                should_plant = planted_count < target_plants
            else:
                # 普通农场：按原逻辑随机选择
                crop_name = random.choice(available_crops)
                should_plant = True
            
            if should_plant:
                crop_info = crop_data[crop_name]
                
                # 更新土地数据（先开垦，再种植）
                land.update({
                    "is_diged": True,  # 确保土地已开垦
                    "is_planted": True,
                    "crop_type": crop_name,
                    "grow_time": 0,  # 立即成熟
                    "max_grow_time": crop_info.get("生长时间", 21600),
                    "is_dead": False,
                    "已浇水": True,
                    "已施肥": True,
                    "土地等级": 0
                })
                
                # 清除施肥时间戳
                if "施肥时间" in land:
                    del land["施肥时间"]
                
                planted_count += 1
            else:
                # 留空的土地：只开垦不种植
                land.update({
                    "is_diged": True,
                    "is_planted": False,
                    "crop_type": "",
                    "grow_time": 0,
                    "max_grow_time": 3,
                    "is_dead": False,
                    "已浇水": False,
                    "已施肥": False,
                    "土地等级": 0
                })
                
                # 清除施肥时间戳
                if "施肥时间" in land:
                    del land["施肥时间"]
        
        # 保存玩家数据
        if self.save_player_data_by_object_id(object_id, player_data):
            self.logger.info(f"成功为 {farm_name} 种植了 {planted_count} 块土地的作物")
            return True
        else:
            self.logger.error(f"保存 {farm_name} 数据失败")
            return False
    
    #每日维护任务
    def daily_maintenance(self):
        """
        每日维护任务
        """
        from datetime import datetime
        
        self.logger.info("开始执行特殊农场维护任务...")
        
        success_count = 0
        total_farms = 0
        current_time = datetime.now()
        current_weekday = current_time.weekday()  # 0=Monday, 1=Tuesday, ..., 6=Sunday
        current_time_str = current_time.strftime("%Y-%m-%d %H:%M:%S")
        
        for farm_name in self.special_farms.keys():
            # 检查农场是否需要在今天维护
            should_maintain = True
            
            if farm_name == "瓜果农场":
                # 瓜果农场只在星期二(1)、四(3)、六(5)维护
                if current_weekday not in [1, 3, 5]:
                    should_maintain = False
                    self.logger.info(f"瓜果农场今日({['周一','周二','周三','周四','周五','周六','周日'][current_weekday]})不需要维护")
            elif farm_name == "幸运农场":
                # 幸运农场只在星期一(0)维护
                if current_weekday != 0:
                    should_maintain = False
                    self.logger.info(f"幸运农场今日({['周一','周二','周三','周四','周五','周六','周日'][current_weekday]})不需要维护")
            
            if should_maintain:
                total_farms += 1
                try:
                    if self.plant_crops_in_farm(farm_name):
                        success_count += 1
                        self.logger.info(f"农场 {farm_name} 维护完成")
                        
                        # 更新维护时间记录
                        try:
                            farm_config = self.special_farms[farm_name]
                            object_id = farm_config["object_id"]
                            player_data = self.get_player_data_by_object_id(object_id)
                            if player_data:
                                player_data["特殊农场最后维护时间"] = current_time_str
                                self.save_player_data_by_object_id(object_id, player_data)
                        except Exception as record_error:
                            self.logger.error(f"更新 {farm_name} 维护时间记录失败: {str(record_error)}")
                    else:
                        self.logger.error(f"农场 {farm_name} 维护失败")
                except Exception as e:
                    self.logger.error(f"维护农场 {farm_name} 时出错: {str(e)}")
        
        self.logger.info(f"维护任务完成: {success_count}/{total_farms} 个农场维护成功")
    
    #启动定时任务调度器（后台线程模式）
    def start_scheduler(self):
        """
        启动定时任务调度器（后台线程模式）
        """
        import threading
        
        self.logger.info("特殊农场定时任务调度器已启动")
        self.logger.info("维护任务将在每天凌晨0点执行")
        
        # 检查是否需要立即执行维护任务
        self._check_and_run_initial_maintenance()
        
        # 在后台线程中运行调度循环
        def scheduler_loop():
            last_maintenance_date = None
            
            while True:
                try:
                    now = datetime.now()
                    current_date = now.strftime("%Y-%m-%d")
                    
                    # 检查是否到了零点且今天还没有执行过维护
                    if (now.hour == 0 and now.minute == 0 and 
                        last_maintenance_date != current_date):
                        self.logger.info("零点维护时间到，开始执行维护任务...")
                        self.daily_maintenance()
                        last_maintenance_date = current_date
                    
                    time.sleep(60)  # 每分钟检查一次
                except Exception as e:
                    self.logger.error(f"调度器运行时出错: {str(e)}")
                    time.sleep(60)
        
        # 启动后台线程
        scheduler_thread = threading.Thread(target=scheduler_loop, daemon=True)
        scheduler_thread.start()
        self.logger.info("特殊农场调度器已在后台线程启动")
    
    #检查是否需要执行初始维护任务
    def _check_and_run_initial_maintenance(self):
        """
        检查是否需要执行初始维护任务
        避免服务器重启时重复执行
        """
        try:
            from datetime import datetime, timedelta
            
            # 检查今天是否已经执行过维护任务
            current_time = datetime.now()
            today = current_time.strftime("%Y-%m-%d")
            current_weekday = current_time.weekday()  # 0=Monday, 1=Tuesday, ..., 6=Sunday
            
            # 获取特殊农场数据，检查最后维护时间
            for farm_name, farm_config in self.special_farms.items():
                object_id = farm_config["object_id"]
                player_data = self.get_player_data_by_object_id(object_id)
                
                # 检查农场是否需要在今天维护
                should_maintain = True
                if farm_name == "瓜果农场":
                    # 瓜果农场只在星期二(1)、四(3)、六(5)维护
                    if current_weekday not in [1, 3, 5]:
                        should_maintain = False
                        self.logger.info(f"瓜果农场今日({['周一','周二','周三','周四','周五','周六','周日'][current_weekday]})不需要维护")
                elif farm_name == "幸运农场":
                    # 幸运农场只在星期一(0)维护
                    if current_weekday != 0:
                        should_maintain = False
                        self.logger.info(f"幸运农场今日({['周一','周二','周三','周四','周五','周六','周日'][current_weekday]})不需要维护")
                
                if should_maintain and player_data:
                    last_maintenance = player_data.get("特殊农场最后维护时间", "")
                    
                    # 如果今天还没有维护过，则执行维护
                    if not last_maintenance or not last_maintenance.startswith(today):
                        self.logger.info(f"检测到 {farm_name} 今日尚未维护，执行维护任务...")
                        if self.plant_crops_in_farm(farm_name):
                            # 更新维护时间记录
                            player_data["特殊农场最后维护时间"] = current_time.strftime("%Y-%m-%d %H:%M:%S")
                            self.save_player_data_by_object_id(object_id, player_data)
                    else:
                        self.logger.info(f"{farm_name} 今日已维护过，跳过初始维护")
                        
        except Exception as e:
            self.logger.error(f"检查初始维护任务时出错: {str(e)}")
            # 如果检查失败，执行一次维护作为备用
            self.logger.info("执行备用维护任务...")
            self.daily_maintenance()
    
    #停止定时任务调度器
    def stop_scheduler(self):
        """
        停止定时任务调度器
        """
        try:
            # 设置停止标志（如果需要的话）
            self.logger.info("特殊农场定时任务调度器已停止")
        except Exception as e:
            self.logger.error(f"停止定时任务调度器时出错: {str(e)}")
    
    #手动执行维护任务
    def manual_maintenance(self, farm_name=None):
        """
        手动执行维护任务
        
        Args:
            farm_name: 指定农场名称，如果为None则维护所有农场
        """
        if farm_name:
            if farm_name in self.special_farms:
                self.logger.info(f"手动维护农场: {farm_name}")
                return self.plant_crops_in_farm(farm_name)
            else:
                self.logger.error(f"未知的农场名称: {farm_name}")
                return False
        else:
            self.logger.info("手动维护所有特殊农场")
            self.daily_maintenance()
            return True

def main():
    """
    主函数
    """
    import sys
    
    # 检查命令行参数
    environment = "production"
    if len(sys.argv) > 1:
        if sys.argv[1] in ["test", "production"]:
            environment = sys.argv[1]
        else:
            print("使用方法: python SpecialFarm.py [test|production]")
            sys.exit(1)
    
    # 创建特殊农场管理器
    manager = SpecialFarmManager(environment)
    
    # 检查是否为手动模式
    if len(sys.argv) > 2 and sys.argv[2] == "manual":
        # 手动执行维护
        farm_name = sys.argv[3] if len(sys.argv) > 3 else None
        manager.manual_maintenance(farm_name)
    else:
        # 启动定时任务
        manager.start_scheduler()

if __name__ == "__main__":
    main()