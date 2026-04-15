# Phase 15 — Decryption Optimization

## Weeks 30–34 | 7 Work Units | ~22 Hours

*Part of the [Orbcrypt Practical Improvements Plan](../../formalization/PRACTICAL_IMPROVEMENTS_PLAN.md)*

---

## Overview

Phase 15 reduces decryption cost from O(n^c) with c approximately 3-5 (full
partition backtracking) to a fast path exploiting QC code structure. This is
the key engineering challenge for practical competitiveness.

The full partition-backtracking canonical form computation is the dominant
cost in Orbcrypt decryption. For large parameters (n >= 512), this cost
makes the scheme impractical compared to lattice-based and code-based KEM
competitors. This phase develops multiple optimization strategies and
benchmarks them to identify the best practical approach.

---

## Core Insight

The automorphism group of a QC code contains a large, known, structured
subgroup: the cyclic-shift group (Z/bZ)^ell. Decryption can decompose
into two phases:

1. **Fast phase:** Reduce modulo the known cyclic structure (O(n) operations).
2. **Residual phase:** Resolve ambiguity from "accidental" automorphisms
   (much smaller group, cheaper backtracking).

This decomposition dramatically reduces the effective backtracking search
space. Where the full group may have order |G| = b^ell * |G_residual|,
the residual group |G_residual| is typically orders of magnitude smaller,
yielding a correspondingly faster decryption.

---

## Objectives

1. Implement fast cyclic reduction that canonicalizes the known
   (Z/bZ)^ell subgroup in O(n) time.
2. Compute and cache the residual group G_residual = PAut(C) / (Z/bZ)^ell
   during key generation.
3. Combine both phases into a complete fast decryption path and validate
   against the slow (full backtracking) path.
4. Explore syndrome-based and probabilistic orbit-hash alternatives.
5. Formalize the two-phase decomposition correctness in Lean 4.
6. Benchmark all methods and identify the optimal decryption strategy.

---

## Prerequisites

- **Phase 11** complete (QC code construction, PAut computation, GAP
  infrastructure for partition backtracking).
- **Phase 14** complete (parameter selection — needed to determine the
  concrete block size b and block count ell for benchmarking).

---

## New Files

```
Orbcrypt/
  Optimization/
    QCCanonical.lean     — QC-structured canonical form (Lean specification)
    TwoPhaseDecrypt.lean — Two-phase decryption specification
implementation/
  gap/
    orbcrypt_fast_dec.g  — Fast decryption implementation in GAP
```

---

## Work Units

### 15.1 — QC Cyclic Reduction

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_fast_dec.g` | **Deps:** Phase 11

Implement the core cyclic-reduction subroutine that exploits the known
(Z/bZ)^ell subgroup structure of QC codes. This is the "fast phase" of
the two-phase decryption approach.

**Sub-tasks:**

#### 15.1a — MinimalBlockRotation helper (1.5h)

Implement the core subroutine that finds the lexicographically minimal
cyclic rotation of a single block of b bits:

```gap
MinimalBlockRotation := function(x, b, blockIndex)
  # Extract block: x[(blockIndex-1)*b+1 .. blockIndex*b]
  # Try all b cyclic rotations, find lex-minimum
  # Return x with that block replaced by its minimum rotation
end;
```

This is O(b^2) per block but since b=8 is constant, it's O(1) per block.

**Exit criteria:** Function works for b=8, returns correct minimal rotation.

---

#### 15.1b — Full QCCyclicReduce (1h)

Compose MinimalBlockRotation over all ell blocks:

```gap
QCCyclicReduce := function(x, b, ell)
  local best, i;
  best := ShallowCopy(x);
  for i in [1..ell] do
    best := MinimalBlockRotation(best, b, i);
  od;
  return best;
end;
```

**Exit criteria:** Function produces consistent results (same input always
gives same output). Verify: applying any cyclic shift to the output then
re-reducing gives the same result (idempotence).

---

#### 15.1c — Correctness validation (1.5h)

Test against full canonical image computation:

- For 100 random bitstrings, verify that `QCCyclicReduce(g . x)` =
  `QCCyclicReduce(h . x)` whenever g and h differ only by cyclic shifts.
- Benchmark O(n) scaling: time QCCyclicReduce for n in {100, 200, 500, 1000}
  and verify linear growth.

**Exit criteria:** 100% consistency; timing confirms O(n).

---

**Phase 15.1 exit criteria:** All three sub-tasks (15.1a, 15.1b, 15.1c) pass.

---

### 15.2 — Residual Group Computation

**Effort:** 3h | **File:** `implementation/gap/orbcrypt_fast_dec.g` | **Deps:** 15.1, 11.2

After cyclic reduction, the residual group is:

```
G_residual = PAut(C) / (Z/bZ)^ell
```

This quotient group is typically much smaller than PAut(C). Compute it
during key generation and store it as part of the secret key:

```gap
ComputeResidualGroup := function(G, b, ell)
  local cyclicSubgroup, residual;
  cyclicSubgroup := QCCyclicSubgroup(b, ell);
  # G_residual represents automorphisms beyond the cyclic structure
  residual := RightTransversal(G, cyclicSubgroup);
  return residual;
end;
```

**Exit criteria:** Residual group is computed correctly. Its size is
measured and reported (expected: much smaller than |G|).

---

### 15.3 — Two-Phase Decryption

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_fast_dec.g` | **Deps:** 15.1, 15.2

Combine the two phases into a complete fast decryption:

```gap
FastDecaps := function(sk, c)
  local phase1, phase2, canon;
  # Phase 1: Fast cyclic reduction (O(n))
  phase1 := QCCyclicReduce(c, sk.b, sk.ell);
  # Phase 2: Residual backtracking (O(n^c') with c' << c)
  phase2 := CanonicalImage(sk.residualGroup, phase1);
  # The result is the full canonical form
  canon := phase2;
  return sk.keyDerive(canon);
end;
```

Validate: `FastDecaps(sk, c) = SlowDecaps(sk, c)` for all test cases.

**Exit criteria:** Fast and slow decryption produce identical results
for 10,000 test cases. Speed improvement is measured and reported.

---

### 15.4 — Syndrome-Based Orbit Identification

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_fast_dec.g` | **Deps:** 11.2

Explore an alternative fast decryption path using syndrome computation:

```gap
# The secret code C has a parity-check matrix H.
# The syndrome of c is s = H * c^T.
# If c = g . x_0 for g in PAut(C), then:
#   s = H * (g . x_0)^T = (H * P_g) * x_0^T
# where P_g is the permutation matrix of g.
# Since g in PAut(C), P_g preserves C, so H * P_g = H * P_g.
# The syndrome therefore depends only on the ORBIT of c.

SyndromeDecaps := function(sk, c)
  local syndrome, key;
  syndrome := sk.H * c;  # Matrix-vector multiply: O(n*k) = O(n^2)
  key := sk.keyDerive(syndrome);
  return key;
end;
```

**Caveat:** This only works if the syndrome uniquely identifies the orbit.
For the KEM (single base point), uniqueness is guaranteed if the parity-check
matrix H is chosen correctly. For the general scheme (multiple representatives),
uniqueness requires that different orbits produce different syndromes.

**Exit criteria:** Syndrome-based decryption is tested. Its correctness
and speed are compared to partition backtracking.

---

### 15.5 — Lean Specification of Two-Phase Decryption

**Effort:** 3h | **File:** `Optimization/TwoPhaseDecrypt.lean` | **Deps:** 15.3, Phase 5

Formalize the correctness of two-phase decryption in Lean:

```lean
/-- Two-phase decryption is correct if the cyclic reduction followed by
    residual canonicalization equals the full canonical form. -/
theorem two_phase_correct
    (G : Subgroup (Equiv.Perm (Fin n)))
    (C : Subgroup G)  -- cyclic subgroup
    (can_full : CanonicalForm G (Bitstring n))
    (can_cyclic : CanonicalForm C (Bitstring n))
    (can_residual : CanonicalForm (G / C) (Bitstring n)) -- quotient
    (hDecomp : ∀ x, can_full.canon x =
      can_residual.canon (can_cyclic.canon x)) :
    ∀ g : G, ∀ x : Bitstring n,
      can_full.canon (g • x) = can_residual.canon (can_cyclic.canon (g • x)) :=
  fun g x => hDecomp (g • x)
```

**Exit criteria:** Specification compiles. The decomposition hypothesis
`hDecomp` is clearly documented as the key correctness requirement.

---

### 15.6 — Orbit Hash Function (Probabilistic Canonical Form)

**Effort:** 2h | **File:** `implementation/gap/orbcrypt_fast_dec.g` | **Deps:** 11.3

Implement a probabilistic orbit hash as an alternative to exact canonical forms:

```gap
OrbitHash := function(G, x, nSamples)
  local samples, sorted, hash;
  # Sample nSamples elements of the orbit
  samples := List([1..nSamples], i -> Image(PseudoRandom(G), x));
  # Sort them lexicographically
  sorted := SortedList(samples);
  # Hash the sorted list
  hash := SHA256(Concatenation(List(sorted, String)));
  return hash;
end;
```

This gives O(nSamples * n) decryption instead of O(n^c) backtracking.
The trade-off: probabilistic correctness (hash collisions between different
orbits, negligible for large nSamples).

**Exit criteria:** Orbit hash produces consistent results across calls.
Collision rate is measured empirically.

---

### 15.7 — Decryption Speed Comparison

**Effort:** 2h | **File:** `implementation/gap/orbcrypt_bench.g` | **Deps:** 15.1–15.6

Benchmark all decryption methods and produce a comparison:

| Method | Time (lambda=128) | Correctness | Notes |
|--------|-------------------|-------------|-------|
| Full partition backtracking | Baseline | Exact | O(n^c) |
| Two-phase (cyclic + residual) | ? | Exact | O(n + n'^c') |
| Syndrome-based | ? | Exact (if valid) | O(n^2) |
| Orbit hash (100 samples) | ? | Probabilistic | O(100n) |
| Orbit hash (1000 samples) | ? | Probabilistic | O(1000n) |

**Exit criteria:** Comparison table filled with measured timings.
Best method identified and documented.

---

## Internal Dependency Graph

```
Phase 11 (QC Construction)
  |
  +---> 15.1 (QC Cyclic Reduction)
  |       |
  |       +---> 15.2 (Residual Group Computation)
  |       |       |
  |       |       +---> 15.3 (Two-Phase Decryption)
  |       |               |
  |       |               +---> 15.5 (Lean Specification) <--- Phase 5
  |       |
  |       +---> 15.7 (Speed Comparison) <--- 15.1–15.6
  |
  +---> 15.4 (Syndrome-Based Identification)
  |       |
  |       +---> 15.7
  |
  +---> 15.6 (Orbit Hash Function)
          |
          +---> 15.7
```

**Critical path:** 15.1 -> 15.2 -> 15.3 -> 15.5 (15 hours sequential).
Units 15.4 and 15.6 can run in parallel with the critical path.

---

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Residual group not significantly smaller than full group for some codes | Medium | High | Test across multiple QC code families; if residual is large, syndrome-based approach may be better |
| Syndrome does not uniquely identify orbits in multi-representative scheme | Medium | Medium | Validate uniqueness empirically; fall back to two-phase for non-unique cases |
| Orbit hash collisions at practical sample sizes | Low | High | Increase nSamples; formal analysis of collision probability |
| Lean formalization of quotient group action is technically complex | Medium | Low | Use `sorry` for quotient action boilerplate if needed; focus on the decomposition theorem statement |
| GAP performance overhead masks true algorithm scaling | Low | Medium | Profile GAP overhead separately; consider C implementation for final benchmarks |
| Two-phase approach does not compose correctly for all group structures | Low | High | Extensive testing against full backtracking (10,000 cases in 15.3); formal specification in 15.5 |

---

## Phase Exit Criteria

1. **Fast cyclic reduction** (15.1): `QCCyclicReduce` is implemented, tested
   for idempotence, and confirmed O(n) scaling.
2. **Residual group** (15.2): Computed and measured; documented size ratio
   |G_residual| / |G| for target parameters.
3. **Two-phase decryption** (15.3): `FastDecaps` matches `SlowDecaps` on
   10,000 test cases with measured speedup.
4. **Syndrome path** (15.4): Tested and compared; correctness conditions
   documented.
5. **Lean specification** (15.5): `two_phase_correct` compiles with zero
   `sorry` (the decomposition hypothesis is a parameter, not proved).
6. **Orbit hash** (15.6): Implemented with measured collision rate.
7. **Benchmark table** (15.7): All five methods benchmarked at lambda=128;
   best method identified and recommended.

---

## Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 15.1 | QC Cyclic Reduction | GAP | 4h | Phase 11 |
| 15.2 | Residual Group Computation | GAP | 3h | 15.1, 11.2 |
| 15.3 | Two-Phase Decryption | GAP | 4h | 15.1, 15.2 |
| 15.4 | Syndrome-Based Identification | GAP | 4h | 11.2 |
| 15.5 | Lean Specification | `Optimization/TwoPhaseDecrypt.lean` | 3h | 15.3, Phase 5 |
| 15.6 | Orbit Hash Function | GAP | 2h | 11.3 |
| 15.7 | Speed Comparison | GAP | 2h | 15.1–15.6 |

### Decryption Speed Comparison (to be filled by 15.7)

| Method | Time (lambda=128) | Correctness | Notes |
|--------|-------------------|-------------|-------|
| Full partition backtracking | Baseline | Exact | O(n^c) |
| Two-phase (cyclic + residual) | ? | Exact | O(n + n'^c') |
| Syndrome-based | ? | Exact (if valid) | O(n^2) |
| Orbit hash (100 samples) | ? | Probabilistic | O(100n) |
| Orbit hash (1000 samples) | ? | Probabilistic | O(1000n) |
