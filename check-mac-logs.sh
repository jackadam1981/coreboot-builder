#!/bin/bash
# 检查MAC地址相关启动日志的脚本

echo "=== 使用cbmem查看MAC地址相关启动日志 ==="
echo ""

# 检查cbmem工具是否存在
if [ ! -f "./tools/cbmem" ]; then
    echo "❌ 错误: 找不到 cbmem 工具"
    echo "   请确保 tools/cbmem 存在"
    exit 1
fi

# 检查是否有root权限
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  需要root权限来访问CBMEM"
    echo "   请使用: sudo $0"
    exit 1
fi

echo "📋 1. 查看所有r8168相关日志:"
echo "----------------------------------------"
sudo ./tools/cbmem -c 2>/dev/null | grep -i "r8168" || echo "   未找到r8168相关日志"

echo ""
echo "📋 2. 查看MAC地址相关日志:"
echo "----------------------------------------"
sudo ./tools/cbmem -c 2>/dev/null | grep -i "mac\|vpd\|ethernet" | head -30 || echo "   未找到MAC相关日志"

echo ""
echo "📋 3. 查看ERI编程相关日志:"
echo "----------------------------------------"
sudo ./tools/cbmem -c 2>/dev/null | grep -i "eri\|programming" | head -20 || echo "   未找到ERI相关日志"

echo ""
echo "📋 4. 查看完整的r8168驱动初始化过程:"
echo "----------------------------------------"
sudo ./tools/cbmem -c 2>/dev/null | grep -A 10 -B 2 "r8168.*Starting\|r8168.*MAC\|r8168.*VPD\|r8168.*ERI" || echo "   未找到相关日志"

echo ""
echo "📋 5. 保存完整日志到文件:"
echo "----------------------------------------"
LOG_FILE="boot_log_$(date +%Y%m%d_%H%M%S).txt"
sudo ./tools/cbmem -c 2>/dev/null > "$LOG_FILE" 2>&1
if [ -f "$LOG_FILE" ]; then
    echo "   ✅ 日志已保存到: $LOG_FILE"
    echo "   文件大小: $(du -h "$LOG_FILE" | cut -f1)"
    echo ""
    echo "   使用以下命令查看完整日志:"
    echo "   cat $LOG_FILE | grep -i r8168"
    echo "   cat $LOG_FILE | grep -i mac"
else
    echo "   ❌ 无法保存日志文件"
fi

echo ""
echo "💡 提示:"
echo "   - 如果看不到日志，可能需要降低日志级别（CONFIG_DEFAULT_CONSOLE_LOGLEVEL=0）"
echo "   - 确保固件已刷入并重启过系统"
echo "   - 某些日志可能只在DEBUG级别下可见"
