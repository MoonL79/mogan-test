; mogan-cli.scm - Minimal Mogan test platform controller
;
; This CLI runs in Goldfish Scheme and provides:
;   - structured status about the required Mogan runtime workflow
;   - stable command routing for the test platform
;   - honest reporting about the live `-server` connection model

(import (liii base)
        (liii json)
        (scheme base)
        (scheme file)
        (scheme process-context))

(define (bootstrap-string-suffix? suffix s)
  (let ((suffix-length (string-length suffix))
        (s-length (string-length s)))
    (and (>= s-length suffix-length)
         (equal? (substring s (- s-length suffix-length) s-length) suffix))))

(define (bootstrap-script-arg? arg)
  (and (> (string-length arg) 13)
       (bootstrap-string-suffix? "mogan-cli.scm" arg)))

(define (bootstrap-dirname path)
  (let loop ((index (- (string-length path) 1)))
    (cond
      ((< index 0) ".")
      ((char=? (string-ref path index) #\/)
       (if (= index 0)
           "/"
           (substring path 0 index)))
      (else
       (loop (- index 1))))))

(define (bootstrap-script-dir args)
  (let loop ((remaining args))
    (cond
      ((null? remaining) #f)
      ((bootstrap-script-arg? (car remaining))
       (bootstrap-dirname (car remaining)))
      (else
       (loop (cdr remaining))))))

(define *bootstrap-script-dir* (bootstrap-script-dir (command-line)))

(load (if *bootstrap-script-dir*
          (string-append *bootstrap-script-dir* "/commands/common.scm")
          "src/cli/commands/common.scm"))
(init-script-context! (command-line))
(load (script-relative-path "batch.scm"))
(load (script-relative-path "target.scm"))
(load (script-relative-path "file.scm"))
(load (script-relative-path "search.scm"))
(load (script-relative-path "edit.scm"))
(load (script-relative-path "buffer.scm"))
(load (script-relative-path "router.scm"))

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
