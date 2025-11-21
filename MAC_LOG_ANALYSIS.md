# MAC地址日志分析指南

## 使用cbmem查看启动日志

### 基本命令

```bash
# 查看完整控制台日志
sudo ./tools/cbmem -c

# 只查看r8168相关日志
sudo ./tools/cbmem -c | grep -i r8168

# 查看MAC地址相关日志
sudo ./tools/cbmem -c | grep -i "mac\|vpd\|ethernet"

# 查看ERI编程相关日志
sudo ./tools/cbmem -c | grep -i "eri\|programming"

# 保存日志到文件
sudo ./tools/cbmem -c > boot_log.txt
```

### 关键日志信息

#### 正常情况（修复后）应该看到的日志：

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

#### VPD中没有MAC地址的情况：

```
[DEBUG] r8168: Starting MAC address programming, config=0x...
[DEBUG] r8168: Attempting to fetch MAC from VPD
[DEBUG] r8168: No MAC found in VPD, macstrbuf is empty
[DEBUG] r8168: Before get_mac_address, default MAC: 00:e0:4c:00:c0:b0
[DEBUG] r8168: MAC address string is empty, keeping default MAC
[DEBUG] r8168: After get_mac_address, final MAC: 00:e0:4c:00:c0:b0
```

#### 问题情况（MAC全0）可能看到的日志：

```
[ERROR] r8168: ignore invalid MAC address format
[ERROR] r8168: Invalid hex digit in MAC address at position X
# 或者完全没有r8168相关日志（说明驱动没有执行）
```

### 日志级别设置

要看到DEBUG级别的日志，需要确保配置中：

```kconfig
CONFIG_DEFAULT_CONSOLE_LOGLEVEL=0  # 或 1
```

当前配置（default.config）中：
```
CONFIG_DEFAULT_CONSOLE_LOGLEVEL=7  # 这太高了，看不到DEBUG日志
```

### 排查步骤

1. **检查日志级别**
   ```bash
   grep "CONFIG_DEFAULT_CONSOLE_LOGLEVEL" new_build/default.config
   ```

2. **查看是否有r8168日志**
   ```bash
   sudo ./tools/cbmem -c | grep -c r8168
   # 如果返回0，说明没有r8168相关日志
   ```

3. **检查驱动是否被调用**
   ```bash
   sudo ./tools/cbmem -c | grep -i "device.*init\|driver.*init" | grep -i r8168
   ```

4. **查看完整的设备初始化过程**
   ```bash
   sudo ./tools/cbmem -c | grep -A 20 "device enable\|device init" | grep -i r8168
   ```

### 如果看不到日志

可能的原因：
1. **日志级别太高** - 修改 `CONFIG_DEFAULT_CONSOLE_LOGLEVEL=0`
2. **驱动没有被调用** - 检查设备树配置
3. **日志缓冲区被覆盖** - 早期日志可能丢失
4. **不在运行coreboot的系统上** - cbmem只能在运行coreboot的系统上使用

### 使用脚本

运行提供的脚本：
```bash
sudo ./check-mac-logs.sh
```

这会自动：
- 检查r8168相关日志
- 检查MAC地址相关日志
- 检查ERI编程日志
- 保存完整日志到文件
