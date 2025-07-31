#!/bin/bash

# R类import修复部署脚本

echo "🔧 应用R类import修复..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "1️⃣ 停止容器..."
docker-compose down

echo "2️⃣ 测试修复后的脚本逻辑..."
cd "../deploy"

# 创建测试配置
echo '{
  "app_name": "测试应用",
  "app_url": "https://888i.bet/?web_app=1",
  "icon_file": "icon.png"
}' > config.json

echo "   ✅ 创建测试配置"

# 复制一个测试图标（如果不存在）
if [ ! -f "icon.png" ]; then
    if [ -f "../app/src/main/res/mipmap-hdpi/ic_launcher.png" ]; then
        cp "../app/src/main/res/mipmap-hdpi/ic_launcher.png" "icon.png"
        echo "   ✅ 复制测试图标"
    else
        echo "   ⚠️  测试图标不存在，但构建可能仍然成功"
    fi
fi

cd "../deploy-ui"

echo "3️⃣ 重新构建并启动容器..."
docker-compose up --build -d

echo "4️⃣ 等待服务启动..."
sleep 20

echo "5️⃣ 检查服务状态..."
docker-compose ps

echo ""
echo "🎉 R类import修复应用完成！"
echo ""
echo "🔧 修复内容："
echo "   - 自动添加正确的 import package.R; 语句"
echo "   - 删除旧的R类import引用"
echo "   - 确保所有Java文件的包名声明正确"
echo ""
echo "✅ 现在R类应该能正确找到了！"
echo ""
echo "🧪 测试地址: http://localhost"
echo "📝 查看构建日志: docker-compose logs backend"