# Mogan Test Platform Design

## Architecture

```
command line
  -> mogan-cli
    -> Goldfish command router
    -> xmake build/run entry for full Mogan client
    -> Mogan internal Scheme via -x
    -> future remote-login connection layer
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
  Starts Mogan and executes Scheme inside the live Mogan runtime through `-x`.
- `connect`
  Reserved command for the next iteration of the real connection layer.

## Constraints

- Do not use headless startup in this stage.
- Do not introduce external TeXmacs tools or wrappers.
- Reuse only the TeXmacs-related mechanisms already present inside `mogan`.

## Current Boundary

What is real:

- The test platform can invoke the real Mogan build workflow.
- The test platform can invoke the real Mogan startup workflow.
- The test platform can dispatch Scheme into Mogan through the real `-x` startup path.
- The runtime expectations are exposed as machine-readable JSON.

What is not finished yet:

- The test platform does not yet complete a real `remote-login` flow.
- The new runtime dispatch entry does not yet prove a working server/client handshake.
- No end-to-end `command -> route -> running Mogan -> result` path exists yet.

## Next Step

Implement `remote-login` on top of the new `exec-internal` runtime path, so the test platform moves from “can execute inside Mogan” to “can connect and authenticate through the existing server/client mechanism”.
