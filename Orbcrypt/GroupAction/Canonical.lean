/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.GroupAction.Basic

/-!
# Orbcrypt.GroupAction.Canonical

Canonical forms under group actions: definition of the `CanonicalForm`
structure, uniqueness (orbit equality from canon equality), and idempotence.

A canonical form abstracts the concept of "lexicographically minimal element
of the orbit" (DEVELOPMENT.md §3.2). It maps each element to a unique
representative of its orbit, enabling decryption: given a ciphertext
`c = g • x_m`, computing `canon(c) = canon(x_m)` recovers the message identity.

## Main definitions and results

* `Orbcrypt.CanonicalForm` — structure bundling a canonicalization function
  with orbit membership and orbit characterization properties
* `Orbcrypt.canon_eq_implies_orbit_eq` — same canon implies same orbit
* `Orbcrypt.orbit_eq_implies_canon_eq` — same orbit implies same canon
* `Orbcrypt.canon_eq_of_mem_orbit` — orbit membership implies canon equality
* `Orbcrypt.canon_idem` — `canon(canon(x)) = canon(x)`

## References

* DEVELOPMENT.md §3.2 — canonical forms in the encryption scheme
* formalization/phases/PHASE_2_GROUP_ACTION_FOUNDATIONS.md — work units 2.5–2.7
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*}

-- ============================================================================
-- Work Unit 2.5: Canonical Form Structure
-- ============================================================================

/--
A canonical form for a group action is a function `canon : X → X` that:
1. Maps each element to a member of its own orbit (`mem_orbit`).
2. Uniquely identifies orbits: `canon x = canon y ↔ orbit G x = orbit G y`
   (`orbit_iff`).

This abstracts the concept of "lexicographically minimal element of the orbit"
used in the concrete Orbcrypt construction (DEVELOPMENT.md §3.2). It is defined
as a structure rather than a type class because a given group action may admit
multiple canonical forms (e.g., lex-min, lex-max). The encryption scheme
explicitly carries its canonical form as data.
-/
structure CanonicalForm (G : Type*) (X : Type*)
    [Group G] [MulAction G X] where
  /-- The canonicalization function. -/
  canon : X → X
  /-- The canonical form of `x` lies in the orbit of `x`. -/
  mem_orbit : ∀ x, canon x ∈ MulAction.orbit G x
  /-- Two elements have the same canonical form iff they are in the same orbit. -/
  orbit_iff : ∀ x y, canon x = canon y ↔
    MulAction.orbit G x = MulAction.orbit G y

-- ============================================================================
-- Work Unit 2.6: Canonical Form Uniqueness
-- ============================================================================

section CanonicalUniqueness

variable [Group G] [MulAction G X]

/-- If two elements have the same canonical form, they are in the same orbit. -/
theorem canon_eq_implies_orbit_eq
    (can : CanonicalForm G X) (x y : X) :
    can.canon x = can.canon y → MulAction.orbit G x = MulAction.orbit G y :=
  (can.orbit_iff x y).mp

/-- If two elements are in the same orbit, they have the same canonical form. -/
theorem orbit_eq_implies_canon_eq
    (can : CanonicalForm G X) (x y : X) :
    MulAction.orbit G x = MulAction.orbit G y → can.canon x = can.canon y :=
  (can.orbit_iff x y).mpr

/-- Elements in the same orbit have the same canonical form (membership version).
    This is the key lemma for the correctness proof: if `y ∈ orbit G x`,
    then `canon y = canon x`, so decryption recovers the original message. -/
theorem canon_eq_of_mem_orbit
    (can : CanonicalForm G X) (x y : X)
    (h : y ∈ MulAction.orbit G x) :
    can.canon y = can.canon x :=
  -- y ∈ orbit G x implies orbit G y = orbit G x (by orbit_eq_iff)
  -- Then orbit_iff gives canon y = canon x
  (can.orbit_iff y x).mpr (MulAction.orbit_eq_iff.mpr h)

end CanonicalUniqueness

-- ============================================================================
-- Work Unit 2.7: Canonical Form Idempotence
-- ============================================================================

section CanonicalIdempotence

variable [Group G] [MulAction G X]

/-- Canonical form is idempotent: `canon(canon(x)) = canon(x)`.
    Since `canon(x) ∈ orbit G x`, we have `orbit G (canon x) = orbit G x`,
    and the orbit characterization property gives the result. -/
theorem canon_idem (can : CanonicalForm G X) (x : X) :
    can.canon (can.canon x) = can.canon x :=
  -- canon x ∈ orbit G x (by mem_orbit), so orbit G (canon x) = orbit G x
  -- Then orbit_iff gives canon (canon x) = canon x
  (can.orbit_iff (can.canon x) x).mpr (MulAction.orbit_eq_iff.mpr (can.mem_orbit x))

end CanonicalIdempotence

end Orbcrypt
