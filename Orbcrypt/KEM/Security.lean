/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.KEM.Encapsulate
import Orbcrypt.GroupAction.Invariant

/-!
# Orbcrypt.KEM.Security

KEM security definitions and the main security theorem: KEMOIA implies
KEM security. Covers adversary structure, advantage definition, the
KEM variant of OIA, and the security reduction.

## Overview

This module defines the security game for the Orbit KEM and proves
that the KEM-OIA assumption implies security. The proof proceeds in three
steps:

1. **Key constancy** (7.6a): the derived key is the same for all group
   elements. Proved unconditionally from `canonical_isGInvariant` by
   `kem_key_constant_direct` — no `KEMOIA` extraction needed. (Pre-L5
   this step was split between `kem_key_constant` and
   `kem_key_constant_direct`; the former is deleted post-L5 because
   it was strictly redundant — see `KEMOIA`'s docstring.)
2. **Ciphertext indistinguishability** (7.6b): under `KEMOIA` (now
   single-conjunct post-L5), no function distinguishes orbit elements.
3. **Security assembly** (7.6c): combining the above to show no adversary
   has advantage.

## Design note: advantage definition

The advantage definition compares two different encapsulations (different
group elements), paralleling the structure of `hasAdvantage` in
`Crypto/Security.lean`. This captures the essential security property:
an adversary who observes an encapsulation (ciphertext, key) cannot
distinguish it from a different encapsulation. This is the natural
deterministic analogue of the IND-CCA KEM security game.

Phase 8 (Probabilistic Foundations) upgrades this to a probabilistic model
with real-vs-random key distinguishing.

## Main definitions and results

* `Orbcrypt.KEMAdversary` — adversary for the KEM security game
* `Orbcrypt.kemHasAdvantage` — adversary distinguishes two encapsulations
* `Orbcrypt.KEMIsSecure` — no adversary has advantage
* `Orbcrypt.KEMOIA` — KEM variant of the Orbit Indistinguishability Assumption
  (single-conjunct form since audit F-AUDIT-2026-04-21-M6 / Workstream L5:
  the earlier key-uniformity conjunct was redundant with
  `kem_key_constant_direct` — see the `KEMOIA` docstring).
* `Orbcrypt.kem_key_constant_direct` — derived key is constant across the orbit,
  proved directly from `canonical_isGInvariant` without any `KEMOIA` hypothesis.
  (The pre-L5 `kem_key_constant`, which extracted the second conjunct of
  `KEMOIA`, has been removed as an unnecessary shim; the direct form is the
  authoritative statement.)* `Orbcrypt.kemIsSecure_iff` — unfolding lemma for `KEMIsSecure`

W6.4 of structural review 2026-05-06 deleted the deterministic KEM
security reduction `kemoia_implies_secure` and the supporting lemma
`kem_ciphertext_indistinguishable`. The non-vacuous probabilistic
counterpart (`concrete_kemoia_uniform_implies_secure` in
`KEM/CompSecurity.lean`) carries the substantive ε-smooth KEM
security content.

## References

* docs/dev_history/formalization/PRACTICAL_IMPROVEMENTS_PLAN.md — work units 7.4, 7.5, 7.6
* Crypto/Security.lean — original AOE security definitions
* Crypto/OIA.lean — original OIA definition
* docs/dev_history/AUDIT_2026-04-21_WORKSTREAM_PLAN.md § 6 (K2) — rationale
  for omitting a `kemoia_implies_secure_distinct` corollary (audit
  finding F-AUDIT-2026-04-21-M1)
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*} {K : Type*}

-- ============================================================================
-- Work Unit 7.4a: KEMAdversary Structure
-- ============================================================================

/--
A deterministic adversary for the KEM security game.

The adversary receives the base point, the ciphertext, and a candidate key,
and outputs a bit. Like `Adversary` in `Crypto/Security.lean`, the adversary
is parameterized by `X` and `K` but NOT by `G` — it does not know the secret
group.
-/
structure KEMAdversary (X : Type*) (K : Type*) where
  /-- Guess based on observed encapsulation.
      Args: basePoint, ciphertext, derived key. -/
  guess : X → X → K → Bool

-- ============================================================================
-- Work Unit 7.4b: kemHasAdvantage Definition
-- ============================================================================

/--
An adversary "has advantage" against a KEM if there exist group elements
`g₀, g₁` such that the adversary's guess differs on the two encapsulations.

This parallels the structure of `hasAdvantage` for `OrbitEncScheme`:
different group elements produce different adversary outputs. Under KEMOIA,
the derived key is constant (by key constancy) and the ciphertext is
indistinguishable (by orbit indistinguishability), so no adversary can
have advantage.

**Deterministic abstraction:** Both encapsulations use the real derived key.
The adversary tries to distinguish which group element was used.
-/
def kemHasAdvantage [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (A : KEMAdversary X K) : Prop :=
  ∃ g₀ g₁ : G,
    A.guess kem.basePoint (g₀ • kem.basePoint)
      (kem.keyDerive (kem.canonForm.canon (g₀ • kem.basePoint))) ≠
    A.guess kem.basePoint (g₁ • kem.basePoint)
      (kem.keyDerive (kem.canonForm.canon (g₁ • kem.basePoint)))

-- ============================================================================
-- Work Unit 7.4c: KEMIsSecure Definition and Unfolding Lemma
-- ============================================================================

/--
A KEM is secure if no adversary has advantage: for all adversaries `A`,
`¬ kemHasAdvantage kem A`.

This is the deterministic analogue of: for all PPT adversaries,
the advantage is negligible.
-/
def KEMIsSecure [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) : Prop :=
  ∀ (A : KEMAdversary X K), ¬ kemHasAdvantage kem A

/--
Unfolding lemma for `KEMIsSecure`: the KEM is secure iff for every adversary
and every pair of group elements, the adversary's guess is the same on both
encapsulations.
-/
theorem kemIsSecure_iff [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) :
    KEMIsSecure kem ↔
    ∀ (A : KEMAdversary X K) (g₀ g₁ : G),
      A.guess kem.basePoint (g₀ • kem.basePoint)
        (kem.keyDerive (kem.canonForm.canon (g₀ • kem.basePoint))) =
      A.guess kem.basePoint (g₁ • kem.basePoint)
        (kem.keyDerive (kem.canonForm.canon (g₁ • kem.basePoint))) := by
  constructor
  · -- Forward: KEMIsSecure → universal equality
    intro hSecure A g₀ g₁
    by_contra h
    exact hSecure A ⟨g₀, g₁, h⟩
  · -- Backward: universal equality → KEMIsSecure
    intro hAll A ⟨g₀, g₁, hNeq⟩
    exact hNeq (hAll A g₀ g₁)

-- W6.8 of structural review 2026-05-06: the deterministic KEMOIA
-- Prop (formerly defined here, Work Unit 7.5) was deleted as part
-- of the deterministic-chain removal scheduled for v0.4.0. The
-- non-vacuous probabilistic counterpart `ConcreteKEMOIA_uniform`
-- (in `KEM/CompSecurity.lean`) carries the substantive ε-smooth
-- KEM-orbit indistinguishability content.

-- ============================================================================
-- Work Unit 7.6a: Key Constancy Lemma
-- ============================================================================

/--
Key constancy proved directly from `canonical_isGInvariant`, without
assuming any `KEMOIA` hypothesis. This is the authoritative form —
the previous extraction-from-`KEMOIA.2` variant was removed in
Workstream L5 along with the redundant second conjunct of `KEMOIA`.

The derived key is the same regardless of which group element was
used for encapsulation, because the canonical form is G-invariant
and `keyDerive` is deterministic.
-/
theorem kem_key_constant_direct [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (g : G) :
    kem.keyDerive (kem.canonForm.canon (g • kem.basePoint)) =
    kem.keyDerive (kem.canonForm.canon kem.basePoint) :=
  congr_arg kem.keyDerive (canonical_isGInvariant kem.canonForm g kem.basePoint)

-- ============================================================================
-- W6.4 of structural review 2026-05-06: the deterministic KEM
-- security reduction `kemoia_implies_secure` (Headline #5,
-- Work Unit 7.6c) and its supporting lemma
-- `kem_ciphertext_indistinguishable` (Work Unit 7.6b) were
-- deleted as part of the deterministic-chain removal scheduled
-- for v0.4.0. The non-vacuous probabilistic counterpart
-- (`concrete_kemoia_uniform_implies_secure`) carries the
-- substantive ε-smooth KEM security content.

-- W6.1 of structural review 2026-05-06: the deterministic-KEMOIA
-- vacuity witness `det_kemoia_false_of_nontrivial_orbit` (formerly
-- defined here, audit 2026-04-23 finding E-06) was deleted as part
-- of the deterministic-chain removal scheduled for v0.4.0. Historical
-- entry in `docs/dev_history/WORKSTREAM_CHANGELOG.md` under the
-- 2026-04-23 Workstream E section.

end Orbcrypt
