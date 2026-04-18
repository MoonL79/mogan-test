;; mogan-server-runtime.scm - Server-side test services loaded via `-x`

(use-modules (server server-base)
             (generic search-widgets)
) ;use-modules

(load "/home/mingshen/git/mogan/TeXmacs/progs/generic/search-widgets.scm")
(load "/home/mingshen/git/mogan/TeXmacs/progs/convert/latex/init-latex.scm")

(define *mogan-test-server-trace-path* "/tmp/mogan-test-server-trace.log")
(define *mogan-test-login-table* (make-ahash-table))
(define (mogan-test-server-log message)
  (string-append-to-file
    (string-append message "\n")
    *mogan-test-server-trace-path*
  ) ;string-append-to-file
) ;define

(mogan-test-server-log "mogan-server-runtime: loaded")

(tm-define (server-add client)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: server-add client="
      (number->string client)
    ) ;string-append
  ) ;mogan-test-server-log
  (former client)
) ;tm-define

(tm-define (server-eval envelope cmd)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: server-eval "
      (object->string* cmd)
    ) ;string-append
  ) ;mogan-test-server-log
  (former envelope cmd)
) ;tm-define

(tm-define (server-return envelope ret-val)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: server-return "
      (object->string* ret-val)
    ) ;string-append
  ) ;mogan-test-server-log
  (former envelope ret-val)
) ;tm-define

(tm-define (server-error envelope error-msg)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: server-error "
      (object->string* error-msg)
    ) ;string-append
  ) ;mogan-test-server-log
  (former envelope error-msg)
) ;tm-define

(tm-define (server-get-user envelope)
  (with client (car envelope)
    (and client (ahash-ref *mogan-test-login-table* client))
  ) ;with
) ;tm-define

(tm-define (server-check-admin? envelope)
  (and-with uid (server-get-user envelope)
    (let* ((users (mogan-test-load-users))
           (user (mogan-test-find-user users uid)))
      (and user (list-ref user 5))
    ) ;let*
  ) ;and-with
) ;tm-define

(define (mogan-test-users-path)
  "$TEXMACS_HOME_PATH/server/users.scm"
) ;define

(define (mogan-test-load-users)
  (let ((f (mogan-test-users-path)))
    (if (url-exists? f)
        (load-object f)
        (list)
    ) ;if
  ) ;let
) ;define

(define (mogan-test-find-user users pseudo)
  (let loop ((rest users))
    (cond
      ((null? rest) #f)
      ((and (pair? (car rest))
            (> (length (car rest)) 1)
            (equal? (cadr (car rest)) pseudo))
       (car rest)
 ;
      ) ;
      (else
       (loop (cdr rest))
      ) ;else
    ) ;cond
  ) ;let
) ;define

(define (mogan-test-save-users users)
  (save-object (mogan-test-users-path) users)
) ;define

(define (mogan-test-user-record pseudo name passwd email)
  (list pseudo pseudo name passwd email #f)
) ;define

(define (mogan-test-upsert-user! pseudo name passwd email)
  (let* ((users (mogan-test-load-users))
         (existing (mogan-test-find-user users pseudo)))
    (if existing
        "exists"
        (begin
          (mogan-test-save-users
            (cons (mogan-test-user-record pseudo name passwd email) users)
          ) ;mogan-test-save-users
          "done"
        ) ;begin
    ) ;if
  ) ;let*
) ;define

(tm-service (mogan-test-bootstrap-account pseudo name passwd email)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: bootstrap-account pseudo="
      pseudo
    ) ;string-append
  ) ;mogan-test-server-log
  (server-return envelope
                 (mogan-test-upsert-user! pseudo name passwd email)
  ) ;server-return
) ;tm-service

(tm-service (new-account pseudo name passwd email agreed)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: new-account pseudo="
      pseudo
    ) ;string-append
  ) ;mogan-test-server-log
  (server-return envelope
                 (mogan-test-upsert-user! pseudo name passwd email)
  ) ;server-return
) ;tm-service

(tm-service (remote-login pseudo passwd)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: remote-login pseudo="
      pseudo
    ) ;string-append
  ) ;mogan-test-server-log
  (let* ((users (mogan-test-load-users))
         (user (mogan-test-find-user users pseudo)))
    (if (not user)
        (begin
          (with client (car envelope)
            (ahash-remove! *mogan-test-login-table* client)
          ) ;with
          (server-error envelope "user not found")
        ) ;begin
        (if (!= (list-ref user 3) passwd)
            (begin
              (with client (car envelope)
                (ahash-remove! *mogan-test-login-table* client)
              ) ;with
              (server-error envelope "invalid password")
            ) ;begin
            (begin
              (with client (car envelope)
                (ahash-set! *mogan-test-login-table* client (car user))
              ) ;with
              (server-return envelope "ready")
            ) ;begin
        ) ;if
    ) ;if
  ) ;let*
) ;tm-service

(define (mogan-test-require-login envelope)
  (if (server-get-user envelope)
      #t
      (begin
        (server-error envelope "not logged in")
        #f
      ) ;begin
  ) ;if
) ;define

(tm-service (mogan-test-ping)
  (mogan-test-server-log "mogan-server-runtime: ping")
  (when (mogan-test-require-login envelope)
    (server-return envelope "pong")
  ) ;when
) ;tm-service

(tm-service (mogan-test-current-buffer)
  (mogan-test-server-log "mogan-server-runtime: current-buffer")
  (when (mogan-test-require-login envelope)
    (with buffer-name (current-buffer)
      (server-return
        envelope
        (if buffer-name
            (url->string buffer-name)
            ""
        ) ;if
      ) ;server-return
    ) ;with
  ) ;when
) ;tm-service

(tm-service (mogan-test-new-document)
  (mogan-test-server-log "mogan-server-runtime: new-document")
  (when (mogan-test-require-login envelope)
    (new-document)
    (with buffer-name (current-buffer)
      (server-return
        envelope
        (if buffer-name
            (url->string buffer-name)
            ""
        ) ;if
      ) ;server-return
    ) ;with
  ) ;when
) ;tm-service

(define (mogan-test-buffer-body)
  (buffer-get-body (current-buffer))
) ;define

(define (mogan-test-tree-text-value body)
  (cond
    ((and body
          (tree-is? body 'document 1)
          (> (tree-arity body) 0)
          (tree-atomic? (tree-ref body 0)))
     (tree->string (tree-ref body 0))
 ;
    ) ;
    (body
     (object->string* (tm->stree body))
    ) ;body
    (else
     ""
    ) ;else
  ) ;cond
) ;define

(define (mogan-test-buffer-text-value-from buffer)
  (mogan-test-tree-text-value (buffer-get-body buffer))
) ;define

(define (mogan-test-buffer-text-value)
  (mogan-test-buffer-text-value-from (current-buffer))
) ;define

(define (mogan-test-buffer-record buffer)
  (list
    (cons "buffer" (url->string buffer))
    (cons "title" (buffer-get-title buffer))
    (cons "modified" (buffer-modified? buffer))
    (cons "current" (equal? buffer (current-buffer)))
  ) ;list
) ;define

(define (mogan-test-buffer-list-value)
  (map mogan-test-buffer-record (buffer-list))
) ;define

(define (mogan-test-decode-utf8-text b64-text)
  (utf8->cork (decode-base64 b64-text))
) ;define

(tm-service (mogan-test-write-text text)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: write-text text="
      text
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (buffer-set-body (current-buffer) `(document ,text))
    (server-return envelope (mogan-test-buffer-text-value))
  ) ;when
) ;tm-service

(tm-service (mogan-test-write-text-b64 b64-text)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: write-text-b64 bytes="
      (number->string (string-length b64-text))
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (buffer-set-body
      (current-buffer)
      `(document ,(mogan-test-decode-utf8-text b64-text))
    ) ;buffer-set-body
    (server-return envelope (mogan-test-buffer-text-value))
  ) ;when
) ;tm-service

(tm-service (mogan-test-buffer-text)
  (mogan-test-server-log "mogan-server-runtime: buffer-text")
  (when (mogan-test-require-login envelope)
    (server-return envelope (mogan-test-buffer-text-value))
  ) ;when
) ;tm-service

(tm-service (mogan-test-buffer-list)
  (mogan-test-server-log "mogan-server-runtime: buffer-list")
  (when (mogan-test-require-login envelope)
    (server-return envelope (mogan-test-buffer-list-value))
  ) ;when
) ;tm-service

(tm-service (mogan-test-open-file path)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: open-file path="
      path
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (let ((u (system->url path)))
      (if (url-exists? u)
          (begin
            (load-buffer u)
            (mogan-test-return-control-state envelope)
          ) ;begin
          (server-error envelope
                        (string-append "file not found: " path)
          ) ;server-error
      ) ;if
    ) ;let
  ) ;when
) ;tm-service

(tm-service (mogan-test-save-as path)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: save-as path="
      path
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (save-buffer-as (system->url path) :overwrite)
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-revert-buffer)
  (mogan-test-server-log "mogan-server-runtime: revert-buffer")
  (when (mogan-test-require-login envelope)
    (revert-buffer-revert)
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-close-buffer)
  (mogan-test-server-log "mogan-server-runtime: close-buffer")
  (when (mogan-test-require-login envelope)
    (let ((buf (current-buffer)))
      (if buf
          (begin
            (buffer-close buf)
            (server-return envelope (mogan-test-buffer-list-value))
          ) ;begin
          (server-error envelope "no current buffer")
      ) ;if
    ) ;let
  ) ;when
) ;tm-service

(define (mogan-test-export-state-value path)
  (append
    (list (cons "exported_to" path))
    (mogan-test-control-state)
  ) ;append
) ;define

(define (mogan-test-export-state-string path)
  (object->string* (mogan-test-export-state-value path))
) ;define

(tm-service (mogan-test-export-buffer path)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: export-buffer path="
      path
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (let ((u (system->url path)))
      (export-buffer path)
      (if (url-exists? u)
          (server-return envelope (mogan-test-export-state-string path))
          (server-error envelope
                        (string-append "export failed: " path)
          ) ;server-error
      ) ;if
    ) ;let
  ) ;when
) ;tm-service

(define (mogan-test-search-buffer-url)
  (search-buffer)
) ;define

(define (mogan-test-replace-buffer-url)
  (replace-buffer)
) ;define

(define (mogan-test-aux-buffer-text buffer-url)
  (if (buffer-exists? buffer-url)
      (mogan-test-buffer-text-value-from buffer-url)
      ""
  ) ;if
) ;define

(define (mogan-test-search-state-value)
  (append
    (mogan-test-control-state)
    (list
      (cons "search_buffer"
            (if (buffer-exists? (mogan-test-search-buffer-url))
                (url->string (mogan-test-search-buffer-url))
                ""
            ) ;if
      ) ;cons
      (cons "search_buffer_exists"
            (buffer-exists? (mogan-test-search-buffer-url))
      ) ;cons
      (cons "search_query"
            (mogan-test-aux-buffer-text (mogan-test-search-buffer-url))
      ) ;cons
      (cons "replace_buffer"
            (if (buffer-exists? (mogan-test-replace-buffer-url))
                (url->string (mogan-test-replace-buffer-url))
                ""
            ) ;if
      ) ;cons
      (cons "replace_buffer_exists"
            (buffer-exists? (mogan-test-replace-buffer-url))
      ) ;cons
      (cons "replace_text"
            (mogan-test-aux-buffer-text (mogan-test-replace-buffer-url))
      ) ;cons
    ) ;list
  ) ;append
) ;define

(define (mogan-test-search-state-string)
  (object->string* (mogan-test-search-state-value))
) ;define

(define (mogan-test-search-buffer-ready? envelope)
  (if (buffer-exists? (mogan-test-search-buffer-url))
      #t
      (begin
        (server-error envelope "search query not set")
        #f
      ) ;begin
  ) ;if
) ;define

(define (mogan-test-replace-buffer-ready? envelope)
  (if (buffer-exists? (mogan-test-replace-buffer-url))
      #t
      (begin
        (server-error envelope "replace text not set")
        #f
      ) ;begin
  ) ;if
) ;define

(define (mogan-test-setup-replace-buffer! replacement)
  (let ((u (current-buffer))
        (aux (mogan-test-replace-buffer-url)))
    (buffer-set-body aux `(document ,replacement))
    (buffer-set-master aux u)
  ) ;let
) ;define

(define (mogan-test-search-set! query)
  (search-toolbar-keypress query #f)
) ;define

(define (mogan-test-run-search-set envelope label query)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: "
      label
      " query="
      query
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (mogan-test-search-set! query)
    (server-return envelope (mogan-test-search-state-string))
  ) ;when
) ;define

(define (mogan-test-run-search-navigation envelope label action)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: "
      label
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (if (not (mogan-test-search-buffer-ready? envelope))
        #f
        (let ((ok? (action)))
          (if ok?
              (server-return envelope (mogan-test-search-state-string))
              (server-error envelope "search match not found")
          ) ;if
        ) ;let
    ) ;if
  ) ;when
) ;define

(define (mogan-test-run-replace-set envelope label replacement)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: "
      label
      " replacement="
      replacement
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (mogan-test-setup-replace-buffer! replacement)
    (server-return envelope (mogan-test-search-state-string))
  ) ;when
) ;define

(define (mogan-test-run-replace-action envelope label action)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: "
      label
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (if (or (not (mogan-test-search-buffer-ready? envelope))
            (not (mogan-test-replace-buffer-ready? envelope)))
        #f
        (begin
          (action)
          (server-return envelope (mogan-test-search-state-string))
        ) ;begin
    ) ;if
  ) ;when
) ;define

(tm-service (mogan-test-search-state)
  (mogan-test-server-log "mogan-server-runtime: search-state")
  (when (mogan-test-require-login envelope)
    (server-return envelope (mogan-test-search-state-string))
  ) ;when
) ;tm-service

(tm-service (mogan-test-search-set query)
  (mogan-test-run-search-set envelope "search-set" query)
) ;tm-service

(tm-service (mogan-test-search-next)
  (mogan-test-run-search-navigation
    envelope
    "search-next"
    (lambda () (search-next-match #t))
  ) ;mogan-test-run-search-navigation
) ;tm-service

(tm-service (mogan-test-search-prev)
  (mogan-test-run-search-navigation
    envelope
    "search-prev"
    (lambda () (search-next-match #f))
  ) ;mogan-test-run-search-navigation
) ;tm-service

(tm-service (mogan-test-search-first)
  (mogan-test-run-search-navigation
    envelope
    "search-first"
    (lambda () (search-extreme-match #f))
  ) ;mogan-test-run-search-navigation
) ;tm-service

(tm-service (mogan-test-search-last)
  (mogan-test-run-search-navigation
    envelope
    "search-last"
    (lambda () (search-extreme-match #t))
  ) ;mogan-test-run-search-navigation
) ;tm-service

(tm-service (mogan-test-replace-set replacement)
  (mogan-test-run-replace-set envelope "replace-set" replacement)
) ;tm-service

(tm-service (mogan-test-replace-one)
  (mogan-test-run-replace-action
    envelope
    "replace-one"
    (lambda () (replace-one))
  ) ;mogan-test-run-replace-action
) ;tm-service

(tm-service (mogan-test-replace-all)
  (mogan-test-run-replace-action
    envelope
    "replace-all"
    (lambda () (replace-all))
  ) ;mogan-test-run-replace-action
) ;tm-service

(define (mogan-test-current-buffer-string)
  (let ((buffer-name (current-buffer)))
    (if buffer-name
        (url->string buffer-name)
        ""
    ) ;if
  ) ;let
) ;define

(define (mogan-test-selection-start-string)
  (if (selection-active-any?)
      (object->string* (selection-get-start))
      ""
  ) ;if
) ;define

(define (mogan-test-selection-end-string)
  (if (selection-active-any?)
      (object->string* (selection-get-end))
      ""
  ) ;if
) ;define

(define (mogan-test-control-state)
  (let ((buffer-name (current-buffer)))
    (list
      (cons "buffer" (mogan-test-current-buffer-string))
      (cons "title"
            (if buffer-name
                (buffer-get-title buffer-name)
                ""
            ) ;if
      ) ;cons
      (cons "modified"
            (and buffer-name (buffer-modified? buffer-name))
      ) ;cons
      (cons "cursor_path" (object->string* (cursor-path)))
      (cons "selection_active" (selection-active-any?))
      (cons "selection_start" (mogan-test-selection-start-string))
      (cons "selection_end" (mogan-test-selection-end-string))
      (cons "selection_tree"
            (if (selection-active-any?)
                (object->string* (selection-tree))
                ""
            ) ;if
      ) ;cons
      (cons "undo_possibilities" (undo-possibilities))
      (cons "redo_possibilities" (redo-possibilities))
      (cons "buffer_text" (mogan-test-buffer-text-value))
      (cons "main_style"
            (let ((styles (get-style-list)))
              (if (null? styles) "" (car styles))
            ) ;let
      ) ;cons
      (cons "style_list" (object->string* (get-style-list)))
      (cons "document_language" (get-document-language))
      (cons "page_medium" (or (get-init "page-medium") ""))
      (cons "page_type" (or (get-init "page-type") ""))
      (cons "page_orientation" (or (get-init "page-orientation") ""))
      (cons "page_width" (or (get-init "page-width") ""))
      (cons "page_height" (or (get-init "page-height") ""))
    ) ;list
  ) ;let
) ;define

(define (mogan-test-control-state-string)
  (object->string* (mogan-test-control-state))
) ;define

(define (mogan-test-return-control-state envelope)
  (server-return envelope (mogan-test-control-state-string))
) ;define

(define (mogan-test-run-control-action envelope label action)
  (mogan-test-server-log
    (string-append "mogan-server-runtime: " label)
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (action)
    (mogan-test-return-control-state envelope)
  ) ;when
) ;define

(define (mogan-test-run-style-action envelope label action)
  (mogan-test-server-log
    (string-append "mogan-server-runtime: " label)
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (action)
    (mogan-test-return-control-state envelope)
  ) ;when
) ;define

(define (mogan-test-run-layout-action envelope label action)
  (mogan-test-server-log
    (string-append "mogan-server-runtime: " label)
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (action)
    (mogan-test-return-control-state envelope)
  ) ;when
) ;define

(define (mogan-test-parse-number envelope label value)
  (let ((n (string->number value)))
    (if n
        n
        (begin
          (server-error envelope
                        (string-append "invalid " label ": " value)
          ) ;server-error
          #f
        ) ;begin
    ) ;if
  ) ;let
) ;define

(tm-service (mogan-test-state)
  (mogan-test-server-log "mogan-server-runtime: state")
  (when (mogan-test-require-login envelope)
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-move-left)
  (mogan-test-run-control-action envelope "move-left" (lambda () (go-left)))
) ;tm-service

(tm-service (mogan-test-move-right)
  (mogan-test-run-control-action envelope "move-right" (lambda () (go-right)))
) ;tm-service

(tm-service (mogan-test-move-up)
  (mogan-test-run-control-action envelope "move-up" (lambda () (go-up)))
) ;tm-service

(tm-service (mogan-test-move-down)
  (mogan-test-run-control-action envelope "move-down" (lambda () (go-down)))
) ;tm-service

(tm-service (mogan-test-move-start)
  (mogan-test-run-control-action envelope "move-start" (lambda () (go-start)))
) ;tm-service

(tm-service (mogan-test-move-end)
  (mogan-test-run-control-action envelope "move-end" (lambda () (go-end)))
) ;tm-service

(tm-service (mogan-test-move-start-line)
  (mogan-test-run-control-action
    envelope
    "move-start-line"
    (lambda () (go-start-line))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-move-end-line)
  (mogan-test-run-control-action
    envelope
    "move-end-line"
    (lambda () (go-end-line))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-move-start-paragraph)
  (mogan-test-run-control-action
    envelope
    "move-start-paragraph"
    (lambda () (go-start-paragraph))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-move-end-paragraph)
  (mogan-test-run-control-action
    envelope
    "move-end-paragraph"
    (lambda () (go-end-paragraph))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-move-word-left)
  (mogan-test-run-control-action
    envelope
    "move-word-left"
    (lambda () (go-to-previous-word))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-move-word-right)
  (mogan-test-run-control-action
    envelope
    "move-word-right"
    (lambda () (go-to-next-word))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-move-to-line line)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: move-to-line line="
      line
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (let ((n (mogan-test-parse-number envelope "line" line)))
      (when n
        (go-to-line n)
        (mogan-test-return-control-state envelope)
      ) ;when
    ) ;let
  ) ;when
) ;tm-service

(tm-service (mogan-test-move-to-column column)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: move-to-column column="
      column
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (let ((n (mogan-test-parse-number envelope "column" column)))
      (when n
        (go-to-column n)
        (mogan-test-return-control-state envelope)
      ) ;when
    ) ;let
  ) ;when
) ;tm-service

(tm-service (mogan-test-select-all)
  (mogan-test-run-control-action
    envelope
    "select-all"
    (lambda () (select-all))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-select-start)
  (mogan-test-run-control-action
    envelope
    "select-start"
    (lambda () (selection-set-start))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-select-end)
  (mogan-test-run-control-action
    envelope
    "select-end"
    (lambda () (selection-set-end))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-clear-selection)
  (mogan-test-run-control-action
    envelope
    "clear-selection"
    (lambda () (selection-cancel))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-history-undo)
  (mogan-test-run-control-action
    envelope
    "undo"
    (lambda () (eval '(undo 0)))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-history-redo)
  (mogan-test-run-control-action
    envelope
    "redo"
    (lambda () (eval '(redo 0)))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-clipboard-copy)
  (mogan-test-run-control-action
    envelope
    "copy"
    (lambda () (eval '(kbd-copy)))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-clipboard-cut)
  (mogan-test-run-control-action
    envelope
    "cut"
    (lambda () (eval '(kbd-cut)))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-clipboard-paste)
  (mogan-test-run-control-action
    envelope
    "paste"
    (lambda () (eval '(kbd-paste)))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-clear-history)
  (mogan-test-run-control-action
    envelope
    "clear-undo-history"
    (lambda () (eval '(clear-undo-history)))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-insert-text text)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-text text="
      text
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (insert text)
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-text-b64 b64-text)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-text-b64 bytes="
      (number->string (string-length b64-text))
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (insert (mogan-test-decode-utf8-text b64-text))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-return)
  (mogan-test-run-control-action
    envelope
    "insert-return"
    (lambda () (insert-return))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-delete-left)
  (mogan-test-run-control-action
    envelope
    "delete-left"
    (lambda () (kbd-backspace))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-delete-right)
  (mogan-test-run-control-action
    envelope
    "delete-right"
    (lambda () (kbd-delete))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-save-buffer)
  (mogan-test-run-control-action
    envelope
    "save-buffer"
    (lambda () (save-buffer))
  ) ;mogan-test-run-control-action
) ;tm-service

(tm-service (mogan-test-set-main-style style)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: set-main-style style="
      style
    ) ;string-append
  ) ;mogan-test-server-log
  (mogan-test-run-style-action
    envelope
    "set-main-style"
    (lambda () (set-main-style style))
  ) ;mogan-test-run-style-action
) ;tm-service

(tm-service (mogan-test-set-document-language language)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: set-document-language language="
      language
    ) ;string-append
  ) ;mogan-test-server-log
  (mogan-test-run-style-action
    envelope
    "set-document-language"
    (lambda () (set-document-language language))
  ) ;mogan-test-run-style-action
) ;tm-service

(tm-service (mogan-test-add-style-package pack)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: add-style-package pack="
      pack
    ) ;string-append
  ) ;mogan-test-server-log
  (mogan-test-run-style-action
    envelope
    "add-style-package"
    (lambda () (add-style-package pack))
  ) ;mogan-test-run-style-action
) ;tm-service

(tm-service (mogan-test-remove-style-package pack)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: remove-style-package pack="
      pack
    ) ;string-append
  ) ;mogan-test-server-log
  (mogan-test-run-style-action
    envelope
    "remove-style-package"
    (lambda () (remove-style-package pack))
  ) ;mogan-test-run-style-action
) ;tm-service

(tm-service (mogan-test-set-page-medium medium)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: set-page-medium medium="
      medium
    ) ;string-append
  ) ;mogan-test-server-log
  (mogan-test-run-layout-action
    envelope
    "set-page-medium"
    (lambda () (init-page-medium medium))
  ) ;mogan-test-run-layout-action
) ;tm-service

(tm-service (mogan-test-set-page-type type)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: set-page-type type="
      type
    ) ;string-append
  ) ;mogan-test-server-log
  (mogan-test-run-layout-action
    envelope
    "set-page-type"
    (lambda () (init-page-type type))
  ) ;mogan-test-run-layout-action
) ;tm-service

(tm-service (mogan-test-set-page-orientation orientation)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: set-page-orientation orientation="
      orientation
    ) ;string-append
  ) ;mogan-test-server-log
  (mogan-test-run-layout-action
    envelope
    "set-page-orientation"
    (lambda () (init-page-orientation orientation))
  ) ;mogan-test-run-layout-action
) ;tm-service

(tm-service (mogan-test-switch-buffer name)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: switch-buffer name="
      name
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (go-to-buffer name)
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(define (mogan-test-smoke-edit-run!)
  (when (selection-active-any?)
    (selection-cancel)
  ) ;when
  (new-document)
  (buffer-set-body (current-buffer) `(document "hello from mogan-test"))
  (go-end)
  (insert "!")
  (mogan-test-control-state-string)
) ;define

(tm-service (mogan-test-smoke-edit)
  (mogan-test-server-log "mogan-server-runtime: smoke-edit")
  (when (mogan-test-require-login envelope)
    (server-return envelope (mogan-test-smoke-edit-run!))
  ) ;when
) ;tm-service

(define (mogan-test-insert-inline-math-tree! tree)
  (if (in-math?)
      (insert tree)
      (begin
        (make 'math)
        (insert tree)
        (mogan-test-leave-inline-math!)
      ) ;begin
  ) ;if
) ;define

(define (mogan-test-leave-inline-math!)
  (and-with math-node (tree-innermost 'math)
    (tree-go-to math-node :end)
    (go-right)
  ) ;and-with
) ;define

(define (mogan-test-leave-displayed-equation!)
  (and-with equation-node (tree-innermost 'equation*)
    (go-end-of 'equation*)
    (insert-return)
  ) ;and-with
) ;define

(define (mogan-test-leave-displayed-math!)
  (and-with math-node (tree-innermost 'math)
    (go-end-of 'math)
    (go-right)
    (insert-return)
  ) ;and-with
) ;define

(define (mogan-test-latex->stree latex-code)
  (tree->stree (latex->texmacs (parse-latex latex-code)))
) ;define

(define (mogan-test-strip-single-document-wrapper stree)
  (if (and (pair? stree)
           (eq? (car stree) 'document)
           (pair? (cdr stree))
           (null? (cddr stree)))
      (cadr stree)
      stree
  ) ;if
) ;define

(define (mogan-test-inline-latex->stree formula)
  (mogan-test-latex->stree (string-append "\\(" formula "\\)"))
) ;define

(define (mogan-test-display-latex->stree formula)
  (mogan-test-latex->stree (string-append "\\[" formula "\\]"))
) ;define

(define (mogan-test-inline-math-content stree)
  (if (and (pair? stree) (eq? (car stree) 'math))
      (let ((body (cdr stree)))
        (cond
          ((null? body) "")
          ((null? (cdr body))
           (car body)
          ) ;
          (else
           (cons 'concat body)
          ) ;else
        ) ;cond
      ) ;let
      stree
  ) ;if
) ;define

(tm-service (mogan-test-insert-equation formula)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-equation formula="
      formula
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (when (in-math?)
      (mogan-test-leave-inline-math!)
    ) ;when
    (insert
      (mogan-test-strip-single-document-wrapper
        (mogan-test-display-latex->stree formula)
      ) ;mogan-test-strip-single-document-wrapper
    ) ;insert
    (mogan-test-leave-displayed-equation!)
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-inline-equation formula)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-inline-equation formula="
      formula
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (let ((parsed-stree (mogan-test-inline-latex->stree formula)))
      (if (in-math?)
          (insert (mogan-test-inline-math-content parsed-stree))
          (insert parsed-stree)
      ) ;if
    ) ;let
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-matrix rows cols data)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-matrix rows="
      (object->string* rows)
      " cols="
      (object->string* cols)
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (let* ((row-count (if (number? rows) rows (string->number rows)))
           (col-count (if (number? cols) cols (string->number cols)))
           (cells
             (cond
               ((list? data) data)
               ((string? data)
                (mogan-test-split-words data)
               ) ;
               (else
                '()
               ) ;else
             ) ;cond
           )) ;let*
      (cond
        ((not row-count)
         (server-error envelope (string-append "invalid rows: " (object->string* rows))))
        ((not col-count)
         (server-error envelope (string-append "invalid cols: " (object->string* cols))))
        ((not (= (length cells) (* row-count col-count)))
         (server-error envelope
                       (string-append "matrix cell count mismatch: expected "
                                      (number->string (* row-count col-count))
                                      ", got "
                                      (number->string (length cells))
                       ) ;string-append
         ) ;server-error
        )
        (else
         (let ((matrix-content (mogan-test-build-matrix row-count col-count cells)))
           (when (in-math?)
             (mogan-test-leave-inline-math!)
           ) ;when
           (insert `(equation* (document ,matrix-content)))
           (mogan-test-leave-displayed-equation!)
           (mogan-test-return-control-state envelope)
         ) ;let
        ) ;else
      ) ;cond
    ) ;let*
  ) ;when
) ;tm-service

(define (mogan-test-build-matrix rows cols data)
  `(matrix
     (table
       ,@(let loop ((r 0)
                    (cells data)
                    (result '()))
           (if (= r rows)
               (reverse result)
               (let row-loop ((c 0)
                              (remaining cells)
                              (row-cells '()))
                 (if (= c cols)
                     (loop (+ r 1)
                           remaining
                           (cons `(row ,@(reverse row-cells)) result))
                     (row-loop (+ c 1)
                               (cdr remaining)
                               (cons `(cell ,(car remaining)) row-cells))))))))
) ;define

(define (mogan-test-filter pred items)
  (cond
    ((null? items) '())
    ((pred (car items))
     (cons (car items) (mogan-test-filter pred (cdr items))))
    (else
     (mogan-test-filter pred (cdr items)))
  ) ;cond
) ;define

(define (mogan-test-whitespace? ch)
  (or (char=? ch #\space)
      (char=? ch #\tab)
      (char=? ch #\newline)
      (char=? ch #\return)
  ) ;or
) ;define

(define (mogan-test-split-words text)
  (let ((len (string-length text)))
    (let loop ((index 0)
               (start #f)
               (result '()))
      (if (= index len)
          (reverse
            (if start
                (cons (substring text start index) result)
                result
            ) ;if
          ) ;reverse
          (let ((ch (string-ref text index)))
            (if (mogan-test-whitespace? ch)
                (loop
                  (+ index 1)
                  #f
                  (if start
                      (cons (substring text start index) result)
                      result
                  ) ;if
                ) ;loop
                (loop
                  (+ index 1)
                  (if start start index)
                  result
                ) ;loop
            ) ;if
          ) ;let
      ) ;if
    ) ;let loop
  ) ;let
) ;define

(tm-service (mogan-test-insert-fraction numerator denominator)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-fraction num="
      numerator " den=" denominator
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (mogan-test-insert-inline-math-tree! `(frac ,numerator ,denominator))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-sqrt content)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-sqrt content="
      content
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (mogan-test-insert-inline-math-tree! `(sqrt ,content))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-nth-root n content)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-nth-root n="
      (number->string n) " content=" content
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (mogan-test-insert-inline-math-tree! `(sqrt ,(number->string n) ,content))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-sup sub sup)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-sup sub="
      sub " sup=" sup
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (mogan-test-insert-inline-math-tree! `(concat ,sub (rsup ,sup)))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-sub sub)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-sub sub="
      sub
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (mogan-test-insert-inline-math-tree! `(concat ,sub (rsub "")))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-sum from to body)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-sum from="
      from " to=" to " body=" body
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (mogan-test-insert-inline-math-tree! `(sum ( dessous ,from ,to) ,body))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-product from to body)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-product from="
      from " to=" to " body=" body
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (mogan-test-insert-inline-math-tree! `(product (dessous ,from ,to) ,body))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-integral from to body)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-integral from="
      from " to=" to " body=" body
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (mogan-test-insert-inline-math-tree! `(integral (integral ,from ,to) ,body))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-limit direction body)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-limit direction="
      direction " body=" body
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (mogan-test-insert-inline-math-tree! `(limit (lim ,direction) ,body))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-table rows cols)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-table rows="
      (object->string* rows)
      " cols="
      (object->string* cols)
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (let ((row-count (if (number? rows) rows (string->number rows)))
          (col-count (if (number? cols) cols (string->number cols))))
      (if (not row-count)
          (server-error envelope (string-append "invalid rows: " (object->string* rows)))
          (if (not col-count)
              (server-error envelope (string-append "invalid cols: " (object->string* cols)))
              (let ((table (mogan-test-build-table row-count col-count)))
                (insert table)
                (mogan-test-return-control-state envelope)
              ) ;let
          ) ;if
      ) ;if
    ) ;let
  ) ;when
) ;tm-service

(define (mogan-test-build-table rows cols)
  (let ((header-cells (map (lambda (c) `(cell "(header)")) (number-list 1 cols)))
        (body-cells (map (lambda (c) `(cell "")) (number-list 1 (* rows cols)))))
    `(document
       (table
         (tformat
           (cwith "1" "1" "1" ,(number->string cols) (cprop "c" "l" "c"))
           (cwith "2" ,(number->string rows) "1" ,(number->string cols) (cprop "c" "l" "c"))
           (row (cell "") ,@header-cells)
           ,@(let loop ((r 2) (result '()))
               (if (> r rows)
                   (reverse result)
                   (let
                     ((row-cells
                        (map (lambda (c) `(cell ""))
                            (number-list 1 cols))))
                     (loop (+ r 1)
                           (cons `(row ,@row-cells) result))))))))
  ) ;let
) ;define

(define (number-list start end)
  (if (> start end)
      '()
      (cons start (number-list (+ start 1) end))
  ) ;if
) ;define

(tm-service (mogan-test-insert-block blocks)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-block blocks="
      blocks
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (insert `(concat ,@(map (lambda (b) `(rgroup ,b)) blocks)))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-vertical-space size)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-vertical-space size="
      (number->string size)
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (insert `(space ,(number->string size)))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-bold text)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-bold text="
      text
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (insert `(bold ,text))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-bold-b64 b64-text)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-bold-b64 bytes="
      (number->string (string-length b64-text))
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (insert `(bold ,(mogan-test-decode-utf8-text b64-text)))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-italic text)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-italic text="
      text
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (insert `(it ,text))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-italic-b64 b64-text)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-italic-b64 bytes="
      (number->string (string-length b64-text))
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (insert `(it ,(mogan-test-decode-utf8-text b64-text)))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-code text)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-code text="
      text
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (insert `(code ,text))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-code-b64 b64-text)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-code-b64 bytes="
      (number->string (string-length b64-text))
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (insert `(code ,(mogan-test-decode-utf8-text b64-text)))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-link url text)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-link url="
      url " text=" text
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (insert `(hlink ,text ,url))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service

(tm-service (mogan-test-insert-link-b64 url b64-text)
  (mogan-test-server-log
    (string-append
      "mogan-server-runtime: insert-link-b64 url="
      url " bytes=" (number->string (string-length b64-text))
    ) ;string-append
  ) ;mogan-test-server-log
  (when (mogan-test-require-login envelope)
    (insert `(hlink ,(mogan-test-decode-utf8-text b64-text) ,url))
    (mogan-test-return-control-state envelope)
  ) ;when
) ;tm-service
