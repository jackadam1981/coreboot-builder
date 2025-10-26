#!/bin/bash
# 合并所有 R8168 修复到单个文件

cd /home/jack/coreboot-builder

# 1. 恢复 r8168.c
echo "📋 恢复 r8168.c..."
cd coreboot && git restore src/drivers/net/r8168.c && cd ..

# 2. 手动应用所有修改
echo "📋 应用所有修改..."
cd coreboot

# 添加 VPD header
sed -i '26a\#include <drivers/vpd/vpd.h>' src/drivers/net/r8168.c

# 添加 VPD parsing (在 fetch_mac_vpd_key 函数开始处)
python3 << 'EOF'
import re

with open('src/drivers/net/r8168.c', 'r') as f:
    content = f.read()

# Add VPD parsing code before "if (fmap_locate_area_as_rdev"
vpd_code = '''	const char *vpd_value;
	int vpd_size;
	printk(BIOS_DEBUG, "r8168: Searching for VPD key: '%s'\\n", vpd_key);
	vpd_value = vpd_find(vpd_key, &vpd_size, VPD_RO);
	printk(BIOS_DEBUG, "r8168: vpd_find result: vpd_value=%p, vpd_size=%d\\n", vpd_value, vpd_size);
	if (vpd_value && vpd_size > 0) {
		int copy_size = MIN(vpd_size, MACLEN - 1);
		memcpy(macstrbuf, vpd_value, copy_size);
		macstrbuf[copy_size] = '\\0';
		printk(BIOS_DEBUG, "r8168: Found MAC in VPD using vpd_find: %s\\n", macstrbuf);
		return CB_SUCCESS;
	}
	printk(BIOS_DEBUG, "r8168: vpd_find failed, trying legacy method\\n");

'''

content = content.replace('	if (fmap_locate_area_as_rdev("RO_VPD", &rdev)) {', vpd_code + '	if (fmap_locate_area_as_rdev("RO_VPD", &rdev)) {')

# Fix get_mac_address
old_loop = '''	for (i = 0; i < 6; i++) {
		macaddr[i] = 0;
		macaddr[i] |= get_hex_digit(strbuf[offset]) << 4;
		macaddr[i] |= get_hex_digit(strbuf[offset + 1]);
		offset += 3;
	}'''

new_loop = '''	for (i = 0; i < 6; i++) {
		u8 hex1, hex2;
		hex1 = get_hex_digit(strbuf[offset]);
		hex2 = get_hex_digit(strbuf[offset + 1]);
		
		if (hex1 > 0x0f || hex2 > 0x0f) {
			printk(BIOS_ERR, "r8168: Invalid hex digit in MAC address at position %d\\n", i);
			return;
		}
		
		macaddr[i] = (hex1 << 4) | hex2;
		offset += 3;
	}
	printk(BIOS_DEBUG, "r8168: Parsed MAC address: %02x:%02x:%02x:%02x:%02x:%02x\\n",
	       macaddr[0], macaddr[1], macaddr[2], macaddr[3], macaddr[4], macaddr[5]);'''

content = content.replace(old_loop, new_loop)

with open('src/drivers/net/r8168.c', 'w') as f:
    f.write(content)

print("✅ 修改完成")
EOF

cd ..

echo "✅ 所有修改已应用"

