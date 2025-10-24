#!/bin/bash

# Kaisa Docker 编译脚本 - ERI 寄存器方案
# 为 Google Kaisa 主板提供 RTL8168 RTL8111H 支持（ERI 寄存器编程，避免 VPD 解析 bug）

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "Kaisa Docker 编译脚本 - ERI 寄存器版"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help              显示此帮助信息"
    echo "  -d, --dev               启动交互式开发环境"
    echo "  -c, --clean             清理编译文件"
    echo "  -f, --force             强制重新拉取镜像"
    echo "  -j, --jobs N            指定编译并行数 (默认: CPU核心数)"
    echo ""
    echo "示例:"
    echo "  $0                      # 使用 MrChromebox build-uefi.sh 编译"
    echo "  $0 --dev                # 启动开发环境"
    echo "  $0 --clean              # 清理编译文件"
    echo "  $0 --jobs 8             # 使用8个并行编译"
    echo ""
    echo "注意: 使用 MrChromebox 的 build-uefi.sh kaisa 命令编译"
    echo "      ERI 寄存器编程确保 MAC 地址持久化"
    echo ""
}

# 默认参数
DEV_MODE=false
CLEAN_MODE=false
FORCE_PULL=false
JOBS=$(nproc)

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dev)
            DEV_MODE=true
            shift
            ;;
        -c|--clean)
            CLEAN_MODE=true
            shift
            ;;
        -f|--force)
            FORCE_PULL=true
            shift
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

log_info "🐳 Kaisa Docker 编译脚本 - ERI 寄存器方案"
log_info "📍 为 Google Kaisa 主板提供 RTL8168 RTL8111H 支持（标准寄存器 + ERI 寄存器）"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/coreboot"
OUTPUT_DIR="$SCRIPT_DIR/roms"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 检查 Docker 是否安装
if ! command -v docker >/dev/null 2>&1; then
    log_error "❌ Docker 未安装，请先安装 Docker"
    log_info "💡 运行: sudo apt install docker.io"
    exit 1
fi

# 选择可用的 Docker 命令（自动回退到 sudo）
if docker images >/dev/null 2>&1; then
    log_info "✅ Docker 权限正常"
    DOCKER_CMD="docker"
else
    log_warn "⚠️ Docker 权限不足，自动使用 sudo docker"
    DOCKER_CMD="sudo docker"
fi

# 清理模式
if [ "$CLEAN_MODE" = true ]; then
    log_info "🧹 清理编译文件..."
    
    # 清理 coreboot 编译文件
    if [ -d "$BUILD_DIR" ]; then
        cd "$BUILD_DIR"
        if [ -f "Makefile" ]; then
            make clean >/dev/null 2>&1 || true
        fi
        rm -rf build/ .config
        log_info "✅ coreboot 编译文件已清理"
    fi
    
    # 清理输出目录
    if [ -d "$OUTPUT_DIR" ]; then
        rm -f "$OUTPUT_DIR"/*.rom
        log_info "✅ 输出文件已清理"
    fi
    
    # 清理 Docker 镜像（可选）
    read -p "是否清理 Docker 镜像? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        $DOCKER_CMD rmi coreboot/coreboot-sdk:latest >/dev/null 2>&1 || true
        log_info "✅ Docker 镜像已清理"
    fi
    
    log_info "🎉 清理完成！"
    exit 0
fi

# 检查 coreboot 目录是否存在
if [ ! -d "$BUILD_DIR" ]; then
    log_info "📦 克隆 MrChromebox coreboot 仓库..."
    git clone https://github.com/MrChromebox/coreboot.git "$BUILD_DIR"
    cd "$BUILD_DIR"
    git checkout MrChromebox-2509
    # 同步并更新子模块
    log_info "📦 同步并更新子模块..."
    git submodule sync --recursive || true
    git submodule update --init --checkout --recursive
else
    log_info "📦 目录已存在，放弃所有更改，使用原始 MrChromebox 代码..."
    cd "$BUILD_DIR"
    # 放弃所有本地更改
    git reset --hard HEAD
    git clean -fd
    # 更新到最新版本（如果网络失败则继续使用本地代码）
    git pull origin MrChromebox-2509 || log_warn "⚠️ 网络连接失败，使用本地代码继续编译"
    # 同步并更新子模块（确保依赖完整）
    log_info "📦 同步并更新子模块..."
    git submodule sync --recursive || true
    git submodule update --init --checkout --recursive
fi

# 应用 ERI 配置补丁（在 git reset 之后）
log_info "🔧 应用 ERI 配置补丁..."

# 修改 Kconfig：添加 depends on REALTEK_8168_RESET
sed -i '/^config RT8168_PUT_MAC_TO_ERI$/,/^config / {
    /^[[:space:]]*bool[[:space:]]*$/a\
	depends on REALTEK_8168_RESET
}' src/drivers/net/Kconfig

# 修改主板 Kconfig：添加 select RT8168_PUT_MAC_TO_ERI
if ! grep -q "select RT8168_PUT_MAC_TO_ERI" src/mainboard/google/puff/Kconfig; then
    sed -i '/select RT8168_GET_MAC_FROM_VPD/a\	select RT8168_PUT_MAC_TO_ERI' src/mainboard/google/puff/Kconfig
fi

# 修改 Makefile：在 olddefconfig 之后添加 ERI 配置
sed -i '/$(MAKE) olddefconfig/a\	@echo "CONFIG_RT8168_PUT_MAC_TO_ERI=y" >> .config' Makefile

# 修改 build-uefi.sh：在 olddefconfig 之后添加 ERI 配置
sed -i '/make olddefconfig/a\\n\t# 强制添加 ERI 配置（在 olddefconfig 之后）\n\techo "CONFIG_RT8168_PUT_MAC_TO_ERI=y" >> .config' build-uefi.sh

# 修改 r8168.c：添加对 RTL8111H revision 12-15 的支持
sed -i '/case 9:/,/break;/ {
    /break;/a\
		case 12:\
		case 13:\
		case 14:\
		case 15:\
			/* RTL8111H revision 12-15 ERI programming */\
			outl(maclo, io_base + ERIDR);\
			inl(io_base + ERIDR);\
			outl(0x8000f0e0, io_base + ERIAR);\
			inl(io_base + ERIAR);\
			outl(machi, io_base + ERIDR);\
			inl(io_base + ERIDR);\
			outl(0x800030e4, io_base + ERIAR);\
			break;
}' src/drivers/net/r8168.c

log_info "✅ ERI 配置补丁已应用"

# 检查 Docker 镜像
log_info "🐳 检查 Docker 环境..."

if [ "$FORCE_PULL" = true ] || ! $DOCKER_CMD images | grep -q "coreboot/coreboot-sdk"; then
    log_info "📥 拉取 coreboot 官方 Docker 镜像..."
    $DOCKER_CMD pull coreboot/coreboot-sdk:latest
else
    log_info "✅ coreboot/coreboot-sdk:latest 镜像已存在"
fi

# 配置 PXE ROM 支持
log_info "🔧 配置 PXE ROM 支持..."

# 定义配置项数组
PXE_CONFIGS=(
    "CONFIG_EDK2_NETWORK_PXE_SUPPORT=y"
    "CONFIG_EDK2_LOAD_OPTION_ROMS=y"
)

# 构建 EDK2 自定义构建参数
EDK2_BUILD_PARAMS="-D NETWORK_DRIVER_ENABLE=TRUE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_ENABLE=TRUE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_IP4_ENABLE=TRUE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_IP6_ENABLE=FALSE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_PXE_BOOT_ENABLE=TRUE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_HTTP_BOOT_ENABLE=FALSE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_SNP_ENABLE=TRUE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_RTEK_PCI=TRUE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_TLS_ENABLE=FALSE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_ISCSI_ENABLE=FALSE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_RTEK_USB=FALSE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_ASIX_USB3=FALSE"
EDK2_BUILD_PARAMS="$EDK2_BUILD_PARAMS -D NETWORK_ASIX_USB2=FALSE"

INTEL_CONFIGS=(
    "CONFIG_SOC_INTEL_COMMON_BLOCK_POWER_LIMIT=y"
    "CONFIG_SOC_INTEL_COMMON_BLOCK_THERMAL=y"
    "CONFIG_SOUTHBRIDGE_INTEL_COMMON_WATCHDOG=y"
    "CONFIG_EC_GOOGLE_CHROMEEC_AUTO_FAN_CTRL=y"
)

# RTL8168 驱动配置 - ERI 寄存器编程（避免 VPD 解析 bug）
RTL8168_CONFIGS=(
    "CONFIG_RT8168_PUT_MAC_TO_ERI=y"
)

# 使用 MrChromebox 的配置文件并添加自定义配置项
log_info "🔧 使用 MrChromebox 配置文件并添加自定义配置项..."

# 检查 MrChromebox 配置文件是否存在
if [ ! -f "configs/cml/config.kaisa.uefi" ]; then
    log_error "❌ 未找到 MrChromebox 配置文件: configs/cml/config.kaisa.uefi"
    log_info "💡 请确保已正确克隆 MrChromebox coreboot 仓库"
    exit 1
fi

# 备份原始配置文件
cp configs/cml/config.kaisa.uefi configs/cml/config.kaisa.uefi.backup
log_info "📦 已备份原始配置文件"

# 添加自定义配置项到现有配置文件
log_info "🔧 添加 PXE ROM 支持配置..."
echo "" >> configs/cml/config.kaisa.uefi
echo "# 自定义 PXE ROM 支持配置" >> configs/cml/config.kaisa.uefi
for config in "${PXE_CONFIGS[@]}"; do
    echo "$config" >> configs/cml/config.kaisa.uefi
done

# 添加 EDK2 自定义构建参数
log_info "🔧 添加 EDK2 自定义构建参数..."
echo "" >> configs/cml/config.kaisa.uefi
echo "# EDK2 自定义构建参数" >> configs/cml/config.kaisa.uefi
echo "CONFIG_EDK2_CUSTOM_BUILD_PARAMS=\"$EDK2_BUILD_PARAMS\"" >> configs/cml/config.kaisa.uefi

# 添加 Intel 芯片组系统稳定配置
log_info "🔧 添加 Intel 芯片组系统稳定配置..."
echo "" >> configs/cml/config.kaisa.uefi
echo "# Intel 芯片组系统稳定配置（适合 Kaisa 主板）" >> configs/cml/config.kaisa.uefi
for config in "${INTEL_CONFIGS[@]}"; do
    echo "$config" >> configs/cml/config.kaisa.uefi
done

# 添加 RTL8168 驱动配置
log_info "🔧 添加 RTL8168 驱动配置（标准寄存器 + ERI 寄存器编程）..."
echo "" >> configs/cml/config.kaisa.uefi
echo "# RTL8168 驱动配置（标准寄存器 + ERI 寄存器编程）" >> configs/cml/config.kaisa.uefi
for config in "${RTL8168_CONFIGS[@]}"; do
    echo "$config" >> configs/cml/config.kaisa.uefi
done

log_info "✅ 配置完成"

# 检查 RTL8168 驱动是否已支持 RTL8111H
log_info "🔍 检查 RTL8168 驱动 RTL8111H 支持..."

RTL8168_DRIVER_PATH='src/drivers/net/r8168.c'
if [ -f "$RTL8168_DRIVER_PATH" ]; then
    log_info "📦 找到 RTL8168 驱动文件: $RTL8168_DRIVER_PATH"
    
    # 检查是否已经支持 RTL8111H
    if grep -q "RTL8111H support" "$RTL8168_DRIVER_PATH"; then
        log_info "✅ RTL8168 驱动已支持 RTL8111H（MrChromebox 版本）"
    else
        log_warn "⚠️ RTL8168 驱动未找到 RTL8111H 支持"
    fi
    
    # 检查 ERI 支持
    if grep -q "RT8168_PUT_MAC_TO_ERI" "$RTL8168_DRIVER_PATH"; then
        log_info "✅ RTL8168 驱动已支持 ERI 寄存器编程"
    else
        log_warn "⚠️ RTL8168 驱动未找到 ERI 支持"
    fi
else
    log_warn "⚠️ 未找到 RTL8168 驱动文件"
fi

# 准备编译环境
log_info "🔧 准备 MrChromebox 编译环境..."

# 开发模式
if [ "$DEV_MODE" = true ]; then
    log_info "🐳 启动交互式开发环境..."
    log_info "📁 映射目录："
    log_info "   - 源码目录: $(pwd) -> /coreboot"
    log_info "   - 输出目录: $OUTPUT_DIR -> /output"
    log_info ""
    log_info "🔧 在容器内可以执行："
    log_info "   - ./build-uefi.sh kaisa    # MrChromebox 编译命令"
    log_info "   - make menuconfig           # 配置编译选项"
    log_info "   - make clean                # 清理"
    log_info "   - exit                      # 退出容器"
    log_info ""
    
    # 启动交互式 Docker 容器
    $DOCKER_CMD run --rm -it \
        -v "$(pwd)":/coreboot \
        -v "$OUTPUT_DIR":/output \
        -w /coreboot \
        coreboot/coreboot-sdk:latest \
        bash
    exit 0
fi

# 编译模式
log_info "🐳 使用 MrChromebox 编译脚本编译 coreboot..."
log_info "📁 映射目录："
log_info "   - 源码目录: $(pwd) -> /coreboot"
log_info "   - 输出目录: $OUTPUT_DIR -> /output"
log_info "   - 编译命令: ./build-uefi.sh kaisa"

# 使用 MrChromebox 编译脚本
$DOCKER_CMD run --rm --user root \
    -v "$(pwd)":/home/coreboot/coreboot \
    -v "$OUTPUT_DIR":/home/coreboot/roms \
    -w /home/coreboot/coreboot \
    coreboot/coreboot-sdk:latest \
    bash -c "git config --global --add safe.directory /home/coreboot/coreboot && \
             echo '🔧 使用 MrChromebox build-uefi.sh 编译 kaisa...' && \
             if [ -f 'patch-build-process.sh' ]; then \
                 echo '应用 ERI 配置补丁...' && \
                 ./patch-build-process.sh; \
             fi && \
             ./build-uefi.sh kaisa && \
             chmod 644 /home/coreboot/roms/*.rom && \
             echo '✅ MrChromebox 编译完成'"

# 检查编译结果
ROM_FILE=$(ls "$OUTPUT_DIR"/coreboot_*.rom 2>/dev/null | head -1)
if [ -n "$ROM_FILE" ]; then
    log_info "✅ 编译成功！"
    
    # 显示 ROM 信息
    log_info "📦 ROM 文件信息："
    ls -lh "$ROM_FILE"
    
    # 显示映射的源码修改
    log_info "📝 源码修改记录："
    if grep -q "RTL8111H support" "src/drivers/net/r8168.c"; then
        log_info "   - RTL8168 驱动已支持 RTL8111H（MrChromebox 版本）"
    fi
    if [ -f "configs/cml/config.kaisa.uefi.backup" ]; then
        log_info "   - 配置文件已添加自定义配置项（基于 MrChromebox 配置）"
        log_info "   - 已启用 ERI 寄存器编程（双重保险模式）"
    fi
    
    # 检查 CBFS 内容
    log_info "🔍 检查 CBFS 内容："
    if [ -f "coreboot/build/cbfstool" ]; then
        coreboot/build/cbfstool "$ROM_FILE" print | grep -E "(rt8168|macaddress)" || echo "未找到 MAC 地址相关条目"
    elif command -v cbfstool >/dev/null 2>&1; then
        cbfstool "$ROM_FILE" print | grep -E "(rt8168|macaddress)" || echo "未找到 MAC 地址相关条目"
    else
        log_warn "cbfstool 未找到，无法检查 CBFS 内容"
    fi
    
    log_info "🎉 编译完成！ROM 文件已保存到: $ROM_FILE"
else
    log_error "❌ 编译失败！"
    exit 1
fi

echo ""
log_info "🚀 MrChromebox Docker 编译完成！"
log_info "📁 ROM 文件位置: $ROM_FILE"
log_info "🔧 可以使用 flash-coreboot-intel.sh 脚本刷入固件"
