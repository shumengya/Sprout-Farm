#!/bin/bash

# 萌芽农场服务器 Docker 部署脚本
# 使用方法: ./deploy.sh [start|stop|restart|logs|status]

set -e

CONTAINER_NAME="mengyafarm-server"
IMAGE_NAME="mengyafarm-server"

# 显示帮助信息
show_help() {
    echo "萌芽农场服务器 Docker 部署脚本"
    echo "使用方法: $0 [命令]"
    echo ""
    echo "可用命令:"
    echo "  start    - 启动服务器"
    echo "  stop     - 停止服务器"
    echo "  restart  - 重启服务器"
    echo "  logs     - 查看日志"
    echo "  status   - 查看状态"
    echo "  build    - 重新构建镜像"
    echo "  clean    - 清理停止的容器和未使用的镜像"
    echo "  help     - 显示此帮助信息"
}

# 检查Docker是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
}

# 启动服务器
start_server() {
    echo "🚀 启动萌芽农场服务器..."
    
    # 检查配置文件是否存在
    if [ ! -f "config/crop_data.json" ]; then
        echo "⚠️  警告: 配置文件不存在，请确保 config 目录包含必要的配置文件"
    fi
    
    # 启动容器
    docker-compose up -d
    
    echo "✅ 服务器启动成功!"
    echo "📡 服务器地址: localhost:6060"
    echo "📝 查看日志: $0 logs"
}

# 停止服务器
stop_server() {
    echo "⏹️  停止萌芽农场服务器..."
    docker-compose down
    echo "✅ 服务器已停止"
}

# 重启服务器
restart_server() {
    echo "🔄 重启萌芽农场服务器..."
    docker-compose restart
    echo "✅ 服务器重启完成"
}

# 查看日志
show_logs() {
    echo "📝 查看服务器日志 (按 Ctrl+C 退出)..."
    docker-compose logs -f
}

# 查看状态
show_status() {
    echo "📊 服务器状态:"
    docker-compose ps
    echo ""
    
    if docker-compose ps | grep -q "Up"; then
        echo "✅ 服务器正在运行"
        echo "🔗 端口映射: 6060:6060"
        
        # 显示资源使用情况
        echo ""
        echo "📈 资源使用情况:"
        docker stats --no-stream $CONTAINER_NAME 2>/dev/null || echo "无法获取资源使用情况"
    else
        echo "❌ 服务器未运行"
    fi
}

# 构建镜像
build_image() {
    echo "🔨 重新构建镜像..."
    docker-compose build --no-cache
    echo "✅ 镜像构建完成"
}

# 清理
clean_up() {
    echo "🧹 清理停止的容器和未使用的镜像..."
    docker-compose down
    docker system prune -f
    echo "✅ 清理完成"
}

# 主函数
main() {
    check_docker
    
    case "${1:-help}" in
        "start")
            start_server
            ;;
        "stop")
            stop_server
            ;;
        "restart")
            restart_server
            ;;
        "logs")
            show_logs
            ;;
        "status")
            show_status
            ;;
        "build")
            build_image
            ;;
        "clean")
            clean_up
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# 执行主函数
main "$@" 