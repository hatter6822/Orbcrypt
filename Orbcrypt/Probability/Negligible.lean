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
    `|f(n)| < n⁻ᶜ`. -/
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

end Orbcrypt
