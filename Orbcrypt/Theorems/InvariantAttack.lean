import Orbcrypt.Crypto.Security
import Orbcrypt.GroupAction.Invariant

/-!
# Orbcrypt.Theorems.InvariantAttack

Invariant attack theorem: if a G-invariant function separates two message
orbits, there **exists** an adversary with `hasAdvantage` — i.e., a specific
`(g₀, g₁)` pair on which the adversary's two guesses disagree. Informal
shorthand: "complete break". Machine-checked proof of the critical
vulnerability from COUNTEREXAMPLE.md. Formalizes DEVELOPMENT.md §4.4
(**existential** form — the Lean content is one level weaker than the
paper-style "Adv = 1/2" claim; see the `invariant_attack` docstring
below for the three-convention catalogue and `DEVELOPMENT.md` §4.4's
"Lean-formalised content" note; audit 2026-04-23 / V1-4 / D13).

## Overview

This module proves Headline Result #2 of the Orbcrypt formalization: the
invariant attack theorem. If an attacker discovers a G-invariant function `f`
such that `f(reps m₀) ≠ f(reps m₁)`, they can construct an adversary that
always correctly guesses which message was encrypted.

The proof proceeds in four steps:

1. **Adversary construction** (4.6): define an adversary that evaluates `f`
   on the ciphertext and compares to `f(reps m₀)`.
2. **Invariance application** (4.7): for G-invariant `f`,
   `f(g • reps m) = f(reps m)`.
3. **Adversary correctness** (4.8): by case split on the challenge bit,
   the adversary always guesses correctly.
4. **Assembly** (4.9): exhibit the adversary and show it has advantage.

## Main results

* `Orbcrypt.invariantAttackAdversary` — adversary using a separating invariant
* `Orbcrypt.invariant_on_encrypt` — invariant function commutes with encryption
* `Orbcrypt.invariantAttackAdversary_correct` — adversary always guesses correctly
* `Orbcrypt.invariant_attack` — existence of a separating invariant implies a break

## References

* DEVELOPMENT.md §4.4 — invariant attack analysis
* COUNTEREXAMPLE.md — concrete invariant attack via Hamming weight
* formalization/phases/PHASE_4_CORE_THEOREMS.md — work units 4.6–4.9
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*} {M : Type*} {Y : Type*}

-- ============================================================================
-- Work Unit 4.6: Adversary Construction
-- ============================================================================

/--
Construct an adversary that uses a separating invariant to break the scheme.
Given `f : X → Y` with `f(reps m₀) ≠ f(reps m₁)` and `f` G-invariant,
the adversary computes `f(c)` and compares to `f(reps m₀)`.

- `choose` always selects the challenge pair `(m₀, m₁)`.
- `guess` returns `true` if `f(c) = f(reps m₀)` (guessing m₀ was encrypted),
  `false` otherwise (guessing m₁ was encrypted). -/
def invariantAttackAdversary [DecidableEq Y]
    (f : X → Y) (m₀ m₁ : M) : Adversary X M where
  choose := fun _reps => (m₀, m₁)
  guess := fun reps c => if f c = f (reps m₀) then true else false

/-- Unfold the choice of the invariant attack adversary. -/
@[simp]
theorem invariantAttackAdversary_choose [DecidableEq Y]
    (f : X → Y) (m₀ m₁ : M) (reps : M → X) :
    (invariantAttackAdversary f m₀ m₁).choose reps = (m₀, m₁) := rfl

/-- Unfold the guess of the invariant attack adversary. -/
@[simp]
theorem invariantAttackAdversary_guess [DecidableEq Y]
    (f : X → Y) (m₀ m₁ : M) (reps : M → X) (c : X) :
    (invariantAttackAdversary f m₀ m₁).guess reps c =
    if f c = f (reps m₀) then true else false := rfl

-- ============================================================================
-- Work Unit 4.7: Invariance Application Helper
-- ============================================================================

/-- For a G-invariant function, `f(g • reps m) = f(reps m)`.
    This bridges "ciphertext is `g • reps m`" and "the adversary can
    compute `f(reps m)` from the ciphertext."

    This one-line lemma is used twice in the adversary correctness proof
    (4.8): once for the `b = false` case and once for the `b = true` case. -/
theorem invariant_on_encrypt [Group G] [MulAction G X]
    {f : X → Y} (hInv : IsGInvariant (G := G) f)
    (reps : M → X) (g : G) (m : M) :
    f (g • reps m) = f (reps m) :=
  hInv g (reps m)

-- ============================================================================
-- Work Unit 4.8: Adversary Correctness by Case Split
-- ============================================================================

/-- The invariant attack adversary always guesses correctly.
    When `b = false` (challenge is `m₀`), guess = `true` = `!false`.
    When `b = true` (challenge is `m₁`), guess = `false` = `!true`.

    **Proof strategy:** Case split on `b`, then:
    - Use G-invariance to simplify `f(g • reps mₓ)` to `f(reps mₓ)`.
    - In the `false` case, `f(reps m₀) = f(reps m₀)` gives `if_pos rfl`.
    - In the `true` case, `f(reps m₁) ≠ f(reps m₀)` gives `if_neg`. -/
theorem invariantAttackAdversary_correct [Group G] [MulAction G X]
    [DecidableEq X] [DecidableEq Y]
    (scheme : OrbitEncScheme G X M)
    (f : X → Y) (m₀ m₁ : M)
    (hInv : IsGInvariant (G := G) f)
    (hSep : f (scheme.reps m₀) ≠ f (scheme.reps m₁))
    (g : G) (b : Bool) :
    let A := invariantAttackAdversary f m₀ m₁
    let mb := if b then m₁ else m₀
    A.guess scheme.reps (g • scheme.reps mb) = !b := by
  -- Strategy: case split on b, simplify via G-invariance, close with if_pos/if_neg
  cases b <;> simp [invariantAttackAdversary_guess, invariant_on_encrypt hInv, Ne.symm hSep]

-- ============================================================================
-- Work Unit 4.9: Invariant Attack Assembly (Headline Result #2)
-- ============================================================================

/--
**Invariant Attack Theorem.** If a G-invariant function separates two message
orbits, an adversary achieves a complete break.
Formalizes DEVELOPMENT.md §4.4 and the lesson of COUNTEREXAMPLE.md.

**Proof strategy:**
1. Exhibit the `invariantAttackAdversary`.
2. Unfold `hasAdvantage` and the adversary's `choose`.
3. Witness `g₀ = 1, g₁ = 1` (identity elements simplify via `one_smul`).
4. Show the two guesses differ: one is `true` (for `m₀`), the other is
   `false` (for `m₁`, using `hSep`).

**Advantage-mapping note (audit 2026-04-21 finding L5 / Workstream M).**
This theorem proves *deterministic advantage = 1* — i.e. the adversary
distinguishes perfectly on at least one specific pair `(g₀, g₁)` of
group elements (`hasAdvantage` is the existential of two group
elements producing disagreeing guesses). Three conventions for
"adversary advantage" appear in the cryptographic literature, and all
three agree on the "complete break" outcome witnessed here:
* **Two-distribution convention** (probabilistic game, see
  `Probability/Advantage.lean`): `Adv = |Pr[D=1 | d₀] - Pr[D=1 | d₁]|`.
  Deterministic advantage 1 corresponds to probabilistic advantage 1
  (the distinguisher always outputs the correct bit).
* **Centred convention**: `Adv = |Pr[correct] - 1/2|`. Deterministic
  advantage 1 corresponds to centred advantage 1/2 (the maximum:
  always correct means `Pr[correct] = 1`).
* **Deterministic convention** (this module): the existence of a
  specific `(g₀, g₁)` pair for which the adversary's two guesses
  differ. This is the *strongest* form — it asserts a
  witness-specific gap, not an average gap.
Consumers computing concrete security parameters from Orbcrypt should
note which convention their downstream analysis uses; the three
conventions agree on "complete break" but differ by a factor of 2
between the two-distribution and centred conventions for intermediate
advantages. -/
theorem invariant_attack [Group G] [MulAction G X] [DecidableEq X]
    [DecidableEq Y]
    (scheme : OrbitEncScheme G X M)
    (f : X → Y) (m₀ m₁ : M)
    (hInv : IsGInvariant (G := G) f)
    (hSep : f (scheme.reps m₀) ≠ f (scheme.reps m₁)) :
    ∃ A : Adversary X M, hasAdvantage scheme A := by
  -- Step 1: Exhibit the adversary
  use invariantAttackAdversary f m₀ m₁
  -- Step 2: Witness g₀ = 1, g₁ = 1
  refine ⟨1, 1, ?_⟩
  -- Step 3: Unfold the adversary's choose and guess
  simp only [invariantAttackAdversary_choose, invariantAttackAdversary_guess]
  -- Step 4: Apply G-invariance to rewrite f(1 • reps mᵢ) to f(reps mᵢ)
  rw [hInv 1 (scheme.reps m₀), hInv 1 (scheme.reps m₁)]
  -- Step 5: The first if-condition is reflexivity (true), the second is hSep (false)
  simp [Ne.symm hSep]

end Orbcrypt
