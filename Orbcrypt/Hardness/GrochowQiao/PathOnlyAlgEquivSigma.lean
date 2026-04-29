/-
Wedderburn–Mal'cev σ-extraction for path-only Subalgebra AlgEquivs
(R-TI Phase 3 / Path B / Sub-task A.6.4).

Given an algebra equivalence `ϕ : ↥(pathOnlyAlgebraSubalgebra m adj₁)
≃ₐ[ℚ] ↥(pathOnlyAlgebraSubalgebra m adj₂)` between two adjacencies'
path-only Subalgebras, this module extracts a vertex permutation σ
that is a graph isomorphism between `(adj₁, adj₂)`, discharging the
research-scope `PathOnlySubalgebraGraphIsoObligation` from
`Discharge.lean`.

The proof reuses the existing WM machinery
(`WedderburnMalcev.lean#wedderburn_malcev_conjugacy`) by composing
ϕ with the canonical inclusions `↥sub_adj_i ↪ pathAlgebraQuotient m`
and observing that:
1. The image family `↑(ϕ (vertexIdempotent_in_sub v))` is a COI in
   `pathAlgebraQuotient m`.
2. WM extracts σ + j with `(1+j) * vertexIdempotent (σ v) * (1-j) =
   ↑(ϕ (vertexIdempotent_in_sub v))`.
3. The structural sandwich identity + J²=0 expansion imply that
   ϕ maps each present arrow `α(u, v) ∈ sub_adj₁` to a *scalar
   multiple* of `α(σ u, σ v) ∈ sub_adj₂`.
4. Since ϕ is injective (and the images are non-zero), σ is a graph
   isomorphism between `(adj₁, adj₂)`.

See `docs/planning/AUDIT_2026-04-28_PHASE_3_PROP_DISCHARGE_PLAN.md`
§ "A.6.4 — Subalgebra σ-extraction" for the work-unit specification.
-/

import Orbcrypt.Hardness.GrochowQiao.PathOnlyAlgebra
import Orbcrypt.Hardness.GrochowQiao.WedderburnMalcev
import Orbcrypt.Hardness.GrochowQiao.AdjacencyInvariance
import Orbcrypt.Hardness.GrochowQiao.Discharge

/-!
# Subalgebra σ-extraction for path-only AlgEquivs

## Public surface

### Path B obligation 2 (UNCONDITIONAL)
* `vertexIdempotentSubalgebra` — vertex idempotent lifted into the
  path-only Subalgebra.
* `vertexIdempotentSubalgebra_completeOrthogonalIdempotents` — the
  family of lifted vertex idempotents is a COI in the Subalgebra.
* `pathOnlySubalgebraAlgEquiv_extractVertexPerm` — σ-extraction
  from a Subalgebra AlgEquiv (the analog of
  `algEquiv_extractVertexPerm` from `WedderburnMalcev.lean`).
* `algEquivLifted_isGraphIso_forward` — the σ extracted from a
  Subalgebra AlgEquiv carries `adj₁`-edges to `adj₂`-edges.
* `pathOnlySubalgebraGraphIsoObligation_discharge` — the headline:
  `PathOnlySubalgebraGraphIsoObligation m` holds unconditionally
  (combines the forward direction at ϕ and ϕ.symm via a
  cardinality-bijection argument).

### Path B obligation 1 (CONDITIONAL on `GrochowQiaoRigidity`)
* `pathOnlyAlgEquiv_of_graph_iso` — constructive AlgEquiv between
  path-only Subalgebras from a graph isomorphism σ.
* `pathOnlyAlgEquivObligation_under_rigidity` — discharges
  `PathOnlyAlgEquivObligation` using `GrochowQiaoRigidity`.
* `grochowQiaoRigidity_via_pathB_chain` — sanity-check that Path B's
  chain composes back to `GrochowQiaoRigidity`'s conclusion.

The two obligations are provably equivalent to `GrochowQiaoRigidity`
modulo the unconditional content (Path B obligation 2).  Discharging
`PathOnlyAlgEquivObligation` unconditionally would solve the deep
open problem of Grochow–Qiao SIAM J. Comp. 2023 §4.3.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt
open scoped BigOperators

-- ============================================================================
-- A.6.4.1 — Vertex idempotents lifted into the Subalgebra.
-- ============================================================================

/-- The vertex idempotent `e_v` lifted into the path-only Subalgebra.

Always inhabits the Subalgebra because `vertexIdempotent_mem_presentArrowsSubspace`
holds for all `v` regardless of `adj`. -/
noncomputable def vertexIdempotentSubalgebra
    (m : ℕ) (adj : Fin m → Fin m → Bool) (v : Fin m) :
    ↥(pathOnlyAlgebraSubalgebra m adj) :=
  ⟨vertexIdempotent m v, vertexIdempotent_mem_presentArrowsSubspace m adj v⟩

/-- Underlying value of the lifted vertex idempotent equals the
unlifted vertex idempotent. -/
@[simp] theorem vertexIdempotentSubalgebra_val
    (m : ℕ) (adj : Fin m → Fin m → Bool) (v : Fin m) :
    (vertexIdempotentSubalgebra m adj v).val = vertexIdempotent m v := rfl

/-- The lifted vertex idempotent is non-zero (since the unlifted one
is, and `Subalgebra` subtype is injective). -/
theorem vertexIdempotentSubalgebra_ne_zero
    (m : ℕ) (adj : Fin m → Fin m → Bool) (v : Fin m) :
    vertexIdempotentSubalgebra m adj v ≠ 0 := by
  intro h
  have h_val : (vertexIdempotentSubalgebra m adj v).val = 0 := by
    rw [h]; rfl
  rw [vertexIdempotentSubalgebra_val] at h_val
  exact vertexIdempotent_ne_zero m v h_val

-- ============================================================================
-- A.6.4.2 — COI structure of lifted vertex idempotents in the Subalgebra.
-- ============================================================================

/-- The family of vertex idempotents lifted into the Subalgebra is a
`CompleteOrthogonalIdempotents` structure.

The COI properties (`idem`, `ortho`, `complete`) follow definitionally
from the corresponding properties in `pathAlgebraQuotient m`
(`vertexIdempotent_completeOrthogonalIdempotents`), since the
Subalgebra-multiplication is the restriction of the full-algebra
multiplication. -/
theorem vertexIdempotentSubalgebra_completeOrthogonalIdempotents
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    CompleteOrthogonalIdempotents (vertexIdempotentSubalgebra m adj) where
  idem v := by
    -- IsIdempotentElem (vertexIdempotentSubalgebra m adj v).
    -- Unfolds to (vertexIdempotentSubalgebra m adj v) * (...) = (...).
    apply Subtype.ext
    show vertexIdempotent m v * vertexIdempotent m v = vertexIdempotent m v
    exact (vertexIdempotent_completeOrthogonalIdempotents m).idem v
  ortho := by
    intro v w h_ne
    apply Subtype.ext
    show vertexIdempotent m v * vertexIdempotent m w = 0
    exact (vertexIdempotent_completeOrthogonalIdempotents m).ortho h_ne
  complete := by
    -- ∑ v, vertexIdempotentSubalgebra m adj v = (1 : ↥sub_adj).
    apply Subtype.ext
    -- After Subtype.ext: (∑ v, ...).val = (1 : ↥sub_adj).val = (1 : pathAlgebraQuotient m).
    rw [AddSubmonoidClass.coe_finset_sum]
    -- Goal: ∑ v, (vertexIdempotentSubalgebra m adj v).val = ↑1 = 1.
    show ∑ v : Fin m, vertexIdempotent m v = (1 : pathAlgebraQuotient m)
    exact (vertexIdempotent_completeOrthogonalIdempotents m).complete

-- ============================================================================
-- A.6.4.3 — AlgEquiv preserves COI on Subalgebras.
-- ============================================================================

/-- The image of the lifted vertex idempotents under any Subalgebra
AlgEquiv is a `CompleteOrthogonalIdempotents` family in the target
Subalgebra. -/
theorem algEquiv_image_vertexIdempotentSubalgebra_COI
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (ϕ : ↥(pathOnlyAlgebraSubalgebra m adj₁) ≃ₐ[ℚ]
            ↥(pathOnlyAlgebraSubalgebra m adj₂)) :
    CompleteOrthogonalIdempotents (ϕ ∘ vertexIdempotentSubalgebra m adj₁) :=
  AlgEquiv_preserves_completeOrthogonalIdempotents ϕ
    (vertexIdempotentSubalgebra_completeOrthogonalIdempotents m adj₁)

/-- The lifted COI in the source maps under ϕ to non-zero elements of
the target Subalgebra. -/
theorem algEquiv_image_vertexIdempotentSubalgebra_ne_zero
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (ϕ : ↥(pathOnlyAlgebraSubalgebra m adj₁) ≃ₐ[ℚ]
            ↥(pathOnlyAlgebraSubalgebra m adj₂)) (v : Fin m) :
    ϕ (vertexIdempotentSubalgebra m adj₁ v) ≠ 0 := by
  intro h
  have h_inj : Function.Injective ϕ := ϕ.injective
  have h_zero : vertexIdempotentSubalgebra m adj₁ v = 0 := by
    apply h_inj
    rw [h, map_zero]
  exact vertexIdempotentSubalgebra_ne_zero m adj₁ v h_zero

-- ============================================================================
-- A.6.4.4 — Lifted family in `pathAlgebraQuotient m` and its COI.
-- ============================================================================

/-- The COI image lifted to `pathAlgebraQuotient m` via inclusion.

For a Subalgebra AlgEquiv ϕ, this is the family
  `Fin m → pathAlgebraQuotient m`
sending `v ↦ ↑(ϕ (vertexIdempotentSubalgebra adj₁ v))`. -/
noncomputable def algEquivLifted
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (ϕ : ↥(pathOnlyAlgebraSubalgebra m adj₁) ≃ₐ[ℚ]
            ↥(pathOnlyAlgebraSubalgebra m adj₂))
    (v : Fin m) : pathAlgebraQuotient m :=
  (ϕ (vertexIdempotentSubalgebra m adj₁ v)).val

/-- `algEquivLifted` is a COI in `pathAlgebraQuotient m`.

The Subalgebra inclusion `Subalgebra.val` is an algebra hom
(in particular, preserves multiplication, zero, one), so it
preserves COI structure. -/
theorem algEquivLifted_completeOrthogonalIdempotents
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (ϕ : ↥(pathOnlyAlgebraSubalgebra m adj₁) ≃ₐ[ℚ]
            ↥(pathOnlyAlgebraSubalgebra m adj₂)) :
    CompleteOrthogonalIdempotents (algEquivLifted m adj₁ adj₂ ϕ) where
  idem v := by
    -- IsIdempotentElem (algEquivLifted m adj₁ adj₂ ϕ v).
    show (ϕ (vertexIdempotentSubalgebra m adj₁ v)).val *
          (ϕ (vertexIdempotentSubalgebra m adj₁ v)).val =
        (ϕ (vertexIdempotentSubalgebra m adj₁ v)).val
    have h_idem :
        IsIdempotentElem (ϕ (vertexIdempotentSubalgebra m adj₁ v)) :=
      (algEquiv_image_vertexIdempotentSubalgebra_COI m adj₁ adj₂ ϕ).idem v
    -- h_idem : ϕ (... v) * ϕ (... v) = ϕ (... v) in the Subalgebra.
    -- Take .val of both sides.
    have h := congrArg Subtype.val h_idem
    exact h
  ortho := by
    intro v w h_ne
    show (ϕ (vertexIdempotentSubalgebra m adj₁ v)).val *
          (ϕ (vertexIdempotentSubalgebra m adj₁ w)).val = 0
    have h_ortho :
        ϕ (vertexIdempotentSubalgebra m adj₁ v) *
          ϕ (vertexIdempotentSubalgebra m adj₁ w) = 0 :=
      (algEquiv_image_vertexIdempotentSubalgebra_COI m adj₁ adj₂ ϕ).ortho h_ne
    have h := congrArg Subtype.val h_ortho
    exact h
  complete := by
    -- ∑ v, (ϕ (... v)).val = (1 : pathAlgebraQuotient m).
    show ∑ v : Fin m, (ϕ (vertexIdempotentSubalgebra m adj₁ v)).val =
          (1 : pathAlgebraQuotient m)
    have h_complete :
        ∑ v : Fin m, ϕ (vertexIdempotentSubalgebra m adj₁ v) = 1 :=
      (algEquiv_image_vertexIdempotentSubalgebra_COI m adj₁ adj₂ ϕ).complete
    -- Take .val of both sides.
    have h := congrArg Subtype.val h_complete
    -- h : (∑ v, ϕ ...).val = (1 : ↥sub_adj₂).val = 1 (in pathAlgebraQuotient m).
    -- (∑ v, ϕ ...).val = ∑ v, (ϕ ...).val by coe_finset_sum.
    rw [AddSubmonoidClass.coe_finset_sum] at h
    exact h

/-- Each lifted element is non-zero. -/
theorem algEquivLifted_ne_zero
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (ϕ : ↥(pathOnlyAlgebraSubalgebra m adj₁) ≃ₐ[ℚ]
            ↥(pathOnlyAlgebraSubalgebra m adj₂)) (v : Fin m) :
    algEquivLifted m adj₁ adj₂ ϕ v ≠ 0 := by
  intro h
  unfold algEquivLifted at h
  have h_eq : ϕ (vertexIdempotentSubalgebra m adj₁ v) = 0 := by
    apply Subtype.ext
    rw [h]; rfl
  exact algEquiv_image_vertexIdempotentSubalgebra_ne_zero m adj₁ adj₂ ϕ v h_eq

-- ============================================================================
-- A.6.4.5 — σ-extraction via existing WM machinery.
-- ============================================================================

/-- **Subalgebra σ-extraction.**

For any path-only Subalgebra AlgEquiv `ϕ : ↥sub_adj₁ ≃ₐ ↥sub_adj₂`,
there exists a vertex permutation σ and a radical element j such that
the conjugation `(1 + j) * vertexIdempotent (σ v) * (1 - j)` equals
the lifted image `↑(ϕ (vertexIdempotentSubalgebra v))` for every `v`.

This is the analog of `algEquiv_extractVertexPerm` from
`WedderburnMalcev.lean` for path-only Subalgebra AlgEquivs.  The
proof composes the Subalgebra COI with the inclusion to get a
full-algebra COI, then applies the existing
`wedderburn_malcev_conjugacy`. -/
theorem pathOnlySubalgebraAlgEquiv_extractVertexPerm
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (ϕ : ↥(pathOnlyAlgebraSubalgebra m adj₁) ≃ₐ[ℚ]
            ↥(pathOnlyAlgebraSubalgebra m adj₂)) :
    ∃ (σ : Equiv.Perm (Fin m)) (j : pathAlgebraQuotient m),
      j ∈ pathAlgebraRadical m ∧
      ∀ v : Fin m,
        (1 + j) * vertexIdempotent m (σ v) * (1 - j) =
        (ϕ (vertexIdempotentSubalgebra m adj₁ v)).val :=
  wedderburn_malcev_conjugacy m (algEquivLifted m adj₁ adj₂ ϕ)
    (algEquivLifted_completeOrthogonalIdempotents m adj₁ adj₂ ϕ)
    (algEquivLifted_ne_zero m adj₁ adj₂ ϕ)

-- ============================================================================
-- A.6.4.6 — Arrow element lifted into the Subalgebra.
-- ============================================================================

/-- The arrow element `α(u, v)` lifted into the path-only Subalgebra
when `adj u v = true`. -/
noncomputable def arrowElementSubalgebra
    (m : ℕ) (adj : Fin m → Fin m → Bool) (u v : Fin m)
    (h : adj u v = true) :
    ↥(pathOnlyAlgebraSubalgebra m adj) :=
  ⟨arrowElement m u v, arrowElement_mem_presentArrowsSubspace m adj u v h⟩

/-- Underlying value of the lifted arrow element. -/
@[simp] theorem arrowElementSubalgebra_val
    (m : ℕ) (adj : Fin m → Fin m → Bool) (u v : Fin m)
    (h : adj u v = true) :
    (arrowElementSubalgebra m adj u v h).val = arrowElement m u v := rfl

/-- The lifted arrow element is non-zero. -/
theorem arrowElementSubalgebra_ne_zero
    (m : ℕ) (adj : Fin m → Fin m → Bool) (u v : Fin m)
    (h : adj u v = true) :
    arrowElementSubalgebra m adj u v h ≠ 0 := by
  intro h_zero
  have h_val : (arrowElementSubalgebra m adj u v h).val = 0 := by
    rw [h_zero]; rfl
  rw [arrowElementSubalgebra_val] at h_val
  have h_at : arrowElement m u v (.edge u v) = (1 : ℚ) := by
    simp [arrowElement]
  rw [h_val] at h_at
  exact one_ne_zero h_at.symm

-- ============================================================================
-- A.6.4.7 — Nilpotent elements (f² = 0) lie in the radical.
-- ============================================================================

/-- **Helper:** if `f² = 0` in `pathAlgebraQuotient m`, then `f` lies
in the path-algebra radical (the span of arrow basis elements).

Proof: `f² = 0` implies `f² (.id w) = 0` for all `w`.  By the
path-algebra multiplication table, `f² (.id w) = (f (.id w))²` (only
the `.id w * .id w = .id w` case contributes).  In `ℚ` (a field),
`x² = 0 ⇒ x = 0`.  So `f (.id w) = 0` for all w, hence `f` is in the
radical (span of arrow elements). -/
theorem nilpotent_mem_pathAlgebraRadical
    (m : ℕ) {f : pathAlgebraQuotient m} (h_sq : f * f = 0) :
    f ∈ pathAlgebraRadical m := by
  -- Show f = pathAlgebra_arrowPart f (which is in the radical).
  rw [show f = pathAlgebra_vertexPart m f + pathAlgebra_arrowPart m f from
        pathAlgebra_decompose_radical m f]
  apply Submodule.add_mem
  · -- vertex_part is in the radical iff it's zero.
    -- vertex_part f = ∑ v, f(.id v) • vertexIdempotent v.
    -- For f² = 0, each f(.id v) = 0.
    have h_id_zero : ∀ w : Fin m, f (.id w) = 0 := by
      intro w
      -- (f * f) (.id w) = f (.id w) * f (.id w) by `pathAlgebraMul_apply_id`.
      -- f * f = 0 ⇒ (f * f) (.id w) = 0 ⇒ (f (.id w))² = 0 ⇒ f (.id w) = 0.
      have h_sq_at : (f * f) (.id w) = 0 := by rw [h_sq]; rfl
      have h_mul_apply : (f * f) (.id w) = f (.id w) * f (.id w) :=
        pathAlgebraMul_apply_id m f f w
      rw [h_mul_apply] at h_sq_at
      -- h_sq_at : f (.id w) * f (.id w) = 0; in ℚ, this gives f (.id w) = 0.
      exact mul_self_eq_zero.mp h_sq_at
    -- vertex_part f = ∑ v, f(.id v) • vertexIdempotent v = 0.
    have h_vp : pathAlgebra_vertexPart m f = 0 := by
      unfold pathAlgebra_vertexPart
      apply Finset.sum_eq_zero
      intro v _
      rw [h_id_zero v, zero_smul]
    rw [h_vp]
    exact (pathAlgebraRadical m).zero_mem
  · -- arrow_part is in the radical by definition.
    exact pathAlgebra_arrowPart_mem_radical m f

-- ============================================================================
-- A.6.4.8 — Inner-conjugation sandwich on radical elements.
-- ============================================================================

/-- **Inner-conjugation sandwich identity (J² = 0 form).**

For any elements `c, d` and any radical element `j ∈ J`, plus any
radical element `A ∈ J`, the inner-conjugation sandwich simplifies:
```
((1 + j) * c * (1 - j)) * A * ((1 + j) * d * (1 - j)) = c * A * d
```

Proof: by J² = 0, multiplying any radical element by another radical
element on either side gives zero.  The conjugation factors `(1 ± j)`
act as identity on the radical element `A` (since their `j`-components
multiply with `A ∈ J` to give zero). -/
theorem innerAut_sandwich_radical
    (m : ℕ) {j : pathAlgebraQuotient m} (h_j : j ∈ pathAlgebraRadical m)
    {A : pathAlgebraQuotient m} (h_A : A ∈ pathAlgebraRadical m)
    (c d : pathAlgebraQuotient m) :
    ((1 + j) * c * (1 - j)) * A * ((1 + j) * d * (1 - j)) = c * A * d := by
  -- Step 1: ((1+j) c (1-j)) * A = c * A.
  -- (1+j)c(1-j) * A = (1+j) c (1-j) * A.
  -- (1-j) * A = A - j*A. j*A ∈ J*J = 0 (since j, A ∈ J). So (1-j) * A = A.
  -- Then (1+j) * c * A = c*A + j*c*A. j*(c*A) ∈ J*J = 0 (since c*A ∈ J,
  -- because A ∈ J and J is left ideal).
  have h_jA : j * A = 0 := pathAlgebraRadical_mul_radical_eq_zero m h_j h_A
  -- Helper: c * A ∈ J when A ∈ J (radical is a two-sided ideal; closed under
  -- left-multiplication).
  have h_cA : c * A ∈ pathAlgebraRadical m := by
    refine Submodule.span_induction ?_ ?_ ?_ ?_ h_A
    · rintro _ ⟨⟨u, v⟩, rfl⟩
      -- c * α(u, v) ∈ J. Decompose c into vertex + arrow parts.
      rw [pathAlgebra_decompose m c, add_mul]
      apply Submodule.add_mem
      · -- vertexPart * α(u, v) = (∑_w c(.id w) • e_w) * α(u, v)
        rw [Finset.sum_mul]
        apply Submodule.sum_mem
        intros w _
        rw [smul_mul_assoc]
        apply Submodule.smul_mem
        -- e_w * α(u, v) = if w = u then α(u, v) else 0
        show pathAlgebraMul m (vertexIdempotent m w) (arrowElement m u v) ∈ _
        rw [vertexIdempotent_mul_arrowElement]
        by_cases h : w = u
        · rw [if_pos h]; exact arrowElement_mem_pathAlgebraRadical m u v
        · rw [if_neg h]; exact Submodule.zero_mem _
      · -- arrowPart * α(u, v): arrow * arrow = 0.
        rw [Finset.sum_mul]
        apply Submodule.sum_mem
        intros p _
        rw [smul_mul_assoc]
        apply Submodule.smul_mem
        rw [arrow_mul_arrow_eq_zero m p.1 p.2 u v]
        exact Submodule.zero_mem _
    · rw [mul_zero]; exact Submodule.zero_mem _
    · intros x y _ _ hx hy
      rw [mul_add]; exact Submodule.add_mem _ hx hy
    · intros r x _ hx
      rw [mul_smul_comm]; exact Submodule.smul_mem _ _ hx
  -- Left absorption: ((1+j) * c * (1-j)) * A = c * A.
  -- Math: (1-j) * A = A (since j*A = 0), so the LHS reduces to (1+j) * c * A
  -- = c * A + j * (c * A) = c * A (since c * A ∈ J ⇒ j * (c * A) = 0).
  have h_left : ((1 + j) * c * (1 - j)) * A = c * A := by
    have h_step1 : (1 - j) * A = A := by
      rw [sub_mul, one_mul, h_jA, sub_zero]
    rw [show ((1 + j) * c * (1 - j)) * A = (1 + j) * c * ((1 - j) * A) by
        noncomm_ring,
        h_step1,
        show (1 + j) * c * A = c * A + j * (c * A) by noncomm_ring]
    have h_jcA : j * (c * A) = 0 :=
      pathAlgebraRadical_mul_radical_eq_zero m h_j h_cA
    rw [h_jcA, add_zero]
  rw [h_left]
  -- Right absorption: (c * A) * ((1+j) * d * (1-j)) = c * A * d.
  -- `c * A * d ∈ J` because the radical is a two-sided ideal.
  have h_cAd : c * A * d ∈ pathAlgebraRadical m :=
    member_radical_mul_anything_mem_radical m d h_cA
  have h_Aj : A * j = 0 := pathAlgebraRadical_mul_radical_eq_zero m h_A h_j
  have h_step2 : c * A * (1 + j) = c * A := by
    rw [mul_add, mul_one,
        show c * A * j = c * (A * j) by noncomm_ring,
        h_Aj, mul_zero, add_zero]
  rw [show c * A * ((1 + j) * d * (1 - j)) =
        (c * A * (1 + j)) * d * (1 - j) by noncomm_ring,
      h_step2, mul_sub, mul_one]
  have h_cAdj : c * A * d * j = 0 :=
    pathAlgebraRadical_mul_radical_eq_zero m h_cAd h_j
  rw [h_cAdj, sub_zero]

-- ============================================================================
-- A.6.4.9 — ϕ-image of an arrow lives in the radical.
-- ============================================================================

/-- The `(ϕ ...)`-image of a present arrow element, viewed in
`pathAlgebraQuotient m`, lies in the path-algebra radical.

Proof: `α(u, v) * α(u, v) = 0` in sub_adj_1 (J²=0).  ϕ is multiplicative,
so `ϕ(α(u, v))² = ϕ(0) = 0`.  Coercing to pathAlgebraQuotient m, the
underlying value squares to zero.  By `nilpotent_mem_pathAlgebraRadical`,
nilpotent elements lie in the radical. -/
theorem algEquivLifted_arrow_mem_radical
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (ϕ : ↥(pathOnlyAlgebraSubalgebra m adj₁) ≃ₐ[ℚ]
            ↥(pathOnlyAlgebraSubalgebra m adj₂))
    (u v : Fin m) (h : adj₁ u v = true) :
    (ϕ (arrowElementSubalgebra m adj₁ u v h)).val ∈ pathAlgebraRadical m := by
  apply nilpotent_mem_pathAlgebraRadical
  have h_sq : arrowElementSubalgebra m adj₁ u v h *
                arrowElementSubalgebra m adj₁ u v h = 0 := by
    apply Subtype.ext
    show arrowElement m u v * arrowElement m u v = 0
    exact arrow_mul_arrow_eq_zero m u v u v
  have h_ϕ_sq : ϕ (arrowElementSubalgebra m adj₁ u v h) *
                  ϕ (arrowElementSubalgebra m adj₁ u v h) = 0 := by
    rw [← map_mul, h_sq, map_zero]
  exact congrArg Subtype.val h_ϕ_sq

-- ============================================================================
-- A.6.4.10 — Sandwich identity for ϕ-image of arrow.
-- ============================================================================

/-- **Sandwich identity for ϕ-image of arrows.**

For each present arrow `α(u, v) ∈ sub_adj_1`, the `ϕ`-image satisfies
the σ-vertex-sandwich identity:
```
(ϕ(arrowElementSubalgebra u v)).val =
  vertexIdempotent (σ u) * (ϕ(arrowElementSubalgebra u v)).val *
                            vertexIdempotent (σ v)
```
where σ is the WM-extracted vertex permutation.

The proof composes the basis-element sandwich identity
(`α(u, v) = e_u * α(u, v) * e_v`), ϕ-multiplicativity, the WM
conjugation identity, and the inner-conjugation sandwich on radical
elements (`innerAut_sandwich_radical`). -/
theorem algEquivLifted_arrow_sandwich
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (ϕ : ↥(pathOnlyAlgebraSubalgebra m adj₁) ≃ₐ[ℚ]
            ↥(pathOnlyAlgebraSubalgebra m adj₂))
    (σ : Equiv.Perm (Fin m)) (j : pathAlgebraQuotient m)
    (h_j : j ∈ pathAlgebraRadical m)
    (h_wm : ∀ v : Fin m,
        (1 + j) * vertexIdempotent m (σ v) * (1 - j) =
        (ϕ (vertexIdempotentSubalgebra m adj₁ v)).val)
    (u v : Fin m) (h_adj : adj₁ u v = true) :
    (ϕ (arrowElementSubalgebra m adj₁ u v h_adj)).val =
      vertexIdempotent m (σ u) *
        (ϕ (arrowElementSubalgebra m adj₁ u v h_adj)).val *
        vertexIdempotent m (σ v) := by
  -- Step 1: α(u, v) = e_u * α(u, v) * e_v in sub_adj_1.
  have h_sandwich_sub :
      arrowElementSubalgebra m adj₁ u v h_adj =
        vertexIdempotentSubalgebra m adj₁ u *
          arrowElementSubalgebra m adj₁ u v h_adj *
          vertexIdempotentSubalgebra m adj₁ v := by
    apply Subtype.ext
    show arrowElement m u v =
        vertexIdempotent m u * arrowElement m u v * vertexIdempotent m v
    -- This is `arrowElement_sandwich`.
    exact (arrowElement_sandwich m u v).symm
  -- Step 2: Apply ϕ to both sides.
  have h_apply_ϕ :
      ϕ (arrowElementSubalgebra m adj₁ u v h_adj) =
        ϕ (vertexIdempotentSubalgebra m adj₁ u) *
          ϕ (arrowElementSubalgebra m adj₁ u v h_adj) *
          ϕ (vertexIdempotentSubalgebra m adj₁ v) := by
    rw [show ϕ (vertexIdempotentSubalgebra m adj₁ u) *
            ϕ (arrowElementSubalgebra m adj₁ u v h_adj) *
            ϕ (vertexIdempotentSubalgebra m adj₁ v) =
          ϕ (vertexIdempotentSubalgebra m adj₁ u *
              arrowElementSubalgebra m adj₁ u v h_adj *
              vertexIdempotentSubalgebra m adj₁ v) from by
      rw [map_mul, map_mul]]
    rw [← h_sandwich_sub]
  -- Step 3: Take .val of both sides; coercion preserves multiplication.
  have h_val_eq : (ϕ (arrowElementSubalgebra m adj₁ u v h_adj)).val =
      (ϕ (vertexIdempotentSubalgebra m adj₁ u)).val *
        (ϕ (arrowElementSubalgebra m adj₁ u v h_adj)).val *
        (ϕ (vertexIdempotentSubalgebra m adj₁ v)).val := by
    exact congrArg Subtype.val h_apply_ϕ
  -- Step 4: Use WM to substitute (1+j) e_{σ x} (1-j) for (ϕ(... x)).val
  -- on LHS only (which is the version that depends on ϕ-images).
  conv_lhs => rw [h_val_eq, ← h_wm u, ← h_wm v]
  -- Goal: ((1+j) * e_{σu} * (1-j)) * A * ((1+j) * e_{σv} * (1-j)) =
  --       e_{σu} * A * e_{σv}
  -- where A := (ϕ(arrowElementSubalgebra u v h_adj)).val ∈ J.
  exact innerAut_sandwich_radical m h_j
    (algEquivLifted_arrow_mem_radical m adj₁ adj₂ ϕ u v h_adj)
    (vertexIdempotent m (σ u)) (vertexIdempotent m (σ v))

-- ============================================================================
-- A.6.4.11 — Radical elements vanish at vertex coordinates.
-- ============================================================================

/-- For any radical element `A ∈ pathAlgebraRadical m`, `A(.id z) = 0`.

The radical is spanned by arrow elements `α(u, v)`, and `α(u, v)(.id z) = 0`
for every `z`.  Span induction extends this to all radical elements. -/
theorem radical_apply_id_eq_zero
    (m : ℕ) {A : pathAlgebraQuotient m} (h_A : A ∈ pathAlgebraRadical m)
    (z : Fin m) : A (.id z) = 0 := by
  refine Submodule.span_induction ?_ ?_ ?_ ?_ h_A
  · rintro _ ⟨⟨u, v⟩, rfl⟩
    -- arrowElement m u v (.id z) = 0
    rfl
  · -- 0 (.id z) = 0
    rfl
  · intros x y _ _ hx hy
    -- (x + y) (.id z) = x (.id z) + y (.id z).
    show x (.id z) + y (.id z) = 0
    rw [hx, hy, add_zero]
  · intros r x _ hx
    -- (r • x) (.id z) = r * x (.id z) = r * 0 = 0.
    show r * x (.id z) = 0
    rw [hx, mul_zero]

-- ============================================================================
-- A.6.4.12 — Sandwich-to-arrow-scalar reduction.
-- ============================================================================

/-- **Sandwich identity for radical elements collapses to a scalar
multiple of an arrow basis element.**

For any `A ∈ pathAlgebraRadical m` and any vertices `x, y`,
```
e_x * A * e_y = A(.edge x y) • α(x, y).
```

Proof: pointwise on `c : QuiverArrow m`.
* For `c = .id z`: both sides evaluate to 0 (`A(.id _) = 0` since
  `A ∈ J`; `α(x, y)(.id _) = 0` always).
* For `c = .edge u w`: by `mul_vertexIdempotent_apply_edge` then
  `vertexIdempotent_mul_apply_edge`, LHS = `if x = u ∧ y = w then
  A(.edge u w) else 0`.  RHS = `A(.edge x y) * α(x, y)(.edge u w) =
  A(.edge x y) * (if x = u ∧ y = w then 1 else 0)`.  When both
  conditions match, `A(.edge x y) = A(.edge u w)`. -/
theorem radical_sandwich_eq_arrow_scalar
    (m : ℕ) {A : pathAlgebraQuotient m} (h_A : A ∈ pathAlgebraRadical m)
    (x y : Fin m) :
    vertexIdempotent m x * A * vertexIdempotent m y =
      A (.edge x y) • arrowElement m x y := by
  funext c
  cases c with
  | id z =>
    -- LHS: (e_x * A * e_y) (.id z) — apply `mul_vertexIdempotent_apply_id`.
    -- RHS: (c • α(x, y)) (.id z) = c * α(x, y) (.id z) = c * 0 = 0.
    show pathAlgebraMul m (pathAlgebraMul m (vertexIdempotent m x) A)
            (vertexIdempotent m y) (.id z) =
          A (.edge x y) * arrowElement m x y (.id z)
    rw [arrowElement_apply_id, mul_zero]
    rw [mul_vertexIdempotent_apply_id]
    -- Goal: (if y = z then (e_x * A) (.id z) else 0) = 0.
    by_cases hyz : y = z
    · rw [if_pos hyz]
      rw [vertexIdempotent_mul_apply_id]
      -- Goal: (if x = z then A(.id z) else 0) = 0.
      have h_id : A (.id z) = 0 := radical_apply_id_eq_zero m h_A z
      split_ifs <;> [exact h_id; rfl]
    · rw [if_neg hyz]
  | edge u w =>
    -- LHS: (e_x * A * e_y) (.edge u w) — apply
    -- `mul_vertexIdempotent_apply_edge` then `vertexIdempotent_mul_apply_edge`.
    -- RHS: (c • α(x, y)) (.edge u w) = c * α(x, y) (.edge u w).
    show pathAlgebraMul m (pathAlgebraMul m (vertexIdempotent m x) A)
            (vertexIdempotent m y) (.edge u w) =
          A (.edge x y) * arrowElement m x y (.edge u w)
    rw [arrowElement_apply_edge]
    rw [mul_vertexIdempotent_apply_edge]
    by_cases hxu : x = u
    · by_cases hyw : y = w
      · -- Both match.
        rw [if_pos hyw, vertexIdempotent_mul_apply_edge, if_pos hxu,
            if_pos ⟨hxu, hyw⟩, mul_one]
        -- Goal: A(.edge u w) = A(.edge x y).  Substitute via hxu, hyw.
        rw [hxu, hyw]
      · -- y ≠ w.
        rw [if_neg hyw, if_neg (fun h => hyw h.2), mul_zero]
    · -- x ≠ u.
      by_cases hyw : y = w
      · rw [if_pos hyw, vertexIdempotent_mul_apply_edge, if_neg hxu,
            if_neg (fun h => hxu h.1), mul_zero]
      · rw [if_neg hyw, if_neg (fun h => hxu h.1), mul_zero]

-- ============================================================================
-- A.6.4.13 — ϕ-image of an arrow is a scalar multiple of an arrow.
-- ============================================================================

/-- **ϕ-image of a present arrow is a scalar multiple of `α(σ u, σ v)`.**

Combining `algEquivLifted_arrow_sandwich` with
`radical_sandwich_eq_arrow_scalar`, we get
```
(ϕ(arrowElementSubalgebra u v h)).val =
  (ϕ(arrowElementSubalgebra u v h)).val (.edge (σ u) (σ v)) •
    arrowElement m (σ u) (σ v).
``` -/
theorem algEquivLifted_arrow_eq_scalar
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (ϕ : ↥(pathOnlyAlgebraSubalgebra m adj₁) ≃ₐ[ℚ]
            ↥(pathOnlyAlgebraSubalgebra m adj₂))
    (σ : Equiv.Perm (Fin m)) (j : pathAlgebraQuotient m)
    (h_j : j ∈ pathAlgebraRadical m)
    (h_wm : ∀ v : Fin m,
        (1 + j) * vertexIdempotent m (σ v) * (1 - j) =
        (ϕ (vertexIdempotentSubalgebra m adj₁ v)).val)
    (u v : Fin m) (h_adj : adj₁ u v = true) :
    (ϕ (arrowElementSubalgebra m adj₁ u v h_adj)).val =
      (ϕ (arrowElementSubalgebra m adj₁ u v h_adj)).val (.edge (σ u) (σ v)) •
        arrowElement m (σ u) (σ v) := by
  -- Compose the sandwich identity (LHS = e_{σu} * A * e_{σv}) with
  -- the radical-sandwich-to-arrow-scalar reduction.  Use `conv_lhs` so
  -- the rewrite affects only the bare LHS, not the coefficient on RHS.
  conv_lhs =>
    rw [algEquivLifted_arrow_sandwich m adj₁ adj₂ ϕ σ j h_j h_wm u v h_adj]
  exact radical_sandwich_eq_arrow_scalar m
    (algEquivLifted_arrow_mem_radical m adj₁ adj₂ ϕ u v h_adj) (σ u) (σ v)

-- ============================================================================
-- A.6.4.14 — The scalar coefficient is non-zero.
-- ============================================================================

/-- **The scalar coefficient `(ϕ A).val (.edge (σ u) (σ v))` is non-zero.**

Since `ϕ(arrowElementSubalgebra u v h)` is non-zero (ϕ is injective on
the non-zero `arrowElementSubalgebra`), and the value
`(ϕ(...)).val = c • α(σ u, σ v)`, we have `c • α(σ u, σ v) ≠ 0`,
which forces `c ≠ 0` (since `α(σ u, σ v) ≠ 0`). -/
theorem algEquivLifted_arrow_scalar_ne_zero
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (ϕ : ↥(pathOnlyAlgebraSubalgebra m adj₁) ≃ₐ[ℚ]
            ↥(pathOnlyAlgebraSubalgebra m adj₂))
    (σ : Equiv.Perm (Fin m)) (j : pathAlgebraQuotient m)
    (h_j : j ∈ pathAlgebraRadical m)
    (h_wm : ∀ v : Fin m,
        (1 + j) * vertexIdempotent m (σ v) * (1 - j) =
        (ϕ (vertexIdempotentSubalgebra m adj₁ v)).val)
    (u v : Fin m) (h_adj : adj₁ u v = true) :
    (ϕ (arrowElementSubalgebra m adj₁ u v h_adj)).val (.edge (σ u) (σ v)) ≠ 0 := by
  intro h_zero
  -- (ϕ A).val = 0 • α(σu, σv) = 0, contradicting injectivity of ϕ on
  -- a non-zero `arrowElementSubalgebra`.
  have h_eq := algEquivLifted_arrow_eq_scalar m adj₁ adj₂ ϕ σ j h_j h_wm u v h_adj
  rw [h_zero, zero_smul] at h_eq
  -- (ϕ A).val = 0 ⇒ ϕ A = 0 ⇒ A = 0 (since ϕ is injective).
  have h_sub_zero : ϕ (arrowElementSubalgebra m adj₁ u v h_adj) = 0 := by
    apply Subtype.ext
    rw [h_eq]; rfl
  have h_inj : Function.Injective ϕ := ϕ.injective
  have h_sub_arrow_zero : arrowElementSubalgebra m adj₁ u v h_adj = 0 := by
    apply h_inj
    rw [h_sub_zero, map_zero]
  exact arrowElementSubalgebra_ne_zero m adj₁ u v h_adj h_sub_arrow_zero

-- ============================================================================
-- A.6.4.15 — σ is a graph isomorphism (forward direction).
-- ============================================================================

/-- **Forward direction of graph isomorphism.**

If `adj₁ u v = true`, then `adj₂ (σ u) (σ v) = true`.

Proof: the value `(ϕ(arrowElementSubalgebra u v h)).val` lies in
`presentArrowsSubspace m adj₂` (since ϕ maps into sub_adj_2).  By
`algEquivLifted_arrow_eq_scalar`, this value equals `c • α(σ u, σ v)`
with `c ≠ 0`.  Evaluated at `.edge (σ u) (σ v)`, the value is `c ≠ 0`.
But for any element of `presentArrowsSubspace m adj₂` to be non-zero
at `.edge (σ u) (σ v)`, we need `(.edge (σ u) (σ v)) ∈ presentArrows
m adj₂`, i.e., `adj₂ (σ u) (σ v) = true`. -/
theorem algEquivLifted_isGraphIso_forward
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (ϕ : ↥(pathOnlyAlgebraSubalgebra m adj₁) ≃ₐ[ℚ]
            ↥(pathOnlyAlgebraSubalgebra m adj₂))
    (σ : Equiv.Perm (Fin m)) (j : pathAlgebraQuotient m)
    (h_j : j ∈ pathAlgebraRadical m)
    (h_wm : ∀ v : Fin m,
        (1 + j) * vertexIdempotent m (σ v) * (1 - j) =
        (ϕ (vertexIdempotentSubalgebra m adj₁ v)).val)
    (u v : Fin m) (h_adj : adj₁ u v = true) :
    adj₂ (σ u) (σ v) = true := by
  -- The .val of ϕ-image lies in presentArrowsSubspace m adj₂.
  have h_mem : (ϕ (arrowElementSubalgebra m adj₁ u v h_adj)).val ∈
      presentArrowsSubspace m adj₂ :=
    (ϕ (arrowElementSubalgebra m adj₁ u v h_adj)).property
  -- presentArrowsSubspace = vectors vanishing outside presentArrows m adj₂.
  rw [mem_presentArrowsSubspace_iff] at h_mem
  -- h_mem : ∀ a ∉ presentArrows m adj₂, (ϕ A).val a = 0.
  -- Suppose adj₂ (σ u) (σ v) = false (for contradiction).
  by_contra h_false
  rw [Bool.not_eq_true] at h_false
  -- Then (.edge (σ u) (σ v)) ∉ presentArrows m adj₂.
  have h_not_mem : (.edge (σ u) (σ v) : QuiverArrow m) ∉ presentArrows m adj₂ := by
    intro h_in
    rw [presentArrows_edge_mem_iff] at h_in
    rw [h_false] at h_in
    exact Bool.false_ne_true h_in
  have h_zero := h_mem (.edge (σ u) (σ v)) h_not_mem
  exact algEquivLifted_arrow_scalar_ne_zero m adj₁ adj₂ ϕ σ j h_j h_wm
    u v h_adj h_zero

-- ============================================================================
-- A.6.4.16 — Discharge `PathOnlySubalgebraGraphIsoObligation`.
-- ============================================================================

/-! Note on bidirection: the full graph-iso conclusion `∀ i j, adj₁ i j
= adj₂ (σ i) (σ j)` (both directions, as a Boolean equality) is
delivered by `pathOnlySubalgebraGraphIsoObligation_discharge` below
via a cardinality-bijection argument that combines two applications
of `algEquivLifted_isGraphIso_forward` (one at ϕ and one at ϕ.symm,
each yielding a one-direction implication on present arrows). -/

/-- The Finset of edges of a graph (pairs `(u, v)` with `adj u v = true`). -/
private def edgeFinset (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Finset (Fin m × Fin m) :=
  Finset.univ.filter (fun p => adj p.1 p.2)

private theorem mem_edgeFinset_iff (m : ℕ) (adj : Fin m → Fin m → Bool)
    (p : Fin m × Fin m) :
    p ∈ edgeFinset m adj ↔ adj p.1 p.2 = true := by
  simp [edgeFinset]

/-- The forward map `(u, v) ↦ (σ u, σ v)` is injective. -/
private theorem sigmaProd_injective (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    Function.Injective (fun p : Fin m × Fin m => (σ p.1, σ p.2)) := by
  intros p₁ p₂ h
  -- After `Prod.mk.injEq`, get σ p₁.1 = σ p₂.1 ∧ σ p₁.2 = σ p₂.2.
  rw [Prod.mk.injEq] at h
  obtain ⟨h₁, h₂⟩ := h
  exact Prod.ext (σ.injective h₁) (σ.injective h₂)

/-- **σ-image of `edgeFinset adj₁` lies in `edgeFinset adj₂`** (forward
direction). -/
private theorem sigmaProd_image_subset
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) (σ : Equiv.Perm (Fin m))
    (h_fwd : ∀ u v, adj₁ u v = true → adj₂ (σ u) (σ v) = true) :
    ∀ p ∈ edgeFinset m adj₁,
      (fun q : Fin m × Fin m => (σ q.1, σ q.2)) p ∈ edgeFinset m adj₂ := by
  intro p hp
  rw [mem_edgeFinset_iff] at hp
  rw [mem_edgeFinset_iff]
  exact h_fwd p.1 p.2 hp

/-- **Cardinality of `edgeFinset adj₂` is at least `edgeFinset adj₁`**
under the forward direction. -/
private theorem edgeFinset_card_le
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) (σ : Equiv.Perm (Fin m))
    (h_fwd : ∀ u v, adj₁ u v = true → adj₂ (σ u) (σ v) = true) :
    (edgeFinset m adj₁).card ≤ (edgeFinset m adj₂).card := by
  apply Finset.card_le_card_of_injOn (fun p => (σ p.1, σ p.2))
  · exact sigmaProd_image_subset m adj₁ adj₂ σ h_fwd
  · intros p₁ _ p₂ _
    exact fun h => sigmaProd_injective m σ h

/-- **σ-image equals `edgeFinset adj₂` under equal cardinalities.**

If σ injectively maps `edgeFinset adj₁` into `edgeFinset adj₂` and
the two have equal cardinalities, then the σ-image equals `edgeFinset
adj₂` exactly. -/
private theorem sigmaProd_image_eq
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) (σ : Equiv.Perm (Fin m))
    (h_fwd : ∀ u v, adj₁ u v = true → adj₂ (σ u) (σ v) = true)
    (h_card : (edgeFinset m adj₁).card = (edgeFinset m adj₂).card) :
    (edgeFinset m adj₁).image (fun p => (σ p.1, σ p.2)) = edgeFinset m adj₂ := by
  apply Finset.eq_of_subset_of_card_le
  · -- Image ⊆ edgeFinset adj₂.
    intro q hq
    rw [Finset.mem_image] at hq
    obtain ⟨p, hp, rfl⟩ := hq
    exact sigmaProd_image_subset m adj₁ adj₂ σ h_fwd p hp
  · -- |edgeFinset adj₂| ≤ |image|.
    rw [Finset.card_image_of_injOn]
    · exact h_card.ge
    · intros p₁ _ p₂ _
      exact fun h => sigmaProd_injective m σ h

/-- **Discharge of `PathOnlySubalgebraGraphIsoObligation`.**

Given a Subalgebra AlgEquiv `ϕ : sub_adj₁ ≃ₐ sub_adj₂`, we extract σ
from ϕ via `pathOnlySubalgebraAlgEquiv_extractVertexPerm`, and σ'
from `ϕ.symm`.  The forward direction at ϕ gives `adj₁ u v = true ⇒
adj₂ (σ u) (σ v) = true`; symmetrically at ϕ.symm we get `adj₂ u' v'
= true ⇒ adj₁ (σ' u') (σ' v') = true`.

We avoid identifying σ' = σ⁻¹ by a cardinality argument: the forward
maps give injections `edgeFinset adj₁ ↪ edgeFinset adj₂` and back, so
|adj₁-edges| = |adj₂-edges|.  Combined with σ-injectivity, the
forward map is a *bijection* between the edge sets, which gives the
converse "adj₂ (σ i) (σ j) = true ⇒ adj₁ i j = true". -/
theorem pathOnlySubalgebraGraphIsoObligation_discharge :
    ∀ m : ℕ, Discharge.PathOnlySubalgebraGraphIsoObligation m := by
  intro m adj₁ adj₂ ⟨ϕ⟩
  -- Step 1: Extract σ from ϕ via the WM-based extraction.
  obtain ⟨σ, j, h_j, h_wm⟩ :=
    pathOnlySubalgebraAlgEquiv_extractVertexPerm m adj₁ adj₂ ϕ
  -- Step 2: Extract σ' from ϕ.symm.
  obtain ⟨σ', j', h_j', h_wm'⟩ :=
    pathOnlySubalgebraAlgEquiv_extractVertexPerm m adj₂ adj₁ ϕ.symm
  -- Step 3: Forward direction at ϕ.
  have h_fwd : ∀ u v, adj₁ u v = true → adj₂ (σ u) (σ v) = true := fun u v =>
    algEquivLifted_isGraphIso_forward m adj₁ adj₂ ϕ σ j h_j h_wm u v
  -- Step 4: Forward direction at ϕ.symm.
  have h_inv : ∀ u v, adj₂ u v = true → adj₁ (σ' u) (σ' v) = true := fun u v =>
    algEquivLifted_isGraphIso_forward m adj₂ adj₁ ϕ.symm σ' j' h_j' h_wm' u v
  -- Step 5: Cardinality match via the two forward injections.
  have h_le_12 := edgeFinset_card_le m adj₁ adj₂ σ h_fwd
  have h_le_21 := edgeFinset_card_le m adj₂ adj₁ σ' h_inv
  have h_card : (edgeFinset m adj₁).card = (edgeFinset m adj₂).card :=
    le_antisymm h_le_12 h_le_21
  -- Step 6: Forward injection is a bijection (image = full target).
  have h_image_eq := sigmaProd_image_eq m adj₁ adj₂ σ h_fwd h_card
  -- Step 7: Use σ as the witness; for each (i, j), case on adj₁ i j.
  refine ⟨σ, fun i j => ?_⟩
  -- Goal: adj₁ i j = adj₂ (σ i) (σ j).
  by_cases h_eq : adj₁ i j = true
  · -- adj₁ i j = true; forward direction gives adj₂ (σ i) (σ j) = true.
    rw [h_eq, (h_fwd i j h_eq).symm]
  · -- adj₁ i j = false (via Boolean: ¬= true ⇒ = false).
    rw [Bool.not_eq_true] at h_eq
    -- need: adj₂ (σ i) (σ j) = false  (i.e., not = true).
    by_contra h_ne
    -- h_ne : ¬ adj₁ i j = adj₂ (σ i) (σ j).
    -- After `h_eq`, LHS = false; so ¬ false = adj₂ (σ i) (σ j) means
    -- adj₂ (σ i) (σ j) ≠ false, i.e., = true.
    have h_adj2_true : adj₂ (σ i) (σ j) = true := by
      cases h : adj₂ (σ i) (σ j)
      · exfalso; apply h_ne; rw [h_eq, h]
      · rfl
    -- (σ i, σ j) ∈ edgeFinset adj₂ (since adj₂ (σ i) (σ j) = true).
    have h_in : (σ i, σ j) ∈ edgeFinset m adj₂ := by
      rw [mem_edgeFinset_iff]; exact h_adj2_true
    -- By h_image_eq, (σ i, σ j) is in the image of σ ∘ σ on edgeFinset adj₁.
    rw [← h_image_eq] at h_in
    rw [Finset.mem_image] at h_in
    obtain ⟨⟨u, v⟩, hp_in, hp_eq⟩ := h_in
    -- hp_eq : (σ u, σ v) = (σ i, σ j); injectivity gives (u, v) = (i, j).
    rw [Prod.mk.injEq] at hp_eq
    obtain ⟨h_u, h_v⟩ := hp_eq
    have h_iu : u = i := σ.injective h_u
    have h_jv : v = j := σ.injective h_v
    rw [h_iu, h_jv] at hp_in
    rw [mem_edgeFinset_iff] at hp_in
    -- Contradiction: adj₁ i j = true but h_eq says false.
    rw [h_eq] at hp_in
    exact Bool.false_ne_true hp_in

-- ============================================================================
-- A.6.4.18 — Constructive AlgEquiv between path-only Subalgebras from a
-- graph isomorphism σ.
-- ============================================================================

/-- The σ⁻¹ direction of a graph iso.

If `σ : Equiv.Perm (Fin m)` satisfies `∀ i j, adj₁ i j = adj₂ (σ i) (σ j)`,
then σ⁻¹ satisfies `∀ i j, adj₂ i j = adj₁ (σ⁻¹ i) (σ⁻¹ j)`. -/
private theorem graph_iso_inv (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (σ : Equiv.Perm (Fin m))
    (h_iso : ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) :
    ∀ i j, adj₂ i j = adj₁ (σ⁻¹ i) (σ⁻¹ j) := by
  intro i j
  have := h_iso (σ⁻¹ i) (σ⁻¹ j)
  -- this : adj₁ (σ⁻¹ i) (σ⁻¹ j) = adj₂ (σ (σ⁻¹ i)) (σ (σ⁻¹ j)).
  rw [show σ (σ⁻¹ i) = i from σ.apply_symm_apply i,
      show σ (σ⁻¹ j) = j from σ.apply_symm_apply j] at this
  -- this : adj₁ (σ⁻¹ i) (σ⁻¹ j) = adj₂ i j.
  exact this.symm

/-- **Constructive AlgEquiv between path-only Subalgebras from a
graph iso.**

Given a graph isomorphism σ between adj₁ and adj₂, the algebra
equivalence `quiverPermAlgEquiv m σ` (which acts as σ on basis
elements at the full-algebra level) restricts to an AlgEquiv between
the path-only Subalgebras.  The forward direction maps
`presentArrowsSubspace m adj₁ → presentArrowsSubspace m adj₂` (because
σ is a graph iso, present arrows of adj₁ map to present arrows of
adj₂); the inverse direction uses σ⁻¹ symmetrically. -/
noncomputable def pathOnlyAlgEquiv_of_graph_iso
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (σ : Equiv.Perm (Fin m))
    (h_iso : ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) :
    ↥(pathOnlyAlgebraSubalgebra m adj₁) ≃ₐ[ℚ]
      ↥(pathOnlyAlgebraSubalgebra m adj₂) := by
  -- Use the elementwise membership lemma `quiverPermFun_mem_presentArrowsSubspace`.
  have h_iso_inv := graph_iso_inv m adj₁ adj₂ σ h_iso
  -- Forward map: x ↦ ⟨quiverPermAlgEquiv σ x.val, ...⟩.
  let fwd : ↥(pathOnlyAlgebraSubalgebra m adj₁) →ₐ[ℚ]
              ↥(pathOnlyAlgebraSubalgebra m adj₂) :=
    AlgHom.codRestrict
      (((quiverPermAlgEquiv m σ).toAlgHom).comp
        (pathOnlyAlgebraSubalgebra m adj₁).val)
      (pathOnlyAlgebraSubalgebra m adj₂)
      (fun x =>
        Discharge.quiverPermFun_mem_presentArrowsSubspace
          m σ adj₁ adj₂ h_iso x.val x.property)
  -- Inverse map: y ↦ ⟨quiverPermAlgEquiv σ⁻¹ y.val, ...⟩.
  let inv : ↥(pathOnlyAlgebraSubalgebra m adj₂) →ₐ[ℚ]
              ↥(pathOnlyAlgebraSubalgebra m adj₁) :=
    AlgHom.codRestrict
      (((quiverPermAlgEquiv m σ⁻¹).toAlgHom).comp
        (pathOnlyAlgebraSubalgebra m adj₂).val)
      (pathOnlyAlgebraSubalgebra m adj₁)
      (fun x =>
        Discharge.quiverPermFun_mem_presentArrowsSubspace
          m σ⁻¹ adj₂ adj₁ h_iso_inv x.val x.property)
  refine AlgEquiv.ofAlgHom fwd inv ?_ ?_
  · -- fwd.comp inv = AlgHom.id (i.e., fwd ∘ inv = id at sub_adj_2).
    apply AlgHom.ext
    intro x
    apply Subtype.ext
    -- ((fwd.comp inv) x).val = x.val.
    show quiverPermFun m σ (quiverPermFun m σ⁻¹ x.val) = x.val
    exact quiverPermFun_round_trip' m σ x.val
  · -- inv.comp fwd = AlgHom.id (i.e., inv ∘ fwd = id at sub_adj_1).
    apply AlgHom.ext
    intro x
    apply Subtype.ext
    show quiverPermFun m σ⁻¹ (quiverPermFun m σ x.val) = x.val
    exact quiverPermFun_round_trip m σ x.val

-- ============================================================================
-- A.6.4.19 — Discharge `PathOnlyAlgEquivObligation` from `GrochowQiaoRigidity`.
-- ============================================================================

/-- **Discharge of `PathOnlyAlgEquivObligation` from
`GrochowQiaoRigidity`.**

Under the existing research-scope Prop `GrochowQiaoRigidity` (which
delivers a graph-iso σ from a tensor isomorphism of encoders), the
Path B obligation `PathOnlyAlgEquivObligation` follows by witnessing
the AlgEquiv as `pathOnlyAlgEquiv_of_graph_iso m adj₁ adj₂ σ h_iso`.

**Mathematical relationship.**  Combined with
`pathOnlySubalgebraGraphIsoObligation_discharge` (UNCONDITIONAL via
WM σ-extraction), this discharge shows that
`PathOnlyAlgEquivObligation` is *equivalent* to `GrochowQiaoRigidity`
modulo unconditional content.  The Path B factoring of
`GrochowQiaoRigidity` reduces the research-scope load to a single
named Prop — `PathOnlyAlgEquivObligation` — which is the obligation
carrying the partition-rigidity content of Grochow–Qiao SIAM J.
Comp. 2023 §4.3.

Specifically:
* `PathOnlyAlgEquivObligation` ⇒ `GrochowQiaoRigidity` (via the
  existing `grochowQiaoRigidity_via_path_only_algEquiv_chain` ∘
  `pathOnlySubalgebraGraphIsoObligation_discharge`).
* `GrochowQiaoRigidity` ⇒ `PathOnlyAlgEquivObligation` (via this
  theorem).

So Path B is no harder than Path A in the discharge direction; the
benefit is structural — Path B factors the discharge into smaller
named Props that future research-scope work can target
independently. -/
theorem pathOnlyAlgEquivObligation_under_rigidity
    (h_rig : GrochowQiaoRigidity) :
    ∀ m : ℕ, Discharge.PathOnlyAlgEquivObligation m := by
  intro m adj₁ adj₂ g hg
  have h_iso : AreTensorIsomorphic
      (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂) :=
    ⟨g, hg⟩
  obtain ⟨σ, h_σ⟩ := h_rig m adj₁ adj₂ h_iso
  exact ⟨pathOnlyAlgEquiv_of_graph_iso m adj₁ adj₂ σ h_σ⟩

-- ============================================================================
-- A.6.4.20 — Path B → unconditional Karp reduction (under `GrochowQiaoRigidity`).
-- ============================================================================

/-- **Path B end-to-end discharge of `GrochowQiaoRigidity`** (under
the same hypothesis, sanity-check via the chain composition).

This theorem composes the two Path B obligations into the original
`GrochowQiaoRigidity` statement.  Since Path B's first obligation
(`PathOnlyAlgEquivObligation`) is *itself* equivalent to
`GrochowQiaoRigidity` (modulo the unconditional second obligation),
this composition is essentially a sanity check that the factoring
preserves the conclusion. -/
theorem grochowQiaoRigidity_via_pathB_chain
    (h_rig : GrochowQiaoRigidity) :
    ∀ m : ℕ, ∀ (adj₁ adj₂ : Fin m → Fin m → Bool),
      AreTensorIsomorphic
        (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂) →
      ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j) := by
  intro m
  exact Discharge.grochowQiaoRigidity_via_path_only_algEquiv_chain m
    (pathOnlyAlgEquivObligation_under_rigidity h_rig m)
    (pathOnlySubalgebraGraphIsoObligation_discharge m)

end GrochowQiao
end Orbcrypt
