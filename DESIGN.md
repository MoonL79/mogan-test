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
- The running server can expose the custom `ping`, `current-buffer`, and `new-document` test services through `mogan-server-runtime.scm`.
- The controller runtime writes scriptable status/value results to `/tmp/mogan-test-runtime-result.txt`.
- Server-side trace can be inspected in `/tmp/mogan-test-server-trace.log` when debugging live failures.

What is still limited:

- End-to-end success still depends on a live Mogan runtime that can stay up with `-server` enabled in the current environment.
- The current custom service surface is intentionally small: `ping`, `current-buffer`, and `new-document`.
- The current account/login behavior is test-scoped and should not be mistaken for the final product-side user system.
- Those custom services and the test-scoped login shim are unavailable when the target `-server` instance was started without loading `mogan-server-runtime.scm`.
- The default validation script checks command construction and local skeleton consistency; live validation is opt-in and should be pointed at an already-running server.

## Next Step

Run `./validate.sh --live` against an already-running `moganstem -server` instance,
confirm `create-account` and `connect`,
then validate `ping` or `new-document` when that target server was started with
`-x '(load ".../mogan-server-runtime.scm")'`.
