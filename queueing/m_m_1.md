# M/M/1 Queuing Model

The M/M/1 queue is the foundational stochastic model in queuing theory. It represents a system with a single server where customers arrive and are processed according to specific probabilistic rules. It is the simplest non-trivial model used to predict wait times and system congestion.

## 1. System Components

The notation follows **Kendall's Notation** ($A/B/c$):

| Symbol | Meaning |
|--------|---------|
| **M** (Arrivals) | Markovian (Poisson) arrival process |
| **M** (Service) | Markovian (Exponential) service time distribution |
| **1** (Server) | Exactly one server available |

### Key Characteristics

- **Arrival Process:** Customers arrive at a constant average rate $\lambda$. The time between arrivals follows an Exponential Distribution.
- **Service Process:** The server processes customers at a constant average rate $\mu$. The service time follows an Exponential Distribution.
- **Capacity:** Infinite buffer (no limit on queue length).
- **Queue Discipline:** FIFO (First-In, First-Out).

### Poisson Process (Arrivals Over Time)

The "M" in M/M/1 stands for **Markovian**, meaning arrivals follow a Poisson process. Arrivals occur randomly but at a constant average rate $\lambda$.

```
Poisson Arrivals Over Time (λ = 4 arrivals/hour)

Hour 1:    ↓   ↓      ↓  ↓↓        ↓
        ───●───●──────●──●●────────●───────────→ time
           5  12     28 3536      52 min
           
           (6 arrivals — above average)

Hour 2:        ↓          ↓     ↓
        ───────●──────────●─────●───────────────→ time
              18         41    53 min
              
           (3 arrivals — below average)

Hour 3:    ↓    ↓    ↓       ↓
        ───●────●────●───────●──────────────────→ time
           8   19   31      48 min
           
           (4 arrivals — exactly average)

Key: Arrivals are random, but average out to λ = 4/hour
```

The probability of exactly $k$ arrivals in one time unit:

$$P(k) = \frac{\lambda^k e^{-\lambda}}{k!}$$

| k (arrivals/hour) | P(k) for λ=4 |
|-------------------|--------------|
| 0 | 1.8% |
| 1 | 7.3% |
| 2 | 14.7% |
| 3 | 19.5% |
| 4 | 19.5% ← most likely |
| 5 | 15.6% |
| 6+ | 21.6% |

**Key Properties:**
- Mean = Variance = $\lambda$
- Arrivals are independent (no clustering or patterns)
- "Memoryless": past arrivals don't affect future arrivals

### Exponential Distribution (Inter-arrival Times)

The time *between* arrivals follows an Exponential distribution:

$$f(t) = \lambda e^{-\lambda t}$$

```
Exponential Distribution (λ = 4/hour → mean = 15 min)

f(t)
 │
 │██
 │████
 │██████
 │████████
 │██████████
 │████████████████
 │██████████████████████████
 ┼───────────────────────────────→ t (minutes)
 0     15     30     45     60
       ↑
    mean = 1/λ
```

**Key Properties:**
- Mean inter-arrival time = $1/\lambda$
- Continuous distribution (measures time)
- "Memoryless": time already waited doesn't affect expected remaining wait

## 2. Stability Condition: Traffic Intensity

Before calculating performance, determine the **Traffic Intensity** (utilization), denoted by $\rho$:

$$\rho = \frac{\lambda}{\mu}$$

> **Stability Requirement:** For the system to reach a "steady state," the arrival rate must be less than the service rate ($\lambda < \mu$), meaning $\rho < 1$. If $\rho \geq 1$, the queue will grow infinitely over time.

```
ρ < 1: Stable          ρ ≥ 1: Unstable
                       
   λ → [Queue] → μ        λ → [Queue ∞∞∞] → μ
   ↓              ↓       ↓                  ↓
  100            120     120                100
 jobs/hr       jobs/hr  jobs/hr           jobs/hr
```

## 3. Key Performance Formulas (Steady-State)

Once the system stabilizes, calculate average customers and waiting times.

### System vs Queue

- **System:** Customer being served + those waiting
- **Queue:** Only those waiting in line

| Metric | Symbol | Formula |
|--------|--------|---------|
| Average number in **system** | $L$ | $L = \frac{\rho}{1 - \rho} = \frac{\lambda}{\mu - \lambda}$ |
| Average number in **queue** | $L_Q$ | $L_Q = \frac{\rho^2}{1 - \rho} = \frac{\lambda^2}{\mu(\mu - \lambda)}$ |
| Average time in **system** | $W$ | $W = \frac{1}{\mu - \lambda}$ |
| Average time in **queue** | $W_Q$ | $W_Q = \frac{\lambda}{\mu(\mu - \lambda)}$ |

### Example Calculation

```
λ = 80 jobs/hour (arrivals)
μ = 100 jobs/hour (service rate)

ρ = 80/100 = 0.8 (80% utilization)

L   = 0.8 / (1 - 0.8) = 4 jobs in system
L_Q = 0.8² / (1 - 0.8) = 3.2 jobs waiting
W   = 1 / (100 - 80) = 0.05 hours = 3 minutes in system
W_Q = 80 / (100 × 20) = 0.04 hours = 2.4 minutes waiting
```

## 4. Probability of System States

Calculate the probability of exactly $n$ customers in the system:

| State | Formula |
|-------|---------|
| System is empty ($P_0$) | $P_0 = 1 - \rho$ |
| Exactly $n$ customers ($P_n$) | $P_n = (1 - \rho)\rho^n$ |

### Example: Probability Distribution

For $\rho = 0.8$:

| n | $P_n$ |
|---|-------|
| 0 | 0.20 (20% idle) |
| 1 | 0.16 |
| 2 | 0.128 |
| 3 | 0.102 |
| 5 | 0.066 |
| 10 | 0.021 |

## 5. Connection to Little's Law

These metrics are linked by **Little's Law**:

$$L = \lambda W$$
$$L_Q = \lambda W_Q$$

The average number of items in a stationary system equals the average arrival rate multiplied by the average time spent in the system.

## Summary

```
        ┌─────────────────────────────────────┐
        │           M/M/1 Queue               │
        │                                     │
   λ →  │  [Wait Queue L_Q]  →  [Server]  →   │  → μ
        │       W_Q                1/μ        │
        │                                     │
        │  ←──────── System (L, W) ────────→  │
        └─────────────────────────────────────┘

Key insight: As ρ → 1, wait times explode (L → ∞)
```
