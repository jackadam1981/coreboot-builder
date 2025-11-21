# CBMEM 日志工具使用指南

## 📖 简介

`cbmem` 是 coreboot 提供的工具，用于查看保存在 CBMEM（Coreboot Memory）中的启动日志。这些日志包含了从固件启动到操作系统加载的完整过程信息。

## 🔧 工具位置

项目中的 cbmem 工具位于：
```
./tools/cbmem
```

## 📋 基本用法

### 查看完整控制台日志

```bash
sudo ./tools/cbmem -c
```

### 查看帮助信息

```bash
./tools/cbmem --help
```

### 常用命令选项

| 选项 | 说明 |
|------|------|
| `-c, --console` | 打印 CBMEM 控制台日志（最常用） |
| `-1, --oneboot` | 只显示最后一次启动的日志 |
| `-2, --2ndtolast` | 显示倒数第二次启动的日志 |
| `-l, --list` | 列出 CBMEM 表内容 |
| `-t, --timestamps` | 显示时间戳信息 |
| `-T, --parseable-timestamps` | 显示可解析的时间戳 |
| `-V, --verbose` | 详细输出（调试模式） |
| `-v, --version` | 显示版本信息 |

## 🔍 查看 MAC 地址相关日志

### 1. 查看所有 r8168 驱动相关日志

```bash
sudo ./tools/cbmem -c | grep -i r8168
```

### 2. 查看 MAC 地址相关日志

```bash
sudo ./tools/cbmem -c | grep -i "mac\|vpd\|ethernet"
```

### 3. 查看 ERI 编程相关日志

```bash
sudo ./tools/cbmem -c | grep -i "eri\|programming"
```

### 4. 查看完整的驱动初始化过程

```bash
sudo ./tools/cbmem -c | grep -A 10 -B 2 "r8168.*Starting\|r8168.*MAC\|r8168.*VPD\|r8168.*ERI"
```

### 5. 保存日志到文件

```bash
# 保存完整日志
sudo ./tools/cbmem -c > boot_log_$(date +%Y%m%d_%H%M%S).txt

# 只保存 r8168 相关日志
sudo ./tools/cbmem -c | grep -i r8168 > r8168_log.txt

# 保存 MAC 地址相关日志
sudo ./tools/cbmem -c | grep -i "mac\|vpd\|ethernet" > mac_log.txt
```

## 📊 日志级别过滤

### 使用日志级别过滤

```bash
# 只显示 INFO 及以上级别的日志
sudo ./tools/cbmem -c -B INFO

# 显示所有日志（包括无级别的日志）
sudo ./tools/cbmem -c -B +INFO
```

### 日志级别说明

coreboot 日志级别（从低到高，数字越小越详细）：
- `0` - BIOS_SPEW（最详细，所有调试信息）
- `1` - BIOS_DEBUG（调试信息）
- `2` - BIOS_INFO（信息）
- `3` - BIOS_NOTICE（通知）
- `4` - BIOS_WARNING（警告）
- `5` - BIOS_ERR（错误）
- `6` - BIOS_EMERG（紧急）
- `7` - BIOS_NEVER（最少）

## 🔎 MAC 地址问题排查

### 正常情况应该看到的日志

```
[DEBUG] r8168: Starting MAC address programming, config=0x...
[DEBUG] r8168: Attempting to fetch MAC from VPD
[DEBUG] r8168: MAC string from VPD: AA:BB:CC:DD:EE:FF
[DEBUG] r8168: Before get_mac_address, default MAC: 00:e0:4c:00:c0:b0
[DEBUG] r8168: Parsed MAC address: aa:bb:cc:dd:ee:ff
[DEBUG] r8168: After get_mac_address, final MAC: aa:bb:cc:dd:ee:ff
[DEBUG] r8168: Programming MAC Address...
[DEBUG] r8168: Programming ERI for RTL8111H revision X
[DEBUG] r8168: ERI programming completed for RTL8111H
```

### VPD 中没有 MAC 地址的情况

```
[DEBUG] r8168: Starting MAC address programming, config=0x...
[DEBUG] r8168: Attempting to fetch MAC from VPD
[DEBUG] r8168: No MAC found in VPD, macstrbuf is empty
[DEBUG] r8168: Before get_mac_address, default MAC: 00:e0:4c:00:c0:b0
[DEBUG] r8168: MAC address string is empty, keeping default MAC
[DEBUG] r8168: After get_mac_address, final MAC: 00:e0:4c:00:c0:b0
```

### 问题情况（MAC 全 0）可能看到的日志

```
[ERROR] r8168: ignore invalid MAC address format
[ERROR] r8168: Invalid hex digit in MAC address at position X
# 或者完全没有 r8168 相关日志（说明驱动没有执行）
```

## 🛠️ 使用自动化脚本

项目提供了自动化检查脚本：

```bash
# 运行检查脚本
sudo ./check-mac-logs.sh
```

脚本会自动：
- 检查 r8168 相关日志
- 检查 MAC 地址相关日志
- 检查 ERI 编程日志
- 保存完整日志到文件

## ⚠️ 注意事项

### 1. 需要 root 权限

cbmem 需要访问 `/dev/mem`，因此需要 root 权限：

```bash
sudo ./tools/cbmem -c
```

### 2. 只能在运行 coreboot 的系统上使用

cbmem 工具只能在已经运行 coreboot 固件的系统上使用。如果系统还在使用原厂固件，cbmem 无法工作。

### 3. 日志级别配置

要看到 DEBUG 级别的日志，需要确保固件配置中：

```kconfig
CONFIG_DEFAULT_CONSOLE_LOGLEVEL=0  # 或 1
```

如果日志级别设置为 7，将看不到任何 DEBUG 日志。

### 4. 日志缓冲区限制

- CBMEM 日志缓冲区大小有限
- 早期启动阶段的日志可能被覆盖
- 如果日志太多，可能需要增加缓冲区大小

### 5. 多次启动的日志

```bash
# 查看最后一次启动的日志
sudo ./tools/cbmem -1

# 查看倒数第二次启动的日志
sudo ./tools/cbmem -2
```

## 📝 实际使用示例

### 示例 1：快速检查 MAC 地址问题

```bash
# 检查是否有 r8168 日志
if sudo ./tools/cbmem -c | grep -q "r8168"; then
    echo "✅ 找到 r8168 日志"
    sudo ./tools/cbmem -c | grep -i r8168
else
    echo "❌ 未找到 r8168 日志，可能驱动未执行或日志级别太高"
fi
```

### 示例 2：保存并分析日志

```bash
# 保存日志
LOG_FILE="boot_log_$(date +%Y%m%d_%H%M%S).txt"
sudo ./tools/cbmem -c > "$LOG_FILE"

# 分析 MAC 地址相关日志
echo "=== MAC 地址相关日志 ==="
grep -i "mac\|vpd\|ethernet" "$LOG_FILE"

# 分析 r8168 驱动日志
echo "=== r8168 驱动日志 ==="
grep -i r8168 "$LOG_FILE"

# 检查是否有错误
echo "=== 错误信息 ==="
grep -i "error\|fail\|invalid" "$LOG_FILE" | grep -i r8168
```

### 示例 3：查看时间戳

```bash
# 查看带时间戳的日志
sudo ./tools/cbmem -c -t | grep -i r8168

# 查看可解析的时间戳格式
sudo ./tools/cbmem -c -T | grep -i r8168
```

## 🔧 故障排查

### 问题 1：cbmem 无法运行

**症状**：
```bash
$ sudo ./tools/cbmem -c
Error: Could not access CBMEM
```

**可能原因**：
- 系统未运行 coreboot 固件
- 权限不足（需要 root）
- CBMEM 区域不可访问

**解决方法**：
- 确认系统已刷入 coreboot 固件
- 使用 `sudo` 运行
- 检查 `/dev/mem` 是否可访问

### 问题 2：看不到 r8168 日志

**可能原因**：
1. 日志级别太高（CONFIG_DEFAULT_CONSOLE_LOGLEVEL=7）
2. 驱动没有被调用
3. 日志缓冲区被覆盖

**解决方法**：
1. 检查日志级别配置
2. 检查设备树配置，确认 r8168 驱动被启用
3. 降低日志级别重新编译

### 问题 3：日志不完整

**可能原因**：
- 日志缓冲区太小
- 早期日志被覆盖

**解决方法**：
- 增加 CBMEM 日志缓冲区大小
- 使用串口控制台查看实时日志

## 📚 相关文档

- [PXE启动日志查看指南](./doc/PXE启动日志查看指南.md)
- [MAC地址日志分析指南](./MAC_LOG_ANALYSIS.md)
- [MAC地址修复总结](./MAC_ADDRESS_FIX_SUMMARY.md)

## 💡 最佳实践

1. **定期保存日志**：每次启动后保存日志，便于对比分析
2. **使用脚本自动化**：使用提供的脚本自动检查和分析
3. **降低日志级别**：调试时使用日志级别 0 或 1
4. **结合串口日志**：cbmem 和串口日志结合使用，获得更完整的信息
5. **时间戳分析**：使用时间戳功能分析启动时间线

## 🔗 相关工具

- **串口控制台**：实时查看启动日志
- **网络抓包**：查看 PXE 启动时的网络流量
- **flashrom**：读取和写入固件
- **cbfstool**：操作 CBFS 文件系统

---

**最后更新**：2025-11-22  
**维护者**：coreboot-builder 项目

