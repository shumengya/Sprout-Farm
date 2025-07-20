# 萌芽农场 MongoDB 迁移说明

## 概述

本文档描述了萌芽农场项目从JSON配置文件迁移到MongoDB数据库的过程。目前已完成每日签到配置的迁移，为后续其他配置的迁移奠定了基础。

## 迁移内容

### 1. 已完成的迁移

#### 每日签到配置 (daily_checkin_config.json)
- **原位置**: `Server/config/daily_checkin_config.json`
- **新位置**: MongoDB数据库 `mengyafarm.gameconfig` 集合
- **文档ID**: `687cce278e77ba00a7414ba2`
- **状态**: ✅ 已完成迁移

### 2. 数据库配置

#### 测试环境
- **地址**: `localhost:27017`
- **数据库**: `mengyafarm`
- **集合**: `gameconfig`

#### 生产环境
- **地址**: `192.168.31.233:27017`
- **数据库**: `mengyafarm`
- **集合**: `gameconfig`

## 技术实现

### 1. MongoDB API (SMYMongoDBAPI.py)

创建了专门的MongoDB API类，提供以下功能：

#### 核心功能
- 数据库连接管理（测试/生产环境）
- 游戏配置的读取和更新
- 通用文档操作（增删改查）
- 错误处理和日志记录

#### 主要方法
```python
# 配置管理
get_daily_checkin_config()          # 获取每日签到配置
update_daily_checkin_config()       # 更新每日签到配置
get_game_config(config_type)        # 获取通用游戏配置
set_game_config(config_type, data)  # 设置通用游戏配置

# 通用操作
insert_document(collection, doc)    # 插入文档
find_documents(collection, query)   # 查找文档
update_document(collection, query, update)  # 更新文档
delete_document(collection, query)  # 删除文档
```

### 2. 服务器集成 (TCPGameServer.py)

#### 修改内容
- 添加MongoDB API导入和初始化
- 修改 `_load_daily_check_in_config()` 方法，优先使用MongoDB
- 添加 `_update_daily_checkin_config_to_mongodb()` 方法
- 实现优雅降级：MongoDB失败时自动回退到JSON文件

#### 配置加载策略
1. **优先**: 尝试从MongoDB获取配置
2. **备选**: 从JSON文件加载配置
3. **兜底**: 使用默认配置

## 测试验证

### 1. MongoDB API测试
运行 `python SMYMongoDBAPI.py` 进行基础功能测试

### 2. 迁移功能测试
运行 `python test_mongodb_migration.py` 进行完整迁移测试

### 3. 服务器集成测试
运行 `python test_server_mongodb.py` 进行服务器集成测试

## 使用说明

### 1. 环境配置

#### 测试环境
```python
api = SMYMongoDBAPI("test")  # 连接到 localhost:27017
```

#### 生产环境
```python
api = SMYMongoDBAPI("production")  # 连接到 192.168.31.233:27017
```

### 2. 获取配置
```python
# 获取每日签到配置
config = api.get_daily_checkin_config()

# 获取通用游戏配置
config = api.get_game_config("config_type")
```

### 3. 更新配置
```python
# 更新每日签到配置
success = api.update_daily_checkin_config(new_config)

# 设置通用游戏配置
success = api.set_game_config("config_type", config_data)
```

## 后续迁移计划

### 1. 待迁移的配置文件
- [ ] `item_config.json` - 道具配置
- [ ] `pet_data.json` - 宠物配置
- [ ] 其他游戏配置文件

### 2. 迁移步骤
1. 将JSON文件导入到MongoDB
2. 修改对应的加载方法
3. 添加更新方法
4. 编写测试用例
5. 验证功能正常

### 3. 迁移原则
- **渐进式迁移**: 一次迁移一个配置文件
- **向后兼容**: 保持JSON文件作为备选方案
- **充分测试**: 每个迁移都要有完整的测试覆盖
- **文档更新**: 及时更新相关文档

## 注意事项

### 1. 数据安全
- 定期备份MongoDB数据
- 重要配置修改前先备份
- 测试环境验证后再应用到生产环境

### 2. 性能考虑
- MongoDB连接池管理
- 配置缓存策略
- 错误重试机制

### 3. 监控和日志
- 记录配置加载来源
- 监控MongoDB连接状态
- 记录配置更新操作

## 故障排除

### 1. MongoDB连接失败
- 检查MongoDB服务是否启动
- 验证连接地址和端口
- 检查网络连接

### 2. 配置加载失败
- 检查MongoDB中是否存在对应文档
- 验证文档格式是否正确
- 查看服务器日志获取详细错误信息

### 3. 配置更新失败
- 检查MongoDB权限
- 验证更新数据格式
- 确认文档ID是否正确

## 总结

本次迁移成功实现了每日签到配置从JSON文件到MongoDB的迁移，建立了完整的MongoDB API框架，为后续其他配置的迁移提供了可靠的基础。迁移过程采用了渐进式和向后兼容的策略，确保了系统的稳定性和可靠性。

通过测试验证，MongoDB迁移功能运行正常，服务器能够正确使用MongoDB中的配置数据，同时保持了JSON文件的备选方案，为后续的全面迁移奠定了坚实的基础。 