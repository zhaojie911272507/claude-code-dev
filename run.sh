#!/bin/bash

# Claude Code 一键安装启动脚本
# 支持: macOS, Linux, Windows (WSL/Git Bash)

set -e

# ===== 配置 =====
PROJECT_NAME="claude-code"
CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude-dev}"
CLAUDE_CACHE_DIR="${CLAUDE_CACHE_DIR:-$HOME/.cache/claude-dev}"
BUN_INSTALL_URL="https://bun.sh/install"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macos";;
        Linux*)    echo "linux";;
        MINGW*|MSYS*|CYGWIN*) echo "windows";;
        *)         echo "unknown";;
    esac
}

# 检测是否已安装 Bun
check_bun() {
    if command -v bun &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 安装 Bun
install_bun() {
    log_info "正在安装 Bun..."
    
    local os=$(detect_os)
    
    case "$os" in
        macos|linux)
            curl -fsSL "$BUN_INSTALL_URL" | bash
            # 添加到当前 shell
            export BUN_INSTALL="$HOME/.bun"
            export PATH="$BUN_INSTALL/bin:$PATH"
            ;;
        windows)
            log_warn "Windows 检测到，请使用 PowerShell 运行:"
            echo "  irm bun.sh | iex"
            exit 1
            ;;
        *)
            log_error "不支持的操作系统"
            exit 1
            ;;
    esac
    
    log_info "Bun 安装完成"
}

# 验证 Bun
verify_bun() {
    if ! check_bun; then
        install_bun
    fi
    
    local bun_version
    bun_version=$(bun --version 2>/dev/null || echo "unknown")
    log_info "Bun 版本: $bun_version"
}

# 安装项目依赖
install_deps() {
    log_info "正在安装项目依赖..."
    
    if [ ! -f "package.json" ]; then
        log_error "package.json 不存在，请确保在项目根目录运行"
        exit 1
    fi
    
    bun install
    log_info "依赖安装完成"
}

# 创建配置目录
setup_config() {
    log_info "配置隔离目录: $CLAUDE_CONFIG_DIR"
    mkdir -p "$CLAUDE_CONFIG_DIR"
    mkdir -p "$CLAUDE_CACHE_DIR"
}

# 启动 Claude Code
start_claude() {
    log_info "正在启动 Claude Code..."
    log_info "配置文件: $CLAUDE_CONFIG_DIR"
    log_info "缓存目录: $CLAUDE_CACHE_DIR"
    
    export CLAUDE_CONFIG_DIR
    export CLAUDE_CACHE_DIR
    
    # 传递所有参数
    bun run src/main.tsx "$@"
}

# 主流程
main() {
    local os=$(detect_os)
    
    echo "========================================"
    echo "  Claude Code 一键启动脚本"
    echo "========================================"
    echo ""
    log_info "检测操作系统: $os"
    
    # 步骤 1: 验证/安装 Bun
    verify_bun
    
    # 步骤 2: 安装依赖
    install_deps
    
    # 步骤 3: 配置隔离
    setup_config
    
    # 步骤 4: 启动
    start_claude "$@"
}

# 显示帮助
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help           显示帮助"
    echo "  --no-install         跳过 Bun 安装"
    echo "  --config-dir <path>  自定义配置目录"
    echo "  --cache-dir <path>   自定义缓存目录"
    echo ""
    echo "示例:"
    echo "  $0                          # 默认启动"
    echo "  $0 --config-dir ~/.claude-dev  # 自定义配置目录"
    echo "  ./run.sh --help             # 查看帮助"
}

# 解析参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --no-install)
                SKIP_BUN_INSTALL=1
                shift
                ;;
            --config-dir)
                CLAUDE_CONFIG_DIR="$2"
                shift 2
                ;;
            --cache-dir)
                CLAUDE_CACHE_DIR="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done
}

# ===== 入口 =====
parse_args "$@"

if [ -z "$SKIP_BUN_INSTALL" ]; then
    main "$@"
else
    verify_bun
    install_deps
    setup_config
    start_claude "$@"
fi