#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
TDMS数据分析脚本 - 检查CH1_Raw数据的连续性和截断情况
正常情况：数据差分值应该是+2或-254（255->1的回绕）
"""

import numpy as np
from nptdms import TdmsFile
import sys
import io

# 设置输出编码为UTF-8
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# TDMS文件路径
tdms_file_path = r"C:\Users\DELL\usb2-fpga-ft2232h\usb2-fpga-ft2232h-main\python_version\data\stream_20251105_160116.tdms"

print("=" * 80)
print("TDMS数据分析 - CH1_Raw异常点分布规律检查")
print("=" * 80)

# 读取TDMS文件
print(f"\n正在读取文件...")
try:
    tdms_file = TdmsFile.read(tdms_file_path)
    print("[OK] 文件读取成功")
except Exception as e:
    print(f"[错误] 文件读取失败: {e}")
    sys.exit(1)

# 获取CH1_Raw数据
print("正在提取CH1_Raw数据...")
ch1_data = None
for group in tdms_file.groups():
    for channel in group.channels():
        if 'CH1_Raw' in channel.name or channel.name == 'CH1_Raw':
            ch1_data = channel[:]
            print(f"[OK] 找到CH1_Raw数据，共 {len(ch1_data):,} 个采样点")
            break
    if ch1_data is not None:
        break

if ch1_data is None:
    print("[错误] 未找到CH1_Raw通道")
    sys.exit(1)

# 计算差分
print("\n正在计算差分...")
diff = np.diff(ch1_data.astype(int))

# 正常情况：差分应该是+2，或者从255跳到1时是-254
normal_increment = (diff == 2)
normal_wrap = (diff == -254)
normal_points = normal_increment | normal_wrap

# 找出真正的异常点
error_indices = np.where(~normal_points)[0]
error_count = len(error_indices)

print("\n" + "=" * 80)
print("基本统计:")
print("=" * 80)
print(f"  总数据点: {len(ch1_data):,}")
print(f"  正常递增点 (差分=2): {np.sum(normal_increment):,} ({np.sum(normal_increment)/len(diff)*100:.2f}%)")
print(f"  正常回绕点 (差分=-254): {np.sum(normal_wrap):,}")
print(f"  异常点数量: {error_count:,} ({error_count/len(diff)*100:.4f}%)")

if error_count == 0:
    print("\n[OK] 数据完全正常，无异常！")
    sys.exit(0)

print(f"\n[警告] 发现 {error_count:,} 处异常！")

# 统计异常差分值
error_diffs = diff[error_indices]
unique_errors, error_counts = np.unique(error_diffs, return_counts=True)

print("\n" + "=" * 80)
print("异常差分值统计:")
print("=" * 80)
print(f"  {'差分值':<10} {'出现次数':<12} {'占比':<10}")
print("  " + "-" * 40)
for val, count in sorted(zip(unique_errors, error_counts), key=lambda x: -x[1]):
    print(f"  {val:<10} {count:<12,} {count/error_count*100:>7.2f}%")

# 详细展示前50个异常点
print("\n" + "=" * 80)
print("前50个异常点详情:")
print("=" * 80)
print(f"  {'序号':<6} {'位置':<12} {'当前值':<8} {'下一值':<8} {'差值':<8}")
print("  " + "-" * 50)
for i, idx in enumerate(error_indices[:50]):
    print(f"  {i+1:<6} {idx:<12,} {int(ch1_data[idx]):<8} {int(ch1_data[idx+1]):<8} {diff[idx]:<8}")

if error_count > 50:
    print(f"\n  ... 还有 {error_count-50:,} 处异常未显示")

# 分析异常点间距规律
print("\n" + "=" * 80)
print("异常点间距分析:")
print("=" * 80)

if error_count > 1:
    error_gaps = np.diff(error_indices)
    
    print(f"  最小间距: {np.min(error_gaps):,}")
    print(f"  最大间距: {np.max(error_gaps):,}")
    print(f"  平均间距: {np.mean(error_gaps):,.2f}")
    print(f"  中位数间距: {np.median(error_gaps):,.0f}")
    print(f"  间距标准差: {np.std(error_gaps):,.2f}")
    
    # 统计间距分布
    unique_gaps, gap_counts = np.unique(error_gaps, return_counts=True)
    
    print("\n  间距分布统计（出现次数最多的前20种）:")
    print(f"  {'间距':<12} {'出现次数':<12} {'占比':<10}")
    print("  " + "-" * 40)
    
    sorted_gaps = sorted(zip(unique_gaps, gap_counts), key=lambda x: -x[1])
    for gap, count in sorted_gaps[:20]:
        print(f"  {gap:<12,} {count:<12,} {count/len(error_gaps)*100:>7.2f}%")
    
    # 检查是否有周期性
    if len(unique_gaps) <= 5:
        print("\n  [注意] 间距种类很少，存在明显的周期性规律！")
    
    # 检查最常见的间距
    most_common_gap = unique_gaps[np.argmax(gap_counts)]
    most_common_count = np.max(gap_counts)
    
    if most_common_count > len(error_gaps) * 0.5:
        print(f"\n  [发现规律] 最常见的间距是 {most_common_gap:,}，")
        print(f"              占所有间距的 {most_common_count/len(error_gaps)*100:.2f}%")
        print(f"              这意味着异常点大约每隔 {most_common_gap:,} 个点出现一次")
        
        # 如果间距非常规律，计算期望的异常点总数
        expected_errors = len(ch1_data) // most_common_gap
        print(f"              基于此规律，预期约有 {expected_errors:,} 个异常点")
        print(f"              实际异常点: {error_count:,}")
        
        if abs(expected_errors - error_count) < error_count * 0.1:
            print(f"              两者非常接近，证明异常点分布非常规律！")

# 分析异常点在整个数据中的分布
print("\n" + "=" * 80)
print("异常点时间分布:")
print("=" * 80)

# 将数据分成10段，看每段的异常数量
segment_count = 10
segment_size = len(diff) // segment_count

print(f"  将数据分为{segment_count}段，每段约 {segment_size:,} 个点:")
print(f"  {'段号':<6} {'起始位置':<14} {'结束位置':<14} {'异常数':<10} {'占比':<10}")
print("  " + "-" * 60)

for seg in range(segment_count):
    start = seg * segment_size
    end = (seg + 1) * segment_size if seg < segment_count - 1 else len(diff)
    
    # 统计这一段的异常数量
    seg_errors = np.sum((error_indices >= start) & (error_indices < end))
    seg_ratio = seg_errors / (end - start) * 100
    
    print(f"  {seg+1:<6} {start:<14,} {end:<14,} {seg_errors:<10,} {seg_ratio:>7.4f}%")

print("\n" + "=" * 80)
print("分析完成！")
print("=" * 80)
