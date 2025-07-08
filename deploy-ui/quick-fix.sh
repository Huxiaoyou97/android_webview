#!/bin/bash

echo "🚀 快速修复部署问题..."

echo "1. 停止所有服务..."
docker-compose down

echo "2. 重新构建前端镜像..."
docker-compose build --no-cache frontend

echo "3. 启动所有服务..."
docker-compose up -d

echo "4. 等待服务启动（30秒）..."
sleep 30

echo "5. 检查服务状态..."
docker-compose ps

echo "6. 测试服务..."
echo "前端测试："
curl -I http://localhost:3000 2>/dev/null | head -1 || echo "前端连接失败"

echo "后端测试："
curl -I http://localhost:3001/api/health 2>/dev/null | head -1 || echo "后端连接失败"

echo "Nginx测试："
curl -I http://localhost 2>/dev/null | head -1 || echo "Nginx连接失败"

echo ""
echo "7. 如果仍有问题，请查看日志："
echo "docker-compose logs frontend"
echo "docker-compose logs backend" 
echo "docker-compose logs nginx"

echo ""
echo "🎉 修复完成！现在应该可以访问 http://你的服务器IP/ 了"