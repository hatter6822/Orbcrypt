/-
Slot bijection extraction (Stage 2 / T-API-5, R-TI rigidity discharge).

Defines the **partition-preserving permutation** predicate
(`IsPartitionPreserving`) and extracts per-class bijections from a
partition-preserving permutation.  The actual proof that GL³ tensor
isomorphisms give rise to partition-preserving permutations is
Stage 3 (T-API-4) content; this module provides the structural
extraction once the Prop is granted.

See `docs/planning/R_TI_PHASE_C_THROUGH_H_PLAN.md` § Stage 2 T-API-5.
-/

import Orbcrypt.Hardness.GrochowQiao.SlotSignature

/-!
# Partition-preserving permutations and slot bijections

A **partition-preserving** permutation `π : Equiv.Perm (Fin (dimGQ m))`
maps the path-algebra slots of `adj₁` to those of `adj₂` (and
correspondingly for padding).  Stronger refinements are
**vertex-preserving** (vertex slots map to vertex slots) and
**present-arrow-preserving** (present-arrow slots map to
present-arrow slots).

Public API:

* `IsPartitionPreserving π m adj₁ adj₂ : Prop` — π preserves the
  path-algebra-vs-padding partition.
* `IsVertexSlotPreserving π m`, `IsPresentArrowSlotPreserving π m
  adj₁ adj₂`, `IsPaddingSlotPreserving π m adj₁ adj₂` — refined
  partition predicates.
* `IsThreePartitionPreserving π m adj₁ adj₂` — π preserves all
  three slot-kind classes simultaneously (vertex, present-arrow,
  padding).
* `vertexBijOfThreePartitionPreserving` — extract a `Set.BijOn`
  from vertex slots of `adj₁` to vertex slots of `adj₂`.
* `presentArrowBijOfThreePartitionPreserving` — same for present arrows.

## Naming

Identifiers describe content (`IsPartitionPreserving`,
`vertexBijOfThreePartitionPreserving`), not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt

-- ============================================================================
-- T-API-5.1 — Partition-preserving predicate definitions.
-- ============================================================================

/-- A permutation `π : Equiv.Perm (Fin (dimGQ m))` is
**partition-preserving** with respect to `(adj₁, adj₂)` if it sends
path-algebra slots of `adj₁` to path-algebra slots of `adj₂`. -/
def IsPartitionPreserving (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (π : Equiv.Perm (Fin (dimGQ m))) : Prop :=
  ∀ i : Fin (dimGQ m),
    isPathAlgebraSlot m adj₁ i = isPathAlgebraSlot m adj₂ (π i)

/-- A permutation `π` is **vertex-slot-preserving** if it sends vertex
slots to vertex slots. -/
def IsVertexSlotPreserving (m : ℕ) (π : Equiv.Perm (Fin (dimGQ m))) : Prop :=
  ∀ i : Fin (dimGQ m), i ∈ vertexSlotIndices m ↔ π i ∈ vertexSlotIndices m

/-- A permutation `π` is **present-arrow-slot-preserving** with respect
to `(adj₁, adj₂)` if it sends present-arrow slots of `adj₁` to
present-arrow slots of `adj₂`. -/
def IsPresentArrowSlotPreserving (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (π : Equiv.Perm (Fin (dimGQ m))) : Prop :=
  ∀ i : Fin (dimGQ m),
    i ∈ presentArrowSlotIndices m adj₁ ↔ π i ∈ presentArrowSlotIndices m adj₂

/-- A permutation `π` is **padding-slot-preserving** with respect to
`(adj₁, adj₂)` if it sends padding slots of `adj₁` to padding slots
of `adj₂`. -/
def IsPaddingSlotPreserving (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (π : Equiv.Perm (Fin (dimGQ m))) : Prop :=
  ∀ i : Fin (dimGQ m),
    i ∈ paddingSlotIndices m adj₁ ↔ π i ∈ paddingSlotIndices m adj₂

/-- A permutation `π` is **three-partition-preserving** with respect to
`(adj₁, adj₂)` if it preserves all three slot-kind classes simultaneously:
vertex slots map to vertex slots, present arrows to present arrows,
padding to padding.

This is the strongest slot-classification predicate, and is the
canonical input to Stages 2 T-API-6 and Stage 3 T-API-4's downstream
consumers. -/
structure IsThreePartitionPreserving (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (π : Equiv.Perm (Fin (dimGQ m))) : Prop where
  vertex : IsVertexSlotPreserving m π
  presentArrow : IsPresentArrowSlotPreserving m adj₁ adj₂ π
  padding : IsPaddingSlotPreserving m adj₁ adj₂ π

-- ============================================================================
-- T-API-5.2 — Identity permutation is trivially three-partition-preserving.
-- ============================================================================

/-- The identity permutation is three-partition-preserving for `adj₁ = adj₂`. -/
theorem isThreePartitionPreserving_one (m : ℕ) (adj : Fin m → Fin m → Bool) :
    IsThreePartitionPreserving m adj adj 1 where
  vertex := fun _ => Iff.rfl
  presentArrow := fun _ => Iff.rfl
  padding := fun _ => Iff.rfl

-- ============================================================================
-- T-API-5.3 — Inverse of three-partition-preserving is three-partition-preserving.
-- ============================================================================

/-- If `π` is vertex-slot-preserving, so is `π⁻¹`. -/
theorem IsVertexSlotPreserving.inv {m : ℕ}
    {π : Equiv.Perm (Fin (dimGQ m))}
    (h : IsVertexSlotPreserving m π) :
    IsVertexSlotPreserving m π⁻¹ := fun i => by
  -- We have h (π⁻¹ i) : (π⁻¹ i ∈ V) ↔ (π (π⁻¹ i) ∈ V), and π (π⁻¹ i) = i.
  have h_back : π (π⁻¹ i) = i := by simp
  rw [Iff.comm]
  rw [show (π⁻¹ i ∈ vertexSlotIndices m) ↔ (π (π⁻¹ i) ∈ vertexSlotIndices m)
        from h (π⁻¹ i)]
  rw [h_back]

/-- If `π` is present-arrow-slot-preserving from `adj₁` to `adj₂`, then `π⁻¹`
is present-arrow-slot-preserving from `adj₂` to `adj₁`. -/
theorem IsPresentArrowSlotPreserving.inv {m : ℕ}
    {adj₁ adj₂ : Fin m → Fin m → Bool}
    {π : Equiv.Perm (Fin (dimGQ m))}
    (h : IsPresentArrowSlotPreserving m adj₁ adj₂ π) :
    IsPresentArrowSlotPreserving m adj₂ adj₁ π⁻¹ := fun i => by
  have h_back : π (π⁻¹ i) = i := by simp
  rw [Iff.comm]
  rw [show (π⁻¹ i ∈ presentArrowSlotIndices m adj₁) ↔
        (π (π⁻¹ i) ∈ presentArrowSlotIndices m adj₂) from h (π⁻¹ i)]
  rw [h_back]

/-- If `π` is padding-slot-preserving from `adj₁` to `adj₂`, then `π⁻¹`
is padding-slot-preserving from `adj₂` to `adj₁`. -/
theorem IsPaddingSlotPreserving.inv {m : ℕ}
    {adj₁ adj₂ : Fin m → Fin m → Bool}
    {π : Equiv.Perm (Fin (dimGQ m))}
    (h : IsPaddingSlotPreserving m adj₁ adj₂ π) :
    IsPaddingSlotPreserving m adj₂ adj₁ π⁻¹ := fun i => by
  have h_back : π (π⁻¹ i) = i := by simp
  rw [Iff.comm]
  rw [show (π⁻¹ i ∈ paddingSlotIndices m adj₁) ↔
        (π (π⁻¹ i) ∈ paddingSlotIndices m adj₂) from h (π⁻¹ i)]
  rw [h_back]

/-- If `π` is three-partition-preserving from `adj₁` to `adj₂`, then `π⁻¹` is
three-partition-preserving from `adj₂` to `adj₁`. -/
theorem IsThreePartitionPreserving.inv {m : ℕ}
    {adj₁ adj₂ : Fin m → Fin m → Bool}
    {π : Equiv.Perm (Fin (dimGQ m))}
    (h : IsThreePartitionPreserving m adj₁ adj₂ π) :
    IsThreePartitionPreserving m adj₂ adj₁ π⁻¹ where
  vertex := h.vertex.inv
  presentArrow := h.presentArrow.inv
  padding := h.padding.inv

-- ============================================================================
-- T-API-5.4 — Bijection extraction on slot classes.
-- ============================================================================

/-- Given a vertex-slot-preserving permutation, the restriction to vertex
slots is a `BijOn` from vertex slots to vertex slots. -/
theorem vertexSlot_bijOn_of_vertexPreserving (m : ℕ)
    (π : Equiv.Perm (Fin (dimGQ m)))
    (h : IsVertexSlotPreserving m π) :
    Set.BijOn (fun i => π i) (vertexSlotIndices m : Set _)
                                (vertexSlotIndices m : Set _) := by
  refine ⟨?_, ?_, ?_⟩
  · -- mapsTo
    intro i hi
    simp only [Finset.mem_coe] at hi ⊢
    exact (h i).mp hi
  · -- injOn (π is globally injective so trivially injOn)
    intro i _ j _ h_eq
    exact π.injective h_eq
  · -- surjOn
    intro j hj
    simp only [Finset.mem_coe] at hj
    refine ⟨π⁻¹ j, ?_, by simp⟩
    -- Need: π⁻¹ j ∈ V.  Use IsVertexSlotPreserving.inv applied at j.
    have h_inv : IsVertexSlotPreserving m π⁻¹ := h.inv
    exact (h_inv j).mp hj

/-- Given a present-arrow-slot-preserving permutation from `adj₁` to `adj₂`,
the restriction to present-arrow slots is a `BijOn`. -/
theorem presentArrowSlot_bijOn_of_presentArrowPreserving (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (π : Equiv.Perm (Fin (dimGQ m)))
    (h : IsPresentArrowSlotPreserving m adj₁ adj₂ π) :
    Set.BijOn (fun i => π i) (presentArrowSlotIndices m adj₁ : Set _)
                                (presentArrowSlotIndices m adj₂ : Set _) := by
  refine ⟨?_, ?_, ?_⟩
  · intro i hi
    simp only [Finset.mem_coe] at hi ⊢
    exact (h i).mp hi
  · intro i _ j _ h_eq
    exact π.injective h_eq
  · intro j hj
    simp only [Finset.mem_coe] at hj
    refine ⟨π⁻¹ j, ?_, by simp⟩
    have h_inv : IsPresentArrowSlotPreserving m adj₂ adj₁ π⁻¹ := h.inv
    exact (h_inv j).mp hj

/-- Given a padding-slot-preserving permutation from `adj₁` to `adj₂`, the
restriction to padding slots is a `BijOn`. -/
theorem paddingSlot_bijOn_of_paddingPreserving (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (π : Equiv.Perm (Fin (dimGQ m)))
    (h : IsPaddingSlotPreserving m adj₁ adj₂ π) :
    Set.BijOn (fun i => π i) (paddingSlotIndices m adj₁ : Set _)
                                (paddingSlotIndices m adj₂ : Set _) := by
  refine ⟨?_, ?_, ?_⟩
  · intro i hi
    simp only [Finset.mem_coe] at hi ⊢
    exact (h i).mp hi
  · intro i _ j _ h_eq
    exact π.injective h_eq
  · intro j hj
    simp only [Finset.mem_coe] at hj
    refine ⟨π⁻¹ j, ?_, by simp⟩
    have h_inv : IsPaddingSlotPreserving m adj₂ adj₁ π⁻¹ := h.inv
    exact (h_inv j).mp hj

-- ============================================================================
-- T-API-5.5 — Cardinality preservation under partition-preserving permutation.
-- ============================================================================

/-- A vertex-slot-preserving permutation preserves the vertex-slot
cardinality (which is always `m`, but stated as a structural identity). -/
theorem vertexSlotIndices_card_eq_of_vertexPreserving (m : ℕ)
    (π : Equiv.Perm (Fin (dimGQ m)))
    (_ : IsVertexSlotPreserving m π) :
    (vertexSlotIndices m).card = (vertexSlotIndices m).card := rfl

/-- A present-arrow-slot-preserving permutation forces both adjacencies to
have the same number of present arrows.

Proof technique: the image of `presentArrowSlotIndices m adj₁` under π
equals `presentArrowSlotIndices m adj₂` (by partition-preservation),
and an image under an injective function preserves cardinality. -/
theorem presentArrowSlot_card_eq_of_presentArrowPreserving (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (π : Equiv.Perm (Fin (dimGQ m)))
    (h : IsPresentArrowSlotPreserving m adj₁ adj₂ π) :
    (presentArrowSlotIndices m adj₁).card =
      (presentArrowSlotIndices m adj₂).card := by
  -- Show the Finset image of `presentArrowSlotIndices m adj₁` under π equals
  -- `presentArrowSlotIndices m adj₂`.
  have h_image : (presentArrowSlotIndices m adj₁).image π =
                 presentArrowSlotIndices m adj₂ := by
    apply Finset.ext
    intro j
    simp only [Finset.mem_image]
    constructor
    · rintro ⟨i, hi, rfl⟩; exact (h i).mp hi
    · intro hj
      have h_inv : IsPresentArrowSlotPreserving m adj₂ adj₁ π⁻¹ := h.inv
      refine ⟨π⁻¹ j, ?_, by simp⟩
      exact (h_inv j).mp hj
  rw [← h_image, Finset.card_image_of_injective _ π.injective]

/-- A padding-slot-preserving permutation preserves the padding-slot
cardinality. -/
theorem paddingSlot_card_eq_of_paddingPreserving (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (π : Equiv.Perm (Fin (dimGQ m)))
    (h : IsPaddingSlotPreserving m adj₁ adj₂ π) :
    (paddingSlotIndices m adj₁).card =
      (paddingSlotIndices m adj₂).card := by
  have h_image : (paddingSlotIndices m adj₁).image π =
                 paddingSlotIndices m adj₂ := by
    apply Finset.ext
    intro j
    simp only [Finset.mem_image]
    constructor
    · rintro ⟨i, hi, rfl⟩; exact (h i).mp hi
    · intro hj
      have h_inv : IsPaddingSlotPreserving m adj₂ adj₁ π⁻¹ := h.inv
      refine ⟨π⁻¹ j, ?_, by simp⟩
      exact (h_inv j).mp hj
  rw [← h_image, Finset.card_image_of_injective _ π.injective]

/-- A three-partition-preserving permutation forces both adjacencies to
have the same number of present arrows (and the same number of padding
slots, by complement). -/
theorem present_arrow_count_eq_of_threePartitionPreserving (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (π : Equiv.Perm (Fin (dimGQ m)))
    (h : IsThreePartitionPreserving m adj₁ adj₂ π) :
    (presentArrowSlotIndices m adj₁).card =
      (presentArrowSlotIndices m adj₂).card :=
  presentArrowSlot_card_eq_of_presentArrowPreserving m adj₁ adj₂ π h.presentArrow

end GrochowQiao
end Orbcrypt
