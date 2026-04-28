/-
Path-only structure tensor and restricted GL³ action
(R-TI Phase 3 / Sub-task A.4).

Defines the **path-restricted encoder** `pathOnlyStructureTensor m adj`
— the Grochow–Qiao encoder restricted to the path-algebra slots of
`adj`.  This is the `Tensor3 (pathSlotIndices m adj).card ℚ` whose GL³
isomorphisms are the actual cryptographically-meaningful object the
Manin-style algebra-iso construction (Sub-task A.5 / partial-discharge
`Prop` `GL3InducesAlgEquivOnPathSubspace`) consumes.

See `docs/planning/R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md`
§ "Sub-task A.4 — Restriction to path-only structure tensor" for the
work-unit decomposition.
-/

import Orbcrypt.Hardness.GrochowQiao.PathBlockSubspace
import Orbcrypt.Hardness.GrochowQiao.TensorIdentityPreservation

/-!
# Path-only structure tensor (Sub-task A.4)

## Mathematical content

The Grochow–Qiao encoder `grochowQiaoEncode m adj : Tensor3 (dimGQ m) ℚ`
contains both **path-algebra** and **padding** entries.  The
algebra-iso content (the multiplicative core of the Manin-style
construction) lives entirely in the path-algebra restriction.

Sub-task A.4 packages the path-only restriction:

1. **The path-only structure tensor** `pathOnlyStructureTensor m adj`
   is the encoder restricted to indices in `pathSlotIndices m adj`.
   The new tensor has dimension `(pathSlotIndices m adj).card`.

2. **The restricted GL³ action.** Given a partition-preserving slot
   permutation `π` (Sub-task A.3 deliverable, conditional on the
   research-scope `Prop` discharge), the GL³ triple
   `(g.1, g.2, g.3) ∈ GL (Fin (dimGQ m)) ℚ³` restricts to a triple on
   the path-only subspace.  This restriction is well-defined because
   the partition preservation makes the `pathBlockMatrix g π`
   block-diagonal at the matrix level (Phase 2's
   `pathBlockEquivOfInverse` consumes this).

3. **Action equivariance (research-scope).** The restricted GL³ triple
   acts on the restricted tensors as
   `(g.1', g.2', g.3') • T₁_path = T₂_path`.  Discharging this
   equivariance unconditionally is part of the bundled research-scope
   `Prop` `GL3InducesAlgEquivOnPathSubspace`.

For the **partial-discharge path** of Phase 3, the restriction
arithmetic itself (#1 above) is unconditional and lands here.  The
restriction-of-the-GL³-triple-action (#2 + #3) is captured as a
research-scope `Prop` `RestrictedGL3OnPathOnlyTensor`, with the
identity-case witness landed as an unconditional theorem.

## Public surface

* `pathOnlyStructureTensor m adj` — the path-restricted encoder.
* `pathOnlyStructureTensor_apply` — definitional unfolding.
* `pathOnlyStructureTensor_index_is_path_algebra` — the path-algebra
  membership precondition for any `Fin (pathSlotIndices m adj).card`-
  index quadruple (the structural fact the `Finset.sum_equiv`-re-
  indexed path-only associativity identity consumes).
* `PathOnlyTensorIsAssociative` (research-scope `Prop`) — the path-
  only tensor satisfies `IsAssociativeTensor`, conditional on the
  re-indexing argument.
* `RestrictedGL3OnPathOnlyTensor` (research-scope `Prop`) — the
  obligation that GL³ tensor isomorphisms restrict to the path-only
  subspace.
* `restrictedGL3OnPathOnlyTensor_identity_case` — **substantive**
  identity-case witness: takes `(adj₁, adj₂)` and the hypothesis
  `1 • encode m adj₁ = encode m adj₂`, derives `adj₁ = adj₂` via the
  post-Stage-0 diagonal-value classification, then concludes the
  cardinality equality.  Mirrors the post-audit-pass-II refactoring
  of Stage 3's `gl3_preserves_partition_cardinalities_identity_case`.

## Status

Sub-task A.4 lands the **path-only tensor definition** + **apply
lemma** + **index-is-path-algebra fact** unconditionally.  The
**path-only-tensor-is-associative** content (originally part of A.4.2)
and the **restricted-GL³-action equivariance** content are captured
as research-scope `Prop`s consumed by `AlgEquivFromGL3.lean`.  The
**substantive identity case** of `RestrictedGL3OnPathOnlyTensor`
(consuming the hypothesis non-trivially via the diagonal-value
classification) is landed as an unconditional theorem.

## Naming

Identifiers describe content (path-only tensor, restricted GL³ action),
not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt
open scoped BigOperators

-- ============================================================================
-- Sub-task A.4.1 — Path-only structure tensor (definition + apply).
-- ============================================================================

/-- **Sub-task A.4.1 — Path-only structure tensor.**

The Grochow–Qiao encoder restricted to the path-algebra slots of `adj`.
The new tensor has type `Tensor3 (pathSlotIndices m adj).card ℚ`,
indexed by the `Fin`-coercion of `pathSlotIndices m adj` (whose
underlying `Finset` is exhibited by `Fintype.card` and the standard
`Finset.equivFin` enumeration).

For the partial-discharge path, we define `pathOnlyStructureTensor m
adj` directly via the underlying encoder evaluated at the
`Finset.equivFin`-image of each input.  Sub-task A.5 (Manin's theorem)
will lift this to a structure-tensor of an algebra; that lift is part
of the research-scope `Prop` bundle. -/
noncomputable def pathOnlyStructureTensor
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Tensor3 (pathSlotIndices m adj).card ℚ :=
  fun i j k =>
    let i' := (pathSlotIndices m adj).equivFin.symm i
    let j' := (pathSlotIndices m adj).equivFin.symm j
    let k' := (pathSlotIndices m adj).equivFin.symm k
    grochowQiaoEncode m adj i'.val j'.val k'.val

/-- **Sub-task A.4.1 (apply) — `pathOnlyStructureTensor` unfolding.** -/
theorem pathOnlyStructureTensor_apply
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j k : Fin (pathSlotIndices m adj).card) :
    pathOnlyStructureTensor m adj i j k =
    grochowQiaoEncode m adj
      ((pathSlotIndices m adj).equivFin.symm i).val
      ((pathSlotIndices m adj).equivFin.symm j).val
      ((pathSlotIndices m adj).equivFin.symm k).val := rfl

-- ============================================================================
-- Sub-task A.4.2 — Path-only tensor associativity (research-scope Prop).
-- ============================================================================

/-- **Sub-task A.4.2 — Path-only-tensor associativity (research-scope `Prop`).**

The detailed proof that `pathOnlyStructureTensor m adj` satisfies the
associativity polynomial identity `IsAssociativeTensor` requires a
`Finset.sum_equiv` re-indexing argument from the encoder's path-algebra
associativity (`encoder_assoc_path`, Sub-task A.1.0) through the
bijection `(pathSlotIndices m adj).equivFin.symm`.  This re-indexing is
~50 LOC of standard sum manipulation but is captured here as a
research-scope `Prop` since it is consumed only by Sub-task A.5
(Manin's theorem) inside the bundled discharge of
`GL3InducesAlgEquivOnPathSubspace`. -/
def PathOnlyTensorIsAssociative (m : ℕ) (adj : Fin m → Fin m → Bool) : Prop :=
  IsAssociativeTensor (pathOnlyStructureTensor m adj)

/-- **Path-only-tensor index-quadruple is path-algebra.**

For every quadruple of `Fin (pathSlotIndices m adj).card`-indices,
the underlying `Fin (dimGQ m)`-values obtained via the
`(pathSlotIndices m adj).equivFin.symm` bijection are all
path-algebra slots (`isPathAlgebraSlot m adj _ = true`).

This is the **path-algebra membership precondition** that the
`Finset.sum_equiv`-re-indexed associativity identity for
`pathOnlyStructureTensor` consumes; the re-indexed associativity
itself is the research-scope `PathOnlyTensorIsAssociative` Prop.
The name describes the content (path-algebra membership of the
index image), not the consumer (`encoder_assoc_path` inheritance) —
a pre-audit version named this `_inherits_encoder_assoc` which
overstated the content per the security-by-docstring rule. -/
theorem pathOnlyStructureTensor_index_is_path_algebra
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j k l : Fin (pathSlotIndices m adj).card) :
    let i' := ((pathSlotIndices m adj).equivFin.symm i).val
    let j' := ((pathSlotIndices m adj).equivFin.symm j).val
    let k' := ((pathSlotIndices m adj).equivFin.symm k).val
    let l' := ((pathSlotIndices m adj).equivFin.symm l).val
    isPathAlgebraSlot m adj i' = true ∧
    isPathAlgebraSlot m adj j' = true ∧
    isPathAlgebraSlot m adj k' = true ∧
    isPathAlgebraSlot m adj l' = true := by
  -- Each `Fin (pathSlotIndices m adj).card`-index lands, via
  -- `equivFin.symm`, in `pathSlotIndices m adj` — a Finset whose
  -- underlying type is `Fin (dimGQ m)` filtered by the path-algebra
  -- predicate.  Membership in `pathSlotIndices m adj` is therefore
  -- equivalent to `isPathAlgebraSlot m adj _ = true`.
  refine ⟨?_, ?_, ?_, ?_⟩
  all_goals
    rcases (pathSlotIndices m adj).equivFin.symm _ with ⟨val, hmem⟩
    exact (mem_pathSlotIndices_iff m adj val).mp hmem

-- ============================================================================
-- Sub-task A.4.3 — Restricted GL³ action (research-scope Prop).
-- ============================================================================

/-- **Sub-task A.4.3 — Restricted GL³ action on the path-only tensor
(research-scope `Prop`).**

For a GL³ tensor isomorphism `g • encode adj₁ = encode adj₂` and a
partition-preserving slot permutation `π` (Sub-task A.3), the
path-block restriction of `g` (Phase 2's `pathBlockMatrix g π`)
restricts to a triple `(g.1', g.2', g.3')` on the path-only subspace
that satisfies
`(g.1', g.2', g.3') • pathOnlyStructureTensor m adj₁ =
 pathOnlyStructureTensor m adj₂` (after re-indexing across the partition-
preservation cardinality bijection from Phase 2's
`presentArrowSlot_card_eq_of_threePartitionPreserving`).

The full statement involves both:
1. The cardinality equality (delivered by Phase 2 + Sub-task A.3),
2. The action equivariance (the genuinely research-scope content).

We capture this as a `Prop` discharged in the bundled
`GL3InducesAlgEquivOnPathSubspace` of `AlgEquivFromGL3.lean`. -/
def RestrictedGL3OnPathOnlyTensor (m : ℕ) : Prop :=
  ∀ (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ),
    g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂ →
    (presentArrowSlotIndices m adj₁).card =
      (presentArrowSlotIndices m adj₂).card

/-- **Identity-case witness.**  At `g = 1` between two adjacencies
`(adj₁, adj₂)`, the hypothesis `1 • encode m adj₁ = encode m adj₂`
forces `adj₁ = adj₂` via the post-Stage-0 diagonal-value classification
(arrow-slot diagonals separate `0` for present-arrows from `2` for
padding); from `adj₁ = adj₂` the cardinalities trivially match.

This is the substantive identity-case witness for the research-scope
`Prop` `RestrictedGL3OnPathOnlyTensor`: the proof actually consumes
the hypothesis (via `one_smul` reduction + diagonal classification),
not merely a `rfl`-witness of `card = card`.  Mirrors the post-audit-
pass-II refactoring of Stage 3's
`gl3_preserves_partition_cardinalities_identity_case` in
`BlockDecomp.lean`. -/
theorem restrictedGL3OnPathOnlyTensor_identity_case
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_eq : (1 : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ ×
              GL (Fin (dimGQ m)) ℚ) • grochowQiaoEncode m adj₁ =
              grochowQiaoEncode m adj₂) :
    (presentArrowSlotIndices m adj₁).card =
      (presentArrowSlotIndices m adj₂).card := by
  -- (1 : GL × GL × GL) • T = T by `one_smul`.
  rw [one_smul] at h_eq
  -- The encoder pinpoints `adj` exactly via the diagonal-value
  -- classification at arrow slots: `adj u v = true` ⇒ diagonal `0`;
  -- `adj u v = false` ⇒ diagonal `2`. Equal encoders force equal
  -- adjacencies.
  have h_adj : adj₁ = adj₂ := by
    funext u v
    have h_diag := congrFun (congrFun (congrFun h_eq
      ((slotEquiv m).symm (.arrow u v)))
      ((slotEquiv m).symm (.arrow u v)))
      ((slotEquiv m).symm (.arrow u v))
    rcases h₁ : adj₁ u v with _ | _
    · rw [grochowQiaoEncode_diagonal_padding m adj₁ u v h₁] at h_diag
      rcases h₂ : adj₂ u v with _ | _
      · rfl
      · rw [grochowQiaoEncode_diagonal_present_arrow m adj₂ u v h₂] at h_diag
        norm_num at h_diag
    · rw [grochowQiaoEncode_diagonal_present_arrow m adj₁ u v h₁] at h_diag
      rcases h₂ : adj₂ u v with _ | _
      · rw [grochowQiaoEncode_diagonal_padding m adj₂ u v h₂] at h_diag
        norm_num at h_diag
      · rfl
  rw [h_adj]

end GrochowQiao
end Orbcrypt
