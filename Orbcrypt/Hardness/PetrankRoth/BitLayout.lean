/-
Bit-layout primitives for the Petrank–Roth (1997) GI ≤ CE Karp reduction.

Layer 0 (Sub-tasks 0.1 and 0.2) — foundational helpers that the
encoder, forward direction, and reverse direction all consume. No
Orbcrypt imports — this file depends only on Mathlib's `Fin`, `Nat`,
`Equiv`, `Fintype`, and `Sum` APIs.

See `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § O / R-15
for the audit-plan reference.
-/

import Mathlib.Data.Fin.Basic
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Sigma
import Mathlib.Data.Fintype.Sum
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Logic.Equiv.Basic

/-!
# Petrank–Roth bit-layout primitives (Sub-tasks 0.1, 0.2)

This module fixes the coordinate layout for the Petrank–Roth (1997)
encoder.  The encoded code lives in `(Fin (dimPR m) → Bool)` where
`dimPR m = m + 4 * numEdges m + 1`:

* `m` vertex columns (one per vertex);
* `numEdges m = m * (m - 1) / 2` incidence columns (one per
  unordered edge slot);
* `3 * numEdges m` marker columns (three per edge slot — these are
  the "marker" columns of the Petrank–Roth construction that force
  the reverse direction);
* one **sentinel** column, used to keep `codeSizePR_pos` true when
  `m ≤ 1` (so the strengthened `GIReducesToCE` Prop's
  `codeSize_pos` field is dischargeable on every `m`).

The four families of columns are enumerated by `PRCoordKind`.
Sub-tasks 0.3 and 0.4 (edge enumeration, `prCoord`/`prCoordKind`
bijection) land in follow-up commits.

## Main definitions (this commit)

* `numEdges m : ℕ` — `m * (m - 1) / 2`, the count of unordered edge
  slots on `m` vertices.
* `dimPR m : ℕ` — total block length of the encoded code.
* `codeSizePR m : ℕ` — total codeword count.
* `PRCoordKind m` — the four-constructor inductive enumerating the
  column families, with `DecidableEq` and `Fintype` instances.

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

/-- Number of unordered edge slots on `m` vertices, i.e. `C(m, 2)`. -/
def numEdges (m : ℕ) : ℕ := m * (m - 1) / 2

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
@[simp] theorem numEdges_two : numEdges 2 = 1 := rfl
@[simp] theorem numEdges_three : numEdges 3 = 3 := rfl
@[simp] theorem numEdges_four : numEdges 4 = 6 := rfl

/-- `numEdges m ≤ m * m`: the unordered-pair count is bounded by the
ordered-pair count. -/
theorem numEdges_le (m : ℕ) : numEdges m ≤ m * m := by
  unfold numEdges
  calc m * (m - 1) / 2
      ≤ m * (m - 1) := Nat.div_le_self _ _
    _ ≤ m * m := Nat.mul_le_mul_left m (Nat.sub_le m 1)

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
-- Sub-task 0.3 — `edgeEndpoints` enumeration with canonicalisation.
-- ============================================================================
--
-- Strategy: enumerate the unordered pairs `(u, v)` with `u.val < v.val`
-- by walking the Sigma type `Σ v : Fin m, Fin v.val` (each `v : Fin m`
-- contributes `v.val` lower endpoints).  The total cardinality of this
-- Sigma type is `numEdges m`, giving the required `Equiv` directly via
-- `Fintype.equivFinOfCardEq`.

/-- The Sigma packaging of ordered pairs `(u, v) : Fin m × Fin m` with
`u.val < v.val`.  Each `v : Fin m` contributes the `v.val` lower
endpoints `u : Fin v.val`. -/
abbrev EdgeSlot (m : ℕ) : Type := Σ v : Fin m, Fin v.val

namespace EdgeSlot

/-- Decode an `EdgeSlot m` into its ordered pair `(u, v) : Fin m × Fin m`
with `u.val < v.val`. -/
def toPair {m : ℕ} (s : EdgeSlot m) : Fin m × Fin m :=
  (⟨s.snd.val, lt_of_lt_of_le s.snd.isLt (Nat.le_of_lt s.fst.isLt)⟩, s.fst)

theorem toPair_lt {m : ℕ} (s : EdgeSlot m) :
    (toPair s).1.val < (toPair s).2.val := s.snd.isLt

end EdgeSlot

/-- `Σ v : Fin m, v.val` evaluates to `m * (m - 1) / 2 = numEdges m`. -/
theorem sum_fin_val_eq_numEdges (m : ℕ) :
    (∑ v : Fin m, v.val) = numEdges m := by
  rw [Fin.sum_univ_eq_sum_range (fun i => i)]
  exact Finset.sum_range_id m

/-- Cardinality identity: `Σ v : Fin m, Fin v.val` has cardinality
`numEdges m`. -/
theorem edgeSlot_card (m : ℕ) : Fintype.card (EdgeSlot m) = numEdges m := by
  classical
  rw [Fintype.card_sigma]
  simp only [Fintype.card_fin]
  exact sum_fin_val_eq_numEdges m

/-- Canonical equivalence between `Fin (numEdges m)` and the
ordered-edge-pair Sigma type `EdgeSlot m`. -/
noncomputable def edgeSlotEquiv (m : ℕ) : Fin (numEdges m) ≃ EdgeSlot m :=
  (Fintype.equivFinOfCardEq (edgeSlot_card m)).symm

/-- Decode an edge index to its endpoint pair `(u, v)` with
`u.val < v.val`. -/
noncomputable def edgeEndpoints (m : ℕ) (e : Fin (numEdges m)) :
    Fin m × Fin m :=
  EdgeSlot.toPair (edgeSlotEquiv m e)

theorem edgeEndpoints_lt (m : ℕ) (e : Fin (numEdges m)) :
    (edgeEndpoints m e).1.val < (edgeEndpoints m e).2.val :=
  EdgeSlot.toPair_lt _

/-- Encode an ordered pair `(u, v)` with `u.val < v.val` as the
corresponding edge index. -/
noncomputable def edgeIndex (m : ℕ) (u v : Fin m) (h : u.val < v.val) :
    Fin (numEdges m) :=
  (edgeSlotEquiv m).symm ⟨v, ⟨u.val, h⟩⟩

theorem edgeEndpoints_edgeIndex (m : ℕ) (u v : Fin m) (h : u.val < v.val) :
    edgeEndpoints m (edgeIndex m u v h) = (u, v) := by
  unfold edgeEndpoints edgeIndex EdgeSlot.toPair
  rw [Equiv.apply_symm_apply]

theorem edgeIndex_edgeEndpoints (m : ℕ) (e : Fin (numEdges m)) :
    edgeIndex m (edgeEndpoints m e).1 (edgeEndpoints m e).2
      (edgeEndpoints_lt m e) = e := by
  unfold edgeEndpoints edgeIndex EdgeSlot.toPair
  apply (edgeSlotEquiv m).injective
  rw [Equiv.apply_symm_apply]

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

-- Edge counts at small `m` (closed-form evaluation):
example : numEdges 3 = 3 := rfl
example : numEdges 4 = 6 := rfl
example : numEdges 5 = 10 := rfl

-- Block-length and codeword-count agreement:
example : dimPR 3 = 16 := rfl                    -- 3 + 4*3 + 1 = 16
example : codeSizePR 3 = 16 := rfl
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

-- `prCoord` evaluates to the expected raw column index at small `m`:
example : (prCoord 3 (.vertex ⟨0, by decide⟩)).val = 0 := rfl
example : (prCoord 3 (.vertex ⟨2, by decide⟩)).val = 2 := rfl
example : (prCoord 3 (.incid ⟨0, by decide⟩)).val = 3 := rfl
example : (prCoord 3 (.incid ⟨2, by decide⟩)).val = 5 := rfl
example : (prCoord 3 (.marker ⟨0, by decide⟩ ⟨0, by decide⟩)).val = 6 := rfl
example : (prCoord 3 (.marker ⟨2, by decide⟩ ⟨2, by decide⟩)).val = 14 := rfl
example : (prCoord 3 (PRCoordKind.sentinel : PRCoordKind 3)).val = 15 := rfl

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

-- `edgeEndpoints` / `edgeIndex` round-trip on a concrete edge.  The
-- explicit edge is `(0, 1)` in `Fin 3`; the index is exhibited via
-- `edgeIndex 3 0 1 (by decide)`.
example : (edgeEndpoints 3 (edgeIndex 3 ⟨0, by decide⟩ ⟨1, by decide⟩
            (by decide))) = (⟨0, by decide⟩, ⟨1, by decide⟩) :=
  edgeEndpoints_edgeIndex 3 _ _ _

end PetrankRoth
end Orbcrypt
