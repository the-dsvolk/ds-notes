# CapEx Analysis for GPU Clusters

CapEx (Capital Expenditure) budget for a GPU cluster requires translating "compute power" into a financial metric that leadership understands. While Return on Assets (ROA) is traditionally a net income ratio, in the context of R&D and Infrastructure, we use **Synthetic ROA** or **Internal Rate of Return (IRR)**.

You are essentially proving that the value created by these GPUs is significantly higher than the cost of the hardware and its depreciation.

## 1. The Core ROA Formula

In a standard business context:

$$ROA = \frac{\text{Net Income}}{\text{Total Assets}}$$

For a GPU cluster, we redefine the components:

$$ROA_{\text{cluster}} = \frac{\text{Value of Work Produced} - \text{Operating Costs}}{\text{Initial CapEx + Depreciation}}$$

## 2. Step-by-Step Calculation for a Budget Request

### Step A: Calculate the Asset Value (The Denominator)

This is your CapEx. It's not just the price of the GPUs, but the **Total Cost of Ownership (TCO)** over their useful life (usually 3 years).

| Component      | Cost          |
|----------------|---------------|
| Hardware       | 1,000 GPUs × $30,000 = **$30M** |
| Infrastructure | Racks, networking, cooling = **$5M** |
| **Total Asset Value** | **$35M** |

### Step B: ROA Calculation Example

| Metric | Year 1 Value | Notes |
|--------|--------------|-------|
| Asset Value (CapEx) | $35,000,000 | Hardware + Setup |
| Synthetic Income | $28,000,000 | Based on $4/hr Cloud Equivalence |
| Operating Costs | ($3,000,000) | Power, Cooling, Staff |
| Net Value Created | $25,000,000 | Income - OpEx |
| **Annual ROA** | **71.4%** | $25M / $35M |

## 3. Addressing Resource Contention

When data shows that SLA for safety-critical workloads is being compromised by resource contention, there are two strategies to consider:

### Option A: CapEx Investment

Buy additional GPUs (e.g., 500 more) to lower the baseline utilization. This approach is appropriate when:
- Contention is persistent and widespread
- Current utilization consistently exceeds 80-90%
- Growth projections justify long-term hardware investment

### Option B: Scheduling Logic Change

Implement a **Preemption Scheduler** that evicts lower-priority jobs (e.g., Priority 3) when higher-priority jobs (e.g., Priority 1) enter the queue. This approach is appropriate when:
- Contention is periodic rather than constant
- Priority 1 jobs represent a small fraction of total workload
- Analysis shows preemption would recover sufficient compute hours

SQL-based analysis can quantify the impact of each strategy—for example, showing that preemption would have saved X-thousand hours of safety-critical testing time without purchasing additional hardware.

## 4. CapEx (On-Prem) vs Cloud: 3-Year Comparison

| Year | Demand (GPUs) | On-Premise (CapEx + OpEx) | Cloud (OpEx Only) |
|------|---------------|---------------------------|-------------------|
| Year 1 | 1,000 | **$56,000,000** | **$15,768,000** |
| | | $50M Buy + $6M Power/Maint | 1k GPUs @ $1.80/hr |
| Year 2 | 1,200 | **$17,200,000** | **$18,921,600** |
| | | $10M New Buy + $7.2M Power/Maint | 1.2k GPUs @ $1.80/hr |
| Year 3 | 1,440 | **$20,640,000** | **$22,705,920** |
| | | $12M New Buy + $8.6M Power/Maint | 1.44k GPUs @ $1.80/hr |
| **TOTAL** | — | **$93,840,000** | **$57,395,520** |

### Key Observations

- **Year 1:** Cloud is ~72% cheaper (no upfront CapEx)
- **Years 2-3:** On-prem becomes competitive as infrastructure is amortized
- **Break-even:** On-prem requires ~5+ years at stable demand to match cloud TCO

### Assumptions

| Parameter | On-Premise | Cloud |
|-----------|------------|-------|
| **Cost per GPU** | $50,000 (H100-class) | $1.80/hr (~$15,768/yr) |
| **Infrastructure** | 20% of GPU cost (racks, networking, cooling) | Included in hourly rate |
| **Power & Maintenance** | ~$6,000/GPU/year | Included in hourly rate |
| **Utilization** | 100% (always on) | 100% (24/7 usage assumed) |
| **Depreciation** | 3-year straight-line | N/A |
| **Demand growth** | 20% YoY | 20% YoY |

> **Note:** This comparison assumes 24/7 usage. Cloud becomes more attractive with variable/bursty workloads where you only pay for actual usage. On-prem wins for sustained, predictable high-utilization workloads over 3+ years.
