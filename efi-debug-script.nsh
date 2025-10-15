# EFI Shell 调试脚本 - 自动收集系统信息到 U 盘
# 使用方法：在 EFI Shell 中执行 fs0:\efi-debug-script.nsh

echo "=== EFI Shell 调试信息收集脚本 ==="
echo "开始时间: %date% %time%"
echo ""

# 设置输出目录为 U 盘（通常是 fs0:）
set OUTPUT_PATH=fs0:\debug
mkdir %OUTPUT_PATH% 2>nul
echo "输出目录: %OUTPUT_PATH%"
echo ""

# 1. 收集设备信息
echo "=== 1. 设备信息 ==="
devices > %OUTPUT_PATH%\devices.txt
echo "设备列表已保存到 devices.txt"

drivers > %OUTPUT_PATH%\drivers.txt
echo "驱动列表已保存到 drivers.txt"

# 2. 重新连接设备
echo "=== 2. 重新连接设备 ==="
connect -r
echo "设备重新连接完成"

# 3. 网络接口检查
echo "=== 3. 网络接口检查 ==="
ifconfig -l > %OUTPUT_PATH%\network_interfaces.txt 2>&1
echo "网络接口信息已保存到 network_interfaces.txt"

# 4. 网络连通性测试
echo "=== 4. 网络连通性测试 ==="
ping 8.8.8.8 > %OUTPUT_PATH%\ping_test.txt 2>&1
echo "网络连通性测试已保存到 ping_test.txt"

# 5. 文件系统映射
echo "=== 5. 文件系统映射 ==="
map -r > %OUTPUT_PATH%\filesystem_map.txt
echo "文件系统映射已保存到 filesystem_map.txt"

# 6. 查找 iPXE 文件
echo "=== 6. 查找 iPXE 文件 ==="
echo "搜索 iPXE 相关文件..." > %OUTPUT_PATH%\ipxe_search.txt
echo "fs0: 分区文件:" >> %OUTPUT_PATH%\ipxe_search.txt
fs0:
ls -l >> %OUTPUT_PATH%\ipxe_search.txt
echo "" >> %OUTPUT_PATH%\ipxe_search.txt

# 检查其他分区
echo "fs1: 分区文件:" >> %OUTPUT_PATH%\ipxe_search.txt
fs1:
ls -l >> %OUTPUT_PATH%\ipxe_search.txt 2>&1
echo "" >> %OUTPUT_PATH%\ipxe_search.txt

echo "fs2: 分区文件:" >> %OUTPUT_PATH%\ipxe_search.txt
fs2:
ls -l >> %OUTPUT_PATH%\ipxe_search.txt 2>&1

# 7. 启动配置检查
echo "=== 7. 启动配置检查 ==="
bcfg boot dump > %OUTPUT_PATH%\boot_config.txt 2>&1
echo "启动配置已保存到 boot_config.txt"

# 8. 内存映射信息
echo "=== 8. 内存映射信息 ==="
memmap > %OUTPUT_PATH%\memory_map.txt
echo "内存映射已保存到 memory_map.txt"

# 9. PCI 设备信息
echo "=== 9. PCI 设备信息 ==="
pci -l > %OUTPUT_PATH%\pci_devices.txt 2>&1
echo "PCI 设备信息已保存到 pci_devices.txt"

# 10. EFI 变量检查
echo "=== 10. EFI 变量检查 ==="
dmpstore > %OUTPUT_PATH%\efi_variables.txt 2>&1
echo "EFI 变量已保存到 efi_variables.txt"

# 11. 系统信息汇总
echo "=== 11. 生成系统信息汇总 ==="
echo "EFI Shell 调试信息收集报告" > %OUTPUT_PATH%\summary.txt
echo "收集时间: %date% %time%" >> %OUTPUT_PATH%\summary.txt
echo "=================================" >> %OUTPUT_PATH%\summary.txt
echo "" >> %OUTPUT_PATH%\summary.txt

echo "收集的文件列表:" >> %OUTPUT_PATH%\summary.txt
ls %OUTPUT_PATH%\ >> %OUTPUT_PATH%\summary.txt
echo "" >> %OUTPUT_PATH%\summary.txt

echo "=== 12. 尝试启动 iPXE ==="
echo "尝试启动 iPXE..." > %OUTPUT_PATH%\ipxe_launch.txt
echo "当前目录: %cwd%" >> %OUTPUT_PATH%\ipxe_launch.txt
echo "" >> %OUTPUT_PATH%\ipxe_launch.txt

# 尝试在多个位置启动 iPXE
if exist ipxe.efi then
  echo "找到 ipxe.efi，尝试启动..." >> %OUTPUT_PATH%\ipxe_launch.txt
  ipxe.efi >> %OUTPUT_PATH%\ipxe_launch.txt 2>&1
else
  echo "当前目录未找到 ipxe.efi" >> %OUTPUT_PATH%\ipxe_launch.txt
endif

fs0:
if exist ipxe.efi then
  echo "fs0: 找到 ipxe.efi，尝试启动..." >> %OUTPUT_PATH%\ipxe_launch.txt
  fs0:\ipxe.efi >> %OUTPUT_PATH%\ipxe_launch.txt 2>&1
else
  echo "fs0: 未找到 ipxe.efi" >> %OUTPUT_PATH%\ipxe_launch.txt
endif

# 13. 完成信息收集
echo ""
echo "=== 调试信息收集完成 ==="
echo "所有文件已保存到: %OUTPUT_PATH%\"
echo "收集的文件:"
ls %OUTPUT_PATH%\
echo ""
echo "请将 U 盘连接到其他计算机查看详细日志"
echo "结束时间: %date% %time%"
