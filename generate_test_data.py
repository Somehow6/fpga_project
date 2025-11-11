#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试数据生成器
生成标准ADC帧格式的正弦波测试数据
"""

import numpy as np
from pathlib import Path
from datetime import datetime

# ============================================================================
# 配置参数
# ============================================================================
# 帧结构参数
FRAME_HEADER1 = 0xAA
FRAME_HEADER2 = 0x55
FRAME_TRAILER1 = 0x55
FRAME_TRAILER2 = 0xAA
SAMPLES_PER_FRAME = 128
BYTES_PER_FRAME = 2 + SAMPLES_PER_FRAME * 2 + 2  # 260字节

# 正弦波参数
ADC_BITS = 12
ADC_MAX = (1 << ADC_BITS) - 1  # 4095 (0xFFF)
ADC_MID = ADC_MAX // 2  # 2047 (中点)
AMPLITUDE = ADC_MID  # 振幅（满幅度）

# 输出目录
OUTPUT_DIR = r"D:\senhaowang\project\data_output"

# ============================================================================
# 数据生成函数
# ============================================================================

def generate_sine_wave(num_samples, frequency=1.0, phase=0.0, amplitude=AMPLITUDE, offset=ADC_MID):
    """
    生成正弦波ADC数据
    
    Args:
        num_samples: 样本数量
        frequency: 频率（周期数）
        phase: 相位偏移（弧度）
        amplitude: 振幅
        offset: 直流偏移
    
    Returns:
        numpy数组，包含12位ADC值（0-4095）
    """
    # 生成时间轴
    t = np.linspace(0, 2 * np.pi * frequency, num_samples)
    
    # 生成正弦波
    sine_wave = amplitude * np.sin(t + phase) + offset
    
    # 限制在ADC范围内并转换为整数
    sine_wave = np.clip(sine_wave, 0, ADC_MAX)
    sine_wave = sine_wave.astype(np.uint16)
    
    return sine_wave

def encode_sample_to_bytes(adc_value):
    """
    将12位ADC值编码为2字节
    
    格式：
        Byte1 = adc_data[11:4] (高8位)
        Byte2 = {4'b0000, adc_data[3:0]} (低4位，高4位补0)
    
    Args:
        adc_value: 12位ADC值 (0-4095)
    
    Returns:
        (byte1, byte2) 元组
    """
    # 确保是12位数据
    adc_value = adc_value & 0xFFF
    
    # 提取高8位和低4位
    high_byte = (adc_value >> 4) & 0xFF  # [11:4]
    low_byte = adc_value & 0x0F  # [3:0]，高4位为0
    
    return high_byte, low_byte

def create_frame(samples):
    """
    创建一帧数据（帧头 + 样本数据 + 帧尾）
    
    Args:
        samples: 样本数组（12位ADC值）
    
    Returns:
        字节列表
    """
    frame_bytes = []
    
    # 帧头
    frame_bytes.append(FRAME_HEADER1)
    frame_bytes.append(FRAME_HEADER2)
    
    # 样本数据（每个样本2字节）
    for sample in samples:
        high_byte, low_byte = encode_sample_to_bytes(sample)
        frame_bytes.append(high_byte)
        frame_bytes.append(low_byte)
    
    # 帧尾
    frame_bytes.append(FRAME_TRAILER1)
    frame_bytes.append(FRAME_TRAILER2)
    
    return frame_bytes

def generate_test_data(num_frames=10, frequency=2.0, save_txt=True):
    """
    生成测试数据文件
    
    Args:
        num_frames: 帧数
        frequency: 正弦波频率（每128个样本的周期数）
        save_txt: 是否保存为txt格式（16进制）
    
    Returns:
        输出文件路径
    """
    print("=" * 80)
    print("ADC测试数据生成器")
    print("=" * 80)
    print(f"帧数: {num_frames}")
    print(f"每帧样本数: {SAMPLES_PER_FRAME}")
    print(f"总样本数: {num_frames * SAMPLES_PER_FRAME:,}")
    print(f"正弦波频率: {frequency} 周期/帧")
    print(f"ADC位数: {ADC_BITS} bit")
    print(f"ADC范围: 0 - {ADC_MAX} (0x000 - 0x{ADC_MAX:03X})")
    print()
    
    # 生成完整的正弦波数据
    total_samples = num_frames * SAMPLES_PER_FRAME
    sine_data = generate_sine_wave(
        num_samples=total_samples,
        frequency=frequency,
        amplitude=AMPLITUDE,
        offset=ADC_MID
    )
    
    print(f"生成的正弦波数据:")
    print(f"  最小值: {np.min(sine_data)} (0x{np.min(sine_data):03X})")
    print(f"  最大值: {np.max(sine_data)} (0x{np.max(sine_data):03X})")
    print(f"  平均值: {np.mean(sine_data):.2f}")
    print(f"  标准差: {np.std(sine_data):.2f}")
    print()
    
    # 创建帧数据
    all_bytes = []
    for frame_idx in range(num_frames):
        # 提取当前帧的样本
        start_idx = frame_idx * SAMPLES_PER_FRAME
        end_idx = start_idx + SAMPLES_PER_FRAME
        frame_samples = sine_data[start_idx:end_idx]
        
        # 创建帧
        frame_bytes = create_frame(frame_samples)
        all_bytes.extend(frame_bytes)
    
    print(f"生成的帧数据:")
    print(f"  总字节数: {len(all_bytes):,}")
    print(f"  期望字节数: {num_frames * BYTES_PER_FRAME:,}")
    print(f"  每帧字节数: {BYTES_PER_FRAME}")
    
    # 验证字节数
    if len(all_bytes) == num_frames * BYTES_PER_FRAME:
        print(f"  [OK] 字节数正确")
    else:
        print(f"  [ERROR] 字节数错误！")
    print()
    
    # 创建输出目录
    output_dir = Path(OUTPUT_DIR)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # 生成文件名
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    base_filename = f"test_sine_{num_frames}frames_{timestamp}"
    
    # 保存为TXT文件（16进制格式）
    if save_txt:
        output_txt = output_dir / f"{base_filename}.txt"
        
        print(f"正在保存TXT文件...")
        with open(output_txt, 'w') as f:
            # 每16个字节一行，方便阅读
            for i in range(0, len(all_bytes), 16):
                hex_line = ' '.join(f'{b:02X}' for b in all_bytes[i:i+16])
                f.write(hex_line + '\n')
        
        print(f"[OK] TXT文件已保存: {output_txt}")
        print(f"  文件大小: {output_txt.stat().st_size:,} 字节")
        
        # 输出文件预览（前几帧）
        print(f"\n文件内容预览（前2帧）:")
        print("-" * 80)
        with open(output_txt, 'r') as f:
            lines = f.readlines()
            preview_lines = min(len(lines), 33)  # 2帧 = 520字节 = 33行
            for i, line in enumerate(lines[:preview_lines], 1):
                # 标注帧头和帧尾
                if i == 1:
                    print(f"[帧1头] {line.strip()}")
                elif i == 17:
                    print(f"[帧1尾+帧2头] {line.strip()}")
                elif i == 33:
                    print(f"[帧2尾] {line.strip()}")
                else:
                    print(f"        {line.strip()}")
        print("-" * 80)
        
        return output_txt
    
    return None

# ============================================================================
# 主程序入口
# ============================================================================

def main():
    """主函数"""
    import sys
    
    # 从命令行参数获取帧数
    if len(sys.argv) > 1:
        try:
            num_frames = int(sys.argv[1])
        except ValueError:
            print(f"[错误] 无效的帧数: {sys.argv[1]}")
            print(f"用法: python {sys.argv[0]} [帧数] [频率]")
            return
    else:
        num_frames = 10  # 默认10帧
    
    # 从命令行参数获取频率
    if len(sys.argv) > 2:
        try:
            frequency = float(sys.argv[2])
        except ValueError:
            print(f"[错误] 无效的频率: {sys.argv[2]}")
            print(f"用法: python {sys.argv[0]} [帧数] [频率]")
            return
    else:
        frequency = 2.0  # 默认2个周期/帧
    
    # 生成测试数据
    output_file = generate_test_data(num_frames=num_frames, frequency=frequency)
    
    print(f"\n" + "=" * 80)
    print(f"测试数据生成完成！")
    print(f"=" * 80)
    print(f"\n可以使用以下命令测试解包:")
    print(f"  python unpack_and_export.py {output_file}")
    print()

if __name__ == "__main__":
    main()

