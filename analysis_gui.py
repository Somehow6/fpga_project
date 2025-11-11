#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
数据分析工具 - 图形化界面
统一的GUI界面，可以调用多个分析脚本
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, filedialog, messagebox
import threading
import sys
import io
import os
from pathlib import Path
import queue
import numpy as np


# ============================================================================
# 输出重定向类
# ============================================================================

class TextRedirector(io.TextIOBase):
    """将输出重定向到GUI文本组件的类"""
    
    def __init__(self, text_widget, output_queue):
        """
        初始化输出重定向
        
        Args:
            text_widget: tkinter Text组件
            output_queue: 线程安全的队列，用于在线程间传递输出
        """
        self.text_widget = text_widget
        self.output_queue = output_queue
        self.buffer = ""
    
    def write(self, string):
        """写入内容到GUI"""
        if string:
            # 将内容放入队列，由主线程处理
            self.output_queue.put(('text', string))
        return len(string)
    
    def flush(self):
        """刷新缓冲区"""
        pass


# ============================================================================
# 虚拟环境检测和激活
# ============================================================================

def detect_and_activate_venv():
    """
    检测并激活虚拟环境
    返回：(是否成功, 消息)
    """
    # 获取当前脚本所在目录
    script_dir = Path(__file__).parent.absolute()
    
    # 检查venv目录
    venv_dir = script_dir / 'venv'
    
    if not venv_dir.exists():
        return False, f"未找到虚拟环境目录: {venv_dir}"
    
    # Windows系统
    if sys.platform == 'win32':
        python_exe = venv_dir / 'Scripts' / 'python.exe'
        site_packages = venv_dir / 'Lib' / 'site-packages'
    # Linux/Mac系统
    else:
        python_exe = venv_dir / 'bin' / 'python'
        site_packages = venv_dir / 'lib' / f'python{sys.version_info.major}.{sys.version_info.minor}' / 'site-packages'
    
    if not python_exe.exists():
        return False, f"未找到Python解释器: {python_exe}"
    
    if not site_packages.exists():
        return False, f"未找到site-packages目录: {site_packages}"
    
    # 将虚拟环境的site-packages添加到sys.path
    site_packages_str = str(site_packages)
    if site_packages_str not in sys.path:
        sys.path.insert(0, site_packages_str)
    
    return True, f"成功激活虚拟环境: {venv_dir}"


# ============================================================================
# GUI主窗口类
# ============================================================================

class AnalysisGUI:
    """数据分析工具GUI主窗口"""
    
    def __init__(self, root):
        """初始化GUI"""
        self.root = root
        self.root.title("数据分析工具 v1.0")
        self.root.geometry("950x750")
        
        # 配置样式
        self.setup_styles()
        
        # 线程相关
        self.analysis_thread = None
        self.is_analyzing = False
        self.output_queue = queue.Queue()
        
        # 创建界面
        self.create_widgets()
        
        # 检测虚拟环境
        self.check_venv()
        
        # 启动输出队列处理
        self.process_output_queue()
    
    def setup_styles(self):
        """配置界面样式"""
        style = ttk.Style()
        
        # 配置按钮样式
        style.configure('Primary.TButton', font=('Arial', 10, 'bold'))
        style.configure('Secondary.TButton', font=('Arial', 9))
        
        # 配置标签样式
        style.configure('Title.TLabel', font=('Arial', 18, 'bold'), foreground='#2c3e50')
        style.configure('Section.TLabel', font=('Arial', 10, 'bold'), foreground='#34495e')
        style.configure('Info.TLabel', font=('Arial', 9), foreground='#7f8c8d')
    
    def create_widgets(self):
        """创建GUI组件"""
        # 主容器
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # 配置网格权重
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(5, weight=1)
        
        # ========== 标题区域 ==========
        title_frame = ttk.Frame(main_frame)
        title_frame.grid(row=0, column=0, columnspan=3, pady=(0, 15), sticky=(tk.W, tk.E))
        
        title_label = ttk.Label(title_frame, text="📊 数据分析工具", style='Title.TLabel')
        title_label.pack(side=tk.TOP)
        
        subtitle_label = ttk.Label(title_frame, text="ADC数据解析与可视化平台", style='Info.TLabel')
        subtitle_label.pack(side=tk.TOP, pady=(2, 0))
        
        # ========== 功能选择区域 ==========
        function_frame = ttk.LabelFrame(main_frame, text=" 功能选择 ", padding="10")
        function_frame.grid(row=1, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        function_frame.columnconfigure(1, weight=1)
        
        ttk.Label(function_frame, text="分析模式:", style='Section.TLabel').grid(row=0, column=0, sticky=tk.W, padx=(0, 10))
        self.script_var = tk.StringVar(value="Mode 2 TDMS分析")
        script_combo = ttk.Combobox(function_frame, textvariable=self.script_var, state='readonly', width=35, font=('Arial', 10))
        script_combo['values'] = ['Mode 2 TDMS分析', '数据可视化', 'ADC数据解包导出']
        script_combo.grid(row=0, column=1, sticky=(tk.W, tk.E), pady=2)
        script_combo.bind('<<ComboboxSelected>>', self.on_function_change)
        
        # ========== 文件选择区域 ==========
        file_frame = ttk.LabelFrame(main_frame, text=" 文件选择 ", padding="10")
        file_frame.grid(row=2, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        file_frame.columnconfigure(1, weight=1)
        
        ttk.Label(file_frame, text="数据文件:", style='Section.TLabel').grid(row=0, column=0, sticky=tk.W, padx=(0, 10))
        self.file_path_var = tk.StringVar()
        file_entry = ttk.Entry(file_frame, textvariable=self.file_path_var, font=('Consolas', 9))
        file_entry.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=(0, 10))
        
        browse_btn = ttk.Button(file_frame, text="📁 浏览", command=self.browse_file, style='Secondary.TButton', width=10)
        browse_btn.grid(row=0, column=2)
        
        # ========== 选项区域（仅对"ADC数据解包导出"功能可见）==========
        self.options_frame = ttk.LabelFrame(main_frame, text=" 导出选项 ", padding="10")
        self.options_frame.grid(row=3, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        self.options_frame.columnconfigure(0, weight=1)
        
        self.generate_html_var = tk.BooleanVar(value=False)
        self.generate_html_check = ttk.Checkbutton(
            self.options_frame, 
            text="✓ 同时生成HTML交互式图表（默认只生成TDMS文件）", 
            variable=self.generate_html_var,
            style='Secondary.TCheckbutton'
        )
        self.generate_html_check.grid(row=0, column=0, sticky=tk.W, pady=2)
        
        # 默认隐藏选项框
        self.options_frame.grid_remove()
        
        # ========== 操作按钮区域 ==========
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=4, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 15))
        
        # 左侧按钮
        left_buttons = ttk.Frame(button_frame)
        left_buttons.pack(side=tk.LEFT)
        
        self.execute_btn = ttk.Button(left_buttons, text="▶ 开始执行", command=self.execute_function, 
                                       style='Primary.TButton', width=15)
        self.execute_btn.pack(side=tk.LEFT, padx=(0, 10))
        
        clear_btn = ttk.Button(left_buttons, text="🗑 清空结果", command=self.clear_results, 
                              style='Secondary.TButton', width=12)
        clear_btn.pack(side=tk.LEFT, padx=(0, 5))
        
        # 右侧按钮
        right_buttons = ttk.Frame(button_frame)
        right_buttons.pack(side=tk.RIGHT)
        
        save_btn = ttk.Button(right_buttons, text="💾 保存日志", command=self.save_results, 
                             style='Secondary.TButton', width=12)
        save_btn.pack(side=tk.LEFT, padx=(0, 5))
        
        open_output_btn = ttk.Button(right_buttons, text="📂 输出目录", command=self.open_output_directory,
                                     style='Secondary.TButton', width=12)
        open_output_btn.pack(side=tk.LEFT)
        
        # ========== 结果显示区域 ==========
        result_frame = ttk.LabelFrame(main_frame, text=" 执行日志 ", padding="5")
        result_frame.grid(row=5, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        result_frame.columnconfigure(0, weight=1)
        result_frame.rowconfigure(0, weight=1)
        main_frame.rowconfigure(5, weight=1)
        
        # 带滚动条的文本框
        text_frame = ttk.Frame(result_frame)
        text_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        text_frame.columnconfigure(0, weight=1)
        text_frame.rowconfigure(0, weight=1)
        
        self.result_text = scrolledtext.ScrolledText(
            text_frame,
            wrap=tk.WORD,
            width=85,
            height=22,
            font=('Consolas', 9),
            bg='#f8f9fa',
            relief=tk.FLAT,
            borderwidth=1
        )
        self.result_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # ========== 状态栏 ==========
        status_frame = ttk.Frame(main_frame, relief=tk.SUNKEN, borderwidth=1)
        status_frame.grid(row=6, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 0))
        status_frame.columnconfigure(1, weight=1)
        
        ttk.Label(status_frame, text="状态:", font=('Arial', 9, 'bold')).pack(side=tk.LEFT, padx=(5, 5))
        self.status_var = tk.StringVar(value="就绪")
        ttk.Label(status_frame, textvariable=self.status_var, font=('Arial', 9), 
                 foreground='#27ae60').pack(side=tk.LEFT, padx=(0, 10))
    
    def check_venv(self):
        """检查虚拟环境"""
        success, message = detect_and_activate_venv()
        if success:
            self.append_text(f"[系统] {message}\n", 'success')
            self.status_var.set("就绪 - 虚拟环境已激活")
        else:
            self.append_text(f"[警告] {message}\n", 'warning')
            self.append_text("[警告] 某些功能可能无法正常使用\n", 'warning')
            self.status_var.set("就绪 - 虚拟环境未激活")
    
    def browse_file(self):
        """打开文件选择对话框"""
        filetypes = [
            ("支持的文件", "*.tdms;*.txt"),
            ("TDMS文件", "*.tdms"),
            ("文本文件", "*.txt"),
            ("所有文件", "*.*")
        ]
        filename = filedialog.askopenfilename(
            title="选择数据文件",
            filetypes=filetypes
        )
        if filename:
            self.file_path_var.set(filename)
    
    def append_text(self, text, tag=None):
        """向文本框追加内容"""
        self.result_text.insert(tk.END, text)
        if tag:
            # 可以在这里添加文本标签样式
            pass
        self.result_text.see(tk.END)  # 自动滚动到最新内容
    
    def clear_results(self):
        """清空结果显示"""
        self.result_text.delete(1.0, tk.END)
        self.status_var.set("就绪")
    
    def save_results(self):
        """保存结果到文件"""
        content = self.result_text.get(1.0, tk.END)
        if not content.strip():
            messagebox.showwarning("警告", "没有可保存的内容")
            return
        
        filename = filedialog.asksaveasfilename(
            title="保存分析结果",
            defaultextension=".txt",
            filetypes=[("文本文件", "*.txt"), ("所有文件", "*.*")]
        )
        if filename:
            try:
                with open(filename, 'w', encoding='utf-8') as f:
                    f.write(content)
                messagebox.showinfo("成功", f"结果已保存到: {filename}")
            except Exception as e:
                messagebox.showerror("错误", f"保存失败: {e}")
    
    def open_output_directory(self):
        """打开输出目录"""
        output_dir = r"D:\senhaowang\project\data_output"
        
        # 如果目录不存在，先创建
        output_path = Path(output_dir)
        if not output_path.exists():
            try:
                output_path.mkdir(parents=True, exist_ok=True)
                self.append_text(f"[信息] 已创建输出目录: {output_dir}\n")
            except Exception as e:
                messagebox.showerror("错误", f"无法创建输出目录: {e}")
                return
        
        # 打开文件管理器
        try:
            if sys.platform == 'win32':
                # Windows系统
                os.startfile(output_dir)
            elif sys.platform == 'darwin':
                # macOS系统
                import subprocess
                subprocess.run(['open', output_dir])
            else:
                # Linux系统
                import subprocess
                subprocess.run(['xdg-open', output_dir])
            
            self.append_text(f"[信息] 已打开输出目录: {output_dir}\n")
        except Exception as e:
            messagebox.showerror("错误", f"无法打开目录: {e}")
    
    def on_function_change(self, event=None):
        """当功能选择改变时的回调"""
        function_name = self.script_var.get()
        
        # 只在"ADC数据解包导出"时显示选项框
        if function_name == "ADC数据解包导出":
            self.options_frame.grid()
        else:
            self.options_frame.grid_remove()
    
    def execute_function(self):
        """根据选择的功能执行相应操作"""
        function_name = self.script_var.get()
        
        if function_name == "Mode 2 TDMS分析":
            self.execute_analysis()
        elif function_name == "数据可视化":
            self.plot_data()
        elif function_name == "ADC数据解包导出":
            self.unpack_and_export_data()
    
    def plot_data(self):
        """绘制数据图表"""
        if self.is_analyzing:
            messagebox.showwarning("警告", "任务正在进行中，请等待完成")
            return
        
        file_path = self.file_path_var.get()
        if not file_path:
            messagebox.showwarning("警告", "请先选择要可视化的文件")
            return
        
        if not os.path.exists(file_path):
            messagebox.showerror("错误", f"文件不存在: {file_path}")
            return
        
        # 清空之前的结果
        self.clear_results()
        
        # 禁用执行按钮
        self.execute_btn.config(state='disabled')
        self.is_analyzing = True
        self.status_var.set("执行中...")
        
        # 在新线程中生成图表
        threading.Thread(
            target=self._generate_plot,
            args=(file_path,),
            daemon=True
        ).start()
    
    def _generate_plot(self, file_path):
        """在线程中生成图表"""
        try:
            self.output_queue.put(('text', '\n正在生成数据可视化图表...\n'))
            
            # 检查文件类型
            file_ext = Path(file_path).suffix.lower()
            
            if file_ext == '.txt':
                # 读取TXT文件
                self.output_queue.put(('text', '正在读取TXT文件...\n'))
                with open(file_path, 'r', encoding='utf-8') as f:
                    data_str = f.read().strip()
                
                # 解析十六进制数据
                self.output_queue.put(('text', '正在解析十六进制数据...\n'))
                hex_values = data_str.split()
                decimal_values = [int(h, 16) for h in hex_values]
                
            elif file_ext == '.tdms':
                # 读取TDMS文件
                self.output_queue.put(('text', '正在读取TDMS文件...\n'))
                try:
                    from nptdms import TdmsFile
                    tdms_file = TdmsFile.read(file_path)
                    
                    # 查找数据通道
                    raw_data = None
                    for group in tdms_file.groups():
                        for channel in group.channels():
                            if 'Raw' in channel.name or 'raw' in channel.name.lower():
                                raw_data = channel[:]
                                break
                        if raw_data is not None:
                            break
                    
                    if raw_data is None:
                        # 使用第一个通道
                        for group in tdms_file.groups():
                            channels = list(group.channels())
                            if len(channels) > 0:
                                raw_data = channels[0][:]
                                break
                    
                    if raw_data is None:
                        self.output_queue.put(('error', '[错误] 未找到任何数据通道\n'))
                        return
                    
                    decimal_values = raw_data.tolist()
                except ImportError:
                    self.output_queue.put(('error', '[错误] 需要安装 nptdms 库来读取TDMS文件\n'))
                    return
            else:
                self.output_queue.put(('error', f'[错误] 不支持的文件类型: {file_ext}\n'))
                return
            
            self.output_queue.put(('text', f'共读取 {len(decimal_values):,} 个数据点\n'))
            
            # 输出统计信息
            self.output_queue.put(('text', '\n数据统计信息:\n'))
            self.output_queue.put(('text', f'  最小值: {min(decimal_values)} (0x{min(decimal_values):02X})\n'))
            self.output_queue.put(('text', f'  最大值: {max(decimal_values)} (0x{max(decimal_values):02X})\n'))
            self.output_queue.put(('text', f'  平均值: {np.mean(decimal_values):.2f}\n'))
            self.output_queue.put(('text', f'  标准差: {np.std(decimal_values):.2f}\n'))
            
            # 导入plotly
            try:
                import plotly.graph_objects as go
                from plotly.subplots import make_subplots
            except ImportError:
                self.output_queue.put(('error', '[错误] 需要安装 plotly 库来生成图表\n'))
                self.output_queue.put(('text', '提示: 请在虚拟环境中运行 pip install plotly\n'))
                return
            
            # 创建子图
            fig = make_subplots(
                rows=2, cols=1,
                subplot_titles=('完整数据波形图 (可缩放、平移、框选)', '局部数据波形图 (前5000点)'),
                vertical_spacing=0.12,
                row_heights=[0.5, 0.5]
            )
            
            # 添加完整数据曲线
            fig.add_trace(
                go.Scattergl(
                    x=list(range(len(decimal_values))),
                    y=decimal_values,
                    mode='lines',
                    name='完整数据',
                    line=dict(color='royalblue', width=1),
                    hovertemplate='<b>采样点</b>: %{x}<br><b>数值</b>: %{y} (0x%{y:X})<extra></extra>'
                ),
                row=1, col=1
            )
            
            # 添加局部数据曲线
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
                title_text=f"<b>数据波形交互式可视化</b><br><sub>共 {len(decimal_values):,} 个采样点 | 值域: 0x{min(decimal_values):02X}-0x{max(decimal_values):02X}</sub>",
                title_x=0.5,
                height=900,
                showlegend=True,
                hovermode='x unified',
                template='plotly_white',
                xaxis=dict(
                    rangeslider=dict(visible=True, thickness=0.05),
                    type='linear'
                )
            )
            
            # 保存为HTML文件到指定输出目录
            output_dir = Path(r"D:\senhaowang\project\data_output")
            output_dir.mkdir(parents=True, exist_ok=True)
            
            # 生成带时间戳的文件名
            from datetime import datetime
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = Path(file_path).stem
            output_html = output_dir / f'{filename}_plot_{timestamp}.html'
            fig.write_html(str(output_html))
            
            self.output_queue.put(('text', f'\n交互式图形已保存为: {output_html}\n'))
            self.output_queue.put(('text', '正在在浏览器中打开...\n'))
            
            # 在默认浏览器中打开
            fig.show()
            
            self.output_queue.put(('text', '\n交互功能说明:\n'))
            self.output_queue.put(('text', '  • 鼠标滚轮：缩放\n'))
            self.output_queue.put(('text', '  • 鼠标拖动：平移\n'))
            self.output_queue.put(('text', '  • 双击：重置视图\n'))
            self.output_queue.put(('text', '  • 框选：选择区域放大\n'))
            self.output_queue.put(('text', '  • 悬停：显示具体数值\n'))
            self.output_queue.put(('text', '  • 下方滑块：快速导航到任意位置\n'))
            self.output_queue.put(('text', '\n[✓] 图表生成完成！\n'))
            
            # 发送完成状态
            self.output_queue.put(('status', 'completed'))
            
        except Exception as e:
            import traceback
            error_msg = f'\n[错误] 生成图表时发生异常:\n{str(e)}\n\n详细信息:\n{traceback.format_exc()}'
            self.output_queue.put(('error', error_msg))
            self.output_queue.put(('status', 'error'))
    
    def unpack_and_export_data(self):
        """解包并导出ADC数据"""
        if self.is_analyzing:
            messagebox.showwarning("警告", "任务正在进行中，请等待完成")
            return
        
        file_path = self.file_path_var.get()
        if not file_path:
            messagebox.showwarning("警告", "请先选择要解包的文件")
            return
        
        if not os.path.exists(file_path):
            messagebox.showerror("错误", f"文件不存在: {file_path}")
            return
        
        # 清空之前的结果
        self.clear_results()
        
        # 禁用执行按钮
        self.execute_btn.config(state='disabled')
        self.is_analyzing = True
        self.status_var.set("执行中...")
        
        # 在新线程中执行解包导出
        threading.Thread(
            target=self._run_unpack_export,
            args=(file_path,),
            daemon=True
        ).start()
    
    def _run_unpack_export(self, file_path):
        """在线程中执行解包导出"""
        try:
            # 创建输出重定向器
            redirector = TextRedirector(self.result_text, self.output_queue)
            
            # 导入并执行解包导出函数
            from unpack_and_export import unpack_and_export
            
            # 获取是否生成HTML的选项
            generate_html = self.generate_html_var.get()
            
            # 执行解包导出，传入自定义输出流和HTML选项
            unpack_and_export(file_path, output=redirector, generate_html=generate_html)
            
            # 完成后显示成功消息
            self.output_queue.put(('status', 'completed_with_dialog'))
            
        except Exception as e:
            # 捕获异常并显示
            import traceback
            error_msg = f"\n[错误] 解包导出过程中发生异常:\n{str(e)}\n\n详细信息:\n{traceback.format_exc()}"
            self.output_queue.put(('error', error_msg))
            self.output_queue.put(('status', 'error'))
    
    def execute_analysis(self):
        """执行TDMS分析"""
        if self.is_analyzing:
            messagebox.showwarning("警告", "任务正在进行中，请等待完成")
            return
        
        file_path = self.file_path_var.get()
        if not file_path:
            messagebox.showwarning("警告", "请选择要分析的文件")
            return
        
        if not os.path.exists(file_path):
            messagebox.showerror("错误", f"文件不存在: {file_path}")
            return
        
        # 清空之前的结果
        self.clear_results()
        
        # 禁用执行按钮
        self.execute_btn.config(state='disabled')
        self.is_analyzing = True
        self.status_var.set("执行中...")
        
        # 在新线程中执行分析
        self.analysis_thread = threading.Thread(
            target=self._run_analysis,
            args=(file_path,),
            daemon=True
        )
        self.analysis_thread.start()
    
    def _run_analysis(self, file_path):
        """在线程中执行TDMS分析"""
        try:
            # 创建输出重定向器
            redirector = TextRedirector(self.result_text, self.output_queue)
            
            # 导入并执行分析函数
            from analyze_mode2_tdms import analyze_mode2_data
            
            # 执行分析，传入自定义输出流
            analyze_mode2_data(file_path, output=redirector)
            
            # 分析完成
            self.output_queue.put(('status', 'completed'))
            
        except Exception as e:
            # 捕获异常并显示
            import traceback
            error_msg = f"\n[错误] 分析过程中发生异常:\n{str(e)}\n\n详细信息:\n{traceback.format_exc()}"
            self.output_queue.put(('error', error_msg))
            self.output_queue.put(('status', 'error'))
    
    def process_output_queue(self):
        """处理输出队列（在主线程中）"""
        try:
            while True:
                msg_type, msg_content = self.output_queue.get_nowait()
                
                if msg_type == 'text':
                    self.append_text(msg_content)
                elif msg_type == 'status':
                    if msg_content == 'completed':
                        self.status_var.set("执行完成")
                        self.is_analyzing = False
                        self.execute_btn.config(state='normal')
                    elif msg_content == 'completed_with_dialog':
                        self.status_var.set("执行完成")
                        self.is_analyzing = False
                        self.execute_btn.config(state='normal')
                        # 显示完成对话框
                        messagebox.showinfo("完成", "ADC数据解包导出完成！\n\n文件已保存到:\nD:\\senhaowang\\project\\data_output\\解包结果_[时间戳]\\")
                    elif msg_content == 'error':
                        self.status_var.set("执行出错")
                        self.is_analyzing = False
                        self.execute_btn.config(state='normal')
                elif msg_type == 'error':
                    self.append_text(msg_content, 'error')
        except queue.Empty:
            pass
        
        # 定期检查队列
        self.root.after(100, self.process_output_queue)


# ============================================================================
# 主程序入口
# ============================================================================

def main():
    """主程序入口"""
    root = tk.Tk()
    app = AnalysisGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()

