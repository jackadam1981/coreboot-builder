#!/bin/bash
# cbmem 安装脚本

set -e

echo "🔧 安装 cbmem 工具..."

# 方法 1: 尝试从包管理器安装
if command -v apt-get &> /dev/null; then
    echo "📦 尝试从 apt 安装..."
    sudo apt-get update
    sudo apt-get install -y cbmem 2>/dev/null && {
        echo "✅ cbmem 已从 apt 安装"
        cbmem --version
        exit 0
    } || echo "⚠️  apt 仓库中没有 cbmem"
fi

# 方法 2: 从 coreboot 源码编译
if [ -d "coreboot/util/cbmem" ]; then
    echo "🔨 从 coreboot 源码编译 cbmem..."
    cd coreboot/util/cbmem
    make
    sudo cp cbmem /usr/local/bin/
    echo "✅ cbmem 已编译并安装到 /usr/local/bin/"
    cbmem --version
    exit 0
fi

# 方法 3: 从 GitHub Actions 构建产物下载（如果有）
echo "📥 尝试从构建产物中查找..."
if [ -f "tools/cbmem" ]; then
    sudo cp tools/cbmem /usr/local/bin/
    sudo chmod +x /usr/local/bin/cbmem
    echo "✅ cbmem 已从 tools 目录安装"
    cbmem --version
    exit 0
fi

echo "❌ 无法安装 cbmem"
echo ""
echo "请尝试以下方法之一："
echo "1. 手动编译："
echo "   cd coreboot/util/cbmem && make && sudo cp cbmem /usr/local/bin/"
echo ""
echo "2. 从 coreboot 官方获取预编译版本"
echo ""
echo "3. 使用串口控制台查看日志（推荐）"
exit 1
