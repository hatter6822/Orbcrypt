<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Phase 16 — Formal Verification of New Components

## Weeks 30–36 | 10 Work Units | ~36 Hours

*Part of the [Orbcrypt Practical Improvements Plan](../../docs/dev_history/formalization/PRACTICAL_IMPROVEMENTS_PLAN.md)*

**Status: COMPLETE (2026-04-21).** All 10 work units delivered. See
`docs/VERIFICATION_REPORT.md` for the consolidated Phase 16 verification
report and `scripts/audit_phase_16.lean` for the machine-checked
`#print axioms` audit script (153 declarations, no `sorryAx`, no custom
axiom). The CI pipeline (`.github/workflows/lean4-build.yml`) runs the
audit script as a regression sentinel on every push.

---

## Overview

Phase 16 extends the Lean 4 formalization to cover the new components from
Phases 7–10. It maintains the project's zero-sorry, zero-custom-axiom standard
wherever possible. Components requiring probabilistic reasoning may use
documented `sorry`s as placeholders for future work.

**Scope:** Verify KEM correctness, AEAD correctness, hybrid encryption
correctness, and key structural lemmas. Security theorems involving
probability (Phase 8) may remain partially formalized.

---

## Objectives

1. Audit all KEM modules (Phase 7) for zero sorry / zero custom axioms.
2. Audit all AEAD modules (Phase 10) for zero sorry.
3. Audit probability modules (Phase 8) — classify all sorry placeholders.
4. Comprehensive sorry audit across all new modules.
5. Comprehensive axiom audit via `#print axioms`.
6. Module docstring audit for Phase 6 standards.
7. Update root import file and dependency graph.
8. Update CI configuration for new modules.
9. Regression test Phases 1–6.
10. Produce final verification report.

---

## Prerequisites

- Phases 7–10 complete (all Lean modules to audit)

---

## Work Units

#### 16.1 — KEM Module Verification

**Effort:** 4h | **File:** `KEM/*.lean` | **Deps:** Phase 7

Audit all Phase 7 modules:
- Verify `kem_correctness` compiles with zero `sorry`
- Verify `kemoia_implies_secure` compiles with zero `sorry`
- Verify `toKEM_correct` compiles with zero `sorry`
- Run `#print axioms` on each theorem
- Verify CI passes with new modules

**Exit criteria:** All Phase 7 theorems compile. Axiom report updated.

---

#### 16.2 — AEAD Module Verification

**Effort:** 4h | **File:** `AEAD/*.lean` | **Deps:** Phase 10

Audit all Phase 10 modules:
- Verify `aead_correctness` compiles with zero `sorry`
- Verify `hybrid_correctness` compiles with zero `sorry`
- Verify MAC correctness field is well-typed
- Run `#print axioms` on each theorem

**Exit criteria:** All Phase 10 theorems compile. Axiom report updated.

---

#### 16.3 — Probability Module Verification

**Effort:** 5h | **File:** `Probability/*.lean` | **Deps:** Phase 8

**Sub-tasks:**

**16.3a — Monad.lean audit (1.5h).**
- `uniformPMF` type-checks with correct Mathlib imports
- `probEvent` / `probTrue` type-check
- Sanity lemmas compile
- Run `#print axioms` on each definition
Exit: audit checklist complete.

**16.3b — Advantage.lean audit (1.5h).**
- `advantage` and all properties compile
- `hybrid_argument` compiles
- Run `#print axioms`
Exit: audit checklist complete.

**16.3c — CompOIA and CompSecurity audit (2h).**
- `ConcreteOIA` type-checks
- `concrete_oia_implies_1cpa` compiles (primary deliverable)
- Classify every `sorry`:
  - `multi_query_skeleton` (8.10): intentional, HSP out of scope
  - PMF-related sorry: document exact Mathlib gap
  - Type-elaboration sorry: document exact error
Exit: every `sorry` classified and documented.

**Exit criteria:** All non-sorry theorems compile. Every sorry documented.

---

#### 16.4 — Sorry Audit

**Effort:** 3h | **File:** All new `.lean` files | **Deps:** 16.1–16.3

```bash
grep -rn "sorry" Orbcrypt/ --include="*.lean"
```

For each sorry: classify as (a) proof obligation to fill, (b) intentional
placeholder, or (c) accidental leftover. Fix type (c) immediately.

**Exit criteria:** Zero type-(a) or type-(c) sorrys. All type-(b) documented.

---

#### 16.5 — Axiom Audit

**Effort:** 2h | **File:** All new `.lean` files | **Deps:** 16.1–16.3

```lean
#print axioms kem_correctness
#print axioms kemoia_implies_secure
#print axioms aead_correctness
#print axioms hybrid_correctness
#print axioms concrete_oia_implies_1cpa
```

Verify: no `sorryAx`, no custom axioms, OIA only as hypothesis.

**Exit criteria:** Axiom transparency report updated in `Orbcrypt.lean`.

---

#### 16.6 — Module Docstring Audit

**Effort:** 3h | **File:** All new `.lean` | **Deps:** 16.1–16.3

Every new `.lean` file must have:
- `/-! ... -/` module docstring
- Every public def/theorem/structure has `/-- ... -/` docstring
- Proof strategy comments on proofs > 3 lines

**Exit criteria:** Docstring coverage matches Phase 6 standards.

---

#### 16.7 — Dependency Graph Update

**Effort:** 3h | **File:** `Orbcrypt.lean` | **Deps:** 16.1–16.3

Add all new imports to the root file:

```lean
import Orbcrypt.KEM.Syntax
import Orbcrypt.KEM.Encapsulate
import Orbcrypt.KEM.Correctness
import Orbcrypt.KEM.Security
import Orbcrypt.Probability.Monad
import Orbcrypt.Probability.Negligible
import Orbcrypt.Probability.Advantage
import Orbcrypt.Crypto.CompOIA
import Orbcrypt.Crypto.CompSecurity
import Orbcrypt.KeyMgmt.SeedKey
import Orbcrypt.KeyMgmt.Nonce
import Orbcrypt.AEAD.MAC
import Orbcrypt.AEAD.AEAD
import Orbcrypt.AEAD.Modes
```

Update the ASCII dependency graph in the module docstring.

**Exit criteria:** `lake build Orbcrypt` succeeds with all new imports.

---

#### 16.8 — CI Update

**Effort:** 3h | **File:** `.github/workflows/lean4-build.yml` | **Deps:** 16.7

- Build all new modules
- Check for sorry (with allowlist for Phase 8 placeholders)
- Check for custom axioms
- Run `#print axioms` on headline theorems

**Exit criteria:** CI passes on the branch with all new modules.

---

#### 16.9 — Regression Testing

**Effort:** 3h | **File:** All `.lean` files | **Deps:** 16.7

Build all 11 original modules individually and verify axiom dependencies:

```bash
lake build Orbcrypt.GroupAction.Basic
lake build Orbcrypt.GroupAction.Canonical
lake build Orbcrypt.GroupAction.Invariant
lake build Orbcrypt.Crypto.Scheme
lake build Orbcrypt.Crypto.Security
lake build Orbcrypt.Crypto.OIA
lake build Orbcrypt.Theorems.Correctness
lake build Orbcrypt.Theorems.InvariantAttack
lake build Orbcrypt.Theorems.OIAImpliesCPA
lake build Orbcrypt.Construction.Permutation
lake build Orbcrypt.Construction.HGOE
```

```lean
#print axioms Orbcrypt.correctness      -- propext, Classical.choice, Quot.sound
#print axioms Orbcrypt.invariant_attack -- propext
#print axioms Orbcrypt.oia_implies_1cpa -- (empty)
```

**Exit criteria:** All 11 original modules build. Axiom deps unchanged.

---

#### 16.10 — Final Verification Report

**Effort:** 6h | **File:** `docs/VERIFICATION_REPORT.md` | **Deps:** 16.1–16.9

**Sub-tasks:**

**16.10a — Automated statistics collection (1.5h).** Shell script to count:
files, lines, theorems, sorrys, axioms, structures/defs.

**16.10b — Theorem inventory (1.5h).** Table of every public theorem with
file, axiom deps, sorry status.

**16.10c — Headline results table (1.5h).**

| # | Name | File | Status | Axioms |
|---|------|------|--------|--------|
| 1 | `correctness` | `Theorems/Correctness.lean` | Unconditional | Standard |
| 2 | `invariant_attack` | `Theorems/InvariantAttack.lean` | Unconditional | `propext` |
| 3 | `oia_implies_1cpa` | `Theorems/OIAImpliesCPA.lean` | Conditional (det OIA) | None |
| 4 | `kem_correctness` | `KEM/Correctness.lean` | Unconditional | Standard |
| 5 | `kemoia_implies_secure` | `KEM/Security.lean` | Conditional (KEM-OIA) | ? |
| 6 | `aead_correctness` | `AEAD/AEAD.lean` | Unconditional | Standard |
| 7 | `hybrid_correctness` | `AEAD/Modes.lean` | Unconditional | Standard |
| 8 | `concrete_oia_implies_1cpa` | `Crypto/CompSecurity.lean` | Conditional | ? |

**16.10d — Known limitations (1.5h).** List all unverified items with
justification: HSP sorry, tensor action sorry, stretch-goal sorry.

**Exit criteria:** Report complete and internally consistent.

---

## Internal Dependency Graph

```
16.1 (KEM)    16.2 (AEAD)    16.3 (Probability)
       \            |            /
        \           |           /
         16.4 (Sorry Audit)
         16.5 (Axiom Audit)
         16.6 (Docstring Audit)
                    |
              16.7 (Dep Graph)
                    |
         ┌─────────┼──────────┐
      16.8 (CI)    |       16.9 (Regression)
                    |
              16.10 (Report)
```

---

## Phase Exit Criteria

1. All Phase 7 theorems compile with zero sorry and zero custom axioms.
2. All Phase 10 theorems compile with zero sorry.
3. Phase 8 sorry count documented; all non-sorry theorems compile.
4. Axiom transparency report covers all new modules.
5. `lake build Orbcrypt` succeeds with all new imports.
6. CI passes on the branch.
7. All 11 original modules still build with unchanged axiom deps.
8. `docs/VERIFICATION_REPORT.md` is complete.

---

## Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 16.1 | KEM Verification | `KEM/*.lean` | 4h | Phase 7 |
| 16.2 | AEAD Verification | `AEAD/*.lean` | 4h | Phase 10 |
| 16.3 | Probability Verification | `Probability/*.lean` | 5h | Phase 8 |
| 16.4 | Sorry Audit | All new `.lean` | 3h | 16.1–16.3 |
| 16.5 | Axiom Audit | All new `.lean` | 2h | 16.1–16.3 |
| 16.6 | Docstring Audit | All new `.lean` | 3h | 16.1–16.3 |
| 16.7 | Dependency Graph Update | `Orbcrypt.lean` | 3h | 16.1–16.3 |
| 16.8 | CI Update | `.github/workflows/` | 3h | 16.7 |
| 16.9 | Regression Testing | All `.lean` | 3h | 16.7 |
| 16.10 | Final Verification Report | `docs/VERIFICATION_REPORT.md` | 6h | 16.1–16.9 |
