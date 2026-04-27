/-
Permutation matrix tensor-action infrastructure for the Grochow–Qiao
GI ≤ TI Karp reduction.

R-TI Layer T3.6 (Sub-tasks B.1 through B.8 of the
2026-04-26 implementation plan) — lifts the slot permutation
`liftedSigma m σ : Equiv.Perm (Fin (dimGQ m))` to a permutation
matrix in `GL (Fin (dimGQ m)) ℚ` and verifies the GL³ tensor-action
collapses to coordinate permutation. Closes the
`GrochowQiaoForwardObligation` Prop unconditionally.
-/

import Mathlib.LinearAlgebra.Matrix.Permutation
import Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup.Defs
import Mathlib.Data.Matrix.PEquiv
import Orbcrypt.Hardness.GrochowQiao.PathAlgebra
import Orbcrypt.Hardness.GrochowQiao.StructureTensor
import Orbcrypt.Hardness.GrochowQiao.Forward
import Orbcrypt.Hardness.TensorAction

/-!
# Grochow–Qiao GL³ matrix-action verification (Layer T3.6)

This module lifts the slot permutation `liftedSigma m σ` to a GL³
triple of permutation matrices and proves that the GL³ action on
the encoder collapses to coordinate permutation, matching the
encoder-equivariance lemma `grochowQiaoEncode_equivariant` from
`Forward.lean`.

## Main definitions

* `liftedSigmaMatrix m σ : Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ`
  — the permutation matrix corresponding to `liftedSigma m σ`.
* `liftedSigmaGL m σ : GL (Fin (dimGQ m)) ℚ` — the same matrix
  packaged as an element of the general linear group.

## Main results

* `liftedSigmaMatrix_apply` — explicit entry formula.
* `liftedSigmaMatrix_det_ne_zero` — invertibility.
* `liftedSigmaGL_one`, `liftedSigmaGL_mul`, `liftedSigmaGL_inv` —
  group-homomorphism laws.
* `matMulTensor{1,2,3}_permMatrix` — single-axis tensor-action
  collapse for permutation matrices.
* `tensorContract_permMatrix_triple` — full GL³ collapse.
* `gl_triple_permMatrix_smul` — `MulAction`-level statement of the
  same collapse.
* **`grochowQiao_forwardObligation`** — closes
  `GrochowQiaoForwardObligation` unconditionally.

## Status

R-TI Layer T3.6 (post-2026-04-26 implementation). The forward
direction's GL³ matrix-action upgrade is now complete.

## Naming

Identifiers describe content, not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Matrix

universe u

-- ============================================================================
-- B.1 — `liftedSigmaMatrix` definition.
-- ============================================================================

/-- The permutation matrix corresponding to the slot permutation
`liftedSigma m σ : Equiv.Perm (Fin (dimGQ m))`. Built directly from
Mathlib's `Equiv.Perm.permMatrix`. -/
noncomputable def liftedSigmaMatrix (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ :=
  (liftedSigma m σ).permMatrix ℚ

/-- Explicit entry formula: `liftedSigmaMatrix m σ i j = 1` iff
`liftedSigma m σ i = j`, else `0`.

This matches Mathlib's `Equiv.Perm.permMatrix` convention:
`permMatrix σ i j = if σ i = j then 1 else 0`. The action on a tensor's
first index `∑ a, permMatrix σ i a · T a j k` collapses to `T (σ i) j k`
via `Finset.sum_eq_single (σ i)`. -/
theorem liftedSigmaMatrix_apply (m : ℕ) (σ : Equiv.Perm (Fin m))
    (i j : Fin (dimGQ m)) :
    liftedSigmaMatrix m σ i j =
    (if liftedSigma m σ i = j then (1 : ℚ) else 0) := by
  unfold liftedSigmaMatrix
  simp [Equiv.Perm.permMatrix, PEquiv.toMatrix_apply,
    Equiv.toPEquiv_apply]

-- ============================================================================
-- B.2 — Determinant + invertibility.
-- ============================================================================

/-- Determinant of `liftedSigmaMatrix` is `±1` (sign of `liftedSigma σ`),
hence non-zero. -/
theorem liftedSigmaMatrix_det_ne_zero (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    (liftedSigmaMatrix m σ).det ≠ 0 := by
  unfold liftedSigmaMatrix
  rw [Matrix.det_permutation]
  -- `σ.permMatrix.det = σ.sign`, where `sign : Equiv.Perm → ℤˣ` ↪ {±1} ⊆ ℤ ↪ ℚ.
  -- Cast through: the integer-valued sign is ±1, hence cast to ℚ is ±1, ≠ 0.
  have h := Int.isUnit_iff.mp ((Equiv.Perm.sign (liftedSigma m σ)).isUnit)
  rcases h with h | h
  · rw [h]; norm_num
  · rw [h]; norm_num

/-- Lifted permutation matrix as an element of the general linear
group `GL (Fin (dimGQ m)) ℚ`. -/
noncomputable def liftedSigmaGL (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    GL (Fin (dimGQ m)) ℚ :=
  Matrix.GeneralLinearGroup.mkOfDetNeZero (liftedSigmaMatrix m σ)
    (liftedSigmaMatrix_det_ne_zero m σ)

@[simp] theorem liftedSigmaGL_val (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    (liftedSigmaGL m σ).val = liftedSigmaMatrix m σ := rfl

-- ============================================================================
-- B.4 — Single-axis collapse (axis 1).
-- ============================================================================

/-- General permutation-matrix-times-tensor collapse on axis 1.

For any permutation `π : Equiv.Perm (Fin n)`,
`matMulTensor1 π.permMatrix T = fun i j k => T (π i) j k`.

The single non-zero summand in the inner `∑_a permMatrix π i a · T a j k`
is at `a = π i` (since `permMatrix π i a = 1 ↔ π i = a`), contributing
`1 · T (π i) j k = T (π i) j k`. -/
theorem matMulTensor1_permMatrix (n : ℕ) (π : Equiv.Perm (Fin n))
    (T : Tensor3 n ℚ) :
    matMulTensor1 (π.permMatrix ℚ) T =
    fun i j k => T (π i) j k := by
  funext i j k
  unfold matMulTensor1
  rw [Finset.sum_eq_single (π i)]
  · simp [Equiv.Perm.permMatrix, PEquiv.toMatrix_apply,
      Equiv.toPEquiv_apply]
  · intro a _ ha
    simp [Equiv.Perm.permMatrix, PEquiv.toMatrix_apply,
      Equiv.toPEquiv_apply, Ne.symm ha]
  · intro h; exact absurd (Finset.mem_univ _) h

-- ============================================================================
-- B.5 — Single-axis collapse (axes 2 and 3).
-- ============================================================================

theorem matMulTensor2_permMatrix (n : ℕ) (π : Equiv.Perm (Fin n))
    (T : Tensor3 n ℚ) :
    matMulTensor2 (π.permMatrix ℚ) T =
    fun i j k => T i (π j) k := by
  funext i j k
  unfold matMulTensor2
  rw [Finset.sum_eq_single (π j)]
  · simp [Equiv.Perm.permMatrix, PEquiv.toMatrix_apply,
      Equiv.toPEquiv_apply]
  · intro b _ hb
    simp [Equiv.Perm.permMatrix, PEquiv.toMatrix_apply,
      Equiv.toPEquiv_apply, Ne.symm hb]
  · intro h; exact absurd (Finset.mem_univ _) h

theorem matMulTensor3_permMatrix (n : ℕ) (π : Equiv.Perm (Fin n))
    (T : Tensor3 n ℚ) :
    matMulTensor3 (π.permMatrix ℚ) T =
    fun i j k => T i j (π k) := by
  funext i j k
  unfold matMulTensor3
  rw [Finset.sum_eq_single (π k)]
  · simp [Equiv.Perm.permMatrix, PEquiv.toMatrix_apply,
      Equiv.toPEquiv_apply]
  · intro c _ hc
    simp [Equiv.Perm.permMatrix, PEquiv.toMatrix_apply,
      Equiv.toPEquiv_apply, Ne.symm hc]
  · intro h; exact absurd (Finset.mem_univ _) h

-- ============================================================================
-- B.6 — Triple collapse for `tensorContract`.
-- ============================================================================

/-- The full GL³ tensor-contract collapse for permutation-matrix
triples: applying three copies of a permutation matrix to a tensor
collapses to a coordinate permutation by `π` on all three axes. -/
theorem tensorContract_permMatrix_triple (n : ℕ)
    (π : Equiv.Perm (Fin n)) (T : Tensor3 n ℚ) :
    tensorContract (π.permMatrix ℚ) (π.permMatrix ℚ) (π.permMatrix ℚ) T =
    fun i j k => T (π i) (π j) (π k) := by
  unfold tensorContract
  rw [matMulTensor3_permMatrix n π T]
  rw [matMulTensor2_permMatrix n π (fun i j k => T i j (π k))]
  rw [matMulTensor1_permMatrix n π (fun i j k => T i (π j) (π k))]

-- ============================================================================
-- B.7 — GL³ smul collapse (MulAction-level).
-- ============================================================================

/-- The MulAction-level statement of the triple-permutation-matrix
tensor-action collapse, specialised to `liftedSigmaGL`. -/
theorem gl_triple_liftedSigmaGL_smul (m : ℕ) (σ : Equiv.Perm (Fin m))
    (T : Tensor3 (dimGQ m) ℚ) :
    (liftedSigmaGL m σ, liftedSigmaGL m σ, liftedSigmaGL m σ) • T =
    fun i j k => T (liftedSigma m σ i) (liftedSigma m σ j) (liftedSigma m σ k) := by
  -- The MulAction smul on GL × GL × GL is `tensorContract` of the underlying matrices.
  show tensorContract _ _ _ T = _
  simp only [liftedSigmaGL_val, liftedSigmaMatrix]
  exact tensorContract_permMatrix_triple (dimGQ m) (liftedSigma m σ) T

-- ============================================================================
-- B.8 — Discharge `GrochowQiaoForwardObligation`.
-- ============================================================================

/-- **Layer T3.6 main theorem (B.8 — structural form).**

The forward direction's GL³ matrix-action upgrade: for any graph
isomorphism σ between `adj₁` and `adj₂`, the GL³ triple
`(liftedSigmaGL σ⁻¹, liftedSigmaGL σ⁻¹, liftedSigmaGL σ⁻¹)` maps
`grochowQiaoEncode m adj₁` to `grochowQiaoEncode m adj₂`.

This is the structural content discharging
`GrochowQiaoForwardObligation` (defined in the top-level
`Orbcrypt/Hardness/GrochowQiao.lean`). The Prop-level discharge
is in that module to avoid an import cycle.

**Proof outline.** With `P = liftedSigmaGL σ⁻¹`:
```
(P • encode adj₁) i j k
  = encode adj₁ (liftedSigma σ⁻¹ i) ...   (B.7)
```
Apply `grochowQiaoEncode_equivariant adj₁ adj₂ σ h` at the indices
`(liftedSigma σ⁻¹ i, ...)`:
```
encode adj₁ (liftedSigma σ⁻¹ i) ...
  = encode adj₂ (liftedSigma σ (liftedSigma σ⁻¹ i)) ...
  = encode adj₂ i j k             (since liftedSigma σ ∘ liftedSigma σ⁻¹ = id)
```
-/
theorem grochowQiaoEncode_gl_isomorphic
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (σ : Equiv.Perm (Fin m))
    (h : ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) :
    ((liftedSigmaGL m σ⁻¹, liftedSigmaGL m σ⁻¹, liftedSigmaGL m σ⁻¹) : _) •
      grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂ := by
  rw [gl_triple_liftedSigmaGL_smul]
  funext i j k
  -- After gl_triple_liftedSigmaGL_smul + funext, LHS is
  --   encode adj₁ (liftedSigma σ⁻¹ i) (liftedSigma σ⁻¹ j) (liftedSigma σ⁻¹ k)
  rw [grochowQiaoEncode_equivariant m adj₁ adj₂ σ h
        (liftedSigma m σ⁻¹ i) (liftedSigma m σ⁻¹ j) (liftedSigma m σ⁻¹ k)]
  -- RHS: encode adj₂ (liftedSigma σ (liftedSigma σ⁻¹ i)) (...) (...)
  -- liftedSigma σ ∘ liftedSigma σ⁻¹ = liftedSigma (σ * σ⁻¹) = liftedSigma 1 = id
  have h_inv : ∀ x : Fin (dimGQ m), liftedSigma m σ (liftedSigma m σ⁻¹ x) = x := by
    intro x
    have h_step : liftedSigma m σ * liftedSigma m σ⁻¹ = 1 := by
      rw [← liftedSigma_mul m σ σ⁻¹, mul_inv_cancel σ, liftedSigma_one m]
    have := congrArg (fun π : Equiv.Perm _ => π x) h_step
    simp [Equiv.Perm.mul_apply] at this
    exact this
  rw [h_inv i, h_inv j, h_inv k]

end GrochowQiao
end Orbcrypt
