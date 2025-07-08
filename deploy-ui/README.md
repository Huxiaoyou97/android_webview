# Android WebApp Builder - 可视化构建平台

一个完整的可视化Android WebApp构建平台，用户可以通过Web界面轻松将网站打包成Android应用。

## ✨ 功能特色

- 🎯 **可视化界面**：直观的Web UI，无需命令行操作
- 📱 **一键打包**：输入应用信息，自动生成APK文件
- 🖼️ **图标处理**：自动调整图标尺寸，适配各种设备
- 📊 **实时进度**：构建过程实时显示，日志可视化
- ⬇️ **即时下载**：构建完成立即提供APK下载
- 🐳 **Docker部署**：容器化部署，环境隔离
- 🔄 **自动化流程**：从上传到构建到下载的完整自动化

## 🏗️ 系统架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   React前端     │◄──►│  Express后端    │◄──►│  Android构建    │
│                 │    │                 │    │                 │
│  - 表单界面     │    │  - 文件上传     │    │  - Gradle构建   │
│  - 进度显示     │    │  - 构建管理     │    │  - APK生成      │
│  - 下载功能     │    │  - API服务      │    │  - 文件处理     │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │                 │
                    │   Nginx代理     │
                    │                 │
                    │  - 路由转发     │
                    │  - 静态文件     │
                    │  - 负载均衡     │
                    │                 │
                    └─────────────────┘
```

## 🚀 快速开始

### 1. 环境准备

确保你的系统已安装：
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### 2. 克隆项目

```bash
# 如果你还没有完整项目，请先获取
git clone <your-repo>
cd android-webapp/deploy-ui
```

### 3. 一键启动

```bash
# 启动所有服务
./start.sh
```

启动完成后，访问：
- **Web界面**: http://localhost
- **API接口**: http://localhost/api

### 4. 使用平台

1. 打开浏览器访问 http://localhost
2. 填写应用信息：
   - 应用名称（例如：我的应用）
   - 网站URL（例如：https://www.example.com）
   - 上传512x512的PNG图标
3. 点击"开始构建APK"
4. 等待构建完成（首次可能需要5-10分钟）
5. 下载生成的APK文件

## 📁 项目结构

```
deploy-ui/
├── frontend/                 # React前端应用
│   ├── src/
│   │   ├── components/      # React组件
│   │   │   ├── BuildForm.jsx
│   │   │   ├── ProgressModal.jsx
│   │   │   └── DownloadModal.jsx
│   │   ├── App.jsx         # 主应用组件
│   │   └── main.jsx        # 入口文件
│   ├── package.json
│   ├── vite.config.js      # Vite配置
│   ├── tailwind.config.js  # TailwindCSS配置
│   └── Dockerfile
├── backend/                 # Node.js后端服务
│   ├── server.js           # Express服务器
│   ├── package.json
│   └── Dockerfile
├── docker-compose.yml      # Docker Compose配置
├── nginx.conf              # Nginx配置
├── start.sh                # 启动脚本
└── README.md               # 项目文档
```

## 🐳 Docker服务说明

### 服务组件

- **frontend**: React前端应用 (端口3000)
- **backend**: Node.js API服务 (端口3001)
- **nginx**: 反向代理服务器 (端口80)

### 常用命令

```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看实时日志
docker-compose logs -f

# 停止所有服务
docker-compose down

# 重新构建并启动
docker-compose up --build -d

# 查看特定服务日志
docker-compose logs -f backend
```

## 🔧 开发模式

如果你想在开发模式下运行（用于调试和修改）：

### 前端开发

```bash
cd frontend
npm install
npm run dev
```

### 后端开发

```bash
cd backend
npm install
npm run dev
```

## 📊 API接口文档

### 构建APK

```http
POST /api/build
Content-Type: multipart/form-data

FormData:
- appName: string (应用名称)
- appUrl: string (网站URL)
- icon: file (PNG图标文件)
```

### 获取构建状态

```http
GET /api/build/status

Response:
{
  "isBuilding": boolean,
  "progress": number (0-100),
  "logs": array,
  "success": boolean,
  "completed": boolean,
  "downloadUrl": string
}
```

### 下载APK

```http
GET /api/download/:filename
```

## 🛠️ 自定义配置

### 修改端口

编辑 `docker-compose.yml` 文件中的端口映射：

```yaml
services:
  nginx:
    ports:
      - "8080:80"  # 改为8080端口
```

### 修改上传限制

编辑 `nginx.conf` 中的文件大小限制：

```nginx
client_max_body_size 50M;  # 改为50MB
```

### 添加环境变量

在 `docker-compose.yml` 中添加环境变量：

```yaml
services:
  backend:
    environment:
      - NODE_ENV=production
      - MAX_FILE_SIZE=10485760
```

## 🔍 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 检查端口占用
   sudo lsof -i :80
   # 或修改docker-compose.yml中的端口
   ```

2. **Docker权限问题**
   ```bash
   # 添加用户到docker组
   sudo usermod -aG docker $USER
   # 重新登录或重启
   ```

3. **构建失败**
   ```bash
   # 查看详细日志
   docker-compose logs backend
   # 检查Android SDK安装
   docker-compose exec backend java -version
   ```

4. **首次构建慢**
   - 首次启动需要下载Android SDK (约1-2GB)
   - 后续构建会快很多
   - 可以提前拉取镜像：`docker-compose pull`

### 日志查看

```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs frontend
docker-compose logs backend
docker-compose logs nginx

# 实时跟踪日志
docker-compose logs -f backend
```

## 📈 性能优化

### 构建优化

1. **缓存Docker层**：Dockerfile已优化层缓存
2. **并行构建**：使用Docker BuildKit
3. **资源限制**：可在docker-compose.yml中添加资源限制

### 监控

```bash
# 查看资源使用
docker stats

# 查看磁盘使用
docker system df
```

## 🔐 安全考虑

- 文件上传限制：只允许PNG格式，最大5MB
- 输入验证：前后端都有表单验证
- 容器隔离：每个服务运行在独立容器中
- 临时文件清理：构建完成后自动清理临时文件

## 🤝 贡献指南

1. Fork项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启Pull Request

## 📄 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

- React团队提供的优秀前端框架
- Express.js团队提供的Node.js框架
- TailwindCSS团队提供的CSS框架
- Docker团队提供的容器化技术

---

**Happy Building! 🚀**