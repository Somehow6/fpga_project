#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Mode 2 TDMS数据分析脚本
分析帧结构数据（每帧：帧头0xAA 0x55 + 128样本×2字节 + 帧尾0x55 0xAA）
检测数据缺失、帧结构错误、数据异常等
"""

import numpy as np
from nptdms import TdmsFile
import sys
import io
from pathlib import Path

# 设置输出编码为UTF-8
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# ============================================================================
# 配置参数
# ============================================================================
# 支持的文件类型：.tdms 或 .txt
# TXT文件格式：16进制数据，空格分隔，例如：80 0B 80 0C 80 0C 80 0B
# 修改下面的路径来分析不同的文件
DATA_FILE_PATH = r"D:\senhaowang\project\33_hs_dual_da\TEST.txt"
# DATA_FILE_PATH = r"C:\Users\DELL\usb2-fpga-ft2232h\usb2-fpga-ft2232h-main\python_version\stream_20251106_002742.tdms"

# 帧结构参数
FRAME_HEADER1 = 0xAA
FRAME_HEADER2 = 0x55
FRAME_TRAILER1 = 0x55
FRAME_TRAILER2 = 0xAA
SAMPLES_PER_FRAME = 128
BYTES_PER_FRAME = 2 + SAMPLES_PER_FRAME * 2 + 2  # Header(2) + Data(256) + Trailer(2) = 260

# ============================================================================
# 文件读取函数
# ============================================================================

def read_txt_file(file_path, output=sys.stdout):
    """
    读取TXT文件，解析16进制数据
    格式：80 0B 80 0C 80 0C 80 0B（空格分隔的16进制数）
    返回：numpy uint8数组
    """
    print("正在读取TXT文件...", file=output)
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 分割并解析16进制数据
        hex_values = content.split()
        
        # 转换为整数数组
        data_list = []
        for hex_str in hex_values:
            try:
                # 移除可能的0x前缀
                if hex_str.startswith('0x') or hex_str.startswith('0X'):
                    value = int(hex_str, 16)
                else:
                    value = int(hex_str, 16)
                
                # 确保值在0-255范围内
                if 0 <= value <= 255:
                    data_list.append(value)
                else:
                    print(f"[警告] 跳过超出范围的值: {hex_str} = {value}", file=output)
            except ValueError:
                print(f"[警告] 无法解析的16进制值: {hex_str}", file=output)
                continue
        
        # 转换为numpy数组
        raw_data = np.array(data_list, dtype=np.uint8)
        print(f"[OK] 成功解析 {len(raw_data):,} 个字节", file=output)
        
        return raw_data
        
    except Exception as e:
        print(f"[错误] 读取TXT文件失败: {e}", file=output)
        return None

def read_tdms_file(file_path, output=sys.stdout):
    """
    读取TDMS文件
    返回：numpy uint8数组
    """
    print("正在读取TDMS文件...", file=output)
    try:
        tdms_file = TdmsFile.read(file_path)
        print("[OK] 文件读取成功", file=output)
    except Exception as e:
        print(f"[错误] 文件读取失败: {e}", file=output)
        return None
    
    # 查找原始数据通道
    print("\n正在查找数据通道...", file=output)
    raw_data = None
    channel_name = None
    
    for group in tdms_file.groups():
        for channel in group.channels():
            # 查找包含"Raw"或"raw"的通道
            if 'Raw' in channel.name or 'raw' in channel.name.lower():
                raw_data = channel[:]
                channel_name = channel.name
                print(f"[OK] 找到通道: {channel_name}", file=output)
                print(f"     数据类型: {raw_data.dtype}", file=output)
                print(f"     数据长度: {len(raw_data):,} 个点", file=output)
                break
        if raw_data is not None:
            break
    
    if raw_data is None:
        # 尝试查找第一个通道
        for group in tdms_file.groups():
            channels = list(group.channels())
            if len(channels) > 0:
                raw_data = channels[0][:]
                channel_name = channels[0].name
                print(f"[警告] 未找到Raw通道，使用第一个通道: {channel_name}", file=output)
                print(f"     数据类型: {raw_data.dtype}", file=output)
                print(f"     数据长度: {len(raw_data):,} 个点", file=output)
                break
    
    if raw_data is None:
        print("[错误] 未找到任何数据通道", file=output)
        return None
    
    # 转换为uint8数组
    if raw_data.dtype != np.uint8:
        print(f"正在转换数据类型: {raw_data.dtype} -> uint8", file=output)
        if raw_data.dtype == np.uint16:
            if np.max(raw_data) < 256:
                print(f"[注意] 数据是uint16类型，但值范围是0-{np.max(raw_data)}", file=output)
                print(f"      这是8位字节数据以uint16格式存储，直接转换", file=output)
                raw_data = raw_data.astype(np.uint8)
            else:
                print(f"[警告] 数据值超出8位范围(0-255)，范围是0-{np.max(raw_data)}", file=output)
                print(f"      强制转换为uint8（会截断高位）", file=output)
                raw_data = raw_data.astype(np.uint8)
        else:
            raw_data = raw_data.astype(np.uint8)
    
    return raw_data

# ============================================================================
# 帧结构解析函数
# ============================================================================

def find_frame_start(data, start_pos=0):
    """查找帧头位置"""
    for i in range(start_pos, len(data) - 1):
        if data[i] == FRAME_HEADER1 and data[i+1] == FRAME_HEADER2:
            return i
    return -1

def find_frame_end(data, start_pos):
    """从指定位置查找帧尾（应该在start_pos + BYTES_PER_FRAME - 2处）"""
    expected_end = start_pos + BYTES_PER_FRAME - 2
    if expected_end + 1 < len(data):
        if data[expected_end] == FRAME_TRAILER1 and data[expected_end + 1] == FRAME_TRAILER2:
            return expected_end
    return -1

def parse_frame(data, start_pos):
    """解析一帧数据，返回(是否成功, 帧数据, 样本列表)"""
    if start_pos + BYTES_PER_FRAME > len(data):
        return False, None, None
    
    # 检查帧头
    if data[start_pos] != FRAME_HEADER1 or data[start_pos + 1] != FRAME_HEADER2:
        return False, None, None
    
    # 检查帧尾
    trailer_pos = start_pos + BYTES_PER_FRAME - 2
    if trailer_pos + 1 >= len(data):
        return False, None, None
    
    if data[trailer_pos] != FRAME_TRAILER1 or data[trailer_pos + 1] != FRAME_TRAILER2:
        return False, None, None
    
    # 提取数据部分（跳过帧头帧尾）
    frame_data = data[start_pos + 2 : trailer_pos]
    
    # 解析128个样本（每个样本2字节）
    samples = []
    for i in range(0, len(frame_data) - 1, 2):
        high_byte = frame_data[i]
        low_byte = frame_data[i + 1]
        # 12位数据：high_byte是[11:4], low_byte是[3:0]（低4位有效）
        sample = (high_byte << 4) | (low_byte & 0x0F)
        samples.append(sample)
    
    return True, frame_data, samples

# ============================================================================
# 主分析函数
# ============================================================================

def analyze_mode2_data(data_file_path, output=sys.stdout):
    """分析Mode 2数据"""
    
    print("=" * 80, file=output)
    print("Mode 2数据分析 - 帧结构检查", file=output)
    print("=" * 80, file=output)
    print(f"文件路径: {data_file_path}", file=output)
    print(f"期望帧结构: [{FRAME_HEADER1:02X} {FRAME_HEADER2:02X}] + 128样本×2字节 + [{FRAME_TRAILER1:02X} {FRAME_TRAILER2:02X}]", file=output)
    print(f"每帧字节数: {BYTES_PER_FRAME}", file=output)
    print(file=output)
    
    # 检测文件类型
    file_path = Path(data_file_path)
    file_extension = file_path.suffix.lower()
    
    print(f"检测到文件类型: {file_extension}", file=output)
    print(file=output)
    
    # 根据文件类型读取数据
    if file_extension == '.txt':
        raw_data = read_txt_file(data_file_path, output)
    elif file_extension == '.tdms':
        raw_data = read_tdms_file(data_file_path, output)
    else:
        print(f"[错误] 不支持的文件类型: {file_extension}", file=output)
        print(f"支持的类型: .txt, .tdms", file=output)
        return
    
    if raw_data is None:
        print("[错误] 数据读取失败", file=output)
        return
    
    print(f"\n原始字节数: {len(raw_data):,}", file=output)
    print(f"期望帧数（260字节/帧）: {len(raw_data) // BYTES_PER_FRAME:.1f}", file=output)
    print(f"可能帧数（256字节/帧，已去掉帧头帧尾）: {len(raw_data) // 256:.1f}", file=output)
    print(file=output)
    
    # 重点检查：根据帧头和帧尾来确定实际帧长
    print("=" * 80, file=output)
    print("帧结构检查：根据帧头+帧尾位置确定实际帧长", file=output)
    print("=" * 80, file=output)
    
    # 查找所有帧头位置
    aa_positions = np.where(raw_data == 0xAA)[0]
    aa55_positions = []
    for pos in aa_positions:
        if pos + 1 < len(raw_data) and raw_data[pos + 1] == 0x55:
            aa55_positions.append(pos)
    
    print(f"找到的帧头 (0xAA 0x55) 数量: {len(aa55_positions):,}", file=output)
    
    # 查找所有帧尾位置
    trailer_positions = []
    for i in range(len(raw_data) - 1):
        if raw_data[i] == FRAME_TRAILER1 and raw_data[i + 1] == FRAME_TRAILER2:
            trailer_positions.append(i)
    
    print(f"找到的帧尾 (0x55 0xAA) 数量: {len(trailer_positions):,}", file=output)
    
    # 根据帧头和帧尾配对形成完整帧
    # 策略：对于每个帧头，找到其后最近的一个帧尾
    # 优化：使用二分搜索加速查找
    import bisect
    
    complete_frames = []
    incomplete_frames = []
    frames_without_trailer = []
    
    print("正在配对帧头和帧尾...", file=output)
    for i, frame_start in enumerate(aa55_positions):
        # 显示进度（每处理10000个帧头显示一次）
        if i > 0 and i % 10000 == 0:
            print(f"  已处理 {i:,} / {len(aa55_positions):,} 个帧头...", file=output)
        # 在合理范围内搜索帧尾（最小20字节，最大1000字节）
        min_search_pos = frame_start + 20  # 至少10个样本
        max_search_pos = frame_start + 1000  # 最多500个样本
        
        # 使用二分搜索找到第一个 >= min_search_pos 的帧尾
        start_idx = bisect.bisect_left(trailer_positions, min_search_pos)
        
        # 从这个位置开始查找第一个在范围内的帧尾
        trailer_found = False
        trailer_pos = -1
        
        if start_idx < len(trailer_positions):
            t_pos = trailer_positions[start_idx]
            if t_pos < max_search_pos:
                trailer_pos = t_pos
                trailer_found = True
        
        if trailer_found:
            # 找到帧尾，计算实际帧长
            frame_length = trailer_pos - frame_start + 2  # +2 包含帧尾的2个字节
            frame_data = raw_data[frame_start : trailer_pos + 2]
            data_length = frame_length - 4  # 减去帧头2字节和帧尾2字节
            sample_count = data_length // 2  # 数据部分的样本数
            
            complete_frames.append({
                'frame_num': i,
                'start_pos': frame_start,
                'end_pos': trailer_pos + 1,
                'trailer_pos': trailer_pos,
                'frame_length': frame_length,
                'data_length': data_length,
                'sample_count': sample_count,
                'frame_data': frame_data
            })
        else:
            # 未找到帧尾
            # 检查是否是数据不足
            if frame_start + BYTES_PER_FRAME > len(raw_data):
                incomplete_frames.append({
                    'frame_num': i,
                    'start_pos': frame_start,
                    'type': 'insufficient_data',
                    'available_bytes': len(raw_data) - frame_start
                })
            else:
                frames_without_trailer.append({
                    'frame_num': i,
                    'start_pos': frame_start,
                    'type': 'trailer_not_found',
                    'search_range': (min_search_pos, min(max_search_pos, len(raw_data)))
                })
    
    print(f"完整帧数（找到帧头+帧尾）: {len(complete_frames):,}", file=output)
    print(f"不完整帧数（数据不足）: {len(incomplete_frames):,}", file=output)
    print(f"未找到帧尾的帧数: {len(frames_without_trailer):,}", file=output)
    print(f"总计检查的帧头数: {len(aa55_positions):,}", file=output)
    
    if len(aa55_positions) > 0:
        complete_ratio = len(complete_frames) / len(aa55_positions) * 100
        incomplete_ratio = len(incomplete_frames) / len(aa55_positions) * 100
        trailer_error_ratio = len(frames_without_trailer) / len(aa55_positions) * 100
        
        print(f"\n比例统计:", file=output)
        print(f"  完整帧比例: {complete_ratio:.2f}%", file=output)
        print(f"  不完整帧比例: {incomplete_ratio:.2f}%", file=output)
        print(f"  未找到帧尾比例: {trailer_error_ratio:.2f}%", file=output)
    
    # 统计实际帧长分布
    if len(complete_frames) > 0:
        frame_lengths = [f['frame_length'] for f in complete_frames]
        sample_counts = [f['sample_count'] for f in complete_frames]
        
        print(f"\n实际帧长统计:", file=output)
        print(f"  最小帧长: {np.min(frame_lengths)} 字节", file=output)
        print(f"  最大帧长: {np.max(frame_lengths)} 字节", file=output)
        print(f"  平均帧长: {np.mean(frame_lengths):.2f} 字节", file=output)
        print(f"  中位数帧长: {np.median(frame_lengths):.0f} 字节", file=output)
        print(f"  期望帧长: {BYTES_PER_FRAME} 字节", file=output)
        
        # 统计帧长分布
        unique_lengths, length_counts = np.unique(frame_lengths, return_counts=True)
        print(f"\n  帧长分布（最常见的10种）:", file=output)
        print(f"  {'帧长(字节)':<12} {'样本数':<12} {'出现次数':<12} {'占比':<10}", file=output)
        print("  " + "-" * 50, file=output)
        sorted_lengths = sorted(zip(unique_lengths, length_counts), key=lambda x: -x[1])[:10]
        for length, count in sorted_lengths:
            samples = (length - 4) // 2  # 减去帧头帧尾，除以2
            print(f"  {length:<12} {samples:<12} {count:<12,} {count/len(complete_frames)*100:>7.2f}%", file=output)
        
        # 统计260字节的帧数
        expected_count = np.sum(np.array(frame_lengths) == BYTES_PER_FRAME)
        print(f"\n  标准帧长（{BYTES_PER_FRAME}字节）的帧数: {expected_count:,} / {len(complete_frames):,} ({expected_count/len(complete_frames)*100:.2f}%)", file=output)
    
    # 显示不完整帧的详细信息
    if len(incomplete_frames) > 0:
        print(f"\n不完整帧详情（前20个）:", file=output)
        print(f"  {'帧号':<8} {'起始位置':<12} {'可用字节':<12} {'类型':<20}", file=output)
        print("  " + "-" * 60, file=output)
        for frame in incomplete_frames[:20]:
            print(f"  {frame['frame_num']:<8} {frame['start_pos']:<12,} {frame.get('available_bytes', 'N/A'):<12} {frame['type']:<20}", file=output)
    
    if len(frames_without_trailer) > 0:
        print(f"\n帧尾错误详情（前20个）:", file=output)
        print(f"  {'帧号':<8} {'起始位置':<12} {'期望帧尾':<15} {'实际帧尾':<15}", file=output)
        print("  " + "-" * 60, file=output)
        for frame in frames_without_trailer[:20]:
            expected = frame.get('expected_trailer', ['N/A', 'N/A'])
            actual = frame.get('actual_trailer', ['N/A', 'N/A'])
            print(f"  {frame['frame_num']:<8} {frame['start_pos']:<12,} {hex(expected[0])} {hex(expected[1]):<10} {hex(actual[0])} {hex(actual[1]):<10}", file=output)
    
    # 检查帧头之间的间距
    if len(aa55_positions) > 1:
        print(f"\n帧头间距分析:", file=output)
        gaps = np.diff(aa55_positions)
        unique_gaps, gap_counts = np.unique(gaps, return_counts=True)
        
        print(f"  最小间距: {np.min(gaps)} 字节", file=output)
        print(f"  最大间距: {np.max(gaps)} 字节", file=output)
        print(f"  平均间距: {np.mean(gaps):.2f} 字节", file=output)
        print(f"  中位数间距: {np.median(gaps):.0f} 字节", file=output)
        print(f"  期望间距: {BYTES_PER_FRAME} 字节", file=output)
        
        print(f"\n  间距分布（最常见的10种）:", file=output)
        print(f"  {'间距':<12} {'出现次数':<12} {'占比':<10}", file=output)
        print("  " + "-" * 40, file=output)
        sorted_gaps = sorted(zip(unique_gaps, gap_counts), key=lambda x: -x[1])[:10]
        for gap, count in sorted_gaps:
            print(f"  {gap:<12,} {count:<12,} {count/len(gaps)*100:>7.2f}%", file=output)
        
        # 检查有多少帧间距是正确的（260字节）
        correct_gaps = np.sum(gaps == BYTES_PER_FRAME)
        print(f"\n  间距正确（{BYTES_PER_FRAME}字节）的帧数: {correct_gaps:,} / {len(gaps):,} ({correct_gaps/len(gaps)*100:.2f}%)", file=output)
    
    # 决定使用哪种格式
    if len(complete_frames) > len(aa55_positions) * 0.5:
        print("\n" + "=" * 80, file=output)
        print("[结论] 数据包含帧头帧尾，多数帧是完整的260字节", file=output)
        print("=" * 80, file=output)
        parse_as_parsed_format = False
        frames = complete_frames  # 使用完整帧列表
    else:
        print("\n" + "=" * 80, file=output)
        print("[结论] 数据可能是已解析格式（帧头帧尾已被PC端移除）", file=output)
        print("=" * 80, file=output)
        parse_as_parsed_format = True
        BYTES_PER_FRAME_PARSED = 256
        frames = []  # 将在下面重新解析
    
    # ========================================================================
    # 帧结构检测（如果前面没有检测到完整帧，则按已解析格式处理）
    # ========================================================================
    if parse_as_parsed_format:
        print("=" * 80, file=output)
        print("帧结构检测（按已解析格式）", file=output)
        print("=" * 80, file=output)
        frame_errors = []
        # 已解析格式：直接按256字节分割，无帧头帧尾
        print("按已解析格式处理（每256字节一帧，无帧头帧尾）", file=output)
        
        frame_count = 0
        pos = 0
        bytes_per_frame = BYTES_PER_FRAME_PARSED
        
        while pos + bytes_per_frame <= len(raw_data):
            # 提取帧数据（256字节 = 128样本 × 2字节）
            frame_data = raw_data[pos : pos + bytes_per_frame]
            
            # 解析128个样本
            samples = []
            for i in range(0, len(frame_data) - 1, 2):
                high_byte = frame_data[i]
                low_byte = frame_data[i + 1]
                sample = (high_byte << 4) | (low_byte & 0x0F)
                samples.append(sample)
            
            frames.append({
                'frame_num': frame_count,
                'start_pos': pos,
                'end_pos': pos + bytes_per_frame - 1,
                'samples': samples
            })
            frame_count += 1
            pos += bytes_per_frame
        
        # 检查是否有剩余数据
        remaining = len(raw_data) - pos
        if remaining > 0:
            frame_errors.append({
                'type': 'incomplete_frame',
                'position': pos,
                'remaining_bytes': remaining
            })
        
        print(f"找到完整帧数: {len(frames):,}", file=output)
        print(f"剩余数据: {remaining} 字节", file=output)
    
    else:
        # 完整格式：已经在前面的检查中检测到了完整帧
        print("=" * 80, file=output)
        print("帧结构检测（已检测到完整帧）", file=output)
        print("=" * 80, file=output)
        print(f"使用前面检测到的完整帧: {len(frames):,} 个", file=output)
        
        # 解析完整帧中的样本数据
        frame_errors = []
        for frame in frames:
            frame_data = frame['frame_data']
            # 跳过帧头（前2字节）和帧尾（后2字节），提取数据部分
            data_part = frame_data[2:-2]
            
            # 解析样本（实际样本数可能不是128）
            samples = []
            for i in range(0, len(data_part) - 1, 2):
                high_byte = data_part[i]
                low_byte = data_part[i + 1]
                sample = (high_byte << 4) | (low_byte & 0x0F)
                samples.append(sample)
            
            frame['samples'] = samples
            
            # 如果样本数不是期望的128，记录错误
            if len(samples) != SAMPLES_PER_FRAME:
                frame_errors.append({
                    'type': 'wrong_sample_count',
                    'frame_num': frame['frame_num'],
                    'start_pos': frame['start_pos'],
                    'expected': SAMPLES_PER_FRAME,
                    'actual': len(samples)
                })
            
            del frame['frame_data']  # 释放内存
    
    # ========================================================================
    # 后续分析（数据完整性检查等）
    # ========================================================================
    
    if len(frame_errors) > 0:
        print("\n帧错误详情:", file=output)
        print(f"  {'类型':<25} {'位置':<12} {'说明':<30}", file=output)
        print("  " + "-" * 70, file=output)
        for err in frame_errors[:20]:
            err_type = err['type']
            err_pos = err.get('start_pos', err.get('position', 'N/A'))
            if err_type == 'frame_not_aligned':
                print(f"  {err_type:<25} {err_pos:<12} 期望位置{err['expected_pos']}, 实际{err['actual_pos']}, 间隙{err['gap']}字节", file=output)
            elif err_type == 'frame_trailer_not_found':
                print(f"  {err_type:<25} {err_pos:<12} 帧尾未找到", file=output)
            elif err_type == 'frame_trailer_mismatch':
                trailer_bytes = err.get('trailer_bytes', [])
                print(f"  {err_type:<25} {err_pos:<12} 帧尾字节{trailer_bytes}", file=output)
            else:
                print(f"  {err_type:<25} {err_pos:<12} {str(err)}", file=output)
        
        if len(frame_errors) > 20:
            print(f"  ... 还有 {len(frame_errors) - 20} 个错误未显示", file=output)
    
    if len(frames) == 0:
        print("\n[错误] 未找到任何完整帧！", file=output)
        return
    
    # ========================================================================
    # 数据完整性检查
    # ========================================================================
    print("\n" + "=" * 80, file=output)
    print("数据完整性检查", file=output)
    print("=" * 80, file=output)
    
    all_samples = []
    for frame in frames:
        all_samples.extend(frame['samples'])
    
    # 统计实际样本数分布
    actual_sample_counts = [len(f['samples']) for f in frames]
    
    print(f"总样本数: {len(all_samples):,}", file=output)
    print(f"期望总样本数（如果都是128样本/帧）: {len(frames) * SAMPLES_PER_FRAME:,}", file=output)
    print(f"实际平均样本数/帧: {np.mean(actual_sample_counts):.2f}", file=output)
    print(f"样本数/帧范围: {np.min(actual_sample_counts)} - {np.max(actual_sample_counts)}", file=output)
    
    # 统计有多少帧是标准的128样本
    standard_frames = sum(1 for count in actual_sample_counts if count == SAMPLES_PER_FRAME)
    print(f"标准帧（{SAMPLES_PER_FRAME}样本/帧）数量: {standard_frames:,} / {len(frames):,} ({standard_frames/len(frames)*100:.2f}%)", file=output)
    
    if len(all_samples) != len(frames) * SAMPLES_PER_FRAME:
        missing_samples = len(frames) * SAMPLES_PER_FRAME - len(all_samples)
        if missing_samples > 0:
            print(f"[警告] 样本数少于期望！缺少 {missing_samples:,} 个样本", file=output)
        else:
            print(f"[警告] 样本数多于期望！多出 {-missing_samples:,} 个样本", file=output)
    
    # ========================================================================
    # 帧内数据连续性检查
    # ========================================================================
    print("\n" + "=" * 80, file=output)
    print("帧内数据连续性检查", file=output)
    print("=" * 80, file=output)
    
    frame_anomalies = []
    for frame in frames:
        samples = frame['samples']
        sample_count = len(samples)
        
        if sample_count != SAMPLES_PER_FRAME:
            frame_anomalies.append({
                'frame': frame['frame_num'],
                'type': 'sample_count_mismatch',
                'expected': SAMPLES_PER_FRAME,
                'actual': sample_count
            })
            # 继续检查其他异常，不要跳过
        
        if sample_count == 0:
            continue  # 空帧，跳过后续检查
        
        # 检查是否有异常值（全0或全1）
        zero_samples = sum(1 for s in samples if s == 0)
        max_samples = sum(1 for s in samples if s == 0xFFF)
        
        if zero_samples > sample_count * 0.5:
            frame_anomalies.append({
                'frame': frame['frame_num'],
                'type': 'too_many_zeros',
                'zero_count': zero_samples,
                'ratio': zero_samples / sample_count * 100
            })
        
        if max_samples > sample_count * 0.5:
            frame_anomalies.append({
                'frame': frame['frame_num'],
                'type': 'too_many_max',
                'max_count': max_samples,
                'ratio': max_samples / sample_count * 100
            })
        
        # 检查是否有突跳（差分过大）
        diffs = np.diff(samples)
        large_jumps = np.where(np.abs(diffs) > 1000)[0]  # 差分超过1000认为是异常
        
        if len(large_jumps) > 0:
            frame_anomalies.append({
                'frame': frame['frame_num'],
                'type': 'large_jumps',
                'jump_count': len(large_jumps),
                'jump_positions': large_jumps.tolist()
            })
    
    print(f"帧内异常数: {len(frame_anomalies):,}", file=output)
    
    if len(frame_anomalies) > 0:
        print("\n帧内异常详情（前20个）:", file=output)
        print(f"  {'帧号':<8} {'异常类型':<20} {'详情':<40}", file=output)
        print("  " + "-" * 70, file=output)
        for anomaly in frame_anomalies[:20]:
            frame_num = anomaly['frame']
            err_type = anomaly['type']
            if err_type == 'too_many_zeros':
                print(f"  {frame_num:<8} {err_type:<20} 零值样本: {anomaly['zero_count']} ({anomaly['ratio']:.1f}%)", file=output)
            elif err_type == 'too_many_max':
                print(f"  {frame_num:<8} {err_type:<20} 最大值样本: {anomaly['max_count']} ({anomaly['ratio']:.1f}%)", file=output)
            elif err_type == 'large_jumps':
                print(f"  {frame_num:<8} {err_type:<20} 突跳数: {anomaly['jump_count']}, 位置: {anomaly['jump_positions'][:5]}", file=output)
            else:
                print(f"  {frame_num:<8} {err_type:<20} {str(anomaly)}", file=output)
    
    # ========================================================================
    # 帧间连续性检查
    # ========================================================================
    print("\n" + "=" * 80, file=output)
    print("帧间连续性检查", file=output)
    print("=" * 80, file=output)
    
    if len(frames) > 1:
        frame_gaps = []
        for i in range(len(frames) - 1):
            current_end = frames[i]['end_pos']
            next_start = frames[i + 1]['start_pos']
            gap = next_start - current_end - 1
            
            if gap != 0:
                frame_gaps.append({
                    'frame_before': frames[i]['frame_num'],
                    'frame_after': frames[i + 1]['frame_num'],
                    'gap': gap
                })
        
        if len(frame_gaps) > 0:
            print(f"[警告] 发现 {len(frame_gaps):,} 处帧间间隙", file=output)
            print(f"  {'前帧号':<8} {'后帧号':<8} {'间隙字节数':<12}", file=output)
            print("  " + "-" * 30, file=output)
            for gap_info in frame_gaps[:20]:
                print(f"  {gap_info['frame_before']:<8} {gap_info['frame_after']:<8} {gap_info['gap']:<12}", file=output)
        else:
            print("[OK] 所有帧都是连续的，无间隙", file=output)
    
    # ========================================================================
    # 数据统计
    # ========================================================================
    print("\n" + "=" * 80, file=output)
    print("数据统计", file=output)
    print("=" * 80, file=output)
    
    all_samples_array = np.array(all_samples)
    
    print(f"样本值范围: 0x{np.min(all_samples_array):03X} - 0x{np.max(all_samples_array):03X} ({np.min(all_samples_array)} - {np.max(all_samples_array)})", file=output)
    print(f"样本平均值: {np.mean(all_samples_array):.2f}", file=output)
    print(f"样本标准差: {np.std(all_samples_array):.2f}", file=output)
    print(f"零值样本数: {np.sum(all_samples_array == 0):,} ({np.sum(all_samples_array == 0) / len(all_samples_array) * 100:.2f}%)", file=output)
    print(f"最大值样本数: {np.sum(all_samples_array == 0xFFF):,} ({np.sum(all_samples_array == 0xFFF) / len(all_samples_array) * 100:.2f}%)", file=output)
    
    # ========================================================================
    # 数据质量分析（详细）
    # ========================================================================
    print("\n" + "=" * 80, file=output)
    print("数据质量详细分析", file=output)
    print("=" * 80, file=output)
    
    # 检查零值分布
    print("\n零值样本分析:", file=output)
    zero_frames = []
    for frame in frames:
        samples = frame['samples']
        sample_count = len(samples)
        if sample_count == 0:
            continue
        zero_count = sum(1 for s in samples if s == 0)
        if zero_count > 0:
            zero_frames.append({
                'frame': frame['frame_num'],
                'zero_count': zero_count,
                'sample_count': sample_count,
                'ratio': zero_count / sample_count * 100
            })
    
    print(f"包含零值的帧数: {len(zero_frames):,} / {len(frames):,} ({len(zero_frames)/len(frames)*100:.2f}%)", file=output)
    if len(zero_frames) > 0:
        avg_zero_ratio = np.mean([f['ratio'] for f in zero_frames])
        print(f"平均零值比例: {avg_zero_ratio:.2f}%", file=output)
        print(f"零值最多的10帧:", file=output)
        sorted_zero_frames = sorted(zero_frames, key=lambda x: x['zero_count'], reverse=True)[:10]
        for f in sorted_zero_frames:
            print(f"  帧 {f['frame']:,}: {f['zero_count']} 个零值 ({f['ratio']:.1f}%)", file=output)
    
    # 检查数据值的分布
    print(f"\n数据值分布:", file=output)
    unique_values, counts = np.unique(all_samples_array, return_counts=True)
    print(f"唯一值数量: {len(unique_values)}", file=output)
    print(f"值范围: 0x{np.min(all_samples_array):03X} - 0x{np.max(all_samples_array):03X} ({np.min(all_samples_array)} - {np.max(all_samples_array)})", file=output)
    print(f"12位ADC理论最大值: 0xFFF (4095)", file=output)
    print(f"实际最大值覆盖率: {np.max(all_samples_array) / 0xFFF * 100:.2f}%", file=output)
    
    # 检查是否有数据突跳（可能是数据丢失）
    print(f"\n数据连续性检查:", file=output)
    all_diffs = np.diff(all_samples_array)
    large_jumps = np.where(np.abs(all_diffs) > 1000)[0]
    medium_jumps = np.where((np.abs(all_diffs) > 100) & (np.abs(all_diffs) <= 1000))[0]
    
    print(f"大跳变（|diff|>1000）: {len(large_jumps):,} 处", file=output)
    print(f"中等跳变（100<|diff|<=1000）: {len(medium_jumps):,} 处", file=output)
    
    if len(large_jumps) > 0:
        print(f"\n前20个大跳变详情:", file=output)
        for i, pos in enumerate(large_jumps[:20]):
            print(f"  位置 {pos:,}: {all_samples_array[pos]} -> {all_samples_array[pos+1]}, 差值: {all_diffs[pos]}", file=output)
    
    # 检查帧间数据连续性
    print(f"\n帧间数据连续性:", file=output)
    frame_boundary_jumps = []
    for i in range(len(frames) - 1):
        last_sample = frames[i]['samples'][-1]
        first_sample = frames[i + 1]['samples'][0]
        diff = abs(first_sample - last_sample)
        if diff > 100:
            frame_boundary_jumps.append({
                'frame_before': frames[i]['frame_num'],
                'frame_after': frames[i + 1]['frame_num'],
                'last': last_sample,
                'first': first_sample,
                'diff': diff
            })
    
    if len(frame_boundary_jumps) > 0:
        print(f"[警告] 发现 {len(frame_boundary_jumps):,} 处帧间大跳变（|diff|>100）", file=output)
        print(f"前20处帧间跳变:", file=output)
        for jump in frame_boundary_jumps[:20]:
            print(f"  帧 {jump['frame_before']} -> {jump['frame_after']}: {jump['last']} -> {jump['first']}, 差值: {jump['diff']}", file=output)
    else:
        print(f"[OK] 帧间数据连续性良好", file=output)
    
    # ========================================================================
    # 总结
    # ========================================================================
    print("\n" + "=" * 80, file=output)
    print("分析总结", file=output)
    print("=" * 80, file=output)
    
    total_errors = len(frame_errors) + len(frame_anomalies)
    
    if total_errors == 0:
        print("[✓] 数据完整，未发现异常！", file=output)
    else:
        print(f"[!] 发现 {total_errors:,} 处问题:", file=output)
        print(f"    - 帧结构错误: {len(frame_errors):,}", file=output)
        print(f"    - 帧内异常: {len(frame_anomalies):,}", file=output)
    
    print(f"\n完整帧数: {len(frames):,}", file=output)
    print(f"总样本数: {len(all_samples):,}", file=output)
    print(f"数据覆盖率: {len(frames) * BYTES_PER_FRAME / len(raw_data) * 100:.2f}%", file=output)
    
    print("\n" + "=" * 80, file=output)
    print("分析完成！", file=output)
    print("=" * 80, file=output)

# ============================================================================
# 主程序入口
# ============================================================================

if __name__ == "__main__":
    analyze_mode2_data(DATA_FILE_PATH)

