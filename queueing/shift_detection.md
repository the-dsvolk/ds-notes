# Shift Detection in Poisson Processes

Methods to detect shifts in arrival rates (e.g., job submissions, requests, events).

## When to Use Each Method

| Method | Best For | Detects |
|--------|----------|---------|
| **Poisson Test** | Comparing two periods | "Did the rate change?" |
| **Control Chart** | Ongoing monitoring | Real-time anomalies |
| **CUSUM/EWMA** | Detecting gradual shifts | When did shift start? |

---

## Method 1: Poisson Rate Test

Best for comparing count data between two periods.

**Example**: Last week 100 jobs/hour, this week 130 jobs/hour. Is this a real shift?

```python
from scipy import stats
import numpy as np

# Last week: 100 jobs/hour average over 168 hours
# This week: 130 jobs/hour average over 168 hours

# Two-sample Poisson rate test
lambda1, n1 = 100, 168  # historical rate, observation hours
lambda2, n2 = 130, 168  # current rate, observation hours

z_poisson = (lambda2 - lambda1) / np.sqrt(lambda1/n1 + lambda2/n2)
p_value = 2 * (1 - stats.norm.cdf(abs(z_poisson)))

print(f"Poisson Z-score: {z_poisson:.3f}")
print(f"P-value: {p_value:.4f}")
```

**Interpretation**:
- p < 0.05 → Unlikely to be random → Probably a real shift
- p > 0.05 → Could be random variation

---

## Method 2: Control Chart (c-chart / u-chart)

Best for **ongoing monitoring** of Poisson count data.

```python
import numpy as np

# Control limits for Poisson data (3-sigma)
average_rate = 100  # historical average jobs/hour

upper_limit = average_rate + 3 * np.sqrt(average_rate)  # ~130
lower_limit = max(0, average_rate - 3 * np.sqrt(average_rate))  # ~70

print(f"Control limits: [{lower_limit:.1f}, {upper_limit:.1f}]")

# Check current observation
current_rate = 130
if current_rate > upper_limit:
    print("ALERT: Rate exceeds upper control limit!")
elif current_rate < lower_limit:
    print("ALERT: Rate below lower control limit!")
else:
    print("Within normal variation")
```

**Rule**: If 1 point is outside ±3σ limits, it's probably not random.

### Control Chart Types

| Chart | Use Case |
|-------|----------|
| **c-chart** | Fixed observation period (e.g., jobs per hour) |
| **u-chart** | Variable observation period (e.g., jobs per variable-length shift) |

---

## Method 3: CUSUM (Cumulative Sum)

Best for detecting **gradual shifts** and identifying **when** the shift started.

```python
def cusum_detector(data, target, threshold=5):
    """
    Detect upward shift in Poisson rate.
    
    Args:
        data: sequence of observed rates
        target: expected rate (baseline)
        threshold: detection threshold (higher = fewer false alarms)
    
    Returns:
        Index where shift detected, or None
    """
    cusum_pos = 0  # Detects increase
    cusum_neg = 0  # Detects decrease
    
    for i, value in enumerate(data):
        cusum_pos = max(0, cusum_pos + (value - target))
        cusum_neg = min(0, cusum_neg + (value - target))
        
        if cusum_pos > threshold:
            print(f"Upward shift detected at observation {i}")
            return i
        if cusum_neg < -threshold:
            print(f"Downward shift detected at observation {i}")
            return i
    
    return None

# Example: hourly job counts
hourly_counts = [98, 102, 105, 110, 125, 130, 128, 135, 140]
baseline = 100
cusum_detector(hourly_counts, target=baseline, threshold=50)
```

### CUSUM vs Control Chart

| Feature | Control Chart | CUSUM |
|---------|---------------|-------|
| Detects large sudden shifts | ✓ Fast | Slower |
| Detects small gradual shifts | Poor | ✓ Good |
| Pinpoints change time | No | ✓ Yes |

---

## Quick Decision Guide

```
Is the rate different between two periods?
  → Poisson Rate Test

Need real-time monitoring for anomalies?
  → Control Chart (c-chart)

Need to detect gradual drift over time?
  → CUSUM or EWMA
```
