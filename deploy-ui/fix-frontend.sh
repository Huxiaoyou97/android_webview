#!/bin/bash

echo "🔧 修复前端构建问题..."

echo "1. 停止所有服务..."
docker-compose down

echo "2. 删除前端镜像..."
docker rmi deploy-ui-frontend 2>/dev/null || echo "镜像不存在，跳过删除"

echo "3. 重新构建前端镜像..."
docker-compose build --no-cache frontend

echo "4. 启动所有服务..."
docker-compose up -d

echo "5. 等待服务启动..."
sleep 20

echo "6. 检查服务状态..."
docker-compose ps

echo "7. 测试访问..."
curl -I http://localhost 2>/dev/null | head -1 || echo "无法访问"

echo ""
echo "🎉 完成！访问地址: http://你的服务器IP/"
echo ""
echo "如果仍有问题，查看日志："
echo "docker-compose logs frontend"
echo "docker-compose logs nginx"