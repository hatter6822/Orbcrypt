/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
Encoder unit-compatibility identity (R-TI Phase 3 / Sub-task A.1.5).

Establishes the structure-tensor identity that captures the
multiplicative-identity equation `1 · slot_j = slot_j` in
`pathAlgebraQuotient m`, expressed via the Grochow–Qiao encoder
restricted to path-algebra slots.

Specifically, for any two path-algebra slots `(j, k)`, the sum of
encoder entries `T(vertex v, j, k)` over all vertex slots `v` equals
the indicator of `slotToArrow slot_j = slotToArrow slot_k`.

This identity is **prerequisite for Sub-task A.5** (Manin tensor-
stabilizer theorem) — it supplies the unit-coefficient equation
constraining a GL³ tensor isomorphism between two encoders to
respect the algebra unit `1 = ∑_v vertexIdempotent v`.

See `docs/planning/AUDIT_2026-04-28_PHASE_3_PROP_DISCHARGE_PLAN.md`
§ "A.1.5 — Encoder unit-compatibility" for the work-unit specification.
-/

import Orbcrypt.Hardness.GrochowQiao.EncoderPolynomialIdentities

/-!
# Encoder unit-compatibility identity (Sub-task A.1.5)

## Mathematical content

In the path algebra `pathAlgebraQuotient m`, the unit element is
`1 = ∑_v vertexIdempotent v`.  Multiplying `1 · slot_j` from the left
is the identity action: `1 · slot_j = slot_j`.  Expanding via the
path-algebra basis structure constants gives
`∑_v T(v, j, k) = δ(slotToArrow slot_j, slotToArrow slot_k)` for
path-algebra `(j, k)`.

This module formalizes that identity for the encoder
`grochowQiaoEncode m adj` (which IS the structure tensor of
`pathAlgebraQuotient m` on path-algebra slots, by construction).

## Public surface

* `encoder_unit_compatibility` — the headline identity at the slot-
  discriminator level.

## Status

Sub-task A.1.5 lands the **encoder unit-compatibility identity**
unconditionally.  Consumed by `Manin/TensorStabilizer.lean` (A.5.3)
as the `h_unit_compat` hypothesis input to Manin's theorem.

## Naming

Identifiers describe content (encoder unit compatibility), not
workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt
open scoped BigOperators

-- ============================================================================
-- Helper lemmas for the unit-compatibility proof.
-- ============================================================================

/-- **Helper:** at vertex slot `i = (slotEquiv m).symm (.vertex v)`, the
encoder factor `T(vertex v, vertex w, k)` is non-zero only when `v = w`,
in which case it equals the indicator that `k = (slotEquiv m).symm
(.vertex w)`. -/
private theorem encoder_vertex_vertex_eq
    (m : ℕ) (adj : Fin m → Fin m → Bool) (k : Fin (dimGQ m)) (v w : Fin m)
    (hk : isPathAlgebraSlot m adj k = true) :
    grochowQiaoEncode m adj
        ((slotEquiv m).symm (.vertex v))
        ((slotEquiv m).symm (.vertex w)) k =
      (if v = w ∧ slotEquiv m k = .vertex v then (1 : ℚ) else 0) := by
  by_cases hvw : v = w
  · subst hvw
    -- v = w: the encoder is `T(vertex v, vertex v, k)`. By idempotency
    -- `pathMul (id v) (id v) = some (id v)`, so `T = 1` iff `slot_k =
    -- vertex v`, else `T = 0`.
    -- NB: `cases hsk : slotEquiv m k` will substitute `slotEquiv m k`
    -- in the goal with the constructor pattern.  We track the post-
    -- substitution shape directly.
    cases hsk : slotEquiv m k with
    | vertex w' =>
        -- Post-cases goal: T = if v = v ∧ SlotKind.vertex w' = SlotKind.vertex v then 1 else 0
        by_cases hvw' : v = w'
        · subst hvw'
          rw [encoder_at_vertex_vertex_vertex_eq_one m adj
                ((slotEquiv m).symm (.vertex v))
                ((slotEquiv m).symm (.vertex v)) k v
                (by rw [Equiv.apply_symm_apply])
                (by rw [Equiv.apply_symm_apply])
                hsk]
          -- Goal: 1 = if v = v ∧ SlotKind.vertex v = SlotKind.vertex v then 1 else 0
          -- Both conjuncts are rfl, so the if returns 1.
          rw [if_pos ⟨rfl, rfl⟩]
        · -- v ≠ w': encoder = 0; condition `SlotKind.vertex w' = SlotKind.vertex v` is false.
          have h_ne :
              pathMul m
                (slotToArrow m (slotEquiv m
                  ((slotEquiv m).symm (.vertex v))))
                (slotToArrow m (slotEquiv m
                  ((slotEquiv m).symm (.vertex v)))) ≠
              some (slotToArrow m (slotEquiv m k)) := by
            rw [Equiv.apply_symm_apply, hsk]
            simp [slotToArrow]
            exact fun h_eq => hvw' h_eq
          rw [encoder_zero_at_remaining_path_triples m adj
                ((slotEquiv m).symm (.vertex v))
                ((slotEquiv m).symm (.vertex v)) k
                (by unfold isPathAlgebraSlot
                    rw [Equiv.apply_symm_apply])
                (by unfold isPathAlgebraSlot
                    rw [Equiv.apply_symm_apply])
                hk h_ne]
          -- Goal: 0 = if v = v ∧ SlotKind.vertex w' = SlotKind.vertex v then 1 else 0
          -- The second conjunct fails: SlotKind.vertex w' = SlotKind.vertex v ↔ w' = v ↔ False (hvw').
          exact (if_neg (fun ⟨_, h⟩ => hvw' (SlotKind.vertex.inj h).symm)).symm
    | arrow u' w' =>
        -- pathMul (id v) (id v) = some (id v); but slot_k = arrow u' w' ≠ id v.
        have h_ne :
            pathMul m
              (slotToArrow m (slotEquiv m
                ((slotEquiv m).symm (.vertex v))))
              (slotToArrow m (slotEquiv m
                ((slotEquiv m).symm (.vertex v)))) ≠
            some (slotToArrow m (slotEquiv m k)) := by
          rw [Equiv.apply_symm_apply, hsk]
          simp [slotToArrow]
        rw [encoder_zero_at_remaining_path_triples m adj
              ((slotEquiv m).symm (.vertex v))
              ((slotEquiv m).symm (.vertex v)) k
              (by unfold isPathAlgebraSlot
                  rw [Equiv.apply_symm_apply])
              (by unfold isPathAlgebraSlot
                  rw [Equiv.apply_symm_apply])
              hk h_ne]
        -- Goal: 0 = if v = v ∧ SlotKind.arrow u' w' = SlotKind.vertex v then 1 else 0
        -- SlotKind.arrow ≠ SlotKind.vertex (different constructors).
        exact (if_neg (by rintro ⟨_, h⟩; cases h)).symm
  · -- v ≠ w: pathMul (id v) (id w) = none ⇒ encoder = 0.
    have h_ne :
        pathMul m
          (slotToArrow m (slotEquiv m
            ((slotEquiv m).symm (.vertex v))))
          (slotToArrow m (slotEquiv m
            ((slotEquiv m).symm (.vertex w)))) ≠
        some (slotToArrow m (slotEquiv m k)) := by
      rw [Equiv.apply_symm_apply, Equiv.apply_symm_apply]
      simp [slotToArrow, pathMul_id_id_ne m v w hvw]
    rw [encoder_zero_at_remaining_path_triples m adj
          ((slotEquiv m).symm (.vertex v))
          ((slotEquiv m).symm (.vertex w)) k
          (by unfold isPathAlgebraSlot
              rw [Equiv.apply_symm_apply])
          (by unfold isPathAlgebraSlot
              rw [Equiv.apply_symm_apply])
          hk h_ne]
    -- Goal: 0 = if v = w ∧ slotEquiv m k = .vertex v then 1 else 0
    -- First conjunct `v = w` is false (hvw).
    exact (if_neg (fun ⟨h, _⟩ => hvw h)).symm

/-- **Helper:** at vertex slot `i = (slotEquiv m).symm (.vertex v)` with
arrow target `j = (slotEquiv m).symm (.arrow u w)` (a present arrow,
`adj u w = true`), the encoder factor `T(vertex v, arrow u w, k)` is
non-zero only when `v = u`, in which case it equals the indicator that
`slotEquiv m k = .arrow u w`. -/
private theorem encoder_vertex_arrow_eq
    (m : ℕ) (adj : Fin m → Fin m → Bool) (k : Fin (dimGQ m))
    (v u w : Fin m) (h_adj : adj u w = true)
    (hk : isPathAlgebraSlot m adj k = true) :
    grochowQiaoEncode m adj
        ((slotEquiv m).symm (.vertex v))
        ((slotEquiv m).symm (.arrow u w)) k =
      (if v = u ∧ slotEquiv m k = .arrow u w then (1 : ℚ) else 0) := by
  by_cases hvu : v = u
  · subst hvu
    -- v = u: pathMul (id v) (edge v w) = some (edge v w); T = 1 iff slot_k = arrow v w.
    cases hsk : slotEquiv m k with
    | vertex w' =>
        -- slot_k = vertex w' ≠ arrow v w; encoder = 0; condition false.
        have h_ne :
            pathMul m
              (slotToArrow m (slotEquiv m
                ((slotEquiv m).symm (.vertex v))))
              (slotToArrow m (slotEquiv m
                ((slotEquiv m).symm (.arrow v w)))) ≠
            some (slotToArrow m (slotEquiv m k)) := by
          rw [Equiv.apply_symm_apply, Equiv.apply_symm_apply, hsk]
          simp [slotToArrow]
        rw [encoder_zero_at_remaining_path_triples m adj
              ((slotEquiv m).symm (.vertex v))
              ((slotEquiv m).symm (.arrow v w)) k
              (by unfold isPathAlgebraSlot
                  rw [Equiv.apply_symm_apply])
              (by unfold isPathAlgebraSlot
                  rw [Equiv.apply_symm_apply]; exact h_adj)
              hk h_ne]
        exact (if_neg (by rintro ⟨_, h⟩; cases h)).symm
    | arrow u' w' =>
        by_cases huw' : u' = v ∧ w' = w
        · obtain ⟨hu', hw'⟩ := huw'
          -- hu' : u' = v, hw' : w' = w.  Use rw to replace u' → v, w' → w
          -- in both the goal and `hsk` (avoiding `subst` which may
          -- eliminate `v` instead of `u'` in this context).
          rw [hu', hw'] at hsk
          rw [hu', hw']
          rw [encoder_at_vertex_arrow_arrow_eq_one m adj
                ((slotEquiv m).symm (.vertex v))
                ((slotEquiv m).symm (.arrow v w)) k v w
                (by rw [Equiv.apply_symm_apply])
                (by rw [Equiv.apply_symm_apply])
                hsk h_adj]
          rw [if_pos ⟨rfl, rfl⟩]
        · have h_ne :
              pathMul m
                (slotToArrow m (slotEquiv m
                  ((slotEquiv m).symm (.vertex v))))
                (slotToArrow m (slotEquiv m
                  ((slotEquiv m).symm (.arrow v w)))) ≠
              some (slotToArrow m (slotEquiv m k)) := by
            rw [Equiv.apply_symm_apply, Equiv.apply_symm_apply, hsk]
            simp [slotToArrow]
            intro h1 h2
            exact huw' ⟨h1.symm, h2.symm⟩
          rw [encoder_zero_at_remaining_path_triples m adj
                ((slotEquiv m).symm (.vertex v))
                ((slotEquiv m).symm (.arrow v w)) k
                (by unfold isPathAlgebraSlot
                    rw [Equiv.apply_symm_apply])
                (by unfold isPathAlgebraSlot
                    rw [Equiv.apply_symm_apply]; exact h_adj)
                hk h_ne]
          -- Goal: 0 = if v = v ∧ SlotKind.arrow u' w' = SlotKind.arrow v w then 1 else 0
          -- The condition's second conjunct: SlotKind.arrow u' w' = SlotKind.arrow v w iff u' = v ∧ w' = w (false by huw').
          exact (if_neg (by
            rintro ⟨_, h⟩
            apply huw'
            injection h with h1 h2
            exact ⟨h1, h2⟩)).symm
  · -- v ≠ u: pathMul (id v) (edge u w) = none ⇒ encoder = 0.
    have h_ne :
        pathMul m
          (slotToArrow m (slotEquiv m
            ((slotEquiv m).symm (.vertex v))))
          (slotToArrow m (slotEquiv m
            ((slotEquiv m).symm (.arrow u w)))) ≠
        some (slotToArrow m (slotEquiv m k)) := by
      rw [Equiv.apply_symm_apply, Equiv.apply_symm_apply]
      show pathMul m (QuiverArrow.id v) (QuiverArrow.edge u w) ≠
           some (slotToArrow m (slotEquiv m k))
      rw [pathMul_id_edge, if_neg hvu]
      intro h; cases h
    rw [encoder_zero_at_remaining_path_triples m adj
          ((slotEquiv m).symm (.vertex v))
          ((slotEquiv m).symm (.arrow u w)) k
          (by unfold isPathAlgebraSlot
              rw [Equiv.apply_symm_apply])
          (by unfold isPathAlgebraSlot
              rw [Equiv.apply_symm_apply]; exact h_adj)
          hk h_ne]
    exact (if_neg (fun ⟨h, _⟩ => hvu h)).symm

-- ============================================================================
-- A.1.5 — Encoder unit-compatibility (headline theorem).
-- ============================================================================

/-- **Sub-task A.1.5 — Vertex-sum identity at a path-algebra slot pair.**

For any path-algebra slots `(j, k)`, the sum of encoder entries
`T(vertex v, j, k)` over all vertex slots `v : Fin m` equals `1` when
`slotToArrow slot_j = slotToArrow slot_k` and `0` otherwise.

This is the **multiplicative-identity identity** witnessing that the
sum-of-vertex-idempotents `∑ v, e_v` acts as the unit `1` of the
path algebra.  In the structure-tensor language: the unit coefficient
vector `c(v) = 1` (across all vertices) maps under the basis-multiplication
to the indicator that `slot_j` and `slot_k` are equal as basis elements.

**Proof technique.**  Case-split `slotEquiv m j` on `vertex w` vs
`arrow u w`.  In the vertex case, only `v = w` contributes a non-zero
summand (idempotent law `e_w · e_w = e_w`); in the arrow case, only
`v = u` contributes (left vertex action `e_u · α(u, w) = α(u, w)`).
Apply `Finset.sum_eq_single` at the contributing vertex.

**Consumer.**  `Manin.algHomOfTensorIso` (A.5.3) consumes this
identity as `h_unit_compat`. -/
theorem encoder_unit_compatibility
    (m : ℕ) (adj : Fin m → Fin m → Bool) (j k : Fin (dimGQ m))
    (hj : isPathAlgebraSlot m adj j = true)
    (hk : isPathAlgebraSlot m adj k = true) :
    (∑ v : Fin m, grochowQiaoEncode m adj
        ((slotEquiv m).symm (.vertex v)) j k) =
      (if slotToArrow m (slotEquiv m j) = slotToArrow m (slotEquiv m k)
       then (1 : ℚ) else 0) := by
  -- Case-split on `slotEquiv m j`, but DO NOT do `cases hsj : slotEquiv m j`
  -- (which would substitute in the goal); instead use `obtain` on a fresh var.
  obtain ⟨sj, hsj⟩ : ∃ sj, slotEquiv m j = sj := ⟨_, rfl⟩
  cases sj with
  | vertex w =>
      -- For `slot_j = vertex w`, only `v = w` contributes.
      -- Convert j to (slotEquiv m).symm (.vertex w) using hsj.
      have hj_eq : j = (slotEquiv m).symm (.vertex w) := by
        rw [← hsj, Equiv.symm_apply_apply]
      rw [hj_eq]
      -- Apply Finset.sum_eq_single at v = w.
      rw [Finset.sum_eq_single w]
      · -- At v = w: T(vertex w, vertex w, k) = if w = w ∧ slot_k = .vertex w then 1 else 0.
        rw [encoder_vertex_vertex_eq m adj k w w hk]
        -- Goal: (if w = w ∧ slotEquiv m k = .vertex w then 1 else 0)
        --     = (if slotToArrow m (slotEquiv m ((slotEquiv m).symm (.vertex w))) = slotToArrow m (slotEquiv m k) then 1 else 0)
        -- Reduce slotEquiv m ((slotEquiv m).symm _) = _ using Equiv.apply_symm_apply.
        simp only [Equiv.apply_symm_apply]
        -- Match the two if-then-elses.
        by_cases h_match : slotToArrow m (.vertex w) =
                            slotToArrow m (slotEquiv m k)
        · -- Construct an explicit witness for the And condition.
          -- First derive `slotEquiv m k = .vertex w` from h_match.
          have h_slot_k : slotEquiv m k = SlotKind.vertex w := by
            cases hsk : slotEquiv m k with
            | vertex w' =>
                rw [hsk] at h_match
                simp [slotToArrow] at h_match
                rw [h_match]
            | arrow u' w' =>
                rw [hsk] at h_match
                simp [slotToArrow] at h_match
          -- Now apply if_pos with explicit ⟨_, h_slot_k⟩.  The first
          -- conjunct `w = w` is presented by Lean's elaboration as `True`
          -- (rather than `w = w` literally) because the `Decidable`-instance
          -- machinery for the And condition reduces the trivially-decidable
          -- `w = w` (where `w : Fin m`, decidable via `Fin.decEq`) to its
          -- decided form during elaboration of the `if` term.  Use
          -- `True.intro` (= `trivial`) as the first witness — semantically
          -- equivalent to `rfl : w = w` since both inhabit the proposition.
          rw [if_pos h_match, if_pos ⟨True.intro, h_slot_k⟩]
        · rw [if_neg h_match]
          rw [if_neg]
          rintro ⟨_, h⟩
          apply h_match
          rw [h]
      · -- For v ≠ w: encoder factor is 0 (different vertex sources).
        intro v _ h_v_ne_w
        rw [encoder_vertex_vertex_eq m adj k v w hk]
        rw [if_neg]
        rintro ⟨h, _⟩
        exact h_v_ne_w h
      · intro h_not_mem
        exact absurd (Finset.mem_univ w) h_not_mem
  | arrow u w =>
      -- For `slot_j = arrow u w` (present arrow), only `v = u` contributes.
      have h_adj : adj u w = true := by
        have := hj
        unfold isPathAlgebraSlot at this
        rw [hsj] at this
        exact this
      have hj_eq : j = (slotEquiv m).symm (.arrow u w) := by
        rw [← hsj, Equiv.symm_apply_apply]
      rw [hj_eq]
      rw [Finset.sum_eq_single u]
      · -- At v = u: T(vertex u, arrow u w, k) = if u = u ∧ slot_k = .arrow u w then 1 else 0.
        rw [encoder_vertex_arrow_eq m adj k u u w h_adj hk]
        simp only [Equiv.apply_symm_apply]
        by_cases h_match : slotToArrow m (.arrow u w) =
                            slotToArrow m (slotEquiv m k)
        · -- Construct an explicit witness for the And condition.
          have h_slot_k : slotEquiv m k = SlotKind.arrow u w := by
            cases hsk : slotEquiv m k with
            | vertex w' =>
                rw [hsk] at h_match
                simp [slotToArrow] at h_match
            | arrow u' w' =>
                rw [hsk] at h_match
                simp [slotToArrow] at h_match
                obtain ⟨h1, h2⟩ := h_match
                -- h1 : u = u', h2 : w = w'.  After subst, the goal becomes
                -- `SlotKind.arrow u w = SlotKind.arrow u w` because
                -- `cases hsk : slotEquiv m k` already substituted
                -- `slotEquiv m k` → `SlotKind.arrow u' w'` in the goal.
                subst h1; subst h2
                rfl
          -- Apply if_pos with explicit ⟨True.intro, h_slot_k⟩.  As in the
          -- vertex-vertex case above, the first conjunct's expected type is
          -- `True` due to `Decidable`-instance normalization of `u = u`.
          rw [if_pos h_match, if_pos ⟨True.intro, h_slot_k⟩]
        · rw [if_neg h_match]
          rw [if_neg]
          rintro ⟨_, h⟩
          apply h_match
          rw [h]
      · intro v _ h_v_ne_u
        rw [encoder_vertex_arrow_eq m adj k v u w h_adj hk]
        rw [if_neg]
        rintro ⟨h, _⟩
        exact h_v_ne_u h
      · intro h_not_mem
        exact absurd (Finset.mem_univ u) h_not_mem

end GrochowQiao
end Orbcrypt
