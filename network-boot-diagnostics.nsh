# Network Boot Diagnostics Script
# Specialized script for diagnosing PXE/HTTP Boot issues
# Usage: Execute fs0:\network-boot-diagnostics.nsh in EFI Shell

echo "=== Network Boot Diagnostics Script ==="
echo "Start time: %date% %time%"
echo ""

# Initialize network diagnostics report
echo "===============================================" > fs0:\network-boot-diagnostics.txt
echo "           Network Boot Diagnostics Report     " >> fs0:\network-boot-diagnostics.txt
echo "===============================================" >> fs0:\network-boot-diagnostics.txt
echo "Collection time: %date% %time%" >> fs0:\network-boot-diagnostics.txt
echo "Script version: 1.0" >> fs0:\network-boot-diagnostics.txt
echo "===============================================" >> fs0:\network-boot-diagnostics.txt
echo "" >> fs0:\network-boot-diagnostics.txt

# 1. Network Device Detection
echo "=== 1. Network Device Detection ==="
echo "1. Network Device Detection" >> fs0:\network-boot-diagnostics.txt
echo "============================" >> fs0:\network-boot-diagnostics.txt
echo "Scanning for network devices..." >> fs0:\network-boot-diagnostics.txt
echo "" >> fs0:\network-boot-diagnostics.txt

# List all devices and filter for network-related ones
devices >> fs0:\network-boot-diagnostics.txt
echo "" >> fs0:\network-boot-diagnostics.txt

# 2. Network Driver Status
echo "=== 2. Network Driver Status ==="
echo "2. Network Driver Status" >> fs0:\network-boot-diagnostics.txt
echo "=========================" >> fs0:\network-boot-diagnostics.txt
echo "Checking network driver status..." >> fs0:\network-boot-diagnostics.txt
drivers >> fs0:\network-boot-diagnostics.txt
echo "" >> fs0:\network-boot-diagnostics.txt

# 3. PCI Network Card Detection
echo "=== 3. PCI Network Card Detection ==="
echo "3. PCI Network Card Detection" >> fs0:\network-boot-diagnostics.txt
echo "=============================" >> fs0:\network-boot-diagnostics.txt
echo "Scanning PCI bus for network cards..." >> fs0:\network-boot-diagnostics.txt
pci -l >> fs0:\network-boot-diagnostics.txt 2>&1
echo "" >> fs0:\network-boot-diagnostics.txt

# 4. Network Interface Status
echo "=== 4. Network Interface Status ==="
echo "4. Network Interface Status" >> fs0:\network-boot-diagnostics.txt
echo "===========================" >> fs0:\network-boot-diagnostics.txt
echo "Checking network interfaces..." >> fs0:\network-boot-diagnostics.txt
ifconfig -l >> fs0:\network-boot-diagnostics.txt 2>&1
echo "" >> fs0:\network-boot-diagnostics.txt

# 5. Boot Menu Analysis
echo "=== 5. Boot Menu Analysis ==="
echo "5. Boot Menu Analysis" >> fs0:\network-boot-diagnostics.txt
echo "=====================" >> fs0:\network-boot-diagnostics.txt
echo "Analyzing UEFI boot menu for network options..." >> fs0:\network-boot-diagnostics.txt
bcfg boot dump >> fs0:\network-boot-diagnostics.txt 2>&1
echo "" >> fs0:\network-boot-diagnostics.txt

# 6. Network Connectivity Test
echo "=== 6. Network Connectivity Test ==="
echo "6. Network Connectivity Test" >> fs0:\network-boot-diagnostics.txt
echo "=============================" >> fs0:\network-boot-diagnostics.txt
echo "Testing basic network connectivity..." >> fs0:\network-boot-diagnostics.txt
ping 8.8.8.8 >> fs0:\network-boot-diagnostics.txt 2>&1
echo "" >> fs0:\network-boot-diagnostics.txt

# 7. iPXE File Detection
echo "=== 7. iPXE File Detection ==="
echo "7. iPXE File Detection" >> fs0:\network-boot-diagnostics.txt
echo "=======================" >> fs0:\network-boot-diagnostics.txt
echo "Searching for iPXE files..." >> fs0:\network-boot-diagnostics.txt
echo "" >> fs0:\network-boot-diagnostics.txt

fs0:
echo "fs0: (USB drive) files:" >> fs0:\network-boot-diagnostics.txt
ls >> fs0:\network-boot-diagnostics.txt 2>&1
echo "" >> fs0:\network-boot-diagnostics.txt

# Check for specific iPXE files
if exist ipxe.efi then
  echo "✅ Found ipxe.efi on fs0:" >> fs0:\network-boot-diagnostics.txt
else
  echo "❌ ipxe.efi not found on fs0:" >> fs0:\network-boot-diagnostics.txt
endif

if exist rtl8168.efi then
  echo "✅ Found rtl8168.efi on fs0:" >> fs0:\network-boot-diagnostics.txt
else
  echo "❌ rtl8168.efi not found on fs0:" >> fs0:\network-boot-diagnostics.txt
endif
echo "" >> fs0:\network-boot-diagnostics.txt

# 8. iPXE Launch Test
echo "=== 8. iPXE Launch Test ==="
echo "8. iPXE Launch Test" >> fs0:\network-boot-diagnostics.txt
echo "===================" >> fs0:\network-boot-diagnostics.txt
echo "Testing iPXE launch..." >> fs0:\network-boot-diagnostics.txt
echo "" >> fs0:\network-boot-diagnostics.txt

# Try to launch iPXE
if exist ipxe.efi then
  echo "Attempting to launch ipxe.efi..." >> fs0:\network-boot-diagnostics.txt
  fs0:\ipxe.efi >> fs0:\network-boot-diagnostics.txt 2>&1
else
  echo "ipxe.efi not available for testing" >> fs0:\network-boot-diagnostics.txt
endif
echo "" >> fs0:\network-boot-diagnostics.txt

# 9. Device Reconnection Test
echo "=== 9. Device Reconnection Test ==="
echo "9. Device Reconnection Test" >> fs0:\network-boot-diagnostics.txt
echo "===========================" >> fs0:\network-boot-diagnostics.txt
echo "Reconnecting all devices..." >> fs0:\network-boot-diagnostics.txt
connect -r
echo "Device reconnection completed" >> fs0:\network-boot-diagnostics.txt
echo "" >> fs0:\network-boot-diagnostics.txt

# 10. Post-Reconnection Network Check
echo "=== 10. Post-Reconnection Network Check ==="
echo "10. Post-Reconnection Network Check" >> fs0:\network-boot-diagnostics.txt
echo "===================================" >> fs0:\network-boot-diagnostics.txt
echo "Checking network status after reconnection..." >> fs0:\network-boot-diagnostics.txt
ifconfig -l >> fs0:\network-boot-diagnostics.txt 2>&1
echo "" >> fs0:\network-boot-diagnostics.txt

# 11. Boot Menu Re-check
echo "=== 11. Boot Menu Re-check ==="
echo "11. Boot Menu Re-check" >> fs0:\network-boot-diagnostics.txt
echo "=======================" >> fs0:\network-boot-diagnostics.txt
echo "Re-checking boot menu after device reconnection..." >> fs0:\network-boot-diagnostics.txt
bcfg boot dump >> fs0:\network-boot-diagnostics.txt 2>&1
echo "" >> fs0:\network-boot-diagnostics.txt

# 12. Diagnostic Summary
echo "12. Diagnostic Summary" >> fs0:\network-boot-diagnostics.txt
echo "=====================" >> fs0:\network-boot-diagnostics.txt
echo "Collection time: %date% %time%" >> fs0:\network-boot-diagnostics.txt
echo "Script version: 1.0" >> fs0:\network-boot-diagnostics.txt
echo "" >> fs0:\network-boot-diagnostics.txt
echo "Key Diagnostic Points:" >> fs0:\network-boot-diagnostics.txt
echo "1. Check section 3 for PCI network card detection" >> fs0:\network-boot-diagnostics.txt
echo "2. Check section 4 for network interface status" >> fs0:\network-boot-diagnostics.txt
echo "3. Check section 5 for network boot options in menu" >> fs0:\network-boot-diagnostics.txt
echo "4. Check section 6 for network connectivity" >> fs0:\network-boot-diagnostics.txt
echo "5. Check section 7 for iPXE file availability" >> fs0:\network-boot-diagnostics.txt
echo "6. Check section 8 for iPXE launch results" >> fs0:\network-boot-diagnostics.txt
echo "" >> fs0:\network-boot-diagnostics.txt
echo "Expected Results for Working Network Boot:" >> fs0:\network-boot-diagnostics.txt
echo "- PCI network card should be detected in section 3" >> fs0:\network-boot-diagnostics.txt
echo "- Network interface should be available in section 4" >> fs0:\network-boot-diagnostics.txt
echo "- Network boot options should appear in section 5" >> fs0:\network-boot-diagnostics.txt
echo "- Network connectivity should work in section 6" >> fs0:\network-boot-diagnostics.txt
echo "- iPXE files should be found in section 7" >> fs0:\network-boot-diagnostics.txt
echo "- iPXE should launch successfully in section 8" >> fs0:\network-boot-diagnostics.txt
echo "" >> fs0:\network-boot-diagnostics.txt
echo "===============================================" >> fs0:\network-boot-diagnostics.txt

# Complete diagnostics
echo ""
echo "=== Network Boot Diagnostics Completed ==="
echo "Diagnostic report: fs0:\network-boot-diagnostics.txt"
echo "File size:"
ls fs0:\network-boot-diagnostics.txt
echo ""
echo "This specialized script focuses on network boot issues."
echo "Please review the report for network boot troubleshooting."
echo "End time: %date% %time%"
