# SSL 证书配置

## 证书文件说明

将您的SSL证书文件放置在此目录中：

- `*.viteoai.com.crt` - SSL证书文件（通配符证书）
- `*.viteoai.com.key` - SSL私钥文件

## 获取证书

### 方式1：使用Let's Encrypt（免费）
```bash
# 安装certbot
apt-get update && apt-get install certbot

# 获取通配符证书（需要DNS验证）
certbot certonly --manual --preferred-challenges dns -d "*.viteoai.com"

# 证书将生成在 /etc/letsencrypt/live/viteoai.com/
# 复制到此目录
cp /etc/letsencrypt/live/viteoai.com/fullchain.pem ./*.viteoai.com.crt
cp /etc/letsencrypt/live/viteoai.com/privkey.pem ./*.viteoai.com.key
```

### 方式2：使用商业证书

从您的证书提供商下载证书文件，通常包含：
- 证书文件 (.crt 或 .pem)
- 私钥文件 (.key)
- 中间证书（如果有）

将它们命名为正确格式：
```bash
# 如果有中间证书，需要合并到crt文件中
cat your_domain.crt intermediate.crt > *.viteoai.com.crt
cp your_domain.key *.viteoai.com.key
```

## 部署步骤

1. 将证书文件（*.viteoai.com.crt 和 *.viteoai.com.key）放置在此目录
2. 确保文件权限正确：
   ```bash
   chmod 644 *.viteoai.com.crt
   chmod 600 *.viteoai.com.key
   ```
3. 重启Docker容器：
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## 注意事项

- 不要将私钥文件提交到Git仓库
- 定期更新证书（Let's Encrypt证书有效期90天）
- 确保证书文件格式正确（PEM格式）