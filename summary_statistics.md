# Summary Statistics

## Formulas Reference

| Statistic | Sample Formula | Population Parameter |
|-----------|----------------|---------------------|
| **Mean** | $\bar{x} = \frac{1}{n}\sum_{i=1}^{n} x_i$ | $\mu_x$ |
| **Variance** | $s_x^2 = \frac{1}{n-1}\sum_{i=1}^{n}(x_i - \bar{x})^2$ | $\sigma_x^2$ |
| **Standard Deviation** | $s_x = \sqrt{\frac{1}{n-1}\sum_{i=1}^{n}(x_i - \bar{x})^2}$ | $\sigma_x$ |
| **Covariance** | $s_{xy} = \frac{1}{n-1}\sum_{i=1}^{n}(x_i - \bar{x})(y_i - \bar{y})$ | $\sigma_{xy}$ |
| **Correlation** | $r = \frac{s_{xy}}{s_x \cdot s_y}$ | $\rho$ |

> **Note:** Sample formulas use $n-1$ (Bessel's correction) for unbiased estimation. Population formulas use $n$.

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

## Covariance Between Two Datasets

**Covariance** measures how two variables change together. If covariance is positive, when X increases, Y tends to increase as well (they move in the same direction). If covariance is negative, when X increases, Y tends to decrease (they move in opposite directions). If covariance is near zero, the variables have no linear relationship — knowing X tells you nothing about Y. However, covariance has a major limitation: its magnitude depends on the scale of the variables, making it hard to interpret (e.g., covariance of 1000 could be strong or weak depending on the data). This is why we normalize covariance by dividing by the product of standard deviations to get **correlation** (r), which always ranges from -1 to +1 and is scale-independent.
