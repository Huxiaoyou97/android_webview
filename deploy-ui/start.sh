#!/bin/bash

echo "🚀 启动Android WebApp构建平台..."

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ 错误：未检测到Docker，请先安装Docker"
    echo "💡 安装指南: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查Docker Compose是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "❌ 错误：未检测到Docker Compose，请先安装Docker Compose"
    echo "💡 安装指南: https://docs.docker.com/compose/install/"
    exit 1
fi

# 停止现有的容器
echo "🛑 停止现有容器..."
docker-compose down

# 构建并启动服务
echo "🔨 构建Docker镜像..."
docker-compose build

echo "🚀 启动服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "📊 检查服务状态..."
docker-compose ps

# 显示访问信息
echo ""
echo "🎉 Android WebApp构建平台已启动！"
echo ""
echo "📱 Web界面: http://localhost"
echo "🔗 API地址: http://localhost/api"
echo "📊 服务状态: docker-compose ps"
echo "📋 查看日志: docker-compose logs -f"
echo "🛑 停止服务: docker-compose down"
echo ""
echo "💡 首次启动可能需要几分钟下载Android SDK..."