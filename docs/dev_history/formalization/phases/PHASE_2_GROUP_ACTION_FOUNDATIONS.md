<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Phase 2 — Group Action Foundations

## Weeks 2–4 | 11 Work Units | ~28 Hours

*Part of the [Orbcrypt Lean 4 Formalization Plan](../FORMALIZATION_PLAN.md)*

---

## Overview

Phase 2 builds the mathematical foundation that the entire formalization rests
upon. It populates the three `GroupAction/` modules — `Basic.lean`,
`Canonical.lean`, and `Invariant.lean` — with Mathlib wrappers, custom
definitions, and lemmas that directly support the cryptographic theorems in
Phase 4.

This phase has **three parallel tracks** after the initial Mathlib wrapping
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

### 2.1 — Orbit API Wrapper

**Effort:** 3 hours
**Module:** `GroupAction/Basic.lean`
**Deliverable:** Re-export `MulAction.orbit`, `MulAction.stabilizer` from
Mathlib with convenience aliases.

#### Implementation Guidance

```lean
import Mathlib.GroupTheory.GroupAction.Basic
import Mathlib.GroupTheory.GroupAction.Defs

/--
Orbcrypt.GroupAction.Basic — Core orbit and stabilizer API.

Re-exports Mathlib's `MulAction` framework with convenience aliases and
additional lemmas needed for orbit encryption proofs.
-/

namespace Orbcrypt

-- Re-export core Mathlib definitions for convenience.
-- Users of Orbcrypt modules should not need to import Mathlib directly
-- for basic orbit operations.

/-- The orbit of `x` under the group `G`. Alias for `MulAction.orbit G x`. -/
abbrev orbit (G : Type*) [Group G] [MulAction G X] (x : X) : Set X :=
  MulAction.orbit G x

/-- The stabilizer of `x` in `G`. Alias for `MulAction.stabilizer G x`. -/
abbrev stabilizer (G : Type*) [Group G] [MulAction G X] (x : X) : Subgroup G :=
  MulAction.stabilizer G x

end Orbcrypt
```

**Key Mathlib entry points to explore:**
- `MulAction.orbit_eq_iff` — characterizes when two orbits are equal
- `MulAction.mem_orbit_iff` — membership in an orbit
- `MulAction.orbitRel` — the equivalence relation induced by orbits

#### Definition of Done

- `GroupAction/Basic.lean` compiles with the re-exports
- A `#check Orbcrypt.orbit` succeeds in a scratch file

---

### 2.2 — Orbit Partition Theorem

**Effort:** 4 hours
**Module:** `GroupAction/Basic.lean`
**Deliverable:** Proof that any two orbits are either equal or disjoint.
**Dependencies:** 2.1

#### Implementation Guidance

```lean
/-- Any two orbits under a group action are either equal or disjoint. -/
theorem orbit_disjoint_or_eq [Group G] [MulAction G X]
    (x y : X) :
    MulAction.orbit G x = MulAction.orbit G y ∨
    Disjoint (MulAction.orbit G x) (MulAction.orbit G y) := by
  sorry
```

**Proof strategy:** Use Mathlib's `MulAction.orbitRel`, which gives an
equivalence relation whose classes are exactly the orbits. Two equivalence
classes are either identical or disjoint — this is a basic property of
equivalence relations (`Setoid.eq_or_disjoint` or equivalent).

**Alternative approach:** Prove directly:
1. Suppose the orbits are not disjoint, i.e., ∃ z ∈ orbit G x ∩ orbit G y.
2. Then ∃ g₁ g₂, g₁ • x = z = g₂ • y, so x = g₁⁻¹ • g₂ • y.
3. Therefore orbit G x = orbit G y (by `MulAction.orbit_eq_iff`).

**Mathlib references:**
- `MulAction.orbit_eq_iff` — the key equivalence
- `Set.Disjoint` or `Disjoint` in the lattice sense

#### Risks

This proof may require careful navigation of Mathlib's `Set` vs `Finset`
distinctions and the `Disjoint` type class hierarchy. If `Disjoint` on `Set`
is awkward, consider stating the theorem as:
```lean
MulAction.orbit G x = MulAction.orbit G y ∨
  ∀ z, z ∉ MulAction.orbit G x ∨ z ∉ MulAction.orbit G y
```

---

### 2.3 — Orbit-Stabilizer Theorem Wrapper

**Effort:** 2 hours
**Module:** `GroupAction/Basic.lean`
**Deliverable:** Wrapped version of Mathlib's orbit-stabilizer theorem with
explicit type annotations.
**Dependencies:** 2.1

#### Implementation Guidance

Mathlib provides `MulAction.card_orbit_mul_card_stabilizer`. Wrap it with
explicit type annotations for our use case:

```lean
/-- Orbit-stabilizer theorem: |orbit G x| * |stab_G(x)| = |G|.
    Wraps Mathlib's `MulAction.card_orbit_mul_card_stabilizer`. -/
theorem orbit_stabilizer [Group G] [Fintype G] [MulAction G X]
    [DecidableEq X] (x : X) :
    Fintype.card (MulAction.orbit G x) *
    Fintype.card (MulAction.stabilizer G x) =
    Fintype.card G := by
  exact MulAction.card_orbit_mul_card_stabilizer G x
```

**Note:** This may require `Fintype` instances for the orbit and stabilizer.
Check whether Mathlib provides these automatically. If not, constructing
`Fintype` instances for orbits of finite groups acting on finite types may
require additional instance declarations.

#### Definition of Done

- The wrapper compiles and `#check orbit_stabilizer` succeeds
- The statement is a direct specialization of the Mathlib theorem

---

### 2.4 — Orbit Membership Lemmas

**Effort:** 3 hours
**Module:** `GroupAction/Basic.lean`
**Deliverable:** Two key lemmas connecting group action to orbit membership.
**Dependencies:** 2.1

#### Implementation Guidance

```lean
/-- Applying a group element to `x` yields a member of the orbit of `x`. -/
theorem smul_mem_orbit [Group G] [MulAction G X]
    (g : G) (x : X) : g • x ∈ MulAction.orbit G x := by
  exact MulAction.mem_orbit _ g

/-- If `y` is obtained from `x` by a group action, they share the same orbit. -/
theorem orbit_eq_of_smul [Group G] [MulAction G X]
    (g : G) (x : X) : MulAction.orbit G (g • x) = MulAction.orbit G x := by
  sorry
```

**Proof strategy for `orbit_eq_of_smul`:** Use `MulAction.orbit_eq_iff`.
We need to show ∃ g' : G, g' • x = g • x (take g' = g), and for the
reverse ∃ g' : G, g' • (g • x) = x (take g' = g⁻¹). Alternatively,
Mathlib may have this directly as `MulAction.orbit_smul`.

**Mathlib references:**
- `MulAction.mem_orbit` — direct proof of membership
- `MulAction.orbit_eq_iff` — orbit equality criterion
- Look for `MulAction.orbit_smul` (may exist under a slightly different name)

---

### 2.5 — Canonical Form Structure

**Effort:** 2 hours
**Module:** `GroupAction/Canonical.lean`
**Deliverable:** The `CanonicalForm` structure definition.
**Dependencies:** 2.1

#### Implementation Guidance

```lean
import Mathlib.GroupTheory.GroupAction.Basic
import Orbcrypt.GroupAction.Basic

/--
A canonical form for a group action is a function `canon : X → X` that:
1. Maps each element to a member of its own orbit (`mem_orbit`).
2. Uniquely identifies orbits: `canon x = canon y ↔ orbit G x = orbit G y`
   (`orbit_iff`).

This abstracts the concept of "lexicographically minimal element of the orbit"
used in the concrete Orbcrypt construction (docs/DEVELOPMENT.md §3.2).
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
```

**Design rationale:** We define `CanonicalForm` as a structure rather than a
type class because a given group action may admit multiple canonical forms
(e.g., lex-min, lex-max). The encryption scheme explicitly carries its
canonical form as data.

#### Definition of Done

- `CanonicalForm` structure compiles
- `#check CanonicalForm` shows the expected type
- `#check CanonicalForm.canon` shows `X → X`

---

### 2.6 — Canonical Form Uniqueness

**Effort:** 3 hours
**Module:** `GroupAction/Canonical.lean`
**Deliverable:** Proof that canonical form equality implies orbit equality
and vice versa (both directions of `orbit_iff` as separate, named lemmas).
**Dependencies:** 2.5

#### Implementation Guidance

```lean
/-- If two elements have the same canonical form, they are in the same orbit. -/
theorem canon_eq_implies_orbit_eq [Group G] [MulAction G X]
    (can : CanonicalForm G X) (x y : X) :
    can.canon x = can.canon y → MulAction.orbit G x = MulAction.orbit G y :=
  (can.orbit_iff x y).mp

/-- If two elements are in the same orbit, they have the same canonical form. -/
theorem orbit_eq_implies_canon_eq [Group G] [MulAction G X]
    (can : CanonicalForm G X) (x y : X) :
    MulAction.orbit G x = MulAction.orbit G y → can.canon x = can.canon y :=
  (can.orbit_iff x y).mpr
```

These are direct consequences of the `orbit_iff` field, but having them as
separate named lemmas improves readability in the correctness proof (Phase 4).

**Additional useful lemma:**
```lean
/-- Elements in the same orbit have the same canonical form (membership version). -/
theorem canon_eq_of_mem_orbit [Group G] [MulAction G X]
    (can : CanonicalForm G X) (x y : X)
    (h : y ∈ MulAction.orbit G x) :
    can.canon y = can.canon x := by
  sorry
  -- Strategy: h gives ∃ g, g • x = y.
  -- Therefore orbit G y = orbit G x (by orbit_eq_of_smul or orbit_eq_iff).
  -- Apply orbit_iff.mpr.
```

---

### 2.7 — Canonical Form Idempotence

**Effort:** 2 hours
**Module:** `GroupAction/Canonical.lean`
**Deliverable:** Proof that applying `canon` twice gives the same result as
applying it once.
**Dependencies:** 2.5, 2.6

#### Implementation Guidance

```lean
/-- Canonical form is idempotent: `canon(canon(x)) = canon(x)`. -/
theorem canon_idem [Group G] [MulAction G X]
    (can : CanonicalForm G X) (x : X) :
    can.canon (can.canon x) = can.canon x := by
  sorry
```

**Proof strategy:**
1. By `mem_orbit`, `can.canon x ∈ orbit G x`.
2. Therefore `orbit G (can.canon x) = orbit G x`.
3. By `orbit_iff` (mpr direction): `can.canon (can.canon x) = can.canon x`.

This is a straightforward application of 2.6 and is a good sanity check on the
`CanonicalForm` definition.

---

### 2.8 — G-Invariant Function Definition

**Effort:** 2 hours
**Module:** `GroupAction/Invariant.lean`
**Deliverable:** Definition of `IsGInvariant` and basic closure properties.
**Dependencies:** 2.1

#### Implementation Guidance

```lean
import Mathlib.GroupTheory.GroupAction.Basic
import Orbcrypt.GroupAction.Basic

/--
A function `f : X → Y` is G-invariant if it is unchanged by the group action:
`f(g • x) = f(x)` for all `g ∈ G` and `x ∈ X`.

Equivalently, `f` is constant on each orbit of `G`.
This is the central concept in the invariant attack theorem
(docs/DEVELOPMENT.md §4.4).
-/
def IsGInvariant [Group G] [MulAction G X] (f : X → Y) : Prop :=
  ∀ (g : G) (x : X), f (g • x) = f x
```

**Basic closure properties to prove:**

```lean
/-- The identity function is G-invariant (trivially). -/
theorem isGInvariant_id [Group G] [MulAction G X] :
    IsGInvariant (G := G) (id : X → X) := by
  sorry  -- Only true if G acts trivially; skip this or state carefully

/-- Composition with any function preserves G-invariance. -/
theorem IsGInvariant.comp [Group G] [MulAction G X]
    {f : X → Y} (hf : IsGInvariant (G := G) f) (h : Y → Z) :
    IsGInvariant (G := G) (h ∘ f) := by
  intro g x
  simp [Function.comp, hf g x]

/-- A constant function is G-invariant. -/
theorem isGInvariant_const [Group G] [MulAction G X] (c : Y) :
    IsGInvariant (G := G) (fun _ => c) := by
  intro g x; rfl
```

---

### 2.9 — Invariant-Orbit Lemma

**Effort:** 3 hours
**Module:** `GroupAction/Invariant.lean`
**Deliverable:** Proof that a G-invariant function is constant on each orbit.
**Dependencies:** 2.8, 2.4

#### Implementation Guidance

```lean
/--
A G-invariant function takes the same value on all elements of an orbit.
This is the key lemma used in the invariant attack theorem:
if f is invariant and c = g • x_m, then f(c) = f(x_m).
-/
theorem invariant_const_on_orbit [Group G] [MulAction G X]
    {f : X → Y} (hf : IsGInvariant (G := G) f)
    {x y : X} (hy : y ∈ MulAction.orbit G x) :
    f y = f x := by
  sorry
```

**Proof strategy:**
1. `hy : y ∈ orbit G x` gives `∃ g : G, g • x = y` (by `MulAction.mem_orbit_iff`).
2. Obtain `g` and `hg : g • x = y`.
3. Rewrite: `f y = f (g • x)` (by `hg`).
4. Apply `hf g x`: `f (g • x) = f x`.

**This lemma is critical.** It is used directly in:
- The invariant attack theorem (Phase 4, unit 4.5): the adversary computes
  f(c*) = f(g • x_{m_b}) = f(x_{m_b}) to identify the message.
- The correctness proof (Phase 4, unit 4.2): canonical form is G-invariant,
  so canon(g • x_m) = canon(x_m).

---

### 2.10 — Separating Invariant Definition

**Effort:** 2 hours
**Module:** `GroupAction/Invariant.lean`
**Deliverable:** Definition of `IsSeparating` and proof that separation implies
distinct orbits.
**Dependencies:** 2.8, 2.9

#### Implementation Guidance

```lean
/--
A function `f` separates two points `x₀` and `x₁` under a group action if:
1. `f` is G-invariant, and
2. `f(x₀) ≠ f(x₁)`.

The invariant attack theorem shows that any separating function yields a
complete break of the encryption scheme.
-/
def IsSeparating [Group G] [MulAction G X] (f : X → Y)
    (x₀ x₁ : X) : Prop :=
  IsGInvariant (G := G) f ∧ f x₀ ≠ f x₁

/-- A separating invariant implies that its arguments lie in distinct orbits. -/
theorem separating_implies_distinct_orbits [Group G] [MulAction G X]
    {f : X → Y} {x₀ x₁ : X}
    (h : IsSeparating (G := G) f x₀ x₁) :
    MulAction.orbit G x₀ ≠ MulAction.orbit G x₁ := by
  sorry
```

**Proof strategy (by contradiction):**
1. Assume `orbit G x₀ = orbit G x₁`.
2. Then `x₁ ∈ orbit G x₀` (since x₁ ∈ orbit G x₁ = orbit G x₀).
3. By `invariant_const_on_orbit` (2.9): `f x₁ = f x₀`.
4. This contradicts `h.2 : f x₀ ≠ f x₁`.

---

### 2.11 — Canonical Form Is G-Invariant

**Effort:** 2 hours
**Module:** `GroupAction/Invariant.lean`
**Deliverable:** Proof that the canonical form function is G-invariant.
**Dependencies:** 2.5, 2.8

#### Implementation Guidance

```lean
/--
The canonical form function is G-invariant: `canon(g • x) = canon(x)`.
This connects the canonical form (used for decryption) to the invariant
framework (used for security analysis).
-/
theorem canonical_isGInvariant [Group G] [MulAction G X]
    (can : CanonicalForm G X) :
    IsGInvariant (G := G) can.canon := by
  sorry
```

**Proof strategy:**
1. We need to show `can.canon (g • x) = can.canon x` for all `g, x`.
2. By `orbit_eq_of_smul` (2.4): `orbit G (g • x) = orbit G x`.
3. By `can.orbit_iff` (mpr direction): `can.canon (g • x) = can.canon x`.

**This connects two parallel tracks:** it requires both the canonical form
(Track B) and the invariant framework (Track C), making it a natural
integration point.

---

## Parallel Execution Plan

After unit 2.1 (the shared foundation), three tracks can proceed simultaneously:

```
                          2.1 Orbit API Wrapper
                         /         |          \
                        /          |           \
          ┌────────────┘           │            └────────────┐
          ▼                        ▼                         ▼
   Track A: Basic            Track B: Canonical        Track C: Invariant
   ┌──────────────┐          ┌──────────────┐          ┌──────────────┐
   │ 2.2 Partition │          │ 2.5 Structure │          │ 2.8 Definition │
   │ 2.3 Orb-Stab  │          │ 2.6 Uniqueness│          │ 2.9 Orbit Lem  │
   │ 2.4 Membership│          │ 2.7 Idempot.  │          │ 2.10 Separating│
   └──────────────┘          └──────────────┘          └──────────────┘
          │                        │                         │
          └────────────────────────┼─────────────────────────┘
                                   ▼
                        2.11 Canon Is Invariant
                      (joins Tracks B and C)
```

**Optimal schedule for a single contributor:**

| Day | Work | Hours | Running Total |
|-----|------|-------|---------------|
| 1 | 2.1 (API wrapper) | 3h | 3h |
| 2 | 2.5 (CanonicalForm struct) + 2.8 (IsGInvariant def) | 4h | 7h |
| 3 | 2.2 (orbit partition) + 2.9 (invariant-orbit lemma) | 7h | 14h |
| 4 | 2.3 (orbit-stabilizer) + 2.4 (membership) | 5h | 19h |
| 5 | 2.6 (uniqueness) + 2.10 (separating) | 5h | 24h |
| 6 | 2.7 (idempotence) + 2.11 (canon is invariant) | 4h | 28h |

---

## Risk Analysis

| Risk | Units Affected | Likelihood | Impact | Mitigation |
|------|---------------|-----------|--------|------------|
| Mathlib API changes between pinned versions | All | Low (pinned) | High | Pin Mathlib commit in lakefile.lean; do not update mid-phase |
| `Disjoint` on `Set` is awkward to work with | 2.2 | Medium | Low | Use pointwise formulation instead |
| `Fintype` instances missing for orbits | 2.3 | Medium | Medium | May need to add `[Fintype X]` constraints or construct instances manually |
| `orbit_eq_of_smul` not in Mathlib by that name | 2.4 | Medium | Low | Search for equivalent: `MulAction.orbit_smul`, or prove from `orbit_eq_iff` |
| Proof of 2.9 harder than expected (universe issues) | 2.9 | Low | Medium | Keep types in the same universe; use `MulAction.mem_orbit_iff.mp` explicitly |

---

## Common Lean 4 / Mathlib Pitfalls

1. **Universe polymorphism:** Ensure `G`, `X`, and `Y` are in compatible
   universes. If you see `universe mismatch` errors, add explicit universe
   annotations.

2. **Instance search depth:** Complex `MulAction` instance chains (e.g.,
   for subgroups) may exceed Lean's default instance search depth. Use
   `set_option maxHeartbeats 400000` if needed, but treat this as a code smell.

3. **`simp` lemma selection:** Tag your lemmas with `@[simp]` sparingly.
   Over-tagging causes `simp` to loop or produce unexpected results.

4. **`sorry` hygiene:** During development, use `sorry` freely but grep for
   it before declaring a unit complete. Phase 6 will audit all remaining
   `sorry` instances.

---

## Exit Criteria

All of the following must be true before proceeding to Phase 3:

- [x] `GroupAction/Basic.lean` compiles without `sorry`
- [x] `GroupAction/Canonical.lean` compiles without `sorry`
- [x] `GroupAction/Invariant.lean` compiles without `sorry`
- [x] `lake build` succeeds with zero errors
- [x] `orbit_disjoint_or_eq` proved
- [x] `CanonicalForm` structure defined with `canon`, `mem_orbit`, `orbit_iff`
- [x] `IsGInvariant` and `IsSeparating` defined
- [x] `invariant_const_on_orbit` proved
- [x] `canonical_isGInvariant` proved
- [x] All lemmas have docstrings

---

## Transition to Phase 3

With the group action foundations complete, Phase 3 builds the cryptographic
layer on top — defining `OrbitEncScheme`, the adversary model, and the OIA
axiom. These definitions directly reference the `CanonicalForm` and
`IsGInvariant` types from this phase.

See: [Phase 3 — Cryptographic Definitions](PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md)
