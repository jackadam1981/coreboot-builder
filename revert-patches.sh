#!/bin/bash

# 补丁撤销脚本
# 用于撤销 RTL8111H PXE MAC 地址修复补丁

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
echo -e "${GREEN}[INFO]${NC} 🔄 RTL8111H PXE MAC 地址修复补丁撤销脚本"
echo -e "${GREEN}[INFO]${NC} 📍 撤销所有应用的补丁，恢复到原始状态"

# 检查参数
PATCH_DIR="patches"
COREBOOT_DIR="coreboot"

# 检查目录
if [ ! -d "$PATCH_DIR" ]; then
    log_error "❌ 补丁目录不存在: $PATCH_DIR"
    exit 1
fi

if [ ! -d "$COREBOOT_DIR" ]; then
    log_error "❌ coreboot 目录不存在: $COREBOOT_DIR"
    exit 1
fi

# 进入 coreboot 目录
cd "$COREBOOT_DIR"

# 撤销补丁函数
revert_patch() {
    local patch_file="../$PATCH_DIR/$1"
    local description="$2"
    
    if [ ! -f "$patch_file" ]; then
        log_error "❌ 补丁文件不存在: $patch_file"
        return 1
    fi
    
    log_info "🔄 撤销补丁: $description"
    
    if patch -p1 -R < "$patch_file"; then
        log_success "✅ 补丁撤销成功: $description"
        return 0
    else
        log_warning "⚠️ 补丁撤销失败或未应用: $description"
        return 1
    fi
}

# 撤销所有补丁（逆序）
log_info "📦 开始撤销补丁..."

# 6. 撤销 Kaisa 配置更新
revert_patch "update-kaisa-config.patch" "撤销 Kaisa 配置更新"

# 5. 撤销 ERI 依赖修复
revert_patch "fix-eri-dependency.patch" "撤销 ERI 依赖关系修复"

# 4. 撤销 ERI 配置启用
revert_patch "enable-eri-config.patch" "撤销 ERI 配置启用"

# 3. 撤销 ERI 调试信息
revert_patch "add-eri-debug-info.patch" "撤销 ERI 调试信息"

# 2. 撤销 RTL8111H ERI 支持
revert_patch "fix-rtl8111h-eri-support.patch" "撤销 RTL8111H ERI 支持"

# 1. 撤销 VPD 解析修复
revert_patch "fix-vpd-parsing-bug.patch" "撤销 VPD 解析修复"

log_success "🎉 所有补丁撤销完成！"

# 验证撤销结果
log_info "🔍 验证撤销结果..."

# 检查关键文件是否已恢复
if ! grep -q "case 12:" src/drivers/net/r8168.c; then
    log_success "✅ RTL8111H ERI 支持已撤销"
else
    log_warning "⚠️ RTL8111H ERI 支持可能未完全撤销"
fi

if ! grep -q "select RT8168_PUT_MAC_TO_ERI" src/mainboard/google/puff/Kconfig; then
    log_success "✅ ERI 配置已撤销"
else
    log_warning "⚠️ ERI 配置可能未完全撤销"
fi

if ! grep -q "depends on REALTEK_8168_RESET" src/drivers/net/Kconfig; then
    log_success "✅ ERI 依赖关系已撤销"
else
    log_warning "⚠️ ERI 依赖关系可能未完全撤销"
fi

if ! grep -q "CONFIG_RT8168_PUT_MAC_TO_ERI=y" configs/cml/config.kaisa.uefi; then
    log_success "✅ Kaisa 配置已撤销"
else
    log_warning "⚠️ Kaisa 配置可能未完全撤销"
fi

log_success "🚀 补丁撤销完成！代码已恢复到原始状态。"
