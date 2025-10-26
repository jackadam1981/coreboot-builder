# Coreboot Builder - RTL8111H PXE MAC 地址修复项目

## 🎯 项目目标

修复 Google Kaisa 主板上 RTL8111H 芯片在 PXE 网络引导时 MAC 地址显示为 `000000000000` 的问题，实现正确的 MAC 地址持久化。

## 🔍 问题分析

### 根本原因
1. **VPD 解析格式不匹配**：coreboot 的 VPD 解析逻辑与 Google VPD 2.0 格式不兼容
2. **ERI 编程支持缺失**：原始代码不支持 RTL8111H revision 12-15 的 ERI 寄存器编程
3. **MAC 地址解析bug**：`get_mac_address` 函数存在关键bug，导致MAC地址被重置为全零
4. **MAC 地址无法持久化**：导致 PXE 启动时 MAC 地址被重置为全零

### 技术方案
- **VPD 解析修复**：使用正确的 `vpd_find()` 函数解析 Google VPD 2.0 格式
- **ERI 编程支持**：添加 RTL8111H revision 12-15 的 ERI 寄存器编程
- **MAC地址解析修复**：修复 `get_mac_address` 函数中的关键bug
- **PXE 支持**：启用 EDK2 网络模块和 PXE 引导功能

## 🛠️ 必须修改的配置项

### 📋 修改清单表格

| 序号 | 修改类型 | 文件路径 | 配置项/修改内容 | 是否必须 | 优先级 | 备注 |
|------|----------|----------|-----------------|----------|---------|------|
| 1 | Kconfig配置 | `src/mainboard/google/puff/Kconfig` | `select RT8168_PUT_MAC_TO_ERI` | ✅ 必须 | 高 | ERI寄存器编程 |
| 2 | Kconfig配置 | `src/mainboard/google/puff/Kconfig` | `select RT8168_GET_MAC_FROM_VPD` | ✅ 必须 | 高 | 从VPD读取MAC |
| 3 | Kconfig配置 | `src/mainboard/google/puff/Kconfig` | `select RT8168_SUPPORT_LEGACY_VPD_MAC` | ✅ 必须 | 高 | 传统VPD格式支持 |
| 4 | Kconfig配置 | `src/mainboard/google/puff/Kconfig` | `select REALTEK_8168_RESET` | ✅ 必须 | 高 | 启用RTL8168驱动 |
| 5 | 主板配置 | `configs/cml/config.kaisa.uefi` | `CONFIG_EDK2_NETWORK_PXE_SUPPORT=y` | ✅ 必须 | 高 | PXE支持 |
| 6 | 主板配置 | `configs/cml/config.kaisa.uefi` | `CONFIG_EDK2_LOAD_OPTION_ROMS=y` | ✅ 必须 | 高 | ROM加载支持 |
| 7 | 主板配置 | `configs/cml/config.kaisa.uefi` | `CONFIG_EDK2_BOOT_TIMEOUT=10` | ❓ 可能必须 | 中 | 启动超时设置（默认3秒可能太短） |
| 8 | 主板配置 | `configs/cml/config.kaisa.uefi` | `CONFIG_EDK2_BOOT_MANAGER_ESCAPE=y` | ❓ 可能必须 | 中 | 启动管理器键（默认F2，Escape更通用） |
| 9 | 主板配置 | `configs/cml/config.kaisa.uefi` | `CONFIG_EDK2_CUSTOM_BUILD_PARAMS` | ✅ 必须 | 高 | EDK2网络驱动启用 |
| 10 | 源码修改 | `src/drivers/net/r8168.c` | VPD解析修复（vpd_find） | ✅ 必须 | 高 | 修复VPD解析 |
| 11 | 源码修改 | `src/drivers/net/r8168.c` | RTL8111H ERI编程支持 | ✅ 必须 | 高 | 添加case 12-15 |
| 12 | 源码修改 | `src/drivers/net/r8168.c` | MAC地址解析bug修复 | ✅ 必须 | 高 | 防止MAC地址重置 |
| 13 | 依赖修复 | `src/drivers/net/Kconfig` | `depends on REALTEK_8168_RESET` | ✅ 必须 | 高 | 修复依赖关系 |

### 🔍 必须性分析

#### ✅ 绝对必须的修改（核心功能）
- **序号 1-4**：RTL8168驱动基础配置 - 没有这些，驱动无法工作
- **序号 5-6**：PXE基础支持 - 没有这些，PXE功能无法启用
- **序号 9**：EDK2网络驱动启用 - 没有这个，EDK2默认不启用网络功能
- **序号 10-12**：源码修复 - 这些是解决MAC地址问题的核心修复
- **序号 13**：依赖关系修复 - 确保配置正确应用

#### ❓ 可能必须的修改（用户体验关键）
- **序号 7**：`CONFIG_EDK2_BOOT_TIMEOUT=10` - 启动超时设置（默认3秒可能太短，用户来不及按启动键）
- **序号 8**：`CONFIG_EDK2_BOOT_MANAGER_ESCAPE=y` - 启动管理器快捷键（Escape比F2更通用，兼容性更好）

#### 🎯 下一步分析目标
我们需要测试：
1. **最小配置**：只保留序号1-6, 9-13的修改（包含EDK2网络驱动）
2. **PXE启动菜单**：是否能在最小配置下正常显示
3. **MAC地址功能**：是否能在最小配置下正常工作
4. **启动体验**：测试默认3秒超时是否足够，F2键是否可用

#### 🧪 测试方案
```bash
# 测试最小配置
# 1. 先测试核心功能配置（序号1-6, 9-13）
# 2. 如果启动菜单显示时间太短，添加序号7
# 3. 如果F2键不工作，添加序号8
# 4. 逐步优化用户体验配置
```

#### 🔍 关键发现：启动配置分析
**默认配置**：
- `PLATFORM_BOOT_TIMEOUT = 3`（默认3秒）
- `BOOT_MANAGER_ESCAPE = FALSE`（默认F2键）

**我们的优化**：
- 超时时间：3秒 → 10秒（给用户更多时间）
- 启动键：F2 → Escape（更通用，兼容性更好）

#### 🔍 关键发现：EDK2_CUSTOM_BUILD_PARAMS 是必须的！
**原因**：EDK2默认配置中网络功能是关闭的：
- `NETWORK_DRIVER_ENABLE = FALSE`（默认）
- `NETWORK_PXE_BOOT = FALSE`（默认）
- `NETWORK_RTEK_PCI = FALSE`（默认）

**必须通过自定义构建参数启用**：
```bash
-D NETWORK_DRIVER_ENABLE=TRUE
-D NETWORK_ENABLE=TRUE  
-D NETWORK_PXE_BOOT_ENABLE=TRUE
-D NETWORK_RTEK_PCI=TRUE
```

### 1. RTL8168 驱动配置 (puff/Kconfig)

```kconfig
# 在 src/mainboard/google/puff/Kconfig 的 BOARD_GOOGLE_BASEBOARD_PUFF 中添加：
select RT8168_PUT_MAC_TO_ERI              # 启用 ERI 寄存器编程
select RT8168_GET_MAC_FROM_VPD            # 从 VPD 读取 MAC 地址
select RT8168_SUPPORT_LEGACY_VPD_MAC      # 支持传统 VPD MAC 格式
select REALTEK_8168_RESET                 # 启用 RTL8168 重置功能
```

### 2. Kaisa 主板配置 (config.kaisa.uefi)

```kconfig
# 在 configs/cml/config.kaisa.uefi 中添加：
# Custom PXE ROM support configuration
CONFIG_EDK2_NETWORK_PXE_SUPPORT=y
CONFIG_EDK2_LOAD_OPTION_ROMS=y

# EDK2 custom build parameters
CONFIG_EDK2_CUSTOM_BUILD_PARAMS="-D NETWORK_DRIVER_ENABLE=TRUE -D NETWORK_ENABLE=TRUE -D NETWORK_IP4_ENABLE=TRUE -D NETWORK_IP6_ENABLE=FALSE -D NETWORK_PXE_BOOT_ENABLE=TRUE -D NETWORK_HTTP_BOOT_ENABLE=FALSE -D NETWORK_SNP_ENABLE=TRUE -D NETWORK_RTEK_PCI=TRUE -D NETWORK_TLS_ENABLE=FALSE -D NETWORK_ISCSI_ENABLE=FALSE -D NETWORK_RTEK_USB=FALSE -D NETWORK_ASIX_USB3=FALSE -D NETWORK_ASIX_USB2=FALSE"
```

### 3. RTL8168 驱动源码修改

#### 3.1 添加 VPD 解析头文件
```c
// 在 src/drivers/net/r8168.c 开头添加：
#include <drivers/vpd/vpd.h>
```

#### 3.2 修复 VPD 解析逻辑
```c
// 在 fetch_mac_vpd_key 函数中添加：
/* Try using the proper VPD parsing function first */
const char *vpd_value = vpd_find(vpd_key, &vpd_size, VPD_RO);
if (vpd_value && vpd_size > 0) {
    /* Copy the value to macstrbuf, ensuring null termination */
    int copy_size = MIN(vpd_size, MACLEN - 1);
    memcpy(macstrbuf, vpd_value, copy_size);
    macstrbuf[copy_size] = '\0';
    printk(BIOS_DEBUG, "r8168: Found MAC in VPD using vpd_find: %s\n", macstrbuf);
    return CB_SUCCESS;
}
```

#### 3.3 添加 RTL8111H ERI 编程支持
```c
// 在 switch (pci_read_config8(dev, PCI_REVISION_ID)) 中添加：
case 12:
case 13:
case 14:
case 15:
    /* RTL8111H revision 12-15 ERI programming */
    printk(BIOS_DEBUG, "r8168: Programming ERI for RTL8111H revision %d\n", revision);
    outl(maclo, io_base + ERIDR);
    inl(io_base + ERIDR);
    outl(0x8000f0e0, io_base + ERIAR);
    inl(io_base + ERIAR);
    outl(machi, io_base + ERIDR);
    inl(io_base + ERIDR);
    outl(0x800030e4, io_base + ERIAR);
    printk(BIOS_DEBUG, "r8168: ERI programming completed for RTL8111H\n");
    break;
```

#### 3.4 修复 MAC 地址解析关键bug
```c
// 修复 get_mac_address 函数中的关键bug：
static void get_mac_address(u8 *macaddr, const u8 *strbuf)
{
    size_t offset = 0;
    int i;
    u8 hex1, hex2;

    if ((strbuf[2] != ':') || (strbuf[5] != ':') ||
        (strbuf[8] != ':') || (strbuf[11] != ':') ||
        (strbuf[14] != ':')) {
        printk(BIOS_ERR, "r8168: ignore invalid MAC address format in cbfs\n");
        return;
    }

    for (i = 0; i < 6; i++) {
        hex1 = get_hex_digit(strbuf[offset]);
        hex2 = get_hex_digit(strbuf[offset + 1]);
        
        /* 关键修复：检查十六进制数字的有效性 */
        if (hex1 > 0x0f || hex2 > 0x0f) {
            printk(BIOS_ERR, "r8168: Invalid hex digit in MAC address at position %d\n", i);
            return;  // 立即返回，保持默认MAC地址
        }
        
        macaddr[i] = (hex1 << 4) | hex2;
        offset += 3;
    }
    
    printk(BIOS_DEBUG, "r8168: Parsed MAC address: %02x:%02x:%02x:%02x:%02x:%02x\n",
           macaddr[0], macaddr[1], macaddr[2], macaddr[3], macaddr[4], macaddr[5]);
}
```

**关键修复说明**：
- **问题**：原始代码在解析MAC地址时，如果遇到无效字符，会将MAC地址重置为全零
- **修复**：添加十六进制数字有效性检查，发现无效字符时立即返回，保持默认MAC地址
- **效果**：防止MAC地址被错误地重置为 `000000000000`

### 4. 依赖关系修复

```kconfig
# 在 src/drivers/net/Kconfig 中修复依赖关系：
config RT8168_PUT_MAC_TO_ERI
    bool "Put MAC address to ERI registers"
    depends on REALTEK_8168_RESET  # 添加此依赖关系
```
## 🚀 构建方法

### 方法 1: 本地 Docker 构建（推荐）

```bash
# 1. 克隆本仓库
git clone https://github.com/your-username/coreboot-builder.git
cd coreboot-builder

# 2. 运行本地构建脚本
./local-build.sh

# 3. 构建完成后，ROM 文件将位于 roms/ 目录
```

**优点**：
- ✅ 无需 GitHub Actions 配额
- ✅ 构建速度快
- ✅ 本地调试方便
- ✅ 完全自动化

### 方法 2: GitHub Actions 编译

### 工作流说明
- **build.yml**: 自动化构建流程

### 使用方法
1. 进入 GitHub Actions 页面
2. 触发构建
3. 下载构建产物

**缺点**：
- ❌ 需要 GitHub Actions 配额
- ❌ 构建速度较慢
- ❌ 调试不方便
