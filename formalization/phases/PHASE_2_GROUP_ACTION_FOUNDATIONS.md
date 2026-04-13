# Phase 2 — Group Action Foundations

## Weeks 2–4 | 16 Work Units | ~30 Hours

*Part of the [Orbcrypt Lean 4 Formalization Plan](../FORMALIZATION_PLAN.md)*

---

## Overview

Phase 2 builds the mathematical foundation that the entire formalization rests
upon. It populates the three `GroupAction/` modules — `Basic.lean`,
`Canonical.lean`, and `Invariant.lean` — with Mathlib wrappers, custom
definitions, and lemmas that directly support the cryptographic theorems in
Phase 4.

This phase has **three parallel tracks** after the initial Mathlib exploration
(unit 2.1), offering up to 3x speedup with multiple contributors.

---

## Objectives

1. A complete API for orbits, stabilizers, and orbit partitions built on
   Mathlib's `MulAction` framework.
2. An abstract `CanonicalForm` structure with uniqueness and idempotence proofs.
3. Formal definitions of G-invariant and separating functions with key lemmas
   connecting them to orbits.

---

## Prerequisites

- Phase 1 complete: `lake build` succeeds with Mathlib resolved.
- Familiarity with Mathlib's `MulAction` API (see §5 of the master plan).

---

## Work Units

### 2.1a — Mathlib API Exploration (Risk Reduction)

**Effort:** 1.5h | **Module:** scratch file | **Deps:** 1.4

Open a scratch `.lean` file and systematically explore the Mathlib API surface
that the entire formalization depends on. This is pure research — no deliverable
code, but the findings determine the implementation strategy for every
subsequent unit.

**Checklist:**
- [ ] `#check @MulAction.orbit` — confirm type signature
- [ ] `#check @MulAction.mem_orbit_iff` — confirm it gives `∃ g, g • x = y`
- [ ] `#check @MulAction.orbit_eq_iff` — confirm it gives orbit equality criterion
- [ ] Search for `MulAction.orbit_smul` or equivalent (needed for 2.4b)
- [ ] `#check @MulAction.orbitRel` — confirm it provides a `Setoid`
- [ ] `#check @MulAction.card_orbit_mul_card_stabilizer` — confirm Fintype constraints
- [ ] Check what `Fintype` instances exist for `MulAction.orbit` and `MulAction.stabilizer`
- [ ] Test whether `Disjoint` on `Set X` works smoothly or requires workarounds
- [ ] Document any API name mismatches between expected and actual Mathlib names

**Output:** A brief notes file listing confirmed API names, type signatures,
and any surprises. This prevents wasted effort in later units.

### 2.1b — Orbit API Wrappers

**Effort:** 1.5h | **Module:** `GroupAction/Basic.lean` | **Deps:** 2.1a

Using findings from 2.1a, write the convenience wrappers:

```lean
import Mathlib.GroupTheory.GroupAction.Basic
import Mathlib.GroupTheory.GroupAction.Defs

namespace Orbcrypt

/-- The orbit of `x` under the group `G`. -/
abbrev orbit (G : Type*) [Group G] [MulAction G X] (x : X) : Set X :=
  MulAction.orbit G x

/-- The stabilizer of `x` in `G`. -/
abbrev stabilizer (G : Type*) [Group G] [MulAction G X] (x : X) : Subgroup G :=
  MulAction.stabilizer G x

end Orbcrypt
```

**Definition of Done:** File compiles, `#check Orbcrypt.orbit` succeeds.

---

### 2.2a — Orbit Partition: Type Setup and Strategy Selection

**Effort:** 1.5h | **Module:** `GroupAction/Basic.lean` | **Deps:** 2.1b

State the orbit partition theorem and determine which proof strategy works
cleanest in Lean 4. There are two candidate approaches — try both in a
scratch file before committing.

**Approach 1 — Via `orbitRel` (preferred):**
```lean
theorem orbit_disjoint_or_eq [Group G] [MulAction G X]
    (x y : X) :
    MulAction.orbit G x = MulAction.orbit G y ∨
    Disjoint (MulAction.orbit G x) (MulAction.orbit G y) := by
  -- Use MulAction.orbitRel to get equivalence relation
  -- Equivalence classes are equal or disjoint by Setoid properties
  sorry
```

**Approach 2 — Direct (fallback if Disjoint is awkward):**
```lean
theorem orbit_disjoint_or_eq' [Group G] [MulAction G X]
    (x y : X) :
    MulAction.orbit G x = MulAction.orbit G y ∨
    (MulAction.orbit G x ∩ MulAction.orbit G y = ∅) := by
  -- If ∃ z ∈ intersection, obtain g₁ g₂ with g₁•x = z = g₂•y
  -- Then orbit G x = orbit G y via orbit_eq_iff
  -- Otherwise intersection is empty
  sorry
```

**Deliverable:** The theorem stated and compiling (with `sorry`), and a
decision documented in a comment about which approach to use.

### 2.2b — Orbit Partition: Complete Proof

**Effort:** 2.5h | **Module:** `GroupAction/Basic.lean` | **Deps:** 2.2a

Complete the proof chosen in 2.2a. The critical sub-steps are:

**If using Approach 1 (orbitRel):**
1. Invoke `MulAction.orbitRel G X` to get the equivalence relation.
2. Use `Setoid.eq_or_disjoint` (or equivalent) on the orbit classes.
3. Bridge between `Setoid` classes and `MulAction.orbit` using
   `MulAction.orbitRel_apply` or similar.

**If using Approach 2 (direct):**
1. `by_cases h : ∃ z, z ∈ orbit G x ∧ z ∈ orbit G y`
2. **Case ∃ z:** Obtain `⟨z, hz_x, hz_y⟩`. From `hz_x`: `∃ g₁, g₁ • x = z`.
   From `hz_y`: `∃ g₂, g₂ • y = z`. Then `g₁ • x = g₂ • y`, so
   `x = g₁⁻¹ • g₂ • y = (g₁⁻¹ * g₂) • y`. Apply `orbit_eq_iff`.
3. **Case ¬∃ z:** The intersection is empty. Conclude `Disjoint`.

**If stuck:** Accept Approach 2 with `∩ = ∅` formulation even if `Disjoint`
doesn't work directly. The key consumer (the correctness proof in 4.3) only
needs the logical content, not the specific `Disjoint` API.

---

### 2.3 — Orbit-Stabilizer Theorem Wrapper

**Effort:** 2h | **Module:** `GroupAction/Basic.lean` | **Deps:** 2.1b

```lean
theorem orbit_stabilizer [Group G] [Fintype G] [MulAction G X]
    [DecidableEq X] (x : X) :
    Fintype.card (MulAction.orbit G x) *
    Fintype.card (MulAction.stabilizer G x) =
    Fintype.card G := by
  exact MulAction.card_orbit_mul_card_stabilizer G x
```

**Sub-steps:**
1. **(30m)** Verify that Mathlib provides `Fintype` instances for
   `MulAction.orbit G x` and `MulAction.stabilizer G x` when `[Fintype G]`
   and `[Fintype X]` are available. If not, add them.
2. **(30m)** State the wrapper with the correct type class constraints.
3. **(1h)** Verify it compiles. If the `exact` doesn't work directly, inspect
   the type mismatch and add necessary coercions or instance arguments.

---

### 2.4a — Orbit Membership: `smul_mem_orbit`

**Effort:** 1h | **Module:** `GroupAction/Basic.lean` | **Deps:** 2.1b

```lean
/-- Applying a group element to `x` yields a member of the orbit of `x`. -/
theorem smul_mem_orbit [Group G] [MulAction G X]
    (g : G) (x : X) : g • x ∈ MulAction.orbit G x :=
  MulAction.mem_orbit _ g
```

**This should be a direct Mathlib application.** If `MulAction.mem_orbit`
does not exist by that name, search for `MulAction.mem_orbit_iff.mpr ⟨g, rfl⟩`.

Tag with `@[simp]` if it helps downstream proofs.

### 2.4b — Orbit Equality Under Action: `orbit_eq_of_smul`

**Effort:** 2h | **Module:** `GroupAction/Basic.lean` | **Deps:** 2.4a

```lean
/-- Acting on x doesn't change its orbit. -/
theorem orbit_eq_of_smul [Group G] [MulAction G X]
    (g : G) (x : X) : MulAction.orbit G (g • x) = MulAction.orbit G x := by
  sorry
```

**Step-by-step proof:**
1. Apply `Set.eq_of_subset_of_subset` (show mutual inclusion).
2. **Forward (⊆):** Let `y ∈ orbit G (g • x)`. Then `∃ h, h • (g • x) = y`,
   so `(h * g) • x = y` by `mul_smul`. Thus `y ∈ orbit G x`.
3. **Reverse (⊇):** Let `y ∈ orbit G x`. Then `∃ h, h • x = y`,
   so `(h * g⁻¹) • (g • x) = h • (g⁻¹ • (g • x)) = h • x = y` by
   `mul_smul` and `inv_smul_smul`. Thus `y ∈ orbit G (g • x)`.

**Alternative:** Check if Mathlib has this as `MulAction.orbit_smul` or
`MulAction.orbit_eq_of_mem_orbit`. The 2.1a exploration should have found this.

---

### 2.5 — Canonical Form Structure

**Effort:** 2h | **Module:** `GroupAction/Canonical.lean` | **Deps:** 2.1b

```lean
structure CanonicalForm (G : Type*) (X : Type*)
    [Group G] [MulAction G X] where
  canon : X → X
  mem_orbit : ∀ x, canon x ∈ MulAction.orbit G x
  orbit_iff : ∀ x y, canon x = canon y ↔
    MulAction.orbit G x = MulAction.orbit G y
```

**Sub-steps:**
1. **(1h)** Define the structure with docstrings for each field.
2. **(1h)** Verify `#check CanonicalForm`, `#check CanonicalForm.canon`,
   and `#check CanonicalForm.orbit_iff` all succeed with expected types.

---

### 2.6a — Canon Forward Direction

**Effort:** 45m | **Module:** `GroupAction/Canonical.lean` | **Deps:** 2.5

```lean
/-- Canon equality implies orbit equality. -/
theorem canon_eq_implies_orbit_eq [Group G] [MulAction G X]
    (can : CanonicalForm G X) (x y : X) :
    can.canon x = can.canon y → MulAction.orbit G x = MulAction.orbit G y :=
  (can.orbit_iff x y).mp
```

Direct extraction from `orbit_iff`. One-liner.

### 2.6b — Canon Reverse Direction

**Effort:** 45m | **Module:** `GroupAction/Canonical.lean` | **Deps:** 2.5

```lean
/-- Orbit equality implies canon equality. -/
theorem orbit_eq_implies_canon_eq [Group G] [MulAction G X]
    (can : CanonicalForm G X) (x y : X) :
    MulAction.orbit G x = MulAction.orbit G y → can.canon x = can.canon y :=
  (can.orbit_iff x y).mpr
```

Direct extraction from `orbit_iff`. One-liner.

### 2.6c — Canon Equality from Orbit Membership

**Effort:** 1.5h | **Module:** `GroupAction/Canonical.lean` | **Deps:** 2.6b, 2.4b

```lean
/-- If y is in the orbit of x, they have the same canonical form. -/
theorem canon_eq_of_mem_orbit [Group G] [MulAction G X]
    (can : CanonicalForm G X) {x y : X}
    (h : y ∈ MulAction.orbit G x) :
    can.canon y = can.canon x := by
  sorry
```

**Step-by-step proof:**
1. From `h : y ∈ orbit G x`, obtain `⟨g, hg⟩ : ∃ g, g • x = y` via
   `MulAction.mem_orbit_iff.mp`.
2. Rewrite goal as `can.canon (g • x) = can.canon x` using `← hg`.
3. Apply `orbit_eq_implies_canon_eq` with the fact that
   `orbit G (g • x) = orbit G x` (from `orbit_eq_of_smul`, unit 2.4b).

**This lemma is the workhorse of the correctness proof** — it's called in
Phase 4 unit 4.2 to show `canon(encrypt) = canon(reps m)`.

---

### 2.7 — Canonical Form Idempotence

**Effort:** 1.5h | **Module:** `GroupAction/Canonical.lean` | **Deps:** 2.6c

```lean
theorem canon_idem [Group G] [MulAction G X]
    (can : CanonicalForm G X) (x : X) :
    can.canon (can.canon x) = can.canon x := by
  sorry
```

**Proof:** Apply `canon_eq_of_mem_orbit` with `can.mem_orbit x`, which gives
`can.canon x ∈ orbit G x`. This is a direct one-step application of 2.6c.

---

### 2.8 — G-Invariant Function Definition and Properties

**Effort:** 2h | **Module:** `GroupAction/Invariant.lean` | **Deps:** 2.1b

```lean
def IsGInvariant [Group G] [MulAction G X] (f : X → Y) : Prop :=
  ∀ (g : G) (x : X), f (g • x) = f x
```

**Sub-steps:**
1. **(45m)** Define `IsGInvariant` with docstring.
2. **(45m)** Prove `IsGInvariant.comp`: composition preserves invariance.
3. **(30m)** Prove `isGInvariant_const`: constant functions are invariant.

---

### 2.9a — Invariant-Orbit Lemma: Witness Extraction

**Effort:** 1h | **Module:** `GroupAction/Invariant.lean` | **Deps:** 2.8, 2.4a

This is the setup step for the critical `invariant_const_on_orbit` lemma.
The proof hinges on extracting the group element from orbit membership.

**Key insight to verify in a scratch file:**
```lean
-- Confirm this works:
example [Group G] [MulAction G X] {x y : X} (h : y ∈ MulAction.orbit G x) :
    ∃ g : G, g • x = y :=
  MulAction.mem_orbit_iff.mp h
```

If `MulAction.mem_orbit_iff` doesn't give exactly this form, find the correct
unpacking. This determines the structure of the full proof.

### 2.9b — Invariant-Orbit Lemma: Complete Proof

**Effort:** 2h | **Module:** `GroupAction/Invariant.lean` | **Deps:** 2.9a

```lean
theorem invariant_const_on_orbit [Group G] [MulAction G X]
    {f : X → Y} (hf : IsGInvariant (G := G) f)
    {x y : X} (hy : y ∈ MulAction.orbit G x) :
    f y = f x := by
  obtain ⟨g, hg⟩ := MulAction.mem_orbit_iff.mp hy  -- Step 1: extract g
  rw [← hg]                                          -- Step 2: rewrite y as g • x
  exact hf g x                                       -- Step 3: apply invariance
```

**If this direct proof doesn't work**, the issue is likely in step 1.
Alternatives:
- `MulAction.mem_orbit_iff` may use `∃ g, g • x = y` or `∃ g, x = g • y` —
  check the direction.
- Use `Exists.elim` or `match` instead of `obtain` if tactic issues arise.

**This is the single most important lemma in the formalization.** Both the
invariant attack theorem (4.5) and the correctness proof (4.2, via 2.6c)
depend on it. Test it thoroughly.

---

### 2.10 — Separating Invariant Definition and Orbit Distinctness

**Effort:** 2h | **Module:** `GroupAction/Invariant.lean` | **Deps:** 2.9b

```lean
def IsSeparating [Group G] [MulAction G X] (f : X → Y)
    (x₀ x₁ : X) : Prop :=
  IsGInvariant (G := G) f ∧ f x₀ ≠ f x₁
```

**Sub-steps:**
1. **(30m)** Define `IsSeparating` with docstring.
2. **(1.5h)** Prove `separating_implies_distinct_orbits`:

```lean
theorem separating_implies_distinct_orbits ... :
    MulAction.orbit G x₀ ≠ MulAction.orbit G x₁ := by
  intro hEq                           -- Assume orbits are equal
  have : x₁ ∈ MulAction.orbit G x₀ := -- x₁ ∈ its own orbit, rewrite
    hEq ▸ MulAction.mem_orbit_self x₁
  have : f x₁ = f x₀ :=              -- By invariant_const_on_orbit
    invariant_const_on_orbit h.1 this
  exact h.2 this.symm                 -- Contradicts f x₀ ≠ f x₁
```

The trickiest step is showing `x₁ ∈ orbit G x₀` from `orbit G x₀ = orbit G x₁`.
Use `hEq ▸ MulAction.mem_orbit_self x₁` (rewrite the set membership using
the orbit equality).

---

### 2.11 — Canonical Form Is G-Invariant

**Effort:** 2h | **Module:** `GroupAction/Invariant.lean` | **Deps:** 2.5, 2.8, 2.4b

```lean
theorem canonical_isGInvariant [Group G] [MulAction G X]
    (can : CanonicalForm G X) :
    IsGInvariant (G := G) can.canon := by
  intro g x
  exact orbit_eq_implies_canon_eq can x (g • x)
    (orbit_eq_of_smul g x).symm
```

**Step-by-step:**
1. Unfold `IsGInvariant`: need `can.canon (g • x) = can.canon x`.
2. From `orbit_eq_of_smul` (2.4b): `orbit G (g • x) = orbit G x`.
3. From `orbit_eq_implies_canon_eq` (2.6b): orbit equality implies canon equality.
4. Chain them. Note the symmetry: `orbit_eq_of_smul` gives
   `orbit G (g • x) = orbit G x`, but we need `orbit G x = orbit G (g • x)`
   or vice versa depending on the direction of `orbit_eq_implies_canon_eq`.

---

## Parallel Execution Plan

```
                      2.1a Mathlib Exploration
                              │
                      2.1b Orbit API Wrappers
                     /         |          \
                    /          |           \
      ┌────────────┘           │            └────────────┐
      ▼                        ▼                         ▼
 Track A: Basic          Track B: Canonical        Track C: Invariant
 ┌──────────────┐        ┌──────────────┐          ┌──────────────┐
 │ 2.2a State   │        │ 2.5 Structure │          │ 2.8 Define   │
 │ 2.2b Prove   │        │ 2.6a Forward  │          │ 2.9a Witness │
 │ 2.3 Orb-Stab │        │ 2.6b Reverse  │          │ 2.9b Proof   │
 │ 2.4a smul_mem│        │ 2.6c Mem ver. │          │ 2.10 Separate│
 │ 2.4b orb_eq  │        │ 2.7 Idempot.  │          └──────────────┘
 └──────────────┘        └──────────────┘                  │
      │                        │                           │
      └────────────────────────┼───────────────────────────┘
                               ▼
                    2.11 Canon Is Invariant
                  (joins Tracks A, B, and C)
```

**Risk-first ordering within each track:**
- Track A: Start with 2.4a (easiest, validates API), then 2.4b (medium), then
  2.2a/2.2b (hardest), then 2.3 (wrapper).
- Track B: Start with 2.5 (definition), then 2.6a/b (one-liners), then 2.6c
  (medium), then 2.7 (uses 2.6c).
- Track C: Start with 2.8 (definition), then 2.9a (exploration), then 2.9b
  (critical proof), then 2.10 (uses 2.9b).

---

## Risk Analysis

| Risk | Units | Likelihood | Impact | Mitigation |
|------|-------|-----------|--------|------------|
| Mathlib API names differ from expected | 2.1a | Medium | High | 2.1a exploration catches this before any code is written |
| `Disjoint` on `Set` awkward | 2.2a | Medium | Low | Use `∩ = ∅` formulation (Approach 2) |
| `Fintype` instances missing for orbits | 2.3 | Medium | Medium | Add `[Fintype X]` or construct instances manually |
| `orbit_eq_of_smul` not in Mathlib | 2.4b | Medium | Low | Prove from `orbit_eq_iff` (proof sketched above) |
| `mem_orbit_iff` direction mismatch | 2.9a | Low | Medium | 2.9a specifically validates this before the proof |
| Universe polymorphism errors | All | Low | Medium | Keep G, X, Y in same universe; add explicit annotations |

---

## Exit Criteria

- [ ] `GroupAction/Basic.lean` compiles without `sorry`
- [ ] `GroupAction/Canonical.lean` compiles without `sorry`
- [ ] `GroupAction/Invariant.lean` compiles without `sorry`
- [ ] `lake build` succeeds with zero errors
- [ ] `orbit_disjoint_or_eq` proved
- [ ] `CanonicalForm` structure defined with `canon`, `mem_orbit`, `orbit_iff`
- [ ] `canon_eq_of_mem_orbit` proved (critical for Phase 4)
- [ ] `IsGInvariant` and `IsSeparating` defined
- [ ] `invariant_const_on_orbit` proved (critical for Phase 4)
- [ ] `canonical_isGInvariant` proved
- [ ] All lemmas have docstrings

---

## Transition to Phase 3

With the group action foundations complete, Phase 3 builds the cryptographic
layer — defining `OrbitEncScheme`, the adversary model, and the OIA axiom.
These definitions directly reference `CanonicalForm` and `IsGInvariant`.

See: [Phase 3 — Cryptographic Definitions](PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md)
