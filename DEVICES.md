# 支持的设备

本项目支持 MrChromebox coreboot 的所有设备。

## 📋 查看完整设备列表

**👉 访问 [MrChromebox 官方设备支持页面](https://mrchromebox.tech/#devices)**

该页面提供：
- ✅ 完整的 292 个设备列表
- ✅ 设备代号与品牌型号对照
- ✅ 按平台分类展示
- ✅ 各设备的固件支持状态

## 🔍 如何使用

### 1. 查找您的设备

访问 https://mrchromebox.tech/#devices 找到您设备的**代号**（Codename）

例如：
- Acer Chromebox CXI4 → **kaisa**
- Google Pixelbook → **eve**
- HP Chromebox G2 → **fizz**

### 2. 在 GitHub Actions 中构建

1. 访问 [Actions 页面](../../actions/workflows/build-coreboot.yml)
2. 点击 "Run workflow"
3. 输入**设备代号**（如 `kaisa`）
4. 选择是否启用 PXE 支持
5. 点击 "Run workflow" 开始构建

### 3. 下载固件

构建完成后（约 30-60 分钟）：
- 在 Actions 页面下载 Artifacts
- 或从 Releases 页面下载（如果创建了 Release）

## 💡 支持的平台

本项目支持以下 Intel/AMD 平台的所有 Chromebook/Chromebox 设备：

- Intel: Sandy Bridge, Ivy Bridge, Haswell, Broadwell, Braswell, Bay Trail, Skylake, Apollo Lake, Kaby Lake, Gemini Lake, Whiskey Lake, Comet Lake, Jasper Lake, Tiger Lake, Alder Lake, Alder Lake-N
- AMD: Stoney Ridge, Picasso, Cezanne, Mendocino

**总计支持：292 个设备**

## 📚 相关资源

- [MrChromebox 设备支持页面](https://mrchromebox.tech/#devices) - 完整设备列表
- [MrChromebox 固件工具](https://mrchromebox.tech/) - 官方固件工具
- [项目 README](README.md) - 项目说明
- [快速使用指南](USAGE.md) - 使用教程
