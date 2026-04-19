print_target_usage() {
  cat <<'EOF'
Usage: mogan-cli target <save|show|list|delete|run> [...]
EOF
}

print_scenario_list() {
  cat <<'EOF'
smoke-edit
batch-smoke
file-smoke
export-smoke
style-smoke
layout-smoke
search-smoke
history-smoke
clipboard-smoke
EOF
}

print_scenario_usage() {
  cat <<'EOF'
Usage: mogan-cli scenario <list|smoke-edit|batch-smoke|file-smoke|export-smoke|style-smoke|layout-smoke|search-smoke|history-smoke|clipboard-smoke> [args...]
EOF
}

print_main_usage() {
  cat <<'EOF'
Usage: mogan-cli <command> [args...]
Commands:
  status         - Show current runtime and connection status as JSON
  workflow       - Show the required Mogan startup workflow
  build-client   - Build Mogan with `xmake b stem`
  start-client   - Start a full Mogan client with `xmake r stem`
  start-server   - Start a connectable Mogan client with `moganstem -server`
  exec-internal  - Start Mogan and execute internal Scheme via `-x`
  create-account - Create a test account through the remote service layer
  connect        - Attempt remote-login inside the runtime
  ping           - Run the server-side `mogan-test-ping` service
  current-buffer - Query the current buffer from the running Mogan instance
  new-document   - Create a new document through the running Mogan instance
  write-text     - Replace the current buffer with plain text content
  stream-text    - Stream text from stdin or a file into the current buffer
  buffer-text    - Read back the current buffer text content
  state          - Inspect buffer, cursor, selection, and text state
  move-*         - Cursor movement primitives
  select-*       - Selection primitives
  undo/redo      - History primitives
  copy/cut/paste - Clipboard primitives
  clear-undo-history - Reset the current edit history
  insert-text    - Insert text at the cursor
  insert-session - Insert a language session (language [variant])
  insert-return  - Insert a raw return
  exit-right     - Exit the current structured node to the right
  delete-*       - Delete at the cursor
  save-buffer    - Save the current buffer
  switch-buffer  - Switch to another buffer
  search-state   - Inspect search and replace state
  search-set     - Set the current search query
  search-next    - Move to the next search match
  search-prev    - Move to the previous search match
  search-first   - Move to the first search match
  search-last    - Move to the last search match
  replace-set    - Set the current replacement text
  replace-one    - Replace the current match once
  replace-all    - Replace all remaining matches
  buffer-list    - List open buffers with titles and modified state
  open-file      - Load a file into the current session
  save-as        - Save the current buffer under a new name
  revert-buffer  - Revert the current buffer from disk
  close-buffer   - Close the current buffer immediately
  batch          - Run a sequence of control commands against one target
  target         - Save, show, list, delete, or use a named target profile
  session        - Alias for target
  scenario       - Run a named batch workflow
  scenario batch-smoke - Run a target-backed low-level smoke workflow
  scenario file-smoke - Run a target-backed file lifecycle workflow
  scenario search-smoke - Run a target-backed search/replace workflow
  scenario history-smoke - Run a target-backed undo/redo workflow
  scenario clipboard-smoke - Run a target-backed clipboard workflow
  traces         - Print the current connect/server trace bundle
  insert-equation - Insert a LaTeX equation
  insert-inline-equation - Insert an inline LaTeX equation
  insert-matrix  - Insert a matrix (rows cols data)
  insert-fraction - Insert a fraction (numerator denominator)
  insert-sqrt    - Insert a square root
  insert-sup     - Insert superscript (sub sup)
  insert-sub     - Insert subscript
  insert-sum     - Insert summation (from to body)
  insert-integral - Insert integral (from to body)
  insert-table   - Insert a table (rows cols)
  insert-bold    - Insert bold text
  insert-italic  - Insert italic text
  insert-code    - Insert code text
  insert-section - Insert a section title
  insert-subsection - Insert a subsection title
  insert-subsubsection - Insert a subsubsection title
  insert-link    - Insert a hyperlink (url text)
  session-evaluate - Evaluate the current session input field
  session-evaluate-all - Evaluate all session inputs in the current session tree
  session-evaluate-above - Evaluate session inputs above the cursor
  session-evaluate-below - Evaluate session inputs at or below the cursor
  session-interrupt - Interrupt the current running session
  session-stop   - Stop the current session process
EOF
}
