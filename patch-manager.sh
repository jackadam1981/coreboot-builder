#!/bin/bash

# 补丁管理脚本
# 用于管理 RTL8111H PXE MAC 地址修复补丁

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo -e "${GREEN}[INFO]${NC} 🔧 RTL8111H PXE MAC 地址修复补丁管理器"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  apply     应用所有补丁"
    echo "  revert    撤销所有补丁"
    echo "  status    检查补丁状态"
    echo "  list      列出所有补丁"
    echo "  help      显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 apply    # 应用所有补丁"
    echo "  $0 status   # 检查补丁状态"
    echo "  $0 revert   # 撤销所有补丁"
}

# 列出所有补丁
list_patches() {
    log_info "📋 可用的补丁列表:"
    echo ""
    echo "1. fix-vpd-parsing-bug.patch"
    echo "   - 修复 VPD 解析 Bug"
    echo "   - 解决 Google VPD 2.0 格式解析问题"
    echo ""
    echo "2. fix-rtl8111h-eri-support.patch"
    echo "   - 添加 RTL8111H ERI 支持"
    echo "   - 支持 revision 12-15 的 ERI 编程"
    echo ""
    echo "3. add-eri-debug-info.patch"
    echo "   - 添加 ERI 调试信息"
    echo "   - 便于问题诊断和调试"
    echo ""
    echo "4. enable-eri-config.patch"
    echo "   - 启用 ERI 配置"
    echo "   - 在主板配置中启用 ERI 功能"
    echo ""
    echo "5. fix-eri-dependency.patch"
    echo "   - 修复 ERI 依赖关系"
    echo "   - 确保正确的配置依赖"
    echo ""
    echo "6. update-kaisa-config.patch"
    echo "   - 更新 Kaisa 配置文件"
    echo "   - 包含完整的 Kaisa 主板配置"
    echo "   - 支持 PXE 网络引导和 RTL8168 驱动"
    echo ""
}

# 主函数
main() {
    case "${1:-help}" in
        "apply")
            log_info "🔧 应用所有补丁..."
            ./apply-patches.sh
            ;;
        "revert")
            log_info "🔄 撤销所有补丁..."
            ./revert-patches.sh
            ;;
        "status")
            log_info "🔍 检查补丁状态..."
            ./check-patch-status.sh
            ;;
        "list")
            list_patches
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "❌ 未知选项: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
