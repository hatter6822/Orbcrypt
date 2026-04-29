/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
Workstream B verification script (audit 2026-04-18).

Verifies the four invariants the audit plan asks for:

1. `#print axioms` outputs for every Workstream B headline result list
   only standard Lean axioms (`propext`, `Classical.choice`, `Quot.sound`)
   plus, for `isSecure_implies_isSecureDistinct`, the stronger property
   "depends on no axioms".
2. `hasAdvantageDistinct` is definitionally equal (via `Iff.rfl`) to
   the conjunction of the distinctness obligation and `hasAdvantage`.
3. `SchemeFamily` is universe-polymorphic in `u, v, w` after the
   B2 refactor — instantiating at fully small universes (`(0, 0, 0)`)
   elaborates without explicit annotations.
4. `DistinctMultiQueryAdversary` is constructible — exhibit a concrete
   instance to prove the wrapper isn't vacuous.

Run: `source ~/.elan/env && lake env lean scripts/audit_b_workstream.lean`

Expected output:
```
'Orbcrypt.isSecure_implies_isSecureDistinct' does not depend on any axioms
'Orbcrypt.hasAdvantageDistinct_iff' does not depend on any axioms
'Orbcrypt.perQueryAdvantage_nonneg' depends on axioms: [propext, Classical.choice, Quot.sound]
'Orbcrypt.perQueryAdvantage_le_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'Orbcrypt.perQueryAdvantage_bound_of_concreteOIA' depends on axioms: [propext, Classical.choice, Quot.sound]
```
(no `sorryAx` anywhere; axiom set never includes a custom `axiom` declaration).
-/

import Orbcrypt.Crypto.Security
import Orbcrypt.Crypto.CompOIA
import Orbcrypt.Crypto.CompSecurity

open Orbcrypt

-- ============================================================================
-- (1) Axiom transparency on every Workstream B headline result.
-- ============================================================================

#print axioms isSecure_implies_isSecureDistinct
#print axioms hasAdvantageDistinct_iff
#print axioms perQueryAdvantage_nonneg
#print axioms perQueryAdvantage_le_one
#print axioms perQueryAdvantage_bound_of_concreteOIA

-- ============================================================================
-- (2) Definitional decomposition: `hasAdvantageDistinct = distinct ∧ hasAdvantage`.
-- ============================================================================
--
-- We exercise the `Iff.rfl` shape to confirm the second conjunct of
-- `hasAdvantageDistinct` reduces to `hasAdvantage` without unfolding work.

section B1Decomposition
variable {G X M : Type} [Group G] [MulAction G X] [DecidableEq X]
variable (scheme : OrbitEncScheme G X M) (A : Adversary X M)

example : hasAdvantageDistinct scheme A ↔
    (A.choose scheme.reps).1 ≠ (A.choose scheme.reps).2 ∧
      hasAdvantage scheme A :=
  hasAdvantageDistinct_iff scheme A

example (h : hasAdvantageDistinct scheme A) : hasAdvantage scheme A := h.2

end B1Decomposition

-- ============================================================================
-- (3) `SchemeFamily` universe polymorphism (audit F-15 / Workstream B2).
-- ============================================================================
--
-- The structure carries three universe parameters bound by the module-level
-- `universe u v w` in `Crypto/CompOIA.lean`. The two examples below
-- elaborate `SchemeFamily` at the smallest possible universes (`Type 0`
-- everywhere) and at lifted universes — confirming the parameters are
-- truly polymorphic and not pinned to a specific universe by the helpers.

section B2UniverseCheck
universe u v w

-- Bare existence proof at default universes — auto-inferred.
example (sf : SchemeFamily) (n : ℕ) (m : sf.M n) : sf.X n := sf.repsAt n m

-- Existence proof with explicit universe instantiation.
example (sf : @SchemeFamily.{u, v, w}) (n : ℕ) (m : sf.M n) : sf.X n :=
  sf.repsAt n m

-- The three F-13 helpers are still definitionally equal to their `@`-threaded
-- forms, even with the universe-polymorphic `SchemeFamily`. (Originally
-- `scripts/audit_a7_defeq.lean`; replicated here so Workstream B's regression
-- test is self-contained.)
example (sf : SchemeFamily) (n : ℕ) (m : sf.M n) :
    sf.repsAt n m =
      @OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n)
        (sf.instGroup n) (sf.instAction n) (sf.instDecEq n) (sf.scheme n) m := rfl

example (sf : SchemeFamily) (n : ℕ) (m : sf.M n) :
    sf.orbitDistAt n m =
      @orbitDist (sf.G n) (sf.X n) (sf.instGroup n) (sf.instFintype n)
        (sf.instNonempty n) (sf.instAction n)
        (@OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n)
          (sf.instGroup n) (sf.instAction n) (sf.instDecEq n) (sf.scheme n) m) := rfl

example (sf : SchemeFamily) (n : ℕ) (D : ∀ n, sf.X n → Bool)
    (m₀ m₁ : ∀ n, sf.M n) :
    sf.advantageAt D m₀ m₁ n =
      @advantage (sf.X n) (D n)
        (sf.orbitDistAt n (m₀ n)) (sf.orbitDistAt n (m₁ n)) := rfl

end B2UniverseCheck

-- ============================================================================
-- (4) `DistinctMultiQueryAdversary` is constructible (audit F-02 / B3).
-- ============================================================================
--
-- We exhibit a concrete instance over a two-element message space (`Bool`)
-- whose `choose` returns the two boolean messages and discharges the
-- distinctness obligation by `decide`. This proves the wrapper is non-vacuous
-- and pinpoints the proof obligation a real adversary must satisfy.

section B3Constructibility
variable (X : Type) (Q : ℕ)

/-- Toy adversary that always picks `(false, true)` regardless of
    the public representative map. The first two indices return distinct
    messages by construction. -/
def toyMultiQuery : MultiQueryAdversary X Bool Q where
  choose _reps _i := (false, true)
  guess _reps _ciphers := false

/-- Distinct-challenge wrapper over the toy adversary. The distinctness
    proof unfolds `toyMultiQuery.choose` to `(false, true)` and discharges
    `false ≠ true` by `Bool.false_ne_true`. -/
def toyDistinctMultiQuery : DistinctMultiQueryAdversary X Bool Q where
  toMultiQueryAdversary := toyMultiQuery X Q
  choose_distinct _reps _i := Bool.false_ne_true

-- Quick sanity check: the wrapper round-trips through `toMultiQueryAdversary`
-- back to its base `choose` field.
example (reps : Bool → X) (i : Fin Q) :
    (toyDistinctMultiQuery X Q).toMultiQueryAdversary.choose reps i = (false, true) := rfl

end B3Constructibility
