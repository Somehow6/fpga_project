#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Mode 1数据分析脚本
分析12位ADC counter数据（高8位 + 低4位格式）
"""
import sys

# 从TEST.txt读取数据
print("正在读取 TEST.txt...")
try:
    with open('TEST.txt', 'r', encoding='utf-8') as f:
        data_hex = f.read()
except FileNotFoundError:
    print("错误: 找不到 TEST.txt 文件")
    sys.exit(1)

# 解析数据
bytes_list = [int(b, 16) for b in data_hex.strip().split()]

print("="*80)
print("Mode 1 数据分析 (12-bit ADC Counter)")
print("="*80)
print(f"总字节数: {len(bytes_list)}")
print(f"总样本数: {len(bytes_list)//2} (每个样本2字节)")
print()

# 解析12位counter值
counters = []
for i in range(0, len(bytes_list)-1, 2):
    high_byte = bytes_list[i]
    low_byte = bytes_list[i+1]
    
    # 12位counter: high_byte是[11:4], low_byte是[3:0]（低4位有效）
    counter_value = (high_byte << 4) | (low_byte & 0x0F)
    counters.append(counter_value)

print(f"解析后counter数量: {len(counters)}")
print(f"Counter范围: 0x{min(counters):03X} - 0x{max(counters):03X} ({min(counters)} - {max(counters)})")
print()

# 检测连续性
print("="*80)
print("连续性检测")
print("="*80)

gaps = []
last_counter = None
continuous_segments = []
current_segment_start = 0
current_segment_length = 0

for idx, counter in enumerate(counters):
    if last_counter is None:
        last_counter = counter
        current_segment_length = 1
        continue
    
    expected = (last_counter + 1) & 0xFFF  # 12位counter，循环到0xFFF后归0
    
    if counter == expected:
        current_segment_length += 1
    else:
        # 检测到跳跃
        if current_segment_length > 0:
            continuous_segments.append({
                'start_idx': current_segment_start,
                'length': current_segment_length,
                'start_val': counters[current_segment_start],
                'end_val': last_counter
            })
        
        if counter < last_counter and last_counter < 0xF00:
            # 异常跳跃（不是正常回绕）
            gap_size = (0x1000 - last_counter) + counter - 1
        else:
            gap_size = (counter - last_counter - 1) & 0xFFF
        
        if gap_size > 0 and gap_size < 0xF00:  # 避免误报大跳跃为回绕
            gaps.append({
                'index': idx,
                'byte_pos': idx*2,
                'prev': last_counter,
                'curr': counter,
                'expected': expected,
                'gap_size': gap_size
            })
        
        current_segment_start = idx
        current_segment_length = 1
    
    last_counter = counter

# 添加最后一段
if current_segment_length > 0:
    continuous_segments.append({
        'start_idx': current_segment_start,
        'length': current_segment_length,
        'start_val': counters[current_segment_start],
        'end_val': last_counter
    })

print(f"连续数据段数量: {len(continuous_segments)}")
print(f"检测到的跳跃: {len(gaps)} 次")
print()

# 显示连续段统计
if len(continuous_segments) > 1:
    print("连续数据段详情 (前10段):")
    for i, seg in enumerate(continuous_segments[:10]):
        print(f"  段 {i+1}: 起始样本 {seg['start_idx']}, "
              f"长度 {seg['length']} 样本, "
              f"值范围 0x{seg['start_val']:03X} - 0x{seg['end_val']:03X}")

if len(gaps) > 0:
    print("\n" + "="*80)
    print("数据跳跃详情 (前10次)")
    print("="*80)
    for i, gap in enumerate(gaps[:10]):
        print(f"\n跳跃 {i+1} @ 样本 {gap['index']} (字节位置 {gap['byte_pos']}):")
        print(f"  前一个值: 0x{gap['prev']:03X} ({gap['prev']})")
        print(f"  当前值:   0x{gap['curr']:03X} ({gap['curr']})")
        print(f"  期望值:   0x{gap['expected']:03X} ({gap['expected']})")
        print(f"  缺失样本: {gap['gap_size']} 个 ({gap['gap_size']*2} 字节)")

    print("\n" + "="*80)
    print("数据丢失汇总")
    print("="*80)
    total_lost = sum(g['gap_size'] for g in gaps)
    print(f"总缺失样本数: {total_lost} 个 ({total_lost*2} 字节)")
    print(f"总接收样本数: {len(counters)} 个 ({len(counters)*2} 字节)")
    print(f"应有样本数:   {len(counters) + total_lost} 个")
    print(f"丢失率:       {total_lost/(len(counters)+total_lost)*100:.2f}%")
    
    # 跳跃大小分布
    gap_sizes = [g['gap_size'] for g in gaps]
    print(f"\n跳跃大小分布:")
    print(f"  最小跳跃: {min(gap_sizes)} 个样本")
    print(f"  最大跳跃: {max(gap_sizes)} 个样本")
    print(f"  平均跳跃: {sum(gap_sizes)/len(gap_sizes):.1f} 个样本")
    
    # 统计跳跃大小的分布
    from collections import Counter
    gap_distribution = Counter(gap_sizes)
    print(f"\n最常见的跳跃大小:")
    for size, count in gap_distribution.most_common(5):
        print(f"  跳跃 {size} 个样本: 出现 {count} 次")

# 检查周期性
if len(gaps) > 1:
    print("\n" + "="*80)
    print("周期性分析")
    print("="*80)
    gap_intervals = []
    for i in range(len(gaps)-1):
        interval = gaps[i+1]['index'] - gaps[i]['index']
        gap_intervals.append(interval)
    
    if gap_intervals:
        avg_interval = sum(gap_intervals) / len(gap_intervals)
        print(f"跳跃间隔统计 (前10个):")
        for i, interval in enumerate(gap_intervals[:10]):
            print(f"  跳跃 {i+1} 到 跳跃 {i+2}: {interval} 个样本")
        print(f"\n平均跳跃间隔: {avg_interval:.1f} 个样本")
        
        # 检查是否有周期性
        from collections import Counter
        interval_distribution = Counter(gap_intervals)
        if len(interval_distribution) < 10:  # 如果间隔种类很少，可能有周期性
            print(f"\n跳跃间隔分布:")
            for interval, count in interval_distribution.most_common(5):
                print(f"  间隔 {interval} 个样本: 出现 {count} 次")

print("\n" + "="*80)
print("分析完成")
print("="*80)
