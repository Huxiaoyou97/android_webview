#!/bin/bash

# Docker重新部署脚本 - 应用多域名APK修复

echo "🔄 重新部署Docker容器以应用多域名APK修复..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 1. 停止现有容器
echo "🛑 停止现有容器..."
docker-compose down

# 2. 清理旧的构建缓存
echo "🧹 清理Docker构建缓存..."
docker-compose build --no-cache

# 3. 重新启动容器
echo "🚀 启动新容器..."
docker-compose up -d

# 4. 等待容器启动
echo "⏳ 等待容器启动..."
sleep 10

# 5. 检查容器状态
echo "📋 检查容器状态..."
docker-compose ps

echo ""
echo "✅ Docker容器重新部署完成！"
echo ""
echo "🌐 访问地址: http://localhost"
echo "🔧 现在可以测试多域名APK构建功能了！"
echo ""
echo "测试建议："
echo "1. 尝试用 https://888i.bet/?web_app=1 构建一个APK"
echo "2. 尝试用 https://example.com?test=1 构建另一个APK"
echo "3. 两个APK应该可以同时安装在设备上"