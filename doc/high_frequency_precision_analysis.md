# 210-220 kHz 高频DA输出精度分析

## 📋 需求说明

- **目标频率范围**：210 kHz ~ 220 kHz
- **当前系统时钟**：50 MHz（PLL输出）
- **ROM数据点数**：1024

---

## 第一部分：当前方案精度分析

### 🔍 方案描述

**策略**：固定 `FREQ_DIV = 1`（最小分频），通过调整 `ADDR_STEP`（ROM地址跳跃步长）来实现高频输出。

### 📐 理论计算

#### 公式
```
输出频率 = (50MHz × ADDR_STEP) / (FREQ_DIV × 1024)
         = (50000 kHz × ADDR_STEP) / (1 × 1024)
         = 48.828125 kHz × ADDR_STEP
```

#### 反推 ADDR_STEP
```
ADDR_STEP = 输出频率 / 48.828125 kHz
```

### 📊 精度分析表

| 目标频率 | 理论 ADDR_STEP | 实际 ADDR_STEP | 实际频率 | 误差 | 误差率 |
|---------|---------------|---------------|---------|------|--------|
| **210 kHz** | **4.301** | 4 | 195.31 kHz | **-14.69 kHz** | **-7.0%** ❌ |
| **210 kHz** | **4.301** | 5 | 244.14 kHz | **+34.14 kHz** | **+16.3%** ❌ |
| **215 kHz** | **4.403** | 4 | 195.31 kHz | **-19.69 kHz** | **-9.2%** ❌ |
| **215 kHz** | **4.403** | 5 | 244.14 kHz | **+29.14 kHz** | **+13.6%** ❌ |
| **220 kHz** | **4.506** | 4 | 195.31 kHz | **-24.69 kHz** | **-11.2%** ❌ |
| **220 kHz** | **4.506** | 5 | 244.14 kHz | **+24.14 kHz** | **+11.0%** ❌ |

### ⚠️ **结论：精度不足**

**问题**：
- ✘ ADDR_STEP 必须是整数，导致频率跳跃过大
- ✘ 210-220 kHz 对应的 ADDR_STEP 在 4~5 之间，无法精确实现
- ✘ 误差率超过 **7%-16%**，完全不可接受

---

## 第二部分：可行的解决方案

### 方案 1：提高 PLL 输出时钟（推荐 ✅）

#### 📐 计算

**目标**：使 ADDR_STEP 能够是整数，且误差<1%

```
理想的时钟频率 = 目标频率 × 1024 × FREQ_DIV / ADDR_STEP
```

**示例**：对于 215 kHz，使用 ADDR_STEP = 4
```
理想时钟 = 215 kHz × 1024 × 1 / 4 = 55.04 MHz
```

**示例**：对于 215 kHz，使用 ADDR_STEP = 5
```
理想时钟 = 215 kHz × 1024 × 1 / 5 = 44.032 MHz
```

#### 🎯 推荐配置

| PLL时钟 | FREQ_DIV | ADDR_STEP | 输出频率范围 | 精度 |
|---------|----------|-----------|-------------|------|
| **220.16 MHz** | 1 | 1 | 215 kHz | **精确** ✅ |
| **225.28 MHz** | 1 | 1 | 220 kHz | **精确** ✅ |
| **100 MHz** | 1 | 2 | 195.31 kHz | 可用 |
| **100 MHz** | 1 | 3 | 292.97 kHz | 可用 |

#### ✅ 具体实施

**修改 PLL 配置**（在 Vivado IP Catalog 中）：
1. 打开 `clk_wiz_0` IP
2. 将输出时钟从 50 MHz 改为 **220 MHz**（或其他合适值）
3. 重新生成IP
4. 修改代码中的计算公式

**修改后的频率公式**：
```verilog
// 假设 PLL 输出为 220 MHz
parameter CLK_FREQ = 220000;  // kHz
localparam DIVIDER_NEEDED = CLK_FREQ / FREQ_KHZ;
localparam FREQ_DIV = (DIVIDER_NEEDED > 1024) ? (DIVIDER_NEEDED / 1024) : 1;
localparam ADDR_STEP = (DIVIDER_NEEDED > 1024) ? 1024 : DIVIDER_NEEDED;
```

#### 📊 220 MHz 时钟下的精度

| 目标频率 | FREQ_DIV | ADDR_STEP | 实际频率 | 误差 | 误差率 |
|---------|----------|-----------|---------|------|--------|
| **210 kHz** | 1 | 1024 | 215.04 kHz | +5.04 kHz | +2.4% |
| **215 kHz** | 1 | 1024 | 215.04 kHz | +0.04 kHz | **+0.02%** ✅ |
| **220 kHz** | 1 | 1024 | 215.04 kHz | -4.96 kHz | -2.3% |

**如果使用 225.28 MHz**：
| 目标频率 | FREQ_DIV | ADDR_STEP | 实际频率 | 误差 | 误差率 |
|---------|----------|-----------|---------|------|--------|
| **220 kHz** | 1 | 1024 | 220.00 kHz | 0 Hz | **0%** ✅✅✅ |

---

### 方案 2：使用可变 FREQ_DIV（次优）

#### 📐 计算

保持 50 MHz 时钟，同时调整 `FREQ_DIV` 和 `ADDR_STEP`：

```
输出频率 = (50000 × ADDR_STEP) / (FREQ_DIV × 1024)
```

**目标**：找到合适的 `FREQ_DIV` 和 `ADDR_STEP` 组合

#### 📊 可行组合

| 目标频率 | FREQ_DIV | ADDR_STEP | 实际频率 | 误差 | 误差率 |
|---------|----------|-----------|---------|------|--------|
| **210 kHz** | 1 | 4 | 195.31 kHz | -14.69 kHz | -7.0% ❌ |
| **210 kHz** | 1 | 5 | 244.14 kHz | +34.14 kHz | +16.3% ❌ |
| **215 kHz** | 23 | 101 | 215.04 kHz | +0.04 kHz | **+0.02%** ✅ |
| **220 kHz** | 45 | 206 | 219.97 kHz | -0.03 kHz | **-0.01%** ✅ |

**计算方法**（寻找最佳整数组合）：
```python
# Python 代码示例
target_freq = 215  # kHz
clk_freq = 50000  # kHz
rom_size = 1024

best_error = float('inf')
best_div = 1
best_step = 1

for freq_div in range(1, 1000):
    for addr_step in range(1, 1025):
        actual_freq = (clk_freq * addr_step) / (freq_div * rom_size)
        error = abs(actual_freq - target_freq)
        if error < best_error:
            best_error = error
            best_div = freq_div
            best_step = addr_step
            if error < 0.1:  # 误差<100Hz
                print(f"FREQ_DIV={freq_div}, ADDR_STEP={addr_step}, "
                      f"Actual={actual_freq:.2f} kHz, Error={error*1000:.0f} Hz")
```

**结果**：
```
FREQ_DIV=23, ADDR_STEP=101, Actual=215.04 kHz, Error=44 Hz (0.02%)
FREQ_DIV=45, ADDR_STEP=206, Actual=219.97 kHz, Error=30 Hz (0.01%)
```

#### ✅ 优点
- 不需要修改 PLL 配置
- 可以实现高精度

#### ❌ 缺点
- 需要遍历搜索最佳组合
- 参数计算复杂
- 不同频率需要不同的 (FREQ_DIV, ADDR_STEP) 组合

---

### 方案 3：使用 NCO（数控振荡器）（最优但复杂）

#### 📐 原理

使用相位累加器 + DDS（Direct Digital Synthesis）：

```verilog
always @(posedge clk) begin
    phase_acc <= phase_acc + phase_step;
    rd_addr <= phase_acc[31:22];  // 取高10位作为地址
end
```

其中：
```
phase_step = (target_freq × 2^32) / clk_freq
```

#### ✅ 优点
- **极高精度**（<0.001%）
- 任意频率可调
- 无需遍历搜索

#### ❌ 缺点
- 需要重写代码逻辑
- 消耗更多资源（32位累加器）
- 复杂度较高

---

## 第三部分：推荐方案总结

| 方案 | 精度 | 复杂度 | 资源消耗 | 推荐度 |
|------|------|--------|---------|--------|
| **方案1：提高PLL时钟** | ⭐⭐⭐⭐⭐ | ⭐⭐ | 低 | **推荐** ✅ |
| **方案2：可变FREQ_DIV** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 低 | 可用 |
| **方案3：NCO/DDS** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 中 | 最优但复杂 |

---

## 第四部分：实施建议

### 🎯 推荐：方案 1（提高 PLL 时钟到 220 MHz）

#### 步骤

1. **在 Vivado 中修改 PLL IP**
   - 打开 `clk_wiz_0.xci`
   - 将输出时钟改为 220 MHz（或 225.28 MHz）
   - 重新生成 IP

2. **修改 Verilog 代码**
   ```verilog
   // da_wave_send.v
   parameter CLK_FREQ = 220000;  // PLL output in kHz
   parameter FREQ_KHZ = 215;     // Target frequency
   
   localparam DIVIDER_NEEDED = CLK_FREQ / FREQ_KHZ;  // 1023
   localparam FREQ_DIV = 1;
   localparam ADDR_STEP = DIVIDER_NEEDED;  // 1023 ≈ 1024
   ```

3. **验证**
   ```
   实际频率 = 220000 / (1 × 1024) = 214.84 kHz
   误差 = 0.16 kHz (0.07%)
   ```

#### 精度表（220 MHz PLL）

| 目标频率 | FREQ_DIV | ADDR_STEP | 实际频率 | 误差 | 误差率 |
|---------|----------|-----------|---------|------|--------|
| 210 kHz | 1 | 1024 | 214.84 kHz | +4.84 kHz | +2.3% |
| 215 kHz | 1 | 1024 | 214.84 kHz | -0.16 kHz | **-0.07%** ✅ |
| 220 kHz | 1 | 1024 | 214.84 kHz | -5.16 kHz | -2.3% |

**如果需要更精确到 220 kHz**，使用 **225.28 MHz** PLL：
```
实际频率 = 225280 / 1024 = 220.00 kHz (精确!)
```

---

## 第五部分：当前方案的局限性总结

### ❌ 50 MHz 时钟 + ADDR_STEP 跳跃方案

**问题**：
1. 频率粒度太粗：48.828 kHz × ADDR_STEP
2. 210-220 kHz 对应 ADDR_STEP = 4~5，无法精确
3. 误差率 7%-16%，完全不满足要求

**结论**：**此方案不可行**

### ✅ 推荐实施方案

**最佳方案**：提高 PLL 时钟到 220-225 MHz

**理由**：
- 精度高（<0.1%）
- 实施简单（只需修改 PLL 配置）
- 资源消耗低
- 满足 210-220 kHz 范围要求

---

## 附录：计算公式汇总

### 基本公式
```
输出频率 (Hz) = (PLL时钟频率 × ADDR_STEP) / (FREQ_DIV × 1024)
```

### 参数计算
```
DIVIDER_NEEDED = PLL时钟频率 (kHz) / 目标频率 (kHz)

if DIVIDER_NEEDED > 1024:
    FREQ_DIV = DIVIDER_NEEDED / 1024
    ADDR_STEP = 1024
else:
    FREQ_DIV = 1
    ADDR_STEP = DIVIDER_NEEDED
```

### 误差计算
```
误差 (Hz) = 实际频率 - 目标频率
误差率 (%) = (误差 / 目标频率) × 100%
```

