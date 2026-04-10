;; mogan-runtime.scm - Code intended to run inside Mogan via `-x`

(define (mogan-test-runtime-status)
  (display
    "mogan-runtime: loaded inside Mogan; runtime glue is available here; remote-login path is not wired yet")
  (newline))

(mogan-test-runtime-status)
