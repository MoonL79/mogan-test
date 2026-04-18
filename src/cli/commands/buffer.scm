(define *control-surface*
  "state, move-*, select-*, undo, redo, copy, cut, paste, clear-undo-history, insert-text, insert-return, exit-right, insert-section, insert-subsection, insert-subsubsection, delete-*, save-buffer, export-buffer, set-main-style, set-document-language, add-style-package, remove-style-package, set-page-medium, set-page-type, set-page-orientation, switch-buffer")

(define *file-control-surface*
  "buffer-list, open-file, save-as, export-buffer, revert-buffer, close-buffer")

(define *style-control-surface*
  "set-main-style, set-document-language, add-style-package, remove-style-package")

(define *layout-control-surface*
  "set-page-medium, set-page-type, set-page-orientation")

(define *search-control-surface*
  "search-state, search-set, search-next, search-prev, search-first, search-last, replace-set, replace-one, replace-all")

(define *shell-entry-script* "./bin/mogan-cli")
(define *shell-lib-dir* "./bin/lib/mogan-cli")
(define *scheme-command-dir* "./src/cli/commands")
(define *runtime-dir* "./src/cli/runtime")
(define *formatting-policy-path* "./playbooks/assets/mogan-formatting-agent-prompt.md")
(define *formatting-policy-embedded*
  "写入 Mogan 时不要把 <with|...>、<math|...>、<matrix|...> 等原始 TeXmacs 标记当作正文文本直接插入；先写纯文本结构，再用现有命令处理标题、强调、代码、链接、公式、分式、矩阵等结构；只要插入了任何结构化节点，紧接着优先调用 `exit-right` 跳出当前结构，再根据需要使用 `insert-return` 和 `insert-text` 继续写内容；完成前自检文档中不应残留原始 <tag|...> 文本")
(define *split-layout*
  "shell 入口位于 `bin/mogan-cli`；shell 命令处理位于 `bin/lib/mogan-cli/*.sh`；Scheme 的 status/workflow 路由位于 `src/cli/mogan-cli.scm` 和 `src/cli/commands/*.scm`；live controller/server runtime 位于 `src/cli/runtime/*.scm`")

(define (status-data)
  (list
    (cons "mogan_root" *mogan-root*)
    (cons "build_command" *build-command*)
    (cons "run_command" *run-command*)
    (cons "start_server_command" *start-server-command*)
    (cons "internal_command" *internal-command*)
    (cons "client_path" (built-client-path))
    (cons "client_built" (client-built?))
    (cons "gf_layer" "负责命令路由并准备进程执行")
    (cons "mogan_layer" "通过 `-x` 在 live Mogan runtime 内执行 Scheme")
    (cons "connect_host" *default-host*)
    (cons "connect_port" *default-port*)
    (cons "connect_trace_path" *connect-trace-path*)
    (cons "server_trace_path" *server-trace-path*)
    (cons "runtime_result_path" *runtime-result-path*)
    (cons "runtime_output_path" *runtime-output-path*)
    (cons "traces_command" "./mogan-cli traces")
    (cons "controller_platform" "minimal")
    (cons "shell_entry_script" *shell-entry-script*)
    (cons "shell_lib_dir" *shell-lib-dir*)
    (cons "scheme_command_dir" *scheme-command-dir*)
    (cons "runtime_dir" *runtime-dir*)
    (cons "formatting_policy_path" *formatting-policy-path*)
    (cons "formatting_policy_embedded" *formatting-policy-embedded*)
    (cons "split_layout" *split-layout*)
    (cons "control_surface" *control-surface*)
    (cons "batch_command" *batch-command*)
    (cons "scenario_command" "./mogan-cli scenario smoke-edit")
    (cons "scenario_batch_command" *scenario-batch-command*)
    (cons "scenario_file_command" *scenario-file-command*)
    (cons "scenario_export_command" *scenario-export-command*)
    (cons "scenario_style_command" *scenario-style-command*)
    (cons "scenario_layout_command" *scenario-layout-command*)
    (cons "scenario_search_command" *scenario-search-command*)
    (cons "scenario_history_command" *scenario-history-command*)
    (cons "scenario_clipboard_command" *scenario-clipboard-command*)
    (cons "target_command" *target-command*)
    (cons "target_store" "${MOGAN_TEST_TARGET_DIR:-$HOME/.config/mogan-test/targets}")
    (cons "state_command" "./mogan-cli state")
    (cons "file_control_surface" *file-control-surface*)
    (cons "style_control_surface" *style-control-surface*)
    (cons "layout_control_surface" *layout-control-surface*)
    (cons "search_control_surface" *search-control-surface*)
    (cons "service_runtime_requirement" "`create-account`、`login` 和自定义服务命令都要求目标 server 实例加载 `mogan-server-runtime.scm`")
    (cons "auth_model" "`mogan-test` 当前使用测试专用的 `users.scm` 账户存储，以及位于 `mogan-server-runtime.scm` 中的 server 侧登录 shim")
    (cons "next_step" *workflow-next-step*)
    (cons "connect_status" "显式 server 路径已准备好进行 live 验证")
    (cons "connect_note" "真实控制路径依赖显式启动的 `moganstem -server` 实例；`xmake r stem` 仍可用于产品启动检查，但不能视为本地 server 可连接的证明")
    (cons "connect_blocker" "跨进程验证仍然依赖一个可达的本地 `-server` 实例，以及已加载 `mogan-server-runtime.scm` 的测试运行时")))

(define (cmd-status args)
  (apply make-success (status-data)))
