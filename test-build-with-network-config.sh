#!/bin/bash

# 测试启用网络配置后的构建效果
echo "=== 测试 EDK2 网络配置构建效果 ==="
echo ""

# 检查当前配置
echo "1. 检查当前 coreboot 配置..."
if [ -f "/root/MrChromebox/.config" ]; then
    echo "✅ 找到 .config 文件"
    
    # 检查网络相关配置
    echo ""
    echo "2. 检查网络相关配置项："
    grep -E "EDK2.*NETWORK|EDK2.*PXE" /root/MrChromebox/.config || echo "❌ 未找到网络配置项"
    
    # 检查 EDK2 仓库配置
    echo ""
    echo "3. 检查 EDK2 仓库配置："
    grep -E "EDK2_REPO" /root/MrChromebox/.config || echo "❌ 未找到 EDK2 仓库配置"
    
else
    echo "❌ 未找到 .config 文件，需要先运行 make menuconfig"
fi

echo ""
echo "4. 建议的测试步骤："
echo ""
echo "步骤1：配置网络支持"
echo "  cd /root/MrChromebox"
echo "  make menuconfig"
echo "  启用以下配置："
echo "    - CONFIG_EDK2_NETWORK_PXE_SUPPORT=y"
echo "    - CONFIG_EDK2_NETWORK_HTTP_BOOT_SUPPORT=y"
echo "    - CONFIG_EDK2_NETWORK_ISCSI_SUPPORT=y"
echo "    - CONFIG_EDK2_LOAD_OPTION_ROMS=y"
echo ""

echo "步骤2：测试构建"
echo "  make -C payloads/external/edk2"
echo "  观察构建日志中是否有网络相关模块被编译"
echo ""

echo "步骤3：检查构建产物"
echo "  find . -name '*.efi' | grep -i network"
echo "  find . -name '*.efi' | grep -i pxe"
echo ""

echo "步骤4：验证 ROM 内容"
echo "  ./cbfstool build/coreboot.rom print"
echo "  检查是否有网络相关的模块被包含"
echo ""

echo "5. 预期结果分析："
echo ""
echo "✅ 如果成功："
echo "  - 构建日志中会显示网络驱动被编译"
echo "  - ROM 中会包含网络相关的 EFI 模块"
echo "  - UEFI 启动菜单中可能出现网络启动选项"
echo ""

echo "❌ 如果失败："
echo "  - 构建日志中可能显示网络模块被跳过"
echo "  - 可能提示某些网络驱动不可用"
echo "  - ROM 中可能不包含网络功能"
echo ""

echo "6. 故障排除："
echo ""
echo "问题1：网络驱动不可用"
echo "  原因：MrChromebox EDK2 仓库可能不包含完整的网络支持"
echo "  解决：使用外部 iPXE 驱动作为主要方案"
echo ""

echo "问题2：RTL8168 不被支持"
echo "  原因：EDK2 网络支持主要针对 USB 网卡"
echo "  解决：依赖专用的 RTL8168 iPXE 驱动"
echo ""

echo "问题3：构建失败"
echo "  原因：网络配置与当前 EDK2 版本不兼容"
echo "  解决：禁用网络配置，仅使用外部 iPXE"
echo ""

echo "=== 测试指南完成 ==="
echo ""
echo "建议：先进行小规模测试，验证网络配置是否真的有效，"
echo "然后再决定是否在生产环境中使用。"
