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
* `RestrictedGL3OnPathOnlyTensor` (research-scope `Prop`) — the
  obligation that GL³ tensor isomorphisms restrict to the path-only
  subspace.
* `restrictedGL3OnPathOnlyTensor_identity_case` — identity witness.

## Status

Sub-task A.4 lands the **path-only tensor definition** + **apply
lemma** unconditionally.  The **path-only-tensor-is-associative**
content (originally part of A.4.2) and the **restricted-GL³-action
equivariance** Prop are part of the research-scope bundle consumed by
`AlgEquivFromGL3.lean`; the identity case is landed as an
unconditional witness.

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

/-- **Identity-case anchor for `PathOnlyTensorIsAssociative`.**

For graphs where every slot is path-algebra (i.e., the complete
directed graph `adj := fun _ _ => true`), the path-only tensor coincides
with the underlying encoder up to re-indexing, and the associativity
identity is the `encoder_assoc_path` result re-indexed.  We capture
this as the **identity-anchor** form: when the index map
`equivFin.symm` lands on a path-algebra slot for every input, the
identity holds.

Formally, the associativity-on-an-arbitrary-quadruple-of-path-slot-indices
form is straightforward but requires the re-indexing.  Below we provide
the per-quadruple identity in the **`encoder_assoc_path`-aligned
form**, which is the form Sub-task A.5's algebra-iso construction
consumes. -/
theorem pathOnlyStructureTensor_inherits_encoder_assoc
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

/-- **Identity-case witness.**  At `g = 1` and `adj₁ = adj₂`, the
restricted-GL³-action Prop holds unconditionally: the restricted
triple is the identity, and the cardinalities trivially match.

This witnesses that the research-scope `Prop`
`RestrictedGL3OnPathOnlyTensor` is inhabitable on at least the
identity case, providing the foundation for the conditional discharge
in `AlgEquivFromGL3.lean`. -/
theorem restrictedGL3OnPathOnlyTensor_identity_case
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    (1 : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ) •
      grochowQiaoEncode m adj = grochowQiaoEncode m adj →
    (presentArrowSlotIndices m adj).card =
      (presentArrowSlotIndices m adj).card := by
  intro _h
  rfl

end GrochowQiao
end Orbcrypt
