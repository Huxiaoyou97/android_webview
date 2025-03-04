package com.jsmiao.webapp;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.WindowManager;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.fm.openinstall.OpenInstall;
import com.fm.openinstall.listener.AppInstallAdapter;
import com.fm.openinstall.model.AppData;
import com.jsmiao.webapp.controls.MWebView;

import java.util.HashMap;
import java.util.Map;

public class MainActivity extends AppCompatActivity {
    private MWebView mWebView; // webView 控件
    private String bindData = ""; // 用于存储获取的安装参数

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_main);
        // 设置页面全屏，隐藏状态栏
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);

        // 获取控件
        mWebView = (MWebView) findViewById(R.id.mWebView);
        mWebView.setActivity(this);

//        String url = "https://v2sky602h5.xbnapi.xyz/?sdmode=2"; // 你要加载的 URL
        String url = "https://v2h5sky501.xbnapi.xyz/?sdmode=2"; // 你要加载的 URL
//        String url = "https://v2h5sky501.xbnapi.xyz/?vconsole=true"; // 你要加载的 URL

        // 配置 WebView
        setupWebView();

        // 加载url
        mWebView.loadUrl(url);

        // 获取安装参数
        OpenInstall.getInstall(new AppInstallAdapter() {
            @Override
            public void onInstall(AppData appData) {
                if (appData != null) {
                    // 获取需要的参数
                    String channelCode = appData.getChannel();
                    bindData = appData.getData(); // 获取安装时传递的参数

                    // 将参数存储到 H5 的 localStorage 中
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            // 页面加载完成后注入参数
                            injectParamsToLocalStorage();
                        }
                    });
                }
            }
        });
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
                if (!bindData.isEmpty()) {
                    injectParamsToLocalStorage();
                }
            }
        });

        // 设置 WebChromeClient 以便处理 JavaScript
        mWebView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onProgressChanged(WebView view, int newProgress) {
                super.onProgressChanged(view, newProgress);
            }
        });
    }

    private void injectParamsToLocalStorage() {
        // 如果 bindData 存在，则提取并存储到 localStorage
        if (bindData != null && !bindData.isEmpty()) {

            // 将参数存储到 H5 的 localStorage 中
            String jsCode =
                    "localStorage.setItem('web_app', '1');" +
                    "localStorage.setItem('app_bindData', '" + bindData + "');";

            // 注入 JavaScript
            mWebView.evaluateJavascript(jsCode, null);
        }
    }

    private Map<String, String> parseUrlParams(String url) {
        Map<String, String> params = new HashMap<>();
        if (url == null || url.isEmpty()) {
            return params;
        }

        String[] urlParts = url.split("[&?]");
        for (String part : urlParts) {
            String[] param = part.split("=");
            if (param.length == 2) {
                params.put(param[0], param[1]);
            }
        }

        return params;
    }

    /*
     * 接管返回键
     */
    @Override
    public void onBackPressed() {
        if (mWebView.canGoBack()) {
            mWebView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}