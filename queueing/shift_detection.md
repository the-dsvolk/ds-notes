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
import numpy as np

def cusum_detector(data, baseline, target_shift=None, confidence_multiplier=4.0):
    """
    Detect shift in Poisson rate with automatic parameter selection.
    
    Args:
        data: sequence of observed rates
        baseline: expected rate (mean under normal conditions)
        target_shift: minimum shift size to detect (default: 20% of baseline)
        confidence_multiplier: controls false alarm rate (default: 4.0)
            - 3.0 = more sensitive, more false alarms
            - 5.0 = less sensitive, fewer false alarms
    
    Returns:
        Index where shift detected, or None
    """
    # 1. Automatic Parameter Selection
    if target_shift is None:
        target_shift = 0.2 * baseline  # Default: detect 20% shift
    
    # Drift = Half of the shift we want to catch
    # This centers the CUSUM to accumulate fastest for shifts of size target_shift
    drift = target_shift / 2
    
    # Threshold = Multiple of the Poisson noise (sqrt of mean)
    # For Poisson, std dev = sqrt(mean), so threshold scales with noise level
    threshold = confidence_multiplier * np.sqrt(baseline)
    
    # 2. Run CUSUM
    cusum_pos = 0  # Detects increase
    cusum_neg = 0  # Detects decrease
    
    for i, value in enumerate(data):
        # Subtract drift to reduce noise accumulation
        cusum_pos = max(0, cusum_pos + (value - baseline - drift))
        cusum_neg = min(0, cusum_neg + (value - baseline + drift))
        
        if cusum_pos > threshold:
            print(f"Upward shift detected at observation {i}")
            return i
        if cusum_neg < -threshold:
            print(f"Downward shift detected at observation {i}")
            return i
    
    return None

# Example: baseline 100 jobs/hour, detect 20% shifts
hourly_counts = [98, 102, 105, 110, 125, 130, 128, 135, 140]
cusum_detector(hourly_counts, baseline=100)
```

### Parameter Selection Logic

| Parameter | Formula | Purpose |
|-----------|---------|---------|
| `drift` | `target_shift / 2` | Filters out noise; only accumulates for real shifts |
| `threshold` | `k × √baseline` | Scales with Poisson noise; k controls sensitivity |

### CUSUM vs Control Chart

| Feature | Control Chart | CUSUM |
|---------|---------------|-------|
| Detects large sudden shifts | ✓ Fast | Slower |
| Detects small gradual shifts | Poor | ✓ Good |
| Pinpoints change time | No | ✓ Yes |

---

## Method 4: EWMA (Exponentially Weighted Moving Average)

Best for **adaptive baseline** that evolves with your data. Good for workloads with trends or slow drift.

```python
import numpy as np

def ewma_detector(data, alpha=0.2, threshold=3.0):
    """
    EWMA-based shift detector with adaptive baseline.
    
    Weight decay (no fixed window - all history contributes):
        Current:   α
        Previous:  α(1-α)
        2 back:    α(1-α)²
        3 back:    α(1-α)³  ...and so on
    
    Effective window ≈ 2/α - 1 (e.g., α=0.2 → ~9 observations)
    
    Args:
        data: sequence of observed rates
        alpha: smoothing factor (0.1-0.3 typical). Higher = more reactive
        threshold: number of std devs for alert
    
    Returns:
        Index where shift detected, or None
    """
    ewma = data[0]
    ewma_var = 0
    
    for i, value in enumerate(data[1:], 1):
        # Update EWMA (exponentially weighted mean)
        ewma = alpha * value + (1 - alpha) * ewma
        
        # Update EWMA variance estimate
        ewma_var = alpha * (value - ewma)**2 + (1 - alpha) * ewma_var
        ewma_std = np.sqrt(ewma_var)
        
        # Check for deviation
        if ewma_std > 0:
            z_score = abs(value - ewma) / ewma_std
            if z_score > threshold:
                print(f"Shift detected at observation {i}, z={z_score:.2f}")
                return i
    
    return None

# Example
hourly_counts = [100, 102, 98, 105, 101, 140, 145, 150, 148]
ewma_detector(hourly_counts, alpha=0.2, threshold=3.0)
```

### Choosing Alpha (α)

| Alpha | Behavior | Use When |
|-------|----------|----------|
| 0.1 | Slow adaptation, smooth | Stable workload, avoid false alarms |
| 0.2 | Balanced | General purpose |
| 0.3+ | Fast adaptation, reactive | Rapidly changing workload |

### EWMA vs CUSUM

| Feature | CUSUM | EWMA |
|---------|-------|------|
| Baseline | Fixed target | Adaptive (evolves) |
| Best for | Detecting deviation from known baseline | Tracking evolving workload |
| False positives with trend | More likely | Less likely |

---

## Quick Decision Guide

```
Is the rate different between two periods?
  → Poisson Rate Test

Need real-time monitoring for anomalies?
  → Control Chart (c-chart)

Need to detect shift from a KNOWN baseline?
  → CUSUM

Need adaptive baseline that evolves with workload?
  → EWMA
```
