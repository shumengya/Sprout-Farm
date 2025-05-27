# 铲除作物功能实现

## 功能概述

实现了玩家可以花费500金钱铲除地块上的作物，将地块变成空地的功能。这个功能完全基于服务器端处理，确保数据的一致性和安全性。

## 功能特点

- **费用固定**：铲除任何作物都需要花费500金钱
- **服务器验证**：所有验证和处理都在服务器端完成
- **状态重置**：铲除后地块变成空地，可以重新种植
- **访客保护**：访客模式下无法进行铲除操作
- **实时更新**：操作完成后立即更新客户端显示

## 实现架构

### 1. 服务器端实现

#### 消息路由
```python
elif message_type == "remove_crop":
    return self._handle_remove_crop(client_id, message)
```

#### 主处理方法
```python
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
```

#### 铲除处理逻辑
```python
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
```

### 2. 网络通信

#### 客户端发送请求
```gdscript
#发送铲除作物信息
func sendRemoveCrop(lot_index):
    if not client.is_client_connected():
        return false
        
    client.send_data({
        "type": "remove_crop",
        "lot_index": lot_index,
        "timestamp": Time.get_unix_time_from_system()
    })
    return true
```

### 3. 客户端UI实现

#### 按钮文本更新
```gdscript
# 更新按钮文本
func _update_button_texts():
    dig_button.text = "开垦"+"\n花费："+str(main_game.dig_money)
    remove_button.text = "铲除"+"\n花费：500"
```

#### 铲除操作处理
```gdscript
#铲除
func _on_remove_button_pressed():
    # 检查是否处于访问模式
    if main_game.is_visiting_mode:
        Toast.show("访问模式下无法铲除作物", Color.ORANGE, 2.0, 1.0)
        self.hide()
        return
    
    # 检查玩家金钱是否足够
    var removal_cost = 500
    if main_game.money < removal_cost:
        Toast.show("金钱不足，铲除作物需要 " + str(removal_cost) + " 金钱", Color.RED, 2.0, 1.0)
        self.hide()
        return
    
    # 检查地块是否有作物
    var lot = main_game.farm_lots[selected_lot_index]
    if not lot.get("is_planted", false) or lot.get("crop_type", "") == "":
        Toast.show("此地块没有种植作物", Color.ORANGE, 2.0, 1.0)
        self.hide()
        return
    
    # 发送铲除作物请求到服务器
    if network_manager and network_manager.is_connected_to_server():
        if network_manager.sendRemoveCrop(selected_lot_index):
            Toast.show("正在铲除作物...", Color.YELLOW, 1.5, 1.0)
            self.hide()
        else:
            Toast.show("发送铲除请求失败", Color.RED, 2.0, 1.0)
            self.hide()
    else:
        Toast.show("网络未连接，无法铲除作物", Color.RED, 2.0, 1.0)
        self.hide()
```

## 验证机制

### 服务器端验证
1. **用户登录验证**：确保用户已登录
2. **地块索引验证**：检查地块索引是否有效
3. **地块状态验证**：确保地块有作物可以铲除
4. **金钱验证**：检查玩家金钱是否足够支付铲除费用

### 客户端预验证
1. **访问模式检查**：访客模式下禁止操作
2. **金钱预检查**：提前检查金钱是否足够
3. **地块状态预检查**：确保地块有作物
4. **网络连接检查**：确保能够发送请求

## 操作流程

### 正常流程
1. 玩家点击地块，显示操作面板
2. 面板显示铲除按钮和费用信息
3. 玩家点击铲除按钮
4. 客户端进行预验证
5. 发送铲除请求到服务器
6. 服务器验证并处理请求
7. 服务器返回操作结果
8. 客户端更新UI显示

### 错误处理
- **金钱不足**：显示错误提示，不发送请求
- **无作物**：显示提示信息，不发送请求
- **访客模式**：显示权限提示，不发送请求
- **网络错误**：显示网络错误提示
- **服务器错误**：显示服务器返回的错误信息

## 数据更新

### 地块状态重置
```python
lot["is_planted"] = False      # 取消种植状态
lot["crop_type"] = ""          # 清空作物类型
lot["grow_time"] = 0           # 重置生长时间
lot["is_dead"] = False         # 重置死亡状态
```

### 玩家数据更新
```python
player_data["money"] -= removal_cost  # 扣除金钱
```

### 实时同步
- 服务器保存玩家数据到文件
- 推送作物更新到客户端
- 客户端接收并更新UI显示

## 使用场景

1. **清理死亡作物**：当作物死亡时，玩家可以花费金钱清理
2. **重新规划农场**：玩家想要种植不同作物时
3. **紧急处理**：当玩家需要快速清理地块时
4. **策略调整**：根据市场需求调整种植策略

## 安全考虑

1. **服务器权威**：所有验证和处理都在服务器端
2. **数据一致性**：确保客户端和服务器数据同步
3. **防作弊**：客户端无法直接修改游戏数据
4. **访问控制**：访客模式下无法进行破坏性操作

## 扩展性

该功能设计具有良好的扩展性：

1. **费用可配置**：可以根据作物类型设置不同的铲除费用
2. **条件扩展**：可以添加更多的铲除条件（如等级要求）
3. **奖励机制**：可以在铲除时给予部分资源回收
4. **工具系统**：可以引入铲子等工具来影响铲除效果

## 测试用例

### 测试用例1：正常铲除
1. 玩家有足够金钱（≥500）
2. 地块有作物
3. 点击铲除按钮
4. 验证：金钱减少500，地块变成空地

### 测试用例2：金钱不足
1. 玩家金钱不足（<500）
2. 地块有作物
3. 点击铲除按钮
4. 验证：显示金钱不足提示，操作失败

### 测试用例3：无作物地块
1. 玩家有足够金钱
2. 地块为空地
3. 点击铲除按钮
4. 验证：显示无作物提示，操作失败

### 测试用例4：访客模式
1. 玩家处于访客模式
2. 点击铲除按钮
3. 验证：显示权限提示，操作失败

### 测试用例5：网络断开
1. 网络连接断开
2. 点击铲除按钮
3. 验证：显示网络错误提示，操作失败

## 总结

铲除作物功能的实现遵循了以下设计原则：

- ✅ **服务器权威**：所有关键逻辑在服务器端处理
- ✅ **用户体验**：提供清晰的费用信息和操作反馈
- ✅ **数据安全**：多层验证确保数据完整性
- ✅ **错误处理**：完善的错误提示和处理机制
- ✅ **代码复用**：利用现有的验证和处理框架
- ✅ **可维护性**：清晰的代码结构和文档

这个功能为玩家提供了更灵活的农场管理选项，同时保持了游戏的平衡性和数据安全性。 