#!/bin/bash

# 测试R类import修复

echo "🧪 测试R类import修复..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 创建测试环境
TEST_DIR="$SCRIPT_DIR/test_r_import"
mkdir -p "$TEST_DIR"

# 复制MainActivity.java进行测试
cp "../app/src/main/java/com/jsmiao/webapp/MainActivity.java" "$TEST_DIR/MainActivity.java"

echo "📝 原始MainActivity.java的package和import:"
head -20 "$TEST_DIR/MainActivity.java" | grep -E "^package|^import"

# 模拟修复过程
TEST_PACKAGE_NAME="com.bet.domain888i"
MAINACTIVITY_FILE="$TEST_DIR/MainActivity.java"

echo ""
echo "🔧 应用R类import修复..."

python3 -c "
import re
import sys

# 读取文件
with open('$MAINACTIVITY_FILE', 'r') as f:
    content = f.read()

# 替换包名声明
content = re.sub(r'^package\s+[^;]+;', 'package $TEST_PACKAGE_NAME;', content, flags=re.MULTILINE)

# 添加或更新R类的import语句
if 'import ' in content and '$TEST_PACKAGE_NAME.R;' not in content:
    # 删除旧的R import（如果存在）
    content = re.sub(r'import\s+[^;]*\.R;\s*\n', '', content, flags=re.MULTILINE)
    
    # 在package声明后添加新的R import
    content = re.sub(r'(package\s+[^;]+;\s*\n)', r'\1\nimport $TEST_PACKAGE_NAME.R;\n', content, flags=re.MULTILINE)

# 替换导入语句中的包名
content = re.sub(r'import\s+com\.jsmiao\.webapp\.', 'import $TEST_PACKAGE_NAME.', content, flags=re.MULTILINE)

# 写回文件
with open('$MAINACTIVITY_FILE', 'w') as f:
    f.write(content)
"

echo "📝 修复后MainActivity.java的package和import:"
head -20 "$MAINACTIVITY_FILE" | grep -E "^package|^import"

echo ""
echo "🔍 检查R类使用情况:"
grep -n "R\." "$MAINACTIVITY_FILE" | head -5

echo ""
echo "✅ R类import修复测试完成"

# 清理测试文件
rm -rf "$TEST_DIR"

echo "🚀 现在可以运行 ./fix_r_import.sh 应用修复"