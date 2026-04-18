(define *batch-command*
  "./mogan-cli batch smoke -- new-document -- insert-text ... -- export-buffer /tmp/mogan-test-export.html")

(define *scenario-batch-command* "./mogan-cli scenario batch-smoke smoke")
(define *scenario-file-command* "./mogan-cli scenario file-smoke smoke /tmp/mogan-test-file-smoke.tm")
(define *scenario-export-command* "./mogan-cli scenario export-smoke smoke /tmp/mogan-test-export.html")
(define *scenario-style-command* "./mogan-cli scenario style-smoke smoke")
(define *scenario-layout-command* "./mogan-cli scenario layout-smoke smoke")
(define *scenario-search-command* "./mogan-cli scenario search-smoke smoke")
(define *scenario-history-command* "./mogan-cli scenario history-smoke smoke")
(define *scenario-clipboard-command* "./mogan-cli scenario clipboard-smoke smoke")
