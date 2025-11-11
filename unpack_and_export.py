#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ADC数据解包导出工具
解析帧结构数据，拼接样本，并导出为HTML图表和TDMS文件
"""

import numpy as np
from nptdms import TdmsFile, TdmsWriter, RootObject, GroupObject, ChannelObject
import sys
import io
from pathlib import Path
from datetime import datetime
import bisect

# 设置输出编码为UTF-8
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# ============================================================================
# 配置参数
# ============================================================================
# 帧结构参数
FRAME_HEADER1 = 0xAA
FRAME_HEADER2 = 0x55
FRAME_TRAILER1 = 0x55
FRAME_TRAILER2 = 0xAA
SAMPLES_PER_FRAME = 128
BYTES_PER_FRAME = 2 + SAMPLES_PER_FRAME * 2 + 2  # Header(2) + Data(256) + Trailer(2) = 260

# ADC参数
ADC_BITS = 12
ADC_MAX_VALUE = (1 << ADC_BITS) - 1  # 4095
ADC_VOLTAGE_REF = 5.0  # 参考电压 5V

# 默认输出目录
DEFAULT_OUTPUT_DIR = r"D:\senhaowang\project\data_output"

# ============================================================================
# 文件读取函数（复用自analyze_mode2_tdms.py）
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
# 帧解析和样本拼接函数
# ============================================================================

def parse_and_extract_samples(raw_data, output=sys.stdout):
    """
    解析帧结构并提取所有样本
    返回：(complete_frames列表, all_samples数组, 统计信息字典)
    """
    print("\n" + "=" * 80, file=output)
    print("帧结构解析和样本提取", file=output)
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
    
    # 配对帧头和帧尾（使用固定帧长验证）
    print("正在配对帧头和帧尾...", file=output)
    complete_frames = []
    incomplete_frames = []
    
    # 标准帧长度：帧头(2) + 数据(256) + 帧尾(2) = 260字节
    expected_frame_length = BYTES_PER_FRAME
    expected_trailer_offset = expected_frame_length - 2  # 帧尾在帧头后258字节
    
    for i, frame_start in enumerate(aa55_positions):
        # 显示进度
        if i > 0 and i % 10000 == 0:
            print(f"  已处理 {i:,} / {len(aa55_positions):,} 个帧头...", file=output)
        
        # 检查是否有足够的数据
        if frame_start + expected_frame_length > len(raw_data):
            incomplete_frames.append({
                'frame_num': i,
                'start_pos': frame_start,
                'reason': 'insufficient_data'
            })
            continue
        
        # 验证固定位置的帧尾
        trailer_pos = frame_start + expected_trailer_offset
        
        if (raw_data[trailer_pos] == FRAME_TRAILER1 and 
            raw_data[trailer_pos + 1] == FRAME_TRAILER2):
            # 帧尾正确，提取帧数据
            frame_data = raw_data[frame_start : frame_start + expected_frame_length]
            
            # 提取样本（跳过帧头2字节和帧尾2字节）
            data_part = frame_data[2:-2]
            samples = []
            
            for j in range(0, len(data_part) - 1, 2):
                # 转换为int类型，避免numpy.uint8的位运算截断问题
                high_byte = int(data_part[j])
                low_byte = int(data_part[j + 1])
                # 12位数据：high_byte是[11:4], low_byte是[3:0]（低4位有效）
                sample = (high_byte << 4) | (low_byte & 0x0F)
                samples.append(sample)
            
            complete_frames.append({
                'frame_num': i,
                'start_pos': frame_start,
                'end_pos': frame_start + expected_frame_length - 1,
                'frame_length': expected_frame_length,
                'sample_count': len(samples),
                'samples': samples
            })
        else:
            # 帧尾不匹配
            actual_bytes = (raw_data[trailer_pos], raw_data[trailer_pos + 1]) if trailer_pos + 1 < len(raw_data) else (0, 0)
            incomplete_frames.append({
                'frame_num': i,
                'start_pos': frame_start,
                'reason': 'trailer_mismatch',
                'expected': (FRAME_TRAILER1, FRAME_TRAILER2),
                'actual': actual_bytes
            })
    
    print(f"\n完整帧数: {len(complete_frames):,}", file=output)
    print(f"不完整帧数: {len(incomplete_frames):,}", file=output)
    
    if len(aa55_positions) > 0:
        complete_ratio = len(complete_frames) / len(aa55_positions) * 100
        print(f"完整帧比例: {complete_ratio:.2f}%", file=output)
    
    # 拼接所有样本
    print("\n正在拼接所有样本...", file=output)
    all_samples = []
    for frame in complete_frames:
        all_samples.extend(frame['samples'])
    
    all_samples_array = np.array(all_samples, dtype=np.uint16)
    print(f"[OK] 总样本数: {len(all_samples_array):,}", file=output)
    
    # 转换为电压值（0-4095 -> 0-5V）
    voltage_array = (all_samples_array / ADC_MAX_VALUE) * ADC_VOLTAGE_REF
    
    # 统计信息（ADC值）
    stats = {
        'total_frames': len(complete_frames),
        'incomplete_frames': len(incomplete_frames),
        'total_samples': len(all_samples_array),
        'min_value': int(np.min(all_samples_array)) if len(all_samples_array) > 0 else 0,
        'max_value': int(np.max(all_samples_array)) if len(all_samples_array) > 0 else 0,
        'mean_value': float(np.mean(all_samples_array)) if len(all_samples_array) > 0 else 0,
        'std_value': float(np.std(all_samples_array)) if len(all_samples_array) > 0 else 0,
        'min_voltage': float(np.min(voltage_array)) if len(voltage_array) > 0 else 0,
        'max_voltage': float(np.max(voltage_array)) if len(voltage_array) > 0 else 0,
        'mean_voltage': float(np.mean(voltage_array)) if len(voltage_array) > 0 else 0,
        'std_voltage': float(np.std(voltage_array)) if len(voltage_array) > 0 else 0
    }
    
    print(f"\nADC值统计:", file=output)
    print(f"  最小值: {stats['min_value']} (0x{stats['min_value']:03X})", file=output)
    print(f"  最大值: {stats['max_value']} (0x{stats['max_value']:03X})", file=output)
    print(f"  平均值: {stats['mean_value']:.2f}", file=output)
    print(f"  标准差: {stats['std_value']:.2f}", file=output)
    
    print(f"\n电压值统计 (0-5V):", file=output)
    print(f"  最小值: {stats['min_voltage']:.6f} V", file=output)
    print(f"  最大值: {stats['max_voltage']:.6f} V", file=output)
    print(f"  平均值: {stats['mean_voltage']:.6f} V", file=output)
    print(f"  标准差: {stats['std_voltage']:.6f} V", file=output)
    
    return complete_frames, all_samples_array, voltage_array, stats

# ============================================================================
# 导出函数
# ============================================================================

def save_as_html(all_samples, voltage_array, output_path, stats, output=sys.stdout):
    """使用plotly生成HTML交互式图表"""
    print("\n正在生成HTML图表...", file=output)
    
    try:
        import plotly.graph_objects as go
        from plotly.subplots import make_subplots
    except ImportError:
        print("[错误] 需要安装 plotly 库", file=output)
        return False
    
    # 创建子图（3行：ADC值波形、电压波形、局部放大）
    fig = make_subplots(
        rows=3, cols=1,
        subplot_titles=(
            'ADC值波形 (12-bit, 0-4095)',
            '电压波形 (0-5V)', 
            '局部数据 (前5000点) - 电压'
        ),
        vertical_spacing=0.08,
        row_heights=[0.35, 0.35, 0.30]
    )
    
    # 第1行：添加ADC值曲线
    fig.add_trace(
        go.Scattergl(
            x=list(range(len(all_samples))),
            y=all_samples.tolist(),
            mode='lines',
            name='ADC值',
            line=dict(color='royalblue', width=1),
            hovertemplate='<b>采样点</b>: %{x}<br><b>ADC值</b>: %{y} (0x%{y:X})<extra></extra>'
        ),
        row=1, col=1
    )
    
    # 第2行：添加电压曲线
    fig.add_trace(
        go.Scattergl(
            x=list(range(len(voltage_array))),
            y=voltage_array.tolist(),
            mode='lines',
            name='电压',
            line=dict(color='green', width=1),
            hovertemplate='<b>采样点</b>: %{x}<br><b>电压</b>: %{y:.6f} V<extra></extra>'
        ),
        row=2, col=1
    )
    
    # 第3行：添加局部电压曲线
    sample_size = min(5000, len(voltage_array))
    fig.add_trace(
        go.Scatter(
            x=list(range(sample_size)),
            y=voltage_array[:sample_size].tolist(),
            mode='lines',
            name=f'前{sample_size}点',
            line=dict(color='coral', width=1.5),
            hovertemplate='<b>采样点</b>: %{x}<br><b>电压</b>: %{y:.6f} V<extra></extra>'
        ),
        row=3, col=1
    )
    
    # 更新X轴标签
    fig.update_xaxes(title_text="采样点索引", row=1, col=1, gridcolor='lightgray')
    fig.update_xaxes(title_text="采样点索引", row=2, col=1, gridcolor='lightgray')
    fig.update_xaxes(title_text="采样点索引", row=3, col=1, gridcolor='lightgray')
    
    # 更新Y轴标签
    fig.update_yaxes(title_text="ADC值", row=1, col=1, gridcolor='lightgray')
    fig.update_yaxes(title_text="电压 (V)", row=2, col=1, gridcolor='lightgray')
    fig.update_yaxes(title_text="电压 (V)", row=3, col=1, gridcolor='lightgray')
    
    fig.update_layout(
        title_text=f"<b>ADC数据解包波形可视化</b><br>"
                   f"<sub>总样本数: {len(all_samples):,} | "
                   f"ADC值域: {stats['min_value']}-{stats['max_value']} | "
                   f"电压范围: {stats['min_voltage']:.3f}V-{stats['max_voltage']:.3f}V</sub>",
        title_x=0.5,
        height=1100,
        showlegend=True,
        hovermode='x unified',
        template='plotly_white',
        xaxis=dict(
            rangeslider=dict(visible=True, thickness=0.03),
            type='linear'
        )
    )
    
    # 保存HTML文件
    fig.write_html(str(output_path))
    print(f"[OK] HTML图表已保存: {output_path}", file=output)
    
    return True

def save_as_tdms(raw_data, all_samples, voltage_array, output_path, stats, source_file, output=sys.stdout):
    """保存为TDMS文件格式"""
    print("\n正在生成TDMS文件...", file=output)
    
    try:
        # 获取当前时间戳
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # 创建根对象和属性
        root = RootObject(properties={
            "创建时间": timestamp,
            "来源文件": str(source_file),
            "数据类型": "ADC解包数据"
        })
        
        # 创建组
        group_name = "ADC_Data"
        group = GroupObject(group_name, properties={
            "完整帧数": stats['total_frames'],
            "不完整帧数": stats['incomplete_frames'],
            "总样本数": stats['total_samples']
        })
        
        # 创建通道1：原始字节数据
        ch1 = ChannelObject(
            group_name, 
            "Raw_Bytes", 
            raw_data, 
            properties={
                "数据类型": "uint8",
                "描述": "原始字节数据（包含帧头帧尾）",
                "字节数": len(raw_data)
            }
        )
        
        # 创建通道2：解包后的ADC样本数据
        ch2 = ChannelObject(
            group_name, 
            "Samples_ADC", 
            all_samples, 
            properties={
                "数据类型": "uint16",
                "描述": "解包后的12位ADC样本值 (0-4095)",
                "样本数": len(all_samples),
                "最小值": stats['min_value'],
                "最大值": stats['max_value'],
                "平均值": stats['mean_value'],
                "标准差": stats['std_value']
            }
        )
        
        # 创建通道3：电压值数据
        ch3 = ChannelObject(
            group_name,
            "Voltage",
            voltage_array.astype(np.float32),
            properties={
                "数据类型": "float32",
                "描述": "转换后的电压值 (0-5V)",
                "样本数": len(voltage_array),
                "单位": "V",
                "参考电压": ADC_VOLTAGE_REF,
                "最小值": stats['min_voltage'],
                "最大值": stats['max_voltage'],
                "平均值": stats['mean_voltage'],
                "标准差": stats['std_voltage']
            }
        )
        
        # 写入TDMS文件
        with TdmsWriter(str(output_path)) as writer:
            writer.write_segment([root, group, ch1, ch2, ch3])
        
        print(f"[OK] TDMS文件已保存: {output_path}", file=output)
        return True
        
    except Exception as e:
        print(f"[错误] 保存TDMS文件失败: {e}", file=output)
        import traceback
        print(traceback.format_exc(), file=output)
        return False

# ============================================================================
# 主函数
# ============================================================================

def unpack_and_export(file_path, output=sys.stdout, generate_html=False):
    """
    主函数：解包ADC数据并导出
    
    Args:
        file_path: 输入文件路径（.txt或.tdms）
        output: 输出流（默认sys.stdout）
        generate_html: 是否生成HTML图表（默认False，只生成TDMS）
    """
    print("=" * 80, file=output)
    print("ADC数据解包导出工具", file=output)
    print("=" * 80, file=output)
    print(f"输入文件: {file_path}", file=output)
    print(file=output)
    
    # 检查文件是否存在
    file_path_obj = Path(file_path)
    if not file_path_obj.exists():
        print(f"[错误] 文件不存在: {file_path}", file=output)
        return
    
    # 读取原始数据
    file_extension = file_path_obj.suffix.lower()
    print(f"检测到文件类型: {file_extension}", file=output)
    print(file=output)
    
    if file_extension == '.txt':
        raw_data = read_txt_file(file_path, output)
    elif file_extension == '.tdms':
        raw_data = read_tdms_file(file_path, output)
    else:
        print(f"[错误] 不支持的文件类型: {file_extension}", file=output)
        print(f"支持的类型: .txt, .tdms", file=output)
        return
    
    if raw_data is None:
        print("[错误] 数据读取失败", file=output)
        return
    
    print(f"\n原始字节数: {len(raw_data):,}", file=output)
    
    # 解析帧结构并提取样本
    complete_frames, all_samples, voltage_array, stats = parse_and_extract_samples(raw_data, output)
    
    if len(all_samples) == 0:
        print("\n[错误] 未提取到任何样本数据", file=output)
        return
    
    # 创建输出目录
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = Path(DEFAULT_OUTPUT_DIR) / f"解包结果_{timestamp}"
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"\n输出目录: {output_dir}", file=output)
    
    # 生成文件名
    base_filename = file_path_obj.stem
    tdms_output = output_dir / f"{base_filename}_unpacked.tdms"
    
    # 保存TDMS文件（必选）
    success_tdms = save_as_tdms(raw_data, all_samples, voltage_array, tdms_output, stats, file_path_obj, output)
    
    # 保存HTML图表（可选）
    success_html = False
    html_output = None
    if generate_html:
        html_output = output_dir / f"{base_filename}_unpacked.html"
        success_html = save_as_html(all_samples, voltage_array, html_output, stats, output)
    
    # 总结
    print("\n" + "=" * 80, file=output)
    print("导出完成", file=output)
    print("=" * 80, file=output)
    
    if success_tdms:
        print(f"✓ TDMS文件: {tdms_output}", file=output)
    else:
        print(f"✗ TDMS文件生成失败", file=output)
    
    if generate_html:
        if success_html:
            print(f"✓ HTML图表: {html_output}", file=output)
        else:
            print(f"✗ HTML图表生成失败", file=output)
    
    print(f"\n所有文件保存在: {output_dir}", file=output)
    print("=" * 80, file=output)

# ============================================================================
# 主程序入口
# ============================================================================

if __name__ == "__main__":
    # 默认测试文件
    TEST_FILE = r"D:\senhaowang\project\33_hs_dual_da\TEST.txt"
    
    if len(sys.argv) > 1:
        # 从命令行参数获取文件路径
        input_file = sys.argv[1]
    else:
        input_file = TEST_FILE
    
    unpack_and_export(input_file)

