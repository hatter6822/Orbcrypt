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

end Orbcrypt
