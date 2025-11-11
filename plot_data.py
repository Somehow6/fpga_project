#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
临时脚本：将TEST.txt中的十六进制数据转换为可交互的动态曲线图
支持功能：缩放、平移、悬停查看数值、范围选择等
"""

import plotly.graph_objects as go
from plotly.subplots import make_subplots
import numpy as np

# 读取数据文件
print("正在读取数据...")
with open('TEST.txt', 'r') as f:
    data_str = f.read().strip()

# 将十六进制字符串转换为整数列表
print("正在解析十六进制数据...")
hex_values = data_str.split()
decimal_values = [int(h, 16) for h in hex_values]

print(f"共读取 {len(decimal_values)} 个数据点")

# 输出统计信息
print("\n数据统计信息:")
print(f"  最小值: {min(decimal_values)} (0x{min(decimal_values):02X})")
print(f"  最大值: {max(decimal_values)} (0x{max(decimal_values):02X})")
print(f"  平均值: {np.mean(decimal_values):.2f}")
print(f"  标准差: {np.std(decimal_values):.2f}")

# 创建子图
fig = make_subplots(
    rows=2, cols=1,
    subplot_titles=('完整数据波形图 (可缩放、平移、框选)', '局部数据波形图 (前5000点)'),
    vertical_spacing=0.12,
    row_heights=[0.5, 0.5]
)

# 添加完整数据曲线
fig.add_trace(
    go.Scattergl(  # 使用Scattergl以提高大数据量性能
        x=list(range(len(decimal_values))),
        y=decimal_values,
        mode='lines',
        name='完整数据',
        line=dict(color='royalblue', width=1),
        hovertemplate='<b>采样点</b>: %{x}<br><b>数值</b>: %{y} (0x%{y:X})<extra></extra>'
    ),
    row=1, col=1
)

# 添加局部数据曲线（前5000个点）
sample_size = min(5000, len(decimal_values))
fig.add_trace(
    go.Scatter(
        x=list(range(sample_size)),
        y=decimal_values[:sample_size],
        mode='lines',
        name=f'前{sample_size}点',
        line=dict(color='coral', width=1.5),
        hovertemplate='<b>采样点</b>: %{x}<br><b>数值</b>: %{y} (0x%{y:X})<extra></extra>'
    ),
    row=2, col=1
)

# 更新布局
fig.update_xaxes(title_text="采样点索引", row=1, col=1, gridcolor='lightgray')
fig.update_xaxes(title_text="采样点索引", row=2, col=1, gridcolor='lightgray')
fig.update_yaxes(title_text="数值", row=1, col=1, gridcolor='lightgray')
fig.update_yaxes(title_text="数值", row=2, col=1, gridcolor='lightgray')

fig.update_layout(
    title_text=f"<b>数据波形交互式可视化</b><br><sub>共 {len(decimal_values)} 个采样点 | 值域: 0x{min(decimal_values):02X}-0x{max(decimal_values):02X}</sub>",
    title_x=0.5,
    height=900,
    showlegend=True,
    hovermode='x unified',
    template='plotly_white',
    # 添加范围滑块
    xaxis=dict(
        rangeslider=dict(visible=True, thickness=0.05),
        type='linear'
    )
)

# 保存为HTML文件
output_html = 'data_plot_interactive.html'
fig.write_html(output_html)
print(f"\n交互式图形已保存为: {output_html}")
print("请在浏览器中打开该文件进行交互操作")

# 在默认浏览器中打开
print("\n正在打开交互式图形...")
fig.show()

print("\n交互功能说明:")
print("  • 鼠标滚轮：缩放")
print("  • 鼠标拖动：平移")
print("  • 双击：重置视图")
print("  • 框选：选择区域放大")
print("  • 悬停：显示具体数值")
print("  • 下方滑块：快速导航到任意位置")

