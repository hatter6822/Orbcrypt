import Orbcrypt.GroupAction.Basic
import Orbcrypt.GroupAction.Canonical

/-!
# Orbcrypt.GroupAction.Invariant

G-invariant functions and their properties: `IsGInvariant`, `IsSeparating`,
the orbit constancy lemma, and proof that canonical forms are G-invariant.

A function is G-invariant if it is unchanged by the group action. This is the
central concept in the invariant attack theorem (DEVELOPMENT.md §4.4): if an
attacker finds a G-invariant function that distinguishes two message orbits,
the encryption scheme is completely broken.

## Main definitions and results

* `Orbcrypt.IsGInvariant` — `f(g • x) = f(x)` for all `g ∈ G, x ∈ X`
* `Orbcrypt.IsGInvariant.comp` — composition preserves G-invariance
* `Orbcrypt.isGInvariant_const` — constant functions are G-invariant
* `Orbcrypt.invariant_const_on_orbit` — G-invariant functions are constant on orbits
* `Orbcrypt.IsSeparating` — invariant function that distinguishes two points
* `Orbcrypt.separating_implies_distinct_orbits` — separation implies distinct orbits
* `Orbcrypt.canonical_isGInvariant` — canonical form is G-invariant
* `Orbcrypt.canon_indicator_isGInvariant` — Boolean indicator
  `fun x => decide (can.canon x = c)` is G-invariant. Workstream I3
  (audit 2026-04-23, finding D-07): the structural building block for
  `distinct_messages_have_invariant_separator`, witnessing that a
  canonical-form discriminator yields a G-invariant Boolean function.

## References

* DEVELOPMENT.md §4.4 — invariant attack analysis
* COUNTEREXAMPLE.md — concrete invariant attack via Hamming weight
* formalization/phases/PHASE_2_GROUP_ACTION_FOUNDATIONS.md — work units 2.8–2.11
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*} {Y : Type*}

-- ============================================================================
-- Work Unit 2.8: G-Invariant Function Definition
-- ============================================================================

section GInvariant

variable [Group G] [MulAction G X]

/--
A function `f : X → Y` is G-invariant if it is unchanged by the group action:
`f(g • x) = f(x)` for all `g ∈ G` and `x ∈ X`.

Equivalently, `f` is constant on each orbit of `G`. This is the central
concept in the invariant attack theorem (DEVELOPMENT.md §4.4).
-/
def IsGInvariant (f : X → Y) : Prop :=
  ∀ (g : G) (x : X), f (g • x) = f x

/-- Composition with any function preserves G-invariance.
    If `f` is G-invariant, then `h ∘ f` is G-invariant for any `h`. -/
theorem IsGInvariant.comp {f : X → Y} (hf : IsGInvariant (G := G) f)
    {Z : Type*} (h : Y → Z) :
    IsGInvariant (G := G) (h ∘ f) := by
  intro g x
  simp only [Function.comp]
  rw [hf g x]

/-- A constant function is G-invariant. -/
theorem isGInvariant_const (c : Y) :
    IsGInvariant (G := G) (fun (_ : X) => c) := by
  intro _ _; rfl

end GInvariant

-- ============================================================================
-- Work Unit 2.9: Invariant-Orbit Lemma
-- ============================================================================

section InvariantOrbit

variable [Group G] [MulAction G X]

/--
A G-invariant function takes the same value on all elements of an orbit.
This is the key lemma used in the invariant attack theorem (Phase 4):
if `f` is invariant and `c = g • x_m` is a ciphertext, then `f(c) = f(x_m)`.

**Proof:** `y ∈ orbit G x` gives `∃ g, g • x = y`. Then
`f(y) = f(g • x) = f(x)` by G-invariance.
-/
theorem invariant_const_on_orbit {f : X → Y}
    (hf : IsGInvariant (G := G) f) {x y : X}
    (hy : y ∈ MulAction.orbit G x) :
    f y = f x := by
  obtain ⟨g, rfl⟩ := MulAction.mem_orbit_iff.mp hy
  exact hf g x

end InvariantOrbit

-- ============================================================================
-- Work Unit 2.10: Separating Invariant Definition
-- ============================================================================

section Separating

variable [Group G] [MulAction G X]

/--
A function `f` separates two points `x₀` and `x₁` under a group action if:
1. `f` is G-invariant, and
2. `f(x₀) ≠ f(x₁)`.

The invariant attack theorem (Phase 4) shows that any separating function
yields `∃ A : Adversary X M, hasAdvantage scheme A` — existence of a
distinguishing `(g₀, g₁)` pair. Informal shorthand: "complete break";
see the `invariant_attack` docstring in
`Orbcrypt/Theorems/InvariantAttack.lean` for the three-convention
advantage catalogue (deterministic = 1, two-distribution = 1,
centered = 1/2) — all three agree on "complete break", but they
differ on intermediate advantages by a factor of 2.
-/
def IsSeparating (f : X → Y) (x₀ x₁ : X) : Prop :=
  IsGInvariant (G := G) f ∧ f x₀ ≠ f x₁

/-- A separating invariant implies that its arguments lie in distinct orbits.

    **Proof (by contradiction):** If the orbits were equal, then `x₁ ∈ orbit G x₀`,
    so by `invariant_const_on_orbit` we'd have `f(x₁) = f(x₀)`, contradicting
    the separation condition `f(x₀) ≠ f(x₁)`. -/
theorem separating_implies_distinct_orbits {f : X → Y} {x₀ x₁ : X}
    (h : IsSeparating (G := G) f x₀ x₁) :
    MulAction.orbit G x₀ ≠ MulAction.orbit G x₁ := by
  intro heq
  apply h.2
  -- x₁ ∈ orbit G x₁ = orbit G x₀, so f(x₁) = f(x₀) by invariance
  have hx₁_mem : x₁ ∈ MulAction.orbit G x₀ :=
    heq ▸ MulAction.mem_orbit_self x₁
  exact (invariant_const_on_orbit h.1 hx₁_mem).symm

end Separating

-- ============================================================================
-- Work Unit 2.11: Canonical Form Is G-Invariant
-- ============================================================================

section CanonicalInvariant

variable [Group G] [MulAction G X]

/--
The canonical form function is G-invariant: `canon(g • x) = canon(x)`.
This connects the canonical form (used for decryption) to the invariant
framework (used for security analysis). The proof uses that the group action
preserves orbits (`MulAction.orbit_smul`) together with the canonical form's
orbit characterization property.
-/
theorem canonical_isGInvariant (can : CanonicalForm G X) :
    IsGInvariant (G := G) can.canon := by
  intro g x
  -- orbit G (g • x) = orbit G x by MulAction.orbit_smul
  -- Then can.orbit_iff gives canon (g • x) = canon x
  exact (can.orbit_iff (g • x) x).mpr (MulAction.orbit_smul g x)

/--
**Canonical-form indicator is G-invariant** (Workstream I3, audit
2026-04-23 finding D-07).

For any canonical form `can : CanonicalForm G X` and any fixed point
`c : X`, the Boolean indicator `fun x => decide (can.canon x = c)` is
G-invariant. The proof composes `decide (· = c)` with the G-invariant
`can.canon` via `canonical_isGInvariant`.

**Role.** This is the structural building block for
`distinct_messages_have_invariant_separator` in
`Theorems/OIAImpliesCPA.lean`: any canonical-form-derived discriminator
delivers G-invariance unconditionally, which the pre-Workstream-I
`insecure_implies_separating` theorem (now renamed
`insecure_implies_orbit_distinguisher`) did not provide. Exposed as a
free-standing Mathlib-style lemma so consumers can build their own
G-invariant Boolean tests without re-deriving the canonical-form
invariance argument at every call site.
-/
theorem canon_indicator_isGInvariant [DecidableEq X]
    (can : CanonicalForm G X) (c : X) :
    IsGInvariant (G := G) (fun x => decide (can.canon x = c)) := by
  intro g x
  -- Goal: decide (can.canon (g • x) = c) = decide (can.canon x = c).
  -- `canonical_isGInvariant can g x : can.canon (g • x) = can.canon x`
  -- rewrites the LHS to match the RHS exactly.
  show decide (can.canon (g • x) = c) = decide (can.canon x = c)
  rw [canonical_isGInvariant can g x]

end CanonicalInvariant

end Orbcrypt
