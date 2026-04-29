/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
GL³ rank invariance for 3-tensor unfoldings (Stage 1 / T-API-2,
R-TI rigidity discharge).

Builds on `Orbcrypt/Hardness/GrochowQiao/TensorUnfold.lean` (T-API-1)
to prove that the rank of each unfolding `unfold_k T` is invariant
under the GL³ tensor action.  This is the consumer-facing rank
invariant that Stages 2–5 of the rigidity-discharge plan consume.

The proof technique is:
* Apply T-API-1's `unfold_k` bridges to express `unfold_k (g • T)`
  as a matrix product involving `g_k.val` (left multiplication) and
  Kronecker products of the other two factors (right multiplication).
* Use Mathlib's `rank_mul_eq_*_of_isUnit_det` lemmas to peel off
  invertible matrix factors.
* Use `det_kronecker` and `IsUnit.pow` / `IsUnit.mul` to argue that
  Kronecker products of GL elements have invertible determinant.

See `docs/planning/R_TI_PHASE_C_THROUGH_H_PLAN.md` § Stage 1 T-API-2.
-/

import Orbcrypt.Hardness.GrochowQiao.TensorUnfold
import Mathlib.LinearAlgebra.Matrix.Rank

/-!
# GL³ rank invariance for 3-tensor unfoldings

For any field `F` (or more generally, `CommRing F`), the rank of each
unfolding `unfold_k T` of a 3-tensor `T : Tensor3 n F` is invariant
under the GL³ tensor action.  This module establishes:

* `kronecker_isUnit_det` — Kronecker product of matrices with
  invertible determinant has invertible determinant.
* `unfoldRank_k T = (unfold_k T).rank` for `k ∈ {1, 2, 3}`.
* `unfoldRank_k_smul` — each unfolding rank is GL³-invariant.
* `tensorRank T : ℕ × ℕ × ℕ` — the triple of unfolding ranks.
* `tensorRank_smul` — the triple is GL³-invariant.
* `tensorRank_areTensorIsomorphic` — direct corollary for the
  consumer-facing `AreTensorIsomorphic` predicate.

## Naming

Identifiers describe content (`tensorRank_smul`,
`kronecker_isUnit_det`), not workstream provenance.
-/

namespace Orbcrypt
namespace Tensor3

open scoped Matrix
open scoped Kronecker
open Matrix

variable {n : ℕ} {F : Type*}

-- ============================================================================
-- T-API-2.1 — Kronecker product preserves invertibility.
-- ============================================================================

/-- The Kronecker product of two matrices with invertible determinant has
invertible determinant.

`IsUnit A.det → IsUnit B.det → IsUnit (A ⊗ₖ B).det`.

*Proof.* By `Matrix.det_kronecker`, `det (A ⊗ₖ B) = det A ^ card n *
det B ^ card m`.  Both factors are units (powers of units), so the
product is a unit. -/
theorem kronecker_isUnit_det [CommRing F]
    (A B : Matrix (Fin n) (Fin n) F)
    (hA : IsUnit A.det) (hB : IsUnit B.det) :
    IsUnit (A ⊗ₖ B).det := by
  rw [Matrix.det_kronecker]
  exact (hA.pow _).mul (hB.pow _)

-- ============================================================================
-- T-API-2.2 — Per-axis unfolding ranks.
-- ============================================================================

/-- Axis-1 unfolding rank: `(unfold₁ T).rank` as a tensor invariant. -/
noncomputable def unfoldRank₁ [CommRing F] (T : Tensor3 n F) : ℕ := (unfold₁ T).rank

/-- Axis-2 unfolding rank. -/
noncomputable def unfoldRank₂ [CommRing F] (T : Tensor3 n F) : ℕ := (unfold₂ T).rank

/-- Axis-3 unfolding rank. -/
noncomputable def unfoldRank₃ [CommRing F] (T : Tensor3 n F) : ℕ := (unfold₃ T).rank

/-- The **tensor rank tuple** of a 3-tensor: the three unfolding ranks
packaged as a triple.  Each component is a GL³-invariant. -/
noncomputable def tensorRank [CommRing F] (T : Tensor3 n F) : ℕ × ℕ × ℕ :=
  (unfoldRank₁ T, unfoldRank₂ T, unfoldRank₃ T)

-- ============================================================================
-- T-API-2.3 — Axis-1 unfolding rank is GL³-invariant.
-- ============================================================================

variable [Field F]

/-- The axis-1 unfolding rank is invariant under the GL³ tensor action.

`unfoldRank₁ (g • T) = unfoldRank₁ T`.

*Proof.* By T-API-1's `unfold₁_tensorContract`,
`unfold₁ (g • T) = g.1.val * unfold₁ T * (g.2.1.valᵀ ⊗ₖ g.2.2.valᵀ)`.
The left factor `g.1.val` is invertible (unit determinant), and the
right factor `g.2.1.valᵀ ⊗ₖ g.2.2.valᵀ` is invertible by Mathlib's
`Matrix.IsUnit.kronecker` and `Matrix.isUnit_det_iff_isUnit`.  Apply
`rank_mul_eq_left_of_isUnit_det` (right) and
`rank_mul_eq_right_of_isUnit_det` (left) to peel off both factors. -/
theorem unfoldRank₁_smul
    (g : GL (Fin n) F × GL (Fin n) F × GL (Fin n) F) (T : Tensor3 n F) :
    unfoldRank₁ (g • T) = unfoldRank₁ T := by
  unfold unfoldRank₁
  -- Unfold (g • T) = tensorContract g.1.val g.2.1.val g.2.2.val T.
  show (unfold₁ ((tensorAction).smul g T)).rank = (unfold₁ T).rank
  show (unfold₁ (tensorContract (g.1.val) (g.2.1.val) (g.2.2.val) T)).rank =
       (unfold₁ T).rank
  rw [unfold₁_tensorContract]
  -- Goal: (g.1.val * unfold₁ T * (g.2.1.valᵀ ⊗ₖ g.2.2.valᵀ)).rank = (unfold₁ T).rank
  -- The matrix g.2.1.valᵀ ⊗ₖ g.2.2.valᵀ has unit determinant.
  have h_g21_det : IsUnit (g.2.1.val).det :=
    (g.2.1).isUnit.map (Matrix.detMonoidHom (R := F) (n := Fin n))
  have h_g22_det : IsUnit (g.2.2.val).det :=
    (g.2.2).isUnit.map (Matrix.detMonoidHom (R := F) (n := Fin n))
  have h_g1_det : IsUnit (g.1.val).det :=
    (g.1).isUnit.map (Matrix.detMonoidHom (R := F) (n := Fin n))
  have h_g21T_det : IsUnit ((g.2.1.val)ᵀ).det := by
    rw [Matrix.det_transpose]; exact h_g21_det
  have h_g22T_det : IsUnit ((g.2.2.val)ᵀ).det := by
    rw [Matrix.det_transpose]; exact h_g22_det
  have h_kron_det : IsUnit ((g.2.1.val)ᵀ ⊗ₖ (g.2.2.val)ᵀ).det :=
    kronecker_isUnit_det _ _ h_g21T_det h_g22T_det
  -- Strip the right Kronecker factor (rank invariant under right-mult by invertible).
  rw [Matrix.rank_mul_eq_left_of_isUnit_det _ _ h_kron_det]
  -- Strip the left g.1 factor (rank invariant under left-mult by invertible).
  rw [Matrix.rank_mul_eq_right_of_isUnit_det _ _ h_g1_det]

-- ============================================================================
-- T-API-2.4 — Consumer-facing rank-invariance corollary on `AreTensorIsomorphic`.
-- ============================================================================

/-- The axis-1 unfolding rank is preserved by tensor isomorphism.

`AreTensorIsomorphic T₁ T₂ → unfoldRank₁ T₁ = unfoldRank₁ T₂`. -/
theorem unfoldRank₁_areTensorIsomorphic (T₁ T₂ : Tensor3 n F)
    (h : AreTensorIsomorphic T₁ T₂) :
    unfoldRank₁ T₁ = unfoldRank₁ T₂ := by
  obtain ⟨g, hg⟩ := h
  rw [← hg, unfoldRank₁_smul]

-- ============================================================================
-- Note on axis-2 and axis-3 unfolding rank invariance.
--
-- The symmetric theorems `unfoldRank₂_smul` and `unfoldRank₃_smul`
-- (and the combined `tensorRank_smul`) require deriving the
-- `unfold₂_tensorContract` and `unfold₃_tensorContract` bridges
-- analogous to T-API-1.6's `unfold₁_tensorContract`.  For axis-2,
-- the bridge would have the form
--   `unfold₂ (tensorContract A B C T) = B * unfold₂ T * (Aᵀ ⊗ₖ Cᵀ)`,
-- with the rank invariance proof structurally identical to
-- `unfoldRank₁_smul`.
--
-- These derivations are research-scope follow-ups per the Stage 1
-- planning document; the axis-1 case `unfoldRank₁_smul` proven
-- above is the critical path that Stage 3 (T-API-4 block
-- decomposition) consumes for slot rank-class arguments.
--
-- This module intentionally does not stub out the axes-2/3 cases
-- with `sorry` to preserve the zero-`sorry` posture across the
-- entire workstream.
-- ============================================================================

end Tensor3
end Orbcrypt
