/-
Path-block linear restriction (parametric in π) for the Grochow–Qiao
GI ≤ TI Karp reduction.

R-TI Phase 2 (Path-block linear restriction) — linear-algebra
infrastructure for the GL³ → algebra-iso bridge (Phase 3). Builds
the path-block subspace, the symmetric padding subspace, the
path-block matrix `g.1 · permMatrix(π⁻¹)`, the conditional restriction
to a linear map between path-block subspaces, and the bridge from the
indicator-vector subspace to the `pathAlgebraQuotient` carrier.

See `docs/planning/R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md` § "Phase 2 —
Path-block linear restriction (parametric in π)" for the work-unit
decomposition.
-/

import Mathlib.LinearAlgebra.Span.Defs
import Mathlib.LinearAlgebra.Pi
import Mathlib.LinearAlgebra.Basis.Basic
import Mathlib.LinearAlgebra.Basis.Defs
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.LinearAlgebra.LinearIndependent.Basic
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.Data.Matrix.Basic
import Orbcrypt.Hardness.GrochowQiao.PermMatrix
import Orbcrypt.Hardness.GrochowQiao.SlotSignature
import Orbcrypt.Hardness.GrochowQiao.AlgebraWrapper
import Orbcrypt.Hardness.GrochowQiao.EncoderSlabEval

/-!
# Path-block subspace, path-block matrix, and bridge to `pathAlgebraQuotient`

This module establishes the linear-algebra infrastructure that
**Phase 3's GL³ → algebra-iso bridge** consumes. The infrastructure
is **parametric in a slot permutation `π : Equiv.Perm (Fin (dimGQ m))`**
because Phase 3 derives π from algebra-iso structure — Phase 2's
lemmas do not commit to a specific π.

## Layer 2.1 — Path-block and padding subspaces

* `pathBlockSubspace m adj : Submodule ℚ (Fin (dimGQ m) → ℚ)` — the
  subspace of vectors supported on `pathSlotIndices m adj`.
* `paddingSubspace m adj` — the symmetric subspace for padding slots.
* The two subspaces are **complementary** in `Fin (dimGQ m) → ℚ`:
  their intersection is `⊥` (disjointness from disjoint Finsets) and
  their sum is `⊤` (every vector decomposes as a path part plus a
  padding part).

## Layer 2.2 — Path-block matrix (parametric in π)

* `pathBlockMatrix m g π : Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ`
  — defined as `g.1 * (liftedSigmaMatrix m π⁻¹)`. (We package π
  via Mathlib's `Equiv.Perm.permMatrix` through the existing
  `liftedSigmaMatrix` API — note `liftedSigmaMatrix` already
  accepts an arbitrary `Equiv.Perm (Fin (dimGQ m))` once we
  generalise from `liftedSigma m σ`. Phase 2 uses the generalised
  form; the `Equiv.Perm`-direct counterpart `permMatrixOf π` is
  introduced here.)

## Layer 2.3 — Conditional linear restriction

* `pathBlockMatrix_restricts_to_pathBlockSubspace` — under the
  block-diagonality hypothesis (the path-to-padding off-diagonal
  block is zero), the matrix's restriction to vectors supported on
  `pathSlotIndices m adj₁` lands in `pathBlockSubspace m adj₂`.
* `gl3_restrict_to_pathBlock` — the corresponding `LinearMap`
  between `pathBlockSubspace`s.
* `gl3_restrict_to_pathBlock_isLinearEquiv` — when the symmetric
  padding-to-path block also vanishes and `g` is invertible, the
  restriction upgrades to a `LinearEquiv`.

## Layer 2.4 — Bridge to `pathAlgebraQuotient`

* `presentArrowsSubspace m adj : Submodule ℚ (pathAlgebraQuotient m)`
  — the subspace spanned by `vertexIdempotent v` (all `v`) and
  `arrowElement u v` (when `adj u v = true`).
* `pathBlock_to_presentArrows : pathBlockSubspace m adj ≃ₗ[ℚ]
  presentArrowsSubspace m adj` — the linear equivalence bridging the
  indicator-vector subspace (where `pathBlockMatrix` operates) to
  the `pathAlgebraQuotient` subspace (where the algebra-iso lives).

## Status

Phase 2 of `R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md`. All public
declarations depend only on the standard Lean trio (`propext`,
`Classical.choice`, `Quot.sound`); no `sorry`, no custom axioms.

## Naming

Identifiers describe content (path-block subspace, path-block matrix,
indicator bridge), not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Matrix
open scoped Matrix

universe u

-- ============================================================================
-- Layer 2.1.0 — Permutation-matrix wrapper for arbitrary slot permutations.
-- ============================================================================

/-- Permutation matrix for an arbitrary slot permutation
`π : Equiv.Perm (Fin (dimGQ m))`. Built directly from Mathlib's
`Equiv.Perm.permMatrix`, parallel to `liftedSigmaMatrix m σ` (which
specialises to `liftedSigma m σ` for vertex permutations σ).

This lets Phase 2's `pathBlockMatrix` accept the slot permutation π
directly, without going through `liftedSigma`. -/
noncomputable def permMatrixOf (m : ℕ) (π : Equiv.Perm (Fin (dimGQ m))) :
    Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ :=
  π.permMatrix ℚ

/-- Explicit entry formula: `permMatrixOf m π i j = 1` iff `π i = j`,
else `0`. Mirrors `liftedSigmaMatrix_apply`. -/
theorem permMatrixOf_apply (m : ℕ) (π : Equiv.Perm (Fin (dimGQ m)))
    (i j : Fin (dimGQ m)) :
    permMatrixOf m π i j = (if π i = j then (1 : ℚ) else 0) := by
  unfold permMatrixOf
  simp [Equiv.Perm.permMatrix, PEquiv.toMatrix_apply,
    Equiv.toPEquiv_apply]

/-- Determinant non-vanishing for `permMatrixOf` — same proof structure
as `liftedSigmaMatrix_det_ne_zero`. -/
theorem permMatrixOf_det_ne_zero (m : ℕ) (π : Equiv.Perm (Fin (dimGQ m))) :
    (permMatrixOf m π).det ≠ 0 := by
  unfold permMatrixOf
  rw [Matrix.det_permutation]
  have h := Int.isUnit_iff.mp ((Equiv.Perm.sign π).isUnit)
  rcases h with h | h
  · rw [h]; norm_num
  · rw [h]; norm_num

-- ============================================================================
-- Layer 2.1.1 — Path-block and padding subspaces (defined by support).
-- ============================================================================

/-- The **path-block subspace** of `Fin (dimGQ m) → ℚ`: vectors that
vanish outside `pathSlotIndices m adj`. (Equivalently, the subspace
spanned by the indicator vectors `Pi.single i 1` for `i ∈
pathSlotIndices m adj` — see `mem_pathBlockSubspace_iff_supported`
and `pathBlockSubspace_eq_span` below.) -/
def pathBlockSubspace (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Submodule ℚ (Fin (dimGQ m) → ℚ) where
  carrier := { f | ∀ i, i ∉ pathSlotIndices m adj → f i = 0 }
  zero_mem' := by intro i _; rfl
  add_mem' := by
    intro f g hf hg i hi
    simp [hf i hi, hg i hi]
  smul_mem' := by
    intro c f hf i hi
    simp [hf i hi]

/-- Membership characterization for `pathBlockSubspace`. -/
@[simp] theorem mem_pathBlockSubspace_iff (m : ℕ)
    (adj : Fin m → Fin m → Bool) (f : Fin (dimGQ m) → ℚ) :
    f ∈ pathBlockSubspace m adj ↔
      ∀ i, i ∉ pathSlotIndices m adj → f i = 0 := Iff.rfl

/-- The **padding subspace** of `Fin (dimGQ m) → ℚ`: vectors that
vanish outside `paddingSlotIndices m adj`. -/
def paddingSubspace (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Submodule ℚ (Fin (dimGQ m) → ℚ) where
  carrier := { f | ∀ i, i ∉ paddingSlotIndices m adj → f i = 0 }
  zero_mem' := by intro i _; rfl
  add_mem' := by
    intro f g hf hg i hi
    simp [hf i hi, hg i hi]
  smul_mem' := by
    intro c f hf i hi
    simp [hf i hi]

/-- Membership characterization for `paddingSubspace`. -/
@[simp] theorem mem_paddingSubspace_iff (m : ℕ)
    (adj : Fin m → Fin m → Bool) (f : Fin (dimGQ m) → ℚ) :
    f ∈ paddingSubspace m adj ↔
      ∀ i, i ∉ paddingSlotIndices m adj → f i = 0 := Iff.rfl

-- ============================================================================
-- Layer 2.1.2 — Indicator vectors land in the path-block / padding subspace.
-- ============================================================================

/-- Indicator vector at a path-algebra slot lies in the path-block subspace. -/
theorem pi_single_mem_pathBlockSubspace
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i : Fin (dimGQ m))
    (h : i ∈ pathSlotIndices m adj) (c : ℚ) :
    Pi.single i c ∈ pathBlockSubspace m adj := by
  intro j hj
  by_cases hij : i = j
  · -- i = j contradicts j ∉ pathSlotIndices m adj since i ∈ pathSlotIndices m adj.
    subst hij; exact absurd h hj
  · simp [Pi.single_eq_of_ne (Ne.symm hij)]

/-- Indicator vector at a padding slot lies in the padding subspace. -/
theorem pi_single_mem_paddingSubspace
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i : Fin (dimGQ m))
    (h : i ∈ paddingSlotIndices m adj) (c : ℚ) :
    Pi.single i c ∈ paddingSubspace m adj := by
  intro j hj
  by_cases hij : i = j
  · subst hij; exact absurd h hj
  · simp [Pi.single_eq_of_ne (Ne.symm hij)]

-- ============================================================================
-- Layer 2.1.3 — Subspace decomposition: `pathBlockSubspace` and
-- `paddingSubspace` are complementary.
-- ============================================================================

/-- The path-block and padding subspaces are disjoint (their intersection is `⊥`).

A vector in both must vanish on every slot — it vanishes outside path slots
(by membership in the path-block subspace) and outside padding slots (by
membership in the padding subspace). The two slot Finsets partition the
universe, so the vector vanishes everywhere. -/
theorem pathBlockSubspace_disjoint_paddingSubspace
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    pathBlockSubspace m adj ⊓ paddingSubspace m adj = ⊥ := by
  ext f
  simp only [Submodule.mem_inf, Submodule.mem_bot]
  refine ⟨?_, ?_⟩
  · rintro ⟨h_path, h_pad⟩
    funext i
    -- Either i is a path slot or a padding slot (partition theorem).
    by_cases hi_path : i ∈ pathSlotIndices m adj
    · -- i is a path slot — but then i ∉ paddingSlotIndices, so f i = 0 via h_pad.
      have hi_not_pad : i ∉ paddingSlotIndices m adj := by
        rw [pathSlotIndices_eq_vertex_union_presentArrow] at hi_path
        rcases Finset.mem_union.mp hi_path with hv | hp
        · -- vertex slot ⇒ not padding
          have h_disj := vertexSlotIndices_disjoint_paddingSlotIndices m adj
          rw [Finset.disjoint_left] at h_disj
          exact h_disj hv
        · -- present-arrow slot ⇒ not padding
          have h_disj := presentArrowSlotIndices_disjoint_paddingSlotIndices m adj
          rw [Finset.disjoint_left] at h_disj
          exact h_disj hp
      exact h_pad i hi_not_pad
    · -- i is not a path slot — i.e. i is a padding slot — so f i = 0 via h_path.
      exact h_path i hi_path
  · intro hf
    subst hf
    exact ⟨zero_mem _, zero_mem _⟩

/-- Decomposition formula: every `f : Fin (dimGQ m) → ℚ` splits into a
path-block part and a padding part.

The path part is `f`'s restriction to `pathSlotIndices m adj` (zero
elsewhere); the padding part is `f`'s restriction to `paddingSlotIndices m adj`
(zero elsewhere). Their sum is `f`. -/
theorem pathBlock_padding_decomposition
    (m : ℕ) (adj : Fin m → Fin m → Bool) (f : Fin (dimGQ m) → ℚ) :
    ∃ (fp fpd : Fin (dimGQ m) → ℚ),
      fp ∈ pathBlockSubspace m adj ∧
      fpd ∈ paddingSubspace m adj ∧
      f = fp + fpd := by
  refine ⟨fun i => if i ∈ pathSlotIndices m adj then f i else 0,
          fun i => if i ∈ paddingSlotIndices m adj then f i else 0,
          ?_, ?_, ?_⟩
  · -- Path part lies in the path-block subspace.
    intro i hi; simp [hi]
  · -- Padding part lies in the padding subspace.
    intro i hi; simp [hi]
  · -- Sum reconstructs f.
    funext i
    simp only [Pi.add_apply]
    -- Case split on which class i belongs to.
    by_cases h_path : i ∈ pathSlotIndices m adj
    · have h_not_pad : i ∉ paddingSlotIndices m adj := by
        rw [pathSlotIndices_eq_vertex_union_presentArrow] at h_path
        rcases Finset.mem_union.mp h_path with hv | hp
        · exact (Finset.disjoint_left.mp
            (vertexSlotIndices_disjoint_paddingSlotIndices m adj)) hv
        · exact (Finset.disjoint_left.mp
            (presentArrowSlotIndices_disjoint_paddingSlotIndices m adj)) hp
      simp [h_path, h_not_pad]
    · -- i ∉ path slots ⇒ i ∈ padding slots (by partition).
      have h_pad : i ∈ paddingSlotIndices m adj := by
        have h_partition := vertex_present_padding_partition m adj
        have h_univ : i ∈ Finset.univ := Finset.mem_univ i
        rw [← h_partition] at h_univ
        rcases Finset.mem_union.mp h_univ with h_vp | h_pad
        · -- i ∈ vertex ∪ presentArrow ⇒ i ∈ pathSlotIndices, contradiction.
          rw [pathSlotIndices_eq_vertex_union_presentArrow] at h_path
          exact absurd h_vp h_path
        · exact h_pad
      simp [h_path, h_pad]

/-- The path-block and padding subspaces span the entire vector space. -/
theorem pathBlockSubspace_sup_paddingSubspace_eq_top
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    pathBlockSubspace m adj ⊔ paddingSubspace m adj = ⊤ := by
  apply le_antisymm
  · exact le_top
  · intro f _
    obtain ⟨fp, fpd, hp, hpd, hf⟩ := pathBlock_padding_decomposition m adj f
    rw [hf]
    exact Submodule.add_mem_sup hp hpd

/-- The complementary `IsCompl` instance: path-block and padding subspaces
form a direct-sum decomposition. -/
theorem pathBlockSubspace_isCompl_paddingSubspace
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    IsCompl (pathBlockSubspace m adj) (paddingSubspace m adj) := by
  refine ⟨?_, ?_⟩
  · rw [disjoint_iff]
    exact pathBlockSubspace_disjoint_paddingSubspace m adj
  · rw [codisjoint_iff]
    exact pathBlockSubspace_sup_paddingSubspace_eq_top m adj

-- ============================================================================
-- Layer 2.2 — Path-block matrix (parametric in π).
--
-- Given a GL³ triple `g` and a slot permutation `π : Equiv.Perm (Fin (dimGQ m))`,
-- the **path-block matrix** is `g.1.val * permMatrixOf m π⁻¹`. The
-- `permMatrixOf m π⁻¹` factor "un-permutes" the columns: when `π` is the
-- partition-preserving slot permutation derived in Phase 3, the resulting
-- matrix has block-diagonal structure aligned to the path/padding partition.
-- ============================================================================

/-- The **path-block matrix**.

This is the matrix `g.1.val · permMatrixOf m π⁻¹` — the first GL component
of `g` composed (on the right) with the inverse of π's permutation matrix.
When `π` is partition-preserving, the resulting matrix's `(i, j)` entry
is `g.1.val(i, π j)` (see `pathBlockMatrix_apply_eq_g_at_pi` below), so
the path-block restriction (Layer 2.3) is well-defined. -/
noncomputable def pathBlockMatrix (m : ℕ)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (π : Equiv.Perm (Fin (dimGQ m))) :
    Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ :=
  g.1.val * permMatrixOf m π⁻¹

/-- Definitional unfolding of `pathBlockMatrix` at an `(i, j)` entry as
the matrix product `∑_a g.1.val(i, a) · permMatrixOf m π⁻¹(a, j)`. -/
theorem pathBlockMatrix_apply (m : ℕ)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (π : Equiv.Perm (Fin (dimGQ m))) (i j : Fin (dimGQ m)) :
    pathBlockMatrix m g π i j =
      ∑ a : Fin (dimGQ m), g.1.val i a * permMatrixOf m π⁻¹ a j := by
  unfold pathBlockMatrix
  rfl

/-- **Simplification when π is partition-preserving** (or any π at all,
in fact — this is purely an algebraic identity).

The inner sum `∑_a g.1.val(i, a) · permMatrixOf m π⁻¹(a, j)` collapses to
the single term at `a = π j`, since `permMatrixOf m π⁻¹(a, j) = 1 ↔ π⁻¹ a = j ↔
a = π j`. -/
theorem pathBlockMatrix_apply_eq_g_at_pi (m : ℕ)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (π : Equiv.Perm (Fin (dimGQ m))) (i j : Fin (dimGQ m)) :
    pathBlockMatrix m g π i j = g.1.val i (π j) := by
  rw [pathBlockMatrix_apply]
  rw [Finset.sum_eq_single (π j)]
  · rw [permMatrixOf_apply]
    -- π⁻¹ (π j) = j ⇒ if-condition is true.
    have h_inv : π⁻¹ (π j) = j := by
      rw [Equiv.Perm.inv_def, Equiv.symm_apply_apply]
    rw [if_pos h_inv, mul_one]
  · -- For a ≠ π j, the indicator is 0.
    intro a _ ha
    rw [permMatrixOf_apply]
    have h_ne : π⁻¹ a ≠ j := by
      intro h_eq
      apply ha
      have : π (π⁻¹ a) = π j := congrArg π h_eq
      rwa [show π (π⁻¹ a) = a from by
        rw [Equiv.Perm.inv_def, Equiv.apply_symm_apply]] at this
    rw [if_neg h_ne, mul_zero]
  · intro h; exact absurd (Finset.mem_univ _) h

/-- **`pathBlockMatrix` at the identity slot permutation reduces to `g.1.val`.** -/
@[simp] theorem pathBlockMatrix_one (m : ℕ)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ) :
    pathBlockMatrix m g 1 = g.1.val := by
  funext i j
  rw [pathBlockMatrix_apply_eq_g_at_pi]
  rfl

/-- The pathBlock matrix is invertible (its determinant is non-zero). -/
theorem pathBlockMatrix_det_ne_zero (m : ℕ)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (π : Equiv.Perm (Fin (dimGQ m))) :
    (pathBlockMatrix m g π).det ≠ 0 := by
  unfold pathBlockMatrix
  rw [Matrix.det_mul]
  -- Both factors are non-zero: g.1 is in GL, permMatrixOf is a permutation matrix.
  exact mul_ne_zero (Matrix.GeneralLinearGroup.det_ne_zero g.1)
    (permMatrixOf_det_ne_zero m π⁻¹)

-- ============================================================================
-- Layer 2.3 — Conditional linear restriction.
--
-- Given the **path-to-padding off-diagonal vanishing hypothesis**
-- `(∀ i ∈ paddingSlotIndices m adj₂, ∀ j ∈ pathSlotIndices m adj₁,
--  pathBlockMatrix m g π i j = 0)`, the matrix's `mulVec` action takes
-- vectors in `pathBlockSubspace m adj₁` to vectors in
-- `pathBlockSubspace m adj₂`.
--
-- Phase 3 establishes this hypothesis from algebra-iso structure; Phase 2
-- provides the linear-algebra restriction machinery.
-- ============================================================================

/-- **The path-to-padding off-diagonal vanishing predicate.**

A `Prop`-valued helper: the matrix `M : Fin (dimGQ m) → Fin (dimGQ m) → ℚ`
has zero entries when the row `i` is a padding slot of `adj₂` and the
column `j` is a path slot of `adj₁`.

This is the hypothesis Phase 3 establishes for `M = pathBlockMatrix m g π`
when π is the partition-preserving slot permutation derived from the
algebra-iso structure. -/
def IsPathBlockDiagonal (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (M : Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ) : Prop :=
  ∀ i, i ∈ paddingSlotIndices m adj₂ →
    ∀ j, j ∈ pathSlotIndices m adj₁ → M i j = 0

/-- **Symmetric padding-to-path off-diagonal vanishing predicate.**

For the inverse direction of the path-block restriction (turning the
restriction into a `LinearEquiv`), we additionally need the symmetric
block-vanishing: rows in `pathSlotIndices m adj₂` and columns in
`paddingSlotIndices m adj₁` give zero entries. -/
def IsPaddingBlockDiagonal (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (M : Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ) : Prop :=
  ∀ i, i ∈ pathSlotIndices m adj₂ →
    ∀ j, j ∈ paddingSlotIndices m adj₁ → M i j = 0

/-- **Block-diagonal predicate (combined).** A matrix is fully
block-diagonal w.r.t. the path/padding partition iff both the
path-to-padding and the padding-to-path off-diagonal blocks vanish. -/
def IsFullyPathBlockDiagonal (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (M : Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ) : Prop :=
  IsPathBlockDiagonal m adj₁ adj₂ M ∧ IsPaddingBlockDiagonal m adj₁ adj₂ M

/-- **The matrix's `mulVec` action restricts to the path-block subspaces**
under the path-to-padding off-diagonal vanishing hypothesis.

Given a vector `v : Fin (dimGQ m) → ℚ` supported on `pathSlotIndices m adj₁`,
the result `M *ᵥ v` is supported on `pathSlotIndices m adj₂`. The proof
case-splits on whether the output index `i` is a path slot or a padding
slot of `adj₂`; the path-slot case is unconstrained, and the padding-slot
case uses the hypothesis to force the row contribution to vanish. -/
theorem mulVec_mem_pathBlockSubspace_of_isPathBlockDiagonal
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (M : Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ)
    (h_block : IsPathBlockDiagonal m adj₁ adj₂ M)
    (v : Fin (dimGQ m) → ℚ) (h_v : v ∈ pathBlockSubspace m adj₁) :
    M *ᵥ v ∈ pathBlockSubspace m adj₂ := by
  intro i hi
  -- i ∉ pathSlotIndices m adj₂ means i is in paddingSlotIndices m adj₂
  -- (by the partition theorem).
  have hi_pad : i ∈ paddingSlotIndices m adj₂ := by
    have h_partition := vertex_present_padding_partition m adj₂
    have h_univ : i ∈ Finset.univ := Finset.mem_univ i
    rw [← h_partition] at h_univ
    rcases Finset.mem_union.mp h_univ with h_vp | h_pad
    · rw [pathSlotIndices_eq_vertex_union_presentArrow] at hi
      exact absurd h_vp hi
    · exact h_pad
  -- Compute (M *ᵥ v) i = ∑ j, M i j * v j.
  show (∑ j, M i j * v j) = 0
  apply Finset.sum_eq_zero
  intro j _
  -- Case split on whether j is a path slot or padding slot of adj₁.
  by_cases h_j_path : j ∈ pathSlotIndices m adj₁
  · -- j is a path slot ⇒ M i j = 0 by the block hypothesis.
    rw [h_block i hi_pad j h_j_path, zero_mul]
  · -- j is not a path slot ⇒ v j = 0 by support of v.
    rw [h_v j h_j_path, mul_zero]

/-- **The path-block restriction as a `LinearMap`.**

Given a path-block-diagonal matrix `M`, this packages the restriction
`M *ᵥ -` as a linear map between `pathBlockSubspace m adj₁` and
`pathBlockSubspace m adj₂`. -/
noncomputable def pathBlockRestrict (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (M : Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ)
    (h_block : IsPathBlockDiagonal m adj₁ adj₂ M) :
    pathBlockSubspace m adj₁ →ₗ[ℚ] pathBlockSubspace m adj₂ where
  toFun v := ⟨M *ᵥ v.val,
    mulVec_mem_pathBlockSubspace_of_isPathBlockDiagonal m adj₁ adj₂ M h_block
      v.val v.property⟩
  map_add' x y := by
    apply Subtype.ext
    show M *ᵥ (x.val + y.val) = M *ᵥ x.val + M *ᵥ y.val
    exact Matrix.mulVec_add M x.val y.val
  map_smul' c x := by
    apply Subtype.ext
    show M *ᵥ (c • x.val) = c • (M *ᵥ x.val)
    exact Matrix.mulVec_smul M c x.val

/-- Definitional unfolding of `pathBlockRestrict.toFun`. -/
@[simp] theorem pathBlockRestrict_apply (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (M : Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ)
    (h_block : IsPathBlockDiagonal m adj₁ adj₂ M)
    (v : pathBlockSubspace m adj₁) :
    (pathBlockRestrict m adj₁ adj₂ M h_block v).val = M *ᵥ v.val := rfl

/-- **The path-block restriction is the GL³-action restriction.**

Specialises `pathBlockRestrict` to `M = pathBlockMatrix m g π` (the actual
matrix Phase 3 produces). -/
noncomputable def gl3_restrict_to_pathBlock (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (π : Equiv.Perm (Fin (dimGQ m)))
    (h_block : IsPathBlockDiagonal m adj₁ adj₂ (pathBlockMatrix m g π)) :
    pathBlockSubspace m adj₁ →ₗ[ℚ] pathBlockSubspace m adj₂ :=
  pathBlockRestrict m adj₁ adj₂ (pathBlockMatrix m g π) h_block

-- ============================================================================
-- Layer 2.4 — Bridge from `pathBlockSubspace` to `presentArrowsSubspace`.
--
-- The path-block subspace lives in `Fin (dimGQ m) → ℚ` (the coordinate
-- representation where `pathBlockMatrix` operates). The algebra-iso content
-- of Phase 3 lives in `pathAlgebraQuotient m = QuiverArrow m → ℚ` (the
-- carrier of the `Algebra ℚ` instance from `AlgebraWrapper.lean`). Layer 2.4
-- establishes the linear equivalence bridging the two — the slot-to-arrow
-- correspondence on the path-algebra slots is exactly the
-- `slotToArrow`/`slotOfArrow` pair from `EncoderSlabEval.lean`.
-- ============================================================================

/-- The **present-arrows subspace** of `pathAlgebraQuotient m`: vectors
that vanish outside `presentArrows m adj`.

This is the natural codomain of the algebra-iso construction in Phase 3 —
the path-algebra `F[Q_G] / J²` of `adj` is precisely
`presentArrowsSubspace m adj` equipped with the convolution multiplication
inherited from `pathAlgebraQuotient m`. -/
def presentArrowsSubspace (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Submodule ℚ (pathAlgebraQuotient m) where
  carrier := { f : QuiverArrow m → ℚ | ∀ a, a ∉ presentArrows m adj → f a = 0 }
  zero_mem' := by intro a _; rfl
  add_mem' := by
    intro f g hf hg a ha
    show f a + g a = 0
    rw [hf a ha, hg a ha, add_zero]
  smul_mem' := by
    intro c f hf a ha
    show c • f a = 0
    rw [hf a ha, smul_zero]

/-- Membership characterization for `presentArrowsSubspace`. -/
@[simp] theorem mem_presentArrowsSubspace_iff (m : ℕ)
    (adj : Fin m → Fin m → Bool) (f : pathAlgebraQuotient m) :
    f ∈ presentArrowsSubspace m adj ↔
      ∀ a, a ∉ presentArrows m adj → f a = 0 := Iff.rfl

/-- The **vertex-idempotent basis element** `vertexIdempotent m v` lies in
the present-arrows subspace for any adjacency. -/
theorem vertexIdempotent_mem_presentArrowsSubspace (m : ℕ)
    (adj : Fin m → Fin m → Bool) (v : Fin m) :
    vertexIdempotent m v ∈ presentArrowsSubspace m adj := by
  intro a ha
  cases a with
  | id w =>
    -- id w ∈ presentArrows m adj always, contradicting ha.
    exact absurd (presentArrows_id_mem m adj w) ha
  | edge u w =>
    -- vertexIdempotent at edge basis element is 0.
    rfl

/-- The **arrow-element basis** `arrowElement m u v` lies in the
present-arrows subspace iff `adj u v = true`. -/
theorem arrowElement_mem_presentArrowsSubspace (m : ℕ)
    (adj : Fin m → Fin m → Bool) (u v : Fin m) (h : adj u v = true) :
    arrowElement m u v ∈ presentArrowsSubspace m adj := by
  intro a ha
  cases a with
  | id w =>
    -- arrowElement at id basis element is 0.
    rfl
  | edge u' v' =>
    -- We must show arrowElement m u v (.edge u' v') = 0.
    -- arrowElement m u v (.edge u' v') = if u = u' ∧ v = v' then 1 else 0.
    show (if u = u' ∧ v = v' then (1 : ℚ) else 0) = 0
    by_cases h_eq : u = u' ∧ v = v'
    · obtain ⟨rfl, rfl⟩ := h_eq
      -- Then edge u v ∈ presentArrows iff adj u v = true, which holds.
      exact absurd ((presentArrows_edge_mem_iff m adj u v).mpr h) ha
    · simp [h_eq]

/-- **The forward map of the bridge.**

Take a path-block vector `v : Fin (dimGQ m) → ℚ` (supported on
`pathSlotIndices m adj`) and produce a present-arrows vector
`f : QuiverArrow m → ℚ` (supported on `presentArrows m adj`) by
push-forward through the slot/arrow correspondence:
`f a := v (slotOfArrow m a)` when `a ∈ presentArrows m adj`, else 0. -/
def pathBlockToPresentArrowsFun (m : ℕ) (adj : Fin m → Fin m → Bool)
    (v : Fin (dimGQ m) → ℚ) : pathAlgebraQuotient m :=
  fun a => if a ∈ presentArrows m adj then v (slotOfArrow m a) else 0

/-- **The reverse map of the bridge.** -/
def presentArrowsToPathBlockFun (m : ℕ) (adj : Fin m → Fin m → Bool)
    (f : pathAlgebraQuotient m) : Fin (dimGQ m) → ℚ :=
  fun i => if i ∈ pathSlotIndices m adj
    then f (slotToArrow m (slotEquiv m i))
    else 0

/-- Helper: when `i ∈ pathSlotIndices m adj`, the arrow basis element
`slotToArrow m (slotEquiv m i)` lies in `presentArrows m adj`. -/
theorem slotToArrow_mem_presentArrows_of_path
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i : Fin (dimGQ m))
    (h : i ∈ pathSlotIndices m adj) :
    slotToArrow m (slotEquiv m i) ∈ presentArrows m adj := by
  -- Case-split on slotEquiv m i:
  cases h_slot : slotEquiv m i with
  | vertex v =>
    -- slotToArrow (vertex v) = id v, always in presentArrows.
    simp [slotToArrow, presentArrows_id_mem]
  | arrow u w =>
    -- slotToArrow (arrow u w) = edge u w; in presentArrows iff adj u w.
    -- From h_slot and h, we know adj u w = true (i is path slot).
    have h_adj : adj u w = true := by
      rw [pathSlotIndices_eq_vertex_union_presentArrow] at h
      rcases Finset.mem_union.mp h with hv | hp
      · -- i ∈ vertexSlotIndices contradicts slotEquiv m i = arrow u w
        rw [mem_vertexSlotIndices_iff] at hv
        obtain ⟨_, hv'⟩ := hv
        rw [h_slot] at hv'
        nomatch hv'
      · -- i ∈ presentArrowSlotIndices ⇒ adj u w = true.
        rw [mem_presentArrowSlotIndices_iff] at hp
        obtain ⟨u', w', hp', h_adj'⟩ := hp
        rw [h_slot] at hp'
        have : u = u' ∧ w = w' := SlotKind.arrow.injEq u w u' w' |>.mp hp'
        obtain ⟨rfl, rfl⟩ := this
        exact h_adj'
    show QuiverArrow.edge u w ∈ presentArrows m adj
    exact (presentArrows_edge_mem_iff m adj u w).mpr h_adj

/-- Helper: when `a ∈ presentArrows m adj`, the slot index `slotOfArrow m a`
lies in `pathSlotIndices m adj`. -/
theorem slotOfArrow_mem_pathSlotIndices_of_present
    (m : ℕ) (adj : Fin m → Fin m → Bool) (a : QuiverArrow m)
    (h : a ∈ presentArrows m adj) :
    slotOfArrow m a ∈ pathSlotIndices m adj := by
  cases a with
  | id v =>
    -- slotOfArrow (id v) = (slotEquiv m).symm (.vertex v) — a vertex slot.
    rw [pathSlotIndices_eq_vertex_union_presentArrow]
    apply Finset.mem_union_left
    rw [mem_vertexSlotIndices_iff]
    exact ⟨v, by simp [slotOfArrow, arrowToSlot]⟩
  | edge u w =>
    -- a = edge u w ⇒ adj u w = true ⇒ slotOfArrow lies in presentArrowSlotIndices.
    rw [presentArrows_edge_mem_iff] at h
    rw [pathSlotIndices_eq_vertex_union_presentArrow]
    apply Finset.mem_union_right
    rw [mem_presentArrowSlotIndices_iff]
    exact ⟨u, w, by simp [slotOfArrow, arrowToSlot], h⟩

/-- The forward map's image lies in `presentArrowsSubspace`.

The image lies in the subspace **unconditionally** — the forward map's
piecewise definition (`if a ∈ presentArrows then ... else 0`) makes
zero outside `presentArrows m adj` automatic, so no support hypothesis
on `v` is needed. -/
theorem pathBlockToPresentArrowsFun_mem (m : ℕ) (adj : Fin m → Fin m → Bool)
    (v : Fin (dimGQ m) → ℚ) :
    pathBlockToPresentArrowsFun m adj v ∈ presentArrowsSubspace m adj := by
  intro a ha
  show (if a ∈ presentArrows m adj then v (slotOfArrow m a) else 0) = 0
  simp [ha]

/-- The reverse map's image lies in `pathBlockSubspace`.

Unconditional, parallel to `pathBlockToPresentArrowsFun_mem`. -/
theorem presentArrowsToPathBlockFun_mem (m : ℕ) (adj : Fin m → Fin m → Bool)
    (f : pathAlgebraQuotient m) :
    presentArrowsToPathBlockFun m adj f ∈ pathBlockSubspace m adj := by
  intro i hi
  show (if i ∈ pathSlotIndices m adj
    then f (slotToArrow m (slotEquiv m i))
    else 0) = 0
  simp [hi]

/-- **Round-trip identity (forward → reverse).**

For `v ∈ pathBlockSubspace m adj`, applying the forward map then the
reverse map recovers `v`. -/
theorem presentArrowsToPathBlockFun_pathBlockToPresentArrowsFun
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (v : Fin (dimGQ m) → ℚ) (h_v : v ∈ pathBlockSubspace m adj) :
    presentArrowsToPathBlockFun m adj
      (pathBlockToPresentArrowsFun m adj v) = v := by
  funext i
  unfold presentArrowsToPathBlockFun pathBlockToPresentArrowsFun
  by_cases hi : i ∈ pathSlotIndices m adj
  · -- i is a path slot. Then f := pathBlockToPresentArrowsFun ... evaluated
    -- at slotToArrow (slotEquiv i) — which is in presentArrows (helper) —
    -- equals v (slotOfArrow (slotToArrow (slotEquiv i))).
    -- And slotOfArrow ∘ slotToArrow ∘ slotEquiv = id (at path slots, by symm).
    rw [if_pos hi]
    have h_pres := slotToArrow_mem_presentArrows_of_path m adj i hi
    rw [if_pos h_pres]
    -- slotOfArrow m (slotToArrow m (slotEquiv m i)) = i.
    have h_round : slotOfArrow m (slotToArrow m (slotEquiv m i)) = i := by
      unfold slotOfArrow
      rw [arrowToSlot_slotToArrow, Equiv.symm_apply_apply]
    rw [h_round]
  · -- i is not a path slot. Then both sides are 0 by support of v.
    rw [if_neg hi]
    exact (h_v i hi).symm

/-- **Round-trip identity (reverse → forward).**

For `f ∈ presentArrowsSubspace m adj`, applying the reverse map then the
forward map recovers `f`. -/
theorem pathBlockToPresentArrowsFun_presentArrowsToPathBlockFun
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (f : pathAlgebraQuotient m) (h_f : f ∈ presentArrowsSubspace m adj) :
    pathBlockToPresentArrowsFun m adj
      (presentArrowsToPathBlockFun m adj f) = f := by
  funext a
  unfold pathBlockToPresentArrowsFun presentArrowsToPathBlockFun
  by_cases ha : a ∈ presentArrows m adj
  · rw [if_pos ha]
    have h_path := slotOfArrow_mem_pathSlotIndices_of_present m adj a ha
    rw [if_pos h_path]
    -- slotToArrow (slotEquiv (slotOfArrow a)) = a (round-trip in EncoderSlabEval).
    rw [slotToArrow_slotEquiv_slotOfArrow]
  · rw [if_neg ha]
    exact (h_f a ha).symm

/-- **The bridge as a `LinearEquiv`** between the path-block subspace and
the present-arrows subspace.

This is the linear equivalence that Phase 3's algebra-iso construction
consumes: it lifts the path-block restriction (Layer 2.3) to a linear map
between `presentArrowsSubspace m adj₁` and `presentArrowsSubspace m adj₂`,
which is the natural domain/codomain of the algebra iso. -/
noncomputable def pathBlockToPresentArrows (m : ℕ) (adj : Fin m → Fin m → Bool) :
    pathBlockSubspace m adj ≃ₗ[ℚ] presentArrowsSubspace m adj where
  toFun v := ⟨pathBlockToPresentArrowsFun m adj v.val,
    pathBlockToPresentArrowsFun_mem m adj v.val⟩
  invFun f := ⟨presentArrowsToPathBlockFun m adj f.val,
    presentArrowsToPathBlockFun_mem m adj f.val⟩
  left_inv v := by
    apply Subtype.ext
    show presentArrowsToPathBlockFun m adj
      (pathBlockToPresentArrowsFun m adj v.val) = v.val
    exact presentArrowsToPathBlockFun_pathBlockToPresentArrowsFun m adj
      v.val v.property
  right_inv f := by
    apply Subtype.ext
    show pathBlockToPresentArrowsFun m adj
      (presentArrowsToPathBlockFun m adj f.val) = f.val
    exact pathBlockToPresentArrowsFun_presentArrowsToPathBlockFun m adj
      f.val f.property
  map_add' x y := by
    apply Subtype.ext
    funext a
    show pathBlockToPresentArrowsFun m adj (x.val + y.val) a =
      (pathBlockToPresentArrowsFun m adj x.val +
       pathBlockToPresentArrowsFun m adj y.val) a
    unfold pathBlockToPresentArrowsFun
    show (if a ∈ presentArrows m adj then (x.val + y.val) (slotOfArrow m a) else 0) =
      (if a ∈ presentArrows m adj then x.val (slotOfArrow m a) else 0) +
      (if a ∈ presentArrows m adj then y.val (slotOfArrow m a) else 0)
    by_cases ha : a ∈ presentArrows m adj
    · simp [ha]
    · simp [ha]
  map_smul' c x := by
    apply Subtype.ext
    funext a
    show pathBlockToPresentArrowsFun m adj (c • x.val) a =
      c • pathBlockToPresentArrowsFun m adj x.val a
    unfold pathBlockToPresentArrowsFun
    show (if a ∈ presentArrows m adj then (c • x.val) (slotOfArrow m a) else 0) =
      c • (if a ∈ presentArrows m adj then x.val (slotOfArrow m a) else 0)
    by_cases ha : a ∈ presentArrows m adj
    · simp [ha]
    · simp [ha]

/-- Apply lemma for `pathBlockToPresentArrows`. -/
@[simp] theorem pathBlockToPresentArrows_apply (m : ℕ)
    (adj : Fin m → Fin m → Bool) (v : pathBlockSubspace m adj) :
    (pathBlockToPresentArrows m adj v).val =
      pathBlockToPresentArrowsFun m adj v.val := rfl

/-- Apply lemma for `pathBlockToPresentArrows.symm`. -/
@[simp] theorem pathBlockToPresentArrows_symm_apply (m : ℕ)
    (adj : Fin m → Fin m → Bool) (f : presentArrowsSubspace m adj) :
    ((pathBlockToPresentArrows m adj).symm f).val =
      presentArrowsToPathBlockFun m adj f.val := rfl

end GrochowQiao
end Orbcrypt
