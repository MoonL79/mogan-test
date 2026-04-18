(define *workflow-steps*
  "1. cd /home/mingshen/git/mogan 2. xmake b stem 3. Start a connectable server with `mogan-cli start-server` or an equivalent `moganstem -server -x '(load .../mogan-server-runtime.scm)'` 4. Save a target profile with `mogan-cli target save <name>` 5. Run `mogan-cli target run <name> state`, `mogan-cli batch <name> -- new-document -- insert-text ...`, `mogan-cli scenario smoke-edit`, `mogan-cli scenario batch-smoke <name>`, `mogan-cli scenario file-smoke <name>`, `mogan-cli scenario export-smoke <name>`, `mogan-cli scenario style-smoke <name>`, `mogan-cli scenario layout-smoke <name>`, `mogan-cli scenario search-smoke <name>`, `mogan-cli scenario history-smoke <name>`, or `mogan-cli scenario clipboard-smoke <name>` to drive the live server 6. Run `create-account`, `connect`, `write-text`, `buffer-text`, `export-buffer`, `set-main-style`, `set-document-language`, `add-style-package`, `remove-style-package`, `set-page-medium`, `set-page-type`, `set-page-orientation`, `ping`, or `new-document` as needed")

(define *workflow-constraints*
  "Do not introduce external TeXmacs tooling; reuse only the TeXmacs-related mechanisms already inside mogan; the controller side may use `-platform minimal` when the current environment cannot open the default Qt display")

(define *workflow-layers*
  "gf handles CLI routing and process dispatch; the server runtime loads test services plus the test-scoped login shim into the target moganstem; the controller runtime logs in and invokes those services through the existing client/server glue")

(define *workflow-formatting-policy*
  "写入 Mogan 时不要把 <with|...>、<math|...>、<matrix|...> 等原始 TeXmacs 标记当作正文文本直接插入；先写纯文本结构，再调用现有命令处理标题、强调、代码、链接、公式、分式、矩阵等结构；完成前自检文档中不应残留原始 <tag|...> 文本")

(define *workflow-next-step*
  "Build with `xmake b stem`, start a connectable server with `mogan-cli start-server` or an equivalent `moganstem -server -x '(load .../mogan-server-runtime.scm)'`, save a target profile with `mogan-cli target save`, then use `target run`, `batch`, `scenario smoke-edit`, `scenario batch-smoke`, `scenario file-smoke`, `scenario export-smoke`, `scenario style-smoke`, `scenario layout-smoke`, `scenario search-smoke`, `scenario history-smoke`, or `scenario clipboard-smoke` to drive the live server")

(define *connect-required-order* "build-client -> start-server -> create-account -> connect")
(define *connect-dispatch-path* "mogan-cli connect -> controller moganstem -platform minimal -x -> load mogan-runtime.scm -> remote-login")
(define *connect-runtime-side* "remote-login and follow-up commands run through explicit client-start, enter-secure-mode, and client-remote-eval")
(define *connect-next-step*
  "If a connectable server is already running with `mogan-server-runtime.scm` loaded, call `./mogan-cli create-account` once for the target credentials and then run `./mogan-cli connect`; add `state`, `move-*`, `select-*`, `undo`, `redo`, `copy`, `cut`, `paste`, `clear-undo-history`, `insert-text`, `delete-*`, `save-buffer`, `export-buffer`, `set-main-style`, `set-document-language`, `add-style-package`, `remove-style-package`, `set-page-medium`, `set-page-type`, `set-page-orientation`, `buffer-list`, `open-file`, `save-as`, `revert-buffer`, `close-buffer`, `search-state`, `search-set`, `search-next`, `search-prev`, `search-first`, `search-last`, `replace-set`, `replace-one`, `replace-all`, `write-text`, `buffer-text`, `batch`, `scenario smoke-edit`, `scenario batch-smoke`, `scenario file-smoke`, `scenario export-smoke`, `scenario style-smoke`, `scenario layout-smoke`, `scenario search-smoke`, `scenario history-smoke`, or `scenario clipboard-smoke` after login succeeds")

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
    (cons "validation_state" "requires-running-server-instance")
    (cons "current_result" "The shell wrapper already drives a real controller runtime; login succeeds or fails entirely against the live `-server` instance and supplied credentials")
    (cons "next_step" *connect-next-step*)))
