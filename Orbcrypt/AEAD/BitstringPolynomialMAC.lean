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
* `docs/dev_history/AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md`
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
    `docs/dev_history/AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md`
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

-- ============================================================================
-- Workstream R-13⁺ — Bitstring-polynomial SU2 + SUF-CMA + Q-time NEGATIVE
-- (audit 2026-04-29 § 8.1, research-scope discharge plan
-- `docs/dev_history/PLAN_R_01_07_08_14_16.md` § R-13⁺)
-- ============================================================================

/-- **Shifted-difference polynomial.** `bitstringDiffPolynomial p n b₁ b₂ -
    C δ` is the polynomial `Δ(X) - δ` whose roots are exactly the
    `k₁` values satisfying `evalAtBitstring p n k₁ b₁ -
    evalAtBitstring p n k₁ b₂ = δ`. -/
private noncomputable def bitstringDiffPolynomialShifted
    (p n : ℕ) [Fact (Nat.Prime p)]
    (b₁ b₂ : Bitstring n) (δ : ZMod p) : Polynomial (ZMod p) :=
  bitstringDiffPolynomial p n b₁ b₂ - Polynomial.C δ

/-- **Shifted polynomial preserves the degree bound.** Subtracting a
    constant `C δ` doesn't increase the natDegree beyond the original
    polynomial's degree. -/
private theorem bitstringDiffPolynomialShifted_natDegree_le
    (p n : ℕ) [Fact (Nat.Prime p)]
    (b₁ b₂ : Bitstring n) (δ : ZMod p) :
    (bitstringDiffPolynomialShifted p n b₁ b₂ δ).natDegree ≤ n := by
  unfold bitstringDiffPolynomialShifted
  -- `(P - C δ).natDegree ≤ max P.natDegree (C δ).natDegree`.
  -- `(C δ).natDegree ≤ 0`, and original P has natDegree ≤ n.
  have h_left : (bitstringDiffPolynomial p n b₁ b₂).natDegree ≤ n :=
    bitstringDiffPolynomial_natDegree_le p n b₁ b₂
  have h_right : (Polynomial.C δ).natDegree ≤ n := by
    rw [Polynomial.natDegree_C]
    omega
  exact (Polynomial.natDegree_sub_le _ _).trans (max_le h_left h_right)

/-- **Shifted polynomial is non-zero for `b₁ ≠ b₂`.** When `Δ` has a
    non-zero coefficient at position `i₀ + 1` (where bits disagree),
    so does `Δ - C δ`: the constant `δ` only affects coefficient
    position 0, but the disagreement is at a strictly positive
    position `i₀ + 1`. -/
private theorem bitstringDiffPolynomialShifted_ne_zero_of_ne
    (p n : ℕ) [Fact (Nat.Prime p)]
    {b₁ b₂ : Bitstring n} (h_ne : b₁ ≠ b₂) (δ : ZMod p) :
    bitstringDiffPolynomialShifted p n b₁ b₂ δ ≠ 0 := by
  -- Find a disagreeing position i₀.
  obtain ⟨i₀, h_disagree⟩ := Function.ne_iff.mp h_ne
  intro h_zero
  -- The coefficient at i₀ + 1 of the shifted polynomial equals the
  -- coefficient at i₀ + 1 of the original difference polynomial,
  -- because subtracting `C δ` only changes coefficient 0.
  have h_coeff_eq :
      (bitstringDiffPolynomialShifted p n b₁ b₂ δ).coeff (i₀.val + 1) =
      (bitstringDiffPolynomial p n b₁ b₂).coeff (i₀.val + 1) := by
    unfold bitstringDiffPolynomialShifted
    rw [Polynomial.coeff_sub, Polynomial.coeff_C]
    -- coeff of `C δ` at `i₀.val + 1`: i₀.val + 1 ≥ 1 > 0, so = 0.
    -- Coefficient of `C δ` at position `i₀.val + 1 ≥ 1` is `0` (only
    -- coeff 0 is non-zero). Closed by `simp` directly via
    -- `Polynomial.coeff_C` + `if_neg` on `i₀.val + 1 ≠ 0`.
    simp
  -- Now h_zero says shifted poly is 0, so its coeff at i₀.val + 1 is 0.
  have h_shifted_coeff :
      (bitstringDiffPolynomialShifted p n b₁ b₂ δ).coeff (i₀.val + 1) = 0 := by
    rw [h_zero]
    exact Polynomial.coeff_zero _
  rw [h_coeff_eq] at h_shifted_coeff
  -- This means original Δ has 0 coefficient at i₀.val + 1, contradicting
  -- the disagreement at position i₀.
  rw [bitstringDiffPolynomial_coeff_at] at h_shifted_coeff
  have h_eq : toBit p (b₁ i₀) = toBit p (b₂ i₀) := sub_eq_zero.mp h_shifted_coeff
  haveI : NeZero p := ⟨(Fact.out : Nat.Prime p).ne_zero⟩
  exact h_disagree (toBit_injective h_eq)

/-- **Joint-collision keys (k₁ component) bound.** For `b₁ ≠ b₂` and
    arbitrary `(t₁, t₂)`, the set of `k₁ : ZMod p` for which there
    exists *any* `k₂` making the joint event hold has cardinality at
    most `n`: such `k₁` are precisely the roots of `Δ - C(t₁ - t₂)`. -/
private theorem bitstringPolynomialHash_joint_keys_card_le
    (p n : ℕ) [Fact (Nat.Prime p)]
    {b₁ b₂ : Bitstring n} (h_ne : b₁ ≠ b₂) (t₁ t₂ : ZMod p) :
    (Finset.univ.filter (fun k : ZMod p =>
        evalAtBitstring p n k b₁ - evalAtBitstring p n k b₂ = t₁ - t₂)).card ≤ n := by
  classical
  have h_Δ_ne_zero : bitstringDiffPolynomialShifted p n b₁ b₂ (t₁ - t₂) ≠ 0 :=
    bitstringDiffPolynomialShifted_ne_zero_of_ne p n h_ne (t₁ - t₂)
  -- The filter ⊆ root-set of Δ via `Δ.eval k = 0 ↔ collision-eq k`.
  have h_subset :
      (Finset.univ.filter (fun k : ZMod p =>
          evalAtBitstring p n k b₁ - evalAtBitstring p n k b₂ = t₁ - t₂)) ⊆
      (bitstringDiffPolynomialShifted p n b₁ b₂ (t₁ - t₂)).roots.toFinset := by
    intro k hk
    rw [Finset.mem_filter] at hk
    rw [Multiset.mem_toFinset, Polynomial.mem_roots h_Δ_ne_zero]
    show (bitstringDiffPolynomialShifted p n b₁ b₂ (t₁ - t₂)).eval k = 0
    unfold bitstringDiffPolynomialShifted
    rw [Polynomial.eval_sub, Polynomial.eval_C, bitstringDiffPolynomial_eval, hk.2]
    ring
  calc (Finset.univ.filter (fun k : ZMod p =>
          evalAtBitstring p n k b₁ - evalAtBitstring p n k b₂ = t₁ - t₂)).card
      ≤ (bitstringDiffPolynomialShifted p n b₁ b₂ (t₁ - t₂)).roots.toFinset.card :=
        Finset.card_le_card h_subset
    _ ≤ Multiset.card (bitstringDiffPolynomialShifted p n b₁ b₂ (t₁ - t₂)).roots :=
        Multiset.toFinset_card_le _
    _ ≤ (bitstringDiffPolynomialShifted p n b₁ b₂ (t₁ - t₂)).natDegree :=
        Polynomial.card_roots' _
    _ ≤ n := bitstringDiffPolynomialShifted_natDegree_le p n b₁ b₂ (t₁ - t₂)

/-- **Joint-collision card bound on `ZMod p × ZMod p`.** For `b₁ ≠ b₂`
    and arbitrary `(t₁, t₂)`, the joint-collision filter has card ≤ n.

    **Proof structure.** Each k₁ admitting any joint-collision must
    satisfy `Δ(k₁) - (t₁ - t₂) = 0` (≤ n such k₁). For each such k₁,
    `k.2` is uniquely determined by `k.2 = t₁ - eval(b₁, k.1)`. So the
    joint filter is in bijection with a subset of valid k₁ values. -/
private theorem bitstringPolynomialHash_joint_collision_card_le
    (p n : ℕ) [Fact (Nat.Prime p)]
    {b₁ b₂ : Bitstring n} (h_ne : b₁ ≠ b₂) (t₁ t₂ : ZMod p) :
    (Finset.univ.filter
      (fun k : ZMod p × ZMod p =>
        bitstringPolynomialHash p n k b₁ = t₁ ∧
        bitstringPolynomialHash p n k b₂ = t₂)).card ≤ n := by
  classical
  -- Define the projection: any joint-collision (k₁, k₂) must have k₁ in
  -- the joint-keys filter, and k₂ uniquely determined.
  -- We bound the joint filter's card by `card (joint-keys-on-k₁)`.
  have h_inj_on_k1 :
      Set.InjOn (fun k : ZMod p × ZMod p => k.1)
        ((Finset.univ.filter
          (fun k : ZMod p × ZMod p =>
            bitstringPolynomialHash p n k b₁ = t₁ ∧
            bitstringPolynomialHash p n k b₂ = t₂)) : Set _) := by
    intro k hk k' hk' h_eq_k1
    -- hk, hk' : both are in the joint filter.
    simp only [Finset.coe_filter, Finset.mem_univ, true_and,
      Set.mem_setOf_eq] at hk hk'
    obtain ⟨h_k_eq₁, _⟩ := hk
    obtain ⟨h_k'_eq₁, _⟩ := hk'
    -- After β-reducing the projection, h_eq_k1 becomes k.1 = k'.1.
    have h_proj : k.1 = k'.1 := h_eq_k1
    -- From h_k_eq₁, h_k'_eq₁, both k.2 and k'.2 equal t₁ - eval(k.1, b₁).
    apply Prod.ext h_proj
    -- Goal: k.2 = k'.2.
    have h_k_eq : k.2 = t₁ - evalAtBitstring p n k.1 b₁ := by
      unfold bitstringPolynomialHash at h_k_eq₁
      linear_combination h_k_eq₁
    have h_k'_eq : k'.2 = t₁ - evalAtBitstring p n k'.1 b₁ := by
      unfold bitstringPolynomialHash at h_k'_eq₁
      linear_combination h_k'_eq₁
    rw [h_k_eq, h_k'_eq, h_proj]
  -- The image of joint-collision under proj_1 is contained in joint-keys.
  have h_image_subset :
      (Finset.univ.filter
        (fun k : ZMod p × ZMod p =>
          bitstringPolynomialHash p n k b₁ = t₁ ∧
          bitstringPolynomialHash p n k b₂ = t₂)).image (fun k => k.1) ⊆
      Finset.univ.filter (fun k₁ : ZMod p =>
        evalAtBitstring p n k₁ b₁ - evalAtBitstring p n k₁ b₂ = t₁ - t₂) := by
    intro k₁ hk₁
    simp only [Finset.mem_image, Finset.mem_filter, Finset.mem_univ,
      true_and] at hk₁
    obtain ⟨⟨k1', k2'⟩, ⟨h_eq₁, h_eq₂⟩, h_proj⟩ := hk₁
    -- h_proj : k1' = k₁
    subst h_proj
    -- h_eq₁ : k.2 + eval b₁ k.1 = t₁, h_eq₂ : k.2 + eval b₂ k.1 = t₂.
    -- Subtract: eval b₁ k.1 - eval b₂ k.1 = t₁ - t₂.
    simp only [Finset.mem_filter, Finset.mem_univ, true_and]
    unfold bitstringPolynomialHash at h_eq₁ h_eq₂
    linear_combination h_eq₁ - h_eq₂
  -- Now: joint card = image card (by injectivity) ≤ joint-keys card ≤ n.
  calc (Finset.univ.filter
          (fun k : ZMod p × ZMod p =>
            bitstringPolynomialHash p n k b₁ = t₁ ∧
            bitstringPolynomialHash p n k b₂ = t₂)).card
      = ((Finset.univ.filter
          (fun k : ZMod p × ZMod p =>
            bitstringPolynomialHash p n k b₁ = t₁ ∧
            bitstringPolynomialHash p n k b₂ = t₂)).image (fun k => k.1)).card :=
        (Finset.card_image_of_injOn h_inj_on_k1).symm
    _ ≤ (Finset.univ.filter (fun k₁ : ZMod p =>
            evalAtBitstring p n k₁ b₁ - evalAtBitstring p n k₁ b₂ = t₁ - t₂)).card :=
        Finset.card_le_card h_image_subset
    _ ≤ n := bitstringPolynomialHash_joint_keys_card_le p n h_ne t₁ t₂

/-- **R-13⁺ SU2 headline.** The bitstring polynomial hash family is
    `(n / p)`-SU2 over the prime field `ZMod p`. The joint-collision
    analysis bounds the joint-card by `n` (degree-≤-n shifted
    difference polynomial); applied to the framework's `ofJointCollision
    CardBound` with `C = n` and `|Tag| = p`, `|K| = p²`, gives
    `(n · p) / p² = n / p`. -/
theorem bitstringPolynomialHash_isEpsilonSU2 (p n : ℕ) [Fact (Nat.Prime p)] :
    IsEpsilonSU2 (bitstringPolynomialHash p n) ((n : ℝ≥0∞) / (p : ℝ≥0∞)) := by
  have h_prime : Nat.Prime p := Fact.out
  have h_pos : 0 < p := h_prime.pos
  have h_p_ne_zero : (p : ℝ≥0∞) ≠ 0 := by exact_mod_cast h_pos.ne'
  have h_p_ne_top : (p : ℝ≥0∞) ≠ ⊤ := ENNReal.natCast_ne_top p
  have h := IsEpsilonSU2.ofJointCollisionCardBound
    (h := bitstringPolynomialHash p n) (C := n)
    (fun b₁ b₂ t₁ t₂ h_ne =>
      bitstringPolynomialHash_joint_collision_card_le p n h_ne t₁ t₂)
  -- h : IsEpsilonSU2 _ ((n : ℝ≥0∞) * |Tag| / |K|).
  -- Need: IsEpsilonSU2 _ (n / p).
  apply IsEpsilonSU2.mono _ h
  -- Goal: (n * |ZMod p|) / |ZMod p × ZMod p| ≤ n / p.
  rw [Fintype.card_prod, ZMod.card]
  push_cast
  -- Goal: (n : ℝ≥0∞) * p / (p * p) ≤ n / p.
  apply le_of_eq
  rw [ENNReal.mul_div_mul_right (n : ℝ≥0∞) (p : ℝ≥0∞) h_p_ne_zero h_p_ne_top]

/-- **R-13⁺ AXU corollary.** The bitstring polynomial hash family is
    `(n / p)`-AXU, derived directly from SU2 via
    `IsEpsilonSU2.toIsEpsilonAXU`. -/
theorem bitstringPolynomialHash_isEpsilonAXU (p n : ℕ) [Fact (Nat.Prime p)] :
    IsEpsilonAXU (bitstringPolynomialHash p n) ((n : ℝ≥0∞) / (p : ℝ≥0∞)) :=
  (bitstringPolynomialHash_isEpsilonSU2 p n).toIsEpsilonAXU

/-- **R-13⁺ 1-time SUF-CMA headline.** `bitstringPolynomialMAC p n` is
    `(n / p)`-SUF-CMA-secure (1-time): every adversary's forgery
    advantage is at most `n / p`.

    **Honest scope.** The bound is informative for `n ≤ p` (giving
    `≤ 1`); for `n > p` the bound is trivially universal. Deployment
    must pin `p ≥ n` (typically `p ≫ n`) to obtain meaningful security.

    **Composition.** Composes the framework reduction
    `isSUFCMASecure_of_isEpsilonSU2` with the R-13⁺ SU2 specialisation
    plus the trivial witness `IsDeterministicTagMAC
    (bitstringPolynomialMAC p n)` (which holds by `rfl` per the body
    of `deterministicTagMAC`). -/
theorem bitstringPolynomialMAC_isSUFCMASecure (p n : ℕ) [Fact (Nat.Prime p)] :
    IsSUFCMASecure (bitstringPolynomialMAC p n) ((n : ℝ) / p) := by
  have h_det : IsDeterministicTagMAC (bitstringPolynomialMAC p n) := fun _ _ _ => rfl
  have h_su2 : IsEpsilonSU2 (bitstringPolynomialMAC p n).tag
      ((n : ℝ≥0∞) / (p : ℝ≥0∞)) :=
    bitstringPolynomialHash_isEpsilonSU2 p n
  have h_finite : ((n : ℝ≥0∞) / (p : ℝ≥0∞)) ≠ ⊤ := by
    have h_prime : Nat.Prime p := Fact.out
    have h_p_ne_zero : (p : ℝ≥0∞) ≠ 0 := by exact_mod_cast h_prime.pos.ne'
    rw [ENNReal.div_eq_inv_mul]
    have h_inv_ne_top : (p : ℝ≥0∞)⁻¹ ≠ ⊤ := ENNReal.inv_ne_top.mpr h_p_ne_zero
    exact ENNReal.mul_ne_top h_inv_ne_top (ENNReal.natCast_ne_top n)
  have h := isSUFCMASecure_of_isEpsilonSU2 (bitstringPolynomialMAC p n) h_det
    ((n : ℝ≥0∞) / p) h_finite h_su2
  -- Convert ((n : ℝ≥0∞) / p).toReal to (n : ℝ) / p.
  have h_toReal : ((n : ℝ≥0∞) / (p : ℝ≥0∞)).toReal = (n : ℝ) / p := by
    rw [ENNReal.toReal_div, ENNReal.toReal_natCast, ENNReal.toReal_natCast]
  rw [h_toReal] at h
  exact h

/-- **Bitstring-polynomial key-recovery procedure.** With Q = 2 queries
    on the witness messages `e₀` (the bitstring `(true, false, ..., false)`)
    and `0` (the all-false bitstring), the honest tags are:

      - `t_e₀ = k.2 + toBit(true) · k.1 + 0 + ... + 0 = k.2 + k.1`
      - `t_0  = k.2 + 0 + ... + 0 = k.2`

    Recovery: `k.1 = t_e₀ - t_0`, `k.2 = t_0`. Same closed form as
    Carter–Wegman.

    Requires `n ≥ 1` so that position 0 exists in the bitstring. -/
private noncomputable def bitstringPolynomialRecover (p : ℕ)
    [Fact (Nat.Prime p)] :
    (Fin 2 → ZMod p) → Option (ZMod p × ZMod p) :=
  fun tags => some (tags 0 - tags 1, tags 1)

/-- **R-13⁺ key-recovery witness.** `bitstringPolynomialHash` is
    key-recoverable from `Q = 2` queries on the witness messages
    `e₀` (one-hot at position 0) and `0` (the all-false bitstring).

    Requires `n ≥ 1` (for position 0 to exist) and `p ≥ 2` (for the
    field `ZMod p` to admit non-zero elements; automatic when prime). -/
theorem bitstringPolynomialHash_isKeyRecoverableForSomeQueries
    (p n : ℕ) [Fact (Nat.Prime p)] (h_n_pos : 1 ≤ n) :
    IsKeyRecoverableForSomeQueries (bitstringPolynomialHash p n) 2 := by
  -- Witness e₀ : Bitstring n is the indicator of position 0.
  let e0 : Bitstring n := fun i => decide (i.val = 0)
  -- Witness 0 : Bitstring n is the all-false bitstring.
  let zero_bs : Bitstring n := fun _ => false
  -- These differ: at position ⟨0, h_n_pos⟩, e0 is true and zero_bs is false.
  have h_e0_ne_zero : e0 ≠ zero_bs := by
    intro h_eq
    have h_apply : e0 ⟨0, h_n_pos⟩ = zero_bs ⟨0, h_n_pos⟩ := by
      rw [h_eq]
    show False
    simp [e0, zero_bs] at h_apply
  -- Refine with msgs = ![e0, zero_bs], recover = bitstringPolynomialRecover.
  refine ⟨![e0, zero_bs], bitstringPolynomialRecover p, ?_, ?_⟩
  · -- Injectivity of msgs. Since ![e0, zero_bs] 0 = e0 and ![e0, zero_bs] 1
    -- = zero_bs are `rfl`-level definitional, the diagonal cases close by
    -- `rfl` and the off-diagonal cases give h_eq : e0 = zero_bs (or its
    -- symm), contradicting h_e0_ne_zero.
    intro i j h_eq
    fin_cases i <;> fin_cases j
    · rfl
    · exact absurd h_eq h_e0_ne_zero
    · exact absurd h_eq.symm h_e0_ne_zero
    · rfl
  · -- For every key k, recover (honest tags) = some k.
    intro k
    -- Compute tags 0 = h k e₀ = k.2 + k.1, tags 1 = h k 0 = k.2.
    -- Recover: (tags 0 - tags 1, tags 1) = (k.1, k.2) = k.
    show bitstringPolynomialRecover p
        (fun i => bitstringPolynomialHash p n k (![e0, zero_bs] i)) = some k
    simp only [bitstringPolynomialRecover, Matrix.cons_val_zero,
      Matrix.cons_val_one]
    -- Compute h k e₀ = k.2 + evalAtBitstring p n k.1 e₀.
    -- evalAtBitstring p n k.1 e₀ = ∑ i, toBit (e₀ i) · k.1^(i+1).
    -- Since e₀ i = decide (i.val = 0), the sum collapses to position 0:
    --   toBit true · k.1^1 + ∑ (i ≥ 1), 0 · k.1^(i+1) = k.1.
    have h_eval_e0 : evalAtBitstring p n k.1 e0 = k.1 := by
      unfold evalAtBitstring
      rw [show (fun i : Fin n => toBit p (e0 i) * k.1 ^ (i.val + 1)) =
            (fun i : Fin n =>
              if i = ⟨0, h_n_pos⟩ then k.1 else 0) from ?_]
      · rw [Finset.sum_ite_eq']
        simp
      funext i
      by_cases h_i : i = ⟨0, h_n_pos⟩
      · subst h_i
        simp [e0, toBit]
      · -- i ≠ ⟨0, _⟩, so i.val ≠ 0, so e0 i = false, so toBit = 0.
        have h_val_ne : i.val ≠ 0 := by
          intro h_val
          apply h_i
          ext
          exact h_val
        simp [e0, toBit, h_val_ne, h_i]
    -- evalAtBitstring p n k.1 zero_bs = 0 (already proved).
    have h_eval_zero : evalAtBitstring p n k.1 zero_bs = 0 := by
      apply evalAtBitstring_zero
    -- Compute the two hashes.
    have h_hash_e0 : bitstringPolynomialHash p n k e0 = k.2 + k.1 := by
      rw [bitstringPolynomialHash_apply, h_eval_e0]
    have h_hash_zero : bitstringPolynomialHash p n k zero_bs = k.2 := by
      rw [bitstringPolynomialHash_apply, h_eval_zero, add_zero]
    rw [h_hash_e0, h_hash_zero]
    -- Goal: some (k.2 + k.1 - k.2, k.2) = some k.
    congr 1
    apply Prod.ext
    · show k.2 + k.1 - k.2 = k.1
      ring
    · rfl

/-- **R-13⁺ Q-time NEGATIVE result.** For `n ≥ 2` and any prime `p`,
    `bitstringPolynomialMAC p n` is **not** `ε`-Q-time-SUF-CMA-secure
    for any `ε < 1`. The (Q+1)-time adversary at `Q = 2` queries
    recovers the key by the linear-system inversion in
    `bitstringPolynomialRecover`, then forges deterministically on
    a fresh bitstring.

    **Cardinality side condition.** `n ≥ 2` ensures `|Bitstring n|
    = 2^n ≥ 4 > 3 = Q + 1`, so the framework's `Q + 1 < |Msg|`
    requirement is satisfied. Recovery itself only needs `n ≥ 1`,
    but the negative theorem additionally requires two fresh
    messages outside `{e₀, 0}`.

    Formalises the well-known limitation of nonce-free polynomial
    Wegman–Carter MACs: Q-time security requires fresh nonces per
    message. The Q-time *positive* bound for nonce-free
    bitstring-polynomial is mathematically false, not just unproven.
    See research milestone R-05. -/
theorem not_bitstringPolynomialMAC_isQtimeSUFCMASecure
    (p n : ℕ) [Fact (Nat.Prime p)] (h_n_ge_two : 2 ≤ n)
    (ε : ℝ) (hε : ε < 1) :
    ¬ IsQtimeSUFCMASecure (Q := 3) (bitstringPolynomialMAC p n) ε := by
  have h_det : IsDeterministicTagMAC (bitstringPolynomialMAC p n) :=
    fun _ _ _ => rfl
  have h_recover : IsKeyRecoverableForSomeQueries
      (bitstringPolynomialMAC p n).tag 2 :=
    bitstringPolynomialHash_isKeyRecoverableForSomeQueries p n (by omega)
  -- Cardinality bound: |Bitstring n| = |Fin n → Bool| = 2^n.
  -- For n ≥ 2, 2^n ≥ 4 > 3 = Q + 1.
  have h_card : 2 + 1 < Fintype.card (Bitstring n) := by
    -- Bitstring n = Fin n → Bool, |Bool|^n = 2^n.
    rw [show Fintype.card (Bitstring n) = 2 ^ n from by
      simp [Bitstring]]
    -- Goal: 3 < 2 ^ n. With n ≥ 2, 2^n ≥ 2^2 = 4.
    have h_pow : 2 ^ 2 ≤ 2 ^ n := Nat.pow_le_pow_right (by omega) h_n_ge_two
    omega
  exact not_isQtimeSUFCMASecure_of_keyRecoverableForSomeQueries
    (bitstringPolynomialMAC p n) h_det h_card h_recover ε hε

end Orbcrypt








