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
* `Orbcrypt.carterWegmanMAC` — a concrete instance over `ZMod p`: the
  Carter–Wegman universal hash `tag (k₁, k₂) m = k₁ * m + k₂`.
* `Orbcrypt.carterWegman_authKEM` — the AEAD composition of an arbitrary
  `OrbitKEM` with `carterWegmanMAC`.
* `Orbcrypt.carterWegmanMAC_int_ctxt` — specialisation of
  `authEncrypt_is_int_ctxt` to the Carter–Wegman composition.

## Scope

This is the *simplest-possible* Lean-level witness demonstrating that
`MAC.verify_inj` is satisfiable and that `INT_CTXT` is therefore inhabited.
The construction is information-theoretically weak — it is deterministic
and the tag space coincides with the key space — and is **not** intended
for production use. Real-world instantiations (HMAC, Poly1305) would
require a probabilistic refinement of the MAC interface.

## References

* docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md § 6 — Workstream C4
* Carter, J. L. & Wegman, M. N. (1979). "Universal classes of hash functions."
  J. Comput. Syst. Sci. 18(2): 143–154.
-/

set_option autoImplicit false

namespace Orbcrypt

-- ============================================================================
-- Generic `decide`-equality MAC template
-- ============================================================================

variable {K : Type*} {Msg : Type*}

/--
A deterministic MAC constructed from any tagging function `f : K → Msg → K`
whose tag space coincides with its key space. Verification tests
`t = f k m` by `decide` — which discharges both the `correct` and
`verify_inj` fields of `MAC` by reflexivity.

This is the canonical "simplest non-trivial MAC" and the intended reading of
the Workstream C4 witness obligation: a Carter–Wegman universal-hash MAC is
an instance obtained by supplying the universal-hash function as `f`.
-/
def deterministicTagMAC [DecidableEq K] (f : K → Msg → K) :
    MAC K Msg K where
  tag := f
  verify := fun k m t => decide (t = f k m)
  correct := fun k m => by
    -- `decide (f k m = f k m) = true` holds by reflexivity of equality.
    exact decide_eq_true rfl
  verify_inj := fun k m t hv => by
    -- `decide (t = f k m) = true` unfolds to `t = f k m`.
    exact of_decide_eq_true hv

-- ============================================================================
-- Carter–Wegman instance over `ZMod p`
-- ============================================================================

/--
The Carter–Wegman universal hash: `cw (k₁, k₂) m = k₁ * m + k₂` over `ZMod p`.

Named as a plain function (not bundled) so that the resulting MAC's tag
unfolds definitionally — useful for `decide`-based checks downstream.
-/
def carterWegmanHash (p : ℕ) (k : ZMod p × ZMod p) (m : ZMod p) : ZMod p :=
  k.1 * m + k.2

/--
A concrete `MAC` instance over `ZMod p` using the Carter–Wegman universal
hash as its tagging function. Both `correct` and `verify_inj` follow
immediately from the `deterministicTagMAC` template; there is no new proof
obligation at this layer.

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

variable {G : Type*} {X : Type*}
  [Group G] [MulAction G X] [DecidableEq X]

/--
Compose an `OrbitKEM` whose key type is `ZMod p × ZMod p` with the
Carter–Wegman MAC, yielding an `AuthOrbitKEM` whose tag type is `ZMod p`.

Users supply the KEM; this wrapper fixes the MAC component so that the
`INT_CTXT` proof becomes a direct application of `authEncrypt_is_int_ctxt`.
-/
def carterWegman_authKEM (p : ℕ) [NeZero p]
    (kem : OrbitKEM G X (ZMod p × ZMod p)) :
    AuthOrbitKEM G X (ZMod p × ZMod p) (ZMod p) where
  kem := kem
  mac := carterWegmanMAC p

/--
**INT-CTXT for the Carter–Wegman composition.**

Direct application of `authEncrypt_is_int_ctxt` (Workstream C2) to the
AEAD composed from any `OrbitKEM` and the Carter–Wegman MAC. The only
remaining hypothesis is the orbit-cover assumption `hOrbitCover` on the
underlying KEM — i.e., that the ciphertext space equals `orbit G basePoint`.

This is the concrete witness completing Workstream C4: `INT_CTXT` is
non-vacuously inhabited for the intended model.
-/
theorem carterWegmanMAC_int_ctxt
    (p : ℕ) [NeZero p] (kem : OrbitKEM G X (ZMod p × ZMod p))
    (hOrbitCover : ∀ c : X, c ∈ MulAction.orbit G kem.basePoint) :
    INT_CTXT (carterWegman_authKEM p kem) :=
  -- The base-point of the composed AuthOrbitKEM is the base-point of `kem`;
  -- pass `hOrbitCover` through unchanged.
  authEncrypt_is_int_ctxt (carterWegman_authKEM p kem) hOrbitCover

end Orbcrypt
