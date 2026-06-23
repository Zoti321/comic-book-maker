# 发布（CD）

桌面端通过 GitHub Actions 持续部署：推送 semver tag 后自动构建并发布到 [GitHub Releases](https://github.com/Zoti321/comic-book-maker/releases)。

## 发布流程

1. 确保 `main` 上最新提交已通过 CI（`.github/workflows/ci.yml`）。
2. 在目标提交上打 tag（版本号与 tag 一致，带 `v` 前缀）：

   ```bash
   git tag v1.2.0
   git push origin v1.2.0
   ```

3. 工作流 `.github/workflows/release.yml` 将：
   - 在 `ubuntu` 上跑 `verify`（codegen、`cargo test`、`flutter analyze`）
   - 并行构建 Windows（Inno Setup 安装包）、macOS（arm64 zip）、Linux（x64 tar.gz）
   - 创建 **Published** GitHub Release 并附上产物

版本号从 tag 推导（`v1.2.0` → `--build-name=1.2.0`），`--build-number` 使用 workflow `run_number`。仓库内 `app/pubspec.yaml` 的 `version:` 无需为发布单独修改。

## 产物

| 平台 | 文件 |
|------|------|
| Windows x64 | `comic-book-maker-<version>-windows-x64-setup.exe`（安装向导为简体中文；语言文件随仓库 `app/windows/installer/ChineseSimplified.isl`） |
| macOS arm64 | `comic-book-maker-<version>-macos-arm64.zip` |
| Linux x64 | `comic-book-maker-<version>-linux-x64.tar.gz` |

## 本地 Windows 安装包

仓库内脚本：`app/windows/installer/comic_book_maker.iss`。先完成 Release 构建：

```powershell
cd app
flutter build windows --release
```

再用 Inno Setup 编译（路径按本机安装位置调整）：

```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" `
  "/DMyAppVersion=1.0.0" `
  "/DOutputDir=$PWD\..\dist" `
  "windows\installer\comic_book_maker.iss"
```

## 未签名安装说明

当前发布产物**未做代码签名**。安装时可能出现：

- **Windows**：SmartScreen「未知发布者」→ 点击「更多信息」→「仍要运行」。
- **macOS**：首次打开被 Gatekeeper 拦截 → 在 `.app` 上右键「打开」，或在终端执行  
  `xattr -cr /path/to/comic_book_maker.app`。

Intel 版 Mac 可通过 Rosetta 运行 arm64 构建。

## Android 签名与侧载更新

Release APK 使用 **固定 release keystore** 签名，以便用户可通过应用内更新覆盖安装。本地与 CI 共用同一密钥。

### 生成 keystore（一次性）

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

将 `upload-keystore.jks` 放在 `app/android/`（已在 `.gitignore` 中忽略）。

### 本地签名

复制 `app/android/key.properties.example` 为 `app/android/key.properties`，填入密码与路径：

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=upload-keystore.jks
```

未配置 `key.properties` 时，release 构建回退为 debug 签名（**无法与正式侧载包互相覆盖更新**）。

### GitHub Actions Secrets

在仓库 Settings → Secrets and variables → Actions 中配置：

| Secret | 内容 |
|--------|------|
| `ANDROID_KEYSTORE_BASE64` | `upload-keystore.jks` 的 base64（`base64 -w0 upload-keystore.jks`） |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 密码 |
| `ANDROID_KEY_ALIAS` | 别名（如 `upload`） |
| `ANDROID_KEY_PASSWORD` | key 密码 |

配置后，`release.yml` 的 `build-android` job 会自动还原 keystore 并签名。

### Android 产物

| 文件 | 说明 |
|------|------|
| `comic-book-maker-<version>-android-arm64.apk` | arm64 侧载包；应用内更新会下载并调起系统安装器 |

应用内更新需用户在系统设置中允许本应用「安装未知应用」。
