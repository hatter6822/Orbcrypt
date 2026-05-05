/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

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

-- The `linter.unusedSectionVars` linter fires on theorems whose
-- section-level binders (the `[CommRing F] [DecidableEq F]` etc.
-- declared by upstream `variable` blocks) aren't strictly needed by
-- every theorem in the module.  We carry these binders project-wide
-- because the discharge bridges below threadthrough multiple paths
-- (`quiverPermAlgEquiv`, `liftedSigma`, `pathBlockSubspace`) that
-- collectively need every binder.  Suppressing the cosmetic warning
-- is preferred over per-theorem `attribute [-instance]` /
-- `letI`-rebuilds that would obscure the proof bodies.
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
-- Path B — Genuine factoring of `GrochowQiaoRigidity` via path-only
-- algebra equivalences.
-- ============================================================================

/-!
## Path B: factoring rigidity through the path-only Subalgebra AlgEquiv

The existing `gl3InducesAlgEquivOnPathSubspace_of_rigidity` (Path A)
discharges the Phase 3 Props directly from `GrochowQiaoRigidity`.

Path B factors `GrochowQiaoRigidity` into TWO smaller research-scope
obligations bridged by an unconditional construction (this PR's
Manin-chain content lives in the discharger of the first obligation):

```
PathOnlyAlgEquivObligation (GL³ ⇒ AlgEquiv on path-only Subalgebras)  [research-scope]
        │
        ▼
PathOnlySubalgebraGraphIsoObligation (AlgEquiv ⇒ σ graph iso)         [research-scope]
```

Each Path B obligation is **strictly smaller** than `GrochowQiaoRigidity`
in the sense that:

* `PathOnlyAlgEquivObligation` does not need to construct a vertex
  permutation σ; it only needs an existential AlgEquiv between the
  two path-only Subalgebras.  A natural discharge uses Manin's
  `algEquivOfTensorIso` (unconditional this PR) once a basis-change
  relation has been derived from the GL³ triple.

* `PathOnlySubalgebraGraphIsoObligation` does not need to handle
  the GL³ tensor structure; it only needs to extract σ from an
  abstract AlgEquiv on path-only Subalgebras.  A natural discharge
  uses Wedderburn–Mal'cev σ-extraction (unconditional, in
  `WedderburnMalcev.lean`) adapted for the Subalgebra setting.

Together they imply `GrochowQiaoRigidity` via a clean composition.
The Manin tensor-stabilizer theorem appears INSIDE a discharger of
the first obligation; this module provides the bridge theorem
(`pathOnlyAlgebraBasis_structureTensor_eq_pathOnlyStructureTensor`)
that lets such a discharger plug Manin into the encoder.

**Audit note (2026-04-28).**  An earlier version of this section
defined `GrochowQiaoRigidityViaMan := GrochowQiaoRigidity` (a
definitional rename that compiled by `Iff.rfl`) and provided
`_via_manin` discharges that were `Iff.rfl`-aliases of Path A.
Those have been **removed as theatrical** — the docstring claimed a
"Manin-route discharge" but the proofs called Path A directly.
The new factoring below is genuinely substantive: each Path B
obligation can be discharged independently of the other, and their
composition is a non-trivial proof.
-/

/-- **Path B research-scope obligation 1: GL³ tensor iso ⇒ AlgEquiv
on path-only Subalgebras.**

For any GL³ tensor isomorphism `g • encode adj₁ = encode adj₂`,
this Prop asserts the existence of an algebra equivalence between
the two adjacencies' path-only Subalgebras.

Discharging this Prop is a research-scope obligation **strictly
smaller** than `GrochowQiaoRigidity`: it does not require
constructing a vertex permutation σ; only an existential AlgEquiv
between the (different-graph) path-only Subalgebras.

**Manin chain discharge route (recommended).**  A natural way to
discharge this obligation uses the Manin chain:
1. From the GL³ tensor iso, derive a basis-change relation on the
   two path-only structure tensors (research-scope sub-step).
2. Apply `Manin.algEquivOfTensorIso` (UNCONDITIONAL) to get the
   AlgEquiv.  The bridge theorem
   `pathOnlyAlgebraBasis_structureTensor_eq_pathOnlyStructureTensor`
   translates between the encoder's structure tensor and Manin's
   abstract form.

The identity case (adj₁ = adj₂) is dischargeable unconditionally
via `pathOnlyAlgEquivObligation_id` below. -/
def PathOnlyAlgEquivObligation (m : ℕ) : Prop :=
  ∀ (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ),
    g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂ →
    Nonempty (↥(pathOnlyAlgebraSubalgebra m adj₁) ≃ₐ[ℚ]
                ↥(pathOnlyAlgebraSubalgebra m adj₂))

/-- **Path B research-scope obligation 2: Subalgebra AlgEquiv ⇒
graph-iso σ.**

For any pair of adjacencies `adj₁, adj₂` and any algebra equivalence
between their path-only Subalgebras, this Prop asserts the existence
of a vertex permutation σ that is a graph isomorphism between
`(adj₁, adj₂)`.

Discharging this Prop is a research-scope obligation **strictly
smaller** than `GrochowQiaoRigidity`: it does not handle the GL³
tensor structure; only abstract Subalgebra AlgEquivs.

**Wedderburn–Mal'cev discharge route (recommended).**  A natural way
to discharge this obligation uses WM σ-extraction:
1. The Subalgebra AlgEquiv corresponds (via `Subalgebra.subtype`) to
   a partial AlgEquiv on `pathAlgebraQuotient m`.
2. Apply `algEquiv_extractVertexPerm` (UNCONDITIONAL, in
   `WedderburnMalcev.lean`) — adapted for the Subalgebra setting —
   to extract σ.
3. Apply `vertexPerm_isGraphIso_iff_arrow_preserving` (UNCONDITIONAL,
   in `AdjacencyInvariance.lean`) to verify σ is a graph iso.

The identity case (adj₁ = adj₂) is dischargeable unconditionally
via σ = identity; see `pathOnlySubalgebraGraphIsoObligation_id`
below. -/
def PathOnlySubalgebraGraphIsoObligation (m : ℕ) : Prop :=
  ∀ (adj₁ adj₂ : Fin m → Fin m → Bool),
    Nonempty (↥(pathOnlyAlgebraSubalgebra m adj₁) ≃ₐ[ℚ]
                ↥(pathOnlyAlgebraSubalgebra m adj₂)) →
    ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)

/-- **Identity-case witness for `PathOnlyAlgEquivObligation`.**

When `adj₁ = adj₂`, the AlgEquiv is `AlgEquiv.refl` on the path-only
Subalgebra. -/
theorem pathOnlyAlgEquivObligation_id (m : ℕ) (adj : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (_hg : g • grochowQiaoEncode m adj = grochowQiaoEncode m adj) :
    Nonempty (↥(pathOnlyAlgebraSubalgebra m adj) ≃ₐ[ℚ]
                ↥(pathOnlyAlgebraSubalgebra m adj)) :=
  ⟨AlgEquiv.refl⟩

/-- **Identity-case witness for `PathOnlySubalgebraGraphIsoObligation`.**

When `adj₁ = adj₂`, σ = identity is a graph iso between `(adj, adj)`. -/
theorem pathOnlySubalgebraGraphIsoObligation_id (m : ℕ)
    (adj : Fin m → Fin m → Bool)
    (_h : Nonempty (↥(pathOnlyAlgebraSubalgebra m adj) ≃ₐ[ℚ]
                      ↥(pathOnlyAlgebraSubalgebra m adj))) :
    ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj i j = adj (σ i) (σ j) :=
  ⟨1, fun i j => by simp⟩

/-- **Path B genuine factoring: composing the two obligations yields
`GrochowQiaoRigidity`.**

Under both Path B research-scope obligations
(`PathOnlyAlgEquivObligation` and
`PathOnlySubalgebraGraphIsoObligation`), `GrochowQiaoRigidity`
follows unconditionally:

1. From `AreTensorIsomorphic encode adj₁ encode adj₂`, extract
   `g, hg`.
2. Apply `PathOnlyAlgEquivObligation` to get an AlgEquiv between
   the two path-only Subalgebras.
3. Apply `PathOnlySubalgebraGraphIsoObligation` to extract σ.

The composition is a substantive proof: each Path B obligation
contributes meaningfully (neither is `Iff.rfl` of the conclusion). -/
theorem grochowQiaoRigidity_via_path_only_algEquiv_chain
    (m : ℕ) (h_in : PathOnlyAlgEquivObligation m)
    (h_out : PathOnlySubalgebraGraphIsoObligation m)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_iso : AreTensorIsomorphic
              (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂)) :
    ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j) := by
  obtain ⟨g, hg⟩ := h_iso
  exact h_out adj₁ adj₂ (h_in adj₁ adj₂ g hg)

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
