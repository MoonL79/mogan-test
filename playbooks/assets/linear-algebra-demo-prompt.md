# 线性代数演示提示词

## Goal

读取 `playbooks/assets/linear-algebra-raw-notes.txt`，把内容整理进当前 Mogan 文档，并导出：

- HTML: `/tmp/linear-algebra-demo.html`

必须满足：

- 新建文档，不污染现有内容
- 标题 1 个
- section 2 到 4 个
- 行内公式至少 1 个
- 显示公式至少 1 个
- 2x2 矩阵 1 个
- “本节核心结论”单独成段并强调
- 标题和 section 标题不手写编号

## One Click

```bash
./playbooks/scripts/linear-algebra-demo.sh
```

可选输出路径：

```bash
./playbooks/scripts/linear-algebra-demo.sh /tmp/linear-algebra-demo.html
```

## Fast Map

- `new-document -> handle_simple_control_command -> mogan-test-new-document -> new-document`
- `set-main-style -> handle_style_command -> mogan-test-set-main-style -> set-main-style`
- `set-document-language -> handle_style_command -> mogan-test-set-document-language -> set-document-language`
- `stream-text -> handle_stream_text -> mogan-test-insert-text-b64 -> insert`
- `insert-text -> handle_control_value_command -> mogan-test-insert-text-b64 -> insert`
- `insert-return -> handle_simple_control_command -> mogan-test-insert-return -> insert-return`
- `insert-bold -> handle_insert_basic_command -> mogan-test-insert-bold-b64 -> insert '(bold ...)`
- `insert-section -> handle_insert_basic_command -> mogan-test-insert-section-b64 -> make-section + insert`
- `exit-right -> handle_simple_control_command -> mogan-test-structured-exit-right -> structured-exit-right`
- `insert-inline-equation -> handle_insert_basic_command -> mogan-test-insert-inline-equation -> parse inline latex + insert`
- `insert-equation -> handle_insert_basic_command -> mogan-test-insert-equation -> parse display latex + insert`
- `insert-matrix -> handle_insert_complex_command -> mogan-test-insert-matrix -> build matrix tree`
- `export-buffer -> handle_file_command -> mogan-test-export-buffer -> export buffer`
- `buffer-text -> handle_simple_control_command -> mogan-test-buffer-text -> serialize tree`
- `state -> handle_simple_control_command -> mogan-test-state -> full state record`

## Steps

### Step 1

- CLI: 读取原始笔记，提取标题 / sections / 公式 / 矩阵 / 总结句
- Chain: 无 Mogan 调用
- Expect: 得到一份 2 到 4 节的结构草稿
- Check: 自检结构是否覆盖所有硬约束

### Step 2

- CLI: `./bin/mogan-cli new-document`
- Chain: `new-document -> handle_simple_control_command -> mogan-test-new-document -> new-document`
- Expect: 切到新 scratch buffer
- Check: `./bin/mogan-cli current-buffer`

### Step 3

- CLI:
```bash
./bin/mogan-cli set-main-style generic
./bin/mogan-cli set-document-language chinese
```
- Chain:
  - `set-main-style -> handle_style_command -> mogan-test-set-main-style -> set-main-style`
  - `set-document-language -> handle_style_command -> mogan-test-set-document-language -> set-document-language`
- Expect: 文档样式为 `generic`，语言为 `chinese`
- Check: `./bin/mogan-cli state`

### Step 4

- CLI:
```bash
./bin/mogan-cli insert-bold "线性代数第三讲：矩阵与线性方程组"
./bin/mogan-cli insert-return
```
- Chain:
  - `insert-bold -> handle_insert_basic_command -> mogan-test-insert-bold-b64 -> insert '(bold ...)`
  - `insert-return -> handle_simple_control_command -> mogan-test-insert-return -> insert-return`
- Expect: 标题出现，光标进入下一段
- Check: `./bin/mogan-cli buffer-text`

### Step 5

- CLI: 对每个 section 重复：
```bash
./bin/mogan-cli insert-section "<标题>"
./bin/mogan-cli exit-right
./bin/mogan-cli insert-return
```
- Chain:
  - `insert-section -> handle_insert_basic_command -> mogan-test-insert-section-b64 -> make-section + insert`
  - `exit-right -> handle_simple_control_command -> mogan-test-structured-exit-right -> structured-exit-right`
  - `insert-return -> handle_simple_control_command -> mogan-test-insert-return -> insert-return`
- Expect: 光标离开 section 标题，落到正文
- Check: `./bin/mogan-cli state`

### Step 6

- CLI: 用 `stream-text` 分块写正文，例如：
```bash
printf '...' | ./bin/mogan-cli stream-text --chunk-size 12
```
- Chain: `stream-text -> handle_stream_text -> mogan-test-insert-text-b64 -> insert`
- Expect: 正文逐步增长，不是一把覆盖
- Check: `./bin/mogan-cli buffer-text`

### Step 7

- CLI:
```bash
./bin/mogan-cli insert-inline-equation 'Ax=b'
./bin/mogan-cli insert-inline-equation 'det(A) \neq 0'
```
- Chain: `insert-inline-equation -> handle_insert_basic_command -> mogan-test-insert-inline-equation -> parse inline latex + insert`
- Expect: 行内公式节点出现在正文中
- Check: `./bin/mogan-cli state`

### Step 8

- CLI:
```bash
./bin/mogan-cli insert-equation 'Ax=b'
```
- Chain: `insert-equation -> handle_insert_basic_command -> mogan-test-insert-equation -> parse display latex + insert`
- Expect: 独立公式块出现，光标回到块外
- Check: `./bin/mogan-cli state`

### Step 9

- CLI:
```bash
./bin/mogan-cli insert-matrix 2 2 '1 2 3 4'
```
- Chain: `insert-matrix -> handle_insert_complex_command -> mogan-test-insert-matrix -> build matrix tree`
- Expect: 2x2 矩阵节点出现
- Check: `./bin/mogan-cli buffer-text`

### Step 10

- CLI:
```bash
./bin/mogan-cli insert-return
./bin/mogan-cli insert-bold '本节核心结论'
./bin/mogan-cli insert-text '：矩阵是线性系统与线性方程组分析的核心表达工具。'
```
- Chain:
  - `insert-return -> handle_simple_control_command -> mogan-test-insert-return -> insert-return`
  - `insert-bold -> handle_insert_basic_command -> mogan-test-insert-bold-b64 -> insert '(bold ...)`
  - `insert-text -> handle_control_value_command -> mogan-test-insert-text-b64 -> insert`
- Expect: 总结段独立，强调短语为结构化加粗
- Check: `./bin/mogan-cli buffer-text`

### Step 11

- CLI:
```bash
./bin/mogan-cli export-buffer /tmp/linear-algebra-demo.html
```
- Chain: `export-buffer -> handle_file_command -> mogan-test-export-buffer -> export buffer`
- Expect: HTML 导出成功
- Check:
```bash
ls -l /tmp/linear-algebra-demo.html
```

## Done

- `./bin/mogan-cli buffer-text`
- `./bin/mogan-cli state`

必须确认：

- 有标题
- 有 2 到 4 个 `section`
- 有行内公式
- 有显示公式
- 有矩阵
- 有总结段
- 没有原始 `<math|...>` / `<matrix|...>` 文本
