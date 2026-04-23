# AI 多轮对话（Chat）设计

**日期**：2026-04-23
**状态**：已评审，待实施
**范围**：在现有"单轮 AI 分析"基础上扩展为"传统 AI 问答"式的多轮对话，保留现有交互入口与视觉风格。

---

## 1. 背景与目标

### 1.1 现状

- `AIAnalysisService` 是单轮模型：`currentContent` 为一个字符串，`AnalysisRequest` 只含 `systemPrompt + userPrompt`。
- `OpenAICompatibleProvider` 内部总是固定组 `[system, user]` 两条消息。
- 每条排盘记录只持久化一个加密字段 `interpretation_<resultId>`，存单块 markdown。
- UI 入口两处：结果页内嵌的 `AIAnalysisWidget` 卡片 + `AIAnalysisFAB` → `_AIAnalysisSheet`。

### 1.2 目标

- 用户点"开始分析"后得到的内容，作为对话的第一条 AI 消息。
- 分析完成后可以继续以传统聊天形式追问；消息气泡、底部输入、流式回复等体验对齐主流 AI 问答产品。
- 完整对话随排盘记录持久化，下次打开记录可继续。
- 对现有代码路径侵入尽量小，保留单轮分析的视觉摘要；旧记录可惰性升级，不需要迁移脚本。

### 1.3 非目标（MVP 明确排除）

- 消息编辑后重发、regenerate 最后一条。
- 多会话（一个卦象多条对话线）。
- 自动摘要以压缩溢出上下文（改由"新建话题"兜底）。
- 跨排盘的通用 AI 助手、语音输入、图片附件。

---

## 2. 关键决策

| 决策点 | 选择 | 依据 |
| --- | --- | --- |
| 对话容器 | 底部抽屉（`DraggableScrollableSheet`） | 对现有卡片侵入小，适合底部输入 + 顶部滚动，符合项目"Shallow nav"策略 |
| 初始分析与对话的关系 | 分析即第一条 AI 消息 | 语义自然，数据模型最简，迁移干净 |
| 持久化范围 | 全量持久化 | 符合用户直觉，token 已消耗的内容默认保留 |
| 上下文策略 | 固定开头（system + cast user + 初始分析） + 滑窗最近 12 条 + "新建话题"按钮兜底 | 锚点保证 AI 不脱离卦象；滑窗控制 token；自动摘要留给后续迭代 |
| 流式 | 保留 | 现有体验，也是 chat UI 标配 |
| 每条消息操作 | 仅"复制本条" | MVP 够用，避免状态复杂 |
| 全局操作 | 新建话题 / 复制全文 / 预览下一次请求 | 覆盖常用需求 |

---

## 3. 数据模型

### 3.1 `AIChatMessage`

```dart
enum ChatRole { system, user, assistant }
enum ChatMessageStatus { sending, streaming, sent, failed }

@freezed
class AIChatMessage with _$AIChatMessage {
  const factory AIChatMessage({
    required String id,                // uuid v4
    required ChatRole role,
    required String content,
    required DateTime timestamp,
    required ChatMessageStatus status,
    String? errorMessage,              // status=failed 时的错误原因
  }) = _AIChatMessage;

  factory AIChatMessage.fromJson(Map<String, dynamic> json) => _$AIChatMessageFromJson(json);
}
```

### 3.2 `CastSnapshot`

```dart
@freezed
class CastSnapshot with _$CastSnapshot {
  const factory CastSnapshot({
    required String systemPrompt,      // 初始组装时的 system prompt
    required String castUserPrompt,    // 初始组装时的卦象 user prompt
    required String model,             // 冻结当时的模型（便于追溯，对话中途切模型不影响已有消息归档）
    required DateTime assembledAt,
  }) = _CastSnapshot;

  factory CastSnapshot.fromJson(Map<String, dynamic> json) => _$CastSnapshotFromJson(json);
}
```

冻结 `systemPrompt + castUserPrompt` 的动机：模板或卦象计算在用户对话进行中被修改时，后续轮次仍应基于"初次分析时的那份上下文"，否则 AI 会"换了个人格"。

### 3.3 `AIConversation`

```dart
@freezed
class AIConversation with _$AIConversation {
  const factory AIConversation({
    required int version,              // schema 版本，MVP = 1
    required String resultId,
    required DivinationType systemType,
    required CastSnapshot castSnapshot,
    required List<AIChatMessage> messages,
    required DateTime updatedAt,
  }) = _AIConversation;

  factory AIConversation.fromJson(Map<String, dynamic> json) => _$AIConversationFromJson(json);
}
```

**不变式**：
- `messages[0].role == assistant`（初始分析）
- 之后顺序严格为 `user, assistant, user, assistant, ...`
- 发送失败的 user 消息也保留在 list 里，`status=failed`，可"重试"
- 流式中的 assistant 消息 `status=streaming`，完成后 `status=sent`

---

## 4. Provider 层改造

### 4.1 新接口

在 `LLMProvider` 上新增：

```dart
Future<ChatResponse> chat(ChatRequest request);
Stream<String>? chatStream(ChatRequest request) => null;

class ChatRequest {
  final List<ProviderChatMessage> messages;
  final double? temperature;
  final int? maxTokens;
}

class ProviderChatMessage {
  final ChatRole role;
  final String content;
}

class ChatResponse {
  final String content;
  final int tokensUsed;
  final Duration latency;
  final String model;
  final String providerId;
}
```

### 4.2 旧接口降级为 shim

`analyze(AnalysisRequest)` 和 `analyzeStream` 保留，内部转成两条消息的 `chat` 调用，现有调用点不破。

### 4.3 OpenAICompatibleProvider

实现非常直接——当前代码已经在组 `[system, user]` 数组，抽出来改为接受 `List<ProviderChatMessage>` 即可。`temperature` / `maxTokens` 从 `_config` 读取默认值，`ChatRequest` 里的传入值优先。

---

## 5. 服务层

### 5.1 `AIConversationService`

独立的 `ChangeNotifier`。持有 `Map<String, AIConversation>` 缓存（keyed by resultId），单一事实来源。

```dart
class AIConversationService extends ChangeNotifier {
  AIConversationService({
    required LLMProviderRegistry providerRegistry,
    required PromptAssembler promptAssembler,
    required AIConfigManager configManager,
    required ChatRepository chatRepository,
  });

  AIConversation? conversationOf(String resultId);
  bool isStreaming(String resultId);
  String? errorOf(String resultId);

  Future<void> startConversation(DivinationResult result, {String? question});
  Future<void> sendFollowUp(String resultId, String userText);
  Future<void> retry(String resultId, String messageId);
  Future<void> stop(String resultId);
  Future<void> reset(String resultId);                // 只保留 messages[0]
  Future<void> delete(String resultId);               // 完全清空（排盘记录被删时调用）
}
```

**内部流程（sendFollowUp）**：

1. 追加 user 消息（status=sending）→ `notifyListeners`
2. `ChatRequestBuilder.build(conversation)` 组装 messages（见 §5.2）
3. 调 `Provider.chatStream(...)`：
   - 追加 assistant 占位消息（status=streaming）
   - 每个 chunk 追加到占位消息 content → `notifyListeners`
   - onDone：status=sent, 持久化
   - onError：status=failed + errorMessage；user 消息也标记 failed 以便重试
4. 无论成功失败都 `ChatRepository.save(conversation)`

**并发保护**：同一 resultId 一次只允许一个 in-flight stream；`Map<String, StreamSubscription>` 管理，新请求到来时先取消旧的。

### 5.2 `ChatRequestBuilder`（纯函数）

```dart
class ChatRequestBuilder {
  static const int followUpWindowSize = 12;  // 初始分析之后保留的消息数

  static List<ProviderChatMessage> build(AIConversation conversation) {
    final anchors = [
      ProviderChatMessage(role: ChatRole.system, content: conversation.castSnapshot.systemPrompt),
      ProviderChatMessage(role: ChatRole.user, content: conversation.castSnapshot.castUserPrompt),
      ProviderChatMessage(role: ChatRole.assistant, content: conversation.messages[0].content),
    ];
    final followUps = conversation.messages.skip(1)
        .where((m) => m.status != ChatMessageStatus.failed)
        .toList();
    final windowed = followUps.length <= followUpWindowSize
        ? followUps
        : followUps.sublist(followUps.length - followUpWindowSize);
    return [
      ...anchors,
      ...windowed.map((m) => ProviderChatMessage(role: m.role, content: m.content)),
    ];
  }
}
```

纯函数，零依赖，完整单元测试覆盖。

### 5.3 `ChatRepository`

封装 `FlutterSecureStorage` 读写。

```dart
class ChatRepository {
  Future<AIConversation?> load(String resultId);      // 先查 conversation_<id>，不存在则尝试 legacy fallback
  Future<void> save(AIConversation conversation);
  Future<void> delete(String resultId);               // 清理 conversation_<id> + legacy interpretation_<id>

  // 惰性迁移：如果 conversation_<id> 不存在但 interpretation_<id> 存在，
  // 返回一个内存中的 AIConversation（仅含第一条 assistant 消息），不写回。
  // 下次用户追问时走 save() 路径才真正落盘。
  Future<AIConversation?> _tryLegacyFallback(String resultId);
}
```

### 5.4 与 `AIAnalysisService` 的关系

- `AIAnalysisService.analyze()` 改为委托：`_conversationService.startConversation(result, question)`；结束后返回 `AnalysisResponse`（从 `conversation.messages[0]` 映射）。
- `AIAnalysisService` 的状态访问器改为派生于 `ConversationService`：
  - `currentContent` → `conversationOf(currentResultId)?.messages[0].content ?? ''`（流式中返回正在追加的内容）
  - `isAnalyzing` → 当 `currentResultId` 对应的会话中 `messages[0].status == streaming`
  - `error` → `errorOf(currentResultId)`
- `AIAnalysisService` 本身通过监听 `ConversationService` 实现 `notifyListeners` 转发，保持结果页卡片现有订阅不变。
- 对外 API 不破；但内部所有路径都汇入 `ConversationService`。

---

## 6. 存储与迁移

### 6.1 新字段

加密字段键名：`conversation_<resultId>`。值为 `AIConversation.toJson()` 的字符串化 JSON。

### 6.2 老数据惰性升级

读取时：
1. `conversation_<id>` 存在 → 直接反序列化。
2. 不存在但 `interpretation_<id>` 存在 → 构造一个临时 `AIConversation`：
   - `messages = [AIChatMessage(role: assistant, content: 旧 blob, status: sent, timestamp: now, id: uuid)]`
   - `castSnapshot = null`（允许可空——legacy 临时态）
   - 返回给 UI 展示，**仅用于渲染**，不能直接进入 `ChatRequestBuilder`。
3. 用户首次发追问时：
   - `AIConversationService.sendFollowUp()` 发现 `castSnapshot == null` → 先用 `PromptAssembler.assemble(result)` 重新组装一份写入 conversation.castSnapshot，再走正常 builder 路径。
   - `ChatRepository.save()` 此时才真正落 `conversation_<id>`；同步清理 `interpretation_<id>`（避免双份）。

对应模型调整：`AIConversation.castSnapshot` 字段改为可空（`CastSnapshot?`）。所有非 legacy 代码路径保证写入时一定非空。

### 6.3 删除同步

`DivinationRepositoryImpl.deleteRecord(id)` 内：删除 drift 行 + 清理 `interpretation_<id>` + 清理 `conversation_<id>`。

---

## 7. UI 设计

### 7.1 现有卡片 `AIAnalysisWidget`

保持结构不变。分析完成且 `conversation.messages.length >= 1` 时，在现有清除按钮上方新增一行主按钮：

- 默认：`💬 继续追问`
- 已有追问：`继续对话 · N 条消息`（其中 N = `messages.length - 1`）

点击打开 `AIChatSheet(resultId)`。

现有的"复制 / 预览 / 重新分析 / 清除"按钮语义：

- **复制 / 预览**：继续针对"初始分析"（messages[0]）生效。
- **重新分析**：语义变更——会**清空整个对话**（含所有追问）后重新启动初始分析。因为后续追问都是基于上一份初始分析的上下文建立的，保留它们会语义错乱。UI 需加二次确认提示："重新分析会清空当前对话的所有追问内容。"
- **清除**：完全删除对话（`ConversationService.delete(resultId)`），等同于回到"未分析"状态。

"新建话题"（抽屉内）与"重新分析"（卡片内）的区别：前者保留 messages[0] 只丢弃追问；后者连 messages[0] 也重新生成。

### 7.2 新增 `AIChatSheet`

```
┌──────── drag handle ────────┐
│ 🤖 AI 对话 · [水雷屯]  ⋮  ✕ │   ← 顶部，sticky
├─────────────────────────────┤
│ [AI 气泡] 初始分析 markdown │
│                 [📋 复制]    │
│                             │
│                [用户气泡]   │
│                             │
│ [AI 气泡] 流式回复中…       │
│                             │
│ ... 历史消息，ListView 滚动 │
├─────────────────────────────┤
│ [继续追问…  多行自适应  ] [➤] │   ← 底部输入栏，sticky
└─────────────────────────────┘
```

- 气泡：AI 左对齐（浅宣纸底 `paperBg` + 墨色边 `inkBorder`）；用户右对齐（主题朱砂 `vermilion`）。使用现有 antique token 库。
- AI 气泡用 `MarkdownBody`，`selectable: true`。
- 流式中的最后一条 AI 气泡底部显示小圆点打字机动画（可选，MVP 可先用纯文本 cursor `▍`）。
- 顶部 `⋮` 菜单：
  - **新建话题**：二次确认；调 `ConversationService.reset(resultId)`。
  - **复制全文**：把全部 `messages` 拼成 markdown 复制到剪贴板。
  - **预览下一次请求**：显示 `ChatRequestBuilder.build(conversation)` 的结果（复用现有预览 sheet 样式）。
- 输入框：多行 `TextField`，最多 5 行自适应高度，超过滚动；placeholder "继续追问…"。
- 发送按钮：生成中变成停止按钮（`■`），点击调 `ConversationService.stop(resultId)`。
- 空文本或正在生成时发送按钮 disabled。
- 键盘：点击发送按钮发送；Enter 换行（移动端主流做法）。

### 7.3 `AIAnalysisFAB`

FAB 的"打开分析 sheet"改为："若对话不存在 → 原行为（启动初始分析）；若已存在 → 打开 `AIChatSheet`"。

### 7.4 仿古风一致性

- 气泡背板：`antiqueCardBg`（AI）/ `vermilion.withOpacity(0.12)`（用户气泡背景，文字仍用 antique 深色）
- 边框：1px `antiqueBorderSubtle`
- 圆角 12px
- 输入栏顶部加一条 `inkDivider`
- 字体沿用 `AppTextStyles.antiqueBody`

---

## 8. 数据流

**启动对话**（首次点"开始分析"）
```
AIAnalysisWidget._startAnalysis()
  → AIConversationService.startConversation(result)
    → PromptAssembler.assemble() → castSnapshot
    → 新建 AIConversation {messages: [], castSnapshot}
    → 追加 assistant 占位 (status=streaming)
    → Provider.chatStream([system, castUserPrompt])
      → 每 chunk 追加 content → notifyListeners
    → 完成：status=sent, ChatRepository.save
```

**继续追问**
```
AIChatSheet.onSend(text)
  → AIConversationService.sendFollowUp(resultId, text)
    → 追加 user (status=sending) → notify
    → ChatRequestBuilder.build(conversation) → messages
    → 追加 assistant 占位 (status=streaming) → notify
    → Provider.chatStream(messages)
      → 流式 chunk → notify
    → 完成：user.status=sent, assistant.status=sent → save
    → 错误：user/assistant.status=failed + errorMessage → save
```

**重试失败消息**
```
AIChatSheet.onRetry(messageId)
  → AIConversationService.retry(resultId, messageId)
    → 定位到失败的 user 消息，删除其后的所有消息（含失败的 assistant 占位）
    → 等价于"重发同样的 user 文本"
    → 走 sendFollowUp 路径
```

**新建话题**
```
AIChatSheet 菜单 → 二次确认
  → AIConversationService.reset(resultId)
    → messages = [messages[0]]
    → save → notify
```

**恢复会话**
```
AIAnalysisWidget.didChangeDependencies / initState
  → AIConversationService.loadIfNeeded(resultId)
    → ChatRepository.load(resultId) → conversation / null
    → 缓存 + notify
```

---

## 9. 错误处理

| 场景 | 处理 |
| --- | --- |
| user 发送失败（网络/鉴权） | user 消息 status=failed，气泡旁红 `!` + "重试" 按钮 |
| 流式中断 | 已到达的 assistant 内容保留，status=failed，气泡底显示 "继续生成" 按钮（内部走 retry） |
| 用户主动 stop | assistant status=sent（保留已到达内容），不标记 failed |
| API 未配置 | 卡片按钮 disable；FAB 隐藏；抽屉不可开启 |
| `context_length_exceeded` / 4xx 超长 | 顶部 SnackBar "对话已过长，请点菜单中的'新建话题'" |
| 同一 resultId 重复触发 | 先取消旧 stream 再走新请求 |
| 反序列化失败（存储损坏） | 返回 null，退回 legacy fallback；记录错误日志；不阻塞 UI |

---

## 10. 测试策略

### 10.1 单元测试

- `ChatRequestBuilder.build`
  - 仅含初始分析（0 条追问）
  - 1 条追问
  - 恰好 12 条追问（窗口满）
  - 13 条追问（窗口溢出，验证丢弃最早一条）
  - 含 failed 消息（验证被过滤）
- `ChatRepository`
  - 读写往返一致
  - 老数据 fallback（只有 `interpretation_<id>`）
  - 老数据 fallback 后首次 save 清理旧字段
  - 空 resultId / 不存在的 key 返回 null
- `AIConversationService`（mocktail mock provider + repository）
  - `startConversation` 状态机（流式 chunks → sent）
  - `startConversation` 错误路径（provider 抛异常）
  - `sendFollowUp` 正常流
  - `sendFollowUp` 流式中途被 `stop` 打断
  - `retry` 从失败消息定位正确
  - `reset` 只保留 messages[0]
  - 并发保护：sendFollowUp 未完成时二次触发，旧 stream 被取消

### 10.2 Widget 测试

- `AIChatBubble` 两个 variant（role=user / assistant）渲染正确
- `AIChatInputBar`
  - 空文本发送按钮 disabled
  - 生成中按钮切换为停止
  - 长文本触发多行扩展
- `AIChatSheet`
  - 空对话占位
  - 已有消息列表渲染 + 滚动到底
  - 菜单操作（新建话题、复制全文、预览请求）

### 10.3 集成测试

- 起卦 → 初始分析 → 1 条追问 → 关闭 app → 重开 → 对话完整恢复
- 删除排盘记录 → `conversation_<id>` 和 `interpretation_<id>` 都被清理

### 10.4 迁移兼容

- 构造只含 `interpretation_<id>` 的老数据 → 打开抽屉 → 渲染为单条 AI 消息
- 在上述状态下发追问 → 落盘 `conversation_<id>` + 清理旧字段

---

## 11. 性能与成本注意点

- 滑窗 12 条（约 6 轮追问）在多数场景下单次请求 token 量稳定在 5k–15k 区间。
- 整段 `AIConversation` 以 JSON 字符串存入 secure storage，实测单条卦象对话 20 条消息约 30–60KB，在 Keychain/Keystore 限制内安全。
- UI 用 `ListView.builder`，避免大对话一次性构建全部气泡。
- 流式 `notifyListeners()` 节流策略：沿用 `AIAnalysisService._safeNotify`（避开 layout/paint 阶段）。

---

## 12. 文件变更清单

### 新增
- `lib/ai/model/ai_chat_message.dart`
- `lib/ai/model/ai_conversation.dart`
- `lib/ai/service/ai_conversation_service.dart`
- `lib/ai/service/chat_request_builder.dart`
- `lib/ai/service/chat_repository.dart`
- `lib/presentation/widgets/ai_chat_sheet.dart`
- `lib/presentation/widgets/ai_chat_bubble.dart`
- `lib/presentation/widgets/ai_chat_input_bar.dart`
- `test/ai/service/chat_request_builder_test.dart`
- `test/ai/service/chat_repository_test.dart`
- `test/ai/service/ai_conversation_service_test.dart`
- `test/presentation/widgets/ai_chat_bubble_test.dart`
- `test/presentation/widgets/ai_chat_input_bar_test.dart`
- `test/presentation/widgets/ai_chat_sheet_test.dart`

### 修改
- `lib/ai/llm_provider.dart`（新增 `chat` / `chatStream` + `ChatRequest/Response/ProviderChatMessage`；旧方法保留）
- `lib/ai/providers/openai_compatible_provider.dart`（实现新方法；老方法转 shim）
- `lib/ai/service/ai_analysis_service.dart`（内部委托 ConversationService）
- `lib/ai/ai_bootstrap.dart`（注册 `AIConversationService` + `ChatRepository`）
- `lib/presentation/widgets/ai_analysis_widget.dart`（新增"继续追问"按钮 + 打开抽屉）
- `lib/data/repositories/divination_repository_impl.dart`（删除记录时清理 conversation 字段）
- `lib/main.dart` 或 provider 注册处：将 `AIConversationService` 暴露给 widget 树

---

## 13. 实施步骤概览

1. 数据模型 + provider 接口扩展（新老并存）
2. `ChatRepository` + 惰性迁移
3. `ChatRequestBuilder`（纯函数，全测试覆盖）
4. `AIConversationService`（状态机，mock provider 充分测试）
5. `AIAnalysisService` 改为委托
6. UI 组件：bubble → input bar → sheet
7. `AIAnalysisWidget` 集成"继续追问"入口
8. `DivinationRepositoryImpl` 同步删除逻辑
9. 集成测试 + 迁移兼容测试
10. 手工验证：真实模型 + 真实卦象走一次完整流程

详细分步骤实施计划见对应的 implementation plan 文档。
