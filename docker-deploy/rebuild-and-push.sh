#!/bin/bash

# 一键重新构建并推送修复版镜像
DOCKER_USERNAME="${1:-huxiaoyou888}"
VERSION="1.0.5"

echo "🔧 修复并重新构建镜像..."
echo "用户名: ${DOCKER_USERNAME}"
echo "版本: ${VERSION}"
echo ""

# 1. 创建或使用buildx构建器
echo "设置多架构构建器..."
docker buildx create --name multiarch-builder --use 2>/dev/null || docker buildx use multiarch-builder
docker buildx inspect --bootstrap

# 2. 构建并推送修复版镜像（支持AMD64和ARM64）
echo "构建并推送多架构镜像..."
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t ${DOCKER_USERNAME}/android-webview-builder:${VERSION} \
    -t ${DOCKER_USERNAME}/android-webview-builder:latest \
    -f Dockerfile.simple \
    --push \
    .. || {
    echo "❌ 构建失败"
    exit 1
}

echo ""
echo "✅ 修复版镜像已推送！"
echo ""
echo "现在在服务器上运行："
echo "docker pull ${DOCKER_USERNAME}/android-webview-builder:latest"
echo "docker run -d --name android-webview-builder -p 8080:80 ${DOCKER_USERNAME}/android-webview-builder:latest"