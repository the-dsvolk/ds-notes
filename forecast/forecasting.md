# Time Series Forecasting Procedure

## Complete Procedure (Enhanced)

1. Explore Data
2. Choose Candidate Models
3. Time-Based Train/Test Split
4. Cross-Validation (Time Series)
5. Fit & Evaluate Each Model
6. Select Best Model
7. Re-fit on Entire Dataset
8. Forecast with Confidence Intervals
9. Monitor & Retrain

---

### 1. Explore Data
- Check for trends, seasonality, stationarity
- Handle missing values
- Visualize patterns

#### Smoothing Techniques for Exploration

Use smoothing to **reveal underlying trends** by removing short-term noise.

| Technique | Formula | Best For |
|-----------|---------|----------|
| **Simple Moving Average (SMA)** | Mean of last N points | Equal weight to recent history |
| **Exponential Moving Average (EMA)** | Weighted, recent = heavier | Emphasize recent data |
| **Double Exponential** | EMA of EMA | Capture trends |

#### Simple Moving Average (SMA)

```python
# Rolling mean - all points weighted equally
df['SMA_7'] = df['value'].rolling(window=7).mean()   # 7-day
df['SMA_30'] = df['value'].rolling(window=30).mean() # 30-day
```

#### Exponential Moving Average (EMA)

```python
# Exponential weighted mean - recent values weighted more heavily
df['EMA_7'] = df['value'].ewm(span=7).mean()
df['EMA_30'] = df['value'].ewm(span=30).mean()

# 'span' controls decay: higher span = smoother, slower to react
```

**Key parameter:** `span` (or `alpha`)
- `span=7` → ~86% weight on last 7 points
- `span=30` → ~86% weight on last 30 points
- Higher span = smoother curve, slower reaction to changes

#### Comparison Plot

```python
import plotly.graph_objects as go

fig = go.Figure()
fig.add_trace(go.Scatter(x=df.index, y=df['value'], name='Raw', opacity=0.3))
fig.add_trace(go.Scatter(x=df.index, y=df['SMA_7'], name='SMA(7)'))
fig.add_trace(go.Scatter(x=df.index, y=df['EMA_7'], name='EMA(7)'))
fig.update_layout(title='Raw vs Smoothed Data')
fig.show()
```

#### When to Use Which

| Scenario | Recommended |
|----------|-------------|
| Detect long-term trend | SMA with large window (30+) |
| React quickly to changes | EMA with small span (7-14) |
| Remove daily noise | SMA(7) or EMA(7) |
| Seasonal pattern check | SMA matching season length (e.g., 7 for weekly) |

#### Decomposition (Alternative)

For formal trend/seasonality separation:

```python
from statsmodels.tsa.seasonal import seasonal_decompose

result = seasonal_decompose(df['value'], model='additive', period=7)
result.plot()  # Shows: observed, trend, seasonal, residual
```

### 2. Choose Candidate Models (plural)
- Simple baseline (naive, seasonal naive)
- Statistical (ARIMA, ETS, Exponential Smoothing)
- ML-based (XGBoost, Prophet, LSTM)

### 3. Time-Based Train/Test Split

⚠️ **Critical:** Never use random split for time series!

```
❌ WRONG (random split):
Train: [Jan, Mar, May, Jul]  ← future leaks into past!
Test:  [Feb, Apr, Jun, Aug]

✅ CORRECT (temporal split):
Train: [Jan, Feb, Mar, Apr, May, Jun]
Test:  [Jul, Aug]  ← always predict forward
```

```python
train = df[df.index < '2023-06-01']
test = df[df.index >= '2023-06-01']
```

### 4. Cross-Validation (Time Series)

Use **rolling/expanding window** validation:

#### Expanding Window vs Rolling Window

| Type | Training Window | Use Case |
|------|-----------------|----------|
| **Expanding** | Grows each fold | More data = better model (common) |
| **Rolling** | Fixed size, slides forward | Recent data matters most |

```
EXPANDING WINDOW (training grows):
Fold 1: Train [===]         → Test [*]
Fold 2: Train [====]        → Test [*]
Fold 3: Train [=====]       → Test [*]
Fold 4: Train [======]      → Test [*]

ROLLING WINDOW (fixed size, slides):
Fold 1: Train [===]         → Test [*]
Fold 2:       Train [===]   → Test [*]
Fold 3:           Train [===] → Test [*]
Fold 4:               Train [===] → Test [*]
```

#### Expanding Window (sklearn TimeSeriesSplit)

```python
from sklearn.model_selection import TimeSeriesSplit
from sklearn.metrics import mean_absolute_error
import numpy as np

# Expanding window: training set grows each fold
tscv = TimeSeriesSplit(n_splits=5)
scores = []

for fold, (train_idx, test_idx) in enumerate(tscv.split(df)):
    train, test = df.iloc[train_idx], df.iloc[test_idx]
    
    print(f"Fold {fold+1}: Train size={len(train)}, Test size={len(test)}")
    
    # Fit model
    model.fit(train['X'], train['y'])
    
    # Predict & evaluate
    preds = model.predict(test['X'])
    score = mean_absolute_error(test['y'], preds)
    scores.append(score)

print(f"Average MAE: {np.mean(scores):.2f} ± {np.std(scores):.2f}")
```

#### Rolling Window (Fixed Size - Manual)

```python
def rolling_window_cv(df, train_size, test_size, step=1):
    """
    Rolling window cross-validation with fixed training size.
    
    Args:
        df: DataFrame with datetime index
        train_size: Number of periods for training
        test_size: Number of periods for testing
        step: How many periods to slide forward each fold
    """
    scores = []
    n = len(df)
    
    fold = 0
    start = 0
    
    while start + train_size + test_size <= n:
        train_end = start + train_size
        test_end = train_end + test_size
        
        train = df.iloc[start:train_end]
        test = df.iloc[train_end:test_end]
        
        print(f"Fold {fold+1}: Train [{start}:{train_end}], Test [{train_end}:{test_end}]")
        
        # Fit and evaluate your model here
        # model.fit(train)
        # preds = model.predict(test)
        # scores.append(evaluate(test, preds))
        
        start += step
        fold += 1
    
    return scores

# Example: 100 days training, 7 days test, slide by 7 days
# rolling_window_cv(df, train_size=100, test_size=7, step=7)
```

#### Which to Choose?

| Scenario | Recommended |
|----------|-------------|
| Long-term patterns matter | Expanding |
| Recent data is most relevant | Rolling |
| Concept drift (patterns change over time) | Rolling |
| Limited data | Expanding (uses all available) |
| Computational constraints | Rolling (fixed train size) |

### 5. Fit & Evaluate Each Model

Compare models using consistent metrics:
- **MAE** (Mean Absolute Error) - interpretable units
- **RMSE** (Root Mean Squared Error) - penalizes large errors
- **MAPE** (Mean Absolute Percentage Error) - scale-independent

### 6. Select Best Model

Choose based on:
- Cross-validation performance
- Computational cost
- Interpretability requirements

### 7. Re-fit on Entire Dataset

Once model is validated, use all available data:

```python
final_model.fit(df['X'], df['y'])  # All data
```

### 8. Forecast with Confidence Intervals

Confidence intervals quantify forecast uncertainty — essential for decision-making.

#### Why Confidence Intervals Matter

```
Point forecast alone:     "Demand will be 75 units"
With confidence interval: "Demand will be 75 ± 12 units (95% CI)"
```

The interval widens as you forecast further into the future (uncertainty grows).

#### ARIMA Confidence Intervals

ARIMA models from `statsmodels` provide built-in confidence intervals:

```python
from statsmodels.tsa.arima.model import ARIMA
import plotly.graph_objects as go

# Fit ARIMA model
model = ARIMA(train, order=(1, 1, 1))  # (p, d, q)
fitted = model.fit()

# Forecast with confidence intervals
forecast = fitted.get_forecast(steps=30)
pred_mean = forecast.predicted_mean
conf_int = forecast.conf_int(alpha=0.05)  # 95% CI

# conf_int has columns: 'lower y' and 'upper y'
lower = conf_int.iloc[:, 0]
upper = conf_int.iloc[:, 1]
```

#### Plotting with Confidence Intervals (Plotly)

```python
fig = go.Figure()

# Historical data
fig.add_trace(go.Scatter(
    x=train.index, y=train.values,
    mode='lines', name='Historical'
))

# Forecast
fig.add_trace(go.Scatter(
    x=pred_mean.index, y=pred_mean.values,
    mode='lines', name='Forecast', line=dict(color='red')
))

# Confidence interval (shaded area)
fig.add_trace(go.Scatter(
    x=list(pred_mean.index) + list(pred_mean.index[::-1]),
    y=list(upper) + list(lower[::-1]),
    fill='toself', fillcolor='rgba(255,0,0,0.2)',
    line=dict(color='rgba(255,255,255,0)'),
    name='95% CI'
))

fig.update_layout(title='ARIMA Forecast with Confidence Interval')
fig.show()
```

#### Interpretation

| CI Width | Meaning |
|----------|---------|
| Narrow | Model is confident (or overconfident!) |
| Wide | High uncertainty — use caution |
| Growing rapidly | Forecast horizon may be too long |

#### Confidence Level Options

```python
conf_int_90 = forecast.conf_int(alpha=0.10)  # 90% CI (narrower)
conf_int_95 = forecast.conf_int(alpha=0.05)  # 95% CI (default)
conf_int_99 = forecast.conf_int(alpha=0.01)  # 99% CI (wider)
```

**Rule of thumb:** 95% CI means "we expect the true value to fall within this range 95% of the time."

### 9. Monitor & Retrain (Ongoing)

- Track forecast accuracy over time
- Retrain when performance degrades
- Update with new data periodically
