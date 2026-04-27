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

-- ============================================================================
-- Sub-task T3.4 — Path-algebra structure-constant equivariance.
-- ============================================================================

/-- **Slot-structure-constant equivariance under the σ-lift.**

Under the GI hypothesis `∀ i j, adj₁ i j = adj₂ (σ i) (σ j)`, the
*ambient* slot structure constant is preserved by the σ-lift on all
three indices. Direct since `ambientSlotStructureConstant` is
`if i = j ∧ j = k then 1 else 0` — a graph-independent function of
the index triple — and the σ-lift is an `Equiv` so it preserves
equality of indices. -/
theorem ambientSlotStructureConstant_equivariant
    (m : ℕ) (σ : Equiv.Perm (Fin m))
    (i j k : Fin (dimGQ m)) :
    ambientSlotStructureConstant m
      (liftedSigma m σ i) (liftedSigma m σ j) (liftedSigma m σ k) =
    ambientSlotStructureConstant m i j k := by
  unfold ambientSlotStructureConstant
  -- The σ-lift is an `Equiv`, so `liftedSigma m σ i = liftedSigma m σ j`
  -- iff `i = j` (by injectivity).
  congr 1
  refine propext ⟨fun h => ?_, fun h => ?_⟩
  · obtain ⟨hij, hjk⟩ := h
    refine ⟨(liftedSigma m σ).injective hij,
            (liftedSigma m σ).injective hjk⟩
  · obtain ⟨hij, hjk⟩ := h
    exact ⟨congrArg _ hij, congrArg _ hjk⟩

/-- **`slotToArrow` commutes with the σ-lift up to `quiverMap`.**

Applying `liftedSigmaSlot σ` to a slot kind and then projecting to
a `QuiverArrow` via `slotToArrow` gives the same result as projecting
first and then applying `quiverMap σ` on the path-algebra basis. -/
theorem slotToArrow_liftedSigmaSlot (m : ℕ) (σ : Equiv.Perm (Fin m))
    (s : SlotKind m) :
    slotToArrow m (liftedSigmaSlot m σ s) =
    quiverMap m σ (slotToArrow m s) := by
  cases s with
  | vertex v => rfl
  | arrow u v => rfl

/-- **Path-structure-constant equivariance under the σ-lift.**

Under the σ-lift on all three slot indices, the path-algebra
structure constant is preserved. The proof reduces to:

1. `slotToArrow (slotEquiv (liftedSigma σ x)) = quiverMap σ (slotToArrow
   (slotEquiv x))` (via `slotToArrow_liftedSigmaSlot`).
2. `pathMul (quiverMap σ a) (quiverMap σ b) = (pathMul a b).map
   (quiverMap σ)` (the basis-element-level σ-equivariance,
   `pathMul_quiverMap`).
3. The "if d = c" decision in `pathSlotStructureConstant`'s output
   is preserved by `quiverMap σ` since `quiverMap σ` is injective.

This is the **slot-level σ-equivariance** lemma the forward
direction's encoder-equivariance proof consumes. The proof is
algebraic and does not require the GL³ matrix-action machinery. -/
theorem pathSlotStructureConstant_equivariant
    (m : ℕ) (σ : Equiv.Perm (Fin m))
    (i j k : Fin (dimGQ m)) :
    pathSlotStructureConstant m
      (liftedSigma m σ i) (liftedSigma m σ j) (liftedSigma m σ k) =
    pathSlotStructureConstant m i j k := by
  -- Set up the basis-element-level abbreviations.
  set a := slotToArrow m (slotEquiv m i) with ha_def
  set b := slotToArrow m (slotEquiv m j) with hb_def
  set c := slotToArrow m (slotEquiv m k) with hc_def
  -- Compute slotToArrow on each lifted index.
  have h_a : slotToArrow m (slotEquiv m (liftedSigma m σ i)) = quiverMap m σ a := by
    show slotToArrow m (slotEquiv m ((slotEquiv m).symm
          (liftedSigmaSlotEquiv m σ (slotEquiv m i)))) = _
    rw [Equiv.apply_symm_apply]
    exact slotToArrow_liftedSigmaSlot m σ (slotEquiv m i)
  have h_b : slotToArrow m (slotEquiv m (liftedSigma m σ j)) = quiverMap m σ b := by
    show slotToArrow m (slotEquiv m ((slotEquiv m).symm
          (liftedSigmaSlotEquiv m σ (slotEquiv m j)))) = _
    rw [Equiv.apply_symm_apply]
    exact slotToArrow_liftedSigmaSlot m σ (slotEquiv m j)
  have h_c : slotToArrow m (slotEquiv m (liftedSigma m σ k)) = quiverMap m σ c := by
    show slotToArrow m (slotEquiv m ((slotEquiv m).symm
          (liftedSigmaSlotEquiv m σ (slotEquiv m k)))) = _
    rw [Equiv.apply_symm_apply]
    exact slotToArrow_liftedSigmaSlot m σ (slotEquiv m k)
  -- Unfold pathSlotStructureConstant on both sides.
  show (match pathMul m
             (slotToArrow m (slotEquiv m (liftedSigma m σ i)))
             (slotToArrow m (slotEquiv m (liftedSigma m σ j))) with
        | some d => if d = slotToArrow m (slotEquiv m (liftedSigma m σ k))
                    then (1 : ℚ) else 0
        | none => 0) =
       (match pathMul m a b with
        | some d => if d = c then (1 : ℚ) else 0
        | none => 0)
  rw [h_a, h_b, h_c]
  -- Now LHS uses pathMul (quiverMap σ a) (quiverMap σ b) =
  -- (pathMul a b).map (quiverMap σ).
  rw [pathMul_quiverMap m σ a b]
  -- Case-split on the pathMul output.
  cases h_pm : pathMul m a b with
  | none => simp
  | some d =>
      simp only [Option.map_some]
      by_cases h_eq : d = c
      · rw [if_pos h_eq, if_pos]
        rw [h_eq]
      · rw [if_neg h_eq, if_neg]
        intro h_eq'
        exact h_eq (quiverMap_injective m σ h_eq')

-- ============================================================================
-- Sub-task T3.6 + T3.7 — Forward direction of the iff (encoder equivariance).
-- ============================================================================

/-- **Encoder equivariance under the σ-lift (T3.6 in encoder-equality form).**

Under the GI hypothesis `∀ i j, adj₁ i j = adj₂ (σ i) (σ j)`, the
encoder is equivariant under the σ-lift on all three tensor indices:

```
grochowQiaoEncode m adj₁ (i, j, k) =
grochowQiaoEncode m adj₂ (liftedSigma σ i, liftedSigma σ j, liftedSigma σ k)
```

This is the encoder-level equivariance statement of the forward
direction. The full Layer T3.6 also restates this as a GL³ matrix
action `(P_σ, P_σ, P_σ) • T_{adj₁} = T_{adj₂}` after constructing
the permutation matrix `P_σ` from `liftedSigma σ`; the
matrix-action restatement is research-scope (audit plan T3.6
~400-line budget) since it requires the GL³ `tensorContract`
unfolding.

**Why this version is sufficient for the iff direction.**
`AreTensorIsomorphic` over `Tensor3` is the existence of a GL³
triple. We can construct the GL³ triple from `liftedSigma σ` via
the permutation-matrix lift; the matrix-action computation reduces
to this encoder-equality statement. -/
theorem grochowQiaoEncode_equivariant
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (σ : Equiv.Perm (Fin m))
    (h : ∀ i j, adj₁ i j = adj₂ (σ i) (σ j))
    (i j k : Fin (dimGQ m)) :
    grochowQiaoEncode m adj₁ i j k =
    grochowQiaoEncode m adj₂
      (liftedSigma m σ i) (liftedSigma m σ j) (liftedSigma m σ k) := by
  -- Case-split on the path-algebra-vs-padding branch of the encoder.
  -- The slot-shape preservation (`isPathAlgebraSlot_liftedSigma`)
  -- ensures both sides land in the same branch.
  by_cases h_path : isPathAlgebraSlot m adj₁ i = true ∧
                    isPathAlgebraSlot m adj₁ j = true ∧
                    isPathAlgebraSlot m adj₁ k = true
  · -- All three slots are path-algebra under adj₁; by isPathAlgebraSlot_liftedSigma,
    -- their σ-lifted images are path-algebra under adj₂.
    obtain ⟨hi, hj, hk⟩ := h_path
    have hi' : isPathAlgebraSlot m adj₂ (liftedSigma m σ i) = true := by
      rw [← isPathAlgebraSlot_liftedSigma m adj₁ adj₂ σ h]; exact hi
    have hj' : isPathAlgebraSlot m adj₂ (liftedSigma m σ j) = true := by
      rw [← isPathAlgebraSlot_liftedSigma m adj₁ adj₂ σ h]; exact hj
    have hk' : isPathAlgebraSlot m adj₂ (liftedSigma m σ k) = true := by
      rw [← isPathAlgebraSlot_liftedSigma m adj₁ adj₂ σ h]; exact hk
    rw [grochowQiaoEncode_path m adj₁ i j k hi hj hk]
    rw [grochowQiaoEncode_path m adj₂ _ _ _ hi' hj' hk']
    -- Now both sides are pathSlotStructureConstant; equivariance from T3.4.
    rw [pathSlotStructureConstant_equivariant m σ i j k]
  · -- Some slot is padding under adj₁; by isPathAlgebraSlot_liftedSigma,
    -- the corresponding slot is padding under adj₂. Both encoders return
    -- the ambient constant, which is graph-independent and σ-equivariant
    -- by `ambientSlotStructureConstant_equivariant`.
    -- Case-split on each of the three booleans to find a padding slot.
    rcases h_b_i : isPathAlgebraSlot m adj₁ i with _ | _
    · -- i is padding.
      have hi'_b : isPathAlgebraSlot m adj₂ (liftedSigma m σ i) = false := by
        rw [← isPathAlgebraSlot_liftedSigma m adj₁ adj₂ σ h]; exact h_b_i
      rw [grochowQiaoEncode_padding_left m adj₁ i j k h_b_i]
      rw [grochowQiaoEncode_padding_left m adj₂ _ _ _ hi'_b]
      exact (ambientSlotStructureConstant_equivariant m σ i j k).symm
    · rcases h_b_j : isPathAlgebraSlot m adj₁ j with _ | _
      · -- j is padding (and i is path-algebra).
        have hj'_b : isPathAlgebraSlot m adj₂ (liftedSigma m σ j) = false := by
          rw [← isPathAlgebraSlot_liftedSigma m adj₁ adj₂ σ h]; exact h_b_j
        rw [grochowQiaoEncode_padding_mid m adj₁ i j k h_b_j]
        rw [grochowQiaoEncode_padding_mid m adj₂ _ _ _ hj'_b]
        exact (ambientSlotStructureConstant_equivariant m σ i j k).symm
      · rcases h_b_k : isPathAlgebraSlot m adj₁ k with _ | _
        · -- k is padding (and i, j are path-algebra).
          have hk'_b : isPathAlgebraSlot m adj₂ (liftedSigma m σ k) = false := by
            rw [← isPathAlgebraSlot_liftedSigma m adj₁ adj₂ σ h]; exact h_b_k
          rw [grochowQiaoEncode_padding_right m adj₁ i j k h_b_k]
          rw [grochowQiaoEncode_padding_right m adj₂ _ _ _ hk'_b]
          exact (ambientSlotStructureConstant_equivariant m σ i j k).symm
        · -- All three are path-algebra; contradicts h_path.
          exact absurd ⟨h_b_i, h_b_j, h_b_k⟩ h_path

/-- **Encoder equivariance restated as encoder equality (Layer T3.7
forward iff direction at the encoder-equality level).**

Under the GI hypothesis, applying `liftedSigma σ⁻¹` to all three
tensor indices of `grochowQiaoEncode m adj₂` produces
`grochowQiaoEncode m adj₁`. This is the encoder-equality form of
the GL³ tensor isomorphism `(P_σ, P_σ, P_σ) • T_{adj₁} =
T_{adj₂}`. -/
theorem grochowQiaoEncode_pull_back_under_iso
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (σ : Equiv.Perm (Fin m))
    (h : ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) :
    ∀ i j k, grochowQiaoEncode m adj₁ i j k =
             grochowQiaoEncode m adj₂
               (liftedSigma m σ i)
               (liftedSigma m σ j)
               (liftedSigma m σ k) :=
  grochowQiaoEncode_equivariant m adj₁ adj₂ σ h

end GrochowQiao
end Orbcrypt
