/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
Workstream C verification script (audit 2026-04-18, finding F-07).

Verifies the five invariants the audit plan asks for:

1. `#print axioms` outputs for every Workstream C headline result list
   only standard Lean axioms (`propext`, `Classical.choice`, `Quot.sound`).
   No `sorryAx`, no custom axiom.
2. `MAC.verify_inj` is a *proof obligation* on the structure — every
   `MAC` value must discharge it. We exercise this by destructuring a
   `MAC` and extracting the field.
3. `authEncrypt_is_int_ctxt` is non-vacuously inhabited: we construct
   a toy `AuthOrbitKEM` and discharge `INT_CTXT` on it. Post-audit
   2026-04-23 Workstream B, the theorem is unconditional — the
   orbit-cover obligation has been absorbed into the game's
   per-challenge precondition on `INT_CTXT` itself.
4. `deterministicTagMAC` is universe- and type-polymorphic: the key,
   message, and tag types are independent; instantiating them at
   distinct concrete types elaborates cleanly.
5. `carterWegmanMAC_int_ctxt` is exercisable: we construct a KEM on
   `ZMod 2` under the natural `Equiv.Perm (ZMod 2)` action and obtain
   `INT_CTXT` for the composed AEAD. Post-Workstream-B this is a
   direct application of `authEncrypt_is_int_ctxt` with no orbit-cover
   argument.

Run: `source ~/.elan/env && lake env lean scripts/audit_c_workstream.lean`

Expected output:
```
'Orbcrypt.authEncrypt_is_int_ctxt' depends on axioms: [propext, Quot.sound]
'Orbcrypt.carterWegmanMAC_int_ctxt' depends on axioms: [propext, Quot.sound]
'Orbcrypt.carterWegmanMAC' depends on axioms: [propext, Quot.sound]
'Orbcrypt.deterministicTagMAC' does not depend on any axioms
'Orbcrypt.aead_correctness' depends on axioms: [propext]
'toyCarterWegmanMAC_is_int_ctxt' depends on axioms: [propext, Classical.choice, Quot.sound]
```
(no `sorryAx` anywhere; axiom set never includes a custom `axiom` declaration).
The `Classical.choice` on `toyCarterWegmanMAC_is_int_ctxt` enters via
`Subsingleton.elim` in the script-local witness — a standard Lean axiom,
not a Workstream C artefact.
-/

import Mathlib.Data.ZMod.Basic
import Orbcrypt.AEAD.MAC
import Orbcrypt.AEAD.AEAD
import Orbcrypt.AEAD.CarterWegmanMAC

open Orbcrypt

-- ============================================================================
-- (1) Axiom transparency on every Workstream C headline result.
-- ============================================================================

#print axioms authEncrypt_is_int_ctxt
#print axioms carterWegmanMAC_int_ctxt
#print axioms carterWegmanMAC
#print axioms deterministicTagMAC
#print axioms aead_correctness

-- ============================================================================
-- (2) `MAC.verify_inj` is a real proof obligation (audit F-07, Workstream C1).
-- ============================================================================
--
-- Exercise the field by destructuring a `MAC` and re-packaging its
-- tag-uniqueness proof. Any constructor that omits `verify_inj` would
-- fail to elaborate here.

section C1FieldCheck
variable {K Msg Tag : Type} (mac : MAC K Msg Tag)

example (k : K) (m : Msg) (t : Tag)
    (hv : mac.verify k m t = true) : t = mac.tag k m :=
  mac.verify_inj k m t hv

end C1FieldCheck

-- ============================================================================
-- (3) `authEncrypt_is_int_ctxt` is non-vacuously inhabited (C2c,
--     refined by Workstream B of the 2026-04-23 audit).
-- ============================================================================
--
-- Exhibit the per-challenge `hOrbit` discharge: every element of `Unit`
-- lies in every orbit (subsingleton witness). Post-Workstream-B, this
-- discharge happens *inside* the `INT_CTXT` game binder rather than on
-- `authEncrypt_is_int_ctxt`'s theorem signature; `authEncrypt_is_int_ctxt`
-- itself is unconditional.

section C2cSatisfiability
open MulAction

-- The trivial group acts trivially on Unit. This instance is already in
-- Mathlib, but we include the `Unique` / `Subsingleton` witness for
-- clarity.
example : ∀ c : Unit, c ∈ MulAction.orbit (Equiv.Perm Unit) (() : Unit) := by
  intro c
  -- Every element of Unit equals ().
  have : c = () := Subsingleton.elim _ _
  rw [this]
  exact MulAction.mem_orbit_self _

end C2cSatisfiability

-- ============================================================================
-- (4) `deterministicTagMAC` is type-polymorphic in K, Msg, Tag (C4 template).
-- ============================================================================
--
-- We exercise three distinct instantiations: (i) Bool keys with Nat messages
-- and String tags (via a toy hash), (ii) Nat keys with Unit messages and Bool
-- tags, and (iii) the specialised Carter–Wegman instance.

section C4TemplateCheck

-- Instantiation (i): three unrelated concrete types.
def toyHashBNS : Bool → ℕ → String :=
  fun b n => if b then toString n else "⊥"

example : MAC Bool ℕ String := deterministicTagMAC toyHashBNS

-- Instantiation (ii): demonstrate that `Tag` need not equal `K`.
example : MAC ℕ Unit Bool := deterministicTagMAC (fun n _ => n % 2 == 0)

-- Instantiation (iii): the Carter–Wegman witness is an instance of
-- `deterministicTagMAC`.  `[Fact (Nat.Prime p)]` (upgraded post-audit
-- from `[NeZero p]` in the L-workstream audit pass, 2026-04-22):
-- the primality constraint is the mathematical precondition for the
-- universal-hash property proved by `carterWegmanHash_isUniversal`.
-- Mathlib provides `instance fact_prime_two : Fact (Nat.Prime 2)`, so
-- `[Fact (Nat.Prime 2)]` resolves automatically.
example (p : ℕ) [Fact (Nat.Prime p)] :
    carterWegmanMAC p = deterministicTagMAC (carterWegmanHash p) := rfl

-- Instantiation (iv): the Carter–Wegman hash is `(1/p)`-universal for
-- every prime `p` (headline theorem of the L-workstream audit pass).
example (p : ℕ) [Fact (Nat.Prime p)] :
    IsEpsilonUniversal (carterWegmanHash p) ((1 : ENNReal) / p) :=
  carterWegmanHash_isUniversal p

-- Concrete discharge at `p = 2` (smallest prime; Fact auto-resolves).
example : IsEpsilonUniversal (carterWegmanHash 2) ((1 : ENNReal) / 2) :=
  carterWegmanHash_isUniversal 2

end C4TemplateCheck

-- ============================================================================
-- (5) `carterWegmanMAC_int_ctxt` is exercisable at the smallest prime
--     `p = 2` over `ZMod 2` under the natural `S_{ZMod 2}` action.
-- ============================================================================
--
-- Post the L-workstream audit pass (2026-04-22), the MAC requires
-- `[Fact (Nat.Prime p)]`.  The smallest such `p` is `2`; we
-- materialise the end-to-end INT-CTXT witness there.  The natural
-- `Equiv.Perm` action on `ZMod 2` is transitive (swap `0` with any
-- point), so the orbit-cover discharge is direct.

section C4ExerciseINT_CTXT_Prime

-- Natural action of `Equiv.Perm α` on `α` (Mathlib's standard instance);
-- made local so unification picks it up for the composition below.
local instance permActionZMod2 :
    MulAction (Equiv.Perm (ZMod 2)) (ZMod 2) := inferInstance

/-- Concrete `OrbitKEM` on `ZMod 2` with constant canonical form `= 0`.
    Under `Equiv.Perm (ZMod 2)` acting naturally on `ZMod 2`, the group
    acts transitively on the two-element set, so every point lies in
    the single orbit, and `canon _ := 0` — always pointing to the
    basepoint — satisfies both `mem_orbit` (via `swap x 0`) and
    `orbit_iff` (all orbits coincide, both sides of the iff are
    trivially true).  Fixture for the audit script. -/
def toyKEMZMod2 :
    OrbitKEM (Equiv.Perm (ZMod 2)) (ZMod 2) (ZMod 2 × ZMod 2) where
  basePoint := (0 : ZMod 2)
  canonForm :=
    { canon := fun _ => 0
      mem_orbit := fun x => by
        -- Goal: `0 ∈ MulAction.orbit _ x` — use the swap `x ↔ 0`.
        refine ⟨Equiv.swap x 0, ?_⟩
        show (Equiv.swap x 0) x = 0
        exact Equiv.swap_apply_left x 0
      orbit_iff := by
        intro x y
        -- `canon x = canon y` is always `(0 = 0) ↔ True`.
        -- `orbit G x = orbit G y` also always holds (transitive action).
        refine ⟨fun _ => ?_, fun _ => rfl⟩
        -- Goal: `MulAction.orbit G x = MulAction.orbit G y`.
        ext z
        refine ⟨fun _ => ⟨Equiv.swap y z, Equiv.swap_apply_left y z⟩,
                fun _ => ⟨Equiv.swap x z, Equiv.swap_apply_left x z⟩⟩ }
  keyDerive := fun _ => ((0 : ZMod 2), (0 : ZMod 2))

/-- Every `c : ZMod 2` lies in `orbit G toyKEMZMod2.basePoint`:
    the `Equiv.swap 0 c` permutation maps `0` to `c`. Post-Workstream-B
    of the 2026-04-23 audit, `carterWegmanMAC_int_ctxt` no longer
    requires this lemma; we retain it for the transitive-action
    witness it provides at the adversary-supplied challenge level. -/
lemma toyKEMZMod2_orbit_cover (c : ZMod 2) :
    c ∈ MulAction.orbit (Equiv.Perm (ZMod 2)) toyKEMZMod2.basePoint :=
  ⟨Equiv.swap 0 c, Equiv.swap_apply_left 0 c⟩

/-- The Carter–Wegman AEAD composition over `toyKEMZMod2` satisfies
    `INT_CTXT`.  End-to-end receipt: `MAC.verify_inj` →
    `authEncrypt_is_int_ctxt` → concrete witness at the smallest prime.
    Post-audit (2026-04-22): moved from `p = 1` (no longer admissible
    under `[Fact (Nat.Prime p)]`) to `p = 2`. Post-audit (2026-04-23
    Workstream B): the `hOrbitCover` argument is removed — the orbit
    condition now lives inside the `INT_CTXT` game as a per-challenge
    precondition. -/
theorem toyCarterWegmanMAC_is_int_ctxt :
    INT_CTXT (carterWegman_authKEM 2 toyKEMZMod2) :=
  carterWegmanMAC_int_ctxt 2 toyKEMZMod2

#print axioms toyCarterWegmanMAC_is_int_ctxt

/-- **Game-shape smoke test (Workstream B).** Exercises the post-B
    `INT_CTXT` binder pattern by explicitly applying the predicate
    to a challenge `(c, t, hOrbit, hFresh)` quadruple. This
    demonstrates that the per-challenge `hOrbit` binder can be
    supplied using `toyKEMZMod2_orbit_cover`, and that the resulting
    obligation type-checks against the `authDecaps = none`
    conclusion. If the pre-B signature crept back into the predicate
    (e.g. via a missing `hOrbit` binder or a theorem-level
    `hOrbitCover` parameter), this example would fail to elaborate. -/
example (c : ZMod 2) (t : ZMod 2)
    (hFresh : ∀ g : Equiv.Perm (ZMod 2),
      c ≠ (authEncaps (carterWegman_authKEM 2 toyKEMZMod2) g).1 ∨
      t ≠ (authEncaps (carterWegman_authKEM 2 toyKEMZMod2) g).2.2) :
    authDecaps (carterWegman_authKEM 2 toyKEMZMod2) c t = none :=
  toyCarterWegmanMAC_is_int_ctxt c t (toyKEMZMod2_orbit_cover c) hFresh

end C4ExerciseINT_CTXT_Prime
