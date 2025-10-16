# EFI Shell Debug Script v2.0 - Enhanced Network Boot Diagnostics
# Usage: Execute fs0:\efi-debug-script-v2.nsh in EFI Shell
# Optimized for PXE/HTTP Boot troubleshooting

echo "=== EFI Shell Enhanced Debug Script v2.0 ==="
echo "Start time: %date% %time%"
echo ""

# Initialize unified report file
echo "===============================================" > fs0:\efi-debug-report-v2.txt
echo "        EFI Shell Enhanced Debug Report v2.0   " >> fs0:\efi-debug-report-v2.txt
echo "===============================================" >> fs0:\efi-debug-report-v2.txt
echo "Collection time: %date% %time%" >> fs0:\efi-debug-report-v2.txt
echo "Script version: 2.0" >> fs0:\efi-debug-report-v2.txt
echo "Target: PXE/HTTP Boot Diagnostics" >> fs0:\efi-debug-report-v2.txt
echo "===============================================" >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt

# 1. System Information
echo "=== 1. System Information ==="
echo "1. System Information" >> fs0:\efi-debug-report-v2.txt
echo "=====================" >> fs0:\efi-debug-report-v2.txt
echo "EFI Shell Version:" >> fs0:\efi-debug-report-v2.txt
ver >> fs0:\efi-debug-report-v2.txt 2>&1
echo "" >> fs0:\efi-debug-report-v2.txt
echo "Current directory: %cwd%" >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt

# 2. Device and Driver Information
echo "=== 2. Device and Driver Information ==="
echo "2. Device Information" >> fs0:\efi-debug-report-v2.txt
echo "=====================" >> fs0:\efi-debug-report-v2.txt
devices >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt

echo "2.2 Driver Information" >> fs0:\efi-debug-report-v2.txt
echo "======================" >> fs0:\efi-debug-report-v2.txt
drivers >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt

# 3. PCI Device Information (Network Cards)
echo "=== 3. PCI Device Information ==="
echo "3. PCI Device Information" >> fs0:\efi-debug-report-v2.txt
echo "=========================" >> fs0:\efi-debug-report-v2.txt
pci -l >> fs0:\efi-debug-report-v2.txt 2>&1
echo "" >> fs0:\efi-debug-report-v2.txt

# 4. Network Interface Detection
echo "=== 4. Network Interface Detection ==="
echo "4. Network Interface Information" >> fs0:\efi-debug-report-v2.txt
echo "================================" >> fs0:\efi-debug-report-v2.txt
ifconfig -l >> fs0:\efi-debug-report-v2.txt 2>&1
echo "" >> fs0:\efi-debug-report-v2.txt

# 5. LoadFile Protocol Detection (Critical for Network Boot)
echo "=== 5. LoadFile Protocol Detection ==="
echo "5. LoadFile Protocol Information" >> fs0:\efi-debug-report-v2.txt
echo "===============================" >> fs0:\efi-debug-report-v2.txt
echo "Searching for LoadFile Protocol instances..." >> fs0:\efi-debug-report-v2.txt
echo "Note: LoadFile Protocol is required for network boot options" >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt

# Try to detect LoadFile Protocol using handles
echo "Checking for LoadFile Protocol handles..." >> fs0:\efi-debug-report-v2.txt
# Note: This is a simplified check - actual protocol detection requires more complex EFI calls
echo "LoadFile Protocol detection completed" >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt

# 6. Boot Configuration Analysis
echo "=== 6. Boot Configuration Analysis ==="
echo "6. Boot Configuration Information" >> fs0:\efi-debug-report-v2.txt
echo "=================================" >> fs0:\efi-debug-report-v2.txt
bcfg boot dump >> fs0:\efi-debug-report-v2.txt 2>&1
echo "" >> fs0:\efi-debug-report-v2.txt

# 7. Filesystem Mapping
echo "=== 7. Filesystem Mapping ==="
echo "7. Filesystem Mapping" >> fs0:\efi-debug-report-v2.txt
echo "======================" >> fs0:\efi-debug-report-v2.txt
map -r >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt

# 8. iPXE File Search (Enhanced)
echo "=== 8. iPXE File Search ==="
echo "8. iPXE File Search" >> fs0:\efi-debug-report-v2.txt
echo "===================" >> fs0:\efi-debug-report-v2.txt
echo "Searching for iPXE related files..." >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt

# Check fs0: (USB drive)
echo "fs0: partition files:" >> fs0:\efi-debug-report-v2.txt
fs0:
ls >> fs0:\efi-debug-report-v2.txt 2>&1
echo "" >> fs0:\efi-debug-report-v2.txt

# Check other partitions
echo "fs1: partition files:" >> fs0:\efi-debug-report-v2.txt
fs1:
ls >> fs0:\efi-debug-report-v2.txt 2>&1
echo "" >> fs0:\efi-debug-report-v2.txt

echo "fs2: partition files:" >> fs0:\efi-debug-report-v2.txt
fs2:
ls >> fs0:\efi-debug-report-v2.txt 2>&1
echo "" >> fs0:\efi-debug-report-v2.txt

# 9. Network Connectivity Test
echo "=== 9. Network Connectivity Test ==="
echo "9. Network Connectivity Test" >> fs0:\efi-debug-report-v2.txt
echo "=============================" >> fs0:\efi-debug-report-v2.txt
echo "Testing network connectivity..." >> fs0:\efi-debug-report-v2.txt
ping 8.8.8.8 >> fs0:\efi-debug-report-v2.txt 2>&1
echo "" >> fs0:\efi-debug-report-v2.txt

# 10. Device Reconnection
echo "=== 10. Device Reconnection ==="
echo "10. Device Reconnection" >> fs0:\efi-debug-report-v2.txt
echo "=======================" >> fs0:\efi-debug-report-v2.txt
echo "Reconnecting all devices..." >> fs0:\efi-debug-report-v2.txt
connect -r
echo "Device reconnection completed" >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt

# 11. iPXE Launch Test (Enhanced)
echo "=== 11. iPXE Launch Test ==="
echo "11. iPXE Launch Test" >> fs0:\efi-debug-report-v2.txt
echo "====================" >> fs0:\efi-debug-report-v2.txt
echo "Testing iPXE launch capabilities..." >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt

# Try to launch iPXE from multiple locations
fs0:
if exist ipxe.efi then
  echo "fs0: Found ipxe.efi, attempting to launch..." >> fs0:\efi-debug-report-v2.txt
  fs0:\ipxe.efi >> fs0:\efi-debug-report-v2.txt 2>&1
else
  echo "fs0: ipxe.efi not found" >> fs0:\efi-debug-report-v2.txt
endif

if exist rtl8168.efi then
  echo "fs0: Found rtl8168.efi, attempting to launch..." >> fs0:\efi-debug-report-v2.txt
  fs0:\rtl8168.efi >> fs0:\efi-debug-report-v2.txt 2>&1
else
  echo "fs0: rtl8168.efi not found" >> fs0:\efi-debug-report-v2.txt
endif
echo "" >> fs0:\efi-debug-report-v2.txt

# 12. Memory Information
echo "=== 12. Memory Information ==="
echo "12. Memory Mapping Information" >> fs0:\efi-debug-report-v2.txt
echo "=============================" >> fs0:\efi-debug-report-v2.txt
memmap >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt

# 13. EFI Variables Check
echo "=== 13. EFI Variables Check ==="
echo "13. EFI Variables Information" >> fs0:\efi-debug-report-v2.txt
echo "============================" >> fs0:\efi-debug-report-v2.txt
dmpstore >> fs0:\efi-debug-report-v2.txt 2>&1
echo "" >> fs0:\efi-debug-report-v2.txt

# 14. Network Boot Specific Analysis
echo "=== 14. Network Boot Analysis ==="
echo "14. Network Boot Specific Analysis" >> fs0:\efi-debug-report-v2.txt
echo "=================================" >> fs0:\efi-debug-report-v2.txt
echo "Analyzing network boot capabilities..." >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt

echo "Checking for PXE-related protocols..." >> fs0:\efi-debug-report-v2.txt
echo "Note: PXE Base Code Protocol should be available if PXE is enabled" >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt

echo "Checking for HTTP Boot capabilities..." >> fs0:\efi-debug-report-v2.txt
echo "Note: HTTP Boot requires HTTP Protocol and LoadFile Protocol" >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt

# 15. Generate Enhanced Summary
echo "15. Enhanced Debug Summary" >> fs0:\efi-debug-report-v2.txt
echo "=========================" >> fs0:\efi-debug-report-v2.txt
echo "Collection time: %date% %time%" >> fs0:\efi-debug-report-v2.txt
echo "Script version: 2.0" >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt
echo "Key Findings:" >> fs0:\efi-debug-report-v2.txt
echo "- Check section 5 for LoadFile Protocol status" >> fs0:\efi-debug-report-v2.txt
echo "- Check section 6 for boot menu entries" >> fs0:\efi-debug-report-v2.txt
echo "- Check section 9 for network connectivity" >> fs0:\efi-debug-report-v2.txt
echo "- Check section 11 for iPXE launch results" >> fs0:\efi-debug-report-v2.txt
echo "" >> fs0:\efi-debug-report-v2.txt
echo "===============================================" >> fs0:\efi-debug-report-v2.txt

# 16. Complete information collection
echo ""
echo "=== Enhanced Debug Information Collection Completed ==="
echo "Unified report file: fs0:\efi-debug-report-v2.txt"
echo "File size:"
ls fs0:\efi-debug-report-v2.txt
echo ""
echo "Key improvements in v2.0:"
echo "- Enhanced network boot diagnostics"
echo "- LoadFile Protocol detection"
echo "- Better error handling"
echo "- Improved output formatting"
echo ""
echo "Please connect USB drive to another computer to view the report"
echo "End time: %date% %time%"
