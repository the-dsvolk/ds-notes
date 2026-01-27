# Queueing Theory

Queueing theory principles apply to compute cluster architectures, with specific limitations and recommendations for each.

## 1. Little's Law

**The Principle:**

$$L = \lambda W$$

- $L$ = average number of jobs in the system
- $\lambda$ = average arrival rate
- $W$ = average time a job spends in the system (wait time + execution time)

**Application:** This is your "sanity check" tool. If you receive 100 jobs/hour and each job takes 2 hours on average, you will always have an average of 200 jobs in the system.

**Limitation:** It only deals with averages. It won't tell you how big your "bursts" are or how long the maximum wait time is. It assumes the system is in a steady state (not crashing or overloaded).

**Relevance:** High. Use this to determine if your VM capacity is even theoretically capable of handling your long-term average load.

## 2. Kingman's Formula (The VUT Equation)

**The Principle:** This formula estimates the Waiting Time ($W_q$) in a queue:

$$W_q \approx \left( \frac{\rho}{1 - \rho} \right) \left( \frac{C_a^2 + C_s^2}{2} \right) \tau$$

Where:
- $\rho$ = utilization
- $C_a$ = arrival variability (coefficient of variation)
- $C_s$ = service variability
- $\tau$ = average service time

**Application:** This is the most important formula for "bursty" traffic. It shows that wait times don't grow linearly; they **explode** as utilization ($\rho$) approaches 100% or as variability ($C_a$) increases.

**Limitation:** The basic formula is an approximation for a single-server queue ($G/G/1$).

### Multi-Server Extension (G/G/s)

For systems with $s$ parallel servers (e.g., VMs), replace the utilization term with the **Magnifying Effect**:

$$\text{Magnifying Effect} = \frac{U^{\sqrt{2(s+1)}-1}}{s(1 - U)}$$

Where:
- $U$ = utilization (0 to 1)
- $s$ = number of parallel servers (VMs)
- The exponent $\sqrt{2(s+1)}-1$ adjusts the "sharpness" of queue growth based on server count

The full multi-server VUT equation becomes:

$$W_q \approx \left( \frac{U^{\sqrt{2(s+1)}-1}}{s(1 - U)} \right) \left( \frac{C_a^2 + C_s^2}{2} \right) \tau$$

> **Note:** As $s \to 1$, this reduces to the standard $G/G/1$ formula. With more servers, the system tolerates higher utilization before wait times explode.

**Relevance:** Critical. It explains why "burstiness" is killing your performance.

## 3. Erlang-C

**The Principle:** Used to calculate the probability that an arriving job will have to wait in a queue, assuming a steady arrival rate (Poisson) and multiple servers.

**Application:** Helps calculate the probability of a "buffer overflow" or how many jobs will be stuck in the queue at any given time.

**Limitation:** Erlang-C assumes random (Poisson) arrivals. Bursty traffic is usually "non-Poisson"—it has higher variance than Erlang-C expects. If you use Erlang-C for bursty GPU jobs, you will **significantly underestimate** the wait times.

**Relevance:** Low-to-Medium. It's too "optimistic" for bursty workloads.

## 4. Square-Root Staffing Rule

**The Principle:** To maintain a certain level of service, the number of "extra" servers (capacity) you need over the average load should be proportional to the square root of the average load.

$$\text{Capacity} = \text{Average Load} + \beta\sqrt{\text{Average Load}}$$

Where $\beta$ is a safety factor (typically 1-2 for 95-99% service levels).

**Application:** For a 1,000 VM cluster, this suggests how much "buffer" you need to handle fluctuations.

**Limitation:** This rule works best when you have a massive number of small, independent jobs. Because GPU jobs often use multiple VMs (gang scheduling), one job might require 8 or 16 VMs at once. This "bulk" requirement breaks the standard Square-Root math.

**Relevance:** Medium. It's a good rule of thumb for "safety capacity" but needs adjustment for multi-node jobs.
