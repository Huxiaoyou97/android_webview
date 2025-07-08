#!/bin/bash

echo "🔧 部署应用..."

echo "1. 停止服务..."
docker-compose down

echo "2. 清理镜像..."
docker rmi deploy-ui-backend 2>/dev/null || echo "后端镜像已清理"

echo "3. 重新构建..."
docker-compose build --no-cache

echo "4. 启动服务..."
docker-compose up -d

echo "5. 等待服务启动..."
sleep 20

echo "6. 检查服务状态..."
docker-compose ps

echo "7. 检查后端日志..."
docker-compose logs --tail=20 backend

echo ""
echo "🎉 部署完成！"
echo "访问: http://你的服务器IP/"