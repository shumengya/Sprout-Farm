# 使用Python 3.13.2官方镜像作为基础镜像
FROM python:3.13.2-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# 配置apt使用阿里云镜像源
RUN echo "deb https://mirrors.aliyun.com/debian/ bookworm main" > /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian/ bookworm-updates main" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian-security/ bookworm-security main" >> /etc/apt/sources.list

# 复制requirements.txt并安装Python依赖
COPY requirements.txt .
# 配置pip使用国内镜像源
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn && \
    pip install --no-cache-dir -r requirements.txt

# 复制所有源代码
COPY . .

# 创建必要的目录
RUN mkdir -p config game_saves chat __pycache__

# 设置目录权限
RUN chmod -R 755 /app

# 暴露端口
EXPOSE 6060

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import socket; s = socket.socket(); s.settimeout(5); s.connect(('localhost', 6060)); s.close()" || exit 1

# 启动命令
CMD ["python", "TCPGameServer.py"] 