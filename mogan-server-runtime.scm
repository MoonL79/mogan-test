;; mogan-server-runtime.scm - Server-side test services loaded via `-x`

(use-modules (server server-base))

(define *mogan-test-server-trace-path* "/tmp/mogan-test-server-trace.log")
(define mogan-test-logged-table (make-ahash-table))

(define (mogan-test-server-log message)
  (string-append-to-file
    (string-append message "\n")
    *mogan-test-server-trace-path*))

(mogan-test-server-log "mogan-server-runtime: loaded")

(tm-define (server-add client)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: server-add client="
      (number->string client)))
  (former client))

(tm-define (server-eval envelope cmd)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: server-eval "
      (object->string* cmd)))
  (former envelope cmd))

(tm-define (server-return envelope ret-val)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: server-return "
      (object->string* ret-val)))
  (former envelope ret-val))

(tm-define (server-error envelope error-msg)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: server-error "
      (object->string* error-msg)))
  (former envelope error-msg))

(define (mogan-test-users-path)
  "$TEXMACS_HOME_PATH/server/users.scm")

(define (mogan-test-load-users)
  (let ((f (mogan-test-users-path)))
    (if (url-exists? f)
        (load-object f)
        (list))))

(define (mogan-test-find-user users pseudo)
  (let loop ((rest users))
    (cond
      ((null? rest) #f)
      ((and (pair? (car rest))
            (> (length (car rest)) 1)
            (equal? (cadr (car rest)) pseudo))
       (car rest))
      (else
       (loop (cdr rest))))))

(define (mogan-test-find-user-record pseudo)
  (mogan-test-find-user (mogan-test-load-users) pseudo))

(define (mogan-test-save-users users)
  (save-object (mogan-test-users-path) users))

(tm-service (mogan-test-bootstrap-account pseudo name passwd email)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: bootstrap-account pseudo="
      pseudo))
  (let ((users (mogan-test-load-users)))
    (if (mogan-test-find-user users pseudo)
      (server-return envelope "exists")
      (begin
        (mogan-test-save-users
          (cons (list pseudo pseudo name passwd email #f) users))
        (server-return
          envelope
          (if (mogan-test-find-user (mogan-test-load-users) pseudo)
              "done"
              "missing"))))))

(tm-service (remote-login pseudo passwd)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: remote-login pseudo="
      pseudo))
  (let ((record (mogan-test-find-user-record pseudo)))
    (if (not record)
        (server-error envelope "user not found")
        (let ((stored-passwd (list-ref record 3))
              (client (car envelope)))
          (if (not (equal? stored-passwd passwd))
              (begin
                (ahash-remove! mogan-test-logged-table client)
                (server-error envelope "invalid password"))
              (begin
                (ahash-set! mogan-test-logged-table client pseudo)
                (server-return envelope "ready")))))))

(define (mogan-test-logged-in? envelope)
  (and (ahash-ref mogan-test-logged-table (car envelope)) #t))

(define (mogan-test-require-login envelope)
  (if (mogan-test-logged-in? envelope)
      #t
      (begin
        (server-error envelope "not logged in")
        #f)))

(tm-service (mogan-test-ping)
  (mogan-test-server-log "mogan-server-runtime: ping")
  (when (mogan-test-require-login envelope)
    (server-return envelope "pong")))

(tm-service (mogan-test-current-buffer)
  (mogan-test-server-log "mogan-server-runtime: current-buffer")
  (when (mogan-test-require-login envelope)
    (with buffer-name (current-buffer)
      (server-return
        envelope
        (if buffer-name
            (url->string buffer-name)
            "")))))

(tm-service (mogan-test-new-document)
  (mogan-test-server-log "mogan-server-runtime: new-document")
  (when (mogan-test-require-login envelope)
    (new-document)
    (with buffer-name (current-buffer)
      (server-return
        envelope
        (if buffer-name
            (url->string buffer-name)
            "")))))
