# Playbooks

`playbooks/` 只放两类文件：

- `assets/`: prompt / source / rules
- `scripts/`: 可直接执行的 runbook

一键执行优先使用：

- `playbooks/scripts/linear-algebra-demo.sh`
- `playbooks/scripts/classroom-notes-demo.sh`

## 目标

让 agent 用最少阅读成本拿到三类信息：

1. 要做什么
2. 按什么顺序做
3. 每一步实际打到哪条调用链

## 写法

每个 playbook 都尽量压缩成这四段：

### 1. Goal

- 最终产物
- 关键约束

### 2. Fast Map

只列会用到的命令映射：

- `CLI -> shell route -> tm-service -> Mogan call/effect`

例如：

- `new-document -> handle_simple_control_command -> mogan-test-new-document -> new-document`
- `insert-text -> handle_control_value_command -> mogan-test-insert-text-b64 -> insert`
- `insert-section -> handle_insert_basic_command -> mogan-test-insert-section-b64 -> make-section + insert`
- `insert-inline-equation -> handle_insert_basic_command -> mogan-test-insert-inline-equation -> parse inline latex + insert`
- `insert-equation -> handle_insert_basic_command -> mogan-test-insert-equation -> parse display latex + insert`
- `insert-matrix -> handle_insert_complex_command -> mogan-test-insert-matrix -> build matrix tree`
- `insert-session -> handle_insert_session_command -> mogan-test-insert-session-b64 -> make-session`
- `session-evaluate -> handle_simple_control_command -> mogan-test-session-evaluate -> session-evaluate`
- `export-buffer -> handle_file_command -> mogan-test-export-buffer -> export buffer`

### 3. Steps

每步只保留这几个字段：

- `Step`
- `CLI`
- `Chain`
- `Expect`
- `Check`

### 4. Done

列最终验收项，不写长说明。

如果步骤已经稳定，优先把它们沉淀成 `.sh` 脚本，而不是只保留 markdown。

## 原则

- 精确，但不啰嗦
- 默认按顺序执行
- 需要 `exit-right` 的地方必须明确写出
- 需要 `state` / `buffer-text` 验证的地方必须明确写出
- 禁止把大段背景介绍夹在步骤中间
