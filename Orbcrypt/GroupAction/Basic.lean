import Mathlib.GroupTheory.GroupAction.Defs
import Mathlib.GroupTheory.GroupAction.Quotient

/-!
# Orbcrypt.GroupAction.Basic

Orbit, stabilizer, orbit partition, and orbit-stabilizer theorem wrappers
around Mathlib's `MulAction` framework. Provides the foundational group action
API used throughout the Orbcrypt formalization.

## Main definitions and results

* `Orbcrypt.orbit` — alias for `MulAction.orbit`
* `Orbcrypt.stabilizer` — alias for `MulAction.stabilizer`
* `Orbcrypt.orbit_disjoint_or_eq` — any two orbits are either equal or disjoint
* `Orbcrypt.orbit_stabilizer` — orbit-stabilizer theorem: |Orb| * |Stab| = |G|
* `Orbcrypt.smul_mem_orbit` — applying a group element yields an orbit member
* `Orbcrypt.orbit_eq_of_smul` — group action preserves orbits

## References

* DEVELOPMENT.md §3 — orbit encryption scheme foundations
* formalization/phases/PHASE_2_GROUP_ACTION_FOUNDATIONS.md — work units 2.1–2.4
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*}

-- ============================================================================
-- Work Unit 2.1: Orbit API Wrapper
-- ============================================================================

section OrbitAPI

/-- The orbit of `x` under the group `G`. Alias for `MulAction.orbit G x`. -/
abbrev orbit (G : Type*) {X : Type*} [Group G] [MulAction G X] (x : X) : Set X :=
  MulAction.orbit G x

/-- The stabilizer of `x` in `G`. Alias for `MulAction.stabilizer G x`. -/
abbrev stabilizer (G : Type*) {X : Type*} [Group G] [MulAction G X] (x : X) : Subgroup G :=
  MulAction.stabilizer G x

end OrbitAPI

-- ============================================================================
-- Work Unit 2.2: Orbit Partition Theorem
-- ============================================================================

section OrbitPartition

variable [Group G] [MulAction G X]

/-- Any two orbits under a group action are either equal or disjoint.
    This is a fundamental property of the orbit equivalence relation
    `MulAction.orbitRel`: equivalence classes are either identical or
    have empty intersection.

    **Proof strategy:** If `x ∈ orbit G y`, the orbits are equal by
    `MulAction.orbit_eq_iff`. Otherwise, any shared element would force
    orbit equality, contradicting the assumption. -/
theorem orbit_disjoint_or_eq (x y : X) :
    MulAction.orbit G x = MulAction.orbit G y ∨
    Disjoint (MulAction.orbit G x) (MulAction.orbit G y) := by
  by_cases h : x ∈ MulAction.orbit G y
  · exact Or.inl (MulAction.orbit_eq_iff.mpr h)
  · right
    rw [Set.disjoint_left]
    intro z hz_x hz_y
    exact h (MulAction.orbit_eq_iff.mp
      ((MulAction.orbit_eq_iff.mpr hz_x).symm.trans (MulAction.orbit_eq_iff.mpr hz_y)))

end OrbitPartition

-- ============================================================================
-- Work Unit 2.3: Orbit-Stabilizer Theorem Wrapper
-- ============================================================================

section OrbitStabilizer

variable [Group G] [MulAction G X] [Fintype G]

/-- Orbit-stabilizer theorem: `|orbit G x| * |stab_G(x)| = |G|`.
    Wraps Mathlib's `MulAction.card_orbit_mul_card_stabilizer_eq_card_group`
    with explicit type annotations for use in Orbcrypt proofs. -/
theorem orbit_stabilizer (x : X)
    [Fintype (MulAction.orbit G x)] [Fintype (MulAction.stabilizer G x)] :
    Fintype.card (MulAction.orbit G x) *
    Fintype.card (MulAction.stabilizer G x) =
    Fintype.card G :=
  MulAction.card_orbit_mul_card_stabilizer_eq_card_group x

end OrbitStabilizer

-- ============================================================================
-- Work Unit 2.4: Orbit Membership Lemmas
-- ============================================================================

section OrbitMembership

variable [Group G] [MulAction G X]

/-- Applying a group element to `x` yields a member of the orbit of `x`.
    Direct wrapper around `MulAction.mem_orbit`. -/
theorem smul_mem_orbit (g : G) (x : X) : g • x ∈ MulAction.orbit G x :=
  MulAction.mem_orbit x g

/-- If `y` is obtained from `x` by a group action, they share the same orbit.
    Wraps Mathlib's `MulAction.orbit_smul`.
    This is essential for the correctness proof: encrypting with any group
    element preserves the orbit (message identity). -/
theorem orbit_eq_of_smul (g : G) (x : X) :
    MulAction.orbit G (g • x) = MulAction.orbit G x :=
  MulAction.orbit_smul g x

end OrbitMembership

end Orbcrypt
