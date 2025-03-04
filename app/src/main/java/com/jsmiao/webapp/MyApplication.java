package com.jsmiao.webapp;

import android.app.Application;

import com.fm.openinstall.OpenInstall;

public class MyApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();

        // 预初始化：不会采集设备信息
        OpenInstall.preInit(this);

        // 初始化时：采集设备信息并上报数据
        OpenInstall.init(this);

        // 如果你不想读取剪切板数据，可以禁用它
        OpenInstall.clipBoardEnabled(false);  // false 为不读取剪切板数据
    }
}