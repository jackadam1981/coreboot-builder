#!/bin/bash

# RTL8168 驱动修改验证脚本
# 用于验证 RTL8111H 支持是否正确编译到 ROM 中

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

# 检查文件是否存在
check_file() {
    if [ ! -f "$1" ]; then
        log_error "文件不存在: $1"
        return 1
    fi
    return 0
}

# 验证配置
verify_config() {
    log_info "🔍 验证构建配置..."
    
    # 检查 .config 文件
    CONFIG_FILE="coreboot/.config"
    if check_file "$CONFIG_FILE"; then
        echo "📁 配置文件: $CONFIG_FILE"
        
        # 检查 REALTEK_8168_RESET 配置
        if grep -q "CONFIG_REALTEK_8168_RESET=y" "$CONFIG_FILE"; then
            log_success "✅ CONFIG_REALTEK_8168_RESET=y (驱动编译已启用)"
        else
            log_error "❌ CONFIG_REALTEK_8168_RESET 未启用"
            echo "   实际值: $(grep "CONFIG_REALTEK_8168_RESET" "$CONFIG_FILE" || echo "未找到")"
            return 1
        fi
        
        # 检查 RT8168_GET_MAC_FROM_VPD 配置（Kaisa 主板使用 VPD 方式）
        if grep -q "CONFIG_RT8168_GET_MAC_FROM_VPD=y" "$CONFIG_FILE"; then
            log_success "✅ CONFIG_RT8168_GET_MAC_FROM_VPD=y (从 VPD 获取 MAC 地址)"
        else
            log_error "❌ CONFIG_RT8168_GET_MAC_FROM_VPD 未启用"
            echo "   实际值: $(grep "CONFIG_RT8168_GET_MAC_FROM_VPD" "$CONFIG_FILE" || echo "未找到")"
        fi
        
        # 检查 RT8168_PUT_MAC_TO_ERI 配置（ERI 寄存器编程）
        # 注意：这个配置是通过 puff/Kconfig 中的 select 语句启用的，只有在编译时才会出现在 .config 中
        if grep -q "CONFIG_RT8168_PUT_MAC_TO_ERI=y" "$CONFIG_FILE"; then
            log_success "✅ CONFIG_RT8168_PUT_MAC_TO_ERI=y (ERI 寄存器编程已启用)"
        elif grep -q "select RT8168_PUT_MAC_TO_ERI" coreboot/src/mainboard/google/puff/Kconfig; then
            log_success "✅ RT8168_PUT_MAC_TO_ERI 已在 puff/Kconfig 中 select (编译时会自动启用)"
        else
            log_error "❌ CONFIG_RT8168_PUT_MAC_TO_ERI 未启用"
            echo "   实际值: $(grep "CONFIG_RT8168_PUT_MAC_TO_ERI" "$CONFIG_FILE" || echo "未找到")"
            return 1
        fi
        
        # 检查 RT8168_SUPPORT_LEGACY_VPD_MAC 配置
        if grep -q "CONFIG_RT8168_SUPPORT_LEGACY_VPD_MAC=y" "$CONFIG_FILE"; then
            log_success "✅ CONFIG_RT8168_SUPPORT_LEGACY_VPD_MAC=y (传统 VPD MAC 支持已启用)"
        else
            log_warning "⚠️ CONFIG_RT8168_SUPPORT_LEGACY_VPD_MAC 未启用"
            echo "   实际值: $(grep "CONFIG_RT8168_SUPPORT_LEGACY_VPD_MAC" "$CONFIG_FILE" || echo "未找到")"
        fi
        
        # 检查 EDK2 相关配置
        if grep -q "CONFIG_EDK2_NETWORK_PXE_SUPPORT=y" "$CONFIG_FILE"; then
            log_success "✅ CONFIG_EDK2_NETWORK_PXE_SUPPORT=y (EDK2 PXE 支持已启用)"
        else
            log_warning "⚠️ CONFIG_EDK2_NETWORK_PXE_SUPPORT 未启用"
            echo "   实际值: $(grep "CONFIG_EDK2_NETWORK_PXE_SUPPORT" "$CONFIG_FILE" || echo "未找到")"
        fi
        
        if grep -q "CONFIG_EDK2_LOAD_OPTION_ROMS=y" "$CONFIG_FILE"; then
            log_success "✅ CONFIG_EDK2_LOAD_OPTION_ROMS=y (EDK2 ROM 加载已启用)"
        else
            log_warning "⚠️ CONFIG_EDK2_LOAD_OPTION_ROMS 未启用"
            echo "   实际值: $(grep "CONFIG_EDK2_LOAD_OPTION_ROMS" "$CONFIG_FILE" || echo "未找到")"
        fi
        
        # 检查 EDK2 启动超时配置
        if grep -q "CONFIG_EDK2_BOOT_TIMEOUT" "$CONFIG_FILE"; then
            BOOT_TIMEOUT=$(grep "CONFIG_EDK2_BOOT_TIMEOUT" "$CONFIG_FILE" | cut -d'=' -f2)
            log_success "✅ CONFIG_EDK2_BOOT_TIMEOUT=$BOOT_TIMEOUT (启动超时设置)"
        else
            log_warning "⚠️ CONFIG_EDK2_BOOT_TIMEOUT 未配置"
        fi
        
        # 检查 EDK2 启动管理器配置
        if grep -q "CONFIG_EDK2_BOOT_MANAGER_ESCAPE=y" "$CONFIG_FILE"; then
            log_success "✅ CONFIG_EDK2_BOOT_MANAGER_ESCAPE=y (使用 Escape 键进入启动管理器)"
        else
            log_warning "⚠️ CONFIG_EDK2_BOOT_MANAGER_ESCAPE 未启用"
        fi
        
        # 检查 EDK2 自定义构建参数
        if grep -q "CONFIG_EDK2_CUSTOM_BUILD_PARAMS" "$CONFIG_FILE"; then
            log_success "✅ CONFIG_EDK2_CUSTOM_BUILD_PARAMS 已配置"
            echo "📝 EDK2 构建参数："
            grep "CONFIG_EDK2_CUSTOM_BUILD_PARAMS" "$CONFIG_FILE" | sed 's/^/    /'
        else
            log_warning "⚠️ CONFIG_EDK2_CUSTOM_BUILD_PARAMS 未配置"
        fi
        
    else
        log_error "❌ 构建配置文件不存在: $CONFIG_FILE"
        log_error "   请先运行构建脚本: ./docker-build-kaisa.sh"
        return 1
    fi
}

# 验证源文件修改
verify_source_modification() {
    log_info "🔍 验证源文件修改（基于修改清单表格）..."
    
    # 验证清单表格中的13项修改
    log_info "📋 验证修改清单表格中的13项修改："
    echo ""
    
    # 1. 检查 r8168.c 驱动文件的所有修改
    if check_file "coreboot/src/drivers/net/r8168.c"; then
        echo "🔧 检查 r8168.c 驱动文件修改："
        
        # 10. VPD解析修复（vpd_find）
        if grep -q "vpd_find" coreboot/src/drivers/net/r8168.c; then
            log_success "✅ [10] VPD解析修复（vpd_find）"
            echo "📝 VPD 解析修复代码："
            grep -A 3 -B 1 "vpd_find" coreboot/src/drivers/net/r8168.c | sed 's/^/    /'
        else
            log_error "❌ [10] VPD解析修复（vpd_find）未找到"
        fi
        
        # 11. RTL8111H ERI编程支持（case 12-15）
        if grep -q "case 12:\|case 13:\|case 14:\|case 15:" coreboot/src/drivers/net/r8168.c; then
            log_success "✅ [11] RTL8111H ERI编程支持（case 12-15）"
            echo "📝 RTL8111H revision 12-15 支持代码："
            grep -A 10 -B 2 "case 12:" coreboot/src/drivers/net/r8168.c | sed 's/^/    /'
        else
            log_error "❌ [11] RTL8111H ERI编程支持（case 12-15）未找到"
        fi
        
        # 12. MAC地址解析bug修复
        if grep -q "hex1.*hex2" coreboot/src/drivers/net/r8168.c; then
            log_success "✅ [12] MAC地址解析bug修复"
            echo "📝 MAC 地址解析修复代码："
            grep -A 5 -B 2 "hex1.*hex2" coreboot/src/drivers/net/r8168.c | sed 's/^/    /'
        else
            log_error "❌ [12] MAC地址解析bug修复未找到"
        fi
        
        # 检查十六进制数字有效性检查
        if grep -q "hex1 > 0x0f.*hex2 > 0x0f" coreboot/src/drivers/net/r8168.c; then
            log_success "✅ [12] 十六进制数字有效性检查"
            echo "📝 十六进制数字有效性检查代码："
            grep -A 3 -B 1 "hex1 > 0x0f.*hex2 > 0x0f" coreboot/src/drivers/net/r8168.c | sed 's/^/    /'
        else
            log_warning "⚠️ [12] 十六进制数字有效性检查未找到"
        fi
        
        # 检查 MAC 地址调试信息
        if grep -q "Parsed MAC address" coreboot/src/drivers/net/r8168.c; then
            log_success "✅ [12] MAC地址调试信息"
            echo "📝 MAC 地址调试信息代码："
            grep -A 1 -B 1 "Parsed MAC address" coreboot/src/drivers/net/r8168.c | sed 's/^/    /'
        else
            log_warning "⚠️ [12] MAC地址调试信息未找到"
        fi
    else
        log_error "❌ r8168.c 文件不存在"
        return 1
    fi
    echo ""
    
    # 13. 检查 Kconfig 依赖关系修复
    if check_file "coreboot/src/drivers/net/Kconfig"; then
        echo "🔧 检查 drivers/net/Kconfig 修改："
        if grep -q "depends on REALTEK_8168_RESET" coreboot/src/drivers/net/Kconfig; then
            log_success "✅ [13] 依赖关系修复（depends on REALTEK_8168_RESET）"
            echo "📝 依赖关系修复："
            grep -A 2 -B 2 "depends on REALTEK_8168_RESET" coreboot/src/drivers/net/Kconfig | sed 's/^/    /'
        else
            log_error "❌ [13] 依赖关系修复（depends on REALTEK_8168_RESET）未找到"
        fi
    else
        log_error "❌ drivers/net/Kconfig 文件不存在"
    fi
    echo ""
    
    # 1-4. 检查 Puff 基板配置
    if check_file "coreboot/src/mainboard/google/puff/Kconfig"; then
        echo "🔧 检查 puff/Kconfig 修改："
        
        # 1. ERI寄存器编程
        if grep -q "select RT8168_PUT_MAC_TO_ERI" coreboot/src/mainboard/google/puff/Kconfig; then
            log_success "✅ [1] ERI寄存器编程（select RT8168_PUT_MAC_TO_ERI）"
            echo "📝 ERI 配置启用："
            grep -A 2 -B 2 "select RT8168_PUT_MAC_TO_ERI" coreboot/src/mainboard/google/puff/Kconfig | sed 's/^/    /'
        else
            log_error "❌ [1] ERI寄存器编程（select RT8168_PUT_MAC_TO_ERI）未找到"
        fi
        
        # 2. 从VPD读取MAC
        if grep -q "select RT8168_GET_MAC_FROM_VPD" coreboot/src/mainboard/google/puff/Kconfig; then
            log_success "✅ [2] 从VPD读取MAC（select RT8168_GET_MAC_FROM_VPD）"
            echo "📝 VPD MAC 读取配置："
            grep -A 2 -B 2 "select RT8168_GET_MAC_FROM_VPD" coreboot/src/mainboard/google/puff/Kconfig | sed 's/^/    /'
        else
            log_error "❌ [2] 从VPD读取MAC（select RT8168_GET_MAC_FROM_VPD）未找到"
        fi
        
        # 3. 传统VPD格式支持
        if grep -q "select RT8168_SUPPORT_LEGACY_VPD_MAC" coreboot/src/mainboard/google/puff/Kconfig; then
            log_success "✅ [3] 传统VPD格式支持（select RT8168_SUPPORT_LEGACY_VPD_MAC）"
            echo "📝 传统 VPD MAC 支持："
            grep -A 2 -B 2 "select RT8168_SUPPORT_LEGACY_VPD_MAC" coreboot/src/mainboard/google/puff/Kconfig | sed 's/^/    /'
        else
            log_error "❌ [3] 传统VPD格式支持（select RT8168_SUPPORT_LEGACY_VPD_MAC）未找到"
        fi
        
        # 4. 启用RTL8168驱动
        if grep -q "select REALTEK_8168_RESET" coreboot/src/mainboard/google/puff/Kconfig; then
            log_success "✅ [4] 启用RTL8168驱动（select REALTEK_8168_RESET）"
            echo "📝 RTL8168 驱动启用："
            grep -A 2 -B 2 "select REALTEK_8168_RESET" coreboot/src/mainboard/google/puff/Kconfig | sed 's/^/    /'
        else
            log_error "❌ [4] 启用RTL8168驱动（select REALTEK_8168_RESET）未找到"
        fi
    else
        log_error "❌ puff/Kconfig 文件不存在"
    fi
    echo ""
    
    # 5-9. 检查 Kaisa 主板配置
    if check_file "coreboot/configs/cml/config.kaisa.uefi"; then
        echo "🔧 检查 config.kaisa.uefi 修改："
        
        # 5. PXE支持
        if grep -q "CONFIG_EDK2_NETWORK_PXE_SUPPORT=y" coreboot/configs/cml/config.kaisa.uefi; then
            log_success "✅ [5] PXE支持（CONFIG_EDK2_NETWORK_PXE_SUPPORT=y）"
            echo "📝 PXE 支持配置："
            grep -A 2 -B 2 "CONFIG_EDK2_NETWORK_PXE_SUPPORT" coreboot/configs/cml/config.kaisa.uefi | sed 's/^/    /'
        else
            log_error "❌ [5] PXE支持（CONFIG_EDK2_NETWORK_PXE_SUPPORT=y）未找到"
        fi
        
        # 6. ROM加载支持
        if grep -q "CONFIG_EDK2_LOAD_OPTION_ROMS=y" coreboot/configs/cml/config.kaisa.uefi; then
            log_success "✅ [6] ROM加载支持（CONFIG_EDK2_LOAD_OPTION_ROMS=y）"
            echo "📝 ROM 加载支持配置："
            grep -A 2 -B 2 "CONFIG_EDK2_LOAD_OPTION_ROMS" coreboot/configs/cml/config.kaisa.uefi | sed 's/^/    /'
        else
            log_error "❌ [6] ROM加载支持（CONFIG_EDK2_LOAD_OPTION_ROMS=y）未找到"
        fi
        
        # 7. 启动超时设置
        if grep -q "CONFIG_EDK2_BOOT_TIMEOUT=10" coreboot/configs/cml/config.kaisa.uefi; then
            log_success "✅ [7] 启动超时设置（CONFIG_EDK2_BOOT_TIMEOUT=10）"
            echo "📝 启动超时配置："
            grep -A 1 -B 1 "CONFIG_EDK2_BOOT_TIMEOUT" coreboot/configs/cml/config.kaisa.uefi | sed 's/^/    /'
        else
            log_warning "⚠️ [7] 启动超时设置（CONFIG_EDK2_BOOT_TIMEOUT=10）未找到"
        fi
        
        # 8. 启动管理器键
        if grep -q "CONFIG_EDK2_BOOT_MANAGER_ESCAPE=y" coreboot/configs/cml/config.kaisa.uefi; then
            log_success "✅ [8] 启动管理器键（CONFIG_EDK2_BOOT_MANAGER_ESCAPE=y）"
            echo "📝 启动管理器键配置："
            grep -A 1 -B 1 "CONFIG_EDK2_BOOT_MANAGER_ESCAPE" coreboot/configs/cml/config.kaisa.uefi | sed 's/^/    /'
        else
            log_warning "⚠️ [8] 启动管理器键（CONFIG_EDK2_BOOT_MANAGER_ESCAPE=y）未找到"
        fi
        
        # 9. EDK2网络驱动启用
        if grep -q "CONFIG_EDK2_CUSTOM_BUILD_PARAMS" coreboot/configs/cml/config.kaisa.uefi; then
            log_success "✅ [9] EDK2网络驱动启用（CONFIG_EDK2_CUSTOM_BUILD_PARAMS）"
            echo "📝 EDK2 构建参数："
            grep -A 1 -B 1 "CONFIG_EDK2_CUSTOM_BUILD_PARAMS" coreboot/configs/cml/config.kaisa.uefi | sed 's/^/    /'
        else
            log_error "❌ [9] EDK2网络驱动启用（CONFIG_EDK2_CUSTOM_BUILD_PARAMS）未找到"
        fi
    else
        log_error "❌ config.kaisa.uefi 文件不存在"
    fi
}

# 验证编译结果
verify_compilation() {
    log_info "🔍 验证编译结果 (coreboot/build/ramstage/drivers/net/r8168.o)..."
    
    OBJECT_FILE="coreboot/build/ramstage/drivers/net/r8168.o"
    if check_file "$OBJECT_FILE"; then
        echo "📁 对象文件: $OBJECT_FILE"
        
        # 检查编译后的对象文件是否包含 RTL8111H 代码
        if strings "$OBJECT_FILE" | grep -q "RTL8111H"; then
            log_success "✅ 编译后的对象文件包含 RTL8111H 支持"
            
            # 显示找到的字符串
            echo "📝 找到的 RTL8111H 相关字符串："
            strings "$OBJECT_FILE" | grep -i "rtl8111h\|8111" | sed 's/^/    /'
        else
            log_warning "⚠️ 编译后的对象文件中未找到 RTL8111H 字符串"
            
            # 检查是否有其他相关字符串
            echo "📝 检查其他相关字符串："
            strings "$OBJECT_FILE" | grep -i "rtl\|8168\|ethernet" | head -10 | sed 's/^/    /'
        fi
        
        # 检查文件大小和修改时间
        echo "📊 文件信息："
        ls -lh "$OBJECT_FILE" | sed 's/^/    /'
    else
        log_error "❌ 编译后的对象文件不存在: $OBJECT_FILE"
        log_error "   驱动可能未被编译，请检查 CONFIG_REALTEK_8168_RESET 配置"
        return 1
    fi
}

# 验证 VPD 和刷机脚本处理
verify_vpd_processing() {
    log_info "🔍 验证 VPD 处理和刷机脚本逻辑..."
    
    # 检查设备目录中的 VPD 文件
    DEVICE_DIRS=$(ls -d device_*/ 2>/dev/null | head -5)
    if [ -n "$DEVICE_DIRS" ]; then
        echo "📁 找到设备目录："
        echo "$DEVICE_DIRS" | sed 's/^/    /'
        
        # 检查最新的设备目录中的 VPD 文件
        LATEST_DEVICE=$(ls -t device_*/ 2>/dev/null | head -1)
        if [ -n "$LATEST_DEVICE" ]; then
            LATEST_FLASH=$(ls -t "${LATEST_DEVICE}flash_"* 2>/dev/null | head -1)
            if [ -n "$LATEST_FLASH" ] && [ -d "$LATEST_FLASH" ]; then
                VPD_FILE="${LATEST_FLASH}/vpd.bin"
                if [ -f "$VPD_FILE" ]; then
                    log_success "✅ 找到 VPD 文件: $VPD_FILE"
                    
                    # 检查 VPD 文件中的 MAC 地址
                    echo "📝 VPD 文件中的 MAC 地址："
                    if strings "$VPD_FILE" | grep -E "^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$" | head -3 | sed 's/^/    /'; then
                        log_success "✅ VPD 中包含有效的 MAC 地址"
                    else
                        log_warning "⚠️ VPD 中未找到标准格式的 MAC 地址"
                        echo "   尝试查找其他格式的 MAC 地址："
                        strings "$VPD_FILE" | grep -E "[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}" | head -3 | sed 's/^/    /' || echo "    未找到"
                    fi
                    
                    # 检查 VPD 文件大小
                    echo "📊 VPD 文件信息："
                    ls -lh "$VPD_FILE" | sed 's/^/    /'
                else
                    log_warning "⚠️ 未找到 VPD 文件: $VPD_FILE"
                fi
            else
                log_warning "⚠️ 未找到设备刷机记录"
            fi
        fi
    else
        log_warning "⚠️ 未找到设备目录，可能尚未运行刷机脚本"
    fi
    
    # 检查刷机脚本是否存在
    if [ -f "flash-coreboot-intel.sh" ]; then
        log_success "✅ 找到刷机脚本: flash-coreboot-intel.sh"
        
        # 检查脚本中的关键功能
        if grep -q "VPD" flash-coreboot-intel.sh; then
            log_success "✅ 刷机脚本包含 VPD 处理逻辑"
        else
            log_warning "⚠️ 刷机脚本中未找到 VPD 处理"
        fi
        
        if grep -q "rt8168-macaddress" flash-coreboot-intel.sh; then
            log_success "✅ 刷机脚本包含 MAC 地址注入逻辑"
        else
            log_warning "⚠️ 刷机脚本中未找到 MAC 地址注入"
        fi
    else
        log_warning "⚠️ 未找到刷机脚本: flash-coreboot-intel.sh"
    fi
}

# 验证 ROM 文件
verify_rom() {
    log_info "🔍 验证最终固件..."
    
    # 优先检查刷机后的 ROM 文件
    FLASHED_ROM=""
    READY_ROM=""
    
    # 查找刷机后的 ROM 文件
    if [ -d "device_7AB7E3275EBC/flash_"* ]; then
        LATEST_FLASH=$(ls -t device_7AB7E3275EBC/flash_* 2>/dev/null | head -1)
        if [ -n "$LATEST_FLASH" ] && [ -d "$LATEST_FLASH" ]; then
            FLASHED_ROM="${LATEST_FLASH}/coreboot.rom"
        fi
    fi
    
    # 查找 ready_roms 中的 ROM 文件
    if [ -d "device_7AB7E3275EBC/ready_roms" ]; then
        READY_ROM=$(ls -t device_7AB7E3275EBC/ready_roms/ready_*.rom 2>/dev/null | head -1)
    fi
    
    # 查找编译后的原始 ROM 文件
    ORIGINAL_ROM=$(ls -t roms/coreboot_edk2-kaisa-mrchromebox_*.rom 2>/dev/null | head -1)
    
    # 选择要检查的 ROM 文件（优先级：刷机后 > ready_roms > 原始编译）
    ROM_TO_CHECK=""
    ROM_TYPE=""
    
    if [ -n "$FLASHED_ROM" ] && [ -f "$FLASHED_ROM" ]; then
        ROM_TO_CHECK="$FLASHED_ROM"
        ROM_TYPE="刷机后的 ROM"
    elif [ -n "$READY_ROM" ] && [ -f "$READY_ROM" ]; then
        ROM_TO_CHECK="$READY_ROM"
        ROM_TYPE="ready_roms 中的 ROM"
    elif [ -n "$ORIGINAL_ROM" ] && [ -f "$ORIGINAL_ROM" ]; then
        ROM_TO_CHECK="$ORIGINAL_ROM"
        ROM_TYPE="编译后的原始 ROM"
    fi
    
    if [ -n "$ROM_TO_CHECK" ] && [ -f "$ROM_TO_CHECK" ]; then
        echo "📁 检查的 ROM 文件: $ROM_TO_CHECK"
        echo "📝 ROM 类型: $ROM_TYPE"
        log_success "✅ 找到固件文件"
        
        # 显示 ROM 文件信息
        echo "📊 ROM 文件信息："
        ls -lh "$ROM_TO_CHECK" | sed 's/^/    /'
        
        # 检查 ROM 文件中的 RTL8168 相关内容
        CBFS_TOOL=""
        if [ -f "coreboot/build/cbfstool" ]; then
            CBFS_TOOL="coreboot/build/cbfstool"
        elif [ -f "coreboot/build/util/cbfstool/cbfstool" ]; then
            CBFS_TOOL="coreboot/build/util/cbfstool/cbfstool"
        elif command -v cbfstool >/dev/null 2>&1; then
            CBFS_TOOL="cbfstool"
        fi
        
        if [ -n "$CBFS_TOOL" ]; then
            echo "📝 ROM 文件中的 RTL8168 相关内容："
            $CBFS_TOOL "$ROM_TO_CHECK" print | grep -i "rtl8168\|macaddress" | sed 's/^/    /'
            
            # 检查 rt8168-macaddress 条目的内容
            if $CBFS_TOOL "$ROM_TO_CHECK" print | grep -q "rt8168-macaddress"; then
                echo "📝 rt8168-macaddress 条目详情："
                $CBFS_TOOL "$ROM_TO_CHECK" print | grep "rt8168-macaddress" | sed 's/^/    /'
                
                # 尝试提取并显示 MAC 地址内容
                if $CBFS_TOOL "$ROM_TO_CHECK" extract -n rt8168-macaddress -f /tmp/rt8168_mac_verify.txt 2>/dev/null; then
                    MAC_CONTENT=$(cat /tmp/rt8168_mac_verify.txt 2>/dev/null)
                    rm -f /tmp/rt8168_mac_verify.txt
                    if [ -n "$MAC_CONTENT" ]; then
                        log_success "✅ rt8168-macaddress 包含 MAC 地址: $MAC_CONTENT"
                    else
                        if [ "$ROM_TYPE" = "编译后的原始 ROM" ]; then
                            log_info "ℹ️ 编译后的原始 ROM 中 rt8168-macaddress 为空是正常的（需要刷机脚本注入）"
                        else
                            log_warning "⚠️ rt8168-macaddress 条目为空"
                        fi
                    fi
                else
                    log_warning "⚠️ 无法提取 rt8168-macaddress 内容"
                fi
            else
                log_warning "⚠️ ROM 中未找到 rt8168-macaddress 条目"
            fi
        else
            log_warning "⚠️ cbfstool 未找到，无法检查 ROM 内容"
            echo "   请先运行构建脚本生成 cbfstool: ./docker-build-kaisa.sh"
        fi
    else
        log_warning "⚠️ 未找到任何 ROM 文件"
        log_warning "   请先运行构建脚本: ./docker-build-kaisa.sh"
        log_warning "   或运行刷机脚本: ./flash-coreboot-intel.sh"
    fi
}

# 生成验证报告
generate_report() {
    log_info "📋 生成验证报告（基于修改清单表格）..."
    
    REPORT_FILE="rtl8168-verification-report.txt"
    
    {
        echo "RTL8168 驱动修改验证报告"
        echo "=========================="
        echo "生成时间: $(date)"
        echo ""
        
        echo "📋 修改清单表格验证结果："
        echo "=========================="
        echo ""
        
        echo "1. Kconfig配置修改检查:"
        echo "----------------------"
        
        # 检查 puff/Kconfig 修改
        if check_file "coreboot/src/mainboard/google/puff/Kconfig"; then
            echo "   [1] ERI寄存器编程 (select RT8168_PUT_MAC_TO_ERI):"
            if grep -q "select RT8168_PUT_MAC_TO_ERI" coreboot/src/mainboard/google/puff/Kconfig; then
                echo "      ✅ 已配置"
            else
                echo "      ❌ 未配置"
            fi
            
            echo "   [2] 从VPD读取MAC (select RT8168_GET_MAC_FROM_VPD):"
            if grep -q "select RT8168_GET_MAC_FROM_VPD" coreboot/src/mainboard/google/puff/Kconfig; then
                echo "      ✅ 已配置"
            else
                echo "      ❌ 未配置"
            fi
            
            echo "   [3] 传统VPD格式支持 (select RT8168_SUPPORT_LEGACY_VPD_MAC):"
            if grep -q "select RT8168_SUPPORT_LEGACY_VPD_MAC" coreboot/src/mainboard/google/puff/Kconfig; then
                echo "      ✅ 已配置"
            else
                echo "      ❌ 未配置"
            fi
            
            echo "   [4] 启用RTL8168驱动 (select REALTEK_8168_RESET):"
            if grep -q "select REALTEK_8168_RESET" coreboot/src/mainboard/google/puff/Kconfig; then
                echo "      ✅ 已配置"
            else
                echo "      ❌ 未配置"
            fi
        else
            echo "   ❌ puff/Kconfig 文件不存在"
        fi
        echo ""
        
        echo "2. 主板配置修改检查:"
        echo "------------------"
        
        # 检查 config.kaisa.uefi 修改
        if check_file "coreboot/configs/cml/config.kaisa.uefi"; then
            echo "   [5] PXE支持 (CONFIG_EDK2_NETWORK_PXE_SUPPORT=y):"
            if grep -q "CONFIG_EDK2_NETWORK_PXE_SUPPORT=y" coreboot/configs/cml/config.kaisa.uefi; then
                echo "      ✅ 已配置"
            else
                echo "      ❌ 未配置"
            fi
            
            echo "   [6] ROM加载支持 (CONFIG_EDK2_LOAD_OPTION_ROMS=y):"
            if grep -q "CONFIG_EDK2_LOAD_OPTION_ROMS=y" coreboot/configs/cml/config.kaisa.uefi; then
                echo "      ✅ 已配置"
            else
                echo "      ❌ 未配置"
            fi
            
            echo "   [7] 启动超时设置 (CONFIG_EDK2_BOOT_TIMEOUT=10):"
            if grep -q "CONFIG_EDK2_BOOT_TIMEOUT=10" coreboot/configs/cml/config.kaisa.uefi; then
                echo "      ✅ 已配置"
            else
                echo "      ⚠️ 未配置（可能必须）"
            fi
            
            echo "   [8] 启动管理器键 (CONFIG_EDK2_BOOT_MANAGER_ESCAPE=y):"
            if grep -q "CONFIG_EDK2_BOOT_MANAGER_ESCAPE=y" coreboot/configs/cml/config.kaisa.uefi; then
                echo "      ✅ 已配置"
            else
                echo "      ⚠️ 未配置（可能必须）"
            fi
            
            echo "   [9] EDK2网络驱动启用 (CONFIG_EDK2_CUSTOM_BUILD_PARAMS):"
            if grep -q "CONFIG_EDK2_CUSTOM_BUILD_PARAMS" coreboot/configs/cml/config.kaisa.uefi; then
                echo "      ✅ 已配置"
            else
                echo "      ❌ 未配置"
            fi
        else
            echo "   ❌ config.kaisa.uefi 文件不存在"
        fi
        echo ""
        
        echo "3. 源码修改检查:"
        echo "---------------"
        
        # 检查 r8168.c 修改
        if check_file "coreboot/src/drivers/net/r8168.c"; then
            echo "   [10] VPD解析修复 (vpd_find):"
            if grep -q "vpd_find" coreboot/src/drivers/net/r8168.c; then
                echo "      ✅ 已修改"
            else
                echo "      ❌ 未修改"
            fi
            
            echo "   [11] RTL8111H ERI编程支持 (case 12-15):"
            if grep -q "case 12:\|case 13:\|case 14:\|case 15:" coreboot/src/drivers/net/r8168.c; then
                echo "      ✅ 已修改"
            else
                echo "      ❌ 未修改"
            fi
            
            echo "   [12] MAC地址解析bug修复:"
            if grep -q "hex1.*hex2" coreboot/src/drivers/net/r8168.c; then
                echo "      ✅ 已修改"
            else
                echo "      ❌ 未修改"
            fi
        else
            echo "   ❌ r8168.c 文件不存在"
        fi
        
        # 检查 Kconfig 依赖关系修复
        if check_file "coreboot/src/drivers/net/Kconfig"; then
            echo "   [13] 依赖关系修复 (depends on REALTEK_8168_RESET):"
            if grep -q "depends on REALTEK_8168_RESET" coreboot/src/drivers/net/Kconfig; then
                echo "      ✅ 已修改"
            else
                echo "      ❌ 未修改"
            fi
        else
            echo "   ❌ drivers/net/Kconfig 文件不存在"
        fi
        echo ""
        
        echo "4. 构建配置检查:"
        echo "---------------"
        if check_file "coreboot/.config"; then
            echo "   CONFIG_REALTEK_8168_RESET: $(grep "CONFIG_REALTEK_8168_RESET" coreboot/.config || echo "未找到")"
            echo "   CONFIG_RT8168_PUT_MAC_TO_ERI: $(grep "CONFIG_RT8168_PUT_MAC_TO_ERI" coreboot/.config || echo "未找到")"
            echo "   CONFIG_RT8168_GET_MAC_FROM_VPD: $(grep "CONFIG_RT8168_GET_MAC_FROM_VPD" coreboot/.config || echo "未找到")"
            echo "   CONFIG_EDK2_NETWORK_PXE_SUPPORT: $(grep "CONFIG_EDK2_NETWORK_PXE_SUPPORT" coreboot/.config || echo "未找到")"
        else
            echo "   构建配置文件不存在"
        fi
        echo ""
        
        echo "5. 编译结果检查:"
        echo "---------------"
        if check_file "coreboot/build/ramstage/drivers/net/r8168.o"; then
            echo "   对象文件大小: $(ls -lh coreboot/build/ramstage/drivers/net/r8168.o | awk '{print $5}')"
            if strings coreboot/build/ramstage/drivers/net/r8168.o | grep -q "RTL8111H"; then
                echo "   ✅ 编译后的对象文件包含 RTL8111H 支持"
            else
                echo "   ❌ 编译后的对象文件中未找到 RTL8111H 字符串"
            fi
        else
            echo "   编译后的对象文件不存在"
        fi
        echo ""
        
        echo "6. VPD 处理检查:"
        echo "---------------"
        DEVICE_DIRS=$(ls -d device_*/ 2>/dev/null | head -1)
        if [ -n "$DEVICE_DIRS" ]; then
            LATEST_FLASH=$(ls -t "${DEVICE_DIRS}flash_"* 2>/dev/null | head -1)
            if [ -n "$LATEST_FLASH" ] && [ -d "$LATEST_FLASH" ]; then
                VPD_FILE="${LATEST_FLASH}/vpd.bin"
                if [ -f "$VPD_FILE" ]; then
                    echo "   ✅ 找到 VPD 文件: $VPD_FILE"
                    echo "   文件大小: $(ls -lh "$VPD_FILE" | awk '{print $5}')"
                    if strings "$VPD_FILE" | grep -qE "^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$"; then
                        echo "   ✅ VPD 包含有效 MAC 地址"
                    else
                        echo "   ❌ VPD 中未找到标准格式 MAC 地址"
                    fi
                else
                    echo "   ❌ 未找到 VPD 文件"
                fi
            else
                echo "   未找到设备刷机记录"
            fi
        else
            echo "   未找到设备目录"
        fi
        echo ""
        
        echo "7. ROM 文件检查:"
        echo "---------------"
        ROM_FILE=$(ls -t roms/coreboot_edk2-kaisa-mrchromebox_*.rom 2>/dev/null | head -1)
        if [ -n "$ROM_FILE" ] && [ -f "$ROM_FILE" ]; then
            echo "   ROM 文件: $ROM_FILE"
            echo "   文件大小: $(ls -lh "$ROM_FILE" | awk '{print $5}')"
        else
            echo "   未找到 ROM 文件"
        fi
        
    } > "$REPORT_FILE"
    
    log_success "✅ 验证报告已生成: $REPORT_FILE"
}

# 主函数
main() {
    echo "🔧 RTL8168 驱动修改验证脚本"
    echo "=============================="
    echo ""
    echo "📋 基于修改清单表格验证13项修改："
    echo "=================================="
    echo "1.  ERI寄存器编程 (select RT8168_PUT_MAC_TO_ERI)"
    echo "2.  从VPD读取MAC (select RT8168_GET_MAC_FROM_VPD)"
    echo "3.  传统VPD格式支持 (select RT8168_SUPPORT_LEGACY_VPD_MAC)"
    echo "4.  启用RTL8168驱动 (select REALTEK_8168_RESET)"
    echo "5.  PXE支持 (CONFIG_EDK2_NETWORK_PXE_SUPPORT=y)"
    echo "6.  ROM加载支持 (CONFIG_EDK2_LOAD_OPTION_ROMS=y)"
    echo "7.  启动超时设置 (CONFIG_EDK2_BOOT_TIMEOUT=10)"
    echo "8.  启动管理器键 (CONFIG_EDK2_BOOT_MANAGER_ESCAPE=y)"
    echo "9.  EDK2网络驱动启用 (CONFIG_EDK2_CUSTOM_BUILD_PARAMS)"
    echo "10. VPD解析修复 (vpd_find)"
    echo "11. RTL8111H ERI编程支持 (case 12-15)"
    echo "12. MAC地址解析bug修复"
    echo "13. 依赖关系修复 (depends on REALTEK_8168_RESET)"
    echo ""
    
    # 检查是否在正确的目录
    if [ ! -d "coreboot" ]; then
        log_error "请在 coreboot-builder 目录中运行此脚本"
        exit 1
    fi
    
    # 执行验证步骤
    verify_config
    echo ""
    
    verify_source_modification
    echo ""
    
    verify_compilation
    echo ""
    
    verify_vpd_processing
    echo ""
    
    verify_rom
    echo ""
    
    generate_report
    
    echo ""
    log_info "🎉 验证完成！"
    echo ""
    log_info "📄 详细报告已生成: rtl8168-verification-report.txt"
    log_info "📋 验证了修改清单表格中的所有13项修改"
}

# 运行主函数
main "$@"

