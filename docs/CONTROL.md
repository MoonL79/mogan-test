# Mogan 实际控制使用指南

本文档说明如何使用 `mogan-test` 对 `mogan` 进行实际控制。

## 快速开始

### 1. 启动服务器并执行控制命令

```bash
# 运行完整演示
./demo-control.sh
```

### 2. 手动控制流程

```bash
# 步骤 1: 启动 Mogan 服务器
cd /home/mingshen/git/mogan
export TEXMACS_PATH=/home/mingshen/git/mogan/TeXmacs
./build/linux/x86_64/debug/moganstem -d -debug-bench -server \
  -x '(load "/home/mingshen/git/mogan-test/src/cli/runtime/mogan-server-runtime.scm")' \
  > /tmp/mogan-server.log 2>&1 &

# 步骤 2: 创建测试账户（只需一次）
cd /home/mingshen/git/mogan-test
./bin/mogan-cli create-account

# 步骤 3: 连接服务器
./bin/mogan-cli connect

# 步骤 4: 执行控制命令
./bin/mogan-cli new-document
./bin/mogan-cli write-text "Hello World"
./bin/mogan-cli buffer-text
./bin/mogan-cli state
```

## 可用控制命令

### 文档操作

| 命令 | 说明 | 示例 |
|------|------|------|
| `new-document` | 创建新文档 | `./bin/mogan-cli new-document` |
| `write-text <text>` | 写入文本（替换整个文档） | `./bin/mogan-cli write-text "Hello"` |
| `buffer-text` | 读取当前缓冲区内容 | `./bin/mogan-cli buffer-text` |
| `state` | 获取完整状态信息 | `./bin/mogan-cli state` |
| `save-as <path>` | 另存为文件 | `./bin/mogan-cli save-as /tmp/doc.tm` |
| `export-buffer <path>` | 导出为其他格式 | `./bin/mogan-cli export-buffer /tmp/doc.html` |
| `open-file <path>` | 打开文件 | `./bin/mogan-cli open-file /tmp/doc.tm` |
| `revert-buffer` | 从磁盘恢复 | `./bin/mogan-cli revert-buffer` |
| `close-buffer` | 关闭当前缓冲区 | `./bin/mogan-cli close-buffer` |
| `buffer-list` | 列出所有缓冲区 | `./bin/mogan-cli buffer-list` |
| `switch-buffer <name>` | 切换到指定缓冲区 | `./bin/mogan-cli switch-buffer tmfs://xxx` |

### 光标移动

| 命令 | 说明 | 示例 |
|------|------|------|
| `move-left/right/up/down` | 基本方向移动 | `./bin/mogan-cli move-right` |
| `move-start/end` | 移动到文档开头/结尾 | `./bin/mogan-cli move-start` |
| `move-start-line/end-line` | 移动到行首/行尾 | `./bin/mogan-cli move-start-line` |
| `move-word-left/right` | 按单词移动 | `./bin/mogan-cli move-word-right` |
| `move-to-line <n>` | 跳转到指定行 | `./bin/mogan-cli move-to-line 5` |
| `move-to-column <n>` | 跳转到指定列 | `./bin/mogan-cli move-to-column 10` |

### 编辑操作

| 命令 | 说明 | 示例 |
|------|------|------|
| `insert-text <text>` | 在光标处插入文本 | `./bin/mogan-cli insert-text "abc"` |
| `insert-return` | 插入换行 | `./bin/mogan-cli insert-return` |
| `delete-left/right` | 删除字符 | `./bin/mogan-cli delete-left` |
| `undo/redo` | 撤销/重做 | `./bin/mogan-cli undo` |
| `clear-undo-history` | 清除撤销历史 | `./bin/mogan-cli clear-undo-history` |

### 选择操作

| 命令 | 说明 | 示例 |
|------|------|------|
| `select-all` | 全选 | `./bin/mogan-cli select-all` |
| `select-start/end` | 设置选区起点/终点 | `./bin/mogan-cli select-start` |
| `clear-selection` | 取消选择 | `./bin/mogan-cli clear-selection` |
| `copy/cut/paste` | 剪贴板操作 | `./bin/mogan-cli copy` |

### 搜索替换

| 命令 | 说明 | 示例 |
|------|------|------|
| `search-set <query>` | 设置搜索词 | `./bin/mogan-cli search-set "hello"` |
| `search-next/prev` | 下一个/上一个匹配 | `./bin/mogan-cli search-next` |
| `search-first/last` | 第一个/最后一个匹配 | `./bin/mogan-cli search-first` |
| `replace-set <text>` | 设置替换文本 | `./bin/mogan-cli replace-set "world"` |
| `replace-one/all` | 替换一次/全部 | `./bin/mogan-cli replace-all` |

### 样式设置

| 命令 | 说明 | 示例 |
|------|------|------|
| `set-main-style <style>` | 设置主样式 | `./bin/mogan-cli set-main-style article` |
| `set-document-language <lang>` | 设置文档语言 | `./bin/mogan-cli set-document-language chinese` |
| `add-style-package <pack>` | 添加样式包 | `./bin/mogan-cli add-style-package number-us` |
| `remove-style-package <pack>` | 移除样式包 | `./bin/mogan-cli remove-style-package number-us` |
| `set-page-medium <medium>` | 设置页面介质 | `./bin/mogan-cli set-page-medium papyrus` |
| `set-page-type <type>` | 设置页面类型 | `./bin/mogan-cli set-page-type letter` |
| `set-page-orientation <orient>` | 设置页面方向 | `./bin/mogan-cli set-page-orientation landscape` |

### 数学公式插入

| 命令 | 说明 | 示例 |
|------|------|------|
| `insert-equation <latex>` | 插入 LaTeX 公式 | `./bin/mogan-cli insert-equation "x^2 + y^2 = 1"` |
| `insert-inline-equation <latex>` | 插入行内公式 | `./bin/mogan-cli insert-inline-equation "E=mc^2"` |
| `insert-fraction <num> <den>` | 插入分数 | `./bin/mogan-cli insert-fraction 1 2` |
| `insert-sqrt <content>` | 插入平方根 | `./bin/mogan-cli insert-sqrt "x+y"` |
| `insert-matrix <rows> <cols> <data>` | 插入矩阵 | `./bin/mogan-cli insert-matrix 2 2 "a b c d"` |
| `insert-sum <from> <to> <body>` | 插入求和 | `./bin/mogan-cli insert-sum i=0 n i` |
| `insert-integral <from> <to> <body>` | 插入积分 | `./bin/mogan-cli insert-integral 0 1 x` |

### 格式化插入

| 命令 | 说明 | 示例 |
|------|------|------|
| `insert-bold <text>` | 插入粗体 | `./bin/mogan-cli insert-bold "bold text"` |
| `insert-italic <text>` | 插入斜体 | `./bin/mogan-cli insert-italic "italic"` |
| `insert-code <text>` | 插入代码 | `./bin/mogan-cli insert-code "print(1)"` |
| `insert-link <url> <text>` | 插入链接 | `./bin/mogan-cli insert-link "https://example.com" "link"` |
| `insert-table <rows> <cols>` | 插入表格 | `./bin/mogan-cli insert-table 3 4` |

## 批量操作

### Target Profile

```bash
# 保存连接配置
./bin/mogan-cli target save myserver 127.0.0.1 user "User Name" pass email@test.com

# 列出所有配置
./bin/mogan-cli target list

# 显示配置详情
./bin/mogan-cli target show myserver

# 使用配置执行命令
./bin/mogan-cli target run myserver new-document
./bin/mogan-cli target run myserver write-text "Hello"
```

### Batch 模式

```bash
# 批量执行多个命令
./bin/mogan-cli batch myserver -- \
  new-document -- \
  write-text "Hello World" -- \
  move-end -- \
  insert-text "!" -- \
  buffer-text
```

### Scenario 场景

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

## 调试与日志

```bash
# 查看运行日志
./bin/mogan-cli traces

# 查看服务器端日志
cat /tmp/mogan-test-server-trace.log

# 查看客户端连接日志
cat /tmp/mogan-test-connect-trace.log

# 查看运行时结果
cat /tmp/mogan-test-runtime-result.txt
```

## 状态返回值说明

`state` 命令返回的状态包含以下字段：

```scheme
(("buffer" . "/path/to/file.tm")        ; 当前缓冲区路径
 ("title" . "文档标题")                  ; 文档标题
 ("modified" . #f)                       ; 是否已修改
 ("cursor_path" . "(1 0 33)")            ; 光标位置
 ("selection_active" . #f)               ; 是否有选区
 ("selection_start" . "")                ; 选区起点
 ("selection_end" . "")                  ; 选区终点
 ("selection_tree" . "")                 ; 选区内容
 ("undo_possibilities" . 1)              ; 可撤销次数
 ("redo_possibilities" . 0)              ; 可重做次数
 ("buffer_text" . "文档内容")             ; 缓冲区文本
 ("main_style" . "generic")              ; 主样式
 ("style_list" . "(...)")                ; 样式列表
 ("document_language" . "chinese")       ; 文档语言
 ("page_medium" . "paper")               ; 页面介质
 ("page_type" . "a4")                    ; 页面类型
 ("page_orientation" . "portrait")       ; 页面方向
 ("page_width" . "auto")                 ; 页面宽度
 ("page_height" . "auto"))               ; 页面高度
```

## 架构说明

```
┌─────────────────────────────────────────────────────────────┐
│                      mogan-cli (Bash)                        │
│                   命令解析与参数处理                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       v
┌─────────────────────────────────────────────────────────────┐
│              client.scm (Goldfish Scheme)                    │
│              客户端运行时，通过 -x 参数加载                   │
│          负责：建立连接、登录、发送远程命令                    │
└──────────────────────┬──────────────────────────────────────┘
                       │ TCP (端口 6561)
                       v
┌─────────────────────────────────────────────────────────────┐
│              mogan-server-runtime.scm                        │
│              服务端运行时，通过 -server -x 加载               │
│      负责：账户管理、命令分发、实际 Mogan API 调用            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       v
┌─────────────────────────────────────────────────────────────┐
│                     Mogan 内部 API                           │
│         buffer-*, cursor-*, selection-*, undo/redo          │
│              insert, delete, export 等                      │
└─────────────────────────────────────────────────────────────┘
```

## 注意事项

1. **必须先启动服务器**：所有控制命令都需要一个运行的 Mogan 服务器实例
2. **账户只需创建一次**：`create-account` 只需在第一次运行时执行
3. **连接是必需的**：执行控制命令前必须先成功执行 `connect`
4. **超时处理**：某些命令可能需要调整超时时间
5. **Qt 显示**：在无头环境使用 `-platform minimal` 参数

## 完整示例

```bash
#!/bin/bash

# 启动服务器
cd /home/mingshen/git/mogan
export TEXMACS_PATH=/home/mingshen/git/mogan/TeXmacs
./build/linux/x86_64/debug/moganstem -d -debug-bench -server \
  -x '(load "/home/mingshen/git/mogan-test/src/cli/runtime/mogan-server-runtime.scm")' &
sleep 5

# 初始化
cd /home/mingshen/git/mogan-test
./bin/mogan-cli create-account
./bin/mogan-cli connect

# 创建文档并编辑
./bin/mogan-cli new-document
./bin/mogan-cli write-text "标题"
./bin/mogan-cli insert-return
./bin/mogan-cli insert-text "这是正文内容"
./bin/mogan-cli move-start
./bin/mogan-cli set-main-style article
./bin/mogan-cli set-document-language chinese

# 保存和导出
./bin/mogan-cli save-as "/tmp/my-doc.tm"
./bin/mogan-cli export-buffer "/tmp/my-doc.html"

# 查看结果
./bin/mogan-cli state
./bin/mogan-cli buffer-text
```