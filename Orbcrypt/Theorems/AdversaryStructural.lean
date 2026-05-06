/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.Crypto.Security
import Orbcrypt.GroupAction.Canonical
import Orbcrypt.GroupAction.Invariant

/-!
# Orbcrypt.Theorems.AdversaryStructural

Structural adversary lemmas: extract distinguisher from advantage,
build a G-invariant separator from distinct messages, unfold
`hasAdvantage`. These theorems are independent of the deterministic
OIA Prop (which was deleted in W6 of structural review 2026-05-06).

This file was created by W6.9 of structural review 2026-05-06: the
surviving content of the now-deleted
`Orbcrypt/Theorems/OIAImpliesCPA.lean` (Phase 4 § 4.11–4.16) is
relocated here. The file's previous name was misleading post-W6
because the OIA → IND-1-CPA reduction itself was deleted along
with the deterministic chain.

## Main results

* `Orbcrypt.hasAdvantage_iff` — unfolding lemma for `hasAdvantage`
  (Phase 4 § 4.11).
* `Orbcrypt.adversary_yields_distinguisher` — extract a
  distinguishing function from any adversary with advantage
  (Phase 4 § 4.14, Track D).
* `Orbcrypt.insecure_implies_orbit_distinguisher` — insecurity
  implies an orbit-distinguisher (renamed from
  `insecure_implies_separating` by Workstream I3 of audit
  2026-04-23, finding D-07; Phase 4 § 4.15).
* `Orbcrypt.distinct_messages_have_invariant_separator` — distinct
  messages admit a G-invariant separator (Workstream I3 NEW
  substantive theorem; the cryptographic content the pre-I name
  advertised but did not deliver).

## References

* docs/dev_history/formalization/phases/PHASE_4_CORE_THEOREMS.md
  — work units 4.11, 4.14, 4.15, 4.16.
* docs/dev_history/AUDIT_2026-04-23_WORKSTREAM_PLAN.md § I3 —
  Workstream I3 rename + new theorem rationale.
* docs/dev_history/AUDIT_2026-05-06_STRUCTURAL_REVIEW.md § 1 row 7
  — W6.9 file relocation rationale.
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*} {M : Type*}

-- ============================================================================
-- Phase 4 § 4.11: hasAdvantage Unfolding Lemma
-- ============================================================================

/-- Unfold `hasAdvantage` past any let-bindings for easier reasoning.

    In Phase 3, `hasAdvantage` was defined directly with `.1` / `.2`
    projections (no `let` destructuring), so this is definitionally
    trivial. The lemma is retained for documentation and as a stable
    API surface: if `hasAdvantage` is later refactored to use `let`
    destructuring, proofs that go through `hasAdvantage_iff` remain
    valid. -/
theorem hasAdvantage_iff [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) :
    hasAdvantage scheme A ↔
      ∃ g₀ g₁ : G,
        A.guess scheme.reps (g₀ • scheme.reps (A.choose scheme.reps).1) ≠
        A.guess scheme.reps (g₁ • scheme.reps (A.choose scheme.reps).2) := by
  rfl

-- ============================================================================
-- Phase 4 § 4.14: Distinguisher Extraction (Track D)
-- ============================================================================

/-- Extract a distinguishing function from an adversary with
    advantage. The function is simply the adversary's guess,
    partially applied to `reps`.

    **Proof strategy:** Destructure `hasAdvantage` to obtain the
    witness group elements and the inequality, then repackage with
    `A.guess scheme.reps` as the distinguishing function. -/
theorem adversary_yields_distinguisher
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (A : Adversary X M) (hAdv : hasAdvantage scheme A) :
    ∃ (f : X → Bool) (m₀ m₁ : M) (g₀ g₁ : G),
      f (g₀ • scheme.reps m₀) ≠ f (g₁ • scheme.reps m₁) := by
  obtain ⟨g₀, g₁, hNeq⟩ := hAdv
  exact ⟨fun x => A.guess scheme.reps x,
         (A.choose scheme.reps).1, (A.choose scheme.reps).2,
         g₀, g₁, hNeq⟩

-- ============================================================================
-- Phase 4 § 4.15: Insecurity → Orbit-Distinguisher (Track D)
-- ============================================================================

/--
**Insecurity yields an orbit distinguisher (renamed from the pre-
Workstream-I `insecure_implies_separating`).**

If the scheme is insecure, there exists a Boolean function that
distinguishes a specific pair `(g₀ • reps m₀, g₁ • reps m₁)`. The
distinguisher returned is the adversary's `guess` function, which
is **not in general G-invariant**.

**Naming corrective (Workstream I3, audit 2026-04-23 finding D-07).**
Pre-I this theorem was named `insecure_implies_separating`, which
suggested it produced a *G-invariant separating function*. The
body delivers only the second conjunct of `IsSeparating` — value
disagreement on a single pair — but no G-invariance claim. The
rename restores accuracy: the conclusion is an *orbit
distinguisher*, not a separating G-invariant function.

**For G-invariant separation** see
`distinct_messages_have_invariant_separator` below, which delivers
genuine G-invariance unconditionally on any two distinct messages
(no adversary required, no `hasAdvantage` hypothesis). -/
theorem insecure_implies_orbit_distinguisher
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (A : Adversary X M) (hAdv : hasAdvantage scheme A) :
    ∃ (f : X → Bool) (m₀ m₁ : M),
      ∃ g₀ g₁ : G, f (g₀ • scheme.reps m₀) ≠ f (g₁ • scheme.reps m₁) := by
  obtain ⟨f, m₀, m₁, g₀, g₁, h⟩ := adversary_yields_distinguisher scheme A hAdv
  exact ⟨f, m₀, m₁, g₀, g₁, h⟩

-- ============================================================================
-- Phase 4 § 4.16: G-Invariant Separator from Message Distinctness
-- (Workstream I3 NEW substantive theorem)
-- ============================================================================

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
function that is G-invariant **and** separating, and it does so
**unconditionally** on the message-distinctness hypothesis (no
adversary, no `hasAdvantage`).

**Construction.** The canonical-form discriminator
`f x := decide (scheme.canonForm.canon x = scheme.canonForm.canon
(scheme.reps m₀))` is:

* **G-invariant** by `canon_indicator_isGInvariant`
  (`GroupAction/Invariant.lean`), which composes `decide (· = c)`
  with the G-invariant `scheme.canonForm.canon`.
* **Separating** for `m₀ ≠ m₁` because `scheme.reps_distinct`
  guarantees the orbits differ, hence the canonical forms differ.

**Status.** Standalone (release-citable). -/
theorem distinct_messages_have_invariant_separator
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    {m₀ m₁ : M} (h_ne : m₀ ≠ m₁) :
    ∃ f : X → Bool,
      IsGInvariant (G := G) f ∧
      f (scheme.reps m₀) ≠ f (scheme.reps m₁) := by
  refine ⟨fun x => decide (scheme.canonForm.canon x =
                             scheme.canonForm.canon
                               (scheme.reps m₀)),
          canon_indicator_isGInvariant scheme.canonForm _,
          ?_⟩
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
