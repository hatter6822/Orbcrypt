/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.Probability.Monad
import Orbcrypt.Probability.Negligible

/-!
# Orbcrypt.Probability.Advantage

Statistical distance and distinguishing advantage for probability
distributions, the core quantitative tool for cryptographic security proofs.

## Main definitions

* `Orbcrypt.advantage` — distinguishing advantage of a Boolean function
  between two PMFs: `|Pr_{d₀}[D = true] - Pr_{d₁}[D = true]|`

## Main results

* `Orbcrypt.advantage_nonneg` — advantage is non-negative
* `Orbcrypt.advantage_symm` — advantage is symmetric in d₀, d₁
* `Orbcrypt.advantage_self` — self-advantage is zero
* `Orbcrypt.advantage_le_one` — advantage is at most 1
* `Orbcrypt.advantage_triangle` — triangle inequality for advantage
* `Orbcrypt.hybrid_argument` — general hybrid argument (n hybrids)
* `Orbcrypt.advantage_bool_le_tv` — total-variation upper bound for any
  `D : Bool → Bool`: `advantage D μ ν ≤ |(μ true).toReal − (ν true).toReal|`
  (Workstream R-12, audit 2026-04-29 § 8.1).
* `Orbcrypt.advantage_bool_id_eq_tv` — tightness witness: at `D = id`,
  the advantage *equals* the total-variation distance between the two
  PMFs at the singleton `{true}`.

## Design

Advantage is defined using `ℝ≥0∞` probabilities converted to `ℝ` via
`.toReal`, then taking the absolute difference. This matches the standard
cryptographic convention while leveraging Mathlib's PMF infrastructure.

## References

* Katz & Lindell §3.2 — distinguishing advantage
* DEVELOPMENT.md §5.2 — OIA advantage
* formalization/PRACTICAL_IMPROVEMENTS_PLAN.md — Phase 8, work units 8.3, 8.9
-/

namespace Orbcrypt

open ENNReal

-- ============================================================================
-- Work Unit 8.3a: Core advantage definition
-- ============================================================================

/-- Distinguishing advantage of a Boolean function `D` between two
    distributions `d₀` and `d₁`:
    `Adv(D, d₀, d₁) = |Pr_{d₀}[D(x) = true] - Pr_{d₁}[D(x) = true]|`

    This is the standard cryptographic measure of how well `D` can tell
    apart samples from `d₀` vs `d₁`. -/
noncomputable def advantage {α : Type*} (D : α → Bool) (d₀ d₁ : PMF α) : ℝ :=
  |(probTrue d₀ D).toReal - (probTrue d₁ D).toReal|

-- ============================================================================
-- Work Unit 8.3b: Basic properties
-- ============================================================================

/-- Advantage is non-negative (it is an absolute value). -/
theorem advantage_nonneg {α : Type*} (D : α → Bool) (d₀ d₁ : PMF α) :
    0 ≤ advantage D d₀ d₁ :=
  abs_nonneg _

/-- Advantage is symmetric: swapping the two distributions preserves advantage. -/
theorem advantage_symm {α : Type*} (D : α → Bool) (d₀ d₁ : PMF α) :
    advantage D d₀ d₁ = advantage D d₁ d₀ :=
  abs_sub_comm _ _

/-- Self-advantage is zero: no distinguisher can tell a distribution from itself. -/
theorem advantage_self {α : Type*} (D : α → Bool) (d : PMF α) :
    advantage D d d = 0 := by
  simp [advantage]

/-- Advantage is at most 1, since probabilities lie in [0, 1]. -/
theorem advantage_le_one {α : Type*} (D : α → Bool) (d₀ d₁ : PMF α) :
    advantage D d₀ d₁ ≤ 1 := by
  unfold advantage
  have h₀ : (probTrue d₀ D).toReal ≤ 1 :=
    ENNReal.toReal_le_of_le_ofReal one_pos.le
      (by rw [ENNReal.ofReal_one]; exact probTrue_le_one d₀ D)
  have h₁ : (probTrue d₁ D).toReal ≤ 1 :=
    ENNReal.toReal_le_of_le_ofReal one_pos.le
      (by rw [ENNReal.ofReal_one]; exact probTrue_le_one d₁ D)
  have h₀' : 0 ≤ (probTrue d₀ D).toReal := ENNReal.toReal_nonneg
  have h₁' : 0 ≤ (probTrue d₁ D).toReal := ENNReal.toReal_nonneg
  rw [abs_le]
  constructor <;> linarith

-- ============================================================================
-- Work Unit 8.3c: Triangle inequality
-- ============================================================================

/-- Triangle inequality for advantage: the advantage between d₀ and d₂ is
    bounded by the sum of advantages through an intermediate d₁.

    This is the foundational lemma for hybrid arguments. -/
theorem advantage_triangle {α : Type*} (D : α → Bool) (d₀ d₁ d₂ : PMF α) :
    advantage D d₀ d₂ ≤ advantage D d₀ d₁ + advantage D d₁ d₂ := by
  unfold advantage
  -- |a - c| ≤ |a - b| + |b - c|
  exact abs_sub_le _ _ _

-- ============================================================================
-- Work Unit 8.9a: Two-hybrid base case (alias for triangle inequality)
-- ============================================================================

/-- Two-hybrid lemma: advantage through two steps is bounded by the sum.
    This is an alias for `advantage_triangle`, serving as the base case
    for the general hybrid argument. -/
theorem hybrid_two {α : Type*} (d₀ d₁ d₂ : PMF α) (D : α → Bool) :
    advantage D d₀ d₂ ≤ advantage D d₀ d₁ + advantage D d₁ d₂ :=
  advantage_triangle D d₀ d₁ d₂

-- ============================================================================
-- Work Unit 8.9b-c: General hybrid argument
-- ============================================================================

/-- Helper lemma for the hybrid argument: inductive step using Nat indexing.
    The advantage between index 0 and index n is bounded by the sum of
    adjacent advantages for indices 0..n-1. -/
private theorem hybrid_argument_nat {α : Type*} (D : α → Bool)
    (n : ℕ) (hybrids : ℕ → PMF α) :
    advantage D (hybrids 0) (hybrids n) ≤
    Finset.sum (Finset.range n) (fun i =>
      advantage D (hybrids i) (hybrids (i + 1))) := by
  induction n with
  | zero => simp [advantage_self]
  | succ n ih =>
    calc advantage D (hybrids 0) (hybrids (n + 1))
        ≤ advantage D (hybrids 0) (hybrids n) +
          advantage D (hybrids n) (hybrids (n + 1)) :=
          advantage_triangle D _ _ _
      _ ≤ Finset.sum (Finset.range n) (fun i =>
            advantage D (hybrids i) (hybrids (i + 1))) +
          advantage D (hybrids n) (hybrids (n + 1)) := by linarith
      _ = Finset.sum (Finset.range (n + 1)) (fun i =>
            advantage D (hybrids i) (hybrids (i + 1))) := by
          rw [Finset.sum_range_succ]

/-- General hybrid argument (ℕ-indexed): the advantage between distributions
    at index 0 and index `n` is bounded by the telescoping sum of adjacent
    advantages.

    This is the key technical tool for multi-query security reductions.
    Given `n+1` hybrid distributions `H₀, H₁, ..., Hₙ`, we have:
    `Adv(D, H₀, Hₙ) ≤ Σᵢ₌₀ⁿ⁻¹ Adv(D, Hᵢ, Hᵢ₊₁)` -/
theorem hybrid_argument {α : Type*} (n : ℕ) (hybrids : ℕ → PMF α)
    (D : α → Bool) :
    advantage D (hybrids 0) (hybrids n) ≤
    Finset.sum (Finset.range n) (fun i =>
      advantage D (hybrids i) (hybrids (i + 1))) :=
  hybrid_argument_nat D n hybrids

-- ============================================================================
-- Workstream E8 prerequisite: uniform hybrid argument (Q * ε bound)
-- ============================================================================

/-- **Uniform hybrid argument.** If every adjacent hybrid pair has
    distinguishing advantage at most `ε`, the end-to-end advantage through
    `Q` steps is at most `Q · ε`.

    This is a direct consequence of `hybrid_argument` (which gives the
    telescoping *sum* bound) plus the identity `Σᵢ₌₀^{Q-1} ε = Q · ε`. It
    is the atomic building block used by Workstream E8's multi-query
    IND-Q-CPA security reduction to telescope `Q` ConcreteOIA-bounded
    per-step advantages.

    **Note (audit 2026-04-21 finding L2 / Workstream M).** No `0 ≤ ε`
    hypothesis is carried on the signature. For `ε < 0`, the per-step
    bound `h_step` is unsatisfiable (advantage is always `≥ 0` via
    `advantage_nonneg`), so the conclusion `advantage D (hybrids 0)
    (hybrids Q) ≤ (Q : ℝ) * ε` holds vacuously (its hypothesis is
    `False`). The intended use case is `ε ∈ [0, 1]`; the library does
    not enforce this at the type level because the `ε < 0` branch is
    harmless. -/
theorem hybrid_argument_uniform {α : Type*} (Q : ℕ) (hybrids : ℕ → PMF α)
    (D : α → Bool) (ε : ℝ)
    (h_step : ∀ i, i < Q → advantage D (hybrids i) (hybrids (i + 1)) ≤ ε) :
    advantage D (hybrids 0) (hybrids Q) ≤ (Q : ℝ) * ε := by
  have h_sum :
      Finset.sum (Finset.range Q) (fun i =>
        advantage D (hybrids i) (hybrids (i + 1))) ≤
      Finset.sum (Finset.range Q) (fun _ : ℕ => ε) := by
    apply Finset.sum_le_sum
    intro i hi
    exact h_step i (Finset.mem_range.mp hi)
  calc advantage D (hybrids 0) (hybrids Q)
      ≤ Finset.sum (Finset.range Q) (fun i =>
          advantage D (hybrids i) (hybrids (i + 1))) :=
        hybrid_argument Q hybrids D
    _ ≤ Finset.sum (Finset.range Q) (fun _ : ℕ => ε) := h_sum
    _ = (Q : ℝ) * ε := by
        rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]

-- ============================================================================
-- Workstream R-12 — Total-variation bound for Bool distinguishers
-- (audit 2026-04-29 plan § 8.1, research-scope discharge plan § R-12 Layer A)
-- ============================================================================

/-- **`probTrue` on `Bool` as a closed-form sum.** For a PMF on `Bool`
    and any Boolean test `D : Bool → Bool`, the probability that `D`
    returns `true` decomposes as the indicator-weighted sum
    `(if D true then μ true else 0) + (if D false then μ false else 0)`.

    Proof: unfold `probTrue` to its `tsum`-of-indicator form via
    `probTrue_eq_tsum`, collapse the `tsum` over `Bool` to a binary
    `Finset.sum` via `tsum_fintype` + `Fintype.sum_bool`, then evaluate
    the `Set.indicator` at each Boolean value. -/
theorem probTrue_bool_eq (μ : PMF Bool) (D : Bool → Bool) :
    probTrue μ D = (if D true = true then μ true else 0) +
                   (if D false = true then μ false else 0) := by
  rw [probTrue_eq_tsum, tsum_fintype, Fintype.sum_bool]
  simp [Set.indicator_apply, Set.mem_setOf_eq]

/-- **PMF sum-to-1 on `Bool` in `ℝ`.** The two `.toReal`-converted
    masses of a PMF on `Bool` add up to `1`.

    Proof: `μ.tsum_coe = 1` in `ℝ≥0∞`; collapse the `tsum` via
    `tsum_fintype` + `Fintype.sum_bool` to `μ true + μ false = 1`;
    convert to `ℝ` using `ENNReal.toReal_add` (both summands finite,
    each `≤ 1`) plus `ENNReal.one_toReal`. -/
theorem pmf_bool_sum_eq_one_toReal (μ : PMF Bool) :
    (μ true).toReal + (μ false).toReal = 1 := by
  -- Step 1 — the ENNReal sum-to-1 fact.
  have h_sum_one : μ true + μ false = (1 : ℝ≥0∞) := by
    have h := μ.tsum_coe
    rw [tsum_fintype, Fintype.sum_bool] at h
    exact h
  -- Step 2 — both summands are finite (≤ 1 < ⊤).
  have h_t : μ true ≠ ⊤ := PMF.apply_ne_top μ true
  have h_f : μ false ≠ ⊤ := PMF.apply_ne_top μ false
  -- Step 3 — push `.toReal` through the addition + `1`.
  have := congrArg ENNReal.toReal h_sum_one
  rwa [ENNReal.toReal_add h_t h_f, ENNReal.toReal_one] at this

/-- **`probTrue` on `Bool` in `ℝ`.** `.toReal`-converted form of
    `probTrue_bool_eq`.  The conversion is clean because each summand
    is either `0` or `μ x` (both `≠ ⊤`). -/
theorem probTrue_bool_toReal_eq (μ : PMF Bool) (D : Bool → Bool) :
    (probTrue μ D).toReal =
      (if D true = true then (μ true).toReal else 0) +
      (if D false = true then (μ false).toReal else 0) := by
  rw [probTrue_bool_eq]
  -- Both branches of each `if` are `≠ ⊤`: the `then` branch is `μ x` (a
  -- PMF value, `≠ ⊤`); the `else` branch is `0 ≠ ⊤`.
  have h_t_finite : (if D true = true then μ true else (0 : ℝ≥0∞)) ≠ ⊤ := by
    by_cases h : D true = true
    · simp [h, PMF.apply_ne_top]
    · simp [h]
  have h_f_finite : (if D false = true then μ false else (0 : ℝ≥0∞)) ≠ ⊤ := by
    by_cases h : D false = true
    · simp [h, PMF.apply_ne_top]
    · simp [h]
  rw [ENNReal.toReal_add h_t_finite h_f_finite]
  -- Push `.toReal` through each `if-then-else` separately.
  by_cases h_t : D true = true
  · by_cases h_f : D false = true
    · simp [h_t, h_f]
    · simp [h_t, h_f]
  · by_cases h_f : D false = true
    · simp [h_t, h_f]
    · simp [h_t, h_f]

/-- **R-12 Layer A — Total-variation bound on Boolean distinguishers.**
    For any `D : Bool → Bool` and any pair of PMFs `μ, ν : PMF Bool`,
    the distinguishing advantage of `D` between `μ` and `ν` is at most
    the total-variation distance between the two PMFs evaluated at the
    singleton `{true}`:

    `advantage D μ ν ≤ |(μ true).toReal − (ν true).toReal|`.

    **Proof structure.** Case-split on the four Boolean functions
    `D : Bool → Bool` (parametrised by `(D true, D false)` ∈
    `{(false, false), (true, true), (true, false), (false, true)}`):
    * `D = const false`: both `probTrue` values are `0`, advantage is
      `0`, bound holds vacuously.
    * `D = const true`: both `probTrue` values equal `(μ true).toReal +
      (μ false).toReal = 1` (by `pmf_bool_sum_eq_one_toReal`),
      advantage is `|1 − 1| = 0`.
    * `D = id` (`D true = true, D false = false`): `probTrue μ D =
      (μ true).toReal`, `probTrue ν D = (ν true).toReal`, advantage
      *equals* the bound.
    * `D = not` (`D true = false, D false = true`): `probTrue μ D =
      (μ false).toReal = 1 − (μ true).toReal` (and similarly for ν);
      the difference reduces to `(ν true).toReal − (μ true).toReal`,
      whose absolute value is `|μ true − ν true|`.

    Closes Workstream R-12 audit 2026-04-29 plan § 8.1. -/
theorem advantage_bool_le_tv (D : Bool → Bool) (μ ν : PMF Bool) :
    advantage D μ ν ≤ |(μ true).toReal - (ν true).toReal| := by
  unfold advantage
  -- Apply the closed-form `probTrue` evaluation on Bool.
  rw [probTrue_bool_toReal_eq, probTrue_bool_toReal_eq]
  -- Sum-to-1 facts for both PMFs (used by the `D = const true` and
  -- `D = not` branches to substitute `μ false = 1 − μ true`).
  have hμ_sum : (μ true).toReal + (μ false).toReal = 1 :=
    pmf_bool_sum_eq_one_toReal μ
  have hν_sum : (ν true).toReal + (ν false).toReal = 1 :=
    pmf_bool_sum_eq_one_toReal ν
  -- Range bounds (used in `linarith`-style closures of degenerate
  -- branches and `abs` rewrites).
  have hμ_t_nn : 0 ≤ (μ true).toReal := ENNReal.toReal_nonneg
  have hμ_f_nn : 0 ≤ (μ false).toReal := ENNReal.toReal_nonneg
  have hν_t_nn : 0 ≤ (ν true).toReal := ENNReal.toReal_nonneg
  have hν_f_nn : 0 ≤ (ν false).toReal := ENNReal.toReal_nonneg
  -- Case-split on `D true` and `D false`. Each branch reduces to a
  -- linear-arithmetic / `abs`-rewrite closure.
  by_cases h_t : D true = true
  · by_cases h_f : D false = true
    · -- D = const true: both probTrue values equal 1.
      rw [if_pos h_t, if_pos h_f, if_pos h_t, if_pos h_f]
      -- Goal: |(μT + μF) − (νT + νF)| ≤ |μT − νT|. Both LHS sums = 1.
      rw [hμ_sum, hν_sum]
      simp
    · -- D = id: probTrue μ D = μ true, probTrue ν D = ν true.
      rw [if_pos h_t, if_neg h_f, if_pos h_t, if_neg h_f]
      simp
  · by_cases h_f : D false = true
    · -- D = not: probTrue μ D = μ false = 1 − μ true.
      rw [if_neg h_t, if_pos h_f, if_neg h_t, if_pos h_f]
      simp only [zero_add]
      -- Goal: |μ false − ν false| ≤ |μ true − ν true|.
      -- Substitute μ false = 1 − μ true and similarly for ν.
      have hμ_f_eq : (μ false).toReal = 1 - (μ true).toReal := by linarith
      have hν_f_eq : (ν false).toReal = 1 - (ν true).toReal := by linarith
      rw [hμ_f_eq, hν_f_eq]
      -- Goal: |(1 − μT) − (1 − νT)| ≤ |μT − νT|. Algebraically equal.
      have h_eq : ((1 : ℝ) - (μ true).toReal) - (1 - (ν true).toReal)
                = (ν true).toReal - (μ true).toReal := by ring
      rw [h_eq, abs_sub_comm]
    · -- D = const false: both probTrue values are 0.
      rw [if_neg h_t, if_neg h_f, if_neg h_t, if_neg h_f]
      simp [abs_nonneg]

/-- **R-12 Layer A — Tightness at `D = id`.** When the distinguisher
    is the identity Boolean function, the bound from
    `advantage_bool_le_tv` is *exact*:

    `advantage id μ ν = |(μ true).toReal − (ν true).toReal|`.

    This anchors the tightness witness for the `concreteHidingBundle`
    fixture: the bound `1/4` proven by `concreteHiding_tight` is
    achieved exactly at `D = id`. -/
theorem advantage_bool_id_eq_tv (μ ν : PMF Bool) :
    advantage (id : Bool → Bool) μ ν = |(μ true).toReal - (ν true).toReal| := by
  unfold advantage
  rw [probTrue_bool_toReal_eq, probTrue_bool_toReal_eq]
  -- D := id, so `D true = true`, `D false = false`.
  -- probTrue μ id = μ true; probTrue ν id = ν true.
  simp

-- ============================================================================
-- Workstream R-09 — Convexity of advantage along an inserted coordinate
-- (audit 2026-04-29 § 8.1, research-scope discharge plan § R-09 Layer 2)
-- ============================================================================

/-- **R-09 Layer 2 — Marginalised-advantage bound.** This lemma is the
    "convexity-of-TV" content underlying the per-step hybrid bound.

    For any two functions `F G : (Fin (n+1) → α) → β` over a finite
    nonempty type `α`, any Boolean distinguisher `D : β → Bool`, and
    any insertion point `j₀ : Fin (n+1)`: if **for every "rest"**
    `rest : Fin n → α` the per-rest sum-of-indicators-difference is
    at most `(Fintype.card α : ℝ) * ε` in absolute value, then the
    advantage between the push-forward PMFs is at most `ε`.

    **Cryptographic intuition.** When `F` and `G` differ in their
    output only as a function of one input coordinate `gs[j₀]` (with
    the other coords passing through unchanged), marginalising over
    the rest of the coordinates reduces the global advantage to
    a per-rest single-coordinate advantage. The hypothesis
    `h_per_rest` packages this per-rest bound, and the conclusion is
    the global bound — same `ε`.

    **Proof.** Express each PMF.map'd probTrue as a filter-card ratio
    via `probTrue_PMF_map_uniformPMF_toReal`. The advantage becomes
    `|card(F-filter) − card(G-filter)| / |α|^(n+1)`. Convert each card
    to a sum-of-indicators (via `Finset.natCast_card_filter`).
    Decompose along the inserted coordinate using
    `sum_pi_succAbove_eq_sum_sum_insertNth`. Apply the triangle
    inequality on the outer sum. Bound each per-rest inner term by
    `|α| · ε` using the hypothesis. Aggregate. -/
theorem advantage_pmf_map_uniform_pi_factor_bound
    {α : Type*} [Fintype α] [Nonempty α] [DecidableEq α]
    {β : Type*} [DecidableEq β]
    {n : ℕ} (j₀ : Fin (n + 1))
    (F G : (Fin (n + 1) → α) → β) (D : β → Bool) (ε : ℝ)
    (h_per_rest : ∀ rest : Fin n → α,
      |(∑ a : α, ((if D (F (Fin.insertNth j₀ a rest)) = true then (1 : ℝ) else 0)
                - (if D (G (Fin.insertNth j₀ a rest)) = true then (1 : ℝ) else 0)))|
      ≤ (Fintype.card α : ℝ) * ε) :
    advantage D
      (PMF.map F (uniformPMF (Fin (n + 1) → α)))
      (PMF.map G (uniformPMF (Fin (n + 1) → α))) ≤ ε := by
  classical
  -- Setup: positivity of the cardinality and the divisor.
  have h_card_pos : 0 < Fintype.card α := Fintype.card_pos
  have h_card_real_pos : (0 : ℝ) < (Fintype.card α : ℝ) := by
    exact_mod_cast h_card_pos
  have h_card_pi : Fintype.card (Fin (n + 1) → α) = (Fintype.card α) ^ (n + 1) :=
    Fintype.card_pi_const α (n + 1)
  have h_pi_pos : 0 < (Fintype.card α) ^ (n + 1) := by positivity
  have h_pi_real_pos : (0 : ℝ) < ((Fintype.card α) ^ (n + 1) : ℝ) := by
    exact_mod_cast h_pi_pos
  -- Step 1 — express advantage as |card-difference| / N.
  unfold advantage
  rw [probTrue_PMF_map_uniformPMF_toReal, probTrue_PMF_map_uniformPMF_toReal]
  rw [h_card_pi]
  -- Normalise the cast: `↑(|α|^(n+1)) = (↑|α|)^(n+1)` in ℝ.
  push_cast
  -- Step 2 — combine into a single fraction.
  rw [show ∀ a b : ℝ,
      (a / ((Fintype.card α) ^ (n + 1) : ℝ))
      - (b / ((Fintype.card α) ^ (n + 1) : ℝ))
      = (a - b) / ((Fintype.card α) ^ (n + 1) : ℝ) from
        fun a b => by ring]
  -- Step 3 — push abs through div (denominator positive).
  rw [abs_div, abs_of_pos h_pi_real_pos]
  -- Goal: |numer| / |α|^(n+1) ≤ ε. Multiply both sides by |α|^(n+1):
  rw [div_le_iff₀ h_pi_real_pos]
  -- Goal: |numer| ≤ ε · |α|^(n+1)
  -- Step 4 — express each card as a sum of indicators.
  have h_card_F :
      ((Finset.univ.filter (fun gs : Fin (n + 1) → α => D (F gs) = true)).card : ℝ)
      = ∑ gs : Fin (n + 1) → α, (if D (F gs) = true then (1 : ℝ) else 0) := by
    rw [Finset.natCast_card_filter]
  have h_card_G :
      ((Finset.univ.filter (fun gs : Fin (n + 1) → α => D (G gs) = true)).card : ℝ)
      = ∑ gs : Fin (n + 1) → α, (if D (G gs) = true then (1 : ℝ) else 0) := by
    rw [Finset.natCast_card_filter]
  rw [h_card_F, h_card_G]
  -- Step 5 — combine into a single sum.
  rw [← Finset.sum_sub_distrib]
  -- Step 6 — apply the sum factorisation along j₀.
  rw [sum_pi_succAbove_eq_sum_sum_insertNth (j₀ := j₀)
        (f := fun gs => (if D (F gs) = true then (1 : ℝ) else 0)
                     - (if D (G gs) = true then (1 : ℝ) else 0))]
  -- Step 7 — swap the order of summation: outer over `rest`, inner over `a`.
  rw [Finset.sum_comm]
  -- Goal: |∑ rest, ∑ a, (...indicator difference...)| ≤ ε · |α|^(n+1)
  -- Step 8 — bound by triangle inequality on the outer sum.
  refine le_trans (Finset.abs_sum_le_sum_abs _ _) ?_
  -- Goal: ∑ rest, |∑ a, (...indicator difference...)| ≤ ε · |α|^(n+1)
  -- Step 9 — apply the per-rest hypothesis.
  refine le_trans (Finset.sum_le_sum (fun rest _ => h_per_rest rest)) ?_
  -- Goal: ∑ rest, |α| · ε ≤ ε · |α|^(n+1)
  rw [Finset.sum_const, Finset.card_univ]
  -- Goal: |Fin n → α| • ((|α| : ℝ) · ε) ≤ ε · |α|^(n+1)
  rw [nsmul_eq_mul]
  -- Goal: |Fin n → α| · (|α| · ε) ≤ ε · |α|^(n+1)
  -- Cardinality: |Fin n → α| = |α|^n
  have h_rest_card : Fintype.card (Fin n → α) = (Fintype.card α) ^ n :=
    Fintype.card_pi_const α n
  rw [h_rest_card]
  -- Goal: (|α|^n : ℝ) · (|α| · ε) ≤ ε · |α|^(n+1)
  push_cast
  -- Both sides are equal up to commutativity; close `X ≤ X` after ring_nf.
  ring_nf
  exact le_refl _

end Orbcrypt
