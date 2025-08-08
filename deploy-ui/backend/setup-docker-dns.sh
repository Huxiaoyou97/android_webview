#!/bin/bash

# CentOS 7 Docker DNS 配置脚本

echo "配置 Docker daemon DNS..."

# 1. 创建或修改 Docker daemon 配置文件
sudo mkdir -p /etc/docker
sudo cat > /etc/docker/daemon.json << 'EOF'
{
  "dns": ["8.8.8.8", "8.8.4.4"],
  "registry-mirrors": [],
  "insecure-registries": [],
  "debug": false,
  "experimental": false
}
EOF

# 2. 重新加载 systemd 配置
sudo systemctl daemon-reload

# 3. 重启 Docker 服务
sudo systemctl restart docker

# 4. 验证配置
echo "验证 Docker 配置..."
sudo docker info | grep -A 2 "DNS"

echo "配置完成！"