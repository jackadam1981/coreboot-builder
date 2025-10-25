# Coreboot Kaisa PXE 补丁文件

本目录包含2个**已验证可用**的补丁文件，用于修复Google Kaisa主板的PXE启动和MAC地址问题。

## 补丁文件状态

### ✅ 已成功创建（可直接使用）

#### 1. 01-puff-kconfig.patch
- **文件**: `src/mainboard/google/puff/Kconfig`
- **修改**: 添加 `select REALTEK_8168_RESET`
- **目的**: 确保RTL8168驱动的基础配置被启用
- **必要性**: ✅ 必须 - 这是其他RTL8168配置的依赖
- **状态**: ✅ 格式正确，可直接应用

#### 2. 04-net-kconfig.patch
- **文件**: `src/drivers/net/Kconfig`
- **修改**: 添加依赖关系 `depends on REALTEK_8168_RESET`
- **目的**: 确保配置依赖关系正确
- **必要性**: ✅ 必须 - 确保配置依赖关系正确
- **状态**: ✅ 格式正确，可直接应用

### ⚠️ 需要手动应用（补丁格式问题）

#### 3. 02-kaisa-config.patch
- **文件**: `configs/cml/config.kaisa.uefi`
- **修改**: 添加EDK2启动配置和PXE支持
- **内容**:
  ```
  # EDK2 Boot Configuration
  CONFIG_EDK2_BOOT_TIMEOUT=10
  CONFIG_EDK2_BOOT_MANAGER_ESCAPE=y
  
  # Custom PXE ROM support configuration
  CONFIG_EDK2_NETWORK_PXE_SUPPORT=y
  CONFIG_EDK2_LOAD_OPTION_ROMS=y
  
  # EDK2 custom build parameters
  CONFIG_EDK2_CUSTOM_BUILD_PARAMS="-D NETWORK_DRIVER_ENABLE=TRUE -D NETWORK_ENABLE=TRUE -D NETWORK_IP4_ENABLE=TRUE -D NETWORK_IP6_ENABLE=FALSE -D NETWORK_PXE_BOOT_ENABLE=TRUE -D NETWORK_HTTP_BOOT_ENABLE=FALSE -D NETWORK_SNP_ENABLE=TRUE -D NETWORK_RTEK_PCI=TRUE -D NETWORK_TLS_ENABLE=FALSE -D NETWORK_ISCSI_ENABLE=FALSE -D NETWORK_RTEK_USB=FALSE -D NETWORK_ASIX_USB3=FALSE -D NETWORK_ASIX_USB2=FALSE"
  ```
- **必要性**: ✅ 必须 - 启用PXE功能和网络驱动
- **状态**: ⚠️ 补丁格式问题，建议手动添加

#### 4. 03-r8168-driver.patch
- **文件**: `src/drivers/net/r8168.c`
- **修改**: 修复MAC地址解析bug
- **内容**: 在 `get_mac_address` 函数中：
  - 移除 `macaddr[i] = 0;` 行
  - 添加十六进制数字验证
  - 添加调试输出
- **必要性**: ✅ 必须 - 修复MAC地址变成000000000000的bug
- **状态**: ⚠️ 行号不匹配，建议手动修改

## 使用方法

### 方法1：应用可用的补丁（推荐）
```bash
cd /path/to/coreboot
patch -p1 < /path/to/patches/clean/01-puff-kconfig.patch
patch -p1 < /path/to/patches/clean/04-net-kconfig.patch
```

### 方法2：手动应用所有修改
参考上面的修改内容，手动编辑以下4个文件：
1. `src/mainboard/google/puff/Kconfig`
2. `configs/cml/config.kaisa.uefi`
3. `src/drivers/net/r8168.c`
4. `src/drivers/net/Kconfig`

### 方法3：使用本地模式编译
```bash
./docker-build-kaisa.sh --local
```
使用 `--local` 选项可以保留当前的手动修改。

## 问题说明

### 为什么02和03补丁无法应用？

1. **02-kaisa-config.patch**: 补丁文件格式问题，可能是由于文件权限或格式不兼容
2. **03-r8168-driver.patch**: 当前文件已经被修改，行号不匹配

### 解决方案

建议使用**方法2（手动应用）**或**方法3（本地模式编译）**，这样可以确保所有修改都正确应用。

## 验证修改

应用修改后，可以使用以下脚本验证：
```bash
./verify-rtl8168-modification.sh
```
