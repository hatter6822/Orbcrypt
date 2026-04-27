/-
Adjacency invariance via σ-induced AlgEquiv (Stage 5 / T-API-9, R-TI rigidity discharge).

Given a vertex permutation `σ : Equiv.Perm (Fin m)`, this module
proves the structural lemmas connecting the σ-induced AlgEquiv
(`quiverPermAlgEquiv` from Stage 4 T-API-7) to the **adjacency
preservation** property `∀ u v, adj₁ u v = adj₂ (σ u) (σ v)`.

Specifically:

1. **Sandwich identity**: `arrowElement m u v = vertexIdempotent m
   u * arrowElement m u v * vertexIdempotent m v` (an algebraic
   identity in `pathAlgebraQuotient m`).
2. **Inner conjugation fixes arrows**: for `j ∈ pathAlgebraRadical m`,
   `(1 + j) * arrowElement m u v * (1 - j) = arrowElement m u v`
   (uses J²=0).
3. **Arrow-image-iff-graph-iso**: σ is a graph isomorphism between
   `(adj₁, adj₂)` iff the σ-induced AlgEquiv preserves the
   `presentArrows`-supported subspace.
4. **Adjacency preservation**: the σ-action on basis-element arrows
   `arrow uv ↦ arrow (σu)(σv)` directly characterizes graph
   isomorphism.

See `docs/planning/R_TI_PHASE_C_THROUGH_H_PLAN.md` § Stage 5 T-API-9.
-/

import Orbcrypt.Hardness.GrochowQiao.AlgEquivLift
import Orbcrypt.Hardness.GrochowQiao.WedderburnMalcev
import Orbcrypt.Hardness.GrochowQiao.SlotSignature

/-!
# Adjacency invariance

Public API:

* `arrowElement_sandwich m u v` — `α(u, v) = e_u * α(u, v) * e_v`.
* `radical_arrowElement_mul` — `j * α(u, v) = 0` for `j ∈ J`.
* `arrowElement_radical_mul` — `α(u, v) * j = 0` for `j ∈ J`.
* `inner_aut_radical_fixes_arrow` — `(1 + j) * α(u, v) * (1 - j) =
  α(u, v)`.
* `quiverPermAlgEquiv_arrow_iff_present` — `(.edge u v) ∈
  presentArrows m adj iff adj u v = true`.
* `vertexPerm_preserves_adjacency_iff` — σ is a graph iso between
  (adj₁, adj₂) iff the σ-action on basis arrows respects the
  adjacency relation.

## Naming

Identifiers describe content, not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt

-- ============================================================================
-- T-API-9.1 — Sandwich identity for `arrowElement`.
-- ============================================================================

/-- **Sandwich identity for `arrowElement`.**

In the path algebra `F[Q] / J²`, every arrow basis element is
"sandwiched" by its endpoint vertex idempotents:
```
arrowElement m u v = vertexIdempotent m u * arrowElement m u v *
                       vertexIdempotent m v.
```

*Proof.* By `vertexIdempotent_mul_arrowElement`, `e_u * α(u, v) =
α(u, v)`; by `arrowElement_mul_vertexIdempotent`, `α(u, v) * e_v =
α(u, v)`. Combine. -/
theorem arrowElement_sandwich (m : ℕ) (u v : Fin m) :
    vertexIdempotent m u * arrowElement m u v * vertexIdempotent m v =
      arrowElement m u v := by
  show pathAlgebraMul m (pathAlgebraMul m (vertexIdempotent m u)
        (arrowElement m u v)) (vertexIdempotent m v) = arrowElement m u v
  rw [vertexIdempotent_mul_arrowElement]
  rw [if_pos rfl]
  rw [arrowElement_mul_vertexIdempotent]
  rw [if_pos rfl]

-- ============================================================================
-- T-API-9.2 — Inner conjugation by `1 + j` fixes arrow elements (J²=0).
-- ============================================================================

/-- For `j ∈ pathAlgebraRadical m`, the product `j * arrowElement u v` is
zero. Equivalent to `member_radical_mul_arrowElement`; restated for
convenience. -/
theorem radical_arrowElement_mul (m : ℕ) (j : pathAlgebraQuotient m)
    (h_j : j ∈ pathAlgebraRadical m) (u v : Fin m) :
    j * arrowElement m u v = 0 :=
  member_radical_mul_arrowElement m u v j h_j

/-- For `j ∈ pathAlgebraRadical m`, `arrowElement u v * j = 0`. Equivalent
to `arrowElement_mul_member_radical`; restated for convenience. -/
theorem arrowElement_radical_mul (m : ℕ) (u v : Fin m)
    (j : pathAlgebraQuotient m) (h_j : j ∈ pathAlgebraRadical m) :
    arrowElement m u v * j = 0 :=
  arrowElement_mul_member_radical m u v j h_j

/-- **Inner conjugation by `1 + j` fixes arrow elements** (J²=0 content).

For any `j ∈ pathAlgebraRadical m`, the inner conjugation `c ↦ (1 + j)
* c * (1 - j)` acts as the identity on `arrowElement u v`:
```
(1 + j) * arrowElement m u v * (1 - j) = arrowElement m u v.
```

*Proof.* Expand `(1 + j) * α * (1 - j) = α + j*α - α*j - j*α*j`. The
last three terms vanish:
* `j * α = 0` (radical times arrow is zero from `member_radical_mul_arrowElement`).
* `α * j = 0` (arrow times radical is zero from `arrowElement_mul_member_radical`).
* `j * α * j = (j * α) * j = 0 * j = 0`.

Hence the expression collapses to `α`. -/
theorem inner_aut_radical_fixes_arrow (m : ℕ) (j : pathAlgebraQuotient m)
    (h_j : j ∈ pathAlgebraRadical m) (u v : Fin m) :
    (1 + j) * arrowElement m u v * (1 - j) = arrowElement m u v := by
  -- Distribute: ((1 + j) * α) * (1 - j) = α + j*α - α*j - j*α*j.
  have h_jα : j * arrowElement m u v = 0 :=
    radical_arrowElement_mul m j h_j u v
  have h_αj : arrowElement m u v * j = 0 :=
    arrowElement_radical_mul m u v j h_j
  have h_jαj : j * arrowElement m u v * j = 0 := by
    rw [h_jα, zero_mul]
  -- Compute (1 + j) * α = α + j * α = α.
  have h_step1 : (1 + j) * arrowElement m u v = arrowElement m u v := by
    rw [add_mul, one_mul, h_jα, add_zero]
  rw [h_step1]
  -- Compute α * (1 - j) = α - α * j = α.
  rw [mul_sub, mul_one, h_αj, sub_zero]

-- ============================================================================
-- T-API-9.3 — σ-induced AlgEquiv: arrow image is `α(σ u, σ v)`.
-- ============================================================================

/-- The σ-induced AlgEquiv preserves the sandwich identity: the σ-image
of `e_u * α(u, v) * e_v` is `e_{σ u} * α(σ u, σ v) * e_{σ v}`. -/
theorem quiverPermAlgEquiv_sandwich (m : ℕ) (σ : Equiv.Perm (Fin m))
    (u v : Fin m) :
    quiverPermAlgEquiv m σ
      (vertexIdempotent m u * arrowElement m u v * vertexIdempotent m v) =
        vertexIdempotent m (σ u) * arrowElement m (σ u) (σ v) *
          vertexIdempotent m (σ v) := by
  rw [arrowElement_sandwich, arrowElement_sandwich,
      quiverPermAlgEquiv_apply_arrowElement]

-- ============================================================================
-- T-API-9.4 — Adjacency preservation characterization.
-- ============================================================================

/-- **Membership in `presentArrows m adj`** iff `adj u v = true`
(direct unfolding of the `presentArrows` definition).

This is the bridge between the algebraic notion of "arrow element
in the path algebra subspace" and the graph-theoretic notion of
"adjacency". -/
theorem mem_presentArrows_iff (m : ℕ) (adj : Fin m → Fin m → Bool)
    (u v : Fin m) :
    (.edge u v : QuiverArrow m) ∈ presentArrows m adj ↔ adj u v = true := by
  unfold presentArrows
  simp only [Finset.mem_union, Finset.mem_image, Finset.mem_filter,
    Finset.mem_univ, true_and]
  -- LHS: (∃ v', .id v' = .edge u v) ∨ (∃ p, adj p.1 p.2 = true ∧ .edge p.1 p.2 = .edge u v)
  -- RHS: adj u v = true
  constructor
  · rintro (⟨w, hw⟩ | ⟨⟨p₁, p₂⟩, h_adj, h_eq⟩)
    · exact absurd hw (by simp)
    · -- .edge p₁ p₂ = .edge u v ⇒ p₁ = u, p₂ = v.
      have h_inj := QuiverArrow.edge.injEq p₁ p₂ u v |>.mp h_eq
      obtain ⟨rfl, rfl⟩ := h_inj
      exact h_adj
  · intro h_adj
    refine Or.inr ⟨(u, v), h_adj, rfl⟩

/-- **`σ` is a graph isomorphism iff its arrow-action respects
adjacency.**

This is a Boolean characterization: `σ` is a graph isomorphism between
`(adj₁, adj₂)` precisely when `σ`'s induced action on basis-element
arrows (via `quiverMap`) carries `presentArrows m adj₁` to
`presentArrows m adj₂`. -/
theorem vertexPerm_isGraphIso_iff_arrow_preserving (m : ℕ)
    (σ : Equiv.Perm (Fin m)) (adj₁ adj₂ : Fin m → Fin m → Bool) :
    (∀ u v, adj₁ u v = adj₂ (σ u) (σ v)) ↔
    (∀ u v, (.edge u v : QuiverArrow m) ∈ presentArrows m adj₁ ↔
            (.edge (σ u) (σ v) : QuiverArrow m) ∈ presentArrows m adj₂) := by
  constructor
  · intro h_iso u v
    rw [mem_presentArrows_iff, mem_presentArrows_iff, h_iso]
  · intro h_arrow u v
    have h_iff := h_arrow u v
    rw [mem_presentArrows_iff, mem_presentArrows_iff] at h_iff
    -- Now: h_iff : adj₁ u v = true ↔ adj₂ (σ u) (σ v) = true.
    -- We need to show: adj₁ u v = adj₂ (σ u) (σ v).
    -- Bool case-analysis using the iff.
    rcases h_a : adj₁ u v with _ | _
    · -- adj₁ u v = false; show adj₂ (σ u) (σ v) = false (else contradiction).
      rcases h_b : adj₂ (σ u) (σ v) with _ | _
      · rfl
      · -- adj₂ true ⇒ adj₁ true via h_iff.mpr; contradicts h_a.
        have h_contra : adj₁ u v = true := h_iff.mpr h_b
        rw [h_a] at h_contra
        exact absurd h_contra Bool.false_ne_true
    · -- adj₁ u v = true; show adj₂ (σ u) (σ v) = true.
      have h_b : adj₂ (σ u) (σ v) = true := h_iff.mp h_a
      rw [h_b]

/-- **σ-induced AlgEquiv arrow action is iff-equivalent to graph isomorphism.**

`σ` is a graph isomorphism between `(adj₁, adj₂)` iff the σ-induced
AlgEquiv carries `presentArrows m adj₁`-arrow elements to
`presentArrows m adj₂`-arrow elements (via the basis-level σ-action).

This is the **adjacency invariance characterization** that closes
the rigidity argument: any σ extracted from a tensor isomorphism
that preserves the arrow support must be a graph isomorphism. -/
theorem quiverPermAlgEquiv_preserves_presentArrows_iff (m : ℕ)
    (σ : Equiv.Perm (Fin m)) (adj₁ adj₂ : Fin m → Fin m → Bool) :
    (∀ u v, adj₁ u v = adj₂ (σ u) (σ v)) ↔
    (∀ u v, (.edge u v : QuiverArrow m) ∈ presentArrows m adj₁ ↔
            (quiverMap m σ (.edge u v) : QuiverArrow m) ∈ presentArrows m adj₂) := by
  rw [vertexPerm_isGraphIso_iff_arrow_preserving]
  -- LHS predicate: ... ∈ presentArrows m adj₂ uses `.edge (σ u) (σ v)`.
  -- RHS predicate: uses `quiverMap m σ (.edge u v) = .edge (σ u) (σ v)`.
  -- Both are pointwise the same after `quiverMap_edge`.
  constructor
  · intro h u v
    rw [quiverMap_edge]
    exact h u v
  · intro h u v
    have := h u v
    rw [quiverMap_edge] at this
    exact this

end GrochowQiao
end Orbcrypt
