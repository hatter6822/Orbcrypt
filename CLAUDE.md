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
    TwoPhaseDecrypt.lean              TwoPhaseDecomposition, two_phase_correct, two_phase_kem_correctness (Phase 15.3 / 15.5)
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
  (TwoPhaseDecomposition predicate, two_phase_correct,
   full_canon_invariant, two_phase_invariant_under_G,
   two_phase_kem_decaps, two_phase_kem_correctness,
   IsOrbitConstant, orbit_constant_encaps_eq_basePoint)
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
docs/
  planning/
    PHASE_11_GAP_PROTOTYPE.md         Weeks 21-26: GAP reference implementation (9 work units)
    PHASE_12_HARDNESS_ALIGNMENT.md    Hardness reduction alignment
    PHASE_13_PUBLIC_KEY_EXTENSION.md  Public-key extension
    PHASE_14_PARAMETER_SELECTION.md   Parameter selection optimization
    PHASE_15_DECRYPTION_OPTIMIZATION.md  Decryption optimization (C/C++)
    PHASE_16_FORMAL_VERIFICATION.md   Extended formal verification
docs/
  HARDNESS_ANALYSIS.md                LESS/MEDS alignment, reduction chain, hardness comparison table
  PUBLIC_KEY_ANALYSIS.md              Phase 13 public-key feasibility analysis (oblivious sampling, KEM agreement, CSIDH-style)
  PARAMETERS.md                       Phase 14 parameter recommendations (3 tiers × 4 security levels)
  VERIFICATION_REPORT.md              Phase 16 end-to-end verification report (sorry audit, axiom audit, headline-results table, exit-criteria checklist)
  benchmarks/
    results_80.csv                    Phase 14 sweep + tier rows, λ = 80
    results_128.csv                   Phase 14 sweep + tier rows, λ = 128
    results_192.csv                   Phase 14 sweep + tier rows, λ = 192
    results_256.csv                   Phase 14 sweep + tier rows, λ = 256
    comparison.csv                    Cross-scheme comparison (AES / Kyber / BIKE / HQC / McEliece / LESS / HGOE)
implementation/
  README.md                           GAP prototype installation, usage, reproducibility guide
  gap/                                GAP source files for HGOE reference implementation
scripts/
  audit_phase_16.lean                 Phase 16 consolidated `#print axioms` audit script
  audit_print_axioms.lean             Per-headline `#print axioms` script (Workstream A historical baseline)
  audit_b_workstream.lean             Workstream B audit script (historical, F-02 + F-15)
  audit_c_workstream.lean             Workstream C audit script (historical, F-07)
  audit_d_workstream.lean             Workstream D audit script (historical, F-08 + F-16)
  audit_e_workstream.lean             Workstream E audit script (historical, F-01 + F-10 + F-11 + F-17 + F-20)
  setup_lean_env.sh                   Lean environment setup with elan SHA-256 verification
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
    example, `two_phase_kem_correctness` may be cited as
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
    `DEVELOPMENT.md` do not carry prose claims that exceed what the
    Lean content delivers.

  *Rationale.* The release-messaging gap flagged as CRITICAL finding
  X-01 in the 2026-04-23 pre-release audit would have let an external
  reviewer read `docs/VERIFICATION_REPORT.md`'s pre-audit "Release
  readiness" section and conclude that `authEncrypt_is_int_ctxt`,
  `carterWegmanMAC_int_ctxt`, `two_phase_correct`, and
  `two_phase_kem_correctness` were standalone machine-checked
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

    **Where process references *are* allowed.** Process markers may appear in prose that lives *outside* the declaration identifier: (a) in `/-- … -/` docstrings as traceability notes ("`audit F-02 / Workstream B1`" is fine in a docstring); (b) in `-- ============================================================================` section banners that group a block of related declarations; (c) in commit messages, branch names, PR titles, and planning documents under `docs/planning/`; (d) in `CLAUDE.md` / `formalization/FORMALIZATION_PLAN.md` / `docs/audits/` change logs. The boundary is sharp: the docstring may say "added in Workstream B3," the identifier may not.

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
| 2 | **Invariant Attack** | If a G-invariant function separates two message orbits, there exists an adversary `A` with `hasAdvantage scheme A` (i.e. a specific `(g₀, g₁)` pair on which the adversary's two guesses disagree) | `Theorems/InvariantAttack.lean` | Standalone | Machine-checked proof of the vulnerability from COUNTEREXAMPLE.md. The theorem's **formal conclusion** is `∃ A : Adversary X M, hasAdvantage scheme A` — existence of one distinguishing adversary — **not** a quantitative "advantage = 1/2" claim in either the two-distribution or centred conventions (see `Probability/Advantage.lean` and the `invariant_attack` docstring for the three-convention catalogue: under a separating G-invariant, deterministic advantage = 1, two-distribution advantage = 1, centred advantage = 1/2). Informal shorthand: "complete break under a separating G-invariant". A quantitative probabilistic lower-bound analysis would produce a cross-orbit advantage ≥ a bound determined by the invariant's separation behaviour; that analysis is research-scope R-01 (audit 2026-04-23 finding V1-4 / D13) |
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
| 24 | **Two-Phase Correctness** | `two_phase_correct : can_full.canon (g • x) = can_residual.canon (can_cyclic.canon (g • x))` (given `TwoPhaseDecomposition`) | `Optimization/TwoPhaseDecrypt.lean` | Conditional | The fast (cyclic ∘ residual) canonical form agrees with the full canonical form on every ciphertext `g • x` **when** `TwoPhaseDecomposition` holds. The theorem is a conditional that documents the strong "fast = slow" agreement property; it is **not** the actual GAP correctness story — post-landing audit empirically confirmed that `TwoPhaseDecomposition` **fails on the default GAP fallback group** because lex-min and the residual transversal action don't commute (self-disclosed in `Optimization/TwoPhaseDecrypt.lean`'s module docstring). The non-vacuous sibling is `fast_kem_round_trip` (row #26), which captures the actual production-correctness story via orbit-constancy of the fast canonical form. Audit 2026-04-23 finding V1-2 / L-03 / D2 (Phase 15.5) |
| 25 | **Two-Phase KEM Correctness (conditional)** | `two_phase_kem_correctness : kem.keyDerive (can_residual.canon (can_cyclic.canon (encaps kem g).1)) = (encaps kem g).2` | `Optimization/TwoPhaseDecrypt.lean` | Conditional | Decapsulation via the fast path recovers the encapsulated key WHEN the two-phase decomposition holds (composes `two_phase_kem_decaps` with `kem_correctness`). **Same hypothesis as row #24**: the GAP implementation does NOT discharge `TwoPhaseDecomposition` because lex-min and the residual transversal action don't commute — this theorem is a conditional that documents the strong agreement property, not the actual GAP correctness story. The non-vacuous sibling is `fast_kem_round_trip` (row #26). Audit 2026-04-23 finding V1-2 / L-03 (Phase 15.3 / 15.5) |
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
| 1 | Project Scaffolding | 1 | 4 | 4.5h | `formalization/phases/PHASE_1_PROJECT_SCAFFOLDING.md` | Complete |
| 2 | Group Action Foundations | 2-4 | 11 | 28h | `formalization/phases/PHASE_2_GROUP_ACTION_FOUNDATIONS.md` | Complete |
| 3 | Cryptographic Definitions | 5-6 | 8 | 18h | `formalization/phases/PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md` | Complete |
| 4 | Core Theorems | 7-10 | 16 | 33h | `formalization/phases/PHASE_4_CORE_THEOREMS.md` | Complete |
| 5 | Concrete Construction | 11-14 | 12 | 26h | `formalization/phases/PHASE_5_CONCRETE_CONSTRUCTION.md` | Complete |
| 6 | Polish & Documentation | 15-16 | 13 | 22.5h | `formalization/phases/PHASE_6_POLISH_AND_DOCUMENTATION.md` | Complete |
| 7 | KEM Reformulation | 17-19 | 8 | ~24h | `formalization/PRACTICAL_IMPROVEMENTS_PLAN.md` | Complete |
| 8 | Probabilistic Foundations | 18-22 | 10 | ~40h | `formalization/PRACTICAL_IMPROVEMENTS_PLAN.md` | Complete |
| 9 | Key Compression & Nonce-Based Enc | 20-22 | 7 | ~18h | `formalization/PRACTICAL_IMPROVEMENTS_PLAN.md` | Complete |
| 10 | Authenticated Encryption & Modes | 22-24 | 6 | ~16h | `docs/planning/PHASE_10_AUTHENTICATED_ENCRYPTION.md` | Complete |
| 11 | Reference Implementation (GAP) | 24-26 | 9 | ~36h | `docs/planning/PHASE_11_GAP_PROTOTYPE.md` | Complete |
| 12 | Hardness Alignment (LESS/MEDS/TI) | 26-28 | 8 | ~32h | `docs/planning/PHASE_12_HARDNESS_ALIGNMENT.md` | Complete |
| 13 | Public-Key Extension | 26-30 | 7 | ~28h | `docs/planning/PHASE_13_PUBLIC_KEY_EXTENSION.md` | Complete |
| 14 | Parameter Selection & Benchmarks | 28-31 | 6 | ~20h | `docs/planning/PHASE_14_PARAMETER_SELECTION.md` | Complete |
| 15 | Decryption Optimisation (C/C++) | 30+ | TBD | ~20h | `docs/planning/PHASE_15_DECRYPTION_OPTIMIZATION.md` | Planned |
| 16 | Formal Verification of New Components | 30-36 | 10 | ~36h | `docs/planning/PHASE_16_FORMAL_VERIFICATION.md` | Complete |
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
  downstream theorem) plus `two_phase_correct`, `full_canon_invariant`,
  `two_phase_invariant_under_G`, `two_phase_kem_decaps`,
  `two_phase_kem_correctness`. Orbit-constancy layer (`IsOrbitConstant`,
  `orbit_constant_encaps_eq_basePoint`, `fast_kem_round_trip`,
  `fast_canon_composition_orbit_constant`) added by the Phase 15.3
  post-landing audit after empirically confirming that the strong
  `TwoPhaseDecomposition` does not hold for the default fallback group
  (lex-min and the residual transversal action don't commute). The
  actual GAP correctness story runs through `fast_kem_round_trip`;
  `two_phase_kem_correctness` is retained as the strong-agreement
  conditional documented at theorem #25.
- `docs/benchmarks/phase15_decryption.csv` — per-method timing table
  emitted by `WritePhase15CSV`, covering full-KEM / fast / syndrome /
  orbit-hash decapsulation speeds at the §14 balanced tier.
- Headline theorems #24 `two_phase_correct`, #25
  `two_phase_kem_correctness` (conditional), and #26
  `fast_kem_round_trip` landed with this phase; all three depend only
  on the standard Lean trio (`propext`, `Classical.choice`,
  `Quot.sound`) — see the axiom-transparency block below.
- `Orbcrypt.lean` dependency graph + axiom-transparency block extended
  with the `Optimization/` layer and nine `#print axioms` assertions
  (`two_phase_correct`, `two_phase_kem_correctness`,
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
  modules, the three new headline theorems #24 `two_phase_correct`,
  #25 `two_phase_kem_correctness` (conditional), and #26
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
see `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § 4 for the
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
building blocks. See `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md`
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
- `Orbcrypt.lean` + `CLAUDE.md` + `DEVELOPMENT.md §8.5` — (C3) new
  headline theorems #19 (`authEncrypt_is_int_ctxt`) and #20
  (`carterWegmanMAC_int_ctxt`); axiom-transparency entries listing
  their dependencies as `[propext, Quot.sound]`; §8.5 in
  `DEVELOPMENT.md` describing the MAC obligations, proof pipeline, and
  orbit-cover rationale.

Traceability: finding F-07 is now resolved. The composition gap that
previously made `INT_CTXT` unprovable (only `MAC.correct` was
available) is closed at the abstraction level; any new concrete MAC
must discharge `verify_inj` to inhabit the structure. See
`docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § 6 for the
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
abstraction level. See `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md`
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
  follow-up in `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md`
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
caveat). See `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § 8
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
- `docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` — updated
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
- `formalization/FORMALIZATION_PLAN.md` — `OIAImpliesCPA.lean` row
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
  `docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 7.1 for
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
  `DEVELOPMENT.md`, `docs/PUBLIC_KEY_ANALYSIS.md`,
  `docs/USE_CASES.md`, `docs/MORE_USE_CASES.md`,
  `docs/VERIFICATION_REPORT.md`,
  `formalization/FORMALIZATION_PLAN.md`, and
  `docs/planning/PHASE_13_PUBLIC_KEY_EXTENSION.md`.

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
`docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 7 for the
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
`docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 8 for the
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
  headline theorems (#24 `two_phase_correct`, #25
  `two_phase_kem_correctness`, #26 `fast_kem_round_trip`), their
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
    `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § E8b and
    in the 2026-04-23 plan's research catalogue as R-09;
  * **N4 (I4):** `scripts/setup_lean_env.sh` passed its audit
    with no findings.
  None of these require any source or doc change. They are
  listed here for completeness so the N1 / N5 additions are not
  misread as the full Workstream-N deliverable.

Traceability: findings I1 and I5 are resolved. See
`docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 9 for the
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
      `Orbcrypt.lean` Vacuity-map ε = 1 disclosure; `DEVELOPMENT.md`
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
      `docs/VERIFICATION_REPORT.md`, and `DEVELOPMENT.md §8.2`
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
      sloppy bound). `DEVELOPMENT.md §6.2.1` (G3) gains a paragraph
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
- `CLAUDE.md` — rows #24 (`two_phase_correct`) and #25
  (`two_phase_kem_correctness`) reclassified to **Conditional** with
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
- `DEVELOPMENT.md` — §7.1 (Hamming weight attack): explicit
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
certification. DEVELOPMENT.md §6.2.1 requires no rewrite because
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
- `DEVELOPMENT.md` — (C2) §8.2 (multi-query IND-Q-CPA discussion)
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

- **G3 — Documentation cross-links.** `DEVELOPMENT.md §6.2.1`
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
non-vacuity witnesses), `DEVELOPMENT.md`, `docs/PARAMETERS.md`,
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
  Plus the transient `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean`
  Lean stub exercising the Mathlib API at the planned types.

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

**Formalization exit criteria (all met):**
- `lake build` succeeds with exit code 0 for all 38 `Orbcrypt/**/*.lean`
  modules (Workstream C added `AEAD/CarterWegmanMAC.lean`, Workstream D
  added no new modules, Workstream E added `KEM/CompSecurity.lean` and
  `Hardness/Encoding.lean`, bringing the pre-Phase-15 total to 36;
  Phase 15 adds `Optimization/QCCanonical.lean` and
  `Optimization/TwoPhaseDecrypt.lean` for a final total of 38)
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
- `#print axioms Orbcrypt.two_phase_correct` — standard Lean only (TwoPhaseDecomposition predicate carried as a hypothesis, Phase 15.5)
- `#print axioms Orbcrypt.two_phase_kem_correctness` — standard Lean only (composes two_phase_kem_decaps with kem_correctness, Phase 15.3 / 15.5)
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
