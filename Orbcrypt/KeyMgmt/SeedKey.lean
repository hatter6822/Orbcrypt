/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Mathlib.Data.Nat.Log
import Orbcrypt.KEM.Correctness
import Orbcrypt.Construction.Permutation

/-!
# Orbcrypt.KeyMgmt.SeedKey

Seed-based key compression for Orbcrypt: reduces the secret key from
~1.8 MB (full SGS storage) to 256 bits (a compact seed), with deterministic
key expansion. This module also specifies the QC code key expansion pipeline
and provides a backward-compatibility bridge from `OrbitEncScheme`.

## Motivation

In the original Orbcrypt formalization, the secret key is the group `G` itself
(its generators, canonical form, etc.), stored as a Strong Generating Set (SGS)
of size O(n² log|G|) — approximately 1.8 MB for λ = 128. This is impractical
for deployment.

The solution: derive all key material deterministically from a short random
seed (e.g., 256 bits) using a PRF-based expansion pipeline. The seed is the
minimal secret; everything else — the QC code, its automorphism group, the
canonical form — is deterministically reconstructed.

## Main definitions

* `Orbcrypt.SeedKey` — seed-based key: compact seed + deterministic expansion
  plus a **machine-checkable bit-length compression witness** (audit
  F-AUDIT-2026-04-21-M2 / Workstream L1).
* `Orbcrypt.seed_kem_correctness` — seed-based KEM correctness
* `Orbcrypt.HGOEKeyExpansion` — λ-parameterised specification of the 7-stage key
  expansion pipeline (post-Workstream-G of audit 2026-04-23, finding V1-13 /
  H-03 / Z-06 / D16: takes a security parameter `lam : ℕ` and asks
  `group_order_log ≥ lam`, unlocking the λ ∈ {80, 192, 256} rows of the
  Phase-14 sweep that the pre-G hard-coded `≥ 128` bound made unreachable)
* `Orbcrypt.seed_determines_key` — equal seeds produce equal key material
* `Orbcrypt.OrbitEncScheme.toSeedKey` — backward compatibility bridge

## Compression semantics

The `compression` field of `SeedKey` formally witnesses a **bit-length
strict inequality** between the seed space and the group:

```text
Nat.log 2 (Fintype.card Seed) < Nat.log 2 (Fintype.card G)
```

Read: "the number of bits required to encode a seed is strictly less
than the number of bits required to encode a group element."

**Scope of the Lean-verified compression claim (audit 2026-04-23
finding V1-5 / D5 / H-01).** The `compression` field only certifies a
**minimum of one bit of compression** (strict inequality ≥ 1 bit).
It is **not** a Lean-verified statement about any specific
quantitative compression ratio (e.g., "256-bit seed compresses a
~1.8 MB group"). Concretely:
* `Nat.log 2 1 = 0`, `Nat.log 2 2 = 1`, so a `SeedKey` with
  `|Seed| = 1` and `|G| = 2` satisfies `compression` trivially.
* The numerical compression ratio achieved at a given deployment
  (e.g., the λ = 128 table below) is a **parameter choice** of the
  PRF and group construction, discharged by the concrete
  `Fintype.card` values supplied at instantiation time. It is **not**
  asserted by the `compression` field.
* External release claims about Orbcrypt's key-size story should
  frame `compression` as "the Lean formalisation proves at least 1
  bit of compression per instance, ruling out the sloppy case
  `|Seed| ≥ |G|`; the 256-bit / 1.8 MB quantitative ratio is a
  deployment parameter, verified by the `decide`-able
  `Fintype.card`-bound discharge at instantiation time."

The strict inequality is also scale-invariant — doubling both
`|Seed|` and `|G|` by a common factor preserves the inequality —
which is the correct semantics for a *per-bit* compression claim,
though not for a *ratio* claim.

### Key size comparison (deployment parameters; not certified by `compression`)

| Representation | Size (λ = 128) | Bit-length source |
|----------------|----------------|-------------------|
| Full SGS       | ~1.8 MB (~15 M bits) | `Nat.log 2 \|G\|`    |
| Seed key       | 256 bits            | `Nat.log 2 \|Seed\|` |
| Compression    | ≥ 1 bit (Lean-field); deployment ratio is a parameter choice | `compression` field (≥ 1-bit certification only) |

At λ = 128 the GAP HGOE implementation uses `Seed = Fin 256 → Bool`
(a 256-bit seed) and `|G|` a subgroup of `S_n` whose order satisfies
`Nat.log 2 |G| ≥ 128`. The bit-length witness `Nat.log 2 (2^256) <
Nat.log 2 |G|` is discharged by the concrete group-order bound
supplied at instantiation time. **The Lean formalisation does not
assert that this instantiation achieves any particular compression
ratio; it asserts only that the bit-length inequality holds, and
the deployment-specific numerical ratio is witnessed by the
`decide`-able `Fintype.card` comparison at that instantiation.**

### Why a witness, not just prose

Landing `compression` as a structure field makes the "compression
ratio" claim a first-class, machine-checked obligation on every
`SeedKey` instance, not an untracked prose assertion. A concrete
consumer (e.g., the GAP harness) cannot inhabit a `SeedKey` whose
seed space is larger than the group — a class of sloppy deployments
the pre-L1 API tacitly allowed.

## Why `Nat.log 2` rather than `Fintype.card` comparison

The alternative formulation `Fintype.card Seed < Fintype.card G`
compares elementwise counts; `compression` compares *bit-lengths*,
matching the prose framing of the comparison table above. The
bit-length form is strictly weaker — it does not preclude `|Seed|`
exceeding `|G|` by a sub-2× factor — but this is the **intended**
semantics: compression is about bits, not element counts, so a seed
with 2¹²⁸ values "compresses" a 2⁵¹² group (bit-length `128 < 512`)
even though the elementwise comparison permits much more.

## References

* docs/DEVELOPMENT.md §6.2.1 — QC code key expansion pipeline
* `docs/PARAMETERS.md` §2 — λ ∈ {80, 128, 192, 256} parameter recommendations
  (cross-referenced from `HGOEKeyExpansion`'s `lam` parameter)
* docs/dev_history/formalization/PRACTICAL_IMPROVEMENTS_PLAN.md — Phase 9, work units 9.1–9.3, 9.6–9.7
* `docs/dev_history/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 7.1 — Workstream L1
  (witnessed-compression refactor, 2026-04-22)
* `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 10 — Workstream G
  (λ-parameterised `HGOEKeyExpansion`, 2026-04-25)
-/

namespace Orbcrypt

variable {Seed : Type*} {G : Type*} {X : Type*} {K : Type*}

-- ============================================================================
-- Work Unit 9.1: Seed-Based Key Definition
-- ============================================================================

/--
A seed-based key: a short seed from which the full group and canonical form
can be deterministically derived, carrying a machine-checkable
**bit-length compression witness** (audit F-AUDIT-2026-04-21-M2 /
Workstream L1).

**Parameters:**
- `Seed`: the seed type (e.g., `Fin 256 → Bool` for 256-bit seeds).
  Must carry a `Fintype` instance so the compression claim is
  quantitative.
- `G`: the group type (derived from the seed via key expansion).
  Must carry a `Fintype` instance for the same reason.
- `X`: the ciphertext space the group acts on.

**Fields:**
- `seed`: the compact secret — a short random value (e.g., 256 bits)
- `expand`: deterministic key expansion from seed to canonical form
  (captures the full pipeline: seed → QC code → PAut(C₀) → SGS → canon)
- `sampleGroup`: deterministic group-element derivation from seed and counter
  (captures the PRF-based sampling: PRF(seed, nonce) → g ∈ G)
- `compression`: a proof that the bit-length of the seed space is
  strictly less than the bit-length of the group. Formally,
  `Nat.log 2 (Fintype.card Seed) < Nat.log 2 (Fintype.card G)`. This
  certifies the compression story advertised by the module docstring.

**Design rationale:**
The seed is the minimal secret. `expand` captures one-time key setup, and
`sampleGroup` captures per-encryption group element derivation. Both are
deterministic functions of the seed, eliminating the need for runtime randomness
and reducing key storage from O(n² log|G|) to |seed| bits. The `compression`
field makes "fewer seed bits than group bits" a **pre-condition** on
inhabiting the structure, so every concrete `SeedKey` instance certifies
its own compression claim.

**Why a structure field and not a separate theorem.** A free theorem
about a `SeedKey` would leave the compression claim a voluntary check
— a sloppy implementation could build a `SeedKey` whose seed space is
actually larger than the group. Making `compression` a field turns
compression into a **constructor obligation**: every `SeedKey`
inhabitant discharges it, and callers of `SeedKey Seed G X` receive
`sk.compression` as a ready-to-use fact. This is the discipline
CLAUDE.md's "no half-finished implementations" rule demands.
-/
structure SeedKey (Seed : Type*) (G : Type*) (X : Type*)
    [Fintype Seed] [Group G] [Fintype G]
    [MulAction G X] [DecidableEq X] where
  /-- The compact secret: a short random seed (e.g., 256 bits). -/
  seed : Seed
  /-- Deterministic key expansion: derive the canonical form from the seed.
      In HGOE, this captures: seed → QC code → PAut(C₀) → SGS → canonical form. -/
  expand : Seed → CanonicalForm G X
  /-- Deterministic group-element derivation from seed and a counter (nonce).
      In HGOE, this captures: PRF(seed, nonce) → pseudo-random g ∈ G. -/
  sampleGroup : Seed → ℕ → G
  /-- **Bit-length compression witness.** The seed's minimum bit-length is
      strictly smaller than the group's minimum bit-length: a concrete
      `SeedKey` instance cannot claim compression it does not deliver.
      The inequality is the scale-invariant form of "fewer bits of seed
      than bits of group element," and is trivially checkable by `decide`
      on concrete `Fintype`s (see the non-vacuity witness in
      `scripts/audit_phase_16.lean`). -/
  compression :
    Nat.log 2 (Fintype.card Seed) < Nat.log 2 (Fintype.card G)

-- ============================================================================
-- Work Unit 9.2: Seed-Key Correctness
-- ============================================================================

/--
**Seed-Key KEM Correctness.** If expansion produces a valid canonical form,
seed-based encryption is correct for the derived KEM.

The key insight is that seed-based key expansion does not affect the correctness
argument — correctness depends only on group-action algebra (canonical form
invariance), not on how the group element was chosen.

This follows directly from `kem_correctness`: regardless of how `g` is
derived (randomly or deterministically from a seed), the KEM correctly
recovers the encapsulated key.

**Proof:** Instantiate `kem_correctness` with `g := sampleGroup(seed, n)`.
-/
theorem seed_kem_correctness
    [Fintype Seed] [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (sk : SeedKey Seed G X)
    (kem : OrbitKEM G X K)
    (n : ℕ) :
    decaps kem (encaps kem (sk.sampleGroup sk.seed n)).1 =
    (encaps kem (sk.sampleGroup sk.seed n)).2 :=
  -- Direct application of KEM correctness — the source of `g` is irrelevant
  kem_correctness kem (sk.sampleGroup sk.seed n)

-- ============================================================================
-- Work Unit 9.3: QC Code Key Expansion Specification
-- ============================================================================

/--
Specification of the 7-stage HGOE key expansion pipeline (docs/DEVELOPMENT.md §6.2.1).

This is a **specification** (Prop-valued fields), not an executable function.
An implementation must satisfy these properties. The pipeline is:

1. **Parameter derivation:** Choose block size `b` and circulant count `ℓ`
   such that `n = b * ℓ`.
2. **Code generation:** Deterministically generate a quasi-cyclic (QC)
   `[n, code_dim]`-code from the seed.
3. **Automorphism computation:** Compute `PAut(C₀)` with sufficient order
   for λ-bit security.
4. **Weight uniformity:** Ensure all orbit representatives have the same
   Hamming weight (defense against the attack in docs/COUNTEREXAMPLE.md).

**Parameters:**
- `lam`: security parameter λ (in bits). Production deployments use
  `lam ∈ {80, 128, 192, 256}`, matching the Phase-14 parameter sweep in
  `docs/PARAMETERS.md`. The Lean identifier is spelled `lam` rather than
  `λ` because `λ` is a Lean reserved token (lambda-abstraction). Named-
  argument syntax accepts the spelling: `HGOEKeyExpansion (lam := 128)
  (n := 512) M`.
- `n`: bitstring length (must be at least `lam`-bit-secure under the
  scaling model in `docs/PARAMETERS.md` §4)
- `M`: message type (orbit indices)

**Note:** Fields 1–3 specify structural properties of the code construction.
Field 4 specifies the Hamming weight defense from docs/COUNTEREXAMPLE.md.

**Pre-Workstream-G note (audit 2026-04-23, finding V1-13 / H-03 / Z-06 /
D16).** Until Workstream G of the 2026-04-23 pre-release audit landed,
this structure hard-coded the bound `group_order_log ≥ 128` rather than
parameterising it by λ. The pre-G shape was instantiable only at the
λ = 128 row of the Phase-14 sweep; the λ ∈ {80, 192, 256} rows could
not discharge the bound (λ = 80 was strictly weaker than 128, λ ≥ 192
was strictly stronger). The post-G shape takes `lam : ℕ` as an explicit
structure parameter and asks `group_order_log ≥ lam`; the Phase-14
sweep's four security tiers are now Lean-instantiable witnesses (see
`scripts/audit_phase_16.lean`'s "Workstream G non-vacuity witnesses"
section for one `HGOEKeyExpansion lam …` example per security level).
The Lean-verified `≥ lam` bound is a **lower bound**, not an exact
bound: the actual group order chosen at deployment can be larger
(e.g., the λ = 128 GAP fixture chooses `group_order_log` well above
the 128 floor; see `docs/benchmarks/results_128.csv`). External
release claims about HGOE's λ coverage should cite this λ-parameterised
form together with the corresponding row of `docs/PARAMETERS.md`.
-/
structure HGOEKeyExpansion (lam : ℕ) (n : ℕ) (M : Type*) where
  /-- Stage 1: block size for the quasi-cyclic code. -/
  b : ℕ
  /-- Stage 1: number of circulant blocks. -/
  ℓ : ℕ
  /-- Stage 1: parameter derivation — code length equals block × circulant. -/
  param_valid : n = b * ℓ
  /-- Stage 2: code dimension (k in [n,k]-code). -/
  code_dim : ℕ
  /-- Stage 2: code dimension does not exceed code length. -/
  code_valid : code_dim ≤ n
  /-- Stage 3: log₂ of the automorphism group order. -/
  group_order_log : ℕ
  /-- Stage 3: group must be large enough for `lam`-bit security. The
      Lean-verified bound is a *lower bound* (`group_order_log ≥ lam`);
      production deployments choose `group_order_log` strictly above
      `lam` per the scaling-model thresholds in `docs/PARAMETERS.md`
      §4 (brute-force orbit enumeration, birthday on orbits, Babai's
      GI bound, algebraic QC-folding). -/
  group_large_enough : group_order_log ≥ lam
  /-- Stage 4: target Hamming weight for all representatives. -/
  weight : ℕ
  /-- Stage 4: orbit representative function. -/
  reps : M → Bitstring n
  /-- Stage 4: all representatives have the same Hamming weight
      (defense against the invariant attack from docs/COUNTEREXAMPLE.md). -/
  reps_same_weight : ∀ m, hammingWeight (reps m) = weight

-- ============================================================================
-- Work Unit 9.6: Key Size Analysis
-- ============================================================================

/--
**Key Determinism Theorem.** The seed uniquely determines all key material,
given equal seeds *and* equal sampling functions.

If two `SeedKey` values share the same seed and the same sampling function,
they produce identical group elements for every nonce. This is a structural
rewrite lemma — it reflects the pointwise consequence of the two hypotheses,
not a security guarantee on the seed-to-key relationship.

The quantitative compression claim advertised by `SeedKey` is discharged by
the `compression` field at construction time (see the module docstring),
not by this theorem. `seed_determines_key` complements the compression
witness with a **determinism** property: compact secrets plus fixed
expansion functions uniquely determine the expanded key material.
-/
theorem seed_determines_key
    [Fintype Seed] [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (sk₁ sk₂ : SeedKey Seed G X)
    (hSeed : sk₁.seed = sk₂.seed)
    (hSample : sk₁.sampleGroup = sk₂.sampleGroup) :
    ∀ n : ℕ, sk₁.sampleGroup sk₁.seed n = sk₂.sampleGroup sk₂.seed n := by
  -- Equal seeds + equal sampling functions → equal group elements for all nonces
  intro n; rw [hSeed, hSample]

/--
**Seed Expansion Determinism.** Equal seeds and expansion functions produce
the same canonical form.

Like `seed_determines_key`, this is a structural rewrite reflecting the
pointwise consequence of the two hypotheses. Semantic constraints on the
seed-to-key relationship (e.g., pseudorandomness of `expand`) are out of
scope for this module.
-/
theorem seed_determines_canon
    [Fintype Seed] [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (sk₁ sk₂ : SeedKey Seed G X)
    (hSeed : sk₁.seed = sk₂.seed)
    (hExpand : sk₁.expand = sk₂.expand) :
    sk₁.expand sk₁.seed = sk₂.expand sk₂.seed := by
  rw [hSeed, hExpand]

-- ============================================================================
-- Work Unit 9.7: Backward Compatibility Bridge
-- ============================================================================

/--
Any `OrbitEncScheme` over a non-trivial finite group can be wrapped in a
`SeedKey Unit G X`. The resulting "seed" carries no information (it is
`()`), so expansion is the identity on the scheme's canonical form.

This bridge proves that the seed-key model **generalizes** the existing
model: the original scheme corresponds to the degenerate case where the
"seed" is the trivial singleton and the canonical form is embedded
directly. Compression is *still* witnessed — at the weakest possible
form, because `|Unit| = 1` gives bit-length zero, which is strictly
less than any group with `Nat.log 2 |G| ≥ 1` (i.e., `|G| ≥ 2`).

**Parameters:**
- `scheme`: the original AOE scheme.
- `sampleG`: a function that provides group elements given a unit seed
  and nonce.
- `hGroupNontrivial`: a proof that the group has at least two elements.
  This is the weakest non-triviality hypothesis discharging the
  `compression` field at `Seed = Unit`; any practical Orbcrypt
  deployment satisfies it (|G| is astronomical).

**Design note:** The seed type is `Unit` because the original scheme
carries all key material explicitly — no *quantitative* compression is
achieved. The `compression` witness still lands, trivially, because
the bit-length inequality `0 < Nat.log 2 |G|` follows from `2 ≤ |G|`
via `Nat.log_pos`.
-/
def OrbitEncScheme.toSeedKey {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (sampleG : ℕ → G)
    (hGroupNontrivial : 1 < Fintype.card G) : SeedKey Unit G X where
  seed := ()
  expand := fun () => scheme.canonForm
  sampleGroup := fun () => sampleG
  -- Bit-length compression witness at `Seed = Unit`:
  -- `Nat.log 2 (Fintype.card Unit) = Nat.log 2 1 = 0`;
  -- `hGroupNontrivial : 1 < Fintype.card G` (i.e., `2 ≤ Fintype.card G`)
  -- gives `0 < Nat.log 2 |G|` via `Nat.log_pos`.
  compression := by
    show Nat.log 2 (Fintype.card Unit) < Nat.log 2 (Fintype.card G)
    -- Rewrite LHS: `Fintype.card Unit = 1` and `Nat.log b 1 = 0`.
    rw [Fintype.card_unit, Nat.log_one_right]
    -- RHS: `Nat.log_pos` delivers `0 < Nat.log 2 (Fintype.card G)` from
    -- `1 < 2` and `hGroupNontrivial : 1 < Fintype.card G` (i.e.,
    -- `2 ≤ Fintype.card G`).
    exact Nat.log_pos (by decide : (1 : ℕ) < 2) hGroupNontrivial

/--
The backward-compatibility bridge preserves the expansion output:
the canonical form from the seed key matches the original scheme's
canonical form.
-/
theorem toSeedKey_expand {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (sampleG : ℕ → G)
    (hGroupNontrivial : 1 < Fintype.card G) :
    (scheme.toSeedKey sampleG hGroupNontrivial).expand
      (scheme.toSeedKey sampleG hGroupNontrivial).seed =
    scheme.canonForm := rfl

/--
The backward-compatibility bridge preserves group element sampling:
the seed key produces the same group elements as the original sampler.
-/
theorem toSeedKey_sampleGroup {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (sampleG : ℕ → G)
    (hGroupNontrivial : 1 < Fintype.card G) (n : ℕ) :
    (scheme.toSeedKey sampleG hGroupNontrivial).sampleGroup
      (scheme.toSeedKey sampleG hGroupNontrivial).seed n =
    sampleG n := rfl

end Orbcrypt
