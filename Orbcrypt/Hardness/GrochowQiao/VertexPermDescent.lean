/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
Vertex permutation descent (Stage 2 / T-API-6, R-TI rigidity discharge).

Given a vertex-slot-preserving permutation `π : Equiv.Perm (Fin (dimGQ m))`,
descend to a vertex permutation `σ : Equiv.Perm (Fin m)` via `slotEquiv`.
This is the structural step that bridges the slot-level rigidity content
of Stages 2-3 to the vertex-level conclusion of `GrochowQiaoRigidity`
(`σ : Equiv.Perm (Fin m)` such that `adj₁ i j = adj₂ (σ i) (σ j)`).

See `docs/planning/R_TI_PHASE_C_THROUGH_H_PLAN.md` § Stage 2 T-API-6.
-/

import Orbcrypt.Hardness.GrochowQiao.SlotBijection

/-!
# Vertex permutation descent

This module descends a vertex-slot-preserving permutation
`π : Equiv.Perm (Fin (dimGQ m))` to an honest vertex permutation
`σ : Equiv.Perm (Fin m)`, using `slotEquiv` to convert between the
two index types.

The construction:

* For `v : Fin m`, lift to the vertex slot index `(slotEquiv m).symm
  (.vertex v)`.
* Apply `π`, getting another slot index `π ((slotEquiv m).symm (.vertex
  v))` which is also a vertex slot (by the vertex-preserving hypothesis).
* Read off the vertex from `slotEquiv m (π ((slotEquiv m).symm (.vertex
  v)))`, which has the form `.vertex w` for some unique `w : Fin m`.
* The map `v ↦ w` is the descended vertex permutation σ.

Public API:

* `vertexImage m π h v : Fin m` — the vertex on the other side of π,
  defined when π is vertex-slot-preserving.
* `vertexImage_spec` — the characteristic identity for `vertexImage`.
* `vertexPermOfVertexPreserving m π h : Equiv.Perm (Fin m)` — the
  descended permutation.
* `vertexPermOfVertexPreserving_apply` — explicit formula.
* `vertexPermOfVertexPreserving_one` — round-trip with the identity.

## Naming

Identifiers describe content (`vertexImage`,
`vertexPermOfVertexPreserving`), not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt

-- ============================================================================
-- T-API-6.1 — Vertex image of π at v.
-- ============================================================================

/-- **Vertex image** of `v : Fin m` under a vertex-slot-preserving π.

Given `π : Equiv.Perm (Fin (dimGQ m))` that preserves vertex slots,
`vertexImage m π h v` is the unique `w : Fin m` such that
`slotEquiv m (π ((slotEquiv m).symm (.vertex v))) = .vertex w`.

This is the "forward" component of the descended permutation. -/
noncomputable def vertexImage (m : ℕ) (π : Equiv.Perm (Fin (dimGQ m)))
    (h : IsVertexSlotPreserving m π) (v : Fin m) : Fin m := by
  have h_in : (slotEquiv m).symm (.vertex v) ∈ vertexSlotIndices m := by
    rw [mem_vertexSlotIndices_iff]
    exact ⟨v, by rw [Equiv.apply_symm_apply]⟩
  have h_out : π ((slotEquiv m).symm (.vertex v)) ∈ vertexSlotIndices m :=
    (h _).mp h_in
  rw [mem_vertexSlotIndices_iff] at h_out
  exact h_out.choose

/-- The characteristic identity for `vertexImage`:
`slotEquiv m (π ((slotEquiv m).symm (.vertex v))) = .vertex (vertexImage m π h v)`. -/
theorem vertexImage_spec (m : ℕ) (π : Equiv.Perm (Fin (dimGQ m)))
    (h : IsVertexSlotPreserving m π) (v : Fin m) :
    slotEquiv m (π ((slotEquiv m).symm (.vertex v))) =
      .vertex (vertexImage m π h v) := by
  unfold vertexImage
  -- The choice from the existential satisfies the spec by definition.
  have h_in : (slotEquiv m).symm (.vertex v) ∈ vertexSlotIndices m := by
    rw [mem_vertexSlotIndices_iff]
    exact ⟨v, by rw [Equiv.apply_symm_apply]⟩
  have h_out : π ((slotEquiv m).symm (.vertex v)) ∈ vertexSlotIndices m :=
    (h _).mp h_in
  rw [mem_vertexSlotIndices_iff] at h_out
  exact h_out.choose_spec

-- ============================================================================
-- T-API-6.2 — Inverse compatibility.
-- ============================================================================

/-- The vertex image of `vertexImage m π h v` under `π⁻¹` is `v`.

This is the "round-trip" identity that makes `vertexPermOfVertexPreserving`
a valid `Equiv`. -/
theorem vertexImage_inv (m : ℕ) (π : Equiv.Perm (Fin (dimGQ m)))
    (h : IsVertexSlotPreserving m π) (v : Fin m) :
    vertexImage m π⁻¹ h.inv (vertexImage m π h v) = v := by
  -- Use the characteristic identities at both layers.
  have h_v := vertexImage_spec m π h v
  have h_w := vertexImage_spec m π⁻¹ h.inv (vertexImage m π h v)
  have h_eq : (slotEquiv m).symm (.vertex (vertexImage m π h v)) =
              π ((slotEquiv m).symm (.vertex v)) := by
    apply (slotEquiv m).injective
    rw [Equiv.apply_symm_apply]
    exact h_v.symm
  rw [h_eq] at h_w
  rw [show π⁻¹ (π ((slotEquiv m).symm (.vertex v))) = (slotEquiv m).symm (.vertex v)
        from by simp] at h_w
  rw [Equiv.apply_symm_apply] at h_w
  -- h_w : .vertex v = .vertex (vertexImage m π⁻¹ h.inv (vertexImage m π h v))
  exact (SlotKind.vertex.injEq _ _ |>.mp h_w).symm

/-- The other direction: vertex image of `vertexImage m π⁻¹ h.inv v` under `π` is `v`.

This is the symmetric round-trip identity. Proof: same structure as
`vertexImage_inv`, swapping the role of π and π⁻¹. -/
theorem vertexImage_inv' (m : ℕ) (π : Equiv.Perm (Fin (dimGQ m)))
    (h : IsVertexSlotPreserving m π) (v : Fin m) :
    vertexImage m π h (vertexImage m π⁻¹ h.inv v) = v := by
  have h_v := vertexImage_spec m π⁻¹ h.inv v
  have h_w := vertexImage_spec m π h (vertexImage m π⁻¹ h.inv v)
  have h_eq : (slotEquiv m).symm (.vertex (vertexImage m π⁻¹ h.inv v)) =
              π⁻¹ ((slotEquiv m).symm (.vertex v)) := by
    apply (slotEquiv m).injective
    rw [Equiv.apply_symm_apply]
    exact h_v.symm
  rw [h_eq] at h_w
  rw [show π (π⁻¹ ((slotEquiv m).symm (.vertex v))) = (slotEquiv m).symm (.vertex v)
        from by simp] at h_w
  rw [Equiv.apply_symm_apply] at h_w
  -- h_w : .vertex v = .vertex (vertexImage m π h (vertexImage m π⁻¹ h.inv v))
  exact (SlotKind.vertex.injEq _ _ |>.mp h_w).symm

-- ============================================================================
-- T-API-6.3 — Construct the descended vertex permutation.
-- ============================================================================

/-- **Vertex permutation descent** (Stage 2 T-API-6 headline).

Given a vertex-slot-preserving permutation `π : Equiv.Perm (Fin (dimGQ m))`,
construct the corresponding vertex permutation `σ : Equiv.Perm (Fin m)`. -/
noncomputable def vertexPermOfVertexPreserving (m : ℕ)
    (π : Equiv.Perm (Fin (dimGQ m)))
    (h : IsVertexSlotPreserving m π) :
    Equiv.Perm (Fin m) where
  toFun := vertexImage m π h
  invFun := vertexImage m π⁻¹ h.inv
  left_inv := vertexImage_inv m π h
  right_inv := vertexImage_inv' m π h

/-- The descended permutation applied to `v` is `vertexImage m π h v`. -/
@[simp] theorem vertexPermOfVertexPreserving_apply (m : ℕ)
    (π : Equiv.Perm (Fin (dimGQ m)))
    (h : IsVertexSlotPreserving m π) (v : Fin m) :
    vertexPermOfVertexPreserving m π h v = vertexImage m π h v := rfl

-- ============================================================================
-- T-API-6.4 — Round-trip with the identity.
-- ============================================================================

/-- The identity slot permutation descends to the identity vertex permutation. -/
theorem vertexPermOfVertexPreserving_one (m : ℕ)
    (h : IsVertexSlotPreserving m (1 : Equiv.Perm (Fin (dimGQ m)))) :
    vertexPermOfVertexPreserving m 1 h = 1 := by
  apply Equiv.ext
  intro v
  -- The goal is `(vertexPermOfVertexPreserving m 1 h) v = 1 v`.
  -- Both are `Fin m`-valued; `(vertexPermOfVertexPreserving m 1 h) v`
  -- unfolds to `vertexImage m 1 h v`, and `1 v = v` for `Equiv.refl`.
  show vertexImage m 1 h v = v
  -- Apply `vertexImage_spec` at v: the identity acts trivially on
  -- `(slotEquiv m).symm (.vertex v)`, so the spec gives
  -- `slotEquiv (slotEquiv.symm (.vertex v)) = .vertex (vertexImage 1 h v)`,
  -- which reduces to `.vertex v = .vertex (vertexImage 1 h v)`.
  have hspec := vertexImage_spec m 1 h v
  rw [show (1 : Equiv.Perm (Fin (dimGQ m))) ((slotEquiv m).symm (.vertex v)) =
          (slotEquiv m).symm (.vertex v) from rfl] at hspec
  rw [Equiv.apply_symm_apply] at hspec
  exact (SlotKind.vertex.injEq _ _ |>.mp hspec).symm

end GrochowQiao
end Orbcrypt
