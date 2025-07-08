# 🚨 紧急部署指南 - 解决404问题

## 立即运行这个命令：

```bash
cd /path/to/deploy-ui
./emergency-fix.sh
```

## 如果还是404，手动检查：

1. **检查所有服务状态**
```bash
docker-compose ps
```

2. **查看日志**
```bash
docker-compose logs --tail=50
```

3. **直接测试各个服务**
```bash
# 测试前端
curl http://localhost:3000
# 测试后端
curl http://localhost:3001/api/health
# 测试nginx
curl http://localhost
```

## 最终解决方案：

如果上面都不行，直接用这个最简单的方法：

```bash
# 停止所有服务
docker-compose down

# 删除所有Docker镜像
docker system prune -af

# 重新构建
docker-compose up --build -d

# 等待30秒
sleep 30

# 检查状态
docker-compose ps
```

**访问地址：http://你的服务器IP/**

## 如果还是不行，说明问题不在前端构建，而在：

1. **端口占用** - 检查80端口是否被占用
2. **防火墙** - 检查服务器防火墙设置
3. **Docker网络** - 检查Docker网络配置
4. **Nginx配置** - 检查nginx代理配置