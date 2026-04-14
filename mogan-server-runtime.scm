;; mogan-server-runtime.scm - Server-side test services loaded via `-x`

(use-modules (server server-base))

(define *mogan-test-server-trace-path* "/tmp/mogan-test-server-trace.log")
(define *mogan-test-login-table* (make-ahash-table))
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

(tm-define (server-get-user envelope)
  (with client (car envelope)
    (and client (ahash-ref *mogan-test-login-table* client))))

(tm-define (server-check-admin? envelope)
  (and-with uid (server-get-user envelope)
    (let* ((users (mogan-test-load-users))
           (user (mogan-test-find-user users uid)))
      (and user (list-ref user 5)))))

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

(define (mogan-test-save-users users)
  (save-object (mogan-test-users-path) users))

(define (mogan-test-user-record pseudo name passwd email)
  (list pseudo pseudo name passwd email #f))

(define (mogan-test-upsert-user! pseudo name passwd email)
  (let* ((users (mogan-test-load-users))
         (existing (mogan-test-find-user users pseudo)))
    (if existing
        "exists"
        (begin
          (mogan-test-save-users
            (cons (mogan-test-user-record pseudo name passwd email) users))
          "done"))))

(tm-service (mogan-test-bootstrap-account pseudo name passwd email)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: bootstrap-account pseudo="
      pseudo))
  (server-return envelope
                 (mogan-test-upsert-user! pseudo name passwd email)))

(tm-service (new-account pseudo name passwd email agreed)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: new-account pseudo="
      pseudo))
  (server-return envelope
                 (mogan-test-upsert-user! pseudo name passwd email)))

(tm-service (remote-login pseudo passwd)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: remote-login pseudo="
      pseudo))
  (let* ((users (mogan-test-load-users))
         (user (mogan-test-find-user users pseudo)))
    (if (not user)
        (begin
          (with client (car envelope)
            (ahash-remove! *mogan-test-login-table* client))
          (server-error envelope "user not found"))
        (if (!= (list-ref user 3) passwd)
            (begin
              (with client (car envelope)
                (ahash-remove! *mogan-test-login-table* client))
              (server-error envelope "invalid password"))
            (begin
              (with client (car envelope)
                (ahash-set! *mogan-test-login-table* client (car user)))
              (server-return envelope "ready"))))))

(define (mogan-test-require-login envelope)
  (if (server-get-user envelope)
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

(define (mogan-test-buffer-body)
  (buffer-get-body (current-buffer)))

(define (mogan-test-buffer-text-value)
  (let ((body (mogan-test-buffer-body)))
    (cond
      ((and body
            (tree-is? body 'document)
            (> (tree-arity body) 0)
            (tree-atomic? (tree-ref body 0)))
       (tree->string (tree-ref body 0)))
      (body
       (object->string* (tm->stree body)))
      (else
       ""))))

(tm-service (mogan-test-write-text text)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: write-text text="
      text))
  (when (mogan-test-require-login envelope)
    (buffer-set-body (current-buffer) `(document ,text))
    (server-return envelope (mogan-test-buffer-text-value))))

(tm-service (mogan-test-buffer-text)
  (mogan-test-server-log "mogan-server-runtime: buffer-text")
  (when (mogan-test-require-login envelope)
    (server-return envelope (mogan-test-buffer-text-value))))

(define (mogan-test-current-buffer-string)
  (let ((buffer-name (current-buffer)))
    (if buffer-name
        (url->string buffer-name)
        "")))

(define (mogan-test-selection-start-string)
  (if (selection-active-any?)
      (object->string* (selection-get-start))
      ""))

(define (mogan-test-selection-end-string)
  (if (selection-active-any?)
      (object->string* (selection-get-end))
      ""))

(define (mogan-test-control-state)
  (let ((buffer-name (current-buffer)))
    (list
      (cons "buffer" (mogan-test-current-buffer-string))
      (cons "title"
            (if buffer-name
                (buffer-get-title buffer-name)
                ""))
      (cons "modified"
            (and buffer-name (buffer-modified? buffer-name)))
      (cons "cursor_path" (object->string* (cursor-path)))
      (cons "selection_active" (selection-active-any?))
      (cons "selection_start" (mogan-test-selection-start-string))
      (cons "selection_end" (mogan-test-selection-end-string))
      (cons "selection_tree"
            (if (selection-active-any?)
                (object->string* (selection-tree))
                ""))
      (cons "undo_possibilities" (undo-possibilities))
      (cons "redo_possibilities" (redo-possibilities))
      (cons "buffer_text" (mogan-test-buffer-text-value)))))

(define (mogan-test-control-state-string)
  (object->string* (mogan-test-control-state)))

(define (mogan-test-return-control-state envelope)
  (server-return envelope (mogan-test-control-state-string)))

(define (mogan-test-run-control-action envelope label action)
  (mogan-test-server-log
    (string-append "mogan-server-runtime: " label))
  (when (mogan-test-require-login envelope)
    (action)
    (mogan-test-return-control-state envelope)))

(define (mogan-test-parse-number envelope label value)
  (let ((n (string->number value)))
    (if n
        n
        (begin
          (server-error envelope
                        (string-append "invalid " label ": " value))
          #f))))

(tm-service (mogan-test-state)
  (mogan-test-server-log "mogan-server-runtime: state")
  (when (mogan-test-require-login envelope)
    (mogan-test-return-control-state envelope)))

(tm-service (mogan-test-move-left)
  (mogan-test-run-control-action envelope "move-left" (lambda () (go-left))))

(tm-service (mogan-test-move-right)
  (mogan-test-run-control-action envelope "move-right" (lambda () (go-right))))

(tm-service (mogan-test-move-up)
  (mogan-test-run-control-action envelope "move-up" (lambda () (go-up))))

(tm-service (mogan-test-move-down)
  (mogan-test-run-control-action envelope "move-down" (lambda () (go-down))))

(tm-service (mogan-test-move-start)
  (mogan-test-run-control-action envelope "move-start" (lambda () (go-start))))

(tm-service (mogan-test-move-end)
  (mogan-test-run-control-action envelope "move-end" (lambda () (go-end))))

(tm-service (mogan-test-move-start-line)
  (mogan-test-run-control-action
    envelope
    "move-start-line"
    (lambda () (go-start-line))))

(tm-service (mogan-test-move-end-line)
  (mogan-test-run-control-action
    envelope
    "move-end-line"
    (lambda () (go-end-line))))

(tm-service (mogan-test-move-start-paragraph)
  (mogan-test-run-control-action
    envelope
    "move-start-paragraph"
    (lambda () (go-start-paragraph))))

(tm-service (mogan-test-move-end-paragraph)
  (mogan-test-run-control-action
    envelope
    "move-end-paragraph"
    (lambda () (go-end-paragraph))))

(tm-service (mogan-test-move-word-left)
  (mogan-test-run-control-action
    envelope
    "move-word-left"
    (lambda () (go-to-previous-word))))

(tm-service (mogan-test-move-word-right)
  (mogan-test-run-control-action
    envelope
    "move-word-right"
    (lambda () (go-to-next-word))))

(tm-service (mogan-test-move-to-line line)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: move-to-line line="
      line))
  (when (mogan-test-require-login envelope)
    (let ((n (mogan-test-parse-number envelope "line" line)))
      (when n
        (go-to-line n)
        (mogan-test-return-control-state envelope)))))

(tm-service (mogan-test-move-to-column column)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: move-to-column column="
      column))
  (when (mogan-test-require-login envelope)
    (let ((n (mogan-test-parse-number envelope "column" column)))
      (when n
        (go-to-column n)
        (mogan-test-return-control-state envelope)))))

(tm-service (mogan-test-select-all)
  (mogan-test-run-control-action
    envelope
    "select-all"
    (lambda () (select-all))))

(tm-service (mogan-test-select-start)
  (mogan-test-run-control-action
    envelope
    "select-start"
    (lambda () (selection-set-start))))

(tm-service (mogan-test-select-end)
  (mogan-test-run-control-action
    envelope
    "select-end"
    (lambda () (selection-set-end))))

(tm-service (mogan-test-clear-selection)
  (mogan-test-run-control-action
    envelope
    "clear-selection"
    (lambda () (selection-cancel))))

(tm-service (mogan-test-history-undo)
  (mogan-test-run-control-action
    envelope
    "undo"
    (lambda () (eval '(undo 0)))))

(tm-service (mogan-test-history-redo)
  (mogan-test-run-control-action
    envelope
    "redo"
    (lambda () (eval '(redo 0)))))

(tm-service (mogan-test-clipboard-copy)
  (mogan-test-run-control-action
    envelope
    "copy"
    (lambda () (eval '(kbd-copy)))))

(tm-service (mogan-test-clipboard-cut)
  (mogan-test-run-control-action
    envelope
    "cut"
    (lambda () (eval '(kbd-cut)))))

(tm-service (mogan-test-clipboard-paste)
  (mogan-test-run-control-action
    envelope
    "paste"
    (lambda () (eval '(kbd-paste)))))

(tm-service (mogan-test-clear-history)
  (mogan-test-run-control-action
    envelope
    "clear-undo-history"
    (lambda () (eval '(clear-undo-history)))))

(tm-service (mogan-test-insert-text text)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-text text="
      text))
  (when (mogan-test-require-login envelope)
    (insert text)
    (mogan-test-return-control-state envelope)))

(tm-service (mogan-test-insert-return)
  (mogan-test-run-control-action
    envelope
    "insert-return"
    (lambda () (insert-return))))

(tm-service (mogan-test-delete-left)
  (mogan-test-run-control-action
    envelope
    "delete-left"
    (lambda () (kbd-backspace))))

(tm-service (mogan-test-delete-right)
  (mogan-test-run-control-action
    envelope
    "delete-right"
    (lambda () (kbd-delete))))

(tm-service (mogan-test-save-buffer)
  (mogan-test-run-control-action
    envelope
    "save-buffer"
    (lambda () (save-buffer))))

(tm-service (mogan-test-switch-buffer name)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: switch-buffer name="
      name))
  (when (mogan-test-require-login envelope)
    (go-to-buffer name)
    (mogan-test-return-control-state envelope)))

(define (mogan-test-smoke-edit-run!)
  (when (selection-active-any?)
    (selection-cancel))
  (new-document)
  (buffer-set-body (current-buffer) `(document "hello from mogan-test"))
  (go-end)
  (insert "!")
  (mogan-test-control-state-string))

(tm-service (mogan-test-smoke-edit)
  (mogan-test-server-log "mogan-server-runtime: smoke-edit")
  (when (mogan-test-require-login envelope)
    (server-return envelope (mogan-test-smoke-edit-run!))))
