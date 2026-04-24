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
  authoritative statement.)
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

**Single-conjunct form (audit F-AUDIT-2026-04-21-M6 / Workstream L5,
2026-04-22).** Previously this definition carried a second "key
uniformity" conjunct asserting that the derived key is constant
across the orbit. That conjunct is **unconditionally provable** from
`canonical_isGInvariant` (see `kem_key_constant_direct` below) and
therefore contributed no assumption content. It has been dropped:
`KEMOIA kem` is now precisely the orbit-indistinguishability
predicate, and downstream proofs that previously extracted the
second conjunct (e.g., `kemoia_implies_secure`) now invoke
`kem_key_constant_direct` directly.

Semantic content: no Boolean function distinguishes orbit elements
(the original OIA restricted to a single orbit).

**Strength:** Like the original `OIA`, the quantification over ALL
Boolean functions makes `KEMOIA` `False` for non-trivial schemes
(where the orbit has more than one element). The security theorem
is therefore vacuously true for such schemes — matching the original
`oia_implies_1cpa`. Phase 8 addresses this with probabilistic OIA.

**Why a `Prop` definition (not an `axiom`):** Same rationale as `OIA`
in `Crypto/OIA.lean` — a Lean `axiom` would assert KEMOIA for ALL
group actions, including trivial ones where the claim is provably
false.
-/
def KEMOIA [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) : Prop :=
  ∀ (f : X → Bool) (g₀ g₁ : G),
    f (g₀ • kem.basePoint) = f (g₁ • kem.basePoint)

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
-- Work Unit 7.6b: Ciphertext Indistinguishability Lemma
-- ============================================================================

/--
Under KEMOIA, no Boolean function can distinguish orbit elements.

Post Workstream L5, `KEMOIA` is precisely the orbit-indistinguishability
predicate, so this theorem is a direct forwarding of the hypothesis (no
conjunct extraction).
-/
theorem kem_ciphertext_indistinguishable [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (hOIA : KEMOIA kem) (f : X → Bool) (g₀ g₁ : G) :
    f (g₀ • kem.basePoint) = f (g₁ • kem.basePoint) :=
  hOIA f g₀ g₁

-- ============================================================================
-- Work Unit 7.6c: Main Security Theorem
-- ============================================================================

/--
**KEM Security Theorem.** KEMOIA implies KEM security.

If the KEM-OIA holds, no adversary can distinguish two different
encapsulations. This is the KEM analogue of `oia_implies_1cpa`.

**Proof strategy (post-Workstream-L5 simplification):**
1. Introduce adversary `A` and assume `kemHasAdvantage kem A`.
2. Destructure to get `g₀`, `g₁`, and the inequality `hNeq`.
3. Apply `kem_key_constant_direct`: both derived keys equal
   `keyDerive(canon(basePoint))`. Rewrite `hNeq` to use this constant
   key. (Pre-L5 this step invoked `hOIA.2`, the now-removed second
   conjunct of `KEMOIA`; post-L5 the fact is proved unconditionally
   from `canonical_isGInvariant`.)
4. Apply `hOIA` (which post-L5 is precisely the
   orbit-indistinguishability predicate): the adversary's guess
   function (partially applied to `basePoint` and the constant key)
   is a Boolean function on `X`, so it must give the same value on
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
  -- Step 1: Apply key constancy — both keys equal keyDerive(canon(basePoint)).
  -- Post-Workstream-L5 we use `kem_key_constant_direct`, which proves the
  -- constancy unconditionally from `canonical_isGInvariant`; no `hOIA`
  -- extraction is needed for this step.
  apply hNeq
  rw [kem_key_constant_direct kem g₀, kem_key_constant_direct kem g₁]
  -- Step 2: Apply orbit indistinguishability — guess is constant across orbit.
  -- `hOIA` is now the single-conjunct form (orbit indistinguishability),
  -- applied directly without a `.1` extraction.
  exact hOIA (fun c => A.guess kem.basePoint c
    (kem.keyDerive (kem.canonForm.canon kem.basePoint))) g₀ g₁

-- ============================================================================
-- Workstream E2 (audit 2026-04-23, finding E-06): machine-checked
-- vacuity witness for the deterministic KEMOIA.
-- ============================================================================

/--
**Vacuity witness (audit 2026-04-23 E-06).** The deterministic `KEMOIA`
predicate is `False` whenever the KEM's base-point orbit is
non-trivial — i.e., there exist two group elements `g₀, g₁ : G`
producing distinct ciphertexts `g₀ • basePoint ≠ g₁ • basePoint`.
This hypothesis holds on every realistic KEM (production HGOE has
`|orbit| ≫ 2`); the witness theorem machine-checks the scaffolding
disclosure that the `KEMOIA` and `Orbcrypt.lean` vacuity-map
docstrings previously asserted only in prose.

The distinguisher is the membership-at-`g₀ • basePoint` Boolean
test `fun c => decide (c = g₀ • kem.basePoint)`. On the LHS it
evaluates to `true` (reflexivity); on the RHS — by the distinctness
hypothesis — it evaluates to `false`; contradiction.

Parallel scheme-layer witness: `det_oia_false_of_distinct_reps` in
`Orbcrypt/Crypto/OIA.lean`.

**Note on `KEMOIA`'s single-conjunct form.** Post-Workstream-L5
(audit F-AUDIT-2026-04-21-M6, 2026-04-22), `KEMOIA` is a
single-conjunct orbit-indistinguishability predicate; the former
key-uniformity conjunct was unconditional (provable from
`canonical_isGInvariant`) and was removed. This proof therefore
applies the single `hKEMOIA` Prop directly, without a `.1` / `.2`
destructuring step.

**Release-messaging status.** Standalone (unconditional on the
orbit-non-triviality hypothesis). Safe to cite directly as formal
evidence that the deterministic KEM chain is scaffolding, not
substantive security content.
-/
theorem det_kemoia_false_of_nontrivial_orbit [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K)
    {g₀ g₁ : G}
    (hDistinct : g₀ • kem.basePoint ≠ g₁ • kem.basePoint) :
    ¬ KEMOIA kem := by
  -- Assume KEMOIA and derive a contradiction via the
  -- membership-at-`g₀ • basePoint` Boolean distinguisher.
  intro hKEMOIA
  have h := hKEMOIA
    (fun c => decide (c = g₀ • kem.basePoint)) g₀ g₁
  -- LHS decides `g₀ • basePoint = g₀ • basePoint` ⇒ `true`.
  have hLHS :
      decide (g₀ • kem.basePoint = g₀ • kem.basePoint) = true :=
    decide_eq_true (Eq.refl _)
  -- RHS decides `g₁ • basePoint = g₀ • basePoint` ⇒ `false` (by
  -- distinctness symmetry).
  have hRHS :
      decide (g₁ • kem.basePoint = g₀ • kem.basePoint) = false :=
    decide_eq_false (fun heq => hDistinct heq.symm)
  rw [hLHS, hRHS] at h
  -- `h : true = false` is impossible; `Bool.noConfusion` closes any
  -- goal (here `False`) from a constructor mismatch.
  exact Bool.noConfusion h

end Orbcrypt
