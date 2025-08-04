#!/bin/bash

# 自动打包脚本 - Android WebApp (支持多域名)
# 使用方法：./auto_build.sh

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检测是否在Docker环境中
if [ -d "/app/workspace" ] && [ "$SCRIPT_DIR" = "/app" ]; then
    # Docker环境中的路径
    PROJECT_DIR="/app/workspace"
    SCRIPT_DIR="/app"
else
    # 本地环境中的路径
    PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

# !!!! 关键修复：确保原始Java文件存在 !!!!
echo "🔧 检查并恢复原始Java文件..."
ORIGINAL_JAVA_DIR="$PROJECT_DIR/app/src/main/java/com/jsmiao/webapp"

# 详细检查每个文件
echo "  检查文件状态:"
echo "    目录: $ORIGINAL_JAVA_DIR"
echo "    MainActivity.java: $([ -f "$ORIGINAL_JAVA_DIR/MainActivity.java" ] && echo "存在" || echo "缺失")"
echo "    MyApplication.java: $([ -f "$ORIGINAL_JAVA_DIR/MyApplication.java" ] && echo "存在" || echo "缺失")"  
echo "    MWebView.java: $([ -f "$ORIGINAL_JAVA_DIR/controls/MWebView.java" ] && echo "存在" || echo "缺失")"

# 强制检查 - 只要任何一个文件缺失就恢复
NEED_RESTORE=false
if [ ! -f "$ORIGINAL_JAVA_DIR/MainActivity.java" ]; then
    echo "    MainActivity.java 缺失，需要恢复"
    NEED_RESTORE=true
fi
if [ ! -f "$ORIGINAL_JAVA_DIR/MyApplication.java" ]; then
    echo "    MyApplication.java 缺失，需要恢复"  
    NEED_RESTORE=true
fi
if [ ! -f "$ORIGINAL_JAVA_DIR/controls/MWebView.java" ]; then
    echo "    MWebView.java 缺失，需要恢复"
    NEED_RESTORE=true
fi

if [ "$NEED_RESTORE" = "true" ]; then
    echo "  检测到Java文件缺失，正在恢复..."
    mkdir -p "$ORIGINAL_JAVA_DIR/controls"
    
    # 确定备份文件路径
    if [ -d "/app/workspace" ] && [ "$SCRIPT_DIR" = "/app" ]; then
        BACKUP_DIR="/app/workspace/deploy/backups"
    else
        BACKUP_DIR="$SCRIPT_DIR/backups"
    fi
    
    # 从备份恢复MainActivity.java
    if [ -f "$BACKUP_DIR/MainActivity.java.backup" ]; then
        cp "$BACKUP_DIR/MainActivity.java.backup" "$ORIGINAL_JAVA_DIR/MainActivity.java"
        echo "  ✅ MainActivity.java 已从备份恢复"
    else
        echo "  ❌ 备份文件不存在: $BACKUP_DIR/MainActivity.java.backup"
        echo "  正在创建默认的MainActivity.java..."
        cat > "$ORIGINAL_JAVA_DIR/MainActivity.java" << 'EOF'
package com.jsmiao.webapp;

import android.annotation.SuppressLint;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.WindowManager;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.jsmiao.webapp.controls.MWebView;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = "MainActivity";

    private MWebView mWebView;
    private static final int FILE_CHOOSER_RESULT_CODE = 1;
    private ValueCallback<Uri[]> filePathCallback;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_main);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);

        mWebView = (MWebView) findViewById(R.id.mWebView);
        mWebView.setActivity(this);

        setupWebView();

        String url = "https://www.google.com/";
        mWebView.loadUrl(url);
        injectParamsToLocalStorage();
    }

    @SuppressLint("SetJavaScriptEnabled")
    private void setupWebView() {
        mWebView.getSettings().setJavaScriptEnabled(true);

        mWebView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                if (url.startsWith("http") || url.startsWith("https")) {
                    return false;
                } else {
                    try {
                        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                        startActivity(intent);
                    } catch (Exception e) {
                        Toast.makeText(MainActivity.this, "无法打开该链接，请检查是否安装了相应的应用", Toast.LENGTH_SHORT).show();
                    }
                    return true;
                }
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                injectParamsToLocalStorage();
            }
        });

        mWebView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onProgressChanged(WebView view, int newProgress) {
                super.onProgressChanged(view, newProgress);
            }

            @Override
            public boolean onShowFileChooser(WebView webView, ValueCallback<Uri[]> filePathCallback,
                    FileChooserParams fileChooserParams) {
                MainActivity.this.filePathCallback = filePathCallback;

                Intent intent = fileChooserParams.createIntent();
                try {
                    startActivityForResult(intent, FILE_CHOOSER_RESULT_CODE);
                } catch (ActivityNotFoundException e) {
                    filePathCallback.onReceiveValue(null);
                    return false;
                }
                return true;
            }
        });
    }

    private void injectParamsToLocalStorage() {
        mWebView.evaluateJavascript("localStorage.setItem('web_app', '1');", null);
    }

    @Override
    public void onBackPressed() {
        if (mWebView.canGoBack()) {
            mWebView.goBack();
        } else {
            super.onBackPressed();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == FILE_CHOOSER_RESULT_CODE) {
            if (filePathCallback != null) {
                Uri[] results = null;

                if (resultCode == RESULT_OK && data != null) {
                    String dataString = data.getDataString();
                    if (dataString != null) {
                        results = new Uri[] { Uri.parse(dataString) };
                    }
                }

                filePathCallback.onReceiveValue(results);
                filePathCallback = null;
            }
        }
    }
}
EOF
    fi
    
    # 创建MyApplication.java
    if [ ! -f "$ORIGINAL_JAVA_DIR/MyApplication.java" ]; then
        cat > "$ORIGINAL_JAVA_DIR/MyApplication.java" << 'EOF'
package com.jsmiao.webapp;

import android.app.Application;

public class MyApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
    }
}
EOF
        echo "  ✅ MyApplication.java 已创建"
    fi
    
    # 创建MWebView.java
    if [ ! -f "$ORIGINAL_JAVA_DIR/controls/MWebView.java" ]; then
        cat > "$ORIGINAL_JAVA_DIR/controls/MWebView.java" << 'EOF'
package com.jsmiao.webapp.controls;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.os.Build;
import android.util.AttributeSet;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MWebView extends WebView {
    private Activity mActivity;

    public MWebView(Context context) {
        super(context);
        init();
    }

    public MWebView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public MWebView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    public void setActivity(Activity activity) {
        this.mActivity = activity;
    }

    @SuppressLint("SetJavaScriptEnabled")
    private void init() {
        WebSettings webSettings = getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setUseWideViewPort(true);
        webSettings.setLoadWithOverviewMode(true);
        webSettings.setCacheMode(WebSettings.LOAD_NO_CACHE);
        webSettings.setDomStorageEnabled(true);
        webSettings.setAllowFileAccess(true);
        webSettings.setAllowContentAccess(true);
        webSettings.setDefaultTextEncodingName("utf-8");
        webSettings.setAllowFileAccessFromFileURLs(false);
        webSettings.setAllowUniversalAccessFromFileURLs(false);
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            webSettings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
            WebView.setWebContentsDebuggingEnabled(true);
        }

        setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                if (url.startsWith("http:") || url.startsWith("https:")) {
                    return false;
                }
                return true;
            }

            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                super.onPageStarted(view, url, favicon);
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
            }
        });

        setWebChromeClient(new WebChromeClient() {
            @Override
            public void onProgressChanged(WebView view, int newProgress) {
                super.onProgressChanged(view, newProgress);
            }

            @Override
            public void onReceivedTitle(WebView view, String title) {
                super.onReceivedTitle(view, title);
            }
        });
    }
}
EOF
        echo "  ✅ MWebView.java 已创建"
    fi
    
    echo "  ✅ 所有原始Java文件已确保存在"
else
    echo "  ✅ 原始Java文件已存在，跳过恢复"
fi

# 清理之前构建的非原始包名目录
echo "🧹 清理之前构建的包名目录..."
JAVA_DIR="$PROJECT_DIR/app/src/main/java"
if [ -d "$JAVA_DIR" ]; then
    # 只删除非原始包名的Java文件，保留原始文件
    find "$JAVA_DIR" -type f -name "*.java" ! -path "*/com/jsmiao/webapp/*" -delete 2>/dev/null || true
    # 删除空目录
    find "$JAVA_DIR" -type d -empty -delete 2>/dev/null || true
fi

# 🔧 恢复activity_main.xml到原始状态
echo "🔧 恢复activity_main.xml到原始状态..."
ACTIVITY_MAIN_FILE="$PROJECT_DIR/app/src/main/res/layout/activity_main.xml"
if [ -f "$ACTIVITY_MAIN_FILE" ]; then
    # 检查是否包含非原始包名的MWebView引用
    if ! grep -q "com\.jsmiao\.webapp\.controls\.MWebView" "$ACTIVITY_MAIN_FILE"; then
        echo "  检测到activity_main.xml包含非原始包名引用，正在恢复..."
        # 恢复开始标签和结束标签的包名引用
        sed -i.tmp 's|<[^[:space:]>]*\.controls\.MWebView|<com.jsmiao.webapp.controls.MWebView|g; s|</[^[:space:]>]*\.controls\.MWebView|</com.jsmiao.webapp.controls.MWebView|g' "$ACTIVITY_MAIN_FILE"
        rm -f "$ACTIVITY_MAIN_FILE.tmp"
        echo "  ✅ activity_main.xml已恢复到原始状态"
    else
        echo "  ✅ activity_main.xml已是原始状态"
    fi
else
    echo "  ❌ activity_main.xml文件不存在"
fi

# 配置文件路径
if [ -d "/app/workspace" ] && [ "$SCRIPT_DIR" = "/app" ]; then
    # Docker环境中的路径
    CONFIG_FILE="/app/workspace/deploy/config.json"
    DOMAIN_MANAGER="/app/domain_manager.py"
    SIMPLE_DOMAIN_MANAGER="/app/simple_domain_manager.py"
    DOMAIN_CONFIGS_FILE="/app/domain_configs.json"
else
    # 本地环境中的路径  
    CONFIG_FILE="$SCRIPT_DIR/config.json"
    DOMAIN_MANAGER="$SCRIPT_DIR/domain_manager.py"
    SIMPLE_DOMAIN_MANAGER="$SCRIPT_DIR/simple_domain_manager.py"
    DOMAIN_CONFIGS_FILE="$SCRIPT_DIR/domain_configs.json"
fi

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
if [ -f "$SIMPLE_DOMAIN_MANAGER" ]; then
    # 只捕获stdout，忽略stderr
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
        if [ ! -f "$DOMAIN_CONFIGS_FILE" ] || [ ! -s "$DOMAIN_CONFIGS_FILE" ]; then
            echo "{}" > "$DOMAIN_CONFIGS_FILE"
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
# app.namespace=$PACKAGE_NAME
keystore.storeFile=$KEYSTORE_PATH
keystore.storePassword=$KEYSTORE_PASSWORD
keystore.alias=$KEY_ALIAS
keystore.keyPassword=$KEY_PASSWORD
EOF

echo "✅ 动态配置文件已创建: $DYNAMIC_CONFIG"
echo "签名文件路径: $KEYSTORE_PATH"

# 检查图标文件是否存在
if [ -d "/app/workspace" ] && [ "$SCRIPT_DIR" = "/app" ]; then
    ICON_PATH="/app/workspace/deploy/$ICON_FILE"
else
    ICON_PATH="$SCRIPT_DIR/$ICON_FILE"
fi

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
if [ -d "/app/workspace" ] && [ "$SCRIPT_DIR" = "/app" ]; then
    BACKUP_DIR="/app/workspace/deploy/backups"
else
    BACKUP_DIR="$SCRIPT_DIR/backups"
fi
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
    
    # 检查源文件是否存在
    echo "  检查源文件: $MAINACTIVITY_DIR/MainActivity.java"
    if [ ! -f "$MAINACTIVITY_DIR/MainActivity.java" ]; then
        echo "错误：源文件 MainActivity.java 不存在: $MAINACTIVITY_DIR/MainActivity.java"
        echo "尝试列出目录内容:"
        ls -la "$MAINACTIVITY_DIR/" 2>/dev/null || echo "目录不存在"
        ls -la "$PROJECT_DIR/app/src/main/java/" 2>/dev/null || echo "java目录不存在"
        find "$PROJECT_DIR/app/src/main/java/" -name "*.java" -type f 2>/dev/null || echo "未找到java文件"
        exit 1
    fi
    
    # 创建新的包名目录
    mkdir -p "$NEW_PACKAGE_DIR/controls"
    
    # 安全地复制文件（而不是移动），保持原始文件不变
    echo "  复制文件到新包名目录..."
    
    if [ -f "$MAINACTIVITY_DIR/MainActivity.java" ]; then
        cp "$MAINACTIVITY_DIR/MainActivity.java" "$NEW_PACKAGE_DIR/MainActivity.java" || {
            echo "错误：无法复制 MainActivity.java"
            exit 1
        }
        echo "    ✅ MainActivity.java 已复制"
    fi
    
    if [ -f "$MAINACTIVITY_DIR/MyApplication.java" ]; then
        cp "$MAINACTIVITY_DIR/MyApplication.java" "$NEW_PACKAGE_DIR/MyApplication.java" || {
            echo "错误：无法复制 MyApplication.java"
            exit 1
        }
        echo "    ✅ MyApplication.java 已复制"
    fi
    
    if [ -f "$MAINACTIVITY_DIR/controls/MWebView.java" ]; then
        cp "$MAINACTIVITY_DIR/controls/MWebView.java" "$NEW_PACKAGE_DIR/controls/MWebView.java" || {
            echo "错误：无法复制 MWebView.java"
            exit 1
        }
        echo "    ✅ MWebView.java 已复制"
    fi
    
    echo "  ✅ 文件已复制到新包名目录"
    
    # 更新所有Java文件的路径（指向新目录）
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

# 替换包名声明（只有包名不同时才替换）
if '$PACKAGE_NAME' != 'com.jsmiao.webapp':
    content = re.sub(r'^package\s+[^;]+;', 'package $PACKAGE_NAME;', content, flags=re.MULTILINE)
    # 添加R类的正确import
    # 先删除任何已存在的R类import
    content = re.sub(r'import\s+[^;]*\.R;\s*\n', '', content, flags=re.MULTILINE)
    # 在androidx.appcompat.app.AppCompatActivity后添加R类import
    content = re.sub(r'(import androidx\.appcompat\.app\.AppCompatActivity;\s*\n)', r'\1import com.jsmiao.webapp.R;\n', content)

# 替换导入语句中的包名（只有包名不同时才替换）
if '$PACKAGE_NAME' != 'com.jsmiao.webapp':
    content = re.sub(r'import\s+com\.jsmiao\.webapp\.controls', 'import $PACKAGE_NAME.controls', content, flags=re.MULTILINE)

# 替换URL
pattern = r'^(\s*String url = \")[^\"]*(\";).*$'
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

# 3.5. 修改activity_main.xml中的MWebView包名引用
echo "正在修改 activity_main.xml 中的包名引用..."
ACTIVITY_MAIN_FILE="$PROJECT_DIR/app/src/main/res/layout/activity_main.xml"

if [ -f "$ACTIVITY_MAIN_FILE" ]; then
    # 创建备份
    cp "$ACTIVITY_MAIN_FILE" "$BACKUP_DIR/activity_main.xml.backup"
    
    # 替换MWebView的包名引用
    if [ "$PACKAGE_NAME" != "com.jsmiao.webapp" ]; then
        sed -i.tmp "s|com.jsmiao.webapp.controls.MWebView|$PACKAGE_NAME.controls.MWebView|g" "$ACTIVITY_MAIN_FILE"
        rm -f "$ACTIVITY_MAIN_FILE.tmp"
        echo "  activity_main.xml 中的包名引用已更新"
    fi
else
    echo "  警告：activity_main.xml 文件不存在"
fi

# 4. 清理之前的构建文件
echo "正在清理之前的构建文件..."
cd "$PROJECT_DIR"
# 删除deploy目录下的旧APK文件
rm -f "$SCRIPT_DIR"/*-app.apk 2>/dev/null || true
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