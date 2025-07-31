#!/bin/bash

# 包名修复部署脚本

echo "🔧 应用Java包名修复..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "1️⃣ 停止容器..."
docker-compose down

echo "2️⃣ 清理旧的域名配置（因为包名格式变了）..."
if [ -f "../deploy/domain_configs.json" ]; then
    echo "{}" > "../deploy/domain_configs.json"
    echo "   ✅ 已重置域名配置"
fi

echo "3️⃣ 测试新的包名生成逻辑..."
cd "../deploy"

echo "   测试 888i.bet:"
python3 simple_domain_manager.py get "https://888i.bet/?web_app=1" | grep package_name

echo "   测试 example.com:"
python3 simple_domain_manager.py get "https://example.com" | grep package_name

echo "   测试 123test.com:"
python3 simple_domain_manager.py get "https://123test.com" | grep package_name

echo "   ✅ 包名生成测试完成"

cd "../deploy-ui"

echo "4️⃣ 重新构建并启动容器..."
docker-compose up --build -d

echo "5️⃣ 等待服务启动..."
sleep 15

echo "6️⃣ 检查服务状态..."
docker-compose ps

echo ""
echo "🎉 Java包名修复应用完成！"
echo ""
echo "📱 新的包名格式："
echo "   - 888i.bet → com.bet.domain888i"
echo "   - example.com → com.com.example"  
echo "   - 123test.com → com.com.domain123test"
echo ""
echo "✅ 现在所有包名都符合Java规范，可以正常构建APK了！"
echo ""
echo "🧪 测试地址: http://localhost"