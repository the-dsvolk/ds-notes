# Log-Normal Distribution

Model for positive-valued data where the logarithm follows a normal distribution. Common in execution sizes, file sizes, latencies, and computing workloads.

## The Formula

The probability density function:

$$f(x) = \frac{1}{x \sigma \sqrt{2\pi}} \exp\left(-\frac{(\ln x - \mu)^2}{2\sigma^2}\right), \quad x > 0$$

Where:
- $\mu$: Mean of the underlying normal distribution (of $\ln X$)
- $\sigma$: Standard deviation of the underlying normal distribution (of $\ln X$)

## Key Properties

| Property | Formula |
|----------|---------|
| Mean | $e^{\mu + \sigma^2/2}$ |
| Median | $e^{\mu}$ |
| Mode | $e^{\mu - \sigma^2}$ |
| Variance | $(e^{\sigma^2} - 1) e^{2\mu + \sigma^2}$ |
| Skewness | $(e^{\sigma^2} + 2)\sqrt{e^{\sigma^2} - 1}$ |

**Critical insight**: Mean > Median > Mode. The mean is pulled up by the heavy right tail.

---

## Why Log-Normal Appears in Computing

Log-normal distributions arise from **multiplicative processes**:

- **Execution sizes**: Jobs spawn sub-jobs, each multiplying work
- **Latencies**: Multiple independent factors multiply together (network × processing × I/O)
- **File sizes**: Growth proportional to current size
- **Resource usage**: Cascading dependencies multiply requirements

**Rule**: If many independent positive factors *multiply* together, the result is log-normal. (Compare to normal: factors that *add* together.)

---

## First Question: Is My Data Log-Normal?

### Method 1: Log-Transform and Test Normality

```python
import numpy as np
from scipy.stats import shapiro, normaltest

def test_lognormal(data, alpha=0.05):
    """
    Test if data follows log-normal distribution.
    H0: Data is log-normally distributed.
    """
    # Remove zeros/negatives (log-normal is for positive values)
    data = np.array(data)
    data = data[data > 0]
    
    # Log-transform
    log_data = np.log(data)
    
    # Shapiro-Wilk test for normality of log-transformed data
    if len(log_data) <= 5000:
        stat, p_value = shapiro(log_data)
        test_name = "Shapiro-Wilk"
    else:
        stat, p_value = normaltest(log_data)
        test_name = "D'Agostino-Pearson"
    
    return {
        'test': test_name,
        'statistic': stat,
        'p_value': p_value,
        'is_lognormal': p_value > alpha
    }

# Example
sizes = [10, 25, 50, 100, 250, 500, 1000, 2500]
result = test_lognormal(sizes)
print(f"Test: {result['test']}, p-value: {result['p_value']:.4f}")
print(f"Is log-normal: {result['is_lognormal']}")
```

### Method 2: Q-Q Plot (Visual)

```python
import numpy as np
from scipy import stats
import plotly.graph_objects as go

def qq_plot_lognormal(data):
    """Q-Q plot comparing log-transformed data to normal distribution."""
    data = np.array(data)
    data = data[data > 0]
    log_data = np.log(data)
    
    # Theoretical quantiles
    (osm, osr), (slope, intercept, r) = stats.probplot(log_data, dist="norm")
    
    fig = go.Figure()
    fig.add_trace(go.Scatter(x=osm, y=osr, mode='markers', name='Data'))
    fig.add_trace(go.Scatter(
        x=osm, y=slope * osm + intercept, 
        mode='lines', name=f'Fit (R²={r**2:.3f})'
    ))
    fig.update_layout(
        title='Q-Q Plot: Log-Transformed Data vs Normal',
        xaxis_title='Theoretical Quantiles',
        yaxis_title='Sample Quantiles (log scale)'
    )
    fig.show()
    
    return {'r_squared': r**2, 'is_lognormal': r**2 > 0.95}
```

### Method 3: Log-Log Plot Check

```python
import numpy as np
import plotly.express as px

def loglog_distribution_check(data, num_bins=30):
    """
    Log-log plot of size vs frequency.
    - Straight line → Power-law
    - Hump shape → Log-normal
    - Steep curve down → Exponential/Poisson
    """
    data = np.array(data)
    data = data[data > 0]
    
    # Logarithmic bins
    log_bins = np.logspace(np.log10(data.min()), np.log10(data.max()), num_bins)
    hist, bin_edges = np.histogram(data, bins=log_bins)
    bin_centers = np.sqrt(bin_edges[:-1] * bin_edges[1:])
    
    # Filter zeros
    mask = hist > 0
    
    fig = px.scatter(
        x=bin_centers[mask], y=hist[mask],
        log_x=True, log_y=True,
        title='Log-Log Plot: Distribution Shape Check',
        labels={'x': 'Size (log scale)', 'y': 'Frequency (log scale)'}
    )
    fig.show()
    
    print("Interpretation:")
    print("- Hump shape (rise then fall) → Log-normal")
    print("- Straight downward line → Power-law")
    print("- Curved rapidly down → Poisson/Exponential")
```

### Quick Decision Table

| Pattern on Log-Log Plot | Distribution | Characteristic |
|------------------------|--------------|----------------|
| Hump (rise → peak → fall) | **Log-normal** | Multiplicative process |
| Straight downward line | Power-law | Scale-free, "rich get richer" |
| Steep exponential decay | Poisson/Exponential | Random events at constant rate |

---

## Fitting Log-Normal Parameters

```python
import numpy as np
from scipy.stats import lognorm

def fit_lognormal(data):
    """
    Fit log-normal distribution to data.
    Returns μ, σ of the underlying normal distribution.
    """
    data = np.array(data)
    data = data[data > 0]
    
    # Method 1: Direct from log-transformed data
    log_data = np.log(data)
    mu = np.mean(log_data)
    sigma = np.std(log_data, ddof=1)
    
    # Method 2: scipy.stats (alternative parameterization)
    # Note: scipy uses (s, loc, scale) where s=sigma, scale=exp(mu)
    shape, loc, scale = lognorm.fit(data, floc=0)
    
    # Convert scipy params to standard (μ, σ)
    mu_scipy = np.log(scale)
    sigma_scipy = shape
    
    return {
        'mu': mu,
        'sigma': sigma,
        'mean': np.exp(mu + sigma**2 / 2),
        'median': np.exp(mu),
        'mode': np.exp(mu - sigma**2),
        'scipy_params': (shape, loc, scale)
    }

# Example
sizes = [10, 25, 50, 100, 250, 500, 1000, 2500, 5000]
params = fit_lognormal(sizes)
print(f"μ = {params['mu']:.2f}, σ = {params['sigma']:.2f}")
print(f"Mean = {params['mean']:.0f}, Median = {params['median']:.0f}, Mode = {params['mode']:.0f}")
```

---

## Visualizing Fit

```python
import numpy as np
from scipy.stats import lognorm
import plotly.graph_objects as go

def plot_lognormal_fit(data, num_bins=30):
    """Compare histogram to fitted log-normal PDF."""
    data = np.array(data)
    data = data[data > 0]
    
    # Fit parameters
    shape, loc, scale = lognorm.fit(data, floc=0)
    
    # Histogram
    hist, bins = np.histogram(data, bins=num_bins, density=True)
    bin_centers = (bins[:-1] + bins[1:]) / 2
    
    # Theoretical PDF
    x = np.linspace(data.min(), data.max(), 200)
    pdf = lognorm.pdf(x, shape, loc, scale)
    
    fig = go.Figure()
    fig.add_trace(go.Bar(x=bin_centers, y=hist, name='Observed', opacity=0.7))
    fig.add_trace(go.Scatter(x=x, y=pdf, mode='lines', name='Log-normal fit', line=dict(width=3)))
    fig.update_layout(
        title=f'Log-Normal Fit (μ={np.log(scale):.2f}, σ={shape:.2f})',
        xaxis_title='Value',
        yaxis_title='Density'
    )
    fig.show()
```

---

## Capacity Planning with Log-Normal

### The Problem: Mean ≠ Typical

For log-normal data, the mean is inflated by rare large values:

```python
def capacity_metrics(data):
    """Calculate capacity planning metrics for log-normal data."""
    data = np.array(data)
    data = data[data > 0]
    
    log_data = np.log(data)
    mu = np.mean(log_data)
    sigma = np.std(log_data)
    
    # Key percentiles
    p50 = np.percentile(data, 50)  # Median (typical case)
    p90 = np.percentile(data, 90)
    p95 = np.percentile(data, 95)
    p99 = np.percentile(data, 99)
    
    return {
        'mean': np.mean(data),
        'median': p50,
        'p90': p90,
        'p95': p95,
        'p99': p99,
        'p99_to_median_ratio': p99 / p50,
        'mean_to_median_ratio': np.mean(data) / p50
    }

# Example interpretation
metrics = capacity_metrics(execution_sizes)
print(f"Median: {metrics['median']:.0f}")
print(f"P99: {metrics['p99']:.0f}")
print(f"P99/Median ratio: {metrics['p99_to_median_ratio']:.1f}x")
# A ratio of 10x or more indicates heavy tail planning is critical
```

### Sizing Recommendations

| σ (sigma) | P99/Median Ratio | Capacity Strategy |
|-----------|------------------|-------------------|
| < 0.5 | ~2-3x | Plan for 2x median |
| 0.5 - 1.0 | ~5-10x | Plan for P90, monitor P99 |
| 1.0 - 2.0 | ~20-50x | Plan for P95, burst capacity for P99 |
| > 2.0 | > 100x | Separate handling for "elephant" jobs |

---

## Detecting Distribution Shifts

### Change in μ (Location Shift)

The median has moved—overall scale of work changed:

```python
from scipy.stats import mannwhitneyu

def detect_location_shift(before, after, alpha=0.05):
    """
    Test if the median has shifted using Mann-Whitney U test.
    Works well for log-normal since it's based on ranks.
    """
    stat, p_value = mannwhitneyu(before, after, alternative='two-sided')
    
    median_before = np.median(before)
    median_after = np.median(after)
    
    return {
        'p_value': p_value,
        'median_before': median_before,
        'median_after': median_after,
        'shift_detected': p_value < alpha,
        'shift_direction': 'increase' if median_after > median_before else 'decrease'
    }
```

### Change in σ (Spread Shift)

The tail has gotten heavier—more extreme values:

```python
from scipy.stats import levene

def detect_spread_shift(before, after, alpha=0.05):
    """
    Test if the variance/spread has changed using Levene's test.
    Important: Compare log-transformed data for log-normal.
    """
    log_before = np.log(np.array(before)[np.array(before) > 0])
    log_after = np.log(np.array(after)[np.array(after) > 0])
    
    stat, p_value = levene(log_before, log_after)
    
    sigma_before = np.std(log_before)
    sigma_after = np.std(log_after)
    
    return {
        'p_value': p_value,
        'sigma_before': sigma_before,
        'sigma_after': sigma_after,
        'shift_detected': p_value < alpha,
        'interpretation': 'heavier tail' if sigma_after > sigma_before else 'lighter tail'
    }
```

---

## Comparing to Other Distributions

| Distribution | Log-Log Shape | Use Case |
|--------------|---------------|----------|
| **Log-normal** | Hump (bell on log-log) | Execution sizes, latencies, file sizes |
| Power-law | Straight line | Network degrees, word frequencies |
| Exponential | Steep curve | Inter-arrival times, memoryless processes |
| Poisson | Discrete, steep | Event counts per interval |

### Distinguish from Power-Law

```python
from scipy.stats import kstest

def compare_lognormal_powerlaw(data):
    """
    Compare fit quality of log-normal vs power-law.
    Uses Kolmogorov-Smirnov test.
    """
    data = np.array(data)
    data = data[data > 0]
    
    # Fit log-normal
    log_data = np.log(data)
    mu, sigma = np.mean(log_data), np.std(log_data)
    
    # K-S test for log-normal
    from scipy.stats import lognorm
    shape, loc, scale = lognorm.fit(data, floc=0)
    ks_lognorm, p_lognorm = kstest(data, 'lognorm', args=(shape, loc, scale))
    
    # For power-law, typically need specialized library (powerlaw)
    # Simplified: check if log-log is linear
    
    return {
        'lognormal_ks': ks_lognorm,
        'lognormal_pvalue': p_lognorm,
        'likely_lognormal': p_lognorm > 0.05
    }
```

---

## Quick Reference

| Property | Formula | Intuition |
|----------|---------|-----------|
| Parameters | $\mu$, $\sigma$ | Of the underlying $\ln(X)$ |
| Mean | $e^{\mu + \sigma^2/2}$ | Pulled up by tail |
| Median | $e^{\mu}$ | "Typical" value |
| Mode | $e^{\mu - \sigma^2}$ | Most common value |
| CV | $\sqrt{e^{\sigma^2} - 1}$ | Coefficient of variation |

**Rule of thumb**: 
- If $\sigma < 0.5$: Mildly skewed, mean ≈ median
- If $\sigma > 1$: Heavily skewed, mean >> median, watch P99
- If $\sigma > 2$: Extremely heavy tail, "elephant" events dominate total

---

## Related Topics

- [Poisson Distribution](poisson.md) - For event counts
- [Shift Detection](shift_detection.md) - Detecting changes in distribution parameters
