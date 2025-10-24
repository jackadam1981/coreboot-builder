# VPD MAC 地址 Bug 分析报告

## 🎯 问题总结

**问题现象**：PXE 引导时显示 MAC 地址为 `00:00:00:00:00:00`，而不是预期的 MAC 地址。

## 🔍 根本原因分析

### 1. VPD 解析 Bug
- **位置**：`src/drivers/net/r8168.c` 中的 `fetch_mac_vpd_key` 函数
- **问题**：没有正确处理 Google VPD 2.0 的二进制格式
- **影响**：返回错误的 MAC 地址数据，导致格式验证失败

### 2. ERI 寄存器编程缺失
- **问题**：某些主板需要将 MAC 地址编程到 ERI 寄存器中
- **影响**：即使 MAC 地址被正确编程，在网卡重置时也会丢失
- **解决方案**：启用 `CONFIG_RT8168_PUT_MAC_TO_ERI=y`

## 🛠️ 解决方案

### 1. 修复 VPD 解析逻辑
需要修改 `fetch_mac_vpd_key` 函数，正确处理 Google VPD 2.0 格式：

```c
// 当前错误的实现
offset += strlen(vpd_key) + 1;  /* move to next character */

// 应该改为
offset += strlen(vpd_key);
if (offset < search_length) {
    u8 value_length = search_address[offset];
    offset += 1;  // 跳过长度字段
    // 然后读取 MAC 地址数据
}
```

### 2. 启用 ERI 寄存器编程
在 VPD 版本编译脚本中添加：

```bash
RTL8168_CONFIGS=(
    "CONFIG_RT8168_PUT_MAC_TO_ERI=y"
)
```

## 📋 已完成的修复

1. ✅ **修改了 `docker-build-kaisa-vpd.sh`**：添加了 `CONFIG_RT8168_PUT_MAC_TO_ERI=y`
2. ✅ **确认了 ERI 版本脚本**：已经正确启用了 ERI 寄存器编程
3. ✅ **分析了原版 coreboot**：发现了相关的 bug 修复提交

## 🧪 测试建议

1. **重新编译 VPD 版本**：使用修改后的脚本编译
2. **验证 ERI 支持**：确认编译时启用了 ERI 寄存器编程
3. **测试 PXE 引导**：检查 MAC 地址是否正确显示

## 📚 相关资源

- **Coreboot Issue**: https://ticket.coreboot.org/issues/579
- **修复提交**: 2b598a9472 - "Add option to program MAC address to ERI registers"
- **VPD 格式**: Google VPD 2.0 二进制格式需要特殊处理

## 🎯 预期结果

修复后，PXE 引导应该能够：
1. 正确从 VPD 读取 MAC 地址
2. 将 MAC 地址编程到常规寄存器和 ERI 寄存器
3. 在网卡重置后保持 MAC 地址
4. PXE 引导时显示正确的 MAC 地址
