<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Orbcrypt HGOE — GAP Reference Implementation

A reference implementation of the Hidden-Group Orbit Encryption (HGOE) scheme
in [GAP](https://www.gap-system.org/) (Groups, Algorithms, Programming),
providing the first empirical benchmarks for key generation, KEM encapsulation,
and KEM decapsulation across multiple security levels.

This implementation is **Phase 11** of the
[Orbcrypt formalization project](../README.md). It translates the formally
verified Lean 4 definitions into runnable code, enabling real performance
measurements that inform subsequent optimization phases.

## Quick Start

```bash
# 1. Install GAP 4.12+ (Ubuntu/Debian)
sudo apt-get install gap gap-guava gap-io

# 2. Install the images package (canonical image computation)
mkdir -p ~/.gap/pkg && cd ~/.gap/pkg
git clone https://github.com/gap-packages/images.git
cd images && git checkout v1.3.2

# 3. (Optional) Install ferret for faster partition backtracking
cd ~/.gap/pkg
git clone https://github.com/gap-packages/ferret.git
cd ferret && bash autogen.sh
./configure --with-gaproot=/usr/share/gap && make

# 4. Run tests
cd <project-root>
echo 'Read("implementation/gap/orbcrypt_keygen.g");; Read("implementation/gap/orbcrypt_kem.g");; Read("implementation/gap/orbcrypt_test.g");; RunAllTests();; QUIT;' | gap -q -b

# 5. Run benchmarks
echo 'Read("implementation/gap/orbcrypt_keygen.g");; Read("implementation/gap/orbcrypt_kem.g");; Read("implementation/gap/orbcrypt_bench.g");; RunBenchmarks();; QUIT;' | gap -q -b

# 6. Run parameter generation
echo 'Read("implementation/gap/orbcrypt_keygen.g");; Read("implementation/gap/orbcrypt_kem.g");; Read("implementation/gap/orbcrypt_params.g");; RunParameterGeneration();; QUIT;' | gap -q -b
```

## Requirements

| Component | Version | Purpose |
|-----------|---------|---------|
| GAP | >= 4.12.0 | Core computational algebra system |
| images | >= 1.3.0, < 1.3.3 | Canonical image computation (Christopher Jefferson) |
| GUAVA | >= 3.15 | Error-correcting code support |
| IO | >= 4.7 | File I/O for benchmark CSV output |
| ferret | >= 0.8.0 | (Optional) Faster partition backtracking |
| datastructures | >= 0.2.0 | (Dependency of images >= 1.3.3) |

**Version pins tested:** GAP 4.12.1, images v1.3.2, GUAVA 3.18, IO 4.8.2.

## Files

| File | Purpose |
|------|---------|
| `gap/orbcrypt_keygen.g` | 7-stage HGOE key generation pipeline |
| `gap/orbcrypt_kem.g` | KEM encapsulation/decapsulation |
| `gap/orbcrypt_params.g` | Parameter generation for all security levels |
| `gap/orbcrypt_test.g` | Correctness test suite (13 tests) |
| `gap/orbcrypt_bench.g` | Benchmark harness with CSV output |
| `gap/orbcrypt_sweep.g` | **Phase 14 parameter sweep + tier-pinned rows** |
| `gap/orbcrypt_fast_dec.g` | **Phase 15 fast-decryption pipeline** (`QCCyclicReduce`, `FastDecaps`, `ComputeResidualGroup`, `SyndromeDecaps`, `OrbitHash`, `RunPhase15Comparison`) |
| `gap/orbcrypt_benchmarks.csv` | Benchmark results (generated) |

### Phase 14 parameter sweep

`gap/orbcrypt_sweep.g` is the Phase 14 parameter-space exploration
driver. It varies `b ∈ {4, 8, 16, 32}`, `w/n ∈ {1/3, 1/2, 2/3}`, and
`k/n ∈ {1/4, 1/3, 1/2}` at each `lambda ∈ {80, 128, 192, 256}`,
measures `log₂|G|`, orbit count, canonical-image time, and keygen
time for each configuration, and also measures the three
recommendation tiers (`aggressive`, `balanced`, `conservative`) from
[`docs/PARAMETERS.md §6`](../docs/PARAMETERS.md).

Output is written to
[`docs/benchmarks/`](../docs/benchmarks/): one CSV per security
level (`results_<lambda>.csv`, 39 rows each) plus
`comparison.csv` (cross-scheme comparison with literature values
for AES-256-GCM, Kyber-768, BIKE-L3, HQC-256, Classic McEliece, and
LESS-L1).

```bash
# Full sweep (20 samples × 3 keygen trials per config, ~30 min on a
# single core at lambda=256 with b=4):
echo 'Read("implementation/gap/orbcrypt_keygen.g");; \
      Read("implementation/gap/orbcrypt_kem.g");; \
      Read("implementation/gap/orbcrypt_bench.g");; \
      Read("implementation/gap/orbcrypt_sweep.g");; \
      RunFullSweep();; QUIT;' | gap -q -b

# Quick smoke test (5 samples × 1 trial, < 2 min):
echo 'Read("implementation/gap/orbcrypt_keygen.g");; \
      Read("implementation/gap/orbcrypt_kem.g");; \
      Read("implementation/gap/orbcrypt_bench.g");; \
      Read("implementation/gap/orbcrypt_sweep.g");; \
      RunQuickSweep();; QUIT;' | gap -q -b
```

## Architecture

### Bitstring Representation

Bitstrings are represented as **sorted lists of 1-positions** (support sets).
For example, the bitstring `[0,1,0,1,1]` is stored as `[2,4,5]`.

The symmetric group S_n acts on support sets via GAP's `OnSets`:

```
g . S = {g(i) : i in S}
```

This is a right action: `(x.s).t = x.(s*t)`. The canonical image under G is
the lexicographically smallest element of the orbit, computed by the `images`
package's `CanonicalImage(G, S, OnSets)`.

### Key Generation Pipeline (docs/DEVELOPMENT.md §6.2.1)

The 7-stage HGOE key generation pipeline:

1. **Parameter derivation:** b=8, ell=ceil(lambda/3), n=b*ell, k=n/2, w=n/2
2. **Group construction:** Block-cyclic wreath product (fallback) or QC code
   automorphism group (slow, available via `HGOEGenerateCodeQC`)
3. **Group validation:** Verify log2(|G|) >= lambda
4. **Orbit representative harvesting:** Sample random weight-w bitstrings,
   compute canonical images, collect representatives from distinct orbits
5. **Lookup table construction:** Map canonical images to message indices
6. **Secret key assembly:** Group SGS + lookup table
7. **Public parameter assembly:** n, w, |M|, representative array

**Note on group construction:** The full QC code + PAut(C) approach from
docs/DEVELOPMENT.md §6.2.1 is available via `HGOEGenerateCodeQC()` but GUAVA's
`AutomorphismGroup` is impractically slow for n > 20 in GAP. The default
`HGOEGenerateCode()` uses a block-cyclic wreath-product construction that
provides |G| >= 2^lambda instantly. This is acceptable for benchmarking
canonical image performance but is NOT cryptographically valid. A production
implementation would use optimized C/C++ code (Leon's algorithm or partition
backtracking) for PAut computation. See Phase 14 for optimization plans.

### KEM Operations

Following the Lean formalization (`KEM/Encapsulate.lean`):

```
encaps(sk, basePoint):
    g <- PseudoRandom(G)
    c := OnSets(basePoint, g)           -- ciphertext
    k := keyDerive(CanonicalImage(G, c)) -- shared key
    return (c, k)

decaps(sk, c):
    k := keyDerive(CanonicalImage(G, c)) -- same shared key
    return k
```

Round-trip correctness holds because `CanonicalImage` maps all orbit elements
to the same representative.

## Parameter Sets

| Lambda | n | b | ell | k | w | log2\|G\| | Keygen | Encaps | Decaps |
|--------|---|---|-----|---|---|-----------|--------|--------|--------|
| 80 | 216 | 8 | 27 | 108 | 108 | 82 | 285ms | 88ms | 102ms |
| 128 | 344 | 8 | 43 | 172 | 172 | 130 | 1360ms | 256ms | 244ms |
| 192 | 512 | 8 | 64 | 256 | 256 | 193 | 4975ms | 784ms | 624ms |
| 256 | 688 | 8 | 86 | 344 | 344 | 259 | 13575ms | 2588ms | 2580ms |

*Timings from GAP 4.12.1 on a single core. Production C/C++ implementation
expected to be 100-1000x faster.*

## Test Suite

The test suite (`orbcrypt_test.g`) includes 13 tests across 4 sections:

### Section 1: Basic Correctness
1. **KEM round-trip** (100 trials): `decaps(encaps(bp).ct) = encaps(bp).key`
2. **Orbit membership** (50 trials): ciphertext in same orbit as base point
3. **Weight preservation** (100 trials): Hamming weight invariant under permutation
4. **Canonical form consistency** (50 trials): `canon(g1.bp) = canon(g2.bp)`
5. **Distinct orbits** (10 orbits): different reps have different canonical images
6. **AOE encrypt/decrypt** (20 trials, 4 messages): multi-message scheme round-trip

### Section 2: Larger Parameters
7. **KEM round-trip** (50 trials, n=64)
8. **Canonical form consistency** (30 trials, n=64)

### Section 3: Invariant Attack Verification
9. **Invariant attack**: Different-weight reps give 100% distinguishing accuracy
10. **Weight defense**: Same-weight reps give ~50% accuracy (random guessing)
11. **Higher-order invariants**: Bit-runs and autocorrelation (informational)

### Section 4: Edge Cases
12. **Identity preservation**: `().x = x`
13. **Composition law**: `(x.s).t = x.(s*t)` (right action)

## Go/No-Go Decision

**Decision: GO** — All criteria met at lambda=128:

| Criterion | Threshold | Measured | Result |
|-----------|-----------|----------|--------|
| Keygen time | < 300s | ~1.1s | PASS |
| Encaps time | < 10s | ~0.2s | PASS |
| Decaps time | < 10s | ~0.2s | PASS |
| Round-trip correctness | 100% | 100% (1000 trials) | PASS |

The canonical image computation (partition backtracking) is the dominant cost,
accounting for >95% of encaps/decaps time. This is expected and motivates
Phase 14 (Decryption Optimization) for C/C++ implementation.

## Known Limitations

1. **Group construction:** The default uses block-cyclic wreath products, not
   QC code automorphism groups. This is sufficient for benchmarking but not
   cryptographically valid. GUAVA's `AutomorphismGroup` is too slow for n > 20.

2. **PRNG:** `PseudoRandom(G)` is not cryptographically secure. Acceptable
   for benchmarking and correctness testing. Production deployment would
   replace with a CSPRNG-based Product Replacement Algorithm.

3. **Canonical image performance:** GAP's `images` package uses pure GAP
   implementation of partition backtracking. A C/C++ implementation (e.g.,
   nauty/Traces or bliss) would be 100-1000x faster.

4. **Memory:** Large parameter sets (lambda >= 256, n >= 688) may require
   significant memory for group element storage and canonical image computation.

5. **Action convention:** GAP uses right-action (`OnSets(OnSets(x,s),t) =
   OnSets(x,s*t)`), while the Lean formalization uses left-action
   (`(s*t).x = s.(t.x)`). The canonical image and round-trip correctness
   are unaffected by this convention difference.

## Comparison with Existing Schemes

| Scheme | Type | Key Size | CT Size | Enc Time | Dec Time |
|--------|------|----------|---------|----------|----------|
| AES-256-GCM | Symmetric | 256 bits | n + 128 bits | ~1 ns/byte | ~1 ns/byte |
| Kyber-768 | KEM | 2400 B | 1088 B | ~30 us | ~25 us |
| BIKE-L3 | Code-KEM | 3114 B | 3114 B | ~100 us | ~200 us |
| HQC-256 | Code-KEM | 7245 B | 14469 B | ~300 us | ~500 us |
| **HGOE-128** | **Orbit-KEM** | **344 bits** | **344 bits** | **~200ms*** | **~220ms*** |

*GAP prototype timings. Production C/C++ expected 100-1000x faster.

HGOE has significantly smaller ciphertext sizes (344 bits vs kilobytes for
post-quantum schemes) but much slower operations in this unoptimized prototype.
The ciphertext compactness is a fundamental advantage of the orbit-based
approach.

## Reproducibility

To reproduce all results from a fresh installation:

```bash
# 1. Install prerequisites (Ubuntu 22.04+ / Debian 12+)
sudo apt-get update
sudo apt-get install -y gap gap-guava gap-io git build-essential autoconf

# 2. Install images package
mkdir -p ~/.gap/pkg
cd ~/.gap/pkg
git clone https://github.com/gap-packages/images.git
cd images && git checkout v1.3.2
cd ..

# 3. (Recommended) Install ferret for better performance
git clone https://github.com/gap-packages/ferret.git
cd ferret && bash autogen.sh
./configure --with-gaproot=/usr/share/gap && make
cd ..

# 4. (For ferret) Install datastructures
git clone https://github.com/gap-packages/datastructures.git
cd datastructures
./configure --with-gaproot=/usr/share/gap && make
cd ..

# 5. Clone Orbcrypt and run tests
cd /path/to/Orbcrypt
echo 'Read("implementation/gap/orbcrypt_keygen.g");; Read("implementation/gap/orbcrypt_kem.g");; Read("implementation/gap/orbcrypt_test.g");; RunAllTests();; QUIT;' | gap -q -b

# 6. Run benchmarks (produces CSV)
echo 'Read("implementation/gap/orbcrypt_keygen.g");; Read("implementation/gap/orbcrypt_kem.g");; Read("implementation/gap/orbcrypt_bench.g");; RunBenchmarks();; QUIT;' | gap -q -b

# 7. Run parameter generation
echo 'Read("implementation/gap/orbcrypt_keygen.g");; Read("implementation/gap/orbcrypt_kem.g");; Read("implementation/gap/orbcrypt_params.g");; RunParameterGeneration();; QUIT;' | gap -q -b
```

## License

MIT — see [LICENSE](../LICENSE) in the project root.
