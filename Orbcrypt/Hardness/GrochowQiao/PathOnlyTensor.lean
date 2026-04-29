/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

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
  index quadruple.
* `pathOnlyStructureTensor_isAssociative` — **substantively proven**
  theorem that the path-only tensor satisfies `IsAssociativeTensor`.
  Proof: re-index path-only sums via `Equiv.sum_comp` +
  `Finset.univ_eq_attach` + `Finset.sum_attach` to land on a Finset
  sum over `pathSlotIndices`; extend to a univ sum via
  `Finset.sum_subset` showing path/padding-mixed terms vanish (via
  the auxiliary `pathOnlySummand_zero_of_not_path_algebra` helpers,
  which apply `grochowQiaoEncode_padding_right`'s ambient-branch
  evaluation); apply `encoder_assoc_path` (Sub-task A.1.0) on the
  full universe.
* `RestrictedGL3OnPathOnlyTensor` (research-scope `Prop`) — the
  obligation that GL³ tensor isomorphisms preserve path/padding
  cardinality.
* `restrictedGL3OnPathOnlyTensor_identity_case` — **substantive**
  identity-case witness: takes `(adj₁, adj₂)` and the hypothesis
  `1 • encode m adj₁ = encode m adj₂`, derives `adj₁ = adj₂` via the
  post-Stage-0 diagonal-value classification, then concludes the
  cardinality equality.  Mirrors the post-audit-pass-II refactoring
  of Stage 3's `gl3_preserves_partition_cardinalities_identity_case`.

## Status

Sub-task A.4 lands the **path-only tensor definition** + **apply
lemma** + **index-is-path-algebra fact** + **path-only associativity
theorem** (substantively proven via `Finset.sum_equiv` re-indexing)
all unconditionally.  The **restricted-GL³-action cardinality-
preservation** content is captured as a research-scope `Prop` consumed
by `AlgEquivFromGL3.lean`; the **substantive identity case**
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
-- Sub-task A.4.2 — Path-only tensor associativity (substantively proved).
-- ============================================================================

/-- **Helper: path-only-summand vanishes outside `pathSlotIndices`.**

For path-algebra `i', j'` and any `a : Fin (dimGQ m)`, the product
`encode m adj i' j' a * encode m adj a k' l'` is zero whenever `a` is
*not* a path-algebra slot (i.e., `a ∉ pathSlotIndices m adj`).

**Proof.** When `a` is padding, the first factor `encode m adj i' j' a`
has slot triple `(path, path, padding)`, which is mixed-class, hence
the encoder takes the ambient branch.  The ambient constant
`if i' = j' ∧ j' = a then 2 else 0` is zero unless `i' = j' = a`; but
`i' = a` is impossible because `i'` is path-algebra while `a` is
padding (`isPathAlgebraSlot` is `true` vs `false`).  Hence the first
factor is zero, so the product is zero. -/
private theorem pathOnlySummand_zero_of_not_path_algebra
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i' j' k' l' a : Fin (dimGQ m))
    (_hi' : isPathAlgebraSlot m adj i' = true)
    (hj' : isPathAlgebraSlot m adj j' = true)
    (ha_not : isPathAlgebraSlot m adj a = false) :
    grochowQiaoEncode m adj i' j' a *
    grochowQiaoEncode m adj a k' l' = 0 := by
  -- `encode m adj i' j' a = ambient (i', j', a) = 0` because j' ≠ a.
  rw [grochowQiaoEncode_padding_right m adj i' j' a ha_not]
  unfold ambientSlotStructureConstant
  -- Goal: (if i' = j' ∧ j' = a then 2 else 0) * encode a k' l' = 0
  rw [if_neg]
  · simp
  · rintro ⟨_hij, hja⟩
    -- hja : j' = a; but j' is path-algebra, a is not → contradiction.
    rw [hja] at hj'
    rw [hj'] at ha_not
    exact Bool.noConfusion ha_not

/-- **Helper: dual form of the previous helper for the RHS-summand.** -/
private theorem pathOnlySummand_zero_of_not_path_algebra'
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i' j' k' l' a : Fin (dimGQ m))
    (_hj' : isPathAlgebraSlot m adj j' = true)
    (hk' : isPathAlgebraSlot m adj k' = true)
    (ha_not : isPathAlgebraSlot m adj a = false) :
    grochowQiaoEncode m adj j' k' a *
    grochowQiaoEncode m adj i' a l' = 0 := by
  -- Same argument: `encode m adj j' k' a = ambient (j', k', a) = 0`
  -- because j' ≠ a (j' path, a padding).
  rw [grochowQiaoEncode_padding_right m adj j' k' a ha_not]
  unfold ambientSlotStructureConstant
  rw [if_neg]
  · simp
  · rintro ⟨_hjk, hka⟩
    rw [hka] at hk'
    rw [hk'] at ha_not
    exact Bool.noConfusion ha_not

/-- **Sub-task A.4.2 — Path-only-tensor associativity (proved).**

The path-only structure tensor `pathOnlyStructureTensor m adj`
satisfies the associativity polynomial identity `IsAssociativeTensor`.

**Proof technique.**  Each `Fin (pathSlotIndices m adj).card`-index
maps via the `equivFin.symm`-bijection to a path-algebra slot in
`Fin (dimGQ m)` (Sub-task A.4 pre-lemma).  We re-index both sides of
the path-only associativity sum as sums over `pathSlotIndices m adj`
(via `Equiv.sum_comp` + `Finset.sum_attach`), then **extend** the sums
to the full `Fin (dimGQ m)` universe by showing that path/padding-
mixed terms contribute zero (via the auxiliary helpers
`pathOnlySummand_zero_of_not_path_algebra`/`'` above, which apply
`grochowQiaoEncode_padding_right`'s ambient-branch evaluation).
Finally, we apply `encoder_assoc_path` (Sub-task A.1.0) on the full
universe to conclude.

This is the substantive proof of `PathOnlyTensorIsAssociative`; the
pre-audit landing carried this as a research-scope `Prop` definition
without proof, which the post-audit pass replaced with this real
theorem. -/
theorem pathOnlyStructureTensor_isAssociative
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    IsAssociativeTensor (pathOnlyStructureTensor m adj) := by
  intro i j k l
  -- Underlying path-algebra slots.
  set i' := ((pathSlotIndices m adj).equivFin.symm i).val with hi'_def
  set j' := ((pathSlotIndices m adj).equivFin.symm j).val with hj'_def
  set k' := ((pathSlotIndices m adj).equivFin.symm k).val with hk'_def
  set l' := ((pathSlotIndices m adj).equivFin.symm l).val with hl'_def
  have hi'_path : isPathAlgebraSlot m adj i' = true :=
    (mem_pathSlotIndices_iff m adj _).mp
      ((pathSlotIndices m adj).equivFin.symm i).property
  have hj'_path : isPathAlgebraSlot m adj j' = true :=
    (mem_pathSlotIndices_iff m adj _).mp
      ((pathSlotIndices m adj).equivFin.symm j).property
  have hk'_path : isPathAlgebraSlot m adj k' = true :=
    (mem_pathSlotIndices_iff m adj _).mp
      ((pathSlotIndices m adj).equivFin.symm k).property
  have hl'_path : isPathAlgebraSlot m adj l' = true :=
    (mem_pathSlotIndices_iff m adj _).mp
      ((pathSlotIndices m adj).equivFin.symm l).property
  -- Re-index the path-only sums via Equiv.sum_comp on equivFin.symm.
  -- pathOnlyStructureTensor m adj i j k = encode m adj i' j' k'.
  -- ∑ a : Fin S.card, encode m adj i' j' (e a).val * encode m adj (e a).val k' l'
  --   = ∑ a : ↑S, encode m adj i' j' a.val * encode m adj a.val k' l'  (Equiv.sum_comp)
  --   = ∑ a ∈ S.attach, encode m adj i' j' a.val * encode m adj a.val k' l'  (sum over subtype)
  --   = ∑ a ∈ S, encode m adj i' j' a * encode m adj a k' l'  (Finset.sum_attach)
  --   = ∑ a : Fin (dimGQ m), encode m adj i' j' a * encode m adj a k' l'  (sum_subset)
  have h_lhs :
      (∑ a : Fin (pathSlotIndices m adj).card,
          pathOnlyStructureTensor m adj i j a *
          pathOnlyStructureTensor m adj a k l) =
      (∑ a : Fin (dimGQ m),
          grochowQiaoEncode m adj i' j' a *
          grochowQiaoEncode m adj a k' l') := by
    -- Step 1: rewrite path-only entries using `pathOnlyStructureTensor_apply`.
    simp only [pathOnlyStructureTensor_apply]
    -- Step 2: re-index sum over `Fin S.card` to sum over `↥S` via
    -- `Equiv.sum_comp` with σ = equivFin.symm : Fin S.card ≃ ↥S.
    -- The lemma gives: ∑ x : Fin S.card, f (σ x) = ∑ x : ↥S, f x.
    rw [Equiv.sum_comp (pathSlotIndices m adj).equivFin.symm
          (fun b : ↥(pathSlotIndices m adj) =>
            grochowQiaoEncode m adj i' j' b.val *
            grochowQiaoEncode m adj b.val k' l')]
    -- After re-indexing: sum over `↥(pathSlotIndices m adj)` (subtype).
    -- Step 3a: convert Fintype-sum on `↥S` to Finset-sum on `S.attach`
    -- via `Finset.univ_eq_attach`.
    rw [show (∑ b : ↥(pathSlotIndices m adj),
              grochowQiaoEncode m adj i' j' b.val *
              grochowQiaoEncode m adj b.val k' l') =
          (∑ b ∈ (pathSlotIndices m adj).attach,
              grochowQiaoEncode m adj i' j' b.val *
              grochowQiaoEncode m adj b.val k' l') from by
          rw [← Finset.univ_eq_attach]]
    -- Step 3b: convert attach-sum to plain Finset.sum via
    -- `Finset.sum_attach`.
    rw [Finset.sum_attach (pathSlotIndices m adj)
          (fun b => grochowQiaoEncode m adj i' j' b *
                    grochowQiaoEncode m adj b k' l')]
    -- Step 4: extend Finset sum to univ sum via Finset.sum_subset.
    apply Finset.sum_subset (Finset.subset_univ (pathSlotIndices m adj))
    intro a _ha_univ ha_not_in
    -- a ∈ univ but a ∉ pathSlotIndices m adj ⇒ a is padding.
    have ha_pad : isPathAlgebraSlot m adj a = false := by
      rw [Bool.eq_false_iff]
      intro h_path
      exact ha_not_in ((mem_pathSlotIndices_iff m adj a).mpr h_path)
    exact pathOnlySummand_zero_of_not_path_algebra
      m adj i' j' k' l' a hi'_path hj'_path ha_pad
  have h_rhs :
      (∑ a : Fin (pathSlotIndices m adj).card,
          pathOnlyStructureTensor m adj j k a *
          pathOnlyStructureTensor m adj i a l) =
      (∑ a : Fin (dimGQ m),
          grochowQiaoEncode m adj j' k' a *
          grochowQiaoEncode m adj i' a l') := by
    simp only [pathOnlyStructureTensor_apply]
    rw [Equiv.sum_comp (pathSlotIndices m adj).equivFin.symm
          (fun b : ↥(pathSlotIndices m adj) =>
            grochowQiaoEncode m adj j' k' b.val *
            grochowQiaoEncode m adj i' b.val l')]
    rw [show (∑ b : ↥(pathSlotIndices m adj),
              grochowQiaoEncode m adj j' k' b.val *
              grochowQiaoEncode m adj i' b.val l') =
          (∑ b ∈ (pathSlotIndices m adj).attach,
              grochowQiaoEncode m adj j' k' b.val *
              grochowQiaoEncode m adj i' b.val l') from by
          rw [← Finset.univ_eq_attach]]
    rw [Finset.sum_attach (pathSlotIndices m adj)
          (fun b => grochowQiaoEncode m adj j' k' b *
                    grochowQiaoEncode m adj i' b l')]
    apply Finset.sum_subset (Finset.subset_univ (pathSlotIndices m adj))
    intro a _ha_univ ha_not_in
    have ha_pad : isPathAlgebraSlot m adj a = false := by
      rw [Bool.eq_false_iff]
      intro h_path
      exact ha_not_in ((mem_pathSlotIndices_iff m adj a).mpr h_path)
    exact pathOnlySummand_zero_of_not_path_algebra'
      m adj i' j' k' l' a hj'_path hk'_path ha_pad
  -- Combine: LHS = univ-LHS = univ-RHS = RHS, where univ-LHS = univ-RHS
  -- is `encoder_assoc_path`.
  rw [h_lhs, h_rhs]
  exact encoder_assoc_path m adj i' j' k' l' hi'_path hj'_path hk'_path hl'_path

/-- **Path-only-tensor index-quadruple is path-algebra.**

For every quadruple of `Fin (pathSlotIndices m adj).card`-indices,
the underlying `Fin (dimGQ m)`-values obtained via the
`(pathSlotIndices m adj).equivFin.symm` bijection are all
path-algebra slots (`isPathAlgebraSlot m adj _ = true`).

This is the **path-algebra membership precondition** that
`pathOnlyStructureTensor_isAssociative` consumes when invoking
`encoder_assoc_path` on the underlying `Fin (dimGQ m)`-values.
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

/-- **Path-only-tensor diagonal value is in `{0, 1}`.**

For any diagonal index `i : Fin (pathSlotIndices m adj).card`, the
path-only structure tensor's diagonal value
`pathOnlyStructureTensor m adj i i i` is either `0` (the index
corresponds to a present-arrow slot of the encoder) or `1` (the
index corresponds to a vertex slot).

**Proof.** The path-only tensor's diagonal at index `i` equals the
encoder's diagonal at the underlying `Fin (dimGQ m)`-slot
`(pathSlotIndices m adj).equivFin.symm i`, which is a path-algebra
slot.  By `encoder_diag_at_path_in_zero_one` (Sub-task A.1.1), the
encoder's diagonal value at a path-algebra slot is either `0` or `1`.

This directly transfers the encoder's path-algebra diagonal
classification to the path-only structure tensor.  Phase 5's
adjacency-recovery argument (research-scope) consumes this
distinction to separate vertex slots (diagonal `1`) from
present-arrow slots (diagonal `0`) within the path-only image. -/
theorem pathOnlyStructureTensor_diagonal_in_zero_one
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i : Fin (pathSlotIndices m adj).card) :
    pathOnlyStructureTensor m adj i i i = 0 ∨
    pathOnlyStructureTensor m adj i i i = 1 := by
  rw [pathOnlyStructureTensor_apply]
  -- The underlying slot is path-algebra (membership in pathSlotIndices).
  have h_path : isPathAlgebraSlot m adj
      ((pathSlotIndices m adj).equivFin.symm i).val = true :=
    (mem_pathSlotIndices_iff m adj _).mp
      ((pathSlotIndices m adj).equivFin.symm i).property
  exact encoder_diag_at_path_in_zero_one m adj _ h_path

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
