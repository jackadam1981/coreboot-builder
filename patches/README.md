# Coreboot RTL8168 Driver Patches

This directory contains patches for fixing MAC address issues in the RTL8168/RTL8111H driver for Google Kaisa mainboards.

## Patch Files

### Core Patches (Required)

1. **`fix-vpd-header.patch`** - Adds VPD header include
   - Adds `#include <drivers/vpd/vpd.h>` to enable VPD parsing functions

2. **`fix-vpd-parsing.patch`** - Improves VPD parsing with vpd_find()
   - Uses `vpd_find()` function for better VPD parsing compatibility
   - Falls back to legacy parsing method if vpd_find() fails
   - Adds debug output for VPD parsing

3. **`fix-get-mac-address.patch`** - Fixes critical MAC address parsing bug
   - Removes erroneous `macaddr[i] = 0;` line that caused MAC addresses to be all zeros
   - Adds hex digit validation and error handling
   - Adds debug output for parsed MAC addresses

4. **`fix-rtl8111h-eri.patch`** - Adds RTL8111H revision 12-15 ERI support
   - Adds case 12, 13, 14, 15 to program_mac_address function
   - Uses same ERI programming sequence as case 9
   - Adds debug output for ERI programming

## Application Order

Patches should be applied in the following order:

1. `fix-vpd-header.patch`
2. `fix-vpd-parsing.patch`
3. `fix-get-mac-address.patch`
4. `fix-rtl8111h-eri.patch`

## Usage

```bash
cd coreboot
patch -p1 < ../patches/fix-vpd-header.patch
patch -p1 < ../patches/fix-vpd-parsing.patch
patch -p1 < ../patches/fix-get-mac-address.patch
patch -p1 < ../patches/fix-rtl8111h-eri.patch
```

## Verification

Each patch can be verified using:

```bash
patch --dry-run -p1 < ../patches/fix-*.patch
```

## Backup Directory

The `backup/` directory contains all previous patch files for reference.

## Clean Directory

The `clean/` directory contains cleanup scripts and utilities.