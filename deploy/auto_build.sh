#!/bin/bash

# 自动打包脚本 - Android WebApp
# 使用方法：./auto_build.sh

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 配置文件路径
CONFIG_FILE="$SCRIPT_DIR/config.json"

# 检查是否安装了jq（用于解析JSON）
if ! command -v jq &> /dev/null; then
    echo "错误：请先安装 jq 工具来解析JSON配置文件"
    echo "在 macOS 上: brew install jq"
    echo "在 Ubuntu 上: sudo apt-get install jq"
    exit 1
fi

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误：配置文件 $CONFIG_FILE 不存在"
    exit 1
fi

# 读取配置文件
echo "正在读取配置文件..."
APP_NAME=$(jq -r '.app_name' "$CONFIG_FILE")
APP_URL=$(jq -r '.app_url' "$CONFIG_FILE")
ICON_FILE=$(jq -r '.icon_file' "$CONFIG_FILE")

# 验证配置
if [ "$APP_NAME" = "null" ] || [ "$APP_URL" = "null" ] || [ "$ICON_FILE" = "null" ]; then
    echo "错误：配置文件格式错误或字段缺失"
    exit 1
fi

echo "配置信息："
echo "  App名称: $APP_NAME"
echo "  App URL: $APP_URL"
echo "  图标文件: $ICON_FILE"

# 检查图标文件是否存在
ICON_PATH="$SCRIPT_DIR/$ICON_FILE"
if [ ! -f "$ICON_PATH" ]; then
    echo "错误：图标文件 $ICON_PATH 不存在"
    exit 1
fi

# 1. 替换图标到各个mipmap文件夹
echo "正在替换应用图标..."
MIPMAP_DIRS=(
    "mipmap-hdpi"
    "mipmap-mdpi"
    "mipmap-xhdpi"
    "mipmap-xxhdpi"
    "mipmap-xxxhdpi"
)

for dir in "${MIPMAP_DIRS[@]}"; do
    TARGET_DIR="$PROJECT_DIR/app/src/main/res/$dir"
    TARGET_FILE="$TARGET_DIR/ic_launcher.png"
    
    if [ -d "$TARGET_DIR" ]; then
        echo "  替换 $dir/ic_launcher.png"
        cp "$ICON_PATH" "$TARGET_FILE"
    else
        echo "  警告：目录 $TARGET_DIR 不存在，跳过"
    fi
done

# 2. 修改MainActivity.java中的URL
echo "正在修改 MainActivity.java 中的 URL..."
MAINACTIVITY_FILE="$PROJECT_DIR/app/src/main/java/com/jsmiao/webapp/MainActivity.java"

if [ ! -f "$MAINACTIVITY_FILE" ]; then
    echo "错误：MainActivity.java 文件不存在"
    exit 1
fi

# 创建备份目录
BACKUP_DIR="$SCRIPT_DIR/backups"
mkdir -p "$BACKUP_DIR"

# 创建备份
cp "$MAINACTIVITY_FILE" "$BACKUP_DIR/MainActivity.java.backup"

# 使用Python替换URL（更可靠）
python3 -c "
import re
import sys

# 读取文件
with open('$MAINACTIVITY_FILE', 'r') as f:
    content = f.read()

# 替换URL，只替换未注释的行
pattern = r'^(\s*String url = \")[^\"]*(\"; // \d+)$'
replacement = r'\1$APP_URL\2'
content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

# 写回文件
with open('$MAINACTIVITY_FILE', 'w') as f:
    f.write(content)
"

echo "  URL 已更新为: $APP_URL"

# 3. 修改strings.xml中的App名称
echo "正在修改 strings.xml 中的 App 名称..."
STRINGS_FILE="$PROJECT_DIR/app/src/main/res/values/strings.xml"

if [ ! -f "$STRINGS_FILE" ]; then
    echo "错误：strings.xml 文件不存在"
    exit 1
fi

# 创建备份
cp "$STRINGS_FILE" "$BACKUP_DIR/strings.xml.backup"

# 使用sed替换App名称
sed -i.tmp "s|<string name=\"app_name\">[^<]*</string>|<string name=\"app_name\">$APP_NAME</string>|g" "$STRINGS_FILE"
rm -f "$STRINGS_FILE.tmp"

echo "  App 名称已更新为: $APP_NAME"

# 4. 清理之前的构建文件
echo "正在清理之前的构建文件..."
cd "$PROJECT_DIR"
./gradlew clean

# 5. 构建APK
echo ""
echo "🚀 开始构建APK..."
echo "这可能需要几分钟时间，请耐心等待..."
echo ""

# 构建Release版本
./gradlew assembleRelease

# 检查构建是否成功
if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 APK构建成功！"
    
    # 查找生成的APK文件
    APK_DIR="$PROJECT_DIR/app/build/outputs/apk/release"
    if [ -d "$APK_DIR" ]; then
        echo ""
        echo "📦 生成的APK文件位置："
        find "$APK_DIR" -name "*.apk" -type f | while read apk_file; do
            echo "  - $apk_file"
            # 显示文件大小
            size=$(du -h "$apk_file" | cut -f1)
            echo "    大小: $size"
        done
        
        # 复制APK到deploy目录
        latest_apk=$(find "$APK_DIR" -name "*.apk" -type f | head -1)
        if [ -n "$latest_apk" ]; then
            deploy_apk="$SCRIPT_DIR/app-release.apk"
            cp "$latest_apk" "$deploy_apk"
            echo ""
            echo "✅ APK已复制到: $deploy_apk"
            echo "🎯 可直接安装此APK文件"
        fi
    fi
    
    echo ""
    echo "🎊 全部完成！应用配置和构建都已完成。"
else
    echo ""
    echo "❌ APK构建失败！"
    echo "请检查构建错误信息，或手动运行 ./gradlew assembleRelease"
    exit 1
fi

echo ""
echo "📝 备份文件已保存到: $BACKUP_DIR" 
echo "  - MainActivity.java.backup"
echo "  - strings.xml.backup"
echo ""
echo "如需恢复，请运行: ./restore_backup.sh"