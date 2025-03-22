package com.jsmiao.webapp;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.content.pm.PackageInfoCompat;

import com.fm.openinstall.OpenInstall;
import com.fm.openinstall.listener.AppInstallAdapter;
import com.fm.openinstall.model.AppData;
import com.jsmiao.webapp.controls.MWebView;

import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.messaging.FirebaseMessaging;

import java.util.HashMap;
import java.util.Map;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = "MainActivity";

    private MWebView mWebView; // webView 控件
    private String bindData = ""; // 用于存储获取的安装参数

    // 声明权限请求启动器
    private final ActivityResultLauncher<String> requestPermissionLauncher =
            registerForActivityResult(new ActivityResultContracts.RequestPermission(), isGranted -> {
                if (isGranted) {
                    // FCM SDK可以发送通知
                    Toast.makeText(this, "Notification permission granted", Toast.LENGTH_SHORT).show();
                } else {
                    // 通知用户您的应用将不会显示通知
                    Toast.makeText(this, "Without notification permission, the app will not be able to display notifications", Toast.LENGTH_LONG).show();
                }
            });

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_main);
        // 设置页面全屏，隐藏状态栏
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);

        // 获取控件
        mWebView = (MWebView) findViewById(R.id.mWebView);
        mWebView.setActivity(this);

        String url = "https://888i.bet"; // 603
//        String url = "https://v2sky602h5.xbnapi.xyz/"; // 602
//        String url = "https://v2h5sky501.xbnapi.xyz"; // 501
//        String url = "https://v2h5sky501.xbnapi.xyz/?vconsole=true"; // 501 需要调试时使用

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

        // 请求通知权限
        askNotificationPermission();

        // 获取FCM令牌
        getFirebaseToken();
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

    /**
     * 获取Firebase消息传递令牌
     */
    private void getFirebaseToken() {
        FirebaseMessaging.getInstance().getToken()
                .addOnCompleteListener(new OnCompleteListener<String>() {
                    @Override
                    public void onComplete(@NonNull Task<String> task) {
                        if (!task.isSuccessful()) {
                            Log.w(TAG, "获取FCM注册令牌失败", task.getException());
                            return;
                        }

                        // 获取新的FCM注册令牌
                        String token = task.getResult();

                        // 记录并显示
                        String msg = getString(R.string.msg_token_fmt, token);
                        Log.d(TAG, msg);
                        // Toast.makeText(MainActivity.this, msg, Toast.LENGTH_SHORT).show();
                    }
                });
    }

    /**
     * 请求通知权限
     */
    private void askNotificationPermission() {
        // 这只对API级别>=33 (TIRAMISU)的设备是必要的
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) ==
                    android.content.pm.PackageManager.PERMISSION_GRANTED) {
                // FCM SDK可以发送通知
            } else if (shouldShowRequestPermissionRationale(android.Manifest.permission.POST_NOTIFICATIONS)) {
                // 你可以显示一个解释性UI，说明通知的好处
                // 如果用户点击"确定"，直接请求权限
                // 这里简单处理，直接请求权限
                requestPermissionLauncher.launch(android.Manifest.permission.POST_NOTIFICATIONS);
            } else {
                // 直接请求权限
                requestPermissionLauncher.launch(android.Manifest.permission.POST_NOTIFICATIONS);
            }
        }
    }
}