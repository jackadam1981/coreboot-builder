# Coreboot Builder

基于 GitHub Actions 的 Coreboot 固件自动化构建项目，支持多种 Chromebook/Chromebox 设备。

使用 [MrChromebox](https://github.com/mrchromebox/coreboot) 的 Coreboot 定制版本，集成 UEFI 固件和可选的 PXE 网络启动支持。

## ✨ 特性

- 🚀 **自动化构建**：通过 GitHub Actions 云端编译，无需本地环境
- 🎯 **设备选择**：支持多种 Chromebook/Chromebox 设备
- 🌐 **PXE 支持**：可选启用 UEFI 网络 PXE 启动功能
- 📦 **自动发布**：可选自动创建 GitHub Release
- ✅ **校验和**：自动生成 SHA1 校验文件

## 📋 支持的设备

| 设备代号 | 设备名称 | 平台 |
|---------|---------|------|
| kaisa | Acer Chromebox CXI4 | CML (Comet Lake) |
| eve | Google Pixelbook | KBL (Kaby Lake) |
| fizz | HP Chromebox G2 | KBL (Kaby Lake) |
| atlas | Google Pixelbook Go | KBL (Kaby Lake) |
| samus | Chromebook Pixel 2015 | BDW (Broadwell) |
| panther | Chromebook Pixel 2013 | HSW (Haswell) |
| all | 所有支持的设备 | - |

更多支持设备请查看 [MrChromebox 设备列表](https://mrchromebox.tech/#devices)

## 🔧 使用方法

### 方式一：GitHub Actions 手动触发（推荐）

1. **进入 Actions 页面**
   - 访问仓库的 `Actions` 标签页
   - 选择 `Build Coreboot Firmware` 工作流

2. **配置构建参数**
   - 点击 `Run workflow` 按钮
   - 选择要编译的设备（或选择 `all` 编译所有设备）
   - 勾选是否启用 PXE 网络启动
   - 勾选是否创建 Release 发布

3. **等待构建完成**
   - 构建过程约 30-60 分钟
   - 完成后在 `Artifacts` 中下载固件

4. **下载固件**
   - 在 Actions 运行记录中下载 `coreboot-firmware-xxx` 文件
   - 如果创建了 Release，也可以在 Releases 页面下载

### 方式二：修改配置自动触发

1. Fork 本仓库
2. 修改 `configs/` 目录下的配置文件
3. 提交推送到 `main` 分支
4. 自动触发构建

## 📁 项目结构

```
coreboot-builder/
├── .github/
│   └── workflows/
│       └── build-coreboot.yml    # GitHub Actions 工作流
├── configs/                       # 自定义设备配置
│   └── cml/
│       └── config.kaisa.uefi     # KAISA 配置（已启用 PXE）
└── README.md                      # 项目说明
```

## 🛠️ 自定义配置

### 添加新设备配置

1. 在 `configs/` 目录下创建对应平台目录（如 `cml/`, `kbl/` 等）
2. 添加配置文件，命名格式：`config.<设备代号>.uefi`
3. 推送到仓库即可在构建时使用

### 启用 PXE 支持

在设备配置文件末尾添加：

```
CONFIG_EDK2_NETWORK_PXE_SUPPORT=y
```

### 修改 GitHub Actions 工作流

编辑 `.github/workflows/build-coreboot.yml` 可以：
- 添加更多设备选项
- 修改构建参数
- 添加其他构建步骤

## 📝 刷写固件

⚠️ **警告**：刷写固件有风险，操作前请备份原固件！

### 使用 Flashrom（Linux）

```bash
# 读取当前固件（备份）
sudo flashrom -p internal -r backup.rom

# 刷写新固件
sudo flashrom -p internal -w coreboot_edk2-kaisa-mrchromebox_YYYYMMDD.rom
```

### 使用 MrChromebox 脚本

```bash
curl -LO https://mrchromebox.tech/firmware-util.sh
sudo bash firmware-util.sh
```

详细说明请访问：https://mrchromebox.tech/

## 🔍 验证固件完整性

```bash
# 验证 SHA1 校验和
sha1sum -c coreboot_edk2-kaisa-mrchromebox_YYYYMMDD.rom.sha1
```

## 🐛 故障排除

### 构建失败

1. 检查 Actions 日志中的错误信息
2. 确认配置文件格式正确
3. 检查是否是子模块克隆问题（工作流会自动处理）

### PXE 启动不工作

1. 确认构建时已启用 PXE 支持
2. 检查 BIOS 设置中是否启用了网络启动
3. 确认网络环境支持 PXE/TFTP

## 📚 参考资源

- [MrChromebox 固件工具](https://mrchromebox.tech/)
- [Coreboot 官方文档](https://doc.coreboot.org/)
- [EDK2 UEFI 固件](https://github.com/tianocore/edk2)
- [支持设备列表](https://mrchromebox.tech/#devices)

## 📄 许可证

本项目使用的 Coreboot 源码遵循 GPL-2.0 许可证。

配置文件和脚本采用 MIT 许可证。

## 🙏 致谢

- [MrChromebox](https://github.com/mrchromebox) - Coreboot UEFI 固件定制
- [Coreboot Project](https://www.coreboot.org/) - 开源固件项目
- [coreboot-sdk](https://hub.docker.com/r/coreboot/coreboot-sdk) - 官方编译环境

---

**注意**：本项目仅供学习和个人使用，刷写固件存在风险，请谨慎操作！

