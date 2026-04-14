# Mogan Test Platform

`mogan-test` 是一个面向运行中 `moganstem -server` 实例的最小命令行控制层。
它使用 Goldfish Scheme 编写控制器和运行时胶水逻辑，并保持验证流程可脚本化。

## 快速开始

先构建并启动可连接的 server：

```bash
./mogan-cli build-client
./mogan-cli start-server --platform minimal
```

然后对正在运行的实例执行 live 验证：

```bash
./validate.sh --live --expect-services
```

## 命令

- `./mogan-cli status`
- `./mogan-cli workflow`
- `./mogan-cli create-account`
- `./mogan-cli connect`
- `./mogan-cli ping`
- `./mogan-cli current-buffer`
- `./mogan-cli new-document`
- `./mogan-cli traces`

这些命令都支持 dry-run 形式，用来打印实际执行的运行时命令，而不是直接运行。

## 运行时文件

- `/tmp/mogan-test-connect-trace.log`
- `/tmp/mogan-test-server-trace.log`
- `/tmp/mogan-test-runtime-result.txt`
- `/tmp/mogan-test-runtime-output.log`

`./mogan-cli traces` 会把这些文件的当前调试内容打印出来。
`status` 命令也会报告同一组路径。

## 当前鉴权模型

当前 live 流程使用的是测试专用的 `users.scm` 用户存储，以及
`mogan-server-runtime.scm` 中的 server 侧登录 shim。
这样可以让 live 控制链路保持稳定，同时把底层 TMDB 账户流程保留为
独立的后续问题。
