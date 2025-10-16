#!/bin/bash

# 测试 EDK2 网络配置是否有效的脚本
echo "=== EDK2 网络配置验证脚本 ==="
echo ""

# 检查 MrChromebox EDK2 配置
echo "1. 检查 MrChromebox EDK2 配置..."
if [ -f "/root/MrChromebox/payloads/external/edk2/Makefile" ]; then
    echo "✅ 找到 EDK2 Makefile"
    
    # 检查网络配置
    echo ""
    echo "2. 检查网络配置项..."
    if grep -q "CONFIG_EDK2_NETWORK_PXE_SUPPORT" /root/MrChromebox/payloads/external/edk2/Makefile; then
        echo "✅ 找到 EDK2_NETWORK_PXE_SUPPORT 配置"
        
        # 显示相关配置
        echo ""
        echo "3. 网络配置详情："
        grep -A 5 -B 2 "CONFIG_EDK2_NETWORK_PXE_SUPPORT" /root/MrChromebox/payloads/external/edk2/Makefile
    else
        echo "❌ 未找到 EDK2_NETWORK_PXE_SUPPORT 配置"
    fi
    
    # 检查构建字符串
    echo ""
    echo "4. 检查构建字符串..."
    if grep -q "NETWORK_DRIVER_ENABLE" /root/MrChromebox/payloads/external/edk2/Makefile; then
        echo "✅ 找到网络驱动启用配置"
        grep -A 3 -B 1 "NETWORK_DRIVER_ENABLE" /root/MrChromebox/payloads/external/edk2/Makefile
    else
        echo "❌ 未找到网络驱动启用配置"
    fi
else
    echo "❌ 未找到 EDK2 Makefile"
fi

echo ""
echo "5. 检查 Kconfig 配置..."
if [ -f "/root/MrChromebox/payloads/external/edk2/Kconfig" ]; then
    echo "✅ 找到 EDK2 Kconfig"
    
    # 检查网络相关配置
    echo ""
    echo "6. 网络相关 Kconfig 配置："
    grep -A 3 -B 1 "NETWORK.*PXE\|PXE.*SUPPORT" /root/MrChromebox/payloads/external/edk2/Kconfig
else
    echo "❌ 未找到 EDK2 Kconfig"
fi

echo ""
echo "=== 配置验证完成 ==="
echo ""
echo "注意：这些配置项只有在 MrChromebox 的 EDK2 仓库中实际存在对应的"
echo "网络驱动和 PXE 支持代码时才会生效。"
echo ""
echo "建议："
echo "1. 检查 MrChromebox EDK2 仓库是否真的包含网络驱动"
echo "2. 验证构建时是否真的包含了网络功能"
echo "3. 测试编译后的固件是否真的有网络启动功能"
