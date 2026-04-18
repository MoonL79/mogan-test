(import (liii base)
        (liii os)
        (liii path)
        (liii string)
        (scheme base)
        (scheme file)
        (scheme process-context)
) ;import

(define *cli* "./bin/mogan-cli")
(define *failed* 0)
(define *temp-counter* 0)

(define *live-mode* #f)
(define *expect-services* #f)

(define *live-host* "")
(define *live-pseudo* "")
(define *live-name* "")
(define *live-pass* "")
(define *live-email* "")

(define *target-test-dir* "")
(define *file-test-path* "")
(define *export-test-path* "")

(define *esc* (string (integer->char 27)))
(define *red* (string-append *esc* "[0;31m"))
(define *green* (string-append *esc* "[0;32m"))
(define *nc* (string-append *esc* "[0m"))

(define (pass msg)
  (display *green*)
  (display "PASS")
  (display *nc*)
  (display ": ")
  (display msg)
  (newline)
) ;define

(define (fail msg)
  (display *red*)
  (display "FAIL")
  (display *nc*)
  (display ": ")
  (display msg)
  (newline)
  (set! *failed* (+ *failed* 1))
) ;define

(define (stringify x)
  (cond
    ((string? x) x)
    ((number? x) (number->string x))
    ((boolean? x) (if x "#t" "#f"))
    (else (object->string x))
  ) ;cond
) ;define

(define (temp-path prefix suffix)
  (set! *temp-counter* (+ *temp-counter* 1))
  (path-join (os-temp-dir)
             (string-append prefix
                            "-"
                            (number->string (getpid))
                            "-"
                            (number->string *temp-counter*)
                            suffix
             ) ;string-append
  ) ;path-join
) ;define

(define (safe-unlink path)
  (if (and (string? path) (not (string-null? path)) (file-exists? path))
      (path-unlink path #t)
      #f
  ) ;if
) ;define

(define (safe-rmtree path)
  (if (and (string? path) (not (string-null? path)) (file-exists? path))
      (os-call (string-append "rm -rf " (shell-quote path)))
      0
  ) ;if
) ;define

(define (cleanup)
  (safe-rmtree *target-test-dir*)
  (safe-unlink *file-test-path*)
  (safe-unlink *export-test-path*)
) ;define

(define (shell-quote value)
  (string-append "'"
                 (string-join (string-split value #\')
                              "'\"'\"'"
                 ) ;string-join
                 "'"
  ) ;string-append
) ;define

(define (contains-all? text patterns)
  (let loop ((rest patterns))
    (if (null? rest)
        #t
        (if (string-contains? text (car rest))
            (loop (cdr rest))
            #f
        ) ;if
    ) ;if
  ) ;let
) ;define

(define (access-ok? path mode)
  (let ((result (access path mode)))
    (if (boolean? result)
        result
        (= result 0)
    ) ;if
  ) ;let
) ;define

(define (check-file-contains path pattern)
  (if (file-exists? path)
      (string-contains? (path-read-text path) pattern)
      #f
  ) ;if
) ;define

(define (command-after-script)
  (let loop ((remaining (command-line)))
    (cond
      ((null? remaining) '())
      ((string-ends? (car remaining) "validate.scm")
       (cdr remaining)
      ) ;
      (else
       (loop (cdr remaining))
      ) ;else
    ) ;cond
  ) ;let
) ;define

(define (flag-present? args flag)
  (let loop ((remaining args))
    (cond
      ((null? remaining) #f)
      ((string=? (car remaining) flag) #t)
      (else
       (loop (cdr remaining))
      ) ;else
    ) ;cond
  ) ;let
) ;define

(define (env-default key fallback)
  (let ((value (get-environment-variable key)))
    (if value value fallback)
  ) ;let
) ;define

(define (env-prefix envs)
  (if (null? envs)
      ""
      (string-append
        (string-join
          (map
            (lambda (pair)
              (string-append (car pair) "=" (shell-quote (cdr pair)))
            ) ;lambda
            envs
          ) ;map
          " "
        ) ;string-join
        " "
      ) ;string-append
  ) ;if
) ;define

(define (command->string program args)
  (string-join (cons (shell-quote program) (map shell-quote args)) " ")
) ;define

(define (cli-command . args)
  (command->string *cli* args)
) ;define

(define (cli-command/env envs . args)
  (string-append (env-prefix envs) (apply cli-command args))
) ;define

(define (run-command raw-command)
  (let*
    ((script-path (temp-path "mogan-validate-script" ".sh"))
     (output-path (temp-path "mogan-validate-output" ".log"))
     (full-command
       (string-append raw-command
                      " > "
                      (shell-quote output-path)
                      " 2>&1"
       ) ;string-append
     ) ;full-command
     (status 0)
     (output "")
    ) ;
    (path-write-text script-path (string-append "#!/bin/sh\n" full-command "\n"))
    (set! status (os-call (command->string "sh" (list script-path))))
    (set! output (if (file-exists? output-path)
                     (path-read-text output-path)
                     "")
    ) ;set!
    (safe-unlink script-path)
    (safe-unlink output-path)
    (list (cons 'status status)
          (cons 'output output)
    ) ;list
  ) ;let*
) ;define

(define (result-status result)
  (cdr (assoc 'status result))
) ;define

(define (result-output result)
  (cdr (assoc 'output result))
) ;define

(define (command-output raw-command)
  (result-output (run-command raw-command))
) ;define

(define (test-output-contains pass-msg fail-msg output patterns)
  (if (contains-all? output patterns)
      (pass pass-msg)
      (fail (string-append fail-msg output))
  ) ;if
) ;define

(define (test-command-contains pass-msg fail-msg raw-command patterns)
  (test-output-contains pass-msg fail-msg (command-output raw-command) patterns)
) ;define

(define (run-bulk-command-check cases)
  (let loop ((remaining cases)
             (failures '()))
    (if (null? remaining)
        (reverse failures)
        (let* ((entry (car remaining))
               (label (car entry))
               (command (cadr entry))
               (needle (caddr entry))
               (output (command-output command)))
          (if (string-contains? output needle)
              (loop (cdr remaining) failures)
              (loop (cdr remaining) (cons label failures))
          ) ;if
        ) ;let*
    ) ;if
  ) ;let
) ;define

(define (run-status-bulk-check cases)
  (let loop ((remaining cases)
             (failures '()))
    (if (null? remaining)
        (reverse failures)
        (let* ((entry (car remaining))
               (label (car entry))
               (output (cadr entry))
               (needle (caddr entry)))
          (if (string-contains? output needle)
              (loop (cdr remaining) failures)
              (loop (cdr remaining) (cons label failures))
          ) ;if
        ) ;let*
    ) ;if
  ) ;let
) ;define

(define (save-test-target!)
  (run-command
    (cli-command/env
      (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
      "target"
      "save"
      "smoke"
      *live-host*
      *live-pseudo*
      *live-name*
      *live-pass*
      *live-email*
    ) ;cli-command/env
  ) ;run-command
) ;define

(define (print-header)
  (display "=== Mogan Test Platform Validation ===")
  (newline)
  (newline)
) ;define

(define (print-summary)
  (newline)
  (display "=== Validation Summary ===")
  (newline)
  (if (= *failed* 0)
      (begin
        (display *green*)
        (display "All tests passed!")
        (display *nc*)
        (newline)
        (newline)
        (display "Runtime Note:")
        (newline)
        (display "  - Build with: ./mogan-cli build-client")
        (newline)
        (display "  - Start a connectable runtime with: ./mogan-cli start-server")
        (newline)
        (display "  - Or point --live validation at your own running moganstem -server instance")
        (newline)
        (display "  - Inspect account bootstrap with: ./mogan-cli create-account --dry-run")
        (newline)
        (display "  - Inspect connect/login with: ./mogan-cli connect --dry-run")
        (newline)
        (display "  - Inspect server-side test services with: ./mogan-cli ping --dry-run")
        (newline)
        (display "  - Inspect text round-trip with: ./mogan-cli write-text --dry-run")
        (newline)
        (display "  - Inspect control primitives with: ./mogan-cli state --dry-run")
        (newline)
        (display "  - Inspect history primitives with: ./mogan-cli undo --dry-run")
        (newline)
        (display "  - Inspect clipboard primitives with: ./mogan-cli copy --dry-run")
        (newline)
        (display "  - Inspect file lifecycle primitives with: ./mogan-cli open-file /tmp/example.tm --dry-run")
        (newline)
        (display "  - Inspect export primitives with: ./mogan-cli export-buffer /tmp/example.html --dry-run")
        (newline)
        (display "  - Inspect style primitives with: ./mogan-cli set-main-style article --dry-run")
        (newline)
        (display "  - Inspect layout primitives with: ./mogan-cli set-page-medium papyrus --dry-run")
        (newline)
        (display "  - Inspect search primitives with: ./mogan-cli search-set alpha --dry-run")
        (newline)
        (display "  - Save a target profile with: ./mogan-cli target save smoke")
        (newline)
        (display "  - Inspect batch workflows with: ./mogan-cli batch smoke -- new-document -- buffer-text")
        (newline)
        (display "  - Run a smoke scenario with: ./mogan-cli scenario smoke-edit")
        (newline)
        (display "  - Run the batch scenario with: ./mogan-cli scenario batch-smoke smoke")
        (newline)
        (display "  - Run the file scenario with: ./mogan-cli scenario file-smoke smoke /tmp/example.tm")
        (newline)
        (display "  - Run the export scenario with: ./mogan-cli scenario export-smoke smoke /tmp/example.html")
        (newline)
        (display "  - Run the style scenario with: ./mogan-cli scenario style-smoke smoke")
        (newline)
        (display "  - Run the layout scenario with: ./mogan-cli scenario layout-smoke smoke")
        (newline)
        (display "  - Run the search scenario with: ./mogan-cli scenario search-smoke smoke")
        (newline)
        (display "  - Run the history scenario with: ./mogan-cli scenario history-smoke smoke")
        (newline)
        (display "  - Run the clipboard scenario with: ./mogan-cli scenario clipboard-smoke smoke")
        (newline)
        (display "  - Inspect trace and runtime files with: ./mogan-cli traces")
        (newline)
        (display "  - Run live validation with: gf run scripts/validate.scm --live")
        (newline)
        (display "  - Add --expect-services when the target server loaded mogan-server-runtime.scm")
        (newline)
        (exit 0)
      ) ;begin
      (begin
        (display *red*)
        (display (number->string *failed*))
        (display " test(s) failed")
        (display *nc*)
        (newline)
        (exit 1)
      ) ;begin
  ) ;if
) ;define

(define (initialize!)
  (let ((args (command-after-script)))
    (set! *live-mode* (flag-present? args "--live"))
    (set! *expect-services* (flag-present? args "--expect-services"))
  ) ;let
  (set! *live-host* (env-default "MOGAN_TEST_HOST" "127.0.0.1"))
  (set! *live-pseudo* (env-default "MOGAN_TEST_PSEUDO" "test-user"))
  (set! *live-name* (env-default "MOGAN_TEST_NAME" "Test User"))
  (set! *live-pass* (env-default "MOGAN_TEST_PASS" "test-pass"))
  (set! *live-email* (env-default "MOGAN_TEST_EMAIL" "test@example.com"))
  (set! *target-test-dir* (temp-path "mogan-test-targets" ""))
  (set! *file-test-path* (temp-path "mogan-test-file" ".tm"))
  (set! *export-test-path* (temp-path "mogan-test-export" ".html"))
  (mkdir *target-test-dir*)
  (safe-unlink *export-test-path*)
) ;define

(define (run-static-tests)
  (let ((status-output "")
        (workflow-output "")
        (batch-dry-run-output "")
        (scenario-batch-dry-run-output "")
        (scenario-history-dry-run-output "")
        (scenario-clipboard-dry-run-output "")
        (scenario-file-dry-run-output "")
        (scenario-export-dry-run-output "")
        (scenario-style-dry-run-output "")
        (scenario-layout-dry-run-output "")
        (scenario-search-dry-run-output ""))
    (display "Test 1: CLI script exists...")
    (if (file-exists? *cli*)
        (pass "CLI script exists")
        (fail (string-append "CLI script not found at " *cli*))
    ) ;if

    (display "Test 2: CLI script is executable...")
    (if (access-ok? *cli* 'X_OK)
        (pass "CLI script is executable")
        (fail "CLI script is not executable")
    ) ;if

    (display "Test 3: Scheme runtime files exist...")
    (if (and (file-exists? "./src/cli/mogan-cli.scm")
             (file-exists? "./src/cli/runtime/client.scm")
             (file-exists? "./src/cli/runtime/mogan-server-runtime.scm"))
        (pass "CLI and runtime Scheme files exist")
        (fail "Required Scheme files are missing")
    ) ;if

    (display "Test 4: CLI returns usage without arguments...")
    (test-command-contains
      "Usage message displayed"
      "Usage message not displayed: "
      (cli-command)
      (list "Usage:")
    ) ;test-command-contains

    (display "Test 5: Status command returns JSON...")
    (set! status-output (command-output (cli-command "status")))
    (if (string-contains? status-output "\"status\"")
        (pass "Status output contains status field")
        (fail (string-append "Status output missing status field: " status-output))
    ) ;if

    (display "Test 6: Status reports build and server-capable startup paths...")
    (test-output-contains
      "Status reports both full-client and server-capable startup paths"
      "Status output missing startup path details: "
      status-output
      (list "\"build_command\":\"xmake b stem\""
            "\"run_command\":\"xmake r stem\""
            "\"start_server_command\""
      ) ;list
    ) ;test-output-contains

    (display "Test 7: Workflow command reports the explicit server-first workflow...")
    (set! workflow-output (command-output (cli-command "workflow")))
    (test-output-contains
      "Workflow reports the explicit server startup and runtime requirement"
      "Workflow output missing the expected explicit server workflow: "
      workflow-output
      (list "create-account" "start-server" "mogan-server-runtime.scm")
    ) ;test-output-contains

    (display "Test 8: Status reports the internal runtime dispatch path...")
    (test-output-contains
      "Status exposes the Mogan internal Scheme dispatch path"
      "Status does not expose the internal runtime dispatch path: "
      status-output
      (list "\"internal_command\":\"TEXMACS_PATH=\\/home\\/mingshen\\/git\\/mogan\\/TeXmacs <moganstem> -d -debug-bench -x <scheme>\""
            "\"mogan_layer\""
      ) ;list
    ) ;test-output-contains

    (display "Test 9: start-server dry-run builds the connectable server command...")
    (test-command-contains
      "start-server dry-run prints the connectable server command"
      "start-server dry-run did not print the expected server command: "
      (cli-command "start-server" "--dry-run")
      (list "moganstem" "-server" "mogan-server-runtime.scm")
    ) ;test-command-contains

    (display "Test 10: exec-internal dry-run builds the runtime command...")
    (test-command-contains
      "exec-internal dry-run prints the Mogan runtime command"
      "exec-internal dry-run did not print the expected command: "
      (cli-command "exec-internal" "--dry-run")
      (list "moganstem" "-x")
    ) ;test-command-contains

    (display "Test 11: connect dry-run builds the remote-login command...")
    (test-command-contains
      "connect dry-run prints the remote-login runtime command"
      "connect dry-run did not print the expected remote-login command: "
      (cli-command "connect" "--dry-run")
      (list "mogan-test-connect" "moganstem")
    ) ;test-command-contains

    (display "Test 12: create-account dry-run builds the account command...")
    (test-command-contains
      "create-account dry-run prints the account creation command"
      "create-account dry-run did not print the expected command: "
      (cli-command "create-account" "--dry-run")
      (list "mogan-test-create-account" "moganstem")
    ) ;test-command-contains

    (display "Test 13: target profiles store and replay runtime defaults...")
    (let
      ((target-save-output
         (command-output
           (cli-command/env
             (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
             "target" "save" "smoke" *live-host* *live-pseudo* *live-name* *live-pass* *live-email*)
           ) ;cli-command/env
         ) ;command-output
       (target-show-output
         (command-output
           (cli-command/env
             (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
             "target" "show" "smoke"
           ) ;cli-command/env
         ) ;command-output
       ) ;target-show-output
       (target-list-output
         (command-output
           (cli-command/env
             (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
             "target" "list"
           ) ;cli-command/env
         ) ;command-output
       ) ;target-list-output
       (target-run-output
         (command-output
           (cli-command/env
             (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
             "target" "run" "smoke" "state" "--dry-run"
           ) ;cli-command/env
         ) ;command-output
       ) ;target-run-output
       (target-scenario-output
         (command-output
           (cli-command/env
             (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
             "target" "run" "smoke" "scenario" "smoke-edit" "--dry-run"
           ) ;cli-command/env
         ) ;command-output
       ) ;target-scenario-output
      ) ;
      (if (and (file-exists? (path-join *target-test-dir* "smoke.target"))
               (contains-all? target-show-output (list (string-append "host=" *live-host*)
                                                       (string-append "pseudo=" *live-pseudo*))
               ) ;contains-all?
               (string-contains? target-list-output "smoke")
               (string-contains? target-run-output "mogan-test-state")
               (string-contains? target-scenario-output "mogan-test-smoke-edit"))
          (pass "Target profiles can be saved, shown, listed, and replayed")
          (fail (string-append "Target profile workflow failed: "
                               target-save-output
                               " | "
                               target-show-output
                               " | "
                               target-list-output
                               " | "
                               target-run-output
                               " | "
                               target-scenario-output)
          ) ;fail
      ) ;if
    ) ;let

    (display "Test 14: batch dry-runs chain low-level commands...")
    (set! batch-dry-run-output
          (command-output
            (cli-command/env
              (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
              "batch" "smoke" "--dry-run" "--"
              "new-document" "--"
              "insert-text" "hello from mogan-test" "--"
              "move-end" "--"
              "insert-text" "!" "--"
              "buffer-text"
            ) ;cli-command/env
          ) ;command-output
    ) ;set!
    (set! scenario-batch-dry-run-output
          (command-output
            (cli-command/env
              (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
              "scenario" "batch-smoke" "smoke" "--dry-run"
            ) ;cli-command/env
          ) ;command-output
    ) ;set!
    (set! scenario-history-dry-run-output
          (command-output
            (cli-command/env
              (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
              "scenario" "history-smoke" "smoke" "--dry-run"
            ) ;cli-command/env
          ) ;command-output
    ) ;set!
    (set! scenario-clipboard-dry-run-output
          (command-output
            (cli-command/env
              (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
              "scenario" "clipboard-smoke" "smoke" "--dry-run"
            ) ;cli-command/env
          ) ;command-output
    ) ;set!
    (if (and (contains-all? batch-dry-run-output
                            (list "mogan-test-new-document"
                                  "mogan-test-move-end"
                                  "mogan-test-insert-text"
                                  "mogan-test-buffer-text")
                            ) ;list
             (contains-all? scenario-batch-dry-run-output
                            (list "mogan-test-new-document"
                                  "mogan-test-buffer-text"
                            ) ;list
             ) ;contains-all?
             (contains-all? scenario-history-dry-run-output
                            (list "mogan-test-history-undo"
                                  "mogan-test-history-redo"
                                  "mogan-test-clear-history"
                            ) ;list
             ) ;contains-all?
             (contains-all? scenario-clipboard-dry-run-output
                            (list "mogan-test-clipboard-copy"
                                  "mogan-test-clipboard-paste")
                            ) ;list
             ) ;contains-all?
        (pass "Batch dry-runs print the expected chained controller commands")
        (fail (string-append "Batch dry-run workflow failed: "
                             batch-dry-run-output
                             " | "
                             scenario-batch-dry-run-output
                             " | "
                             scenario-history-dry-run-output
                             " | "
                             scenario-clipboard-dry-run-output)
        ) ;fail
    ) ;if

    (display "Test 15: control dry-runs build the expected controller commands...")
    (let
      ((control-failures
         (run-bulk-command-check
           (list
             (list "ping" (cli-command "ping" "--dry-run") "mogan-test-ping")
             (list "current-buffer" (cli-command "current-buffer" "--dry-run") "mogan-test-current-buffer")
             (list "new-document" (cli-command "new-document" "--dry-run") "mogan-test-new-document")
             (list "write-text" (cli-command "write-text" "--dry-run") "mogan-test-write-text")
             (list "buffer-text" (cli-command "buffer-text" "--dry-run") "mogan-test-buffer-text")
             (list "state" (cli-command "state" "--dry-run") "mogan-test-state")
             (list "move-left" (cli-command "move-left" "--dry-run") "mogan-test-move-left")
             (list "move-to-line" (cli-command "move-to-line" "--dry-run") "mogan-test-move-to-line")
             (list "select-all" (cli-command "select-all" "--dry-run") "mogan-test-select-all")
             (list "insert-text" (cli-command "insert-text" "--dry-run") "mogan-test-insert-text")
             (list "delete-left" (cli-command "delete-left" "--dry-run") "mogan-test-delete-left")
             (list "save-buffer" (cli-command "save-buffer" "--dry-run") "mogan-test-save-buffer")
             (list "switch-buffer" (cli-command "switch-buffer" "--dry-run") "mogan-test-switch-buffer")
             (list "undo" (cli-command "undo" "--dry-run") "mogan-test-history-undo")
             (list "redo" (cli-command "redo" "--dry-run") "mogan-test-history-redo")
             (list "copy" (cli-command "copy" "--dry-run") "mogan-test-clipboard-copy")
             (list "cut" (cli-command "cut" "--dry-run") "mogan-test-clipboard-cut")
             (list "paste" (cli-command "paste" "--dry-run") "mogan-test-clipboard-paste")
             (list "clear-undo-history" (cli-command "clear-undo-history" "--dry-run") "mogan-test-clear-history")
             (list "set-page-medium" (cli-command "set-page-medium" "papyrus" "--dry-run") "mogan-test-set-page-medium")
             (list "set-page-type" (cli-command "set-page-type" "letter" "--dry-run") "mogan-test-set-page-type")
             (list "set-page-orientation" (cli-command "set-page-orientation" "landscape" "--dry-run") "mogan-test-set-page-orientation"))
           ) ;list
         ) ;run-bulk-command-check
      ) ;
      (if (null? control-failures)
          (pass "Control dry-runs print the expected controller commands")
          (fail (string-append "One or more service dry-runs were incorrect: "
                               (string-join control-failures ", "))
          ) ;fail
      ) ;if
    ) ;let

    (display "Test 16: file dry-runs build the expected lifecycle commands...")
    (set! scenario-file-dry-run-output
          (command-output
            (cli-command/env
              (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
              "scenario" "file-smoke" "smoke" *file-test-path* "--dry-run"
            ) ;cli-command/env
          ) ;command-output
    ) ;set!
    (if (and (string-contains? (command-output (cli-command "open-file" *file-test-path* "--dry-run"))
                               "mogan-test-open-file")
             (string-contains? (command-output (cli-command "save-as" *file-test-path* "--dry-run"))
                               "mogan-test-save-as"
             ) ;string-contains?
             (string-contains? (command-output (cli-command "buffer-list" "--dry-run"))
                               "mogan-test-buffer-list"
             ) ;string-contains?
             (string-contains? (command-output (cli-command "revert-buffer" "--dry-run"))
                               "mogan-test-revert-buffer"
             ) ;string-contains?
             (string-contains? (command-output (cli-command "close-buffer" "--dry-run"))
                               "mogan-test-close-buffer"
             ) ;string-contains?
             (contains-all? scenario-file-dry-run-output
                            (list "mogan-test-open-file"
                                  "mogan-test-save-as"
                                  "mogan-test-close-buffer")
                            ) ;list
             ) ;contains-all?
        (pass "File dry-runs print the expected lifecycle commands")
        (fail "File dry-run workflow failed")
    ) ;if

    (display "Test 17a: export dry-runs build the expected export commands...")
    (set! scenario-export-dry-run-output
          (command-output
            (cli-command/env
              (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
              "scenario" "export-smoke" "smoke" *export-test-path* "--dry-run"
            ) ;cli-command/env
          ) ;command-output
    ) ;set!
    (if (and (string-contains? (command-output (cli-command "export-buffer" *export-test-path* "--dry-run"))
                               "mogan-test-export-buffer")
             (contains-all? scenario-export-dry-run-output
                            (list "mogan-test-export-buffer"
                                  "mogan-test-write-text")
                            ) ;list
             ) ;contains-all?
        (pass "Export dry-runs print the expected export commands")
        (fail "Export dry-run workflow failed")
    ) ;if

    (display "Test 17b: style and layout dry-runs build the expected commands...")
    (set! scenario-style-dry-run-output
          (command-output
            (cli-command/env
              (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
              "scenario" "style-smoke" "smoke" "--dry-run"
            ) ;cli-command/env
          ) ;command-output
    ) ;set!
    (set! scenario-layout-dry-run-output
          (command-output
            (cli-command/env
              (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
              "scenario" "layout-smoke" "smoke" "--dry-run"
            ) ;cli-command/env
          ) ;command-output
    ) ;set!
    (if (and (string-contains? (command-output (cli-command "set-main-style" "article" "--dry-run"))
                               "mogan-test-set-main-style")
             (string-contains? (command-output (cli-command "set-document-language" "chinese" "--dry-run"))
                               "mogan-test-set-document-language"
             ) ;string-contains?
             (string-contains? (command-output (cli-command "add-style-package" "number-us" "--dry-run"))
                               "mogan-test-add-style-package"
             ) ;string-contains?
             (string-contains? (command-output (cli-command "remove-style-package" "number-us" "--dry-run"))
                               "mogan-test-remove-style-package"
             ) ;string-contains?
             (contains-all? scenario-style-dry-run-output
                            (list "mogan-test-set-main-style"
                                  "mogan-test-set-document-language"
                                  "mogan-test-add-style-package"
                                  "mogan-test-remove-style-package"
                            ) ;list
             ) ;contains-all?
             (contains-all? scenario-layout-dry-run-output
                            (list "mogan-test-set-page-medium"
                                  "mogan-test-set-page-type"
                                  "mogan-test-set-page-orientation")
                            ) ;list
             ) ;contains-all?
        (pass "Style and layout dry-runs print the expected commands")
        (fail "Style or layout dry-run workflow failed")
    ) ;if

    (display "Test 17: search dry-runs build the expected search commands...")
    (set! scenario-search-dry-run-output
          (command-output
            (cli-command/env
              (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
              "scenario" "search-smoke" "smoke" "--dry-run"
            ) ;cli-command/env
          ) ;command-output
    ) ;set!
    (if (and (string-contains? (command-output (cli-command "search-set" "alpha" "--dry-run"))
                               "mogan-test-search-set")
             (string-contains? (command-output (cli-command "search-state" "--dry-run"))
                               "mogan-test-search-state"
             ) ;string-contains?
             (string-contains? (command-output (cli-command "search-next" "--dry-run"))
                               "mogan-test-search-next"
             ) ;string-contains?
             (string-contains? (command-output (cli-command "search-prev" "--dry-run"))
                               "mogan-test-search-prev"
             ) ;string-contains?
             (string-contains? (command-output (cli-command "search-first" "--dry-run"))
                               "mogan-test-search-first"
             ) ;string-contains?
             (string-contains? (command-output (cli-command "search-last" "--dry-run"))
                               "mogan-test-search-last"
             ) ;string-contains?
             (string-contains? (command-output (cli-command "replace-set" "gamma" "--dry-run"))
                               "mogan-test-replace-set"
             ) ;string-contains?
             (string-contains? (command-output (cli-command "replace-one" "--dry-run"))
                               "mogan-test-replace-one"
             ) ;string-contains?
             (string-contains? (command-output (cli-command "replace-all" "--dry-run"))
                               "mogan-test-replace-all"
             ) ;string-contains?
             (contains-all? scenario-search-dry-run-output
                            (list "mogan-test-search-set"
                                  "mogan-test-replace-set"
                                  "mogan-test-replace-all")
                            ) ;list
             ) ;contains-all?
        (pass "Search dry-runs print the expected search commands")
        (fail "Search dry-run workflow failed")
    ) ;if

    (display "Test 18: traces command reports the current debug bundle...")
    (test-command-contains
      "traces command reports the current debug bundle"
      "traces command did not report the expected debug bundle: "
      (cli-command "traces")
      (list "/tmp/mogan-test-connect-trace.log"
            "/tmp/mogan-test-server-trace.log"
            "/tmp/mogan-test-runtime-result.txt"
      ) ;list
    ) ;test-command-contains

    (display "Test 19: Shell wrapper syntax is valid...")
    (if (= (result-status (run-command (command->string "bash" (list "-n" *cli*)))) 0)
        (pass "Shell wrapper syntax is valid")
        (fail "Shell wrapper syntax is invalid")
    ) ;if
  ) ;let
) ;define

(define (run-live-tests)
  (display "Test 20: Live create-account reaches the running server...")
  (let
    ((output
       (command-output
         (cli-command "create-account"
                      *live-host*
                      *live-pseudo*
                      *live-name*
                      *live-pass*
                      *live-email*)
         ) ;cli-command
       ) ;command-output
    ) ;
    (if (or (string-contains? output "status: ok")
            (string-contains? output "value: user already exists"))
        (pass "Live create-account reached the running server")
        (fail (string-append "Live create-account failed: " output))
    ) ;if
  ) ;let

  (display "Test 21: Live connect reaches the running server...")
  (let
    ((output
       (command-output
         (cli-command "connect"
                      *live-host*
                      *live-pseudo*
                      *live-pass*)
         ) ;cli-command
       ) ;command-output
    ) ;
    (if (contains-all? output (list "status: ok" "value: ready"))
        (pass "Live connect succeeded against the running server")
        (fail (string-append "Live connect failed: " output))
    ) ;if
  ) ;let

  (if *expect-services*
      (begin
        (display "Test 22: Live ping reaches the custom server runtime...")
        (let
          ((output
             (command-output
               (cli-command "ping"
                            *live-host*
                            *live-pseudo*
                            *live-pass*)
               ) ;cli-command
             ) ;command-output
          ) ;
          (if (contains-all? output (list "status: ok" "value: \"pong\""))
              (pass "Live ping succeeded against the custom server runtime")
              (fail (string-append "Live ping failed: " output))
          ) ;if
        ) ;let

        (display "Test 23: Live smoke scenario reaches the running server...")
        (save-test-target!)
        (let
          ((output
             (command-output
               (cli-command/env
                 (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
                 "target" "run" "smoke" "scenario" "smoke-edit")
               ) ;cli-command/env
             ) ;command-output
          ) ;
          (if (contains-all? output (list "status: ok" "buffer_text" "hello from mogan-test!"))
              (pass "Live smoke scenario succeeded against the custom server runtime")
              (fail (string-append "Live smoke scenario failed: " output))
          ) ;if
        ) ;let

        (display "Test 24: Live batch scenario reaches the running server...")
        (let
          ((output
             (command-output
               (cli-command/env
                 (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
                 "scenario" "batch-smoke" "smoke")
               ) ;cli-command/env
             ) ;command-output
          ) ;
          (if (contains-all? output (list "status: ok" "buffer_text" "hello from mogan-test!"))
              (pass "Live batch scenario succeeded against the custom server runtime")
              (fail (string-append "Live batch scenario failed: " output))
          ) ;if
        ) ;let

        (display "Test 25: Live history scenario reaches the running server...")
        (let
          ((output
             (command-output
               (cli-command/env
                 (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
                 "scenario" "history-smoke" "smoke")
               ) ;cli-command/env
             ) ;command-output
          ) ;
          (if (contains-all? output
                             (list "status: ok"
                                   "buffer_text"
                                   "hello"
                                   "undo_possibilities"
                                   "redo_possibilities")
                             ) ;list
              (pass "Live history scenario succeeded against the custom server runtime")
              (fail (string-append "Live history scenario failed: " output))
          ) ;if
        ) ;let

        (display "Test 26: Live clipboard scenario reaches the running server...")
        (let
          ((output
             (command-output
               (cli-command/env
                 (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
                 "scenario" "clipboard-smoke" "smoke")
               ) ;cli-command/env
             ) ;command-output
          ) ;
          (if (contains-all? output
                             (list "status: ok"
                                   "buffer_text"
                                   "hello"
                                   "undo_possibilities"
                                   "redo_possibilities")
                             ) ;list
              (pass "Live clipboard scenario succeeded against the custom server runtime")
              (fail (string-append "Live clipboard scenario failed: " output))
          ) ;if
        ) ;let

        (display "Test 27: Live search scenario reaches the running server...")
        (let
          ((output
             (command-output
               (cli-command/env
                 (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
                 "scenario" "search-smoke" "smoke")
               ) ;cli-command/env
             ) ;command-output
          ) ;
          (if (contains-all? output (list "status: ok" "search_query" "replace_text" "gamma beta gamma"))
              (pass "Live search scenario succeeded against the custom server runtime")
              (fail (string-append "Live search scenario failed: " output))
          ) ;if
        ) ;let

        (display "Test 28: Live file scenario reaches the running server...")
        (let
          ((output
             (command-output
               (cli-command/env
                 (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
                 "scenario" "file-smoke" "smoke" *file-test-path*)
               ) ;cli-command/env
             ) ;command-output
          ) ;
          (if (contains-all? output (list "status: ok" "file smoke" *file-test-path* "close-buffer"))
              (pass "Live file scenario succeeded against the custom server runtime")
              (fail (string-append "Live file scenario failed: " output))
          ) ;if
        ) ;let

        (display "Test 28a: Live export scenario reaches the running server...")
        (safe-unlink *export-test-path*)
        (let
          ((output
             (command-output
               (cli-command/env
                 (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
                 "scenario" "export-smoke" "smoke" *export-test-path*)
               ) ;cli-command/env
             ) ;command-output
          ) ;
          (if (and (contains-all? output (list "status: ok" "exported_to" "export smoke"))
                   (file-exists? *export-test-path*)
                   (> (path-getsize *export-test-path*) 0))
              (pass "Live export scenario succeeded against the custom server runtime")
              (fail (string-append "Live export scenario failed: " output))
          ) ;if
        ) ;let

        (display "Test 28b: Live style scenario reaches the running server...")
        (let
          ((output
             (command-output
               (cli-command/env
                 (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
                 "scenario" "style-smoke" "smoke")
               ) ;cli-command/env
             ) ;command-output
          ) ;
          (if (contains-all? output
                             (list "status: ok"
                                   "main_style"
                                   "style_list"
                                   "document_language"
                                   "article"
                                   "chinese")
                             ) ;list
              (pass "Live style scenario succeeded against the custom server runtime")
              (fail (string-append "Live style scenario failed: " output))
          ) ;if
        ) ;let

        (display "Test 28c: Live layout scenario reaches the running server...")
        (let
          ((output
             (command-output
               (cli-command/env
                 (list (cons "MOGAN_TEST_TARGET_DIR" *target-test-dir*))
                 "scenario" "layout-smoke" "smoke")
               ) ;cli-command/env
             ) ;command-output
          ) ;
          (if (contains-all? output
                             (list "status: ok"
                                   "page_medium"
                                   "page_type"
                                   "page_orientation"
                                   "papyrus"
                                   "letter"
                                   "landscape")
                             ) ;list
              (pass "Live layout scenario succeeded against the custom server runtime")
              (fail (string-append "Live layout scenario failed: " output))
          ) ;if
        ) ;let
      ) ;begin
  ) ;if
      #f
) ;define

(define (main)
  (dynamic-wind
    (lambda ()
      (initialize!)
      (print-header)
    ) ;lambda
    (lambda ()
      (run-static-tests)
      (if *live-mode*
          (run-live-tests)
          #f
      ) ;if
      (print-summary)
    ) ;lambda
    (lambda ()
      (cleanup)
    ) ;lambda
  ) ;dynamic-wind
) ;define
