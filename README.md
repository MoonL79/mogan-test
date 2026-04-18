# mogan-test Agent 说明

这个文件给 agent 读，不是给终端用户读的。

## 目标

`mogan-test` 是一个面向运行中 `moganstem -server` 实例的可脚本化控制层。
它不是 Mogan 的替代品，而是通过 CLI 命令连接到一个已经启动的 server，
再通过测试运行时完成认证并驱动真实的编辑器进程。

主要入口：

```bash
./bin/mogan-cli
```

运行时分层：

- Shell 路由：`bin/mogan-cli`、`bin/lib/mogan-cli/*.sh`
- Scheme 命令元数据：`src/cli/commands/*.scm`
- Client runtime：`src/cli/runtime/client.scm`
- Server runtime：`src/cli/runtime/mogan-server-runtime.scm`

## 前置条件

通常默认以下条件成立：

- Mogan 源码树位于 `/home/mingshen/git/mogan`
- 已构建二进制位于 `/home/mingshen/git/mogan/build/linux/x86_64/{debug,release}/moganstem`
- `gf` 已在 `PATH` 中可用
- 已有一个带 `mogan-server-runtime.scm` 的 `moganstem -server` 进程在运行

典型启动流程：

```bash
./bin/mogan-cli build-client
./bin/mogan-cli start-server
./bin/mogan-cli create-account
./bin/mogan-cli connect
```

重复性工作优先使用 target：

```bash
./bin/mogan-cli target run smoke <command> ...
```

## Agent 关心的能力

### 会话与状态检查

- `status`
- `workflow`
- `ping`
- `current-buffer`
- `buffer-text`
- `state`
- `buffer-list`
- `traces`

如果需要机器可读验证，优先用 `state`。它能返回：

- 当前 buffer 路径
- 标题
- modified 状态
- 光标路径
- 选区状态
- 样式、语言、页面设置
- 序列化后的 buffer tree

### 文本编辑

- `new-document`
- `write-text`
- `stream-text`
- `insert-text`
- `insert-return`
- `delete-left`
- `delete-right`
- `undo`
- `redo`
- `clear-undo-history`

重要细节：

- `stream-text` 可以制造“正在输入”的观感，但单靠内嵌 `\n` 不保证生成你想要的可见块结构。
- 如果你需要真实段落边界，请显式调用 `insert-return`。

### 选择与剪贴板

- `select-all`
- `select-start`
- `select-end`
- `clear-selection`
- `copy`
- `cut`
- `paste`

### 光标移动

- `move-left`
- `move-right`
- `move-up`
- `move-down`
- `move-start`
- `move-end`
- `move-start-line`
- `move-end-line`
- `move-start-paragraph`
- `move-end-paragraph`
- `move-word-left`
- `move-word-right`
- `move-to-line`
- `move-to-column`

### 文件生命周期

- `open-file`
- `save-buffer`
- `save-as`
- `export-buffer`
- `revert-buffer`
- `close-buffer`
- `switch-buffer`

### 搜索与替换

- `search-state`
- `search-set`
- `search-next`
- `search-prev`
- `search-first`
- `search-last`
- `replace-set`
- `replace-one`
- `replace-all`

### 样式与版式

- `set-main-style`
- `set-document-language`
- `add-style-package`
- `remove-style-package`
- `set-page-medium`
- `set-page-type`
- `set-page-orientation`

### 数学与富文本结构

- `insert-inline-equation`
- `insert-equation`
- `insert-fraction`
- `insert-sqrt`
- `insert-sup`
- `insert-sub`
- `insert-sum`
- `insert-integral`
- `insert-matrix`
- `insert-table`
- `insert-bold`
- `insert-italic`
- `insert-code`
- `insert-link`

### 节结构

- `insert-section`
- `insert-subsection`
- `insert-subsubsection`
- `exit-right`

这几个命令插入的是真实 section 节点，不是“看起来像标题”的普通文本。

统一规则：

- 只要插入了任何结构化节点，都先执行 `exit-right`，再决定是否 `insert-return` 或继续写正文。
- 不要假设结构插入后光标会自动回到外层。
- `section`、`subsection`、`subsubsection` 的标题文本不要带显式编号，编号交给环境自动生成。

关键使用规则：

```bash
./bin/mogan-cli insert-section "标题"
./bin/mogan-cli exit-right
./bin/mogan-cli insert-return
./bin/mogan-cli insert-text "正文"
```

如果省略 `exit-right`，后续编辑可能仍然停留在刚插入的结构内部，而不是落到你预期的外层位置。

## 推荐模式

### 安全通用模式

1. `new-document`
2. 必要时先设置 style / language
3. 先插结构：section、subsection、equation、matrix、table
4. 任意结构插入后立刻 `exit-right`
5. 用 `insert-return` 制造真实段落边界
6. 用 `state` 或 `buffer-text` 验证 tree 形状
7. 如果需要交付物，再 `export-buffer`

### 需要“像人在输入”时

可以用 `stream-text --chunk-size N`，但真实结构边界仍然应靠显式命令完成，而不是靠原始换行字符。

### 需要可复现时

优先用：

- `target run`
- `batch`
- `scenario`

示例：

```bash
./bin/mogan-cli target run smoke state
./bin/mogan-cli batch smoke -- new-document -- insert-section "Intro" -- exit-right -- insert-return -- insert-text "Body"
./bin/mogan-cli scenario batch-smoke smoke
```

## 约束与坑点

- 这是对真实编辑器的 live 控制。很多命令只有在 server 真正运行并可连接时才有意义。
- `create-account`、`connect` 以及所有远程控制命令都依赖 server 侧 runtime 已被加载。
- `state` 里的 `buffer_text` 是序列化树，不是渲染后的纯文本。
- 如果你要验证“真实结构”，应看 `buffer-text` 或 `state` 返回的 tree，而不是只看视觉渲染。
- 对于任何结构节点，不要假设普通 `insert-return` 就能自动跳出结构。应显式调用 `exit-right`。
- 对于 `insert-section`、`insert-subsection`、`insert-subsubsection`，不要把 `1.`、`1.1`、`第一节` 之类编号写进标题文本。
- 不要把 `<math|...>`、`<with|...>` 之类原始 TeXmacs 标记当纯文本写进去。应使用专门的结构化命令。

## 关键路径

- 连接 trace：`/tmp/mogan-test-connect-trace.log`
- 服务端 trace：`/tmp/mogan-test-server-trace.log`
- runtime result：`/tmp/mogan-test-runtime-result.txt`
- runtime output：`/tmp/mogan-test-runtime-output.log`

## 最小验证片段

创建真实 section，且正文位于标题结构外部：

```bash
./bin/mogan-cli new-document
./bin/mogan-cli insert-section "Section A"
./bin/mogan-cli exit-right
./bin/mogan-cli insert-return
./bin/mogan-cli insert-text "Body outside section title."
./bin/mogan-cli buffer-text
```

预期 tree 形状：

```scheme
(document
  (section "Section A")
  "Body outside section title.")
```
