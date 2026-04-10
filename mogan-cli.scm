; mogan-cli.scm - Minimal Mogan test platform controller
;
; This CLI runs in Goldfish Scheme and provides:
;   - structured status about the required Mogan runtime workflow
;   - stable command routing for the test platform
;   - honest reporting for features that are not connected yet

(import (liii base)
        (liii json)
        (scheme base)
        (scheme file)
        (scheme process-context))

(define *mogan-root* "/home/mingshen/git/mogan")
(define *build-command* "xmake b stem")
(define *run-command* "xmake r stem")
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
    (cons "internal_command" *internal-command*)
    (cons "client_path" (built-client-path))
    (cons "client_built" (client-built?))
    (cons "gf_layer" "Routes commands and prepares process execution")
    (cons "mogan_layer" "Runs Scheme through `-x` inside the live Mogan runtime")
    (cons "connect_host" *default-host*)
    (cons "connect_port" *default-port*)
    (cons "connect_trace_path" *connect-trace-path*)
    (cons "next_step" "Use `mogan-cli connect --dry-run` to inspect the direct moganstem remote-login runtime path, then validate it against a running Mogan instance")
    (cons "connect_status" "runtime-skeleton")
    (cons "connect_note" "The full client still starts via `xmake r stem`; internal execution bypasses xmake run because the stem target drops extra arguments")))

(define (cmd-status args)
  (apply make-success (status-data)))

(define (cmd-workflow args)
  (make-success
    (cons "steps"
          "1. cd /home/mingshen/git/mogan 2. xmake b stem 3. xmake r stem in one client instance 4. Use mogan-cli connect or exec-internal to run direct moganstem `-x` commands in another runtime 5. Validate remote-login")
    (cons "constraints"
          "Do not use headless startup in this stage; do not introduce external TeXmacs tooling; only reuse TeXmacs-related mechanisms already inside mogan")
    (cons "layers"
          "gf handles CLI routing and process dispatch; Mogan internal Scheme runs through `-x` and is the only place where runtime glue is available")))

(define (cmd-connect args)
  (make-response
    "pending"
    (cons "required_order"
          "build-client -> start-client -> connect")
    (cons "host" *default-host*)
    (cons "port" *default-port*)
    (cons "trace_path" *connect-trace-path*)
    (cons "dispatch_path" "mogan-cli connect -> moganstem -d -debug-bench -x -> load mogan-runtime.scm -> mogan-test-remote-login")
    (cons "runtime_side" "remote-login is attempted inside Mogan through client-login-then")
    (cons "validation_state" "unverified")
    (cons "next_step" "Run `mogan-cli connect --dry-run` to inspect the exact runtime command, then validate it against a separately started Mogan client instance and inspect the trace file")))

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
                "status, workflow, connect, build-client, start-client, exec-internal")))))

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
  (display "  exec-internal - Start Mogan and execute internal Scheme through `-x`")
  (newline)
  (display "  connect       - Attempt remote-login through Mogan internal Scheme")
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
