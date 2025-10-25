#!/bin/bash

# 补丁状态检查脚本
# 用于检查 RTL8111H PXE MAC 地址修复补丁的应用状态

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

# 显示标题
echo -e "${GREEN}[INFO]${NC} 🔍 RTL8111H PXE MAC 地址修复补丁状态检查"
echo -e "${GREEN}[INFO]${NC} 📍 检查所有补丁的应用状态"

# 检查目录
COREBOOT_DIR="coreboot"

if [ ! -d "$COREBOOT_DIR" ]; then
    log_error "❌ coreboot 目录不存在: $COREBOOT_DIR"
    exit 1
fi

# 进入 coreboot 目录
cd "$COREBOOT_DIR"

# 检查函数
check_patch() {
    local description="$1"
    local check_command="$2"
    local success_message="$3"
    local failure_message="$4"
    
    log_info "🔍 检查: $description"
    
    if eval "$check_command"; then
        log_success "✅ $success_message"
        return 0
    else
        log_warning "⚠️ $failure_message"
        return 1
    fi
}

# 检查所有补丁状态
log_info "📦 开始检查补丁状态..."

# 1. 检查 VPD 解析修复
check_patch "VPD 解析修复" \
    "grep -q 'offset += vpd\[offset + 1\] + 2' src/drivers/net/r8168.c" \
    "VPD 解析修复已应用" \
    "VPD 解析修复未应用"

# 2. 检查 RTL8111H ERI 支持
check_patch "RTL8111H ERI 支持" \
    "grep -q 'case 12:' src/drivers/net/r8168.c" \
    "RTL8111H ERI 支持已添加" \
    "RTL8111H ERI 支持未添加"

# 3. 检查 ERI 调试信息
check_patch "ERI 调试信息" \
    "grep -q 'Programming MAC to ERI registers' src/drivers/net/r8168.c" \
    "ERI 调试信息已添加" \
    "ERI 调试信息未添加"

# 4. 检查 ERI 配置启用
check_patch "ERI 配置启用" \
    "grep -q 'select RT8168_PUT_MAC_TO_ERI' src/mainboard/google/puff/Kconfig" \
    "ERI 配置已启用" \
    "ERI 配置未启用"

# 5. 检查 ERI 依赖关系
check_patch "ERI 依赖关系" \
    "grep -q 'depends on REALTEK_8168_RESET' src/drivers/net/Kconfig" \
    "ERI 依赖关系已修复" \
    "ERI 依赖关系未修复"

# 6. 检查 Kaisa 配置更新
check_patch "Kaisa 配置更新" \
    "grep -q 'CONFIG_BOARD_GOOGLE_KAISA=y' configs/cml/config.kaisa.uefi && grep -q 'CONFIG_EDK2_NETWORK_PXE_SUPPORT=y' configs/cml/config.kaisa.uefi && grep -q 'CONFIG_RT8168_PUT_MAC_TO_ERI=y' configs/cml/config.kaisa.uefi" \
    "Kaisa 配置已更新" \
    "Kaisa 配置未更新"

# 统计结果
log_info "📊 补丁状态统计..."

# 计算已应用的补丁数量
applied_count=0
total_count=6

# 重新检查并计数
if grep -q "offset += vpd\[offset + 1\] + 2" src/drivers/net/r8168.c; then ((applied_count++)); fi
if grep -q "case 12:" src/drivers/net/r8168.c; then ((applied_count++)); fi
if grep -q "Programming MAC to ERI registers" src/drivers/net/r8168.c; then ((applied_count++)); fi
if grep -q "select RT8168_PUT_MAC_TO_ERI" src/mainboard/google/puff/Kconfig; then ((applied_count++)); fi
if grep -q "depends on REALTEK_8168_RESET" src/drivers/net/Kconfig; then ((applied_count++)); fi
if grep -q "CONFIG_BOARD_GOOGLE_KAISA=y" configs/cml/config.kaisa.uefi && grep -q "CONFIG_EDK2_NETWORK_PXE_SUPPORT=y" configs/cml/config.kaisa.uefi && grep -q "CONFIG_RT8168_PUT_MAC_TO_ERI=y" configs/cml/config.kaisa.uefi; then ((applied_count++)); fi

# 显示统计结果
log_info "📈 补丁应用状态: $applied_count/$total_count"

if [ $applied_count -eq $total_count ]; then
    log_success "🎉 所有补丁都已正确应用！"
elif [ $applied_count -gt 0 ]; then
    log_warning "⚠️ 部分补丁已应用，建议检查未应用的补丁"
else
    log_warning "⚠️ 没有补丁被应用，建议运行 apply-patches.sh"
fi

# 显示详细信息
log_info "🔍 详细信息:"

echo "  - VPD 解析修复: $(grep -q "offset += vpd\[offset + 1\] + 2" src/drivers/net/r8168.c && echo "✅ 已应用" || echo "❌ 未应用")"
echo "  - RTL8111H ERI 支持: $(grep -q "case 12:" src/drivers/net/r8168.c && echo "✅ 已应用" || echo "❌ 未应用")"
echo "  - ERI 调试信息: $(grep -q "Programming MAC to ERI registers" src/drivers/net/r8168.c && echo "✅ 已应用" || echo "❌ 未应用")"
echo "  - ERI 配置启用: $(grep -q "select RT8168_PUT_MAC_TO_ERI" src/mainboard/google/puff/Kconfig && echo "✅ 已应用" || echo "❌ 未应用")"
echo "  - ERI 依赖关系: $(grep -q "depends on REALTEK_8168_RESET" src/drivers/net/Kconfig && echo "✅ 已应用" || echo "❌ 未应用")"
echo "  - Kaisa 配置更新: $(grep -q "CONFIG_BOARD_GOOGLE_KAISA=y" configs/cml/config.kaisa.uefi && grep -q "CONFIG_EDK2_NETWORK_PXE_SUPPORT=y" configs/cml/config.kaisa.uefi && grep -q "CONFIG_RT8168_PUT_MAC_TO_ERI=y" configs/cml/config.kaisa.uefi && echo "✅ 已应用" || echo "❌ 未应用")"

log_success "🚀 补丁状态检查完成！"
