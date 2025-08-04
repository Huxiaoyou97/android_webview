#!/bin/bash

# 自动打包脚本 - Android WebApp (支持多域名)
# 使用方法：./auto_build.sh

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 清理之前构建的非原始包名目录
echo "🧹 清理之前构建的包名目录..."
JAVA_DIR="$PROJECT_DIR/app/src/main/java"
if [ -d "$JAVA_DIR" ]; then
    find "$JAVA_DIR" -type d -path "*/com/*" ! -path "*/com/jsmiao/webapp*" -exec rm -rf {} + 2>/dev/null || true
fi

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

# 尝试使用简化版域名管理器
SIMPLE_DOMAIN_MANAGER="$SCRIPT_DIR/simple_domain_manager.py"
if [ -f "$SIMPLE_DOMAIN_MANAGER" ]; then
    DOMAIN_CONFIG=$(python3 "$SIMPLE_DOMAIN_MANAGER" get "$APP_URL" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$DOMAIN_CONFIG" ]; then
        echo "✅ 使用简化版域名管理器获取配置成功"
    else
        echo "❌ 简化版域名管理器也失败，使用默认配置"
        DOMAIN_CONFIG=""
    fi
else
    # 回退到原始域名管理器
    DOMAIN_CONFIG=$(python3 "$DOMAIN_MANAGER" get "$APP_URL" 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$DOMAIN_CONFIG" ]; then
        echo "❌ 获取域名配置失败，尝试重新初始化..."
        
        # 确保domain_configs.json文件存在且格式正确
        if [ ! -f "$SCRIPT_DIR/domain_configs.json" ] || [ ! -s "$SCRIPT_DIR/domain_configs.json" ]; then
            echo "{}" > "$SCRIPT_DIR/domain_configs.json"
            echo "✅ 已初始化domain_configs.json文件"
        fi
        
        # 重新尝试获取配置
        DOMAIN_CONFIG=$(python3 "$DOMAIN_MANAGER" get "$APP_URL" 2>/dev/null)
        if [ $? -ne 0 ] || [ -z "$DOMAIN_CONFIG" ]; then
            echo "❌ 仍然无法获取域名配置，使用默认配置"
            DOMAIN_CONFIG=""
        else
            echo "✅ 重新获取域名配置成功"
        fi
    else
        echo "✅ 获取域名配置成功"
    fi
fi

# 只有在成功获取配置时才解析
if [ -n "$DOMAIN_CONFIG" ] && [ "$DOMAIN_CONFIG" != "" ]; then
    echo "🔍 解析域名配置..."
    echo "配置内容: $DOMAIN_CONFIG"
    
    # 解析域名配置
    DOMAIN=$(echo "$DOMAIN_CONFIG" | python3 -c "import json, sys; config=json.load(sys.stdin); print(config['domain'])" 2>/dev/null)
    PACKAGE_NAME=$(echo "$DOMAIN_CONFIG" | python3 -c "import json, sys; config=json.load(sys.stdin); print(config['package_name'])" 2>/dev/null)
    KEYSTORE_PATH=$(echo "$DOMAIN_CONFIG" | python3 -c "import json, sys; config=json.load(sys.stdin); print(config['keystore_path'])" 2>/dev/null)
    KEYSTORE_PASSWORD=$(echo "$DOMAIN_CONFIG" | python3 -c "import json, sys; config=json.load(sys.stdin); print(config['keystore_password'])" 2>/dev/null)
    KEY_ALIAS=$(echo "$DOMAIN_CONFIG" | python3 -c "import json, sys; config=json.load(sys.stdin); print(config['key_alias'])" 2>/dev/null)
    KEY_PASSWORD=$(echo "$DOMAIN_CONFIG" | python3 -c "import json, sys; config=json.load(sys.stdin); print(config['key_password'])" 2>/dev/null)
    
    echo "解析结果："
    echo "  域名: '$DOMAIN'"
    echo "  包名: '$PACKAGE_NAME'"  
    echo "  签名文件: '$KEYSTORE_PATH'"
    
    # 在Docker环境中，需要转换路径格式
    if [ -n "$KEYSTORE_PATH" ]; then
        KEYSTORE_RELATIVE_PATH=$(basename "$KEYSTORE_PATH")
        if [[ "$KEYSTORE_PATH" == *"/deploy/keystores/"* ]]; then
            # 在Docker环境中使用相对路径
            KEYSTORE_PATH="keystores/$KEYSTORE_RELATIVE_PATH"
            echo "  转换后路径: '$KEYSTORE_PATH'"
        fi
    fi
else
    echo "❌ 域名配置为空，使用默认配置"
    # 使用默认配置
    DOMAIN="default"
    PACKAGE_NAME="com.jsmiao.webapp"
    KEYSTORE_PATH="../bluetooth.jks"
    KEYSTORE_PASSWORD="Appsdotapps"
    KEY_ALIAS="bluetooth"
    KEY_PASSWORD="Appsdotapps"
fi

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

# 确保签名文件路径不为空
if [ -z "$KEYSTORE_PATH" ] || [ "$KEYSTORE_PATH" = "null" ]; then
    echo "❌ 错误：签名文件路径为空"
    exit 1
fi

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
echo "签名文件路径: $KEYSTORE_PATH"

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

# 创建备份目录
BACKUP_DIR="$SCRIPT_DIR/backups"
mkdir -p "$BACKUP_DIR"

# 先创建所有文件的备份
if [ -f "$MAINACTIVITY_FILE" ]; then
    cp "$MAINACTIVITY_FILE" "$BACKUP_DIR/MainActivity.java.backup"
fi
if [ -f "$MAINACTIVITY_DIR/MyApplication.java" ]; then
    cp "$MAINACTIVITY_DIR/MyApplication.java" "$BACKUP_DIR/MyApplication.java.backup"
fi
if [ -f "$MAINACTIVITY_DIR/controls/MWebView.java" ]; then
    cp "$MAINACTIVITY_DIR/controls/MWebView.java" "$BACKUP_DIR/MWebView.java.backup"
fi
if [ -f "$ANDROIDMANIFEST_FILE" ]; then
    cp "$ANDROIDMANIFEST_FILE" "$BACKUP_DIR/AndroidManifest.xml.backup"
fi

# 如果包名发生变化，需要删除旧目录的文件
NEW_PACKAGE_DIR="$PROJECT_DIR/app/src/main/java/$(echo $PACKAGE_NAME | tr '.' '/')"

if [ "$PACKAGE_NAME" != "com.jsmiao.webapp" ]; then
    echo "  包名已变更，重新组织目录结构..."
    echo "  新包名目录: $NEW_PACKAGE_DIR"
    
    # 先保存原始文件
    TEMP_DIR="/tmp/android_webview_temp_$$"
    mkdir -p "$TEMP_DIR/controls"
    cp "$MAINACTIVITY_DIR/MainActivity.java" "$TEMP_DIR/" 2>/dev/null || true
    cp "$MAINACTIVITY_DIR/MyApplication.java" "$TEMP_DIR/" 2>/dev/null || true
    cp "$MAINACTIVITY_DIR/controls/MWebView.java" "$TEMP_DIR/controls/" 2>/dev/null || true
    
    # 创建新的包名目录
    mkdir -p "$NEW_PACKAGE_DIR/controls"
    
    # 从临时目录复制文件到新目录
    cp "$TEMP_DIR/MainActivity.java" "$NEW_PACKAGE_DIR/"
    cp "$TEMP_DIR/MyApplication.java" "$NEW_PACKAGE_DIR/"
    cp "$TEMP_DIR/controls/MWebView.java" "$NEW_PACKAGE_DIR/controls/"
    
    # 删除旧目录，避免编译时使用错误的文件
    echo "  删除旧目录..."
    rm -rf "$MAINACTIVITY_DIR"
    
    # 清理临时目录
    rm -rf "$TEMP_DIR"
    
    echo "  ✅ 文件已移动到新包名目录，旧目录已删除"
    
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

# 使用Python替换MainActivity.java中的URL和包名
python3 -c "
import re
import sys

# 读取文件
with open('$MAINACTIVITY_FILE', 'r') as f:
    content = f.read()

# 替换包名声明
content = re.sub(r'^package\s+[^;]+;', 'package $PACKAGE_NAME;', content, flags=re.MULTILINE)

# 添加或更新R类的import语句
# 删除旧的R import（如果存在）
content = re.sub(r'import\s+[^;]*\.R;\s*\n', '', content, flags=re.MULTILINE)

# 在其他import语句之后添加新的R import
import_section = re.search(r'(import\s+[^;]+;\s*\n)+', content, flags=re.MULTILINE)
if import_section:
    # 在最后一个import后添加R import
    last_import_end = import_section.end()
    content = content[:last_import_end] + f'import $PACKAGE_NAME.R;\n' + content[last_import_end:]
else:
    # 如果没有import语句，在package声明后添加
    content = re.sub(r'(package\s+[^;]+;\s*\n)', r'\1\nimport $PACKAGE_NAME.R;\n', content, flags=re.MULTILINE)

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