# RTL8111H PXE MAC 地址修复补丁集

## 📋 补丁概述

本补丁集包含6个独立的补丁，每个解决一个具体问题：

1. **fix-vpd-parsing-bug.patch** - 修复 VPD 解析 Bug
2. **fix-rtl8111h-eri-support.patch** - 添加 RTL8111H ERI 支持
3. **add-eri-debug-info.patch** - 添加 ERI 调试信息
4. **enable-eri-config.patch** - 启用 ERI 配置
5. **fix-eri-dependency.patch** - 修复 ERI 依赖关系
6. **update-kaisa-config.patch** - 更新 Kaisa 配置文件

## 🔧 补丁详情

### 1. fix-vpd-parsing-bug.patch
**问题**：VPD 解析函数错误处理 Google VPD 2.0 格式
**解决**：修复 `fetch_mac_vpd_key` 函数中的偏移计算
**影响**：避免返回格式错误的 MAC 地址字符串

```diff
- offset += strlen(vpd_key) + 1;
+ offset += vpd[offset + 1] + 2;  /* length field + data */
```

### 2. fix-rtl8111h-eri-support.patch
**问题**：原始代码不支持 RTL8111H revision 12-15 的 ERI 编程
**解决**：添加 case 12-15 的 ERI 编程支持
**影响**：确保 RTL8111H 芯片的 MAC 地址持久化

```diff
+ case 12:
+ case 13:
+ case 14:
+ case 15:
+     /* RTL8111H revision 12-15 ERI programming */
+     outl(maclo, io_base + ERIDR);
+     // ... ERI 编程代码
```

### 3. add-eri-debug-info.patch
**问题**：缺少 ERI 编程的调试信息
**解决**：添加详细的调试输出
**影响**：便于确认 ERI 编程是否正确执行

```diff
+ printk(BIOS_DEBUG, "r8168: Programming MAC to ERI registers...\n");
+ printk(BIOS_DEBUG, "r8168: Device revision ID: 0x%02x\n", revision);
```

### 4. enable-eri-config.patch
**问题**：主板配置中未启用 ERI 功能
**解决**：在 Puff 主板配置中添加 `select RT8168_PUT_MAC_TO_ERI`
**影响**：确保 ERI 功能在编译时被启用

```diff
+ select RT8168_PUT_MAC_TO_ERI
```

### 5. fix-eri-dependency.patch
**问题**：ERI 配置缺少依赖关系
**解决**：添加 `depends on REALTEK_8168_RESET`
**影响**：确保 ERI 配置的正确依赖关系

```diff
+ depends on REALTEK_8168_RESET
```

### 6. update-kaisa-config.patch
**问题**：Kaisa 配置文件缺少完整的配置项
**解决**：添加完整的 Kaisa 主板配置，包括：
- 主板基本配置（Google Kaisa）
- PXE 网络引导支持
- EDK2 网络驱动配置
- Intel 芯片组稳定配置
- RTL8168 驱动完整配置

**影响**：确保 Kaisa 主板的所有功能都被正确配置

```diff
+ CONFIG_BOARD_GOOGLE_KAISA=y
+ CONFIG_EDK2_NETWORK_PXE_SUPPORT=y
+ CONFIG_EDK2_LOAD_OPTION_ROMS=y
+ CONFIG_EDK2_CUSTOM_BUILD_PARAMS="..."
+ CONFIG_SOC_INTEL_COMMON_BLOCK_POWER_LIMIT=y
+ CONFIG_RT8168_PUT_MAC_TO_ERI=y
+ CONFIG_RT8168_GET_MAC_FROM_VPD=y
+ CONFIG_RT8168_SET_LED_MODE=y
+ CONFIG_RT8168_GEN_ACPI_POWER_RESOURCE=y
```

## 🚀 使用方法

### 自动应用所有补丁
```bash
cd /home/jack/coreboot-builder
./apply-patches.sh
```

### 手动应用单个补丁
```bash
cd coreboot
patch -p1 < ../patches/fix-rtl8111h-eri-support.patch
```

### 验证补丁应用
```bash
./verify-rtl8168-modification.sh
```

## 📊 补丁应用顺序

建议按以下顺序应用补丁：

1. **fix-vpd-parsing-bug.patch** - 修复 VPD 解析
2. **fix-rtl8111h-eri-support.patch** - 添加 ERI 支持
3. **add-eri-debug-info.patch** - 添加调试信息
4. **enable-eri-config.patch** - 启用配置
5. **fix-eri-dependency.patch** - 修复依赖
6. **update-kaisa-config.patch** - 更新配置文件

## 🔍 验证方法

### 检查 ERI 支持
```bash
grep -A 10 "case 12:" coreboot/src/drivers/net/r8168.c
```

### 检查配置启用
```bash
grep "select RT8168_PUT_MAC_TO_ERI" coreboot/src/mainboard/google/puff/Kconfig
```

### 检查依赖关系
```bash
grep "depends on REALTEK_8168_RESET" coreboot/src/drivers/net/Kconfig
```

### 检查 Kaisa 配置
```bash
grep "CONFIG_RT8168_PUT_MAC_TO_ERI=y" coreboot/configs/cml/config.kaisa.uefi
```

## 🐛 故障排除

### 补丁应用失败
- 检查文件路径是否正确
- 确认补丁文件格式正确
- 查看是否有冲突的修改

### 编译失败
- 检查所有补丁是否都正确应用
- 验证配置是否正确启用
- 查看编译错误信息

### 功能不工作
- 检查调试信息输出
- 验证 ERI 编程是否执行
- 确认硬件兼容性

## 📝 技术说明

### 补丁设计原则
- **单一职责**：每个补丁只解决一个问题
- **独立性**：补丁之间相互独立
- **可逆性**：可以单独撤销某个补丁
- **可验证性**：提供验证方法

### 兼容性考虑
- 支持 MrChromebox 分支
- 兼容 Google Kaisa 主板
- 支持 RTL8111H revision 12-15
- 保持向后兼容性

## 🎯 预期效果

应用所有补丁后，应该能够：

1. **正确解析 VPD**：避免格式错误的 MAC 地址
2. **支持 RTL8111H**：revision 12-15 的 ERI 编程
3. **持久化 MAC 地址**：重置后不会丢失
4. **解决 PXE 问题**：MAC 地址不再是全0
5. **提供调试信息**：便于问题诊断

## 📚 参考资料

- [Coreboot RTL8168 驱动文档](https://doc.coreboot.org/drivers/network/rtl8168.html)
- [Realtek RTL8111H 数据手册](https://www.realtek.com/en/products/communications-network-ics/item/rtl8111h)
- [Google VPD 2.0 格式说明](https://chromium.googlesource.com/chromiumos/platform/vpd/+/master/README.md)
