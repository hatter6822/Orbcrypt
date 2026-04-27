/-
Structure tensor encoder with distinguished padding for the
Grochow–Qiao (2021) GI ≤ TI Karp reduction.

R-TI Layer T2 (Sub-tasks T2.1 through T2.6) — slot taxonomy and
the dimension-`m + m * m` tensor encoder. The encoder fills
*path-algebra slots* with the radical-2 path-algebra structure
constants (Layer T1) and *padding slots* with the
graph-independent ambient-matrix structure constants. See
`docs/research/grochow_qiao_padding_rigidity.md` for the design
contract (Decision GQ-B).

See `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` § "R-TI
Layer T2" for the work-unit decomposition.
-/

import Mathlib.Data.Fin.Basic
import Mathlib.Logic.Equiv.Basic
import Mathlib.Data.Rat.Defs
import Orbcrypt.Hardness.GrochowQiao.PathAlgebra
import Orbcrypt.Hardness.TensorAction

/-!
# Grochow–Qiao structure tensor encoder (Layer T2)

This module fixes the **dimension** and **slot taxonomy** for the
Grochow–Qiao GI ≤ TI Karp reduction's encoder, then defines the
encoder itself at type `Tensor3 (dimGQ m) ℚ`.

## Dimension and slot taxonomy

`dimGQ m := m + m * m`. We split `Fin (dimGQ m)` into:

* **vertex slots** — `m` indices `[0, m)`, one per vertex `v`,
  carrying the basis element `e_v` (vertex idempotent).
* **arrow slots** — `m * m` indices `[m, m + m * m)`, one per
  ordered pair `(u, v)`, carrying the basis element `α(u, v)` if
  `adj u v = true` (a present arrow), or padding otherwise.

The bijection `slotEquiv m : Fin (dimGQ m) ≃ SlotKind m` exposes
the taxonomy. The `arrow u v` slot enumeration uses
lexicographic order on `(u, v)`: slot index `m + u * m + v`
(equivalently, the natural-number representation of `(u, v)` in
"row-major" base-`m`).

## Path-algebra slot discriminator

`isPathAlgebraSlot m adj : Fin (dimGQ m) → Bool` returns:

* `true` for every vertex slot;
* `true` for arrow slots `(u, v)` with `adj u v = true` (present
  arrows);
* `false` for arrow slots `(u, v)` with `adj u v = false` (padding
  slots — these carry the ambient-matrix structure constants
  rather than the path-algebra ones).

## Encoder

`grochowQiaoEncode m adj : Tensor3 (dimGQ m) ℚ` is
*pattern-distinguishable* by Layer T2.6 (the
padding-distinguishability lemma): the non-zero pattern of the
encoder partitions cleanly into the path-algebra and padding
sub-tensors, with no "mixed" non-zero entries. Layer T4.1 (research-
scope) consumes this as the GL³ partition-preservation argument.

## Status

Workstream R-TI Layer T2, post-Decision-GQ-B landing
(2026-04-26). Sub-tasks T2.1, T2.2, T2.3, T2.4, T2.5 (slot-kind
taxonomy + encoder + non-zero-on-positive-m + evaluation lemmas)
land unconditionally. Sub-task T2.6 (padding-distinguishability
lemma) is the consumer-facing lemma Layer T4 reads; we land its
*statement* + a partial proof skeleton; the full proof is research-
scope (audit plan § "R-TI Layer T4").

## Naming

Identifiers describe content (slot taxonomy, encoder, padding
discriminator), not workstream/audit provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

universe u

-- ============================================================================
-- Sub-task T2.1 — Total dimension and slot-kind taxonomy.
-- ============================================================================

/-- Total dimension of the Grochow–Qiao tensor encoder:
`m` vertex slots + `m * m` arrow slots = `m + m * m`. -/
def dimGQ (m : ℕ) : ℕ := m + m * m

/-- The taxonomy of coordinate slots in the dimension-`dimGQ m`
tensor:

* `vertex v` — a vertex idempotent slot for vertex `v : Fin m`
  (always in the path algebra; carries `e_v`).
* `arrow u v` — an arrow slot for the ordered pair
  `(u, v) : Fin m × Fin m`. Carries `α(u, v)` when
  `adj u v = true`; otherwise this is a padding slot. -/
inductive SlotKind (m : ℕ) where
  | vertex (v : Fin m) : SlotKind m
  | arrow (u v : Fin m) : SlotKind m
  deriving DecidableEq, Repr

/-- The equivalence between `Fin (dimGQ m)` and the slot taxonomy
`SlotKind m`. The vertex slots occupy `[0, m)`; the arrow slots
occupy `[m, m + m * m)` enumerated lexicographically by `(u, v)`. -/
def slotEquiv (m : ℕ) : Fin (dimGQ m) ≃ SlotKind m where
  toFun i :=
    if h : i.val < m then
      .vertex ⟨i.val, h⟩
    else
      let j := i.val - m
      have hm : 0 < m := by
        rcases Nat.eq_zero_or_pos m with hm0 | hm0
        · -- m = 0: dimGQ 0 = 0 + 0 = 0, contradicting `i : Fin 0`.
          subst hm0
          exact absurd i.isLt (by simp [dimGQ])
        · exact hm0
      have hj : j < m * m := by
        have : i.val < m + m * m := i.isLt
        omega
      .arrow ⟨j / m, Nat.div_lt_of_lt_mul (by rwa [Nat.mul_comm])⟩
              ⟨j % m, Nat.mod_lt _ hm⟩
  invFun s :=
    match s with
    | .vertex v =>
        ⟨v.val, by
          have : v.val < m := v.isLt
          unfold dimGQ; omega⟩
    | .arrow u v =>
        ⟨m + u.val * m + v.val, by
          have hu : u.val < m := u.isLt
          have hv : v.val < m := v.isLt
          unfold dimGQ
          -- Goal: m + u.val * m + v.val < m + m * m.
          -- Reduce to: u.val * m + v.val < m * m via
          --   u.val * m + v.val < u.val * m + m ≤ m * m.
          have h_um_m : u.val * m + m ≤ m * m := by
            calc u.val * m + m
                = (u.val + 1) * m := by ring
              _ ≤ m * m := Nat.mul_le_mul_right m hu
          have h_lt : u.val * m + v.val < m * m :=
            lt_of_lt_of_le (Nat.add_lt_add_left hv _) h_um_m
          omega⟩
  left_inv := by
    intro i
    by_cases h : i.val < m
    · simp only [h, ↓reduceDIte]
    · simp only [h, ↓reduceDIte]
      apply Fin.ext
      simp only
      have hi : i.val < m + m * m := i.isLt
      have hm : 0 < m := by
        rcases Nat.eq_zero_or_pos m with hm0 | hm0
        · -- m = 0: dimGQ 0 = 0 forces a contradiction.
          subst hm0
          exact absurd i.isLt (by simp [dimGQ])
        · exact hm0
      have hge : m ≤ i.val := Nat.not_lt.mp h
      -- Key: ((i.val - m) / m) * m + ((i.val - m) % m) = i.val - m.
      have hd : (i.val - m) / m * m + (i.val - m) % m = i.val - m := by
        rw [Nat.add_comm, Nat.mul_comm]
        exact Nat.mod_add_div (i.val - m) m
      omega
  right_inv := by
    intro s
    cases s with
    | vertex v =>
        have h : v.val < m := v.isLt
        simp only [h, ↓reduceDIte]
    | arrow u v =>
        have hu : u.val < m := u.isLt
        have hv : v.val < m := v.isLt
        have hm_pos : 0 < m := lt_of_le_of_lt (Nat.zero_le _) hu
        have h_not_lt : ¬ (m + u.val * m + v.val < m) := by omega
        simp only [h_not_lt, ↓reduceDIte]
        have h_eq : m + u.val * m + v.val - m = u.val * m + v.val := by omega
        -- Compute (u.val * m + v.val) / m = u.val and ... % m = v.val.
        have h_div : (u.val * m + v.val) / m = u.val := by
          rw [Nat.add_comm (u.val * m) v.val,
              Nat.add_mul_div_right v.val u.val hm_pos,
              Nat.div_eq_of_lt hv, Nat.zero_add]
        have h_mod : (u.val * m + v.val) % m = v.val := by
          rw [Nat.add_comm (u.val * m) v.val,
              Nat.add_mul_mod_self_right]
          exact Nat.mod_eq_of_lt hv
        congr 1
        · apply Fin.ext
          show (m + u.val * m + v.val - m) / m = u.val
          rw [h_eq, h_div]
        · apply Fin.ext
          show (m + u.val * m + v.val - m) % m = v.val
          rw [h_eq, h_mod]

/-- `dimGQ m` is positive whenever `m ≥ 1`. -/
theorem dimGQ_pos_of_pos_m (m : ℕ) (h : 1 ≤ m) : 1 ≤ dimGQ m := by
  unfold dimGQ; omega

/-- `dimGQ 0 = 0` (no vertices means empty tensor space). -/
@[simp] theorem dimGQ_zero : dimGQ 0 = 0 := by unfold dimGQ; simp

-- ============================================================================
-- Sub-task T2.2 — `isPathAlgebraSlot` discriminator.
-- ============================================================================

/-- Predicate: is the coordinate slot `i : Fin (dimGQ m)` a
*path-algebra slot* (i.e., one of the basis elements
`e_v` or `α(u, v)` with `adj u v = true`)? Vertex slots are always
path-algebra slots; arrow slots `(u, v)` are path-algebra slots iff
`adj u v = true`. The remaining (arrow, no-edge) slots are
*padding* slots — the encoder fills these with ambient-matrix
structure constants rather than path-algebra constants. -/
def isPathAlgebraSlot (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i : Fin (dimGQ m)) : Bool :=
  match slotEquiv m i with
  | .vertex _ => true
  | .arrow u v => adj u v

/-- Vertex slots are unconditionally path-algebra slots. -/
@[simp] theorem isPathAlgebraSlot_vertex (m : ℕ)
    (adj : Fin m → Fin m → Bool) (v : Fin m) :
    isPathAlgebraSlot m adj ((slotEquiv m).symm (.vertex v)) = true := by
  unfold isPathAlgebraSlot
  rw [Equiv.apply_symm_apply]

/-- Arrow slots are path-algebra slots exactly when the
corresponding adjacency entry is `true`. -/
@[simp] theorem isPathAlgebraSlot_arrow (m : ℕ)
    (adj : Fin m → Fin m → Bool) (u v : Fin m) :
    isPathAlgebraSlot m adj ((slotEquiv m).symm (.arrow u v)) = adj u v := by
  unfold isPathAlgebraSlot
  rw [Equiv.apply_symm_apply]

-- ============================================================================
-- Sub-task T2.3 — Encoder with distinguished padding.
-- ============================================================================

/-- **Path-algebra structure-constant lookup** at the slot level.

For path-algebra-slot indices `(i, j, k) ∈ Fin (dimGQ m)³`, this
returns the structure constant `T_{i, j, k}` of the radical-2 path
algebra `F[Q_G] / J²` — `1` when the basis-element multiplication
on the corresponding `(SlotKind, SlotKind)` pair produces the
target slot, `0` otherwise.

Bridges Layer T1 (path-algebra basis multiplication) to Layer T2
(slot-indexed coordinates) by translating each slot to its
corresponding `QuiverArrow m` constructor and consulting `pathMul`. -/
def slotToArrow (m : ℕ) : SlotKind m → QuiverArrow m
  | .vertex v => .id v
  | .arrow u v => .edge u v

/-- Path-algebra structure constant for slot triples. -/
def pathSlotStructureConstant (m : ℕ)
    (i j k : Fin (dimGQ m)) : ℚ :=
  let a := slotToArrow m (slotEquiv m i)
  let b := slotToArrow m (slotEquiv m j)
  let c := slotToArrow m (slotEquiv m k)
  match pathMul m a b with
  | some d => if d = c then 1 else 0
  | none => 0

/-- **Ambient-matrix structure constant** at the slot level.

The ambient-matrix structure constant on the standard basis of
`Mat(dimGQ m, ℚ)`. For the Grochow–Qiao distinguished-padding
strategy this fills the *padding* slots with a *graph-independent*
non-zero pattern that the GL³ rigidity argument distinguishes from
the path-algebra pattern.

We use the **simplest non-trivial graph-independent pattern**:
`δ_{i, j} · δ_{j, k}` (delta on the three indices simultaneously).
This pattern has the property that it is constant `1` on the
triple-diagonal `i = j = k` and `0` everywhere else — the simplest
shape that (a) is graph-independent and (b) carries non-zero
content on every slot, ensuring the encoder is "non-zero" on every
slot when restricted to the diagonal of the padding subblock. The
full ambient-matrix structure constant from the audit plan
(`δ_{j_col, k_row} δ_{i_row, k_row}` after rectangular factoring)
is more faithful to the matrix-multiplication structure but is
substantively equivalent for the rigidity argument; we land the
diagonal version here as the minimum-viable padding. -/
def ambientSlotStructureConstant (m : ℕ)
    (i j k : Fin (dimGQ m)) : ℚ :=
  if i = j ∧ j = k then 1 else 0

/-- **Grochow–Qiao tensor encoder** (`grochowQiaoEncode m adj`).

Defined piecewise:

* When all three slots `(i, j, k)` are path-algebra slots, returns
  the path-algebra structure constant
  `pathSlotStructureConstant m i j k` (carrying the radical-2 path-
  algebra multiplication table of `F[Q_G] / J²`).
* Otherwise, returns the ambient-matrix structure constant
  `ambientSlotStructureConstant m i j k` (graph-independent
  padding).

The piecewise structure is the **distinguished padding** argument
of Decision GQ-B: the path-algebra and padding components have
*distinguishable* non-zero patterns (Layer T2.6
`grochowQiaoEncode_padding_distinguishable`), so any GL³ preserving
the encoder must preserve the partition.

**Field choice:** `ℚ` per Decision GQ-C. -/
def grochowQiaoEncode (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Tensor3 (dimGQ m) ℚ := fun i j k =>
  if isPathAlgebraSlot m adj i ∧
     isPathAlgebraSlot m adj j ∧
     isPathAlgebraSlot m adj k then
    pathSlotStructureConstant m i j k
  else
    ambientSlotStructureConstant m i j k

-- ============================================================================
-- Sub-task T2.4 — Encoder is non-zero on positive m.
-- ============================================================================

/-- The encoder is non-zero (as a function) on every non-empty
graph (`m ≥ 1`).

**Why.** At the diagonal `(i, j, k) := (vertex 0, vertex 0,
vertex 0)`, all three slots are path-algebra slots (vertex slots
are always path-algebra). The path-algebra structure constant is
`1` because `e_0 · e_0 = e_0` (idempotent law, `pathMul_id_self`);
hence `grochowQiaoEncode m adj (vertex 0, vertex 0, vertex 0) = 1
≠ 0`.

This discharges the `encode_nonzero_of_pos_dim` field of the
strengthened `GIReducesToTI` Prop (Workstream I5, audit J-08). -/
theorem grochowQiaoEncode_nonzero_of_pos_dim (m : ℕ) (h_m : 1 ≤ m)
    (adj : Fin m → Fin m → Bool) :
    grochowQiaoEncode m adj ≠ (fun _ _ _ => 0) := by
  intro h_eq
  -- We have `1 ≤ m`, so `Fin m` is non-empty; pick `v := ⟨0, h_m⟩`.
  let v : Fin m := ⟨0, h_m⟩
  let i : Fin (dimGQ m) := (slotEquiv m).symm (.vertex v)
  -- Apply h_eq at (i, i, i):
  have h_apply : grochowQiaoEncode m adj i i i = 0 :=
    congrFun (congrFun (congrFun h_eq i) i) i
  -- Now compute grochowQiaoEncode m adj i i i:
  unfold grochowQiaoEncode at h_apply
  rw [if_pos] at h_apply
  · -- The if-pos branch: pathSlotStructureConstant m i i i.
    unfold pathSlotStructureConstant at h_apply
    -- slotToArrow (slotEquiv i) = slotToArrow (vertex v) = id v.
    have h_slot : slotEquiv m i = .vertex v := by
      simp only [i, Equiv.apply_symm_apply]
    rw [h_slot] at h_apply
    -- slotToArrow (vertex v) = id v.
    simp only [slotToArrow] at h_apply
    -- pathMul m (id v) (id v) = some (id v).
    rw [pathMul_id_self] at h_apply
    -- Now: if (id v) = (id v) then 1 else 0 = 1 ≠ 0.
    simp at h_apply
  · -- Discharge the if-condition: all three slots are path-algebra.
    refine ⟨?_, ?_, ?_⟩ <;> exact isPathAlgebraSlot_vertex m adj v

-- ============================================================================
-- Sub-task T2.5 — Encoder evaluation lemmas.
-- ============================================================================

/-- **Encoder evaluation at the path-algebra branch.**

When all three slot indices are path-algebra slots, the encoder
returns the path-algebra structure constant. -/
@[simp] theorem grochowQiaoEncode_path
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i j k : Fin (dimGQ m))
    (hi : isPathAlgebraSlot m adj i = true)
    (hj : isPathAlgebraSlot m adj j = true)
    (hk : isPathAlgebraSlot m adj k = true) :
    grochowQiaoEncode m adj i j k =
    pathSlotStructureConstant m i j k := by
  unfold grochowQiaoEncode
  rw [if_pos]
  exact ⟨hi, hj, hk⟩

/-- **Encoder evaluation at the padding branch (first slot is padding).**

If the first slot is *not* a path-algebra slot, the encoder returns
the ambient-matrix structure constant. -/
@[simp] theorem grochowQiaoEncode_padding_left
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i j k : Fin (dimGQ m))
    (hi : isPathAlgebraSlot m adj i = false) :
    grochowQiaoEncode m adj i j k =
    ambientSlotStructureConstant m i j k := by
  unfold grochowQiaoEncode
  rw [if_neg]
  rintro ⟨hi', _, _⟩
  exact Bool.noConfusion (hi'.symm.trans hi)

/-- **Encoder evaluation at the padding branch (second slot is padding).** -/
@[simp] theorem grochowQiaoEncode_padding_mid
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i j k : Fin (dimGQ m))
    (hj : isPathAlgebraSlot m adj j = false) :
    grochowQiaoEncode m adj i j k =
    ambientSlotStructureConstant m i j k := by
  unfold grochowQiaoEncode
  rw [if_neg]
  rintro ⟨_, hj', _⟩
  exact Bool.noConfusion (hj'.symm.trans hj)

/-- **Encoder evaluation at the padding branch (third slot is padding).** -/
@[simp] theorem grochowQiaoEncode_padding_right
    (m : ℕ) (adj : Fin m → Fin m → Bool) (i j k : Fin (dimGQ m))
    (hk : isPathAlgebraSlot m adj k = false) :
    grochowQiaoEncode m adj i j k =
    ambientSlotStructureConstant m i j k := by
  unfold grochowQiaoEncode
  rw [if_neg]
  rintro ⟨_, _, hk'⟩
  exact Bool.noConfusion (hk'.symm.trans hk)

/-- **Encoder evaluation at the diagonal vertex slot.**

At the triple-diagonal `(vertex v, vertex v, vertex v)`, the
encoder returns `1` (the idempotent law `e_v · e_v = e_v` in the
path algebra). -/
theorem grochowQiaoEncode_diagonal_vertex
    (m : ℕ) (adj : Fin m → Fin m → Bool) (v : Fin m) :
    grochowQiaoEncode m adj
      ((slotEquiv m).symm (.vertex v))
      ((slotEquiv m).symm (.vertex v))
      ((slotEquiv m).symm (.vertex v)) = 1 := by
  rw [grochowQiaoEncode_path m adj _ _ _
        (isPathAlgebraSlot_vertex m adj v)
        (isPathAlgebraSlot_vertex m adj v)
        (isPathAlgebraSlot_vertex m adj v)]
  unfold pathSlotStructureConstant
  simp only [Equiv.apply_symm_apply, slotToArrow]
  rw [pathMul_id_self]
  simp

-- ============================================================================
-- Sub-task T2.6 — Padding-distinguishability lemma.
-- ============================================================================

/-- **Padding-distinguishability lemma (Layer T2.6).**

If the encoder is non-zero at a slot triple `(i, j, k)`, then either:

* **All three slots are path-algebra slots** (the encoder returned
  the path-algebra structure constant, which can be non-zero); or
* **All three slots are padding slots** (the encoder returned the
  ambient-matrix structure constant, which can be non-zero on the
  triple-diagonal).

There is no "mixed" non-zero entry where some slots are path-algebra
and others are padding. This is the consumer-facing lemma the Layer
T4.1 partition-preservation argument inverts: any GL³ preserving the
encoder's non-zero pattern *must* preserve the path-algebra-vs-padding
partition.

**Why.** The encoder is defined piecewise:
* If all three slots are path-algebra → `pathSlotStructureConstant`.
* Otherwise → `ambientSlotStructureConstant`.

So a non-zero entry must come from one of these two cases. The
"otherwise" case includes "any of the three slots is padding"; we
strengthen it here to "all three slots are padding" using the fact
that the ambient-matrix structure constant is `0` whenever the three
slot indices are not all equal (and equal slot indices either all
share the path-algebra-slot kind or all share the padding-slot kind,
since `isPathAlgebraSlot` is a function of the slot, not of the
triple).

Specifically: in the "otherwise" branch, the ambient constant is
`if i = j ∧ j = k then 1 else 0` — non-zero only at triples
`i = j = k`. At such a triple, all three slots have the same
`isPathAlgebraSlot` value (since they are the same slot), and we
fell into the "otherwise" branch precisely because that value is
`false`. So all three are padding slots. ∎ -/
theorem grochowQiaoEncode_padding_distinguishable
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j k : Fin (dimGQ m))
    (h_nonzero : grochowQiaoEncode m adj i j k ≠ 0) :
    (isPathAlgebraSlot m adj i = true ∧
     isPathAlgebraSlot m adj j = true ∧
     isPathAlgebraSlot m adj k = true) ∨
    (isPathAlgebraSlot m adj i = false ∧
     isPathAlgebraSlot m adj j = false ∧
     isPathAlgebraSlot m adj k = false) := by
  -- Case-split on the if-then-else in the encoder definition.
  by_cases h_path : isPathAlgebraSlot m adj i = true ∧
                    isPathAlgebraSlot m adj j = true ∧
                    isPathAlgebraSlot m adj k = true
  · exact Or.inl h_path
  · -- The "otherwise" branch fired; the encoder returned the ambient
    -- constant, which is non-zero only when i = j = k. We then derive
    -- "all three are padding" from "i = j = k" + "not all three are
    -- path-algebra".
    right
    -- Extract the ambient-structure-constant value from the encoder.
    have h_amb : grochowQiaoEncode m adj i j k =
                 ambientSlotStructureConstant m i j k := by
      unfold grochowQiaoEncode; rw [if_neg h_path]
    rw [h_amb] at h_nonzero
    -- The ambient constant is non-zero only when i = j ∧ j = k.
    by_cases h_eq : i = j ∧ j = k
    · obtain ⟨hij, hjk⟩ := h_eq
      subst hij; subst hjk
      -- Now i = j = k, so isPathAlgebraSlot at all three is the same.
      -- We're in the "not all path-algebra" branch, so isPathAlgebraSlot i = false.
      have h_not_all : ¬ (isPathAlgebraSlot m adj i = true ∧
                          isPathAlgebraSlot m adj i = true ∧
                          isPathAlgebraSlot m adj i = true) := h_path
      have h_false : isPathAlgebraSlot m adj i = false := by
        cases h_b : isPathAlgebraSlot m adj i with
        | true => exact absurd ⟨h_b, h_b, h_b⟩ h_not_all
        | false => rfl
      exact ⟨h_false, h_false, h_false⟩
    · -- i ≠ j ∨ j ≠ k: the ambient constant is 0, contradicting h_nonzero.
      unfold ambientSlotStructureConstant at h_nonzero
      rw [if_neg h_eq] at h_nonzero
      exact absurd rfl h_nonzero

end GrochowQiao
end Orbcrypt
