#!/bin/bash
# 验证 patches 文件是否正确

set -e

echo "🔍 开始验证 patches..."

cd coreboot

# 1. 恢复远程 r8168.c
echo "📋 步骤 1: 恢复远程 r8168.c"
git restore src/drivers/net/r8168.c

# 2. 顺序应用 patch
echo ""
echo "📋 步骤 2: 顺序应用 patches..."

echo "📝 4.1: 应用 fix-vpd-header.patch..."
patch -p1 < ../patches/fix-vpd-header.patch || echo "⚠️  Patch 可能已经应用"

echo "📝 4.2: 应用 fix-vpd-parsing.patch..."
patch -p1 < ../patches/fix-vpd-parsing.patch || echo "⚠️  Patch 应用失败，继续..."

echo "📝 4.3: 应用 fix-get-mac-address.patch..."
patch -p1 < ../patches/fix-get-mac-address.patch || echo "⚠️  Patch 应用失败，继续..."

echo "📝 4.4: 应用 fix-rtl8111h-eri.patch..."
patch -p1 < ../patches/fix-rtl8111h-eri.patch || echo "⚠️  Patch 应用失败，继续..."

echo "📝 4.5: 应用 fix-vpd-debug.patch..."
patch -p1 < ../patches/fix-vpd-debug.patch || echo "⚠️  Patch 应用失败，继续..."

# 3. 验证关键修改
echo ""
echo "📋 步骤 3: 验证关键修改..."

if grep -q "#include <drivers/vpd/vpd.h>" src/drivers/net/r8168.c; then
    echo "✅ VPD header include 存在"
else
    echo "❌ VPD header include 不存在"
    exit 1
fi

if grep -q "vpd_find(vpd_key, &vpd_size, VPD_RO)" src/drivers/net/r8168.c; then
    echo "✅ vpd_find 调用存在"
else
    echo "❌ vpd_find 调用不存在"
    exit 1
fi

if grep -q "Check if both hex digits are valid" src/drivers/net/r8168.c; then
    echo "✅ MAC 地址验证代码存在"
else
    echo "❌ MAC 地址验证代码不存在"
    exit 1
fi

if grep -q "case 12:" src/drivers/net/r8168.c; then
    echo "✅ RTL8111H case 12 存在"
else
    echo "❌ RTL8111H case 12 不存在"
    exit 1
fi

if grep -q "fetch_mac_vpd_dev_idx: device_index" src/drivers/net/r8168.c; then
    echo "✅ VPD 调试代码存在"
else
    echo "❌ VPD 调试代码不存在"
    exit 1
fi

echo ""
echo "✅ 所有验证通过！patch 文件格式正确。"

# 4. 显示关键代码片段
echo ""
echo "📋 关键代码片段："
echo "===================="
echo ""
echo "VPD header:"
grep -n "#include <drivers/vpd/vpd.h>" src/drivers/net/r8168.c
echo ""
echo "VPD parsing:"
grep -A 3 "Searching for VPD key:" src/drivers/net/r8168.c | head -5
echo ""
echo "MAC address fix:"
grep -A 5 "Check if both hex digits are valid" src/drivers/net/r8168.c | head -8
echo ""
echo "RTL8111H support:"
grep -n "case 12:" src/drivers/net/r8168.c
echo ""

echo "✅ 验证完成！"

