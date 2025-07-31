#!/bin/bash

# 简化测试脚本 - 测试域名管理功能

echo "🧪 测试域名管理功能..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 确保配置文件存在
echo "{}" > domain_configs.json
echo "✅ 重置配置文件"

# 测试域名
TEST_URL="https://888i.bet/?web_app=1"

echo ""
echo "🔧 测试域名: $TEST_URL"

# 直接调用Python脚本
python3 domain_manager.py get "$TEST_URL"

echo ""
echo "📋 查看生成的配置文件："
cat domain_configs.json

echo ""
echo "🔍 检查keystores目录："
ls -la keystores/ 2>/dev/null || echo "keystores目录不存在"