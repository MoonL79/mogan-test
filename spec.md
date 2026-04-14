# 任务规格

## 任务名称

Mogan 命令行控制与测试平台

## 目标

在 `mogan-test` 仓库中实现一个以 **Goldfish Scheme** 为核心的最小可用平台，
使代理能够通过命令行命令稳定地控制真实的 Mogan 能力，而不是依赖脆弱的 GUI 点击自动化。

该平台的职责是：

- 为代理提供操作 Mogan 的统一命令入口
- 将命令行请求路由到稳定的 Scheme 能力
- 优先调用真实的 Mogan 内部能力，而不是停留在纯 stub
- 为后续扩展更多编辑、查询、导出、图形测试能力提供稳定骨架

## 问题定义

这个平台的本质，不是一个抽象测试框架，也不是一个单纯的 mock/stub 系统。
它更接近一个“可被命令行驱动的 Mogan 控制层”：

- 上层是命令行调用
- 中层是稳定的请求/路由层
- 下层是对运行中的 Mogan 进程的真实 Scheme 能力调用

测试只是这个控制层的直接用途之一。
更重要的是，代理可以通过它明确知道“应该调用什么能力”以及“如何验证结果”。

这里的 `server` 是中介控制面，不是最终目标本身。
测试平台通过连接运行中的 `server`，间接控制真实的 Mogan 能力。

## 运行模型

测试时必须使用完整的真实 Mogan，而不是只在仓库内模拟函数调用。

目标运行链路应当是：

1. 启动一个可连接的真实 Mogan 进程，并让它暴露 server/client 控制通道
2. 由测试平台连接到该运行中的 server
3. 通过命令行请求触发平台能力
4. 由平台将请求转发为对 Mogan 内部 Scheme 能力的调用
5. 返回结构化结果，供代理验证

这意味着平台需要面向“运行中的应用实例”设计，而不是只面向静态代码组织设计。

## 已确认的 Mogan 架构事实

根据当前 `mogan` 代码库，Mogan 并不是一个需要从零设计连接层的黑盒应用。
它已经具备本地 server/client 机制：

- 应用侧可以启动本地 server
- 客户端可以连接这个 server
- 双方之间已经存在 Scheme 层的读写与远程调用机制
- 底层连接使用 TCP，默认端口 6561

因此，`mogan-test` 的正确方向不是重新发明一套控制协议，而是：

- 复用 Mogan 已有的本地 server/client 架构
- 在其上提供更稳定的命令行入口
- 将请求包装为适合代理使用的命令与结构化结果

当前已确认的相关能力包括：

- `server-start`
- `server-stop`
- `server-started?`
- `server-read`
- `server-write`
- `client-start`
- `client-stop`
- `client-read`
- `client-write`
- `enter-secure-mode`

服务端还存在远程命令分发与执行能力，因此平台第一阶段应优先验证：

1. 启动 Mogan
2. 启动或连接本地 server
3. 建立客户端连接
4. 发出一个最小真实命令
5. 收到结构化结果

## 强约束

- 必须使用 **Goldfish Scheme** 完成主平台逻辑。
- 禁止使用任何与 TeXmacs 相关的外部工具、平台、接口、命名迁移方案或替代实现。
- 唯一例外是 `mogan` 目录中已经存在、且作为 Mogan 现有组成部分保留的 TeXmacs 相关代码与机制；对这些现有内容可以读取、分析和复用，但不能把平台设计建立在额外引入或额外依赖 TeXmacs 之上。
- 必须优先面向“真实控制 Mogan”设计，而不是只做 stub。
- 测试时必须针对真实启动的完整 Mogan 进程执行。
- 测试链路必须先准备一个可连接的真实 Mogan 进程，再由测试平台连接该运行中的 server 并尝试执行操作。
- 当前阶段没有必要使用无头方式启动 Mogan。
- Mogan 当前的规范启动方式是先执行 `xmake b stem`，再执行 `xmake r stem`。
- 平台必须考虑“如何连接到运行中的 Mogan”这一层能力。
- 平台默认应复用 Mogan 已有的本地 server/client 机制，而不是另起一套协议。
- 可以保留 stub，但 stub 只能作为过渡层或回退层，不能成为长期主路径。
- 当前阶段不实现远程网络服务，优先实现本地命令行控制。
- 所有实现必须保持最小可用范围，避免过早抽象。
- 所有接口都应尽量面向自动化调用与结果验证，而不是面向人工交互。

## 本阶段范围

本阶段允许且优先实现以下内容：

1. 仓库基础骨架
2. 一个可直接从命令行调用的 Mogan 控制入口
3. 启动可连接的真实 Mogan 进程的最小入口
4. 请求/响应协议定义
5. 能力注册与路由入口
6. 基于现有 server/client 机制连接真实 Mogan 进程的最小链路
7. 至少一条真实的 Mogan 能力调用链路
8. 必要时保留最小 stub 作为回退或占位
9. 最小验证用例
10. 简短文档

## 第一优先级能力

平台优先支持这类能力，而不是抽象上的空路由：

- 启动可连接的真实 Mogan 进程，或连接到一个已启动的 Mogan 实例
- 明确区分“启动可连接的 Mogan 进程”和“测试平台连接到其 server”这两个阶段
- 复用现有 server/client 连接能力
- 打开或创建测试上下文
- 调用一个真实的 Mogan Scheme 动作
- 查询动作结果或当前状态
- 将结果以可断言的形式返回给命令行

## 控制原语

平台需要优先暴露这些可脚本化的低级能力，而不是只停留在高层封装：

- `state`
- `move-left` / `move-right` / `move-up` / `move-down`
- `move-start` / `move-end`
- `move-start-line` / `move-end-line`
- `move-start-paragraph` / `move-end-paragraph`
- `move-word-left` / `move-word-right`
- `move-to-line` / `move-to-column`
- `select-all` / `select-start` / `select-end` / `clear-selection`
- `undo` / `redo`
- `copy` / `cut` / `paste`
- `clear-undo-history`
- `insert-text` / `insert-return`
- `delete-left` / `delete-right`
- `save-buffer`
- `buffer-list`
- `open-file`
- `save-as`
- `revert-buffer`
- `close-buffer`
- `switch-buffer`
- `batch`
- `write-text` / `buffer-text` 作为更高层的兼容命令

## Target 和 Scenario

平台还需要支持命名 target profile，用来复用一组 live server 连接参数：

- `target save`
- `target show`
- `target list`
- `target run`

此外需要一个最小 scenario 入口，用来把多个控制原语串成一条可脚本化工作流：

- `scenario smoke-edit`
- `scenario batch-smoke`
- `scenario file-smoke`
- `scenario history-smoke`
- `scenario clipboard-smoke`

`batch` 命令应当支持在同一个 target profile 上串行执行多个步骤。

这些命令应该返回可脚本化结果，至少包含当前缓冲区、打开缓冲区列表、光标、选区、编辑历史和文本状态。

如果真实 Mogan 能力暂时无法完整接入，则必须明确：

- 哪一层已经是真实调用
- 哪一层仍然是 stub
- 下一步应从哪里继续接入

## 非目标

- 基于鼠标坐标或窗口焦点的 GUI 自动化
- 远程通信
- 复杂插件系统
- 与当前阶段无关的大规模抽象
- 为了追求架构完整而延后真实能力接入
- 将“只调用本仓库内 stub”当作完成目标

## 验收标准

- 仓库中存在清晰的骨架目录结构
- 主逻辑以 Goldfish Scheme 实现
- 存在一个明确的命令行入口，可以驱动平台执行动作
- 平台能够启动或连接到真实 Mogan
- 平台复用了现有的 Mogan 本地 server/client 机制，或明确说明了尚未复用的阻塞点
- 至少存在一条“命令行请求 -> 路由 -> 运行中的 Mogan 调用层 -> 结果”链路
- 至少存在一条低级控制链路，例如 `state -> move-* -> insert-text -> buffer-text`
- 至少存在一个可复用的 target profile 和一个可运行的 scenario workflow
- 至少存在一个可脚本化的 batch workflow
- 结果可被脚本化验证，而不是只靠人工观察
- 文档能说明平台目标、当前边界、真实接入点和仍然是 stub 的部分

## 实现原则

- 最小可用
- 真实能力优先于纯 stub
- 结构先于扩张
- 命名稳定
- 结果可验证
- 测试优先于扩展
