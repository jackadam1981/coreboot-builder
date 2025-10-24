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
if [ $# -lt 1 ]; then
    echo "用法 / Usage: sudo $0 <coreboot.rom> [--use-ready]"
    echo ""
    echo "示例 / Examples:"
    echo "  sudo $0 coreboot_edk2-kaisa-mrchromebox_20251001.rom"
    echo "  sudo $0 --use-ready                # 使用最新的处理好的ROM"
    echo "  sudo $0 ready_A1B2C3D4E5F6_20251001_120000.rom  # 使用指定的处理好的ROM"
    exit 1
fi

CUSTOM_ROM="$1"
USE_READY_ROM=false

# 检查是否使用已处理的ROM
if [ "$CUSTOM_ROM" = "--use-ready" ]; then
    USE_READY_ROM=true
    CUSTOM_ROM=""
elif [ -f "$CUSTOM_ROM" ]; then
    # 获取ROM文件的绝对路径
    CUSTOM_ROM=$(realpath "$CUSTOM_ROM")
else
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
READY_DIR="${DEVICE_DIR}/ready_roms"  # 存放处理好的ROM文件

mkdir -p "$WORK_DIR"
mkdir -p "$READY_DIR"

# 如果使用已处理的ROM
if [ "$USE_READY_ROM" = true ]; then
    # 查找最新的ready ROM
    LATEST_READY=$(ls -t "$READY_DIR"/ready_${MAC_ADDR}_*.rom 2>/dev/null | head -1)
    if [ -z "$LATEST_READY" ]; then
        log_error "未找到此设备的已处理ROM / No ready ROM found for this device"
        log_error "请先使用原始ROM进行首次刷写"
        exit 1
    fi
    # 使用绝对路径，避免工作目录切换后路径失效
    CUSTOM_ROM="$(realpath "$LATEST_READY")"
    log_info "使用已处理的ROM / Using ready ROM: $CUSTOM_ROM"
fi

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

# 判断是使用已处理的ROM还是处理新ROM
if [ "$USE_READY_ROM" = true ]; then
    # ========================================
    # 使用已处理的ROM（快速刷写模式）
    # ========================================
    log_info "🚀 快速刷写模式：使用已处理的ROM"
    log_info "跳过备份和VPD/HWID处理步骤"
    echo ""
    
    # 直接复制ready ROM
    cp "$CUSTOM_ROM" ./coreboot.rom
    log_info "已准备ROM: $(basename $CUSTOM_ROM)"
else
    # ========================================
    # 完整处理流程
    # ========================================
    
    # 步骤 2: 备份当前固件
    BACKUP_FILE="backup_${TIMESTAMP}.rom"
    
    log_info "步骤 2/6: 备份当前固件 / Step 2/6: Backing up current firmware"
    log_info "设备目录 / Device directory: $DEVICE_DIR"
    log_warn "此步骤可能需要几分钟，请耐心等待 / This may take a few minutes, please wait"
    
    "$TOOLS_DIR/flashrom" -p internal -r "$BACKUP_FILE" --ifd -i bios
    log_info "备份完成: $BACKUP_FILE"
    
    echo ""
    
    # 步骤 3: 提取 VPD
    log_info "步骤 3/6: 从备份中提取 VPD / Step 3/6: Extracting VPD from backup"
    
    "$TOOLS_DIR/cbfstool" "$BACKUP_FILE" read -r RO_VPD -f vpd.bin
    if [ -f "vpd.bin" ]; then
        log_info "VPD 提取完成: vpd.bin"
    else
        log_error "VPD 提取失败"
        exit 1
    fi
    
    echo ""
    
    # 步骤 4: 准备自定义 ROM
    log_info "步骤 4/6: 准备自定义 ROM / Step 4/6: Preparing custom ROM"
    
    # 复制自定义 ROM 到工作目录
    cp "$CUSTOM_ROM" ./coreboot.rom
    
    # 校验固件完整性 (在修改之前校验)
    log_info "校验原始固件完整性 / Verifying original firmware integrity"
    SHA1_FILE="${CUSTOM_ROM}.sha1"
    if [ -f "$SHA1_FILE" ]; then
        log_info "找到SHA1校验文件: $(basename $SHA1_FILE)"
        
        CALCULATED_SHA1=$(sha1sum coreboot.rom | awk '{print $1}')
        EXPECTED_SHA1=$(cat "$SHA1_FILE" | awk '{print $1}')
        
        if [ "$CALCULATED_SHA1" = "$EXPECTED_SHA1" ]; then
            log_info "✅ SHA1 校验通过 / SHA1 verification passed"
        else
            log_error "❌ SHA1 校验失败！/ SHA1 verification failed!"
            log_error "   预期值 Expected: $EXPECTED_SHA1"
            log_error "   实际值 Actual: $CALCULATED_SHA1"
            log_error "   固件文件可能已损坏或被篡改，刷写中止！"
            exit 1
        fi
    else
        log_warn "⚠️  未找到SHA1校验文件，跳过校验"
    fi
    echo ""
    
    # 注入 VPD
    log_info "注入 VPD 到自定义 ROM..."
    "$TOOLS_DIR/cbfstool" coreboot.rom write -r RO_VPD -f vpd.bin
    log_info "VPD 注入完成"
    
    # 步骤 4.5: 写入 MAC 地址到 rt8168-macaddress CBFS 条目
    log_info "步骤 4.5/6: 写入 MAC 地址到 CBFS / Step 4.5/6: Writing MAC address to CBFS"
    
    # 注入 MAC 地址前：列出固件详细信息
    log_info "注入 MAC 地址前的固件 CBFS 内容："
    log_info "=========================================="
    "$TOOLS_DIR/cbfstool" coreboot.rom print
    log_info "=========================================="
    echo ""

    # 优先从 VPD 中提取 MAC 地址
    MAC_FROM_VPD=$(strings vpd.bin | grep -E "^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$" | head -1)
    if [ -z "$MAC_FROM_VPD" ]; then
        MAC_FROM_VPD=$(strings vpd.bin | grep -E "[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}" | head -1)
    fi

    TARGET_MAC=""
    if [ -n "$MAC_FROM_VPD" ]; then
        TARGET_MAC="$MAC_FROM_VPD"
        log_info "从 VPD 中提取到 MAC 地址: $TARGET_MAC"
    else
        # 回退：从系统网卡读取（排除无效地址）
        SYS_MAC=$(ip link show | grep -A1 "state UP" | grep "link/ether" | head -1 | awk '{print $2}')
        if echo "$SYS_MAC" | grep -qiE "^[0-9a-f]{2}(:[0-9a-f]{2}){5}$"; then
            TARGET_MAC=$(echo "$SYS_MAC" | tr '[:lower:]' '[:upper:]')
            log_info "从系统接口获取到 MAC 地址: $TARGET_MAC"
        fi
    fi

    # 可选：若存在外部覆盖文件，则优先生效（内容需为 AA:BB:CC:DD:EE:FF）
    if [ -f "$SCRIPT_DIR/rt8168-macaddress.txt" ]; then
        OVERRIDE_MAC=$(tr -d '\r\n' < "$SCRIPT_DIR/rt8168-macaddress.txt")
        if echo "$OVERRIDE_MAC" | grep -qiE "^[0-9a-f]{2}(:[0-9a-f]{2}){5}$"; then
            TARGET_MAC=$(echo "$OVERRIDE_MAC" | tr '[:lower:]' '[:upper:]')
            log_info "使用外部覆盖 MAC 地址: $TARGET_MAC"
        else
            log_warn "覆盖文件格式不正确，忽略: $OVERRIDE_MAC"
        fi
    fi

    if [ -n "$TARGET_MAC" ]; then
        # 写入临时文件（驱动期望为文本形式）
        echo -n "$TARGET_MAC" > rt8168-macaddress.bin

        # 先移除旧条目（忽略失败），再添加新条目
        "$TOOLS_DIR/cbfstool" coreboot.rom remove -n rt8168-macaddress 2>/dev/null || true
        "$TOOLS_DIR/cbfstool" coreboot.rom add -f rt8168-macaddress.bin -n rt8168-macaddress -t raw

        # 双重校验：提取对比 + 列表检查
        if "$TOOLS_DIR/cbfstool" coreboot.rom extract -n rt8168-macaddress -f rt8168-macaddress-verify.bin 2>/dev/null; then
            VERIFIED_MAC=$(cat rt8168-macaddress-verify.bin)
            rm -f rt8168-macaddress-verify.bin
            if [ "$VERIFIED_MAC" != "$TARGET_MAC" ]; then
                log_error "MAC 校验失败：期望 $TARGET_MAC，实际 $VERIFIED_MAC"
                exit 1
            fi
        else
            log_error "无法提取 rt8168-macaddress 进行校验"
            exit 1
        fi

        # 确认 CBFS 列表中存在且大小>0
        if ! "$TOOLS_DIR/cbfstool" coreboot.rom print | grep -E "rt8168-macaddress" >/dev/null; then
            log_error "CBFS 中未找到 rt8168-macaddress 条目"
            exit 1
        fi

        log_info "✅ MAC 地址已写入并通过校验: $TARGET_MAC"
        
        # 注入 MAC 地址后：再次列出固件详细信息进行对比
        log_info "注入 MAC 地址后的固件 CBFS 内容："
        log_info "=========================================="
        "$TOOLS_DIR/cbfstool" coreboot.rom print
        log_info "=========================================="
        echo ""
        
        rm -f rt8168-macaddress.bin
    else
        log_warn "⚠️ 无法获取 MAC 地址（VPD/系统/覆盖文件均无），跳过 CBFS 写入"
    fi
    
    echo ""
    
    # 步骤 5: 提取并注入 HWID
    log_info "步骤 5/6: 提取并注入 HWID / Step 5/6: Extracting and injecting HWID"
    
    # 注入 HWID 前：列出固件详细信息
    log_info "注入 HWID 前的固件 CBFS 内容："
    log_info "=========================================="
    "$TOOLS_DIR/cbfstool" coreboot.rom print
    log_info "=========================================="
    echo ""
    
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
        
        # 先尝试删除现有HWID（如果存在），忽略错误
        "$TOOLS_DIR/cbfstool" coreboot.rom remove -n hwid 2>/dev/null || true
        
        # 添加新的HWID
        "$TOOLS_DIR/cbfstool" coreboot.rom add -n hwid -f hwid.txt -t raw
        log_info "✅ HWID 注入完成"
        
        # 注入 HWID 后：再次列出固件详细信息进行对比
        log_info "注入 HWID 后的固件 CBFS 内容："
        log_info "=========================================="
        "$TOOLS_DIR/cbfstool" coreboot.rom print
        log_info "=========================================="
        echo ""
    else
        log_warn "⚠️  HWID 提取失败或为空，跳过注入"
        log_warn "   某些设备或固件可能不需要HWID"
    fi
    
    echo ""
    
    # 保存处理好的ROM（包含VPD和HWID）
    READY_ROM="ready_${MAC_ADDR}_${TIMESTAMP}.rom"
    READY_ROM_PATH="../ready_roms/$READY_ROM"
    cp coreboot.rom "$READY_ROM_PATH"
    log_info "✅ 已保存处理好的 ROM: $READY_ROM_PATH"
    log_info "此 ROM 可直接用于刷写，无需重复处理"
    
    echo ""
fi

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
    log_info "处理后ROM位置 / Ready ROM location: $READY_ROM_PATH"
    log_info "设备标识 / Device ID: MAC_$MAC_ADDR"
    echo ""
    log_info "💡 提示：处理后的ROM已包含此设备专属的VPD和HWID"
    log_info "   - 可用于此设备的重复刷写（无需重新处理）"
    log_info "   - ⚠️ 不能用于其他设备，即使是相同型号"
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

