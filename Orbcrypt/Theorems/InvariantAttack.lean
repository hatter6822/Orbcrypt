/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.Crypto.Security
import Orbcrypt.Crypto.CompOIA
import Orbcrypt.Crypto.CompSecurity
import Orbcrypt.GroupAction.Invariant
import Orbcrypt.Probability.Monad

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

## Probabilistic strengthening (Workstream R-01)

The base theorem `invariant_attack` delivers the *existential* form of
the break: there exists *some* `(g₀, g₁)` pair that separates the two
guesses. Workstream R-01 strengthens this to a tight quantitative
statement at the probabilistic IND-1-CPA layer: under a separating
G-invariant, the invariant-attack adversary's `indCPAAdvantage` is
exactly `1` — the maximum advantage attainable in the two-distribution
convention (cf. `advantage_le_one`).

The probabilistic upgrade is delivered in three lemmas:

1. `Orbcrypt.probTrue_orbitDist_invariant_eq_one` — under a G-invariant
   `f` with `f x = f y`, the predicate `decide (f · = f y)` is
   constantly `true` on the orbit of `x`, so the orbit distribution
   assigns mass `1` to the predicate.
2. `Orbcrypt.probTrue_orbitDist_invariant_eq_zero` — symmetrically,
   when `f x ≠ f y`, the predicate is constantly `false` on the orbit
   of `x`, so the orbit distribution assigns mass `0`.
3. `Orbcrypt.indCPAAdvantage_invariantAttackAdversary_eq_one` —
   composes the two mass lemmas via `indCPAAdvantage_eq` to deliver
   the headline equality `indCPAAdvantage = 1`.

The KEM-layer companion of R-01 was found mathematically vacuous
during plan review (`docs/planning/PLAN_R_01_07_08_14_16.md`
§ "KEM-layer companion: dropped"): the KEM uniform-form game's two
distributions live in the basepoint's single orbit, so any G-invariant
distinguisher gives advantage `0`, not `1`. The KEM-layer parallel of
R-01's *existential* content (`G-invariant attack ⇒ KEMOIA is False`)
is already discharged by `det_kemoia_false_of_nontrivial_orbit` in
`Orbcrypt/KEM/Security.lean` (post-Workstream-E of audit 2026-04-23,
finding E-06). That theorem uses the *non*-G-invariant test
`fun c => decide (c = g₀ • basePoint)` to refute deterministic
KEMOIA — exactly the right adversarial shape because the KEM game
distinguishes ciphertexts within ONE orbit (so a G-invariant function
carries no signal there).

## Main results

* `Orbcrypt.invariantAttackAdversary` — adversary using a separating invariant
* `Orbcrypt.invariant_on_encrypt` — invariant function commutes with encryption
* `Orbcrypt.invariantAttackAdversary_correct` — adversary always guesses correctly
* `Orbcrypt.invariant_attack` — existence of a separating invariant implies a break
* `Orbcrypt.probTrue_orbitDist_invariant_eq_one` — constant-true mass lemma
  (Workstream R-01)
* `Orbcrypt.probTrue_orbitDist_invariant_eq_zero` — constant-false mass lemma
  (Workstream R-01)
* `Orbcrypt.indCPAAdvantage_invariantAttackAdversary_eq_one` — quantitative
  IND-1-CPA bound: separating G-invariant gives advantage exactly `1`
  (Workstream R-01 headline)

## References

* DEVELOPMENT.md §4.4 — invariant attack analysis
* COUNTEREXAMPLE.md — concrete invariant attack via Hamming weight
* formalization/phases/PHASE_4_CORE_THEOREMS.md — work units 4.6–4.9
* docs/planning/PLAN_R_01_07_08_14_16.md § R-01 — quantitative
  cross-orbit advantage lower bound
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

-- ============================================================================
-- Workstream R-01: Quantitative cross-orbit advantage lower bound
-- (audit 2026-04-29 § 8.1, research-scope discharge plan
-- `docs/planning/PLAN_R_01_07_08_14_16.md` § R-01)
-- ============================================================================
--
-- The deterministic `invariant_attack` theorem above delivers existence of
-- *one* `(g₀, g₁)` pair on which the invariant-attack adversary's two
-- guesses disagree. R-01 strengthens this to a *tight* probabilistic
-- equality: at the IND-1-CPA layer, the invariant-attack adversary
-- achieves advantage exactly `1`.

section RelativeAdvantage

open ENNReal

variable [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq Y]

/--
**R-01 mass lemma (constant-true case).** When `f` is G-invariant and
`f x = f y`, the Boolean predicate `fun c => decide (f c = f y)` is
constantly `true` on the orbit of `x`, so the orbit distribution
assigns mass `1` to the predicate.

**Proof strategy.**
1. Unfold `probTrue (orbitDist x) D = (orbitDist x).toOuterMeasure {z | D z}`
   and rewrite `orbitDist x = PMF.map (· • x) (uniformPMF G)` via
   `PMF.toOuterMeasure_map_apply` to land in
   `(uniformPMF G).toOuterMeasure {g | f (g • x) = f y}` form, which is
   `probTrue (uniformPMF G) (fun g => decide (f (g • x) = f y))`.
2. Apply `probTrue_uniformPMF_card` to express this as a filter-card ratio.
3. Show the filter equals `Finset.univ`: every `g : G` satisfies the
   predicate because G-invariance gives `f (g • x) = f x = f y`.
4. The ratio collapses to `|G| / |G| = 1` via `ENNReal.div_self`
   (`|G| ≠ 0` from `Nonempty G + Fintype G`; `|G| ≠ ⊤` from
   `ENNReal.natCast_ne_top`).

The result lives in `ℝ≥0∞` (matching `probTrue`'s codomain). The
headline `indCPAAdvantage_invariantAttackAdversary_eq_one` converts
to `ℝ` via `.toReal` only at the final step.
-/
theorem probTrue_orbitDist_invariant_eq_one
    {f : X → Y} (hInv : IsGInvariant (G := G) f) (x y : X)
    (hEq : f x = f y) :
    probTrue (orbitDist (G := G) x)
        (fun c => decide (f c = f y)) = 1 := by
  classical
  -- Step 1: rewrite probTrue through the orbitDist push-forward.
  -- `orbitDist x = PMF.map (· • x) (uniformPMF G)`, so
  -- `probTrue (orbitDist x) D = probTrue (uniformPMF G) (D ∘ (· • x))`.
  unfold orbitDist
  rw [probTrue_map]
  -- Step 2: filter-card form for the uniform PMF over G. After this rewrite,
  -- the numerator predicate carries a residual function-composition
  -- `((fun c => decide (...)) ∘ fun g => g • x)`. The hypothesis
  -- `h_filter_univ` matches that exact composed form, sidestepping the
  -- alpha-renaming pitfall a directly-stated `Finset.univ.filter
  -- (fun g => decide (f (g • x) = f y) = true)` would trigger under
  -- `rw` on the post-`probTrue_uniformPMF_card` goal.
  rw [probTrue_uniformPMF_card]
  -- Step 3: rewrite the filter to `Finset.univ` — every `g : G` satisfies
  -- the predicate because G-invariance gives `f (g • x) = f x = f y`.
  -- The per-element `Finset.filter_true_of_mem` consumes both `hInv` and
  -- `hEq` non-trivially (the goal `decide (f (g • x) = f y) = true`
  -- requires both ingredients).
  have h_filter_univ :
      Finset.univ.filter
          (fun g : G => ((fun c => decide (f c = f y)) ∘ (fun g' : G => g' • x)) g = true)
        = Finset.univ := by
    apply Finset.filter_true_of_mem
    intro g _
    -- Goal (after `Function.comp` β-reduction): `decide (f (g • x) = f y) = true`.
    -- f (g • x) = f x (by hInv) = f y (by hEq).
    show decide (f (g • x) = f y) = true
    have : f (g • x) = f y := (hInv g x).trans hEq
    exact decide_eq_true this
  rw [h_filter_univ]
  -- Step 4: |G| / |G| = 1 in ℝ≥0∞.
  -- |G| ≠ 0 (Nonempty G + Fintype G); |G| ≠ ⊤ (Nat-cast).
  have h_card_pos : 0 < Fintype.card G := Fintype.card_pos
  have h_ne_zero : (Fintype.card G : ℝ≥0∞) ≠ 0 := by
    exact_mod_cast h_card_pos.ne'
  have h_ne_top : (Fintype.card G : ℝ≥0∞) ≠ ⊤ := ENNReal.natCast_ne_top _
  rw [Finset.card_univ]
  exact ENNReal.div_self h_ne_zero h_ne_top

/--
**R-01 mass lemma (constant-false case).** Symmetric companion of
`probTrue_orbitDist_invariant_eq_one`: when `f` is G-invariant and
`f x ≠ f y`, the Boolean predicate `fun c => decide (f c = f y)` is
constantly `false` on the orbit of `x`, so the orbit distribution
assigns mass `0`.

**Proof strategy.** Same shape as the `_eq_one` companion: unfold
through the push-forward, rewrite to a filter-card ratio, show the
filter is *empty* (every `g` satisfies `f (g • x) = f x ≠ f y`),
and close `0 / |G| = 0` via `Finset.card_empty` + `zero_div`.
-/
theorem probTrue_orbitDist_invariant_eq_zero
    {f : X → Y} (hInv : IsGInvariant (G := G) f) (x y : X)
    (hNe : f x ≠ f y) :
    probTrue (orbitDist (G := G) x)
        (fun c => decide (f c = f y)) = 0 := by
  classical
  -- Step 1: route through the orbitDist push-forward.
  unfold orbitDist
  rw [probTrue_map]
  -- Step 2: filter-card form (same canonicalisation strategy as the
  -- `_eq_one` companion above).
  rw [probTrue_uniformPMF_card]
  -- Step 3: the filter is empty — every g falsifies the predicate
  -- because G-invariance gives f (g • x) = f x ≠ f y.
  have h_filter_empty :
      Finset.univ.filter
          (fun g : G => ((fun c => decide (f c = f y)) ∘ (fun g' : G => g' • x)) g = true)
        = ∅ := by
    apply Finset.filter_false_of_mem
    intro g _
    -- Goal (after `Function.comp` reduction):
    -- `¬ (decide (f (g • x) = f y) = true)`.
    show ¬ (decide (f (g • x) = f y) = true)
    have hfx_ne_fy : f (g • x) ≠ f y := by
      rw [hInv g x]; exact hNe
    simp [hfx_ne_fy]
  rw [h_filter_empty]
  -- Step 4: 0 / |G| = 0 in ℝ≥0∞.
  rw [Finset.card_empty]
  simp

end RelativeAdvantage

/--
**R-01 headline (Workstream R-01).** The IND-1-CPA advantage of the
invariant-attack adversary is *exactly* `1` whenever the underlying
G-invariant `f` separates the two message representatives. This is the
quantitative companion of `invariant_attack`: that theorem delivers
existence of one distinguishing `(g₀, g₁)` pair (deterministic
advantage `1` in the three-convention catalogue, see the
`invariant_attack` docstring); R-01 lifts the conclusion to the
two-distribution probabilistic convention with a tight equality.

**Cryptographic interpretation.** `indCPAAdvantage scheme A ≤ 1` is
the universal upper bound (`indCPAAdvantage_le_one`); R-01 says the
upper bound is *attained* by the invariant-attack adversary on every
scheme that admits a separating G-invariant. The bound is tight in
both directions:
* From `advantage_le_one`: the IND-1-CPA advantage of any adversary
  is at most `1`.
* From R-01: the invariant-attack adversary achieves *exactly* `1`,
  not just `≥ ε` for some `ε`.

**Composition with `concrete_oia_implies_1cpa`.** The probabilistic
upper bound `concrete_oia_implies_1cpa` says `ConcreteOIA scheme ε
⇒ indCPAAdvantage scheme A ≤ ε`. Combined with R-01, this means: any
scheme admitting a separating G-invariant cannot satisfy
`ConcreteOIA scheme ε` for any `ε < 1`. This formalises the audit-
disclosed "complete break" bound: a separating G-invariant rules out
all non-trivial probabilistic security, not just deterministic-OIA.

**Proof strategy.**
1. Unfold `indCPAAdvantage` via `indCPAAdvantage_eq` to expose the
   `advantage` form.
2. Unfold `advantage` to `|probTrue ... left - probTrue ... right|`.
3. Substitute the invariant-attack adversary's `choose` and `guess`:
   * `A.choose reps = (m₀, m₁)`.
   * `A.guess reps c = decide (f c = f (reps m₀))`.
4. Apply the two mass lemmas:
   * The `m₀` orbit distribution gives mass `1` (constant-true,
     `probTrue_orbitDist_invariant_eq_one` with `x = reps m₀`,
     `y = reps m₀`).
   * The `m₁` orbit distribution gives mass `0` (constant-false,
     `probTrue_orbitDist_invariant_eq_zero` with `x = reps m₁`,
     `y = reps m₀`, using `hSep`).
5. Arithmetic: `|1 - 0| = 1` via `abs_of_pos` + `norm_num`.
-/
theorem indCPAAdvantage_invariantAttackAdversary_eq_one
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    [DecidableEq Y]
    (scheme : OrbitEncScheme G X M) (f : X → Y) (m₀ m₁ : M)
    (hInv : IsGInvariant (G := G) f)
    (hSep : f (scheme.reps m₀) ≠ f (scheme.reps m₁)) :
    indCPAAdvantage scheme (invariantAttackAdversary f m₀ m₁) = 1 := by
  -- Step 1-2: unfold to the `advantage` form.
  rw [indCPAAdvantage_eq]
  unfold advantage
  -- Step 3: simplify the adversary's `choose` and `guess`.
  -- `A.choose reps = (m₀, m₁)` — `.1 = m₀`, `.2 = m₁`.
  -- `A.guess reps = fun c => if f c = f (reps m₀) then true else false`.
  simp only [invariantAttackAdversary_choose, invariantAttackAdversary_guess]
  -- The adversary's guess function `fun c => if f c = f (reps m₀) then true else false`
  -- is defeq to `fun c => decide (f c = f (reps m₀))`. The two mass lemmas are
  -- stated in `decide` form; bridge by `show ... = decide ...`.
  have h_guess_eq :
      (fun c => if f c = f (scheme.reps m₀) then true else false)
        = (fun c => decide (f c = f (scheme.reps m₀))) := by
    funext c
    by_cases h : f c = f (scheme.reps m₀)
    · simp [h]
    · simp [h]
  rw [h_guess_eq]
  -- Step 4a: mass lemma for the m₀ orbit (constant-true, x = y = reps m₀).
  rw [probTrue_orbitDist_invariant_eq_one (G := G) hInv
        (scheme.reps m₀) (scheme.reps m₀) rfl]
  -- Step 4b: mass lemma for the m₁ orbit (constant-false, x = reps m₁, y = reps m₀).
  rw [probTrue_orbitDist_invariant_eq_zero (G := G) hInv
        (scheme.reps m₁) (scheme.reps m₀) (Ne.symm hSep)]
  -- Step 5: |(1 : ℝ≥0∞).toReal - (0 : ℝ≥0∞).toReal| = |1 - 0| = 1.
  simp

end Orbcrypt
