# -*- coding: utf-8 -*-
"""
MNIST 数据集二值化与bit序列转换
将MNIST图像转换为784位bit序列并保存到文本文件
"""

import struct
import numpy as np
import os
import matplotlib.pyplot as plt

# ==================== 配置参数 ====================
# 数据集选择：'train' 或 'test'
DATASET_TYPE = 'test'

# 起始索引（从第几个图片开始处理，0表示从第一个开始）
START_INDEX = 0

# 处理图片数量（从起始索引开始取多少张图片）
NUM_IMAGES = 200

# 数字筛选：从起始位置取NUM_IMAGES张图片后，只保留符合条件的数字
# 示例：FILTER_DIGITS = 1      -> 只保留数字1
#       FILTER_DIGITS = [1, 0]  -> 只保留数字1和0
#       FILTER_DIGITS = 10      -> 不筛选，保留所有数字
FILTER_DIGITS = 10

# 阈值比例（最大灰度值的30%）
THRESHOLD_RATIO = 0.3

# 数据文件路径
DATA_DIR = r"D:\senhaowang\harry_project\MNIST_process\MNIST\raw"
TRAIN_IMAGES_FILE = os.path.join(DATA_DIR, "train-images.idx3-ubyte")
TRAIN_LABELS_FILE = os.path.join(DATA_DIR, "train-labels.idx1-ubyte")
TEST_IMAGES_FILE = os.path.join(DATA_DIR, "t10k-images.idx3-ubyte")
TEST_LABELS_FILE = os.path.join(DATA_DIR, "t10k-labels.idx1-ubyte")

# 输出目录（修改为当前目录下的output文件夹）
OUTPUT_DIR = r"output"

# 可视化参数
ENABLE_VISUALIZATION = True  # 是否输出图片
VISUALIZE_IMAGE_INDEX = 0  # 可视化第几张图片（从0开始索引）
FIG_SIZE = (8, 6)
FONT_SIZE = 12

# ==================== 核心函数 ====================

def load_images(filename):
    """
    加载 MNIST 图像数据
    
    参数:
        filename: .idx3-ubyte 格式的图像文件路径
    
    返回:
        images: numpy 数组，形状为 (num_images, height, width)
    """
    with open(filename, 'rb') as f:
        # 读取文件头：magic number, 图像数量, 行数, 列数
        magic, num, rows, cols = struct.unpack(">IIII", f.read(16))
        
        # 读取图像数据
        data = np.frombuffer(f.read(), dtype=np.uint8)
        images = data.reshape(num, rows, cols)
        return images

def load_labels(filename):
    """
    加载 MNIST 标签数据
    
    参数:
        filename: .idx1-ubyte 格式的标签文件路径
    
    返回:
        labels: numpy 数组，形状为 (num_labels,)
    """
    with open(filename, 'rb') as f:
        # 读取文件头：magic number, 标签数量
        magic, num = struct.unpack(">II", f.read(8))
        
        # 读取标签数据
        labels = np.frombuffer(f.read(), dtype=np.uint8)
        return labels

def preprocess_image(image, threshold_ratio=0.3):
    """
    图像预处理：动态阈值二值化
    
    参数:
        image: 输入图像（2D numpy数组）
        threshold_ratio: 阈值比例（默认0.3，即最大灰度值的30%）
    
    返回:
        binary_image: 二值化后的图像（值为0或1）
    """
    # 计算动态阈值：T = threshold_ratio × max(I)
    threshold = threshold_ratio * np.max(image)
    
    # 二值化：大于阈值置1，否则置0
    binary_image = (image > threshold).astype(np.uint8)
    
    return binary_image

def image_to_bits(image):
    """
    将28x28图像展开为784位一维序列
    
    参数:
        image: 2D numpy数组 (28, 28)
    
    返回:
        bits: 1D numpy数组 (784,)
    """
    return image.flatten()

def filter_by_digits(images, labels, filter_digits, num_images=None, start_index=0):
    """
    根据指定的数字筛选数据集
    
    新逻辑：从起始索引开始取num_images张图片，然后只保留标签符合条件的图片
    
    参数:
        images: 图像数组
        labels: 标签数组
        filter_digits: 筛选的数字，可以是：
                      - 单个数字 (int): 只保留该数字，如 1
                      - 数字列表 (list): 保留列表中的数字，如 [1, 0]
                      - 大于9的数字: 不筛选，返回所有数据
        num_images: 从起始位置开始取多少张图片（None表示取到末尾）
        start_index: 起始索引位置（默认为0）
    
    返回:
        filtered_images: 筛选后的图像数组
        filtered_labels: 筛选后的标签数组
    """
    # 处理筛选条件
    if isinstance(filter_digits, int):
        if filter_digits > 9:
            # 不筛选
            print(f"FILTER_DIGITS = {filter_digits} (> 9)，不进行数字筛选")
            target_digits = None
        else:
            # 单个数字
            target_digits = [filter_digits]
    elif isinstance(filter_digits, list):
        # 数字列表
        target_digits = filter_digits
    else:
        raise ValueError(f"FILTER_DIGITS 必须是 int 或 list，当前类型: {type(filter_digits)}")
    
    # 步骤1：从起始索引截取指定数量的图片
    if num_images is None:
        end_index = len(images)
    else:
        end_index = min(start_index + num_images, len(images))
    
    print(f"从索引 {start_index} 到 {end_index-1}，共取 {end_index - start_index} 张图片")
    
    sliced_images = images[start_index:end_index]
    sliced_labels = labels[start_index:end_index]
    
    # 步骤2：筛选符合条件的数字
    if target_digits is None:
        # 不筛选，返回所有切片后的数据
        print(f"不进行数字筛选，保留全部 {len(sliced_labels)} 张")
        return sliced_images, sliced_labels
    
    print(f"数字筛选: 只保留数字 {target_digits}")
    
    # 筛选逻辑
    filtered_images = []
    filtered_labels = []
    digit_counts = {d: 0 for d in target_digits}
    
    for img, label in zip(sliced_images, sliced_labels):
        if label in target_digits:
            filtered_images.append(img)
            filtered_labels.append(label)
            digit_counts[label] += 1
    
    # 转换为 numpy 数组
    filtered_images = np.array(filtered_images)
    filtered_labels = np.array(filtered_labels)
    
    # 打印筛选统计
    print(f"筛选结果:")
    for digit in target_digits:
        print(f"  - 数字 {digit}: {digit_counts[digit]} 张")
    print(f"  - 总计: {len(filtered_labels)} 张")
    
    return filtered_images, filtered_labels

def bits_to_bytes(bits):
    """
    将784位bit序列压缩为98个8bit字节

    参数:
        bits: 784个bit的numpy数组

    返回:
        bytes_array: 98个8bit字节的列表
    """
    bytes_array = []
    for i in range(0, 784, 8):
        # 取8个bit，转换为一个字节
        byte_value = 0
        for j in range(8):
            if i + j < len(bits):
                byte_value |= (bits[i + j] << (7 - j))  # MSB在前
        bytes_array.append(byte_value)
    return bytes_array

def save_bits_and_labels(bits_array, labels_array, output_dir):
    """
    保存bit序列、标签和COE文件到指定目录

    参数:
        bits_array: shape (num_images, 784) - 所有图片的bit序列
        labels_array: shape (num_images,) - 对应的标签
        output_dir: 输出目录路径
    """
    # 输出文件路径
    bits_file = os.path.join(output_dir, "mnist_bits.txt")
    labels_file = os.path.join(output_dir, "mnist_labels.txt")
    coe_file = os.path.join(output_dir, "mnist_images.coe")

    # 保存 mnist_bits.txt：每行一个bit值
    print(f"正在保存bit序列到: {bits_file}")
    with open(bits_file, 'w') as f:
        for img_bits in bits_array:
            for bit in img_bits:
                f.write(f"{bit}\n")

    # 保存 mnist_labels.txt：每行一个标签
    print(f"正在保存标签到: {labels_file}")
    with open(labels_file, 'w') as f:
        for label in labels_array:
            f.write(f"{label}\n")

    # 生成并保存COE文件
    print(f"正在生成COE文件: {coe_file}")
    generate_coe_file(bits_array, labels_array, coe_file)

    print(f"[OK] 文件保存完成！")
    print(f"  - mnist_bits.txt: {len(bits_array) * 784:,} 行")
    print(f"  - mnist_labels.txt: {len(labels_array)} 行")
    print(f"  - mnist_images.coe: {len(bits_array) * 98:,} 个字节")

def generate_coe_file(bits_array, labels_array, coe_file_path):
    """
    生成COE文件，包含压缩后的图像数据

    数据格式：
    - 每张图片：98个8bit字节（压缩后的784位）
    - 每行16个字节的16进制表示
    - 格式：XX,XX,XX,...（每行16个字节）

    参数:
        bits_array: shape (num_images, 784) - bit序列
        labels_array: shape (num_images,) - 标签
        coe_file_path: COE文件输出路径
    """
    with open(coe_file_path, 'w') as f:
        # COE文件头
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")

        # 处理每张图片
        for i, (bits, label) in enumerate(zip(bits_array, labels_array)):
            # 将784位压缩为98个8bit字节
            bytes_data = bits_to_bytes(bits)

            # 写入98个字节，每16个字节一行
            for j in range(0, len(bytes_data), 16):
                chunk = bytes_data[j:j+16]
                line = ','.join([f"{byte:02X}" for byte in chunk])

                # 不是第一行且不是最后一行时，需要在行尾加逗号
                if j + 16 < len(bytes_data) or i < len(bits_array) - 1:
                    line += ','

                f.write(line + '\n')

        # COE文件结尾
        f.write(";\n")

    print(f"COE文件生成完成: {len(bits_array)} 张图片，每张98字节")

# ==================== 主程序 ====================

if __name__ == "__main__":
    print("="*60)
    print("MNIST 数据集 -> bit 序列转换")
    print("="*60)
    
    # 1. 根据配置加载数据集
    if DATASET_TYPE == 'train':
        print(f"\n【加载训练集】")
        images = load_images(TRAIN_IMAGES_FILE)
        labels = load_labels(TRAIN_LABELS_FILE)
    elif DATASET_TYPE == 'test':
        print(f"\n【加载测试集】")
        images = load_images(TEST_IMAGES_FILE)
        labels = load_labels(TEST_LABELS_FILE)
    else:
        raise ValueError(f"DATASET_TYPE 必须是 'train' 或 'test'，当前值: {DATASET_TYPE}")
    
    print(f"原始数据集大小: {images.shape[0]} 张图片")
    
    # 2. 根据 FILTER_DIGITS 筛选特定数字
    print(f"\n【数字筛选】")
    images, labels = filter_by_digits(images, labels, FILTER_DIGITS, NUM_IMAGES, START_INDEX)
    
    # 3. 预处理：二值化
    print(f"\n【二值化处理】")
    print(f"阈值公式: T = {THRESHOLD_RATIO} × max(I)")
    
    preprocessed_images = np.zeros_like(images, dtype=np.uint8)
    for i in range(len(images)):
        preprocessed_images[i] = preprocess_image(images[i], THRESHOLD_RATIO)
    
    print(f"二值化完成，像素值范围: [0, 1]")
    
    # 4. 展开为784位序列
    print(f"\n【展开为bit序列】")
    bits_array = np.zeros((len(preprocessed_images), 784), dtype=np.uint8)
    for i in range(len(preprocessed_images)):
        bits_array[i] = image_to_bits(preprocessed_images[i])
    
    print(f"bit序列数组形状: {bits_array.shape}")
    
    # 5. 保存到文件
    print(f"\n【保存到文件】")
    save_bits_and_labels(bits_array, labels, OUTPUT_DIR)
    
    # 6. 打印处理信息摘要
    print(f"\n" + "="*60)
    print("处理完成摘要")
    print("="*60)
    print(f"数据集类型: {DATASET_TYPE}")
    print(f"数字筛选: {FILTER_DIGITS}")
    print(f"处理图片数: {len(images)}")
    print(f"阈值比例: {THRESHOLD_RATIO}")
    print(f"输出目录: {OUTPUT_DIR}")
    print(f"总bit数: {len(images) * 784}")
    print("="*60)
