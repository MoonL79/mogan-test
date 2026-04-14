; mogan-cli.scm - Minimal Mogan test platform controller
;
; This CLI runs in Goldfish Scheme and provides:
;   - structured status about the required Mogan runtime workflow
;   - stable command routing for the test platform
;   - honest reporting about the live `-server` connection model

(import (liii base)
        (liii json)
        (scheme base)
        (scheme file)
        (scheme process-context))

(define *mogan-root* "/home/mingshen/git/mogan")
(define *build-command* "xmake b stem")
(define *run-command* "xmake r stem")
(define *start-server-command*
  "TEXMACS_PATH=/home/mingshen/git/mogan/TeXmacs <moganstem> -server -x <runtime>")
(define *internal-command* "TEXMACS_PATH=/home/mingshen/git/mogan/TeXmacs <moganstem> -d -debug-bench -x <scheme>")
(define *default-host* "127.0.0.1")
(define *default-port* 6561)

(define (make-response status data)
  (cons (cons "status" status) data))

(define (make-success . data)
  (make-response "ok" data))

(define (make-error message . extra)
  (make-response "error" (cons (cons "message" message) extra)))

(define *connect-trace-path* "/tmp/mogan-test-connect-trace.log")
(define *server-trace-path* "/tmp/mogan-test-server-trace.log")
(define *runtime-result-path* "/tmp/mogan-test-runtime-result.txt")
(define *runtime-output-path* "/tmp/mogan-test-runtime-output.log")

(define (candidate-client-paths)
  (list
    (string-append *mogan-root* "/build/linux/x86_64/debug/moganstem")
    (string-append *mogan-root* "/build/linux/x86_64/release/moganstem")))

(define (built-client-path)
  (let loop ((paths (candidate-client-paths)))
    (cond
      ((null? paths)
       (car (candidate-client-paths)))
      ((file-exists? (car paths))
       (car paths))
      (else
       (loop (cdr paths))))))

(define (client-built?)
  (let loop ((paths (candidate-client-paths)))
    (cond
      ((null? paths) #f)
      ((file-exists? (car paths)) #t)
      (else (loop (cdr paths))))))

(define (string-suffix? suffix s)
  (let ((suffix-length (string-length suffix))
        (s-length (string-length s)))
    (and (>= s-length suffix-length)
         (equal? (substring s (- s-length suffix-length) s-length) suffix))))

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
    (cons "control_surface" "state, move-*, select-*, undo, redo, copy, cut, paste, clear-undo-history, insert-text, delete-*, save-buffer, switch-buffer")
    (cons "batch_command" "./mogan-cli batch smoke -- new-document -- insert-text ...")
    (cons "scenario_command" "./mogan-cli scenario smoke-edit")
    (cons "scenario_batch_command" "./mogan-cli scenario batch-smoke smoke")
    (cons "scenario_file_command" "./mogan-cli scenario file-smoke smoke /tmp/mogan-test-file-smoke.tm")
    (cons "scenario_history_command" "./mogan-cli scenario history-smoke smoke")
    (cons "scenario_clipboard_command" "./mogan-cli scenario clipboard-smoke smoke")
    (cons "target_command" "./mogan-cli target run <name> <command>")
    (cons "target_store" "${MOGAN_TEST_TARGET_DIR:-$HOME/.config/mogan-test/targets}")
    (cons "state_command" "./mogan-cli state")
    (cons "file_control_surface" "buffer-list, open-file, save-as, revert-buffer, close-buffer")
    (cons "service_runtime_requirement" "create-account, login, and custom service commands require the target server instance to load mogan-server-runtime.scm")
    (cons "auth_model" "mogan-test currently uses a test-scoped users.scm account store and server-side login shim inside mogan-server-runtime.scm")
    (cons "next_step" "Build with `xmake b stem`, start a connectable server with `mogan-cli start-server` or an equivalent `moganstem -server -x '(load .../mogan-server-runtime.scm)'`, save a target profile with `mogan-cli target save`, then use `target run`, `batch`, `scenario smoke-edit`, `scenario batch-smoke`, `scenario file-smoke`, `scenario history-smoke`, or `scenario clipboard-smoke` to drive the live server")
    (cons "connect_status" "explicit-server-path-ready-for-live-validation")
    (cons "connect_note" "The real control path is an explicit `moganstem -server` instance; `xmake r stem` remains useful for product startup checks but is not treated as proof of a connectable local server")
    (cons "connect_blocker" "Cross-process validation still depends on a reachable local `-server` instance and the test runtime loaded from mogan-server-runtime.scm")))

(define (cmd-status args)
  (apply make-success (status-data)))

(define (cmd-workflow args)
  (make-success
    (cons "steps"
          "1. cd /home/mingshen/git/mogan 2. xmake b stem 3. Start a connectable server with `mogan-cli start-server --platform minimal` or an equivalent `moganstem -server -x '(load .../mogan-server-runtime.scm)'` 4. Save a target profile with `mogan-cli target save <name>` 5. Run `mogan-cli target run <name> state`, `mogan-cli batch <name> -- new-document -- insert-text ...`, `mogan-cli scenario smoke-edit`, `mogan-cli scenario batch-smoke <name>`, `mogan-cli scenario file-smoke <name>`, `mogan-cli scenario history-smoke <name>`, or `mogan-cli scenario clipboard-smoke <name>` to drive the live server 6. Run `create-account`, `connect`, `write-text`, `buffer-text`, `ping`, or `new-document` as needed")
    (cons "constraints"
          "Do not introduce external TeXmacs tooling; reuse only the TeXmacs-related mechanisms already inside mogan; the controller side may use `-platform minimal` when the current environment cannot open the default Qt display")
    (cons "layers"
          "gf handles CLI routing and process dispatch; the server runtime loads test services plus the test-scoped login shim into the target moganstem; the controller runtime logs in and invokes those services through the existing client/server glue")))

(define (cmd-connect args)
  (make-success
    (cons "required_order"
          "build-client -> start-server -> create-account -> connect")
    (cons "host" *default-host*)
    (cons "port" *default-port*)
    (cons "trace_path" *connect-trace-path*)
    (cons "dispatch_path" "mogan-cli connect -> controller moganstem -platform minimal -x -> load mogan-runtime.scm -> remote-login")
    (cons "runtime_side" "remote-login and follow-up commands run through explicit client-start, enter-secure-mode, and client-remote-eval")
    (cons "validation_state" "requires-running-server-instance")
    (cons "current_result" "The shell wrapper already drives a real controller runtime; login succeeds or fails entirely against the live `-server` instance and supplied credentials")
    (cons "next_step" "If a connectable server is already running with `mogan-server-runtime.scm` loaded, call `./mogan-cli create-account` once for the target credentials and then run `./mogan-cli connect`; add `state`, `move-*`, `select-*`, `undo`, `redo`, `copy`, `cut`, `paste`, `clear-undo-history`, `insert-text`, `delete-*`, `save-buffer`, `buffer-list`, `open-file`, `save-as`, `revert-buffer`, `close-buffer`, `write-text`, `buffer-text`, `batch`, `scenario smoke-edit`, `scenario batch-smoke`, `scenario file-smoke`, `scenario history-smoke`, or `scenario clipboard-smoke` after login succeeds")))

(define *commands*
  `(("status" . ,cmd-status)
    ("workflow" . ,cmd-workflow)
    ("connect" . ,cmd-connect)))

(define (dispatch command args)
  (let ((handler (assoc command *commands*)))
    (if handler
        ((cdr handler) args)
          (make-error
           (string-append "Unknown command: " command)
           (cons "available"
                "status, workflow, connect, build-client, start-client, start-server, exec-internal, create-account, ping, current-buffer, new-document, write-text, buffer-text, state, move-left, move-right, move-up, move-down, move-start, move-end, move-start-line, move-end-line, move-start-paragraph, move-end-paragraph, move-word-left, move-word-right, move-to-line, move-to-column, select-all, select-start, select-end, clear-selection, undo, redo, copy, cut, paste, clear-undo-history, insert-text, insert-return, delete-left, delete-right, save-buffer, buffer-list, open-file, save-as, revert-buffer, close-buffer, switch-buffer, batch, target, session, scenario")))))

(define (show-usage)
  (display "Usage: mogan-cli <command> [args...]")
  (newline)
  (display "Commands:")
  (newline)
  (display "  status        - Show current runtime and connection status as JSON")
  (newline)
  (display "  workflow      - Show the required Mogan startup workflow")
  (newline)
  (display "  build-client  - Build Mogan with `xmake b stem`")
  (newline)
  (display "  start-client  - Start a full Mogan client with `xmake r stem`")
  (newline)
  (display "  start-server  - Start a connectable Mogan client with `-server` enabled")
  (newline)
  (display "  exec-internal - Start Mogan and execute internal Scheme through `-x`")
  (newline)
  (display "  create-account - Create a test account through the remote service path")
  (newline)
  (display "  connect       - Attempt remote-login through Mogan internal Scheme")
  (newline)
  (display "  ping          - Call the server-side ping service")
  (newline)
  (display "  current-buffer - Query the current buffer from the running Mogan instance")
  (newline)
  (display "  new-document  - Create a new document through the running Mogan instance")
  (newline)
  (display "  write-text    - Replace the current buffer body with plain text")
  (newline)
  (display "  buffer-text   - Read back the current buffer body as plain text")
  (newline)
  (display "  state         - Inspect buffer, cursor, selection, and text state")
  (newline)
  (display "  move/select   - Cursor, selection, history, clipboard, insert, delete, save, and switch primitives")
  (newline)
  (display "  batch         - Run a sequence of control commands against one target")
  (newline)
  (display "  target        - Save, show, list, delete, or use a named target profile")
  (newline)
  (display "  session       - Alias for target")
  (newline)
  (display "  scenario      - Run a named batch workflow")
  (newline)
  (display "  scenario batch-smoke - Run a target-backed low-level smoke workflow")
  (newline)
  (display "  scenario history-smoke - Run a target-backed undo/redo workflow")
  (newline)
  (display "  scenario clipboard-smoke - Run a target-backed clipboard workflow")
  (newline))

(define (script-arg? arg)
  (and (> (string-length arg) 13)
       (string-suffix? "mogan-cli.scm" arg)))

(define (status-ok? result)
  (equal? (cdr (assoc "status" result)) "ok"))

(define (main)
  (let ((args (command-line)))
    (let loop ((remaining args)
               (found-script #f))
      (cond
        ((null? remaining)
         (show-usage)
         (exit 1))
        (found-script
         (if (null? remaining)
             (begin
               (show-usage)
               (exit 1))
             (let ((command (car remaining))
                   (cmd-args (cdr remaining)))
               (let ((result (dispatch command cmd-args)))
                 (display (json->string result))
                 (newline)
                 (if (status-ok? result)
                     (exit 0)
                     (exit 1))))))
        ((script-arg? (car remaining))
         (loop (cdr remaining) #t))
        (else
         (loop (cdr remaining) found-script))))))

(main)
