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

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
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
    echo "  -t, --test              测试模式：只验证补丁应用，不进行编译"
    echo "  -d, --dev               启动交互式开发环境"
    echo "  -c, --clean             清理编译文件"
    echo "  -f, --force             强制重新拉取镜像"
    echo "  -j, --jobs N            指定编译并行数 (默认: CPU核心数)"
    echo ""
    echo "示例:"
    echo "  $0                      # 完整编译模式"
    echo "  $0 --test               # 测试模式：只验证补丁应用"
    echo "  $0 --dev                # 启动开发环境"
    echo "  $0 --clean              # 清理编译文件"
    echo "  $0 --jobs 8             # 使用8个并行编译"
    echo ""
    echo "注意: 使用 MrChromebox 的 build-uefi.sh kaisa 命令编译"
    echo "      ERI 寄存器编程确保 MAC 地址持久化"
    echo ""
}

# 默认参数
TEST_MODE=false
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
        -t|--test)
            TEST_MODE=true
            shift
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
        # 使用 sudo 清理 build 目录，避免权限问题
        sudo rm -rf build/ .config 2>/dev/null || rm -rf build/ .config 2>/dev/null || true
        log_info "✅ coreboot 编译文件已清理"
    fi
    
    # 清理输出目录
    if [ -d "$OUTPUT_DIR" ]; then
        rm -f "$OUTPUT_DIR"/*.rom
        rm -f "$OUTPUT_DIR"/*.sha1
        log_info "✅ 输出文件已清理 (ROM 和 SHA1 文件)"
    fi
    
    # 清理设备目录（刷机时创建的）
    if [ -d "$SCRIPT_DIR" ]; then
        cd "$SCRIPT_DIR"
        device_dirs=$(ls -d device_* 2>/dev/null | wc -l)
        if [ "$device_dirs" -gt 0 ]; then
            log_info "🧹 发现 $device_dirs 个设备目录"
            read -p "是否清理设备目录? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                for device_dir in device_*; do
                    if [ -d "$device_dir" ]; then
                        log_info "🧹 清理设备目录: $device_dir"
                        if sudo rm -rf "$device_dir" 2>/dev/null; then
                            log_success "✅ 设备目录已清理: $device_dir"
                        else
                            log_warn "⚠️ 无法清理设备目录: $device_dir (需要 root 权限)"
                            log_info "💡 请手动运行: sudo rm -rf $device_dir"
                        fi
                    fi
                done
            else
                log_info "⏭️ 跳过设备目录清理"
            fi
        fi
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
    log_info "📦 目录已存在，恢复原始 MrChromebox 代码..."
    cd "$BUILD_DIR"
    # 始终重置代码到干净状态，确保补丁能正确应用
    git reset --hard HEAD
    git clean -fd
    # 更新到最新版本（如果网络失败则继续使用本地代码）
    git pull origin MrChromebox-2509 || log_warn "⚠️ 网络连接失败，使用本地代码继续编译"
    # 同步并更新子模块（确保依赖完整）
    log_info "📦 同步并更新子模块..."
    git submodule sync --recursive || true
    git submodule update --init --checkout --recursive
fi

# 检查 Docker 镜像
log_info "🐳 检查 Docker 环境..."

if [ "$FORCE_PULL" = true ] || ! $DOCKER_CMD images | grep -q "coreboot/coreboot-sdk"; then
    log_info "📥 拉取 coreboot 官方 Docker 镜像..."
    $DOCKER_CMD pull coreboot/coreboot-sdk:latest
else
    log_info "✅ coreboot/coreboot-sdk:latest 镜像已存在"
fi


# 应用补丁
log_info "🔧 应用 RTL8111H 修复补丁..."

# 检查补丁文件是否存在
PATCH_DIR="$SCRIPT_DIR/patches"
if [ -d "$PATCH_DIR" ]; then
    log_info "📦 发现补丁目录，应用补丁..."
    
    # 进入 coreboot 目录
    cd "$BUILD_DIR"
    
    # 应用所有补丁
    for patch_file in "$PATCH_DIR"/*.patch; do
        if [ -f "$patch_file" ]; then
            patch_name=$(basename "$patch_file")
            log_info "🔧 应用补丁: $patch_name"
            
            # 应用补丁
            if patch -p1 < "$patch_file" >/dev/null 2>&1; then
                log_success "✅ 补丁应用成功: $patch_name"
            else
                log_warn "⚠️ 补丁应用失败: $patch_name"
                # 显示补丁文件内容用于调试
                log_debug "补丁文件内容:"
                head -10 "$patch_file" | sed 's/^/    /'
            fi
        fi
    done
    
    log_info "🎉 所有补丁应用完成！"
else
    log_warn "⚠️ 补丁目录不存在，跳过补丁应用"
fi

# 测试模式：只验证补丁应用，不进行编译
if [ "$TEST_MODE" = true ]; then
    log_info "🧪 测试模式：验证补丁应用结果..."
    
    # 详细验证补丁应用结果
    log_info "🔍 详细验证补丁应用结果..."
    
    # 检查 RTL8111H 支持
    if grep -q "case 12:" src/drivers/net/r8168.c; then
        log_success "✅ RTL8111H revision 12-15 支持已添加"
        echo "   📝 相关代码："
        grep -A 5 "case 12:" src/drivers/net/r8168.c | sed 's/^/      /'
    else
        log_warn "⚠️ RTL8111H revision 12-15 支持未找到"
    fi
    
    # 检查 ERI 配置
    if grep -q "select RT8168_PUT_MAC_TO_ERI" src/mainboard/google/puff/Kconfig; then
        log_success "✅ ERI 配置已启用"
    else
        log_warn "⚠️ ERI 配置未启用"
    fi
    
    # 检查 ERI 依赖
    if grep -q "depends on REALTEK_8168_RESET" src/drivers/net/Kconfig; then
        log_success "✅ ERI 依赖关系已修复"
    else
        log_warn "⚠️ ERI 依赖关系未修复"
    fi
    
    # 检查 Kaisa 配置
    if grep -q "CONFIG_RT8168_PUT_MAC_TO_ERI=y" configs/cml/config.kaisa.uefi; then
        log_success "✅ Kaisa 配置已更新"
    else
        log_warn "⚠️ Kaisa 配置未更新"
    fi
    
    # 检查调试信息
    if grep -q "Programming MAC to ERI registers" src/drivers/net/r8168.c; then
        log_success "✅ ERI 调试信息已添加"
    else
        log_warn "⚠️ ERI 调试信息未添加"
    fi
    
    # 检查 VPD 解析修复
    if grep -q "offset += vpd\[offset + 1\] + 2" src/drivers/net/r8168.c; then
        log_success "✅ VPD 解析修复已应用"
        echo "   📝 修复内容："
        grep -A 1 -B 1 "offset += vpd\[offset + 1\] + 2" src/drivers/net/r8168.c | sed 's/^/      /'
    else
        log_warn "⚠️ VPD 解析修复未应用"
    fi
    
    log_info "🎉 测试模式完成！补丁应用验证结束。"
    log_info "💡 如需进行完整编译，请运行: $0"
    exit 0
fi

# 准备编译环境
log_info "🔧 准备 MrChromebox 编译环境..."

# 自动清理输出目录
if [ -d "$OUTPUT_DIR" ]; then
    log_info "🧹 自动清理输出目录..."
    rm -f "$OUTPUT_DIR"/*.rom
    rm -f "$OUTPUT_DIR"/*.sha1
    log_info "✅ 输出目录已清理 (ROM 和 SHA1 文件)"
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
