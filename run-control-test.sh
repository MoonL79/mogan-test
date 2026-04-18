#!/bin/bash
# 启动 mogan 服务器并执行测试

set -e

# 环境变量
export TEXMACS_PATH=/home/mingshen/git/mogan/TeXmacs
MOGAN_ROOT=/home/mingshen/git/mogan
MOGAN_TEST_ROOT=/home/mingshen/git/mogan-test
SERVER_RUNTIME="$MOGAN_TEST_ROOT/src/cli/runtime/mogan-server-runtime.scm"
CLIENT_RUNTIME="$MOGAN_TEST_ROOT/src/cli/runtime/client.scm"
MOGANSTEM="$MOGAN_ROOT/build/linux/x86_64/debug/moganstem"

# 启动服务器
echo "Starting mogan server..."
cd "$MOGAN_ROOT"
"$MOGANSTEM" -d -debug-bench -server -x "(load \"$SERVER_RUNTIME\")" > /tmp/mogan-server.log 2>&1 &
SERVER_PID=$!
echo "Server PID: $SERVER_PID"

# 等待服务器启动
sleep 3

# 检查服务器是否运行
if ! ps -p $SERVER_PID > /dev/null 2>&1; then
    echo "Server failed to start"
    cat /tmp/mogan-server.log
    exit 1
fi

echo "Server started successfully"

# 创建账户
echo "Creating test account..."
cd "$MOGAN_TEST_ROOT"
timeout 15 ./bin/mogan-cli create-account || echo "Account creation result: $?"

# 测试连接
echo "Testing connection..."
timeout 15 ./bin/mogan-cli connect || echo "Connect result: $?"

# 执行实际控制命令
echo "Running control commands..."
timeout 15 ./bin/mogan-cli new-document || echo "new-document result: $?"
timeout 15 ./bin/mogan-cli write-text "Hello from mogan-test controller!" || echo "write-text result: $?"
timeout 15 ./bin/mogan-cli buffer-text || echo "buffer-text result: $?"
timeout 15 ./bin/mogan-cli state || echo "state result: $?"

# 停止服务器
echo "Stopping server..."
kill $SERVER_PID 2>/dev/null || true

echo "Done!"