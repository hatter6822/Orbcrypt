/-
3-tensor matrix unfoldings (Stage 1 / T-API-1, R-TI rigidity discharge).

This module bridges `Tensor3 n F` (`Fin n → Fin n → Fin n → F`) to
matrices over `Fin n × (Fin n × Fin n)`, by "unfolding" the 3-tensor
along each of its three axes. The unfolding lets us cast the GL³
tensor action `tensorContract A B C T` into matrix products with
Kronecker products, which in turn enables the rank-invariance
results in `Orbcrypt/Hardness/GrochowQiao/RankInvariance.lean`
(T-API-2).

This is reusable Mathlib-quality infrastructure independent of the
Grochow–Qiao encoder; any future Orbcrypt content needing 3-tensor
unfoldings can import it.

See `docs/planning/R_TI_PHASE_C_THROUGH_H_PLAN.md` § Stage 1 for the
overall design.
-/

import Orbcrypt.Hardness.TensorAction
import Mathlib.LinearAlgebra.Matrix.Kronecker
import Mathlib.Data.Matrix.Basic

/-!
# 3-tensor matrix unfoldings

For a 3-tensor `T : Tensor3 n F`, this module defines three
matrix-valued **unfoldings** `unfold₁ T`, `unfold₂ T`, `unfold₃ T`
of type `Matrix (Fin n) (Fin n × Fin n) F`. Each unfolding fixes
one tensor axis as the row index and pairs the other two axes
lexicographically as the column index.

The key bridge to the GL³ action: applying `matMulTensor_k` to
axis `k` of the tensor corresponds to a specific matrix product
on the unfolding, mediated by the Kronecker product. Specifically:

* Axis-1 contraction acts as **left matrix multiplication** on `unfold₁ T`.
* Axis-2 / axis-3 contraction acts as **right multiplication** by a
  Kronecker product `(B ⊗ₖ 1)` / `(1 ⊗ₖ C)` on `unfold₁ T`.

Combined, the full GL³ contraction `tensorContract A B C T` becomes
`A * unfold₁ T * (B ⊗ₖ C)ᵀ` on `unfold₁`, with symmetric statements
for `unfold₂` and `unfold₃`.

## Public API

* `Tensor3.unfold₁`, `Tensor3.unfold₂`, `Tensor3.unfold₃` — the three matrix unfoldings.
* `unfold₁_inj` — distinct tensors give distinct unfoldings.
* `unfold₁_matMulTensor1`, `unfold₁_matMulTensor2`, `unfold₁_matMulTensor3` — single-axis bridges.
* `unfold₁_tensorContract` — combined GL³-action bridge.
* (Symmetric variants for `unfold₂` and `unfold₃`.)

## Naming

Identifiers describe content (`unfold₁`, `tensorContract`), not workstream provenance.
-/

namespace Orbcrypt
namespace Tensor3

open scoped Matrix
open scoped Kronecker
open Matrix

variable {n : ℕ} {F : Type*}

-- ============================================================================
-- T-API-1.1 — The three unfoldings.
-- ============================================================================

/-- **Axis-1 unfolding** of a 3-tensor.

The row index is the tensor's first axis; the column index is the
pair `(j, k)` of the second and third axes (lexicographically).

`unfold₁ T (i, (j, k)) = T i j k`. -/
def unfold₁ (T : Tensor3 n F) : Matrix (Fin n) (Fin n × Fin n) F :=
  fun i p => T i p.1 p.2

/-- **Axis-2 unfolding** of a 3-tensor.

The row index is the tensor's second axis; the column index is the
pair `(i, k)` of the first and third axes.

`unfold₂ T (j, (i, k)) = T i j k`. -/
def unfold₂ (T : Tensor3 n F) : Matrix (Fin n) (Fin n × Fin n) F :=
  fun j p => T p.1 j p.2

/-- **Axis-3 unfolding** of a 3-tensor.

The row index is the tensor's third axis; the column index is the
pair `(i, j)` of the first and second axes.

`unfold₃ T (k, (i, j)) = T i j k`. -/
def unfold₃ (T : Tensor3 n F) : Matrix (Fin n) (Fin n × Fin n) F :=
  fun k p => T p.1 p.2 k

-- ============================================================================
-- T-API-1.2 — Apply lemmas (definitional `@[simp]`).
-- ============================================================================

/-- `unfold₁ T i (j, k) = T i j k`, by definition. -/
@[simp] theorem unfold₁_apply (T : Tensor3 n F) (i j k : Fin n) :
    unfold₁ T i (j, k) = T i j k := rfl

/-- `unfold₂ T j (i, k) = T i j k`, by definition. -/
@[simp] theorem unfold₂_apply (T : Tensor3 n F) (i j k : Fin n) :
    unfold₂ T j (i, k) = T i j k := rfl

/-- `unfold₃ T k (i, j) = T i j k`, by definition. -/
@[simp] theorem unfold₃_apply (T : Tensor3 n F) (i j k : Fin n) :
    unfold₃ T k (i, j) = T i j k := rfl

-- ============================================================================
-- T-API-1.3 — Injectivity of unfoldings.
-- ============================================================================

/-- The axis-1 unfolding is injective: distinct tensors give distinct
unfoldings.  Direct from definitional equality. -/
theorem unfold₁_inj : Function.Injective (unfold₁ : Tensor3 n F → _) := by
  intro T₁ T₂ h
  funext i j k
  have := congrFun (congrFun h i) (j, k)
  simpa [unfold₁] using this

/-- The axis-2 unfolding is injective. -/
theorem unfold₂_inj : Function.Injective (unfold₂ : Tensor3 n F → _) := by
  intro T₁ T₂ h
  funext i j k
  have := congrFun (congrFun h j) (i, k)
  simpa [unfold₂] using this

/-- The axis-3 unfolding is injective. -/
theorem unfold₃_inj : Function.Injective (unfold₃ : Tensor3 n F → _) := by
  intro T₁ T₂ h
  funext i j k
  have := congrFun (congrFun h k) (i, j)
  simpa [unfold₃] using this

-- ============================================================================
-- T-API-1.4 — Single-axis matMulTensor bridges to matrix multiplication.
-- ============================================================================

variable [CommSemiring F]

/-- Axis-1 contraction `matMulTensor1 A T` corresponds to **left matrix
multiplication** `A * unfold₁ T` on the axis-1 unfolding.

`unfold₁ (matMulTensor1 A T) = A * unfold₁ T`.

*Proof:* unfold both sides at `(i, (j, k))`. LHS:
`(matMulTensor1 A T) i j k = ∑_a A i a * T a j k`. RHS:
`(A * unfold₁ T) i (j, k) = ∑_a A i a * unfold₁ T a (j, k) = ∑_a A i a * T a j k`. -/
theorem unfold₁_matMulTensor1 (A : Matrix (Fin n) (Fin n) F) (T : Tensor3 n F) :
    unfold₁ (matMulTensor1 A T) = A * unfold₁ T := by
  funext i ⟨j, k⟩
  simp only [unfold₁_apply, matMulTensor1, Matrix.mul_apply]

/-- Axis-2 contraction `matMulTensor2 B T` corresponds to **left matrix
multiplication** `B * unfold₂ T` on the axis-2 unfolding.

`unfold₂ (matMulTensor2 B T) = B * unfold₂ T`. -/
theorem unfold₂_matMulTensor2 (B : Matrix (Fin n) (Fin n) F) (T : Tensor3 n F) :
    unfold₂ (matMulTensor2 B T) = B * unfold₂ T := by
  funext j ⟨i, k⟩
  simp only [unfold₂_apply, matMulTensor2, Matrix.mul_apply]

/-- Axis-3 contraction `matMulTensor3 C T` corresponds to **left matrix
multiplication** `C * unfold₃ T` on the axis-3 unfolding.

`unfold₃ (matMulTensor3 C T) = C * unfold₃ T`. -/
theorem unfold₃_matMulTensor3 (C : Matrix (Fin n) (Fin n) F) (T : Tensor3 n F) :
    unfold₃ (matMulTensor3 C T) = C * unfold₃ T := by
  funext k ⟨i, j⟩
  simp only [unfold₃_apply, matMulTensor3, Matrix.mul_apply]

-- ============================================================================
-- T-API-1.5 — Cross-axis bridges via Kronecker products on `unfold₁`.
--
-- Axis-2 and axis-3 actions on `unfold₁ T` correspond to right matrix
-- multiplications by Kronecker products.  These bridges are what
-- T-API-2's GL³ rank-invariance proof consumes for the non-axis-1
-- factors.
-- ============================================================================

/-- Axis-2 contraction `matMulTensor2 B T` corresponds to **right matrix
multiplication** by `Bᵀ ⊗ₖ 1` on the axis-1 unfolding.

`unfold₁ (matMulTensor2 B T) = unfold₁ T * (Bᵀ ⊗ₖ 1)`.

*Proof.* Compute at coordinate `(i, (j, k))`. LHS:
`(matMulTensor2 B T) i j k = ∑_b B j b * T i b k`. RHS via Kronecker:
`(Bᵀ ⊗ₖ 1) (b, k') (j, k) = B j b * (if k' = k then 1 else 0)`.
After `Finset.sum_product`, the inner sum over `k'` collapses to the
single `k' = k` term, leaving `∑_b T i b k * B j b`, which equals the
LHS by commutativity. -/
theorem unfold₁_matMulTensor2 (B : Matrix (Fin n) (Fin n) F) (T : Tensor3 n F) :
    unfold₁ (matMulTensor2 B T) =
      unfold₁ T * (Bᵀ ⊗ₖ (1 : Matrix (Fin n) (Fin n) F)) := by
  funext i ⟨j, k⟩
  simp only [unfold₁_apply, matMulTensor2, Matrix.mul_apply]
  rw [Fintype.sum_prod_type]
  -- Goal: ∑_b B j b * T i b k = ∑_(b) ∑_(k') (unfold₁ T) i (b, k') * (Bᵀ ⊗ₖ 1) (b, k') (j, k).
  refine Finset.sum_congr rfl (fun b _ => ?_)
  rw [Finset.sum_eq_single k]
  · simp [Matrix.transpose_apply]; ring
  · intros k' _ h_ne
    simp [h_ne]
  · intro h; exact absurd (Finset.mem_univ _) h

/-- Axis-3 contraction `matMulTensor3 C T` corresponds to **right matrix
multiplication** by `1 ⊗ₖ Cᵀ` on the axis-1 unfolding.

`unfold₁ (matMulTensor3 C T) = unfold₁ T * (1 ⊗ₖ Cᵀ)`.

*Proof.* Symmetric to `unfold₁_matMulTensor2`. The axis-3 contraction
mixes the second column-index `k`, leaving the first column-index `j`
unchanged — hence the `1` (identity) factor on the first Kronecker
slot and the `Cᵀ` factor on the second. -/
theorem unfold₁_matMulTensor3 (C : Matrix (Fin n) (Fin n) F) (T : Tensor3 n F) :
    unfold₁ (matMulTensor3 C T) =
      unfold₁ T * ((1 : Matrix (Fin n) (Fin n) F) ⊗ₖ Cᵀ) := by
  funext i ⟨j, k⟩
  simp only [unfold₁_apply, matMulTensor3, Matrix.mul_apply]
  rw [Fintype.sum_prod_type]
  -- Switch the order of summation so the outer index is the surviving one (c).
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl (fun c _ => ?_)
  rw [Finset.sum_eq_single j]
  · simp [Matrix.transpose_apply]; ring
  · intros j' _ h_ne
    simp [h_ne]
  · intro h; exact absurd (Finset.mem_univ _) h

-- ============================================================================
-- T-API-1.6 — Combined GL³-action bridge.
-- ============================================================================

/-- The full GL³ contraction `tensorContract A B C T` corresponds, on the
axis-1 unfolding, to the matrix product `A * unfold₁ T * (Bᵀ ⊗ₖ Cᵀ)`.

`unfold₁ (tensorContract A B C T) = A * unfold₁ T * (Bᵀ ⊗ₖ Cᵀ)`.

*Proof.* Compose the three single-axis bridges (T-API-1.4 + T-API-1.5)
plus `mul_kronecker_mul` to combine the two right-multiplied Kronecker
factors into a single one. -/
theorem unfold₁_tensorContract (A B C : Matrix (Fin n) (Fin n) F) (T : Tensor3 n F) :
    unfold₁ (tensorContract A B C T) = A * unfold₁ T * (Bᵀ ⊗ₖ Cᵀ) := by
  unfold tensorContract
  rw [unfold₁_matMulTensor1, unfold₁_matMulTensor2, unfold₁_matMulTensor3]
  -- Goal: A * ((unfold₁ T * (1 ⊗ₖ Cᵀ)) * (Bᵀ ⊗ₖ 1)) = A * unfold₁ T * (Bᵀ ⊗ₖ Cᵀ)
  -- Combine the two Kronecker factors via mul_kronecker_mul.
  rw [Matrix.mul_assoc (unfold₁ T), ← Matrix.mul_kronecker_mul, Matrix.one_mul,
    Matrix.mul_one, ← Matrix.mul_assoc]

end Tensor3
end Orbcrypt
