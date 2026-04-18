(define *workflow-steps*
  "1. 进入 `/home/mingshen/git/mogan` 目录 2. 执行 `xmake b stem` 3. 使用 `mogan-cli start-server` 或等价的 `moganstem -server -x '(load .../mogan-server-runtime.scm)'` 启动可连接的 server 4. 使用 `mogan-cli target save <name>` 保存 target 配置 5. 通过 `mogan-cli target run <name> state`、`mogan-cli batch <name> -- new-document -- insert-text ...`、`mogan-cli scenario smoke-edit`、`mogan-cli scenario batch-smoke <name>`、`mogan-cli scenario file-smoke <name>`、`mogan-cli scenario export-smoke <name>`、`mogan-cli scenario style-smoke <name>`、`mogan-cli scenario layout-smoke <name>`、`mogan-cli scenario search-smoke <name>`、`mogan-cli scenario history-smoke <name>`、`mogan-cli scenario clipboard-smoke <name>` 驱动 live server 6. 按需要执行 `create-account`、`connect`、`write-text`、`buffer-text`、`export-buffer`、`set-main-style`、`set-document-language`、`add-style-package`、`remove-style-package`、`set-page-medium`、`set-page-type`、`set-page-orientation`、`insert-section`、`insert-subsection`、`insert-subsubsection`、`exit-right`、`insert-return`、`ping`、`new-document` 等命令")

(define *workflow-constraints*
  "不要引入额外的 TeXmacs 外部工具；只复用 mogan 内部已有的 TeXmacs 相关机制；如果当前环境无法打开默认 Qt 显示，controller 侧可以使用 `-platform minimal`")

(define *workflow-layers*
  "`gf` 负责 CLI 路由和进程调度；server runtime 会把测试服务和测试专用登录 shim 加载到目标 `moganstem` 中；controller runtime 通过现有 client/server 胶水逻辑登录并调用这些服务")

(define *workflow-formatting-policy*
  "写入 Mogan 时不要把 <with|...>、<math|...>、<matrix|...> 等原始 TeXmacs 标记当作正文文本直接插入；先写纯文本结构，再调用现有命令处理标题、强调、代码、链接、公式、分式、矩阵等结构；只要插入了任何结构化节点，紧接着优先调用 `exit-right` 跳出当前结构，再根据需要使用 `insert-return` 和 `insert-text` 继续写内容；如果使用 `insert-section`、`insert-subsection`、`insert-subsubsection`，标题文本本身不要携带显式编号，编号交给环境自动生成；完成前自检文档中不应残留原始 <tag|...> 文本")

(define *workflow-next-step*
  "先用 `xmake b stem` 构建，再用 `mogan-cli start-server` 或等价的 `moganstem -server -x '(load .../mogan-server-runtime.scm)'` 启动可连接的 server，接着用 `mogan-cli target save` 保存 target 配置，然后通过 `target run`、`batch`、`scenario smoke-edit`、`scenario batch-smoke`、`scenario file-smoke`、`scenario export-smoke`、`scenario style-smoke`、`scenario layout-smoke`、`scenario search-smoke`、`scenario history-smoke`、`scenario clipboard-smoke` 驱动 live server；凡是插入 section、subsection、公式、矩阵、表格、强调、链接等结构，都先执行 `exit-right`，再按需要执行 `insert-return` 和正文写入；section 类标题不要手写编号，交给环境自动编号")

(define *connect-required-order* "build-client -> start-server -> create-account -> connect")
(define *connect-dispatch-path* "`mogan-cli connect` -> controller `moganstem -platform minimal -x` -> 加载 `mogan-runtime.scm` -> `remote-login`")
(define *connect-runtime-side* "`remote-login` 以及后续命令会通过显式的 `client-start`、`enter-secure-mode` 和 `client-remote-eval` 执行")
(define *connect-next-step*
  "如果一个带 `mogan-server-runtime.scm` 的可连接 server 已在运行，则先为目标凭据执行一次 `./mogan-cli create-account`，再执行 `./mogan-cli connect`；登录成功后，可继续使用 `state`、`move-*`、`select-*`、`undo`、`redo`、`copy`、`cut`、`paste`、`clear-undo-history`、`insert-text`、`insert-return`、`exit-right`、`insert-section`、`insert-subsection`、`insert-subsubsection`、`delete-*`、`save-buffer`、`export-buffer`、`set-main-style`、`set-document-language`、`add-style-package`、`remove-style-package`、`set-page-medium`、`set-page-type`、`set-page-orientation`、`buffer-list`、`open-file`、`save-as`、`revert-buffer`、`close-buffer`、`search-state`、`search-set`、`search-next`、`search-prev`、`search-first`、`search-last`、`replace-set`、`replace-one`、`replace-all`、`write-text`、`buffer-text`、`batch`、`scenario smoke-edit`、`scenario batch-smoke`、`scenario file-smoke`、`scenario export-smoke`、`scenario style-smoke`、`scenario layout-smoke`、`scenario search-smoke`、`scenario history-smoke`、`scenario clipboard-smoke`")

(define (cmd-workflow args)
  (make-success
    (cons "steps" *workflow-steps*)
    (cons "constraints" *workflow-constraints*)
    (cons "layers" *workflow-layers*)
    (cons "formatting_policy_path" "./playbooks/assets/mogan-formatting-agent-prompt.md")
    (cons "formatting_policy_embedded" *workflow-formatting-policy*)))

(define (cmd-connect args)
  (make-success
    (cons "required_order" *connect-required-order*)
    (cons "host" *default-host*)
    (cons "port" *default-port*)
    (cons "trace_path" *connect-trace-path*)
    (cons "dispatch_path" *connect-dispatch-path*)
    (cons "runtime_side" *connect-runtime-side*)
    (cons "formatting_policy_path" "./playbooks/assets/mogan-formatting-agent-prompt.md")
    (cons "formatting_policy_embedded" *workflow-formatting-policy*)
    (cons "validation_state" "需要一个正在运行的 server 实例")
    (cons "current_result" "shell 封装层已经在驱动真实的 controller runtime；登录是否成功完全取决于 live `-server` 实例和所提供的凭据")
    (cons "next_step" *connect-next-step*)))
