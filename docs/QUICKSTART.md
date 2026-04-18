# Mogan 实际控制指南

本文档演示如何使用 `mogan-test` 对 `mogan` 进行实际控制。

## 快速演示

我们已经为你准备好了完整的演示脚本：

```bash
./demo-control.sh
```

这将自动：
1. 启动 Mogan 服务器
2. 创建测试账户
3. 连接服务器
4. 执行一系列控制命令（创建文档、写入文本、移动光标、保存、导出等）
5. 显示可用的控制命令列表

## 控制架构

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  mogan-cli      │────▶│  client.scm      │────▶│  moganstem      │
│  (Bash 脚本)    │     │  (Goldfish)      │     │  (Mogan 客户端) │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                                               TCP:6561   │
                                                          ▼
                                                 ┌─────────────────┐
                                                 │  moganstem      │
                                                 │  -server        │
                                                 │  (Mogan 服务端) │
                                                 └────────┬────────┘
                                                          │
                                                          ▼
                                                 ┌─────────────────┐
                                                 │  mogan-server   │
                                                 │  -runtime.scm   │
                                                 │  (服务端运行时) │
                                                 └────────┬────────┘
                                                          │
                                                          ▼
                                                 ┌─────────────────┐
                                                 │  Mogan API      │
                                                 │  (实际文档操作) │
                                                 └─────────────────┘
```

## 实际操作示例

### 1. 查看系统状态

```bash
./bin/mogan-cli status
```

输出示例：
```json
{"status":"ok","mogan_root":"/home/mingshen/git/mogan","client_built":true,...}
```

### 2. 启动服务器

```bash
# 方式 1: 使用 mogan-cli
./bin/mogan-cli start-server

# 方式 2: 手动启动
cd /home/mingshen/git/mogan
export TEXMACS_PATH=/home/mingshen/git/mogan/TeXmacs
./build/linux/x86_64/debug/moganstem -d -debug-bench -server \
  -x '(load "/home/mingshen/git/mogan-test/src/cli/runtime/mogan-server-runtime.scm")'
```

### 3. 创建账户并连接

```bash
# 创建测试账户（只需执行一次）
./bin/mogan-cli create-account

# 连接到服务器
./bin/mogan-cli connect
```

### 4. 文档操作

```bash
# 创建新文档
./bin/mogan-cli new-document

# 写入文本（替换整个文档内容）
./bin/mogan-cli write-text "Hello from mogan-test controller!"

# 在光标位置插入文本
./bin/mogan-cli insert-text " [追加内容]"

# 读取当前缓冲区内容
./bin/mogan-cli buffer-text
# 输出: status: ok
#       value: (document "Hello from mogan-test controller! [追加内容]")

# 获取完整状态信息
./bin/mogan-cli state
# 输出包含: buffer, title, modified, cursor_path, selection_active, undo_possibilities 等
```

### 5. 光标移动

```bash
# 基本移动
./bin/mogan-cli move-start      # 移动到文档开头
./bin/mogan-cli move-end        # 移动到文档结尾
./bin/mogan-cli move-left       # 左移
./bin/mogan-cli move-right      # 右移
./bin/mogan-cli move-up         # 上移
./bin/mogan-cli move-down       # 下移

# 高级移动
./bin/mogan-cli move-start-line     # 移动到行首
./bin/mogan-cli move-end-line       # 移动到行尾
./bin/mogan-cli move-word-left      # 按单词左移
./bin/mogan-cli move-word-right     # 按单词右移
./bin/mogan-cli move-to-line 5      # 跳转到第5行
./bin/mogan-cli move-to-column 10   # 跳转到第10列
```

### 6. 编辑操作

```bash
# 删除操作
./bin/mogan-cli delete-left     # 删除光标左侧字符
./bin/mogan-cli delete-right    # 删除光标右侧字符

# 历史操作
./bin/mogan-cli undo            # 撤销
./bin/mogan-cli redo            # 重做
./bin/mogan-cli clear-undo-history  # 清除撤销历史

# 剪贴板操作
./bin/mogan-cli select-all      # 全选
./bin/mogan-cli copy            # 复制
./bin/mogan-cli cut             # 剪切
./bin/mogan-cli paste           # 粘贴
./bin/mogan-cli clear-selection # 取消选择
```

### 7. 文件操作

```bash
# 保存文档
./bin/mogan-cli save-as "/tmp/my-document.tm"

# 导出为 HTML
./bin/mogan-cli export-buffer "/tmp/my-document.html"

# 打开文件
./bin/mogan-cli open-file "/tmp/my-document.tm"

# 从磁盘恢复
./bin/mogan-cli revert-buffer

# 关闭当前缓冲区
./bin/mogan-cli close-buffer

# 列出所有缓冲区
./bin/mogan-cli buffer-list
```

### 8. 样式设置

```bash
# 设置文档样式
./bin/mogan-cli set-main-style article
./bin/mogan-cli set-main-style letter
./bin/mogan-cli set-main-style book

# 设置文档语言
./bin/mogan-cli set-document-language chinese
./bin/mogan-cli set-document-language english
./bin/mogan-cli set-document-language french

# 添加/移除样式包
./bin/mogan-cli add-style-package number-us
./bin/mogan-cli remove-style-package number-us

# 页面布局
./bin/mogan-cli set-page-medium paper
./bin/mogan-cli set-page-type a4
./bin/mogan-cli set-page-orientation portrait
./bin/mogan-cli set-page-orientation landscape
```

### 9. 搜索替换

```bash
# 设置搜索词
./bin/mogan-cli search-set "hello"

# 导航匹配项
./bin/mogan-cli search-next     # 下一个
./bin/mogan-cli search-prev     # 上一个
./bin/mogan-cli search-first    # 第一个
./bin/mogan-cli search-last     # 最后一个

# 替换
./bin/mogan-cli replace-set "world"   # 设置替换文本
./bin/mogan-cli replace-one           # 替换当前匹配
./bin/mogan-cli replace-all           # 替换所有匹配

# 查看搜索状态
./bin/mogan-cli search-state
```

### 10. 批量操作

```bash
# 使用 target profile 保存连接配置
./bin/mogan-cli target save myserver \
  127.0.0.1 test-user "Test User" test-pass test@example.com

# 使用 target 执行命令
./bin/mogan-cli target run myserver new-document
./bin/mogan-cli target run myserver write-text "Hello"

# 批量执行多个命令
./bin/mogan-cli batch myserver -- \
  new-document -- \
  write-text "Hello World" -- \
  move-end -- \
  insert-text "!" -- \
  buffer-text
```

### 11. 预定义场景

```bash
# 列出可用场景
./bin/mogan-cli scenario list

# 运行编辑测试场景
./bin/mogan-cli scenario smoke-edit

# 运行批量测试场景
./bin/mogan-cli scenario batch-smoke myserver

# 运行文件操作场景
./bin/mogan-cli scenario file-smoke myserver /tmp/test.tm

# 运行导出测试场景
./bin/mogan-cli scenario export-smoke myserver /tmp/export.html

# 运行样式测试场景
./bin/mogan-cli scenario style-smoke myserver

# 运行页面布局场景
./bin/mogan-cli scenario layout-smoke myserver

# 运行搜索替换场景
./bin/mogan-cli scenario search-smoke myserver

# 运行历史操作场景
./bin/mogan-cli scenario history-smoke myserver

# 运行剪贴板场景
./bin/mogan-cli scenario clipboard-smoke myserver
```

## 调试

```bash
# 查看完整日志
./bin/mogan-cli traces

# 查看特定日志文件
cat /tmp/mogan-test-connect-trace.log    # 连接跟踪
cat /tmp/mogan-test-server-trace.log     # 服务端跟踪
cat /tmp/mogan-test-runtime-result.txt   # 运行时结果
cat /tmp/mogan-test-runtime-output.log   # 运行时输出
```

## 完整工作流示例

```bash
#!/bin/bash

# 1. 启动服务器
cd /home/mingshen/git/mogan
export TEXMACS_PATH=/home/mingshen/git/mogan/TeXmacs
./build/linux/x86_64/debug/moganstem -d -debug-bench -server \
  -x '(load "/home/mingshen/git/mogan-test/src/cli/runtime/mogan-server-runtime.scm")' &
sleep 5

# 2. 初始化连接
cd /home/mingshen/git/mogan-test
./bin/mogan-cli create-account  # 只需一次
./bin/mogan-cli connect

# 3. 创建并编辑文档
./bin/mogan-cli new-document
./bin/mogan-cli write-text "Mogan 实际控制演示"
./bin/mogan-cli insert-return
./bin/mogan-cli insert-text "这是一段测试文本。"
./bin/mogan-cli set-main-style article
./bin/mogan-cli set-document-language chinese

# 4. 保存和导出
./bin/mogan-cli save-as "/tmp/demo.tm"
./bin/mogan-cli export-buffer "/tmp/demo.html"

# 5. 查看结果
echo "=== 文档状态 ==="
./bin/mogan-cli state
echo "=== 文档内容 ==="
./bin/mogan-cli buffer-text
echo "=== 文件列表 ==="
ls -la /tmp/demo.*
```

## 更多文档

- [完整控制命令参考](CONTROL.md) - 详细的命令列表和参数说明
- [项目规范](../CLAUDE.md) - 开发规范和约束
- [任务规格](spec.md) - 原始任务规格说明