/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Topology.Algebra.Order.LiminfLimsup

/-!
# Orbcrypt.Probability.Negligible

Negligible functions in the standard cryptographic sense: a function
`f : ℕ → ℝ` is negligible if it vanishes faster than any inverse polynomial.

## Main definitions

* `Orbcrypt.IsNegligible` — negligible function predicate

## Main results

* `Orbcrypt.isNegligible_zero` — the zero function is negligible
* `Orbcrypt.IsNegligible.add` — sum of negligible functions is negligible
* `Orbcrypt.IsNegligible.mul_const` — negligible times a constant is negligible

## References

* Katz & Lindell, "Introduction to Modern Cryptography", Definition 3.5
* DEVELOPMENT.md §5.2 — negligible advantage
* formalization/PRACTICAL_IMPROVEMENTS_PLAN.md — Phase 8, work unit 8.2
-/

namespace Orbcrypt

-- ============================================================================
-- Work Unit 8.2: Negligible function definition and closure properties
-- ============================================================================

/-- A function `f : ℕ → ℝ` is **negligible** if for every positive integer `c`,
    there exists a threshold `n₀` such that for all `n ≥ n₀`,
    `|f(n)| < n⁻ᶜ`.

    **Convention at `n = 0` (audit 2026-04-21 finding L7 / Workstream M).**
    Lean's extended-arithmetic convention assigns `(0 : ℝ)⁻¹ = 0`, so
    the clause `|f n| < (n : ℝ)⁻¹ ^ c` reduces at `n = 0` to
    * `|f 0| < 0 ^ c`, which is `|f 0| < 0` for `c ≥ 1` (trivially false),
    * `|f 0| < (0 : ℝ)⁻¹ ^ 0 = 1` at `c = 0` (possibly true).

    All in-tree proofs of `IsNegligible f` (see `isNegligible_zero`,
    `isNegligible_const_zero`, and the `IsNegligible.add` /
    `IsNegligible.mul_const` closure lemmas) choose `n₀ ≥ 1` to
    side-step the `n = 0` edge case. The intended semantics of the
    definition is the standard "eventually" form from Katz & Lindell:
    the `n = 0` case carries no content and is a harmless artefact of
    Lean's total `(·)⁻¹` convention, not a design decision. Downstream
    consumers that need a uniform behaviour at `n = 0` can either
    choose `n₀ ≥ 1` themselves (matching the in-tree proofs) or
    explicitly handle the edge case. -/
def IsNegligible (f : ℕ → ℝ) : Prop :=
  ∀ (c : ℕ), ∃ n₀ : ℕ, ∀ n : ℕ, n₀ ≤ n → |f n| < (n : ℝ)⁻¹ ^ c

/-- The zero function is negligible. -/
theorem isNegligible_zero : IsNegligible (fun _ => 0) := by
  intro c
  refine ⟨1, fun n hn => ?_⟩
  simp only [abs_zero]
  positivity

/-- A constant zero function (spelled differently) is negligible. -/
theorem isNegligible_const_zero : IsNegligible (0 : ℕ → ℝ) := by
  intro c
  refine ⟨1, fun n hn => ?_⟩
  simp only [Pi.zero_apply, abs_zero]
  positivity

/-- The sum of two negligible functions is negligible. -/
theorem IsNegligible.add {f g : ℕ → ℝ} (hf : IsNegligible f) (hg : IsNegligible g) :
    IsNegligible (fun n => f n + g n) := by
  intro c
  obtain ⟨n₁, h₁⟩ := hf (c + 1)
  obtain ⟨n₂, h₂⟩ := hg (c + 1)
  refine ⟨max (max n₁ n₂) 2, fun n hn => ?_⟩
  have hn₁ : n₁ ≤ n := le_trans (le_trans (le_max_left n₁ n₂) (le_max_left _ 2)) hn
  have hn₂ : n₂ ≤ n := le_trans (le_trans (le_max_right n₁ n₂) (le_max_left _ 2)) hn
  have hn2 : (2 : ℝ) ≤ n := by exact_mod_cast le_trans (le_max_right (max n₁ n₂) 2) hn
  have hn_pos : (0 : ℝ) < n := lt_of_lt_of_le two_pos hn2
  have hinv_nonneg : (0 : ℝ) ≤ (n : ℝ)⁻¹ := inv_nonneg.mpr hn_pos.le
  calc |f n + g n|
      ≤ |f n| + |g n| := abs_add_le _ _
    _ < (n : ℝ)⁻¹ ^ (c + 1) + (n : ℝ)⁻¹ ^ (c + 1) :=
        add_lt_add (h₁ n hn₁) (h₂ n hn₂)
    _ = 2 * ((n : ℝ)⁻¹ ^ c * (n : ℝ)⁻¹) := by ring
    _ ≤ (n : ℝ) * ((n : ℝ)⁻¹ ^ c * (n : ℝ)⁻¹) :=
        mul_le_mul_of_nonneg_right hn2 (mul_nonneg (pow_nonneg hinv_nonneg _) hinv_nonneg)
    _ = (n : ℝ)⁻¹ ^ c * ((n : ℝ) * (n : ℝ)⁻¹) := by ring
    _ = (n : ℝ)⁻¹ ^ c * 1 := by rw [mul_inv_cancel₀ (ne_of_gt hn_pos)]
    _ = (n : ℝ)⁻¹ ^ c := mul_one _

/-- Scaling a negligible function by a constant yields a negligible function.

    Proof strategy: For degree `c`, use degree `c+1` from `hf`. For large `n`,
    `|f(n) * C| = |f(n)| * |C| < n⁻⁽ᶜ⁺¹⁾ * |C| = |C| * n⁻ᶜ * n⁻¹ ≤ n⁻ᶜ`
    when `n ≥ |C|`. -/
theorem IsNegligible.mul_const {f : ℕ → ℝ} (hf : IsNegligible f) (C : ℝ) :
    IsNegligible (fun n => f n * C) := by
  intro c
  obtain ⟨n₁, h₁⟩ := hf (c + 1)
  -- Need n ≥ max(n₁, ⌈|C|⌉ + 1) so that n > |C| and n ≥ n₁ and n ≥ 1
  refine ⟨max (max n₁ (Nat.ceil (|C| + 1))) 1, fun n hn => ?_⟩
  have hn₁ : n₁ ≤ n := le_trans (le_trans (le_max_left n₁ _) (le_max_left _ 1)) hn
  have hfn := h₁ n hn₁
  have hn_ge_one : 1 ≤ n := le_trans (le_max_right _ 1) hn
  have hn_pos_from_one : (0 : ℝ) < n := by
    exact_mod_cast Nat.one_pos.trans_le hn_ge_one
  by_cases hC : C = 0
  · -- When C = 0, |f n * 0| = 0 < n⁻ᶜ
    simp only [hC, mul_zero, abs_zero]
    exact pow_pos (inv_pos.mpr hn_pos_from_one) _
  · have hC_pos : (0 : ℝ) < |C| := abs_pos.mpr hC
    have hn_ge_C : |C| < (n : ℝ) := by
      calc |C| < |C| + 1 := lt_add_one _
        _ ≤ ↑(Nat.ceil (|C| + 1)) := Nat.le_ceil _
        _ ≤ (n : ℝ) := by
          exact_mod_cast le_trans (le_trans (le_max_right n₁ _) (le_max_left _ 1)) hn
    have hn_pos : (0 : ℝ) < n := lt_trans hC_pos hn_ge_C
    have hinv_nonneg : (0 : ℝ) ≤ (n : ℝ)⁻¹ := inv_nonneg.mpr hn_pos.le
    calc |f n * C|
        = |f n| * |C| := abs_mul _ _
      _ < (n : ℝ)⁻¹ ^ (c + 1) * |C| :=
          mul_lt_mul_of_pos_right hfn hC_pos
      _ = |C| * ((n : ℝ)⁻¹ ^ c * (n : ℝ)⁻¹) := by ring
      _ < (n : ℝ) * ((n : ℝ)⁻¹ ^ c * (n : ℝ)⁻¹) :=
          mul_lt_mul_of_pos_right hn_ge_C
            (mul_pos (pow_pos (inv_pos.mpr hn_pos) _) (inv_pos.mpr hn_pos))
      _ = (n : ℝ)⁻¹ ^ c * ((n : ℝ) * (n : ℝ)⁻¹) := by ring
      _ = (n : ℝ)⁻¹ ^ c * 1 := by rw [mul_inv_cancel₀ (ne_of_gt hn_pos)]
      _ = (n : ℝ)⁻¹ ^ c := mul_one _

end Orbcrypt
