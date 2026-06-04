# Changelog

## v1.0.0-beta.1 - 2026-06-04

### 中文

这是 WatchMemo 的第一个 beta 里程碑版本。

已完成并通过真机验证：

- Apple Watch 录音。
- WatchConnectivity 传输到 iPhone。
- iPhone 收件箱与录音详情页。
- iPhone 播放录音与播放进度。
- OpenAI 兼容音频理解接口。
- 结构化 AI 笔记：
  - 标题
  - 摘要
  - 关键结论
  - 整理后的原文
  - 行动项
  - 标签
- Markdown 复制。
- iPhone Obsidian URI 投递。
- 长音频分段策略。
- 上传前临时音频增强。
- 收件箱 / 归档 / 恢复到收件箱。
- 设置页集中配置：
  - AI provider
  - API Key
  - Obsidian vault / folder
  - 中英文界面
  - 明亮 / 暗黑外观
- iPhone 全屏兼容修复，避免真机 letterboxed 显示。

已验证命令：

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
swift test --package-path WatchMemo/packages/LongAudioProcessingCore
swift test --package-path WatchMemo/packages/NoteDeliveryCore
swift test --package-path WatchMemo/packages/WatchDeliveryCore
swift test --package-path WatchMemo/packages/WatchMemoMessageCore
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' build
```

仍待完善：

- UI 细节继续对齐 Stitch 参考稿。
- 自动化 iOS UI 测试。
- 删除与存储清理策略。
- 搜索、标签筛选、批量操作。
- 不支持音频理解模型的 ASR + LLM 适配链路。
- 更完整的失败恢复与离线队列体验。

### English

This is the first beta milestone for WatchMemo.

Implemented and validated on real devices:

- Apple Watch recording.
- WatchConnectivity transfer to iPhone.
- iPhone inbox and memo detail page.
- iPhone audio playback with progress.
- OpenAI-compatible audio understanding provider.
- Structured AI notes:
  - title
  - summary
  - key conclusions
  - cleaned transcript
  - action items
  - tags
- Markdown copy.
- iPhone Obsidian URI export.
- Long-audio segmentation strategy.
- Temporary upload-time audio enhancement.
- Inbox / Archive / Restore to Inbox workflow.
- Unified Settings page:
  - AI provider
  - API key
  - Obsidian vault / folder
  - English / Simplified Chinese UI
  - light / dark appearance
- iPhone fullscreen compatibility fix to avoid letterboxed real-device display.

Validated commands:

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
swift test --package-path WatchMemo/packages/LongAudioProcessingCore
swift test --package-path WatchMemo/packages/NoteDeliveryCore
swift test --package-path WatchMemo/packages/WatchDeliveryCore
swift test --package-path WatchMemo/packages/WatchMemoMessageCore
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' build
```

Still pending:

- More UI polish against the Stitch references.
- Automated iOS UI tests.
- Delete and storage cleanup policies.
- Search, tag filters, and batch actions.
- ASR + LLM fallback for models that do not accept audio directly.
- More complete failure recovery and offline queue UX.
