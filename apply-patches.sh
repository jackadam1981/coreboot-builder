#!/bin/bash

# 补丁应用脚本
# 用于应用 RTL8111H PXE MAC 地址修复补丁

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
echo -e "${GREEN}[INFO]${NC} 🔧 RTL8111H PXE MAC 地址修复补丁应用脚本"
echo -e "${GREEN}[INFO]${NC} 📍 应用多个补丁解决 RTL8111H 芯片问题"

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

# 应用补丁函数
apply_patch() {
    local patch_file="../$PATCH_DIR/$1"
    local description="$2"
    
    if [ ! -f "$patch_file" ]; then
        log_error "❌ 补丁文件不存在: $patch_file"
        return 1
    fi
    
    log_info "🔧 应用补丁: $description"
    
    if patch -p1 < "$patch_file"; then
        log_success "✅ 补丁应用成功: $description"
        return 0
    else
        log_warning "⚠️ 补丁应用失败或已存在: $description"
        return 1
    fi
}

# 应用所有补丁
log_info "📦 开始应用补丁..."

# 1. RTL8168 驱动修复（VPD解析、RTL8111H支持、调试信息）
apply_patch "r8168-driver-fixes.patch" "RTL8168 驱动修复（VPD解析、RTL8111H支持、调试信息）"

# 2. 启用 ERI 配置
apply_patch "eri-config-enable.patch" "启用 ERI 配置"

# 3. 修复 ERI 依赖
apply_patch "eri-dependency-fix.patch" "修复 ERI 依赖关系"

# 4. 更新 Kaisa 配置
apply_patch "kaisa-config-update.patch" "更新 Kaisa 主板配置"

log_success "🎉 所有补丁应用完成！"

# 验证补丁应用结果
log_info "🔍 验证补丁应用结果..."

# 检查关键文件是否被修改
if grep -q "case 12:" src/drivers/net/r8168.c; then
    log_success "✅ RTL8111H ERI 支持已添加"
else
    log_warning "⚠️ RTL8111H ERI 支持可能未正确添加"
fi

if grep -q "select RT8168_PUT_MAC_TO_ERI" src/mainboard/google/puff/Kconfig; then
    log_success "✅ ERI 配置已启用"
else
    log_warning "⚠️ ERI 配置可能未正确启用"
fi

if grep -q "depends on REALTEK_8168_RESET" src/drivers/net/Kconfig; then
    log_success "✅ ERI 依赖关系已修复"
else
    log_warning "⚠️ ERI 依赖关系可能未正确修复"
fi

if grep -q "CONFIG_RT8168_PUT_MAC_TO_ERI=y" configs/cml/config.kaisa.uefi; then
    log_success "✅ Kaisa 配置已更新"
else
    log_warning "⚠️ Kaisa 配置可能未正确更新"
fi

log_success "🚀 补丁应用完成！现在可以编译固件了。"
