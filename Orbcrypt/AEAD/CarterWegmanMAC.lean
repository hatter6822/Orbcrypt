import Mathlib.Data.ZMod.Basic
import Orbcrypt.AEAD.MAC
import Orbcrypt.AEAD.AEAD

/-!
# Orbcrypt.AEAD.CarterWegmanMAC

A concrete witness for the `MAC` abstraction (audit F-07, Workstream C4):
a deterministic Carter–Wegman-style universal-hash MAC whose `verify` is
definitionally `decide (t = tag k m)`. This is the simplest construction that
discharges all four `MAC` fields, including the new `verify_inj` uniqueness
obligation introduced in Workstream C1.

## Overview

* `Orbcrypt.deterministicTagMAC` — a generic MAC whose verification is
  `decide`-equality against a user-supplied tagging function. Any such MAC
  satisfies `verify_inj` by `of_decide_eq_true`, and `correct` by `decide`-
  reflexivity.
* `Orbcrypt.carterWegmanHash` — the linear hash function
  `(k₁, k₂) ↦ k₁ * m + k₂` over `ZMod p`. Carrying the *shape* of the
  Carter–Wegman universal-hash function, but **not** its universal-hash
  *guarantee* (which requires primality of `p` and probabilistic key
  sampling).
* `Orbcrypt.carterWegmanMAC` — a concrete `MAC (ZMod p × ZMod p) (ZMod p)
  (ZMod p)` built from `carterWegmanHash` via `deterministicTagMAC`.
* `Orbcrypt.carterWegman_authKEM` — the AEAD composition of an `OrbitKEM`
  whose ciphertext space is `ZMod p` with `carterWegmanMAC`.
* `Orbcrypt.carterWegmanMAC_int_ctxt` — specialisation of
  `authEncrypt_is_int_ctxt` to the Carter–Wegman composition.

## Naming note (audit F-AUDIT-2026-04-21-M3 / Workstream L2)

The identifier `carterWegmanMAC` names the **linear hash shape**
`k₁ · m + k₂` over `ZMod p`. The Carter–Wegman universal-hash
**security guarantee** requires (i) `p` prime, (ii) probabilistic key
sampling, and (iii) a 2-universal pair-collision analysis — none of
which are asserted by this Lean definition. What the definition *does*
assert is that the resulting MAC satisfies `MAC.correct` and
`MAC.verify_inj`, which is everything `INT_CTXT` needs to elaborate.

Consumers who want the CW universal-hash property must add
`[Fact (Nat.Prime p)]` and a probabilistic-key-sampling argument **on
top of** this MAC; the base construction is the deterministic
linear-hash MAC, not the cryptographic primitive.

## Scope

This is the *simplest-possible* Lean-level witness demonstrating that
`MAC.verify_inj` is satisfiable and that `INT_CTXT` is therefore inhabited.
The construction is information-theoretically weak — it is deterministic
and the tag space coincides with `ZMod p` — and is **not** intended for
production use. Real-world instantiations (HMAC, Poly1305) would require
a probabilistic refinement of the MAC interface.

The composition `carterWegman_authKEM` specialises the ciphertext type to
`ZMod p`; in the concrete Orbcrypt use-case the ciphertext space is a
permutation orbit on `Bitstring n`, so this MAC witness is not a drop-in
replacement for the production AEAD composition. Its purpose is purely to
show that the `MAC` + `AuthOrbitKEM` + `INT_CTXT` chain is inhabitable.

## `[NeZero p]` typeclass constraint

All `carterWegman*` definitions take a `[NeZero p]` typeclass constraint
on the modulus. `ZMod 0 = ℤ` is the integer ring — infinite, not a
proper finite type, and in particular cannot support a valid universal
hash even in principle. `[NeZero p]` rules out `p = 0` at elaboration
time without demanding primality (which is over-restrictive for the
Lean `correct` and `verify_inj` obligations — both hold for any
`NeZero p`). Mathlib provides `instance : NeZero (n+1)` for every
`n : ℕ`, so `[NeZero 1]` resolves automatically for the audit script's
`p = 1` witness (`audit_c_workstream.lean`).

## References

* docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md § 6 — Workstream C4
* docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md § 7.2 — Workstream L2
  (primality hygiene via `[NeZero p]`, 2026-04-22)
* Carter, J. L. & Wegman, M. N. (1979). "Universal classes of hash functions."
  J. Comput. Syst. Sci. 18(2): 143–154.
-/

set_option autoImplicit false

namespace Orbcrypt

-- ============================================================================
-- Generic `decide`-equality MAC template
-- ============================================================================

variable {K : Type*} {Msg : Type*} {Tag : Type*}

/--
A deterministic MAC constructed from any tagging function `f : K → Msg → Tag`.
Verification tests `t = f k m` by `decide` — which discharges both the
`correct` and `verify_inj` fields of `MAC` by reflexivity.

This is the canonical "simplest non-trivial MAC" and the intended reading of
the Workstream C4 witness obligation: a Carter–Wegman universal-hash MAC is
an instance obtained by supplying the universal-hash function as `f`.
-/
def deterministicTagMAC [DecidableEq Tag] (f : K → Msg → Tag) :
    MAC K Msg Tag where
  tag := f
  verify := fun k m t => decide (t = f k m)
  -- `decide (f k m = f k m) = true` holds by reflexivity of equality;
  -- `rfl` inhabits `f k m = f k m` and `decide_eq_true` lifts it.
  correct := fun _ _ => decide_eq_true rfl
  -- `decide (t = f k m) = true` unfolds to `t = f k m`.
  verify_inj := fun _ _ _ hv => of_decide_eq_true hv

-- ============================================================================
-- Carter–Wegman instance over `ZMod p`
-- ============================================================================

/--
The Carter–Wegman linear hash shape: `cw (k₁, k₂) m = k₁ * m + k₂` over
`ZMod p`. Carries the *shape* of the Carter–Wegman universal-hash
function, but **not** its universal-hash *guarantee* (which requires
primality of `p` and probabilistic key sampling, neither of which is
asserted here).

`[NeZero p]` (audit F-AUDIT-2026-04-21-M3 / Workstream L2) rules out
`p = 0` at elaboration time — `ZMod 0 = ℤ` is the integer ring, not a
proper finite type, and admits no valid universal-hash semantics even
in principle.

Named as a plain function (not bundled) so that the resulting MAC's tag
unfolds definitionally — useful for `decide`-based checks downstream.
-/
def carterWegmanHash (p : ℕ) [NeZero p]
    (k : ZMod p × ZMod p) (m : ZMod p) : ZMod p :=
  k.1 * m + k.2

/--
A concrete `MAC` instance over `ZMod p` using the Carter–Wegman linear
hash as its tagging function. Both `correct` and `verify_inj` follow
immediately from the `deterministicTagMAC` template; there is no new proof
obligation at this layer.

`[NeZero p]` (audit F-AUDIT-2026-04-21-M3 / Workstream L2) rules out
the degenerate `ZMod 0 = ℤ` branch. The name `carterWegmanMAC` reflects
the **hash shape**, not the universal-hash security property — see the
module-level "Naming note" for details.

**Satisfiability witness (audit F-07, Workstream C4):** inhabiting
`MAC (ZMod p × ZMod p) (ZMod p) (ZMod p)` discharges the `verify_inj`
requirement introduced in Workstream C1 and therefore shows it is not
vacuous.
-/
def carterWegmanMAC (p : ℕ) [NeZero p] :
    MAC (ZMod p × ZMod p) (ZMod p) (ZMod p) :=
  deterministicTagMAC (carterWegmanHash p)

-- ============================================================================
-- Composition into an AuthOrbitKEM + `INT_CTXT` instantiation
-- ============================================================================
--
-- The composition bridge specialises the ciphertext type to `ZMod p`
-- because the MAC's `Msg` field must equal the KEM's `X`. `G` and `p`
-- vary per invocation; we declare them explicitly per-definition rather
-- than as section `variable`s so that the `MulAction G (ZMod p)` instance
-- can be threaded with the right `p`.

/--
Compose an `OrbitKEM` whose ciphertext space is `ZMod p` and key type is
`ZMod p × ZMod p` with the Carter–Wegman MAC, yielding an `AuthOrbitKEM`
whose tag type is `ZMod p`.

The ciphertext type is fixed to `ZMod p` because the MAC's `Msg` type
must equal the KEM's `X`. Consumers must therefore supply a KEM whose
ciphertext space is literally `ZMod p` — typically via an explicit
`MulAction G (ZMod p)` instance.
-/
def carterWegman_authKEM {G : Type*} [Group G] (p : ℕ) [NeZero p]
    [MulAction G (ZMod p)]
    (kem : OrbitKEM G (ZMod p) (ZMod p × ZMod p)) :
    AuthOrbitKEM G (ZMod p) (ZMod p × ZMod p) (ZMod p) where
  kem := kem
  mac := carterWegmanMAC p

/--
**INT-CTXT for the Carter–Wegman composition.**

Direct application of `authEncrypt_is_int_ctxt` (Workstream C2) to the
AEAD composed from any `OrbitKEM` on ciphertext space `ZMod p` and the
Carter–Wegman MAC. The only remaining hypothesis is the orbit-cover
assumption `hOrbitCover` on the underlying KEM — i.e., that every
`c : ZMod p` lies in `orbit G kem.basePoint`.

This is the concrete witness completing Workstream C4: `INT_CTXT` is
non-vacuously inhabited for the intended model.
-/
theorem carterWegmanMAC_int_ctxt {G : Type*} [Group G]
    (p : ℕ) [NeZero p] [MulAction G (ZMod p)]
    (kem : OrbitKEM G (ZMod p) (ZMod p × ZMod p))
    (hOrbitCover : ∀ c : ZMod p, c ∈ MulAction.orbit G kem.basePoint) :
    INT_CTXT (carterWegman_authKEM p kem) :=
  -- The base-point of the composed AuthOrbitKEM is the base-point of `kem`;
  -- pass `hOrbitCover` through unchanged.
  authEncrypt_is_int_ctxt (carterWegman_authKEM p kem) hOrbitCover

end Orbcrypt
