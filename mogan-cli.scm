; mogan-cli.scm - Minimal Mogan test platform controller
;
; This CLI runs in Goldfish Scheme and provides:
;   - structured status about the required Mogan runtime workflow
;   - stable command routing for the test platform
;   - honest reporting for features that are not connected yet

(import (liii base)
        (liii json)
        (scheme base)
        (scheme process-context))

(define *mogan-root* "/home/mingshen/git/mogan")
(define *build-command* "xmake b stem")
(define *run-command* "xmake r stem")
(define *internal-command* "xmake r stem -x <scheme>")
(define *default-host* "127.0.0.1")
(define *default-port* 6561)

(define (make-response status data)
  (cons (cons "status" status) data))

(define (make-success . data)
  (make-response "ok" data))

(define (make-error message . extra)
  (make-response "error" (cons (cons "message" message) extra)))

(define (built-client-path)
  (string-append *mogan-root* "/build/linux/x86_64/debug/moganstem"))

(define (string-suffix? suffix s)
  (let ((suffix-length (string-length suffix))
        (s-length (string-length s)))
    (and (>= s-length suffix-length)
         (equal? (substring s (- s-length suffix-length) s-length) suffix))))

(define (file-exists? path)
  (guard (exn
           (else #f))
    (call-with-input-file path
      (lambda (port)
        (close-input-port port)
        #t))))

(define (status-data)
  (list
    (cons "mogan_root" *mogan-root*)
    (cons "build_command" *build-command*)
    (cons "run_command" *run-command*)
    (cons "internal_command" *internal-command*)
    (cons "client_path" (built-client-path))
    (cons "client_built" (file-exists? (built-client-path)))
    (cons "gf_layer" "Routes commands and prepares process execution")
    (cons "mogan_layer" "Runs Scheme through `-x` inside the live Mogan runtime")
    (cons "connect_host" *default-host*)
    (cons "connect_port" *default-port*)
    (cons "next_step" "Use `mogan-cli exec-internal --dry-run` to inspect the Mogan runtime dispatch path, then wire remote-login on top of it")
    (cons "connect_status" "stub")
    (cons "connect_note" "The runtime dispatch path is real; the remote-login connection flow is not wired yet")))

(define (cmd-status args)
  (apply make-success (status-data)))

(define (cmd-workflow args)
  (make-success
    (cons "steps"
          "1. cd /home/mingshen/git/mogan 2. xmake b stem 3. xmake r stem or mogan-cli exec-internal 4. Wire remote-login on top of the runtime dispatch path")
    (cons "constraints"
          "Do not use headless startup in this stage; do not introduce external TeXmacs tooling; only reuse TeXmacs-related mechanisms already inside mogan")
    (cons "layers"
          "gf handles CLI routing and process dispatch; Mogan internal Scheme runs through `-x` and is the only place where runtime glue is available")))

(define (cmd-connect args)
  (make-error
    "Connection layer not implemented yet"
    (cons "required_order"
          "build-client -> exec-internal or start-client -> connect")
    (cons "host" *default-host*)
    (cons "port" *default-port*)
    (cons "dispatch_path" "Use `mogan-cli exec-internal` to execute Scheme inside Mogan before wiring remote-login")
    (cons "next_step" "Implement a real remote-login path on top of the Mogan internal runtime dispatch entry")))

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
  (display "  connect       - Reserved entry for test-platform connection")
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
