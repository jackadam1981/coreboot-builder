# WDS 启动优盘制作指南

## 概述

本指南介绍如何创建支持 Windows Deployment Services (WDS) 的启动优盘，用于网络启动和系统部署。

## 方法一：使用 WDS 创建启动优盘

### 1. 配置 WDS 服务器

确保 WDS 服务器已正确配置并运行。

### 2. 创建启动镜像

在 WDS 服务器上执行以下步骤：

```powershell
# 创建自定义启动镜像
New-WdsBootImage -Path "D:\WinPE_amd64\sources\boot.wim" -NewImageName "WinPE_Custom" -NewImageDescription "Custom WinPE with network drivers"

# 添加网络驱动
Add-WdsDriverPackage -Path "D:\Drivers\network" -BootImagePath "D:\WinPE_amd64\sources\boot.wim"

# 创建 ISO 文件
MakeWinPEMedia /ISO D:\WinPE_amd64 D:\WinPE_Custom.iso
```

### 3. 制作启动优盘

**Windows 系统：**
```cmd
# 使用 Rufus 工具
rufus.exe D:\WinPE_Custom.iso

# 或使用 dd 命令（Windows 10+）
dd if=D:\WinPE_Custom.iso of=\\.\PhysicalDriveX bs=4M
```

**Linux 系统：**
```bash
# 使用 dd 命令
sudo dd if=WinPE_Custom.iso of=/dev/sdX bs=4M
```

## 网络配置

### DHCP 服务器配置

在 DHCP 服务器中配置以下选项：

**Windows DHCP 服务器 (PowerShell):**
```powershell
# UEFI x64 客户端
Set-DhcpServerv4OptionValue -ScopeId 10.10.10.0 -PolicyName "PXEClient (UEFI x64)" -OptionId 067 -Value "boot\x64\wdsmgfw.efi"

# UEFI x86 客户端  
Set-DhcpServerv4OptionValue -ScopeId 10.10.10.0 -PolicyName "PXEClient (UEFI x86)" -OptionId 067 -Value "boot\x86\wdsmgfw.efi"

# BIOS 客户端 (x86 & x64)
Set-DhcpServerv4OptionValue -ScopeId 10.10.10.0 -PolicyName "PXEClient (BIOS x86 & x64)" -OptionId 067 -Value "boot\x64\wdsnbp.com"
```

**通用 DHCP 配置:**
- **Option 66 (Next Server)**: WDS 服务器 IP 地址
- **Option 67 (Boot File)**: `boot/x64/wdsmgfw.efi` (UEFI) 或 `boot/x64/wdsnbp.com` (BIOS)

## 使用方法

### 网络启动流程

1. 插入启动优盘到目标设备
2. 从优盘启动
3. 系统会自动通过 PXE 连接 WDS 服务器
4. 选择要安装的 Windows 映像
5. 开始系统部署

### 故障排除

**常见问题：**

1. **无法连接 WDS 服务器**
   - 检查网络连接
   - 验证 DHCP 配置
   - 确认 WDS 服务器运行状态

2. **启动文件加载失败**
   - 检查 WDS 启动镜像配置
   - 验证网络驱动是否正确添加

3. **部署过程中断**
   - 检查网络稳定性
   - 验证目标设备硬件兼容性

## 技术说明

- **WDS 版本**: Windows Server 2019/2022
- **启动镜像**: Windows PE 10/11
- **网络协议**: PXE, TFTP, SMB
- **支持架构**: x86, x64, ARM64