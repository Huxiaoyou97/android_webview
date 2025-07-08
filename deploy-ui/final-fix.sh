#!/bin/bash

echo "🔧 最终修复前端构建问题..."

echo "1. 停止所有服务..."
docker-compose down

echo "2. 清理Docker缓存..."
docker system prune -f
docker rmi deploy-ui-frontend 2>/dev/null || echo "前端镜像不存在"

echo "3. 检查前端源代码..."
echo "=== 检查package.json ==="
cat frontend/package.json | grep -A5 -B5 "scripts"

echo "=== 检查vite.config.js ==="
cat frontend/vite.config.js

echo "4. 重新构建前端镜像（详细日志）..."
docker-compose build --no-cache --progress=plain frontend

echo "5. 验证构建是否成功..."
if docker run --rm deploy-ui-frontend sh -c "ls -la /app/dist/index.html" 2>/dev/null; then
    echo "✅ 前端构建成功！"
    BUILD_SUCCESS=true
else
    echo "❌ 前端构建失败，尝试手动调试..."
    echo "启动容器进行调试..."
    docker run -it --rm deploy-ui-frontend sh -c "
        echo '=== 工作目录 ==='
        ls -la /app/
        echo '=== 检查依赖 ==='
        yarn list --depth=0 2>/dev/null | head -10
        echo '=== 手动构建 ==='
        cd /app && yarn build 2>&1
        echo '=== 构建结果 ==='
        ls -la /app/dist/ 2>/dev/null || echo 'dist目录不存在'
    " || echo "容器启动失败"
    BUILD_SUCCESS=false
fi

if [ "$BUILD_SUCCESS" = true ]; then
    echo "6. 启动所有服务..."
    docker-compose up -d
    
    echo "7. 等待服务启动..."
    sleep 20
    
    echo "8. 检查服务状态..."
    docker-compose ps
    
    echo "9. 测试访问..."
    echo "前端直接访问："
    curl -I http://localhost:3000 2>/dev/null | head -1 || echo "前端无法访问"
    
    echo "Nginx代理访问："
    curl -I http://localhost 2>/dev/null | head -1 || echo "Nginx无法访问"
    
    echo ""
    echo "🎉 修复完成！"
    echo "📱 访问地址: http://你的服务器IP/"
    echo ""
    echo "如果仍有问题，请查看日志："
    echo "docker-compose logs frontend"
    echo "docker-compose logs nginx"
else
    echo "❌ 构建失败，需要手动检查前端代码"
    echo "可能的原因："
    echo "1. package.json 脚本配置错误"
    echo "2. vite.config.js 配置问题"
    echo "3. 前端代码语法错误"
    echo "4. 依赖版本冲突"
fi