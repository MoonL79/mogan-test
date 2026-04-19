(define *mogan-root* "/home/mingshen/git/mogan")
(define *build-command* "xmake b stem")
(define *run-command* "xmake r stem")
(define *start-server-command*
  "TEXMACS_PATH=/home/mingshen/git/mogan/TeXmacs <moganstem> -server -x <runtime>")
(define *internal-command* "TEXMACS_PATH=/home/mingshen/git/mogan/TeXmacs <moganstem> -d -debug-bench -x <scheme>")
(define *default-host* "127.0.0.1")
(define *default-port* 6561)

(define *connect-trace-path* "/tmp/mogan-test-connect-trace.log")
(define *server-trace-path* "/tmp/mogan-test-server-trace.log")
(define *runtime-result-path* "/tmp/mogan-test-runtime-result.txt")
(define *runtime-output-path* "/tmp/mogan-test-runtime-output.log")

(define *available-commands*
  "status, workflow, connect, build-client, start-client, start-server, exec-internal, create-account, ping, current-buffer, new-document, write-text, stream-text, buffer-text, state, move-left, move-right, move-up, move-down, move-start, move-end, move-start-line, move-end-line, move-start-paragraph, move-end-paragraph, move-word-left, move-word-right, move-to-line, move-to-column, select-all, select-start, select-end, clear-selection, undo, redo, copy, cut, paste, clear-undo-history, insert-text, insert-session, insert-return, exit-right, delete-left, delete-right, save-buffer, export-buffer, set-main-style, set-document-language, add-style-package, remove-style-package, set-page-medium, set-page-type, set-page-orientation, search-state, search-set, search-next, search-prev, search-first, search-last, replace-set, replace-one, replace-all, session-evaluate, session-evaluate-all, session-evaluate-above, session-evaluate-below, session-interrupt, session-stop, buffer-list, open-file, save-as, revert-buffer, close-buffer, switch-buffer, insert-section, insert-subsection, insert-subsubsection, batch, target, session, scenario")

(define *script-path* #f)
(define *script-dir* #f)

(define (make-response status data)
  (cons (cons "status" status) data))

(define (make-success . data)
  (make-response "ok" data))

(define (make-error message . extra)
  (make-response "error" (cons (cons "message" message) extra)))

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

(define (script-arg? arg)
  (and (> (string-length arg) 13)
       (string-suffix? "mogan-cli.scm" arg)))

(define (status-ok? result)
  (equal? (cdr (assoc "status" result)) "ok"))

(define (pathname-dirname path)
  (let loop ((index (- (string-length path) 1)))
    (cond
      ((< index 0) ".")
      ((char=? (string-ref path index) #\/)
       (if (= index 0)
           "/"
           (substring path 0 index)))
      (else
       (loop (- index 1))))))

(define (init-script-context! args)
  (let loop ((remaining args))
    (cond
      ((null? remaining) #f)
      ((script-arg? (car remaining))
       (begin
         (set! *script-path* (car remaining))
         (set! *script-dir* (pathname-dirname (car remaining)))
         #t))
      (else
       (loop (cdr remaining))))))

(define (script-relative-path leaf)
  (if *script-dir*
      (string-append *script-dir* "/commands/" leaf)
      (string-append "src/cli/commands/" leaf)))
