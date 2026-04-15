# Phase 11 — Reference Implementation (GAP Prototype)

## Weeks 21–26 | 9 Work Units | ~36 Hours

*Part of the [Orbcrypt Practical Improvements Plan](../../formalization/PRACTICAL_IMPROVEMENTS_PLAN.md)*

---

## Overview

Phase 11 builds an executable reference implementation in GAP (Groups,
Algorithms, Programming) to validate practical viability and produce real
benchmarks. GAP is the natural choice: it has built-in Schreier-Sims,
partition backtracking, canonical images, and native permutation group
support. This prototype translates the formally verified Lean definitions
into runnable code, enabling the first empirical measurements of key
generation, encapsulation, and decapsulation performance across multiple
security levels.

The implementation lives entirely outside the Lean build system in a
separate `implementation/` directory. All files are `.g` (GAP language),
not `.lean`. The Lean formalization remains the source of truth for
correctness and security properties; the GAP prototype provides empirical
data that informs subsequent optimization phases (Phases 14–15).

---

## Why GAP

| Language | Pros | Cons |
|----------|------|------|
| **GAP** | Native permutation groups, canonical images via `images` package, Schreier-Sims built-in | Slow for bit-level operations, limited crypto libraries |
| Python/SageMath | Good ecosystem, `permutation_group` in Sage | Sage's perm group is slower than GAP's C kernel |
| Rust/C++ | Fast execution | Must implement Schreier-Sims and partition backtracking from scratch |
| Magma | Excellent computational algebra | Commercial, not open-source |

GAP provides the fastest path to working benchmarks. Performance-critical
reimplementation in Rust/C++ can follow if benchmarks are promising.

---

## Objectives

1. Install and configure GAP 4.12+ with required packages (`images`, `GUAVA`, `IO`).
2. Implement the complete 7-stage HGOE key generation pipeline from DEVELOPMENT.md Section 6.2.1.
3. Implement KEM encapsulation and decapsulation with round-trip correctness.
4. Build a comprehensive correctness test suite covering orbit membership, weight preservation, canonical form consistency, and distinct orbits.
5. Build a benchmark harness producing structured CSV output with timing breakdowns.
6. Generate and validate parameter sets for security levels lambda in {80, 128, 192, 256}.
7. Collect comparison data against existing schemes (AES-256-GCM, Kyber-768, BIKE-L3, HQC-256).
8. Empirically verify the invariant attack and Hamming weight defense.
9. Write reproducibility documentation enabling fresh installations to replicate all results.

---

## Prerequisites

- **Phase 7 complete** (KEM Reformulation) — the GAP prototype implements the KEM interface (`encaps`/`decaps`) defined in Phase 7, not the original `OrbitEncScheme` encrypt/decrypt. The single-base-point KEM architecture from Phase 7 determines the prototype's API.
- **Phase 2 complete** (`CanonicalForm` — the GAP `CanonicalImage` function mirrors the Lean canonical form definition).
- **Phase 5 complete** (HGOE construction — the GAP prototype instantiates the same S_n action on bitstrings with Hamming weight defense).

---

## New Files

```
implementation/
  gap/
    orbcrypt_kem.g       -- KEM encapsulation/decapsulation
    orbcrypt_keygen.g    -- Key generation (QC code, PAut, SGS)
    orbcrypt_bench.g     -- Benchmark harness
    orbcrypt_test.g      -- Correctness test suite
    orbcrypt_params.g    -- Parameter generation for multiple security levels
  README.md              -- Installation, usage, and reproducibility guide
```

**Note:** These are `.g` files (GAP language), not `.lean` files. They live
outside the Lean build system in a separate `implementation/` directory.

---

## Work Units

### 11.1 — GAP Environment Setup

**Effort:** 2h | **File:** `implementation/gap/README.md` | **Deps:** None

Install GAP 4.12+ with the `images` package (Christopher Jefferson's
canonical image library). Document installation steps, required packages,
and version pins.

Required GAP packages:
- `images` — canonical image computation for permutation groups
- `GUAVA` — error-correcting code support (for QC code generation)
- `IO` — file I/O for benchmark output

**Exit criteria:** `gap --version` reports 4.12+. `LoadPackage("images")`
succeeds. A trivial test (canonical image of a 4-element permutation group)
runs correctly.

---

### 11.2 — Permutation Group Key Generation

**Effort:** 5h | **File:** `implementation/gap/orbcrypt_keygen.g` | **Deps:** 11.1

Implement the 7-stage HGOE key generation pipeline from DEVELOPMENT.md
Section 6.2.1.

**Sub-tasks:**

**11.2a — Stage 1: Parameter derivation (0.5h).** Implement:
```gap
HGOEParams := function(lambda)
  local b, ell, n, k, w;
  b := 8; ell := Int(Ceil(lambda / Log2(b)));
  n := b * ell; k := Int(n / 2); w := Int(n / 2);
  return rec(b := b, ell := ell, n := n, k := k, w := w, lambda := lambda);
end;
```
Exit: `HGOEParams(128)` returns correct record.

**11.2b — Stages 2-3: QC code generation and PAut computation (2h).**
Generate a random quasi-cyclic code over GF(2) with circulant blocks,
then compute its permutation automorphism group using GAP's
`AutomorphismGroup` or the `images` package. This is the most technically
challenging sub-task — GAP's code-theoretic tools (GUAVA package) may
need specific configuration for QC codes.
```gap
HGOEGenerateCode := function(params)
  # For each of params.ell blocks, sample a random circulant b x b matrix
  # Assemble into generator matrix
  # Compute PAut via GUAVA or manual approach
end;
```
Exit: function returns a permutation group G with `Size(G) >= 2^lambda`.
If GUAVA is unavailable, fall back to generating a random permutation group
directly (less cryptographically motivated but sufficient for benchmarking).

**11.2c — Stage 4: Orbit representative harvesting (1.5h).** Sample
weight-w bitstrings and compute canonical images to find distinct orbits:
```gap
HGOEHarvestReps := function(G, n, w, numReps)
  # Sample random weight-w bitstring
  # Compute CanonicalImage(G, x) via images package
  # If canonical image is new, add to representative set
  # Repeat until numReps distinct orbits found
end;
```
Exit: function returns `numReps` distinct representatives, all with weight w.

**11.2d — Stages 5-7: Assembly and validation (1h).** Combine the above
into the complete `HGOEKeygen` function. Run validation checks:
- `Size(G) >= 2^lambda`
- All representatives have weight w
- All canonical images are distinct
- `CanonicalImage(G, rep_i) <> CanonicalImage(G, rep_j)` for i != j

Exit: `HGOEKeygen(HGOEParams(128))` produces a valid key in under 60 seconds.

---

### 11.3 — KEM Encapsulation/Decapsulation

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_kem.g` | **Deps:** 11.2

**Sub-tasks:**

**11.3a — Bitstring permutation action (1h).** Implement the core group
action `g . x` for bitstrings represented as GAP lists:
```gap
PermuteBitstring := function(x, sigma)
  # Apply sigma^(-1) permutation to coordinates (left-action convention)
  return Permuted(x, sigma^(-1));
end;
```
Validate: `PermuteBitstring(x, ())` = x (identity acts trivially).
`PermuteBitstring(PermuteBitstring(x, sigma), tau)` =
`PermuteBitstring(x, sigma * tau)` (composition law).
Exit: function works for n=8 test case.

**11.3b — Encapsulation (1h).** Implement:
```gap
HGOEEncaps := function(sk, basePoint)
  local g, c, canon_c, k;
  g := PseudoRandom(sk.G);
  c := PermuteBitstring(basePoint, g);
  canon_c := CanonicalImage(sk.G, c, OnTuples);
  k := sk.keyDerive(canon_c);
  return rec(ciphertext := c, key := k);
end;
```
Note: `OnTuples` is the GAP action function for permutations acting on
lists — must match the `images` package API exactly.
Exit: `HGOEEncaps` returns a record with ciphertext and key.

**11.3c — Decapsulation (1h).** Implement:
```gap
HGOEDecaps := function(sk, c)
  local canon_c;
  canon_c := CanonicalImage(sk.G, c, OnTuples);
  return sk.keyDerive(canon_c);
end;
```
Exit: `HGOEDecaps(sk, HGOEEncaps(sk, bp).ciphertext)` = `HGOEEncaps(sk, bp).key`.

**11.3d — Round-trip validation (1h).** Test 100 random encapsulations and
verify decaps recovers the same key. Also test with different base points.
Exit: 100% round-trip success rate.

**Exit criteria:** All four sub-tasks pass.

---

### 11.4 — Correctness Test Suite

**Effort:** 3h | **File:** `implementation/gap/orbcrypt_test.g` | **Deps:** 11.3

Comprehensive correctness tests:

1. **Round-trip test:** For N=1000 random encapsulations, verify decaps
   recovers the encapsulated key.
2. **Orbit membership test:** Verify every ciphertext lies in the correct orbit.
3. **Weight preservation test:** Verify every ciphertext has the correct
   Hamming weight.
4. **Canonical form consistency:** Verify `CanonicalImage(G, g1.x) =
   CanonicalImage(G, g2.x)` for random g1, g2.
5. **Distinct orbit test:** Verify different base points have different
   canonical images.

**Exit criteria:** All tests pass for parameter sets lambda in {80, 128}.

---

### 11.5 — Benchmark Harness

**Effort:** 5h | **File:** `implementation/gap/orbcrypt_bench.g` | **Deps:** 11.3

**Sub-tasks:**

**11.5a — Timing utility (1h).** Implement a reusable timing wrapper:
```gap
TimeOperation := function(op, nTrials)
  # Run op() nTrials times, collect wall-clock timings
  # Return: rec(mean, median, min, max, stddev)
end;
```
Exit: `TimeOperation(function() return 1; end, 100)` returns valid stats.

**11.5b — Key generation benchmark (1h).** Time `HGOEKeygen` for each
lambda in {80, 128, 192, 256}. Run 5 trials per lambda (keygen is slow).
Also measure: SGS size (number of generators), group order (log2), number
of Schreier-Sims levels.
Exit: CSV row per lambda with keygen timing and key metadata.

**11.5c — Encapsulation benchmark (1h).** Time `HGOEEncaps` with 1000
trials per lambda. Separately measure: group element sampling time vs.
permutation application time vs. canonical image time.
Exit: CSV row per lambda with encaps timing breakdown.

**11.5d — Decapsulation benchmark (1h).** Time `HGOEDecaps` with 1000
trials per lambda. The dominant cost is `CanonicalImage` — measure it
separately.
Exit: CSV row per lambda with decaps timing and canonical image breakdown.

**11.5e — CSV output and summary (1h).** Combine all timing data into
a structured CSV:
```
lambda, n, log2_G, keygen_ms, encaps_ms, decaps_ms, ct_bits, key_bits
80, 216, 81, ..., ..., ..., 216, 256
128, 344, 129, ..., ..., ..., 344, 256
```
Also generate a human-readable summary table to stdout.
Exit: CSV file is written and parseable.

**Exit criteria:** All five sub-tasks produce valid output.

---

### 11.6 — Parameter Generation Utility

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_params.g` | **Deps:** 11.2

**Sub-tasks:**

**11.6a — Parameter derivation for all levels (1h).** Implement
`HGOEParams(lambda)` and run for lambda in {80, 128, 192, 256}:

| Lambda | n | b | ell | k | w | Expected |G| |
|--------|---|---|-----|---|---|---------------|
| 80 | 216 | 8 | 27 | 108 | 108 | >= 2^81 |
| 128 | 344 | 8 | 43 | 172 | 172 | >= 2^129 |
| 192 | 520 | 8 | 65 | 260 | 260 | >= 2^195 |
| 256 | 688 | 8 | 86 | 344 | 344 | >= 2^258 |

Exit: table populated with derived values.

**11.6b — Group order validation (1.5h).** For each parameter set, generate
a QC code and verify `Log2(Size(G)) >= lambda`. Record actual group orders.
Exit: all four parameter sets pass validation.

**11.6c — Orbit count estimation (1.5h).** For each parameter set, estimate
the number of distinct weight-w orbits by sampling 1000 random weight-w
bitstrings and counting distinct canonical images. Compare to the theoretical
estimate C(n,w)/|G|.
Exit: orbit count estimates match theoretical predictions within 10x.

**Exit criteria:** All three sub-tasks complete.

---

### 11.7 — Comparison Data Collection

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_bench.g` | **Deps:** 11.5

Collect comparison data against existing schemes at equivalent security levels.
This is a literature exercise (not implementation of other schemes):

| Scheme | Type | Key Size | CT Size | Enc Time | Dec Time |
|--------|------|----------|---------|----------|----------|
| AES-256-GCM | Symmetric | 256 bits | n + 128 bits | ~1 ns/byte | ~1 ns/byte |
| Kyber-768 | KEM | 2400 B | 1088 B | ~30 us | ~25 us |
| BIKE-L3 | Code-KEM | 3114 B | 3114 B | ~100 us | ~200 us |
| HQC-256 | Code-KEM | 7245 B | 14469 B | ~300 us | ~500 us |
| **HGOE-128** | Orbit-KEM | **?** | **344 bits** | **?** | **?** |

Fill in the HGOE-128 row from benchmarks. This data informs Phase 14.

**Exit criteria:** Comparison table populated with HGOE measurements.

---

### 11.8 — Invariant Attack Verification

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_test.g` | **Deps:** 11.3

Empirically verify the invariant attack and defense:

1. **Attack test:** Create a scheme with different-weight representatives.
   Confirm Hamming weight distinguishes them with advantage 1 (100% accuracy).
2. **Defense test:** Create a scheme with same-weight representatives.
   Confirm Hamming weight gives advantage 0 (50% accuracy, random guessing).
3. **Higher-order invariant test:** Test several candidate invariants on
   same-weight representatives: number of bit-runs, autocorrelation at lag 1,
   parity of specific coordinate subsets. Measure empirical advantage for each.

**Exit criteria:** Attack test confirms 100% accuracy on different-weight reps.
Defense test confirms ~50% accuracy on same-weight reps. Higher-order
invariant tests report their empirical advantages.

---

### 11.9 — Documentation and Reproducibility

**Effort:** 5h | **File:** `implementation/README.md` | **Deps:** 11.5, 11.6

Write documentation covering:
- Installation instructions (GAP, packages, exact versions)
- How to run tests: `gap orbcrypt_test.g`
- How to run benchmarks: `gap orbcrypt_bench.g`
- How to generate parameters: `gap orbcrypt_params.g`
- Interpretation guide for benchmark output
- Known limitations and caveats

**Exit criteria:** A fresh GAP installation can reproduce all benchmarks
following only the README instructions.

---

## Internal Dependency Graph

```
11.1 (GAP Environment Setup)
  |
  v
11.2 (Key Generation)
  |         \
  v          \
11.3 (KEM)   11.6 (Parameter Generation)
  |   \   \         |
  v    \   \        v
11.4   \  11.8   11.9 (Documentation) <-- also depends on 11.5
(Tests) \  (Invariant Attack)
         v
       11.5 (Benchmark Harness)
         |
         v
       11.7 (Comparison Data)
         |
         v
       11.9 (Documentation)
```

**Critical path:** 11.1 -> 11.2 -> 11.3 -> 11.5 -> 11.7 -> 11.9 (20h sequential).

**Explicit dependency edges:**

| Unit | Depends On |
|------|------------|
| 11.1 | None |
| 11.2 | 11.1 |
| 11.3 | 11.2 |
| 11.4 | 11.3 |
| 11.5 | 11.3 |
| 11.6 | 11.2 |
| 11.7 | 11.5 |
| 11.8 | 11.3 |
| 11.9 | 11.5, 11.6 |

---

## Parallelism Notes

After 11.3 (KEM) completes, three independent work streams can proceed in
parallel:

- **Stream A (Testing):** 11.4 (Correctness Tests) and 11.8 (Invariant Attack
  Verification) can run simultaneously. Both depend only on 11.3.
- **Stream B (Benchmarking):** 11.5 (Benchmark Harness) -> 11.7 (Comparison
  Data). Sequential within the stream but parallel to Stream A.
- **Stream C (Parameters):** 11.6 (Parameter Generation) depends only on 11.2,
  so it can start as soon as key generation is working, running in parallel
  with 11.3 and everything downstream.

11.9 (Documentation) is a join point: it waits for both 11.5 and 11.6 before
starting, to ensure benchmark results and parameter tables are available for
inclusion.

**Maximum parallelism schedule (2 workers):**

| Week | Worker 1 | Worker 2 |
|------|----------|----------|
| 21 | 11.1 (2h), 11.2 start (3h) | — |
| 22 | 11.2 finish (2h), 11.3 start (2h) | 11.6 (4h) |
| 23 | 11.3 finish (2h), 11.5 (5h) | 11.4 (3h), 11.8 (4h) |
| 24-25 | 11.7 (4h), 11.9 (5h) | — |

---

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| GUAVA package unavailable or incompatible with GAP 4.12+ | Medium | Medium | Fall back to generating random permutation groups directly (less cryptographically motivated but sufficient for benchmarking). Document the fallback in README. |
| `CanonicalImage` too slow for n >= 344 | High | High | This is the primary performance risk. If canonical image computation exceeds 10 seconds per call at n=344, the KEM is impractical at 128-bit security. Mitigation: (1) try the `ferret` package for partition backtracking, (2) reduce n by increasing block size b, (3) flag for Phase 14 optimization. |
| Group order too small (|G| < 2^lambda) | Medium | High | QC code automorphism groups may not be large enough. Mitigation: increase number of circulant blocks (ell), or use wreath product construction to amplify group size. |
| Orbit harvesting too slow | Medium | Medium | Finding distinct weight-w orbits requires many canonical image computations. Mitigation: pre-filter by easily-computable invariants before expensive canonical image calls. |
| GAP's `PseudoRandom` not cryptographically secure | Low | Low | Acceptable for benchmarking and correctness testing. Real deployment would replace with a CSPRNG. Document this limitation. |
| Round-trip failure due to action convention mismatch | Medium | Medium | The left-action convention (`sigma^(-1)` in coordinate permutation) must be consistent between `PermuteBitstring`, `CanonicalImage`, and `HGOEKeygen`. Mitigation: extensive unit tests in 11.3a and 11.4. |

---

## Go/No-Go Decision Point

After completing 11.5 (Benchmark Harness), evaluate the following criteria
before proceeding to 11.7-11.9:

**Go criteria (all must hold):**
1. `HGOEKeygen(HGOEParams(128))` completes in under 300 seconds.
2. `HGOEEncaps` at lambda=128 completes in under 10 seconds per call.
3. `HGOEDecaps` at lambda=128 completes in under 10 seconds per call.
4. Round-trip correctness holds for 100% of 1000 test cases at lambda=80.

**No-go outcomes:**
- If keygen exceeds 300 seconds at lambda=128: investigate whether the bottleneck
  is PAut computation or orbit harvesting. If PAut, consider alternative group
  families. If orbit harvesting, consider pre-computation strategies.
- If encaps/decaps exceeds 10 seconds at lambda=128: the canonical image
  computation is the bottleneck. Escalate to Phase 14 (Decryption Optimization)
  and consider the canonical form cache or approximate methods.
- If round-trip fails: debug the action convention mismatch (most likely cause).
  Do not proceed until 100% correctness is achieved.

**Decision:** Record the go/no-go decision and rationale in
`implementation/gap/README.md` before proceeding to 11.7.

---

## Phase Exit Criteria

All of the following must hold before Phase 11 is considered complete:

1. **Environment:** GAP 4.12+ installed with `images`, `GUAVA` (or documented fallback), and `IO` packages.
2. **Key generation:** `HGOEKeygen` produces valid keys for all four security levels (lambda in {80, 128, 192, 256}).
3. **Round-trip correctness:** `HGOEDecaps(sk, HGOEEncaps(sk, bp).ciphertext)` recovers the encapsulated key for 1000 trials at lambda=80 and lambda=128.
4. **Test suite:** All five correctness tests (round-trip, orbit membership, weight preservation, canonical form consistency, distinct orbits) pass.
5. **Benchmarks:** CSV file produced with timing data for all four security levels. Timing breakdown (keygen, encaps, decaps) available per level.
6. **Parameters:** All four parameter sets validated with `Log2(Size(G)) >= lambda`. Orbit count estimates recorded.
7. **Comparison table:** HGOE-128 row populated in the comparison table alongside AES-256-GCM, Kyber-768, BIKE-L3, and HQC-256.
8. **Invariant attack:** Empirically verified — 100% accuracy on different-weight reps, ~50% accuracy on same-weight reps.
9. **Documentation:** `implementation/README.md` enables a fresh GAP installation to reproduce all results.
10. **Go/no-go:** Decision recorded with rationale.

---

## Summary Table

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 11.1 | GAP Environment Setup | `implementation/gap/README.md` | 2h | None |
| 11.2 | Key Generation | `implementation/gap/orbcrypt_keygen.g` | 5h | 11.1 |
| 11.3 | KEM Enc/Dec | `implementation/gap/orbcrypt_kem.g` | 4h | 11.2 |
| 11.4 | Correctness Tests | `implementation/gap/orbcrypt_test.g` | 3h | 11.3 |
| 11.5 | Benchmark Harness | `implementation/gap/orbcrypt_bench.g` | 5h | 11.3 |
| 11.6 | Parameter Generation | `implementation/gap/orbcrypt_params.g` | 4h | 11.2 |
| 11.7 | Comparison Data | `implementation/gap/orbcrypt_bench.g` | 4h | 11.5 |
| 11.8 | Invariant Attack Verification | `implementation/gap/orbcrypt_test.g` | 4h | 11.3 |
| 11.9 | Documentation | `implementation/README.md` | 5h | 11.5, 11.6 |

**Total effort:** ~36 hours across 9 work units.

**Parallelism:** 11.4 (tests) and 11.5 (benchmarks) can run in parallel
after 11.3. 11.6 (params) depends only on 11.2. 11.8 (invariant attack)
depends only on 11.3.
