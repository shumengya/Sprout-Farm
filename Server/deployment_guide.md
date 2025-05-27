# 萌芽农场游戏服务器部署指南

## 系统要求
- Python 3.7 或更高版本
- 稳定的互联网连接
- 建议：2GB+ 内存，足够的磁盘空间存储玩家数据

## 安装步骤

### 1. 准备环境
```bash
# 在服务器上创建项目文件夹
mkdir MengYaFarm
cd MengYaFarm

# 克隆或上传服务器代码到此文件夹
# (手动上传文件或使用Git)
```

### 2. 安装依赖
```bash
# 创建虚拟环境(推荐)
python -m venv venv
# Linux/Mac激活虚拟环境
source venv/bin/activate
# Windows激活虚拟环境
# venv\Scripts\activate

# 安装依赖
pip install -r requirements.txt
```

### 3. 配置服务器
1. 确保已创建所需文件夹:
```bash
mkdir -p game_saves config
```

2. 创建初始玩家数据模板 (如果尚未存在):
```bash
# 在config目录中创建initial_player_data_template.json
```

3. 检查 TCPGameServer.py 中的服务器地址和端口配置:
```python
server_host: str = "0.0.0.0"  # 使用0.0.0.0允许所有网络接口访问
server_port: int = 9000       # 确保此端口在防火墙中开放
```

4. 如需使用QQ邮箱验证功能，请在QQEmailSend.py中更新发件邮箱配置:
```python
SENDER_EMAIL = 'your_qq_number@qq.com'  # 发件人邮箱
SENDER_AUTH_CODE = 'your_auth_code'     # 授权码
```

### 4. 启动服务器
```bash
# 直接启动
python Server/TCPGameServer.py

# 或使用nohup在后台运行
nohup python Server/TCPGameServer.py > server.log 2>&1 &
```

### 5. 监控与维护
- 服务器日志会输出到控制台或server.log
- 玩家数据存储在game_saves文件夹中
- 定期备份game_saves文件夹以防数据丢失

### 6. 防火墙配置
确保服务器防火墙允许TCP 9000端口的入站连接:

```bash
# Ubuntu/Debian
sudo ufw allow 9000/tcp

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=9000/tcp
sudo firewall-cmd --reload
```

### 7. 系统服务配置 (可选)
可以创建systemd服务使服务器自动启动:

```bash
# 创建服务文件
sudo nano /etc/systemd/system/mengyafarm.service

# 添加以下内容
[Unit]
Description=MengYa Farm Game Server
After=network.target

[Service]
Type=simple
User=your_username
WorkingDirectory=/path/to/MengYaFarm
ExecStart=/path/to/MengYaFarm/venv/bin/python /path/to/MengYaFarm/Server/TCPGameServer.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target

# 启用并启动服务
sudo systemctl enable mengyafarm.service
sudo systemctl start mengyafarm.service
```

## 常见问题

### 服务器无法启动
- 检查Python版本
- 确认所有依赖已正确安装
- 检查端口是否被占用

### 客户端无法连接
- 确认服务器IP和端口配置正确
- 检查防火墙设置
- 验证网络连接

### 发送验证码失败
- 检查QQ邮箱和授权码设置
- 确认SMTP服务器可访问 