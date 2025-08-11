# 🐳 Docker一键部署指南

## 快速使用（给使用者）

如果你只想使用这个Android WebView构建器，直接运行：

```bash
docker run -d \
  --name android-webview-builder \
  -p 8080:80 \
  -v ./data:/app/data \
  huxiaoyou888/android-webview-builder:latest
```

访问 `http://localhost:8080` 即可使用！

## 开发者指南

所有Docker相关文件都在 `docker-deploy/` 文件夹中：

```bash
cd docker-deploy
./docker-buildx-push.sh 你的dockerhub用户名 版本号
```

详细文档请查看：[docker-deploy/README.md](./docker-deploy/README.md)

## 支持的平台

- ✅ Linux AMD64 (x86_64) - 大多数服务器
- ✅ Linux ARM64 (aarch64) - Mac M1/M2, ARM服务器
- ✅ CentOS 7+
- ✅ Ubuntu 18.04+
- ✅ Debian 10+

## 系统要求

- Docker 20.10+
- 4GB+ 内存
- 10GB+ 磁盘空间