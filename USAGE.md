# 快速使用指南

## 🚀 快速开始

### 1. Fork 本仓库到您的 GitHub 账户

点击右上角的 `Fork` 按钮

### 2. 启用 GitHub Actions

1. 进入您 Fork 的仓库
2. 点击 `Actions` 标签
3. 点击 "I understand my workflows, go ahead and enable them"

### 3. 开始构建

1. 点击 `Actions` → `Build Coreboot Firmware`
2. 点击右侧的 `Run workflow` 按钮
3. 选择参数：
   - **设备 (Device)**: 选择您的设备型号（如 kaisa）
   - **启用 PXE (Enable PXE)**: 勾选以启用网络启动
   - **创建 Release**: 勾选以自动发布
4. 点击绿色的 `Run workflow` 按钮

### 4. 下载固件

构建完成后（约 30-60 分钟）：

**方式 A - 从 Artifacts 下载：**
1. 进入构建任务页面
2. 滚动到底部的 `Artifacts` 部分
3. 下载 `coreboot-firmware-xxx` 压缩包

**方式 B - 从 Releases 下载（如果创建了 Release）：**
1. 点击仓库的 `Releases` 标签
2. 下载最新的 `.rom` 固件文件和 `.sha1` 校验文件

## 📋 支持的设备选项

在 GitHub Actions 界面中可以选择：

- **kaisa** - Acer Chromebox CXI4
- **eve** - Google Pixelbook  
- **fizz** - HP Chromebox G2
- **atlas** - Google Pixelbook Go
- **samus** - Chromebook Pixel 2015
- **panther** - Chromebook Pixel 2013
- **all** - 编译所有设备（耗时较长）

## 💡 高级用法

### 自定义启动 Logo

替换仓库中的 `coreboot_logo.bmp` 文件：

1. 准备您的 Logo 文件（推荐尺寸：638 x 531 像素，BMP 格式）
2. 将文件命名为 `coreboot_logo.bmp`
3. 替换仓库根目录的同名文件
4. 手动触发构建即可应用

### 修改设备列表

编辑 `.github/workflows/build-coreboot.yml` 文件中的设备选项：

```yaml
device:
  description: '选择设备 / Select Device'
  type: choice
  options:
    - 'all - 编译所有设备'
    - 'Acer Chromebox CXI4 (kaisa)'
    - 'Your Device Name (your-codename)'  # 添加您的设备
```

### 本地测试构建

如果想在本地测试构建流程：

```bash
# 克隆 coreboot
git clone https://github.com/mrchromebox/coreboot.git
cd coreboot
git submodule update --init --checkout --recursive

# 替换 Logo（可选）
cp /path/to/your/coreboot_logo.bmp Documentation/

# 使用 Docker 构建
docker pull coreboot/coreboot-sdk:latest
docker run --rm -it -v $PWD:/home/coreboot/coreboot \
  -w /home/coreboot/coreboot coreboot/coreboot-sdk:latest \
  bash -c "git config --global --add safe.directory /home/coreboot/coreboot && \
           make crossgcc-i386 CPUS=$(nproc) && \
           ./build-uefi.sh kaisa"
```

## ⚙️ 配置选项说明

### PXE 网络启动

启用后，固件将支持：
- ✅ UEFI PXE 网络启动
- ✅ 从网络服务器加载操作系统
- ✅ 支持多种网络适配器（Intel、Realtek 等）

配置项：`CONFIG_EDK2_NETWORK_PXE_SUPPORT=y`

### 其他常用配置

在配置文件中可以添加：

```
# 启用串口调试
CONFIG_CONSOLE_SERIAL=y

# 启用 TPM
CONFIG_TPM_ENABLE=TRUE

# 调整启动超时时间（秒）
CONFIG_PLATFORM_BOOT_TIMEOUT=10
```

## 🔧 故障排除

### 构建卡在某个阶段

- 等待更长时间，EDK2 编译可能需要 20-30 分钟
- 检查 Actions 日志的详细输出

### 下载的固件文件损坏

- 使用 `.sha1` 文件验证完整性
- 重新触发构建

### Actions 权限问题

确保仓库设置中：
1. Settings → Actions → General
2. Workflow permissions 设置为 "Read and write permissions"
3. 勾选 "Allow GitHub Actions to create and approve pull requests"

## 📞 获取帮助

- 查看 [README.md](README.md) 获取更多信息
- 访问 [MrChromebox 官网](https://mrchromebox.tech/)
- 查看 [Issues](../../issues) 已知问题

---

**祝您构建顺利！** 🎉

