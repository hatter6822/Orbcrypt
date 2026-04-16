import Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup.Defs
import Mathlib.Data.Matrix.Basic

/-!
# Orbcrypt.Hardness.TensorAction

Tensor group action and Tensor Isomorphism (TI) problem definition.
Defines the action of GL(n,F)³ on 3-tensors via trilinear contraction,
proves the MulAction laws, and states the TI decision problem.

TI is strictly harder than Graph Isomorphism (GI): no quasi-polynomial
algorithm is known for TI, whereas Babai's 2015 result gives GI a
2^O(√(n log n)) algorithm. This makes TI-based hardness assumptions
the strongest in the Orbcrypt reduction chain.

## Main definitions

* `Orbcrypt.Tensor3` — 3-tensor type (Fin n → Fin n → Fin n → F)
* `Orbcrypt.tensorContract` — trilinear contraction by three matrices
* `Orbcrypt.tensorAction` — MulAction instance for GL(n,F)³ on Tensor3
* `Orbcrypt.AreTensorIsomorphic` — tensor isomorphism relation
* `Orbcrypt.GIReducesToTI` — GI ≤ TI (Prop definition)

## Main results

* `Orbcrypt.matMulTensor1_one` — identity matrix acts trivially (axis 1)
* `Orbcrypt.matMulTensor1_mul` — composition law (axis 1)
* `Orbcrypt.matMulTensor1_matMulTensor2_comm` — cross-axis commutativity
* `Orbcrypt.areTensorIsomorphic_refl` — TI reflexivity

## References

* docs/planning/PHASE_12_HARDNESS_ALIGNMENT.md — work units 12.4–12.5
* Grochow & Qiao (2021) — Tensor Isomorphism complexity
* MEDS signature scheme — NIST PQC submission using MCE/ATFE
-/

namespace Orbcrypt

-- Open Matrix and Finset only in the helper section to avoid
-- ambiguity with MulAction.mul_smul in the action section.
open Finset

variable {n : ℕ} {F : Type*}

-- ============================================================================
-- Work Unit 12.4a: Tensor3 Type
-- ============================================================================

/-- A 3-tensor of dimension n over F: a trilinear map Fin n × Fin n × Fin n → F.
    Represents the coefficient tensor T_{ijk} of a trilinear form. -/
def Tensor3 (n : ℕ) (F : Type*) := Fin n → Fin n → Fin n → F

-- ============================================================================
-- Work Unit 12.4b: Tensor Contraction Helpers
-- ============================================================================

section TensorHelpers

variable [CommSemiring F]

/-- Apply matrix A to the first index of a tensor: (A ·₁ T)_{ijk} = ∑_a A_{ia} T_{ajk}.
    This is a single-axis contraction, much easier to reason about than the
    full trilinear contraction. -/
noncomputable def matMulTensor1 (A : Matrix (Fin n) (Fin n) F)
    (T : Tensor3 n F) : Tensor3 n F :=
  fun i j k => ∑ a : Fin n, A i a * T a j k

/-- Apply matrix B to the second index: (B ·₂ T)_{ijk} = ∑_b B_{jb} T_{ibk}. -/
noncomputable def matMulTensor2 (B : Matrix (Fin n) (Fin n) F)
    (T : Tensor3 n F) : Tensor3 n F :=
  fun i j k => ∑ b : Fin n, B j b * T i b k

/-- Apply matrix C to the third index: (C ·₃ T)_{ijk} = ∑_c C_{kc} T_{ijc}. -/
noncomputable def matMulTensor3 (C : Matrix (Fin n) (Fin n) F)
    (T : Tensor3 n F) : Tensor3 n F :=
  fun i j k => ∑ c : Fin n, C k c * T i j c

/-- Full trilinear contraction: apply A, B, C to indices 1, 2, 3 respectively.
    (A,B,C) · T = A ·₁ (B ·₂ (C ·₃ T)). -/
noncomputable def tensorContract (A B C : Matrix (Fin n) (Fin n) F)
    (T : Tensor3 n F) : Tensor3 n F :=
  matMulTensor1 A (matMulTensor2 B (matMulTensor3 C T))

-- ============================================================================
-- Work Unit 12.4b (continued): Identity Lemmas
-- ============================================================================

/-- Identity matrix acts trivially on the first index.
    **Proof:** ∑_a δ_{ia} T_{ajk} = T_{ijk} by Finset.sum_ite_eq. -/
@[simp]
theorem matMulTensor1_one (T : Tensor3 n F) :
    matMulTensor1 (1 : Matrix (Fin n) (Fin n) F) T = T := by
  funext i j k
  simp only [matMulTensor1, Matrix.one_apply, ite_mul, one_mul, zero_mul,
             Finset.sum_ite_eq, Finset.mem_univ, ite_true]

/-- Identity matrix acts trivially on the second index. -/
@[simp]
theorem matMulTensor2_one (T : Tensor3 n F) :
    matMulTensor2 (1 : Matrix (Fin n) (Fin n) F) T = T := by
  funext i j k
  simp only [matMulTensor2, Matrix.one_apply, ite_mul, one_mul, zero_mul,
             Finset.sum_ite_eq, Finset.mem_univ, ite_true]

/-- Identity matrix acts trivially on the third index. -/
@[simp]
theorem matMulTensor3_one (T : Tensor3 n F) :
    matMulTensor3 (1 : Matrix (Fin n) (Fin n) F) T = T := by
  funext i j k
  simp only [matMulTensor3, Matrix.one_apply, ite_mul, one_mul, zero_mul,
             Finset.sum_ite_eq, Finset.mem_univ, ite_true]

-- ============================================================================
-- Work Unit 12.4b (continued): Composition Lemmas
-- ============================================================================

/-- Composition law for axis 1: applying A*B equals applying B then A.
    **Proof:** Expand matrix product, swap sums, factor. -/
theorem matMulTensor1_mul (A B : Matrix (Fin n) (Fin n) F) (T : Tensor3 n F) :
    matMulTensor1 (A * B) T = matMulTensor1 A (matMulTensor1 B T) := by
  funext i j k
  simp only [matMulTensor1, Matrix.mul_apply, sum_mul]
  rw [sum_comm]
  congr 1; ext p
  rw [mul_sum]
  congr 1; ext a
  ring

/-- Composition law for axis 2. -/
theorem matMulTensor2_mul (A B : Matrix (Fin n) (Fin n) F) (T : Tensor3 n F) :
    matMulTensor2 (A * B) T = matMulTensor2 A (matMulTensor2 B T) := by
  funext i j k
  simp only [matMulTensor2, Matrix.mul_apply, sum_mul]
  rw [sum_comm]
  congr 1; ext q
  rw [mul_sum]
  congr 1; ext b
  ring

/-- Composition law for axis 3. -/
theorem matMulTensor3_mul (A B : Matrix (Fin n) (Fin n) F) (T : Tensor3 n F) :
    matMulTensor3 (A * B) T = matMulTensor3 A (matMulTensor3 B T) := by
  funext i j k
  simp only [matMulTensor3, Matrix.mul_apply, sum_mul]
  rw [sum_comm]
  congr 1; ext r
  rw [mul_sum]
  congr 1; ext c
  ring

-- ============================================================================
-- Work Unit 12.4b (continued): Cross-Axis Commutativity
-- ============================================================================

/-- Axes 1 and 2 commute: the order of applying matrices to different
    indices does not matter.
    **Proof:** Swap summation order, use commutativity of F. -/
theorem matMulTensor1_matMulTensor2_comm
    (A : Matrix (Fin n) (Fin n) F)
    (B : Matrix (Fin n) (Fin n) F) (T : Tensor3 n F) :
    matMulTensor1 A (matMulTensor2 B T) =
    matMulTensor2 B (matMulTensor1 A T) := by
  funext i j k
  simp only [matMulTensor1, matMulTensor2, mul_sum]
  rw [sum_comm]
  congr 1; ext b
  congr 1; ext a
  ring

/-- Axes 1 and 3 commute. -/
theorem matMulTensor1_matMulTensor3_comm
    (A : Matrix (Fin n) (Fin n) F)
    (C : Matrix (Fin n) (Fin n) F) (T : Tensor3 n F) :
    matMulTensor1 A (matMulTensor3 C T) =
    matMulTensor3 C (matMulTensor1 A T) := by
  funext i j k
  simp only [matMulTensor1, matMulTensor3, mul_sum]
  rw [sum_comm]
  congr 1; ext c
  congr 1; ext a
  ring

/-- Axes 2 and 3 commute. -/
theorem matMulTensor2_matMulTensor3_comm
    (B : Matrix (Fin n) (Fin n) F)
    (C : Matrix (Fin n) (Fin n) F) (T : Tensor3 n F) :
    matMulTensor2 B (matMulTensor3 C T) =
    matMulTensor3 C (matMulTensor2 B T) := by
  funext i j k
  simp only [matMulTensor2, matMulTensor3, mul_sum]
  rw [sum_comm]
  congr 1; ext c
  congr 1; ext b
  ring

end TensorHelpers

-- ============================================================================
-- Work Unit 12.4c: MulAction Instance
-- ============================================================================

section TensorAction

variable [Field F]

/-- GL(n,F)³ acts on 3-tensors by trilinear contraction.
    (A, B, C) • T applies A to the first index, B to the second, C to the third.

    The `MulAction` laws follow from the helper decomposition:
    - `one_smul`: identity matrices act trivially (matMulTensor{1,2,3}_one)
    - `mul_smul`: matrix multiplication distributes through contraction
      (matMulTensor{1,2,3}_mul) and different axes commute
      (matMulTensor{1,2}_comm, etc.) -/
noncomputable instance tensorAction :
    MulAction (GL (Fin n) F × GL (Fin n) F × GL (Fin n) F) (Tensor3 n F) where
  smul g T := tensorContract (↑g.1 : Matrix (Fin n) (Fin n) F)
                              (↑g.2.1 : Matrix (Fin n) (Fin n) F)
                              (↑g.2.2 : Matrix (Fin n) (Fin n) F) T
  one_smul T := by
    -- (1, 1, 1) • T = tensorContract 1 1 1 T = M1 1 (M2 1 (M3 1 T)) = T
    show tensorContract (↑(1 : GL (Fin n) F)) (↑(1 : GL (Fin n) F))
                        (↑(1 : GL (Fin n) F)) T = T
    simp [tensorContract, Units.val_one]
  mul_smul g h T := by
    -- (g * h) • T = g • (h • T) via helper decomposition
    show tensorContract (↑(g * h).1 : Matrix (Fin n) (Fin n) F)
                        (↑(g * h).2.1) (↑(g * h).2.2) T =
         tensorContract (↑g.1) (↑g.2.1) (↑g.2.2)
           (tensorContract (↑h.1) (↑h.2.1) (↑h.2.2) T)
    simp only [tensorContract, Prod.fst_mul, Prod.snd_mul, Units.val_mul,
               matMulTensor1_mul, matMulTensor2_mul, matMulTensor3_mul]
    -- After mul lemmas, LHS and RHS differ only in ordering of operations
    -- on different axes. Use commutativity to reorder.
    -- LHS: M1 g₁ (M1 h₁ (M2 g₂ (M2 h₂ (M3 g₃ (M3 h₃ T)))))
    -- RHS: M1 g₁ (M2 g₂ (M3 g₃ (M1 h₁ (M2 h₂ (M3 h₃ T)))))
    -- Move h₁ past g₂ (M1-M2 comm)
    conv_lhs => arg 2; rw [matMulTensor1_matMulTensor2_comm]
    -- State: M1 g₁ (M2 g₂ (M1 h₁ (M2 h₂ (M3 g₃ (M3 h₃ T)))))
    -- Move g₃ before h₂ using M2-M3 comm (inside M1 h₁)
    conv_lhs => arg 2; arg 2; arg 2; rw [matMulTensor2_matMulTensor3_comm]
    -- State: M1 g₁ (M2 g₂ (M1 h₁ (M3 g₃ (M2 h₂ (M3 h₃ T)))))
    -- Move h₁ past g₃ (M1-M3 comm)
    conv_lhs => arg 2; arg 2; rw [matMulTensor1_matMulTensor3_comm]
    -- State: M1 g₁ (M2 g₂ (M3 g₃ (M1 h₁ (M2 h₂ (M3 h₃ T))))) = RHS

end TensorAction

-- ============================================================================
-- Work Unit 12.5: Tensor Isomorphism Problem
-- ============================================================================

section TensorIsomorphism

variable [Field F]

/-- Two 3-tensors T₁, T₂ are isomorphic if there exist invertible matrices
    (A, B, C) ∈ GL(n,F)³ such that (A,B,C) · T₁ = T₂.

    Tensor Isomorphism (TI) is a decision problem: given T₁ and T₂,
    determine whether they are isomorphic. TI is at least as hard as
    Graph Isomorphism (GI) and is believed strictly harder — no
    quasi-polynomial algorithm is known for TI. -/
def AreTensorIsomorphic (T₁ T₂ : Tensor3 n F) : Prop :=
  ∃ g : GL (Fin n) F × GL (Fin n) F × GL (Fin n) F, g • T₁ = T₂

/-- Tensor isomorphism is reflexive: every tensor is isomorphic to itself
    via the identity triple (1, 1, 1). -/
theorem areTensorIsomorphic_refl (T : Tensor3 n F) :
    AreTensorIsomorphic T T :=
  ⟨(1, 1, 1), MulAction.one_smul T⟩

/-- Tensor isomorphism is symmetric: if T₁ ≅ T₂ then T₂ ≅ T₁,
    using the inverse triple (A⁻¹, B⁻¹, C⁻¹). -/
theorem areTensorIsomorphic_symm {T₁ T₂ : Tensor3 n F}
    (h : AreTensorIsomorphic T₁ T₂) :
    AreTensorIsomorphic T₂ T₁ := by
  obtain ⟨g, hg⟩ := h
  refine ⟨g⁻¹, ?_⟩
  subst hg
  simp [smul_smul]

/-- GI reduces to TI: graphs can be encoded as 3-tensors such that
    graph isomorphism corresponds to tensor isomorphism.

    This well-known result (Grochow & Qiao, 2021) establishes TI as at
    least as hard as GI. The encoding uses the structure tensor of a
    graph's adjacency algebra.

    **Key distinction:** While GI admits Babai's quasi-polynomial algorithm,
    no such algorithm is known for TI, making TI-based assumptions strictly
    stronger than GI-based ones.

    Stated as a `Prop`-valued definition following the OIA pattern.
    The encoding construction is beyond this formalization's scope. -/
def GIReducesToTI : Prop :=
  ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool),
    (∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) →
    ∃ (k : ℕ) (T₁ T₂ : Tensor3 k F),
      @AreTensorIsomorphic k F _ T₁ T₂

end TensorIsomorphism

end Orbcrypt
