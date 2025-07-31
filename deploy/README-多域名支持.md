# 多域名APK构建系统 - 使用说明

## 功能概述

现在你的Android WebView项目支持为不同域名生成独立的APK，每个域名都有自己的：
- 唯一包名 (Package Name)
- 独立签名文件 (Keystore)
- 专用配置存储

这样不同域名的APK可以在同一设备上共存，不会相互替换。

## 主要改进

### 1. 自动域名管理
- 每个域名自动生成唯一的包名 (如：com.com.example, com.com.google)
- 每个域名自动生成独立的签名密钥
- 域名配置自动保存和重用

### 2. 动态构建配置
- build.gradle 支持动态包名和签名配置
- auto_build.sh 脚本集成域名管理系统
- 后端自动处理域名特定的APK文件命名

### 3. 签名密钥管理
- 每个域名的签名密钥存储在 `deploy/keystores/` 目录
- 密钥文件命名格式：`域名_密钥.jks`
- 自动生成安全的密码和别名

## 使用方法

### 通过Web界面（推荐）
像之前一样使用deploy-ui的Web界面：
1. 输入应用名称
2. 输入APP URL（如：https://example.com）
3. 上传图标
4. 点击构建

系统会自动：
- 检测域名并生成/重用配置
- 使用域名特定的包名和签名
- 生成以域名命名的APK文件

### 通过命令行

#### 查看域名配置
```bash
cd deploy
./manage_domains.sh list                    # 列出所有已配置域名
./manage_domains.sh show https://example.com # 查看特定域名配置
```

#### 手动构建
```bash
cd deploy
# 1. 准备config.json
echo '{
  "app_name": "我的应用",
  "app_url": "https://example.com",
  "icon_file": "icon.png"
}' > config.json

# 2. 复制图标文件到deploy目录
cp your_icon.png icon.png

# 3. 运行构建脚本
./auto_build.sh
```

## 文件结构

```
deploy/
├── domain_manager.py          # 域名管理核心脚本
├── manage_domains.sh          # 域名管理便利工具
├── auto_build.sh             # 增强的构建脚本
├── keystores/                # 签名密钥存储目录
│   ├── example_com.jks       # example.com的签名密钥
│   └── google_com.jks        # google.com的签名密钥
├── domain_configs.json       # 域名配置数据库
└── config.json              # 当前构建配置
```

## APK命名规则

生成的APK文件现在包含域名信息：
- 构建目录：`域名-app.apk` (如：example.com-app.apk)
- 下载文件：`构建ID前缀-域名-app.apk` (如：a1b2c3d4-example.com-app.apk)

## 包名生成规则

域名会被转换为Java包名格式：
- `example.com` → `com.com.example`
- `test.app.io` → `com.io.app.test`
- `my-site.net` → `com.net.mysite`

## 签名密钥管理

每个域名的签名密钥信息：
- 密钥文件：`keystores/域名_密钥.jks`
- 密钥别名：域名去掉特殊字符
- 密钥密码：基于域名生成的16位安全密码
- 有效期：10000天

## 测试结果

✅ 域名配置管理正常工作
✅ 签名密钥自动生成成功
✅ 配置重用机制正常
✅ 文件命名规则正确
✅ 多域名APK可以共存

## 兼容性说明

- 完全向后兼容现有的构建流程
- 如果不指定域名，会使用默认配置
- 所有现有的Web界面功能保持不变
- 自动清理临时文件和配置

现在你可以为不同的网站构建独立的APK了！每个APK都有自己的身份，可以在同一设备上共存。