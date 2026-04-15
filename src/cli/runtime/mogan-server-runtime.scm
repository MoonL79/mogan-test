;; mogan-server-runtime.scm - Server-side test services loaded via `-x`

(use-modules (server server-base)
             (generic search-widgets))

(load "/home/mingshen/git/mogan/TeXmacs/progs/generic/search-widgets.scm")

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

(define (mogan-test-tree-text-value body)
  (cond
    ((and body
          (tree-is? body 'document 1)
          (> (tree-arity body) 0)
          (tree-atomic? (tree-ref body 0)))
     (tree->string (tree-ref body 0)))
    (body
     (object->string* (tm->stree body)))
    (else
     "")))

(define (mogan-test-buffer-text-value-from buffer)
  (mogan-test-tree-text-value (buffer-get-body buffer)))

(define (mogan-test-buffer-text-value)
  (mogan-test-buffer-text-value-from (current-buffer)))

(define (mogan-test-buffer-record buffer)
  (list
    (cons "buffer" (url->string buffer))
    (cons "title" (buffer-get-title buffer))
    (cons "modified" (buffer-modified? buffer))
    (cons "current" (equal? buffer (current-buffer)))))

(define (mogan-test-buffer-list-value)
  (map mogan-test-buffer-record (buffer-list)))

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

(tm-service (mogan-test-buffer-list)
  (mogan-test-server-log "mogan-server-runtime: buffer-list")
  (when (mogan-test-require-login envelope)
    (server-return envelope (mogan-test-buffer-list-value))))

(tm-service (mogan-test-open-file path)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: open-file path="
      path))
  (when (mogan-test-require-login envelope)
    (let ((u (system->url path)))
      (if (url-exists? u)
          (begin
            (load-buffer u)
            (mogan-test-return-control-state envelope))
          (server-error envelope
                        (string-append "file not found: " path))))))

(tm-service (mogan-test-save-as path)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: save-as path="
      path))
  (when (mogan-test-require-login envelope)
    (save-buffer-as (system->url path) :overwrite)
    (mogan-test-return-control-state envelope)))

(tm-service (mogan-test-revert-buffer)
  (mogan-test-server-log "mogan-server-runtime: revert-buffer")
  (when (mogan-test-require-login envelope)
    (revert-buffer-revert)
    (mogan-test-return-control-state envelope)))

(tm-service (mogan-test-close-buffer)
  (mogan-test-server-log "mogan-server-runtime: close-buffer")
  (when (mogan-test-require-login envelope)
    (let ((buf (current-buffer)))
      (if buf
          (begin
            (buffer-close buf)
            (server-return envelope (mogan-test-buffer-list-value)))
          (server-error envelope "no current buffer")))))

(define (mogan-test-export-state-value path)
  (append
    (list (cons "exported_to" path))
    (mogan-test-control-state)))

(define (mogan-test-export-state-string path)
  (object->string* (mogan-test-export-state-value path)))

(tm-service (mogan-test-export-buffer path)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: export-buffer path="
      path))
  (when (mogan-test-require-login envelope)
    (let ((u (system->url path)))
      (export-buffer path)
      (if (url-exists? u)
          (server-return envelope (mogan-test-export-state-string path))
          (server-error envelope
                        (string-append "export failed: " path))))))

(define (mogan-test-search-buffer-url)
  (search-buffer))

(define (mogan-test-replace-buffer-url)
  (replace-buffer))

(define (mogan-test-aux-buffer-text buffer-url)
  (if (buffer-exists? buffer-url)
      (mogan-test-buffer-text-value-from buffer-url)
      ""))

(define (mogan-test-search-state-value)
  (append
    (mogan-test-control-state)
    (list
      (cons "search_buffer"
            (if (buffer-exists? (mogan-test-search-buffer-url))
                (url->string (mogan-test-search-buffer-url))
                ""))
      (cons "search_buffer_exists"
            (buffer-exists? (mogan-test-search-buffer-url)))
      (cons "search_query"
            (mogan-test-aux-buffer-text (mogan-test-search-buffer-url)))
      (cons "replace_buffer"
            (if (buffer-exists? (mogan-test-replace-buffer-url))
                (url->string (mogan-test-replace-buffer-url))
                ""))
      (cons "replace_buffer_exists"
            (buffer-exists? (mogan-test-replace-buffer-url)))
      (cons "replace_text"
            (mogan-test-aux-buffer-text (mogan-test-replace-buffer-url))))))

(define (mogan-test-search-state-string)
  (object->string* (mogan-test-search-state-value)))

(define (mogan-test-search-buffer-ready? envelope)
  (if (buffer-exists? (mogan-test-search-buffer-url))
      #t
      (begin
        (server-error envelope "search query not set")
        #f)))

(define (mogan-test-replace-buffer-ready? envelope)
  (if (buffer-exists? (mogan-test-replace-buffer-url))
      #t
      (begin
        (server-error envelope "replace text not set")
        #f)))

(define (mogan-test-setup-replace-buffer! replacement)
  (let ((u (current-buffer))
        (aux (mogan-test-replace-buffer-url)))
    (buffer-set-body aux `(document ,replacement))
    (buffer-set-master aux u)))

(define (mogan-test-search-set! query)
  (search-toolbar-keypress query #f))

(define (mogan-test-run-search-set envelope label query)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: "
      label
      " query="
      query))
  (when (mogan-test-require-login envelope)
    (mogan-test-search-set! query)
    (server-return envelope (mogan-test-search-state-string))))

(define (mogan-test-run-search-navigation envelope label action)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: "
      label))
  (when (mogan-test-require-login envelope)
    (if (not (mogan-test-search-buffer-ready? envelope))
        #f
        (let ((ok? (action)))
          (if ok?
              (server-return envelope (mogan-test-search-state-string))
              (server-error envelope "search match not found"))))))

(define (mogan-test-run-replace-set envelope label replacement)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: "
      label
      " replacement="
      replacement))
  (when (mogan-test-require-login envelope)
    (mogan-test-setup-replace-buffer! replacement)
    (server-return envelope (mogan-test-search-state-string))))

(define (mogan-test-run-replace-action envelope label action)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: "
      label))
  (when (mogan-test-require-login envelope)
    (if (or (not (mogan-test-search-buffer-ready? envelope))
            (not (mogan-test-replace-buffer-ready? envelope)))
        #f
        (begin
          (action)
          (server-return envelope (mogan-test-search-state-string))))))

(tm-service (mogan-test-search-state)
  (mogan-test-server-log "mogan-server-runtime: search-state")
  (when (mogan-test-require-login envelope)
    (server-return envelope (mogan-test-search-state-string))))

(tm-service (mogan-test-search-set query)
  (mogan-test-run-search-set envelope "search-set" query))

(tm-service (mogan-test-search-next)
  (mogan-test-run-search-navigation
    envelope
    "search-next"
    (lambda () (search-next-match #t))))

(tm-service (mogan-test-search-prev)
  (mogan-test-run-search-navigation
    envelope
    "search-prev"
    (lambda () (search-next-match #f))))

(tm-service (mogan-test-search-first)
  (mogan-test-run-search-navigation
    envelope
    "search-first"
    (lambda () (search-extreme-match #f))))

(tm-service (mogan-test-search-last)
  (mogan-test-run-search-navigation
    envelope
    "search-last"
    (lambda () (search-extreme-match #t))))

(tm-service (mogan-test-replace-set replacement)
  (mogan-test-run-replace-set envelope "replace-set" replacement))

(tm-service (mogan-test-replace-one)
  (mogan-test-run-replace-action
    envelope
    "replace-one"
    (lambda () (replace-one))))

(tm-service (mogan-test-replace-all)
  (mogan-test-run-replace-action
    envelope
    "replace-all"
    (lambda () (replace-all))))

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
      (cons "buffer_text" (mogan-test-buffer-text-value))
      (cons "main_style"
            (let ((styles (get-style-list)))
              (if (null? styles) "" (car styles))))
      (cons "style_list" (object->string* (get-style-list)))
      (cons "document_language" (get-document-language))
      (cons "page_medium" (or (get-init "page-medium") ""))
      (cons "page_type" (or (get-init "page-type") ""))
      (cons "page_orientation" (or (get-init "page-orientation") ""))
      (cons "page_width" (or (get-init "page-width") ""))
      (cons "page_height" (or (get-init "page-height") "")))))

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

(define (mogan-test-run-style-action envelope label action)
  (mogan-test-server-log
    (string-append "mogan-server-runtime: " label))
  (when (mogan-test-require-login envelope)
    (action)
    (mogan-test-return-control-state envelope)))

(define (mogan-test-run-layout-action envelope label action)
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

(tm-service (mogan-test-set-main-style style)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: set-main-style style="
      style))
  (mogan-test-run-style-action
    envelope
    "set-main-style"
    (lambda () (set-main-style style))))

(tm-service (mogan-test-set-document-language language)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: set-document-language language="
      language))
  (mogan-test-run-style-action
    envelope
    "set-document-language"
    (lambda () (set-document-language language))))

(tm-service (mogan-test-add-style-package pack)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: add-style-package pack="
      pack))
  (mogan-test-run-style-action
    envelope
    "add-style-package"
    (lambda () (add-style-package pack))))

(tm-service (mogan-test-remove-style-package pack)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: remove-style-package pack="
      pack))
  (mogan-test-run-style-action
    envelope
    "remove-style-package"
    (lambda () (remove-style-package pack))))

(tm-service (mogan-test-set-page-medium medium)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: set-page-medium medium="
      medium))
  (mogan-test-run-layout-action
    envelope
    "set-page-medium"
    (lambda () (init-page-medium medium))))

(tm-service (mogan-test-set-page-type type)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: set-page-type type="
      type))
  (mogan-test-run-layout-action
    envelope
    "set-page-type"
    (lambda () (init-page-type type))))

(tm-service (mogan-test-set-page-orientation orientation)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: set-page-orientation orientation="
      orientation))
  (mogan-test-run-layout-action
    envelope
    "set-page-orientation"
    (lambda () (init-page-orientation orientation))))

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
