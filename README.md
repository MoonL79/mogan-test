# Mogan Test Platform

中文版本: [README.zh_CN.md](/home/mingshen/git/mogan-test/README.zh_CN.md)

`mogan-test` is a minimal command-line control layer for a live `moganstem -server`
instance. The server is the intermediary control surface: `mogan-test` connects to
it and indirectly controls the live Mogan process. It uses Goldfish Scheme for the
controller/runtime glue and keeps the validation path scriptable.

## Quick Start

Build and start a connectable server:

```bash
./mogan-cli build-client
./mogan-cli start-server
```

Run the live validation against that running instance:

```bash
./validate.sh --live --expect-services
```

## Commands

- `./mogan-cli status`
- `./mogan-cli workflow`
- `./mogan-cli create-account`
- `./mogan-cli connect`
- `./mogan-cli ping`
- `./mogan-cli current-buffer`
- `./mogan-cli new-document`
- `./mogan-cli write-text 127.0.0.1 test-user test-pass "hello from mogan-test"`
- `./mogan-cli buffer-text`
- `./mogan-cli state`
- `./mogan-cli move-end`
- `./mogan-cli insert-text 127.0.0.1 test-user test-pass "!"`
- `./mogan-cli select-all`
- `./mogan-cli undo`
- `./mogan-cli redo`
- `./mogan-cli copy`
- `./mogan-cli cut`
- `./mogan-cli paste`
- `./mogan-cli clear-undo-history`
- `./mogan-cli save-buffer`
- `./mogan-cli buffer-list`
- `./mogan-cli open-file /tmp/example.tm`
- `./mogan-cli save-as /tmp/example.tm`
- `./mogan-cli export-buffer /tmp/example.html`
- `./mogan-cli set-main-style article`
- `./mogan-cli set-document-language chinese`
- `./mogan-cli add-style-package number-us`
- `./mogan-cli remove-style-package number-us`
- `./mogan-cli set-page-medium papyrus`
- `./mogan-cli set-page-type letter`
- `./mogan-cli set-page-orientation landscape`
- `./mogan-cli revert-buffer`
- `./mogan-cli close-buffer`
- `./mogan-cli search-state`
- `./mogan-cli search-set alpha`
- `./mogan-cli search-next`
- `./mogan-cli search-prev`
- `./mogan-cli search-first`
- `./mogan-cli search-last`
- `./mogan-cli replace-set gamma`
- `./mogan-cli replace-one`
- `./mogan-cli replace-all`
- `./mogan-cli batch smoke -- new-document -- insert-text "hello" -- move-end -- insert-text "!" -- buffer-text`
- `./mogan-cli target save smoke`
- `./mogan-cli target run smoke state`
- `./mogan-cli scenario smoke-edit`
- `./mogan-cli scenario batch-smoke smoke`
- `./mogan-cli scenario file-smoke smoke /tmp/example.tm`
- `./mogan-cli scenario export-smoke smoke /tmp/example.html`
- `./mogan-cli scenario style-smoke smoke`
- `./mogan-cli scenario layout-smoke smoke`
- `./mogan-cli scenario search-smoke smoke`
- `./mogan-cli scenario history-smoke smoke`
- `./mogan-cli scenario clipboard-smoke smoke`
- `./mogan-cli traces`

Dry-run variants print the exact runtime command instead of executing it.

## Runtime Files

- `/tmp/mogan-test-connect-trace.log`
- `/tmp/mogan-test-server-trace.log`
- `/tmp/mogan-test-runtime-result.txt`
- `/tmp/mogan-test-runtime-output.log`

`./mogan-cli traces` prints the current debug bundle from these files. The
`status` command also reports the same paths.

## Current Auth Model

The current live workflow uses a test-scoped `users.scm` store and a server-side
login shim in `mogan-server-runtime.scm`. That keeps the live control path stable
while the underlying TMDB-backed account flow remains a separate concern.

## Current Control Slice

Beyond `ping` and buffer identity checks, the current test runtime also exposes a
small set of low-level editing, history, clipboard, and file lifecycle primitives:

1. `./mogan-cli new-document`
2. `./mogan-cli write-text 127.0.0.1 test-user test-pass "hello from mogan-test"`
3. `./mogan-cli state 127.0.0.1 test-user test-pass`
4. `./mogan-cli move-end 127.0.0.1 test-user test-pass`
5. `./mogan-cli insert-text 127.0.0.1 test-user test-pass "!"`
6. `./mogan-cli buffer-text 127.0.0.1 test-user test-pass`
7. `./mogan-cli undo 127.0.0.1 test-user test-pass`
8. `./mogan-cli redo 127.0.0.1 test-user test-pass`
9. `./mogan-cli copy 127.0.0.1 test-user test-pass`
10. `./mogan-cli cut 127.0.0.1 test-user test-pass`
11. `./mogan-cli paste 127.0.0.1 test-user test-pass`
12. `./mogan-cli clear-undo-history 127.0.0.1 test-user test-pass`
13. `./mogan-cli buffer-list 127.0.0.1 test-user test-pass`
14. `./mogan-cli open-file /tmp/example.tm`
15. `./mogan-cli save-as /tmp/example.tm`
16. `./mogan-cli revert-buffer`
17. `./mogan-cli close-buffer`
18. `./mogan-cli search-state`
19. `./mogan-cli search-set alpha`
20. `./mogan-cli search-next`
21. `./mogan-cli search-prev`
22. `./mogan-cli search-first`
23. `./mogan-cli search-last`
24. `./mogan-cli replace-set gamma`
25. `./mogan-cli replace-one`
26. `./mogan-cli replace-all`
27. `./mogan-cli set-main-style article`
28. `./mogan-cli set-document-language chinese`
29. `./mogan-cli add-style-package number-us`
30. `./mogan-cli remove-style-package number-us`
31. `./mogan-cli set-page-medium papyrus`
32. `./mogan-cli set-page-type letter`
33. `./mogan-cli set-page-orientation landscape`

This path lets agents inspect state, move the cursor, manage edit history, use
the clipboard, manage file-backed buffers, export to another format, control
document style, language, and page layout, search and replace text, insert text,
and read the result back as a scriptable response.

## Targets and Scenarios

`mogan-test` now supports named target profiles. Save one with
`./mogan-cli target save <name>`, then run any command with
`./mogan-cli target run <name> <command> ...`.

For batch workflows, `./mogan-cli scenario smoke-edit` runs a minimal live edit
sequence in one scenario step.

`./mogan-cli batch smoke -- new-document -- insert-text "hello" -- move-end -- insert-text "!" -- buffer-text`
is the low-level multi-step version of the same idea.

`./mogan-cli scenario batch-smoke smoke` is the named scenario wrapper around that
batch flow.

`./mogan-cli scenario history-smoke smoke` validates undo/redo.

`./mogan-cli scenario clipboard-smoke smoke` validates copy/paste.

`./mogan-cli scenario file-smoke smoke /tmp/example.tm` exercises open/save/revert/close.

`./mogan-cli scenario export-smoke smoke /tmp/example.html` exercises export.

`./mogan-cli scenario style-smoke smoke` exercises document style and language control.

`./mogan-cli scenario layout-smoke smoke` exercises page layout control.

`./mogan-cli scenario search-smoke smoke` exercises search navigation and replace.
