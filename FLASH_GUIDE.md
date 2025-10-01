# Coreboot 固件刷写指南 / Flash Guide

## Intel 设备自动刷写脚本

### 使用方法

1. **准备固件文件**
   ```bash
   # 将编译好的 ROM 文件放在任意位置
   # 例如: coreboot_edk2-kaisa-mrchromebox_20251001.rom
   ```

2. **运行刷写脚本**
   ```bash
   sudo ./flash-coreboot-intel.sh <你的ROM文件>
   ```

   **示例：**
   ```bash
   sudo ./flash-coreboot-intel.sh coreboot_edk2-kaisa-mrchromebox_20251001.rom
   ```

### 脚本功能

脚本会自动完成以下步骤：

1. ✅ **下载工具**
   - flashrom (固件刷写工具)
   - cbfstool (Coreboot 文件系统工具)
   - gbb_utility (Google Binary Block 工具)

2. ✅ **校验固件完整性**
   - 自动查找 .sha1 校验文件
   - 验证固件未损坏或被篡改
   - 校验失败会中止刷写操作

3. ✅ **备份当前固件**
   - 自动备份到设备专属目录
   - 文件名：`backup_<时间戳>.rom`
   - 仅备份 BIOS 区域（Intel 设备）
   - 每个设备（MAC地址）有独立目录

4. ✅ **提取 VPD (Vital Product Data)**
   - 从备份中提取 VPD
   - VPD 包含序列号等重要信息

5. ✅ **准备自定义 ROM**
   - 将 VPD 注入到新固件
   - 保留设备身份信息

6. ✅ **提取并注入 HWID**
   - 提取硬件 ID
   - 注入到新固件

7. ✅ **保存处理后的ROM**
   - 保存到 ready_roms/ 目录
   - 可用于将来快速刷写

8. ✅ **刷写固件**
   - 使用安全参数刷写
   - 仅更新 BIOS 区域

### 安全提示 ⚠️

1. **确保电源稳定**
   - 刷写过程中请勿断电
   - 建议连接充电器（笔记本）

2. **保存备份文件**
   - 脚本会为每个设备创建独立目录：`device_<MAC地址>/`
   - 备份文件：`backup_<时间戳>.rom`
   - 同一设备的所有刷写记录都在同一目录下
   - 请妥善保存整个设备目录以备恢复

3. **确认设备型号**
   - 确保 ROM 文件与您的设备匹配
   - 刷写错误的固件可能导致设备无法启动

### 工作目录结构

脚本会为每个设备（基于MAC地址）创建独立目录：

```
工作目录/
├── coreboot_edk2-kaisa-mrchromebox_20251001.rom  # GitHub Actions 编译的原始固件
├── coreboot_edk2-kaisa-mrchromebox_20251001.rom.sha1
├── tools/                              # 工具目录（所有设备共享）
│   ├── flashrom
│   ├── cbfstool
│   └── gbb_utility
└── device_A1B2C3D4E5F6/                # 设备目录（MAC地址）
    ├── ready_roms/                     # 处理好的ROM（可直接刷写）
    │   ├── ready_A1B2C3D4E5F6_20251001_120000.rom
    │   ├── ready_A1B2C3D4E5F6_20251002_140000.rom
    │   └── ...
    ├── flash_20251001_120000/          # 第一次刷写记录
    │   ├── backup_20251001_120000.rom  # 原固件备份
    │   ├── vpd.bin                     # VPD 数据
    │   ├── hwid.txt                    # 硬件 ID
    │   └── coreboot.rom                # 临时文件
    ├── flash_20251002_140000/          # 第二次刷写记录
    │   └── ...
    └── flash_20251003_160000/          # 第三次刷写记录
        └── ...
```

**目录说明：**
- `tools/` - 所有设备共享的工具，只下载一次
- `device_<MAC>/` - 每个设备的独立目录
- `ready_roms/` - **处理好的ROM文件**（已注入VPD和HWID，可直接刷写）
- `flash_<时间戳>/` - 每次刷写的工作记录

**文件命名规则：**
- 备份文件：`backup_<时间戳>.rom`
- 处理后ROM：`ready_<MAC地址>_<时间戳>.rom`

**优势：**
- ✅ 工具共享，节省空间
- ✅ 处理后的ROM可重复使用
- ✅ 多设备管理清晰
- ✅ 保留完整刷写历史
- ✅ 方便查找特定设备的备份
- ✅ 避免文件混淆

### 如果出现问题

**刷写失败怎么办？**
1. 检查错误信息
2. 确保以 root 权限运行
3. 尝试重新运行脚本

**无法启动怎么办？**
1. 使用外部刷写器恢复备份
2. 或使用紧急恢复模式

### AMD 设备

如需 AMD 设备脚本，请联系或参考手动步骤：

```bash
# AMD 设备刷写命令
sudo ./flashrom -p internal -r backup.rom
sudo ./flashrom -p internal -w coreboot.rom
```

### 常见问题

**Q: 脚本会自动重启吗？**
A: 会询问是否重启，您可以选择立即重启或稍后手动重启。

**Q: 备份文件在哪里？**
A: 在 `device_<MAC地址>/flash_<时间戳>/` 目录中，文件名为 `backup_<时间戳>.rom`。每个设备有独立的目录。

**Q: 可以重复运行脚本吗？**
A: 可以，脚本会检测已存在的文件并跳过下载。

**Q: 需要联网吗？**
A: 首次运行需要联网下载工具，之后可离线使用。

**Q: 多次刷写同一设备会怎样？**
A: 每次刷写会在设备目录下创建新的时间戳子目录，保留完整历史记录，不会覆盖旧备份。

**Q: SHA1 校验失败怎么办？**
A: 说明固件文件已损坏或被篡改，请重新下载固件。确保从 GitHub Releases 或 Artifacts 下载完整的 .rom 和 .sha1 文件。

**Q: 如何使用快速刷写模式？**
A: 如果之前已经刷写过，可以使用 `sudo ./flash-coreboot-intel.sh --use-ready` 直接刷写最新的已处理ROM，跳过备份和VPD/HWID处理步骤。

### 技术支持

- MrChromebox 文档: https://mrchromebox.tech/
- GitHub Issues: https://github.com/jackadam1981/coreboot-builder/issues

---

**免责声明 / Disclaimer**

刷写固件存在风险，可能导致设备变砖。使用本脚本的风险由您自行承担。请务必保存好备份文件。

Flashing firmware has risks and may brick your device. Use this script at your own risk. Please keep your backup file safe.

