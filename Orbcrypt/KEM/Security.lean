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
   elements (provable from `canonical_isGInvariant`, also extractable from
   KEMOIA.2).
2. **Ciphertext indistinguishability** (7.6b): under KEMOIA, no function
   distinguishes orbit elements.
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
* `Orbcrypt.kem_key_constant` — derived key is constant (from KEMOIA.2)
* `Orbcrypt.kem_key_constant_direct` — same, proved from `canonical_isGInvariant`
* `Orbcrypt.kem_ciphertext_indistinguishable` — ciphertexts indistinguishable
* `Orbcrypt.kemoia_implies_secure` — **KEMOIA implies KEM security**
* `Orbcrypt.kemIsSecure_iff` — unfolding lemma for `KEMIsSecure`

## Design note — no distinct-challenge KEM variant (Workstream K)

Unlike the scheme-level security game (which carries both `IsSecure` and
`IsSecureDistinct` — the latter filtering out the degenerate
collision-choice `(m, m)` the classical IND-1-CPA challenger would
reject), the KEM game does not admit a parallel `_distinct` refinement.
`kemHasAdvantage` quantifies over two *group elements* `g₀, g₁ : G`
rather than two messages; encapsulation operates on the single
base point `kem.basePoint`, so every ciphertext lives in the same
orbit `orbit G kem.basePoint`. There is no per-message collision risk
at the KEM layer — see the extended note on `kemoia_implies_secure`
below for the full rationale.

## References

* formalization/PRACTICAL_IMPROVEMENTS_PLAN.md — work units 7.4, 7.5, 7.6
* Crypto/Security.lean — original AOE security definitions
* Crypto/OIA.lean — original OIA definition
* docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md § 6 (K2) — rationale
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

-- ============================================================================
-- Work Unit 7.5: KEM-OIA Definition
-- ============================================================================

/--
KEM variant of the Orbit Indistinguishability Assumption.

Two conjuncts:
1. **Orbit indistinguishability:** No Boolean function distinguishes orbit
   elements. This is the original OIA restricted to a single orbit.
2. **Key uniformity:** The derived key is the same for all orbit elements.
   This follows from canonical form G-invariance + deterministic `keyDerive`,
   so the second conjunct is provable from `canonical_isGInvariant`
   (see `kem_key_constant_direct`). It is included in the definition for
   convenient extraction in proofs.

**Strength:** Like the original `OIA`, the first conjunct quantifies over
ALL Boolean functions, making `KEMOIA` `False` for non-trivial schemes
(where the orbit has more than one element). The security theorem is
therefore vacuously true for such schemes — matching the original
`oia_implies_1cpa`. Phase 8 addresses this with probabilistic OIA.

**Why a `Prop` definition (not an `axiom`):** Same rationale as `OIA` in
`Crypto/OIA.lean` — a Lean `axiom` would assert KEMOIA for ALL group actions,
including trivial ones where the claim is provably false.
-/
def KEMOIA [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) : Prop :=
  (∀ (f : X → Bool) (g₀ g₁ : G),
    f (g₀ • kem.basePoint) = f (g₁ • kem.basePoint)) ∧
  (∀ (g : G), kem.keyDerive (kem.canonForm.canon (g • kem.basePoint)) =
    kem.keyDerive (kem.canonForm.canon kem.basePoint))

-- ============================================================================
-- Work Unit 7.6a: Key Constancy Lemma
-- ============================================================================

/--
Under KEMOIA, the derived key is the same regardless of which group element
was used for encapsulation.

This is a direct extraction from the second KEMOIA conjunct.
-/
theorem kem_key_constant [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (hOIA : KEMOIA kem) (g : G) :
    kem.keyDerive (kem.canonForm.canon (g • kem.basePoint)) =
    kem.keyDerive (kem.canonForm.canon kem.basePoint) :=
  hOIA.2 g

/--
Key constancy proved directly from `canonical_isGInvariant`, without
assuming KEMOIA. This demonstrates that the second conjunct of KEMOIA
is redundant — it is always provable from the structure of `OrbitKEM`.
-/
theorem kem_key_constant_direct [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (g : G) :
    kem.keyDerive (kem.canonForm.canon (g • kem.basePoint)) =
    kem.keyDerive (kem.canonForm.canon kem.basePoint) :=
  congr_arg kem.keyDerive (canonical_isGInvariant kem.canonForm g kem.basePoint)

-- ============================================================================
-- Work Unit 7.6b: Ciphertext Indistinguishability Lemma
-- ============================================================================

/--
Under KEMOIA, no Boolean function can distinguish orbit elements.

This is a direct extraction from the first KEMOIA conjunct.
-/
theorem kem_ciphertext_indistinguishable [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (hOIA : KEMOIA kem) (f : X → Bool) (g₀ g₁ : G) :
    f (g₀ • kem.basePoint) = f (g₁ • kem.basePoint) :=
  hOIA.1 f g₀ g₁

-- ============================================================================
-- Work Unit 7.6c: Main Security Theorem
-- ============================================================================

/--
**KEM Security Theorem.** KEMOIA implies KEM security.

If the KEM-OIA holds, no adversary can distinguish two different
encapsulations. This is the KEM analogue of `oia_implies_1cpa`.

**Proof strategy:**
1. Introduce adversary `A` and assume `kemHasAdvantage kem A`.
2. Destructure to get `g₀`, `g₁`, and the inequality `hNeq`.
3. Apply KEMOIA.2 (key constancy): both derived keys equal
   `keyDerive(canon(basePoint))`. Rewrite `hNeq` to use this constant key.
4. Apply KEMOIA.1 (orbit indistinguishability): the adversary's guess
   function (partially applied to `basePoint` and the constant key) is
   a Boolean function on `X`, so it must give the same value on
   `g₀ • basePoint` and `g₁ • basePoint`.
5. This equality contradicts `hNeq`.

**Axioms:** Zero custom axioms. `#print axioms kemoia_implies_secure` shows
only standard Lean axioms. KEMOIA appears as a hypothesis.

## No distinct-challenge KEM corollary required

At the scheme level, `Crypto/Security.lean` carries a second
`IsSecureDistinct` predicate because the underlying `Adversary.choose`
function may return a collision `(m, m)` on its two *message*
challenges — the classical IND-1-CPA game rejects such collisions
before sampling, so `IsSecure` and `IsSecureDistinct` differ (with
`IsSecure → IsSecureDistinct`, proved by
`isSecure_implies_isSecureDistinct`).

The KEM security game (`kemHasAdvantage` / `KEMIsSecure` above) does
**not** admit the analogous collision-choice gap. A `KEMAdversary`'s
two encapsulations are parameterised by *group elements* `g₀, g₁ : G`,
which are drawn by the challenger from `G` uniformly rather than
chosen by the adversary; there is only one base point (`kem.basePoint`),
so every ciphertext lies in the single orbit `orbit G kem.basePoint`.
No per-message distinctness filter applies. Therefore no
`kemoia_implies_secure_distinct` corollary is introduced — the
`Adversary`-level game asymmetry documented at `IsSecure` does not
surface at the KEM layer.

The probabilistic KEM advantage (`kemAdvantage_uniform` in
`KEM/CompSecurity.lean`) likewise uses a fixed reference group element
and measures distinguishing advantage between a uniform orbit
distribution and a point mass on that reference; it has no
challenge-distinctness obligation either. The bound
`concrete_kemoia_uniform_implies_secure` applies unconditionally to
every KEM adversary without distinctness filtering.
-/
theorem kemoia_implies_secure [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (hOIA : KEMOIA kem) : KEMIsSecure kem := by
  -- Introduce adversary and assume advantage for contradiction
  intro A ⟨g₀, g₁, hNeq⟩
  -- Step 1: Apply key constancy — both keys equal keyDerive(canon(basePoint))
  apply hNeq
  rw [hOIA.2 g₀, hOIA.2 g₁]
  -- Step 2: Apply orbit indistinguishability — guess is constant across orbit
  -- The function (fun c => A.guess basePoint c constant_key) is X → Bool
  exact hOIA.1 (fun c => A.guess kem.basePoint c
    (kem.keyDerive (kem.canonForm.canon kem.basePoint))) g₀ g₁

end Orbcrypt
