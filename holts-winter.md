# Holt-Winters (Triple Exponential Smoothing)

Triple Exponential Smoothing is a powerful forecasting method used when data exhibits both a **Trend** (long-term increase or decrease) and **Seasonality** (repeating cycles like daily, weekly, or yearly patterns).

---

## Why "Exponential"?

The "exponential" part refers to how the model weights past data. It uses a weighted moving average where the influence of older data points decreases exponentially over time.

In the recursive formula:

$$
S_t = \alpha y_t + (1 - \alpha)S_{t-1}
$$

When expanded mathematically:

$$
S_t = \alpha y_t + \alpha(1-\alpha)y_{t-1} + \alpha(1-\alpha)^2y_{t-2} + \dots
$$

Because $(1-\alpha)$ is a fraction (e.g., $0.8$), raising it to a higher power ($^2, ^3, ^4$) makes the weight smaller and smaller. This creates an **exponential decay curve** for the importance of history.

---

## The Three Components (The "Triple")

The method calculates three separate "levels" of the data, each with its own smoothing constant:

| Component | Parameter | Purpose |
|-----------|-----------|---------|
| **Level** | $\alpha$ (Alpha) | The base value or "average" at time $t$ |
| **Trend** | $\beta$ (Beta) | The slope or rate of change over time |
| **Seasonality** | $\gamma$ (Gamma) | The repeated pattern (e.g., every 7 days) |

---

## Additive vs Multiplicative Seasonality

The choice between Additive and Multiplicative seasonality depends on whether the size of your seasonal "swings" stays the same or grows as your data increases.

### Additive Seasonality

In an additive model, the seasonal variations are **constant in magnitude**.

**Rule:** If you see an upward trend, but the height of the peaks and the depth of the troughs remain the same (e.g., you always sell exactly 500 more units in December regardless of total yearly sales), use Additive.

$$
\text{Forecast} = \text{Level} + \text{Trend} + \text{Seasonality}
$$

### Multiplicative Seasonality

In a multiplicative model, the seasonal variations are **proportional to the level** of the series.

**Rule:** If the seasonal "swings" get larger as the trend goes up (creating a "megaphone" shape), use Multiplicative. This is very common in business growth—as a company grows, its "Holiday Peak" becomes significantly larger in absolute numbers.

$$
\text{Forecast} = (\text{Level} + \text{Trend}) \times \text{Seasonality}
$$

### Quick Reference

| Pattern | Seasonality Type |
|---------|------------------|
| Swings stay constant as level increases | Additive |
| Swings grow proportionally with level | Multiplicative |

---

## How to Choose Parameters ($\alpha, \beta, \gamma$)

The goal is to find values between 0 and 1 that make your forecast as accurate as possible. We do this by **minimizing the Mean Squared Error (MSE)**.

### The Logic of MSE Optimization

1. **Start with Guesses:** Pick random values (e.g., $0.5, 0.1, 0.1$)
2. **Calculate Error:** See how far the "forecast" for yesterday was from the "actual" value. Square that difference: $(Actual - Forecast)^2$
3. **Sum it up:** Add up all the squared errors for your entire dataset
4. **Iterate:** Use an optimization algorithm to tweak the parameters until that total error is at its minimum

---

## Implementation in Python

The `statsmodels` library can automatically optimize parameters for you.

```python
import pandas as pd
from statsmodels.tsa.holtwinters import ExponentialSmoothing

# 1. Load your data (Example: monthly sales)
df = pd.read_csv('sales_data.csv')

# 2. Initialize the Model
# 'add' means additive seasonality; 'mul' means multiplicative
model = ExponentialSmoothing(
    df['sales'], 
    trend='add', 
    seasonal='add', 
    seasonal_periods=12  # Monthly data with yearly seasonality
)

# 3. Fit the model (automatically finds the best alpha, beta, gamma)
fit_model = model.fit()

# 4. View the optimized parameters
print(f"Alpha: {fit_model.params['smoothing_level']:.4f}")
print(f"Beta:  {fit_model.params['smoothing_trend']:.4f}")
print(f"Gamma: {fit_model.params['smoothing_seasonal']:.4f}")

# 5. Forecast the next 12 months
forecast = fit_model.forecast(12)
```

### Common `seasonal_periods` Values

| Data Frequency | Seasonality | `seasonal_periods` |
|----------------|-------------|-------------------|
| Daily | Weekly | 7 |
| Daily | Yearly | 365 |
| Weekly | Yearly | 52 |
| Monthly | Yearly | 12 |
| Quarterly | Yearly | 4 |

---

## Plotting Forecast with Plotly

```python
import plotly.graph_objects as go

# Get forecast with confidence intervals
forecast = fit_model.forecast(12)

fig = go.Figure()

# Historical data
fig.add_trace(go.Scatter(
    x=df.index, 
    y=df['sales'],
    mode='lines', 
    name='Historical'
))

# Forecast
fig.add_trace(go.Scatter(
    x=forecast.index, 
    y=forecast.values,
    mode='lines', 
    name='Forecast', 
    line=dict(color='red', dash='dash')
))

fig.update_layout(
    title='Holt-Winters Forecast',
    xaxis_title='Date',
    yaxis_title='Sales'
)
fig.show()
```

---

## Summary

| Aspect | Details |
|--------|---------|
| **Use when** | Data has both trend and seasonality |
| **Parameters** | $\alpha$ (level), $\beta$ (trend), $\gamma$ (seasonal) |
| **Optimization** | Minimizes MSE automatically |
| **Additive** | Constant seasonal amplitude |
| **Multiplicative** | Seasonal amplitude grows with level |
