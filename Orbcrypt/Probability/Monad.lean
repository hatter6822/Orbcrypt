import Mathlib.Probability.ProbabilityMassFunction.Constructions
import Mathlib.Probability.Distributions.Uniform

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

end Orbcrypt
