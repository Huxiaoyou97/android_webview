#!/bin/bash

echo "🔧 重新构建前端服务..."

echo "1. 停止所有服务..."
docker-compose down

echo "2. 删除前端镜像缓存..."
docker-compose build --no-cache frontend

echo "3. 启动所有服务..."
docker-compose up -d

echo "4. 等待服务启动..."
sleep 15

echo "5. 检查服务状态..."
docker-compose ps

echo "6. 检查前端构建结果..."
docker-compose exec frontend ls -la dist/ 2>/dev/null || echo "等待容器完全启动..."

echo "7. 测试访问..."
if curl -f http://localhost >/dev/null 2>&1; then
    echo "✅ 服务正常运行！"
    echo "🌐 现在可以访问: http://你的服务器IP/"
else
    echo "❌ 仍有问题，查看详细日志："
    echo ""
    echo "前端日志："
    docker-compose logs frontend
    echo ""
    echo "Nginx日志："
    docker-compose logs nginx
fi