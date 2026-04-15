# Phase 8 — Probabilistic Foundations

## Weeks 18–22 | 10 Work Units | ~40 Hours

*Part of the [Orbcrypt Practical Improvements Plan](../../formalization/PRACTICAL_IMPROVEMENTS_PLAN.md)*

---

## Overview

Phase 8 replaces the deterministic OIA (which is `False` for all non-trivial
schemes) with a probabilistic formulation that captures meaningful
computational indistinguishability. This is the most technically challenging
phase and the most impactful for theoretical credibility.

**The core problem:** The current OIA states:

```lean
def OIA (scheme : OrbitEncScheme G X M) : Prop :=
  ∀ (f : X → Bool) (m₀ m₁ : M) (g₀ g₁ : G),
    f (g₀ • scheme.reps m₀) = f (g₁ • scheme.reps m₁)
```

This quantifies over ALL Boolean functions, including
`fun x => decide (x = reps m₀)`, which trivially separates orbits.
Therefore `OIA scheme` is `False` for any scheme with distinct
representatives. The security theorem `oia_implies_1cpa` is vacuously
true (ex falso quodlibet).

**The fix:** Introduce a probability monad and work with *distributions*
over orbit elements rather than individual elements. The probabilistic
OIA states: for all distinguishers D, the advantage
`|Pr[D(g · x_{m₀}) = 1] - Pr[D(g · x_{m₁}) = 1]|` is bounded.

**Approach:** We use Mathlib's `PMF` type (option A) unless blocked, with
a fallback to a simpler `ConcreteOIA` that avoids asymptotic machinery.

---

## Objectives

1. Wrap Mathlib's PMF with cryptographic convenience definitions.
2. Define negligible functions with closure properties.
3. Define distinguishing advantage with triangle inequality.
4. Define orbit distributions via `PMF.map`.
5. Define ConcreteOIA (primary) and CompOIA (stretch goal).
6. Define probabilistic IND-1-CPA advantage.
7. Prove: ConcreteOIA implies bounded IND-1-CPA advantage.
8. Prove the hybrid argument lemma for multi-query reduction.
9. Bridge: deterministic OIA implies probabilistic OIA.
10. State multi-query security skeleton.

---

## Prerequisites

- Phases 1–6 complete (all existing Lean modules)
- Mathlib PMF API available at pinned commit

---

## New Files

```
Orbcrypt/
  Probability/
    Monad.lean           — PMF type, uniform distribution, bind/map
    Negligible.lean      — Negligible function definition
    Advantage.lean       — Statistical distance, advantage definition
  Crypto/
    CompOIA.lean         — Computational (probabilistic) OIA
    CompSecurity.lean    — Probabilistic IND-CPA security game
```

---

## Work Units

### Track A: Probability Infrastructure (8.1 → 8.2 → 8.3 → 8.9)

---

#### 8.1 — Probability Monad Wrapper

**Effort:** 4h | **File:** `Probability/Monad.lean` | **Deps:** Mathlib

**Sub-tasks:**

**8.1a — Mathlib PMF import validation (1h).** Verify the required Mathlib
modules exist at the pinned commit:

```bash
grep -r "ProbabilityMassFunction" .lake/packages/mathlib/Mathlib/ --include="*.lean" -l
```

Verify: `PMF.uniformOfFintype`, `PMF.map`, `PMF.bind`, `PMF.pure` are all
available. If any are missing, document the gap and choose fallback.

Exit: written note documenting available vs. needed API.

**8.1b — uniformPMF and basic wrappers (1.5h).** Define:

```lean
noncomputable def uniformPMF (α : Type*) [Fintype α] [Nonempty α] : PMF α :=
  PMF.uniformOfFintype α

noncomputable def probEvent (d : PMF α) (p : α → Prop)
    [DecidablePred p] : ℝ≥0∞ :=
  d.toOuterMeasure {x | p x}

noncomputable def probTrue (d : PMF α) (f : α → Bool) : ℝ≥0∞ :=
  probEvent d (fun x => f x = true)
```

Exit: all three definitions compile.

**8.1c — Sanity lemmas (1.5h).** Prove:

```lean
theorem probEvent_certain (d : PMF α) :
    probEvent d (fun _ => True) = 1

theorem probEvent_impossible (d : PMF α) :
    probEvent d (fun _ => False) = 0
```

Exit: at least these two compile. Coin lemma is a stretch goal.

**Fallback:** If Mathlib PMF is unworkable, define:

```lean
structure FinDist (α : Type*) [Fintype α] where
  weights : α → ℚ≥0
  sum_one : Finset.sum Finset.univ weights = 1
```

**Exit criteria:** All sub-tasks pass or fallback is activated.

---

#### 8.2 — Negligible Function Definition

**Effort:** 3h | **File:** `Probability/Negligible.lean` | **Deps:** Mathlib

```lean
def IsNegligible (f : ℕ → ℝ) : Prop :=
  ∀ (c : ℕ), ∃ n₀ : ℕ, ∀ n : ℕ, n₀ ≤ n → |f n| < (n : ℝ)⁻¹ ^ c
```

Prove closure properties:
- `IsNegligible.add` — sum of negligible is negligible
- `IsNegligible.mul_poly` — negligible times polynomial is negligible
- `isNegligible_zero` — zero is negligible

**Exit criteria:** Definition and closure lemmas compile.

---

#### 8.3 — Advantage Definition

**Effort:** 4h | **File:** `Probability/Advantage.lean` | **Deps:** 8.1, 8.2

**Sub-tasks:**

**8.3a — Core definition (1h).**

```lean
noncomputable def advantage (D : α → Bool) (d₀ d₁ : PMF α) : ℝ :=
  |(probTrue d₀ D).toReal - (probTrue d₁ D).toReal|
```

Exit: definition type-checks.

**8.3b — Basic properties (1.5h).**

```lean
theorem advantage_nonneg : 0 ≤ advantage D d₀ d₁ := abs_nonneg _
theorem advantage_symm : advantage D d₀ d₁ = advantage D d₁ d₀ := abs_sub_comm _ _
theorem advantage_le_one : advantage D d₀ d₁ ≤ 1  -- requires PMF bounds
```

Exit: all three compile.

**8.3c — Triangle inequality (1.5h).**

```lean
theorem advantage_triangle (D : α → Bool) (d₀ d₁ d₂ : PMF α) :
    advantage D d₀ d₂ ≤ advantage D d₀ d₁ + advantage D d₁ d₂
```

Proof via `abs_sub_abs_le_abs_sub` from Mathlib.

Exit: lemma compiles.

**Exit criteria:** All sub-tasks pass `lake build`.

---

#### 8.9 — Hybrid Argument Lemma

**Effort:** 4h | **File:** `Probability/Advantage.lean` | **Deps:** 8.3

**Sub-tasks:**

**8.9a — Self-advantage and base case (1h).**

```lean
theorem advantage_self (D : α → Bool) (d : PMF α) :
    advantage D d d = 0

theorem hybrid_two (d₀ d₁ d₂ : PMF α) (D : α → Bool) :
    advantage D d₀ d₂ ≤ advantage D d₀ d₁ + advantage D d₁ d₂
```

Exit: both compile.

**8.9b — General hybrid statement (1.5h).**

```lean
theorem hybrid_argument (hybrids : Fin (n+1) → PMF α) (D : α → Bool) :
    advantage D (hybrids 0) (hybrids (Fin.last n)) ≤
    Finset.sum Finset.univ (fun i : Fin n =>
      advantage D (hybrids i.castSucc) (hybrids i.succ))
```

Exit: statement type-checks.

**8.9c — Inductive proof (1.5h).** Prove by induction on n.

Helper lemma needed first:
```lean
theorem advantage_self (D : α → Bool) (d : PMF α) :
    advantage D d d = 0 := by
  simp [advantage, sub_self, abs_zero]
```

Proof strategy for `hybrid_argument`:
```lean
theorem hybrid_argument : ... := by
  induction n with
  | zero =>
    -- hybrids : Fin 1 → PMF α, so hybrids 0 = hybrids (Fin.last 0)
    -- LHS = advantage D d d = 0 (by advantage_self)
    -- RHS = Finset.sum Finset.univ (empty) = 0
    simp [advantage_self]
  | succ n ih =>
    -- Split: advantage D (hybrids 0) (hybrids (Fin.last (n+1)))
    --   ≤ advantage D (hybrids 0) (hybrids (Fin.last n).castSucc)
    --     + advantage D (hybrids (Fin.last n).castSucc) (hybrids (Fin.last (n+1)))
    -- Apply advantage_triangle, then IH on the prefix
    calc advantage D (hybrids 0) (hybrids (Fin.last (n+1)))
        ≤ advantage D (hybrids 0) (hybrids n.castSucc)
          + advantage D (hybrids n.castSucc) (hybrids (Fin.last (n+1)))
            := advantage_triangle ...
      _ ≤ ... := by rw [Finset.sum_univ_succ]; linarith [ih ...]
```

The `Fin` arithmetic is the main difficulty. Key Mathlib lemmas:
- `Fin.last_succ` for connecting `Fin.last (n+1)` with `(Fin.last n).succ`
- `Finset.sum_univ_succ` for splitting the sum into prefix + last element
- `Fin.castSucc` coercion for lifting `Fin n` into `Fin (n+1)`

If the `Fin` manipulation proves too cumbersome, an alternative approach
is to prove the equivalent statement for `List (PMF α)` and convert.

Exit: full proof compiles with zero `sorry`.

**Exit criteria:** All sub-tasks pass `lake build`.

---

### Track B: Orbit Distributions and OIA (8.4 → 8.5)

---

#### 8.4 — Orbit Distribution Definition

**Effort:** 4h | **File:** `Crypto/CompOIA.lean` | **Deps:** 8.1

**Sub-tasks:**

**8.4a — orbitDist definition (1h).**

```lean
noncomputable def orbitDist [Fintype G] [Nonempty G]
    [Group G] [MulAction G X] (x : X) : PMF X :=
  PMF.map (fun g => g • x) (uniformPMF G)
```

Exit: definition type-checks.

**8.4b — orbitDist basic properties (1.5h).**

```lean
theorem orbitDist_support (x y : X) :
    (orbitDist x) y ≠ 0 → y ∈ MulAction.orbit G x

theorem orbitDist_pos_of_mem (x y : X) (hy : y ∈ MulAction.orbit G x) :
    (orbitDist x) y ≠ 0
```

Exit: at least `orbitDist_support` compiles.

**8.4c — Free-action uniformity (1.5h, stretch goal).**

```lean
theorem orbitDist_uniform_of_free (x : X)
    (hFree : MulAction.stabilizer G x = ⊥) (y : X)
    (hy : y ∈ MulAction.orbit G x) :
    (orbitDist x) y = 1 / Fintype.card (MulAction.orbit G x)
```

Requires showing `g ↦ g • x` is injective when stabilizer is trivial.

Exit: compiles or marked `sorry` with documentation.

**Exit criteria:** 8.4a and 8.4b pass. 8.4c is a documented stretch goal.

---

#### 8.5 — Computational OIA (Probabilistic)

**Effort:** 5h | **File:** `Crypto/CompOIA.lean` | **Deps:** 8.3, 8.4

**Sub-tasks:**

**8.5a — SchemeFamily type (1h, stretch goal).**

```lean
structure SchemeFamily where
  G : ℕ → Type*
  X : ℕ → Type*
  M : ℕ → Type*
  instGroup : ∀ λ, Group (G λ)
  instAction : ∀ λ, MulAction (G λ) (X λ)
  instFintype : ∀ λ, Fintype (G λ)
  instNonempty : ∀ λ, Nonempty (G λ)
  instDecEq : ∀ λ, DecidableEq (X λ)
  scheme : ∀ λ, @OrbitEncScheme (G λ) (X λ) (M λ)
    (instGroup λ) (instAction λ) (instDecEq λ)
```

Exit: type-checks (trickiest part — may need manual `@` annotations).

**8.5b — Asymptotic CompOIA definition (1.5h, stretch goal).**

```lean
def CompOIA (sf : SchemeFamily) : Prop :=
  ∀ (D : ∀ λ, sf.X λ → Bool) (m₀ m₁ : ∀ λ, sf.M λ),
    IsNegligible (fun λ => @advantage (sf.X λ) (D λ)
      (@orbitDist ...) (@orbitDist ...))
```

Exit: type-checks.

**8.5c — ConcreteOIA fallback (1h, primary target).**

```lean
def ConcreteOIA [Fintype G] [Nonempty G] [Group G] [MulAction G X]
    [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (ε : ℝ) : Prop :=
  ∀ (D : X → Bool) (m₀ m₁ : M),
    advantage D (orbitDist (scheme.reps m₀)) (orbitDist (scheme.reps m₁)) ≤ ε
```

Exit: type-checks.

**8.5d — ConcreteOIA lemmas (1.5h).**

```lean
theorem concreteOIA_zero_implies_perfect (scheme : OrbitEncScheme G X M)
    (hOIA : ConcreteOIA scheme 0) (D : X → Bool) (m₀ m₁ : M) :
    advantage D (orbitDist (scheme.reps m₀)) (orbitDist (scheme.reps m₁)) = 0

theorem concreteOIA_mono (ε₁ ε₂ : ℝ) (hle : ε₁ ≤ ε₂)
    (hOIA : ConcreteOIA scheme ε₁) : ConcreteOIA scheme ε₂
```

Exit: both compile.

**Design note:** ConcreteOIA is the primary target. CompOIA is a stretch goal.

**Implementation order:** Start with 8.5c (ConcreteOIA) and 8.5d (lemmas).
Only attempt 8.5a (SchemeFamily) and 8.5b (CompOIA) after 8.5c/d compile
successfully. If SchemeFamily causes type-elaboration issues (likely due to
dependent instance bundling), abandon it and proceed with ConcreteOIA only.
This decision does NOT affect downstream work units — 8.6, 8.7, 8.8 all
have ConcreteOIA-based variants as their primary targets.

**Exit criteria:** At least ConcreteOIA (8.5c + 8.5d) compiles.

---

### Track C: Security Theorems (8.6 → 8.7 → 8.8 → 8.10)

Merges Tracks A and B.

---

#### 8.6 — Probabilistic IND-CPA Game

**Effort:** 5h | **File:** `Crypto/CompSecurity.lean` | **Deps:** 8.1, 8.3

**Sub-tasks:**

**8.6a — indCPAAdvantage definition (1.5h).**

```lean
noncomputable def indCPAAdvantage [Fintype G] [Nonempty G]
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) : ℝ :=
  let (m₀, m₁) := A.choose scheme.reps
  advantage (fun x => A.guess scheme.reps x)
    (orbitDist (scheme.reps m₀))
    (orbitDist (scheme.reps m₁))
```

Exit: type-checks.

**8.6b — Unfolding lemma (1.5h).**

```lean
theorem indCPAAdvantage_eq (scheme : OrbitEncScheme G X M) (A : Adversary X M) :
    indCPAAdvantage scheme A =
    advantage (fun x => A.guess scheme.reps x)
      (orbitDist (scheme.reps (A.choose scheme.reps).1))
      (orbitDist (scheme.reps (A.choose scheme.reps).2))
```

Exit: compiles (may be `rfl`).

**8.6c — Bridge to deterministic hasAdvantage (2h, stretch goal).**

```lean
theorem hasAdvantage_implies_pos_indCPA (scheme : OrbitEncScheme G X M)
    (A : Adversary X M) (hAdv : hasAdvantage scheme A) :
    0 < indCPAAdvantage scheme A
```

Exit: compiles or documented as requiring specific PMF properties.

**Exit criteria:** 8.6a compiles. 8.6b and 8.6c are stretch goals.

---

#### 8.7 — Probabilistic Security Theorem

**Effort:** 5h | **File:** `Crypto/CompSecurity.lean` | **Deps:** 8.5, 8.6

**Sub-tasks:**

**8.7a — Concrete security theorem (2h, primary target).**

```lean
theorem concrete_oia_implies_1cpa [Fintype G] [Nonempty G]
    (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (hOIA : ConcreteOIA scheme ε) (A : Adversary X M) :
    indCPAAdvantage scheme A ≤ ε
```

Proof: unfold `indCPAAdvantage`; the adversary's guess is a distinguisher;
apply `ConcreteOIA` directly.

Exit: compiles with zero `sorry`.

**8.7b — Satisfiability witness (1h).**

```lean
theorem concreteOIA_one (scheme : OrbitEncScheme G X M) :
    ConcreteOIA scheme 1
```

Shows ConcreteOIA is not vacuously unsatisfiable.

Exit: compiles.

**8.7c — Asymptotic security (2h, stretch goal).**

```lean
theorem comp_oia_implies_1cpa (sf : SchemeFamily) (hOIA : CompOIA sf)
    (A : ∀ λ, Adversary (sf.X λ) (sf.M λ)) :
    IsNegligible (fun λ => indCPAAdvantage (sf.scheme λ) (A λ))
```

Exit: compiles or documented.

**Exit criteria:** 8.7a compiles with zero `sorry`.

---

#### 8.8 — Bridge: Deterministic OIA Implies Probabilistic OIA

**Effort:** 3h | **File:** `Crypto/CompOIA.lean` | **Deps:** 8.5, Phase 3

```lean
theorem det_oia_implies_comp_oia (scheme : OrbitEncScheme G X M)
    (hOIA : OIA scheme) (D : X → Bool) (m₀ m₁ : M) :
    advantage D (orbitDist (scheme.reps m₀)) (orbitDist (scheme.reps m₁)) = 0
```

Compatibility theorem: deterministic OIA implies zero probabilistic advantage.
Since `OIA scheme` is `False` for non-trivial schemes, this is vacuously
true — but it serves as a sanity check.

**Exit criteria:** Theorem compiles.

---

#### 8.10 — Multi-Query Security Skeleton

**Effort:** 3h | **File:** `Crypto/CompSecurity.lean` | **Deps:** 8.7, 8.9

```lean
/-- Multi-query IND-CPA security skeleton. Full proof requires HSP
    formalization (out of scope). -/
theorem comp_oia_implies_qcpa
    (schemeFamily : ℕ → OrbitEncScheme G X M)
    (hOIA : CompOIA schemeFamily)
    (Q : ℕ → ℕ) (hHSP : HSPHard G)
    (A : ℕ → MultiQueryAdversary X M) :
    IsNegligible (fun λ => indQCPAAdvantage (schemeFamily λ) (Q λ) (A λ)) :=
  sorry -- HSP formalization is out of scope
```

This is explicitly a skeleton with `sorry`. The value is in the correct
type signature for future formalization.

**Exit criteria:** Statement type-checks. Module docstring explains the `sorry`.

---

## Internal Dependency Graph

```
Track A:  8.1 (PMF) → 8.2 (Negligible) → 8.3 (Advantage) → 8.9 (Hybrid)
                                               |
Track B:  8.1 (PMF) → 8.4 (OrbitDist) → 8.5 (OIA defs)
                                               |
                                    ┌──────────┴──────────┐
Track C:                         8.6 (IND-CPA)         8.8 (Bridge)
                                    |
                                 8.7 (Security thm)
                                    |
                                 8.10 (Multi-query)
```

**Critical path:** 8.1 → 8.4 → 8.5 → 8.6 → 8.7 (23h)

---

## Parallelism Notes

- **Track A** (8.1 → 8.2 → 8.3 → 8.9) and **Track B** (8.1 → 8.4 → 8.5)
  can proceed in parallel after 8.1.
- **Track C** merges A and B at 8.6.
- 8.8 (bridge) depends only on 8.5 and Phase 3; can run independently.

---

## Risk Analysis

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Mathlib PMF API inadequate | Medium | High | Fall back to ConcreteOIA with FinDist |
| SchemeFamily type plumbing fails | High | Medium | Use ConcreteOIA as primary target |
| `advantage_le_one` requires deep PMF lemmas | Medium | Low | Accept as sorry if needed |
| `orbitDist_uniform_of_free` too hard | Medium | Low | Mark as stretch goal |
| Lean elaboration struggles with families | High | Medium | Use explicit `@` annotations |

**Key risk mitigation:** ConcreteOIA is the primary target throughout. Every
unit has a concrete-security fallback that avoids the SchemeFamily plumbing.

---

## Go/No-Go Decision Point

After Phase 8: If the probabilistic OIA cannot be stated in a satisfiable
way within Lean, the theoretical improvement over Phases 1–6 is minimal.
Decision: publish with deterministic formalization and note the probabilistic
gap as future work.

---

## Phase Exit Criteria

1. `Probability/Monad.lean` compiles with `uniformPMF`, `probEvent`, `probTrue`.
2. `Probability/Negligible.lean` compiles with `IsNegligible` and closures.
3. `Probability/Advantage.lean` compiles with `advantage` and triangle inequality.
4. `Crypto/CompOIA.lean` compiles with at least `ConcreteOIA` and `orbitDist`.
5. `Crypto/CompSecurity.lean` compiles with `indCPAAdvantage`.
6. `concrete_oia_implies_1cpa` has zero `sorry`.
7. `hybrid_argument` has zero `sorry`.
8. Every intentional `sorry` (8.10, stretch goals) is documented in its
   module docstring with what would be needed to fill it.
9. `#print axioms concrete_oia_implies_1cpa` shows only standard axioms.

---

## Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 8.1 | Probability Monad Wrapper | `Probability/Monad.lean` | 4h | Mathlib |
| 8.2 | Negligible Functions | `Probability/Negligible.lean` | 3h | Mathlib |
| 8.3 | Advantage Definition | `Probability/Advantage.lean` | 4h | 8.1, 8.2 |
| 8.4 | Orbit Distribution | `Crypto/CompOIA.lean` | 4h | 8.1 |
| 8.5 | Computational OIA | `Crypto/CompOIA.lean` | 5h | 8.3, 8.4 |
| 8.6 | Probabilistic IND-CPA | `Crypto/CompSecurity.lean` | 5h | 8.1, 8.3 |
| 8.7 | Probabilistic Security Thm | `Crypto/CompSecurity.lean` | 5h | 8.5, 8.6 |
| 8.8 | Deterministic→Probabilistic | `Crypto/CompOIA.lean` | 3h | 8.5, Phase 3 |
| 8.9 | Hybrid Argument | `Probability/Advantage.lean` | 4h | 8.3 |
| 8.10 | Multi-Query Skeleton | `Crypto/CompSecurity.lean` | 3h | 8.7, 8.9 |
