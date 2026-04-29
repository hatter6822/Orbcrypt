/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
Wedderburn–Mal'cev conjugacy (specialised to J² = 0) for the
radical-2 truncated path algebra `F[Q_G] / J²`.

Layer 6b of the 2026-04-26 implementation plan.
-/

import Mathlib.LinearAlgebra.Span.Defs
import Mathlib.Algebra.Algebra.Equiv
import Mathlib.Tactic.NoncommRing
import Orbcrypt.Hardness.GrochowQiao.AlgebraWrapper

namespace Orbcrypt
namespace GrochowQiao

-- ============================================================================
-- Layer 6b.1 — Jacobson radical of `F[Q_G] / J²`.
-- ============================================================================

/-- **The Jacobson radical of the path algebra.** Submodule spanned by
arrow basis elements. -/
noncomputable def pathAlgebraRadical (m : ℕ) :
    Submodule ℚ (pathAlgebraQuotient m) :=
  Submodule.span ℚ
    (Set.range (fun (p : Fin m × Fin m) => arrowElement m p.1 p.2))

theorem arrowElement_mem_pathAlgebraRadical (m : ℕ) (u v : Fin m) :
    arrowElement m u v ∈ pathAlgebraRadical m :=
  Submodule.subset_span ⟨(u, v), rfl⟩

/-- Convenience wrapper: arrow times arrow = 0 in `*` form. -/
theorem arrow_mul_arrow_eq_zero (m : ℕ) (u v u' v' : Fin m) :
    arrowElement m u v * arrowElement m u' v' = 0 :=
  arrowElement_mul_arrowElement_eq_zero m u v u' v'

/-- **Helper: an arrow basis element times any radical element is zero.**

Proof by `Submodule.span_induction` on the radical element using
standard ring lemmas. -/
theorem arrowElement_mul_member_radical (m : ℕ) (u v : Fin m)
    (j : pathAlgebraQuotient m) (h_j : j ∈ pathAlgebraRadical m) :
    arrowElement m u v * j = 0 := by
  refine Submodule.span_induction ?_ ?_ ?_ ?_ h_j
  · -- mem case: x = arrowElement m u' v' for some (u', v').
    rintro _ ⟨⟨u', v'⟩, rfl⟩
    exact arrow_mul_arrow_eq_zero m u v u' v'
  · -- zero case.
    exact mul_zero _
  · -- add case.
    intros x y _ _ hx hy
    rw [mul_add, hx, hy, add_zero]
  · -- smul case.
    intros r x _ hx
    rw [mul_smul_comm, hx, smul_zero]

/-- **Helper: any radical element times an arrow basis element is zero.** -/
theorem member_radical_mul_arrowElement (m : ℕ) (u v : Fin m)
    (j : pathAlgebraQuotient m) (h_j : j ∈ pathAlgebraRadical m) :
    j * arrowElement m u v = 0 := by
  refine Submodule.span_induction ?_ ?_ ?_ ?_ h_j
  · rintro _ ⟨⟨u', v'⟩, rfl⟩
    exact arrow_mul_arrow_eq_zero m u' v' u v
  · exact zero_mul _
  · intros x y _ _ hx hy
    rw [add_mul, hx, hy, add_zero]
  · intros r x _ hx
    rw [smul_mul_assoc, hx, smul_zero]

/-- **J · J = 0** — the defining property of the radical-2 truncation.

For any two elements of `pathAlgebraRadical m`, their product is zero.
This is the structural fact that drives the entire Wedderburn–Mal'cev
simplification: in `F[Q_G] / J²`, any conjugation
`(1 + j) · c · (1 - j)` collapses to `c + j · c - c · j` (the
`j · c · j` term vanishes). -/
theorem pathAlgebraRadical_mul_radical_eq_zero (m : ℕ)
    {j₁ j₂ : pathAlgebraQuotient m}
    (h₁ : j₁ ∈ pathAlgebraRadical m) (h₂ : j₂ ∈ pathAlgebraRadical m) :
    j₁ * j₂ = 0 := by
  refine Submodule.span_induction ?_ ?_ ?_ ?_ h₁
  · rintro _ ⟨⟨u, v⟩, rfl⟩
    -- arrow * any radical element = 0
    exact arrowElement_mul_member_radical m u v j₂ h₂
  · exact zero_mul _
  · intros x y _ _ hx hy
    rw [add_mul, hx, hy, add_zero]
  · intros r x _ hx
    rw [smul_mul_assoc, hx, smul_zero]

-- ============================================================================
-- Layer 6b.2 — Element decomposition modulo radical.
-- ============================================================================

/-- **Arrow part of an element lies in the radical.** -/
theorem pathAlgebra_arrow_part_mem_radical (m : ℕ) (f : pathAlgebraQuotient m) :
    (∑ p : Fin m × Fin m, f (.edge p.1 p.2) • arrowElement m p.1 p.2) ∈
    pathAlgebraRadical m := by
  apply Submodule.sum_mem
  intros p _
  apply Submodule.smul_mem
  exact arrowElement_mem_pathAlgebraRadical m p.1 p.2

/-- **Vertex part is the canonical sum of vertex idempotents
weighted by the .id-coefficients.** -/
noncomputable def pathAlgebra_vertexPart (m : ℕ) (f : pathAlgebraQuotient m) :
    pathAlgebraQuotient m :=
  ∑ v : Fin m, f (.id v) • vertexIdempotent m v

/-- **Arrow part is the canonical sum of arrow elements
weighted by the .edge-coefficients (lies in the radical).** -/
noncomputable def pathAlgebra_arrowPart (m : ℕ) (f : pathAlgebraQuotient m) :
    pathAlgebraQuotient m :=
  ∑ p : Fin m × Fin m, f (.edge p.1 p.2) • arrowElement m p.1 p.2

theorem pathAlgebra_arrowPart_mem_radical (m : ℕ) (f : pathAlgebraQuotient m) :
    pathAlgebra_arrowPart m f ∈ pathAlgebraRadical m :=
  pathAlgebra_arrow_part_mem_radical m f

/-- **Decomposition: `f = vertexPart + arrowPart`.**

Direct re-statement of `pathAlgebra_decompose` (Layer 5.3) using the
named projections. -/
theorem pathAlgebra_decompose_radical (m : ℕ) (f : pathAlgebraQuotient m) :
    f = pathAlgebra_vertexPart m f + pathAlgebra_arrowPart m f :=
  pathAlgebra_decompose m f

-- ============================================================================
-- Layer 6b.4 — Inner automorphism `c ↦ (1 + j) · c · (1 - j)`.
-- ============================================================================

/-- **`(1 + j)(1 - j) = 1` when `j ∈ pathAlgebraRadical m`.**

By `j² = 0`: `(1+j)(1-j) = 1 - j + j - j² = 1`. -/
theorem oneAddRadical_mul_oneSubRadical (m : ℕ) (j : pathAlgebraQuotient m)
    (h_j : j ∈ pathAlgebraRadical m) :
    (1 + j) * (1 - j) = 1 := by
  have h_jj : j * j = 0 :=
    pathAlgebraRadical_mul_radical_eq_zero m h_j h_j
  have step : (1 + j) * (1 - j) = 1 - j * j := by noncomm_ring
  rw [step, h_jj, sub_zero]

/-- **`(1 - j)(1 + j) = 1` when `j ∈ pathAlgebraRadical m`.** -/
theorem oneSubRadical_mul_oneAddRadical (m : ℕ) (j : pathAlgebraQuotient m)
    (h_j : j ∈ pathAlgebraRadical m) :
    (1 - j) * (1 + j) = 1 := by
  have h_jj : j * j = 0 :=
    pathAlgebraRadical_mul_radical_eq_zero m h_j h_j
  have step : (1 - j) * (1 + j) = 1 - j * j := by noncomm_ring
  rw [step, h_jj, sub_zero]

/-- **Helper: arrow times anything lies in the radical.**

`α(u, v) * c ∈ J` for any `c`, because the result has zero `.id` components
(arrows kill vertex idempotents on the wrong side). -/
theorem arrowElement_mul_anything_mem_radical (m : ℕ) (u v : Fin m)
    (c : pathAlgebraQuotient m) :
    arrowElement m u v * c ∈ pathAlgebraRadical m := by
  -- Decompose c into vertex + arrow parts; each part * α(u, v) is in J.
  rw [pathAlgebra_decompose m c, mul_add]
  apply Submodule.add_mem
  · -- α(u, v) * vertexPart = α(u, v) * (∑_w c(.id w) • e_w)
    rw [Finset.mul_sum]
    apply Submodule.sum_mem
    intros w _
    rw [mul_smul_comm]
    apply Submodule.smul_mem
    -- α(u, v) * e_w = if v = w then α(u, v) else 0
    show pathAlgebraMul m (arrowElement m u v) (vertexIdempotent m w) ∈ _
    rw [arrowElement_mul_vertexIdempotent]
    by_cases h : v = w
    · rw [if_pos h]; exact arrowElement_mem_pathAlgebraRadical m u v
    · rw [if_neg h]; exact Submodule.zero_mem _
  · -- α(u, v) * arrowPart: each arrow * arrow = 0.
    rw [Finset.mul_sum]
    apply Submodule.sum_mem
    intros p _
    rw [mul_smul_comm]
    apply Submodule.smul_mem
    rw [arrow_mul_arrow_eq_zero m u v p.1 p.2]
    exact Submodule.zero_mem _

/-- **Helper: any radical element times anything stays in the radical.**

By induction on the radical element. -/
theorem member_radical_mul_anything_mem_radical (m : ℕ)
    {j : pathAlgebraQuotient m} (c : pathAlgebraQuotient m)
    (h_j : j ∈ pathAlgebraRadical m) :
    j * c ∈ pathAlgebraRadical m := by
  refine Submodule.span_induction ?_ ?_ ?_ ?_ h_j
  · rintro _ ⟨⟨u, v⟩, rfl⟩
    exact arrowElement_mul_anything_mem_radical m u v c
  · rw [zero_mul]; exact Submodule.zero_mem _
  · intros x y _ _ hx hy
    rw [add_mul]; exact Submodule.add_mem _ hx hy
  · intros r x _ hx
    rw [smul_mul_assoc]; exact Submodule.smul_mem _ _ hx

/-- **Crucial cancellation: `j · c · j = 0` when `j ∈ J`.**

`j · c ∈ J` (radical absorbs left-multiplication), then `(j · c) · j ∈ J · J = 0`. -/
theorem radical_sandwich_eq_zero (m : ℕ) {j : pathAlgebraQuotient m}
    (c : pathAlgebraQuotient m) (h_j : j ∈ pathAlgebraRadical m) :
    j * c * j = 0 := by
  have h_jc : j * c ∈ pathAlgebraRadical m :=
    member_radical_mul_anything_mem_radical m c h_j
  exact pathAlgebraRadical_mul_radical_eq_zero m h_jc h_j

/-- **Simplified conjugation in `J² = 0`: `(1 + j)·c·(1 - j) = c + j·c - c·j`.**

This is the structural fact that makes the Wedderburn–Mal'cev construction
tractable: the conjugation is "linear in j" modulo the `J² = 0` relation. -/
theorem innerAut_simplified (m : ℕ) {j : pathAlgebraQuotient m}
    (c : pathAlgebraQuotient m) (h_j : j ∈ pathAlgebraRadical m) :
    (1 + j) * c * (1 - j) = c + j * c - c * j := by
  -- Expand: (1 + j) * c * (1 - j) = c - c*j + j*c - j*c*j.
  have step : (1 + j) * c * (1 - j) =
              c - c * j + j * c - j * c * j := by noncomm_ring
  rw [step, radical_sandwich_eq_zero m c h_j, sub_zero]
  -- c - c*j + j*c = c + j*c - c*j (rearranging additive terms).
  noncomm_ring

-- ============================================================================
-- Layer 6b.3 — Wedderburn–Mal'cev conjugacy: vertex coefficient analysis.
-- ============================================================================

variable {m : ℕ} {ι : Type*} [Fintype ι]

/-- **Vertex coefficient is 0 or 1 in any idempotent.**

Direct from `pathAlgebra_idempotent_lambda_squared` (Layer 6.2). -/
theorem coi_vertex_coef_zero_or_one
    {e' : ι → pathAlgebraQuotient m} (h : CompleteOrthogonalIdempotents e')
    (i : ι) (z : Fin m) :
    (e' i) (.id z) = 0 ∨ (e' i) (.id z) = 1 :=
  pathAlgebra_idempotent_lambda_squared m (e' i) (h.idem i) z

/-- **Vertex coefficient orthogonality: `λ(v, z) * λ(w, z) = 0` for `v ≠ w`.** -/
theorem coi_vertex_coef_orth
    {e' : ι → pathAlgebraQuotient m} (h : CompleteOrthogonalIdempotents e')
    {i j : ι} (h_ne : i ≠ j) (z : Fin m) :
    (e' i) (.id z) * (e' j) (.id z) = 0 := by
  have h_prod : e' i * e' j = 0 := h.ortho h_ne
  have h_eval : (e' i * e' j) (.id z) = (0 : pathAlgebraQuotient m) (.id z) := by
    rw [h_prod]
  -- LHS = (e' i)(.id z) * (e' j)(.id z); RHS = 0.
  rw [show (e' i * e' j) (.id z) = pathAlgebraMul m (e' i) (e' j) (.id z) from rfl,
      pathAlgebraMul_apply_id] at h_eval
  exact h_eval

/-- Helper: pull a function-application through a Finset sum on the
type alias `pathAlgebraQuotient m`. -/
private lemma sum_pathAlgQ_apply {ι : Type*} (s : Finset ι)
    (g : ι → pathAlgebraQuotient m) (a : QuiverArrow m) :
    (∑ i ∈ s, g i) a = ∑ i ∈ s, g i a :=
  Finset.sum_apply a s g

/-- **Vertex coefficient completeness: `∑_i λ(i, z) = 1`.** -/
theorem coi_vertex_coef_complete
    {e' : ι → pathAlgebraQuotient m} (h : CompleteOrthogonalIdempotents e')
    (z : Fin m) :
    ∑ i, (e' i) (.id z) = 1 := by
  have h_sum : ∑ i, e' i = 1 := h.complete
  have h_eval : (∑ i, e' i) (.id z) = (1 : pathAlgebraQuotient m) (.id z) := by
    rw [h_sum]
  rw [sum_pathAlgQ_apply] at h_eval
  rw [h_eval]
  -- (1 : pathAlgebraQuotient m) (.id z) = pathAlgebraOne m (.id z) = 1.
  show pathAlgebraOne m (.id z) = 1
  exact pathAlgebraOne_apply_id m z

/-- **An idempotent with all `.id` coefficients zero is itself zero.**

Proof: by the `mu`-constraint (Layer 6.2), `(b (.edge u w)) * (b (.id u) + b (.id w) - 1) = 0`,
which under the all-zero hypothesis on `.id` coefs forces `b (.edge u w) = 0`. -/
theorem pathAlgebra_idempotent_zero_of_id_coef_zero
    (b : pathAlgebraQuotient m) (h_idem : IsIdempotentElem b)
    (h_id : ∀ z, b (.id z) = 0) : b = 0 := by
  funext c
  cases c with
  | id z =>
    show b (.id z) = (0 : pathAlgebraQuotient m) (.id z)
    rw [h_id z]; rfl
  | edge u w =>
    show b (.edge u w) = (0 : pathAlgebraQuotient m) (.edge u w)
    have h_mu := pathAlgebra_idempotent_mu_constraint m b h_idem u w
    -- h_mu : b (.edge u w) = 0 ∨ b (.id u) + b (.id w) = 1
    rcases h_mu with h_zero | h_sum
    · rw [h_zero]; rfl
    · -- b (.id u) = 0, b (.id w) = 0, so 0 + 0 = 1, contradiction.
      rw [h_id u, h_id w] at h_sum
      norm_num at h_sum

/-- **Every non-zero element of a COI has at least one active vertex.** -/
theorem coi_nonzero_has_active_vertex
    {e' : ι → pathAlgebraQuotient m} (h_coi : CompleteOrthogonalIdempotents e')
    {i : ι} (h_nz : e' i ≠ 0) :
    ∃ z, (e' i) (.id z) = 1 := by
  by_contra h_no
  push Not at h_no
  -- h_no : ∀ z, (e' i) (.id z) ≠ 1
  -- Combined with `coi_vertex_coef_zero_or_one`, each coef is 0.
  have h_all_zero : ∀ z, (e' i) (.id z) = 0 := fun z =>
    (coi_vertex_coef_zero_or_one h_coi i z).resolve_right (h_no z)
  -- Then e' i = 0, contradiction.
  exact h_nz (pathAlgebra_idempotent_zero_of_id_coef_zero _ (h_coi.idem i) h_all_zero)

-- ============================================================================
-- Layer 6b.3 — σ extraction (Fin m specialization).
-- ============================================================================

/-- **Uniqueness of active i per z: exactly one COI element activates each `.id z`.** -/
theorem coi_unique_active_per_z
    {e' : Fin m → pathAlgebraQuotient m} (h_coi : CompleteOrthogonalIdempotents e')
    (z : Fin m) :
    ∃! i, (e' i) (.id z) = 1 := by
  -- Existence: from completeness, ∑_i (e' i)(.id z) = 1, so some term is non-zero.
  have h_sum : ∑ i : Fin m, (e' i) (.id z) = 1 := coi_vertex_coef_complete h_coi z
  -- If all coefs were 0, the sum would be 0; we'd contradict 1.
  have h_exists : ∃ i, (e' i) (.id z) = 1 := by
    by_contra h_no
    push Not at h_no
    -- h_no : ∀ i, (e' i)(.id z) ≠ 1
    have h_all_zero : ∀ i, (e' i) (.id z) = 0 := fun i =>
      (coi_vertex_coef_zero_or_one h_coi i z).resolve_right (h_no i)
    have : ∑ i : Fin m, (e' i) (.id z) = 0 :=
      Finset.sum_eq_zero (fun i _ => h_all_zero i)
    rw [this] at h_sum
    norm_num at h_sum
  -- Uniqueness: from orthogonality, two different active i's contradict.
  obtain ⟨i₀, h_i₀⟩ := h_exists
  refine ⟨i₀, h_i₀, ?_⟩
  intros j h_j
  by_contra h_ne
  have h_orth := coi_vertex_coef_orth h_coi (Ne.symm h_ne) z
  -- h_orth : (e' j) (.id z) * (e' i₀) (.id z) = 0
  rw [h_j, h_i₀] at h_orth
  norm_num at h_orth

/-- **Choose the unique active `i` for each `z`.** -/
noncomputable def coi_chooseActive
    {e' : Fin m → pathAlgebraQuotient m} (h_coi : CompleteOrthogonalIdempotents e')
    (z : Fin m) : Fin m :=
  (coi_unique_active_per_z h_coi z).choose

theorem coi_chooseActive_spec
    {e' : Fin m → pathAlgebraQuotient m} (h_coi : CompleteOrthogonalIdempotents e')
    (z : Fin m) :
    (e' (coi_chooseActive h_coi z)) (.id z) = 1 :=
  (coi_unique_active_per_z h_coi z).choose_spec.1

theorem coi_chooseActive_unique
    {e' : Fin m → pathAlgebraQuotient m} (h_coi : CompleteOrthogonalIdempotents e')
    (z : Fin m) (i : Fin m) (h : (e' i) (.id z) = 1) :
    i = coi_chooseActive h_coi z :=
  (coi_unique_active_per_z h_coi z).choose_spec.2 i h

/-- **`coi_chooseActive` is surjective** (when all COI elements are non-zero).

For each `i : Fin m`, since `e' i ≠ 0`, there's some `z` with `(e' i)(.id z) = 1`,
which witnesses `coi_chooseActive z = i`. -/
theorem coi_chooseActive_surjective
    {e' : Fin m → pathAlgebraQuotient m} (h_coi : CompleteOrthogonalIdempotents e')
    (h_nz : ∀ i, e' i ≠ 0) :
    Function.Surjective (coi_chooseActive h_coi) := by
  intro i
  obtain ⟨z, hz⟩ := coi_nonzero_has_active_vertex h_coi (h_nz i)
  refine ⟨z, ?_⟩
  -- coi_chooseActive z is the unique j with (e' j)(.id z) = 1; we have hz : (e' i)(.id z) = 1.
  -- By uniqueness, i = coi_chooseActive z.
  exact (coi_chooseActive_unique h_coi z i hz).symm

/-- **`coi_chooseActive` is bijective.** -/
theorem coi_chooseActive_bijective
    {e' : Fin m → pathAlgebraQuotient m} (h_coi : CompleteOrthogonalIdempotents e')
    (h_nz : ∀ i, e' i ≠ 0) :
    Function.Bijective (coi_chooseActive h_coi) :=
  ⟨(Finite.injective_iff_surjective (f := coi_chooseActive h_coi)).mpr
    (coi_chooseActive_surjective h_coi h_nz),
   coi_chooseActive_surjective h_coi h_nz⟩

/-- **Vertex permutation `σ` extracted from a non-degenerate COI.**

Defined as the inverse of `coi_chooseActive`. For each `v : Fin m`,
`σ v` is the unique `z` such that `(e' v)(.id z) = 1`. -/
noncomputable def coi_vertexPerm
    {e' : Fin m → pathAlgebraQuotient m} (h_coi : CompleteOrthogonalIdempotents e')
    (h_nz : ∀ i, e' i ≠ 0) :
    Equiv.Perm (Fin m) :=
  (Equiv.ofBijective (coi_chooseActive h_coi) (coi_chooseActive_bijective h_coi h_nz)).symm

/-- **σ-defining property: `(e' v)(.id (σ v)) = 1`.** -/
theorem coi_vertexPerm_active
    {e' : Fin m → pathAlgebraQuotient m} (h_coi : CompleteOrthogonalIdempotents e')
    (h_nz : ∀ i, e' i ≠ 0) (v : Fin m) :
    (e' v) (.id (coi_vertexPerm h_coi h_nz v)) = 1 := by
  -- coi_vertexPerm = (Equiv.ofBijective coi_chooseActive _).symm.
  -- So coi_vertexPerm v = z such that coi_chooseActive z = v.
  -- And coi_chooseActive z = v means (e' v)(.id z) = 1.
  have h_eq : coi_chooseActive h_coi (coi_vertexPerm h_coi h_nz v) = v := by
    show (Equiv.ofBijective (coi_chooseActive h_coi) (coi_chooseActive_bijective h_coi h_nz))
           ((Equiv.ofBijective (coi_chooseActive h_coi) (coi_chooseActive_bijective h_coi h_nz)).symm v) = v
    exact Equiv.apply_symm_apply _ v
  -- From coi_chooseActive_spec: (e' (coi_chooseActive z))(.id z) = 1.
  -- Apply with z = coi_vertexPerm v: (e' (coi_chooseActive (coi_vertexPerm v)))(.id (coi_vertexPerm v)) = 1.
  -- And by h_eq: coi_chooseActive (coi_vertexPerm v) = v.
  have h_spec := coi_chooseActive_spec h_coi (coi_vertexPerm h_coi h_nz v)
  rw [h_eq] at h_spec
  exact h_spec

/-- **σ-defining property: `(e' v)(.id z) = 1 ↔ z = σ v`.** -/
theorem coi_vertexPerm_iff
    {e' : Fin m → pathAlgebraQuotient m} (h_coi : CompleteOrthogonalIdempotents e')
    (h_nz : ∀ i, e' i ≠ 0) (v z : Fin m) :
    (e' v) (.id z) = 1 ↔ z = coi_vertexPerm h_coi h_nz v := by
  constructor
  · intro h
    -- (e' v)(.id z) = 1 ⟹ v = coi_chooseActive z (by coi_chooseActive_unique).
    have h_v : v = coi_chooseActive h_coi z := coi_chooseActive_unique h_coi z v h
    -- coi_vertexPerm = (Equiv.ofBijective coi_chooseActive _).symm
    -- So coi_vertexPerm v = z requires coi_chooseActive z = v.
    -- We have v = coi_chooseActive z (from h_v), so coi_chooseActive z = v.
    show z = (Equiv.ofBijective (coi_chooseActive h_coi) (coi_chooseActive_bijective h_coi h_nz)).symm v
    rw [Equiv.eq_symm_apply]
    exact h_v.symm
  · intro h_eq
    rw [h_eq]
    exact coi_vertexPerm_active h_coi h_nz v

/-- **σ-defining property: `(e' v)(.id z) = if z = σ v then 1 else 0`.** -/
theorem coi_vertexPerm_eval
    {e' : Fin m → pathAlgebraQuotient m} (h_coi : CompleteOrthogonalIdempotents e')
    (h_nz : ∀ i, e' i ≠ 0) (v z : Fin m) :
    (e' v) (.id z) = if z = coi_vertexPerm h_coi h_nz v then 1 else 0 := by
  by_cases h : z = coi_vertexPerm h_coi h_nz v
  · rw [if_pos h, h]; exact coi_vertexPerm_active h_coi h_nz v
  · rw [if_neg h]
    -- Use binary property: either 0 or 1, and ≠ 1 (since 1 would imply z = σv).
    rcases coi_vertex_coef_zero_or_one h_coi v z with h_zero | h_one
    · exact h_zero
    · exact absurd ((coi_vertexPerm_iff h_coi h_nz v z).mp h_one) h

-- ============================================================================
-- Layer 6b.3 — Conjugating element `j` and the conjugation identity.
-- ============================================================================

variable {e' : Fin m → pathAlgebraQuotient m} {h_coi : CompleteOrthogonalIdempotents e'}
  {h_nz : ∀ i, e' i ≠ 0}

/-- **The conjugating element `j`** for the Wedderburn–Mal'cev construction.

`j := -∑_{(w, s)} (e' w)(.edge (σ w) s) • α(σ w, s)`.

Each summand is `c · α(σ w, s)` for some scalar `c` and arrow basis
element. By the construction below, `(1 + j) * e_{σ v} * (1 - j) = e' v`. -/
noncomputable def coi_conjugator
    (h_coi : CompleteOrthogonalIdempotents e') (h_nz : ∀ i, e' i ≠ 0) :
    pathAlgebraQuotient m :=
  -∑ p : Fin m × Fin m,
    (e' p.1) (.edge (coi_vertexPerm h_coi h_nz p.1) p.2) •
    arrowElement m (coi_vertexPerm h_coi h_nz p.1) p.2

/-- **`coi_conjugator` lies in the path algebra radical.** -/
theorem coi_conjugator_mem_radical
    (h_coi : CompleteOrthogonalIdempotents e') (h_nz : ∀ i, e' i ≠ 0) :
    coi_conjugator h_coi h_nz ∈ pathAlgebraRadical m := by
  show -(∑ p : Fin m × Fin m, _) ∈ _
  rw [show -(∑ p : Fin m × Fin m, _) =
          (-1 : ℚ) • (∑ p : Fin m × Fin m,
            (e' p.1) (.edge (coi_vertexPerm h_coi h_nz p.1) p.2) •
              arrowElement m (coi_vertexPerm h_coi h_nz p.1) p.2)
       from by rw [neg_smul, one_smul]]
  apply Submodule.smul_mem
  apply Submodule.sum_mem
  intros p _
  apply Submodule.smul_mem
  exact arrowElement_mem_pathAlgebraRadical m _ _

/-- **`coi_conjugator` has zero `.id` components** (it is a sum of arrows). -/
theorem coi_conjugator_apply_id
    (h_coi : CompleteOrthogonalIdempotents e') (h_nz : ∀ i, e' i ≠ 0)
    (w : Fin m) :
    coi_conjugator h_coi h_nz (.id w) = 0 := by
  unfold coi_conjugator
  -- Goal: (-∑ p, ...) (.id w) = 0
  -- Push neg through, then push application through sum.
  show -((∑ p : Fin m × Fin m,
            (e' p.1) (.edge (coi_vertexPerm h_coi h_nz p.1) p.2) •
              arrowElement m (coi_vertexPerm h_coi h_nz p.1) p.2) (.id w)) = 0
  rw [sum_pathAlgQ_apply]
  rw [Finset.sum_eq_zero (fun p _ => ?_)]
  · simp
  · -- Each summand: (c • α(σp.1, p.2)) (.id w) = c * α(σp.1, p.2)(.id w) = c * 0 = 0.
    show (e' p.1) (.edge (coi_vertexPerm h_coi h_nz p.1) p.2) *
         arrowElement m (coi_vertexPerm h_coi h_nz p.1) p.2 (.id w) = 0
    rw [arrowElement_apply_id, mul_zero]

/-- **Compute `coi_conjugator (.edge u t) = -(e' (σ⁻¹ u)) (.edge u t)`.**

Only the (w, s) = (σ⁻¹ u, t) term contributes, since `α(σ w, s)(.edge u t) = 1`
iff `σ w = u ∧ s = t`. -/
theorem coi_conjugator_apply_edge
    (h_coi : CompleteOrthogonalIdempotents e') (h_nz : ∀ i, e' i ≠ 0)
    (u t : Fin m) :
    coi_conjugator h_coi h_nz (.edge u t) =
    -(e' ((coi_vertexPerm h_coi h_nz).symm u)) (.edge u t) := by
  set σ := coi_vertexPerm h_coi h_nz
  show (-∑ p : Fin m × Fin m,
            (e' p.1) (.edge (σ p.1) p.2) • arrowElement m (σ p.1) p.2) (.edge u t) =
       -(e' (σ.symm u)) (.edge u t)
  rw [show (-(∑ p : Fin m × Fin m,
              (e' p.1) (.edge (σ p.1) p.2) • arrowElement m (σ p.1) p.2)) (.edge u t) =
           -(∑ p : Fin m × Fin m,
              (e' p.1) (.edge (σ p.1) p.2) • arrowElement m (σ p.1) p.2) (.edge u t)
       from rfl]
  rw [show ((∑ p : Fin m × Fin m,
              (e' p.1) (.edge (σ p.1) p.2) • arrowElement m (σ p.1) p.2) (.edge u t) : ℚ) =
           ∑ p : Fin m × Fin m,
              ((e' p.1) (.edge (σ p.1) p.2) • arrowElement m (σ p.1) p.2) (.edge u t)
       from sum_pathAlgQ_apply _ _ _]
  congr 1
  -- Goal: ∑ p, (e' p.1)(.edge (σ p.1) p.2) * α(σ p.1, p.2)(.edge u t) = (e' (σ.symm u))(.edge u t)
  -- Only p = (σ.symm u, t) contributes a non-zero term.
  rw [Finset.sum_eq_single (σ.symm u, t)]
  · -- Main term
    show ((e' (σ.symm u)) (.edge (σ (σ.symm u)) t) •
            arrowElement m (σ (σ.symm u)) t) (.edge u t) =
         (e' (σ.symm u)) (.edge u t)
    rw [Equiv.apply_symm_apply σ u]
    show (e' (σ.symm u)) (.edge u t) * (arrowElement m u t (.edge u t)) =
         (e' (σ.symm u)) (.edge u t)
    rw [arrowElement_apply_edge]
    simp
  · -- Other terms vanish.
    intros p _ h_ne
    show ((e' p.1) (.edge (σ p.1) p.2) • arrowElement m (σ p.1) p.2) (.edge u t) = 0
    show (e' p.1) (.edge (σ p.1) p.2) * (arrowElement m (σ p.1) p.2 (.edge u t)) = 0
    rw [arrowElement_apply_edge]
    -- if (σ p.1 = u ∧ p.2 = t) then 1 else 0
    by_cases h_match : σ p.1 = u ∧ p.2 = t
    · -- Then σ p.1 = u ⟹ p.1 = σ.symm u, AND p.2 = t. So p = (σ.symm u, t), contradicting h_ne.
      exfalso
      apply h_ne
      have h1 : p.1 = σ.symm u := by
        rw [← Equiv.symm_apply_apply σ p.1, h_match.1]
      have h2 : p.2 = t := h_match.2
      ext <;> simp_all
    · rw [if_neg h_match, mul_zero]
  · intro h; exact absurd (Finset.mem_univ _) h

-- ============================================================================
-- Layer 6b.3 — Pointwise computation of (1 + j) * e_{σv} * (1 - j).
-- ============================================================================

/-- **Self-loop coefficient is 0 in any idempotent at the active vertex.**

For an idempotent `b` with `b(.id z) = 1`, the self-loop
`b(.edge z z) = 0` (from `2X = X` ⟹ `X = 0`). -/
theorem pathAlgebra_idempotent_self_loop_zero
    (b : pathAlgebraQuotient m) (h_idem : IsIdempotentElem b) {z : Fin m}
    (h_active : b (.id z) = 1) :
    b (.edge z z) = 0 := by
  -- Idempotency: b² = b. Apply at .edge z z.
  have h_idem' : pathAlgebraMul m b b = b := h_idem
  have h_eval : pathAlgebraMul m b b (.edge z z) = b (.edge z z) := by rw [h_idem']
  rw [pathAlgebraMul_apply_edge] at h_eval
  -- h_eval : b(.id z) * b(.edge z z) + b(.edge z z) * b(.id z) = b(.edge z z)
  rw [h_active, one_mul, mul_one] at h_eval
  -- h_eval : b(.edge z z) + b(.edge z z) = b(.edge z z)
  linarith

/-- **Off-diagonal arrow coefficient vanishes when both endpoints are non-active.** -/
theorem pathAlgebra_idempotent_offdiag_arrow_zero
    (b : pathAlgebraQuotient m) (h_idem : IsIdempotentElem b) {u t : Fin m}
    (h_u : b (.id u) = 0) (h_t : b (.id t) = 0) :
    b (.edge u t) = 0 := by
  have h_idem' : pathAlgebraMul m b b = b := h_idem
  have h_eval : pathAlgebraMul m b b (.edge u t) = b (.edge u t) := by rw [h_idem']
  rw [pathAlgebraMul_apply_edge, h_u, h_t, zero_mul, mul_zero, zero_add] at h_eval
  exact h_eval.symm

/-- **Cross-COI orthogonality at .edge:**
`(e' v)(.edge u t) + (e' (σ⁻¹u))(.edge u t) = 0` when `t = σv` and `u ≠ σv`.

Derived from `e' (σ⁻¹u) * e' v = 0` (orthogonality, since v ≠ σ⁻¹u under
`u ≠ σv`), evaluated at `.edge u t` via `pathAlgebraMul_apply_edge`. -/
theorem coi_cross_arrow_compat
    (h_coi : CompleteOrthogonalIdempotents e') (h_nz : ∀ i, e' i ≠ 0)
    {v : Fin m} {u t : Fin m}
    (h_t : t = coi_vertexPerm h_coi h_nz v)
    (h_u_ne : u ≠ coi_vertexPerm h_coi h_nz v) :
    (e' v) (.edge u t) =
    -(e' ((coi_vertexPerm h_coi h_nz).symm u)) (.edge u t) := by
  set σ := coi_vertexPerm h_coi h_nz
  -- σ.symm u ≠ v: if σ.symm u = v, then u = σ v, contradicting h_u_ne.
  have h_ne : σ.symm u ≠ v := by
    intro h_eq
    apply h_u_ne
    rw [← Equiv.apply_symm_apply σ u, h_eq]
  -- Use orthogonality: e' (σ.symm u) * e' v = 0.
  have h_orth : e' (σ.symm u) * e' v = 0 := h_coi.ortho h_ne
  -- Evaluate at .edge u t.
  have h_eval : (pathAlgebraMul m (e' (σ.symm u)) (e' v)) (.edge u t) =
                (0 : pathAlgebraQuotient m) (.edge u t) := by
    show (e' (σ.symm u) * e' v) (.edge u t) = (0 : pathAlgebraQuotient m) (.edge u t)
    rw [h_orth]
  rw [pathAlgebraMul_apply_edge] at h_eval
  -- h_eval : (e' (σ.symm u))(.id u) * (e' v)(.edge u t) +
  --          (e' (σ.symm u))(.edge u t) * (e' v)(.id t) = 0
  -- (e' (σ.symm u))(.id u) = 1 (by σ-defining property: σ.symm u maps to u).
  have h1 : (e' (σ.symm u)) (.id u) = 1 := by
    have := coi_vertexPerm_active h_coi h_nz (σ.symm u)
    rw [Equiv.apply_symm_apply] at this
    exact this
  -- (e' v)(.id t) = 1 (from h_t : t = σv).
  have h2 : (e' v) (.id t) = 1 := by
    rw [h_t]; exact coi_vertexPerm_active h_coi h_nz v
  rw [h1, h2, one_mul, mul_one] at h_eval
  -- h_eval : (e' v)(.edge u t) + (e' (σ.symm u))(.edge u t) = (0 : pathAlgebraQuotient m)(.edge u t)
  show (e' v) (.edge u t) = -(e' (σ.symm u)) (.edge u t)
  have hzero : (0 : pathAlgebraQuotient m) (.edge u t) = 0 := rfl
  rw [hzero] at h_eval
  linarith

-- ============================================================================
-- Layer 6b.3 — Main conjugation identity.
-- ============================================================================

/-- **The Wedderburn–Mal'cev conjugation identity.**

For a non-degenerate complete orthogonal idempotent decomposition `e'`,
the inner conjugation by `1 + j` (where `j` is the explicit conjugator
`coi_conjugator`) maps the canonical vertex idempotent at `σ v` back to
`e' v`. -/
theorem coi_conjugation_identity
    (h_coi : CompleteOrthogonalIdempotents e') (h_nz : ∀ i, e' i ≠ 0)
    (v : Fin m) :
    (1 + coi_conjugator h_coi h_nz) *
      vertexIdempotent m (coi_vertexPerm h_coi h_nz v) *
      (1 - coi_conjugator h_coi h_nz) = e' v := by
  -- Step 1: simplify via innerAut_simplified.
  have h_jR : coi_conjugator h_coi h_nz ∈ pathAlgebraRadical m :=
    coi_conjugator_mem_radical h_coi h_nz
  rw [innerAut_simplified m _ h_jR]
  -- Goal: vertexIdempotent m (σ v) + j * vertexIdempotent m (σ v)
  --       - vertexIdempotent m (σ v) * j = e' v
  -- Step 2: prove pointwise.
  funext c
  cases c with
  | id w =>
    show (vertexIdempotent m (coi_vertexPerm h_coi h_nz v) +
          pathAlgebraMul m (coi_conjugator h_coi h_nz)
            (vertexIdempotent m (coi_vertexPerm h_coi h_nz v)) -
          pathAlgebraMul m (vertexIdempotent m (coi_vertexPerm h_coi h_nz v))
            (coi_conjugator h_coi h_nz)) (.id w) = (e' v) (.id w)
    show vertexIdempotent m (coi_vertexPerm h_coi h_nz v) (.id w) +
         pathAlgebraMul m (coi_conjugator h_coi h_nz)
           (vertexIdempotent m (coi_vertexPerm h_coi h_nz v)) (.id w) -
         pathAlgebraMul m (vertexIdempotent m (coi_vertexPerm h_coi h_nz v))
           (coi_conjugator h_coi h_nz) (.id w) =
         (e' v) (.id w)
    rw [pathAlgebraMul_apply_id, pathAlgebraMul_apply_id]
    rw [coi_conjugator_apply_id]
    rw [zero_mul, mul_zero, add_zero, sub_zero]
    rw [vertexIdempotent_apply_id, coi_vertexPerm_eval h_coi h_nz v w]
    by_cases h : coi_vertexPerm h_coi h_nz v = w
    · rw [if_pos h, h, if_pos rfl]
    · rw [if_neg h, if_neg (fun h_eq => h h_eq.symm)]
  | edge u t =>
    show (vertexIdempotent m (coi_vertexPerm h_coi h_nz v) +
          pathAlgebraMul m (coi_conjugator h_coi h_nz)
            (vertexIdempotent m (coi_vertexPerm h_coi h_nz v)) -
          pathAlgebraMul m (vertexIdempotent m (coi_vertexPerm h_coi h_nz v))
            (coi_conjugator h_coi h_nz)) (.edge u t) = (e' v) (.edge u t)
    show vertexIdempotent m (coi_vertexPerm h_coi h_nz v) (.edge u t) +
         pathAlgebraMul m (coi_conjugator h_coi h_nz)
           (vertexIdempotent m (coi_vertexPerm h_coi h_nz v)) (.edge u t) -
         pathAlgebraMul m (vertexIdempotent m (coi_vertexPerm h_coi h_nz v))
           (coi_conjugator h_coi h_nz) (.edge u t) =
         (e' v) (.edge u t)
    rw [pathAlgebraMul_apply_edge, pathAlgebraMul_apply_edge]
    rw [coi_conjugator_apply_id, zero_mul, zero_add]
    rw [coi_conjugator_apply_id, mul_zero, add_zero]
    rw [vertexIdempotent_apply_edge, vertexIdempotent_apply_id, vertexIdempotent_apply_id]
    rw [coi_conjugator_apply_edge h_coi h_nz u t]
    -- Goal:
    -- 0 + (-(e' (σ.symm u))(.edge u t)) * (if σv = t then 1 else 0) -
    -- ((if σv = u then 1 else 0) * (-(e' (σ.symm u))(.edge u t))) = (e' v)(.edge u t)
    rw [zero_add]
    by_cases hu : coi_vertexPerm h_coi h_nz v = u
    · by_cases ht : coi_vertexPerm h_coi h_nz v = t
      · -- σv = u and σv = t (so u = t = σv).
        rw [if_pos hu, if_pos ht]
        ring_nf
        -- Goal: 0 = (e' v)(.edge u t) for u = t = σv (self-loop).
        have h_ut : u = t := by rw [← hu, ht]
        subst h_ut
        have h_uσv : u = coi_vertexPerm h_coi h_nz v := hu.symm
        subst h_uσv
        rw [pathAlgebra_idempotent_self_loop_zero (e' v) (h_coi.idem v)
              (coi_vertexPerm_active h_coi h_nz v)]
      · -- σv = u, σv ≠ t.
        rw [if_pos hu, if_neg ht]
        ring_nf
        -- Goal: (e' (σ.symm u))(.edge u t) = (e' v)(.edge u t)
        have h_v : (coi_vertexPerm h_coi h_nz).symm u = v := by
          rw [← hu]; exact Equiv.symm_apply_apply _ v
        rw [h_v]
    · by_cases ht : coi_vertexPerm h_coi h_nz v = t
      · -- σv ≠ u, σv = t.
        rw [if_neg hu, if_pos ht]
        ring_nf
        -- Goal: -(e' (σ.symm u))(.edge u t) = (e' v)(.edge u t)
        rw [coi_cross_arrow_compat h_coi h_nz ht.symm (fun h => hu h.symm)]
      · -- σv ≠ u, σv ≠ t.
        rw [if_neg hu, if_neg ht]
        ring_nf
        -- Goal: 0 = (e' v)(.edge u t) (off-diag arrow with non-active endpoints).
        have h_u : (e' v) (.id u) = 0 := by
          rw [coi_vertexPerm_eval h_coi h_nz]
          rw [if_neg (fun h_eq => hu h_eq.symm)]
        have h_t : (e' v) (.id t) = 0 := by
          rw [coi_vertexPerm_eval h_coi h_nz]
          rw [if_neg (fun h_eq => ht h_eq.symm)]
        rw [pathAlgebra_idempotent_offdiag_arrow_zero (e' v) (h_coi.idem v) h_u h_t]

-- ============================================================================
-- Layer 6b.3 — Headline: Wedderburn–Mal'cev conjugacy for `F[Q_G] / J²`.
-- ============================================================================

/-- **Wedderburn–Mal'cev conjugacy for `F[Q_G] / J²` (HEADLINE THEOREM).**

For any complete orthogonal idempotent decomposition `e' : Fin m →
pathAlgebraQuotient m` with each `e' v ≠ 0`, there exist a vertex
permutation `σ : Equiv.Perm (Fin m)` and a radical element
`j ∈ pathAlgebraRadical m` such that the inner conjugation by `1 + j`
maps each canonical vertex idempotent `e_{σ v}` to `e' v`:
```
(1 + j) * vertexIdempotent m (σ v) * (1 - j) = e' v   for all v.
```

This is the fully-discharged form of the Wedderburn–Mal'cev structure
theorem for the radical-2 truncated path algebra. The σ and j are
constructed concretely via:
* `σ := coi_vertexPerm h_coi h_nz` — the unique vertex with active
  `.id`-coordinate per COI element (built from the binary
  vertex-coefficient structure).
* `j := coi_conjugator h_coi h_nz` — the explicit sum
  `-∑_{w, s} (e' w)(.edge (σ w) s) • α(σ w, s)`. -/
theorem wedderburn_malcev_conjugacy (m : ℕ)
    (e' : Fin m → pathAlgebraQuotient m)
    (h_coi : CompleteOrthogonalIdempotents e')
    (h_nz : ∀ v, e' v ≠ 0) :
    ∃ (σ : Equiv.Perm (Fin m)) (j : pathAlgebraQuotient m),
      j ∈ pathAlgebraRadical m ∧
      ∀ v : Fin m,
        (1 + j) * vertexIdempotent m (σ v) * (1 - j) = e' v :=
  ⟨coi_vertexPerm h_coi h_nz, coi_conjugator h_coi h_nz,
   coi_conjugator_mem_radical h_coi h_nz,
   coi_conjugation_identity h_coi h_nz⟩

-- ============================================================================
-- Phase F starter — AlgEquiv-derived vertex permutation (consumes WM).
-- ============================================================================

/-- **AlgEquiv-derived COI from `vertexIdempotent`.**

For any `AlgEquiv φ` on `pathAlgebraQuotient m`, the family
`φ ∘ vertexIdempotent` is a complete orthogonal idempotent decomposition. -/
theorem algEquiv_image_vertexIdempotent_COI (m : ℕ)
    (φ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m) :
    CompleteOrthogonalIdempotents (φ ∘ vertexIdempotent m) :=
  AlgEquiv_preserves_completeOrthogonalIdempotents φ
    (vertexIdempotent_completeOrthogonalIdempotents m)

/-- **AlgEquiv preserves non-zero vertex idempotents.**

`φ (vertexIdempotent v) ≠ 0` because `φ` is injective and `vertexIdempotent v ≠ 0`. -/
theorem algEquiv_image_vertexIdempotent_ne_zero (m : ℕ)
    (φ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m) (v : Fin m) :
    φ (vertexIdempotent m v) ≠ 0 := by
  intro h
  have h_inj : Function.Injective φ := φ.injective
  have h_zero : vertexIdempotent m v = 0 := by
    apply h_inj
    rw [h, map_zero]
  exact vertexIdempotent_ne_zero m v h_zero

/-- **Phase F starter (Layer 9.1): vertex permutation from any AlgEquiv.**

Given an `AlgEquiv` on the path algebra, there exists a vertex
permutation `σ` and a radical element `j` such that the AlgEquiv
maps each canonical vertex idempotent to the inner-conjugate
of `vertexIdempotent (σ v)` by `1 + j`:
```
φ (vertexIdempotent v) = (1 + j) * vertexIdempotent (σ v) * (1 - j).
```

This is the headline corollary of Wedderburn–Mal'cev applied to the
COI `φ ∘ vertexIdempotent`. It is the entry point for Phase F's
σ-extraction from a `tensorContract`-induced AlgEquiv. -/
theorem algEquiv_extractVertexPerm (m : ℕ)
    (φ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m) :
    ∃ (σ : Equiv.Perm (Fin m)) (j : pathAlgebraQuotient m),
      j ∈ pathAlgebraRadical m ∧
      ∀ v : Fin m,
        (1 + j) * vertexIdempotent m (σ v) * (1 - j) = φ (vertexIdempotent m v) :=
  wedderburn_malcev_conjugacy m (φ ∘ vertexIdempotent m)
    (algEquiv_image_vertexIdempotent_COI m φ)
    (algEquiv_image_vertexIdempotent_ne_zero m φ)

end GrochowQiao
end Orbcrypt
