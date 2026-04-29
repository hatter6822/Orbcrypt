/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
Padding rigidity: trivial-algebra identity + concentrated-slot
characterisation (R-TI Phase 3 / Sub-task A.3.1 + A.3.2).

Establishes the **padding-portion structural identity**: at any
padding slot `i`, the encoder's slab is concentrated at the
triple-diagonal `(i, i, i)` with value `2`, witnessing that the
padding portion of the encoder is a direct sum of trivial 1-dim
algebras.

Consumed by `PartitionRigidity.lean` (A.3.3 + A.3.5) as the
foundation for the partition-cardinality preservation argument.

See `docs/planning/AUDIT_2026-04-28_PHASE_3_PROP_DISCHARGE_PLAN.md`
§ "A.3.1 — Padding trivial-algebra identity" + "A.3.2 —
paddingRankInvariant".
-/

import Orbcrypt.Hardness.GrochowQiao.EncoderPolynomialIdentities

/-!
# Padding rigidity (Sub-task A.3.1 + A.3.2)

## Mathematical content

The Grochow–Qiao encoder restricted to padding slots has a very
specific shape: at any padding slot `i = (slotEquiv).symm (.arrow u v)`
with `adj u v = false`, the slab `T(i, j, k)` is non-zero iff
`j = k = i`, and the diagonal value is `2`:
```
T(i, j, k) = if i = j ∧ j = k then 2 else 0     (when i is padding)
```

This means the padding portion of the encoder is a **direct sum of
trivial 1-dimensional algebras**, each spanned by a single padding
slot (with the unit `e_i = 2 · 1_F` after rescaling).

## Public surface

* `encoder_padding_trivial_algebra` — the shape identity at padding
  slots (a re-export of `encoder_padding_diag_only` in slot-form).
* `IsConcentratedSlot` — predicate for "this slot has rank-1-supported
  slabs concentrated at the triple-diagonal with value `2`".
* `paddingRankInvariant` — the GL³-invariant counting concentrated
  slots; equals `(paddingSlotIndices m adj).card` on the encoder.
* `paddingRankInvariant_eq_paddingSlotIndices_card` — the encoder
  evaluation theorem.

## Status

Sub-tasks A.3.1 + A.3.2.1–A.3.2.3 land unconditionally.

The originally-planned GL³-invariance Prop for `paddingRankInvariant`
is **not** required by the partial-discharge form of Phase 3
(`Discharge.lean` discharges both Phase 3 research-scope Props
`GL3InducesAlgEquivOnPathSubspace` and `RestrictedGL3OnPathOnlyTensor`
directly from `GrochowQiaoRigidity` via the σ-induced
`quiverPermAlgEquiv` infrastructure, bypassing the padding-rank
invariant entirely).  This module's content stands as standalone
**structural mathematical content** about the encoder: the encoder's
diagonal value is `2` exactly at padding slots, and
`paddingRankInvariant` (counting concentrated slots) equals the
padding-slot count.  It documents the padding portion's algebraic
shape — a direct sum of trivial 1-dim algebras — even though the
final discharge does not consume it.

## Naming

Identifiers describe content (padding trivial-algebra, concentrated
slot, padding-rank invariant), not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt
open scoped BigOperators

-- ============================================================================
-- Sub-task A.3.1 — Padding trivial-algebra identity (re-export).
-- ============================================================================

/-- **Sub-task A.3.1 — Padding trivial-algebra identity.**

For any padding slot `i` (`isPathAlgebraSlot m adj i = false`), the
encoder evaluates as:
```
T(i, j, k) = if i = j ∧ j = k then 2 else 0
```

This re-exports `encoder_padding_diag_only` (Sub-task A.1.4) in the
slot-discriminator form. -/
theorem encoder_padding_trivial_algebra
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i j k : Fin (dimGQ m))
    (hi : isPathAlgebraSlot m adj i = false) :
    grochowQiaoEncode m adj i j k =
      (if i = j ∧ j = k then (2 : ℚ) else 0) := by
  -- Apply grochowQiaoEncode_padding_left to switch to ambient branch.
  rw [grochowQiaoEncode_padding_left m adj i j k hi]
  -- Unfold ambient: ambient i j k = if i = j ∧ j = k then 2 else 0.
  rfl

-- ============================================================================
-- Sub-task A.3.2.1 — IsConcentratedSlot predicate.
-- ============================================================================

/-- **Sub-task A.3.2.1 — Concentrated-slot predicate.**

A slot index `i : Fin n` is *concentrated* in a tensor `T : Tensor3 n ℚ`
if the three slabs `T(i, ·, ·)`, `T(·, i, ·)`, `T(·, ·, i)` are all
supported only at the triple-diagonal `(i, i, i)` with value `2`.

Equivalently: `T(i, j, k) ≠ 0 ⟹ (j = i ∧ k = i)`, and similarly for
the other two slabs through `i`, and `T(i, i, i) = 2`. -/
def IsConcentratedSlot {n : ℕ} (T : Tensor3 n ℚ) (i : Fin n) : Prop :=
  T i i i = 2 ∧
  (∀ j k, T i j k = 0 ∨ (j = i ∧ k = i)) ∧
  (∀ j k, T j i k = 0 ∨ (j = i ∧ k = i)) ∧
  (∀ j k, T j k i = 0 ∨ (j = i ∧ k = i))

-- ============================================================================
-- Sub-task A.3.2.2 — paddingRankInvariant.
-- ============================================================================

/-- **Sub-task A.3.2 — Padding-rank invariant.**

The number of concentrated slots in a tensor `T`.

Uses `Classical.dec` for the filter predicate (since `IsConcentratedSlot`
involves universal quantifiers over `Fin n`). -/
noncomputable def paddingRankInvariant {n : ℕ} (T : Tensor3 n ℚ) : ℕ :=
  open Classical in
  (Finset.univ.filter fun i => IsConcentratedSlot T i).card

/-- Helper: `isPathAlgebraSlot m adj i = false` iff
`i ∈ paddingSlotIndices m adj`. -/
private theorem isPathAlgebraSlot_false_iff_mem_paddingSlotIndices
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i : Fin (dimGQ m)) :
    isPathAlgebraSlot m adj i = false ↔ i ∈ paddingSlotIndices m adj := by
  constructor
  · intro h
    rw [mem_paddingSlotIndices_iff]
    cases hslot : slotEquiv m i with
    | vertex w =>
      exfalso
      unfold isPathAlgebraSlot at h
      rw [hslot] at h
      exact Bool.noConfusion h
    | arrow u v =>
      refine ⟨u, v, rfl, ?_⟩
      unfold isPathAlgebraSlot at h
      rw [hslot] at h
      exact h
  · intro h_pad
    rw [mem_paddingSlotIndices_iff] at h_pad
    obtain ⟨u, v, hslot, h_adj⟩ := h_pad
    unfold isPathAlgebraSlot
    rw [hslot]
    exact h_adj

/-- **Sub-task A.3.2.2 — Encoder evaluation: invariant equals padding-slot
cardinality.**

For the Grochow–Qiao encoder, the padding-rank invariant equals
`(paddingSlotIndices m adj).card` — every padding slot is concentrated
(by A.3.1), and no path-algebra slot is concentrated (because vertex
slots have diagonal value `1` and present-arrow slots have diagonal
value `0`, neither matching the required value `2`). -/
theorem paddingRankInvariant_eq_paddingSlotIndices_card
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    paddingRankInvariant (grochowQiaoEncode m adj) =
      (paddingSlotIndices m adj).card := by
  classical
  -- Show the filter Finset equals `paddingSlotIndices m adj`, then card.
  unfold paddingRankInvariant
  congr 1
  ext i
  simp only [Finset.mem_filter, Finset.mem_univ, true_and]
  rw [← isPathAlgebraSlot_false_iff_mem_paddingSlotIndices]
  constructor
  · -- Concentrated ⇒ isPathAlgebraSlot = false.
    rintro ⟨h_diag, _, _, _⟩
    -- T(i, i, i) = 2.  If `i` were path-algebra, the diagonal would be
    -- 0 or 1 (`encoder_diag_at_path_in_zero_one`), not 2.
    cases h : isPathAlgebraSlot m adj i with
    | true =>
      exfalso
      rcases encoder_diag_at_path_in_zero_one m adj i h with h0 | h1
      · rw [h0] at h_diag; norm_num at h_diag
      · rw [h1] at h_diag; norm_num at h_diag
    | false => rfl
  · -- isPathAlgebraSlot = false ⇒ Concentrated.
    intro h_pad
    refine ⟨?_, ?_, ?_, ?_⟩
    · -- T(i, i, i) = 2 (encoder_padding_trivial_algebra at j = k = i).
      rw [encoder_padding_trivial_algebra m adj i i i h_pad]
      simp
    · -- ∀ j k, T(i, j, k) = 0 ∨ (j = i ∧ k = i).
      intro j k
      rw [encoder_padding_trivial_algebra m adj i j k h_pad]
      by_cases h : i = j ∧ j = k
      · -- i = j = k: returns 2 (≠ 0), so we need (j = i ∧ k = i).
        right
        exact ⟨h.1.symm, by rw [← h.2, ← h.1]⟩
      · left; exact if_neg h
    · -- ∀ j k, T(j, i, k) = 0 ∨ (j = i ∧ k = i).
      intro j k
      -- Encoder at slot triple (j, i, k).  If j is path-algebra, the
      -- triple is mixed (path, padding, ?) and equals 0 by A.1.3.
      -- If j is padding, use trivial-algebra identity at slot j.
      by_cases hj_path : isPathAlgebraSlot m adj j = true
      · -- j path: the triple has at least one path slot (j) and one padding
        -- slot (i), so it's mixed-class ⇒ encoder = 0.
        left
        apply encoder_off_diag_path_padding_zero
        refine ⟨?_, ?_⟩
        · rintro ⟨_, hi_p, _⟩
          rw [h_pad] at hi_p
          exact Bool.noConfusion hi_p
        · rintro ⟨hj_f, _, _⟩
          rw [hj_path] at hj_f
          exact Bool.noConfusion hj_f
      · -- j padding: use trivial-algebra identity.
        have hj_pad : isPathAlgebraSlot m adj j = false := by
          cases h : isPathAlgebraSlot m adj j with
          | true => exact absurd h hj_path
          | false => rfl
        rw [encoder_padding_trivial_algebra m adj j i k hj_pad]
        by_cases h : j = i ∧ i = k
        · -- j = i and i = k.
          right
          exact ⟨h.1, h.2.symm⟩
        · left; exact if_neg h
    · -- ∀ j k, T(j, k, i) = 0 ∨ (j = i ∧ k = i).
      intro j k
      by_cases hj_path : isPathAlgebraSlot m adj j = true
      · left
        apply encoder_off_diag_path_padding_zero
        refine ⟨?_, ?_⟩
        · rintro ⟨_, _, hi_p⟩
          rw [h_pad] at hi_p
          exact Bool.noConfusion hi_p
        · rintro ⟨hj_f, _, _⟩
          rw [hj_path] at hj_f
          exact Bool.noConfusion hj_f
      · have hj_pad : isPathAlgebraSlot m adj j = false := by
          cases h : isPathAlgebraSlot m adj j with
          | true => exact absurd h hj_path
          | false => rfl
        rw [encoder_padding_trivial_algebra m adj j k i hj_pad]
        by_cases h : j = k ∧ k = i
        · right
          -- h : j = k ∧ k = i.  Need to show j = i ∧ k = i.
          exact ⟨h.1.trans h.2, h.2⟩
        · left; exact if_neg h

end GrochowQiao
end Orbcrypt
