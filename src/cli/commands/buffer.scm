(define *control-surface*
  "state, move-*, select-*, undo, redo, copy, cut, paste, clear-undo-history, insert-text, delete-*, save-buffer, export-buffer, set-main-style, set-document-language, add-style-package, remove-style-package, set-page-medium, set-page-type, set-page-orientation, switch-buffer")

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
(define *split-layout*
  "shell entry in bin/mogan-cli; shell command handlers in bin/lib/mogan-cli/*.sh; Scheme status/workflow router in src/cli/mogan-cli.scm and src/cli/commands/*.scm; live controller/server runtimes in src/cli/runtime/*.scm")

(define (status-data)
  (list
    (cons "mogan_root" *mogan-root*)
    (cons "build_command" *build-command*)
    (cons "run_command" *run-command*)
    (cons "start_server_command" *start-server-command*)
    (cons "internal_command" *internal-command*)
    (cons "client_path" (built-client-path))
    (cons "client_built" (client-built?))
    (cons "gf_layer" "Routes commands and prepares process execution")
    (cons "mogan_layer" "Runs Scheme through `-x` inside the live Mogan runtime")
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
    (cons "service_runtime_requirement" "create-account, login, and custom service commands require the target server instance to load mogan-server-runtime.scm")
    (cons "auth_model" "mogan-test currently uses a test-scoped users.scm account store and server-side login shim inside mogan-server-runtime.scm")
    (cons "next_step" *workflow-next-step*)
    (cons "connect_status" "explicit-server-path-ready-for-live-validation")
    (cons "connect_note" "The real control path is an explicit `moganstem -server` instance; `xmake r stem` remains useful for product startup checks but is not treated as proof of a connectable local server")
    (cons "connect_blocker" "Cross-process validation still depends on a reachable local `-server` instance and the test runtime loaded from mogan-server-runtime.scm")))

(define (cmd-status args)
  (apply make-success (status-data)))
