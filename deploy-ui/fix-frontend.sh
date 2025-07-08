#!/bin/bash

echo "🔧 重新部署..."

echo "1. 停止所有服务..."
docker-compose down

echo "2. 清理镜像..."
docker rmi deploy-ui-frontend deploy-ui-backend 2>/dev/null || echo "镜像已清理"

echo "3. 重新构建..."
docker-compose build --no-cache

echo "4. 启动服务..."
docker-compose up -d

echo "5. 检查状态..."
sleep 15
docker-compose ps

echo "6. 测试访问..."
curl -I http://localhost 2>/dev/null | head -1 || echo "无法访问"

echo ""
echo "🎉 完成！访问: http://你的服务器IP/"