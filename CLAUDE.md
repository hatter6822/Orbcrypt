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

The formalization machine-checks a clustered set of correctness,
security, and structural results. The full headline-theorem table —
clustered by cryptographic role (symmetric primary, hardness chain
quantitative, public-key research scaffolding, structural / integrity
API, distinct-challenge corollaries, vacuity witnesses) — lives in
[`docs/API_SURFACE.md` § "Three core theorems, by cluster"](docs/API_SURFACE.md#three-core-theorems-by-cluster).
That document is the canonical "what does the formalization deliver"
reference and is regenerable from `lake build` +
`scripts/audit_phase_16.lean` output.

The **Status** column on each row classifies the result for
**release messaging** — see "Release messaging policy" in Key
Conventions (above) for the absolute rule that governs how each
status may be cited externally.

For the historical record of how the headline-theorem set evolved
across audit cycles and workstream landings, see
[`docs/dev_history/WORKSTREAM_CHANGELOG.md`](docs/dev_history/WORKSTREAM_CHANGELOG.md).

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

The Lean 4 formalization is delivered across 16 phases (1–14 plus 16
complete; Phase 15 formalisation complete, C/C++ implementation
research-scope). The phase-by-phase table — with effort estimates,
work-unit counts, and links to per-phase planning documents —
lives in [`docs/API_SURFACE.md` § "Formalization roadmap"](docs/API_SURFACE.md#formalization-roadmap).

Per-phase planning documents are under
[`docs/dev_history/`](docs/dev_history/) and
[`docs/dev_history/formalization/phases/`](docs/dev_history/formalization/phases/).

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

## Pre-merge checks

Every PR to this branch must pass the following CI gates (configured in
`.github/workflows/lean4-build.yml`):

1. **`lake build`** — the full project builds clean (zero warnings,
   zero errors).
2. **No-`sorry` check** — the comment-aware Perl strip + `grep` returns
   empty across `Orbcrypt/`. (Comment-aware stripping handles nested
   block comments — see the W2 / I5 disclosure in the workflow file.)
3. **No-axiom check** — `grep -rEn '^axiom\s+\w+\s*[\[({:]' Orbcrypt/`
   returns empty. (OIA, KEMOIA, ConcreteOIA, etc. are `def`s, not
   `axiom`s.)
4. **`lake-manifest.json` drift check** — every direct `require ... @
   git "<rev>"` directive in `lakefile.lean` matches the corresponding
   `rev` field in `lake-manifest.json`.
5. **Hypothesis-consumption gate** — `python3
   scripts/audit_hypothesis_consumption.py` reports zero violations.
   The gate catches the "theatrical theorem" pattern: a non-
   underscored hypothesis name that the proof body never references
   (and that doesn't appear in the conclusion type or in any
   subsequent binder's type either). Tactics that consume hypotheses
   by type (`omega`, `simp`, `simp_all`, `assumption`, `aesop`,
   `decide`, `linarith`, etc.) short-circuit the per-theorem check.
   Underscored names (`_h_foo`) are exempt by convention. See the
   script's module docstring for the full algorithm and the
   `ALLOW_LIST` for documented exemptions.
6. **Phase-16 axiom-transparency audit** — `lake env lean
   scripts/audit_phase_16.lean` exits 0; every `#print axioms` line
   reports `[propext, Classical.choice, Quot.sound]` or "does not
   depend on any axioms". A hidden `sorry` in any dependency chain
   surfaces as `sorryAx` in the script's output.
7. **GAP–Lean canonical-image correspondence** — `cd
   implementation/gap && gap -q -b -c 'Read("orbcrypt_test.g");
   ok := TestLeanVectors(); Print("FINAL: ", ok); QUIT;'` prints
   `FINAL: true` and `(48/48 vectors passed)`. The gate validates
   that Lean's `CanonicalForm.ofLexMin` (under
   `bitstringLinearOrder`) agrees byte-for-byte with GAP's
   `CanonicalImage(G, support, OnSets)` on every `Bitstring n` for
   n ∈ {3, 4} under the full symmetric group and the trivial
   subgroup. The GAP install (`apt-get install gap` + `git clone -b
   v1.3.3 https://github.com/gap-packages/images ~/.gap/pkg/images`)
   is automated by `scripts/setup_lean_env.sh`'s
   `install_gap_environment` function, which runs on both the
   fast-path and the slow-path so any developer entering the
   environment gets GAP regardless of how often they re-run setup.
   The committed test-vector file
   `implementation/gap/lean_test_vectors.txt` is regenerated by
   `lake env lean scripts/generate_test_vectors.lean >
   implementation/gap/lean_test_vectors.txt` (deterministic).

An eighth check is conventionally enforced at landing time but not by CI
(because it requires `git diff` against `origin/main`):

8. **Naming-rule grep** — every newly added `def` /
   `theorem` / `structure` / `class` / `instance` / `abbrev` /
   `lemma` declaration must pass the project's "Names describe
   content, never provenance" rule (see Key Conventions § "Naming
   conventions"). Run the recipe in that section's "Enforcement at
   review time" subsection before merging.

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

**Current Phase:** Phases 1–14 + 16 Complete; Phase 15 formalisation
complete (C/C++ implementation Phase 15 itself remains research-
scope). The structural review of 2026-05-06 (plan
`docs/dev_history/AUDIT_2026-05-06_STRUCTURAL_REVIEW.md`) is in
progress.

For the **historical record** of every workstream landing, audit-
pass cleanup, and phase-completion log, see
[`docs/dev_history/WORKSTREAM_CHANGELOG.md`](docs/dev_history/WORKSTREAM_CHANGELOG.md).
That document carries the full per-workstream-snapshot prose
extracted from this `CLAUDE.md` by Workstream 5.2 of the 2026-05-06
structural review (pre-W5.2 `CLAUDE.md` was 9,061 lines; the
relocated content is ~8,200 lines).

For the **current state** of the formalization (module count,
theorem inventory, axiom transparency, version), see
[`docs/API_SURFACE.md`](docs/API_SURFACE.md) — the canonical "what
does the formalization deliver" reference.

For the **release-readiness posture** (sorry / axiom audit, headline-
results inventory, known limitations), see
[`docs/VERIFICATION_REPORT.md`](docs/VERIFICATION_REPORT.md).

New workstream snapshots from this point forward land directly in
`WORKSTREAM_CHANGELOG.md`, not in this file.

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
