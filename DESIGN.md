# Mogan Test Platform Design

## Architecture

```
command line
  -> mogan-cli
    -> Goldfish command router
    -> xmake build/run entry for full Mogan client
    -> direct moganstem `-x` runtime entry for injected Scheme
    -> runtime trace file for scripted verification
    -> remote-login connection layer
```

## Current Slice

The platform is split into two stages:

1. Build and start a full Mogan client with the required workflow:
   - `xmake b stem`
   - `xmake r stem`
2. Connect the test platform to that running client and operate it.

## Commands

- `status`
  Returns JSON with the current runtime workflow, target path, and connection status.
- `workflow`
  Returns JSON describing the required startup order and current constraints.
- `build-client`
  Runs `xmake b stem` inside `/home/mingshen/git/mogan`.
- `start-client`
  Runs `xmake r stem` inside `/home/mingshen/git/mogan`.
- `exec-internal`
  Runs the built `moganstem` binary directly with `-d -debug-bench -x ...` so injected Scheme actually reaches the Mogan runtime.
- `connect`
  Runs the built `moganstem` binary directly, loads `mogan-runtime.scm`, and records the real remote-login trace in `/tmp/mogan-test-connect-trace.log`.

## Constraints

- Do not use headless startup in this stage.
- Do not introduce external TeXmacs tools or wrappers.
- Reuse only the TeXmacs-related mechanisms already present inside `mogan`.

## Current Boundary

What is real:

- The test platform can invoke the real Mogan build workflow.
- The test platform can invoke the real Mogan startup workflow.
- The test platform can dispatch Scheme into Mogan through a real direct `moganstem -x` path.
- The test platform can record runtime-side connection traces to `/tmp/mogan-test-connect-trace.log`.
- The runtime expectations are exposed as machine-readable JSON.

What is not finished yet:

- The test platform still does not complete a real `remote-login` flow.
- The current runtime trace proves that `client-start` is returning `-1` in the injected connector runtime.
- A plain `xmake r stem` full client did not expose a confirmed TCP listener on port `6561` in this environment, so the server side is not yet connectable.
- No successful end-to-end `command -> route -> running Mogan -> result` path exists yet.

## Next Step

Make the full client side genuinely connectable on port `6561`, then rerun the recorded `client-start` probe and continue from the existing direct `moganstem -x` runtime path.
