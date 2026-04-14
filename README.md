# Mogan Test Platform

`mogan-test` is a minimal command-line control layer for a live `moganstem -server`
instance. It uses Goldfish Scheme for the controller/runtime glue and keeps the
validation path scriptable.

## Quick Start

Build and start a connectable server:

```bash
./mogan-cli build-client
./mogan-cli start-server --platform minimal
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

Dry-run variants print the exact runtime command instead of executing it.

## Runtime Files

- `/tmp/mogan-test-connect-trace.log`
- `/tmp/mogan-test-server-trace.log`
- `/tmp/mogan-test-runtime-result.txt`
- `/tmp/mogan-test-runtime-output.log`

## Current Auth Model

The current live workflow uses a test-scoped `users.scm` store and a server-side
login shim in `mogan-server-runtime.scm`. That keeps the live control path stable
while the underlying TMDB-backed account flow remains a separate concern.
