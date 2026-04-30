/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Field.ZMod
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Algebra.Polynomial.Eval.Defs
import Orbcrypt.AEAD.MAC
import Orbcrypt.AEAD.AEAD
import Orbcrypt.AEAD.CarterWegmanMAC
import Orbcrypt.Construction.Permutation
import Orbcrypt.Probability.UniversalHash

/-!
# Orbcrypt.AEAD.BitstringPolynomialMAC

A `Bitstring n`-typed polynomial-evaluation hash family + MAC + AEAD
composition with the in-orbit-only `INT_CTXT` discharge. This closes
research-scope item **R-13** (audit 2026-04-29 § 8.1) — namely, the
incompatibility between `carterWegmanMAC` (typed at `X = ZMod p`) and
HGOE's `Bitstring n` ciphertext space.

## Strategy: generalise, don't adapt

Rather than build a `Bitstring n → ZMod p` orbit-preserving adapter
(which would require new structural infrastructure), we **generalise**
Carter–Wegman to a polynomial-evaluation hash family directly typed at
`Bitstring n`. This is the standard Carter–Wegman polynomial hash
(Stinson 1996 §4.2), specialised to bit-encoding the message:

  `bitstringPolynomialHash p n (k, s) b
     = s + ∑ i : Fin n, (toBit (b i)) · k^(i+1)`

Here `toBit : Bool → ZMod p` is `false ↦ 0, true ↦ 1`, and the sum
ranges over the bit positions of `b : Bitstring n`. The exponent
`i + 1` (rather than `i`) keeps the constant term zero so the offset
`s` carries the affine shift cleanly.

## Universality

For distinct bitstrings `b₁ ≠ b₂`, the difference polynomial

  `Δ_{b₁, b₂}(X) := ∑ i, (toBit (b₁ i) − toBit (b₂ i)) · X^(i+1)`

* Is non-zero (at any disagreeing bit position `i₀`, the coefficient
  is `±1 ≠ 0` in the prime field `ZMod p`).
* Has degree ≤ n.
* Has at most n roots in `ZMod p` (over a field, by
  `Polynomial.card_roots'`).

Each colliding key `k` admits all `p` values of `s` (which cancels in
the difference). So the collision count is at most `n · p`, giving an
`(n · p) / p² = n / p`-universal hash family.

## Headline result

  `bitstringPolynomialHash_isUniversal (p n : ℕ) [Fact (Nat.Prime p)] :
     IsEpsilonUniversal (bitstringPolynomialHash p n)
       ((n : ℝ≥0∞) / (p : ℝ≥0∞))`

This bound is informative for `n ≤ p` (giving ε ≤ 1) and is consistent
with deployment parameter selection.

## MAC and INT-CTXT composition

  `bitstringPolynomialMAC p n` — concrete `MAC` via
  `deterministicTagMAC bitstringPolynomialHash`.
  `bitstringPolynomial_authKEM p n kem` — composes with any `OrbitKEM
  G (Bitstring n) (ZMod p × ZMod p)`.
  `bitstringPolynomialMAC_int_ctxt` — unconditional INT-CTXT via the
  post-Workstream-B `authEncrypt_is_int_ctxt`.

This gives Orbcrypt a release-facing **Standalone**-grade
ciphertext-integrity citation for HGOE-typed authenticated KEM.

## Naming honesty

The identifier `bitstringPolynomial*` (not `carterWegman*`) reflects
the polynomial-hash content: at `n > 1`, the bound is `n / p` rather
than the single-block `1 / p`. The identifier names the polynomial
shape, not Carter–Wegman's single-block primitive. This obeys the
"Security-by-docstring prohibition" naming rule in `CLAUDE.md`.

## References

* Stinson, D. R. (1996). "On the connections between universal hashing,
  combinatorial designs and error-correcting codes." Congressus
  Numerantium 114: 7–27.
* Carter, J. L. & Wegman, M. N. (1977). "Universal classes of hash
  functions."
* `docs/planning/AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md`
  § 8.1 — research-scope catalogue, R-13.
-/

set_option autoImplicit false

namespace Orbcrypt

open PMF ENNReal Polynomial

universe u

variable {p n : ℕ}

-- ============================================================================
-- WU-β.1 — Bit-to-field encoding
-- ============================================================================

/-- **Bit-to-field encoding.** `toBit : Bool → ZMod p` sends `false ↦ 0`
    and `true ↦ 1`. This is the natural inclusion `{0, 1} ↪ ZMod p`
    that the polynomial-hash uses to encode message bits as field
    elements.

    For `p ≥ 2` (i.e. any prime), `toBit` is injective. -/
def toBit (p : ℕ) (b : Bool) : ZMod p :=
  if b then 1 else 0

@[simp] theorem toBit_false : toBit p false = 0 := rfl
@[simp] theorem toBit_true : toBit p true = 1 := rfl

/-- `toBit` is injective when `1 ≠ 0` in `ZMod p` — i.e. for any prime
    `p`, since the smallest prime is 2 and `(1 : ZMod 2) = 1 ≠ 0`. -/
theorem toBit_injective [NeZero p] [Fact (Nat.Prime p)] :
    Function.Injective (toBit p) := by
  intro a b h
  cases a <;> cases b <;> simp_all [toBit]

-- ============================================================================
-- WU-β.2 — Polynomial-evaluation hash core
-- ============================================================================

/-- **Polynomial-evaluation hash on bitstrings.** Evaluate a length-`n`
    bitstring `b` at key `k ∈ ZMod p` as

      `evalAtBitstring p n k b = ∑ i : Fin n, (toBit (b i)) · k^(i+1)`.

    This is the "polynomial part" of the hash — the offset `s` is
    added in `bitstringPolynomialHash` below. The `i + 1` exponent
    keeps the constant term zero so the offset cancels cleanly in
    the collision analysis (see `bitstringPolynomialHash_collision_iff_eval`). -/
def evalAtBitstring (p n : ℕ) [Fact (Nat.Prime p)]
    (k : ZMod p) (b : Bitstring n) : ZMod p :=
  ∑ i : Fin n, (toBit p (b i)) * k ^ (i.val + 1)

/-- `evalAtBitstring` of the all-`false` bitstring is `0`. Every term
    `toBit false · k^(i+1) = 0 · k^(i+1) = 0`. -/
@[simp] theorem evalAtBitstring_zero (p n : ℕ) [Fact (Nat.Prime p)] (k : ZMod p) :
    evalAtBitstring p n k (fun _ => false) = 0 := by
  simp [evalAtBitstring, toBit]

-- ============================================================================
-- WU-β.3 — `bitstringPolynomialHash`
-- ============================================================================

/-- **Bitstring polynomial hash family.** A two-part keyed hash:
    `(k, s) ↦ s + evalAtBitstring p n k b`. The `k` component is the
    "evaluation point" used by the polynomial part; `s` is the affine
    offset.

    For prime `p`, `Fintype.card (ZMod p × ZMod p) = p²` makes this
    a key family of size `p²`. For distinct messages `b₁ ≠ b₂`, the
    collision probability is at most `n / p` (`bitstringPolynomialHash_isUniversal`),
    so for `n ≤ p` the bound is informative. -/
def bitstringPolynomialHash (p n : ℕ) [Fact (Nat.Prime p)]
    (k : ZMod p × ZMod p) (b : Bitstring n) : ZMod p :=
  k.2 + evalAtBitstring p n k.1 b

/-- Definitional unfolding of `bitstringPolynomialHash`. -/
theorem bitstringPolynomialHash_apply (p n : ℕ) [Fact (Nat.Prime p)]
    (k : ZMod p × ZMod p) (b : Bitstring n) :
    bitstringPolynomialHash p n k b = k.2 + evalAtBitstring p n k.1 b := rfl

/-- **Collision iff polynomial collision.** The offset `s = k.2`
    cancels in the difference `hash (k, s) b₁ − hash (k, s) b₂`. So
    two messages collide iff their polynomial parts agree at `k`. -/
theorem bitstringPolynomialHash_collision_iff_eval (p n : ℕ) [Fact (Nat.Prime p)]
    (k : ZMod p × ZMod p) (b₁ b₂ : Bitstring n) :
    bitstringPolynomialHash p n k b₁ = bitstringPolynomialHash p n k b₂ ↔
    evalAtBitstring p n k.1 b₁ = evalAtBitstring p n k.1 b₂ := by
  unfold bitstringPolynomialHash
  exact add_right_inj k.2

-- ============================================================================
-- WU-β.5 / β.6 / β.7 — Difference polynomial and its degree/eval
-- ============================================================================

/-- **Difference polynomial.** For two bitstrings `b₁ b₂ : Bitstring n`,
    the polynomial
    `Δ(X) := ∑ i : Fin n, C (toBit (b₁ i) − toBit (b₂ i)) · X^(i+1)`
    over `(ZMod p)[X]`.

    Two key properties:
    * `(Δ).eval k = evalAtBitstring p n k b₁ − evalAtBitstring p n k b₂`
      (`bitstringDiffPolynomial_eval`).
    * For `b₁ ≠ b₂`, `Δ ≠ 0` and `(Δ).natDegree ≤ n`. -/
noncomputable def bitstringDiffPolynomial (p n : ℕ) [Fact (Nat.Prime p)]
    (b₁ b₂ : Bitstring n) : Polynomial (ZMod p) :=
  ∑ i : Fin n, Polynomial.C (toBit p (b₁ i) - toBit p (b₂ i))
    * Polynomial.X ^ (i.val + 1)

/-- **Evaluation of the difference polynomial.** `eval k Δ` recovers
    the difference of the two `evalAtBitstring` values. The `s`
    component (offset) is irrelevant since the polynomial only
    depends on the bit-encoded values, not on the affine shift. -/
theorem bitstringDiffPolynomial_eval (p n : ℕ) [Fact (Nat.Prime p)]
    (k : ZMod p) (b₁ b₂ : Bitstring n) :
    (bitstringDiffPolynomial p n b₁ b₂).eval k =
      evalAtBitstring p n k b₁ - evalAtBitstring p n k b₂ := by
  unfold bitstringDiffPolynomial evalAtBitstring
  rw [Polynomial.eval_finset_sum]
  -- Goal: ∑ i, eval k (C (toBit b₁ i - toBit b₂ i) * X^(i+1))
  --       = ∑ i, toBit b₁ i · k^(i+1) − ∑ i, toBit b₂ i · k^(i+1)
  rw [← Finset.sum_sub_distrib]
  apply Finset.sum_congr rfl
  intro i _
  rw [Polynomial.eval_mul, Polynomial.eval_C, Polynomial.eval_pow,
      Polynomial.eval_X]
  ring

/-- **Degree bound on the difference polynomial.** Each summand
    `C c · X^(i+1)` has degree `≤ i + 1 ≤ n` (since `i : Fin n` so
    `i < n`). The sum's `natDegree` is bounded by the max of summand
    `natDegree`s. -/
theorem bitstringDiffPolynomial_natDegree_le (p n : ℕ) [Fact (Nat.Prime p)]
    (b₁ b₂ : Bitstring n) :
    (bitstringDiffPolynomial p n b₁ b₂).natDegree ≤ n := by
  unfold bitstringDiffPolynomial
  apply Polynomial.natDegree_sum_le_of_forall_le
  intro i _
  -- Each summand: C c · X^(i+1). natDegree ≤ i.val + 1 ≤ n.
  calc (Polynomial.C (toBit p (b₁ i) - toBit p (b₂ i))
        * Polynomial.X ^ (i.val + 1)).natDegree
      ≤ (i.val + 1) := by
        apply le_trans (Polynomial.natDegree_C_mul_X_pow_le _ _)
        exact le_refl _
    _ ≤ n := i.isLt

/-- **Coefficient at the disagreeing position is non-zero.** For
    `b₁ ≠ b₂`, pick `i₀ : Fin n` with `b₁ i₀ ≠ b₂ i₀`. The
    coefficient of `X^(i₀.val + 1)` in the difference polynomial is
    `toBit (b₁ i₀) − toBit (b₂ i₀) ∈ {−1, +1}`, which is non-zero in
    `ZMod p` for `p` prime.

    Other summands `C c_j · X^(j+1)` (with `j ≠ i₀`) contribute `0`
    at `X^(i₀+1)` because `j + 1 ≠ i₀ + 1`. -/
theorem bitstringDiffPolynomial_coeff_at (p n : ℕ) [Fact (Nat.Prime p)]
    (b₁ b₂ : Bitstring n) (i₀ : Fin n) :
    (bitstringDiffPolynomial p n b₁ b₂).coeff (i₀.val + 1) =
      toBit p (b₁ i₀) - toBit p (b₂ i₀) := by
  unfold bitstringDiffPolynomial
  rw [Polynomial.finset_sum_coeff]
  -- Single non-zero contribution at i = i₀; others have wrong exponent.
  rw [Finset.sum_eq_single i₀]
  · -- Main contribution: C c · X^(i₀+1) coeff at i₀+1 is c.
    rw [Polynomial.coeff_C_mul, Polynomial.coeff_X_pow_self]
    ring
  · -- Other summands: C c_j · X^(j+1) coeff at i₀+1 is 0 when j ≠ i₀.
    intro j _ h_ne
    rw [Polynomial.coeff_C_mul, Polynomial.coeff_X_pow]
    have h_exp_ne : j.val + 1 ≠ i₀.val + 1 := by
      intro h
      apply h_ne
      ext
      omega
    rw [if_neg (fun h => h_exp_ne h.symm)]
    ring
  · intro h_not_mem
    exact absurd (Finset.mem_univ i₀) h_not_mem

/-- **Difference polynomial is non-zero for distinct bitstrings.**
    From `Function.ne_iff` we get an `i₀` where the bits disagree;
    the coefficient at `X^(i₀ + 1)` is `±1` in the prime field, hence
    non-zero. -/
theorem bitstringDiffPolynomial_ne_zero_of_ne (p n : ℕ) [Fact (Nat.Prime p)]
    {b₁ b₂ : Bitstring n} (h_ne : b₁ ≠ b₂) :
    bitstringDiffPolynomial p n b₁ b₂ ≠ 0 := by
  -- Find a disagreeing position.
  obtain ⟨i₀, h_disagree⟩ := Function.ne_iff.mp h_ne
  intro h_zero
  -- The coefficient at i₀+1 must be 0 if the polynomial is 0.
  have h_coeff : (bitstringDiffPolynomial p n b₁ b₂).coeff (i₀.val + 1) = 0 := by
    rw [h_zero]
    exact Polynomial.coeff_zero _
  rw [bitstringDiffPolynomial_coeff_at] at h_coeff
  -- toBit b₁ i₀ - toBit b₂ i₀ = 0 ⇒ toBit b₁ i₀ = toBit b₂ i₀.
  have h_eq : toBit p (b₁ i₀) = toBit p (b₂ i₀) := sub_eq_zero.mp h_coeff
  -- Apply injectivity of toBit (uses Fact (Nat.Prime p) for [NeZero p]).
  haveI : NeZero p := ⟨(Fact.out : Nat.Prime p).ne_zero⟩
  exact h_disagree (toBit_injective h_eq)

-- ============================================================================
-- WU-β.9 — Root-cardinality bound
-- ============================================================================

/-- **Root-cardinality bound.** Over the field `ZMod p` (where
    `Fact (Nat.Prime p)` makes `ZMod p` a field), the difference
    polynomial has at most `n` roots:
    `(Δ.roots).card ≤ Δ.natDegree ≤ n` (`Polynomial.card_roots'` +
    `bitstringDiffPolynomial_natDegree_le`). -/
theorem bitstringDiffPolynomial_card_roots_le (p n : ℕ) [Fact (Nat.Prime p)]
    (b₁ b₂ : Bitstring n) :
    Multiset.card (bitstringDiffPolynomial p n b₁ b₂).roots ≤ n :=
  (bitstringDiffPolynomial p n b₁ b₂).card_roots'.trans
    (bitstringDiffPolynomial_natDegree_le p n b₁ b₂)

-- ============================================================================
-- WU-β.10 — Collision-card bound
-- ============================================================================

/-- **Collision-key set restricted to the first coordinate.** The
    cardinality of the keys `k : ZMod p` whose first component
    produces a collision is at most `n`: each such `k` is a root
    of the difference polynomial.

    Going through `Polynomial.roots.toFinset` (the set of *distinct*
    roots) since the filter we care about is set-theoretic, not
    multiplicity-counted. -/
theorem bitstringDiffPolynomial_collision_keys_card_le (p n : ℕ)
    [Fact (Nat.Prime p)] {b₁ b₂ : Bitstring n} (h_ne : b₁ ≠ b₂) :
    (Finset.univ.filter (fun k : ZMod p =>
        evalAtBitstring p n k b₁ = evalAtBitstring p n k b₂)).card ≤ n := by
  classical
  -- The filter equals the toFinset of roots of the difference polynomial.
  have h_ne_zero : bitstringDiffPolynomial p n b₁ b₂ ≠ 0 :=
    bitstringDiffPolynomial_ne_zero_of_ne p n h_ne
  -- `eval k Δ = 0 ↔ evalAtBitstring p n k b₁ = evalAtBitstring p n k b₂`
  -- (modulo sign, but it's `sub_eq_zero`).
  have h_filter_subset :
      (Finset.univ.filter (fun k : ZMod p =>
        evalAtBitstring p n k b₁ = evalAtBitstring p n k b₂)) ⊆
      (bitstringDiffPolynomial p n b₁ b₂).roots.toFinset := by
    intro k hk
    rw [Finset.mem_filter] at hk
    rw [Multiset.mem_toFinset, Polynomial.mem_roots h_ne_zero]
    show (bitstringDiffPolynomial p n b₁ b₂).eval k = 0
    rw [bitstringDiffPolynomial_eval]
    exact sub_eq_zero.mpr hk.2
  calc (Finset.univ.filter (fun k : ZMod p =>
          evalAtBitstring p n k b₁ = evalAtBitstring p n k b₂)).card
      ≤ (bitstringDiffPolynomial p n b₁ b₂).roots.toFinset.card :=
        Finset.card_le_card h_filter_subset
    _ ≤ Multiset.card (bitstringDiffPolynomial p n b₁ b₂).roots :=
        Multiset.toFinset_card_le _
    _ ≤ n := bitstringDiffPolynomial_card_roots_le p n b₁ b₂

/-- **Collision-card bound on `ZMod p × ZMod p`.** For distinct
    bitstrings `b₁ ≠ b₂`, the keys `(k, s)` causing a collision
    satisfy `k ∈ {roots of Δ}` (at most `n` choices) and `s` ranges
    over all of `ZMod p` (at most `p` choices). So total ≤ `n · p`.

    Implementation uses the `Finset.product` decomposition: the
    collision filter on `ZMod p × ZMod p` equals
    `(collision-keys-for-k) ×ˢ Finset.univ`. -/
theorem bitstringPolynomialHash_collision_card_le (p n : ℕ)
    [Fact (Nat.Prime p)] {b₁ b₂ : Bitstring n} (h_ne : b₁ ≠ b₂) :
    (Finset.univ.filter
      (fun kp : ZMod p × ZMod p =>
        bitstringPolynomialHash p n kp b₁ = bitstringPolynomialHash p n kp b₂)).card
    ≤ n * p := by
  classical
  -- Step 1 — rewrite the collision condition via `_collision_iff_eval`.
  have h_filter_eq :
      Finset.univ.filter
        (fun kp : ZMod p × ZMod p =>
          bitstringPolynomialHash p n kp b₁ = bitstringPolynomialHash p n kp b₂)
      = Finset.univ.filter
        (fun kp : ZMod p × ZMod p =>
          evalAtBitstring p n kp.1 b₁ = evalAtBitstring p n kp.1 b₂) := by
    apply Finset.filter_congr
    intro kp _
    exact bitstringPolynomialHash_collision_iff_eval p n kp b₁ b₂
  rw [h_filter_eq]
  -- Step 2 — show the rewritten filter is the product
  -- `(roots-set on k) ×ˢ Finset.univ`.
  set S : Finset (ZMod p) := Finset.univ.filter (fun k : ZMod p =>
    evalAtBitstring p n k b₁ = evalAtBitstring p n k b₂) with hS_def
  have h_filter_product :
      Finset.univ.filter
        (fun kp : ZMod p × ZMod p =>
          evalAtBitstring p n kp.1 b₁ = evalAtBitstring p n kp.1 b₂)
      = S ×ˢ (Finset.univ : Finset (ZMod p)) := by
    ext kp
    simp [hS_def, Finset.mem_product]
  rw [h_filter_product]
  -- Step 3 — cardinality of the product is the product of cardinalities.
  rw [Finset.card_product]
  -- Step 4 — bound: |S| ≤ n, |Finset.univ : Finset (ZMod p)| = p.
  have hS_le : S.card ≤ n := bitstringDiffPolynomial_collision_keys_card_le p n h_ne
  have h_univ : (Finset.univ : Finset (ZMod p)).card = p := by
    rw [Finset.card_univ, ZMod.card]
  rw [h_univ]
  exact Nat.mul_le_mul_right _ hS_le

-- ============================================================================
-- WU-β.11 — Headline universality
-- ============================================================================

/-- **Headline universal-hash theorem (R-13).** The bitstring polynomial
    hash family is `(n / p)`-universal over the prime field `ZMod p`.

    **Proof.** Apply `IsEpsilonUniversal.ofCollisionCardBound` with
    `C = n · p` (the collision-card bound from
    `bitstringPolynomialHash_collision_card_le`). The keyspace has
    cardinality `p²` (`Fintype.card (ZMod p × ZMod p) = p · p` via
    `ZMod.card` + `Fintype.card_prod`). Arithmetic: `(n · p) / p² =
    n / p`.

    **Honest scope.** The bound `(n : ℝ≥0∞) / p` is *informative*
    only when `n ≤ p` (giving `≤ 1`). For `n > p`, the bound is
    trivially universal. Deployment must pin `p ≥ n` (typically
    `p ≫ n`) to obtain meaningful security; the universality proof
    itself doesn't carry this side condition because Mathlib's
    `IsEpsilonUniversal.ofCollisionCardBound` accepts any bound. -/
theorem bitstringPolynomialHash_isUniversal (p n : ℕ) [Fact (Nat.Prime p)] :
    IsEpsilonUniversal (bitstringPolynomialHash p n)
      ((n : ℝ≥0∞) / (p : ℝ≥0∞)) := by
  -- Apply the generic collision-card sufficient-condition lemma.
  have h := IsEpsilonUniversal.ofCollisionCardBound
    (h := bitstringPolynomialHash p n) (C := n * p)
    (fun b₁ b₂ h_ne =>
      bitstringPolynomialHash_collision_card_le p n h_ne)
  -- Rewrite the resulting bound `(n*p) / |ZMod p × ZMod p| = n / p`.
  have h_card : (Fintype.card (ZMod p × ZMod p) : ℝ≥0∞)
              = (p : ℝ≥0∞) * (p : ℝ≥0∞) := by
    rw [Fintype.card_prod, ZMod.card]
    push_cast
    rfl
  -- Re-shape the bound.
  have h_prime : Nat.Prime p := Fact.out
  have h_pos : 0 < p := h_prime.pos
  have h_p_ne_zero : (p : ℝ≥0∞) ≠ 0 := by exact_mod_cast h_pos.ne'
  have h_p_ne_top : (p : ℝ≥0∞) ≠ ⊤ := ENNReal.natCast_ne_top p
  -- Goal-bound rewrite: (n*p) / (p*p) = n / p.
  apply IsEpsilonUniversal.mono _ h
  -- Need: (↑(n * p)) / ↑(Fintype.card (ZMod p × ZMod p)) ≤ ↑n / ↑p
  rw [h_card]
  -- Goal: ↑(n * p) / (↑p * ↑p) ≤ ↑n / ↑p
  push_cast
  -- Goal: ↑n * ↑p / (↑p * ↑p) ≤ ↑n / ↑p
  rw [ENNReal.mul_div_mul_right (n : ℝ≥0∞) (p : ℝ≥0∞) h_p_ne_zero h_p_ne_top]

-- ============================================================================
-- WU-β.12 — Concrete MAC instance
-- ============================================================================

/-- **`Bitstring n`-typed MAC** built from `bitstringPolynomialHash` via
    the deterministic-tag template. Both `correct` and `verify_inj`
    discharge by `deterministicTagMAC` (Carter–Wegman analogue). The
    universal-hash property is a *separate* theorem
    (`bitstringPolynomialHash_isUniversal`), available to consumers
    needing the per-pair collision bound. -/
def bitstringPolynomialMAC (p n : ℕ) [Fact (Nat.Prime p)] :
    MAC (ZMod p × ZMod p) (Bitstring n) (ZMod p) :=
  deterministicTagMAC (bitstringPolynomialHash p n)

-- ============================================================================
-- WU-β.13 — AEAD composition
-- ============================================================================

/-- **AEAD composition for `Bitstring n` ciphertexts.** Compose any
    `OrbitKEM G (Bitstring n) (ZMod p × ZMod p)` (where the keyspace
    matches the MAC's key type `ZMod p × ZMod p`) with
    `bitstringPolynomialMAC p n`, yielding an authenticated KEM
    typed at HGOE's natural ciphertext space.

    This is the **direct R-13 composition** that the post-Workstream-A
    `carterWegmanMAC_int_ctxt` could not provide because that theorem
    is typed at `X = ZMod p` (not `Bitstring n`). -/
def bitstringPolynomial_authKEM {G : Type*} [Group G] (p n : ℕ)
    [Fact (Nat.Prime p)] [MulAction G (Bitstring n)]
    (kem : OrbitKEM G (Bitstring n) (ZMod p × ZMod p)) :
    AuthOrbitKEM G (Bitstring n) (ZMod p × ZMod p) (ZMod p) where
  kem := kem
  mac := bitstringPolynomialMAC p n

-- ============================================================================
-- WU-β.14 — Headline INT-CTXT
-- ============================================================================

/-- **Headline INT-CTXT for `Bitstring n`-typed authenticated KEM.**

    Direct application of `authEncrypt_is_int_ctxt` (Workstream B of
    audit 2026-04-23): post-B, `INT_CTXT` carries a per-challenge
    orbit-cover precondition on the game itself, so the theorem
    discharges *unconditionally* on every `AuthOrbitKEM`. This is
    the consumer-facing **Standalone**-grade result for HGOE-typed
    authenticated encryption.

    **Significance.** Closes audit finding V1-7 / D4 / I-08 / R-13
    (`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 18,
    `docs/planning/AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md`
    § 8.1). Pre-R-13, the only ciphertext-integrity result in-tree
    was `carterWegmanMAC_int_ctxt`, typed at `X = ZMod p` and
    incompatible with HGOE's `Bitstring n` ciphertext space. R-13
    closes the gap by generalising Carter–Wegman to a
    polynomial-evaluation hash typed at `Bitstring n`. -/
theorem bitstringPolynomialMAC_int_ctxt {G : Type*} [Group G]
    (p n : ℕ) [Fact (Nat.Prime p)] [MulAction G (Bitstring n)]
    (kem : OrbitKEM G (Bitstring n) (ZMod p × ZMod p)) :
    INT_CTXT (bitstringPolynomial_authKEM p n kem) :=
  -- Post-Workstream-B `authEncrypt_is_int_ctxt` is unconditional.
  authEncrypt_is_int_ctxt (bitstringPolynomial_authKEM p n kem)

end Orbcrypt








