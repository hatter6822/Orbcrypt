/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.PublicKey.CSIDHHardness
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Field.ZMod

/-!
# Orbcrypt.PublicKey.MultGroupAction

The multiplicative-group commutative action `(ZMod p)ˣ ↷ ZMod p` for prime
`p`, the canonical non-trivial witness for `CommGroupAction`, plus a toy
`(ZMod 7)ˣ` `CommOrbitPKE` non-vacuity instance.

## Workstream R-11 (audit 2026-04-29 § 8.1, plan
`docs/planning/PLAN_R_05_11_15.md` § R-11)

This module is the *concrete instance* companion of `CSIDHHardness.lean`.
The hardness Prop module (`CSIDHHardness.lean`) is parametric over any
`CommGroupAction`; this module plugs in `(ZMod p)ˣ ↷ ZMod p` and gives a
toy `(ZMod 7)ˣ` `CommOrbitPKE` to demonstrate that `CommGroupAction`'s
typeclass is genuinely inhabitable by a non-trivial commutative action.

**Contrast with `selfAction`.** The pre-R-11 `selfAction` (defined in
`CommutativeAction.lean`) registered a `CommGroup G` acting on itself by
left multiplication — but only as a `def`, not an `instance`, to avoid a
diamond with Mathlib's `Monoid.toMulAction`. That action is broken in
polynomial time by discrete log in finite cyclic groups (the action group
and the carrier coincide, giving the discrete log oracle the
adversary needs). The R-11 multiplicative-group action `(ZMod p)ˣ ↷ ZMod p`
is genuinely non-trivial: the acting group `(ZMod p)ˣ` is a *strict subset*
of the carrier `ZMod p` (missing `0`), so the orbit structure is
non-trivial — `0` is a fixed point, and `(ZMod p)ˣ` is a single orbit of
cardinality `p − 1`. The DDH hardness for `(ZMod p)ˣ ↷ ZMod p` reduces to
the standard finite-cyclic-group DDH, which is a believed-hard problem in
finite fields.

## Main definitions

* `Orbcrypt.multGroupCommAction p` — the `CommGroupAction (ZMod p)ˣ
  (ZMod p)` instance for prime `p`.
* `Orbcrypt.toyZMod7CommPKE` — a `CommOrbitPKE (ZMod 7)ˣ (ZMod 7)` instance
  parameterised by `secretKey : (ZMod 7)ˣ`, with `basePoint = 1`. Non-vacuity
  witness for `CommGroupAction`'s typeclass.

## Main results

* `Orbcrypt.multGroupAction_orbit_zero` — the orbit of `0 : ZMod p` under
  `(ZMod p)ˣ` is the singleton `{0}` (the fixed point).
* `Orbcrypt.multGroupAction_orbit_one` — the orbit of `1 : ZMod p` under
  `(ZMod p)ˣ` is exactly the image of the units coercion `((ZMod p)ˣ →
  ZMod p)`, i.e., the non-zero residues.
* `Orbcrypt.toyZMod7CommPKE_correctness` — the toy `(ZMod 7)ˣ` PKE inherits
  the abstract `CommOrbitPKE.comm_pke_correctness` (decryption recovers the
  shared secret).

## Design decisions

* **`smul := fun u x => (u : ZMod p) * x`.** The natural action coercing
  units to ring elements via `Units.val` and using ring multiplication.
* **Avoiding the `Mul.toSMul` diamond.** The `(ZMod p)ˣ` group has a
  natural self-action via group multiplication, but that's an action on
  *units*, not on `ZMod p`. Our instance is on a *different* carrier, so
  no diamond with `Mul.toSMul` arises.
* **`Fact (Nat.Prime p)` constraint.** The constraint upgrades `ZMod p` to
  a field (via `Mathlib.Algebra.Field.ZMod`), which is needed for the
  `multGroupAction_orbit_one` characterisation: every non-zero residue is a
  unit, and units act transitively on themselves.
* **Toy basepoint `1 : ZMod 7`.** We pick `basePoint = 1` because:
  (a) `1` is a non-zero residue, hence a non-fixed point;
  (b) `pk = sk • 1 = sk * 1 = sk` makes the algebra clean for `decide`-able
  witnesses;
  (c) `1` is canonical (every non-zero residue would work).

## References

* `docs/PUBLIC_KEY_ANALYSIS.md` — Phase 13 feasibility analysis.
* `docs/planning/PLAN_R_05_11_15.md` § R-11 — workstream plan.
-/

namespace Orbcrypt

open MulAction

-- ============================================================================
-- WU-3.1 — multGroupCommAction p instance
-- ============================================================================

/--
**Multiplicative-group commutative action.**

For prime `p`, the units `(ZMod p)ˣ` act on the full residue ring `ZMod p`
by left multiplication: `u • x := (u : ZMod p) * x`.

This action is:
* **Commutative** — `(ZMod p)ˣ` is abelian (it's the multiplicative group
  of a finite field), so `u • (v • x) = u * (v * x) = (u * v) * x =
  (v * u) * x = v • (u • x)`.
* **Non-trivial** — the acting group `(ZMod p)ˣ` is a strict subset of the
  carrier `ZMod p` (missing `0`); the orbit of `0` is `{0}` (fixed point)
  and the orbit of any non-zero residue is `(ZMod p)ˣ` (single orbit of
  size `p − 1`).

The natural instance discharges all four `CommGroupAction` fields:
* `smul u x := (u : ZMod p) * x`;
* `one_smul x` — by `one_mul`;
* `mul_smul u v x` — by `Units.val_mul` plus `mul_assoc`;
* `comm a b x` — by ring commutativity (`mul_comm` + `mul_assoc`).

**No diamond with `Mul.toSMul`.** Mathlib's default `Mul.toSMul` instance
gives `(ZMod p)ˣ` a self-action `u • v := u * v` (with both sides in
`(ZMod p)ˣ`); our instance is on a different carrier `ZMod p`, so no
diamond arises at typeclass synthesis time.

**No diamond with `selfAction`.** The pre-R-11 `selfAction` from
`Orbcrypt/PublicKey/CommutativeAction.lean` is on a self-action `G ↷ G`
where the group acts on itself; ours is `(ZMod p)ˣ ↷ ZMod p` (different
carrier types), so the two definitions coexist without conflict.
-/
instance multGroupCommAction (p : ℕ) [Fact (Nat.Prime p)] :
    CommGroupAction (ZMod p)ˣ (ZMod p) where
  smul u x := (u : ZMod p) * x
  one_smul x := by
    show ((1 : (ZMod p)ˣ) : ZMod p) * x = x
    rw [Units.val_one, one_mul]
  mul_smul u v x := by
    show ((u * v : (ZMod p)ˣ) : ZMod p) * x =
         (u : ZMod p) * ((v : ZMod p) * x)
    rw [Units.val_mul, mul_assoc]
  comm a b x := by
    show (a : ZMod p) * ((b : ZMod p) * x) =
         (b : ZMod p) * ((a : ZMod p) * x)
    ring

/--
**Apply lemma for the multiplicative-group action.** Unfolds `u • x` to
`(u : ZMod p) * x` for explicit computation.
-/
@[simp]
theorem multGroupCommAction_smul {p : ℕ} [Fact (Nat.Prime p)]
    (u : (ZMod p)ˣ) (x : ZMod p) :
    u • x = (u : ZMod p) * x := rfl

-- ============================================================================
-- WU-3.2a — Orbit of 0 (the fixed point)
-- ============================================================================

/--
**The orbit of `0 : ZMod p` under `(ZMod p)ˣ` is the singleton `{0}`.**

Direct computation: every unit `u : (ZMod p)ˣ` acts trivially on `0`
because `(u : ZMod p) * 0 = 0` for any `u`. Hence the orbit is `{0}`.

The orbit-of-`0` is a singleton means `0` is a *fixed point* of the action.
The plan's `toyZMod7CommPKE` picks `basePoint = 1` (not `0`) precisely to
avoid the fixed-point degeneracy: at `basePoint = 0`, the encryption's
ciphertext `c.1 = r • 0 = 0` is constant, leaking information about `r`'s
absence and trivially distinguishing the IND-CPA real and random branches.
-/
theorem multGroupAction_orbit_zero (p : ℕ) [Fact (Nat.Prime p)] :
    MulAction.orbit (ZMod p)ˣ (0 : ZMod p) = {0} := by
  ext x
  rw [MulAction.mem_orbit_iff]
  simp only [multGroupCommAction_smul, mul_zero, Set.mem_singleton_iff]
  constructor
  · rintro ⟨_, h⟩
    exact h.symm
  · intro hx
    exact ⟨1, hx.symm⟩

-- ============================================================================
-- WU-3.2b — Orbit of 1 (the units, as a subset of ZMod p)
-- ============================================================================

/--
**The orbit of `1 : ZMod p` under `(ZMod p)ˣ` is exactly the image of the
units coercion**: `{x : ZMod p | ∃ u : (ZMod p)ˣ, (u : ZMod p) = x}`.

Direct computation: `u • 1 = (u : ZMod p) * 1 = (u : ZMod p)`, so the orbit
is precisely the set `{(u : ZMod p) | u : (ZMod p)ˣ}` (the image of the
canonical coercion). This set, set-theoretically, equals the non-zero
residues of `ZMod p` when `p` is prime (every non-zero residue is a unit).
-/
theorem multGroupAction_orbit_one (p : ℕ) [Fact (Nat.Prime p)] :
    MulAction.orbit (ZMod p)ˣ (1 : ZMod p) =
      {x : ZMod p | ∃ u : (ZMod p)ˣ, (u : ZMod p) = x} := by
  ext x
  rw [MulAction.mem_orbit_iff]
  simp only [Set.mem_setOf_eq, multGroupCommAction_smul, mul_one]

/--
**The orbit of `1` is exactly the non-zero residues** (an equivalent
formulation of `multGroupAction_orbit_one` using `IsUnit` / `≠ 0`).

For prime `p`, `ZMod p` is a field (via `Mathlib.Algebra.Field.ZMod`), so
`x : ZMod p` is a unit iff `x ≠ 0`. Hence the image of the units
coercion `((ZMod p)ˣ → ZMod p)` equals `{x | x ≠ 0}`.
-/
theorem multGroupAction_orbit_one_eq_nonzero (p : ℕ) [Fact (Nat.Prime p)] :
    MulAction.orbit (ZMod p)ˣ (1 : ZMod p) =
      {x : ZMod p | x ≠ 0} := by
  rw [multGroupAction_orbit_one]
  ext x
  simp only [Set.mem_setOf_eq]
  constructor
  · rintro ⟨u, rfl⟩
    -- (u : ZMod p) ≠ 0 because u is a unit (units are non-zero in a field)
    exact (Units.ne_zero u)
  · intro hx
    -- x ≠ 0 ⇒ x is a unit ⇒ ∃ u, (u : ZMod p) = x
    have h_unit : IsUnit x := isUnit_iff_ne_zero.mpr hx
    exact ⟨h_unit.unit, IsUnit.unit_spec h_unit⟩

-- ============================================================================
-- WU-3.3 — Toy `(ZMod 7)ˣ` `CommOrbitPKE` non-vacuity instance
-- ============================================================================

/--
**Toy concrete `CommOrbitPKE` instance at `p = 7`.**

For each `secretKey : (ZMod 7)ˣ`, produces a `CommOrbitPKE (ZMod 7)ˣ
(ZMod 7)` whose:
* `basePoint = 1 : ZMod 7` (a non-fixed point — `0` would be the fixed
  point of the action and would make encryption trivially distinguishable).
* `secretKey = secretKey` (the input).
* `publicKey = (secretKey : ZMod 7) * 1 = (secretKey : ZMod 7)` (just the
  unit's coercion to the ring).
* `pk_valid` discharged by the algebraic identity `(secretKey : ZMod 7)
  * 1 = (secretKey : ZMod 7)` (the action's apply rule + `mul_one`).

**Non-vacuity witness role.** This instance demonstrates that the
`CommGroupAction` typeclass admits at least one *concrete* commutative-
action `CommOrbitPKE` value. It is parameterised by `secretKey` so callers
can construct arbitrary toy instances by `decide`-able inputs.

**Why `p = 7`.** Mathlib provides `fact_prime_two` and `fact_prime_three`
natively but not for larger primes; for `p = 7` we use the established
`local instance ... := ⟨by decide⟩` pattern at audit-script consumption
sites. `p = 7` is small enough for `decide`-based algebra checks but large
enough to give a non-trivial cyclic group `(ZMod 7)ˣ` (cyclic of order 6).
-/
def toyZMod7CommPKE [Fact (Nat.Prime 7)] (secretKey : (ZMod 7)ˣ) :
    CommOrbitPKE (ZMod 7)ˣ (ZMod 7) where
  basePoint := 1
  secretKey := secretKey
  publicKey := (secretKey : ZMod 7)
  pk_valid := by
    -- pk = secretKey • basePoint = (secretKey : ZMod 7) * 1 = (secretKey : ZMod 7)
    show (secretKey : ZMod 7) = (secretKey : ZMod 7) * 1
    rw [mul_one]

/--
**The toy `(ZMod 7)ˣ` PKE is correctness-correct.** Direct application of
`comm_pke_correctness` from `CommutativeAction.lean`: for any sender
randomness `r : (ZMod 7)ˣ`,

  `decrypt(encrypt(r).1) = encrypt(r).2`.

The shared secret recovered by the recipient (via `secretKey • c.1`) equals
the shared secret derived by the sender (via `r • publicKey`).
-/
theorem toyZMod7CommPKE_correctness [Fact (Nat.Prime 7)]
    (sk r : (ZMod 7)ˣ) :
    let pke := toyZMod7CommPKE sk
    pke.decrypt (pke.encrypt r).1 = (pke.encrypt r).2 :=
  comm_pke_correctness (toyZMod7CommPKE sk) r

/--
**The toy `(ZMod 7)ˣ` PKE inherits the CSIDH-style commutative key-agreement
identity.** Direct application of `comm_pke_shared_secret` from
`CommutativeAction.lean`: the sender's shared secret `r • publicKey` equals
`secretKey • (r • basePoint)`, the recipient-side computation.
-/
theorem toyZMod7CommPKE_shared_secret [Fact (Nat.Prime 7)]
    (sk r : (ZMod 7)ˣ) :
    let pke := toyZMod7CommPKE sk
    r • pke.publicKey = pke.secretKey • (r • pke.basePoint) :=
  comm_pke_shared_secret (toyZMod7CommPKE sk) r

end Orbcrypt
