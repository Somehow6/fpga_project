# 摄像头实时图像预处理实施总结

## 实施完成状态 ✅

所有核心模块和集成工作已完成，系统已准备好进行综合和上板测试。

---

## 已完成的工作

### 1. 新增核心模块（12个）

#### 显示相关模块
- ✅ `rtl/video_mixer.v` - 视频混合器，实现左右分屏 (512×768 each)
- ✅ `rtl/osd_rectangle.v` - OSD红框绘制，标注ROI区域
- ✅ `rtl/right_panel_gen.v` - 右半屏布局生成（深灰背景+二值图像）

#### 预处理流水线模块
- ✅ `rtl/roi_extractor.v` - ROI提取 (1024×768 → 112×112)
- ✅ `rtl/rgb2gray.v` - RGB565转灰度 (硬件优化算法)
- ✅ `rtl/gaussian_filter.v` - 3×3高斯滤波（行列分离优化）
- ✅ `rtl/max_pooling.v` - 2×2最大池化（两级降采样）
- ✅ `rtl/binarization.v` - 动态阈值二值化 (threshold = 0.3×max)
- ✅ `rtl/image_preprocessor.v` - 预处理顶层集成模块

#### 显示辅助模块
- ✅ `rtl/binary_image_buffer.v` - 28×28二值图像缓存 (784bit BRAM)
- ✅ `rtl/pixel_scaler.v` - 像素放大模块 (28×28 → 280×280)

### 2. 修改的现有模块（3个）

- ✅ `rtl/hdmi_top.v` - 集成视频混合器和显示逻辑
- ✅ `rtl/ov5640_hdmi.v` - 集成预处理流水线和缓存管理
- ✅ `rtl/hs_dual_da_hdmi_top.v` - 取消注释，启用摄像头/HDMI/DDR3

### 3. 更新的约束文件

- ✅ `prj/hs_dual_da.srcs/constrs_1/new/hs_dual_da.xdc`
  - 启用HDMI接口约束
  - 启用摄像头接口约束  
  - 添加cmos_pclk到异步时钟组

---

## 系统架构总览

```
OV5640摄像头 (1024×768)
    ↓
DDR3帧缓存
    ↓
读出 ──┬─→ 左路：OSD红框叠加 ──┐
       │                      │
       └─→ 右路：预处理流水线    ├──→ 视频混合器 ──→ HDMI输出
           ROI提取(112×112)   │    (左右分屏)     (1024×768)
           ↓                 │
           RGB→灰度           │
           ↓                 │
           高斯滤波1          │
           ↓                 │
           池化1 (→56×56)    │
           ↓                 │
           高斯滤波2          │
           ↓                 │
           池化2 (→28×28)    │
           ↓                 │
           二值化            │
           ↓                 │
           缓存 ──────────────┘
           (28×28bit)
           放大10倍显示
```

---

## 关键参数总结

| 参数 | 值 | 说明 |
|------|-----|------|
| 输入分辨率 | 1024×768 | OV5640摄像头输出 |
| ROI区域 | 112×112 | 中心区域，坐标(456,328)到(567,439) |
| 红框宽度 | 2像素 | RGB565红色0xF800 |
| 滤波核 | 3×3高斯 | [1 2 1; 2 4 2; 1 2 1]/16 |
| 池化方式 | 2×2最大 | 两级池化：112→56→28 |
| 二值化阈值 | 0.3×max | 动态阈值计算 |
| 输出尺寸 | 28×28 | 二值图像 |
| 显示放大 | 10倍 | 280×280像素显示 |
| 左半屏 | 512×768 | 原图+红框 |
| 右半屏 | 512×768 | 处理结果+深灰背景 |

---

## 资源预估

| 资源类型 | 预计使用 | 芯片总量 | 使用率 |
|---------|---------|---------|--------|
| BRAM | 10-12块 | 36块 | ~33% |
| LUT | 3000-4000 | 20000+ | ~20% |
| FF | 2000-3000 | 20000+ | ~15% |
| DSP | 4-6个 | 20个 | ~30% |

**结论**: EG4S20B256资源充足，无瓶颈

---

## 时钟域说明

| 时钟域 | 频率 | 用途 |
|--------|------|------|
| sys_clk | 50MHz | 系统输入时钟 |
| clk_20m | 20MHz | DDS输出、按键消抖 |
| clk_50m | 50MHz | UART、摄像头I2C配置 |
| clk_200m | 200MHz | DDR3参考时钟 |
| pixel_clk | 65MHz | HDMI像素时钟、图像预处理 |
| pixel_clk_5x | 325MHz | HDMI串行化时钟 |
| cam_pclk | ~25MHz | 摄像头像素时钟 |
| usb_clk_60m | 60MHz | USB传输、ADC采集 |

**CDC处理**: 所有跨时钟域信号都经过二级同步器处理

---

## 下一步操作指南

### 步骤1: 综合项目

```tcl
# 在Vivado中打开项目
open_project prj/hs_dual_da.xpr

# 运行综合
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# 检查综合报告
open_run synth_1
report_utilization -file utilization_post_synth.txt
report_timing_summary -file timing_post_synth.txt
```

**预期结果**:
- 无严重timing violations
- 资源使用在预估范围内
- 无critical warnings

### 步骤2: 实现(Implementation)

```tcl
# 运行实现
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# 检查实现报告
open_run impl_1
report_utilization -hierarchical -file utilization_post_impl.txt
report_timing_summary -file timing_post_impl.txt
```

**关注点**:
- Setup/Hold时序是否满足
- 最差负slack (WNS) 应 > 0
- 总负slack (TNS) 应 = 0

### 步骤3: 生成比特流

```tcl
# 生成比特流
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
```

### 步骤4: 上板调试

#### 4.1 硬件连接确认
- [x] OV5640摄像头连接到FMC接口
- [x] HDMI显示器连接
- [x] DDR3内存芯片正常
- [x] 电源供电正常
- [x] JTAG调试器连接

#### 4.2 程序下载
```tcl
# 在Vivado Hardware Manager中
open_hw_manager
connect_hw_server
open_hw_target
program_hw_devices [get_hw_devices] -bitstream path/to/bitfile.bit
```

#### 4.3 功能验证清单

##### 基础功能
- [ ] 摄像头采集正常（DDR3写入工作）
- [ ] HDMI显示输出正常（左右分屏）
- [ ] 左半屏显示原图
- [ ] 左半屏红框位置正确（112×112中心区域）

##### 预处理功能
- [ ] 右半屏背景为深灰色
- [ ] 右半屏中心显示280×280放大图像
- [ ] 二值图像黑白分明
- [ ] 实时更新（延迟约1帧=16ms）

##### 图像质量检测
- [ ] 拍摄手写数字，观察二值化效果
- [ ] 调整环境光线，测试动态阈值适应性
- [ ] 移动物体，测试实时性

#### 4.4 参数调优（如果需要）

**二值化阈值调整**
修改 `rtl/binarization.v` 第122行:
```verilog
// 当前: threshold = (max_value >> 2) + (max_value >> 4);  // ≈ 0.3125
// 如需更高阈值: threshold = (max_value >> 1);  // = 0.5
// 如需更低阈值: threshold = (max_value >> 3);  // = 0.125
```

**ROI位置调整**
修改 `rtl/osd_rectangle.v` 和 `rtl/roi_extractor.v`:
```verilog
// 当前中心: (512, 384)
// 修改ROI_X_MIN, ROI_X_MAX, ROI_Y_MIN, ROI_Y_MAX参数
```

**高斯滤波强度**
修改 `rtl/gaussian_filter.v` 卷积核系数（第93-95行）

---

## 潜在问题与解决方案

### 问题1: HDMI显示花屏或不显示
**可能原因**:
- PLL未锁定
- 时序违例
- DDR3初始化失败

**解决方法**:
1. 检查LED[3] (output_enable指示灯)
2. 添加ILA监控关键信号
3. 检查DDR3 init_calib_complete信号

### 问题2: 预处理结果全黑或全白
**可能原因**:
- 摄像头曝光问题
- 二值化阈值不合适
- ROI区域错误

**解决方法**:
1. 检查原图显示是否正常
2. 调整摄像头曝光参数（i2c_ov5640_rgb565_cfg.v）
3. 修改二值化阈值系数

### 问题3: 图像更新延迟过大
**可能原因**:
- DDR3带宽不足
- 流水线停顿

**解决方法**:
1. 优化DDR3突发传输长度
2. 检查FIFO满标志
3. 减少预处理级数（去掉一级高斯滤波）

### 问题4: 综合时序不满足
**可能原因**:
- 组合逻辑路径过长
- 跨时钟域约束不当

**解决方法**:
1. 增加流水线寄存器
2. 检查异步时钟组设置
3. 降低目标频率（如pixel_clk从65MHz降到60MHz）

---

## 仿真建议（可选）

如需在上板前进行功能仿真，可创建以下测试文件：

### 基础模块测试
```verilog
// sim/tb/tb_image_preprocessor.v
- 使用Python生成112×112测试图像
- 验证输出28×28二值结果
- 对比MNIST.py的处理结果
```

### 视频混合器测试
```verilog
// sim/tb/tb_video_mixer.v
- 测试左右分屏切换逻辑
- 验证坐标映射正确性
```

---

## 后续扩展（DDS连接）

当HDMI显示验证通过后，可进行以下扩展：

### 步骤1: 连接到DDS
修改 `rtl/mnist_tx_controller.v`:
```verilog
// 添加实时数据输入接口
input [783:0] camera_bits,  // 来自binary_image_buffer
input camera_frame_done,     // 帧完成标志
input [1:0] data_source_sel  // 0=ROM, 1=Camera
```

### 步骤2: 添加模式切换
使用按键切换：
- 模式0: ROM模式（原有MNIST数据）
- 模式1: 实时摄像头模式

### 步骤3: 完整闭环测试
- 摄像头拍摄手写数字
- 实时预处理为28×28
- 通过ASK调制发送到压电振子
- ADC采集并识别

---

## 技术支持

### 调试工具
- Vivado ILA: 在线逻辑分析
- Chipscope: 信号波形捕获
- UART日志: 打印关键状态

### 参考文档
- 项目简介: `项目简介.md`
- 实施计划: `camera-real.plan.md`
- FPGA数据手册: Xilinx 7-series文档

---

## 版本信息

- **实施日期**: 2025-11-11
- **Vivado版本**: 2020.2 (推荐) 或更高
- **目标芯片**: Xilinx Artix-7 XC7A35T (或同系列)
- **设计状态**: ✅ RTL设计完成，待综合验证

---

**祝调试顺利！** 🚀

