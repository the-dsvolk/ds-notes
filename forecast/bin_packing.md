# Bin Packing vs Multiple Knapsack

Two related but fundamentally different optimization problems for resource allocation.

## Problem Comparison

| Aspect | Multiple Knapsack | Bin Packing |
|--------|-------------------|-------------|
| **Objective** | Maximize total value | Minimize number of bins |
| **Bins** | Fixed number, varying capacities | As many as needed, common capacity |
| **Items** | Have weights AND values | Have weights only |
| **Constraint** | Pack a subset of items | Pack ALL items |
| **Question** | "What's the most valuable selection?" | "What's the fewest bins needed?" |

## Multiple Knapsack Problem

**Goal:** Pack a *subset* of items into a *fixed number* of bins (with varying capacities) to **maximize total value**.

```
Bins (fixed):           Items (select subset):
┌─────────┐             ○ Item A: weight=5, value=$100
│ Bin 1   │ cap=10      ○ Item B: weight=3, value=$60
└─────────┘             ○ Item C: weight=8, value=$120
┌───────────────┐       ○ Item D: weight=2, value=$30
│ Bin 2         │ cap=15
└───────────────┘

Question: Which items to pack to maximize $$$?
(Some items may be left out)
```

**Use case:** You have limited resources (VMs, GPUs) and must choose which jobs to run to maximize business value.

## Bin Packing Problem

**Goal:** Pack *all* items into the **fewest bins** possible (bins have common capacity).

```
Items (must pack ALL):      Bins (as many as needed):
○ Item A: weight=48         ┌─────────┐
○ Item B: weight=30         │ Bin ?   │ cap=100
○ Item C: weight=19         └─────────┘
○ Item D: weight=36         ┌─────────┐
○ Item E: weight=36         │ Bin ?   │ cap=100
○ Item F: weight=27         └─────────┘
                            ┌─────────┐
                            │ Bin ?   │ cap=100
                            └─────────┘
                            ... (minimize this count)

Question: What's the minimum number of bins?
(All items must be packed)
```

**Use case:** You must run all jobs—how many VMs do you need to provision?

## When to Use Each

| Scenario | Problem Type |
|----------|--------------|
| Fixed budget, prioritize high-value work | Multiple Knapsack |
| Must complete all work, minimize cost | Bin Packing |
| CapEx planning: "How many GPUs do we need?" | Bin Packing |
| Resource allocation: "Which jobs to run now?" | Multiple Knapsack |

## References

- [Google OR-Tools: Bin Packing Problem](https://developers.google.com/optimization/pack/bin_packing)
