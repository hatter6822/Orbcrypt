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
* `Orbcrypt.probTrue_uniformPMF_decide_eq` — helper: `probTrue` under
  `uniformPMF` on a decidable predicate equals the cardinality of the
  satisfying filter divided by the keyspace cardinality.

## Main results

* `Orbcrypt.IsEpsilonUniversal.mono` — monotonicity in ε.
* `Orbcrypt.IsEpsilonUniversal.ofCollisionCardBound` — sufficient
  cardinality bound: if the collision-set cardinality is bounded by
  `C`, the family is `C/|K|`-universal.

## Scope

This module formalizes the **ε-universality** property. It does **not**
prove the Wegman–Carter MAC security reduction from universality to
SUF-CMA (which would require probabilistic game infrastructure beyond
this module). The canonical instance `carterWegmanHash_isUniversal`
in `Orbcrypt/AEAD/CarterWegmanMAC.lean` produces `(1/p)`-universality
from primality, which is sufficient for future Wegman–Carter layering.

## References

* Carter, J. L. & Wegman, M. N. (1977). "Universal classes of hash
  functions." J. Comput. Syst. Sci. 18(2): 143–154.
* Wegman, M. N. & Carter, J. L. (1981). "New hash functions and their
  use in authentication and set equality." J. Comput. Syst. Sci. 22:
  265–279.
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

end Orbcrypt
