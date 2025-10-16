# EFI Shell Debug Script - Auto collect system info to USB
# Usage: Execute fs0:\efi-debug-script.nsh in EFI Shell

echo "=== EFI Shell Debug Information Collection Script ==="
echo "Start time: %date% %time%"
echo ""

# Set output directory to USB drive (usually fs0:)
set OUTPUT_PATH=fs0:\debug
set OUTPUT_FILE=fs0:\debug\efi-debug-report.txt
mkdir %OUTPUT_PATH% 2>nul
echo "Output directory: %OUTPUT_PATH%"
echo "Unified report file: %OUTPUT_FILE%"
echo ""

# Initialize unified report file
echo "===============================================" > %OUTPUT_FILE%
echo "           EFI Shell Debug Report               " >> %OUTPUT_FILE%
echo "===============================================" >> %OUTPUT_FILE%
echo "Collection time: %date% %time%" >> %OUTPUT_FILE%
echo "Script version: 1.0" >> %OUTPUT_FILE%
echo "===============================================" >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

# 1. Collect device information
echo "=== 1. Device Information ==="
echo "1. Device Information" >> %OUTPUT_FILE%
echo "=====================" >> %OUTPUT_FILE%
devices >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

echo "1.2 Driver Information" >> %OUTPUT_FILE%
echo "======================" >> %OUTPUT_FILE%
drivers >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%
echo "Device information collection completed"

# 2. Reconnect devices
echo "=== 2. Reconnect Devices ==="
echo "2. Device Reconnection" >> %OUTPUT_FILE%
echo "=======================" >> %OUTPUT_FILE%
connect -r
echo "Device reconnection completed" >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

# 3. Network interface check
echo "=== 3. Network Interface Check ==="
echo "3. Network Interface Information" >> %OUTPUT_FILE%
echo "================================" >> %OUTPUT_FILE%
ifconfig -l >> %OUTPUT_FILE% 2>&1
echo "" >> %OUTPUT_FILE%

# 4. Network connectivity test
echo "=== 4. Network Connectivity Test ==="
echo "4. Network Connectivity Test" >> %OUTPUT_FILE%
echo "=============================" >> %OUTPUT_FILE%
ping 8.8.8.8 >> %OUTPUT_FILE% 2>&1
echo "" >> %OUTPUT_FILE%

# 5. Filesystem mapping
echo "=== 5. Filesystem Mapping ==="
echo "5. Filesystem Mapping" >> %OUTPUT_FILE%
echo "======================" >> %OUTPUT_FILE%
map -r >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

# 6. Search for iPXE files
echo "=== 6. Search for iPXE Files ==="
echo "6. iPXE File Search" >> %OUTPUT_FILE%
echo "===================" >> %OUTPUT_FILE%
echo "Searching for iPXE related files..." >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

echo "fs0: partition files:" >> %OUTPUT_FILE%
fs0:
ls -l >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

# Check other partitions
echo "fs1: partition files:" >> %OUTPUT_FILE%
fs1:
ls -l >> %OUTPUT_FILE% 2>&1
echo "" >> %OUTPUT_FILE%

echo "fs2: partition files:" >> %OUTPUT_FILE%
fs2:
ls -l >> %OUTPUT_FILE% 2>&1
echo "" >> %OUTPUT_FILE%

# 7. Boot configuration check
echo "=== 7. Boot Configuration Check ==="
echo "7. Boot Configuration Information" >> %OUTPUT_FILE%
echo "=================================" >> %OUTPUT_FILE%
bcfg boot dump >> %OUTPUT_FILE% 2>&1
echo "" >> %OUTPUT_FILE%

# 8. Memory mapping information
echo "=== 8. Memory Mapping Information ==="
echo "8. Memory Mapping Information" >> %OUTPUT_FILE%
echo "=============================" >> %OUTPUT_FILE%
memmap >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

# 9. PCI device information
echo "=== 9. PCI Device Information ==="
echo "9. PCI Device Information" >> %OUTPUT_FILE%
echo "=========================" >> %OUTPUT_FILE%
pci -l >> %OUTPUT_FILE% 2>&1
echo "" >> %OUTPUT_FILE%

# 10. EFI variables check
echo "=== 10. EFI Variables Check ==="
echo "10. EFI Variables Information" >> %OUTPUT_FILE%
echo "============================" >> %OUTPUT_FILE%
dmpstore >> %OUTPUT_FILE% 2>&1
echo "" >> %OUTPUT_FILE%

# 11. Try to launch iPXE
echo "=== 11. Try to Launch iPXE ==="
echo "11. iPXE Launch Test" >> %OUTPUT_FILE%
echo "====================" >> %OUTPUT_FILE%
echo "Attempting to launch iPXE..." >> %OUTPUT_FILE%
echo "Current directory: %cwd%" >> %OUTPUT_FILE%
echo "" >> %OUTPUT_FILE%

# Try to launch iPXE from multiple locations
if exist ipxe.efi then
  echo "Found ipxe.efi, attempting to launch..." >> %OUTPUT_FILE%
  ipxe.efi >> %OUTPUT_FILE% 2>&1
else
  echo "ipxe.efi not found in current directory" >> %OUTPUT_FILE%
endif

fs0:
if exist ipxe.efi then
  echo "fs0: Found ipxe.efi, attempting to launch..." >> %OUTPUT_FILE%
  fs0:\ipxe.efi >> %OUTPUT_FILE% 2>&1
else
  echo "fs0: ipxe.efi not found" >> %OUTPUT_FILE%
endif
echo "" >> %OUTPUT_FILE%

# 12. Generate summary
echo "12. Debug Summary" >> %OUTPUT_FILE%
echo "=================" >> %OUTPUT_FILE%
echo "Collection time: %date% %time%" >> %OUTPUT_FILE%
echo "Script version: 1.0" >> %OUTPUT_FILE%
echo "===============================================" >> %OUTPUT_FILE%

# 13. Complete information collection
echo ""
echo "=== Debug Information Collection Completed ==="
echo "Unified report file: %OUTPUT_FILE%"
echo "File size:"
ls -l %OUTPUT_FILE%
echo ""
echo "Please connect USB drive to another computer to view %OUTPUT_FILE% file"
echo "End time: %date% %time%"
