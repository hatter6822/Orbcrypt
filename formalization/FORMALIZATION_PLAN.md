# Orbcrypt — Lean 4 Formalization Master Plan

## Formal Verification of Permutation-Orbit Encryption

---

## Table of Contents

1. [Vision & Goals](#1-vision--goals)
2. [Scope & Non-Goals](#2-scope--non-goals)
3. [Project Architecture](#3-project-architecture)
4. [Module Overview](#4-module-overview)
5. [Mathlib Integration](#5-mathlib-integration)
6. [Development Roadmap](#6-development-roadmap)
7. [Critical Path Analysis](#7-critical-path-analysis)
8. [Effort & Timeline Summary](#8-effort--timeline-summary)
9. [Coding Conventions](#9-coding-conventions)

---

## 1. Vision & Goals

The Lean 4 formalization of Orbcrypt aims to produce machine-checked proofs of
the three core results underpinning the encryption scheme's theoretical
foundation:

| # | Result | Statement | Significance |
|---|--------|-----------|--------------|
| 1 | **Correctness** | Dec(Enc(m)) = m for all messages m and all group elements g used in encryption | The scheme faithfully recovers encrypted messages |
| 2 | **Invariant Attack Theorem** | If a G-invariant function separates two message orbits, an adversary achieves maximum advantage (complete break) | Machine-checked proof of the critical vulnerability from COUNTEREXAMPLE.md |
| 3 | **Conditional Security Reduction** | OIA ⟹ IND-1-CPA | If the Orbit Indistinguishability Assumption holds, the scheme is secure against single-query chosen-plaintext attacks |

These three results together establish: the scheme is correct, its failure mode
is precisely characterized, and under a stated assumption it is secure. The
formalization provides the highest possible assurance that the mathematical
arguments in the development document (DEVELOPMENT.md §§4–8) are sound.

### What We Do Not Formalize

The OIA itself is a **computational conjecture** — it asserts that no efficient
algorithm can distinguish orbit samples. This is not a mathematical theorem
amenable to proof in Lean 4; it is a hardness assumption analogous to "factoring
is hard" in RSA. We state it as an axiom and prove that security follows from it.

---

## 2. Scope & Non-Goals

### In Scope

| Item | Description | Formalized In |
|------|-------------|---------------|
| Group action fundamentals | Orbits, stabilizers, partition theorem, orbit-stabilizer | `GroupAction/Basic.lean` |
| Canonical forms | Abstract canonical form definition, uniqueness, idempotence | `GroupAction/Canonical.lean` |
| G-invariant functions | Definition, properties, separating condition | `GroupAction/Invariant.lean` |
| AOE scheme syntax | `OrbitEncScheme` structure with `encrypt` and `decrypt` | `Crypto/Scheme.lean` |
| IND-CPA security game | Adversary structure, advantage definition | `Crypto/Security.lean` |
| OIA axiom | Formal statement as Lean axiom | `Crypto/OIA.lean` |
| Correctness theorem | `decrypt(encrypt(g, m)) = some m` | `Theorems/Correctness.lean` |
| Invariant attack theorem | Separating invariant implies complete break | `Theorems/InvariantAttack.lean` |
| OIA implies IND-1-CPA | Conditional security reduction | `Theorems/OIAImpliesCPA.lean` |
| S\_n action on bitstrings | `MulAction (Equiv.Perm (Fin n)) (Fin n → Bool)` | `Construction/Permutation.lean` |
| HGOE instance | Concrete scheme instantiation with correctness | `Construction/HGOE.lean` |
| Hamming weight defense | Proof that same-weight reps defeat weight attacks | `Construction/HGOE.lean` |

### Non-Goals

| Item | Reason |
|------|--------|
| Probabilistic reasoning | Requires a probability monad or CryptHOL port; deferred to future work (see DEVELOPMENT.md §10.7) |
| PPT adversary modeling | Computational complexity classes are not natively expressible in Lean 4's type theory |
| CFI graph construction | Complex combinatorial construction with limited formalization value relative to effort |
| Code equivalence reduction | Requires algebraic coding theory beyond current Mathlib coverage |
| Executable encryption | Performance-oriented implementation is a separate engineering effort |

---

## 3. Project Architecture

### File Layout

```
Orbcrypt/
├── lakefile.lean                     -- Build configuration (Mathlib dependency)
├── lean-toolchain                    -- Lean 4 version pin
├── Orbcrypt.lean                     -- Root import file
└── Orbcrypt/
    ├── GroupAction/
    │   ├── Basic.lean                -- Orbit, stabilizer, orbit partition
    │   ├── Canonical.lean            -- Canonical forms under group actions
    │   └── Invariant.lean            -- G-invariant functions and properties
    ├── Crypto/
    │   ├── Scheme.lean               -- AOE scheme syntax (Setup, Enc, Dec)
    │   ├── Security.lean             -- IND-CPA game and advantage definition
    │   └── OIA.lean                  -- Orbit Indistinguishability Assumption
    ├── Theorems/
    │   ├── Correctness.lean          -- Dec(Enc(m)) = m
    │   ├── InvariantAttack.lean      -- Separating invariant ⟹ Adv = 1/2
    │   └── OIAImpliesCPA.lean        -- OIA ⟹ IND-1-CPA
    └── Construction/
        ├── HGOE.lean                 -- Hidden-Group Orbit Encryption instance
        └── Permutation.lean          -- S_n action on {0,1}^n
```

### Module Dependency Graph

```
              GroupAction.Basic
             /       |        \
            /        |         \
 GroupAction.   GroupAction.    \
  Canonical      Invariant      \
           \        |         /  \
            \       |        /    \
             Crypto.Scheme        \
            /              \       \
           /                \       \
  Crypto.Security        Crypto.OIA \
     |        \            /         \
     |         \          /           \
     |    Theorems.OIAImpliesCPA      |
     |                                |
  Theorems.Correctness                |
  Theorems.InvariantAttack            |
     |                                |
     └────────────┬───────────────────┘
                  |
   Construction.Permutation  (depends on GroupAction.Basic only)
                  |
                  v
   Construction.HGOE  (depends on Permutation + Theorems + Crypto)
```

**Note:** `Construction/Permutation.lean` depends only on `GroupAction.Basic`
(not on Crypto or Theorems). `Construction/HGOE.lean` depends on both
`Permutation.lean` and the Theorem modules. This is what enables the
parallelism described in §6 — Permutation.lean can be built as soon as
Phase 2 completes.

### Design Principles

1. **Maximal Mathlib reuse.** Never redefine what Mathlib already provides.
   Wrap and re-export where convenient, but the source of truth is Mathlib's
   `MulAction` framework.

2. **Thin abstraction layers.** Each module should expose a small, well-typed
   API. Internal proof details should not leak across module boundaries.

3. **Axiom transparency.** Every `axiom` must be clearly documented with its
   mathematical justification and its relationship to the computational
   assumption it models.

4. **Zero `sorry` at release.** The final formalization must contain no `sorry`
   outside of explicitly declared and justified axioms.

---

## 4. Module Overview

### Layer 1: Group Action Foundations (`GroupAction/`)

These modules wrap and extend Mathlib's group action library with lemmas
specifically needed for orbit encryption.

| Module | Key Definitions | Key Results |
|--------|----------------|-------------|
| `Basic.lean` | Re-exports: `MulAction.orbit`, `MulAction.stabilizer` | `orbit_disjoint_or_eq`, `smul_mem_orbit`, `orbit_eq_of_smul`, orbit-stabilizer wrapper |
| `Canonical.lean` | `CanonicalForm` structure (fields: `canon`, `mem_orbit`, `orbit_iff`) | `canon_unique` (orbit equality from canon equality), `canon_idem` (idempotence) |
| `Invariant.lean` | `IsGInvariant`, `IsSeparating` | `invariant_const_on_orbit`, canonical form is G-invariant |

### Layer 2: Cryptographic Framework (`Crypto/`)

These modules define the abstract encryption scheme and security notions.

| Module | Key Definitions | Purpose |
|--------|----------------|---------|
| `Scheme.lean` | `OrbitEncScheme`, `encrypt`, `decrypt` | Formalizes AOE syntax from DEVELOPMENT.md §4.1 |
| `Security.lean` | `Adversary`, `hasAdvantage`, `IsSecure` | Deterministic abstraction of IND-CPA from §4.3 |
| `OIA.lean` | `OIA` (axiom) | Formalizes §5.2 as a Lean axiom |

### Layer 3: Theorems (`Theorems/`)

The three headline results of the formalization.

| Module | Theorem | Formalizes |
|--------|---------|------------|
| `Correctness.lean` | `decrypt(encrypt(g, m)) = some m` | DEVELOPMENT.md §4.2 |
| `InvariantAttack.lean` | Separating invariant implies adversary with Adv = 1/2 | DEVELOPMENT.md §4.4 |
| `OIAImpliesCPA.lean` | OIA implies IND-1-CPA security | DEVELOPMENT.md §8.1 |

### Layer 4: Concrete Construction (`Construction/`)

Instantiation with S\_n acting on bitstrings.

| Module | Key Content |
|--------|-------------|
| `Permutation.lean` | `Bitstring n` type, `MulAction` instance for S\_n, `hammingWeight`, weight-invariance proof |
| `HGOE.lean` | `OrbitEncScheme` instance for a subgroup of S\_n, correctness instantiation, Hamming weight defense |

---

## 5. Mathlib Integration

### Required Mathlib Modules

| Mathlib Module | Purpose | Used By |
|---------------|---------|---------|
| `Mathlib.GroupTheory.GroupAction.Basic` | `MulAction`, `orbit`, `stabilizer` | `GroupAction/Basic.lean` |
| `Mathlib.GroupTheory.GroupAction.Defs` | Core action type class definitions | `GroupAction/Basic.lean` |
| `Mathlib.GroupTheory.Subgroup.Basic` | `Subgroup` type for G ≤ S\_n | `Construction/HGOE.lean` |
| `Mathlib.GroupTheory.Perm.Basic` | `Equiv.Perm` (symmetric group S\_n) | `Construction/Permutation.lean` |
| `Mathlib.Data.Fintype.Basic` | `Fintype` for finite message spaces | `Crypto/Scheme.lean` |
| `Mathlib.Data.ZMod.Basic` | `ZMod 2` (F\_2) — available if bitstrings need algebraic operations | `Construction/Permutation.lean` (optional; `Bool` is used instead) |
| `Mathlib.Order.BooleanAlgebra` | Boolean operations for adversary output | `Crypto/Security.lean` |

### Key Mathlib API Surface

The following Mathlib definitions and theorems are central to the formalization.
Familiarity with these is essential before beginning implementation:

| Mathlib Name | Type | Role in Orbcrypt |
|-------------|------|------------------|
| `MulAction.orbit G x` | `Set X` | The orbit of x under G |
| `MulAction.stabilizer G x` | `Subgroup G` | The stabilizer of x |
| `MulAction.orbitRel G X` | `Setoid X` | Orbits as equivalence classes |
| `MulAction.orbit_eq_iff` | theorem | `orbit G x = orbit G y ↔ x ∈ orbit G y` |
| `MulAction.mem_orbit_iff` | theorem | `y ∈ orbit G x ↔ ∃ g, g • x = y` |
| `MulAction.card_orbit_mul_card_stabilizer_eq_card_group` | theorem | Orbit-stabilizer: `|orbit| * |stab| = |G|` |
| `Equiv.Perm` | type | Permutations (symmetric group) |

### Version Strategy

Pin to a specific Mathlib4 commit via `lean-toolchain` and `lakefile.lean` to
ensure reproducible builds. Update Mathlib only during Phase 6 (Polish) if
API breakage is discovered, and only after verifying all proofs still compile.

---

## 6. Development Roadmap

The formalization proceeds in six phases. Each phase has its own detailed
planning document with implementation guidance, risk analysis, and verification
criteria.

| Phase | Title | Weeks | Units | Effort | Document |
|-------|-------|-------|-------|--------|----------|
| 1 | Project Scaffolding | 1 | 4 | 4.5h | [Phase 1](phases/PHASE_1_PROJECT_SCAFFOLDING.md) |
| 2 | Group Action Foundations | 2–4 | 11 | 28h | [Phase 2](phases/PHASE_2_GROUP_ACTION_FOUNDATIONS.md) |
| 3 | Cryptographic Definitions | 5–6 | 8 | 18h | [Phase 3](phases/PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md) |
| 4 | Core Theorems | 7–10 | 16 | 33h | [Phase 4](phases/PHASE_4_CORE_THEOREMS.md) |
| 5 | Concrete Construction | 11–14 | 12 | 26h | [Phase 5](phases/PHASE_5_CONCRETE_CONSTRUCTION.md) |
| 6 | Polish & Documentation | 15–16 | 13 | 22.5h | [Phase 6](phases/PHASE_6_POLISH_AND_DOCUMENTATION.md) |
| | **Total** | **16** | **64** | **~132h** | |

### Phase Dependencies

```
Phase 1 ─── Scaffolding
   │
   ▼
Phase 2 ─── Group Action Foundations
   │
   ├──────────────────────────────────┐
   ▼                                  ▼
Phase 3 ─── Crypto Definitions    Phase 5a ─── Permutation.lean (5.1–5.6)
   │                                  │
   ▼                                  │
Phase 4 ─── Core Theorems            │
   │                                  │
   ├──────────────────────────────────┘
   ▼
Phase 5b ─── HGOE.lean (5.7–5.11)
   │
   ▼
Phase 6 ─── Polish & Documentation
```

**Key parallelism opportunity:** `Construction/Permutation.lean` (Phase 5,
units 5.1–5.6) depends only on Phase 2's group action foundations. It can
begin as soon as Phase 2 completes, running in parallel with Phases 3 and 4.
The HGOE instantiation (units 5.7–5.11) then joins both streams.

---

## 7. Critical Path Analysis

The critical path determines the minimum time to completion, assuming unlimited
parallelism for independent work units.

### Three Critical Chains

**Chain A — Correctness (longest path):**
```
1.1 → 1.4 → 2.1 → 2.4 → 2.5 → 2.6 → 3.1 → 3.2 → 3.3 → 4.1 → 4.2 → 4.3 → 4.4 → 4.5
 2h    1h    3h    3h    2h    3h    3h    1h    4h   1.5h   2h   2.5h   2h    2h  = 32h
```

**Chain B — Invariant Attack:**
```
1.1 → 1.4 → 2.1 → 2.8 → 2.9 → 3.1 → 3.4 → 4.6 → 4.7 → 4.8 → 4.9
 2h    1h    3h    2h    3h    3h    2h    2h   1.5h   3h    2h      = 24.5h
```

**Chain C — OIA implies CPA:**
```
1.1 → 1.4 → 2.1 → 3.1 → 3.7 → 4.10 → 4.11 → 4.12 → 4.13
 2h    1h    3h    3h    2h    1.5h     2h     1.5h    1.5h   = 17.5h
```

**Overall critical path: Chain A at ~32 hours** of sequential work, achievable
within the 16-week timeline even at modest weekly throughput. The finer
decomposition of Phase 4 does not change the critical path length because
the total effort per chain is preserved — work is redistributed into
smaller units, not added.

### Parallelism Opportunities

| Phase | Independent Tracks | Max Parallel Speedup |
|-------|-------------------|---------------------|
| 2 | Basic (2.2–2.4) ∥ Canonical (2.5–2.7) ∥ Invariant (2.8–2.11) | 3x |
| 3 | Security (3.4–3.6) ∥ OIA (3.7–3.8), after Scheme (3.1–3.3) | 2x |
| 4 | Correctness (4.1–4.5) ∥ InvariantAttack (4.6–4.9) ∥ OIA→CPA (4.10–4.13) | 3x |
| 5 | Permutation (5.1–5.6) can pipeline with Phase 3–4 | pipeline |
| 6 | Sorry audit (6.1–6.4) ∥ Documentation (6.5–6.9) ∥ Infrastructure (6.10–6.11) | 3x |

---

## 8. Effort & Timeline Summary

| Metric | Value |
|--------|-------|
| Total work units | 64 |
| Total estimated effort | ~132 engineer-hours |
| Calendar duration | 16 weeks |
| Minimum serial effort (critical path) | ~32 hours |
| Maximum useful parallelism | 3 contributors |
| Lean source files produced | 10 |
| Key theorems proved | 3 (+ supporting lemmas) |
| Axioms introduced | 1 (OIA) |

### Effort Distribution

```
Phase 4: Core Theorems   █████████████████████████████████████  33h  (25%)
Phase 2: Group Actions   ██████████████████████████████  28h  (21%)
Phase 5: Construction    ████████████████████████████  26h  (20%)
Phase 6: Polish          ████████████████████████  22.5h  (17%)
Phase 3: Crypto Defs     ████████████████████  18h  (14%)
Phase 1: Scaffolding     █████  4.5h  (3%)
```

---

## 9. Coding Conventions

### Naming

| Category | Convention | Example |
|----------|-----------|---------|
| Theorems and lemmas | `snake_case` (Mathlib style) | `orbit_disjoint_or_eq`, `canon_encrypt` |
| Structures | `CamelCase` | `CanonicalForm`, `OrbitEncScheme` |
| Type variables | Capital letters by role | `G` (groups), `X` (spaces), `M` (messages) |
| Type class instances | Bracket notation | `[Group G]`, `[MulAction G X]` |
| Hypothesis names | `h`-prefixed descriptors | `hInv`, `hSep`, `hDistinct` |

### Proof Style

- Prefer **tactic mode** for non-trivial proofs.
- Use `calc` blocks for equational reasoning chains.
- Use `have` for intermediate steps with descriptive names.
- Comment proof strategy at the top of each theorem:
  ```lean
  -- Strategy: unfold encrypt, apply canon orbit_iff, use reps_distinct
  ```
- Avoid `decide` on large finite types (performance trap).

### Documentation

- Every `.lean` file begins with a `/-! ... -/` module docstring (not `/-- ... -/`).
  Module docstrings use `/-!` to avoid parse errors in files without declarations.
  Declaration docstrings (`/-- ... -/`) attach to the next declaration only.
- Every public definition and theorem has a `/-- ... -/` docstring.
- Axioms include a `-- Justification: ...` comment block explaining the
  mathematical and cryptographic reasoning.

### Import Discipline

- Import only the specific Mathlib modules needed, never `import Mathlib`.
- Re-export key definitions via the root `Orbcrypt.lean` for consumer
  convenience.
- Within the project, import by full path: `import Orbcrypt.GroupAction.Basic`.

### Git Practices

- One commit per completed work unit (or logical group of related units).
- Commit messages reference work unit numbers: `"2.5: Define CanonicalForm structure"`.
- All commits must pass `lake build` — never commit broken code.

---

*This document is the master reference for the Orbcrypt formalization effort.
For detailed implementation guidance, dependency analysis, and risk assessment
for each phase, see the individual phase documents linked in
[§6](#6-development-roadmap).*

*Parent document: [DEVELOPMENT.md](../DEVELOPMENT.md)*
