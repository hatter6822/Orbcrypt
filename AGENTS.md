<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# CLAUDE.md — Orbcrypt project guidance

> This file and `AGENTS.md` must remain byte-identical below this header. When
> updating one, update both in the same commit.

## What this project is

Orbcrypt is a research-stage symmetric-key encryption scheme with formal
verification in Lean 4 using Mathlib. Security arises from hiding the
equivalence relation (orbit structure) that makes data meaningful, not from
hiding data itself. A message is the *identity* of an orbit under a secret
permutation group G ≤ S_n; a ciphertext is a uniformly random element of that
orbit. The hardness assumption (OIA) reduces to Graph Isomorphism on
Cai–Furer–Immerman graphs and to Permutation Code Equivalence.

**Status.** Phases 1–14 and Phase 16 are complete. Phase 15 formalisation is
complete; the Phase 15 C/C++ implementation remains research-scope. The
structural review of 2026-05-06 (plan
`docs/dev_history/AUDIT_2026-05-06_STRUCTURAL_REVIEW.md`) is in progress.

For state and history, see:

- `docs/API_SURFACE.md` — canonical theorem and module inventory.
- `docs/VERIFICATION_REPORT.md` — release-readiness posture.
- `docs/dev_history/WORKSTREAM_CHANGELOG.md` — per-workstream historical record.

## Build and run

```bash
# Environment setup (recommended)
./scripts/setup_lean_env.sh

# Or manually: install Lean 4 via elan, then
source ~/.elan/env

# Build the entire project
source ~/.elan/env && lake build

# Build a specific module
source ~/.elan/env && lake build Orbcrypt.GroupAction.Basic

# Download Mathlib precompiled cache (speeds up Mathlib-importing builds)
lake exe cache get
```

**Toolchain.** Lean 4 v4.30.0-rc1 (pinned in `lean-toolchain` to match
Mathlib). `scripts/setup_lean_env.sh` handles full environment setup including
elan, the Lean toolchain, the GAP install, and SHA-256 verification.

### Module build verification (mandatory)

**Before committing any `.lean` file**, verify that the specific module
compiles:

```bash
source ~/.elan/env && lake build <Module.Path>
```

For example, after modifying `Orbcrypt/GroupAction/Basic.lean`:

```bash
lake build Orbcrypt.GroupAction.Basic
```

**`lake build` (default target) is NOT sufficient.** It only builds modules
reachable from the root `Orbcrypt.lean` import file. Modules not yet imported
will silently pass `lake build` even with broken proofs. Always build the
specific module path.

## Source layout

```
Orbcrypt.lean                       Root import file (imports all submodules)
Orbcrypt/
  GroupAction/
    Basic.lean                      Orbits, stabilizers, orbit partition, orbit-stabilizer wrapper
    Canonical.lean                  Canonical forms: definition, uniqueness, idempotence
    CanonicalLexMin.lean            CanonicalForm.ofLexMin constructor
    Invariant.lean                  G-invariant functions, separating condition, orbit constancy
  Crypto/
    Scheme.lean                     AOE scheme syntax (Setup, Enc, Dec)
    Security.lean                   IND-CPA game, adversary structure, advantage definition
    CompOIA.lean                    Probabilistic OIA: ConcreteOIA, CompOIA, orbit distribution
    CompSecurity.lean               Probabilistic IND-CPA game, concrete_oia_implies_1cpa
  Probability/
    Monad.lean                      PMF wrappers: uniformPMF, probTrue, sanity lemmas
    Negligible.lean                 Negligible function definition and closure properties
    Advantage.lean                  Distinguishing advantage, triangle inequality, hybrid argument
    UniversalHash.lean              IsEpsilonUniversal, carterWegmanHash_isUniversal
  Theorems/
    Correctness.lean                Dec(Enc(m)) = m
    InvariantAttack.lean            Separating invariant ⇒ ∃ A, hasAdvantage
    AdversaryStructural.lean        hasAdvantage unfolding, invariant-from-distinct-messages
  KEM/
    Syntax.lean                     OrbitKEM structure, OrbitEncScheme.toKEM bridge
    Encapsulate.lean                encaps / decaps functions, simp lemmas
    Correctness.lean                decaps(encaps()) recovers the key
    Security.lean                   KEMAdversary, kem_key_constant_direct
    CompSecurity.lean               Probabilistic KEM security, concrete_kem_hardness_chain_implies_*
  Construction/
    Permutation.lean                S_n action on {0,1}^n, Bitstring type, Hamming weight
    BitstringSupport.lean           Bitstring↔Finset (Fin n) bijection, G-equivariance, order-preservation
    HGOE.lean                       Hidden-Group Orbit Encryption instance, correctness, weight defense
    HGOEInvariants.lean             Catalogue of G-invariants on Bitstring n beyond Hamming weight
    HGOEKEM.lean                    HGOE-KEM instantiation, scheme→KEM bridge
  KeyMgmt/
    SeedKey.lean                    Seed-based key compression, HGOEKeyExpansion spec
    Nonce.lean                      Nonce-based deterministic encryption, misuse resistance
  AEAD/
    MAC.lean                        Message Authentication Code abstraction (tag, verify, correct, verify_inj)
    MACSecurity.lean                Probabilistic SUF-CMA framework for MACs
    AEAD.lean                       Authenticated KEM: Encrypt-then-MAC, INT_CTXT, authEncrypt_is_int_ctxt
    Modes.lean                      KEM+DEM hybrid encryption, DEM structure, hybrid_correctness
    CarterWegmanMAC.lean            Deterministic Carter–Wegman MAC, carterWegmanMAC_int_ctxt
    BitstringPolynomialMAC.lean     Polynomial-evaluation MAC over F_p with bitstring messages
    NoncedMAC.lean                  Wegman–Carter nonce-MAC: hash + PRF composition with additive masking
    NoncedMACSecurity.lean          Nonce-MAC concrete specialisations and SUF-CMA bounds
  Hardness/
    CodeEquivalence.lean            CE problem, PAut group, CEOIA, GI ≤ CE reduction
    TensorAction.lean               Tensor3, GL³ MulAction, TI problem, GI ≤ TI, SurrogateTensor
    Encoding.lean                   OrbitPreservingEncoding, identityEncoding
    Reductions.lean                 ConcreteHardnessChain, *_viaEncoding props, tight_one_exists_at_s2Surrogate
    GrochowQiao.lean                Grochow–Qiao GI ≤ TI Karp reduction — top-level re-export
    GrochowQiao/                    ~26 sub-modules implementing the forward + partial reverse reduction
                                    (path algebra, Wedderburn–Malcev, structure tensor, Manin, padding, σ-extraction)
    PetrankRoth.lean                Petrank–Roth GI ≤ CE Karp reduction — forward-direction closure
    PetrankRoth/                    Sub-modules: BitLayout, MarkerForcing
  PublicKey/
    ObliviousSampling.lean          OrbitalRandomizers, obliviousSample, refreshRandomizers
    KEMAgreement.lean               Two-party OrbitKeyAgreement, kem_agreement_correctness
    CommutativeAction.lean          CommGroupAction class, csidh_exchange, CommOrbitPKE
    CombineImpossibility.lean       Combiner impossibility + probabilistic counterpart
  Optimization/
    QCCanonical.lean                QCCyclicCanonical abbrev, orbit-constancy lemmas
    TwoPhaseDecrypt.lean            TwoPhaseDecomposition, canonical agreement, kem_round_trip
implementation/
  gap/
    orbcrypt_keygen.g               7-stage HGOE key generation pipeline
    orbcrypt_kem.g                  KEM encapsulation / decapsulation
    orbcrypt_params.g               Parameter generation for all security levels
    orbcrypt_test.g                 Correctness test suite (RunTest harness)
    orbcrypt_bench.g                Benchmark harness with CSV output
    orbcrypt_sweep.g                Parameter sweep + tier-pinned rows
    orbcrypt_fast_dec.g             Fast decryption (QCCyclicReduce, FastDecaps, ...)
    lean_test_vectors.txt           Committed canonical-form test vectors (GAP–Lean cross-check input)
    orbcrypt_benchmarks.csv         Benchmark output (generated by orbcrypt_bench.g)
  README.md                         Installation, usage, reproducibility guide
scripts/
  setup_lean_env.sh                 Lean environment setup with elan SHA-256 verification
  audit_phase_16.lean               Consolidated #print axioms script (comprehensive coverage of every
                                    public declaration under Orbcrypt/**/*.lean + non-vacuity witnesses)
  audit_hypothesis_consumption.py   Hypothesis-consumption gate (CI gate #5)
  generate_test_vectors.lean        GAP–Lean test-vector generator (deterministic)
  legacy/                           Archived per-workstream audit scripts
```

Workstream / phase provenance for individual declarations and files is
recorded in `docs/dev_history/WORKSTREAM_CHANGELOG.md`. File descriptions
above describe **what the file is**, not when or by which workstream it
landed.

### Module dependency graph

High-level overview; not exhaustive. The `Hardness.GrochowQiao/` and
`Hardness.PetrankRoth/` subtrees contain ~30 further sub-modules
omitted from this diagram. See `Orbcrypt.lean` for the full import
list and `docs/API_SURFACE.md` for the headline-theorem inventory.

```
              GroupAction.Basic
              /       |        \
GroupAction.Canonical  GroupAction.Invariant
              \        |        /
        GroupAction.CanonicalLexMin
                      |
              Crypto.Scheme ─── KEM.Syntax
                    |                 |
              Crypto.Security    KEM.Encapsulate
                    |                /        \
                    |          KEM.{Correctness, Security}
                    |
   Theorems.{Correctness, InvariantAttack, AdversaryStructural}
                    |
   Construction.{Permutation, BitstringSupport, HGOE, HGOEInvariants, HGOEKEM}

   Mathlib.Probability.{PMF, Uniform}
        |
   Probability.{Monad, Negligible, Advantage, UniversalHash}
        |
   Crypto.{CompOIA, CompSecurity}   ◄── carries the OIA → IND-1-CPA quantitative reduction
        |
   KEM.CompSecurity                  ◄── KEM-layer parallel of concrete_oia_implies_1cpa

   KEM.Encapsulate + Construction.Permutation
        |
   KeyMgmt.{SeedKey, Nonce}

   AEAD.MAC ──► AEAD.{AEAD, Modes, MACSecurity, CarterWegmanMAC,
                       BitstringPolynomialMAC, NoncedMAC, NoncedMACSecurity}

   Hardness.{CodeEquivalence, TensorAction, Encoding}
        |
   Hardness.Reductions ◄── Crypto.CompOIA

   Hardness.GrochowQiao/   GI ≤ TI Karp reduction (forward + partial reverse)
   Hardness.PetrankRoth/   GI ≤ CE Karp reduction (forward-direction closure)

   PublicKey.{ObliviousSampling, KEMAgreement, CommutativeAction, CombineImpossibility}
   ◄── KEM.* + GroupAction.{Basic, Canonical}

   Optimization.QCCanonical      ◄── GroupAction.Canonical, Construction.Permutation
   Optimization.TwoPhaseDecrypt  ◄── Optimization.QCCanonical, KEM.Correctness
```

The deterministic `Crypto.OIA` Prop and the `Theorems.OIAImpliesCPA`
reduction (vacuously false on every non-trivial scheme) were deleted
in Workstream W6 of the 2026-05-06 structural review; the surviving
adversary-structural content was relocated to
`Theorems.AdversaryStructural`. The quantitative OIA → IND-1-CPA
reduction now lives in `Crypto.CompSecurity` (with its KEM parallel in
`KEM.CompSecurity`).

## Document layout

```
README.md                           Project title and tagline
LICENSE                             MIT license
CLAUDE.md                           Development guidance for Claude (this file)
AGENTS.md                           Byte-identical mirror of CLAUDE.md for non-Claude agents
lakefile.lean                       Lake build configuration (autoImplicit := false)
lean-toolchain                      Lean 4 version pin (v4.30.0-rc1)
lake-manifest.json                  Dependency lock file
.claude/settings.json               Claude Code session hook (auto-runs setup_lean_env.sh)
.github/workflows/lean4-build.yml   CI workflow (the eight pre-merge gates)
docs/
  API_SURFACE.md                    Canonical "what the formalization delivers" reference
  DEVELOPMENT.md                    Master specification
  POE.md                            High-level concept exposition
  COUNTEREXAMPLE.md                 Invariant attack analysis
  HARDNESS_ANALYSIS.md              LESS/MEDS alignment, reduction chain, comparison
  PUBLIC_KEY_ANALYSIS.md            Public-key feasibility analysis
  PARAMETERS.md                     Parameter recommendations (3 tiers × 4 security levels)
  VERIFICATION_REPORT.md            End-to-end verification report (large; see "Reading large files")
  USE_CASES.md, MORE_USE_CASES.md   Cryptographic use-case catalogues
  benchmarks/                       Sweep, tier-pinned, and cross-scheme CSVs
  planning/                         Active workstream plans (pending or research-scope)
  audits/                           Source audit reports
  research/                         Grochow–Qiao paper synthesis notes
  dev_history/                      Completed workstream / phase planning documents
    WORKSTREAM_CHANGELOG.md         Per-workstream historical record
    PHASE_*.md                      Per-phase completion records
    formalization/                  Original Lean 4 roadmap and Phase 1–6 plans
implementation/
  README.md                         GAP prototype installation, usage
  gap/                              GAP source files for the HGOE reference implementation
```

## Conventions

### Style and structure

- **`autoImplicit := false`** is enforced project-wide in `lakefile.lean`. All
  universe and type variables must be declared explicitly. This prevents
  subtle bugs from Lean auto-introducing variables.
- **Maximal Mathlib reuse.** Never redefine what Mathlib already provides.
  Wrap and re-export where convenient; the source of truth is Mathlib's
  `MulAction` framework. Import only the specific Mathlib modules needed —
  never `import Mathlib`.
- **Import discipline.** Use full paths within the project:
  `import Orbcrypt.GroupAction.Basic`. Re-export key definitions via the root
  `Orbcrypt.lean`.
- **Git practices.** One commit per completed work unit. All commits must
  pass `lake build` — never commit broken code.
- **No `axiom` / no `sorry`.** Zero custom axioms; the Orbit
  Indistinguishability Assumption is encoded as the `Prop`-valued
  `ConcreteOIA` (probabilistic, ε-bounded), **not** a Lean `axiom`. Theorems
  carry it as an explicit hypothesis (e.g.
  `theorem concrete_oia_implies_1cpa (h : ConcreteOIA scheme ε) ...`). A
  universal `axiom` would introduce inconsistency by asserting OIA for trivial
  group actions where it is provably false. The deterministic `OIA` Prop and
  its dependent chain (vacuously false on every non-trivial scheme) were
  deleted in Workstream W6 of the 2026-05-06 structural review; the
  probabilistic chain is the sole security chain. Zero `sorry` at release.

### Naming conventions

- Theorems and lemmas: `snake_case` (Mathlib style) — `orbit_disjoint_or_eq`,
  `canon_encrypt`.
- Structures, classes, namespaces: `CamelCase` — `CanonicalForm`,
  `OrbitEncScheme`.
- Type variables: capital letters by role — `G` (groups), `X` (spaces), `M`
  (messages).
- Type class instances: bracket notation — `[Group G]`, `[MulAction G X]`.
- Hypothesis names: `h`-prefixed descriptors — `hInv`, `hSep`, `hDistinct`.

**Names describe content, never provenance.** A declaration's identifier
(name of a `def` / `theorem` / `structure` / `class` / `instance` / `abbrev`
/ `lemma` / namespace) must describe *what the declaration is or proves*,
never *where in the development process it was added*. Forbidden tokens
include, non-exhaustively:

- workstream labels — `workstream`, `ws`, `wu`, and letter prefixes like
  `a1`, `b1c`, `e8a` (even embedded, e.g. `workstreamB_perQueryBound`);
- phase labels — `phase`, `phase1`, `phase_12`, `stretch`;
- audit finding ids — `audit`, `f02`, `f_15`, `finding`, `cve`;
- sub-task / work-unit numbers — `3_4`, `step1`, `task2`, `wu4a`;
- session / PR / branch references — `pr23`, `claude_`, `session_`,
  `revision2`;
- temporal markers — `old`, `new`, `v2`, `legacy`, `deprecated`, `temp`,
  `tmp`, `foo`, `bar`, `baz`, `todo`, `fixme`.

The rule applies to the full identifier, including any namespace qualifier:
`WorkstreamB.perQueryAdvantage`, `Phase4.correctness`, and
`Audit2026.hasAdvantageDistinct` are all disallowed even though their last
component reads normally. A declaration that should be private to a scope
uses `private` / `section`, not a process-marker prefix.

*Rationale.* Process markers rot: workstreams close, audits are superseded,
phases get renumbered, but the declarations persist. Downstream users reading
`perQueryAdvantage_bound_of_concreteOIA` learn what the theorem proves;
reading `b3_e8_bound_f02` they learn nothing and must chase a changelog.
Mathlib enforces the same discipline.

*Where process references are allowed.* In `/-- ... -/` docstrings as
traceability notes ("audit F-02 / Workstream B1" is fine in a docstring); in
`-- ====` section banners that group related declarations; in commit
messages, branch names, PR titles, and planning documents under
`docs/planning/`; in `CLAUDE.md` / `AGENTS.md` / `docs/dev_history/` change
logs. The boundary is sharp: the docstring may say "added in Workstream B3";
the identifier may not.

*Enforcement at review time.* Before landing any new declaration, grep the
diff for forbidden tokens:

```bash
git diff --cached -U0 -- '*.lean' \
  | grep -E '^\+(def|theorem|structure|class|instance|abbrev|lemma|noncomputable)' \
  | grep -iE 'workstream|\bws[0-9_a-z]*|\bwu[0-9_a-z]*|\bphase[0-9_]|audit|\bf[0-9]{2}\b|\bstep[0-9]|\btmp\b|\btodo\b|\bfixme\b|claude_|session_'
```

A non-empty result is a review-blocking naming violation.

### Proof style

- Prefer tactic mode for non-trivial proofs.
- Use `calc` blocks for equational reasoning chains.
- Use `have` for intermediate steps with descriptive names.
- Comment proof strategy at the top of each theorem.
- Avoid `decide` on large finite types (performance trap).

### Documentation style

- Every `.lean` file begins with a `/-! ... -/` module docstring (not
  `/-- ... -/`).
- Every public definition and theorem has a `/-- ... -/` docstring.
- Axioms include a `-- Justification: ...` comment block. (The release
  surface has zero `axiom`s; this rule applies to any future addition.)

## Absolute policies

The following three policies are non-negotiable. Violating any of them is a
release-gate failure.

### Security-by-docstring prohibition

If an identifier names a cryptographic primitive or security property — e.g.
`carterWegmanMAC`, `universalHash`, `ind_cca_secure`, `forward_secret_kem` —
the Lean code for that identifier **must formally prove the advertised
security property** (or carry it as an explicit hypothesis Prop the caller
discharges). It is **not acceptable** to name an identifier after a security
primitive and disclaim the property in a docstring. Doing so is a
security-reducing shortcut: it tricks downstream readers and consumers into
building on a name that promises more than the code delivers.

Concretely:

- If the name promises ε-universal hashing, the module must prove
  `IsEpsilonUniversal h ε` (see `Orbcrypt/Probability/UniversalHash.lean`).
- If the name promises IND-CPA security, the module must prove `IsSecure` or
  `IsSecureDistinct` (see `Orbcrypt/Crypto/Security.lean`).
- If the name promises ciphertext integrity, the module must prove
  `INT_CTXT` (see `Orbcrypt/AEAD/AEAD.lean`).

When the full security property cannot yet be proved, **rename the
identifier** to describe what the code *does* prove — e.g. a "linear hash
shape" (`linearHashOverFp`) rather than a "universal hash"
(`universalHashMAC`). Docstring disclaimers are **not** an acceptable
substitute for a rename or a proof.

### Release messaging policy

Every external claim that references an Orbcrypt Lean theorem — in a README,
paper, blog post, slide deck, marketing page, spec document, or downstream
dependency — must reproduce the theorem's **Status** classification from the
headline-theorem table in `docs/API_SURFACE.md` and cite only what the Lean
code actually proves. The formalisation carries two parallel security chains
(deterministic and probabilistic) whose theorems look superficially identical
but deliver very different content; external messaging that blurs the
distinction is a release-gate failure.

**Allowed citations.** Theorems classified **Standalone** or
**Quantitative** in the headline-theorem table. Every citation must include
the theorem name, its Status classification, and — for **Quantitative**
theorems — the ε bound together with the surrogate / encoder / keyDerive
profile in use (at ε = 1 via the trivial `tight_one_exists` witness, or at
ε < 1 via a caller-supplied hardness witness).

**Conditional citations.** Theorems classified **Conditional** may be cited
**only with their hypothesis made explicit**. For example,
`kem_round_trip_under_two_phase_decomposition` may be cited as: "under the
`TwoPhaseDecomposition` hypothesis, which does not hold on the default GAP
fallback group — the production-correctness argument runs through
`fast_kem_round_trip` via orbit-constancy." Pure Conditional citations
without the hypothesis disclosure are **forbidden**.

**Scaffolding citations (forbidden).** The pre-W6 deterministic chain
(`oia_implies_1cpa`, `kemoia_implies_secure`, `hardness_chain_implies_security`,
their K-distinct corollaries, and the deterministic combiner-impossibility
theorems) was vacuously true on every non-trivial scheme and was deleted in
W6 of the 2026-05-06 structural review. Quantitative security content now
runs through `concrete_oia_implies_1cpa`,
`concrete_hardness_chain_implies_1cpa_advantage_bound`, and their KEM-layer
parallels. Documentation that re-introduces a Scaffolding-shaped citation
must explicitly mark it historical and direct readers to the probabilistic
counterpart.

**ε = 1 disclosure.** Every Quantitative-at-ε=1 result must be cited with
the explicit phrase: "inhabited only at ε = 1 via the trivial `_one_*` /
`tight_one_exists` witness in the current formalisation; ε < 1 requires a
concrete surrogate + encoder witness (research-scope follow-up)". Applies to
`concrete_hardness_chain_implies_1cpa_advantage_bound` and
`concrete_kem_hardness_chain_implies_kem_advantage_bound` until
R-02 / R-03 / R-04 / R-05 research milestones land concrete ε < 1 witnesses.

**Status-column authority.** The Status column in `docs/API_SURFACE.md` and
the headline table in `docs/VERIFICATION_REPORT.md` are the canonical
sources of truth. A PR that adds or modifies a headline theorem — or
changes a theorem's hypothesis structure such that its Status classification
changes — **must update both documents in the same diff**.

**Documentation-vs-code parity.** Before any v1.0 release tag, run the
"Documentation-vs-code parity gates" checklist in
`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 20.3 to confirm that
`CLAUDE.md`, `AGENTS.md`, `docs/VERIFICATION_REPORT.md`, and
`docs/DEVELOPMENT.md` do not carry prose claims exceeding what the Lean
content delivers.

### Pull request authoring policy

**Forbidden in PR descriptions, bodies, and review comments:** session URLs
of the shape `https://claude.ai/code/session_*` or any equivalent
agent-harness session permalink. Session URLs point at private workspace
artefacts (the PR reader cannot open them), they rot quickly, they leak
authoring-tool internals, and they violate the names-describe-content
discipline applied to release-facing prose.

**Cite instead:**

- the audit / planning document under `docs/planning/` or
  `docs/dev_history/` (e.g.
  `docs/dev_history/PLAN_R_01_07_08_14_16.md` § R-07);
- the headline theorem name + file path (e.g.
  `combinerDistinguisherAdvantage_ge_inv_card` in
  `Orbcrypt/PublicKey/CombineImpossibility.lean`);
- the `WORKSTREAM_CHANGELOG.md` or `VERIFICATION_REPORT.md` entry that
  records the work;
- the relevant audit-script entry in `scripts/audit_phase_16.lean`.

**Scope.** Forbidden in PR bodies, PR review comments, and PR-edit `body`
arguments to `mcp__github__update_pull_request` /
`mcp__github__add_issue_comment` /
`mcp__github__add_reply_to_pull_request_comment`. Out of scope: local
commit messages (which live only in `git log`).

**Enforcement.**

1. Before invoking `mcp__github__create_pull_request` or
   `mcp__github__update_pull_request`, scan the prepared `body` string for
   the regex
   `https?://(?:www\.)?claude\.ai/code/session_[A-Za-z0-9]+` (or any
   equivalent agent-harness session-permalink shape). Strip every match
   before submission.
2. If a session URL is discovered in an already-open PR, update the body
   via `mcp__github__update_pull_request` to remove the offending
   substring. Preserve the rest of the description verbatim.
3. The scan applies on every PR-body edit, even for unrelated edits.
   Removing pre-existing session URLs is a free cleanup; never reintroduce
   them.

Earlier PRs may carry session URLs as historical artefacts; the rule is
forward-looking and not subject to retroactive scrubbing.

## Working with files

### Reading large files

Several files are large (`docs/VERIFICATION_REPORT.md` alone is ~200KB).
Always page through large files using `offset` and `limit` in ≤500-line
chunks rather than reading the whole file:

```
Read(file_path, offset=1,   limit=500)
Read(file_path, offset=501, limit=500)
```

Known large files (sizes drift; treat as approximate):

- `docs/VERIFICATION_REPORT.md` — ~200KB / ~3700 lines (the largest doc).
- `docs/DEVELOPMENT.md` — ~76KB / ~1500 lines (master specification).
- `docs/HARDNESS_ANALYSIS.md` — ~36KB / ~750 lines.
- `docs/PARAMETERS.md` — ~32KB / ~600 lines.
- `docs/PUBLIC_KEY_ANALYSIS.md` — ~28KB / ~550 lines.
- `docs/API_SURFACE.md` — ~28KB / ~400 lines.
- `docs/dev_history/formalization/FORMALIZATION_PLAN.md` — ~400 lines.
- Per-phase planning docs under `docs/dev_history/formalization/phases/` —
  ~400–1140 lines each.
- `scripts/audit_phase_16.lean` — ~6000 lines (read only when extending or
  diagnosing the axiom-transparency audit).

When editing, read only the region around the target lines
(e.g. `offset=380, limit=40`) — not the whole file. This avoids
context-window pressure and "file too large" errors.

### Editing existing files

- **Always prefer Edit over Write** for existing files. Edit only carries the
  diff; it never times out, regardless of file size.
- **Read before you Edit.** The `old_string` must match exactly, including
  whitespace and indentation.
- **One logical change per Edit call.** If three sections change, make three
  Edit calls anchored to distinct context.

### Creating or rewriting large files

The Write tool has a content-size timeout. To avoid it:

- **Never pass more than ~100 lines of content in a single Write call.**
- **For new files >100 lines**, either:
  - build incrementally: write an under-100-line skeleton, then append
    sections via successive Edit calls (each ≤80 lines), anchored to the
    previously written content; or
  - use a Bash heredoc (`cat <<'EOF' > path/to/file`) — Bash has no
    equivalent size limit.
- **Verify after writing.** `wc -l` to confirm the line count; Read the last
  few lines to confirm nothing was truncated or duplicated.
- **If a Write call times out**, do not retry with the same large content.
  Switch to incremental Edits or a heredoc.

### Handling large search and command output

Constrain output upfront — large results trigger truncation and context
pressure.

- **Grep:** use `head_limit` (e.g. `head_limit=30`); paginate with `offset`.
  Prefer `output_mode: "files_with_matches"` first to identify files, then
  switch to `content` on specific files.
- **Glob:** narrow with `path` rather than searching the whole repo.
- **Bash commands** (`lake build`, etc.): pipe through `head` or `tail` for
  likely-large output (`lake build 2>&1 | tail -80`). For very large output,
  redirect to a temp file and read it in chunks:
  ```bash
  lake build 2>&1 > /tmp/build.log
  ```
  then `Read("/tmp/build.log", offset=1, limit=500)`.

Rule of thumb: if a command or search might return more than ~100 lines, cap
it upfront.

### Background agent file-change protection

Background agents (launched via Agent with `run_in_background: true`) run
concurrently and may finish *after* the foreground agent has already
modified the same files. Stale background writes silently overwrite
foreground progress. To prevent this:

1. **Never delegate file writes to a background agent for files the
   foreground agent may also edit.** Identify every file the background
   agent might create or modify before launching. If there is any chance of
   overlap, run the agent in the foreground or restructure the work.
2. **Partition files strictly when parallel work is genuinely needed.**
   Assign each agent a disjoint set of files and document the partition in
   the prompt (e.g. "you own `Foo.lean` and `Bar.lean` only — do not modify
   any other file"). The foreground must not touch those files until the
   background agent completes.
3. **Safe background uses.** Read-only research, builds, tests, searches, or
   writes to files the foreground will not edit during this session.
4. **After a background agent returns**, check whether it touched files the
   foreground has since modified. If so, discard the background version and
   redo on top of the current foreground state.

When in doubt, run in the foreground. Sequential correctness beats parallel
speed.

## Pre-merge checks

Every PR must pass the CI gates configured in
`.github/workflows/lean4-build.yml`:

1. **`lake build`** — full project builds clean (zero warnings, zero
   errors).
2. **No-`sorry` check** — a comment-aware Perl strip removes all block
   comments before `grep` scans `Orbcrypt/`. The strip handles nested block
   comments correctly; see the inline rationale in the workflow's
   "Verify no sorry" step.
3. **No-axiom check** —
   `grep -rEn '^axiom\s+\w+\s*[\[({:]' Orbcrypt/` returns empty. OIA,
   KEMOIA, ConcreteOIA, etc. are `def`s, not `axiom`s.
4. **`lake-manifest.json` drift check** — every direct
   `require ... @ git "<rev>"` directive in `lakefile.lean` matches the
   corresponding `rev` field in `lake-manifest.json`.
5. **Hypothesis-consumption gate** —
   `python3 scripts/audit_hypothesis_consumption.py` reports zero
   violations. Catches the "theatrical theorem" pattern: a non-underscored
   hypothesis whose name the proof body never references and which doesn't
   appear in the conclusion type or any later binder. Tactics that consume
   hypotheses by type (`omega`, `simp`, `simp_all`, `assumption`, `aesop`,
   `decide`, `linarith`, etc.) short-circuit the per-theorem check.
   Underscored names (`_h_foo`) are exempt; see the script docstring and
   `ALLOW_LIST` for documented exemptions.
6. **Phase-16 axiom-transparency audit** —
   `lake env lean scripts/audit_phase_16.lean` exits 0; every
   `#print axioms` line reports `[propext, Classical.choice, Quot.sound]`
   or "does not depend on any axioms". A hidden `sorry` in any dependency
   chain surfaces as `sorryAx` in the script output.
7. **GAP–Lean canonical-image correspondence** —
   ```bash
   cd implementation/gap && gap -q -b -c \
     'Read("orbcrypt_test.g"); ok := TestLeanVectors(); Print("FINAL: ", ok); QUIT;'
   ```
   prints `FINAL: true` and `(48/48 vectors passed)`. The gate validates
   that Lean's `CanonicalForm.ofLexMin` (under `bitstringLinearOrder`)
   agrees byte-for-byte with GAP's `CanonicalImage(G, support, OnSets)` on
   every `Bitstring n` for n ∈ {3, 4} under the full symmetric group and
   the trivial subgroup. The GAP install
   (`apt-get install gap` + `git clone -b v1.3.3
   https://github.com/gap-packages/images ~/.gap/pkg/images`) is automated
   by `scripts/setup_lean_env.sh`'s `install_gap_environment` function on
   both fast and slow paths. The committed test-vector file
   `implementation/gap/lean_test_vectors.txt` is regenerated by
   `lake env lean scripts/generate_test_vectors.lean > implementation/gap/lean_test_vectors.txt`.

An eighth check is conventionally enforced at landing time but not by CI
(because it requires `git diff` against `origin/main`):

8. **Naming-rule grep** — every newly added `def` / `theorem` /
   `structure` / `class` / `instance` / `abbrev` / `lemma` declaration must
   pass the "Names describe content, never provenance" rule (see
   § Naming conventions for the grep recipe).

## Reference documents

The canonical sources of truth, by topic:

| File | Purpose |
|------|---------|
| `docs/API_SURFACE.md` | Theorem and module inventory; the headline-theorem table (clustered by cryptographic role, with **Status** classification) and formalization roadmap. Regenerable from `lake build` + `scripts/audit_phase_16.lean` output. |
| `docs/VERIFICATION_REPORT.md` | Release-readiness posture: sorry / axiom audit, headline-results table, exit-criteria checklist. |
| `docs/DEVELOPMENT.md` | Master specification: full scheme design, security proofs, hardness reductions, 7-stage pipeline. |
| `docs/POE.md` | Core intuition behind orbit encryption, isogeny variant, unifying view. |
| `docs/COUNTEREXAMPLE.md` | Why naïve constructions fail; invariant attack principle; Hamming-weight break. |
| `docs/HARDNESS_ANALYSIS.md` | LESS / MEDS alignment, full reduction chain, hardness comparison table. |
| `docs/PUBLIC_KEY_ANALYSIS.md` | Public-key feasibility analysis (oblivious sampling, KEM agreement, CSIDH-style). |
| `docs/PARAMETERS.md` | Parameter recommendations across 3 tiers × 4 security levels. |
| `docs/dev_history/WORKSTREAM_CHANGELOG.md` | Per-workstream historical record (landings, audit cleanups, phase completions). |
| `docs/dev_history/formalization/FORMALIZATION_PLAN.md` | Master Lean 4 roadmap: architecture, module dependencies, conventions, timeline. |
| `docs/dev_history/formalization/phases/PHASE_*.md` | Per-phase implementation guides (historical record). |

### Cross-document update rules

When changing behavior, theorems, or formalization status, update **in the
same PR**:

1. `docs/DEVELOPMENT.md` — if scheme design, security analysis, or
   mathematical content changes.
2. `docs/API_SURFACE.md` — if the headline-theorem inventory or Status
   classifications change.
3. `docs/VERIFICATION_REPORT.md` — if sorry/axiom posture or
   headline-results table changes.
4. `docs/COUNTEREXAMPLE.md` — if invariant attack analysis is refined.
5. `docs/POE.md` — if the concept exposition needs updating.
6. `README.md` — if project status or description changes.
7. `CLAUDE.md` **and** `AGENTS.md` (keep byte-identical below the header) —
   if development guidance, conventions, or project status changes.

Canonical ownership:

- `docs/DEVELOPMENT.md` owns the full scheme specification.
- `docs/API_SURFACE.md` owns the formalization inventory.
- `docs/dev_history/formalization/FORMALIZATION_PLAN.md` owns the Lean 4
  architecture and conventions.
- `docs/POE.md` owns the concept exposition; `docs/COUNTEREXAMPLE.md` owns
  the vulnerability analysis.

## Mathlib integration

The formalization depends heavily on Mathlib's group action library.
Familiarity with these definitions is essential.

| Mathlib name | Type | Role in Orbcrypt |
|--------------|------|------------------|
| `MulAction.orbit G x` | `Set X` | Orbit of `x` under `G` |
| `MulAction.stabilizer G x` | `Subgroup G` | Stabilizer of `x` |
| `MulAction.orbitRel G X` | `Setoid X` | Orbits as equivalence classes |
| `MulAction.orbit_eq_iff` | theorem | `orbit G x = orbit G y ↔ x ∈ orbit G y` |
| `MulAction.mem_orbit_iff` | theorem | `y ∈ orbit G x ↔ ∃ g, g • x = y` |
| `MulAction.card_orbit_mul_card_stabilizer_eq_card_group` | theorem | Orbit–stabilizer: `|orbit| * |stab| = |G|` |
| `Equiv.Perm` | type | Permutations (symmetric group) |

**Most-used Mathlib modules in the project** (run `grep -rhE '^import Mathlib'
Orbcrypt --include='*.lean' | sort -u` for the full list):

- `Mathlib.GroupTheory.GroupAction.{Defs, Quotient}` — `MulAction`, `orbit`,
  `stabilizer`, quotient-by-orbit machinery.
- `Mathlib.GroupTheory.Perm.Basic` — `Equiv.Perm` (symmetric group S_n).
- `Mathlib.Algebra.Group.Subgroup.Defs` — `Subgroup` (for G ≤ S_n).
- `Mathlib.Data.Fintype.{Basic, BigOperators, Card, EquivFin, Perm, Pi, Prod, Sets, Sum}` —
  finite types, cardinality, big operators.
- `Mathlib.Data.Finset.{Basic, Card, Defs, Image, Max}` — `Finset` API.
- `Mathlib.Data.ZMod.Basic` and `Mathlib.Algebra.Field.ZMod` — `ZMod n` (F_2 for
  bitstrings, F_p for the polynomial MAC).
- `Mathlib.Probability.ProbabilityMassFunction.{Basic, Constructions}` —
  `PMF`, `PMF.map`, `PMF.ofFintype`.
- `Mathlib.Probability.Distributions.Uniform` — `PMF.uniformOfFintype`.
- `Mathlib.Analysis.SpecificLimits.Basic` — convergence lemmas for negligible
  functions.
- `Mathlib.Algebra.{Algebra.Basic, Algebra.Equiv, Algebra.Hom, Module.Equiv.Basic, Polynomial.Eval.Defs, Polynomial.Roots}` —
  the algebraic core of the Grochow–Qiao reduction.

**Version strategy.** Pin to a specific Mathlib4 commit via `lean-toolchain`
and `lakefile.lean` for reproducible builds. The current pin is
`leanprover-community/mathlib4 @ fa6418a8` (matches `lake-manifest.json`).
Update Mathlib only after verifying that all proofs still compile.

## Mathematical context

**Core idea.** Encryption samples from symmetry orbits in a space where
orbit structure is computationally hidden. Without the symmetry, the space
collapses into an indistinguishable distribution. The key restores the
partition into meaningful equivalence classes.

| Concept | Definition |
|---------|------------|
| Group action | `• : G × X → X` with identity `e • x = x` and compatibility `(g·h) • x = g • (h • x)` |
| Orbit | `G • x = {g • x : g ∈ G}` — the equivalence class under the action |
| Stabilizer | `Stab_G(x) = {g ∈ G : g • x = x}` — the subgroup fixing `x` |
| Canonical form | `can_G : X → X` with `can_G(x) ∈ G • x` and `can_G(x) = can_G(y) ↔ G • x = G • y` |
| G-invariant | `f(g • x) = f(x)` for all `g ∈ G, x ∈ X` (constant on orbits) |
| Separating invariant | An invariant with `f(x_{m₀}) ≠ f(x_{m₁})` for distinct message representatives |
| OIA | Orbit samples from different message orbits are computationally indistinguishable |

**Security model.** IND-CPA. The scheme targets IND-1-CPA (single query) as
the primary formalized result, with multi-query extension via standard
hybrid argument (see `docs/DEVELOPMENT.md` § 8.2).

**Hardness assumptions.**

- **Graph Isomorphism (GI).** Best classical algorithm: `2^O(√(n log n))`
  (Babai, 2015). CFI graphs are provably hard for the Weisfeiler–Leman
  hierarchy.
- **Permutation Code Equivalence (CE).** At least as hard as GI
  (`GI ≤_p CE`). Believed strictly harder for specific code families.
- **Hidden Subgroup Problem.** Hard even for quantum computers — the key
  barrier for quantum GI algorithms.

## Vulnerability reporting

If you discover a possible software vulnerability that could reasonably
warrant a CVE designation, you **must** immediately report it to the user
before continuing. This applies to vulnerabilities found in:

- **Cryptographic design** — logic errors in the AOE scheme, invariant
  attacks not covered by the counterexample analysis, flaws in the OIA
  reduction to GI or CE, or any other issue that could lead to a complete
  or partial scheme break.
- **Formalization gaps** — cases where Lean 4 fails to capture a
  security-relevant property, creating a false-assurance gap. Examples: an
  over-strong axiom making security proofs vacuous, or a definition that
  diverges from `docs/DEVELOPMENT.md`.
- **Dependencies and toolchain** — known or suspected vulnerabilities in
  Lean, Lake, elan, Mathlib, or any library encountered during builds.
- **Build and CI infrastructure** — insecure script patterns (e.g. command
  injection, unsafe file permissions) exploitable in a dev or CI
  environment.

**What to report.**

1. **Summary** — concise description of the vulnerability.
2. **Location** — file path(s) and line number(s).
3. **Severity estimate** — Critical / High / Medium / Low and exploitability.
4. **Reproduction or evidence** — how the issue manifests or could be
   triggered.
5. **Suggested remediation** — if apparent, a recommended fix or mitigation.

**How to report.** Stop current work and surface the finding in your response
immediately. Do **not** silently fix a CVE-worthy vulnerability — always
flag it explicitly so it can be tracked, triaged, and disclosed
appropriately. If the vulnerability is in a third-party dependency, note
whether an upstream advisory already exists.
