/-
Per-slot slab evaluation, associativity identity, and path-identity
pairing for the Grochow–Qiao encoder.

R-TI Phase 1 (Encoder structural foundation) — pure structural lemmas
about the encoder `grochowQiaoEncode m adj`, with no GL³-invariance
claims.  These lemmas decompose the encoder's value at every slot
triple `(i, j, k)` into a small finite catalogue of cases, and prove
the associativity identity that the algebra-iso construction (Phase 3)
will consume.

See `docs/planning/R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md` § "Phase 1 —
Encoder structural foundation" for the work-unit decomposition.
-/

import Orbcrypt.Hardness.GrochowQiao.SlotSignature
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Fintype.BigOperators

/-!
# Encoder slab evaluation, associativity identity, path-identity pairing

This module establishes three layers of structural content about the
Grochow–Qiao encoder `grochowQiaoEncode m adj : Tensor3 (dimGQ m) ℚ`,
all proven from the existing `pathMul` table and the Stage 0 +
Layer T2 evaluation lemmas.

## Layer 1.1 — Per-slot slab evaluation

Every non-zero entry of the encoder is captured by one of four
explicit cases:

* **Vertex–vertex–vertex diagonal** (`encoder_at_vertex_vertex_vertex_eq_one`):
  the triple-diagonal at a vertex slot evaluates to `1` (idempotent law).
* **Vertex–arrow–arrow** (`encoder_at_vertex_arrow_arrow_eq_one`):
  with `i = vertex v`, `j = k = arrow v w`, `adj v w = true`, the
  encoder evaluates to `1` (left vertex action on a present arrow).
* **Arrow–vertex–arrow** (`encoder_at_arrow_vertex_arrow_eq_one`):
  with `i = k = arrow u v`, `j = vertex v`, `adj u v = true`, the
  encoder evaluates to `1` (right vertex action on a present arrow).
* **Padding diagonal** (re-export of `grochowQiaoEncode_diagonal_padding`):
  the triple-diagonal at a padding slot evaluates to `2`.

The classification lemma `encoder_zero_at_remaining_path_triples`
exhausts the remaining path-algebra cases as zero.

## Layer 1.2 — Associativity identity

The encoder's structure tensor satisfies the associativity identity
```
∑ a, encode m adj i j a · encode m adj a k l =
  ∑ a, encode m adj j k a · encode m adj i a l
```
when `(i, j, k, l)` are all path-algebra slots.  Both sides expand
via `pathMul` to the chained product
`pathMul (pathMul slot_i slot_j) slot_k = some slot_l`, with the
two bracketings reconciled by `pathMul_assoc`.

## Layer 1.3 — Path-identity pairing

The diagonal trace `∑ j, encode m adj i j j` counts the number of
slots that pair with `slot_i` via the path multiplication.  This is
an algebraic invariant that distinguishes vertex slots from
present-arrow slots without referring to the slot-kind discriminator
directly.

## Status

All three layers are unconditional; every `#print axioms` reports the
standard Lean trio only.

## Naming

Identifiers describe content (slab evaluation, associativity identity,
path pairing), not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt

-- ============================================================================
-- Layer 1.1.0 — Slot-equality unfolding helpers.
--
-- The Phase-1 layer 1.1 evaluation lemmas accept slot indices `i, j,
-- k : Fin (dimGQ m)` together with a hypothesis pinning each index to a
-- specific `SlotKind m` constructor (e.g. `slotEquiv m i = .vertex v`).
-- These small private helpers turn such hypotheses into the
-- definitional-equality form `i = (slotEquiv m).symm (.vertex v)` that
-- the underlying `pathSlotStructureConstant` definition expects.
-- ============================================================================

private theorem index_eq_symm_of_slotEquiv
    {m : ℕ} (i : Fin (dimGQ m)) (s : SlotKind m)
    (h : slotEquiv m i = s) : i = (slotEquiv m).symm s := by
  rw [← h, Equiv.symm_apply_apply]

-- ============================================================================
-- Layer 1.1.1 — Vertex-vertex-vertex diagonal evaluates to 1.
-- ============================================================================

/-- **Layer 1.1.1 — Vertex–vertex–vertex diagonal evaluates to one.**

When all three slot indices are the same vertex slot `vertex v`, the
encoder evaluates to `1`.  This is the **idempotent-law** witness
`e_v · e_v = e_v` lifted into the structure-tensor language:
`pathMul (.id v) (.id v) = some (.id v)`, and the structure-constant
indicator `[pathMul slot_i slot_j = some slot_k]` fires. -/
theorem encoder_at_vertex_vertex_vertex_eq_one
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j k : Fin (dimGQ m)) (v : Fin m)
    (hi : slotEquiv m i = .vertex v)
    (hj : slotEquiv m j = .vertex v)
    (hk : slotEquiv m k = .vertex v) :
    grochowQiaoEncode m adj i j k = 1 := by
  -- Replace `i, j, k` with the canonical `(slotEquiv m).symm (.vertex v)`
  -- form so we can reuse `grochowQiaoEncode_diagonal_vertex`.
  have hi' := index_eq_symm_of_slotEquiv i (.vertex v) hi
  have hj' := index_eq_symm_of_slotEquiv j (.vertex v) hj
  have hk' := index_eq_symm_of_slotEquiv k (.vertex v) hk
  rw [hi', hj', hk']
  exact grochowQiaoEncode_diagonal_vertex m adj v

-- ============================================================================
-- Layer 1.1.2 — Vertex–arrow–arrow evaluates to 1 (left vertex action).
-- ============================================================================

/-- **Layer 1.1.2 — Vertex–arrow–arrow evaluates to one (left action).**

When `i = vertex v`, `j = k = arrow v w`, and the arrow `(v, w)` is
present in the adjacency (`adj v w = true`), the encoder evaluates to
`1`.  This is the **left vertex action on a present arrow** witness
`e_v · α(v, w) = α(v, w)`, encoded as
`pathMul (.id v) (.edge v w) = some (.edge v w)`. -/
theorem encoder_at_vertex_arrow_arrow_eq_one
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j k : Fin (dimGQ m)) (v w : Fin m)
    (hi : slotEquiv m i = .vertex v)
    (hj : slotEquiv m j = .arrow v w)
    (hk : slotEquiv m k = .arrow v w)
    (h_adj : adj v w = true) :
    grochowQiaoEncode m adj i j k = 1 := by
  -- All three slots are path-algebra: vertex slots always are; arrow
  -- slot `(v, w)` is path-algebra iff `adj v w = true`.
  have hi_path : isPathAlgebraSlot m adj i = true := by
    unfold isPathAlgebraSlot; rw [hi]
  have hj_path : isPathAlgebraSlot m adj j = true := by
    unfold isPathAlgebraSlot; rw [hj]; exact h_adj
  have hk_path : isPathAlgebraSlot m adj k = true := by
    unfold isPathAlgebraSlot; rw [hk]; exact h_adj
  -- Take the path-algebra branch.
  rw [grochowQiaoEncode_path m adj i j k hi_path hj_path hk_path]
  -- The structure constant evaluates `pathMul (.id v) (.edge v w)`,
  -- which is `some (.edge v w)`.  The output equals `slotToArrow k =
  -- .edge v w`, so the indicator fires (`1`).
  unfold pathSlotStructureConstant
  rw [hi, hj, hk]
  simp [slotToArrow]

-- ============================================================================
-- Layer 1.1.3 — Arrow–vertex–arrow evaluates to 1 (right vertex action).
-- ============================================================================

/-- **Layer 1.1.3 — Arrow–vertex–arrow evaluates to one (right action).**

When `i = k = arrow u v`, `j = vertex v`, and the arrow `(u, v)` is
present in the adjacency (`adj u v = true`), the encoder evaluates to
`1`.  This is the **right vertex action on a present arrow** witness
`α(u, v) · e_v = α(u, v)`, encoded as
`pathMul (.edge u v) (.id v) = some (.edge u v)`. -/
theorem encoder_at_arrow_vertex_arrow_eq_one
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j k : Fin (dimGQ m)) (u v : Fin m)
    (hi : slotEquiv m i = .arrow u v)
    (hj : slotEquiv m j = .vertex v)
    (hk : slotEquiv m k = .arrow u v)
    (h_adj : adj u v = true) :
    grochowQiaoEncode m adj i j k = 1 := by
  have hi_path : isPathAlgebraSlot m adj i = true := by
    unfold isPathAlgebraSlot; rw [hi]; exact h_adj
  have hj_path : isPathAlgebraSlot m adj j = true := by
    unfold isPathAlgebraSlot; rw [hj]
  have hk_path : isPathAlgebraSlot m adj k = true := by
    unfold isPathAlgebraSlot; rw [hk]; exact h_adj
  rw [grochowQiaoEncode_path m adj i j k hi_path hj_path hk_path]
  unfold pathSlotStructureConstant
  rw [hi, hj, hk]
  simp [slotToArrow]

-- ============================================================================
-- Layer 1.1.4 — Padding diagonal evaluates to 2 (re-export).
--
-- The padding-diagonal value-2 witness already lives in
-- `StructureTensor.lean` as `grochowQiaoEncode_diagonal_padding`; we
-- restate it here in the slot-equality form used by Layer 1.1's catalogue.
-- ============================================================================

/-- **Layer 1.1.4 — Padding diagonal evaluates to two.**

Slot-equality re-statement of `grochowQiaoEncode_diagonal_padding`: at
the triple-diagonal `(i, i, i)` for an arrow slot `(u, v)` with
`adj u v = false` (i.e. a padding slot), the encoder evaluates to `2`. -/
theorem encoder_at_padding_diagonal_eq_two
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i : Fin (dimGQ m)) (u v : Fin m)
    (hi : slotEquiv m i = .arrow u v)
    (h_padding : adj u v = false) :
    grochowQiaoEncode m adj i i i = 2 := by
  have hi' := index_eq_symm_of_slotEquiv i (.arrow u v) hi
  rw [hi']
  exact grochowQiaoEncode_diagonal_padding m adj u v h_padding

-- ============================================================================
-- Layer 1.1.5 — Encoder is zero at non-matching path-algebra triples.
-- ============================================================================

/-- **Layer 1.1.5 — Encoder is zero at non-matching path-algebra triples.**

For any path-algebra triple `(i, j, k)`, the encoder evaluates to zero
*unless* the radical-2 path multiplication of the corresponding slots
`slot_i, slot_j` has output `some slot_k`. Equivalently, the structure
constant `pathSlotStructureConstant m i j k` is zero whenever
`pathMul m (slotToArrow (slotEquiv m i)) (slotToArrow (slotEquiv m j))
≠ some (slotToArrow (slotEquiv m k))`.

This is the classification gate: combined with Layers 1.1.1–1.1.3,
every non-zero entry of the encoder is captured by exactly one of the
four explicit cases (vertex–vertex–vertex diagonal, vertex–arrow–arrow
left action, arrow–vertex–arrow right action, padding diagonal). -/
theorem encoder_zero_at_remaining_path_triples
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j k : Fin (dimGQ m))
    (hi : isPathAlgebraSlot m adj i = true)
    (hj : isPathAlgebraSlot m adj j = true)
    (hk : isPathAlgebraSlot m adj k = true)
    (h_no_match : pathMul m (slotToArrow m (slotEquiv m i))
                            (slotToArrow m (slotEquiv m j)) ≠
                  some (slotToArrow m (slotEquiv m k))) :
    grochowQiaoEncode m adj i j k = 0 := by
  rw [grochowQiaoEncode_path m adj i j k hi hj hk]
  show (match pathMul m (slotToArrow m (slotEquiv m i))
                        (slotToArrow m (slotEquiv m j)) with
    | some d => if d = slotToArrow m (slotEquiv m k) then (1 : ℚ) else 0
    | none => 0) = 0
  -- `pathMul slot_i slot_j` is either `some d` with `d ≠ slot_k`, or `none`.
  rcases h_p : pathMul m (slotToArrow m (slotEquiv m i))
                          (slotToArrow m (slotEquiv m j)) with _ | d
  · -- `none` branch: the encoder returns `0` by definition.
    rfl
  · -- `some d` branch: we have `some d ≠ some slot_k`, so `d ≠ slot_k`,
    -- so the `if-then-else` returns `0`.
    have h_ne : d ≠ slotToArrow m (slotEquiv m k) := by
      intro h_eq
      apply h_no_match
      rw [h_p, h_eq]
    show (if d = slotToArrow m (slotEquiv m k) then (1 : ℚ) else 0) = 0
    exact if_neg h_ne

-- ============================================================================
-- Layer 1.1.6 — Encoder is zero at mixed (path/padding) triples.
--
-- This is the consumer-facing form of the existing
-- `grochowQiaoEncode_padding_distinguishable` lemma: any non-zero
-- encoder entry has all three slots in the same partition class
-- (either all path-algebra, or all padding).  Equivalently, mixed
-- triples are identically zero.
-- ============================================================================

/-- **Layer 1.1.6 — Encoder is zero at mixed (path/padding) triples.**

If the slot triple `(i, j, k)` has *some* slot in the path-algebra
class and *some* other slot in the padding class (i.e. the three
slots do not all lie in the same class), then the encoder evaluates
to zero.

This is the contrapositive of the existing
`grochowQiaoEncode_padding_distinguishable` lemma packaged in the
form Layer 1.2's associativity-identity proof consumes.  No new
mathematical content is introduced. -/
theorem encoder_zero_at_mixed_triples
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j k : Fin (dimGQ m))
    (h_mixed :
      ¬ (isPathAlgebraSlot m adj i = true ∧
         isPathAlgebraSlot m adj j = true ∧
         isPathAlgebraSlot m adj k = true) ∧
      ¬ (isPathAlgebraSlot m adj i = false ∧
         isPathAlgebraSlot m adj j = false ∧
         isPathAlgebraSlot m adj k = false)) :
    grochowQiaoEncode m adj i j k = 0 := by
  -- Suppose the encoder is non-zero; then by `_padding_distinguishable`
  -- the slots all lie in the same partition class — contradicting
  -- `h_mixed`.
  by_contra h_nz
  obtain ⟨h_not_all_path, h_not_all_pad⟩ := h_mixed
  rcases grochowQiaoEncode_padding_distinguishable m adj i j k h_nz with
    h_path | h_pad
  · exact h_not_all_path h_path
  · exact h_not_all_pad h_pad

-- ============================================================================
-- Layer 1.2.0 — Slot/arrow round-trip helpers.
--
-- The associativity-identity proof needs to convert a `QuiverArrow m`
-- output of `pathMul` (e.g. `pathMul slot_i slot_j = some d`) into a
-- slot index `a : Fin (dimGQ m)` with `slotToArrow (slotEquiv m a) = d`.
-- These helpers establish the inverse map and its round-trip identity.
-- ============================================================================

/-- The inverse of `slotToArrow`: convert a `QuiverArrow m` basis element
back to its `SlotKind m` representation. -/
def arrowToSlot (m : ℕ) : QuiverArrow m → SlotKind m
  | .id v => .vertex v
  | .edge u v => .arrow u v

/-- `slotToArrow` and `arrowToSlot` are mutually inverse. -/
@[simp] theorem slotToArrow_arrowToSlot (m : ℕ) (a : QuiverArrow m) :
    slotToArrow m (arrowToSlot m a) = a := by
  cases a <;> rfl

/-- `arrowToSlot` is the left inverse of `slotToArrow`. -/
@[simp] theorem arrowToSlot_slotToArrow (m : ℕ) (s : SlotKind m) :
    arrowToSlot m (slotToArrow m s) = s := by
  cases s <;> rfl

/-- Slot-of-arrow: convert a `QuiverArrow m` to a slot index in
`Fin (dimGQ m)`.  This is the unique slot index `a` such that
`slotToArrow m (slotEquiv m a) = q`. -/
def slotOfArrow (m : ℕ) (q : QuiverArrow m) : Fin (dimGQ m) :=
  (slotEquiv m).symm (arrowToSlot m q)

/-- Round-trip: the slot index `slotOfArrow m q` recovers the arrow `q`. -/
@[simp] theorem slotToArrow_slotEquiv_slotOfArrow (m : ℕ) (q : QuiverArrow m) :
    slotToArrow m (slotEquiv m (slotOfArrow m q)) = q := by
  unfold slotOfArrow
  rw [Equiv.apply_symm_apply, slotToArrow_arrowToSlot]

/-- Round-trip on the other side: `slotOfArrow` of `slotToArrow` recovers
the original slot index. -/
@[simp] theorem slotOfArrow_slotToArrow_slotEquiv (m : ℕ) (a : Fin (dimGQ m)) :
    slotOfArrow m (slotToArrow m (slotEquiv m a)) = a := by
  unfold slotOfArrow
  rw [arrowToSlot_slotToArrow, Equiv.symm_apply_apply]

/-- The slot index assigned to an arrow basis element matches a free
slot index `a` exactly when `slotToArrow (slotEquiv m a) = q`. -/
theorem eq_slotOfArrow_iff {m : ℕ} (a : Fin (dimGQ m)) (q : QuiverArrow m) :
    a = slotOfArrow m q ↔ slotToArrow m (slotEquiv m a) = q := by
  unfold slotOfArrow
  constructor
  · intro h
    rw [h, Equiv.apply_symm_apply, slotToArrow_arrowToSlot]
  · intro h
    rw [← h, arrowToSlot_slotToArrow, Equiv.symm_apply_apply]

/-- **Path-algebra output closure.** If `slot_a, slot_b` are both
path-algebra slots and `pathMul slot_a slot_b = some d`, then the
slot `slotOfArrow d` is also a path-algebra slot.

The proof case-splits on the four `pathMul`-table cases.  In each
non-`none` case, the output is uniquely determined by a present basis
element of one of the inputs, which itself is path-algebra by
hypothesis. -/
theorem slotOfArrow_pathMul_isPathAlgebra
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (a b : Fin (dimGQ m)) (d : QuiverArrow m)
    (ha : isPathAlgebraSlot m adj a = true)
    (hb : isPathAlgebraSlot m adj b = true)
    (h_pm : pathMul m (slotToArrow m (slotEquiv m a))
                       (slotToArrow m (slotEquiv m b)) = some d) :
    isPathAlgebraSlot m adj (slotOfArrow m d) = true := by
  -- Case-split on slotEquiv m a and slotEquiv m b.
  cases hsa : slotEquiv m a with
  | vertex va =>
      cases hsb : slotEquiv m b with
      | vertex vb =>
          -- pathMul (.id va) (.id vb) = if va = vb then some (.id va) else none.
          rw [hsa, hsb] at h_pm
          simp only [slotToArrow] at h_pm
          by_cases hv : va = vb
          · subst hv
            -- d = .id va, so slotOfArrow d = .vertex va — a vertex slot, always
            -- path-algebra.
            simp at h_pm
            subst h_pm
            unfold slotOfArrow arrowToSlot
            rw [isPathAlgebraSlot_vertex]
          · simp [hv] at h_pm
      | arrow ub vb =>
          -- pathMul (.id va) (.edge ub vb) = if va = ub then some (.edge ub vb)
          -- else none.
          rw [hsa, hsb] at h_pm
          simp only [slotToArrow, pathMul] at h_pm
          by_cases hv : va = ub
          · subst hv
            simp at h_pm
            subst h_pm
            -- d = .edge va vb, so slotOfArrow d = .arrow va vb.
            -- For path-algebra we need adj va vb = true; this follows from hb
            -- (b is the path-algebra arrow slot (va, vb)).
            have hb' : isPathAlgebraSlot m adj b = adj va vb := by
              unfold isPathAlgebraSlot; rw [hsb]
            rw [hb'] at hb
            unfold slotOfArrow arrowToSlot
            rw [isPathAlgebraSlot_arrow]
            exact hb
          · simp [hv] at h_pm
  | arrow ua wa =>
      cases hsb : slotEquiv m b with
      | vertex vb =>
          -- pathMul (.edge ua wa) (.id vb) = if wa = vb then some (.edge ua wa)
          -- else none.
          rw [hsa, hsb] at h_pm
          simp only [slotToArrow, pathMul] at h_pm
          by_cases hw : wa = vb
          · subst hw
            simp at h_pm
            subst h_pm
            -- d = .edge ua wa, so slotOfArrow d = .arrow ua wa.
            -- For path-algebra we need adj ua wa = true; this follows from ha.
            have ha' : isPathAlgebraSlot m adj a = adj ua wa := by
              unfold isPathAlgebraSlot; rw [hsa]
            rw [ha'] at ha
            unfold slotOfArrow arrowToSlot
            rw [isPathAlgebraSlot_arrow]
            exact ha
          · simp [hw] at h_pm
      | arrow ub vb =>
          -- pathMul (.edge _ _) (.edge _ _) = none, contradicting h_pm.
          rw [hsa, hsb] at h_pm
          simp only [slotToArrow, pathMul] at h_pm
          -- h_pm : none = some d, contradiction.
          exact absurd h_pm (by intro h; cases h)

-- ============================================================================
-- Layer 1.2.0 helper — Encoder factor T(i, j, a) is zero off the unique a*.
--
-- This private lemma packages the case analysis used in the LHS / RHS proofs
-- of the associativity identity: for every slot index `a` other than
-- `slotOfArrow d` (where `d` is the pathMul output, if it exists), the
-- encoder factor `T(i, j, a)` evaluates to zero.  The two failure cases
-- (path-algebra `a` with mismatched slot, padding `a` with mixed triple)
-- are both reduced to `encoder_zero_at_remaining_path_triples` and
-- `encoder_zero_at_mixed_triples` respectively.
-- ============================================================================

private theorem encoder_factor_zero_when_pathMul_mismatch
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j a : Fin (dimGQ m))
    (hi : isPathAlgebraSlot m adj i = true)
    (hj : isPathAlgebraSlot m adj j = true)
    (h_no_match : pathMul m (slotToArrow m (slotEquiv m i))
                             (slotToArrow m (slotEquiv m j)) ≠
                  some (slotToArrow m (slotEquiv m a))) :
    grochowQiaoEncode m adj i j a = 0 := by
  by_cases h_a : isPathAlgebraSlot m adj a = true
  · exact encoder_zero_at_remaining_path_triples m adj i j a hi hj h_a h_no_match
  · have h_a_false : isPathAlgebraSlot m adj a = false := by
      cases h : isPathAlgebraSlot m adj a with
      | true => exact absurd h h_a
      | false => rfl
    apply encoder_zero_at_mixed_triples m adj i j a
    refine ⟨?_, ?_⟩
    · rintro ⟨_, _, h_path_a⟩
      exact Bool.noConfusion (h_a_false.symm.trans h_path_a)
    · rintro ⟨h_pad_i, _, _⟩
      exact Bool.noConfusion (h_pad_i.symm.trans hi)

-- ============================================================================
-- Layer 1.2.0 helper — Encoder factor evaluation at the unique slot a*.
--
-- For path-algebra slots `i, j, a` with `pathMul slot_i slot_j = some slot_a`,
-- the encoder factor `T(i, j, a)` evaluates to `1`.  This is just the
-- path-algebra branch of the encoder applied at the matching case.
-- ============================================================================

private theorem encoder_factor_eq_one_at_pathMul_match
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j a : Fin (dimGQ m))
    (hi : isPathAlgebraSlot m adj i = true)
    (hj : isPathAlgebraSlot m adj j = true)
    (ha : isPathAlgebraSlot m adj a = true)
    (h_match : pathMul m (slotToArrow m (slotEquiv m i))
                          (slotToArrow m (slotEquiv m j)) =
               some (slotToArrow m (slotEquiv m a))) :
    grochowQiaoEncode m adj i j a = 1 := by
  rw [grochowQiaoEncode_path m adj i j a hi hj ha]
  show (match pathMul m (slotToArrow m (slotEquiv m i))
                        (slotToArrow m (slotEquiv m j)) with
    | some d => if d = slotToArrow m (slotEquiv m a) then (1 : ℚ) else 0
    | none => 0) = 1
  rw [h_match]
  show (if slotToArrow m (slotEquiv m a) = slotToArrow m (slotEquiv m a) then
          (1 : ℚ) else 0) = 1
  exact if_pos rfl

-- ============================================================================
-- Layer 1.2.1 — Closed form for the LHS of associativity.
-- ============================================================================

/-- **Layer 1.2.1 — Closed form for the associativity LHS.**

For any path-algebra triple `(i, j, k, l)`, the sum `∑ a, T(i, j, a) ·
T(a, k, l)` collapses to the indicator of the **chained** path
multiplication
`Option.bind (pathMul slot_i slot_j) (fun ab => pathMul ab slot_k) =
some slot_l`.

The sum is non-zero only at the single slot index
`a* := slotOfArrow (pathMul slot_i slot_j)` (if `pathMul slot_i slot_j`
is defined; the sum is zero otherwise).  At `a*` the product reduces
to `T(a*, k, l)`, which is `1` exactly when `pathMul slot_{a*} slot_k =
some slot_l`. -/
theorem encoder_associativity_lhs_eq_pathMul_chain
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j k l : Fin (dimGQ m))
    (hi : isPathAlgebraSlot m adj i = true)
    (hj : isPathAlgebraSlot m adj j = true)
    (hk : isPathAlgebraSlot m adj k = true)
    (hl : isPathAlgebraSlot m adj l = true) :
    (∑ a : Fin (dimGQ m), grochowQiaoEncode m adj i j a *
                          grochowQiaoEncode m adj a k l) =
    (if Option.bind (pathMul m (slotToArrow m (slotEquiv m i))
                                (slotToArrow m (slotEquiv m j)))
         (fun ab => pathMul m ab (slotToArrow m (slotEquiv m k))) =
         some (slotToArrow m (slotEquiv m l))
     then (1 : ℚ) else 0) := by
  -- Case-split on `pathMul slot_i slot_j`.
  rcases h_p : pathMul m (slotToArrow m (slotEquiv m i))
                          (slotToArrow m (slotEquiv m j)) with _ | d
  · -- `none` case: every T(i, j, a) = 0, so the sum is `0`; the RHS is also
    -- `0` because `Option.bind none _ = none ≠ some _`.
    -- After `rcases h_p:`, the RHS already has `none.bind ...` form.
    -- Reduce the if-then-else to `0` first.
    show (∑ a : Fin (dimGQ m), grochowQiaoEncode m adj i j a *
                                grochowQiaoEncode m adj a k l) =
         (if (none : Option (QuiverArrow m)).bind
              (fun ab => pathMul m ab (slotToArrow m (slotEquiv m k))) =
              some (slotToArrow m (slotEquiv m l))
          then (1 : ℚ) else 0)
    rw [show ((none : Option (QuiverArrow m)).bind
              (fun ab => pathMul m ab (slotToArrow m (slotEquiv m k)))) =
             (none : Option (QuiverArrow m)) from rfl]
    rw [if_neg (by intro h; cases h)]
    apply Finset.sum_eq_zero
    intro a _
    have h_T_zero : grochowQiaoEncode m adj i j a = 0 :=
      encoder_factor_zero_when_pathMul_mismatch m adj i j a hi hj (by
        rw [h_p]; intro h_eq; cases h_eq)
    rw [h_T_zero, zero_mul]
  · -- `some d` case.  The sum collapses to the contribution at
    -- `a* := slotOfArrow d`.
    set a_star : Fin (dimGQ m) := slotOfArrow m d with h_a_star_def
    have h_slot_a_star : slotToArrow m (slotEquiv m a_star) = d :=
      slotToArrow_slotEquiv_slotOfArrow m d
    have h_a_star_path : isPathAlgebraSlot m adj a_star = true :=
      slotOfArrow_pathMul_isPathAlgebra m adj i j d hi hj h_p
    -- Match-form: pathMul slot_i slot_j = some slot_{a*}.
    have h_p_a_star : pathMul m (slotToArrow m (slotEquiv m i))
                                  (slotToArrow m (slotEquiv m j)) =
                       some (slotToArrow m (slotEquiv m a_star)) := by
      rw [h_p, h_slot_a_star]
    -- Use Finset.sum_eq_single to collapse the sum at a_star.
    rw [Finset.sum_eq_single a_star]
    · -- Compute T(i, j, a*) * T(a*, k, l) and match against the RHS.
      rw [encoder_factor_eq_one_at_pathMul_match m adj i j a_star hi hj
            h_a_star_path h_p_a_star, one_mul]
      -- Now the goal is:
      --   grochowQiaoEncode m adj a_star k l =
      --     if (some d).bind (fun ab => pathMul m ab slot_k) = some slot_l then 1 else 0
      -- Reduce both sides to a common form `pathMul m d slot_k`.
      rw [grochowQiaoEncode_path m adj a_star k l h_a_star_path hk hl]
      unfold pathSlotStructureConstant
      -- LHS now: `match pathMul m (slotToArrow (slotEquiv a_star)) (slotToArrow ..k) with ...`
      -- Substitute `slotToArrow (slotEquiv a_star) = d`:
      rw [h_slot_a_star]
      -- LHS: `match pathMul m d slot_k with ... | some e => if e = slot_l then 1 else 0 | none => 0`
      -- RHS: `if (some d).bind (fun ab => pathMul m ab slot_k) = some slot_l then 1 else 0`
      --    = `if pathMul m d slot_k = some slot_l then 1 else 0` (by Option.bind).
      show (match pathMul m d (slotToArrow m (slotEquiv m k)) with
        | some e => if e = slotToArrow m (slotEquiv m l) then (1 : ℚ) else 0
        | none => 0) =
            (if Option.bind (some d)
                  (fun ab => pathMul m ab (slotToArrow m (slotEquiv m k))) =
                some (slotToArrow m (slotEquiv m l))
             then (1 : ℚ) else 0)
      cases h_q : pathMul m d (slotToArrow m (slotEquiv m k)) with
      | none =>
          show (0 : ℚ) =
                if Option.bind (some d)
                    (fun ab => pathMul m ab (slotToArrow m (slotEquiv m k))) =
                    some (slotToArrow m (slotEquiv m l)) then (1 : ℚ) else 0
          rw [show (Option.bind (some d)
                    (fun ab => pathMul m ab (slotToArrow m (slotEquiv m k)))) =
                    pathMul m d (slotToArrow m (slotEquiv m k)) from rfl]
          rw [h_q, if_neg (by intro h; cases h)]
      | some e =>
          show (if e = slotToArrow m (slotEquiv m l) then (1 : ℚ) else 0) =
                if Option.bind (some d)
                    (fun ab => pathMul m ab (slotToArrow m (slotEquiv m k))) =
                    some (slotToArrow m (slotEquiv m l)) then (1 : ℚ) else 0
          rw [show (Option.bind (some d)
                    (fun ab => pathMul m ab (slotToArrow m (slotEquiv m k)))) =
                    pathMul m d (slotToArrow m (slotEquiv m k)) from rfl]
          rw [h_q]
          by_cases h_eq : e = slotToArrow m (slotEquiv m l)
          · subst h_eq; simp
          · rw [if_neg h_eq, if_neg]
            intro h_some
            exact h_eq (Option.some.inj h_some)
    · -- For `a ≠ a*`, T(i, j, a) is zero.
      intro a _ h_ne
      have h_T_zero : grochowQiaoEncode m adj i j a = 0 :=
        encoder_factor_zero_when_pathMul_mismatch m adj i j a hi hj (by
          rw [h_p]
          intro h_eq
          apply h_ne
          rw [h_a_star_def, eq_slotOfArrow_iff]
          exact (Option.some.inj h_eq).symm)
      rw [h_T_zero, zero_mul]
    · intro h_not_mem
      exact absurd (Finset.mem_univ a_star) h_not_mem

-- ============================================================================
-- Layer 1.2.2 — Closed form for the RHS of associativity.
-- ============================================================================

/-- **Layer 1.2.2 — Closed form for the associativity RHS.**

Symmetric to Layer 1.2.1: for any path-algebra triple `(i, j, k, l)`,
the sum `∑ a, T(j, k, a) · T(i, a, l)` collapses to the indicator of
the alternative chained path multiplication
`Option.bind (pathMul slot_j slot_k) (fun bc => pathMul slot_i bc) =
some slot_l`. -/
theorem encoder_associativity_rhs_eq_pathMul_chain
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j k l : Fin (dimGQ m))
    (hi : isPathAlgebraSlot m adj i = true)
    (hj : isPathAlgebraSlot m adj j = true)
    (hk : isPathAlgebraSlot m adj k = true)
    (hl : isPathAlgebraSlot m adj l = true) :
    (∑ a : Fin (dimGQ m), grochowQiaoEncode m adj j k a *
                          grochowQiaoEncode m adj i a l) =
    (if Option.bind (pathMul m (slotToArrow m (slotEquiv m j))
                                (slotToArrow m (slotEquiv m k)))
         (fun bc => pathMul m (slotToArrow m (slotEquiv m i)) bc) =
         some (slotToArrow m (slotEquiv m l))
     then (1 : ℚ) else 0) := by
  -- Case-split on `pathMul slot_j slot_k`.
  rcases h_p : pathMul m (slotToArrow m (slotEquiv m j))
                          (slotToArrow m (slotEquiv m k)) with _ | d
  · -- `none` case: every T(j, k, a) = 0, so the sum is `0`; the RHS is also `0`.
    show (∑ a : Fin (dimGQ m), grochowQiaoEncode m adj j k a *
                                grochowQiaoEncode m adj i a l) =
         (if (none : Option (QuiverArrow m)).bind
              (fun bc => pathMul m (slotToArrow m (slotEquiv m i)) bc) =
              some (slotToArrow m (slotEquiv m l))
          then (1 : ℚ) else 0)
    rw [show ((none : Option (QuiverArrow m)).bind
              (fun bc => pathMul m (slotToArrow m (slotEquiv m i)) bc)) =
             (none : Option (QuiverArrow m)) from rfl]
    rw [if_neg (by intro h; cases h)]
    apply Finset.sum_eq_zero
    intro a _
    have h_T_zero : grochowQiaoEncode m adj j k a = 0 :=
      encoder_factor_zero_when_pathMul_mismatch m adj j k a hj hk (by
        rw [h_p]; intro h_eq; cases h_eq)
    rw [h_T_zero, zero_mul]
  · -- `some d` case.  The sum collapses at `a* := slotOfArrow d`.
    set a_star : Fin (dimGQ m) := slotOfArrow m d with h_a_star_def
    have h_slot_a_star : slotToArrow m (slotEquiv m a_star) = d :=
      slotToArrow_slotEquiv_slotOfArrow m d
    have h_a_star_path : isPathAlgebraSlot m adj a_star = true :=
      slotOfArrow_pathMul_isPathAlgebra m adj j k d hj hk h_p
    have h_p_a_star : pathMul m (slotToArrow m (slotEquiv m j))
                                  (slotToArrow m (slotEquiv m k)) =
                       some (slotToArrow m (slotEquiv m a_star)) := by
      rw [h_p, h_slot_a_star]
    rw [Finset.sum_eq_single a_star]
    · -- T(j, k, a*) = 1, so T(j, k, a*) * T(i, a*, l) = T(i, a*, l).
      rw [encoder_factor_eq_one_at_pathMul_match m adj j k a_star hj hk
            h_a_star_path h_p_a_star, one_mul]
      rw [grochowQiaoEncode_path m adj i a_star l hi h_a_star_path hl]
      unfold pathSlotStructureConstant
      rw [h_slot_a_star]
      show (match pathMul m (slotToArrow m (slotEquiv m i)) d with
        | some e => if e = slotToArrow m (slotEquiv m l) then (1 : ℚ) else 0
        | none => 0) =
            (if Option.bind (some d)
                  (fun bc => pathMul m (slotToArrow m (slotEquiv m i)) bc) =
                some (slotToArrow m (slotEquiv m l))
             then (1 : ℚ) else 0)
      cases h_q : pathMul m (slotToArrow m (slotEquiv m i)) d with
      | none =>
          show (0 : ℚ) =
                if Option.bind (some d)
                    (fun bc => pathMul m (slotToArrow m (slotEquiv m i)) bc) =
                    some (slotToArrow m (slotEquiv m l)) then (1 : ℚ) else 0
          rw [show (Option.bind (some d)
                    (fun bc => pathMul m (slotToArrow m (slotEquiv m i)) bc)) =
                    pathMul m (slotToArrow m (slotEquiv m i)) d from rfl]
          rw [h_q, if_neg (by intro h; cases h)]
      | some e =>
          show (if e = slotToArrow m (slotEquiv m l) then (1 : ℚ) else 0) =
                if Option.bind (some d)
                    (fun bc => pathMul m (slotToArrow m (slotEquiv m i)) bc) =
                    some (slotToArrow m (slotEquiv m l)) then (1 : ℚ) else 0
          rw [show (Option.bind (some d)
                    (fun bc => pathMul m (slotToArrow m (slotEquiv m i)) bc)) =
                    pathMul m (slotToArrow m (slotEquiv m i)) d from rfl]
          rw [h_q]
          by_cases h_eq : e = slotToArrow m (slotEquiv m l)
          · subst h_eq; simp
          · rw [if_neg h_eq, if_neg]
            intro h_some
            exact h_eq (Option.some.inj h_some)
    · -- For `a ≠ a*`, T(j, k, a) is zero.
      intro a _ h_ne
      have h_T_zero : grochowQiaoEncode m adj j k a = 0 :=
        encoder_factor_zero_when_pathMul_mismatch m adj j k a hj hk (by
          rw [h_p]
          intro h_eq
          apply h_ne
          rw [h_a_star_def, eq_slotOfArrow_iff]
          exact (Option.some.inj h_eq).symm)
      rw [h_T_zero, zero_mul]
    · intro h_not_mem
      exact absurd (Finset.mem_univ a_star) h_not_mem

-- ============================================================================
-- Layer 1.2.3 — Path-multiplication associativity (re-export).
--
-- The basis-element-level associativity `pathMul_assoc` already lives
-- in `PathAlgebra.lean`; we use it directly in Layer 1.2.4.  No new
-- declaration is added here.
-- ============================================================================

-- ============================================================================
-- Layer 1.2.4 — Encoder associativity identity (composition).
-- ============================================================================

/-- **Layer 1.2.4 — Encoder associativity identity.**

For any path-algebra quadruple `(i, j, k, l)`, the encoder satisfies
the associativity identity
```
∑ a, encode m adj i j a · encode m adj a k l =
  ∑ a, encode m adj j k a · encode m adj i a l
```

**Proof.** Both sides reduce by Layers 1.2.1 / 1.2.2 to closed-form
indicators of chained path multiplications.  The two chained
multiplications agree by `pathMul_assoc` (basis-element-level path-
algebra associativity from `PathAlgebra.lean`). -/
theorem encoder_associativity_identity
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j k l : Fin (dimGQ m))
    (hi : isPathAlgebraSlot m adj i = true)
    (hj : isPathAlgebraSlot m adj j = true)
    (hk : isPathAlgebraSlot m adj k = true)
    (hl : isPathAlgebraSlot m adj l = true) :
    (∑ a : Fin (dimGQ m), grochowQiaoEncode m adj i j a *
                          grochowQiaoEncode m adj a k l) =
    (∑ a : Fin (dimGQ m), grochowQiaoEncode m adj j k a *
                          grochowQiaoEncode m adj i a l) := by
  rw [encoder_associativity_lhs_eq_pathMul_chain m adj i j k l hi hj hk hl,
      encoder_associativity_rhs_eq_pathMul_chain m adj i j k l hi hj hk hl]
  -- Both sides are now `if (chained pathMul) = some slot_l then 1 else 0`.
  -- pathMul_assoc says the two chained pathMuls agree.
  rw [pathMul_assoc m (slotToArrow m (slotEquiv m i))
                       (slotToArrow m (slotEquiv m j))
                       (slotToArrow m (slotEquiv m k))]

-- ============================================================================
-- Layer 1.3 — Encoder path-identity pairing (algebraic non-degeneracy).
-- ============================================================================

/-- **Layer 1.3 — Encoder path-identity pairing at a present-arrow slot.**

For any present-arrow slot `i = .arrow u v` (with `adj u v = true`),
the double sum `∑ j k, encode m adj i j k` evaluates to exactly `1`.

**Why.**  In the radical-2 path algebra, the only basis elements `b`
such that `α(u, v) · b = c` for some basis element `c` are the
right-identity `e_v` (with `α(u, v) · e_v = α(u, v)`).  All other
products involving `α(u, v)` either return `0` (`α(u, v) · e_w = 0`
for `w ≠ v`, `α(u, v) · α(_, _) = 0` from `J² = 0`) or vanish at the
encoder (mixed triples). -/
theorem encoder_double_sum_at_present_arrow_slot
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i : Fin (dimGQ m)) (u v : Fin m)
    (hi : slotEquiv m i = .arrow u v)
    (h_adj : adj u v = true) :
    (∑ j : Fin (dimGQ m), ∑ k : Fin (dimGQ m),
      grochowQiaoEncode m adj i j k) = 1 := by
  -- The unique non-zero contribution is at (j, k) = (.vertex v, .arrow u v).
  let j_star : Fin (dimGQ m) := (slotEquiv m).symm (.vertex v)
  let k_star : Fin (dimGQ m) := (slotEquiv m).symm (.arrow u v)
  have hi_path : isPathAlgebraSlot m adj i = true := by
    unfold isPathAlgebraSlot; rw [hi]; exact h_adj
  have h_j_star_path : isPathAlgebraSlot m adj j_star = true := by
    unfold j_star
    exact isPathAlgebraSlot_vertex m adj v
  have h_k_star_path : isPathAlgebraSlot m adj k_star = true := by
    unfold k_star
    rw [isPathAlgebraSlot_arrow]; exact h_adj
  -- ∑ j, ∑ k, T(i, j, k) = ∑ j, [(j = j*) → ∑_k = T(i, j*, k_star) = 1, else = 0]
  rw [Finset.sum_eq_single j_star]
  · -- The j = j_star contribution.
    -- The inner sum ∑ k, T(i, j_star, k) collapses at k = k_star.
    rw [Finset.sum_eq_single k_star]
    · -- T(i, j_star, k_star) = 1 (arrow–vertex–arrow case).
      apply encoder_at_arrow_vertex_arrow_eq_one m adj i j_star k_star u v
        hi (by unfold j_star; rw [Equiv.apply_symm_apply])
        (by unfold k_star; rw [Equiv.apply_symm_apply])
        h_adj
    · -- For k ≠ k_star, T(i, j_star, k) = 0.
      intro k _ h_ne
      -- We compute pathMul slot_i slot_{j_star} = pathMul (.edge u v) (.id v) = some (.edge u v).
      have h_slot_j_star : slotEquiv m j_star = .vertex v := by
        unfold j_star; rw [Equiv.apply_symm_apply]
      have h_pmul : pathMul m (slotToArrow m (slotEquiv m i))
                              (slotToArrow m (slotEquiv m j_star)) =
                    some (.edge u v) := by
        rw [hi, h_slot_j_star]
        simp [slotToArrow, pathMul]
      -- Case-split on whether k is path-algebra.
      by_cases h_k_path : isPathAlgebraSlot m adj k = true
      · -- All path-algebra: use encoder_zero_at_remaining_path_triples.
        apply encoder_zero_at_remaining_path_triples m adj i j_star k
          hi_path h_j_star_path h_k_path
        rw [h_pmul]
        -- some (.edge u v) ≠ some (slotToArrow (slotEquiv k)) requires
        -- slot_k ≠ .arrow u v, i.e., k ≠ k_star.
        intro h_eq
        apply h_ne
        have h_slot : slotToArrow m (slotEquiv m k) = .edge u v :=
          (Option.some.inj h_eq).symm
        have h_k_eq : k = (slotEquiv m).symm (slotEquiv m k) :=
          (Equiv.symm_apply_apply _ _).symm
        rw [h_k_eq]
        have h_slot_eq : slotEquiv m k = .arrow u v := by
          rw [show slotEquiv m k = arrowToSlot m (slotToArrow m (slotEquiv m k))
                from (arrowToSlot_slotToArrow m _).symm]
          rw [h_slot]
          rfl
        rw [h_slot_eq]
      · -- Mixed branch: i, j_star path-algebra, k padding.
        have h_k_false : isPathAlgebraSlot m adj k = false := by
          cases h : isPathAlgebraSlot m adj k with
          | true => exact absurd h h_k_path
          | false => rfl
        apply encoder_zero_at_mixed_triples m adj i j_star k
        refine ⟨?_, ?_⟩
        · rintro ⟨_, _, h_path_k⟩
          exact Bool.noConfusion (h_k_false.symm.trans h_path_k)
        · rintro ⟨h_pad_i, _, _⟩
          exact Bool.noConfusion (h_pad_i.symm.trans hi_path)
    · intro h_not_mem
      exact absurd (Finset.mem_univ k_star) h_not_mem
  · -- For j ≠ j_star, the inner sum ∑ k, T(i, j, k) is zero.
    -- Argument: T(i, j, k) is non-zero only when (i, j, k) is one of the four
    -- explicit cases.  Since slot_i = .arrow u v, the only case is arrow–
    -- vertex–arrow, requiring slot_j = .vertex v.  So if j ≠ j_star, T = 0.
    intro j _ h_ne
    apply Finset.sum_eq_zero
    intro k _
    -- We show T(i, j, k) = 0.
    -- Case-split on whether (i, j, k) is path-algebra or padding.
    by_cases h_j : isPathAlgebraSlot m adj j = true
    · by_cases h_k : isPathAlgebraSlot m adj k = true
      · -- All path-algebra: use encoder_zero_at_remaining_path_triples.
        apply encoder_zero_at_remaining_path_triples m adj i j k hi_path h_j h_k
        -- pathMul slot_i slot_j = pathMul (.edge u v) slot_j.  By the table:
        -- = some (.edge u v) iff slot_j = .id v; else = none.
        rw [hi]
        show pathMul m (slotToArrow m (.arrow u v))
                       (slotToArrow m (slotEquiv m j)) ≠
              some (slotToArrow m (slotEquiv m k))
        cases h_sj : slotEquiv m j with
        | vertex w =>
            simp only [slotToArrow, pathMul]
            by_cases h_vw : v = w
            · subst h_vw
              -- slot_j = .vertex v, but j ≠ j_star = .symm (.vertex v).
              -- Contradiction with h_ne.
              exfalso
              apply h_ne
              unfold j_star
              rw [← h_sj, Equiv.symm_apply_apply]
            · simp [h_vw]
        | arrow uj wj =>
            simp only [slotToArrow, pathMul]
            intro h
            cases h
      · -- Mixed branch: i path, j path, k padding.
        have h_k_false : isPathAlgebraSlot m adj k = false := by
          cases h : isPathAlgebraSlot m adj k with
          | true => exact absurd h h_k
          | false => rfl
        apply encoder_zero_at_mixed_triples m adj i j k
        refine ⟨?_, ?_⟩
        · rintro ⟨_, _, h_path_k⟩
          exact Bool.noConfusion (h_k_false.symm.trans h_path_k)
        · rintro ⟨h_pad_i, _, _⟩
          exact Bool.noConfusion (h_pad_i.symm.trans hi_path)
    · -- Mixed branch: i path, j padding.
      have h_j_false : isPathAlgebraSlot m adj j = false := by
        cases h : isPathAlgebraSlot m adj j with
        | true => exact absurd h h_j
        | false => rfl
      apply encoder_zero_at_mixed_triples m adj i j k
      refine ⟨?_, ?_⟩
      · rintro ⟨_, h_path_j, _⟩
        exact Bool.noConfusion (h_j_false.symm.trans h_path_j)
      · rintro ⟨h_pad_i, _, _⟩
        exact Bool.noConfusion (h_pad_i.symm.trans hi_path)
  · intro h_not_mem
    exact absurd (Finset.mem_univ j_star) h_not_mem

/-- **Layer 1.3 — Encoder path-identity pairing at a vertex slot.**

For any vertex slot `i = .vertex u`, the encoder restricted to the
`(vertex u, vertex u, vertex u)` triple-diagonal contributes `1`,
witnessing that the double sum `∑ j k, encode m adj i j k` is at
least `1`.

*Cryptographic role.*  Combined with
`encoder_double_sum_at_present_arrow_slot` (which gives the *exact*
value `1` for present-arrow slots), this forms part of the algebraic
non-degeneracy invariant Layer 1.3 establishes: the path algebra's
multiplication structure leaves a non-zero footprint at every path-
algebra slot, distinguishing it from the padding subspace (where the
double sum is also non-zero, but with value `2` from the
distinguished-padding diagonal). -/
theorem encoder_idempotent_contribution_at_vertex_slot
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i : Fin (dimGQ m)) (u : Fin m)
    (hi : slotEquiv m i = .vertex u) :
    grochowQiaoEncode m adj i i i = 1 := by
  exact encoder_at_vertex_vertex_vertex_eq_one m adj i i i u hi hi hi

end GrochowQiao
end Orbcrypt
