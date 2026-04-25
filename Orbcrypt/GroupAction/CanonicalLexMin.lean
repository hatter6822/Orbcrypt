import Orbcrypt.GroupAction.Canonical
import Mathlib.Data.Set.Finite.Range
import Mathlib.Data.Finset.Max
import Mathlib.Data.Fintype.Sets

/-!
# Orbcrypt.GroupAction.CanonicalLexMin

A concrete `CanonicalForm` constructor: the minimum element of a finite orbit
under a `LinearOrder`. Given a group action with finite group and decidable-
equality target space equipped with any linear order, every element's orbit is
a finite `Set`, convertible to a `Finset` via `Set.toFinset`, and nonempty
(it contains the representative). `Finset.min'` of the orbit is therefore a
well-defined element of `X`, lies in the orbit, and uniquely identifies the
orbit among all orbits. This discharges all three `CanonicalForm` fields.

## Main definitions and results

* `Orbcrypt.CanonicalForm.ofLexMin` — the lex-min canonical form constructor,
  producing a `CanonicalForm G X` from any `[Group G] [MulAction G X]
  [Fintype G] [DecidableEq X] [LinearOrder X]`. The "lex" terminology is
  standard Orbcrypt shorthand for "minimum element of the orbit under a
  chosen linear order"; the construction does not privilege any specific
  `LinearOrder`, so callers supply their own (lexicographic, `toNat`-
  induced, etc.).
* `Orbcrypt.CanonicalForm.ofLexMin_canon` — `@[simp]` unfolding lemma
  exposing `canon x = (orbit G x).toFinset.min' _`.
* `Orbcrypt.CanonicalForm.ofLexMin_canon_mem_orbit` — reminder lemma that
  the `canon x` output lies in the orbit.

## Design notes

* The constructor is abstract over `X` and over `[LinearOrder X]`, not
  specialised to `Bitstring n`. The Orbcrypt scheme's canonical `Bitstring n`
  instantiation is via the `bitstringLinearOrder` instance in
  `Orbcrypt/Construction/Permutation.lean`, which registers a computable lex
  order (big-endian `Fin (2^n)` encoding) so that `canon` reduces by `decide`
  on small concrete inputs. Any other `LinearOrder X` — including
  `noncomputable` ones such as `Lex.linearOrder` — also discharges the
  constructor; concrete evaluation of `canon` then inherits whatever
  computational properties the chosen order has.

* The orbit-membership field (`mem_orbit`) follows from `Finset.min'_mem`.

* The orbit-characterisation field (`orbit_iff`) splits into:
  - forward (`canon x = canon y → orbit G x = orbit G y`): the shared
    `min'` element `m` is in both orbits by `min'_mem` +
    `Set.mem_toFinset`; applying `MulAction.orbit_eq_iff` to the forward
    inclusion twice gives `orbit G x = orbit G m = orbit G y`.
  - reverse (`orbit G x = orbit G y → canon x = canon y`): equal orbits
    (as `Set`s) produce equal `.toFinset` values via
    `Set.toFinset_congr`, and equal finsets give equal `min'` values.

## References

* DEVELOPMENT.md §3.2 — canonical forms in the encryption scheme
* docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md § 9 — Workstream F
  (V1-10 / F-04): concrete `CanonicalForm.ofLexMin` constructor; this
  module is the F1 + F2 + F3a + F3b + F3c landing.
* `Orbcrypt/Construction/Permutation.lean` — `bitstringLinearOrder`
  instance used by the non-vacuity witness in
  `scripts/audit_phase_16.lean`.
* `Orbcrypt/Construction/HGOE.lean` — `hgoeScheme.ofLexMin` convenience
  constructor (Workstream F / F4).
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*}

-- ============================================================================
-- Work Unit F3a: Orbit Fintype + toFinset helper
-- ============================================================================

section OrbitFinite

variable [Group G] [MulAction G X] [Fintype G] [DecidableEq X]

/-- The orbit of `x` under a finite group is a `Fintype`. `MulAction.orbit`
    is definitionally `Set.range (fun g => g • x)`; with `[Fintype G]` and
    `[DecidableEq X]` this `Set` inherits Mathlib's `Set.fintypeRange`. The
    `Fintype (PLift G)` side condition is discharged automatically from
    `[Fintype G]` via `Fintype.ofEquiv` on the `PLift` equiv. -/
instance orbitFintype (x : X) : Fintype (MulAction.orbit G x) :=
  inferInstanceAs (Fintype (Set.range fun g : G => g • x))

/-- Membership in the `.toFinset` of an orbit coincides with orbit
    membership. Thin wrapper around `Set.mem_toFinset` exposing the
    Orbcrypt-side name so downstream proofs can reference it without
    unfolding the abbreviation.

    *Not* tagged `@[simp]`: Mathlib's `Set.mem_toFinset` is already
    `@[simp]`, so `simp` rewrites `y ∈ (orbit G x).toFinset` to
    `y ∈ orbit G x` regardless of which lemma is invoked. Tagging this
    wrapper `@[simp]` would register two simp rules with identical
    LHS/RHS, slowing `simp` calls without adding rewrite power. The
    wrapper is kept as a *named alias* for explicit term-mode proofs
    (e.g. inside `CanonicalForm.ofLexMin`'s `mem_orbit` discharge),
    where the orbit-specific name reads more clearly than the generic
    `Set.mem_toFinset`. -/
theorem mem_orbit_toFinset_iff (x y : X) :
    y ∈ (MulAction.orbit G x).toFinset ↔ y ∈ MulAction.orbit G x :=
  Set.mem_toFinset

/-- The `.toFinset` of an orbit is always nonempty (the orbit contains
    its base point). -/
theorem orbit_toFinset_nonempty (x : X) :
    (MulAction.orbit G x).toFinset.Nonempty :=
  ⟨x, (mem_orbit_toFinset_iff x x).mpr (MulAction.mem_orbit_self x)⟩

end OrbitFinite

-- ============================================================================
-- Work Unit F2 + F3b + F3c: CanonicalForm.ofLexMin constructor
-- ============================================================================

section OfLexMin

variable [Group G] [MulAction G X] [Fintype G] [DecidableEq X] [LinearOrder X]

/--
Lex-minimum canonical form. `canon x` is the least element of `x`'s orbit
under the ambient `LinearOrder X`. This discharges all three `CanonicalForm`
fields:

* `canon` — defined as `(orbit G x).toFinset.min' _`, with non-emptiness
  discharged by the base-point witness `x ∈ orbit G x`;
* `mem_orbit` — follows from `Finset.min'_mem` + `mem_orbit_toFinset_iff`;
* `orbit_iff` — forward direction extracts the shared `min'` element and
  threads it through `MulAction.orbit_eq_iff`; reverse direction uses
  `Set.toFinset_congr` + `Finset.min'` proof-irrelevance in its
  non-emptiness argument.

Callers at non-trivial actions instantiate with their preferred
`LinearOrder X` (for `Bitstring n`, see
`Orbcrypt/Construction/Permutation.lean`'s `bitstringLinearOrder`).
Closes audit finding V1-10 / F-04 (Workstream F of the 2026-04-23 audit):
`hgoeScheme`'s previously-abstract `CanonicalForm` parameter now has a
concrete in-tree witness at every subgroup of `Equiv.Perm (Fin n)`.
-/
def CanonicalForm.ofLexMin : CanonicalForm G X where
  canon := fun x =>
    (MulAction.orbit G x).toFinset.min' (orbit_toFinset_nonempty x)
  mem_orbit := by
    -- `min' s _ ∈ s` (Finset.min'_mem), then pass through
    -- `mem_orbit_toFinset_iff`.
    intro x
    exact (mem_orbit_toFinset_iff x _).mp
      (Finset.min'_mem _ (orbit_toFinset_nonempty x))
  orbit_iff := by
    intro x y
    constructor
    · -- Forward: canon x = canon y → orbit G x = orbit G y.
      -- Set m := canon x = canon y; m is in both orbits by min'_mem +
      -- mem_orbit_toFinset_iff, so orbit G m = orbit G x = orbit G y via
      -- MulAction.orbit_eq_iff.
      intro h_canon_eq
      -- m ∈ orbit G x (by min'_mem and iff).
      have hm_x : (MulAction.orbit G x).toFinset.min'
          (orbit_toFinset_nonempty x) ∈ MulAction.orbit G x :=
        (mem_orbit_toFinset_iff x _).mp
          (Finset.min'_mem _ (orbit_toFinset_nonempty x))
      -- `canon x = canon y` rewrites min' of orbit x to min' of orbit y,
      -- giving m ∈ orbit G y.
      have hm_y : (MulAction.orbit G x).toFinset.min'
          (orbit_toFinset_nonempty x) ∈ MulAction.orbit G y := by
        rw [h_canon_eq]
        exact (mem_orbit_toFinset_iff y _).mp
          (Finset.min'_mem _ (orbit_toFinset_nonempty y))
      -- Conclude via transitivity through m's orbit.
      rw [← MulAction.orbit_eq_iff.mpr hm_x,
          ← MulAction.orbit_eq_iff.mpr hm_y]
    · -- Reverse: orbit G x = orbit G y → canon x = canon y.
      -- Equal orbits as Set → equal .toFinset values (Set.toFinset_congr).
      -- Equal finsets give equal min' values (congr_arg + proof-irrel
      -- for the non-emptiness argument).
      intro h_orbit_eq
      congr 1
      exact Set.toFinset_congr h_orbit_eq

/-- Unfolding lemma for `ofLexMin`'s `canon` field: `canon x` is the
    `min'` of the orbit's `toFinset` with the base-point non-emptiness
    witness. -/
@[simp]
theorem CanonicalForm.ofLexMin_canon (x : X) :
    (CanonicalForm.ofLexMin (G := G) (X := X)).canon x =
      (MulAction.orbit G x).toFinset.min' (orbit_toFinset_nonempty x) :=
  rfl

/-- Restatement of `mem_orbit` for `ofLexMin` with the shared name used
    downstream. Equivalent to `CanonicalForm.mem_orbit` on the abstract
    structure — provided at the `ofLexMin` level so callers needn't
    project through the structure field. -/
theorem CanonicalForm.ofLexMin_canon_mem_orbit (x : X) :
    (CanonicalForm.ofLexMin (G := G) (X := X)).canon x ∈
      MulAction.orbit G x :=
  (CanonicalForm.ofLexMin (G := G) (X := X)).mem_orbit x

end OfLexMin

end Orbcrypt
