# CLAUDE.md — Orbcrypt project guidance

## What this project is

Orbcrypt is a research-stage symmetric-key encryption scheme with formal verification in Lean 4 using Mathlib. Security arises from hiding the equivalence relation (orbit structure) that makes data meaningful, not from hiding data itself. A message is the *identity* of an orbit under a secret permutation group G ≤ S_n; a ciphertext is a uniformly random element of that orbit. The hardness assumption (OIA) reduces to Graph Isomorphism on Cai-Furer-Immerman graphs and to Permutation Code Equivalence. Current status: Phases 1–3 complete. Group action foundations, cryptographic definitions (scheme, adversary, OIA axiom) are fully formalized. Phase 4 (core theorems) is next.

## Build and run

```bash
# Environment setup (recommended: use the setup script)
./scripts/setup_lean_env.sh

# Or manually: install Lean 4 via elan
source ~/.elan/env

# Build entire project
source ~/.elan/env && lake build

# Build a specific module
source ~/.elan/env && lake build Orbcrypt.GroupAction.Basic

# Download Mathlib precompiled cache (speeds up builds that import Mathlib)
lake exe cache get
```

**Toolchain:** Lean 4 v4.30.0-rc1 (pinned in `lean-toolchain` to match Mathlib). The `scripts/setup_lean_env.sh` script handles full environment setup including elan, the Lean toolchain, and CRT verification.

## Module build verification (mandatory)

**Before committing any `.lean` file**, you MUST verify that the specific module compiles:

```bash
source ~/.elan/env && lake build <Module.Path>
```

For example, if you modified `Orbcrypt/GroupAction/Basic.lean`:
```bash
lake build Orbcrypt.GroupAction.Basic
```

**`lake build` (default target) is NOT sufficient.** The default target only builds modules reachable from the root `Orbcrypt.lean` import file. Modules not yet imported will silently pass `lake build` even with broken proofs. Always build the specific module path.

## Source layout

```
Orbcrypt.lean                         Root import file (imports all submodules)
Orbcrypt/
  GroupAction/
    Basic.lean                        Orbits, stabilizers, orbit partition, orbit-stabilizer wrapper
    Canonical.lean                    Canonical forms: definition, uniqueness, idempotence
    Invariant.lean                    G-invariant functions, separating condition, orbit constancy
  Crypto/
    Scheme.lean                       AOE scheme syntax (Setup, Enc, Dec)
    Security.lean                     IND-CPA game, adversary structure, advantage definition
    OIA.lean                          Orbit Indistinguishability Assumption (Prop definition)
    CompOIA.lean                      Probabilistic OIA: ConcreteOIA, CompOIA, orbit distribution
    CompSecurity.lean                 Probabilistic IND-CPA game and security theorems
  Probability/
    Monad.lean                        PMF wrappers: uniformPMF, probTrue, sanity lemmas
    Negligible.lean                   Negligible function definition and closure properties
    Advantage.lean                    Distinguishing advantage, triangle inequality, hybrid argument
  Theorems/
    Correctness.lean                  Dec(Enc(m)) = m
    InvariantAttack.lean              Separating invariant implies Adv = 1/2 (complete break)
    OIAImpliesCPA.lean                OIA implies IND-1-CPA security
  KEM/
    Syntax.lean                       OrbitKEM structure, OrbitEncScheme.toKEM bridge
    Encapsulate.lean                  encaps and decaps functions, simp lemmas
    Correctness.lean                  decaps(encaps()) recovers the key (rfl)
    Security.lean                     KEMAdversary, KEMOIA, kemoia_implies_secure
  Construction/
    Permutation.lean                  S_n action on {0,1}^n, Bitstring type, Hamming weight
    HGOE.lean                         Hidden-Group Orbit Encryption instance, correctness, weight defense
    HGOEKEM.lean                      HGOE-KEM instantiation, bridge from scheme to KEM
  KeyMgmt/
    SeedKey.lean                      Seed-based key compression, HGOEKeyExpansion spec, backward compat
    Nonce.lean                        Nonce-based deterministic encryption, misuse resistance properties
```

### Module dependency graph

```
              GroupAction.Basic
             /       |        \
            /        |         \
 GroupAction.   GroupAction.   (orbit lemmas
  Canonical      Invariant     feed both)
           \        |         /
            \       |        /
             Crypto.Scheme ─────────── KEM.Syntax
            /              \               |
           /                \         KEM.Encapsulate
  Crypto.Security        Crypto.OIA    /          \
     |        \            /      KEM.Correctness  KEM.Security
     |         \          /
     |    Theorems.OIAImpliesCPA
     |
  Theorems.Correctness
  Theorems.InvariantAttack
              |
              v
  Construction.Permutation
              |
              v
  Construction.HGOE ──── Construction.HGOEKEM

  Mathlib.Probability.PMF ──── Mathlib.Distributions.Uniform
              |
              v
  Probability.Monad ─────── Probability.Negligible
              |                       |
              v                       v
  Probability.Advantage ◄────────────┘
              |
              v
  Crypto.CompOIA ◄── Crypto.OIA
              |
              v
  Crypto.CompSecurity ◄── Crypto.Security

  KEM.Encapsulate + Construction.Permutation
              |
              v
  KeyMgmt.SeedKey ──── (SeedKey, HGOEKeyExpansion)
              |
              v
  KeyMgmt.Nonce ────── (nonceEncaps, nonce-misuse properties)
```

## Document layout

```
README.md                             Project title and tagline
LICENSE                               MIT license
CLAUDE.md                             This file — development guidance for Claude
DEVELOPMENT.md                        Master specification (~56KB): scheme design, security proofs, hardness reductions
POE.md                                Permutation-Orbit Encryption high-level concept exposition
COUNTEREXAMPLE.md                     Critical vulnerability analysis: invariant attack theorem
lakefile.lean                         Lake build configuration (Mathlib dependency, autoImplicit := false)
lean-toolchain                        Lean 4 version pin (v4.30.0-rc1, matching Mathlib)
lake-manifest.json                    Dependency lock file (Mathlib + 8 transitive deps)
.gitignore                            Build artifact exclusions
scripts/
  setup_lean_env.sh                   Lean environment setup (elan, toolchain, CRT verification)
.claude/
  settings.json                       Claude Code session hook (auto-runs setup on start)
formalization/
  FORMALIZATION_PLAN.md               Master Lean 4 formalization roadmap (architecture, timeline, conventions)
  phases/
    PHASE_1_PROJECT_SCAFFOLDING.md    Week 1: lakefile.lean, directory structure, root import, clean build
    PHASE_2_GROUP_ACTION_FOUNDATIONS.md  Weeks 2-4: orbit/stabilizer API, canonical forms, invariants
    PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md  Weeks 5-6: AOE scheme, IND-CPA game, OIA assumption
    PHASE_4_CORE_THEOREMS.md          Weeks 7-10: correctness, invariant attack, OIA implies CPA
    PHASE_5_CONCRETE_CONSTRUCTION.md  Weeks 11-14: S_n on bitstrings, HGOE instance, Hamming defense
    PHASE_6_POLISH_AND_DOCUMENTATION.md  Weeks 15-16: sorry audit, docstrings, Mathlib update, README
```

## Reading large files

Several files in this repo are large (DEVELOPMENT.md is ~56KB). When reading any file, always use `offset` and `limit` parameters to read in chunks rather than attempting the entire file at once:

```
Read(file_path, offset=1,   limit=500)   # lines 1-500
Read(file_path, offset=501, limit=500)   # lines 501-1000
```

**Known large files** (read in <=500-line chunks):
- `DEVELOPMENT.md` (~1200 lines, ~56KB) — master specification
- `formalization/phases/PHASE_2_GROUP_ACTION_FOUNDATIONS.md` (~500 lines)
- `formalization/FORMALIZATION_PLAN.md` (~400 lines)
- `formalization/phases/PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md` (~400 lines)
- `formalization/phases/PHASE_4_CORE_THEOREMS.md` (~1140 lines)
- `formalization/phases/PHASE_5_CONCRETE_CONSTRUCTION.md` (~750 lines)
- `formalization/phases/PHASE_6_POLISH_AND_DOCUMENTATION.md` (~680 lines)

When editing large files, read the specific region around the target lines first (e.g., `offset=380, limit=40`) rather than the whole file. This avoids context-window pressure and "file too large" errors.

## Writing and editing large files

The Write tool replaces an entire file in one call. For files over ~100 lines this is error-prone: the tool call **times out**, content gets silently truncated, sections are accidentally dropped, and the context window fills up. **Prefer the Edit tool for all changes to existing files**, regardless of size.

**Hard limit — Write tool timeout prevention:**

The Write tool will time out if the inline content is too large. To avoid this:

- **Never pass more than 100 lines of content in a single Write call.** Files at or above this threshold must be built incrementally (skeleton + Edit appends) or written via Bash `cat <<'HEREDOC'` to a file.
- **For existing files, never use Write at all.** Always use Edit with targeted `old_string`/`new_string` pairs. Edit calls do not carry the full file content and therefore do not time out.
- **If a Write call times out or fails**, do not retry with the same large content. Switch to the incremental approach below.

**Rules for large-file changes:**

1. **Never rewrite a large file with Write.** Use Edit with a precise `old_string`/`new_string` pair targeting only the lines that change. This is safer, faster, and avoids timeouts.
2. **One logical change per Edit call.** If you need to change three separate sections, make three Edit calls rather than one giant replacement that spans the whole file.
3. **Read before you edit.** Always Read the specific region first (e.g., `offset=350, limit=50`) so the `old_string` matches exactly, including indentation and whitespace.
4. **Adding large new sections.** If you must insert more than ~80 new lines into an existing file, break the insertion into multiple sequential Edit calls (each <=80 lines), anchoring each one to context already present in the file.
5. **Creating new large files.** When a new file must exceed ~100 lines, build it incrementally:
   - Write an initial skeleton (imports, structure, first section) with Write, keeping the content **under 100 lines**.
   - Use successive Edit calls to append remaining sections, using the end of the previously written content as the `old_string` anchor.
   - Each Edit append should add no more than ~80 lines at a time.
   - Verify the final line count with `wc -l` via Bash.
   - **Alternative**: use Bash with a heredoc to write the full file in one shot (`cat <<'EOF' > path/to/file.lean`). Bash does not have the same content-size timeout as the Write tool.
6. **Post-write verification.** After any large write or series of edits, spot-check the result by reading the modified region (and the file's last few lines) to confirm nothing was truncated or duplicated.

## Handling large search and command output

Grep and other search tools can return oversized results. Always constrain output to avoid truncation and context-window pressure:

- **Grep**: Use `head_limit` to cap results (e.g., `head_limit=30`). If more results exist, paginate with `offset` (e.g., `offset=30, head_limit=30` for the next batch). Prefer `output_mode: "files_with_matches"` first to identify relevant files, then switch to `output_mode: "content"` on specific files.
- **Glob**: Use `path` to narrow the search directory instead of searching the entire repo. If results are numerous, combine with Grep on specific matches.
- **Bash commands** (`lake build`, etc.): Pipe through `head` or `tail` when output may be large (e.g., `lake build 2>&1 | tail -80`). For very large output, redirect to a temp file and read in chunks:
  ```bash
  lake build 2>&1 > /tmp/build.log
  ```
  Then use `Read("/tmp/build.log", offset=1, limit=500)` to page through it.

**Rule of thumb**: if a command or search might return more than ~100 lines, limit it upfront. Paginate through results rather than requesting everything at once.

## Background agent file-change protection

Background agents (launched via the Task tool with `run_in_background: true`) run concurrently and may finish after the foreground agent has already modified the same files. When this happens the background agent's stale writes silently overwrite the foreground agent's progress. **You must prevent this.**

**Rules:**

1. **Never delegate file writes to a background agent for files you may also edit.** Before launching a background agent, identify every file it might create or modify. If there is any chance the foreground agent (you) will touch the same file while the background agent runs, do **not** run that agent in the background — run it in the foreground instead, or restructure the work so there is no file overlap.
2. **Partition files strictly.** When parallel work is genuinely needed, assign each agent a disjoint set of files. Document the partition in your task prompt to the background agent (e.g., "You own `Foo.lean` and `Bar.lean` only — do not modify any other file"). The foreground agent must not touch those files until the background agent completes.
3. **Use background agents only for read-only or independent-file tasks.** Safe uses include: running builds/tests, searching the codebase, reading files for research, or writing to files that the foreground agent will never edit during this session. Unsafe uses include: editing shared source files, modifying configuration files, or any task where the output files overlap with foreground work.
4. **Check background results before acting on shared state.** When a background agent finishes, read its output and verify whether it touched any files. If it wrote to a file you have since modified, discard the background agent's version and redo that work on top of your current file state.
5. **When in doubt, run in foreground.** The performance benefit of background execution is never worth the risk of silently lost work. Prefer sequential correctness over parallel speed.

## Key conventions

- **No axiom/sorry**: forbidden in the final formalization proof surface. Zero custom axioms — the OIA (Orbit Indistinguishability Assumption) is a `Prop`-valued definition, NOT a Lean `axiom`. Theorems carry it as an explicit hypothesis (e.g., `theorem oia_implies_1cpa (hOIA : OIA scheme) : IsSecure scheme`). A universal `axiom` would introduce inconsistency by asserting OIA for trivial group actions where it is provably false. Zero `sorry` at release.
- **autoImplicit := false**: the lakefile.lean enforces this project-wide. All universe and type variables must be declared explicitly. This prevents subtle bugs from Lean auto-introducing variables.
- **Maximal Mathlib reuse**: never redefine what Mathlib already provides. Wrap and re-export where convenient, but the source of truth is Mathlib's `MulAction` framework. Import only the specific Mathlib modules needed — never `import Mathlib`.
- **Naming conventions**:
  - Theorems and lemmas: `snake_case` (Mathlib style) — e.g., `orbit_disjoint_or_eq`, `canon_encrypt`
  - Structures: `CamelCase` — e.g., `CanonicalForm`, `OrbitEncScheme`
  - Type variables: capital letters by role — `G` (groups), `X` (spaces), `M` (messages)
  - Type class instances: bracket notation — `[Group G]`, `[MulAction G X]`
  - Hypothesis names: `h`-prefixed descriptors — `hInv`, `hSep`, `hDistinct`
- **Proof style**:
  - Prefer tactic mode for non-trivial proofs
  - Use `calc` blocks for equational reasoning chains
  - Use `have` for intermediate steps with descriptive names
  - Comment proof strategy at the top of each theorem
  - Avoid `decide` on large finite types (performance trap)
- **Documentation**:
  - Every `.lean` file begins with a `/-! ... -/` module docstring (not `/-- ... -/`)
  - Every public definition and theorem has a `/-- ... -/` docstring
  - Axioms include a `-- Justification: ...` comment block
- **Import discipline**: import by full path within the project: `import Orbcrypt.GroupAction.Basic`. Re-export key definitions via the root `Orbcrypt.lean`.
- **Git practices**: one commit per completed work unit. Commit messages reference work unit numbers: `"2.5: Define CanonicalForm structure"`. All commits must pass `lake build` — never commit broken code.

## Three core theorems

The entire formalization exists to machine-check three results. Understand what they are before modifying anything:

| # | Name | Statement | File | Significance |
|---|------|-----------|------|--------------|
| 1 | **Correctness** | `decrypt(encrypt(g, m)) = some m` for all messages m and group elements g | `Theorems/Correctness.lean` | The scheme faithfully recovers encrypted messages |
| 2 | **Invariant Attack** | If a G-invariant function separates two message orbits, an adversary achieves advantage 1/2 (complete break) | `Theorems/InvariantAttack.lean` | Machine-checked proof of the critical vulnerability from COUNTEREXAMPLE.md |
| 3 | **Conditional Security** | OIA implies IND-1-CPA | `Theorems/OIAImpliesCPA.lean` | If the Orbit Indistinguishability Assumption holds, the scheme is secure against single-query chosen-plaintext attacks |
| 4 | **KEM Correctness** | `decaps(encaps(g).1) = encaps(g).2` for all group elements g | `KEM/Correctness.lean` | The KEM correctly recovers the shared secret (proof by `rfl`) |
| 5 | **KEM Security** | KEMOIA implies KEM security | `KEM/Security.lean` | If the KEM-OIA holds, no adversary can distinguish two encapsulations |
| 6 | **Probabilistic Security** | ConcreteOIA(ε) implies IND-1-CPA advantage ≤ ε | `Crypto/CompSecurity.lean` | Non-vacuous security: ConcreteOIA is satisfiable (unlike deterministic OIA) |
| 7 | **Asymptotic Security** | CompOIA implies negligible IND-1-CPA advantage | `Crypto/CompSecurity.lean` | Standard asymptotic formulation with negligible functions |
| 8 | **Bridge** | Deterministic OIA implies ConcreteOIA(0) | `Crypto/CompOIA.lean` | Backward compatibility: probabilistic framework generalizes deterministic |
| 9 | **Seed-Key Correctness** | `decaps(encaps(sampleGroup(seed, n)).1) = encaps(sampleGroup(seed, n)).2` | `KeyMgmt/SeedKey.lean` | Seed-based key expansion preserves KEM correctness |
| 10 | **Nonce Correctness** | `nonceDecaps(nonceEncaps(sk, kem, nonce).1) = nonceEncaps(sk, kem, nonce).2` | `KeyMgmt/Nonce.lean` | Nonce-based encryption preserves KEM correctness |
| 11 | **Nonce Orbit Leakage** | Cross-KEM nonce reuse leaks orbit membership | `KeyMgmt/Nonce.lean` | Formal warning: nonce misuse breaks orbit indistinguishability |

Together these establish: the scheme is correct, its failure mode is precisely characterized, and under a stated assumption it is secure. The KEM reformulation (theorems 4–5) provides the same guarantees in the modern KEM+DEM hybrid encryption paradigm. The probabilistic foundations (theorems 6–8) replace the vacuously-true deterministic security with meaningful computational security guarantees. The key management results (theorems 9–11) prove that seed-based key compression and nonce-based encryption preserve correctness while formally characterizing nonce-misuse risks.

## Mathlib integration

The formalization depends heavily on Mathlib's group action library. Familiarity with these definitions is essential:

| Mathlib Name | Type | Role in Orbcrypt |
|-------------|------|------------------|
| `MulAction.orbit G x` | `Set X` | The orbit of x under G |
| `MulAction.stabilizer G x` | `Subgroup G` | The stabilizer of x |
| `MulAction.orbitRel G X` | `Setoid X` | Orbits as equivalence classes |
| `MulAction.orbit_eq_iff` | theorem | `orbit G x = orbit G y <-> x in orbit G y` |
| `MulAction.mem_orbit_iff` | theorem | `y in orbit G x <-> exists g, g . x = y` |
| `MulAction.card_orbit_mul_card_stabilizer_eq_card_group` | theorem | Orbit-stabilizer: `|orbit| * |stab| = |G|` |
| `Equiv.Perm` | type | Permutations (symmetric group) |

**Required Mathlib modules:**
- `Mathlib.GroupTheory.GroupAction.Basic` / `Defs` — `MulAction`, `orbit`, `stabilizer`
- `Mathlib.GroupTheory.Subgroup.Basic` — `Subgroup` type for G <= S_n
- `Mathlib.GroupTheory.Perm.Basic` — `Equiv.Perm` (symmetric group S_n)
- `Mathlib.Data.Fintype.Basic` — `Fintype` for finite message spaces
- `Mathlib.Data.ZMod.Basic` — `ZMod 2` (F_2) for bitstring arithmetic
- `Mathlib.Order.BooleanAlgebra` — Boolean operations for adversary output
- `Mathlib.Probability.ProbabilityMassFunction.Basic` — `PMF` type for discrete distributions (Phase 8)
- `Mathlib.Probability.ProbabilityMassFunction.Constructions` — `PMF.map`, `PMF.ofFintype` (Phase 8)
- `Mathlib.Probability.Distributions.Uniform` — `PMF.uniformOfFintype` (Phase 8)
- `Mathlib.Analysis.SpecificLimits.Basic` — convergence lemmas for negligible functions (Phase 8)

**Version strategy:** Pin to a specific Mathlib4 commit via `lean-toolchain` and `lakefile.lean` for reproducible builds. Update Mathlib only during Phase 6 (Polish) if API breakage is discovered, and only after verifying all proofs still compile.

## Formalization roadmap

The Lean 4 formalization proceeds in nine completed phases plus planned extensions:

| Phase | Title | Weeks | Units | Effort | Document | Status |
|-------|-------|-------|-------|--------|----------|--------|
| 1 | Project Scaffolding | 1 | 4 | 4.5h | `formalization/phases/PHASE_1_PROJECT_SCAFFOLDING.md` | Complete |
| 2 | Group Action Foundations | 2-4 | 11 | 28h | `formalization/phases/PHASE_2_GROUP_ACTION_FOUNDATIONS.md` | Complete |
| 3 | Cryptographic Definitions | 5-6 | 8 | 18h | `formalization/phases/PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md` | Complete |
| 4 | Core Theorems | 7-10 | 16 | 33h | `formalization/phases/PHASE_4_CORE_THEOREMS.md` | Complete |
| 5 | Concrete Construction | 11-14 | 12 | 26h | `formalization/phases/PHASE_5_CONCRETE_CONSTRUCTION.md` | Complete |
| 6 | Polish & Documentation | 15-16 | 13 | 22.5h | `formalization/phases/PHASE_6_POLISH_AND_DOCUMENTATION.md` | Complete |
| 7 | KEM Reformulation | 17-19 | 8 | ~24h | `formalization/PRACTICAL_IMPROVEMENTS_PLAN.md` | Complete |
| 8 | Probabilistic Foundations | 18-22 | 10 | ~40h | `formalization/PRACTICAL_IMPROVEMENTS_PLAN.md` | Complete |
| 9 | Key Compression & Nonce-Based Enc | 20-22 | 7 | ~18h | `formalization/PRACTICAL_IMPROVEMENTS_PLAN.md` | Complete |
| 10–16 | Practical Improvements | 22+ | 53 | ~190h | `formalization/PRACTICAL_IMPROVEMENTS_PLAN.md` | Planned |
| | **Total (1–9)** | **22** | **89** | **~214h** | | |

**Critical path:** Chain A (Correctness) at ~32 hours of sequential work is the longest path:
```
1.1 -> 1.4 -> 2.1 -> 2.4 -> 2.5 -> 2.6 -> 3.1 -> 3.2 -> 3.3 -> 4.1 -> 4.2 -> 4.3 -> 4.4 -> 4.5
 2h     1h     3h     3h     2h     3h     3h     1h     4h    1.5h    2h    2.5h    2h     2h
```

**Key parallelism opportunity:** `Construction/Permutation.lean` (Phase 5, units 5.1-5.6) depends only on Phase 2's group action foundations. It can begin as soon as Phase 2 completes, running in parallel with Phases 3 and 4.

Read the individual phase documents for detailed implementation guidance, work unit breakdowns, risk analysis, and verification criteria before starting any phase.

## Documentation rules

When changing behavior, theorems, or formalization status, update in the same PR:
1. `DEVELOPMENT.md` — if the change affects scheme design, security analysis, or mathematical content
2. `formalization/FORMALIZATION_PLAN.md` — if the change affects module architecture, timeline, or conventions
3. The relevant phase document under `formalization/phases/` — if work unit status or guidance changes
4. `COUNTEREXAMPLE.md` — if invariant attack analysis is refined
5. `POE.md` — if the high-level concept exposition needs updating
6. `README.md` — if project status or description changes
7. `CLAUDE.md` — if development guidance, conventions, or project status changes

Canonical ownership: `DEVELOPMENT.md` owns the full scheme specification. `formalization/FORMALIZATION_PLAN.md` owns the Lean 4 architecture and conventions. Phase documents own implementation-level guidance for their respective phases. `POE.md` and `COUNTEREXAMPLE.md` own the high-level concept exposition and vulnerability analysis respectively.

## Key documents reference

| File | Size | Purpose | Read This To Understand |
|------|------|---------|------------------------|
| `DEVELOPMENT.md` | ~56KB | Master specification | Full scheme design, security proofs, hardness reductions, 7-stage pipeline |
| `POE.md` | ~6KB | Concept exposition | Core intuition behind orbit encryption, isogeny variant, unifying view |
| `COUNTEREXAMPLE.md` | ~5KB | Vulnerability analysis | Why naive constructions fail, invariant attack principle, Hamming weight break |
| `formalization/FORMALIZATION_PLAN.md` | ~17KB | Master Lean 4 roadmap | Architecture, module dependencies, Mathlib integration, timeline, conventions |
| `formalization/phases/PHASE_1_*.md` | ~8KB | Scaffolding guide | lakefile.lean setup, directory structure, .gitignore, clean build verification |
| `formalization/phases/PHASE_2_*.md` | ~20KB | Group action guide | Orbit API wrappers, canonical forms, invariant functions (11 work units) |
| `formalization/phases/PHASE_3_*.md` | ~16KB | Crypto definitions guide | AOE scheme, IND-CPA game, OIA assumption (8 work units) |
| `formalization/phases/PHASE_4_*.md` | ~40KB | Core theorems guide | Correctness proof, invariant attack proof, OIA->CPA reduction (16 work units, 4 tracks) |
| `formalization/phases/PHASE_5_*.md` | ~26KB | Construction guide | S_n bitstring action, HGOE instance, Hamming defense (12 work units) |
| `formalization/phases/PHASE_6_*.md` | ~24KB | Polish guide | sorry audit by module, docstrings, CI, Mathlib pin, final audit (13 work units) |

## Mathematical context

Understanding the cryptographic concepts is essential before modifying any formalization code:

**Core Idea:** Encryption samples from symmetry orbits in a space where orbit structure is computationally hidden. Without the symmetry, the space collapses into an indistinguishable distribution. The key restores the partition into meaningful equivalence classes.

**Key Definitions:**

| Concept | Definition |
|---------|-----------|
| **Group Action** | . : G x X -> X satisfying identity (e . x = x) and compatibility ((gh) . x = g . (h . x)) |
| **Orbit** | G . x = {g . x : g in G}, the equivalence class under the action |
| **Stabilizer** | Stab_G(x) = {g in G : g . x = x}, the subgroup fixing x |
| **Canonical Form** | can_G : X -> X with can_G(x) in G . x and can_G(x) = can_G(y) iff G . x = G . y |
| **G-Invariant** | f(g . x) = f(x) for all g in G, x in X (constant on orbits) |
| **Separating Invariant** | An invariant where f(x_m0) != f(x_m1) for distinct message representatives |
| **OIA** | Orbit samples from different message orbits are computationally indistinguishable |

**Security Model:** IND-CPA (Indistinguishability under Chosen Plaintext Attack). The scheme targets IND-1-CPA (single query) as the primary formalized result, with multi-query extension via standard hybrid argument discussed in DEVELOPMENT.md section 8.2.

**Hardness Assumptions:**
- **Graph Isomorphism (GI):** Best classical algorithm: 2^O(sqrt(n log n)) (Babai, 2015). CFI graphs provide provably hard instances for Weisfeiler-Leman hierarchy.
- **Permutation Code Equivalence (CE):** At least as hard as GI (GI <=_p CE). Believed strictly harder for specific code families.
- **Hidden Subgroup Problem:** Hard even for quantum computers — key barrier for quantum GI algorithms.

## Active development status

**Current Phase:** Phases 1–9 Complete — Key Compression & Nonce-Based Encryption Done

Phase 1 (Project Scaffolding) has been completed:
- `lakefile.lean` — Lean 4 package with Mathlib dependency pinned to commit `fa6418a8`, `autoImplicit := false`
- `lean-toolchain` — pinned to `leanprover/lean4:v4.30.0-rc1` (matching Mathlib)
- `lake-manifest.json` — locks Mathlib at commit `fa6418a8` plus 8 transitive dependencies
- 16 `.lean` files in correct directory structure (11 original + 5 KEM)
- `Orbcrypt.lean` — root import file importing all 16 submodules
- `scripts/setup_lean_env.sh` — automated Lean environment setup (elan + toolchain)
- `.claude/settings.json` — SessionStart hook for auto-setup

Phase 2 (Group Action Foundations) has been completed:
- `GroupAction/Basic.lean` — orbit/stabilizer aliases, orbit partition theorem (`orbit_disjoint_or_eq`), orbit-stabilizer wrapper, membership lemmas (`smul_mem_orbit`, `orbit_eq_of_smul`)
- `GroupAction/Canonical.lean` — `CanonicalForm` structure with `canon`, `mem_orbit`, `orbit_iff`; uniqueness lemmas (`canon_eq_implies_orbit_eq`, `orbit_eq_implies_canon_eq`, `canon_eq_of_mem_orbit`); idempotence (`canon_idem`)
- `GroupAction/Invariant.lean` — `IsGInvariant` definition with closure properties (`comp`, `const`); orbit constancy lemma (`invariant_const_on_orbit`); `IsSeparating` definition with `separating_implies_distinct_orbits`; `canonical_isGInvariant`
- All 11 work units (2.1–2.11) implemented with zero `sorry`, zero warnings
- `lake build` succeeds with exit code 0 (902 jobs, zero errors)

Phase 3 (Cryptographic Definitions) has been completed:
- `Crypto/Scheme.lean` — `OrbitEncScheme` structure with `reps`, `reps_distinct`, `canonForm`; `encrypt` function (`g • reps m`); `decrypt` function (canonical form lookup via `Exists.choose`, noncomputable)
- `Crypto/Security.lean` — `Adversary` structure with `choose` and `guess`; `hasAdvantage` predicate (∃ distinguishing group elements); `IsSecure` predicate (no adversary has advantage)
- `Crypto/OIA.lean` — `OIA` as `Prop`-valued definition (strong deterministic formulation: `∀ f m₀ m₁ g₀ g₁, f(g₀ • reps m₀) = f(g₁ • reps m₁)`); NOT an `axiom` (avoids inconsistency from trivial instantiation); comprehensive documentation covering soundness rationale, probabilistic relationship, weak-version counterexample, dependency audit, and hardness foundations
- All 8 work units (3.1–3.8) implemented with zero `sorry`, zero warnings
- `lake build` succeeds with exit code 0 (902 jobs, zero errors)

Phase 4 (Core Theorems) has been completed:
- `Theorems/Correctness.lean` — `encrypt_mem_orbit` (ciphertext in orbit), `canon_encrypt` (canonical form preserved), `decrypt_unique` (message recovery uniqueness), `correctness` (decrypt inverts encrypt). Axioms: `propext`, `Classical.choice`, `Quot.sound` (standard Lean only)
- `Theorems/InvariantAttack.lean` — `invariantAttackAdversary` construction, `invariant_on_encrypt` helper, `invariantAttackAdversary_correct` (case split proof), `invariant_attack` (separating invariant implies complete break). Axioms: `propext` only
- `Theorems/OIAImpliesCPA.lean` — `oia_specialized` (OIA instantiation), `hasAdvantage_iff` (clean unfolding), `no_advantage_from_oia` (advantage elimination), `oia_implies_1cpa` (OIA implies IND-1-CPA security). Axioms: zero (OIA is a hypothesis, not an axiom)
- Track D (contrapositive): `adversary_yields_distinguisher`, `insecure_implies_separating`
- All 16 work units (4.1–4.16) implemented with zero `sorry`, zero warnings, zero custom axioms
- `lake build` succeeds with exit code 0 (902 jobs, zero errors)

Phase 5 (Concrete Construction) has been completed:
- `Construction/Permutation.lean` — `Bitstring n` type (abbrev for `Fin n → Bool`); `MulAction (Equiv.Perm (Fin n)) (Bitstring n)` instance with `(σ • x) i = x (σ⁻¹ i)`; simp lemmas (`perm_smul_apply`, `one_perm_smul`); `perm_action_faithful` (non-identity perms move some bitstring); `hammingWeight` definition (count of true bits); `hammingWeight_invariant` (weight preserved by permutations, via `Finset.card_map`)
- `Construction/HGOE.lean` — `subgroupBitstringAction` (subgroup inherits action via `MulAction.compHom`); `hgoeScheme` (concrete `OrbitEncScheme` constructor); `hgoe_correctness` (direct application of abstract correctness); `hammingWeight_invariant_subgroup` (bridge from full S_n to subgroup); `hgoe_weight_attack` (different weights imply complete break, via `invariant_attack`); `same_weight_not_separating` (same-weight representatives defeat Hamming attack)
- All 12 work units (5.1–5.12) implemented with zero `sorry`, zero warnings, zero custom axioms
- `lake build` succeeds with exit code 0 (903 jobs, zero errors)

Phase 6 (Polish & Documentation) has been completed:
- Sorry audit: zero `sorry` across all 11 Lean source files (verified by grep)
- Module docstrings: all 11 files have `/-! ... -/` module docstrings with key definitions, results, and references
- Inline proof comments: every proof > 3 lines has a strategy comment; key `have` statements annotated
- Public definition docstrings: all 56 public `def`/`theorem`/`structure`/`instance`/`abbrev` declarations have `/-- ... -/` docstrings
- Dependency graph: module-level imports, headline theorem dependencies, and axiom dependencies documented in `Orbcrypt.lean`
- Axiom transparency report: written in `Orbcrypt.lean` — zero custom axioms, OIA is a hypothesis not an axiom
- CI configuration: `.github/workflows/lean4-build.yml` — builds on push/PR, verifies no sorry, verifies no unexpected axioms
- Mathlib pin: `lakefile.lean` pins Mathlib to commit `fa6418a815fa14843b7f0a19fe5983831c5f870e` (previously tracked `master`)
- All 13 work units (6.1–6.13) complete

Phase 7 (KEM Reformulation) has been completed:
- `KEM/Syntax.lean` — `OrbitKEM` structure with `basePoint`, `canonForm`, `keyDerive`; `OrbitEncScheme.toKEM` backward-compatibility bridge
- `KEM/Encapsulate.lean` — `encaps` (sample g, output ciphertext + key), `decaps` (re-derive key from ciphertext); simp lemmas (`encaps_fst`, `encaps_snd`, `decaps_eq`)
- `KEM/Correctness.lean` — `kem_correctness` (decaps inverts encaps, proof by `rfl`); `toKEM_correct` (bridge correctness)
- `KEM/Security.lean` — `KEMAdversary` structure; `kemHasAdvantage` (two-encapsulation distinguishability); `KEMIsSecure` predicate; `kemIsSecure_iff` (unfolding lemma); `KEMOIA` (orbit indistinguishability + key uniformity); `kem_key_constant` (from KEMOIA.2); `kem_key_constant_direct` (from `canonical_isGInvariant`, proving KEMOIA.2 is redundant); `kem_ciphertext_indistinguishable` (from KEMOIA.1); `kemoia_implies_secure` (KEMOIA implies KEM security)
- `Construction/HGOEKEM.lean` — `hgoeKEM` (concrete KEM for S_n subgroups on bitstrings); `hgoe_kem_correctness` (instantiation of abstract correctness); `hgoeScheme_toKEM` (bridge from HGOE scheme to KEM); `hgoeScheme_toKEM_correct` (bridge correctness)
- All 8 work units (7.1–7.8) implemented with zero `sorry`, zero warnings, zero custom axioms
- 22 new public declarations across 591 lines
- `lake build` succeeds for all 16 modules (zero errors)

Phase 8 (Probabilistic Foundations) has been completed:
- `Probability/Monad.lean` — `uniformPMF` (wraps `PMF.uniformOfFintype`); `probEvent` and `probTrue` (event probability under PMF); `probEvent_certain`, `probEvent_impossible`, `probTrue_le_one` (sanity lemmas)
- `Probability/Negligible.lean` — `IsNegligible` (standard crypto negligible function definition); `isNegligible_zero`, `IsNegligible.add`, `IsNegligible.mul_const` (closure properties)
- `Probability/Advantage.lean` — `advantage` (distinguishing advantage `|Pr[D=1|d₀] - Pr[D=1|d₁]|`); `advantage_nonneg`, `advantage_symm`, `advantage_self`, `advantage_le_one` (basic properties); `advantage_triangle` (triangle inequality); `hybrid_argument` (general n-hybrid argument by induction)
- `Crypto/CompOIA.lean` — `orbitDist` (orbit distribution via PMF.map); `orbitDist_support`, `orbitDist_pos_of_mem` (support characterization); `ConcreteOIA` (concrete-security OIA with explicit bound ε); `concreteOIA_zero_implies_perfect`, `concreteOIA_mono`, `concreteOIA_one` (basic lemmas); `SchemeFamily` (security-parameter-indexed families); `CompOIA` (asymptotic computational OIA); `det_oia_implies_concrete_zero` (bridge: deterministic OIA → ConcreteOIA(0))
- `Crypto/CompSecurity.lean` — `indCPAAdvantage` (probabilistic IND-1-CPA advantage); `indCPAAdvantage_eq` (unfolding lemma); `concrete_oia_implies_1cpa` (ConcreteOIA(ε) → advantage ≤ ε); `concreteOIA_one_meaningful` (ConcreteOIA(1) is trivially satisfied); `CompIsSecure` (asymptotic security); `comp_oia_implies_1cpa` (CompOIA → computational security); `MultiQueryAdversary` structure; `single_query_bound` (per-query advantage ≤ ε, building block for multi-query)
- All 10 work units (8.1–8.10) implemented with zero `sorry`, zero custom axioms
- 5 new Lean files, ~30 new public declarations
- `lake build` succeeds for all 21 modules (zero errors)

Phase 9 (Key Compression & Nonce-Based Encryption) has been completed:
- `KeyMgmt/SeedKey.lean` — `SeedKey` structure (compact seed + deterministic expansion + PRF-based sampling); `seed_kem_correctness` (seed-based KEM correctness, follows from `kem_correctness`); `HGOEKeyExpansion` (7-stage QC code key expansion specification with weight uniformity); `seed_determines_key` (equal seeds → equal key material); `seed_determines_canon` (equal seeds → equal canonical forms); `OrbitEncScheme.toSeedKey` (backward compatibility bridge); `toSeedKey_expand` and `toSeedKey_sampleGroup` (bridge preservation lemmas)
- `KeyMgmt/Nonce.lean` — `nonceEncaps` (nonce-based deterministic KEM encapsulation); `nonceDecaps` (nonce-based decapsulation); `nonce_encaps_correctness` (decaps recovers encapsulated key); `nonce_reuse_deterministic` (same nonce → same output, by `rfl`); `distinct_nonces_distinct_elements` (injective PRF → distinct group elements); `nonce_reuse_leaks_orbit` (cross-KEM nonce reuse leaks orbit membership — formal warning theorem); `nonceEncaps_mem_orbit` (ciphertext lies in base point's orbit); simp lemmas for unfolding
- All 7 work units (9.1–9.7) implemented with zero `sorry`, zero warnings, zero custom axioms
- 2 new Lean files, 19 new public declarations across 467 lines
- `lake build` succeeds for all 23 modules (zero errors)

**Formalization exit criteria (all met):**
- `lake build` succeeds with exit code 0 for all modules (23 total)
- `grep -rn "sorry" Orbcrypt/ --include="*.lean"` returns empty
- `grep -rn "^axiom " Orbcrypt/ --include="*.lean"` returns empty (OIA/KEMOIA/ConcreteOIA/CompOIA are `def`s, not `axiom`s)
- `#print axioms correctness` — no `OIA`, no `sorryAx` (standard Lean only)
- `#print axioms invariant_attack` — no `OIA`, no `sorryAx` (standard Lean only)
- `#print axioms oia_implies_1cpa` — only standard axioms (OIA is a hypothesis)
- `#print axioms kem_correctness` — standard Lean only
- `#print axioms kemoia_implies_secure` — standard Lean only (KEMOIA is a hypothesis)
- `#print axioms concrete_oia_implies_1cpa` — standard Lean only (ConcreteOIA is a hypothesis)
- `#print axioms comp_oia_implies_1cpa` — standard Lean only (CompOIA is a hypothesis)
- `#print axioms det_oia_implies_concrete_zero` — standard Lean only (OIA is a hypothesis)
- `#print axioms seed_kem_correctness` — standard Lean only (follows from kem_correctness)
- `#print axioms nonce_encaps_correctness` — standard Lean only (follows from kem_correctness)
- `#print axioms nonce_reuse_leaks_orbit` — standard Lean only (follows from orbit_eq_of_smul)
- Every `.lean` file has a module-level docstring
- Every public theorem and def has a docstring
- GitHub Actions CI passes on push
- Dependency graph and axiom transparency report documented

## Vulnerability reporting

While executing any task in this codebase, if you discover a possible software vulnerability that could reasonably warrant a CVE (Common Vulnerabilities and Exposures) designation, you **must** immediately report it to the user before continuing. This applies to vulnerabilities found in:

- **This project's cryptographic design** — logic errors in the AOE scheme definition, invariant attacks not covered by the counterexample analysis, flaws in the OIA reduction to GI or CE, or any other issue that could lead to a complete or partial break of the encryption scheme.
- **Formalization gaps** — cases where the Lean 4 formalization fails to capture a security-relevant property of the scheme, creating a false assurance gap. For example: an axiom that is too strong (making the security proof vacuously true) or a definition that does not match the mathematical intent in DEVELOPMENT.md.
- **Dependencies and toolchain** — known or suspected vulnerabilities in Lean, Lake, elan, Mathlib, or any library encountered during builds, updates, or code review.
- **Build and CI infrastructure** — insecure script patterns (e.g., command injection in shell scripts, unsafe file permissions) that could be exploited in a development or CI environment.

**What to report:**

1. **Summary** — a concise description of the vulnerability.
2. **Location** — file path(s) and line number(s) where the issue exists.
3. **Severity estimate** — your assessment of impact (Critical / High / Medium / Low) and exploitability.
4. **Reproduction or evidence** — how the issue manifests or could be triggered.
5. **Suggested remediation** — if apparent, a recommended fix or mitigation.

**How to report:**

- Stop current work and surface the finding in your response immediately.
- Do **not** silently fix a CVE-worthy vulnerability — always flag it explicitly so it can be tracked, triaged, and disclosed appropriately.
- If the vulnerability is in a third-party dependency, note whether an upstream advisory already exists.
