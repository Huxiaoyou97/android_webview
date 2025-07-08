#!/bin/bash

echo "🔍 详细调试前端构建问题..."

echo "1. 停止服务..."
docker-compose down

echo "2. 手动构建前端镜像并查看详细输出..."
docker-compose build --no-cache frontend

echo "3. 启动前端容器进行调试..."
docker-compose up -d frontend

echo "4. 等待容器启动..."
sleep 5

echo "5. 检查前端容器内容..."
docker-compose exec frontend sh -c "
echo '=== 工作目录内容 ==='
ls -la /app/
echo ''
echo '=== 检查package.json ==='
cat /app/package.json | head -20
echo ''
echo '=== 检查yarn版本 ==='
yarn --version
echo ''
echo '=== 手动尝试构建 ==='
cd /app && yarn build
echo ''
echo '=== 检查构建结果 ==='
ls -la /app/dist/ || echo 'dist目录不存在'
"

echo "6. 检查构建是否成功..."
if docker-compose exec frontend ls /app/dist/index.html >/dev/null 2>&1; then
    echo "✅ 构建成功！重启所有服务..."
    docker-compose down
    docker-compose up -d
else
    echo "❌ 构建失败，查看错误日志..."
    docker-compose logs frontend
fi