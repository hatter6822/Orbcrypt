<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Audit 2026-04-29 — Comprehensive Pre-Release Workstream Plan

**Source audit.** `docs/audits/LEAN_MODULE_AUDIT_2026-04-29_COMPREHENSIVE.md`
(16 findings: **0 CRITICAL** · **3 HIGH** · **1 MEDIUM** · **4 LOW** · **8 INFO**).

**Scope.** Pre-v1.0 release remediation plan for the Orbcrypt Lean 4
formalization. The 2026-04-29 audit is the fifth in the audit series and
the broadest in scope. **All three HIGH-severity findings are
documentation-vs-code parity gaps in prose surfaces; the Lean code itself
is clean** — zero `sorry`, zero custom axioms, every `#print axioms`
result on the standard Lean trio (`propext`, `Classical.choice`,
`Quot.sound`). The findings register (§ 3) decomposes the work into
**four letter-coded workstreams** (**A** release-blocking; **B**
recommended polish; **C** deferred v1.1+ engineering; **D** research-
scope catalogue). Letter codes are used as document identifiers only
per `CLAUDE.md`'s naming discipline — they **never** appear in Lean
declaration names.

**Branch.** Author this plan on the existing development branch
(`claude/audit-workstream-planning-HsW8k` per the session brief) and
land each Workstream **A**–**D** work unit on its own implementation
branch as enumerated in § 11.

**Author.** Claude (Opus 4.7). **Date.** 2026-04-29.
**Project baseline (verified at audit time).** 76 Lean source modules
under `Orbcrypt/`, `lakefile.lean` `version := v!"0.2.0"`, Lean
toolchain `leanprover/lean4:v4.30.0-rc1`, Mathlib pinned at
`fa6418a815fa14843b7f0a19fe5983831c5f870e`, audit script
`scripts/audit_phase_16.lean` exercising 928 `#print axioms` entries +
238 non-vacuity `example` bindings, full `lake build` succeeds with
3,426 jobs, zero warnings, zero errors.

**Naming-discipline reminder.** Per `CLAUDE.md`'s Key Conventions
("Names describe content, never provenance"), work-unit identifiers
(`A1`, `A2`, `B3`, …) are plan-document identifiers and commit-message
tokens; Lean `def` / `theorem` / `structure` / `instance` / `abbrev` /
`lemma` names added during implementation **must not** carry any
workstream or audit-finding token (`workstream`, `ws`, `audit`,
`a-07`, `g-02`, etc.). Docstrings may carry traceability prose
(`"audit 2026-04-29 / Workstream A / finding G-02"`); identifiers may
not.

**Release-messaging context.** This plan operates **inside** the
Release-messaging policy (ABSOLUTE) framework added to `CLAUDE.md` by
Workstream **A** of the 2026-04-23 audit. Every documentation edit in
this plan must respect that policy: no overclaiming Lean content; no
citing Conditional / Scaffolding / Quantitative-at-ε=1 theorems
without their qualifiers; no introducing new prose that exceeds what
the Lean code actually proves. The workstreams below remediate
existing parity gaps; they do **not** introduce new ones.

## Table of contents

- § 0 — Executive summary
- § 1 — Finding taxonomy and validation log
- § 2 — Finding → workstream mapping
- § 3 — Workstream summary
- § 4 — Workstream dependency graph and parallelism
- § 5 — **Workstream A** — Release-blocking documentation parity (HIGH + MEDIUM)
- § 6 — **Workstream B** — Recommended pre-release polish (LOW)
- § 7 — **Workstream C** — Optional v1.1+ engineering enhancements (INFO)
- § 8 — **Workstream D** — Research-scope catalogue (deferred)
- § 9 — Regression safeguards
- § 10 — Release-readiness checklist
- § 11 — Implementation branches
- § 12 — Signoff
- Appendix A — Finding-ID → workstream-and-work-unit cross-reference
- Appendix B — Workstream status tracker
- Appendix C — Documentation update templates (concrete prose snippets)
- Appendix D — Validation methodology

## 0. Executive summary

The 2026-04-29 audit demonstrates a **mature, audit-converged
codebase**. Compared to the 2026-04-23 audit (which catalogued 30+
HIGH-severity items spread across the entire codebase), this audit
records:

* **0 CRITICAL findings** — no Lean code-correctness violations.
* **3 HIGH findings** — all in **prose surfaces** (one Lean-file
  module docstring, one analysis document, one root-file snapshot
  block). No Lean theorem changed; no headline definition broke; no
  axiom regression.
* **1 MEDIUM finding** — `lakefile.lean` version (`0.2.0`) is
  unrecorded in the `CLAUDE.md` per-workstream changelog (last
  documented bump is `0.1.28 → 0.1.29`). A documentation-parity
  issue, not a build-correctness issue.
* **4 LOW + 8 INFO findings** — cosmetic, archive-relocation, and
  defense-in-depth observations.

Independent verification (audit § N-05) confirms `lake build` succeeds
across 3,426 jobs with zero errors / zero warnings, and the Phase-16
audit script emits **only** the standard Lean trio across **928**
`#print axioms` entries — zero `sorryAx`, zero non-trio axioms.

**Pre-release slate (release-blocking).** Workstream **A** absorbs all
three HIGH findings plus the MEDIUM lakefile parity issue:

| Finding | Severity | Audit § | Work unit | Effort |
|---------|----------|---------|-----------|--------|
| **G-02** — `PetrankRoth.lean` overclaims absent layers | **HIGH** | § G | **A1** | 30 min |
| **L-04** — `docs/VERIFICATION_REPORT.md` headline numbers stale | **HIGH** | § L | **A2** | 1.5 h |
| **A-07 / J-02** — `Orbcrypt.lean` Phase 16 snapshot stale | **HIGH** | § A, § J | **A3** | 45 min |
| **A-02 / L-03a** — Lakefile `0.2.0` unrecorded in `CLAUDE.md` log | **MEDIUM** | § A, § L | **A4** | 30 min |

**Total release-blocking effort: ≈ 3.25 hours serial; ≈ 1.5 hours
parallelised between two implementers** (A1, A2, A3, A4 are mutually
file-disjoint and parallelise trivially).

**Recommended pre-release slate (Workstream B, ≈ 50 min)** absorbs the
LOW findings: remove transient `_ApiSurvey.lean` (B1), relocate legacy
audit scripts (B2), refresh `README.md` audit-script count (B3),
compact the post-Workstream-I deletion comment in `KEM/CompSecurity.lean`
(B4).

**Optional v1.1+ engineering (Workstream C)** absorbs the INFO findings:
explicit lakefile globs, fast-path checksum verification, CI nested-
comment regex upgrade, lake-manifest drift check, formal GAP/Lean
canonical-image equivalence at arbitrary `n`. None block v1.0.

**Research catalogue (Workstream D, never closes)** tracks R-09, R-12,
R-13, R-15-residual-CE-reverse, R-15-residual-TI-reverse,
R-15-residual-TI-forward-matrix — all multi-month research milestones
already documented in CLAUDE.md and in the prior audit plans. This
plan does **not** alter the research catalogue; it records continuity.

**Release-gate commitment.** After Workstream **A** lands, the v1.0
release narrative is honest: every prose surface that describes Lean
content (`PetrankRoth.lean` module docstring, `VERIFICATION_REPORT.md`
headline numbers, `Orbcrypt.lean` Phase 16 snapshot, `lakefile.lean`
version field) accurately reflects what the code delivers. Workstream
**B** is strongly recommended polish; **C** and **D** defer to v1.1+ /
v2.0.

## 1. Finding taxonomy and validation log

### 1.1 Severity taxonomy

The 2026-04-29 audit follows a CVSS-style severity classification
(matching the prior 2026-04-23 audit's framework):

* **CRITICAL** — Lean code correctness violation; release-stops on
  its own. Examples: a new custom axiom; a `sorry` regression; a
  theorem whose proof body fails to discharge its conclusion.
* **HIGH** — Documentation-vs-code parity violation that could
  mislead a v1.0 release reviewer about what the Lean code proves.
  Examples: a module docstring claiming an absent declaration; a
  release-readiness document carrying stale metrics.
* **MEDIUM** — Documentation parity gap of low ambiguity, or
  codebase-hygiene issue affecting external reviewers but not
  release-messaging.
* **LOW** — Cosmetic, dead-code, transient-stub, or minor-staleness
  issue. Recommended polish but not release-blocking.
* **INFO** — Observation; defense-in-depth opportunity; not an
  action item for v1.0.

### 1.2 Severity distribution (verified from source audit § M)

| Severity | Count | IDs | Treatment |
|----------|-------|-----|-----------|
| CRITICAL | 0 | — | n/a |
| HIGH | 3 | G-02, L-04, A-07/J-02 | Workstream **A** (pre-release) |
| MEDIUM | 1 | A-02 / L-03a | Workstream **A** (pre-release) |
| LOW | 4 | A-01/H-03a, A-06, C-13b, L-01 | Workstream **B** (recommended) |
| INFO | 8 | A-03, A-04, A-05, A-08, B-03a, B-03b, C-03a, C-13a, D-02a, F-03a | Workstream **C** (deferred) |

**Note on INFO count.** The audit's M-02 severity summary lists 8
INFO findings, but the M-01 findings table enumerates 10 INFO-class
entries (B-03a, B-03b, C-03a, C-13a are listed individually). This
plan counts each ID separately. Workstream **C** absorbs all INFO
findings regardless of count.

### 1.3 Validation log — every finding spot-checked

This plan has **independently re-verified** each of the audit's 16
findings against the Lean source / prose surface it cites, prior to
workstream assignment. The methodology mirrors the 2026-04-23 plan's
§ 21 validation log: every finding's file:line citation is opened and
the claimed defect is confirmed (or refuted) by direct inspection.
**Zero findings are erroneous.** The verification record:

| Finding | Audit citation | Spot-check command (or read) | Verified? |
|---------|----------------|------------------------------|-----------|
| **G-02** | `PetrankRoth.lean:9-19, 38-52` | `sed -n '1,60p' Orbcrypt/Hardness/PetrankRoth.lean` (confirms docstring claims layers 5/6/7 with `prEncode_iff`, `prEncode_codeSize_pos`, `prEncode_card_eq`, `petrankRoth_isInhabitedKarpReduction`) + `grep -n "prEncode_iff\|petrankRoth_isInhabitedKarpReduction" Orbcrypt/Hardness/PetrankRoth*.lean` (returns only the docstring/comment occurrences; never a `def` / `theorem` declaration) | ✅ |
| **L-04** | `docs/VERIFICATION_REPORT.md` (header + ~17 in-doc references) | `grep -n "342\|36 modules\|38 modules\|347 public" docs/VERIFICATION_REPORT.md` (returns 17 lines including header `Snapshot: 2026-04-21`, header table `38 modules` / `347 public` / `342 declarations`, repeated through the document body) | ✅ |
| **A-07 / J-02** | `Orbcrypt.lean:1279-1314` | `sed -n '1275,1320p' Orbcrypt.lean` (confirms snapshot section header `Phase 16 Verification Audit Snapshot (2026-04-21)`, then `36 Lean source modules`, `342 declarations`, `343 public`, `5 intentionally private`) | ✅ |
| **A-02 / L-03a** | `lakefile.lean:13`, CLAUDE.md changelog | `grep -n "version :=" lakefile.lean` returns `version := v!"0.2.0"`; `grep -n "0\.1\.30\|0\.2\.0\|0\.1\.29" CLAUDE.md` returns only the Path B Sub-task A.6.4 entry's `0.1.28 to 0.1.29` text (one match); no `0.1.29 → 0.1.30` or `0.1.30 → 0.2.0` snapshot section | ✅ |
| **A-01 / H-03a** | `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean` | File exists (`ls -la …` returns `4663 bytes`); not imported by `Orbcrypt.lean` (`grep "_ApiSurvey" Orbcrypt.lean` returns no match); only one in-tree reference (the audit script comment at `scripts/audit_phase_16.lean:2234`) | ✅ |
| **A-03** | `lakefile.lean:30-31` | `head -25 lakefile.lean` confirms `lean_lib Orbcrypt where srcDir := "."`; combined with A-01 verification (the un-imported `_ApiSurvey.lean` builds despite no `import` line for it), the default-target glob behaviour is confirmed | ✅ |
| **A-04** | `scripts/setup_lean_env.sh:252-262` | `sed -n '250,265p' scripts/setup_lean_env.sh` confirms the `fast_path_ready()` check verifies presence of `${tc_dir}/bin/lean` and `${tc_dir}/lib/crti.o` only, no checksum | ✅ |
| **A-05** | `.github/workflows/lean4-build.yml:60-94` | The audit acknowledges this is a self-disclosed limitation and notes the `lake build` step is the definitive guard. The verification confirmed multiple `Orbcrypt/**/*.lean` files have multiple `/-` markers (e.g., `Construction/HGOE.lean: 11`), so the precondition for the regex's safety is "no nested block comments" — a post-audit eyeball-check confirmed each multi-`/-` file uses sequential top-level docstrings, not nested ones | ✅ |
| **A-06** | `scripts/audit_{a7_defeq,b_workstream,c_workstream,d_workstream,e_workstream,phase15,print_axioms}.lean` | `ls -la scripts/audit_*.lean` returns 7 historical scripts plus the active `audit_phase_16.lean`; CI workflow only invokes `audit_phase_16.lean` | ✅ |
| **A-08** | `lake-manifest.json` | `ls -la lake-manifest.json` and `head -10 lake-manifest.json` confirm presence + Mathlib pin `fa6418a8…`; CI cache key in `.github/workflows/lean4-build.yml:36` includes `lake-manifest.json` but the workflow has no drift-check step | ✅ |
| **B-03a** | `Orbcrypt/GroupAction/CanonicalLexMin.lean` | The `bitstringLinearOrder` `def` in `Construction/Permutation.lean` is `@[reducible] def` not `instance`, requiring caller `letI` discipline | ✅ |
| **B-03b** | `Orbcrypt/GroupAction/CanonicalLexMin.lean:92` | `grep -n "instance.*orbitFintype" Orbcrypt/GroupAction/CanonicalLexMin.lean` returns line 92: `instance orbitFintype (x : X) : Fintype (MulAction.orbit G x) := …` (global instance, inherited by importers) | ✅ |
| **C-03a** | `Orbcrypt/Crypto/OIA.lean:185` | The `-- Justification:` comment block on a `def` (the `OIA` definition) is consistent with the `axiom` justification rule's spirit (the rule was originally written for `axiom` declarations) | ✅ |
| **C-13a** | `Orbcrypt/KEM/CompSecurity.lean:13` | `head -25 Orbcrypt/KEM/CompSecurity.lean` confirms `import Orbcrypt.Hardness.Reductions` at line 13 — the KEM-chain-above-scheme-chain layering | ✅ |
| **C-13b** | `Orbcrypt/KEM/CompSecurity.lean:392-404` | `sed -n '385,410p' Orbcrypt/KEM/CompSecurity.lean` confirms the `--`-prefixed comment block describing post-Workstream-I deletions is present at the cited location, ~14 lines | ✅ |
| **D-02a** | `Orbcrypt/Construction/HGOE.lean:88-113` | `sed -n '85,115p' Orbcrypt/Construction/HGOE.lean` confirms the prose claims that the Lean / GAP `CanonicalImage` produce identical canonical images on every concrete input "for every orbit O under any subgroup G ≤ S_n"; the audit script's small-`n` `decide`-based examples are persuasive but not exhaustive | ✅ |
| **F-03a** | `Orbcrypt/Hardness/Reductions.lean:989` | `grep -n "_hDistinct" Orbcrypt/Hardness/Reductions.lean` returns line 989 with the underscore-prefixed parameter on the K4 companion theorem; the docstring at 992-995 explains the parameter is intentionally unused | ✅ |
| **L-01** | `README.md:53` | `grep -n "382" README.md` returns line 53: `Phase-16 audit script | 382+ #print axioms checks; …` — stale relative to actual `928` (start-of-line `#print axioms` count) | ✅ |

**Verification verdict.** Every finding cited in the audit corresponds
to a real defect at the cited location. **No erroneous findings.**

### 1.4 Cryptographic-correctness verdict (re-confirmed)

The audit's M-03 verdict ("Lean code itself: CLEAN") was re-verified
during this plan's drafting:

* `find Orbcrypt -name '*.lean' | wc -l` → **76 modules**.
* `grep -c "^import" Orbcrypt.lean` → **75 imports** (matches 76
  modules minus `_ApiSurvey.lean`, which is intentionally not
  imported per its own transient-status docstring).
* `grep -c "^#print axioms" scripts/audit_phase_16.lean` → **928**
  axiom checks at the start-of-line (the audit's "928 vs 932"
  rounding gap is explained by the latter counting all `#print
  axioms` occurrences anywhere on a line, including section banners
  with `#print axioms` mentioned in prose comments).
* No `sorry` regressions; no custom axioms; standard-trio-only
  axiom dependencies confirmed by the audit's M-03 independent
  verification.

This plan does **not** introduce any Lean source changes. Every
work unit in Workstream **A** edits prose-only surfaces (markdown
files, Lean module-header docstrings inside `/-! … -/` blocks,
`lakefile.lean`'s `version` literal). Every work unit in Workstream
**B** is also prose-only or file-relocation. Workstream **C** is
explicitly deferred. **The cryptographic-correctness posture is
untouched.**

## 2. Finding → workstream mapping

This table maps each finding to its assigned workstream and work
unit. Findings sharing a slash (e.g., `A-07 / J-02`) are reported
twice in the audit (in two different module groups) but represent
a single underlying defect; the plan treats them as one work unit.

| Finding | Severity | Audit § | Workstream | Work unit | Pre-release? |
|---------|----------|---------|------------|-----------|--------------|
| **G-02** | HIGH | § G | **A** | A1 | **yes** |
| **L-04** | HIGH | § L | **A** | A2 | **yes** |
| **A-07 / J-02** | HIGH | § A, § J | **A** | A3 | **yes** |
| **A-02 / L-03a** | MEDIUM | § A, § L | **A** | A4 | **yes** |
| **A-01 / H-03a** | LOW | § A, § H | **B** | B1 | recommended |
| **A-06** | LOW | § A | **B** | B2 | recommended |
| **L-01** | LOW | § L | **B** | B3 | recommended |
| **C-13b** | LOW | § C | **B** | B4 | recommended |
| **A-03** | INFO | § A | **C** | C1 | defer (v1.1+) |
| **A-04** | INFO | § A | **C** | C2 | defer (v1.1+) |
| **A-05** | INFO | § A | **C** | C3 | defer (v1.1+) |
| **A-08** | INFO | § A | **C** | C4 | defer (v1.1+) |
| **D-02a** | INFO | § D | **C** | C5 | defer (v1.1+) |
| **B-03a** | INFO | § B | **C** | C6 (docstring polish) | defer |
| **B-03b** | INFO | § B | **C** | C6 (docstring polish) | defer |
| **C-03a** | INFO | § C | **C** | C6 (docstring polish) | defer |
| **C-13a** | INFO | § C | **C** | C6 (docstring polish) | defer |
| **F-03a** | INFO | § F | **C** | C6 (docstring polish) | defer |
| **R-09 / R-12 / R-13 / R-15-residual-CE-reverse / R-15-residual-TI-reverse / R-15-residual-TI-forward-matrix** | research | § N-04 | **D** | n/a (catalogue) | v1.1+ / v2.0 |

Note that **B-03a, B-03b, C-03a, C-13a, F-03a** are all "no-action"
INFO observations (the audit explicitly says "No action needed" or
"Not a finding — intentional API design"). Workstream **C**'s
work-unit C6 captures them only for completeness; no edits are
required.

## 3. Workstream summary

| WS | Scope | Headline findings | Files touched | Effort | Slate |
|----|-------|-------------------|---------------|--------|-------|
| **A** | Release-blocking documentation parity. Edits four prose / metadata surfaces: `Orbcrypt/Hardness/PetrankRoth.lean` module docstring (A1, lines 9-19 and 38-52); `docs/VERIFICATION_REPORT.md` headline numbers + 17 in-doc references (A2); `Orbcrypt.lean` "Phase 16 Verification Audit Snapshot" section (A3, lines 1279-1314); `lakefile.lean` `version` field reconciled with a new `CLAUDE.md` changelog entry (A4). **No Lean source semantics change.** | G-02, L-04, A-07/J-02, A-02 | `Orbcrypt/Hardness/PetrankRoth.lean`, `docs/VERIFICATION_REPORT.md`, `Orbcrypt.lean`, `lakefile.lean`, `CLAUDE.md` | 3.25 h | **pre-release (blocking)** |
| **B** | Recommended pre-release polish. Removes the un-imported `_ApiSurvey.lean` transient stub (B1); decides on the legacy per-workstream audit scripts under `scripts/` (B2); refreshes `README.md`'s audit-script count (B3); compacts the 14-line `--`-comment block in `Orbcrypt/KEM/CompSecurity.lean:392-404` (B4). | A-01/H-03a, A-06, L-01, C-13b | `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean` (delete or relocate), `scripts/audit_*.lean` (move to `scripts/legacy/`), `README.md`, `Orbcrypt/KEM/CompSecurity.lean` | 50 min | recommended |
| **C** | Optional v1.1+ engineering enhancements. Defense-in-depth and hygiene improvements: explicit lakefile globs (C1); fast-path checksum verification in `setup_lean_env.sh` (C2); CI nested-block-comment regex upgrade (C3); CI `lake-manifest.json` drift check (C4); formal GAP/Lean canonical-image equivalence theorem at arbitrary `n` (C5); INFO-class docstring observations grouped (C6). | A-03, A-04, A-05, A-08, D-02a, B-03a, B-03b, C-03a, C-13a, F-03a | `lakefile.lean`, `scripts/setup_lean_env.sh`, `.github/workflows/lean4-build.yml`, `Orbcrypt/Construction/HGOE.lean` (research-scope theorem), assorted docstrings | n/a (defer) | **v1.1+** |
| **D** | Research-scope catalogue (informational only — never closes). Tracks R-09 (`h_step` discharge in `indQCPA_from_perStepBound`), R-12 (tight 1/4 ε-bound on `ObliviousSamplingConcreteHiding`), R-13 (`Bitstring n → ZMod p` orbit-preserving adapter), R-15-residual-CE-reverse (PetrankRoth Layers 4.1–7), R-15-residual-TI-reverse (Grochow–Qiao Layer T5), R-15-residual-TI-forward-matrix (Grochow–Qiao Layer T3.6 matrix-action upgrade). All multi-month; explicitly not v1.0 work. | R-09, R-12, R-13, R-15-residual-CE-reverse, R-15-residual-TI-reverse, R-15-residual-TI-forward-matrix | n/a — tracking only | n/a | **v1.1+ / v2.0** |
| — | **Totals** | 16 audit findings | — | ≈ 4.1 h pre-tag work | — |

**Parallelism.** Workstream **A**'s four work units (A1, A2, A3, A4)
are mutually file-disjoint (the only file edited by multiple work
units is `CLAUDE.md`, and only A4 edits `CLAUDE.md`'s changelog;
A2 / A3 edit `CLAUDE.md` only at the Workstream-status-tracker
checkbox). They parallelise trivially:

* **Two-implementer split:** {A1, A4} and {A2, A3}. Bottleneck ≈ 1.5 h
  (A2 is the longest single work unit at ~1.5 h).
* **Four-implementer split:** A1 (30 min), A2 (1.5 h), A3 (45 min),
  A4 (30 min). Bottleneck = A2 ≈ 1.5 h.

**Critical path to v1.0 tag:** Workstream **A** alone. A single
implementer working serially lands the blocking slate in ≈ 3.25 h of
coding time; two implementers working concurrently land it in
≈ 1.5 h. Workstream **B** is decoupled and may run before, during,
or after **A**.

## 4. Workstream dependency graph and parallelism

```
        ┌─────────────────────────────────────────────────┐
        │   ~~~ PRE-RELEASE SLATE (blocking for v1.0) ~~~ │
        └─────────────────────────────────────────────────┘

   A1 (PetrankRoth docstring) ────┐
   A2 (VERIFICATION_REPORT.md) ───┤
   A3 (Orbcrypt.lean snapshot) ───┼───►  [v1.0 tag gate]  ───►  release candidate
   A4 (lakefile / CLAUDE.md) ─────┘

        ┌─────────────────────────────────────────────────┐
        │   ~~~ RECOMMENDED PRE-RELEASE (polish) ~~~      │
        └─────────────────────────────────────────────────┘

   B1 (_ApiSurvey.lean) ──────┐
   B2 (legacy audit scripts) ─┤
   B3 (README.md count) ──────┤────►  polish-tag
   B4 (KEM/CompSecurity.lean
       comment) ──────────────┘

        ┌─────────────────────────────────────────────────┐
        │   ~~~ DEFERRED (v1.1+ / v2.0) ~~~               │
        └─────────────────────────────────────────────────┘

   C1 (lakefile globs)  ────┐
   C2 (setup_lean_env.sh
       checksums) ──────────┤
   C3 (CI sorry-strip
       nested-comment) ─────┼─►  v1.1+ engineering
   C4 (CI lake-manifest
       drift) ──────────────┤
   C5 (GAP/Lean equiv
       theorem) ────────────┤
   C6 (INFO docstrings) ────┘

   D — research catalogue ──►  v1.1+ / v2.0 roadmap
```

Read as: an arrow `X ──► Y` means "Y cannot start until X is merged
into its target branch". All four Workstream-A work units are
**mutually independent** (different files, different sections of
`CLAUDE.md`). All four Workstream-B work units are **mutually
independent** as well. Workstream **A** and Workstream **B** are
also **mutually independent** of each other — they edit disjoint
file sets.

**Concrete parallelism plan (recommended).**

* **Implementer 1 (≈ 1.5 h):** A2 (1.5 h, the longest single unit).
* **Implementer 2 (≈ 1.5 h):** A1 (30 min) → A3 (45 min) → A4 (30 min)
  — sequenced to respect single-implementer file ordering on
  `CLAUDE.md` (A2 and A3 both touch the Workstream-status tracker;
  but A2 is on Implementer 1, so the ordering serializes naturally
  via PR review).

In practice each work unit can also land in its own PR. The
Workstream-A umbrella branch (`claude/audit-findings-2026-04-29-A`)
can either accept all four work units together or each unit can
land separately on `claude/audit-findings-2026-04-29-{A1,A2,A3,A4}`
branches. § 11 enumerates the full implementation-branch list.

**Why no inter-workstream dependencies.** Unlike the 2026-04-23 plan
(where **K** depended on **A** and **I** for stable rename targets),
this plan's workstreams have no semantic coupling. Workstream **A**
edits prose; Workstream **B** removes / relocates files; Workstream
**C** is deferred. There is no cross-workstream PR ordering
constraint.

## 5. Workstream A — Release-blocking documentation parity

**Severity.** HIGH (G-02, L-04, A-07/J-02) + MEDIUM (A-02 / L-03a).
**Effort.** ≈ 3.25 h serial; ≈ 1.5 h with two implementers.
**Scope.** Documentation-only. No Lean source semantics changes.

### 5.1 Problem statement

The 2026-04-29 audit identified four documentation-vs-code parity
gaps that block v1.0 release per `CLAUDE.md`'s "Release messaging
policy (ABSOLUTE)":

1. **G-02:** `Orbcrypt/Hardness/PetrankRoth.lean`'s module docstring
   (lines 9-19 and 38-52) declares Layers 5/6/7 as **present in this
   file**, naming `prEncode_iff`, `prEncode_codeSize_pos`,
   `prEncode_card_eq`, and `petrankRoth_isInhabitedKarpReduction` —
   none of which exist in any module. A reader who consults the
   docstring will conclude the Petrank-Roth Karp reduction is fully
   landed; in fact, the reverse direction (Layers 4–7) is
   research-scope (`R-15-residual-CE-reverse`), correctly disclosed
   only in the sister module `MarkerForcing.lean`.

2. **L-04:** `docs/VERIFICATION_REPORT.md` is the auditor-facing
   document (per `README.md`'s documentation map). Its headline
   numbers (snapshot date, module count, declaration count, audit-
   script entry count, private-helper count) are **2-9× stale**
   relative to current reality:
   - Snapshot date: `2026-04-21` → reality: `2026-04-29`.
   - Modules: `38` → reality: `76` (drops to `75` post-Workstream-B1).
   - Public declarations: `347` → reality: ≈ 800-900 (the
     README's floor estimate of `358+` is itself understated per
     L-01; the precise count must be verified at implementation
     time via the grep recipe in A3 Step 4).
   - Audit-script entries: `342` → reality: `928` (verified by
     `grep -c "^#print axioms" scripts/audit_phase_16.lean`).
   - `private` declarations: `5` → reality: ≈ 47 (≈ 9× stale).
   The stale numbers appear at ≈ 19 grep matches in the document
   body, of which **6** are current-state references that need
   refreshing and **13** are inside historical-snapshot bullets
   that MUST be preserved (see A2 below for the disambiguation).

3. **A-07 / J-02:** `Orbcrypt.lean`'s "Phase 16 Verification Audit
   Snapshot" section (lines 1279-1314) records the same stale
   numbers as L-04, dated `2026-04-21`. This section is
   consumer-facing — every reader of the root file sees these
   numbers.

4. **A-02 / L-03a:** `lakefile.lean:13` declares `version :=
   v!"0.2.0"`. The most recent per-workstream version-bump entry in
   `CLAUDE.md`'s changelog is the R-TI Phase 3 — Path B Sub-task
   A.6.4 entry, which records `0.1.28 → 0.1.29`. There is no
   `CLAUDE.md` snapshot recording the subsequent jumps `0.1.29 →
   0.1.30 → 0.2.0`. The git log (verified via `git log --oneline
   --all -- lakefile.lean` followed by per-commit
   `git show <hash>:lakefile.lean | grep version`) shows two
   intermediate version-bumping commits: `42b7e03` ("Audit pass:
   PathOnlyAlgEquivSigma cleanup + extended tests + docs"), which
   bumped `0.1.29 → 0.1.30`, and `9f4b9ec` ("Bump minor version:
   0.1.30 → 0.2.0"). Neither bump has a corresponding CLAUDE.md
   changelog entry.

### 5.2 Fix scope

Workstream **A** performs a **release-messaging reconciliation
pass** with these explicit deliverables:

1. **A1 (G-02).** Rewrite the two overstated docstrings in
   `Orbcrypt/Hardness/PetrankRoth.lean` to mirror the honest
   disclosure pattern already established by `MarkerForcing.lean`.
2. **A2 (L-04).** Refresh `docs/VERIFICATION_REPORT.md`'s headline
   numbers, snapshot date, and the **6 current-state in-document
   references** (lines 78, 455, 472, 494, 506, 595). The
   **13 historical-snapshot references** inside per-Workstream /
   Document-history bullets MUST be preserved (lines 165, 1722,
   1801, 1902, 1988, 2057, 2154, 2156, 2218, 2302, 2390, 2481,
   2489). Two strategies are evaluated for the header table; the
   chosen Strategy (b) restructures the table to reference
   `CLAUDE.md` as the canonical running-state source, then carries
   only invariants in the report.
3. **A3 (A-07 / J-02).** Refresh the `Orbcrypt.lean` Phase 16
   snapshot section to current numbers and the `2026-04-29` date.
4. **A4 (A-02 / L-03a).** Add a `CLAUDE.md` per-workstream changelog
   entry recording the `0.1.29 → 0.1.30 → 0.2.0` version-bump chain
   with rationale.

### 5.3 Work units

#### A1 — Fix `PetrankRoth.lean` module docstring overclaim (G-02)

**File.** `Orbcrypt/Hardness/PetrankRoth.lean`, lines 9-19 and 38-52.

**Severity.** HIGH (release-blocking).

**Problem.** Two docstring blocks declare layers 5/6/7 are in this
file, naming four absent declarations:

* `prEncode_iff` — claimed at line 47 in the "Layer organisation"
  list as "Layer 5 — `prEncode_iff` assembling forward (Layer 2)
  with the reverse direction (Layer 4, `MarkerForcing.lean`)".
* `prEncode_codeSize_pos` and `prEncode_card_eq` — claimed at
  lines 49-50 as the "Layer 6 — non-degeneracy bridge".
* `petrankRoth_isInhabitedKarpReduction` — claimed at line 51 as
  "Layer 7 — `petrankRoth_isInhabitedKarpReduction` discharging
  the strengthened `GIReducesToCE` Prop".

**Verification (re-run prior to landing the fix).**

```bash
grep -n "prEncode_iff\|prEncode_codeSize_pos\|prEncode_card_eq\|petrankRoth_isInhabitedKarpReduction" \
    Orbcrypt/Hardness/PetrankRoth.lean \
    Orbcrypt/Hardness/PetrankRoth/MarkerForcing.lean \
    Orbcrypt/Hardness/PetrankRoth/BitLayout.lean
```

Expected output (before fix): **only docstring/comment matches**
(lines 47, 49, 50, 51 in `PetrankRoth.lean`; lines 19, 85, 86 in
`MarkerForcing.lean`); **zero declaration sites**.

**Change recipe.**

* **Step 1:** Rewrite the first block (lines 9-19), the file's
  preamble docstring, to honestly disclose what is and is not
  present. Replace:

  ```
  /-
  Petrank–Roth (1997) Karp reduction GI ≤ CE.

  Top-level encoder, forward direction (Layer 2), iff assembly (Layer 5),
  non-degeneracy bridge (Layer 6), and `GIReducesToCE` inhabitant
  (Layer 7).  The reverse direction (Layers 3, 4) lives in
  `Orbcrypt/Hardness/PetrankRoth/MarkerForcing.lean`.

  See `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` for
  the full design and the layer-by-layer landing plan.
  -/
  ```

  with:

  ```
  /-
  Petrank–Roth (1997) Karp reduction GI ≤ CE — partial closure.

  This module lands the **forward direction** (Layer 2) of the
  Petrank–Roth Karp reduction: the encoder `prEncode`, its
  cardinality theorem `prEncode_card`, and the headline forward
  theorem `prEncode_forward`. The Layer-3 column-weight invariance
  machinery (`MarkerForcing.lean`) is also landed and exercised by
  the surjectivity bridge `prEncode_surjectivity`.

  **Status: partial closure.** Layers 4 (reverse direction —
  marker-forcing endpoint recovery), 5 (iff assembly
  `prEncode_iff`), 6 (non-degeneracy bridge
  `prEncode_codeSize_pos` / `prEncode_card_eq`), and 7 (the
  `GIReducesToCE` inhabitant `petrankRoth_isInhabitedKarpReduction`)
  are **research-scope** and **not yet landed**, tracked as
  `R-15-residual-CE-reverse` in CLAUDE.md and at
  `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`
  Layer-4 obligations § 4.1–4.10 / § 5 / § 6 / § 7. The
  identifiers `prEncode_iff`, `prEncode_codeSize_pos`,
  `prEncode_card_eq`, and `petrankRoth_isInhabitedKarpReduction`
  named in the layer organisation below **do not yet exist** as
  Lean declarations; they are placeholder names tracked for the
  research-scope work.

  See `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`
  for the full design and the layer-by-layer landing plan.
  -/
  ```

* **Step 2:** Rewrite the second block (lines 38-52), the
  "Layer organisation" docstring inside the `/-! … -/` markdown
  module docstring. Replace each layer bullet with a status
  marker. Specifically:

  ```
  ## Layer organisation

  * **Layer 1 (LANDED)** — codeword constructors (`vertexCodeword`,
    `edgeCodeword`, `markerCodeword`, `sentinelCodeword`), the
    encoder `prEncode`, evaluation lemmas, and `prEncode_card`.
  * **Layer 2 (LANDED)** — forward direction: vertex-permutation σ ∈
    `Equiv.Perm (Fin m)` lifts to `Equiv.Perm (Fin (dimPR m))` via
    `liftAut`, and `prEncode_forward` exhibits the lift as a witness
    of `ArePermEquivalent (prEncode m adj₁) (prEncode m adj₂)`.
  * **Layer 3 (LANDED in `MarkerForcing.lean`)** — column-weight
    invariance machinery used by Layer 4. The four per-family
    column-weight signatures (`colWeight_prEncode_at_vertex`, …,
    `colWeight_prEncode_at_sentinel`) and the surjectivity bridge
    `prEncode_surjectivity` are exercised here.
  * **Layer 4 (RESEARCH-SCOPE — `R-15-residual-CE-reverse`)** — the
    full marker-forcing reverse direction: vertex-permutation
    extraction (`extractVertexPerm` and bijectivity); edge-permutation
    extraction (`extractEdgePerm`); the `extractEdgePerm =
    liftedEdgePerm extractVertexPerm` identification core; marker-
    block freedom; adjacency recovery; empty-graph case. Multi-week
    formalisation work; see
    `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`
    sub-tasks 4.1–4.10.
  * **Layer 5 (RESEARCH-SCOPE)** — `prEncode_iff` assembling Layer 2's
    forward direction with the Layer-4 reverse direction. **Not yet
    in the codebase**; the identifier `prEncode_iff` does not exist.
  * **Layer 6 (RESEARCH-SCOPE)** — non-degeneracy bridge
    (`prEncode_codeSize_pos`, `prEncode_card_eq`). **Not yet in the
    codebase.**
  * **Layer 7 (RESEARCH-SCOPE)** — `petrankRoth_isInhabitedKarpReduction`
    discharging the strengthened `GIReducesToCE` Prop. **Not yet in
    the codebase.** The pre-Layer-7 inhabitant of `GIReducesToCE`
    (a singleton-encoder non-degeneracy witness retained as
    `_card_nondegeneracy_witness` in
    `Orbcrypt/Hardness/CodeEquivalence.lean`) is the type-level
    placeholder until Layer 7 lands.
  ```

* **Step 3:** Verify the fix by re-running the verification command
  from the Problem section. Output should now be the docstring
  matches (re-positioned but still in prose context) plus an
  *additional* match line on the new "Status: partial closure"
  block; **no declaration sites should appear** (since none were
  added).

**Acceptance criteria.**

* **Mechanical:** `grep -n "petrankRoth_isInhabitedKarpReduction"
  Orbcrypt/Hardness/PetrankRoth.lean` returns at least one match per
  the new "research-scope" disclosure, but `grep -E
  "^(theorem|def|structure|class|instance|abbrev|lemma) +petrankRoth_isInhabitedKarpReduction"
  Orbcrypt/Hardness/**/*.lean` returns zero matches.
* **Semantic:** A reader of the rewritten docstrings can no longer
  infer that the four named declarations exist. Each layer has an
  explicit status marker: `(LANDED)`, `(LANDED in <file>)`, or
  `(RESEARCH-SCOPE — <tracking-id>)`.
* **Build:** `lake build Orbcrypt.Hardness.PetrankRoth` succeeds.
* **Audit script:** `lake env lean scripts/audit_phase_16.lean`
  emits no error / warning lines and the standard-trio axiom output
  is unchanged for every PetrankRoth declaration.

**Regression safeguard.**

* The change is comment-only; the kernel cannot be affected.
* Re-running the audit script confirms no `#print axioms` output
  changes.
* The CLAUDE.md change-log requires a Workstream-A snapshot entry
  per § 11 documentation-rules — handled in A4's CLAUDE.md edit.

**Estimated effort.** 30 minutes (read source + edit two
docstring blocks + verify).

#### A2 — Refresh `docs/VERIFICATION_REPORT.md` headline numbers (L-04)

**File.** `docs/VERIFICATION_REPORT.md` (~2700 LOC).

**Severity.** HIGH (release-blocking).

**Problem.** The auditor-facing document carries headline numbers
that are 2-9× stale. **Critical disambiguation:** the document
contains *two distinct categories* of stale-looking references —
**current-state claims** (which describe the audit's CURRENT method
/ result / verdict and DO need refreshing) and **historical-
snapshot content** (per-Workstream / per-Phase entries inside the
"Document history" section that record state AT THE TIME of each
landing and MUST NOT be refreshed, on pain of erasing the audit
trail).

A blanket `sed -i` over every stale-looking string would damage
the historical record. The implementer must apply edits ONLY to
the current-state subset.

**Current-state references (REFRESH).** These are top-level
descriptions of what the audit script does NOW and what its
current output is.

| Line | Section | Stale value | Current value |
|------|---------|-------------|---------------|
| 12 | Snapshot-date header | `2026-04-21` | `2026-04-29` |
| 28-48 | Headline numbers table | various | rewrite per Strategy a + b hybrid |
| 49-55 | Verdict | factually still true | augment per Step 3 |
| 78 | "How to reproduce the audit" Step 5 prose | `342 declarations` | `928 declarations` (start-of-line `#print axioms` count) |
| 455 | "Method." section header for the audit body | `runs #print axioms on 342` | `runs #print axioms on 928` |
| 472 | Method continuation | `342 declarations exercised` | `928 declarations exercised` |
| 494 | "Result." section header | `All 36 modules carry a /-! …` | `All 76 modules carry a /-! …` (or 75 post-B1) |
| 506 | Method continuation (root file imports) | `Orbcrypt.lean imports all 36 modules` | `Orbcrypt.lean imports all 75 modules (76 source modules under Orbcrypt/, minus _ApiSurvey.lean — intentionally not imported and a Workstream-B1 removal target)` |
| 595 | Method conclusion | `The 342 declarations exercised` | `The 928 declarations exercised` |

**Historical-snapshot references (PRESERVE).** These appear inside
the "Document history" section's per-Workstream / per-Phase
bullets. Each describes the state at the time of THAT workstream's
landing; refreshing them would erase the audit-trail traceability.

| Line | Snapshot owner | Why preserved |
|------|----------------|---------------|
| 165 | Workstream D (audit 2026-04-23) snapshot | "The 38-module total and the 347 public-declaration count are unchanged" describes the post-D state correctly. |
| 1722 | "2026-04-21 — Phase 16 verification report authored" Document-history entry | Records the original Phase 16 landing's `342 #print axioms` count. |
| 1801 | Workstream K (audit 2026-04-21, distinct-IND-1-CPA) snapshot | "All 38 modules build clean" describes the post-K state. |
| 1902 | Workstream L snapshot | post-L state |
| 1988 | Workstream M snapshot | post-M state |
| 2057 | Workstream N snapshot | post-N state |
| 2154, 2156 | Workstream A (audit 2026-04-23) snapshot | post-A state for that audit |
| 2218 | Workstream B (audit 2026-04-23) snapshot | post-B state for that audit |
| 2302 | Workstream C (audit 2026-04-23) snapshot | post-C state for that audit |
| 2390 | Workstream D (audit 2026-04-23) snapshot — second mention | post-D state |
| 2481 | Workstream E (audit 2026-04-23) snapshot | post-E state |
| 2489 | Workstream E (audit 2026-04-23) snapshot — second mention | "rises from 342 to 344" records the literal delta, not the current count |

**Disambiguation rule.** A reference is **historical** iff it
appears inside a `* **YYYY-MM-DD …** —` Document-history bullet
or inside a per-Workstream / per-Phase snapshot subsection. Every
other stale reference is a **current-state** claim and must be
refreshed.

The header table at lines 28-48 also requires holistic refresh.
Strategy (b) (see below) replaces the entire table with a
cross-reference paragraph, so the per-cell delta below is
*illustrative* of the staleness rather than a literal post-A2
target table. Implementers adopting Strategy (a) instead should
verify each post-fix value at implementation time:

| Pre-fix value | Post-fix value (verify at impl time) |
|---------------|--------------------------------------|
| Lean source modules: 38 | 76 (or 75 post-B1); `find Orbcrypt -name '*.lean' \| wc -l` |
| Public declarations: 347 | ≈ 800-900 (verified grep recipe; README "358+" is itself understated) |
| Public declarations checked by audit script: 346 | 928; `grep -c "^#print axioms" scripts/audit_phase_16.lean` |
| `theorem` declarations: 220 | ≈ 622; `grep -rE "^theorem [a-zA-Z]" Orbcrypt --include="*.lean" \| wc -l` |
| `def` declarations: 105 | ≈ 168; `grep -rE "^def [a-zA-Z]" Orbcrypt --include="*.lean" \| wc -l` |
| `private` declarations: 5 | ≈ 47; verified grep recipe |
| `lake build` jobs: 3,366 | 3,426 (or 3,425 post-B1); `lake build` final summary line |

**Strategy decision.** The audit recommends two strategies:

* **Strategy (a) — refresh in place:** Update every stale number to
  the 2026-04-29 reality. Time-boxed but creates ongoing maintenance
  debt — the next audit will face the same staleness problem unless
  numbers are continuously refreshed.
* **Strategy (b) — restructure to reference CLAUDE.md:** Replace
  numerical claims with cross-references to CLAUDE.md as the
  canonical running-state source. Carry only invariants (zero-sorry
  / zero-custom-axiom posture; standard-trio-only axioms) and a
  per-snapshot date.

**This plan adopts Strategy (b)** for the headline table and the
"Methodology" section, plus **Strategy (a)** for the per-headline
theorem table (which intrinsically lists specific theorems, not
counts). Rationale:

* Strategy (b) eliminates the per-audit refresh burden — all future
  audits update CLAUDE.md (which they already must, per the
  "Documentation rules" in CLAUDE.md), and `VERIFICATION_REPORT.md`
  re-renders correctly without edits.
* Strategy (a) is appropriate where the numbers are intrinsic to
  the document's purpose (e.g., the headline-theorem table at
  lines 80–600+ enumerates specific theorems by name, which doesn't
  go stale even when counts shift).

**Change recipe.**

* **Step 1 — header refresh (Strategy a + b hybrid).** Update
  lines 11-48: snapshot date → `2026-04-29`; the headline-numbers
  table is rewritten to remove every count cell and replace with a
  short cross-reference paragraph:

  ```markdown
  *Snapshot: 2026-04-29.* For current running counts (module total,
  public-declaration total, audit-script `#print axioms` total,
  `lake build` job total), consult `CLAUDE.md`'s most recent
  per-workstream changelog entry — that document is the canonical
  source for ephemeral metrics and is updated continuously per the
  "Documentation rules" guidance. The invariants below are
  guaranteed at every snapshot:

  | Invariant | Status |
  |-----------|--------|
  | `lake build Orbcrypt` succeeds with exit 0 | ✅ |
  | Zero `sorry` occurrences across `Orbcrypt/**/*.lean` | ✅ |
  | Zero custom `axiom` declarations across `Orbcrypt/**/*.lean` | ✅ |
  | Every `#print axioms` result on standard Lean trio (`propext`, `Classical.choice`, `Quot.sound`) or "does not depend on any axioms" | ✅ |
  | Every public declaration carries a `/-- … -/` docstring | ✅ |
  ```

* **Step 2 — body sweep (Strategy a, current-state references
  only).** Rewrite ONLY the current-state references identified in
  the "REFRESH" table above (lines 78, 455, 472, 494, 506, 595).
  Use exact `Edit`-tool replacements with sufficient surrounding
  context to disambiguate from the historical-snapshot references
  on the same numerical pattern. **Do not** apply a blanket
  `sed -i` substitution — that would corrupt the historical
  Document-history bullets. Each refresh preserves the surrounding
  prose intact and only updates the count cells.

  **Per-line refresh recipe (illustrative — implementer adjusts to
  actual line content):**

  - **Line 78:** `342 declarations` → `928 declarations`. Preserve
    the surrounding `Step 5 prints #print axioms for ...` prose.
  - **Line 455:** `runs #print axioms on 342` → `runs #print
    axioms on 928`.
  - **Line 472:** `342 declarations exercised` → `928 declarations
    exercised`.
  - **Line 494:** `All 36 modules carry a /-! …` → `All 75 modules
    carry a /-! …` (post-B1; or 76 if B1 has not landed).
  - **Line 506:** Update the "imports all 36 modules" claim to
    reflect the post-B1 count of 75 imports (the un-imported
    `_ApiSurvey.lean` was deleted; the root file imports all 75
    remaining modules).
  - **Line 595:** `The 342 declarations exercised` → `The 928
    declarations exercised`.

  **Verification of disambiguation.** After Step 2, run:
  ```bash
  grep -n "342\|36 modules\|38 modules\|347 public" docs/VERIFICATION_REPORT.md
  ```
  Expected output: only the lines listed in the "PRESERVE" table
  above (165, 1722, 1801, 1902, 1988, 2057, 2154, 2156, 2218,
  2302, 2390, 2481, 2489). If any line listed in the "REFRESH"
  table still appears in the grep output, Step 2 is incomplete.

* **Step 3 — body verdict refresh.** The "Verdict" section
  (lines 49-55) currently reads "Phase 16 exit criteria are all
  met. The formal verification posture established at the end of
  Phase 6 — zero `sorry`, zero custom axioms ... extends unchanged
  through Phases 7–14, and now also through the Workstream
  A/B/C/D/E audit follow-ups." This is **factually still true**.
  Augment with: "Subsequent post-2026-04-21 work (Workstream G/H/J/K/L/M/N
  of the 2026-04-21 audit; Workstream A/B/C/D/E of the 2026-04-23
  audit; Workstreams F/G of the 2026-04-23 audit; the R-CE/R-TI
  Karp-reduction subtree expansion; the R-TI Phase 1/2/3 partial-
  discharge work; Workstreams I/J/etc. of the 2026-04-23 audit's
  preferred slate) preserves the same posture — every Lean source
  change since the 2026-04-21 snapshot has been verified to
  maintain zero-sorry / zero-custom-axiom / standard-trio-only
  axioms by the unchanged Phase-16 audit script and CI workflow."

* **Step 4 — Document history entry.** Append a new entry to the
  Document history section dated `2026-04-29` recording this
  Workstream-A2 landing.

**Acceptance criteria.**

* **Mechanical (current-state refreshed):** Lines 78, 455, 472,
  494, 506, 595 no longer carry `342 declarations` / `36 modules`
  / `38 modules` / `347 public` claims; they reflect 2026-04-29
  reality.
* **Mechanical (historical snapshots preserved):** Lines 165,
  1722, 1801, 1902, 1988, 2057, 2154, 2156, 2218, 2302, 2390,
  2481, 2489 are **byte-identical** to their pre-A2 state. The
  historical Workstream / Phase snapshot bullets are preserved
  verbatim.
* **Mechanical:** The header date reads `Snapshot: 2026-04-29`.
* **Mechanical:** The headline-numbers table (lines 28-48) is
  rewritten per Strategy a + b hybrid (cross-references CLAUDE.md
  for ephemeral metrics; carries only invariants explicitly).
* **Semantic:** A reader of the refreshed document does not
  encounter a CURRENT-STATE numerical claim that contradicts the
  current reality. Historical-snapshot bullets continue to record
  state at the time of the corresponding workstream landing.
* **Build:** Document is markdown-only; no Lean build impact.

**Regression safeguard.** The historical-snapshot disambiguation
rule (PRESERVE table above) is the primary safeguard. Reviewers
of the A2 PR should `git diff` the touched lines and verify each
diff hunk is in the REFRESH list, not the PRESERVE list. A
diff against any line in the PRESERVE table is a review-blocking
regression.

**Estimated effort.** 1.5 hours (multiple pass: 30 min header
restructure, 45 min body sweep across ~17 references, 15 min
Document history entry + cross-reference checks).

#### A3 — Refresh `Orbcrypt.lean` Phase 16 snapshot section (A-07 / J-02)

**File.** `Orbcrypt.lean`, lines 1279-1314.

**Severity.** HIGH (release-blocking).

**Problem.** The "Phase 16 Verification Audit Snapshot (2026-04-21)"
section records:

| Stale value | Current value |
|-------------|---------------|
| 36 Lean source modules | 76 |
| 0 `sorry` (still true) | 0 (still true) |
| 0 custom axiom (still true) | 0 (still true) |
| 342 declarations | 928 |
| 343 public (non-`private`) declarations | ≈ 800-900 (verified at impl time; README's floor `358+` understated) |
| 5 intentionally `private` helper declarations | 47 |
| 3,364 `lake build` jobs | 3,426 |
| `(2026-04-21)` date | `(2026-04-29)` |

This snapshot is **inside Lean source** — it lives in
`Orbcrypt.lean`'s module-header docstring block (`/-! … -/`). It is
visible to any reader who opens the root file or runs `cat
Orbcrypt.lean`. **Strict consumer-visible parity gap.**

**Strategy decision.** The audit recommends two strategies:

* **Strategy (a) — refresh in place:** Update the Phase 16 snapshot
  section to current numbers and the `2026-04-29` date.
* **Strategy (b) — remove and forward:** Delete the snapshot section
  from `Orbcrypt.lean` and forward to a separately-versioned
  artefact (e.g., `docs/audits/PHASE_16_SNAPSHOT.md`).

**This plan adopts Strategy (a)** for the immediate v1.0 release,
**plus** Strategy (b) as a deferred Workstream-K-style follow-up
to be tracked under the 2026-04-23 plan's Workstream **K**
("root-file split + legacy script relocation"), which is already
catalogued as `pending`. Rationale:

* Strategy (a) is the minimal change required for v1.0 release
  honesty. It preserves the existing structure that downstream
  consumers may depend on.
* Strategy (b) is the right long-term solution but exceeds the
  release-blocking scope of this plan. The 2026-04-23
  Workstream **K** is the appropriate vehicle.

**Change recipe.**

* **Step 1 — refresh header date.** Line 1280: `Phase 16
  Verification Audit Snapshot (2026-04-21)` → `Phase 16
  Verification Audit Snapshot (2026-04-29)`.

* **Step 2 — refresh module-count and `lake build` lines.** The
  current text at lines 1289-1291:

  ```
  * **36** Lean source modules under `Orbcrypt/`, all building successfully
    via `lake build Orbcrypt` (3,364 jobs, zero errors, zero warnings).
  ```

  is rewritten to:

  ```
  * **76** Lean source modules under `Orbcrypt/` (75 imported by this
    root file + the un-imported transient `_ApiSurvey.lean`), all
    building successfully via `lake build Orbcrypt` (3,426 jobs as of
    audit 2026-04-29, zero errors, zero warnings).
  ```

  The transient `_ApiSurvey.lean` reference acknowledges Workstream **B**'s
  removal target. If Workstream **B1** (delete `_ApiSurvey.lean`) lands
  before A3, the parenthetical is rewritten to "(75 imported and built
  by this root file)" with the module count adjusted to **75**.

* **Step 3 — refresh declaration counts.** Lines 1294-1305:

  ```
  * **342** declarations exercised by `scripts/audit_phase_16.lean` via
    `#print axioms` — every public `def`, `theorem`, `structure`,
    `class`, `instance`, and `abbrev` declared under
    `Orbcrypt/**/*.lean`. **All 342** depend only on the standard Lean
    axioms (`propext`, `Classical.choice`, `Quot.sound`); 133 depend on
    *no* axioms at all.
  ```

  is rewritten to:

  ```
  * **928** declarations exercised by `scripts/audit_phase_16.lean` via
    `#print axioms` — every public `def`, `theorem`, `structure`,
    `class`, `instance`, and `abbrev` declared under
    `Orbcrypt/**/*.lean`, plus the research-scope and partial-
    closure declarations landed by the post-2026-04-21
    Workstream-G/H/J/K/L/M/N (audit 2026-04-21), Workstream-A/B/C/D/E
    (audit 2026-04-23), Workstream-F/G (audit 2026-04-23), and the
    R-CE/R-TI Karp-reduction subtree. **All 928** depend only on the
    standard Lean axioms (`propext`, `Classical.choice`, `Quot.sound`);
    a substantial fraction depend on *no* axioms at all (the precise
    count tracks the per-Workstream summary in CLAUDE.md). **No
    `sorryAx`** appears in any output. The CI parser de-wraps Lean's
    multi-line axiom lists before scanning, so a custom axiom cannot
    hide on a continuation line.
  ```

* **Step 4 — refresh public-declaration count.** Lines 1306-1308:

  ```
  * **343** public (non-`private`) declarations across the source tree;
    every one carries a `/-- … -/` docstring (Phase 6 standards retained
    through Phases 7–14).
  ```

  is rewritten using a count verified at A3-implementation-time
  via:
  ```bash
  PUB=$(grep -rE "^(theorem|def|structure|class|instance|abbrev) [a-zA-Z]" \
        Orbcrypt --include="*.lean" | wc -l)
  PRIV=$(grep -rE "^private (theorem|def|lemma|structure|class|instance|abbrev|noncomputable)" \
         Orbcrypt --include="*.lean" | wc -l)
  echo "Public: $PUB; Private: $PRIV"
  ```

  Note the README.md's headline "358+" is acknowledged by the
  audit (L-01) as "likely understated"; the snapshot should
  reflect the verified `$PUB` value at the time A3 lands. As of
  the planning-document drafting, `$PUB ≈ 840` (622 theorems +
  168 defs + 50 structures/classes/instances/abbrevs); the
  noncomputable-prefixed declarations (~83) further extend the
  total. The actual snapshot writes:

  ```
  * **<verified-count>** public (non-`private`) declarations across
    the source tree (verified via the grep recipe at A3 implementation
    time; expected ≈ 800-900 as of 2026-04-29); every one carries a
    `/-- … -/` docstring (Phase 6 standards retained through Phases
    7–14, the post-2026-04-21 audit work, and the R-CE / R-TI / Manin
    chain landing). The exact running count is recorded in CLAUDE.md's
    most recent per-workstream changelog entry; the README.md headline
    figure ("358+") is a deliberate floor estimate retained for
    stability across PRs.
  ```

  The `<verified-count>` placeholder is filled in by the
  implementer after running the grep recipe above.

* **Step 5 — refresh private-helper count.** Lines 1309-1313:

  ```
  * **5** intentionally `private` helper declarations
    (`Probability.Advantage.hybrid_argument_nat`,
    `AEAD.AEAD.{authDecaps_none_of_verify_false, keyDerive_canon_eq_of_mem_orbit}`,
    `PublicKey.CombineImpossibility.{probTrue_map_id_eq, probTrue_orbitDist_eq}`).
    Private-by-design, deliberately not part of the public API.
  ```

  is rewritten to (using the verified `$PRIV` count from
  Step 4's grep recipe; ≈ 47 as of audit 2026-04-29):

  ```
  * **<verified-private-count>** intentionally `private` helper
    declarations across the source tree (verified via the grep
    recipe in Step 4; ≈ 47 as of 2026-04-29), all private-by-
    design and deliberately not part of the public API. The
    pre-2026-04-21 5-helper enumeration
    (`Probability.Advantage.hybrid_argument_nat`,
    `AEAD.AEAD.{authDecaps_none_of_verify_false, keyDerive_canon_eq_of_mem_orbit}`,
    `PublicKey.CombineImpossibility.{probTrue_map_id_eq, probTrue_orbitDist_eq}`)
    is preserved; the additional ≈ 42 private helpers were
    introduced by post-2026-04-21 R-CE / R-TI / Manin / Path-B /
    Discharge / EncoderSlabEval / PathBlockSubspace /
    PathOnlyAlgebra / Wedderburn–Mal'cev / AlgebraWrapper
    modules.
  ```

  The `<verified-private-count>` placeholder is filled in by the
  implementer after running the grep recipe in Step 4.

* **Step 6 — add Workstream-A snapshot pointer.** Append a single
  line at the end of the section directing future maintenance to
  CLAUDE.md:

  ```
  See `CLAUDE.md`'s per-workstream changelog and `docs/VERIFICATION_REPORT.md`'s
  Document history for the running snapshot of metrics; this in-source
  block is refreshed only at audit boundaries.
  ```

**Acceptance criteria.**

* **Mechanical:** `sed -n '1279,1340p' Orbcrypt.lean` displays the
  refreshed snapshot dated `2026-04-29` with current numbers
  (verified at A3-implementation-time):
  - 76 (or 75 post-B1) Lean source modules
  - 928 audit-script `#print axioms` entries
  - **verified** public-declaration count from the Step-4 grep
    recipe (≈ 800-900 expected; the README-style "358+" floor
    estimate is also acceptable for a stable headline figure)
  - **verified** private-declaration count from the Step-4 grep
    recipe (≈ 47 expected)
  - 3,426 (or 3,425 post-B1) `lake build` jobs.
* **Semantic:** A reader of the root file no longer encounters
  numerical claims that conflict with current reality.
* **Build:** `lake build Orbcrypt` succeeds (the change is inside
  a `/-! … -/` docstring block — no kernel impact).
* **Audit script:** Unchanged output (the docstring is not parsed by
  Lean's elaborator).

**Regression safeguard.** None — comment-only. The snapshot section
is purely informational; the kernel cannot be affected.

**Estimated effort.** 45 minutes (read source + edit ~6 sub-blocks +
verify counts via `find`/`grep`).

#### A4 — Reconcile `lakefile.lean` version with `CLAUDE.md` changelog (A-02 / L-03a)

**File.** `lakefile.lean:13`, `CLAUDE.md` (per-workstream changelog).

**Severity.** MEDIUM (release-blocking per audit § N-01).

**Problem.** `lakefile.lean:13` declares `version := v!"0.2.0"`. The
last `CLAUDE.md` per-workstream version-bump entry records
`0.1.28 → 0.1.29` (R-TI Phase 3 — Path B Sub-task A.6.4). There is
**no `CLAUDE.md` snapshot** recording either of the two intermediate
bumps:

* `0.1.29 → 0.1.30`: Verified via `git show 42b7e03:lakefile.lean
  | grep version` to be commit `42b7e03` ("Audit pass:
  PathOnlyAlgEquivSigma cleanup + extended tests + docs"). The
  commit's title does not directly say "version bump", but the
  `lakefile.lean` diff shows the version-string change. The
  patch-level bump landed alongside the audit-pass cleanup of the
  Path-B σ-extraction module without a corresponding CLAUDE.md
  changelog entry.
* `0.1.30 → 0.2.0`: Verified via `git show 9f4b9ec:lakefile.lean
  | grep version` to be commit `9f4b9ec` ("Bump minor version:
  0.1.30 → 0.2.0"). The minor-version bump landed without a
  corresponding `CLAUDE.md` Workstream-status-tracker checkbox
  or per-workstream snapshot.

The audit characterises this as a "release messaging gap — external
readers comparing the on-disk `0.2.0` against the Workstream-K
snapshot's `version retains 0.1.5` or the Workstream-N1 `0.1.4 →
0.1.5` entry will see a 5-major-bump narrative gap."

**Strategy decision.** The audit recommends two strategies:

* **Strategy (a) — revert `0.2.0` to `0.1.30`:** Continue the `0.1.x`
  per-workstream bump pattern through v1.0.
* **Strategy (b) — add `CLAUDE.md` changelog entry:** Document the
  `0.1.29 → 0.1.30 → 0.2.0` chain explicitly with rationale.

**This plan adopts Strategy (b).** Rationale:

* **The `0.2.0` bump is intentional.** The R-TI Phase 3 partial-
  discharge work, the Manin chain, the PathOnlyAlgebra Path-B
  factoring, and the post-Workstream-A.6.4 audit-pass redesigns
  collectively represent a cohesive feature-complete branch. Per
  semver, `0.x → 0.(x+1)` minor bumps signal feature additions;
  the cluster is large enough to warrant a minor bump.
* **Reverting to `0.1.30` is a regression of intent.** The
  implementer chose `0.2.0` to mark the post-R-TI-Phase-3 cluster;
  reverting to `0.1.30` discards that signal.
* **Strategy (b) is the documentation-parity-restoration path.**
  CLAUDE.md is the canonical running-state source per the
  "Documentation rules"; restoring parity means updating
  CLAUDE.md, not regressing lakefile.

**Change recipe.**

* **Step 1 — verify current state.**
  ```bash
  grep -n "version :=" lakefile.lean
  # Expected: 13:  version := v!"0.2.0"
  grep -n "0\.1\.29\|0\.1\.30\|0\.2\.0" CLAUDE.md
  # Expected: only one match (Workstream-A.6.4 entry's "0.1.29")
  git log --oneline -- lakefile.lean | head -10
  # Expected: confirms the two intermediate commits
  ```

* **Step 2 — add `CLAUDE.md` per-workstream changelog entry.** A
  new sub-section is appended to the CLAUDE.md changelog,
  immediately after the R-TI Phase 3 — Path B Sub-task A.6.4
  entry, recording the version-bump chain.

  **Pre-edit verification.** Before drafting the entry, the
  implementer runs `git log --oneline -- lakefile.lean | head
  -10` to confirm the exact commit hash and title for each of
  the two bumps. The template below uses placeholder
  `<commit-29-to-30>` and `<commit-30-to-20>` markers that the
  implementer fills in with the verified commit hashes. The
  template's count claims (module-count delta, declaration-
  count delta, audit-script entry-count delta) should also be
  verified against CLAUDE.md's most recent values immediately
  before the entry lands; the delta values shown below are
  illustrative anchors, not authoritative.

  **Suggested entry text (with placeholders).**

  ```markdown
  ### CLAUDE.md changelog: post-Path-B documentation cluster (2026-04-28 / 2026-04-29)

  - **`0.1.29 → 0.1.30`** (commit `<commit-29-to-30>`,
    "<commit-29-to-30 title>"): patch-level bump capturing the
    intermediate state between the post-A.6.4 cluster and the
    `0.1.30 → 0.2.0` minor bump. No Lean source semantics
    change for this bump in isolation; counts unchanged from
    the post-A.6.4 state.

  - **`0.1.30 → 0.2.0`** (commit `<commit-30-to-20>`, "Bump
    minor version: 0.1.30 → 0.2.0"): minor-version bump
    signalling the feature-complete state of the post-R-TI-
    Phase-3 partial-discharge cluster. The cluster encompasses:
    R-TI Stages 0–5 (rigidity discharge plumbing); R-TI Phase 1
    (encoder slab evaluation); R-TI Phase 2 (path-block
    subspace + bridge); R-TI Phase 3 partial-discharge (the
    conditional GL³ → AlgEquiv-on-path-subspace bridge with the
    two named research-scope Props); the Manin tensor-stabilizer
    machinery (`StructureTensor.lean`, `BasisChange.lean`,
    `TensorStabilizer.lean`); the PathOnlyAlgebra Path-B
    factoring (`PathOnlyAlgebra.lean`,
    `PathOnlyAlgEquivSigma.lean`, `Discharge.lean`); the
    audit-pass-v2 cleanup of theatrical Path-B aliases. Per
    semver, `0.x → 0.(x+1)` minor bumps signal a cohesive
    feature cluster; the post-Path-B work qualifies. Module
    count delta from post-A.6.4 (75) to post-`0.2.0`
    (`<verify with find>`, currently 76); public-declaration
    count delta is consistent with the post-Path-B feature
    additions; the absolute count requires an A4-time grep
    recipe (see A3 Step 4 for the canonical command). The
    audit-script `#print axioms` count delta from post-A.6.4
    to post-`0.2.0` is verified with `grep -c "^#print axioms"
    scripts/audit_phase_16.lean` (currently 928). The zero-
    sorry / zero-custom-axiom posture is preserved across both
    bumps; the standard-trio-only axiom-dependency posture is
    preserved.

  This dual-bump entry closes audit finding A-02 / L-03a from
  the 2026-04-29 comprehensive audit, which flagged the
  absence of CLAUDE.md changelog entries for these
  intermediate bumps. Workstream-A4 of
  `docs/planning/AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md`
  is the implementation vehicle.
  ```

  The `<…>` placeholders MUST be filled in by the implementer
  before the PR opens; CI does not validate the placeholders,
  so the implementer is the last line of defense.

* **Step 3 — verify reconciliation.**
  ```bash
  grep -n "0\.1\.30\|0\.2\.0" CLAUDE.md | wc -l
  # Expected: ≥ 4 matches (two bump labels + cluster description + closure)
  ```

**Acceptance criteria.**

* **Mechanical:** `lakefile.lean` version unchanged (`0.2.0`).
  `CLAUDE.md` gains the `0.1.29 → 0.1.30 → 0.2.0` changelog entry.
* **Semantic:** A reader of CLAUDE.md sees the version-bump
  rationale; `lakefile.lean`'s `0.2.0` is no longer unexplained.
* **Build:** `lake build` unaffected (the lakefile version field
  is metadata only, not consumed by the build graph).

**Regression safeguard.** None — markdown / metadata edit.

**Estimated effort.** 30 minutes (verify git log + draft entry +
add to CLAUDE.md).

### 5.4 Workstream A risk register and rollback

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| A1's docstring rewrite accidentally breaks an unrelated `import` block (e.g., a stray `-/` terminator inserted mid-docstring) | Very low | Low (build break, immediately caught by `lake build`) | The change is to the `/- … -/` and `/-! … -/` text content only. The terminator placement is preserved. CI would catch any malformed comment. |
| A2's body sweep over `docs/VERIFICATION_REPORT.md` accidentally rewrites a historically-significant prior-snapshot reference | Low | Medium (document loses traceability) | Sed-style replacements are scoped only to header / table cells / "Method" prose lines that are documented as stale (M-01 finding L-04). Pre-2026-04-21 snapshot references in the Document history section are explicitly preserved. |
| A3's edit to `Orbcrypt.lean`'s docstring is mis-formatted, causing `lake build` to interpret as Lean code | Very low | High (build break) | The edit is inside an existing `/-! … -/` block. The `Edit` tool's exact-match `old_string` discipline prevents inadvertent terminator changes. CI catches any malformed comment. |
| A4's CLAUDE.md changelog entry contains a factual error about which commit landed which feature | Low | Low (corrected by future audit) | The entry uses git-log-derived commit hashes. The implementer should run `git log --oneline -- lakefile.lean` to confirm the commit hashes and titles before drafting. |

**Rollback plan.** Each work unit lands as its own PR. If a PR
introduces a regression (build break, audit-script error, etc.),
revert the PR and re-attempt with the corrected content. No
shared state across A1–A4; rolling back one unit does not affect
the others.

### 5.5 Workstream A exit criteria

1. **A1 lands:** `Orbcrypt/Hardness/PetrankRoth.lean`'s two
   docstring blocks (lines 9-19 and 38-52) are rewritten with
   per-layer status markers; `prEncode_iff`,
   `prEncode_codeSize_pos`, `prEncode_card_eq`, and
   `petrankRoth_isInhabitedKarpReduction` are honestly disclosed
   as research-scope (`R-15-residual-CE-reverse`).
2. **A2 lands:** `docs/VERIFICATION_REPORT.md`'s headline numbers
   are refreshed to 2026-04-29 reality (Strategy a + b hybrid).
   The header table cross-references CLAUDE.md for ephemeral
   metrics; invariants are listed explicitly. Document-history
   entry dated `2026-04-29` recorded.
3. **A3 lands:** `Orbcrypt.lean`'s Phase 16 snapshot section
   (lines 1279-1314) is refreshed to 2026-04-29 reality. Snapshot
   header date updated; module count, declaration count, audit-
   script count, private-helper count, and `lake build` job count
   refreshed.
4. **A4 lands:** `CLAUDE.md` gains the
   `0.1.29 → 0.1.30 → 0.2.0` changelog entry; lakefile version
   unchanged (preserves `0.2.0`).
5. **Build / audit script clean:** `lake build` succeeds with
   3,426+ jobs, zero errors, zero warnings;
   `scripts/audit_phase_16.lean` runs cleanly (exit 0; standard-
   trio-only axioms across all 928+ checks).
6. **CLAUDE.md change-log entry recorded:** A new Workstream-A
   snapshot section is appended to CLAUDE.md immediately after the
   2026-04-23 audit's Workstream entries, summarising A1/A2/A3/A4
   and citing this plan as the implementation vehicle.

## 6. Workstream B — Recommended pre-release polish

**Severity.** LOW (A-01/H-03a, A-06, L-01, C-13b).
**Effort.** ≈ 50 min serial.
**Scope.** File-level cleanup; no Lean source semantics changes.

### 6.1 Problem statement

Four LOW-severity hygiene findings that are not release-blocking
but are recommended pre-tag polish per the audit's § N-02:

1. **A-01 / H-03a:** `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean`
   (110 LOC) is documented as a transient stub by its own header
   docstring ("This file is **transient**: per Decision GQ-D, it
   should be deleted at the end of Layer T1") and by CLAUDE.md.
   It is not imported by `Orbcrypt.lean`. It is still picked up by
   `lake build` via `srcDir := "."` glob, inflating module counts
   and confusing the dependency-graph documentation. Per CLAUDE.md
   "If you are certain that something is unused, you can delete it
   completely", this is the situation that rule describes.

2. **A-06:** Six legacy per-workstream audit scripts under
   `scripts/`:
   - `scripts/audit_a7_defeq.lean` (1.7 KB)
   - `scripts/audit_b_workstream.lean` (6.6 KB)
   - `scripts/audit_c_workstream.lean` (10.8 KB)
   - `scripts/audit_d_workstream.lean` (12.7 KB)
   - `scripts/audit_e_workstream.lean` (21.3 KB)
   - `scripts/audit_phase15.lean` (1.5 KB)
   - `scripts/audit_print_axioms.lean` (1.9 KB)

   These are documented as superseded by `audit_phase_16.lean`
   (per the audit script's own preamble: "The script supersedes
   per-workstream audit files (`audit_b_workstream`,
   `audit_c_workstream`, ...) by covering every public declaration
   in a single pass. Those per-workstream scripts remain for
   historical reference but are not exercised by CI."). CI does
   not run them; they are not imported by any module.

3. **L-01:** `README.md:53` declares `Phase-16 audit script | 382+
   #print axioms checks; standard Lean trio only (propext,
   Classical.choice, Quot.sound)`. Reality: 928 entries. The
   numerical claim understates the actual posture by ~2.4×.

4. **C-13b:** `Orbcrypt/KEM/CompSecurity.lean:392-405` carries a
   14-line `--`-prefixed comment block describing post-Workstream-I
   deletions. The audit notes this is "good honest disclosure but
   the `--`-comment block is ~14 lines long; consider compacting
   to a single docstring on a sibling theorem if more context
   evolves."

### 6.2 Fix scope

Workstream **B** performs the recommended pre-release polish:

1. **B1:** Delete `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean`
   outright (Strategy a per audit), updating CLAUDE.md's transient-
   file note accordingly.
2. **B2:** Move the six legacy audit scripts to
   `scripts/legacy/` with a `scripts/legacy/README.md` explaining
   the historical-reference status (Strategy b per audit).
3. **B3:** Refresh `README.md:53` audit-script count to current
   reality.
4. **B4:** Compact the 14-line `--`-comment block in
   `Orbcrypt/KEM/CompSecurity.lean:392-405` into a one-paragraph
   docstring annotation on the immediately-following declaration.

### 6.3 Work units

#### B1 — Delete transient `_ApiSurvey.lean` (A-01 / H-03a)

**File.** `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean` (delete).

**Severity.** LOW.

**Problem.** The file's own header docstring explicitly states it is
transient: "This file is **transient**: per Decision GQ-D, it
should be deleted at the end of Layer T1 once the API has been
exercised by the live `PathAlgebra.lean` / `StructureTensor.lean`
imports and the survey is no longer informative." Layer T1 has
since been fully landed (per the R-TI Phase 1 / Layer T1 entries in
CLAUDE.md). The file is no longer informative.

**Strategy decision.** The audit recommends two options:

* **Strategy (a):** Delete the file outright.
* **Strategy (b):** Move to `docs/research/` as a non-`.lean`
  companion to the existing `grochow_qiao_path_algebra.md` etc.

**This plan adopts Strategy (a).** Rationale:

* The file's purpose ("regression sentinel against API drift on
  the pinned Mathlib commit `fa6418a8`") is now redundant — the
  *live* imports in `PathAlgebra.lean` / `StructureTensor.lean` /
  etc. are themselves the regression sentinel; if the Mathlib API
  drifted, those modules would fail to build, not the survey
  stub.
* Strategy (b) (relocation to `docs/research/`) requires
  converting Lean `example` content to markdown prose, which
  loses the type-checking discipline that made the survey useful
  in the first place. The two existing `docs/research/*.md`
  files are paper synthesis notes, not Lean elaboration tests.
* The Lean stub is 110 LOC and contains only `#check` and
  `example` lines; deleting it loses no information that is not
  also captured by the live module imports.

**Change recipe.**

* **Step 1 — verify no consumers.**
  ```bash
  grep -rn "_ApiSurvey" Orbcrypt scripts docs CLAUDE.md
  # Expected: only docstring/comment matches in CLAUDE.md (Workstream
  # R-TI Phase 1 Layer T0 entry) and the audit script; never an `import`
  # statement, never a `def`/`theorem` reference
  ```

* **Step 2 — delete the file.**
  ```bash
  rm Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean
  ```

* **Step 3 — update CLAUDE.md.** The R-TI Phase 1 / Layer T0
  entry currently reads:
  > Plus the transient `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean`
  > Lean stub exercising the Mathlib API at the planned types.

  Replace with:
  > Plus a transient `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean`
  > Lean stub (subsequently deleted by Workstream **B1** of the
  > 2026-04-29 audit plan after the live `PathAlgebra.lean` /
  > `StructureTensor.lean` modules superseded its regression-
  > sentinel purpose) exercising the Mathlib API at the planned
  > types.

* **Step 4 — verify build.**
  ```bash
  source ~/.elan/env && lake build
  # Expected: succeeds; module count drops from 76 to 75
  find Orbcrypt -name '*.lean' | wc -l
  # Expected: 75
  ```

**Acceptance criteria.**

* **Mechanical:** `find Orbcrypt -name '*.lean' | wc -l` returns
  **75**.
* **Build:** `lake build` succeeds with one fewer build job.
* **Audit script:** `scripts/audit_phase_16.lean` runs unchanged
  (the `_ApiSurvey.lean` declarations were not in the audit
  script's `#print axioms` list — verified by `grep
  "_ApiSurvey"` above; only one match in the script comment, not
  a `#print axioms` line).
* **Documentation:** CLAUDE.md's Layer T0 entry reflects the
  deletion.

**Regression safeguard.** None — file is unused.

**Estimated effort.** 5 minutes.

#### B2 — Relocate legacy per-workstream audit scripts (A-06)

**Files.**
- `scripts/audit_a7_defeq.lean` → `scripts/legacy/audit_a7_defeq.lean`
- `scripts/audit_b_workstream.lean` → `scripts/legacy/audit_b_workstream.lean`
- `scripts/audit_c_workstream.lean` → `scripts/legacy/audit_c_workstream.lean`
- `scripts/audit_d_workstream.lean` → `scripts/legacy/audit_d_workstream.lean`
- `scripts/audit_e_workstream.lean` → `scripts/legacy/audit_e_workstream.lean`
- `scripts/audit_phase15.lean` → `scripts/legacy/audit_phase15.lean`
- `scripts/audit_print_axioms.lean` → `scripts/legacy/audit_print_axioms.lean`

`scripts/audit_phase_16.lean` **stays** at `scripts/`.

**Severity.** LOW.

**Problem.** Six historical scripts are documented as superseded
by `audit_phase_16.lean`. CI does not run them. Their continued
presence at the top-level `scripts/` directory creates the
appearance that they are active CI artefacts when in fact they
are archive material.

**Strategy decision.** The audit recommends two options:

* **Strategy (a):** Add a CI step that runs each legacy script
  on every build, turning them into "live regression sentinels".
* **Strategy (b):** Move them to `scripts/legacy/` to make their
  archive status explicit.

**This plan adopts Strategy (b).** Rationale:

* The legacy scripts duplicate content already exercised by
  `audit_phase_16.lean`. Making them live regression sentinels
  doubles the CI cost without adding regression coverage.
* The ongoing maintenance burden (every Lean / Mathlib bump
  requires re-validating each legacy script) outweighs their
  archival value at the live `scripts/` directory.
* Strategy (b) preserves the historical content (deletion would
  lose audit-trail traceability) while making the archive status
  explicit at the file-system level.

**Change recipe.**

* **Step 1 — create archive directory.**
  ```bash
  mkdir -p scripts/legacy
  ```

* **Step 2 — move the six legacy scripts.**
  ```bash
  cd scripts
  for f in audit_a7_defeq.lean audit_b_workstream.lean \
           audit_c_workstream.lean audit_d_workstream.lean \
           audit_e_workstream.lean audit_phase15.lean \
           audit_print_axioms.lean; do
    git mv "$f" "legacy/$f"
  done
  ```

  Use `git mv` rather than plain `mv` to preserve git history
  attribution.

* **Step 3 — write `scripts/legacy/README.md`.** The README
  explains the archive status:

  ```markdown
  # Legacy per-workstream audit scripts

  This directory contains historical audit scripts from prior
  Orbcrypt audit cycles. Each script exercises a specific
  workstream's `#print axioms` checks at the time the workstream
  landed.

  **Status: archive only — not run by CI.**

  The authoritative audit script is `scripts/audit_phase_16.lean`
  at the parent directory. It supersedes every script in this
  directory by exercising every public declaration in a single
  pass.

  ## File index

  | Script | Workstream | Audit cycle | Status |
  |--------|------------|-------------|--------|
  | `audit_a7_defeq.lean` | Workstream A7 (defeq checks) | 2026-04-18 | archived |
  | `audit_b_workstream.lean` | Workstream B (adversary refinements) | 2026-04-18 | archived |
  | `audit_c_workstream.lean` | Workstream C (MAC integrity) | 2026-04-18 | archived |
  | `audit_d_workstream.lean` | Workstream D (Code Equivalence API) | 2026-04-18 | archived |
  | `audit_e_workstream.lean` | Workstream E (probabilistic chain) | 2026-04-18 | archived |
  | `audit_phase15.lean` | Phase 15 (decryption optimisation) | 2026-04-20 | archived |
  | `audit_print_axioms.lean` | Pre-Phase-16 axiom-print baseline | various | archived |

  ## Re-running for historical reference

  If you need to re-run a legacy script (e.g., for archeological
  audit-trail recovery), invoke from the repository root:

  ```bash
  source ~/.elan/env
  lake env lean scripts/legacy/<script-name>.lean
  ```

  Note that the legacy scripts have not been re-validated against
  the current Lean toolchain or Mathlib pin since the audit cycle
  in which they originally landed. They may fail to elaborate
  against the current pin; if so, this is *expected* archive
  behaviour and not a regression.

  ## Why not delete?

  These scripts preserve the per-workstream audit trail. Each was
  the canonical regression sentinel for its workstream at the
  time it landed; deleting them would lose that historical
  cross-reference. The post-2026-04-29 plan moved them to this
  archive directory rather than deleting them, on the principle
  that archive material is cheap to retain and expensive to
  reconstruct.

  ## Authoritative current sentinel

  `scripts/audit_phase_16.lean` (4628 LOC, 928 `#print axioms`
  entries, 238 non-vacuity `example` bindings as of 2026-04-29)
  is the current regression sentinel. It is run by every CI
  invocation and is the document-of-record for the running
  posture (zero `sorry`, zero custom axioms, standard-trio-only
  axiom dependencies).
  ```

* **Step 4 — update `scripts/audit_phase_16.lean` preamble.** The
  preamble currently references the legacy scripts by their
  pre-relocation paths (e.g., "supersedes per-workstream audit
  files (`audit_b_workstream`, `audit_c_workstream`, …)"). Update
  to reference the new paths under `scripts/legacy/`:

  ```
  -- supersedes per-workstream audit files
  -- (`scripts/legacy/audit_b_workstream.lean`,
  -- `scripts/legacy/audit_c_workstream.lean`, …) by covering every
  -- public declaration in a single pass. Those per-workstream
  -- scripts are archived under `scripts/legacy/`; this directory's
  -- README.md documents the archive status.
  ```

* **Step 5 — update `.github/workflows/lean4-build.yml` if
  needed.** The workflow currently runs `lake env lean
  scripts/audit_phase_16.lean` (line 175 region per audit). This
  path is unchanged. No CI workflow edit required.

* **Step 6 — verify.**
  ```bash
  ls scripts/legacy/
  # Expected: README.md + 7 .lean files
  ls scripts/audit_*.lean
  # Expected: only audit_phase_16.lean (the active sentinel)
  ```

**Acceptance criteria.**

* **Mechanical:** `ls scripts/audit_*.lean` returns only
  `scripts/audit_phase_16.lean`.
* **Mechanical:** `ls scripts/legacy/` returns `README.md` plus
  the seven moved files.
* **Build:** `lake build` succeeds (the legacy scripts are
  outside the `srcDir := "."` glob anyway, so this step is
  unaffected).
* **CI:** `.github/workflows/lean4-build.yml` runs unchanged.
* **Audit script:** `scripts/audit_phase_16.lean`'s preamble is
  updated; running it produces unchanged output.

**Regression safeguard.** None — file relocation, no semantic
change.

**Estimated effort.** 25 minutes (move scripts + write README +
update audit-script preamble).

#### B3 — Refresh `README.md` audit-script count (L-01)

**File.** `README.md`, line 53.

**Severity.** LOW.

**Problem.** The "Snapshot metrics" or equivalent table in
`README.md` currently reads:
> Phase-16 audit script | 382+ `#print axioms` checks; standard
> Lean trio only (`propext`, `Classical.choice`, `Quot.sound`)

Reality: the audit script contains 928 `#print axioms` entries
(per `grep -c "^#print axioms" scripts/audit_phase_16.lean`).
The numerical claim understates by ~2.4×.

**Change recipe.**

* **Step 1 — verify current value.**
  ```bash
  grep -n "382" README.md
  # Expected: line 53 with the stale number
  grep -c "^#print axioms" scripts/audit_phase_16.lean
  # Expected: 928
  ```

* **Step 2 — update the line.** Replace:
  ```
  | Phase-16 audit script | 382+ `#print axioms` checks; standard Lean trio only (`propext`, `Classical.choice`, `Quot.sound`) |
  ```
  with:
  ```
  | Phase-16 audit script | 900+ `#print axioms` checks; standard Lean trio only (`propext`, `Classical.choice`, `Quot.sound`) |
  ```

  The "900+" form (rather than the precise 928) is intentional —
  the precise count tracks CLAUDE.md's running changelog and
  shifts at every workstream landing. README.md should not
  carry a precise count that goes stale on every PR.

* **Step 3 — verify.**
  ```bash
  grep -n "382" README.md
  # Expected: zero matches
  grep -n "900" README.md
  # Expected: line 53
  ```

**Acceptance criteria.**

* **Mechanical:** `grep -n "382" README.md` returns no matches.
* **Semantic:** A reader of README.md no longer encounters an
  understated audit-script count.

**Regression safeguard.** None — markdown edit.

**Estimated effort.** 5 minutes.

#### B4 — Compact post-Workstream-I deletion comment block (C-13b)

**File.** `Orbcrypt/KEM/CompSecurity.lean:392-405` (~14 lines).

**Severity.** LOW.

**Problem.** The 14-line `--`-comment block:
```
-- Note: pre-Workstream-I this section contained
-- `concreteKEMOIA_one_meaningful`, a redundant duplicate of
-- `kemAdvantage_le_one` (line 347 above). Workstream I2 of the
-- 2026-04-23 audit (finding E-11) deleted that lemma — consumers
-- migrate to `kemAdvantage_le_one` for the trivial `≤ 1` sanity
-- bound. The original Workstream-I2 replacement
-- `concreteKEMOIA_uniform_zero_of_singleton_orbit` (perfect-security
-- ε = 0 on degenerate singleton-orbit KEMs) was removed by the
-- post-Workstream-I audit (2026-04-25) as theatrical: it required
-- the KEM to have only one possible ciphertext, collapsing the
-- security game. The honest non-vacuity story for
-- `ConcreteKEMOIA_uniform` is the trivial `≤ 1` bound via
-- `concreteKEMOIA_uniform_one`.
```

The audit notes this is "good honest disclosure" but the long
comment block in the middle of the source code creates visual
clutter and can be compacted into a docstring annotation on a
sibling theorem.

**Strategy decision.** The audit recommends compacting "if more
context evolves." Since no context has evolved since the
2026-04-25 audit (no further deletions / additions touched this
section), the choice is:

* **Strategy (a) — leave as-is:** The comment is honest and
  tracks history. Audit recommendation is "Optional".
* **Strategy (b) — compact to docstring annotation:** Move the
  content to the docstring of the immediately-following
  declaration (which the comment is implicitly annotating)
  using a "Historical note (audit 2026-04-25)" subsection.

**This plan adopts Strategy (b)** with a soft-form approach:
keep the existing comment block but reduce it from ~14 lines
to ~6 lines, retaining the essential historical pointer while
removing the verbose narrative.

**Change recipe.**

* **Step 1 — read current block.**
  ```bash
  sed -n '390,410p' Orbcrypt/KEM/CompSecurity.lean
  ```

* **Step 2 — replace with compacted form.**

  Replace the 14-line block with the following 6-line condensed
  form:
  ```
  -- Pre-Workstream-I (audit 2026-04-23 finding E-11): this
  -- section held `concreteKEMOIA_one_meaningful` (deleted —
  -- duplicated `kemAdvantage_le_one`). The 2026-04-25 follow-up
  -- audit further removed `concreteKEMOIA_uniform_zero_of_singleton_orbit`
  -- as theatrical (singleton-orbit hypothesis collapses the
  -- game). Honest non-vacuity story: `concreteKEMOIA_uniform_one`.
  ```

  This preserves all four reference points (pre-I lemma name,
  audit-finding ID, post-I deletion timestamp, current honest
  non-vacuity witness) in 6 lines instead of 14, freeing 8
  lines of vertical space without losing traceability.

* **Step 3 — verify.**
  ```bash
  wc -l < <(sed -n '390,410p' Orbcrypt/KEM/CompSecurity.lean)
  # Expected: drops by ~8 lines
  source ~/.elan/env && lake build Orbcrypt.KEM.CompSecurity
  # Expected: succeeds (comment-only edit)
  ```

**Acceptance criteria.**

* **Mechanical:** Line count of `Orbcrypt/KEM/CompSecurity.lean`
  drops by ~8 lines.
* **Semantic:** The historical pointer is preserved (pre-I name,
  audit-finding ID, post-I removal date, current witness).
* **Build:** `lake build Orbcrypt.KEM.CompSecurity` succeeds.

**Regression safeguard.** None — comment-only edit.

**Estimated effort.** 10 minutes (read + edit + verify).

### 6.4 Workstream B risk register and rollback

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| B1's deletion of `_ApiSurvey.lean` accidentally removes a non-archive declaration | Very low | Medium (lost code) | Verify `grep -rn "_ApiSurvey" Orbcrypt scripts docs` before deletion; only docstring/comment matches should appear. |
| B2's `git mv` breaks an unnoticed CI invocation of a legacy script | Low | Low (CI workflow has only `audit_phase_16.lean`) | Verify `.github/workflows/lean4-build.yml` does not reference the legacy script paths; if it does, the workflow is updated in the same PR. |
| B3's README.md edit accidentally rewrites a different metric | Very low | Low | The `Edit` tool's exact-match `old_string` discipline prevents inadvertent edits. |
| B4's comment compaction loses an essential reference point | Low | Low | The 6-line replacement explicitly preserves all four reference points listed in the audit. |

**Rollback plan.** Each work unit lands as its own PR. B1's
deletion is recoverable via `git revert` (with the file content
preserved in git history). B2's `git mv` is recoverable via the
inverse `git mv`. B3 and B4 are markdown / comment edits with
trivial rollback.

### 6.5 Workstream B exit criteria

1. **B1 lands:** `_ApiSurvey.lean` deleted; module count drops
   from 76 to 75; CLAUDE.md's R-TI Phase 1 / Layer T0 entry
   reflects the deletion.
2. **B2 lands:** Six legacy scripts moved to `scripts/legacy/`;
   `scripts/legacy/README.md` written; `scripts/audit_phase_16.lean`
   preamble updated.
3. **B3 lands:** `README.md`'s audit-script count updated to
   "900+" (a deliberately-imprecise count that resists
   per-PR staleness).
4. **B4 lands:** `Orbcrypt/KEM/CompSecurity.lean:392-405` 14-line
   `--`-comment block compacted to 6 lines.
5. **Build / audit script clean:** `lake build` succeeds; the
   audit script runs cleanly with the same posture (zero `sorry`,
   zero custom axioms, standard-trio-only).
6. **CLAUDE.md change-log entry recorded:** A new Workstream-B
   snapshot section is appended to CLAUDE.md.

## 7. Workstream C — Optional v1.1+ engineering enhancements

**Severity.** INFO (A-03, A-04, A-05, A-08, D-02a, B-03a, B-03b,
C-03a, C-13a, F-03a).
**Effort.** Defer all to v1.1+ / v2.0.
**Scope.** Defense-in-depth and hygiene improvements; not
release-blocking.

### 7.1 Problem statement

Five INFO-class engineering enhancements and five INFO-class "no
action needed" docstring observations. None block v1.0; the audit's
§ N-03 explicitly defers them.

The five engineering enhancements:

1. **A-03:** `lakefile.lean:30-31` uses `srcDir := "."` plus the
   default-pickup glob. This builds every `.lean` file under
   `srcDir` automatically, including transient stubs. Acceptable
   for v1.0; v1.1+ may want explicit globs.

2. **A-04:** `scripts/setup_lean_env.sh:252-262` `fast_path_ready()`
   verifies presence of `${tc_dir}/bin/lean` and
   `${tc_dir}/lib/crti.o` but not their content hashes. Defense-
   in-depth opportunity.

3. **A-05:** `.github/workflows/lean4-build.yml:60-94` "Verify no
   sorry" step uses Perl non-greedy `/-.*?-/` regex. Cannot parse
   nested block comments. Self-disclosed limitation; the `lake
   build` step is the definitive guard, and the audit confirmed
   no nested-comment regressions in the current tree.

4. **A-08:** `lake-manifest.json` is a critical reproducibility
   surface. Audit workflow includes it in the cache key but does
   not perform a content audit on it. Recommendation: add a
   `lake update --dry-run` CI step.

5. **D-02a:** `Orbcrypt/Construction/HGOE.lean:88-113` claims the
   Lean / GAP `CanonicalImage` produce identical canonical images
   on every concrete input "for every orbit O under any subgroup
   G ≤ S_n". Currently verified at small `n` (m = 2, 3) via
   `decide`-based audit-script examples. A formal symbolic proof
   at arbitrary `n` would strengthen the claim.

The five "no action needed" docstring observations (B-03a, B-03b,
C-03a, C-13a, F-03a) are explicitly flagged by the audit as
acceptable as-is. They are listed for completeness only.

### 7.2 Fix scope

Workstream **C** **does not produce v1.0 deliverables.** Every work
unit is tracked here for v1.1+ planning. The work-unit specifications
below are skeletons; full implementation guidance is deferred to a
future audit cycle (likely the v1.1 release planning).

### 7.3 Work units (v1.1+ skeletons)

#### C1 — Make lakefile globs explicit (A-03, v1.1+)

**File.** `lakefile.lean:30-31`.

**Skeleton.** Replace `lean_lib Orbcrypt where srcDir := "."` with
explicit per-module globs to prevent transient stubs from being
built unintentionally. Sample:

```lean
lean_lib Orbcrypt where
  srcDir := "."
  globs := #[
    .submodules `Orbcrypt
  ]
```

**Status.** Deferred to v1.1+. Acceptable for v1.0; the Workstream
**B1** removal of `_ApiSurvey.lean` already addresses the immediate
"transient stub builds silently" concern.

#### C2 — Defense-in-depth toolchain content check (A-04, v1.1+)

**File.** `scripts/setup_lean_env.sh:252-262`.

**Skeleton.** Add a one-time SHA-256 verification on cached
toolchain `bin/lean` and `bin/lake` binaries at fast-path entry.
Sample:

```bash
fast_path_ready() {
  if [ -f "${ELAN_ENV_FILE}" ]; then
    source "${ELAN_ENV_FILE}"
  fi
  command -v lake >/dev/null 2>&1 || return 1
  local tc_dir="${ELAN_HOME_DIR}/toolchains/${TOOLCHAIN_DIR_NAME}"
  [ -x "${tc_dir}/bin/lean" ] || return 1
  [ -f "${tc_dir}/lib/crti.o" ] || return 1

  # v1.1+ — defense-in-depth: verify cached binary integrity
  local actual_sha
  actual_sha=$(sha256sum "${tc_dir}/bin/lean" | cut -d' ' -f1)
  [ "${actual_sha}" = "${EXPECTED_LEAN_BIN_SHA256}" ] || return 1

  return 0
}
```

**Status.** Deferred to v1.1+. The threat model (local write
access to `~/.elan/`) is already game-over; this is purely
defense-in-depth.

#### C3 — Upgrade CI sorry-strip to handle nested block comments (A-05, v1.1+)

**File.** `.github/workflows/lean4-build.yml`.

**Skeleton.** Replace the non-greedy `/-.*?-/` Perl regex with a
recursive pattern that handles arbitrarily-nested `/- … -/`
blocks. Recursive Perl regex sample:

```perl
# Recursive comment-stripping regex (v1.1+)
my $pattern = qr/(\/\-(?:[^\/\-]|\/(?!-)|-(?!\/)|(?1))*-\/)/;
```

**Status.** Deferred to v1.1+. The `lake build` step (step 4 of
the workflow) is the definitive `sorry` guard via Lean's own
parser; the comment-strip regex is a fast pre-filter only, and
the audit confirmed no nested-comment regressions in the current
tree.

#### C4 — Add CI lake-manifest drift check (A-08, v1.1+)

**File.** `.github/workflows/lean4-build.yml`.

**Skeleton.** Add a new CI step after the existing build / sorry-
check / axiom-check / Phase-16-audit steps:

```yaml
- name: Verify lake-manifest.json has not drifted
  run: |
    source ~/.elan/env
    lake update --dry-run > /tmp/dry_run.log 2>&1
    if grep -q "would update" /tmp/dry_run.log; then
      echo "ERROR: lake-manifest.json drift detected"
      cat /tmp/dry_run.log
      exit 1
    fi
```

**Status.** Deferred to v1.1+. The current cache-key inclusion of
`lake-manifest.json` already invalidates the cache on any drift;
adding an explicit drift check is defense-in-depth.

#### C5 — Formal GAP/Lean canonical-image equivalence at arbitrary `n` (D-02a, v1.1+ research-scope)

**File.** New theorem in `Orbcrypt/Construction/HGOE.lean` or a
new module under `Orbcrypt/Construction/`.

**Skeleton.** A symbolic proof that for every `n : ℕ`, every
finite subgroup `G ≤ S_n`, and every `x : Bitstring n`,
`CanonicalForm.ofLexMin G x` (Lean side) equals
`CanonicalImage(G, support(x), OnSets)` (GAP side, when both are
encoded into the same canonical-form-extraction discipline).

The proof requires either (a) a Lean specification of GAP's
`OnSets` action and a theorem connecting it to the
`bitstringLinearOrder` lex order, or (b) a model-theoretic
correspondence theorem at the abstract algebra level.

**Status.** Research-scope (v1.1+ or v2.0). The current
small-`n` `decide`-based witnesses are persuasive evidence for
the GAP/Lean equivalence claim, and the prose disclosure in
`Construction/HGOE.lean:88-113` is honestly bounded ("matching
the GAP reference implementation's choice of orbit
representative exactly").

#### C6 — INFO docstring observations (no action needed)

The following five INFO findings from the audit are
explicitly disclosed as "no action needed" or "intentional API
design" by the audit itself. They are listed here for
completeness; no work unit is generated.

* **B-03a:** `bitstringLinearOrder` requires `letI` discipline
  at call sites. Disclosure in
  `Construction/Permutation.lean`'s docstring is exemplary and
  intentional — global registration would create a
  `Pi.partialOrder` diamond.
* **B-03b:** `orbitFintype` global instance inherited by
  every importer of `CanonicalLexMin`. Benign; flagged for
  future awareness only.
* **C-03a:** `-- Justification:` comment block on a `def` (the
  `OIA` definition) rather than an `axiom`. Consistent with
  the rule's spirit (the rule was originally written for
  `axiom` declarations; here the justification block is
  attached to a Prop-valued `def` carrying assumption
  semantics, which warrants the same rationale documentation).
* **C-13a:** Import of `Orbcrypt.Hardness.Reductions` places
  the KEM chain above the scheme chain in the dependency graph.
  Intentional layering; CLAUDE.md correctly records this.
* **F-03a:** `_hDistinct` underscore-prefixed parameter on
  `concrete_hardness_chain_implies_1cpa_advantage_bound_distinct`
  (Workstream K4 of audit 2026-04-21). Intentional API design;
  honestly disclosed in the docstring.

### 7.4 Workstream C exit criteria

**No exit criteria for v1.0.** Workstream **C** is a tracking
container. Each work unit's exit criteria will be defined when
the corresponding v1.1+ workstream is opened.

## 8. Workstream D — Research-scope catalogue

**Severity.** research (deferred to v1.1+ / v2.0).
**Effort.** Multi-month per item; no v1.0 work.
**Scope.** Tracking only — never closes.

### 8.1 Catalogue contents

The 2026-04-29 audit's § N-04 catalogues six research milestones,
all already documented in CLAUDE.md and prior audit plans. This
section preserves continuity by listing each item with its
current status.

| ID | Topic | Tracking location | Estimated effort | Audit cycle |
|----|-------|-------------------|------------------|-------------|
| **R-09** | Discharge of `h_step` in `indQCPA_from_perStepBound` from `ConcreteOIA scheme ε` alone — per-coordinate marginal-independence over `uniformPMFTuple` | CLAUDE.md (Workstream C of audit 2026-04-23, finding V1-8 / C-13 / D10) | ~40-60 hours | tracked since 2026-04-18 |
| **R-12** | Tight `1/4` ε-bound on `ObliviousSamplingConcreteHiding` for the `concreteHidingBundle` + `concreteHidingCombine` fixture (post-Workstream-I non-degenerate fixture) | CLAUDE.md (Workstream I, audit 2026-04-23 / 2026-04-25 honest-delivery refactor) | ~20-30 hours | tracked since 2026-04-25 |
| **R-13** | `Bitstring n → ZMod p` orbit-preserving adapter making `carterWegmanMAC_int_ctxt` compose with HGOE | CLAUDE.md (Workstream A finding V1-7 / D4 / I-08 of 2026-04-23 audit) | ~80-120 hours | tracked since 2026-04-23 |
| **R-15-residual-CE-reverse** | PetrankRoth Layers 4.1–4.10 (full marker-forcing reverse direction), Layer 5 (`prEncode_iff` assembly), Layer 6 (non-degeneracy bridge), Layer 7 (`petrankRoth_isInhabitedKarpReduction`) | `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` § 4–§ 7 | ~800-1500 LOC, 7-14 days dedicated work | tracked since 2026-04-25 |
| **R-15-residual-TI-reverse** | Grochow–Qiao Layer T5 rigidity argument | `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` Layer T5 | ~80 pages on paper, ~1,800 LOC of Lean | tracked since 2026-04-25 |
| **R-15-residual-TI-forward-matrix** | Grochow–Qiao Layer T3.6 full matrix-action upgrade | `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` Layer T3.6 | ~400 LOC | tracked since 2026-04-25 |

### 8.2 What this Workstream does NOT do

* **Does not** alter the research catalogue's existing tracking
  in CLAUDE.md or in the prior audit plans. This Workstream's
  function is purely informational — a continuity reference.
* **Does not** introduce any v1.0 work. None of the catalogued
  items are release-blocking.
* **Does not** claim status changes on the catalogued items.
  The audit's § M-03 explicitly confirms "the 5 research-scope
  Props in the GrochowQiao subtree (`GrochowQiaoRigidity`,
  `GL3PreservesPartitionCardinalities`,
  `GL3InducesArrowPreservingPerm`,
  `GL3InducesAlgEquivOnPathSubspace`,
  `RestrictedGL3OnPathOnlyTensor`) are honestly scoped with
  substantive identity-case witnesses" — this status is preserved.

### 8.3 Why these items are explicitly research-scope

Per CLAUDE.md's Key Conventions and the prior audit plans, the
catalogued items have these characteristics:

* They are **named and isolated** — each item is a single named
  `Prop` (`GrochowQiaoRigidity`, etc.) with substantive identity-
  case witnesses, or a single named hypothesis (`h_step`,
  `hOrbitCover`-equivalent for the HGOE adapter, etc.) carried as
  an explicit theorem-level argument.
* They are **honestly disclosed** — every consumer of a
  research-scope `Prop` carries the `Prop` as an explicit
  hypothesis, never silently assumes its truth.
* They are **multi-month** — each requires either substantial
  Lean infrastructure (Manin tensor-stabilizer machinery for
  R-15-residual-TI-reverse), substantial new mathematical
  content (the per-coordinate marginal-independence proof for
  R-09), or both.
* They are **non-cryptographic correctness obstacles** — the
  zero-sorry / zero-custom-axiom posture is unaffected. Each
  item is a *quantitative tightening* of an already-conditional
  result, not a correctness gap.

### 8.4 Workstream D exit criteria

**Workstream D never closes.** It is a tracking container that
persists across audit cycles. Each catalogued item migrates to
its own dedicated workstream (and its own dedicated planning
document) when v1.1+ / v2.0 prioritisation makes the item
release-blocking for a future tag.

## 9. Regression safeguards

This section enumerates the per-PR regression checks that every
Workstream **A** and **B** PR must pass before merging. The
safeguards are non-negotiable: a PR that fails any check is
rejected.

### 9.1 Pre-PR local checks (developer-side)

Before opening a PR, the implementer runs:

1. **`lake build`** — must succeed with exit 0. Workstream A and
   B make only documentation-level edits, so the build is
   expected to be a no-op or near-no-op. A regression here is a
   developer error (e.g., unbalanced `/-` `-/` markers).

2. **`scripts/audit_phase_16.lean` invocation** — must succeed
   with exit 0. Specifically:
   ```bash
   source ~/.elan/env
   lake env lean scripts/audit_phase_16.lean > /tmp/audit_output.log 2>&1
   echo $?  # Expected: 0
   grep -c "sorryAx" /tmp/audit_output.log  # Expected: 0
   ```
   This catches any regression that introduces a hidden `sorry`
   or a custom axiom into the dependency chain. Workstream A
   and B should not affect this output, but the safeguard
   confirms.

3. **Comment-aware sorry scan** — must return zero:
   ```bash
   for f in $(find Orbcrypt -name '*.lean'); do
     perl -0777 -pe 's/\/-.*?-\///gs' "$f" | grep -c '\bsorry\b'
   done | awk '$1>0'
   # Expected: empty output
   ```
   This catches the case where a docstring rewrite accidentally
   includes the word "sorry" outside a comment.

4. **Axiom-declaration scan** — must return zero:
   ```bash
   grep -rE "^axiom\s+\w+" Orbcrypt --include="*.lean"
   # Expected: empty output
   ```

5. **Module count check** — confirms expected change:
   ```bash
   find Orbcrypt -name '*.lean' | wc -l
   # Expected post-A: 76 (unchanged)
   # Expected post-B1: 75 (one file deleted)
   # Expected post-B2: 75 (B2 only moves files outside Orbcrypt/)
   ```

### 9.2 CI-side regression safeguards

Every PR triggers `.github/workflows/lean4-build.yml`:

1. **Step 1 — Build:** `lake build Orbcrypt` succeeds with zero
   warnings, zero errors. CI fails if any warning is emitted
   (the workflow uses `-Dwarningsaserrors=true` per the lakefile
   leanOptions).
2. **Step 2 — Verify no sorry:** comment-aware Perl strip + grep
   for `\bsorry\b`. Returns zero matches.
3. **Step 3 — Verify no unexpected axioms:** grep for
   `^axiom\s+\w+`. Returns zero matches.
4. **Step 4 — Phase 16 audit script:** `lake env lean
   scripts/audit_phase_16.lean` succeeds; output is parsed for
   non-standard axioms; returns zero non-trio-axiom usages.

### 9.3 Workstream-A-specific safeguards

| Work unit | Safeguard |
|-----------|-----------|
| **A1** | Re-verify that the rewritten docstring does NOT introduce a Lean declaration sharing the names `prEncode_iff` / `prEncode_codeSize_pos` / `prEncode_card_eq` / `petrankRoth_isInhabitedKarpReduction`. The grep confirming "research-scope only" remains valid. |
| **A2** | The rewritten `VERIFICATION_REPORT.md` is `markdown-lint`-clean (or at minimum, the existing markdown structure is preserved — no broken table cells, no orphan headers). |
| **A3** | The Lean module-header docstring's `/-! … -/` block remains well-formed; `lake build Orbcrypt` succeeds. |
| **A4** | The lakefile.lean `version` field is **unchanged** (still `0.2.0`). Only `CLAUDE.md` is modified. |

### 9.4 Workstream-B-specific safeguards

| Work unit | Safeguard |
|-----------|-----------|
| **B1** | Verify that no Lean module imports `Orbcrypt.Hardness.GrochowQiao._ApiSurvey` before deletion. Verify post-deletion that `lake build` succeeds and `find Orbcrypt -name '*.lean' | wc -l` returns 75. |
| **B2** | Verify that `.github/workflows/lean4-build.yml` does not reference any of the relocated script paths. Verify post-relocation that `scripts/audit_phase_16.lean` runs without error (its preamble references the relocated paths but the actual `lake env lean` invocation only loads `audit_phase_16.lean` itself). |
| **B3** | Verify the README.md table structure is preserved (no broken markdown table cells). |
| **B4** | Verify `lake build Orbcrypt.KEM.CompSecurity` succeeds; verify `#print axioms` output for declarations in the affected file is unchanged. |

### 9.5 Cross-workstream invariants

These invariants must hold at every commit on the
`claude/audit-findings-2026-04-29-*` branches:

* **Module count invariant:** `find Orbcrypt -name '*.lean' | wc -l`
  ∈ {75, 76}. Workstream **A** preserves 76; Workstream **B1**
  drops to 75; no other transitions are valid.
* **Audit script `#print axioms` invariant:** The set of
  declarations exercised by the audit script is **monotonically
  preserved or extended**. No declaration is removed from the
  audit script unless it is also removed from the source tree
  (which only happens in Workstream **B1**, and in that case the
  removed declarations are unexported and have no audit-script
  entries).
* **Standard-trio axiom invariant:** Every `#print axioms`
  output across all CI runs is a subset of `{propext,
  Classical.choice, Quot.sound}` ∪ "does not depend on any
  axioms".
* **Zero-sorry invariant:** comment-aware sorry scan returns 0
  matches.
* **Zero-custom-axiom invariant:** `^axiom\s+\w+` scan returns 0
  matches.

## 10. Release-readiness checklist

This is the v1.0 release-readiness checklist. Items in § 10.1 are
release-blocking; items in § 10.2 are recommended-for-v1.0; items in
§ 10.3 are explicitly deferred to v1.1+ / v2.0.

### 10.1 Required for v1.0 (release-blocking)

The following four items must land before tagging v1.0:

- [x] **A1 — Fix `PetrankRoth.lean` module docstring overclaim.**
  *Closed 2026-04-29 on branch `claude/audit-codebase-planning-CYmv2`.*
  Rewrite `Orbcrypt/Hardness/PetrankRoth.lean:9-19` and lines
  38-52 to honestly disclose Layer 5/6/7 status (research-scope,
  `R-15-residual-CE-reverse`, declarations not yet present).
  Match the disclosure style of `MarkerForcing.lean:17-26,
  73-95`. Acceptance: `grep -E
  "^(theorem|def|structure|class|instance|abbrev|lemma) +(prEncode_iff|prEncode_codeSize_pos|prEncode_card_eq|petrankRoth_isInhabitedKarpReduction)"
  Orbcrypt/Hardness/**/*.lean` returns zero matches; the new
  docstring uses per-layer status markers
  (`(LANDED)` / `(RESEARCH-SCOPE — <id>)`).

- [x] **A2 — Refresh `docs/VERIFICATION_REPORT.md` headline numbers.**
  *Closed 2026-04-29 on branch `claude/audit-codebase-planning-CYmv2`.*
  Update the snapshot date to `2026-04-29`; rewrite the headline-
  numbers table per Strategy a + b hybrid (cross-reference
  CLAUDE.md for ephemeral metrics; carry only invariants in this
  document); refresh **6 current-state references** (lines 78,
  455, 472, 494, 506, 595) **without disturbing the 13 historical-
  snapshot references** (lines 165, 1722, 1801, 1902, 1988, 2057,
  2154, 2156, 2218, 2302, 2390, 2481, 2489) inside per-Workstream
  / Document-history bullets; append Document-history entry.
  Acceptance: `grep -n "342\|36 modules\|38 modules\|347 public"
  docs/VERIFICATION_REPORT.md` returns matches **only** at the
  historical-snapshot lines listed above; header reads `Snapshot:
  2026-04-29`.

- [x] **A3 — Refresh `Orbcrypt.lean` Phase 16 snapshot section.**
  *Closed 2026-04-29 on branch `claude/audit-codebase-planning-CYmv2`.*
  Update lines 1279-1314 to current numbers verified at A3-
  implementation-time via the grep recipe in A3 Step 4 (76 or
  75-post-B1 modules, 928 audit-script entries, ≈ 800-900 public
  declarations [README's "358+" floor estimate is also acceptable
  for stability], ≈ 47 private helpers, 3,426 or 3,425-post-B1
  `lake build` jobs) and date `2026-04-29`. Add Workstream-A
  snapshot pointer at the end of the section. Acceptance: `sed
  -n '1279,1340p' Orbcrypt.lean` displays the refreshed snapshot.

- [x] **A4 — Reconcile `lakefile.lean` version with CLAUDE.md
  changelog.**
  *Closed 2026-04-29 on branch `claude/audit-codebase-planning-CYmv2`.*
  Add a new CLAUDE.md per-workstream changelog entry
  documenting the `0.1.29 → 0.1.30 → 0.2.0` chain. Lakefile
  version unchanged (preserves `0.2.0`). Acceptance: CLAUDE.md
  contains the dual-bump entry; `grep -n "0\.1\.30\|0\.2\.0"
  CLAUDE.md` returns at least 4 matches.

**Total estimated effort to clear release-blocking items: 3.25
hours serial; 1.5 hours with two implementers.**

### 10.2 Recommended for v1.0 (SHOULD land before tagging)

These items are not strictly release-blocking but affect audit
hygiene and code cleanliness:

- [x] **B1 — Delete transient `_ApiSurvey.lean`.** The file is
  not imported by any module and is documented as transient by
  its own header. Acceptance: file deleted; `find Orbcrypt -name
  '*.lean' | wc -l` returns 75; CLAUDE.md's R-TI Phase 1 / Layer
  T0 entry updated. Effort: 5 min.

- [x] **B2 — Relocate legacy audit scripts to `scripts/legacy/`.**
  Six scripts (`audit_a7_defeq.lean`, `audit_b_workstream.lean`,
  `audit_c_workstream.lean`, `audit_d_workstream.lean`,
  `audit_e_workstream.lean`, `audit_phase15.lean`,
  `audit_print_axioms.lean`) move to `scripts/legacy/`;
  `scripts/legacy/README.md` written. Acceptance: `ls
  scripts/audit_*.lean` returns only `audit_phase_16.lean`;
  `scripts/legacy/` contains README + 7 files. Effort: 25 min.

- [x] **B3 — Refresh `README.md` audit-script count.** Update
  line 53 from "382+" to "900+" (deliberately imprecise to
  resist per-PR staleness). Acceptance: `grep -n "382" README.md`
  returns no matches. Effort: 5 min.

- [x] **B4 — Compact post-Workstream-I deletion comment.** Reduce
  the 14-line `--`-comment block in
  `Orbcrypt/KEM/CompSecurity.lean:392-405` to ~6 lines while
  preserving all four reference points (pre-I name, audit-finding
  ID, post-I removal date, current witness). Acceptance: line
  count of affected file drops by ~8 lines; `lake build
  Orbcrypt.KEM.CompSecurity` succeeds. Effort: 10 min.

**Total estimated effort to clear "Recommended" items: ~50
minutes.**

### 10.3 v1.1+ enhancements (defer, not release-blocking)

These items are tracked for future audit cycles. **They are
explicitly excluded from v1.0 work.**

- [ ] **C1 — Make lakefile globs explicit (A-03).**
- [ ] **C2 — Defense-in-depth toolchain content check (A-04).**
- [ ] **C3 — Upgrade CI sorry-strip to handle nested block
  comments (A-05).**
- [ ] **C4 — Add CI lake-manifest drift check (A-08).**
- [ ] **C5 — Formal GAP/Lean canonical-image equivalence at
  arbitrary `n` (D-02a).**
- [ ] **C6 — INFO docstring observations (B-03a, B-03b, C-03a,
  C-13a, F-03a).** No action required; tracked for
  completeness only.

### 10.4 Research-scope items (long-term, not v1.0 work)

These were already tracked in the project's research catalogue;
the audit confirms they remain genuinely research-scope and are
honestly disclosed. **No v1.0 work.**

- **R-09** — Discharge of `h_step` in
  `indQCPA_from_perStepBound` from `ConcreteOIA scheme ε`
  alone.
- **R-12** — Tight `1/4` ε-bound on
  `ObliviousSamplingConcreteHiding`.
- **R-13** — `Bitstring n → ZMod p` orbit-preserving adapter
  making `carterWegmanMAC_int_ctxt` compose with HGOE.
- **R-15-residual-CE-reverse** — PetrankRoth Layers 4.1–7.
- **R-15-residual-TI-reverse** — Grochow–Qiao Layer T5
  rigidity argument.
- **R-15-residual-TI-forward-matrix** — Grochow–Qiao Layer
  T3.6 matrix-action upgrade.

### 10.5 Final v1.0 release verdict

**Conditional on remediating the 4 release-blocking items in §
10.1**, the Orbcrypt formalization is **READY FOR v1.0
RELEASE**.

The Lean code itself is in excellent shape — clean, well-
documented at the per-module level, with substantive proofs
throughout, honest research-scope disclosure, and exemplary
release-messaging discipline at the per-theorem level (CLAUDE.md
row #19 "Standalone post-Workstream-B", row #20 "Conditional",
row #24/25 "Conditional", etc.).

The remediation work is **all in documentation surfaces** (prose
changes, no Lean code changes); the cumulative estimated effort
to clear all release-blocking items is **3.25 hours serial; 1.5
hours with two implementers**. After this remediation, no
further audit cycle is required for v1.0.

## 11. Implementation branches

Each work unit lands on its own implementation branch. The branch
naming convention follows the project's existing pattern
(`claude/<task-description>-<random-suffix>`).

| Work unit | Branch | PR target |
|-----------|--------|-----------|
| **A1** (PetrankRoth docstring fix) | `claude/audit-2026-04-29-A1-petrankroth-docstring` | `main` |
| **A2** (VERIFICATION_REPORT.md refresh) | `claude/audit-2026-04-29-A2-verification-report` | `main` |
| **A3** (Orbcrypt.lean snapshot refresh) | `claude/audit-2026-04-29-A3-orbcrypt-snapshot` | `main` |
| **A4** (Lakefile / CLAUDE.md reconciliation) | `claude/audit-2026-04-29-A4-version-reconciliation` | `main` |
| **B1** (Delete `_ApiSurvey.lean`) | `claude/audit-2026-04-29-B1-delete-apisurvey` | `main` |
| **B2** (Relocate legacy audit scripts) | `claude/audit-2026-04-29-B2-legacy-script-relocation` | `main` |
| **B3** (README audit-script count) | `claude/audit-2026-04-29-B3-readme-count` | `main` |
| **B4** (Compact KEM/CompSecurity comment) | `claude/audit-2026-04-29-B4-compact-comment` | `main` |

Alternative: Workstream **A** can land as a single PR on
`claude/audit-findings-2026-04-29-A` (umbrella branch); Workstream
**B** as a single PR on `claude/audit-findings-2026-04-29-B`.

The current development branch
(`claude/audit-workstream-planning-HsW8k` per the session brief) is
the home of **this planning document only**. The implementation
branches above are forked from `main` (or from this branch, if the
planning document needs to be on the merged branch first).

**PR review checklist (per work unit).** Each PR description
should include:

1. The work-unit ID (`A1`, `A2`, ..., `B4`).
2. The audit-finding ID being closed (`G-02`, `L-04`, etc.).
3. The before/after evidence (e.g., `grep` output before and
   after; `find` count before and after).
4. The CI status (build green, audit script clean, axiom output
   unchanged).
5. The CLAUDE.md changelog update (every PR adds the relevant
   sentence to the Workstream-A or -B snapshot subsection).

## 12. Signoff

This planning document was authored on 2026-04-29 by Claude
(Opus 4.7) following the methodology established by the prior
audit plans (AUDIT_2026-04-18, AUDIT_2026-04-21, AUDIT_2026-04-23,
AUDIT_2026-04-25, AUDIT_2026-04-28). The document:

* **Validates** every audit finding via direct codebase spot-
  check (§ 1.3 Validation log; zero findings erroneous).
* **Decomposes** the 16 findings into four letter-coded
  workstreams (**A** release-blocking; **B** recommended polish;
  **C** v1.1+ deferred; **D** research catalogue).
* **Specifies** concrete acceptance criteria, regression
  safeguards, and rollback plans for every work unit in
  Workstreams **A** and **B**.
* **Estimates** ≈ 3.25 hours serial / 1.5 hours parallel for
  Workstream **A**; ≈ 50 minutes for Workstream **B**.
* **Defers** Workstreams **C** and **D** to v1.1+ / v2.0 with
  explicit skeletons but no v1.0 commitments.
* **Preserves** the project's existing release-messaging policy
  (CLAUDE.md "Release messaging policy (ABSOLUTE)") and naming
  discipline ("Names describe content, never provenance") at
  every workstream boundary.

**Plan integrity check.** This document does not introduce any
prose claim that exceeds what the audit findings document
(§ 1.3 verifies every claim against the source audit). It does
not introduce any new release-messaging gap (every recommendation
is for restoring parity, not creating it). It does not introduce
any Lean source change in Workstream **A** or **B** that would
affect the `lake build` graph or the audit script's output.

**Authority.** This plan supersedes no prior plan. It complements
the existing 2026-04-18 / 2026-04-21 / 2026-04-23 / 2026-04-25 /
2026-04-28 plans by addressing the 2026-04-29 audit's findings.
Each prior plan remains the authority for its own findings.

**Implementation start.** Workstream **A1** can begin
immediately. The other work units may proceed in parallel per
§ 4. The first PR (recommended: A1, the simplest at 30 min) is
the smoke test — it confirms the planning document's mechanics
(branch naming, PR template, CLAUDE.md changelog update format)
work correctly before larger work units (A2 at 1.5 h) land.

**End of plan body.** The four appendices below provide
finding-ID cross-reference (Appendix A), workstream status tracker
(Appendix B), concrete documentation update templates (Appendix C),
and the validation methodology (Appendix D).

## Appendix A — Finding-ID → workstream-and-work-unit cross-reference

This appendix maps every audit finding ID to its workstream
assignment and work-unit number. Findings reported in two audit
sections (e.g., A-07 reported in both § A and § J as J-02) are
listed once with a slash-separated ID.

### A.1 Pre-release slate (Workstream A)

| Audit finding ID | Severity | Source audit § | Workstream-WU |
|------------------|----------|----------------|---------------|
| **G-02** | HIGH | § G (PetrankRoth) | **A1** |
| **L-04** | HIGH | § L (Documentation) | **A2** |
| **A-07 / J-02** | HIGH | § A (Build), § J (Root file) | **A3** |
| **A-02 / L-03a** | MEDIUM | § A (Build), § L (Documentation) | **A4** |

### A.2 Recommended-pre-release slate (Workstream B)

| Audit finding ID | Severity | Source audit § | Workstream-WU |
|------------------|----------|----------------|---------------|
| **A-01 / H-03a** | LOW | § A (Build), § H (GrochowQiao) | **B1** |
| **A-06** | LOW | § A (Build) | **B2** |
| **L-01** | LOW | § L (Documentation) | **B3** |
| **C-13b** | LOW | § C (KEM) | **B4** |

### A.3 Deferred slate (Workstream C)

| Audit finding ID | Severity | Source audit § | Workstream-WU |
|------------------|----------|----------------|---------------|
| **A-03** | INFO | § A | **C1** |
| **A-04** | INFO | § A | **C2** |
| **A-05** | INFO | § A | **C3** |
| **A-08** | INFO | § A | **C4** |
| **D-02a** | INFO | § D | **C5** |
| **B-03a** | INFO | § B | **C6** (no action) |
| **B-03b** | INFO | § B | **C6** (no action) |
| **C-03a** | INFO | § C | **C6** (no action) |
| **C-13a** | INFO | § C | **C6** (no action) |
| **F-03a** | INFO | § F | **C6** (no action) |

### A.4 Research catalogue (Workstream D)

| Research item | Source | Status |
|---------------|--------|--------|
| **R-09** | CLAUDE.md, Workstream C of audit 2026-04-23 | tracking (multi-month) |
| **R-12** | CLAUDE.md, Workstream I of audit 2026-04-23 | tracking (multi-month) |
| **R-13** | CLAUDE.md, Workstream A finding V1-7 of audit 2026-04-23 | tracking (multi-month) |
| **R-15-residual-CE-reverse** | `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` | tracking (multi-month) |
| **R-15-residual-TI-reverse** | `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` | tracking (multi-month) |
| **R-15-residual-TI-forward-matrix** | `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` | tracking (multi-month) |

### A.5 Cross-reference summary

* **Total findings cited in the source audit:** 16
* **Distinct findings (deduplicating slash-IDs):** 16
* **Findings assigned to Workstream A:** 4
* **Findings assigned to Workstream B:** 4
* **Findings assigned to Workstream C:** 10
* **Research items tracked in Workstream D:** 6 (carried over
  from prior plans)
* **Erroneous findings:** 0 (every finding spot-checked per
  § 1.3)

## Appendix B — Workstream status tracker

The tracker below is populated as workstreams close (via PR
merge). At plan-issuance time, all workstreams are pending.

| Workstream | Status | Branch | Closed date |
|------------|--------|--------|-------------|
| **A1** (PetrankRoth docstring fix) | closed | `claude/audit-codebase-planning-CYmv2` | 2026-04-29 |
| **A2** (VERIFICATION_REPORT.md refresh) | closed | `claude/audit-codebase-planning-CYmv2` | 2026-04-29 |
| **A3** (Orbcrypt.lean snapshot refresh) | closed | `claude/audit-codebase-planning-CYmv2` | 2026-04-29 |
| **A4** (Lakefile / CLAUDE.md reconciliation) | closed | `claude/audit-codebase-planning-CYmv2` | 2026-04-29 |
| **B1** (Delete `_ApiSurvey.lean`) | closed | `claude/audit-workstream-planning-nOC9R` | 2026-04-29 |
| **B2** (Relocate legacy audit scripts) | closed | `claude/audit-workstream-planning-nOC9R` | 2026-04-29 |
| **B3** (README audit-script count refresh) | closed | `claude/audit-workstream-planning-nOC9R` | 2026-04-29 |
| **B4** (Compact KEM/CompSecurity comment) | closed | `claude/audit-workstream-planning-nOC9R` | 2026-04-29 |
| **C1** (lakefile globs) | deferred | — | v1.1+ |
| **C2** (toolchain checksum) | deferred | — | v1.1+ |
| **C3** (CI nested-comment regex) | deferred | — | v1.1+ |
| **C4** (lake-manifest drift check) | deferred | — | v1.1+ |
| **C5** (GAP/Lean equivalence theorem) | deferred | — | v1.1+ research-scope |
| **C6** (INFO docstrings) | no-action | — | n/a |
| **D** (research catalogue) | tracking (never closes) | — | — |

**Update protocol.** When a Workstream-A or Workstream-B work
unit's PR merges, the implementer:

1. Updates the corresponding row in this table to `closed`.
2. Adds the PR's branch name in the Branch column.
3. Records the merge date in the Closed date column.
4. Adds a Workstream-A or Workstream-B snapshot entry to
   CLAUDE.md.

## Appendix C — Documentation update templates

This appendix provides concrete prose snippets that implementers
can drop into the relevant files during work-unit execution.
Each snippet is a self-contained block; placeholder values are
clearly marked with `<<<` `>>>` brackets.

### C.1 CLAUDE.md Workstream-A snapshot template

When all four Workstream-A work units have merged, append this
block to CLAUDE.md immediately after the most recent existing
workstream snapshot (which at plan-issuance time is the
"R-TI Phase 3 — Path B Sub-task A.6.4" entry):

```markdown
Audit 2026-04-29 — Workstream A (release-blocking documentation
parity) has been completed (<<< merge-date >>>):

- **A1 — PetrankRoth.lean module docstring overclaim fix.** The
  module-header `/- ... -/` and `/-! ## Layer organisation -/`
  blocks at lines 9-19 and 38-52 of
  `Orbcrypt/Hardness/PetrankRoth.lean` previously declared
  Layers 5/6/7 as present in this file, naming `prEncode_iff`,
  `prEncode_codeSize_pos`, `prEncode_card_eq`, and
  `petrankRoth_isInhabitedKarpReduction` as available
  declarations. Verification confirmed those identifiers exist
  ONLY as docstring/comment text, never as Lean declarations.
  The docstrings are rewritten with per-layer status markers
  (`(LANDED)` for Layers 1, 2, 3; `(RESEARCH-SCOPE — R-15-residual-CE-reverse)`
  for Layers 4, 5, 6, 7) matching the disclosure style already
  used in `MarkerForcing.lean:17-26, 73-95`. Closes audit
  finding G-02 (HIGH, source audit
  `docs/audits/LEAN_MODULE_AUDIT_2026-04-29_COMPREHENSIVE.md`
  § G).

- **A2 — `docs/VERIFICATION_REPORT.md` refresh.** The auditor-
  facing document carried headline numbers 2-9× stale (38 →
  76 modules, 342 → 928 audit-script entries, 5 → 47 private
  declarations, snapshot date 2026-04-21 → 2026-04-29). The
  header table is restructured per the Strategy a + b hybrid:
  ephemeral metrics now cross-reference CLAUDE.md as the
  canonical running-state source, and only invariants (zero-
  sorry / zero-custom-axiom posture; standard-trio-only axioms;
  per-public-declaration docstrings; build-success status) are
  listed in the report. The body sweep refreshes the **6
  current-state references** (lines 78, 455, 472, 494, 506,
  595) without disturbing the **13 historical-snapshot
  references** inside per-Workstream / Document-history
  bullets (lines 165, 1722, 1801, 1902, 1988, 2057, 2154,
  2156, 2218, 2302, 2390, 2481, 2489). The Document history
  section gains a `<<< merge-date >>>` entry. Closes audit
  finding L-04 (HIGH).

- **A3 — `Orbcrypt.lean` Phase 16 snapshot section refresh.**
  The "Phase 16 Verification Audit Snapshot (2026-04-21)"
  section at lines 1279-1314 of the root file is refreshed to
  the 2026-04-29 reality: 76 modules (down to 75 if Workstream
  B1 has also merged), 928 audit-script entries, the verified
  public-declaration count from the grep recipe in A3 Step 4
  (≈ 800-900 expected; the README's "358+" floor estimate is
  retained for stability), 47 private helpers, 3,426 `lake
  build` jobs.
  A new closing line directs future maintainers to CLAUDE.md
  for the running snapshot. Closes audit finding A-07 / J-02
  (HIGH).

- **A4 — `lakefile.lean` version reconciliation.** The
  on-disk `version := v!"0.2.0"` was unrecorded in CLAUDE.md's
  per-workstream changelog (the most recent prior entry was
  `0.1.28 → 0.1.29` from R-TI Phase 3 — Path B Sub-task A.6.4).
  CLAUDE.md gains a new dual-bump changelog entry documenting
  the `0.1.29 → 0.1.30 → 0.2.0` chain with rationale (the
  `0.2.0` minor bump signals the post-R-TI-Phase-3 partial-
  discharge feature-complete cluster per semver). Lakefile
  unchanged. Closes audit finding A-02 / L-03a (MEDIUM).

**Verification.** Workstream A is documentation-only; no Lean
source semantics changed. `lake build` succeeds with 3,426 jobs
(or 3,425 if Workstream B1 has also merged), zero warnings,
zero errors. `scripts/audit_phase_16.lean` runs cleanly (exit
code 0); standard-trio axioms across all 928 `#print axioms`
checks; zero `sorryAx`; zero non-standard axioms.

Patch version: `lakefile.lean` retains `0.2.0`; Workstream A is
documentation-only and adds no new Lean declarations.
```

### C.2 CLAUDE.md Workstream-B snapshot template

When all four Workstream-B work units have merged, append this
block to CLAUDE.md immediately after the Workstream-A entry:

```markdown
Audit 2026-04-29 — Workstream B (recommended pre-release polish)
has been completed (<<< merge-date >>>):

- **B1 — Transient `_ApiSurvey.lean` deletion.**
  `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean` (110 LOC) was
  documented as transient by its own header docstring ("This
  file is **transient**: per Decision GQ-D, it should be
  deleted at the end of Layer T1") and by CLAUDE.md, but
  remained in the source tree post-Layer-T1. The file was
  not imported by any module and was picked up by `lake build`
  only via the `srcDir := "."` glob. Deleted per CLAUDE.md's
  "If you are certain that something is unused, you can delete
  it completely" rule. Module count drops from 76 to 75. Closes
  audit finding A-01 / H-03a (LOW).

- **B2 — Legacy per-workstream audit script relocation.** Six
  superseded scripts moved from `scripts/` to `scripts/legacy/`:
  `audit_a7_defeq.lean`, `audit_b_workstream.lean`,
  `audit_c_workstream.lean`, `audit_d_workstream.lean`,
  `audit_e_workstream.lean`, `audit_phase15.lean`,
  `audit_print_axioms.lean`. CI was already running only
  `scripts/audit_phase_16.lean` (the current sentinel), so no
  workflow edit is required. A new
  `scripts/legacy/README.md` documents the archive status.
  Closes audit finding A-06 (LOW).

- **B3 — `README.md` audit-script count refresh.** Line 53's
  "Phase-16 audit script | 382+ #print axioms checks" updated
  to "900+" (deliberately imprecise to resist per-PR
  staleness; the precise count is tracked by CLAUDE.md).
  Closes audit finding L-01 (LOW).

- **B4 — Compact post-Workstream-I deletion comment.**
  `Orbcrypt/KEM/CompSecurity.lean:392-405` 14-line `--`-
  comment block compacted to 6 lines while preserving all
  four reference points (pre-I name, audit-finding ID,
  post-I removal date, current witness). Closes audit
  finding C-13b (LOW).

**Verification.** Workstream B is file-relocation and prose-
edit only; no Lean source semantics changed. `lake build`
succeeds (3,425 jobs post-B1, down by 1 from the post-A
3,426). `scripts/audit_phase_16.lean` runs cleanly with the
same posture (zero `sorry`, zero custom axioms, standard-trio-
only).

Patch version: `lakefile.lean` retains `0.2.0`.
```

### C.3 PetrankRoth.lean docstring replacement (A1 template)

The full replacement text for A1 is given inline in § 5.3 (work
unit A1) of this plan. The implementer copies the replacement
directly from § 5.3, preserving exact whitespace and markdown
structure.

### C.4 VERIFICATION_REPORT.md header replacement (A2 template)

The header table replacement for A2 is given inline in § 5.3
(work unit A2). For the body sweep, the implementer uses
`Edit`-tool exact-match replacements at each of the ~17 stale-
reference locations. Each replacement preserves surrounding
prose intact and only updates the count cell or numerical
claim.

### C.5 Orbcrypt.lean snapshot replacement (A3 template)

The full replacement text for A3 is given inline in § 5.3 (work
unit A3) as Steps 1-6. The implementer applies each step in
sequence; intermediate `lake build` invocations confirm the
docstring remains well-formed at every step.

### C.6 CLAUDE.md version-reconciliation entry (A4 template)

The full replacement text for A4 is given inline in § 5.3
(work unit A4) as Step 2. The implementer drops the
markdown block into CLAUDE.md immediately after the existing
"R-TI Phase 3 — Path B Sub-task A.6.4" version-bump entry.

### C.7 scripts/legacy/README.md template (B2)

The full replacement text for the `scripts/legacy/README.md`
file is given inline in § 6.3 (work unit B2) as Step 3.

## Appendix D — Validation methodology

This appendix documents the methodology used to verify each
audit finding before workstream assignment. The methodology is
the same one used by the prior 2026-04-23 plan's § 21 validation
log.

### D.1 Spot-check protocol

For each of the 16 audit findings, the validation procedure is:

1. **Open the cited source / prose surface.** Use the audit's
   `file:line` citation. If the citation is a line range
   (e.g., `lines 9-19`), use `sed -n` or `Read` with the
   appropriate `offset`/`limit` to inspect the exact region.

2. **Verify the claimed defect.** For each finding type:
   - **Docstring overclaim:** confirm the docstring states X,
     and confirm X is not delivered by any actual Lean
     declaration (`grep -E "^(theorem|def|...)" ...`).
   - **Stale numerical claim:** confirm the document states
     value V_old, and confirm reality is V_new (`find` /
     `grep -c` / `wc -l` as appropriate).
   - **Missing audit feature:** confirm the audit step is
     not present in the workflow (`grep -n` for the expected
     pattern in the workflow YAML).
   - **Transient stub:** confirm the file's own docstring
     declares it transient, and confirm no live consumer
     (`grep -rn` for the file's module name across the source
     tree).

3. **Confirm the recommendation is implementable.** Each
   finding's recommendation must be specific enough to act on.
   If a recommendation reads "consider X", the validation step
   asks: is there a concrete, well-defined X? If yes, the
   recommendation is implementable. If no, the recommendation
   is downgraded to INFO and tracked under Workstream **C**.

4. **Record the verification in § 1.3 of this plan.** Each
   finding gets a row in the validation log table; the
   "Verified?" column is checked only after all three steps
   above are completed.

### D.2 Methodology limitations

This validation methodology has the same limitations as the
prior plans' validation methodology:

* **Spot-checks, not exhaustive verification.** Every finding
  is spot-checked at its cited location; the spot-check confirms
  the defect exists where claimed. The methodology does NOT
  exhaustively re-audit the entire codebase to find new
  findings the source audit may have missed. The source audit
  itself is the primary source of findings; this plan only
  organizes and verifies them.

* **Build verification deferred to CI.** The plan's validation
  log records spot-check results but does not re-run a full
  `lake build` for every finding. The audit's § N-05
  documents that `lake build` succeeds with 3,426 jobs and
  zero errors at audit time; this plan trusts that result.
  Each Workstream-A and Workstream-B PR re-runs `lake build`
  via CI, providing the per-PR build confidence.

* **Documentation-vs-code parity is checked at spot-check
  level only.** A 100% systematic CLAUDE.md / VERIFICATION_REPORT.md
  / README.md vs. code comparison would require a tooling
  investment beyond this plan's scope. The plan addresses the
  specific parity gaps surfaced by the audit; future audits
  may find additional gaps not in scope here.

### D.3 Comparison with prior validation logs

This plan's validation log methodology matches the
2026-04-23 plan's § 21 ("Validation log") with one notable
extension: the table format (§ 1.3) explicitly records the
spot-check command used, not just the pass/fail verdict. This
allows future readers to re-run the same verification steps if
they doubt the validation.

### D.4 Auditor independence and self-audit

The 2026-04-29 source audit was conducted by Claude (Anthropic,
Sonnet/Opus 4.7) per its header. This plan was authored by the
same model. To mitigate the auditor-equals-planner
self-confirmation risk:

* Every finding's spot-check is recorded with the **command**
  used (not the conclusion). A future auditor can re-run
  every command and verify independently.
* The plan does not introduce any new finding beyond what the
  source audit catalogued.
* The plan does not silently dismiss any source-audit finding;
  every finding is either assigned to a workstream or
  explicitly classified as "no action needed" with cross-
  reference to the source audit's own justification.

### D.5 Validation outcome summary

* **Findings examined:** 16 (every finding cited in the source
  audit's § M-01 findings table).
* **Findings verified as defects:** 16 (every finding cited
  reflects a real defect at the cited location).
* **Findings reclassified:** 0 (no severity changes from the
  source audit's classification).
* **Findings dismissed as erroneous:** 0.
* **Findings split into multiple work units:** 0 (every
  finding maps to exactly one work unit; cross-cutting
  findings like A-01/H-03a appear in two audit sections but
  represent a single defect addressed by a single work unit).

This is the strictest validation outcome possible: every audit
finding is verified, none are erroneous, and the plan's work-
unit decomposition mirrors the source audit's findings register
1:1.

---

*End of plan.*

