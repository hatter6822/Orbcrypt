/-
Column-weight invariant infrastructure for the Petrank–Roth (1997)
GI ≤ CE Karp reduction — the "marker-forcing" reverse direction.

Layer 3 (column-weight definition + invariance under `permuteCodeword`)
is implemented here as the foundational infrastructure for Layer 4
(extracting the GI permutation σ from any CE-witness π).

**Status.**  Layer 3 provides the column-weight invariance machinery;
Layer 4 (full marker-forcing endpoint recovery → `prEncode_reverse`
→ headline `petrankRoth_isInhabitedKarpReduction`) is the multi-week
residual work cleanly factored out as research-scope
**R-15-residual-CE-reverse** per the audit-plan Risk Gate
(`docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` § "R-CE
Layer 4 risk register").  Once Layer 4 lands, the iff in
`Orbcrypt.GIReducesToCE` is provable for arbitrary (possibly
asymmetric) `adj` thanks to the post-refactor direction-faithful
encoder (see `PetrankRoth.lean`'s "Encoder design" section).

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

-- ============================================================================
-- Sub-task 3.3 — Column-weight signatures of the four codeword families.
-- ============================================================================
--
-- For the directed-edge encoder, each column kind has a characteristic
-- column-weight signature, computed as the sum of contributions from
-- the four codeword families.  These signatures form the basis for the
-- column-kind discriminator (Sub-task 3.4) used by the marker-forcing
-- reverse direction (Layer 4).

/-- Column weight of `prEncode m adj` at a vertex column.

The vertex column for `v : Fin m` is true in:
* The `vertexCodeword m v` (always, weight 1).
* Each `edgeCodeword m adj e` where `edgePresent m adj e = true` and
  `v ∈ {(edgeEndpoints m e).1, (edgeEndpoints m e).2}`.

Marker codewords and the sentinel codeword are always false at vertex
columns.  The closed-form expression decomposes into the constant
contribution (1, from the vertex codeword) plus the count of
present-edge incidences. -/
theorem colWeight_prEncode_at_vertex (m : ℕ) (adj : Fin m → Fin m → Bool)
    (v : Fin m) :
    colWeight (prEncode m adj) (prCoord m (.vertex v)) =
    1 + ((Finset.univ : Finset (Fin (numEdges m))).filter
          (fun e => edgePresent m adj e ∧
                    (v = (edgeEndpoints m e).1 ∨
                     v = (edgeEndpoints m e).2))).card := by
  classical
  -- Decompose `prEncode m adj` into its four components.
  unfold colWeight prEncode
  -- The four families.
  set V : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (vertexCodeword m) with hV
  set E : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (edgeCodeword m adj) with hE
  set M : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (Function.uncurry (markerCodeword m)) with hM
  set S : Finset (Fin (dimPR m) → Bool) := {sentinelCodeword m} with hS
  -- Filter distributes over union.
  show ((((V ∪ E) ∪ M) ∪ S).filter
        (fun c => c (prCoord m (.vertex v)) = true)).card = _
  rw [Finset.filter_union, Finset.filter_union, Finset.filter_union]
  -- Each family contributes:
  -- V: vertexCodeword v evaluates to true at vertex v's column iff
  --    the codeword's "v" matches our column's "v".  So the filtered
  --    image is {vertexCodeword m v}, with cardinality 1.
  have hVfilter :
      (V.filter (fun c => c (prCoord m (.vertex v)) = true)) =
      ({vertexCodeword m v} : Finset (Fin (dimPR m) → Bool)) := by
    ext c
    rw [hV, Finset.mem_filter, Finset.mem_image, Finset.mem_singleton]
    constructor
    · rintro ⟨⟨v', _, hv'⟩, htrue⟩
      -- c = vertexCodeword m v', and c at vertex column v is true.
      subst hv'
      -- vertexCodeword m v' (prCoord m (.vertex v)) = decide (v = v') = true.
      rw [vertexCodeword_at_vertex] at htrue
      have := of_decide_eq_true htrue
      subst this
      rfl
    · intro h
      subst h
      refine ⟨⟨v, Finset.mem_univ _, rfl⟩, ?_⟩
      rw [vertexCodeword_at_vertex]
      simp
  -- E: edgeCodeword adj e evaluates to true at vertex v's column iff
  --    edgePresent adj e AND v is one of the endpoints of e.
  have hEfilter :
      (E.filter (fun c => c (prCoord m (.vertex v)) = true)).card =
      ((Finset.univ : Finset (Fin (numEdges m))).filter
          (fun e => edgePresent m adj e ∧
                    (v = (edgeEndpoints m e).1 ∨
                     v = (edgeEndpoints m e).2))).card := by
    rw [hE, Finset.filter_image]
    rw [Finset.card_image_of_injective _ (edgeCodeword_injective m adj)]
    congr 1
    ext e
    simp only [Finset.mem_filter, Finset.mem_univ, true_and]
    rw [edgeCodeword_at_vertex]
    -- Goal: (edgePresent && (decide v=p.1 || decide v=p.2)) = true
    --        ↔ edgePresent ∧ (v = p.1 ∨ v = p.2).
    constructor
    · intro h
      cases hp : edgePresent m adj e with
      | true =>
          refine ⟨rfl, ?_⟩
          rw [hp] at h
          simp only [Bool.true_and] at h
          rcases (Bool.or_eq_true _ _).mp h with hl | hr
          · exact Or.inl (of_decide_eq_true hl)
          · exact Or.inr (of_decide_eq_true hr)
      | false =>
          rw [hp] at h
          simp only [Bool.false_and] at h
          exact absurd h (by decide)
    · rintro ⟨hpres, hvp⟩
      rw [hpres]
      simp only [Bool.true_and]
      rcases hvp with hl | hr
      · rw [decide_eq_true hl]; rfl
      · rw [decide_eq_true hr]; simp
  -- M: marker codewords are always false at vertex columns.
  have hMfilter :
      (M.filter (fun c => c (prCoord m (.vertex v)) = true)) = ∅ := by
    rw [hM]
    apply Finset.filter_eq_empty_iff.mpr
    intro c hc
    rw [Finset.mem_image] at hc
    obtain ⟨⟨e, k⟩, _, hek⟩ := hc
    simp only [Function.uncurry] at hek
    subst hek
    rw [markerCodeword_at_vertex]
    decide
  -- S: sentinel codeword is always false at vertex columns.
  have hSfilter :
      (S.filter (fun c => c (prCoord m (.vertex v)) = true)) = ∅ := by
    rw [hS]
    apply Finset.filter_eq_empty_iff.mpr
    intro c hc
    rw [Finset.mem_singleton] at hc
    subst hc
    rw [sentinelCodeword_at_vertex]
    decide
  -- Combine: total count = 1 (V) + (E count) + 0 (M) + 0 (S).
  -- We rewrite the union step by step using disjointness.
  rw [hMfilter, hSfilter, Finset.union_empty, Finset.union_empty]
  -- Goal: ((V filter) ∪ (E filter)).card = 1 + (E count).
  have hVE : Disjoint
      (V.filter (fun c => c (prCoord m (.vertex v)) = true))
      (E.filter (fun c => c (prCoord m (.vertex v)) = true)) := by
    apply Finset.disjoint_filter_filter
    rw [hV, hE, Finset.disjoint_left]
    rintro c hcV hcE
    rw [Finset.mem_image] at hcV hcE
    obtain ⟨v', _, hv'⟩ := hcV
    obtain ⟨e, _, he⟩ := hcE
    exact vertexCodeword_ne_edgeCodeword m adj v' e (hv'.trans he.symm)
  rw [Finset.card_union_of_disjoint hVE, hVfilter, Finset.card_singleton, hEfilter]

/-- Column weight of `prEncode m adj` at an incidence column.

The incidence column for edge slot `e` is true in only one codeword
of `prEncode m adj`: the edge codeword for `e` (regardless of whether
the edge is present or absent — the incidence column is always set).
Vertex, marker, and sentinel codewords are all false at incidence
columns. -/
theorem colWeight_prEncode_at_incid (m : ℕ) (adj : Fin m → Fin m → Bool)
    (e : Fin (numEdges m)) :
    colWeight (prEncode m adj) (prCoord m (.incid e)) = 1 := by
  classical
  unfold colWeight prEncode
  set V : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (vertexCodeword m) with hV
  set E : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (edgeCodeword m adj) with hE
  set M : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (Function.uncurry (markerCodeword m)) with hM
  set S : Finset (Fin (dimPR m) → Bool) := {sentinelCodeword m} with hS
  show ((((V ∪ E) ∪ M) ∪ S).filter
        (fun c => c (prCoord m (.incid e)) = true)).card = _
  rw [Finset.filter_union, Finset.filter_union, Finset.filter_union]
  -- V: vertex codewords are always false at incidence columns.
  have hVfilter :
      (V.filter (fun c => c (prCoord m (.incid e)) = true)) = ∅ := by
    rw [hV]
    apply Finset.filter_eq_empty_iff.mpr
    intro c hc
    rw [Finset.mem_image] at hc
    obtain ⟨v, _, hv⟩ := hc
    subst hv
    rw [vertexCodeword_at_incid]
    decide
  -- E: edge codeword for slot e' is true at incid e iff e' = e.
  -- The image is exactly {edgeCodeword m adj e}.
  have hEfilter :
      (E.filter (fun c => c (prCoord m (.incid e)) = true)) =
      ({edgeCodeword m adj e} : Finset (Fin (dimPR m) → Bool)) := by
    ext c
    rw [hE, Finset.mem_filter, Finset.mem_image, Finset.mem_singleton]
    constructor
    · rintro ⟨⟨e', _, he'⟩, htrue⟩
      subst he'
      rw [edgeCodeword_at_incid] at htrue
      have := of_decide_eq_true htrue
      subst this
      rfl
    · intro h
      subst h
      refine ⟨⟨e, Finset.mem_univ _, rfl⟩, ?_⟩
      rw [edgeCodeword_at_incid]
      simp
  -- M: marker codewords are always false at incidence columns.
  have hMfilter :
      (M.filter (fun c => c (prCoord m (.incid e)) = true)) = ∅ := by
    rw [hM]
    apply Finset.filter_eq_empty_iff.mpr
    intro c hc
    rw [Finset.mem_image] at hc
    obtain ⟨⟨e', k⟩, _, hek⟩ := hc
    simp only [Function.uncurry] at hek
    subst hek
    rw [markerCodeword_at_incid]
    decide
  -- S: sentinel codeword is false at incidence columns.
  have hSfilter :
      (S.filter (fun c => c (prCoord m (.incid e)) = true)) = ∅ := by
    rw [hS]
    apply Finset.filter_eq_empty_iff.mpr
    intro c hc
    rw [Finset.mem_singleton] at hc
    subst hc
    rw [sentinelCodeword_at_incid]
    decide
  rw [hVfilter, hEfilter, hMfilter, hSfilter]
  simp

/-- Column weight of `prEncode m adj` at a marker column.

The marker column for `(e, k)` is true in only one codeword of
`prEncode m adj`: the marker codeword for `(e, k)`.  All other
codewords are false at marker columns. -/
theorem colWeight_prEncode_at_marker (m : ℕ) (adj : Fin m → Fin m → Bool)
    (e : Fin (numEdges m)) (k : Fin 3) :
    colWeight (prEncode m adj) (prCoord m (.marker e k)) = 1 := by
  classical
  unfold colWeight prEncode
  set V : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (vertexCodeword m) with hV
  set E : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (edgeCodeword m adj) with hE
  set M : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (Function.uncurry (markerCodeword m)) with hM
  set S : Finset (Fin (dimPR m) → Bool) := {sentinelCodeword m} with hS
  show ((((V ∪ E) ∪ M) ∪ S).filter
        (fun c => c (prCoord m (.marker e k)) = true)).card = _
  rw [Finset.filter_union, Finset.filter_union, Finset.filter_union]
  have hVfilter :
      (V.filter (fun c => c (prCoord m (.marker e k)) = true)) = ∅ := by
    rw [hV]
    apply Finset.filter_eq_empty_iff.mpr
    intro c hc
    rw [Finset.mem_image] at hc
    obtain ⟨v, _, hv⟩ := hc
    subst hv
    rw [vertexCodeword_at_marker]
    decide
  have hEfilter :
      (E.filter (fun c => c (prCoord m (.marker e k)) = true)) = ∅ := by
    rw [hE]
    apply Finset.filter_eq_empty_iff.mpr
    intro c hc
    rw [Finset.mem_image] at hc
    obtain ⟨e', _, he'⟩ := hc
    subst he'
    rw [edgeCodeword_at_marker]
    decide
  have hMfilter :
      (M.filter (fun c => c (prCoord m (.marker e k)) = true)) =
      ({markerCodeword m e k} : Finset (Fin (dimPR m) → Bool)) := by
    ext c
    rw [hM, Finset.mem_filter, Finset.mem_image, Finset.mem_singleton]
    constructor
    · rintro ⟨⟨⟨e', k'⟩, _, hek'⟩, htrue⟩
      simp only [Function.uncurry] at hek'
      subst hek'
      rw [markerCodeword_at_marker] at htrue
      have h := of_decide_eq_true htrue
      obtain ⟨he, hk⟩ := h
      subst he; subst hk
      rfl
    · intro h
      subst h
      refine ⟨⟨(e, k), Finset.mem_univ _, ?_⟩, ?_⟩
      · simp [Function.uncurry]
      · rw [markerCodeword_at_marker]; simp
  have hSfilter :
      (S.filter (fun c => c (prCoord m (.marker e k)) = true)) = ∅ := by
    rw [hS]
    apply Finset.filter_eq_empty_iff.mpr
    intro c hc
    rw [Finset.mem_singleton] at hc
    subst hc
    rw [sentinelCodeword_at_marker]
    decide
  rw [hVfilter, hEfilter, hMfilter, hSfilter]
  simp

/-- Column weight of `prEncode m adj` at the sentinel column.

The sentinel column is true in only one codeword of `prEncode m adj`:
the sentinel codeword.  All other codewords (vertex, edge, marker)
are false at the sentinel column. -/
theorem colWeight_prEncode_at_sentinel (m : ℕ) (adj : Fin m → Fin m → Bool) :
    colWeight (prEncode m adj)
              (prCoord m (PRCoordKind.sentinel : PRCoordKind m)) = 1 := by
  classical
  unfold colWeight prEncode
  set V : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (vertexCodeword m) with hV
  set E : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (edgeCodeword m adj) with hE
  set M : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (Function.uncurry (markerCodeword m)) with hM
  set S : Finset (Fin (dimPR m) → Bool) := {sentinelCodeword m} with hS
  show ((((V ∪ E) ∪ M) ∪ S).filter
        (fun c => c (prCoord m (PRCoordKind.sentinel : PRCoordKind m)) =
                  true)).card = _
  rw [Finset.filter_union, Finset.filter_union, Finset.filter_union]
  have hVfilter :
      (V.filter (fun c => c (prCoord m (PRCoordKind.sentinel : PRCoordKind m)) =
                          true)) = ∅ := by
    rw [hV]
    apply Finset.filter_eq_empty_iff.mpr
    intro c hc
    rw [Finset.mem_image] at hc
    obtain ⟨v, _, hv⟩ := hc
    subst hv
    rw [vertexCodeword_at_sentinel]
    decide
  have hEfilter :
      (E.filter (fun c => c (prCoord m (PRCoordKind.sentinel : PRCoordKind m)) =
                          true)) = ∅ := by
    rw [hE]
    apply Finset.filter_eq_empty_iff.mpr
    intro c hc
    rw [Finset.mem_image] at hc
    obtain ⟨e, _, he⟩ := hc
    subst he
    rw [edgeCodeword_at_sentinel]
    decide
  have hMfilter :
      (M.filter (fun c => c (prCoord m (PRCoordKind.sentinel : PRCoordKind m)) =
                          true)) = ∅ := by
    rw [hM]
    apply Finset.filter_eq_empty_iff.mpr
    intro c hc
    rw [Finset.mem_image] at hc
    obtain ⟨⟨e, k⟩, _, hek⟩ := hc
    simp only [Function.uncurry] at hek
    subst hek
    rw [markerCodeword_at_sentinel]
    decide
  have hSfilter :
      (S.filter (fun c => c (prCoord m (PRCoordKind.sentinel : PRCoordKind m)) =
                          true)) =
      ({sentinelCodeword m} : Finset (Fin (dimPR m) → Bool)) := by
    rw [hS]
    apply Finset.ext
    intro c
    simp only [Finset.mem_filter, Finset.mem_singleton]
    constructor
    · intro ⟨h1, _⟩; exact h1
    · intro h; subst h
      refine ⟨rfl, ?_⟩
      rw [sentinelCodeword_at_sentinel]
  rw [hVfilter, hEfilter, hMfilter, hSfilter]
  simp

-- ============================================================================
-- Sub-task 4.0 — Cardinality-forced surjectivity bridge.
-- ============================================================================
--
-- `ArePermEquivalent C₁ C₂` provides a one-sided witness: a single
-- permutation `σ` such that `permuteCodeword σ` maps each codeword
-- of `C₁` *into* `C₂`.  Layer 4's marker-forcing argument (and most
-- of the column-weight invariance reasoning) requires the *two-sided*
-- conclusion: every codeword of `C₂` is the image of some codeword
-- of `C₁`.  When `|C₁| = |C₂|` and `permuteCodeword σ` is injective
-- (which it always is, being an `Equiv`-derived map), this two-sided
-- conclusion follows from finite-cardinality arithmetic.

/-- **Cardinality-forced surjectivity bridge.**

If `σ : Equiv.Perm (Fin n)` maps each codeword of `C₁ : Finset (Fin n
→ Bool)` into `C₂ : Finset (Fin n → Bool)`, and the two finsets have
equal cardinality, then every codeword of `C₂` is the `permuteCodeword
σ`-image of some codeword of `C₁`.

This is the structural witness Layer 4's marker-forcing argument
consumes when extracting a vertex permutation from a CE-witness
permutation: `prEncode_card` ensures the underlying finsets have
equal cardinality (`= codeSizePR m`), so any one-sided CE-witness
extends to a two-sided "image equals" statement. -/
theorem surjectivity_of_card_eq {n : ℕ}
    (σ : Equiv.Perm (Fin n))
    (C₁ C₂ : Finset (Fin n → Bool))
    (hσ : ∀ c ∈ C₁, permuteCodeword σ c ∈ C₂)
    (hcard : C₁.card = C₂.card) :
    ∀ c' ∈ C₂, ∃ c ∈ C₁, permuteCodeword σ c = c' := by
  classical
  -- The image `C₁.image (permuteCodeword σ)` is a subset of `C₂` and
  -- has cardinality equal to `C₁.card` (by injectivity of
  -- `permuteCodeword σ`).  Combined with `C₁.card = C₂.card`, we
  -- conclude the image equals `C₂`.
  have himg_sub : C₁.image (permuteCodeword σ) ⊆ C₂ := by
    intro c hc
    rw [Finset.mem_image] at hc
    obtain ⟨c₀, hc₀, hc₀eq⟩ := hc
    rw [← hc₀eq]
    exact hσ _ hc₀
  have himg_card : (C₁.image (permuteCodeword σ)).card = C₁.card :=
    Finset.card_image_of_injective C₁ (permuteCodeword_injective σ)
  have himg_eq : C₁.image (permuteCodeword σ) = C₂ := by
    apply Finset.eq_of_subset_of_card_le himg_sub
    rw [himg_card, hcard]
  intro c' hc'
  rw [← himg_eq, Finset.mem_image] at hc'
  obtain ⟨c, hc, hceq⟩ := hc'
  exact ⟨c, hc, hceq⟩

/-- Specialisation of `surjectivity_of_card_eq` to the Petrank–Roth
encoding.  `prEncode_card` automatically discharges the
equal-cardinality hypothesis, since both `prEncode m adj₁` and
`prEncode m adj₂` have cardinality `codeSizePR m`. -/
theorem prEncode_surjectivity (m : ℕ)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (σ : Equiv.Perm (Fin (dimPR m)))
    (hσ : ∀ c ∈ prEncode m adj₁, permuteCodeword σ c ∈ prEncode m adj₂) :
    ∀ c' ∈ prEncode m adj₂,
      ∃ c ∈ prEncode m adj₁, permuteCodeword σ c = c' := by
  apply surjectivity_of_card_eq σ _ _ hσ
  rw [prEncode_card, prEncode_card]

end PetrankRoth
end Orbcrypt
