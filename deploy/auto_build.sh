#!/bin/bash

# 自动打包脚本 - Android WebApp (支持多域名)
# 使用方法：./auto_build.sh

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 配置文件路径
CONFIG_FILE="$SCRIPT_DIR/config.json"
DOMAIN_MANAGER="$SCRIPT_DIR/domain_manager.py"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误：配置文件 $CONFIG_FILE 不存在"
    exit 1
fi

# 检查域名管理器是否存在
if [ ! -f "$DOMAIN_MANAGER" ]; then
    echo "错误：域名管理器 $DOMAIN_MANAGER 不存在"
    exit 1
fi

# 读取配置文件（使用Python解析JSON）
echo "正在读取配置文件..."
APP_NAME=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['app_name'])")
APP_URL=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['app_url'])")
ICON_FILE=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['icon_file'])")

# 验证配置
if [ "$APP_NAME" = "null" ] || [ "$APP_URL" = "null" ] || [ "$ICON_FILE" = "null" ]; then
    echo "错误：配置文件格式错误或字段缺失"
    exit 1
fi

echo "配置信息："
echo "  App名称: $APP_NAME"
echo "  App URL: $APP_URL"
echo "  图标文件: $ICON_FILE"

# 获取域名配置
echo ""
echo "🔧 获取域名配置..."
DOMAIN_CONFIG=$(python3 "$DOMAIN_MANAGER" get "$APP_URL")
if [ $? -ne 0 ]; then
    echo "❌ 获取域名配置失败"
    exit 1
fi

# 解析域名配置
DOMAIN=$(echo "$DOMAIN_CONFIG" | python3 -c "import json, sys; config=json.load(sys.stdin); print(config['domain'])")
PACKAGE_NAME=$(echo "$DOMAIN_CONFIG" | python3 -c "import json, sys; config=json.load(sys.stdin); print(config['package_name'])")
KEYSTORE_PATH=$(echo "$DOMAIN_CONFIG" | python3 -c "import json, sys; config=json.load(sys.stdin); print(config['keystore_path'])")
KEYSTORE_PASSWORD=$(echo "$DOMAIN_CONFIG" | python3 -c "import json, sys; config=json.load(sys.stdin); print(config['keystore_password'])")
KEY_ALIAS=$(echo "$DOMAIN_CONFIG" | python3 -c "import json, sys; config=json.load(sys.stdin); print(config['key_alias'])")
KEY_PASSWORD=$(echo "$DOMAIN_CONFIG" | python3 -c "import json, sys; config=json.load(sys.stdin); print(config['key_password'])")

echo ""
echo "域名配置信息："
echo "  域名: $DOMAIN"
echo "  包名: $PACKAGE_NAME"
echo "  签名文件: $KEYSTORE_PATH"
echo "  密钥别名: $KEY_ALIAS"

# 创建动态配置文件
echo ""
echo "📝 创建动态配置文件..."
DYNAMIC_CONFIG="$PROJECT_DIR/dynamic.properties"
cat > "$DYNAMIC_CONFIG" << EOF
# 动态配置文件 - 由 auto_build.sh 自动生成
app.domainName=$DOMAIN
app.packageName=$PACKAGE_NAME
app.namespace=$PACKAGE_NAME
keystore.storeFile=$KEYSTORE_PATH
keystore.storePassword=$KEYSTORE_PASSWORD
keystore.alias=$KEY_ALIAS
keystore.keyPassword=$KEY_PASSWORD
EOF

echo "✅ 动态配置文件已创建: $DYNAMIC_CONFIG"

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

# 2. 修改MainActivity.java中的URL和包名，以及AndroidManifest.xml
echo "正在修改 MainActivity.java 中的 URL 和包名..."
MAINACTIVITY_DIR="$PROJECT_DIR/app/src/main/java/com/jsmiao/webapp"
MAINACTIVITY_FILE="$MAINACTIVITY_DIR/MainActivity.java"
ANDROIDMANIFEST_FILE="$PROJECT_DIR/app/src/main/AndroidManifest.xml"

# 如果包名发生变化，需要重新组织目录结构
NEW_PACKAGE_DIR="$PROJECT_DIR/app/src/main/java/$(echo $PACKAGE_NAME | tr '.' '/')"

if [ "$PACKAGE_NAME" != "com.jsmiao.webapp" ]; then
    echo "  包名已变更，重新组织目录结构..."
    echo "  新包名目录: $NEW_PACKAGE_DIR"
    
    # 创建新的包名目录
    mkdir -p "$NEW_PACKAGE_DIR"
    
    # 复制文件到新目录
    if [ -d "$MAINACTIVITY_DIR" ]; then
        cp -r "$MAINACTIVITY_DIR"/* "$NEW_PACKAGE_DIR/"
        echo "  ✅ 文件已复制到新包名目录"
    fi
    
    # 更新所有Java文件的路径
    MAINACTIVITY_FILE="$NEW_PACKAGE_DIR/MainActivity.java"
    MYAPPLICATION_FILE="$NEW_PACKAGE_DIR/MyApplication.java"
    MWEBVIEW_FILE="$NEW_PACKAGE_DIR/controls/MWebView.java"
else
    MYAPPLICATION_FILE="$MAINACTIVITY_DIR/MyApplication.java"
    MWEBVIEW_FILE="$MAINACTIVITY_DIR/controls/MWebView.java"
fi

if [ ! -f "$MAINACTIVITY_FILE" ]; then
    echo "错误：MainActivity.java 文件不存在: $MAINACTIVITY_FILE"
    exit 1
fi

if [ ! -f "$ANDROIDMANIFEST_FILE" ]; then
    echo "错误：AndroidManifest.xml 文件不存在: $ANDROIDMANIFEST_FILE"
    exit 1
fi

# 创建备份目录
BACKUP_DIR="$SCRIPT_DIR/backups"
mkdir -p "$BACKUP_DIR"

# 创建备份
cp "$MAINACTIVITY_FILE" "$BACKUP_DIR/MainActivity.java.backup"
cp "$ANDROIDMANIFEST_FILE" "$BACKUP_DIR/AndroidManifest.xml.backup"

# 使用Python替换MainActivity.java中的URL和包名
python3 -c "
import re
import sys

# 读取文件
with open('$MAINACTIVITY_FILE', 'r') as f:
    content = f.read()

# 替换包名声明
content = re.sub(r'^package\s+[^;]+;', 'package $PACKAGE_NAME;', content, flags=re.MULTILINE)

# 替换导入语句中的包名
content = re.sub(r'import\s+com\.jsmiao\.webapp\.', 'import $PACKAGE_NAME.', content, flags=re.MULTILINE)

# 替换URL，只替换未注释的行
pattern = r'^(\s*String url = \")[^\"]*(\"; // \d+)$'
replacement = r'\1$APP_URL\2'
content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

# 写回文件
with open('$MAINACTIVITY_FILE', 'w') as f:
    f.write(content)
"

# 更新其他Java文件的包名
if [ "$PACKAGE_NAME" != "com.jsmiao.webapp" ]; then
    echo "  更新其他Java文件的包名..."
    
    # 更新MyApplication.java
    if [ -f "$MYAPPLICATION_FILE" ]; then
        python3 -c "
import re
with open('$MYAPPLICATION_FILE', 'r') as f:
    content = f.read()
content = re.sub(r'^package\s+[^;]+;', 'package $PACKAGE_NAME;', content, flags=re.MULTILINE)
content = re.sub(r'import\s+com\.jsmiao\.webapp\.', 'import $PACKAGE_NAME.', content, flags=re.MULTILINE)
with open('$MYAPPLICATION_FILE', 'w') as f:
    f.write(content)
"
    fi
    
    # 更新MWebView.java
    if [ -f "$MWEBVIEW_FILE" ]; then
        python3 -c "
import re
with open('$MWEBVIEW_FILE', 'r') as f:
    content = f.read()
content = re.sub(r'^package\s+[^;]+;', 'package $PACKAGE_NAME.controls;', content, flags=re.MULTILINE)
content = re.sub(r'import\s+com\.jsmiao\.webapp\.', 'import $PACKAGE_NAME.', content, flags=re.MULTILINE)
with open('$MWEBVIEW_FILE', 'w') as f:
    f.write(content)
"
    fi
fi

# 使用Python替换AndroidManifest.xml中的包名引用（如果包名变化）
if [ "$PACKAGE_NAME" != "com.jsmiao.webapp" ]; then
    echo "  更新AndroidManifest.xml中的包名引用..."
    python3 -c "
import re
import sys

# 读取文件
with open('$ANDROIDMANIFEST_FILE', 'r') as f:
    content = f.read()

# 替换activity name引用，从相对路径改为绝对路径
content = re.sub(r'android:name=\"\.MainActivity\"', 'android:name=\"$PACKAGE_NAME.MainActivity\"', content)
content = re.sub(r'android:name=\"\.MyApplication\"', 'android:name=\"$PACKAGE_NAME.MyApplication\"', content) 

# 写回文件
with open('$ANDROIDMANIFEST_FILE', 'w') as f:
    f.write(content)
"
fi

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
        
        # 复制APK到deploy目录 (使用域名命名)
        latest_apk=$(find "$APK_DIR" -name "*-app.apk" -type f | head -1)
        if [ -n "$latest_apk" ]; then
            deploy_apk="$SCRIPT_DIR/${DOMAIN}-app.apk"
            cp "$latest_apk" "$deploy_apk"
            echo ""
            echo "✅ APK已复制到: $deploy_apk"
            echo "🎯 可直接安装此APK文件"
            echo "📱 包名: $PACKAGE_NAME"
            echo "🌐 域名: $DOMAIN"
        fi
    fi
    
    echo ""
    echo "🎊 全部完成！域名 $DOMAIN 的应用配置和构建都已完成。"
    echo "📦 包名: $PACKAGE_NAME"
    echo "🔐 签名: $KEYSTORE_PATH"
else
    echo ""
    echo "❌ APK构建失败！"
    echo "请检查构建错误信息，或手动运行 ./gradlew assembleRelease"
    exit 1
fi

# 清理动态配置文件
if [ -f "$DYNAMIC_CONFIG" ]; then
    rm -f "$DYNAMIC_CONFIG"
    echo "🧹 已清理临时配置文件"
fi

echo ""
echo "📝 备份文件已保存到: $BACKUP_DIR" 
echo "  - MainActivity.java.backup"
echo "  - strings.xml.backup"
echo ""
echo "如需恢复，请运行: ./restore_backup.sh"