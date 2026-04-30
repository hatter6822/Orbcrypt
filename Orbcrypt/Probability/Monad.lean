/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Mathlib.Probability.ProbabilityMassFunction.Constructions
import Mathlib.Probability.Distributions.Uniform
import Mathlib.Data.Fin.Tuple.Basic

/-!
# Orbcrypt.Probability.Monad

Thin wrappers around Mathlib's `PMF` (Probability Mass Function) type,
providing a convenient API for cryptographic probability arguments.

## Main definitions

* `Orbcrypt.uniformPMF` — uniform distribution over a finite nonempty type
* `Orbcrypt.probEvent` — probability of an event under a PMF
* `Orbcrypt.probTrue` — probability that a Boolean function returns `true`

## Main results

* `Orbcrypt.probEvent_certain` — `Pr[True] = 1`
* `Orbcrypt.probEvent_impossible` — `Pr[False] = 0`
* `Orbcrypt.probTrue_le_one` — `Pr[f = true] ≤ 1`

## Design

We use Mathlib's `PMF` (discrete probability distributions valued in `ℝ≥0∞`)
rather than a custom distribution type, following the maximal-Mathlib-reuse
convention. The wrappers provide short names and hide `ℝ≥0∞` plumbing from
downstream cryptographic definitions.

## References

* Mathlib `PMF` — `Mathlib.Probability.ProbabilityMassFunction.Basic`
* Mathlib `PMF.uniformOfFintype` — `Mathlib.Probability.Distributions.Uniform`
* formalization/PRACTICAL_IMPROVEMENTS_PLAN.md — Phase 8, work unit 8.1
-/

namespace Orbcrypt

open PMF ENNReal MeasureTheory

-- ============================================================================
-- Work Unit 8.1a: Uniform distribution wrapper
-- ============================================================================

/-- Uniform distribution over a finite nonempty type. Each element receives
    probability `1 / |α|`. This wraps `PMF.uniformOfFintype` from Mathlib. -/
noncomputable def uniformPMF (α : Type*) [Fintype α] [Nonempty α] : PMF α :=
  PMF.uniformOfFintype α

/-- Each element has probability `1 / |α|` under the uniform distribution. -/
theorem uniformPMF_apply {α : Type*} [Fintype α] [Nonempty α] (a : α) :
    uniformPMF α a = (Fintype.card α : ℝ≥0∞)⁻¹ :=
  PMF.uniformOfFintype_apply a

/-- Every element is in the support of the uniform distribution. -/
theorem mem_support_uniformPMF {α : Type*} [Fintype α] [Nonempty α] (a : α) :
    a ∈ (uniformPMF α).support :=
  PMF.mem_support_uniformOfFintype a

-- ============================================================================
-- Work Unit 8.1b: Probability of events
-- ============================================================================

/-- Probability of an event (a set) under a PMF, measured via `toOuterMeasure`.
    Returns a value in `ℝ≥0∞` (extended non-negative reals). -/
noncomputable def probEvent {α : Type*} (d : PMF α) (p : α → Prop)
    [DecidablePred p] : ℝ≥0∞ :=
  d.toOuterMeasure {x | p x}

/-- Probability that a Boolean-valued function returns `true` under a PMF. -/
noncomputable def probTrue {α : Type*} (d : PMF α) (f : α → Bool) : ℝ≥0∞ :=
  d.toOuterMeasure {x | f x = true}

/-- `probTrue` can be expressed as a sum over the type. -/
theorem probTrue_eq_tsum {α : Type*} (d : PMF α) (f : α → Bool) :
    probTrue d f = ∑' x, ({x | f x = true} : Set α).indicator d x :=
  d.toOuterMeasure_apply {x | f x = true}

-- ============================================================================
-- Work Unit 8.1c: Sanity lemmas
-- ============================================================================

/-- The probability of a certain event is 1. -/
theorem probEvent_certain {α : Type*} (d : PMF α) :
    probEvent d (fun _ => True) = 1 := by
  unfold probEvent
  rw [Set.setOf_true]
  exact (PMF.toOuterMeasure_apply_eq_one_iff d Set.univ).mpr (fun _ _ => Set.mem_univ _)

/-- The probability of an impossible event is 0. -/
theorem probEvent_impossible {α : Type*} (d : PMF α) :
    probEvent d (fun _ => False) = 0 := by
  unfold probEvent
  rw [Set.setOf_false]
  exact (PMF.toOuterMeasure_apply_eq_zero_iff d ∅).mpr (by simp [Set.disjoint_empty])

/-- `probTrue` is at most 1 (probability of a sub-event). -/
theorem probTrue_le_one {α : Type*} (d : PMF α) (f : α → Bool) :
    probTrue d f ≤ 1 := by
  have h_univ : d.toOuterMeasure Set.univ = 1 :=
    (PMF.toOuterMeasure_apply_eq_one_iff d Set.univ).mpr (fun _ _ => Set.mem_univ _)
  calc probTrue d f = d.toOuterMeasure {x | f x = true} := rfl
    _ ≤ d.toOuterMeasure Set.univ := d.toOuterMeasure.mono (Set.subset_univ _)
    _ = 1 := h_univ

-- ============================================================================
-- Workstream E7 — Product PMF infrastructure for multi-query hybrids
-- ============================================================================

/-- **Workstream E7a.** Uniform distribution over `Fin Q → α`, the canonical
    product-PMF used for multi-query cryptographic security reductions.

    Defined as `uniformPMF (Fin Q → α)`: `Fin Q → α` inherits `Fintype` from
    `Pi.fintype` and `Nonempty` from `Pi.instNonempty`, so we can directly
    apply `uniformPMF` to it without an explicit product construction. This
    gives each tuple `f : Fin Q → α` probability `1 / |α|^Q`.

    **Why a named wrapper.** Threading `uniformPMF (Fin Q → α)` through
    downstream proofs is unwieldy when typeclass inference needs to be
    spelled out; `uniformPMFTuple` centralises that step. -/
noncomputable def uniformPMFTuple (α : Type*) (Q : ℕ)
    [Fintype α] [Nonempty α] : PMF (Fin Q → α) :=
  uniformPMF (Fin Q → α)

/-- Each tuple `f : Fin Q → α` has probability `1 / |α|^Q` under
    `uniformPMFTuple`.

    `|Fin Q → α| = |α|^Q` by `Fintype.card_pi_const`, so `uniformPMF_apply`
    delivers the result after one rewrite through that card identity. -/
theorem uniformPMFTuple_apply {α : Type*} (Q : ℕ)
    [Fintype α] [Nonempty α] (f : Fin Q → α) :
    uniformPMFTuple α Q f = ((Fintype.card α) ^ Q : ℝ≥0∞)⁻¹ := by
  unfold uniformPMFTuple
  rw [uniformPMF_apply, Fintype.card_pi_const]
  push_cast
  rfl

/-- `uniformPMFTuple α Q` is in the support of every tuple `f : Fin Q → α`.
    Direct consequence of uniformity over a nonempty finite type. -/
theorem mem_support_uniformPMFTuple {α : Type*} (Q : ℕ)
    [Fintype α] [Nonempty α] (f : Fin Q → α) :
    f ∈ (uniformPMFTuple α Q).support :=
  mem_support_uniformPMF f

-- ============================================================================
-- Push-forward and uniform-Fintype computational helpers
-- ============================================================================

/-- **`probTrue` push-forward through `PMF.map`.** For any `f : α → β`
    and any Boolean `D : β → Bool`, the probability that `D` returns
    `true` under `μ.map f` equals the probability that `D ∘ f` returns
    `true` under `μ`.

    Direct consequence of `PMF.toOuterMeasure_map_apply`: the push-
    forward outer measure on a set equals the original outer measure
    on the preimage. -/
theorem probTrue_map {α β : Type*} (μ : PMF α) (f : α → β) (D : β → Bool) :
    probTrue (μ.map f) D = probTrue μ (D ∘ f) := by
  unfold probTrue
  rw [PMF.toOuterMeasure_map_apply]
  rfl

/-- **`probTrue` of a uniform PMF as a filter-cardinality ratio.** For
    a Fintype `α` with `[DecidableEq]` and any Boolean `D : α → Bool`,
    `probTrue (uniformPMF α) D = |{x ∈ α | D x = true}| / |α|`.

    The right-hand side lives in `ℝ≥0∞` (extended non-negative reals),
    matching `probTrue`'s codomain. The proof routes through Mathlib's
    `PMF.toOuterMeasure_uniformOfFintype_apply` after rewriting
    `{x | D x = true}` to a `Finset.filter`. -/
theorem probTrue_uniformPMF_card {α : Type*} [Fintype α] [Nonempty α]
    [DecidableEq α] (D : α → Bool) :
    probTrue (uniformPMF α) D
    = ((Finset.univ.filter (fun x => D x = true)).card : ℝ≥0∞)
      / (Fintype.card α : ℝ≥0∞) := by
  classical
  unfold probTrue uniformPMF
  -- Apply the uniform-Fintype outer-measure formula.
  rw [PMF.toOuterMeasure_uniformOfFintype_apply]
  -- Translate `Fintype.card ↥{x | D x = true}` into the
  -- `Finset.filter ... |>.card` form.
  congr 1
  exact_mod_cast Fintype.card_subtype (fun x => D x = true)

-- ============================================================================
-- Workstream R-09 — uniform-tuple factorisation at a specific coordinate
-- (audit 2026-04-29 § 8.1, research-scope discharge plan § R-09 Layer 1)
-- ============================================================================

/-- **Sum-factorisation of `Fin (n+1) → α` along an inserted coordinate.**

    For any `j₀ : Fin (n+1)` and any `Finset.univ`-summed function over
    `Fin (n+1) → α`, the sum splits into a doubly-nested sum: outer
    over `α` (the value at `j₀`) and inner over `Fin n → α` (the
    "rest", indexed via `Fin.succAbove j₀`).

    This is the cardinality lemma underlying R-09's per-step bound:
    summing a Bool predicate over `Fin (n+1) → α` factors over
    `(value at j₀) × (rest)`, enabling the per-coordinate
    `ConcreteOIA` application after fixing the rest. -/
theorem sum_pi_succAbove_eq_sum_sum_insertNth {α : Type*} [Fintype α]
    {n : ℕ} {β : Type*} [AddCommMonoid β]
    (j₀ : Fin (n + 1)) (f : (Fin (n + 1) → α) → β) :
    ∑ gs : Fin (n + 1) → α, f gs =
      ∑ a : α, ∑ rest : Fin n → α, f (Fin.insertNth j₀ a rest) := by
  classical
  -- Step 1: re-index `∑ gs : Fin (n+1) → α, f gs` along the equiv
  -- `Fin.insertNthEquiv (fun _ => α) j₀ : α × (Fin n → α) ≃ Fin (n+1) → α`.
  -- This converts the LHS to `∑ p : α × (Fin n → α), f (insertNth j₀ p.1 p.2)`
  -- (since the equiv's `toFun` is `fun p => insertNth j₀ p.1 p.2`).
  rw [← Equiv.sum_comp (Fin.insertNthEquiv (fun _ : Fin (n + 1) => α) j₀) f]
  -- Step 2: the equiv's `toFun` is definitionally
  -- `fun p => Fin.insertNth j₀ p.1 p.2` (see `Fin.insertNthEquiv`'s
  -- `def` in `Mathlib.Data.Fin.Tuple.Basic`). So the goal
  -- reduces to splitting a sum over `α × (Fin n → α)` into the
  -- doubly-nested form via `Fintype.sum_prod_type`.
  exact Fintype.sum_prod_type (fun p => f (Fin.insertNth j₀ p.1 p.2))

/-- **`probTrue` of a `PMF.map` of `uniformPMF` as a filter-card ratio
    in ℝ.** Combines `probTrue_map` and `probTrue_uniformPMF_card` and
    performs the ENNReal-to-Real conversion. The denominator is
    `Fintype.card α` cast to ℝ; the numerator is the filter
    cardinality cast to ℝ.

    For our R-09 application, this lets us express the per-step
    advantage as a difference of two filter cardinalities scaled by
    `1 / |G|^Q`. -/
theorem probTrue_PMF_map_uniformPMF_toReal {α : Type*} [Fintype α] [Nonempty α]
    [DecidableEq α] {β : Type*} (F : α → β) (D : β → Bool) :
    (probTrue (PMF.map F (uniformPMF α)) D).toReal =
      ((Finset.univ.filter (fun x : α => D (F x) = true)).card : ℝ)
        / (Fintype.card α : ℝ) := by
  classical
  -- Push probTrue through PMF.map: probTrue (PMF.map F μ) D = probTrue μ (D ∘ F).
  rw [probTrue_map]
  -- Express probTrue (uniformPMF α) (D ∘ F) as filter-card ratio.
  rw [probTrue_uniformPMF_card]
  -- Convert (n / m : ℝ≥0∞).toReal = (n : ℝ) / (m : ℝ) under finiteness.
  rw [ENNReal.toReal_div]
  -- Both numerator and denominator are natural-cast ENNReals; their
  -- `.toReal` simplifies to the natural cast (and the goal is `rfl`
  -- after the simp).
  rfl

end Orbcrypt
