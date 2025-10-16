# EFI Shell 调试脚本 - 自动收集系统信息到 U 盘
# 使用方法：在 EFI Shell 中执行 fs0:\efi-debug-script.nsh

echo "=== EFI Shell 调试信息收集脚本 ==="
echo "开始时间: %date% %time%"
echo ""

# 设置输出目录为 U 盘（通常是 fs0:）
set OUTPUT_PATH=fs0:\debug
set OUTPUT_FILE=%OUTPUT_PATH%\efi-debug-report.txt
mkdir %OUTPUT_PATH% 2>nul
echo "输出目录: %OUTPUT_PATH%"
echo "统一报告文件: %OUTPUT_FILE%"
echo ""

# 初始化统一报告文件
echo "===============================================" > %OUTPUT_FILE%
echo "           EFI Shell 调试信息收集报告           " >> %OUTPUT_FILE%
echo "===============================================" >> %OUTPUT_FILE%
echo "收集时间: %date% %time%" >> %OUTPUT_FILE%
echo "脚本版本: 1.0" >> %OUTPUT_FILE%
echo "===============================================" >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

# 1. 收集设备信息
echo "=== 1. 设备信息 ==="
echo "1. 设备信息" >> %OUTPUT_FILE%
echo "===========" >> %OUTPUT_FILE%
devices >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

echo "1.2 驱动信息" >> %OUTPUT_FILE%
echo "=============" >> %OUTPUT_FILE%
drivers >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%
echo "设备信息收集完成"

# 2. 重新连接设备
echo "=== 2. 重新连接设备 ==="
echo "2. 设备重新连接" >> %OUTPUT_FILE%
echo "===============" >> %OUTPUT_FILE%
connect -r
echo "设备重新连接完成" >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

# 3. 网络接口检查
echo "=== 3. 网络接口检查 ==="
echo "3. 网络接口信息" >> %OUTPUT_FILE%
echo "===============" >> %OUTPUT_FILE%
ifconfig -l >> %OUTPUT_FILE% 2>&1
echo "" >> %OUTPUT_FILE%

# 4. 网络连通性测试
echo "=== 4. 网络连通性测试 ==="
echo "4. 网络连通性测试" >> %OUTPUT_FILE%
echo "=================" >> %OUTPUT_FILE%
ping 8.8.8.8 >> %OUTPUT_FILE% 2>&1
echo "" >> %OUTPUT_FILE%

# 5. 文件系统映射
echo "=== 5. 文件系统映射 ==="
echo "5. 文件系统映射" >> %OUTPUT_FILE%
echo "===============" >> %OUTPUT_FILE%
map -r >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

# 6. 查找 iPXE 文件
echo "=== 6. 查找 iPXE 文件 ==="
echo "6. iPXE 文件搜索" >> %OUTPUT_FILE%
echo "===============" >> %OUTPUT_FILE%
echo "搜索 iPXE 相关文件..." >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

echo "fs0: 分区文件:" >> %OUTPUT_FILE%
fs0:
ls -l >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

# 检查其他分区
echo "fs1: 分区文件:" >> %OUTPUT_FILE%
fs1:
ls -l >> %OUTPUT_FILE% 2>&1
echo "" >> %OUTPUT_FILE%

echo "fs2: 分区文件:" >> %OUTPUT_FILE%
fs2:
ls -l >> %OUTPUT_FILE% 2>&1
echo "" >> %OUTPUT_FILE%

# 7. 启动配置检查
echo "=== 7. 启动配置检查 ==="
echo "7. 启动配置信息" >> %OUTPUT_FILE%
echo "===============" >> %OUTPUT_FILE%
bcfg boot dump >> %OUTPUT_FILE% 2>&1
echo "" >> %OUTPUT_FILE%

# 8. 内存映射信息
echo "=== 8. 内存映射信息 ==="
echo "8. 内存映射信息" >> %OUTPUT_FILE%
echo "===============" >> %OUTPUT_FILE%
memmap >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

# 9. PCI 设备信息
echo "=== 9. PCI 设备信息 ==="
echo "9. PCI 设备信息" >> %OUTPUT_FILE%
echo "===============" >> %OUTPUT_FILE%
pci -l >> %OUTPUT_FILE% 2>&1
echo "" >> %OUTPUT_FILE%

# 10. EFI 变量检查
echo "=== 10. EFI 变量检查 ==="
echo "10. EFI 变量信息" >> %OUTPUT_FILE%
echo "=================" >> %OUTPUT_FILE%
dmpstore >> %OUTPUT_FILE% 2>&1
echo "" >> %OUTPUT_FILE%

# 11. 尝试启动 iPXE
echo "=== 11. 尝试启动 iPXE ==="
echo "11. iPXE 启动测试" >> %OUTPUT_FILE%
echo "=================" >> %OUTPUT_FILE%
echo "尝试启动 iPXE..." >> %OUTPUT_FILE%
echo "当前目录: %cwd%" >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

# 尝试在多个位置启动 iPXE
if exist ipxe.efi then
  echo "找到 ipxe.efi，尝试启动..." >> %OUTPUT_FILE%
  ipxe.efi >> %OUTPUT_FILE% 2>&1
else
  echo "当前目录未找到 ipxe.efi" >> %OUTPUT_FILE%
endif

fs0:
if exist ipxe.efi then
  echo "fs0: 找到 ipxe.efi，尝试启动..." >> %OUTPUT_FILE%
  fs0:\ipxe.efi >> %OUTPUT_FILE% 2>&1
else
  echo "fs0: 未找到 ipxe.efi" >> %OUTPUT_FILE%
endif
echo "" >> %OUTPUT_FILE%

# 12. 生成总结
echo "12. 调试总结" >> %OUTPUT_FILE%
echo "=============" >> %OUTPUT_FILE%
echo "收集时间: %date% %time%" >> %OUTPUT_FILE%
echo "脚本版本: 1.0" >> %OUTPUT_FILE%
echo "===============================================" >> %OUTPUT_FILE%

# 13. 完成信息收集
echo ""
echo "=== 调试信息收集完成 ==="
echo "统一报告文件: %OUTPUT_FILE%"
echo "文件大小:"
ls -l %OUTPUT_FILE%
echo ""
echo "请将 U 盘连接到其他计算机查看 %OUTPUT_FILE% 文件"
echo "结束时间: %date% %time%"
