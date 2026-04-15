# Mogan Test Platform

`mogan-test` 是一个面向运行中 `moganstem -server` 实例的最小命令行控制层。
这里的 server 是中介控制面，`mogan-test` 连接它，再间接控制运行中的 Mogan。
它使用 Goldfish Scheme 编写控制器和运行时胶水逻辑，并保持验证流程可脚本化。

## 快速开始

先构建并启动可连接的 server：

```bash
./mogan-cli build-client
./mogan-cli start-server
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
- `./mogan-cli scenario search-smoke smoke`
- `./mogan-cli scenario history-smoke smoke`
- `./mogan-cli scenario clipboard-smoke smoke`
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

## 当前控制片段

除了 `ping` 和缓冲区身份检查之外，当前测试运行时还暴露了一组
低级编辑、历史、剪贴板和文件生命周期原语：

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

这条路径让 agent 可以检查状态、移动光标、管理编辑历史、使用剪贴板、
管理文件型缓冲区、导出到其他格式、控制文档样式和语言、搜索和替换文本、
插入文本，并把结果以脚本化形式读回。

## Targets 和 Scenarios

`mogan-test` 现在支持命名 target 配置。先用
`./mogan-cli target save <name>` 保存一个配置，再用
`./mogan-cli target run <name> <command> ...` 运行命令。

对于批量工作流，可以直接执行 `./mogan-cli scenario smoke-edit`。

`./mogan-cli batch smoke -- new-document -- insert-text "hello" -- move-end -- insert-text "!" -- buffer-text`
是同一思路的低级多步版本。

`./mogan-cli scenario batch-smoke smoke` 是它的命名场景包装器。

`./mogan-cli scenario history-smoke smoke` 用来验证撤销/重做。

`./mogan-cli scenario clipboard-smoke smoke` 用来验证复制/粘贴。

`./mogan-cli scenario file-smoke smoke /tmp/example.tm` 用来验证打开、另存、回退和关闭。

`./mogan-cli scenario export-smoke smoke /tmp/example.html` 用来验证导出。

`./mogan-cli scenario style-smoke smoke` 用来验证文档样式和语言控制。

`./mogan-cli scenario search-smoke smoke` 用来验证搜索导航和替换。
