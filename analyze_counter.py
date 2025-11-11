#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
USB纯计数器数据分析脚本
数据格式：连续的8位计数器 (0x00, 0x01, 0x02, ...)
"""

def parse_data(filename):
    """解析USB数据文件"""
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read().strip()
    
    # 分割为十六进制字符串列表
    hex_values = content.split()
    
    # 转换为整数列表
    data = [int(h, 16) for h in hex_values]
    
    return data

def analyze_counter(data):
    """分析计数器连续性"""
    print("=" * 60)
    print("USB 计数器数据分析")
    print("=" * 60)
    
    total_bytes = len(data)
    print(f"\n总字节数: {total_bytes}")
    
    if total_bytes < 2:
        print("数据太少，无法分析")
        return
    
    # 分析计数器连续性
    print(f"\n【计数器连续性分析】")
    expected = data[0]
    missing_segments = []
    current_segment = None
    
    for i, value in enumerate(data):
        expected_mod = expected % 256
        
        if value != expected_mod:
            # 检测到丢失
            if current_segment is None:
                # 开始新的丢失段
                current_segment = {
                    'start_idx': i,
                    'expected': expected_mod,
                    'actual': value,
                    'missing_count': 0
                }
            
            # 计算丢失的数量
            if value > expected_mod:
                missing = value - expected_mod
            else:
                missing = (256 - expected_mod) + value
            
            current_segment['missing_count'] += missing
            expected = value
        else:
            # 计数器正常
            if current_segment is not None:
                # 结束当前丢失段
                current_segment['end_idx'] = i - 1
                missing_segments.append(current_segment)
                current_segment = None
        
        expected += 1
    
    # 如果最后还有未结束的丢失段
    if current_segment is not None:
        current_segment['end_idx'] = len(data) - 1
        missing_segments.append(current_segment)
    
    # 统计结果
    total_received = len(data)
    total_missing = sum(seg['missing_count'] for seg in missing_segments)
    total_expected = total_received + total_missing
    loss_rate = (total_missing / total_expected * 100) if total_expected > 0 else 0
    
    print(f"接收的计数器值: {total_received}")
    print(f"丢失的计数器值: {total_missing}")
    print(f"总期望值: {total_expected}")
    print(f"丢包率: {loss_rate:.2f}%")
    
    if missing_segments:
        print(f"\n【丢失详情】共 {len(missing_segments)} 段")
        for i, seg in enumerate(missing_segments[:10]):  # 只显示前10段
            print(f"  段 {i+1}: 索引 {seg['start_idx']}-{seg['end_idx']}, "
                  f"期望 0x{seg['expected']:02X}, 实际 0x{seg['actual']:02X}, "
                  f"丢失 {seg['missing_count']} 个值")
        
        if len(missing_segments) > 10:
            print(f"  ... (还有 {len(missing_segments) - 10} 段未显示)")
    else:
        print(f"\n✓ 未检测到丢包！数据完全连续。")
    
    # 显示数据样本
    print(f"\n【数据样本】")
    print(f"前30字节: {' '.join([f'{data[i]:02X}' for i in range(min(30, len(data)))])}")
    print(f"后30字节: {' '.join([f'{data[i]:02X}' for i in range(max(0, len(data) - 30), len(data))])}")
    
    print("\n" + "=" * 60)

if __name__ == "__main__":
    import sys
    
    # 配置输出编码
    if sys.stdout.encoding != 'utf-8':
        import io
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    
    filename = "usb_data.txt"
    
    try:
        data = parse_data(filename)
        analyze_counter(data)
    except FileNotFoundError:
        print(f"错误: 找不到文件 '{filename}'")
    except Exception as e:
        print(f"错误: {e}")
        import traceback
        traceback.print_exc()

