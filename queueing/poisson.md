# Poisson Distribution

Model for counting events that occur randomly at a constant average rate.

## The Formula

The probability of receiving exactly $k$ events in a given interval:

$$P(X=k) = \frac{\lambda^k e^{-\lambda}}{k!}$$

Where:
- $\lambda$ (Lambda): Average number of events (the mean)
- $k$: Actual number of events observed

## Key Property: Mean = Variance

In a true Poisson distribution:

$$E[X] = Var(X) = \lambda$$

This is the foundation for detecting anomalies.

---

## First Question: Is My Data Actually Poisson?

Before using Poisson models, verify the assumption holds.

### Method 1: Dispersion Test (Quick Check)

```python
import numpy as np

def dispersion_test(counts):
    """
    Test if variance ≈ mean (Poisson property).
    Returns dispersion ratio and interpretation.
    """
    mean = np.mean(counts)
    var = np.var(counts, ddof=1)
    ratio = var / mean
    
    # Chi-squared test for dispersion
    n = len(counts)
    chi2 = (n - 1) * ratio
    
    from scipy.stats import chi2 as chi2_dist
    p_value = 2 * min(chi2_dist.cdf(chi2, n-1), 1 - chi2_dist.cdf(chi2, n-1))
    
    return {
        'dispersion_ratio': ratio,
        'p_value': p_value,
        'is_poisson': 0.5 < ratio < 1.5 and p_value > 0.05
    }

# Example: hourly job counts
counts = [98, 102, 95, 108, 101, 97, 105, 99]
result = dispersion_test(counts)
print(f"Dispersion ratio: {result['dispersion_ratio']:.2f}")
print(f"Is Poisson: {result['is_poisson']}")
```

### Method 2: Chi-Squared Goodness of Fit

```python
from scipy.stats import chisquare, poisson
import numpy as np

def poisson_goodness_of_fit(counts, num_bins=10):
    """
    Chi-squared test comparing observed distribution to Poisson.
    H0: Data follows Poisson distribution.
    """
    lambda_hat = np.mean(counts)
    
    # Create histogram of observed counts
    observed, bin_edges = np.histogram(counts, bins=num_bins)
    
    # Calculate expected frequencies under Poisson
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
    expected_probs = poisson.pmf(np.round(bin_centers).astype(int), lambda_hat)
    expected = expected_probs * len(counts)
    
    # Avoid zero expected counts
    mask = expected > 5
    
    chi2, p_value = chisquare(observed[mask], expected[mask])
    
    return {
        'chi2': chi2,
        'p_value': p_value,
        'is_poisson': p_value > 0.05  # Fail to reject H0
    }
```

### Method 3: Visual Check

```python
import numpy as np
from scipy.stats import poisson
import plotly.graph_objects as go

def plot_poisson_fit(counts):
    """Compare histogram to fitted Poisson PMF."""
    lambda_hat = np.mean(counts)
    
    # Observed histogram
    hist, bins = np.histogram(counts, bins='auto', density=True)
    bin_centers = (bins[:-1] + bins[1:]) / 2
    
    # Theoretical Poisson
    x = np.arange(0, max(counts) + 1)
    pmf = poisson.pmf(x, lambda_hat)
    
    fig = go.Figure()
    fig.add_trace(go.Bar(x=bin_centers, y=hist, name='Observed'))
    fig.add_trace(go.Scatter(x=x, y=pmf, mode='lines+markers', name=f'Poisson(λ={lambda_hat:.1f})'))
    fig.update_layout(title='Observed vs Poisson Fit')
    fig.show()
```

### Quick Decision

| Dispersion Ratio | Interpretation | Action |
|------------------|----------------|--------|
| 0.8 - 1.2 | Likely Poisson | Use Poisson models |
| > 1.5 | Overdispersed | Use Negative Binomial instead |
| < 0.5 | Underdispersed | Data too regular, investigate |

---

## Health Check: Variance vs Mean

| Condition | Name | Meaning |
|-----------|------|---------|
| $Var(X) = E[X]$ | Equidispersed | Normal Poisson behavior |
| $Var(X) > E[X]$ | **Overdispersed** | Traffic is "clumpy" or bursty |
| $Var(X) < E[X]$ | Underdispersed | More regular than random |

**Sign of a shift**: If $Var(X) > E[X]$, the workload has become bursty (e.g., retry storms). The Poisson assumption has broken, and capacity models need to adjust for higher volatility.

```python
def check_dispersion(observed_counts):
    """Check if traffic follows Poisson (mean ≈ variance)"""
    mean = sum(observed_counts) / len(observed_counts)
    variance = sum((x - mean)**2 for x in observed_counts) / len(observed_counts)
    
    dispersion_ratio = variance / mean
    
    if dispersion_ratio > 1.5:
        return "Overdispersed (bursty traffic)"
    elif dispersion_ratio < 0.5:
        return "Underdispersed (too regular)"
    else:
        return "Normal Poisson"
```

---

## Detecting Heavy Tails

Check for heavy-tailed distributions where outliers (P99) are significantly larger than average.

**Metric**: Use **Kurtosis**. High kurtosis means the "tail" is fat—a few "elephant" requests could saturate resources even if average RPS looks fine.

```python
from scipy.stats import kurtosis

# Excess kurtosis > 3 suggests heavy tails
k = kurtosis(request_times, fisher=True)
if k > 3:
    print("Warning: Heavy-tailed distribution detected")
```

---

## Shift Detection

For detecting if a Poisson rate has shifted, see [shift_detection.md](shift_detection.md):
- Poisson Rate Test (comparing two periods)
- Control Charts for ongoing monitoring
- CUSUM for gradual drift detection

---

## Handling Seasonality ("Monday 9 AM" Problem)

A predictable burst (like everyone logging in at 9 AM Monday) will trigger false positive alarms with simple moving averages.

### Solutions

**1. Seasonal Comparison**

Compare "now" to "same time last week," not "10 minutes ago":

```python
# Day-over-Day or Week-over-Week baseline
shift = X_now - X_last_week_same_time

if abs(shift) < threshold:
    print("Normal seasonal burst")
else:
    print("Genuine workload shift on top of seasonality")
```

**2. Predictive Scaling (Warm-up)**

Don't wait for detection. If the pattern is consistent:
- Use scheduled scaling to pre-warm fleet to 120% capacity at 8:45 AM
- Cron-based approach avoids reactive scrambling

**3. Seasonal Decomposition**

Strip out seasonality to see if current burst exceeds *expected* burst:

```python
from statsmodels.tsa.seasonal import seasonal_decompose

result = seasonal_decompose(traffic_series, period=24*7)  # Weekly
residual = result.resid  # Actual - Seasonal - Trend

# Monitor residual for anomalies, not raw traffic
```

---

## Quick Reference

| Property | Value |
|----------|-------|
| Mean | $\lambda$ |
| Variance | $\lambda$ |
| Std Dev | $\sqrt{\lambda}$ |
| Z-score | $(X - \lambda) / \sqrt{\lambda}$ |

**Rule of thumb**: If observed count is more than $3\sqrt{\lambda}$ away from $\lambda$, it's likely a real shift (p < 0.003).
