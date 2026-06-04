# WatchMemo

> 中文说明在前，English follows.

WatchMemo 是一个 **Apple Watch 优先** 的随身录音与 AI 笔记整理工具。它的目标是让会议、交流、灵感和临时想法的记录像看时间一样快：手表负责可靠捕捉，iPhone 负责接收、播放、AI 整理、复制 Markdown、投递 Obsidian 和归档。

当前版本是 `v1.0.0-beta.1`：已经完成 Apple Watch 到 iPhone 的真机闭环验证，适合作为第一个可展示、可继续迭代的 beta 版本。

## 功能概览

- Apple Watch 端快速录音。
- WatchConnectivity 将录音传到 iPhone。
- iPhone 收件箱显示录音卡片、状态、时长和来源。
- iPhone 端播放录音，并在详情页显示播放进度。
- 支持 OpenAI 兼容接口的音频理解模型。
- AI 输出结构化笔记：
  - 标题
  - 摘要
  - 关键结论
  - 原文整理
  - 行动项
  - 标签
- 支持复制 Markdown。
- 支持通过 Obsidian URI 投递到 iPhone Obsidian。
- 支持长音频分段处理策略。
- 支持弱录音上传前临时音频增强。
- 支持收件箱 / 归档工作流。
- 支持中英文界面切换。
- 支持明亮 / 暗黑外观切换。

## 当前 Beta 边界

这个 beta 版本重点验证端到端流程，不是完整商用版本。

已验证：

- Apple Watch 真机录音。
- iPhone 真机接收录音。
- iPhone 真机调用 OpenAI 兼容音频理解模型。
- AI 生成可读结构化文本。
- Markdown 复制。
- Obsidian 投递。
- 归档与恢复。

仍待完善：

- 更完整的 UI 细节打磨。
- 自动化 iOS UI 测试。
- 删除 / 清理策略。
- 搜索、标签筛选和批量操作。
- 多模型适配，包括不支持音频理解的模型链路。
- 更完整的异常恢复和离线队列体验。
- 可配置的云端或本地 agent 投递方案。

## 架构

```text
Apple Watch
  └─ 录音与本地队列
      └─ WatchConnectivity
          └─ iPhone Companion
              ├─ 收件箱与归档
              ├─ 播放与音频诊断
              ├─ AI 音频理解 / 结构化整理
              ├─ Markdown 复制
              └─ Obsidian 投递
```

主要模块：

- `WatchMemo/apps/companion/WatchMemoWatch/`：Apple Watch 应用。
- `WatchMemo/apps/companion/WatchMemo/`：iPhone companion 应用。
- `WatchMemo/packages/PhoneInboxCore/`：iPhone 录音收件箱、持久化、归档状态。
- `WatchMemo/packages/TranscriptPipelineCore/`：AI provider、文本整理、结构化笔记。
- `WatchMemo/packages/LongAudioProcessingCore/`：长音频分段策略。
- `WatchMemo/packages/NoteDeliveryCore/`：Obsidian 导出。
- `WatchMemo/packages/WatchDeliveryCore/`：Watch 端投递重试策略。
- `WatchMemo/packages/WatchMemoMessageCore/`：Watch/iPhone 消息协议。
- `WatchMemo/docs/`：产品计划、技术计划、阶段记录和决策日志。

## 开发环境

建议环境：

- macOS Tahoe 26.2 或更新版本。
- Xcode 26.5 或更新版本。
- iPhone 与 Apple Watch 真机。
- Apple ID 登录 Xcode，并在真机开启 Developer Mode。

这个项目目前主要面向 Apple 平台。小米、华为等其他手表系统仍在未来研究范围内。

## 构建

iOS Simulator 构建：

```sh
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Swift package 测试：

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
swift test --package-path WatchMemo/packages/LongAudioProcessingCore
swift test --package-path WatchMemo/packages/NoteDeliveryCore
swift test --package-path WatchMemo/packages/WatchDeliveryCore
swift test --package-path WatchMemo/packages/WatchMemoMessageCore
```

真机测试需要在 Xcode 中选择自己的 Team。公开仓库不会包含你的 API Key；OpenAI 兼容接口的 Key 会保存在 iPhone Keychain。

## 使用方式

1. 在 Xcode 打开 `WatchMemo/apps/companion/WatchMemo.xcodeproj`。
2. 登录 Apple ID 并选择自己的 Team。
3. 将 iPhone 与 Apple Watch 接入开发环境。
4. 构建并安装 iPhone companion 和 Watch app。
5. 在 Apple Watch 上录音。
6. 在 iPhone WatchMemo 中等待录音进入收件箱。
7. 在设置中配置 OpenAI 兼容接口、模型和 API Key。
8. 在录音详情页生成 AI 笔记。
9. 复制 Markdown，或导出到 Obsidian。
10. 处理完成后归档记录。

## AI Provider

当前默认方向是 **模型直接支持音频理解**。你可以使用兼容 OpenAI Chat Completions 形状的远程接口，并选择支持音频输入的模型。

后续会补充另一条链路：

```text
音频 -> ASR 转写模型 -> 通用 LLM 整理 -> 结构化笔记
```

## Obsidian

当前 Obsidian 投递使用 iPhone 上的 Obsidian URI。它适合 beta 阶段验证：

- 快速打开 Obsidian。
- 创建结构化 Markdown 笔记。
- 避免先搭建复杂后端。

## 项目记忆

长期上下文记录在：

- `WatchMemo/docs/current-status.md`
- `WatchMemo/docs/decision-log.md`
- `WatchMemo/docs/phase-logs/`

如果你继续基于这个仓库开发，建议先阅读最新 phase log。

## 许可证

许可证尚未声明。公开发布前建议选择一个开源许可证，例如 MIT、Apache-2.0 或 GPL-3.0。

---

# WatchMemo

WatchMemo is an **Apple Watch first** recording and AI note-crafting tool. The goal is to make capturing a meeting, conversation, idea, or passing thought as fast as checking the time: the watch captures reliably, while the iPhone receives, plays, organizes with AI, copies Markdown, exports to Obsidian, and archives completed memos.

The current version is `v1.0.0-beta.1`: the real-device Apple Watch to iPhone loop has been validated and is suitable as the first public beta milestone.

## Features

- Fast audio capture on Apple Watch.
- WatchConnectivity transfer to iPhone.
- iPhone inbox with recording cards, status, duration, and source.
- Audio playback with progress in the detail page.
- OpenAI-compatible audio understanding provider.
- Structured AI notes:
  - title
  - summary
  - key conclusions
  - cleaned transcript
  - action items
  - tags
- Markdown copy.
- Obsidian delivery through iPhone Obsidian URI.
- Long-audio segmentation strategy.
- Temporary upload-time audio enhancement for weak recordings.
- Inbox / Archive workflow.
- English / Simplified Chinese UI switching.
- Light / dark appearance switching.

## Beta Scope

This beta validates the end-to-end workflow. It is not a finished commercial app.

Validated:

- Real Apple Watch recording.
- Real iPhone receipt.
- Real iPhone OpenAI-compatible audio understanding calls.
- AI-generated structured notes.
- Markdown copy.
- Obsidian export.
- Archive and restore.

Still pending:

- More UI polish.
- Automated iOS UI tests.
- Delete and cleanup policies.
- Search, tag filters, and batch actions.
- Multi-provider support for models that do not understand audio directly.
- More robust offline and failure recovery.
- Configurable cloud or local agent delivery.

## Architecture

```text
Apple Watch
  └─ Recording and local delivery queue
      └─ WatchConnectivity
          └─ iPhone Companion
              ├─ Inbox and Archive
              ├─ Playback and audio diagnostics
              ├─ AI audio understanding / structured notes
              ├─ Markdown copy
              └─ Obsidian delivery
```

Main modules:

- `WatchMemo/apps/companion/WatchMemoWatch/`: Apple Watch app.
- `WatchMemo/apps/companion/WatchMemo/`: iPhone companion app.
- `WatchMemo/packages/PhoneInboxCore/`: iPhone inbox, persistence, archive state.
- `WatchMemo/packages/TranscriptPipelineCore/`: AI providers, cleanup, structured notes.
- `WatchMemo/packages/LongAudioProcessingCore/`: long-audio segmentation strategy.
- `WatchMemo/packages/NoteDeliveryCore/`: Obsidian export.
- `WatchMemo/packages/WatchDeliveryCore/`: watch-side delivery retry policy.
- `WatchMemo/packages/WatchMemoMessageCore/`: watch/iPhone message protocol.
- `WatchMemo/docs/`: product plan, technical plan, phase logs, and decisions.

## Development Environment

Recommended:

- macOS Tahoe 26.2 or later.
- Xcode 26.5 or later.
- Real iPhone and Apple Watch.
- Apple ID signed into Xcode, with Developer Mode enabled on devices.

The project currently targets Apple platforms. Xiaomi, Huawei, and other wearable operating systems remain future research areas.

## Build

iOS Simulator build:

```sh
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Swift package tests:

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
swift test --package-path WatchMemo/packages/LongAudioProcessingCore
swift test --package-path WatchMemo/packages/NoteDeliveryCore
swift test --package-path WatchMemo/packages/WatchDeliveryCore
swift test --package-path WatchMemo/packages/WatchMemoMessageCore
```

Real-device testing requires selecting your own Team in Xcode. API keys are not stored in the repository; OpenAI-compatible provider keys are saved in the iPhone Keychain.

## Usage

1. Open `WatchMemo/apps/companion/WatchMemo.xcodeproj` in Xcode.
2. Sign in with an Apple ID and select your Team.
3. Connect a real iPhone and paired Apple Watch.
4. Build and install the iPhone companion and Watch app.
5. Record on Apple Watch.
6. Wait for the recording to appear in the iPhone inbox.
7. Configure the OpenAI-compatible endpoint, model, and API key in Settings.
8. Generate an AI note from the recording detail page.
9. Copy Markdown or export to Obsidian.
10. Archive the memo when it no longer needs inbox attention.

## AI Provider

The current default path assumes the model supports **direct audio understanding**. You can use an OpenAI Chat Completions compatible endpoint with a model that accepts audio input.

A future path will support:

```text
audio -> ASR model -> general LLM cleanup -> structured note
```

## Obsidian

Obsidian delivery currently uses the iPhone Obsidian URI scheme. This is suitable for the beta because it:

- opens Obsidian quickly,
- creates structured Markdown notes,
- avoids adding backend complexity too early.

## Project Memory

Long-running context lives in:

- `WatchMemo/docs/current-status.md`
- `WatchMemo/docs/decision-log.md`
- `WatchMemo/docs/phase-logs/`

Read the latest phase log before continuing development.

## License

No license has been declared yet. Before publishing publicly, choose an open-source license such as MIT, Apache-2.0, or GPL-3.0.
