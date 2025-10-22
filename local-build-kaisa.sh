#!/bin/bash

# Kaisa 本地编译脚本
# Local Build Script for Kaisa with EDK2 PXE Support

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then 
    log_error "请使用 sudo 运行此脚本 / Please run with sudo"
    exit 1
fi

log_info "🚀 开始 Kaisa 本地编译（EDK2 PXE 支持）"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/coreboot"
OUTPUT_DIR="$SCRIPT_DIR/roms"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 检查 coreboot 目录是否存在
if [ ! -d "$BUILD_DIR" ]; then
    log_info "📦 克隆 MrChromebox coreboot 仓库..."
    git clone https://github.com/MrChromebox/coreboot.git "$BUILD_DIR"
    cd "$BUILD_DIR"
    git checkout main
else
    log_info "📦 更新 MrChromebox coreboot 仓库..."
    cd "$BUILD_DIR"
    git pull origin main
fi

log_info "🔧 配置 PXE ROM 支持..."

# 定义配置项数组
PXE_CONFIGS=(
    "CONFIG_EDK2_NETWORK_PXE_SUPPORT=y"
    "CONFIG_EDK2_LOAD_OPTION_ROMS=y"
    "# 启用 ERI 寄存器写入，确保 MAC 地址在网卡重置后保持"
    "CONFIG_RT8168_PUT_MAC_TO_ERI=y"
)

# 构建 EDK2 自定义构建参数
EDK2_BUILD_PARAMS="-D NETWORK_DRIVER_ENABLE=TRUE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_ENABLE=TRUE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_IP4_ENABLE=TRUE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_IP6_ENABLE=FALSE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_PXE_BOOT_ENABLE=TRUE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_HTTP_BOOT_ENABLE=FALSE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_SNP_ENABLE=TRUE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_RTEK_PCI=TRUE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_TLS_ENABLE=FALSE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_ISCSI_ENABLE=FALSE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_RTEK_USB=FALSE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_ASIX_USB3=FALSE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_ASIX_USB2=FALSE"

INTEL_CONFIGS=(
    "CONFIG_SOC_INTEL_COMMON_BLOCK_POWER_LIMIT=y"
    "CONFIG_SOC_INTEL_COMMON_BLOCK_THERMAL=y"
    "CONFIG_SOUTHBRIDGE_INTEL_COMMON_WATCHDOG=y"
    "CONFIG_EC_GOOGLE_CHROMEEC_AUTO_FAN_CTRL=y"
)

# 写入 PXE ROM 支持配置
echo "" >> configs/cml/config.kaisa.uefi
echo "# PXE ROM 支持配置" >> configs/cml/config.kaisa.uefi
for config in "${PXE_CONFIGS[@]}"; do
    echo "$config" >> configs/cml/config.kaisa.uefi
done
echo "" >> configs/cml/config.kaisa.uefi

# 写入 EDK2 自定义构建参数
echo "CONFIG_EDK2_CUSTOM_BUILD_PARAMS=\"$EDK2_BUILD_PARAMS\"" >> configs/cml/config.kaisa.uefi
echo "" >> configs/cml/config.kaisa.uefi

# 写入 Intel 芯片组系统稳定配置
echo "# Intel 芯片组系统稳定配置（适合 Kaisa 主板）" >> configs/cml/config.kaisa.uefi
for config in "${INTEL_CONFIGS[@]}"; do
    echo "$config" >> configs/cml/config.kaisa.uefi
done
echo "" >> configs/cml/config.kaisa.uefi

log_info "✅ 配置完成，显示最终配置："
echo "📋 最终配置文件内容:"
echo "===================="
tail -20 configs/cml/config.kaisa.uefi
echo ""

# 修改 RTL8168 驱动支持 RTL8111H
log_info "🔧 修改 RTL8168 驱动支持 RTL8111H..."

RTL8168_DRIVER_PATH='src/drivers/net/r8168.c'
if [ -f "$RTL8168_DRIVER_PATH" ]; then
    log_info "📦 找到 RTL8168 驱动文件: $RTL8168_DRIVER_PATH"
    
    # 检查是否已经修改过
    if grep -q "RTL8111H support" "$RTL8168_DRIVER_PATH"; then
        log_info "✅ RTL8168 驱动已支持 RTL8111H"
    else
        log_info "🔧 正在修改 RTL8168 驱动..."
        
        # 备份原文件
        cp "$RTL8168_DRIVER_PATH" "${RTL8168_DRIVER_PATH}.backup"
        
        # 使用 sed 修改驱动
        sed -i '/case 9:/,/break;/c\
		case 9:\
			outl(maclo, io_base + ERIDR);\
			inl(io_base + ERIDR);\
			outl(0x8000f0e0, io_base + ERIAR);\
			inl(io_base + ERIAR);\
			outl(machi, io_base + ERIDR);\
			inl(io_base + ERIDR);\
			outl(0x800030e4, io_base + ERIAR);\
			break;\
		case 12: /* RTL8111H support */\
		case 13: /* RTL8111H support */\
		case 14: /* RTL8111H support */\
		case 15: /* RTL8111H support */\
		default: /* Support newer RTL8111H variants */\
			/* Use the same ERI programming as revision 9 for RTL8111H */\
			outl(maclo, io_base + ERIDR);\
			inl(io_base + ERIDR);\
			outl(0x8000f0e0, io_base + ERIAR);\
			inl(io_base + ERIAR);\
			outl(machi, io_base + ERIDR);\
			inl(io_base + ERIDR);\
			outl(0x800030e4, io_base + ERIAR);\
			break;' "$RTL8168_DRIVER_PATH"
        
        log_info "✅ RTL8168 驱动已修改支持 RTL8111H"
    fi
else
    log_warn "⚠️ 未找到 RTL8168 驱动文件"
fi

# 开始编译
log_info "🔨 开始编译 coreboot..."

# 准备配置文件
cfg_file=$(find ./configs -name 'config.kaisa.uefi')
cp "$cfg_file" .config
echo 'CONFIG_LOCALVERSION="$(git describe --tags --dirty)"' >> .config

# 清理并配置
make clean
make olddefconfig

# 显示关键配置
log_info "🔍 检查关键配置："
echo "📋 RTL8168 相关配置:"
grep -i 'rt8168\|mac' .config | head -10
echo ""
echo "📋 EDK2 网络配置:"
grep -i 'network\|pxe' .config | head -10
echo ""

# 开始编译
log_info "🔨 开始编译（这可能需要一些时间）..."
make -j$(nproc)

# 检查编译结果
if [ -f "build/coreboot.rom" ]; then
    log_info "✅ 编译成功！"
    
    # 复制 ROM 文件到输出目录
    cp build/coreboot.rom "$OUTPUT_DIR/coreboot.rom"
    chmod 644 "$OUTPUT_DIR/coreboot.rom"
    
    # 显示 ROM 信息
    log_info "📦 ROM 文件信息："
    ls -lh "$OUTPUT_DIR/coreboot.rom"
    
    # 检查 CBFS 内容
    log_info "🔍 检查 CBFS 内容："
    if command -v cbfstool >/dev/null 2>&1; then
        cbfstool "$OUTPUT_DIR/coreboot.rom" print | grep -E "(rt8168|macaddress)" || echo "未找到 MAC 地址相关条目"
    else
        log_warn "cbfstool 未安装，无法检查 CBFS 内容"
    fi
    
    log_info "🎉 编译完成！ROM 文件已保存到: $OUTPUT_DIR/coreboot.rom"
else
    log_error "❌ 编译失败！"
    exit 1
fi

echo ""
log_info "🚀 本地编译完成！"
log_info "📁 ROM 文件位置: $OUTPUT_DIR/coreboot.rom"
log_info "🔧 可以使用 flash-coreboot-intel.sh 脚本刷入固件"
