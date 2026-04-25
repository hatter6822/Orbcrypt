/-
Petrank–Roth (1997) Karp reduction GI ≤ CE.

Top-level encoder, forward direction (Layer 2), iff assembly (Layer 5),
non-degeneracy bridge (Layer 6), and `GIReducesToCE` inhabitant
(Layer 7).  The reverse direction (Layers 3, 4) lives in
`Orbcrypt/Hardness/PetrankRoth/MarkerForcing.lean`.

See `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` for
the full design and the layer-by-layer landing plan.
-/

import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Data.Finset.Image
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Prod
import Mathlib.GroupTheory.Perm.Basic
import Orbcrypt.Hardness.PetrankRoth.BitLayout
import Orbcrypt.Hardness.CodeEquivalence

/-!
# Petrank–Roth (1997) Karp reduction GI ≤ CE — encoder, forward direction, iff

This module is the top-level home of the Petrank–Roth Karp reduction.
The bit-layout primitives that the encoder consumes live in
`Orbcrypt/Hardness/PetrankRoth/BitLayout.lean` (Layer 0); the
column-weight invariant and marker-forcing reverse direction live in
`Orbcrypt/Hardness/PetrankRoth/MarkerForcing.lean` (Layers 3 and 4).

## Layer organisation

* **Layer 1** — codeword constructors (`vertexCodeword`,
  `edgeCodeword`, `markerCodeword`, `sentinelCodeword`), the encoder
  `prEncode`, evaluation lemmas, and `prEncode_card`.
* **Layer 2** — forward direction: vertex-permutation σ ∈
  `Equiv.Perm (Fin m)` lifts to `Equiv.Perm (Fin (dimPR m))` via
  `liftAut`, and `prEncode_forward` exhibits the lift as a witness of
  `ArePermEquivalent (prEncode m adj₁) (prEncode m adj₂)`.
* **Layer 5** — `prEncode_iff` assembling forward (Layer 2) with the
  reverse direction (Layer 4, `MarkerForcing.lean`).
* **Layer 6** — non-degeneracy bridge (`prEncode_codeSize_pos`,
  `prEncode_card_eq`).
* **Layer 7** — `petrankRoth_isInhabitedKarpReduction` discharging
  the strengthened `GIReducesToCE` Prop.

## Naming

Identifiers describe content (codeword family, encoding cardinality,
forward/reverse direction), not the surrounding workstream / research
identifier.  See `CLAUDE.md`'s naming rule.

## Provenance

Petrank, Erez and Roth, Ron M. (1997).  *Is code equivalence easy to
decide?*  IEEE Transactions on Information Theory 43(5): 1602–1604.
-/

namespace Orbcrypt
namespace PetrankRoth

universe u

-- ============================================================================
-- Sub-task 1.1 — Codeword constructors.
-- ============================================================================

/-- Vertex codeword for vertex `v : Fin m`.  Has `true` at exactly one
column (the vertex-`v` column) and `false` everywhere else.  Weight 1. -/
def vertexCodeword (m : ℕ) (v : Fin m) : Fin (dimPR m) → Bool :=
  fun i => decide (prCoordKind m i = .vertex v)

/-- "Edge present" predicate symmetric in the endpoint ordering.

The Karp reduction's iff statement
`(∃ σ, ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) ↔ ArePermEquivalent (...)`
does not assume `adj` is symmetric.  When σ canonicalises endpoints by
swapping the order, the asymmetric formula `adj p.1 p.2` would change.
We therefore use the **symmetrised** predicate
`adj p.1 p.2 || adj p.2 p.1`, which is invariant under swap of the
endpoint ordering and matches the Karp-reduction semantics for both
directed and undirected graphs.  For symmetric `adj` this coincides
with `adj p.1 p.2`. -/
noncomputable def edgePresent (m : ℕ) (adj : Fin m → Fin m → Bool)
    (e : Fin (numEdges m)) : Bool :=
  let p := edgeEndpoints m e
  adj p.1 p.2 || adj p.2 p.1

/-- Edge codeword for edge slot `e : Fin (numEdges m)` under adjacency
`adj`.  Weight depends on whether `edgePresent m adj e` is true:

* If the edge is present, the codeword has `true` at three columns:
  the two vertex columns `p.1`, `p.2` and the incidence column for
  `e`.  Weight 3.
* Otherwise, the codeword has `true` only at the incidence column
  for `e`.  Weight 1.

The marker columns and the sentinel are always `false` for edge
codewords. -/
noncomputable def edgeCodeword (m : ℕ) (adj : Fin m → Fin m → Bool)
    (e : Fin (numEdges m)) : Fin (dimPR m) → Bool :=
  fun i =>
    match prCoordKind m i with
    | .vertex v =>
        let p := edgeEndpoints m e
        edgePresent m adj e &&
          (decide (v = p.1) || decide (v = p.2))
    | .incid e' => decide (e = e')
    | .marker _ _ => false
    | .sentinel => false

/-- Marker codeword for the `k`-th marker column of edge slot `e`.
Has `true` at exactly one column (the `(e, k)` marker column).
Weight 1. -/
def markerCodeword (m : ℕ) (e : Fin (numEdges m)) (k : Fin 3) :
    Fin (dimPR m) → Bool :=
  fun i => decide (prCoordKind m i = .marker e k)

/-- Sentinel codeword.  Has `true` at exactly the sentinel column.
Weight 1.  This is the "dimension-keeping" codeword that ensures
`codeSizePR m` is always positive (and in particular ≥ 1 at `m = 0`). -/
def sentinelCodeword (m : ℕ) : Fin (dimPR m) → Bool :=
  fun i => decide (prCoordKind m i = .sentinel)

-- ============================================================================
-- Sub-task 1.2 — Codeword evaluation lemmas (`@[simp]` rewrite suite).
-- ============================================================================

-- Vertex codeword evaluations.

@[simp] theorem vertexCodeword_at_vertex (m : ℕ) (v v' : Fin m) :
    vertexCodeword m v (prCoord m (.vertex v')) = decide (v' = v) := by
  unfold vertexCodeword
  rw [prCoordKind_prCoord]
  by_cases h : v' = v
  · subst h; simp
  · have hne : (PRCoordKind.vertex v' : PRCoordKind m) ≠ .vertex v := by
      intro heq
      exact h ((PRCoordKind.vertex.injEq v' v).mp heq)
    simp [h, hne]

@[simp] theorem vertexCodeword_at_incid (m : ℕ) (v : Fin m)
    (e : Fin (numEdges m)) :
    vertexCodeword m v (prCoord m (.incid e)) = false := by
  unfold vertexCodeword; rw [prCoordKind_prCoord]; simp

@[simp] theorem vertexCodeword_at_marker (m : ℕ) (v : Fin m)
    (e : Fin (numEdges m)) (k : Fin 3) :
    vertexCodeword m v (prCoord m (.marker e k)) = false := by
  unfold vertexCodeword; rw [prCoordKind_prCoord]; simp

@[simp] theorem vertexCodeword_at_sentinel (m : ℕ) (v : Fin m) :
    vertexCodeword m v (prCoord m (PRCoordKind.sentinel : PRCoordKind m)) =
    false := by
  unfold vertexCodeword; rw [prCoordKind_prCoord]; simp

-- Edge codeword evaluations.

@[simp] theorem edgeCodeword_at_vertex (m : ℕ) (adj : Fin m → Fin m → Bool)
    (e : Fin (numEdges m)) (v : Fin m) :
    edgeCodeword m adj e (prCoord m (.vertex v)) =
    (edgePresent m adj e &&
      (decide (v = (edgeEndpoints m e).1) ||
       decide (v = (edgeEndpoints m e).2))) := by
  unfold edgeCodeword; rw [prCoordKind_prCoord]

@[simp] theorem edgeCodeword_at_incid (m : ℕ) (adj : Fin m → Fin m → Bool)
    (e e' : Fin (numEdges m)) :
    edgeCodeword m adj e (prCoord m (.incid e')) = decide (e = e') := by
  unfold edgeCodeword; rw [prCoordKind_prCoord]

@[simp] theorem edgeCodeword_at_marker (m : ℕ) (adj : Fin m → Fin m → Bool)
    (e : Fin (numEdges m)) (e' : Fin (numEdges m)) (k : Fin 3) :
    edgeCodeword m adj e (prCoord m (.marker e' k)) = false := by
  unfold edgeCodeword; rw [prCoordKind_prCoord]

@[simp] theorem edgeCodeword_at_sentinel (m : ℕ) (adj : Fin m → Fin m → Bool)
    (e : Fin (numEdges m)) :
    edgeCodeword m adj e (prCoord m (PRCoordKind.sentinel : PRCoordKind m)) =
    false := by
  unfold edgeCodeword; rw [prCoordKind_prCoord]

-- Marker codeword evaluations.

@[simp] theorem markerCodeword_at_vertex (m : ℕ) (e : Fin (numEdges m))
    (k : Fin 3) (v : Fin m) :
    markerCodeword m e k (prCoord m (.vertex v)) = false := by
  unfold markerCodeword; rw [prCoordKind_prCoord]; simp

@[simp] theorem markerCodeword_at_incid (m : ℕ) (e : Fin (numEdges m))
    (k : Fin 3) (e' : Fin (numEdges m)) :
    markerCodeword m e k (prCoord m (.incid e')) = false := by
  unfold markerCodeword; rw [prCoordKind_prCoord]; simp

@[simp] theorem markerCodeword_at_marker (m : ℕ) (e : Fin (numEdges m))
    (k : Fin 3) (e' : Fin (numEdges m)) (k' : Fin 3) :
    markerCodeword m e k (prCoord m (.marker e' k')) =
    decide (e' = e ∧ k' = k) := by
  unfold markerCodeword
  rw [prCoordKind_prCoord]
  by_cases h : e' = e ∧ k' = k
  · obtain ⟨he, hk⟩ := h; subst he; subst hk; simp
  · push Not at h
    by_cases he : e' = e
    · subst he
      have hk : k' ≠ k := h rfl
      simp [hk]
    · have hne : (PRCoordKind.marker e' k' : PRCoordKind m) ≠ .marker e k := by
        intro heq
        exact he ((PRCoordKind.marker.injEq e' k' e k).mp heq).1
      simp [he, hne]

@[simp] theorem markerCodeword_at_sentinel (m : ℕ) (e : Fin (numEdges m))
    (k : Fin 3) :
    markerCodeword m e k (prCoord m (PRCoordKind.sentinel : PRCoordKind m)) =
    false := by
  unfold markerCodeword; rw [prCoordKind_prCoord]; simp

-- Sentinel codeword evaluations.

@[simp] theorem sentinelCodeword_at_vertex (m : ℕ) (v : Fin m) :
    sentinelCodeword m (prCoord m (.vertex v)) = false := by
  unfold sentinelCodeword; rw [prCoordKind_prCoord]; simp

@[simp] theorem sentinelCodeword_at_incid (m : ℕ) (e : Fin (numEdges m)) :
    sentinelCodeword m (prCoord m (.incid e)) = false := by
  unfold sentinelCodeword; rw [prCoordKind_prCoord]; simp

@[simp] theorem sentinelCodeword_at_marker (m : ℕ) (e : Fin (numEdges m))
    (k : Fin 3) :
    sentinelCodeword m (prCoord m (.marker e k)) = false := by
  unfold sentinelCodeword; rw [prCoordKind_prCoord]; simp

@[simp] theorem sentinelCodeword_at_sentinel (m : ℕ) :
    sentinelCodeword m (prCoord m (PRCoordKind.sentinel : PRCoordKind m)) =
    true := by
  unfold sentinelCodeword; rw [prCoordKind_prCoord]; simp

-- ============================================================================
-- Sub-task 1.3 — Within-family injectivity.
-- ============================================================================

theorem vertexCodeword_injective (m : ℕ) :
    Function.Injective (vertexCodeword m) := by
  intro v v' hvv'
  have h := congrArg (fun c => c (prCoord m (.vertex v))) hvv'
  -- `simp` reduces to `True = decide (v = v')` which forces `v = v'`.
  simp [vertexCodeword_at_vertex] at h
  exact h

theorem edgeCodeword_injective (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Function.Injective (edgeCodeword m adj) := by
  intro e e' hee'
  have h := congrArg (fun c => c (prCoord m (.incid e))) hee'
  simp [edgeCodeword_at_incid] at h
  exact h.symm

theorem markerCodeword_injective (m : ℕ) :
    Function.Injective
      (Function.uncurry (markerCodeword m) :
        Fin (numEdges m) × Fin 3 → Fin (dimPR m) → Bool) := by
  rintro ⟨e, k⟩ ⟨e', k'⟩ hek
  have h := congrArg (fun c => c (prCoord m (.marker e k))) hek
  simp [Function.uncurry, markerCodeword_at_marker] at h
  obtain ⟨he, hk⟩ := h
  exact Prod.mk.injEq .. |>.mpr ⟨he, hk⟩

-- ============================================================================
-- Sub-task 1.4 — Cross-family disjointness.
-- ============================================================================

/-- `vertexCodeword v ≠ edgeCodeword adj e`.  Discriminate at the
incidence column for `e`: vertex codeword is `false`, edge codeword
is `true`. -/
theorem vertexCodeword_ne_edgeCodeword (m : ℕ)
    (adj : Fin m → Fin m → Bool) (v : Fin m) (e : Fin (numEdges m)) :
    vertexCodeword m v ≠ edgeCodeword m adj e := by
  intro hcontra
  have h := congrArg (fun c => c (prCoord m (.incid e))) hcontra
  simp at h

theorem vertexCodeword_ne_markerCodeword (m : ℕ) (v : Fin m)
    (e : Fin (numEdges m)) (k : Fin 3) :
    vertexCodeword m v ≠ markerCodeword m e k := by
  intro hcontra
  -- Discriminate at vertex column v: vertex codeword is `true`,
  -- marker codeword is `false`.
  have h := congrArg (fun c => c (prCoord m (.vertex v))) hcontra
  simp at h

theorem vertexCodeword_ne_sentinelCodeword (m : ℕ) (v : Fin m) :
    vertexCodeword m v ≠ sentinelCodeword m := by
  intro hcontra
  have h := congrArg (fun c => c (prCoord m (.vertex v))) hcontra
  simp at h

theorem edgeCodeword_ne_markerCodeword (m : ℕ)
    (adj : Fin m → Fin m → Bool) (e : Fin (numEdges m))
    (e' : Fin (numEdges m)) (k : Fin 3) :
    edgeCodeword m adj e ≠ markerCodeword m e' k := by
  intro hcontra
  -- Discriminate at incid e: edge codeword is `true`, marker is `false`.
  have h := congrArg (fun c => c (prCoord m (.incid e))) hcontra
  simp at h

theorem edgeCodeword_ne_sentinelCodeword (m : ℕ)
    (adj : Fin m → Fin m → Bool) (e : Fin (numEdges m)) :
    edgeCodeword m adj e ≠ sentinelCodeword m := by
  intro hcontra
  have h := congrArg (fun c => c (prCoord m (.incid e))) hcontra
  simp at h

theorem markerCodeword_ne_sentinelCodeword (m : ℕ)
    (e : Fin (numEdges m)) (k : Fin 3) :
    markerCodeword m e k ≠ sentinelCodeword m := by
  intro hcontra
  have h := congrArg (fun c => c (prCoord m (.marker e k))) hcontra
  simp at h

-- ============================================================================
-- Sub-task 1.5 — `prEncode` definition.
-- ============================================================================

/-- The Petrank–Roth encoding of an `m`-vertex graph `adj`.

The image is a `Finset` of codewords in `Fin (dimPR m) → Bool` —
the union of four families:

* `m` vertex codewords (one per vertex);
* `numEdges m` edge codewords (one per unordered edge slot, weight 1
  or 3 depending on whether the edge is present in `adj`);
* `3 * numEdges m` marker codewords (three per edge slot);
* one sentinel codeword.

Total cardinality: `codeSizePR m = m + 4 * numEdges m + 1` (proved as
`prEncode_card`). -/
noncomputable def prEncode (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Finset (Fin (dimPR m) → Bool) :=
  (Finset.univ.image (vertexCodeword m)) ∪
  (Finset.univ.image (edgeCodeword m adj)) ∪
  (Finset.univ.image (Function.uncurry (markerCodeword m))) ∪
  {sentinelCodeword m}

-- ============================================================================
-- Sub-task 1.5b — Membership shape lemmas (used by Layers 2 and 4).
-- ============================================================================

theorem mem_prEncode (m : ℕ) (adj : Fin m → Fin m → Bool)
    (c : Fin (dimPR m) → Bool) :
    c ∈ prEncode m adj ↔
      (∃ v : Fin m, c = vertexCodeword m v) ∨
      (∃ e : Fin (numEdges m), c = edgeCodeword m adj e) ∨
      (∃ e : Fin (numEdges m), ∃ k : Fin 3, c = markerCodeword m e k) ∨
      c = sentinelCodeword m := by
  unfold prEncode
  simp only [Finset.mem_union, Finset.mem_image, Finset.mem_univ,
    true_and, Finset.mem_singleton]
  constructor
  · rintro (((⟨v, hv⟩ | ⟨e, he⟩) | ⟨⟨e, k⟩, hek⟩) | hsent)
    · exact Or.inl ⟨v, hv.symm⟩
    · exact Or.inr (Or.inl ⟨e, he.symm⟩)
    · exact Or.inr (Or.inr (Or.inl ⟨e, k, by simp [Function.uncurry] at hek
                                             exact hek.symm⟩))
    · exact Or.inr (Or.inr (Or.inr hsent))
  · rintro (⟨v, hv⟩ | ⟨e, he⟩ | ⟨e, k, hek⟩ | hsent)
    · exact Or.inl (Or.inl (Or.inl ⟨v, hv.symm⟩))
    · exact Or.inl (Or.inl (Or.inr ⟨e, he.symm⟩))
    · refine Or.inl (Or.inr ⟨(e, k), ?_⟩); simp [Function.uncurry, hek]
    · exact Or.inr hsent

-- ============================================================================
-- Sub-task 1.6 — Cardinality.
-- ============================================================================

/-- The four image-of-univ Finsets (one per coordinate kind) plus the
sentinel singleton are pairwise disjoint, the sum of their cardinalities
equals `codeSizePR m`. -/
theorem prEncode_card (m : ℕ) (adj : Fin m → Fin m → Bool) :
    (prEncode m adj).card = codeSizePR m := by
  -- Strategy: write `prEncode m adj = V ∪ E ∪ M ∪ S` with the four
  -- families pairwise disjoint, then `Finset.card_union_of_disjoint`
  -- four times and reduce each `Finset.image` to `Finset.univ`'s
  -- cardinality via the within-family injectivity lemmas (Sub-task 1.3).
  classical
  set V : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (vertexCodeword m) with hV
  set E : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (edgeCodeword m adj) with hE
  set M : Finset (Fin (dimPR m) → Bool) :=
    Finset.univ.image (Function.uncurry (markerCodeword m)) with hM
  set S : Finset (Fin (dimPR m) → Bool) := {sentinelCodeword m} with hS
  -- Cardinalities of the four families.
  have hVcard : V.card = m := by
    rw [hV, Finset.card_image_of_injective _ (vertexCodeword_injective m)]
    simp
  have hEcard : E.card = numEdges m := by
    rw [hE, Finset.card_image_of_injective _ (edgeCodeword_injective m adj)]
    simp
  have hMcard : M.card = 3 * numEdges m := by
    rw [hM, Finset.card_image_of_injective _ (markerCodeword_injective m)]
    simp [Fintype.card_prod, Fintype.card_fin, mul_comm]
  have hScard : S.card = 1 := by rw [hS]; simp
  -- Pairwise disjointness.
  have hVE : Disjoint V E := by
    rw [hV, hE]
    rw [Finset.disjoint_left]
    rintro c hcV hcE
    rw [Finset.mem_image] at hcV hcE
    obtain ⟨v, _, hv⟩ := hcV
    obtain ⟨e, _, he⟩ := hcE
    exact vertexCodeword_ne_edgeCodeword m adj v e (hv.trans he.symm)
  have hVM : Disjoint V M := by
    rw [hV, hM]
    rw [Finset.disjoint_left]
    rintro c hcV hcM
    rw [Finset.mem_image] at hcV hcM
    obtain ⟨v, _, hv⟩ := hcV
    obtain ⟨⟨e, k⟩, _, hek⟩ := hcM
    simp [Function.uncurry] at hek
    exact vertexCodeword_ne_markerCodeword m v e k (hv.trans hek.symm)
  have hVS : Disjoint V S := by
    rw [hV, hS]
    rw [Finset.disjoint_left]
    rintro c hcV hcS
    rw [Finset.mem_image] at hcV
    rw [Finset.mem_singleton] at hcS
    obtain ⟨v, _, hv⟩ := hcV
    exact vertexCodeword_ne_sentinelCodeword m v (hv.trans hcS)
  have hEM : Disjoint E M := by
    rw [hE, hM]
    rw [Finset.disjoint_left]
    rintro c hcE hcM
    rw [Finset.mem_image] at hcE hcM
    obtain ⟨e, _, he⟩ := hcE
    obtain ⟨⟨e', k⟩, _, hek⟩ := hcM
    simp [Function.uncurry] at hek
    exact edgeCodeword_ne_markerCodeword m adj e e' k (he.trans hek.symm)
  have hES : Disjoint E S := by
    rw [hE, hS]
    rw [Finset.disjoint_left]
    rintro c hcE hcS
    rw [Finset.mem_image] at hcE
    rw [Finset.mem_singleton] at hcS
    obtain ⟨e, _, he⟩ := hcE
    exact edgeCodeword_ne_sentinelCodeword m adj e (he.trans hcS)
  have hMS : Disjoint M S := by
    rw [hM, hS]
    rw [Finset.disjoint_left]
    rintro c hcM hcS
    rw [Finset.mem_image] at hcM
    rw [Finset.mem_singleton] at hcS
    obtain ⟨⟨e, k⟩, _, hek⟩ := hcM
    simp [Function.uncurry] at hek
    exact markerCodeword_ne_sentinelCodeword m e k (hek.trans hcS)
  -- Disjointness of three-way unions: V ∪ E disjoint from M.
  have hVEM : Disjoint (V ∪ E) M := Finset.disjoint_union_left.mpr ⟨hVM, hEM⟩
  -- and V ∪ E ∪ M disjoint from S.
  have hVEMS : Disjoint (V ∪ E ∪ M) S :=
    Finset.disjoint_union_left.mpr ⟨Finset.disjoint_union_left.mpr ⟨hVS, hES⟩, hMS⟩
  -- Card of the four-way union.
  have hUnion : prEncode m adj = V ∪ E ∪ M ∪ S := rfl
  rw [hUnion]
  rw [Finset.card_union_of_disjoint hVEMS,
      Finset.card_union_of_disjoint hVEM,
      Finset.card_union_of_disjoint hVE,
      hVcard, hEcard, hMcard, hScard]
  unfold codeSizePR; ring

-- ============================================================================
-- Sub-task 2.1 — Vertex-permutation-induced edge permutation.
-- ============================================================================

/-- The raw underlying function `Fin (numEdges m) → Fin (numEdges m)` of
the edge permutation induced by a vertex permutation `σ`.

For each edge `e` with endpoints `(u, w) := edgeEndpoints m e` (with
`u.val < w.val`), apply σ to both: `(σ u, σ w)`.  Canonicalise (swap
if needed) to enforce `(.).1.val < (.).2.val`, then read back via
`edgeIndex`. -/
noncomputable def liftedEdgePermFun (m : ℕ) (σ : Equiv.Perm (Fin m))
    (e : Fin (numEdges m)) : Fin (numEdges m) :=
  let p := edgeEndpoints m e
  if h : (σ p.1).val < (σ p.2).val then
    edgeIndex m (σ p.1) (σ p.2) h
  else
    edgeIndex m (σ p.2) (σ p.1) (by
      have hne : (σ p.1 : Fin m) ≠ σ p.2 := σ.injective.ne
        (Fin.ne_of_lt (edgeEndpoints_lt m e))
      have hne_val : (σ p.1).val ≠ (σ p.2).val :=
        fun heq => hne (Fin.ext heq)
      omega)

/-- Bool-equality on disjunctions: `(decide p || decide q) = decide (p ∨ q)`. -/
private theorem decide_or_to_bool (p q : Prop) [Decidable p] [Decidable q] :
    (decide p || decide q) = decide (p ∨ q) := by
  cases hp : decide p
  · cases hq : decide q
    · simp only [Bool.or_self]
      have hp' : ¬ p := of_decide_eq_false hp
      have hq' : ¬ q := of_decide_eq_false hq
      exact (decide_eq_false (fun h => h.elim hp' hq')).symm
    · simp only [Bool.false_or]
      have hq' : q := of_decide_eq_true hq
      exact (decide_eq_true (Or.inr hq')).symm
  · simp only [Bool.true_or]
    have hp' : p := of_decide_eq_true hp
    exact (decide_eq_true (Or.inl hp')).symm

/-- Bool equality of disjunctions follows from iff-equality of the disjuncts. -/
private theorem decide_or_iff_bool (p q r s : Prop)
    [Decidable p] [Decidable q] [Decidable r] [Decidable s]
    (h : p ∨ q ↔ r ∨ s) :
    (decide p || decide q) = (decide r || decide s) := by
  rw [decide_or_to_bool, decide_or_to_bool]
  exact decide_eq_decide.mpr h

/-- Proof irrelevance for `edgeIndex`: if the endpoints agree, the
proof argument is irrelevant. -/
private theorem edgeIndex_congr (m : ℕ) (u v u' v' : Fin m)
    (heu : u = u') (hev : v = v')
    (h : u.val < v.val) (h' : u'.val < v'.val) :
    edgeIndex m u v h = edgeIndex m u' v' h' := by
  subst heu; subst hev; rfl

/-- Endpoints of `liftedEdgePermFun σ e` in the
"σ-preserves-ordering" branch. -/
private theorem liftedEdgePermFun_endpoints_pos (m : ℕ)
    (σ : Equiv.Perm (Fin m)) (e : Fin (numEdges m))
    (h : (σ (edgeEndpoints m e).1).val < (σ (edgeEndpoints m e).2).val) :
    edgeEndpoints m (liftedEdgePermFun m σ e) =
      (σ (edgeEndpoints m e).1, σ (edgeEndpoints m e).2) := by
  show edgeEndpoints m (liftedEdgePermFun m σ e) = _
  have heq : liftedEdgePermFun m σ e =
      edgeIndex m (σ (edgeEndpoints m e).1) (σ (edgeEndpoints m e).2) h := by
    show (let p := edgeEndpoints m e
          if h' : (σ p.1).val < (σ p.2).val then
            edgeIndex m (σ p.1) (σ p.2) h'
          else _) = _
    simp only [dif_pos h]
  rw [heq]
  exact edgeEndpoints_edgeIndex m _ _ h

/-- Endpoints of `liftedEdgePermFun σ e` in the
"σ-reverses-ordering" branch. -/
private theorem liftedEdgePermFun_endpoints_neg (m : ℕ)
    (σ : Equiv.Perm (Fin m)) (e : Fin (numEdges m))
    (h : ¬ (σ (edgeEndpoints m e).1).val < (σ (edgeEndpoints m e).2).val)
    (h' : (σ (edgeEndpoints m e).2).val < (σ (edgeEndpoints m e).1).val) :
    edgeEndpoints m (liftedEdgePermFun m σ e) =
      (σ (edgeEndpoints m e).2, σ (edgeEndpoints m e).1) := by
  show edgeEndpoints m (liftedEdgePermFun m σ e) = _
  have heq : liftedEdgePermFun m σ e =
      edgeIndex m (σ (edgeEndpoints m e).2) (σ (edgeEndpoints m e).1) h' := by
    show (let p := edgeEndpoints m e
          if h'' : (σ p.1).val < (σ p.2).val then _
          else edgeIndex m (σ p.2) (σ p.1) _) = _
    simp only [dif_neg h]
  rw [heq]
  exact edgeEndpoints_edgeIndex m _ _ h'

/-- Helper: `σ⁻¹ (σ x) = x` for `Equiv.Perm`. -/
private theorem perm_inv_apply_self (m : ℕ) (σ : Equiv.Perm (Fin m))
    (x : Fin m) : σ⁻¹ (σ x) = x := σ.symm_apply_apply x

/-- Helper: `σ (σ⁻¹ x) = x` for `Equiv.Perm`. -/
private theorem perm_apply_inv_self (m : ℕ) (σ : Equiv.Perm (Fin m))
    (x : Fin m) : σ (σ⁻¹ x) = x := σ.apply_symm_apply x

/-- Round-trip: `liftedEdgePermFun σ⁻¹` is a left inverse of
`liftedEdgePermFun σ`. -/
theorem liftedEdgePermFun_left_inv (m : ℕ) (σ : Equiv.Perm (Fin m))
    (e : Fin (numEdges m)) :
    liftedEdgePermFun m σ⁻¹ (liftedEdgePermFun m σ e) = e := by
  set p := edgeEndpoints m e with hp_def
  have hp_lt : p.1.val < p.2.val := edgeEndpoints_lt m e
  -- Inequality auxiliaries needed in both branches.
  have hsne : (σ p.1 : Fin m) ≠ σ p.2 :=
    σ.injective.ne (Fin.ne_of_lt hp_lt)
  have hsne_val : (σ p.1).val ≠ (σ p.2).val :=
    fun heq => hsne (Fin.ext heq)
  by_cases hcase : (σ p.1).val < (σ p.2).val
  · -- Case A: σ preserves the ordering.
    have hep : edgeEndpoints m (liftedEdgePermFun m σ e) = (σ p.1, σ p.2) := by
      rw [hp_def] at hcase
      simpa [hp_def] using
        liftedEdgePermFun_endpoints_pos m σ e (by rw [← hp_def] at hcase; exact hcase)
    -- After applying σ⁻¹, the new endpoints are (p.1, p.2) and ordering preserved.
    have h_inv_lt :
        (σ⁻¹ (edgeEndpoints m (liftedEdgePermFun m σ e)).1).val <
        (σ⁻¹ (edgeEndpoints m (liftedEdgePermFun m σ e)).2).val := by
      rw [hep]
      show (σ⁻¹ (σ p.1)).val < (σ⁻¹ (σ p.2)).val
      rw [perm_inv_apply_self, perm_inv_apply_self]
      exact hp_lt
    have h_step :=
      liftedEdgePermFun_endpoints_pos m σ⁻¹ (liftedEdgePermFun m σ e) h_inv_lt
    -- We want: liftedEdgePermFun σ⁻¹ (liftedEdgePermFun σ e) = e.
    -- Apply edgeIndex_edgeEndpoints to e: edgeIndex m p.1 p.2 hp_lt = e.
    -- The lhs evaluates (under positive branch) to
    --   edgeIndex m (σ⁻¹ ((edgeEndpoints m (liftedEdgePermFun m σ e)).1))
    --              (σ⁻¹ ((edgeEndpoints m (liftedEdgePermFun m σ e)).2))
    --              h_inv_lt
    -- = edgeIndex m (σ⁻¹ (σ p.1)) (σ⁻¹ (σ p.2)) ...
    -- = edgeIndex m p.1 p.2 ... = e.
    have hlhs_eq : liftedEdgePermFun m σ⁻¹ (liftedEdgePermFun m σ e) =
        edgeIndex m (σ⁻¹ (edgeEndpoints m (liftedEdgePermFun m σ e)).1)
                    (σ⁻¹ (edgeEndpoints m (liftedEdgePermFun m σ e)).2) h_inv_lt := by
      show (let q := edgeEndpoints m (liftedEdgePermFun m σ e)
            if h' : (σ⁻¹ q.1).val < (σ⁻¹ q.2).val then
              edgeIndex m (σ⁻¹ q.1) (σ⁻¹ q.2) h'
            else _) = _
      simp only [dif_pos h_inv_lt]
    rw [hlhs_eq]
    -- Goal: edgeIndex m (σ⁻¹ q.1) (σ⁻¹ q.2) _ = e.
    -- We have q.1 = σ p.1 and q.2 = σ p.2 (from hep), so σ⁻¹ q.1 = p.1
    -- and σ⁻¹ q.2 = p.2.  Use edgeIndex_congr to align with `edgeIndex_edgeEndpoints`.
    have hq1 : σ⁻¹ (edgeEndpoints m (liftedEdgePermFun m σ e)).1 =
               (edgeEndpoints m e).1 := by
      have : (edgeEndpoints m (liftedEdgePermFun m σ e)).1 = σ p.1 :=
        congrArg Prod.fst hep
      rw [this, perm_inv_apply_self]
    have hq2 : σ⁻¹ (edgeEndpoints m (liftedEdgePermFun m σ e)).2 =
               (edgeEndpoints m e).2 := by
      have : (edgeEndpoints m (liftedEdgePermFun m σ e)).2 = σ p.2 :=
        congrArg Prod.snd hep
      rw [this, perm_inv_apply_self]
    rw [edgeIndex_congr m _ _ (edgeEndpoints m e).1 (edgeEndpoints m e).2
        hq1 hq2 h_inv_lt (edgeEndpoints_lt m e)]
    exact edgeIndex_edgeEndpoints m e
  · -- Case B: σ reverses the ordering.
    have h_swap_lt : (σ p.2).val < (σ p.1).val := by omega
    have hep : edgeEndpoints m (liftedEdgePermFun m σ e) = (σ p.2, σ p.1) :=
      liftedEdgePermFun_endpoints_neg m σ e hcase h_swap_lt
    -- After applying σ⁻¹, ordering reverses again — we go to else branch of σ⁻¹.
    have h_inv_not_lt :
        ¬ (σ⁻¹ (edgeEndpoints m (liftedEdgePermFun m σ e)).1).val <
          (σ⁻¹ (edgeEndpoints m (liftedEdgePermFun m σ e)).2).val := by
      rw [hep]
      show ¬ (σ⁻¹ (σ p.2)).val < (σ⁻¹ (σ p.1)).val
      rw [perm_inv_apply_self, perm_inv_apply_self]
      omega
    have h_inv_swap_lt :
        (σ⁻¹ (edgeEndpoints m (liftedEdgePermFun m σ e)).2).val <
        (σ⁻¹ (edgeEndpoints m (liftedEdgePermFun m σ e)).1).val := by
      rw [hep]
      show (σ⁻¹ (σ p.1)).val < (σ⁻¹ (σ p.2)).val
      rw [perm_inv_apply_self, perm_inv_apply_self]
      exact hp_lt
    have hlhs_eq : liftedEdgePermFun m σ⁻¹ (liftedEdgePermFun m σ e) =
        edgeIndex m (σ⁻¹ (edgeEndpoints m (liftedEdgePermFun m σ e)).2)
                    (σ⁻¹ (edgeEndpoints m (liftedEdgePermFun m σ e)).1)
                    h_inv_swap_lt := by
      show (let q := edgeEndpoints m (liftedEdgePermFun m σ e)
            if h' : (σ⁻¹ q.1).val < (σ⁻¹ q.2).val then _
            else edgeIndex m (σ⁻¹ q.2) (σ⁻¹ q.1) _) = _
      simp only [dif_neg h_inv_not_lt]
    rw [hlhs_eq]
    -- Same strategy: q.1 = σ p.2, q.2 = σ p.1, so σ⁻¹ q.2 = p.1
    -- and σ⁻¹ q.1 = p.2.
    have hq1 : σ⁻¹ (edgeEndpoints m (liftedEdgePermFun m σ e)).2 =
               (edgeEndpoints m e).1 := by
      have : (edgeEndpoints m (liftedEdgePermFun m σ e)).2 = σ p.1 :=
        congrArg Prod.snd hep
      rw [this, perm_inv_apply_self]
    have hq2 : σ⁻¹ (edgeEndpoints m (liftedEdgePermFun m σ e)).1 =
               (edgeEndpoints m e).2 := by
      have : (edgeEndpoints m (liftedEdgePermFun m σ e)).1 = σ p.2 :=
        congrArg Prod.fst hep
      rw [this, perm_inv_apply_self]
    rw [edgeIndex_congr m _ _ (edgeEndpoints m e).1 (edgeEndpoints m e).2
        hq1 hq2 h_inv_swap_lt (edgeEndpoints_lt m e)]
    exact edgeIndex_edgeEndpoints m e

/-- `liftedEdgePerm σ` is the `Equiv.Perm (Fin (numEdges m))` induced
by `σ : Equiv.Perm (Fin m)`.  Defined via `Equiv.ofBijective` from
`liftedEdgePermFun`'s round-trip identity. -/
noncomputable def liftedEdgePerm (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    Equiv.Perm (Fin (numEdges m)) where
  toFun := liftedEdgePermFun m σ
  invFun := liftedEdgePermFun m σ⁻¹
  left_inv := liftedEdgePermFun_left_inv m σ
  right_inv := by
    intro e
    -- Reuse left_inv at σ⁻¹: liftedEdgePermFun σ (liftedEdgePermFun σ⁻¹ e) = e.
    -- This is liftedEdgePermFun_left_inv applied at σ⁻¹ (since (σ⁻¹)⁻¹ = σ).
    have h := liftedEdgePermFun_left_inv m σ⁻¹ e
    rw [inv_inv] at h
    exact h

@[simp] theorem liftedEdgePerm_apply (m : ℕ) (σ : Equiv.Perm (Fin m))
    (e : Fin (numEdges m)) :
    liftedEdgePerm m σ e = liftedEdgePermFun m σ e := rfl

@[simp] theorem liftedEdgePerm_symm_apply (m : ℕ) (σ : Equiv.Perm (Fin m))
    (e : Fin (numEdges m)) :
    (liftedEdgePerm m σ).symm e = liftedEdgePermFun m σ⁻¹ e := rfl

/-- Endpoints of `liftedEdgePerm σ e` in the σ-order-preserving branch. -/
theorem edgeEndpoints_liftedEdgePerm_pos (m : ℕ) (σ : Equiv.Perm (Fin m))
    (e : Fin (numEdges m))
    (h : (σ (edgeEndpoints m e).1).val < (σ (edgeEndpoints m e).2).val) :
    edgeEndpoints m (liftedEdgePerm m σ e) =
      (σ (edgeEndpoints m e).1, σ (edgeEndpoints m e).2) :=
  liftedEdgePermFun_endpoints_pos m σ e h

/-- Endpoints of `liftedEdgePerm σ e` in the σ-order-reversing branch. -/
theorem edgeEndpoints_liftedEdgePerm_neg (m : ℕ) (σ : Equiv.Perm (Fin m))
    (e : Fin (numEdges m))
    (h : ¬ (σ (edgeEndpoints m e).1).val < (σ (edgeEndpoints m e).2).val)
    (h' : (σ (edgeEndpoints m e).2).val < (σ (edgeEndpoints m e).1).val) :
    edgeEndpoints m (liftedEdgePerm m σ e) =
      (σ (edgeEndpoints m e).2, σ (edgeEndpoints m e).1) :=
  liftedEdgePermFun_endpoints_neg m σ e h h'

/-- The endpoint *set* `{(σ u, σ w)}` equals the endpoint set of
`liftedEdgePerm σ e` (as a 2-element subset of `Fin m`).  This is the
canonicalisation-free characterisation. -/
theorem edgeEndpoints_liftedEdgePerm_set (m : ℕ) (σ : Equiv.Perm (Fin m))
    (e : Fin (numEdges m)) (v : Fin m) :
    (v = (edgeEndpoints m (liftedEdgePerm m σ e)).1 ∨
     v = (edgeEndpoints m (liftedEdgePerm m σ e)).2) ↔
    (v = σ (edgeEndpoints m e).1 ∨ v = σ (edgeEndpoints m e).2) := by
  by_cases hcase : (σ (edgeEndpoints m e).1).val <
      (σ (edgeEndpoints m e).2).val
  · rw [edgeEndpoints_liftedEdgePerm_pos m σ e hcase]
  · have hne : (σ (edgeEndpoints m e).1 : Fin m) ≠ σ (edgeEndpoints m e).2 :=
      σ.injective.ne (Fin.ne_of_lt (edgeEndpoints_lt m e))
    have hne_val : (σ (edgeEndpoints m e).1).val ≠ (σ (edgeEndpoints m e).2).val :=
      fun heq => hne (Fin.ext heq)
    have h_swap_lt : (σ (edgeEndpoints m e).2).val < (σ (edgeEndpoints m e).1).val := by
      omega
    rw [edgeEndpoints_liftedEdgePerm_neg m σ e hcase h_swap_lt]
    tauto

@[simp] theorem liftedEdgePerm_one (m : ℕ) :
    liftedEdgePerm m (1 : Equiv.Perm (Fin m)) = 1 := by
  apply Equiv.ext
  intro e
  show liftedEdgePermFun m 1 e = e
  -- For σ = 1, simp reduces `(1 : Equiv.Perm (Fin m)) x` to `x`,
  -- so the if-branch is the `(p.1.val < p.2.val)` "true" branch and the
  -- result is `edgeIndex m p.1 p.2 (edgeEndpoints_lt m e)`,
  -- which round-trips to e.
  simp only [liftedEdgePermFun, Equiv.Perm.coe_one, id_eq]
  rw [dif_pos (edgeEndpoints_lt m e)]
  exact edgeIndex_edgeEndpoints m e

-- ============================================================================
-- Sub-task 2.3 — `liftAut` construction.
-- ============================================================================

/-- The action of `σ : Equiv.Perm (Fin m)` on `PRCoordKind m`:
* vertex columns are permuted by σ;
* incidence and marker columns are permuted by `liftedEdgePerm σ`
  (markers retain their `Fin 3` slot index);
* the sentinel is fixed.

Acts as an `Equiv.Perm (PRCoordKind m)` via the natural inverse from σ⁻¹. -/
noncomputable def liftAutKindFun (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    PRCoordKind m → PRCoordKind m
  | .vertex v => .vertex (σ v)
  | .incid e => .incid (liftedEdgePerm m σ e)
  | .marker e k => .marker (liftedEdgePerm m σ e) k
  | .sentinel => .sentinel

@[simp] theorem liftAutKindFun_vertex (m : ℕ) (σ : Equiv.Perm (Fin m))
    (v : Fin m) :
    liftAutKindFun m σ (.vertex v) = .vertex (σ v) := rfl

@[simp] theorem liftAutKindFun_incid (m : ℕ) (σ : Equiv.Perm (Fin m))
    (e : Fin (numEdges m)) :
    liftAutKindFun m σ (.incid e) = .incid (liftedEdgePerm m σ e) := rfl

@[simp] theorem liftAutKindFun_marker (m : ℕ) (σ : Equiv.Perm (Fin m))
    (e : Fin (numEdges m)) (k : Fin 3) :
    liftAutKindFun m σ (.marker e k) = .marker (liftedEdgePerm m σ e) k := rfl

@[simp] theorem liftAutKindFun_sentinel (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    liftAutKindFun m σ (PRCoordKind.sentinel : PRCoordKind m) =
    PRCoordKind.sentinel := rfl

theorem liftAutKindFun_left_inv (m : ℕ) (σ : Equiv.Perm (Fin m))
    (κ : PRCoordKind m) :
    liftAutKindFun m σ⁻¹ (liftAutKindFun m σ κ) = κ := by
  cases κ with
  | vertex v =>
      simp only [liftAutKindFun_vertex, perm_inv_apply_self]
  | incid e =>
      simp only [liftAutKindFun_incid]
      congr 1
      exact (liftedEdgePerm m σ).left_inv e
  | marker e k =>
      simp only [liftAutKindFun_marker]
      congr 1
      exact (liftedEdgePerm m σ).left_inv e
  | sentinel => rfl

/-- The action of σ ∈ S_m on `PRCoordKind m` packaged as an Equiv. -/
noncomputable def liftAutKind (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    Equiv.Perm (PRCoordKind m) where
  toFun := liftAutKindFun m σ
  invFun := liftAutKindFun m σ⁻¹
  left_inv := liftAutKindFun_left_inv m σ
  right_inv := by
    intro κ
    have h := liftAutKindFun_left_inv m σ⁻¹ κ
    rw [inv_inv] at h
    exact h

@[simp] theorem liftAutKind_apply (m : ℕ) (σ : Equiv.Perm (Fin m))
    (κ : PRCoordKind m) :
    liftAutKind m σ κ = liftAutKindFun m σ κ := rfl

@[simp] theorem liftAutKind_symm_apply (m : ℕ) (σ : Equiv.Perm (Fin m))
    (κ : PRCoordKind m) :
    (liftAutKind m σ).symm κ = liftAutKindFun m σ⁻¹ κ := rfl

/-- The vertex-permutation lift to `Equiv.Perm (Fin (dimPR m))`.

Defined by conjugation: `liftAut σ = prCoordEquiv ∘ liftAutKind σ ∘
prCoordEquiv⁻¹`.  This is the canonical permutation of column indices
underlying the forward direction of the Petrank–Roth iff. -/
noncomputable def liftAut (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    Equiv.Perm (Fin (dimPR m)) :=
  (prCoordEquiv m).symm.trans ((liftAutKind m σ).trans (prCoordEquiv m))

@[simp] theorem liftAut_apply (m : ℕ) (σ : Equiv.Perm (Fin m))
    (i : Fin (dimPR m)) :
    liftAut m σ i = prCoord m (liftAutKindFun m σ (prCoordKind m i)) := rfl

@[simp] theorem liftAut_symm_apply (m : ℕ) (σ : Equiv.Perm (Fin m))
    (i : Fin (dimPR m)) :
    (liftAut m σ).symm i =
    prCoord m (liftAutKindFun m σ⁻¹ (prCoordKind m i)) := rfl

-- ============================================================================
-- Sub-task 2.4 — `liftAut` group-homomorphism lemmas.
-- ============================================================================

@[simp] theorem liftAutKind_one (m : ℕ) :
    liftAutKind m (1 : Equiv.Perm (Fin m)) = 1 := by
  apply Equiv.ext
  intro κ
  cases κ <;> simp [liftAutKindFun]

@[simp] theorem liftAut_one (m : ℕ) :
    liftAut m (1 : Equiv.Perm (Fin m)) = 1 := by
  apply Equiv.ext
  intro i
  show prCoord m (liftAutKindFun m 1 (prCoordKind m i)) = i
  cases h : prCoordKind m i with
  | vertex v =>
      simp only [liftAutKindFun_vertex, Equiv.Perm.coe_one, id_eq]
      rw [show prCoord m (.vertex v) = i from by
        rw [← h]; exact prCoord_prCoordKind m i]
  | incid e =>
      simp only [liftAutKindFun_incid, liftedEdgePerm_one, Equiv.Perm.coe_one, id_eq]
      rw [show prCoord m (.incid e) = i from by
        rw [← h]; exact prCoord_prCoordKind m i]
  | marker e k =>
      simp only [liftAutKindFun_marker, liftedEdgePerm_one, Equiv.Perm.coe_one, id_eq]
      rw [show prCoord m (.marker e k) = i from by
        rw [← h]; exact prCoord_prCoordKind m i]
  | sentinel =>
      simp only [liftAutKindFun_sentinel]
      rw [show prCoord m (PRCoordKind.sentinel : PRCoordKind m) = i from by
        rw [← h]; exact prCoord_prCoordKind m i]

-- ============================================================================
-- Sub-task 2.5–2.8 — Action of `liftAut σ` on each codeword family.
-- ============================================================================

/-- Helper: `(liftAut σ)⁻¹` applied to coordinate `i` is
`prCoord m (liftAutKindFun σ⁻¹ (prCoordKind m i))`.  The `permuteCodeword
(liftAut σ) c i = c ((liftAut σ)⁻¹ i)` rewrite below uses this. -/
private theorem liftAut_inv_apply (m : ℕ) (σ : Equiv.Perm (Fin m))
    (i : Fin (dimPR m)) :
    (liftAut m σ)⁻¹ i = prCoord m (liftAutKindFun m σ⁻¹ (prCoordKind m i)) := by
  show (liftAut m σ).symm i = _
  rfl

/-- Forward action on vertex codewords:
`permuteCodeword (liftAut σ) (vertexCodeword m v) = vertexCodeword m (σ v)`. -/
theorem permuteCodeword_liftAut_vertexCodeword
    (m : ℕ) (σ : Equiv.Perm (Fin m)) (v : Fin m) :
    permuteCodeword (liftAut m σ) (vertexCodeword m v) =
    vertexCodeword m (σ v) := by
  funext i
  -- LHS: vertexCodeword m v ((liftAut σ)⁻¹ i)
  --    = decide (prCoordKind m ((liftAut σ)⁻¹ i) = .vertex v)
  --    = decide (liftAutKindFun σ⁻¹ (prCoordKind m i) = .vertex v).
  -- RHS: decide (prCoordKind m i = .vertex (σ v)).
  rw [permuteCodeword_apply, liftAut_inv_apply]
  show decide (prCoordKind m (prCoord m (liftAutKindFun m σ⁻¹ (prCoordKind m i)))
              = PRCoordKind.vertex v) =
       decide (prCoordKind m i = PRCoordKind.vertex (σ v))
  rw [prCoordKind_prCoord]
  cases h : prCoordKind m i with
  | vertex v' =>
      -- LHS: decide (.vertex (σ⁻¹ v') = .vertex v) = decide (σ⁻¹ v' = v)
      -- RHS: decide (.vertex v' = .vertex (σ v)) = decide (v' = σ v)
      -- And `σ⁻¹ v' = v ↔ v' = σ v`.
      show decide (PRCoordKind.vertex (σ⁻¹ v') = PRCoordKind.vertex v) =
           decide (PRCoordKind.vertex v' = PRCoordKind.vertex (σ v))
      have hbridge : σ⁻¹ v' = v ↔ v' = σ v := by
        constructor
        · intro heq
          have h_eq := congrArg σ heq
          have h_lhs : σ (σ⁻¹ v') = v' := σ.apply_symm_apply v'
          rw [h_lhs] at h_eq
          exact h_eq
        · intro heq
          subst heq
          exact perm_inv_apply_self m σ v
      by_cases hcase : v' = σ v
      · have h1 : σ⁻¹ v' = v := hbridge.mpr hcase
        rw [decide_eq_true (congrArg PRCoordKind.vertex h1),
            decide_eq_true (congrArg PRCoordKind.vertex hcase)]
      · have h1 : σ⁻¹ v' ≠ v := fun heq => hcase (hbridge.mp heq)
        have hne1 : (PRCoordKind.vertex (σ⁻¹ v') : PRCoordKind m) ≠ .vertex v :=
          fun heq => h1 ((PRCoordKind.vertex.injEq _ _).mp heq)
        have hne2 : (PRCoordKind.vertex v' : PRCoordKind m) ≠ .vertex (σ v) :=
          fun heq => hcase ((PRCoordKind.vertex.injEq _ _).mp heq)
        rw [decide_eq_false hne1, decide_eq_false hne2]
  | incid e =>
      simp only [liftAutKindFun_incid, reduceCtorEq, decide_false]
  | marker e k =>
      simp only [liftAutKindFun_marker, reduceCtorEq, decide_false]
  | sentinel =>
      simp only [liftAutKindFun_sentinel, reduceCtorEq, decide_false]

/-- Forward action on marker codewords:
`permuteCodeword (liftAut σ) (markerCodeword m e k) =
markerCodeword m (liftedEdgePerm σ e) k`. -/
theorem permuteCodeword_liftAut_markerCodeword
    (m : ℕ) (σ : Equiv.Perm (Fin m))
    (e : Fin (numEdges m)) (k : Fin 3) :
    permuteCodeword (liftAut m σ) (markerCodeword m e k) =
    markerCodeword m (liftedEdgePerm m σ e) k := by
  funext i
  rw [permuteCodeword_apply, liftAut_inv_apply]
  show decide (prCoordKind m (prCoord m
              (liftAutKindFun m σ⁻¹ (prCoordKind m i)))
              = PRCoordKind.marker e k) =
       decide (prCoordKind m i =
              PRCoordKind.marker (liftedEdgePerm m σ e) k)
  rw [prCoordKind_prCoord]
  cases h : prCoordKind m i with
  | vertex v =>
      simp only [liftAutKindFun_vertex, reduceCtorEq, decide_false]
  | incid e' =>
      simp only [liftAutKindFun_incid, reduceCtorEq, decide_false]
  | marker e' k' =>
      simp only [liftAutKindFun_marker]
      -- Goal:  decide (.marker (liftedEdgePerm σ⁻¹ e') k' = .marker e k)
      --      = decide (.marker e' k' = .marker (liftedEdgePerm σ e) k).
      -- The marker injectivity gives:
      --   LHS = decide ((liftedEdgePerm σ⁻¹ e' = e) ∧ k' = k)
      --   RHS = decide ((e' = liftedEdgePerm σ e) ∧ k' = k)
      -- And `liftedEdgePerm σ⁻¹ e' = e ↔ e' = liftedEdgePerm σ e`.
      have hbridge : (liftedEdgePerm m σ⁻¹) e' = e ↔
                     e' = liftedEdgePerm m σ e := by
        constructor
        · intro heq
          have h_eq := congrArg (liftedEdgePerm m σ) heq
          have h_lhs : (liftedEdgePerm m σ) ((liftedEdgePerm m σ⁻¹) e') = e' :=
            (liftedEdgePerm m σ).right_inv e'
          rw [h_lhs] at h_eq
          exact h_eq
        · intro heq
          subst heq
          exact (liftedEdgePerm m σ).left_inv e
      have hcomb :
          (PRCoordKind.marker ((liftedEdgePerm m σ⁻¹) e') k' :
             PRCoordKind m) = .marker e k ↔
          (PRCoordKind.marker e' k' : PRCoordKind m) =
            .marker (liftedEdgePerm m σ e) k := by
        rw [PRCoordKind.marker.injEq, PRCoordKind.marker.injEq, hbridge]
      exact decide_eq_decide.mpr hcomb
  | sentinel =>
      simp only [liftAutKindFun_sentinel, reduceCtorEq, decide_false]

/-- Forward action on the sentinel codeword (sentinel is fixed). -/
theorem permuteCodeword_liftAut_sentinelCodeword
    (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    permuteCodeword (liftAut m σ) (sentinelCodeword m) = sentinelCodeword m := by
  funext i
  rw [permuteCodeword_apply, liftAut_inv_apply]
  show decide (prCoordKind m (prCoord m
              (liftAutKindFun m σ⁻¹ (prCoordKind m i)))
              = PRCoordKind.sentinel) =
       decide (prCoordKind m i = PRCoordKind.sentinel)
  rw [prCoordKind_prCoord]
  cases prCoordKind m i with
  | vertex v => simp only [liftAutKindFun_vertex, reduceCtorEq, decide_false]
  | incid e => simp only [liftAutKindFun_incid, reduceCtorEq, decide_false]
  | marker e k => simp only [liftAutKindFun_marker, reduceCtorEq, decide_false]
  | sentinel => simp only [liftAutKindFun_sentinel]

/-- Edge presence is preserved by the lifted permutation: the edge
slot `liftedEdgePerm σ e` of `adj₂` is "present" iff edge slot `e` of
`adj₁` is present, given the GI hypothesis. -/
theorem edgePresent_liftedEdgePerm
    (m : ℕ) (σ : Equiv.Perm (Fin m))
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : ∀ i j, adj₁ i j = adj₂ (σ i) (σ j))
    (e : Fin (numEdges m)) :
    edgePresent m adj₁ e = edgePresent m adj₂ (liftedEdgePerm m σ e) := by
  show (adj₁ (edgeEndpoints m e).1 (edgeEndpoints m e).2 ||
        adj₁ (edgeEndpoints m e).2 (edgeEndpoints m e).1) =
       (adj₂ (edgeEndpoints m (liftedEdgePerm m σ e)).1
             (edgeEndpoints m (liftedEdgePerm m σ e)).2 ||
        adj₂ (edgeEndpoints m (liftedEdgePerm m σ e)).2
             (edgeEndpoints m (liftedEdgePerm m σ e)).1)
  by_cases hcase : (σ (edgeEndpoints m e).1).val <
                   (σ (edgeEndpoints m e).2).val
  · rw [edgeEndpoints_liftedEdgePerm_pos m σ e hcase]
    rw [h (edgeEndpoints m e).1 (edgeEndpoints m e).2,
        h (edgeEndpoints m e).2 (edgeEndpoints m e).1]
  · have hne : (σ (edgeEndpoints m e).1 : Fin m) ≠ σ (edgeEndpoints m e).2 :=
      σ.injective.ne (Fin.ne_of_lt (edgeEndpoints_lt m e))
    have hne_val : (σ (edgeEndpoints m e).1).val ≠
                   (σ (edgeEndpoints m e).2).val :=
      fun heq => hne (Fin.ext heq)
    have h_swap : (σ (edgeEndpoints m e).2).val <
                  (σ (edgeEndpoints m e).1).val := by omega
    rw [edgeEndpoints_liftedEdgePerm_neg m σ e hcase h_swap]
    rw [h (edgeEndpoints m e).1 (edgeEndpoints m e).2,
        h (edgeEndpoints m e).2 (edgeEndpoints m e).1]
    exact Bool.or_comm _ _

/-- Forward action on edge codewords. -/
theorem permuteCodeword_liftAut_edgeCodeword
    (m : ℕ) (σ : Equiv.Perm (Fin m))
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : ∀ i j, adj₁ i j = adj₂ (σ i) (σ j))
    (e : Fin (numEdges m)) :
    permuteCodeword (liftAut m σ) (edgeCodeword m adj₁ e) =
    edgeCodeword m adj₂ (liftedEdgePerm m σ e) := by
  -- Symmetric edge presence: the σ-shift via `edgePresent_liftedEdgePerm`.
  have hep := edgePresent_liftedEdgePerm m σ adj₁ adj₂ h e
  funext i
  rw [permuteCodeword_apply, liftAut_inv_apply]
  show edgeCodeword m adj₁ e
        (prCoord m (liftAutKindFun m σ⁻¹ (prCoordKind m i))) =
       edgeCodeword m adj₂ (liftedEdgePerm m σ e) i
  cases hi : prCoordKind m i with
  | vertex v =>
      simp only [liftAutKindFun_vertex]
      rw [edgeCodeword_at_vertex, edgeCodeword]
      rw [hi]
      -- LHS = edgePresent adj₁ e && (decide (σ⁻¹ v = p.1) || decide (σ⁻¹ v = p.2))
      -- RHS = edgePresent adj₂ (liftedEdgePerm σ e) && (decide (v = q.1) || decide (v = q.2))
      -- where p := edgeEndpoints e and q := edgeEndpoints (liftedEdgePerm σ e).
      -- `edgePresent` is symmetric so the && argument is equal by `hep`.
      -- The membership disjunction equates by `edgeEndpoints_liftedEdgePerm_set`
      -- plus σ-injectivity.
      set p := edgeEndpoints m e with hp_def
      have hep' : edgePresent m adj₁ e =
                  edgePresent m adj₂ (liftedEdgePerm m σ e) := hep
      have hmem :
          (decide (σ⁻¹ v = p.1) || decide (σ⁻¹ v = p.2)) =
          (decide (v = (edgeEndpoints m (liftedEdgePerm m σ e)).1) ||
           decide (v = (edgeEndpoints m (liftedEdgePerm m σ e)).2)) := by
        -- σ⁻¹ v = p.i ↔ v = σ p.i, and the σ-image vertex set agrees
        -- with the endpoint set of (liftedEdgePerm σ e).
        have hb1 : (σ⁻¹ v = p.1) ↔ (v = σ p.1) := by
          constructor
          · intro heq
            have h_eq := congrArg σ heq
            rw [perm_apply_inv_self] at h_eq
            exact h_eq
          · intro heq
            subst heq
            exact perm_inv_apply_self m σ p.1
        have hb2 : (σ⁻¹ v = p.2) ↔ (v = σ p.2) := by
          constructor
          · intro heq
            have h_eq := congrArg σ heq
            rw [perm_apply_inv_self] at h_eq
            exact h_eq
          · intro heq
            subst heq
            exact perm_inv_apply_self m σ p.2
        have hset := edgeEndpoints_liftedEdgePerm_set m σ e v
        -- Combined iff: (σ⁻¹ v = p.1 ∨ σ⁻¹ v = p.2) ↔
        --              (v = (lifted σ e).1 ∨ v = (lifted σ e).2).
        have hcomb :
            (σ⁻¹ v = p.1 ∨ σ⁻¹ v = p.2) ↔
            (v = (edgeEndpoints m (liftedEdgePerm m σ e)).1 ∨
             v = (edgeEndpoints m (liftedEdgePerm m σ e)).2) := by
          rw [hb1, hb2]; exact hset.symm
        exact decide_or_iff_bool _ _ _ _ hcomb
      rw [hep', hmem]
  | incid e' =>
      -- LHS evaluates to `decide (e = liftedEdgePerm σ⁻¹ e')`.
      -- RHS evaluates to `decide (liftedEdgePerm σ e = e')`.
      simp only [liftAutKindFun_incid]
      rw [edgeCodeword_at_incid, edgeCodeword]
      rw [hi]
      have hbridge : (liftedEdgePerm m σ e) = e' ↔
                     e = (liftedEdgePerm m σ⁻¹) e' := by
        constructor
        · intro heq
          have h_eq := congrArg (liftedEdgePerm m σ⁻¹) heq
          have h_lhs : (liftedEdgePerm m σ⁻¹) (liftedEdgePerm m σ e) = e :=
            (liftedEdgePerm m σ).left_inv e
          rw [h_lhs] at h_eq
          exact h_eq
        · intro heq
          rw [heq]
          exact (liftedEdgePerm m σ).right_inv e'
      -- The match RHS reduces to `decide (liftedEdgePerm σ e = e')` by
      -- `rfl` after `rw [hi]`.  Convert to bool equality via the iff.
      show decide (e = liftedEdgePerm m σ⁻¹ e') = decide (liftedEdgePerm m σ e = e')
      exact (decide_eq_decide.mpr hbridge.symm)
  | marker e' k =>
      simp only [liftAutKindFun_marker]
      rw [edgeCodeword_at_marker, edgeCodeword]
      rw [hi]
  | sentinel =>
      simp only [liftAutKindFun_sentinel]
      rw [edgeCodeword_at_sentinel, edgeCodeword]
      rw [hi]

-- ============================================================================
-- Sub-task 2.9 — `prEncode_forward` assembly.
-- ============================================================================

/-- **Forward direction of the Petrank–Roth iff.**

If `σ : Equiv.Perm (Fin m)` is a graph isomorphism witness — i.e.,
`∀ i j, adj₁ i j = adj₂ (σ i) (σ j)` — then the lifted permutation
`liftAut σ : Equiv.Perm (Fin (dimPR m))` witnesses the permutation-
equivalence of the encoded codes. -/
theorem prEncode_forward (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) :
    ArePermEquivalent (prEncode m adj₁) (prEncode m adj₂) := by
  obtain ⟨σ, hσ⟩ := h
  refine ⟨liftAut m σ, ?_⟩
  intro c hc
  rw [mem_prEncode] at hc
  rw [mem_prEncode]
  rcases hc with ⟨v, hv⟩ | ⟨e, he⟩ | ⟨e, k, hek⟩ | hsent
  · -- Vertex codeword.
    subst hv
    rw [permuteCodeword_liftAut_vertexCodeword]
    exact Or.inl ⟨σ v, rfl⟩
  · -- Edge codeword.
    subst he
    rw [permuteCodeword_liftAut_edgeCodeword m σ adj₁ adj₂ hσ]
    exact Or.inr (Or.inl ⟨liftedEdgePerm m σ e, rfl⟩)
  · -- Marker codeword.
    subst hek
    rw [permuteCodeword_liftAut_markerCodeword]
    exact Or.inr (Or.inr (Or.inl ⟨liftedEdgePerm m σ e, k, rfl⟩))
  · -- Sentinel codeword.
    subst hsent
    rw [permuteCodeword_liftAut_sentinelCodeword]
    exact Or.inr (Or.inr (Or.inr rfl))



