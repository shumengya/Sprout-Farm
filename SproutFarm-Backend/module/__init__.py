#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
萌芽农场服务器模块包
包含所有服务器外置插件模块
"""

# 导入所有模块类
from .SMYMongoDBAPI import SMYMongoDBAPI
from .QQEmailSendAPI import QQMailAPI, EmailVerification
from .ConsoleCommandsAPI import ConsoleCommandsAPI  # 明确导入类名，避免循环导入
from .SpecialFarm import SpecialFarmManager  # 导入特殊农场管理器
from .WSRemoteCmdApi import WSRemoteCmdApi
from .NetworkCore import MessageHandler


# 定义模块导出列表
__all__ = [
    'SMYMongoDBAPI',
    'QQMailAPI',
    'EmailVerification',
    'ConsoleCommandsAPI',
    'SpecialFarmManager',
    'WSRemoteCmdApi'
]