<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# 2026-05-06 — Structural Review Resolution Plan

**Source review:** Deep codebase review surfaced seven structural concerns at the
documentation/scaffolding boundary, distinct from the per-module Lean
correctness focus of the prior audit cycles (`docs/audits/LEAN_MODULE_AUDIT_*`).
**Branch:** `claude/project-review-feedback-s6PLN`
**Baseline HEAD SHA:** `36ef20a0104998aa73c1804ba7406ad4f888a83b`
**Created:** 2026-05-06
**Author:** Claude (planning + implementation agent)

## 0. How to read this document

- The seven structural concerns are organised into **nine workstreams** (W0
  pre-flight + W1–W7 + W8 post-flight). Each workstream maps cleanly to one of
  the concerns or to wrapper hygiene.
- Workstreams W1–W4 are independent and can be implemented in any order
  (possibly in parallel by different contributors). W5 must precede W6
  (post-split documentation is W6's edit target). W6 must precede W7 (W7
  refreshes post-deletion metric anchors).
- The full plan lives at `/root/.claude/plans/thanks-can-you-create-merry-rabin.md`
  in the implementing agent's worktree; this document is the in-tree summary.
- Every workstream carries a `lake build` verification command and an explicit
  rollback strategy. The leaf-first sequence inside W6 (deterministic-OIA
  deletion) ensures every per-commit intermediate state lake-builds cleanly.

## 1. The seven structural concerns

| # | Concern | Resolution workstream |
|---|---------|----------------------|
| 1 | Two-Phase headline names overstate their conditional content | W1 (rename) |
| 2 | "Theatrical theorem" pattern (hypothesis ignored, vacuous conclusion) recurring across audit passes | W2 (CI gate) |
| 3 | GAP–Lean correspondence asserted only in prose; no machine-checked correspondence at runtime | W3 (test vectors) |
| 4 | Conditional-Prop scaffolding (e.g., `tight_one_exists` at PUnit) reads as vacuous | W4 (S_2-shaped surrogate; tight R-07 advantage) |
| 5 | CLAUDE.md size (9,061 lines) — onboarding-prohibitive, mixes stable conventions with historical changelog | W5 (three-way split) |
| 6 | Public-key extension lacks honest demarcation as research scaffolding in headline tables | W5 (clustered sections in API_SURFACE.md) |
| 7 | Deterministic-OIA chain (`OIA`, `KEMOIA`, `HardnessChain`, etc.) is `False` on every non-trivial scheme; ~17 vacuous declarations | W6 (delete entirely) |

User decisions confirmed pre-implementation:
- **Concern #7:** delete entirely (eliminates ~17 declarations across 6 modules; 779 references cleaned).
- **Concern #4:** tractable structural wins only (no multi-week research discharges; ε < 1 *cryptographic* discharges remain research-scope).

## 2. Baseline metrics (pre-W0)

Captured at HEAD `36ef20a0104998aa73c1804ba7406ad4f888a83b` on 2026-05-06,
immediately before the workstream sequence began.

| Metric | Value |
|--------|-------|
| Lean modules under `Orbcrypt/` | 81 |
| Audit-script `#print axioms` entries (`scripts/audit_phase_16.lean`) | 1,154 |
| Public-declaration prefix-line count (theorem/def/structure/class/instance/abbrev/lemma) | 1,083 |
| `wc -l CLAUDE.md` | 9,061 |
| `lakefile.lean` version | 0.3.2 |
| `lake build` job count (last verified pre-W0) | 3,424 |
| Sorry count | 0 |
| Custom-axiom count | 0 |
| `#print axioms` outputs not on the standard Lean trio | 0 |

## 3. Expected post-implementation metrics (post-W7)

| Metric | Expected value | Source |
|--------|----------------|--------|
| Lean modules | 79 | W6 deletes `Orbcrypt/Crypto/OIA.lean` and `Orbcrypt/Theorems/OIAImpliesCPA.lean` |
| Audit-script `#print axioms` entries | ~1,140 | W6 removes ~17 entries; W3, W4 add a small handful |
| Public-declaration prefix-line count | ~1,070 | W6 removes ~17 declarations; W4 adds 3; W3 may add a few |
| `wc -l CLAUDE.md` | ~1,200 | W5 relocates ~7,800 lines |
| `wc -l docs/API_SURFACE.md` | ~900 | W5 creates new |
| `wc -l docs/dev_history/WORKSTREAM_CHANGELOG.md` | ~7,050 | W5 relocates from CLAUDE.md |
| `lakefile.lean` version | 0.4.0 | minor bump for major API removal (W6) |
| Sorry count | 0 | preserved |
| Custom-axiom count | 0 | preserved |

## 4. Workstream sequence

Per `/root/.claude/plans/thanks-can-you-create-merry-rabin.md` § "Sequencing
Strategy". Dependencies:

- W0 → all others (baseline + branch readiness).
- W1, W2, W3, W4 are independent of each other.
- W5 must precede W6.
- W6 must precede W7.
- W8 is final.

## 5. Risk and rollback

Each workstream carries an explicit risk + rollback section in the master plan.
The highest-risk workstream is W6 (deterministic-OIA deletion); it is decomposed
into 11 leaf-first commits, each independently revertible. The leaf-first
sequence guarantees every intermediate commit lake-builds cleanly: W6 never
leaves the tree in a state where a downstream-import-ed declaration depends on
a not-yet-removed deleted declaration.

## 6. Verification posture

The implementation must preserve, at every commit:
- `lake build` succeeds with zero warnings, zero errors.
- `scripts/audit_phase_16.lean` exit-0 with every `#print axioms` line on the
  standard Lean trio (`[propext, Classical.choice, Quot.sound]`) or "does not
  depend on any axioms".
- `grep -rn '\bsorry\b' Orbcrypt/` (comment-aware) returns empty.
- `grep -rEn '^axiom\s+\w+\s*[\[({:]' Orbcrypt/` returns empty.
- `lake-manifest.json` drift check passes.
- (Post-W2) The Python hypothesis-consumption gate
  (`scripts/audit_hypothesis_consumption.py`) reports zero violations.

## 7. Out of scope

The structural review explicitly excludes the multi-month research-scope
items tracked separately:
- **R-15-residual-CE-reverse** (Petrank–Roth Layers 4–7).
- **R-15-residual-TI-reverse** (full discharge of `GrochowQiaoRigidity` and
  the four GL³-rigidity Props).
- **R-05⁺** (full Wegman–Carter §3 nonced-MAC reduction).
- **Lean → C/OCaml extraction** (alternative to W3's test-vector approach).
- **Adaptive-query / IND-CCA security**.

These remain in their existing planning documents
(`docs/planning/PLAN_R_05_11_15.md`, etc.) and audit cycles.
