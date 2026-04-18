(define *commands*
  `(("status" . ,cmd-status)
    ("workflow" . ,cmd-workflow)
    ("connect" . ,cmd-connect)))

(define *usage-core-lines*
  (list
    "Usage: mogan-cli <command> [args...]"
    "Commands:"
    "  status        - Show current runtime and connection status as JSON"
    "  workflow      - Show the required Mogan startup workflow"
    "  build-client  - Build Mogan with `xmake b stem`"
    "  start-client  - Start a full Mogan client with `xmake r stem`"
    "  start-server  - Start a connectable Mogan client with `-server` enabled"
    "  exec-internal - Start Mogan and execute internal Scheme through `-x`"
    "  create-account - Create a test account through the remote service path"
    "  connect       - Attempt remote-login through Mogan internal Scheme"
    "  ping          - Call the server-side ping service"
    "  current-buffer - Query the current buffer from the running Mogan instance"
    "  new-document  - Create a new document through the running Mogan instance"
    "  write-text    - Replace the current buffer body with plain text"
    "  buffer-text   - Read back the current buffer body as plain text"
    "  state         - Inspect buffer, cursor, selection, and text state"
    "  move/select   - Cursor, selection, history, clipboard, insert, delete, save, and switch primitives"
    "  batch         - Run a sequence of control commands against one target"))

(define (dispatch command args)
  (let ((handler (assoc command *commands*)))
    (if handler
        ((cdr handler) args)
        (make-error
          (string-append "Unknown command: " command)
          (cons "available" *available-commands*)))))

(define (show-usage)
  (for-each
    (lambda (line)
      (display line)
      (newline))
    (append *usage-core-lines* *usage-file-lines* *usage-search-lines*)))
