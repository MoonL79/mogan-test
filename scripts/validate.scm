; validate.scm - Mogan Test Platform validation in Scheme
;
; This script defines test specifications and validates file structure.
; For runtime CLI tests, use the bash wrapper: ./scripts/validate.sh

(import (liii base)
        (liii json)
        (liii string)
        (liii path)
        (scheme base)
        (scheme file)
) ;import

(define (red s) (string-append "[RED]" s "[NC]"))
(define (green s) (string-append "[GREEN]" s "[NC]"))

(define (pass msg)
  (display (green "PASS"))
  (display ": ")
  (display msg)
  (newline)
) ;define

(define (fail msg)
  (display (red "FAIL"))
  (display ": ")
  (display msg)
  (newline)
) ;define

(define (info msg)
  (display "[INFO] ")
  (display msg)
  (newline)
) ;define

(define (section title)
  (newline)
  (display "=== ")
  (display title)
  (display " ===")
  (newline)
  (newline)
) ;define

(define (check-file-exists path)
  (file-exists? path)
) ;define

(define (check-file-contains path pattern)
  (if (file-exists? path)
      (string-contains? (path-read-text path) pattern)
      #f
  ) ;if
) ;define

(define (check-dir-exists path)
  (and (file-exists? path)
       (file-exists? (string-append path "/."))
  ) ;and
) ;define

(define (main)
  (section "Mogan Test Platform Validation - Static Checks")
  
  (info "Running static validation (file structure and content)...")
  (info "For dynamic CLI tests, use: ./scripts/validate.sh")
  (newline)

  (section "File Structure Checks")

  (display "Test 1: CLI wrapper exists...")
  (if (check-file-exists "./bin/mogan-cli")
      (pass "CLI wrapper exists at ./bin/mogan-cli")
      (fail "CLI wrapper not found at ./bin/mogan-cli")
  ) ;if

  (display "Test 2: Scheme runtime files exist...")
  (let ((cli-scm (check-file-exists "./src/cli/mogan-cli.scm"))
        (client-scm (check-file-exists "./src/cli/runtime/client.scm"))
        (server-scm (check-file-exists "./src/cli/runtime/mogan-server-runtime.scm")))
    (if (and cli-scm client-scm server-scm)
        (pass "All Scheme runtime files exist")
        (fail (string-append "Missing: "
          (if cli-scm "" "mogan-cli.scm ")
          (if client-scm "" "client.scm ")
          (if server-scm "" "mogan-server-runtime.scm"))
        ) ;fail
    ) ;if
  ) ;let

  (display "Test 3: Documentation files exist...")
  (let ((readme (check-file-exists "./docs/README.md"))
        (readme-zh (check-file-exists "./docs/README.zh_CN.md"))
        (design (check-file-exists "./docs/DESIGN.md"))
        (spec (check-file-exists "./docs/spec.md")))
    (if (and readme readme-zh design spec)
        (pass "All documentation files exist")
        (fail "Missing documentation files")
    ) ;if
  ) ;let
) ;define

  (display "Test 4: Command stub directories exist...")
  (let ((commands-dir (check-dir-exists "./src/cli/commands"))
        (runtime-dir (check-dir-exists "./src/cli/runtime")))
    (if (and commands-dir runtime-dir)
        (pass "Command and runtime directories exist")
        (fail "Missing directories")
    ) ;if
  ) ;let

  (display "Test 5: Test stub files exist...")
  (let ((batch (check-file-exists "./src/cli/commands/batch.scm"))
        (buffer (check-file-exists "./src/cli/commands/buffer.scm"))
        (edit (check-file-exists "./src/cli/commands/edit.scm"))
        (file-cmd (check-file-exists "./src/cli/commands/file.scm"))
        (search (check-file-exists "./src/cli/commands/search.scm"))
        (target (check-file-exists "./src/cli/commands/target.scm"))
        (router (check-file-exists "./src/cli/commands/router.scm")))
    (if (and batch buffer edit file-cmd search target router)
        (pass "All command stub files exist")
        (fail "Missing command stub files")
    ) ;if
  ) ;let

  (section "Source Code Structure Checks")

  (display "Test 6: CLI script contains command definitions...")
  (if (check-file-contains "./src/cli/mogan-cli.scm" "define *commands*")
      (pass "CLI script contains command definitions")
      (fail "CLI script missing command definitions")
  ) ;if

  (display "Test 7: CLI script contains status command...")
  (if (check-file-contains "./src/cli/mogan-cli.scm" "cmd-status")
      (pass "CLI script contains status command")
      (fail "CLI script missing status command")
  ) ;if

  (display "Test 8: CLI script contains workflow command...")
  (if (check-file-contains "./src/cli/mogan-cli.scm" "cmd-workflow")
      (pass "CLI script contains workflow command")
      (fail "CLI script missing workflow command")
  ) ;if

  (display "Test 9: CLI script references mogan-server-runtime...")
  (if (check-file-contains "./src/cli/mogan-cli.scm" "mogan-server-runtime.scm")
      (pass "CLI script references mogan-server-runtime")
      (fail "CLI script missing mogan-server-runtime reference")
  ) ;if

  (display "Test 10: Shell wrapper has correct script paths...")
  (if (check-file-contains "./bin/mogan-cli" "../src/cli/mogan-cli.scm")
      (pass "Shell wrapper references correct script path")
      (fail "Shell wrapper has incorrect script paths")
  ) ;if

  (display "Test 11: Runtime client script has remote-call...")
  (if (check-file-contains "./src/cli/runtime/client.scm" "remote-call")
      (pass "Runtime client has remote-call function")
      (fail "Runtime client missing remote-call function")
  ) ;if

  (display "Test 12: Runtime server script has service definitions...")
  (if (check-file-contains "./src/cli/runtime/mogan-server-runtime.scm" "tm-define")
      (pass "Runtime server has service definitions")
      (fail "Runtime server missing service definitions")
  ) ;if

  (section "Validation Summary")
  (newline)
  (display "Static validation complete!")
  (newline)
  (newline)
  (display "To run full validation including CLI command tests:")
  (newline)
  (display "  ./scripts/validate.sh")
  (newline)
  (newline)
  (display "To run live server tests:")
  (newline)
  (display "  1. Start server: ./bin/mogan-cli start-server")
  (newline)
  (display "  2. Run tests: ./scripts/validate.sh --live --expect-services")
  (newline)

(main)
