/-
Polynomial-identity catalogue for the Grochow–Qiao encoder
(R-TI Phase 3 / Sub-task A.1).

Catalogues the family of polynomial identities the encoder
`grochowQiaoEncode m adj : Tensor3 (dimGQ m) ℚ` satisfies.  The Phase 3
algebra-iso construction (Approach A) consumes these identities as the
central technical lever: GL³ tensor isomorphisms preserve them
(Sub-task A.2), and the partition-preservation argument
(Sub-task A.3) then combines the identities with the encoder's
distinguished-padding structure to derive a slot permutation
preserving the path/padding partition.

See `docs/planning/R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md`
§ "Sub-task A.1 — Encoder polynomial-identity catalogue" for the
work-unit decomposition.
-/

import Orbcrypt.Hardness.GrochowQiao.EncoderSlabEval

/-!
# Encoder polynomial identities (Sub-task A.1)

The Grochow–Qiao encoder `grochowQiaoEncode m adj : Tensor3 (dimGQ m) ℚ`
satisfies a family of polynomial identities — relations among the
encoder's entries that hold for *every* graph `adj`.  This module
catalogues the identities consumed by Phase 3's algebra-iso
construction (Approach A) under the partial-discharge path that lands
the deep multilinear-algebra content as a single named research-scope
`Prop` (`GL3InducesAlgEquivOnPathSubspace`, declared in
`AlgEquivFromGL3.lean`).

## Catalogued identities

* **Associativity (path-algebra slots)** — re-export of
  `encoder_associativity_identity` from `EncoderSlabEval.lean`:
  ```
  ∑ a, encode m adj i j a · encode m adj a k l =
    ∑ a, encode m adj j k a · encode m adj i a l
  ```
  for every path-algebra quadruple `(i, j, k, l)`.

* **Path-algebra diagonal in `{0, 1}`** — at every path-algebra slot
  `i`, the diagonal value `encode m adj i i i` is either `0` (if `i`
  is a present-arrow slot) or `1` (if `i` is a vertex slot).  No path-
  algebra slot has diagonal value `2`.

* **Padding diagonal value `2`** — re-export of
  `encoder_at_padding_diagonal_eq_two` in slot-discriminator form.

* **Mixed-class triples vanish** — re-export of
  `encoder_zero_at_mixed_triples`: any non-zero encoder entry has all
  three slots in the same partition class (path-algebra or padding).

* **Padding slabs are trivial-algebra** — at any padding slot `i`, the
  encoder's slab `encode m adj i j k` is non-zero iff
  `j = i ∧ k = i`.  This is the **trivial-algebra identity** witnessing
  that the padding portion is a direct sum of trivial 1-dimensional
  algebras (the diagonal entries scaled by `2`).

## Status

All identities land unconditionally; every `#print axioms` reports the
standard Lean trio only.  The identities are pure structural
consequences of `EncoderSlabEval.lean`'s per-slot evaluation lemmas
plus `pathMul_assoc` (basis-element-level associativity from
`PathAlgebra.lean`).

The detailed **unit-compatibility identity**
`∑_v T(vertex v, j, k) = δ(slotToArrow slot_j, slotToArrow slot_k)`
(Sub-task A.1.5) is consumed only by Sub-task A.5 (Manin's tensor-
stabilizer theorem), which is genuinely research-scope (multi-month,
~600 LOC, requires Mathlib content not present at the pinned commit).
For the partial-discharge path, that content is captured as the `Prop`
`GL3InducesAlgEquivOnPathSubspace` consumed by
`Orbcrypt/Hardness/GrochowQiao/AlgEquivFromGL3.lean`; the unit-
compatibility identity is part of that `Prop`'s discharge obligation
and is not needed by the conditional-iso machinery itself.

## Naming

Identifiers describe content (associativity, diagonal classification,
trivial-algebra identity), not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt

-- ============================================================================
-- Sub-task A.1.0 — Re-export of the associativity identity.
-- ============================================================================

/-- **Sub-task A.1.0 — Encoder associativity identity (path-algebra slots).**

Re-export of `encoder_associativity_identity` from `EncoderSlabEval.lean`
under a Phase-3-facing name.  For every path-algebra quadruple
`(i, j, k, l)`,
```
∑ a, encode m adj i j a · encode m adj a k l =
  ∑ a, encode m adj j k a · encode m adj i a l.
```

This is the central polynomial identity Sub-task A.2 will preserve
under GL³ action and Sub-task A.5 will consume in the Manin-style
algebra-iso construction. -/
theorem encoder_assoc_path (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j k l : Fin (dimGQ m))
    (hi : isPathAlgebraSlot m adj i = true)
    (hj : isPathAlgebraSlot m adj j = true)
    (hk : isPathAlgebraSlot m adj k = true)
    (hl : isPathAlgebraSlot m adj l = true) :
    (∑ a : Fin (dimGQ m), grochowQiaoEncode m adj i j a *
                          grochowQiaoEncode m adj a k l) =
    (∑ a : Fin (dimGQ m), grochowQiaoEncode m adj j k a *
                          grochowQiaoEncode m adj i a l) :=
  encoder_associativity_identity m adj i j k l hi hj hk hl

-- ============================================================================
-- Sub-task A.1.1 — Diagonal value at path-algebra slots is in {0, 1}.
-- ============================================================================

/-- **Sub-task A.1.1 — Path-algebra diagonal is in `{0, 1}`.**

For every path-algebra slot `i`, the encoder's diagonal value
`encode m adj i i i` is either `0` or `1`:

* If `i = vertex v` (a vertex slot), the diagonal is `1`
  (`grochowQiaoEncode_diagonal_vertex` — the idempotent law
  `e_v · e_v = e_v` in the path algebra).
* If `i = arrow u v` with `adj u v = true` (a present-arrow slot),
  the diagonal is `0` (`grochowQiaoEncode_diagonal_present_arrow` —
  follows from `J² = 0`, since `pathMul (.edge u v) (.edge u v) = none`).

Together, the identity exhibits the algebraic distinction between
vertex slots and present-arrow slots at the diagonal-value level
within the path-algebra subspace.  Sub-task A.3.5's three-partition
refinement consumes this distinction. -/
theorem encoder_diag_at_path_in_zero_one
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i : Fin (dimGQ m))
    (hi : isPathAlgebraSlot m adj i = true) :
    grochowQiaoEncode m adj i i i = 0 ∨
    grochowQiaoEncode m adj i i i = 1 := by
  -- Case-split on `slotEquiv m i`.
  cases hsi : slotEquiv m i with
  | vertex v =>
      right
      have hi_eq : i = (slotEquiv m).symm (.vertex v) := by
        rw [← hsi, Equiv.symm_apply_apply]
      rw [hi_eq]
      exact grochowQiaoEncode_diagonal_vertex m adj v
  | arrow u v =>
      left
      -- `i` is path-algebra ⇒ `adj u v = true` (the path-algebra discriminator).
      have h_adj : adj u v = true := by
        have := hi
        unfold isPathAlgebraSlot at this
        rw [hsi] at this
        exact this
      have hi_eq : i = (slotEquiv m).symm (.arrow u v) := by
        rw [← hsi, Equiv.symm_apply_apply]
      rw [hi_eq]
      exact grochowQiaoEncode_diagonal_present_arrow m adj u v h_adj

-- ============================================================================
-- Sub-task A.1.2 — Diagonal value at padding slots is exactly 2.
-- ============================================================================

/-- **Sub-task A.1.2 — Padding diagonal is exactly `2`.**

Re-export of `grochowQiaoEncode_diagonal_padding` (Stage 0
distinguished-padding strengthening) under a Phase-3-facing name and
in slot-discriminator form: at any padding slot `i` (i.e.,
`isPathAlgebraSlot m adj i = false`), the encoder's diagonal value
`encode m adj i i i` is `2`.

Combined with Sub-task A.1.1 (diagonal in `{0, 1}` on path-algebra
slots), this gives the three-way diagonal-value separation:

* vertex slot diagonal: `1`,
* present-arrow slot diagonal: `0`,
* padding slot diagonal: `2`.

The three values are pairwise distinct, witnessing that the encoder's
diagonal scalar literally identifies its slot kind.  This closes the
isolated-vertex degeneracy that motivated Stage 0 and is the
post-Stage-0 anchor of the rigidity argument. -/
theorem encoder_diag_at_padding_eq_two
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i : Fin (dimGQ m))
    (hi : isPathAlgebraSlot m adj i = false) :
    grochowQiaoEncode m adj i i i = 2 := by
  -- A padding slot is necessarily an arrow slot with `adj u v = false`,
  -- because vertex slots are unconditionally path-algebra.
  cases hsi : slotEquiv m i with
  | vertex v =>
      -- Vertex slots always have `isPathAlgebraSlot = true`,
      -- contradicting `hi`.
      exfalso
      have h_path : isPathAlgebraSlot m adj i = true := by
        unfold isPathAlgebraSlot
        rw [hsi]
      rw [hi] at h_path
      exact Bool.noConfusion h_path
  | arrow u v =>
      have h_adj : adj u v = false := by
        have := hi
        unfold isPathAlgebraSlot at this
        rw [hsi] at this
        exact this
      exact encoder_at_padding_diagonal_eq_two m adj i u v hsi h_adj

-- ============================================================================
-- Sub-task A.1.3 — Off-diagonal mixed (path/padding) entries vanish.
-- ============================================================================

/-- **Sub-task A.1.3 — Off-diagonal path/padding entries vanish.**

Re-export of `encoder_zero_at_mixed_triples` in the form Sub-task A.3
will consume.  If at least one slot of a triple `(i, j, k)` is path-
algebra and at least one is padding (so the three slots do not all lie
in the same partition class), then the encoder evaluates to zero.

This is the **partition-aligned support** identity: the encoder's
non-zero entries split cleanly into "all-path" or "all-padding" triples
with no mixed entries. -/
theorem encoder_off_diag_path_padding_zero
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i j k : Fin (dimGQ m))
    (h_mixed :
      ¬ (isPathAlgebraSlot m adj i = true ∧
         isPathAlgebraSlot m adj j = true ∧
         isPathAlgebraSlot m adj k = true) ∧
      ¬ (isPathAlgebraSlot m adj i = false ∧
         isPathAlgebraSlot m adj j = false ∧
         isPathAlgebraSlot m adj k = false)) :
    grochowQiaoEncode m adj i j k = 0 :=
  encoder_zero_at_mixed_triples m adj i j k h_mixed

-- ============================================================================
-- Sub-task A.1.4 — Padding slabs are trivial-algebra (diagonal only).
-- ============================================================================

/-- **Sub-task A.1.4 — Padding-slot non-zero entries are diagonal only.**

For any padding slot `i` (`isPathAlgebraSlot m adj i = false`), the
encoder's slab `encode m adj i j k` is non-zero iff
`j = i ∧ k = i` — i.e., only the triple-diagonal `(i, i, i)` carries
non-zero content.

This is the **trivial-algebra identity**: the padding portion is a
direct sum of trivial 1-dimensional algebras, each spanned by a single
padding slot.  This shape distinguishes padding slots from path-algebra
slots, where multiple non-zero entries arise from the path-algebra
multiplication table. -/
theorem encoder_padding_diag_only
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i j k : Fin (dimGQ m))
    (hi : isPathAlgebraSlot m adj i = false) :
    grochowQiaoEncode m adj i j k ≠ 0 ↔ (j = i ∧ k = i) := by
  -- The first slot is padding ⇒ encoder takes the ambient branch
  -- ⇒ value is `2` if `i = j ∧ j = k`, else `0`.
  rw [grochowQiaoEncode_padding_left m adj i j k hi]
  unfold ambientSlotStructureConstant
  constructor
  · intro h_nz
    by_contra h_not
    -- If not (j = i ∧ k = i), then the if-then-else returns 0.
    have h_if_zero : (if i = j ∧ j = k then (2 : ℚ) else 0) = 0 := by
      apply if_neg
      rintro ⟨hij, hjk⟩
      apply h_not
      exact ⟨hij.symm, by rw [← hjk, ← hij]⟩
    exact h_nz h_if_zero
  · rintro ⟨hji, hki⟩
    rw [hji, hki]
    simp

end GrochowQiao
end Orbcrypt
