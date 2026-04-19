#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

OUTPUT_HTML="${1:-/tmp/classroom-notes-demo.html}"

check_env
ensure_connection

log "building classroom notes investor demo"

cli_try new-document

printf '线性代数 第三讲：矩阵与线性方程组\n\n矩阵用于表示线性变换。\n线性系统通常写成 ' \
  | cli_try stream-text --replace --chunk-size 16
cli_try insert-inline-equation 'Ax=b'

printf '\n若 ' | cli_try stream-text --chunk-size 16
cli_try insert-inline-equation 'det(A) \neq 0'
printf '，则系统有唯一解。\n\n例子：考虑一个 2x2 矩阵。\n' \
  | cli_try stream-text --chunk-size 16

cli_try insert-equation 'Ax=b'
cli_try insert-matrix 2 2 '1 2 3 4'

cli_try insert-return
cli_try insert-bold '本节核心结论'
cli_try insert-text '：矩阵是线性系统与线性变换的统一表示工具。'
cli_try insert-return

cli_try export-buffer "$OUTPUT_HTML"

log "verifying document structure"
cli_try buffer-text
cli_try state >/tmp/mogan-classroom-notes-demo-state.out
show_file_if_exists "$OUTPUT_HTML"

log "done: $OUTPUT_HTML"
