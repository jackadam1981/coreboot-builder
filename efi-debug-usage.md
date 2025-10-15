# EFI Shell 调试脚本使用说明

## 文件说明
- `efi-debug-script.nsh` - EFI Shell 可执行脚本
- `efi-debug-commands.txt` - 手动命令参考

## 使用方法

### 1. 准备工作
1. 将 `efi-debug-script.nsh` 复制到 U 盘根目录
2. 确保 U 盘已插入计算机
3. 启动到 EFI Shell

### 2. 执行脚本
在 EFI Shell 中执行：
```bash
# 切换到 U 盘（通常是 fs0:）
fs0:

# 执行调试脚本
efi-debug-script.nsh
```

### 3. 收集的信息
脚本会自动收集以下信息到 U 盘的 `debug` 文件夹：

| 文件名 | 内容描述 |
|--------|----------|
| `devices.txt` | 所有设备列表 |
| `drivers.txt` | 已加载的驱动列表 |
| `network_interfaces.txt` | 网络接口信息 |
| `ping_test.txt` | 网络连通性测试结果 |
| `filesystem_map.txt` | 文件系统映射 |
| `ipxe_search.txt` | iPXE 文件搜索结果 |
| `boot_config.txt` | 启动配置信息 |
| `memory_map.txt` | 内存映射信息 |
| `pci_devices.txt` | PCI 设备列表 |
| `efi_variables.txt` | EFI 变量信息 |
| `ipxe_launch.txt` | iPXE 启动尝试结果 |
| `summary.txt` | 收集信息汇总 |

### 4. 分析结果
1. 将 U 盘连接到其他计算机
2. 查看 `debug` 文件夹中的日志文件
3. 重点关注：
   - `ipxe_search.txt` - 是否找到 iPXE 文件
   - `ipxe_launch.txt` - iPXE 启动是否成功
   - `network_interfaces.txt` - 网卡是否被识别
   - `boot_config.txt` - 启动菜单配置

## 故障排除

### 如果脚本执行失败
1. 检查 U 盘是否被识别：`map -r`
2. 确认脚本文件权限：`ls -l fs0:\efi-debug-script.nsh`
3. 手动执行单个命令进行调试

### 如果找不到 iPXE 文件
1. 检查 ROM 是否正确刷入
2. 使用 `cbfstool` 验证 ROM 内容
3. 尝试手动查找：`ls -l fs*:\`

### 如果网络不工作
1. 检查网卡驱动是否加载：查看 `drivers.txt`
2. 检查网络接口状态：查看 `network_interfaces.txt`
3. 尝试手动连接：`connect -r`
