/-
Bit-layout primitives for the Petrank–Roth (1997) GI ≤ CE Karp reduction.

Layer 0 (Sub-tasks 0.1 through 0.4) — foundational helpers that the
encoder, forward direction, and reverse direction all consume. No
Orbcrypt imports — this file depends only on Mathlib's `Fin`, `Nat`,
`Equiv`, `Fintype`, and `Sum` APIs.

See `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` for
the workstream plan and design discussion.
-/

import Mathlib.Data.Fin.Basic
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Sum
import Mathlib.Logic.Equiv.Basic

/-!
# Petrank–Roth bit-layout primitives (Layer 0)

This module fixes the coordinate layout for the Petrank–Roth (1997)
encoder.  The encoded code lives in `(Fin (dimPR m) → Bool)` where
`dimPR m = m + 4 * numEdges m + 1`:

* `m` vertex columns (one per vertex);
* `numEdges m = m * (m - 1)` incidence columns (one per **directed**
  edge slot — ordered pairs `(u, v)` with `u ≠ v`);
* `3 * numEdges m` marker columns (three per edge slot — these are
  the "marker" columns of the Petrank–Roth construction that force
  the reverse direction);
* one **sentinel** column, used to keep `codeSizePR_pos` true when
  `m ≤ 1` (so the strengthened `GIReducesToCE` Prop's
  `codeSize_pos` field is dischargeable on every `m`).

The four families of columns are enumerated by `PRCoordKind`.
Directed edge slots are packaged as `EdgeSlot m := Fin m × Fin (m -
1)` with `otherVertex` / `otherVertexInverse` providing the
skip-the-source bijection between `Fin (m - 1)` and the `m - 1`
target vertices distinct from the source.

## Main definitions

* `numEdges m : ℕ` — `m * (m - 1)`, the count of directed edge
  slots on `m` vertices.
* `dimPR m : ℕ` — total block length of the encoded code.
* `codeSizePR m : ℕ` — total codeword count.
* `PRCoordKind m` — the four-constructor inductive enumerating the
  column families, with `DecidableEq` and `Fintype` instances.
* `EdgeSlot m`, `otherVertex`, `otherVertexInverse` — directed-edge
  slot packaging and the skip-the-source bijection.
* `edgeEndpoints m e`, `edgeIndex m u v h` — the bijection between
  `Fin (numEdges m)` and ordered pairs `(u, v)` with `u ≠ v`.
* `prCoord m`, `prCoordKind m`, `prCoordEquiv m` — the bijection
  `PRCoordKind m ≃ Fin (dimPR m)`.

## Naming

Identifiers in this file describe *content* (column families,
dimensions, coordinate bijections), not the surrounding workstream
or research-scope identifier.  See `CLAUDE.md`'s naming rule.
-/

namespace Orbcrypt
namespace PetrankRoth

universe u

-- ============================================================================
-- Sub-task 0.1 — Dimension and edge-count primitives.
-- ============================================================================

/-- Number of **directed** edge slots on `m` vertices: ordered pairs
`(u, v)` with `u ≠ v`, count `m * (m - 1)`.

Using directed edge slots (rather than unordered pairs `m * (m - 1) /
2`) lets the encoder distinguish `adj p.1 p.2` from `adj p.2 p.1`,
which is necessary for the Karp-reduction iff to hold over arbitrary
adjacency matrices in `GIReducesToCE`.  Symmetric (undirected)
adjacencies are a special case where this distinction collapses. -/
def numEdges (m : ℕ) : ℕ := m * (m - 1)

/-- Block length of the Petrank–Roth encoded code on `m`-vertex graphs:
`m` vertex columns + `4 * numEdges m` incidence + marker columns +
one sentinel column. -/
def dimPR (m : ℕ) : ℕ := m + 4 * numEdges m + 1

/-- Codeword count of the Petrank–Roth encoded code on `m`-vertex
graphs.  Coincides with `dimPR m` (the encoder is "square": one
codeword per coordinate family member). -/
def codeSizePR (m : ℕ) : ℕ := m + 4 * numEdges m + 1

@[simp] theorem numEdges_zero : numEdges 0 = 0 := rfl
@[simp] theorem numEdges_one : numEdges 1 = 0 := rfl
@[simp] theorem numEdges_two : numEdges 2 = 2 := rfl
@[simp] theorem numEdges_three : numEdges 3 = 6 := rfl
@[simp] theorem numEdges_four : numEdges 4 = 12 := rfl

/-- `numEdges m ≤ m * m`: the directed-edge count is bounded by the
ordered-pair count (excludes self-loops). -/
theorem numEdges_le (m : ℕ) : numEdges m ≤ m * m := by
  unfold numEdges
  exact Nat.mul_le_mul_left m (Nat.sub_le m 1)

/-- `dimPR m` is always positive (the sentinel column gives `≥ 1`). -/
theorem dimPR_pos (m : ℕ) : 0 < dimPR m := by
  unfold dimPR; omega

/-- `codeSizePR m` is always positive — discharges the strengthened
`GIReducesToCE` Prop's `codeSize_pos` field at every `m`. -/
theorem codeSizePR_pos (m : ℕ) : 0 < codeSizePR m := by
  unfold codeSizePR; omega

/-- `dimPR m` and `codeSizePR m` coincide by construction. -/
theorem dimPR_eq_codeSizePR (m : ℕ) : dimPR m = codeSizePR m := rfl

-- ============================================================================
-- Sub-task 0.2 — `PRCoordKind` inductive + DecidableEq + Fintype.
-- ============================================================================

/-- Coordinate-kind taxonomy for the Petrank–Roth block layout.

Each `Fin (dimPR m)` index falls into exactly one of four families:

* `vertex v` — vertex column for vertex `v : Fin m`.
* `incid e` — incidence column for unordered edge slot
  `e : Fin (numEdges m)`.
* `marker e k` — marker column at position `k : Fin 3` within edge
  slot `e`'s 3-marker block.
* `sentinel` — the dimension-keeping column used to maintain
  `codeSizePR_pos` at small `m`.
-/
inductive PRCoordKind (m : ℕ) where
  | vertex (v : Fin m)
  | incid (e : Fin (numEdges m))
  | marker (e : Fin (numEdges m)) (k : Fin 3)
  | sentinel
  deriving DecidableEq

namespace PRCoordKind

/-- Convert a `PRCoordKind m` to the disjoint sum
`Fin m ⊕ Fin (numEdges m) ⊕ (Fin (numEdges m) × Fin 3) ⊕ Unit`,
used to derive a `Fintype` instance. -/
def toSum (m : ℕ) : PRCoordKind m →
    Fin m ⊕ Fin (numEdges m) ⊕ (Fin (numEdges m) × Fin 3) ⊕ Unit
  | .vertex v => .inl v
  | .incid e => .inr (.inl e)
  | .marker e k => .inr (.inr (.inl (e, k)))
  | .sentinel => .inr (.inr (.inr ()))

/-- Inverse of `toSum`. -/
def ofSum (m : ℕ) :
    Fin m ⊕ Fin (numEdges m) ⊕ (Fin (numEdges m) × Fin 3) ⊕ Unit →
    PRCoordKind m
  | .inl v => .vertex v
  | .inr (.inl e) => .incid e
  | .inr (.inr (.inl (e, k))) => .marker e k
  | .inr (.inr (.inr ())) => .sentinel

theorem ofSum_toSum (m : ℕ) (k : PRCoordKind m) :
    ofSum m (toSum m k) = k := by
  cases k <;> rfl

theorem toSum_ofSum (m : ℕ)
    (s : Fin m ⊕ Fin (numEdges m) ⊕ (Fin (numEdges m) × Fin 3) ⊕ Unit) :
    toSum m (ofSum m s) = s := by
  rcases s with v | s
  · rfl
  rcases s with e | s
  · rfl
  rcases s with ek | u
  · rcases ek with ⟨e, k⟩; rfl
  · rcases u with ⟨⟩; rfl

/-- `PRCoordKind m ≃ Fin m ⊕ Fin (numEdges m) ⊕ (Fin (numEdges m) × Fin 3) ⊕ Unit`. -/
def equivSum (m : ℕ) :
    PRCoordKind m ≃
      Fin m ⊕ Fin (numEdges m) ⊕ (Fin (numEdges m) × Fin 3) ⊕ Unit where
  toFun := toSum m
  invFun := ofSum m
  left_inv := ofSum_toSum m
  right_inv := toSum_ofSum m

instance instFintype (m : ℕ) : Fintype (PRCoordKind m) :=
  Fintype.ofEquiv _ (equivSum m).symm

end PRCoordKind

-- ============================================================================
-- Sub-task 0.3 — `edgeEndpoints` enumeration (directed, no canonicalisation).
-- ============================================================================
--
-- Strategy: enumerate the directed pairs `(u, v) : Fin m × Fin m` with
-- `u ≠ v` by packaging them as `Fin m × Fin (m - 1)` — for each source
-- vertex `u : Fin m`, the second component `k : Fin (m - 1)` ranges
-- over the `m - 1` vertices distinct from `u`.  Decoding `k` to a
-- target vertex `v ≠ u` is done by `otherVertex`, which "skips" `u`:
-- if `k.val < u.val` then `v.val = k.val`, else `v.val = k.val + 1`.

/-- The product packaging of directed edge slots: pairs `(u, k)` where
`u : Fin m` is the source vertex and `k : Fin (m - 1)` indexes the
`m - 1` other vertices. -/
abbrev EdgeSlot (m : ℕ) : Type := Fin m × Fin (m - 1)

/-- Decode the second component `k : Fin (m - 1)` of an edge slot
sourced at `u : Fin m` into its target vertex `v : Fin m` with `v ≠ u`.

Implementation: insert `u` into the gap by mapping `k.val` to `k.val`
when `k.val < u.val` and to `k.val + 1` otherwise.  The result is
exactly the `k.val`-th element of `(Fin m).erase u`. -/
def otherVertex (m : ℕ) (u : Fin m) (k : Fin (m - 1)) : Fin m :=
  if h : k.val < u.val then
    ⟨k.val, lt_of_lt_of_le h (Nat.le_of_lt u.isLt)⟩
  else
    ⟨k.val + 1, by
      have hk := k.isLt
      have hu := u.isLt
      omega⟩

theorem otherVertex_ne_self (m : ℕ) (u : Fin m) (k : Fin (m - 1)) :
    otherVertex m u k ≠ u := by
  intro heq
  have h := Fin.val_eq_of_eq heq
  by_cases hlt : k.val < u.val
  · -- otherVertex returns ⟨k.val, _⟩, so .val = k.val < u.val,
    -- but heq says .val = u.val, contradiction.
    have h1 : (otherVertex m u k).val = k.val := by
      unfold otherVertex; rw [dif_pos hlt]
    rw [h1] at h
    exact absurd h (Nat.ne_of_lt hlt)
  · -- otherVertex returns ⟨k.val + 1, _⟩, so .val = k.val + 1.
    -- But heq says .val = u.val and ¬ k.val < u.val (so u.val ≤ k.val),
    -- giving k.val + 1 = u.val ≤ k.val, contradiction.
    have h1 : (otherVertex m u k).val = k.val + 1 := by
      unfold otherVertex; rw [dif_neg hlt]
    rw [h1] at h
    omega

/-- Encoder of the second component `k : Fin (m - 1)` from a target
vertex `v : Fin m` distinct from the source `u : Fin m`. -/
def otherVertexInverse (m : ℕ) (u v : Fin m) (h : v ≠ u) : Fin (m - 1) :=
  if hlt : v.val < u.val then
    ⟨v.val, by have := u.isLt; omega⟩
  else
    ⟨v.val - 1, by
      have hv := v.isLt
      have hne : v.val ≠ u.val := fun heq => h (Fin.ext heq)
      have hge : u.val ≤ v.val := Nat.le_of_not_lt hlt
      have hgt : u.val < v.val := lt_of_le_of_ne hge (Ne.symm hne)
      have : 1 ≤ v.val := lt_of_le_of_lt (Nat.zero_le _) hgt
      omega⟩

theorem otherVertex_otherVertexInverse (m : ℕ) (u v : Fin m) (h : v ≠ u) :
    otherVertex m u (otherVertexInverse m u v h) = v := by
  apply Fin.ext
  by_cases hlt : v.val < u.val
  · -- otherVertexInverse returns ⟨v.val, _⟩, whose .val < u.val,
    -- so otherVertex returns ⟨v.val, _⟩.
    have h1 : (otherVertexInverse m u v h).val = v.val := by
      unfold otherVertexInverse; rw [dif_pos hlt]
    have h2 : (otherVertexInverse m u v h).val < u.val := h1 ▸ hlt
    show (otherVertex m u (otherVertexInverse m u v h)).val = v.val
    unfold otherVertex
    rw [dif_pos h2]
    exact h1
  · -- otherVertexInverse returns ⟨v.val - 1, _⟩, whose .val ≥ u.val
    -- (because u.val < v.val gives u.val ≤ v.val - 1).
    have hne : v.val ≠ u.val := fun heq => h (Fin.ext heq)
    have hge : u.val ≤ v.val := Nat.le_of_not_lt hlt
    have hgt : u.val < v.val := lt_of_le_of_ne hge (Ne.symm hne)
    have h1 : (otherVertexInverse m u v h).val = v.val - 1 := by
      unfold otherVertexInverse; rw [dif_neg hlt]
    have h2 : ¬ (otherVertexInverse m u v h).val < u.val := by rw [h1]; omega
    show (otherVertex m u (otherVertexInverse m u v h)).val = v.val
    unfold otherVertex
    rw [dif_neg h2]
    show (otherVertexInverse m u v h).val + 1 = v.val
    rw [h1]; omega

theorem otherVertexInverse_otherVertex (m : ℕ) (u : Fin m) (k : Fin (m - 1)) :
    otherVertexInverse m u (otherVertex m u k) (otherVertex_ne_self m u k) = k := by
  apply Fin.ext
  by_cases hlt : k.val < u.val
  · -- otherVertex returns ⟨k.val, _⟩, whose .val is < u.val,
    -- so otherVertexInverse returns ⟨k.val, _⟩ in the lt branch.
    have h1 : (otherVertex m u k).val = k.val := by
      unfold otherVertex; rw [dif_pos hlt]
    have h2 : (otherVertex m u k).val < u.val := h1 ▸ hlt
    show (otherVertexInverse m u (otherVertex m u k) _).val = k.val
    unfold otherVertexInverse
    rw [dif_pos h2]
    exact h1
  · -- otherVertex returns ⟨k.val + 1, _⟩, whose .val is ≥ u.val,
    -- so otherVertexInverse goes to the else branch and returns
    -- ⟨(k.val + 1) - 1, _⟩, whose .val = k.val.
    have h1 : (otherVertex m u k).val = k.val + 1 := by
      unfold otherVertex; rw [dif_neg hlt]
    have h2 : ¬ (otherVertex m u k).val < u.val := by rw [h1]; omega
    show (otherVertexInverse m u (otherVertex m u k) _).val = k.val
    unfold otherVertexInverse
    rw [dif_neg h2]
    show (otherVertex m u k).val - 1 = k.val
    rw [h1]; omega

/-- Cardinality identity: `EdgeSlot m = Fin m × Fin (m - 1)` has
cardinality `numEdges m = m * (m - 1)`. -/
theorem edgeSlot_card (m : ℕ) : Fintype.card (EdgeSlot m) = numEdges m := by
  unfold numEdges EdgeSlot
  rw [Fintype.card_prod, Fintype.card_fin, Fintype.card_fin]

/-- Canonical equivalence between `Fin (numEdges m)` and the
directed-edge-pair product type `EdgeSlot m`. -/
noncomputable def edgeSlotEquiv (m : ℕ) : Fin (numEdges m) ≃ EdgeSlot m :=
  (Fintype.equivFinOfCardEq (edgeSlot_card m)).symm

/-- Decode an edge index to its directed endpoint pair `(u, v)` with
`u ≠ v`. -/
noncomputable def edgeEndpoints (m : ℕ) (e : Fin (numEdges m)) :
    Fin m × Fin m :=
  let s := edgeSlotEquiv m e
  (s.1, otherVertex m s.1 s.2)

/-- Endpoints of any edge slot are distinct (no self-loops). -/
theorem edgeEndpoints_ne (m : ℕ) (e : Fin (numEdges m)) :
    (edgeEndpoints m e).2 ≠ (edgeEndpoints m e).1 := by
  unfold edgeEndpoints
  exact otherVertex_ne_self m _ _

/-- Encode a directed pair `(u, v)` with `v ≠ u` as the corresponding
edge index. -/
noncomputable def edgeIndex (m : ℕ) (u v : Fin m) (h : v ≠ u) :
    Fin (numEdges m) :=
  (edgeSlotEquiv m).symm (u, otherVertexInverse m u v h)

theorem edgeEndpoints_edgeIndex (m : ℕ) (u v : Fin m) (h : v ≠ u) :
    edgeEndpoints m (edgeIndex m u v h) = (u, v) := by
  unfold edgeEndpoints edgeIndex
  rw [Equiv.apply_symm_apply]
  exact Prod.ext rfl (otherVertex_otherVertexInverse m u v h)

theorem edgeIndex_edgeEndpoints (m : ℕ) (e : Fin (numEdges m)) :
    edgeIndex m (edgeEndpoints m e).1 (edgeEndpoints m e).2
      (edgeEndpoints_ne m e) = e := by
  apply (edgeSlotEquiv m).injective
  show edgeSlotEquiv m (edgeIndex m (edgeEndpoints m e).1 (edgeEndpoints m e).2
      (edgeEndpoints_ne m e)) = edgeSlotEquiv m e
  -- The endpoints decompose as `(s.1, otherVertex m s.1 s.2)` where
  -- `s := edgeSlotEquiv m e`.
  show edgeSlotEquiv m ((edgeSlotEquiv m).symm
      ((edgeSlotEquiv m e).1,
       otherVertexInverse m (edgeSlotEquiv m e).1
         (otherVertex m (edgeSlotEquiv m e).1 (edgeSlotEquiv m e).2)
         _)) = edgeSlotEquiv m e
  rw [Equiv.apply_symm_apply]
  -- Now goal: ((edgeSlotEquiv m e).1, otherVertexInverse … (otherVertex …) _) = edgeSlotEquiv m e.
  -- Use Prod.ext with the otherVertexInverse_otherVertex round-trip on the second component.
  apply Prod.ext
  · rfl
  · exact otherVertexInverse_otherVertex m _ _

-- ============================================================================
-- Sub-task 0.4 — `prCoord` / `prCoordKind` bijection.
-- ============================================================================

/-- Encode a `PRCoordKind m` value as a `Fin (dimPR m)` index.

Layout: vertices in `[0, m)`, incidences in `[m, m + numEdges m)`,
markers in `[m + numEdges m, m + 4 * numEdges m)` (3 per edge slot,
ordered as `3 * e.val + k.val`), sentinel at `m + 4 * numEdges m`.
-/
def prCoord (m : ℕ) : PRCoordKind m → Fin (dimPR m)
  | .vertex v =>
      ⟨v.val, by
        have := v.isLt
        unfold dimPR
        omega⟩
  | .incid e =>
      ⟨m + e.val, by
        have := e.isLt
        unfold dimPR
        omega⟩
  | .marker e k =>
      ⟨m + numEdges m + 3 * e.val + k.val, by
        have he := e.isLt
        have hk := k.isLt
        have h3 : 3 * e.val + k.val < 3 * numEdges m := by
          have h := Nat.mul_le_mul_left 3 he
          omega
        unfold dimPR
        omega⟩
  | .sentinel =>
      ⟨m + 4 * numEdges m, by
        unfold dimPR
        omega⟩

@[simp] theorem prCoord_vertex_val (m : ℕ) (v : Fin m) :
    (prCoord m (.vertex v)).val = v.val := rfl

@[simp] theorem prCoord_incid_val (m : ℕ) (e : Fin (numEdges m)) :
    (prCoord m (.incid e)).val = m + e.val := rfl

@[simp] theorem prCoord_marker_val (m : ℕ)
    (e : Fin (numEdges m)) (k : Fin 3) :
    (prCoord m (.marker e k)).val =
    m + numEdges m + 3 * e.val + k.val := rfl

@[simp] theorem prCoord_sentinel_val (m : ℕ) :
    (prCoord m (PRCoordKind.sentinel : PRCoordKind m)).val =
    m + 4 * numEdges m := rfl

/-- Decode a `Fin (dimPR m)` index into its `PRCoordKind m`.

The function case-splits on which of the four ranges `i.val` falls
into.  In the marker range `[m + numEdges m, m + 4 * numEdges m)`
the offset `r := i.val - (m + numEdges m)` decomposes as
`r = 3 * (r / 3) + r % 3` with `r / 3 < numEdges m` and `r % 3 < 3`.
-/
def prCoordKind (m : ℕ) (i : Fin (dimPR m)) : PRCoordKind m :=
  if hv : i.val < m then
    .vertex ⟨i.val, hv⟩
  else if hi : i.val < m + numEdges m then
    .incid ⟨i.val - m, by omega⟩
  else if hm : i.val < m + 4 * numEdges m then
    .marker
      ⟨(i.val - (m + numEdges m)) / 3, by
        rw [Nat.div_lt_iff_lt_mul (by decide : (0 : ℕ) < 3)]
        omega⟩
      ⟨(i.val - (m + numEdges m)) % 3, Nat.mod_lt _ (by decide)⟩
  else
    .sentinel

theorem prCoord_prCoordKind (m : ℕ) (i : Fin (dimPR m)) :
    prCoord m (prCoordKind m i) = i := by
  apply Fin.ext
  unfold prCoordKind
  split_ifs with hv hi hm
  · -- Vertex case: i.val < m, so prCoordKind = .vertex ⟨i.val, hv⟩.
    simp only [prCoord_vertex_val]
  · -- Incid case: m ≤ i.val < m + numEdges m.
    simp only [prCoord_incid_val]
    omega
  · -- Marker case: m + numEdges m ≤ i.val < m + 4 * numEdges m.
    simp only [prCoord_marker_val]
    -- The remaining identity is
    -- m + numEdges m + 3 * ((i.val - (m + numEdges m)) / 3)
    --   + (i.val - (m + numEdges m)) % 3 = i.val
    have hdm := Nat.div_add_mod (i.val - (m + numEdges m)) 3
    omega
  · -- Sentinel case: ¬ i.val < m + 4 * numEdges m, but i.val < dimPR m.
    simp only [prCoord_sentinel_val]
    have hi_lt := i.isLt
    unfold dimPR at hi_lt
    omega

theorem prCoordKind_prCoord (m : ℕ) (k : PRCoordKind m) :
    prCoordKind m (prCoord m k) = k := by
  cases k with
  | vertex v =>
      have hv : (prCoord m (.vertex v)).val < m := by
        rw [prCoord_vertex_val]; exact v.isLt
      simp only [prCoordKind, dif_pos hv]
      congr 1
  | incid e =>
      have he := e.isLt
      have hv : ¬ (prCoord m (.incid e)).val < m := by
        rw [prCoord_incid_val]; omega
      have hi : (prCoord m (.incid e)).val < m + numEdges m := by
        rw [prCoord_incid_val]; omega
      simp only [prCoordKind, dif_neg hv, dif_pos hi]
      congr 1
      apply Fin.ext
      show (prCoord m (.incid e)).val - m = e.val
      rw [prCoord_incid_val]
      omega
  | marker e k =>
      have he := e.isLt
      have hk := k.isLt
      have h3 : 3 * e.val + k.val < 3 * numEdges m := by
        have h := Nat.mul_le_mul_left 3 he
        omega
      have hv : ¬ (prCoord m (.marker e k)).val < m := by
        rw [prCoord_marker_val]; omega
      have hi : ¬ (prCoord m (.marker e k)).val < m + numEdges m := by
        rw [prCoord_marker_val]; omega
      have hm : (prCoord m (.marker e k)).val < m + 4 * numEdges m := by
        rw [prCoord_marker_val]; omega
      simp only [prCoordKind, dif_neg hv, dif_neg hi, dif_pos hm]
      -- Goal: PRCoordKind.marker ⟨...val.../3, _⟩ ⟨...val...%3, _⟩ = .marker e k.
      -- The `(prCoord m (.marker e k)).val` reduces by simp to
      -- `m + numEdges m + 3*e.val + k.val`, and the offset
      -- subtracts to `3*e.val + k.val`, whose div-3 is `e.val`
      -- and mod-3 is `k.val`.
      have hsub : (prCoord m (.marker e k)).val - (m + numEdges m) =
                  3 * e.val + k.val := by
        rw [prCoord_marker_val]; omega
      have hdiv : (3 * e.val + k.val) / 3 = e.val := by omega
      have hmod : (3 * e.val + k.val) % 3 = k.val := by omega
      congr 1
      · apply Fin.ext
        show ((prCoord m (.marker e k)).val - (m + numEdges m)) / 3 = e.val
        rw [hsub]; exact hdiv
      · apply Fin.ext
        show ((prCoord m (.marker e k)).val - (m + numEdges m)) % 3 = k.val
        rw [hsub]; exact hmod
  | sentinel =>
      have hv : ¬ (prCoord m (PRCoordKind.sentinel : PRCoordKind m)).val < m := by
        rw [prCoord_sentinel_val]; omega
      have hi : ¬ (prCoord m (PRCoordKind.sentinel : PRCoordKind m)).val < m + numEdges m := by
        rw [prCoord_sentinel_val]; omega
      have hm : ¬ (prCoord m (PRCoordKind.sentinel : PRCoordKind m)).val < m + 4 * numEdges m := by
        rw [prCoord_sentinel_val]; omega
      simp only [prCoordKind, dif_neg hv, dif_neg hi, dif_neg hm]

/-- Bijection `PRCoordKind m ≃ Fin (dimPR m)`. -/
def prCoordEquiv (m : ℕ) : PRCoordKind m ≃ Fin (dimPR m) where
  toFun := prCoord m
  invFun := prCoordKind m
  left_inv := prCoordKind_prCoord m
  right_inv := prCoord_prCoordKind m

-- ============================================================================
-- Sub-task 0.5 — Layer 0 non-vacuity sanity checks.
-- ============================================================================
-- These `example` blocks verify (via `rfl` / `decide`) that the
-- bit-layout primitives behave on small concrete `m` exactly as the
-- module's design comments claim.  They serve as compile-time
-- regressions; the Phase 16 consolidated audit script
-- (`scripts/audit_phase_16.lean`) is updated separately to replay
-- the underlying `#print axioms` checks.

-- Edge counts at small `m` (closed-form evaluation, directed pairs):
example : numEdges 3 = 6 := rfl
example : numEdges 4 = 12 := rfl
example : numEdges 5 = 20 := rfl

-- Block-length and codeword-count agreement:
example : dimPR 3 = 28 := rfl                    -- 3 + 4*6 + 1 = 28
example : codeSizePR 3 = 28 := rfl
example : dimPR 0 = 1 := rfl                     -- sentinel-only at m = 0
example : dimPR 1 = 2 := rfl                     -- 1 vertex + sentinel at m = 1

-- `dimPR_pos` / `codeSizePR_pos` discharge the strengthened-Prop
-- non-degeneracy field at every `m`:
example : 0 < codeSizePR 0 := codeSizePR_pos 0
example : 0 < codeSizePR 1 := codeSizePR_pos 1
example : 0 < codeSizePR 100 := codeSizePR_pos 100

-- `PRCoordKind` constructors are pairwise distinct:
example : (PRCoordKind.vertex (m := 3) ⟨0, by decide⟩) ≠
          (PRCoordKind.sentinel) := by decide
example : (PRCoordKind.incid (m := 3) ⟨0, by decide⟩) ≠
          (PRCoordKind.sentinel) := by decide
example : (PRCoordKind.marker (m := 3) ⟨0, by decide⟩ ⟨0, by decide⟩) ≠
          (PRCoordKind.sentinel) := by decide

-- `prCoord` evaluates to the expected raw column index at small `m`
-- (note: `numEdges 3 = 6` with directed slots).
example : (prCoord 3 (.vertex ⟨0, by decide⟩)).val = 0 := rfl
example : (prCoord 3 (.vertex ⟨2, by decide⟩)).val = 2 := rfl
example : (prCoord 3 (.incid ⟨0, by decide⟩)).val = 3 := rfl
example : (prCoord 3 (.incid ⟨5, by decide⟩)).val = 8 := rfl
example : (prCoord 3 (.marker ⟨0, by decide⟩ ⟨0, by decide⟩)).val = 9 := rfl
example : (prCoord 3 (.marker ⟨5, by decide⟩ ⟨2, by decide⟩)).val = 26 := rfl
example : (prCoord 3 (PRCoordKind.sentinel : PRCoordKind 3)).val = 27 := rfl

-- The four families occupy the four expected coordinate ranges,
-- so distinct families produce distinct columns:
example : (prCoord 3 (.vertex ⟨0, by decide⟩)) ≠
          (prCoord 3 (.incid ⟨0, by decide⟩)) := by decide
example : (prCoord 3 (.incid ⟨0, by decide⟩)) ≠
          (prCoord 3 (.marker ⟨0, by decide⟩ ⟨0, by decide⟩)) := by decide
example : (prCoord 3 (.marker ⟨0, by decide⟩ ⟨0, by decide⟩)) ≠
          (prCoord 3 (PRCoordKind.sentinel : PRCoordKind 3)) := by decide

-- `prCoordEquiv` round-trips:
example : prCoordKind 3 (prCoord 3 (PRCoordKind.sentinel : PRCoordKind 3)) =
          PRCoordKind.sentinel := prCoordKind_prCoord 3 _

-- `edgeEndpoints` / `edgeIndex` round-trip on a concrete directed
-- edge.  The explicit edge is `(0, 1)` in `Fin 3` (i.e. the edge from
-- vertex 0 to vertex 1).
example : (edgeEndpoints 3 (edgeIndex 3 ⟨0, by decide⟩ ⟨1, by decide⟩
            (by decide))) = (⟨0, by decide⟩, ⟨1, by decide⟩) :=
  edgeEndpoints_edgeIndex 3 _ _ _

-- `otherVertex` correctness on small examples: skip-the-source layout.
example : otherVertex 3 ⟨0, by decide⟩ ⟨0, by decide⟩ = ⟨1, by decide⟩ := rfl
example : otherVertex 3 ⟨0, by decide⟩ ⟨1, by decide⟩ = ⟨2, by decide⟩ := rfl
example : otherVertex 3 ⟨1, by decide⟩ ⟨0, by decide⟩ = ⟨0, by decide⟩ := rfl
example : otherVertex 3 ⟨1, by decide⟩ ⟨1, by decide⟩ = ⟨2, by decide⟩ := rfl
example : otherVertex 3 ⟨2, by decide⟩ ⟨0, by decide⟩ = ⟨0, by decide⟩ := rfl
example : otherVertex 3 ⟨2, by decide⟩ ⟨1, by decide⟩ = ⟨1, by decide⟩ := rfl

end PetrankRoth
end Orbcrypt
