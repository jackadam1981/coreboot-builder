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
    log_info "🔍 验证构建配置 (coreboot/.config)..."
    
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
            return 1
        fi
    else
        log_error "❌ 构建配置文件不存在: $CONFIG_FILE"
        log_error "   请先运行构建脚本: ./docker-build-kaisa.sh"
        return 1
    fi
}

# 验证源文件修改
verify_source_modification() {
    log_info "🔍 验证源文件修改..."
    
    if check_file "coreboot/src/drivers/net/r8168.c"; then
        # 检查 RTL8111H 支持代码
        if grep -q "RTL8111H support" coreboot/src/drivers/net/r8168.c; then
            log_success "✅ 源文件包含 RTL8111H 支持代码"
            
            # 显示相关代码片段
            echo "📝 相关代码片段："
            grep -A 3 -B 1 "RTL8111H support" coreboot/src/drivers/net/r8168.c | sed 's/^/    /'
        else
            log_error "❌ 源文件中未找到 RTL8111H 支持代码"
            return 1
        fi
    else
        log_error "❌ 源文件不存在"
        return 1
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

# 验证 ROM 文件
verify_rom() {
    log_info "🔍 验证最终固件 (roms/coreboot_edk2-kaisa-mrchromebox_*.rom)..."
    
    # 查找最新的 ROM 文件
    ROM_FILE=$(ls -t roms/coreboot_edk2-kaisa-mrchromebox_*.rom 2>/dev/null | head -1)
    
    if [ -n "$ROM_FILE" ] && [ -f "$ROM_FILE" ]; then
        echo "📁 ROM 文件: $ROM_FILE"
        log_success "✅ 找到最终固件文件"
        
        # 显示 ROM 文件信息
        echo "📊 ROM 文件信息："
        ls -lh "$ROM_FILE" | sed 's/^/    /'
        
        # 检查 ROM 文件中的 RTL8168 相关内容
        CBFS_TOOL=""
        if [ -f "coreboot/build/cbfstool" ]; then
            CBFS_TOOL="coreboot/build/cbfstool"
        elif command -v cbfstool >/dev/null 2>&1; then
            CBFS_TOOL="cbfstool"
        fi
        
        if [ -n "$CBFS_TOOL" ]; then
            echo "📝 ROM 文件中的 RTL8168 相关内容："
            $CBFS_TOOL "$ROM_FILE" print | grep -i "rtl8168\|macaddress" | sed 's/^/    /'
        else
            log_warning "⚠️ cbfstool 未找到，无法检查 ROM 内容"
            echo "   请先运行构建脚本生成 cbfstool: ./docker-build-kaisa.sh"
        fi
    else
        log_warning "⚠️ 未找到 ROM 文件: roms/coreboot_edk2-kaisa-mrchromebox_*.rom"
        log_warning "   请先运行构建脚本: ./docker-build-kaisa.sh"
    fi
}

# 生成验证报告
generate_report() {
    log_info "📋 生成验证报告..."
    
    REPORT_FILE="rtl8168-verification-report.txt"
    
    {
        echo "RTL8168 驱动修改验证报告"
        echo "=========================="
        echo "生成时间: $(date)"
        echo ""
        
        echo "1. 构建配置检查:"
        if check_file "coreboot/build/config.h"; then
            echo "   CONFIG_REALTEK_8168_RESET: $(grep "CONFIG_REALTEK_8168_RESET" coreboot/build/config.h || echo "未找到")"
            echo "   CONFIG_RT8168_PUT_MAC_TO_ERI: $(grep "CONFIG_RT8168_PUT_MAC_TO_ERI" coreboot/build/config.h || echo "未找到")"
        else
            echo "   构建配置文件不存在"
        fi
        echo ""
        
        echo "2. 源文件修改检查:"
        if check_file "coreboot/src/drivers/net/r8168.c"; then
            if grep -q "RTL8111H support" coreboot/src/drivers/net/r8168.c; then
                echo "   ✅ 源文件包含 RTL8111H 支持代码"
            else
                echo "   ❌ 源文件中未找到 RTL8111H 支持代码"
            fi
        else
            echo "   源文件不存在"
        fi
        echo ""
        
        echo "3. 编译结果检查:"
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
        
        echo "4. ROM 文件检查:"
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
    
    verify_rom
    echo ""
    
    generate_report
    
    echo ""
    log_info "🎉 验证完成！"
}

# 运行主函数
main "$@"
