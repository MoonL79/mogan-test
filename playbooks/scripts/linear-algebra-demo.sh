#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

RAW_NOTES_PATH="${RAW_NOTES_PATH:-$REPO_ROOT/playbooks/assets/linear-algebra-raw-notes.txt}"
OUTPUT_HTML="${1:-/tmp/linear-algebra-demo.html}"

TITLE="线性代数第三讲：矩阵与线性方程组"
SECTION_1="矩阵与线性方程组"
SECTION_2="行列式、可逆与解的情况"
SECTION_3="一个 2x2 例子"
SECTION_4="后续联系"
SUMMARY_LABEL="本节核心结论"
SUMMARY_TEXT="：矩阵把线性关系与线性方程组统一成了一个可计算、可分析的结构。"

require_raw_notes() {
  [[ -f "$RAW_NOTES_PATH" ]] || fail "missing raw notes: $RAW_NOTES_PATH"
}

read_raw_notes() {
  log "reading raw notes: $RAW_NOTES_PATH"
  RAW_NOTES_CONTENT="$(cat "$RAW_NOTES_PATH")"
  [[ -n "$RAW_NOTES_CONTENT" ]] || fail "raw notes are empty"
}

prepare_runtime() {
  check_env
  ensure_connection
}

start_document() {
  log "creating a new document"
  cli_try new-document
  cli_try set-main-style generic
  cli_try set-document-language chinese
}

insert_title() {
  log "inserting title"
  cli_try insert-bold "$TITLE"
  cli_try insert-return
}

open_section() {
  local title="$1"
  cli_try insert-section "$title"
  cli_try exit-right
  cli_try insert-return
}

insert_section_matrix_and_system() {
  log "inserting section: $SECTION_1"
  open_section "$SECTION_1"
  printf '矩阵不只是表格，它也是线性变换的一种表示。线性系统通常写成 ' \
    | cli_try stream-text --chunk-size 14
  cli_try insert-inline-equation 'Ax=b'
  printf '。矩阵和方程组可以统一理解，就是把许多方程压缩成一个统一表示。' \
    | cli_try stream-text --chunk-size 14
}

insert_section_determinant() {
  log "inserting section: $SECTION_2"
  open_section "$SECTION_2"
  printf '若 ' | cli_try stream-text --chunk-size 14
  cli_try insert-inline-equation 'det(A) \neq 0'
  printf '，则矩阵可逆，系统有唯一解。若 ' | cli_try stream-text --chunk-size 14
  cli_try insert-inline-equation 'det(A)=0'
  printf '，则系统不再有唯一解，可能无解，也可能有无穷多解。' \
    | cli_try stream-text --chunk-size 14
  cli_try insert-return
  cli_try insert-equation 'Ax=b'
}

insert_section_matrix_example() {
  log "inserting section: $SECTION_3"
  open_section "$SECTION_3"
  printf '下面用一个 2x2 矩阵说明矩阵表示与方程组表示之间的联系。' \
    | cli_try stream-text --chunk-size 14
  cli_try insert-return
  cli_try insert-matrix 2 2 '1 2 3 4'
  cli_try insert-return
  printf '矩阵的列向量也可以理解成变换后基向量的位置。' \
    | cli_try stream-text --chunk-size 14
}

insert_section_followup() {
  log "inserting section: $SECTION_4"
  open_section "$SECTION_4"
  printf '后续内容会把矩阵、行列式与特征值、特征向量联系起来理解。' \
    | cli_try stream-text --chunk-size 14
  cli_try insert-return
}

insert_summary() {
  log "inserting summary"
  cli_try insert-bold "$SUMMARY_LABEL"
  cli_try insert-text "$SUMMARY_TEXT"
  cli_try insert-return
}

export_document() {
  log "exporting html: $OUTPUT_HTML"
  cli_try export-buffer "$OUTPUT_HTML"
}

verify_document() {
  log "verifying document structure"
  cli_try buffer-text >/tmp/mogan-linear-algebra-demo-buffer.out
  cli_try state >/tmp/mogan-linear-algebra-demo-state.out
  show_file_if_exists "$OUTPUT_HTML"
}

main() {
  require_raw_notes
  read_raw_notes
  prepare_runtime
  start_document
  insert_title
  insert_section_matrix_and_system
  insert_section_determinant
  insert_section_matrix_example
  insert_section_followup
  insert_summary
  export_document
  verify_document
  log "done: $OUTPUT_HTML"
}

main "$@"
