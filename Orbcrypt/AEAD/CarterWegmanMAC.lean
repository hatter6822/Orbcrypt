import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Field.ZMod
import Mathlib.Data.Nat.Prime.Basic
import Orbcrypt.AEAD.MAC
import Orbcrypt.AEAD.AEAD
import Orbcrypt.Probability.UniversalHash

/-!
# Orbcrypt.AEAD.CarterWegmanMAC

The Carter–Wegman universal-hash MAC (Carter & Wegman 1977;
Wegman & Carter 1981), formalised as a concrete `MAC` instance over
the prime field `ZMod p` with a machine-checked proof that the
underlying hash family is `(1/p)`-universal.

## Overview

* `Orbcrypt.deterministicTagMAC` — a generic MAC whose verification is
  `decide`-equality against a user-supplied tagging function. Any such
  MAC satisfies `verify_inj` by `of_decide_eq_true` and `correct` by
  `decide`-reflexivity.
* `Orbcrypt.carterWegmanHash` — the Carter–Wegman linear hash function
  `(k₁, k₂) ↦ k₁ · m + k₂` over the prime field `ZMod p`
  (`[Fact (Nat.Prime p)]`). The primality constraint makes `ZMod p` a
  field, which is the hypothesis for the 2-universal pair-collision
  analysis.
* `Orbcrypt.carterWegmanHash_collision_iff` — algebraic characterisation
  of collisions: in the prime field `F_p`, `h (k₁,k₂) m₁ = h (k₁,k₂) m₂`
  holds iff `k₁ = 0` (for `m₁ ≠ m₂`).
* `Orbcrypt.carterWegmanHash_collision_card` — counting form: the
  collision set has cardinality exactly `p`.
* `Orbcrypt.carterWegmanHash_isUniversal` — **headline theorem**: the
  Carter–Wegman hash family is `(1/p)`-universal. This is the proper
  ε-universal pair-collision bound from Carter & Wegman 1977, not a
  docstring disclaimer.
* `Orbcrypt.carterWegmanMAC` — the concrete `MAC (ZMod p × ZMod p)
  (ZMod p) (ZMod p)` built from `carterWegmanHash` via
  `deterministicTagMAC`.
* `Orbcrypt.carterWegman_authKEM` — the AEAD composition of an
  `OrbitKEM` whose ciphertext space is `ZMod p` with `carterWegmanMAC`.
* `Orbcrypt.carterWegmanMAC_int_ctxt` — specialisation of
  `authEncrypt_is_int_ctxt` to the Carter–Wegman composition.

## Primality constraint

Every `carterWegman*` definition takes a `[Fact (Nat.Prime p)]`
typeclass constraint. This is **not** a stylistic choice — it is the
mathematical precondition for the universal-hash guarantee: the proof
that `h (k₁,k₂) m₁ = h (k₁,k₂) m₂ ↔ k₁ = 0` (for `m₁ ≠ m₂`) requires
`m₁ - m₂` to be a unit, which holds precisely when `ZMod p` is a field
— i.e. when `p` is prime.

Previously (Workstream L2 landing, 2026-04-22) the constraint was the
weaker `[NeZero p]` with a docstring disclaimer that the hash shape is
**not** the cryptographic primitive. That was a naming-honesty
violation per the "Security-by-docstring prohibition" rule in
`CLAUDE.md`: if the identifier names a Carter–Wegman universal-hash
MAC, the code must **prove** the universal-hash property, not
disclaim it. This module now does prove it
(`carterWegmanHash_isUniversal`).

Mathlib provides `instance fact_prime_two : Fact (Nat.Prime 2)` and
`instance fact_prime_three : Fact (Nat.Prime 3)`, so `p = 2` and
`p = 3` resolve automatically for test-witness purposes. Larger primes
are discharged by `decide` or `Nat.prime_def_lt` when instantiating
at specific values.

## Scope

The `(1/p)`-universal bound is the information-theoretic pair-collision
probability Carter & Wegman 1977 proved. Turning this into a
computationally-secure MAC (Wegman & Carter 1981 SUF-CMA reduction)
additionally requires probabilistic key sampling plus a reduction
that bounds per-query forgery probability by the per-pair collision
probability. That reduction is layered on top of the ε-universal
Prop and is out of scope for this module — when it lands, the
ε-universality proved here will slot into it as the key hypothesis.

## References

* Carter, J. L. & Wegman, M. N. (1977). "Universal classes of hash
  functions." J. Comput. Syst. Sci. 18(2): 143–154.
* Wegman, M. N. & Carter, J. L. (1981). "New hash functions and their
  use in authentication and set equality." J. Comput. Syst. Sci. 22:
  265–279.
* docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md § 6 — Workstream C4
  (original witness-only landing).
* docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md § 7.2 — Workstream
  L2 (primality hygiene via `[NeZero p]`, 2026-04-22; superseded by
  `[Fact (Nat.Prime p)]` + universal-hash theorem in the L-workstream
  post-audit pass).
-/

set_option autoImplicit false

namespace Orbcrypt

open PMF ENNReal

-- ============================================================================
-- Generic `decide`-equality MAC template
-- ============================================================================

variable {K : Type*} {Msg : Type*} {Tag : Type*}

/--
A deterministic MAC constructed from any tagging function
`f : K → Msg → Tag`. Verification tests `t = f k m` by `decide`, which
discharges both the `correct` and `verify_inj` fields of `MAC`.

This is the canonical "simplest non-trivial MAC" and the template on
which `carterWegmanMAC` is built: supply a universal-hash function as
`f`, and the ε-universal property of the family (proved separately
against `IsEpsilonUniversal`) is preserved by the template.
-/
def deterministicTagMAC [DecidableEq Tag] (f : K → Msg → Tag) :
    MAC K Msg Tag where
  tag := f
  verify := fun k m t => decide (t = f k m)
  -- `decide (f k m = f k m) = true` holds by reflexivity of equality.
  correct := fun _ _ => decide_eq_true rfl
  -- `decide (t = f k m) = true` unfolds to `t = f k m`.
  verify_inj := fun _ _ _ hv => of_decide_eq_true hv

-- ============================================================================
-- Carter–Wegman linear hash over a prime field
-- ============================================================================

/--
The Carter–Wegman linear hash: `cw (k₁, k₂) m = k₁ · m + k₂` over the
prime field `ZMod p`.

`[Fact (Nat.Prime p)]` is a **mathematical** constraint, not a stylistic
one: it upgrades `ZMod p` to a field, enabling the universal-hash
analysis (see `carterWegmanHash_isUniversal`).

Named as a plain function (not bundled) so that the resulting MAC's
tag unfolds definitionally, enabling `decide`-based checks downstream.
-/
def carterWegmanHash (p : ℕ) [Fact (Nat.Prime p)]
    (k : ZMod p × ZMod p) (m : ZMod p) : ZMod p :=
  k.1 * m + k.2

-- ============================================================================
-- Collision analysis: the algebraic heart of the universal-hash proof
-- ============================================================================

/--
**Collision characterisation.** Over the prime field `ZMod p`, the
Carter–Wegman hash collides on distinct messages `m₁ ≠ m₂` iff the
first key component `k.1` is zero. The second component `k.2` is
irrelevant to collisions (it cancels in the difference).

**Proof.** `k₁·m₁ + k₂ = k₁·m₂ + k₂` iff `k₁·m₁ = k₁·m₂` iff
`k₁·(m₁ - m₂) = 0`. In a field, a product is zero iff a factor is
zero; since `m₁ - m₂ ≠ 0` (by hypothesis), `k₁ = 0`.

This is the sole algebraic content of the Carter–Wegman 2-universality
argument.
-/
theorem carterWegmanHash_collision_iff (p : ℕ) [Fact (Nat.Prime p)]
    {m₁ m₂ : ZMod p} (h_ne : m₁ ≠ m₂) (k : ZMod p × ZMod p) :
    carterWegmanHash p k m₁ = carterWegmanHash p k m₂ ↔ k.1 = 0 := by
  unfold carterWegmanHash
  constructor
  · intro h_eq
    -- Cancel `k.2` to get `k.1 * m₁ = k.1 * m₂`.
    have h1 : k.1 * m₁ = k.1 * m₂ := add_right_cancel h_eq
    -- Rewrite as `k.1 * (m₁ - m₂) = 0`.
    have h2 : k.1 * (m₁ - m₂) = 0 := by
      rw [mul_sub, sub_eq_zero]
      exact h1
    -- In a field, `a * b = 0 → a = 0 ∨ b = 0`. Eliminate the `b = 0`
    -- branch using `h_ne : m₁ ≠ m₂`.
    have h_sub_ne : m₁ - m₂ ≠ 0 := fun h => h_ne (sub_eq_zero.mp h)
    exact (mul_eq_zero.mp h2).resolve_right h_sub_ne
  · intro hk
    rw [hk, zero_mul, zero_mul]

/--
**Collision count.** The collision set for Carter–Wegman at distinct
messages `m₁ ≠ m₂` has cardinality exactly `p`.

**Proof.** By `carterWegmanHash_collision_iff`, the collision set equals
`{k : ZMod p × ZMod p | k.1 = 0}`. This set is in bijection with the
image of `(fun k₂ => (0, k₂))` from `ZMod p`, which has cardinality `p`
by `ZMod.card`.
-/
theorem carterWegmanHash_collision_card (p : ℕ) [Fact (Nat.Prime p)]
    {m₁ m₂ : ZMod p} (h_ne : m₁ ≠ m₂) :
    (Finset.univ.filter
      (fun k : ZMod p × ZMod p =>
        carterWegmanHash p k m₁ = carterWegmanHash p k m₂)).card = p := by
  classical
  -- Step 1: rewrite collision filter to `{k | k.1 = 0}` filter.
  have h_filter_eq :
      Finset.univ.filter
        (fun k : ZMod p × ZMod p =>
          carterWegmanHash p k m₁ = carterWegmanHash p k m₂)
      = Finset.univ.filter (fun k : ZMod p × ZMod p => k.1 = 0) := by
    apply Finset.filter_congr
    intro k _
    exact carterWegmanHash_collision_iff p h_ne k
  rw [h_filter_eq]
  -- Step 2: `{k | k.1 = 0}` = image of `(0, ·)` from ZMod p.
  have h_image :
      Finset.univ.filter (fun k : ZMod p × ZMod p => k.1 = 0)
      = (Finset.univ : Finset (ZMod p)).image (fun k₂ => ((0 : ZMod p), k₂)) := by
    ext k
    simp only [Finset.mem_filter, Finset.mem_univ, true_and,
      Finset.mem_image]
    constructor
    · intro hk1
      -- After simp-reducing `k₂ ∈ Finset.univ ↝ True`, the existential
      -- collapses to `∃ k₂, (0, k₂) = k`.  Provide `k.2` as the witness.
      refine ⟨k.2, ?_⟩
      -- Goal: (0, k.2) = k.  Extensionality on a Prod.
      apply Prod.ext
      · exact hk1.symm
      · rfl
    · rintro ⟨k₂, rfl⟩
      rfl
  rw [h_image]
  -- Step 3: image cardinality via injectivity of `(0, ·)`.
  rw [Finset.card_image_of_injective _
    (fun _ _ h => (Prod.ext_iff.mp h).2)]
  -- Step 4: Finset.univ.card = Fintype.card ZMod p = p.
  rw [Finset.card_univ, ZMod.card]

-- ============================================================================
-- Headline: Carter–Wegman is (1/p)-universal
-- ============================================================================

/--
**Carter–Wegman universal-hash theorem (Carter & Wegman 1977).** The
linear hash family `h (k₁,k₂) m = k₁·m + k₂` over the prime field
`ZMod p` is `(1/p)`-universal: for any two distinct messages `m₁ ≠ m₂`,
the probability of collision under a uniformly-random key `(k₁,k₂) ∈
ZMod p × ZMod p` is at most `1/p`.

**Proof.** The collision set for `m₁ ≠ m₂` has cardinality exactly `p`
(`carterWegmanHash_collision_card`). The keyspace `ZMod p × ZMod p` has
cardinality `p²`. The collision probability is therefore exactly
`p / p² = 1/p`.

**Significance.** This is the **cryptographic foundation** the name
"Carter–Wegman MAC" promises. In combination with probabilistic key
sampling (Wegman–Carter 1981, out of scope for this module), this
delivers an unconditionally-secure one-time MAC with forgery
probability `≤ 1/p` per query against a computationally unbounded
adversary.
-/
theorem carterWegmanHash_isUniversal (p : ℕ) [Fact (Nat.Prime p)] :
    IsEpsilonUniversal (carterWegmanHash p) ((1 : ℝ≥0∞) / (p : ℕ)) := by
  -- `Fintype (ZMod p × ZMod p)` and `Nonempty (ZMod p × ZMod p)` are
  -- auto-derived from the prime Fact. Extract positivity of `p`.
  have h_prime : Nat.Prime p := Fact.out
  have h_pos : 0 < p := h_prime.pos
  have h_ne_zero : (p : ℝ≥0∞) ≠ 0 := by
    exact_mod_cast h_pos.ne'
  have h_ne_top : (p : ℝ≥0∞) ≠ ⊤ := ENNReal.natCast_ne_top p
  intro m₁ m₂ h_ne
  -- Express the Bool probTrue as a Finset.card / Fintype.card quotient.
  rw [probTrue_uniformPMF_decide_eq]
  -- Goal: (collision_card : ℝ≥0∞) / Fintype.card (ZMod p × ZMod p) ≤ 1 / p
  rw [carterWegmanHash_collision_card p h_ne]
  -- Goal: (p : ℝ≥0∞) / Fintype.card (ZMod p × ZMod p) ≤ 1 / p
  rw [Fintype.card_prod, ZMod.card]
  -- Goal: (p : ℝ≥0∞) / (p * p : ℕ) ≤ 1 / p.  Push cast and reduce to equality.
  push_cast
  apply le_of_eq
  -- Subgoal: (p : ℝ≥0∞) / ((p : ℝ≥0∞) * p) = 1 / p.
  -- Rewrite both sides to `p⁻¹`.
  rw [one_div, ENNReal.div_eq_inv_mul,
      ENNReal.mul_inv (Or.inl h_ne_zero) (Or.inl h_ne_top),
      mul_assoc, ENNReal.inv_mul_cancel h_ne_zero h_ne_top, mul_one]

-- ============================================================================
-- The Carter–Wegman MAC and its INT-CTXT composition
-- ============================================================================

/--
A concrete `MAC` instance over `ZMod p` (with `[Fact (Nat.Prime p)]`)
using the Carter–Wegman linear hash as its tagging function.

Both the `correct` and `verify_inj` fields are discharged by
`deterministicTagMAC`. The universal-hash property is a **separate**
theorem (`carterWegmanHash_isUniversal`), available to consumers who
need the per-pair collision bound for downstream Wegman–Carter MAC
reductions.

**Why `[Fact (Nat.Prime p)]`?** See the module docstring. In short:
the universal-hash guarantee requires `p` prime so that `ZMod p` is a
field. Dropping this constraint to `[NeZero p]` would give the MAC
data structure without the universal-hash Prop it needs; the name
`carterWegmanMAC` would then mislead downstream callers.

**Satisfiability witness (audit F-07, Workstream C4):** inhabiting
`MAC (ZMod p × ZMod p) (ZMod p) (ZMod p)` discharges the `verify_inj`
requirement introduced in Workstream C1.
-/
def carterWegmanMAC (p : ℕ) [Fact (Nat.Prime p)] :
    MAC (ZMod p × ZMod p) (ZMod p) (ZMod p) :=
  deterministicTagMAC (carterWegmanHash p)

/--
Compose an `OrbitKEM` whose ciphertext space is `ZMod p` (`p` prime) and
key type is `ZMod p × ZMod p` with the Carter–Wegman MAC, yielding an
`AuthOrbitKEM` whose tag type is `ZMod p`.

The ciphertext type is fixed to `ZMod p` because the MAC's `Msg` type
must equal the KEM's `X`. Consumers must therefore supply a KEM whose
ciphertext space is literally `ZMod p` — typically via an explicit
`MulAction G (ZMod p)` instance.
-/
def carterWegman_authKEM {G : Type*} [Group G] (p : ℕ) [Fact (Nat.Prime p)]
    [MulAction G (ZMod p)]
    (kem : OrbitKEM G (ZMod p) (ZMod p × ZMod p)) :
    AuthOrbitKEM G (ZMod p) (ZMod p × ZMod p) (ZMod p) where
  kem := kem
  mac := carterWegmanMAC p

/--
**INT-CTXT for the Carter–Wegman composition.**

Direct application of `authEncrypt_is_int_ctxt` (Workstream C2) to
the AEAD composed from any `OrbitKEM` on ciphertext space `ZMod p`
and the Carter–Wegman MAC. Post-audit 2026-04-23 Workstream B, this
is an unconditional specialisation — the orbit-cover hypothesis that
the pre-B formulation carried has been absorbed into the game's
per-challenge well-formedness precondition on `INT_CTXT` itself (see
`Orbcrypt/AEAD/AEAD.lean` for the refactor).

This is the concrete witness completing Workstream C4: `INT_CTXT` is
non-vacuously inhabited for the intended model, with the orbit
condition now living on each `INT_CTXT` challenge rather than as a
theorem-level assumption.

**HGOE compatibility (audit 2026-04-23 finding V1-7 / D4 / I-08 /
Workstream A).** This theorem's ciphertext type is `ZMod p` — it is
**not** directly compatible with HGOE's `Bitstring n = Fin n → Bool`
ciphertext space. Composing Carter–Wegman with an HGOE `OrbitKEM G
(Bitstring n) K` requires an auxiliary `Bitstring n → ZMod p` adapter
that preserves the orbit structure `authEncrypt_is_int_ctxt` relies
on; no such adapter is formalised in the current release, and
building one is research-scope R-13 in
`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 18.
Release-facing citations should frame this theorem as "the
satisfiability witness for `MAC.verify_inj` and the `INT_CTXT`
pipeline on a `ZMod p`-typed composition; it does not compose with
concrete HGOE without R-13." For standalone universal-hash
citations, use `carterWegmanHash_isUniversal` (the Carter–Wegman
1977 `(1/p)`-universal property proved at `[Fact (Nat.Prime p)]`).
-/
theorem carterWegmanMAC_int_ctxt {G : Type*} [Group G]
    (p : ℕ) [Fact (Nat.Prime p)] [MulAction G (ZMod p)]
    (kem : OrbitKEM G (ZMod p) (ZMod p × ZMod p)) :
    INT_CTXT (carterWegman_authKEM p kem) :=
  -- Post-Workstream-B, `authEncrypt_is_int_ctxt` is unconditional;
  -- the orbit-cover obligation has been absorbed into the game's
  -- per-challenge precondition on `INT_CTXT` itself.
  authEncrypt_is_int_ctxt (carterWegman_authKEM p kem)

end Orbcrypt
