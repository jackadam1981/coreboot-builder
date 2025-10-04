# Coreboot Builder with iPXE Integration

这个项目提供了编译集成 iPXE 的 Coreboot 固件的工作流，支持网络启动和 WDS 服务器连接。

## 功能特性

- ✅ 编译 MrChromebox Coreboot 固件（UEFI）
- ✅ 集成 iPXE 网络启动功能
- ✅ 支持 RTL8111H/RTL8168 网卡
- ✅ 生成 iPXE EFI 和 ISO 文件
- ✅ 智能 WDS 服务器自动发现
- ✅ 完整的网络启动解决方案

## 快速开始

### 1. 运行工作流

1. 进入 GitHub Actions 页面
2. 选择 "Build Coreboot Firmware" 工作流
3. 点击 "Run workflow"
4. 可选择创建 Release 发布

### 2. 下载固件

构建完成后，下载以下文件：

**固件文件：**
- `coreboot_edk2-kaisa-mrchromebox_*.rom` - 集成 iPXE 版本（推荐）
- `coreboot_kaisa_without_ipxe.rom` - 原始版本

**iPXE 启动文件：**
- `ipxe_x64.efi` - iPXE EFI 应用程序（支持 DHCP 自动 PXE 引导）

### 3. 刷写固件

```bash
# 刷写集成 iPXE 版本
flashrom -p internal -w coreboot_edk2-kaisa-mrchromebox_*.rom
```

## 详细文档

- [WDS 启动优盘制作指南](docs/WDS_Boot_Disk_Guide.md) - 详细的启动优盘制作说明
- [网络配置说明](docs/Network_Configuration.md) - DHCP 和 WDS 服务器配置
- [故障排除指南](docs/Troubleshooting.md) - 常见问题解决方案

## 支持的硬件

- **设备**: Acer Chromebox CXI4 (kaisa)
- **网卡**: RTL8111H (兼容 RTL8168)
- **架构**: x86_64 UEFI

## 网络启动功能

### 自动 WDS 服务器发现

iPXE 会自动尝试以下服务器地址：
- 网关地址
- 192.168.0.10, 192.168.1.10, 192.168.10.10
- 10.0.0.10, 10.0.1.10, 10.0.10.10
- 172.16.0.10

### 支持的启动文件

- `bootmgr.efi` - Windows WDS 启动管理器
- `bootx64.efi` - 通用 UEFI 启动文件

## 使用方法

### 固件集成 iPXE

刷写集成版本固件后，启动菜单会显示 iPXE 选项，无需外部设备。

### DHCP 自动引导

配置 DHCP 服务器，iPXE 会自动通过 PXE 引导 WDS。

### 手动加载

在 UEFI Shell 中手动加载 `ipxe_x64.efi` 文件。

## 技术说明

- **Coreboot 版本**: MrChromebox (包含 EDK2 网络栈支持)
- **iPXE 版本**: 最新版本，包含完整网络驱动
- **编译环境**: GitHub Actions + Docker
- **输出格式**: UEFI EFI 应用程序和 ISO 镜像

## 许可证

本项目遵循相应的开源许可证。请查看各组件项目的许可证信息。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目。