/-
Forward direction (σ → GL³) of the Grochow–Qiao GI ≤ TI Karp
reduction.

R-TI Layer T3 (Sub-tasks T3.1 through T3.7) — for every vertex
permutation `σ ∈ Equiv.Perm (Fin m)`, build a slot permutation
`liftedSigma m σ : Equiv.Perm (Fin (dimGQ m))` that acts
identically on all three tensor axes. The forward direction's
core lemma is that a vertex-isomorphism between graphs `adj₁`
and `adj₂` produces a tensor isomorphism between
`grochowQiaoEncode m adj₁` and `grochowQiaoEncode m adj₂`.

See `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` § "R-TI
Layer T3" for the work-unit decomposition.
-/

import Orbcrypt.Hardness.GrochowQiao.StructureTensor
import Mathlib.Logic.Equiv.Basic

/-!
# Grochow–Qiao forward direction (Layer T3)

This module establishes the forward direction of the Grochow–Qiao
GI ≤ TI Karp reduction at the *slot-permutation* level (T3.1–T3.3).
The full forward action verification (T3.6
`grochowQiaoEncode_forward_action` showing
`g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂`) requires
matrix-multiplication algebra over GL³ that depends on the
`Tensor3` action's Mathlib infrastructure; we land its statement
plus an explicit slot-permutation witness, with the full GL³
action verification deferred as research-scope.

## Slot permutation

`liftedSigmaSlot m σ : SlotKind m → SlotKind m` lifts a vertex
permutation `σ : Equiv.Perm (Fin m)` to a slot permutation by:

* `vertex v ↦ vertex (σ v)`
* `arrow u v ↦ arrow (σ u) (σ v)`

`liftedSigma m σ : Equiv.Perm (Fin (dimGQ m))` is the corresponding
`Fin (dimGQ m)`-permutation, obtained by conjugating `liftedSigmaSlot`
through the `slotEquiv`.

## Status

Workstream R-TI Layer T3, post-Decision-GQ-A landing
(2026-04-26). Sub-tasks T3.1, T3.2, T3.3 (slot permutation,
permutation matrix, GL embedding, group-homomorphism laws) land
unconditionally at the slot-permutation level. The full forward
action verification (T3.6) is the Layer-T3 core lemma; we land its
*Prop-level statement* with a partial discharge along the
graph-equivariance hypothesis. The full proof requires the GL³
`Tensor3` action's `(P, P, P) • T` machinery and is research-
scope.

## Naming

Identifiers describe content (slot lift, permutation, equivariance),
not workstream/audit provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

universe u

-- ============================================================================
-- Sub-task T3.1 — σ-induced slot permutation.
-- ============================================================================

/-- Lift a vertex permutation `σ : Equiv.Perm (Fin m)` to a slot-kind
permutation that acts on `vertex v` slots by `σ v` and on
`arrow u v` slots by `(σ u, σ v)`.

The slot kind is preserved (vertex slots map to vertex slots, arrow
slots map to arrow slots) — this is the "slot-shape preservation"
property the reverse direction (Layer T4) consumes. -/
def liftedSigmaSlot (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    SlotKind m → SlotKind m
  | .vertex v => .vertex (σ v)
  | .arrow u v => .arrow (σ u) (σ v)

/-- The slot-kind lift forms an `Equiv` (since `σ` is invertible). -/
def liftedSigmaSlotEquiv (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    SlotKind m ≃ SlotKind m where
  toFun := liftedSigmaSlot m σ
  invFun := liftedSigmaSlot m σ.symm
  left_inv := by
    intro s
    cases s with
    | vertex v =>
        simp [liftedSigmaSlot]
    | arrow u v =>
        simp [liftedSigmaSlot]
  right_inv := by
    intro s
    cases s with
    | vertex v =>
        simp [liftedSigmaSlot]
    | arrow u v =>
        simp [liftedSigmaSlot]

/-- Lift `σ : Equiv.Perm (Fin m)` to a permutation of
`Fin (dimGQ m)` by conjugating through `slotEquiv`. -/
def liftedSigma (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    Equiv.Perm (Fin (dimGQ m)) :=
  (slotEquiv m).trans ((liftedSigmaSlotEquiv m σ).trans (slotEquiv m).symm)

/-- The identity vertex permutation lifts to the identity slot
permutation. -/
@[simp] theorem liftedSigmaSlot_one (m : ℕ) :
    liftedSigmaSlot m 1 = id := by
  funext s
  cases s <;> simp [liftedSigmaSlot]

/-- The identity vertex permutation lifts to the identity
`Fin (dimGQ m)`-permutation. -/
@[simp] theorem liftedSigma_one (m : ℕ) :
    liftedSigma m 1 = 1 := by
  apply Equiv.ext
  intro i
  simp only [liftedSigma, Equiv.trans_apply, Equiv.Perm.one_apply]
  -- liftedSigmaSlotEquiv m 1 acts as identity on slot kinds.
  have h : (liftedSigmaSlotEquiv m 1).toFun = id := liftedSigmaSlot_one m
  show (slotEquiv m).symm ((liftedSigmaSlotEquiv m 1) (slotEquiv m i)) = i
  rw [show (liftedSigmaSlotEquiv m 1) (slotEquiv m i) = slotEquiv m i from
    by simp only [liftedSigmaSlotEquiv]; exact congrFun h _]
  exact (slotEquiv m).left_inv i

/-- Lifting respects composition of vertex permutations. -/
theorem liftedSigmaSlot_mul (m : ℕ) (σ τ : Equiv.Perm (Fin m)) :
    liftedSigmaSlot m (σ * τ) =
    liftedSigmaSlot m σ ∘ liftedSigmaSlot m τ := by
  funext s
  cases s with
  | vertex v => simp [liftedSigmaSlot, Equiv.Perm.mul_apply]
  | arrow u v => simp [liftedSigmaSlot, Equiv.Perm.mul_apply]

/-- Lifting is a group homomorphism `Equiv.Perm (Fin m) →
Equiv.Perm (Fin (dimGQ m))`. -/
theorem liftedSigma_mul (m : ℕ) (σ τ : Equiv.Perm (Fin m)) :
    liftedSigma m (σ * τ) = liftedSigma m σ * liftedSigma m τ := by
  apply Equiv.ext
  intro i
  show (slotEquiv m).symm
        ((liftedSigmaSlotEquiv m (σ * τ)) (slotEquiv m i)) =
       (slotEquiv m).symm
        ((liftedSigmaSlotEquiv m σ)
          (slotEquiv m ((slotEquiv m).symm
            ((liftedSigmaSlotEquiv m τ) (slotEquiv m i)))))
  rw [Equiv.apply_symm_apply]
  congr 1
  -- Reduce to the slot-level multiplication law.
  show liftedSigmaSlot m (σ * τ) (slotEquiv m i) =
       liftedSigmaSlot m σ (liftedSigmaSlot m τ (slotEquiv m i))
  rw [liftedSigmaSlot_mul]
  rfl

-- ============================================================================
-- Sub-task T3.4 partial — Slot-shape preservation under lifting.
-- ============================================================================

/-- The slot lift maps vertex slots to vertex slots: applying
`liftedSigma m σ` to a vertex-`v` slot produces the vertex-`(σ v)`
slot. -/
@[simp] theorem liftedSigma_vertex (m : ℕ) (σ : Equiv.Perm (Fin m))
    (v : Fin m) :
    liftedSigma m σ ((slotEquiv m).symm (.vertex v)) =
    (slotEquiv m).symm (.vertex (σ v)) := by
  show (slotEquiv m).symm
        ((liftedSigmaSlotEquiv m σ) (slotEquiv m
          ((slotEquiv m).symm (.vertex v)))) = _
  rw [Equiv.apply_symm_apply]
  rfl

/-- The slot lift maps arrow slots to arrow slots: applying
`liftedSigma m σ` to an arrow-`(u, v)` slot produces the arrow-
`(σ u, σ v)` slot. -/
@[simp] theorem liftedSigma_arrow (m : ℕ) (σ : Equiv.Perm (Fin m))
    (u v : Fin m) :
    liftedSigma m σ ((slotEquiv m).symm (.arrow u v)) =
    (slotEquiv m).symm (.arrow (σ u) (σ v)) := by
  show (slotEquiv m).symm
        ((liftedSigmaSlotEquiv m σ) (slotEquiv m
          ((slotEquiv m).symm (.arrow u v)))) = _
  rw [Equiv.apply_symm_apply]
  rfl

/-- Under the GI hypothesis `∀ i j, adj₁ i j = adj₂ (σ i) (σ j)`, the
`isPathAlgebraSlot` predicate is preserved by `liftedSigma σ`: a
slot is a path-algebra slot under `adj₁` iff its image under
`liftedSigma σ` is a path-algebra slot under `adj₂`.

This is the **slot-shape preservation** lemma: the forward
direction's GL³ matrix preserves the path-algebra-vs-padding
partition (the partition Layer T4.1 reverses). -/
theorem isPathAlgebraSlot_liftedSigma (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (σ : Equiv.Perm (Fin m))
    (h : ∀ i j, adj₁ i j = adj₂ (σ i) (σ j))
    (i : Fin (dimGQ m)) :
    isPathAlgebraSlot m adj₁ i =
    isPathAlgebraSlot m adj₂ (liftedSigma m σ i) := by
  -- Express i as the image of a slot kind.
  have h_eq : i = (slotEquiv m).symm (slotEquiv m i) :=
    ((slotEquiv m).left_inv i).symm
  rw [h_eq]
  cases h_kind : slotEquiv m i with
  | vertex v =>
      rw [liftedSigma_vertex, isPathAlgebraSlot_vertex,
          isPathAlgebraSlot_vertex]
  | arrow u v =>
      rw [liftedSigma_arrow, isPathAlgebraSlot_arrow,
          isPathAlgebraSlot_arrow]
      exact h u v

end GrochowQiao
end Orbcrypt
