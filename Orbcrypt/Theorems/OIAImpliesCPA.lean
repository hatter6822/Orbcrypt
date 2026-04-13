import Orbcrypt.Crypto.Security
import Orbcrypt.Crypto.OIA

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
* `Orbcrypt.adversary_yields_distinguisher` — advantage implies a distinguisher
* `Orbcrypt.insecure_implies_separating` — insecurity implies a separating function

## References

* DEVELOPMENT.md §8.1 — OIA implies IND-1-CPA security
* formalization/phases/PHASE_4_CORE_THEOREMS.md — work units 4.10–4.15
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
**Contrapositive.** If the scheme is insecure, a separating function exists.
Together with the invariant attack theorem, this establishes:
  insecurity ↔ existence of a separating invariant
(modulo the distinction between G-invariant functions and arbitrary
distinguishers).

**Scope limitation:** This theorem shows that *some* Boolean function
distinguishes orbit samples, but does not prove that function is G-invariant.
The full equivalence would require showing that any distinguisher can be
"averaged" into a G-invariant one, which requires probabilistic reasoning
beyond the current scope. -/
theorem insecure_implies_separating [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (A : Adversary X M) (hAdv : hasAdvantage scheme A) :
    ∃ (f : X → Bool) (m₀ m₁ : M),
      ∃ g₀ g₁ : G, f (g₀ • scheme.reps m₀) ≠ f (g₁ • scheme.reps m₁) := by
  obtain ⟨f, m₀, m₁, g₀, g₁, h⟩ := adversary_yields_distinguisher scheme A hAdv
  exact ⟨f, m₀, m₁, g₀, g₁, h⟩

end Orbcrypt
