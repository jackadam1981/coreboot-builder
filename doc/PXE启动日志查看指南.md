# PXE 启动日志查看指南

## 📍 日志存储位置

PXE 启动日志**不会自动保存到文件**，需要通过以下方式实时查看：

### 1. 串口控制台（Serial Console）

**最常用的方法**：通过串口实时查看启动日志

#### 硬件连接
- 使用 USB 转串口适配器连接到主板的串口（通常是 COM1，波特率 115200）
- 或使用 IPMI/iKVM 的串口重定向功能

#### 软件工具
```bash
# Linux
screen /dev/ttyUSB0 115200
# 或
minicom -D /dev/ttyUSB0 -b 115200

# Windows
# 使用 PuTTY、Tera Term 或 SecureCRT
# 连接类型：Serial
# 波特率：115200
# 数据位：8
# 停止位：1
# 校验位：None
# 流控制：None
```

### 2. CBMEM（Coreboot Memory）

coreboot 会将启动日志保存在内存中（CBMEM），可以在 Linux 启动后查看：

```bash
# 方法 1: 从 coreboot 源码编译（推荐）
cd coreboot/util/cbmem
make
sudo cp cbmem /usr/local/bin/
# 或直接使用
./cbmem -c

# 方法 2: 从包管理器安装（如果可用）
# Ubuntu/Debian
sudo apt-get install cbmem

# 方法 3: 使用项目中的工具（如果已编译）
# 本项目 tools/ 目录中可能有预编译的 cbmem
./tools/cbmem -c

# 查看完整的启动日志（需要 root 权限）
sudo cbmem -c

# 查看最近的日志（从上次启动开始）
sudo cbmem -1

# 将日志保存到文件
sudo cbmem -c > boot.log
```

### 3. EDK2/UEFI Shell 调试

在 UEFI Shell 中可以使用以下命令查看网络相关信息：

```bash
# 进入 UEFI Shell（启动时按 F2 或 ESC）

# 查看网络设备信息
devices -s network

# 查看 MAC 地址
ifconfig -l

# 查看 PXE 相关信息
dmpstore -all | grep -i network
dmpstore -all | grep -i pxe
```

### 4. 网络抓包（PXE 阶段）

在 PXE 启动时，可以通过网络抓包查看 DHCP 请求中的 MAC 地址：

```bash
# 在 PXE 服务器上抓包
sudo tcpdump -i eth0 -n -v 'port 67 or port 68'

# 或使用 Wireshark
# 过滤条件：bootp
```

## 🔍 查看 RTL8168 MAC 地址相关日志

### 在 coreboot 日志中查找

```bash
# 使用 cbmem 查看日志
sudo cbmem -c | grep -i "r8168\|rtl8168\|mac\|ERI\|VPD"

# 关键日志信息：
# - "r8168: Searching for VPD key"
# - "r8168: Found MAC in VPD"
# - "r8168: MAC address programmed to ERI"
# - "r8168: Parsed MAC address"
```

### 在串口控制台中查找

启动时观察串口输出，查找以下关键信息：
- `r8168:` 开头的所有日志
- `VPD` 相关的日志
- `ERI` 寄存器编程相关的日志
- `MAC address` 相关的日志

## 📊 日志级别配置

### coreboot 日志级别

当前配置（在 `default.config` 中）：
```
CONFIG_DEFAULT_CONSOLE_LOGLEVEL=7
CONFIG_CONSOLE_USE_LOGLEVEL_PREFIX=y
```

日志级别说明：
- 0: BIOS_SPEW (最详细)
- 1: BIOS_DEBUG
- 2: BIOS_INFO
- 3: BIOS_NOTICE
- 4: BIOS_WARNING
- 5: BIOS_ERR
- 6: BIOS_EMERG
- 7: BIOS_NEVER (最少)

### EDK2 调试日志

在 EDK2 构建配置中（`UefiPayloadPkg.dsc`）：
```
gEfiMdePkgTokenSpaceGuid.PcdDebugPrintErrorLevel|0x8000004F
```

调试级别位掩码：
- `0x00000001`: DEBUG_INIT (初始化)
- `0x00000002`: DEBUG_WARN (警告)
- `0x00000004`: DEBUG_LOAD (加载事件)
- `0x00000040`: DEBUG_INFO (信息)
- `0x00004000`: DEBUG_NET (网络驱动)
- `0x00010000`: DEBUG_UNDI (UNDI 驱动)
- `0x80000000`: DEBUG_ERROR (错误)

## 🛠️ 启用更详细的日志

### 1. 修改 coreboot 日志级别

在构建配置中修改：
```kconfig
# 在 configs/cml/config.kaisa.uefi 中
CONFIG_DEFAULT_CONSOLE_LOGLEVEL=0  # 最详细的日志
```

### 2. 启用 RTL8168 驱动调试

在 `r8168.c` 中，日志使用 `printk(BIOS_DEBUG, ...)`，需要确保日志级别足够低。

### 3. 启用 EDK2 网络调试

在 EDK2 构建参数中添加：
```
-D NETWORK_DEBUG_ENABLE=TRUE
```

## 📝 日志分析示例

### 正常的 MAC 地址编程日志

```
[DEBUG] r8168: Searching for VPD key: 'ethernet_mac0'
[DEBUG] r8168: vpd_find result: vpd_value=0x..., vpd_size=17
[DEBUG] r8168: Found MAC in VPD using vpd_find: AA:BB:CC:DD:EE:FF
[DEBUG] r8168: Parsed MAC address: aa:bb:cc:dd:ee:ff
[DEBUG] r8168: Programming MAC address to ERI registers...
[DEBUG] r8168: MAC address programmed successfully
```

### 问题日志（MAC 全零）

```
[ERROR] r8168: Couldn't find RO_VPD region.
# 或
[ERROR] r8168: vpd_find failed, trying legacy method
[ERROR] r8168: Invalid hex digit in MAC address at position 0
# 或
[WARNING] r8168: Using default MAC address: 00:e0:4c:00:c0:b0
```

## 🔧 故障排查步骤

1. **检查串口连接**
   ```bash
   # 确认串口设备
   ls -l /dev/ttyUSB*
   # 测试连接
   echo "test" > /dev/ttyUSB0
   ```

2. **查看完整启动日志**
   ```bash
   sudo cbmem -c > full_boot.log
   # 分析日志
   grep -i "r8168\|mac\|vpd\|eri" full_boot.log
   ```

3. **检查 VPD 内容**
   ```bash
   # 在 Linux 中查看 VPD
   vpd -l | grep -i mac
   # 或
   cat /sys/firmware/vpd/ro/ethernet_mac0
   ```

4. **检查网络设备**
   ```bash
   # 查看网络接口
   ip link show
   # 查看 MAC 地址
   cat /sys/class/net/eth0/address
   ```

## 📚 相关文档

- coreboot 日志文档：`coreboot/Documentation/`
- EDK2 调试指南：`edk2/UefiPayloadPkg/Readme.md`
- RTL8168 驱动源码：`coreboot/src/drivers/net/r8168.c`

## ⚠️ 注意事项

1. **串口日志是实时的**：如果不及时捕获，日志会丢失
2. **CBMEM 日志**：只有在 Linux 启动后才能查看，PXE 阶段的日志可能不完整
3. **日志缓冲区大小**：coreboot 的日志缓冲区有限，早期日志可能被覆盖
4. **网络抓包**：只能看到网络层面的信息，看不到固件内部的日志

## 💡 建议

对于 MAC 地址问题排查，建议：
1. **使用串口控制台**：实时查看完整的启动过程
2. **保存日志**：使用 `cbmem -c > boot.log` 保存完整日志
3. **启用详细日志**：临时降低日志级别以获取更多信息
4. **网络抓包**：配合网络抓包确认 MAC 地址是否正确传递到网络层

