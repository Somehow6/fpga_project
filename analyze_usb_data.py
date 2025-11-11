#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
USB数据丢包分析脚本
数据格式：交替发送 [状态字节] [计数器值]
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

def analyze_packet_loss(data):
    """分析丢包情况"""
    print("=" * 60)
    print("USB 数据丢包分析")
    print("=" * 60)
    
    total_bytes = len(data)
    print(f"\n总字节数: {total_bytes}")
    
    if total_bytes < 2:
        print("数据太少，无法分析")
        return
    
    # 分离状态字节和计数器值
    status_bytes = []
    counter_values = []
    
    for i in range(0, len(data), 2):
        if i + 1 < len(data):
            status_bytes.append(data[i])
            counter_values.append(data[i + 1])
    
    print(f"数据对数量: {len(counter_values)}")
    
    # 分析状态字节
    print(f"\n【状态字节分析】")
    unique_status = set(status_bytes)
    print(f"唯一状态值: {[f'0x{s:02X}' for s in sorted(unique_status)]}")
    
    if len(unique_status) == 1:
        status = list(unique_status)[0]
        print(f"\n状态字节 0x{status:02X} (0b{status:08b}) 解析:")
        state_raw = status & 0x03
        fifo_empty = (status >> 2) & 0x01
        fifo_full = (status >> 3) & 0x01
        txe_sync = (status >> 4) & 0x01
        
        state_names = {0: "IDLE", 1: "WRITE", 2: "WAIT"}
        print(f"  - State: {state_names.get(state_raw, 'UNKNOWN')} ({state_raw})")
        print(f"  - FIFO Empty: {fifo_empty}")
        print(f"  - FIFO Full: {fifo_full}")
        print(f"  - TXE# Sync: {txe_sync}")
    
    # 分析计数器连续性
    print(f"\n【计数器连续性分析】")
    expected = counter_values[0]
    missing_segments = []
    current_segment = None
    
    for i, value in enumerate(counter_values):
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
        current_segment['end_idx'] = len(counter_values) - 1
        missing_segments.append(current_segment)
    
    # 统计结果
    total_received = len(counter_values)
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
    
    # 显示前后数据样本
    print(f"\n【数据样本】")
    print(f"前20对: ", end="")
    for i in range(min(20, len(counter_values))):
        print(f"[{status_bytes[i]:02X} {counter_values[i]:02X}] ", end="")
    print()
    
    print(f"后20对: ", end="")
    start = max(0, len(counter_values) - 20)
    for i in range(start, len(counter_values)):
        print(f"[{status_bytes[i]:02X} {counter_values[i]:02X}] ", end="")
    print()
    
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
        analyze_packet_loss(data)
    except FileNotFoundError:
        print(f"错误: 找不到文件 '{filename}'")
    except Exception as e:
        print(f"错误: {e}")
        import traceback
        traceback.print_exc()

