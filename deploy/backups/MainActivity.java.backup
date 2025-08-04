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

    private MWebView mWebView; // webView 控件
    private static final int FILE_CHOOSER_RESULT_CODE = 1;
    private ValueCallback<Uri[]> filePathCallback;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_main);
        // 设置页面全屏，隐藏状态栏
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);

        // 获取控件
        mWebView = (MWebView) findViewById(R.id.mWebView);
        mWebView.setActivity(this);

        // 配置 WebView
        setupWebView();

        // String testUrl = "http://192.168.31.89:6002?web_app=1"; // 测试
        // String testUrl = "https://888i.bet?web_app=1"; // 603
        // String testUrl = "https://v2sky602h5.xbnapi.xyz?web_app=1"; // 602
        // String testUrl = "https://v2h5sky501.xbnapi.xyz?web_app=1"; // 501
        // String testUrl = "https://sky503v2-h5.xbnapi.xyz?web_app=1"; // 503
        // String testUrl = "https://v2h5sky501.xbnapi.xyz/?vconsole=true"; // 501
        // 需要调试时使用
        String url = "https://google.com"; // 605

        // 加载url
        mWebView.loadUrl(url);

        // 注入web_app标识
        injectParamsToLocalStorage();
    }

    @SuppressLint("SetJavaScriptEnabled")
    private void setupWebView() {
        // 启用 JavaScript
        mWebView.getSettings().setJavaScriptEnabled(true);

        // 设置 WebViewClient，处理 URL 跳转
        mWebView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                if (url.startsWith("http") || url.startsWith("https")) {
                    // 普通网页加载
                    return false;
                } else {
                    // 自定义协议处理
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
                // 页面加载完成后执行注入 JavaScript 的代码
                injectParamsToLocalStorage();
            }
        });

        // 设置 WebChromeClient 以便处理 JavaScript
        mWebView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onProgressChanged(WebView view, int newProgress) {
                super.onProgressChanged(view, newProgress);
            }

            // 处理文件选择
            @Override
            public boolean onShowFileChooser(WebView webView, ValueCallback<Uri[]> filePathCallback,
                    FileChooserParams fileChooserParams) {
                MainActivity.this.filePathCallback = filePathCallback;

                // 创建文件选择Intent
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
        // 存储web_app标识
        mWebView.evaluateJavascript("localStorage.setItem('web_app', '1');", null);
    }

    @Override
    public void onBackPressed() {
        if (mWebView.canGoBack()) {
            mWebView.goBack(); // 返回上一页
        } else {
            super.onBackPressed(); // 正常退出应用
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