#!/bin/bash

# 恢复备份脚本 - Android WebApp
# 使用方法：./restore_backup.sh

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups"

# 文件路径
MAINACTIVITY_FILE="$PROJECT_DIR/app/src/main/java/com/jsmiao/webapp/MainActivity.java"
STRINGS_FILE="$PROJECT_DIR/app/src/main/res/values/strings.xml"
ACTIVITY_MAIN_FILE="$PROJECT_DIR/app/src/main/res/layout/activity_main.xml"

echo "正在恢复备份文件..."

# 恢复MainActivity.java
if [ -f "$BACKUP_DIR/MainActivity.java.backup" ]; then
    cp "$BACKUP_DIR/MainActivity.java.backup" "$MAINACTIVITY_FILE"
    echo "✅ MainActivity.java 已恢复"
else
    echo "❌ MainActivity.java 备份文件不存在"
fi

# 恢复strings.xml
if [ -f "$BACKUP_DIR/strings.xml.backup" ]; then
    cp "$BACKUP_DIR/strings.xml.backup" "$STRINGS_FILE"
    echo "✅ strings.xml 已恢复"
else
    echo "❌ strings.xml 备份文件不存在"
fi

# 恢复activity_main.xml
if [ -f "$BACKUP_DIR/activity_main.xml.backup" ]; then
    cp "$BACKUP_DIR/activity_main.xml.backup" "$ACTIVITY_MAIN_FILE"
    echo "✅ activity_main.xml 已恢复"
else
    echo "❌ activity_main.xml 备份文件不存在"
fi

echo ""
echo "🎉 备份恢复完成！"