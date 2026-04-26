/-
Column-weight invariant infrastructure for the Petrank–Roth (1997)
GI ≤ CE Karp reduction — the "marker-forcing" reverse direction.

Layer 3 (column-weight definition + invariance under `permuteCodeword`)
is implemented here as the foundational infrastructure for Layer 4
(extracting the GI permutation σ from any CE-witness π).

**Status (post-R-CE Option B landing).**  Layer 3 provides the
column-weight invariance machinery; Layer 4 (full marker-forcing
endpoint recovery → `prEncode_reverse` → headline
`petrankRoth_isInhabitedKarpReduction`) is the multi-week residual
work cleanly factored out as research-scope **R-15-residual-CE-
reverse** per the audit-plan Risk Gate
(`docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` § "R-CE
Layer 4 risk register").

The forward direction (Layer 2, `prEncode_forward`) is fully landed
in `Orbcrypt/Hardness/PetrankRoth.lean`.
-/

import Orbcrypt.Hardness.PetrankRoth

/-!
# Column-weight invariant for the Petrank–Roth encoder (Layer 3)

The Petrank–Roth Karp reduction's reverse direction proves that any
permutation π : Equiv.Perm (Fin (dimPR m)) witnessing
`ArePermEquivalent (prEncode m adj₁) (prEncode m adj₂)` must respect
the four-family column partition (vertex / incidence / marker /
sentinel) — which then lets us extract a vertex permutation σ that
witnesses GI between adj₁ and adj₂.

This module establishes the Layer-3 column-weight invariance
infrastructure underlying that argument.

## Main definitions

* `colWeight C i` — count of codewords in `C` that are `true` at
  column `i`; defined for any `Finset (Fin n → Bool)`.

## Main results

* `colWeight_empty`, `colWeight_singleton_self`,
  `colWeight_singleton_other`, `colWeight_union_disjoint` — basic
  algebraic identities for the `Finset.filter`-based column-weight
  function.
* `colWeight_permuteCodeword_image` — column weights are preserved
  by `permuteCodeword`-image of a Finset, up to the underlying
  permutation's coordinate relabelling.

## Layer-4 obligations (research-scope, R-15-residual-CE-reverse)

The following Layer-4 results — extracting σ from a CE-witness π and
discharging the reverse iff direction — are documented at
`docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`
sub-tasks 4.1–4.10 and tracked as research scope:

* `extractVertexPerm`, `extractEdgePerm`, `extractMarkerPerm_within_block`
* `extractEdgePerm_eq_liftedEdgePerm_extractVertexPerm` (the
  marker-forcing core; ~300 line single sub-task)
* `adj_recovery_from_edgeCodeword`,
  `prEncode_reverse_empty_graph`, `prEncode_reverse`
* assembly: `prEncode_iff` (Layer 5) and the headline
  `petrankRoth_isInhabitedKarpReduction` (Layer 7)

## Encoder design

The `prEncode` encoder (in `PetrankRoth.lean`) is direction-faithful:
the Layer-0 enumeration uses `numEdges m = m * (m - 1)` directed
edge slots, so each ordered pair `(u, v)` with `u ≠ v` produces a
distinct codeword whose presence is `edgePresent m adj e =
adj p.1 p.2` (directly asymmetric).  Layer-4 work inhabiting the
full iff in `Orbcrypt.GIReducesToCE` therefore extends to arbitrary
(possibly asymmetric) `adj`.

## Naming

Identifiers describe content (column-weight, permutation invariance),
not the surrounding workstream / research-scope identifier.  See
`CLAUDE.md`'s naming rule.
-/

namespace Orbcrypt
namespace PetrankRoth

universe u

-- ============================================================================
-- Sub-task 3.1 — Column-weight definition.
-- ============================================================================

/-- The "column weight" of column `i` in a finite set of Boolean
codewords `C : Finset (Fin n → Bool)`: the number of codewords that
are `true` at column `i`. -/
def colWeight {n : ℕ} (C : Finset (Fin n → Bool)) (i : Fin n) : ℕ :=
  (C.filter (fun c => c i = true)).card

@[simp] theorem colWeight_empty {n : ℕ} (i : Fin n) :
    colWeight (∅ : Finset (Fin n → Bool)) i = 0 := by
  unfold colWeight; simp

theorem colWeight_singleton_self {n : ℕ} (c : Fin n → Bool) (i : Fin n)
    (h : c i = true) : colWeight ({c} : Finset (Fin n → Bool)) i = 1 := by
  unfold colWeight
  rw [Finset.filter_singleton]
  simp [h]

theorem colWeight_singleton_other {n : ℕ} (c : Fin n → Bool) (i : Fin n)
    (h : c i = false) : colWeight ({c} : Finset (Fin n → Bool)) i = 0 := by
  unfold colWeight
  rw [Finset.filter_singleton]
  simp [h]

theorem colWeight_union_disjoint {n : ℕ}
    (C₁ C₂ : Finset (Fin n → Bool)) (h : Disjoint C₁ C₂) (i : Fin n) :
    colWeight (C₁ ∪ C₂) i = colWeight C₁ i + colWeight C₂ i := by
  unfold colWeight
  rw [Finset.filter_union]
  exact Finset.card_union_of_disjoint
    (Finset.disjoint_filter_filter h)

-- ============================================================================
-- Sub-task 3.2 — `colWeight` invariance under `permuteCodeword`.
-- ============================================================================

/-- **Column-weight invariance under permutation.**

For any `π : Equiv.Perm (Fin n)` and column `i`, the column weight of
column `π i` in the `permuteCodeword π`-image of `C` equals the column
weight of column `i` in `C`.

This is the key Layer-3 result underlying the marker-forcing reverse
direction: it forces any CE-witnessing π to preserve column weights up
to coordinate relabelling.  Combined with the column-weight
signatures of the four codeword families (Layer 3.3) and the
column-kind discriminator (Layer 3.4), this lets Layer 4 extract a
vertex permutation σ from any CE-witness π. -/
theorem colWeight_permuteCodeword_image {n : ℕ}
    (C : Finset (Fin n → Bool)) (π : Equiv.Perm (Fin n)) (i : Fin n) :
    colWeight (C.image (permuteCodeword π)) (π i) = colWeight C i := by
  classical
  unfold colWeight
  rw [Finset.filter_image]
  -- We have: (C.image (permuteCodeword π)).filter (fun c => c (π i) = true)
  --        = (C.filter (fun c => permuteCodeword π c (π i) = true)).image (permuteCodeword π)
  -- and the inner filter simplifies via `permuteCodeword_apply`.
  rw [Finset.card_image_of_injective _ (permuteCodeword_injective π)]
  -- Now: (C.filter (fun c => permuteCodeword π c (π i) = true)).card
  --    = (C.filter (fun c => c i = true)).card
  congr 1
  ext c
  simp only [Finset.mem_filter]
  constructor
  · rintro ⟨hc, h⟩
    refine ⟨hc, ?_⟩
    rw [permuteCodeword_apply] at h
    -- h : c (π⁻¹ (π i)) = true.  But π⁻¹ (π i) = i.
    have : π⁻¹ (π i) = i := π.symm_apply_apply i
    rw [this] at h; exact h
  · rintro ⟨hc, h⟩
    refine ⟨hc, ?_⟩
    rw [permuteCodeword_apply]
    have : π⁻¹ (π i) = i := π.symm_apply_apply i
    rw [this]; exact h

end PetrankRoth
end Orbcrypt
