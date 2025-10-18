# Auto iPXE Setup Script
# 自动检测和配置 iPXE 网络启动
# 使用方法：在 EFI Shell 中执行 fs0:\auto-ipxe-setup.nsh

echo "=== Auto iPXE Setup ==="
echo "Automatically configuring iPXE network boot..."
echo ""

# 检查 iPXE 文件是否存在
if exist ipxe.efi then
  echo "✅ Found ipxe.efi"
  IPXE_PATH="fs0:\ipxe.efi"
else if exist efi\boot\bootx64.efi then
  echo "✅ Found efi\boot\bootx64.efi"
  IPXE_PATH="fs0:\efi\boot\bootx64.efi"
else
  echo "❌ No iPXE file found"
  echo "Available files:"
  ls
  exit 1
endif

# 显示当前启动项
echo ""
echo "Current boot entries:"
bcfg boot dump
echo ""

# 检查是否已经存在 iPXE 启动项
echo "Checking for existing iPXE boot entries..."
bcfg boot dump | grep -i "ipxe" > nul
if %lasterror% == 0 then
  echo "⚠️ iPXE boot entry already exists"
  echo "Do you want to replace it? (y/n)"
  set /p choice=
  if /i "%choice%" == "y" then
    echo "Removing existing iPXE boot entry..."
    bcfg boot rm 0
  else
    echo "Keeping existing iPXE boot entry"
    goto :show_usage
  endif
endif

# 添加 iPXE 到启动菜单
echo ""
echo "Adding iPXE to UEFI boot menu..."
bcfg boot add 0 %IPXE_PATH% "iPXE Network Boot"

# 验证添加结果
echo ""
echo "Updated boot entries:"
bcfg boot dump
echo ""

# 显示网络状态
echo "=== Network Status ==="
ifconfig -l
echo ""

# 显示使用说明
:show_usage
echo "=== Setup Complete ==="
echo "iPXE has been configured for network boot"
echo ""
echo "Usage:"
echo "1. Restart the system"
echo "2. In UEFI boot menu, select 'iPXE Network Boot'"
echo "3. Or press F12 during boot to access boot menu"
echo ""
echo "Management commands:"
echo "- View boot entries: bcfg boot dump"
echo "- Remove iPXE: bcfg boot rm 0"
echo "- Test network: ping 8.8.8.8"
echo ""
echo "Script completed successfully!"
