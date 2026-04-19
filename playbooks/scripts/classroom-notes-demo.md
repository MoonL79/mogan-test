# 课堂笔记 Demo 剧本

## Goal

面向投资人演示：

- agent 在真实文档里持续编辑
- 同时处理文本 / 公式 / 矩阵 / 强调
- 最后导出 HTML 交付物

主题固定：

- `线性代数：矩阵与线性方程组`

## One Click

```bash
./playbooks/scripts/classroom-notes-demo.sh
```

可选输出路径：

```bash
./playbooks/scripts/classroom-notes-demo.sh /tmp/classroom-notes-demo.html
```

## Fast Map

- `ping -> handle_simple_control_command -> mogan-test-ping`
- `current-buffer -> handle_simple_control_command -> mogan-test-current-buffer`
- `new-document -> handle_simple_control_command -> mogan-test-new-document -> new-document`
- `stream-text -> handle_stream_text -> mogan-test-insert-text-b64 -> insert`
- `insert-inline-equation -> handle_insert_basic_command -> mogan-test-insert-inline-equation -> parse inline latex + insert`
- `insert-equation -> handle_insert_basic_command -> mogan-test-insert-equation -> parse display latex + insert`
- `insert-matrix -> handle_insert_complex_command -> mogan-test-insert-matrix -> build matrix tree`
- `insert-bold -> handle_insert_basic_command -> mogan-test-insert-bold-b64 -> insert '(bold ...)`
- `insert-text -> handle_control_value_command -> mogan-test-insert-text-b64 -> insert`
- `insert-return -> handle_simple_control_command -> mogan-test-insert-return -> insert-return`
- `export-buffer -> handle_file_command -> mogan-test-export-buffer -> export buffer`
- `buffer-text -> handle_simple_control_command -> mogan-test-buffer-text -> serialize tree`
- `state -> handle_simple_control_command -> mogan-test-state -> full state`

## Steps

### Step 0

- CLI:
```bash
./bin/mogan-cli ping
./bin/mogan-cli current-buffer
```
- Expect: server 可用，当前连接有效
- Check: `pong` 和当前 buffer 路径

### Step 1

- CLI:
```bash
./bin/mogan-cli new-document
```
- Chain: `new-document -> handle_simple_control_command -> mogan-test-new-document -> new-document`
- Expect: 新 scratch buffer
- Check:
```bash
./bin/mogan-cli current-buffer
```

### Step 2

- CLI:
```bash
printf '线性代数 第三讲：矩阵与线性方程组\n\n矩阵用于表示线性变换。\n线性系统通常写成 ' \
  | ./bin/mogan-cli stream-text --replace --chunk-size 16
```
- Chain: `stream-text -> handle_stream_text -> mogan-test-insert-text-b64 -> insert`
- Expect: 标题和正文分块出现
- Check:
```bash
./bin/mogan-cli buffer-text
```

### Step 3

- CLI:
```bash
./bin/mogan-cli insert-inline-equation 'Ax=b'
```
- Chain: `insert-inline-equation -> handle_insert_basic_command -> mogan-test-insert-inline-equation -> parse inline latex + insert`
- Expect: 行内公式出现
- Check:
```bash
./bin/mogan-cli state
```

### Step 4

- CLI:
```bash
printf '\n若 ' | ./bin/mogan-cli stream-text --chunk-size 16
./bin/mogan-cli insert-inline-equation 'det(A) \neq 0'
printf '，则系统有唯一解。\n\n例子：考虑一个 2x2 矩阵。\n' \
  | ./bin/mogan-cli stream-text --chunk-size 16
```
- Chain:
  - `stream-text -> handle_stream_text -> mogan-test-insert-text-b64 -> insert`
  - `insert-inline-equation -> handle_insert_basic_command -> mogan-test-insert-inline-equation -> parse inline latex + insert`
- Expect: 正文和第二个行内公式接上
- Check:
```bash
./bin/mogan-cli buffer-text
```

### Step 5

- CLI:
```bash
./bin/mogan-cli insert-equation 'Ax=b'
```
- Chain: `insert-equation -> handle_insert_basic_command -> mogan-test-insert-equation -> parse display latex + insert`
- Expect: 显示公式块出现
- Check:
```bash
./bin/mogan-cli state
```

### Step 6

- CLI:
```bash
./bin/mogan-cli insert-matrix 2 2 '1 2 3 4'
```
- Chain: `insert-matrix -> handle_insert_complex_command -> mogan-test-insert-matrix -> build matrix tree`
- Expect: 2x2 矩阵出现
- Check:
```bash
./bin/mogan-cli buffer-text
```

### Step 7

- CLI:
```bash
./bin/mogan-cli insert-return
./bin/mogan-cli insert-bold '本节核心结论'
./bin/mogan-cli insert-text '：矩阵是线性系统与线性变换的统一表示工具。'
```
- Chain:
  - `insert-return -> handle_simple_control_command -> mogan-test-insert-return -> insert-return`
  - `insert-bold -> handle_insert_basic_command -> mogan-test-insert-bold-b64 -> insert '(bold ...)`
  - `insert-text -> handle_control_value_command -> mogan-test-insert-text-b64 -> insert`
- Expect: 总结段独立且有强调
- Check:
```bash
./bin/mogan-cli buffer-text
```

### Step 8

- CLI:
```bash
./bin/mogan-cli export-buffer /tmp/classroom-notes-demo.html
```
- Chain: `export-buffer -> handle_file_command -> mogan-test-export-buffer -> export buffer`
- Expect: HTML 文件生成
- Check:
```bash
ls -l /tmp/classroom-notes-demo.html
```

## Done

- `./bin/mogan-cli buffer-text`
- `./bin/mogan-cli state`

确认：

- 有标题
- 有行内公式
- 有显示公式
- 有矩阵
- 有总结段
- 没有原始 TeXmacs 标记文本
