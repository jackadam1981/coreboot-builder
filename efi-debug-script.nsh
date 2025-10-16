# EFI Shell Debug Script - Auto collect system info to USB
# Usage: Execute fs0:\efi-debug-script.nsh in EFI Shell

echo "=== EFI Shell Debug Information Collection Script ==="
echo "Start time: %date% %time%"
echo ""

# Set output directory to USB drive (usually fs0:)
echo ""

# Initialize unified report file
echo "===============================================" > fs0:\efi-debug-report.txt
echo "           EFI Shell Debug Report               " >> fs0:\efi-debug-report.txt
echo "===============================================" >> fs0:\efi-debug-report.txt
echo "Collection time: %date% %time%" >> fs0:\efi-debug-report.txt
echo "Script version: 1.0" >> fs0:\efi-debug-report.txt
echo "===============================================" >> fs0:\efi-debug-report.txt
echo "" >> fs0:\efi-debug-report.txt

# 1. Collect device information
echo "=== 1. Device Information ==="
echo "1. Device Information" >> fs0:\efi-debug-report.txt
echo "=====================" >> fs0:\efi-debug-report.txt
devices >> fs0:\efi-debug-report.txt
echo "" >> fs0:\efi-debug-report.txt

echo "1.2 Driver Information" >> fs0:\efi-debug-report.txt
echo "======================" >> fs0:\efi-debug-report.txt
drivers >> fs0:\efi-debug-report.txt
echo "" >> fs0:\efi-debug-report.txt
echo "Device information collection completed"

# 2. Reconnect devices
echo "=== 2. Reconnect Devices ==="
echo "2. Device Reconnection" >> fs0:\efi-debug-report.txt
echo "=======================" >> fs0:\efi-debug-report.txt
connect -r
echo "Device reconnection completed" >> fs0:\efi-debug-report.txt
echo "" >> fs0:\efi-debug-report.txt

# 3. Network interface check
echo "=== 3. Network Interface Check ==="
echo "3. Network Interface Information" >> fs0:\efi-debug-report.txt
echo "================================" >> fs0:\efi-debug-report.txt
ifconfig -l >> fs0:\efi-debug-report.txt 2>&1
echo "" >> fs0:\efi-debug-report.txt

# 4. Network connectivity test
echo "=== 4. Network Connectivity Test ==="
echo "4. Network Connectivity Test" >> fs0:\efi-debug-report.txt
echo "=============================" >> fs0:\efi-debug-report.txt
ping 8.8.8.8 >> fs0:\efi-debug-report.txt 2>&1
echo "" >> fs0:\efi-debug-report.txt

# 5. Filesystem mapping
echo "=== 5. Filesystem Mapping ==="
echo "5. Filesystem Mapping" >> fs0:\efi-debug-report.txt
echo "======================" >> fs0:\efi-debug-report.txt
map -r >> fs0:\efi-debug-report.txt
echo "" >> fs0:\efi-debug-report.txt

# 6. Search for iPXE files
echo "=== 6. Search for iPXE Files ==="
echo "6. iPXE File Search" >> fs0:\efi-debug-report.txt
echo "===================" >> fs0:\efi-debug-report.txt
echo "Searching for iPXE related files..." >> fs0:\efi-debug-report.txt
echo "" >> fs0:\efi-debug-report.txt

echo "fs0: partition files:" >> fs0:\efi-debug-report.txt
fs0:
ls -l >> fs0:\efi-debug-report.txt
echo "" >> fs0:\efi-debug-report.txt

# Check other partitions
echo "fs1: partition files:" >> fs0:\efi-debug-report.txt
fs1:
ls -l >> fs0:\efi-debug-report.txt 2>&1
echo "" >> fs0:\efi-debug-report.txt

echo "fs2: partition files:" >> fs0:\efi-debug-report.txt
fs2:
ls -l >> fs0:\efi-debug-report.txt 2>&1
echo "" >> fs0:\efi-debug-report.txt

# 7. Boot configuration check
echo "=== 7. Boot Configuration Check ==="
echo "7. Boot Configuration Information" >> fs0:\efi-debug-report.txt
echo "=================================" >> fs0:\efi-debug-report.txt
bcfg boot dump >> fs0:\efi-debug-report.txt 2>&1
echo "" >> fs0:\efi-debug-report.txt

# 8. Memory mapping information
echo "=== 8. Memory Mapping Information ==="
echo "8. Memory Mapping Information" >> fs0:\efi-debug-report.txt
echo "=============================" >> fs0:\efi-debug-report.txt
memmap >> fs0:\efi-debug-report.txt
echo "" >> fs0:\efi-debug-report.txt

# 9. PCI device information
echo "=== 9. PCI Device Information ==="
echo "9. PCI Device Information" >> fs0:\efi-debug-report.txt
echo "=========================" >> fs0:\efi-debug-report.txt
pci -l >> fs0:\efi-debug-report.txt 2>&1
echo "" >> fs0:\efi-debug-report.txt

# 10. EFI variables check
echo "=== 10. EFI Variables Check ==="
echo "10. EFI Variables Information" >> fs0:\efi-debug-report.txt
echo "============================" >> fs0:\efi-debug-report.txt
dmpstore >> fs0:\efi-debug-report.txt 2>&1
echo "" >> fs0:\efi-debug-report.txt

# 11. Try to launch iPXE
echo "=== 11. Try to Launch iPXE ==="
echo "11. iPXE Launch Test" >> fs0:\efi-debug-report.txt
echo "====================" >> fs0:\efi-debug-report.txt
echo "Attempting to launch iPXE..." >> fs0:\efi-debug-report.txt
echo "Current directory: %cwd%" >> fs0:\efi-debug-report.txt
echo "" >> fs0:\efi-debug-report.txt

# Try to launch iPXE from multiple locations
if exist ipxe.efi then
  echo "Found ipxe.efi, attempting to launch..." >> fs0:\efi-debug-report.txt
  ipxe.efi >> fs0:\efi-debug-report.txt 2>&1
else
  echo "ipxe.efi not found in current directory" >> fs0:\efi-debug-report.txt
endif

fs0:
if exist ipxe.efi then
  echo "fs0: Found ipxe.efi, attempting to launch..." >> fs0:\efi-debug-report.txt
  fs0:\ipxe.efi >> fs0:\efi-debug-report.txt 2>&1
else
  echo "fs0: ipxe.efi not found" >> fs0:\efi-debug-report.txt
endif
echo "" >> fs0:\efi-debug-report.txt

# 12. Generate summary
echo "12. Debug Summary" >> fs0:\efi-debug-report.txt
echo "=================" >> fs0:\efi-debug-report.txt
echo "Collection time: %date% %time%" >> fs0:\efi-debug-report.txt
echo "Script version: 1.0" >> fs0:\efi-debug-report.txt
echo "===============================================" >> fs0:\efi-debug-report.txt

# 13. Complete information collection
echo ""
echo "=== Debug Information Collection Completed ==="
echo "Unified report file: fs0:\efi-debug-report.txt"
echo "File size:"
ls -l fs0:\efi-debug-report.txt
echo ""
echo "Please connect USB drive to another computer to view fs0:\efi-debug-report.txt file"
echo "End time: %date% %time%"
