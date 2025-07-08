#!/bin/bash

echo "🚨 紧急修复 - 直接解决404问题"

echo "1. 停止所有服务"
docker-compose down

echo "2. 删除所有镜像重新开始"
docker rmi deploy-ui-frontend deploy-ui-backend deploy-ui-nginx 2>/dev/null || echo "镜像已清理"

echo "3. 使用最简单的前端配置"
cat > frontend/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
RUN ls -la dist/
EXPOSE 3000
CMD ["npx", "serve", "-s", "dist", "-l", "3000"]
EOF

echo "4. 重新构建并立即启动"
docker-compose up --build -d

echo "5. 等待启动完成"
sleep 30

echo "6. 检查状态"
docker-compose ps

echo "7. 测试访问"
curl -I http://localhost 2>/dev/null | head -1 || echo "仍然无法访问"

echo ""
echo "🔧 如果还是404，运行以下命令检查："
echo "docker-compose logs --tail=50"
echo ""
echo "💡 直接访问前端: http://localhost:3000"
echo "💡 直接访问后端: http://localhost:3001"
echo "💡 nginx代理: http://localhost"