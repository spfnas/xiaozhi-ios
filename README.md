# 小智AI iOS 客户端 (XiaozhiAI for iOS)

基于 [xiaoniu/xiaozhi-ai-android](https://github.com/xiaoniu/xiaozhi-ai-android) 的通信协议，用 **Swift + SwiftUI** 重写的 iOS 版本小智 AI 实时语音聊天客户端。

> ⚠️ 这是从 Android (Kotlin/Compose) 项目**重写**而来，不是直接移植。复用了其 WebSocket 通信协议、OTA 激活流程和消息格式；UI、音频、网络层均为原生 iOS 实现。

## 功能

- OTA 地址配置 + 激活（与小智后端绑定）
- WebSocket 实时双向通信（Opus 音频）
- 语音对话：手动 / 自动多轮模式
- 文本输入对话
- 打断 / 停止
- 会话状态显示

## 技术要点

| 模块 | 实现 |
|------|------|
| UI | SwiftUI |
| 网络 | `URLSessionWebSocketTask` |
| 音频采集/播放 | `AVAudioEngine` |
| 音频编解码 | libopus (16k, mono, 60ms) |
| 激活 | OTA HTTP 接口 |

## 协议（与 Android 版一致）

- 握手：`hello` → `hello`（`transport: websocket`）
- 音频：Opus 编码二进制帧，16kHz 单声道，60ms 帧
- 消息类型：`hello` / `listen` / `stt` / `tts` / `llm` / `abort` / `iot`
- 请求头：`Authorization: Bearer <token>`、`Device-Id`、`Client-Id`、`Protocol-Version: 1`

## 本地编译（需要 Mac + Xcode）

```bash
cd xiaozhi-ios
bash build_opus.sh          # 下载并编译 libopus
open XiaozhiAI.xcodeproj    # 用 Xcode 打开，选设备运行
```

## GitHub Actions 远程编译 IPA

仓库已包含 `.github/workflows/build.yml`：

1. 把本目录推送到 GitHub 仓库
2. 在仓库 **Actions** 页手动触发 `Build iOS IPA`
3. 下载产物 `XiaozhiAI-unsigned.ipa`（未签名，需自签/侧载）

> 侧载方式：使用 AltStore / Sideloadly / 企业签名 等工具安装到 iPhone。
> 若需上架或真机调试签名，在 `XiaozhiAI.xcodeproj` 中配置你的 Bundle ID、证书与 Provisioning Profile 即可。

## 使用

1. 打开 App → 右上角「设置」
2. 填入 OTA 地址（默认 `https://api.tenclass.net/xiaozhi/ota/`）→ 点「通过 OTA 激活」
3. 激活成功后返回主页，点「自动对话」或「按住说话」开始聊天

## 目录结构

```
xiaozhi-ios/
├── XiaozhiAI.xcodeproj/      # Xcode 工程
├── XiaozhiAI/
│   ├── XiaozhiAIApp.swift    # 入口
│   ├── ContentView.swift      # 主聊天界面
│   ├── SettingsView.swift     # 设置页
│   ├── Models/MessageModels.swift
│   ├── Data/ConfigManager.swift
│   ├── Network/OtaService.swift
│   ├── Network/WebSocketManager.swift
│   ├── Audio/OpusCodec.swift
│   ├── Audio/AudioManager.swift
│   ├── ViewModels/ConversationViewModel.swift
│   └── Info.plist
├── build_opus.sh              # 编译 libopus
└── .github/workflows/build.yml
```
