# Phase 6 — Polish & Documentation

## Weeks 15–16 | 6 Work Units | ~16 Hours

*Part of the [Orbcrypt Lean 4 Formalization Plan](../FORMALIZATION_PLAN.md)*

---

## Overview

Phase 6 transforms the formalization from a working proof artifact into a
release-quality project. It audits for completeness, adds documentation,
configures continuous integration, and performs a final verification.

This phase has **two parallel tracks**: content quality (6.1–6.4) and
infrastructure (6.5–6.6).

---

## Objectives

1. Zero `sorry` in non-axiom positions across all `.lean` files.
2. Every module, definition, and theorem has proper documentation.
3. CI pipeline ensures the project builds on every push.
4. Clean build from scratch succeeds with zero warnings.

---

## Prerequisites

- All prior phases complete: all 10 `.lean` files compile.
- All three headline theorems proved (correctness, invariant attack, OIA ⟹ CPA).

---

## Work Units

### 6.1 — Audit All `sorry`

**Effort:** 4h | **Module:** All `.lean` files | **Deps:** All prior phases

#### Implementation Guidance

1. Search for all `sorry` instances:
   ```bash
   grep -rn "sorry" Orbcrypt/ --include="*.lean"
   ```

2. For each `sorry` found, choose one of:
   - **Prove it.** Most remaining `sorry` should be provable with the lemmas
     already established.
   - **Promote to `axiom`.** If the statement is a computational assumption
     that cannot be proved (like OIA), declare it as an `axiom` with a
     justification comment.
   - **Remove it.** If the lemma is unused and not worth proving, delete it.
     Do not leave dead `sorry` code.

3. After all `sorry` instances are resolved, verify:
   ```bash
   grep -rn "sorry" Orbcrypt/ --include="*.lean"
   # Should return empty
   ```

4. Verify axiom transparency:
   ```lean
   #print axioms correctness          -- Should show only standard axioms
   #print axioms invariant_attack     -- Should show only standard axioms
   #print axioms oia_implies_1cpa     -- Should show OIA + standard axioms
   ```

#### Common `sorry` Patterns and Fixes

| Pattern | Typical Cause | Fix |
|---------|--------------|-----|
| Orbit membership `sorry` | Missing `simp` lemma | Add `@[simp]` to `smul_mem_orbit` |
| `Fintype.find?` `sorry` | Spec lemma unknown | Use `Finset.univ.find?_some` or equivalent |
| `DecidableEq` `sorry` | Instance not derived | Add `deriving DecidableEq` or use `inferInstance` |
| `ext` goal `sorry` | Function extensionality | Apply `funext` tactic |

---

### 6.2 — Add Module Docstrings

**Effort:** 3h | **Module:** All `.lean` files | **Deps:** All prior phases

Each `.lean` file must begin with a module-level docstring explaining:
- What the module contains
- Its role in the overall formalization
- Which section of DEVELOPMENT.md it formalizes
- Key definitions and theorems in the module

**Template:**
```lean
/--
# Orbcrypt.GroupAction.Basic

Core orbit and stabilizer API built on Mathlib's `MulAction` framework.
Formalizes the group action fundamentals from DEVELOPMENT.md §3.1.

## Key Definitions
- `orbit G x` — the orbit of `x` under `G` (re-export from Mathlib)
- `stabilizer G x` — the stabilizer of `x` in `G` (re-export from Mathlib)

## Key Results
- `orbit_disjoint_or_eq` — orbits are disjoint or equal
- `smul_mem_orbit` — `g • x ∈ orbit G x`
- `orbit_eq_of_smul` — `orbit G (g • x) = orbit G x`
-/
```

---

### 6.3 — Add Inline Proof Comments

**Effort:** 3h | **Module:** All `.lean` files | **Deps:** All prior phases

Each non-trivial proof tactic block should have a comment explaining the
strategy. Focus on:

1. **Theorem-level strategy comments:** At the top of each proof, a 1-3 line
   comment explaining the approach.
   ```lean
   theorem correctness ... := by
     -- Strategy: unfold encrypt/decrypt, show canon(g • reps m) = canon(reps m)
     -- by orbit membership + canonical form properties, then use reps_distinct
     -- to conclude Fintype.find? returns some m.
   ```

2. **Key step annotations:** Before non-obvious `have` statements.
   ```lean
     -- The ciphertext is in the same orbit as the representative:
     have h_orbit : c ∈ orbit G (reps m) := encrypt_mem_orbit ...
   ```

3. **Do not over-comment.** Skip comments for simple `simp`, `exact`, or
   `rfl` steps. Comment the *why*, not the *what*.

---

### 6.4 — Dependency Graph

**Effort:** 2h | **Module:** Documentation | **Deps:** All prior phases

Generate a text-based dependency graph showing:
1. Module-level import dependencies (which files import which).
2. Theorem dependencies (which lemmas each headline theorem uses).
3. Axiom dependencies (which theorems depend on the OIA axiom).

Add this as a comment block in `Orbcrypt.lean` or as a separate
`ARCHITECTURE.md` in the project root.

**Generate programmatically where possible:**
```bash
# Module imports
grep -h "^import Orbcrypt" Orbcrypt/*.lean Orbcrypt/**/*.lean | sort -u

# Axiom dependencies
lake env lean --run -c '#print axioms correctness' 2>/dev/null
```

---

### 6.5 — CI Configuration

**Effort:** 2h | **Module:** `.github/workflows/` | **Deps:** Phase 1

Create a GitHub Actions workflow that builds the project on every push:

```yaml
# .github/workflows/lean4-build.yml
name: Lean 4 Build
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: leanprover/lean4-action@v1
        with:
          mathlib-cache: true
      - run: lake build
```

**Key considerations:**
- Use `mathlib-cache: true` to avoid rebuilding Mathlib on every CI run.
- Cache `~/.elan` and `./lake-packages` for faster subsequent builds.
- Set a reasonable timeout (30 minutes should suffice with cached Mathlib).

---

### 6.6 — Final Build Verification

**Effort:** 2h | **Module:** All | **Deps:** 6.1–6.5

Perform a clean build from scratch and verify everything:

```bash
lake clean
lake exe cache get   # Fetch Mathlib cache
lake build           # Full build
echo $?              # Must be 0
```

**Verification checklist:**
1. Zero errors from `lake build`.
2. Zero `sorry` (verified by grep).
3. `#print axioms` for each headline theorem shows expected dependencies.
4. CI workflow passes on a push to a test branch.
5. All `.lean` files have module docstrings.

---

## Parallel Execution Plan

```
  Track A: Content Quality     Track B: Infrastructure
  ┌───────────────────────┐    ┌──────────────────────┐
  │ 6.1 Audit sorry       │    │ 6.5 CI configuration │
  │ 6.2 Module docstrings │    └──────────────────────┘
  │ 6.3 Proof comments    │              │
  │ 6.4 Dependency graph  │              │
  └───────────────────────┘              │
           │                             │
           └──────────────┬──────────────┘
                          ▼
                  6.6 Final verification
```

6.5 (CI) can proceed independently of the content quality work.

---

## Risk Analysis

| Risk | Units | Likelihood | Impact | Mitigation |
|------|-------|-----------|--------|------------|
| Stubborn `sorry` that requires new lemma | 6.1 | Medium | High | Budget 4h specifically for this; promote to `axiom` if truly stuck |
| CI action version incompatibility | 6.5 | Low | Low | Pin action versions; test locally first with `act` |
| Mathlib cache miss in CI | 6.5 | Medium | Medium | Use official `lean4-action` which handles caching |
| Documentation is tedious and gets rushed | 6.2, 6.3 | High | Medium | Do 6.2 and 6.3 incrementally alongside other work |

---

## Exit Criteria (Project-Level)

These are the **final exit criteria for the entire formalization**:

- [ ] `lake clean && lake build` succeeds with exit code 0
- [ ] `grep -rn "sorry" Orbcrypt/ --include="*.lean"` returns empty
- [ ] `#print axioms correctness` — no `OIA`, no `sorry`
- [ ] `#print axioms invariant_attack` — no `OIA`, no `sorry`
- [ ] `#print axioms oia_implies_1cpa` — only `OIA` (plus standard Lean axioms)
- [ ] Every `.lean` file has a module-level docstring
- [ ] Every public theorem has a docstring
- [ ] GitHub Actions CI passes on push
- [ ] Dependency graph documented in `Orbcrypt.lean` or `ARCHITECTURE.md`
- [ ] All files committed and pushed

---

## What Comes After

With the formalization complete, the natural next steps (from DEVELOPMENT.md
§10) include:

1. **Probabilistic extension** — Port CryptHOL or build a probability monad
   to formalize the full probabilistic IND-CPA game.
2. **Executable implementation** — Write a runnable Lean 4 implementation of
   HGOE with actual group computation.
3. **Extended proofs** — Formalize the multi-query security argument (§8.2)
   and the noisy variant (§8.3).
4. **Community review** — Submit to the Lean 4 community for review and
   potential inclusion in a formal cryptography library.
