#!/bin/bash

# 补丁脚本：在 MrChromebox 构建过程中添加 ERI 配置
# 这个脚本会在 make olddefconfig 之后添加我们的配置

set -e

# 检查是否在 coreboot 目录中
if [ ! -f "build-uefi.sh" ]; then
    echo "错误：请在 coreboot 目录中运行此脚本"
    exit 1
fi

# 备份原始构建脚本
if [ ! -f "build-uefi.sh.backup" ]; then
    cp build-uefi.sh build-uefi.sh.backup
    echo "已备份原始构建脚本"
fi

# 创建修改后的构建脚本
cat > build-uefi.sh << 'EOF'
#!/usr/bin/env bash
#

set -e

platforms=('snb_ivb' 'hsw' 'byt' 'bdw' 'bsw' 'skl' 'apl' 'kbl' 'whl' 'glk' \
           'cml' 'jsl' 'tgl' 'adl' 'adl_n' 'mtl' 'str' 'pco' 'czn' 'mdn')
build_targets=()

output_folder="../roms"
mkdir -p ${output_folder}

if [ -z "$1" ]; then
	for subdir in "${platforms[@]}"; do
		for cfg in configs/"$subdir"/config*.*; do
			build_targets+=("$(basename "$cfg" | cut -f2 -d'.')")
		done
	done
else
	build_targets=("$@")
fi

# get git rev
rev=$(git describe --tags --dirty)

for device in "${build_targets[@]}"; do
	filename="coreboot_edk2-${device}-mrchromebox_$(date +"%Y%m%d").rom"
	rm -f ${output_folder}/"${filename}"*
	rm -rf ./build
	cfg_file=$(find ./configs -name "config.$device.uefi")
	cp "$cfg_file" .config
	echo "CONFIG_LOCALVERSION=\"${rev}\"" >> .config
	make clean
	make olddefconfig
	
	# 添加我们的 ERI 配置（在 olddefconfig 之后）
	echo "" >> .config
	echo "# 自定义 ERI 配置" >> .config
	echo "CONFIG_RT8168_PUT_MAC_TO_ERI=y" >> .config
	
	if ! make -j"$(nproc)"; then
		echo -e "Error building $device"
		exit 1
	fi
	cp ./build/coreboot.rom ./"${filename}"
	sha1sum "${filename}" > "${filename}.sha1"
	mv "${filename}"* "${output_folder}"
done
EOF

chmod +x build-uefi.sh
echo "已创建修改后的构建脚本，包含 ERI 配置"
