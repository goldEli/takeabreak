# TakeABreak

一个基于 `AppKit + SwiftUI` 的 macOS 菜单栏休息提醒应用。

## 功能

- 每完成一个工作周期后，发送系统通知提醒休息
- 休息倒计时结束后自动切回工作状态并继续计时
- 支持配置工作分钟数和休息秒数
- 只显示在菜单栏，不显示 Dock 图标
- 配置通过 `UserDefaults` 持久化，重启后保留

## 目录结构

- `Sources/takeabreak/TakeABreakApp.swift`：应用入口
- `Sources/takeabreak/AppDelegate.swift`：菜单栏图标、弹窗、通知权限
- `Sources/takeabreak/BreakTimerStore.swift`：计时状态机、通知、配置持久化
- `Sources/takeabreak/MenuBarContentView.swift`：设置界面
- `App/Info.plist`：菜单栏应用元数据，包含 `LSUIElement`
- `scripts/build_app.sh`：生成 `.app` 包

## 编译

命令行构建：

```bash
swift build
```

生成可双击启动的 `.app`：

```bash
./scripts/build_app.sh
open .build/app/TakeABreak.app
```

首次启动时，macOS 会请求通知权限；允许后才能收到休息提醒。
