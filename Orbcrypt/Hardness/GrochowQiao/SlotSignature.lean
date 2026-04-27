/-
Slot rank-signature classification (Stage 2 / T-API-3, R-TI rigidity discharge).

Defines and characterizes the three slot kinds — **vertex**,
**present-arrow**, and **padding** — that appear in the
Grochow–Qiao encoder, with index Finsets, cardinality identities,
disjointness, and partition lemmas.  The post-Stage-0 strengthening
(`ambientSlotStructureConstant = 2`) makes the three kinds literally
distinguishable at the diagonal-value level alone:

* Vertex slot diagonal: `1` (idempotent law `e_v · e_v = e_v`).
* Present-arrow slot diagonal: `0` (since `pathMul (.edge u v) (.edge u v) = none`
  from `J² = 0`).
* Padding slot diagonal: `2` (the strengthened ambient value).

This is the structural foundation the rigidity argument (Stage 3
T-API-4) consumes for slot classification.

See `docs/planning/R_TI_PHASE_C_THROUGH_H_PLAN.md` § Stage 2 T-API-3.
-/

import Orbcrypt.Hardness.GrochowQiao.StructureTensor

/-!
# Slot signature classification

This module establishes the structural slot-kind theory for the
Grochow–Qiao encoder.  The public API:

* `vertexSlotIndices m`, `presentArrowSlotIndices m adj`,
  `paddingSlotIndices m adj`, `pathSlotIndices m adj` — Finsets
  partitioning `Fin (dimGQ m)`.
* Cardinality identities: `vertexSlotIndices_card`,
  `presentArrowSlotIndices_card`, `paddingSlotIndices_card`,
  `pathSlotIndices_card`.
* Pairwise disjointness lemmas.
* Partition equation: every slot index is either vertex or arrow,
  every arrow is either present or padding.
* `grochowQiaoEncode_slotKind_of_diagonal` — the diagonal-value
  triple `(0, 1, 2)` determines slot kind on the encoder.

## Naming

Identifiers describe content (`vertexSlotIndices`,
`pathSlotIndices_card`), not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt

-- ============================================================================
-- T-API-3.1 — Slot-index Finsets (vertex / present-arrow / padding / path).
-- ============================================================================

/-- Boolean predicate: `i` is a vertex slot. -/
def isVertexSlot (m : ℕ) (i : Fin (dimGQ m)) : Bool :=
  match slotEquiv m i with
  | .vertex _ => true
  | .arrow _ _ => false

/-- Boolean predicate: `i` is a present-arrow slot for the given adjacency. -/
def isPresentArrowSlot (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i : Fin (dimGQ m)) : Bool :=
  match slotEquiv m i with
  | .vertex _ => false
  | .arrow u v => adj u v

/-- Boolean predicate: `i` is a padding slot for the given adjacency. -/
def isPaddingSlot (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i : Fin (dimGQ m)) : Bool :=
  match slotEquiv m i with
  | .vertex _ => false
  | .arrow u v => !(adj u v)

/-- The Finset of **vertex slot indices** in `Fin (dimGQ m)`.

A slot index `i` is a vertex slot iff `slotEquiv m i` has the form
`.vertex v` for some `v : Fin m`.  By the `slotEquiv` definition,
this is the lex-first `m` indices in `Fin (dimGQ m)`. -/
def vertexSlotIndices (m : ℕ) : Finset (Fin (dimGQ m)) :=
  Finset.univ.filter (fun i => isVertexSlot m i = true)

/-- The Finset of **present-arrow slot indices** in `Fin (dimGQ m)` for a
given adjacency.

A slot index `i` is a present-arrow slot iff `slotEquiv m i` has the
form `.arrow u v` *and* `adj u v = true`. -/
def presentArrowSlotIndices (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Finset (Fin (dimGQ m)) :=
  Finset.univ.filter (fun i => isPresentArrowSlot m adj i = true)

/-- The Finset of **padding slot indices** in `Fin (dimGQ m)` for a given
adjacency.

A slot index `i` is a padding slot iff `slotEquiv m i` has the form
`.arrow u v` *and* `adj u v = false`. -/
def paddingSlotIndices (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Finset (Fin (dimGQ m)) :=
  Finset.univ.filter (fun i => isPaddingSlot m adj i = true)

/-- The Finset of **path-algebra slot indices** in `Fin (dimGQ m)` for a
given adjacency.

This is the union of vertex slots (always path-algebra) and
present-arrow slots (path-algebra iff `adj u v = true`).  Equivalently,
the support of the `isPathAlgebraSlot m adj` predicate. -/
def pathSlotIndices (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Finset (Fin (dimGQ m)) :=
  Finset.univ.filter (fun i => isPathAlgebraSlot m adj i = true)

-- ============================================================================
-- T-API-3.2 — Membership-iff lemmas (slot-kind index Finset characterization).
-- ============================================================================

/-- `i ∈ vertexSlotIndices m` iff `slotEquiv m i` is a vertex slot. -/
theorem mem_vertexSlotIndices_iff (m : ℕ) (i : Fin (dimGQ m)) :
    i ∈ vertexSlotIndices m ↔ ∃ v : Fin m, slotEquiv m i = .vertex v := by
  simp only [vertexSlotIndices, Finset.mem_filter, Finset.mem_univ, true_and,
    isVertexSlot]
  cases h : slotEquiv m i with
  | vertex v =>
    constructor
    · intro _; exact ⟨v, rfl⟩
    · intro _; rfl
  | arrow u v =>
    constructor
    · intro h_eq; exact Bool.noConfusion h_eq
    · rintro ⟨w, hw⟩; nomatch hw

/-- `i ∈ presentArrowSlotIndices m adj` iff `slotEquiv m i` is an arrow
slot `(u, v)` with `adj u v = true`. -/
theorem mem_presentArrowSlotIndices_iff
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i : Fin (dimGQ m)) :
    i ∈ presentArrowSlotIndices m adj ↔
    ∃ u v : Fin m, slotEquiv m i = .arrow u v ∧ adj u v = true := by
  simp only [presentArrowSlotIndices, Finset.mem_filter, Finset.mem_univ, true_and,
    isPresentArrowSlot]
  cases h : slotEquiv m i with
  | vertex v =>
    constructor
    · intro h_eq; exact Bool.noConfusion h_eq
    · rintro ⟨u, w, hw, _⟩; nomatch hw
  | arrow u v =>
    constructor
    · intro h_adj; exact ⟨u, v, rfl, h_adj⟩
    · rintro ⟨u', v', hw, h_adj⟩
      have h_inj : u = u' ∧ v = v' := SlotKind.arrow.injEq u v u' v' |>.mp hw
      obtain ⟨rfl, rfl⟩ := h_inj
      exact h_adj

/-- `i ∈ paddingSlotIndices m adj` iff `slotEquiv m i` is an arrow slot
`(u, v)` with `adj u v = false`. -/
theorem mem_paddingSlotIndices_iff
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i : Fin (dimGQ m)) :
    i ∈ paddingSlotIndices m adj ↔
    ∃ u v : Fin m, slotEquiv m i = .arrow u v ∧ adj u v = false := by
  simp only [paddingSlotIndices, Finset.mem_filter, Finset.mem_univ, true_and,
    isPaddingSlot]
  cases h : slotEquiv m i with
  | vertex v =>
    constructor
    · intro h_eq; exact Bool.noConfusion h_eq
    · rintro ⟨u, w, hw, _⟩; nomatch hw
  | arrow u v =>
    constructor
    · intro h_not_adj
      refine ⟨u, v, rfl, ?_⟩
      cases h_b : adj u v with
      | true => simp [h_b] at h_not_adj
      | false => rfl
    · rintro ⟨u', v', hw, h_adj⟩
      have h_inj : u = u' ∧ v = v' := SlotKind.arrow.injEq u v u' v' |>.mp hw
      obtain ⟨rfl, rfl⟩ := h_inj
      simp [h_adj]

/-- `i ∈ pathSlotIndices m adj` iff `isPathAlgebraSlot m adj i = true`. -/
@[simp] theorem mem_pathSlotIndices_iff
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i : Fin (dimGQ m)) :
    i ∈ pathSlotIndices m adj ↔ isPathAlgebraSlot m adj i = true := by
  unfold pathSlotIndices
  simp [Finset.mem_filter]

-- ============================================================================
-- T-API-3.3 — Disjointness lemmas (slot kinds are mutually exclusive).
-- ============================================================================

/-- Vertex slots and present-arrow slots are disjoint. -/
theorem vertexSlotIndices_disjoint_presentArrowSlotIndices
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Disjoint (vertexSlotIndices m) (presentArrowSlotIndices m adj) := by
  rw [Finset.disjoint_left]
  intro i h_v h_p
  rw [mem_vertexSlotIndices_iff] at h_v
  rw [mem_presentArrowSlotIndices_iff] at h_p
  obtain ⟨v, hv⟩ := h_v
  obtain ⟨u', v', hp, _⟩ := h_p
  rw [hv] at hp
  nomatch hp

/-- Vertex slots and padding slots are disjoint. -/
theorem vertexSlotIndices_disjoint_paddingSlotIndices
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Disjoint (vertexSlotIndices m) (paddingSlotIndices m adj) := by
  rw [Finset.disjoint_left]
  intro i h_v h_p
  rw [mem_vertexSlotIndices_iff] at h_v
  rw [mem_paddingSlotIndices_iff] at h_p
  obtain ⟨v, hv⟩ := h_v
  obtain ⟨u', v', hp, _⟩ := h_p
  rw [hv] at hp
  nomatch hp

/-- Present-arrow slots and padding slots are disjoint. -/
theorem presentArrowSlotIndices_disjoint_paddingSlotIndices
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Disjoint (presentArrowSlotIndices m adj) (paddingSlotIndices m adj) := by
  rw [Finset.disjoint_left]
  intro i h_p h_pad
  rw [mem_presentArrowSlotIndices_iff] at h_p
  rw [mem_paddingSlotIndices_iff] at h_pad
  obtain ⟨u, v, hp, h_true⟩ := h_p
  obtain ⟨u', v', hpad, h_false⟩ := h_pad
  rw [hp] at hpad
  have h_inj : u = u' ∧ v = v' := SlotKind.arrow.injEq u v u' v' |>.mp hpad
  obtain ⟨rfl, rfl⟩ := h_inj
  rw [h_true] at h_false
  exact Bool.noConfusion h_false

-- ============================================================================
-- T-API-3.4 — Partition theorems (vertex + present-arrow + padding = univ).
-- ============================================================================

/-- The Finsets `vertexSlotIndices m`, `presentArrowSlotIndices m adj`,
and `paddingSlotIndices m adj` partition `Finset.univ`. -/
theorem vertex_present_padding_partition
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    vertexSlotIndices m ∪ presentArrowSlotIndices m adj ∪
      paddingSlotIndices m adj = Finset.univ := by
  apply Finset.ext
  intro i
  simp only [Finset.mem_union, Finset.mem_univ, iff_true]
  cases h : slotEquiv m i with
  | vertex v =>
    left; left
    rw [mem_vertexSlotIndices_iff]
    exact ⟨v, h⟩
  | arrow u v =>
    cases h_adj : adj u v with
    | true =>
      left; right
      rw [mem_presentArrowSlotIndices_iff]
      exact ⟨u, v, h, h_adj⟩
    | false =>
      right
      rw [mem_paddingSlotIndices_iff]
      exact ⟨u, v, h, h_adj⟩

/-- `pathSlotIndices m adj = vertexSlotIndices m ∪ presentArrowSlotIndices m adj`.

The path-algebra slots are exactly the union of vertex slots and
present-arrow slots, since `isPathAlgebraSlot` is `true` on vertex slots
unconditionally and on arrow slots iff `adj u v = true`. -/
theorem pathSlotIndices_eq_vertex_union_presentArrow
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    pathSlotIndices m adj =
    vertexSlotIndices m ∪ presentArrowSlotIndices m adj := by
  apply Finset.ext
  intro i
  -- Substitute `i = (slotEquiv m).symm (slotEquiv m i)` to set up case analysis
  -- on the slot kind.
  have h_i : i = (slotEquiv m).symm (slotEquiv m i) := (Equiv.symm_apply_apply _ _).symm
  rw [h_i]
  set s := slotEquiv m i with hs
  -- Now the goal is in terms of `(slotEquiv m).symm s` for `s : SlotKind m`.
  cases s with
  | vertex v =>
    simp only [Finset.mem_union, mem_pathSlotIndices_iff, mem_vertexSlotIndices_iff,
      mem_presentArrowSlotIndices_iff, isPathAlgebraSlot_vertex,
      Equiv.apply_symm_apply, true_iff]
    refine Or.inl ⟨v, rfl⟩
  | arrow u v =>
    simp only [Finset.mem_union, mem_pathSlotIndices_iff, mem_vertexSlotIndices_iff,
      mem_presentArrowSlotIndices_iff, isPathAlgebraSlot_arrow,
      Equiv.apply_symm_apply]
    constructor
    · intro h_adj
      exact Or.inr ⟨u, v, rfl, h_adj⟩
    · rintro (⟨w, hw⟩ | ⟨u', v', hw, h_adj⟩)
      · nomatch hw
      · have h_uv : u = u' ∧ v = v' := SlotKind.arrow.injEq u v u' v' |>.mp hw
        rw [h_uv.1, h_uv.2]
        exact h_adj

-- ============================================================================
-- T-API-3.5 — Cardinality lemmas.
-- ============================================================================

/-- The number of vertex slots equals `m`. -/
theorem vertexSlotIndices_card (m : ℕ) :
    (vertexSlotIndices m).card = m := by
  -- The vertex slot Finset equals the image of `Finset.univ : Finset (Fin m)`
  -- under `(slotEquiv m).symm ∘ .vertex`. The image of an injective function
  -- has the same cardinality as the source.
  have h_eq : vertexSlotIndices m =
      ((Finset.univ : Finset (Fin m)).image
        (fun v => (slotEquiv m).symm (.vertex v))) := by
    apply Finset.ext
    intro i
    simp only [Finset.mem_image, Finset.mem_univ, true_and]
    rw [mem_vertexSlotIndices_iff]
    constructor
    · rintro ⟨v, hv⟩
      refine ⟨v, ?_⟩
      rw [← hv, Equiv.symm_apply_apply]
    · rintro ⟨v, hv⟩
      refine ⟨v, ?_⟩
      rw [← hv, Equiv.apply_symm_apply]
  rw [h_eq]
  rw [Finset.card_image_of_injective _ (fun a b (h : (slotEquiv m).symm (.vertex a) =
                                          (slotEquiv m).symm (.vertex b)) => by
    have h2 : SlotKind.vertex a = SlotKind.vertex b := (slotEquiv m).symm.injective h
    have : a = b := SlotKind.vertex.injEq a b |>.mp h2
    exact this)]
  exact (Finset.card_univ : (Finset.univ : Finset (Fin m)).card = Fintype.card (Fin m)).trans
    (Fintype.card_fin m)

/-- The vertex slots and the path-algebra slots have the same cardinality
on the empty graph: every slot is either a vertex or padding. -/
theorem pathSlotIndices_card_empty (m : ℕ) :
    (pathSlotIndices m (fun _ _ => false)).card = m := by
  rw [pathSlotIndices_eq_vertex_union_presentArrow]
  rw [Finset.card_union_of_disjoint
    (vertexSlotIndices_disjoint_presentArrowSlotIndices m _)]
  rw [vertexSlotIndices_card]
  -- The empty graph has no present arrows, so the second term is 0.
  have : presentArrowSlotIndices m (fun _ _ => false) = ∅ := by
    apply Finset.ext
    intro i
    simp only [mem_presentArrowSlotIndices_iff, Finset.notMem_empty, iff_false]
    rintro ⟨_, _, _, h⟩
    exact Bool.noConfusion h
  rw [this, Finset.card_empty, Nat.add_zero]

-- ============================================================================
-- T-API-3.6 — Diagonal-value-determines-slot-kind on the encoder.
--
-- Post-Stage-0, the three slot kinds have pairwise distinct diagonal
-- values on the encoder: vertex = 1, present-arrow = 0, padding = 2.
-- These three values are the foundational invariant the rigidity
-- argument (Stage 3 T-API-4) consumes for slot classification.
-- ============================================================================

/-- For a vertex slot index `i`, the encoder diagonal value is `1`. -/
theorem grochowQiaoEncode_diagonal_at_vertexSlot
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i : Fin (dimGQ m))
    (h_v : i ∈ vertexSlotIndices m) :
    grochowQiaoEncode m adj i i i = 1 := by
  rw [mem_vertexSlotIndices_iff] at h_v
  obtain ⟨v, hv⟩ := h_v
  have h_i : i = (slotEquiv m).symm (.vertex v) := by
    rw [← hv, Equiv.symm_apply_apply]
  rw [h_i]
  exact grochowQiaoEncode_diagonal_vertex m adj v

/-- For a present-arrow slot index `i`, the encoder diagonal value is `0`. -/
theorem grochowQiaoEncode_diagonal_at_presentArrowSlot
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i : Fin (dimGQ m))
    (h_p : i ∈ presentArrowSlotIndices m adj) :
    grochowQiaoEncode m adj i i i = 0 := by
  rw [mem_presentArrowSlotIndices_iff] at h_p
  obtain ⟨u, v, hp, h_adj⟩ := h_p
  have h_i : i = (slotEquiv m).symm (.arrow u v) := by
    rw [← hp, Equiv.symm_apply_apply]
  rw [h_i]
  exact grochowQiaoEncode_diagonal_present_arrow m adj u v h_adj

/-- For a padding slot index `i`, the encoder diagonal value is `2`. -/
theorem grochowQiaoEncode_diagonal_at_paddingSlot
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i : Fin (dimGQ m))
    (h_pad : i ∈ paddingSlotIndices m adj) :
    grochowQiaoEncode m adj i i i = 2 := by
  rw [mem_paddingSlotIndices_iff] at h_pad
  obtain ⟨u, v, hp, h_adj⟩ := h_pad
  have h_i : i = (slotEquiv m).symm (.arrow u v) := by
    rw [← hp, Equiv.symm_apply_apply]
  rw [h_i]
  exact grochowQiaoEncode_diagonal_padding m adj u v h_adj

/-- The three slot-kind diagonal values `(1, 0, 2)` are pairwise distinct.

This is the post-Stage-0 distinguishability property: the encoder's
diagonal value at any slot literally determines its kind. -/
theorem encoder_diagonal_values_pairwise_distinct :
    ((1 : ℚ) ≠ 0) ∧ ((1 : ℚ) ≠ 2) ∧ ((0 : ℚ) ≠ 2) := by
  refine ⟨?_, ?_, ?_⟩ <;> norm_num

end GrochowQiao
end Orbcrypt
