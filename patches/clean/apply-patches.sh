#!/bin/bash

# 应用补丁脚本
# 用于将4个补丁文件应用到coreboot源码

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COREBOOT_DIR="$PROJECT_ROOT/coreboot"

echo "=== 应用补丁到coreboot源码 ==="
echo "项目根目录: $PROJECT_ROOT"
echo "Coreboot目录: $COREBOOT_DIR"
echo "补丁目录: $SCRIPT_DIR"

# 检查coreboot目录是否存在
if [ ! -d "$COREBOOT_DIR" ]; then
    echo "错误: coreboot目录不存在: $COREBOOT_DIR"
    exit 1
fi

# 应用补丁
cd "$COREBOOT_DIR"

echo "=== 应用补丁文件 ==="
for patch_file in "$SCRIPT_DIR"/*.patch; do
    if [ -f "$patch_file" ]; then
        echo "应用补丁: $(basename "$patch_file")"
        if ! patch -p1 < "$patch_file"; then
            echo "错误: 应用补丁失败: $patch_file"
            exit 1
        fi
    fi
done

echo "=== 补丁应用完成 ==="
echo "已应用的补丁文件:"
ls -la "$SCRIPT_DIR"/*.patch

echo "=== 验证修改 ==="
echo "检查关键文件是否存在:"
echo "- src/mainboard/google/puff/Kconfig: $([ -f "src/mainboard/google/puff/Kconfig" ] && echo "✓" || echo "✗")"
echo "- src/drivers/net/r8168.c: $([ -f "src/drivers/net/r8168.c" ] && echo "✓" || echo "✗")"
echo "- src/drivers/net/Kconfig: $([ -f "src/drivers/net/Kconfig" ] && echo "✓" || echo "✗")"
echo "- configs/cml/config.kaisa.uefi: $([ -f "configs/cml/config.kaisa.uefi" ] && echo "✓" || echo "✗")"

echo "=== 补丁应用成功 ==="
