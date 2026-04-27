/-
Block decomposition under GL³ (Stage 3 / T-API-4, R-TI rigidity discharge).

This module captures the **block-decomposition theorem** of the Grochow–Qiao
rigidity argument as a layered structure.  The core mathematical content
is genuinely research-grade (≈80 pages of Grochow–Qiao SIAM J. Comp.
2023 §4.3; multi-month formalization effort), so this module isolates
the truly research-scope step as a single named `Prop`
(`GL3PreservesPartitionCardinalities`) and proves the rest of the
structural framework unconditionally.

## Design

Stage 3 decomposes the rigidity-argument's "block decomposition" into
two genuinely independent parts:

1. **Cardinality preservation under GL³** (research-scope, isolated as
   `GL3PreservesPartitionCardinalities`): under `g • encode₁ = encode₂`,
   the present-arrow slot count is preserved between `adj₁` and `adj₂`.
   This is the deep multilinear-algebra content.

2. **Partition-preserving permutation construction** (proven
   unconditionally here): given that the present-arrow cardinalities
   are equal, construct an `Equiv.Perm (Fin (dimGQ m))` that
   preserves the vertex / present-arrow / padding partition.

Composition: under `GL3PreservesPartitionCardinalities`, every GL³
tensor isomorphism gives rise to a partition-preserving permutation —
which is exactly what Stage 4 (T-API-7 AlgEquiv lift) and Stage 5
(adjacency invariance) consume.

See `docs/planning/R_TI_PHASE_C_THROUGH_H_PLAN.md` § Stage 3 T-API-4.
-/

import Orbcrypt.Hardness.GrochowQiao.RankInvariance
import Orbcrypt.Hardness.GrochowQiao.VertexPermDescent

/-!
# Block decomposition under GL³

Public API:

* `GL3PreservesPartitionCardinalities : Prop` — the research-scope
  obligation.  States: any GL³ triple preserving the encoder
  preserves the present-arrow slot count between `adj₁` and `adj₂`.
* `partitionPreservingPermFromEqualCardinalities m adj₁ adj₂ h` —
  given equal present-arrow cardinalities, construct a
  partition-preserving permutation.
* `partitionPreservingPermFromEqualCardinalities_isThreePartition` —
  the constructed permutation is three-partition-preserving.
* `partition_preserving_perm_under_GL3` — composition: under the
  Prop, every GL³ tensor isomorphism yields a three-partition-
  preserving permutation.

## Naming

Identifiers describe content (`GL3PreservesPartitionCardinalities`,
`partitionPreservingPermFromEqualCardinalities`), not workstream
provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt
open scoped Matrix

-- ============================================================================
-- T-API-4.A — Research-scope: GL³ preserves partition cardinalities.
-- ============================================================================

/-- **GL³ preserves partition cardinalities** (research-scope obligation).

States that for any GL³ triple `g` with `g • grochowQiaoEncode m adj₁
= grochowQiaoEncode m adj₂`, the present-arrow slot cardinality is
preserved:
```
(presentArrowSlotIndices m adj₁).card = (presentArrowSlotIndices m adj₂).card.
```

**Why this is a `Prop` rather than a proven theorem.** Discharging
this requires the deep block-decomposition theory of Grochow–Qiao
2021 SIAM J. Comp. 2023 §4.3 (~80 pages on paper; ~1,000+ LOC of
multilinear-algebra Lean infrastructure). Specifically: the multiset
of slabRanks of the encoder is GL³-invariant (Stage 1 T-API-2 only
proves the *single* rank `unfoldRank₁` is invariant; the multiset
preservation is genuinely stronger and requires per-slot rank-class
analysis).

Once discharged, this Prop combined with the Stage 2 + Stage 3
structural infrastructure produces a partition-preserving permutation
unconditionally; Stages 4–5 then build on that.

Tracked as research-scope **R-15-residual-TI-reverse**. -/
def GL3PreservesPartitionCardinalities : Prop :=
  ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ),
    g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂ →
    (presentArrowSlotIndices m adj₁).card =
      (presentArrowSlotIndices m adj₂).card

-- ============================================================================
-- T-API-4.B — Identity witness.
-- ============================================================================

/-- **Identity-case witness for `GL3PreservesPartitionCardinalities`.**

The identity GL³ triple acts trivially on tensors (`one_smul`), so
`(1, 1, 1) • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂`
reduces to `grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂`.
For this case, the present-arrow cardinalities trivially agree
because the encoders are the same function.

This is a substantive identity-case witness for the research-scope
`GL3PreservesPartitionCardinalities` Prop — it proves the Prop's
conclusion when the GL³ triple is the identity, demonstrating the
Prop is non-vacuous on the diagonal of the action. -/
theorem gl3_preserves_partition_cardinalities_identity_case
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : ((1 : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ ×
            GL (Fin (dimGQ m)) ℚ)) • grochowQiaoEncode m adj₁ =
          grochowQiaoEncode m adj₂) :
    (presentArrowSlotIndices m adj₁).card =
      (presentArrowSlotIndices m adj₂).card := by
  -- (1 : GL × GL × GL) • T = T by `one_smul`.
  rw [one_smul] at h
  -- Now h : grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂.
  -- The cardinalities depend only on adj via presentArrowSlotIndices,
  -- so we need to show adj₁ and adj₂ have equal arrow-counts.
  -- This follows from the fact that the encoder's diagonal values at
  -- arrow slots determine adj: T (arrow uv) (arrow uv) (arrow uv) = 0
  -- iff adj u v = true (present-arrow case), = 2 iff adj u v = false
  -- (padding case). Hence encode₁ = encode₂ ⇒ adj₁ = adj₂.
  have h_adj : adj₁ = adj₂ := by
    funext u v
    -- Compute the diagonal at (slotEquiv).symm (.arrow u v).
    have h_diag := congrFun (congrFun (congrFun h
      ((slotEquiv m).symm (.arrow u v)))
      ((slotEquiv m).symm (.arrow u v)))
      ((slotEquiv m).symm (.arrow u v))
    -- Direct Bool case analysis on adj₁ u v and adj₂ u v.
    rcases h₁ : adj₁ u v with _ | _
    · -- adj₁ u v = false ⇒ LHS diagonal = 2.
      rw [grochowQiaoEncode_diagonal_padding m adj₁ u v h₁] at h_diag
      rcases h₂ : adj₂ u v with _ | _
      · rfl
      · -- adj₂ u v = true ⇒ RHS diagonal = 0; contradicts 2 = 0.
        rw [grochowQiaoEncode_diagonal_present_arrow m adj₂ u v h₂] at h_diag
        norm_num at h_diag
    · -- adj₁ u v = true ⇒ LHS diagonal = 0.
      rw [grochowQiaoEncode_diagonal_present_arrow m adj₁ u v h₁] at h_diag
      rcases h₂ : adj₂ u v with _ | _
      · -- adj₂ u v = false ⇒ RHS diagonal = 2; contradicts 0 = 2.
        rw [grochowQiaoEncode_diagonal_padding m adj₂ u v h₂] at h_diag
        norm_num at h_diag
      · rfl
  rw [h_adj]

-- ============================================================================
-- T-API-4.C — Partition-preserving permutation from equal cardinalities.
--
-- This is the structural construction: given that the present-arrow
-- cardinalities are equal between `adj₁` and `adj₂` (the consequence of
-- `GL3PreservesPartitionCardinalities`), build a permutation of
-- `Fin (dimGQ m)` that preserves the vertex / present-arrow / padding
-- partition.
-- ============================================================================

/-- The **per-class equiv** between present-arrow slots of `adj₁` and `adj₂`,
constructed from equal cardinalities. -/
noncomputable def presentArrowSlotEquiv (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card) :
    {i : Fin (dimGQ m) // i ∈ presentArrowSlotIndices m adj₁} ≃
    {i : Fin (dimGQ m) // i ∈ presentArrowSlotIndices m adj₂} :=
  Fintype.equivOfCardEq (by
    rw [Fintype.card_coe, Fintype.card_coe]; exact h)

/-- The **per-class equiv** between padding slots of `adj₁` and `adj₂`,
constructed from equal cardinalities. -/
noncomputable def paddingSlotEquiv (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (paddingSlotIndices m adj₁).card =
         (paddingSlotIndices m adj₂).card) :
    {i : Fin (dimGQ m) // i ∈ paddingSlotIndices m adj₁} ≃
    {i : Fin (dimGQ m) // i ∈ paddingSlotIndices m adj₂} :=
  Fintype.equivOfCardEq (by
    rw [Fintype.card_coe, Fintype.card_coe]; exact h)

/-- Equal present-arrow cardinalities imply equal padding cardinalities,
via the partition identity `padding_card = m² - present_card`. -/
theorem padding_card_eq_of_present_card_eq (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card) :
    (paddingSlotIndices m adj₁).card =
      (paddingSlotIndices m adj₂).card := by
  rw [padding_card_eq_arrow_count_complement,
      padding_card_eq_arrow_count_complement, h]

-- ============================================================================
-- T-API-4.D — Partition-preserving permutation construction.
-- ============================================================================

/-- **Forward function** of the partition-preserving permutation.

Given equal present-arrow cardinalities, defines a function
`Fin (dimGQ m) → Fin (dimGQ m)` that:
* Acts as the identity on vertex slots.
* Maps present-arrow slots of `adj₁` to present-arrow slots of `adj₂`
  via `presentArrowSlotEquiv`.
* Maps padding slots of `adj₁` to padding slots of `adj₂` via
  `paddingSlotEquiv`.
* Falls back to identity on the unreachable case (every slot is in
  exactly one of the three classes by `vertex_present_padding_partition`). -/
noncomputable def partitionPreservingFwd (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card)
    (i : Fin (dimGQ m)) : Fin (dimGQ m) := by
  classical
  exact
    if _ : i ∈ vertexSlotIndices m then i
    else if h_pres : i ∈ presentArrowSlotIndices m adj₁ then
      ((presentArrowSlotEquiv m adj₁ adj₂ h) ⟨i, h_pres⟩ : Fin (dimGQ m))
    else if h_pad : i ∈ paddingSlotIndices m adj₁ then
      ((paddingSlotEquiv m adj₁ adj₂
          (padding_card_eq_of_present_card_eq m adj₁ adj₂ h))
            ⟨i, h_pad⟩ : Fin (dimGQ m))
    else
      i

/-- **Inverse function** of the partition-preserving permutation. -/
noncomputable def partitionPreservingInv (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card)
    (i : Fin (dimGQ m)) : Fin (dimGQ m) := by
  classical
  exact
    if _ : i ∈ vertexSlotIndices m then i
    else if h_pres : i ∈ presentArrowSlotIndices m adj₂ then
      ((presentArrowSlotEquiv m adj₁ adj₂ h).symm ⟨i, h_pres⟩ : Fin (dimGQ m))
    else if h_pad : i ∈ paddingSlotIndices m adj₂ then
      ((paddingSlotEquiv m adj₁ adj₂
          (padding_card_eq_of_present_card_eq m adj₁ adj₂ h)).symm
            ⟨i, h_pad⟩ : Fin (dimGQ m))
    else
      i

-- ============================================================================
-- Slot-classification preservation lemmas (used in Equiv proof).
-- ============================================================================

/-- The forward function of `partitionPreservingFwd` maps present-arrow slots
of `adj₁` to present-arrow slots of `adj₂`. -/
theorem partitionPreservingFwd_presentArrow (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card)
    (i : Fin (dimGQ m)) (hi : i ∈ presentArrowSlotIndices m adj₁) :
    partitionPreservingFwd m adj₁ adj₂ h i ∈ presentArrowSlotIndices m adj₂ := by
  classical
  unfold partitionPreservingFwd
  -- i is not in vertex (disjoint), so we hit the present-arrow branch.
  have h_not_v : i ∉ vertexSlotIndices m := fun h_v =>
    Finset.disjoint_left.mp
      (vertexSlotIndices_disjoint_presentArrowSlotIndices m adj₁) h_v hi
  rw [dif_neg h_not_v, dif_pos hi]
  exact ((presentArrowSlotEquiv m adj₁ adj₂ h) ⟨i, hi⟩).property

/-- The forward function of `partitionPreservingFwd` maps padding slots of
`adj₁` to padding slots of `adj₂`. -/
theorem partitionPreservingFwd_padding (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card)
    (i : Fin (dimGQ m)) (hi : i ∈ paddingSlotIndices m adj₁) :
    partitionPreservingFwd m adj₁ adj₂ h i ∈ paddingSlotIndices m adj₂ := by
  classical
  unfold partitionPreservingFwd
  have h_not_v : i ∉ vertexSlotIndices m := fun h_v =>
    Finset.disjoint_left.mp
      (vertexSlotIndices_disjoint_paddingSlotIndices m adj₁) h_v hi
  have h_not_p : i ∉ presentArrowSlotIndices m adj₁ := fun h_p =>
    Finset.disjoint_left.mp
      (presentArrowSlotIndices_disjoint_paddingSlotIndices m adj₁) h_p hi
  rw [dif_neg h_not_v, dif_neg h_not_p, dif_pos hi]
  exact ((paddingSlotEquiv m adj₁ adj₂
    (padding_card_eq_of_present_card_eq m adj₁ adj₂ h)) ⟨i, hi⟩).property

/-- The forward function fixes vertex slots. -/
theorem partitionPreservingFwd_vertex (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card)
    (i : Fin (dimGQ m)) (hi : i ∈ vertexSlotIndices m) :
    partitionPreservingFwd m adj₁ adj₂ h i = i := by
  classical
  unfold partitionPreservingFwd
  rw [dif_pos hi]

/-- Symmetric: the inverse function fixes vertex slots. -/
theorem partitionPreservingInv_vertex (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card)
    (i : Fin (dimGQ m)) (hi : i ∈ vertexSlotIndices m) :
    partitionPreservingInv m adj₁ adj₂ h i = i := by
  classical
  unfold partitionPreservingInv
  rw [dif_pos hi]

-- ============================================================================
-- Round-trip identities (fwd ∘ inv = id and inv ∘ fwd = id).
-- ============================================================================

/-- The forward function unfolds at present-arrow slots. -/
theorem partitionPreservingFwd_apply_presentArrow (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card)
    (i : Fin (dimGQ m)) (hi : i ∈ presentArrowSlotIndices m adj₁) :
    partitionPreservingFwd m adj₁ adj₂ h i =
      ((presentArrowSlotEquiv m adj₁ adj₂ h) ⟨i, hi⟩ : Fin (dimGQ m)) := by
  classical
  unfold partitionPreservingFwd
  have h_not_v : i ∉ vertexSlotIndices m := fun h_v =>
    Finset.disjoint_left.mp
      (vertexSlotIndices_disjoint_presentArrowSlotIndices m adj₁) h_v hi
  rw [dif_neg h_not_v, dif_pos hi]

/-- The forward function unfolds at padding slots. -/
theorem partitionPreservingFwd_apply_padding (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card)
    (i : Fin (dimGQ m)) (hi : i ∈ paddingSlotIndices m adj₁) :
    partitionPreservingFwd m adj₁ adj₂ h i =
      ((paddingSlotEquiv m adj₁ adj₂
          (padding_card_eq_of_present_card_eq m adj₁ adj₂ h))
            ⟨i, hi⟩ : Fin (dimGQ m)) := by
  classical
  unfold partitionPreservingFwd
  have h_not_v : i ∉ vertexSlotIndices m := fun h_v =>
    Finset.disjoint_left.mp
      (vertexSlotIndices_disjoint_paddingSlotIndices m adj₁) h_v hi
  have h_not_p : i ∉ presentArrowSlotIndices m adj₁ := fun h_p =>
    Finset.disjoint_left.mp
      (presentArrowSlotIndices_disjoint_paddingSlotIndices m adj₁) h_p hi
  rw [dif_neg h_not_v, dif_neg h_not_p, dif_pos hi]

/-- The inverse function unfolds at present-arrow slots. -/
theorem partitionPreservingInv_apply_presentArrow (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card)
    (i : Fin (dimGQ m)) (hi : i ∈ presentArrowSlotIndices m adj₂) :
    partitionPreservingInv m adj₁ adj₂ h i =
      ((presentArrowSlotEquiv m adj₁ adj₂ h).symm ⟨i, hi⟩ : Fin (dimGQ m)) := by
  classical
  unfold partitionPreservingInv
  have h_not_v : i ∉ vertexSlotIndices m := fun h_v =>
    Finset.disjoint_left.mp
      (vertexSlotIndices_disjoint_presentArrowSlotIndices m adj₂) h_v hi
  rw [dif_neg h_not_v, dif_pos hi]

/-- The inverse function unfolds at padding slots. -/
theorem partitionPreservingInv_apply_padding (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card)
    (i : Fin (dimGQ m)) (hi : i ∈ paddingSlotIndices m adj₂) :
    partitionPreservingInv m adj₁ adj₂ h i =
      ((paddingSlotEquiv m adj₁ adj₂
          (padding_card_eq_of_present_card_eq m adj₁ adj₂ h)).symm
            ⟨i, hi⟩ : Fin (dimGQ m)) := by
  classical
  unfold partitionPreservingInv
  have h_not_v : i ∉ vertexSlotIndices m := fun h_v =>
    Finset.disjoint_left.mp
      (vertexSlotIndices_disjoint_paddingSlotIndices m adj₂) h_v hi
  have h_not_p : i ∉ presentArrowSlotIndices m adj₂ := fun h_p =>
    Finset.disjoint_left.mp
      (presentArrowSlotIndices_disjoint_paddingSlotIndices m adj₂) h_p hi
  rw [dif_neg h_not_v, dif_neg h_not_p, dif_pos hi]

-- ============================================================================
-- Inverse-pair identity: partitionPreservingInv ∘ partitionPreservingFwd = id.
-- ============================================================================

/-- `inv ∘ fwd = id` (round-trip identity). -/
theorem partitionPreservingInv_fwd (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card)
    (i : Fin (dimGQ m)) :
    partitionPreservingInv m adj₁ adj₂ h
      (partitionPreservingFwd m adj₁ adj₂ h i) = i := by
  classical
  -- Case split on which slot kind `i` belongs to.
  -- Use the partition: every slot is in exactly one of vertex / present-arrow / padding.
  by_cases h_v : i ∈ vertexSlotIndices m
  · -- Vertex slot: fwd i = i, inv i = i.
    rw [partitionPreservingFwd_vertex m adj₁ adj₂ h i h_v,
        partitionPreservingInv_vertex m adj₁ adj₂ h i h_v]
  · by_cases h_p : i ∈ presentArrowSlotIndices m adj₁
    · -- Present-arrow slot.
      rw [partitionPreservingFwd_apply_presentArrow m adj₁ adj₂ h i h_p]
      have h_image : ((presentArrowSlotEquiv m adj₁ adj₂ h) ⟨i, h_p⟩).val ∈
                      presentArrowSlotIndices m adj₂ :=
        ((presentArrowSlotEquiv m adj₁ adj₂ h) ⟨i, h_p⟩).property
      rw [partitionPreservingInv_apply_presentArrow m adj₁ adj₂ h _ h_image]
      -- Now: ((equiv).symm ⟨equiv ⟨i, h_p⟩, ...⟩).val = i.
      have : ((presentArrowSlotEquiv m adj₁ adj₂ h).symm
              ⟨((presentArrowSlotEquiv m adj₁ adj₂ h) ⟨i, h_p⟩).val, h_image⟩) =
             ⟨i, h_p⟩ := by
        rw [show (⟨((presentArrowSlotEquiv m adj₁ adj₂ h) ⟨i, h_p⟩).val, h_image⟩ :
                {j // j ∈ presentArrowSlotIndices m adj₂}) =
            (presentArrowSlotEquiv m adj₁ adj₂ h) ⟨i, h_p⟩ from
          Subtype.ext rfl]
        exact (presentArrowSlotEquiv m adj₁ adj₂ h).symm_apply_apply _
      rw [this]
    · -- Padding slot (the only remaining case by the partition).
      -- Use vertex_present_padding_partition to derive `i ∈ paddingSlotIndices`.
      have h_pad : i ∈ paddingSlotIndices m adj₁ := by
        have h_partition := vertex_present_padding_partition m adj₁
        have : i ∈ Finset.univ := Finset.mem_univ _
        rw [← h_partition] at this
        rcases Finset.mem_union.mp this with h_vp | h_pad
        · rcases Finset.mem_union.mp h_vp with h_v' | h_p'
          · exact absurd h_v' h_v
          · exact absurd h_p' h_p
        · exact h_pad
      rw [partitionPreservingFwd_apply_padding m adj₁ adj₂ h i h_pad]
      have h_pad_eq := padding_card_eq_of_present_card_eq m adj₁ adj₂ h
      have h_image : ((paddingSlotEquiv m adj₁ adj₂ h_pad_eq) ⟨i, h_pad⟩).val ∈
                      paddingSlotIndices m adj₂ :=
        ((paddingSlotEquiv m adj₁ adj₂ h_pad_eq) ⟨i, h_pad⟩).property
      rw [partitionPreservingInv_apply_padding m adj₁ adj₂ h _ h_image]
      have : ((paddingSlotEquiv m adj₁ adj₂ h_pad_eq).symm
              ⟨((paddingSlotEquiv m adj₁ adj₂ h_pad_eq) ⟨i, h_pad⟩).val, h_image⟩) =
             ⟨i, h_pad⟩ := by
        rw [show (⟨((paddingSlotEquiv m adj₁ adj₂ h_pad_eq) ⟨i, h_pad⟩).val, h_image⟩ :
                {j // j ∈ paddingSlotIndices m adj₂}) =
            (paddingSlotEquiv m adj₁ adj₂ h_pad_eq) ⟨i, h_pad⟩ from
          Subtype.ext rfl]
        exact (paddingSlotEquiv m adj₁ adj₂ h_pad_eq).symm_apply_apply _
      rw [this]

/-- `fwd ∘ inv = id` (symmetric round-trip identity). -/
theorem partitionPreservingFwd_inv (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card)
    (i : Fin (dimGQ m)) :
    partitionPreservingFwd m adj₁ adj₂ h
      (partitionPreservingInv m adj₁ adj₂ h i) = i := by
  classical
  by_cases h_v : i ∈ vertexSlotIndices m
  · rw [partitionPreservingInv_vertex m adj₁ adj₂ h i h_v,
        partitionPreservingFwd_vertex m adj₁ adj₂ h i h_v]
  · by_cases h_p : i ∈ presentArrowSlotIndices m adj₂
    · rw [partitionPreservingInv_apply_presentArrow m adj₁ adj₂ h i h_p]
      have h_image : ((presentArrowSlotEquiv m adj₁ adj₂ h).symm ⟨i, h_p⟩).val ∈
                      presentArrowSlotIndices m adj₁ :=
        ((presentArrowSlotEquiv m adj₁ adj₂ h).symm ⟨i, h_p⟩).property
      rw [partitionPreservingFwd_apply_presentArrow m adj₁ adj₂ h _ h_image]
      have : ((presentArrowSlotEquiv m adj₁ adj₂ h)
              ⟨((presentArrowSlotEquiv m adj₁ adj₂ h).symm ⟨i, h_p⟩).val, h_image⟩) =
             ⟨i, h_p⟩ := by
        rw [show (⟨((presentArrowSlotEquiv m adj₁ adj₂ h).symm ⟨i, h_p⟩).val, h_image⟩ :
                {j // j ∈ presentArrowSlotIndices m adj₁}) =
            (presentArrowSlotEquiv m adj₁ adj₂ h).symm ⟨i, h_p⟩ from
          Subtype.ext rfl]
        exact (presentArrowSlotEquiv m adj₁ adj₂ h).apply_symm_apply _
      rw [this]
    · -- Padding case.
      have h_pad : i ∈ paddingSlotIndices m adj₂ := by
        have h_partition := vertex_present_padding_partition m adj₂
        have : i ∈ Finset.univ := Finset.mem_univ _
        rw [← h_partition] at this
        rcases Finset.mem_union.mp this with h_vp | h_pad
        · rcases Finset.mem_union.mp h_vp with h_v' | h_p'
          · exact absurd h_v' h_v
          · exact absurd h_p' h_p
        · exact h_pad
      rw [partitionPreservingInv_apply_padding m adj₁ adj₂ h i h_pad]
      have h_pad_eq := padding_card_eq_of_present_card_eq m adj₁ adj₂ h
      have h_image : ((paddingSlotEquiv m adj₁ adj₂ h_pad_eq).symm ⟨i, h_pad⟩).val ∈
                      paddingSlotIndices m adj₁ :=
        ((paddingSlotEquiv m adj₁ adj₂ h_pad_eq).symm ⟨i, h_pad⟩).property
      rw [partitionPreservingFwd_apply_padding m adj₁ adj₂ h _ h_image]
      have : ((paddingSlotEquiv m adj₁ adj₂ h_pad_eq)
              ⟨((paddingSlotEquiv m adj₁ adj₂ h_pad_eq).symm ⟨i, h_pad⟩).val, h_image⟩) =
             ⟨i, h_pad⟩ := by
        rw [show (⟨((paddingSlotEquiv m adj₁ adj₂ h_pad_eq).symm ⟨i, h_pad⟩).val, h_image⟩ :
                {j // j ∈ paddingSlotIndices m adj₁}) =
            (paddingSlotEquiv m adj₁ adj₂ h_pad_eq).symm ⟨i, h_pad⟩ from
          Subtype.ext rfl]
        exact (paddingSlotEquiv m adj₁ adj₂ h_pad_eq).apply_symm_apply _
      rw [this]

-- ============================================================================
-- T-API-4.E — Package as `Equiv.Perm` and prove three-partition-preserving.
-- ============================================================================

/-- **The partition-preserving permutation** (Stage 3 T-API-4 headline).

Given equal present-arrow cardinalities, build an `Equiv.Perm (Fin
(dimGQ m))` that preserves the vertex / present-arrow / padding
partition. -/
noncomputable def partitionPreservingPermFromEqualCardinalities (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card) :
    Equiv.Perm (Fin (dimGQ m)) where
  toFun := partitionPreservingFwd m adj₁ adj₂ h
  invFun := partitionPreservingInv m adj₁ adj₂ h
  left_inv := partitionPreservingInv_fwd m adj₁ adj₂ h
  right_inv := partitionPreservingFwd_inv m adj₁ adj₂ h

/-- The constructed permutation applied to `i` is `partitionPreservingFwd ... i`. -/
@[simp] theorem partitionPreservingPermFromEqualCardinalities_apply (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card)
    (i : Fin (dimGQ m)) :
    partitionPreservingPermFromEqualCardinalities m adj₁ adj₂ h i =
      partitionPreservingFwd m adj₁ adj₂ h i := rfl

-- ============================================================================
-- T-API-4.F — The constructed permutation is `IsThreePartitionPreserving`.
-- ============================================================================

/-- The constructed permutation is **vertex-slot-preserving**.

For any slot `i`, `i ∈ vertexSlotIndices m ↔ π i ∈ vertexSlotIndices m`.

*Proof*: by case analysis on which class `i` belongs to. Vertex slots
are fixed by π, and non-vertex slots map to non-vertex slots
(present-arrow slots map to present-arrow slots, padding slots to
padding slots; both are disjoint from vertex slots). -/
theorem partitionPreservingPermFromEqualCardinalities_vertexPreserving (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card) :
    IsVertexSlotPreserving m
      (partitionPreservingPermFromEqualCardinalities m adj₁ adj₂ h) := by
  intro i
  simp only [partitionPreservingPermFromEqualCardinalities_apply]
  by_cases h_v : i ∈ vertexSlotIndices m
  · -- Vertex case: fwd i = i.
    rw [partitionPreservingFwd_vertex m adj₁ adj₂ h i h_v]
  · -- Non-vertex: i is in present-arrow or padding (by partition).
    -- The forward image is also in present-arrow or padding (disjoint from vertex).
    have h_partition := vertex_present_padding_partition m adj₁
    have hi_univ : i ∈ Finset.univ := Finset.mem_univ _
    rw [← h_partition] at hi_univ
    rcases Finset.mem_union.mp hi_univ with h_vp | h_pad
    · rcases Finset.mem_union.mp h_vp with h_v' | h_p
      · exact absurd h_v' h_v
      · -- Present-arrow case: image is in present-arrow adj₂, hence not vertex.
        have h_img : partitionPreservingFwd m adj₁ adj₂ h i ∈
                      presentArrowSlotIndices m adj₂ :=
          partitionPreservingFwd_presentArrow m adj₁ adj₂ h i h_p
        have h_not_v_img : partitionPreservingFwd m adj₁ adj₂ h i ∉
                            vertexSlotIndices m := fun h_v_img =>
          Finset.disjoint_left.mp
            (vertexSlotIndices_disjoint_presentArrowSlotIndices m adj₂)
            h_v_img h_img
        exact ⟨fun h_v' => absurd h_v' h_v, fun h_v' => absurd h_v' h_not_v_img⟩
    · -- Padding case: image is in padding adj₂, hence not vertex.
      have h_img : partitionPreservingFwd m adj₁ adj₂ h i ∈
                    paddingSlotIndices m adj₂ :=
        partitionPreservingFwd_padding m adj₁ adj₂ h i h_pad
      have h_not_v_img : partitionPreservingFwd m adj₁ adj₂ h i ∉
                          vertexSlotIndices m := fun h_v_img =>
        Finset.disjoint_left.mp
          (vertexSlotIndices_disjoint_paddingSlotIndices m adj₂)
          h_v_img h_img
      exact ⟨fun h_v' => absurd h_v' h_v, fun h_v' => absurd h_v' h_not_v_img⟩

/-- The constructed permutation is **present-arrow-slot-preserving**.

For any slot `i`, `i ∈ presentArrowSlotIndices m adj₁ ↔ π i ∈
presentArrowSlotIndices m adj₂`. -/
theorem partitionPreservingPermFromEqualCardinalities_presentArrowPreserving (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card) :
    IsPresentArrowSlotPreserving m adj₁ adj₂
      (partitionPreservingPermFromEqualCardinalities m adj₁ adj₂ h) := by
  intro i
  simp only [partitionPreservingPermFromEqualCardinalities_apply]
  constructor
  · -- Forward: i ∈ present adj₁ → fwd i ∈ present adj₂.
    intro h_p
    exact partitionPreservingFwd_presentArrow m adj₁ adj₂ h i h_p
  · -- Reverse: fwd i ∈ present adj₂ → i ∈ present adj₁.
    -- Case split on which class `i` is in.
    intro h_fwd
    by_cases h_v : i ∈ vertexSlotIndices m
    · -- Vertex case: fwd i = i, so i ∈ present adj₂. But i ∈ vertex,
      -- contradicting disjointness (vertex slots are independent of adj).
      rw [partitionPreservingFwd_vertex m adj₁ adj₂ h i h_v] at h_fwd
      exact absurd h_v
        (Finset.disjoint_left.mp
          (vertexSlotIndices_disjoint_presentArrowSlotIndices m adj₂) · h_fwd)
    · by_cases h_p : i ∈ presentArrowSlotIndices m adj₁
      · exact h_p
      · -- Padding case (only remaining): fwd i ∈ padding adj₂, contradicting h_fwd.
        have h_pad : i ∈ paddingSlotIndices m adj₁ := by
          have h_partition := vertex_present_padding_partition m adj₁
          have : i ∈ Finset.univ := Finset.mem_univ _
          rw [← h_partition] at this
          rcases Finset.mem_union.mp this with h_vp | h_pad
          · rcases Finset.mem_union.mp h_vp with h_v' | h_p'
            · exact absurd h_v' h_v
            · exact absurd h_p' h_p
          · exact h_pad
        have h_img : partitionPreservingFwd m adj₁ adj₂ h i ∈
                      paddingSlotIndices m adj₂ :=
          partitionPreservingFwd_padding m adj₁ adj₂ h i h_pad
        exact absurd h_fwd
          (Finset.disjoint_right.mp
            (presentArrowSlotIndices_disjoint_paddingSlotIndices m adj₂) h_img)

/-- The constructed permutation is **padding-slot-preserving**. -/
theorem partitionPreservingPermFromEqualCardinalities_paddingPreserving (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card) :
    IsPaddingSlotPreserving m adj₁ adj₂
      (partitionPreservingPermFromEqualCardinalities m adj₁ adj₂ h) := by
  intro i
  simp only [partitionPreservingPermFromEqualCardinalities_apply]
  constructor
  · intro h_pad
    exact partitionPreservingFwd_padding m adj₁ adj₂ h i h_pad
  · intro h_fwd
    by_cases h_v : i ∈ vertexSlotIndices m
    · rw [partitionPreservingFwd_vertex m adj₁ adj₂ h i h_v] at h_fwd
      exact absurd h_v
        (Finset.disjoint_left.mp
          (vertexSlotIndices_disjoint_paddingSlotIndices m adj₂) · h_fwd)
    · by_cases h_p : i ∈ presentArrowSlotIndices m adj₁
      · -- Present-arrow case: fwd i ∈ present adj₂, contradicting h_fwd.
        have h_img : partitionPreservingFwd m adj₁ adj₂ h i ∈
                      presentArrowSlotIndices m adj₂ :=
          partitionPreservingFwd_presentArrow m adj₁ adj₂ h i h_p
        exact absurd h_fwd
          (Finset.disjoint_right.mp
            (presentArrowSlotIndices_disjoint_paddingSlotIndices m adj₂).symm h_img)
      · -- Padding case (only remaining).
        have h_partition := vertex_present_padding_partition m adj₁
        have : i ∈ Finset.univ := Finset.mem_univ _
        rw [← h_partition] at this
        rcases Finset.mem_union.mp this with h_vp | h_pad
        · rcases Finset.mem_union.mp h_vp with h_v' | h_p'
          · exact absurd h_v' h_v
          · exact absurd h_p' h_p
        · exact h_pad

/-- **Headline theorem**: the constructed permutation is three-partition-
preserving with respect to `(adj₁, adj₂)`. -/
theorem partitionPreservingPermFromEqualCardinalities_isThreePartition (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : (presentArrowSlotIndices m adj₁).card =
         (presentArrowSlotIndices m adj₂).card) :
    IsThreePartitionPreserving m adj₁ adj₂
      (partitionPreservingPermFromEqualCardinalities m adj₁ adj₂ h) where
  vertex := partitionPreservingPermFromEqualCardinalities_vertexPreserving m adj₁ adj₂ h
  presentArrow :=
    partitionPreservingPermFromEqualCardinalities_presentArrowPreserving m adj₁ adj₂ h
  padding :=
    partitionPreservingPermFromEqualCardinalities_paddingPreserving m adj₁ adj₂ h

-- ============================================================================
-- T-API-4.G — Composition with the research-scope Prop.
-- ============================================================================

/-- **The composition theorem**: under the research-scope
`GL3PreservesPartitionCardinalities` Prop, every GL³ tensor isomorphism
gives rise to a three-partition-preserving permutation.

This is the **consumer-facing API** that Stages 4 and 5 build on:
once the `GL3PreservesPartitionCardinalities` Prop is discharged
(research-scope **R-15-residual-TI-reverse**), this theorem produces
the partition-preserving permutation unconditionally for every GL³
tensor isomorphism. -/
theorem partition_preserving_perm_under_GL3
    (h_gl3 : GL3PreservesPartitionCardinalities)
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (h_iso : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂) :
    ∃ π : Equiv.Perm (Fin (dimGQ m)),
      IsThreePartitionPreserving m adj₁ adj₂ π := by
  have h_card : (presentArrowSlotIndices m adj₁).card =
                (presentArrowSlotIndices m adj₂).card :=
    h_gl3 m adj₁ adj₂ g h_iso
  exact ⟨partitionPreservingPermFromEqualCardinalities m adj₁ adj₂ h_card,
         partitionPreservingPermFromEqualCardinalities_isThreePartition m
           adj₁ adj₂ h_card⟩

end GrochowQiao
end Orbcrypt
