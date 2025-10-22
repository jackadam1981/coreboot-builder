#!/bin/bash

# MAC 地址调试脚本（在开发机器上运行）
# Debug Script for MAC Address Issues (Run on development machine)

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
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

log_info "🔍 MAC 地址调试脚本"
echo ""

# 检查当前系统 MAC 地址
log_info "📋 检查当前系统 MAC 地址："
ip link show | grep -A 1 "state UP" | grep "link/ether" || echo "未找到活跃网络接口"
echo ""

# 检查 RTL8168 驱动配置
if [ -f "coreboot/src/drivers/net/r8168.c" ]; then
    log_info "🔍 检查 RTL8168 驱动配置："
    
    # 检查 RTL8111H 支持
    if grep -q "RTL8111H support" coreboot/src/drivers/net/r8168.c; then
        log_info "✅ RTL8168 驱动已支持 RTL8111H"
    else
        log_warn "⚠️ RTL8168 驱动未支持 RTL8111H"
    fi
    
    # 检查 ERI 编程逻辑
    if grep -q "case 12:" coreboot/src/drivers/net/r8168.c; then
        log_info "✅ 找到 RTL8111H ERI 编程逻辑"
    else
        log_warn "⚠️ 未找到 RTL8111H ERI 编程逻辑"
    fi
    
    echo ""
fi

# 检查 coreboot 配置
if [ -f "coreboot/.config" ]; then
    log_info "🔍 检查 coreboot 配置："
    
    # 检查 RTL8168 相关配置
    echo "📋 RTL8168 相关配置:"
    grep -i 'rt8168\|mac' coreboot/.config | head -10 || echo "未找到 RTL8168 配置"
    echo ""
    
    # 检查 EDK2 网络配置
    echo "📋 EDK2 网络配置:"
    grep -i 'network\|pxe' coreboot/.config | head -10 || echo "未找到 EDK2 网络配置"
    echo ""
fi

# 检查已编译的 ROM
if [ -f "roms/coreboot.rom" ]; then
    log_info "🔍 检查已编译的 ROM："
    
    # 检查 CBFS 内容
    if command -v cbfstool >/dev/null 2>&1; then
        echo "📋 CBFS 内容（查找 MAC 地址相关条目）:"
        cbfstool roms/coreboot.rom print | grep -E "(rt8168|macaddress|ethernet)" || echo "未找到 MAC 地址相关条目"
        echo ""
        
        # 检查 rt8168-macaddress 条目
        if cbfstool roms/coreboot.rom extract -n rt8168-macaddress -f /tmp/rt8168-macaddress.bin 2>/dev/null; then
            log_info "✅ 找到 rt8168-macaddress CBFS 条目"
            echo "📋 MAC 地址内容:"
            cat /tmp/rt8168-macaddress.bin
            echo ""
            rm -f /tmp/rt8168-macaddress.bin
        else
            log_warn "⚠️ 未找到 rt8168-macaddress CBFS 条目"
        fi
    else
        log_warn "cbfstool 未安装，无法检查 CBFS 内容"
    fi
else
    log_warn "⚠️ 未找到已编译的 ROM 文件"
fi

# 检查 VPD 内容（如果有备份固件）
if [ -f "vpd.bin" ]; then
    log_info "🔍 检查 VPD 内容："
    echo "📋 VPD 中的 MAC 地址:"
    strings vpd.bin | grep -E "[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}" || echo "未找到 MAC 地址"
    echo ""
fi

log_info "🎯 调试完成！"
log_info "💡 如果 MAC 地址仍然是全零，可能的原因："
log_info "   1. RTL8168 驱动未正确支持 RTL8111H"
log_info "   2. ERI 寄存器编程失败"
log_info "   3. EDK2 UNDI 驱动读取时机问题"
log_info "   4. MAC 地址在网卡重置后丢失"
