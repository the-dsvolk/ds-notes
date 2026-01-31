# A/B Testing: Two-Proportion Z-Test

The most important statistical test for A/B testing when comparing conversion rates, click-through rates, or any binary outcome.

## The Core Idea

You have two independent groups (A and B), and you measure success proportions in each:

- **Group A**: p̂₁ = x₁/n₁ (e.g., 120 conversions out of 1000 visitors = 0.12)
- **Group B**: p̂₂ = x₂/n₂ (e.g., 150 conversions out of 1000 visitors = 0.15)

**Question**: Is this difference statistically significant, or could it be due to random chance?

## Key Assumptions

1. **Independent samples**: No user is in both groups
2. **Random assignment**: Users randomly assigned to A or B
3. **Large enough sample size** (rule of thumb for each group):
   - n₁p̂₁ ≥ 10
   - n₁(1-p̂₁) ≥ 10
   - n₂p̂₂ ≥ 10
   - n₂(1-p̂₂) ≥ 10
4. **Independent observations**: Each user's outcome doesn't affect others

## The Test Statistic

### Pooled Proportion

Under H₀ (p₁ = p₂ = p), we estimate the common proportion by pooling both samples:

```
p̂ = (x₁ + x₂) / (n₁ + n₂)
```

**Why pool?** Under H₀, both samples come from populations with the same proportion. Pooling gives a more precise standard error for testing the null hypothesis.

### Z-Score Formula

```
        p̂₁ - p̂₂
Z = ─────────────────────────
    √[p̂(1-p̂)(1/n₁ + 1/n₂)]
```

Where:
- **Numerator**: Observed difference = (p̂₁ - p̂₂)
- **Denominator**: Standard Error under H₀

## Example: Conversion Rate A/B Test

**Scenario**:
- Version A (control): 120 conversions / 1000 visitors → p̂₁ = 0.12
- Version B (treatment): 150 conversions / 1000 visitors → p̂₂ = 0.15

### Step 1: State Hypotheses

- H₀: p₁ = p₂ (Version B is no better than A)
- H₁: p₂ > p₁ (Version B has higher conversion)
- α = 0.05

### Step 2: Pooled Proportion

```
p̂ = (120 + 150) / (1000 + 1000) = 270/2000 = 0.135
```

### Step 3: Standard Error

```
SE = √[0.135 × 0.865 × (1/1000 + 1/1000)]
   = √[0.135 × 0.865 × 0.002]
   = 0.01528
```

### Step 4: Z-Score

```
Z = (0.15 - 0.12) / 0.01528 = 1.962
```

### Step 5: p-value

For Z = 1.962:
- One-tailed: p-value = 0.025
- Two-tailed: p-value = 0.05

### Step 6: Decision

Since p-value (0.025) < α (0.05), **reject H₀**.

**Conclusion**: Version B has statistically significantly higher conversion than Version A.

## Confidence Interval Approach

Instead of hypothesis test, compute 95% CI for the difference:

```
(p̂₁ - p̂₂) ± Z* × √[p̂₁(1-p̂₁)/n₁ + p̂₂(1-p̂₂)/n₂]
```

Where Z* = 1.96 for 95% confidence.

**Example**:
```
0.03 ± 1.96 × √[(0.12×0.88/1000) + (0.15×0.85/1000)]
= 0.03 ± 0.0296
= (0.0004, 0.0596)
```

**Interpretation**: 95% confident the true difference is between 0.04% and 5.96%.

## Sample Size Calculation

Decide **before** running the test:

- Baseline conversion rate (p₁)
- Minimum Detectable Effect (MDE)
- Significance level (α, typically 0.05)
- Power (1-β, typically 0.8)

```
n = [(Z_α + Z_β)² × (p₁(1-p₁) + p₂(1-p₂))] / (p₁ - p₂)²
```

## One-tailed vs Two-tailed

| Type | When to use |
|------|-------------|
| **One-tailed** | Only care if B > A (or A > B) |
| **Two-tailed** | Care if B ≠ A (could be better or worse) |

**Default for A/B testing**: Two-tailed, unless you have a strong directional hypothesis.

## Common Pitfalls

1. **Stopping too early**: Small samples → unstable results
2. **Peeking**: Checking results repeatedly inflates false positive rate
3. **Multiple comparisons**: Testing many variations without correction
4. **Ignoring practical significance**: 0.1% improvement might be statistically significant but not business-relevant
5. **Violating independence**: Same user seeing both versions

## Python Implementation

```python
import numpy as np
from statsmodels.stats.proportion import proportions_ztest

# Data
conversions = [120, 150]  # [Group A, Group B]
visitors = [1000, 1000]

# Two-proportion z-test
z_stat, p_value = proportions_ztest(conversions, visitors, alternative='two-sided')

print(f"Z-statistic: {z_stat:.3f}")
print(f"P-value: {p_value:.4f}")

# Manual calculation
p1, p2 = 120/1000, 150/1000
p_pool = (120 + 150) / (1000 + 1000)
se = np.sqrt(p_pool * (1 - p_pool) * (1/1000 + 1/1000))
z_manual = (p2 - p1) / se

print(f"Manual Z: {z_manual:.3f}")
```

**Output**:
```
Z-statistic: 1.962
P-value: 0.0498
Manual Z: 1.962
```

## Summary

| Component | Formula |
|-----------|---------|
| Pooled proportion | p̂ = (x₁ + x₂) / (n₁ + n₂) |
| Standard error | SE = √[p̂(1-p̂)(1/n₁ + 1/n₂)] |
| Z-score | Z = (p̂₁ - p̂₂) / SE |

**Key insight**: Pooling proportions under H₀ makes this more powerful than comparing with individual standard errors. The test asks: *"Assuming there's no real difference, how unlikely is the difference we observed?"*
