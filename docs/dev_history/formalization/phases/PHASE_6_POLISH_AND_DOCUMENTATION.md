<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Phase 6 — Polish & Documentation

## Weeks 15–16 | 13 Work Units | ~22.5 Hours

*Part of the [Orbcrypt Lean 4 Formalization Plan](../FORMALIZATION_PLAN.md)*

---

## Overview

Phase 6 transforms the formalization from a working proof artifact into a
release-quality project. It audits for completeness, adds documentation,
configures continuous integration, and performs a final verification.

The original 6 work units have been decomposed into 13 smaller units. The
`sorry` audit (originally one 4-hour block) is split across four module
groups so that each audit is focused and less error-prone. Documentation
is split by layer. A new Mathlib compatibility check (6.11) and a
dedicated final audit checklist (6.13) ensure nothing is missed.

This phase has **three parallel tracks**: sorry audit (6.1–6.4),
documentation (6.5–6.9), and infrastructure (6.10–6.11). All converge
at the final verification (6.12–6.13).

---

## Objectives

1. Zero `sorry` in non-axiom positions across all `.lean` files.
2. Every module, definition, and theorem has proper documentation.
3. CI pipeline ensures the project builds on every push.
4. Mathlib compatibility verified and pinned.
5. Clean build from scratch succeeds with zero warnings.

---

## Prerequisites

- All prior phases complete: all 10 `.lean` files compile.
- All three headline theorems proved (correctness, invariant attack, OIA ⟹ CPA).

---

## Work Units

### Track A: Sorry Audit (6.1 → 6.2 → 6.3 → 6.4)

The sorry audit is the most critical activity in Phase 6. Splitting it by
module group ensures focused attention and prevents "sorry blindness" from
auditing too many files in one sitting.

For each `sorry` found, choose one of:
- **Prove it.** Most remaining `sorry` should be provable with established lemmas.
- **Promote to `axiom`.** Only if the statement is a computational assumption
  that cannot be proved (like OIA). Must include a justification comment.
- **Remove it.** If the lemma is unused and not worth proving, delete it.

---

#### 6.1 — Sorry Audit: GroupAction Modules

**Effort:** 2h | **Module:** `GroupAction/*.lean` | **Deps:** Phase 2

**Files to audit:**
1. `GroupAction/Basic.lean` — orbit API, partition, orbit-stabilizer, membership
2. `GroupAction/Canonical.lean` — CanonicalForm, uniqueness, idempotence
3. `GroupAction/Invariant.lean` — IsGInvariant, IsSeparating, invariant-orbit

**Procedure:**
```bash
grep -rn "sorry" Orbcrypt/GroupAction/ --include="*.lean"
```

**Common sorry patterns in this layer:**

| Pattern | Likely Location | Fix |
|---------|----------------|-----|
| `orbit_disjoint_or_eq sorry` | Basic.lean | Use `MulAction.orbitRel` + equivalence class disjointness |
| `orbit_eq_of_smul sorry` | Basic.lean | Apply `MulAction.orbit_eq_iff` with witness `g` |
| `canon_eq_of_mem_orbit sorry` | Canonical.lean | Chain `orbit_eq_iff` → `orbit_iff.mpr` |
| `invariant_const_on_orbit sorry` | Invariant.lean | `obtain ⟨g, hg⟩ := mem_orbit_iff.mp hy; rw [← hg, hf g]` |
| `separating_implies_distinct_orbits sorry` | Invariant.lean | Contradiction: equal orbits → same f-value → contradicts separation |

**Definition of Done:**
- `grep -rn "sorry" Orbcrypt/GroupAction/` returns empty.
- `lake build Orbcrypt.GroupAction.Basic` succeeds (and Canonical, Invariant).

---

#### 6.2 — Sorry Audit: Crypto Modules

**Effort:** 1.5h | **Module:** `Crypto/*.lean` | **Deps:** Phase 3

**Files to audit:**
1. `Crypto/Scheme.lean` — OrbitEncScheme, encrypt, decrypt
2. `Crypto/Security.lean` — Adversary, hasAdvantage, IsSecure
3. `Crypto/OIA.lean` — OIA axiom (this file should contain NO sorry,
   only an `axiom` declaration)

**Procedure:**
```bash
grep -rn "sorry" Orbcrypt/Crypto/ --include="*.lean"
```

**Expected state:** These modules are mostly definitions, not proofs. Any
`sorry` here likely indicates a missing instance (e.g., `Decidable` for the
decrypt predicate) rather than an unproved theorem.

**Common sorry patterns:**

| Pattern | Likely Location | Fix |
|---------|----------------|-----|
| `DecidableEq` instance sorry | Scheme.lean | Use `inferInstance` or derive |
| `Decidable (decryptPred ...)` sorry | Scheme.lean | Follows from `DecidableEq X` |
| Stray `sorry` in OIA.lean | OIA.lean | Must be an `axiom`, not a `sorry`-ed theorem |

**Critical check for OIA.lean:**
```lean
-- OIA.lean must contain exactly ONE axiom and ZERO sorry:
-- axiom OIA ... : ...
-- No: theorem OIA ... := sorry
```

**Definition of Done:**
- `grep -rn "sorry" Orbcrypt/Crypto/` returns empty.
- `OIA.lean` uses `axiom`, not `sorry`.
- All three Crypto modules build.

---

#### 6.3 — Sorry Audit: Theorem Modules

**Effort:** 2h | **Module:** `Theorems/*.lean` | **Deps:** Phase 4

**Files to audit:**
1. `Theorems/Correctness.lean` — encrypt-in-orbit, canon-of-encrypt, correctness
2. `Theorems/InvariantAttack.lean` — adversary, adversary correctness, attack theorem
3. `Theorems/OIAImpliesCPA.lean` — OIA specialization, advantage elimination, security

**Procedure:**
```bash
grep -rn "sorry" Orbcrypt/Theorems/ --include="*.lean"
```

**Common sorry patterns:**

| Pattern | Likely Location | Fix |
|---------|----------------|-----|
| `Fintype.find?` spec sorry | Correctness.lean | Locate correct Mathlib lemma name; see 4.3 guidance |
| `decryptPred_unique` sorry | Correctness.lean | Contrapositive of `reps_distinct`; see 4.4 |
| `decide_eq_false` sorry | InvariantAttack.lean | Use `decide_eq_false_iff_not` or `if_neg` |
| `no_advantage_from_oia` sorry | OIAImpliesCPA.lean | Multi-step OIA application; see 4.12 strategy |

**Axiom audit (critical):**
```lean
-- After all sorry are resolved, verify:
#print axioms correctness          -- Must NOT contain sorryAx or OIA
#print axioms invariant_attack     -- Must NOT contain sorryAx or OIA
#print axioms oia_implies_1cpa     -- Must contain OIA, must NOT contain sorryAx
```

If `sorryAx` appears in any `#print axioms` output, there is a hidden
`sorry` somewhere in the dependency chain. Use `#print axioms lemma_name`
on each intermediate lemma to locate it.

**Definition of Done:**
- `grep -rn "sorry" Orbcrypt/Theorems/` returns empty.
- Axiom audit passes for all three headline theorems.
- All three Theorem modules build.

---

#### 6.4 — Sorry Audit: Construction Modules

**Effort:** 1.5h | **Module:** `Construction/*.lean` | **Deps:** Phase 5

**Files to audit:**
1. `Construction/Permutation.lean` — Bitstring, S\_n action, Hamming weight
2. `Construction/HGOE.lean` — subgroup action, scheme instance, weight defense

**Procedure:**
```bash
grep -rn "sorry" Orbcrypt/Construction/ --include="*.lean"
```

**Common sorry patterns:**

| Pattern | Likely Location | Fix |
|---------|----------------|-----|
| `perm_action_faithful` sorry | Permutation.lean | Construct indicator bitstring; see 5.4 |
| `hammingWeight_invariant` sorry | Permutation.lean | Finset bijection; see 5.6 approach B |
| `subgroupBitstringAction` sorry | HGOE.lean | Coercion + parent action; see 5.7 |

**Definition of Done:**
- `grep -rn "sorry" Orbcrypt/Construction/` returns empty.
- Both Construction modules build.

---

### Track B: Documentation (6.5 → 6.6 → 6.7 → 6.8 → 6.9)

---

#### 6.5 — Module Docstrings: Foundations Layer

**Effort:** 2h | **Module:** `GroupAction/*.lean`, `Crypto/*.lean` | **Deps:** Track A

Each `.lean` file must begin with a module-level docstring. The foundations
layer (6 files) is documented first since it's the most stable.

**Template:**
```lean
/--
# Orbcrypt.GroupAction.Basic

Core orbit and stabilizer API built on Mathlib's `MulAction` framework.
Formalizes the group action fundamentals from docs/DEVELOPMENT.md §3.1.

## Key Definitions
- `orbit G x` — the orbit of `x` under `G` (re-export from Mathlib)
- `stabilizer G x` — the stabilizer of `x` in `G` (re-export from Mathlib)

## Key Results
- `orbit_disjoint_or_eq` — orbits are disjoint or equal
- `smul_mem_orbit` — `g • x ∈ orbit G x`
- `orbit_eq_of_smul` — `orbit G (g • x) = orbit G x`
-/
```

**Files to document (6):**
1. `GroupAction/Basic.lean` — references docs/DEVELOPMENT.md §3.1
2. `GroupAction/Canonical.lean` — references docs/DEVELOPMENT.md §3.2
3. `GroupAction/Invariant.lean` — references docs/DEVELOPMENT.md §4.4
4. `Crypto/Scheme.lean` — references docs/DEVELOPMENT.md §4.1
5. `Crypto/Security.lean` — references docs/DEVELOPMENT.md §4.3
6. `Crypto/OIA.lean` — references docs/DEVELOPMENT.md §5.2

**Definition of Done:**
- All 6 files begin with a `/-- ... -/` module docstring.
- Each docstring lists key definitions and key results.
- Each docstring references the relevant docs/DEVELOPMENT.md section.

---

#### 6.6 — Module Docstrings: Theorems & Construction Layer

**Effort:** 2h | **Module:** `Theorems/*.lean`, `Construction/*.lean` | **Deps:** Track A

**Files to document (5):**
1. `Theorems/Correctness.lean` — references docs/DEVELOPMENT.md §4.2
2. `Theorems/InvariantAttack.lean` — references docs/DEVELOPMENT.md §4.4 and docs/COUNTEREXAMPLE.md
3. `Theorems/OIAImpliesCPA.lean` — references docs/DEVELOPMENT.md §8.1
4. `Construction/Permutation.lean` — references docs/DEVELOPMENT.md §3.2, §7.1
5. `Construction/HGOE.lean` — references docs/DEVELOPMENT.md §7.1

**Special attention:**
- `Theorems/OIAImpliesCPA.lean` should note which theorems depend on OIA.
- `Construction/HGOE.lean` should note the connection to docs/COUNTEREXAMPLE.md.

**Definition of Done:**
- All 5 files begin with a `/-- ... -/` module docstring.
- Theorem modules note their axiom dependencies.

---

#### 6.7 — Inline Proof Comments

**Effort:** 2.5h | **Module:** All `.lean` files | **Deps:** Track A

Add strategy comments to every non-trivial proof. Focus on the *why*, not
the *what*.

**Comment levels:**

1. **Theorem-level strategy:** At the top of each proof, 1–3 lines
   explaining the overall approach.
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

3. **Do NOT comment:** Simple `simp`, `exact`, `rfl`, or `trivial` steps.
   Comment the *why*, not the *what*.

**Priority order (highest first):**
1. Three headline theorems (correctness, invariant_attack, oia_implies_1cpa)
2. Key supporting lemmas (canon_encrypt, invariantAttackAdversary_correct,
   no_advantage_from_oia)
3. Infrastructure (decryptPred helpers, hammingWeight_invariant)

**Definition of Done:**
- Every proof > 3 lines has a strategy comment.
- Key `have` statements in headline proofs are annotated.
- No over-commenting on trivial steps.

---

#### 6.8 — Module Dependency Graph

**Effort:** 1.5h | **Module:** `Orbcrypt.lean` or `ARCHITECTURE.md` | **Deps:** Track A

Generate and document three dependency views:

**1. Module-level imports:**
```bash
grep -h "^import Orbcrypt" Orbcrypt/**/*.lean | sort -u
```

Document as a text diagram in `Orbcrypt.lean` (as a comment block) or in a
new `ARCHITECTURE.md` file.

**2. Theorem dependencies (for headline results):**
```
correctness
  ├── encrypt_mem_orbit (4.1)
  ├── canon_encrypt (4.2)
  ├── decryptPred_self (4.4)
  ├── decryptPred_unique (4.4)
  └── Fintype.find? spec (Mathlib)

invariant_attack
  ├── invariantAttackAdversary (4.6)
  ├── invariant_on_encrypt (4.7)
  └── invariantAttackAdversary_correct (4.8)

oia_implies_1cpa
  ├── no_advantage_from_oia (4.12)
  ├── oia_specialized (4.10)
  └── OIA (axiom)
```

**3. Axiom dependencies:**
```bash
# In a Lean file:
#print axioms correctness
#print axioms invariant_attack
#print axioms oia_implies_1cpa
```

**Definition of Done:**
- Dependency graph documented (either in `Orbcrypt.lean` or `ARCHITECTURE.md`).
- All three views (module, theorem, axiom) are included.

---

#### 6.9 — Axiom Transparency Report

**Effort:** 1h | **Module:** Documentation | **Deps:** 6.8

Create a dedicated section (in `Orbcrypt.lean` or `ARCHITECTURE.md`) that
clearly states:

1. **The sole axiom:** `OIA` — what it says, why it's an axiom, and where
   it's declared (`Crypto/OIA.lean`).
2. **What depends on it:** Only `oia_implies_1cpa` (and transitively,
   `IsSecure` results). The correctness theorem and invariant attack theorem
   are unconditional.
3. **What does NOT depend on it:** `correctness`, `invariant_attack`,
   all `GroupAction/` lemmas, all `Construction/` proofs.
4. **How to verify:** `#print axioms <theorem_name>` commands.

**Template:**
```lean
/--
## Axiom Transparency

This formalization introduces exactly ONE axiom beyond Lean's standard axioms:

  `axiom OIA` (declared in `Orbcrypt.Crypto.OIA`)

### Axiom-free results
- `correctness` (Theorems/Correctness.lean)
- `invariant_attack` (Theorems/InvariantAttack.lean)
- All GroupAction/ and Construction/ lemmas

### OIA-dependent results
- `oia_implies_1cpa` (Theorems/OIAImpliesCPA.lean)
- `IsSecure` (derived from oia_implies_1cpa)

Verify with: `#print axioms <theorem_name>`
-/
```

**Definition of Done:**
- Axiom transparency report written and placed.
- Every claim in the report is verified with `#print axioms`.

---

### Track C: Infrastructure (6.10 → 6.11)

---

#### 6.10 — CI Configuration

**Effort:** 2h | **Module:** `.github/workflows/` | **Deps:** Phase 1

Create a GitHub Actions workflow that builds the project on every push:

```yaml
# .github/workflows/lean4-build.yml
name: Lean 4 Build
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - name: Install elan
        run: |
          curl https://elan.lean-lang.org/install.sh -sSf | sh
          echo "$HOME/.elan/bin" >> $GITHUB_PATH
      - name: Cache Mathlib
        uses: actions/cache@v4
        with:
          path: |
            ~/.elan
            .lake
          key: mathlib-${{ hashFiles('lean-toolchain', 'lakefile.lean') }}
          restore-keys: mathlib-
      - name: Fetch Mathlib cache
        run: lake exe cache get || true
      - name: Build
        run: lake build
      - name: Verify no sorry
        run: |
          if grep -rn "sorry" Orbcrypt/ --include="*.lean"; then
            echo "ERROR: sorry found in source files"
            exit 1
          fi
```

**Key considerations:**
- Use Mathlib cache to avoid rebuilding Mathlib (~30 min without cache).
- The `cache get || true` allows builds even if the cache is stale.
- The sorry check is a separate step so it's visible in CI output.
- Set `timeout-minutes: 30` to prevent runaway builds.

**Alternative: Use `leanprover/lean4-action@v1`** if available. This
handles elan installation and Mathlib caching automatically:
```yaml
      - uses: leanprover/lean4-action@v1
        with:
          mathlib-cache: true
      - run: lake build
```

**Definition of Done:**
- `.github/workflows/lean4-build.yml` exists and is valid YAML.
- The workflow passes on a test push (or dry-run with `act` locally).

---

#### 6.11 — Mathlib Compatibility Check

**Effort:** 1.5h | **Module:** `lakefile.lean`, `lean-toolchain` | **Deps:** Phase 1

*New unit. Ensures the Mathlib pin is intentional and up-to-date.*

**Procedure:**

1. Check current Mathlib pin:
   ```bash
   cat lean-toolchain
   grep -A2 "require mathlib" lakefile.lean
   ```

2. Check if a newer Mathlib is available:
   ```bash
   cd .lake/packages/mathlib
   git log --oneline -5
   ```

3. **Decision point:** If the pin is more than 3 months old:
   - Option A: Keep the current pin (stability). Document the pin date and
     the reason for not updating.
   - Option B: Update to latest Mathlib. Run `lake update mathlib`, then
     `lake build` and fix any breakage. This is risky — only do it if
     specific Mathlib bugs are blocking.

4. **Pin explicitly** if not already:
   ```lean
   require mathlib from git
     "https://github.com/leanprover-community/mathlib4" @ "abc123..."
   ```

5. Document the pin in a comment:
   ```lean
   -- Pinned to Mathlib4 commit abc123 (2024-XX-XX)
   -- Compatible with lean4:v4.X.0
   -- Last verified: YYYY-MM-DD
   ```

**Definition of Done:**
- Mathlib version is explicitly pinned in `lakefile.lean`.
- `lean-toolchain` version matches Mathlib's requirement.
- `lake build` succeeds with the pinned version.

---

### Convergence: Final Verification (6.12 → 6.13)

---

#### 6.12 — Clean Build Verification

**Effort:** 1.5h | **Module:** All | **Deps:** 6.1–6.11

Perform a clean build from scratch:

```bash
lake clean
lake exe cache get   # Fetch Mathlib cache
lake build           # Full build
echo $?              # Must be 0
```

**If build fails:**
1. Read the error message carefully.
2. Identify which module fails (the error shows the file path).
3. Check if the failure is a Mathlib API change (common after updates).
4. Fix the specific module and re-run `lake build <Module.Path>`.
5. Do NOT use `lake build` without a target — use specific module paths
   to avoid rebuilding everything.

**Post-build checks:**
```bash
# Zero sorry:
grep -rn "sorry" Orbcrypt/ --include="*.lean"

# Count definitions and theorems:
grep -c "^theorem\|^def\|^instance\|^axiom" Orbcrypt/**/*.lean

# Count lines of Lean:
find Orbcrypt/ -name "*.lean" -exec cat {} + | wc -l
```

**Definition of Done:**
- `lake clean && lake build` succeeds with exit code 0.
- `grep sorry` returns empty.
- Build completes in < 5 minutes (with cached Mathlib).

---

#### 6.13 — Final Audit Checklist

**Effort:** 1.5h | **Module:** All | **Deps:** 6.12

This is the **final quality gate** before the formalization is declared
complete. Go through every item systematically.

**Proof integrity:**
- [x] `#print axioms correctness` — `propext`, `Classical.choice`, `Quot.sound` (standard only)
- [x] `#print axioms invariant_attack` — `propext` (standard only)
- [x] `#print axioms oia_implies_1cpa` — zero custom axioms (OIA is a hypothesis)
- [x] `grep -rn "sorry" Orbcrypt/` returns empty
- [x] Zero `axiom` declarations (OIA is a `def`, not an `axiom`)

**Documentation:**
- [x] Every `.lean` file has a module-level `/-! ... -/` docstring (12/12)
- [x] Every public `theorem` and `def` has a `/-- ... -/` docstring (56/56)
- [x] The OIA definition has a justification comment block
- [x] Dependency graph documented in `Orbcrypt.lean`
- [x] Axiom transparency report written in `Orbcrypt.lean`

**Infrastructure:**
- [x] `lakefile.lean` pins Mathlib to commit `fa6418a8`
- [x] `lean-toolchain` = `leanprover/lean4:v4.30.0-rc1` (matches Mathlib)
- [x] `.github/workflows/lean4-build.yml` exists and is valid
- [x] CI configured on push and pull_request

**Code quality:**
- [x] `autoImplicit := false` is set in `lakefile.lean`
- [x] No `import Mathlib` (only specific module imports)
- [x] Every proof > 3 lines has a strategy comment
- [x] Naming follows conventions (snake_case theorems, CamelCase structures)

**Git:**
- [x] All files committed
- [x] Commit messages reference work unit numbers
- [x] No build artifacts in the repository

**Definition of Done:**
- Every checkbox above is checked.
- The project is ready for review and public release.

---

## Parallel Execution Plan

```
  Track A: Sorry Audit    Track B: Documentation    Track C: Infrastructure
  ┌───────────────────┐   ┌───────────────────┐     ┌──────────────────┐
  │ 6.1 GroupAction 2h│   │ 6.5 Foundations 2h│     │ 6.10 CI config 2h│
  │ 6.2 Crypto    1.5h│   │ 6.6 Thm+Constr 2h│     │ 6.11 Mathlib  1.5h│
  │ 6.3 Theorems    2h│   │ 6.7 Proof cmts2.5h│     └──────────────────┘
  │ 6.4 Construct 1.5h│   │ 6.8 Dep graph 1.5h│            │
  └───────────────────┘   │ 6.9 Axiom rpt   1h│            │
           │              └───────────────────┘            │
           └──────────────────────┬────────────────────────┘
                                  ▼
                       6.12 Clean build verification (1.5h)
                                  │
                                  ▼
                       6.13 Final audit checklist (1.5h)
```

Track A (sorry audit) must complete before Track B (documentation) can
finalize, since docstrings may reference the proved lemmas. Track C
(infrastructure) is fully independent.

**Optimal schedule for a single contributor:**

| Day | Work | Hours | Running Total |
|-----|------|-------|---------------|
| 1 | 6.1 (GroupAction audit) + 6.10 (CI config) | 4h | 4h |
| 2 | 6.2 (Crypto audit) + 6.11 (Mathlib check) | 3h | 7h |
| 3 | 6.3 (Theorems audit) + 6.5 (foundations docstrings) | 4h | 11h |
| 4 | 6.4 (Construction audit) + 6.6 (theorem docstrings) | 3.5h | 14.5h |
| 5 | 6.7 (proof comments) + 6.8 (dep graph) | 4h | 18.5h |
| 6 | 6.9 (axiom report) + 6.12 (clean build) + 6.13 (final audit) | 4h | 22.5h |

---

## Risk Analysis

| Risk | Units | Likelihood | Impact | Mitigation |
|------|-------|-----------|--------|------------|
| Stubborn `sorry` requiring new lemma | 6.1–6.4 | Medium | High | Budget 2h overflow per audit block; promote to `axiom` as last resort (requires justification) |
| CI action version incompatibility | 6.10 | Low | Low | Pin action versions; test locally with `act` |
| Mathlib cache miss in CI | 6.10 | Medium | Medium | Use `actions/cache` with proper key; `cache get || true` fallback |
| Mathlib update breaks proofs | 6.11 | Medium | High | Default to keeping current pin; only update if specific bug blocks |
| Documentation is tedious and gets rushed | 6.5–6.7 | High | Medium | Do documentation alongside sorry audit (alternate between proof and prose) |
| `#print axioms` reveals unexpected dependency | 6.13 | Low | High | Investigate immediately; trace through intermediate lemmas to find the leak |

---

## Exit Criteria (Project-Level)

These are the **final exit criteria for the entire formalization**:

- [x] `lake build Orbcrypt` succeeds with exit code 0 (903 jobs, zero errors)
- [x] `grep -rn "sorry" Orbcrypt/ --include="*.lean"` returns empty
- [x] Zero `axiom` declarations in source (OIA is a `def`, not an `axiom`)
- [x] `#print axioms correctness` — `propext`, `Classical.choice`, `Quot.sound` (standard Lean only)
- [x] `#print axioms invariant_attack` — `propext` (standard Lean only)
- [x] `#print axioms oia_implies_1cpa` — zero custom axioms (OIA is a hypothesis)
- [x] Every `.lean` file has a module-level `/-! ... -/` docstring (12/12 files)
- [x] Every public theorem and def has a `/-- ... -/` docstring (54/54 declarations)
- [x] GitHub Actions CI configured (`.github/workflows/lean4-build.yml`)
- [x] Dependency graph documented in `Orbcrypt.lean` (module, theorem, and axiom views)
- [x] Axiom transparency report written in `Orbcrypt.lean`
- [x] `lakefile.lean` pins Mathlib to commit `fa6418a815fa14843b7f0a19fe5983831c5f870e`
- [x] All files committed and pushed

---

## What Comes After

With the formalization complete, the natural next steps (from docs/DEVELOPMENT.md
§10) include:

1. **Probabilistic extension** — Port CryptHOL or build a probability monad
   to formalize the full probabilistic IND-CPA game.
2. **Executable implementation** — Write a runnable Lean 4 implementation of
   HGOE with actual group computation.
3. **Extended proofs** — Formalize the multi-query security argument (§8.2)
   and the noisy variant (§8.3).
4. **Community review** — Submit to the Lean 4 community for review and
   potential inclusion in a formal cryptography library.
