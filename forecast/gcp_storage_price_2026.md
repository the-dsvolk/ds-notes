
# GCP Cloud Storage Pricing

## Units

GCP uses **binary units** (IEC standard):

| Unit | Definition | Bytes |
|------|------------|-------|
| GiB (gibibyte) | 2³⁰ | 1,073,741,824 |
| TiB (tebibyte) | 2⁴⁰ | 1,099,511,627,776 |

Note: 1 TiB = 1,024 GiB (not 1,000 like decimal TB/GB).

## Storage Classes

Prices are billed **hourly** but shown as monthly equivalents (≈730 hours/month).

### Single Region (e.g., us-central1)

| Storage Class | $/GiB/month | 100 TiB/month |
|---------------|-------------|---------------|
| Standard | $0.02 | ~$2,048 |
| Nearline | $0.01 | ~$1,024 |
| Coldline | $0.004 | ~$410 |
| Archive | $0.0012 | ~$123 |

### Multi-region (US, EU, Asia)

| Storage Class | $/GiB/month |
|---------------|-------------|
| Standard | $0.026 |
| Nearline | $0.015 |
| Coldline | $0.007 |
| Archive | $0.003 |

**Minimum storage duration** applies: Nearline (30 days), Coldline (90 days), Archive (365 days).

## Operations

| Class | Examples | Standard Storage (per 1,000 ops) |
|-------|----------|----------------------------------|
| **A** | insert, list, copy, compose | $0.005 |
| **B** | get, getIamPolicy | $0.0004 |
| **Free** | delete | $0 |

**Example**: Reading 1 million objects from Standard storage costs $0.40 (Class B operations).

## Retrieval Fees

A retrieval fee applies when you read, copy, move, or rewrite data from cold storage classes. This is **in addition to** operations and network charges.

| Storage Class | Retrieval Fee |
|---------------|---------------|
| Standard | $0 |
| Nearline | $0.01/GiB |
| Coldline | $0.02/GiB |
| Archive | $0.05/GiB |

**Note**: Retrieval fees do **not** apply when Autoclass is enabled.

## Data Transfer

- **Same region** (e.g., VM ↔ bucket in us-central1): **Free**
- **Cross-region** (within GCP): $0.02–$0.08/GiB
- **Egress to internet**: $0.12/GiB (first 10 TiB)

## Reference

- [Cloud Storage Pricing](https://cloud.google.com/storage/pricing)
