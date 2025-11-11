#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""快速分析相位log数据"""

import re
import statistics

# 读取log文件前部分
log_path = r'D:\senhaowang\project\data_output\相位解包结果_20251108_160630\phase_debug_log.txt'

with open(log_path, 'r', encoding='utf-8') as f:
    # 只读前500KB用于快速分析
    data = f.read(500000)

# 提取所有相位数据
phases = [float(m.group(1)) for m in re.finditer(r'相位 \(度\):\s+(\d+\.\d+)', data)]

print(f"=== Phase Data Analysis ===")
print(f"Total frames sampled: {len(phases)}")
print(f"Phase range: {min(phases):.2f}° - {max(phases):.2f}°")
print(f"Phase std dev: {statistics.stdev(phases):.2f}°")
print(f"Phase mean: {statistics.mean(phases):.2f}°")

# 分析相邻帧的相位变化
diffs = [phases[i] - phases[i-1] for i in range(1, min(1000, len(phases)))]
wrap_count = sum(1 for d in diffs if abs(d) > 180)

print(f"\nPhase wraps (|diff| > 180°) in first 1000 frames: {wrap_count}")
print(f"Average phase change per frame: {sum(diffs)/len(diffs):.3f}°")

# 显示前20帧的相位变化
print(f"\nFirst 20 frames phase progression:")
for i in range(min(20, len(phases))):
    if i == 0:
        print(f"  Frame {i:4d}: {phases[i]:6.2f}°")
    else:
        diff = phases[i] - phases[i-1]
        print(f"  Frame {i:4d}: {phases[i]:6.2f}° (Δ={diff:+7.2f}°)")

