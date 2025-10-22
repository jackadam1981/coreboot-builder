# 本地编译说明

## 🎯 使用场景

这些脚本是**在开发机器上**运行的，用于编译和调试 Kaisa 固件。

## 📋 脚本说明

### 1. `local-build-kaisa.sh` - 完整本地编译
- **运行位置**：开发机器
- **功能**：完整编译 Kaisa 固件，包含 EDK2 PXE 支持
- **输出**：`roms/coreboot.rom`

### 2. `debug-mac-address.sh` - MAC 地址调试
- **运行位置**：开发机器
- **功能**：分析已编译固件中的 MAC 地址处理
- **用途**：调试 MAC 地址全零问题

### 3. `quick-test-mac.sh` - 快速测试
- **运行位置**：开发机器
- **功能**：快速编译和测试 MAC 地址注入
- **用途**：验证 MAC 地址处理逻辑

## 🚀 使用流程

### 步骤 1：在开发机器上编译固件
```bash
# 完整编译
sudo ./local-build-kaisa.sh

# 或者快速测试
./quick-test-mac.sh
```

### 步骤 2：调试 MAC 地址问题
```bash
# 分析固件中的 MAC 地址处理
./debug-mac-address.sh
```

### 步骤 3：传输固件到目标设备
```bash
# 将编译好的固件传输到 Kaisa 设备
scp roms/coreboot.rom user@kaisa-device:/tmp/
scp flash-coreboot-intel.sh user@kaisa-device:/tmp/
```

### 步骤 4：在目标设备上刷入固件
```bash
# 在 Kaisa 设备上运行
sudo ./flash-coreboot-intel.sh /tmp/coreboot.rom
```

## ⚠️ 重要说明

- **开发机器**：运行编译脚本，生成固件
- **目标设备**：运行刷机脚本，刷入固件
- **不要混淆**：编译脚本在开发机器上运行，刷机脚本在目标设备上运行

## 🔧 环境要求

### 开发机器
- Linux 系统
- Git
- 编译工具链
- cbfstool（可选，用于调试）

### 目标设备（Kaisa）
- Linux 系统
- sudo 权限
- 网络连接（用于下载工具）
