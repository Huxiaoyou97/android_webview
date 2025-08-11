#!/bin/bash

# 多架构构建和推送脚本
# 支持AMD64（x86_64）和ARM64架构

DOCKER_USERNAME="${1:-huxiaoyou888}"
VERSION="${2:-1.0.0}"
IMAGE_NAME="android-webview-builder"

echo "🔨 多架构Docker镜像构建和推送"
echo "用户名: ${DOCKER_USERNAME}"
echo "版本: ${VERSION}"
echo ""

# 检查是否已登录
echo "1. 检查Docker登录状态..."
docker info > /dev/null 2>&1 || {
    echo "请先登录Docker Hub："
    docker login
}

# 创建或使用buildx构建器
echo "2. 设置buildx多架构构建器..."
docker buildx create --name multiarch-builder --use 2>/dev/null || \
docker buildx use multiarch-builder

# 启动构建器
docker buildx inspect --bootstrap

# 构建并推送多架构镜像
echo "3. 构建并推送多架构镜像（AMD64 + ARM64）..."
echo "这可能需要较长时间，请耐心等待..."

docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION} \
    -t ${DOCKER_USERNAME}/${IMAGE_NAME}:latest \
    -f Dockerfile.cross-platform \
    --push \
    . || {
    echo "❌ 构建失败"
    exit 1
}

echo ""
echo "✅ 多架构镜像推送成功！"
echo ""
echo "支持的架构："
echo "  - linux/amd64 (x86_64) - 适用于大多数服务器"
echo "  - linux/arm64 (aarch64) - 适用于Mac M1/M2和ARM服务器"
echo ""
echo "Docker Hub地址："
echo "  https://hub.docker.com/r/${DOCKER_USERNAME}/${IMAGE_NAME}"
echo ""
echo "现在可以在任何架构上运行："
echo "  docker run -d --name ${IMAGE_NAME} -p 8080:80 ${DOCKER_USERNAME}/${IMAGE_NAME}:latest"