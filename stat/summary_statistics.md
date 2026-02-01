# Summary Statistics

## Formulas Reference

| Statistic | Sample Formula | Population Parameter |
|-----------|----------------|---------------------|
| **Mean** | $\bar{x} = \frac{1}{n}\sum_{i=1}^{n} x_i$ | $\mu_x$ |
| **Variance** | $s_x^2 = \frac{1}{n-1}\sum_{i=1}^{n}(x_i - \bar{x})^2$ | $\sigma_x^2$ |
| **Standard Deviation** | $s_x = \sqrt{\frac{1}{n-1}\sum_{i=1}^{n}(x_i - \bar{x})^2}$ | $\sigma_x$ |
| **Coefficient of Variation** | $CV = \frac{s_x}{\bar{x}}$ | $\frac{\sigma_x}{\mu_x}$ |
| **Covariance** | $s_{xy} = \frac{1}{n-1}\sum_{i=1}^{n}(x_i - \bar{x})(y_i - \bar{y})$ | $\sigma_{xy}$ |
| **Correlation** | $r = \frac{s_{xy}}{s_x \cdot s_y}$ | $\rho$ |
| **Median** | Middle value when sorted | $\tilde{\mu}$ or $M$ |
| **Mode** | Most frequent value | $Mo$ |
| **Skewness** | $\frac{1}{n}\sum\left(\frac{x_i - \bar{x}}{s}\right)^3$ | $\gamma_1$ |
| **Kurtosis** | $\frac{1}{n}\sum\left(\frac{x_i - \bar{x}}{s}\right)^4 - 3$ | $\gamma_2$ |

> **Note:** Sample formulas use $n-1$ (Bessel's correction) for unbiased estimation. Population formulas use $n$.

---

## Median

The **median** is the middle value when data is sorted. It divides the dataset into two equal halves.

$$\text{Median} = \begin{cases} x_{(n+1)/2} & \text{if } n \text{ is odd} \\ \frac{x_{n/2} + x_{n/2+1}}{2} & \text{if } n \text{ is even} \end{cases}$$

### Why Use Median?

- **Robust to outliers**: Unlike the mean, extreme values don't pull the median
- **Better for skewed data**: For log-normal, Pareto, or income data, median represents the "typical" value
- **Always exists**: Works for any ordinal data

```python
import numpy as np

data = [1, 2, 3, 4, 100]  # Outlier at 100

mean = np.mean(data)      # 22.0 (pulled by outlier)
median = np.median(data)  # 3.0 (robust)
```

---

## Mode

The **mode** is the most frequently occurring value in a dataset.

- A distribution can be **unimodal** (one peak), **bimodal** (two peaks), or **multimodal**
- For continuous data, mode is the peak of the probability density function

```python
from scipy import stats

data = [1, 2, 2, 3, 3, 3, 4, 5]
mode_result = stats.mode(data, keepdims=True)
print(f"Mode: {mode_result.mode[0]}, Count: {mode_result.count[0]}")
# Mode: 3, Count: 3
```

---

## Skewness

**Skewness** measures the asymmetry of a distribution around its mean.

$$\text{Skewness} = \frac{1}{n}\sum_{i=1}^{n}\left(\frac{x_i - \bar{x}}{s}\right)^3$$

| Value | Interpretation |
|-------|----------------|
| = 0 | Symmetric (like Normal) |
| > 0 | Right-skewed (long tail to the right) |
| < 0 | Left-skewed (long tail to the left) |

```
Right-skewed (positive):        Left-skewed (negative):

    ▄█▄                                      ▄█▄
   █████▄                                 ▄█████
  ████████▄▄▄                       ▄▄▄████████
━━━━━━━━━━━━━━━━━━━              ━━━━━━━━━━━━━━━━━━━
     ↑                                         ↑
   median                                   median
        ←── long tail                long tail ──→
```

```python
from scipy.stats import skew

data = [1, 2, 3, 4, 5, 6, 7, 8, 100]  # Right-skewed
print(f"Skewness: {skew(data):.2f}")  # Positive value
```

---

## Kurtosis

**Kurtosis** measures the "tailedness" of a distribution — how much probability mass is in the tails vs the center.

$$\text{Excess Kurtosis} = \frac{1}{n}\sum_{i=1}^{n}\left(\frac{x_i - \bar{x}}{s}\right)^4 - 3$$

The "-3" makes it relative to the Normal distribution (which has kurtosis = 3).

| Excess Kurtosis | Name | Interpretation |
|-----------------|------|----------------|
| = 0 | Mesokurtic | Normal-like tails |
| > 0 | Leptokurtic | Heavy tails, more outliers |
| < 0 | Platykurtic | Light tails, fewer outliers |

### Visual: Kurtosis Comparison

```
Platykurtic (< 0):     Mesokurtic (= 0):      Leptokurtic (> 0):
Light tails            Normal                  Heavy tails

    ▄▄▄▄▄▄▄                 ▄█▄                    ▄█▄
  ▄██████████▄            ▄█████▄                ██████
 ████████████████       ▄█████████▄           ▄█████████▄
━━━━━━━━━━━━━━━━━━━   ━━━━━━━━━━━━━━━━━━   ━━━▄▄━━━━━━━━▄▄━━━
                                              ↑         ↑
                                           fat tails (outliers)
```

### Why Kurtosis Matters

- **High kurtosis** = expect more extreme values (P99 >> P50)
- **Critical for capacity planning**: A few "elephant" requests can overwhelm resources
- **Risk assessment**: High kurtosis means higher probability of rare extreme events

```python
from scipy.stats import kurtosis
import numpy as np

# Normal distribution
normal_data = np.random.normal(0, 1, 10000)
print(f"Normal kurtosis: {kurtosis(normal_data):.2f}")  # ≈ 0

# Heavy-tailed (e.g., log-normal)
lognormal_data = np.random.lognormal(0, 1, 10000)
print(f"Log-normal kurtosis: {kurtosis(lognormal_data):.2f}")  # >> 0

# Rule of thumb for capacity planning
k = kurtosis(lognormal_data)
if k > 3:
    print("⚠️ Heavy tails detected - plan for extreme outliers")
elif k > 1:
    print("Moderate tails - monitor P99")
else:
    print("Light tails - standard planning OK")
```

### Quick Reference

| Distribution | Excess Kurtosis | Tail Behavior |
|--------------|-----------------|---------------|
| Uniform | -1.2 | No tails (bounded) |
| Normal | 0 | Baseline |
| Exponential | 6 | Moderate heavy tail |
| Log-normal | Varies (often > 10) | Heavy tail |
| Pareto | Very high | Extremely heavy |

---

## Mean vs Median vs Mode

For symmetric distributions (like Normal), all three are equal. For skewed distributions, they differ:

### Right-Skewed (Positive Skew)

```
Mode < Median < Mean

        Mode
         ↓
         ▄█▄
        █████▄
       ████████▄▄▄▄▄
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
             ↑        ↑
           Median   Mean
           
Examples: Income, file sizes, latencies, execution times
```

### Left-Skewed (Negative Skew)

```
Mean < Median < Mode

                              Mode
                               ↓
                             ▄█▄
                          ▄█████
                 ▄▄▄▄▄████████
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
         ↑        ↑
       Mean    Median

Examples: Age at retirement, test scores with ceiling
```

### Which to Use?

| Scenario | Best Measure | Why |
|----------|--------------|-----|
| Symmetric data | Mean | All three are equal, mean is most efficient |
| Skewed data | Median | Robust to outliers, represents "typical" |
| Categorical data | Mode | Only option for non-numeric |
| Capacity planning | Percentiles (P90, P99) | Need to handle tail cases |
| Log-normal data | Median = $e^{\mu}$ | Mean is inflated by heavy tail |

### Log-Normal Example

For log-normal distribution with parameters μ and σ:

| Statistic | Formula | Relationship |
|-----------|---------|--------------|
| Mode | $e^{\mu - \sigma^2}$ | Smallest |
| Median | $e^{\mu}$ | Middle |
| Mean | $e^{\mu + \sigma^2/2}$ | Largest |

```python
import numpy as np

# Log-normal parameters
mu, sigma = 3.0, 1.0

mode = np.exp(mu - sigma**2)        # 7.4
median = np.exp(mu)                  # 20.1
mean = np.exp(mu + sigma**2 / 2)     # 33.1

print(f"Mode: {mode:.1f} < Median: {median:.1f} < Mean: {mean:.1f}")
```

---

## NumPy Functions

```python
import numpy as np

x = np.array([1, 2, 3, 4, 5])
y = np.array([2, 4, 5, 4, 5])

# Mean
mean_x = np.mean(x)                    # μ_x

# Variance
var_x = np.var(x, ddof=1)              # Sample variance (ddof=1 for n-1)
var_x_pop = np.var(x, ddof=0)          # Population variance (ddof=0 for n)

# Standard Deviation
std_x = np.std(x, ddof=1)              # Sample std dev
std_x_pop = np.std(x, ddof=0)          # Population std dev

# Covariance (returns 2x2 matrix)
cov_matrix = np.cov(x, y)              # [[var_x, cov_xy], [cov_xy, var_y]]
cov_xy = cov_matrix[0, 1]              # Extract covariance

# Correlation (returns 2x2 matrix)
corr_matrix = np.corrcoef(x, y)        # [[1, r], [r, 1]]
corr_xy = corr_matrix[0, 1]            # Extract correlation coefficient

# Median and Mode
median_x = np.median(x)                # Median

from scipy import stats
mode_result = stats.mode(x, keepdims=True)
mode_x = mode_result.mode[0]           # Mode

# Skewness and Kurtosis
from scipy.stats import skew, kurtosis
skewness_x = skew(x)                   # Skewness (0 = symmetric)
kurtosis_x = kurtosis(x)               # Excess kurtosis (0 = normal-like)
```

---

## Mean and Standard Deviation Relationship

The **mean** tells you the center of your data — where values tend to cluster. The **standard deviation** tells you how spread out the data is around that center. Together, they define the shape of your distribution: a small standard deviation means data points are tightly packed near the mean, while a large standard deviation means values are widely scattered. For normally distributed data, approximately 68% of values fall within 1 standard deviation of the mean, 95% within 2, and 99.7% within 3 — this is the famous "68-95-99.7 rule" (empirical rule). When comparing datasets, two groups can have the same mean but very different standard deviations, which tells a completely different story about variability and risk.

### 68-95-99.7 Rule (Empirical Rule)

```
                         99.7% (±3σ)
            ┌─────────────────────────────────────┐
            │         95% (±2σ)                   │
            │    ┌───────────────────────┐        │
            │    │     68% (±1σ)         │        │
            │    │   ┌───────────┐       │        │
            │    │   │           │       │        │
                     ▄▄▄████▄▄▄
                  ▄██████████████▄
               ▄██████████████████▄
            ▄████████████████████████▄
         ▄████████████████████████████████▄
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
       -3σ    -2σ    -1σ     μ     +1σ    +2σ    +3σ
```

### Same Mean, Different Standard Deviations

```
Small σ (tight):              Large σ (spread):
        ▄███▄                        ▄▄▄▄▄▄▄▄▄▄▄
       ██████▄                    ▄██████████████▄
    ━━━━━┿━━━━━                ━━━━━━━━━┿━━━━━━━━━
         μ                             μ
    
    Same mean (μ), but very different spreads!
```

---

## Coefficient of Variation (CV)

The **coefficient of variation** is the ratio of standard deviation to the mean, expressing variability as a proportion of the average:

$$CV = \frac{\sigma}{\mu} \quad \text{or as percentage:} \quad CV\% = \frac{\sigma}{\mu} \times 100$$

### Why Use CV?

Standard deviation alone doesn't tell you if variability is "high" or "low" — it depends on the scale. CV normalizes this, making it **unit-free** and comparable across different datasets.

### Example: Comparing Two Processes

| Process | Mean (μ) | Std Dev (σ) | CV |
|---------|----------|-------------|-----|
| Job arrivals (per hour) | 100 | 30 | 0.30 |
| Job duration (seconds) | 500 | 30 | 0.06 |

Both have σ = 30, but:
- Arrivals: CV = 0.30 → **high variability** (30% of mean)
- Duration: CV = 0.06 → **low variability** (6% of mean)

### Visual: Same σ, Different CV

```
High CV (small mean):           Low CV (large mean):

σ = 30, μ = 100                 σ = 30, μ = 500
CV = 0.30                       CV = 0.06

    ▄███▄                              ▄███▄
   ███████                            ███████
━━━━━┿━━━━━━━━━━━━━━━━━━━    ━━━━━━━━━━━━━━━━━━━┿━━━━
   100                                        500

  ←─ 30 ─→                              ←─ 30 ─→
  (30% of μ)                            (6% of μ)
```
---

## Covariance Between Two Datasets

**Covariance** measures how two variables change together. If covariance is positive, when X increases, Y tends to increase as well (they move in the same direction). If covariance is negative, when X increases, Y tends to decrease (they move in opposite directions). If covariance is near zero, the variables have no linear relationship — knowing X tells you nothing about Y. However, covariance has a major limitation: its magnitude depends on the scale of the variables, making it hard to interpret (e.g., covariance of 1000 could be strong or weak depending on the data). This is why we normalize covariance by dividing by the product of standard deviations to get **correlation** (r), which always ranges from -1 to +1 and is scale-independent.
