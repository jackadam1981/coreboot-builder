#!/bin/bash

# Coreboot 固件刷写脚本 (Intel 设备)
# Flash Coreboot Firmware Script (Intel Devices)

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then 
    log_error "请使用 sudo 运行此脚本 / Please run with sudo"
    exit 1
fi

# 检查参数
if [ $# -ne 1 ]; then
    echo "用法 / Usage: sudo $0 <coreboot.rom>"
    echo "示例 / Example: sudo $0 coreboot_edk2-kaisa-mrchromebox_20251001.rom"
    exit 1
fi

CUSTOM_ROM="$1"

# 获取ROM文件的绝对路径
CUSTOM_ROM=$(realpath "$CUSTOM_ROM")

# 检查 ROM 文件是否存在
if [ ! -f "$CUSTOM_ROM" ]; then
    log_error "找不到 ROM 文件 / ROM file not found: $CUSTOM_ROM"
    exit 1
fi

log_info "准备刷写固件 / Preparing to flash firmware: $CUSTOM_ROM"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$SCRIPT_DIR/tools"
mkdir -p "$TOOLS_DIR"

# 获取 MAC 地址作为设备标识
MAC_ADDR=$(ip link show | grep -A 1 "state UP" | grep "link/ether" | head -1 | awk '{print $2}' | tr -d ':' | tr '[:lower:]' '[:upper:]')
if [ -z "$MAC_ADDR" ]; then
    # 如果获取失败，尝试获取第一个非 lo 接口
    MAC_ADDR=$(cat /sys/class/net/*/address 2>/dev/null | grep -v "00:00:00:00:00:00" | head -1 | tr -d ':' | tr '[:lower:]' '[:upper:]')
fi
if [ -z "$MAC_ADDR" ]; then
    MAC_ADDR="UNKNOWN"
fi
log_info "设备 MAC 地址 / Device MAC Address: $MAC_ADDR"

# 创建设备专属目录（基于MAC地址）
DEVICE_DIR="device_${MAC_ADDR}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
WORK_DIR="${DEVICE_DIR}/flash_${TIMESTAMP}"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

log_info "工作目录 / Working directory: $(pwd)"
echo ""

# ========================================
# 步骤 1: 下载工具
# ========================================
log_info "步骤 1/6: 下载必要工具 / Step 1/6: Downloading required tools"
log_info "工具目录 / Tools directory: $TOOLS_DIR"

if [ ! -f "$TOOLS_DIR/flashrom" ]; then
    log_info "下载 flashrom..."
    wget -q --show-progress -O "$TOOLS_DIR/flashrom.tar.gz" https://mrchromebox.tech/files/util/flashrom_ups_libpci37_20240418.tar.gz
    tar -zxf "$TOOLS_DIR/flashrom.tar.gz" -C "$TOOLS_DIR"
    chmod +x "$TOOLS_DIR/flashrom"
    rm -f "$TOOLS_DIR/flashrom.tar.gz"
    log_info "flashrom 下载完成"
else
    log_info "flashrom 已存在，跳过下载"
fi

if [ ! -f "$TOOLS_DIR/cbfstool" ]; then
    log_info "下载 cbfstool..."
    wget -q --show-progress -O "$TOOLS_DIR/cbfstool.tar.gz" https://mrchromebox.tech/files/util/cbfstool.tar.gz
    tar -zxf "$TOOLS_DIR/cbfstool.tar.gz" -C "$TOOLS_DIR"
    chmod +x "$TOOLS_DIR/cbfstool"
    rm -f "$TOOLS_DIR/cbfstool.tar.gz"
    log_info "cbfstool 下载完成"
else
    log_info "cbfstool 已存在，跳过下载"
fi

if [ ! -f "$TOOLS_DIR/gbb_utility" ]; then
    log_info "下载 gbb_utility..."
    wget -q --show-progress -O "$TOOLS_DIR/gbb_utility.tar.gz" https://mrchromebox.tech/files/util/gbb_utility.tar.gz
    tar -zxf "$TOOLS_DIR/gbb_utility.tar.gz" -C "$TOOLS_DIR"
    chmod +x "$TOOLS_DIR/gbb_utility"
    rm -f "$TOOLS_DIR/gbb_utility.tar.gz"
    log_info "gbb_utility 下载完成"
else
    log_info "gbb_utility 已存在，跳过下载"
fi

echo ""

# ========================================
# 步骤 2: 备份当前固件
# ========================================
BACKUP_FILE="backup_${TIMESTAMP}.rom"

log_info "步骤 2/6: 备份当前固件 / Step 2/6: Backing up current firmware"
log_info "设备目录 / Device directory: $DEVICE_DIR"
log_warn "此步骤可能需要几分钟，请耐心等待 / This may take a few minutes, please wait"

"$TOOLS_DIR/flashrom" -p internal -r "$BACKUP_FILE" --ifd -i bios
log_info "备份完成: $BACKUP_FILE"

echo ""

# ========================================
# 步骤 3: 提取 VPD
# ========================================
log_info "步骤 3/6: 从备份中提取 VPD / Step 3/6: Extracting VPD from backup"

"$TOOLS_DIR/cbfstool" "$BACKUP_FILE" read -r RO_VPD -f vpd.bin
if [ -f "vpd.bin" ]; then
    log_info "VPD 提取完成: vpd.bin"
else
    log_error "VPD 提取失败"
    exit 1
fi

echo ""

# ========================================
# 步骤 4: 准备自定义 ROM
# ========================================
log_info "步骤 4/6: 准备自定义 ROM / Step 4/6: Preparing custom ROM"

# 复制自定义 ROM 到工作目录
cp "$CUSTOM_ROM" ./coreboot.rom

# 注入 VPD
log_info "注入 VPD 到自定义 ROM..."
"$TOOLS_DIR/cbfstool" coreboot.rom write -r RO_VPD -f vpd.bin
log_info "VPD 注入完成"

echo ""

# ========================================
# 步骤 5: 提取并注入 HWID
# ========================================
log_info "步骤 5/6: 提取并注入 HWID / Step 5/6: Extracting and injecting HWID"

# 尝试从固件实用程序脚本的固件中提取
if "$TOOLS_DIR/cbfstool" "$BACKUP_FILE" extract -n hwid -f hwid.txt 2>/dev/null; then
    log_info "从固件实用程序脚本固件中提取 HWID"
else
    # 从库存固件中提取
    log_info "从库存固件中提取 HWID"
    "$TOOLS_DIR/gbb_utility" "$BACKUP_FILE" --get --hwid > hwid.txt
fi

if [ -f "hwid.txt" ] && [ -s "hwid.txt" ]; then
    log_info "HWID: $(cat hwid.txt)"
    "$TOOLS_DIR/cbfstool" coreboot.rom add -n hwid -f hwid.txt -t raw 2>/dev/null || \
    "$TOOLS_DIR/cbfstool" coreboot.rom remove -n hwid 2>/dev/null && \
    "$TOOLS_DIR/cbfstool" coreboot.rom add -n hwid -f hwid.txt -t raw
    log_info "HWID 注入完成"
else
    log_warn "HWID 提取失败或为空，跳过注入（某些设备可能不需要）"
fi

echo ""

# ========================================
# 步骤 6: 刷写固件
# ========================================
log_info "步骤 6/6: 刷写自定义固件 / Step 6/6: Flashing custom firmware"
log_warn "⚠️  警告：即将刷写固件，请勿中断电源！"
log_warn "⚠️  WARNING: About to flash firmware, DO NOT interrupt power!"
echo ""

read -p "确认刷写固件？(yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    log_warn "用户取消操作"
    exit 0
fi

log_info "开始刷写固件（Intel 设备）..."
"$TOOLS_DIR/flashrom" -p internal --ifd -i bios -w coreboot.rom -N

if [ $? -eq 0 ]; then
    echo ""
    log_info "=========================================="
    log_info "✅ 固件刷写成功！/ Firmware flashed successfully!"
    log_info "=========================================="
    log_info "备份文件位置 / Backup location: $(pwd)/$BACKUP_FILE"
    log_info "设备标识 / Device ID: MAC_$MAC_ADDR"
    log_info "请妥善保存备份文件以备不时之需"
    echo ""
    log_info "请重新启动计算机 / Please reboot your computer"
    echo ""
    read -p "是否立即重启？(yes/no): " -r
    echo
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "正在重启..."
        sleep 2
        reboot
    fi
else
    log_error "固件刷写失败！/ Firmware flash failed!"
    log_error "请检查错误信息并重试"
    exit 1
fi

