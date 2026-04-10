;; mogan-runtime.scm - Code intended to run inside Mogan via `-x`

(use-modules (client client-base))

(define *connect-trace-path* "/tmp/mogan-test-connect-trace.log")
(define *remote-login-finished?* #f)
(define *remote-login-client* -1)

(define (runtime-log message)
  (string-append-to-file
    (string-append message "\n")
    *connect-trace-path*)
  (display message)
  (newline))

(define (mogan-test-runtime-status)
  (runtime-log
    "mogan-runtime: loaded inside Mogan; runtime glue is available here; remote-login skeleton is wired"))

(define (mogan-test-remote-login server-name pseudo passwd)
  (set! *remote-login-finished?* #f)
  (set! *remote-login-client* -1)
  (runtime-log "mogan-runtime: attempting remote-login through explicit client-start flow")
  (delayed
    (:idle 5000)
    (when (not *remote-login-finished?*)
      (set! *remote-login-finished?* #t)
      (when (>= *remote-login-client* 0)
        (client-stop *remote-login-client*))
      (runtime-log "mogan-runtime: remote-login timed out")
      (quit-TeXmacs)))
  (set! *remote-login-client* (client-start server-name))
  (runtime-log
    (string-append
      "mogan-runtime: client-start returned "
      (number->string *remote-login-client*)))
  (if (< *remote-login-client* 0)
      (begin
        (set! *remote-login-finished?* #t)
        (runtime-log "mogan-runtime: client-start failed")
        (quit-TeXmacs))
      (begin
        (runtime-log "mogan-runtime: entering secure mode")
        (enter-secure-mode *remote-login-client*)
        (client-remote-eval*
          *remote-login-client*
          `(remote-login ,pseudo ,passwd)
          (lambda (ret)
            (set! *remote-login-finished?* #t)
            (client-stop *remote-login-client*)
            (runtime-log
              (string-append "mogan-runtime: remote-login callback " ret))
            (quit-TeXmacs))))))

(mogan-test-runtime-status)
