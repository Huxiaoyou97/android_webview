#!/bin/bash

# 快速修复脚本 - 应用多域名APK修复并重新部署

echo "🔧 应用多域名APK共存修复..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "1️⃣ 停止现有容器..."
docker-compose down

echo "2️⃣ 应用修复..."
# 确保所有修复文件都存在
echo "   检查修复文件..."
if [ ! -f "../deploy/simple_domain_manager.py" ]; then
    echo "❌ 简化域名管理器缺失"
    exit 1
fi

if [ ! -f "../deploy/domain_configs.json" ]; then
    echo "{}" > "../deploy/domain_configs.json"
    echo "   ✅ 创建domain_configs.json"
fi

if [ ! -d "../deploy/keystores" ]; then
    mkdir -p "../deploy/keystores"
    echo "   ✅ 创建keystores目录"
fi

echo "   ✅ 所有修复文件就位"

echo "3️⃣ 重新构建并启动容器..."
docker-compose up --build -d

echo "4️⃣ 等待服务启动..."
sleep 15

echo "5️⃣ 检查服务状态..."
docker-compose ps

echo ""
echo "🎉 修复应用完成！"
echo ""
echo "📱 现在可以测试多域名APK共存功能："
echo "   🌐 Web界面: http://localhost"
echo ""
echo "🧪 测试步骤："
echo "   1. 用 https://888i.bet/?web_app=1 构建第一个APK"
echo "   2. 用 https://example.com?test=1 构建第二个APK"  
echo "   3. 两个APK应该可以同时安装在设备上"
echo ""
echo "📊 包名预期："
echo "   - 888i.bet → com.bet.888i"
echo "   - example.com → com.com.example"
echo ""
echo "✅ 如果还有问题，查看日志: docker-compose logs backend"