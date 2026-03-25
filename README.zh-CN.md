# TypeLingo

[English README](./README.md)

TypeLingo 是一个 macOS 实时字幕浮窗工具。它会监听当前聚焦的输入框，在接近实时的条件下翻译输入内容，并把结果显示在一个悬浮字幕面板中。

它适合这些场景：

- 双语聊天和客服回复
- 实时演示和录屏
- 直播字幕辅助
- 在标准 macOS 输入框中边输入边翻译

当前项目是一个基于 Accessibility API 的 macOS 原生原型。它已经足够轻量和实用，但还不是完整输入法，因此对中文等 IME 输入法组合态的支持仍然有限。

## 项目能力

- 监听 macOS 当前聚焦的输入控件
- 自动跳过安全输入框
- 将捕获的文本翻译成指定目标语言
- 通过可缩放的悬浮字幕窗口显示翻译结果
- 支持可配置的全局唤醒快捷键来显示或隐藏浮窗
- 支持 `Google Web` 和 `OpenAI-compatible` 两类翻译后端
- 支持多个 API profile 和多个 prompt profile
- API key 存储在 macOS Keychain 中，而不是明文保存在应用配置里
- 支持设置导入和导出

## 当前限制

- 依赖 Accessibility 权限
- 在成为真正的 `InputMethodKit` 输入法之前，中文和其他 IME 的组合态文本捕获仍然不完全可靠
- 一些 Electron 应用、游戏、远程桌面客户端和自定义控件不会暴露可用的 Accessibility 文本值
- `Google Web` 只是原型阶段的便捷翻译后端，不是生产级 SLA 集成
- 未正式签名或仅 ad-hoc 签名的构建产物，在其他 Mac 上仍然可能被 Gatekeeper 拦截

## 技术栈

- Swift 6
- SwiftUI
- AppKit
- Accessibility API
- macOS Keychain
- Swift Package Manager

## 快速开始

### 环境要求

- macOS 14 或更高版本
- Xcode Command Line Tools

### 从源码运行

```bash
git clone git@github.com:DEROOCE/TypeLingo.git
cd TypeLingo
swift run typelingo
```

首次运行后，请在这里授予 `Accessibility` 权限：

`系统设置 -> 隐私与安全性 -> 辅助功能`

### 构建

```bash
swift build
swift test
```

## 翻译 Provider

TypeLingo 当前支持两种 provider 模式：

### Google Web

- 不需要 API key
- 适合本地快速测试
- 配置成本低

### OpenAI-Compatible

- 可配置 `API Key`、`Base URL` 和 `Model`
- 支持多个 API profile
- 支持多个 system prompt profile，以适配不同翻译场景

## 打包

### 构建本地 App Bundle

```bash
./scripts/package-app.sh
```

输出：

```bash
dist/TypeLingo.app
```

本地 app bundle 会使用 ad-hoc 签名，确保 Finder 和 `open` 可以在你自己的机器上正常启动。

### 构建 Release 产物

```bash
./scripts/package-release.sh
```

输出：

```bash
dist/TypeLingo-0.1.0.zip
dist/TypeLingo-0.1.0.dmg
```

如果没有真实的 `Developer ID Application` 证书和 notarization，这些产物只适合本地使用或小范围内测。

## 安装说明

如果用户安装 TypeLingo 后，macOS 出现类似下面的提示：

> Apple 无法验证 “TypeLingo” 是否包含可能危害 Mac 安全或泄漏隐私的恶意软件。

这是当前 release 构建的预期行为。

目前 TypeLingo 的 release 产物是：

- ad-hoc 签名
- 未经过 Apple notarization

这意味着 macOS Gatekeeper 在首次打开时可能会阻止应用启动。

### 命令行处理方式

高级用户可以手动移除 quarantine 属性：

```bash
xattr -dr com.apple.quarantine '/Applications/TypeLingo.app'
```

然后重新启动应用。

### 为什么会出现这个提示

这个提示并不自动意味着应用是恶意软件。出现它的原因是，当前公开构建还没有使用下面这两项：

- 付费 Apple `Developer ID Application` 正式签名
- Apple notarization 公证

当 TypeLingo 以后接入真实的 Developer ID 签名和 notarization 后，这个提示才可以对终端用户消除。

## Developer ID 签名与 Notarization

如果要正式对外分发 macOS 应用，需要具备：

- 有效的 `Developer ID Application` 证书
- 已配置的 `notarytool` keychain profile

示例：

```bash
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_KEYCHAIN_PROFILE="typelingo-notary" \
./scripts/package-release.sh
```

## 设置与密钥

- UI 设置保存在 macOS preferences 中
- API key 存储在 macOS Keychain 中
- 默认导出的设置不包含 API key
- `Export With API Keys` 仅适用于受信任设备之间的迁移

## Roadmap

- 从 Accessibility 轮询迁移到更可靠的文本观察模型
- 增加 app 黑名单和按应用配置行为
- 优化长时间输入场景下的文本切分
- 演进为真正的 `InputMethodKit` 输入法实现，以稳定支持 IME 组合态文本

## 开源状态

TypeLingo 目前是一个持续演进中的开源原型。产品方向已经明确，但部分实现细节仍然优先服务于快速迭代，而不是长期框架完备性。

如果你现在使用它，应该预期：

- 它是一个实用的本地工具
- 它会保持快速迭代
- 它会明确暴露 macOS 平台约束

第一阶段的完整复盘可以参考：

- [POSTMORTEM.md](./POSTMORTEM.md)
- [POSTMORTEM.zh-CN.md](./POSTMORTEM.zh-CN.md)

## License

MIT
