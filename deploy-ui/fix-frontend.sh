#!/bin/bash

echo "🔧 修复前端构建问题..."

echo "1. 停止所有服务..."
docker-compose down

echo "2. 删除前端镜像..."
docker rmi deploy-ui-frontend 2>/dev/null || echo "镜像不存在，跳过删除"

echo "3. 重新构建前端镜像（查看详细输出）..."
docker-compose build --no-cache --progress=plain frontend

echo "4. 检查构建是否成功..."
if docker run --rm deploy-ui-frontend ls /app/dist/index.html >/dev/null 2>&1; then
    echo "✅ 前端构建成功！"
else
    echo "❌ 前端构建失败，查看构建日志："
    echo "可能的原因："
    echo "1. vite配置问题"
    echo "2. 依赖安装失败" 
    echo "3. 代码语法错误"
    exit 1
fi

echo "5. 启动所有服务..."
docker-compose up -d

echo "6. 等待服务启动..."
sleep 15

echo "7. 测试前端访问..."
if curl -f http://localhost:3000 >/dev/null 2>&1; then
    echo "✅ 前端服务正常"
else
    echo "❌ 前端服务异常"
    docker-compose logs frontend
fi

echo "8. 测试完整流程..."
if curl -f http://localhost >/dev/null 2>&1; then
    echo "✅ 网站可以正常访问了！"
    echo "🌐 访问地址: http://你的服务器IP/"
else
    echo "❌ 网站仍有问题，查看nginx日志："
    docker-compose logs nginx
fi