(load "scripts/validate-core.scm")

(define *test-failures* 0)

(define (test-pass msg)
  (display "PASS: ")
  (display msg)
  (newline)
) ;define

(define (test-fail msg)
  (display "FAIL: ")
  (display msg)
  (newline)
  (set! *test-failures* (+ *test-failures* 1))
) ;define

(define (assert-true msg value)
  (if value
      (test-pass msg)
      (test-fail msg)
  ) ;if
) ;define

(define (assert-equal msg actual expected)
  (if (equal? actual expected)
      (test-pass msg)
      (test-fail (string-append msg
                                " expected="
                                (object->string expected)
                                " actual="
                                (object->string actual))
      ) ;test-fail
  ) ;if
) ;define

(define (assert-output-contains msg text needle)
  (if (string-contains? text needle)
      (test-pass msg)
      (test-fail (string-append msg
                                " missing="
                                (object->string needle)
                                " output="
                                (object->string text))
      ) ;test-fail
  ) ;if
) ;define

(define (main)
  (assert-equal "shell-quote handles plain text"
                (shell-quote "alpha")
                "'alpha'"
  ) ;assert-equal
  (assert-equal "shell-quote escapes single quotes"
                (shell-quote "a'b")
                "'a'\"'\"'b'"
  ) ;assert-equal
  (assert-true "contains-all? succeeds on all substrings"
               (contains-all? "alpha beta gamma" (list "alpha" "gamma"))
  ) ;assert-true
  (assert-true "flag-present? detects requested flag"
               (flag-present? (list "--live" "--expect-services") "--expect-services")
  ) ;assert-true
  (assert-equal "env-prefix quotes values"
                (env-prefix (list (cons "A" "x y")))
                "A='x y' "
  ) ;assert-equal
  (assert-equal "command->string quotes argv correctly"
                (command->string "./bin/mogan-cli" (list "search-set" "alpha beta" "--dry-run"))
                "'./bin/mogan-cli' 'search-set' 'alpha beta' '--dry-run'"
  ) ;assert-equal
  (let ((status-output (command-output "./bin/mogan-cli status")))
    (assert-output-contains "status reports shell split entry" status-output "\"shell_entry_script\"")
    (assert-output-contains "status reports shell lib dir" status-output "\"shell_lib_dir\"")
    (assert-output-contains "status reports scheme command dir" status-output "\"scheme_command_dir\"")
    (assert-output-contains "status reports runtime dir" status-output "\"runtime_dir\"")
  ) ;let
  (if (= *test-failures* 0)
      (exit 0)
      (exit 1)
  ) ;if
) ;define

(main)
