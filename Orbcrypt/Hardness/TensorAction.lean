import Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup.Defs
import Mathlib.Data.Matrix.Basic
import Orbcrypt.Probability.Monad
import Orbcrypt.Probability.Advantage

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

-- Module-level universe variable. Used below by `SurrogateTensor F`'s
-- `carrier : Type u` field and propagated to every downstream Prop /
-- structure that consumes the surrogate (audit 2026-04-21 finding L1 /
-- Workstream M1).
universe u

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

    A many-one (Karp) reduction: there exists a uniform encoding function
    mapping graphs to 3-tensors such that graph isomorphism holds if and only
    if the encoded tensors are GL³-isomorphic. The encoding uses the structure
    tensor of a graph's adjacency algebra (Grochow & Qiao, 2021).

    **Key distinction:** While GI admits Babai's quasi-polynomial algorithm,
    no such algorithm is known for TI, making TI-based assumptions strictly
    stronger than GI-based ones.

    Stated as a `Prop`-valued definition following the OIA pattern.
    The encoding construction is beyond this formalization's scope.

    **Audit note (F-12 / 2026-04-21 H1 follow-up).** This definition is
    the deterministic Karp-claim Prop paired with the probabilistic
    `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding` (Workstream G /
    Fix C) in `Hardness/Reductions.lean`. A concrete witness via the
    Grochow–Qiao structure-tensor encoding (2021) would discharge both
    the deterministic claim and the per-encoding Prop simultaneously;
    it is a research-scope follow-up
    (`docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 15.1). Listed
    in the root-file "Hardness parameter Props" section for transparency.

    **Degenerate-encoder disclosure (audit 2026-04-21 finding L4 /
    Workstream M).** Like `GIReducesToCE`, this Prop states the
    reduction at the *orbit-equivalence level* rather than the
    advantage level, and therefore admits degenerate encoders (e.g. a
    constant map `encode _ _ := fun _ _ _ => 0` into a 0-dimensional
    tensor space). This is by design: `GIReducesToTI` is an
    *algebraic-scaffolding* Prop expressing the *existence* of a Karp
    reduction, not a bound-preserving advantage transfer. Quantitative
    hardness transfer lives in the probabilistic counterpart
    `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding` (which names an
    explicit encoder and a per-layer ε), *not* in this Prop. Cite the
    probabilistic per-encoding Prop for release-facing security
    claims. -/
def GIReducesToTI : Prop :=
  ∃ (dim : ℕ → ℕ)
    (encode : (m : ℕ) → (Fin m → Fin m → Bool) → Tensor3 (dim m) F),
    ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool),
      (∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) ↔
      @AreTensorIsomorphic (dim m) F _ (encode m adj₁) (encode m adj₂)

end TensorIsomorphism

-- ============================================================================
-- Workstream E2b — `ConcreteTensorOIA`: probabilistic Tensor-Isomorphism OIA
-- ============================================================================

section ConcreteTensor

-- `[Field F]` is *not* required here: `Tensor3 n F` is a plain function
-- type (`Fin n → Fin n → Fin n → F`) with no ring structure, and
-- `PMF.map`/`advantage` depend only on the surrogate group `G_TI`. The
-- outer `AreTensorIsomorphic` content does need `[Field F]` for `GL³`;
-- scoping the requirement out of this section keeps the probabilistic
-- sub-language constraint-minimal.

/-- Orbit distribution on tensors under a finite group action. Parameterised
    over an arbitrary `Fintype` group `G_TI` acting on `Tensor3 n F`, so the
    definition is usable with any concrete surrogate for GL(n,F)³.

    **Why abstract over `G_TI`.** The natural target group is
    `(GL (Fin n) F) × (GL (Fin n) F) × (GL (Fin n) F)` (see `tensorAction`
    above), but Mathlib does not currently provide a `Fintype` instance for
    `GL (Fin n) F` even when `F` is finite. Abstracting over `G_TI` lets
    this workstream land without blocking on that upstream instance;
    post-Workstream-G, callers supply a specific `G_TI` via
    `SurrogateTensor F` (Fix B). Discharging the surrogate with the
    concrete `tensorAction` once `Fintype (GL (Fin n) F)` lands is a
    research-scope follow-up
    (`docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 15.1). -/
noncomputable def tensorOrbitDist
    {G_TI : Type*} [Group G_TI] [Fintype G_TI] [Nonempty G_TI]
    [MulAction G_TI (Tensor3 n F)]
    (T : Tensor3 n F) : PMF (Tensor3 n F) :=
  PMF.map (fun g : G_TI => g • T) (uniformPMF G_TI)

/-- **Probabilistic Tensor-Isomorphism OIA** with explicit advantage bound
    `ε`. Every Boolean distinguisher on `Tensor3 n F` has advantage at most
    `ε` between the orbit distributions of two candidate tensors `T₀, T₁`
    under the action of any specified finite group `G_TI`.

    **Strength.** Mirrors `ConcreteOIA` / `ConcreteCEOIA`: `ε = 1` is
    trivially satisfied (see `concreteTensorOIA_one`), smaller ε
    parameterises the MEDS/ATFE-style concrete security target. -/
def ConcreteTensorOIA
    {G_TI : Type*} [Group G_TI] [Fintype G_TI] [Nonempty G_TI]
    [MulAction G_TI (Tensor3 n F)]
    (T₀ T₁ : Tensor3 n F) (ε : ℝ) : Prop :=
  ∀ (D : Tensor3 n F → Bool),
    advantage D (tensorOrbitDist (G_TI := G_TI) T₀)
      (tensorOrbitDist (G_TI := G_TI) T₁) ≤ ε

/-- `ConcreteTensorOIA` with `ε = 1` is trivially satisfied. -/
theorem concreteTensorOIA_one
    {G_TI : Type*} [Group G_TI] [Fintype G_TI] [Nonempty G_TI]
    [MulAction G_TI (Tensor3 n F)]
    (T₀ T₁ : Tensor3 n F) :
    ConcreteTensorOIA (G_TI := G_TI) T₀ T₁ 1 :=
  fun D => advantage_le_one D _ _

/-- `ConcreteTensorOIA` is monotone in the bound. -/
theorem concreteTensorOIA_mono
    {G_TI : Type*} [Group G_TI] [Fintype G_TI] [Nonempty G_TI]
    [MulAction G_TI (Tensor3 n F)]
    (T₀ T₁ : Tensor3 n F) {ε₁ ε₂ : ℝ}
    (hle : ε₁ ≤ ε₂) (hOIA : ConcreteTensorOIA (G_TI := G_TI) T₀ T₁ ε₁) :
    ConcreteTensorOIA (G_TI := G_TI) T₀ T₁ ε₂ :=
  fun D => le_trans (hOIA D) hle

end ConcreteTensor

-- ============================================================================
-- Workstream G (audit 2026-04-21, finding H1) — `SurrogateTensor F` structure
-- ============================================================================

/-- **Tensor-action surrogate.** Bundles a cryptographically meaningful
    group-and-action pair used as the tensor-layer surrogate in
    `UniversalConcreteTensorOIA` and `ConcreteHardnessChain`.

    **Motivation (audit F-AUDIT-2026-04-21-H1).** Prior to Workstream G,
    the universal tensor-hardness predicate
    `UniversalConcreteTensorOIA εT` implicitly quantified over every
    `G_TI : Type` equipped with `Group`, `Fintype`, `Nonempty`, and a
    `MulAction` on `Tensor3 n F`. That universal quantifier was satisfied
    by `G_TI := PUnit` with the trivial `MulAction`, under which the
    orbit distribution collapses to a point mass admitting advantage-1
    distinguishers. Consequently any claim of the form "tensor hardness
    at εT < 1 holds for all instances" was provably false, and every
    reduction Prop threading through `UniversalConcreteTensorOIA` became
    vacuous. The chain still inhabited at ε = 1 (trivial bound), but no
    intermediate ε carried quantitative content.

    **Fix (Workstream G, Fix B).** The surrogate binds `G_TI` to a
    *specific* finite group chosen by the caller. `SurrogateTensor F`
    packages the four typeclass obligations plus the per-dimension
    `MulAction`; downstream Props and structures take
    `S : SurrogateTensor F` as a named parameter rather than implicitly
    quantifying over every possible instance.

    **Cryptographic interpretation.** A *production* surrogate is a
    finite subgroup witness for GL³(F) (or the full GL³(F) once Mathlib
    provides `Fintype (GL (Fin n) F)`). A *trivial* surrogate is
    `PUnit`; choosing `PUnit` is explicit at the call site and makes
    the chain's ε bound reflect the (trivial) hardness of that
    surrogate, not an accidental quantifier collapse.

    **Field structure.** `carrier` is the group type; `action` provides
    the per-dimension MulAction; `groupInst` / `fintypeInst` /
    `nonemptyInst` carry the three required typeclass instances. Lean
    4's structure syntax does *not* support instance-field angle
    brackets at declaration time, so the three instances are exposed as
    regular fields here and re-registered via the four top-level
    `instance` declarations below (`surrogateTensor_group`,
    `surrogateTensor_fintype`, `surrogateTensor_nonempty`,
    `surrogateTensor_mulAction`). Downstream defs referencing
    `S.carrier` or `Tensor3 n F` pick up the instances automatically
    via typeclass inference — no manual `letI` threading is required.

    **Universe polymorphism (audit 2026-04-21 finding L1 / Workstream M1).**
    `carrier` is declared as `Type u` (where `u` is the module-level
    universe variable, see `universe u` at the top of the module).
    Pre-Workstream-M, the field was fixed at `Type` (universe 0);
    post-Workstream-G, downstream `MulAction`-consuming Props already
    quantified over `Type*`, so binding the carrier to a specific
    universe level served no purpose. The generalisation lets callers
    supply finite groups inhabiting any universe (e.g. an index-type
    coming from `Fin m` lives in `Type 0`, while a subgroup of a
    matrix group over a universe-polymorphic field may land in
    `Type u`). `punitSurrogate F` still discharges non-vacuity
    because `PUnit` is itself universe-polymorphic
    (`PUnit.{u+1} : Type u`). -/
structure SurrogateTensor (F : Type*) where
  /-- The underlying group carrier. Universe-polymorphic (audit L1 /
      Workstream M1). -/
  carrier : Type u
  /-- `Group` instance on the carrier. -/
  groupInst : Group carrier
  /-- `Fintype` instance on the carrier. -/
  fintypeInst : Fintype carrier
  /-- `Nonempty` instance on the carrier. -/
  nonemptyInst : Nonempty carrier
  /-- `MulAction` on `Tensor3 n F` for every dimension `n`. -/
  action : ∀ n : ℕ, MulAction carrier (Tensor3 n F)

/-- Register the surrogate's `Group` field as a typeclass instance on
    its carrier, so downstream defs referencing `S.carrier` pick up
    the bundled structure without manual `letI` threading. -/
instance surrogateTensor_group {F : Type*} (S : SurrogateTensor F) :
    Group S.carrier := S.groupInst

/-- Register the surrogate's `Fintype` field as a typeclass instance. -/
instance surrogateTensor_fintype {F : Type*} (S : SurrogateTensor F) :
    Fintype S.carrier := S.fintypeInst

/-- Register the surrogate's `Nonempty` field as a typeclass instance. -/
instance surrogateTensor_nonempty {F : Type*} (S : SurrogateTensor F) :
    Nonempty S.carrier := S.nonemptyInst

/-- Register the surrogate's per-dimension `MulAction` as a typeclass
    instance. The dimension `n` is a regular parameter, so this is a
    dependent instance that fires once `n` is known. -/
instance surrogateTensor_mulAction {F : Type*} (S : SurrogateTensor F)
    (n : ℕ) : MulAction S.carrier (Tensor3 n F) := S.action n

/-- **Trivial PUnit surrogate.** The one-element group acting trivially
    on every `Tensor3 n F`. Used as the canonical non-vacuity witness
    at ε = 1 in `ConcreteHardnessChain.tight_one_exists`.

    **Why PUnit.** The audit finding H1 (cf. docstring of
    `SurrogateTensor`) showed that `PUnit` previously caused the
    universal tensor-hardness Prop to collapse. After Fix B, using
    `PUnit` as the surrogate is an *explicit caller choice* — it
    simply declares that the chain's hardness input is trivial, which
    is the correct cryptographic reading.

    **Universe choice (audit 2026-04-21 finding L1 / Workstream M1).**
    Post-M1, `SurrogateTensor.{u}` is universe-polymorphic in the
    carrier universe `u`. `punitSurrogate` fixes `u := 0` by returning
    `SurrogateTensor.{0} F` with `carrier := PUnit` (which elaborates
    to `PUnit.{1} : Type 0`). This matches every in-tree non-vacuity
    use site, which works at `Type 0` because the scheme side
    (`OrbitEncScheme G X M`) quantifies `G, X, M` at independent
    universes. Callers wanting a surrogate at a higher universe
    supply their own `SurrogateTensor.{v} F` value. -/
def punitSurrogate (F : Type*) : SurrogateTensor.{0} F where
  carrier := PUnit
  groupInst := inferInstance
  fintypeInst := inferInstance
  nonemptyInst := inferInstance
  action := fun _ =>
    { smul := fun _ T => T
      one_smul := fun _ => rfl
      mul_smul := fun _ _ _ => rfl }

end Orbcrypt
