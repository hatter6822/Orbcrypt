# Phase 9 — Key Compression & Nonce-Based Encryption

## Weeks 20–22 | 7 Work Units | ~18 Hours

*Part of the [Orbcrypt Practical Improvements Plan](../../formalization/PRACTICAL_IMPROVEMENTS_PLAN.md)*

---

## Overview

Phase 9 addresses two critical practical limitations of the Orbcrypt scheme:

1. **Key size.** The current formalization stores the full strong generating set
   (SGS) of the permutation automorphism group as the secret key. For the
   target security parameter (lambda = 128), this requires storing O(n^2 log|G|)
   bits — approximately 1.8 MB (15 million bits). This dwarfs AES-256's 32-byte
   key by a factor of ~56,000x, making Orbcrypt impractical for key exchange,
   key storage, and any protocol that transmits keys.

2. **Randomness requirement.** The current `encrypt` function requires a fresh
   uniformly random group element g in G for each encryption. In practice,
   sampling uniformly from a large permutation group is expensive and requires
   a trusted randomness source. Nonce-based deterministic encryption replaces
   this with a PRF-based derivation: given a seed and a nonce (counter), the
   group element is computed deterministically.

**Solution:** Replace the explicit SGS key with a 256-bit seed from which the
full key material (QC code, automorphism group, SGS, canonical form) is
deterministically derived. The seed serves as both the key compression
mechanism and the PRF seed for nonce-based encryption. The result:

- Key size: **256 bits** (matching AES-256)
- Encryption: **deterministic** given (seed, nonce) — no runtime randomness
- Security: **unchanged** — the seed expansion is a one-time computation;
  correctness depends only on group-action algebra, not on how the group
  element was chosen

---

## Objectives

1. Define the `SeedKey` structure: a compact seed from which the full group
   action key material is deterministically derived.
2. Prove seed-based encryption correctness: if expansion is faithful, the
   KEM correctness theorem carries over unchanged.
3. Specify the 7-stage HGOE key expansion pipeline as a Prop-valued
   specification (not executable Lean).
4. Define nonce-based deterministic encryption: derive the group element
   from (seed, nonce) rather than sampling randomly.
5. Characterize nonce-misuse behavior: reuse is detectable and does not
   leak the key, but does leak orbit membership.
6. Document and formalize the key size comparison (256 bits vs. ~15M bits).
7. Provide backward compatibility: show the existing `OrbitEncScheme` embeds
   trivially into the seed-key model.

---

## Prerequisites

- **Phase 7 (KEM Reformulation):** Complete. Phase 9 builds on the `OrbitKEM`
  structure, `encaps`/`decaps` functions, and `kem_correctness` theorem from
  Phase 7. The seed-key model wraps the KEM interface.
- **Phase 3 (Cryptographic Definitions):** Complete. The backward compatibility
  bridge (9.7) connects to `OrbitEncScheme` from Phase 3.
- **Phase 2 (Group Action Foundations):** Complete. `CanonicalForm` is used
  throughout.

**Not required:** Phase 8 (Probabilistic Foundations). The seed-key model is
purely algebraic — it does not require probability monads or computational
security definitions. Phase 8 and Phase 9 can proceed in parallel.

---

## New Files

```
Orbcrypt/
  KeyMgmt/
    SeedKey.lean         -- Seed-based key expansion definition (9.1, 9.2, 9.3, 9.6, 9.7)
    Nonce.lean           -- Nonce-based deterministic encryption (9.4, 9.5)
```

**Dependency on existing code:** Builds on `KEM/Syntax.lean` and
`KEM/Encapsulate.lean` (Phase 7) for the `OrbitKEM`, `encaps`, and `decaps`
definitions. Uses `GroupAction/Canonical.lean` for `CanonicalForm`. Connects
back to `Crypto/Scheme.lean` for the backward compatibility bridge.
Does NOT modify existing files — purely additive.

---

## Work Units

### Track A: Seed-Key Model (9.1 -> 9.2 -> 9.3)

Track A defines the seed-based key representation and proves it preserves
KEM correctness. It depends on Phase 7 (OrbitKEM).

---

#### 9.1 — Seed-Based Key Definition

**Effort:** 2h | **File:** `KeyMgmt/SeedKey.lean` | **Deps:** Phase 7

Define the seed-based key model. A `SeedKey` bundles a compact secret (the
seed) with two deterministic derivation functions: one that expands the seed
into a canonical form (the full key material), and one that derives group
elements from the seed and a counter (for encryption).

```lean
/-- A seed-based key: a short seed from which the full group and canonical
    form can be deterministically derived. -/
structure SeedKey (Seed : Type*) (G : Type*) (X : Type*)
    [Group G] [MulAction G X] [DecidableEq X] where
  /-- The compact secret: a short random seed (e.g., 256 bits). -/
  seed : Seed
  /-- Deterministic key expansion: derive group generators from the seed. -/
  expand : Seed → CanonicalForm G X
  /-- Deterministic group-element derivation from seed and a counter. -/
  sampleGroup : Seed → ℕ → G
```

**Design rationale:**

- `expand` captures the one-time key expansion (seed -> QC code -> PAut(C_0) ->
  SGS -> canonical form). This is a heavyweight computation performed once at
  key generation time; the result is cached for all subsequent operations.
- `sampleGroup` captures the PRF-based group-element derivation for encryption.
  Given the seed and a nonce (natural number counter), it deterministically
  produces a group element. In implementation, this would be a PRF (e.g.,
  HMAC-SHA3) applied to (seed || nonce), with the output mapped to a group
  element via the Schreier-Sims transversal representation.
- The seed is the minimal secret; everything else is derived. This mirrors
  the standard practice in symmetric cryptography where the key is a short
  random string and all internal state is expanded from it.

**Exit criteria:** Structure type-checks. `lake build Orbcrypt.KeyMgmt.SeedKey`
succeeds with zero warnings.

---

#### 9.2 — Seed-Key Correctness

**Effort:** 3h | **File:** `KeyMgmt/SeedKey.lean` | **Deps:** 9.1, Phase 7

```lean
theorem seed_kem_correctness (sk : SeedKey Seed G X) (kem : OrbitKEM G X K)
    (hExpand : sk.expand sk.seed = kem.canonForm) (n : ℕ) :
    decaps kem (encaps kem (sk.sampleGroup sk.seed n)).1 =
    (encaps kem (sk.sampleGroup sk.seed n)).2
```

Follows directly from `kem_correctness` — seed expansion does not affect
the correctness argument.

**Exit criteria:** Theorem compiles.

---

#### 9.3 — QC Code Key Expansion Specification

**Effort:** 3h | **File:** `KeyMgmt/SeedKey.lean` | **Deps:** 9.1

Prop-valued specification (not executable) of the 7-stage HGOE pipeline:

```lean
structure HGOEKeyExpansion (n b ℓ : ℕ) where
  param_valid : n = b * ℓ
  code_dim : ℕ
  code_valid : code_dim ≤ n
  group_order_log : ℕ
  group_large_enough : group_order_log ≥ 128
  weight : ℕ
  reps_same_weight : ∀ m, hammingWeight (reps m) = weight
```

**Exit criteria:** Specification structure type-checks.

---

#### 9.4 — Nonce-Based Encryption Definition

**Effort:** 3h | **File:** `KeyMgmt/Nonce.lean` | **Deps:** 9.1, Phase 7

```lean
def nonceEncaps (sk : SeedKey Seed G X) (kem : OrbitKEM G X K)
    (nonce : ℕ) : X × K :=
  encaps kem (sk.sampleGroup sk.seed nonce)
```

Correctness follows from `kem_correctness`:

```lean
theorem nonce_encaps_correct (sk : SeedKey Seed G X) (kem : OrbitKEM G X K)
    (nonce : ℕ) :
    decaps kem (nonceEncaps sk kem nonce).1 = (nonceEncaps sk kem nonce).2 :=
  kem_correctness kem (sk.sampleGroup sk.seed nonce)
```

**Exit criteria:** Definition and correctness lemma compile.

---

#### 9.5 — Nonce-Misuse Resistance Property

**Effort:** 2h | **File:** `KeyMgmt/Nonce.lean` | **Deps:** 9.4

```lean
theorem nonce_reuse_deterministic (sk : SeedKey Seed G X)
    (kem : OrbitKEM G X K) (nonce : ℕ) :
    nonceEncaps sk kem nonce = nonceEncaps sk kem nonce := rfl
```

Warning theorem about cross-base-point nonce reuse:

```lean
theorem nonce_reuse_leaks_orbit (sk : SeedKey Seed G X)
    (kem₁ kem₂ : OrbitKEM G X K) (nonce : ℕ)
    (hDiffOrbit : MulAction.orbit G kem₁.basePoint ≠
                  MulAction.orbit G kem₂.basePoint) :
    (nonceEncaps sk kem₁ nonce).1 ≠ (nonceEncaps sk kem₂ nonce).1 ∨
    MulAction.orbit G (nonceEncaps sk kem₁ nonce).1 ≠
    MulAction.orbit G (nonceEncaps sk kem₂ nonce).1 :=
  sorry -- Requires orbit separation argument
```

**Exit criteria:** Deterministic lemma compiles; leakage warning stated.

---

#### 9.6 — Key Size Analysis

**Effort:** 2h | **File:** `KeyMgmt/SeedKey.lean` | **Deps:** 9.1

```lean
theorem seed_determines_key (sk₁ sk₂ : SeedKey Seed G X)
    (hSeed : sk₁.seed = sk₂.seed)
    (hExpand : sk₁.expand = sk₂.expand)
    (hSample : sk₁.sampleGroup = sk₂.sampleGroup) :
    ∀ n : ℕ, sk₁.sampleGroup sk₁.seed n = sk₂.sampleGroup sk₂.seed n := by
  intro n; rw [hSeed, hSample]
```

Module docstring documents: seed = 256 bits vs SGS = O(n² log|G|) ≈ 15M bits.

**Exit criteria:** Lemma compiles; size comparison documented.

---

#### 9.7 — Backward Compatibility: Unkeyed → Seed-Keyed

**Effort:** 3h | **File:** `KeyMgmt/SeedKey.lean` | **Deps:** 9.1, Phase 3

```lean
def OrbitEncScheme.toSeedKey (scheme : OrbitEncScheme G X M)
    (sampleG : Unit → ℕ → G) : SeedKey Unit G X where
  seed := ()
  expand := fun () => scheme.canonForm
  sampleGroup := sampleG ()
```

Trivial embedding proving the seed-key model generalizes the existing model.

**Exit criteria:** Definition type-checks.

---

## Internal Dependency Graph

```
            9.1 (SeedKey)
           / |  \      \
         /   |    \      \
      9.2  9.3   9.6    9.7
      (Correct) (Spec) (Size) (Compat)
         |
      9.4 (Nonce)
         |
      9.5 (Misuse)
```

---

## Risk Analysis

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| `SeedKey` structure too abstract | Low | Low | Keep fields generic |
| Nonce leakage sorry hard to fill | Medium | Low | Document as known limitation |
| QC expansion spec doesn't type-check | Low | Medium | Adjust field types |

---

## Phase Exit Criteria

1. `KeyMgmt/SeedKey.lean` compiles with `SeedKey`, `HGOEKeyExpansion`.
2. `KeyMgmt/Nonce.lean` compiles with `nonceEncaps`, `nonce_encaps_correct`.
3. `seed_kem_correctness` has zero `sorry`.
4. `nonce_encaps_correct` has zero `sorry`.
5. Key size comparison documented in module docstring.

---

## Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 9.1 | Seed-Based Key Def | `KeyMgmt/SeedKey.lean` | 2h | Phase 7 |
| 9.2 | Seed-Key Correctness | `KeyMgmt/SeedKey.lean` | 3h | 9.1, Phase 7 |
| 9.3 | QC Key Expansion Spec | `KeyMgmt/SeedKey.lean` | 3h | 9.1 |
| 9.4 | Nonce-Based Encryption | `KeyMgmt/Nonce.lean` | 3h | 9.1, Phase 7 |
| 9.5 | Nonce-Misuse Properties | `KeyMgmt/Nonce.lean` | 2h | 9.4 |
| 9.6 | Key Size Analysis | `KeyMgmt/SeedKey.lean` | 2h | 9.1 |
| 9.7 | Backward Compatibility | `KeyMgmt/SeedKey.lean` | 3h | 9.1, Phase 3 |
