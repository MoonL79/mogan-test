#!/bin/bash
# mogan-test 实际控制演示脚本
# 使用方式: ./demo-control.sh

set -euo pipefail

# 配置
MOGAN_ROOT="/home/mingshen/git/mogan"
MOGAN_TEST_ROOT="/home/mingshen/git/mogan-test"
TEXMACS_PATH="$MOGAN_ROOT/TeXmacs"
MOGANSTEM="$MOGAN_ROOT/build/linux/x86_64/debug/moganstem"
SERVER_RUNTIME="$MOGAN_TEST_ROOT/src/cli/runtime/mogan-server-runtime.scm"
CLIENT_RUNTIME="$MOGAN_TEST_ROOT/src/cli/runtime/client.scm"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if [[ ! -x "$MOGANSTEM" ]]; then
        log_error "moganstem 未找到或未编译"
        log_info "请先运行: cd $MOGAN_ROOT && xmake b stem"
        exit 1
    fi
    
    if ! command -v gf >/dev/null 2>&1; then
        log_error "Goldfish Scheme (gf) 未安装"
        exit 1
    fi
    
    log_info "依赖检查通过"
}

# 启动服务器
start_server() {
    log_info "启动 Mogan 服务器..."
    
    # 检查是否已有服务器在运行
    if pgrep -f "moganstem -server" > /dev/null; then
        log_warn "服务器已经在运行"
        return 0
    fi
    
    cd "$MOGAN_ROOT"
    export TEXMACS_PATH
    
    # 启动服务器
    "$MOGANSTEM" -d -debug-bench -server \
        -x "(load \"$SERVER_RUNTIME\")" \
        > /tmp/mogan-server.log 2>&1 &
    
    SERVER_PID=$!
    log_info "服务器 PID: $SERVER_PID"
    
    # 等待服务器启动
    log_info "等待服务器启动..."
    for i in {1..30}; do
        if grep -q "Starting event loop" /tmp/mogan-server.log 2>/dev/null; then
            log_info "服务器已就绪"
            return 0
        fi
        sleep 1
    done
    
    log_error "服务器启动超时"
    cat /tmp/mogan-server.log
    exit 1
}

# 停止服务器
stop_server() {
    log_info "停止服务器..."
    pkill -f "moganstem -server" 2>/dev/null || true
    sleep 1
}

# 运行控制命令
run_control_commands() {
    cd "$MOGAN_TEST_ROOT"
    
    log_info "========== 步骤 1: 创建测试账户 =========="
    timeout 15 ./bin/mogan-cli create-account || {
        log_warn "账户创建结果: $? (可能已存在)"
    }
    
    log_info "========== 步骤 2: 连接服务器 =========="
    timeout 15 ./bin/mogan-cli connect || {
        log_error "连接失败"
        return 1
    }
    
    log_info "========== 步骤 3: 创建新文档 =========="
    timeout 15 ./bin/mogan-cli new-document
    
    log_info "========== 步骤 4: 写入文本 =========="
    timeout 15 ./bin/mogan-cli write-text "Hello from mogan-test controller!"
    
    log_info "========== 步骤 5: 读取缓冲区内容 =========="
    timeout 15 ./bin/mogan-cli buffer-text
    
    log_info "========== 步骤 6: 获取完整状态 =========="
    timeout 15 ./bin/mogan-cli state
    
    log_info "========== 步骤 7: 光标移动演示 =========="
    timeout 15 ./bin/mogan-cli move-end
    timeout 15 ./bin/mogan-cli insert-text " [追加内容]"
    timeout 15 ./bin/mogan-cli buffer-text
    
    log_info "========== 步骤 8: 保存文档 =========="
    timeout 15 ./bin/mogan-cli save-as "/tmp/mogan-test-demo.tm"
    
    log_info "========== 步骤 9: 导出为 HTML =========="
    timeout 15 ./bin/mogan-cli export-buffer "/tmp/mogan-test-demo.html"
    
    log_info "========== 所有控制命令执行完成 =========="
}

# 显示可用的控制命令
show_available_commands() {
    echo ""
    log_info "可用的控制命令:"
    echo ""
    echo "  文档操作:"
    echo "    new-document    - 创建新文档"
    echo "    write-text      - 写入文本内容"
    echo "    buffer-text     - 读取缓冲区文本"
    echo "    save-as         - 另存为文件"
    echo "    export-buffer   - 导出为其他格式"
    echo ""
    echo "  光标移动:"
    echo "    move-left/right/up/down"
    echo "    move-start/end"
    echo "    move-to-line <n>"
    echo ""
    echo "  编辑操作:"
    echo "    insert-text     - 插入文本"
    echo "    delete-left/right"
    echo "    undo/redo"
    echo ""
    echo "  样式设置:"
    echo "    set-main-style"
    echo "    set-document-language"
    echo ""
    echo "  批量操作:"
    echo "    batch           - 批量执行命令"
    echo "    scenario        - 运行预定义场景"
    echo ""
}

# 主函数
main() {
    echo "========================================"
    echo "  Mogan 实际控制演示"
    echo "========================================"
    echo ""
    
    check_dependencies
    
    # 确保没有残留的服务器进程
    stop_server
    
    # 启动服务器
    start_server
    
    # 运行控制命令
    run_control_commands
    
    # 显示可用命令
    show_available_commands
    
    # 保持服务器运行以供进一步操作
    log_info "服务器仍在运行，可以继续执行控制命令"
    log_info "使用 ./bin/mogan-cli <command> 执行更多操作"
    log_info "使用 pkill -f 'moganstem -server' 停止服务器"
    
    # 显示 tracer 命令
    echo ""
    log_info "查看运行日志:"
    echo "  ./bin/mogan-cli traces"
}

# 信号处理
cleanup() {
    log_info "清理中..."
    stop_server
}
trap cleanup EXIT

# 运行主函数
main