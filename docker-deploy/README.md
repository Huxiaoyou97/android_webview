# 🐳 Docker部署指南

## 📁 文件说明

- **Dockerfile.fixed** - 修复版Dockerfile（解决路径问题）
- **rebuild-and-push.sh** - 一键构建并推送到Docker Hub
- **docker-buildx-push.sh** - 多架构构建脚本
- **docker-compose.simple.yml** - Docker Compose配置
- **Makefile** - Make命令集合

## 🚀 使用方法

### 1. 构建并推送镜像（开发者）

```bash
cd docker-deploy
./rebuild-and-push.sh 你的dockerhub用户名
```

这会构建支持AMD64和ARM64的多架构镜像并推送到Docker Hub。

### 2. 部署运行（使用者）

```bash
docker run -d \
  --name android-webview-builder \
  -p 8080:80 \
  huxiaoyou888/android-webview-builder:latest
```

访问 `http://localhost:8080`

## 🔧 如果遇到问题

重新构建并推送修复版：
```bash
./rebuild-and-push.sh 你的用户名
```

## 📝 支持架构

- Linux AMD64 (x86_64) - CentOS、Ubuntu等
- Linux ARM64 (aarch64) - Mac M1/M2