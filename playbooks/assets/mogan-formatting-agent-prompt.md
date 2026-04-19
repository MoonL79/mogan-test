# 通用 Mogan 排版提示词

## Goal

把用户内容实际写进 Mogan 文档，而不是输出一段“排版后的文本”。

## Fast Rules

- 不手写 TeXmacs/Mogan 原始标记
- 能用结构命令就不用纯文本伪装结构
- `section` / `subsection` / `subsubsection` 后必须显式 `exit-right`
- 完成前必须跑 `buffer-text` 或 `state`

## Fast Map

- `new-document -> handle_simple_control_command -> mogan-test-new-document -> new-document`
- `write-text -> handle_write_text -> mogan-test-write-text-b64 -> buffer-set-body`
- `stream-text -> handle_stream_text -> mogan-test-insert-text-b64 -> insert`
- `insert-text -> handle_control_value_command -> mogan-test-insert-text-b64 -> insert`
- `insert-return -> handle_simple_control_command -> mogan-test-insert-return -> insert-return`
- `insert-bold -> handle_insert_basic_command -> mogan-test-insert-bold-b64 -> insert '(bold ...)`
- `insert-italic -> handle_insert_basic_command -> mogan-test-insert-italic-b64 -> insert '(it ...)`
- `insert-code -> handle_insert_basic_command -> mogan-test-insert-code-b64 -> insert '(code ...)`
- `insert-inline-equation -> handle_insert_basic_command -> mogan-test-insert-inline-equation -> parse inline latex + insert`
- `insert-equation -> handle_insert_basic_command -> mogan-test-insert-equation -> parse display latex + insert`
- `insert-matrix -> handle_insert_complex_command -> mogan-test-insert-matrix -> build matrix tree`
- `insert-link -> handle_insert_complex_command -> mogan-test-insert-link -> insert hlink`
- `insert-section -> handle_insert_basic_command -> mogan-test-insert-section-b64 -> make-section + insert`
- `exit-right -> handle_simple_control_command -> mogan-test-structured-exit-right -> structured-exit-right`
- `insert-session -> handle_insert_session_command -> mogan-test-insert-session-b64 -> make-session`
- `session-evaluate -> handle_simple_control_command -> mogan-test-session-evaluate -> session-evaluate`
- `export-buffer -> handle_file_command -> mogan-test-export-buffer -> export buffer`
- `buffer-text -> handle_simple_control_command -> mogan-test-buffer-text -> serialize tree`
- `state -> handle_simple_control_command -> mogan-test-state -> full state`

## Execution Skeleton

### Step 1. Parse

- 提取：标题 / sections / 强调句 / 公式 / 矩阵 / 总结

### Step 2. Open

- `./bin/mogan-cli new-document`

### Step 3. Build Base

- 普通正文优先用 `stream-text`
- 必要时用 `insert-text`

### Step 4. Add Structure

- 标题强调：`insert-bold`
- section：`insert-section` -> `exit-right` -> `insert-return`
- 行内公式：`insert-inline-equation`
- 显示公式：`insert-equation`
- 矩阵：`insert-matrix`
- 代码：`insert-code`
- 链接：`insert-link`
- session：`insert-session` -> `session-evaluate`

### Step 5. Verify

- `./bin/mogan-cli buffer-text`
- `./bin/mogan-cli state`

## Hard Failures

- 把 `<with|...>` / `<math|...>` / `<matrix|...>` 当正文写进去
- section 标题里手写编号
- 该用结构命令的地方只写纯文本
- 不做 `buffer-text` / `state` 自检

## Minimal Report Format

完成后只需回报这三类信息：

1. 实际执行了哪些关键命令
2. 最终文档结构
3. 导出路径或验证结果
