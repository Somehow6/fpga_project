#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
COE文件生成脚本
用于生成Xilinx ROM IP核的初始化文件

用法:
1. 运行脚本：python gen_coe.py
2. 输出文件：output.coe
3. 位宽：10位（0-1023）
4. 深度：2^19 = 524288
"""

import numpy as np

# 数据大小：2^16 = 65536
DATA_SIZE = 2**16  # 65536

# 生成10位波形数据（0-1023）
# 这里生成正弦波作为示例，你可以根据需要修改波形类型
def generate_waveform(size, bit_width=10):
    """
    生成波形数据
    可选波形类型：
    1. 正弦波
    2. 三角波
    3. 方波
    4. 锯齿波
    """
    max_value = (2**bit_width) - 1  # 10位：1023
    mid_value = max_value // 2      # 中间值：511
    
    # 生成正弦波（一个完整周期）
    period = size  # 波形周期等于整个数据大小，整个ROM存储一个完整周期
    t = np.arange(size)
    waveform = mid_value + (mid_value * np.sin(2 * np.pi * t / period))
    
    # 转换为整数并限制在有效范围内
    data = np.clip(waveform, 0, max_value).astype(int)
    
    return data.tolist()

# 生成波形数据
data_list = generate_waveform(DATA_SIZE, bit_width=10)

# COE文件头
coe_header = """memory_initialization_radix=16;
memory_initialization_vector=
"""

# 生成COE内容
coe_content = []
for i in range(0, len(data_list), 16):  # 每行16个数据
    chunk = data_list[i:i+16]
    # 转换为16进制字符串，10位数据用3位十六进制表示（0x000-0x3FF）
    line = ','.join([f"{value:03X}" for value in chunk])
    coe_content.append(line)

# 最后一行不需要逗号
coe_content[-1] = coe_content[-1].rstrip(',')

# 写入文件
output_file = 'output.coe'
print(f"正在生成COE文件，这可能需要一些时间...")
with open(output_file, 'w') as f:
    f.write(coe_header)
    for line in coe_content[:-1]:
        f.write(line + ',\n')  # 除了最后一行，加逗号和换行
    f.write(coe_content[-1] + ';\n')  # 最后一行加分号

print(f"COE文件生成完成: {output_file}")
print(f"位宽: 10位")
print(f"数据深度: {len(data_list)} (2^19 = {2**19})")
print(f"数值范围: 0-1023 (0x000-0x3FF)")
print(f"波形类型: 正弦波")
