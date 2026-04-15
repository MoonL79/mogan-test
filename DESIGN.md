# Mogan Test Platform Design

## Architecture

```
command line
  -> mogan-cli
    -> Goldfish command router for status/workflow
    -> xmake build entry for moganstem
    -> explicit `moganstem -server` startup path as the connectable runtime
  -> server-side runtime loaded via `-x` to register test services and test-scoped login
  -> controller-side runtime loaded via `-x` to create accounts, login, and call services
    -> trace/result files in /tmp for scripted verification
    -> `./mogan-cli traces` to print the current debug bundle
```

## Current Slice

The platform is split into a connectable server path and a separate full-client path:

1. Connectable server path
   - `xmake b stem`
   - built `moganstem`
   - started with `-server`
   - optionally started with `-platform minimal` when the current environment cannot open the default Qt display
   - should load `mogan-server-runtime.scm` when you want the custom test services
2. Separate full-client path
   - `xmake b stem`
   - `xmake r stem`
   - starts the normal interactive Mogan instance
   - is still useful for product-side startup checks
   - is not treated as proof that a TCP control endpoint is available

The control client is a second `moganstem` runtime that loads `mogan-runtime.scm`,
logs in through the existing `client-start` and `remote-login` glue,
and then invokes a server-side command.

In this architecture, the server is the intermediary control surface.
`mogan-test` connects to that running server and uses it to indirectly control the live Mogan process.

The current account flow is intentionally test-scoped:
- `create-account` writes a lightweight `users.scm` record through `mogan-server-runtime.scm`
- `remote-login` is shimmed inside `mogan-server-runtime.scm` so it authenticates against the same test user store
- this keeps the test platform off the currently unstable TMDB-backed account path while preserving a login step in the control workflow

## Commands

- `status`
  Returns JSON describing the current workflow, startup commands, and connection assumptions.
- `workflow`
  Returns JSON describing the required startup order and current runtime constraints.
- `build-client`
  Runs `xmake b stem` inside `/home/mingshen/git/mogan`.
- `start-client`
  Runs `xmake r stem` inside `/home/mingshen/git/mogan` for the normal interactive client path.
- `start-server`
  Runs the built `moganstem` binary directly with `-server` and loads `mogan-server-runtime.scm`.
- `exec-internal`
  Runs the built `moganstem` binary directly with `-x ...` so injected Scheme reaches the Mogan runtime.
- `create-account`
  Uses the controller runtime to call a test bootstrap service that creates a local test account inside the running server.
- `connect`
  Uses the controller runtime to verify `remote-login` against the test-scoped account store loaded by `mogan-server-runtime.scm`.
- `ping`
  Calls the server-side `mogan-test-ping` service after login. This requires the target server to have loaded `mogan-server-runtime.scm`.
- `current-buffer`
  Calls the server-side `mogan-test-current-buffer` service after login. This requires the target server to have loaded `mogan-server-runtime.scm`.
- `new-document`
  Calls the server-side `mogan-test-new-document` service after login. This requires the target server to have loaded `mogan-server-runtime.scm`.
- `write-text`
  Calls the server-side `mogan-test-write-text` service after login. This replaces the current buffer body with a plain-text document and returns the written text.
- `buffer-text`
  Calls the server-side `mogan-test-buffer-text` service after login. This reads back the current buffer body as plain text when possible, or as a structural fallback string.
- `buffer-list`
  Calls the server-side `mogan-test-buffer-list` service after login. This returns the open buffer list with titles and modified state.
- `state`
  Calls the server-side `mogan-test-state` service after login. This returns the current buffer, cursor, selection, edit history, and text summary.
- `move-*`
  Calls the low-level cursor movement services after login.
- `select-*`
  Calls the selection primitives after login.
- `undo` / `redo`
  Calls the edit-history primitives after login.
- `copy` / `cut` / `paste`
  Calls the clipboard primitives after login.
- `clear-undo-history`
  Resets the current edit history after login.
- `insert-text`
  Inserts text at the current cursor position after login.
- `delete-*`
  Deletes text at the cursor after login.
- `save-buffer`
  Saves the current buffer after login.
- `open-file`
  Loads a file into the current session after login.
- `save-as`
  Saves the current buffer under a new name after login.
- `export-buffer`
  Exports the current buffer to another format or path after login.
- `revert-buffer`
  Reverts the current buffer from disk after login.
- `close-buffer`
  Closes the current buffer immediately after login.
- `search-state`
  Returns JSON describing the current search and replace buffers plus the active document state.
- `search-set`
  Sets the current search query and performs the initial search.
- `search-next` / `search-prev`
  Moves to the next or previous search match after login.
- `search-first` / `search-last`
  Jumps to the first or last search match after login.
- `replace-set`
  Sets the current replacement text.
- `replace-one` / `replace-all`
  Replaces the current match once or all remaining matches after login.
- `switch-buffer`
  Switches to another buffer after login.
- `batch`
  Runs a sequence of approved control commands against one named target profile.
- `scenario smoke-edit`
  Runs a one-step batch edit workflow against the live server.
- `scenario batch-smoke`
  Runs the low-level batch smoke workflow against a target profile.
- `scenario file-smoke`
  Runs the file lifecycle smoke workflow against a target profile.
- `scenario search-smoke`
  Runs the search/replace smoke workflow against a target profile.
- `target save` / `target run`
  Saves a named target profile and reuses it to run commands without repeating connection details.

## Constraints

- Do not introduce external TeXmacs tools or wrappers.
- Reuse only the TeXmacs-related mechanisms already present inside `mogan`.
- Treat `-server` as the explicit prerequisite for a connectable local control path.
- Treat `xmake r stem` as a separate full-client path, not as proof that a connectable TCP server is available.
- Allow `-platform minimal` on the control path when the current environment cannot open the default Qt display.

## Current Boundary

What is real:

- The test platform can invoke the real Mogan build workflow.
- The test platform now distinguishes between the explicit connectable server path and the separate full-client startup path.
- The connectable path reuses the real `client-start` and `client-remote-eval` glue already present in `mogan`.
- Account bootstrap and login are currently provided by `mogan-server-runtime.scm` as a test-scoped substitute for the unstable TMDB-backed account path.
- The running server can expose the custom `ping`, `current-buffer`, `new-document`, `state`, search/replace, export, and low-level editing services through `mogan-server-runtime.scm`.
- The running server can expose a minimal text-edit round trip through `write-text` and `buffer-text`.
- Named target profiles can be saved under `MOGAN_TEST_TARGET_DIR` and replayed through `mogan-cli target run`.
- `mogan-cli batch` can chain low-level steps against one target profile.
- `mogan-cli scenario smoke-edit`, `mogan-cli scenario batch-smoke`, `mogan-cli scenario file-smoke`, `mogan-cli scenario search-smoke`, `mogan-cli scenario history-smoke`, and `mogan-cli scenario clipboard-smoke` provide named workflows.
- The controller runtime writes scriptable status/value results to `/tmp/mogan-test-runtime-result.txt`.
- The controller runtime writes captured process output to `/tmp/mogan-test-runtime-output.log`.
- Server-side trace can be inspected in `/tmp/mogan-test-server-trace.log` when debugging live failures.
- `./mogan-cli traces` prints the current connect trace, server trace, runtime result, and runtime output bundle.

What is still limited:

- End-to-end success still depends on a live Mogan runtime that can stay up with `-server` enabled in the current environment.
- The current custom service surface is intentionally small, but now includes `ping`, `current-buffer`, `new-document`, `state`, `move-*`, `select-*`, `undo`, `redo`, `copy`, `cut`, `paste`, `clear-undo-history`, `insert-text`, `delete-*`, `save-buffer`, `buffer-list`, `open-file`, `save-as`, `export-buffer`, `revert-buffer`, `close-buffer`, `search-state`, `search-set`, `search-next`, `search-prev`, `search-first`, `search-last`, `replace-set`, `replace-one`, `replace-all`, `switch-buffer`, `write-text`, and `buffer-text`.
- The current platform also has named target profiles, a batch runner, and minimal scenario runners for edit, file lifecycle, search/replace, history, and clipboard workflows.
- The current account/login behavior is test-scoped and should not be mistaken for the final product-side user system.
- Those custom services and the test-scoped login shim are unavailable when the target `-server` instance was started without loading `mogan-server-runtime.scm`.
- The default validation script checks command construction and local skeleton consistency; live validation is opt-in and should be pointed at an already-running server.

## Next Step

Run `./validate.sh --live` against an already-running `moganstem -server` instance,
confirm `create-account` and `connect`,
then validate `mogan-cli target run smoke scenario smoke-edit`,
`mogan-cli scenario file-smoke smoke`,
`mogan-cli scenario export-smoke smoke`,
`mogan-cli scenario search-smoke smoke`,
`mogan-cli scenario history-smoke smoke`,
`mogan-cli scenario clipboard-smoke smoke`,
or `mogan-cli scenario batch-smoke smoke` when that target server was started with
`-x '(load ".../mogan-server-runtime.scm")'`.
