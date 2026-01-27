# Forecasting Metrics

## MAE (Mean Absolute Error)

Average of absolute differences between predicted and actual values.

$$
\text{MAE} = \frac{1}{n} \sum_{i=1}^{n} |y_i - \hat{y}_i|
$$

```python
from sklearn.metrics import mean_absolute_error
mae = mean_absolute_error(y_true, y_pred)
```

---

## MSE (Mean Squared Error)

Average of squared differences. Penalizes large errors more heavily.

$$
\text{MSE} = \frac{1}{n} \sum_{i=1}^{n} (y_i - \hat{y}_i)^2
$$

```python
from sklearn.metrics import mean_squared_error
mse = mean_squared_error(y_true, y_pred)
```

---

## RMSE (Root Mean Squared Error)

Square root of MSE. Same units as the target variable.

$$
\text{RMSE} = \sqrt{\frac{1}{n} \sum_{i=1}^{n} (y_i - \hat{y}_i)^2}
$$

```python
from sklearn.metrics import root_mean_squared_error
rmse = root_mean_squared_error(y_true, y_pred)

# Or manually:
import numpy as np
rmse = np.sqrt(mean_squared_error(y_true, y_pred))
```

---

## Statsmodels Usage

```python
from statsmodels.tools.eval_measures import mse, rmse, meanabs

mae = meanabs(y_true, y_pred)
mse_val = mse(y_true, y_pred)
rmse_val = rmse(y_true, y_pred)
```

---

## Comparison

| Metric | Units | Sensitivity to Outliers |
|--------|-------|------------------------|
| MAE | Same as target | Low |
| MSE | Squared units | High |
| RMSE | Same as target | High |
