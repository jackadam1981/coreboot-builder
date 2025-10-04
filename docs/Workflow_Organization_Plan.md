# 工作流文件组织方案 / Workflow Organization Plan

## 📁 **文件命名规范**

### **命名格式**
```
{序号}-strategy-{技术路线}-{目标}.yml
```

### **具体文件列表**

| 序号 | 方案名称 | 文件名 | 状态 |
|------|----------|--------|------|
| 1 | MrChromebox EDK2 + 运行时 iPXE 集成 | `1-strategy-edk2-runtime-ipxe.yml` | ✅ 已创建 |
| 2 | 标准 Coreboot + iPXE Payload | `2-strategy-standard-ipxe-payload.yml` | ⏳ 待创建 |
| 3 | MrChromebox + 预编译 iPXE 编译时集成 | `3-strategy-mrchromebox-compiletime-ipxe.yml` | ⏳ 待创建 |
| 4 | QEMU 测试环境 | `4-strategy-qemu-test-environment.yml` | ⏳ 待创建 |
| 5 | 纯 EDK2 网络启动 | `5-strategy-pure-edk2-network.yml` | ⏳ 待创建 |
| 6 | 多路径 iPXE 集成 | `6-strategy-multipath-ipxe-integration.yml` | ⏳ 待创建 |

---

## 🎯 **方案优先级和创建顺序**

### **高优先级（立即创建）**
1. **方案2** - 标准 Coreboot + iPXE Payload
   - 如果 MrChromebox 支持，这是最佳方案
   - 需要验证 iPXE payload 支持

2. **方案5** - 纯 EDK2 网络启动
   - 作为基础对比方案
   - 验证 EDK2 原生网络功能

### **中优先级（后续创建）**
3. **方案6** - 多路径 iPXE 集成
   - 优化方案1的集成效果
   - 测试不同 CBFS 路径

4. **方案4** - QEMU 测试环境
   - 开发测试环境
   - 验证不同集成方式

### **低优先级（最后创建）**
5. **方案3** - MrChromebox + 预编译 iPXE 编译时集成
   - 已确认 MrChromebox 不支持
   - 作为历史记录保留

---

## 🔧 **工作流模板结构**

### **标准工作流结构**
```yaml
name: 方案X - [方案名称] / Strategy X - [Strategy Name]

on:
  workflow_dispatch:
    inputs:
      release: boolean (optional)
      test_mode: choice (optional)

jobs:
  build:
    steps:
      - name: 📋 显示方案信息 / Display Strategy Info
      - name: 检出构建仓库 / Checkout Builder Repository
      - name: 拉取 Coreboot SDK 容器 / Pull Coreboot SDK
      - name: 克隆 Coreboot 源码 / Clone Coreboot Source
      - name: 配置特定方案设置 / Configure Strategy Specific Settings
      - name: 编译固件 / Build Firmware
      - name: 验证结果 / Verify Results
      - name: 生成方案测试报告 / Generate Strategy Test Report
      - name: 上传产物 / Upload Artifacts
      - name: 创建 Release (可选) / Create Release (Optional)
```

### **方案特定步骤**
每个方案会有独特的配置和集成步骤，但整体结构保持一致。

---

## 📊 **测试报告标准**

### **报告模板**
```markdown
# 方案X测试报告 - [方案名称]

**测试时间**: [timestamp]
**GitHub Actions Run**: [run_number]
**Coreboot 版本**: [commit_sha]

## 方案说明
- **方案名称**: [方案名称]
- **技术路线**: [技术描述]
- **适用场景**: [使用场景]

## 测试结果
- **编译状态**: ✅/❌
- **集成状态**: ✅/❌
- **功能验证**: ✅/❌

## 结论
- **方案可行性**: ✅/❌
- **推荐使用**: [是/否]
- **下一步建议**: [具体建议]
```

---

## 🚀 **实施计划**

### **阶段1：核心方案测试**
- [x] 创建方案1工作流
- [ ] 创建方案2工作流（验证 iPXE payload 支持）
- [ ] 创建方案5工作流（纯 EDK2 对比）

### **阶段2：优化方案测试**
- [ ] 创建方案6工作流（多路径优化）
- [ ] 创建方案4工作流（QEMU 测试）

### **阶段3：完整方案对比**
- [ ] 创建方案3工作流（历史记录）
- [ ] 生成完整的方案对比报告
- [ ] 确定最佳实践方案

---

## 📝 **维护说明**

### **文件更新**
- 每次修改工作流后，更新此文档
- 记录测试结果和发现的问题
- 更新方案优先级

### **版本控制**
- 使用语义化版本号标记重要更新
- 保留历史版本的工作流文件
- 记录每个方案的演进过程

---

*此文档将随着工作流文件的创建和测试结果持续更新。*
