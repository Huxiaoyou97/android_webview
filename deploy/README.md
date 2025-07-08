# Android WebApp 自动打包脚本

这是一个用于自动配置和打包Android WebApp的脚本套件。

## 文件说明

- `config.json` - 配置文件，包含App名称、URL和图标文件名
- `auto_build.sh` - 主要的自动打包脚本
- `restore_backup.sh` - 恢复备份的脚本
- `icon.png` - 你的应用图标文件（请替换为你的图标）

## 使用方法

### 1. 配置你的应用

编辑 `config.json` 文件：

```json
{
  "app_name": "你的应用名称",
  "app_url": "https://你的网站.com",
  "icon_file": "icon.png"
}
```

### 2. 准备图标

将你的应用图标文件放在 `deploy` 文件夹中，命名为 `icon.png`（或者在config.json中指定其他名称）。

### 3. 一键运行脚本

```bash
cd deploy
./auto_build.sh
```

**就是这么简单！** 一个命令完成所有配置和APK构建。

脚本会自动：
- 替换图标和配置
- 清理之前的构建文件
- 构建Release版本APK
- 复制APK到deploy目录

完成后，你可以在 `deploy/app-release.apk` 找到可安装的APK文件。

## 脚本功能

自动打包脚本会执行以下操作：

1. **替换应用图标**：将 `icon.png` 复制到所有 mipmap 文件夹中，并重命名为 `ic_launcher.png`
2. **修改URL**：更新 `MainActivity.java` 中的 WebView URL
3. **修改应用名称**：更新 `strings.xml` 中的应用名称
4. **清理构建**：运行 `./gradlew clean` 清理之前的构建文件
5. **构建APK**：运行 `./gradlew assembleRelease` 构建Release版本
6. **复制APK**：将生成的APK复制到 `deploy/app-release.apk` 方便使用

## 恢复备份

如果需要恢复到修改前的状态：

```bash
./restore_backup.sh
```

## 注意事项

1. 确保你的系统已安装 `jq` 工具（用于解析JSON）：
   - macOS: `brew install jq`
   - Ubuntu: `sudo apt-get install jq`

2. 脚本会自动创建备份文件，安全性更高

3. 图标文件应该是PNG格式，建议尺寸为512x512像素

## 支持的图标尺寸

脚本会自动将图标复制到以下文件夹：
- `mipmap-hdpi` (72x72)
- `mipmap-mdpi` (48x48)
- `mipmap-xhdpi` (96x96)
- `mipmap-xxhdpi` (144x144)
- `mipmap-xxxhdpi` (192x192)

注意：脚本使用相同的图标文件复制到所有尺寸文件夹中。如果需要不同尺寸的图标，请手动准备相应尺寸的图标文件。