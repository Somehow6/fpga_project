# PLL配置指南 - clk_wiz_unified

本文档说明如何在Vivado中配置统一的时钟管理PLL IP核。

## 概述

整合后的项目需要一个统一的PLL来生成所有必需的时钟信号，替代原来两个项目各自的PLL。

## 配置步骤

### 1. 打开Vivado项目

打开位于 `D:\senhaowang\project\33_hs_dual_da\prj\hs_dual_da.xpr` 的项目。

### 2. 创建新的Clock Wizard IP核

1. 在Vivado中点击 `IP Catalog`
2. 搜索 `Clocking Wizard`
3. 双击打开配置界面

### 3. 基本配置

在 **Clocking Options** 页面：

```
Component Name: clk_wiz_0
```

### 4. 输入时钟配置

在 **Clocking Features** 标签页：

#### Input Clock (Primary)
- **Port Name**: `clk_in1`
- **Input Frequency**: `50.000 MHz`
- **Input Jitter**: `0.010 ns` (默认值)

### 5. 输出时钟配置

在 **Output Clocks** 标签页，配置5个输出时钟：

#### clk_out1 - DDR3参考时钟
- **Port Name**: `clk_out1`
- **Output Freq (MHz)**: `200.000`
- **Phase (degrees)**: `0.000`
- **Duty Cycle (%)**: `50.0`
- **用途**: DDR3 MIG IP核参考时钟和系统时钟

#### clk_out2 - 摄像头配置和UART时钟
- **Port Name**: `clk_out2`
- **Output Freq (MHz)**: `50.000`
- **Phase (degrees)**: `0.000`
- **Duty Cycle (%)**: `50.0`
- **用途**: OV5640 I2C配置、UART RX

#### clk_out3 - DDS时钟
- **Port Name**: `clk_out3`
- **Output Freq (MHz)**: `20.000`
- **Phase (degrees)**: `0.000`
- **Duty Cycle (%)**: `50.0`
- **用途**: DA波形输出、MNIST控制器、UART TX

#### clk_out4 - HDMI像素时钟
- **Port Name**: `clk_out4`
- **Output Freq (MHz)**: `65.000` (1024x768 @ 60Hz标准)
- **Phase (degrees)**: `0.000`
- **Duty Cycle (%)**: `50.0`
- **用途**: HDMI视频驱动、DVI编码

> **注意**: 
> - 1024x768 (XGA) @ 60Hz = 65MHz（本项目配置）
> - 720p @ 60Hz = 74.25MHz
> - 1080p @ 60Hz = 148.5MHz
> - 640x480 @ 60Hz = 25.175MHz

#### clk_out5 - HDMI串行化时钟
- **Port Name**: `clk_out5`
- **Output Freq (MHz)**: `325.000` (65 × 5)
- **Phase (degrees)**: `0.000`
- **Duty Cycle (%)**: `50.0`
- **用途**: TMDS串行化（10:1 serializer）

> **注意**: 此时钟频率必须是pixel_clk的5倍

### 6. 其他选项

在 **Port Renaming** 标签页（可选）：
- 保持默认端口名称

在 **MMCM Settings** 标签页：
- 让Vivado自动优化PLL参数
- 或手动调整以获得更精确的频率

### 7. 完成生成

1. 点击 `OK` 完成配置
2. 在弹出的对话框中点击 `Generate`
3. 选择 `Global` synthesis 选项
4. 等待IP核生成完成

## PLL资源检查

配置完成后，检查以下内容：

### 频率精度
查看生成报告，确认实际输出频率与目标频率的误差：
- **可接受误差**: < 0.5%
- **理想误差**: < 0.1%

### 资源占用
检查MMCM/PLL资源使用：
- Artix-7系列芯片通常有4-6个MMCM
- 确保有足够的MMCM资源（本设计占用1个）

## 端口映射

生成后的IP核端口：

```verilog
clk_wiz_0 u_clk_wiz_0 (
    // 输入
    .clk_in1   (sys_clk),      // 50MHz系统时钟输入
    .reset     (~sys_rst_n),   // 复位（高电平有效）
    
    // 输出
    .clk_out1  (clk_200m),     // 200MHz (DDR3)
    .clk_out2  (clk_50m),      // 50MHz (UART/I2C)
    .clk_out3  (clk_20m),      // 20MHz (DDS)
    .clk_out4  (pixel_clk),    // 65MHz (1024x768 @ 60Hz)
    .clk_out5  (pixel_clk_5x), // 325MHz (5x pixel clock)
    .locked    (locked)        // PLL锁定信号
);
```

## 常见问题

### Q1: 无法生成325MHz时钟
**A**: Artix-7的MMCM输出频率范围通常是4.69~800 MHz。325MHz在范围内，如果遇到问题：
- 检查输入时钟频率是否为50MHz
- 调整VCO频率范围（建议600-1200 MHz）
- 确保输出频率是VCO频率的整数分频

### Q2: 频率误差过大
**A**: 尝试以下方法：
- 启用 "Optimize Clocking" 选项
- 手动调整CLKFBOUT_MULT和DIVCLK_DIVIDE参数
- 检查VCO频率是否在最佳范围（600-1200 MHz）

### Q3: 时序违规
**A**: 如果综合后出现时序违规：
- 检查约束文件中的时钟约束
- 添加适当的时钟组和异步时钟约束
- 考虑降低像素时钟频率（如640x480模式）

## 验证步骤

### 1. 综合检查
运行综合后，检查：
```
Reports > Clocking > Clock Utilization
```
确认5个时钟都已正确生成。

### 2. 时序检查
运行实现后，检查：
```
Reports > Timing > Timing Summary
```
确认WNS (Worst Negative Slack) > 0。

### 3. 功能验证
上板测试时，依次验证：
1. LED闪烁（说明20MHz时钟正常）
2. UART通信（说明20MHz和50MHz正常）
3. 数码管显示（说明20MHz正常）
4. 摄像头初始化（说明50MHz正常，观察cam_scl信号）
5. HDMI输出（说明pixel_clk和pixel_clk_5x正常）

## 替代方案（如果单个PLL无法满足）

如果单个MMCM无法生成所需的所有时钟频率，可以使用两个PLL：

### 方案A: 两个PLL级联
```
PLL1 (clk_wiz_1):
  - Input: 50MHz
  - Output1: 100MHz (给PLL2)
  - Output2: 20MHz (DDS)
  - Output3: 50MHz (UART/Camera)

PLL2 (clk_wiz_2):
  - Input: 100MHz (from PLL1)
  - Output1: 200MHz (DDR3)
  - Output2: 74.25MHz (HDMI pixel)
  - Output3: 371.25MHz (HDMI serial)
```

### 方案B: 两个独立PLL
```
PLL1 (for DDS):
  - Input: 50MHz
  - Output: 20MHz, 50MHz

PLL2 (for HDMI):
  - Input: 50MHz  
  - Output: 200MHz, 74.25MHz, 371.25MHz
```

## 完成后续步骤

PLL配置完成后，继续以下步骤：

1. ✅ 将所有RTL文件添加到项目
2. ✅ 设置 `hs_dual_da_hdmi_top.v` 为顶层模块
3. ✅ 添加/更新约束文件
4. ⚠️ 复制或重新生成MIG DDR3 IP核（参考HDMI项目配置）
5. ⚠️ 复制HDMI项目的FIFO IP核（rd_fifo和wr_fifo）
6. ✅ 运行综合和实现
7. ✅ 生成比特流文件
8. ✅ 上板测试

---

**创建时间**: 2024年  
**适用项目**: DDS + OV5640 + HDMI整合项目  
**参考文档**: Xilinx UG472 - Clocking Resources User Guide

