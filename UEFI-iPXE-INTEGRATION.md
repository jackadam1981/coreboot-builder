# UEFI iPXE 固件集成使用指南

## 🎯 概述

本方案将 iPXE 网络启动功能真正集成到 coreboot/EDK2 固件中，提供双重网络启动保障：
1. **固件原生支持**：EDK2 内置的 UEFI 网络启动功能
2. **增强 iPXE**：专用的 RTL8168 iPXE 驱动作为补充

## 📦 包含文件

- `ipxe.efi` - RTL8168 专用 iPXE 驱动 (257 KB)
- `uefi-boot-setup.nsh` - UEFI 启动项设置脚本

## 🚀 使用方法

### 方法 1：固件原生网络启动（推荐）

1. 重启系统，进入 UEFI 启动菜单
2. 选择 "Network Boot" 或 "PXE Boot" 选项
3. 系统将自动使用 EDK2 内置的网络启动功能

### 方法 2：增强 iPXE 启动

1. 进入 EFI Shell
2. 执行以下命令之一：
   ```bash
   fs0:\ipxe.efi
   # 或者
   ipxe.efi
   ```

### 方法 3：添加到 UEFI 启动菜单

1. 进入 EFI Shell
2. 运行自动设置脚本：
   ```bash
   fs0:\uefi-boot-setup.nsh
   ```
3. 重启系统，在 UEFI 启动菜单中选择 "iPXE Network Boot"

### 方法 4：手动添加启动项

1. 进入 EFI Shell
2. 手动添加启动项：
   ```bash
   bcfg boot add 0 fs0:\ipxe.efi "iPXE Network Boot"
   ```
3. 查看启动项列表：
   ```bash
   bcfg boot dump
   ```

## 🔧 管理启动项

### 查看所有启动项
```bash
bcfg boot dump
```

### 删除 iPXE 启动项
```bash
bcfg boot rm 0
```

### 调整启动项优先级
```bash
bcfg boot mv 0 1  # 将项目 0 移动到位置 1
```

## 🌐 网络功能

iPXE 支持以下网络功能：

- **DHCP 自动获取 IP**
- **HTTP 下载**：`http://server/path/file`
- **TFTP 下载**：`tftp://server/path/file`
- **iSCSI 启动**：`iscsi://server:3260/iqn`
- **网络启动脚本**：`http://server/script.ipxe`

## 📋 示例用法

### 从网络启动 Linux
```bash
# 在 iPXE 命令行中
dhcp
kernel http://server/vmlinuz
initrd http://server/initrd.img
boot
```

### 启动 Windows PE
```bash
# 在 iPXE 命令行中
dhcp
kernel http://server/winpe.wim
boot
```

### 使用启动脚本
```bash
# 在 iPXE 命令行中
dhcp
chain http://server/boot-menu.ipxe
```

## ⚠️ 注意事项

1. **网络连接**：确保网线已连接且网络正常
2. **防火墙**：确保目标服务器端口开放
3. **文件路径**：使用正确的文件路径和文件名
4. **驱动支持**：本版本专门针对 RTL8168 网卡优化

## 🔍 故障排除

### 网络连接问题
```bash
# 在 iPXE 中检查网络状态
ifstat
ping 8.8.8.8
```

### 启动项问题
```bash
# 在 EFI Shell 中检查文件
ls fs0:\
if exist fs0:\ipxe.efi
```

### 重新设置
```bash
# 删除所有启动项并重新添加
bcfg boot rm 0
bcfg boot rm 1
bcfg boot rm 2
fs0:\uefi-boot-setup.nsh
```

## 📞 技术支持

如遇到问题，请提供以下信息：
- 主板型号和 BIOS 版本
- 网卡型号
- 错误信息截图
- 网络环境描述
