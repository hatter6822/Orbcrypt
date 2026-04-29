/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.KeyMgmt.SeedKey

/-!
# Orbcrypt.KeyMgmt.Nonce

Nonce-based deterministic encryption for Orbcrypt: replaces random group-element
sampling with deterministic derivation from a seed and nonce, eliminating the
need for runtime randomness.

## Motivation

Standard Orbcrypt encryption requires sampling a uniformly random group element
`g ∈ G` for each encapsulation. This demands a cryptographically secure random
number generator (CSRNG) at encryption time, which may not be available in all
deployment environments (embedded systems, deterministic protocols).

Nonce-based encryption derives `g` deterministically from the seed key and a
nonce (counter): `g = sampleGroup(seed, nonce)`. This:
1. Eliminates the need for runtime randomness.
2. Makes encryption deterministic and reproducible (for a given seed + nonce).
3. Enables key/ciphertext pre-computation in batch scenarios.

## Security considerations

**Nonce reuse is safe within a single KEM** — reusing a nonce produces the
same ciphertext and key (deterministic, no new information leaks).

**Nonce reuse across different KEMs is dangerous** — if two KEMs have base
points in different orbits, the ciphertexts are in different orbits, leaking
orbit membership. The `nonce_reuse_leaks_orbit` theorem formalizes this warning.

## Main definitions

* `Orbcrypt.nonceEncaps` — nonce-based KEM encapsulation
* `Orbcrypt.nonceDecaps` — nonce-based KEM decapsulation (same as standard)
* `Orbcrypt.nonce_encaps_correctness` — decaps recovers the encapsulated key
* `Orbcrypt.nonce_reuse_deterministic` — same nonce → same output
* `Orbcrypt.nonce_reuse_leaks_orbit` — cross-KEM nonce reuse leaks orbit info

## References

* DEVELOPMENT.md §6.2.2 — nonce-based encryption
* formalization/PRACTICAL_IMPROVEMENTS_PLAN.md — Phase 9, work units 9.4–9.5
-/

namespace Orbcrypt

variable {Seed : Type*} {G : Type*} {X : Type*} {K : Type*}

-- ============================================================================
-- Work Unit 9.4: Nonce-Based Encryption Definition
-- ============================================================================

/--
Nonce-based KEM encapsulation: the group element is derived deterministically
from the seed and a nonce, eliminating the need for runtime randomness.

`nonceEncaps sk kem nonce` computes the group element `g = sampleGroup(seed, nonce)`
and then performs standard KEM encapsulation `encaps kem g`.

**Parameters:**
- `sk`: the seed-based key (contains the seed and sampling function)
- `kem`: the KEM to encapsulate with
- `nonce`: a counter or unique value for this encapsulation

**Returns:** A pair `(ciphertext, shared_key)`, identical to `encaps`.

**Security note:** Each nonce should be used at most once with a given
(seed, KEM) pair to maintain IND-CPA security. Nonce reuse within the same
KEM is safe (deterministic repetition) but wasteful. Nonce reuse across
different KEMs may leak orbit membership (see `nonce_reuse_leaks_orbit`).
-/
def nonceEncaps
    [Fintype Seed] [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (sk : SeedKey Seed G X) (kem : OrbitKEM G X K)
    (nonce : ℕ) : X × K :=
  encaps kem (sk.sampleGroup sk.seed nonce)

/--
Nonce-based KEM decapsulation. Identical to standard `decaps` — the nonce
is not needed for decapsulation because the canonical form recovers the
key from any orbit element.
-/
def nonceDecaps [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (c : X) : K :=
  decaps kem c

-- Simp lemmas for unfolding nonce-based operations in proofs

/-- Unfold nonce encapsulation to standard encapsulation with derived group element. -/
@[simp]
theorem nonceEncaps_eq
    [Fintype Seed] [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (sk : SeedKey Seed G X) (kem : OrbitKEM G X K) (nonce : ℕ) :
    nonceEncaps sk kem nonce = encaps kem (sk.sampleGroup sk.seed nonce) := rfl

/-- Unfold nonce decapsulation to standard decapsulation. -/
@[simp]
theorem nonceDecaps_eq [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (c : X) :
    nonceDecaps kem c = decaps kem c := rfl

/-- Unfold the ciphertext component of nonce encapsulation. -/
@[simp]
theorem nonceEncaps_fst
    [Fintype Seed] [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (sk : SeedKey Seed G X) (kem : OrbitKEM G X K) (nonce : ℕ) :
    (nonceEncaps sk kem nonce).1 = sk.sampleGroup sk.seed nonce • kem.basePoint := rfl

/-- Unfold the key component of nonce encapsulation. -/
@[simp]
theorem nonceEncaps_snd
    [Fintype Seed] [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (sk : SeedKey Seed G X) (kem : OrbitKEM G X K) (nonce : ℕ) :
    (nonceEncaps sk kem nonce).2 =
    kem.keyDerive (kem.canonForm.canon
      (sk.sampleGroup sk.seed nonce • kem.basePoint)) := rfl

-- ============================================================================
-- Nonce-Based KEM Correctness
-- ============================================================================

/--
**Nonce-Based KEM Correctness.** Decapsulation recovers the key from a
nonce-based encapsulation.

This follows directly from `kem_correctness` — the deterministic derivation
of the group element does not affect correctness (which depends only on
canonical form invariance under the group action).
-/
theorem nonce_encaps_correctness
    [Fintype Seed] [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (sk : SeedKey Seed G X) (kem : OrbitKEM G X K) (nonce : ℕ) :
    nonceDecaps kem (nonceEncaps sk kem nonce).1 =
    (nonceEncaps sk kem nonce).2 :=
  -- Unfold to kem_correctness with g = sampleGroup(seed, nonce)
  kem_correctness kem (sk.sampleGroup sk.seed nonce)

-- ============================================================================
-- Work Unit 9.5: Nonce-Misuse Resistance Properties
-- ============================================================================

/--
**Nonce Reuse Determinism.** Two seed keys with the same seed and sampling
function produce identical encapsulations for the same nonce and KEM.

This is the defining property of deterministic encryption: the output is
fully determined by (seed, sampleGroup, kem, nonce). No new information
leaks from a repeated nonce because the output is exactly the same. The
adversary learns nothing beyond what the first encapsulation already revealed.
-/
theorem nonce_reuse_deterministic
    [Fintype Seed] [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (sk₁ sk₂ : SeedKey Seed G X)
    (hSeed : sk₁.seed = sk₂.seed)
    (hSample : sk₁.sampleGroup = sk₂.sampleGroup)
    (kem : OrbitKEM G X K) (nonce : ℕ) :
    nonceEncaps sk₁ kem nonce = nonceEncaps sk₂ kem nonce := by
  -- Both encapsulations use the same group element when seeds and samplers match
  simp only [nonceEncaps_eq, hSeed, hSample]

/--
**Distinct Nonces with Injective Sampling Produce Distinct Group Elements.**

If the seed-key's `sampleGroup` function is injective in the nonce parameter
(a standard PRF requirement), then distinct nonces yield distinct group elements.
This is the foundation for security: each encapsulation uses a "fresh" group
element, preventing replay attacks.
-/
theorem distinct_nonces_distinct_elements
    [Fintype Seed] [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (sk : SeedKey Seed G X)
    (hInj : Function.Injective (sk.sampleGroup sk.seed))
    (n₁ n₂ : ℕ) (hne : n₁ ≠ n₂) :
    sk.sampleGroup sk.seed n₁ ≠ sk.sampleGroup sk.seed n₂ := by
  -- Injective functions map distinct inputs to distinct outputs
  exact fun h => hne (hInj h)

/--
**WARNING: Nonce Reuse Across Different KEMs Leaks Orbit Membership.**

If two KEMs have base points in different orbits, then nonce-based
encapsulations under the same nonce produce ciphertexts in different orbits.
An adversary observing both ciphertexts can detect that they came from
different orbits (by comparing canonical forms or applying any G-invariant
function).

This is the formal statement of the nonce-misuse vulnerability: cross-KEM
nonce reuse breaks orbit indistinguishability.

**Proof strategy:**
- The ciphertexts are `g • bp₁` and `g • bp₂` for the same `g`.
- Since `orbit G (g • x) = orbit G x` (group action preserves orbits),
  the ciphertexts are in the same orbits as their respective base points.
- By hypothesis, the base points are in different orbits.
- Therefore the ciphertexts are in different orbits.
-/
theorem nonce_reuse_leaks_orbit
    [Fintype Seed] [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (sk : SeedKey Seed G X) (kem₁ kem₂ : OrbitKEM G X K)
    (nonce : ℕ)
    (hDiffOrbit : MulAction.orbit G kem₁.basePoint ≠
                  MulAction.orbit G kem₂.basePoint) :
    MulAction.orbit G (nonceEncaps sk kem₁ nonce).1 ≠
    MulAction.orbit G (nonceEncaps sk kem₂ nonce).1 := by
  -- Ciphertexts are g • bp₁ and g • bp₂ where g = sampleGroup(seed, nonce)
  simp only [nonceEncaps_fst]
  -- Group action preserves orbits: orbit G (g • x) = orbit G x
  rw [orbit_eq_of_smul, orbit_eq_of_smul]
  -- The base points are in different orbits by hypothesis
  exact hDiffOrbit

/--
**Nonce-based encapsulation produces ciphertexts in the base point's orbit.**
The ciphertext `g • basePoint` is always in the orbit of `basePoint`.
-/
theorem nonceEncaps_mem_orbit
    [Fintype Seed] [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (sk : SeedKey Seed G X) (kem : OrbitKEM G X K) (nonce : ℕ) :
    (nonceEncaps sk kem nonce).1 ∈ MulAction.orbit G kem.basePoint := by
  simp only [nonceEncaps_fst]
  exact smul_mem_orbit (sk.sampleGroup sk.seed nonce) kem.basePoint

end Orbcrypt
