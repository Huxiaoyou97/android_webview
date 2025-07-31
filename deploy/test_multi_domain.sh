#!/bin/bash

# 测试多域名APK构建脚本
# 用于验证不同域名是否能生成不同包名的APK

echo "🧪 开始测试多域名APK构建功能..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 测试域名列表
DOMAINS=(
    "https://example.com?test=1"
    "https://google.com/search?q=test"
    "https://test.app.io/path"
)

# 创建测试图标
if [ ! -f "icon.png" ]; then
    echo "⚠️  请先将测试图标文件复制为 icon.png"
    exit 1
fi

echo ""
echo "📋 测试域名列表："
for i in "${!DOMAINS[@]}"; do
    echo "  $((i+1)). ${DOMAINS[$i]}"
done

echo ""
echo "🔧 生成域名配置..."
for domain in "${DOMAINS[@]}"; do
    echo "处理域名: $domain"
    python3 domain_manager.py get "$domain" > /dev/null
done

echo ""
echo "📋 生成的域名配置："
./manage_domains.sh list

echo ""
echo "🔍 检查生成的签名文件："
ls -la keystores/

echo ""
echo "✅ 域名配置测试完成！"
echo ""
echo "现在可以通过以下方式测试实际构建："
echo "1. 使用Web界面分别输入不同域名进行构建"
echo "2. 或者修改config.json并运行auto_build.sh"
echo ""
echo "预期结果："
echo "- 每个域名应该生成不同的包名"
echo "- 每个域名应该使用不同的签名文件" 
echo "- 生成的APK应该可以在同一设备上共存"