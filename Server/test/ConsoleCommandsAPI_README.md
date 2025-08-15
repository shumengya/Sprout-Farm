# 控制台命令API模块 (ConsoleCommandsAPI)

## 功能特性

### 基础游戏管理命令
- `/addmoney <QQ号> <数量>` - 为玩家添加金币
- `/addxp <QQ号> <数量>` - 为玩家添加经验值
- `/addlevel <QQ号> <数量>` - 为玩家添加等级
- `/addseed <QQ号> <作物名称> <数量>` - 为玩家添加种子
- `/lsplayer` - 列出所有在线玩家
- `/playerinfo <QQ号>` - 查看玩家详细信息
- `/resetland <QQ号>` - 重置玩家土地
- `/weather <天气类型>` - 设置天气

### 系统管理命令
- `/help` - 显示帮助信息
- `/save` - 保存所有玩家数据
- `/reload` - 重新加载配置文件
- `/stop` - 停止服务器

### MongoDB数据库管理命令
- `/dbtest` - 测试数据库连接
- `/dbconfig <操作> [参数]` - 数据库配置管理
  - `list` - 列出所有配置类型
  - `get <配置类型>` - 获取指定配置
  - `reload <配置类型>` - 重新加载指定配置到服务器
- `/dbchat <操作> [参数]` - 聊天消息管理
  - `latest` - 获取最新聊天消息
  - `history [天数] [数量]` - 获取聊天历史
  - `clean [保留天数]` - 清理旧聊天消息
- `/dbclean <类型>` - 数据库清理
  - `codes` - 清理过期验证码
  - `chat [保留天数]` - 清理旧聊天消息
  - `all` - 清理所有过期数据
- `/dbbackup [类型]` - 数据库备份
  - `config` - 备份游戏配置
  - `chat` - 备份聊天消息

## 使用方法

### 1. 导入模块
```python
from ConsoleCommandsAPI import ConsoleCommandsAPI
```

### 2. 初始化
```python
# 在服务器初始化时创建控制台命令实例
console = ConsoleCommandsAPI(server)
```

### 3. 处理命令
```python
# 在控制台输入处理函数中
command_line = input("服务器控制台> ")
console.process_command(command_line)
```

## 扩展功能

### 添加自定义命令
```python
# 添加新命令
console.add_custom_command("mycommand", my_command_function, "我的自定义命令")

# 移除命令
console.remove_command("mycommand")

# 获取命令信息
info = console.get_command_info("addmoney")

# 批量执行命令
commands = ["addmoney 123456 1000", "addxp 123456 500"]
console.execute_batch_commands(commands)
```

## 依赖项

- `SMYMongoDBAPI` - MongoDB数据库操作模块
- `json` - JSON数据处理
- `os` - 操作系统接口
- `datetime` - 日期时间处理
- `typing` - 类型提示

## 注意事项

1. **MongoDB集成**: 数据库相关命令需要服务器启用MongoDB支持
2. **权限管理**: 所有命令都具有管理员权限，请谨慎使用
3. **数据备份**: 建议定期使用 `/dbbackup` 命令备份重要数据
4. **错误处理**: 所有命令都包含完善的错误处理和用户友好的提示信息
