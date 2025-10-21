#!/usr/bin/env python3
"""
修改 RTL8168 驱动支持 RTL8111H 网卡
Modify RTL8168 driver to support RTL8111H network card
"""

import re
import sys
import os

def modify_rtl8168_driver():
    """修改 RTL8168 驱动以支持 RTL8111H"""
    file_path = 'src/drivers/net/r8168.c'
    
    # 检查文件是否存在
    if not os.path.exists(file_path):
        print(f"❌ 错误：未找到文件 {file_path}")
        return False
    
    # 备份原文件
    backup_path = f"{file_path}.backup"
    if not os.path.exists(backup_path):
        import shutil
        shutil.copy2(file_path, backup_path)
        print(f"💾 已备份原文件到 {backup_path}")
    
    # 读取文件内容
    with open(file_path, 'r') as f:
        content = f.read()
    
    # 查找并替换 case 9 部分
    pattern = r'case 9:.*?break;'
    replacement = '''case 9:
			outl(maclo, io_base + ERIDR);
			inl(io_base + ERIDR);
			outl(0x8000f0e0, io_base + ERIAR);
			inl(io_base + ERIAR);
			outl(machi, io_base + ERIDR);
			inl(io_base + ERIDR);
			outl(0x800030e4, io_base + ERIAR);
			break;
		case 12: /* RTL8111H support */
		case 13: /* RTL8111H support */
		case 14: /* RTL8111H support */
		case 15: /* RTL8111H support */
		default: /* Support newer RTL8111H variants */
			/* Use the same ERI programming as revision 9 for RTL8111H */
			outl(maclo, io_base + ERIDR);
			inl(io_base + ERIDR);
			outl(0x8000f0e0, io_base + ERIAR);
			inl(io_base + ERIAR);
			outl(machi, io_base + ERIDR);
			inl(io_base + ERIDR);
			outl(0x800030e4, io_base + ERIAR);
			break;'''
    
    # 执行替换
    new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    # 检查是否有修改
    if new_content == content:
        print("⚠️ 警告：未找到匹配的 case 9 部分，可能已经修改过")
        return False
    
    # 写入修改后的内容
    with open(file_path, 'w') as f:
        f.write(new_content)
    
    print('✅ RTL8168 驱动已修改支持 RTL8111H')
    return True

def verify_modification():
    """验证修改结果"""
    file_path = 'src/drivers/net/r8168.c'
    
    if not os.path.exists(file_path):
        print(f"❌ 错误：未找到文件 {file_path}")
        return False
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # 检查是否包含 RTL8111H 支持
    if 'RTL8111H support' in content:
        print("🔍 验证成功：找到 RTL8111H 支持代码")
        return True
    else:
        print("❌ 验证失败：未找到 RTL8111H 支持代码")
        return False

if __name__ == '__main__':
    print("🔧 修改 RTL8168 驱动支持 RTL8111H...")
    
    # 修改驱动
    if modify_rtl8168_driver():
        # 验证修改结果
        verify_modification()
    else:
        print("❌ 修改失败")
        sys.exit(1)
