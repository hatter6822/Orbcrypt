<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Orbcrypt HGOE — Parameter Recommendations

*Phase 14 deliverable — see
[docs/dev_history/PHASE_14_PARAMETER_SELECTION.md](planning/PHASE_14_PARAMETER_SELECTION.md).*

This document turns the Phase 11 GAP benchmark data and a systematic
parameter sweep into concrete parameter guidance for HGOE (Hidden-Group
Orbit Encryption) across four security levels λ ∈ {80, 128, 192, 256}.

It is organised in six sections mirroring Phase 14's work units:

| §   | Topic                               | Work Unit |
|-----|-------------------------------------|-----------|
| §1  | Parameter-space exploration         | 14.1      |
| §2  | Optimal parameter selection         | 14.2      |
| §3  | Cross-scheme comparison             | 14.3      |
| §4  | Security-margin analysis            | 14.4      |
| §5  | Ciphertext-expansion analysis       | 14.5      |
| §6  | Three-tier recommendations          | 14.6      |

Reproducibility: every table and recommendation is traceable to a CSV
under `docs/benchmarks/`. Section §7 documents how to regenerate the
data from a fresh GAP install.

---

## Conventions and notation

- **λ (lambda)** — the classical security parameter (bits of work).
- **b** — block size of the quasi-cyclic code / wreath product.
- **ell (ℓ)** — number of blocks; `ell = ⌈λ / log₂(b)⌉`.
- **n** — bitstring length; `n = b · ell`.
- **k** — code dimension; rate `k/n`.
- **w** — Hamming weight of the base-point support.
- **|G|** — order of the (secret) permutation group; `log₂|G|` is the
  bit-size of that order.
- **canon_ms** — time to compute the canonical image under G, the
  dominant cost of both encapsulation and decapsulation.

Rows tagged **measured** in the CSVs come from the Phase 11 GAP
benchmark (`implementation/gap/orbcrypt_benchmarks.csv`). Rows tagged
**projected** come from the scaling model documented in §1, which
should be replaced by direct measurements when
`implementation/gap/orbcrypt_sweep.g` is run on a production box.

---

## 1. Parameter-space exploration (Work Unit 14.1)

### 1.1 The sweep grid

For each level λ ∈ {80, 128, 192, 256} we sweep three axes:

| Axis     | Values                        | Rationale                         |
|----------|-------------------------------|-----------------------------------|
| `b`      | {4, 8, 16, 32}                | Block size of the QC / wreath product |
| `w/n`    | {1/3, 1/2, 2/3}               | Target Hamming weight             |
| `k/n`    | {1/4, 1/3, 1/2}               | Code rate (QC generator parameter) |

`ell = ⌈λ / log₂(b)⌉` is derived from λ and `b`; `n = b · ell` is a
consequence. Each level therefore has 4 × 3 × 3 = **36 configurations**,
well above the 16-configuration minimum in the phase exit criterion.

### 1.2 Sweep implementation

The full sweep is implemented in
[`implementation/gap/orbcrypt_sweep.g`](../implementation/gap/orbcrypt_sweep.g).
Usage:

```bash
echo 'Read("implementation/gap/orbcrypt_keygen.g");; \
      Read("implementation/gap/orbcrypt_kem.g");; \
      Read("implementation/gap/orbcrypt_bench.g");; \
      Read("implementation/gap/orbcrypt_sweep.g");; \
      RunFullSweep();; QUIT;' | gap -q -b
```

For each configuration the script measures `log₂|G|`, the number of
distinct orbits observed in `numSamples` uniformly-random weight-w
draws, the mean canonical-image time, and the mean keygen time; it
writes `docs/benchmarks/results_<λ>.csv` plus the cross-scheme
`comparison.csv`. `RunQuickSweep()` is the low-sample smoke test.

Each per-level CSV has 39 rows: 36 grid-sweep rows (tagged
`tier = sweep`) plus 3 tier-pinned rows (`tier = aggressive | balanced
| conservative`) used by §6. The aggressive tier coincides exactly
with the `(b = 8, w = n/2, k = n/2)` grid sweep row, so each CSV
contains one intentional duplicate pair — one row for the sweep
context, one for the §6 tier lookup. The `tier` column disambiguates
them.

### 1.3 Scaling model used for pre-populated CSVs

Until the sweep is run on a live GAP install, the
`docs/benchmarks/results_*.csv` files are pre-populated from the
Phase 11 measurements (four `b = 8, w = n/2, k = n/2` anchor rows,
one per λ) extended by the power-law model

```
canon_ms(λ, b, w) ≈ canon_8(λ) · (n / n_8)^1.51 · (8/b)^0.25 · W(w/n)
keygen_ms(λ, b, w) ≈ keygen_8(λ) · (n / n_8)^1.51 · (8/b)^0.20
W(w/n) = 1.00 if w = n/2, else 0.87
```

The exponent `1.51` is the log-log least-squares fit of
`(n, canon_ms)` across the four Phase 11 b=8 rows
(n ∈ {216, 344, 512, 688}). Rows derived from this model carry
`status = projected`; the four anchor rows carry `status = measured`.

### 1.4 Sweep outputs at a glance

The `w = n/2`, `k = n/2` slice of `docs/benchmarks/results_128.csv`
(12 configurations × 1 weight × 1 rate reduces to 4 rows):

| b  | ell | n    | log₂\|G\| | canon_ms | keygen_ms | status |
|----|-----|------|-----------|----------|-----------|--------|
| 4  | 64  | 256  | 129       | 244      | 335       | projected |
| 8  | 43  | 344  | 130       | 320      | 455       | **measured** |
| 16 | 32  | 512  | 129       | 491      | 722       | projected |
| 32 | 26  | 832  | 131       | 859      | 1309      | projected |

Observation: `b = 4` minimises `n` (hence `canon_ms`) for a fixed
`log₂|G|` threshold because each block contributes only
`log₂(4) = 2` bits, so ell grows but `n = b · ell` stays compact. The
cost is a larger generator count (65 vs 44 at b=8), which partially
cancels the speedup. See §6 for the final recommendation.

---

## 2. Optimal parameter selection (Work Unit 14.2)

### 2.1 Optimisation criteria

In priority order:

1. **Security** — `log₂|G| ≥ λ` is a hard constraint. Rows failing this
   are marked `passed = false` in the sweep CSVs.
2. **Decryption speed** — minimise `canon_ms`.
3. **Ciphertext size** — minimise `n`.
4. **Key size** — minimise the serialised secret-key representation.
   With `KeyMgmt/SeedKey.lean` the key is a 32-byte seed regardless of
   `(b, ell)`, so this criterion is currently satisfied by every
   configuration.

### 2.2 Optimal parameter table (measured baseline, `b = 8`)

Using the Phase 11 measurements directly — the `balanced` tier in §6:

| Level | λ   | n    | b | ell | k    | w    | log₂\|G\| | CT size | Dec time |
|-------|-----|------|---|-----|------|------|-----------|---------|----------|
| L1    | 80  | 216  | 8 | 27  | 108  | 108  | 82        | 27 B    | 182 ms   |
| L3    | 128 | 344  | 8 | 43  | 172  | 172  | 130       | 43 B    | 348 ms   |
| L5    | 192 | 512  | 8 | 64  | 256  | 256  | 193       | 64 B    | 532 ms   |
| L7    | 256 | 688  | 8 | 86  | 344  | 344  | 259       | 86 B    | 1186 ms  |

Dec time is the mean decapsulation time from
`orbcrypt_benchmarks.csv`; ciphertext size is `⌈n/8⌉` bytes for the
KEM-only ciphertext.

### 2.2.1 Lean cross-link — λ-parameterised `HGOEKeyExpansion`

Each row of the table above corresponds to an instantiable Lean
witness of the structure
`HGOEKeyExpansion lam n M` declared in
`Orbcrypt/KeyMgmt/SeedKey.lean`. The leading `lam : ℕ` parameter
**is** the security parameter `λ` of this section (the Lean
identifier is spelled `lam` because `λ` is a reserved Lean token). The
structure's `group_large_enough : group_order_log ≥ lam` field is the
machine-checked obligation that the underlying group is at least
`λ`-bit secure; the `log₂|G|` column above shows the actual
`group_order_log` value chosen at deployment, which is always ≥ `λ`
(strict for L3, L5, L7).

Workstream G of the 2026-04-23 pre-release audit (finding V1-13 /
H-03 / Z-06 / D16, landed 2026-04-25) lifted the pre-G hard-coded
`group_order_log ≥ 128` bound to `≥ lam`, so all four security
tiers (L1, L3, L5, L7) are now Lean-instantiable. Pre-G, only L3
(λ = 128) had a corresponding Lean witness; L1 was strictly weaker
than the bound, and L5 / L7 received only the L3 strength
guarantee — a release-messaging gap that the audit flagged as
MEDIUM-severity. See `scripts/audit_phase_16.lean` "Workstream G
non-vacuity witnesses" for the four `example`s machine-checking
that each tier inhabits the structure.

The Lean-verified `≥ lam` bound is a **lower bound**, not an exact
bound: deployment chooses `group_order_log` per the §4 scaling-model
thresholds, often strictly above `lam`. Release claims about HGOE's
security level should cite this λ-parameterised form together with
the corresponding row above.

### 2.3 Caveat — Phase 11 baseline is a performance proxy, not a
secure parameter set

The Phase 11 fallback group is a block-cyclic wreath product whose
order `b^ell · 2 ≥ 2^λ` is guaranteed, but whose cryptographic
security depends on the underlying **code** structure that the
wreath product is not in fact derived from. The §4 security-margin
analysis identifies two additional constraints — birthday resistance
and algebraic-folding resistance — that the Phase 11 baseline does not
satisfy. Section §6 therefore recommends the balanced tier **only for
performance baselining**, and promotes `b = 4, n = 4λ` as the
minimal cryptographically-valid parameterisation.

---

## 3. Cross-scheme comparison (Work Unit 14.3)

All values at NIST Level 3 (~128-bit classical security). Raw values
are in `docs/benchmarks/comparison.csv`.

| Metric         | AES-256-GCM | Kyber-768   | BIKE-L3     | HQC-256     | Classic McEliece | LESS-L1     | **HGOE-128** |
|----------------|-------------|-------------|-------------|-------------|------------------|-------------|--------------|
| Type           | symmetric   | lattice-KEM | code-KEM    | code-KEM    | code-KEM         | code-sig    | **orbit-KEM** |
| Key (bytes)    | 32          | 2 400       | 3 114       | 7 245       | 261 120          | 13 900      | **32 (seed)** |
| CT (bytes)     | \|m\|+28    | 1 088       | 3 114       | 14 469      | 96               | 5 000       | **43**       |
| Enc (µs)       | 0.05        | 30          | 100         | 300         | 100              | N/A         | **314 000 †** |
| Dec (µs)       | 0.05        | 25          | 200         | 500         | 150              | N/A         | **348 000 †** |
| PQ secure?     | no          | yes         | yes         | yes         | yes              | yes         | **conjectured** |
| Assumption     | none        | MLWE        | QC-MDPC     | QC-HQC      | Goppa decoding   | Perm-CE     | **CE-OIA**   |
| Source         | SP800-38D   | FIPS 203    | NIST R4     | NIST R4     | NIST R4          | NIST On-Ramp | Phase 11    |

† GAP prototype timings. A production C/C++ implementation with
partition backtracking via `nauty` / `bliss` is expected to deliver
two to three orders of magnitude of speedup (see Phase 15 plan).

### 3.1 Honest per-metric assessment

**Key size (bytes).** HGOE's 32-byte seed equals AES-256 and is the
smallest of any KEM candidate in this table. This is a genuine
structural advantage: unlike code-based KEMs, the secret key material
never has to store generator matrices or parity-check structure — the
seed expands deterministically (`KeyMgmt/SeedKey.lean`).

**Ciphertext size (bytes).** HGOE-128's 43-byte ciphertext is 25× smaller
than Kyber-768, 72× smaller than BIKE-L3, and 336× smaller than
HQC-256. This is the other structural advantage of orbit-based
encryption: the ciphertext is a single orbit element, length `n`
bits. At conservative parameters (n = 512 for b = 4, §6 balanced)
the ciphertext is still 64 bytes — comparable to Classic McEliece.

**Encryption / decryption time (µs).** HGOE is currently 4–5 orders of
magnitude slower than Kyber and BIKE. The entire cost is in the
canonical-image computation; the remaining operations (group element
sampling, bitstring permutation) are <1 ms combined. A production
implementation is the explicit scope of Phase 15
(`docs/dev_history/PHASE_15_DECRYPTION_OPTIMIZATION.md`).

**Post-quantum posture.** HGOE security reduces to Code Equivalence
(CE) and/or Graph Isomorphism (GI), both of which are hard for
known quantum algorithms. The reduction chain is machine-checked in
`Hardness/Reductions.lean` and aligned with LESS / MEDS in
`docs/HARDNESS_ANALYSIS.md`. The final "conjectured" label reflects
that no quantum cryptanalysis against the exact HGOE parameterisation
has been published; it is not a stronger or weaker claim than the
candidates it is compared against.

**Assumption class.** CE-OIA is a fresh assumption introduced by
Orbcrypt, while MLWE / QC-MDPC / QC-HQC / Goppa have decades of
cryptanalysis behind them. This is the single largest open security
gap, tracked in `docs/dev_history/PHASE_16_FORMAL_VERIFICATION.md` as
ongoing work.

---

## 4. Security-margin analysis (Work Unit 14.4)

Each row below is evaluated against the §6 **balanced** parameter set
(`b = 8`, the Phase 11 baseline) and the §6 **conservative** parameter
set (`b = 4`, `n = 4λ`).

### 4.1 Attack vectors and costs

| Vector                        | Cost model                        | Notes                                         |
|-------------------------------|-----------------------------------|-----------------------------------------------|
| Brute-force orbit enumeration | `\|orbit\| = \|G\|/\|Stab\|`      | `\|Stab\| = 1` for generic weight-w support   |
| Birthday on orbits            | `sqrt(\|G\|)`                     | Attacker collects orbit samples (§4.3)        |
| Babai's GI (quasi-polynomial) | `2^O((log m)^3)`                  | `m` = vertex count of the CFI instance       |
| Algebraic folding (QC)        | hardness at dim = n/b             | §4.4 — binding constraint at small b          |

### 4.2 Brute-force orbit enumeration

The attacker enumerates every element of `|orbit|`. For the Phase 11
baseline at λ=128 with `log₂|G| = 130` and stabiliser order 1 this
costs 2^130 operations — comfortably above the λ threshold.

### 4.3 Birthday resistance

For birthday attacks the attacker collects `≈ sqrt(|G|)` ciphertexts
and expects a collision (two ciphertexts in the same orbit). Cost is
therefore `2^(log₂|G| / 2)`.

To achieve λ bits of **birthday** resistance we need
`log₂|G| ≥ 2λ`, i.e. `ell · log₂(b) ≥ 2λ`, equivalently
`ell ≥ ⌈2λ / log₂(b)⌉` and `n ≥ b · ell`:

| λ    | `n_birth`  (b=4) | `n_birth`  (b=8) | `n_birth`  (b=16) | `n_birth`  (b=32) |
|------|------------------|------------------|-------------------|-------------------|
| 80   | 320              | 432              | 640               | 1 024             |
| 128  | 512              | 688              | 1 024             | 1 664             |
| 192  | 768              | 1 024            | 1 536             | 2 464             |
| 256  | 1 024            | 1 368            | 2 048             | 3 296             |

Note that the Phase 11 baseline `n=344` at λ=128 provides only
`log₂|G|/2 ≈ 65` bits of birthday resistance. **If the application
allows multi-key / multi-target collisions, full birthday resistance
requires doubling the current Phase 11 `n` values.**

### 4.4 Algebraic folding on QC structure

Quasi-cyclic codes of block size `b` admit a structural attack that
folds the length-`n` permutation-equivalence instance into a
length-`n/b` instance over the extension field `F_{2^b}` (cf. Beullens
2021, LESS cryptanalysis). Concrete security requires the folded
instance to itself resist CE attacks, which in the LESS/MEDS
parameterisation empirically needs dimension `n/b ≥ λ`. Rearranged:

```
n ≥ b · λ  (algebraic-folding threshold)
```

| λ    | `n_alg`  (b=4) | `n_alg`  (b=8) | `n_alg`  (b=16) | `n_alg`  (b=32) |
|------|----------------|----------------|-----------------|-----------------|
| 80   | 320            | 640            | 1 280           | 2 560           |
| 128  | 512            | 1 024          | 2 048           | 4 096           |
| 192  | 768            | 1 536          | 3 072           | 6 144           |
| 256  | 1 024          | 2 048          | 4 096           | 8 192           |

**This is the binding constraint for b ≥ 8.** For b = 4 the algebraic
and birthday thresholds coincide (both require n ≥ 4λ), which is why
`b = 4` is the recommended conservative block size in §6.

### 4.5 Babai's Graph-Isomorphism bound

Babai (2015) showed GI has a quasi-polynomial algorithm running in
`2^O((log m)^3)` where `m` is the vertex count of the graph instance.
Via the CFI gadget the effective `m` is at least `n`, so the concrete
cost is at least `2^((log n)^3)` with a small hidden constant. For
`n = 512` this is `2^9^3 = 2^729` — far above any of the λ we
consider. Babai's bound is therefore **not a binding constraint** at
any of the parameter sets in this document; it rules out only the
fully trivial regime `n < 32` or so.

### 4.6 Security margin summary

For the three §6 recommended tiers at each security level. The
`log₂|G|` values below come from the fallback group order formula
`log₂|G| = ell · log₂(b) + 1` (block-cyclic direct product plus one
swap).

| λ   | Aggressive (b=8 Phase 11)                                                      | Balanced (b=4, n=4λ)                                                          | Conservative (b=4, n=8λ)                                                         |
|-----|--------------------------------------------------------------------------------|--------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| 80  | n=216 · ENUM=82 · BIRTH=41 · ALG=27  · **fails alg & birth**                   | n=320 · ENUM=161 · BIRTH=80 · ALG=80  · **passes all**                         | n=640 · ENUM=321 · BIRTH=160 · ALG=160 · **passes all, 2λ margin**              |
| 128 | n=344 · ENUM=130 · BIRTH=65 · ALG=43  · **fails alg & birth**                  | n=512 · ENUM=257 · BIRTH=128 · ALG=128 · **passes all**                        | n=1024 · ENUM=513 · BIRTH=256 · ALG=256 · **passes all, 2λ margin**             |
| 192 | n=512 · ENUM=193 · BIRTH=96 · ALG=64  · **fails alg & birth**                  | n=768 · ENUM=385 · BIRTH=192 · ALG=192 · **passes all**                        | n=1536 · ENUM=769 · BIRTH=384 · ALG=384 · **passes all, 2λ margin**             |
| 256 | n=688 · ENUM=259 · BIRTH=129 · ALG=86 · **fails alg & birth**                  | n=1024 · ENUM=513 · BIRTH=256 · ALG=256 · **passes all**                       | n=2048 · ENUM=1025 · BIRTH=512 · ALG=512 · **passes all, 2λ margin**            |

`ENUM = log₂|G|` (bits against brute-force).
`BIRTH = log₂|G|/2` (bits against birthday).
`ALG = n/b` (bits against QC-folding).
An entry with all three ≥ λ has full λ-bit security. The aggressive
Phase 11 baseline provides only brute-force resistance at λ and fails
both the birthday and algebraic-folding thresholds. The balanced
tier meets all three thresholds at exactly λ bits. The conservative
tier doubles every margin at the cost of ~3× larger `n`.

See `docs/benchmarks/comparison.csv` and `results_<λ>.csv` for the
raw numbers.

---

## 5. Ciphertext-expansion analysis (Work Unit 14.5)

### 5.1 Modes and overheads

| Mode                | Ciphertext formula           | Components                                |
|---------------------|-------------------------------|-------------------------------------------|
| HGOE-KEM            | `n` bits                      | one orbit element (KEM ct)                |
| HGOE-KEM + AEAD DEM | `n + \|m\| + 128` bits        | KEM ct + plaintext + 128-bit MAC tag      |
| AES-256-GCM         | `\|m\| + 96 + 128` bits       | plaintext + 96-bit IV + 128-bit tag       |

### 5.2 Break-even message length

Setting HGOE-hybrid total equal to AES-GCM total:

```
n + |m| + 128  =  |m| + 96 + 128
                  ──────────────
n              =  96  bits
```

For any `n > 96` bits the HGOE hybrid ciphertext is strictly larger
than the corresponding AES-GCM ciphertext, by a **constant overhead of
`n - 96` bits** independent of message length. Long messages therefore
amortise the overhead; short messages pay it in full.

### 5.3 Expansion ratio vs. AES-GCM (constant overhead, bytes)

| λ    | `n` (b=4 conservative) | CT overhead (bytes) | AES-GCM overhead (bytes) | Extra vs AES-GCM |
|------|-------------------------|---------------------|---------------------------|------------------|
| 80   | 320 bits  (40 B)        | 56 B                | 28 B                      | +28 B            |
| 128  | 512 bits  (64 B)        | 80 B                | 28 B                      | +52 B            |
| 192  | 768 bits  (96 B)        | 112 B               | 28 B                      | +84 B            |
| 256  | 1 024 bits (128 B)      | 144 B               | 28 B                      | +116 B           |

(`CT overhead = KEM ct + tag = n/8 + 16 bytes`.
`AES-GCM overhead = IV + tag = 12 + 16 = 28 bytes`.
Plaintext size is identical in both modes.)

### 5.4 Go / no-go against the 100× ceiling

The Phase 14 plan requires narrowing scope to KEM-only operation if
ciphertext expansion exceeds 100× AES-GCM for typical messages.
Expansion ratios for the **balanced** λ=128 parameters (`n = 512`,
§6.2):

| Message size | AES-GCM total | HGOE hybrid total | Ratio |
|--------------|---------------|-------------------|-------|
| 16 B         | 44 B          | 96 B              | 2.18× |
| 64 B         | 92 B          | 144 B             | 1.57× |
| 1 KiB        | 1 052 B       | 1 104 B           | 1.05× |
| 1 MiB        | ~1 048 604 B  | ~1 048 656 B      | ~1.0× |

**Verdict: GO.** Expansion never approaches the 100× ceiling; the
hybrid overhead is 2.18× for a 16 B message and asymptotically 1× for
messages much larger than `n/8` bytes. KEM-only operation is
therefore not required by the Phase 14 exit criteria.

At the conservative λ=128 tier (`n = 1024`) the numbers scale by a
constant: the HGOE hybrid total is `|m| + 128 + 16` bytes, the AES-GCM
total is `|m| + 28` bytes, giving a 4.82× ratio at 16 B and an
asymptotic 1× ratio for very long messages. The 100× ceiling is not
approached at any realistic message length in either tier.

---

## 6. Tiered parameter recommendations (Work Unit 14.6)

Three tiers per security level, plus a "not recommended" row
documenting configurations that fail one or more §4 constraints.

### 6.1 Conservative — 2λ-bit margins on every vector

For applications that want **double the minimum-viable security margin
against every known attack vector**. Meets `log₂|G| ≥ 4λ` AND
`n/b ≥ 2λ` simultaneously; sets `b = 4, n = 8λ`. Ciphertext is twice
the balanced tier; decapsulation is ~3× slower (projected).

| λ    | n     | b  | ell  | k     | w     | log₂\|G\| | CT (B) | Dec (ms, proj.) |
|------|-------|----|------|-------|-------|-----------|--------|-----------------|
| 80   | 640   | 4  | 160  | 320   | 320   | 321       | 80     | ~1 055          |
| 128  | 1 024 | 4  | 256  | 512   | 512   | 513       | 128    | ~1 976          |
| 192  | 1 536 | 4  | 384  | 768   | 768   | 769       | 192    | ~2 624          |
| 256  | 2 048 | 4  | 512  | 1 024 | 1 024 | 1 025     | 256    | ~7 150          |

### 6.2 Balanced — minimal parameters meeting all §4 thresholds

Smallest `n` that simultaneously satisfies `log₂|G| ≥ 2λ` (birthday)
AND `n/b ≥ λ` (algebraic). At `b = 4` both thresholds collapse to
`n = 4λ`, which is why the balanced tier uses `b = 4`. This is the
**default** recommended tier.

| λ    | n     | b  | ell  | k     | w     | log₂\|G\| | CT (B) | Dec (ms, proj.) |
|------|-------|----|------|-------|-------|-----------|--------|-----------------|
| 80   | 320   | 4  | 80   | 160   | 160   | 161       | 40     | ~370            |
| 128  | 512   | 4  | 128  | 256   | 256   | 257       | 64     | ~694            |
| 192  | 768   | 4  | 192  | 384   | 384   | 385       | 96     | ~921            |
| 256  | 1 024 | 4  | 256  | 512   | 512   | 513       | 128    | ~2 511          |

### 6.3 Aggressive — performance baseline (Phase 11 `b=8`)

The Phase 11 measured configuration. Satisfies only the brute-force
`log₂|G| ≥ λ` bound; **fails the birthday and algebraic-folding
thresholds**. Recommended only for performance baselining and
hardware-acceleration benchmarking, never for production.

| λ    | n     | b  | ell  | k     | w     | log₂\|G\| | CT (B) | Dec (ms, measured) |
|------|-------|----|------|-------|-------|-----------|--------|--------------------|
| 80   | 216   | 8  | 27   | 108   | 108   | 82        | 27     | 182                |
| 128  | 344   | 8  | 43   | 172   | 172   | 130       | 43     | 348                |
| 192  | 512   | 8  | 64   | 256   | 256   | 193       | 64     | 532                |
| 256  | 688   | 8  | 86   | 344   | 344   | 259       | 86     | 1 186              |

### 6.4 Not recommended

| Config                           | Why it fails                                                                                                             |
|----------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| Any `b` with `log₂|G| < λ`       | Fails brute-force resistance (hard constraint).                                                                          |
| `b = 16` at any λ                | Inefficient: b = 4 reaches the same security at `n = 4λ` vs `16λ` for `b = 16`, giving 4× smaller ciphertext.            |
| `b = 32` at any λ                | Same inefficiency, plus `n ≥ 32λ` pushes decaps time over 10 s at λ = 128 (projected > 700 ms at n = 832; scales > 10 s at n = 4 096). |
| `w < n/4` or `w > 3n/4`          | Small / dense supports have smaller orbits; `|Stab|` inflates and the brute-force cost drops below 2^λ.                   |
| Fallback wreath-product group    | No code-equivalence hardness argument; §4 results assume the QC-PAut construction from `orbcrypt_keygen.g`'s `HGOEGenerateCodeQC`. |

### 6.5 Recommendation summary

| Tier          | λ=80 (n,b) | λ=128 (n,b) | λ=192 (n,b) | λ=256 (n,b) |
|---------------|------------|-------------|-------------|-------------|
| Conservative  | 640, 4     | 1 024, 4    | 1 536, 4    | 2 048, 4    |
| **Balanced**  | 320, 4     | 512, 4      | 768, 4      | 1 024, 4    |
| Aggressive    | 216, 8     | 344, 8      | 512, 8      | 688, 8      |

**Default** (Orbcrypt library users should pick this unless they have
specific requirements): the **balanced** tier at their chosen λ.

---

## 7. Reproducibility

Every table is traceable to a CSV:

| Table          | Source CSV                                 |
|----------------|---------------------------------------------|
| §1 sweep       | `docs/benchmarks/results_<λ>.csv`           |
| §2 optimal     | `docs/benchmarks/results_<λ>.csv` (anchors) |
| §3 comparison  | `docs/benchmarks/comparison.csv`            |
| §4 margins     | derived from `results_<λ>.csv` + §4 models  |
| §5 expansion   | derived from §2 `n` column                  |
| §6 tiers       | `results_<λ>.csv` + §4 thresholds           |

### 7.1 Regenerating sweep CSVs from GAP

```bash
# From the project root:
echo 'Read("implementation/gap/orbcrypt_keygen.g");; \
      Read("implementation/gap/orbcrypt_kem.g");; \
      Read("implementation/gap/orbcrypt_bench.g");; \
      Read("implementation/gap/orbcrypt_sweep.g");; \
      RunFullSweep();; QUIT;' | gap -q -b
```

The default `RunFullSweep()` uses 20 canonical-image samples and
3 keygen trials per configuration; at λ=256 with `b = 4` this takes
several minutes. `RunQuickSweep()` (5 samples, 1 trial) is a CI-sized
smoke test.

Running the sweep replaces `status = projected` rows with measured
values; the `status = measured` anchor rows come out unchanged (up to
GAP PRNG jitter).

### 7.2 Regenerating the cross-scheme comparison

`RunFullSweep()` also writes `docs/benchmarks/comparison.csv`. The
non-HGOE rows are literature values with sources listed in the `source`
column; the `HGOE-128` row is a live measurement from the sweep's
embedded `BenchKeygen / BenchEncaps / BenchDecaps` calls.

### 7.3 Dependencies

GAP 4.12+ with the `images` (v1.3.2), `GUAVA` (≥ 3.15), and `IO`
(≥ 4.7) packages. Full install instructions are in
`implementation/README.md`.

---

## 8. Change log

| Date       | Change                                                            |
|------------|-------------------------------------------------------------------|
| 2026-04-20 | Initial Phase 14 publication (Work Units 14.1–14.6).              |
