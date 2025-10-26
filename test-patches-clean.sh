#!/bin/bash
# 在干净环境中测试所有 patches

set -e

echo "🔍 开始测试 patches..."

cd coreboot

# 1. 恢复远程 r8168.c
echo ""
echo "📋 步骤 1: 恢复远程 r8168.c"
git restore src/drivers/net/r8168.c
rm -f src/drivers/net/r8168.c.rej src/drivers/net/r8168.c.orig

# 2. 验证第一个 patch
echo ""
echo "📋 步骤 2: 测试 fix-vpd-header.patch"
if grep -q "#include <drivers/vpd/vpd.h>" src/drivers/net/r8168.c; then
    echo "⚠️  VPD header 已经存在，跳过..."
else
    patch -p1 < ../patches/fix-vpd-header.patch
    echo "✅ fix-vpd-header.patch 应用成功"
fi

# 3. 验证第二个 patch
echo ""
echo "📋 步骤 3: 测试 fix-vpd-parsing.patch"
if grep -q "Searching for VPD key:" src/drivers/net/r8168.c; then
    echo "⚠️  VPD parsing 修改已经存在，跳过..."
else
    patch -p1 < ../patches/fix-vpd-parsing.patch
    echo "✅ fix-vpd-parsing.patch 应用成功"
fi

# 4. 验证第三个 patch
echo ""
echo "📋 步骤 4: 测试 fix-get-mac-address.patch"
if grep -q "Check if both hex digits are valid" src/drivers/net/r8168.c; then
    echo "⚠️  get_mac_address 修改已经存在，跳过..."
else
    patch -p1 < ../patches/fix-get-mac-address.patch
    echo "✅ fix-get-mac-address.patch 应用成功"
fi

# 5. 验证第四个 patch
echo ""
echo "📋 步骤 5: 测试 fix-rtl8111h-eri.patch"
if grep -q "case 12:" src/drivers/net/r8168.c; then
    echo "⚠️  RTL8111H ERI 修改已经存在，跳过..."
else
    patch -p1 < ../patches/fix-rtl8111h-eri.patch
    echo "✅ fix-rtl8111h-eri.patch 应用成功"
fi

# 6. 验证第五个 patch
echo ""
echo "📋 步骤 6: 测试 fix-vpd-debug.patch"
if grep -q "fetch_mac_vpd_dev_idx: device_index" src/drivers/net/r8168.c; then
    echo "⚠️  VPD debug 修改已经存在，跳过..."
else
    patch -p1 < ../patches/fix-vpd-debug.patch
    echo "✅ fix-vpd-debug.patch 应用成功"
fi

# 7. 最终验证
echo ""
echo "📋 步骤 7: 最终验证"
echo ""
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

