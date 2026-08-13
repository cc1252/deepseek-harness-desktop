# DeepSeek Harness Desktop

[English](README.en.md) · [下载 Releases](https://github.com/cc1252/deepseek-harness-desktop/releases)

一个面向 Windows 的、完整开源的 **DeepSeek Harness 非官方 Electron 桌面封装**。
它启动官方 `@deepseek-ai/dsh` 本地 Web 服务，再用隔离的 Electron
`WebContentsView` 加载官方界面；桌面壳只负责进程生命周期、窗口、安全导航和自绘标题栏。

> [!IMPORTANT]
> 本项目不是 DeepSeek 官方产品，也不提供模型额度或绕过 API 鉴权。
> DeepSeek Harness 仍处于 Developer Preview，请勿在高权限模式下打开不可信项目。

![DeepSeek Harness Desktop](docs/screenshot.png)

## 下载

在 [GitHub Releases](https://github.com/cc1252/deepseek-harness-desktop/releases) 中提供：

- `DeepSeek-Harness-Desktop-Setup-0.1.0-x64.exe`：完整 Windows 安装包；
- `DeepSeek-Harness-Desktop-Portable-0.1.0-x64.exe`：无需安装的便携单文件；
- `DeepSeek-Harness-Desktop-Source-0.1.0.zip`：与发布对应的源码快照；
- `SHA256SUMS.txt`：发布文件校验值；
- GitHub 自动生成的源码归档。

安装包没有商业代码签名，因此 Windows 可能显示“未知发布者”。
安装版使用当前用户的标准应用目录，以避开 Windows 传统路径长度限制；如需放在任意目录，
请使用便携版或 `win-unpacked` 构建。

## 当前锁定版本

| 组件 | 版本 |
| --- | --- |
| DeepSeek Harness (`@deepseek-ai/dsh`) | `0.1.0-rc.6` |
| Electron | `43.4.0` |
| 内置 Node.js | `24.19.0` |
| electron-builder | `26.15.3` |

版本被明确锁定在两个 `package-lock.json` 中。准备脚本从 Node.js 官方站点下载运行时，
并在解压前同时比对仓库内固定值和官方 `SHASUMS256.txt`。当前 Windows x64 压缩包的
SHA-256 为 `57F71AB3652E797D84ACDDC79C81CC9FF1C6DDB2A1974CDB83F00FEE9BFF4C73`。

## 从源码运行

要求：Windows 10/11 x64、Node.js 24、npm 和 PowerShell 5 或更高版本。

```powershell
git clone https://github.com/cc1252/deepseek-harness-desktop.git
cd deepseek-harness-desktop
npm ci
npm run setup
npm run start
```

也可以用 `npm run dev` 自动执行运行时准备后启动。

`npm run setup` 会：

1. 按 `harness/package-lock.json` 安装官方 Harness 及其完整运行依赖；
2. 下载并校验官方 Node.js Windows x64 运行时；
3. 从 Harness npm 包提取官方鲸鱼图标；
4. 生成所有随包 npm 依赖的第三方许可证清单。

## 构建 Windows 发布包

```powershell
npm ci
npm run build:windows
```

生成结果位于 `dist/`：

- 标准 NSIS 安装包；
- 便携单文件；
- `win-unpacked/` 快速启动目录；
- `SHA256SUMS.txt`。

单独构建也可以使用：

```powershell
npm run build:dir
npm run build:installer
npm run build:portable
```

## 结构

```text
.
├─ main.js                         Electron 主进程、Harness 子进程和内容视图
├─ preload.js                      最小权限窗口控制桥
├─ shell.html                      自绘标题栏和启动画面
├─ build/deepseek-harness.svg      官方 Harness 包中的鲸鱼图标
├─ harness/
│  ├─ package.json                 官方 CLI 的独立运行时依赖
│  └─ package-lock.json            完整锁文件
├─ scripts/
│  ├─ prepare-runtime.ps1          一键准备、下载和校验
│  ├─ build-windows.ps1            安装版 + 便携版构建
│  └─ generate-third-party-notices.mjs
└─ .github/workflows/              源码检查和 Release 自动构建
```

架构细节参见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。

## API Key 与数据

应用会继承启动进程的环境变量，因此已有 `DEEPSEEK_API_KEY` 时可以直接使用。
也可以在 Harness 左下角的“设置”→“Models”中配置供应商。本项目不保存、上传或内置 API Key。

用户数据和日志保存在：

```text
%APPDATA%\deepseek-harness-desktop\harness-home
%APPDATA%\deepseek-harness-desktop\logs\desktop.log
```

卸载程序默认保留用户数据，避免误删会话。

## 安全边界

- Harness 服务只监听 `127.0.0.1` 的随机端口；
- 官方页面运行在 `sandbox: true`、`contextIsolation: true`、`nodeIntegration: false` 的内容视图中；
- 自绘标题栏只能通过受限 IPC 请求最小化、最大化/还原和关闭；
- 非本地导航交给系统浏览器，不允许页面直接访问 Node.js；
- 单实例退出时同步停止 Harness 子进程。

## 上游、图标和许可证

壳代码采用 [MIT License](LICENSE)。DeepSeek Harness 及官方鲸鱼图标归上游项目所有，
按其 MIT 许可证使用和署名。完整信息见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

- 上游项目：[deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness)
- Electron：[electron/electron](https://github.com/electron/electron)
- Node.js：[nodejs/node](https://github.com/nodejs/node)

## 贡献

欢迎 Issue 和 Pull Request。提交前请运行：

```powershell
npm ci
npm run check
```

参见 [CONTRIBUTING.md](CONTRIBUTING.md) 和 [SECURITY.md](SECURITY.md)。
