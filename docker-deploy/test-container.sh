#!/bin/bash

# 测试Docker容器环境
CONTAINER_NAME="${1:-android-webview-builder}"

echo "🔍 测试容器环境: ${CONTAINER_NAME}"
echo ""

echo "1. 检查Java环境："
docker exec ${CONTAINER_NAME} bash -c "java -version"
echo ""

echo "2. 检查Gradle："
docker exec ${CONTAINER_NAME} bash -c "cd /app/workspace && ./gradlew --version"
echo ""

echo "3. 检查关键文件："
docker exec ${CONTAINER_NAME} bash -c "ls -la /app/workspace/gradle/wrapper/"
echo ""

echo "4. 检查签名文件："
docker exec ${CONTAINER_NAME} bash -c "ls -la /app/workspace/deploy/keystores/"
echo ""

echo "5. 检查日志目录："
docker exec ${CONTAINER_NAME} bash -c "ls -la /app/logs/"
echo ""

echo "6. 测试构建（简单测试）："
docker exec ${CONTAINER_NAME} bash -c "cd /app/workspace && ./gradlew tasks | head -20"
echo ""

echo "7. 检查后端服务："
docker exec ${CONTAINER_NAME} bash -c "curl -s http://localhost:3001/health || echo '后端未响应'"
echo ""

echo "8. 查看后端日志："
docker exec ${CONTAINER_NAME} bash -c "tail -20 /app/logs/backend.log 2>/dev/null || echo '无日志'"