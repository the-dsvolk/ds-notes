# ARIMA (AutoRegressive Integrated Moving Average)

ARIMA(p, d, q) combines three components to model time series data.

---

## The Three Components

| Parameter | Component | Purpose |
|-----------|-----------|---------|
| **p** | AutoRegressive (AR) | Use past values to predict current |
| **d** | Integrated (I) | Differencing to remove trend |
| **q** | Moving Average (MA) | Use past forecast errors to predict current |

---

## AR: AutoRegressive (p)

**Idea:** Today's value depends on previous values.

$$
y_t = c + \phi_1 y_{t-1} + \phi_2 y_{t-2} + \dots + \phi_p y_{t-p} + \epsilon_t
$$

- $p$ = how many past values to use
- $\phi_i$ = learned weights for each lag
- $\epsilon_t$ = random noise

**Example:** AR(2) means today depends on yesterday and the day before:
$$
y_t = c + \phi_1 y_{t-1} + \phi_2 y_{t-2} + \epsilon_t
$$

---

## I: Integrated (d)

**Idea:** Difference the data to remove trend and make it stationary.

$$
y'_t = y_t - y_{t-1}
$$

- $d=1$: First difference (removes linear trend)
- $d=2$: Second difference (removes quadratic trend)

**Example:** If $d=1$, instead of modeling $y_t$, we model the changes:
$$
y'_t = y_t - y_{t-1}
$$

---

## MA: Moving Average (q)

**Idea:** Today's value depends on past forecast errors (not past values).

$$
y_t = c + \epsilon_t + \theta_1 \epsilon_{t-1} + \theta_2 \epsilon_{t-2} + \dots + \theta_q \epsilon_{t-q}
$$

- $q$ = how many past errors to use
- $\theta_i$ = learned weights for each error lag
- $\epsilon_t$ = forecast error at time $t$

**Example:** MA(1) means today's value is adjusted by yesterday's error:
$$
y_t = c + \epsilon_t + \theta_1 \epsilon_{t-1}
$$

---

## Full ARIMA(p, d, q) Equation

Combining all three on the differenced series:

$$
y'_t = c + \underbrace{\phi_1 y'_{t-1} + \dots + \phi_p y'_{t-p}}_{\text{AR(p)}} + \underbrace{\epsilon_t + \theta_1 \epsilon_{t-1} + \dots + \theta_q \epsilon_{t-q}}_{\text{MA(q)}}
$$

Where $y'_t$ is the $d$-times differenced series.

---

## Quick Reference

| Order | Effect |
|-------|--------|
| p=0 | No autoregressive terms (ignore past values) |
| p=1 | Use only yesterday's value |
| p=2 | Use yesterday + day before |
| d=0 | No differencing (data already stationary) |
| d=1 | Remove linear trend |
| d=2 | Remove quadratic trend |
| q=0 | No moving average terms (ignore past errors) |
| q=1 | Correct using yesterday's error |
| q=2 | Correct using last 2 errors |
