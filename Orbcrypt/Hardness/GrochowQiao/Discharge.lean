/-
Final discharge of R-TI Phase 3 research-scope Props
(`GL3InducesAlgEquivOnPathSubspace`, `RestrictedGL3OnPathOnlyTensor`)
from `GrochowQiaoRigidity` (the existing Stages 0–5 research-scope Prop).

This module is the **central conductor** of R-TI Phase 3: it bridges
the partial-discharge framework introduced by Phase 3 (which defines
new Props in terms of AlgEquiv on the path subspace) to the existing
Stages 0–5 chain (which uses `GrochowQiaoRigidity` defined in terms
of vertex permutation σ).

See `docs/planning/AUDIT_2026-04-28_PHASE_3_PROP_DISCHARGE_PLAN.md`
§ "A.6.3 — Final discharge".

Mathematical content: from a graph isomorphism σ between `(adj₁, adj₂)`,
the σ-induced AlgEquiv `quiverPermAlgEquiv m σ` carries
`presentArrowsSubspace m adj₁` exactly onto `presentArrowsSubspace m
adj₂`.  Combined with `GrochowQiaoRigidity` (which delivers σ from a
GL³ tensor isomorphism), this discharges
`GL3InducesAlgEquivOnPathSubspace`.  The cardinality preservation
(`RestrictedGL3OnPathOnlyTensor`) follows from `liftedSigma m σ`
bijecting path-algebra slots between adj₁ and adj₂.
-/

import Orbcrypt.Hardness.GrochowQiao.AlgEquivLift
import Orbcrypt.Hardness.GrochowQiao.AdjacencyInvariance
import Orbcrypt.Hardness.GrochowQiao.AlgEquivFromGL3
import Orbcrypt.Hardness.GrochowQiao.PathOnlyTensor
import Orbcrypt.Hardness.GrochowQiao.Reverse
import Orbcrypt.Hardness.GrochowQiao.PathBlockSubspace
import Orbcrypt.Hardness.GrochowQiao.Forward
import Orbcrypt.Hardness.GrochowQiao.PathOnlyAlgebra
import Orbcrypt.Hardness.GrochowQiao.Manin.TensorStabilizer

/-!
# Final discharge of Phase 3 research-scope Props (Sub-task A.6.3)

## Public surface

* `quiverPermAlgEquiv_image_presentArrowsSubspace` — the central
  bridge: σ a graph iso ⇒ σ-induced AlgEquiv carries the subspace.
* `gl3InducesAlgEquivOnPathSubspace_of_rigidity` — discharges
  `GL3InducesAlgEquivOnPathSubspace m` from `GrochowQiaoRigidity`.
* `restrictedGL3OnPathOnlyTensor_of_rigidity` — discharges
  `RestrictedGL3OnPathOnlyTensor m` from `GrochowQiaoRigidity`.
-/

namespace Orbcrypt
namespace GrochowQiao
namespace Discharge

open Orbcrypt
open scoped BigOperators

set_option linter.unusedSectionVars false

-- ============================================================================
-- Bridge 1 — `presentArrowsSubspace` membership preservation under
-- σ-induced AlgEquiv when σ is a graph isomorphism.
-- ============================================================================

/-- **Forward inclusion (σ-image ⊆ adj₂'s subspace).**

If σ is a graph isomorphism `adj₁ u v = adj₂ (σ u) (σ v)`, then for
any `f ∈ presentArrowsSubspace m adj₁`, we have
`quiverPermFun m σ f ∈ presentArrowsSubspace m adj₂`.

Proof: `(quiverPermFun σ f) a = f (quiverMap σ⁻¹ a)`.  For
`a ∉ presentArrows m adj₂`, we show `quiverMap σ⁻¹ a ∉ presentArrows
m adj₁` (by graph-iso symmetry), hence `f (quiverMap σ⁻¹ a) = 0`. -/
theorem quiverPermFun_mem_presentArrowsSubspace
    (m : ℕ) (σ : Equiv.Perm (Fin m))
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_σ : ∀ u v, adj₁ u v = adj₂ (σ u) (σ v))
    (f : pathAlgebraQuotient m) (h_f : f ∈ presentArrowsSubspace m adj₁) :
    quiverPermFun m σ f ∈ presentArrowsSubspace m adj₂ := by
  rw [mem_presentArrowsSubspace_iff] at h_f ⊢
  intro a h_a
  rw [quiverPermFun_apply]
  apply h_f
  intro h_in
  cases a with
  | id v =>
    exact absurd (presentArrows_id_mem m adj₂ v) h_a
  | edge u v =>
    have h_adj₂ : adj₂ u v = false := by
      cases h_b : adj₂ u v with
      | true =>
        exfalso
        apply h_a
        rw [presentArrows_edge_mem_iff]
        exact h_b
      | false => rfl
    -- quiverMap σ⁻¹ (.edge u v) = .edge (σ⁻¹ u) (σ⁻¹ v).
    rw [quiverMap] at h_in
    rw [presentArrows_edge_mem_iff] at h_in
    -- adj₁ (σ⁻¹ u) (σ⁻¹ v) = true.
    -- Apply h_σ at (σ⁻¹ u, σ⁻¹ v):
    --   adj₁ (σ⁻¹ u) (σ⁻¹ v) = adj₂ (σ (σ⁻¹ u)) (σ (σ⁻¹ v)) = adj₂ u v.
    have h_eq : adj₁ (σ⁻¹ u) (σ⁻¹ v) = adj₂ u v := by
      rw [h_σ (σ⁻¹ u) (σ⁻¹ v), Equiv.Perm.inv_def,
          Equiv.apply_symm_apply, Equiv.apply_symm_apply]
    rw [h_eq] at h_in
    rw [h_in] at h_adj₂
    exact Bool.noConfusion h_adj₂

/-- **σ-image of presentArrowsSubspace lies in the target subspace.** -/
theorem quiverPermAlgEquiv_image_subset_presentArrowsSubspace
    (m : ℕ) (σ : Equiv.Perm (Fin m))
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_σ : ∀ u v, adj₁ u v = adj₂ (σ u) (σ v)) :
    quiverPermAlgEquiv m σ ''
      (presentArrowsSubspace m adj₁ : Set (pathAlgebraQuotient m)) ⊆
    (presentArrowsSubspace m adj₂ : Set (pathAlgebraQuotient m)) := by
  rintro y ⟨f, h_f, rfl⟩
  rw [quiverPermAlgEquiv_apply]
  exact quiverPermFun_mem_presentArrowsSubspace m σ adj₁ adj₂ h_σ f h_f

/-- **Symmetry: σ⁻¹ is also a graph iso (between adj₂ and adj₁).** -/
private theorem graphIso_inv (m : ℕ) (σ : Equiv.Perm (Fin m))
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_σ : ∀ u v, adj₁ u v = adj₂ (σ u) (σ v)) :
    ∀ u v, adj₂ u v = adj₁ (σ⁻¹ u) (σ⁻¹ v) := by
  intro u v
  rw [h_σ (σ⁻¹ u) (σ⁻¹ v), Equiv.Perm.inv_def,
      Equiv.apply_symm_apply, Equiv.apply_symm_apply]

/-- **Image equality of presentArrowsSubspace under σ-AlgEquiv.**

When σ is a graph isomorphism, the σ-induced AlgEquiv carries
`presentArrowsSubspace m adj₁` exactly onto `presentArrowsSubspace m
adj₂` as `Set`s.

Proof: forward inclusion via `quiverPermAlgEquiv_image_subset_…`;
reverse inclusion by exhibiting σ⁻¹-image preimage and using
quiverPermFun composition law (σ • σ⁻¹ • g = g). -/
theorem quiverPermAlgEquiv_image_presentArrowsSubspace
    (m : ℕ) (σ : Equiv.Perm (Fin m))
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_σ : ∀ u v, adj₁ u v = adj₂ (σ u) (σ v)) :
    quiverPermAlgEquiv m σ ''
      (presentArrowsSubspace m adj₁ : Set (pathAlgebraQuotient m)) =
    (presentArrowsSubspace m adj₂ : Set (pathAlgebraQuotient m)) := by
  apply Set.Subset.antisymm
  · exact quiverPermAlgEquiv_image_subset_presentArrowsSubspace m σ adj₁ adj₂ h_σ
  · -- Reverse: every g ∈ presentArrowsSubspace adj₂ has a preimage in
    -- presentArrowsSubspace adj₁ under quiverPermAlgEquiv σ.
    intro g h_g
    refine ⟨quiverPermFun m σ⁻¹ g, ?_, ?_⟩
    · -- Show quiverPermFun σ⁻¹ g ∈ presentArrowsSubspace adj₁.
      exact quiverPermFun_mem_presentArrowsSubspace m σ⁻¹ adj₂ adj₁
              (graphIso_inv m σ adj₁ adj₂ h_σ) g h_g
    · -- Show quiverPermAlgEquiv σ (quiverPermFun σ⁻¹ g) = g.
      rw [quiverPermAlgEquiv_apply]
      -- σ • (σ⁻¹ • g) c = g (quiverMap σ⁻¹⁻¹ (quiverMap σ⁻¹ c))
      --                 = g (quiverMap σ (quiverMap σ⁻¹ c)) = g c.
      funext c
      rw [quiverPermFun_apply, quiverPermFun_apply, inv_inv]
      have h_round : quiverMap m σ (quiverMap m σ⁻¹ c) = c := by
        cases c with
        | id v =>
          rw [quiverMap, quiverMap]
          simp [Equiv.Perm.inv_def, Equiv.apply_symm_apply]
        | edge u v =>
          rw [quiverMap, quiverMap]
          simp [Equiv.Perm.inv_def, Equiv.apply_symm_apply]
      rw [h_round]

-- ============================================================================
-- Discharge 1 — `GL3InducesAlgEquivOnPathSubspace` from `GrochowQiaoRigidity`.
-- ============================================================================

/-- **Discharge of `GL3InducesAlgEquivOnPathSubspace` from
`GrochowQiaoRigidity`.**

Under the existing research-scope Prop `GrochowQiaoRigidity` (which
delivers a graph-iso vertex permutation σ from a tensor isomorphism
of encoders), the new Phase 3 Prop `GL3InducesAlgEquivOnPathSubspace`
follows by witnessing the AlgEquiv as `quiverPermAlgEquiv m σ` and
applying `quiverPermAlgEquiv_image_presentArrowsSubspace` for the
subspace-preservation property. -/
theorem gl3InducesAlgEquivOnPathSubspace_of_rigidity
    (h_rig : GrochowQiaoRigidity) (m : ℕ) :
    GL3InducesAlgEquivOnPathSubspace m := by
  intro adj₁ adj₂ g hg
  have h_iso : AreTensorIsomorphic
      (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂) :=
    ⟨g, hg⟩
  obtain ⟨σ, h_σ⟩ := h_rig m adj₁ adj₂ h_iso
  refine ⟨quiverPermAlgEquiv m σ, ?_⟩
  exact quiverPermAlgEquiv_image_presentArrowsSubspace m σ adj₁ adj₂ h_σ

-- ============================================================================
-- Discharge 2 — `RestrictedGL3OnPathOnlyTensor` from `GrochowQiaoRigidity`.
-- ============================================================================

/-- **Slot-shape preservation under `liftedSigma σ` for present-arrow
slots.**

If σ is a graph isomorphism `adj₁ u v = adj₂ (σ u) (σ v)`, then the
`isPresentArrowSlot` predicate is preserved by `liftedSigma σ`. -/
theorem isPresentArrowSlot_liftedSigma
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (σ : Equiv.Perm (Fin m))
    (h : ∀ i j, adj₁ i j = adj₂ (σ i) (σ j))
    (i : Fin (dimGQ m)) :
    isPresentArrowSlot m adj₁ i =
    isPresentArrowSlot m adj₂ (liftedSigma m σ i) := by
  have h_eq : i = (slotEquiv m).symm (slotEquiv m i) :=
    ((slotEquiv m).left_inv i).symm
  rw [h_eq]
  cases h_kind : slotEquiv m i with
  | vertex v =>
    rw [liftedSigma_vertex]
    unfold isPresentArrowSlot
    rw [Equiv.apply_symm_apply, Equiv.apply_symm_apply]
  | arrow u v =>
    rw [liftedSigma_arrow]
    unfold isPresentArrowSlot
    rw [Equiv.apply_symm_apply, Equiv.apply_symm_apply]
    exact h u v

/-- **Cardinality bijection: `presentArrowSlotIndices` matches via
`liftedSigma σ`.**

If σ is a graph isomorphism, then `liftedSigma m σ` bijects
`presentArrowSlotIndices m adj₁` with `presentArrowSlotIndices m adj₂`. -/
theorem presentArrowSlotIndices_card_eq_of_graphIso
    (m : ℕ) (σ : Equiv.Perm (Fin m))
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_σ : ∀ u v, adj₁ u v = adj₂ (σ u) (σ v)) :
    (presentArrowSlotIndices m adj₁).card =
      (presentArrowSlotIndices m adj₂).card := by
  apply Finset.card_bij
    (fun (i : Fin (dimGQ m))
        (_h : i ∈ presentArrowSlotIndices m adj₁) => liftedSigma m σ i)
  · intro i hi
    simp only [presentArrowSlotIndices, Finset.mem_filter,
                Finset.mem_univ, true_and] at hi ⊢
    rw [← isPresentArrowSlot_liftedSigma m adj₁ adj₂ σ h_σ i]
    exact hi
  · intro i _hi j _hj h_eq
    exact (liftedSigma m σ).injective h_eq
  · intro j hj
    refine ⟨(liftedSigma m σ).symm j, ?_, ?_⟩
    · simp only [presentArrowSlotIndices, Finset.mem_filter,
                  Finset.mem_univ, true_and] at hj ⊢
      have h_at : isPresentArrowSlot m adj₁ ((liftedSigma m σ).symm j) =
                  isPresentArrowSlot m adj₂ j := by
        rw [isPresentArrowSlot_liftedSigma m adj₁ adj₂ σ h_σ,
            Equiv.apply_symm_apply]
      rw [h_at]
      exact hj
    · exact Equiv.apply_symm_apply _ _

/-- **Discharge of `RestrictedGL3OnPathOnlyTensor` from
`GrochowQiaoRigidity`.** -/
theorem restrictedGL3OnPathOnlyTensor_of_rigidity
    (h_rig : GrochowQiaoRigidity) (m : ℕ) :
    RestrictedGL3OnPathOnlyTensor m := by
  intro adj₁ adj₂ g hg
  have h_iso : AreTensorIsomorphic
      (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂) :=
    ⟨g, hg⟩
  obtain ⟨σ, h_σ⟩ := h_rig m adj₁ adj₂ h_iso
  exact presentArrowSlotIndices_card_eq_of_graphIso m σ adj₁ adj₂ h_σ

-- ============================================================================
-- Path B — Discharge via Manin tensor-stabilizer + path-only Subalgebra.
-- ============================================================================

/-- **Path B research-scope obligation: GL³-to-graph-iso via Manin route.**

This is the alternative research-scope obligation factoring
`GrochowQiaoRigidity` into a Manin-aware shape:

> For any GL³ tensor isomorphism `g • encode adj₁ = encode adj₂`, the
> Manin tensor-stabilizer chain (basis-change relation on path-only
> structure tensors → AlgEquiv on path-only Subalgebras → σ via WM
> σ-extraction → arrow preservation) yields a vertex permutation σ
> that is a graph isomorphism between `(adj₁, adj₂)`.

Discharging this Prop is a research-scope obligation analogous to
`GrochowQiaoRigidity` but factored through the Manin chain.  The
benefit of factoring is that intermediate steps are unconditional
Mathlib-quality content:

1. `Manin.algEquivOfTensorIso` — UNCONDITIONAL (this PR).
2. `pathOnlyAlgebraBasis_structureTensor_eq_pathOnlyStructureTensor` —
   UNCONDITIONAL (this PR).
3. WM σ-extraction (`algEquiv_extractVertexPerm`) — UNCONDITIONAL
   (existing `WedderburnMalcev.lean`).
4. Arrow preservation under conjugation
   (`vertexPerm_isGraphIso_iff_arrow_preserving`) — UNCONDITIONAL
   (existing `AdjacencyInvariance.lean`).

Only the **outer reduction** (deriving the basis-change relation
from a generic GL³ triple) and the **Subalgebra→full-algebra lift**
(adapting WM σ-extraction for a path-only Subalgebra AlgEquiv)
remain research-scope. -/
def GrochowQiaoRigidityViaMan : Prop :=
  ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool),
    AreTensorIsomorphic
      (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂) →
    ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)

/-- **Bridge: `GrochowQiaoRigidityViaMan` and `GrochowQiaoRigidity` are
the same predicate.**

The two Props are definitionally equal: both assert "GL³ tensor iso ⇒
∃ σ graph iso".  They differ only in how they're discharged
(Path A: directly; Path B: via the Manin chain).

This bridge ensures Path B's discharge of `GL3InducesAlgEquivOnPathSubspace`
runs through the same final composition as Path A, keeping the
downstream chain consistent. -/
theorem grochowQiaoRigidityViaMan_iff_grochowQiaoRigidity :
    GrochowQiaoRigidityViaMan ↔ GrochowQiaoRigidity := Iff.rfl

/-- **Path B discharge of `GL3InducesAlgEquivOnPathSubspace` from
`GrochowQiaoRigidityViaMan`.**

Identical conclusion as `gl3InducesAlgEquivOnPathSubspace_of_rigidity`
but framed via the Manin-route research-scope obligation. -/
theorem gl3InducesAlgEquivOnPathSubspace_via_manin
    (h_rig : GrochowQiaoRigidityViaMan) (m : ℕ) :
    GL3InducesAlgEquivOnPathSubspace m :=
  gl3InducesAlgEquivOnPathSubspace_of_rigidity
    (grochowQiaoRigidityViaMan_iff_grochowQiaoRigidity.mp h_rig) m

/-- **Path B discharge of `RestrictedGL3OnPathOnlyTensor` from
`GrochowQiaoRigidityViaMan`.** -/
theorem restrictedGL3OnPathOnlyTensor_via_manin
    (h_rig : GrochowQiaoRigidityViaMan) (m : ℕ) :
    RestrictedGL3OnPathOnlyTensor m :=
  restrictedGL3OnPathOnlyTensor_of_rigidity
    (grochowQiaoRigidityViaMan_iff_grochowQiaoRigidity.mp h_rig) m

-- ============================================================================
-- Manin chain — unconditional reusable content (this PR).
-- ============================================================================

/-- **Manin's algEquiv from path-only structure tensor: trivial-case
witness.**

For any adjacency `adj`, applying Manin's tensor-stabilizer theorem
to `(pathOnlyAlgebraBasis m adj, pathOnlyAlgebraBasis m adj, 1, 1,
IsBasisChangeRelated.id, IsUnitCompatible at 1)` produces an algebra
equivalence on the path-only Subalgebra.  This is the **non-vacuity
witness** for the Manin chain at the smallest non-trivial instance:
the construction is a well-typed `AlgEquiv` derived end-to-end from
`Manin.algEquivOfTensorIso`. -/
theorem pathOnlyAlgebra_manin_trivial
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Nonempty (↥(pathOnlyAlgebraSubalgebra m adj) ≃ₐ[ℚ]
                ↥(pathOnlyAlgebraSubalgebra m adj)) :=
  ⟨Manin.algEquivOfTensorIso
      (pathOnlyAlgebraBasis m adj) (pathOnlyAlgebraBasis m adj) 1 1
      (Manin.IsBasisChangeRelated.id _)
      (pathOnlyAlgebraBasis_unitCompatible_self m adj)⟩

end Discharge
end GrochowQiao
end Orbcrypt
