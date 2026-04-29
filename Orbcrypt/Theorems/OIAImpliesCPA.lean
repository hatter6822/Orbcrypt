/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.Crypto.Security
import Orbcrypt.Crypto.OIA
-- Workstream I3 (audit 2026-04-23, finding D-07): the new theorem
-- `distinct_messages_have_invariant_separator` consumes
-- `IsGInvariant` and `canon_indicator_isGInvariant` from
-- `GroupAction/Invariant.lean`.
import Orbcrypt.GroupAction.Invariant

/-!
# Orbcrypt.Theorems.OIAImpliesCPA

Conditional security reduction: OIA implies IND-1-CPA security. If the Orbit
Indistinguishability Assumption holds, the scheme is secure against single-query
chosen-plaintext attacks. Formalizes DEVELOPMENT.md §8.1.

## Overview

This module proves Headline Result #3 of the Orbcrypt formalization: the
OIA implies IND-1-CPA security. The proof proceeds in four steps:

1. **OIA specialization** (4.10): instantiate the OIA with the adversary's
   guess function to obtain equality on all orbit pairs.
2. **hasAdvantage unfolding** (4.11): provide a clean characterization of
   `hasAdvantage` for easier reasoning.
3. **Advantage elimination** (4.12): show no adversary has advantage under OIA.
4. **Assembly** (4.13): combine into the headline security theorem.

Additionally, Track D (optional) proves the contrapositive direction:
5. **Distinguisher extraction** (4.14): extract a distinguishing function
   from an adversary with advantage.
6. **Contrapositive theorem** (4.15): insecurity implies a separating function.

## Main results

* `Orbcrypt.oia_specialized` — OIA specialized to an adversary's guess function
* `Orbcrypt.hasAdvantage_iff` — clean characterization of `hasAdvantage`
* `Orbcrypt.no_advantage_from_oia` — OIA implies no adversary has advantage
* `Orbcrypt.oia_implies_1cpa` — **OIA implies IND-1-CPA security**
* `Orbcrypt.oia_implies_1cpa_distinct` — classical distinct-challenge
  IND-1-CPA form: OIA implies `IsSecureDistinct` (composes
  `oia_implies_1cpa` with `isSecure_implies_isSecureDistinct`). This is
  the release-facing corollary matching the literature's IND-1-CPA game
  (challenger rejects `(m, m)` before sampling).
* `Orbcrypt.adversary_yields_distinguisher` — advantage implies a distinguisher
* `Orbcrypt.insecure_implies_orbit_distinguisher` — insecurity implies a
  Boolean orbit-distinguisher (renamed from the pre-Workstream-I
  `insecure_implies_separating`; the renamed identifier accurately
  describes the weaker content — an arbitrary Boolean distinguisher,
  *not* a G-invariant separating function). Audit 2026-04-23 finding
  D-07, Workstream I3.
* `Orbcrypt.distinct_messages_have_invariant_separator` — the
  cryptographic-content delivery the pre-I name advertised: from any
  two distinct messages, exhibit a **G-invariant** Boolean function
  separating their representatives. Strictly stronger than
  `insecure_implies_orbit_distinguisher` (no adversary required;
  conclusion includes G-invariance). Workstream I3 (audit D-07).

## References

* DEVELOPMENT.md §8.1 — OIA implies IND-1-CPA security
* formalization/phases/PHASE_4_CORE_THEOREMS.md — work units 4.10–4.15
* docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md § 6 — Workstream K
  (distinct-challenge IND-1-CPA corollary, audit finding
  F-AUDIT-2026-04-21-M1)
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*} {M : Type*}

-- ============================================================================
-- Work Unit 4.10: OIA Specialization to Adversary
-- ============================================================================

/-- Specialize the strong OIA to the adversary's guess function.
    For ANY pair of group elements, the guess is the same on both orbits.

    The strong OIA gives `f(g₀ • reps m₀) = f(g₁ • reps m₁)` for any
    Boolean function `f`. Instantiating `f` with `A.guess scheme.reps`
    (which has type `X → Bool`) yields the result directly. -/
theorem oia_specialized [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (hOIA : OIA scheme)
    (A : Adversary X M) (m₀ m₁ : M) (g₀ g₁ : G) :
    A.guess scheme.reps (g₀ • scheme.reps m₀) =
    A.guess scheme.reps (g₁ • scheme.reps m₁) :=
  hOIA (fun x => A.guess scheme.reps x) m₀ m₁ g₀ g₁

-- ============================================================================
-- Work Unit 4.11: hasAdvantage Unfolding Lemma
-- ============================================================================

/-- Unfold `hasAdvantage` past any let-bindings for easier reasoning.

    In Phase 3, `hasAdvantage` was defined directly with `.1` / `.2`
    projections (no `let` destructuring), so this is definitionally trivial.
    The lemma is retained for documentation and as a stable API surface:
    if `hasAdvantage` is later refactored to use `let` destructuring,
    proofs that go through `hasAdvantage_iff` remain valid. -/
theorem hasAdvantage_iff [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) :
    hasAdvantage scheme A ↔
      ∃ g₀ g₁ : G,
        A.guess scheme.reps (g₀ • scheme.reps (A.choose scheme.reps).1) ≠
        A.guess scheme.reps (g₁ • scheme.reps (A.choose scheme.reps).2) := by
  -- hasAdvantage already uses .1 / .2 directly, so this is Iff.rfl
  rfl

-- ============================================================================
-- Work Unit 4.12: Advantage Elimination
-- ============================================================================

/-- OIA implies no adversary has advantage.

    **Proof strategy:** Assume `hasAdvantage scheme A` for contradiction.
    Destructure to get `g₀, g₁` and the inequality `guess(...) ≠ guess(...)`.
    Apply `oia_specialized` to derive the equality, contradicting the
    inequality directly. -/
theorem no_advantage_from_oia [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (hOIA : OIA scheme) (A : Adversary X M) :
    ¬ hasAdvantage scheme A := by
  -- Negate the existential: ∀ g₀ g₁, guess(g₀ • reps m₀) = guess(g₁ • reps m₁)
  intro ⟨g₀, g₁, hNeq⟩
  -- Apply OIA to derive the equality that contradicts hNeq
  exact hNeq (oia_specialized scheme hOIA A _ _ g₀ g₁)

-- ============================================================================
-- Work Unit 4.13: Security Theorem Assembly (Headline Result #3)
-- ============================================================================

/--
**Security Theorem.** The OIA implies IND-1-CPA security.
Formalizes DEVELOPMENT.md §8.1.

If the Orbit Indistinguishability Assumption holds for a scheme, then no
adversary can achieve non-zero advantage in the IND-1-CPA game. This is the
core conditional security guarantee of the Orbcrypt construction.

**Note on the OIA hypothesis:** `OIA scheme` is a `Prop`-valued definition,
NOT a Lean `axiom`. The theorem carries it as an explicit hypothesis, so
`#print axioms oia_implies_1cpa` shows only standard Lean axioms. -/
theorem oia_implies_1cpa [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (hOIA : OIA scheme) : IsSecure scheme := by
  -- IsSecure = ∀ A, ¬ hasAdvantage scheme A
  intro A
  exact no_advantage_from_oia scheme hOIA A

/--
**Distinct-challenge IND-1-CPA from OIA (classical game).**

Corollary of `oia_implies_1cpa`: the OIA hypothesis implies the
classical distinct-challenge security predicate `IsSecureDistinct`.
Composes the strong uniform-challenge `oia_implies_1cpa` with
`isSecure_implies_isSecureDistinct` (proved in `Crypto/Security.lean`).

**Why this corollary.** The classical IND-1-CPA game in the literature
requires the adversary to submit *distinct* challenges `m₀ ≠ m₁`; the
challenger rejects `(m, m)` before sampling. `IsSecure` is strictly
stronger — it demands security even against the degenerate collision
choice that the classical challenger would reject. External summaries
and downstream citations that read "IND-1-CPA under OIA" should prefer
`oia_implies_1cpa_distinct` over `oia_implies_1cpa` because this form
matches the game shape actually studied in the literature.

**Scaffolding disclosure.** Like `oia_implies_1cpa`, this theorem
inherits the *scaffolding* status of the deterministic chain: the
`OIA` hypothesis quantifies over every Boolean distinguisher and is
**False on every non-trivial scheme** (see `Crypto/OIA.lean`).
Consequently the conclusion is vacuously true on production
instances. For genuinely ε-smooth distinct-challenge security, cite
the probabilistic chain (`concrete_oia_implies_1cpa` +
`indCPAAdvantage_collision_zero`; the probabilistic advantage is
unconditionally bounded for every adversary, so the distinct-challenge
restriction transfers for free).
-/
theorem oia_implies_1cpa_distinct [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (hOIA : OIA scheme) : IsSecureDistinct scheme :=
  isSecure_implies_isSecureDistinct scheme (oia_implies_1cpa scheme hOIA)

-- ============================================================================
-- Track D (Optional): Contrapositive Direction
-- ============================================================================

-- ============================================================================
-- Work Unit 4.14: Distinguisher Extraction
-- ============================================================================

/-- Extract a distinguishing function from an adversary with advantage.
    The function is simply the adversary's guess, partially applied to `reps`.

    **Proof strategy:** Destructure `hasAdvantage` to obtain the witness group
    elements and the inequality, then repackage with `A.guess scheme.reps`
    as the distinguishing function. -/
theorem adversary_yields_distinguisher [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (A : Adversary X M) (hAdv : hasAdvantage scheme A) :
    ∃ (f : X → Bool) (m₀ m₁ : M) (g₀ g₁ : G),
      f (g₀ • scheme.reps m₀) ≠ f (g₁ • scheme.reps m₁) := by
  obtain ⟨g₀, g₁, hNeq⟩ := hAdv
  exact ⟨fun x => A.guess scheme.reps x,
         (A.choose scheme.reps).1, (A.choose scheme.reps).2,
         g₀, g₁, hNeq⟩

-- ============================================================================
-- Work Unit 4.15: Contrapositive Theorem
-- ============================================================================

/--
**Insecurity yields an orbit distinguisher (renamed from the pre-
Workstream-I `insecure_implies_separating`).**

If the scheme is insecure, there exists a Boolean function that
distinguishes a specific pair `(g₀ • reps m₀, g₁ • reps m₁)`. The
distinguisher returned is the adversary's `guess` function, which is
**not in general G-invariant**.

**Naming corrective (Workstream I3, audit 2026-04-23 finding D-07).**
Pre-I this theorem was named `insecure_implies_separating`, which
suggested it produced a *G-invariant separating function* (in the
sense of `IsSeparating` from `GroupAction/Invariant.lean`). The body
delivers only the second conjunct of `IsSeparating` — value
disagreement on a single pair — but no G-invariance claim. The
rename restores accuracy: the conclusion is an *orbit distinguisher*
(a Boolean test that disagrees on two specific orbit-action images),
not a separating G-invariant function.

**For G-invariant separation** see
`distinct_messages_have_invariant_separator` below, which delivers
genuine G-invariance unconditionally on any two distinct messages
(no adversary required, no `hasAdvantage` hypothesis). The two
theorems sit alongside each other: `insecure_implies_orbit_
distinguisher` for adversary-extracted distinguishers (which may
fail G-invariance), and `distinct_messages_have_invariant_separator`
for the structural existence of a G-invariant separator on any
distinct-message pair. -/
theorem insecure_implies_orbit_distinguisher
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (A : Adversary X M) (hAdv : hasAdvantage scheme A) :
    ∃ (f : X → Bool) (m₀ m₁ : M),
      ∃ g₀ g₁ : G, f (g₀ • scheme.reps m₀) ≠ f (g₁ • scheme.reps m₁) := by
  obtain ⟨f, m₀, m₁, g₀, g₁, h⟩ := adversary_yields_distinguisher scheme A hAdv
  exact ⟨f, m₀, m₁, g₀, g₁, h⟩

/--
**G-invariant separator from message distinctness** (Workstream I3,
audit 2026-04-23 finding D-07).

Given any two **distinct** messages `m₀ ≠ m₁`, there exists a
G-invariant Boolean function on `X` that takes different values on
their representatives `scheme.reps m₀` and `scheme.reps m₁`.

This is the **cryptographic content** the pre-Workstream-I name
`insecure_implies_separating` (renamed to
`insecure_implies_orbit_distinguisher`) advertised but did not
deliver. The pre-I theorem produced an arbitrary distinguisher
extracted from a hypothetical adversary; this theorem produces a
function that is G-invariant (in the sense of
`GroupAction/Invariant.lean`'s `IsGInvariant`) **and** separating
(in the sense of `IsSeparating`'s second conjunct), and it does so
**unconditionally** on the message-distinctness hypothesis (no
adversary, no `hasAdvantage`).

**Construction.** The canonical-form discriminator
`f x := decide (scheme.canonForm.canon x = scheme.canonForm.canon
(scheme.reps m₀))` is:

* **G-invariant** by `canon_indicator_isGInvariant`
  (`GroupAction/Invariant.lean`), which composes `decide (· = c)`
  with the G-invariant `scheme.canonForm.canon`.
* **Separating** for `m₀ ≠ m₁` because `scheme.reps_distinct`
  guarantees the orbits differ, hence the canonical forms differ
  (contrapositive of `canon_eq_implies_orbit_eq` in
  `GroupAction/Canonical.lean`). The LHS evaluates to `true` by
  reflexivity; the RHS evaluates to `false` by the contrapositive.

**Status.** Standalone (release-citable). This closes the
release-messaging gap that audit findings F-06 (2026-04-14) and
D-07 (2026-04-23) flagged: the scheme's vulnerability to the
invariant attack of `Theorems/InvariantAttack.lean` is now
machine-checked at the *predicate-existence* level, not just at
the *adversary-existence* level. -/
theorem distinct_messages_have_invariant_separator
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    {m₀ m₁ : M} (h_ne : m₀ ≠ m₁) :
    ∃ f : X → Bool,
      IsGInvariant (G := G) f ∧
      f (scheme.reps m₀) ≠ f (scheme.reps m₁) := by
  -- Witness: the canonical-form discriminator at `canon (reps m₀)`.
  refine ⟨fun x => decide (scheme.canonForm.canon x =
                             scheme.canonForm.canon
                               (scheme.reps m₀)),
          canon_indicator_isGInvariant scheme.canonForm _,
          ?_⟩
  -- Separation: distinct messages have distinct orbits (by
  -- `reps_distinct`), hence distinct canonical forms.
  have h_orbit_ne :
      MulAction.orbit G (scheme.reps m₀) ≠
      MulAction.orbit G (scheme.reps m₁) :=
    scheme.reps_distinct m₀ m₁ h_ne
  have h_canon_ne :
      scheme.canonForm.canon (scheme.reps m₀) ≠
      scheme.canonForm.canon (scheme.reps m₁) := by
    intro h_eq
    exact h_orbit_ne
      (canon_eq_implies_orbit_eq scheme.canonForm _ _ h_eq)
  -- Goal: decide (canon (reps m₀) = canon (reps m₀)) ≠
  --       decide (canon (reps m₁) = canon (reps m₀))
  -- LHS reduces to `true` by reflexivity; RHS reduces to `false` by
  -- `decide_eq_false` applied to the symmetric form of `h_canon_ne`.
  -- Beta-reduce the lambda applications so the rewrites match.
  show decide (scheme.canonForm.canon (scheme.reps m₀) =
              scheme.canonForm.canon (scheme.reps m₀)) ≠
       decide (scheme.canonForm.canon (scheme.reps m₁) =
              scheme.canonForm.canon (scheme.reps m₀))
  have h_lhs : decide (scheme.canonForm.canon (scheme.reps m₀) =
                       scheme.canonForm.canon (scheme.reps m₀)) = true :=
    decide_eq_true rfl
  have h_rhs : decide (scheme.canonForm.canon (scheme.reps m₁) =
                       scheme.canonForm.canon (scheme.reps m₀)) = false :=
    decide_eq_false (Ne.symm h_canon_ne)
  rw [h_lhs, h_rhs]
  decide

end Orbcrypt
