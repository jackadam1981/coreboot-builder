# Coreboot RTL8168 RTL8111H 支持项目

## 📋 项目概述

本项目为 Google Kaisa 主板提供 RTL8168 网卡驱动对 RTL8111H 芯片的支持，通过修改 coreboot 源码解决 PXE 网络引导功能中的 **MAC 地址全0问题**。

## 🎯 项目目标

- **解决 PXE 引导问题**：修复 RTL8111H 芯片在 PXE 网络引导时 MAC 地址显示为全0的问题
- **支持 RTL8111H 芯片**：兼容 revision 12-15 及更新的变体
- **实现 MAC 地址持久化**：确保 MAC 地址在网卡重置后能够正确保持
- **提供 ERI 方案**：ERI 寄存器编程（避免 VPD 解析 bug，确保 MAC 地址持久化）
- **自动化构建**：一键构建和验证流程

## 🔧 技术方案

### 问题背景
RTL8111H 芯片（revision 12-15）在 PXE 网络引导时会出现 MAC 地址全0的问题，导致：
- PXE 服务器无法识别设备
- 网络引导失败
- 无法获取 IP 地址

### ERI 寄存器编程方案
- **ERI 配置**：`CONFIG_RT8168_PUT_MAC_TO_ERI=y` - 将 MAC 地址写入 ERI 寄存器
- **原理**：直接通过 ERI 寄存器编程实现 MAC 地址持久化，避免 VPD 解析 bug
- **适用**：所有主板（包括 Google Kaisa）
- **优势**：最可靠的解决方案，避免 VPD 解析问题，直接硬件控制
- **解决效果**：彻底解决 PXE 引导时 MAC 地址全0问题

### 技术细节
- **ERI 编程**：将 MAC 地址写入网卡的 ERI 寄存器，确保持久化
- **避免 VPD bug**：不依赖 VPD 解析，直接使用默认 MAC 地址或 CBFS 中的 MAC 地址
- **硬件控制**：直接控制网卡硬件，确保 MAC 地址在重置后保持

### ✅ 推荐配置

**重要**：使用 ERI 寄存器编程，避免 VPD 解析 bug：

```kconfig
# ERI 寄存器编程方案（推荐）
CONFIG_RT8168_PUT_MAC_TO_ERI=y

# 这种配置避免了 VPD 解析 bug，直接通过 ERI 寄存器确保持久化
```

## 📁 项目结构

```
coreboot-builder/
├── coreboot/                    # coreboot 源码目录
│   ├── src/drivers/net/r8168.c # RTL8168 驱动源码
│   └── configs/cml/            # 主板配置文件
├── roms/                       # 编译输出目录
├── docker-build-kaisa.sh      # 统一构建脚本（ERI 寄存器编程，解决 PXE MAC 全0问题）
├── flash-coreboot-intel.sh    # 固件刷写脚本
├── verify-rtl8168-modification.sh # 验证脚本
└── README.md                   # 项目说明
```

## 🚀 快速开始

### 1. 环境准备

```bash
# 安装 Docker
sudo apt install docker.io

# 添加用户到 docker 组
sudo usermod -aG docker $USER
newgrp docker
```

### 2. 构建固件（解决 PXE MAC 全0问题）

```bash
# 使用 VPD 方案构建（推荐）
./docker-build-kaisa-vpd.sh
```

### 3. 验证修改

```bash
# 验证 RTL8111H 支持是否正确应用
./verify-rtl8168-modification.sh
```

### 4. 刷写固件

```bash
# 刷写到主板
./flash-coreboot-intel.sh
```

### 5. 测试 PXE 引导

```bash
# 重启后进入 UEFI 设置，启用网络引导
# 检查 MAC 地址是否正确显示（不再是全0）
# 验证 PXE 服务器能否识别设备
```

## 🔍 技术实现

### 问题根源
RTL8111H 芯片（revision 12-15）在网卡初始化时，MAC 地址没有正确写入 ERI 寄存器，导致：
1. 网卡重置后 MAC 地址丢失
2. PXE 引导时显示 MAC 地址为全0
3. 网络服务器无法识别设备

### RTL8111H 支持代码

在 `program_mac_address` 函数中添加了以下支持：

```c
/* RTL8111H support - 解决 PXE MAC 全0问题，支持 revision 12-15 */
switch (pci_read_config8(dev, PCI_REVISION_ID)) {
case 12: /* RTL8111H support */
case 13: /* RTL8111H support */
case 14: /* RTL8111H support */
case 15: /* RTL8111H support */
default: /* Support newer RTL8111H variants */
    /* Use the same ERI programming as revision 9 for RTL8111H */
    /* 确保 MAC 地址正确写入 ERI 寄存器，解决 PXE 引导问题 */
    outl(maclo, io_base + ERIDR);
    inl(io_base + ERIDR);
    outl(0x8000f0e0, io_base + ERIAR);
    inl(io_base + ERIAR);
    outl(machi, io_base + ERIDR);
    inl(io_base + ERIDR);
    outl(0x800030e4, io_base + ERIAR);
    break;
}
```

### 解决原理
1. **检测芯片版本**：识别 RTL8111H revision 12-15
2. **写入 ERI 寄存器**：使用与 revision 9 相同的 ERI 编程方法
3. **MAC 地址持久化**：确保 MAC 地址在网卡重置后保持
4. **PXE 引导修复**：解决 PXE 引导时 MAC 地址全0的问题

### 自动修改机制

构建脚本会自动：
1. 克隆/更新 MrChromebox coreboot 源码
2. 应用 Kaisa 主板配置
3. 修改 RTL8168 驱动添加 RTL8111H 支持
4. 在 Docker 环境中编译固件
5. 生成可刷写的 ROM 文件

## 📊 验证方法

### 配置验证
- `CONFIG_REALTEK_8168_RESET=y` - 驱动编译已启用
- `CONFIG_RT8168_GET_MAC_FROM_VPD=y` - VPD 方案已启用

### 源码验证
- 源文件包含 RTL8111H 支持代码
- 支持 revision 12-15 和更新的变体

### 编译验证
- 编译后的对象文件包含 RTL8111H 字符串
- ROM 文件包含 RTL8168 驱动

### PXE 功能验证
- **UEFI 设置中检查**：网络设备 MAC 地址不再显示为全0
- **PXE 服务器日志**：能够识别设备并分配 IP 地址
- **网络引导测试**：成功从网络启动操作系统

## 🛠️ 开发说明

### 修改驱动代码

如需修改 RTL8168 驱动，编辑 `docker-build-kaisa.sh` 中的 sed 命令：

```bash
# 在 ERI 条件编译块中添加 RTL8111H 支持（备用方案）
sed -i '/case 9:/,/break;/c\
    # 修改内容
' "$RTL8168_DRIVER_PATH"

# 在 program_mac_address 函数结尾添加 RTL8111H 支持（主方案）
sed -i '/^static void program_mac_address/,/^}$/{
    # 修改内容
}' "$RTL8168_DRIVER_PATH"
```

### 添加新主板支持

1. 在 `coreboot/configs/` 下添加主板配置文件
2. 修改构建脚本中的配置路径
3. 根据需要选择 VPD 或 ERI 方案

## 🔧 故障排除

### 常见问题

1. **Docker 权限问题**
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

2. **构建失败**
   - 检查网络连接
   - 确保 Docker 正常运行
   - 查看构建日志

3. **验证失败**
   - 确保构建完成
   - 检查配置文件是否正确
   - 验证源码修改是否应用

### 调试方法

```bash
# 查看构建日志
./docker-build-kaisa.sh 2>&1 | tee build.log

# 检查配置
grep "RT8168" coreboot/.config

# 验证源码修改
grep -A 10 "RTL8111H support" coreboot/src/drivers/net/r8168.c
```

## 📝 版本历史

- **v1.0** - 初始版本，支持 RTL8111H revision 12-15
- **v1.1** - 添加 VPD 方案支持
- **v1.2** - 完善验证脚本和文档

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进项目。

## 📄 许可证

本项目基于 coreboot 的 GPL-2.0 许可证。

## ⚠️ 免责声明

刷写固件存在风险，可能导致设备无法启动。请确保：
- 了解刷写风险
- 备份原始固件
- 在测试环境中验证
- 自行承担使用风险
