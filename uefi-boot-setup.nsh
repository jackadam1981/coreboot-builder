# UEFI Boot Setup Script for iPXE
# 将 iPXE 添加到 UEFI 启动菜单的脚本
# 使用方法：在 EFI Shell 中执行 fs0:\uefi-boot-setup.nsh

echo "=== UEFI Boot Setup for iPXE ==="
echo "Setting up iPXE as UEFI boot option..."
echo ""

# 检查 iPXE 文件是否存在
if exist ipxe.efi then
  echo "✅ Found ipxe.efi"
else
  echo "❌ ipxe.efi not found in current directory"
  echo "Please make sure you are in the correct directory (fs0:)"
  exit 1
endif

# 显示当前启动项
echo ""
echo "Current boot entries:"
bcfg boot dump
echo ""

# 添加 iPXE 到启动菜单（优先级 0，最高）
echo "Adding iPXE to UEFI boot menu..."
bcfg boot add 0 fs0:\ipxe.efi "iPXE Network Boot"

# 验证添加结果
echo ""
echo "Updated boot entries:"
bcfg boot dump
echo ""

# 显示使用说明
echo "=== Setup Complete ==="
echo "iPXE has been added to the UEFI boot menu"
echo ""
echo "To use iPXE:"
echo "1. Restart the system"
echo "2. In UEFI boot menu, select 'iPXE Network Boot'"
echo "3. Or press F12 during boot to access boot menu"
echo ""
echo "To remove iPXE from boot menu later:"
echo "bcfg boot rm 0"
echo ""
echo "Script completed successfully!"
