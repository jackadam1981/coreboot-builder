#!/bin/bash
# 本地 Docker 构建脚本
# 用于编译修复后的 coreboot 固件

set -e

echo "🚀 开始本地 Docker 构建 coreboot..."

# 检查是否在正确的目录
if [ ! -f "coreboot/Makefile" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    exit 1
fi

# 检查 r8168.c 修复是否已应用
if ! grep -q "#include <drivers/vpd/vpd.h>" coreboot/src/drivers/net/r8168.c; then
    echo "📝 应用 r8168.c 修复..."
    cp fixed-files/r8168.c coreboot/src/drivers/net/r8168.c
    echo "✅ r8168.c 修复已应用"
fi

# 进入 coreboot 目录
cd coreboot

echo "🐳 使用 Docker 构建..."

# 检查是否存在构建脚本
if [ ! -f "build-uefi.sh" ]; then
    echo "❌ 错误: 未找到 build-uefi.sh"
    exit 1
fi

# 构建 kaisa 固件
echo "🔧 开始构建 kaisa 固件..."
./build-uefi.sh kaisa

# 检查构建结果
if [ -f "build/coreboot.rom" ]; then
    echo "✅ 构建成功!"
    echo "📋 ROM 文件位置: $(pwd)/build/coreboot.rom"
    echo "📋 文件大小: $(du -h build/coreboot.rom | cut -f1)"
    
    # 复制到 roms 目录
    mkdir -p ../roms
    cp build/coreboot.rom ../roms/coreboot_edk2-kaisa-custom_$(date +%Y%m%d).rom
    echo "✅ ROM 已复制到 ../roms/"
else
    echo "❌ 构建失败: 未找到 coreboot.rom"
    exit 1
fi

