# Phase 14 — Parameter Selection & Benchmarks

## Weeks 28–31 | 6 Work Units | ~20 Hours

*Part of the [Orbcrypt Practical Improvements Plan](../../formalization/PRACTICAL_IMPROVEMENTS_PLAN.md)*

---

## Overview

Phase 14 produces concrete parameter tables for multiple security levels,
generates comparison data against existing schemes, and publishes a parameter
recommendation document. This phase transforms GAP benchmark data (Phase 11)
into actionable parameter guidance.

---

## Objectives

1. Systematically explore the parameter space (block size, weight, code rate).
2. Identify optimal parameter configurations for each security level.
3. Build a definitive comparison table against AES, Kyber, BIKE, HQC.
4. Analyze security margins against all known attack vectors.
5. Analyze ciphertext expansion and compute break-even message lengths.
6. Produce conservative, balanced, and aggressive parameter recommendations.

---

## Prerequisites

- Phase 11 complete (GAP prototype with working benchmarks)

---

## New Files

```
docs/
  PARAMETERS.md          — Parameter recommendation document
  benchmarks/
    results_80.csv       — Benchmark data for lambda=80
    results_128.csv      — Benchmark data for lambda=128
    results_192.csv      — Benchmark data for lambda=192
    results_256.csv      — Benchmark data for lambda=256
    comparison.csv       — Cross-scheme comparison
```

---

## Work Units

#### 14.1 — Parameter Space Exploration

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_params.g` | **Deps:** Phase 11

Systematically explore the parameter space. For each security level, vary:
- Block size b in {4, 8, 16, 32}
- Index ell (derived from b and lambda)
- Target weight w in {n/3, n/2, 2n/3}
- Code rate k/n in {1/4, 1/3, 1/2}

For each configuration, measure:
- Actual |PAut(C)| (meets 2^lambda threshold?)
- Number of distinct orbits at target weight
- Key generation time
- Canonical image computation time (proxy for decryption)

Output: CSV with all configurations and measurements.

**Exit criteria:** Sweep completes for lambda=128 with >= 16 configs tested.

---

#### 14.2 — Optimal Parameter Selection

**Effort:** 3h | **File:** `docs/PARAMETERS.md` | **Deps:** 14.1

Optimization targets (priority order):
1. **Security:** |PAut(C)| >= 2^lambda (hard constraint)
2. **Decryption speed:** Minimize canonical image computation time
3. **Ciphertext size:** Minimize n
4. **Key size:** Minimize seed representation

Produce recommended parameter set for each level:

| Level | Lambda | n | b | ell | k | w | \|G\| (log2) | CT size | Dec time |
|-------|--------|---|---|-----|---|---|-------------|---------|----------|
| L1 | 80 | ? | ? | ? | ? | ? | >= 80 | ? bits | ? ms |
| L3 | 128 | ? | ? | ? | ? | ? | >= 128 | ? bits | ? ms |
| L5 | 192 | ? | ? | ? | ? | ? | >= 192 | ? bits | ? ms |
| L7 | 256 | ? | ? | ? | ? | ? | >= 256 | ? bits | ? ms |

**Exit criteria:** Table with concrete numbers for all four levels.

---

#### 14.3 — Comparison Against Existing Schemes

**Effort:** 4h | **File:** `docs/PARAMETERS.md` | **Deps:** 14.2, 11.7

| Metric | AES-256 | Kyber-768 | BIKE-L3 | HQC-256 | **HGOE-128** |
|--------|---------|-----------|---------|---------|-------------|
| Type | Sym | KEM | KEM | KEM | **KEM** |
| Key (bytes) | 32 | 2400 | 3114 | 7245 | **32** (seed) |
| CT (bytes) | 16+tag | 1088 | 3114 | 14469 | **n/8** |
| Enc (ops) | ~100 | ~30K | ~100K | ~300K | **?** |
| Dec (ops) | ~100 | ~25K | ~200K | ~500K | **?** |
| PQ secure? | No | Yes | Yes | Yes | **Conjectured** |
| Assumption | None | MLWE | QC-MDPC | QC-HQC | **CE-OIA** |

**Exit criteria:** All cells filled. Honest assessment paragraph per metric.

---

#### 14.4 — Security Margin Analysis

**Effort:** 3h | **File:** `docs/PARAMETERS.md` | **Deps:** 14.2

For each parameter set analyze:

- **Brute-force orbit enumeration:** Cost = |orbit| = |G| / |Stab|.
  For |G| >= 2^lambda and |Stab| = 1, cost = 2^lambda.
- **Birthday attack on orbits:** Cost = sqrt(|G|). For lambda=128 with
  |G| >= 2^128, birthday cost is only 2^64. **Important:** to achieve
  128-bit birthday resistance, we need |G| >= 2^256 (so sqrt = 2^128).
  The recommended minimum is therefore log2(|G|) >= 2*lambda for full
  birthday resistance, or document that birthday security is lambda/2
  bits when log2(|G|) = lambda.
- **Babai's GI algorithm:** Cost = 2^O(sqrt(n log n)) where n is the
  number of vertices in the underlying graph (for GI-OIA). Compute for
  each parameter set.
- **Algebraic attacks on QC structure:** Effective dimension after folding
  = n/b. Must ensure effective dim >= lambda for security. For b=8 and
  lambda=128, need n >= 1024 (effective dim = 128). For b=32, need
  n >= 4096.

**Exit criteria:** Security margin table with bit-security estimates
for each attack vector. Birthday resistance level explicitly stated.

---

#### 14.5 — Ciphertext Expansion Analysis

**Effort:** 3h | **File:** `docs/PARAMETERS.md` | **Deps:** 14.2

- KEM mode: ciphertext = n bits
- Hybrid (KEM+DEM): n bits + |message| + tag
- vs AES-GCM: |message| + 128 bits (tag) + 96 bits (IV)

Compute break-even message length where Orbcrypt total equals AES-GCM total.

**Exit criteria:** Break-even analysis with concrete numbers.

---

#### 14.6 — Parameter Recommendation Summary

**Effort:** 3h | **File:** `docs/PARAMETERS.md` | **Deps:** 14.1–14.5

Three recommendation tiers per security level:
1. **Conservative:** Optimized for security margin.
2. **Balanced:** Best security/performance trade-off (default).
3. **Aggressive:** Optimized for performance.
4. **Not recommended:** Failed configurations with explanations.

**Exit criteria:** Three concrete parameter sets per security level.

---

## Internal Dependency Graph

```
14.1 (Sweep) → 14.2 (Optimal) → 14.3 (Comparison)
                    |          → 14.4 (Security Margin)
                    |          → 14.5 (Expansion)
                    └──────────→ 14.6 (Recommendation)
```

---

## Go/No-Go Decision Point

After Phase 14: If ciphertext expansion exceeds 100x compared to AES-GCM
for typical message sizes, narrow scope to KEM-only operation.

---

## Phase Exit Criteria

1. Parameter sweep CSV generated for all four security levels.
2. `docs/PARAMETERS.md` contains recommended parameters, comparison table,
   security margins, expansion analysis, and tier recommendations.
3. All benchmark data is reproducible from Phase 11 GAP scripts.

---

## Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 14.1 | Parameter Space Exploration | GAP scripts | 4h | Phase 11 |
| 14.2 | Optimal Parameter Selection | `docs/PARAMETERS.md` | 3h | 14.1 |
| 14.3 | Scheme Comparison | `docs/PARAMETERS.md` | 4h | 14.2, 11.7 |
| 14.4 | Security Margin Analysis | `docs/PARAMETERS.md` | 3h | 14.2 |
| 14.5 | Ciphertext Expansion | `docs/PARAMETERS.md` | 3h | 14.2 |
| 14.6 | Parameter Recommendation | `docs/PARAMETERS.md` | 3h | 14.1–14.5 |
