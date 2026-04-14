;; mogan-runtime.scm - Control-side runtime loaded inside moganstem via `-x`

(use-modules (client client-base))

(define *mogan-test-result-path* "/tmp/mogan-test-runtime-result.txt")
(define *mogan-test-trace-path* "/tmp/mogan-test-connect-trace.log")
(define *mogan-test-finished?* #f)
(define *mogan-test-client* -1)
(define *mogan-test-secure-mode?* #f)

(define (runtime-log message)
  (string-append-to-file
    (string-append message "\n")
    *mogan-test-trace-path*)
  (display message)
  (newline))

(define (write-result status value)
  (string-save
    (string-append status "\n" value "\n")
    *mogan-test-result-path*))

(define (close-client!)
  (when (>= *mogan-test-client* 0)
    (client-stop *mogan-test-client*)
    (set! *mogan-test-client* -1)))

(define (finish! status value)
  (when (not *mogan-test-finished?*)
    (set! *mogan-test-finished?* #t)
    (write-result status value)
    (runtime-log (string-append "mogan-runtime: " status " -> " value))
    (close-client!)
    (quit-TeXmacs)))

(define (start-timeout! label)
  (delayed
    (:idle 5000)
    (when (not *mogan-test-finished?*)
      (finish! "error" (string-append label " timed out")))))

(define (start-client! server-name)
  (set! *mogan-test-client* (client-start server-name))
  (runtime-log
    (string-append
      "mogan-runtime: client-start returned "
      (number->string *mogan-test-client*)))
  (if (< *mogan-test-client* 0)
      (begin
        (finish! "error" "client-start failed")
        #f)
      #t))

(define (enter-secure-mode-if-needed!)
  (when *mogan-test-secure-mode?*
    (runtime-log "mogan-runtime: entering secure mode")
    (enter-secure-mode *mogan-test-client*)))

(define (remote-call! command on-success on-error)
  (runtime-log
    (string-append
      "mogan-runtime: client-remote-eval <- "
      (object->string* command)))
  (client-remote-eval
    *mogan-test-client*
    command
    (lambda (ret)
      (runtime-log
        (string-append
          "mogan-runtime: client-remote-result -> "
          (object->string* ret)))
      (on-success ret))
    (lambda (err)
      (runtime-log
        (string-append
          "mogan-runtime: client-remote-error -> "
          (object->string* err)))
      (on-error err))))

(define (mogan-test-runtime-status)
  (write-result "ok" "runtime-loaded")
  (runtime-log "mogan-runtime: loaded inside Mogan"))

(define (mogan-test-create-account server-name pseudo name passwd email)
  (set! *mogan-test-finished?* #f)
  (set! *mogan-test-client* -1)
  (runtime-log "mogan-runtime: attempting new-account")
  (start-timeout! "new-account")
  (when (start-client! server-name)
    (enter-secure-mode-if-needed!)
    (remote-call!
      `(mogan-test-bootstrap-account ,pseudo ,name ,passwd ,email)
      (lambda (ret)
        (if (or (equal? ret "done")
                (equal? ret "exists"))
            (finish! "ok" ret)
            (finish! "error" ret)))
      (lambda (err)
        (finish! "error" err)))))

(define (mogan-test-connect server-name pseudo passwd)
  (set! *mogan-test-finished?* #f)
  (set! *mogan-test-client* -1)
  (runtime-log "mogan-runtime: attempting remote-login")
  (start-timeout! "remote-login")
  (when (start-client! server-name)
    (enter-secure-mode-if-needed!)
    (remote-call!
      `(remote-login ,pseudo ,passwd)
      (lambda (ret)
        (if (equal? ret "ready")
            (finish! "ok" ret)
            (finish! "error" ret)))
      (lambda (err)
        (finish! "error" err)))))

(define (mogan-test-run-command server-name pseudo passwd command)
  (set! *mogan-test-finished?* #f)
  (set! *mogan-test-client* -1)
  (runtime-log
    (string-append
      "mogan-runtime: attempting command "
      (object->string* command)))
  (start-timeout! "remote-command")
  (when (start-client! server-name)
    (enter-secure-mode-if-needed!)
    (remote-call!
      `(remote-login ,pseudo ,passwd)
      (lambda (ret)
        (if (not (equal? ret "ready"))
            (finish! "error" ret)
            (remote-call!
              command
              (lambda (command-ret)
                (finish! "ok" (object->string* command-ret)))
              (lambda (command-err)
                (finish! "error" command-err)))))
      (lambda (err)
        (finish! "error" err)))))

(mogan-test-runtime-status)
