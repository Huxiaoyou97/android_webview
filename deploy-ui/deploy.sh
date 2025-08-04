#!/bin/bash

echo "🔧 部署应用..."

echo "0. 检查并恢复原始Java文件..."
# 检查原始Java文件是否存在，如果不存在则从备份恢复
JAVA_DIR="../app/src/main/java/com/jsmiao/webapp"
if [ ! -f "$JAVA_DIR/MainActivity.java" ]; then
    echo "  恢复原始Java文件..."
    mkdir -p "$JAVA_DIR/controls"
    
    # 从备份恢复MainActivity.java
    if [ -f "../deploy/backups/MainActivity.java.backup" ]; then
        cp "../deploy/backups/MainActivity.java.backup" "$JAVA_DIR/MainActivity.java"
        echo "  ✅ MainActivity.java 已恢复"
    fi
    
    # 创建MyApplication.java
    cat > "$JAVA_DIR/MyApplication.java" << 'EOF'
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
    
    # 创建MWebView.java
    cat > "$JAVA_DIR/controls/MWebView.java" << 'EOF'
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

    /**
     * 设置要选择图片的activity
     *
     * @param activity
     */
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

echo "1. 停止服务..."
docker-compose down

echo "2. 清理镜像..."
docker rmi deploy-ui-backend 2>/dev/null || echo "后端镜像已清理"

echo "3. 重新构建..."
docker-compose build --no-cache

echo "4. 启动服务..."
docker-compose up -d

echo "5. 等待服务启动..."
sleep 5

echo "6. 检查服务状态..."
docker-compose ps

echo "7. 检查后端日志..."
docker-compose logs --tail=20 backend

echo ""
echo "🎉 部署完成！"
echo "访问: http://你的服务器IP/"