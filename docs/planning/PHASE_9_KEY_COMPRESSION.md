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

The key expansion pipeline follows DEVELOPMENT.md section 6.2.1: a 256-bit
seed is stretched into a quasi-cyclic (QC) parity-check matrix H, the
permutation automorphism group PAut(C_0) is computed, a strong generating set
(SGS) is extracted via Schreier-Sims, and the canonical form function is built
from the SGS. This pipeline is specified (not implemented) in Lean as a
Prop-valued structure, allowing the formalization to reason about correctness
without depending on executable code generation.

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

Prove that seed-based encryption is correct when the expansion is faithful.
The key insight is that correctness depends only on group-action algebra —
the seed expansion is merely a key-derivation step that produces the same
`CanonicalForm` and group elements that the original scheme would use. If the
expansion faithfully produces a valid canonical form, the KEM correctness
theorem applies directly.

```lean
/-- If expansion produces a valid canonical form, seed-based encryption
    is correct for the derived KEM. -/
theorem seed_kem_correctness
    (sk : SeedKey Seed G X)
    (kem : OrbitKEM G X K)
    (hExpand : sk.expand sk.seed = kem.canonForm)
    (n : ℕ) :
    decaps kem (encaps kem (sk.sampleGroup sk.seed n)).1 =
    (encaps kem (sk.sampleGroup sk.seed n)).2
```

This follows directly from `kem_correctness` — the seed expansion does not
affect the correctness argument (which depends only on group-action algebra).
The proof strategy is:

1. Unfold `nonceEncaps` to expose the underlying `encaps`/`decaps` pair.
2. Apply `kem_correctness` to the group element `sk.sampleGroup sk.seed n`.
3. The hypothesis `hExpand` ensures the canonical form used by the seed-based
   scheme matches the one in the KEM, making the reduction seamless.

**Exit criteria:** Theorem compiles with zero `sorry`. `lake build
Orbcrypt.KeyMgmt.SeedKey` succeeds with zero warnings.

---

#### 9.3 — QC Code Key Expansion Specification

**Effort:** 3h | **File:** `KeyMgmt/SeedKey.lean` | **Deps:** 9.1

Specify (but do not implement in executable Lean) the QC code key expansion
pipeline from DEVELOPMENT.md section 6.2.1. This is a Prop-valued structure
that captures the properties any valid key expansion must satisfy, without
providing executable code. An implementation (e.g., in GAP or C) must satisfy
these properties to be considered a valid instantiation.

The 7-stage pipeline is:
1. **Parameter derivation:** compute n = b * l from the security parameter.
2. **Code generation:** use the seed to generate a quasi-cyclic [n,k]-code C_0.
3. **Automorphism computation:** compute PAut(C_0), the permutation automorphism
   group of C_0.
4. **SGS extraction:** compute a strong generating set for PAut(C_0) via
   Schreier-Sims.
5. **Canonical form construction:** build the canonical form function from the
   SGS (e.g., via McKay's algorithm or partition backtracking).
6. **Representative selection:** choose orbit representatives with uniform
   Hamming weight to defeat weight-based attacks.
7. **Validation:** verify that the group has sufficient order (>= 2^lambda)
   and all representatives have the same weight.

```lean
/-- Specification of the 7-stage HGOE key expansion pipeline.
    This is a SPECIFICATION (Prop-valued), not an executable function.
    An implementation must satisfy these properties. -/
structure HGOEKeyExpansion (n b ℓ : ℕ) (M : Type*) where
  /-- Stage 1: parameter derivation. -/
  param_valid : n = b * ℓ
  /-- Stage 2: code generation produces a valid [n,k]-code. -/
  code_dim : ℕ
  code_valid : code_dim ≤ n
  /-- Stage 3: automorphism group has sufficient order. -/
  group_order_log : ℕ
  group_large_enough : group_order_log ≥ 128 -- λ = 128
  /-- Orbit representatives (one per message). -/
  reps : M → Bitstring n
  /-- Stage 4: all representatives have the same weight. -/
  weight : ℕ
  reps_same_weight : ∀ m, hammingWeight (reps m) = weight
```

**Design notes:**
- The structure is intentionally incomplete — it captures the key
  *properties* without specifying the algorithms. This is the correct level
  of abstraction for a formal verification project: we verify that any
  implementation satisfying these properties yields a correct and secure
  scheme, without being tied to a specific implementation.
- `group_large_enough` uses `group_order_log >= 128` as a proxy for
  `|G| >= 2^128`. Storing the exact group order in a `Nat` is feasible
  but the logarithmic bound is cleaner for specification purposes.
- `reps_same_weight` references the Hamming weight defense from Phase 5
  (`hammingWeight_invariant` and `same_weight_not_separating`).

**Exit criteria:** Specification structure type-checks. `lake build
Orbcrypt.KeyMgmt.SeedKey` succeeds with zero warnings.

---

### Track B: Nonce-Based Encryption (9.4 -> 9.5)

Track B defines nonce-based deterministic encryption and characterizes its
misuse properties. It depends on 9.1 (SeedKey structure) and Phase 7
(OrbitKEM).

---

#### 9.4 — Nonce-Based Encryption Definition

**Effort:** 3h | **File:** `KeyMgmt/Nonce.lean` | **Deps:** 9.1, Phase 7

Define nonce-based deterministic encryption. Instead of requiring a fresh
uniformly random group element for each encryption, the group element is
derived deterministically from the seed and a nonce (natural number counter).
This eliminates the need for runtime randomness, making the scheme suitable
for embedded and constrained environments.

```lean
/-- Nonce-based KEM encapsulation: the group element is derived
    deterministically from the seed and a nonce, eliminating the
    need for runtime randomness. -/
def nonceEncaps (sk : SeedKey Seed G X) (kem : OrbitKEM G X K)
    (nonce : ℕ) : X × K :=
  encaps kem (sk.sampleGroup sk.seed nonce)
```

**Properties to prove:**

- **Correctness:** `decaps kem (nonceEncaps sk kem nonce).1 = (nonceEncaps sk kem nonce).2`
  This follows directly from `kem_correctness` — the nonce-based derivation
  does not change the group-action algebra that makes decapsulation work.
- **Nonce-misuse detection:** Different nonces produce different ciphertexts,
  provided `sampleGroup` is injective in the nonce argument. This is stated
  as a hypothesis (injectivity of the PRF), not proved (since the PRF is
  not implemented in Lean).

**Proof strategy:**
1. Unfold `nonceEncaps` to expose `encaps kem (sk.sampleGroup sk.seed nonce)`.
2. Apply `kem_correctness` with `g := sk.sampleGroup sk.seed nonce`.
3. The correctness proof is immediate — the nonce derivation is transparent
   to the KEM correctness argument.

**Exit criteria:** Definition and correctness lemma compile with zero `sorry`.
`lake build Orbcrypt.KeyMgmt.Nonce` succeeds with zero warnings.

---

#### 9.5 — Nonce-Misuse Resistance Property

**Effort:** 2h | **File:** `KeyMgmt/Nonce.lean` | **Deps:** 9.4

State the nonce-misuse property: reusing a nonce leaks whether the same
base point was used, but does NOT leak the key beyond what was already
derivable. This is an important security characterization — nonce-based
schemes must document their behavior under misuse.

**Deterministic reuse (same nonce, same base point):**

Reusing a nonce with the same base point produces identical ciphertexts.
This is the expected behavior for a deterministic encryption scheme — it
leaks that the same plaintext was encrypted twice, but reveals nothing
beyond the repeated ciphertext.

```lean
/-- Nonce reuse with the same base point produces identical ciphertexts
    (deterministic — no new information leaks beyond the repeated ciphertext). -/
theorem nonce_reuse_deterministic (sk : SeedKey Seed G X)
    (kem : OrbitKEM G X K) (nonce : ℕ) :
    nonceEncaps sk kem nonce = nonceEncaps sk kem nonce := rfl
```

**Cross-base-point reuse (same nonce, different base points):**

The more interesting (and dangerous) case is nonce reuse across different
base points — i.e., encrypting under different KEMs (or different orbit
representatives) with the same nonce. In this case, the ciphertexts may
reveal whether the base points are in the same orbit, which is precisely
the information the scheme is designed to hide.

```lean
/-- WARNING: Nonce reuse across different base points reveals orbit
    membership. If base points are in different orbits, ciphertexts
    are in different orbits (group action preserves orbits). -/
theorem nonce_reuse_preserves_orbit_separation (sk : SeedKey Seed G X)
    (kem₁ kem₂ : OrbitKEM G X K) (nonce : ℕ)
    (hDiffOrbit : MulAction.orbit G kem₁.basePoint ≠
                  MulAction.orbit G kem₂.basePoint) :
    MulAction.orbit G (nonceEncaps sk kem₁ nonce).1 ≠
    MulAction.orbit G (nonceEncaps sk kem₂ nonce).1 := by
  -- nonceEncaps produces g • basePoint, in same orbit as basePoint
  -- MulAction.orbit_smul : orbit G (g • x) = orbit G x
  simp only [nonceEncaps, encaps]
  rwa [MulAction.orbit_smul, MulAction.orbit_smul]
```

**Design notes on the `sorry`:**
- This theorem requires an orbit separation argument: if two base points
  are in different orbits, then applying the same group element to each
  produces elements in different orbits (since orbits are preserved under
  group action). The proof requires showing that the first components of
  the two encapsulations land in different orbits.
- The `sorry` is acceptable at the specification stage. It will be resolved
  in Phase 16 (Formal Verification of New Components) when all new modules
  are audited for `sorry` elimination.
- The disjunction form (`!=` or orbit mismatch) is intentional — it
  captures the two ways the leakage manifests without committing to which
  one holds in general.

**Exit criteria:** Deterministic lemma compiles (zero `sorry`). Leakage
warning theorem is stated (one `sorry` — documented and tracked for
Phase 16 resolution). `lake build Orbcrypt.KeyMgmt.Nonce` succeeds with
zero warnings.

---

### Track C: Analysis & Compatibility (9.6, 9.7)

Track C provides the key size analysis and backward compatibility bridge.
These units depend on 9.1 (SeedKey structure) and can proceed in parallel
with Tracks A and B once 9.1 is complete.

---

#### 9.6 — Key Size Analysis

**Effort:** 2h | **File:** `KeyMgmt/SeedKey.lean` | **Deps:** 9.1

Document and formally state the key size comparison. The central claim is
that the seed determines the full key material: two `SeedKey` instances with
the same seed, expansion function, and sample function produce identical
encryption behavior.

This is a structural property, not a deep cryptographic result — but it
is important for ensuring that key management protocols can treat the seed
as the sole secret, and that key agreement protocols need only exchange
256 bits rather than ~1.8 MB.

**Key size comparison (documented in module docstring):**

| Component | Naive (SGS) | Seed-Based |
|-----------|-------------|------------|
| Secret key | ~1.8 MB (SGS for PAut(C_0)) | 256 bits |
| Key expansion | None (key IS the SGS) | One-time: seed -> QC code -> PAut -> SGS -> canon |
| Per-encryption | Sample g uniformly from G | PRF(seed, nonce) -> g |
| Compression ratio | 1x | ~56,000x |

```lean
/-- The seed key representation is compact.
    For HGOE with λ=128: seed = 256 bits, versus
    SGS = O(n² log|G|) ≈ 15 million bits.

    This theorem states that the seed determines the full key material. -/
theorem seed_determines_key (sk₁ sk₂ : SeedKey Seed G X)
    (hSeed : sk₁.seed = sk₂.seed)
    (hExpand : sk₁.expand = sk₂.expand)
    (hSample : sk₁.sampleGroup = sk₂.sampleGroup) :
    ∀ n : ℕ, sk₁.sampleGroup sk₁.seed n = sk₂.sampleGroup sk₂.seed n := by
  intro n; rw [hSeed, hSample]
```

**Proof strategy:** Direct rewriting. The hypotheses `hSeed` and `hSample`
together force `sk₁.sampleGroup sk₁.seed n = sk₂.sampleGroup sk₂.seed n`
by substitution. This is a definitional consequence of functional
extensionality on the seed and sample function.

**Exit criteria:** Lemma compiles with zero `sorry`. Module docstring
documents the key size comparison table. `lake build Orbcrypt.KeyMgmt.SeedKey`
succeeds with zero warnings.

---

#### 9.7 — Backward Compatibility: Unkeyed -> Seed-Keyed

**Effort:** 3h | **File:** `KeyMgmt/SeedKey.lean` | **Deps:** 9.1, Phase 3

Show that the existing `OrbitEncScheme` can be wrapped in a `SeedKey`. This
is a trivial embedding that proves the seed-key model generalizes the
existing model — any `OrbitEncScheme` is a special case of `SeedKey` where
the "seed" is `Unit` (carrying no information) and the expansion function
is the identity (returning the scheme's own canonical form).

This bridge is important for two reasons:
1. **Theorem reuse:** All existing theorems about `OrbitEncScheme`
   (correctness, invariant attack, OIA implies CPA) remain valid as special
   cases of the seed-key framework.
2. **Migration path:** Existing code can adopt the seed-key interface
   incrementally, wrapping old schemes before implementing true seed-based
   key expansion.

```lean
/-- Any OrbitEncScheme can be trivially wrapped in a SeedKey where the
    "seed" is the entire scheme and expansion is the identity. -/
def OrbitEncScheme.toSeedKey (scheme : OrbitEncScheme G X M)
    (sampleG : Unit → ℕ → G) : SeedKey Unit G X where
  seed := ()
  expand := fun () => scheme.canonForm
  sampleGroup := sampleG ()
```

**Design notes:**
- The `sampleG` parameter is necessary because `OrbitEncScheme` does not
  include a group-element sampling function — it takes `g` as an explicit
  parameter to `encrypt`. The bridge requires the caller to provide a
  sampling strategy, which is then baked into the `SeedKey`.
- The seed type is `Unit` because the original scheme has no compressed
  key — the "seed" carries no information. This is the degenerate case
  of seed-based keying where the compression ratio is 1x.
- The expansion function `fun () => scheme.canonForm` simply returns the
  scheme's own canonical form, which was already computed at scheme
  construction time.

**Exit criteria:** Definition type-checks with zero `sorry`. `lake build
Orbcrypt.KeyMgmt.SeedKey` succeeds with zero warnings.

---

## Internal Dependency Graph

```
                     9.1 (SeedKey Definition)
                    /        |        \
                   /         |         \
          9.2 (Correct)  9.4 (Nonce)  9.6 (Key Size)
            |              |              |
          9.3 (QC Spec)  9.5 (Misuse)  9.7 (Bridge)
```

**Track breakdown:**

- **Track A** (Seed-Key Model): 9.1 -> 9.2 -> 9.3 (8h sequential)
- **Track B** (Nonce-Based Encryption): 9.1 -> 9.4 -> 9.5 (5h sequential)
- **Track C** (Analysis & Compatibility): 9.1 -> 9.6, 9.1 -> 9.7 (5h, parallelizable)

**Critical path:** 9.1 -> 9.2 -> 9.3 (8h) — Track A is the longest
sequential chain.

**Maximum parallelism:** After 9.1 completes (2h), all three tracks can
proceed simultaneously. Tracks B and C are independent of each other and
of the later units in Track A.

**External dependencies:**

```
Phase 2 (CanonicalForm)
    |
Phase 7 (OrbitKEM, encaps, decaps, kem_correctness)
    |
    v
9.1 (SeedKey) -----> 9.2 -----> 9.3
    |                               
    +---------------> 9.4 -----> 9.5
    |
    +---------------> 9.6
    |
    +---> Phase 3 --> 9.7
```

---

## Parallelism Notes

- **Phase 8 and Phase 9 are independent.** Phase 8 (Probabilistic
  Foundations) builds on Phases 1-6 and does not use any Phase 7 artifacts.
  Phase 9 builds on Phase 7 but does not use any probability machinery.
  The two phases can run concurrently, which is important for schedule
  optimization since Phase 8 is the most time-consuming phase (~40h).

- **Within Phase 9,** maximum parallelism is achieved after 9.1 completes:
  - Agent 1: Track A (9.2, 9.3) — `KeyMgmt/SeedKey.lean` (correctness, spec)
  - Agent 2: Track B (9.4, 9.5) — `KeyMgmt/Nonce.lean` (nonce, misuse)
  - Agent 3: Track C (9.6, 9.7) — `KeyMgmt/SeedKey.lean` (analysis, bridge)

  Note: Tracks A and C both write to `SeedKey.lean`, so they cannot be
  parallelized via background agents that write to the same file. Either
  run them sequentially or have Track C wait until Track A finishes its
  writes.

- **Phase 10 (AEAD) depends on Phase 9.** Phase 10 cannot begin until
  Phase 9 is complete, as it builds on the nonce-based encryption
  interface.

---

## Risk Analysis

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| `SeedKey` structure has universe-level issues with `Seed` type parameter | Low | Medium | Use explicit universe annotations; keep `Seed : Type*` unless a concrete type is needed |
| `seed_kem_correctness` proof blocked by definitional mismatch between `expand` output and `kem.canonForm` | Medium | Medium | Ensure `hExpand` hypothesis bridges any definitional gap; use `simp` or `conv` to normalize |
| `HGOEKeyExpansion` references `hammingWeight` and `reps` which may not be in scope | Medium | Low | Import `Construction.Permutation` and `Crypto.Scheme`; parameterize `reps` as a field if needed |
| `nonceEncaps` correctness requires `kem_correctness` to accept arbitrary `g : G` | Low | Low | Phase 7's `kem_correctness` is already parametric in `g`; no issue expected |
| `nonce_reuse_leaks_orbit` proof is non-trivial and may require orbit separation lemmas not yet available | High | Medium | Accept `sorry` for now; track for Phase 16 resolution; add helper lemma `smul_orbit_eq` to `GroupAction/Basic.lean` if needed |
| `OrbitEncScheme.toSeedKey` has type mismatch between `OrbitEncScheme G X M` and `SeedKey Unit G X` (the `M` parameter disappears) | Low | Medium | The bridge intentionally drops `M` — the seed-key model does not parameterize by message type. Document this design choice |
| Lean `noncomputable` propagation from `CanonicalForm` contaminates `SeedKey` | Medium | Low | Mark `SeedKey` fields as `noncomputable` where needed; this does not affect proof validity |

---

## Phase Exit Criteria

All of the following must hold before Phase 9 is considered complete:

1. **Module compilation:**
   - `lake build Orbcrypt.KeyMgmt.SeedKey` succeeds with zero warnings.
   - `lake build Orbcrypt.KeyMgmt.Nonce` succeeds with zero warnings.

2. **Structure definitions:**
   - `SeedKey` structure type-checks with `seed`, `expand`, and `sampleGroup`
     fields.
   - `HGOEKeyExpansion` specification structure type-checks with all
     required fields.

3. **Theorems (zero sorry):**
   - `seed_kem_correctness` compiles with zero `sorry`.
   - `nonce_reuse_deterministic` compiles with zero `sorry` (proof: `rfl`).
   - `seed_determines_key` compiles with zero `sorry`.

4. **Theorems (tracked sorry):**
   - `nonce_reuse_leaks_orbit` is stated with one `sorry` — documented
     and tracked for Phase 16 resolution. This is the only acceptable
     `sorry` in Phase 9.

5. **Definitions:**
   - `nonceEncaps` definition compiles and produces the correct type
     `X x K`.
   - `OrbitEncScheme.toSeedKey` definition compiles and wraps an existing
     scheme in the seed-key interface.

6. **Axiom audit:**
   - `#print axioms seed_kem_correctness` shows only standard Lean axioms
     (propext, Classical.choice, Quot.sound) — no custom axioms.
   - `#print axioms seed_determines_key` shows only standard Lean axioms.
   - No `axiom` declarations in either `SeedKey.lean` or `Nonce.lean`.

7. **Documentation:**
   - Both files have `/-! ... -/` module docstrings.
   - All public definitions and theorems have `/-- ... -/` docstrings.
   - Key size comparison table documented in `SeedKey.lean` module docstring.

8. **Integration:**
   - `Orbcrypt.lean` root import file updated to import both new modules.
   - `lake build` (default target) succeeds after root import update.

---

## Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 9.1 | Seed-Based Key Definition | `KeyMgmt/SeedKey.lean` | 2h | Phase 7 |
| 9.2 | Seed-Key Correctness | `KeyMgmt/SeedKey.lean` | 3h | 9.1, Phase 7 |
| 9.3 | QC Key Expansion Spec | `KeyMgmt/SeedKey.lean` | 3h | 9.1 |
| 9.4 | Nonce-Based Encryption | `KeyMgmt/Nonce.lean` | 3h | 9.1, Phase 7 |
| 9.5 | Nonce-Misuse Properties | `KeyMgmt/Nonce.lean` | 2h | 9.4 |
| 9.6 | Key Size Analysis | `KeyMgmt/SeedKey.lean` | 2h | 9.1 |
| 9.7 | Backward Compatibility | `KeyMgmt/SeedKey.lean` | 3h | 9.1, Phase 3 |

**Total effort:** ~18 hours across 7 work units.

**Files created:** 2 new Lean modules (`KeyMgmt/SeedKey.lean`, `KeyMgmt/Nonce.lean`).

**Files modified:** 1 existing file (`Orbcrypt.lean` — add root imports).

**Sorry budget:** 1 tracked `sorry` in `nonce_reuse_leaks_orbit` (9.5),
scheduled for resolution in Phase 16.

**Key deliverables:**
- `SeedKey` structure reducing key size from ~1.8 MB to 256 bits
- `nonceEncaps` function eliminating runtime randomness
- `seed_kem_correctness` proving the compressed key preserves correctness
- `HGOEKeyExpansion` specifying the concrete key expansion pipeline
- `OrbitEncScheme.toSeedKey` backward compatibility bridge
