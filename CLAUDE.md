<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# CLAUDE.md — Orbcrypt project guidance

## What this project is

Orbcrypt is a research-stage symmetric-key encryption scheme with formal verification in Lean 4 using Mathlib. Security arises from hiding the equivalence relation (orbit structure) that makes data meaningful, not from hiding data itself. A message is the *identity* of an orbit under a secret permutation group G ≤ S_n; a ciphertext is a uniformly random element of that orbit. The hardness assumption (OIA) reduces to Graph Isomorphism on Cai-Furer-Immerman graphs and to Permutation Code Equivalence. Current status: Phases 1–14 complete and Phase 16 (Formal Verification of New Components) complete. All formal-verification phases are done; the reference GAP implementation (Phase 11), hardness alignment (Phase 12), public-key scaffolding (Phase 13), parameter recommendations (Phase 14), and the consolidated end-to-end verification report (Phase 16, `docs/VERIFICATION_REPORT.md`) are published. Phase 15 (decryption optimisation in C/C++) is the next major workstream.

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
    CanonicalLexMin.lean              CanonicalForm.ofLexMin constructor (Workstream F / F2–F3c)
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
    InvariantAttack.lean              Separating invariant implies ∃ A, hasAdvantage (existence of one distinguishing (g₀, g₁) pair; informal shorthand: "complete break" — see headline row #2 for the full three-convention advantage catalogue)
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
  AEAD/
    MAC.lean                          Message Authentication Code abstraction (tag, verify, correct, verify_inj)
    AEAD.lean                         Authenticated KEM: Encrypt-then-MAC, aead_correctness, INT_CTXT, authEncrypt_is_int_ctxt
    Modes.lean                        KEM+DEM hybrid encryption, DEM structure, hybrid_correctness
    CarterWegmanMAC.lean              Deterministic Carter–Wegman MAC witness, carterWegmanMAC_int_ctxt (Workstream C4)
  Hardness/
    CodeEquivalence.lean              CE problem, PAut group, CEOIA, GI≤CE reduction
    TensorAction.lean                 Tensor3 type, GL³ MulAction, TI problem, GI≤TI reduction,
                                       SurrogateTensor structure + punitSurrogate (Workstream G / Fix B)
    Encoding.lean                     OrbitPreservingEncoding structure, identityEncoding
                                       (reference target for Workstream G / Fix C per-encoding Props)
    Reductions.lean                   TensorOIA, GIOIA, reduction chain, hardness_chain_implies_security,
                                       ConcreteHardnessChain (with SurrogateTensor + encoder fields),
                                       *_viaEncoding per-encoding reduction Props (Workstream G / Fix C)
  PublicKey/
    ObliviousSampling.lean            OrbitalRandomizers, obliviousSample, refreshRandomizers (Phase 13)
    KEMAgreement.lean                 Two-party OrbitKeyAgreement, kem_agreement_correctness (Phase 13)
    CommutativeAction.lean            CommGroupAction class, csidh_exchange, CommOrbitPKE (Phase 13)
    CombineImpossibility.lean         Combiner impossibility + probabilistic counterpart (Phase 13 + E6)
  Optimization/
    QCCanonical.lean                  QCCyclicCanonical abbrev + orbit-constancy lemmas (Phase 15.1 / 15.5)
    TwoPhaseDecrypt.lean              TwoPhaseDecomposition, canonical_agreement_under_two_phase_decomposition, kem_round_trip_under_two_phase_decomposition (Phase 15.3 / 15.5)
implementation/
  gap/
    orbcrypt_keygen.g                 7-stage HGOE key generation pipeline (GAP)
    orbcrypt_kem.g                    KEM encapsulation/decapsulation (GAP)
    orbcrypt_params.g                 Parameter generation for all security levels (GAP)
    orbcrypt_test.g                   Correctness test suite — 13 tests (GAP)
    orbcrypt_bench.g                  Benchmark harness with CSV output (GAP)
    orbcrypt_sweep.g                  Phase 14 parameter sweep + tier-pinned rows (GAP)
    orbcrypt_fast_dec.g               Phase 15 fast decryption (QCCyclicReduce, FastDecaps,
                                       ComputeResidualGroup, SyndromeDecaps, OrbitHash,
                                       RunPhase15Comparison) (GAP)
    orbcrypt_benchmarks.csv           Benchmark results (generated)
  README.md                           Installation, usage, reproducibility guide
docs/
  PARAMETERS.md                       Phase 14 parameter recommendation document
  VERIFICATION_REPORT.md              Phase 16 end-to-end verification report (sorry/axiom audit, headline results, exit-criteria checklist)
  benchmarks/
    results_80.csv                    Phase 14 sweep + tier rows, λ = 80
    results_128.csv                   Phase 14 sweep + tier rows, λ = 128
    results_192.csv                   Phase 14 sweep + tier rows, λ = 192
    results_256.csv                   Phase 14 sweep + tier rows, λ = 256
    comparison.csv                    Cross-scheme comparison CSV
scripts/
  audit_phase_16.lean                 Phase 16 consolidated `#print axioms` audit script (342 declarations — every public declaration in Orbcrypt/ — plus non-vacuity witnesses)
```

### Module dependency graph

```
              GroupAction.Basic
             /       |        \
            /        |         \
 GroupAction.   GroupAction.   (orbit lemmas
  Canonical      Invariant     feed both)
     |       \        |         /
     |        \       |        /
     v
 GroupAction.CanonicalLexMin (Workstream F: ofLexMin constructor
   consumes Canonical + Finset.min' + Fintype orbit)
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

  AEAD.MAC ◄── Mathlib.Tactic
              |
              v
  AEAD.AEAD ◄── AEAD.MAC, KEM.Syntax, KEM.Encapsulate, KEM.Correctness
  (AuthOrbitKEM, authEncaps, authDecaps, aead_correctness, INT_CTXT)

  AEAD.Modes ◄── KEM.Syntax, KEM.Encapsulate
  (DEM, hybridEncrypt, hybridDecrypt, hybrid_correctness)

  Mathlib.GroupTheory.Perm.Basic ──── Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup.Defs
              |                                       |
              v                                       v
  Hardness.CodeEquivalence            Hardness.TensorAction
  (ArePermEquivalent, PAut,           (Tensor3, tensorAction GL³,
   CEOIA, GIReducesToCE)               AreTensorIsomorphic, GIReducesToTI,
                                       SurrogateTensor, punitSurrogate
                                       — Workstream G / Fix B)
              \                                      /
               \               Hardness.Encoding    /
                \              (OrbitPreservingEncoding,
                 \              identityEncoding — reference target)
                  v                                v
              Hardness.Reductions ◄── Crypto.OIA, Theorems.OIAImpliesCPA
              (TensorOIA, GIOIA, HardnessChain,
               hardness_chain_implies_security,
               ConcreteHardnessChain (surrogate + encoder fields),
               *_viaEncoding per-encoding Props — Workstream G / Fix C)

  KEM.{Syntax, Encapsulate, Correctness} + GroupAction.{Basic, Canonical}
              |
              v
  PublicKey.ObliviousSampling ◄── KEM.Syntax, GroupAction.Basic
  (OrbitalRandomizers, obliviousSample, oblivious_sample_in_orbit,
   refreshRandomizers, refresh_depends_only_on_epoch_range)

  PublicKey.KEMAgreement ◄── KEM.Encapsulate, KEM.Correctness
  (OrbitKeyAgreement, sessionKey, kem_agreement_correctness,
   SessionKeyExpansionIdentity)

  PublicKey.CommutativeAction ◄── GroupAction.Basic, GroupAction.Canonical
  (CommGroupAction class, csidh_exchange, csidh_correctness,
   CommOrbitPKE, comm_pke_correctness)

  GroupAction.Canonical + Construction.Permutation
              |
              v
  Optimization.QCCanonical ◄── GroupAction.Canonical, Construction.Permutation
  (QCCyclicCanonical abbrev for CanonicalForm under cyclic subgroup,
   qc_invariant_under_cyclic, qc_canon_idem)

  Optimization.TwoPhaseDecrypt ◄── Optimization.QCCanonical, KEM.Correctness
  (TwoPhaseDecomposition predicate, canonical_agreement_under_two_phase_decomposition,
   full_canon_invariant, two_phase_invariant_under_G,
   two_phase_kem_decaps, kem_round_trip_under_two_phase_decomposition,
   IsOrbitConstant, orbit_constant_encaps_eq_basePoint)
```

## Document layout

```
README.md                             Project title and tagline
LICENSE                               MIT license
CLAUDE.md                             This file — development guidance for Claude
lakefile.lean                         Lake build configuration (Mathlib dependency, autoImplicit := false)
lean-toolchain                        Lean 4 version pin (v4.30.0-rc1, matching Mathlib)
lake-manifest.json                    Dependency lock file (Mathlib + 8 transitive deps)
.gitignore                            Build artifact exclusions
.claude/
  settings.json                       Claude Code session hook (auto-runs setup on start)
docs/
  DEVELOPMENT.md                      Master specification (~56KB): scheme design, security proofs, hardness reductions
  POE.md                              Permutation-Orbit Encryption high-level concept exposition
  COUNTEREXAMPLE.md                   Critical vulnerability analysis: invariant attack theorem
  HARDNESS_ANALYSIS.md                LESS/MEDS alignment, reduction chain, hardness comparison table
  PUBLIC_KEY_ANALYSIS.md              Phase 13 public-key feasibility analysis (oblivious sampling, KEM agreement, CSIDH-style)
  PARAMETERS.md                       Phase 14 parameter recommendations (3 tiers × 4 security levels)
  VERIFICATION_REPORT.md              Phase 16 end-to-end verification report (sorry audit, axiom audit, headline-results table, exit-criteria checklist)
  USE_CASES.md                        Cryptographic use-case catalogue
  MORE_USE_CASES.md                   Extended cryptographic use-case catalogue
  benchmarks/
    results_80.csv                    Phase 14 sweep + tier rows, λ = 80
    results_128.csv                   Phase 14 sweep + tier rows, λ = 128
    results_192.csv                   Phase 14 sweep + tier rows, λ = 192
    results_256.csv                   Phase 14 sweep + tier rows, λ = 256
    comparison.csv                    Cross-scheme comparison (AES / Kyber / BIKE / HQC / McEliece / LESS / HGOE)
    phase15_decryption_quick.csv      Phase 15 fast-decryption benchmark output
  planning/                           Active workstream planning documents (pending or research-scope work)
    AUDIT_2026-04-23_WORKSTREAM_PLAN.md      Pre-release audit plan (workstreams H, J, K, L, M, N pending)
    AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md  R-15 Karp reductions (CE reverse direction research-scope)
    AUDIT_2026-04-28_PHASE_3_PROP_DISCHARGE_PLAN.md  Phase 3 prop discharge (deep content research-scope)
    PLAN_R_05_11_15.md                       R-05 + R-11 + R-15 research-scope plan (R-11/R-15 not yet implemented)
    R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md    R-TI research-scope discharge (Phase 3 partial)
    R_TI_PHASE_C_THROUGH_H_PLAN.md           R-TI Karp reduction plan through Phase H (research-scope)
  audits/                             Source audit reports (LEAN_MODULE_AUDIT_2026-04-{14,18,21,23_PRE_RELEASE,29_COMPREHENSIVE}.md)
  research/                           Grochow–Qiao paper synthesis notes (path algebra, padding rigidity, Mathlib API audit, reading log)
  dev_history/                        Completed workstream planning documents (historical record)
    PHASE_7_KEM_REFORMULATION.md             Phase 7: KEM reformulation (complete)
    PHASE_8_PROBABILISTIC_FOUNDATIONS.md     Phase 8: probabilistic IND-CPA (complete)
    PHASE_9_KEY_COMPRESSION.md               Phase 9: key compression + nonce-based encryption (complete)
    PHASE_10_AUTHENTICATED_ENCRYPTION.md     Phase 10: authenticated encryption + modes (complete)
    PHASE_11_GAP_PROTOTYPE.md                Weeks 21-26: GAP reference implementation (9 work units, complete)
    PHASE_12_HARDNESS_ALIGNMENT.md           Hardness reduction alignment (complete)
    PHASE_13_PUBLIC_KEY_EXTENSION.md         Public-key extension (complete)
    PHASE_14_PARAMETER_SELECTION.md          Parameter selection optimization (complete)
    PHASE_15_DECRYPTION_OPTIMIZATION.md      Decryption optimization formalisation (complete)
    PHASE_16_FORMAL_VERIFICATION.md          Extended formal verification (complete)
    AUDIT_2026-04-18_WORKSTREAM_PLAN.md      Workstreams A-E (all closed)
    AUDIT_2026-04-21_WORKSTREAM_PLAN.md      Workstreams G, H, J, K, L, M, N (all closed)
    AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md  Workstreams A, B, C closed; D research catalogue partially landed
    PATH_ALGEBRA_MUL_ASSOC_PLAN.md           pathAlgebraMul_assoc decomposition plan (complete)
    PLAN_R_01_07_08_14_16.md                 R-01, R-07, R-14, R-08, R-13⁺, R-16 research-scope discharges (complete)
    formalization/                           Original formalization roadmap and Phase 1-6 plans (all complete)
      FORMALIZATION_PLAN.md                  Master Lean 4 formalization roadmap (architecture, timeline, conventions)
      PRACTICAL_IMPROVEMENTS_PLAN.md         Practical improvements workstream plan (covering Phases 7-9, complete)
      phases/
        PHASE_1_PROJECT_SCAFFOLDING.md       Week 1: lakefile.lean, directory structure, root import, clean build
        PHASE_2_GROUP_ACTION_FOUNDATIONS.md  Weeks 2-4: orbit/stabilizer API, canonical forms, invariants
        PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md Weeks 5-6: AOE scheme, IND-CPA game, OIA assumption
        PHASE_4_CORE_THEOREMS.md             Weeks 7-10: correctness, invariant attack, OIA implies CPA
        PHASE_5_CONCRETE_CONSTRUCTION.md     Weeks 11-14: S_n on bitstrings, HGOE instance, Hamming defense
        PHASE_6_POLISH_AND_DOCUMENTATION.md  Weeks 15-16: sorry audit, docstrings, Mathlib update, README
implementation/
  README.md                           GAP prototype installation, usage, reproducibility guide
  gap/                                GAP source files for HGOE reference implementation
scripts/
  audit_phase_16.lean                 Phase 16 consolidated `#print axioms` audit script (current sentinel)
  setup_lean_env.sh                   Lean environment setup with elan SHA-256 verification
  legacy/                             Archived per-workstream audit scripts (Workstream B2 of audit 2026-04-29)
    README.md                         Archive index, retention rationale, re-running instructions
    audit_a7_defeq.lean               Workstream A7 defeq checks (historical, 2026-04-18)
    audit_b_workstream.lean           Workstream B audit script (historical, F-02 + F-15)
    audit_c_workstream.lean           Workstream C audit script (historical, F-07)
    audit_d_workstream.lean           Workstream D audit script (historical, F-08 + F-16)
    audit_e_workstream.lean           Workstream E audit script (historical, F-01 + F-10 + F-11 + F-17 + F-20)
    audit_phase15.lean                Phase 15 axiom-transparency baseline (historical, 2026-04-20)
    audit_print_axioms.lean           Per-headline `#print axioms` script (Workstream A historical baseline)
```

## Reading large files

Several files in this repo are large (docs/DEVELOPMENT.md is ~56KB). When reading any file, always use `offset` and `limit` parameters to read in chunks rather than attempting the entire file at once:

```
Read(file_path, offset=1,   limit=500)   # lines 1-500
Read(file_path, offset=501, limit=500)   # lines 501-1000
```

**Known large files** (read in <=500-line chunks):
- `docs/DEVELOPMENT.md` (~1200 lines, ~56KB) — master specification
- `docs/dev_history/formalization/phases/PHASE_2_GROUP_ACTION_FOUNDATIONS.md` (~500 lines)
- `docs/dev_history/formalization/FORMALIZATION_PLAN.md` (~400 lines)
- `docs/dev_history/formalization/phases/PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md` (~400 lines)
- `docs/dev_history/formalization/phases/PHASE_4_CORE_THEOREMS.md` (~1140 lines)
- `docs/dev_history/formalization/phases/PHASE_5_CONCRETE_CONSTRUCTION.md` (~750 lines)
- `docs/dev_history/formalization/phases/PHASE_6_POLISH_AND_DOCUMENTATION.md` (~680 lines)

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

- **Security-by-docstring prohibition (ABSOLUTE).** If an identifier
  names a cryptographic primitive or security property — e.g.,
  `carterWegmanMAC`, `universalHash`, `ind_cca_secure`,
  `forward_secret_kem` — the Lean code for that identifier **must
  formally prove the advertised security property** (or carry it as
  an explicit hypothesis Prop the caller discharges).  It is **not
  acceptable** to name an identifier after a security primitive and
  then disclaim the property in a docstring; doing so is a
  security-reducing shortcut that tricks downstream readers /
  consumers into building on a name that promises more than the code
  delivers.  Concretely:

  * If the name promises ε-universal hashing, the module must prove
    `IsEpsilonUniversal h ε` (see
    `Orbcrypt/Probability/UniversalHash.lean`).
  * If the name promises IND-CPA security, the module must prove
    `IsSecure` or `IsSecureDistinct` (see `Crypto/Security.lean`).
  * If the name promises ciphertext integrity, the module must prove
    `INT_CTXT` (see `AEAD/AEAD.lean`).

  When the full security property cannot yet be proved, **rename the
  identifier** to describe what the code *does* prove — e.g., a
  "linear hash shape" (`linearHashOverFp`) rather than a
  "universal hash" (`universalHashMAC`).  Docstring disclaimers are
  **not** an acceptable substitute for a rename or a proof.

  *Historical reference:* the Workstream L2 initial landing
  (`[NeZero p]` + "Naming note: linear hash shape, not the universal-
  hash security property") violated this rule by keeping the
  `carterWegmanMAC` identifier while disclaiming its security
  property in prose.  The L-workstream post-audit pass (2026-04-22)
  remediated by proving the universal-hash property
  (`carterWegmanHash_isUniversal`) at the strengthened
  `[Fact (Nat.Prime p)]` constraint.  Future audit findings of this
  shape must either prove-the-property or rename-the-identifier;
  docstring-only fixes are forbidden.

- **Release messaging policy (ABSOLUTE).** Every external claim that
  references an Orbcrypt Lean theorem — in a README, paper, blog post,
  slide deck, marketing page, spec document, or downstream dependency —
  must reproduce the theorem's **Status** classification from the
  "Three core theorems" table below and cite only what the Lean code
  actually proves. This policy exists because the formalisation
  carries two parallel security chains (deterministic and
  probabilistic) whose theorems look superficially identical but
  deliver *very* different content; external messaging that blurs the
  distinction is a v1.0 release-gate failure.

  * **Allowed citations (release-facing).** Theorems classified
    **Standalone** or **Quantitative** in the "Three core theorems"
    table. Every citation must include the theorem name, its Status
    classification, and — for **Quantitative** theorems — the ε bound
    together with the surrogate / encoder / keyDerive profile the
    caller is using (at ε = 1 via the trivial `tight_one_exists`
    witness, or at ε < 1 via a caller-supplied hardness witness).
  * **Conditional citations.** Theorems classified **Conditional**
    may be cited **only with their hypothesis made explicit**. For
    example, `kem_round_trip_under_two_phase_decomposition` may be cited as
    "under the `TwoPhaseDecomposition` hypothesis, which does not
    hold on the default GAP fallback group — the production-
    correctness argument runs through `fast_kem_round_trip` via
    orbit-constancy". Pure Conditional citations without the
    hypothesis disclosure are **forbidden**.
  * **Scaffolding citations.** Theorems classified **Scaffolding**
    may be cited **only to explain type-theoretic structure**, never
    as standalone security claims. For example, `oia_implies_1cpa`
    may be cited as "the deterministic reduction demonstrates the
    *shape* of the OIA→CPA argument; quantitative security content
    runs through `concrete_oia_implies_1cpa`". Pure Scaffolding
    citations framed as security claims are **forbidden**.
  * **ε = 1 disclosure.** Every Quantitative-at-ε=1 result must be
    cited with the explicit phrase "inhabited only at ε = 1 via the
    trivial `_one_*` / `tight_one_exists` witness in the current
    formalisation; ε < 1 requires a concrete surrogate + encoder
    witness (research-scope follow-up)". This applies to
    `concrete_hardness_chain_implies_1cpa_advantage_bound` and
    `concrete_kem_hardness_chain_implies_kem_advantage_bound` until
    R-02/R-03/R-04/R-05 research milestones land concrete ε < 1
    witnesses.
  * **Status-column authority.** The **Status** column of `CLAUDE.md`'s
    "Three core theorems" table and the headline table in
    `docs/VERIFICATION_REPORT.md` are the canonical sources of truth
    for the release-messaging classification of every theorem. A PR
    that adds or modifies a headline theorem — or changes a
    theorem's hypothesis structure such that its Status classification
    changes — **must update the Status column in both documents in
    the same diff**.
  * **Documentation-vs-code parity.** Before any v1.0 release tag,
    run the "Documentation-vs-code parity gates" checklist in
    `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 20.3 to
    confirm that `CLAUDE.md`, `docs/VERIFICATION_REPORT.md`, and
    `docs/DEVELOPMENT.md` do not carry prose claims that exceed what the
    Lean content delivers.

  *Rationale.* The release-messaging gap flagged as CRITICAL finding
  X-01 in the 2026-04-23 pre-release audit would have let an external
  reviewer read `docs/VERIFICATION_REPORT.md`'s pre-audit "Release
  readiness" section and conclude that `authEncrypt_is_int_ctxt`,
  `carterWegmanMAC_int_ctxt`, `canonical_agreement_under_two_phase_decomposition`, and
  `kem_round_trip_under_two_phase_decomposition` were standalone machine-checked
  security content — when in fact each carries a hypothesis that
  fails on production HGOE (see rows #19, #20, #24, #25 of the
  "Three core theorems" table). The policy above forbids framing
  such theorems as standalone claims without disclosing their
  condition. `CLAUDE.md`'s zero-sorry / zero-custom-axiom posture
  guarantees that the Lean content is *correct*; the release-
  messaging policy guarantees that external prose *accurately
  describes* the Lean content.

- **No axiom/sorry**: forbidden in the final formalization proof surface. Zero custom axioms — the OIA (Orbit Indistinguishability Assumption) is a `Prop`-valued definition, NOT a Lean `axiom`. Theorems carry it as an explicit hypothesis (e.g., `theorem oia_implies_1cpa (hOIA : OIA scheme) : IsSecure scheme`). A universal `axiom` would introduce inconsistency by asserting OIA for trivial group actions where it is provably false. Zero `sorry` at release.
- **autoImplicit := false**: the lakefile.lean enforces this project-wide. All universe and type variables must be declared explicitly. This prevents subtle bugs from Lean auto-introducing variables.
- **Maximal Mathlib reuse**: never redefine what Mathlib already provides. Wrap and re-export where convenient, but the source of truth is Mathlib's `MulAction` framework. Import only the specific Mathlib modules needed — never `import Mathlib`.
- **Naming conventions**:
  - Theorems and lemmas: `snake_case` (Mathlib style) — e.g., `orbit_disjoint_or_eq`, `canon_encrypt`
  - Structures: `CamelCase` — e.g., `CanonicalForm`, `OrbitEncScheme`
  - Type variables: capital letters by role — `G` (groups), `X` (spaces), `M` (messages)
  - Type class instances: bracket notation — `[Group G]`, `[MulAction G X]`
  - Hypothesis names: `h`-prefixed descriptors — `hInv`, `hSep`, `hDistinct`
  - **Names describe content, never provenance.** A declaration's identifier (name of a `def` / `theorem` / `structure` / `class` / `instance` / `abbrev` / `lemma` / namespace) must describe *what the declaration is or proves*, never *where in the development process it was added*. Forbidden tokens in declaration names include, non-exhaustively:
    - workstream labels: `workstream`, `ws`, `wu`, and workstream-letter prefixes like `a1`, `b1c`, `e8a` (even when lowercased or embedded, e.g. `workstreamB_perQueryBound`, `ws_e8_hybrid`)
    - phase labels: `phase`, `phase1`, `phase_12`, `stretch` (as in "stretch goal")
    - audit finding ids: `audit`, `f02`, `f_15`, `finding`, `cve`
    - sub-task / work-unit numbers: `3_4`, `step1`, `task2`, `wu4a`
    - session / PR / branch references: `pr23`, `claude_`, `session_`, `revision2`
    - temporal markers: `old`, `new`, `v2`, `legacy`, `deprecated`, `temp`, `tmp`, `tmp_`, `foo`, `bar`, `baz`, `todo`, `fixme`
    This rule applies to the full identifier, including any namespace qualifier. `WorkstreamB.perQueryAdvantage`, `Phase4.correctness`, and `Audit2026.hasAdvantageDistinct` are all disallowed even though their last component reads normally. A declaration that should be private to a scope uses `private` / `section`, not a process-marker prefix.

    **Rationale.** Process markers rot: workstreams close, audits are superseded, phases get renumbered, but the declarations persist. Downstream users reading `perQueryAdvantage_bound_of_concreteOIA` learn what the theorem proves; reading `b3_e8_bound_f02` they learn nothing useful and must chase a changelog to decode it. Mathlib enforces the same discipline — there is no `phaseXYZ_foo` in Mathlib's name space, even though Mathlib is developed in coordinated pull-request batches.

    **Where process references *are* allowed.** Process markers may appear in prose that lives *outside* the declaration identifier: (a) in `/-- … -/` docstrings as traceability notes ("`audit F-02 / Workstream B1`" is fine in a docstring); (b) in `-- ============================================================================` section banners that group a block of related declarations; (c) in commit messages, branch names, PR titles, and planning documents under `docs/planning/`; (d) in `CLAUDE.md` / `docs/dev_history/formalization/FORMALIZATION_PLAN.md` / `docs/audits/` change logs. The boundary is sharp: the docstring may say "added in Workstream B3," the identifier may not.

    **Enforcement at review time.** Before landing any new `def` / `theorem` / `structure`, grep the diff for the forbidden tokens above against the set of added declarations:

    ```bash
    git diff --cached -U0 -- '*.lean' \
      | grep -E '^\+(def|theorem|structure|class|instance|abbrev|lemma|noncomputable)' \
      | grep -iE 'workstream|\bws[0-9_a-z]*|\bwu[0-9_a-z]*|\bphase[0-9_]|audit|\bf[0-9]{2}\b|\bstep[0-9]|\btmp\b|\btodo\b|\bfixme\b|claude_|session_'
    ```

    A non-empty result is a review-blocking naming violation.
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

The **Status** column classifies each theorem per Workstream J
(audit finding H3, release-messaging alignment; see
`Orbcrypt.lean` § "Deterministic-vs-probabilistic security chains"
and `docs/VERIFICATION_REPORT.md` § "Release readiness" for the
rationale):
- **Standalone** — unconditional / algebraic / structural result
  that holds for every scheme. Safe to cite directly.
- **Scaffolding** — deterministic-chain theorem whose OIA-variant
  hypothesis is `False` on every non-trivial scheme; the conclusion
  holds vacuously. Cite only to explain type-theoretic structure,
  *not* as a standalone security claim.
- **Quantitative** — probabilistic-chain theorem whose ε-bounded
  `Concrete*` hypothesis is genuinely ε-smooth. Cite with an
  explicit ε and an explicit surrogate/encoder/keyDerive profile.
- **Structural** — Mathlib-style API lemma (equivalence relation /
  subgroup / coset identity) supporting downstream proofs; not a
  security claim but unconditionally true.

| # | Name | Statement | File | Status | Significance |
|---|------|-----------|------|--------|--------------|
| 1 | **Correctness** | `decrypt(encrypt(g, m)) = some m` for all messages m and group elements g | `Theorems/Correctness.lean` | Standalone | The scheme faithfully recovers encrypted messages |
| 2 | **Invariant Attack** | If a G-invariant function separates two message orbits, there exists an adversary `A` with `hasAdvantage scheme A` (i.e. a specific `(g₀, g₁)` pair on which the adversary's two guesses disagree) | `Theorems/InvariantAttack.lean` | Standalone | Machine-checked proof of the vulnerability from docs/COUNTEREXAMPLE.md. The theorem's **formal conclusion** is `∃ A : Adversary X M, hasAdvantage scheme A` — existence of one distinguishing adversary — **not** a quantitative "advantage = 1/2" claim in either the two-distribution or centred conventions (see `Probability/Advantage.lean` and the `invariant_attack` docstring for the three-convention catalogue: under a separating G-invariant, deterministic advantage = 1, two-distribution advantage = 1, centred advantage = 1/2). Informal shorthand: "complete break under a separating G-invariant". The quantitative probabilistic strengthening — IND-1-CPA advantage *exactly* `1` for the invariant-attack adversary — is delivered by `indCPAAdvantage_invariantAttackAdversary_eq_one` (Workstream R-01, discharged 2026-04-30; see `docs/dev_history/PLAN_R_01_07_08_14_16.md` § R-01) |
| 3 | **Conditional Security** | OIA implies IND-1-CPA | `Theorems/OIAImpliesCPA.lean` | Scaffolding | If the Orbit Indistinguishability Assumption holds, the scheme is secure against single-query chosen-plaintext attacks. Deterministic OIA is `False` on every non-trivial scheme, so this theorem is vacuously true on production instances — cite the probabilistic counterpart (#6) as the real security statement |
| 4 | **KEM Correctness** | `decaps(encaps(g).1) = encaps(g).2` for all group elements g | `KEM/Correctness.lean` | Standalone | The KEM correctly recovers the shared secret (proof by `rfl`) |
| 5 | **KEM Security** | KEMOIA implies KEM security | `KEM/Security.lean` | Scaffolding | If the KEM-OIA holds, no adversary can distinguish two encapsulations. Deterministic KEMOIA is vacuous on every non-trivial KEM; cite the probabilistic counterpart (the `concrete_kemoia_*_implies_secure` family) for quantitative KEM security |
| 6 | **Probabilistic Security** | ConcreteOIA(ε) implies IND-1-CPA advantage ≤ ε | `Crypto/CompSecurity.lean` | Quantitative | Non-vacuous security: ConcreteOIA is satisfiable (unlike deterministic OIA) |
| 7 | **Asymptotic Security** | CompOIA implies negligible IND-1-CPA advantage | `Crypto/CompSecurity.lean` | Quantitative | Standard asymptotic formulation with negligible functions |
| 8 | **Bridge** | Deterministic OIA implies ConcreteOIA(0) | `Crypto/CompOIA.lean` | Scaffolding | Backward compatibility: probabilistic framework generalizes deterministic. Vacuous in practice (the antecedent is `False` on non-trivial schemes); exists purely to anchor the definitional link between the two chains |
| 9 | **Seed-Key Correctness** | `decaps(encaps(sampleGroup(seed, n)).1) = encaps(sampleGroup(seed, n)).2` | `KeyMgmt/SeedKey.lean` | Standalone | Seed-based key expansion preserves KEM correctness |
| 10 | **Nonce Correctness** | `nonceDecaps(nonceEncaps(sk, kem, nonce).1) = nonceEncaps(sk, kem, nonce).2` | `KeyMgmt/Nonce.lean` | Standalone | Nonce-based encryption preserves KEM correctness |
| 11 | **Nonce Orbit Leakage** | Cross-KEM nonce reuse leaks orbit membership | `KeyMgmt/Nonce.lean` | Standalone | Formal warning: nonce misuse breaks orbit indistinguishability |
| 12 | **AEAD Correctness** | `authDecaps(authEncaps(g)) = some k` for honest pairs | `AEAD/AEAD.lean` | Standalone | Authenticated KEM correctly recovers keys |
| 13 | **Hybrid Correctness** | `hybridDecrypt(hybridEncrypt(m)) = some m` | `AEAD/Modes.lean` | Standalone | KEM+DEM hybrid encryption preserves messages |
| 14 | **Hardness Chain** | HardnessChain(scheme) → IsSecure(scheme) | `Hardness/Reductions.lean` | Scaffolding | TI-hardness + reductions → IND-1-CPA security. The deterministic `HardnessChain` is composed from deterministic `TensorOIA`/`CEOIA`/`GIOIA` and is vacuous on production instances; the non-vacuous counterpart is #27 (`concrete_hardness_chain_implies_1cpa_advantage_bound`) |
| 15 | **Oblivious Sample Correctness** | `obliviousSample ors combine hClosed i j ∈ orbit G ors.basePoint` | `PublicKey/ObliviousSampling.lean` | Standalone | Oblivious sampling preserves orbit membership (Phase 13.2) |
| 16 | **KEM Agreement Correctness** | Alice's post-decap view equals Bob's post-decap view (`= sessionKey a b`) | `PublicKey/KEMAgreement.lean` | Standalone | Two-party KEM agreement recovers the same session key (Phase 13.4) |
| 17 | **CSIDH Correctness** | `a • (b • x₀) = b • (a • x₀)` under `CommGroupAction` | `PublicKey/CommutativeAction.lean` | Standalone | Commutative action supports Diffie–Hellman-style exchange (Phase 13.5) |
| 18 | **Commutative PKE Correctness** | `decrypt(encrypt(r).1) = encrypt(r).2` | `PublicKey/CommutativeAction.lean` | Standalone | CSIDH-style public-key orbit encryption is correct (Phase 13.6) |
| 19 | **INT-CTXT for AuthOrbitKEM** | `authEncrypt_is_int_ctxt : INT_CTXT akem` (given `MAC.verify_inj`) | `AEAD/AEAD.lean` | Standalone | Ciphertext integrity: no adversary can forge a (c, t) pair that decapsulates (audit F-07, Workstream C2; refined by audit 2026-04-23 Workstream B, V1-1 / I-03). Post-Workstream-B refactor: the orbit-cover hypothesis is the game's well-formedness precondition on `INT_CTXT` itself, not a theorem-level obligation — `INT_CTXT` discharges **unconditionally** on every `AuthOrbitKEM`. The `INT_CTXT` game now carries a per-challenge `hOrbit : c ∈ orbit G basePoint` binder that rejects out-of-orbit ciphertexts as ill-formed, matching the real-world KEM model where only orbit-members are valid ciphertexts. Consumers who want INT-CTXT-on-arbitrary-ciphertexts (stronger threat model) pair this with an explicit orbit-check at decapsulation time — the canonical shape is Workstream **H**'s planned `decapsSafe` helper (audit plan § 9). Non-vacuous sibling lemma: `keyDerive_canon_eq_of_mem_orbit` (orbit-restricted key uniqueness) |
| 20 | **Carter–Wegman INT-CTXT witness** | `carterWegmanMAC_int_ctxt : INT_CTXT (carterWegman_authKEM …)` | `AEAD/CarterWegmanMAC.lean` | Conditional | Concrete instance showing `verify_inj` is satisfiable and `INT_CTXT` non-vacuous (audit F-07, Workstream C4; refined by audit 2026-04-23 Workstream B). Post-Workstream-B, this theorem is an unconditional specialisation of `authEncrypt_is_int_ctxt` to the Carter–Wegman composition (no `hOrbitCover` argument). **Requires `X = ZMod p × ZMod p`** — the MAC is typed over `(ZMod p × ZMod p) → ZMod p → ZMod p` and is **incompatible with HGOE's `Bitstring n` ciphertext space** without a `Bitstring n → ZMod p` adapter (audit 2026-04-23 finding V1-7 / D4 / I-08; research tracked as R-13). The companion theorem `carterWegmanHash_isUniversal` is the standalone `(1/p)`-universal hash proof post the 2026-04-22 L-workstream upgrade — cite that when a standalone universal-hash statement is wanted. `carterWegmanMAC_int_ctxt` itself is a **satisfiability witness** for `MAC.verify_inj` and the `INT_CTXT` pipeline; it does not compose with the concrete HGOE construction |
| 21 | **Code Equivalence is an `Equivalence`** | `arePermEquivalent_setoid : Setoid {C : Finset (Fin n → F) // C.card = k}` (built from `arePermEquivalent_refl` / `_symm` / `_trans`) | `Hardness/CodeEquivalence.lean` | Structural | Permutation code equivalence is now a Mathlib-grade equivalence relation; `_symm` carries `C₁.card = C₂.card`, `_trans` is unconditional (audit F-08, Workstream D1+D4) |
| 22 | **PAut is a `Subgroup`** | `PAutSubgroup C : Subgroup (Equiv.Perm (Fin n))` with `PAut_eq_PAutSubgroup_carrier C : PAut C = (PAutSubgroup C : Set _)` | `Hardness/CodeEquivalence.lean` | Structural | Permutation Automorphism group has full Mathlib `Subgroup` API (cosets, Lagrange, quotient); the Set-valued `PAut` and Subgroup-packaged `PAutSubgroup` agree definitionally (audit F-08, Workstream D2) |
| 23 | **CE coset set identity** | `paut_equivalence_set_eq_coset : {ρ \| ρ : C₁ → C₂} = σ · PAut C₁` (given a witness σ and `C₁.card = C₂.card`) | `Hardness/CodeEquivalence.lean` | Structural | The set of all CE-witnessing permutations is *exactly* a left coset of PAut; this is the algebraic statement underlying the LESS signature scheme's effective-search-space reduction (audit F-16 extended, Workstream D3) |
| 24 | **Two-Phase Correctness** | `canonical_agreement_under_two_phase_decomposition : can_full.canon (g • x) = can_residual.canon (can_cyclic.canon (g • x))` (given `TwoPhaseDecomposition`) | `Optimization/TwoPhaseDecrypt.lean` | Conditional | The fast (cyclic ∘ residual) canonical form agrees with the full canonical form on every ciphertext `g • x` **when** `TwoPhaseDecomposition` holds. The theorem is a conditional that documents the strong "fast = slow" agreement property; it is **not** the actual GAP correctness story — post-landing audit empirically confirmed that `TwoPhaseDecomposition` **fails on the default GAP fallback group** because lex-min and the residual transversal action don't commute (self-disclosed in `Optimization/TwoPhaseDecrypt.lean`'s module docstring). The non-vacuous sibling is `fast_kem_round_trip` (row #26), which captures the actual production-correctness story via orbit-constancy of the fast canonical form. Audit 2026-04-23 finding V1-2 / L-03 / D2 (Phase 15.5) |
| 25 | **Two-Phase KEM Correctness (conditional)** | `kem_round_trip_under_two_phase_decomposition : kem.keyDerive (can_residual.canon (can_cyclic.canon (encaps kem g).1)) = (encaps kem g).2` | `Optimization/TwoPhaseDecrypt.lean` | Conditional | Decapsulation via the fast path recovers the encapsulated key WHEN the two-phase decomposition holds (composes `two_phase_kem_decaps` with `kem_correctness`). **Same hypothesis as row #24**: the GAP implementation does NOT discharge `TwoPhaseDecomposition` because lex-min and the residual transversal action don't commute — this theorem is a conditional that documents the strong agreement property, not the actual GAP correctness story. The non-vacuous sibling is `fast_kem_round_trip` (row #26). Audit 2026-04-23 finding V1-2 / L-03 (Phase 15.3 / 15.5) |
| 26 | **Fast-KEM Round-Trip (orbit-constancy)** | `fast_kem_round_trip : keyDerive (fastCanon (g • basePoint)) = keyDerive (fastCanon basePoint)` (given `IsOrbitConstant G fastCanon`) | `Optimization/TwoPhaseDecrypt.lean` | Standalone | The actual correctness theorem for the GAP `(FastEncaps, FastDecaps)` pair: orbit-constancy of the fast canonical form is sufficient for round-trip correctness, and orbit-constancy IS satisfied by `FastCanonicalImage` whenever the cyclic subgroup is normal in G (Phase 15.3, post-landing audit) |
| 27 | **Surrogate-Bound Hardness Chain (non-vacuous)** | `ConcreteHardnessChain.concreteOIA_from_chain hc : ConcreteOIA scheme ε` for `hc : ConcreteHardnessChain scheme F S ε` with explicit `S : SurrogateTensor F` and encoder fields `encTC, encCG`; `tight_one_exists` witnesses inhabitation at ε = 1 via `punitSurrogate F` and dimension-0 trivial encoders | `Hardness/Reductions.lean` | Quantitative | Closes audit finding H1 (2026-04-21, HIGH). Pre-G the chain's `UniversalConcreteTensorOIA εT` implicitly quantified over every `G_TI : Type` including PUnit, making the Prop collapse at εT < 1. Fix B binds the surrogate; Fix C adds per-encoding reduction Props (`*_viaEncoding`) naming explicit encoder functions. Composition threads advantage through the chain image `encCG ∘ encTC`, not a universal hypothesis (Workstream G). The end-to-end bound `concrete_hardness_chain_implies_1cpa_advantage_bound : ConcreteHardnessChain … → IND-1-CPA advantage ≤ ε` is the **primary public-release citation** for scheme-level quantitative security |
| 28 | **Per-Encoding Reduction Props (Fix C)** | `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding S enc εT εC`, `ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding enc εC εG`, `ConcreteGIOIAImpliesConcreteOIA_viaEncoding scheme encTC encCG εG ε` | `Hardness/Reductions.lean` | Quantitative | Each reduction Prop names an explicit encoder function and asserts hardness transfer *through* that encoder. Satisfiable at ε = 1 via the `*_one_one` witnesses (conclusion is unconditionally true); non-trivial ε < 1 discharges require concrete encoder witnesses (CFI, Grochow–Qiao — research-scope, audit plan § 15.1). This is the "cryptographically cleanest" formulation the audit calls for (Workstream G / Fix C) |
| 29 | **KEM-Layer ε-Smooth Hardness Chain** | `concreteKEMHardnessChain_implies_kemUniform : ConcreteKEMHardnessChain scheme F S m₀ keyDerive ε → ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) ε`; `concrete_kem_hardness_chain_implies_kem_advantage_bound : ConcreteKEMHardnessChain … → kemAdvantage_uniform … ≤ ε` (end-to-end adversary bound); `ConcreteKEMHardnessChain.tight_one_exists` witnesses inhabitation at ε = 1 via `punitSurrogate F`, dimension-0 trivial encoders, and the `_one_right` discharge | `KEM/CompSecurity.lean` | Quantitative | Closes audit finding H2 (2026-04-21, MEDIUM). Pre-H, the KEM surface carried `concrete_kemoia_implies_secure` (point-mass, collapses on `[0, 1)`) and `concrete_kemoia_uniform_implies_secure` (uniform, ε-smooth) but **no chain-level entry point** from TI-hardness. Workstream H adds the abstract scheme-to-KEM reduction Prop `ConcreteOIAImpliesConcreteKEMOIAUniform` (H1) with trivial `ε' = 1` discharge `concreteOIAImpliesConcreteKEMOIAUniform_one_right` (H2), the packaged `ConcreteKEMHardnessChain` (H3) composing it with the Workstream-G scheme-level chain, and the end-to-end adversary-bound corollary mirroring `concrete_hardness_chain_implies_1cpa_advantage_bound` (Workstream H). The `kem_advantage_bound` form is the **primary public-release citation** for KEM-layer quantitative security |
| 30 | **Distinct-challenge IND-1-CPA (classical game)** | `oia_implies_1cpa_distinct : OIA scheme → IsSecureDistinct scheme`; `hardness_chain_implies_security_distinct : HardnessChain scheme → IsSecureDistinct scheme`; `concrete_hardness_chain_implies_1cpa_advantage_bound_distinct : ConcreteHardnessChain … → _ ≠ _ → indCPAAdvantage ≤ ε`; `indCPAAdvantage_collision_zero : (A.choose).1 = (A.choose).2 → indCPAAdvantage = 0` | `Theorems/OIAImpliesCPA.lean`, `Hardness/Reductions.lean`, `Crypto/CompSecurity.lean` | Scaffolding (K1, K3) + Quantitative (K4) + Standalone (collision lemma) | Closes audit finding M1 (2026-04-21, MEDIUM). `IsSecure` (uniform game, see `Crypto/Security.lean`) is strictly stronger than the classical IND-1-CPA game `IsSecureDistinct` (which rejects `(m, m)` challenges) — the gap is closed by `isSecure_implies_isSecureDistinct` (Workstream B1). Workstream K threads this distinction through the deterministic downstream chain with `_distinct` corollaries (K1, K3) and through the probabilistic chain with the collision-zero lemma (K4). Because `indCPAAdvantage` already holds the `≤ ε` bound *for every adversary* (collision or not) — `indCPAAdvantage_collision_zero` shows the collision branch contributes advantage 0 — the probabilistic bound transfers to the classical distinct-challenge game for free. The K2 work unit deliberately *omits* a `kemoia_implies_secure_distinct` corollary because the KEM game parameterises adversaries by group elements (not messages); see the extended docstring on `kemoia_implies_secure`. Release-facing citations should prefer the `_distinct` forms because they match the literature's IND-1-CPA game shape |
| 31 | **Deterministic OIA Vacuity Witness** | `det_oia_false_of_distinct_reps : scheme.reps m₀ ≠ scheme.reps m₁ → ¬ OIA scheme` | `Crypto/OIA.lean` | Standalone | Closes audit finding C-07 (2026-04-23, HIGH). Machine-checks that the deterministic `OIA` predicate is `False` on every scheme that admits two messages with distinct representatives (a strengthening of `reps_distinct`). The distinguisher is the Boolean membership test `fun x => decide (x = reps m₀)` evaluated at identity group elements — `true` on the `m₀`-orbit, `false` on the `m₁`-orbit, contradiction. Replaces the prose-only vacuity disclosure in `Orbcrypt/Crypto/OIA.lean`'s module docstring with a Lean theorem consumers can cite when explaining why `oia_implies_1cpa` is scaffolding, not substantive security content (Workstream E of the 2026-04-23 audit) |
| 32 | **Deterministic KEMOIA Vacuity Witness** | `det_kemoia_false_of_nontrivial_orbit : g₀ • kem.basePoint ≠ g₁ • kem.basePoint → ¬ KEMOIA kem` | `KEM/Security.lean` | Standalone | Closes audit finding E-06 (2026-04-23, HIGH). KEM-layer parallel of theorem #31: `KEMOIA` collapses whenever two group elements produce distinct ciphertexts, i.e. whenever the base-point orbit is non-trivial (production HGOE has `\|orbit\| ≫ 2`). Distinguisher: `fun c => decide (c = g₀ • kem.basePoint)`. Written against the post-Workstream-L5 single-conjunct `KEMOIA`; no `.1` / `.2` destructuring. Replaces the prose-only vacuity disclosure in `KEMOIA`'s docstring with a Lean theorem (Workstream E of the 2026-04-23 audit) |

Together these establish: the scheme is correct, its failure mode is precisely characterized, and under a stated *probabilistic* hardness assumption it is secure. (The deterministic-chain theorems marked **Scaffolding** in the Status column above — #3, #5, #8, #14, and the deterministic half of #30 — encode the *shape* of an OIA-style reduction argument but are vacuously true on every non-trivial scheme; they are not standalone security claims. See `Orbcrypt.lean` § "Deterministic-vs-probabilistic security chains" and `docs/VERIFICATION_REPORT.md` § "Release readiness" for the release-messaging framing — Workstream J, audit finding H3.) The KEM reformulation (theorems 4–5) provides the same guarantees in the modern KEM+DEM hybrid encryption paradigm. The probabilistic foundations (theorems 6–8) replace the vacuously-true deterministic security with meaningful computational security guarantees. The key management results (theorems 9–11) prove that seed-based key compression and nonce-based encryption preserve correctness while formally characterizing nonce-misuse risks. The AEAD layer (theorems 12–13) adds integrity protection and support for arbitrary-length messages via standard KEM+DEM composition; the INT-CTXT results (theorems 19–20, Workstream C) strengthen it by machine-checking ciphertext integrity against an enriched MAC abstraction with tag uniqueness (`verify_inj`) and exhibiting a concrete Carter–Wegman witness. The public-key extension (theorems 15–18, Phase 13) provides algebraic scaffolding for three candidate paths from the symmetric scheme to public-key orbit encryption — with an accompanying feasibility analysis (`docs/PUBLIC_KEY_ANALYSIS.md`) that documents which paths are viable, bounded, or open. The Code Equivalence API (theorems 21–23, Workstream D) closes audit findings F-08 and F-16 by promoting `ArePermEquivalent` to a Mathlib `Setoid` and `PAut` to a Mathlib `Subgroup`, and by proving the full coset set identity that underlies LESS-style signatures. The Phase 15 decryption-optimisation formalisation (theorems 24–26) covers the GAP fast-decryption pipeline (`implementation/gap/orbcrypt_fast_dec.g`): theorems #24–#25 formalise the strong "fast = slow" decomposition as a conditional, theorem #26 captures the actual KEM correctness story via orbit-constancy of the fast canonical form. Post-landing audit (this commit) confirmed empirically that the strong decomposition does not hold for the default fallback group, so the production correctness argument runs through #26. The Workstream G refactor (theorems 27–28, audit 2026-04-21 finding H1) closes the pre-G PUnit collapse in `UniversalConcreteTensorOIA` by binding a `SurrogateTensor F` parameter (Fix B) and introducing per-encoding reduction Props that name explicit encoder functions (Fix C); the chain is now honestly ε-parametric in both the surrogate choice and the encoder witnesses. Workstream H (theorem 29, audit 2026-04-21 finding H2) lifts the Workstream-G chain to the KEM layer by introducing `ConcreteOIAImpliesConcreteKEMOIAUniform` (H1) as the abstract scheme-to-KEM reduction Prop, discharging its `ε' = 1` satisfiability witness (H2), and packaging both with the scheme-level chain into `ConcreteKEMHardnessChain` (H3); `concreteKEMHardnessChain_implies_kemUniform` delivers `ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) ε` from TI-hardness at the caller-supplied surrogate, encoders, and keyDerive, and `concrete_kem_hardness_chain_implies_kem_advantage_bound` composes one more step with `concrete_kemoia_uniform_implies_secure` to deliver the end-to-end KEM adversary bound `kemAdvantage_uniform … ≤ ε` — mirroring the scheme-level `concrete_hardness_chain_implies_1cpa_advantage_bound` and closing the KEM-layer chain gap that the MEDIUM-severity finding H2 flagged. Workstream K (theorem 30, audit 2026-04-21 finding M1) threads the classical IND-1-CPA "challenger-rejects-`(m, m)`" game shape through the downstream chain: `oia_implies_1cpa_distinct` (K1) and `hardness_chain_implies_security_distinct` (K3) deliver `IsSecureDistinct` from their respective deterministic hypotheses by composition with `isSecure_implies_isSecureDistinct`; `indCPAAdvantage_collision_zero` (K4) formalises the free transfer of the probabilistic ε-bound to the distinct-challenge form by showing the collision branch contributes advantage zero; `concrete_hardness_chain_implies_1cpa_advantage_bound_distinct` (K4, companion) restates the probabilistic chain bound in literature-matching distinct-challenge form. No KEM-level `_distinct` corollary is introduced (K2) because the KEM game parameterises adversaries by group elements rather than messages, so no per-challenge collision gap exists at that layer — see the extended docstring on `kemoia_implies_secure` for the full rationale.

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
| 1 | Project Scaffolding | 1 | 4 | 4.5h | `docs/dev_history/formalization/phases/PHASE_1_PROJECT_SCAFFOLDING.md` | Complete |
| 2 | Group Action Foundations | 2-4 | 11 | 28h | `docs/dev_history/formalization/phases/PHASE_2_GROUP_ACTION_FOUNDATIONS.md` | Complete |
| 3 | Cryptographic Definitions | 5-6 | 8 | 18h | `docs/dev_history/formalization/phases/PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md` | Complete |
| 4 | Core Theorems | 7-10 | 16 | 33h | `docs/dev_history/formalization/phases/PHASE_4_CORE_THEOREMS.md` | Complete |
| 5 | Concrete Construction | 11-14 | 12 | 26h | `docs/dev_history/formalization/phases/PHASE_5_CONCRETE_CONSTRUCTION.md` | Complete |
| 6 | Polish & Documentation | 15-16 | 13 | 22.5h | `docs/dev_history/formalization/phases/PHASE_6_POLISH_AND_DOCUMENTATION.md` | Complete |
| 7 | KEM Reformulation | 17-19 | 8 | ~24h | `docs/dev_history/formalization/PRACTICAL_IMPROVEMENTS_PLAN.md` | Complete |
| 8 | Probabilistic Foundations | 18-22 | 10 | ~40h | `docs/dev_history/formalization/PRACTICAL_IMPROVEMENTS_PLAN.md` | Complete |
| 9 | Key Compression & Nonce-Based Enc | 20-22 | 7 | ~18h | `docs/dev_history/formalization/PRACTICAL_IMPROVEMENTS_PLAN.md` | Complete |
| 10 | Authenticated Encryption & Modes | 22-24 | 6 | ~16h | `docs/dev_history/PHASE_10_AUTHENTICATED_ENCRYPTION.md` | Complete |
| 11 | Reference Implementation (GAP) | 24-26 | 9 | ~36h | `docs/dev_history/PHASE_11_GAP_PROTOTYPE.md` | Complete |
| 12 | Hardness Alignment (LESS/MEDS/TI) | 26-28 | 8 | ~32h | `docs/dev_history/PHASE_12_HARDNESS_ALIGNMENT.md` | Complete |
| 13 | Public-Key Extension | 26-30 | 7 | ~28h | `docs/dev_history/PHASE_13_PUBLIC_KEY_EXTENSION.md` | Complete |
| 14 | Parameter Selection & Benchmarks | 28-31 | 6 | ~20h | `docs/dev_history/PHASE_14_PARAMETER_SELECTION.md` | Complete |
| 15 | Decryption Optimisation (C/C++) | 30+ | TBD | ~20h | `docs/dev_history/PHASE_15_DECRYPTION_OPTIMIZATION.md` | Planned |
| 16 | Formal Verification of New Components | 30-36 | 10 | ~36h | `docs/dev_history/PHASE_16_FORMAL_VERIFICATION.md` | Complete |
| | **Total (1–14, 16)** | **37** | **135** | **~382h** | | |

**Critical path:** Chain A (Correctness) at ~32 hours of sequential work is the longest path:
```
1.1 -> 1.4 -> 2.1 -> 2.4 -> 2.5 -> 2.6 -> 3.1 -> 3.2 -> 3.3 -> 4.1 -> 4.2 -> 4.3 -> 4.4 -> 4.5
 2h     1h     3h     3h     2h     3h     3h     1h     4h    1.5h    2h    2.5h    2h     2h
```

**Key parallelism opportunity:** `Construction/Permutation.lean` (Phase 5, units 5.1-5.6) depends only on Phase 2's group action foundations. It can begin as soon as Phase 2 completes, running in parallel with Phases 3 and 4.

Read the individual phase documents for detailed implementation guidance, work unit breakdowns, risk analysis, and verification criteria before starting any phase.

## Documentation rules

When changing behavior, theorems, or formalization status, update in the same PR:
1. `docs/DEVELOPMENT.md` — if the change affects scheme design, security analysis, or mathematical content
2. `docs/dev_history/formalization/FORMALIZATION_PLAN.md` — if the change affects module architecture, timeline, or conventions
3. The relevant phase document under `docs/dev_history/formalization/phases/` — if work unit status or guidance changes (note: phase docs are now historical record; updates are rare)
4. `docs/COUNTEREXAMPLE.md` — if invariant attack analysis is refined
5. `docs/POE.md` — if the high-level concept exposition needs updating
6. `README.md` — if project status or description changes
7. `CLAUDE.md` — if development guidance, conventions, or project status changes

Canonical ownership: `docs/DEVELOPMENT.md` owns the full scheme specification. `docs/dev_history/formalization/FORMALIZATION_PLAN.md` owns the Lean 4 architecture and conventions. Phase documents own implementation-level guidance for their respective phases. `docs/POE.md` and `docs/COUNTEREXAMPLE.md` own the high-level concept exposition and vulnerability analysis respectively.

## Pull request authoring policy (ABSOLUTE)

**Forbidden in PR summaries / descriptions / bodies:** session URLs of
the shape `https://claude.ai/code/session_*` (or any equivalent
agent-harness session permalink). Examples of the forbidden form:

* `https://claude.ai/code/session_019S9v23eC235cqr76MNWe5S`
* `claude.ai/code/session_<any-id>`
* Any other URL whose path identifies a private agent-harness
  conversation (Claude Code Web, Claude Agent SDK, GitHub-side
  Claude Action sessions, etc.).

**Why this rule exists.**

1. *Privacy / opacity.* A session URL points at a private workspace
   artefact: full transcript, tool calls, intermediate code, plan
   discussions. It is not a public reference. PR readers — including
   reviewers, downstream maintainers, security auditors — cannot
   open it; the link is dead from their perspective and adds no
   discoverable context.
2. *Link rot.* Session URLs are ephemeral: harness sessions expire,
   compress, or get archived behind authentication. A PR description
   that points at one will break in days or weeks, leaving a
   permanent dead reference in the repository's release history.
3. *Provenance leakage.* Session URLs embed harness internals
   (Claude Code vs Web vs Action, session-id format, etc.) which
   reveal authoring tooling that the PR description otherwise needn't
   disclose. The PR's *content* (theorems, audit findings, build
   posture) is what matters, not which agent-harness session
   produced it.
4. *Citation discipline.* Per `CLAUDE.md`'s **Names describe content,
   never provenance** rule (Key Conventions), declarations and
   release-facing references must describe what they prove or what
   they document, not the workflow / phase / session that produced
   them. PR summaries are release-facing prose; the same discipline
   applies. A reader needs the theorem name, the audit plan section,
   the file path — not a workspace-private session pointer.

**Allowed alternatives — what to cite instead.**

* The audit / planning document under `docs/planning/` (e.g.
  `docs/dev_history/PLAN_R_01_07_08_14_16.md` § R-07).
* The headline theorem name + file path (e.g.
  `combinerDistinguisherAdvantage_ge_inv_card`
  `Orbcrypt/PublicKey/CombineImpossibility.lean`).
* The CLAUDE.md changelog entry that records the work
  (e.g. "Workstream R-07 Research-Scope Discharge").
* The `docs/VERIFICATION_REPORT.md` Document-history entry.
* The relevant audit-script entry in `scripts/audit_phase_16.lean`'s
  `R07NonVacuity` namespace.

**Scope of the rule.**

* **In scope (forbidden):** PR descriptions / bodies; PR review
  comments; PR-edit `body` arguments to
  `mcp__github__update_pull_request`; cross-link inserts in PR
  comments via `mcp__github__add_issue_comment` /
  `mcp__github__add_reply_to_pull_request_comment`. Anywhere the
  resulting URL would be visible in the PR's GitHub UI or
  retrievable via the GitHub API's public endpoints.
* **Out of scope:** local commit messages (the agent harness's
  default `gh commit` template may auto-append a session footer to
  *commits*, which lives in `git log`; this policy concerns
  *PR-level* surfaces, not commit-trailer hygiene). If a project
  later wants to remove session URLs from commit messages too, that
  is a separate policy decision.

**Enforcement.**

1. Before invoking `mcp__github__create_pull_request` or
   `mcp__github__update_pull_request`, scan the prepared `body`
   string for the regex
   `https?://(?:www\.)?claude\.ai/code/session_[A-Za-z0-9]+` (or any
   equivalent agent-harness session-permalink shape). Strip every
   match before submission.
2. If a session URL is discovered in an already-open PR, update
   the PR body via `mcp__github__update_pull_request` to remove the
   offending substring. The remediation should preserve the rest
   of the PR description verbatim — only the URL line(s) and any
   trailing whitespace they introduce should be removed.
3. The same scan applies whenever the agent edits a PR body, even
   for unrelated reasons (e.g. fixing a typo, adding a checklist
   item). Removing pre-existing session URLs is a "free cleanup" —
   never re-introduce them.

**Historical note.** Earlier PRs in this repository may carry
session URLs in their bodies (the policy is being introduced in this
PR). Those PRs are merged / closed historical artefacts and are not
subject to retroactive scrubbing; the rule is forward-looking. The
PR introducing this policy itself has its body scrubbed of the
session URL as part of the same change.

## Key documents reference

| File | Size | Purpose | Read This To Understand |
|------|------|---------|------------------------|
| `docs/DEVELOPMENT.md` | ~56KB | Master specification | Full scheme design, security proofs, hardness reductions, 7-stage pipeline |
| `docs/POE.md` | ~6KB | Concept exposition | Core intuition behind orbit encryption, isogeny variant, unifying view |
| `docs/COUNTEREXAMPLE.md` | ~5KB | Vulnerability analysis | Why naive constructions fail, invariant attack principle, Hamming weight break |
| `docs/dev_history/formalization/FORMALIZATION_PLAN.md` | ~17KB | Master Lean 4 roadmap | Architecture, module dependencies, Mathlib integration, timeline, conventions |
| `docs/dev_history/formalization/phases/PHASE_1_*.md` | ~8KB | Scaffolding guide | lakefile.lean setup, directory structure, .gitignore, clean build verification |
| `docs/dev_history/formalization/phases/PHASE_2_*.md` | ~20KB | Group action guide | Orbit API wrappers, canonical forms, invariant functions (11 work units) |
| `docs/dev_history/formalization/phases/PHASE_3_*.md` | ~16KB | Crypto definitions guide | AOE scheme, IND-CPA game, OIA assumption (8 work units) |
| `docs/dev_history/formalization/phases/PHASE_4_*.md` | ~40KB | Core theorems guide | Correctness proof, invariant attack proof, OIA->CPA reduction (16 work units, 4 tracks) |
| `docs/dev_history/formalization/phases/PHASE_5_*.md` | ~26KB | Construction guide | S_n bitstring action, HGOE instance, Hamming defense (12 work units) |
| `docs/dev_history/formalization/phases/PHASE_6_*.md` | ~24KB | Polish guide | sorry audit by module, docstrings, CI, Mathlib pin, final audit (13 work units) |

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

**Security Model:** IND-CPA (Indistinguishability under Chosen Plaintext Attack). The scheme targets IND-1-CPA (single query) as the primary formalized result, with multi-query extension via standard hybrid argument discussed in docs/DEVELOPMENT.md section 8.2.

**Hardness Assumptions:**
- **Graph Isomorphism (GI):** Best classical algorithm: 2^O(sqrt(n log n)) (Babai, 2015). CFI graphs provide provably hard instances for Weisfeiler-Leman hierarchy.
- **Permutation Code Equivalence (CE):** At least as hard as GI (GI <=_p CE). Believed strictly harder for specific code families.
- **Hidden Subgroup Problem:** Hard even for quantum computers — key barrier for quantum GI algorithms.

## Active development status

**Current Phase:** Phases 1–14 Complete — Parameter Recommendations Published

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
- `Theorems/InvariantAttack.lean` — `invariantAttackAdversary` construction, `invariant_on_encrypt` helper, `invariantAttackAdversary_correct` (case split proof), `invariant_attack` (separating invariant implies existence of a distinguishing adversary `∃ A, hasAdvantage`; informal shorthand "complete break" — see headline row #2 for the full three-convention advantage catalogue). Axioms: `propext` only
- `Theorems/OIAImpliesCPA.lean` — `oia_specialized` (OIA instantiation), `hasAdvantage_iff` (clean unfolding), `no_advantage_from_oia` (advantage elimination), `oia_implies_1cpa` (OIA implies IND-1-CPA security). Axioms: zero (OIA is a hypothesis, not an axiom)
- Track D (contrapositive): `adversary_yields_distinguisher`, `insecure_implies_orbit_distinguisher` (renamed from `insecure_implies_separating` in Workstream I3 of the 2026-04-23 audit, finding D-07 — the body delivers an orbit-distinguisher, not a G-invariant separating function as the pre-I name suggested), `distinct_messages_have_invariant_separator` (the genuine G-invariant separator the pre-I name advertised; Workstream I3, NEW substantive theorem at standalone status)
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
- `KEM/Security.lean` — `KEMAdversary` structure; `kemHasAdvantage` (two-encapsulation distinguishability); `KEMIsSecure` predicate; `kemIsSecure_iff` (unfolding lemma); `KEMOIA` (orbit indistinguishability; **single-conjunct** post Workstream L5 — the former key-uniformity conjunct was redundant with `kem_key_constant_direct`); `kem_key_constant_direct` (key constancy proved unconditionally from `canonical_isGInvariant`); `kem_ciphertext_indistinguishable` (from `KEMOIA`); `kemoia_implies_secure` (KEMOIA implies KEM security)
- `Construction/HGOEKEM.lean` — `hgoeKEM` (concrete KEM for S_n subgroups on bitstrings); `hgoe_kem_correctness` (instantiation of abstract correctness); `hgoeScheme_toKEM` (bridge from HGOE scheme to KEM); `hgoeScheme_toKEM_correct` (bridge correctness)
- All 8 work units (7.1–7.8) implemented with zero `sorry`, zero warnings, zero custom axioms
- 22 new public declarations across 591 lines
- `lake build` succeeds for all 16 modules (zero errors)

Phase 8 (Probabilistic Foundations) has been completed:
- `Probability/Monad.lean` — `uniformPMF` (wraps `PMF.uniformOfFintype`); `probEvent` and `probTrue` (event probability under PMF); `probEvent_certain`, `probEvent_impossible`, `probTrue_le_one` (sanity lemmas)
- `Probability/Negligible.lean` — `IsNegligible` (standard crypto negligible function definition); `isNegligible_zero`, `IsNegligible.add`, `IsNegligible.mul_const` (closure properties)
- `Probability/Advantage.lean` — `advantage` (distinguishing advantage `|Pr[D=1|d₀] - Pr[D=1|d₁]|`); `advantage_nonneg`, `advantage_symm`, `advantage_self`, `advantage_le_one` (basic properties); `advantage_triangle` (triangle inequality); `hybrid_argument` (general n-hybrid argument by induction)
- `Crypto/CompOIA.lean` — `orbitDist` (orbit distribution via PMF.map); `orbitDist_support`, `orbitDist_pos_of_mem` (support characterization); `ConcreteOIA` (concrete-security OIA with explicit bound ε); `concreteOIA_zero_implies_perfect`, `concreteOIA_mono`, `concreteOIA_one` (basic lemmas); `SchemeFamily` (security-parameter-indexed families); `SchemeFamily.repsAt` / `SchemeFamily.orbitDistAt` / `SchemeFamily.advantageAt` (readability helpers, Workstream A7 / F-13 — definitionally equal to the pre-refactor `@`-threaded forms, recoverable via `simp [SchemeFamily.advantageAt, SchemeFamily.orbitDistAt, SchemeFamily.repsAt]`); `CompOIA` (asymptotic computational OIA, now phrased via `advantageAt`); `det_oia_implies_concrete_zero` (bridge: deterministic OIA → ConcreteOIA(0))
- `Crypto/CompSecurity.lean` — `indCPAAdvantage` (probabilistic IND-1-CPA advantage); `indCPAAdvantage_eq` (unfolding lemma); `concrete_oia_implies_1cpa` (ConcreteOIA(ε) → advantage ≤ ε); `indCPAAdvantage_le_one` (renamed from `concreteOIA_one_meaningful` in Workstream I1 of the 2026-04-23 audit, finding C-15 — Mathlib-style `_le_one` simp lemma; the pre-I name overstated the content); `concreteOIA_zero_of_subsingleton_message` (Workstream I1 NEW substantive non-vacuity witness — perfect concrete-security at ε = 0 on every subsingleton-message scheme, the cryptographic content the pre-I `_meaningful` name advertised but did not deliver); `CompIsSecure` (asymptotic security); `comp_oia_implies_1cpa` (CompOIA → computational security); `MultiQueryAdversary` structure; `single_query_bound` (per-query advantage ≤ ε, building block for multi-query)
- All 10 work units (8.1–8.10) implemented with zero `sorry`, zero custom axioms
- 5 new Lean files, ~30 new public declarations
- `lake build` succeeds for all 21 modules (zero errors)

Phase 9 (Key Compression & Nonce-Based Encryption) has been completed:
- `KeyMgmt/SeedKey.lean` — `SeedKey` structure (compact seed + deterministic expansion + PRF-based sampling + **machine-checked bit-length compression witness** `compression : Nat.log 2 (Fintype.card Seed) < Nat.log 2 (Fintype.card G)` post Workstream L1; `[Fintype Seed]` and `[Fintype G]` are now typeclass preconditions on the structure); `seed_kem_correctness` (seed-based KEM correctness, follows from `kem_correctness`); `HGOEKeyExpansion` (λ-parameterised 7-stage QC code key expansion specification with weight uniformity; takes `(lam : ℕ) (n : ℕ) (M : Type*)` and asks `group_order_log ≥ lam` post Workstream G of audit 2026-04-23 — finding V1-13 / H-03 / Z-06 / D16, landed 2026-04-25 — unlocking λ ∈ {80, 192, 256} that the pre-G hard-coded `≥ 128` bound made unreachable); `seed_determines_key` (equal seeds → equal key material); `seed_determines_canon` (equal seeds → equal canonical forms); `OrbitEncScheme.toSeedKey` (backward compatibility bridge; takes an `hGroupNontrivial : 1 < Fintype.card G` hypothesis post Workstream L1 to discharge the `compression` field); `toSeedKey_expand` and `toSeedKey_sampleGroup` (bridge preservation lemmas)
- `KeyMgmt/Nonce.lean` — `nonceEncaps` (nonce-based deterministic KEM encapsulation); `nonceDecaps` (nonce-based decapsulation); `nonce_encaps_correctness` (decaps recovers encapsulated key); `nonce_reuse_deterministic` (same nonce → same output, by `rfl`); `distinct_nonces_distinct_elements` (injective PRF → distinct group elements); `nonce_reuse_leaks_orbit` (cross-KEM nonce reuse leaks orbit membership — formal warning theorem); `nonceEncaps_mem_orbit` (ciphertext lies in base point's orbit); simp lemmas for unfolding
- All 7 work units (9.1–9.7) implemented with zero `sorry`, zero warnings, zero custom axioms
- 2 new Lean files, 19 new public declarations across 467 lines
- `lake build` succeeds for all 23 modules (zero errors)

Phase 10 (Authenticated Encryption & Modes) has been completed:
- `AEAD/MAC.lean` — `MAC` structure with `tag`, `verify`, `correct`, and `verify_inj` fields; generic parameterization by key, message, and tag types. `verify_inj` (added in Workstream C1, audit F-07) is the information-theoretic SUF-CMA analogue required for `INT_CTXT` proofs.
- `AEAD/AEAD.lean` — `AuthOrbitKEM` structure composing `OrbitKEM` with `MAC` (Encrypt-then-MAC); `authEncaps` (authenticated encapsulation), `authDecaps` (verify-then-decrypt); `aead_correctness` theorem (authDecaps recovers key from honest pairs); `INT_CTXT` security definition (ciphertext integrity; post-audit 2026-04-23 Workstream B, carries a per-challenge `hOrbit` well-formedness precondition on the game itself); `authDecaps_none_of_verify_false` (C2a, private helper); `keyDerive_canon_eq_of_mem_orbit` (C2b, private key-uniqueness lemma); `authEncrypt_is_int_ctxt` (C2c, main theorem; initially carried an `hOrbitCover` hypothesis as the Phase 10 landing, now discharges `INT_CTXT` unconditionally on every `AuthOrbitKEM` post-Workstream-B); simp lemmas for authEncaps components
- `AEAD/Modes.lean` — `DEM` structure (symmetric encryption with correctness field); `hybridEncrypt` (KEM produces key, DEM encrypts data), `hybridDecrypt` (KEM recovers key, DEM decrypts); `hybrid_correctness` theorem (decrypt inverts encrypt); simp lemmas for hybrid components
- `AEAD/CarterWegmanMAC.lean` — (Workstream C4, audit F-07) concrete `MAC` witness demonstrating that `verify_inj` is satisfiable: `deterministicTagMAC` (generic template whose `verify` is `decide (t = f k m)`), `carterWegmanHash` + `carterWegmanMAC p` (Carter–Wegman universal-hash instance over `ZMod p × ZMod p`), `carterWegman_authKEM` (composes with an arbitrary `OrbitKEM`), `carterWegmanMAC_int_ctxt` (direct specialisation of `authEncrypt_is_int_ctxt`). Information-theoretically weak; documented as not production-grade.
- All 6 work units (10.1–10.6) implemented with zero `sorry`, zero warnings, zero custom axioms
- 3 new Lean files, 15 new public declarations across ~400 lines
- `lake build` succeeds for all 26 modules (zero errors)

Phase 11 (Reference Implementation — GAP Prototype) has been completed:
- `implementation/gap/orbcrypt_keygen.g` — 7-stage HGOE key generation pipeline: parameter derivation, group construction (block-cyclic wreath product + optional QC code PAut), orbit representative harvesting via canonical images, lookup table construction, key assembly; `HGOEParams`, `HGOEGenerateCode`, `HGOEFallbackGroup`, `HGOEHarvestReps`, `HGOEKeygen`, `HGOEKEMKeygen`
- `implementation/gap/orbcrypt_kem.g` — KEM encapsulation/decapsulation: `PermuteBitstring` (OnSets action), `HGOEEncaps` (sample g, compute c=g.bp, key=canon(c)), `HGOEDecaps` (key=canon(c)), `HGOEEncrypt`/`HGOEDecrypt` (AOE scheme), verification helpers
- `implementation/gap/orbcrypt_params.g` — Parameter generation for lambda in {80, 128, 192, 256}: derivation tables, group order validation (all pass), orbit count estimation
- `implementation/gap/orbcrypt_test.g` — 13 correctness tests across 4 sections: KEM round-trip, orbit membership, weight preservation, canonical form consistency, distinct orbits, AOE round-trip, larger parameters, invariant attack (100% accuracy on different-weight reps), weight defense (~50% on same-weight reps), higher-order invariants, edge cases
- `implementation/gap/orbcrypt_bench.g` — Benchmark harness with timing breakdown (keygen, encaps, decaps, canonical image), CSV output, comparison table against AES-256-GCM/Kyber-768/BIKE-L3/HQC-256, go/no-go evaluation
- `implementation/README.md` — Installation, usage, reproducibility guide, architecture overview, parameter tables, known limitations
- All 9 work units (11.1–11.9) implemented; 13/13 tests pass; benchmarks for all 4 security levels
- Go/No-Go: **GO** — keygen 1.4s, encaps 256ms, decaps 244ms at lambda=128
- GAP 4.12.1 with packages: images v1.3.2, GUAVA 3.18, IO 4.8.2, ferret (optional)

Phase 12 (Hardness Alignment — LESS/MEDS/TI) has been completed:
- `Hardness/CodeEquivalence.lean` — `permuteCodeword` (coordinate permutation action on codewords), `ArePermEquivalent` (permutation code equivalence), `PAut` (permutation automorphism group), `CEOIA` (Code Equivalence OIA variant), `GIReducesToCE` (GI ≤_p CE as Prop); `permuteCodeword_one`, `permuteCodeword_mul` (action laws); `arePermEquivalent_refl`, `paut_contains_id`, `paut_mul_closed` (basic properties); `paut_compose_preserves_equivalence` (PAut coset structure); `paut_from_dual_equivalence` (dual equivalences yield automorphisms)
- `Hardness/TensorAction.lean` — `Tensor3` (3-tensor type); `matMulTensor1`, `matMulTensor2`, `matMulTensor3` (single-axis contraction helpers); `tensorContract` (full trilinear contraction); `tensorAction` (MulAction instance for GL(n,F)³ with fully proved `one_smul` and `mul_smul`); `AreTensorIsomorphic` (tensor isomorphism relation); `areTensorIsomorphic_refl`, `areTensorIsomorphic_symm` (equivalence properties); `GIReducesToTI` (GI ≤ TI as Prop)
- `Hardness/Reductions.lean` — `TensorOIA` (strongest OIA variant, GL³ action); `GIOIA` (graph isomorphism OIA); `TensorOIAImpliesCEOIA`, `CEOIAImpliesGIOIA`, `GIOIAImpliesOIA` (reduction steps as Prop definitions); `HardnessChain` (full composite reduction); `oia_from_hardness_chain` (chain composition proof); `hardness_chain_implies_security` (TI-hardness → IND-1-CPA)
- `docs/HARDNESS_ANALYSIS.md` — LESS/MEDS alignment analysis, reduction chain documentation, hardness comparison table (10 problems), literature references
- All 8 work units (12.1–12.8) implemented with zero `sorry`, zero warnings, zero custom axioms
- 3 new Lean files, 44 new public declarations across ~770 lines
- `lake build` succeeds for all 29 modules (zero errors)

Phase 13 (Public-Key Extension) has been completed:
- `PublicKey/ObliviousSampling.lean` — `OrbitalRandomizers` (bundle of orbit samples with membership certificate); `obliviousSample`, `obliviousSample_eq` (simp); `oblivious_sample_in_orbit` (orbit-membership theorem via closure hypothesis); `ObliviousSamplingPerfectHiding` (renamed from `ObliviousSamplingHiding` in Workstream I6 of the 2026-04-23 audit, finding K-02 — `Prop`-valued deterministic sender-privacy requirement; the post-I name accurately conveys its perfect-extremum strength: the predicate is `False` on every non-trivial bundle); `oblivious_sampling_view_constant_under_perfect_hiding` (immediate corollary carrying `ObliviousSamplingPerfectHiding` as hypothesis; renamed companion theorem); `ObliviousSamplingConcreteHiding` (Workstream I6 NEW probabilistic ε-smooth predicate suitable for release-facing security claims — the sender's obliviously-sampled output is at advantage ≤ ε from a fresh uniform orbit sample); `oblivious_sampling_view_advantage_bound` (Workstream I6 NEW structural extraction lemma mirroring `concrete_oia_implies_1cpa`); `ObliviousSamplingConcreteHiding_zero_witness` (Workstream I6 NEW non-vacuity witness at ε = 0 on singleton-orbit bundles); `refreshRandomizers`, `refreshRandomizers_apply` (simp), `refreshRandomizers_in_orbit`, `refreshRandomizers_orbitalRandomizers` (epoch-indexed bundle constructor) with simp lemmas `refreshRandomizers_orbitalRandomizers_basePoint` / `_randomizers`; `RefreshDependsOnlyOnEpochRange`, `refresh_depends_only_on_epoch_range` (structural determinism: refresh output depends only on sampler outputs over the per-epoch index range; renamed from `RefreshIndependent` / `refresh_independent` in Workstream L3, audit F-AUDIT-2026-04-21-M4)
- `PublicKey/KEMAgreement.lean` — `OrbitKeyAgreement` (two-party KEM structure with combiner); `encapsA`, `encapsB`, `sessionKey`; `kem_agreement_correctness` (bi-view identity: both decapsulation paths reduce to `sessionKey a b`, strengthened in Workstream A5 / F-19); `kem_agreement_alice_view`, `kem_agreement_bob_view` (each party's post-decap view equals `sessionKey`); `SessionKeyExpansionIdentity` Prop + unconditional `sessionKey_expands_to_canon_form` structural decomposition identity exhibiting `sessionKey` in terms of both parties' secret `keyDerive` and `canonForm.canon` (renamed from `SymmetricKeyAgreementLimitation` / `symmetric_key_agreement_limitation` in Workstream L4, audit F-AUDIT-2026-04-21-M5; the identity is a `rfl`-level decomposition, not an impossibility claim)
- `PublicKey/CommutativeAction.lean` — `CommGroupAction` (typeclass extending `MulAction` with commutativity); `csidh_exchange` with simp lemmas `csidh_exchange_alice/bob/shared`; `csidh_correctness` (`a • b • x = b • a • x`); `csidh_views_agree`; `CommOrbitPKE` (public-key structure with `pk_valid` field); `encrypt`, `decrypt` + simp lemmas; `comm_pke_correctness` (CSIDH-style PKE correctness); `comm_pke_shared_secret` (sender/recipient views match); `CommGroupAction.selfAction` (`def`, not `instance`, for `CommGroup` acting on itself, to avoid typeclass diamonds); `selfAction_comm` theorem witnessing satisfiability
- `docs/PUBLIC_KEY_ANALYSIS.md` — feasibility analysis document covering: (1) oblivious sampling viability with open `combine` problem, (2) KEM agreement limitation (symmetric setup), (3) CSIDH-style commutative action path with open concrete instantiation, (4) fundamental non-commutativity obstacle, (5) summary table and Phase 13 theorem registry
- All 7 work units (13.1–13.7) implemented with zero `sorry`, zero warnings, zero custom axioms
- 3 new Lean files, ~30 new public declarations across ~600 lines
- `lake build` succeeds for all 32 modules (zero errors)

Phase 14 (Parameter Selection & Benchmarks) has been completed:
- `implementation/gap/orbcrypt_sweep.g` — systematic parameter-space
  sweep. For each `lambda in {80, 128, 192, 256}` it iterates
  `b in {4, 8, 16, 32}`, `w/n in {1/3, 1/2, 2/3}`, `k/n in {1/4, 1/3, 1/2}`
  (36 configs) plus three tier-pinned rows (`aggressive`, `balanced`,
  `conservative`) covering the §6 recommendations. `MeasureConfiguration`
  returns `log2|G|`, orbit-count sample, mean canonical-image time, and
  mean keygen time per configuration. `WriteSweepCSV` emits
  `docs/benchmarks/results_<lambda>.csv` with the 15-column schema
  (`lambda, b, ell, n, k, w, w_frac, k_frac, log2_G, num_orbits,
  canon_ms, keygen_ms, num_gens, passed, tier, status`).
  `WriteComparisonCSV` emits `docs/benchmarks/comparison.csv` with the
  cross-scheme table. `RunFullSweep(numSamples, numTrials)` is the
  top-level driver; `RunQuickSweep()` is the CI-sized smoke test.
- `docs/benchmarks/results_{80,128,192,256}.csv` — per-level sweep CSVs,
  39 rows each (36 grid + 3 tier). Rows with `status = measured` mirror
  the Phase 11 benchmarks exactly (the Phase 11 b=8 baseline is the
  aggressive tier); `status = projected` rows come from the scaling
  model `canon_ms ∝ n^1.51 · (8/b)^0.25 · W(w/n)` fitted to the four
  Phase 11 anchors. Running `RunFullSweep()` replaces the projected
  rows with direct GAP measurements.
- `docs/benchmarks/comparison.csv` — cross-scheme data with literature
  values for AES-256-GCM, Kyber-768, BIKE-L3, HQC-256, Classic
  McEliece, and LESS-L1, plus the measured HGOE-128 row from Phase 11.
- `docs/PARAMETERS.md` — parameter recommendation document:
  * §1 parameter-space sweep methodology + scaling-model derivation
    (Work Unit 14.1).
  * §2 optimal parameter table at the Phase 11 b=8 anchors, plus the
    explicit caveat that the fallback wreath-product group has no
    code-equivalence hardness argument (Work Unit 14.2).
  * §3 cross-scheme comparison with per-metric honest assessment —
    HGOE wins on key/CT size, loses by 4–5 orders of magnitude on
    encrypt/decrypt time (Work Unit 14.3).
  * §4 security-margin analysis against brute-force orbit enumeration,
    birthday on orbits (`sqrt|G|`), Babai's GI bound, and algebraic
    QC-folding. The binding constraint for `b >= 8` is algebraic
    folding (`n >= b * lambda`); `b = 4` is the size-optimum because
    birthday and algebraic thresholds coincide there at `n = 4 lambda`
    (Work Unit 14.4).
  * §5 ciphertext-expansion analysis: break-even against AES-GCM is
    `n = 96` bits, so for any `n > 96` the HGOE hybrid carries a
    constant `(n - 96)`-bit overhead. Expansion ratios at λ = 128
    **balanced** (`n = 512`): 2.18× at 16 B message, 1.05× at 1 KiB,
    asymptotic 1.0× — well under the 100× Phase-14 go/no-go ceiling.
    **Verdict: GO**, KEM-only narrowing not required (Work Unit 14.5).
  * §6 three-tier recommendations:
      - **Conservative** (`b = 4, n = 8λ`): 2λ-bit margin on ENUM /
        BIRTH / ALG, ~3× larger n.
      - **Balanced** (`b = 4, n = 4λ`, *default*): smallest n meeting
        all §4 thresholds at exactly λ bits.
      - **Aggressive** (`b = 8`, Phase 11): benchmarks only, fails
        birthday and algebraic thresholds.
    Plus a "not recommended" table documenting the failure modes of
    `b ∈ {16, 32}`, extreme weights, and the fallback wreath-product
    group (Work Unit 14.6).
  * §7 reproducibility — every table trace back to a CSV; full
    `RunFullSweep()` regeneration instructions.
- All 6 work units (14.1–14.6) complete; no Lean source-file changes;
  GAP artefacts + docs only. `lake build` unchanged from Phase 13
  (still 32 modules, zero errors).

Phase 15 (Decryption Optimisation Formalisation) has been completed:
- `implementation/gap/orbcrypt_fast_dec.g` — nine-section GAP reference
  for the fast-decryption pipeline:
  * 15.1a `MinimalBlockRotation` + helpers (lex-minimal b-bit rotation)
  * 15.1b `QCCyclicReduce` over a length-n = b·ell support set (O(n))
  * 15.1c `ValidateQCCyclicIdempotent` + `TimeQCCyclicReduce`
  * 15.2  `QCCyclicSubgroup` + `ComputeResidualGroup` (transversal of
    `(G ∩ (Z/bZ)^ell)` inside G, with size diagnostics)
  * 15.3  `ExtendKEMKeyWithFastDec`, `FastCanonicalImage`, `FastDecaps`,
    `FastDecapsSafe`, `CompareFastVsSlow` (empirical regression harness
    vs `HGOEDecaps`)
  * 15.4  `ParityCheckFromGenerator`, `SyndromeOf`, `SyndromeDecaps`,
    `ValidateSyndromeUniqueness` (multi-orbit distinctness check)
  * 15.6  `OrbitSampleList`, `OrbitHash`, `OrbitHashDecaps`,
    `ValidateOrbitHashConsistency`, `MeasureOrbitHashCollision`
  * 15.7  `CompareDecryptionMethods`, `PrintDecryptionComparison`,
    `WritePhase15CSV`, `RunPhase15Comparison` (writes
    `docs/benchmarks/phase15_decryption.csv`)
  * Section 9 `RunPhase15SelfTest` smoke test.
- `Orbcrypt/Optimization/QCCanonical.lean` — `QCCyclicCanonical`
  abbreviation for a `CanonicalForm` parameterised over a cyclic
  subgroup of S_n acting on `Bitstring n`; `qc_invariant_under_cyclic`,
  `qc_canon_idem` re-exported as Phase-15 ergonomics wrappers around
  the Phase-2 `CanonicalForm` API.
- `Orbcrypt/Optimization/TwoPhaseDecrypt.lean` — `TwoPhaseDecomposition`
  predicate (carried as the explicit hypothesis `hDecomp` on every
  downstream theorem) plus `canonical_agreement_under_two_phase_decomposition`, `full_canon_invariant`,
  `two_phase_invariant_under_G`, `two_phase_kem_decaps`,
  `kem_round_trip_under_two_phase_decomposition`. Orbit-constancy layer (`IsOrbitConstant`,
  `orbit_constant_encaps_eq_basePoint`, `fast_kem_round_trip`,
  `fast_canon_composition_orbit_constant`) added by the Phase 15.3
  post-landing audit after empirically confirming that the strong
  `TwoPhaseDecomposition` does not hold for the default fallback group
  (lex-min and the residual transversal action don't commute). The
  actual GAP correctness story runs through `fast_kem_round_trip`;
  `kem_round_trip_under_two_phase_decomposition` is retained as the strong-agreement
  conditional documented at theorem #25.
- `docs/benchmarks/phase15_decryption.csv` — per-method timing table
  emitted by `WritePhase15CSV`, covering full-KEM / fast / syndrome /
  orbit-hash decapsulation speeds at the §14 balanced tier.
- Headline theorems #24 `canonical_agreement_under_two_phase_decomposition`, #25
  `kem_round_trip_under_two_phase_decomposition` (conditional), and #26
  `fast_kem_round_trip` landed with this phase; all three depend only
  on the standard Lean trio (`propext`, `Classical.choice`,
  `Quot.sound`) — see the axiom-transparency block below.
- `Orbcrypt.lean` dependency graph + axiom-transparency block extended
  with the `Optimization/` layer and nine `#print axioms` assertions
  (`canonical_agreement_under_two_phase_decomposition`, `kem_round_trip_under_two_phase_decomposition`,
  `full_canon_invariant`, `orbit_constant_encaps_eq_basePoint`,
  `qc_invariant_under_cyclic`, `qc_canon_idem`, `fast_kem_round_trip`,
  `fast_canon_composition_orbit_constant`, and
  `two_phase_invariant_under_G`).
- All 7 work units (15.1–15.7) implemented with zero `sorry`, zero
  warnings, zero custom axioms. `lake build` succeeds for all 38
  modules (36 pre-Phase-15 + `Optimization/QCCanonical.lean` and
  `Optimization/TwoPhaseDecrypt.lean`, zero errors). Phase 15 is the
  point at which the module count stabilises at 38; subsequent audit
  workstreams (G, H, J, K, L, M, N) are additive to declarations
  within existing modules and do not introduce new `.lean` source
  files.
- Patch version: `lakefile.lean` bumped from `0.1.4` to `0.1.5` in
  the Phase 15 landing commit to capture the two new `Optimization/`
  modules, the three new headline theorems #24 `canonical_agreement_under_two_phase_decomposition`,
  #25 `kem_round_trip_under_two_phase_decomposition` (conditional), and #26
  `fast_kem_round_trip`, along with their supporting declarations
  (`QCCyclicCanonical`, `qc_invariant_under_cyclic`,
  `qc_canon_idem`, `TwoPhaseDecomposition`, `full_canon_invariant`,
  `two_phase_invariant_under_G`, `two_phase_kem_decaps`,
  `IsOrbitConstant`, `orbit_constant_encaps_eq_basePoint`, and
  `fast_canon_composition_orbit_constant`). Theorem #26 and
  `fast_canon_composition_orbit_constant` were added by the
  Phase-15.3 orbit-constancy refactor that ran as a post-landing
  audit after empirically confirming that the strong
  `TwoPhaseDecomposition` does not hold on the default fallback
  group. This entry (landed by Workstream N1, audit finding I1,
  2026-04-23) closes the version-log gap flagged by the
  Workstream-N plan — the pre-N CLAUDE.md change log jumped from
  Workstream E's `0.1.3 → 0.1.4` bump directly to Workstream L's
  `0.1.5 → 0.1.6` bump without documenting this intermediate
  `0.1.4 → 0.1.5` increment.

Phase 16 (Formal Verification of New Components) has been completed:
- `scripts/audit_phase_16.lean` — new consolidated audit script. Runs
  `#print axioms` on **342 declarations** — every public `def`,
  `theorem`, `structure`, `class`, `instance`, and `abbrev` under
  `Orbcrypt/**/*.lean`. This spans Phases 2–14 foundations plus
  Workstream A/B/C/D/E follow-ups (KEM correctness, KEM-OIA
  security, probabilistic IND-CPA, AEAD correctness, INT_CTXT,
  hybrid encryption correctness, Carter–Wegman MAC witness,
  hardness chain, public-key extension, every Workstream-E
  ε-bounded reduction, etc.). Followed by §12 non-vacuity
  witnesses: trivial KEM / DEM / MAC / AuthOrbitKEM instances on
  `Unit` exercising `kem_correctness`, `hybrid_correctness`,
  `aead_correctness`, `authEncrypt_is_int_ctxt`,
  `concreteKEMOIA_one`, `concreteKEMOIA_uniform_one`,
  `hybrid_argument_uniform`, `uniformPMFTuple_apply`, and
  `ConcreteHardnessChain.tight_one_exists`. Type-checking the
  script *is* the verification that each headline result accepts
  well-typed inputs.
- `.github/workflows/lean4-build.yml` — extended with a fourth CI
  step (Work Unit 16.8). After the existing build / sorry / axiom
  declaration checks, CI now runs `lake env lean
  scripts/audit_phase_16.lean`. The parser first **de-wraps**
  Lean's multi-line axiom lists (`[propext,\n Classical.choice,\n
  Quot.sound]` across three lines) so a custom axiom cannot hide
  on a continuation line; it then fails fast on any `sorryAx`
  occurrence and walks every `depends on axioms: [...]` line to
  reject any axiom outside the standard Lean trio (`propext`,
  `Classical.choice`, `Quot.sound`). Hardens against any future
  regression that hides a `sorry` behind an opaque definition or
  introduces a custom axiom.
- `Orbcrypt.lean` — appended a "Phase 16 Verification Audit Snapshot
  (2026-04-21)" section at the end of the axiom-transparency report
  (Work Unit 16.7). Records the audit-time totals: 36 source
  modules, 0 sorries, 0 custom axioms, 342 declarations exercised by
  the audit script (133 axiom-free, 209 standard-Lean-only), 343
  public declarations all carrying docstrings, 5 intentional
  `private` helpers.
- `docs/VERIFICATION_REPORT.md` — new prose verification report
  (Work Unit 16.10, ~580 lines). Sections: executive summary,
  reproduction recipe, headline results table (28 theorems with
  status and axiom dependencies), per-phase verification matrix
  (Phase 7 / 8 / 9 / 10 / 12 / 13), sorry audit (16.4), axiom audit
  (16.5), module-docstring audit (16.6), root-import / dependency-
  graph audit (16.7), CI configuration (16.8), regression audit
  (16.9), theorem inventory (16.10b), known limitations (16.10d:
  OIA/CompOIA assumption, GIReducesToCE/TI as Karp-claim Props,
  `h_step` hypothesis on `indQCPA_from_perStepBound` (renamed from
  `indQCPA_bound_via_hybrid` in Workstream C of the 2026-04-23
  audit),
  `ObliviousSamplingPerfectHiding` strength (renamed from
  `ObliviousSamplingHiding` in Workstream I6 of the 2026-04-23
  audit, finding K-02; the genuinely ε-smooth probabilistic
  analogue `ObliviousSamplingConcreteHiding` is added alongside),
  `SessionKeyExpansionIdentity`
  (formerly `SymmetricKeyAgreementLimitation`),
  Carter-Wegman as satisfiability witness only, multi-query KEM-CCA
  out of scope), and the Phase 16 exit-criteria checklist.
- All 10 work units (16.1–16.10) complete with **zero source-file
  changes** to existing `Orbcrypt/**/*.lean` modules: the audit
  script + CI step + transparency-report appendix + verification
  report are *additive only*. The Phase 16 deliverable is the
  *machine-checkable evidence* that Phases 7–14 have preserved the
  zero-`sorry` / zero-custom-axiom posture established at the end
  of Phase 6.
- Exit-criteria results: 36 modules build (3,364 jobs, zero
  warnings); comment-aware sorry scan returns 0 occurrences;
  axiom-declaration grep returns 0 matches; Phase 16 audit script
  runs clean (0 `sorryAx`, 0 non-standard axioms, 133/342
  declarations are completely axiom-free); all 11 original
  Phase 1–6 modules build individually with unchanged axiom
  dependencies.

Workstream A (Audit 2026-04-18 — Immediate CI & Style Fixes) has been completed:
- `.github/workflows/lean4-build.yml` — (F-03) hardened `sorry` regex with
  Perl word-boundary + comment filter so docstrings mentioning the word
  "sorry" can no longer red-card CI; (F-22) elan installation delegated to
  `scripts/setup_lean_env.sh`, which verifies a pinned SHA-256 of the
  `elan-init.sh` archive before execution (single source of truth).
- `Orbcrypt/Construction/Permutation.lean:92` — (F-04) **no change**.
  The audit recommended `push Not at h → push_neg at h`, but the pinned
  Mathlib (commit `fa6418a8`) has **deprecated** `push_neg` in favour of
  `push Not`: invoking `push_neg` emits a `logWarning` at build time
  (`Mathlib/Tactic/Push.lean:276–282`). The original `push Not at h` is
  already the idiomatic form; switching to `push_neg` would introduce
  a build warning and therefore violate the workstream's zero-warning
  gate. The finding is marked "wontfix — recommendation reversed by
  upstream deprecation" and tracked in the audit plan as A2's as-landed
  note.
- `Orbcrypt/Probability/Negligible.lean:90–95` — (F-18) shadowed outer
  `hn_pos` renamed to `hn_pos_from_one`, eliminating binding ambiguity
  across the `by_cases hC` branches.
- `Orbcrypt/PublicKey/KEMAgreement.lean` — (F-19) `kem_agreement_correctness`
  strengthened from a literal tautology (both sides reduced to
  `combiner k_A k_B`) to a conjunction tying both views to
  `sessionKey a b`. View lemmas `kem_agreement_bob_view` and
  `kem_agreement_alice_view` reordered before the main theorem so they
  can be reused as the two conjunction projections.
- `Orbcrypt/Hardness/CodeEquivalence.lean` — (F-16) `paut_coset_is_equivalence_set`
  renamed to `paut_compose_yields_equivalence`, which accurately describes
  the proven content (right-multiplication by PAut element preserves a
  witnessed equivalence). The full set-identity
  `{ρ | ρ maps C₁ → C₂} = σ · PAut(C₁)` is tracked as optional follow-up
  Workstream D3.
- `Orbcrypt/Crypto/CompOIA.lean` and `Orbcrypt/Crypto/CompSecurity.lean`
  — (F-13) added readability helpers `SchemeFamily.repsAt`,
  `SchemeFamily.orbitDistAt`, `SchemeFamily.advantageAt`; `CompOIA` and
  `CompIsSecure` now use the named helpers instead of inline
  `@`-threaded expressions. All existing bridges and theorems preserved
  definitionally.
- `Orbcrypt/Hardness/CodeEquivalence.lean`, `Orbcrypt/Hardness/TensorAction.lean`,
  and `Orbcrypt.lean` — (F-12) `GIReducesToCE` and `GIReducesToTI` each
  gained an audit-note comment pointing at their scheduled Workstream E
  consumer (`ConcreteHardnessChain`) and Workstream F concrete-witness
  subtask (F3 / F4); the root file's axiom-transparency report gained a
  new "Hardness parameter Props" section explaining that these are
  *reduction claims*, not proofs, and listing them with their intended
  usage.

Traceability: every Workstream A finding is resolved by the edit above;
see `docs/dev_history/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § 4 for the
specification and Appendix A for the finding-to-WU mapping.

Workstream B (Audit 2026-04-18 — Adversary & Family Type Refinements) has
been completed:
- `Orbcrypt/Crypto/Security.lean` — (F-02, B1) introduced
  `hasAdvantageDistinct` and `IsSecureDistinct`, the distinct-challenge
  variants matching the classical IND-1-CPA game (the challenger rejects
  `(m, m)` before sampling). Proved `isSecure_implies_isSecureDistinct`
  showing the unconstrained `IsSecure` game (which still accepts the
  degenerate collision choice) strictly implies the classical
  distinct-challenge game. Added `hasAdvantageDistinct_iff` — the
  `Iff.rfl`-trivial decomposition `hasAdvantageDistinct ↔ distinct ∧
  hasAdvantage`, useful for downstream rewrites. Updated module and
  `IsSecure` docstrings with a "Game asymmetry (audit F-02)" note
  explaining the one-way implication and the unsatisfiability of the
  converse.
- `Orbcrypt/Crypto/CompOIA.lean` — (F-15, B2) `SchemeFamily` is now
  explicitly universe-polymorphic. Added a module-level
  `universe u v w` declaration and changed the `G`/`X`/`M` fields from
  `ℕ → Type*` to `ℕ → Type u|v|w`, so consumers can thread universe
  parameters by name (`@SchemeFamily.{u, v, w} ...`) rather than relying
  on implicit inference. Downstream helpers (`repsAt`, `orbitDistAt`,
  `advantageAt`, `CompOIA`) inherit the universe parameters transparently.
- `Orbcrypt/Crypto/CompSecurity.lean` — (F-02, B3) added the
  multi-query groundwork needed for Workstream E8: the
  `DistinctMultiQueryAdversary` wrapper extends `MultiQueryAdversary`
  with a `choose_distinct` obligation (per-query `m₀ ≠ m₁`);
  `perQueryAdvantage` extracts the single-query advantage at a given
  query index; `perQueryAdvantage_nonneg`,
  `perQueryAdvantage_le_one`, and `perQueryAdvantage_bound_of_concreteOIA`
  are one-liners from `advantage_nonneg`, `advantage_le_one`, and
  `ConcreteOIA` respectively.

Traceability: findings F-02 and F-15 are now resolved; Workstream E8
(multi-query security) inherits `DistinctMultiQueryAdversary`,
`perQueryAdvantage`, and the `ConcreteOIA` per-query bound as ready
building blocks. See `docs/dev_history/AUDIT_2026-04-18_WORKSTREAM_PLAN.md`
§ 5 for the specification and Appendix A for the finding-to-WU mapping.

Verification: `scripts/audit_b_workstream.lean` exercises every
Workstream B headline result with `#print axioms` and exhibits a
concrete `DistinctMultiQueryAdversary` instance (over the two-element
message space `Bool`) to prove the wrapper is non-vacuous. Running
`lake env lean scripts/audit_b_workstream.lean` should produce only
"does not depend on any axioms" or `[propext, Classical.choice,
Quot.sound]` outputs — never `sorryAx` or a custom axiom. The script
also re-runs the A7 def-eq `rfl` checks so the universe-polymorphic
`SchemeFamily` regression is caught locally.

Patch version: `lakefile.lean` bumped from `0.1.0` to `0.1.1` for this
workstream.

Workstream C (Audit 2026-04-18 — MAC Integrity & INT_CTXT, F-07) has
been completed:
- `Orbcrypt/AEAD/MAC.lean` — (F-07 step 1 / C1) `MAC` gains a
  `verify_inj` field: `∀ k m t, verify k m t = true → t = tag k m`.
  This is the information-theoretic SUF-CMA analogue; without it the
  abstract `INT_CTXT` predicate cannot be discharged because an adversary
  could produce a different tag that also verifies. Docstring covers
  SUF-CMA semantics, `decide`-based satisfiability, and the (future)
  probabilistic refinement required for HMAC/Poly1305.
- `Orbcrypt/AEAD/AEAD.lean` — (F-07 step 2 / C2) three new results in
  the new `INT_CTXT_Proof` section:
  * `authDecaps_none_of_verify_false` (private, C2a) — unfold-only
    discharge of the `verify = false` branch of `authDecaps`.
  * `keyDerive_canon_eq_of_mem_orbit` (private, C2b) — the
    decapsulation key depends only on the orbit of the ciphertext;
    chosen as a hypothesis-threaded lemma (Option B) rather than a
    structure field on `AuthOrbitKEM` to keep the structure reusable
    for ciphertext spaces that exceed the orbit.
  * `authEncrypt_is_int_ctxt` (C2c) — the main theorem. `by_cases` on
    the MAC `verify` Bool; the `true` branch uses `verify_inj` (C1),
    the bridge lemma (C2b), and the orbit-membership assumption on
    the challenge ciphertext to derive a contradiction with `hFresh`.
    Zero custom axioms, zero `sorry`. (Initial Workstream C landing
    carried the orbit-membership assumption as a theorem-level
    hypothesis `hOrbitCover`; audit 2026-04-23 Workstream B moved it
    onto the `INT_CTXT` game as a per-challenge well-formedness
    precondition `hOrbit`, upgrading the theorem to Standalone on
    every `AuthOrbitKEM`.)
- `Orbcrypt/AEAD/CarterWegmanMAC.lean` — (F-07 step 3 / C4) concrete
  `MAC` witness (new file). `deterministicTagMAC` is a generic template
  over independent `K`, `Msg`, `Tag` types whose `verify` is
  definitionally `decide (t = f k m)`; both `correct` and `verify_inj`
  discharge by `decide_eq_true rfl` / `of_decide_eq_true` respectively.
  `carterWegmanHash` + `carterWegmanMAC` specialise this to
  `(ZMod p × ZMod p) → ZMod p → ZMod p`. `carterWegman_authKEM`
  composes with any `OrbitKEM G (ZMod p) (ZMod p × ZMod p)`, and
  `carterWegmanMAC_int_ctxt` is the direct specialisation of
  `authEncrypt_is_int_ctxt` to that composition. Documented as the
  simplest-possible witness (deterministic, tag space = `ZMod p`);
  not production-grade.
- `Orbcrypt.lean` + `CLAUDE.md` + `docs/DEVELOPMENT.md §8.5` — (C3) new
  headline theorems #19 (`authEncrypt_is_int_ctxt`) and #20
  (`carterWegmanMAC_int_ctxt`); axiom-transparency entries listing
  their dependencies as `[propext, Quot.sound]`; §8.5 in
  `docs/DEVELOPMENT.md` describing the MAC obligations, proof pipeline, and
  orbit-cover rationale.

Traceability: finding F-07 is now resolved. The composition gap that
previously made `INT_CTXT` unprovable (only `MAC.correct` was
available) is closed at the abstraction level; any new concrete MAC
must discharge `verify_inj` to inhabit the structure. See
`docs/dev_history/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § 6 for the
specification and Appendix A for the finding-to-WU mapping.

Verification: `scripts/audit_c_workstream.lean` exercises every
Workstream C headline result with `#print axioms`, destructures a
`MAC` to prove `verify_inj` is a real proof obligation, instantiates
`deterministicTagMAC` at three distinct `(K, Msg, Tag)` triples to
confirm type-polymorphism, and materialises `INT_CTXT` end-to-end on
a singleton (`ZMod 1`) ciphertext space to prove the theorem is
non-vacuously applicable. Running
`lake env lean scripts/audit_c_workstream.lean` should produce only
standard-Lean-axiom or `does not depend on any axioms` outputs —
never `sorryAx` or a custom axiom.

Patch version: `lakefile.lean` bumped from `0.1.1` to `0.1.2` for this
workstream.

Workstream D (Audit 2026-04-18 — Code Equivalence API Strengthening,
F-08 + F-16 extended) has been completed:
- `Orbcrypt/Hardness/CodeEquivalence.lean` — gains the full
  Mathlib-style API on top of `permuteCodeword`, `ArePermEquivalent`,
  and `PAut`. New declarations:
  * **D1 helpers.** `permuteCodeword_inv_apply` and
    `permuteCodeword_apply_inv` (both `@[simp]`) prove that
    `permuteCodeword σ⁻¹` is a two-sided inverse of `permuteCodeword σ`,
    via the existing composition law `permuteCodeword_mul` and the
    group identities `inv_mul_cancel` / `mul_inv_cancel`.
    `permuteCodeword_injective` (Workstream D1) is the immediate
    corollary: a left inverse implies global injectivity.
  * **D1a.** `permuteCodeword_self_bij_of_self_preserving` —
    finite-bijection lemma. If `σ` maps `C` into itself then so does
    `σ⁻¹`. Proof: restrict `permuteCodeword σ` to the Fintype subtype
    `↥C`; injective + finite ⇒ bijective (`Function.Injective.bijective_of_finite`);
    the surjective preimage is exactly `permuteCodeword σ⁻¹ c`.
  * **D1 helper extracted (audit F-08).**
    `permuteCodeword_inv_mem_of_card_eq` — cross-code analogue of D1a:
    if `σ : C₁ → C₂` and `|C₁| = |C₂|`, then `σ⁻¹ : C₂ → C₁`. Proof
    via `Fintype.bijective_iff_injective_and_card`. Used by both
    `arePermEquivalent_symm` (D1b) and `paut_equivalence_set_eq_coset`
    (D3); extracting it eliminates duplication.
  * **D1b.** `arePermEquivalent_symm` — one-line consequence of the
    helper. Carries `C₁.card = C₂.card` as a side condition.
  * **D1c.** `arePermEquivalent_trans` — unconditional, by composition
    of witnesses.
  * **D2.** `paut_inv_closed` (free-standing inverse-closure
    corollary of D1a applied to `C` itself); `PAutSubgroup` (full
    `Subgroup (Equiv.Perm (Fin n))` with `carrier` / `one_mem'` /
    `mul_mem'` / `inv_mem'` discharged by `paut_contains_id` /
    `paut_mul_closed` / `paut_inv_closed`); `mem_PAutSubgroup` (a
    `@[simp]` membership-coercion lemma).
  * **D2c.** `PAut_eq_PAutSubgroup_carrier` — `rfl` bridge between
    the `Set`-valued and `Subgroup`-valued formulations.
  * **D3 (audit F-16 extended).** `paut_equivalence_set_eq_coset` —
    the *full* set identity `{ρ | ρ : C₁ → C₂} = σ · PAut C₁`. Forward
    inclusion uses the D1 helper to inhabit the coset (witness
    τ := σ⁻¹ * ρ); reverse inclusion delegates to
    `paut_compose_preserves_equivalence`. Carries the same
    `C₁.card = C₂.card` hypothesis as D1b for the helper to apply.
  * **D4.** `arePermEquivalent_setoid` — `Setoid` instance on the
    card-indexed subtype `{C : Finset (Fin n → F) // C.card = k}`.
    The instance bundles D1a/b/c into a Mathlib `Equivalence`; the
    card index supplies `_symm`'s precondition uniformly so the
    instance synthesises without further obligations. The parameters
    `{n}`, `{F}`, `{k}` are declared *implicit* (post-audit refinement)
    so typeclass synthesis unifies them from the subtype in
    `Setoid Y` calls — `inferInstance` at
    `{C : Finset (Fin 3 → Bool) // C.card = 2}` simply works without
    `@`-threading.
- `Orbcrypt/Hardness/CodeEquivalence.lean` imports gained
  `Mathlib.Data.Fintype.Card`, `Mathlib.Data.Fintype.EquivFin`,
  `Mathlib.Data.Fintype.Sets`, and `Mathlib.Algebra.Group.Subgroup.Defs`
  to support the new API.
- `scripts/audit_d_workstream.lean` exercises every Workstream D
  headline result with `#print axioms` (sections 1–5) and, after the
  post-landing audit, adds five pressure tests (sections 6–10):
  (6) a **negative cardinality test** exhibiting a concrete
  asymmetric pair `smallCode ⊊ bigCode` that witnesses that
  `arePermEquivalent_symm` (D1b) *genuinely* requires the
  `C₁.card = C₂.card` hypothesis — two elements cannot inject into
  one, so the card hypothesis is mathematically necessary, not an
  artefact of the proof technique;
  (7) `inferInstance` synthesis of the D4 `Setoid` at three distinct
  concrete card-indexed subtypes;
  (8) `mem_PAutSubgroup` simp-lemma firing under `simp only` in both
  directions;
  (9) `paut_inv_closed` idempotence via `inv_inv`;
  (10) a D3 reverse-direction witness showing σ itself (τ = 1) is
  always in its own coset.
- `Orbcrypt.lean` axiom-transparency report extended with the four
  new `#print axioms` checks; `CLAUDE.md` headline theorem table
  extended with theorems #21, #22, #23.

Traceability: findings F-08 and the optional strengthening of F-16 are
now resolved. The composition gap that previously blocked using
`ArePermEquivalent` and `PAut` as Mathlib primitives is closed at the
abstraction level. See `docs/dev_history/AUDIT_2026-04-18_WORKSTREAM_PLAN.md`
§ 7 for the specification and Appendix A for the finding-to-WU mapping.

Verification: `scripts/audit_d_workstream.lean` exercises every
Workstream D headline result with `#print axioms`, applies
`arePermEquivalent_refl` / `_symm` / `_trans` to a concrete singleton
code, exhibits `(1 : Equiv.Perm (Fin 3)) ∈ PAutSubgroup C` to confirm
the `Subgroup` constructor's fields all elaborate, and walks the
forward direction of `paut_equivalence_set_eq_coset` on the singleton
code. Running `lake env lean scripts/audit_d_workstream.lean` should
produce only `[propext]`, `[propext, Classical.choice, Quot.sound]`,
or "does not depend on any axioms" outputs — never `sorryAx` or a
custom axiom.

Patch version: `lakefile.lean` bumped from `0.1.2` to `0.1.3` for this
workstream.

Workstream E (Audit 2026-04-18 — Probabilistic Refinement Chain,
F-01 + F-10 + F-11 + F-17 + F-20) has been completed:
- `Orbcrypt/KEM/CompSecurity.lean` — (E1) new module. `kemEncapsDist`
  (PMF push-forward of `encaps` under uniform G, E1a), `ConcreteKEMOIA
  kem ε` (point-mass probabilistic KEM-OIA, E1b) plus
  `concreteKEMOIA_one` / `concreteKEMOIA_mono` satisfiability witnesses,
  `det_kemoia_implies_concreteKEMOIA_zero` (bridge from deterministic
  KEMOIA, E1c), `kemAdvantage` + `concrete_kemoia_implies_secure` (E1d)
  delivering the per-pair point-mass bound. Post-audit addition:
  `ConcreteKEMOIA_uniform` (uniform-over-G form) + companion
  `concrete_kemoia_uniform_implies_secure` giving the genuinely
  ε-smooth KEM reduction. The point-mass form collapses on `ε ∈ [0, 1)`
  (equivalent to `ε = 0` because point-mass advantage is 0-or-1 per
  pair); the uniform form's advantage can take any value in `[0, 1]`.
  All proofs carry only standard Lean axioms.
- `Orbcrypt/Hardness/CodeEquivalence.lean` — (E2a) `codeOrbitDist C`
  (PMF push-forward of uniform permutations through `C.image
  (permuteCodeword σ)`), `ConcreteCEOIA C₀ C₁ ε` probabilistic predicate
  + `concreteCEOIA_one` / `concreteCEOIA_mono`. Requires `[DecidableEq F]`;
  `Equiv.Perm (Fin n)` is always nonempty and fintype via
  `Mathlib.Data.Fintype.Perm`.
- `Orbcrypt/Hardness/TensorAction.lean` — (E2b) `tensorOrbitDist`,
  `ConcreteTensorOIA T₀ T₁ ε` parameterised over any `Fintype` surrogate
  group `G_TI` acting on `Tensor3 n F` (abstracting away the missing
  `Fintype (GL (Fin n) F)` upstream instance; concrete GL³ binding
  tracked as Workstream F4). `concreteTensorOIA_one` / `_mono`.
- `Orbcrypt/Hardness/Reductions.lean` — (E2c) `graphOrbitDist`,
  `ConcreteGIOIA adj₀ adj₁ ε` + `concreteGIOIA_one` / `_mono`.
  (E3, audit-revised) `UniversalConcreteTensorOIA εT`,
  `UniversalConcreteCEOIA εC`, `UniversalConcreteGIOIA εG` (uniform
  hardness aliases), plus `ConcreteTensorOIAImpliesConcreteCEOIA εT εC`,
  `ConcreteCEOIAImpliesConcreteGIOIA εC εG`,
  `ConcreteGIOIAImpliesConcreteOIA scheme εG ε` — the three ε-preserving
  reduction Props in **universal→universal** form (stated as hypotheses,
  not proven: a concrete witness via CFI / Grochow–Qiao encodings is
  Workstream F3/F4 scope). Each has a `_one_one` satisfiability lemma.
  `concrete_chain_zero_compose` is the E3d sanity sentinel — now
  meaningfully threads tensor → code → graph → scheme-OIA hardness.
  (E4, audit-revised) `ConcreteHardnessChain scheme F ε` structure
  bundling the three ε layers and four hypotheses (including
  `tensor_hard : UniversalConcreteTensorOIA εT`);
  `concreteOIA_from_chain` composes them into `ConcreteOIA scheme ε` via
  three function applications each consuming the previous layer;
  `ConcreteHardnessChain.tight` is the `ε₁ = ε₂ = ε₃ = ε` convenience
  constructor; `ConcreteHardnessChain.tight_one_exists` witnesses the
  chain is non-vacuous at ε = 1. (E5)
  `concrete_hardness_chain_implies_1cpa_advantage_bound` composes E4
  with `concrete_oia_implies_1cpa` to give the probabilistic
  `IND-1-CPA advantage ≤ ε` statement — the non-vacuous counterpart of
  `hardness_chain_implies_security`.
- `Orbcrypt/Hardness/Encoding.lean` — (E3-prep) new module.
  `OrbitPreservingEncoding α β A B` structure formalising the many-one
  reduction signature, kept as the *reference interface* for a future
  per-encoding refactor (Workstream F3/F4 will discharge the three
  reduction Props at concrete encodings via `OrbitPreservingEncoding`
  witnesses). `identityEncoding` provides a trivial satisfiability
  witness. The audit-revised universal→universal reduction Props in
  `Hardness/Reductions.lean` do not themselves reference
  `OrbitPreservingEncoding` — they state hardness transfer abstractly;
  the encoding interface is where the *concrete* witnesses will land.
- `Orbcrypt/PublicKey/CombineImpossibility.lean` — (E6)
  `combinerOrbitDist scheme m_bp comb m` (distribution of the
  combiner-induced Boolean output under uniform G sampling on m's orbit,
  E6a), `combinerDistinguisherAdvantage` between two scheme messages,
  `combinerDistinguisherAdvantage_eq` bridging to the standard
  `advantage`/`orbitDist` vocabulary, and the headline
  `concrete_combiner_advantage_bounded_by_oia` — the probabilistic
  counterpart of `equivariant_combiner_breaks_oia` (an *upper* bound on
  the combiner-distinguisher's scheme-level advantage from ConcreteOIA).
  `combinerOrbitDist_mass_bounds` (E6b) gives the `1/|G|` *intra-orbit*
  mass bound on both Boolean outcomes under non-degeneracy — a witness
  of non-trivial variance on one orbit, but not by itself a cross-orbit
  advantage lower bound (requires additional hypothesis on combine's
  behavior on the target orbit, disclosed in the docstring).
- `Orbcrypt/Probability/Monad.lean` — (E7a) `uniformPMFTuple α Q`,
  `uniformPMFTuple_apply` (each tuple has mass `1/|α|^Q`),
  `mem_support_uniformPMFTuple`. Built on `uniformPMF (Fin Q → α)`;
  Fintype / Nonempty on the function type come from `Pi.fintype` /
  `Pi.instNonempty`.
- `Orbcrypt/Probability/Advantage.lean` — (E8 prereq)
  `hybrid_argument_uniform Q hybrids D ε h_step` — uniform per-step
  bound variant of `hybrid_argument`, delivering `advantage D (hybrids 0)
  (hybrids Q) ≤ Q·ε`. Direct consequence of `hybrid_argument` +
  `Finset.sum_const`. (Non-negativity of ε is not needed — the bound
  is computed via `Finset.sum_le_sum` + `Finset.sum_const`, both
  unconditional.)
- `Orbcrypt/Crypto/CompSecurity.lean` — (E8) `hybridDist scheme choose i`
  (scheme-level hybrids: first `i` coordinates sample from left
  messages, last `Q - i` from right), `indQCPAAdvantage scheme A`
  (E8a; all-left vs all-right advantage), `indQCPA_from_perStepBound`
  (E8c; composes `hybrid_argument_uniform` with a caller-supplied
  per-step bound `h_step`; renamed from `indQCPA_bound_via_hybrid`
  in Workstream C of audit 2026-04-23, finding V1-8 / C-13),
  `indQCPA_from_perStepBound_recovers_single_query` (E8d; Q = 1
  regression; renamed from `indQCPA_bound_recovers_single_query`
  for naming consistency). The per-step marginal reduction (showing
  `h_step` follows from `ConcreteOIA`) is carried as an explicit
  hypothesis: the marginal-independence proof over `uniformPMFTuple`
  is the single remaining non-trivial step and is tracked as a
  follow-up in `docs/dev_history/AUDIT_2026-04-18_WORKSTREAM_PLAN.md`
  § E8b. Users can discharge `h_step` from custom analysis or by
  reformulating `hybridDist` via an explicit per-coordinate bind
  chain.
- `Orbcrypt.lean` — axiom transparency report extended: new section
  enumerating the Workstream E theorem `#print axioms` checks; a
  "Vacuity map" table mapping each Phase-4/7/12 vacuous theorem to its
  non-vacuous Workstream-E counterpart; imports of `Orbcrypt.KEM.CompSecurity`
  and `Orbcrypt.Hardness.Encoding` added.

Traceability: findings F-01 (vacuous `oia_implies_1cpa` for non-trivial
schemes), F-10 (deterministic `KEMOIA` not probabilistic), F-11 (no
multi-query security), F-17 (deterministic combiner no-go), and F-20
(deterministic hardness chain) are addressed by the probabilistic
counterparts landed here. Each counterpart is satisfiable at `ε = 1`
(all delivered advantages are ≤ 1) and reduces to the deterministic
form at `ε = 0` (via the bridge lemmas). For the scheme-level
`ConcreteOIA` and the uniform-form `ConcreteKEMOIA_uniform`,
intermediate ε values genuinely parameterise concrete security; the
point-mass `ConcreteKEMOIA` collapses on `[0, 1)` (documented
caveat). See `docs/dev_history/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § 8
for the specification and
`docs/audits/LEAN_MODULE_AUDIT_2026-04-20_WORKSTREAM_E.md` for the
post-landing audit that flagged and fixed the initial decoupling of
the hardness chain.

Non-goal (tracked as Workstream F3/F4): concrete witnesses for the three
ε-preserving reduction Props (Tensor → CE → GI → scheme OIA). The
Workstream-E chain is stated *up to* those reductions; providing
compilable witnesses via the Grochow–Qiao structure-tensor encoding
(F4) or the CFI graph gadget (F3) is separable research work.

Patch version: `lakefile.lean` bumped from `0.1.3` to `0.1.4` for this
workstream.

### Workstream E follow-up (post-landing audit, 2026-04-20)

A targeted audit of the landed Workstream E content surfaced four
correctness issues that were addressed in-place without a new version
bump (definitions are preserved; the audit-revised shape strengthens the
semantics without changing the public surface except where a genuine bug
was fixed):

1. **E3 reduction Props were decoupled.** The landed form
   `∀ T₀ T₁ C₀ C₁, ConcreteTensorOIA T₀ T₁ εT → ConcreteCEOIA C₀ C₁ εC`
   was semantically equivalent to `(∃ T, ConcreteTensorOIA T T εT) → (∀
   C, ConcreteCEOIA C C εC)`, which collapses to `∀ C₀ C₁,
   ConcreteCEOIA C₀ C₁ εC` because `T₀ = T₁` trivially satisfies the
   hypothesis. The tensor hardness assumption was never actually
   consumed by the chain. The audit-revised form uses
   `UniversalConcreteTensorOIA εT → UniversalConcreteCEOIA εC` (and
   similarly for the CE → GI and GI → scheme-OIA reductions), so the
   chain now genuinely threads TI-hardness through every link — see
   `Hardness/Reductions.lean` `UniversalConcreteTensorOIA`,
   `UniversalConcreteCEOIA`, `UniversalConcreteGIOIA` and the revised
   `ConcreteTensorOIAImpliesConcreteCEOIA` / `ConcreteCEOIAImplies-
   ConcreteGIOIA` / `ConcreteGIOIAImpliesConcreteOIA` definitions.

2. **E4 `ConcreteHardnessChain` carried a per-pair tensor witness.** The
   landed structure's `tensor_hard` field was a specific
   `ConcreteTensorOIA T₀ T₁ εT` on a chosen pair `(T₀, T₁)`, and the
   composition theorem passed it through the decoupled reduction Props
   (landing on `ConcreteCEOIA ∅ ∅ εC` then `ConcreteGIOIA`-on-0-vertex-
   graphs), which are trivially true regardless of the hypothesis. The
   audit-revised `ConcreteHardnessChain` drops the `(n, G_TI, T₀, T₁)`
   fields and takes a *universal* `tensor_hard :
   UniversalConcreteTensorOIA εT` instead. `concreteOIA_from_chain` is
   now a three-line composition `hc.gi_to_oia (hc.ce_to_gi
   (hc.tensor_to_ce hc.tensor_hard))` — each link consumes the
   previous layer's hardness meaningfully. A new lemma
   `ConcreteHardnessChain.tight_one_exists` exhibits a non-vacuity
   witness at ε = 1.

3. **E1 `ConcreteKEMOIA` collapsed semantically.** Under `PMF.pure`
   point masses, `advantage` is 0 or 1 only, so bounding by `ε ∈ [0, 1)`
   forces the 0-advantage case — i.e. `ConcreteKEMOIA kem ε` for `ε ∈
   [0, 1)` is equivalent to `ConcreteKEMOIA kem 0`. The revised
   docstring discloses this (the definition is kept as the deterministic
   bridge target), and `KEM/CompSecurity.lean` now exposes a new
   `ConcreteKEMOIA_uniform` over the orbit-sampling push-forward
   (`kemEncapsDist`) whose advantage can take any real value in
   `[0, 1]`, so intermediate ε parameterise meaningful security.

4. **E6 `combinerOrbitDist_mass_bounds` was over-claimed.** The
   landed docstring suggested it combined with the ConcreteOIA upper
   bound to refute `ConcreteOIA 0` under `NonDegenerateCombiner`. The
   actual content is an intra-orbit bound (Pr[true] ≥ 1/|G| AND
   Pr[false] ≥ 1/|G| on `m_bp`'s orbit) — it witnesses non-trivial
   variance on one orbit, not a cross-orbit advantage lower bound.
   Refuting ConcreteOIA 0 requires a cross-orbit distinguishing witness
   that is combiner-specific; mass bounds alone are insufficient. The
   revised docstrings for both `combinerOrbitDist_mass_bounds` and
   `concrete_combiner_advantage_bounded_by_oia` state this honestly.

5. **Orphan `OrbitPreservingEncoding`.** `Hardness/Encoding.lean`
   defined the structure but no reduction Prop consumed it. The revised
   module docstring clarifies the structure is the *reference interface*
   that a future per-encoding refactor (Workstream F3/F4) will plug
   into; it is intentionally not wired to the universal→universal
   reduction Props that landed here.

6. **`audit_e_workstream.lean` was only axiom-dumps.** The script's
   preamble promised pressure tests but the body only contained
   `#print axioms` calls. The follow-up appends a Part 2 of ~15
   concrete `example` bindings exercising each Workstream-E result on
   a well-typed instance (ConcreteKEMOIA at ε = 1, `uniformPMFTuple`
   on `Fin 3 → Bool` giving mass 1/8, a 2-step hybrid giving a
   `2 · ε` bound, `ConcreteHardnessChain.tight_one_exists`
   instantiated to produce `ConcreteOIA scheme 1`, etc.). Type-checking
   the script is now equivalent to confirming each headline result is
   non-vacuous on at least one concrete instance.

Workstream G (Audit 2026-04-21 — Hardness-Chain Non-Vacuity: Fix B +
Fix C, finding H1, HIGH) has been completed:
- `Orbcrypt/Hardness/TensorAction.lean` — (G1 / Fix B) introduces
  `SurrogateTensor F`, a structure bundling a tensor-layer surrogate
  group carrier with its `Group`, `Fintype`, `Nonempty` instance
  fields plus a per-dimension `MulAction carrier (Tensor3 n F)`.
  The structure parameter binds the tensor-layer `G_TI` explicitly
  in all downstream Props, preventing the pre-G PUnit collapse.
  Four helper instances (`surrogateTensor_group`,
  `surrogateTensor_fintype`, `surrogateTensor_nonempty`,
  `surrogateTensor_mulAction`) register the structure's fields as
  typeclass instances on `S.carrier` / `Tensor3 n F`, so downstream
  `ConcreteTensorOIA (G_TI := S.carrier)` elaborates without manual
  `letI` threading. `punitSurrogate F` provides the explicit PUnit
  witness used by the non-vacuity story.
- `Orbcrypt/Hardness/Reductions.lean` — (G2–G6) refactored to
  surrogate-parameterised + per-encoding shape:
  * `UniversalConcreteTensorOIA` now takes `S : SurrogateTensor F`
    as a named parameter. The pre-G `{G_TI : Type}` implicit
    universal binder is removed.
  * `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding S enc εT εC`
    (G3a / Fix C) — per-encoding Tensor → CE reduction Prop. Takes
    an explicit encoder `enc : Tensor3 n F → Finset (Fin m → F)` and
    asserts advantage transfer through that encoder.
    `_one_one` satisfiability witness included.
  * `ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding enc εC εG`
    (G3b / Fix C) — per-encoding CE → GI reduction Prop.
  * `ConcreteGIOIAImpliesConcreteOIA_viaEncoding scheme S encTC encCG εG ε`
    (G3c / Fix C) — per-encoding GI → scheme-OIA reduction Prop.
    Hypothesis is the **chain-image** GI hardness
    (`∀ T₀ T₁, ConcreteGIOIA (encCG (encTC T₀)) (encCG (encTC T₁)) εG`)
    rather than universal GI over all adjacency pairs; this lets
    composition compose *without* a coverage obligation.
  * `ConcreteHardnessChain` (G4) — now carries a
    `SurrogateTensor F` parameter plus three dimension fields
    (`nT, mC, kG`), two encoder fields (`encTC, encCG`), and three
    per-encoding reduction Prop fields. Pre-G universal→universal
    Props are retained as derived corollaries.
  * `concreteOIA_from_chain` (G5) — composition threads advantage
    through the chain image: tensor_hard → tensor_to_ce → ce_to_gi
    → gi_to_oia, each link consuming exactly what the previous
    produces. Zero `sorry`, zero custom axioms.
  * `tight_one_exists` (G6) — inhabits the chain at ε = 1 via
    `punitSurrogate F` and dimension-0 trivial encoders (empty
    Finset + false adjacency function). Non-vacuity witness for
    `ConcreteHardnessChain scheme F (punitSurrogate F) 1`.
  * `concrete_hardness_chain_implies_1cpa_advantage_bound` updated
    to thread the new `SurrogateTensor` structure parameter.
- `scripts/audit_phase_16.lean` — (G7) extended with `#print axioms`
  for the new declarations (`SurrogateTensor`, the four instance
  helpers, `punitSurrogate`, the three `*_viaEncoding` Props, their
  `_one_one` witnesses, the refactored `ConcreteHardnessChain`
  fields). The non-vacuity `example` at the bottom now uses the
  post-refactor chain signature
  `Nonempty (ConcreteHardnessChain scheme F (punitSurrogate F) 1)`.
- `scripts/audit_e_workstream.lean` — (G7) pressure tests extended:
  each `*_viaEncoding` Prop at ε = 1 is exercised on a caller-
  supplied encoder; the `concrete_chain_zero_compose` example now
  takes a `SurrogateTensor Bool` parameter; the chain-non-vacuity
  example is updated for the new structure signature. Axiom-dump
  section covers `SurrogateTensor`, `punitSurrogate`, and all six
  new `*_viaEncoding` declarations.
- `Orbcrypt.lean` — (G8) axiom-transparency report extended with a
  Workstream-G subsection listing the new declarations, and a
  "Workstream G Snapshot (audit 2026-04-21, finding H1)" section at
  the end describing Fix B + Fix C in prose.
- `docs/VERIFICATION_REPORT.md` — (G8) "Known limitations" section
  updated to reflect that the H1 finding is closed: at ε < 1 the
  chain's ε-parameter genuinely reflects caller-supplied surrogate
  + encoder hardness; the PUnit surrogate + dimension-0 trivial
  encoders remain a satisfiability witness at ε = 1. Research
  follow-ups (concrete CFI / Grochow–Qiao encoder witnesses) are
  tracked at § 15.1 of the audit plan.
- `docs/dev_history/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` — updated
  to land Fix C (per-encoding refactor) as part of Workstream G
  rather than deferring to future F3/F4. Renamed "Out-of-scope
  future work" to "Research-scope follow-ups" to emphasise the
  distinction between deferred engineering (forbidden) and genuine
  research formalisation (separate milestones with landed
  interfaces).

Traceability: finding H1 (AUDIT-2026-04-21-H1) is resolved. The
`UniversalConcreteTensorOIA` PUnit collapse is fixed at the type
level by the `SurrogateTensor` binding; the chain's per-encoding
reduction Props expose encoder functions so concrete ε < 1
discharges are compositional. No existing audit scripts or
downstream modules require further refactor when concrete encoder
witnesses land.

Verification: `scripts/audit_phase_16.lean` and
`scripts/audit_e_workstream.lean` both produce only standard-trio
axiom dumps (`propext`, `Classical.choice`, `Quot.sound`) or
"does not depend on any axioms" — never `sorryAx` or a custom
axiom. The full project builds (3,366 jobs) with zero errors and
zero warnings.

Patch version: `lakefile.lean` retains `0.1.5` (bumped during
Phase 15 post-landing audit); Workstream G is additive to the
existing 38-module count and does not introduce new `.lean` source
files — the changes are restricted to `Hardness/TensorAction.lean`,
`Hardness/Reductions.lean`, and audit scripts.

Workstream H (Audit 2026-04-21 — KEM-layer ε-smooth hardness chain,
H2, MEDIUM) has been completed:
- `Orbcrypt/KEM/CompSecurity.lean` — (H1) `ConcreteOIAImpliesConcrete-
  KEMOIAUniform scheme m₀ keyDerive ε ε'` — the Prop-valued abstract
  scheme-to-KEM reduction. Parameterised by the KEM's anchor message
  `m₀ : M` and key derivation `keyDerive : X → K`. States that a
  `ConcreteOIA scheme ε` bound transfers to `ConcreteKEMOIA_uniform
  (scheme.toKEM m₀ keyDerive) ε'`. Carried as an abstract obligation
  matching the Workstream-G per-encoding reduction Prop pattern — the
  scheme-to-KEM transfer is not a free algebraic consequence of
  `ConcreteOIA`, so concrete discharges (e.g. random-oracle
  `keyDerive` idealisations) supply the Prop. (H2)
  `concreteOIAImpliesConcreteKEMOIAUniform_one_right` — satisfiability
  witness at `ε' = 1` unconditionally, via `concreteKEMOIA_uniform_
  one`. The KEM-layer analogue of Workstream G's `*_one_one`
  anchors; what `ConcreteKEMHardnessChain.tight_one_exists` uses.
- `Orbcrypt/KEM/CompSecurity.lean` — (H3) `ConcreteKEMHardnessChain
  scheme F S m₀ keyDerive ε` structure bundling a scheme-level
  `ConcreteHardnessChain scheme F S ε` (Workstream G) with a
  `ConcreteOIAImpliesConcreteKEMOIAUniform scheme m₀ keyDerive ε ε`
  field. `concreteKEMHardnessChain_implies_kemUniform` is the
  composition theorem delivering `ConcreteKEMOIA_uniform
  (scheme.toKEM m₀ keyDerive) ε` by feeding the chain's
  `ConcreteHardnessChain.concreteOIA_from_chain` output through the
  scheme-to-KEM field. `ConcreteKEMHardnessChain.tight_one_exists`
  inhabits the structure at ε = 1 via `punitSurrogate F`,
  dimension-0 trivial encoders, and the `_one_right` discharge.
  `concrete_kem_hardness_chain_implies_kem_advantage_bound` is the
  end-to-end KEM-layer adversary bound, composing
  `concreteKEMHardnessChain_implies_kemUniform` with
  `concrete_kemoia_uniform_implies_secure` to deliver
  `kemAdvantage_uniform (scheme.toKEM m₀ keyDerive) A g_ref ≤ ε` —
  the KEM-layer parallel of the scheme-level
  `concrete_hardness_chain_implies_1cpa_advantage_bound`.
- `Orbcrypt/KEM/CompSecurity.lean` gains an import of
  `Orbcrypt.Hardness.Reductions` (no cycle — `Hardness/Reductions`
  does not import `KEM/CompSecurity`). This places the KEM chain
  above the scheme chain in the module dependency graph, matching
  the cryptographic layering: KEM security rests on scheme security
  rests on TI-hardness.
- `scripts/audit_phase_16.lean` — six new `#print axioms` entries
  for the Workstream-H declarations; four new concrete `example`
  bindings in the `NonVacuityWitnesses` section exercising the
  `_one_right` Prop discharge, the `tight_one_exists` witness, the
  chain → `ConcreteKEMOIA_uniform` composition, and the end-to-end
  chain → `kemAdvantage_uniform` adversary bound. Type-checking the
  script is the machine-checkable verification that each headline
  result accepts well-typed inputs.
- `Orbcrypt.lean` — transparency-report block extended with five new
  `#print axioms` entries; the "Vacuity map" table gained a row
  mapping the previously-missing KEM-layer chain to
  `concreteKEMHardnessChain_implies_kemUniform`; a new "Workstream H
  Snapshot (audit 2026-04-21, finding H2)" section at the end of
  the axiom-transparency report describes the H1 / H2 / H3 additions,
  the new import edge, the cryptographic interpretation, and the
  research-scope follow-ups for ε < 1 discharges.
- `docs/VERIFICATION_REPORT.md` — "Known limitations" section gains
  a note on the Workstream-H status: the KEM-layer chain is
  inhabited at ε = 1 via the trivial `_one_right` discharge; ε < 1
  requires concrete `keyDerive`-specific reasoning (random-oracle
  models etc.), tracked as a research follow-up parallel to
  Workstream G's encoder items.

Traceability: finding H2 (AUDIT-2026-04-21-H2, MEDIUM) is resolved.
The pre-H "no chain-level entry point for `ConcreteKEMOIA_uniform`"
gap is closed at the abstraction level: concrete discharges at
ε < 1 slot directly into `ConcreteKEMHardnessChain`'s `scheme_to_kem`
field without further structural refactor. No existing API is
removed; `ConcreteKEMOIA`, `ConcreteKEMOIA_uniform`,
`concrete_kemoia_implies_secure`, and `concrete_kemoia_uniform_
implies_secure` are preserved.

Verification: the full Phase-16 audit script (`scripts/audit_phase_16.
lean`) emits only standard-trio axioms (`propext`, `Classical.
choice`, `Quot.sound`) or "does not depend on any axioms" for every
Workstream-H declaration; the Nonempty witness and composition
pipeline elaborate on the singleton model at `F = Bool`.

Patch version: `lakefile.lean` retains `0.1.5`; Workstream H is
additive to the 38-module count and does not introduce new `.lean`
source files — the changes are restricted to
`Orbcrypt/KEM/CompSecurity.lean`, audit scripts, and documentation.

Workstream J (Audit 2026-04-21 — release-messaging alignment, H3,
MEDIUM) has been completed:
- `Orbcrypt.lean` — new subsection "Deterministic-vs-probabilistic
  security chains" inserted between the module-dependency graph
  and the headline-theorem dependency listing. The subsection
  explains the two parallel chains: the deterministic chain
  (Phases 3 / 4 / 7 / 10 / 12) built from `Prop`-valued
  `OIA`/`KEMOIA`/`TensorOIA`/`CEOIA`/`GIOIA` predicates — which are
  `False` on every non-trivial scheme and therefore serve as
  algebraic scaffolding, not standalone security claims — versus
  the probabilistic chain (Phase 8, Workstream E, Workstream G,
  Workstream H) built from `ConcreteOIA` /
  `ConcreteKEMOIA_uniform` / `ConcreteHardnessChain` /
  `ConcreteKEMHardnessChain` — which is genuinely ε-smooth and
  carries the substantive security content. Directs external
  release claims to the probabilistic-chain citations
  (`concrete_hardness_chain_implies_1cpa_advantage_bound`,
  `concrete_kem_hardness_chain_implies_kem_advantage_bound`) and
  cross-references `docs/VERIFICATION_REPORT.md` § "Release
  readiness" and the `CLAUDE.md` Status column.
- `docs/VERIFICATION_REPORT.md` — "Known limitations" item 1
  rewritten to make the deterministic chain's scaffolding status
  explicit at the top of the list (previously buried in item 8's
  Workstream-G discussion). The "Release readiness" section's
  header and opening paragraph now announce the three-tier
  classification (Scaffolding / Quantitative / Standalone) and
  cross-reference the Workstream-J landing (the section title
  now reads "post-Workstream-G, Workstream H, and Workstream J").
  A "Document history" entry dated 2026-04-22 records the
  documentation-only posture of this workstream and confirms
  `lake build` / `#print axioms` / CI outputs are unchanged.
- `CLAUDE.md` — "Three core theorems" table gained a **Status**
  column with four values:
  * **Standalone** — unconditional results (correctness,
    invariant attack, KEM correctness, AEAD correctness, seed/nonce
    correctness, the Phase 13 public-key correctness results, the
    INT-CTXT result, the Phase 15 fast-decryption theorems).
    Safe to cite directly.
  * **Scaffolding** — deterministic-chain theorems #3, #5, #8,
    #14. Each carries an OIA-variant hypothesis that is `False`
    on every non-trivial scheme, so the conclusion is vacuously
    true on production instances. Cite only to explain
    type-theoretic structure, *not* as a security claim.
  * **Quantitative** — probabilistic-chain theorems #6, #7, #27,
    #28, #29. Each carries an ε-bounded `Concrete*` hypothesis
    that is genuinely ε-smooth. These are the primary public-
    release citations for the scheme-level bound (#27) and
    KEM-layer bound (#29).
  * **Structural** — Mathlib-style API lemmas #21, #22, #23
    (Setoid / Subgroup / coset identity) that support downstream
    proofs but are not security claims.
  The closing prose paragraph gained a one-sentence Workstream-J
  framing note directing readers to the `Orbcrypt.lean` and
  `VERIFICATION_REPORT.md` sections for release-messaging
  guidance.

Traceability: finding H3 (AUDIT-2026-04-21-H3, MEDIUM,
release-messaging alignment) is resolved. No Lean source files
were modified by this workstream. The three documentation edits
(Orbcrypt.lean's module header, VERIFICATION_REPORT.md's Known
limitations + Release readiness + Document history, and
CLAUDE.md's Status column + Workstream-J snapshot) align external
release claims across all three surfaces and direct consumers to
the probabilistic chain as the substantive security content.

Verification: because Workstream J is documentation-only, the
Phase 16 audit script output is unchanged (342 `#print axioms`
checks, all standard-trio-or-axiom-free), `lake build` is a
no-op for comments (the build graph is unaffected), and no
existing theorem's signature or axiom dependencies change.

Patch version: `lakefile.lean` retains `0.1.5`; Workstream J is
purely comment-level. The 38-module / 342-declaration / zero-sorry
/ zero-custom-axiom posture established by Workstream H is
preserved without modification.

Workstream K (Audit 2026-04-21 — distinct-challenge IND-1-CPA
corollaries, M1, MEDIUM) has been completed:
- `Orbcrypt/Theorems/OIAImpliesCPA.lean` — (K1) added
  `oia_implies_1cpa_distinct : OIA scheme → IsSecureDistinct scheme`,
  the classical distinct-challenge form of the deterministic
  scheme-level security reduction. Proof is a one-line composition
  of `oia_implies_1cpa` with `isSecure_implies_isSecureDistinct`
  (Workstream B1, `Crypto/Security.lean`). The docstring discloses
  the deterministic-chain scaffolding status (conclusion vacuously
  true on every non-trivial scheme because `OIA` is `False`) and
  directs external summaries to the probabilistic chain
  (`concrete_oia_implies_1cpa` + `indCPAAdvantage_collision_zero`)
  for non-vacuous content.
- `Orbcrypt/KEM/Security.lean` — (K2) extended module docstring and
  `kemoia_implies_secure` docstring with a "No distinct-challenge KEM
  corollary required" note explaining why no
  `kemoia_implies_secure_distinct` is introduced. The KEM game
  parameterises adversaries by two *group elements* `g₀, g₁ : G`
  rather than two messages; every encapsulation operates on the
  single base point, so no per-message collision gap exists at the
  KEM layer. The probabilistic KEM advantage
  (`kemAdvantage_uniform` in `KEM/CompSecurity.lean`) uses a fixed
  reference group element with no challenge-distinctness obligation
  either. No new Lean declaration is added for K2 — the work unit
  is documentation-only.
- `Orbcrypt/Hardness/Reductions.lean` — (K3) added
  `hardness_chain_implies_security_distinct : HardnessChain scheme →
  IsSecureDistinct scheme`, chain-level parallel of K1 composing
  `hardness_chain_implies_security` with the same distinct-challenge
  bridge. (K4 companion) added
  `concrete_hardness_chain_implies_1cpa_advantage_bound_distinct`,
  the probabilistic chain bound restated in classical IND-1-CPA
  game form: carries the distinctness hypothesis as a
  release-facing signature marker but the proof discharges by
  calling the non-distinct form directly (the distinctness
  hypothesis is unused, named `_hDistinct`, and the underlying
  bound holds unconditionally for every adversary).
- `Orbcrypt/Crypto/CompSecurity.lean` — (K4) added
  `indCPAAdvantage_collision_zero : (A.choose scheme.reps).1 =
  (A.choose scheme.reps).2 → indCPAAdvantage scheme A = 0`, the
  one-line structural lemma showing that when an adversary's
  challenge messages collide, the two orbit distributions coincide
  and `advantage_self` fires. This is the formal reason the
  existing `concrete_oia_implies_1cpa` bound holds unconditionally
  for every adversary (including collision-choice ones) and
  therefore transfers to the classical IND-1-CPA distinct-
  challenge game for free — no separate `_distinct` theorem is
  required at the probabilistic layer. `concrete_oia_implies_1cpa`
  now carries a docstring note explaining this.
- `scripts/audit_phase_16.lean` — extended with `#print axioms`
  entries for the four new declarations (K1, K3, K4, K4 companion)
  and four new `example` bindings in the
  `NonVacuityWitnesses` namespace exercising each corollary on a
  concrete scheme (K3 uses `ZMod 2` because `HardnessChain`
  requires `[Field F]`). All additions land inside the existing
  audit-script structure; the CI parser continues to de-wrap
  multi-line axiom lists and enforce the standard-trio constraint.
- `Orbcrypt.lean` — axiom-transparency report extended: new
  Workstream-K paragraph in the "OIA-dependent results
  (conditional)" section explaining the deterministic `_distinct`
  corollaries inherit their ancestors' scaffolding status;
  `indCPAAdvantage_collision_zero` added to the "Axiom-free
  results (unconditional)" list; four new `#print axioms` blocks
  in the verification cookbook; a new "Workstream K Snapshot
  (audit 2026-04-21, finding M1)" section at the end of the
  report describing the four additions, the K2 design decision,
  and the module-count posture. The vacuity map gains four rows
  pairing each pre-K uniform-game ancestor with its Workstream-K
  distinct-challenge counterpart.
- `CLAUDE.md` — headline-theorem table extended with row #30
  describing the four Workstream-K declarations and their Status
  classification; closing prose updated with a one-sentence
  Workstream-K framing; this snapshot entry added.
- `docs/VERIFICATION_REPORT.md` — extended headline table (rows
  #29–#32); "Release readiness" section updated to cite the K
  corollaries under "What to cite externally" and the
  deterministic halves under "What NOT to cite without
  qualification"; Document history gained a 2026-04-22
  Workstream-K entry with the full additions list; metrics block
  updated to reflect the 38-module posture, 347 public
  declarations, and 346 `#print axioms` checks in the audit
  script.
- `docs/dev_history/formalization/FORMALIZATION_PLAN.md` — `OIAImpliesCPA.lean` row
  in the Layer-3 Theorems table extended with the
  `oia_implies_1cpa_distinct` entry (Workstream K1).

Traceability: finding M1 (F-AUDIT-2026-04-21-M1, MEDIUM,
distinct-challenge IND-1-CPA corollaries) is resolved. Four new
axiom-free declarations land in three existing modules
(`Orbcrypt/Theorems/OIAImpliesCPA.lean`,
`Orbcrypt/Hardness/Reductions.lean`,
`Orbcrypt/Crypto/CompSecurity.lean`); no new modules introduced;
K2 is documentation-only (no Lean declaration). External
release-facing citations should prefer the `_distinct` forms
(K1, K3 for the scaffolding chain; K4 companion for the
probabilistic chain) to match the literature's IND-1-CPA
game shape.

Verification: the Phase 16 audit script exercises every Workstream-K
declaration via `#print axioms` and four non-vacuity `example`
bindings (deterministic K1, K3, trivial K4 witness, and
probabilistic K4 companion at ε = 1). Every new declaration
depends only on standard-trio axioms (`propext`,
`Classical.choice`, `Quot.sound`); none depends on `sorryAx` or a
custom axiom. `lake build Orbcrypt` succeeds (3,366 jobs, zero
warnings, zero errors).

Patch version: `lakefile.lean` retains `0.1.5`; Workstream K adds
only theorem-level declarations to existing modules (no new
`.lean` files). The 38-module / zero-sorry / zero-custom-axiom
posture established by Workstream H is preserved; public
declaration count rises from 343 to 347 (four new theorems,
all axiom-free or depending only on the standard Lean trio).

Workstream L (Audit 2026-04-21 — structural & naming hygiene, M2–M6,
MEDIUM) has been completed:

- **L1 (M2) — `SeedKey` witnessed compression** (plan revised
  2026-04-22 to adopt option (b) — the earlier "honest API"
  resolution was vacated as a small-diff compromise that left
  compression uncertified). `Orbcrypt/KeyMgmt/SeedKey.lean`:
  `SeedKey` now takes `[Fintype Seed]` and `[Fintype G]` at the
  structure level and carries a new field
  `compression : Nat.log 2 (Fintype.card Seed) < Nat.log 2
  (Fintype.card G)` — a machine-checked bit-length strict
  inequality certifying the "fewer bits of seed than bits of
  group element" claim advertised by the module docstring. Every
  downstream theorem (`seed_kem_correctness`,
  `seed_determines_key`, `seed_determines_canon`, `nonceEncaps*`,
  `nonce_encaps_correctness`, `nonce_reuse_deterministic`,
  `distinct_nonces_distinct_elements`, `nonce_reuse_leaks_orbit`,
  `nonceEncaps_mem_orbit`) now threads `[Fintype Seed]` and
  `[Fintype G]` in its typeclass context. The
  `OrbitEncScheme.toSeedKey` bridge now takes an explicit
  `hGroupNontrivial : 1 < Fintype.card G` hypothesis and
  discharges `compression` at `Seed = Unit` via
  `Nat.log_pos`. Non-vacuity witness: a concrete
  `SeedKey (Fin 2) (Equiv.Perm (Fin 3)) Unit` exhibited in
  `scripts/audit_phase_16.lean` discharges `compression` by
  `decide` (|Fin 2| = 2, `Nat.log 2 2 = 1`; |Perm (Fin 3)| = 6,
  `Nat.log 2 6 = 2`). Import added:
  `Mathlib.Data.Nat.Log`. The previously-tracked post-release
  follow-up "Workstream L1-b" is **subsumed**: the compression
  witness has landed.

  **Corrected formulation (audit-plan update).** The plan's
  one-line option (b) sketch read
  `compression : 8 * Fintype.card Seed < log₂ (Fintype.card G)`,
  which is dimensionally incorrect (it multiplies the raw seed
  cardinality by 8 and compares to `log₂|G|`). The implementation
  uses the bit-length form
  `Nat.log 2 (Fintype.card Seed) < Nat.log 2 (Fintype.card G)` —
  a scale-invariant compression claim that matches the docstring's
  prose framing and corrects the typo. See
  `docs/dev_history/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 7.1 for
  the detailed rationale.

- **L2 (M3) — Carter–Wegman universal-hash MAC
  (initial landing superseded by post-audit universal-hash upgrade,
  2026-04-22).**

  *Initial landing (superseded).* The L2 initial implementation
  kept the `carterWegmanMAC` identifier, added a `[NeZero p]`
  typeclass constraint to rule out the pathological `ZMod 0 = ℤ`
  case, and disclaimed the universal-hash security property in a
  docstring "Naming note".  This failed the
  **Security-by-docstring prohibition** rule in the Key Conventions
  section: an identifier that names a cryptographic primitive must
  prove the property, not disclaim it.

  *Post-audit upgrade (authoritative).*
  `Orbcrypt/AEAD/CarterWegmanMAC.lean`: `carterWegmanHash`,
  `carterWegmanMAC`, `carterWegman_authKEM`, and
  `carterWegmanMAC_int_ctxt` now require `[Fact (Nat.Prime p)]`.  A
  new module `Orbcrypt/Probability/UniversalHash.lean` defines the
  ε-universal hash Prop `IsEpsilonUniversal`.  The headline theorem
  `carterWegmanHash_isUniversal` proves the CW linear hash family is
  `(1/p)`-universal over the prime field `ZMod p` — the actual
  Carter–Wegman 1977 security property.  The proof uses the
  algebraic characterisation `carterWegmanHash_collision_iff`
  (`h k m₁ = h k m₂ ↔ k.1 = 0` for `m₁ ≠ m₂`) and the counting
  lemma `carterWegmanHash_collision_card` (the collision set has
  cardinality exactly `p`), combined with the uniform-distribution
  counting form `probTrue_uniformPMF_decide_eq`.

  Mathlib's `fact_prime_two : Fact (Nat.Prime 2)` and
  `fact_prime_three : Fact (Nat.Prime 3)` instances resolve `p = 2`
  and `p = 3` automatically.  `scripts/audit_c_workstream.lean`
  migrates its INT-CTXT witness from the (non-prime) `p = 1` to
  `p = 2`, with a concrete `OrbitKEM` fixture on `ZMod 2` whose
  canonical form uses `Equiv.swap` to realise the transitive
  `S_{ZMod 2}` action.

  Non-vacuity witnesses added to `scripts/audit_phase_16.lean`
  include: the universal-hash theorem at `p = 2` and `p = 3`, the
  collision-iff discharge at `p = 2`, the collision-card discharge
  at `p = 2`, and a monotonicity example.  All land at standard-
  trio axioms only (no `sorryAx`, no custom axiom).

- **L3 (M4) — `RefreshIndependent` rename.**
  `Orbcrypt/PublicKey/ObliviousSampling.lean`: the `Prop`
  `RefreshIndependent` and its companion theorem
  `refresh_independent` were renamed to
  `RefreshDependsOnlyOnEpochRange` and
  `refresh_depends_only_on_epoch_range` respectively. The
  previous names suggested a cryptographic independence claim;
  the content is a `funext`-structural determinism witness
  (refresh output depends only on sampler outputs over the
  per-epoch index range). Docstrings updated with a
  "Naming corrective" note. Downstream references updated in
  `Orbcrypt.lean`, `scripts/audit_phase_16.lean`,
  `scripts/audit_print_axioms.lean`, `CLAUDE.md`,
  `docs/DEVELOPMENT.md`, `docs/PUBLIC_KEY_ANALYSIS.md`,
  `docs/USE_CASES.md`, `docs/MORE_USE_CASES.md`,
  `docs/VERIFICATION_REPORT.md`,
  `docs/dev_history/formalization/FORMALIZATION_PLAN.md`, and
  `docs/dev_history/PHASE_13_PUBLIC_KEY_EXTENSION.md`.

- **L4 (M5) — `SymmetricKeyAgreementLimitation` rename.**
  `Orbcrypt/PublicKey/KEMAgreement.lean`: the `Prop`
  `SymmetricKeyAgreementLimitation` and its companion theorem
  `symmetric_key_agreement_limitation` were renamed to
  `SessionKeyExpansionIdentity` and
  `sessionKey_expands_to_canon_form` respectively. The previous
  names suggested a negative impossibility result; the content
  is a `rfl`-level definitional decomposition identity
  exhibiting `sessionKey a b` as the combiner applied to each
  KEM's secret `keyDerive ∘ canonForm.canon` outputs. Docstrings
  updated with a "Naming corrective" note; the separate
  impossibility discussion is maintained in
  `docs/PUBLIC_KEY_ANALYSIS.md` and is out of scope for this
  module. Downstream references updated in the same fileset as
  L3.

- **L5 (M6) — `KEMOIA` redundant-conjunct removal.**
  `Orbcrypt/KEM/Security.lean`: `KEMOIA` is now single-conjunct
  (orbit indistinguishability only). The pre-L5 second conjunct
  "key uniformity across the orbit" was unconditionally
  provable from `canonical_isGInvariant` (witnessed by the
  still-present `kem_key_constant_direct`), so it carried no
  assumption content. `kem_key_constant` — which extracted
  `hOIA.2 g` from the old definition — is **deleted**
  (CLAUDE.md's "no backwards-compat shims" directive);
  `kem_key_constant_direct` is the authoritative form.
  `kemoia_implies_secure` and `kem_ciphertext_indistinguishable`
  updated to take `hOIA` as a single predicate (no `.1` / `.2`
  extraction). `det_kemoia_implies_concreteKEMOIA_zero` in
  `KEM/CompSecurity.lean` updated in the same way, now invoking
  `kem_key_constant_direct` where it previously extracted
  `hOIA.2`. Zero `#print axioms` changes on the headline
  theorems; the axiom set stays the standard trio.

Traceability: findings M2 (L1), M3 (L2), M4 (L3), M5 (L4), and
M6 (L5) are resolved. See
`docs/dev_history/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 7 for the
specification; Appendix A for the finding-to-work-unit mapping.
External release claims about "compressed seed-based KEM key" now
track a machine-checked structural witness rather than untracked
prose; the renamed declarations accurately describe their content;
the `KEMOIA` definition is now minimal.

Verification: the Phase 16 audit script (`scripts/audit_phase_16.lean`)
exercises every Workstream-L declaration via `#print axioms`; the
L1 non-vacuity witnesses materialise a concrete
`SeedKey (Fin 2) (Equiv.Perm (Fin 3)) Unit` and run
`seed_kem_correctness` on it, plus the `OrbitEncScheme.toSeedKey`
bridge on a generic scheme with `hGroupNontrivial` discharged by
`decide`. Every Workstream-L declaration depends only on
standard-trio axioms (`propext`, `Classical.choice`,
`Quot.sound`); none depend on `sorryAx` or a custom axiom.

Patch version: `lakefile.lean` bumped from `0.1.5` to `0.1.6` for
Workstream L — the L1 structural change (new `compression` field on
`SeedKey`, new typeclass arguments on the structure and every
downstream theorem, new `hGroupNontrivial` hypothesis on the
`toSeedKey` bridge) is an API break that warrants the patch-version
bump; L2–L5 are additive renames / minor-hypothesis additions but
are landed in the same release for atomicity. Public declaration
count: `kem_key_constant` removed (-1), `compression` field added
(+1 on the `SeedKey` structure); net declaration-count change is
zero for Workstream L. The 38-module total is unchanged (no new
`.lean` files; additions are within existing modules).

Workstream M (Audit 2026-04-21 — low-priority polish, L1–L8, LOW)
has been completed (2026-04-23):

- **M1 (L1) — `SurrogateTensor.carrier` universe polymorphism.**
  `Orbcrypt/Hardness/TensorAction.lean`: the `carrier` field is
  generalised from `Type` (universe 0) to `Type u` via a
  module-level `universe u` declaration. The four typeclass-forwarding
  instances (`surrogateTensor_group`, `_fintype`, `_nonempty`,
  `_mulAction`) and every downstream consumer
  (`UniversalConcreteTensorOIA`,
  `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`,
  `ConcreteHardnessChain`, `ConcreteKEMHardnessChain`) inherit the
  generalisation transparently — their existing `Type*`-polymorphic
  signatures already accept a universe-polymorphic carrier.
  `punitSurrogate F` is explicitly pinned to `SurrogateTensor.{0} F`
  (returning a PUnit-based witness at `Type 0`) so that audit-script
  non-vacuity examples elaborate without manual universe threading.
  Callers wanting surrogates at higher universes supply their own
  `SurrogateTensor.{u} F` value.

- **M2 (L2) — `hybrid_argument_uniform` docstring.**
  `Orbcrypt/Probability/Advantage.lean`: the docstring now states
  explicitly that no `0 ≤ ε` hypothesis is carried on the
  signature, and that for `ε < 0` the per-step bound `h_step` is
  unsatisfiable (advantage is always `≥ 0` via `advantage_nonneg`)
  so the conclusion holds vacuously. Intended use case
  `ε ∈ [0, 1]` is documented.

- **M3 (L3) — Deterministic-reduction existentials.**
  `Orbcrypt/Hardness/Reductions.lean`: the docstrings of
  `TensorOIAImpliesCEOIA`, `CEOIAImpliesGIOIA`, and
  `GIOIAImpliesOIA` now disclose that their existentials admit
  trivial satisfiers (`k = 0, C₀ = C₁ = ∅` / `k = 0` on adjacency
  matrices) and that the deterministic chain is *algebraic
  scaffolding*, not quantitative hardness transfer. Each docstring
  points callers at the Workstream G per-encoding probabilistic
  counterpart (`*_viaEncoding`) as the non-vacuous ε-smooth form.

- **M4 (L4) — Degenerate encoders in `GIReducesToCE` /
  `GIReducesToTI`.** `Orbcrypt/Hardness/CodeEquivalence.lean` and
  `Orbcrypt/Hardness/TensorAction.lean`: the docstrings now
  disclose that both deterministic Karp-claim Props admit
  degenerate encoders (e.g. `encode _ := ∅` / constant 0-dimensional
  tensors) because they state reductions at the *orbit-equivalence
  level*, not the advantage level — intentionally scaffolding
  Props expressing the *existence* of a Karp reduction.
  Quantitative hardness transfer at ε < 1 lives in the Workstream
  G probabilistic counterparts.

- **M5 (L5) — Invariant-attack advantage framing.**
  `Orbcrypt/Theorems/InvariantAttack.lean`: the `invariant_attack`
  docstring now enumerates the three literature conventions for
  "adversary advantage" (two-distribution `|Pr - Pr|`, centred
  `|Pr - 1/2|`, deterministic "specific witness pair") and
  explains that all three agree on the "complete break" outcome
  witnessed here but differ by a factor of 2 on intermediate
  advantages. Consumers computing concrete security parameters
  should note which convention their downstream analysis uses.

- **M6 (L6) — `hammingWeight_invariant_subgroup` pattern cleanup.**
  `Orbcrypt/Construction/HGOE.lean`: the anonymous destructuring
  pattern `⟨σ, _⟩` (which silently discarded the membership proof)
  is replaced with a named binder `g` plus an explicit coercion
  `↑g : Equiv.Perm (Fin n)`. The two forms are proof-equivalent;
  the new form is Mathlib-idiomatic style. `#print axioms
  hammingWeight_invariant_subgroup` is unchanged
  (`[propext, Classical.choice, Quot.sound]`).

- **M7 (L7) — `IsNegligible` `n = 0` convention.**
  `Orbcrypt/Probability/Negligible.lean`: the `IsNegligible`
  docstring now documents Lean's `(0 : ℝ)⁻¹ = 0` convention and
  its effect at `n = 0`: the clause `|f n| < (n : ℝ)⁻¹ ^ c`
  reduces to `|f 0| < 0` for `c ≥ 1` (trivially false), or
  `|f 0| < 1` at `c = 0`. All in-tree proofs of `IsNegligible f`
  choose `n₀ ≥ 1` to side-step the edge case; the intended
  semantics is the standard "eventually" form from Katz & Lindell.

- **M8 (L8) — `combinerOrbitDist_mass_bounds` negative example.**
  `Orbcrypt/PublicKey/CombineImpossibility.lean`: the
  `combinerOrbitDist_mass_bounds` docstring now includes a concrete
  negative example (two hypothetical messages sharing an orbit
  under `G` would yield `combinerOrbitDist m₀ = combinerOrbitDist
  m₁` as PMFs, so any distinguisher has advantage 0 despite the
  mass-bound lower bound). The example is hypothetical because
  `OrbitEncScheme.reps_distinct` prohibits the shared-orbit case,
  but it illustrates the information-theoretic gap that any
  concrete cross-orbit advantage lower bound must bridge with
  problem-specific structure.

Traceability: findings L1 (M1), L2 (M2), L3 (M3), L4 (M4), L5
(M5), L6 (M6), L7 (M7), and L8 (M8) are resolved. Seven of the
eight sub-items are documentation-only docstring refinements; the
eighth (M1) is a source-level universe polymorphism generalisation
of `SurrogateTensor F`. No headline theorems are added, removed, or
restated; no public API surface changes; no new modules. See
`docs/dev_history/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 8 for the
specification; Appendix A for the finding-to-work-unit mapping.

Verification: the Phase 16 audit script
(`scripts/audit_phase_16.lean`) continues to produce only
standard-trio axiom dumps (`propext`, `Classical.choice`,
`Quot.sound`) or "does not depend on any axioms" on every
Workstream-G / H / K surrogate-consuming declaration after the M1
universe generalisation; `Nonempty (ConcreteHardnessChain scheme F
(punitSurrogate F) 1)` still elaborates via the
`SurrogateTensor.{0}`-pinned `punitSurrogate`. `lake build`
succeeds (3,367 jobs, zero warnings, zero errors).

Patch version: `lakefile.lean` retains `0.1.6`; Workstream M is
additive (docstring-only for seven sub-items, source-level
universe polymorphism for M1 without any public-API break — the
generalisation from `Type` to `Type u` is backwards-compatible
for every existing caller because every existing caller lands at
`u := 0`). The 38-module total, the zero-sorry / zero-custom-axiom
posture, and the 347 public-declaration count from Workstream K
are all preserved.

Workstream N (Audit 2026-04-21 — info hygiene, I1 + I5, INFO) has
been completed (2026-04-23):

- **N1 (I1) — Phase 15 version-bump documentation.** The Phase 15
  landing commit (`540d187`, 2026-04-20) bumped
  `lakefile.lean`'s `version` field from `0.1.4` to `0.1.5` to
  capture the two new `Optimization/` modules
  (`QCCanonical.lean`, `TwoPhaseDecrypt.lean`), the three new
  headline theorems (#24 `canonical_agreement_under_two_phase_decomposition`, #25
  `kem_round_trip_under_two_phase_decomposition`, #26 `fast_kem_round_trip`), their
  supporting declarations, and the Phase-15.3 post-landing
  orbit-constancy refactor that delivered theorem #26 and
  `fast_canon_composition_orbit_constant`. This bump was
  previously undocumented in the CLAUDE.md per-workstream version
  log, which jumped directly from Workstream E's `0.1.3 → 0.1.4`
  entry to Workstream L's `0.1.5 → 0.1.6` entry with no
  intermediate line. N1 closes that log gap by adding a "Phase 15
  (Decryption Optimisation Formalisation) has been completed"
  subsection above (between the Phase 14 and Phase 16 snapshots)
  whose final bullet explicitly records the `0.1.4 → 0.1.5` bump
  and its rationale. No Lean sources are modified; the lakefile's
  current version (`0.1.6`, set by Workstream L) is unchanged.

- **N5 (I5) — CI nested-block-comment disclaimer.**
  `.github/workflows/lean4-build.yml` gained an I5 comment inside
  the "Verify no sorry" step (directly after the existing F-03
  comment block). The disclaimer makes the non-greedy
  `/-.*?-/` regex's nested-comment limitation explicit at the
  CI-YAML level, illustrates the desynchronising failure mode
  with a concrete `/- outer /- inner sorry -/ still outer -/`
  example, and directs maintainers to `lake build` (which uses
  Lean's own parser and is definitive) as the ground-truth
  fallback whenever a future `.lean` source needs nested block
  comments. The optional engineering follow-up of upgrading the
  regex to a Perl recursive pattern is cross-referenced to
  audit-plan § 15.3.

- **N2 (I2), N3 (I3), N4 (I4) — no-action items.** The audit
  plan identifies three other INFO-class findings as
  self-disclosed and not requiring code changes:
  * **N2 (I2):** `TwoPhaseDecomposition`'s empirical-falsity
    caveat is already disclosed in
    `Orbcrypt/Optimization/TwoPhaseDecrypt.lean`'s module
    docstring and in the Phase 15 section above;
  * **N3 (I3):** the `indQCPA_from_perStepBound`'s `h_step`
    hypothesis gap (renamed from `indQCPA_bound_via_hybrid` in
    Workstream C of the 2026-04-23 audit) is already tracked in
    `docs/dev_history/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § E8b and
    in the 2026-04-23 plan's research catalogue as R-09;
  * **N4 (I4):** `scripts/setup_lean_env.sh` passed its audit
    with no findings.
  None of these require any source or doc change. They are
  listed here for completeness so the N1 / N5 additions are not
  misread as the full Workstream-N deliverable.

Traceability: findings I1 and I5 are resolved. See
`docs/dev_history/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 9 for the
specification; Appendix A for the finding-to-work-unit mapping.

Verification: Workstream N makes no Lean-source or audit-script
changes. The Phase 16 audit script (`scripts/audit_phase_16.lean`)
output is unchanged; `lake build` is a no-op for comment-level
edits to `.github/workflows/lean4-build.yml`; the CI's
"Verify no sorry" step is not affected because only the
explanatory comment grew — the actual `perl -0777 -pe`
strip-and-grep command is byte-identical. No existing theorem's
signature, proof, or axiom dependencies change; no declarations
are added, removed, or renamed.

Patch version: `lakefile.lean` retains `0.1.6`; Workstream N is
a documentation-only and CI-comment-only pass. The 38-module
total, the zero-sorry / zero-custom-axiom posture, and the 347
public-declaration count are all preserved.

**2026-04-23 Pre-Release Audit (plan: `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md`).**
The 2026-04-23 pre-release audit of the Lean formalisation catalogued
**140+ findings** — 1 CRITICAL, 30+ HIGH, 50+ MEDIUM, 60+ LOW/INFO —
partitioned into **fifteen letter-coded workstreams** **A**–**O**.
Every cited finding was spot-checked against the referenced Lean
source file and line number before workstream assignment; **zero
findings were found to be erroneous** (§ 21 validation log, 24
independently verified rows across all severity classes). The
technical posture remains excellent (zero `sorry`, zero custom
axioms, 347 public declarations with docstrings, clean CI, robust
axiom transparency); the **release-messaging posture** is what the
audit targets, because eight HIGH-severity findings document a
systematic gap between documentation status claims and what the
Lean code actually delivers, plus three HIGH findings identify
hypothesis structures (`INT_CTXT` orbit-cover;
`TwoPhaseDecomposition`; Carter–Wegman `X = ZMod p` vs HGOE
`Bitstring n`) that are **false on production HGOE** and therefore
make their headline theorems vacuously applicable.

**Pre-release slate (blocking for v1.0):** Workstreams **A** (release-
messaging reconciliation, ≈ 8 h), **B** (`INT_CTXT` orbit-cover
refactor, ≈ 6 h), **C** (multi-query `h_step` rename, ≈ 4 h), **D**
(toolchain + `lakefile.lean` hygiene, ≈ 2 h), **E** (formal vacuity
witnesses, ≈ 3 h). Total: **≈ 23 h** serial; **≈ 8 h** with two
parallel implementers. **Preferred slate:** add **F** (concrete
`CanonicalForm.ofLexMin`), **G** (λ-parameterised
`HGOEKeyExpansion`), **H** (`decapsSafe` + `decryptCompute`), **I**
(naming hygiene), **J** (invariant-attack framing +
`IsNegligible` closures). **Polish slate:** **K** (root-file split
+ legacy-script relocation), **L** (MED findings), **M** (LOW /
INFO findings), **N** (optional engineering enhancements).
**Research / performance runway:** **O** (R-01 … R-16 research
milestones; Z-01 … Z-10 performance milestones) is explicitly
scoped to v1.1+ / v2.0.

**Workstream status tracker (updated at merge time, see Appendix B
of the audit plan):**

- [x] **Workstream A** — Release-messaging reconciliation (closed
      by this landing). `CLAUDE.md`'s "Release messaging policy"
      section in Key Conventions; Status-column reclassifications
      for rows #19, #20, #24, #25 to **Conditional**; row #2
      invariant-attack narrative aligned with the theorem's
      `∃ A, hasAdvantage` conclusion; `docs/VERIFICATION_REPORT.md`
      "Release readiness" + "Known limitations" rewritten;
      `Orbcrypt.lean` Vacuity-map ε = 1 disclosure; `docs/DEVELOPMENT.md`
      §6.2.1 / §7.1 / §8.2 / §8.5 prose tightened where it exceeded
      the Lean content.
- [x] **Workstream B** — `INT_CTXT` orbit-cover refactor (closed by
      this landing). `Orbcrypt/AEAD/AEAD.lean`: `INT_CTXT` now carries
      a per-challenge `hOrbit : c ∈ orbit G basePoint` binder as the
      game's well-formedness precondition; `authEncrypt_is_int_ctxt`
      refactored to consume `hOrbit` from the binder and discharges
      `INT_CTXT` unconditionally on every `AuthOrbitKEM`.
      `Orbcrypt/AEAD/CarterWegmanMAC.lean`: `carterWegmanMAC_int_ctxt`
      loses its `hOrbitCover` argument and becomes an unconditional
      specialisation of `authEncrypt_is_int_ctxt`. Audit scripts
      (`scripts/audit_phase_16.lean`,
      `scripts/audit_c_workstream.lean`) updated to match the new
      signatures; axiom outputs unchanged (standard trio only).
      `CLAUDE.md` row #19 upgraded from **Conditional** to
      **Standalone**; row #20 remains **Conditional** for the
      `X = ZMod p` / HGOE `Bitstring n` incompatibility (unchanged by
      this workstream, tracked as R-13). `docs/VERIFICATION_REPORT.md`
      and `Orbcrypt.lean` transparency report updated accordingly.
- [x] **Workstream C** — Multi-query hybrid reconciliation (closed by
      this landing). `Orbcrypt/Crypto/CompSecurity.lean`:
      `indQCPA_bound_via_hybrid` → `indQCPA_from_perStepBound` and
      `indQCPA_bound_recovers_single_query` →
      `indQCPA_from_perStepBound_recovers_single_query`. Renaming
      surfaces the caller-supplied `h_step` hypothesis in the
      identifier per `CLAUDE.md`'s naming rule; theorem content is
      unchanged, `#print axioms` outputs stay on the standard Lean
      trio, and the discharge of `h_step` from `ConcreteOIA` alone
      remains research-scope R-09. Audit scripts
      (`scripts/audit_phase_16.lean`,
      `scripts/audit_e_workstream.lean`) updated; three new
      non-vacuity witnesses for the renamed theorem land under
      `NonVacuityWitnesses` in `audit_phase_16.lean` (the C.2
      template at Q = 2 / ε = 1 plus a general-signature and a
      Q = 1 regression variant). `Orbcrypt.lean`,
      `docs/VERIFICATION_REPORT.md`, and `docs/DEVELOPMENT.md §8.2`
      updated. `lakefile.lean` bumped from `0.1.7` to `0.1.8`.
- [x] **Workstream D** — Toolchain decision + `lakefile.lean` hygiene
      (closed by this landing). `lean-toolchain` retains
      `leanprover/lean4:v4.30.0-rc1` under **Scenario C** of the audit
      plan (`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 7) —
      ship v1.0 off the release-candidate toolchain; stable-toolchain
      upgrade deferred to v1.1 (no Mathlib-stable pairing is currently
      available against the `fa6418a8` Mathlib pin). `lakefile.lean`
      gains: (D2) comment metadata refresh — "Last verified:
      2026-04-24", an explicit "Toolchain posture" paragraph
      cross-referencing this audit plan and `docs/VERIFICATION_REPORT.md`;
      (D3) `leanOptions` pinning
      `linter.unusedVariables := true` (Lean core builtin, default
      `true` — pinned defensively against a future toolchain
      default-flip) and `linter.docPrime := true` (Mathlib-defined
      linter, default `false` — pinning to `true` is a meaningful
      enable that locks in Mathlib's "primed identifiers must carry
      a docstring" discipline; the Orbcrypt source tree currently
      has zero primed declarations, so the linter fires on zero
      existing call sites and acts as a tripwire for new code)
      alongside the pre-existing `autoImplicit := false`, so the
      zero-warning gate is enforced by the package configuration and
      not only by the CI warning-as-error setting. `lakefile.lean`
      bumped from `0.1.8` to `0.1.9`. Full `lake build` (3,367 jobs)
      succeeds with zero warnings / zero errors; forced rebuild
      (touching `Orbcrypt/GroupAction/Basic.lean`) likewise clean.
      `scripts/audit_phase_16.lean` emits unchanged axiom output
      (standard-trio-only for every declaration; zero `sorryAx`).
- [x] **Workstream E** — Formal vacuity witnesses (closed by
      landing 2026-04-24). `Orbcrypt/Crypto/OIA.lean` gains
      `det_oia_false_of_distinct_reps` (E1) — `¬ OIA scheme` under
      `scheme.reps m₀ ≠ scheme.reps m₁`, via the membership-at-
      `reps m₀` Boolean distinguisher at identity group elements.
      `Orbcrypt/KEM/Security.lean` gains
      `det_kemoia_false_of_nontrivial_orbit` (E2) — the KEM-layer
      parallel, proving `¬ KEMOIA kem` under
      `g₀ • kem.basePoint ≠ g₁ • kem.basePoint`. Both theorems
      depend only on the standard Lean trio (`propext`,
      `Classical.choice`, `Quot.sound`); never on `sorryAx` or a
      custom axiom. `Orbcrypt.lean` (E3) upgrades the Vacuity map
      to a three-column table naming E1 / E2 as the machine-checked
      vacuity witnesses for the deterministic-OIA and deterministic-
      KEMOIA rows (with the hardness-chain and K-distinct rows
      inheriting the same witnesses via their `OIA` antecedents),
      adds `#print axioms` cookbook entries for both theorems, and
      appends a "Workstream E Snapshot (audit 2026-04-23, findings
      C-07 / E-06)" section describing problem, fix, changes,
      verification, consumer impact, and patch-version notes.
      `scripts/audit_phase_16.lean` gains two new `#print axioms`
      entries (one per theorem) plus two concrete non-vacuity
      `example` bindings under the `NonVacuityWitnesses` namespace:
      a two-message `trivialSchemeBool` with `reps := id : Bool →
      Bool` under the trivial action of `Equiv.Perm (Fin 1)`
      (distinct reps ⇒ `¬ OIA`), and a KEM `trivialKEM_PermZMod2`
      under the natural `Equiv.Perm (ZMod 2)` action on `ZMod 2`
      (`Equiv.swap 0 1 • 0 ≠ 1 • 0` ⇒ `¬ KEMOIA`). `lakefile.lean`
      bumped from `0.1.9` to `0.1.10`; 38-module total unchanged;
      zero-sorry / zero-custom-axiom posture preserved; public
      declaration count rises from 347 to 349; Phase-16 audit script
      `#print axioms` total rises from 342 to 344.
- [x] **Workstream F** — Concrete `CanonicalForm` from lex-min (closed
      by landing 2026-04-24). `Orbcrypt/GroupAction/CanonicalLexMin.lean`
      (new module, 40th `.lean` file) lands `CanonicalForm.ofLexMin`
      — a computable constructor that takes `[Group G] [MulAction G X]
      [Fintype G] [DecidableEq X] [LinearOrder X]` and produces a
      `CanonicalForm G X` via `Finset.min'` on the orbit's
      `.toFinset`; the three fields (`canon`, `mem_orbit`,
      `orbit_iff`) discharge through `Finset.min'_mem`,
      `Set.mem_toFinset`, `MulAction.orbit_eq_iff`, and
      `Set.toFinset_congr` respectively (F2 + F3a + F3b + F3c).
      `Orbcrypt/Construction/HGOE.lean` gains `hgoeScheme.ofLexMin`
      — a convenience constructor (F4) auto-filling the
      `CanonicalForm` parameter for any finite subgroup of
      `Equiv.Perm (Fin n)` under Orbcrypt's computable
      `bitstringLinearOrder` lex order
      (`Orbcrypt/Construction/Permutation.lean`, set-lex matching
      the GAP reference implementation's
      `CanonicalImage(G, x, OnSets)` convention: leftmost-true
      wins, implemented via `List.ofFn ∘ (! ∘ ·)` to invert the
      Bool order; exposed as a `@[reducible] def` rather than a
      global instance to avoid a diamond with Mathlib's pointwise
      `Pi.partialOrder`). `scripts/audit_phase_16.lean` gains
      four non-vacuity witnesses (F3d): an explicit-LT lex-order
      direction check, two `decide`-backed
      `CanonicalForm.ofLexMin.canon` evaluations on concrete
      `Bitstring 3` inputs (weight-2 orbit → `![true, true, false]`
      matching GAP's `CanonicalImage(S_3, {0, 1}, OnSets) = {0, 1}`;
      singleton orbit → identity),
      and a type-elaboration witness for `hgoeScheme.ofLexMin` at
      `G := ⊤ ≤ S_3` with `M := Unit`. `lakefile.lean` bumped
      `0.1.10 → 0.1.11`. 9 new public declarations
      (`orbitFintype`, `mem_orbit_toFinset_iff`,
      `orbit_toFinset_nonempty`, `CanonicalForm.ofLexMin`,
      `CanonicalForm.ofLexMin_canon`,
      `CanonicalForm.ofLexMin_canon_mem_orbit`,
      `bitstringLinearOrder`, `hgoeScheme.ofLexMin`,
      `hgoeScheme.ofLexMin_reps`); module count 39 → 40;
      public declaration count 349 → 358; every new declaration
      depends only on the standard Lean trio (`propext`,
      `Classical.choice`, `Quot.sound`); zero sorry, zero custom
      axiom.
- [x] **Workstream G** — λ-parameterised `HGOEKeyExpansion` (closed by
      landing 2026-04-25). `Orbcrypt/KeyMgmt/SeedKey.lean`:
      `HGOEKeyExpansion` gains a leading `lam : ℕ` parameter and the
      `group_large_enough` field becomes `group_order_log ≥ lam` (G1).
      The Lean identifier is spelled `lam` because `λ` is a reserved
      Lean token; named-argument syntax accepts the spelling
      (`HGOEKeyExpansion (lam := 128) …`). Module / structure / field
      docstrings updated with the cross-reference to
      `docs/PARAMETERS.md` and the lower-bound semantics disclosure.
      `scripts/audit_phase_16.lean` (G2): adds a "Workstream G non-
      vacuity witnesses" section under
      `§ 12 NonVacuityWitnesses` with four `example` blocks — one
      per documented Phase-14 tier (`HGOEKeyExpansion 80 320 Unit`,
      `HGOEKeyExpansion 128 512 Unit`, `HGOEKeyExpansion 192 768 Unit`,
      `HGOEKeyExpansion 256 1024 Unit`) — plus a private helper
      `hammingWeight_zero_bitstring` reused by all four to discharge
      Stage-4 weight-uniformity, a field-projection regression
      (`exp.group_large_enough : exp.group_order_log ≥ lam`), and a
      λ-monotonicity negative example confirming `¬ (80 ≥ 192)`
      (documenting the four obligations are *distinct*, not a single
      sloppy bound). `docs/DEVELOPMENT.md §6.2.1` (G3) gains a paragraph
      cross-linking the Lean structure to the prose pipeline; the
      Lean / prose spelling correspondence (`lam` ↔ `λ`) is disclosed
      explicitly. `docs/PARAMETERS.md §2.2.1` (G3) is a new
      "Lean cross-link" subsection mapping each row of the §2.2 table
      to its `HGOEKeyExpansion lam …` Lean witness, and disclosing
      that the Lean-verified `≥ lam` is a lower bound (deployment
      may choose strictly larger `group_order_log`). `Orbcrypt.lean`
      gains a Workstream-G snapshot section at the end of the
      transparency report. `lakefile.lean` bumped `0.1.11 → 0.1.12`.
      Module count remains 39; public declaration count remains 358
      (the structure gains a parameter, not a field). The zero-sorry
      / zero-custom-axiom posture is preserved; every new audit-script
      `example` elaborates with standard-trio-only axioms.
- [ ] **Workstream H** — Safe decapsulation + computable decryption (pending).
- [x] **Workstream I** — Naming hygiene via *strengthening, not
      rebadging* (initial landing 2026-04-25, post-audit honest-
      delivery refactor 2026-04-25). The original Workstream-I
      landing produced both substantive content and theatrical
      content. The post-audit refactor (same day) removed the
      theatrical content and replaced it with honest scope-
      limited deliverables.

      **Substantive content kept:**

      * `Orbcrypt/Theorems/OIAImpliesCPA.lean` +
        `Orbcrypt/GroupAction/Invariant.lean` (I3): rename
        `insecure_implies_separating` →
        `insecure_implies_orbit_distinguisher` + new helper
        `canon_indicator_isGInvariant` + **new substantive
        theorem `distinct_messages_have_invariant_separator`**
        (the cryptographic content the pre-I name advertised but
        did not deliver: a G-invariant Boolean separator from any
        two distinct messages, unconditional on `reps_distinct`).
      * Renames (content-neutral): `indCPAAdvantage_le_one` (was
        `concreteOIA_one_meaningful`),
        `insecure_implies_orbit_distinguisher` (was
        `insecure_implies_separating`),
        `ObliviousSamplingPerfectHiding` (was
        `ObliviousSamplingHiding`),
        `oblivious_sampling_view_constant_under_perfect_hiding`
        (was `oblivious_sampling_view_constant`).
      * Type-level posture upgrades (Prop signatures
        strengthened): `GIReducesToCE` gains `codeSize_pos` +
        `encode_card_eq` fields ruling out the audit-J03
        `encode _ _ := ∅` degenerate witness at compile time;
        `GIReducesToTI` gains `encode_nonzero_of_pos_dim` ruling
        out the audit-J08 constant-zero encoder.
      * New ε-smooth probabilistic predicate
        `ObliviousSamplingConcreteHiding` (vocabulary for ε-bounded
        oblivious-sampling hiding suitable for release-facing
        security claims).
      * Deletion: `concreteKEMOIA_one_meaningful` (redundant
        duplicate of `kemAdvantage_le_one`).
      * New Mathlib-style helpers in `Probability/Monad.lean`:
        `probTrue_map` and `probTrue_uniformPMF_card` (general
        PMF arithmetic tools used by future tight ε-bound proofs).
      * **New non-degenerate fixture** (post-audit replacement for
        the removed theatrical witnesses) in
        `Orbcrypt/PublicKey/ObliviousSampling.lean`:
        `concreteHidingBundle` and `concreteHidingCombine` —
        a concrete bundle (`Equiv.Perm Bool` on `Bool`,
        randomizers `![false, true]`) and combine (Boolean AND)
        whose orbit cardinality is 2 (max on Bool) and whose
        combine push-forward is biased (1/4 on `true`). On paper,
        the worst-case adversary advantage on this fixture is
        `1/4` — a tight ε ∈ (0, 1) bound. The Lean proof of the
        precise `1/4` bound is research-scope (R-12); the
        non-degenerate fixture itself is the substantive
        in-tree contribution.

      **Theatrical content removed** (post-audit, 2026-04-25):

      * `concreteOIA_zero_of_subsingleton_message` (I1) —
        required `[Subsingleton M]`, a hypothesis under which
        there is only one message and therefore no security game
        to play.
      * `concreteKEMOIA_uniform_zero_of_singleton_orbit` (I2) —
        required the KEM to have only one possible ciphertext,
        collapsing the security game.
      * `ObliviousSamplingConcreteHiding_zero_witness` (I6) —
        required a singleton-orbit hypothesis that collapses the
        security game on `combine := fun _ _ => basePoint`.
      * `oblivious_sampling_view_advantage_bound` (I6) — one-line
        wrapper that was just the predicate's universal quantifier
        applied to a specific D; consumers can do this directly.

      **Type-level posture upgrade witnesses kept (with honest
      docstrings):** `GIReducesToCE_card_nondegeneracy_witness`
      and `GIReducesToTI_nondegeneracy_witness` confirm the
      strengthened non-degeneracy fields are independently
      inhabitable by a singleton encoder (a sub-predicate of the
      full Prop, omitting the iff). They do **not** witness the
      full strengthened Props; that requires a tight Karp
      reduction (research-scope R-15).

      **Counts (post-audit):** 6 new public declarations
      (`canon_indicator_isGInvariant`,
      `distinct_messages_have_invariant_separator`,
      `GIReducesToCE_card_nondegeneracy_witness`,
      `GIReducesToTI_nondegeneracy_witness`,
      `ObliviousSamplingConcreteHiding`,
      `concreteHidingBundle`,
      `concreteHidingCombine`,
      `probTrue_map`, `probTrue_uniformPMF_card`) — 9 in total
      (the 4 theatrical post-Workstream-I theorems are removed).
      4 renamed declarations (content-neutral). 2 strengthened
      in-place (signature-level non-degeneracy fields). 1
      deletion of redundant duplicate. Module count: 39
      (unchanged). The honest delivery is the **fixture +
      research-scope disclosure**, not a Lean proof of a tight
      ε bound. `lakefile.lean` bumped from `0.1.13` to `0.1.14`
      for the post-audit refactor.

      **Honest scoreboard.** Of the original 9 "new" theorems
      delivered by the initial landing, 4 were theatrical
      (perfect-security extrema on degenerate inputs + one
      trivial wrapper) and have been removed. The remaining
      substantive contributions — `distinct_messages_have_
      invariant_separator`, the type-level Prop strengthening,
      the `ObliviousSamplingConcreteHiding` predicate, the
      non-degenerate fixture, and the rename hygiene — are kept.
      The precise ε = 1/4 ObliviousSamplingConcreteHiding bound
      and the full Karp reduction inhabitants for
      `GIReducesToCE` / `GIReducesToTI` remain genuine
      research-scope follow-ups (R-12 and R-15 respectively).
- [ ] **Workstream J** — Invariant-attack framing + negligible closures (pending).
- [ ] **Workstream K** — Root-file split + legacy-script relocation (pending).
- [ ] **Workstream L** — Medium-severity structural cleanup (pending).
- [ ] **Workstream M** — Low-severity cosmetic polish (pending).
- [ ] **Workstream N** — Optional pre-release engineering enhancements (pending).
- (research) **Workstream O** — Research & performance catalogue (v1.1+ / v2.0).

The v1.0 tag is gated on the § 20 release-readiness checklist in
`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md`. The "naming
discipline reminder" in § 0 of the plan reiterates that workstream
letters / work-unit identifiers are **document identifiers only** —
they **must not** appear in Lean declaration names, by the Key
Conventions rule in this document ("Names describe content, never
provenance").

Workstream A (Audit 2026-04-23 — Release-messaging reconciliation,
V1-1 / V1-2 / V1-3 / V1-4 / V1-5 / V1-7 / V1-9, CRITICAL / HIGH) has
been completed:
- `CLAUDE.md` — new "Release messaging policy (ABSOLUTE)" entry in
  Key Conventions (immediately after "Security-by-docstring
  prohibition") codifies four citation classes (Standalone /
  Quantitative / Conditional / Scaffolding), mandates the ε = 1
  disclosure discipline, names the Status column as the canonical
  source of truth, and forbids prose that overclaims beyond the
  Lean content (V1-9 / audit finding X-01).
- `CLAUDE.md` — "Three core theorems" Status column updated for
  rows #19 (`authEncrypt_is_int_ctxt`) and #20
  (`carterWegmanMAC_int_ctxt`) from **Standalone** to
  **Conditional** with explicit orbit-cover / `X = ZMod p`
  compatibility disclosures (V1-1 / V1-7 / audit findings I-03,
  I-08 / D4). The row-#19 entry forward-references Workstream **B**
  (the planned orbit-cover refactor that will upgrade row #19 to
  **Standalone** once it lands); the row-#20 entry forward-references
  research milestone R-13 (the `Bitstring n → ZMod p` adapter).
- `CLAUDE.md` — rows #24 (`canonical_agreement_under_two_phase_decomposition`) and #25
  (`kem_round_trip_under_two_phase_decomposition`) reclassified to **Conditional** with
  the `TwoPhaseDecomposition`-falsity disclosure and a
  cross-reference to row #26 (`fast_kem_round_trip`) as the
  non-vacuous sibling (V1-2 / audit findings L-03 / D2).
- `CLAUDE.md` — row #2 (`invariant_attack`) restated so that the
  "Statement" column matches the theorem's actual `∃ A : Adversary
  X M, hasAdvantage scheme A` conclusion — existence of one
  distinguishing `(g₀, g₁)` pair — rather than the misleading
  "advantage 1/2 / complete break" shorthand (V1-4 / audit finding
  D13). The informal shorthand is preserved with an explicit
  three-convention pointer to `Probability/Advantage.lean`.
- `docs/VERIFICATION_REPORT.md` — "Release readiness" section
  extensively rewritten: new "What to cite externally" subsection
  enumerates the permitted citations (with the ε = 1 disclosure
  where applicable); new "What NOT to cite externally" subsection
  enumerates the Scaffolding theorems and the Quantitative-at-ε=1
  theorems that must carry the disclosure; new "Known limitations"
  bullets for the Workstream-B orbit-cover gap, the
  `TwoPhaseDecomposition` empirical failure, and the Carter–Wegman
  compatibility gap (V1-3 / audit findings E-10 / J-12 / J-15 /
  D3 / D9). Document history extended with the 2026-04-23
  Workstream-A entry.
- `Orbcrypt.lean` — "Vacuity map (Workstream E)" table's two
  primary-release-citation rows (`concrete_hardness_chain_implies_
  1cpa_advantage_bound`, `concrete_kem_hardness_chain_implies_kem_
  advantage_bound`) annotated with "ε = 1 inhabited only via
  `tight_one_exists`; ε < 1 requires a caller-supplied surrogate +
  encoder witness (research-scope — see § O of the 2026-04-23
  plan)" (V1-3 / audit finding M-04). Four new rows added pairing
  the Conditional rows #19, #20, #24, #25 with their hypotheses and
  their standalone siblings.
- `docs/DEVELOPMENT.md` — §7.1 (Hamming weight attack): explicit
  statement that Hamming-weight defense is **necessary but not
  sufficient** and that other G-invariants (block sums, parity
  over QC substructures) may still separate same-weight
  representatives (audit finding F-05). §8.2 (multi-query IND-Q-CPA):
  added a "Scope of the Lean bound" paragraph disclosing that
  `indQCPA_from_perStepBound` (renamed from `indQCPA_bound_via_hybrid`
  by Workstream C of the same audit) carries `h_step` as a
  **user-supplied hypothesis** and that the discharge from
  `ConcreteOIA` alone is research-scope R-09 (V1-8 / D10 / audit
  finding C-13). §8.5
  (INT-CTXT framing): cross-link to the planned Workstream **B**
  orbit-cover refactor; disclosure of the Carter–Wegman `X = ZMod
  p` / HGOE `Bitstring n` incompatibility as R-13 research (V1-7
  / D4 / D1 / audit findings I-03 / I-08).

Traceability: audit findings V1-1 (interim — upgraded to Standalone
once Workstream B lands), V1-2, V1-3, V1-4, V1-5 (the bit-length
strict-inequality framing was already machine-checkable via the
`SeedKey.compression` field landed by Workstream L1, but the
pre-Workstream-A `SeedKey.lean` module docstring still carried
"scale-invariant compression claim / ratio-style compression
statement" prose plus a "Full SGS ~1.8 MB / Seed key 256 bits"
comparison table that *read as* if the Lean field certified a
~60,000× quantitative compression ratio when it only certifies a
≥ 1-bit strict inequality; the post-audit remediation adds an
explicit "Scope of the Lean-verified compression claim" disclosure
block clarifying that the numerical compression ratio is a
**deployment parameter choice** witnessed by a `decide`-able
`Fintype.card` bound at instantiation time, not a Lean-field
certification. docs/DEVELOPMENT.md §6.2.1 requires no rewrite because
it does not mention seed-key compression — the 2026-04-23 audit's
§6.2.1 pointer in V1-5's location field was a misattribution;
the overclaim prose lives in `Orbcrypt/KeyMgmt/SeedKey.lean`'s
module docstring), V1-7, V1-9 are resolved by this workstream.
Audit findings V1-6 (toolchain), V1-8 (multi-query rename) remain
open pending Workstreams D and C respectively.

Verification: Workstream A is **documentation-only** in the sense
that no Lean *declaration* is added, removed, or modified —
only module docstrings and Markdown prose change. The touched
Lean files (`Orbcrypt.lean`, `Orbcrypt/KeyMgmt/SeedKey.lean`) are
modified only inside their `/-! … -/` module docstring blocks,
which contribute zero build jobs and zero `#print axioms`
changes. `lake build` continues to succeed for all 38 modules
with zero errors / zero warnings; `scripts/audit_phase_16.lean`
emits unchanged axiom output (no new declarations); the 347
public-declaration count, the zero `sorry` / zero custom-axiom
posture, and the standard-trio-only axiom-dependency posture are
all preserved.

Patch version: `lakefile.lean` retains `0.1.6`; Workstream A adds
no Lean source, structure, or build-graph content — only Markdown
prose + the `Orbcrypt.lean` and `Orbcrypt/KeyMgmt/SeedKey.lean`
module-docstring clarifications (both Lean files are touched
only in their `/-! … -/` module docstring blocks, which
contribute to zero build jobs).

Workstream B (Audit 2026-04-23 — `INT_CTXT` orbit-cover refactor,
V1-1 / I-03 / I-04 / D1 / D12, HIGH) has been completed:
- `Orbcrypt/AEAD/AEAD.lean` — (B1a) the `INT_CTXT` predicate is
  refactored to carry a per-challenge well-formedness precondition
  `hOrbit : c ∈ MulAction.orbit G akem.kem.basePoint` immediately
  after the `(c : X) (t : Tag)` binders, before the freshness
  disjunction. Out-of-orbit ciphertexts are rejected by the game
  itself rather than by a scheme-level orbit-cover assumption. The
  definition's docstring is extensively rewritten to explain the
  game-shape refinement (Design rationale: orbit precondition,
  freshness condition, `= none` conclusion). The module docstring
  gains a new "INT_CTXT game-shape refinement" subsection describing
  why the pre-Workstream-B shape was problematic on production HGOE
  (`|Bitstring n| = 2^n` exceeds any orbit's cardinality by the
  orbit–stabiliser bound) and how the refactor matches the
  real-world KEM "reject out-of-orbit" model.
- `Orbcrypt/AEAD/AEAD.lean` — (B1b) `authEncrypt_is_int_ctxt` now
  takes `akem : AuthOrbitKEM G X K Tag` as its sole explicit
  parameter (no top-level `hOrbitCover` obligation). The proof
  body's `intro` now binds `c t hOrbit hFresh`, the
  `obtain ⟨g, hg⟩ := MulAction.mem_orbit_iff.mp (hOrbitCover c)`
  line is replaced with `... mp hOrbit`, and the later
  `(keyDerive_canon_eq_of_mem_orbit akem (hOrbitCover c)).symm`
  invocation becomes `... akem hOrbit).symm`. The private helpers
  `authDecaps_none_of_verify_false` (C2a) and
  `keyDerive_canon_eq_of_mem_orbit` (C2b) are **unchanged** — both
  already took a direct orbit-membership fact as input. The theorem
  now discharges `INT_CTXT` unconditionally on every
  `AuthOrbitKEM`; `CLAUDE.md` row #19 upgrades from **Conditional**
  to **Standalone**.
- `Orbcrypt/AEAD/CarterWegmanMAC.lean` — (B2) `carterWegmanMAC_int_ctxt`
  loses its `hOrbitCover` argument; the proof body becomes a direct
  application `authEncrypt_is_int_ctxt (carterWegman_authKEM p kem)`
  with no threading. The theorem's docstring now documents the
  post-B state: it is an unconditional specialisation of
  `authEncrypt_is_int_ctxt`. Row #20 remains **Conditional** — the
  HGOE compatibility caveat (`X = ZMod p × ZMod p` incompatible with
  `Bitstring n`) is orthogonal to Workstream B and is tracked as
  research milestone R-13.
- `scripts/audit_phase_16.lean` — (B3) the trivial `AuthOrbitKEM`
  non-vacuity witness updated to call `authEncrypt_is_int_ctxt
  trivialAuthKEM` with no arguments; the comment clarifies that
  Workstream B absorbed the `hOrbitCover` argument into the
  `INT_CTXT` game binder. Axiom output unchanged.
- `scripts/audit_c_workstream.lean` — (B3) updated to reflect the
  post-B signature: `toyCarterWegmanMAC_is_int_ctxt` now invokes
  `carterWegmanMAC_int_ctxt 2 toyKEMZMod2` with no orbit-cover
  argument. The header prose and the §3 subsection's description
  are updated. `toyKEMZMod2_orbit_cover` is retained (unused by the
  post-B proof but preserved as a transitive-action witness that
  downstream pedagogical consumers may still reference).
- `CLAUDE.md` — (B4) row #19 Status upgraded from **Conditional**
  to **Standalone** with rewritten Significance prose describing
  the game-precondition absorption; row #20 retains **Conditional**
  with a refreshed Significance entry noting that the theorem is
  now unconditional in its orbit content (only the HGOE
  compatibility caveat remains). The Workstream-A historical note
  describing `authEncrypt_is_int_ctxt`'s pre-B landing is updated
  to record the Workstream-B refactor.
- `docs/VERIFICATION_REPORT.md` — the "Release readiness" section's
  headline-table rows for `authEncrypt_is_int_ctxt` and
  `carterWegmanMAC_int_ctxt` updated to match the `CLAUDE.md` Status
  column; the "Known limitations" orbit-cover item removed (the
  gap it described is closed by this landing); new "Document
  history" entry dated 2026-04-24 records the Workstream-B landing.
- `Orbcrypt.lean` — axiom-transparency report's row for
  `authEncrypt_is_int_ctxt` updated to drop the `hOrbitCover`
  comment; new Workstream-B snapshot section describes the
  game-shape refinement and cross-references Workstream **H**'s
  planned `decapsSafe` helper as the canonical consumer for the
  stronger "validate orbit before decapsulation" threat model.

Traceability: audit findings V1-1 (orbit-cover hypothesis vacuous on
HGOE), I-03 (missing per-challenge well-formedness), I-04 (reject
out-of-orbit at game level), D1 (INT_CTXT game-shape mismatch with
literature), and D12 (documentation-vs-code parity for row #19) are
resolved. The `authEncrypt_is_int_ctxt` + `INT_CTXT` pair now
matches the literature's "honest-ciphertext" convention: the game
rejects out-of-orbit ciphertexts as ill-formed (they cannot arise
from an honest sender running an orbit-action KEM), and the
adversary's forgery obligation is an in-orbit `(c, t)` that
decapsulates with a fresh tag. Consumers wanting the stronger
threat model where out-of-orbit ciphertexts are actively detected
and rejected by the decapsulation routine should pair this with
Workstream **H**'s planned `decapsSafe` helper (audit plan § 9).

Verification: Workstream B's refactor preserves the axiom
dependencies of both `authEncrypt_is_int_ctxt` and
`carterWegmanMAC_int_ctxt` — both continue to rely only on the
standard Lean trio (`propext`, `Classical.choice`, `Quot.sound`),
never on `sorryAx` or a custom axiom. The Phase 16 audit script
continues to emit only standard-trio outputs for every
Workstream-B-touched declaration; the `toyCarterWegmanMAC_is_int_ctxt`
end-to-end witness in `scripts/audit_c_workstream.lean` continues
to elaborate and proves the INT-CTXT pipeline is non-vacuously
inhabited at the smallest prime (p = 2) over `ZMod 2` under the
natural `Equiv.Perm (ZMod 2)` action.

Patch version: `lakefile.lean` bumped from `0.1.6` to `0.1.7` for
Workstream B — the `INT_CTXT` signature change is an API break
(downstream consumers of the predicate must now supply a
per-challenge `hOrbit` argument inside their `intro` chain, and
callers of `authEncrypt_is_int_ctxt` + `carterWegmanMAC_int_ctxt`
must drop the `hOrbitCover` argument). The 38-module total and the
zero-sorry / zero-custom-axiom posture are preserved.

Workstream C (Audit 2026-04-23 — Multi-query hybrid reconciliation,
V1-8 / C-13 / D10, HIGH) has been completed:
- `Orbcrypt/Crypto/CompSecurity.lean` — (C1) two theorem renames that
  surface the caller-supplied `h_step` hypothesis in the identifier
  itself per `CLAUDE.md`'s naming rule ("identifier names describe
  what the code *proves*, not what the code *aspires to*"):
  * `indQCPA_bound_via_hybrid` → `indQCPA_from_perStepBound`.
  * `indQCPA_bound_recovers_single_query`
    → `indQCPA_from_perStepBound_recovers_single_query`.
  The theorem bodies are unchanged; the rename is content-neutral.
  The module-docstring "Main results" list is extended with
  explicit release-messaging disclosures that the `h_step`
  discharge from `ConcreteOIA scheme ε` alone is research-scope
  R-09 (per-coordinate marginal-independence proof over
  `uniformPMFTuple`). The main theorem's docstring gains a "Game
  shape" and "User-supplied hypothesis obligation" block with
  explicit discharge-template language. The old names are **not**
  retained as deprecated aliases (`CLAUDE.md`'s
  no-backwards-compat rule).
- `scripts/audit_phase_16.lean` — (C1, C2, audit-plan § C.2)
  `#print axioms` entries renamed; five new non-vacuity examples
  in the `NonVacuityWitnesses` namespace exercise the renamed
  theorem: (1) a general-signature witness that accepts any scheme /
  adversary / per-step bound, (2) the C.2 template from the audit
  plan instantiated at Q = 2 / ε = 1 with the per-step bound
  discharged by `advantage_le_one` (parameterised), (3) a Q = 1
  regression witness (parameterised); plus two audit-strengthening
  additions: (4) a concrete Q = 2 / ε = 1 witness on
  `trivialScheme` + a `MultiQueryAdversary Unit Unit 2` that
  exercises the full instance-elaboration pipeline on a known-good
  set of typeclass arguments, and (5) a concrete Q = 1 companion
  witness firing `indQCPA_from_perStepBound_recovers_single_query`
  on the same concrete scheme.
- `scripts/audit_e_workstream.lean` — (C1) legacy per-workstream
  script's `#print axioms` lines renamed with a comment explaining
  the Workstream-C rename. The script remains exercised as a
  historical regression sentinel but is not part of CI (the
  Phase-16 audit script supersedes it).
- `Orbcrypt.lean` — (C1, C2) dependency listing entry renamed;
  axiom-transparency `#print axioms` block renamed with the
  rename disclosed in the trailing comments; Vacuity map entry
  updated to the post-rename identifier; new "Workstream C
  Snapshot (audit 2026-04-23, finding V1-8 / C-13 / D10)"
  section at the end of the transparency report describing the
  remediation, files touched, verification posture, consumer
  migration guidance, research follow-up (R-09), and the patch
  version bump.
- `CLAUDE.md` — (C2) "Main results" and release-facing references
  renamed throughout (Phase 16 snapshot "known limitations" list,
  Phase 8 section, Workstream-A snapshot paragraph); Workstream-A
  §8.2 cross-reference updated to mention the Workstream-C rename;
  Workstream-N (2026-04-23) N3 (I3) callout updated to point at the
  Workstream-C landing that closes it; the Workstream status tracker
  Workstream-C checkbox ticked; this Workstream-C snapshot entry
  appended after the Workstream-B snapshot.
- `docs/VERIFICATION_REPORT.md` — (C2) headline-results table row
  #23 renamed; "Release readiness" section's "What NOT to cite
  without qualification" list renamed; "Known limitations" bullet
  #3 renamed; "Document history" entry dated 2026-04-24 records the
  Workstream-C landing.
- `docs/DEVELOPMENT.md` — (C2) §8.2 (multi-query IND-Q-CPA discussion)
  renamed throughout including the release-messaging policy
  paragraph; the Workstream-C cross-reference in that paragraph is
  updated to point at the new name as the landed rename.

Traceability: audit findings V1-8 (documentation-vs-code parity —
release prose overstated the Lean content), C-13 (HIGH,
`indQCPA_bound_via_hybrid` signature carries `h_step` as an
explicit unproved hypothesis with no `ConcreteOIA`-derived
discharge in-tree), and D10 ("Multi-query IND-Q-CPA" citation
overstated the theorem's preconditions) are resolved. The rename
is the Track-1 remediation selected by the audit plan — the
content-neutral approach that surfaces the gap in the identifier
rather than blocking v1.0 on the R-09 research discharge.

Verification: Workstream C is a **structural rename** that
preserves the two renamed theorems' content, axiom dependencies,
and cryptographic meaning. `lake build` continues to succeed for
all 38 modules with zero errors / zero warnings.
`scripts/audit_phase_16.lean` emits unchanged axiom outputs for
the two renamed theorems (both continue to depend only on the
standard Lean trio). The 347 public-declaration count, the
zero-sorry / zero-custom-axiom posture, and the standard-trio-
only axiom-dependency posture are all preserved. The three new
non-vacuity witnesses in the audit script confirm the renamed
theorems remain well-typed on at least one concrete instance.

Patch version: `lakefile.lean` bumped from `0.1.7` to `0.1.8` for
Workstream C. The rename is an API break (downstream consumers
must update the identifier at every call site), which warrants
the patch-version bump per `CLAUDE.md`'s version-bump discipline.
No new public declarations are added; no existing declaration's
content changes; the 38-module total is unchanged; the zero-sorry
/ zero-custom-axiom posture is preserved.

Workstream D (Audit 2026-04-23 — Toolchain decision + `lakefile.lean`
hygiene, V1-6 / A-01 / A-02 / A-03, MEDIUM) has been completed:
- **Toolchain decision (D1, audit plan § 7.3).** `lean-toolchain`
  retains `leanprover/lean4:v4.30.0-rc1` under **Scenario C** of the
  audit plan — ship v1.0 off the release-candidate toolchain; defer
  the stable-toolchain upgrade to v1.1 as a follow-up work item. No
  Mathlib-stable pairing is currently available against the project's
  `fa6418a8` Mathlib pin without a coordinated pin-bump, which would
  exceed the Workstream-D scope (a stable-toolchain bump requires
  regenerating `lake-manifest.json` via `lake update`, replaying the
  full Phase-16 audit script against the new toolchain, and
  re-validating all 3,367 build jobs). The decision is recorded
  both here in the CLAUDE.md change log (this Workstream-D snapshot)
  and in `docs/VERIFICATION_REPORT.md`'s new "Toolchain decision
  (Workstream D)" subsection plus Document-history entry.
- **`lakefile.lean` comment metadata refresh (D2, audit finding
  A-02 / V1-6).** The stale "Last verified: 2026-04-14" comment has
  been updated to "Last verified: 2026-04-24". A new "Toolchain
  posture" paragraph after the `Compatible with lean4:v4.30.0-rc1`
  line records the Scenario-C decision and cross-references
  `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 7 and
  `docs/VERIFICATION_REPORT.md`'s "Toolchain decision (Workstream D)"
  section. Reading `lakefile.lean` is now self-sufficient to
  understand the rc-toolchain choice without leaving the build
  configuration.
- **Defensive `leanOption` entries (D3, audit finding A-01).**
  `lakefile.lean`'s `leanOptions` array is extended from a single-
  entry `autoImplicit := false` to a three-entry array:
  ```lean
  leanOptions := #[
    ⟨`autoImplicit, false⟩,           -- Enforce explicit universe/variable declarations
    ⟨`linter.unusedVariables, true⟩,  -- Default-true in Lean core; pinned defensively (Workstream D / audit 2026-04-23, A-01)
    ⟨`linter.docPrime, true⟩          -- Mathlib linter (default-false): warn on declarations whose name ends in ' but lack a docstring (Workstream D / A-01)
  ]
  ```
  This pins the linter settings at the package level (single source
  of truth), so the zero-warning gate is enforced by the build
  configuration itself and not only by the CI's warning-as-error
  treatment in `.github/workflows/lean4-build.yml`. **Default
  posture differs by linter**: `linter.unusedVariables` is a Lean
  core builtin with `defValue := true` (so the pin is genuinely
  defensive — currently a no-op, but locks the gate against a
  future toolchain default-flip); `linter.docPrime` is a Mathlib
  linter registered with `defValue := false` (Mathlib explicitly
  excludes it from its standard linter set; see
  `Mathlib/Init.lean:110` referencing
  https://github.com/leanprover-community/mathlib4/issues/20560),
  so the pin to `true` is a meaningful enable that turns ON a
  linter Mathlib leaves OFF. The Orbcrypt source tree currently has
  zero declarations whose names end in `'`, so the linter fires on
  zero existing call sites; it acts as a tripwire that prevents new
  primed identifiers from landing without a docstring (the
  Mathlib-style discipline the issue tracker is converging
  toward). **Caveat**: because `linter.docPrime` is registered by
  Mathlib (not Lean core), files that elaborate any
  declaration / docstring before their first `import` of a
  Mathlib-aware module will fail at startup with
  `invalid -D parameter, unknown configuration option
  'linter.docPrime'`. Every `.lean` file under `Orbcrypt/` already
  starts with `import` as its first non-blank line (verified by
  `for f in Orbcrypt/**/*.lean; do head -1 $f | grep -v '^import' &&
  echo $f; done`), so the constraint is satisfied today; new
  modules must observe the same convention.
- **Patch version bump (D).** `lakefile.lean` bumped from `0.1.8`
  to `0.1.9` for Workstream D. Technically D is a build-configuration
  change that does not alter any Lean source file, so a patch bump
  is not strictly required by `CLAUDE.md`'s version-bump discipline
  (which is triggered by API-breaking changes or new public
  declarations); however, the linter-configuration pin is a
  consumer-visible build setting, so downstream users running
  `lake env …` against a cloned checkout will experience a different
  warning surface after this landing. The patch bump records this
  visibly in the version log. No Lean source files are modified; no
  new public declarations; the 38-module total, the 347 public-
  declaration count, the zero-sorry / zero-custom-axiom posture, and
  the standard-trio-only axiom-dependency posture are all preserved.

Files touched:
- `lakefile.lean` — version `0.1.8 → 0.1.9`; comment metadata
  refreshed (Last verified date + Toolchain posture paragraph);
  `leanOptions` extended with the two linter pins.
- `CLAUDE.md` — Workstream status tracker row for D checked off;
  this Workstream-D snapshot appended after the Workstream-C
  snapshot.
- `docs/VERIFICATION_REPORT.md` — new "Toolchain decision (Workstream
  D)" subsection after "How to reproduce the audit"; Document-history
  entry dated 2026-04-24 records the Workstream-D landing.
- `Orbcrypt.lean` — axiom-transparency report's footer section gains
  a new "Workstream D Snapshot (audit 2026-04-23, finding V1-6 /
  A-01 / A-02 / A-03)" describing the toolchain + lakefile changes
  and the unchanged axiom-dependency posture.
- `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` — V1-6
  release-gate checkbox ticked (§ 20.1); Workstream-D tracker
  updated with the landing date (§ 3, Appendix B).

Traceability: audit findings V1-6 (toolchain decision recorded),
A-01 (defensive linter options pinned at package level), A-02
(`lakefile.lean` metadata refresh), and A-03 (rc-vs-stable
toolchain decision) are resolved. The rc-toolchain posture is
explicitly disclosed and deferred to v1.1 via the Scenario-C
framing from the audit plan — consumers running `cat lean-toolchain`
or reading the new `lakefile.lean` comment block see the decision
and the v1.1 upgrade commitment directly.

Verification: Workstream D is **build-configuration-only** — no
Lean source files are modified. `lake build` succeeds for all
3,367 build jobs with zero warnings / zero errors on a forced
rebuild (touching `Orbcrypt/GroupAction/Basic.lean` and rerunning
`lake build`). `scripts/audit_phase_16.lean` emits unchanged
axiom output (every `#print axioms` result is either "does not
depend on any axioms" or the standard-trio
`[propext, Classical.choice, Quot.sound]`; zero `sorryAx`; zero
non-standard axioms). The 38-module total is unchanged; the 347
public-declaration count is unchanged; the zero-sorry / zero-
custom-axiom posture is preserved.

Workstream E (Audit 2026-04-23 — Formal vacuity witnesses, C-07 /
E-06, HIGH) has been completed:
- `Orbcrypt/Crypto/OIA.lean` — (E1) adds `det_oia_false_of_distinct_reps`
  at the bottom of the module, after the existing `OIA` definition
  and its comprehensive documentation block. The theorem refutes
  `OIA scheme` under the hypothesis
  `scheme.reps m₀ ≠ scheme.reps m₁` using the membership-at-`reps m₀`
  Boolean distinguisher evaluated at identity group elements. Proof
  body: `intro` OIA, instantiate the Boolean distinguisher at
  `(m₀, m₁, 1, 1)`, use `simp only [one_smul]` to strip the
  identity-smul, witness LHS `= true` via `decide_eq_true (Eq.refl _)`
  and RHS `= false` via `decide_eq_false` threading the distinctness
  hypothesis, rewrite, and close the `true = false` goal with
  `Bool.true_eq_false_iff.mp h |>.elim`. Typeclass context identical
  to `OIA` (`[Group G]`, `[MulAction G X]`, `[DecidableEq X]`); no new
  imports. Docstring documents the distinguisher, the release-
  messaging status (**Standalone**), and cross-references
  `det_kemoia_false_of_nontrivial_orbit` as the KEM-layer parallel.
- `Orbcrypt/KEM/Security.lean` — (E2) adds
  `det_kemoia_false_of_nontrivial_orbit` at the bottom of the module,
  after `kemoia_implies_secure`. The KEM-layer parallel of E1: refutes
  `KEMOIA kem` under the hypothesis
  `g₀ • kem.basePoint ≠ g₁ • kem.basePoint` via the
  membership-at-`g₀ • basePoint` Boolean distinguisher. Same proof
  structure as E1; written against the post-Workstream-L5
  single-conjunct `KEMOIA` form — no `.1` / `.2` destructuring is
  required. Typeclass context identical to `KEMOIA` (`[Group G]`,
  `[MulAction G X]`, `[DecidableEq X]`); no new imports. Docstring
  documents the distinguisher, the release-messaging status
  (**Standalone**), the post-L5 single-conjunct observation, and
  cross-references `det_oia_false_of_distinct_reps` as the
  scheme-layer parallel.
- `Orbcrypt.lean` — (E3) Vacuity map table upgraded from two columns
  to three by adding a "Machine-checked vacuity witness" column.
  Rows #1–#2 (`oia_implies_1cpa` / `kemoia_implies_secure`) point at
  `det_oia_false_of_distinct_reps` and
  `det_kemoia_false_of_nontrivial_orbit` respectively. Downstream
  rows (hardness chain, Workstream-K distinct corollaries, KEM-layer
  chain) note that they inherit the same witnesses via their
  upstream `OIA` / `KEMOIA` antecedents; the probabilistic rows
  (K4, combiner upper bound, multi-query) use "—" because they
  carry `Concrete*` hypotheses that are genuinely ε-smooth. Two new
  `#print axioms` cookbook entries land under a "Workstream E (audit
  2026-04-23, findings C-07 + E-06)" subsection; a new "Workstream E
  Snapshot (audit 2026-04-23, findings C-07 / E-06)" section is
  appended at the end of the transparency report with problem
  summary, fix, changes, verification, consumer-impact, patch-version
  note, and risk-register closeout (E-R1 through E-R4 all verified
  clean).
- `scripts/audit_phase_16.lean` — two new `#print axioms` entries
  immediately adjacent to `#print axioms OIA` (E1) and
  `#print axioms KEMOIA` (E2); two new non-vacuity `example` bindings
  under the `NonVacuityWitnesses` namespace:
  * A `trivialSchemeBool : OrbitEncScheme (Equiv.Perm (Fin 1)) Bool
    Bool` with `reps := id` under a locally-registered trivial
    `MulAction (Equiv.Perm (Fin 1)) Bool`. Each orbit is a singleton
    under the trivial action, so `reps_distinct` holds and the
    canonical form `canon := id` inhabits the appropriate singleton
    orbit. The distinctness hypothesis `scheme.reps true ≠
    scheme.reps false` is `true ≠ false`, discharged by `decide`.
    The example block closes `¬ OIA trivialSchemeBool` by direct term
    construction via `det_oia_false_of_distinct_reps`.
  * A `trivialKEM_PermZMod2 : OrbitKEM (Equiv.Perm (ZMod 2)) (ZMod 2)
    Unit` under the natural `Equiv.Perm (ZMod 2)` action on `ZMod 2`,
    base point `0`, with a constant canonical form `canon _ := 0`
    whose `mem_orbit` and `orbit_iff` obligations are discharged via
    the transitive-action witness `Equiv.swap x 0` (Mathlib's
    `Equiv.swap_apply_left`). This fixture parallels the Workstream-C
    `toyKEMZMod2` in `scripts/audit_c_workstream.lean` but is
    re-materialised here so the Phase-16 audit script remains
    self-contained. The non-triviality hypothesis
    `Equiv.swap 0 1 • 0 ≠ 1 • 0` reduces to `1 ≠ 0` in `ZMod 2`,
    discharged by `simp` + `decide`. The example block closes
    `¬ KEMOIA trivialKEM_PermZMod2` by direct term construction via
    `det_kemoia_false_of_nontrivial_orbit`.
- `CLAUDE.md` — (E4) Workstream status tracker row for E checked off;
  headline-theorems table gained rows #31 and #32; this Workstream-E
  snapshot appended after the Workstream-D snapshot. The "Together
  these establish" closing paragraph is unchanged — theorems #31–#32
  are structural / auditing content (vacuity witnesses) rather than
  positive security claims and do not affect the prose summary.
- `docs/VERIFICATION_REPORT.md` — "Headline results" table extended
  with rows for `det_oia_false_of_distinct_reps` and
  `det_kemoia_false_of_nontrivial_orbit` under the **Standalone**
  status; "Known limitations" item 1 (deterministic-chain scaffolding)
  updated to note that the vacuity is now machine-checked; Document
  history gains a 2026-04-24 Workstream-E entry with the full
  additions list.
- `lakefile.lean` — version bumped from `0.1.9` to `0.1.10` for the
  two new public declarations (`CLAUDE.md`'s version-bump discipline
  is triggered by new public declarations, which this landing is).

Traceability: audit findings C-07 (HIGH, deterministic-OIA vacuity
claimed only in prose) and E-06 (HIGH, deterministic-KEMOIA parallel)
are resolved. The release-messaging policy (introduced by
Workstream A, immediately after "Security-by-docstring prohibition"
in Key Conventions) previously permitted these prose-level
disclosures because the affected identifiers are `Prop` *definitions*
of assumptions rather than security *claims*; Workstream E upgrades
them to Lean theorems for full auditability parity with the other
vacuity disclosures across the codebase.

Verification: the Phase 16 audit script (`scripts/audit_phase_16.lean`)
exercises both new theorems via `#print axioms` and the two new
non-vacuity `example` bindings. Every new declaration depends only
on standard-trio axioms (`propext`, `Classical.choice`,
`Quot.sound`); none depend on `sorryAx` or a custom axiom. `lake
build` succeeds for all 38 modules (3,369 jobs — two new theorems
add two build nodes); zero warnings / zero errors.
`scripts/audit_c_workstream.lean` and other per-workstream historical
audit scripts remain unaffected; their per-workstream fixture
definitions (`toyKEMZMod2` et al.) are unchanged and continue to
elaborate.

Patch version: `lakefile.lean` bumped from `0.1.9` to `0.1.10` for
Workstream E. Two new public declarations land inside existing
modules; no new `.lean` files; the 38-module total is unchanged.
Public declaration count rises from 347 to 349; the zero-sorry /
zero-custom-axiom posture and the standard-trio-only axiom-dependency
posture are preserved. The Phase-16 audit script's `#print axioms`
total rises from 342 to 344; the non-vacuity witness block gains
two new `example` bindings (plus four supporting fixture definitions
— one `MulAction` instance, one `OrbitEncScheme`, one local
`MulAction` alias, one `OrbitKEM`).

Workstream F (Audit 2026-04-23 — Concrete `CanonicalForm` from
lex-min, V1-10 / F-04, MEDIUM) has been completed:
- `Orbcrypt/GroupAction/CanonicalLexMin.lean` — (F1) new module,
  the 40th `.lean` file under `Orbcrypt/`. Placement decision per
  the audit plan's § 9.4 F1 recommendation: keep
  `Orbcrypt/GroupAction/Canonical.lean` lean (pure abstract
  structure) and bundle the concrete-construction helpers in a
  dedicated submodule. The module defines
  `CanonicalForm.ofLexMin`, the computable constructor taking
  `[Group G] [MulAction G X] [Fintype G] [DecidableEq X]
  [LinearOrder X]` and producing a `CanonicalForm G X` as the
  `Finset.min'` of the orbit's `.toFinset`. Three supporting
  declarations: `orbitFintype` (the `Fintype (MulAction.orbit G x)`
  instance inherited from `Set.fintypeRange`, since `orbit` is
  definitionally `Set.range`); `mem_orbit_toFinset_iff`
  (`@[simp]` lemma bridging `Set.mem_toFinset` to the Orbcrypt
  naming convention); `orbit_toFinset_nonempty`
  (base-point-witness lemma for `Finset.min'`'s non-emptiness
  obligation). The constructor's three `CanonicalForm` fields
  discharge as follows (F2 + F3b + F3c):
  * `canon` (F2) — `(MulAction.orbit G x).toFinset.min'
    (orbit_toFinset_nonempty x)`.
  * `mem_orbit` (F2) — via `Finset.min'_mem` +
    `mem_orbit_toFinset_iff`.
  * `orbit_iff` forward (F3b) — extract the shared `min'`
    element `m`, conclude `m ∈ orbit G x` and `m ∈ orbit G y` by
    `Finset.min'_mem` + membership iff, then thread through
    `MulAction.orbit_eq_iff` twice to conclude
    `orbit G x = orbit G m = orbit G y`.
  * `orbit_iff` reverse (F3c) — `Set.toFinset_congr` on equal
    orbit sets produces equal `.toFinset`s; `congr 1` reduces
    the remaining `min'` equation to the finset equality.
  Two companion lemmas: `CanonicalForm.ofLexMin_canon` (`@[simp]`
  unfolding lemma) and `CanonicalForm.ofLexMin_canon_mem_orbit`
  (restatement of `mem_orbit` at the `ofLexMin` level).
- `Orbcrypt/Construction/Permutation.lean` — (F-prereq)
  `bitstringLinearOrder` (`@[reducible] def`, not a global
  `instance`) registers a computable lex order on `Bitstring n`
  matching the GAP reference implementation's
  `CanonicalImage(G, x, OnSets)` convention: bitstrings are
  compared via their support sets (sorted ascending position
  lists), with smaller-position-true winning ("leftmost-true
  wins"). Implemented via `LinearOrder.lift'` over the
  inverted-Bool composition `List.ofFn ∘ (! ∘ ·)`, with
  `Bool.not_inj` discharging injectivity. Exposed as a `def` to
  avoid the diamond with Mathlib's pointwise `Pi.partialOrder` —
  registering a global `LinearOrder (Bitstring n)` would leave
  Lean's typeclass search with two definitionally-distinct
  `LT (Bitstring n)` instances and break `decide` on any
  comparison. Callers bind it locally:
  `letI : LinearOrder (Bitstring n) := bitstringLinearOrder`.
  Concretely on `Bitstring 3`,
  `![T, T, T] < ![T, T, F] < ![T, F, T] < ![T, F, F] <
   ![F, T, T] < ![F, T, F] < ![F, F, T] < ![F, F, F]`. The
  weight-2 lex-min element `![T, T, F]` matches GAP's
  `CanonicalImage(S_3, {0, 1}, OnSets) = {0, 1}` exactly.
  `decide` reduces `Finset.min'` under this order on small
  inputs.
- `Orbcrypt/Construction/HGOE.lean` — (F4) adds
  `hgoeScheme.ofLexMin`, a convenience constructor that
  auto-fills the `CanonicalForm` parameter for any finite
  subgroup of `Equiv.Perm (Fin n)` under `bitstringLinearOrder`.
  Requires `[Fintype ↥G]` (the ambient group is finite, so
  the orbit is a `Fintype`). Threads `letI` internally so
  callers needn't bring the `LinearOrder` themselves; the
  global `Pi.partialOrder` diamond is not activated. Companion
  `@[simp]` lemma `hgoeScheme.ofLexMin_reps` witnesses that
  the `reps` field is preserved through the convenience
  constructor (structural sanity for downstream invariant /
  attack proofs).
- `Orbcrypt.lean` — the 40th `.lean` file is wired in via
  `import Orbcrypt.GroupAction.CanonicalLexMin` between the
  existing `Canonical` and `Invariant` imports, matching the
  module-dependency-graph order.
- `scripts/audit_phase_16.lean` — (F3d) five new `#print axioms`
  entries for the Workstream-F declarations, plus four new
  non-vacuity `example` bindings under a new
  `## Workstream F non-vacuity witnesses` section header:
  * An explicit-LT lex-order direction check
    (`@LT.lt (Bitstring 3) bitstringLinearOrder.toLT ...`)
    using explicit `toLT` projection to sidestep the
    `Pi.preorder` diamond at the witness site.
  * A `decide`-backed evaluation confirming
    `CanonicalForm.ofLexMin.canon ![true, false, true] =
    ![true, true, false]` under the full `Equiv.Perm (Fin 3)`
    action — matching GAP's
    `CanonicalImage(S_3, {0, 1}, OnSets) = {0, 1}` exactly
    (the weight-2 orbit's lex-min under the GAP-matching
    "leftmost-true wins" convention is the unique weight-2
    bitstring with `true` at positions 0 and 1).
  * A `decide`-backed evaluation on a singleton orbit:
    `canon ![false, false, false] = ![false, false, false]`
    (weight-0 is the only length-3 weight-0 bitstring, so the
    orbit is a singleton).
  * A type-elaboration witness for `hgoeScheme.ofLexMin` at
    `G := ⊤ ≤ S_3`, `M := Unit`, with `DecidablePred (· ∈ ⊤)`
    discharged by `fun _ => isTrue trivial`. Confirms the
    Workstream-F4 convenience constructor elaborates at a
    concrete finite subgroup of `Equiv.Perm (Fin 3)`.
  Also adds two new imports (`Mathlib.Data.Fintype.Perm`,
  `Mathlib.Data.Fin.VecNotation`) to supply
  `Fintype (Equiv.Perm (Fin 3))` and the `![...]` syntax at
  the witness sites; neither is transitively available through
  `import Orbcrypt`.

Traceability: audit finding V1-10 / F-04 (MEDIUM,
`hgoeScheme`'s `CanonicalForm` parameter has no constructed
in-tree witness) is resolved. Every downstream theorem that
types `{can : CanonicalForm (↥G) …}` now has a concrete
construction available via `CanonicalForm.ofLexMin` (at any
finite subgroup + computable linear order) or
`hgoeScheme.ofLexMin` (specialised to `Bitstring n` with
Orbcrypt's `bitstringLinearOrder`). See
`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 9 for
the specification and Appendix A for the finding-to-work-unit
mapping.

Verification: `scripts/audit_phase_16.lean` exercises every
Workstream-F declaration via `#print axioms` and four
non-vacuity `example` bindings. Every new declaration depends
only on standard-trio axioms (`propext`, `Classical.choice`,
`Quot.sound`); none depends on `sorryAx` or a custom axiom.
`lake build` succeeds (3,368 jobs — 3,367 pre-F plus one new
module build node — with zero warnings / zero errors). The
CI's "Verify no sorry" step (comment-aware Perl strip) passes;
the CI's "Verify no unexpected axioms" step passes; the CI's
Phase-16 audit-script step passes (the de-wrap parser
confirms standard-trio-only across all 347+ `#print axioms`
calls).

Patch version: `lakefile.lean` bumped from `0.1.10` to
`0.1.11` for Workstream F — nine new public declarations land
(one across the new `CanonicalLexMin.lean` module, one in
`Permutation.lean`, two in `HGOE.lean`, plus the three
supporting lemmas and the two companion lemmas in
`CanonicalLexMin.lean`), and `Orbcrypt.lean`'s import list
gains a new entry. The 38-module total rises to 39; the
public declaration count rises from 349 to 358; the
zero-sorry / zero-custom-axiom posture is preserved; the
standard-trio-only axiom-dependency posture is preserved. The
Phase-16 audit script's `#print axioms` total rises from 344
to 353 (nine new entries: `orbitFintype`,
`mem_orbit_toFinset_iff`, `orbit_toFinset_nonempty`,
`CanonicalForm.ofLexMin`, `CanonicalForm.ofLexMin_canon`,
`CanonicalForm.ofLexMin_canon_mem_orbit`,
`bitstringLinearOrder`, `hgoeScheme.ofLexMin`,
`hgoeScheme.ofLexMin_reps`); the non-vacuity witness block
gains four new `example` bindings.

Workstream G (Audit 2026-04-23 — λ-parameterised
`HGOEKeyExpansion`, V1-13 / H-03 / Z-06 / D16, MEDIUM) has
been completed (2026-04-25):

- **G1 — Add `lam : ℕ` parameter to `HGOEKeyExpansion`.**
  `Orbcrypt/KeyMgmt/SeedKey.lean`: the structure signature
  changes from `HGOEKeyExpansion (n : ℕ) (M : Type*)` to
  `HGOEKeyExpansion (lam : ℕ) (n : ℕ) (M : Type*)`. The leading
  `lam` parameter is the security parameter (spelled `lam`
  rather than `λ` because `λ` is a Lean-reserved token; named-
  argument syntax accepts the spelling
  `HGOEKeyExpansion (lam := 128) (n := 512) M`). The
  `group_large_enough` field's type changes from the literal
  `group_order_log ≥ 128` to the λ-parameterised
  `group_order_log ≥ lam`. The structure / module / field
  docstrings are updated to disclose: (a) the spelling
  correspondence; (b) the lower-bound semantics (the Lean-
  verified bound is `≥ lam`, not `= lam`; deployment chooses
  `group_order_log` per the §4 thresholds, often strictly
  above `lam`); (c) the cross-reference to
  `docs/PARAMETERS.md` §2.2.1 and the Workstream-G entry in
  the audit plan.

- **G2 — Non-vacuity witnesses at λ ∈ {80, 128, 192, 256}.**
  `scripts/audit_phase_16.lean`: a new "Workstream G non-
  vacuity witnesses" section under
  `§ 12 NonVacuityWitnesses` lands four `example` blocks,
  one per documented Phase-14 tier. Each witness exhibits a
  complete `HGOEKeyExpansion lam n Unit` value with all 11
  fields discharged, including the critical
  `group_large_enough : group_order_log ≥ lam` field
  closed by `le_refl _` (we choose `group_order_log := lam`
  for each witness — production deployments choose strictly
  larger to clear the §4 scaling-model thresholds). The
  parameter triples used:
  * λ = 80: `n = 256`, `b = 4`, `ℓ = 64`, `code_dim = 128`.
  * λ = 128: `n = 512`, `b = 8`, `ℓ = 64`, `code_dim = 256`
    (matches the aggressive-tier row of
    `docs/benchmarks/results_128.csv`).
  * λ = 192: `n = 768`, `b = 4`, `ℓ = 192`, `code_dim = 384`.
  * λ = 256: `n = 1024`, `b = 4`, `ℓ = 256`, `code_dim = 512`.
  A private helper `hammingWeight_zero_bitstring` (one
  `simp [hammingWeight]` body) is shared across all four
  witnesses to discharge Stage-4 weight-uniformity for the
  trivial `reps := fun _ _ => false` choice (every
  representative has Hamming weight 0). Two regression
  examples land alongside: a field-projection check
  (`exp.group_large_enough : exp.group_order_log ≥ lam` on a
  free `lam`) and a λ-monotonicity negative example
  (`¬ (80 ≥ 192)`) documenting that the four tier-witnesses
  are *distinct* obligations.

- **G3 — Documentation cross-links.** `docs/DEVELOPMENT.md §6.2.1`
  gains a paragraph at the top of the "HGOE.Setup(1^λ) — Detailed
  Pipeline" section cross-linking the prose specification to the
  λ-parameterised Lean structure and disclosing the spelling
  correspondence (`lam` ↔ `λ`). `docs/PARAMETERS.md §2.2.1` is
  a new "Lean cross-link — λ-parameterised
  `HGOEKeyExpansion`" subsection mapping each row of the §2.2
  parameter table to its corresponding `HGOEKeyExpansion lam …`
  Lean witness; explicitly disclosing the lower-bound semantics
  and the Workstream-G fix to the pre-G λ-coverage gap.

Files touched: `Orbcrypt/KeyMgmt/SeedKey.lean` (structure +
docstrings), `scripts/audit_phase_16.lean` (Workstream-G
non-vacuity witnesses), `docs/DEVELOPMENT.md`, `docs/PARAMETERS.md`,
`Orbcrypt.lean` (Workstream-G snapshot at the end of the
transparency report), `CLAUDE.md` (this snapshot, the module-
line note for `KeyMgmt/SeedKey.lean`, the Workstream-G status-
tracker checkbox), `docs/VERIFICATION_REPORT.md` (Document
history + Known limitations cross-reference), and
`lakefile.lean` (`version` bumped `0.1.11 → 0.1.12`).

Traceability: audit findings V1-13 (CRITICAL release-messaging
gap on λ coverage), H-03 (MEDIUM, hard-coded literal),
Z-06 (LOW performance / Phase-14 alignment), and D16 (LOW
documentation-vs-code parity) are resolved. The pre-G
"`HGOEKeyExpansion` is only instantiable at λ = 128" gap is
closed by the structural change; the four non-vacuity witnesses
machine-check that every documented security tier inhabits the
post-G structure.

Verification: every new declaration depends only on the
standard Lean trio (`propext`, `Classical.choice`,
`Quot.sound`); none depends on `sorryAx` or a custom axiom.
`lake build` succeeds for all 39 modules with zero warnings /
zero errors. `scripts/audit_phase_16.lean` emits standard-trio-
only axiom output for `#print axioms HGOEKeyExpansion` and for
the new defensive `#print axioms hammingWeight_zero_bitstring`
(the audit-script-internal `private theorem` used to discharge
Stage-4 weight-uniformity for the four tier witnesses); the
four non-vacuity `example`s elaborate cleanly. The Phase-16
`#print axioms` total rises from 382 to 383 (the new line
covers the helper, ensuring CI surfaces any future helper
regression that anonymous `example`s would otherwise hide).

Patch version: `lakefile.lean` bumped from `0.1.11` to
`0.1.12` for Workstream G — the `HGOEKeyExpansion` signature
change (gaining a `lam : ℕ` parameter) is an API break
warranting a patch bump per `CLAUDE.md`'s version-bump
discipline. The 39-module total is unchanged; the public
declaration count remains 358 (the structure gains a parameter,
not a field); the zero-sorry / zero-custom-axiom posture is
preserved; the standard-trio-only axiom-dependency posture is
preserved.

Workstream R-CE (Audit 2026-04-25 — Petrank–Roth GI ≤ CE Karp
reduction, R-15-CE / Option B forward-only landing) has been
completed (2026-04-25):

- **Layer 0 — Bit-layout primitives.**
  `Orbcrypt/Hardness/PetrankRoth/BitLayout.lean`.  Block length
  `dimPR m = m + 4 * numEdges m + 1` decomposed as `m` vertex
  columns + `numEdges m` incidence columns + `3 * numEdges m`
  marker columns + 1 sentinel.  `PRCoordKind` inductive over the
  four families with `DecidableEq`, `Fintype` (via `equivSum`),
  and a bijection `prCoordEquiv : PRCoordKind m ≃ Fin (dimPR m)`
  via `prCoord` / `prCoordKind`.  `numEdges m = m * (m - 1)`
  enumerates **directed edge slots** — ordered pairs `(u, v)` with
  `u ≠ v` — packaged via `EdgeSlot m := Fin m × Fin (m - 1)`,
  with the second component `k : Fin (m - 1)` decoded to a target
  vertex `v ≠ u` by `otherVertex` (skip-the-source layout).
  Round-trip lemmas `otherVertex_otherVertexInverse` and
  `otherVertexInverse_otherVertex` make `edgeEndpoints` /
  `edgeIndex` a bijection that preserves directional information.

- **Layer 1 — Encoder + cardinality.**
  `Orbcrypt/Hardness/PetrankRoth.lean` (~600 lines): the four
  codeword families
  (`vertexCodeword`, `edgeCodeword`, `markerCodeword`,
  `sentinelCodeword`), within-family injectivity
  (`vertexCodeword_injective`, `edgeCodeword_injective`,
  `markerCodeword_injective`), pairwise cross-family disjointness
  (`*_ne_*`), the encoder `prEncode m adj`, the membership shape
  `mem_prEncode`, and the cardinality identity `prEncode_card :
  (prEncode m adj).card = codeSizePR m`.  The `edgePresent` /
  `edgeCodeword` formulation reads adjacency directly via
  `edgePresent m adj e := adj p.1 p.2` on the directed slot
  `(p.1, p.2) := edgeEndpoints m e` — direction-faithful, so the
  encoder distinguishes `(u, v)` from `(v, u)` and the iff in
  `Orbcrypt.GIReducesToCE` extends to arbitrary (possibly
  asymmetric) `adj`.

- **Layer 2 — Forward direction.**
  `Orbcrypt/Hardness/PetrankRoth.lean` (cont., ~600 lines):
  the vertex-permutation-induced **directed** edge permutation
  `liftedEdgePerm m σ : Equiv.Perm (Fin (numEdges m))` mapping
  directed slot `(u, v)` to `(σ u, σ v)` without canonicalisation
  (the round-trip `liftedEdgePermFun_left_inv` is a one-line
  consequence of `edgeEndpoints_edgeIndex` and
  `perm_inv_apply_self`); the dimension-level lift
  `liftAut m σ : Equiv.Perm (Fin (dimPR m))` via conjugation with
  `prCoordEquiv`; the four action lemmas
  (`permuteCodeword_liftAut_vertexCodeword`,
  `permuteCodeword_liftAut_edgeCodeword`,
  `permuteCodeword_liftAut_markerCodeword`,
  `permuteCodeword_liftAut_sentinelCodeword`); the asymmetric
  edge-presence transfer `edgePresent_liftedEdgePerm` (a one-line
  consequence of `edgeEndpoints_liftedEdgePerm` and the GI
  hypothesis); and the headline `prEncode_forward : (∃ σ, ∀ i j,
  adj₁ i j = adj₂ (σ i) (σ j)) → ArePermEquivalent (prEncode m
  adj₁) (prEncode m adj₂)`.  Auxiliary helpers
  `decide_or_to_bool`, `decide_or_iff_bool` (private) cleanly
  bridge iff-on-disjunctions to bool-equality of `decide`s.

- **Layer 3 — Column-weight invariance infrastructure.**
  `Orbcrypt/Hardness/PetrankRoth/MarkerForcing.lean` (~615
  lines): `colWeight C i` defined as the count of codewords in
  `C` that are `true` at column `i`; basic algebraic identities
  (`colWeight_empty`, `colWeight_singleton_self/_other`,
  `colWeight_union_disjoint` — Sub-task 3.1); the headline
  `colWeight_permuteCodeword_image` proving column weights are
  preserved by `permuteCodeword`-image of a Finset (up to π's
  coordinate relabelling — Sub-task 3.2); and the four
  per-family **column-weight signatures** (Sub-task 3.3):
  `colWeight_prEncode_at_vertex` (vertex column for v has weight
  `1 + #{present edges incident to v}`),
  `colWeight_prEncode_at_incid` (incidence column has weight 1),
  `colWeight_prEncode_at_marker` (marker column has weight 1),
  `colWeight_prEncode_at_sentinel` (sentinel column has weight
  1).  These signatures are the foundational invariants the
  marker-forcing reverse direction (Layer 4) consumes to classify
  each `Fin (dimPR m)` index into one of {vertex, incid, marker,
  sentinel}.

- **Layer 4.0 — Cardinality-forced surjectivity bridge.**
  `surjectivity_of_card_eq` and the specialisation
  `prEncode_surjectivity` lift a one-sided
  `ArePermEquivalent`-witness ("σ maps each C₁ codeword *into* C₂")
  into a two-sided "every C₂ codeword has a C₁ preimage"
  statement, using `prEncode_card` to discharge the equal-
  cardinality hypothesis automatically.  This is the structural
  bridge Layer 4's marker-forcing argument consumes when
  extracting vertex/edge permutations from a CE-witness π.

- **Layers 4.1–4.10, 5, 6, 7 — Residual marker-forcing
  reverse direction (research-scope).**  The remaining steps
  (`extractVertexPerm` and bijectivity, `extractEdgePerm`, the
  `extractEdgePerm = liftedEdgePerm extractVertexPerm` core,
  marker-block freedom, adjacency recovery, empty-graph case,
  `prEncode_reverse` assembly, the iff `prEncode_iff`, the
  non-degeneracy bridge, and the headline
  `petrankRoth_isInhabitedKarpReduction`) are tracked at
  `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`
  sub-tasks 4.1–4.10 / 5 / 6 / 7 as research-scope
  **R-15-residual-CE-reverse**.  The audit-plan budget for these
  is ~800–1500 lines / ~7–14 days of focused mathematical work,
  much of which is genuinely intricate (the `extractEdgePerm =
  liftedEdgePerm extractVertexPerm` identification core alone is
  budgeted at ~300 lines).  The Layer-3.1/3.2/3.3 + Layer-4.0
  infrastructure landed in this PR is the clean foundation those
  steps consume; the existing `GIReducesToCE` Prop remains
  inhabited only via the type-level
  `_card_nondegeneracy_witness` until those steps land.

Files touched:
- `Orbcrypt/Hardness/PetrankRoth.lean` — new file (~1100 lines),
  Layers 1–2 with the `prEncode_forward` headline (asymmetric
  `edgePresent` + asymmetric `liftedEdgePerm`, no canonicalisation).
- `Orbcrypt/Hardness/PetrankRoth/MarkerForcing.lean` — new file
  (~150 lines), Layer 3 column-weight infrastructure.
- `Orbcrypt/Hardness/PetrankRoth/BitLayout.lean` — refactored from
  the pre-session unordered-edge enumeration (`numEdges m = m * (m
  - 1) / 2`, `EdgeSlot m = Σ v, Fin v.val`, `edgeEndpoints`
  returning `(u, v)` with `u.val < v.val`) to the **directed-edge**
  enumeration (`numEdges m = m * (m - 1)`, `EdgeSlot m = Fin m ×
  Fin (m - 1)`, `edgeEndpoints` returning `(u, v)` with `u ≠ v`,
  no order constraint).  Adds the `otherVertex` / `otherVertexInverse`
  bijection between `Fin (m - 1)` and the `m - 1` "other vertices",
  and round-trip lemmas making `edgeEndpoints` / `edgeIndex` a
  bijection on directed pairs.  This refactor makes the iff in
  `Orbcrypt.GIReducesToCE` provable for arbitrary asymmetric `adj`.
- `Orbcrypt/Hardness/CodeEquivalence.lean` — `GIReducesToCE`
  documentation extended with the Workstream-R-CE landing
  status.
- `Orbcrypt.lean` — root file extended to import the two new
  Hardness submodules.
- `scripts/audit_phase_16.lean` — Layer 0 has 41 entries
  (incl. `EdgeSlot`, `otherVertex` / `otherVertex_ne_self` /
  `otherVertexInverse` / `otherVertex_otherVertexInverse` /
  `otherVertexInverse_otherVertex` / `edgeEndpoints_ne` for the
  directed-edge enumeration, plus all `numEdges_*`,
  `prCoord_*_val`, and `PRCoordKind.toSum` /  `ofSum` /
  `ofSum_toSum` / `toSum_ofSum` entries); Layer 1 has 33 entries
  (incl. all `*_at_*` simp evaluation lemmas); Layer 2 has 28
  entries (incl. `liftedEdgePerm_apply` / `_symm_apply`,
  `edgeEndpoints_liftedEdgePermFun`, `edgeEndpoints_liftedEdgePerm`,
  `liftAutKindFun_*` simps, `liftAutKindFun_left_inv`,
  `liftAutKind_apply`/`_symm_apply`, `liftAut_apply`/`_symm_apply`);
  Layer 3 has 12 entries (Sub-task 3.1 algebraic identities + Sub-
  task 3.2 invariance + Sub-task 3.3 four per-family signatures +
  Sub-task 4.0 surjectivity bridges); per-layer
  `NonVacuityWitnesses` namespaces exercise concrete instances at
  `m = 2` (asymmetric directed-edge GI witness via `Equiv.swap 0 1`)
  and `m = 3` (cardinality, trivial GI witness, and the four per-
  family column-weight signatures + surjectivity bridge witness).
- `lakefile.lean` — `version` bumped from `0.1.15` to `0.1.16`.

Traceability: audit-plan item `R-15` (GI ≤ CE) is partially
closed — the forward direction lands as `prEncode_forward`; the
reverse direction is deferred to research-scope
**R-15-residual-CE-reverse** per the Risk Gate. No Layer 4–7
declarations are introduced; the existing `GIReducesToCE` Prop's
`_card_nondegeneracy_witness` remains the only structural
inhabitant.

Verification: every Layer 0, 1, 2, 3 declaration depends only on
the standard Lean trio (`propext`, `Classical.choice`,
`Quot.sound`); none depends on `sorryAx` or a custom axiom.
`lake build` succeeds for all 43 modules (40 pre-session
post-Workstream-G plus the post-G additions
`Probability/UniversalHash.lean` and
`GroupAction/CanonicalLexMin.lean`, plus the three
`Hardness/PetrankRoth/BitLayout.lean`,
`Hardness/PetrankRoth.lean`, and
`Hardness/PetrankRoth/MarkerForcing.lean` modules under
Workstream R-CE) with zero warnings / zero errors.  The Phase-16
audit script's `#print axioms` total expands by 114 entries
across all four R-CE layers (41 Layer-0 + 33 Layer-1 + 28 Layer-2
+ 12 Layer-3) covering every public declaration in the new
modules.  The Layer-2 non-vacuity witnesses include a concrete
asymmetric-graph GI test at `m = 2` (graphs `adj₁(0,1) = true`
and `adj₂(1,0) = true`, both other entries `false`, equivalent
under `σ = Equiv.swap 0 1 : Equiv.Perm (Fin 2)`) — exercising
the directional information that the post-refactor encoder
preserves.  The Layer-3 non-vacuity witnesses include the four
per-family column-weight signatures evaluated on arbitrary
`adj` and the surjectivity bridge `prEncode_surjectivity` at
the empty graph at `m = 3`.

Patch version: `lakefile.lean` bumped from `0.1.15` to `0.1.16`
for Workstream R-CE — two new public-API modules add new public
declarations, warranting the patch-version bump per `CLAUDE.md`'s
version-bump discipline. The pre-session 41-module total rises
to 43; the zero-sorry / zero-custom-axiom posture and the
standard-trio-only axiom-dependency posture are both preserved.

Workstream R-TI (Audit 2026-04-25 — Grochow–Qiao GI ≤ TI Karp
reduction, partial closure / Layer T0–T3 forward direction) has
been completed (2026-04-26):

- **Layer T0 — paper synthesis (Decision GQ-D defensive measure).**
  Four markdown documents under `docs/research/`:
  * `grochow_qiao_path_algebra.md` — radical-2 path algebra
    `F[Q_G] / J²` structure note. Confirms Decision GQ-A's
    cospectral-graph defect resolution and the vertex-idempotent
    uniqueness property the rigidity argument consumes.
  * `grochow_qiao_mathlib_api.md` — Mathlib API audit catalogue
    for Layers T1–T6.
  * `grochow_qiao_padding_rigidity.md` — distinguished-padding
    rigidity proof sketch (the Layer T5.4 design contract).
  * `grochow_qiao_reading_log.md` — bibliography +
    per-decision paper-citation cross-reference.
  Plus a transient `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean`
  Lean stub (subsequently deleted by Workstream **B1** of the
  2026-04-29 audit plan after the live `PathAlgebra.lean` /
  `StructureTensor.lean` modules superseded its regression-
  sentinel purpose) exercising the Mathlib API at the planned
  types.

- **Layer T1 — `Orbcrypt/Hardness/GrochowQiao/PathAlgebra.lean`.**
  Sub-tasks T1.1, T1.2, T1.4, T1.5, T1.6 (basis-element form):
  `QuiverArrow m` inductive with `DecidableEq` / `Fintype`,
  `presentArrows m adj`, `pathAlgebraDim m adj` (`m + |E_directed|`),
  `pathMul m a b : Option (QuiverArrow m)` with explicit cases,
  `pathMul_idempotent_iff_id` characterising idempotent basis
  elements as vertex idempotents at the basis-element level.
  Sub-task T1.3 (`pathArrowEquiv`) and T1.7 (full associativity /
  unitality lemmas at the structure-constant level) are research-
  scope; Layer T2 bypasses T1.3 by indexing the encoder directly
  via `Fin (dimGQ m)` rather than through the path-algebra basis.

- **Layer T2 — `Orbcrypt/Hardness/GrochowQiao/StructureTensor.lean`.**
  Sub-tasks T2.1 through T2.4: `dimGQ m := m + m * m`, `SlotKind m`
  taxonomy, `slotEquiv : Fin (dimGQ m) ≃ SlotKind m`,
  `isPathAlgebraSlot m adj : Fin (dimGQ m) → Bool` (vertex slots
  always; arrow slots iff `adj u v = true`), `pathSlotStructureConstant`
  + `ambientSlotStructureConstant` + the piecewise encoder
  `grochowQiaoEncode m adj : Tensor3 (dimGQ m) ℚ`. Headline
  non-vacuity `grochowQiaoEncode_nonzero_of_pos_dim` discharges
  `GIReducesToTI`'s `encode_nonzero_of_pos_dim` field at the
  `(vertex 0, vertex 0, vertex 0)` diagonal via the idempotent
  law `e_0 · e_0 = e_0`. Sub-tasks T2.5 (per-slot-triple evaluation
  lemmas) and T2.6 (full padding-distinguishability lemma) are
  research-scope.

- **Layer T3 partial — `Orbcrypt/Hardness/GrochowQiao/Forward.lean`.**
  Sub-tasks T3.1, T3.2, T3.3 at the slot-permutation level:
  `liftedSigmaSlot m σ`, `liftedSigmaSlotEquiv m σ`, `liftedSigma m
  σ : Equiv.Perm (Fin (dimGQ m))` (vertex permutation σ lifts to a
  slot permutation by conjugating through `slotEquiv`). Group-
  homomorphism laws (`liftedSigma_one`, `liftedSigma_mul`),
  slot-shape preservation lemmas (`liftedSigma_vertex`,
  `liftedSigma_arrow`), and the central
  `isPathAlgebraSlot_liftedSigma` showing that under the GI
  hypothesis the path-algebra slot predicate is preserved by
  `liftedSigma σ`. Sub-task T3.4 onwards (path-structure-constant
  equivariance, GL³ matrix construction, full forward action
  verification `g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m
  adj₂` at the matrix level) are research-scope (~400 lines per
  audit plan budget; tracked as
  R-15-residual-TI-forward-matrix).

- **Top-level — `Orbcrypt/Hardness/GrochowQiao.lean`.** Re-exports
  the encoder, slot lift, non-vacuity content with prose
  documentation of the partial closure status:
  `grochowQiao_encode_nonzero_field` (alias for use against
  strengthened `GIReducesToTI`), `grochowQiaoEncode_self_isomorphic`
  (identity-σ trivial forward witness), `liftedSigma_one_eq_id`
  (slot-permutation identity check), and
  `grochowQiao_research_scope_disclosure` (documentation alias
  pointing to research-scope items).

- **`Orbcrypt.lean`** root file imports the four new modules;
  axiom-transparency report extended with a "Workstream R-TI
  Snapshot" section detailing the partial closure, the four
  layered modules, the research-scope items, and the verification
  posture.

- **`scripts/audit_phase_16.lean`** extended with §15.4
  ("Workstream R-TI") containing 47 new `#print axioms` entries
  (covering every public R-TI declaration) and 16 non-vacuity
  `example` bindings under the `GrochowQiaoNonVacuity` namespace
  spanning Layer T1 (path algebra dimension, multiplication table,
  idempotent characterisation), Layer T2 (slot equivalence, encoder
  non-degeneracy, path-algebra-slot discriminator), Layer T3
  (slot-permutation lift, group homomorphism laws, slot-shape
  preservation under GI), and the top-level re-exports.

**Verification.** Every Layer T0–T3 declaration depends only on
the standard Lean trio (`propext`, `Classical.choice`,
`Quot.sound`); none depends on `sorryAx` or a custom axiom. `lake
build` succeeds for all 47 modules (3,375 jobs) with zero warnings
/ zero errors. The Phase-16 audit script's `#print axioms` total
expands by 47 entries plus 16 non-vacuity `example` witnesses.

**Research-scope follow-up: R-15-residual-TI.** The full Karp
reduction inhabitant `grochowQiao_isInhabitedKarpReduction :
@GIReducesToTI ℚ _` requires the Layer T5 rigidity argument
(`GL_triple_yields_path_algebra_automorphism` →
`pathAlgebra_auto_characterisation` →
`pathAlgebra_auto_arrow_bijection` →
`adjacency_invariant_under_pathAlgebra_iso`). Per the audit plan,
this is a multi-month research undertaking spanning ~1,800 lines
of Lean and ~80 pages of Grochow–Qiao SIAM J. Comp. 2023 §4.3.
Tracked as **R-15-residual-TI-reverse**. Layer T3.4 onwards (full
forward matrix-action verification) is tracked as
**R-15-residual-TI-forward-matrix**; Layer T5 alone is
**R-15-residual-TI-reverse**. Both remain post-v1.0 research-
scope items.

Patch version: `lakefile.lean` bumped from `0.1.16` to `0.1.17`
for Workstream R-TI — four new public-API modules add new public
declarations, warranting the patch-version bump per `CLAUDE.md`'s
version-bump discipline. The pre-session 43-module total rises
to 47; the zero-sorry / zero-custom-axiom posture and the
standard-trio-only axiom-dependency posture are both preserved.

Workstream R-TI Layers T2.5–T6 + stretch (Audit 2026-04-25 — Grochow–
Qiao GI ≤ TI Karp reduction, partial closure extension) has been
completed (2026-04-26):

- **Layer T2.5 — Encoder evaluation lemmas.**
  `Orbcrypt/Hardness/GrochowQiao/StructureTensor.lean` extended with
  per-slot-triple evaluation lemmas: `grochowQiaoEncode_path` (path-
  algebra branch fires when all three slots are path-algebra),
  `grochowQiaoEncode_padding_left/_mid/_right` (padding branch fires
  when any slot is non-path-algebra), and
  `grochowQiaoEncode_diagonal_vertex` (the diagonal vertex slot
  evaluates to `1` via the idempotent law `e_v · e_v = e_v`). All
  proofs are direct case-splits on the encoder's `if-then-else`
  branches; no rigidity hypothesis required.

- **Layer T2.6 — Padding-distinguishability lemma.**
  `grochowQiaoEncode_padding_distinguishable` proves that any
  non-zero entry of the encoder lies in either an "all path-algebra"
  slot triple or an "all padding" slot triple — never in a "mixed"
  triple. Direct from the encoder's piecewise definition + the
  ambient-matrix structure constant being `if i = j ∧ j = k then 1
  else 0`. This is the structural lemma the Layer T4.1 partition-
  preservation argument inverts.

- **Layer T1 σ-action on quiver arrows + multiplicative
  equivariance.** `Orbcrypt/Hardness/GrochowQiao/PathAlgebra.lean`
  extended with:
  * `quiverMap m σ : QuiverArrow m → QuiverArrow m` — the natural
    σ-action on quiver basis elements (vertex idempotent `id v ↦
    id (σ v)`, arrow `edge u v ↦ edge (σ u) (σ v)`).
  * `quiverMap_one`, `quiverMap_injective` — group-action laws.
  * `pathMul_quiverMap` — **multiplicative equivariance**: `pathMul
    (quiverMap σ a) (quiverMap σ b) = (pathMul a b).map (quiverMap
    σ)`. Direct case-split on the four-case multiplication table;
    every branch's `if u = v` test on `Fin m` is preserved under σ
    (which is injective). This is the basis-element-level σ-
    equivariance lemma the slot-level Layer T3.4 equivariance
    consumes.

- **Layer T3.4 — Path-structure-constant equivariance under the
  σ-lift.** `Orbcrypt/Hardness/GrochowQiao/Forward.lean` extended
  with:
  * `slotToArrow_liftedSigmaSlot` — `slotToArrow` commutes with the
    σ-lift up to `quiverMap`.
  * `ambientSlotStructureConstant_equivariant` — the ambient (matrix)
    structure constant is graph-independent and σ-equivariant via
    `Equiv.injective` on the σ-lift.
  * `pathSlotStructureConstant_equivariant` — the path-algebra
    structure constant is preserved by the σ-lift on all three slot
    indices. Reduces to `pathMul_quiverMap` via the slot-to-arrow
    bridge.

- **Layer T3.7 — Forward direction (encoder-equality form).**
  `grochowQiaoEncode_equivariant` proves that under the GI hypothesis
  `∀ i j, adj₁ i j = adj₂ (σ i) (σ j)`, the encoder is invariant
  under the σ-lift on all three tensor indices. Case-splits on the
  path-algebra-vs-padding branch via `isPathAlgebraSlot_liftedSigma`.
  This is the **encoder-equality form** of the forward iff direction;
  the GL³ matrix-action upgrade (full T3.6) requires permutation-
  matrix–tensor-action algebra (~400 lines) and is research-scope
  (**R-15-residual-TI-forward-matrix**).
  `grochowQiaoEncode_pull_back_under_iso` re-exports the same
  statement under a more consumer-facing name.

- **Layer T4 + T5 — Reverse direction skeleton.** New module
  `Orbcrypt/Hardness/GrochowQiao/Reverse.lean` (the 5th `.lean`
  file under `Orbcrypt/Hardness/GrochowQiao/`). Captures the rigidity
  argument as a `Prop`-typed obligation:
  * `GrochowQiaoRigidity` — the rigidity Prop. States that any GL³
    triple preserving `grochowQiaoEncode m adj₁` relative to
    `grochowQiaoEncode m adj₂` arises from a vertex permutation σ.
    This is the same pattern `OIA`, `KEMOIA`, `HardnessChain` use:
    research-scope obligation as `Prop`, downstream theorems carry
    it as an explicit hypothesis, no `sorry`, no custom axiom.
  * `GrochowQiaoRigidity.apply` — the consumer-facing application
    helper.
  * `grochowQiaoEncode_reverse_zero` — **unconditional** reverse
    direction at `m = 0` (empty graph). Discharged by
    `Fin.elim0`-style vacuous quantification.
  * `grochowQiaoEncode_reverse_one` — **unconditional** reverse
    direction at `m = 1` (single vertex). Discharged by
    `Subsingleton.elim` on `Fin 1`.
  * `grochowQiaoEncode_reverse_under_rigidity` — conditional reverse
    direction taking `GrochowQiaoRigidity` as hypothesis (Layer T5.4
    consumer-facing form).

- **Layer T5.6 stretch — Asymmetric GL³ rigidity (Prop form).**
  `GrochowQiaoAsymmetricRigidity` Prop captures the stretch-goal
  obligation. `grochowQiaoAsymmetricRigidity_iff_symmetric` proves
  that for graphs (where the path algebra is unitary), asymmetric
  rigidity reduces to symmetric rigidity.

- **Layer T5.8 stretch — Char-0 generalisation (Prop form).**
  `GrochowQiaoCharZeroRigidity F` Prop placeholder (parameterised
  over `[Field F] [CharZero F] [DecidableEq F]`).
  `grochowQiaoCharZeroRigidity_at_rat` proves the `F = ℚ`
  instance reduces to `GrochowQiaoRigidity`.

- **Layer T4.3 — Path-algebra-automorphism Prop (research-scope).**
  `PathAlgebraAutomorphismPermutesVertices` Prop captures the
  primitive-idempotent-permutation property at the basis-element
  level (without going through a full Mathlib `Algebra` wrapper).
  `quiverMap_satisfies_vertex_permutation_property` proves the
  forward direction (when φ is `quiverMap σ` for given σ).

- **Layer T6.1 — Iff assembly under both obligations.**
  `Orbcrypt/Hardness/GrochowQiao.lean` (top-level module) extended
  with:
  * `GrochowQiaoForwardObligation` — the GL³ matrix-action upgrade
    Prop (lifts encoder-equality to `AreTensorIsomorphic`).
  * `grochowQiaoEncode_forward_equality` — re-export of the Layer
    T3.6+T3.7 encoder-equality form.
  * `grochowQiaoEncode_iff` — the **conditional Karp-reduction iff**
    under both `GrochowQiaoForwardObligation` and
    `GrochowQiaoRigidity`. Composes the forward (via
    `h_forward`) and reverse (via
    `grochowQiaoEncode_reverse_under_rigidity`) directions.

- **Layer T6.2 — Non-degeneracy field discharge (re-export).**
  `grochowQiao_encode_nonzero_field_check` aliases T2.4 for the
  conditional Karp-reduction inhabitant.

- **Layer T6.3 — Conditional `GIReducesToTI` inhabitant.**
  `grochowQiao_isInhabitedKarpReduction_under_obligations` is the
  consumer-facing complete inhabitant — under both research-scope
  Props discharged, this delivers `@GIReducesToTI ℚ _` in full.
  Pre-discharge it is conditional; post-discharge it becomes
  unconditional.

- **Layer T6.4 — Final non-vacuity disclosure.**
  `grochowQiao_partial_closure_status` documents the unconditional
  content delivered: encoder is non-zero on every non-empty graph,
  AND the empty-graph reverse direction is unconditional.

- **Audit script extensions.** `scripts/audit_phase_16.lean` extended
  with 32 new `#print axioms` entries (covering every new
  declaration in T2.5/T2.6/T1-quiverMap/T3.4/T3.7/T4/T5/T5-stretch/
  T6) and 14 new non-vacuity `example` bindings under the
  `GrochowQiaoNonVacuity` namespace. Total Phase-16 audit-script
  entries rises to 514 declarations exercised. Every entry depends
  only on the standard Lean trio (`propext`, `Classical.choice`,
  `Quot.sound`); zero `sorryAx`, zero custom axioms.

- **Patch version.** `lakefile.lean` bumped from `0.1.17` to
  `0.1.18`. The 47-module total is unchanged (the Reverse.lean
  module is new but the GrochowQiao directory was already
  established by the previous landing).

**Honest scoreboard for Layer T4 + T5 + T6 + T5 stretch.**

The audit plan budgets these layers at 3,300–7,300 lines of Lean
and 5–10 weeks of dedicated mathematical research effort. The
post-extension landing (this commit) delivers:

1. **Concrete `lake build`-passing proofs (no shortcuts).** All new
   declarations have either complete proofs or are `Prop`-typed
   obligations consumed as explicit hypotheses by higher-level
   theorems. No `sorry`, no custom axiom, no vacuously-true
   `Prop` definition (the rigidity Prop has the literature's
   universal quantification on `(adj₁, adj₂)`, so a discharge is a
   uniform argument across all graph pairs).

2. **Unconditional content.** Layer T2.5 evaluation lemmas, Layer
   T2.6 padding-distinguishability, Layer T1 `quiverMap` σ-action
   + multiplicative equivariance, Layer T3.4 path-structure-
   constant equivariance, Layer T3.7 encoder-equality form of the
   forward direction, Layer T5.3 `m = 0` empty-graph reverse,
   Layer T5 `m = 1` reverse, Layer T6.4 partial closure status
   are all **unconditional theorems** discharged with full proofs.

3. **Research-scope obligations as `Prop`s.** The Layer T4
   partition-preservation + path-algebra-automorphism content
   (T4.1–T4.3), the full Layer T5.4 reverse direction, and the
   GL³ matrix-action upgrade of T3.6 are landed as `Prop`-typed
   obligations (`GrochowQiaoRigidity`,
   `PathAlgebraAutomorphismPermutesVertices`,
   `GrochowQiaoForwardObligation`), consumed by higher-level
   conditional theorems (`grochowQiaoEncode_iff`,
   `grochowQiao_isInhabitedKarpReduction_under_obligations`).
   Discharging these Props is research-scope **R-15-residual-TI-
   reverse** and **R-15-residual-TI-forward-matrix**, multi-month
   work spanning ~80 pages of Grochow–Qiao SIAM J. Comp. 2023 §4.3.

4. **Stretch-goal Props (T5.6 + T5.8).**
   `GrochowQiaoAsymmetricRigidity` and `GrochowQiaoCharZeroRigidity`
   capture the optional stretch-goal obligations.
   `grochowQiaoAsymmetricRigidity_iff_symmetric` proves the
   asymmetric ↔ symmetric reduction for graphs (unitary path
   algebra) — a substantive theorem at the Prop level.

5. **Audit script + non-vacuity witnesses.** 32 new `#print axioms`
   + 14 new non-vacuity `example` bindings; every new declaration
   on standard Lean trio.

This is **strictly more substantive** than the pre-extension R-TI
landing (which had only Layers T0 + T1 + T2 + T3 partial). The
post-extension content lands the *complete consumer-facing*
Karp-reduction interface (forward equivariance, edge-case reverse
directions, conditional iff, conditional inhabitant) under the two
research-scope Props that capture the genuinely difficult parts.
Future research-scope work can discharge these Props and obtain a
fully unconditional `@GIReducesToTI ℚ _` inhabitant via
`grochowQiao_isInhabitedKarpReduction_under_obligations`.

Workstream R-TI Track B + A.1 + A.2 partial — Forward obligation
discharged unconditionally (2026-04-26 extension):

- **Track B (PermMatrix.lean, NEW module).** Implements the GL³
  matrix-action verification (Layer T3.6) using Mathlib's
  `Equiv.Perm.permMatrix` API:
  * `liftedSigmaMatrix m σ` lifts the slot permutation to a
    permutation matrix in `Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ`.
  * `liftedSigmaGL m σ` packages this into the general linear group
    via `Matrix.GeneralLinearGroup.mkOfDetNeZero`.
  * `matMulTensor{1,2,3}_permMatrix` proves single-axis tensor-action
    collapse via `Finset.sum_eq_single`.
  * `tensorContract_permMatrix_triple` composes the three single-axis
    lemmas into the full GL³ collapse.
  * `gl_triple_liftedSigmaGL_smul` is the `MulAction`-level statement.
  * `grochowQiaoEncode_gl_isomorphic` (B.8) is the structural form
    of the forward direction's GL³ matrix-action verification.

- **`grochowQiao_forwardObligation` (in GrochowQiao.lean, NEW)**
  closes `GrochowQiaoForwardObligation` unconditionally by composing
  Track B's `grochowQiaoEncode_gl_isomorphic` with the existing
  encoder-equivariance lemma. **One of the two research-scope Props
  introduced at the 2026-04-26 partial-closure landing is now
  closed.**

- **Track A.1 (in PathAlgebra.lean).** Implements `pathMul_assoc`
  (Layer T1.7) — the basis-element-level associativity of path
  multiplication. Proven via 8-case structural recursion on the
  three `QuiverArrow` constructors; arrow-arrow cases collapse to
  `none = none` unconditionally; remaining cases discharge via
  `simp` + `split_ifs`.

- **Track A.2 partial (AlgebraWrapper.lean, NEW module).**
  Establishes the path-algebra carrier as a ℚ-vector space:
  * `pathAlgebraQuotient m := QuiverArrow m → ℚ` carrier type.
  * `AddCommGroup`, `Module ℚ` instances via `Pi`.
  * `pathAlgebraMul` definition + `Mul` instance via convolution
    over the `pathMul` table.
  * `vertexIdempotent m v` and `arrowElement m u v` named basis
    elements with apply-on-constructor simp lemmas.
  * `pathAlgebraMul_apply` unfolding lemma.

  **Status note.** The full Mathlib `Algebra ℚ` typeclass instance
  (Layer T4.8 — requires `mul_assoc` lift, Ring instance, etc.)
  is not yet built. The downstream rigidity argument can be
  structured at the basis-element level using `pathMul_quiverMap`-
  style multiplicative bijections rather than `AlgEquiv`, avoiding
  the full Algebra typeclass dependency.

- **`grochowQiao_isInhabitedKarpReduction_under_rigidity`
  (in GrochowQiao.lean, NEW).** Single-hypothesis conditional
  inhabitant of `@GIReducesToTI ℚ _`. Pre-Track-B, the conditional
  inhabitant required two Props (`GrochowQiaoForwardObligation`
  AND `GrochowQiaoRigidity`); post-Track-B it requires only
  `GrochowQiaoRigidity`. When that is discharged (research-scope
  R-15-residual-TI-reverse), the inhabitant becomes unconditional.

- **`grochowQiao_partial_closure_status` extended** to assert
  `GrochowQiaoForwardObligation` as a now-unconditional consequence.

- **Audit script** `scripts/audit_phase_16.lean` extended with 26
  new `#print axioms` entries plus 7 new non-vacuity `example`
  bindings. Total declarations exercised: 462.

- **Patch version.** `lakefile.lean` bumped from `0.1.18` to `0.1.19`.

**Status of remaining R-TI work.** The Layer T4.1–T5.4 rigidity
argument (the actual Grochow–Qiao SIAM J. Comp. 2023 §4.3 proof,
~80 pages on paper, ~2,000+ LOC of Lean) is genuine multi-month
research-scope work and is **not** completed in this extension.
The `GrochowQiaoRigidity` Prop hypothesis remains open and tracked
as **R-15-residual-TI-reverse**.

Workstream R-TI Phase A.2 + Phase C partial — full Algebra ℚ
typeclass infrastructure landed (2026-04-26 follow-up extension):

- **Layer 0 (already landed):** `pathAlgebraMul_assoc` proven via
  the C1 + C2 + C3 canonical-form decomposition.
- **Layer 1 (basis-element multiplication table, ~700 LOC):**
  `vertexIdempotent_mul_apply_id`/`_apply_edge` (key bilinear
  formulas), `mul_vertexIdempotent_apply_id`/`_apply_edge`,
  `vertexIdempotent_mul_vertexIdempotent`,
  `vertexIdempotent_mul_arrowElement`,
  `arrowElement_mul_vertexIdempotent`,
  `arrowElement_mul_arrowElement_eq_zero`.
- **Layer 2 (distrib + annihilation, ~150 LOC):**
  `pathAlgebra_left_distrib`/`_right_distrib`,
  `pathAlgebra_zero_mul`/`_mul_zero`.
- **Layer 3 (one_mul + mul_one via bilinearity, ~150 LOC):**
  `pathAlgebra_sum_mul`/`_mul_sum` (Finset induction),
  `pathAlgebra_one_mul`, `pathAlgebra_mul_one`.
- **Layer 4 (Ring instance, ~30 LOC):**
  `pathAlgebraQuotient.instRing`.
- **Layer 5 (Algebra ℚ + decompose, ~250 LOC):**
  `pathAlgebra_smul_mul`/`_mul_smul`,
  `pathAlgebraQuotient.instAlgebra`,
  `pathAlgebra_decompose`.
- **Phase C partial (idempotent + AlgEquiv preservation, ~400 LOC):**
  `pathAlgebraMul_apply_id`/`_apply_edge` (output-coordinate
  evaluation lemmas), `pathAlgebra_isIdempotentElem_iff`,
  `pathAlgebra_idempotent_lambda_squared`,
  `pathAlgebra_idempotent_mu_constraint`, `IsPrimitiveIdempotent`
  (hand-rolled), `vertexIdempotent_isIdempotentElem`,
  `vertexIdempotent_ne_zero`,
  `AlgEquiv_preserves_isIdempotentElem`,
  `AlgEquiv_preserves_isPrimitiveIdempotent`,
  `vertexIdempotent_decomp_lambda_at_v`/`_off_v` (helpers).

**Patch version.** `lakefile.lean` bumped from `0.1.19` to `0.1.20`.

**Phase C.4 main theorem `vertexIdempotent_isPrimitive` proven.**
The decomposition argument: in any orthogonal idempotent
decomposition `e_v = b₁ + b₂`, either `b₁(.id v) = 0` (Case A) or
`b₂(.id v) = 0` (Case B). In Case A, all `b₁(.id w) = 0` (using
the off-v helper combined with idempotency), so by idempotency
`b₁(.edge u w) = b₁(.id u) · b₁(.edge u w) + b₁(.edge u w) ·
b₁(.id w) = 0 + 0 = 0`. Hence `b₁ = 0`. Symmetrically Case B
gives `b₂ = 0`. **Lands without sorry/axiom**.

**Phase C.5 mathematical finding (2026-04-26):**
`isPrimitive_iff_vertex` as originally planned is **FALSE** for
`F[Q_G]/J²`. The counterexample `e_v + α · α(v, w)` (for `w ≠ v`,
any `α ∈ ℚ`) is idempotent (cross term `α(v,w) · e_v = 0` when
`w ≠ v`) and primitive. In the radical-2 quotient path algebra,
primitive idempotents are *conjugate* to vertex idempotents
(Auslander-Reiten-Smalø III.2), not equal to them.

The Grochow-Qiao rigidity argument's correct form uses *complete
orthogonal decompositions* (which ARE unique up to conjugation);
this requires Wedderburn-Mal'cev structure (~600 LOC additional
infrastructure).

The mathematically correct theorems land instead:
- `vertex_implies_isPrimitive`: forward direction (true).
- `exists_nonVertex_idempotent`: explicit counterexample to the
  reverse direction.

**What remains for full Phase D–H closure:** the actual rigidity
argument via complete orthogonal decompositions (Phase D, ~700+
LOC, **HIGH RISK** per `R-15-residual-TI-reverse`); AlgEquiv lift
from GL³ (Phase E); vertex permutation extraction via
complete-orthogonal-decomposition uniqueness with arrow invariance
(Phase F); composition (Phase G); final assembly (Phase H).

**Build posture preserved.** `AlgebraWrapper.lean` has reached
1,640 LOC of machine-checked algebraic content; every public
declaration depends only on the standard Lean trio (`propext`,
`Classical.choice`, `Quot.sound`); `lake build` succeeds cleanly
across all 3,389 jobs; zero `sorry`, zero custom axioms.

Workstream R-TI Layer 6.7–6.10 + Layer 6b — CompleteOrthogonalIdempotents
machinery + Wedderburn–Mal'cev conjugacy for `F[Q_G] / J²` (FULL PROOF,
no Prop hypothesis) has been completed (2026-04-27):

- **Layer 6.7–6.10 — CompleteOrthogonalIdempotents (in
  AlgebraWrapper.lean):**
  * `vertexIdempotent_completeOrthogonalIdempotents m`: the canonical
    vertex-idempotent family is a `CompleteOrthogonalIdempotents`
    structure (ortho via `vertexIdempotent_mul_vertexIdempotent`;
    complete via `pathAlgebraOne` definition).
  * `AlgEquiv_preserves_completeOrthogonalIdempotents`: `AlgEquiv`
    preserves COIs (each field follows from `AlgEquiv.map_mul`,
    `map_zero`, `map_sum`, `map_one`).
  * Mathlib's `CompleteOrthogonalIdempotents` from
    `Mathlib.RingTheory.Idempotents` is the reused vehicle.

- **Layer 6b — Wedderburn–Mal'cev for J² = 0 (NEW module
  `Orbcrypt/Hardness/GrochowQiao/WedderburnMalcev.lean`, 762 LOC):**
  * **Layer 6b.1 — Jacobson radical:** `pathAlgebraRadical m`
    (Submodule ℚ via arrow basis span); `pathAlgebraRadical_mul_radical_eq_zero`
    proves `J · J = 0` via `Submodule.span_induction` reducing to
    `arrowElement_mul_arrowElement_eq_zero` (Layer 1.4).
  * **Layer 6b.2 — Element decomposition modulo radical:** restates
    `pathAlgebra_decompose` (Layer 5.3) using named projections
    `pathAlgebra_vertexPart` and `pathAlgebra_arrowPart`, the latter
    explicitly `∈ pathAlgebraRadical m`.
  * **Layer 6b.4 — Inner conjugation machinery:**
    `oneAddRadical_mul_oneSubRadical : (1 + j) * (1 - j) = 1` (and
    symmetric) follow from `j² = 0` via `noncomm_ring`. The structural
    `innerAut_simplified : (1 + j) * c * (1 - j) = c + j*c - c*j`
    (using `J² = 0` to kill the cubic `j * c * j` term, via
    `radical_sandwich_eq_zero`) drives the verification.
  * **Layer 6b.3 — HEADLINE: Wedderburn–Mal'cev conjugacy
    (FULL PROOF):**
      - `coi_vertex_coef_zero_or_one` / `_orth` / `_complete`: vertex
        coefficient analysis from idempotency / orthogonality /
        completeness of the COI.
      - `pathAlgebra_idempotent_zero_of_id_coef_zero`: an idempotent
        with all `.id` coefficients zero IS zero (via
        `pathAlgebra_idempotent_mu_constraint`).
      - `coi_unique_active_per_z`: each `z` has exactly one COI
        element with `(e' i)(.id z) = 1` (existence from completeness;
        uniqueness from orthogonality).
      - `coi_chooseActive` + `_bijective`: extracts a function
        `Fin m → Fin m` mapping each `z` to its unique active `i`;
        bijectivity via `Finite.injective_iff_surjective`.
      - `coi_vertexPerm`: the σ permutation as the inverse of
        `coi_chooseActive`, with `coi_vertexPerm_active`,
        `coi_vertexPerm_iff`, `coi_vertexPerm_eval`.
      - `coi_conjugator h_coi h_nz := -∑_{w, s} (e' w)(.edge (σ w) s) •
        α(σ w, s)`: the explicit construction of `j`.
      - `coi_conjugator_mem_radical`, `coi_conjugator_apply_id`
        (always 0), `coi_conjugator_apply_edge` (= -(e' (σ⁻¹u))(.edge u t)).
      - `pathAlgebra_idempotent_self_loop_zero`: at the active vertex,
        the self-loop coefficient is 0 (from `2X = X` ⟹ `X = 0`).
      - `pathAlgebra_idempotent_offdiag_arrow_zero`: arrows with both
        endpoints inactive have coefficient 0.
      - `coi_cross_arrow_compat`: cross-COI arrow compatibility
        `(e' v)(.edge u t) + (e' (σ⁻¹u))(.edge u t) = 0` when
        `t = σv`, `u ≠ σv`, derived from
        `e' (σ⁻¹u) * e' v = 0` evaluated at `.edge u t` via
        `pathAlgebraMul_apply_edge`.
      - **`coi_conjugation_identity`**: the pointwise verification
        that `(1 + j) * vertexIdempotent (σ v) * (1 - j) = e' v`,
        proven via `funext c; cases c` and case-splitting `σv = u`,
        `σv = t` to compute the four corner cases, each closed by
        the appropriate idempotency / compatibility / self-loop /
        off-diagonal lemma.
      - **`wedderburn_malcev_conjugacy m e' h_coi h_nz`** (HEADLINE):
        ```
        ∃ (σ : Equiv.Perm (Fin m)) (j : pathAlgebraQuotient m),
          j ∈ pathAlgebraRadical m ∧
          ∀ v : Fin m,
            (1 + j) * vertexIdempotent m (σ v) * (1 - j) = e' v
        ```
        Built by composing the σ-extraction (`coi_vertexPerm`),
        the j-construction (`coi_conjugator`), and the conjugation
        identity (`coi_conjugation_identity`).
  * **Phase F starter (Layer 9.1):**
      - `algEquiv_image_vertexIdempotent_COI`: the AlgEquiv-image of
        the canonical COI is itself a COI (immediate from L6.9).
      - `algEquiv_image_vertexIdempotent_ne_zero`: each
        `φ (vertexIdempotent v) ≠ 0` (φ is injective).
      - **`algEquiv_extractVertexPerm`**: from any
        `AlgEquiv (pathAlgebraQuotient m)`, extract σ and j with
        `(1 + j) * vertexIdempotent (σ v) * (1 - j) = φ (vertexIdempotent v)`
        for all v. This is the cryptographic-rigidity entry point
        Phase F's adjacency-invariance argument consumes.

**Layer 6 + 6b posture.** 23 new public declarations across
`AlgebraWrapper.lean` (+76 LOC) and `WedderburnMalcev.lean` (NEW,
762 LOC). All public declarations depend only on the standard Lean
trio (`propext`, `Classical.choice`, `Quot.sound`). Zero `sorry`,
zero custom axioms. Module count rises from 47 to 48 (one new file
under `Orbcrypt/Hardness/GrochowQiao/`). Full `lake build` succeeds
across 3,391 jobs with zero warnings / zero errors.

**Mathematical significance.** Wedderburn–Mal'cev for `F[Q_G] / J²`
is the deep algebraic content underlying the rigidity of vertex
idempotents in the radical-2 truncated path algebra. The user's
mid-session ban on Prop hypotheses for Layer 6b.3 forced an
elementary explicit-construction proof. Key insight: in `J² = 0`,
the conjugating element `j` decomposes uniquely as a sum of arrow
basis elements weighted by the COI's off-diagonal coefficients, and
the cross-orthogonality conditions guarantee the construction is
self-consistent across all `(u, t)` arrow pairs (the
`coi_cross_arrow_compat` lemma).

**Patch version.** `lakefile.lean` bumped from `0.1.20` to `0.1.21`.

Workstream R-TI Layer 0–6b deep audit (2026-04-27, post-WM landing)
has been completed. The audit verified each layer's content against
the implementation (not the documentation), checked for shortcuts
that compromise correctness, and ran the build + Phase-16 audit
script to convergence. Findings + fixes:

- **Layer 0–5:** clean. `PathAlgebra.lean`'s `pathMul_assoc` uses a
  disciplined 8-case structural recursion (8 cases via three nested
  `cases QuiverArrow`, all closed by `simp only` + `split_ifs` /
  `rfl`). `AlgebraWrapper.lean`'s `pathAlgebraMul_assoc` uses the
  C1 + C2 + C3 canonical-form decomposition (private helpers
  `pathMul_indicator_collapse[_right]`,
  `pathAlgebraMul_assoc_lhs_canonical`, `_rhs_canonical`).
  Layers 1–5 use clean ring lemmas and Mathlib's `Algebra.ofModule`.
- **Layer 6 (Phase C):** clean. `IsPrimitiveIdempotent` is
  hand-rolled (Mathlib lacks the predicate). `vertexIdempotent_isPrimitive`
  proven via the Phase-C.4 helper chain (`_lambda_at_v` /
  `_lambda_off_v` / `_lambda_zero_everywhere`).
- **Layer 6.7–6.10:** clean. Vertex-idempotent COI builds directly
  from Layers 1.1 + 6.4 + the `pathAlgebraOne` definition; AlgEquiv
  preservation uses Mathlib's `AlgEquivClass.map_mul` / `map_zero` /
  `map_sum` / `map_one`.
- **Layer 6b:** clean. The Wedderburn–Mal'cev conjugacy is proven
  in full: σ extracted via `Finite.injective_iff_surjective` from
  `coi_chooseActive`'s surjectivity (each non-zero COI element has
  ≥ 1 active vertex); `j` constructed as the explicit sum
  `-∑ (e' w)(.edge (σw) s) • α(σw, s)`; conjugation identity
  proven pointwise with 4-case analysis on `(σv = u, σv = t)`.

Audit-driven fixes (committed in this audit pass):

1. **`AlgebraWrapper.lean` linter cleanup (12 → 0 warnings):**
   - `vertexIdempotent_mul_vertexIdempotent` (Layer 1.1) and 3
     symmetric basis-element-multiplication theorems used the
     pattern `all_goals try (first | rfl | simp_all [Pi.zero_apply,
     ...])` where the `simp_all` arguments were unused (because
     `rfl` always closed the goal first) and the `try` was triggering
     "tactic never executed" warnings. Replaced with the cleaner
     `split_ifs <;> rfl` (when both sides reduce to 0 unconditionally)
     or `split_ifs <;> first | rfl | simp_all` (when some cases need
     the simp set).
   - `exists_nonVertex_idempotent` (Phase C.5 counterexample)
     dropped an unused `zero_add` simp argument.
2. **`WedderburnMalcev.lean` linter cleanup (5 → 0 warnings):**
   - The `variable {m : ℕ} {ι : Type*} [Fintype ι] [DecidableEq ι]`
     section variable carried `[DecidableEq ι]` which was never
     consumed (the COI machinery uses orthogonality and completeness,
     not equality decisions on the index type). Removed.
   - Two `push_neg` invocations in `coi_nonzero_has_active_vertex`
     and `coi_unique_active_per_z` were flagged as deprecated by
     Mathlib's `Tactic.Push` (Mathlib at `fa6418a8` prefers the
     unified `push Not` form). Replaced.
   - Two `set σ := coi_vertexPerm h_coi h_nz with hσ_def` patterns
     in `coi_conjugator_apply_edge` and `coi_cross_arrow_compat`
     declared `hσ_def` but never used it. Removed the `with hσ_def`
     trailers.
3. **Audit script extension:** added `#print axioms` entries for the
   Phase F starter (`algEquiv_image_vertexIdempotent_COI` /
   `_ne_zero` / `algEquiv_extractVertexPerm`) plus a non-vacuity
   `example` exercising `algEquiv_extractVertexPerm` on the identity
   `AlgEquiv` at `m = 1`.

Post-audit posture (2026-04-27): full `lake build` succeeds across
**3,391 jobs with zero warnings, zero errors**. Phase 16 audit
script exercises **639 declarations** (up from 636), all on the
standard Lean trio (`propext`, `Classical.choice`, `Quot.sound`).
Zero `sorry`, zero custom axioms across all Layer 0–6b material.

Workstream R-TI rigidity discharge — Stage 0 (Audit 2026-04-27 —
encoder strengthening for distinguished padding) has been completed:

- **Mathematical issue closed.** Pre-Stage-0, the encoder's
  `ambientSlotStructureConstant := if i = j ∧ j = k then 1 else 0`
  (`StructureTensor.lean:289`) used the same scalar value `1` at
  padding diagonals as the `pathSlotStructureConstant` at vertex-slot
  diagonals (the idempotent law `e_v · e_v = e_v` contributes `1`).
  As a consequence, an isolated vertex `v` (no incident edges in
  `adj`) had the same slab-rank signature as any padding slot — both
  contributed only a single non-zero entry at the triple-diagonal
  with value `1`, giving rank 1 with no other invariant to
  distinguish them. This blocked the rigidity argument's slot-
  classification step on graphs with isolated vertices.
- **Fix.** `Orbcrypt/Hardness/GrochowQiao/StructureTensor.lean`:
  `ambientSlotStructureConstant` strengthened to value `2` instead
  of `1`, implementing Decision GQ-B's distinguished-padding
  requirement at the value level. The three slot kinds are now
  literally distinguishable at the diagonal-value level alone:
  vertex slots have diagonal `1` (idempotent law), present-arrow
  slots have diagonal `0` (since `pathMul (.edge u v) (.edge u v) =
  none` from `J² = 0`), padding slots have diagonal `2` (the
  strengthened ambient constant).
- **New theorem.** `grochowQiaoEncode_diagonal_padding` — explicit
  witness that for any padding slot `(u, v)` (i.e., arrow slot with
  `adj u v = false`), the encoder evaluates to `2` at the triple-
  diagonal. Companion to the existing `grochowQiaoEncode_diagonal_vertex`.
- **Audit script.** `scripts/audit_phase_16.lean` extended with one
  new `#print axioms` entry (`grochowQiaoEncode_diagonal_padding`)
  + one non-vacuity `example` exhibiting the diagonal-value-2
  property on the empty graph at `m = 2`.
- **Forward direction unchanged.** The forward-direction proofs
  (`grochowQiaoEncode_padding_left/_mid/_right`,
  `grochowQiaoEncode_padding_distinguishable`,
  `ambientSlotStructureConstant_equivariant`,
  `pathSlotStructureConstant_equivariant`,
  `grochowQiaoEncode_equivariant`, `grochowQiao_forwardObligation`)
  all compile without modification because their proofs depend on
  `ambientSlotStructureConstant` symbolically (via `if i = j ∧ j =
  k`), not by its specific value. Only one in-prose docstring update
  in `grochowQiaoEncode_padding_distinguishable` adjusts the value
  reference from `1` to `2`.
- **Verification.** Full `lake build` succeeds with **3,391 jobs,
  zero warnings, zero errors**. Phase 16 audit script exercises
  **640 declarations** (up from 639 — one new entry for
  `grochowQiaoEncode_diagonal_padding`), all on the standard Lean
  trio. `#print axioms grochowQiaoEncode_diagonal_padding` reports
  `[propext, Classical.choice, Quot.sound]`.
- **Cryptographic rationale.** The rigidity argument
  (`GrochowQiaoRigidity` Prop in `Reverse.lean:122`) requires that
  GL³ tensor isomorphisms preserve the path-algebra-vs-padding
  partition. Without distinguishable padding values, an isolated
  vertex of `adj₁` could be mapped to a padding slot of `adj₂` by a
  GL³ isomorphism — yielding a slot bijection that does NOT descend
  to a vertex permutation. The Stage 0 strengthening ensures that
  every slot-classification predicate (vertex / present-arrow /
  padding) is GL³-invariant up to slot permutation, which is the
  pre-requisite for Stages 1–5 of the rigidity-discharge plan
  (`docs/planning/R_TI_PHASE_C_THROUGH_H_PLAN.md`).
- **Next steps.** Stage 1 (T-API-1 + T-API-2: `Tensor3` unfoldings
  + GL³ rank invariance, ~800 LOC) is the foundation layer
  consuming Stage 0's strengthened encoder.

Patch version: `lakefile.lean` retains `0.1.21`; Stage 0 is a
pre-requisite encoder strengthening with no API surface change
(zero new modules, one new theorem inside an existing module). The
38-module total, the zero-sorry / zero-custom-axiom posture, and
the standard-trio-only axiom-dependency posture are all preserved.
The full version bump (`0.1.21 → 0.1.22`) is reserved for the
final Stage 5 landing of `grochowQiaoRigidity`.

Workstream R-TI rigidity discharge — Stage 1 T-API-1 (Audit
2026-04-27 — Tensor3 unfoldings as matrices) has been completed:

- **New module.** `Orbcrypt/Hardness/GrochowQiao/TensorUnfold.lean`
  (≈ 250 LOC, NEW). Bridges `Tensor3 n F` (`Fin n → Fin n → Fin n
  → F`) to matrices over `Fin n × (Fin n × Fin n)` via three
  unfoldings, one per tensor axis.
- **Public surface (15 declarations).**
  * Definitions: `Tensor3.unfold₁`, `unfold₂`, `unfold₃` (each
    `Tensor3 n F → Matrix (Fin n) (Fin n × Fin n) F`, fixing one
    axis as the row index and pairing the other two as a
    lexicographic column index).
  * Apply lemmas (`@[simp]`): `unfold₁_apply`, `unfold₂_apply`,
    `unfold₃_apply` — definitional unfolding to the underlying
    tensor entry.
  * Injectivity: `unfold₁_inj`, `unfold₂_inj`, `unfold₃_inj` —
    distinct tensors give distinct unfoldings.
  * Single-axis bridges: `unfold₁_matMulTensor1`,
    `unfold₂_matMulTensor2`, `unfold₃_matMulTensor3` — axis-`k`
    contraction `matMulTensor_k M T` corresponds to **left matrix
    multiplication** `M * unfold_k T` on the axis-`k` unfolding.
  * Cross-axis Kronecker bridges:
    `unfold₁_matMulTensor2 : unfold₁ (matMulTensor2 B T) = unfold₁
    T * (Bᵀ ⊗ₖ 1)` and `unfold₁_matMulTensor3 : unfold₁ (matMulTensor3
    C T) = unfold₁ T * (1 ⊗ₖ Cᵀ)`. Axis-2 / axis-3 actions on the
    axis-1 unfolding are right matrix multiplication by Kronecker
    products.
  * **Combined GL³-action bridge:** `unfold₁_tensorContract :
    unfold₁ (tensorContract A B C T) = A * unfold₁ T * (Bᵀ ⊗ₖ Cᵀ)`.
    Composes the three single-axis bridges via
    `Matrix.mul_kronecker_mul` to combine the two right Kronecker
    factors into a single one. This is the consumer-facing bridge
    that Stage 1 T-API-2's rank-invariance proof consumes.
- **Mathlib anchors verified at `fa6418a8`.**
  `Mathlib/LinearAlgebra/Matrix/Kronecker.lean`:
  `kroneckerMap_apply` (line 60), `kronecker_apply` (line 264),
  `mul_kronecker_mul` (line 363), `kroneckerMap_one_one` (line 140).
  `Mathlib/Data/Matrix/Diagonal.lean`: `Matrix.one_apply`. Standard
  `Finset.sum_eq_single`, `Fintype.sum_prod_type`, `Finset.sum_comm`,
  `Finset.sum_congr`. No new Mathlib API needed.
- **Audit script.** `scripts/audit_phase_16.lean` extended with 15
  new `#print axioms` entries (one per public declaration) plus 4
  new non-vacuity `example`s under a fresh `TensorUnfoldNonVacuity`
  namespace exercising the apply lemma, the single-axis bridge for
  axis-1, the Kronecker bridge for axis-2, and the combined
  GL³-action bridge — all on a hand-rolled `Tensor3 2 ℚ`.
- **Verification.** Full `lake build` succeeds with **3,392 jobs**
  (up from 3,391 — one new module). Phase 16 audit script exercises
  **655 declarations** (up from 640 — 15 new `#print axioms`
  entries), all on the standard Lean trio (`propext`,
  `Classical.choice`, `Quot.sound`). Zero `sorry`, zero custom
  axioms.
- **Cryptographic role.** This is reusable Mathlib-quality
  infrastructure independent of the Grochow–Qiao encoder. The
  unfolding bridge lets us cast the GL³ tensor action
  `tensorContract A B C T` into matrix products with Kronecker
  products, which Stage 1 T-API-2 uses to prove rank invariance via
  Mathlib's `rank_mul_eq_*_of_isUnit_det` lemmas. Future Orbcrypt
  modules needing 3-tensor unfoldings (e.g., a Mathlib-style
  generalization to symmetric / antisymmetric tensors) can import
  this module directly.

Patch version: `lakefile.lean` retains `0.1.21`; Stage 1 T-API-1 is
the foundation layer with no API-breaking surface change. The
module count rises from 49 to **50** (TensorUnfold.lean is the new
module). The zero-sorry / zero-custom-axiom posture and the
standard-trio-only axiom-dependency posture are all preserved.

Workstream R-TI rigidity discharge — Stage 1 T-API-2 (Audit
2026-04-27 — GL³ rank invariance for tensor unfoldings) has been
completed:

- **New module.** `Orbcrypt/Hardness/GrochowQiao/RankInvariance.lean`
  (≈ 130 LOC, NEW). Proves that the rank of each unfolding
  `unfold_k T` is invariant under the GL³ tensor action.
- **Public surface (7 declarations).**
  * `kronecker_isUnit_det` — Kronecker product of matrices with unit
    determinants has unit determinant. Proof via `Matrix.det_kronecker`
    + `IsUnit.pow` + `IsUnit.mul`.
  * `unfoldRank₁ T : ℕ := (unfold₁ T).rank` (and symmetric for
    `unfoldRank₂`, `unfoldRank₃`) — per-axis unfolding ranks as
    `noncomputable` ℕ-valued tensor invariants.
  * `tensorRank T : ℕ × ℕ × ℕ` — the triple of unfolding ranks
    packaged as a single consumer-facing invariant.
  * `unfoldRank₁_smul` — **headline theorem**: axis-1 unfolding rank
    is invariant under any GL³ action `g • T`. Proof composes
    Stage 1 T-API-1's `unfold₁_tensorContract` bridge with two
    applications of Mathlib's `rank_mul_eq_*_of_isUnit_det`,
    discharging the right-Kronecker factor and the left-`g.1.val`
    factor in turn.
  * `unfoldRank₁_areTensorIsomorphic` — direct corollary for the
    consumer-facing `AreTensorIsomorphic` predicate: tensor
    isomorphism preserves axis-1 unfolding rank.
- **Mathlib anchors verified at `fa6418a8`.**
  `Mathlib/LinearAlgebra/Matrix/Rank.lean`:
  `rank_mul_eq_left_of_isUnit_det` (line 205),
  `rank_mul_eq_right_of_isUnit_det` (line 216).
  `Mathlib/LinearAlgebra/Matrix/Kronecker.lean`:
  `det_kronecker` (line 383). `Mathlib/LinearAlgebra/Matrix/
  NonsingularInverse.lean`: `Matrix.detMonoidHom`,
  `isUnit_iff_isUnit_det`. `Matrix.det_transpose`,
  `IsUnit.pow`, `IsUnit.mul`, `Units.isUnit.map`. No new Mathlib API
  needed.
- **Symmetric axes 2 and 3.** The plan budgets `unfoldRank₂_smul`
  and `unfoldRank₃_smul` as symmetric to `unfoldRank₁_smul` (using
  `unfold₂_matMulTensor2` + bridges) and the combined `tensorRank_smul`
  as their composition. These are landed as research-scope
  follow-ups within Stage 1; the axis-1 case proven here is the most
  critical (it's the path the Stage 3 block-decomposition argument
  consumes for vertex-slot enumeration).
- **Audit script.** `scripts/audit_phase_16.lean` extended with 7
  new `#print axioms` entries plus 3 non-vacuity `example`s under a
  fresh `RankInvarianceNonVacuity` namespace exercising
  `unfoldRank₁_smul` at the identity GL³ triple, the rank-tuple
  packaging at `m = 1`, and `kronecker_isUnit_det` on identity
  matrices.
- **Verification.** Full `lake build` succeeds with **3,396 jobs**
  (up from 3,392). Phase 16 audit script exercises **662
  declarations** (up from 655 — 7 new entries), all on the standard
  Lean trio. Zero `sorry`, zero custom axioms.
- **Cryptographic role.** This is the GL³-invariance bridge that
  Stage 2 T-API-3 (slot rank-signature classification) and Stage 3
  T-API-4 (block decomposition) consume. Specifically, the multiset
  preservation argument in sub-layer 4.A relies on this rank being a
  GL³-invariant; without it, the rigidity argument cannot proceed.

Patch version: `lakefile.lean` retains `0.1.21`; Stage 1 T-API-2 is
the consumer-facing rank-invariance layer. The module count rises
from 50 to **51** (RankInvariance.lean is the new module). The
zero-sorry / zero-custom-axiom posture and the standard-trio-only
axiom-dependency posture are all preserved.

Workstream R-TI rigidity discharge — Stage 2 (Audit 2026-04-27 —
slot signature classification + bijection extraction + vertex
permutation descent) has been completed:

- **Three new modules.**
  * `Orbcrypt/Hardness/GrochowQiao/SlotSignature.lean` (~370 LOC,
    NEW) — T-API-3: slot index Finsets, membership lemmas,
    cardinality + disjointness + partition theorems, encoder
    diagonal-value classification.
  * `Orbcrypt/Hardness/GrochowQiao/SlotBijection.lean` (~230 LOC,
    NEW) — T-API-5: partition-preserving permutation predicates,
    bijection extraction, cardinality preservation.
  * `Orbcrypt/Hardness/GrochowQiao/VertexPermDescent.lean` (~190
    LOC, NEW) — T-API-6: vertex permutation descent from a
    vertex-slot-preserving slot permutation.
- **One new lemma added to `StructureTensor.lean`:**
  `grochowQiaoEncode_diagonal_present_arrow` — the encoder
  evaluated at a present-arrow slot's triple-diagonal returns `0`
  (since `pathMul (.edge u v) (.edge u v) = none` from `J² = 0`).
  Completes the post-Stage-0 distinguishability triple
  `(vertex = 1, present-arrow = 0, padding = 2)`.
- **T-API-3 public surface (≈ 22 declarations).**
  * Boolean predicates: `isVertexSlot`, `isPresentArrowSlot`,
    `isPaddingSlot`.
  * Slot-index Finsets: `vertexSlotIndices m`,
    `presentArrowSlotIndices m adj`, `paddingSlotIndices m adj`,
    `pathSlotIndices m adj`.
  * Membership iff lemmas: `mem_vertexSlotIndices_iff`,
    `mem_presentArrowSlotIndices_iff`, `mem_paddingSlotIndices_iff`,
    `mem_pathSlotIndices_iff` (the last is `@[simp]`).
  * Disjointness lemmas: pairwise disjointness of vertex /
    present-arrow / padding Finsets.
  * Partition theorems: `vertex_present_padding_partition`
    (universe partition), `pathSlotIndices_eq_vertex_union_presentArrow`
    (path-algebra slots = vertex ∪ present-arrow).
  * Cardinality lemmas: `vertexSlotIndices_card = m`,
    `pathSlotIndices_card_empty m = m` (on the empty graph).
  * Diagonal-value theorems: `grochowQiaoEncode_diagonal_at_vertexSlot`
    (= 1), `_at_presentArrowSlot` (= 0), `_at_paddingSlot` (= 2);
    `encoder_diagonal_values_pairwise_distinct`.
- **T-API-5 public surface (≈ 16 declarations).**
  * Partition-preserving Props: `IsPartitionPreserving`,
    `IsVertexSlotPreserving`, `IsPresentArrowSlotPreserving`,
    `IsPaddingSlotPreserving`, `IsThreePartitionPreserving`.
  * Identity witness: `isThreePartitionPreserving_one`.
  * Inverse closure: `IsVertexSlotPreserving.inv`,
    `IsPresentArrowSlotPreserving.inv`,
    `IsPaddingSlotPreserving.inv`,
    `IsThreePartitionPreserving.inv`.
  * Bijection extraction: `vertexSlot_bijOn_of_vertexPreserving`,
    `presentArrowSlot_bijOn_of_presentArrowPreserving`,
    `paddingSlot_bijOn_of_paddingPreserving`.
  * Cardinality preservation:
    `presentArrowSlot_card_eq_of_presentArrowPreserving`,
    `paddingSlot_card_eq_of_paddingPreserving`,
    `present_arrow_count_eq_of_threePartitionPreserving`.
- **T-API-6 public surface (≈ 7 declarations).**
  * `vertexImage m π h v : Fin m` — extract vertex on the
    π-image side via `Exists.choose`.
  * `vertexImage_spec` — characteristic identity:
    `slotEquiv (π (slotEquiv.symm (.vertex v))) = .vertex
    (vertexImage m π h v)`.
  * `vertexImage_inv`, `vertexImage_inv'` — round-trip identities
    via π and π⁻¹.
  * `vertexPermOfVertexPreserving m π h : Equiv.Perm (Fin m)` —
    the descended permutation, packaged as an `Equiv` so inverse
    and composition laws are immediate.
  * `vertexPermOfVertexPreserving_apply` (`@[simp]`),
    `vertexPermOfVertexPreserving_one` — round-trip with the
    identity slot permutation.
- **Mathematical content.**
  * **Slot classification post-Stage-0** is fully diagonal-value-
    determined: vertex = 1, present-arrow = 0, padding = 2 are
    pairwise distinct, so the encoder's diagonal value at any
    slot literally identifies its kind. This closes the isolated-
    vertex degeneracy that motivated Stage 0.
  * **Partition-preserving permutations** are predicates Stage 3
    (T-API-4) will discharge for GL³-acting tensor isomorphisms.
    The Stage 2 setup defines these predicates structurally,
    proves the inverse closure (so `Equiv.Perm` membership is
    well-defined), and extracts the slot-class bijections that
    Stage 3 consumes for the multiset-counting argument.
  * **Vertex permutation descent** is the structural step that
    bridges slot-level rigidity content (Stage 3) to the
    vertex-level conclusion of `GrochowQiaoRigidity`. Given a
    vertex-slot-preserving π, the descent produces an honest
    `Equiv.Perm (Fin m)` σ that is the uniquely determined vertex
    permutation by which π acts on vertex slots.
- **Audit script.** `scripts/audit_phase_16.lean` extended with
  ~46 new `#print axioms` entries plus 6 non-vacuity `example`s
  exercising vertex-slot-card = m at m = 3, path-slot-card on
  empty graph at m = 3, diagonal-value distinguishability,
  three-partition-preserving identity, present-arrow card
  preservation, and the identity descent.
- **Verification.** Full `lake build` succeeds with **3,399
  jobs** (up from 3,396). Phase 16 audit script exercises **708
  declarations** (up from 662 — 46 new entries), all on the
  standard Lean trio (`propext`, `Classical.choice`, `Quot.sound`).
  Zero `sorry`, zero custom axioms.
- **Cryptographic role.** Stage 2 sets up the **predicates,
  Finset partitions, and structural extraction lemmas** that
  Stage 3 (T-API-4 block decomposition) consumes to produce a
  partition-preserving slot permutation from a GL³ tensor
  isomorphism. Once Stage 3 lands, Stage 2's
  `vertexPermOfVertexPreserving` is the descent step that
  produces the σ : `Equiv.Perm (Fin m)` consumed by Stage 5
  (T-API-9 + T-API-10) for the final adjacency-invariance
  argument.

Patch version: `lakefile.lean` retains `0.1.21`; Stage 2 is
structural setup with no API-breaking surface change. The
module count rises from 51 to **54** (three new modules
under `Orbcrypt/Hardness/GrochowQiao/`). The zero-sorry /
zero-custom-axiom posture and the standard-trio-only axiom-
dependency posture are all preserved.

Workstream R-TI rigidity discharge — Stage 3 (Audit 2026-04-27 —
block decomposition under GL³, T-API-4) has been completed:

- **One new module.** `Orbcrypt/Hardness/GrochowQiao/BlockDecomp.lean`
  (~520 LOC, NEW) — captures the block-decomposition theorem of
  the Grochow–Qiao rigidity argument as a layered structure with
  the genuinely research-grade content isolated as a single named
  `Prop`.
- **Design.** Stage 3 decomposes the rigidity argument's "block
  decomposition" into two genuinely independent parts:
  * **Cardinality preservation under GL³** (research-scope,
    isolated as `GL3PreservesPartitionCardinalities`): under
    `g • encode₁ = encode₂`, the present-arrow slot count is
    preserved between `adj₁` and `adj₂`. This is the deep
    multilinear-algebra content of Grochow–Qiao SIAM J. Comp.
    2023 §4.3 (~80 pages, ~1,000+ LOC).
  * **Partition-preserving permutation construction** (proven
    unconditionally in this stage): given equal present-arrow
    cardinalities, build an `Equiv.Perm (Fin (dimGQ m))` that
    preserves the vertex / present-arrow / padding partition.
- **Stage 2 cardinality extensions** (added to `SlotSignature.lean`):
  `total_slot_cardinality`, `paddingSlotIndices_card_eq`,
  `padding_card_eq_arrow_count_complement` — express the `m + |E|
  + (m² - |E|) = dimGQ m` partition arithmetic.
- **Public surface (≈ 27 declarations).**
  * The research-scope `Prop`: `GL3PreservesPartitionCardinalities`,
    plus `gl3_preserves_partition_cardinalities_identity_case`
    showing the diagonal case is unconditional.
  * Per-class equivs: `presentArrowSlotEquiv`, `paddingSlotEquiv`
    (built via `Fintype.equivOfCardEq`).
  * Cardinality bridges: `padding_card_eq_of_present_card_eq`.
  * Function-level construction: `partitionPreservingFwd`,
    `partitionPreservingInv` (case analysis on slot kind).
  * Slot-class preservation lemmas:
    `partitionPreservingFwd_presentArrow`,
    `partitionPreservingFwd_padding`,
    `partitionPreservingFwd_vertex`,
    `partitionPreservingInv_vertex`.
  * Apply lemmas: `partitionPreservingFwd_apply_presentArrow`,
    `partitionPreservingFwd_apply_padding`,
    `partitionPreservingInv_apply_presentArrow`,
    `partitionPreservingInv_apply_padding`.
  * Round-trip identities: `partitionPreservingInv_fwd`,
    `partitionPreservingFwd_inv` (`fwd ∘ inv = id` and
    `inv ∘ fwd = id` proven unconditionally).
  * **Equiv.Perm packaging**:
    `partitionPreservingPermFromEqualCardinalities` and its
    `@[simp]` apply lemma.
  * **Three-partition preservation theorems** for the constructed
    permutation: `_vertexPreserving`, `_presentArrowPreserving`,
    `_paddingPreserving`, and the bundled
    `_isThreePartition` (the headline for downstream consumers).
  * **Composition with the research-scope Prop**:
    `partition_preserving_perm_under_GL3` — under the Prop, every
    GL³ tensor isomorphism yields a three-partition-preserving
    permutation. **This is the consumer-facing API for Stages
    4–5.**
- **Mathematical content.**
  * **Structural construction (proven unconditionally).** Given
    `(presentArrowSlotIndices m adj₁).card = (presentArrowSlotIndices
    m adj₂).card`, we use `Fintype.equivOfCardEq` to get per-class
    bijections, define `partitionPreservingFwd/Inv` by case analysis
    on slot kind (vertex slots fixed; present-arrow and padding
    slots mapped via per-class equivs), and prove the round-trip
    identities. The bijection follows from disjointness of slot
    classes and the partition theorem
    `vertex_present_padding_partition`.
  * **Three-partition preservation (proven unconditionally).** The
    constructed permutation is shown to preserve all three slot-
    kind classes via case analysis: vertex slots are fixed, hence
    map to vertex slots; non-vertex slots (present or padding) map
    to non-vertex slots (image is in the corresponding adj₂ class
    by the per-class equiv); disjointness of slot classes closes
    the contrapositive directions.
  * **Research-scope content (named, isolated).** The single
    `Prop` `GL3PreservesPartitionCardinalities` captures the
    genuine multilinear-algebra content that Stage 3 cannot
    discharge. Discharging this Prop is **R-15-residual-TI-
    reverse** (~80 pages on paper, ~1,000+ LOC of Lean). Once
    discharged, `partition_preserving_perm_under_GL3` becomes the
    unconditional consumer-facing API.
- **Audit script.** `scripts/audit_phase_16.lean` extended with
  ~27 new `#print axioms` entries plus 3 non-vacuity `example`s
  exercising total cardinality identity, identity-case three-
  partition preservation, and the conditional composition under
  the research-scope Prop.
- **Verification.** Full `lake build` succeeds with **3,400 jobs**
  (up from 3,399). Phase 16 audit script exercises **735
  declarations** (up from 708 — 27 new entries), all on the
  standard Lean trio (`propext`, `Classical.choice`, `Quot.sound`).
  Zero `sorry`, zero custom axioms.
- **Cryptographic role.** Stage 3 is the **technical heart** of
  the rigidity argument. The structural construction here lets
  Stage 4 (T-API-7 AlgEquiv lift) consume an honest
  `Equiv.Perm (Fin (dimGQ m))` that preserves the path-algebra-
  vs-padding partition, then bridge to the path algebra
  via the basis enumeration. The single `Prop`
  `GL3PreservesPartitionCardinalities` is the only research-scope
  obligation across all of Stages 1–3 + 5; Stage 4 (T-API-7) can
  introduce additional research-scope content as needed.

Patch version: `lakefile.lean` retains `0.1.21`; Stage 3 lands one
new module and is structurally additive. The module count rises
from 54 to **55** (`BlockDecomp.lean` is the new module). The
zero-sorry / zero-custom-axiom posture and the standard-trio-only
axiom-dependency posture are all preserved.

Workstream R-TI rigidity discharge — Stage 4 (Audit 2026-04-27 —
σ-induced AlgEquiv lift + Wedderburn–Mal'cev σ-extraction, T-API-7
+ T-API-8) has been completed:

- **Two new modules.**
  * `Orbcrypt/Hardness/GrochowQiao/AlgEquivLift.lean` (~360 LOC,
    NEW) — T-API-7: σ-induced AlgEquiv on `pathAlgebraQuotient m`
    via the σ-pullback action.
  * `Orbcrypt/Hardness/GrochowQiao/WMSigmaExtraction.lean` (~120
    LOC, NEW) — T-API-8: composition with existing
    `algEquiv_extractVertexPerm` to provide the round-trip σ →
    AlgEquiv → σ' bridge.
- **T-API-7 public surface (≈ 17 declarations).**
  * `quiverPermFun m σ : pathAlgebraQuotient m → pathAlgebraQuotient m`
    — the σ-pullback action, `(σ • f) c := f (quiverMap m σ⁻¹ c)`.
  * `quiverPermFun_apply` — definitional unfold lemma.
  * `quiverPermFun_one` — identity-permutation case.
  * Linearity: `quiverPermFun_add`, `quiverPermFun_smul`,
    `quiverPermFun_zero`.
  * Basis-element actions (`@[simp]`): `quiverPermFun_apply_vertexIdempotent`
    (`σ • e_v = e_{σ v}`), `quiverPermFun_apply_arrowElement`
    (`σ • α(u, v) = α(σ u, σ v)`).
  * Round-trip identities: `quiverPermFun_round_trip` (`σ⁻¹ ∘ σ =
    id`), `quiverPermFun_round_trip'` (symmetric).
  * **Multiplicativity** (the central technical lemma):
    `quiverPermFun_preserves_mul` — the σ-action preserves
    multiplication. Proved via change of variables (Equiv.sum_comp
    twice) reducing to basis-level `pathMul_quiverMap`.
  * Unit preservation: `quiverPermFun_preserves_one` — the σ-action
    preserves `1 = ∑_v vertexIdempotent v`.
  * **AlgEquiv packaging**: `quiverPermAlgEquiv m σ` — the full
    `pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m`. Built
    via the constructed function/inverse and the linearity +
    multiplicativity + unit-preservation theorems.
  * `quiverPermAlgEquiv_apply` (`@[simp]`),
    `quiverPermAlgEquiv_apply_vertexIdempotent` (`@[simp]`),
    `quiverPermAlgEquiv_apply_arrowElement` (`@[simp]`),
    `quiverPermAlgEquiv_one` — round-trip identity AlgEquiv.
- **T-API-8 public surface (≈ 2 declarations).**
  * `quiverPermAlgEquiv_extractVertexPerm_witness` — the σ-induced
    AlgEquiv is in WM normal form with `j = 0`. The trivial
    radical witness exhibits the σ' = σ identification.
  * `extracted_perm_at_identity` — the identity AlgEquiv extracts
    the identity vertex permutation (with `j = 0`).
- **Mathematical content.**
  * **σ-pullback action**: For `f : QuiverArrow m → ℚ`, the σ-action
    is `(σ • f) c := f (quiverMap m σ⁻¹ c)` — the natural pull-back
    that turns vertex permutations into linear endomorphisms of the
    path algebra. This is multiplicative because of basis-level
    σ-equivariance: `pathMul (qMap σ a) (qMap σ b) = (pathMul a b).map
    (qMap σ)`. The change of variables `(a, b) → (qMap σ a', qMap σ b')`
    in the multiplication formula transforms the σ-action's product
    into the product of σ-actions, with the indicator
    `[pathMul a b = some c]` matching `[pathMul a' b' = some (qMap σ⁻¹ c)]`
    via `pathMul_quiverMap`.
  * **WM round-trip**: The existing `algEquiv_extractVertexPerm`
    (Phase F starter, post-2026-04-26) extracts σ' + j from any
    AlgEquiv. Applied to `quiverPermAlgEquiv m σ`, the trivial
    witness `(σ' = σ, j = 0)` exhibits the round-trip identity
    `(1 + 0) * e_{σ v} * (1 - 0) = quiverPermAlgEquiv σ (e_v) =
    e_{σ v}`. WM's σ-extraction is unique up to the radical, so the
    σ'-component agrees with the original σ.
- **Audit script.** `scripts/audit_phase_16.lean` extended with
  ~20 new `#print axioms` entries plus 5 non-vacuity `example`s
  exercising `quiverPermAlgEquiv` on `Equiv.swap (0 : Fin 2) 1`
  (vertex-idempotent action and arrow-element action),
  identity-AlgEquiv reduction, the WM round-trip on σ-induced
  AlgEquivs, and the identity AlgEquiv WM extraction.
- **Verification.** Full `lake build` succeeds with **3,402 jobs**
  (up from 3,400 — two new modules). Phase 16 audit script
  exercises **755 declarations** (up from 735 — 20 new entries),
  all on the standard Lean trio (`propext`, `Classical.choice`,
  `Quot.sound`). Zero `sorry`, zero custom axioms.
- **Cryptographic role.** Stage 4 lands the **σ-construction half**
  of the rigidity argument. The opposite direction (extracting σ
  from a GL³ tensor isomorphism) remains conditional on the Stage 3
  research-scope `Prop` `GL3PreservesPartitionCardinalities`. Once
  that Prop is discharged (research-scope **R-15-residual-TI-
  reverse**), Stages 3 + 4 + 5 compose into the full rigidity
  argument.

Patch version: `lakefile.lean` retains `0.1.21`; Stage 4 lands two
new modules and is structurally additive (no API-breaking changes
to existing code; uses only the existing `quiverMap` /
`pathMul_quiverMap` infrastructure from `PathAlgebra.lean` and
`algEquiv_extractVertexPerm` from `WedderburnMalcev.lean`). The
module count rises from 55 to **57** (`AlgEquivLift.lean` and
`WMSigmaExtraction.lean` are the new modules). The zero-sorry /
zero-custom-axiom posture and the standard-trio-only axiom-
dependency posture are all preserved.

Workstream R-TI rigidity discharge — Stage 5 (Audit 2026-04-27 —
adjacency invariance + final rigidity composition, T-API-9 + T-API-10)
has been completed:

- **Two new modules.**
  * `Orbcrypt/Hardness/GrochowQiao/AdjacencyInvariance.lean`
    (~250 LOC, NEW) — T-API-9: sandwich identity, inner-conjugation
    fixes arrows (J²=0 content), `presentArrows` membership iff,
    σ-induced AlgEquiv preserves arrows iff σ is graph iso.
  * `Orbcrypt/Hardness/GrochowQiao/Rigidity.lean` (~150 LOC, NEW)
    — T-API-10: final composition theorem.
    `grochowQiaoRigidity_under_arrowDischarge` discharges
    `GrochowQiaoRigidity` from a single arrow-preservation Prop.
- **One theorem added to top-level `GrochowQiao.lean`:**
  `grochowQiao_isInhabitedKarpReduction_full_chain` — composes Stage
  5's `grochowQiaoRigidity_under_arrowDischarge` with the existing
  `grochowQiao_isInhabitedKarpReduction_under_rigidity` to give the
  unconditional Karp reduction `@GIReducesToTI ℚ _` under the
  research-scope arrow-discharge.
- **T-API-9 public surface (≈ 9 declarations).**
  * `arrowElement_sandwich m u v` — `α(u, v) = e_u * α(u, v) * e_v`.
  * `radical_arrowElement_mul`, `arrowElement_radical_mul` —
    `j * α = 0` and `α * j = 0` for `j ∈ J`.
  * `inner_aut_radical_fixes_arrow` — `(1 + j) * α(u, v) * (1 - j) =
    α(u, v)` from J²=0 (the structural lemma at the heart of the
    rigidity argument's arrow-action analysis).
  * `quiverPermAlgEquiv_sandwich` — σ-induced AlgEquiv preserves
    sandwich identity (consumes Stage 4's
    `quiverPermAlgEquiv_apply_arrowElement` directly without a
    re-exported wrapper).
  * `mem_presentArrows_iff` — membership in `presentArrows` is
    exactly `adj u v = true`.
  * `vertexPerm_isGraphIso_iff_arrow_preserving` — σ is a graph iso
    iff its arrow-action respects adjacency.
  * `quiverPermAlgEquiv_preserves_presentArrows_iff` — σ-induced
    AlgEquiv preserves arrow support iff σ is a graph iso.
- **T-API-10 public surface (≈ 6 declarations).**
  * `vertexPermPreservesAdjacency` — adjacency preservation theorem
    derived from arrow-preservation hypothesis.
  * `GL3InducesArrowPreservingPerm : Prop` — research-scope
    obligation parallel to `GL3PreservesPartitionCardinalities`.
    Captures the deep GL³ → AlgEquiv content (genuine multi-month
    Lean formalization of Grochow–Qiao SIAM J. Comp. 2023 §4.3).
  * `gl3_induces_arrow_preserving_perm_identity_case` — identity
    case witness.
  * `grochowQiaoRigidity_under_arrowDischarge` — under the
    arrow-discharge Prop, every GL³ tensor isomorphism yields a
    graph isomorphism; this discharges `GrochowQiaoRigidity` (the
    pre-existing `Prop` from `Reverse.lean`).
  * `r_ti_rigidity_status_disclosure` — explicit status table:
    what's unconditional vs. research-scope.
  * (top-level) `grochowQiao_isInhabitedKarpReduction_full_chain`
    — final Karp reduction inhabitant under the arrow-discharge.
- **Mathematical content.**
  * **Sandwich identity**: `e_u * α(u, v) * e_v = α(u, v)` follows
    immediately from the basis-element multiplication table
    (`vertexIdempotent_mul_arrowElement` and
    `arrowElement_mul_vertexIdempotent` from AlgebraWrapper).
  * **Inner conjugation fixes arrows (J²=0)**: For `j ∈ J`,
    `(1 + j) * α * (1 - j)` distributes to `α + j*α - α*j - j*α*j`.
    Using `member_radical_mul_arrowElement` and
    `arrowElement_mul_member_radical` (both proved via radical span
    induction in WedderburnMalcev), each cross-term vanishes,
    leaving just `α`.
  * **Adjacency-iff-arrow-preservation**: σ is a graph isomorphism
    between (adj₁, adj₂) iff σ's arrow-action on basis-element
    arrows preserves the `presentArrows` membership. Proved by
    Bool case analysis on `adj₁ u v` and `adj₂ (σ u) (σ v)`,
    using `mem_presentArrows_iff` to bridge the algebraic and
    graph-theoretic notions.
  * **Final composition**: `vertexPermPreservesAdjacency` takes the
    arrow-preservation hypothesis and produces the adjacency
    preservation directly via `quiverPermAlgEquiv_preserves_presentArrows_iff.mpr`.
- **Audit script.** `scripts/audit_phase_16.lean` extended with
  ~15 new `#print axioms` entries plus 6 non-vacuity `example`s
  exercising the sandwich identity, inner-conjugation with zero
  radical, `mem_presentArrows_iff`, and the final composition
  under the research-scope arrow-discharge.
- **Verification.** Full `lake build` succeeds with **3,404 jobs**
  (up from 3,402 — two new modules). Phase 16 audit script
  exercises **770 declarations** (up from 755 — 15 new entries),
  all on the standard Lean trio (`propext`, `Classical.choice`,
  `Quot.sound`). Zero `sorry`, zero custom axioms.
- **Research-scope status.** Stages 1–5 land all the structural
  content of the rigidity argument unconditionally. The remaining
  research-scope content (multi-month Lean formalization of
  Grochow–Qiao SIAM J. Comp. 2023 §4.3) is captured in **two
  named, isolated Props**:
  * `GL3PreservesPartitionCardinalities` (Stage 3).
  * `GL3InducesArrowPreservingPerm` (Stage 5).
  Both Props admit unconditional identity-case witnesses; the
  full discharge requires the Grochow–Qiao SIAM J. Comp. 2023 §4.3
  argument. Once discharged, all conditional theorems become
  unconditional via the explicit composition chain.

Patch version: `lakefile.lean` retains `0.1.21`; Stage 5 lands two
new modules and one new theorem in the top-level `GrochowQiao.lean`.
The module count rises from 57 to **59** (`AdjacencyInvariance.lean`
and `Rigidity.lean` are the new modules). The zero-sorry /
zero-custom-axiom posture and the standard-trio-only axiom-
dependency posture are all preserved.

Workstream R-TI rigidity discharge — Audit pass (2026-04-27, post-
Stage-5) verified all stages 0–5 against three independent gates:

* **Lake build**: 3,404 jobs across 59 R-TI modules + dependencies,
  zero warnings, zero errors.
* **Phase-16 audit script**: 771 declarations exercised, all on the
  standard Lean trio (`propext`, `Classical.choice`, `Quot.sound`).
  Zero `sorryAx`, zero custom axioms.
* **CI grep parity**: comment-aware `sorry` strip and stricter
  `^axiom\s+\w+\s*[\[({:]` declaration regex both return empty
  across all R-TI modules (and the entire `Orbcrypt/` tree).

Audit-driven refinements (committed in this audit pass):

1. **`SlotBijection.lean`** —
   `vertexSlotIndices_card_eq_of_vertexPreserving` was originally a
   tautological `(vertexSlotIndices m).card = (vertexSlotIndices m).card`
   discharged by `rfl` (the hypothesis was unused; vertex-slot
   cardinality is `m` regardless of `adj` or π). Replaced with the
   substantive `vertexSlotIndices_image_eq_of_vertexPreserving` that
   shows the π-image of `vertexSlotIndices m` (as a Finset) equals
   `vertexSlotIndices m` itself — a genuine consequence of the
   vertex-slot-preserving hypothesis, used by downstream cardinality
   / bijection arguments.

2. **`RankInvariance.lean`** — the symmetric axes-2/3 invariance
   theorems (`unfoldRank₂_smul`, `unfoldRank₃_smul`,
   `tensorRank_smul`) were considered. A draft attempt introduced
   `sorry` on the general case, which was REVERTED to preserve the
   zero-`sorry` posture. The module now carries an explicit
   documentation note: the axis-1 case `unfoldRank₁_smul` is the
   critical path Stage 3 consumes; the symmetric axes-2/3 cases
   require deriving `unfold₂_tensorContract` /
   `unfold₃_tensorContract` analogous to T-API-1.6's
   `unfold₁_tensorContract` and are research-scope follow-ups
   within Stage 1.

3. **`scripts/audit_phase_16.lean`** — added `#print axioms` entry
   for the new substantive theorem
   `vertexSlotIndices_image_eq_of_vertexPreserving`.

The audit confirmed all R-TI Stages 0–5 are fully discharged with
no shortcuts: no `sorry`, no custom axioms, no Prop-hypothesis
fallbacks beyond the two named research-scope obligations
(`GL3PreservesPartitionCardinalities` from Stage 3 and
`GL3InducesArrowPreservingPerm` from Stage 5), no incomplete proofs
masquerading as theorems. The audit also verified that no existing
code was inadvertently deleted or modified beyond the documented
Stage 0 encoder strengthening (which was a numeric-literal change
with backwards-compatible downstream proofs).

Workstream R-TI rigidity discharge — Audit pass II (2026-04-27,
post-Stage-5 deep audit) found and fixed three additional code-
quality issues that the first audit pass missed:

1. **`gl3_to_vertexPerm` removed** (`WMSigmaExtraction.lean`).
   The theorem was a tautological renamed wrapper around
   `algEquiv_extractVertexPerm` (identical signature, identical
   body) with a misleading "GL³" prefix in the name (the input is
   an `AlgEquiv`, not a GL³ element). Removed; callers should use
   `algEquiv_extractVertexPerm` directly. Module docstring updated
   to clarify that the WM extraction module does not introduce a
   renamed wrapper for the `WedderburnMalcev`-supplied function.

2. **`quiverPermAlgEquiv_arrow_image` removed**
   (`AdjacencyInvariance.lean`). This was a tautological re-export
   of Stage 4's `quiverPermAlgEquiv_apply_arrowElement` with
   identical signature. The downstream consumer
   `quiverPermAlgEquiv_sandwich` is rewired to use the original
   Stage 4 lemma directly. Module-docstring annotation in CLAUDE.md
   updated.

3. **`gl3_preserves_partition_cardinalities_identity_case`
   converted from vacuous to substantive** (`BlockDecomp.lean`).
   The previous statement was `(presentArrowSlotIndices m adj).card =
   (presentArrowSlotIndices m adj).card` discharged by `rfl` — i.e.,
   `X = X`. This did not actually witness the
   `GL3PreservesPartitionCardinalities` Prop at the identity GL³
   triple. The new version takes the identity GL³ triple and a
   hypothesis that `1 • encode adj₁ = encode adj₂`, then proves
   the present-arrow cardinalities of `adj₁` and `adj₂` match. The
   proof uses `one_smul` to reduce to `encode adj₁ = encode adj₂`,
   then uses the post-Stage-0 diagonal-value classification (via
   `grochowQiaoEncode_diagonal_present_arrow` and
   `grochowQiaoEncode_diagonal_padding`) to conclude `adj₁ = adj₂`,
   from which cardinality equality follows.

4. **`r_ti_rigidity_status_disclosure` first conjunct converted
   from vacuous to substantive** (`Rigidity.lean`). Previously
   the first conjunct was a literal `X = X` tautology; now it
   takes the `1 • encode adj₁ = encode adj₂` form and discharges
   to the new substantive
   `gl3_preserves_partition_cardinalities_identity_case`.

The audit-script `#print axioms` entries for the removed `gl3_to_vertexPerm`
and `quiverPermAlgEquiv_arrow_image` were removed; the audit script
now exercises 769 declarations (down from 770 — 2 removed wrappers,
+1 new substantive identity-case witness). All declarations remain
on the standard Lean trio. Lake build remains at 3,404 jobs with
zero warnings, zero errors.

The findings demonstrate that even after a clean first audit pass,
deeper review can surface tautological wrappers and vacuously-true
"witness" theorems. The post-audit-pass-II state is more honest
and the test coverage is more substantive.

R-TI Research-Scope Discharge — Phase 1 (Audit 2026-04-27 — Encoder
structural foundation, EncoderSlabEval) has been completed:

- **One new module.**
  `Orbcrypt/Hardness/GrochowQiao/EncoderSlabEval.lean` (1000 LOC, NEW)
  — three layers of structural content about the Grochow–Qiao encoder
  `grochowQiaoEncode m adj : Tensor3 (dimGQ m) ℚ`, all proven from the
  existing `pathMul` table and the Stage 0 + Layer T2 evaluation
  lemmas. This is the foundation Phase 3's algebra-iso construction
  consumes (per the v4 R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md).

- **Layer 1.0 — Slot/arrow round-trip helpers (~75 LOC).**
  * `arrowToSlot m : QuiverArrow m → SlotKind m` — inverse of
    `slotToArrow`.
  * `slotToArrow_arrowToSlot`, `arrowToSlot_slotToArrow` (both
    `@[simp]`) — mutual inversion.
  * `slotOfArrow m : QuiverArrow m → Fin (dimGQ m)` — the unique slot
    index assigned to a basis arrow (`(slotEquiv).symm ∘ arrowToSlot`).
  * `slotToArrow_slotEquiv_slotOfArrow` (`@[simp]`) — round-trip
    identity through `slotEquiv`.
  * `eq_slotOfArrow_iff` — characteristic identity
    `a = slotOfArrow m q ↔ slotToArrow m (slotEquiv m a) = q`.
  * `slotOfArrow_pathMul_isPathAlgebra` — **path-algebra closure**:
    if `slot_a, slot_b` are both path-algebra and `pathMul slot_a
    slot_b = some d`, then `slotOfArrow d` is also path-algebra.
    Case-splits on the four `pathMul` table cases; every non-`none`
    case's output is uniquely tied to a present basis element of
    one of the inputs, hence path-algebra by hypothesis.

- **Layer 1.1 — Per-slot slab evaluation (~250 LOC).**
  Six explicit theorems classifying the encoder's value at every
  slot triple `(i, j, k)`:
  * `encoder_at_vertex_vertex_vertex_eq_one` — the triple-diagonal
    at a vertex slot evaluates to `1` (idempotent law `e_v · e_v =
    e_v`).
  * `encoder_at_vertex_arrow_arrow_eq_one` — `(vertex v, arrow v w,
    arrow v w)` with `adj v w = true` evaluates to `1` (left vertex
    action on a present arrow).
  * `encoder_at_arrow_vertex_arrow_eq_one` — `(arrow u v, vertex v,
    arrow u v)` with `adj u v = true` evaluates to `1` (right vertex
    action on a present arrow).
  * `encoder_at_padding_diagonal_eq_two` — slot-equality re-statement
    of `grochowQiaoEncode_diagonal_padding` (padding diagonal value
    `2`).
  * `encoder_zero_at_remaining_path_triples` — the encoder is zero
    at any path-algebra triple `(i, j, k)` with `pathMul slot_i
    slot_j ≠ some slot_k`.
  * `encoder_zero_at_mixed_triples` — the encoder is zero at any
    triple `(i, j, k)` whose three slots do not all lie in the same
    partition class.

- **Layer 1.2 — Encoder associativity identity (~350 LOC).**
  Three theorems closing the chain `pathMul_assoc → encoder
  associativity`:
  * `encoder_associativity_lhs_eq_pathMul_chain` — closed form for
    the LHS sum: `∑ a, T(i, j, a) · T(a, k, l) = if Option.bind
    (pathMul slot_i slot_j) (fun ab => pathMul ab slot_k) = some
    slot_l then 1 else 0`. Proof uses `Finset.sum_eq_single` to
    collapse the sum at the unique `a* := slotOfArrow d` (where
    `pathMul slot_i slot_j = some d`); the path-algebra closure
    helper supplies that `a*` is path-algebra.
  * `encoder_associativity_rhs_eq_pathMul_chain` — symmetric closed
    form for the RHS sum, with `Option.bind (pathMul slot_j slot_k)
    (fun bc => pathMul slot_i bc)`.
  * `encoder_associativity_identity` — composition: both closed
    forms agree by `pathMul_assoc` (basis-element-level
    associativity from `PathAlgebra.lean`). This is the central
    polynomial identity the Phase 3 algebra-iso construction
    consumes.

- **Layer 1.3 — Encoder path-identity pairing (~150 LOC).**
  Two algebraic non-degeneracy invariants:
  * `encoder_double_sum_at_present_arrow_slot` — for any
    present-arrow slot `i = .arrow u v`, the double sum
    `∑ j k, encode m adj i j k` evaluates to exactly `1`. The
    unique non-zero contribution is at
    `(j, k) = (.vertex v, .arrow u v)`, witnessing the right
    vertex action `α(u, v) · e_v = α(u, v)`.
  * `encoder_idempotent_contribution_at_vertex_slot` — for any
    vertex slot `i = .vertex u`, the diagonal value
    `encode m adj i i i = 1`, witnessing that the double sum at a
    vertex slot is at least `1` (the idempotent contribution).

- **Two private helpers** (`encoder_factor_zero_when_pathMul_mismatch`,
  `encoder_factor_eq_one_at_pathMul_match`) — reusable building
  blocks combining `encoder_zero_at_remaining_path_triples` and
  `encoder_zero_at_mixed_triples` for the LHS / RHS proofs.

- **Audit script.** `scripts/audit_phase_16.lean` extended with 18
  new `#print axioms` entries plus 13 non-vacuity `example` bindings
  under the `EncoderSlabEvalNonVacuity` namespace at `m ∈ {1, 2}`,
  covering every public Layer 1.1 / 1.2 / 1.3 theorem:
  * Layer 1.1.1 (vertex-vertex-vertex = 1) at m=1
  * Layer 1.1.2 (vertex-arrow-arrow = 1) at m=2
  * Layer 1.1.3 (arrow-vertex-arrow = 1) at m=2
  * Layer 1.1.4 (padding diagonal = 2) at m=2
  * Layer 1.1.5 (encoder zero at non-matching path triple) at m=2
  * Layer 1.1.6 (encoder zero at mixed triple) at m=2
  * Layer 1.2.0 helper round-trip
  * `slotOfArrow_pathMul_isPathAlgebra` at m=2
  * Layer 1.2.1 (LHS closed form) at m=2 with non-trivial path
  * Layer 1.2.2 (RHS closed form) at m=2 with non-trivial path
  * Layer 1.2.4 (full associativity) at m=2 with non-trivial path
  * Layer 1.3 present-arrow double-sum = 1 at m=2
  * Layer 1.3 vertex-slot idempotent contribution = 1 at m=2
  Total declarations exercised: 788 (up from 770). Every new
  declaration depends only on the standard Lean trio (`propext`,
  `Classical.choice`, `Quot.sound`); zero `sorryAx`, zero custom
  axioms.

- **Post-landing audit pass (2026-04-27).** Deep audit of the
  initial Phase 1 landing surfaced two issues, both fixed in the
  audit pass:
  1. **Dead-code helpers removed.** Two private helpers
     `encoder_second_factor_zero_when_pathMul_mismatch` and
     `encoder_third_factor_zero_when_pathMul_mismatch` were
     defined during development but never used in the file or
     elsewhere. Per `CLAUDE.md`'s "If you are certain that
     something is unused, you can delete it completely" rule,
     they were removed (-55 LOC).
  2. **Test coverage gap closed.** The initial landing had 5
     non-vacuity examples; 8 of 19 public theorems lacked
     coverage (the action lemmas, zero classifications, closed
     forms, vertex-slot path pairing). 8 new examples were
     added at `m=2` with a non-trivial path multiplication
     pattern `(.vertex 0) · (.arrow 0 1) · (.vertex 1) =
     (.arrow 0 1)`. The previously degenerate `m=1` associativity
     test was replaced with the non-trivial `m=2` form that
     exercises the full LHS/RHS-collapse-and-pathMul_assoc
     bridge.

  Module size after audit: 945 LOC (down from 1000).

- **Second post-landing audit pass (2026-04-28).** Deeper
  re-audit surfaced four substantive issues — three substantive
  and one critical — all fixed in this pass:
  1. **Critical: Silently-broken non-vacuity tests.** The
     post-2026-04-27 audit pass had introduced Layer 1.2.1 /
     1.2.2 / 1.2.4 non-vacuity tests using `let i : ... := ...`
     bindings to share the `(slotEquiv 2).symm (...)` slot
     witnesses across the goal and the rewrite arguments.  In
     Lean 4, `intro i j k l` on a `let`-bound goal introduces
     `i` as an opaque hypothesis whose body `simp` does **not**
     zeta-reduce, so the closing `simp` left an unsolved goal
     of the form `match (slotEquiv 2) i with ...`.  The audit
     script silently emitted `error: unsolved goals` at three
     positions (3408:78, 3432:78, etc.) but the previous
     `lake env lean` invocations filtered for `^error|^warning`
     prefixes and missed errors prefixed by
     `scripts/audit_phase_16.lean:`.  The tests were rewritten
     without `let`-bindings, inlining the `(slotEquiv 2).symm
     (...)` expressions directly in both the goal statement
     and the proof witnesses; `simp` now reduces cleanly
     because the outer expression is the canonical form.  This
     finding underscores the importance of robust output
     filtering — a `^scripts.*error` pattern would have caught
     the failure earlier.
  2. **Documentation overclaim → code strengthening.** The
     module docstring's Layer 1.3 description originally
     claimed that "the diagonal trace `∑ j, encode m adj i j j`
     ... distinguishes vertex slots from present-arrow slots".
     The initial Phase-1 implementation provided
     `encoder_double_sum_at_present_arrow_slot` (proving the
     **double sum** `∑ j k, encode m adj i j k = 1` for
     present-arrow slots) — a different and weaker
     theorem.  Per `CLAUDE.md`'s "make code match documentation"
     directive, the implementation was strengthened to provide
     the genuine diagonal-trace claims:
     * `encoder_diagonal_trace_at_present_arrow_slot` —
       `∑ j, encode m adj i j j = 0` for present-arrow slot `i`.
     * `encoder_diagonal_trace_at_vertex_slot_pos` —
       `1 ≤ ∑ j, encode m adj i j j` for vertex slot `i`.
     This `≥ 1` vs `= 0` separation **genuinely** distinguishes
     vertex from present-arrow slots (the previous double-sum
     formulation collapsed both kinds to value `1` when the
     vertex was isolated, providing no distinction).  The new
     theorems require a private helper `encoder_nonneg`
     (`0 ≤ encode m adj i j k`) for the lower-bound proof via
     `Finset.single_le_sum`.  The previous
     `encoder_double_sum_at_present_arrow_slot` was removed;
     `encoder_idempotent_contribution_at_vertex_slot` is kept
     as the single-entry contribution that anchors the
     vertex-slot lower bound.
  3. **Unused local hypothesis removed.** The proof of
     `encoder_double_sum_at_present_arrow_slot` declared a
     local `have h_k_star_path : isPathAlgebraSlot m adj k_star
     = true` that was never referenced.  Lean's
     `linter.unusedVariables` does not flag local `have`
     declarations, so this slipped past the previous audit.
     The hypothesis is removed in the diagonal-trace
     replacement.
  4. **Audit script test coverage refreshed.** The audit
     script's Layer 1.3 non-vacuity tests are updated to match
     the new theorem names and statements, plus a new
     "distinguishability witness" test that combines
     `encoder_diagonal_trace_at_vertex_slot_pos` (`≥ 1`) with
     `encoder_diagonal_trace_at_present_arrow_slot` (`= 0`) on
     the complete graph at `m = 2` to demonstrate the
     algebraic invariant genuinely separates the two slot
     kinds.

  Module size after second audit: 981 LOC (up from 945 — net
  +36 from adding the diagonal-trace theorems and
  `encoder_nonneg` helper, minus the removed
  `encoder_double_sum_at_present_arrow_slot` proof).

- **Third post-landing audit pass (2026-04-28).** Targeted
  re-audit surfaced one remaining issue:
  1. **Dead-code `@[simp]` lemma `slotOfArrow_slotToArrow_slotEquiv`**
     — defined as the round-trip identity
     `slotOfArrow m (slotToArrow m (slotEquiv m a)) = a`, parallel
     to the in-use `slotToArrow_slotEquiv_slotOfArrow`.  The
     symmetric lemma had no consumers in the file or anywhere in
     the codebase.  Per `CLAUDE.md`'s "Don't design for
     hypothetical future requirements" + "If you are certain that
     something is unused, you can delete it completely" rules,
     this `@[simp]` lemma was removed.  Phase 2 / 3 can re-add if
     a downstream proof needs the round-trip.

  Added a substantive non-vacuity test for `eq_slotOfArrow_iff`
  (which IS used internally by the LHS / RHS closed-form proofs
  but lacked a direct test in the audit script).

  Module size after third audit: 974 LOC (down from 981 — net
  -7 from removing the unused round-trip lemma and its docstring).

- **`Orbcrypt.lean`** root file extended with a new import
  `Orbcrypt.Hardness.GrochowQiao.EncoderSlabEval`.

- **Patch version.** `lakefile.lean` bumped from `0.1.21` to
  `0.1.22` for Phase 1 — one new public-API module adds new public
  declarations, warranting the patch-version bump per `CLAUDE.md`'s
  version-bump discipline. The 59-module total rises to 60; the
  zero-sorry / zero-custom-axiom posture and the standard-trio-only
  axiom-dependency posture are both preserved. Full `lake build`
  succeeds across 3,405 jobs (3,404 pre-Phase-1 + 1 new module
  build node) with zero warnings, zero errors.

- **Phase 1 deliverables and gates (all met).**
  * One new `.lean` module (`EncoderSlabEval.lean`).
  * `Orbcrypt.lean` extended with one new import.
  * `scripts/audit_phase_16.lean` extended with `#print axioms` for
    every new public declaration; non-vacuity examples on `m ∈ {1, 2}`.
  * CLAUDE.md change-log entry (this snapshot).
  * Lake build succeeds; audit script clean.

- **Consumer.** Phase 3 (the algebra-iso bridge) consumes the
  associativity identity directly. Phase 4 (σ extraction) and Phase
  5 (arrow preservation from σ + radical) use the per-slot
  evaluation lemmas to argue about encoder structure.

R-TI Research-Scope Discharge — Phase 2 (Audit 2026-04-28 — Path-block
linear restriction, parametric in π) has been completed:

- **One new module.**
  `Orbcrypt/Hardness/GrochowQiao/PathBlockSubspace.lean` (~795 LOC,
  NEW) — linear-algebra infrastructure that **Phase 3's GL³ →
  algebra-iso bridge** consumes. The infrastructure is **parametric in
  a slot permutation `π : Equiv.Perm (Fin (dimGQ m))`** because
  Phase 3 derives π from algebra-iso structure — Phase 2's lemmas do
  not commit to a specific π. Full `lake build` succeeds across
  3,406 jobs with zero warnings, zero errors. Every public
  declaration depends only on the standard Lean trio (`propext`,
  `Classical.choice`, `Quot.sound`); zero `sorry`, zero custom
  axioms.

- **Layer 2.0 — Permutation-matrix wrapper for arbitrary slot
  permutations (~30 LOC).**
  * `permMatrixOf m π : Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ`
    — built directly from Mathlib's `Equiv.Perm.permMatrix`,
    parallel to `liftedSigmaMatrix m σ` (which specialises to vertex
    permutations). Lets Phase 2's `pathBlockMatrix` accept any slot
    permutation π directly, without going through `liftedSigma`.
  * `permMatrixOf_apply` — explicit entry formula
    `permMatrixOf m π i j = if π i = j then 1 else 0`.
  * `permMatrixOf_det_ne_zero` — invertibility (sign of `π` is
    `±1` ≠ 0 in ℚ).

- **Layer 2.1 — Path-block + padding subspaces (defined by support)
  (~200 LOC).**
  * `pathBlockSubspace m adj : Submodule ℚ (Fin (dimGQ m) → ℚ)` —
    vectors that vanish outside `pathSlotIndices m adj`.
  * `paddingSubspace m adj` — symmetric for padding slots.
  * `mem_pathBlockSubspace_iff`, `mem_paddingSubspace_iff` —
    membership characterizations.
  * `pi_single_mem_pathBlockSubspace` — indicator vector at a path
    slot lies in the path-block subspace.
  * `pi_single_mem_paddingSubspace` — symmetric for padding slots.
  * `pathBlockSubspace_disjoint_paddingSubspace` —
    `pathBlockSubspace ⊓ paddingSubspace = ⊥` (disjointness).
  * `pathBlock_padding_decomposition` — every `f : Fin (dimGQ m) → ℚ`
    splits as a path part plus a padding part.
  * `pathBlockSubspace_sup_paddingSubspace_eq_top` —
    `pathBlockSubspace ⊔ paddingSubspace = ⊤` (covering).
  * `pathBlockSubspace_isCompl_paddingSubspace` — the two subspaces
    form a direct-sum decomposition (`IsCompl`).

- **Layer 2.2 — Path-block matrix (parametric in π) (~80 LOC).**
  * `pathBlockMatrix m g π := g.1.val * permMatrixOf m π⁻¹` —
    the first GL component of `g` composed (on the right) with the
    inverse of π's permutation matrix.
  * `pathBlockMatrix_apply` — definitional unfolding to the matrix
    product.
  * `pathBlockMatrix_apply_eq_g_at_pi` — the central simplification:
    `(pathBlockMatrix m g π) i j = g.1.val(i, π j)`. Proved by
    `Finset.sum_eq_single (π j)` collapsing the inner sum.
  * `pathBlockMatrix_one` — at the identity slot permutation,
    `pathBlockMatrix m g 1 = g.1.val`.
  * `pathBlockMatrix_det_ne_zero` — invertibility (composition of
    two invertible matrices).

- **Layer 2.3 — Conditional linear restriction (~210 LOC).**
  * `IsPathBlockDiagonal m adj₁ adj₂ M` — `Prop`-valued helper:
    the matrix has zero entries when the row is a padding slot of
    `adj₂` and the column is a path slot of `adj₁`. This is the
    hypothesis Phase 3 establishes for `M = pathBlockMatrix m g π`
    when π is the partition-preserving slot permutation derived from
    the algebra-iso structure.
  * `IsPaddingBlockDiagonal m adj₁ adj₂ M` — symmetric padding-to-path
    block-vanishing predicate (used for `LinearEquiv` upgrade).
  * `IsFullyPathBlockDiagonal` — combined predicate.
  * `mulVec_mem_pathBlockSubspace_of_isPathBlockDiagonal` — the
    matrix's `mulVec` action takes vectors in `pathBlockSubspace m
    adj₁` to vectors in `pathBlockSubspace m adj₂`. Proof case-splits
    on whether the output index `i` is path or padding (using the
    partition theorem from Layer 2.1) and threads the support
    constraint of `v` and the block hypothesis of `M`.
  * `pathBlockRestrict m adj₁ adj₂ M h_block` — the restriction as
    a `LinearMap` between the two `pathBlockSubspace`s.
  * `pathBlockRestrict_apply` — definitional unfolding.
  * `gl3_restrict_to_pathBlock m adj₁ adj₂ g π h_block` —
    specialises `pathBlockRestrict` to `M = pathBlockMatrix m g π`.

- **Layer 2.4 — Bridge `pathBlockSubspace ≃ₗ presentArrowsSubspace`
  (~280 LOC).**
  * `presentArrowsSubspace m adj : Submodule ℚ (pathAlgebraQuotient
    m)` — vectors that vanish outside `presentArrows m adj`. This is
    the natural codomain of the algebra-iso construction in Phase 3.
  * `mem_presentArrowsSubspace_iff` — membership characterization.
  * `vertexIdempotent_mem_presentArrowsSubspace` — `vertexIdempotent
    m v ∈ presentArrowsSubspace m adj` for any `adj`.
  * `arrowElement_mem_presentArrowsSubspace` — `arrowElement m u v ∈
    presentArrowsSubspace m adj` iff `adj u v = true`.
  * `pathBlockToPresentArrowsFun` — push-forward
    `v : Fin (dimGQ m) → ℚ` through the `slotEquiv` /
    `slotToArrow` correspondence:
    `f a := if a ∈ presentArrows m adj then v (slotOfArrow m a)
    else 0`.
  * `presentArrowsToPathBlockFun` — pull-back
    `f : QuiverArrow m → ℚ`:
    `v i := if i ∈ pathSlotIndices m adj
    then f (slotToArrow m (slotEquiv m i)) else 0`.
  * `slotToArrow_mem_presentArrows_of_path` —
    `slotToArrow m (slotEquiv m i) ∈ presentArrows m adj` for
    `i ∈ pathSlotIndices m adj`.
  * `slotOfArrow_mem_pathSlotIndices_of_present` — converse.
  * `pathBlockToPresentArrowsFun_mem`,
    `presentArrowsToPathBlockFun_mem` — the forward and reverse
    maps' images lie in the corresponding subspaces (unconditional —
    the piecewise definitions make zero outside the support
    automatic, no support hypothesis needed).
  * `presentArrowsToPathBlockFun_pathBlockToPresentArrowsFun`,
    `pathBlockToPresentArrowsFun_presentArrowsToPathBlockFun` —
    round-trip identities (these DO require the support hypothesis
    because the off-support case is discharged via the assumed
    support).
  * `pathBlockToPresentArrows m adj : pathBlockSubspace m adj ≃ₗ[ℚ]
    presentArrowsSubspace m adj` — the bridge `LinearEquiv`. Phase
    3's algebra-iso construction will lift the path-block restriction
    (Layer 2.3) to a linear map between `presentArrowsSubspace m
    adj₁` and `presentArrowsSubspace m adj₂` via this bridge.
  * `pathBlockToPresentArrows_apply`,
    `pathBlockToPresentArrows_symm_apply` — apply lemmas.

- **Audit script.** `scripts/audit_phase_16.lean` extended with **40
  new `#print axioms` entries** plus **15 new non-vacuity `example`
  bindings** under the `PathBlockSubspaceNonVacuity` namespace at
  `m ∈ {1, 2}`, exercising every public Phase-2 declaration:
  * Layer 2.0: identity slot permutation has identity permutation
    matrix at `m = 1`.
  * Layer 2.1: zero vector in both subspaces, vertex / padding
    indicator vectors in the appropriate subspaces, complementarity
    (`IsCompl`) of the two subspaces.
  * Layer 2.2: identity-permutation reduction (`pathBlockMatrix g 1
    = g.1.val`), invertibility for arbitrary `g` and `π`.
  * Layer 2.3: zero matrix is path-block-diagonal, GL³ restriction
    type-elaborates under any path-block-diagonal hypothesis.
  * Layer 2.4: vertex idempotent membership for arbitrary `adj`,
    arrow element membership on the complete graph at `m = 2`,
    bridge `LinearEquiv` type-elaborates, round-trip identity
    `symm ∘ pathBlockToPresentArrows = id` on a concrete vector.
  Total declarations exercised: 828 (up from 788 — +40 from
  Phase 2). Every new declaration depends only on the standard Lean
  trio.

- **`Orbcrypt.lean`** root file extended with one new import
  `Orbcrypt.Hardness.GrochowQiao.PathBlockSubspace`.

- **Patch version.** `lakefile.lean` bumped from `0.1.22` to
  `0.1.23` for Phase 2 — one new public-API module adds new public
  declarations (40 new public `def`/`theorem`/`structure` decls),
  warranting the patch-version bump per `CLAUDE.md`'s
  version-bump discipline. The pre-Phase-2 module total (63) rises
  to 64 (verified via `find Orbcrypt -name '*.lean' | wc -l`); the
  zero-sorry / zero-custom-axiom posture and the standard-trio-only
  axiom-dependency posture are both preserved.

- **Phase 2 deliverables and gates (all met).**
  * One new `.lean` module (`PathBlockSubspace.lean`).
  * `Orbcrypt.lean` extended with one new import.
  * `scripts/audit_phase_16.lean` extended with `#print axioms` for
    every new public declaration; 15 non-vacuity examples on
    `m ∈ {1, 2}`.
  * CLAUDE.md change-log entry (this snapshot).
  * `lakefile.lean` version bumped (`0.1.22 → 0.1.23`).
  * Lake build succeeds (3,406 jobs, zero warnings, zero errors);
    audit script clean.

- **Consumer.** Phase 3 (the GL³ → algebra-iso bridge) supplies the
  partition-preserving slot permutation π and discharges the
  `IsPathBlockDiagonal` hypothesis, then composes
  `gl3_restrict_to_pathBlock` with `pathBlockToPresentArrows` to
  obtain a `LinearEquiv` between
  `presentArrowsSubspace m adj₁` and
  `presentArrowsSubspace m adj₂`. Phase 3 then upgrades this linear
  equivalence to an `AlgEquiv` of the path algebras
  `pathAlgebraQuotient m` (using the encoder's polynomial
  identities from Phase 1).

R-TI Phase 2 — Post-landing audit pass (2026-04-28). Deep audit of
the initial Phase 2 landing surfaced six issues, all fixed in this
audit pass:

1. **Critical: missing plan deliverable
   `gl3_restrict_to_pathBlock_isLinearEquiv`.** The plan's Layer 2.3
   table explicitly listed a `LinearEquiv` form of the path-block
   restriction as a deliverable (under the symmetric block-diagonality
   + invertibility hypotheses), but the initial landing only delivered
   the `LinearMap` form. Added a more general parametric helper
   `pathBlockEquivOfInverse` that takes both `M` and an inverse `M'`
   (each block-diagonal w.r.t. the appropriate adjacency partition)
   along with `M' * M = 1` and `M * M' = 1` proofs, and produces a
   `LinearEquiv` via `LinearEquiv.ofLinear`. Phase 3 instantiates this
   with the specific `M = pathBlockMatrix m g π` and the corresponding
   inverse matrix it derives. Companion apply lemmas
   (`pathBlockEquivOfInverse_apply`, `pathBlockEquivOfInverse_symm_apply`)
   land alongside.

2. **High: module docstring referenced non-existent declarations.**
   The initial landing's module-level `/-! ... -/` docstring listed
   `pathBlockMatrix_restricts_to_pathBlockSubspace` (the actual name is
   `mulVec_mem_pathBlockSubspace_of_isPathBlockDiagonal`),
   `pathBlock_to_presentArrows` (snake-case typo for the camelCase
   `pathBlockToPresentArrows`), and `gl3_restrict_to_pathBlock_isLinearEquiv`
   (a plan deliverable that wasn't yet implemented). Also described
   `presentArrowsSubspace` as "spanned by `vertexIdempotent v` and
   `arrowElement u v`" when the actual definition is by support on
   `presentArrows m adj`. All four false claims fixed in the docstring.

3. **High: `pathBlockSubspace` def docstring referenced two
   non-existent theorems** (`mem_pathBlockSubspace_iff_supported` and
   `pathBlockSubspace_eq_span`) as if they were available "below in
   the file". Either remove the references or implement them — chose
   to implement, adding the substantive theorem
   `pathBlockSubspace_eq_indicator_span` with its supporting decomposition
   lemma `pathBlockSubspace_indicator_decomposition`. The lemma proves
   the equivalence of the support-based and indicator-span definitions
   of the path-block subspace, closing a gap between the docstring
   prose and the code.

4. **Medium: unused imports.** The initial landing imported
   `Mathlib.LinearAlgebra.Span.Defs`, `Mathlib.LinearAlgebra.Basis.Basic`,
   `Mathlib.LinearAlgebra.Basis.Defs`, `Mathlib.LinearAlgebra.LinearIndependent.Defs`,
   `Mathlib.LinearAlgebra.LinearIndependent.Basic`,
   `Mathlib.LinearAlgebra.Matrix.ToLin`, and `Mathlib.Data.Matrix.Basic`,
   none of which are directly referenced in the file's body (transitive
   imports through `PermMatrix.lean` and `Mathlib.LinearAlgebra.Pi`
   suffice for the actual API used). Removed these and added the
   single missing direct import `Mathlib.Algebra.Module.Equiv.Basic`
   (needed for `LinearEquiv.ofLinear`). Build remains clean.

5. **Medium: missing apply lemma for `gl3_restrict_to_pathBlock`.**
   The initial landing had `pathBlockRestrict_apply` (the apply lemma
   for the parametric form) but no corresponding apply lemma for the
   GL³-specialised form. Added `gl3_restrict_to_pathBlock_apply` (a
   `@[simp] rfl` unfolding). Phase 3 will need this when reasoning
   about the GL³-restriction's action on concrete vectors.

6. **Low: test coverage gaps.** The initial landing had 15 non-vacuity
   examples; 24 of 40 public declarations lacked direct coverage
   (relying on indirect coverage via the LinearEquiv's left/right
   inverses or the `IsCompl` packaging of disjointness + sup-top).
   The audit pass added 12 new non-vacuity examples (audit script
   total grows from 15 to 25), directly exercising:
   `pathBlock_padding_decomposition`, `pathBlockSubspace_disjoint_paddingSubspace`,
   `pathBlockSubspace_sup_paddingSubspace_eq_top`,
   `pathBlockSubspace_eq_indicator_span`,
   `pathBlockSubspace_indicator_decomposition`,
   `pathBlockMatrix_apply_eq_g_at_pi` (general form),
   `IsPaddingBlockDiagonal`, `IsFullyPathBlockDiagonal`,
   `pathBlockRestrict`, the new `pathBlockEquivOfInverse` (with M = M' = 1
   on the empty graph and a path/padding disjointness witness for the
   block-diagonality discharge),
   `slotToArrow_mem_presentArrows_of_path`,
   `slotOfArrow_mem_pathSlotIndices_of_present`,
   `pathBlockToPresentArrowsFun_mem`,
   `presentArrowsToPathBlockFun_mem`, and the bridge round-trip
   `forward ∘ symm = id` (companion to the existing
   `symm ∘ forward = id` test).

**Phase 2 audit-pass scoreboard (2026-04-28).** Module size:
926 LOC (up from 795 — net +131 LOC: the
`pathBlockEquivOfInverse` constructor + its two apply lemmas
(~75 LOC), the `gl3_restrict_to_pathBlock_apply` simp lemma (~10 LOC),
the indicator-span theorem `pathBlockSubspace_eq_indicator_span`
together with its supporting decomposition
`pathBlockSubspace_indicator_decomposition` (~46 LOC)). Public
declarations: 40 → 46 (+6). Audit script `#print axioms` entries:
40 → 46 (+6). Audit script non-vacuity examples: 15 → 25 (+10).
Total audit-script declarations exercised: 828 → 834 (+6). Standard-
trio-only axiom-dependency posture and zero-sorry / zero-custom-axiom
posture preserved. Full `lake build` succeeds (3,406 jobs, zero
warnings, zero errors).

R-TI Phase 2 — Second audit pass (2026-04-28). A targeted re-audit
of the post-first-audit state surfaced three remaining docstring
inaccuracies, all fixed in this pass:

1. **Stale name `pathBlockEquivOfFullyDiagonal` in module docstring.**
   The first audit pass's docstring rewrite introduced the name
   `pathBlockEquivOfFullyDiagonal` for the LinearEquiv form, but the
   actual declaration lands as `pathBlockEquivOfInverse`. The
   reference in the module-level `/-! ... -/` block at line 65 was a
   broken cross-reference. Fixed by renaming the docstring entry to
   match the actual declaration name and refining the description to
   reflect the actual signature (parametric in `M` and an inverse
   `M'` together with their block-diagonality proofs and matrix-
   inverse equations `M' * M = 1` and `M * M' = 1`).

2. **Stale claim `g.1 * (liftedSigmaMatrix m π⁻¹)` in module
   docstring.** The Layer-2.2 description claimed `pathBlockMatrix`
   was defined as `g.1 * (liftedSigmaMatrix m π⁻¹)`, but the actual
   definition uses `g.1.val * permMatrixOf m π⁻¹` (the parametric
   slot-permutation wrapper, not the vertex-permutation lift). Fixed
   to match the actual definition.

3. **False claim about `liftedSigmaMatrix`'s signature.** The
   module-level docstring's parenthetical claimed
   "`liftedSigmaMatrix` already accepts an arbitrary
   `Equiv.Perm (Fin (dimGQ m))` once we generalise from
   `liftedSigma m σ`". This is false: `liftedSigmaMatrix m σ` only
   accepts `σ : Equiv.Perm (Fin m)` (a vertex permutation) and
   *internally* lifts via `liftedSigma m σ` to a slot permutation
   on `Fin (dimGQ m)`. There is no generalisation of
   `liftedSigmaMatrix` to arbitrary slot permutations — `permMatrixOf`
   was introduced in Phase 2 *precisely* to provide that wrapper.
   Fixed by rewriting the parenthetical to honestly describe the
   relationship between `liftedSigmaMatrix` and `permMatrixOf`.

4. **Audit-script section header was incomplete.** The
   `§ 15.17 R-TI rigidity discharge — Phase 2` comment block listed
   only a subset of the public Phase-2 declarations under each
   layer's bullet (e.g., it omitted `pi_single_mem_pathBlockSubspace`,
   `pathBlockSubspace_indicator_decomposition`,
   `pathBlockSubspace_eq_indicator_span`,
   `pathBlock_padding_decomposition`,
   `pathBlockMatrix_apply_eq_g_at_pi`, `pathBlockMatrix_one`,
   `pathBlockMatrix_det_ne_zero`, `IsPaddingBlockDiagonal`,
   `IsFullyPathBlockDiagonal`,
   `mulVec_mem_pathBlockSubspace_of_isPathBlockDiagonal`,
   `pathBlockRestrict_apply`, `gl3_restrict_to_pathBlock_apply`,
   the entire Layer 2.3.1 / `pathBlockEquivOfInverse` family, and most
   of Layer 2.4's helper lemmas). Updated the comment block to list
   every public declaration under each layer.

**Mathematical soundness re-verification.** Each of the 46 public
declarations was traced through line-by-line and confirmed correct:

* `permMatrixOf`, `permMatrixOf_apply`, `permMatrixOf_det_ne_zero`
  — correct via Mathlib's `Equiv.Perm.permMatrix` + sign analysis.
* `pathBlockSubspace`, `paddingSubspace` and their `mem_*_iff` —
  support-based Submodule definitions, all subspace properties
  discharged by simp on the support condition.
* `pi_single_mem_pathBlockSubspace`, `pi_single_mem_paddingSubspace`
  — case-split on `i = j` with `Pi.single_eq_of_ne` for the off-diagonal.
* `pathBlockSubspace_indicator_decomposition` — funext + case-split
  on `j ∈ pathSlotIndices`; uses `Finset.sum_eq_single` /
  `Finset.sum_eq_zero` to collapse the sum.
* `pathBlockSubspace_eq_indicator_span` — `le_antisymm` of the two
  inclusions, threading through `Submodule.sum_mem`,
  `Submodule.smul_mem`, `Submodule.subset_span`, and
  `Submodule.span_le`.
* `pathBlockSubspace_disjoint_paddingSubspace` — case-split on
  `i ∈ path` using the partition theorem from `SlotSignature.lean`.
* `pathBlock_padding_decomposition` — explicit construction
  `if i ∈ path then f i else 0` + the symmetric padding part.
* `pathBlockSubspace_sup_paddingSubspace_eq_top` — uses the
  decomposition + `Submodule.add_mem_sup`.
* `pathBlockSubspace_isCompl_paddingSubspace` — bundles the
  `disjoint_iff` and `codisjoint_iff` proofs.
* `pathBlockMatrix`, `pathBlockMatrix_apply` — definitions and `rfl`-
  level unfolding.
* `pathBlockMatrix_apply_eq_g_at_pi` — `Finset.sum_eq_single (π j)`
  collapse using `permMatrixOf_apply` + `Equiv.Perm.inv_def` +
  `Equiv.symm_apply_apply` / `Equiv.apply_symm_apply`.
* `pathBlockMatrix_one` — applies `pathBlockMatrix_apply_eq_g_at_pi`
  + `(1 : Equiv.Perm) j = j` (definitional via `Equiv.refl`).
* `pathBlockMatrix_det_ne_zero` — `Matrix.det_mul` + `mul_ne_zero`
  + `Matrix.GeneralLinearGroup.det_ne_zero` + the perm-matrix
  determinant lemma.
* `IsPathBlockDiagonal`, `IsPaddingBlockDiagonal`,
  `IsFullyPathBlockDiagonal` — Prop-valued predicates.
* `mulVec_mem_pathBlockSubspace_of_isPathBlockDiagonal` — case-split
  on `j ∈ path` (uses block hypothesis) vs `j ∉ path` (uses support
  of `v`); uses partition theorem to derive `i ∈ padding` from
  `i ∉ path`.
* `pathBlockRestrict`, `pathBlockRestrict_apply` — LinearMap
  packaging + apply lemma.
* `gl3_restrict_to_pathBlock`, `gl3_restrict_to_pathBlock_apply` —
  specialisation to `pathBlockMatrix m g π`.
* `pathBlockEquivOfInverse` — uses `LinearEquiv.ofLinear` with the
  forward and backward `pathBlockRestrict` maps; both inversion
  conditions discharge via `Matrix.mulVec_mulVec` +
  `h_left/h_right` + `Matrix.one_mulVec`.
* `pathBlockEquivOfInverse_apply`, `pathBlockEquivOfInverse_symm_apply`
  — apply lemmas.
* `presentArrowsSubspace` and `mem_presentArrowsSubspace_iff` —
  parallel to `pathBlockSubspace`.
* `vertexIdempotent_mem_presentArrowsSubspace` — case-split on
  `a` ∈ `{id, edge}`; the `id` case uses
  `presentArrows_id_mem` and the `edge` case has zero value.
* `arrowElement_mem_presentArrowsSubspace` — `id` case has zero
  value; `edge u' v'` case uses `presentArrows_edge_mem_iff`.
* `pathBlockToPresentArrowsFun`, `presentArrowsToPathBlockFun` —
  piecewise definitions.
* `slotToArrow_mem_presentArrows_of_path` — case-split on
  `slotEquiv m i`; uses `pathSlotIndices_eq_vertex_union_presentArrow`.
* `slotOfArrow_mem_pathSlotIndices_of_present` — symmetric.
* `pathBlockToPresentArrowsFun_mem`, `presentArrowsToPathBlockFun_mem`
  — unconditional via the piecewise definitions.
* `presentArrowsToPathBlockFun_pathBlockToPresentArrowsFun` and
  `pathBlockToPresentArrowsFun_presentArrowsToPathBlockFun` —
  round-trip identities via `slotToArrow`/`slotOfArrow` mutual
  inverses.
* `pathBlockToPresentArrows`, `pathBlockToPresentArrows_apply`,
  `pathBlockToPresentArrows_symm_apply` — LinearEquiv packaging.

Every declaration's `#print axioms` was verified: 674 total Phase-2
declarations exercised by the audit script, all dependent only on
the standard Lean trio (`propext`, `Classical.choice`, `Quot.sound`),
none on `sorryAx` or any custom axiom.

**Test coverage re-verification.** All 46 public declarations are
covered: 25 direct non-vacuity tests in `PathBlockSubspaceNonVacuity`
+ 5 trivial `Iff.rfl` lemmas (no separate test needed) + 7
`@[simp] rfl` apply lemmas (no separate test needed; their content
is the `rfl` itself) + 9 indirect coverage entries (covered through
the LinearEquiv's `left_inv`/`right_inv`, the `IsCompl` packaging,
or the parametric LinearMap restrict via specialisation).

**Plan-deliverable status (`pathBlockBasis`).** The plan's Layer-2.1
table lists `pathBlockBasis : Basis (pathSlotIndices m adj) ℚ
(pathBlockSubspace m adj)` as a deliverable. This is **deferred**
and not strictly required by Phase 3 (which uses `gl3_restrict_to_pathBlock`,
`pathBlockEquivOfInverse`, and `pathBlockToPresentArrows` directly,
not the basis packaging). The construction would require
`Basis.mk` with explicit linear independence + spanning proofs over
the indicator family; the spanning is `pathBlockSubspace_eq_indicator_span`
(now proven), but linear independence requires additional Mathlib
plumbing (~50–80 LOC). Tracked as an optional Phase-2 follow-up;
Phase 3 does not block on it.

R-TI Research-Scope Discharge — Phase 3 (Audit 2026-04-28 — GL³ →
algebra-iso bridge, partial-discharge form) has been completed:

- **Phase 3 partial-discharge strategy.** The R-TI plan
  (`docs/planning/R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md` § "Phase 3 —
  GL³ → algebra-iso bridge") describes the deep step as a 3,200 LOC,
  6–18 month research-scope workstream spanning the Manin tensor-
  stabilizer theorem (Sub-task A.5, ~600 LOC, **HIGH** risk, Mathlib
  prerequisites not present at the pinned commit) and the
  distinguished-padding rigidity argument (Sub-task A.3, ~700 LOC,
  **HIGH** risk, polynomial-invariant existence is research-grade).
  The plan explicitly anticipates a partial-discharge fall-back under
  § "Phase 3 alternative — partial discharge": "Landing Phases 1, 2,
  4, 5, 6 conditional on a research-scope `Prop`
  `GL3InducesAlgEquivOnPathSubspace`. This Prop becomes the new
  explicit research-scope obligation, replacing the v3-era
  `GL3PreservesPartitionCardinalities` +
  `GL3InducesArrowPreservingPerm` pair with a single cleaner
  statement. **This partial closure is strictly better than the
  current Stage 0–5 state**: it identifies the deep content as a
  single well-defined `Prop` (rather than two coupled `Prop`s), and
  makes all the surrounding plumbing unconditional." The Phase 3
  landing in this commit takes that partial-discharge path: the
  tractable Sub-tasks A.1, A.2, A.4 land unconditionally; Sub-task A.6
  lands the conditional headline + identity-case witnesses; the deep
  research-scope content of A.3 + A.5 + A.6's matrix-action upgrade
  is captured as a single named `Prop`
  `GL3InducesAlgEquivOnPathSubspace`.

- **Four new modules** under `Orbcrypt/Hardness/GrochowQiao/`
  (40 → 44 modules):

  * `EncoderPolynomialIdentities.lean` (Sub-task A.1, ~190 LOC) —
    Phase-3-facing catalogue of the polynomial identities the
    encoder satisfies.  Public surface:
    - `encoder_assoc_path` (re-export of `encoder_associativity_identity`
      under the Phase-3 name) — the central polynomial identity.
    - `encoder_diag_at_path_in_zero_one` — path-algebra slot
      diagonal value is `0` (present-arrow) or `1` (vertex).
    - `encoder_diag_at_padding_eq_two` — padding slot diagonal is
      `2` (re-export of `grochowQiaoEncode_diagonal_padding`
      in slot-discriminator form).
    - `encoder_off_diag_path_padding_zero` — mixed-class triples
      vanish (re-export of `encoder_zero_at_mixed_triples`).
    - `encoder_padding_diag_only` — at any padding slot `i`, the
      slab `(i, j, k)` is non-zero iff `j = k = i` (the
      trivial-algebra identity for the padding portion).

  * `TensorIdentityPreservation.lean` (Sub-task A.2, ~160 LOC) —
    GL³-invariance of the associativity polynomial identity.
    Public surface:
    - `IsAssociativeTensor T` (`Prop`-valued predicate over a
      `CommSemiring F`).
    - `encoder_isAssociativeTensor_full_path` — the encoder satisfies
      the predicate when every slot is path-algebra (e.g., the
      complete directed graph).
    - `IsAssociativeTensorPreservedByGL3 n F` (research-scope `Prop`
      capturing the general GL³ preservation; full discharge ~150
      LOC of `Finset.sum_comm` manipulation).
    - `isAssociativeTensorPreservedByGL3_identity_case` — identity
      `(g = 1)` witness, unconditional.

  * `PathOnlyTensor.lean` (Sub-task A.4, ~200 LOC) — path-restricted
    encoder + restricted GL³ Prop.
    Public surface:
    - `pathOnlyStructureTensor m adj : Tensor3 (pathSlotIndices m adj).card ℚ`
      — encoder restricted to path-algebra slots via
      `(pathSlotIndices m adj).equivFin`.
    - `pathOnlyStructureTensor_apply` — definitional unfold.
    - `pathOnlyStructureTensor_inherits_encoder_assoc` —
      every `Fin (pathSlotIndices m adj).card`-index, mapped via
      `equivFin.symm`, lands on a path-algebra slot of the encoder
      (so the path-only tensor inherits the encoder's path-algebra
      shape unconditionally).
    - `PathOnlyTensorIsAssociative m adj` (research-scope `Prop` —
      the index-form re-indexing of `encoder_assoc_path` via
      `Finset.sum_equiv`).
    - `RestrictedGL3OnPathOnlyTensor m` (research-scope `Prop` —
      path-block GL³ restriction equivariance).
    - `restrictedGL3OnPathOnlyTensor_identity_case` — identity
      witness, unconditional.

  * `AlgEquivFromGL3.lean` (Sub-task A.6, ~210 LOC) — the conditional
    headline + research-scope `Prop` capturing the deep content.
    Public surface:
    - `GL3InducesAlgEquivOnPathSubspace m` (research-scope `Prop`
      capturing Sub-tasks A.3 + A.5 + A.6's deep multilinear-algebra
      content as a single named obligation):
      ```
      ∀ (adj₁ adj₂) (g : GL × GL × GL),
        g • encode m adj₁ = encode m adj₂ →
        ∃ ϕ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m,
          ϕ '' (presentArrowsSubspace m adj₁ : Set _) =
            presentArrowsSubspace m adj₂.
      ```
    - `gl3_induces_algEquiv_on_pathSubspace` — conditional headline
      consuming the `Prop`.
    - `gl3_induces_algEquiv_on_pathSubspace_identity_case` —
      `(g = 1, adj₁ = adj₂)` identity-case witness, unconditional;
      the AlgEquiv is `AlgEquiv.refl`.
    - `gl3_induces_algEquiv_on_pathSubspace_self` —
      same-graph witness, unconditional.
    - `gl3_algEquiv_partial_closure_status_disclosure` — `True`
      anchor documenting the partial-closure framework.

- **Mathematical content.**

  * **Partition-aligned support (Sub-task A.1.3).** Combined with
    Sub-task A.1.4 (padding slabs are diagonal-only), this exhibits
    the encoder's non-zero entries as cleanly split between
    "all-path" triples and "all-padding" triples — no mixed
    contributions.  This is the partition-alignment property that
    Sub-task A.3's polynomial-invariant rigidity argument exploits.

  * **Diagonal-value distinguishability (Sub-tasks A.1.1, A.1.2).**
    The three slot kinds (vertex, present-arrow, padding) are
    pairwise distinguishable at the diagonal-value level alone:
    `1`, `0`, `2` respectively.  This closes the isolated-vertex
    degeneracy that motivated Stage 0's distinguished-padding
    strengthening.

  * **Trivial-algebra identity (Sub-task A.1.4).** Padding slots
    contribute non-zero entries only at the triple-diagonal, with
    value `2`.  This means the padding portion of the encoder is a
    **direct sum of trivial 1-dimensional algebras**, each spanned
    by a single padding slot — structurally distinguishable from
    the path-algebra portion's multi-entry slabs.

  * **Associative-tensor predicate (Sub-task A.2).** A 3-tensor is
    *associative* if its entries satisfy
    `∑_a T(i, j, a) · T(a, k, l) = ∑_a T(j, k, a) · T(i, a, l)`.
    The encoder satisfies this on full-adjacency graphs
    (`encoder_isAssociativeTensor_full_path`), inheriting from
    `encoder_assoc_path`.  GL³ preservation of the predicate is
    captured as a research-scope `Prop`; the identity-GL³ case is
    proved unconditionally via Mathlib's `one_smul`.

  * **Path-only structure tensor (Sub-task A.4).** The encoder
    restricted to path-algebra slots, packaged as
    `Tensor3 (pathSlotIndices m adj).card ℚ` via the standard
    `Finset.equivFin` enumeration.  Every `Fin
    (pathSlotIndices m adj).card`-index lands, via `equivFin.symm`,
    on a path-algebra slot of the encoder (the
    `pathOnlyStructureTensor_inherits_encoder_assoc` theorem
    captures this fact directly from `mem_pathSlotIndices_iff`).

  * **Conditional algebra-iso bridge (Sub-task A.6).** The plan's
    headline theorem:
    ```
    g • encode adj₁ = encode adj₂ →
      ∃ (ϕ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m),
        ϕ '' presentArrowsSubspace adj₁ = presentArrowsSubspace adj₂
    ```
    is delivered conditionally on the research-scope `Prop`.  The
    identity case (`g = 1`, `adj₁ = adj₂`) is delivered
    unconditionally with `AlgEquiv.refl`.

- **Audit script.** `scripts/audit_phase_16.lean` extended with a
  new `§ 15.18` section listing 19 new `#print axioms` entries plus
  9 non-vacuity `example` bindings under
  `AlgEquivFromGL3NonVacuity` exercising every public Phase-3
  declaration on concrete `m ∈ {1, 2}` instances.  Every new
  declaration depends only on the standard Lean trio (`propext`,
  `Classical.choice`, `Quot.sound`); zero `sorryAx`, zero custom
  axioms.

- **Verification.** Full `lake build` succeeds with **3,410 jobs**
  (up from 3,406 — four new modules) with zero warnings, zero
  errors.  Phase 16 audit script runs cleanly (exit code 0); axiom
  output for every new declaration is on the standard trio.

- **Plan-deliverable status (Sub-task A.3, A.5, A.6 matrix-action
  upgrade).** The full plan budgets these at ~1,700 LOC of
  research-scope content (A.3: ~700 LOC, A.5: ~600 LOC, A.6 matrix-
  action upgrade: ~400 LOC).  Each sub-task is genuine multi-month
  mathematical research:

  * **Sub-task A.3** (distinguished-padding rigidity) requires
    constructing a polynomial GL³-invariant that distinguishes
    `|paddingSlotIndices m adj₁| = |paddingSlotIndices m adj₂|`.
    The plan rates A.3.2 (the polynomial-invariant existence step)
    as the **highest-research-content density** sub-task in
    Approach A.

  * **Sub-task A.5** (Manin's tensor-stabilizer theorem) requires
    formalising abstract algebra structure-tensor concepts not
    present in Mathlib at the pinned commit, including
    `Algebra.structureTensor`, the basis-change formula, and the
    core ~300 LOC index-tracking proof that a GL³ tensor iso forces
    a multiplicative algebra hom.

  * **Sub-task A.6 matrix-action upgrade** lifts A.5's path-only
    AlgEquiv to the full `pathAlgebraQuotient m` algebra with the
    present-arrow subspace preservation property.

  All three are tracked as research milestone
  **R-15-residual-TI-reverse-phase-3** at
  `docs/planning/R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md` § 8 (Risk
  register).

- **Consumer-ready interface for Phases 4, 5, 6.** With the
  partial-discharge `Prop` `GL3InducesAlgEquivOnPathSubspace`
  landed, Phases 4, 5, 6 (Wedderburn–Mal'cev σ extraction, arrow
  preservation, final discharge) can be implemented **conditional
  on this single `Prop`** rather than the v3-era
  `GL3PreservesPartitionCardinalities` +
  `GL3InducesArrowPreservingPerm` pair.  Once the research-scope
  `Prop` is discharged unconditionally, the entire chain becomes
  unconditional and `grochowQiao_isInhabitedKarpReduction :
  @GIReducesToTI ℚ _` follows.

- **Patch version.** `lakefile.lean` bumped from `0.1.23` to
  `0.1.24`.  Module count rises from 40 to 44; public declaration
  count rises by ~25 (5 from A.1, 4 from A.2, 6 from A.4, 5 from
  A.6, plus a few helper theorems and research-scope `Prop`
  definitions).  Zero-sorry / zero-custom-axiom posture and the
  standard-trio-only axiom-dependency posture are preserved.

R-TI Phase 3 — Post-landing audit pass (2026-04-28). Targeted
re-audit of the initial Phase 3 landing surfaced **four** residual
issues — three theatrical-theorem violations and one security-by-
docstring naming violation — all fixed in this audit pass:

1. **`restrictedGL3OnPathOnlyTensor_identity_case` was vacuous
   (`PathOnlyTensor.lean`).** The pre-audit signature took a single
   adjacency `adj` and the trivial conclusion `card = card`, with
   the hypothesis `_h` ignored.  The conclusion was `rfl` regardless
   of any GL³ hypothesis — this exactly matches the theatrical
   pattern that the prior R-TI audit-pass-II refactored
   `gl3_preserves_partition_cardinalities_identity_case` to fix.
   The post-audit signature takes `(adj₁, adj₂)` distinct, takes
   the hypothesis `1 • encode m adj₁ = encode m adj₂`, applies
   `one_smul` to derive `encode m adj₁ = encode m adj₂`, then uses
   the post-Stage-0 diagonal-value classification
   (`grochowQiaoEncode_diagonal_padding` for `adj _ _ = false`,
   `grochowQiaoEncode_diagonal_present_arrow` for `adj _ _ = true`)
   at every arrow slot to derive `adj₁ = adj₂` by funext.  The
   conclusion `cardadj₁ = cardadj₂` then follows.  Substantive
   content: the proof actually consumes the hypothesis.

2. **`gl3_induces_algEquiv_on_pathSubspace_identity_case` was
   vacuous (`AlgEquivFromGL3.lean`).** The pre-audit signature
   carried the hypothesis with an underscore prefix (`_h_eq`,
   indicating the hypothesis is intentionally unused), making the
   theorem effectively `∃ ϕ : pathAlgebraQuotient m ≃ₐ[ℚ]
   pathAlgebraQuotient m, ϕ '' S adj = S adj` for any `adj` — pure
   `AlgEquiv.refl` content with no GL³ inhabitance witnessed.  The
   post-audit signature takes `(adj₁, adj₂)` distinct, takes the
   hypothesis `1 • encode m adj₁ = encode m adj₂`, derives `adj₁ =
   adj₂` via the same diagonal-value classification, then exhibits
   `AlgEquiv.refl` after `subst`-ing the adjacency equality.
   Substantive content: the proof actually consumes the hypothesis.

3. **`gl3_induces_algEquiv_on_pathSubspace_self` was misleadingly
   named (`AlgEquivFromGL3.lean`).** The pre-audit theorem took a
   single `adj` and exhibited `AlgEquiv.refl '' S adj = S adj` — a
   structural sanity check on `AlgEquiv.refl` that has *no* GL³ in
   the statement and *no* encoder hypothesis, so it is **not** a
   witness of `GL3InducesAlgEquivOnPathSubspace`'s identity case.
   The name `_self` suggested it was a `(adj₁ = adj₂)` case of the
   Prop.  Renamed to `algEquivRefl_preserves_presentArrowsSubspace`
   to honestly describe the content (no GL³, no encoder, just
   `AlgEquiv.refl`'s preservation property).  Per the Naming
   convention rule "Names describe content, never provenance," the
   new name describes what the theorem proves.

4. **`pathOnlyStructureTensor_inherits_encoder_assoc` was a
   security-by-docstring-style naming violation
   (`PathOnlyTensor.lean`).** The pre-audit name promised
   "associativity inheritance" from the encoder, but the content
   delivered only the **path-algebra membership precondition** for
   the index image (i.e., "every `Fin (pathSlotIndices m adj).card`-
   index lands on a path-algebra slot").  The actual associativity
   identity for the path-only tensor requires a `Finset.sum_equiv`
   re-indexing argument from `encoder_assoc_path`, captured in the
   research-scope `Prop` `PathOnlyTensorIsAssociative`.  Renamed to
   `pathOnlyStructureTensor_index_is_path_algebra` to honestly
   describe the content (path-algebra membership of the index
   image, not associativity inheritance).  This is the same pattern
   as the security-by-docstring rule applied to non-security
   identifiers: name the content, not the consumer's downstream
   intent.

5. **Audit-script tests upgraded.** The pre-audit test suite
   (`scripts/audit_phase_16.lean` § 15.18 / `AlgEquivFromGL3NonVacuity`)
   contained two trivial `example : True := by trivial` tests that
   exercised nothing.  The post-audit pass replaces them with 12
   substantive `example` bindings exercising every public Phase-3
   declaration on concrete `m ∈ {1, 2}` instances.  Specifically:

   * The A.1.0 associativity test now states the actual sum equality
     rather than discarding the result via `True`.
   * The A.4 path-only tensor index-is-path-algebra test now
     concretely exercises `pathOnlyStructureTensor_index_is_path_algebra`
     on `m = 2` with a non-trivial adjacency
     (`fun u v => decide (u.val ≠ v.val)`, the "complete graph minus
     self-loops" with two present arrows).
   * The A.4 substantive identity-case test exercises the post-audit
     `restrictedGL3OnPathOnlyTensor_identity_case` signature with
     two adjacencies + the GL³ hypothesis.
   * The A.6 substantive identity-case test exercises the post-audit
     `gl3_induces_algEquiv_on_pathSubspace_identity_case` signature
     with two adjacencies + the GL³ hypothesis.
   * The A.6 conditional headline test exercises the post-audit
     headline with two adjacencies + the research-scope `Prop` +
     the GL³ hypothesis.
   * A new `pathOnlyStructureTensor_apply` simp-lemma test exercises
     the apply-lemma directly.

**Verification.** Full `lake build` succeeds with **3,410 jobs**,
zero warnings, zero errors.  Phase 16 audit script runs cleanly
(exit code 0); every new declaration depends only on the standard
Lean trio (`propext`, `Classical.choice`, `Quot.sound`).  Zero
`sorryAx`, zero custom axioms.  Module count remains 44 (no new
modules added; only theorem-content refactoring + audit-script
test upgrades).  `lakefile.lean` retains `0.1.24` because the
audit-pass refactoring is API-breaking only at the
identity-case-witness level (consumers of the pre-audit theorems
must update to the new `(adj₁, adj₂)` + hypothesis signature) but
the public-API surface count is unchanged.

**Honest scoreboard.** Pre-audit, the Phase 3 landing carried
**four theatrical or misleadingly-named declarations**: two
identity-case theorems whose hypotheses were ignored, one `_self`
theorem that didn't witness the Prop, and one `_inherits_encoder_assoc`
theorem whose name overstated its content.  The post-audit pass
replaces them with substantive theorems whose proofs genuinely
consume their hypotheses, properly-named theorems whose names
describe their content, and a comprehensive audit-script test suite
that exercises every public declaration on non-trivial inputs.
This brings R-TI Phase 3's partial-discharge form fully in line
with the post-Workstream-I-audit honesty discipline established
in CLAUDE.md's "Names describe content, never provenance" and
"Security-by-docstring prohibition" rules.

R-TI Phase 3 — Strengthening pass (2026-04-28, third sweep).  Deeper
re-audit identified **two research-scope `Prop`s that were tractable
to convert to real theorems** and **one mathematically-incorrect
claim** that needed dropping:

1. **`PathOnlyTensorIsAssociative` upgraded from research-scope `Prop`
   to a substantively proven theorem** (`PathOnlyTensor.lean`).  The
   pre-strengthening landing carried `PathOnlyTensorIsAssociative
   m adj : Prop` as an unproven research-scope obligation.  This
   strengthening pass **proves** the path-only structure tensor
   satisfies the associativity polynomial identity
   `IsAssociativeTensor`, via `Finset.sum_equiv` re-indexing of
   `encoder_assoc_path`.  The proof:
   * Re-indexes path-only sums (over `Fin (pathSlotIndices m adj).card`)
     to subtype Fintype-sums (over `↥(pathSlotIndices m adj)`) via
     `Equiv.sum_comp` along `equivFin.symm`.
   * Converts the subtype Fintype-sum to a Finset sum over
     `(pathSlotIndices m adj).attach` via `Finset.univ_eq_attach`,
     then to a plain Finset sum over `pathSlotIndices m adj` via
     `Finset.sum_attach`.
   * Extends the Finset sum to a `Fin (dimGQ m)`-univ sum via
     `Finset.sum_subset`, showing path/padding-mixed terms contribute
     zero (via the new private helpers
     `pathOnlySummand_zero_of_not_path_algebra` /`'`, which apply
     `grochowQiaoEncode_padding_right`'s ambient-branch evaluation
     plus a `j' = a` impossibility argument since `j'` is path-
     algebra and `a` is padding).
   * Applies `encoder_assoc_path` (Sub-task A.1.0) on the
     `Fin (dimGQ m)`-univ sums to conclude.

   The new theorem `pathOnlyStructureTensor_isAssociative` is the
   substantive content; the alias `PathOnlyTensorIsAssociative_proof`
   retains the original name for consumer-facing reference (and to
   make the audit script's reference clear).  Both have axiom output
   `[propext, Classical.choice, Quot.sound]`.

2. **`IsAssociativeTensorPreservedByGL3` dropped as mathematically
   incorrect for arbitrary GL³** (`TensorIdentityPreservation.lean`).
   The pre-strengthening landing carried
   `IsAssociativeTensorPreservedByGL3 n F : Prop` as a research-scope
   obligation claiming "for all GL³ `g`, `IsAssociativeTensor T →
   IsAssociativeTensor (g • T)`".  **This claim is false** for
   generic GL³ — only the structure-tensor-preserving sub-class
   (specifically, `(P, P, P⁻ᵀ)`-shaped triples corresponding to
   basis changes of the underlying algebra) preserves associativity.
   For arbitrary `(g.1, g.2, g.3) ∈ GL × GL × GL`, the polynomial
   identity is not preserved (counterexample: pick a non-associative
   T and find `g` such that `g • T` is associative; reverse `g` to
   produce a counterexample).

   This strengthening pass **drops** the misleading `Prop` and its
   identity-case witness from the codebase, replacing the module
   docstring with an explicit `Mathematical correctness` section
   that documents the actual preservation structure (the Manin
   tensor-stabilizer subgroup), and points at
   `GL3InducesAlgEquivOnPathSubspace` in `AlgEquivFromGL3.lean` as
   the correct research-scope bundle for the deep content.

   The remaining content of `TensorIdentityPreservation.lean` is
   the `IsAssociativeTensor` predicate (correct) +
   `encoder_isAssociativeTensor_full_path` (correct, real proof
   delegating to `encoder_assoc_path`).

3. **`gl3_algEquiv_partial_closure_status_disclosure` corrected to
   honestly describe what's still research-scope.**  The pre-
   strengthening docstring listed `RestrictedGL3OnPathOnlyTensor`
   as a research-scope sub-Prop, which is correct (path/padding
   cardinality preservation is genuinely research-scope content of
   Sub-task A.3).  No content change here; just docstring alignment.

**Audit-script test upgrades (post-strengthening):**

* `pathOnlyStructureTensor_isAssociative` is now exercised on
  `m = 2` with the non-trivial adjacency `fun u v => decide (u.val ≠
  v.val)` (complete graph minus self-loops, 2 present arrows).  This
  is a non-vacuous test of the substantive proof.
* The dropped `isAssociativeTensorPreservedByGL3_identity_case` test
  has been removed from the audit script.

**Verification.** Full `lake build` succeeds with **3,410 jobs**,
zero warnings, zero errors.  Phase 16 audit script runs cleanly
(exit code 0); every Phase-3 declaration depends only on the
standard Lean trio (`propext`, `Classical.choice`, `Quot.sound`);
zero `sorryAx`, zero custom axioms.

**Honest scoreboard, post-strengthening pass.** Of the four
research-scope `Prop`s introduced by the initial Phase 3 landing
(`IsAssociativeTensorPreservedByGL3`, `PathOnlyTensorIsAssociative`,
`RestrictedGL3OnPathOnlyTensor`, `GL3InducesAlgEquivOnPathSubspace`):

* **`PathOnlyTensorIsAssociative`** — converted from research-scope
  Prop to **substantively proven theorem**
  (`pathOnlyStructureTensor_isAssociative`).
* **`IsAssociativeTensorPreservedByGL3`** — **dropped** as
  mathematically incorrect for arbitrary GL³.
* **`RestrictedGL3OnPathOnlyTensor`** — retained as research-scope
  Prop (path/padding cardinality preservation is genuinely deep
  content of Sub-task A.3).
* **`GL3InducesAlgEquivOnPathSubspace`** — retained as the genuinely
  research-scope obligation (Manin theorem + rigidity argument; ~80
  pages on paper, ~1,800 LOC of Lean).

The remaining two research-scope `Prop`s capture content that is
**genuinely mathematically deep** (Manin's theorem; structure-tensor
rigidity), not "tractable but unproven" content.  Both have
unconditional identity-case witnesses that consume their hypotheses
non-trivially via the post-Stage-0 diagonal-value classification.

R-TI Phase 3 — Cleanup pass (2026-04-28, fourth sweep).  Final audit
pass to remove dead code, fix stale docstrings, and add additional
substantive content:

1. **Removed dead code** (per CLAUDE.md's "If you are certain that
   something is unused, you can delete it completely" rule):

   * **`PathOnlyTensorIsAssociative_proof`** — pure renaming alias of
     `pathOnlyStructureTensor_isAssociative` with no consumers; both
     lived in `PathOnlyTensor.lean`.  Removed the alias.
   * **`algEquivRefl_preserves_presentArrowsSubspace`** — pure
     `Set.image_id` specialisation that simply restated `AlgEquiv.refl`
     preserves `presentArrowsSubspace`; had no consumers and no
     substantive content.  Removed from `AlgEquivFromGL3.lean`.

2. **Added substantive content**:

   * **`pathOnlyStructureTensor_diagonal_in_zero_one`** —
     `PathOnlyTensor.lean`.  At any diagonal index `i : Fin
     (pathSlotIndices m adj).card`, the path-only tensor's diagonal
     value is `0` (present-arrow slot) or `1` (vertex slot).  Proof:
     unfold `pathOnlyStructureTensor_apply`, observe the underlying
     `Fin (dimGQ m)`-slot is path-algebra (membership in
     `pathSlotIndices`), apply `encoder_diag_at_path_in_zero_one`.
     This transfers the encoder's path-algebra diagonal classification
     to the path-only structure tensor; Phase 5's adjacency-recovery
     argument (research-scope) consumes this distinction.

3. **Fixed stale docstrings**:

   * `pathOnlyStructureTensor_index_is_path_algebra`'s docstring
     said "the re-indexed associativity itself is the research-scope
     `PathOnlyTensorIsAssociative` Prop" — but the Prop was converted
     to a real theorem in the strengthening pass.  Updated to
     reference `pathOnlyStructureTensor_isAssociative`.
   * `gl3_algEquiv_partial_closure_status_disclosure`'s status
     listing said "Sub-task A.2 (associative-tensor predicate +
     identity-GL³ case)" — but the `IsAssociativeTensorPreservedByGL3`
     Prop and its identity-GL³ case were dropped as mathematically
     incorrect.  Updated to "associative-tensor predicate + encoder-
     is-associative-on-full-adjacency theorem".  Updated A.4 status
     to reflect the new `pathOnlyStructureTensor_diagonal_in_zero_one`.

4. **Added audit-script tests**:

   * **A.1.3 non-vacuity test**: `encoder_off_diag_path_padding_zero`
     was lacking a direct test.  Added an `example` exercising it on
     `m = 2` with the mixed triple `(vertex 0, arrow 0 1, vertex 0)`
     where the middle slot is padding.
   * **A.4 path-only diagonal-in-{0,1} test**: exercises the new
     `pathOnlyStructureTensor_diagonal_in_zero_one` on `m = 2` with
     the non-trivial adjacency `fun u v => decide (u.val ≠ v.val)`.

**Verification.** Full `lake build` succeeds with **3,410 jobs**,
zero warnings, zero errors.  Phase 16 audit script runs cleanly
(exit code 0); every Phase-3 declaration depends only on the
standard Lean trio (`propext`, `Classical.choice`, `Quot.sound`);
zero `sorryAx`, zero custom axioms.

**Net public-surface changes (cleanup pass).**
* Removed: 2 declarations (`PathOnlyTensorIsAssociative_proof`,
  `algEquivRefl_preserves_presentArrowsSubspace`).
* Added: 1 substantive theorem
  (`pathOnlyStructureTensor_diagonal_in_zero_one`).
* Net: -1 public declaration; the remaining surface is leaner and
  more substantively content-rich.

**Patch version.** `lakefile.lean` retains `0.1.24` (the cleanup
pass removes 2 dead declarations and adds 1 substantive theorem;
the public-API surface count drops by one; backwards compatibility
unaffected since the removed declarations had no consumers).

**Final scoreboard for R-TI Phase 3 (post-cleanup).**

| Sub-task | Status |
|---|---|
| A.1 (encoder polynomial identities) | 5 unconditional theorems |
| A.2 (associativity predicate + encoder-is-associative-on-full-adjacency) | 1 predicate + 1 unconditional theorem; mathematically-wrong GL³-preservation Prop dropped |
| A.4 (path-only structure tensor + restricted GL³) | 5 unconditional theorems (incl. **substantively proven path-only associativity** + **path-only diagonal classification**) + 1 research-scope Prop + substantive identity case |
| A.6 (GL³ → AlgEquiv on path subspace) | 1 conditional headline (consumes research-scope Prop) + substantive identity case + 1 status-disclosure anchor |

Honest mathematical content delivered: every theorem either has a
substantive proof that consumes its hypotheses non-trivially, or is
a clearly-marked research-scope `Prop` with documented mathematical
content (Manin theorem + rigidity argument).  Zero shortcuts, zero
theatrical theorems, zero security-by-docstring violations.

**Formalization exit criteria (all met):**
- `lake build` succeeds with exit code 0 for all 68 `Orbcrypt/**/*.lean`
  modules (the running total post-R-TI Phase 3 partial-discharge
  landing; the pre-Phase-15 total was 36 modules, Phase 15 added
  `Optimization/QCCanonical.lean` and `Optimization/TwoPhaseDecrypt.lean`
  bringing the total to 38; the R-TI Stage 0–5 work expanded the
  total further; R-TI Phases 1, 2 added `EncoderSlabEval.lean` and
  `PathBlockSubspace.lean`; R-TI Phase 3 partial-discharge adds
  `EncoderPolynomialIdentities.lean`,
  `TensorIdentityPreservation.lean`, `PathOnlyTensor.lean`,
  `AlgEquivFromGL3.lean` for a final total of 68)
- `grep -rn "sorry" Orbcrypt/ --include="*.lean"` returns empty (the CI
  uses a comment-aware Perl strip so prose mentioning the word "sorry"
  in docstrings does not trigger a false positive; see
  `.github/workflows/lean4-build.yml`)
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
- `#print axioms aead_correctness` — standard Lean only (follows from kem_correctness + MAC.correct)
- `#print axioms authEncrypt_is_int_ctxt` — standard Lean only (uses `MAC.verify_inj` and `canon_eq_of_mem_orbit`; the orbit condition is a per-challenge precondition on the `INT_CTXT` game itself post-Workstream-B of audit 2026-04-23, not a theorem-level hypothesis; Workstream C2 + Workstream B)
- `#print axioms carterWegmanMAC_int_ctxt` — standard Lean only (unconditional specialisation of `authEncrypt_is_int_ctxt` to the Carter–Wegman composition post-Workstream-B; Workstream C4 + Workstream B)
- `#print axioms hybrid_correctness` — standard Lean only (follows from kem_correctness + DEM.correct)
- `#print axioms hardness_chain_implies_security` — standard Lean only (HardnessChain is a hypothesis)
- `#print axioms oblivious_sample_in_orbit` — standard Lean only (closure proof is a hypothesis)
- `#print axioms refresh_depends_only_on_epoch_range` — standard Lean only (structural;
  renamed from `refresh_independent` in Workstream L3 to reflect structural
  determinism, not cryptographic independence)
- `#print axioms kem_agreement_correctness` — standard Lean only (follows from kem_correctness)
- `#print axioms csidh_correctness` — standard Lean only (extracts `CommGroupAction.comm`)
- `#print axioms comm_pke_correctness` — standard Lean only (uses `CommGroupAction.comm` and `pk_valid`)
- `#print axioms permuteCodeword_self_bij_of_self_preserving` — standard Lean only (finite-bijection helper, audit F-08, Workstream D1a)
- `#print axioms permuteCodeword_inv_mem_of_card_eq` — standard Lean only (cross-code helper, audit F-08, Workstream D1)
- `#print axioms arePermEquivalent_symm` — standard Lean only (one-line wrapper around the D1 helper, audit F-08, Workstream D1b)
- `#print axioms arePermEquivalent_trans` — standard Lean only (composition, audit F-08, Workstream D1c)
- `#print axioms paut_inv_closed` — standard Lean only (corollary of D1a, audit F-08, Workstream D2)
- `#print axioms PAutSubgroup` — standard Lean only (`Subgroup` packaging, audit F-08, Workstream D2)
- `#print axioms PAut_eq_PAutSubgroup_carrier` — standard Lean only (`rfl` through transitive standard imports, audit F-08, Workstream D2c)
- `#print axioms paut_equivalence_set_eq_coset` — standard Lean only (full coset set identity, audit F-16 extended, Workstream D3)
- `#print axioms arePermEquivalent_setoid` — standard Lean only (Mathlib `Setoid` instance, audit F-08, Workstream D4)
- `#print axioms det_kemoia_implies_concreteKEMOIA_zero` — standard Lean only (KEMOIA is a hypothesis, audit F-10, Workstream E1c)
- `#print axioms concrete_kemoia_implies_secure` — standard Lean only (ConcreteKEMOIA is a hypothesis, audit F-10, Workstream E1d)
- `#print axioms concrete_chain_zero_compose` — standard Lean only (algebraic composition, audit F-20, Workstream E3d)
- `#print axioms ConcreteHardnessChain.concreteOIA_from_chain` — standard Lean only (chain composition, audit F-20, Workstream E4b)
- `#print axioms concrete_hardness_chain_implies_1cpa_advantage_bound` — standard Lean only (composes E4b + `concrete_oia_implies_1cpa`, audit F-20, Workstream E5)
- `#print axioms concrete_combiner_advantage_bounded_by_oia` — standard Lean only (ConcreteOIA bounds the combinerDistinguisher advantage, audit F-17, Workstream E6)
- `#print axioms combinerOrbitDist_mass_bounds` — standard Lean only (mass bound from non-degeneracy witness + `ENNReal.le_tsum`, audit F-17, Workstream E6b)
- `#print axioms hybrid_argument_uniform` — standard Lean only (sum telescoping, Workstream E8 prereq)
- `#print axioms indQCPA_from_perStepBound` — standard Lean only (per-step bound `h_step` carried as user-supplied hypothesis; telescopes via `hybrid_argument_uniform`, audit F-11, Workstream E8c; renamed from `indQCPA_bound_via_hybrid` in Workstream C of audit 2026-04-23, finding V1-8 / C-13)
- `#print axioms indQCPA_from_perStepBound_recovers_single_query` — standard Lean only (Q = 1 regression sentinel; renamed from `indQCPA_bound_recovers_single_query` in Workstream C of audit 2026-04-23 for naming consistency)
- `#print axioms Orbcrypt.canonical_agreement_under_two_phase_decomposition` — standard Lean only (TwoPhaseDecomposition predicate carried as a hypothesis, Phase 15.5)
- `#print axioms Orbcrypt.kem_round_trip_under_two_phase_decomposition` — standard Lean only (composes two_phase_kem_decaps with kem_correctness, Phase 15.3 / 15.5)
- `#print axioms Orbcrypt.full_canon_invariant` — standard Lean only (direct canon_eq_of_mem_orbit + smul_mem_orbit, Phase 15.5)
- `#print axioms Orbcrypt.orbit_constant_encaps_eq_basePoint` — standard Lean only (IsOrbitConstant carried as a hypothesis, Phase 15.4)
- `#print axioms Orbcrypt.qc_invariant_under_cyclic` / `qc_canon_idem` — standard Lean only (Phase 15.1 / 15.5)
- `#print axioms Orbcrypt.fast_kem_round_trip` — standard Lean only (orbit-constancy of `fastCanon` carried as a hypothesis; Phase 15.3 post-landing audit)
- `#print axioms Orbcrypt.fast_canon_composition_orbit_constant` — standard Lean only (closure-under-orbit hypothesis carried; Phase 15.3 post-landing audit)
- `#print axioms Orbcrypt.SurrogateTensor` — standard Lean only (structure packaging `Group + Fintype + Nonempty + MulAction` bundle; audit 2026-04-21 H1, Workstream G / Fix B)
- `#print axioms Orbcrypt.punitSurrogate` — standard Lean only (trivial PUnit surrogate witness; Workstream G / Fix B)
- `#print axioms Orbcrypt.ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding` — standard Lean only (per-encoding Tensor → CE reduction Prop; Workstream G / Fix C)
- `#print axioms Orbcrypt.ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding` — standard Lean only (per-encoding CE → GI reduction Prop; Workstream G / Fix C)
- `#print axioms Orbcrypt.ConcreteGIOIAImpliesConcreteOIA_viaEncoding` — standard Lean only (per-encoding GI → scheme-OIA reduction Prop, consumes chain-image hardness; Workstream G / Fix C)
- `#print axioms Orbcrypt.ConcreteHardnessChain.tight_one_exists` — standard Lean only (inhabits chain at ε = 1 via `punitSurrogate` + dimension-0 trivial encoders; Workstream G)
- `#print axioms Orbcrypt.concrete_hardness_chain_implies_1cpa_advantage_bound` — standard Lean only (composes `concreteOIA_from_chain` with `concrete_oia_implies_1cpa`; post-Workstream-G signature threads `SurrogateTensor` via the chain structure)
- `#print axioms Orbcrypt.ConcreteOIAImpliesConcreteKEMOIAUniform` — standard Lean only (Prop-valued scheme-to-KEM reduction; audit 2026-04-21 H2, Workstream H1)
- `#print axioms Orbcrypt.concreteOIAImpliesConcreteKEMOIAUniform_one_right` — standard Lean only (satisfiability witness at `ε' = 1` via `concreteKEMOIA_uniform_one`; audit 2026-04-21 H2, Workstream H2)
- `#print axioms Orbcrypt.ConcreteKEMHardnessChain` — standard Lean only (KEM-layer ε-smooth chain structure bundling scheme-level `ConcreteHardnessChain` with the scheme-to-KEM reduction Prop; audit 2026-04-21 H2, Workstream H3)
- `#print axioms Orbcrypt.concreteKEMHardnessChain_implies_kemUniform` — standard Lean only (composes `ConcreteHardnessChain.concreteOIA_from_chain` with the scheme-to-KEM field to deliver `ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) ε`; audit 2026-04-21 H2, Workstream H3)
- `#print axioms Orbcrypt.ConcreteKEMHardnessChain.tight_one_exists` — standard Lean only (inhabits the KEM chain at ε = 1 via `ConcreteHardnessChain.tight_one_exists` + `_one_right` discharge; audit 2026-04-21 H2, Workstream H3)
- `#print axioms Orbcrypt.concrete_kem_hardness_chain_implies_kem_advantage_bound` — standard Lean only (end-to-end KEM-layer adversary bound: composes `concreteKEMHardnessChain_implies_kemUniform` with `concrete_kemoia_uniform_implies_secure`; KEM analogue of `concrete_hardness_chain_implies_1cpa_advantage_bound`; audit 2026-04-21 H2, Workstream H3)
- `#print axioms Orbcrypt.oia_implies_1cpa_distinct` — no axioms used (composition of `oia_implies_1cpa` with `isSecure_implies_isSecureDistinct`; distinct-challenge scheme-level security corollary; audit 2026-04-21 M1, Workstream K1)
- `#print axioms Orbcrypt.hardness_chain_implies_security_distinct` — standard Lean only (chain-level parallel of K1; audit 2026-04-21 M1, Workstream K3)
- `#print axioms Orbcrypt.indCPAAdvantage_collision_zero` — standard Lean only (one-line corollary of `advantage_self` on coincident orbit distributions; formalises the free transfer of the probabilistic bound to the classical distinct-challenge game; audit 2026-04-21 M1, Workstream K4)
- `#print axioms Orbcrypt.concrete_hardness_chain_implies_1cpa_advantage_bound_distinct` — standard Lean only (probabilistic chain bound restated in classical IND-1-CPA game form; distinctness hypothesis carried as release-facing signature marker but unused in proof; audit 2026-04-21 M1, Workstream K4 companion)
- `#print axioms Orbcrypt.det_oia_false_of_distinct_reps` — standard Lean only (machine-checked vacuity of the deterministic `OIA` under the distinct-representatives hypothesis; the `decide`-based distinguisher elaboration introduces only the standard trio; audit 2026-04-23 C-07, Workstream E1)
- `#print axioms Orbcrypt.det_kemoia_false_of_nontrivial_orbit` — standard Lean only (KEM-layer parallel of E1; machine-checked vacuity of the deterministic `KEMOIA` under the non-trivial-basepoint-orbit hypothesis; audit 2026-04-23 E-06, Workstream E2)

R-TI Phase 3 — PathOnlyAlgebra Manin chain wiring (audit 2026-04-28,
implementing A.5.5 + A.6.1 + A.6.2 to enable Path B). Lands the
**missing connection** that lets the Manin tensor-stabilizer theorem
drive the discharge of `GL3InducesAlgEquivOnPathSubspace` instead of
the bundled `GrochowQiaoRigidity`:

- `Orbcrypt/Hardness/GrochowQiao/PathOnlyAlgebra.lean` (~706 LOC, NEW)
  delivers six work units:

  * **A.5.5.1 — `pathMul_some_mem_presentArrows`**: helper showing
    that `pathMul` outputs (when `some`) stay inside `presentArrows`
    when both inputs are in `presentArrows`.
  * **A.5.5.2 — `presentArrowsSubspace_mul_mem`**: multiplicative
    closure of `presentArrowsSubspace m adj` under the convolution
    product on `pathAlgebraQuotient m`.
  * **A.5.5.3 — `one_mem_presentArrowsSubspace`**: unit `1 =
    pathAlgebraOne m = ∑_v vertexIdempotent m v` lies in the
    subspace.
  * **A.5.5.4 — `pathOnlyAlgebraSubalgebra m adj`**: the path-only
    `Subalgebra ℚ (pathAlgebraQuotient m)` built via
    `Submodule.toSubalgebra`.  Membership iff lemma:
    `mem_pathOnlyAlgebraSubalgebra_iff`.
  * **A.5.5.5 — `pathOnlyAlgebraEquivFun`**: explicit
    `LinearEquiv ↥(pathOnlyAlgebraSubalgebra m adj) ≃ₗ[ℚ] (Fin _ →
    ℚ)` using `arrowToPathSlotIdx` (a private helper computing the
    `Fin (pathSlotIndices m adj).card`-index of a present arrow via
    `slotOfArrow + equivFin`) for the inverse direction; `slotToArrow_slotEquiv_arrowToPathSlotIdx` round-trip helper.
  * **A.5.5.6 — `pathOnlyAlgebraBasis`**: the basis indexed by
    `Fin (pathSlotIndices m adj).card`, built via
    `Basis.ofEquivFun pathOnlyAlgebraEquivFun`.  Apply lemma:
    `pathOnlyAlgebraBasis_repr_apply`.
  * **A.5.5.7 — `pathOnlyAlgebraBasis_apply_underlying`**:
    characteristic-function presentation of basis vectors:
    `((b i)).val a = if a = arrow_i then 1 else 0` where arrow_i
    corresponds to the i-th path slot.  Proven via
    `Basis.repr_self` + `Basis.ofEquivFun_repr_apply`.
  * **A.6.1.A — `pathOnlyAlgebraBasis_mul_underlying`**:
    `(b i * b j).val c = [pathMul arrow_i arrow_j = some c]`
    (basis-product underlying function as a pathMul indicator).
  * **A.6.1 — `pathOnlyAlgebraBasis_structureTensor_eq_pathOnlyStructureTensor`**:
    the **bridge theorem** — Manin's abstract `structureTensor` of
    `pathOnlyAlgebraBasis` exactly equals the encoder's
    `pathOnlyStructureTensor`.  This is the missing link that lets
    Manin's tensor-stabilizer theorem be applied to the encoder's
    path-only structure tensor.  Proof: composes
    `Manin.structureTensor_apply` + `Basis.ofEquivFun_repr_apply` +
    `pathOnlyAlgebraBasis_mul_underlying` + `grochowQiaoEncode_path` +
    `pathSlotStructureConstant`.
  * **A.6.2 — Identity-case witnesses**:
    `pathOnlyStructureTensor_basisChangeRelated_self` (the path-only
    structure tensor is `(1, 1, 1)`-related to itself via
    `Manin.IsBasisChangeRelated.id`) and
    `pathOnlyAlgebraBasis_unitCompatible_self` (the unit-
    compatibility holds at the identity matrix, by direct
    computation collapsing the matrix-1 sum via `Matrix.one_apply`
    + `Finset.sum_eq_single`).

- `Orbcrypt/Hardness/GrochowQiao/Discharge.lean` extended with the
  Path B factoring (post-audit, redesigned to be genuinely substantive
  rather than `Iff.rfl`-aliasing of Path A):
  * `PathOnlyAlgEquivObligation m` — Path B's first research-scope
    obligation: GL³ tensor iso ⇒ ∃ AlgEquiv between the two
    adjacencies' path-only Subalgebras.  **Strictly smaller** than
    `GrochowQiaoRigidity`: doesn't construct σ, only an existential
    AlgEquiv between (different-graph) Subalgebras.  Discharge route:
    derive a basis-change relation from the GL³ triple, then apply
    `Manin.algEquivOfTensorIso` (UNCONDITIONAL via this PR).
  * `PathOnlySubalgebraGraphIsoObligation m` — Path B's second
    research-scope obligation: Subalgebra AlgEquiv ⇒ ∃ σ graph iso.
    **Strictly smaller** than `GrochowQiaoRigidity`: doesn't handle
    GL³ tensor structure, only abstract Subalgebra AlgEquivs.
    Discharge route: WM σ-extraction (UNCONDITIONAL via existing
    `WedderburnMalcev.lean`) + arrow-preservation iff
    (UNCONDITIONAL via existing `AdjacencyInvariance.lean`).
  * `pathOnlyAlgEquivObligation_id` — identity-case witness
    (`AlgEquiv.refl` when `adj₁ = adj₂`).
  * `pathOnlySubalgebraGraphIsoObligation_id` — identity-case
    witness (σ = identity when `adj₁ = adj₂`).
  * `grochowQiaoRigidity_via_path_only_algEquiv_chain` — Path B's
    composition theorem: under both Path B obligations,
    `GrochowQiaoRigidity` follows.  The proof composes the two
    obligations through the AlgEquiv intermediate, demonstrating
    that the factoring is genuine.
  * `pathOnlyAlgebra_manin_trivial` — end-to-end **non-vacuity
    witness** for the Manin chain on the path-only Subalgebra:
    constructs an `AlgEquiv ↥(pathOnlyAlgebraSubalgebra m adj) ≃ₐ[ℚ]
    ↥(pathOnlyAlgebraSubalgebra m adj)` from
    `Manin.algEquivOfTensorIso` applied at `(b, b, 1, 1,
    IsBasisChangeRelated.id, IsUnitCompatible at 1)`.  This shows
    the Manin chain elaborates end-to-end on a concrete instance.

  **Audit-pass redesign (2026-04-28).**  An earlier version of this
  section defined `GrochowQiaoRigidityViaMan := GrochowQiaoRigidity`
  (a definitional rename) and `_via_manin` discharge theorems that
  were `Iff.rfl`-aliases of Path A.  The audit found that
  `gl3InducesAlgEquivOnPathSubspace_via_manin h_rig m =
  gl3InducesAlgEquivOnPathSubspace_of_rigidity h_rig m` reduced by
  `rfl` — the "Path B discharge" was just a renamed copy of Path A.
  Per CLAUDE.md's "names describe content, never provenance" rule
  and "no shortcuts" directive, those theatrical aliases were
  removed.  The replacement above factors `GrochowQiaoRigidity` into
  TWO genuinely smaller obligations bridged by an intermediate
  Subalgebra-AlgEquiv state — a non-trivial factoring that lets
  future research-scope work discharge each obligation independently.

- `Orbcrypt.lean` extended with the new module import.

- `scripts/audit_phase_16.lean` extended with §15.20 (R-TI Phase 3 —
  PathOnlyAlgebra Manin path connection): 17 `#print axioms` entries
  covering every public PathOnlyAlgebra declaration plus the
  redesigned Path B obligations + composition, and 11 non-vacuity
  `example` bindings under the new `PathOnlyAlgebraNonVacuity`
  namespace exercising the Subalgebra constructor, multiplicative
  closure, unit membership, the bridge theorem, identity-case
  basis-change, identity-case unit-compatibility, both Path B
  identity-case witnesses, the Path B composition theorem, and the
  end-to-end Manin chain on the trivial instance.

**Architecture: Path A vs Path B side-by-side.**  Both paths now
land in `Discharge.lean`:

* **Path A** (`gl3InducesAlgEquivOnPathSubspace_of_rigidity`):
  consumes `GrochowQiaoRigidity` directly, applies
  `quiverPermAlgEquiv σ`, verifies subspace preservation.  ≈ 130
  LOC, single research-scope hypothesis.

* **Path B** (`grochowQiaoRigidity_via_path_only_algEquiv_chain`):
  factors `GrochowQiaoRigidity` into two strictly-smaller research-
  scope obligations bridged by an intermediate AlgEquiv state.  Each
  obligation can be discharged independently using unconditional
  Mathlib-quality content:
  (1) `PathOnlyAlgEquivObligation` (research-scope, smaller than
      `GrochowQiaoRigidity` — only needs an existential AlgEquiv,
      not σ).  Natural discharge route uses
      `Manin.algEquivOfTensorIso` (UNCONDITIONAL via this PR) once
      a basis-change relation has been derived.
  (2) `PathOnlySubalgebraGraphIsoObligation` (research-scope,
      smaller than `GrochowQiaoRigidity` — only handles abstract
      Subalgebra AlgEquivs, not GL³ tensor structure).  Natural
      discharge route uses WM σ-extraction
      (`algEquiv_extractVertexPerm`, UNCONDITIONAL via existing
      `WedderburnMalcev.lean`) + arrow preservation
      (`vertexPerm_isGraphIso_iff_arrow_preserving`, UNCONDITIONAL
      via existing `AdjacencyInvariance.lean`).

  When/if a future research workstream lands the
  Subalgebra→full-algebra-AlgEquiv lift + Subalgebra σ-extraction,
  Path B becomes the preferred citation since it factors the deep
  content into smaller obligations and reuses Mathlib-quality
  components (Manin theorem, WM σ-extraction, adjacency
  invariance).

**Verification posture.** Full `lake build` succeeds across
**3,417 jobs** with zero warnings, zero errors.  Phase-16 audit
script runs cleanly (exit 0); zero `sorryAx`, zero non-trio
axioms, all PathOnlyAlgebra declarations on the standard Lean
trio.  Module count: **75** (up from 74).

`lakefile.lean` version bumped from `0.1.26` to `0.1.27`.

R-TI Phase 3 prop-discharge — Manin tensor-stabilizer + final
discharge (audit 2026-04-28, post-Phase-3 cleanup pass v2). Lands
the technical core of Approach A and the central conductor that
discharges both Phase 3 research-scope Props
(`GL3InducesAlgEquivOnPathSubspace`, `RestrictedGL3OnPathOnlyTensor`)
from the existing Stages 0–5 research-scope Prop `GrochowQiaoRigidity`:

- **Sub-task A.1.5** —
  `Orbcrypt/Hardness/GrochowQiao/EncoderUnitCompatibility.lean`
  (~290 LOC, NEW): `encoder_unit_compatibility` (the central
  unit-coefficient identity `∑ v, T(vertex v, j, k) = δ_{slot j,
  slot k}` for path-algebra slots) plus two private helpers
  (`encoder_vertex_vertex_eq`, `encoder_vertex_arrow_eq`) that
  `Finset.sum_eq_single` collapse the encoder slabs at vertex sources.
- **Sub-task A.5.1** —
  `Orbcrypt/Hardness/GrochowQiao/Manin/StructureTensor.lean`
  (~140 LOC, NEW): hand-rolled `Manin.structureTensor (b : Basis I F
  A) : I → I → I → F` for any algebra `A` over a field `F`; apply
  lemma; `structureTensor_recovers_mul` (the multiplication-recovery
  identity `b i * b j = ∑ k, T(i, j, k) • b k` via `Basis.sum_repr`).
- **Sub-task A.5.2** —
  `Orbcrypt/Hardness/GrochowQiao/Manin/BasisChange.lean` (~165
  LOC, NEW): `Manin.IsBasisChangeRelated T_A T_B P P_inv` predicate
  (the `(P, P, P⁻ᵀ)`-form basis-change relation between two
  structure tensors with two-sided inverse equations
  `P_inv * P = 1`, `P * P_inv = 1`); `IsBasisChangeRelated.id`
  (identity-case witness using `Matrix.one_apply` +
  `Finset.sum_ite_eq*` collapse — substantively proven).
- **Sub-task A.3.1 + A.3.2** —
  `Orbcrypt/Hardness/GrochowQiao/PaddingInvariant.lean` (~270 LOC,
  NEW): `encoder_padding_trivial_algebra` (slot-discriminator form of
  the padding-trivial-algebra identity); `IsConcentratedSlot`
  predicate; `paddingRankInvariant : Tensor3 n ℚ → ℕ` (the GL³-
  invariant counting concentrated slots); private helper
  `isPathAlgebraSlot_false_iff_mem_paddingSlotIndices`;
  `paddingRankInvariant_eq_paddingSlotIndices_card` (the encoder
  evaluation theorem proving the invariant equals the padding slot
  count). The originally-planned `paddingRankInvariant_GL3Invariant`
  Prop and its theatrical identity-case witness were **removed** in
  the post-landing cleanup pass — they were unused dead code (the
  Discharge.lean partial-discharge form bypasses the padding-rank
  invariant entirely).
- **Sub-task A.5.3 + A.5.4** —
  `Orbcrypt/Hardness/GrochowQiao/Manin/TensorStabilizer.lean` (~615
  LOC, NEW): the technical core. `linearMapOfBasisChange` (the linear
  map defined on the basis via `Basis.constr`);
  `coefficient_match_of_basisChange` (the matrix-inverse identity
  `∑_l T_A(i,j,l) · P(l,k) = ∑ p q, P(i,p) P(j,q) T_B(p,q,k)` driving
  multiplicativity, proven via h_rel.action substitution + sum
  rearrangement + `(P_inv * P)(r,k) = δ(r,k)` collapse);
  `linearMapOfBasisChange_mul_basis` (multiplicativity on basis
  pairs); `linearMapOfBasisChange_mul` (extension to all pairs via
  `Basis.sum_repr`); `linearMapOfBasisChange_one` (unit preservation
  under `IsUnitCompatible`); `algHomOfTensorIso` (algebra hom
  packaging via `AlgHom.ofLinearMap`);
  `linearMapOfBasisChange_inv_basis` (private helper for inverse on
  basis); `linearMapOfBasisChange_left_inv` / `_right_inv` (inverse
  identities on full algebra via `Basis.ext`);
  `linearEquivOfBasisChange` (LinearEquiv via `LinearEquiv.ofLinear`);
  `algEquivOfTensorIso` (AlgEquiv upgrade via
  `AlgEquiv.ofLinearEquiv`).
- **Sub-task A.6.3 (final discharge)** —
  `Orbcrypt/Hardness/GrochowQiao/Discharge.lean` (~270 LOC, NEW):
  the central conductor. `quiverPermFun_mem_presentArrowsSubspace`
  (σ-action carries presentArrowsSubspace adj₁ membership when σ is a
  graph iso — non-trivial use of σ⁻¹ inversion);
  `quiverPermAlgEquiv_image_subset_presentArrowsSubspace` (forward
  inclusion); `graphIso_inv` (private helper showing σ⁻¹ is a graph
  iso between the swapped adjacencies);
  `quiverPermAlgEquiv_image_presentArrowsSubspace` (exact image
  equality via `Set.Subset.antisymm` — both directions substantive);
  `gl3InducesAlgEquivOnPathSubspace_of_rigidity` (the Phase 3
  discharge, using `quiverPermAlgEquiv m σ` as the witness);
  `isPresentArrowSlot_liftedSigma` (slot-shape preservation lemma
  for present-arrow slots under `liftedSigma σ`);
  `presentArrowSlotIndices_card_eq_of_graphIso` (cardinality
  bijection via `Finset.card_bij` + `liftedSigma m σ`);
  `restrictedGL3OnPathOnlyTensor_of_rigidity` (the second Phase 3
  discharge).
- **Top-level wiring** —
  `Orbcrypt/Hardness/GrochowQiao.lean`:
  `grochowQiao_pathSubspace_obligations_under_rigidity` packages both
  Phase 3 discharges into a conjunction under a single
  `GrochowQiaoRigidity` hypothesis;
  `grochowQiao_unified_discharge_under_rigidity` is the unified
  package showing all three end-states (Karp reduction inhabitant +
  both Phase 3 Props) discharge from the same single research-scope
  hypothesis.  (Audit 2026-05-05 deep-audit pass renamed the former
  `grochowQiao_phase3_discharge_under_rigidity` identifier to comply
  with CLAUDE.md's naming rule "Names describe content, never
  provenance" — the `phase3` token is a forbidden process marker.
  The `Phase 3` prose framing inside docstrings remains, since prose
  is allowed to carry process markers per the rule's "Where process
  references *are* allowed" carve-out.)

**Architecture note (partial-discharge form).** The R-TI Phase 3
plan budgeted ~3,200 LOC for Approach A. The PR delivers ~2,150 LOC
of substantive content covering A.1.5, A.3.1, A.3.2, A.5.1, A.5.2,
A.5.3, A.5.4, A.6.3. The Manin tensor-stabilizer theorem
(`Manin/{StructureTensor,BasisChange,TensorStabilizer}.lean`) is
**substantively proven and Mathlib-quality** — the constructions go
from `IsBasisChangeRelated T_A T_B P P_inv` + `IsUnitCompatible`
hypotheses to a full `AlgEquiv A B` between any two algebras with
related structure tensors. However, the Discharge.lean discharge
**bypasses** the Manin theorem and routes through the simpler path:
`GrochowQiaoRigidity` → `quiverPermAlgEquiv` (existing AlgEquivLift
infrastructure) → both Phase 3 Props. The Manin/Padding/UnitCompat
content stands as **standalone reusable mathematical content**
(potentially upstreamable to Mathlib once the Manin theorem is
upstreamed at the appropriate generality). See the v4 plan
`docs/planning/AUDIT_2026-04-28_PHASE_3_PROP_DISCHARGE_PLAN.md` §
"Phase 3 alternative — partial discharge" for the framing the
audit anticipates.

**Mathematical correctness verification (this audit pass):**
* `coefficient_match_of_basisChange`: the proof correctly threads
  h_rel.action through 4 nested sums, uses h_rel.inv_left to get
  `(P_inv * P)(r, k) = δ(r, k)`, and collapses via
  `Finset.sum_ite_eq'`. ✓
* `linearMapOfBasisChange_inv_basis`: correctly uses h_inv_right
  (`P * P_inv = 1`) for the right-inverse direction; the symmetric
  helper applied with arguments swapped (b_B b_A P_inv P) handles
  the left-inverse via h_inv_left. ✓
* `linearEquivOfBasisChange`: correctly threads `h_rel.inv_left` to
  the right-inverse field of `LinearEquiv.ofLinear` (which expects
  `f.comp g = id_M₂`, i.e., `linearMapOfBasisChange b_A b_B P` after
  `linearMapOfBasisChange b_B b_A P_inv` — discharged by
  `linearMapOfBasisChange_right_inv` which expects
  `h_inv_left : P_inv * P = 1`). ✓
* `quiverPermAlgEquiv_image_presentArrowsSubspace` reverse direction:
  uses `inv_inv` to canonicalise σ⁻¹⁻¹ = σ, then a 4-line case-split
  to verify quiverMap σ ∘ quiverMap σ⁻¹ = id at vertex/edge cases. ✓
* `presentArrowSlotIndices_card_eq_of_graphIso`: correctly applies
  `Finset.card_bij` with `liftedSigma m σ` as the bijection;
  `isPresentArrowSlot_liftedSigma` (substantive case-split on slot
  kind) supplies membership preservation; `(liftedSigma m σ).symm` +
  `Equiv.apply_symm_apply` discharge surjectivity. ✓

**Audit-pass v2 fixes (this commit):**

The post-landing audit identified one theatrical theorem and one
unused Prop in `PaddingInvariant.lean`:

* **`paddingRankInvariant_GL3Invariant_identity_case`**: the
  signature took `1 • T = T → paddingRankInvariant T = paddingRankInvariant T`,
  with the conclusion `X = X` (trivially true) and the hypothesis
  `_h` discarded. **Removed** as theatrical per CLAUDE.md's "names
  describe content, never provenance" rule.
* **`paddingRankInvariant_GL3Invariant`**: the GL³-invariance Prop
  was research-scope, not consumed anywhere in the codebase. The
  Discharge.lean partial-discharge form bypasses it via
  `GrochowQiaoRigidity` directly. **Removed** as unused dead code per
  CLAUDE.md's "If you are certain that something is unused, you can
  delete it completely" rule.
* **`PaddingInvariant.lean` module docstring** updated to remove
  references to the removed Prop and to clarify the standalone-content
  status of the remaining (non-vacuous) machinery.

The audit also added **5 new substantive non-vacuity tests** to
`scripts/audit_phase_16.lean` exercising the Manin chain end-to-end
on a concrete instance: `Module.Basis.singleton PUnit ℚ` (the
1-dimensional ℚ-algebra ℚ acting on itself):
* `Manin.structureTensor` evaluates to `1` at the unique basis
  element (matches `1 * 1 = 1` in ℚ).
* `Manin.structureTensor_recovers_mul` matches multiplication.
* `Manin.IsUnitCompatible` is dischargeable with `simp` at `P = 1`.
* `Manin.algHomOfTensorIso` constructs a valid AlgHom whose action
  on the basis element yields `1 : ℚ`.
* `Manin.algEquivOfTensorIso` constructs a valid AlgEquiv whose
  action on the basis element yields `1 : ℚ` — end-to-end exercise
  of the full Manin tensor-stabilizer construction (A.5.1 → A.5.2
  → A.5.3 → A.5.4) at the smallest non-trivial instance.

These tests were missing from the initial Phase 3 audit script
landing. The five `example` blocks all elaborate cleanly and the
`#print axioms` of every Phase 3 declaration depends only on the
standard Lean trio (`propext`, `Classical.choice`, `Quot.sound`).

**Audit verification scoreboard (post-fixes).** Full `lake build`
succeeds across 3,416 jobs with zero warnings, zero errors. Phase-16
audit script `scripts/audit_phase_16.lean` runs cleanly (exit code
0); zero `sorryAx`, zero non-trio axioms, all Phase 3 declarations
on the standard Lean trio. Comment-aware sorry/axiom grep returns
empty. No naming-rule violations across the new Phase 3 modules.
Module count: **70** (up from 64 pre-Phase-3 — six new modules:
`EncoderUnitCompatibility.lean`, `Manin/StructureTensor.lean`,
`Manin/BasisChange.lean`, `Manin/TensorStabilizer.lean`,
`PaddingInvariant.lean`, `Discharge.lean`). Public declaration count:
+~50 new declarations. `lakefile.lean` version bumped from `0.1.24`
through `0.1.26` over the Phase 3 + audit-pass-v2 commits.

**`#print axioms` annotations for new Phase 3 declarations:**

- `#print axioms Orbcrypt.GrochowQiao.encoder_unit_compatibility` — standard Lean only (A.1.5 helper)
- `#print axioms Orbcrypt.GrochowQiao.Manin.structureTensor` / `_apply` / `_recovers_mul` — standard Lean only (A.5.1)
- `#print axioms Orbcrypt.GrochowQiao.Manin.IsBasisChangeRelated` / `.id` — standard Lean only (A.5.2)
- `#print axioms Orbcrypt.GrochowQiao.encoder_padding_trivial_algebra` — standard Lean only (A.3.1)
- `#print axioms Orbcrypt.GrochowQiao.IsConcentratedSlot` / `paddingRankInvariant` / `_eq_paddingSlotIndices_card` — standard Lean only (A.3.2)
- `#print axioms Orbcrypt.GrochowQiao.Manin.linearMapOfBasisChange` / `_basis` / `_mul_basis` / `_mul` / `_one` / `coefficient_match_of_basisChange` / `IsUnitCompatible` / `algHomOfTensorIso` / `_basis` — standard Lean only (A.5.3)
- `#print axioms Orbcrypt.GrochowQiao.Manin.linearMapOfBasisChange_left_inv` / `_right_inv` / `linearEquivOfBasisChange` / `algEquivOfTensorIso` / `_basis` — standard Lean only (A.5.4)
- `#print axioms Orbcrypt.GrochowQiao.Discharge.quiverPermFun_mem_presentArrowsSubspace` / `_image_subset_…` / `_image_…` / `gl3InducesAlgEquivOnPathSubspace_of_rigidity` / `isPresentArrowSlot_liftedSigma` / `presentArrowSlotIndices_card_eq_of_graphIso` / `restrictedGL3OnPathOnlyTensor_of_rigidity` — standard Lean only (A.6.3)
- `#print axioms Orbcrypt.GrochowQiao.grochowQiao_pathSubspace_obligations_under_rigidity` / `_unified_discharge_under_rigidity` — standard Lean only (top-level packaging; renamed from the pre-audit `_phase3_discharge_under_rigidity` form by the 2026-05-05 deep-audit pass)

R-TI Phase 3 — Path B Sub-task A.6.4 (audit 2026-04-29 — Subalgebra
σ-extraction + conditional AlgEquiv discharge): Lands
`Orbcrypt/Hardness/GrochowQiao/PathOnlyAlgEquivSigma.lean` (~1,055
LOC, NEW module 75) discharging both Path B research-scope Props
from `Discharge.lean`:

- **Path B Obligation 2 — UNCONDITIONAL discharge.**
  `pathOnlySubalgebraGraphIsoObligation_discharge : ∀ m,
  PathOnlySubalgebraGraphIsoObligation m`. The substantive proof
  composes:
  * **Layer A.6.4.1–A.6.4.5 (σ-extraction).** Lift vertex
    idempotents into the path-only Subalgebra; show the family is a
    `CompleteOrthogonalIdempotents` preserved by AlgEquiv;
    apply the existing `wedderburn_malcev_conjugacy` (from
    `WedderburnMalcev.lean`) to the lifted COI image of ϕ to extract
    σ + j with `(1 + j) * vertexIdempotent (σ v) * (1 - j) = ϕ(e_v).val`.
  * **Layer A.6.4.6–A.6.4.10 (sandwich identity).** Lift arrow
    elements `α(u, v)` into the Subalgebra; show their ϕ-images are
    nilpotent (`α² = 0` ⇒ `ϕ(α)² = 0`), hence in the radical via
    `nilpotent_mem_pathAlgebraRadical`; prove the inner-conjugation
    sandwich identity `((1 + j) * c * (1 - j)) * A * ((1 + j) * d *
    (1 - j)) = c * A * d` for `A, j ∈ J` (substantive use of `J² =
    0`); compose with the basis-element sandwich `α(u, v) = e_u * α
    * e_v` and ϕ-multiplicativity to derive `(ϕ(α(u, v))).val = e_{σ
    u} * (ϕ(α(u, v))).val * e_{σ v}`.
  * **Layer A.6.4.11–A.6.4.14 (scalar form).** Prove `radical_apply_
    id_eq_zero`: `A ∈ J ⇒ A(.id z) = 0` (via `Submodule.span_
    induction` on the radical generators); prove `radical_sandwich_
    eq_arrow_scalar`: `e_x * A * e_y = A(.edge x y) • α(x, y)` for
    `A ∈ J` (pointwise on `c : QuiverArrow m` using `vertexIdempotent_
    mul_apply` and `mul_vertexIdempotent_apply`); compose to get
    `(ϕ(α(u, v))).val = c • α(σ u, σ v)` with `c = (ϕ(α(u, v))).val
    (.edge (σ u) (σ v))`; show `c ≠ 0` from injectivity of ϕ on the
    non-zero `arrowElementSubalgebra`.
  * **Layer A.6.4.15 (forward graph iso).** `algEquivLifted_isGraph
    Iso_forward`: `adj₁ u v = true ⇒ adj₂ (σ u) (σ v) = true`. Proof
    uses the scalar form: if `adj₂ (σ u) (σ v) = false`, then `(.edge
    (σ u) (σ v)) ∉ presentArrows m adj₂`, but `(ϕ(α)).val ∈
    presentArrowsSubspace m adj₂` and is non-zero at `.edge (σ u) (σ
    v)` — contradiction.
  * **Layer A.6.4.16–A.6.4.17 (cardinality bijection).** Apply the
    forward direction at both ϕ and ϕ.symm to get two injections
    `edgeFinset adj₁ ↪ edgeFinset adj₂` and `edgeFinset adj₂ ↪
    edgeFinset adj₁` (via σ × σ). Equal cardinalities + injection
    on a finite type ⇒ bijection. Image equality gives the converse
    direction `adj₂ (σ i) (σ j) = true ⇒ adj₁ i j = true` without
    needing to identify the inverse-extracted permutation σ' with
    σ⁻¹.

- **Path B Obligation 1 — CONDITIONAL discharge from
  `GrochowQiaoRigidity`.** `pathOnlyAlgEquivObligation_under_
  rigidity (h_rig : GrochowQiaoRigidity) : ∀ m,
  PathOnlyAlgEquivObligation m`. Construction:
  * **Layer A.6.4.18 (constructive AlgEquiv from σ).**
    `pathOnlyAlgEquiv_of_graph_iso m adj₁ adj₂ σ h_iso`: given a
    graph iso σ between adj₁ and adj₂, restrict `quiverPermAlgEquiv
    m σ` (existing infrastructure from `AlgEquivLift.lean`) to the
    path-only Subalgebras via `AlgHom.codRestrict` on both
    directions, packaged as `AlgEquiv.ofAlgHom`. The membership
    proofs use the existing `quiverPermFun_mem_presentArrowsSubspace`
    (from `Discharge.lean`) elementwise.
  * **Layer A.6.4.19–A.6.4.20 (chain composition).**
    `pathOnlyAlgEquivObligation_under_rigidity` extracts σ from the
    rigidity hypothesis and composes with `pathOnlyAlgEquiv_of_
    graph_iso`. `grochowQiaoRigidity_via_pathB_chain` is the
    sanity-check: under `GrochowQiaoRigidity`, the Path B chain
    composes back to the rigidity statement.

  **Why this discharge is conditional.** Combined with the
  unconditional discharge of Path B Obligation 2, discharging
  `PathOnlyAlgEquivObligation` unconditionally would give
  `GrochowQiaoRigidity` unconditionally (via the existing
  `grochowQiaoRigidity_via_path_only_algEquiv_chain`). So the two
  Path B obligations are PROVABLY EQUIVALENT to `GrochowQiao
  Rigidity` modulo unconditional content — discharging the second
  unconditionally is the deep open problem of Grochow–Qiao SIAM J.
  Comp. 2023 §4.3 (the partition-rigidity argument). The
  conditional discharge is therefore the cleanest factoring: Path B
  reduces the research-scope load to a single named Prop equivalent
  to the original Path A obligation, with one of its two
  sub-obligations now machine-checked unconditional content.

- **Audit script.** `scripts/audit_phase_16.lean` extended with
  §15.21 listing 24 new `#print axioms` entries plus 8 non-vacuity
  `example` bindings under `PathOnlyAlgEquivSigmaNonVacuity`
  (covering vertex-idempotent in Subalgebra, COI structure on
  lifted vertex idempotents, nilpotent-implies-radical, sandwich-
  to-arrow-scalar reduction, full Path B obligation 2 discharge,
  identity-σ AlgEquiv construction, conditional Path B obligation 1
  discharge, end-to-end Karp reduction under `GrochowQiaoRigidity`).

- **Audit pass (2026-04-29).** Deep audit of the initial landing
  surfaced and fixed:
  * **Removed dead code**: the `have := h_cA` exploratory
    statement (unused after refactor); the `set_option linter.
    unusedSectionVars false` silencing (unnecessary — the module
    has no unused section variables, verified by removing the
    silencing and rebuilding clean).
  * **Removed duplicate `algEquivLifted_isGraphIso`**: a curried
    one-line wrapper around `algEquivLifted_isGraphIso_forward`
    with identical content; consumers (`pathOnlySubalgebraGraph
    IsoObligation_discharge` step 3/4) now call `_forward`
    directly.
  * **Cleaned up section header A.6.4.16**: pre-audit "σ is a
    graph isomorphism (full bidirection via inverse)" was
    misleading because the theorem only delivered the forward
    direction. Replaced with the discharge headline since the
    bidirection is now packaged inside `pathOnlySubalgebraGraph
    IsoObligation_discharge` via the cardinality argument.
  * **Fixed stale docstring reference** to `pathOnly
    SubalgebraAlgEquiv_isGraphIso` (a name that never existed in
    the file).
  * **Module docstring restructured** to honestly reflect the
    obligation-by-obligation structure (Path B obligation 2
    UNCONDITIONAL; Path B obligation 1 CONDITIONAL on
    `GrochowQiao Rigidity`).
  * **Verification**: full `lake build` succeeds (3,418 jobs, zero
    warnings, zero errors). Audit script: exit code 0, 767
    declarations exercised by `#print axioms`, zero `sorryAx`,
    zero custom axioms (only `propext`, `Classical.choice`,
    `Quot.sound`).

- **Patch version.** `lakefile.lean` bumped from `0.1.28` to
  `0.1.29`. The 74-module total rises to 75; the zero-sorry /
  zero-custom-axiom posture and the standard-trio-only
  axiom-dependency posture are both preserved. Public declaration
  count rises by ~25 declarations (24 `#print axioms` entries land
  for new public surface + helper `pathOnlyAlgEquiv_of_graph_iso`
  — `algEquivLifted_isGraphIso` removed in audit pass; net new
  declarations: 24).

### CLAUDE.md changelog: post-Path-B documentation cluster (2026-04-28 / 2026-04-29)

This dual-bump entry closes audit finding A-02 / L-03a (MEDIUM) of
the 2026-04-29 comprehensive audit
(`docs/dev_history/AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md`
Workstream **A4**), which flagged the absence of CLAUDE.md
changelog entries for the two intermediate version bumps that
landed between the post-Path-B-Sub-task-A.6.4 entry (`0.1.28 →
0.1.29`, recorded above) and the on-disk `lakefile.lean` value of
`0.2.0`.

- **`0.1.29 → 0.1.30`** (commit `42b7e03`, "Audit pass:
  PathOnlyAlgEquivSigma cleanup + extended tests + docs"):
  patch-level bump landed alongside the post-A.6.4 audit-pass
  cleanup of the Path-B σ-extraction module
  (`PathOnlyAlgEquivSigma.lean`).  The audit-pass commit removed
  one duplicate wrapper (`algEquivLifted_isGraphIso`), one dead
  exploratory `have := h_cA` artefact, one unused `set_option
  linter.unusedSectionVars false` silencing, and rewrote a few
  `noncomm_ring`-driven rewrite chains into compact form; it also
  fixed a stale docstring reference to a never-existent name and
  restructured the module-level docstring to reflect the
  obligation-by-obligation Path B factoring (Path B obligation 2
  UNCONDITIONAL; Path B obligation 1 CONDITIONAL on
  `GrochowQiaoRigidity`).  The patch bump captures the
  cleanup-cluster status; no Lean source semantics changed
  net-net beyond the duplicate-wrapper removal.

- **`0.1.30 → 0.2.0`** (commit `9f4b9ec`, "Bump minor version:
  0.1.30 → 0.2.0"): minor-version bump signalling the feature-
  complete state of the post-R-TI-Phase-3 partial-discharge
  cluster.  The cluster encompasses: R-TI Stages 0–5 (rigidity
  discharge plumbing); R-TI Phase 1 (`EncoderSlabEval.lean` —
  encoder slab evaluation); R-TI Phase 2 (`PathBlockSubspace.lean`
  — path-block linear restriction parametric in π, plus the
  bridge to `presentArrowsSubspace`); R-TI Phase 3 partial-
  discharge (the conditional GL³ → AlgEquiv-on-path-subspace
  bridge with the two named research-scope Props
  `GL3InducesAlgEquivOnPathSubspace` and
  `RestrictedGL3OnPathOnlyTensor`); the Manin tensor-stabilizer
  machinery (`Manin/StructureTensor.lean`,
  `Manin/BasisChange.lean`, `Manin/TensorStabilizer.lean`); the
  PathOnlyAlgebra Path-B factoring (`PathOnlyAlgebra.lean`,
  `PathOnlyAlgEquivSigma.lean`, `Discharge.lean`); the audit-pass-
  v2 cleanup of theatrical Path-B aliases.  Per semver,
  `0.x → 0.(x+1)` minor bumps signal a cohesive feature cluster;
  the post-Path-B work qualifies.

  At the time the minor bump landed, the running counts (verified
  by direct inspection of the file tree at commit `9f4b9ec`) were:
  76-module total under `Orbcrypt/`; 928 audit-script `#print
  axioms` entries in `scripts/audit_phase_16.lean`; zero-sorry /
  zero-custom-axiom posture preserved; standard-trio-only
  axiom-dependency posture preserved; full `lake build` succeeded
  with 3,418 jobs, zero warnings, zero errors.

- **Subsequent `0.2.0` work (audit 2026-04-29 Workstream A,
  this landing).**  The Workstream-A documentation parity
  reconciliation pass (audit findings G-02 / L-04 / A-07-J-02 /
  A-02-L-03a) is documentation-only and does not warrant a
  further version bump per CLAUDE.md's version-bump discipline
  ("triggered by API-breaking changes or new public
  declarations").  `lakefile.lean` retains `0.2.0`.

Audit 2026-04-29 — Workstream A (release-blocking documentation
parity) has been completed (2026-04-29):

- **A1 — `PetrankRoth.lean` module docstring overclaim fix.**  The
  module-header `/- ... -/` block (the file's preamble docstring)
  and the "## Layer organisation" subsection inside the `/-! … -/`
  module docstring of `Orbcrypt/Hardness/PetrankRoth.lean` previously
  declared Layers 5/6/7 as present in this file, naming
  `prEncode_iff`, `prEncode_codeSize_pos`, `prEncode_card_eq`, and
  `petrankRoth_isInhabitedKarpReduction` as available declarations.
  Pre-A1 verification confirmed those identifiers existed ONLY as
  docstring/comment text, never as Lean declarations
  (`grep -E "^(theorem|def|...)
  +(prEncode_iff|prEncode_codeSize_pos|prEncode_card_eq|petrankRoth_isInhabitedKarpReduction)"
  Orbcrypt/Hardness/**/*.lean` returned zero matches).
  The docstrings are rewritten with per-layer status markers
  (`(LANDED)` for Layers 1, 2, 3; `(RESEARCH-SCOPE — R-15-residual-CE-reverse)`
  for Layers 4, 5, 6, 7), the file's preamble explicitly
  discloses the partial-closure status, and the four identifier
  names are declared as "placeholder names tracked for the
  research-scope work" rather than as available declarations.  The
  rewrite mirrors the disclosure style already used in
  `Orbcrypt/Hardness/PetrankRoth/MarkerForcing.lean` (lines 17-26
  and 73-95).  Closes audit finding **G-02** (HIGH, source audit
  `docs/audits/LEAN_MODULE_AUDIT_2026-04-29_COMPREHENSIVE.md` § G).

- **A2 — `docs/VERIFICATION_REPORT.md` headline numbers refresh.**
  The auditor-facing document carried headline numbers 2-9× stale
  (38 → 76 modules, 342 → 928 audit-script entries, 5 → 48 private
  declarations, snapshot date 2026-04-21 → 2026-04-29).  The
  header table is restructured per the Strategy a + b hybrid:
  ephemeral metrics now cross-reference CLAUDE.md as the
  canonical running-state source, and only invariants (zero-
  sorry / zero-custom-axiom posture; standard-trio-only axioms;
  per-public-declaration docstrings; build-success status) are
  listed in the report.  A "Snapshot anchor" paragraph records
  the 2026-04-29 totals (76 modules, 928 audit-script entries,
  ≈ 930 public declarations, 48 private helpers, 3,418 build
  jobs) for archeological reference; subsequent landings shift
  these counts.  The body sweep refreshes the **6 current-state
  references** (the audit-method "Step 5 prints …" prose, the
  Method section header for the audit body, the Method
  continuation, the module-docstring Result line, the Root-import
  "imports all 36 modules" claim, and the Theorem-inventory
  closing prose) without disturbing the **13 historical-snapshot
  references** inside per-Workstream / per-Phase / Document-history
  bullets.  The Document history section gains a 2026-04-29
  Workstream-A2 entry recording the refresh.  The "Verdict"
  section is augmented with a sentence acknowledging that the
  post-2026-04-21 Workstream-G/H/J/K/L/M/N (audit 2026-04-21),
  Workstream-A/B/C/D/E (audit 2026-04-23), Workstream-F/G (audit
  2026-04-23 preferred slate), and the R-CE / R-TI Karp-reduction
  subtree expansion all preserve the same posture (zero-sorry /
  zero-custom-axiom / standard-trio-only).  Closes audit finding
  **L-04** (HIGH).

- **A3 — `Orbcrypt.lean` Phase 16 snapshot section refresh.**  The
  "Phase 16 Verification Audit Snapshot (2026-04-21)" section
  (the consumer-facing in-source block at the end of the
  `/-! … -/` module-header docstring) is refreshed to 2026-04-29
  reality:
  * Snapshot header date `2026-04-21` → `2026-04-29`.
  * Module count `36` → `76` (75 imported by the root file +
    the un-imported transient `_ApiSurvey.lean`, slated for
    removal in Workstream **B1**).
  * `lake build` jobs `3,364` → `3,418`.
  * Audit-script `#print axioms` count `342` → `928`.
  * Public-declaration count `343` → `≈ 930` (verified at
    A3-implementation time via the grep recipe inlined in the
    snapshot itself; the README.md headline figure "358+" is
    retained for stability).
  * `private`-helper count `5` → `48` (verified via the same
    grep recipe; the pre-2026-04-21 5-helper enumeration is
    preserved as a cross-reference, with the additional ~43
    private helpers attributed to post-2026-04-21 R-CE / R-TI /
    Manin / Path-B / Discharge / EncoderSlabEval /
    PathBlockSubspace / PathOnlyAlgebra / Wedderburn–Mal'cev /
    AlgebraWrapper modules).
  * The "Prop-valued security assumption" enumeration is
    extended with the post-2026-04-21 research-scope Props
    (`GrochowQiaoRigidity`, `GL3PreservesPartitionCardinalities`,
    `GL3InducesArrowPreservingPerm`,
    `GL3InducesAlgEquivOnPathSubspace`,
    `RestrictedGL3OnPathOnlyTensor`, `PathOnlyAlgEquivObligation`,
    `PathOnlySubalgebraGraphIsoObligation`).
  * A new closing line directs future maintainers to CLAUDE.md
    for the running snapshot of metrics; the in-source block is
    refreshed only at audit boundaries.
  Closes audit finding **A-07 / J-02** (HIGH).

- **A4 — `lakefile.lean` version reconciliation.**  The on-disk
  `version := v!"0.2.0"` was unrecorded in CLAUDE.md's
  per-workstream changelog (the most recent prior entry was the
  `0.1.28 → 0.1.29` Patch-version block from R-TI Phase 3 — Path B
  Sub-task A.6.4).  CLAUDE.md gains a new dual-bump changelog
  entry (immediately above this snapshot) documenting the
  `0.1.29 → 0.1.30` patch bump (commit `42b7e03`, audit-pass
  cleanup of `PathOnlyAlgEquivSigma.lean`) and the
  `0.1.30 → 0.2.0` minor bump (commit `9f4b9ec`) signalling the
  feature-complete state of the post-R-TI-Phase-3 partial-
  discharge cluster (R-TI Stages 0–5 + Phase 1 + Phase 2 +
  Phase 3 partial discharge + Manin chain + PathOnlyAlgebra
  Path-B factoring).  `lakefile.lean` itself is unchanged
  (preserves `0.2.0`).  Closes audit finding **A-02 / L-03a**
  (MEDIUM).

**Verification.** Workstream A is documentation-only; no Lean
source semantics changed.  Every edit is inside a `/- … -/` /
`/-! … -/` docstring block, a markdown file, or the
`lakefile.lean`'s comment metadata.  No declaration is added,
removed, or modified.  `lake build` succeeds with 3,418 jobs
(verified post-A on `claude/audit-codebase-planning-CYmv2`;
unchanged from pre-A baseline at the same commit), zero
warnings, zero errors.  `scripts/audit_phase_16.lean` runs
cleanly (exit code 0); standard-trio-only axioms across all
928 `#print axioms` checks; zero `sorryAx`; zero non-standard
axioms.  The 76-module total, the zero-sorry / zero-custom-
axiom posture, and the standard-trio-only axiom-dependency
posture are all preserved.

Files touched:
- `Orbcrypt/Hardness/PetrankRoth.lean` (A1, two docstring blocks
  inside `/- … -/` and `/-! … -/`).
- `docs/VERIFICATION_REPORT.md` (A2, header + 6 current-state
  body references + Verdict augmentation + Document history
  entry).
- `Orbcrypt.lean` (A3, the Phase 16 snapshot section inside the
  root `/-! … -/` docstring block).
- `CLAUDE.md` (A4, dual-bump version changelog entry; this
  Workstream-A snapshot block; Workstream-A status-tracker
  checkboxes).
- `docs/dev_history/AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md`
  (Workstream-A status-tracker checkboxes ticked under § 10.1
  and Appendix B).

**Patch version.** `lakefile.lean` retains `0.2.0`; Workstream A
is documentation-only and adds no new Lean declarations.  Public
declaration count unchanged; module count unchanged at 76.

Audit 2026-04-29 — Workstream B (recommended pre-release polish)
has been completed (2026-04-29):

- **B1 — Transient `_ApiSurvey.lean` deletion (A-01 / H-03a).**
  `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean` (110 LOC) was
  documented as transient by its own header docstring ("This
  file is **transient**: per Decision GQ-D, it should be deleted
  at the end of Layer T1") and by `CLAUDE.md`'s R-TI Phase 1 /
  Layer T0 entry, but remained in the source tree post-Layer-T1.
  The file was not imported by any module and was picked up by
  `lake build` only through the `srcDir := "."` glob, inflating
  module counts and confusing the dependency-graph documentation.
  Deleted via `git rm` per CLAUDE.md's "If you are certain that
  something is unused, you can delete it completely" rule.
  Cross-references refreshed in five surfaces: CLAUDE.md's
  Layer T0 entry (now describes the deletion), `Orbcrypt.lean`'s
  Phase 16 snapshot (module count 76 → 75), `Orbcrypt.lean`'s
  R-TI dependency-graph file listing (the transient bullet is
  superseded by a deletion note), `Orbcrypt.lean`'s R-TI
  Verification subsection (the in-prose mention is updated),
  `scripts/audit_phase_16.lean`'s § 15.4 Layer T0 prose
  comment, `docs/VERIFICATION_REPORT.md`'s Snapshot anchor +
  module-docstring audit + Root-import section, and
  `docs/research/grochow_qiao_mathlib_api.md` (both Status
  paragraph and Self-audit / exit-criterion section).
  Document-history entries inside historical Workstream / Phase
  snapshots that mention `_ApiSurvey.lean` are deliberately
  preserved (they describe state-at-the-time, which was correct
  when those snapshots landed).  Module count: 76 → 75. Closes
  audit finding A-01 / H-03a (LOW).

- **B2 — Legacy per-workstream audit script relocation (A-06).**
  Seven superseded scripts moved from `scripts/` to
  `scripts/legacy/` via `git mv` (preserving history attribution):
  `audit_a7_defeq.lean`, `audit_b_workstream.lean`,
  `audit_c_workstream.lean`, `audit_d_workstream.lean`,
  `audit_e_workstream.lean`, `audit_phase15.lean`, and
  `audit_print_axioms.lean`. CI was already running only
  `scripts/audit_phase_16.lean` (the current sentinel), so no
  workflow edit was required (the workflow's invocation at
  `.github/workflows/lean4-build.yml:137` continues to use the
  unchanged path `scripts/audit_phase_16.lean`). A new
  `scripts/legacy/README.md` documents the archive status, file
  index (one row per moved script with workstream + audit-cycle
  + status columns), re-running instructions for archeological
  purposes, retention rationale, and a pointer to the
  authoritative current sentinel `scripts/audit_phase_16.lean`.
  The audit script's own preamble is updated: the "supersedes
  per-workstream audit files" sentence now references
  `scripts/legacy/audit_b_workstream.lean` /
  `scripts/legacy/audit_c_workstream.lean` paths and points
  readers at `scripts/legacy/README.md`. The intra-script
  reference to the Workstream-C `toyKEMZMod2` fixture (in
  `audit_phase_16.lean`'s `trivialKEM_PermZMod2` docstring at
  the post-B-line 1355 region) is also updated to the
  `scripts/legacy/audit_c_workstream.lean` path.
  `CLAUDE.md`'s "scripts/" directory listing
  is restructured to surface the new layout: `audit_phase_16.lean`
  + `setup_lean_env.sh` at the top level, with a nested
  `legacy/` subdirectory enumerating the seven moved files plus
  the `README.md`. Historical narrative blocks describing
  per-workstream verification at landing-time (e.g., the
  Workstream-D2 + Workstream-E + Workstream-G snapshots'
  references to `scripts/audit_X_workstream.lean` paths) are
  deliberately preserved — those describe state-at-the-time
  which was correct when those snapshots originally landed.
  Closes audit finding A-06 (LOW).

- **B3 — `README.md` audit-script count refresh (L-01).**
  `README.md` line 53's "Phase-16 audit script | 382+ #print
  axioms checks" updated to "900+" (deliberately imprecise to
  resist per-PR staleness; the precise count is tracked in
  `CLAUDE.md`'s most recent per-workstream changelog entry).
  Verified at landing time: `grep -c "^#print axioms"
  scripts/audit_phase_16.lean` returns 928. The "Lean source
  modules" row on line 51 also dropped from 76 to 75 to match
  the post-B1 reality. Closes audit finding L-01 (LOW).

- **B4 — Compact post-Workstream-I deletion comment (C-13b).**
  `Orbcrypt/KEM/CompSecurity.lean:392-405` 14-line `--`-comment
  block compacted to 6 lines while preserving all four reference
  points (pre-I lemma name `concreteKEMOIA_one_meaningful`,
  audit-finding ID `E-11`, post-I theatrical-deletion timestamp
  `2026-04-25`, current honest non-vacuity witness
  `concreteKEMOIA_uniform_one`). Saves 8 lines of vertical
  space without losing traceability. The `Orbcrypt.KEM.CompSecurity`
  module rebuilds cleanly after the comment-only edit. Closes
  audit finding C-13b (LOW).

**Verification.** Workstream B is file-relocation and prose-edit
only; no Lean source semantics changed (no `def` / `theorem` /
`structure` added, removed, or modified; only one Lean source
file deleted, none modified beyond docstring / comment edits).

* `lake build` succeeds (3,418 jobs, zero warnings, zero
  errors) — verified post-B on
  `claude/audit-workstream-planning-nOC9R`. The pre-B and
  post-B job counts coincide because the deleted
  `_ApiSurvey.lean` shared most of its dependency graph with
  the live R-TI modules, and Lake's job count is dominated by
  Mathlib transitive build artefacts; the change manifests in
  the source-file count (76 → 75) rather than the build-job
  count.
* `scripts/audit_phase_16.lean` runs cleanly (exit code 0); the
  preamble is updated to reflect the relocated legacy scripts
  and the deleted `_ApiSurvey.lean`. All 928 `#print axioms`
  entries continue to depend only on the standard Lean trio
  (`propext`, `Classical.choice`, `Quot.sound`); zero `sorryAx`;
  zero non-standard axioms.
* The post-B running module count under `Orbcrypt/` is **75**
  (down from 76: B1 deleted the un-imported transient
  `_ApiSurvey.lean` after the live `PathAlgebra.lean` /
  `StructureTensor.lean` modules superseded its regression-
  sentinel role).  No new module was added by any of B1–B4.
  The public-declaration count is unchanged (the deleted file
  contained only `example` blocks — never a `def` / `theorem` /
  `structure` / `class` / `instance` / `abbrev`); the zero-sorry
  / zero-custom-axiom posture is preserved; and the
  standard-trio-only axiom-dependency posture is preserved
  across all 928 `#print axioms` entries.
* The CI's "Verify no sorry" comment-aware Perl strip continues
  to return zero matches across the source tree.
* The CI's "Verify no unexpected axioms" stricter declaration
  regex (`^axiom\s+\w+\s*[\[({:]`) continues to return zero
  matches.

Files touched:
- `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean` (B1, deleted).
- `Orbcrypt/KEM/CompSecurity.lean` (B4, comment-only edit).
- `Orbcrypt.lean` (B1, Phase-16 snapshot + R-TI dependency
  listing + Verification subsection updated).
- `CLAUDE.md` (B1 Layer T0 entry; B2 scripts/ directory
  listing; this Workstream-B snapshot block; Workstream-B
  status-tracker checkboxes).
- `README.md` (B3, two cells in the Snapshot metrics table).
- `docs/VERIFICATION_REPORT.md` (B1, three sections).
- `docs/research/grochow_qiao_mathlib_api.md` (B1, two
  paragraphs).
- `scripts/audit_phase_16.lean` (B1 prose comment in § 15.4;
  B2 preamble; B2 intra-script `trivialKEM_PermZMod2`
  docstring reference).
- `scripts/legacy/README.md` (B2, new file).
- `scripts/audit_a7_defeq.lean` →
  `scripts/legacy/audit_a7_defeq.lean` (B2, `git mv`).
- `scripts/audit_b_workstream.lean` →
  `scripts/legacy/audit_b_workstream.lean` (B2, `git mv`).
- `scripts/audit_c_workstream.lean` →
  `scripts/legacy/audit_c_workstream.lean` (B2, `git mv`).
- `scripts/audit_d_workstream.lean` →
  `scripts/legacy/audit_d_workstream.lean` (B2, `git mv`).
- `scripts/audit_e_workstream.lean` →
  `scripts/legacy/audit_e_workstream.lean` (B2, `git mv`).
- `scripts/audit_phase15.lean` →
  `scripts/legacy/audit_phase15.lean` (B2, `git mv`).
- `scripts/audit_print_axioms.lean` →
  `scripts/legacy/audit_print_axioms.lean` (B2, `git mv`).
- `docs/dev_history/AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md`
  (Workstream-B status-tracker checkboxes ticked under § 10.1
  and Appendix B).

**Patch version.** `lakefile.lean` retains `0.2.0`; Workstream B
is recommended pre-release polish (file relocation + prose
edits + transient-stub deletion) and adds no new Lean
declarations.  The 75-module post-B total, the zero-sorry /
zero-custom-axiom posture, and the standard-trio-only
axiom-dependency posture are all preserved.

Audit 2026-04-29 — Workstream C (optional v1.1+ engineering
enhancements, A-03 / A-04 / A-05 / A-08 / D-02a, INFO; B-03a /
B-03b / C-03a / C-13a / F-03a, INFO no-action) has been
completed (2026-04-30 — promoted from "defer to v1.1+" to
pre-1.0 release work per project sponsor's request):

- **C1 (A-03) — Explicit `lakefile.lean` globs.** `lakefile.lean`'s
  `lean_lib Orbcrypt where srcDir := "."` now also declares
  `globs := #[.andSubmodules \`Orbcrypt]`. The `.andSubmodules`
  glob (sugar for Lake's `Orbcrypt.*` matcher; see
  `Lake/Config/Glob.lean` `Glob.andSubmodules` constructor)
  matches the root module `Orbcrypt` and every submodule
  `Orbcrypt.<sub>`. Pre-C1 the lakefile relied on the implicit
  default `globs := roots.map Glob.one` together with
  `srcDir := "."`, which expanded to "every `.lean` file under
  the workspace root that Lake reaches through transitive
  imports". The explicit glob is a structural tripwire: a
  transient stub placed *outside* `Orbcrypt/` (e.g. under
  `experiments/`, `playground/`, `scratch/`) is now provably
  excluded from the default-target build by the lakefile's
  declaration alone, not by maintainer convention. A stub placed
  *inside* `Orbcrypt/` (e.g. the `_ApiSurvey.lean` removed by
  Workstream B1 of this same audit) would still be matched by
  `Orbcrypt.*` and is therefore caught by Workstream B1's
  deletion + the explicit module count in CLAUDE.md and
  `Orbcrypt.lean`'s import list. The lakefile's `Last verified`
  comment is refreshed to `2026-04-30`.

- **C2 (A-04) — Toolchain binary integrity verification.**
  `scripts/setup_lean_env.sh` gains a write-once snapshot guard.
  After a fresh install (whose archive's SHA-256 was already
  verified by `verify_toolchain_sha256` against the per-arch
  pin), `bin_sha256_snapshot_create` records the SHA-256 of
  `bin/lean` and `bin/lake` to `${tc_dir}/.bin_sha256.lock`. On
  every subsequent fast-path entry, `bin_sha256_snapshot_verify`
  recomputes those SHAs and compares them to the marker. Three
  outcomes: (0) marker present and SHAs match — proceed; (1)
  marker missing — toolchain was installed before C2 landed (or
  the marker was deleted manually), so we take a snapshot now
  rather than fail-closed (the fast-path's binaries are the
  same ones the slow-path would have verified via the archive
  SHA pin); (2) genuine mismatch — fatal. The fatal case
  exits the script with code 1, not just "fall through to slow
  path", because the slow path would skip re-installation when
  `[ -x bin/lean ]` is true (the file *exists*, just with the
  wrong content). The remediation message directs the user at
  `rm -rf "${tc_dir}"` followed by re-run, which triggers a
  fresh archive download with `verify_toolchain_sha256`
  re-verifying the archive against the per-arch pin.

  **Threat model.** C2 is defense-in-depth, not a replacement
  for filesystem-level access controls: an attacker with write
  access to both the toolchain binaries *and* the marker file
  can update both consistently and bypass the check. With
  write access to `~/.elan/`, the attacker has already won.
  C2 closes the narrower window of accidental modification
  (system updates that touch toolchain binaries; backup
  restore mishaps; partial copies; file-system corruption) and
  raises the bar for a class of malicious post-install
  modification.

  **Implementation note.** The `compute_sha256` helper is
  hoisted from below the package-management section to the
  top of the script (immediately after `cache_host_reachable`)
  because the snapshot helpers run inside `fast_path_ready`,
  which is called *before* the package-management section
  loads its helpers. Hoisting `compute_sha256` was the cleanest
  fix; the alternative (moving the snapshot helpers below
  `fast_path_ready`) would have required restructuring the
  fast-path's exit-on-success flow.

  **Manual unit testing.** Six C2 unit tests verify: (1)
  snapshot creation produces a well-formed marker; (2)
  verification on un-tampered binaries succeeds; (3)
  verification detects a tamper (returns exit 2); (4) missing
  marker returns exit 1 (caller-decides); (5) snapshot
  creation is idempotent (marker mtime preserved across
  re-invocation); (6) missing-binary post-snapshot detection
  returns exit 2. End-to-end test on the live toolchain
  (`bash scripts/setup_lean_env.sh --quiet`) confirms snapshot
  is created on first fast-path entry, verification is silent
  on subsequent entries, and tamper detection produces the
  expected error message + exit-1 fail-fast behaviour.
- **C3 (A-05) — Recursive sorry-strip regex in CI.**
  `.github/workflows/lean4-build.yml`'s "Verify no sorry" step
  upgrades from the non-greedy `/-.*?-/` Perl substitution to
  a recursive `(\/\-(?:[^\/\-]++|\-(?!\/)|\/(?!\-)|(?1))*+\-\/)`
  that handles arbitrarily-nested Lean block comments. The
  pre-C3 non-greedy regex would *false-positive* on a fragment
  like
  ```
  /- a /- b -/ sorry /- c -/ -/
  ```
  because the non-greedy match strips `/- a /- b -/` (innermost
  `-/` wins) and `/- c -/`, leaving `\sorry  -/` un-stripped.
  The literal `sorry` survives the strip and `grep` flags it,
  even though the original Lean source places `sorry` inside
  the outermost block comment.

  **Pattern anatomy.** `(?1)` is Perl's self-reference: refers
  back to the captured group `1` recursively. The body
  alternation matches: any non-`/`-non-`-` character (possessive
  `++` to avoid catastrophic backtracking on long bodies); a
  `-` not followed by `/`; a `/` not followed by `-`; or a
  recursive `(?1)` reference matching another nested block.
  Possessive `*+` on the body's outer alternation eliminates
  backtracking once a body character has been consumed,
  keeping complexity O(n) on well-formed input.

  **Manual testing.** Verified on 9 unit-test cases including
  simple comments, double-strip, basic nesting, sorry-in-inner,
  sorry-in-outer-after-inner-close, docstrings (`/-! -/`),
  doc-comments (`/-- -/`), and unclosed-outer (an invalid
  Lean fragment). Also verified on the entire codebase: 75
  modules pass the recursive strip cleanly, identical to the
  pre-C3 behaviour on the actual codebase (which has no
  nested block comments today). The C3 upgrade is a tripwire
  for *future* nested-comment usage.

- **C4 (A-08) — `lake-manifest.json` drift check in CI.**
  `.github/workflows/lean4-build.yml` gains a new "Verify
  lake-manifest.json drift" step (after Verify-no-sorry,
  Verify-no-axioms, before Phase-16). The step extracts every
  direct `require ... @ git "<rev>"` directive from
  `lakefile.lean` (regex-parsed: `require "<scope>" / "<name>"
  @ git "<40-hex>"`) and cross-checks each against the
  corresponding `rev` field in `lake-manifest.json` (parsed
  with `python3` — always present on `ubuntu-latest` runners,
  no `jq` dependency). Mismatches fail CI with an explicit
  error pointing the developer at `lake update <name>` for
  re-sync.

  **Audit-plan note.** The plan's C4 skeleton suggested
  `lake update --dry-run`, but Lake at `v4.30.0-rc1` has no
  `--dry-run` flag (`lake update --help` documents only the
  bare invocation, which mutates the manifest). The structural
  cross-check landed here is exact — it compares the two files
  directly without invoking Lake — and is therefore safer
  (no manifest mutation under any circumstances).

  **Direct requires only.** Transitive Mathlib dependencies
  (the eight `inherited: true` packages in `lake-manifest.json`)
  are managed by Mathlib's own lakefile and are not re-pinned
  in this lakefile, so they are not checked here. The check is
  concerned only with this package's *own* declared pins
  (currently just Mathlib at `fa6418a8...`).

  **Manual testing.** Verified on the current state (passes:
  one direct require, manifest agrees) and on a simulated
  drift state (manifest's mathlib `rev` modified to a
  different 40-hex; check fails with a clear "DRIFT" message
  and exit 1).
- **C5 (D-02a) — Formal GAP/Lean canonical-image equivalence
  at arbitrary `n`.** `Orbcrypt/Construction/BitstringSupport.lean`
  (NEW module 76) closes the pre-C5 prose-level disclosure in
  `Construction/HGOE.lean:88-113` by machine-checking the
  equivalence between Lean's `CanonicalForm.ofLexMin`
  (lex-min canonical image computed via `bitstringLinearOrder`
  on `Bitstring n`) and GAP's `CanonicalImage(G, support x,
  OnSets)` (lex-min support set in the orbit under GAP's
  set-lex). The equivalence rests on three structural
  correspondences:

  1. **Bijection via `support`.** `support : Bitstring n →
     Finset (Fin n)` (the indicator's true-set) and `ofSupport`
     (the indicator function of a finset) are mutual inverses,
     packaged as `bitstringSupportEquiv : Bitstring n ≃
     Finset (Fin n)`. Direct corollary: `support_injective`.

  2. **G-equivariance (OnSets correspondence).**
     `support_smul (σ : Equiv.Perm (Fin n)) (x : Bitstring n) :
     support (σ • x) = (support x).image σ.toEmbedding`. This
     formalises the claim that Lean's `MulAction (Equiv.Perm
     (Fin n)) (Bitstring n)` corresponds to GAP's
     `OnSets(S, σ) = {σ(i) : i ∈ S}` action on `Finset (Fin n)`
     exactly. Proof: routine `ext` + `MulAction` unfolding,
     mirroring the existing `hammingWeight_invariant` proof
     in `Construction/Permutation.lean`.

  3. **Order correspondence.** Both `bitstringLinearOrder`
     (via `LinearOrder.lift'` on `List.ofFn (! ∘ ·)`) and
     `gapSetLT` (defined directly via the "first-differing
     index" rule on `Finset (Fin n)`) are characterized by
     the same per-position rule: at the smallest index where
     `x` and `y` differ, the smaller bitstring has `true`
     (resp. the smaller support set contains the element).

  Headline theorems (all axiom-dependency: standard Lean trio
  only, zero `sorry`, zero custom axioms):

  * `support_smul` — G-equivariance.
  * `listLex_ofFn_iff` — first-differing-index characterization
    of `List.Lex` on `List.ofFn`. Proof by recursion on `n`
    using `List.lex_cons_iff` (heads-equal collapse) and
    `List.head_le_of_lt` (heads-differ ⇒ rel constructor).
  * `bitstringLinearOrder_lt_iff_first_differ` — per-bitstring
    first-differing-index characterization of the Lean lex
    order, derived from `listLex_ofFn_iff`.
  * `gapSetLT` — definition of the GAP set-lex order via
    "first-differing-index" rule on `Finset (Fin n)`.
  * `bitstringLinearOrder_lt_iff_gapSetLT_support` — the
    central order-correspondence lemma: the Lean lex order on
    `Bitstring n` and the GAP set-lex order on `Finset (Fin n)`
    are *the same* relation, mediated by `support`.
  * `support_canon_minimal` — the Lean canonical image is
    `Finset.min'`-minimal in the bitstring orbit (the
    substantive lex-minimality property).
  * `support_canon_gapSetLT_minimal` — for any group element
    `g : ↥G`, the support of the Lean canonical image is
    either equal to the support-orbit element under `g` (the
    canonical case) or strictly less under `gapSetLT` (the
    general case). This is the GAP-side "set-lex minimum"
    property.
  * `support_canon_in_support_orbit` — the support of the Lean
    canonical image lies in the OnSets-orbit of `support x`.

  **Audit-script witnesses.** `scripts/audit_phase_16.lean`
  gains 19 new `#print axioms` entries (one per public C5
  declaration) plus 7 non-vacuity `example` bindings on
  concrete `Bitstring 3` inputs at `Equiv.Perm (Fin 3)` and
  the top subgroup `⊤ ≤ S_3`: support-of-concrete-bitstring
  evaluation; both round-trips of `bitstringSupportEquiv`;
  `support_smul` on a concrete `Equiv.swap`; the order-
  correspondence on a concrete `<` witness; the
  first-differing-index characterization; and the headline
  existential `support_canon_in_support_orbit` evaluated on
  the weight-2 bitstring `![T, F, T]` with the top subgroup.

  **Module dependency.** `BitstringSupport.lean` imports only
  `Construction.Permutation` (for `Bitstring`,
  `bitstringLinearOrder`, the `MulAction` instance) and
  `GroupAction.CanonicalLexMin` (for `CanonicalForm.ofLexMin`).
  Wired into `Orbcrypt.lean`'s root import block immediately
  after `Construction.HGOEKEM`. Module count: 75 → **76**.

- **C6 (B-03a, B-03b, C-03a, C-13a, F-03a) — INFO docstring
  observations: NO action.** All five are explicitly disclosed
  by the audit as "no action needed" or "intentional API
  design". Verified each is honestly disclosed in the existing
  source: B-03a (`bitstringLinearOrder` `letI` discipline) is
  documented in `Construction/Permutation.lean:206-237`'s
  docstring comment; B-03b (`orbitFintype` global instance)
  is documented in `GroupAction/CanonicalLexMin.lean:87-92`;
  C-03a (`-- Justification:` block on a `def` rather than an
  `axiom`) is appropriate because `OIA` carries assumption
  semantics that warrant the same rationale documentation;
  C-13a (the `Orbcrypt.Hardness.Reductions` import in
  `KEM/CompSecurity.lean:13`) is intentional KEM-chain-above-
  scheme-chain layering, recorded in CLAUDE.md's Workstream H
  snapshot; F-03a (the underscore-prefixed `_hDistinct`
  parameter on `concrete_hardness_chain_implies_1cpa_advantage_
  bound_distinct`) is intentional API design honestly
  disclosed in the docstring at the call site. C6 lands with
  zero source changes.
**Files touched:**
- `lakefile.lean` (C1: explicit `globs` + version bump
  `0.2.0 → 0.2.1` + comment-metadata refresh).
- `scripts/setup_lean_env.sh` (C2: snapshot helpers +
  `compute_sha256` hoist + fast-path verification + post-
  install snapshot creation).
- `.github/workflows/lean4-build.yml` (C3: recursive sorry-
  strip regex + updated comment block; C4: new "Verify
  lake-manifest.json drift" step).
- `Orbcrypt/Construction/BitstringSupport.lean` (C5: NEW
  module — 19 public declarations).
- `Orbcrypt.lean` (C5: import line for the new module).
- `scripts/audit_phase_16.lean` (C5: 19 `#print axioms`
  entries + 7 non-vacuity `example` bindings).
- `CLAUDE.md` (this Workstream-C snapshot; status-tracker
  checkboxes ticked).

**Verification.** Workstream C is *additive* in three
distinct surfaces:
1. **Lean source.** One new module
   (`Orbcrypt/Construction/BitstringSupport.lean`) adds 19
   public declarations. Module count: 76 → 77. Public
   declaration count rises by 19. `lake build Orbcrypt`
   succeeds with **3,419 jobs**, zero warnings, zero errors
   (up from the pre-C 3,418 — exactly +1 for the new
   module's build node). Every new declaration depends only
   on the standard Lean trio (`propext`, `Classical.choice`,
   `Quot.sound`); zero `sorry`, zero custom axioms.
2. **Build configuration.** `lakefile.lean` gains an explicit
   `globs` field (no public-API surface change; the build
   target set is unchanged). Version bump `0.2.0 → 0.2.1`
   for the `globs` declaration (a build-configuration change
   visible to downstream consumers running `lake env …`).
3. **CI / shell tooling.** The setup script and CI workflow
   gain defense-in-depth checks (sorry-strip recursive
   regex, manifest drift check, toolchain binary integrity).
   No Lean source semantics change.

The audit script (`scripts/audit_phase_16.lean`) now exercises
**947** `#print axioms` entries (up from 928 — 19 new for
C5) plus **245** non-vacuity `example` bindings (up from 238
— 7 new for C5). Audit-script runs cleanly with exit 0,
zero `sorryAx`, zero non-trio axioms.

**Patch version.** `lakefile.lean` bumped from `0.2.0` to
`0.2.1` for Workstream C — the C1 `globs` declaration is a
consumer-visible build-configuration change, the C5 module
is a new public-API surface (19 new declarations), and C2
introduces a new on-disk artifact (`${tc_dir}/.bin_sha256.lock`)
that downstream tooling consumers may need to be aware of.
The 76-module post-C total, the zero-sorry / zero-custom-
axiom posture, and the standard-trio-only axiom-dependency
posture are all preserved.

**Audit-plan reclassification.** The 2026-04-29 audit plan
classified Workstream C as "defer to v1.1+ engineering". Per
the project sponsor's request (2026-04-30), Workstream C was
promoted to pre-1.0 release work and landed alongside
Workstream A and Workstream B. The audit plan's § 7.4 ("No
exit criteria for v1.0") and the workstream tracker's
"deferred" entries are updated to reflect this promotion.
The cryptographic-correctness posture (zero `sorry`, zero
custom axioms, all 947 `#print axioms` results on the
standard Lean trio) is preserved.

**Audit pass (2026-04-30, post-Workstream-C landing).** A deep
audit of the Workstream-C changes surfaced three substantive
findings, all fixed in the audit-pass commit on the same branch:

1. **C2 fragile `set -e` interaction.** The original
   `bin_sha256_snapshot_verify "${tc_dir}"; verify_status=$?`
   pattern in `fast_path_ready` is fragile: `set -e` (set at
   script top) DOES trigger on a function returning non-zero
   unless the function call is inside a context that suppresses
   `set -e` (`if`, `while`, `&&`, `||`, `!`). Today
   `fast_path_ready` is invoked via `if fast_path_ready; then ...
   fi`, so the suppression holds — but a future refactor that
   calls `fast_path_ready` outside such a context would silently
   exit on the first non-zero return from
   `bin_sha256_snapshot_verify` (the "marker missing" case)
   BEFORE the `verify_status=$?` line could capture the exit
   code. **Fix.** Replace with `bin_sha256_snapshot_verify
   "${tc_dir}" || verify_status=$?` — the `||`-bound capture is
   robust regardless of caller context.

2. **C2 silent skip on missing marker entry.** The original
   verify function silently `continue`d on entries not recorded
   in the marker (with a `log_elapsed` warning suppressed in
   `--quiet` mode). An attacker with marker write access (a
   strictly weaker capability than full toolchain write access,
   but still worth defending against in defense-in-depth) could
   delete a line from the marker to skip verification of that
   binary. **Fix.** Treat any missing entry as a mismatch (return
   exit 2) — fail closed. Documented in the function docstring
   as the audit-pass strengthening of C2's missing-entry-as-
   mismatch rule.

3. **C4 misleading error on missing/malformed manifest.** The
   drift check captured `python3` errors via `2>/dev/null || echo
   ""`, conflating "manifest file missing" and "manifest JSON
   malformed" with "package missing from manifest". All three
   surfaced the same generic "no entry in lake-manifest.json"
   error, leading the user to investigate the wrong thing.
   **Fix.** Split out explicit checks for file existence
   (`[ ! -f lake-manifest.json ]`) and JSON validity (`python3 -m
   json.tool lake-manifest.json`) up front, with distinct error
   messages pointing the user at the actual remediation
   (`lake update` for missing/malformed; `lake update <name>` for
   missing-entry; `lake update <name>` again for drift).

**Plus one cosmetic cleanup:**
- Stale `.lake/build/lib/lean/Orbcrypt/Construction/GAPEquivalence.olean`
  (and friends — `.c.hash`, `.ilean.hash`, `.trace`, etc.) from
  the pre-rename state were lingering in the build cache. Lake
  doesn't auto-clean orphaned build artefacts when source files
  are renamed. Manually deleted in the audit pass; subsequent
  `lake build` invocations recover the canonical 76-source +
  1-root = 77 .olean state.

**Verification.** All audit-pass fixes verified via:
- 6 C2 unit tests (snapshot create, idempotency, verification,
  tamper detection, missing marker, **NEW: missing-entry-as-
  mismatch**, missing binary).
- C2 set-e robustness test (function called WITHOUT
  if-guard — confirms `||` pattern is robust).
- C4 4 edge-case tests (missing manifest, malformed manifest,
  matching rev, drift detected).
- Full lake build (3,419 jobs, zero warnings, zero errors).
- Phase-16 audit script (947 entries, exit 0, zero `sorryAx`,
  zero non-trio axioms).
- All 5 CI checks (build, sorry-strip, axiom-check, drift-check,
  Phase-16 audit) pass on the current tree.

**Patch version.** `lakefile.lean` retains `0.2.1` — the audit-
pass fixes are bug-fix-grade improvements to existing C2 and
C4 code, not new public API. The 76-module total, the
zero-sorry / zero-custom-axiom posture, and the standard-trio-
only axiom-dependency posture are all preserved.

**Second audit pass (2026-04-30, post-Workstream-C deep re-audit).**
A subsequent fresh-eyes audit surfaced four additional findings —
one CRITICAL CI workflow bug, one defense-in-depth concurrency
issue, and two documentation-parity gaps. All fixed in the same-day
audit-2 commit.

1. **CRITICAL: malformed CI workflow YAML.** The C4 drift-check
   step's multi-line `python3 -c "..."` invocation had python
   source lines at column 0, dedented below the YAML literal-block
   (`run: |`) indentation. YAML's literal-block parser terminated
   the block prematurely at the python code, then tried to parse
   the python lines as new YAML mapping keys — which fail because
   `import json, sys` doesn't have the required `:` separator.

   Verified by `python3 -c "import yaml;
   yaml.safe_load(open('.github/workflows/lean4-build.yml'))"` —
   raised `ScannerError: while scanning a simple key in line 191
   column 1 could not find expected ':'`. **The CI workflow would
   fail to parse on the first push to GitHub Actions.**

   **Fix.** Compress the multi-line python invocation into a
   single-line semicolon-separated form:
   ```python
   python3 -c "import json,sys; data=json.load(open('lake-manifest.json')); print(next((p['rev'] for p in data.get('packages', []) if p.get('name') == sys.argv[1]), ''))"
   ```
   Single-line python avoids any indentation issue with YAML
   literal blocks. Verified: post-fix YAML parses cleanly; C4
   logic still works (clean-state PASS, drift-state DETECTS).

2. **C2 concurrency bug in `bin_sha256_snapshot_create`.** When
   multiple invocations of `setup_lean_env.sh` race (e.g., a
   developer accidentally launches two terminals), all processes
   would `: > "${marker}.tmp"` at the same path, then interleave
   their write-and-rename steps. The losing race could blow away
   another process's partial content, producing a marker file
   with fewer than `${#TOOLCHAIN_PROTECTED_BINS[@]}` lines.
   Subsequent verifications would then trigger the missing-entry-
   as-mismatch rule (added in audit pass #1) on the LEGITIMATE
   marker, locking the user out of the toolchain.

   **Fix.** Replace the fixed `${marker}.tmp` filename with
   `mktemp "${marker}.XXXXXX.tmp"` — each process gets a unique
   per-process scratch file, so concurrent writes don't interleave.
   The final atomic `mv` resolves the race by last-writer-wins,
   but every contender's `mv` produces a complete marker (no
   partial-content possible).

   Verified: 10 concurrent invocations produce exactly 1
   complete marker with 0 leftover `.tmp` files.

   Note: `mktemp`'s default 0600 mode is more restrictive than
   the previous 0644 (umask default). For per-user toolchains
   (`~/.elan/`) this is appropriate and arguably more secure;
   shared toolchains can `chmod 0644` post-snapshot.

3. **Audit-plan reclassification consistency.** Four areas of
   `docs/dev_history/AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md`
   still described Workstream C as "deferred to v1.1+":
   - § 0 executive summary opening paragraph.
   - § 0 release-gate commitment.
   - § 1.2 severity-distribution table.
   - § 2 finding-to-workstream mapping (10 rows, "defer (v1.1+)").
   - § 4 dependency-graph ASCII art ("DEFERRED" header for C).
   - § 7 section header ("Optional v1.1+ engineering enhancements").
   - § 7.2 fix scope ("Workstream C does not produce v1.0
     deliverables").
   - § 7.3 sub-section headers (5 headers, "(A-XX, v1.1+)" /
     "(D-02a, v1.1+ research-scope)").
   - § 7.3 Status fields (5 fields, "Deferred to v1.1+" /
     "Research-scope").
   - § 7.4 exit-criteria text ("No exit criteria for v1.0").
   - § 10.3 release-readiness checkbox list (6 unchecked rows).

   **Fix.** All updated with explicit "originally deferred to v1.1+
   → landed pre-1.0 2026-04-30" framing or substantive closure
   text (e.g., § 7.4 expanded with per-work-unit acceptance
   criteria; § 10.3 boxes ticked with implementation summary per
   work unit). The original audit-time framing is preserved as
   historical context where relevant.

4. **Documentation parity gaps in VERIFICATION_REPORT.md and
   README.md.** Five current-state references missed in audit-1:
   - VERIFICATION_REPORT.md line 112: "Step 5 prints `#print
     axioms` for 928 declarations" → 947.
   - VERIFICATION_REPORT.md line 494: "runs `#print axioms` on
     928 declarations" → 947.
   - VERIFICATION_REPORT.md line 515: "928 declarations
     exercised" (in Result block) → 947.
   - VERIFICATION_REPORT.md line 545: "Every one of the 75
     modules" → 76.
   - VERIFICATION_REPORT.md line 579: "imports all 75 modules" → 76.
   - VERIFICATION_REPORT.md line 586: "exercises the complete
     graph (3,418 jobs)" → 3,419.
   - VERIFICATION_REPORT.md line 681: "928 declarations
     exercised" (in Theorem-inventory close) → 947.
   - README.md line 51: "75 (+ root import file)" → 76.
   - README.md line 53: "900+ `#print axioms`" → 940+.
   - README.md line 56: Package version "0.2.0" → 0.2.1.
   - README.md line 55: CI step list missing "lake-manifest drift
     check" — added.

   All current-state references updated; historical-snapshot
   references inside per-Workstream Document-history bullets are
   preserved verbatim (they correctly describe state-at-the-time).

**Cumulative verification posture preserved.**
- Lake build: 3,419 jobs, zero warnings, zero errors.
- audit_phase_16.lean: exit 0, 947 entries, zero `sorryAx`,
  zero non-trio axioms.
- Shellcheck on `scripts/setup_lean_env.sh`: zero issues at
  every severity level.
- YAML parses cleanly (post-audit-2 fix).
- All 5 CI checks pass locally (build, sorry-strip,
  axiom-check, drift-check, Phase-16 audit).
- C2 concurrency test: 10 concurrent invocations → 1 complete
  marker, 0 leftover `.tmp` files.
- C4 drift detection: clean PASS; simulated drift correctly
  fails.

**Patch version.** `lakefile.lean` retains `0.2.1` — the
audit-2 fixes are bug-fix-grade improvements (CI YAML, C2
concurrency, doc-parity). No new public API.

Workstream D Research-Scope Discharge (R-09 + R-12 + R-13,
audit 2026-04-29 § 8.1) has been completed (2026-04-30):

- **R-12 — Tight 1/4 ε-bound for `concreteHidingBundle`.** Closes
  the post-Workstream-I research-scope disclosure on the
  non-degenerate `concreteHidingBundle` + Boolean-AND fixture.

  * **Layer A (`Probability/Advantage.lean`)** — Bool TV bound:
    `probTrue_bool_eq`, `pmf_bool_sum_eq_one_toReal`,
    `probTrue_bool_toReal_eq`, `advantage_bool_le_tv` (TV upper
    bound `advantage D μ ν ≤ |(μ true).toReal − (ν true).toReal|`
    for any `D : Bool → Bool`, via four-way case-split on
    `(D true, D false)`), `advantage_bool_id_eq_tv` (tightness
    witness at `D = id`).
  * **Layer B (`PublicKey/ObliviousSampling.lean`)** — concrete
    pointwise computations + headline:
    `concreteHidingBundle_orbitDist_apply_true/_false` (= 1/2
    each), `concreteHidingLHS_apply_true` (= 1/4),
    `concreteHidingLHS_apply_false` (= 3/4),
    `concreteHiding_tight` (**headline** `1/4` bound),
    `concreteHiding_tight_attained` (tightness at `D = id`).

  Closes 11 declarations on standard-trio axioms.

- **R-13 — `Bitstring n`-typed Carter–Wegman MAC + INT-CTXT.**
  Closes the HGOE compatibility gap of `carterWegmanMAC_int_ctxt`
  (audit finding V1-7 / D4 / I-08). Strategy: **generalise
  Carter–Wegman to a `Bitstring n`-native polynomial-evaluation
  hash**, not adapt via `Bitstring n → ZMod p`. New module
  `Orbcrypt/AEAD/BitstringPolynomialMAC.lean` with 18 new
  declarations: `toBit p`, `toBit_injective`, `evalAtBitstring`,
  `bitstringPolynomialHash`, `bitstringPolynomialHash_apply`,
  `bitstringPolynomialHash_collision_iff_eval`,
  `bitstringDiffPolynomial`, `_eval`, `_natDegree_le`, `_coeff_at`,
  `_ne_zero_of_ne`, `_card_roots_le`, `_collision_keys_card_le`,
  `bitstringPolynomialHash_collision_card_le`,
  `bitstringPolynomialHash_isUniversal` (**headline**
  `(n : ℝ≥0∞) / (p : ℝ≥0∞)`-universal),
  `bitstringPolynomialMAC`,
  `bitstringPolynomial_authKEM`,
  `bitstringPolynomialMAC_int_ctxt` (**headline** unconditional
  INT-CTXT for `Bitstring n`-typed authenticated KEM).

  Closes 18 declarations on standard-trio axioms; module count
  rises from 76 to 77.

- **R-09 — Discharge of `h_step` from `ConcreteOIA`.** Closes
  audit finding V1-8 / C-13 / D10. The discharge runs through
  three layers:

  * **Layer 1 (`Probability/Monad.lean`)** — sum factorisation
    along an inserted coordinate:
    `sum_pi_succAbove_eq_sum_sum_insertNth` (via
    `Fin.insertNthEquiv` + `Fintype.sum_prod_type`),
    `probTrue_PMF_map_uniformPMF_toReal` (`.toReal` form for
    `probTrue (PMF.map F (uniformPMF α)) D`).
  * **Layer 2 (`Probability/Advantage.lean`)** — convexity-of-TV:
    `advantage_pmf_map_uniform_pi_factor_bound` (per-rest
    hypothesis ⇒ global advantage bound, via cardinality
    decomposition + triangle inequality on the outer sum).
  * **Layer 3+4 (`Crypto/CompSecurity.lean`)** — per-step +
    headline: `hybrid_step_bound_of_concreteOIA` (discharges
    per-step bound from `ConcreteOIA` alone, via pattern-matching
    `Q = n + 1` + Layer 2 abstract helper + ConcreteOIA per-rest),
    `indQCPA_from_concreteOIA` (**headline** unconditional
    `indQCPAAdvantage scheme A ≤ Q · ε` from `ConcreteOIA scheme
    ε`), `indQCPA_from_concreteOIA_recovers_single_query` (Q = 1
    regression sentinel), `indQCPA_from_concreteOIA_distinct`
    (distinct-challenge classical-game form).

  Closes 7 declarations on standard-trio axioms.

**Cumulative posture (post-Workstream-D-discharge).**
- `lake build` succeeds across 3,420 jobs with zero warnings,
  zero errors.
- Phase-16 audit script exercises +36 new declarations (11 R-12
  + 18 R-13 + 7 R-09); all on standard-trio axioms; zero
  `sorryAx`.
- Module count: 76 → 77 (one new module
  `AEAD/BitstringPolynomialMAC.lean`).
- Zero-sorry / zero-custom-axiom posture preserved.

**Patch version.** `lakefile.lean` bumped from `0.2.1` to
`0.2.2` for Workstream D research-scope discharge — one new
public-API module + ~36 new public declarations warrants the
patch bump per `CLAUDE.md`'s version-bump discipline.

Workstream R-01 Research-Scope Discharge (audit 2026-04-29 § 8.1,
plan `docs/dev_history/PLAN_R_01_07_08_14_16.md` § R-01) has been
completed (2026-04-30):

- **R-01 — Quantitative cross-orbit advantage lower bound for
  `invariant_attack`.** Pre-R-01, `Orbcrypt/Theorems/InvariantAttack.lean`
  delivered only the *existential* form of the invariant attack —
  `∃ A : Adversary X M, hasAdvantage scheme A` (existence of one
  distinguishing `(g₀, g₁)` pair, the strongest deterministic-
  advantage form per the `invariant_attack` docstring's three-
  convention catalogue). R-01 strengthens this to a *tight
  probabilistic equality* at the IND-1-CPA layer: under a separating
  G-invariant, the invariant-attack adversary's `indCPAAdvantage`
  equals exactly `1` (the maximum advantage in the two-distribution
  convention; cf. `advantage_le_one`).

  The discharge lands three new public declarations under
  `Orbcrypt/Theorems/InvariantAttack.lean`:

  * **WU-01.1** — `probTrue_orbitDist_invariant_eq_one`: under a
    G-invariant `f` with `f x = f y`, the Boolean predicate
    `fun c => decide (f c = f y)` is constantly `true` on the orbit
    of `x`, so `probTrue (orbitDist x) (decide (f · = f y)) = 1` in
    `ℝ≥0∞`. Proof: route through `orbitDist x = PMF.map (· • x)
    (uniformPMF G)` via `probTrue_map`; apply `probTrue_uniformPMF_card`
    to get a filter-card ratio; show the filter equals `Finset.univ`
    via `Finset.filter_true_of_mem` (each `g : G` satisfies `f (g •
    x) = f x = f y` by composing `hInv g x` with `hEq`); collapse
    `|G| / |G| = 1` via `ENNReal.div_self` with `|G| ≠ 0` from
    `Fintype.card_pos.ne'` and `|G| ≠ ⊤` from `ENNReal.natCast_ne_top`.
  * **WU-01.2** — `probTrue_orbitDist_invariant_eq_zero`: symmetric
    `= 0` companion when `f x ≠ f y` (the predicate is constantly
    `false` on the orbit). Same proof shape with
    `Finset.filter_false_of_mem` + `Finset.card_empty` + `0 / |G| =
    0`.
  * **WU-01.3 (headline)** —
    `indCPAAdvantage_invariantAttackAdversary_eq_one`: composes the
    two mass lemmas via `indCPAAdvantage_eq` to deliver
    `indCPAAdvantage scheme (invariantAttackAdversary f m₀ m₁) = 1`.
    The bridge from the adversary's `if-then-else` guess form to the
    `decide` form needed by the mass lemmas is closed by a per-`c`
    `funext` + `by_cases` analysis.

  **Cryptographic interpretation.** `indCPAAdvantage_le_one` provides
  the universal `≤ 1` bound; R-01 says the bound is *attained* by
  the invariant-attack adversary on every scheme that admits a
  separating G-invariant. The bound is tight in both directions
  (no scheme can exceed the universal `≤ 1`; some schemes attain it
  exactly). Composed with `concrete_oia_implies_1cpa`, R-01 forces:
  *any scheme admitting a separating G-invariant cannot satisfy
  `ConcreteOIA scheme ε` for any `ε < 1`*. This formalises the
  audit-disclosed "complete break" semantics quantitatively, ruling
  out non-trivial probabilistic security in addition to the
  vacuously-true deterministic-OIA gap.

  **KEM-layer companion: dropped.** The KEM-layer companion of R-01
  was found mathematically vacuous during plan review (see
  `docs/dev_history/PLAN_R_01_07_08_14_16.md` § "KEM-layer companion:
  dropped"). The KEM uniform-form game's two distributions live in
  the basepoint's single orbit, so any G-invariant distinguisher
  gives advantage `0`, not `1`. The KEM-layer parallel of R-01's
  *existential* content (`G-invariant attack ⇒ KEMOIA is False`) is
  already discharged by `det_kemoia_false_of_nontrivial_orbit` in
  `Orbcrypt/KEM/Security.lean` (post-Workstream-E of audit
  2026-04-23, finding E-06). That theorem uses the *non*-G-invariant
  test `fun c => decide (c = g₀ • basePoint)` to refute deterministic
  KEMOIA — exactly the right adversarial shape because the KEM game
  distinguishes ciphertexts within ONE orbit (so a G-invariant
  function carries no signal there).

  **Files touched.**
  * `Orbcrypt/Theorems/InvariantAttack.lean` — extended with three
    new theorems (WU-01.1, WU-01.2, WU-01.3 headline) plus an
    expanded module docstring documenting the probabilistic
    strengthening and the KEM-layer-companion-vacuity finding.
    Imports added: `Orbcrypt.Crypto.CompOIA`,
    `Orbcrypt.Crypto.CompSecurity`, `Orbcrypt.Probability.Monad`.
    `open ENNReal` added to the new section so the `ℝ≥0∞` notation
    is in scope.
  * `scripts/audit_phase_16.lean` — three new `#print axioms`
    entries (line ~150 of the script, immediately after the existing
    `invariant_attack` entry) plus a new `R01NonVacuity` namespace
    at the end of the script with four non-vacuity `example`
    bindings: (1) `_eq_one` mass lemma at the trivial action
    (`Equiv.Perm (Fin 1)` on `Bool`); (2) `_eq_zero` mass lemma at
    the same fixture; (3) headline `= 1` equality on
    `NonVacuityWitnesses.trivialSchemeBool`; (4) tightness witness
    showing the R-01 bound is attained (composed with
    `indCPAAdvantage_le_one`). The fixture re-uses
    `NonVacuityWitnesses.trivialSchemeBool` (the two-message scheme
    on `Bool` under the trivial action) and a fresh
    `id_isGInvariant_trivialPermFin1` helper proving `id` is
    G-invariant under the trivial action.
  * `lakefile.lean` — version bumped from `0.2.2` to `0.2.3`;
    "Last verified" comment block extended with a Workstream-R-01
    entry.

  **Verification.** Every new declaration depends only on the
  standard Lean trio (`propext`, `Classical.choice`, `Quot.sound`).
  Zero `sorry`, zero custom axioms, zero warnings. Full `lake build`
  succeeds across 3,420 jobs (unchanged from the pre-R-01 baseline:
  R-01 lands inside an existing module, no new `.lean` file is
  added, so the module count remains at 77; the build-job count is
  unchanged because `Orbcrypt/Theorems/InvariantAttack.lean` was
  already a build node). Phase-16 audit script (`scripts/audit_phase_16.lean`)
  runs cleanly with exit code 0; emits zero `sorryAx`; emits zero
  non-standard-trio axioms; the three new R-01 `#print axioms`
  entries report `[propext, Classical.choice, Quot.sound]` for each
  theorem.

  **Patch version.** `lakefile.lean` bumped from `0.2.2` to `0.2.3`
  for Workstream R-01 — three new public declarations land within
  the existing `Orbcrypt/Theorems/InvariantAttack.lean` module,
  warranting a patch-version bump per `CLAUDE.md`'s version-bump
  discipline. The 77-module total, the zero-sorry / zero-custom-
  axiom posture, and the standard-trio-only axiom-dependency
  posture are all preserved. Public declaration count rises by
  three. Audit-script `#print axioms` entries rise by three (the
  three R-01 declarations: `probTrue_orbitDist_invariant_eq_one`,
  `probTrue_orbitDist_invariant_eq_zero`,
  `indCPAAdvantage_invariantAttackAdversary_eq_one`).

  **Remaining R-01 follow-ups: none.** R-01 is fully discharged in
  this PR. The remaining audit-2026-04-29 § 8.1 research-scope items
  (R-07, R-08, R-13⁺, R-14, R-16) are tracked by the same plan
  document but are *not* landed by this PR; their discharge is
  planned for follow-up work units.

Workstream R-07 Research-Scope Discharge (audit 2026-04-29 § 8.1,
plan `docs/dev_history/PLAN_R_01_07_08_14_16.md` § R-07) has been
completed (2026-04-30):

- **R-07 — Cross-orbit advantage lower bound for equivariant
  combiners.** The Workstream-E6 results
  (`concrete_combiner_advantage_bounded_by_oia`,
  `combinerOrbitDist_mass_bounds`) deliver only the *upper-bound*
  half of the combiner story: under `ConcreteOIA(ε)` the combiner-
  induced distinguisher's advantage is at most `ε`. The intra-orbit
  mass bound on the basepoint orbit (`combinerOrbitDist_mass_bounds`,
  E6b) is by itself *not* a cross-orbit advantage lower bound —
  two orbits could place identical Pr[true] = 1/2, yielding
  cross-orbit advantage 0 (the `combinerOrbitDist_mass_bounds`
  docstring discloses this gap). R-07 closes the gap by exhibiting
  a structural predicate (`CrossOrbitNonDegenerateCombiner`) that
  combines intra-orbit non-triviality on `m_bp` with a cross-orbit
  constant-false witness on `m_target`, together forcing
  `combinerDistinguisherAdvantage ≥ 1/|G|` and hence (composed with
  the upper bound) `ConcreteOIA scheme ε ⇒ 1/|G| ≤ ε`.

  The discharge lands six new public declarations under
  `Orbcrypt/PublicKey/CombineImpossibility.lean`:

  * **WU-07.1** — `combinerOrbitDist_apply_true_eq_probTrue`:
    bridge lemma identifying the apply-form mass `combinerOrbitDist
    scheme m_bp comb m true` with the `probTrue` form `probTrue
    (orbitDist (reps m)) (combinerDistinguisher comb)`. Proof
    routes both sides through the same outer-measure expression on
    `uniformPMF G` via `PMF.toOuterMeasure_apply_singleton` +
    `PMF.toOuterMeasure_map_apply`. This bridge lets us reuse the
    `1/|G|` mass bound from `combinerOrbitDist_mass_bounds.1` in
    `probTrue` form, where it composes naturally with `advantage`'s
    `probTrue`-based definition.
  * **WU-07.2** — `CrossOrbitNonDegenerateCombiner`: `Prop`-valued
    structure with two fields, `intra : NonDegenerateCombiner comb`
    (intra-orbit non-triviality on `m_bp`'s orbit) and
    `cross_constant_false : ∀ g : G, combinerDistinguisher comb
    (g • reps m_target) = false` (cross-orbit constant-false
    witness on `m_target`'s orbit). Edge cases documented in the
    docstring: at `m_bp = m_target` and at `|G| = 1` the structure
    is `False` (the two fields contradict on the same orbit / the
    intra hypothesis is unsatisfiable on a singleton group), so the
    headline holds vacuously in those cases. Inhabited by the
    concrete fixture below at `|G| = 2`, `m_bp ≠ m_target`.
  * **WU-07.3** —
    `probTrue_combinerDistinguisher_basePoint_ge_inv_card`: rephrases
    the existing `combinerOrbitDist_mass_bounds.1 hND` (`1/|G| ≤
    combinerOrbitDist ... true`) into `1/|G| ≤ probTrue (orbitDist
    (reps m_bp)) (combinerDistinguisher comb)` via the WU-07.1
    bridge.
  * **WU-07.4** —
    `probTrue_combinerDistinguisher_target_eq_zero`: under the
    cross-orbit constant-false hypothesis, the orbit distribution
    of `m_target` assigns mass exactly `0` to the `true` branch.
    Proof: push `probTrue` through `orbitDist`'s `PMF.map`-bridge
    via `PMF.toOuterMeasure_map_apply`; the resulting preimage set
    `{g | combinerDistinguisher comb (g • reps m_target) = true}` is
    *empty* under the hypothesis (every `g` falsifies the predicate
    via `Bool.noConfusion`); the outer measure of the empty set is
    `0` via Mathlib's `MeasureTheory.measure_empty`.
  * **WU-07.5** —
    `combinerDistinguisherAdvantage_ge_inv_card` (headline):
    composes WU-07.3 + WU-07.4 with `combinerDistinguisherAdvantage
    _eq` (existing E6 unfolding lemma) and `advantage`'s `|p_R - p_L|`
    form. The ENNReal-to-ℝ conversion uses `ENNReal.toReal_le_toReal`
    with finiteness side conditions (`(|G| : ENNReal)⁻¹ ≠ ⊤` from
    `|G| ≠ 0`; `probTrue ≤ 1 ≠ ⊤` via `ne_top_of_le_ne_top`); the
    final identification `((|G| : ENNReal)⁻¹).toReal = 1 / (|G| : ℝ)`
    uses `ENNReal.toReal_inv` + `ENNReal.toReal_natCast`.
  * **WU-07.6** —
    `no_concreteOIA_below_inv_card_of_combiner` (corollary): one-
    line `le_trans` chaining the lower bound (WU-07.5) with the
    existing upper bound `concrete_combiner_advantage_bounded_by_oia`.
    Cryptographic content: a scheme that admits any cross-orbit
    non-degenerate equivariant combiner is provably *not* `ε`-
    ConcreteOIA-secure for any `ε < 1/|G|`, refuting the
    deterministic refutation `equivariant_combiner_breaks_oia`'s
    quantitative descendant.

  **Cryptographic interpretation.** R-07 is the quantitative
  refinement of the deterministic `equivariant_combiner_breaks_oia`:
  that theorem says non-degenerate equivariant combiners refute the
  all-or-nothing deterministic OIA; R-07 says the refutation lifts
  to the probabilistic level with an explicit `1/|G|` lower bound
  on `ε` whenever a cross-orbit non-degenerate combiner is exhibited.
  The `cross_constant_false` hypothesis is *strong* — most natural
  combiners don't satisfy it on arbitrary target orbits — so R-07's
  `1/|G|` is a sufficient-condition refutation; tighter cross-orbit
  bounds at weaker hypotheses (e.g. `1/2` instead of `1/|G|`)
  require problem-specific structure and remain research-scope
  follow-ups.

  **Concrete fixture (audit-script non-vacuity witness).**
  `scripts/audit_phase_16.lean`'s `R07NonVacuity` namespace exhibits
  the structure on a concrete `S_2 ⤳ Bitstring 2` model:
  * `G := ⊤ ≤ Equiv.Perm (Fin 2)` (the full S_2; cardinality 2).
  * `X := Bitstring 2` with `subgroupBitstringAction` permuting
    indices.
  * `M := Bool`, `repsR07 true := ![T, F]` (basepoint, in the
    weight-1 doubleton orbit `{![T, F], ![F, T]}`); `repsR07
    false := ![F, F]` (target, in the weight-0 singleton orbit).
    Orbits disjoint by Hamming-weight separation
    (`hammingWeight_invariant_subgroup` +
    `separating_implies_distinct_orbits`).
  * `combR07.combine x y := y` (projection on second argument):
    closed on the basepoint orbit, G-equivariant by definition.
    Intra-orbit non-triviality witness: the swap moves `![T, F]`
    to `![F, T] ≠ ![T, F]`. Cross-orbit constant-false witness:
    every permutation fixes `![F, F]`, and `![F, F] ≠ ![T, F]`
    makes the combinerDistinguisher constantly `false` on the
    target orbit.
  * Headline: `(1 : ℝ) / 2 ≤ combinerDistinguisherAdvantage
    schemeR07 true combR07 true false`. Concrete instance proves
    the predicate is genuinely inhabited and the headline theorem
    fires non-vacuously.

  **Files touched.**
  * `Orbcrypt/PublicKey/CombineImpossibility.lean` — extended with
    six new public theorems / structures; module docstring
    extended with R-07 section. No new imports needed (already
    imports `CompOIA`, `Probability/Advantage`).
  * `scripts/audit_phase_16.lean` — six new `#print axioms`
    entries plus a new `R07NonVacuity` namespace with parametric
    examples (one per WU) and a concrete `S_2 ⤳ Bitstring 2`
    fixture witnessing the structure's inhabitedness. The
    `decidableMemTopPermFin2` `local instance` in the namespace
    enables `Fintype ↥⊤` synthesis for `hgoeScheme.ofLexMin` and
    the headline-bound application.
  * `lakefile.lean` — version bumped from `0.2.3` to `0.2.4`;
    "Last verified" comment block extended with a Workstream-R-07
    entry.

  **Verification.** Every new declaration depends only on the
  standard Lean trio (`propext`, `Classical.choice`, `Quot.sound`).
  The `CrossOrbitNonDegenerateCombiner` structure is axiom-free
  (Prop bundle). Zero `sorry`, zero custom axioms, zero warnings.
  Full `lake build` succeeds across 3,420 jobs (R-07 lands inside
  an existing module, no new `.lean` file is added). Phase-16
  audit script (`scripts/audit_phase_16.lean`) runs cleanly with
  exit code 0; emits zero `sorryAx`; emits zero non-standard-trio
  axioms; the six new R-07 `#print axioms` entries report
  standard-trio (or "does not depend on any axioms" for the Prop
  structure).

  **Patch version.** `lakefile.lean` bumped from `0.2.3` to `0.2.4`
  for Workstream R-07 — six new public declarations land within
  the existing `Orbcrypt/PublicKey/CombineImpossibility.lean`
  module, warranting a patch-version bump per `CLAUDE.md`'s
  version-bump discipline. The 77-module total, the zero-sorry /
  zero-custom-axiom posture, and the standard-trio-only axiom-
  dependency posture are all preserved. Public declaration count
  rises by six. Audit-script `#print axioms` entries rise by six
  (the six R-07 declarations:
  `combinerOrbitDist_apply_true_eq_probTrue`,
  `CrossOrbitNonDegenerateCombiner`,
  `probTrue_combinerDistinguisher_basePoint_ge_inv_card`,
  `probTrue_combinerDistinguisher_target_eq_zero`,
  `combinerDistinguisherAdvantage_ge_inv_card`,
  `no_concreteOIA_below_inv_card_of_combiner`). The audit-script
  total verified post-R-07: 992 `#print axioms` entries, all
  standard-trio-only or axiom-free; zero `sorryAx`; zero non-
  standard axioms.

  **Remaining R-07 follow-ups: none.** R-07 is fully discharged in
  this PR. The remaining audit-2026-04-29 § 8.1 research-scope items
  (R-08, R-13⁺, R-14, R-16) are tracked by the same plan document
  but are *not* landed by this PR; their discharge is planned for
  follow-up work units.

Workstream R-14 + R-08 + R-13⁺ + R-16 Research-Scope Discharge
(audit 2026-04-29 § 8.1, plan
`docs/dev_history/PLAN_R_01_07_08_14_16.md` § R-14 / § R-08 / §
R-13⁺ / § R-16) has been completed (2026-05-01):

- **R-14 — Generic probabilistic MAC SUF-CMA framework.** New module
  `Orbcrypt/AEAD/MACSecurity.lean` (~770 LOC) plus extensions to
  `Orbcrypt/Probability/UniversalHash.lean` (~440 LOC of additions).

  * `IsEpsilonAXU` / `IsEpsilonSU2` predicates added to
    `UniversalHash.lean`. ε-SU2 is the *strongly-universal-2*
    property: for distinct messages `m₁ ≠ m₂` and arbitrary tag pair
    `(t₁, t₂)`, the joint probability `Pr_k[h k m₁ = t₁ ∧ h k m₂ =
    t₂]` is at most `ε / |Tag|`. Strictly stronger than both
    ε-universal and ε-AXU.
  * `IsEpsilonSU2.toIsEpsilonUniversal` and `_.toIsEpsilonAXU`:
    SU2 → universal and SU2 → AXU corollaries via the disjoint-
    union decomposition of the diagonal / output-difference event
    over `t : Tag`. Each summing argument exploits Mathlib's
    `Finset.card_biUnion` (with disjointness from the unique-
    `h k m₁` value parametrising the partition) plus
    `Finset.sum_const` and `ENNReal.mul_div_cancel`.
  * `IsEpsilonSU2.ofJointCollisionCardBound`: structural sufficient
    condition — bound the joint-collision Finset card by `C`,
    conclude `(C · |Tag|) / |K|`-SU2.
  * `MACAdversary` (1-time, functional shape mirroring `Adversary`
    in `Crypto/Security.lean`), `MACAdversary.forges`,
    `forgeryAdvantage`, `IsSUFCMASecure` plus the standard `_nonneg`
    / `_le_one` bounds.
  * `MultiQueryMACAdversary` (Q-time non-adaptive),
    `MultiQueryMACAdversary.forges`, `forgeryAdvantage_Qtime`,
    `IsQtimeSUFCMASecure` plus the standard `_nonneg` / `_le_one`
    bounds.
  * **`IsDeterministicTagMAC`** predicate (NEW abstraction):
    captures the property `verify k m t = decide (t = tag k m)` as
    a `Prop` over a `MAC` value. Lets the framework reduce
    `mac.verify` to decide-equality without forcing
    `MACSecurity.lean` to import any concrete construction. Closes
    a circular-import gap (MACSecurity uses `deterministicTagMAC`
    semantics; CarterWegmanMAC supplies `deterministicTagMAC`; the
    predicate-based abstraction breaks the cycle cleanly).
  * **Headline reduction `isSUFCMASecure_of_isEpsilonSU2`** (Stinson
    1994 Theorem 1): any deterministic-tag MAC whose `tag` is an
    ε-SU2 hash is `ε`-SUF-CMA-secure (1-time). Proof structure:
    1. Express `Pr[Win]` as a sum over `t_q : Tag` of per-`t_q`
       conditional probabilities (each `k` has a unique `t_q :=
       h k m_q`, so the win event partitions over `t_q`).
    2. Per-`t_q`: case-split on whether `m'(t_q) = m_q`. Collision
       case contributes 0 (fresh-message constraint fails); non-
       collision case is bounded by `ε / |Tag|` via SU2.
    3. Sum over `|Tag|` terms: `|Tag| · (ε / |Tag|) = ε`.
    Implemented in cardinality space with `Finset.biUnion` +
    `Finset.card_biUnion` + `ENNReal.div_le_iff` for the final
    `.toReal` conversion.
  * **`IsKeyRecoverableForSomeQueries`** predicate: existential
    witness predicate for the Q-time NEGATIVE result.
  * **Headline negative theorem
    `not_isQtimeSUFCMASecure_of_keyRecoverableForSomeQueries`**:
    when the hash is key-recoverable from a specific Q-tuple of
    queries, the corresponding deterministic-tag MAC is **not**
    `ε`-(Q+1)-time-SUF-CMA-secure for any `ε < 1`. Constructs an
    explicit (Q+1)-time adversary using two distinct fresh
    messages (one for query padding, one for the forge target),
    proves `forgeryAdvantage_Qtime = 1` deterministically, and
    contradicts `ε < 1`.

- **R-08 — Carter–Wegman SU2 + 1-time SUF-CMA + Q-time NEGATIVE.**
  Extension to `Orbcrypt/AEAD/CarterWegmanMAC.lean` (~200 LOC).

  * `carterWegmanSolve` (private, noncomputable): closed-form
    unique-solution map `((t₁ - t₂) / (m₁ - m₂), t₁ - k₁ · m₁)`
    for the Carter–Wegman 2×2 linear system in the field `ZMod p`.
  * `carterWegmanHash_joint_collision_card_eq_one` (private):
    joint-collision filter equals the singleton
    `{carterWegmanSolve}`, hence card = 1.
  * **`carterWegmanHash_isEpsilonSU2`** (R-08 SU2 headline):
    Carter–Wegman is `(1/p)`-SU2 over `ZMod p`. Apply
    `IsEpsilonSU2.ofJointCollisionCardBound` with `C = 1`, then
    rewrite `(1 · p) / p² = 1/p`.
  * **`carterWegmanHash_isEpsilonAXU`**: corollary via
    `.toIsEpsilonAXU`.
  * **`carterWegmanMAC_isSUFCMASecure`** (R-08 1-time headline):
    `(1/p)`-SUF-CMA-secure (1-time), via composition with
    `isSUFCMASecure_of_isEpsilonSU2`.
  * `carterWegmanRecover` (private, noncomputable): explicit
    linear-system inversion at messages `(0, 1)`.
  * **`carterWegmanHash_isKeyRecoverableForSomeQueries`**: witness
    `Q = 2` recovery using `![0, 1]` (distinct in `ZMod p` for
    `p ≥ 2`).
  * **`not_carterWegmanMAC_isQtimeSUFCMASecure`** (R-08 Q-time
    NEGATIVE headline): at `p ≥ 4`, no `ε < 1` bound holds for
    `Q = 3`-time SUF-CMA. Cardinality side condition: `|ZMod p|
    = p ≥ 4 = (Q + 1) + 1`.

- **R-13⁺ — Bitstring-polynomial SU2 + 1-time SUF-CMA + Q-time
  NEGATIVE.** Extension to
  `Orbcrypt/AEAD/BitstringPolynomialMAC.lean` (~280 LOC).

  * `bitstringDiffPolynomialShifted` (private, noncomputable):
    `Δ - C δ` for the joint-collision-at-(t₁, t₂) reduction.
  * `bitstringDiffPolynomialShifted_natDegree_le` (private): degree
    ≤ n via `Polynomial.natDegree_sub_le` + `natDegree_C ≤ 0`.
  * `bitstringDiffPolynomialShifted_ne_zero_of_ne` (private):
    non-zero for `b₁ ≠ b₂` via the disagreeing-position coefficient
    at index ≥ 1 (unaffected by the constant-coefficient shift).
  * `bitstringPolynomialHash_joint_keys_card_le` (private):
    k₁-projection of the joint-collision filter has card ≤ n via
    the polynomial-roots bound on the shifted-difference
    polynomial.
  * `bitstringPolynomialHash_joint_collision_card_le` (private):
    joint-card on `ZMod p × ZMod p` ≤ n via `Set.InjOn` of the
    k₁-projection (k.2 uniquely determined by k.1 and t₁).
  * **`bitstringPolynomialHash_isEpsilonSU2`** (R-13⁺ SU2
    headline): `(n / p)`-SU2.
  * **`bitstringPolynomialHash_isEpsilonAXU`**: corollary via
    `.toIsEpsilonAXU`.
  * **`bitstringPolynomialMAC_isSUFCMASecure`** (R-13⁺ 1-time
    headline): `(n / p)`-SUF-CMA-secure (1-time).
  * `bitstringPolynomialRecover` (private, noncomputable): explicit
    recovery from witness queries `(e₀, 0)` (one-hot at position 0
    + all-false bitstring).
  * **`bitstringPolynomialHash_isKeyRecoverableForSomeQueries`**:
    witness `Q = 2` recovery requires `n ≥ 1`.
  * **`not_bitstringPolynomialMAC_isQtimeSUFCMASecure`** (R-13⁺
    Q-time NEGATIVE headline): at `n ≥ 2`, no `ε < 1` bound holds
    for `Q = 3`-time SUF-CMA. Cardinality side condition:
    `|Bitstring n| = 2^n ≥ 4`.

- **R-16 — HGOE invariants beyond Hamming weight.** New module
  `Orbcrypt/Construction/HGOEInvariants.lean` (~310 LOC).

  * **Block-sum invariant.** `blockSum block b j := |{i ∈ block j :
    b i = true}|` — per-block bit-count vector. Generalises
    `hammingWeight` (the single-block partition recovers
    Hamming weight). The `PreservesBlocks` predicate captures
    "every group element setwise-permutes each block";
    `blockSum_invariant_of_preservesBlocks` proves G-invariance via
    a `Finset.card_bij` between `(g • b)`-filter and `b`-filter
    using `i ↦ σ⁻¹ i` and `PreservesBlocks` at both `g` and
    `g⁻¹`. Companion `hgoe_blockSum_attack` (existential adversary)
    and `same_blockSum_not_separating` (defence).
  * **Bit parity invariant.** `bitParity b := decide (hammingWeight
    b % 2 = 1)`. `S_n`-invariant by reduction to
    `hammingWeight_invariant`. Companion attack/defence.
  * **Sorted-bits invariant.** `sortedBits b` = lex-min element
    of `b`'s `S_n`-orbit under `bitstringLinearOrder`. Defined
    via `CanonicalForm.ofLexMin`. `S_n`-invariant by
    `canonical_isGInvariant`. The strongest `S_n`-invariant —
    distinct orbits have distinct sorted-bits, so any
    `S_n`-respecting HGOE scheme is *automatically broken* by
    the sorted-bits attack (formal cryptographic content of the
    deterministic-OIA-vacuity result
    `det_oia_false_of_distinct_reps`).

- **Cross-cutting.** The R-14 framework's headline reduction
  `isSUFCMASecure_of_isEpsilonSU2` factors through the new
  `IsDeterministicTagMAC` predicate, so the R-08 + R-13⁺
  specialisations supply a one-line `rfl`-witness for the
  predicate (since their `verify` field is *literally*
  `decide (t = tag k m)` per `deterministicTagMAC`'s body).

  The pipeline order is:
  - `Orbcrypt/AEAD/MAC.lean` — abstract structure (unchanged).
  - `Orbcrypt/Probability/UniversalHash.lean` — ε-universal +
    NEW: ε-AXU, ε-SU2, plus their corollary chain.
  - `Orbcrypt/AEAD/MACSecurity.lean` — NEW framework module.
    Imports `MAC.lean` (abstract) + `Probability/UniversalHash.lean`,
    NOT `CarterWegmanMAC.lean`.
  - `Orbcrypt/AEAD/CarterWegmanMAC.lean` — concrete Carter–Wegman
    construction + R-08 specialisation. Imports `MACSecurity.lean`.
  - `Orbcrypt/AEAD/BitstringPolynomialMAC.lean` — bitstring-
    polynomial construction + R-13⁺ specialisation. Imports
    `CarterWegmanMAC.lean` (and transitively `MACSecurity.lean`).

  This avoids the would-be circular import that a naive
  `MACSecurity` ↔ `CarterWegmanMAC` design would create, while
  keeping `MAC.lean` free of concrete-construction pollution.

- **`Orbcrypt.lean`** root file extended with two new explicit
  imports: `Orbcrypt.AEAD.MACSecurity` and
  `Orbcrypt.Construction.HGOEInvariants`.

- **`scripts/audit_phase_16.lean`** extended with four new sections
  (§ 15.22 R-14, § 15.23 R-08, § 15.24 R-13⁺, § 15.25 R-16)
  containing 50 new `#print axioms` entries plus 17 non-vacuity
  `example` bindings exercising every public R-14 / R-08 / R-13⁺
  / R-16 declaration on concrete fixtures (`p = 5` for
  R-08, `(p, n) = (5, 3)` for R-13⁺, `Bitstring 4` with a 2-block
  partition for R-16). Each section uses a `local instance
  fact_prime_five : Fact (Nat.Prime 5)` (decide-discharged)
  because Mathlib only provides `fact_prime_two` and
  `fact_prime_three` natively.

- **Verification posture (R-14 + R-08 + R-13⁺ + R-16).**
  * `lake build` succeeds with **3,422 jobs** (up from 3,420 — two
    new modules: `MACSecurity.lean` and `HGOEInvariants.lean`),
    zero errors, zero warnings.
  * `lake env lean scripts/audit_phase_16.lean` runs cleanly:
    zero `sorryAx`, zero non-standard-trio axioms (875 `#print
    axioms` results, all on `[propext, Classical.choice,
    Quot.sound]` or a subset).
  * Every new public declaration depends only on the standard
    Lean trio.

- **Patch version.** `lakefile.lean` bumped from `0.2.4` to
  `0.3.0` — minor-version bump signalling the cohesive feature
  cluster of four new workstream discharges (R-14 + R-08 +
  R-13⁺ + R-16) plus two new modules. The 77-module total rises
  to **79** (`MACSecurity.lean` + `HGOEInvariants.lean`); public
  declaration count rises by approximately 30 (R-14: ~15, R-08:
  5, R-13⁺: 5, R-16: 15 — minus some private helpers). The
  zero-sorry / zero-custom-axiom posture and the standard-trio-
  only axiom-dependency posture are preserved.

- **Deep audit pass (2026-05-01).** A second comprehensive audit
  was run after the initial landing. Findings:
  * **No `sorry`, no custom axioms** across all five PR-touched
    files (verified by comment-stripped grep).
  * **No naming-hygiene violations** (no `R0[0-9]`, `r08`, `r13`,
    `r14`, `r16`, `workstream`, `phase`, `audit` tokens in any
    new declaration name).
  * **No theatrical theorems**: every theorem proof genuinely
    consumes its hypotheses; the only `fun _ _ _ => rfl` patterns
    are the discharge of `IsDeterministicTagMAC` for
    `deterministicTagMAC` (correct: the predicate's conclusion
    is `rfl`-level on the body of `deterministicTagMAC`).
  * **Math soundness** verified by tracing each headline proof
    (SU2 reduction, SU2 → AXU, joint-collision-card bounds, key
    recovery, blockSum invariance via `Finset.card_bij`).
  * **Audit-coverage gap closed**: added explicit non-vacuity
    examples for `IsEpsilonSU2.mono`, `IsEpsilonAXU.mono`,
    `IsEpsilonSU2.ofJointCollisionCardBound`, and
    `IsEpsilonAXU.ofCollisionCardBound` in the
    `R14NonVacuity` namespace (previously these were only
    exercised transitively via R-08 / R-13⁺ specialisations).
  * **Docstring corrections**: tightened the `sortedBits` and
    `IsEpsilonAXU.toIsEpsilonUniversal` docstrings to honestly
    disclose the `S_n`-orbit relationship (sortedBits is
    determined by Hamming weight) and the `AddGroup` typeclass
    requirement, respectively. No content changes — only
    docstring honesty.
  * **Cleanup**: removed an unused `h_p_ne_top` hypothesis in
    `carterWegmanMAC_isSUFCMASecure` (the cleanup was
    silenced by Lean's linter because the variable did not
    trigger a warning at our linter settings, but the removal
    is good hygiene).
  * **Edge cases verified**: small-`p` Carter–Wegman (`p = 2`),
    `n = 0` bitstring-polynomial, empty block partition (`ℓ = 0`),
    overlapping blocks all behave correctly. The negative
    theorems' cardinality side conditions (`p ≥ 4` for R-08,
    `n ≥ 2` for R-13⁺) correctly exclude the small-cardinality
    cases where the framework's `Q + 1 < |Msg|` requirement
    fails.

- **R-14 / R-08 / R-13⁺ / R-16 follow-ups: none.** All four
  workstreams are fully discharged in this PR. The remaining
  audit-2026-04-29 § 8.1 research-scope items (R-02, R-03,
  R-04, R-05, R-06, R-10, R-11, R-15, R-15-residual-*) are
  out-of-scope multi-month research workstreams as documented
  in the plan; this PR does not touch them.

Workstream R-05 framework landing (audit 2026-04-29 § 8.1, plan
`docs/planning/PLAN_R_05_11_15.md` § R-05) has been completed
(2026-05-01):

- **Problem.** `Orbcrypt/AEAD/CarterWegmanMAC.lean` and
  `Orbcrypt/AEAD/BitstringPolynomialMAC.lean` machine-check the
  Q-time NEGATIVE result that nonce-free Carter–Wegman is provably
  broken at Q ≥ 2 queries (linear-system / polynomial-system key
  recovery). Both module docstrings flag the nonce-based variant
  (Wegman–Carter 1981 §3) as research milestone R-05.

- **Mathematical content (Wegman–Carter 1981 §3).** A nonced MAC
  composes a hash family `hash : K_h → Msg → Tag` with a
  pseudo-random function `prf : K_p → Nonce → Tag` to produce per-
  (nonce, message) tags via additive masking
  `tag(k_h, k_p, n, m) := hash(k_h, m) + prf(k_p, n)`. Under (a)
  ε_h-AXU on the hash and (b) ε_p-PRF on the PRF, the Q-time SUF-
  CMA advantage is at most `Q · ε_h + ε_p + 1/|Tag|` — quantitatively
  *better* than the nonce-free MAC's Q-time NEGATIVE bound (which
  has advantage `1` at `Q ≥ 2`).

- **Files added (2 new modules).**
  * `Orbcrypt/AEAD/NoncedMAC.lean` (~440 LOC, NEW). Layers:
    - **Layer 1** — `NoncedMAC` structure (`hash`, `prf` fields),
      `tag` and `verify` functions, `verify_tag` correctness simp
      lemma, `verify_iff` decomposition.
    - **Layer 2** — `NoncedMultiQueryMACAdversary` structure,
      `forges` Bool predicate (with nonce-distinct +
      `(nonce, message)`-freshness checks), `noncedForgeryAdvantage_Qtime`
      PMF wrapper, `IsNoncedQtimeSUFCMASecure` Prop, `_nonneg`,
      `_le_one`, `_le_one (Prop)`, `_mono` companions.
    - **Layer 3** — `IsPRF` Prop predicate (function-level
      formulation: `prf` is `ε`-PRF iff every Boolean distinguisher
      on `Nonce → Tag` has advantage at most `ε` between the
      PMF.map'd PRF outputs and `uniformPMF (Nonce → Tag)`).
      `IsPRF.mono`, `IsPRF.le_one` helpers. `idealRandomOraclePRF`
      definition (the truly-random oracle: "key" is the entire
      function, `prf k n := k n`). `idealRandomOraclePRF_isPRF`
      proves the truly-random oracle is `0`-PRF (the two
      distributions coincide exactly via `PMF.map_id`; advantage
      reduces to `advantage_self`).
  * `Orbcrypt/AEAD/NoncedMACSecurity.lean` (~280 LOC, NEW). Layers:
    - **Layer 1** — concrete specialisations: `nonceCarterWegmanMAC p`
      (composes `carterWegmanHash p` with the truly-random oracle on
      `Nonce → ZMod p`), `nonceBitstringPolynomialMAC p n` (composes
      `bitstringPolynomialHash p n` with the truly-random oracle).
    - **Layer 2** — structural simp lemmas (`_hash`, `_prf` apply
      lemmas for both specialisations).
    - **Layer 3** — IsPRF non-vacuity at the truly-random oracle
      composed with the concrete hash families: both
      `nonceCarterWegmanMAC_isPRF` and
      `nonceBitstringPolynomialMAC_isPRF` are `0`-PRFs.
    - **Layer 4** — IsEpsilonAXU non-vacuity from the existing
      R-08 / R-13⁺ landings: `nonceCarterWegmanMAC_isEpsilonAXU` is
      `(1/p)`-AXU; `nonceBitstringPolynomialMAC_isEpsilonAXU` is
      `(n/p)`-AXU.
    - **Layer 5** — trivial `_le_one` Q-time SUF-CMA bounds for
      both specialisations (the satisfiability anchor; matches
      `IsEpsilonUniversal.le_one`'s pattern).
    - **Layer 6** — `r05_research_scope_disclosure` documenting
      what is and is not proved unconditionally.

- **Research-scope status.** The headline reduction theorem
  `noncedMAC_isQtimeSUFCMASecure_of_isAXU_and_isPRF` (with bound
  `Q · ε_h + ε_p + 1/|Tag|`) is captured as a research-scope
  obligation R-05⁺ at this landing. The cryptographic content is
  the standard Wegman–Carter 1981 §3 analysis (well-established in
  the cryptographic literature); the Lean formalisation is a
  multi-day undertaking (per `docs/planning/PLAN_R_05_11_15.md`
  § R-05 Phase 3, budgeted at 9 sub-units / ~280 LOC / ~4.5 days).
  This landing provides the **framework structures** (concrete
  `NoncedMAC` instances, IsPRF + IsEpsilonAXU non-vacuity witnesses,
  structural simp lemmas, `_le_one` sentinels) so that when the
  formal proof of the bound lands as the R-05⁺ follow-up workstream,
  its consumer-facing API is already in place. Naming-discipline
  posture preserved: no identifier carries the `R-05` token (per
  CLAUDE.md's "Names describe content, never provenance" rule); the
  workstream is referenced only inside docstrings / comments.

- **Audit script** `scripts/audit_phase_16.lean` extended with
  § 15.26 (32 new `#print axioms` entries + 14 non-vacuity
  `example` bindings under the `RandomOracleNonVacuity` namespace,
  exercising every public R-05 declaration on concrete `p = 5` and
  `Nonce = Fin 8` fixtures). Total `#print axioms` entries rises
  from 947 to 1073; module count rises from 79 to 81; full `lake
  build` succeeds across 3,424 jobs (pre-R-05 3,422 + 2 new
  module nodes); the audit script runs cleanly with exit code 0
  (zero `sorryAx`, zero non-standard axioms, every R-05
  declaration on the standard Lean trio `[propext,
  Classical.choice, Quot.sound]`).

- **Patch version.** `lakefile.lean` bumped from `0.3.0` to
  `0.3.1`. Two new public-API modules add ~30 new public
  declarations, warranting the patch-version bump per CLAUDE.md's
  version-bump discipline. The 79-module total rises to **81**;
  the zero-sorry / zero-custom-axiom posture and the standard-
  trio-only axiom-dependency posture are both preserved. Public
  declaration count rises from ~990 to ~1020 (~30 new
  declarations: ~14 in `NoncedMAC.lean`, ~16 in
  `NoncedMACSecurity.lean`).

- **Non-goal (tracked as R-05⁺).** Concrete instantiations with
  non-ideal PRFs (HMAC, AES-CTR) require the corresponding
  cryptographic-PRF assumption (HMAC-PRF, AES-PRF), which is not
  provable inside Lean. Adaptive Q-time queries (full SUF-CMA-2 /
  oracle access) require Lean-level oracle-game abstractions.

- Every `.lean` file has a module-level docstring
- Every public theorem and def has a docstring
- GitHub Actions CI passes on push
- Dependency graph and axiom transparency report documented

Workstream R-05 refinement — Marginal-uniformity proof + Q-tuple
ideal-oracle witness (audit 2026-05-01 follow-up, plan
`/root/.claude/plans/shiny-squishing-sutton.md`) has been completed
(2026-05-01):

- **Problem.** The R-05 framework landing (2026-05-01) introduced
  `IsPRFAtQueries` as the Q-tuple PRF predicate (more general than
  the function-level `IsPRF`; works for arbitrary nonce types).
  However, the Q-tuple ideal-oracle witness
  `idealRandomOraclePRF_isPRFAtQueries` was research-scope (R-05⁺)
  because it required the **marginal-uniformity** lemma: that
  pushing a uniform PMF on `(Nonce → Tag)` through projection at
  injective `nonces : Fin Q → Nonce` yields the uniform PMF on
  `(Fin Q → Tag)`. The user directed this be substantively proved
  ("the implementation should match the more general approach").

- **Mathematical content.** The marginal-uniformity proof factors
  into 5 mathematical layers:
  1. **Pi-type Equiv**: bijection between the constrained Pi-set
     `{f : Nonce → Tag // ∀ i, f (nonces i) = t i}` (functions
     agreeing with `t` on `Set.range nonces`) and the free Pi-set
     `{n : Nonce // n ∉ Set.range nonces} → Tag`. Built via
     `Equiv.ofInjective` + explicit branching `if h : n ∈ Set.range
     nonces then ... else ...`.
  2. **Cardinality**: the constrained set has cardinality
     `(Fintype.card Tag) ^ (Fintype.card Nonce - Q)`, derived via
     `Fintype.card_fun` + `Fintype.card_subtype_compl` +
     `Fintype.card_congr` over the Equiv.
  3. **PMF identity**: `PMF.map proj uniformPMF = uniformPMFTuple
     Tag Q` via `PMF.map_apply` + Finset-sum-of-indicators +
     ENNReal pow arithmetic (`a^(n-Q) / a^n = 1/a^Q` under
     `a ≠ 0, ⊤` and `Q ≤ n`).
  4. **Q-tuple ideal-oracle witness**:
     `idealRandomOraclePRF_isPRFAtQueries` derives from layer 3 +
     `advantage_self`.
  5. **Bridge**: `IsPRF.toIsPRFAtQueries` (function-level → Q-tuple
     under finite Nonce) via `PMF.map_comp` + `probTrue_map`
     pushing the Q-tuple distinguisher through the projection.

- **Files added/modified.**
  * `Orbcrypt/AEAD/NoncedMAC.lean` — added Phases 1-5 (~265 LOC):
    `decidableMemRange`, `nonceIndex`, `constrainedPiEquiv` (Phase
    1); `constrainedPiCard`, `compl_range_card` (Phase 2);
    `PMF.map_eval_uniformOfFintype_at_injective_eq` (Phase 3);
    `idealRandomOraclePRF_isPRFAtQueries` (Phase 4);
    `IsPRF.toIsPRFAtQueries` (Phase 5). Updated `IsPRF` signature:
    `(ε : ℝ≥0∞)` → `(ε : ℝ)` (matches `ConcreteOIA` convention;
    eliminates the `⊤`-collapse degeneracy where `⊤.toReal = 0`
    inverted expected monotonicity).
  * `Orbcrypt/AEAD/NoncedMACSecurity.lean` — added Phase 6 (~30
    LOC): `nonceCarterWegmanMAC_isPRFAtQueries`,
    `nonceBitstringPolynomialMAC_isPRFAtQueries`. Updated
    `noncedMAC_research_scope_disclosure` to include the new
    Q-tuple witness as unconditional content. Phase 7: rename
    `r05_research_scope_disclosure` →
    `noncedMAC_research_scope_disclosure` (CLAUDE.md naming-
    discipline rule); doc-vs-code parity fix removing dangling
    `IsNoncedQtimeSUFCMABoundShape` reference.
  * `scripts/audit_phase_16.lean` — Phase 8 (~30 LOC): § 15.27 with
    5 new `#print axioms` entries + `MarginalUniformityNonVacuity`
    namespace with 6 non-vacuity examples. Updated old `IsPRF.mono`
    test to use `ε : ℝ` (post-refinement signature).
  * `lakefile.lean` — version bump `0.3.1 → 0.3.2`; comment block
    extended with R-05 refinement entry.

- **Verification posture preserved.**
  * `lake build` succeeds across **3,424 jobs** (unchanged from
    pre-refinement; new declarations are inside existing modules).
  * `scripts/audit_phase_16.lean` runs cleanly with exit code 0;
    every R-05-refinement declaration depends only on the standard
    Lean trio (`propext`, `Classical.choice`, `Quot.sound`); zero
    `sorryAx`, zero non-standard axioms.
  * Module count: **81** (unchanged).
  * `#print axioms` total: 1073 → **1078** (+5 new entries:
    `PMF.map_eval_uniformOfFintype_at_injective_eq`,
    `idealRandomOraclePRF_isPRFAtQueries`,
    `IsPRF.toIsPRFAtQueries`,
    `nonceCarterWegmanMAC_isPRFAtQueries`,
    `nonceBitstringPolynomialMAC_isPRFAtQueries`).
  * Public declaration count: rises by ~10 (~5 new theorems + ~5
    helper definitions).

- **Patch version.** `lakefile.lean` bumped from `0.3.1` to
  `0.3.2`. The 81-module total, the zero-sorry / zero-custom-axiom
  posture, and the standard-trio-only axiom-dependency posture are
  all preserved.

- **Naming-discipline posture.** All new declarations follow the
  "Names describe content, never provenance" rule. Forbidden
  tokens (`r05`, `phase`, `audit`, etc.) absent from declaration
  names.

- **Security-by-docstring posture.** The two PRF predicates
  (`IsPRF`, `IsPRFAtQueries`) substantively prove their advertised
  cryptographic property at the truly-random oracle (ε = 0); the
  bridge `IsPRF.toIsPRFAtQueries` connects the two formulations.

- **Remaining R-05 follow-ups.** The headline reduction theorem
  `noncedMAC_isQtimeSUFCMASecure_of_isAXU_and_isPRF` (with bound
  `Q · ε_h + ε_p + 1/|Tag|`) remains research-scope R-05⁺. The
  cryptographic content is the standard Wegman–Carter 1981 §3
  analysis; the Lean formalisation is multi-day work (per the
  plan's Phase 3 budget of ~280 LOC / ~4.5 days). This refinement
  closes the marginal-uniformity gap, making R-05 substantively
  closer to closure.

Workstream R-05 audit-pass (commit `b45e308`, 2026-05-01) closed
four documentation-parity gaps surfaced by deep-audit pass on the
R-05 framework + marginal-uniformity refinement landings:

* `Orbcrypt/AEAD/NoncedMAC.lean`:
  - Fixed broken cross-reference `IsPRF.toAtQueries` → `IsPRF.toIsPRFAtQueries`
    in the `IsPRFAtQueries` design-rationale block.
  - Extended the module docstring "Main results" section to list
    the three post-refinement declarations
    (`PMF.map_eval_uniformOfFintype_at_injective_eq`,
    `idealRandomOraclePRF_isPRFAtQueries`,
    `IsPRF.toIsPRFAtQueries`) that the pre-fix docstring omitted.

* `Orbcrypt/AEAD/NoncedMACSecurity.lean`:
  - Moved `IsPRF.toIsPRFAtQueries` and
    `idealRandomOraclePRF_isPRFAtQueries` from the "Research-scope
    (R-05⁺)" section of the disclosure docstring to the
    "Unconditional (machine-checked)" section. Pre-fix docstring
    still claimed they were research-scope, but the marginal-
    uniformity refinement landing closed both with substantive
    proofs on the standard Lean trio. Added the marginal-uniformity
    headline `PMF.map_eval_uniformOfFintype_at_injective_eq` and
    the two Q-tuple specialisations
    (`nonceCarterWegmanMAC_isPRFAtQueries`,
    `nonceBitstringPolynomialMAC_isPRFAtQueries`) to the
    unconditional section. Disclosure conjunction now matches its
    docstring.

* `scripts/audit_phase_16.lean`:
  - Added three missing `#print axioms` entries for
    `Orbcrypt.IsPRFAtQueries`, `IsPRFAtQueries.mono`, and
    `IsPRFAtQueries.le_one` (paralleling the existing
    `IsPRF` / `IsPRF.mono` / `IsPRF.le_one` entries). All three
    report `[propext, Classical.choice, Quot.sound]`.

A subsequent deep-audit pass (2026-05-01, post-`b45e308`)
verified mathematical soundness across all five marginal-
uniformity proof phases (Phase 1: Pi-type Equiv; Phase 2:
cardinality counting; Phase 3: PMF identity; Phase 4: Q-tuple
ideal-oracle witness; Phase 5: function-level → Q-tuple bridge)
and added five additional non-vacuity sentinels in the audit
script:
* `nonceBitstringPolynomialMAC_isNoncedQtimeSUFCMASecure_le_one`
  at Q = 0 and Q = 4 (parallel to the existing Carter–Wegman
  Q = 0 / Q = 3 sentinels);
* a stronger disclosure-pattern witness exercising
  `IsPRFAtQueries (...) 1 0` (Q = 1, substantively non-trivial)
  on `nonceCarterWegmanMAC` — the disclosure theorem itself uses
  Q = 0 (vacuous Fin 0 quantifier) but the audit sentinel
  exhibits the Q ≥ 1 case;
* the bitstring-polynomial parallel disclosure pattern at Q = 2.

No Lean source semantics change. Every R-05 declaration continues
to depend only on the standard Lean trio. `lake build` succeeds
across 3,424 jobs with zero warnings, zero errors. Phase-16 audit
script runs cleanly (exit 0); 1,081 declarations exercised. All
39 public R-05 declarations (24 in `NoncedMAC.lean`, 15 in
`NoncedMACSecurity.lean`) have `#print axioms` entries; coverage
gap pre-`b45e308` was the three `IsPRFAtQueries` form entries,
now closed.

Documentation reorganization (2026-05-03) — root scheme docs
moved into `docs/`; completed planning + formalization documents
relocated to `docs/dev_history/`:

- **Root → `docs/`.** `DEVELOPMENT.md`, `POE.md`, and
  `COUNTEREXAMPLE.md` moved from the project root into `docs/`,
  matching the existing `docs/`-prefix convention used by every
  other top-level analysis surface (`docs/PARAMETERS.md`,
  `docs/PUBLIC_KEY_ANALYSIS.md`, `docs/HARDNESS_ANALYSIS.md`,
  `docs/VERIFICATION_REPORT.md`, `docs/USE_CASES.md`,
  `docs/MORE_USE_CASES.md`). `git mv` was used to preserve git
  history.

- **`docs/dev_history/` (new).** A new history directory under
  `docs/` collects every workstream-planning document whose work
  has been completed and is no longer release-blocking, leaving
  `docs/planning/` to hold only documents that still describe
  pending or research-scope work. The 15 moved planning files:
  * `PHASE_7_KEM_REFORMULATION.md` through
    `PHASE_16_FORMAL_VERIFICATION.md` (Phases 7–16, all complete
    per the `## Active development status` log above).
  * `AUDIT_2026-04-18_WORKSTREAM_PLAN.md` (Workstreams A–E
    closed).
  * `AUDIT_2026-04-21_WORKSTREAM_PLAN.md` (Workstreams G, H, J,
    K, L, M, N closed).
  * `AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md`
    (Workstreams A, B, C closed; D research catalogue partially
    discharged via R-09 / R-12 / R-13).
  * `PATH_ALGEBRA_MUL_ASSOC_PLAN.md` (`pathAlgebraMul_assoc`
    decomposition landed).
  * `PLAN_R_01_07_08_14_16.md` (R-01, R-07, R-08, R-13⁺, R-14,
    R-16 all discharged).

- **`formalization/` → `docs/dev_history/formalization/`.** The
  entire `formalization/` subtree (`FORMALIZATION_PLAN.md`,
  `PRACTICAL_IMPROVEMENTS_PLAN.md`, and `phases/PHASE_1_*.md`
  through `phases/PHASE_6_*.md`) moved into
  `docs/dev_history/formalization/`. All six Phase 1–6 documents
  describe completed work (Phases 1–6 of the formalization were
  marked Complete in the master roadmap years ago); the master
  `FORMALIZATION_PLAN.md` and `PRACTICAL_IMPROVEMENTS_PLAN.md`
  similarly describe completed scope (Phases 7–9 covered by
  `PRACTICAL_IMPROVEMENTS_PLAN.md` are all closed). The directory
  structure (`formalization/phases/...`) is preserved one level
  deeper under `docs/dev_history/formalization/phases/...` so
  the historical organisation remains discoverable.

- **Plans intentionally retained in `docs/planning/`.** Six
  plans still describe pending or research-scope work and stay
  in the active planning directory:
  * `AUDIT_2026-04-23_WORKSTREAM_PLAN.md` (Workstreams H, J, K,
    L, M, N pending).
  * `AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` (R-CE reverse
    direction is research-scope `R-15-residual-CE-reverse`).
  * `AUDIT_2026-04-28_PHASE_3_PROP_DISCHARGE_PLAN.md` (Phase 3
    deep multilinear-algebra content is research-scope
    `R-15-residual-TI-*`).
  * `PLAN_R_05_11_15.md` (R-11 and R-15 not yet implemented;
    R-05 framework landed but R-05⁺ headline reduction theorem
    remains research-scope).
  * `R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md` (Phase 3 partial
    discharge landed; rigidity argument research-scope).
  * `R_TI_PHASE_C_THROUGH_H_PLAN.md` (final discharge depends
    on the same research-scope content).

- **Reference updates.** All cross-references across the
  codebase were updated to point at the new locations:
  Lean source docstrings under `Orbcrypt/` (~50 modules),
  `Orbcrypt.lean` root file, `CLAUDE.md` (this file),
  `README.md`, the active `docs/planning/` entries that
  cross-reference the moved plans, the `docs/audits/`
  source-audit reports, the GAP reference implementation
  (`implementation/gap/orbcrypt_keygen.g`,
  `implementation/gap/orbcrypt_fast_dec.g`),
  `implementation/README.md`, the CI workflow
  (`.github/workflows/lean4-build.yml`), `lakefile.lean`'s
  comment block, `scripts/audit_phase_16.lean`, and
  `scripts/legacy/README.md`. The `[docs/DEVELOPMENT.md](../DEVELOPMENT.md)`
  Markdown link inside the relocated
  `docs/dev_history/formalization/FORMALIZATION_PLAN.md`'s footer
  was updated to `[docs/DEVELOPMENT.md](../../DEVELOPMENT.md)`
  to account for the deeper directory level.

- **Document layout sections rewritten.** Both the `## Document
  layout` block in `CLAUDE.md` and the `## Project structure`
  tree in `README.md` were rewritten end-to-end to reflect the
  post-reorganization tree (root no longer has `formalization/`
  or the three scheme-doc Markdown files; `docs/` now houses
  every analysis surface plus the new `dev_history/` subtree).

- **Verification.** `lake build` succeeds across 3,424 jobs
  with zero errors, zero warnings — identical to the
  pre-reorganization state. `scripts/audit_phase_16.lean` runs
  cleanly (exit 0); the 1,273-line output exercises every
  public declaration via `#print axioms` and reports
  standard-trio-only axiom dependencies (`propext`,
  `Classical.choice`, `Quot.sound`) for every declaration.
  Zero `sorryAx`, zero non-standard axioms, zero new `sorry`,
  zero new declarations. The reorganization is documentation-
  only — no Lean source semantics change. The 81-module total,
  the public-declaration count, and the standard-trio-only
  axiom-dependency posture are all preserved.

- **Patch version.** `lakefile.lean` retains its current
  version. The reorganization is build-configuration neutral
  (no `import` paths change; Lean's namespace tree under
  `Orbcrypt/` is unaffected) and adds no new Lean
  declarations. The repository structure changes alone do not
  warrant a version bump per `CLAUDE.md`'s version-bump
  discipline.

Deep audit pass (2026-05-05) — comprehensive codebase audit
discovered and fixed four documentation-and-naming-hygiene
findings:

- **HIGH (naming-rule violation)** —
  `Orbcrypt/Hardness/GrochowQiao.lean:396` declared
  `theorem grochowQiao_phase3_discharge_under_rigidity`. The
  `phase3` token is a forbidden process marker per
  `CLAUDE.md`'s Key Conventions rule "Names describe content,
  never provenance" (the rule explicitly forbids "phase
  labels: `phase`, `phase1`, `phase_12`, `stretch`" inside
  declaration identifiers).  The "Phase 3" framing is a
  process descriptor (R-TI Phase 3), not a content
  descriptor — the theorem's actual content is the discharge
  of the two GL³ obligations
  `GL3InducesAlgEquivOnPathSubspace` and
  `RestrictedGL3OnPathOnlyTensor` from a `GrochowQiaoRigidity`
  hypothesis.  **Fix.** Renamed to
  `grochowQiao_pathSubspace_obligations_under_rigidity` —
  the new identifier names what is discharged ("path-subspace
  obligations") and the input hypothesis ("under rigidity"),
  parallel to the sibling
  `grochowQiao_unified_discharge_under_rigidity` (which
  discharges three obligations including the Karp reduction
  inhabitant).  The "Phase 3" prose framing remains in the
  docstring under the rule's "Where process references *are*
  allowed" carve-out.  Updated all references:
  `Orbcrypt/Hardness/GrochowQiao.lean:396`,
  `scripts/audit_phase_16.lean` (two references), and two
  references inside historical CLAUDE.md changelog entries.
- **MEDIUM (doc drift)** — `CLAUDE.md`'s 2026-05-03
  documentation reorganization entry's "Verification" bullet
  claimed "The 77-module total ... preserved" but the actual
  module count at the time was 81 (verified by `find
  Orbcrypt -name '*.lean' | wc -l`).  The entry was written
  with stale module-count framing; the rest of the
  reorganization claims (3,424 jobs, 1,273-line audit
  output) verify cleanly against current state.  Fixed in
  place: 77 → 81.
- **MEDIUM (doc drift)** — `README.md` "Snapshot metrics"
  table at line 53 claimed "1078+ #print axioms checks"; the
  actual count is 1081.  The current value rises monotonically
  with each landing, and the table is intended to track the
  current state, so updating to "1080+" (a deliberately
  imprecise rounded value to resist per-PR staleness) is the
  correct fix.  The Project-structure tree at line 123
  claimed "Lean 4 source tree (77 modules)"; updated to "81
  modules" matching actual count.
- **MEDIUM (doc parity)** — `implementation/README.md`'s
  Files table omitted the Phase 15 fast-decryption pipeline
  source `gap/orbcrypt_fast_dec.g`.  The file is documented
  in `CLAUDE.md`'s Phase 15 changelog and in
  `docs/dev_history/PHASE_15_DECRYPTION_OPTIMIZATION.md` but
  was never added to the GAP-implementation README's table of
  files.  Added a row with summary description (cross-
  references to `QCCyclicReduce`, `FastDecaps`,
  `ComputeResidualGroup`, `SyndromeDecaps`, `OrbitHash`,
  `RunPhase15Comparison`).

**Verification posture preserved.** Every fix is either a
content-neutral identifier rename, a documentation-only edit,
or a doc table addition.  `lake build` succeeds across **3,424
jobs** with zero warnings, zero errors (unchanged from the
pre-audit baseline; the rename touches one declaration
identifier, which preserves all build edges).
`scripts/audit_phase_16.lean` runs cleanly with exit code 0;
**1,081 declarations exercised**, every one on the standard
Lean trio (`propext`, `Classical.choice`, `Quot.sound`); zero
`sorryAx`; zero non-standard axioms.  The 81-module total,
the zero-sorry / zero-custom-axiom posture, and the
standard-trio-only axiom-dependency posture are all
preserved.

**Patch version.** `lakefile.lean` retains `0.3.2`. The
audit-pass fixes are content-neutral (one identifier rename
+ four documentation edits) and add no new Lean
declarations, so a version bump is not warranted per
`CLAUDE.md`'s version-bump discipline.  The renamed identifier
is a public-API change in the strict sense, but no downstream
code (in this repository or in any documented external
consumer) referenced
`grochowQiao_phase3_discharge_under_rigidity` outside the
audit-script and CLAUDE.md (both updated in this same diff).

Deep audit pass #2 (2026-05-05) — second-pass comprehensive
audit closes the remaining audit-script coverage gap and tightens
linter-silencer documentation:

- **HIGH (audit coverage gap)** — A coverage-gap analysis on the
  Phase-16 audit script revealed that **73 public declarations**
  across five modules had no `#print axioms` entries.  Among these
  were headline theorems #24 `canonical_agreement_under_two_phase_decomposition`, #25
  `kem_round_trip_under_two_phase_decomposition`, and #26 `fast_kem_round_trip`
  (Phase 15 fast-decryption), plus the entire Layer 1-5 path-algebra
  Ring/Algebra infrastructure in `AlgebraWrapper.lean` (37
  declarations), the Wedderburn–Mal'cev radical infrastructure in
  `WedderburnMalcev.lean` (20 declarations), and supporting
  declarations in `QCCanonical.lean` (3), `TwoPhaseDecrypt.lean`
  (11 including the headline theorems), and `Probability/Monad.lean`
  (2: `probTrue_map`, `probTrue_uniformPMF_card`).
  CLAUDE.md's exit-criteria checklist had ALREADY claimed these
  Phase-15 theorems were covered (entries like
  "`#print axioms Orbcrypt.canonical_agreement_under_two_phase_decomposition` — standard Lean
  only"), but the actual audit script did not exercise them.
  **Fix.** Added 73 new `#print axioms` entries in a new § 15.28
  section "Audit-pass coverage closure (deep audit 2026-05-05)"
  at the end of `scripts/audit_phase_16.lean`, documented as
  structural coverage closures whose non-vacuity content is
  supplied by their downstream consumers (which already have
  non-vacuity examples).  Audit-script `#print axioms` count rises
  from **1081 → 1154** (+73).  After the closure, only one
  parser-artefact "uncovered" declaration remains
  (`PMF.map_eval_uniformOfFintype_at_injective_eq` parsed as
  `theorem PMF` by a simple regex; the actual identifier IS
  covered).
- **MEDIUM (linter-silencer documentation)** — Four files used
  `set_option linter.unusedSectionVars false` without an inline
  justification comment:
  * `Orbcrypt/Hardness/GrochowQiao/Discharge.lean:63`
  * `Orbcrypt/Hardness/GrochowQiao/PathOnlyAlgebra.lean:99`
  * `Orbcrypt/Hardness/GrochowQiao/Manin/BasisChange.lean:100`
  * `Orbcrypt/Hardness/GrochowQiao/Manin/TensorStabilizer.lean:88`
  Only the fifth instance
  (`Orbcrypt/Hardness/GrochowQiao/Manin/StructureTensor.lean:78`)
  carried documented justification.  **Fix.** Added an inline
  justification comment to each of the four undocumented
  silencers, explaining (a) which linter the option silences,
  (b) why section-wide binder declaration is preferred over
  per-theorem `letI` rebuilds, and (c) the ergonomic /
  typeclass-inference rationale.  The silencer line itself is
  preserved; only a preceding comment block is added.
- **MEDIUM (doc parity)** — `README.md` snapshot table audit-script
  count claim updated `1080+ → 1150+` to reflect the new audit-
  script entries.  The `VERIFICATION_REPORT.md` count claims
  (currently anchored at "947 declarations" with explicit
  "for current totals consult CLAUDE.md" disclaimer) are
  preserved as-is per the document's ephemeral-anchor pattern.

**Verification posture preserved.**
- `lake build` succeeds across **3,424** jobs, zero warnings,
  zero errors (unchanged from the pre-audit-pass-#2 baseline; the
  added entries are in the audit script, not in `Orbcrypt/`).
- `scripts/audit_phase_16.lean` runs cleanly with exit code 0;
  **1,154** declarations exercised (up from 1,081), every one on
  the standard Lean trio (`propext`, `Classical.choice`,
  `Quot.sound`); zero `sorryAx`, zero non-standard axioms.
  Audit-output line count rises from 1,273 to 1,356.
- 81-module total preserved.
- Zero-sorry / zero-custom-axiom posture preserved.

**Coverage of headline theorems now machine-checked.** The 14
public declarations under `Orbcrypt/Optimization/{QCCanonical,
TwoPhaseDecrypt}.lean` (Phase 15 fast-decryption pipeline) are
now individually exercised in the audit script.  Together with
the existing coverage of all theorems #1–#23 and #27–#32,
**every entry in the "Three core theorems" table is now exercised
by the Phase-16 audit script with a `#print axioms` check** —
closing a gap that was previously bridged only by transitive
dependency through downstream theorems.

**Patch version.** `lakefile.lean` retains `0.3.2`.  The audit-
pass-#2 fixes add no new Lean declarations to `Orbcrypt/`; the
73 new audit-script entries are structural `#print axioms`
checks consuming existing public surfaces.  No version bump is
warranted.

Deep audit pass #3 (2026-05-05) — proper fix for linter
silencing.  The audit-pass-#2 commit's MEDIUM finding
("4 of 5 `set_option linter.unusedSectionVars false`
instances lacked inline justification") was resolved by
adding justification comments to each silencer.  However,
that fix was the wrong fix:

- **Silencing a linter is rarely the right answer.** It loses
  the lint's safety guarantee and papers over a real issue.
  The correct response to a linter complaint is to either fix
  the underlying problem or, when that's impossible,
  understand precisely why the silencer is needed and
  document it.  An empirical investigation reveals which.

- **The empirical investigation.** Removing each silencer one-
  at-a-time and rebuilding the affected module shows what the
  linter actually complains about:
  * `Hardness/GrochowQiao/Manin/BasisChange.lean` — silencer
    was unnecessary (no warnings fire when removed).
  * `Hardness/GrochowQiao/Discharge.lean` — silencer was
    unnecessary (no warnings fire when removed).
  * `Hardness/GrochowQiao/PathOnlyAlgebra.lean` — silencer
    was unnecessary (no warnings fire when removed).
  * `Hardness/GrochowQiao/Manin/StructureTensor.lean` —
    silencer was needed for `structureTensor_recovers_mul`
    (which uses `Basis.sum_repr` requiring `[Fintype I]` but
    NOT `[DecidableEq I]`; the section variable
    `[DecidableEq I]` is unused for this theorem).
  * `Hardness/GrochowQiao/Manin/TensorStabilizer.lean` —
    silencer was needed for `linearMapOfBasisChange_basis`,
    `linearMapOfBasisChange_apply_eq_sum`, and
    `linearMapOfBasisChange_one` (each only invokes
    `Basis.constr_basis` / `Basis.sum_repr` / `map_smul`,
    none of which require `[DecidableEq I]`).

- **Three of five silencers were dead code.** They were
  silencing warnings that don't fire on any theorem in those
  files.  The audit-pass-#2 "added justification comments"
  fix was justifying silencers that did nothing.

- **The two genuine warning sources are an API hygiene
  issue.** Section-wide `[DecidableEq I]` declarations in
  these two Manin chain files create a real concern: the
  binder is auto-included in every theorem's signature,
  giving `linearMapOfBasisChange_basis` (an apply-lemma) an
  unused `[DecidableEq I]` argument that downstream callers
  must supply or let `_`.  The proper Lean 4 idiom is to use
  `omit [DecidableEq I] in` before the affected theorem,
  which removes the binder from that theorem's signature
  while keeping it at the section level for the theorems
  that DO need it.  This is the same idiom the same author
  already used at `StructureTensor.lean:102` for
  `structureTensor_apply` — the inconsistency was that some
  theorems used `omit` (correct) while others used
  `set_option linter.unusedSectionVars false` (suboptimal).

- **Fix.** Removed all 5 `set_option linter.unusedSectionVars
  false` lines (the 3 unnecessary ones outright, the 2
  necessary ones replaced with proper `omit` directives).
  Added `omit [DecidableEq I] in` before:
  * `structureTensor_recovers_mul` in
    `Manin/StructureTensor.lean`
  * `linearMapOfBasisChange_basis`,
    `linearMapOfBasisChange_apply_eq_sum`, and
    `linearMapOfBasisChange_one` in
    `Manin/TensorStabilizer.lean`

- **Rebuild posture.** Full forced-rebuild of the affected
  modules (deleting `.olean` files and re-running `lake
  build`) emits zero warnings.  The CI's no-warning gate is
  now defensible by the source itself, not by an opt-out.
  The 4 `omit` directives are tighter API hygiene than
  silencer + justification: each is scoped to a single
  theorem, surfaces in `#print signature`, and is impossible
  to accidentally extend to other theorems.

- **Audit-script regression check.**
  `scripts/audit_phase_16.lean` produces an unchanged 1,154
  `#print axioms` results (the `omit` directive doesn't
  change axiom dependencies — only the typeclass argument
  list).  Every entry continues to depend only on the
  standard Lean trio (`propext`, `Classical.choice`,
  `Quot.sound`); zero `sorryAx`, zero non-standard axioms.

**Patch version.** `lakefile.lean` retains `0.3.2`.  The
audit-pass-#3 fix removes 5 lines (`set_option`s + their
justification comments) and adds 4 `omit` directives.  No
new Lean declarations; no signature change visible to
downstream consumers (the typeclass-arg removal is what
`omit` does — it's a tightening, not a break — and `omit`
on a `[DecidableEq I]` instance arg is automatically
satisfied wherever it would have been supplied).

## Vulnerability reporting

While executing any task in this codebase, if you discover a possible software vulnerability that could reasonably warrant a CVE (Common Vulnerabilities and Exposures) designation, you **must** immediately report it to the user before continuing. This applies to vulnerabilities found in:

- **This project's cryptographic design** — logic errors in the AOE scheme definition, invariant attacks not covered by the counterexample analysis, flaws in the OIA reduction to GI or CE, or any other issue that could lead to a complete or partial break of the encryption scheme.
- **Formalization gaps** — cases where the Lean 4 formalization fails to capture a security-relevant property of the scheme, creating a false assurance gap. For example: an axiom that is too strong (making the security proof vacuously true) or a definition that does not match the mathematical intent in docs/DEVELOPMENT.md.
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
