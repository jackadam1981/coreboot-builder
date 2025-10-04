# WDS 启动优盘制作指南

## 概述

本指南介绍如何创建支持 Windows Deployment Services (WDS) 的启动优盘，用于网络启动和系统部署。

## 方法一：使用 iPXE ISO 制作网络启动优盘

### 下载 iPXE 文件

从 GitHub Actions 构建产物中下载以下文件：
- `ipxe_x64.efi` - iPXE EFI 应用程序
- `ipxe_boot.iso` - iPXE ISO 镜像

### 使用 Ventoy（推荐）

1. **安装 Ventoy**：
   - 下载 Ventoy 并安装到 USB 设备
   - 创建 Ventoy 分区

2. **添加 iPXE ISO**：
   ```bash
   # 直接将 ISO 文件复制到 Ventoy 分区
   cp ipxe_boot.iso /path/to/ventoy/partition/
   ```

3. **启动**：
   - 从 Ventoy 启动盘启动
   - 选择 `ipxe_boot.iso` 进入 iPXE 环境

### 传统制作方法

**Windows 系统：**
```cmd
# 使用 Rufus 工具
rufus.exe ipxe_boot.iso
```

**Linux 系统：**
```bash
# 使用 dd 命令
sudo dd if=ipxe_boot.iso of=/dev/sdX bs=4M
```

### 特点

- ✅ 支持所有主流网卡驱动
- ✅ 智能 WDS 服务器自动发现
- ✅ 纯网络启动，体积小
- ✅ 支持 DHCP 自动配置

## 方法二：通过 WDS 创建 Windows 部署启动优盘

### WDS 服务器端操作

#### 1. 使用 WDSUTIL 命令行工具

```cmd
# 创建捕获镜像
WDSUTIL /New-CaptureImage /Image:"Capture Image" /ImageType:Boot /Architecture:x64 /FilePath:"D:\Capture.wim"

# 创建启动镜像
WDSUTIL /Add-Image /ImageFile:"D:\Boot.wim" /ImageType:Boot /Architecture:x64

# 创建多播传输
WDSUTIL /New-MulticastTransmission /Transmission:"Deploy Image" /Image:"Install Image" /ImageGroup:"ImageGroup1" /MulticastType:AutoCast
```

#### 2. 使用 WDS 管理控制台

1. 打开 **Windows Deployment Services** 管理控制台
2. 展开服务器节点，右键点击 **"Boot Images"**
3. 选择 **"Add Boot Image"**
4. 浏览到 Windows PE 镜像文件（通常位于 `C:\Windows\System32\Recovery\Winre.wim`）
5. 设置镜像名称和描述
6. 完成添加后，右键点击新添加的启动镜像
7. 选择 **"Create Capture Boot Image"**
8. 选择 **"Create Boot Image from Existing Boot Image"**
9. 设置捕获镜像的存储位置
10. 完成创建

#### 3. 生成启动优盘 ISO

```cmd
# 使用 WDSUTIL 导出启动镜像
WDSUTIL /Export-Image /Image:"Boot Image Name" /ImageType:Boot /Architecture:x64 /DestinationImage /FilePath:"D:\BootImage.iso"

# 或使用 DISM 工具
DISM /Export-Image /SourceImageFile:"D:\Boot.wim" /SourceIndex:1 /DestinationImageFile:"D:\BootImage.iso" /Compress:Maximum
```

### 制作启动优盘

1. 使用 Rufus 或类似工具将 ISO 写入 USB 设备
2. 确保 USB 设备支持 UEFI 启动
3. 测试启动优盘功能

## 方法三：使用 Windows ADK 创建自定义启动镜像

### 安装 Windows ADK

1. 下载 Windows Assessment and Deployment Kit (ADK)
2. 安装时选择 **"Deployment Tools"** 和 **"Windows Preinstallation Environment (Windows PE)"**

### 创建自定义 Windows PE

```cmd
# 复制 Windows PE 文件
copype amd64 D:\WinPE_amd64

# 挂载 Windows PE 镜像
DISM /Mount-Image /ImageFile:"D:\WinPE_amd64\media\sources\boot.wim" /Index:1 /MountDir:"D:\WinPE_amd64\mount"

# 添加网络驱动和 WDS 客户端
DISM /Add-Package /Image:"D:\WinPE_amd64\mount" /PackagePath:"D:\WinPE_amd64\packages\WinPE-WDS-Tools.cab"

# 卸载镜像
DISM /Unmount-Image /MountDir:"D:\WinPE_amd64\mount" /Commit

# 创建 ISO 文件
MakeWinPEMedia /ISO D:\WinPE_amd64 D:\WinPE_Custom.iso
```

## 网络配置

### DHCP 服务器配置

在 DHCP 服务器中配置以下选项：

- **Option 66 (Next Server)**: WDS 服务器 IP 地址
- **Option 67 (Boot File Name)**: 启动文件名（如 `bootmgr.efi`）

### iPXE 自动发现

iPXE 启动盘会自动尝试以下 WDS 服务器地址：

- 网关地址
- 192.168.0.10, 192.168.1.10, 192.168.10.10
- 10.0.0.10, 10.0.1.10, 10.0.10.10
- 172.16.0.10

## 使用方法

### 网络启动流程

1. 插入启动优盘到目标设备
2. 从 USB 设备启动
3. 自动获取网络配置（DHCP）
4. 连接到 WDS 服务器
5. 选择要部署的操作系统镜像
6. 开始网络部署

### 故障排除

如果自动连接失败，可以手动配置：

```bash
# 在 iPXE shell 中
iPXE> set next-server 192.168.1.100
iPXE> chain tftp://${next-server}/bootmgr.efi
```

## 常见问题

### Q: 启动优盘无法识别网卡
A: 确保使用包含所有网卡驱动的 iPXE ISO，或使用 Windows PE 启动盘

### Q: 无法连接到 WDS 服务器
A: 检查网络连接和 DHCP 配置，确认 WDS 服务器地址正确

### Q: 启动镜像损坏
A: 重新下载或重新创建启动镜像，检查文件完整性

## 总结

选择合适的启动优盘制作方法：

- **iPXE ISO**: 适合纯网络启动，体积小，启动快
- **WDS 启动盘**: 适合 Windows 系统部署，功能完整
- **自定义 Windows PE**: 适合需要特定驱动或工具的场景

根据实际需求选择最适合的方案。
