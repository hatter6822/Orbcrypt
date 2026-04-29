/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.Probability.Monad
import Orbcrypt.Probability.Negligible
import Orbcrypt.Probability.Advantage
import Orbcrypt.Crypto.OIA

/-!
# Orbcrypt.Crypto.CompOIA

Probabilistic (computational) Orbit Indistinguishability Assumption,
replacing the vacuously-false deterministic OIA with a meaningful
cryptographic assumption.

## Main definitions

* `Orbcrypt.orbitDist` — orbit distribution: push uniform G through `g ↦ g • x`
* `Orbcrypt.ConcreteOIA` — concrete-security OIA with explicit bound `ε`
* `Orbcrypt.CompOIA` — asymptotic OIA with negligible advantage
* `Orbcrypt.SchemeFamily` — security-parameter-indexed scheme family
  (explicitly universe-polymorphic over `u, v, w` after audit F-15)
* `Orbcrypt.SchemeFamily.repsAt` — per-level representative under the
  family (readability helper, F-13)
* `Orbcrypt.SchemeFamily.orbitDistAt` — per-level orbit distribution under
  the family (readability helper, F-13)
* `Orbcrypt.SchemeFamily.advantageAt` — per-level distinguishing advantage
  under the family (readability helper, F-13)

## Main results

* `Orbcrypt.orbitDist_support` — orbit distribution supported on orbit
* `Orbcrypt.concreteOIA_mono` — ConcreteOIA is monotone in `ε`
* `Orbcrypt.concreteOIA_one` — ConcreteOIA with `ε = 1` is trivially true
* `Orbcrypt.det_oia_implies_concrete_zero` — deterministic OIA implies ConcreteOIA 0

## References

* DEVELOPMENT.md §5.2 — probabilistic OIA definition
* formalization/PRACTICAL_IMPROVEMENTS_PLAN.md — Phase 8, work units 8.4, 8.5, 8.8
-/

namespace Orbcrypt

open PMF ENNReal

-- Explicit universe variables for `SchemeFamily` (audit F-15 / Workstream B2).
-- Making `u, v, w` first-class lets consumers thread them by name at call
-- sites (`@SchemeFamily.{u, v, w} ...`) and avoids the implicit
-- universe-inference pain that appears when `G, X, M` use `Type*`.
universe u v w

variable {G : Type*} {X : Type*} {M : Type*}

-- ============================================================================
-- Work Unit 8.4a: Orbit distribution definition
-- ============================================================================

/-- The orbit distribution of `x` under `G`: sample a uniform group element
    `g ∈ G` and return `g • x`. -/
noncomputable def orbitDist [Group G] [Fintype G] [Nonempty G] [MulAction G X]
    (x : X) : PMF X :=
  PMF.map (fun g => g • x) (uniformPMF G)

-- ============================================================================
-- Work Unit 8.4b: Orbit distribution basic properties
-- ============================================================================

/-- Elements with positive probability under `orbitDist x` lie in the orbit
    of `x`. -/
theorem orbitDist_support [Group G] [Fintype G] [Nonempty G] [MulAction G X]
    [DecidableEq X] (x : X) (y : X)
    (hy : (orbitDist (G := G) x : PMF X) y ≠ 0) :
    y ∈ MulAction.orbit G x := by
  have hmem : y ∈ (orbitDist (G := G) x : PMF X).support := hy
  rw [orbitDist, PMF.support_map] at hmem
  obtain ⟨g, _, rfl⟩ := hmem
  exact MulAction.mem_orbit _ _

/-- Every orbit element has positive probability under the orbit distribution. -/
theorem orbitDist_pos_of_mem [Group G] [Fintype G] [Nonempty G] [MulAction G X]
    [DecidableEq X] (x : X) (y : X)
    (hy : y ∈ MulAction.orbit G x) :
    (orbitDist (G := G) x : PMF X) y ≠ 0 := by
  rw [MulAction.mem_orbit_iff] at hy
  obtain ⟨g, rfl⟩ := hy
  show (g • x) ∈ (orbitDist (G := G) x : PMF X).support
  rw [orbitDist, PMF.support_map]
  exact ⟨g, mem_support_uniformPMF g, rfl⟩

-- ============================================================================
-- Work Unit 8.5c: Concrete OIA definition (primary target)
-- ============================================================================

/-- **Concrete-security OIA**: For a specific scheme, every Boolean
    distinguisher has advantage at most `ε` between any two orbit
    distributions. -/
def ConcreteOIA [Group G] [Fintype G] [Nonempty G] [MulAction G X]
    [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (ε : ℝ) : Prop :=
  ∀ (D : X → Bool) (m₀ m₁ : M),
    advantage D (orbitDist (G := G) (scheme.reps m₀))
      (orbitDist (G := G) (scheme.reps m₁)) ≤ ε

-- ============================================================================
-- Work Unit 8.5d: ConcreteOIA basic lemmas
-- ============================================================================

/-- ConcreteOIA with `ε = 0` implies perfect indistinguishability. -/
theorem concreteOIA_zero_implies_perfect [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (hOIA : ConcreteOIA scheme 0) (D : X → Bool) (m₀ m₁ : M) :
    advantage D (orbitDist (G := G) (scheme.reps m₀))
      (orbitDist (G := G) (scheme.reps m₁)) = 0 := by
  exact le_antisymm (hOIA D m₀ m₁) (advantage_nonneg D _ _)

/-- ConcreteOIA is monotone in the bound. -/
theorem concreteOIA_mono [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) {ε₁ ε₂ : ℝ}
    (hle : ε₁ ≤ ε₂) (hOIA : ConcreteOIA scheme ε₁) :
    ConcreteOIA scheme ε₂ :=
  fun D m₀ m₁ => le_trans (hOIA D m₀ m₁) hle

/-- ConcreteOIA with `ε = 1` is trivially true: advantage never exceeds 1. -/
theorem concreteOIA_one [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) :
    ConcreteOIA scheme 1 :=
  fun D _ _ => advantage_le_one D _ _

-- ============================================================================
-- Work Unit 8.5a: Asymptotic scheme family type (stretch goal)
-- ============================================================================

/-- A family of orbit encryption schemes indexed by security parameter.

    After audit F-15 / Workstream B2 the structure is explicitly
    universe-polymorphic: the module-level `universe u v w` declaration
    above binds the three type-field universes. Consumers can therefore
    thread universe parameters by name at call sites
    (`@SchemeFamily.{u, v, w} ...`) and avoid the universe-inference pain
    that appears when `G, X, M` use the anonymous `Type*`. -/
structure SchemeFamily where
  /-- Group type at each security level (universe `u`). -/
  G : ℕ → Type u
  /-- Space type at each security level (universe `v`). -/
  X : ℕ → Type v
  /-- Message type at each security level (universe `w`). -/
  M : ℕ → Type w
  /-- Group instances. -/
  instGroup : ∀ n, Group (G n)
  /-- MulAction instances. -/
  instAction : ∀ n, MulAction (G n) (X n)
  /-- Fintype instances for groups. -/
  instFintype : ∀ n, Fintype (G n)
  /-- Nonempty instances for groups. -/
  instNonempty : ∀ n, Nonempty (G n)
  /-- DecidableEq instances for spaces. -/
  instDecEq : ∀ n, DecidableEq (X n)
  /-- The concrete scheme at each security level. -/
  scheme : ∀ n, @OrbitEncScheme (G n) (X n) (M n)
    (instGroup n) (instAction n) (instDecEq n)

-- ============================================================================
-- Readability helpers (audit finding F-13)
-- ============================================================================
--
-- Before these helpers, `CompOIA`, `CompIsSecure`, and the forthcoming
-- Workstream E hardness-chain definitions embedded ~10-token
-- `@`-qualified expressions inline. Those expressions are fragile under
-- Mathlib renames and make proof scripts hard to read. The three
-- definitions below centralise the explicit instance threading and let
-- downstream callers work in the named forms
-- `sf.repsAt`, `sf.orbitDistAt`, `sf.advantageAt`.

/-- Per-level representative embedding of message `m` at security level
    `n` under the scheme family `sf`. Equal by `rfl` to
    `(sf.scheme n).reps m`; introduced as a named helper so higher-level
    definitions avoid the `@`-threaded explicit-instance forms. -/
def SchemeFamily.repsAt (sf : SchemeFamily) (n : ℕ) (m : sf.M n) : sf.X n :=
  @OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n)
    (sf.instGroup n) (sf.instAction n) (sf.instDecEq n) (sf.scheme n) m

/-- Per-level orbit distribution of `sf.repsAt n m` at security level `n`.
    Push-forward of the uniform distribution on `sf.G n` through the
    group action — the concrete ciphertext distribution sampled by
    `encaps` on message `m`. -/
noncomputable def SchemeFamily.orbitDistAt (sf : SchemeFamily) (n : ℕ)
    (m : sf.M n) : PMF (sf.X n) :=
  @orbitDist (sf.G n) (sf.X n) (sf.instGroup n) (sf.instFintype n)
    (sf.instNonempty n) (sf.instAction n) (sf.repsAt n m)

/-- Per-level distinguishing advantage of the Boolean distinguisher `D n`
    between the two orbit distributions of `m₀ n` and `m₁ n`. -/
noncomputable def SchemeFamily.advantageAt (sf : SchemeFamily)
    (D : ∀ n, sf.X n → Bool) (m₀ m₁ : ∀ n, sf.M n) (n : ℕ) : ℝ :=
  @advantage (sf.X n) (D n) (sf.orbitDistAt n (m₀ n)) (sf.orbitDistAt n (m₁ n))

-- ============================================================================
-- Work Unit 8.5b: Asymptotic CompOIA definition (stretch goal)
-- ============================================================================

/-- **Asymptotic Computational OIA**: every family of distinguishers has
    negligible advantage between orbit distributions of different
    messages.

    After F-13 cleanup, the definition is stated in terms of
    `sf.advantageAt D m₀ m₁` rather than an inline `@`-threaded
    expression. The unfolded form is definitionally equal and is
    recovered by `simp [SchemeFamily.advantageAt, SchemeFamily.orbitDistAt,
    SchemeFamily.repsAt]` when needed. -/
def CompOIA (sf : SchemeFamily) : Prop :=
  ∀ (D : ∀ n, sf.X n → Bool) (m₀ m₁ : ∀ n, sf.M n),
    IsNegligible (sf.advantageAt D m₀ m₁)

-- ============================================================================
-- Work Unit 8.8: Bridge — Deterministic OIA implies Probabilistic OIA
-- ============================================================================

/-- The deterministic OIA implies ConcreteOIA with `ε = 0`.

    Proof: Under OIA, `D(g • reps m₀) = D(g • reps m₁)` for all g.
    So `Pr_g[D(g • reps m₀) = true] = Pr_g[D(g • reps m₁) = true]`,
    giving advantage exactly 0. -/
theorem det_oia_implies_concrete_zero [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (hOIA : OIA scheme) :
    ConcreteOIA scheme 0 := by
  intro D m₀ m₁
  suffices h : probTrue (orbitDist (G := G) (scheme.reps m₀)) D =
    probTrue (orbitDist (G := G) (scheme.reps m₁)) D by
    simp [advantage, h]
  -- Use toOuterMeasure_map_apply to reduce to preimage equality on uniformPMF G
  simp only [probTrue, orbitDist]
  rw [PMF.toOuterMeasure_map_apply, PMF.toOuterMeasure_map_apply]
  congr 1
  ext g
  simp only [Set.mem_preimage, Set.mem_setOf_eq]
  -- D(g • reps m₀) = true ↔ D(g • reps m₁) = true, from OIA
  constructor
  · intro h; rwa [← hOIA D m₀ m₁ g g]
  · intro h; rwa [hOIA D m₀ m₁ g g]

end Orbcrypt
