/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Mathlib.Data.Finset.Card
import Mathlib.Probability.Distributions.Uniform
import Orbcrypt.Probability.Monad

/-!
# Orbcrypt.Probability.UniversalHash

Universal hash families (Carter–Wegman 1977): a ε-universal hash family
is one where for any two distinct messages, the probability that a
uniformly random key produces a collision is bounded by ε.

Universal hash families are the information-theoretic foundation of
unconditionally secure Wegman–Carter authentication (1981). A MAC
built from an ε-universal family with uniformly random keys has
per-query forgery probability ≤ ε against a computationally unbounded
adversary (no query phase) — this is the strongest possible security
guarantee.

## Main definitions

* `Orbcrypt.IsEpsilonUniversal` — ε-universal hash family as a Prop.
* `Orbcrypt.IsEpsilonAXU` — ε-almost-XOR-universal: a strictly
  stronger property bounding the joint difference probability for
  every output difference δ. Required for the Q-time Wegman–Carter
  SUF-CMA reduction.
* `Orbcrypt.IsEpsilonSU2` — ε-strongly-universal-2: for every two
  distinct messages and every (t₁, t₂) tag pair, the joint
  probability is at most ε / |Tag|. The "right" hypothesis for the
  one-time SUF-CMA reduction. Strictly stronger than both
  `IsEpsilonUniversal` and `IsEpsilonAXU`.
* `Orbcrypt.probTrue_uniformPMF_decide_eq` — helper: `probTrue` under
  `uniformPMF` on a decidable predicate equals the cardinality of the
  satisfying filter divided by the keyspace cardinality.

## Main results

* `Orbcrypt.IsEpsilonUniversal.mono` — monotonicity in ε.
* `Orbcrypt.IsEpsilonUniversal.ofCollisionCardBound` — sufficient
  cardinality bound: if the collision-set cardinality is bounded by
  `C`, the family is `C/|K|`-universal.
* `Orbcrypt.IsEpsilonAXU.mono` — monotonicity in ε.
* `Orbcrypt.IsEpsilonAXU.toIsEpsilonUniversal` — AXU specialises to
  universal at `δ = 0`.
* `Orbcrypt.IsEpsilonAXU.ofCollisionCardBound` — sufficient
  cardinality bound parallel to the universal version.
* `Orbcrypt.IsEpsilonSU2.mono` — monotonicity in ε.
* `Orbcrypt.IsEpsilonSU2.ofJointCollisionCardBound` — sufficient
  cardinality bound: if the joint-collision cardinality is bounded
  uniformly by `C` over all `(t₁, t₂)` tag pairs, the family is
  `(C * |Tag| / |K|)`-SU2.
* `Orbcrypt.IsEpsilonSU2.toIsEpsilonUniversal` — SU2 implies
  universal (the δ = 0 specialisation in joint-tag form).
* `Orbcrypt.IsEpsilonSU2.toIsEpsilonAXU` — SU2 implies AXU when
  `Tag` carries an additive group structure.

## Scope

This module formalizes the **ε-universality**, **ε-AXU**, and
**ε-SU2** properties. The Wegman–Carter MAC security reduction from
ε-SU2 to one-time SUF-CMA lives in `Orbcrypt/AEAD/MACSecurity.lean`
(Workstream R-14). The canonical instance `carterWegmanHash_isUniversal`
in `Orbcrypt/AEAD/CarterWegmanMAC.lean` produces `(1/p)`-universality
from primality; the SU2 strengthening
`carterWegmanHash_isEpsilonSU2` (R-08) uses the same primality
hypothesis and slot into the SUF-CMA reduction directly.

## References

* Carter, J. L. & Wegman, M. N. (1977). "Universal classes of hash
  functions." J. Comput. Syst. Sci. 18(2): 143–154.
* Wegman, M. N. & Carter, J. L. (1981). "New hash functions and their
  use in authentication and set equality." J. Comput. Syst. Sci. 22:
  265–279.
* Stinson, D. R. (1994). "Universal hashing and authentication codes."
  Designs, Codes and Cryptography 4(4): 369–380. (Theorem 1: the
  one-time SUF-CMA reduction from ε-SU2.)
* docs/dev_history/PLAN_R_01_07_08_14_16.md § R-14 — generic
  probabilistic MAC SUF-CMA framework (R-14 introduces the SU2 and
  AXU predicates here; R-08 + R-13⁺ instantiate them at concrete
  hash families).
-/

set_option autoImplicit false

namespace Orbcrypt

open PMF ENNReal

universe u v w

variable {K : Type u} {Msg : Type v} {Tag : Type w}

-- ============================================================================
-- The ε-universal hash property
-- ============================================================================

/--
An ε-universal hash family over a finite nonempty key space `K`: for
any two distinct messages, the probability that a uniformly-random key
produces a collision is at most ε.

**Formal definition.**
  `∀ m₁ m₂ : Msg, m₁ ≠ m₂ →
     probTrue (uniformPMF K) (fun k => decide (h k m₁ = h k m₂)) ≤ ε`

**Canonical instance.** The Carter–Wegman linear hash family
`h (k₁,k₂) m = k₁ · m + k₂` over the prime field `ZMod p` is
`(1/p)`-universal (see `carterWegmanHash_isUniversal` in
`Orbcrypt/AEAD/CarterWegmanMAC.lean`).

**Scope.** This Prop is the *per-pair collision bound*. Constructing an
unconditionally-secure MAC from an ε-universal family additionally
requires a separate reduction — Wegman–Carter 1981 — which relates
per-pair collision probability to per-query forgery probability. That
reduction is future work; this Prop captures the information-theoretic
primitive itself.
-/
def IsEpsilonUniversal [Fintype K] [Nonempty K] [DecidableEq Tag]
    (h : K → Msg → Tag) (ε : ℝ≥0∞) : Prop :=
  ∀ m₁ m₂ : Msg, m₁ ≠ m₂ →
    probTrue (uniformPMF K) (fun k => decide (h k m₁ = h k m₂)) ≤ ε

/--
Monotonicity: if `h` is ε₁-universal and ε₁ ≤ ε₂, then `h` is
ε₂-universal. A weaker bound is always implied by a tighter one.
-/
theorem IsEpsilonUniversal.mono [Fintype K] [Nonempty K] [DecidableEq Tag]
    {h : K → Msg → Tag} {ε₁ ε₂ : ℝ≥0∞}
    (hle : ε₁ ≤ ε₂) (hu : IsEpsilonUniversal h ε₁) :
    IsEpsilonUniversal h ε₂ :=
  fun m₁ m₂ h_ne => (hu m₁ m₂ h_ne).trans hle

/--
Every hash family is trivially `1`-universal (probability is always
bounded by 1). This is a satisfiability anchor, not a meaningful
security claim — the content is in `ε < 1`.
-/
theorem IsEpsilonUniversal.le_one [Fintype K] [Nonempty K] [DecidableEq Tag]
    (h : K → Msg → Tag) : IsEpsilonUniversal h 1 :=
  fun _ _ _ => probTrue_le_one _ _

-- ============================================================================
-- Counting lemma: `probTrue` under `uniformPMF` = #filter / card
-- ============================================================================

/--
`probTrue` of a decidable predicate under `uniformPMF K` equals the
cardinality of the satisfying filter over the keyspace cardinality.

This is the counting form of the uniform-distribution probability:
`Pr_{k ∼ U(K)}[P(k)] = |{k : P(k)}| / |K|`. It reduces universal-hash
proofs to pure cardinality arguments (how many keys produce a
collision?), which is the classical counting form Carter & Wegman 1977
used.
-/
theorem probTrue_uniformPMF_decide_eq {α : Type*} [Fintype α] [Nonempty α]
    (P : α → Prop) [DecidablePred P] :
    probTrue (uniformPMF α) (fun x => decide (P x))
    = ((Finset.univ.filter P).card : ℝ≥0∞) / (Fintype.card α : ℝ≥0∞) := by
  classical
  unfold probTrue uniformPMF
  -- Simplify `{x | decide (P x) = true}` to `{x | P x}` as a Set.
  have hset :
      {x : α | (fun x => decide (P x)) x = true} = {x : α | P x} := by
    ext x
    simp
  rw [hset]
  -- `toOuterMeasure_uniformOfFintype_apply` gives the `Fintype.card` form
  -- for uniform distributions on Fintypes.
  rw [PMF.toOuterMeasure_uniformOfFintype_apply]
  -- Convert `Fintype.card ↥{x | P x}` (subtype cardinality) to the
  -- Finset.filter cardinality via `Fintype.card_subtype`.
  congr 1
  · exact_mod_cast Fintype.card_subtype P

/--
**Sufficient cardinality bound.** If every pair of distinct messages
admits at most `C` colliding keys, the family is `(C / |K|)`-universal.

This is the standard counting-form statement that universal-hash
proofs (including the Carter–Wegman linear hash) discharge by
bounding the collision-set size.
-/
theorem IsEpsilonUniversal.ofCollisionCardBound [Fintype K] [Nonempty K]
    [DecidableEq Tag]
    (h : K → Msg → Tag) (C : ℕ)
    (hCard : ∀ m₁ m₂ : Msg, m₁ ≠ m₂ →
      (Finset.univ.filter
        (fun k : K => h k m₁ = h k m₂)).card ≤ C) :
    IsEpsilonUniversal h ((C : ℝ≥0∞) / (Fintype.card K : ℝ≥0∞)) := by
  intro m₁ m₂ h_ne
  classical
  rw [probTrue_uniformPMF_decide_eq]
  -- Goal: (#filter collisions) / |K| ≤ C / |K|
  -- Numerator is ≤ C (by hCard); denominator is the same.
  exact ENNReal.div_le_div_right (Nat.cast_le.mpr (hCard m₁ m₂ h_ne)) _

-- ============================================================================
-- ε-almost-XOR-universal (ε-AXU)
-- ============================================================================

/--
A hash family `h : K → Msg → Tag` is **ε-almost-XOR-universal** (ε-AXU)
iff for every two distinct messages `m₁ ≠ m₂` and every output difference
`δ : Tag`, the probability over uniform `k` that `h k m₁ - h k m₂ = δ`
is at most ε.

**Relation to ε-universal.** AXU specialises to universal at `δ = 0`:
`h k m₁ - h k m₂ = 0 ↔ h k m₁ = h k m₂` (when `Tag` carries an
`AddGroup` structure). So `IsEpsilonAXU h ε → IsEpsilonUniversal h ε`.

**Cryptographic significance.** AXU is the standard hypothesis for
nonce-based Wegman–Carter MAC constructions: a fresh nonce per message
randomises the offset, and AXU bounds the per-query forgery
probability without requiring the joint-distribution control of SU2.

**Hypothesis sufficient for Q-time SUF-CMA?** No. AXU controls the
output-difference distribution but not the joint marginal. For nonce-
free MACs (the in-tree `carterWegmanMAC` / `bitstringPolynomialMAC`),
AXU does **not** imply Q-time SUF-CMA — see
`docs/dev_history/PLAN_R_01_07_08_14_16.md` § R-14 for the linear-system
key-recovery counterexample at Q ≥ 2 queries.
-/
def IsEpsilonAXU [Fintype K] [Nonempty K] [DecidableEq Tag]
    [SubtractionMonoid Tag] (h : K → Msg → Tag) (ε : ℝ≥0∞) : Prop :=
  ∀ (m₁ m₂ : Msg) (δ : Tag), m₁ ≠ m₂ →
    probTrue (uniformPMF K) (fun k => decide (h k m₁ - h k m₂ = δ)) ≤ ε

/--
Monotonicity for AXU: if `h` is ε₁-AXU and ε₁ ≤ ε₂, then `h` is ε₂-AXU.
-/
theorem IsEpsilonAXU.mono [Fintype K] [Nonempty K] [DecidableEq Tag]
    [SubtractionMonoid Tag]
    {h : K → Msg → Tag} {ε₁ ε₂ : ℝ≥0∞}
    (hle : ε₁ ≤ ε₂) (hAXU : IsEpsilonAXU h ε₁) :
    IsEpsilonAXU h ε₂ :=
  fun m₁ m₂ δ h_ne => (hAXU m₁ m₂ δ h_ne).trans hle

/--
**AXU implies ε-universal.** AXU is the `δ = 0` specialisation of
universal once `Tag` has additive-group structure: `h k m₁ - h k m₂ = 0`
in an `AddGroup` is equivalent to `h k m₁ = h k m₂` via `sub_eq_zero`.

(The base `IsEpsilonAXU` predicate only requires `SubtractionMonoid`
to express the difference, but the `↔ h k m₁ = h k m₂` round-trip
needs the full `AddGroup` cancellation property of `sub_eq_zero`.)
-/
theorem IsEpsilonAXU.toIsEpsilonUniversal [Fintype K] [Nonempty K]
    [DecidableEq Tag] [AddGroup Tag]
    {h : K → Msg → Tag} {ε : ℝ≥0∞} (hAXU : IsEpsilonAXU h ε) :
    IsEpsilonUniversal h ε := by
  intro m₁ m₂ h_ne
  -- Convert `h k m₁ = h k m₂` to `h k m₁ - h k m₂ = 0` and apply AXU at δ = 0.
  have h_predicate_eq :
      (fun k : K => decide (h k m₁ = h k m₂))
        = (fun k : K => decide (h k m₁ - h k m₂ = (0 : Tag))) := by
    funext k
    by_cases h_eq : h k m₁ = h k m₂
    · simp [h_eq, sub_self]
    · simp only [h_eq, decide_false]
      have h_sub_ne : h k m₁ - h k m₂ ≠ (0 : Tag) := fun h_zero =>
        h_eq (sub_eq_zero.mp h_zero)
      simp [h_sub_ne]
  rw [h_predicate_eq]
  exact hAXU m₁ m₂ 0 h_ne

/--
**Sufficient cardinality bound for AXU.** If for every `m₁ ≠ m₂` and
every `δ : Tag`, the cardinality of keys `k` with `h k m₁ - h k m₂ = δ`
is bounded by `C`, then `h` is `(C / |K|)`-AXU.
-/
theorem IsEpsilonAXU.ofCollisionCardBound [Fintype K] [Nonempty K]
    [DecidableEq Tag] [SubtractionMonoid Tag]
    (h : K → Msg → Tag) (C : ℕ)
    (hCard : ∀ (m₁ m₂ : Msg) (δ : Tag), m₁ ≠ m₂ →
      (Finset.univ.filter
        (fun k : K => h k m₁ - h k m₂ = δ)).card ≤ C) :
    IsEpsilonAXU h ((C : ℝ≥0∞) / (Fintype.card K : ℝ≥0∞)) := by
  intro m₁ m₂ δ h_ne
  classical
  rw [probTrue_uniformPMF_decide_eq]
  exact ENNReal.div_le_div_right (Nat.cast_le.mpr (hCard m₁ m₂ δ h_ne)) _

-- ============================================================================
-- ε-strongly-universal-2 (ε-SU2) — the hypothesis for one-time SUF-CMA
-- ============================================================================

/--
A hash family `h : K → Msg → Tag` is **ε-strongly-universal-2** (ε-SU2)
iff for every two distinct messages `m₁ ≠ m₂` and every pair of tag
values `(t₁, t₂) : Tag × Tag`, the joint probability over uniform `k`
that `h k m₁ = t₁ ∧ h k m₂ = t₂` is at most `ε / |Tag|`.

**Mathematical content.** This is **strictly stronger** than both
`IsEpsilonUniversal` (the `t₁ = t₂` specialisation gives the universal
bound after summing over `t : Tag`) and `IsEpsilonAXU` (the
`δ = t₁ - t₂` specialisation gives the AXU bound after summing over
`t₁`). The joint-distribution control is what's needed for the one-
time Wegman–Carter SUF-CMA reduction (see
`Orbcrypt/AEAD/MACSecurity.lean`'s `isSUFCMASecure_of_isEpsilonSU2`).

**Reference.** Stinson 1994 ("Universal hashing and authentication
codes," Theorem 1) states the ε-SU2 hypothesis under the name
"strongly ε-universal hash family of size 2" or "ε-balanced." The
name "strongly-universal-2" matches the modern cryptographic
literature (e.g., Krovetz 2007).

**Why `[Nonempty Tag]`.** The denominator `|Tag|` must be non-zero
for the bound `ε / |Tag|` to be meaningful in `ℝ≥0∞` (avoiding the
`ε / 0 = ⊤` degenerate case for `ε ≠ 0`). For Carter–Wegman over
`ZMod p` with `[Fact (Nat.Prime p)]`, `Nonempty (ZMod p)` is
automatic.
-/
def IsEpsilonSU2 [Fintype K] [Nonempty K] [Fintype Tag] [Nonempty Tag]
    [DecidableEq Tag] (h : K → Msg → Tag) (ε : ℝ≥0∞) : Prop :=
  ∀ (m₁ m₂ : Msg) (t₁ t₂ : Tag), m₁ ≠ m₂ →
    probTrue (uniformPMF K)
      (fun k => decide (h k m₁ = t₁ ∧ h k m₂ = t₂)) ≤
    ε / (Fintype.card Tag : ℝ≥0∞)

/--
Monotonicity for SU2: if `h` is ε₁-SU2 and ε₁ ≤ ε₂, then `h` is ε₂-SU2.
-/
theorem IsEpsilonSU2.mono [Fintype K] [Nonempty K] [Fintype Tag] [Nonempty Tag]
    [DecidableEq Tag]
    {h : K → Msg → Tag} {ε₁ ε₂ : ℝ≥0∞}
    (hle : ε₁ ≤ ε₂) (hSU2 : IsEpsilonSU2 h ε₁) :
    IsEpsilonSU2 h ε₂ := by
  intro m₁ m₂ t₁ t₂ h_ne
  refine (hSU2 m₁ m₂ t₁ t₂ h_ne).trans ?_
  exact ENNReal.div_le_div_right hle _

/--
**Sufficient cardinality bound for SU2.** If for every `m₁ ≠ m₂` and
every `(t₁, t₂)`, the joint-collision cardinality
`#{k | h k m₁ = t₁ ∧ h k m₂ = t₂}` is bounded by `C`, then `h` is
`(C * |Tag| / |K|)`-SU2.

**Why the `C * |Tag|` numerator.** The SU2 bound asks
`probTrue ≤ ε / |Tag|`, i.e. `(joint-card) / |K| ≤ ε / |Tag|`. Solving
for ε gives `ε = C * |Tag| / |K|`. The constructor takes the bound on
joint-card and produces the matching ε.

**Carter–Wegman application.** With `C = 1` (unique solution to the
2×2 linear system) and `|Tag| = p`, `|K| = p²`, this gives
`ε = 1 * p / p² = 1/p` — the standard Carter–Wegman ε.
-/
theorem IsEpsilonSU2.ofJointCollisionCardBound [Fintype K] [Nonempty K]
    [Fintype Tag] [Nonempty Tag] [DecidableEq Tag]
    (h : K → Msg → Tag) (C : ℕ)
    (hCard : ∀ (m₁ m₂ : Msg) (t₁ t₂ : Tag), m₁ ≠ m₂ →
      (Finset.univ.filter
        (fun k : K => h k m₁ = t₁ ∧ h k m₂ = t₂)).card ≤ C) :
    IsEpsilonSU2 h
      (((C : ℝ≥0∞) * (Fintype.card Tag : ℝ≥0∞)) / (Fintype.card K : ℝ≥0∞)) := by
  intro m₁ m₂ t₁ t₂ h_ne
  classical
  rw [probTrue_uniformPMF_decide_eq]
  -- Goal: (joint-card : ℝ≥0∞) / |K| ≤ (C * |Tag|) / |K| / |Tag|.
  -- Simplify the RHS via cancellation: (C * |Tag|) / |K| / |Tag| = C / |K|
  -- when |Tag| ≠ 0, ⊤. The numerator (joint-card) ≤ C, so we're done.
  have h_tag_pos : 0 < Fintype.card Tag := Fintype.card_pos
  have h_tag_ne_zero : (Fintype.card Tag : ℝ≥0∞) ≠ 0 := by
    exact_mod_cast h_tag_pos.ne'
  have h_tag_ne_top : (Fintype.card Tag : ℝ≥0∞) ≠ ⊤ :=
    ENNReal.natCast_ne_top _
  -- Reduce the right-hand side to (C : ℝ≥0∞) / (Fintype.card K : ℝ≥0∞)
  -- via `(a * b) / c / b = a / c` when `b ≠ 0, ⊤`. Use `ENNReal.mul_div_assoc`
  -- (`(a * b) / c = a * (b / c)`) and `ENNReal.mul_div_cancel_right`-style
  -- algebra; the simplest path goes via `div_eq_mul_inv` and `mul_assoc`.
  have h_rhs_eq :
      ((C : ℝ≥0∞) * (Fintype.card Tag : ℝ≥0∞)) / (Fintype.card K : ℝ≥0∞)
        / (Fintype.card Tag : ℝ≥0∞)
      = (C : ℝ≥0∞) / (Fintype.card K : ℝ≥0∞) := by
    -- Rewrite using `div_eq_mul_inv` to expose the multiplicative form.
    rw [ENNReal.div_eq_inv_mul, ENNReal.div_eq_inv_mul, ENNReal.div_eq_inv_mul]
    -- Pull `|Tag|⁻¹` past `|K|⁻¹` and cancel with `|Tag|`.
    -- Goal: |Tag|⁻¹ * (|K|⁻¹ * (C * |Tag|)) = |K|⁻¹ * C.
    -- Rearrange via `mul_left_comm` and `mul_assoc` to expose
    -- `|Tag|⁻¹ * |Tag|` as adjacent factors.
    rw [mul_left_comm (Fintype.card Tag : ℝ≥0∞)⁻¹]
    -- Goal: |K|⁻¹ * (|Tag|⁻¹ * (C * |Tag|)) = |K|⁻¹ * C.
    -- Pull |Tag| out of the inner product, cancel with |Tag|⁻¹.
    rw [show (C : ℝ≥0∞) * (Fintype.card Tag : ℝ≥0∞)
        = (Fintype.card Tag : ℝ≥0∞) * (C : ℝ≥0∞) from mul_comm _ _]
    -- Goal: |K|⁻¹ * (|Tag|⁻¹ * (|Tag| * C)) = |K|⁻¹ * C.
    rw [← mul_assoc (Fintype.card Tag : ℝ≥0∞)⁻¹]
    -- Goal: |K|⁻¹ * (|Tag|⁻¹ * |Tag| * C) = |K|⁻¹ * C.
    rw [ENNReal.inv_mul_cancel h_tag_ne_zero h_tag_ne_top, one_mul]
  rw [h_rhs_eq]
  exact ENNReal.div_le_div_right (Nat.cast_le.mpr (hCard m₁ m₂ t₁ t₂ h_ne)) _

-- ============================================================================
-- SU2 implications: SU2 ⇒ ε-universal and SU2 ⇒ ε-AXU
-- ============================================================================

/--
**SU2 implies ε-universal.** From the joint-distribution control of
SU2, sum over the diagonal `(t, t)` and apply `Finset.sum_le_sum` +
`Finset.sum_const` to get the universal bound.

**Why no factor of `|Tag|` in the conclusion.** The collision event
`h k m₁ = h k m₂` is the disjoint union over `t : Tag` of the joint
events `h k m₁ = t ∧ h k m₂ = t`. Each joint event has probability
≤ `ε / |Tag|` (by SU2). Summing gives `|Tag| · (ε / |Tag|) = ε`.
The cancellation requires `|Tag| ≠ 0, ⊤`, which the typeclass
instances supply.

**Proof structure.** `probTrue (uniformPMF K) (collision)` =
`Σ t ∈ Tag, probTrue (uniformPMF K) (joint at t)`. The disjoint-union
identity follows from the fact that `h k m₁ = h k m₂` holds iff there
exists a unique `t = h k m₁` such that the joint condition holds.
-/
theorem IsEpsilonSU2.toIsEpsilonUniversal [Fintype K] [Nonempty K]
    [Fintype Tag] [Nonempty Tag] [DecidableEq Tag]
    {h : K → Msg → Tag} {ε : ℝ≥0∞} (hSU2 : IsEpsilonSU2 h ε) :
    IsEpsilonUniversal h ε := by
  intro m₁ m₂ h_ne
  classical
  -- The collision event partitions over `t : Tag` (the shared output).
  rw [probTrue_uniformPMF_decide_eq]
  -- Goal: (#{k | h k m₁ = h k m₂}) / |K| ≤ ε
  -- Strategy: cardinality of the collision set equals the sum over t
  -- of cardinalities of `{k | h k m₁ = t ∧ h k m₂ = t}`.
  have h_card_eq :
      (Finset.univ.filter (fun k : K => h k m₁ = h k m₂)).card
      = ∑ t : Tag, (Finset.univ.filter
          (fun k : K => h k m₁ = t ∧ h k m₂ = t)).card := by
    -- Bijective decomposition via the disjoint Tag-indexed family.
    rw [← Finset.card_biUnion]
    · congr 1
      ext k
      simp only [Finset.mem_filter, Finset.mem_univ, true_and,
        Finset.mem_biUnion]
      -- After simp, the biUnion direction is `∃ i, h k m₁ = i ∧ h k m₂ = i`.
      constructor
      · intro h_coll
        -- Provide `t = h k m₁`; both equalities follow from rfl + h_coll.
        exact ⟨h k m₁, rfl, h_coll.symm⟩
      · rintro ⟨t, h_eq₁, h_eq₂⟩
        exact h_eq₁.trans h_eq₂.symm
    · intro t _ s _ h_t_ne_s
      simp only [Finset.disjoint_left, Finset.mem_filter, Finset.mem_univ,
        true_and]
      rintro k ⟨h_t₁, _⟩ ⟨h_s₁, _⟩
      exact h_t_ne_s (h_t₁.symm.trans h_s₁)
  -- Now express probTrue of each per-t joint event as a card / |K| ratio.
  have h_per_t :
      ∀ t : Tag,
        ((Finset.univ.filter
          (fun k : K => h k m₁ = t ∧ h k m₂ = t)).card : ℝ≥0∞)
          / (Fintype.card K : ℝ≥0∞) ≤ ε / (Fintype.card Tag : ℝ≥0∞) := by
    intro t
    have h_su2_t := hSU2 m₁ m₂ t t h_ne
    rwa [probTrue_uniformPMF_decide_eq] at h_su2_t
  -- Push-cast the sum and apply `Finset.sum_le_sum` then `sum_const`.
  have h_sum_le :
      ∑ t : Tag, ((Finset.univ.filter
        (fun k : K => h k m₁ = t ∧ h k m₂ = t)).card : ℝ≥0∞)
          / (Fintype.card K : ℝ≥0∞)
      ≤ ∑ _t : Tag, ε / (Fintype.card Tag : ℝ≥0∞) :=
    Finset.sum_le_sum (fun t _ => h_per_t t)
  -- Combine: LHS = (full collision-card cast) / |K|.
  -- Convert collision-card / |K| to a sum of per-t card / |K| ratios.
  -- We use `Finset.sum_div`-style rewrite: ∑ a, f a / d = (∑ a, f a) / d.
  have h_lhs_sum :
      ((Finset.univ.filter (fun k : K => h k m₁ = h k m₂)).card : ℝ≥0∞)
        / (Fintype.card K : ℝ≥0∞)
      = ∑ t : Tag, ((Finset.univ.filter
          (fun k : K => h k m₁ = t ∧ h k m₂ = t)).card : ℝ≥0∞)
            / (Fintype.card K : ℝ≥0∞) := by
    -- Convert each `card / |K|` to `card * |K|⁻¹`.
    simp_rw [div_eq_mul_inv]
    -- Now: card_total * |K|⁻¹ = ∑ t, card_t * |K|⁻¹.
    -- Pull |K|⁻¹ out via `Finset.sum_mul`.
    rw [← Finset.sum_mul]
    -- Now: card_total * |K|⁻¹ = (∑ t, card_t) * |K|⁻¹.
    -- It remains to rewrite card_total = ∑ t, card_t.
    congr 1
    rw [show (Finset.univ.filter (fun k : K => h k m₁ = h k m₂)).card
          = ∑ t : Tag, (Finset.univ.filter
              (fun k : K => h k m₁ = t ∧ h k m₂ = t)).card from h_card_eq]
    push_cast
    rfl
  rw [h_lhs_sum]
  refine h_sum_le.trans ?_
  -- Goal: ∑ _t : Tag, ε / |Tag| ≤ ε.
  -- Compute the sum directly: it equals (|Tag| : ℝ≥0∞) * (ε / |Tag|) = ε.
  have h_tag_pos : 0 < Fintype.card Tag := Fintype.card_pos
  have h_tag_ne_zero : (Fintype.card Tag : ℝ≥0∞) ≠ 0 := by
    exact_mod_cast h_tag_pos.ne'
  have h_tag_ne_top : (Fintype.card Tag : ℝ≥0∞) ≠ ⊤ :=
    ENNReal.natCast_ne_top _
  -- ENNReal nsmul: `n • c = (n : ℝ≥0∞) * c` by induction on n.
  have h_nsmul_eq_mul :
      ∀ (n : ℕ) (c : ℝ≥0∞), n • c = (n : ℝ≥0∞) * c := by
    intro n c
    induction n with
    | zero => simp
    | succ k ih => rw [succ_nsmul, ih, Nat.cast_succ, add_mul, one_mul]
  rw [Finset.sum_const, Finset.card_univ, h_nsmul_eq_mul]
  rw [ENNReal.mul_div_cancel h_tag_ne_zero h_tag_ne_top]

/--
**SU2 implies ε-AXU.** When `Tag` carries an additive group structure,
SU2's joint-distribution bound implies the AXU output-difference bound.

**Proof structure.** The event `h k m₁ - h k m₂ = δ` is the disjoint
union over `t : Tag` of the joint events `h k m₁ = t ∧ h k m₂ = t - δ`.
Each joint event has probability ≤ `ε / |Tag|` (by SU2). Summing gives
`|Tag| · (ε / |Tag|) = ε`.
-/
theorem IsEpsilonSU2.toIsEpsilonAXU [Fintype K] [Nonempty K] [Fintype Tag]
    [Nonempty Tag] [DecidableEq Tag] [AddCommGroup Tag]
    {h : K → Msg → Tag} {ε : ℝ≥0∞} (hSU2 : IsEpsilonSU2 h ε) :
    IsEpsilonAXU h ε := by
  intro m₁ m₂ δ h_ne
  classical
  rw [probTrue_uniformPMF_decide_eq]
  -- Strategy: parametrise the AXU set by the value of `h k m₁`.
  -- `h k m₁ - h k m₂ = δ ↔ ∃ t, h k m₁ = t ∧ h k m₂ = t - δ`.
  have h_card_eq :
      (Finset.univ.filter (fun k : K => h k m₁ - h k m₂ = δ)).card
      = ∑ t : Tag, (Finset.univ.filter
          (fun k : K => h k m₁ = t ∧ h k m₂ = t - δ)).card := by
    rw [← Finset.card_biUnion]
    · congr 1
      ext k
      simp only [Finset.mem_filter, Finset.mem_univ, true_and,
        Finset.mem_biUnion]
      -- After simp, biUnion side is `∃ i, h k m₁ = i ∧ h k m₂ = i - δ`.
      constructor
      · intro h_diff
        refine ⟨h k m₁, rfl, ?_⟩
        -- Goal: h k m₂ = h k m₁ - δ.  From `h k m₁ - h k m₂ = δ`,
        -- compute `h k m₂ = h k m₁ - (h k m₁ - h k m₂) = h k m₁ - δ`.
        have : h k m₂ = h k m₁ - (h k m₁ - h k m₂) := (sub_sub_self _ _).symm
        rw [this, h_diff]
      · rintro ⟨t, h_eq₁, h_eq₂⟩
        -- Goal: h k m₁ - h k m₂ = δ.  Substitute and simplify.
        rw [h_eq₁, h_eq₂]
        -- Goal: t - (t - δ) = δ.
        exact sub_sub_self _ _
    · intro t _ s _ h_t_ne_s
      simp only [Finset.disjoint_left, Finset.mem_filter, Finset.mem_univ,
        true_and]
      rintro k ⟨h_t₁, _⟩ ⟨h_s₁, _⟩
      exact h_t_ne_s (h_t₁.symm.trans h_s₁)
  -- Express probTrue of each per-t joint event as a card / |K| ratio.
  have h_per_t :
      ∀ t : Tag,
        ((Finset.univ.filter
          (fun k : K => h k m₁ = t ∧ h k m₂ = t - δ)).card : ℝ≥0∞)
          / (Fintype.card K : ℝ≥0∞) ≤ ε / (Fintype.card Tag : ℝ≥0∞) := by
    intro t
    have h_su2_t := hSU2 m₁ m₂ t (t - δ) h_ne
    rwa [probTrue_uniformPMF_decide_eq] at h_su2_t
  -- Push-cast and apply `Finset.sum_le_sum`.
  have h_sum_le :
      ∑ t : Tag, ((Finset.univ.filter
        (fun k : K => h k m₁ = t ∧ h k m₂ = t - δ)).card : ℝ≥0∞)
          / (Fintype.card K : ℝ≥0∞)
      ≤ ∑ _t : Tag, ε / (Fintype.card Tag : ℝ≥0∞) :=
    Finset.sum_le_sum (fun t _ => h_per_t t)
  -- Sum-decomposition for AXU: same shape as the universal proof.
  have h_lhs_sum :
      ((Finset.univ.filter (fun k : K => h k m₁ - h k m₂ = δ)).card : ℝ≥0∞)
        / (Fintype.card K : ℝ≥0∞)
      = ∑ t : Tag, ((Finset.univ.filter
          (fun k : K => h k m₁ = t ∧ h k m₂ = t - δ)).card : ℝ≥0∞)
            / (Fintype.card K : ℝ≥0∞) := by
    -- Convert each `card / |K|` to `card * |K|⁻¹`.
    simp_rw [div_eq_mul_inv]
    -- Pull |K|⁻¹ out via `Finset.sum_mul`.
    rw [← Finset.sum_mul]
    congr 1
    rw [show (Finset.univ.filter (fun k : K => h k m₁ - h k m₂ = δ)).card
          = ∑ t : Tag, (Finset.univ.filter
              (fun k : K => h k m₁ = t ∧ h k m₂ = t - δ)).card from h_card_eq]
    push_cast
    rfl
  rw [h_lhs_sum]
  refine h_sum_le.trans ?_
  have h_tag_pos : 0 < Fintype.card Tag := Fintype.card_pos
  have h_tag_ne_zero : (Fintype.card Tag : ℝ≥0∞) ≠ 0 := by
    exact_mod_cast h_tag_pos.ne'
  have h_tag_ne_top : (Fintype.card Tag : ℝ≥0∞) ≠ ⊤ :=
    ENNReal.natCast_ne_top _
  -- ENNReal nsmul: `n • c = (n : ℝ≥0∞) * c` by induction on n.
  have h_nsmul_eq_mul :
      ∀ (n : ℕ) (c : ℝ≥0∞), n • c = (n : ℝ≥0∞) * c := by
    intro n c
    induction n with
    | zero => simp
    | succ k ih => rw [succ_nsmul, ih, Nat.cast_succ, add_mul, one_mul]
  rw [Finset.sum_const, Finset.card_univ, h_nsmul_eq_mul]
  rw [ENNReal.mul_div_cancel h_tag_ne_zero h_tag_ne_top]

end Orbcrypt
