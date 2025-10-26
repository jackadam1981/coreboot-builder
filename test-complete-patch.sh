#!/bin/bash
# 测试完整的单个 patch

set -e

echo "🔍 测试完整的单个 patch..."

cd coreboot

# 1. 恢复远程 r8168.c
echo ""
echo "📋 步骤 1: 恢复远程 r8168.c"
git restore src/drivers/net/r8168.c
rm -f src/drivers/net/r8168.c.rej src/drivers/net/r8168.c.orig

# 2. 应用完整的 patch
echo ""
echo "📋 步骤 2: 应用 fix-r8168-complete.patch"
patch -p1 < ../patches/fix-r8168-complete.patch

echo "✅ Patch 应用成功！"

# 3. 验证所有修改
echo ""
echo "📋 步骤 3: 验证所有修改"

if grep -q "#include <drivers/vpd/vpd.h>" src/drivers/net/r8168.c; then
    echo "✅ VPD header include"
else
    echo "❌ VPD header include"
    exit 1
fi

if grep -q "Searching for VPD key:" src/drivers/net/r8168.c; then
    echo "✅ VPD parsing debug"
else
    echo "❌ VPD parsing debug"
    exit 1
fi

if grep -q "Check if both hex digits are valid" src/drivers/net/r8168.c; then
    echo "✅ MAC address validation"
else
    echo "❌ MAC address validation"
    exit 1
fi

if grep -q "case 12:" src/drivers/net/r8168.c; then
    echo "✅ RTL8111H case 12"
else
    echo "❌ RTL8111H case 12"
    exit 1
fi

if grep -q "fetch_mac_vpd_dev_idx: device_index" src/drivers/net/r8168.c; then
    echo "✅ VPD debug info"
else
    echo "❌ VPD debug info"
    exit 1
fi

echo ""
echo "✅ 所有验证通过！"

