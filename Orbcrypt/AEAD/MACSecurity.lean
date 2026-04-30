/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Mathlib.Data.Fintype.Pi
import Mathlib.Probability.ProbabilityMassFunction.Basic
import Orbcrypt.AEAD.MAC
import Orbcrypt.AEAD.CarterWegmanMAC
import Orbcrypt.Probability.Monad
import Orbcrypt.Probability.UniversalHash

/-!
# Orbcrypt.AEAD.MACSecurity

Probabilistic SUF-CMA framework for Message Authentication Codes.

## Overview

This module formalises the Wegman–Carter SUF-CMA security model
(Stinson 1994 Theorem 1) and its associated reduction from
ε-strongly-universal-2 hash families to one-time SUF-CMA security.

## Main definitions

* `Orbcrypt.MACAdversary` — a 1-time MAC adversary: chooses a query
  message, observes the honest tag, and produces a forgery.
* `Orbcrypt.MACAdversary.forges` — Boolean predicate: the forgery
  uses a fresh message and the tag verifies under the (unknown) key.
* `Orbcrypt.forgeryAdvantage` — probability of a successful forgery,
  averaged over uniformly random key.
* `Orbcrypt.IsSUFCMASecure` — `mac` is `ε`-SUF-CMA-secure (1-time)
  iff every `MACAdversary` has forgery advantage at most `ε`.
* `Orbcrypt.MultiQueryMACAdversary` — Q-time non-adaptive variant:
  pre-commits to `Q` queries, observes the `Q` honest tags, then
  produces a forgery on a fresh message.
* `Orbcrypt.forgeryAdvantage_Qtime` — Q-time forgery probability.
* `Orbcrypt.IsQtimeSUFCMASecure` — `ε`-SUF-CMA-secure (Q-time).
* `Orbcrypt.IsKeyRecoverableForSomeQueries` — predicate witnessing
  the existence of `Q` query-tag pairs from which a recovery
  function can extract the key. The witness for the negative Q-time
  SUF-CMA result.

## Main results

* `Orbcrypt.forgeryAdvantage_nonneg`, `forgeryAdvantage_le_one` —
  basic bounds on forgery advantage.
* `Orbcrypt.isSUFCMASecure_of_isEpsilonSU2` — **headline 1-time
  SUF-CMA reduction**: ε-SU2 implies ε-SUF-CMA security for the
  deterministic-tag MAC.
* `Orbcrypt.not_isQtimeSUFCMASecure_of_keyRecoverableForSomeQueries`
  — **headline Q-time NEGATIVE result**: when the hash is key-
  recoverable from some specific Q-tuple of queries, the
  corresponding deterministic-tag MAC is **not** ε-(Q+1)-time-SUF-
  CMA-secure for any ε < 1.

## Mathematical content

### One-time SUF-CMA reduction (Stinson 1994 Theorem 1)

Let `mac := deterministicTagMAC h` and `h` be `ε`-SU2. Every 1-time
adversary `A` has `forgeryAdvantage mac A ≤ ε`.

**Proof outline.** Set `m_q := A.query`, `m'(t) := (A.forge t).1`,
`t'(t) := (A.forge t).2`. The win event is
```
Win(k) := m'(h k m_q) ≠ m_q ∧ verify k (m'(h k m_q)) (t'(h k m_q))
```
By `verify_inj`, the second conjunct is equivalent to
`h k (m'(h k m_q)) = t'(h k m_q)`.

For each `t_q : Tag`, define
`Win_at(k, t_q) := (h k m_q = t_q) ∧ (m'(t_q) ≠ m_q) ∧
                   (h k (m'(t_q)) = t'(t_q))`.
Since `h k m_q` takes exactly one value, the events `Win_at(k, t_q)`
partition `Win(k)` over `t_q`. Hence
```
Pr_k[Win] = Σ_{t_q : Tag} Pr_k[Win_at(t_q)]
```

Per-`t_q` bound:
* If `m'(t_q) = m_q`: `Win_at` is false, summand = 0.
* If `m'(t_q) ≠ m_q`: by ε-SU2 at messages `(m_q, m'(t_q))` and
  tag values `(t_q, t'(t_q))`,
  `Pr_k[h k m_q = t_q ∧ h k (m'(t_q)) = t'(t_q)] ≤ ε / |Tag|`.
  Note: `Win_at(t_q)` is a sub-event of this joint event (it adds
  the `m'(t_q) ≠ m_q` constraint), so the same bound applies.

Sum over `t_q`:
```
Pr_k[Win] ≤ Σ_{t_q : Tag} (ε / |Tag|) = |Tag| · (ε / |Tag|) = ε.
```

### Q-time SUF-CMA — NEGATIVE result for nonce-free MACs

The standard Wegman–Carter 1981 Q-time MAC requires fresh nonces
per message. For nonce-free constructions like the in-tree
`carterWegmanMAC` and `bitstringPolynomialMAC`, the adversary at
Q ≥ 2 queries can solve a 2-equation linear / polynomial system
to recover the key, then forge deterministically on any fresh
message. This module formalises that attack as a *negative* result:
under the hypothesis that the hash is "key-recoverable from some
queries" (an existential predicate), no `ε < 1` Q-time SUF-CMA
bound holds.

The Q-time *positive* bound for nonce-free MACs is mathematically
false; achieving Q-time SUF-CMA requires nonce-based key derivation
(research milestone R-05).

## Design rationale

* **Functional adversary** (mirrors `Adversary` in `Crypto/Security`):
  cleaner than oracle-based; matches the ε-SU2 hypothesis precisely;
  no PMF-monad over the adversary. Faithfully models PPT adversaries
  by derandomisation: every probabilistic adversary can be
  derandomised by fixing its random tape, and the security bound
  holds for the worst-case tape.
* **Non-adaptive Q-time** (commits to all queries upfront): keeps
  the framework clean. Adaptive Q-time would require a more
  intricate PMF-tree argument.

## References

* Carter, J. L. & Wegman, M. N. (1977). "Universal classes of hash
  functions." J. Comput. Syst. Sci. 18(2): 143–154.
* Wegman, M. N. & Carter, J. L. (1981). "New hash functions and
  their use in authentication and set equality." J. Comput. Syst.
  Sci. 22: 265–279.
* Stinson, D. R. (1994). "Universal hashing and authentication
  codes." Designs, Codes and Cryptography 4(4): 369–380. (Theorem 1.)
* docs/planning/PLAN_R_01_07_08_14_16.md § R-14 — generic
  probabilistic MAC SUF-CMA framework.
-/

set_option autoImplicit false

namespace Orbcrypt

open PMF ENNReal

universe u v w

variable {K : Type u} {Msg : Type v} {Tag : Type w}

-- ============================================================================
-- Layer 1 — 1-time MAC adversary structure and forgery advantage
-- ============================================================================

/--
A **1-time MAC adversary**: given access to a single tag for a chosen
message `query`, output a forgery `(m_forge, t_forge)`. The fresh-message
constraint `m_forge ≠ query` is enforced in the `forges` predicate.

**Functional shape.** Mirrors `Adversary` from `Crypto/Security.lean`:
the adversary is a deterministic function (not a PMF / oracle
machine). Probabilistic adversaries are modelled by fixing the
random tape — the security bound holds for the worst-case tape.
-/
structure MACAdversary (K : Type u) (Msg : Type v) (Tag : Type w) where
  /-- The message the adversary chooses to query for an honest tag. -/
  query : Msg
  /-- Given the honest tag for `query`, produce a forgery candidate. -/
  forge : Tag → Msg × Tag

/--
**Forgery event** for a 1-time MAC adversary at a given key `k`.
`true` iff the adversary's forgery uses a fresh message AND the tag
verifies.

**Fields.**
* `t_honest = mac.tag k A.query` — the honest tag the adversary
  observes.
* `(m', t') = A.forge t_honest` — the adversary's forgery.
* `m' ≠ A.query` — fresh-message constraint (SUF-CMA shape).
* `mac.verify k m' t'` — the tag verifies under the (unknown to the
  adversary) key `k`.
-/
def MACAdversary.forges [DecidableEq Msg] (mac : MAC K Msg Tag)
    (A : MACAdversary K Msg Tag) (k : K) : Bool :=
  let t_honest := mac.tag k A.query
  let (m', t') := A.forge t_honest
  decide (m' ≠ A.query) && mac.verify k m' t'

/--
**1-time SUF-CMA forgery advantage.** Probability over uniformly-random
key that the adversary's fresh-message forgery verifies.

The result lives in `ℝ` (not `ℝ≥0∞`), matching the convention of
`indCPAAdvantage` and `combinerDistinguisherAdvantage`. The
conversion `(probTrue ...).toReal` is well-defined because
`probTrue ≤ 1 ≠ ⊤`.
-/
noncomputable def forgeryAdvantage [Fintype K] [Nonempty K]
    [DecidableEq Msg] (mac : MAC K Msg Tag) (A : MACAdversary K Msg Tag) : ℝ :=
  (probTrue (uniformPMF K) (A.forges mac)).toReal

/--
A MAC is **ε-SUF-CMA-secure (1-time)** iff every adversary's forgery
advantage is at most `ε`. The bound is across all 1-time adversaries;
the "1-time" qualifier refers to the adversary observing exactly one
honest tag before producing the forgery.
-/
def IsSUFCMASecure [Fintype K] [Nonempty K] [DecidableEq Msg]
    (mac : MAC K Msg Tag) (ε : ℝ) : Prop :=
  ∀ A : MACAdversary K Msg Tag, forgeryAdvantage mac A ≤ ε

/-- `forgeryAdvantage` is non-negative, since it's the `.toReal` of
    a non-negative `ℝ≥0∞` value. -/
theorem forgeryAdvantage_nonneg [Fintype K] [Nonempty K] [DecidableEq Msg]
    (mac : MAC K Msg Tag) (A : MACAdversary K Msg Tag) :
    0 ≤ forgeryAdvantage mac A :=
  ENNReal.toReal_nonneg

/-- `forgeryAdvantage ≤ 1`, since `probTrue ≤ 1` in `ℝ≥0∞` and the
    `.toReal` conversion preserves the bound. -/
theorem forgeryAdvantage_le_one [Fintype K] [Nonempty K] [DecidableEq Msg]
    (mac : MAC K Msg Tag) (A : MACAdversary K Msg Tag) :
    forgeryAdvantage mac A ≤ 1 := by
  unfold forgeryAdvantage
  -- probTrue ≤ 1, so .toReal ≤ 1.toReal = 1.
  have h_le : probTrue (uniformPMF K) (A.forges mac) ≤ 1 :=
    probTrue_le_one _ _
  have h_ne_top : probTrue (uniformPMF K) (A.forges mac) ≠ ⊤ :=
    ne_top_of_le_ne_top ENNReal.one_ne_top h_le
  have : (probTrue (uniformPMF K) (A.forges mac)).toReal ≤ (1 : ℝ≥0∞).toReal :=
    (ENNReal.toReal_le_toReal h_ne_top ENNReal.one_ne_top).mpr h_le
  simpa using this

-- ============================================================================
-- Layer 3 — Headline 1-time SUF-CMA reduction (Stinson 1994 Theorem 1)
-- ============================================================================

/--
**Headline 1-time SUF-CMA reduction (Stinson 1994 Theorem 1).** A
`deterministicTagMAC` over an `ε`-SU2 hash is `ε`-SUF-CMA-secure
(1-time): every adversary's forgery advantage is at most `ε`.

**Hypothesis is SU2, not ε-universal.** ε-universal alone is
**insufficient**: it bounds only `Pr[h k m₁ = h k m₂]` (the δ = 0
specialisation), but the SUF-CMA win event corresponds to a
*specific tag* `t' = h k m'` (the forged tag, a function of the
view), not the symmetric coincidence. ε-SU2 directly encodes the
joint bound `Pr[h k m₁ = t₁ ∧ h k m₂ = t₂] ≤ ε / |Tag|` and gives
the cleanest reduction.

**Proof structure (from the module docstring's Mathematical content
section).**
1. Express `Pr[Win]` as a sum over `t_q : Tag` of per-`t_q`
   conditional probabilities, exploiting the fact that `h k m_q`
   takes exactly one value for each `k`.
2. Per-`t_q`: case-split on whether `m'(t_q) = m_q`. The collision
   case contributes 0; the non-collision case is bounded by
   `ε / |Tag|` via SU2.
3. Sum over `|Tag|` terms: `|Tag| · (ε / |Tag|) = ε`.

The proof is implemented in cardinality space (counting over the
finite key space) for cleanest finite-arithmetic manipulation.
-/
theorem isSUFCMASecure_of_isEpsilonSU2 [Fintype K] [Nonempty K]
    [Fintype Tag] [Nonempty Tag] [DecidableEq K] [DecidableEq Msg]
    [DecidableEq Tag]
    (h : K → Msg → Tag) (ε : ℝ≥0∞) (hε_finite : ε ≠ ⊤)
    (hSU2 : IsEpsilonSU2 h ε) :
    IsSUFCMASecure (deterministicTagMAC h) ε.toReal := by
  intro A
  classical
  -- Unfold the forgery advantage to a probTrue ratio.
  unfold forgeryAdvantage
  -- Reduce A.forges (deterministicTagMAC h) to the joint-event indicator.
  -- The verify of deterministicTagMAC is `decide (t = h k m)`, so the
  -- adversary wins iff: m'(h k m_q) ≠ m_q ∧ h k (m'(h k m_q)) = t'(h k m_q).
  set m_q : Msg := A.query
  set m' : Tag → Msg := fun t => (A.forge t).1
  set t' : Tag → Tag := fun t => (A.forge t).2
  -- Step 1: Express probTrue of the forgery event in cardinality form.
  rw [probTrue_uniformPMF_card]
  -- Goal: (#filter ...).card / |K| ≤ ε.toReal
  -- We need to bound this by ε.toReal.  Compute it goes through ENNReal.
  -- Strategy: show the filter cardinality is ≤ |Tag| * (joint-event card)
  -- per t_q, then sum.
  -- For each t_q : Tag, define the "forges-at-t_q" filter.
  set forgesAtFilter : Tag → Finset K := fun t_q =>
    Finset.univ.filter (fun k : K =>
      h k m_q = t_q ∧ m' t_q ≠ m_q ∧ h k (m' t_q) = t' t_q)
  -- Step 2: The Total forgery filter equals the disjoint union over t_q.
  have h_forge_eq :
      Finset.univ.filter (fun k : K => A.forges (deterministicTagMAC h) k = true)
      = Finset.univ.biUnion forgesAtFilter := by
    ext k
    simp only [Finset.mem_filter, Finset.mem_univ, true_and,
      Finset.mem_biUnion, forgesAtFilter]
    constructor
    · -- Forward: if A wins at k, partition by t_q := h k m_q.
      intro h_wins
      -- Unfold A.forges to get the conjuncts; decide unfolding gives equalities.
      unfold MACAdversary.forges deterministicTagMAC at h_wins
      simp only [Bool.and_eq_true, decide_eq_true_eq] at h_wins
      -- After simp, h_wins is `(m' (h k m_q) ≠ m_q) ∧ (t' (h k m_q) = h k (m' (h k m_q)))`.
      obtain ⟨h_fresh, h_verify_eq⟩ := h_wins
      -- The biUnion side's existential: `∃ t_q, h k m_q = t_q ∧ m' t_q ≠ m_q ∧ h k (m' t_q) = t' t_q`.
      refine ⟨h k m_q, rfl, h_fresh, h_verify_eq.symm⟩
    · -- Backward: from forgesAtFilter we extract A.forges = true.
      rintro ⟨t_q, h_t_q_eq, h_fresh, h_verify_eq⟩
      -- h_t_q_eq : h k m_q = t_q.  Substitute t_q := h k m_q in h_fresh, h_verify_eq.
      subst h_t_q_eq
      unfold MACAdversary.forges deterministicTagMAC
      simp only [Bool.and_eq_true, decide_eq_true_eq]
      exact ⟨h_fresh, h_verify_eq.symm⟩
  -- Step 3: Express card(biUnion) as sum of card(per-tᵩ).
  -- The biUnion is disjoint because each k has a unique t_q := h k m_q.
  have h_disj :
      ∀ s ∈ (Finset.univ : Finset Tag), ∀ t ∈ (Finset.univ : Finset Tag),
        s ≠ t → Disjoint (forgesAtFilter s) (forgesAtFilter t) := by
    intro s _ t _ h_ne
    simp only [Finset.disjoint_left, Finset.mem_filter, Finset.mem_univ,
      true_and, forgesAtFilter]
    rintro k ⟨h_s, _⟩ ⟨h_t, _⟩
    exact h_ne (h_s.symm.trans h_t)
  -- Step 4: Bound each card(forgesAtFilter t_q) ≤ joint-collision-card.
  -- joint-collision is `h k m_q = t_q ∧ h k (m' t_q) = t' t_q` (no fresh-msg).
  -- forgesAtFilter ⊆ joint-collision-filter (drop the fresh-msg constraint).
  have h_per_t :
      ∀ t_q : Tag, ((forgesAtFilter t_q).card : ℝ≥0∞) ≤
        ε / (Fintype.card Tag : ℝ≥0∞) * (Fintype.card K : ℝ≥0∞) := by
    intro t_q
    by_cases h_eq : m' t_q = m_q
    · -- Collision case: forgesAtFilter is empty.
      have h_empty : forgesAtFilter t_q = ∅ := by
        rw [Finset.eq_empty_iff_forall_notMem]
        intro k hk
        simp only [Finset.mem_filter, Finset.mem_univ, true_and,
          forgesAtFilter] at hk
        exact hk.2.1 h_eq
      rw [h_empty, Finset.card_empty]
      simp
    · -- Non-collision case: apply SU2 at (m_q, m' t_q) with tags (t_q, t' t_q).
      -- forgesAtFilter t_q ⊆ joint-collision-filter, so card-monotone applies.
      have h_subset :
          forgesAtFilter t_q ⊆ Finset.univ.filter (fun k : K =>
            h k m_q = t_q ∧ h k (m' t_q) = t' t_q) := by
        intro k hk
        simp only [Finset.mem_filter, Finset.mem_univ, true_and,
          forgesAtFilter] at hk
        simp only [Finset.mem_filter, Finset.mem_univ, true_and]
        exact ⟨hk.1, hk.2.2⟩
      have h_card_le := Finset.card_le_card h_subset
      -- SU2 bound on the joint-collision-card.
      have hSU2_t := hSU2 m_q (m' t_q) t_q (t' t_q) (Ne.symm h_eq)
      rw [probTrue_uniformPMF_decide_eq] at hSU2_t
      -- hSU2_t : (joint-card : ℝ≥0∞) / |K| ≤ ε / |Tag|.
      -- Multiply both sides by |K|: joint-card ≤ ε / |Tag| * |K|.
      have h_card_pos : 0 < Fintype.card K := Fintype.card_pos
      have h_card_ne_zero : (Fintype.card K : ℝ≥0∞) ≠ 0 := by
        exact_mod_cast h_card_pos.ne'
      have h_card_ne_top : (Fintype.card K : ℝ≥0∞) ≠ ⊤ := ENNReal.natCast_ne_top _
      have h_joint_le :
          ((Finset.univ.filter (fun k : K =>
              h k m_q = t_q ∧ h k (m' t_q) = t' t_q)).card : ℝ≥0∞) ≤
          ε / (Fintype.card Tag : ℝ≥0∞) * (Fintype.card K : ℝ≥0∞) := by
        have := (ENNReal.div_le_iff h_card_ne_zero h_card_ne_top).mp hSU2_t
        exact this
      calc ((forgesAtFilter t_q).card : ℝ≥0∞)
          ≤ ((Finset.univ.filter (fun k : K =>
              h k m_q = t_q ∧ h k (m' t_q) = t' t_q)).card : ℝ≥0∞) := by
            exact_mod_cast h_card_le
        _ ≤ ε / (Fintype.card Tag : ℝ≥0∞) * (Fintype.card K : ℝ≥0∞) := h_joint_le
  -- Step 5: Sum the per-tᵩ bound over all t_q ∈ Tag.
  have h_sum_le :
      ∑ t_q : Tag, ((forgesAtFilter t_q).card : ℝ≥0∞) ≤
      (Fintype.card Tag : ℝ≥0∞) *
        (ε / (Fintype.card Tag : ℝ≥0∞) * (Fintype.card K : ℝ≥0∞)) := by
    have h_sum := Finset.sum_le_sum (fun t_q (_ : t_q ∈ Finset.univ) => h_per_t t_q)
    rw [Finset.sum_const, Finset.card_univ] at h_sum
    -- Convert ℕ-smul to ENNReal-mul.
    have h_nsmul_eq_mul :
        ∀ (n : ℕ) (c : ℝ≥0∞), n • c = (n : ℝ≥0∞) * c := by
      intro n c
      induction n with
      | zero => simp
      | succ k ih => rw [succ_nsmul, ih, Nat.cast_succ, add_mul, one_mul]
    rw [h_nsmul_eq_mul] at h_sum
    exact h_sum
  -- Step 6: |Tag| * (ε / |Tag| * |K|) = ε * |K|.
  have h_tag_pos : 0 < Fintype.card Tag := Fintype.card_pos
  have h_tag_ne_zero : (Fintype.card Tag : ℝ≥0∞) ≠ 0 := by
    exact_mod_cast h_tag_pos.ne'
  have h_tag_ne_top : (Fintype.card Tag : ℝ≥0∞) ≠ ⊤ := ENNReal.natCast_ne_top _
  have h_simp :
      (Fintype.card Tag : ℝ≥0∞) *
        (ε / (Fintype.card Tag : ℝ≥0∞) * (Fintype.card K : ℝ≥0∞)) =
      ε * (Fintype.card K : ℝ≥0∞) := by
    rw [← mul_assoc, ENNReal.mul_div_cancel h_tag_ne_zero h_tag_ne_top]
  rw [h_simp] at h_sum_le
  -- Step 7: Convert to ℝ.toReal at the headline.
  -- h_sum_le : (∑ t_q, card t_q : ℝ≥0∞) ≤ ε * |K|.
  -- Divide both sides by |K| via div_le_iff.
  have h_card_pos : 0 < Fintype.card K := Fintype.card_pos
  have h_card_ne_zero : (Fintype.card K : ℝ≥0∞) ≠ 0 := by
    exact_mod_cast h_card_pos.ne'
  have h_card_ne_top : (Fintype.card K : ℝ≥0∞) ≠ ⊤ := ENNReal.natCast_ne_top _
  -- We need to show: (#filter ... = true).card / |K| ≤ ε.toReal
  -- where #filter is the original A.forges-true filter.
  -- Combine: card(filter) = card(biUnion) = ∑ card(per_t) (via h_forge_eq + Finset.card_biUnion).
  have h_card_filter_eq :
      (Finset.univ.filter (fun k : K =>
          A.forges (deterministicTagMAC h) k = true)).card =
      ∑ t_q : Tag, (forgesAtFilter t_q).card := by
    rw [h_forge_eq, Finset.card_biUnion h_disj]
  -- Apply this rewrite to the goal's LHS.
  rw [h_card_filter_eq]
  -- Goal: (∑ t_q, card_t_q : ℝ≥0∞) / |K| ≤ ε.toReal
  -- We have h_sum_le : (∑ t_q, card_t_q : ℝ≥0∞) ≤ ε * |K|.  Divide both sides
  -- by |K| in ENNReal, then convert to ℝ.
  have h_ennreal_bound :
      (∑ t_q : Tag, ((forgesAtFilter t_q).card : ℝ≥0∞)) /
        (Fintype.card K : ℝ≥0∞) ≤ ε := by
    rw [ENNReal.div_le_iff h_card_ne_zero h_card_ne_top]
    exact h_sum_le
  -- Convert to ℝ via .toReal. The LHS is at most ε which is finite.
  have h_lhs_ne_top :
      (∑ t_q : Tag, ((forgesAtFilter t_q).card : ℝ≥0∞)) /
        (Fintype.card K : ℝ≥0∞) ≠ ⊤ :=
    ne_top_of_le_ne_top hε_finite h_ennreal_bound
  have h_real_bound :
      ((∑ t_q : Tag, ((forgesAtFilter t_q).card : ℝ≥0∞)) /
          (Fintype.card K : ℝ≥0∞)).toReal ≤ ε.toReal :=
    (ENNReal.toReal_le_toReal h_lhs_ne_top hε_finite).mpr h_ennreal_bound
  -- The goal LHS uses `((sum-of-card : ℕ) : ℝ≥0∞)` with the natCast wrapping the
  -- whole sum, while h_real_bound uses the sum-of-natCasts form. Equate them.
  have h_sum_cast_eq :
      ((∑ t_q : Tag, (forgesAtFilter t_q).card : ℕ) : ℝ≥0∞) =
      ∑ t_q : Tag, ((forgesAtFilter t_q).card : ℝ≥0∞) := by
    push_cast; rfl
  rw [h_sum_cast_eq]
  exact h_real_bound

-- ============================================================================
-- Layer 2 — Q-time (multi-query) MAC adversary structure
-- ============================================================================

/--
A **Q-time MAC adversary** (non-adaptive): pre-commits to `Q` queries
upfront, observes the `Q` honest tags, then produces a forgery `(m', t')`.
The fresh-message constraint is `m' ∉ Set.range queries`.

**Non-adaptive choice.** The adversary commits to all `Q` queries
*before* observing any tag. This keeps the framework clean: an
adaptive Q-time adversary would require iterated PMF binds. The
non-adaptive form is sufficient for the negative theorem (the
key-recovery attack does not benefit from adaptivity) and matches
the standard textbook formulation of multi-query SUF-CMA against
deterministic MACs.
-/
structure MultiQueryMACAdversary (K : Type u) (Msg : Type v) (Tag : Type w)
    (Q : ℕ) where
  /-- The `Q` chosen messages. -/
  queries : Fin Q → Msg
  /-- Given the `Q` honest tags, produce a forgery `(m', t')`. -/
  forge : (Fin Q → Tag) → Msg × Tag

/--
**Forgery event** for a Q-time non-adaptive adversary at a given key
`k`. `true` iff the forgery uses a fresh message (not any of the
queries) AND the tag verifies.
-/
def MultiQueryMACAdversary.forges [DecidableEq Msg]
    {Q : ℕ} (mac : MAC K Msg Tag)
    (A : MultiQueryMACAdversary K Msg Tag Q) (k : K) : Bool :=
  let tags := fun i => mac.tag k (A.queries i)
  let (m', t') := A.forge tags
  decide (∀ i : Fin Q, m' ≠ A.queries i) && mac.verify k m' t'

/--
**Q-time SUF-CMA forgery advantage.** Probability over uniformly-random
key that the Q-time adversary's fresh-message forgery verifies.
-/
noncomputable def forgeryAdvantage_Qtime [Fintype K] [Nonempty K]
    [DecidableEq Msg] {Q : ℕ} (mac : MAC K Msg Tag)
    (A : MultiQueryMACAdversary K Msg Tag Q) : ℝ :=
  (probTrue (uniformPMF K) (A.forges mac)).toReal

/--
A MAC is **ε-Q-time-SUF-CMA-secure** iff every Q-time non-adaptive
adversary has forgery advantage at most `ε`.

**Vacuity at small message spaces.** When `|Msg| ≤ Q`, the fresh-
message constraint `∀ i, m' ≠ queries i` forces `queries` non-
injective in the typical case (or impossible); the predicate is
`false` and the security holds vacuously at any `ε ≥ 0`. For
meaningful Q-time analysis, callers pick `Q < |Msg|`.
-/
def IsQtimeSUFCMASecure [Fintype K] [Nonempty K] [DecidableEq Msg]
    {Q : ℕ} (mac : MAC K Msg Tag) (ε : ℝ) : Prop :=
  ∀ A : MultiQueryMACAdversary K Msg Tag Q, forgeryAdvantage_Qtime mac A ≤ ε

/-- `forgeryAdvantage_Qtime ≥ 0`. Direct from `ENNReal.toReal_nonneg`. -/
theorem forgeryAdvantage_Qtime_nonneg [Fintype K] [Nonempty K] [DecidableEq Msg]
    {Q : ℕ} (mac : MAC K Msg Tag) (A : MultiQueryMACAdversary K Msg Tag Q) :
    0 ≤ forgeryAdvantage_Qtime mac A :=
  ENNReal.toReal_nonneg

/-- `forgeryAdvantage_Qtime ≤ 1`. Same proof as 1-time. -/
theorem forgeryAdvantage_Qtime_le_one [Fintype K] [Nonempty K] [DecidableEq Msg]
    {Q : ℕ} (mac : MAC K Msg Tag) (A : MultiQueryMACAdversary K Msg Tag Q) :
    forgeryAdvantage_Qtime mac A ≤ 1 := by
  unfold forgeryAdvantage_Qtime
  have h_le : probTrue (uniformPMF K) (A.forges mac) ≤ 1 :=
    probTrue_le_one _ _
  have h_ne_top : probTrue (uniformPMF K) (A.forges mac) ≠ ⊤ :=
    ne_top_of_le_ne_top ENNReal.one_ne_top h_le
  have : (probTrue (uniformPMF K) (A.forges mac)).toReal ≤ (1 : ℝ≥0∞).toReal :=
    (ENNReal.toReal_le_toReal h_ne_top ENNReal.one_ne_top).mpr h_le
  simpa using this

-- ============================================================================
-- Layer 4 — Q-time NEGATIVE result for key-recoverable hash families
-- ============================================================================

/--
**Key-recoverable from some Q-tuple of queries** (existential
predicate). The hash family `h` is key-recoverable from `Q` queries
iff there exists a specific injective `Q`-tuple of messages and a
recovery function such that, for *every* key `k`, the recovery
function applied to the honest tags at those messages returns
`some k`.

**Existential, not universal.** The predicate uses `∃ msgs` (not
`∀ msgs`) because for some hash families (e.g.,
`bitstringPolynomialHash`), unique key-recovery succeeds only at
*specific* message choices — the universal-over-msgs form is overly
restrictive and would fail for some valid recovery instances. The
existential form is sufficient for the negative theorem: as long
as ONE recovery-friendly message-tuple exists, the adversary can
use it.

**Cryptographic content.** This is the witness predicate for the
Q-time NEGATIVE result `not_isQtimeSUFCMASecure_of_keyRecoverable
ForSomeQueries`. For Carter–Wegman with `Q = 2`, the recovery
solves the 2×2 linear system; for bitstring-polynomial with `Q = 2`,
the recovery solves the polynomial-evaluation system at
sufficiently-distinct bitstrings.
-/
def IsKeyRecoverableForSomeQueries [Fintype K] [Nonempty K]
    [DecidableEq Msg] [DecidableEq Tag]
    (h : K → Msg → Tag) (queries : ℕ) : Prop :=
  ∃ (msgs : Fin queries → Msg) (recover : (Fin queries → Tag) → Option K),
    Function.Injective msgs ∧
    ∀ k : K, recover (fun i => h k (msgs i)) = some k

/--
**Headline Q-time NEGATIVE result.** When the hash family is key-
recoverable from a specific `Q`-tuple of queries, the corresponding
`deterministicTagMAC` is **not** `ε`-(Q+1)-time-SUF-CMA-secure for
any `ε < 1`. An explicit adversary achieves forgery advantage `1`
(the deterministic recovery + forge always wins).

**Adversary construction.** Given `(msgs, recover)` from the
hypothesis, the (Q+1)-time adversary:
1. Submits the `Q` queries `msgs : Fin Q → Msg` (extends to `Fin
   (Q+1)` by appending an extra message; the extra slot is irrelevant
   to recovery but needed to satisfy the type-level `Q+1` count).
2. Receives `Q+1` honest tags `tags`.
3. Recovers the key `k_recovered := (recover (tags ∘ Fin.castLE)).get`
   via the hypothesis (which guarantees `recover ... = some k`).
4. Picks any fresh message `m'` not in `Set.range queries` (exists
   when `|Msg| > Q+1`, the standard case).
5. Computes the deterministic forgery `t' := h k_recovered m'`.
6. Submits `(m', t')`. Since `k_recovered = k`, this verifies.

**Required cardinality.** `Fintype.card Msg > Q + 1` is needed for
step (4) to find a fresh `m'`. For `ZMod p` with `p ≥ 4` and
`Q = 2` this is automatic.
-/
theorem not_isQtimeSUFCMASecure_of_keyRecoverableForSomeQueries
    [Fintype K] [Nonempty K] [Fintype Msg] [DecidableEq K]
    [DecidableEq Msg] [DecidableEq Tag]
    {Q : ℕ}
    (h : K → Msg → Tag)
    (hQ_lt_card : Q + 1 < Fintype.card Msg)
    (hRecover : IsKeyRecoverableForSomeQueries h Q)
    (ε : ℝ) (hε : ε < 1) :
    ¬ IsQtimeSUFCMASecure (Q := Q + 1) (deterministicTagMAC h) ε := by
  -- Extract recovery witness.
  obtain ⟨msgs, recover, h_inj, h_recover_eq⟩ := hRecover
  -- Find TWO distinct fresh messages m_pad, m_target ∉ Set.range msgs.
  -- This is possible because |Msg| > Q + 1 = |range msgs| + 2 (when Q+1 ≤ |Msg|−1).
  -- Specifically: range msgs has Q distinct elements; we need at least 2 fresh.
  -- |Msg| > Q + 1 ≥ Q + 2 − 1, so |Msg| − Q ≥ 2, giving at least 2 fresh messages.
  have h_range_card : (Finset.univ.image msgs).card = Q := by
    rw [Finset.card_image_of_injective _ h_inj, Finset.card_univ, Fintype.card_fin]
  -- Fresh-message complement has card = |Msg| - Q ≥ 2.
  have h_compl_card :
      (Finset.univ \ Finset.univ.image msgs).card ≥ 2 := by
    rw [Finset.card_sdiff_of_subset (Finset.subset_univ _),
        Finset.card_univ, h_range_card]
    omega
  -- Pick two distinct fresh messages from the complement.
  have h_compl_two_le_card :
      2 ≤ (Finset.univ \ Finset.univ.image msgs).card := h_compl_card
  -- Pick m_pad first.
  obtain ⟨m_pad, h_m_pad_in⟩ : ∃ m_pad,
      m_pad ∈ Finset.univ \ Finset.univ.image msgs := by
    have h_nonempty : (Finset.univ \ Finset.univ.image msgs).Nonempty :=
      Finset.card_pos.mp (by omega)
    exact h_nonempty
  -- After choosing m_pad, the remaining complement still has ≥ 1 element.
  have h_remaining_pos :
      0 < ((Finset.univ \ Finset.univ.image msgs).erase m_pad).card := by
    rw [Finset.card_erase_of_mem h_m_pad_in]
    omega
  obtain ⟨m_target, h_m_target_in⟩ : ∃ m_target,
      m_target ∈ (Finset.univ \ Finset.univ.image msgs).erase m_pad :=
    Finset.card_pos.mp h_remaining_pos
  -- Extract the properties of m_pad and m_target via the membership rewrites.
  rw [Finset.mem_sdiff] at h_m_pad_in
  have h_m_pad_fresh : m_pad ∉ Finset.univ.image msgs := h_m_pad_in.2
  rw [Finset.mem_erase, Finset.mem_sdiff] at h_m_target_in
  have h_m_target_ne_pad : m_target ≠ m_pad := h_m_target_in.1
  have h_m_target_fresh : m_target ∉ Finset.univ.image msgs := h_m_target_in.2.2
  -- Translate "fresh" to "≠ msgs j for every j".
  have h_pad_ne_msgs : ∀ j : Fin Q, m_pad ≠ msgs j := by
    intro j h_eq
    apply h_m_pad_fresh
    rw [h_eq]
    exact Finset.mem_image_of_mem _ (Finset.mem_univ j)
  have h_target_ne_msgs : ∀ j : Fin Q, m_target ≠ msgs j := by
    intro j h_eq
    apply h_m_target_fresh
    rw [h_eq]
    exact Finset.mem_image_of_mem _ (Finset.mem_univ j)
  -- The (Q+1)-time adversary: queries are `extendedQueries`, the
  -- recovery is `extendedRecover`, the forge is `extendedForge`.
  -- All defined as ordinary functions (no `let` body) so they expand
  -- transparently via `show`.
  -- Define extendedQueries: Fin Q ⊆ Fin (Q+1) via Fin.castSucc, last slot = m_pad.
  set extendedQueries : Fin (Q + 1) → Msg := fun i =>
    if h_lt : i.val < Q then msgs ⟨i.val, h_lt⟩ else m_pad with hexq
  -- Recovery extended to Fin (Q+1) tags: drop the last slot.
  set extendedRecover : (Fin (Q + 1) → Tag) → Option K := fun tags =>
    recover (fun i : Fin Q => tags ⟨i.val, by omega⟩) with hexr
  -- Forge: recover the key, then forge on m_target.
  set extendedForge : (Fin (Q + 1) → Tag) → Msg × Tag := fun tags =>
    match extendedRecover tags with
    | some k => (m_target, h k m_target)
    | none => (m_target, tags 0) with hexf
  let A : MultiQueryMACAdversary K Msg Tag (Q + 1) :=
    { queries := extendedQueries, forge := extendedForge }
  -- Compute extendedQueries on the first Q indices: equals msgs.
  have h_eq_msgs : ∀ i : Fin Q,
      extendedQueries ⟨i.val, by omega⟩ = msgs i := by
    intro i
    show (if h_lt : i.val < Q then msgs ⟨i.val, h_lt⟩ else m_pad) = msgs i
    simp only [i.isLt, dif_pos]
  -- Show A always wins: A.forges (deterministicTagMAC h) k = true for every k.
  have h_always_wins :
      ∀ k : K, A.forges (deterministicTagMAC h) k = true := by
    intro k
    -- Step 1: extendedRecover(honest tags) = some k.
    have h_recover_at_k :
        extendedRecover (fun j : Fin (Q + 1) => h k (extendedQueries j))
          = some k := by
      show recover (fun i : Fin Q =>
              h k (extendedQueries ⟨i.val, by omega⟩)) = some k
      have h_q' :
          (fun i : Fin Q => h k (extendedQueries ⟨i.val, by omega⟩)) =
          (fun i : Fin Q => h k (msgs i)) := by
        funext i
        congr 1
        exact h_eq_msgs i
      rw [h_q']
      exact h_recover_eq k
    -- Step 2: extendedForge (honest tags) = (m_target, h k m_target).
    have h_forge_eq :
        extendedForge (fun j : Fin (Q + 1) => h k (extendedQueries j))
          = (m_target, h k m_target) := by
      show (match extendedRecover
              (fun j : Fin (Q + 1) => h k (extendedQueries j)) with
            | some k' => (m_target, h k' m_target)
            | none => (m_target, _)) = (m_target, h k m_target)
      rw [h_recover_at_k]
    -- Step 3: A.forges = decide (fresh) && verify.
    show (decide (∀ i : Fin (Q + 1),
            (extendedForge fun j => h k (extendedQueries j)).1 ≠
              extendedQueries i)
            && (deterministicTagMAC h).verify k
              (extendedForge fun j => h k (extendedQueries j)).1
              (extendedForge fun j => h k (extendedQueries j)).2) = true
    rw [h_forge_eq]
    simp only [Bool.and_eq_true, decide_eq_true_eq]
    refine ⟨?_, ?_⟩
    · -- Fresh-message: m_target ≠ extendedQueries i for every i.
      intro i
      show m_target ≠ if h_lt : i.val < Q then msgs ⟨i.val, h_lt⟩ else m_pad
      by_cases h_lt : i.val < Q
      · simp only [h_lt, dif_pos]
        exact h_target_ne_msgs ⟨i.val, h_lt⟩
      · simp only [h_lt, dif_neg, not_false_iff]
        exact h_m_target_ne_pad
    · -- Verify: tag verifies under k.
      show (deterministicTagMAC h).verify k m_target (h k m_target) = true
      unfold deterministicTagMAC
      simp
  -- From h_always_wins, conclude forgeryAdvantage_Qtime A = 1.
  have h_adv_eq_one : forgeryAdvantage_Qtime (deterministicTagMAC h) A = 1 := by
    unfold forgeryAdvantage_Qtime
    -- The probTrue equals 1 because the predicate is constantly true.
    have h_predicate_const :
        (A.forges (deterministicTagMAC h)) = (fun _ : K => true) := by
      funext k
      exact h_always_wins k
    rw [h_predicate_const]
    -- probTrue (uniformPMF K) (constantly true) = 1.
    rw [probTrue_uniformPMF_card]
    -- After rewrite: ((filter (fun k => true)).card : ℝ≥0∞).toReal / |K|.toReal
    -- The filter is Finset.univ; cardinality = |K|.
    have h_filter_eq :
        Finset.univ.filter (fun k : K => (fun _ : K => true) k = true)
        = Finset.univ := by
      apply Finset.filter_true_of_mem
      intro _ _
      rfl
    rw [h_filter_eq, Finset.card_univ]
    -- Goal: (|K| : ℝ≥0∞) / |K| = 1 in ENNReal, then .toReal = 1.
    have h_card_pos : 0 < Fintype.card K := Fintype.card_pos
    have h_card_ne_zero : (Fintype.card K : ℝ≥0∞) ≠ 0 := by
      exact_mod_cast h_card_pos.ne'
    have h_card_ne_top : (Fintype.card K : ℝ≥0∞) ≠ ⊤ :=
      ENNReal.natCast_ne_top _
    rw [ENNReal.div_self h_card_ne_zero h_card_ne_top]
    exact ENNReal.toReal_one
  -- Use h_adv_eq_one to contradict IsQtimeSUFCMASecure mac ε with ε < 1.
  intro h_secure
  have h_le := h_secure A
  rw [h_adv_eq_one] at h_le
  linarith

end Orbcrypt
