#!/bin/bash

# 快速测试 MAC 地址问题
# Quick Test Script for MAC Address Issues

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "🚀 快速测试 MAC 地址问题"
echo ""

# 检查是否有已编译的 ROM
if [ ! -f "roms/coreboot.rom" ]; then
    log_info "📦 未找到已编译的 ROM，开始快速编译..."
    
    # 检查 coreboot 目录
    if [ ! -d "coreboot" ]; then
        log_info "📦 克隆 MrChromebox coreboot..."
        git clone https://github.com/MrChromebox/coreboot.git
    fi
    
    cd coreboot
    
    # 快速配置
    log_info "🔧 快速配置..."
    cfg_file=$(find ./configs -name 'config.kaisa.uefi')
    cp "$cfg_file" .config
    
    # 添加关键配置
    echo "" >> .config
    echo "# 快速测试配置" >> .config
    echo "CONFIG_EDK2_NETWORK_PXE_SUPPORT=y" >> .config
    echo "CONFIG_EDK2_LOAD_OPTION_ROMS=y" >> .config
    echo "CONFIG_RT8168_PUT_MAC_TO_ERI=y" >> .config
    echo "CONFIG_EDK2_CUSTOM_BUILD_PARAMS=\"-D NETWORK_DRIVER_ENABLE=TRUE -D NETWORK_ENABLE=TRUE -D NETWORK_IP4_ENABLE=TRUE -D NETWORK_PXE_BOOT_ENABLE=TRUE -D NETWORK_SNP_ENABLE=TRUE -D NETWORK_RTEK_PCI=TRUE\"" >> .config
    
    # 修改 RTL8168 驱动
    log_info "🔧 修改 RTL8168 驱动支持 RTL8111H..."
    if [ -f "src/drivers/net/r8168.c" ]; then
        # 简单的 sed 替换
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
			outl(maclo, io_base + ERIDR);\
			inl(io_base + ERIDR);\
			outl(0x8000f0e0, io_base + ERIAR);\
			inl(io_base + ERIAR);\
			outl(machi, io_base + ERIDR);\
			inl(io_base + ERIDR);\
			outl(0x800030e4, io_base + ERIAR);\
			break;' src/drivers/net/r8168.c
        log_info "✅ RTL8168 驱动已修改"
    fi
    
    # 快速编译
    log_info "🔨 开始快速编译..."
    make clean
    make olddefconfig
    make -j$(nproc)
    
    # 复制 ROM
    mkdir -p ../roms
    cp build/coreboot.rom ../roms/coreboot.rom
    cd ..
    
    log_info "✅ 快速编译完成"
else
    log_info "📦 使用已存在的 ROM 文件"
fi

# 测试 MAC 地址注入
log_info "🔧 测试 MAC 地址注入..."

# 创建测试 MAC 地址
TEST_MAC="c0:18:50:8c:be:6c"
echo -n "$TEST_MAC" > rt8168-macaddress.bin

# 注入到 ROM
if command -v cbfstool >/dev/null 2>&1; then
    # 移除现有条目
    cbfstool roms/coreboot.rom remove -n rt8168-macaddress 2>/dev/null || true
    
    # 添加新条目
    if cbfstool roms/coreboot.rom add -f rt8168-macaddress.bin -n rt8168-macaddress -t raw; then
        log_info "✅ MAC 地址已注入到 ROM"
        
        # 验证注入
        if cbfstool roms/coreboot.rom extract -n rt8168-macaddress -f rt8168-macaddress-verify.bin 2>/dev/null; then
            VERIFIED_MAC=$(cat rt8168-macaddress-verify.bin)
            if [ "$VERIFIED_MAC" = "$TEST_MAC" ]; then
                log_info "✅ MAC 地址验证成功: $VERIFIED_MAC"
            else
                log_warn "⚠️ MAC 地址验证失败: 期望 $TEST_MAC，实际 $VERIFIED_MAC"
            fi
            rm -f rt8168-macaddress-verify.bin
        else
            log_warn "⚠️ 无法验证 MAC 地址"
        fi
    else
        log_error "❌ MAC 地址注入失败"
    fi
    
    # 显示 CBFS 内容
    log_info "🔍 CBFS 内容:"
    cbfstool roms/coreboot.rom print | grep -E "(rt8168|macaddress)" || echo "未找到相关条目"
    
else
    log_warn "⚠️ cbfstool 未安装，无法测试 MAC 地址注入"
fi

# 清理临时文件
rm -f rt8168-macaddress.bin

log_info "🎉 快速测试完成！"
log_info "📁 ROM 文件: roms/coreboot.rom"
log_info "💡 可以使用 flash-coreboot-intel.sh 脚本刷入测试"
