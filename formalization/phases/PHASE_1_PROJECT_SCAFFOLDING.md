# Phase 1 — Project Scaffolding

## Week 1 | 4 Work Units | ~4.5 Hours

*Part of the [Orbcrypt Lean 4 Formalization Plan](../FORMALIZATION_PLAN.md)*

---

## Overview

Phase 1 establishes the Lean 4 project infrastructure that all subsequent
phases build upon. The deliverable is a clean, building Lean 4 project with
Mathlib as a dependency, the full directory structure in place, and a root
import file connecting all modules.

This phase is **strictly sequential** — each work unit depends on the previous
one. There are no parallelism opportunities, but the total effort is small
(~4.5 hours) and the work is mechanical.

---

## Objectives

1. A working Lean 4 project that successfully resolves and builds Mathlib.
2. The complete directory and file structure from the master plan (§3).
3. A root import file that will serve as the single entry point for consumers.
4. Confirmation that `lake build` succeeds with zero errors.

---

## Prerequisites

- **Lean 4** installed (via `elan`). Use the stable toolchain unless a specific
  Mathlib commit requires nightly.
- **Git** initialized (already done — repository exists).
- Familiarity with `lake` (Lean 4 build system) and `lakefile.lean` syntax.

---

## Work Units

### 1.1 — Initialize Lean 4 Project

**Effort:** 2 hours
**Deliverable:** `lakefile.lean`, `lean-toolchain`, `.gitignore` with Mathlib
dependency configured and resolving.

#### Implementation Guidance

1. **Create `lean-toolchain`:**
   ```
   leanprover/lean4:v4.x.0
   ```
   Pin to a specific stable version. Check which version the target Mathlib
   commit requires by consulting [the Mathlib4 lean-toolchain file](https://github.com/leanprover-community/mathlib4/blob/master/lean-toolchain).

2. **Create `lakefile.lean`:**
   ```lean
   import Lake
   open Lake DSL

   package "orbcrypt" where
     version := v!"0.1.0"
     leanOptions := #[
       ⟨`autoImplicit, false⟩  -- Enforce explicit universe/variable declarations
     ]

   require "leanprover-community" / "mathlib" @ git "master"

   @[default_target]
   lean_lib Orbcrypt where
     srcDir := "."
   ```

   **Key decisions:**
   - `autoImplicit := false` prevents subtle bugs from Lean auto-introducing
     universe variables. This is standard practice for formal verification
     projects.
   - Mathlib is pulled from git. For reproducibility, pin to a specific commit
     hash in `lake-manifest.json` rather than tracking a branch.
   - **Lake 5.0.0 syntax:** Package names are now strings (`"orbcrypt"`),
     and `require` uses scope/name syntax (`"leanprover-community" / "mathlib"`).

3. **Create `.gitignore`:**
   ```
   /build/
   /lake-packages/
   /.lake/
   /lakefile.olean
   ```

4. **Run `lake update`** to fetch Mathlib. This will take significant time on
   first run (Mathlib is large). Verify it completes without error.

#### Verification

```bash
lake update    # Fetches Mathlib — may take 10-30 minutes on first run
lake env printPaths  # Should show Mathlib in the package list
```

#### Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Lean/Mathlib version mismatch | Medium | Blocks all work | Always check Mathlib's `lean-toolchain` first and match exactly |
| Mathlib download failure (network) | Low | Delays | Retry; use `lake update` with `--verbose` for diagnostics |
| `autoImplicit` causing confusion later | Medium | Subtle bugs | Set `autoImplicit := false` from the start (done above) |

---

### 1.2 — Create Directory Structure

**Effort:** 1 hour
**Deliverable:** All directories and empty `.lean` stub files per the master
plan's project architecture.

#### Implementation Guidance

Create the following structure inside the project root:

```
Orbcrypt/
├── GroupAction/
│   ├── Basic.lean
│   ├── Canonical.lean
│   └── Invariant.lean
├── Crypto/
│   ├── Scheme.lean
│   ├── Security.lean
│   └── OIA.lean
├── Theorems/
│   ├── Correctness.lean
│   ├── InvariantAttack.lean
│   └── OIAImpliesCPA.lean
└── Construction/
    ├── HGOE.lean
    └── Permutation.lean
```

Each `.lean` file should contain a minimal stub using a module docstring:

```lean
/-!
# Module.Name

[Module purpose — one or two lines]
-/

-- TODO: Implementation in Phase N, Work Unit N.X
```

**Note:** Use `/-! ... -/` (module docstring) not `/-- ... -/` (declaration docstring).
Declaration docstrings attach to the next declaration and will cause parse errors
in files with no declarations. Module docstrings are freestanding.

This ensures `lake build` can find all files referenced by the root import.

#### Verification

```bash
find Orbcrypt/ -name "*.lean" | sort
# Should list all 11 files in the structure above
```

---

### 1.3 — Create Root Import File

**Effort:** 30 minutes
**Deliverable:** `Orbcrypt.lean` importing all submodules.

#### Implementation Guidance

Create `Orbcrypt.lean` at the project root (next to `lakefile.lean`):

```lean
import Orbcrypt.GroupAction.Basic
import Orbcrypt.GroupAction.Canonical
import Orbcrypt.GroupAction.Invariant

import Orbcrypt.Crypto.Scheme
import Orbcrypt.Crypto.Security
import Orbcrypt.Crypto.OIA

import Orbcrypt.Theorems.Correctness
import Orbcrypt.Theorems.InvariantAttack
import Orbcrypt.Theorems.OIAImpliesCPA

import Orbcrypt.Construction.Permutation
import Orbcrypt.Construction.HGOE

/-!
# Orbcrypt — Formal Verification of Permutation-Orbit Encryption

This is the root import file. Importing `Orbcrypt` gives access to the
complete formalization: group action foundations, cryptographic definitions,
core theorems, and the concrete HGOE construction.
-/
```

**Note:** In Lean 4, `import` statements must appear at the very beginning of
a file. Module docstrings (`/-! ... -/`) must come after all imports. Using a
declaration docstring (`/-- ... -/`) before imports will cause a parse error.

#### Verification

The file should parse without errors (though the imported stubs are empty, the
imports themselves should resolve once `lake build` runs).

---

### 1.4 — Verify Clean Build

**Effort:** 1 hour
**Deliverable:** `lake build` succeeds with Mathlib resolved, all stubs
compiling, and zero errors.

#### Implementation Guidance

1. Run `lake build` from the project root.
2. On first build with Mathlib, this will compile Mathlib's `.olean` cache.
   Using Mathlib's precompiled cache significantly speeds this up:
   ```bash
   lake exe cache get   # Downloads precompiled Mathlib .olean files
   lake build           # Should now be fast
   ```
3. Fix any issues:
   - **Import resolution failures:** verify file paths match `import` statements
     exactly (Lean 4 is case-sensitive).
   - **Toolchain errors:** ensure `lean-toolchain` matches Mathlib's requirement.

#### Verification

```bash
lake build 2>&1 | tail -5
# Should end with a successful build message and no errors
echo $?
# Should be 0
```

#### Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Mathlib cache download fails | Low | 30+ minute build time | Fall back to full source compilation; ensure sufficient disk space (>5GB) |
| Case-sensitive import mismatch | Medium | Build failure | Double-check directory names match import paths exactly |
| Stale oleans after file moves | Low | Confusing errors | Run `lake clean` before `lake build` if files were moved |

---

## Dependency Graph

```
1.1 Initialize Lean 4 project
 │
 ▼
1.2 Create directory structure
 │
 ▼
1.3 Create root import file
 │
 ▼
1.4 Verify clean build
```

Strictly linear — no parallelism possible in this phase.

---

## Exit Criteria

All of the following must be true before proceeding to Phase 2:

- [x] `lean-toolchain` pins a specific Lean 4 version compatible with Mathlib
- [x] `lakefile.lean` declares the `orbcrypt` package with Mathlib dependency
- [x] `.gitignore` excludes build artifacts
- [x] All 11 `.lean` stub files exist in the correct directory structure
- [x] `Orbcrypt.lean` imports all 11 submodules
- [x] `lake build` completes with exit code 0 and zero errors
- [x] All files are committed to version control

---

## Transition to Phase 2

With the project infrastructure in place, Phase 2 begins populating the
`GroupAction/` modules with Mathlib wrappers and orbit-encryption-specific
lemmas. The first task (2.1) directly builds on the empty `GroupAction/Basic.lean`
stub created in this phase.

See: [Phase 2 — Group Action Foundations](PHASE_2_GROUP_ACTION_FOUNDATIONS.md)
