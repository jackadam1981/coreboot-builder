# iPXE 集成策略方案列表 / iPXE Integration Strategy Plans

## 📋 **方案概览**

本文档列出了所有可能的 iPXE 集成方案，包括目标说明、技术细节、预期结果和测试状态。

---

## 🎯 **方案1：MrChromebox EDK2 + 运行时 iPXE 集成** ⭐**当前方案**

### **目标**
- 使用 MrChromebox 的 EDK2 作为主要 payload
- 通过运行时集成添加 iPXE 增强功能
- 提供双重网络启动支持

### **技术实现**
```yaml
# 配置 EDK2 网络支持
CONFIG_EDK2_NETWORK_PXE_SUPPORT=y
CONFIG_EDK2_NETWORK_HTTP_BOOT_SUPPORT=y
CONFIG_EDK2_NETWORK_ISCSI_SUPPORT=y

# 运行时集成 iPXE
cbfstool rom.rom add -f ipxe_x64.efi -n efi/ipxe/ipxe.efi -t raw -c lzma
```

### **预期结果**
- EDK2 原生 PXE 支持（基础网络启动）
- iPXE 增强功能（高级网络启动选项）
- UEFI 启动菜单显示两个选项

### **测试状态**
- ✅ 工作流已实现
- ⏳ 待测试
- 📝 测试要点：EDK2 网络配置、iPXE 运行时集成、启动菜单显示

---

## 🎯 **方案2：标准 Coreboot + iPXE Payload**

### **目标**
- 使用标准 coreboot 源码（非 MrChromebox）
- 将 iPXE 作为 payload 编译到固件中
- 实现纯 iPXE 网络启动

### **技术实现**
```bash
# 配置 iPXE payload
CONFIG_PAYLOAD_IPXE=y

# 编译时集成
make menuconfig -> Payload -> iPXE
```

### **预期结果**
- iPXE 直接作为固件 payload
- 启动时直接进入 iPXE 环境
- 最佳的网络启动性能

### **测试状态**
- ✅ 工作流已创建：`2-strategy-standard-ipxe-payload.yml`
- ⏳ 待测试 - 需要验证 MrChromebox 是否支持 iPXE payload
- 📝 MrChromebox 基于标准 coreboot，可能支持 iPXE payload
- 💡 如果支持，这是最佳的集成方案

---

## 🎯 **方案3：MrChromebox + 预编译 iPXE 编译时集成**

### **目标**
- 使用 MrChromebox 源码
- 将预编译 iPXE EFI 复制到源码目录
- 尝试编译时集成

### **技术实现**
```bash
# 复制 iPXE 到源码目录
cp ipxe_x64.efi coreboot/util/cbfstool/ipxe.efi

# 使用 MrChromebox 编译脚本
./build-uefi.sh kaisa
```

### **预期结果**
- 如果 MrChromebox 支持，iPXE 可能被编译为 payload 的一部分
- 启动时直接执行 iPXE

### **测试状态**
- ✅ 工作流已创建：`3-strategy-mrchromebox-compiletime-ipxe.yml`
- ❌ MrChromebox 不支持 CONFIG_PAYLOAD_IPXE=y
- 📝 历史记录测试，用于对比验证
- 💡 不适合 MrChromebox 架构

---

## 🎯 **方案4：QEMU 测试环境**

### **目标**
- 创建 QEMU 兼容的 coreboot BIOS
- 在虚拟环境中测试 iPXE 集成
- 验证不同集成路径的有效性

### **技术实现**
```bash
# 编译 QEMU 版本 coreboot
make menuconfig -> Mainboard -> QEMU x86 i440fx

# 集成 iPXE 到 QEMU BIOS
cbfstool qemu_bios.rom add -f ipxe.efi -n efi/boot/bootx64.efi
```

### **预期结果**
- 在 QEMU 中测试 iPXE 启动
- 验证不同 CBFS 路径的有效性
- 测试压缩对启动的影响

### **测试状态**
- ✅ 工作流已创建：`4-strategy-qemu-test-environment.yml`
- ⏳ 待测试
- 📝 测试要点：QEMU PXE 启动、不同路径测试
- 🔧 支持多种测试模式：full-test, ipxe-only, bios-only

---

## 🎯 **方案5：纯 EDK2 网络启动**

### **目标**
- 仅使用 MrChromebox 的 EDK2 原生网络支持
- 不集成 iPXE，依赖 EDK2 的 PXE 功能
- 简化集成复杂度

### **技术实现**
```yaml
# 仅配置 EDK2 网络支持
CONFIG_EDK2_NETWORK_PXE_SUPPORT=y
CONFIG_EDK2_NETWORK_HTTP_BOOT_SUPPORT=y
CONFIG_EDK2_NETWORK_ISCSI_SUPPORT=y

# 不添加 iPXE
```

### **预期结果**
- EDK2 原生 PXE 支持
- 启动菜单显示网络启动选项
- 功能相对简单但稳定

### **测试状态**
- ✅ 工作流已创建：`5-strategy-pure-edk2-network.yml`
- ⏳ 待测试
- 📝 测试要点：EDK2 PXE 功能、网络启动能力
- 🎯 作为方案1的对比基准

---

## 🎯 **方案6：多路径 iPXE 集成**

### **目标**
- 尝试多个 CBFS 路径集成 iPXE
- 测试不同压缩方式的影响
- 找到最可靠的集成方法

### **技术实现**
```bash
# 尝试多个路径
efi/boot/bootx64.efi  # 标准 UEFI 启动路径
efi/boot/ipxe.efi     # 自定义 iPXE 路径
efi/ipxe/ipxe.efi     # iPXE 专用路径

# 尝试不同压缩
-t raw                # 无压缩
-t raw -c lzma        # LZMA 压缩
```

### **预期结果**
- 找到最可靠的 iPXE 集成路径
- 确定最佳压缩策略
- 提高 iPXE 在启动菜单中的可见性

### **测试状态**
- ✅ 工作流已创建：`6-strategy-multipath-ipxe-integration.yml`
- ⏳ 待测试
- 📝 测试要点：不同路径的启动成功率
- 🔧 自动生成最佳集成方式推荐
- 📊 详细的 CSV 测试结果报告

---

## 🎯 **方案7：Realtek 8111 PXE ROM 集成** ⭐**新方案 - 最简单**

### **目标**
- 集成 Realtek 官方 PXE ROM 到 coreboot/EDK2
- 利用硬件原生 PXE 支持
- 无需修改 payload 或网络栈

### **技术实现**
```bash
# 1. 下载 Realtek 8111 官方 PXE ROM
wget https://www.realtek.com/.../rtl8111_pxe_uefi.rom

# 2. 添加到 CBFS 作为 PCI Option ROM
cbfstool coreboot.rom add \
  -f rtl8111_pxe_uefi.rom \
  -n pci10ec,8168.rom \
  -t raw

# 3. coreboot 自动加载 PCI Option ROM
# RTL8111H: Vendor ID = 0x10ec, Device ID = 0x8168
```

### **预期结果**
- 硬件层面启用网络启动
- BIOS/UEFI 自动识别网卡的 PXE 能力
- 最简单、最可靠的集成方式

### **测试状态**
- ✅ 工作流待创建：`7-strategy-rtl8111-pxe-rom.yml`
- ⏳ 待测试
- 📝 测试要点：PCI Option ROM 加载、网络启动功能
- 💡 **优势**：
  - 官方支持，兼容性好
  - 不依赖 EDK2 网络栈
  - 不需要修改 iPXE
  - 集成步骤最简单

### **技术优势**
| 特性 | 方案7 (PXE ROM) | 方案1 (iPXE) | 方案2 (iPXE Payload) |
|------|----------------|--------------|---------------------|
| **集成复杂度** | ⭐ 最简单 | ⭐⭐⭐ 中等 | ⭐⭐⭐⭐ 复杂 |
| **官方支持** | ✅ Realtek 官方 | ❌ 社区 | ❌ 社区 |
| **网络兼容性** | ✅ 硬件原生 | ⚠️ 依赖驱动 | ✅ iPXE 驱动 |
| **启动速度** | ⭐⭐⭐ 快 | ⭐⭐ 一般 | ⭐⭐ 一般 |
| **功能丰富性** | ⭐⭐ 基础 PXE | ⭐⭐⭐⭐⭐ 高级功能 | ⭐⭐⭐⭐⭐ 高级功能 |

---

## 📊 **测试优先级**

### **最高优先级** 🔥
1. **方案7** - Realtek 8111 PXE ROM 集成（最简单、最可靠）

### **高优先级**
2. **方案2** - 标准 Coreboot + iPXE Payload（功能最强）
3. **方案5** - 纯 EDK2 网络启动（基础验证）

### **中优先级**
4. **方案1** - MrChromebox EDK2 + 运行时 iPXE 集成（已发现 EDK2 网络栈问题）
5. **方案4** - QEMU 测试环境（开发测试）
6. **方案6** - 多路径 iPXE 集成（优化测试）

### **低优先级**
7. **方案3** - MrChromebox + 预编译 iPXE 编译时集成（已确认不支持）

---

## 🧪 **测试计划**

### **阶段1：基础功能验证**
- [ ] 测试方案1：EDK2 + 运行时 iPXE 集成
- [ ] 测试方案2：验证 MrChromebox 是否支持 iPXE payload
- [ ] 测试方案5：纯 EDK2 网络启动
- [ ] 验证固件编译成功
- [ ] 检查启动菜单显示

### **阶段2：功能对比测试**
- [ ] 对比 EDK2 原生 PXE 与 iPXE 功能差异
- [ ] 测试网络启动成功率
- [ ] 验证 WDS 服务器连接

### **阶段3：优化测试**
- [ ] 测试方案4：QEMU 环境验证
- [ ] 测试方案6：多路径集成优化
- [ ] 性能对比分析

---

## 📝 **测试记录模板**

### **测试结果记录**
```markdown
## 方案X测试结果 - YYYY-MM-DD

### 测试环境
- GitHub Actions 运行
- 固件版本：coreboot_edk2-kaisa-mrchromebox_YYYYMMDD.rom
- iPXE 版本：从 boot.ipxe.org 下载

### 测试步骤
1. 编译固件
2. 集成 iPXE
3. 验证结果

### 测试结果
- ✅/❌ 编译成功
- ✅/❌ iPXE 集成成功
- ✅/❌ 启动菜单显示 iPXE 选项
- ✅/❌ 网络启动功能正常

### 问题记录
- 问题描述
- 解决方案
- 后续改进

### 结论
- 方案可行性评估
- 推荐使用场景
```

---

## 🔄 **更新日志**

- **2025-01-04** - 创建方案列表文档
- **2025-01-04** - 添加当前方案1的详细说明
- **2025-01-04** - 整理测试优先级和计划

---

*本文档将根据测试结果持续更新，记录每个方案的可行性和最佳实践。*
