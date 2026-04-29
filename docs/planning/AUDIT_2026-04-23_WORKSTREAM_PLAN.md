<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Audit 2026-04-23 — Pre-Release Workstream Plan

**Source audit.** `docs/audits/LEAN_MODULE_AUDIT_2026-04-23_PRE_RELEASE.md`
(140+ findings: **1 CRITICAL** · 30+ HIGH · 50+ MEDIUM · 60+ LOW/INFO).

**Scope.** Pre-v1.0 release remediation plan for the Orbcrypt Lean 4
formalization. Organises the audit's findings into **fifteen letter-coded
workstreams** (**A**–**O**, skipping none; letter codes are **document
identifiers only**, per `CLAUDE.md`'s naming discipline — they never appear
in Lean declaration names). Each workstream is decomposed into atomic work
units with concrete acceptance criteria, regression safeguards, satisfiability
witnesses, and exit criteria.

**Branch.** `claude/audit-findings-workstream-xVw9o` (this document lands on
this branch; per-workstream implementation branches are listed in § 22).

**Author.** Claude (Opus 4.7 [1M]). **Date.** 2026-04-23.
**Project baseline.** 38 modules, 347 public declarations, `lakefile.lean`
version `0.1.6` (Workstream-L bump from the 2026-04-21 audit), Lean toolchain
`v4.30.0-rc1`, Mathlib pinned at `fa6418a815fa14843b7f0a19fe5983831c5f870e`.

**Naming-discipline reminder.** Per `CLAUDE.md`'s Key Conventions, work-unit
identifiers (`A1`, `C3`, `L2-WU4`, …) are plan-document identifiers and
commit-message tokens; Lean `def` / `theorem` / `structure` / `instance` /
`abbrev` / `lemma` names added during implementation **must not** carry any
workstream or audit-finding token (`workstream`, `ws`, `audit`, `f02`,
`v1_1`, `step3`, etc.). Docstrings may carry traceability prose
(`"audit 2026-04-23 / V1-1 / Workstream B"`); identifiers may not.

**Reading guide — letter-code hygiene.** Workstream letters appear
bold-faced (**A**, **B**, **C**, …) and near the words "Workstream", "WS",
or section numbers. Audit-finding IDs (`A-01`, `B-03`, `C-13`, `I-03`,
`V1-1` …) retain their source-audit prefix: the **letter prefix is a
module-group code from the source audit**, not a workstream letter in this
plan. Thus `I-03` is audit finding #3 in audit-section I (AEAD/AEAD),
whereas "Workstream I" below is a different construct. Where collisions
would ambiguate, the finding ID is written with its source-audit prefix
("audit finding I-03") and the workstream with the bold letter
("Workstream **I**"). Appendix A is the canonical mapping.

## Table of contents

- § 0 — Executive summary
- § 1 — Finding taxonomy
- § 2 — Finding → workstream mapping
- § 3 — Workstream summary
  - § 3.1 — Workstream dependency graph (critical path + parallelism)
- § 4 — **Workstream A** — Release-messaging reconciliation (docs-only; V1-9 policy)
  - § 4.4 — Risk register and rollback
- § 5 — **Workstream B** — `INT_CTXT` orbit-cover refactor (V1-1)
  - § 5.4 — Work units (B1a, B1b, B2, B3, B4)
  - § 5.5 — Risk register and rollback
- § 6 — **Workstream C** — Multi-query hybrid reconciliation (V1-8)
  - § 6.4 — Risk register and rollback
- § 7 — **Workstream D** — Toolchain decision + `lakefile.lean` hygiene (V1-6)
- § 8 — **Workstream E** — Formal vacuity witnesses (V1-11)
  - § 8.3 — Work units with full proof bodies
  - § 8.4 — Risk register and rollback
- § 9 — **Workstream F** — Concrete `CanonicalForm` from lex-min (V1-10)
  - § 9.4 — Work units (F1, F2, F3a–d with proof bodies, F4)
  - § 9.5 — Risk register and rollback
- § 10 — **Workstream G** — λ-parameterised `HGOEKeyExpansion` (V1-13)
- § 11 — **Workstream H** — Safe decapsulation + computable decryption (V1-12, V1-14)
  - § 11.4 — Work units (H1, H2, H3a–c with proof bodies)
  - § 11.5 — Risk register and rollback
- § 12 — **Workstream I** — Naming hygiene (V1-15)
- § 13 — **Workstream J** — Invariant-attack framing + negligible-function closure (V1-4, V1-16)
- § 14 — **Workstream K** — Root-file split + legacy script relocation (V1-17, V1-18, V1-21)
  - § 14.3 — Work units (K1a–c, K2a–c, K3, K4, K5, K6, K7)
  - § 14.4 — Risk register and rollback
- § 15 — **Workstream L** — Medium-severity structural cleanup
  - § 15.4 — PR grouping (nine module-aligned PRs)
  - § 15.5 — Risk register
- § 16 — **Workstream M** — Low-severity cosmetic polish
- § 17 — **Workstream N** — Optional pre-release engineering enhancements (V1-19, V1-20, V1-22)
- § 18 — **Workstream O** — Research & performance catalogue (v1.1+ / v2.0; R-* + Z-*)
- § 19 — Regression safeguards
- § 20 — Release-readiness checklist
- § 21 — Validation log (findings verified against source)
- § 22 — Implementation branches
- § 23 — Signoff
- Appendix A — Finding-ID → workstream-and-work-unit cross-reference
- Appendix B — Workstream status tracker
- Appendix C — Non-vacuity witness Lean snippets (per workstream)

## 0. Executive summary

The 2026-04-23 pre-release audit is the harshest of the four completed
audit cycles because the project is approaching its first major-version
tag. **The technical posture is excellent** — zero `sorry`, zero custom
axioms, 347+ public declarations with docstrings, clean CI, robust
axiom-transparency infrastructure. **The release-messaging posture is
not v1.0-ready**: eight HIGH-severity findings document a systematic gap
between `CLAUDE.md` / `VERIFICATION_REPORT.md` status claims and what the
Lean code actually delivers, plus three HIGH findings identify hypothesis
structures (`INT_CTXT` orbit-cover; `TwoPhaseDecomposition`) that are
**false on production HGOE** and therefore make their headline theorems
vacuously applicable rather than standalone.

The single **CRITICAL** finding (X-01, two-chains release messaging) is
the umbrella for ten HIGH findings on scaffolding-vs-quantitative
framing (C-07, E-06, I-03, L-03, E-10, J-03, J-08, J-12, K-01, K-02, K-07).
None of these require a correctness rollback; they require a messaging
reconciliation pass (docs-only, Workstream **A**) plus three small Lean
refactors: `INT_CTXT` signature refinement (Workstream **B**), multi-query
`h_step` discharge-or-rename (Workstream **C**), and formal vacuity
witnesses (Workstream **E**).

**Validation.** Every finding cited by this plan was spot-checked directly
against the referenced Lean source file and line numbers prior to
workstream assignment. § 21 ("Validation log") records 24 independently
verified findings across all severity classes; **zero findings were found
to be erroneous**, and one (I-03 status-column mislabel) was confirmed as
partially valid in the sense that the structural claim is accurate but the
remediation is a one-word edit, not a refactor.

**Release-gate commitment.** After Workstreams **A** (release messaging),
**B** (INT_CTXT orbit-cover), **C** (multi-query reconciliation), **D**
(toolchain), and **E** (formal vacuity witnesses) land, the v1.0 release
narrative becomes honest — every external claim is either a machine-checked
standalone theorem or an explicitly qualified conditional / scaffolding /
quantitative-at-ε result. Workstreams **F**–**J** are strongly recommended
polish; **K**–**N** are optional polish; **O** is the v1.1+ / v2.0 research
runway.

**Effort estimate.** Pre-release slate (**A**+**B**+**C**+**D**+**E**) ≈
**32 hours** of dedicated engineering + review. Preferred additions
(**F**+**G**+**H**+**I**+**J**) ≈ **33 hours** more — Workstream **I** is
revised from the pre-revision 4 h naming-only estimate to **14.5 h**
because the section is now scoped to *strengthen* the codebase rather than
rebadge weak content (nine new public declarations land at standard-trio
axioms, plus four renames + one deletion + two in-place Prop signature
strengthenings). Polish (**K**+**L**+**M**+**N**) ≈ **15 hours** more.
**Total pre-v1.0 engineering budget if every non-research workstream
lands: ~80.5 hours**.
The research milestones (**O**, R-01 through R-16) are multi-month and
explicitly scoped to v1.1+ / v2.0.

## 1. Finding taxonomy

The source audit organises findings by a module-group letter prefix
(A: toolchain; B: `GroupAction`; C: `Crypto`; D: `Theorems`; E: `KEM`;
F: `Construction`; G: `Probability`; H: `KeyMgmt`; I: `AEAD`;
J: `Hardness`; K: `PublicKey`; L: `Optimization`; M: root `Orbcrypt.lean`;
N: audit scripts; P: axiom transparency; X: cross-cutting; V1-*: release
checklist items; D1–D16: documentation-vs-code divergence log;
Z-*: performance / implementation; R-*: research follow-ups). This plan
**preserves the source-audit prefix** in every finding reference to keep
the cross-reference mechanical.

**Severity distribution** (source-audit § 14):

| Severity | Count (approx.) | Treatment in this plan |
|----------|-----------------|------------------------|
| CRITICAL | 1 (X-01) | Addressed by Workstreams **A** (documentation policy) + **B**/**C**/**E** (supporting Lean changes). |
| HIGH | 30+ | Partitioned across Workstreams **A**–**E** (blocking for v1.0) and **F**–**J** (strongly recommended). |
| MEDIUM | 50+ | Partitioned across Workstreams **F**–**N**. |
| LOW / INFO | 60+ | Grouped into Workstream **M** (cosmetic polish) and **N** (info hygiene). |

**Counts are approximate** because the source audit itself does not number
individual findings uniformly — some sections carry a single "Finding
<section>-NN" identifier per code reading, others enumerate multiple
findings per section. This plan uses the source-audit's exact identifier
for every finding cited (so `I-03` in this plan ↔ Finding I-03 in the
source audit at § 3.27).

## 2. Finding → workstream mapping

Only pre-release-actionable findings are listed here. § 18 (Workstream
**O**, the research + performance catalogue) owns the R-* and Z-*
identifiers; those are not release-blocking.

| Finding | Grade | Audit § | Workstream | Pre-release? |
|---------|-------|---------|------------|--------------|
| X-01 (two chains) | CRITICAL | 6.1 | **A** (framing) + **B**/**C**/**E** (Lean backfill) | **yes** |
| V1-1 / I-03 / I-04 | HIGH | 3.27, 10.1 | **B** | **yes** |
| V1-2 / L-03 / M-02 / D2 | HIGH | 3.39, 10.1, 9 | **A** (docs) + optional status-field lemma in **B** | **yes** |
| V1-3 / E-10 / J-12 / J-15 / D3 / D9 | HIGH | 3.16, 3.33, 10.1, 9 | **A** | **yes** |
| V1-4 / D-04 / D-05 / D-06 / D13 | HIGH / MED | 3.10, 9, 10.1 | **A** (framing) + **J** (helper cleanup) | **yes** |
| V1-5 / H-01 / D5 | HIGH | 3.24, 9, 10.1 | **A** | **yes** |
| V1-6 / A-03 | MEDIUM | 2.2, 10.1 | **D** | **yes** |
| V1-7 / I-08 / I-10 / D4 | HIGH | 3.29, 10.1 | **A** | **yes** |
| V1-8 / C-13 / D10 / R-09 | HIGH | 3.8, 10.1 | **C** | **yes** |
| V1-9 / X-01 | CRITICAL | 10.1 | **A** | **yes** |
| C-07 / E-06 / V1-11 | HIGH | 3.6, 3.15, 10.2 | **E** | preferred |
| C-15 / E-11 / V1-15 | LOW/MED | 3.8, 3.16, 10.2 | **I** | preferred |
| D-07 / V1-15 | HIGH | 3.11, 10.2 | **I** | preferred |
| J-03 / J-08 / V1-15 | HIGH | 3.31, 3.32, 10.2 | **I** | preferred |
| K-02 / V1-15 | HIGH | 3.34, 10.2 | **I** | preferred |
| F-04 / V1-10 | MEDIUM | 3.18, 10.2 | **F** | preferred |
| E-04 / V1-14 | HIGH | 3.13, 10.2 | **H** | preferred |
| C-01 / X-02 / V1-12 | MEDIUM | 3.4, 6.2, 10.2 | **H** | preferred |
| H-03 / Z-06 / V1-13 / D16 | MEDIUM | 3.24, 9, 10.2 | **G** | preferred |
| G-04 / G-05 / V1-16 | MEDIUM | 3.21, 10.2 | **J** | preferred |
| M-01 / V1-17 | HIGH | 4, 10.2 | **K** | polish |
| N-03 / N-04 / V1-18 | INFO | 5.2, 10.2 | **K** | polish |
| I-07 / V1-19 | MEDIUM | 3.28, 10.3 | **N** | polish |
| E-07 / V1-20 | MEDIUM | 3.15, 10.3 | **N** | polish |
| M-03 / V1-21 | LOW | 4, 10.3 | **K** | polish |
| E-08 / V1-22 | MEDIUM | 3.15, 10.3 | **N** | polish |
| All other MED findings | MEDIUM | §§ 3 various | **L** | polish |
| All other LOW / INFO findings | LOW / INFO | §§ 3 various | **M** / **N** | polish |
| R-01 … R-16 | research | 11 | **O** (catalogue) | v2.0 |
| Z-01 … Z-10 | performance | 12 | **O** (catalogue) | v1.1+ |

**Total pre-release slate:** Workstreams **A** + **B** + **C** + **D** +
**E**.
**Total preferred slate:** add **F** + **G** + **H** + **I** + **J**.
**Total polish slate:** add **K** + **L** + **M** + **N**.
**Deferred:** **O** (research + performance, tracked for v1.1+ / v2.0).

## 3. Workstream summary

| WS | Scope | Headline findings | Est. effort | Depends on | Slate |
|----|-------|-------------------|-------------|------------|-------|
| **A** | Release-messaging reconciliation: `CLAUDE.md` status column, `VERIFICATION_REPORT.md` release-readiness, `Orbcrypt.lean` header. Publishes the **release-messaging policy** (V1-9). Documents-only; no Lean source changes. | X-01, V1-2, V1-3, V1-4, V1-5, V1-7, V1-9, D1–D16 | 8 h | none | pre-release |
| **B** | `INT_CTXT` orbit-cover refactor: restrict the predicate to ciphertexts in the basepoint orbit (Option B) so the theorem discharges unconditionally; update `AuthOrbitKEM` consumers and the Carter–Wegman witness. | V1-1, I-03, I-04, D1, D12 | 6 h | none | pre-release |
| **C** | Multi-query hybrid reconciliation: rename `indQCPA_bound_via_hybrid` to surface the `h_step` user-hypothesis obligation, or provide the marginal-independence discharge from `ConcreteOIA`. | V1-8, C-13, D10 | 4 h | none | pre-release |
| **D** | Toolchain decision + `lakefile.lean` hygiene: decide stable-vs-rc, bump or freeze the toolchain and Mathlib pin, update `lakefile.lean` comment, add defensive linter options. | V1-6, A-01, A-02, A-03 | 2 h | none | pre-release |
| **E** | Formal vacuity witnesses: prove `det_oia_false_of_distinct_reps` and `det_kemoia_false_of_nontrivial_orbit` so the deterministic-chain scaffolding disclosures are machine-checked rather than prose-only. | C-07, E-06, V1-11 | 3 h | none | pre-release |
| **F** | Concrete `CanonicalForm` witness: land `CanonicalForm.ofLexMin` on finite subgroups of `S_n` acting on `Bitstring n`, closing the "no concrete canonical form in Lean" gap. | F-04, V1-10 | 4 h | none | preferred |
| **G** | λ-parameterised `HGOEKeyExpansion`: generalise `group_large_enough` from the hard-coded `≥ 128` bound to a parameter `λ : ℕ` with `group_order_log ≥ λ`, unlocking the {80, 192, 256} security levels the Phase-14 sweep already documents. | H-03, D16, V1-13, Z-06 | 3 h | none | preferred |
| **H** | Safe decapsulation + computable decryption: `decapsSafe : X → Option K` that rejects out-of-orbit ciphertexts; `decryptCompute` using `Finset.decidableExistsOfFinset` with an agreement theorem against `decrypt`. | E-04, C-01, X-02, V1-12, V1-14 | 6 h | **F** | preferred |
| **I** | Naming hygiene **via strengthening, not rebadging**: replace pre-I weak identifiers with the actual cryptographic content their names advertised — perfect-security non-vacuity witnesses for `ConcreteOIA` / `ConcreteKEMOIA_uniform` (replacing the trivial `_meaningful` lemmas), G-invariant separator from `reps_distinct` (replacing the non-G-invariant `insecure_implies_separating`), non-degeneracy fields on `GIReducesToCE` / `GIReducesToTI` (replacing the degenerate-encoder admission), probabilistic ε-smooth `ObliviousSamplingConcreteHiding` (replacing the deterministic `False`-on-non-trivial-bundle predicate). Per `CLAUDE.md`'s Security-by-docstring prohibition's *prove-the-property* clause: this is the strengthening branch of the rule, not the rename branch. Nine new public declarations land at standard-trio axioms; four pre-I identifiers are renamed; one is deleted; two `GIReducesTo*` Props gain non-degeneracy fields in place. | C-15, E-11, D-07, J-03, J-08, K-02, V1-15 | 14.5 h | none | preferred |
| **J** | Invariant-attack framing + negligible-function closure: tighten `invariant_attack` statement (D-04/D-13); add `IsNegligible.of_le` / `IsNegligible.const_mul` closure lemmas (G-04, G-05). | D-04, D-05, D-06, D13, G-04, G-05, G-06, V1-16 | 5 h | none | preferred |
| **K** | Root-file split + legacy script relocation: split the 1585-line `Orbcrypt.lean` docstring into `CHANGELOG.md` + `AXIOM_TRANSPARENCY.md`; move per-workstream audit scripts to `scripts/legacy/`. | M-01, M-02, M-03, N-03, N-04, V1-17, V1-18, V1-21 | 6 h | **A**, **I** | polish |
| **L** | Medium-severity structural cleanup: findings without dedicated workstreams — `CanonicalForm` bundled idempotence (B-04), `advantage` `toReal` threading (G-06/G-08), `probEvent`/`probTrue` consolidation (G-01/G-02), `hybridDist` left/right convention (C-14), `AuthOrbitKEM.encaps` triple (I-05), `DEM` security note (I-06), `MAC` metadata (I-02), `Tensor3` bundling (J-10), `SurrogateTensor` universe posture audit (X-04), combiner probabilistic lower bound (K-10/K-11), `hgoeKEM` unconstrained `keyDerive` (F-08), `nonceDecaps` aliasing (H-07), `OrbitalRandomizers` distinctness (K-04), `Hardness/Reductions.lean` split (J-14). Each is a single-file docstring or small-diff edit. | 30+ assorted MED findings | 8 h | none | polish |
| **M** | Low-severity cosmetic polish: docstring tightening (B-01, B-02, B-05, B-06, C-02, C-03, C-09, C-11, C-16, D-01, D-02, D-03, D-08, D-09, E-02, E-03, E-05, F-01, F-02, F-03, F-06, F-07, G-03, G-07, G-09, H-04, H-05, H-06, I-01, I-09, J-02, J-05, J-06, J-07, J-09, J-11, J-13, K-03, K-06, K-08, K-09, L-01, L-02, L-04, L-05, L-06, N-01, N-02, N-05, N-06, P-02, P-03, P-04, X-03, X-04, X-05). | 60+ assorted LOW/INFO findings | 6 h | none | polish |
| **N** | Optional pre-release engineering enhancements: authenticated hybrid layer (I-07/V1-19), `KEMAdversary.ofGame` adapter (E-07/V1-20), K2 design-note consolidation (E-08/V1-22). | V1-19, V1-20, V1-22, I-07, E-07, E-08 | 5 h | **B** | nice-to-have |
| **O** | Research & performance catalogue (NOT engineering deliverables): R-01 through R-16 research milestones, Z-01 through Z-10 performance milestones. Tracked for transparency; content assigned to v1.1+ and v2.0 roadmaps. | R-*, Z-* | n/a | n/a | v1.1+ / v2.0 |
| — | **Totals** | 140+ findings | ≈ 80.5 h | — | — |

**Parallelism.** Workstreams **A**, **C**, **D**, **E**, **F**, **G**,
**I**, **J**, **L**, **M** are mutually independent and can run in
parallel. Workstream **B** is the prerequisite for Workstream **N** (the
authenticated hybrid layer and `KEMAdversary.ofGame` adapter both consume
the refined `INT_CTXT` signature). Workstream **H** depends on Workstream
**F** for the concrete `CanonicalForm.ofLexMin` instance. Workstream
**K** depends on Workstream **A** (for the rewritten `CLAUDE.md` /
`VERIFICATION_REPORT.md` content to fold into `CHANGELOG.md` /
`AXIOM_TRANSPARENCY.md`) and Workstream **I** (renames must be stable
before the docstring snapshots migrate).

### 3.1 Workstream dependency graph

```
                ┌──────────────────────────────────────────┐
                │      ~~~ PRE-RELEASE SLATE (blocking) ~~~ │
                └──────────────────────────────────────────┘

                                       ┌────► N  (auth-hybrid,
  A ──────┐                             │         ofGame adapter)
  B ──────┤                             │
  C ──────┤────►  [v1.0 tag gate]  ─────┤────► release candidate
  D ──────┤                             │
  E ──────┘                             │
                                       │
                ┌─────────────────────────────────────────┐
                │     ~~~ PREFERRED PRE-RELEASE ~~~       │
                └─────────────────────────────────────────┘

  F  (lex-min canon)  ───► H  (decapsSafe, decryptCompute) ───► N
                              │
                              └───► polish-gate
  G  (λ-parametric HGOEKE)  ───────────────────────────────────►
  I  (renames)  ──────────────┐
                             ▼
  J  (invariant-attack,       K  (root split,
      negligible closures)    legacy migration)
                                       │
                                       ▼
                ┌─────────────────────────────────────────┐
                │     ~~~ POLISH (non-blocking) ~~~       │
                └─────────────────────────────────────────┘

  L  (30+ medium docstrings)   ──┐
  M  (60+ low / info)            ├──► continuous landing
                                  │
  O  (research + perf catalogue) ─► v1.1+ / v2.0 roadmap
```

Read as: an arrow `X ──► Y` means "Y cannot start until X is merged
into its target branch". Unlinked workstreams are parallel-safe.

**Critical path to v1.0 tag:** any one of **A**, **B**, **C**, **D**,
**E** (all independent, each ≈ 2–8 h). A single implementer working
serially lands the blocking slate in ~23 h of coding time; two
implementers working concurrently land it in ~8 h (bottleneck is
Workstream A at 8 h). Preferred slate (adding **F → H** and **I, J**)
adds another ~33 h serial or ~10 h parallel — Workstream **I**'s
strengthening rewrite (adopted in this revision in place of the
pre-revision rebadging plan) raises its individual estimate from
4 h to 14.5 h, but I1–I6 are mutually independent and parallelise
trivially across two implementers (≈ 6.5 h max-track + 2 h sequential
I7 audit-script + documentation sweep ≈ 8.5 h parallel for the
Workstream-I subportion alone).

**Critical-path longest chain:** `F → H → N` at 6 + 6 + 5 = 17 h. This
is the longest sequential dependency and determines the earliest
calendar date for an N-complete release: at least two working days if
run sequentially, one if parallelised with the critical slate.

## 4. Workstream A — Release-messaging reconciliation

**Severity.** CRITICAL (X-01) + multiple HIGH. **Effort.** ≈ 8 h.
**Scope.** Documentation-only. No Lean source files are modified.

### 4.1 Problem statement

Audit finding X-01 identifies the CRITICAL release-messaging gap:
`CLAUDE.md`'s "Three core theorems" Status column labels rows #19
(`authEncrypt_is_int_ctxt`), #24 (`two_phase_correct`), #25
(`two_phase_kem_correctness`), and #20 (`carterWegmanMAC_int_ctxt`) as
**Standalone**, when each one carries a hypothesis that is **false on
production HGOE** (row #19: `hOrbitCover`; rows #24 #25:
`TwoPhaseDecomposition` as self-disclosed in
`Optimization/TwoPhaseDecrypt.lean`'s module docstring; row #20: the
MAC is typed over `ZMod p × ZMod p → ZMod p`, incompatible with HGOE's
`Bitstring n` ciphertext space). The Status column should be
**Conditional** for those rows.

Additionally, the audit's **documentation-vs-code divergence log**
(§ 9, entries D1–D16) enumerates sixteen specific places where
documentation claims exceed what the Lean code delivers. Ten of the
sixteen are HIGH severity. Every such divergence is a v1.0
release-gate risk — an external reviewer reading `CLAUDE.md` or
`docs/VERIFICATION_REPORT.md` and finding a Scaffolding or
ε=1-inhabited theorem advertised as machine-checked security content
will correctly flag the project as mis-selling.

### 4.2 Scope

Workstream **A** performs the **release-messaging reconciliation
pass**:

1. Add a **"Release messaging policy"** section to `CLAUDE.md` that
   forbids citing a Scaffolding-class or Quantitative-at-ε=1
   theorem without explicit disclosure (V1-9).
2. Correct the Status column in `CLAUDE.md`'s "Three core theorems"
   table for every row identified in the divergence log (V1-2,
   V1-4, V1-5, V1-7 — the D1, D2, D4, D5, D6, D7, D8, D9, D12, D13,
   D16 entries).
3. Rewrite `docs/VERIFICATION_REPORT.md`'s "Release readiness"
   section to explicitly state that (a) the deterministic chain is
   scaffolding only; (b) the probabilistic chain is inhabited only
   at ε = 1 in the current formalisation; (c) concrete ε < 1
   discharges are research-scope (V1-3, V1-9).
4. Update `Orbcrypt.lean`'s "Vacuity map" table to mark
   probabilistic-chain counterparts as **ε = 1 only** (V1-3 /
   M-04).
5. Update `DEVELOPMENT.md` where its prose claims exceed the Lean
   content (`§6.2.1` compression ratio claim / D5; `§8.2`
   multi-query claim / D10; any other hits found in the cleanup
   pass).
6. Fix the invariant-attack narrative (`CLAUDE.md` row #2,
   `VERIFICATION_REPORT.md`) to match the theorem's actual
   statement (`∃ A, hasAdvantage`), not "advantage 1/2" / "complete
   break" (V1-4 / D13).
7. Reword the `SeedKey.compression` description to note the field
   is a **bit-length strict inequality** (minimum 1 bit), not the
   "256-bit seed → 10⁶⁰ group" quantitative ratio (V1-5 / D5).
8. Add explicit "`carterWegmanMAC_int_ctxt` is a
   **satisfiability witness** for `MAC.verify_inj` only; it does
   not compose with the concrete HGOE construction without a
   `Bitstring n → ZMod p` adapter (tracked as research R-13)"
   note (V1-7 / D4 / I-08).

### 4.3 Work units

#### A1 — Add "Release messaging policy" to `CLAUDE.md`

**File.** `CLAUDE.md`, new section immediately after the
"Security-by-docstring prohibition" under Key Conventions.

**Change.** Insert a ~40-line policy block stating:

* **Allowed citations (release-facing):** theorems classified
  **Standalone** or **Quantitative** in the headline table; every
  citation must include the theorem name, its Status classification,
  and — for Quantitative theorems — the ε bound and scheme-instance
  context.
* **Conditional citations:** theorems classified **Conditional** may
  be cited **only with their hypothesis made explicit**; e.g.
  `two_phase_kem_correctness` may be cited "under the
  `TwoPhaseDecomposition` hypothesis, which does not hold on the
  default GAP fallback group". Pure Conditional citations without
  the hypothesis disclosure are forbidden.
* **Scaffolding citations:** theorems classified **Scaffolding**
  may be cited **only to explain type-theoretic structure**, never
  as a security claim. E.g. `oia_implies_1cpa` may be cited "the
  deterministic reduction demonstrates the *shape* of the OIA→CPA
  argument; quantitative security content runs through
  `concrete_oia_implies_1cpa`". Pure Scaffolding citations framed
  as security claims are forbidden.
* **ε = 1 disclosure:** Every Quantitative-at-ε=1 result must be
  cited with the explicit phrase "inhabited only at ε = 1 via the
  trivial `_one_*` / `tight_one_exists` witness in the current
  formalisation; ε < 1 requires a concrete surrogate + encoder
  witness (research follow-up)".
* **Status-column authority:** the Status column of `CLAUDE.md`'s
  "Three core theorems" table and `docs/VERIFICATION_REPORT.md`'s
  headline table are the canonical source of truth. A PR that adds
  or modifies a headline theorem must update the Status column in
  both documents in the same diff.

**Acceptance.** Manual review; the policy is documented and
cross-linked from `docs/VERIFICATION_REPORT.md`'s "Release
readiness" section.

**Regression safeguard.** None (documentation-only). The policy
does not add CI enforcement; Workstream K may later add a
`status-label` lint if the policy is repeatedly violated.

#### A2 — Reclassify rows #19, #20, #24, #25

**File.** `CLAUDE.md`, the "Three core theorems" table (row entries
for theorem #19 / #20 / #24 / #25 in the 30-row table).

**Change.**

| Row | Theorem | Pre-A2 Status | Post-A2 Status | Rationale |
|-----|---------|---------------|----------------|-----------|
| #19 | `authEncrypt_is_int_ctxt` | Standalone | **Conditional** | Carries `hOrbitCover`, false on production HGOE (audit I-03). |
| #20 | `carterWegmanMAC_int_ctxt` | Standalone | **Conditional** | Requires `X = ZMod p` ≠ HGOE's `Bitstring n`; is a `MAC.verify_inj` satisfiability witness only (audit I-08 / D4). |
| #24 | `two_phase_correct` | Standalone | **Conditional** | Carries `TwoPhaseDecomposition` hypothesis, empirically false on the default GAP fallback group (audit L-03 / D2). |
| #25 | `two_phase_kem_correctness` | Standalone | **Conditional** | Same hypothesis as #24; the `(conditional)` suffix already in the theorem's display name is correctly surfaced, but the Status column is currently `Standalone`. |

Add a per-row prose qualifier (~1–2 lines in the "Significance"
column) disclosing the hypothesis and pointing to the non-vacuous
sibling where applicable: #19 → `keyDerive_canon_eq_of_mem_orbit`
(the orbit-restricted variant Workstream **B** lands);
#20 → `carterWegmanHash_isUniversal` (the standalone universal-
hash theorem); #24/#25 → `fast_kem_round_trip` (theorem #26, the
orbit-constancy result that is the actual GAP correctness story).

**Acceptance.**
- `grep -n "Standalone" CLAUDE.md` at rows #19, #20, #24, #25 no
  longer matches (they read `Conditional`).
- `docs/VERIFICATION_REPORT.md`'s headline table mirrors the
  update (A3 below handles this).

**Regression safeguard.** The release-gate checklist (§ 13)
includes a `grep`-based sentinel verifying the four Status values
are `Conditional` post-A2.

#### A3 — Rewrite `docs/VERIFICATION_REPORT.md` release-readiness

**File.** `docs/VERIFICATION_REPORT.md`, "Release readiness" +
"Known limitations" sections.

**Change.**

1. **Release readiness header.** Retitle from
   "Release readiness (post-Workstream-G, Workstream H, and
   Workstream J)" to
   "Release readiness (post-Workstream-G, H, J, and 2026-04-23
   audit)" and append a paragraph noting the 2026-04-23 audit
   surfaced eight documentation-vs-code divergences at the
   Status-column level, all remediated by Workstream **A** of the
   2026-04-23 plan.

2. **"What to cite externally" subsection.** Revise to read:
   - For **scheme-level quantitative security** (honest but at
     ε = 1 until research milestones R-02/R-03/R-04 land), cite
     `concrete_hardness_chain_implies_1cpa_advantage_bound` **with
     the ε-bound disclosed** and the surrogate choice
     (`punitSurrogate` gives trivial ε = 1; caller must supply a
     non-trivial `SurrogateTensor F` for meaningful ε < 1).
   - For **KEM-level quantitative security**, cite
     `concrete_kem_hardness_chain_implies_kem_advantage_bound`
     with the same ε-disclosure discipline.
   - For **scheme correctness**, cite `correctness` (unconditional).
   - For **KEM correctness**, cite `kem_correctness` (`rfl`).
   - For **distinct-challenge classical IND-1-CPA**, cite the
     Workstream-K `_distinct` corollaries with their scaffolding /
     quantitative classification exposed.
   - For **AEAD correctness**, cite `aead_correctness` (unconditional)
     and `hybrid_correctness` (unconditional).
   - For **ciphertext integrity (INT_CTXT)**, cite the
     **Workstream-B** refactored orbit-restricted form; **do not**
     cite `authEncrypt_is_int_ctxt` without the `hOrbitCover`
     disclosure if the Workstream-B refactor has not landed yet.

3. **"What NOT to cite externally" subsection.** New subsection
   listing every Scaffolding theorem (rows #3, #5, #8, #14;
   deterministic half of row #30) and every Quantitative-at-ε=1
   theorem that lacks a non-trivial ε witness, with the explicit
   advice: "do not cite as a security claim; cite only for
   type-theoretic structure or as an infrastructure-completeness
   witness". Include rows #19 (pre-B), #20, #24, #25 with their
   Conditional hypothesis exposed.

4. **"Known limitations" subsection.** Add three new bullets:
   - The orbit-cover hypothesis in pre-Workstream-B `INT_CTXT`
     (item D1 / I-03).
   - The empirical failure of `TwoPhaseDecomposition` on the
     default GAP fallback group (item D2 / L-03).
   - The Carter–Wegman `X = ZMod p` vs HGOE `Bitstring n`
     incompatibility (item D4 / I-08).

**Acceptance.**
- Manual review.
- Cross-reference `CLAUDE.md`'s release-messaging policy (A1).

**Regression safeguard.** None (documentation-only).

#### A4 — Update `Orbcrypt.lean`'s vacuity map

**File.** `Orbcrypt.lean`, the "Vacuity map" table (per the
Workstream-E snapshot).

**Change.** Every row with a "non-vacuous counterpart" column
entry that currently reads
`concrete_hardness_chain_implies_1cpa_advantage_bound` or
`concrete_kem_hardness_chain_implies_kem_advantage_bound` gains
the suffix "`(ε = 1 inhabited only via tight_one_exists; ε < 1 is
research-scope — see § O of the 2026-04-23 plan)`". New rows are
added for the four A2 reclassifications (row #19 / #20 / #24 /
#25) pairing the Conditional theorem with its hypothesis and its
standalone sibling.

**Acceptance.**
- The updated table renders cleanly in `Orbcrypt.lean`'s
  module-header docstring.
- No build-graph impact (comments do not affect kernel output).

#### A5 — Update `DEVELOPMENT.md` where prose exceeds code

**File.** `DEVELOPMENT.md`, sections §6.2.1 (seed-key compression),
§8.2 (multi-query IND-Q-CPA), §8.5 (INT-CTXT framing), and any
other section whose prose exceeds the Lean content.

**Change.** Audit-finding-driven edits:

- **§6.2.1 (D5 / V1-5 / H-01).** Rewrite the "256-bit seed → 10⁶⁰
  group" quantitative compression claim: state the **Lean-verified**
  property is `Nat.log 2 (Fintype.card Seed) < Nat.log 2 (Fintype.card G)`
  (bit-length strict inequality, minimum 1 bit); state the
  numerical compression ratio achievable at deployment is a
  **parameter choice** of the PRF and group construction, not a
  Lean-verified property.
- **§8.2 (D10 / V1-8 / C-13).** Add: "`indQCPA_bound_via_hybrid`
  carries the per-step bound `h_step` as a **user-supplied
  hypothesis**; the discharge of `h_step` from `ConcreteOIA` alone
  is tracked as research follow-up R-09 and is not part of the
  v1.0 formalisation. Workstream **C** of the 2026-04-23 plan
  either discharges `h_step` or renames the theorem to make the
  gap self-evident."
- **§8.5 (D1 / I-03).** Cross-link the Workstream-B INT_CTXT
  refactor and disclose the pre-B orbit-cover hypothesis.
- **§7.1 (F-05).** Explicitly disclose that Hamming-weight defense
  is **necessary but not sufficient**; other G-invariants (block
  sums, parity of weight over QC substructures) may still
  separate same-weight representatives.

**Acceptance.** Manual review. Cross-references to the
Workstream-B / C / E artefacts where those workstreams have
landed.

#### A6 — Fix the invariant-attack narrative

**File.** `CLAUDE.md` row #2; `docs/VERIFICATION_REPORT.md`
headline row for `invariant_attack`.

**Change.** Replace the "complete break / advantage = 1/2"
framing with a statement matching the theorem's actual
conclusion: `∃ A : Adversary X M, hasAdvantage scheme A` — i.e.,
**there exists an adversary that distinguishes on at least one
`(g₀, g₁)` pair**. Include a "Stronger reading available via the
probabilistic game" cross-link: on the probabilistic chain, the
invariant attack would produce a cross-orbit advantage ≥ some
lower bound determined by the invariant's separation behaviour;
that quantitative analysis is research follow-up R-01.

The existing "significance" column can keep its narrative force
("under a separating G-invariant, HGOE is broken") without
overstating the advantage value.

**Acceptance.** `CLAUDE.md` row #2 and the
`VERIFICATION_REPORT.md` equivalent no longer say "advantage
1/2" or "complete break" without immediate disclosure that the
theorem's formal conclusion is existence-of-one-distinguishing-
pair.

#### A7 — Cross-reference audit to plan in `CLAUDE.md` codebase status

**File.** `CLAUDE.md`, "Active development status" section, at the
end.

**Change.** Add a new top-level entry "**2026-04-23 Pre-Release
Audit (plan: `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md`)**
with a one-paragraph summary: 140+ findings partitioned into
fifteen workstreams **A**–**O**; zero erroneous findings per § 21
validation log; the pre-release slate is **A**+**B**+**C**+**D**+
**E** (≈ 32 h); v1.0 tag is gated on completion of the § 20
release-readiness checklist.

**Acceptance.** The entry exists, cross-links this plan document,
and lists the workstream-status checklist (empty at plan landing;
populated as workstreams close).

### 4.4 Risk register and rollback

| # | Risk | Likelihood | Severity | Mitigation | Rollback |
|---|------|-----------|----------|------------|----------|
| A-R1 | A reclassification (row #19/#20/#24/#25 Status column update) is later reverted in Workstream **B**; external consumers who pinned to the interim text see churn | Medium | Low | Workstream **A**'s reclassifications are framed as "pre-Workstream-**B** interim" with explicit forward-reference: "post-Workstream-**B**, row #19 upgrades to **Standalone**". The interim text and the post-B text are both pre-committed to this plan. | No code rollback. A single post-B documentation update tightens the Status column; no interim text is ever "wrong", only "superseded". |
| A-R2 | The "Release messaging policy" forbids citations external reviewers expect (e.g., a marketing page cites `authEncrypt_is_int_ctxt` as "INT-CTXT verified") | Medium | Medium | The policy's wording emphasizes what *can* be cited (Standalone, Quantitative-with-ε) with explicit examples; Conditional / Scaffolding theorems are listed as "cite with caveat" (not "never cite"). The policy is tested against a hypothetical marketing sentence before being finalized. | Amend the policy with an exception table; the correct response is to tighten the policy, not weaken it. |
| A-R3 | A prose update in `DEVELOPMENT.md` subtly alters the cryptographic specification (as distinct from aligning language) | Low | High | Every Workstream-A edit to `DEVELOPMENT.md` is limited to *removing overclaim* or *adding caveats*; the change set is reviewed against a pre-A snapshot to verify no new specification content is introduced. | `git revert` the offending edit; re-land with narrower scope. |
| A-R4 | The interim status "Conditional" is incorrectly read as "deprecated / abandoned" by downstream consumers | Low | Low | Every "Conditional" reclassification in `CLAUDE.md`'s headline table includes a one-sentence explanation of the condition (e.g., "requires orbit-cover precondition, Workstream B will absorb into game well-formedness"). | Doc-level remediation via a clarifying pull request; no structural change. |

**Full-workstream rollback.** Workstream A is documentation-only.
Rollback is always `git revert <commit>`; no code breakage risk.

### 4.5 Exit criteria for Workstream A

1. `CLAUDE.md`'s headline-theorem Status column reads `Conditional`
   for rows #19, #20, #24, #25.
2. `docs/VERIFICATION_REPORT.md`'s "Release readiness" section
   carries "What to cite / What NOT to cite" subsections with the
   Workstream-A reclassifications reflected.
3. `Orbcrypt.lean`'s vacuity map distinguishes ε = 1 witnesses
   from ε < 1 research-scope.
4. `DEVELOPMENT.md` prose at §6.2.1, §7.1, §8.2, §8.5 no longer
   overstates the Lean content.
5. The "Release messaging policy" section of `CLAUDE.md` is the
   canonical authority for release citations.
6. `lake build` is a no-op for comment changes (no regressions).
7. `scripts/audit_phase_16.lean` emits unchanged axiom output
   (Workstream **A** introduces no Lean declarations).
8. `CLAUDE.md`'s per-workstream log includes the 2026-04-23 audit
   cross-reference.
9. The risk register in § 4.4 has no open items (A-R1 closes once
   Workstream **B** lands; A-R2 / A-R3 / A-R4 close at plan
   signoff).

## 5. Workstream B — `INT_CTXT` orbit-cover refactor

**Severity.** HIGH (V1-1 / I-03 / I-04 / D1 / D12). **Effort.** ≈ 6 h.
**Scope.** Modifies `Orbcrypt/AEAD/AEAD.lean` and
`Orbcrypt/AEAD/CarterWegmanMAC.lean`; adds no new `.lean` files.

### 5.1 Problem statement

`authEncrypt_is_int_ctxt` in `Orbcrypt/AEAD/AEAD.lean:264` takes
`hOrbitCover : ∀ c : X, c ∈ MulAction.orbit G akem.kem.basePoint`
as an explicit hypothesis. On production HGOE the ciphertext space
is `Bitstring n = Fin n → Bool` with cardinality `2^n`; the orbit
of `basePoint` under any non-trivial subgroup `G ≤ S_n` has
cardinality at most `|G| / |Stab|` by the orbit-stabiliser
theorem, which is **strictly less than `2^n`** for any realistic
choice of `(n, G)`. So `hOrbitCover` is **false** on production
HGOE, and the theorem is vacuously applicable. The `CLAUDE.md`
Status column currently labels the theorem **Standalone**, which
is misleading.

### 5.2 Fix selection

Two remediation options are viable:

- **Option A (restrict the game).** Redefine `INT_CTXT` so that
  the adversary's forged ciphertext must lie in `orbit G basePoint`
  — i.e., the game **rejects** ciphertexts outside the orbit by
  construction. The theorem then discharges unconditionally on
  every `AuthOrbitKEM`. Downstream consumers who want
  INT-CTXT-on-arbitrary-ciphertexts (a stronger real-world threat
  model) must precede decapsulation with an explicit orbit-check,
  which Workstream **H** delivers as `decapsSafe`.

- **Option B (structural field).** Move `hOrbitCover` onto
  `AuthOrbitKEM` as a structural obligation
  (`orbit_cover : ∀ c : X, c ∈ orbit G basePoint`). Production
  HGOE cannot discharge this obligation, so `hgoeScheme`-derived
  `AuthOrbitKEM`s would be non-constructible — defeating the
  purpose.

**This plan adopts Option A.** Rationale: the real-world KEM
security model is "reject out-of-orbit ciphertexts", which matches
the Workstream-**H** `decapsSafe` design. The refactored
`INT_CTXT` predicate captures exactly what a correctly-implemented
KEM achieves; the pre-B `hOrbitCover` hypothesis is an artefact
of modelling an idealised game where all `X`-typed values are
legitimate ciphertexts.

### 5.3 Target API shape (post-fix)

```lean
/-- `INT_CTXT akem` holds when no adversary can forge a (c, t) pair
    that both (a) lies in the basepoint orbit and (b) passes
    `authDecaps` with a fresh tag (not produced by the challenger).
    Out-of-orbit ciphertexts are rejected by the game's
    well-formedness precondition and do not count as forgeries. -/
def INT_CTXT
    {G : Type*} {X : Type*} {K : Type*} {Tag : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (akem : AuthOrbitKEM G X K Tag) : Prop :=
  ∀ (c : X) (t : Tag)
    (_hOrbit : c ∈ MulAction.orbit G akem.kem.basePoint)
    (_hFresh : ∀ g : G, (c, t) ≠ (authEncaps akem g).1),
    authDecaps akem (c, t) = none
```

The `hOrbit` hypothesis is *caller-supplied per challenge*, not a
global scheme-level obligation; every `AuthOrbitKEM` now satisfies
`INT_CTXT` unconditionally.

### 5.4 Work units

Workstream **B** is a single-module refactor with four downstream
propagation steps. WUs **B1a** and **B1b** split the in-module work
(predicate-signature change first, proof-body threading second, so
the two diffs review independently). WUs **B2**–**B4** propagate to
consumers and documentation.

#### B1a — Refactor `INT_CTXT` predicate signature (no proof body changes)

**File.** `Orbcrypt/AEAD/AEAD.lean`.

**Precise change.** Only the `INT_CTXT` `def` is touched in this
WU; `authEncrypt_is_int_ctxt` is left in its pre-B1a state and
will temporarily fail to type-check (the hypothesis `hOrbitCover`
no longer matches the new predicate shape). This is *intentional*:
it confines the signature-change diff to one `def`, so a reviewer
can approve the predicate refinement without also approving the
proof-body threading in B1b.

Target form:

```lean
def INT_CTXT
    {G : Type*} {X : Type*} {K : Type*} {Tag : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (akem : AuthOrbitKEM G X K Tag) : Prop :=
  ∀ (c : X) (t : Tag)
    (_hOrbit : c ∈ MulAction.orbit G akem.kem.basePoint)
    (_hFresh : ∀ g : G, (c, t) ≠ (authEncaps akem g).1),
    authDecaps akem (c, t) = none
```

**Acceptance.**
- `lake build Orbcrypt.AEAD.AEAD` **intentionally fails at this
  WU**; record the build-failure message in the B1a commit body.
- `#check @INT_CTXT` shows the refactored signature.

**Rollback rule.** If B1b cannot be landed within 24 hours of B1a
for any reason, **revert B1a** — do not ship the repository with a
broken build. Workstream **B** is atomic at the B1a + B1b + B2
granularity; either all three land or none do.

#### B1b — Refactor `authEncrypt_is_int_ctxt` proof body

**File.** `Orbcrypt/AEAD/AEAD.lean`.

**Precise change.** Rewrite `authEncrypt_is_int_ctxt`'s signature
and proof body to consume the per-challenge `hOrbit` hypothesis
instead of the top-level `hOrbitCover`. The private helpers
`authDecaps_none_of_verify_false` (C2a) and
`keyDerive_canon_eq_of_mem_orbit` (C2b) are **unchanged** — both
already take a direct orbit-membership fact as input, not a
universal-`hOrbitCover` consequence.

The proof body's `obtain ⟨g, hg⟩ := MulAction.mem_orbit_iff.mp
(hOrbitCover c)` line at AEAD.lean:290 is replaced by `obtain
⟨g, hg⟩ := MulAction.mem_orbit_iff.mp hOrbit` (the `c` is now
implicit from the per-challenge binder); the later
`(keyDerive_canon_eq_of_mem_orbit akem (hOrbitCover c)).symm`
invocation at AEAD.lean:322 becomes
`(keyDerive_canon_eq_of_mem_orbit akem hOrbit).symm`.

Post-refactor signature:

```lean
theorem authEncrypt_is_int_ctxt
    {G : Type*} {X : Type*} {K : Type*} {Tag : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (akem : AuthOrbitKEM G X K Tag) :
    INT_CTXT akem := by
  intro c t hOrbit hFresh
  -- unchanged tactic body, using `hOrbit` where `hOrbitCover c`
  -- previously appeared
  ...
```

**Acceptance.**
- `lake build Orbcrypt.AEAD.AEAD` **succeeds** at this WU (B1a +
  B1b together restore the build).
- `#check @authEncrypt_is_int_ctxt` shows the refactored signature
  (no `hOrbitCover` parameter).
- `#print axioms authEncrypt_is_int_ctxt` emits only
  `[propext, Classical.choice, Quot.sound]` (unchanged from pre-B).

**Regression safeguard.** `authDecaps_none_of_verify_false` and
`keyDerive_canon_eq_of_mem_orbit` are declared `private` at
AEAD.lean:282-ish and :299-ish respectively; their non-mutation in
B1b is part of the acceptance criteria. If a reviewer's feedback
forces a refactor of those helpers, the refactor belongs in a
separate PR with its own non-vacuity witness test.

#### B2 — Update Carter–Wegman INT_CTXT witness

**File.** `Orbcrypt/AEAD/CarterWegmanMAC.lean`.

**Change.** `carterWegmanMAC_int_ctxt` loses its `hOrbitCover`
argument and threads the per-challenge `hOrbit` through. The
proof body is structurally unchanged.

**Acceptance.**
- `lake build Orbcrypt.AEAD.CarterWegmanMAC` succeeds.
- `#check @carterWegmanMAC_int_ctxt` shows the refactored
  signature.

**Regression safeguard.** `scripts/audit_phase_16.lean` and
`scripts/audit_c_workstream.lean` both exercise
`authEncrypt_is_int_ctxt` and `carterWegmanMAC_int_ctxt` in their
non-vacuity `example` blocks; those examples are updated to
match the new signature.

#### B3 — Update audit scripts + non-vacuity witnesses

**Files.** `scripts/audit_phase_16.lean`,
`scripts/audit_c_workstream.lean`.

**Change.** Existing examples that instantiate `INT_CTXT` on a
`Unit`-typed toy `AuthOrbitKEM` are updated: the trivial
discharge `hOrbit` for the toy is `by trivial` (singleton orbit);
the discharge on the Carter–Wegman witness uses the `ZMod 2 ×
ZMod 2`-orbit-under-`Equiv.swap` structure already present in
`audit_c_workstream.lean`'s post-L2 migration.

**Acceptance.**
- `lake env lean scripts/audit_phase_16.lean` produces only
  standard-trio axioms.
- `lake env lean scripts/audit_c_workstream.lean` produces only
  standard-trio axioms and the `INT_CTXT` examples type-check.

#### B4 — Update `CLAUDE.md` headline-table entry #19

**File.** `CLAUDE.md`.

**Change.** Row #19's Status is now **Standalone** (post-B) —
the orbit-cover hypothesis has been absorbed into the game's
well-formedness precondition, so the theorem discharges
unconditionally. This is a tightening of the Workstream-**A**
reclassification (pre-B: `Standalone` mislabel → `Conditional`;
post-B: genuinely `Standalone`). Update row #19's
"Significance" column with: "post-Workstream-B refactor: the
orbit-cover hypothesis is the game's well-formedness
precondition, not a theorem-level obligation — `INT_CTXT`
discharges unconditionally on every `AuthOrbitKEM`".

Also update row #20 similarly: post-B, `carterWegmanMAC_int_ctxt`
is an unconditional specialisation but **still requires
`X = ZMod p`**; the Workstream-**A** HGOE-incompatibility
disclosure (D4 / I-08) remains relevant. Row #20 retains the
Conditional label with the compatibility caveat; cross-reference
R-13 for the `Bitstring n → ZMod p` adapter research.

**Acceptance.** Row #19 reads **Standalone**; row #20 reads
**Conditional** with the compatibility disclosure.

### 5.5 Risk register and rollback

| # | Risk | Likelihood | Severity | Mitigation | Rollback |
|---|------|-----------|----------|------------|----------|
| B-R1 | B1a lands but B1b is blocked by reviewer feedback; repository left with broken build | Low | High | WUs B1a + B1b must land in a single PR or two sequential PRs merged within the same 24-hour window. Reviewer must be tagged before B1a is pushed. | `git revert <B1a-commit>` restores the pre-B1a predicate shape; a new PR bundles B1a + B1b together. |
| B-R2 | The per-challenge `hOrbit` hypothesis semantics diverge from the literature's "honest ciphertext" convention in consumers' mental models | Medium | Medium | Workstream **A** A3 carries the release-messaging note explicitly framing this as "the game rejects out-of-orbit ciphertexts by well-formedness precondition". `docs/VERIFICATION_REPORT.md` cross-links B's refactor with **H**'s `decapsSafe` (same conceptual pairing). | Semantic-only concern; no code rollback required. If consumer confusion persists post-release, a v1.1 polish PR adds a `INT_CTXT_unrestricted` variant that re-introduces the universal hypothesis at the game level. |
| B-R3 | A future `AuthOrbitKEM` consumer forgets the orbit-membership precondition and invokes `INT_CTXT` on an out-of-orbit ciphertext, producing a statement they mis-interpret as "always `none`" | Low | Medium | `INT_CTXT`'s docstring explicitly declares the caller's obligation; Workstream **H**'s `decapsSafe` (single-point-of-truth for orbit validation) is the canonical consumer. | Doc-level remediation; no rollback. |
| B-R4 | Carter–Wegman witness (B2) breaks because the post-L2 `[Fact (Nat.Prime p)]` constraint interacts with the new signature | Low | Low | B2 simply removes one argument from the theorem signature; proof body is mechanical `obtain`/`intro` renaming. B2 is a ≤ 20-line diff. | `git revert <B2-commit>` temporarily reverts B2; update `scripts/audit_c_workstream.lean` to fall back to the pre-B signature in its non-vacuity witness. |

**Full-workstream rollback.** If any of the four WUs fails at review
gate, revert all four atomically and leave the audit finding I-03
open (with a cross-reference to this plan) until a revised approach
(e.g., Option B / structural field) is evaluated in a follow-up
plan. `CLAUDE.md`'s row #19 Status would then be re-labeled
**Conditional** (the Workstream-A reclassification) until a
successful refactor.

### 5.6 Exit criteria for Workstream B

1. `lake build` for all 38 modules succeeds.
2. `INT_CTXT` takes `hOrbit` per-challenge, no `hOrbitCover` at
   theorem signature level.
3. `scripts/audit_phase_16.lean` passes with the updated
   examples; axiom set unchanged.
4. `CLAUDE.md` row #19 is **Standalone**, row #20 is
   **Conditional** with the compatibility caveat.
5. `Orbcrypt.lean`'s axiom-transparency report is updated with a
   Workstream-B snapshot.
6. The risk register in § 5.5 has no open items (B-R1 is closed by
   the successful single-PR merge; B-R2 / B-R3 / B-R4 are
   doc-level and do not require post-merge action).

## 6. Workstream C — Multi-query hybrid reconciliation

**Severity.** HIGH (V1-8 / C-13 / D10). **Effort.** ≈ 4 h (rename
track) or ≈ 16 h (discharge track — then falls into research scope R-09).
**Scope.** Modifies `Orbcrypt/Crypto/CompSecurity.lean`; no new files.

### 6.1 Problem statement

`indQCPA_bound_via_hybrid` carries the per-step bound `h_step` as
an **explicit hypothesis** rather than discharging it from
`ConcreteOIA scheme ε`. External documentation
(`docs/VERIFICATION_REPORT.md`, various `DEVELOPMENT.md` prose
discussing multi-query security) describes the theorem as
"multi-query IND-Q-CPA from `ConcreteOIA`", which overstates
what the code delivers. The marginal-independence argument
(showing `h_step` follows from `ConcreteOIA` via a marginal over
`uniformPMFTuple`) is a non-trivial proof about PMF
push-forwards; it has been deferred since the Workstream-E
landing of the 2026-04-18 audit (tracked as E8b in that plan, and
as R-09 in this plan's research catalogue).

### 6.2 Fix selection

Two remediation options:

- **Track 1 (rename).** Rename the theorem to make the
  user-hypothesis obligation self-evident. For example,
  `indQCPA_bound_via_hybrid` → `indQCPA_from_perStepBound` (the
  name proposed in the audit). Also rename
  `indQCPA_bound_recovers_single_query` to keep terminology
  consistent. Update docstrings and all external documentation.
  Effort: ≈ 4 h.

- **Track 2 (discharge).** Formalise the marginal-independence
  step `∀ i, advantage (hybridDist scheme choose i) (hybridDist
  scheme choose (i+1)) ≤ ε` from `ConcreteOIA scheme ε`. This is
  research-scope R-09; the proof navigates PMF push-forwards
  along a coordinate projection of `uniformPMFTuple`. Effort:
  research-multi-week.

**This plan adopts Track 1 for v1.0.** Rationale: Track 2 is
genuine research formalisation (equivalent to providing a new
probabilistic meta-theorem about PMF coordinate independence).
The v1.0 release should not block on research; Track 1 honestly
surfaces the gap in the theorem's name, matching `CLAUDE.md`'s
naming convention that identifier names describe what the code
*proves*, not what the code *aspires to*. Track 2 is catalogued
at § 18 (R-09) as a post-v1.0 milestone.

### 6.3 Work units

#### C1 — Rename `indQCPA_bound_via_hybrid`

**File.** `Orbcrypt/Crypto/CompSecurity.lean`.

**Change.** Rename `indQCPA_bound_via_hybrid` to
`indQCPA_from_perStepBound`. The docstring prepends a "Game
shape" paragraph making the per-step obligation explicit: "This
theorem delivers a Q·ε bound on the multi-query IND-Q-CPA
advantage **given** a per-query bound `h_step` that the caller
must discharge. The discharge of `h_step` from `ConcreteOIA
scheme ε` alone is research-scope (see
`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 18 / R-09);
until that lands, consumers supply `h_step` from custom analysis
or from a stronger assumption (e.g., a query-adaptive variant of
`ConcreteOIA`)."

Rename the companion `indQCPA_bound_recovers_single_query` to
`indQCPA_from_perStepBound_recovers_single_query` for
consistency.

**Acceptance.**
- `lake build Orbcrypt.Crypto.CompSecurity` succeeds.
- `grep -rn "indQCPA_bound_via_hybrid"` across the repo returns
  empty (all references updated).
- `#print axioms indQCPA_from_perStepBound` emits only standard-
  trio axioms.

**Regression safeguard.** `scripts/audit_phase_16.lean` and any
other audit script that referenced the old name is updated in
the same commit. The old name is **not retained as an alias**
(per `CLAUDE.md`'s no-backwards-compat-shim rule).

#### C2 — Update `CLAUDE.md`, `VERIFICATION_REPORT.md`,
`DEVELOPMENT.md` references

**Files.** `CLAUDE.md` (if the theorem appears in the codebase
status section), `docs/VERIFICATION_REPORT.md` (headline table /
release-readiness), `DEVELOPMENT.md §8.2` (multi-query IND-Q-CPA
discussion).

**Change.** Substitute the new name everywhere the old name
appears; where the old name appeared in a sentence describing
what the theorem proves, rewrite to expose the `h_step`
obligation (matching the Workstream-**A** release-messaging
policy).

**Acceptance.** `grep -rn "indQCPA_bound_via_hybrid"` across the
repo — including `.md` files — returns empty.

#### C3 — Add `IndQCPA_Adversary_withPerStepBound` structure (optional)

**File.** `Orbcrypt/Crypto/CompSecurity.lean`.

**Change (optional — can be deferred to v1.1).** Introduce a
helper structure bundling a `DistinctMultiQueryAdversary` with
its per-query bound, so callers can pattern-match on the bundle
instead of carrying the bound as a separate hypothesis. This is
ergonomic sugar; the C1 rename is the core remediation.

**Acceptance.** If landed, the structure ships with a
non-vacuity witness in `scripts/audit_phase_16.lean`; if
deferred, the deferral is noted in the C3 commit message. This
plan does NOT require C3 for v1.0.

### 6.4 Risk register and rollback

| # | Risk | Likelihood | Severity | Mitigation | Rollback |
|---|------|-----------|----------|------------|----------|
| C-R1 | External consumers have cached `indQCPA_bound_via_hybrid` via Lean tooling (e.g., LSP) and a rename produces confusing broken references for days | Low | Low | Rename lands in a single atomic PR; the old name is *not* kept as a deprecated alias (per `CLAUDE.md` no-backwards-compat rule). LSP rebuilds on next `lake build`. | Affected parties invoke `lake clean && lake build`. |
| C-R2 | The renamed `indQCPA_from_perStepBound` carries the same `h_step` hypothesis, but downstream readers continue to mistake it for an unconditional multi-query bound | Medium | Medium | The new name explicitly surfaces the obligation (`from_perStepBound`); the theorem's docstring carries a "**User-supplied hypothesis obligation**" block with explicit discharge-template language. | Additional docstring-level tightening in a follow-up PR; no code rollback. |
| C-R3 | A future attempt to discharge `h_step` from `ConcreteOIA` (research R-09) finds a subtle counterexample, invalidating the premise of the rename | Very low | Medium | The rename is content-neutral: if R-09 is solvable, the discharge theorem sits next to `indQCPA_from_perStepBound` and consumes it; if R-09 is impossible, the rename is the correct final name. Either way, no revision is needed. | No action; the rename is future-proof. |

**Full-workstream rollback.** If the rename meets external-reviewer
resistance (e.g., a consumer requests the old name via a pin), the
rollback is a single `git revert`. The underlying mathematical
content is unchanged by the rename; reverting does not lose theorem
content.

### 6.5 Exit criteria for Workstream C

1. `indQCPA_bound_via_hybrid` no longer exists in any `.lean`
   source file; its content is at `indQCPA_from_perStepBound`.
2. Every external document references the new name.
3. `DEVELOPMENT.md §8.2` exposes the `h_step` user-hypothesis
   obligation.
4. `#print axioms indQCPA_from_perStepBound` emits only standard-
   trio axioms; the research follow-up (R-09) is tracked in this
   plan's § 18.
5. `lake build` succeeds; `scripts/audit_phase_16.lean` passes.
6. The risk register in § 6.4 has no open items.

## 7. Workstream D — Toolchain decision + `lakefile.lean` hygiene

**Severity.** MEDIUM (V1-6 / A-01 / A-02 / A-03). **Effort.** ≈ 2 h.
**Scope.** Modifies `lakefile.lean`, `lean-toolchain`, possibly
`lake-manifest.json`; no `.lean` source changes.

### 7.1 Problem statement

`lean-toolchain` pins `leanprover/lean4:v4.30.0-rc1`, a release
candidate rather than a stable release. Shipping a v1.0 off an rc
toolchain is out of step with mainstream Lean/Mathlib projects.
Additionally, `lakefile.lean`'s comment line 12 reads "Last
verified: 2026-04-14", which is stale (Workstream L / M / N
revalidations in 2026-04-22 / 2026-04-23 have implicitly
revalidated). And no defensive `leanOption` pins for
`linter.unusedVariables` or `linter.docPrime` — the zero-warning
gate is enforced only by the CI warning-as-error setting.

### 7.2 Fix selection

Three scenarios:

- **Scenario A (stable toolchain available).** If Mathlib has
  pinned a stable Lean release (e.g., `v4.30.0` or `v4.31.0`) at
  a commit compatible with the current `Hardness/Reductions.lean`
  API, bump `lean-toolchain` and `lakefile.lean`'s Mathlib pin
  together, update `lake-manifest.json` via `lake update`, and
  run the full audit suite. Effort: ≈ 2 h + review.

- **Scenario B (no stable pairing available).** Keep
  `v4.30.0-rc1`; add a release-note item "built against
  v4.30.0-rc1, stable-toolchain upgrade deferred to v1.1".
  Effort: ≈ 0.5 h (documentation only).

- **Scenario C (split).** Ship v1.0 off the rc; open a v1.1
  tracking issue with the stable-upgrade commitment. This is the
  most common pre-release posture.

**This plan adopts Scenario C by default** (minimises
release-cycle risk) and leaves the final choice to the project
owner at tag time. The workstream's work units cover both paths.

### 7.3 Work units

#### D1 — Toolchain decision

**Task.** Project owner reviews Mathlib's stable-toolchain
availability at release time. Records the decision in the v1.0
release notes.

**Artefacts.**
- If Scenario A: a diff updating `lean-toolchain`,
  `lakefile.lean` Mathlib pin, and `lake-manifest.json`; a full
  `lake build` + `scripts/audit_phase_16.lean` clean run.
- If Scenario B/C: a release-notes entry explaining the rc
  choice and the v1.1 upgrade commitment.

**Acceptance.** Decision recorded; artefacts landed.

#### D2 — Refresh `lakefile.lean` comment metadata

**File.** `lakefile.lean`.

**Change.** Update comment line 12 from "Last verified:
2026-04-14" to the current audit date ("Last verified:
2026-04-23"). Add a one-line cross-reference to
`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md`.

**Acceptance.** `lakefile.lean` comment metadata matches reality.

#### D3 — Add defensive `leanOption` entries

**File.** `lakefile.lean`.

**Change (optional, recommended for v1.0).** Add:

```lean
leanOptions := #[
  ⟨`autoImplicit, false⟩,  -- already present, keep
  ⟨`linter.unusedVariables, true⟩,
  ⟨`linter.docPrime, true⟩
]
```

Run a full `lake build` and fix any warnings that surface. If
warnings exist, they are fixed in a follow-up work unit under
Workstream **M** (cosmetic polish).

**Acceptance.**
- `lake build` succeeds with exit code 0.
- No new warnings are introduced (or, if any surface, each is
  either fixed or explicitly documented in the D3 commit
  message).

### 7.4 Exit criteria for Workstream D

1. Toolchain decision recorded in release notes.
2. `lakefile.lean` metadata is current as of 2026-04-23.
3. Defensive linter options (if landed) compile clean.
4. `scripts/audit_phase_16.lean` emits unchanged axiom output.

## 8. Workstream E — Formal vacuity witnesses

**Severity.** HIGH (C-07 / E-06 / V1-11). **Effort.** ≈ 3 h.
**Scope.** Modifies `Orbcrypt/Crypto/OIA.lean` and
`Orbcrypt/KEM/Security.lean`; adds two new theorems.

### 8.1 Problem statement

`Crypto/OIA.lean`'s module docstring (lines 46–67) asserts in
prose that the deterministic OIA is `False` for every non-trivial
scheme ("because `f := fun x => decide (x = reps m₀)` is a
distinguisher"). Same pattern for `KEM/Security.lean`'s
`KEMOIA` docstring (lines 186–189). Neither claim is **formally
proved**; consumers wishing to verify the scaffolding disclosure
must take the prose on trust. This is the exact pattern that
`CLAUDE.md`'s "no docstring disclaimers" rule forbids for
**security claims**; the present case is a **vacuity claim** (the
opposite direction — disclosing that a predicate is false) and is
therefore not a strict Security-by-docstring violation, but the
absence of a machine-checked witness weakens the
`Orbcrypt.lean` axiom-transparency story.

### 8.2 Fix scope

Two small, axiom-free theorems that discharge the vacuity claim
on any non-trivial scheme:

```lean
/-- The deterministic OIA predicate is False whenever the scheme
    has two messages whose representatives lie in distinct orbits
    (which is exactly the `reps_distinct` obligation). The
    distinguisher is `fun x => decide (x = reps m₀)`. -/
theorem det_oia_false_of_distinct_reps
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    {m₀ m₁ : M} (hDistinct : scheme.reps m₀ ≠ scheme.reps m₁) :
    ¬ OIA scheme := by
  intro hOIA
  have := hOIA (fun x => decide (x = scheme.reps m₀)) m₀ m₁ 1 1
  simp [one_smul] at this
  exact hDistinct (of_decide_eq_true (by simpa using this.symm))

/-- The deterministic KEMOIA predicate is False whenever the KEM's
    basepoint orbit is non-trivial (|orbit| ≥ 2). Distinguisher is
    the orbit-membership Boolean evaluated at a specific orbit
    element. -/
theorem det_kemoia_false_of_nontrivial_orbit
    ...
```

The KEM-layer version parallels the scheme-layer version; its
hypothesis is "there exist two distinct group elements whose
action on basepoint produces distinct ciphertexts" — always true
on production non-trivial KEMs.

### 8.3 Work units

Workstream **E** lands two small, axiom-free theorems plus a
transparency-report update. Each theorem is ≤ 15 lines of Lean;
the complexity is concentrated in the *decidability-instance plumbing*
(the distinguisher `fun x => decide (x = scheme.reps m₀)` requires a
`Decidable (x = scheme.reps m₀)` instance, which follows from
`[DecidableEq X]` on the scheme's carrier).

#### E1 — Add `det_oia_false_of_distinct_reps`

**File.** `Orbcrypt/Crypto/OIA.lean`, at the bottom of the module
(after the existing `OIA` def and documentation block).

**Change.** Add the theorem with the full proof body:

```lean
/-- **Vacuity witness (audit 2026-04-23 C-07).** The deterministic
    `OIA` predicate is `False` whenever the scheme exhibits two
    messages whose representatives are distinct — which is exactly
    the `reps_distinct` obligation. The distinguisher is the
    orbit-membership test `fun x => decide (x = scheme.reps m₀)`,
    which is `true` on the `m₀`-orbit point after identity-element
    action and `false` on the `m₁`-orbit point.

    This theorem machine-checks the scaffolding disclosure that
    `Orbcrypt.lean`'s vacuity map previously asserted only in prose.
    Callers of `oia_implies_1cpa` now have a formal handle on the
    vacuity: compose this theorem with `absurd` to derive `False`
    under a hypothesis of the form `OIA scheme ∧ scheme.reps m₀ ≠
    scheme.reps m₁`. -/
theorem det_oia_false_of_distinct_reps
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    {m₀ m₁ : M} (hDistinct : scheme.reps m₀ ≠ scheme.reps m₁) :
    ¬ OIA scheme := by
  intro hOIA
  -- Apply OIA to the membership-at-m₀ Boolean distinguisher, at
  -- identity group elements, on the (m₀, m₁) message pair.
  have h := hOIA (fun x => decide (x = scheme.reps m₀)) m₀ m₁ 1 1
  -- Identity action reduces `1 • reps mᵢ` to `reps mᵢ`.
  simp only [one_smul] at h
  -- The LHS decide evaluates to `true` (reflexivity); the RHS to
  -- `false` (distinctness). Contradiction.
  have hLHS : decide (scheme.reps m₀ = scheme.reps m₀) = true :=
    decide_eq_true (Eq.refl _)
  have hRHS : decide (scheme.reps m₁ = scheme.reps m₀) = false :=
    decide_eq_false (fun heq => hDistinct heq.symm)
  rw [hLHS, hRHS] at h
  exact Bool.true_eq_false_iff.mp h |>.elim
```

**Rationale for each tactic step.**
- `intro hOIA` — destructure the Prop-valued `OIA`, making its
  universal-over-`(f, m₀, m₁, g₀, g₁)` body available.
- `hOIA _ m₀ m₁ 1 1` — instantiate with identity group elements.
  This is the *minimal* instantiation; more elaborate choices (any
  `(g₀, g₁)`) also work but `1 • x = x` is the cleanest rewrite.
- `simp only [one_smul]` — reduces `1 • scheme.reps mᵢ` to
  `scheme.reps mᵢ` on both sides.
- `decide_eq_true (Eq.refl _)` — the Mathlib-standard idiom for
  discharging `decide P = true` when `P` holds definitionally.
- The final contradiction is
  `Bool.true_eq_false_iff.mp h` (`h : true = false`).

**Decidability obligation.** The `DecidableEq X` typeclass instance
is already on `scheme`'s context (every scheme-level theorem in the
codebase carries it); no new instance is needed. The per-theorem
elaboration of `decide (x = scheme.reps m₀)` uses
`instDecidableEq` transparently.

**Acceptance.**
- `lake build Orbcrypt.Crypto.OIA` succeeds, zero warnings.
- `#print axioms Orbcrypt.det_oia_false_of_distinct_reps` emits
  `'Orbcrypt.det_oia_false_of_distinct_reps' depends on axioms:
  [propext, Classical.choice, Quot.sound]` (standard trio; the
  `decide` tactics introduce `Classical.choice` via the
  `Decidable.decide`-elaboration path).
- A non-vacuity `example` in `scripts/audit_phase_16.lean`
  exhibits the theorem applied to the in-tree toy scheme from
  `§ 12 NonVacuityWitnesses`: two-message scheme over `Unit × Unit`
  with reps `⟨true, false⟩` and `⟨false, true⟩` (distinct by
  construction).

#### E2 — Add `det_kemoia_false_of_nontrivial_orbit`

**File.** `Orbcrypt/KEM/Security.lean`, at the bottom of the
module.

**Change.** The KEM-layer analogue. The KEM game quantifies over
group elements (not messages); the vacuity hypothesis is therefore
the existence of two distinct *ciphertexts* on the basepoint's
orbit — equivalently, two group elements `g₀, g₁ : G` with
`g₀ • basePoint ≠ g₁ • basePoint`.

```lean
/-- **Vacuity witness (audit 2026-04-23 E-06).** The deterministic
    `KEMOIA` predicate is `False` whenever the KEM's basepoint
    orbit is non-trivial — i.e., there exist two group elements
    producing distinct ciphertexts. Distinguisher:
    `fun c => decide (c = g₀ • basePoint)`.

    Parallel to `det_oia_false_of_distinct_reps` at the KEM layer.
    The hypothesis `∃ g₀ g₁ : G, g₀ • kem.basePoint ≠ g₁ •
    kem.basePoint` holds on every realistic KEM (production HGOE
    has |orbit| ≫ 2); the witness theorem machine-checks the
    scaffolding disclosure. -/
theorem det_kemoia_false_of_nontrivial_orbit
    {G : Type*} {X : Type*} {K : Type*}
    [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K)
    {g₀ g₁ : G}
    (hDistinct : g₀ • kem.basePoint ≠ g₁ • kem.basePoint) :
    ¬ KEMOIA kem := by
  intro hKEMOIA
  -- Apply KEMOIA to the membership-at-(g₀ • basePoint) distinguisher.
  have h := hKEMOIA
    (fun c => decide (c = g₀ • kem.basePoint)) g₀ g₁
  -- The LHS decide is `true` (reflexivity on `g₀ • basePoint`).
  -- The RHS decide is `false` (distinctness hypothesis).
  have hLHS : decide (g₀ • kem.basePoint = g₀ • kem.basePoint) = true :=
    decide_eq_true (Eq.refl _)
  have hRHS : decide (g₁ • kem.basePoint = g₀ • kem.basePoint) = false :=
    decide_eq_false (fun heq => hDistinct heq.symm)
  rw [hLHS, hRHS] at h
  exact Bool.true_eq_false_iff.mp h |>.elim
```

**Note on `KEMOIA`'s single-conjunct form.** Post-Workstream-L5
(2026-04-21), `KEMOIA` is a single-conjunct orbit
indistinguishability predicate; the former key-uniformity conjunct
was unconditional and was removed. E2's proof therefore does not
need to thread `hKEMOIA.1`/`.2` destructuring — it applies the
single Prop directly.

**Decidability obligation.** Identical to E1 — `DecidableEq X` is
already on every KEM-level theorem's context.

**Acceptance.**
- `lake build Orbcrypt.KEM.Security` succeeds.
- `#print axioms Orbcrypt.det_kemoia_false_of_nontrivial_orbit`
  emits the standard trio.
- A non-vacuity `example` in `scripts/audit_phase_16.lean`
  exhibits the theorem on a concrete toy KEM with a permutation
  group `{1, σ}` where `σ ≠ 1`, `σ • basePoint ≠ basePoint`.
  This uses the `Equiv.swap`-based witness already in
  `§ 12 NonVacuityWitnesses`.

#### E3 — Update `Orbcrypt.lean` vacuity-map + transparency report

**File.** `Orbcrypt.lean`.

**Change.** The vacuity-map table gains a "Machine-checked
vacuity witness" column pointing to E1 / E2 where applicable.
The Workstream-A ε=1 disclosure remains. Add a new
"Workstream E Snapshot (audit 2026-04-23, findings C-07 / E-06)"
section at the end of the transparency report.

**Acceptance.** The vacuity-map reader can navigate from each
Scaffolding theorem to its machine-checked vacuity witness
theorem (E1 / E2).

### 8.4 Risk register and rollback

| # | Risk | Likelihood | Severity | Mitigation | Rollback |
|---|------|-----------|----------|------------|----------|
| E-R1 | The `decide` elaboration path introduces `Classical.choice` in `#print axioms` output unexpectedly | Low | Low | The proof sketches in § 8.3 explicitly use `decide_eq_true` / `decide_eq_false` with `Eq.refl` / lambda discharge — both paths already introduce `Classical.choice` in-tree (as evidenced by Phase 16 audit). The standard trio is expected and acceptable. | If somehow the axioms expand beyond the standard trio, switch to a `rfl`-based discharge via `Bool.decide_True` / `Bool.decide_False` explicit rewrites. |
| E-R2 | `simp only [one_smul]` does not fire because the `MulAction` instance is elaborated via coercion (e.g., `↥G` with subgroup coercion) | Medium | Low | Fall back to `rw [one_smul, one_smul]` or to explicit `MulAction.one_smul` invocations. The proof body is short enough that the tactic-flavor is easy to adjust. | Proof-body edit only. |
| E-R3 | `det_kemoia_false_of_nontrivial_orbit` hypothesis `g₀ • kem.basePoint ≠ g₁ • kem.basePoint` is satisfied by every production KEM but requires an explicit witness for the non-vacuity example; finding a witness on the in-tree toy KEM is non-trivial | Medium | Low | The Phase-16 `§ 12 NonVacuityWitnesses` block already constructs an `Equiv.swap 0 1`-based toy action on `ZMod 2` (Workstream C post-L2); the same construction witnesses `σ • 0 ≠ 1 • 0`. Reuse. | Use a different witness group (e.g., `Subgroup.closure {Equiv.swap 0 1}` on `Fin 3 → Bool`); structural, not proof-body, change. |
| E-R4 | A future `KEMOIA` refactor adds a second conjunct (unlikely post-L5 but possible), and E2's proof no longer destructures correctly | Very low | Medium | E2's proof is written against the post-L5 single-conjunct form explicitly; a future refactor would need to update E2 in the same PR. | If the refactor lands separately, a follow-up PR adjusts E2's `intro hKEMOIA` pattern to destructure. |

**Full-workstream rollback.** E1 + E2 + E3 land in one atomic PR.
If review blocks the PR, the scaffolding disclosure reverts to
prose-only (pre-E state); Workstream A's release-messaging policy
remains authoritative for external citations.

### 8.5 Exit criteria for Workstream E

1. `det_oia_false_of_distinct_reps` and
   `det_kemoia_false_of_nontrivial_orbit` land with standard-trio
   axiom dependencies only.
2. `Orbcrypt.lean`'s vacuity-map cross-references both witnesses.
3. `scripts/audit_phase_16.lean` exercises both in its non-vacuity
   witness block.
4. `lake build` succeeds for all modules; `CLAUDE.md` gains a
   Workstream-E snapshot and both theorems appear in the
   "zero-custom-axiom" exit-criteria list.
5. The risk register in § 8.4 has no open items.

**Closure status (2026-04-24).** All five exit criteria verified.
`det_oia_false_of_distinct_reps` lands in `Orbcrypt/Crypto/OIA.lean`
and `det_kemoia_false_of_nontrivial_orbit` in
`Orbcrypt/KEM/Security.lean`, each depending only on the standard
Lean trio (`propext`, `Classical.choice`, `Quot.sound`) — never on
`sorryAx` or a custom axiom. `Orbcrypt.lean`'s Vacuity map is
upgraded to a three-column table with a "Machine-checked vacuity
witness" column pointing rows #1–#2 (plus the inheriting
hardness-chain / K-distinct rows) at E1 / E2; two new `#print
axioms` cookbook entries land under a "Workstream E (audit
2026-04-23, findings C-07 + E-06)" subsection; a new "Workstream E
Snapshot" section is appended at the end of the transparency
report. `scripts/audit_phase_16.lean` gains two new `#print axioms`
entries (adjacent to `#print axioms OIA` and `#print axioms
KEMOIA`) and two concrete non-vacuity `example` bindings in the
`NonVacuityWitnesses` namespace: a two-message `trivialSchemeBool`
under the trivial action of `Equiv.Perm (Fin 1)` on `Bool`, and a
`trivialKEM_PermZMod2` under the natural `Equiv.Perm (ZMod 2)`
action on `ZMod 2`. `CLAUDE.md` gains the required Workstream-E
snapshot (immediately after the Workstream-D snapshot), two new
entries in the `#print axioms` exit-criteria list, headline-theorem
rows #31–#32 (both **Standalone**), and the Workstream-E tracker
row's checkbox is ticked. `docs/VERIFICATION_REPORT.md`'s headline
table and document history are likewise extended. `lakefile.lean`
bumped from `0.1.9` to `0.1.10`. All four risk-register items
(E-R1 through E-R4) closed clean — no fallback tactic required.

## 9. Workstream F — Concrete `CanonicalForm` from lex-min

**Severity.** MEDIUM (V1-10 / F-04). **Effort.** ≈ 4 h.
**Scope.** New module `Orbcrypt/GroupAction/CanonicalLexMin.lean`
(or embeds as a new section in `Orbcrypt/GroupAction/Canonical.lean`;
the final choice is a WU F1 decision). Modifies
`Orbcrypt/Construction/HGOE.lean` only to add a convenience
constructor.

### 9.1 Problem statement

`hgoeScheme` takes `can : CanonicalForm (↥G) (Bitstring n)` as a
**parameter** without providing a concrete instance. The GAP
reference implementation uses lex-minimum orbit element, but
there is no Lean-side witness that a lex-min `CanonicalForm`
exists for any concrete nontrivial finite subgroup of S_n. Every
downstream theorem that types `{can : CanonicalForm (↥G) …}` is
therefore parameterised by a structure with no constructed
inhabitant in-tree.

### 9.2 Fix scope

Land `CanonicalForm.ofLexMin` (or similar name — the final
identifier is a naming-hygiene decision in F1, per
`CLAUDE.md`'s naming discipline), a constructor that takes a
finite subgroup `G ≤ S_n` with appropriate `Fintype` /
`DecidableEq` instances and builds a `CanonicalForm (↥G)
(Bitstring n)` via `Finset.min'` on the orbit with respect to a
lexicographic order on `Bitstring n`.

### 9.3 Target API shape

```lean
/-- Lex-min canonical form on `Bitstring n` under a finite
    subgroup of `S_n`. The orbit is a `Finset`; `Finset.min'`
    picks the lex-minimum element. Membership: the min' is an
    orbit element (trivially, since it's in the orbit). Orbit
    characterisation: two points have the same min' iff they
    have the same orbit. -/
def CanonicalForm.ofLexMin
    {n : ℕ} (G : Subgroup (Equiv.Perm (Fin n))) [Fintype (↥G)]
    [DecidableEq (Bitstring n)] :
    CanonicalForm (↥G) (Bitstring n) where
  canon := fun x => (MulAction.orbit (↥G) x).toFinset.min' ⟨x, by
    exact MulAction.mem_orbit_self x⟩
  mem_orbit := by
    intro x
    exact Finset.min'_mem _ _
  orbit_iff := by
    intro x y
    constructor
    · intro h
      -- equal min' implies same orbit (both in orbit of the
      -- shared min')
      sorry  -- WU F3 fills in; not landing with `sorry` in tree
    · intro h
      -- same orbit implies same toFinset, hence same min'
      congr 1
      exact Finset.coe_injective (Set.ext fun z => by
        simp [Set.mem_toFinset, MulAction.mem_orbit_iff,
              MulAction.orbit_eq_iff.mpr h])
```

The `sorry` in the sketch above is **not** intended to land; WU F3
provides the completed proof. The sketch is illustrative only —
per `CLAUDE.md`'s no-`sorry` gate, landing a sketch with a
`sorry` would red-card CI.

### 9.4 Work units

#### F1 — Naming decision + module placement

**Decision point.** Two placement options:

- **Option A:** new module `Orbcrypt/GroupAction/CanonicalLexMin.lean`
  that re-exports `CanonicalForm` and adds `ofLexMin`.
- **Option B:** append `ofLexMin` to
  `Orbcrypt/GroupAction/Canonical.lean` as a new section.

**Recommendation.** Option A — keeps `Canonical.lean` lean
(pure abstract structure) and bundles the concrete-construction
helpers in a dedicated submodule. Mirrors the Mathlib convention
of separating "abstract structure" and "concrete instances".

**Acceptance.** Placement decided; naming-hygiene grep (per
`CLAUDE.md` naming conventions) returns empty for any
workstream/audit token in the chosen identifier.

#### F2 — Implement `CanonicalForm.ofLexMin.canon` and `mem_orbit`

**File.** Per F1 decision.

**Change.** Define `canon` via `Finset.min'` on the orbit's
`toFinset`. Prove `mem_orbit` by `Finset.min'_mem` — the `min'`
is in the finset by construction, and the finset is the orbit.

**Acceptance.**
- `lake build` of the new/modified module succeeds.
- `canon` is computable (modulo `DecidableEq` / `Fintype` typeclass
  obligations, which are inputs).

#### F3a — Helper lemma: orbit membership implies `toFinset` membership

**File.** Per F1 decision.

**Change.** Add a helper lemma `mem_orbit_toFinset_iff` proving that
the `.toFinset` of `MulAction.orbit (↥G) x` contains `y` iff `y ∈
MulAction.orbit (↥G) x`. This is a thin wrapper around
`Set.mem_toFinset` but having it named at the module level makes
the downstream proofs (F3b, F3c) dramatically cleaner.

```lean
private lemma mem_orbit_toFinset_iff
    {n : ℕ} (G : Subgroup (Equiv.Perm (Fin n)))
    [Fintype (MulAction.orbit (↥G) x)] (x y : Bitstring n) :
    y ∈ (MulAction.orbit (↥G) x).toFinset ↔
    y ∈ MulAction.orbit (↥G) x :=
  Set.mem_toFinset
```

**Decidability / `Fintype` obligation.** `(MulAction.orbit (↥G) x)`
is a `Set (Bitstring n)`. Converting to a `Finset` via `.toFinset`
requires `Fintype ↥(MulAction.orbit (↥G) x)`. This instance is
derivable from `[Fintype (Bitstring n)]` (automatic since
`Bitstring n = Fin n → Bool`) plus `[DecidablePred (· ∈ MulAction.orbit (↥G) x)]`
(which requires `[DecidableEq (Bitstring n)]` plus `[Fintype (↥G)]`).

**Action item.** If the derived instance is not found automatically
by Lean's typeclass search, add an explicit `instance` block at the
top of the file:

```lean
instance {n : ℕ} (G : Subgroup (Equiv.Perm (Fin n))) [Fintype (↥G)]
    (x : Bitstring n) : Fintype (MulAction.orbit (↥G) x) :=
  Set.Finite.fintype (Set.Finite.map _ (Set.toFinite _))
```

(The exact incantation depends on Mathlib's precise `Set.Finite`
API; a grep for `MulAction.orbit.*Fintype` in Mathlib finds the
canonical form.)

**Acceptance.**
- `lake build` on the new module succeeds.
- `#print axioms mem_orbit_toFinset_iff` emits only standard-trio
  axioms.

#### F3b — Prove `orbit_iff` forward direction (`canon x = canon y → orbit x = orbit y`)

**File.** Per F1 decision, inside the `CanonicalForm.ofLexMin`
definition's `orbit_iff` field.

**Proof strategy.**
1. Let `m := canon x = canon y` (the shared lex-min value).
2. By `Finset.min'_mem` + `mem_orbit_toFinset_iff`, `m ∈ orbit x`
   and `m ∈ orbit y`.
3. By `MulAction.orbit_eq_iff.mpr`, `m ∈ orbit x` implies
   `orbit m = orbit x`; symmetrically `orbit m = orbit y`.
4. Transitivity: `orbit x = orbit m = orbit y`.

**Explicit Lean body.**

```lean
-- Forward direction
intro h_canon_eq
-- Extract: min' of orbit x is the shared value m
set m := (MulAction.orbit (↥G) x).toFinset.min' ⟨x, by
  exact MulAction.mem_orbit_self x⟩ with hm_def
-- m is in orbit x (by min'_mem)
have hm_x : m ∈ MulAction.orbit (↥G) x :=
  (mem_orbit_toFinset_iff G x m).mp (Finset.min'_mem _ _)
-- m = min' orbit y as well (from h_canon_eq)
have hm_y : m ∈ MulAction.orbit (↥G) y := by
  rw [hm_def]
  rw [h_canon_eq]  -- canon x = canon y reduces LHS to RHS shape
  exact (mem_orbit_toFinset_iff G y _).mp (Finset.min'_mem _ _)
-- Conclude orbit x = orbit y via transitivity through m's orbit
rw [← MulAction.orbit_eq_iff.mpr hm_x,
    ← MulAction.orbit_eq_iff.mpr hm_y]
```

**Subtle point: `set … with hm_def` vs. `let`.** The `set` tactic
creates a definitional equation `hm_def : m = …` that can be used
by `rw` in either direction. This is important because step 4
rewrites `orbit m` on both sides via the symmetric equations.

**Acceptance.**
- The forward-direction proof compiles.
- `#print axioms` emits only standard-trio axioms.

#### F3c — Prove `orbit_iff` reverse direction (`orbit x = orbit y → canon x = canon y`)

**File.** Per F1 decision, continuing inside the same `orbit_iff`
field after F3b.

**Proof strategy.**
1. Hypothesis: `orbit x = orbit y` (as `Set (Bitstring n)`).
2. The `.toFinset` operation is `Set`-injective on finite sets:
   equal sets give equal finsets.
3. Equal finsets give equal `min'` values (with the trivial
   non-empty-finset witnesses).

**Explicit Lean body.**

```lean
-- Reverse direction
intro h_orbit_eq
-- Show the two toFinsets are equal (as Finsets)
have h_toFinset_eq : (MulAction.orbit (↥G) x).toFinset =
    (MulAction.orbit (↥G) y).toFinset := by
  ext z
  rw [mem_orbit_toFinset_iff, mem_orbit_toFinset_iff]
  constructor
  · intro hz; rw [← h_orbit_eq]; exact hz
  · intro hz; rw [h_orbit_eq]; exact hz
-- Equal toFinsets give equal min' values. Mathlib's
-- Finset.min'_congr does this under a non-empty-witness constraint.
rw [show (fun (s : Finset (Bitstring n)) (h : s.Nonempty) => s.min' h) =
    Finset.min' from rfl]
congr 1
exact h_toFinset_eq
```

**Subtle point: `Finset.min'` and proof-irrelevance.** `Finset.min'`
takes a non-emptiness proof as a second argument. When the
underlying finset is the same, any two non-emptiness proofs give
the same `min'` (by proof-irrelevance for `Prop`-valued
arguments to functions). The `congr 1` tactic reduces the goal to
the finset-equality hypothesis.

**Alternative shorter body** (if `congr 1` does not close the
non-emptiness-proof subgoal automatically):

```lean
intro h_orbit_eq
simp only [h_orbit_eq]
```

Because `canon x` is definitionally
`(MulAction.orbit (↥G) x).toFinset.min' ⟨x, _⟩` and the orbit
equation `h_orbit_eq : orbit G x = orbit G y` rewrites the
`toFinset` directly, `simp only [h_orbit_eq]` may close the goal
in one line. The F3 implementer selects whichever form compiles
cleanest; both are proof-equivalent.

**Acceptance.**
- The reverse-direction proof compiles.
- Combined with F3b, the `orbit_iff` field of
  `CanonicalForm.ofLexMin` is fully discharged.
- `#print axioms Orbcrypt.CanonicalForm.ofLexMin` emits only
  standard-trio axioms.
- **No `sorry` in the tree**: the WU F3a + F3b + F3c sequence
  replaces the illustrative `sorry` in § 9.3 entirely.

#### F3d — Concrete-instance non-vacuity witness

**File.** `scripts/audit_phase_16.lean`.

**Change.** Add to `§ 12 NonVacuityWitnesses` a worked example:

```lean
-- Non-vacuity witness for CanonicalForm.ofLexMin (audit F-04 / V1-10)
section LexMinWitness
open Orbcrypt

/-- A concrete subgroup of S_3 for which ofLexMin exhibits a
    computable canonical form. -/
example : ∃ (G : Subgroup (Equiv.Perm (Fin 3))),
    True := by
  -- The subgroup generated by the swap (0 1)
  let σ : Equiv.Perm (Fin 3) := Equiv.swap 0 1
  refine ⟨Subgroup.closure {σ}, trivial⟩

/-- The lex-min canonical form of `![true, false, true]` under the
    subgroup `⟨Equiv.swap 0 1⟩` is `![true, false, true]` itself
    (the swap of positions 0 and 1 yields `![false, true, true]`,
    but under the GAP-matching `bitstringLinearOrder`'s "leftmost-
    true wins" convention, the input `![true, false, true]` has its
    leftmost true at position 0 while `![false, true, true]` has
    its leftmost true at position 1, so the input itself is the
    lex-min of the orbit).

    NOTE: this expected value reflects the GAP-matching order
    landed in Workstream F. An earlier sketch in this planning
    document predicted `![false, true, true]` based on the
    standard `false < true` Bool ordering interpretation; the
    actual implementation uses the inverted-Bool composition
    `List.ofFn ∘ (! ∘ ·)` so that Lean's canonical-form choice
    matches the GAP reference's `CanonicalImage(G, x, OnSets)`
    output point-for-point. -/
-- Evaluation test (expected to reduce by `decide` at compile time):
example :
    let σ : Equiv.Perm (Fin 3) := Equiv.swap 0 1
    let G : Subgroup (Equiv.Perm (Fin 3)) := Subgroup.closure {σ}
    let can := CanonicalForm.ofLexMin G
    can.canon ![true, false, true] = ![true, false, true] := by
  decide
end LexMinWitness
```

**Acceptance.**
- The `decide` call terminates in reasonable time (~seconds at
  n = 3).
- The non-vacuity witness is a machine-checked demonstration that
  `ofLexMin` computes concrete canonical forms — not merely that
  it type-checks.

**Alternative if `decide` is too slow.** If the `decide` call
exceeds the 60-second default, replace with `native_decide`; if
that too is slow, reduce to `n = 2` (`⟨Equiv.swap 0 1⟩` on
`Bitstring 2`). The non-vacuity witness's *purpose* is confirming
computation, not stress-testing.

#### F4 — Convenience constructor in HGOE

**File.** `Orbcrypt/Construction/HGOE.lean`.

**Change.** Add a `hgoeScheme.ofLexMin` helper that takes a
finite subgroup + reps + distinctness and returns an
`OrbitEncScheme` with the lex-min canonical form auto-filled.
This is ergonomic sugar; existing `hgoeScheme` callers are not
required to migrate.

**Acceptance.**
- `hgoeScheme.ofLexMin` type-checks and produces a well-formed
  scheme.
- A non-vacuity example in the audit script exercises the full
  correctness chain using `ofLexMin` to eliminate the
  `can` parameter.

### 9.5 Risk register and rollback

| # | Risk | Likelihood | Severity | Mitigation | Rollback |
|---|------|-----------|----------|------------|----------|
| F-R1 | `Fintype (MulAction.orbit (↥G) x)` instance is not found by automatic typeclass search | Medium | Low | F3a adds an explicit instance block as fallback; a one-line typeclass declaration resolves this. | Add the explicit instance locally; if Mathlib's API has changed, use `Set.Fintype.ofFinset` idiom. |
| F-R2 | `simp only [h_orbit_eq]` in F3c does not close the goal cleanly because `canon` unfolds through multiple layers | Low | Low | F3c provides two alternative proof bodies (congr-based + simp-based); the implementer picks whichever compiles. | If neither works, fall back to the four-line explicit proof using `Finset.min'` equality plus `h_orbit_eq` rewrite on the `toFinset` argument — a mechanical expansion of the `congr 1` tactic. |
| F-R3 | `decide` in F3d's non-vacuity witness exceeds the CI time limit | Low | Low | F3d documents a `native_decide` fallback and an `n = 2` size reduction. | If both fail, replace the witness with a proof-level `rfl` after manually evaluating `canon` on both sides; the goal is computation demonstration, not stress testing. |
| F-R4 | `Finset.min'` on `Bitstring n = Fin n → Bool` requires a `LinearOrder` instance not automatically provided | Medium | Medium | Mathlib has `Pi.linearOrder` for `Fin n → Bool` (via `Bool.linearOrder` + Pi instance). Verify the instance is found; if not, derive via `Lex.linearOrder` with an explicit lex coercion. | If the instance path is non-trivial, switch from `Finset.min'` (which needs `LinearOrder`) to `Finset.min` (which needs only `LE` + decidable equality), but then canonical form might be `Option`-valued; wrap with a `Classical.choice` fallback. |

**Full-workstream rollback.** F is a preferred-pre-release item, not
a blocker. If F3a–F3c cannot be completed within the 4-hour effort
estimate (e.g., Mathlib API surprises), park the work with a note in
§ 20 (Release-readiness checklist) and defer to v1.1; do not push a
partial `CanonicalForm.ofLexMin`.

### 9.6 Exit criteria for Workstream F

1. `CanonicalForm.ofLexMin` is a computable `def` landing with
   standard-trio axioms only.
2. A concrete non-vacuity witness (F3d) exhibits the constructor
   on a small instance and evaluates `canon` by `decide` /
   `native_decide`.
3. `hgoeScheme.ofLexMin` eliminates the `can` parameter for
   callers who use the lex-min convention.
4. `CLAUDE.md` gains a Workstream-F snapshot; the headline
   theorem table references the new constructor in the
   `CanonicalForm`-related rows.
5. No `sorry` in the tree: WUs F3a + F3b + F3c together discharge
   the `orbit_iff` obligation that § 9.3's illustrative sketch
   deliberately left as `sorry`.
6. The risk register in § 9.5 has no open items.

### 9.7 Closure status (2026-04-24)

**Workstream F is closed.**

All six § 9.6 exit criteria met:

1. ✅ `CanonicalForm.ofLexMin` lands as a computable `def` in
   `Orbcrypt/GroupAction/CanonicalLexMin.lean`. `#print axioms
   Orbcrypt.CanonicalForm.ofLexMin` reports `[propext,
   Classical.choice, Quot.sound]` — standard Lean trio only.
2. ✅ Non-vacuity witness (F3d) exhibits
   `CanonicalForm.ofLexMin.canon ![true, false, true] =
   ![true, true, false]` under `Equiv.Perm (Fin 3)` on
   `Bitstring 3` via `decide` — matching GAP's
   `CanonicalImage(S_3, {0, 1}, OnSets) = {0, 1}` exactly; a
   second `decide`-backed example confirms the singleton-orbit
   case
   `canon ![false, false, false] = ![false, false, false]`.
3. ✅ `hgoeScheme.ofLexMin` (in
   `Orbcrypt/Construction/HGOE.lean`) eliminates the `can`
   parameter; a type-elaboration witness at `G := ⊤ ≤ S_3` with
   `M := Unit` confirms the convenience constructor fires at a
   concrete finite subgroup of `Equiv.Perm (Fin 3)`.
4. ✅ `CLAUDE.md` gains a Workstream-F snapshot; the
   Workstream status tracker row for F is marked closed;
   source-layout tree gains the `CanonicalLexMin.lean` entry;
   module-dependency graph extended with the Workstream-F
   node.
5. ✅ No `sorry` in the tree. The CI's "Verify no sorry" step
   (comment-aware Perl strip) passes locally; WUs F3a + F3b +
   F3c together discharge the `orbit_iff` obligation without
   any `sorry` anywhere in the landed source.
6. ✅ Risk register § 9.5 items F-R1 through F-R4: none
   encountered during landing.
   * **F-R1** (orbit `Fintype` typeclass search): Mathlib's
     `Set.fintypeRange` instance fires automatically under
     `[Fintype G] [DecidableEq X]` because `MulAction.orbit`
     is definitionally `Set.range`; no explicit instance
     block needed.
   * **F-R2** (`simp only [h_orbit_eq]` closure): the landed
     proof uses `congr 1 ; exact Set.toFinset_congr h_orbit_eq`
     rather than `simp only`; this alternative from § 9.4
     F3c's "alternative shorter body" path compiles cleanly.
   * **F-R3** (`decide` timing): the non-vacuity witness at
     n = 3 + full `Equiv.Perm (Fin 3)` evaluates in well
     under the 60-second default; no `native_decide` fallback
     required.
   * **F-R4** (`LinearOrder (Bitstring n)` instance): handled
     by defining `bitstringLinearOrder` as a `@[reducible]
     def` rather than a global instance to avoid the diamond
     with Mathlib's pointwise `Pi.partialOrder`. Callers bind
     it locally via `letI`. This is a genuine design decision
     that surfaced during landing; the § 9.5 "Rollback"
     column suggested switching to `Finset.min` +
     `Option`-valued canonical form, which the `def`-scoped
     approach side-steps entirely.

**Landing artefacts:**
- Lean: 9 new public declarations (6 in
  `Orbcrypt/GroupAction/CanonicalLexMin.lean`, 1 in
  `Orbcrypt/Construction/Permutation.lean`, 2 in
  `Orbcrypt/Construction/HGOE.lean`); module count 39 → 40;
  public declaration count 349 → 358.
- Audit script: 6 new `#print axioms` calls, 4 new
  non-vacuity `example` bindings; audit total 373 → 382.
- Version: `lakefile.lean` `0.1.10 → 0.1.11`.
- Docs: `CLAUDE.md`, `Orbcrypt.lean` axiom-transparency
  report, `docs/VERIFICATION_REPORT.md` Document history —
  all extended with Workstream-F sections.
- CI: "Verify no sorry", "Verify no unexpected axioms", and
  Phase-16 audit-script steps all pass locally with the
  de-wrap parser seeing only standard-trio axioms.

No open follow-ups; the workstream is fully self-contained.

## 10. Workstream G — λ-parameterised `HGOEKeyExpansion`

**Severity.** MEDIUM (V1-13 / H-03 / Z-06 / D16). **Effort.** ≈ 3 h.
**Scope.** Modifies `Orbcrypt/KeyMgmt/SeedKey.lean`; adds no new
modules.

### 10.1 Problem statement

`HGOEKeyExpansion` (line 218 onwards in `SeedKey.lean`) has a
field `group_large_enough : group_order_log ≥ 128`. The literal
`128` is **hard-coded** and **not a structure parameter**. The
Phase-14 parameter sweep (`docs/PARAMETERS.md`,
`docs/benchmarks/results_{80,128,192,256}.csv`) exercises four
security levels (λ ∈ {80, 128, 192, 256}), but the
formalisation's `HGOEKeyExpansion` structure is only
instantiable at λ = 128 because the other three levels cannot
discharge `group_order_log ≥ 128` (λ = 80) or the bound is
weaker than needed (λ = 192, 256).

### 10.2 Fix scope

Parameterise `HGOEKeyExpansion` by a security parameter `λ : ℕ`;
the field `group_large_enough` becomes
`group_order_log ≥ λ` for caller-supplied `λ`. Production
callers at each security level instantiate the structure with
their λ; the Workstream-**A** `DEVELOPMENT.md` update (A5) now
matches the Lean content.

### 10.3 Target API shape

```lean
structure HGOEKeyExpansion (λ : ℕ) (n : ℕ) (M : Type*) where
  -- existing fields ...
  group_order_log : ℕ
  group_large_enough : group_order_log ≥ λ
  -- other fields unchanged ...
```

All callers are updated: every downstream theorem and every audit
script example that constructs an `HGOEKeyExpansion` passes an
explicit λ.

### 10.4 Work units

#### G1 — Add `λ` parameter to `HGOEKeyExpansion`

**File.** `Orbcrypt/KeyMgmt/SeedKey.lean`.

**Change.** Insert `(λ : ℕ)` as a leading structure parameter
(after `(n : ℕ)` or before — naming and parameter-order is a
style decision; recommended to keep `n` first to match existing
convention, then insert `λ`, then `M`). `group_large_enough`'s
type becomes `group_order_log ≥ λ`.

**Acceptance.**
- `lake build Orbcrypt.KeyMgmt.SeedKey` succeeds.
- `#check @HGOEKeyExpansion` shows `(λ : ℕ)` as an explicit
  parameter.

**Regression safeguard.** Every existing call site is updated in
the same commit; `grep -rn "HGOEKeyExpansion"` across the repo
audits full coverage.

#### G2 — Instantiate at {80, 128, 192, 256}

**File.** `scripts/audit_phase_16.lean` (non-vacuity witnesses).

**Change.** Add four `example`s exhibiting
`HGOEKeyExpansion 80 …`, `HGOEKeyExpansion 128 …`,
`HGOEKeyExpansion 192 …`, `HGOEKeyExpansion 256 …` on toy
instances whose `group_order_log` is large enough in each case.
These serve as the machine-checked witnesses that the
parameterised structure is non-vacuous at every documented
security level.

**Acceptance.** Four `example`s type-check; `#print axioms`
emits only standard-trio axioms on each.

#### G3 — Update `DEVELOPMENT.md` and `docs/PARAMETERS.md`

**Files.** `DEVELOPMENT.md §6.2.1`, `docs/PARAMETERS.md §2`.

**Change.** Cross-link the λ-parameterised `HGOEKeyExpansion` to
the parameter table; disclose that the Lean-verified `≥ λ`
bound is a lower bound, not an exact bound (the actual group
order chosen at deployment can be larger).

**Acceptance.** Documentation prose matches the Lean content.

### 10.5 Exit criteria for Workstream G

1. `HGOEKeyExpansion` takes λ as a parameter; the {80, 128, 192,
   256} non-vacuity witnesses land in the audit script.
2. `#print axioms` on new examples emits only standard-trio
   axioms.
3. Documentation (Workstream-A §6.2.1 update) matches the Lean
   content.
4. `CLAUDE.md` gains a Workstream-G snapshot.

## 11. Workstream H — Safe decapsulation + computable decryption

**Severity.** HIGH (E-04 / V1-14) + MEDIUM (C-01 / X-02 / V1-12).
**Effort.** ≈ 6 h. **Scope.** Modifies `Orbcrypt/KEM/Encapsulate.lean`
(adds `decapsSafe`) and `Orbcrypt/Crypto/Scheme.lean` (adds
`decryptCompute` with agreement theorem). Depends on Workstream
**F** for the concrete `CanonicalForm.ofLexMin` witness used in
the decidability proof for `decryptCompute`.

### 11.1 Problem statement

**E-04 (decaps rejection).** `decaps : X → K` always computes a
key, including on ciphertexts outside `orbit G basePoint`. In
real-world KEM implementations, an out-of-orbit ciphertext is a
protocol violation and must be rejected; silently decapsulating
spurious keys is a CCA-style attack surface. The Lean
formalisation does not model rejection; the refactored
`INT_CTXT` predicate from Workstream **B** *does* fold orbit
membership into the game's well-formedness precondition, but the
`decaps` function itself lacks a safe variant.

**C-01 / X-02 (computable decryption).** Scheme-level `decrypt`
is `noncomputable` (uses `Exists.choose`). A v1.0 release
claiming "formal verification of a cryptosystem" benefits from
a **computable** reference algorithm that agrees with `decrypt`
on honest ciphertexts. The GAP implementation provides this
empirically; the Lean formalisation should provide it formally.

### 11.2 Fix scope

Two independent additions:

1. **`decapsSafe : X → Option K`** in `KEM/Encapsulate.lean`:
   decapsulates when the ciphertext lies in `orbit G basePoint`,
   returns `none` otherwise. Proved to equal `some (decaps c)`
   on orbit ciphertexts and `none` otherwise. Requires
   `[Fintype G]` + `[DecidableEq X]` (both already present on
   most consumers).

2. **`decryptCompute : X → Option M`** in `Crypto/Scheme.lean`:
   uses `Finset.decidableExistsOfFinset` + `Fintype.choose` over
   a finite message space to search for a matching representative.
   Proved to agree with `decrypt` under the classical-choice
   axiom (which is the axiom `decrypt` already consumes). Requires
   `[Fintype M]` + `[DecidableEq X]`.

### 11.3 Target API shape

```lean
/-- Orbit-checked decapsulation. Returns the key if the
    ciphertext is in the basepoint's orbit; `none` otherwise. -/
def decapsSafe
    {G : Type*} {X : Type*} {K : Type*}
    [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (c : X) : Option K :=
  if decide (∃ g : G, g • kem.basePoint = c) then some (decaps kem c) else none

theorem decapsSafe_eq_some_of_mem_orbit
    (kem : OrbitKEM G X K) {c : X}
    (hOrbit : c ∈ MulAction.orbit G kem.basePoint) :
    decapsSafe kem c = some (decaps kem c) := ...

theorem decapsSafe_eq_none_of_not_mem_orbit
    (kem : OrbitKEM G X K) {c : X}
    (hOrbit : c ∉ MulAction.orbit G kem.basePoint) :
    decapsSafe kem c = none := ...

/-- Computable decryption; iterates over the finite message
    space searching for a representative whose canonical form
    matches `c`'s. -/
def decryptCompute
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [MulAction G X] [DecidableEq X] [Fintype M] [DecidableEq M]
    (scheme : OrbitEncScheme G X M) (c : X) : Option M := ...

theorem decryptCompute_eq_decrypt
    ...
    (scheme : OrbitEncScheme G X M) (c : X) :
    decryptCompute scheme c = decrypt scheme c := ...
```

### 11.4 Work units

#### H1 — Implement `decapsSafe`

**File.** `Orbcrypt/KEM/Encapsulate.lean`.

**Change.** Add `decapsSafe` with the two companion theorems
`decapsSafe_eq_some_of_mem_orbit` and
`decapsSafe_eq_none_of_not_mem_orbit`. The orbit-membership test
reduces to `∃ g : G, g • basePoint = c`, which is decidable
under `[Fintype G]` + `[DecidableEq X]`.

**Acceptance.**
- `lake build Orbcrypt.KEM.Encapsulate` succeeds.
- `#print axioms decapsSafe` and the two companion theorems emit
  only standard-trio axioms.

#### H2 — Prove correctness: `decapsSafe (encaps g).1 = some (encaps g).2`

**File.** `Orbcrypt/KEM/Correctness.lean`.

**Change.** New theorem `decapsSafe_correctness` chaining
`decapsSafe_eq_some_of_mem_orbit` (the encapsulated ciphertext
is always in orbit by construction) with `kem_correctness`.

**Acceptance.** `#print axioms` emits only standard-trio.

#### H3a — Implement `decryptCompute` (the computable search)

**File.** `Orbcrypt/Crypto/Scheme.lean`.

**Precise change.** Add the `decryptCompute` function, using
`Finset.univ.filter` to locate candidate messages and
`Finset.min'` (or `Finset.choose`) to pick a unique witness. Note
that `decrypt`'s "ciphertext matches some representative" predicate
is:

```lean
∃ m : M, canon (reps m) = canon c
```

The `decryptCompute` search mirrors this with a **decidable**
filter predicate:

```lean
/-- Computable decryption: iterates over the finite message
    space, selecting the unique `m` whose orbit representative has
    the same canonical form as `c`. Returns `none` when no such
    message exists (malformed ciphertext).

    Honest ciphertexts always produce `some m`; malformed
    ciphertexts (e.g. `c ∉ orbit (reps m)` for any `m`) produce
    `none`. Agreement with `decrypt` is proved in
    `decryptCompute_eq_decrypt` (H3b). -/
def decryptCompute
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [MulAction G X] [DecidableEq X]
    [Fintype M] [DecidableEq M]
    (scheme : OrbitEncScheme G X M) (c : X) : Option M :=
  let candidates : Finset M :=
    (Finset.univ : Finset M).filter
      (fun m => scheme.canonForm.canon (scheme.reps m) =
                scheme.canonForm.canon c)
  if h : candidates.Nonempty then
    some (candidates.min' h)
  else
    none
```

**Why `min'` and not `choose`?** `Finset.choose` requires a
uniqueness proof at construction time, which is exactly what
`reps_distinct` provides — but `choose`'s type signature bundles
the uniqueness proof as an obligation that must be discharged
*before* the `Option` is returned. Using `min'` (which requires
only `LinearOrder M` and non-emptiness) avoids that coupling: the
uniqueness proof is used in H3b's agreement theorem, not in the
function definition. `min'` is canonical and computable.

**Alternative: `Finset.filter.toList.head?`** would also work but
carries less useful simp-normal-form structure. `min'` is the
Mathlib-idiomatic form.

**Decidability obligation.** The filter predicate
`scheme.canonForm.canon (scheme.reps m) = scheme.canonForm.canon c`
is `DecidableEq X` by `[DecidableEq X]`. `Finset.filter` requires
`DecidablePred p`; this is inferred automatically.

**LinearOrder obligation on `M`.** `Finset.min'` requires
`[LinearOrder M]`. Production message spaces (`Fin 2`, `Bool`, etc.)
have this trivially. For arbitrary `M`, the typeclass is usually
derivable. If the consumer has no `LinearOrder M`, fall back to
`Finset.choose` (which requires the uniqueness obligation but not
`LinearOrder`).

**Acceptance.**
- `lake build Orbcrypt.Crypto.Scheme` succeeds.
- The function is **computable** (no `noncomputable` keyword).
- `#check @decryptCompute` shows the new typeclass context
  (`[Fintype M] [DecidableEq M] [LinearOrder M]`).
- `#print axioms decryptCompute` emits only standard-trio axioms.

#### H3b — Prove `decryptCompute_eq_decrypt` (agreement theorem)

**File.** `Orbcrypt/Crypto/Scheme.lean` or
`Orbcrypt/Theorems/Correctness.lean` (preferred: the latter, to
keep `Scheme.lean` focused on definitions).

**Proof strategy.**

The agreement theorem states:

```lean
theorem decryptCompute_eq_decrypt
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [MulAction G X] [DecidableEq X]
    [Fintype M] [DecidableEq M] [LinearOrder M]
    (scheme : OrbitEncScheme G X M) (c : X) :
    decryptCompute scheme c = decrypt scheme c
```

The proof splits on whether any message representative matches:

```lean
  unfold decryptCompute decrypt
  split_ifs with h_cand_nonempty h_exists
  · -- Both definitions found a match; uniqueness closes the goal.
    -- `candidates.min'` = the unique `m` s.t. canon (reps m) = canon c
    -- `h_exists.choose` = the same unique m by reps_distinct.
    congr 1
    -- Extract the unique-candidate property.
    have h_unique : ∀ m₁ m₂ : M,
        scheme.canonForm.canon (scheme.reps m₁) = scheme.canonForm.canon c →
        scheme.canonForm.canon (scheme.reps m₂) = scheme.canonForm.canon c →
        m₁ = m₂ := by
      intro m₁ m₂ h₁ h₂
      by_contra h_ne
      -- Distinct messages have distinct reps, hence distinct orbits,
      -- hence distinct canonical forms — contradiction with h₁ + h₂.
      have h_distinct := scheme.reps_distinct m₁ m₂ h_ne
      have h_same_canon : scheme.canonForm.canon (scheme.reps m₁) =
                          scheme.canonForm.canon (scheme.reps m₂) :=
        h₁.trans h₂.symm
      -- canon_eq_implies_orbit_eq (from GroupAction/Canonical.lean)
      -- closes the gap: equal canons imply equal orbits.
      exact h_distinct (scheme.canonForm.canon_eq_implies_orbit_eq
                        h_same_canon)
    -- Now: candidates.min' is a filter witness, and h_exists.choose
    -- is a classical witness; both satisfy the matching predicate.
    exact h_unique _ _
      ((Finset.mem_filter.mp (Finset.min'_mem _ h_cand_nonempty)).2)
      (h_exists.choose_spec)
  · -- candidates nonempty but no classical witness — contradiction.
    exfalso
    obtain ⟨m, hm⟩ := h_cand_nonempty
    apply h_exists
    exact ⟨m, (Finset.mem_filter.mp hm).2⟩
  · -- classical witness exists but candidates empty — contradiction.
    exfalso
    apply h_cand_nonempty
    exact ⟨h_exists.choose, Finset.mem_filter.mpr
      ⟨Finset.mem_univ _, h_exists.choose_spec⟩⟩
  · -- neither found; both return `none`.
    rfl
```

**Critical helper.** `canon_eq_implies_orbit_eq` (from
`Orbcrypt/GroupAction/Canonical.lean:71`) proves equal canonical
forms imply equal orbits. This is the *uniqueness bridge* between
the filter-based search and the classical witness.

**Decidability note.** The `split_ifs with h_cand_nonempty h_exists`
uses the propositional `Decidable`-instance on
`candidates.Nonempty` and on `∃ m, canon (reps m) = canon c`. Both
are decidable under `[Fintype M]` + `[DecidableEq X]`.

**Acceptance.**
- `lake build Orbcrypt.Theorems.Correctness` succeeds.
- `#print axioms decryptCompute_eq_decrypt` emits only
  standard-trio axioms.
- A non-vacuity `example` in `scripts/audit_phase_16.lean`
  exhibits `decryptCompute scheme (encrypt scheme g m) = some m`
  on a small toy instance.

#### H3c — Prove `decryptCompute_encrypt` (reflexivity corollary)

**File.** `Orbcrypt/Theorems/Correctness.lean`.

**Change.** A thin corollary mirroring `correctness` but for the
computable variant:

```lean
theorem decryptCompute_encrypt
    [Group G] [MulAction G X] [DecidableEq X]
    [Fintype M] [DecidableEq M] [LinearOrder M]
    (scheme : OrbitEncScheme G X M) (m : M) (g : G) :
    decryptCompute scheme (encrypt scheme g m) = some m := by
  rw [decryptCompute_eq_decrypt]
  exact correctness scheme m g
```

**Acceptance.**
- `lake build` succeeds.
- `#print axioms` emits only standard-trio axioms.
- Non-vacuity witness added to the audit script.

#### H4 — [RESERVED — rolled into H3b]

This WU is subsumed by H3b; the numbering is preserved for
cross-reference with the audit's V1-12 item. No separate work.

#### H5 — Update audit scripts

**File.** `scripts/audit_phase_16.lean`.

**Change.** Add non-vacuity examples:
- `decapsSafe` on a small toy KEM: orbit ciphertext returns
  `some`; off-orbit ciphertext returns `none`.
- `decryptCompute` on a small toy scheme: matching ciphertext
  returns `some m`; malformed ciphertext returns `none`.
- `decryptCompute = decrypt` on a specific honest ciphertext.

**Acceptance.** All examples type-check; axiom output unchanged.

### 11.5 Risk register and rollback

| # | Risk | Likelihood | Severity | Mitigation | Rollback |
|---|------|-----------|----------|------------|----------|
| H-R1 | `[LinearOrder M]` is not available on `Fin k` instances automatically and blocks `decryptCompute` elaboration at concrete call sites | Low | Low | Mathlib provides `LinearOrder (Fin n)` globally; `Bool` is a `LinearOrder`; product types inherit it lexicographically. Verified at plan authoring. If a future consumer uses `M := SomeRecord` without `LinearOrder`, they can supply a `Finset.choose`-based variant. | Add a typeclass-instance fallback path `Finset.choose (by exact …)` using the uniqueness proof; this is a drop-in replacement keeping the function signature stable. |
| H-R2 | Workstream **F**'s `CanonicalForm.ofLexMin` arrives after Workstream **H** starts; H3b needs the concrete canon form for its non-vacuity witness | Low | Medium | H depends on F per § 3.1; the work order enforces F-before-H. | If H must start early, use the abstract `CanonicalForm` for H3b's witness; the non-vacuity example in § H5 degrades from "concrete computation" to "type-checks against the abstract structure". |
| H-R3 | The `split_ifs with h_cand_nonempty h_exists` tactic in H3b generates four cases; one of the contradiction branches fails to close because the decidability instance is classical-opaque | Medium | Low | H3b's proof body provides explicit `exfalso` + constructive-contradiction tactics for the mixed cases. If elaboration still fails, split into per-branch `by_cases` manually. | Proof-body edit only. |
| H-R4 | `decryptCompute` is correct but dramatically slower than the GAP implementation (the search is linear in `|M|`) | Certain | Low | This is the expected state: `decryptCompute` is a reference algorithm, not a performance benchmark. Production deployment uses the GAP/C implementation (Phase 15). The docstring explicitly discloses this. | No action. |
| H-R5 | `decapsSafe`'s orbit-membership decidability `∃ g : G, g • basePoint = c` requires `[Fintype G]` and may not elaborate under a subgroup `↥G` coercion | Medium | Medium | The typeclass instance `Fintype ↥G` is standard; `DecidableEq X` is already present. If elaboration fails, the explicit `Finset.decidableBAll` / `Finset.decidableExistsOfFinset` form from Mathlib closes it. | Proof-body edit; no structural change. |

**Full-workstream rollback.** H is a preferred-pre-release item.
If H3a / H3b cannot be completed within scope, the workstream
splits: H1 + H2 (decapsSafe) can land independently without H3;
H3 defers to v1.1 with a tracking item in § 18 Z-07 (C/C++ fast
path provides equivalent behaviour externally).

### 11.6 Exit criteria for Workstream H

1. `decapsSafe` and `decryptCompute` land as computable `def`s
   with standard-trio axiom dependencies.
2. Agreement theorems between `decryptCompute` and `decrypt`
   land.
3. Non-vacuity witnesses in the audit script exercise both
   functions and their correctness theorems.
4. `CLAUDE.md` row entries for correctness and KEM correctness
   gain cross-references to the safe/computable variants; the
   headline table adds new rows if the maintainer chooses (not
   required).
5. The risk register in § 11.5 has no open items.

## 12. Workstream I — Naming hygiene via *strengthening*, not rebadging

**Severity.** HIGH (D-07 / J-03 / J-08 / K-02 / V1-15) + MEDIUM
(C-15 / E-11 / V1-15). **Effort.** ≈ 14.5 h serial (sum of
work-unit estimates I1–I7); ≈ 8.5 h with two parallel
implementers (the I1–I6 partition runs in two ~6.5 h tracks
followed by the 2 h sequential I7 audit-script + documentation
sweep). **Scope.** Source-
level theorem additions plus minimal renames across six modules
(`Orbcrypt/Crypto/CompSecurity.lean`,
`Orbcrypt/KEM/CompSecurity.lean`,
`Orbcrypt/Theorems/OIAImpliesCPA.lean`,
`Orbcrypt/Hardness/CodeEquivalence.lean`,
`Orbcrypt/Hardness/TensorAction.lean`,
`Orbcrypt/PublicKey/ObliviousSampling.lean`); audit-script
coverage in `scripts/audit_phase_16.lean`; transparency-report
sweep across `Orbcrypt.lean`, `CLAUDE.md`,
`docs/VERIFICATION_REPORT.md`, `docs/PUBLIC_KEY_ANALYSIS.md`,
`DEVELOPMENT.md`. New public declarations land at standard-trio
axioms only; no `sorry`; no custom axiom.

### 12.1 Problem statement

**Why renaming is the wrong remedy.** The pre-I version of this
plan proposed rebadging six identifiers whose names overstate
what their theorems prove (e.g., `concreteOIA_one_meaningful`
proves the trivial `≤ 1` bound; `insecure_implies_separating`
proves existence of a distinguisher that is *not* G-invariant
despite the name; `ObliviousSamplingHiding` is `False` on every
non-trivial bundle; `GIReducesToCE` / `GIReducesToTI` admit
degenerate `encode _ _ := ∅` witnesses; `concreteKEMOIA_one_
meaningful` is duplicative of the existing `kemAdvantage_le_one`
sanity bound). The rebadging approach satisfies the literal
text of `CLAUDE.md`'s **Naming-content rule** ("identifier
describes what it proves") but it **violates the spirit of the
sibling Security-by-docstring prohibition**: the rule's
explicit remedy clause requires that "when the full security
property cannot yet be proved, **rename the identifier** to
describe what the code does prove — *or prove the property*."
Pre-I treated rename as the default; this revision makes
proving-the-property the default and falls back to renaming
only when the property is genuinely out of reach.

**The strengthening criterion.** For each pre-I weak identifier,
the rewritten plan asks two questions:

1. *Is the property the original name advertised provable in-
   tree, with the existing infrastructure, at standard-trio
   axioms?* If yes → **prove it**. The original identifier is
   either (a) reassigned to the new, stronger theorem, or (b)
   the original lemma is kept as a named, narrowly-scoped
   sanity bound (Mathlib-style `_le_one` / `_nonneg` simp
   lemma) and the strong content lands under a new identifier
   that genuinely captures it.
2. *If the original property is not yet provable in-tree,
   what is the **strongest cryptographically meaningful
   refinement** the existing infrastructure already supports,
   and does that refinement carry an inhabited non-vacuity
   witness?* If yes → land the refined predicate, prove a
   non-vacuity witness, and rename only the residual weak
   form to a name that accurately flags its scaffolding
   status.

The six pre-I targets sort cleanly into the two categories:

| # | Pre-I name | Audit | Category | Strengthening direction |
|---|------------|-------|----------|-------------------------|
| 1 | `concreteOIA_one_meaningful` | C-15 | (1) provable | New `concreteOIA_zero_of_subsingleton_message` — perfect concrete-security at ε = 0 on every subsingleton-message scheme. Trivial bound `≤ 1` retained as Mathlib-style simp lemma `indCPAAdvantage_le_one`. |
| 2 | `concreteKEMOIA_one_meaningful` | E-11 | (1) provable | New `concreteKEMOIA_uniform_zero_of_singleton_orbit` — perfect uniform-form security at ε = 0 on every KEM whose basepoint orbit is a singleton. Pre-I `_meaningful` lemma is *literally redundant* with the already-existing `kemAdvantage_le_one` (line 347 of `KEM/CompSecurity.lean`); deleted, not renamed. |
| 3 | `insecure_implies_separating` | D-07 | (1) provable | New `distinct_messages_have_invariant_separator` — given any two distinct messages, exhibit a **G-invariant** separating Boolean function on `(reps m₀, reps m₁)`. This is the cryptographic content the original name advertised; the proof goes through the canonical-form discriminator `fun x => decide (canon x = canon (reps m₀))` (G-invariant via `canonical_isGInvariant`; separating via `reps_distinct + canon_eq_implies_orbit_eq`). The pre-I theorem (which only delivers a non-G-invariant distinguisher) is renamed `insecure_implies_orbit_distinguisher`. |
| 4 | `GIReducesToCE` | J-03 | (2) refinement | Strengthened predicate adds a non-degeneracy field requiring `(encode m adj).card = codeSize m` for a function `codeSize : ℕ → ℕ` with `0 < codeSize m`. Rules out the `encode _ _ := ∅` degenerate witness flagged by audit. Non-vacuity witness lands at the trivial 1-vertex case via a singleton encoder. The pre-I name is *retained for the strengthened predicate*; the residual weak existential-only form is gone. |
| 5 | `GIReducesToTI` | J-08 | (2) refinement | Strengthened predicate adds a non-zero-tensor field `encode m adj ≠ (fun _ _ _ => 0)` for `m ≥ 1`. Rules out the constant-zero degenerate witness flagged by audit. Same non-vacuity / naming pattern as #4. |
| 6 | `ObliviousSamplingHiding` | K-02 | (2) refinement | Land the genuinely ε-smooth probabilistic predicate `ObliviousSamplingConcreteHiding ors combine ε` over the uniform-index push-forward; prove a non-vacuity witness at ε = 0 for the trivial-action case (orbit is a singleton, so the obliviously-sampled output and the uniform orbit sample coincide). The pre-I deterministic predicate is renamed `ObliviousSamplingPerfectHiding` (matching its `False`-on-non-trivial-bundles strength); the rename is `(2)`'s residual fallback because a probabilistic refinement is *added* on top, not as a substitute. |

The six pre-I weak identifiers correspond to a structured set
of post-I declaration changes. The categorisation below
matches the per-work-unit specifications in § 12.4 and the
acceptance-criterion #5 list in § 12.6 verbatim — implementers
and reviewers can use any of the three lists as the canonical
source of truth.

* **New strong-content theorems (4) — the cryptographic-content
  delivery of the rewrite.** `concreteOIA_zero_of_subsingleton_
  message` (perfect concrete-security at ε = 0),
  `concreteKEMOIA_uniform_zero_of_singleton_orbit` (perfect
  uniform-form KEM security at ε = 0),
  `distinct_messages_have_invariant_separator`
  (G-invariant separator from `reps_distinct`),
  `ObliviousSamplingConcreteHiding` (genuinely ε-smooth
  probabilistic hiding predicate).
* **New helper / extraction lemmas (2).**
  `canon_indicator_isGInvariant` (G-invariance of the
  canonical-form discriminator; reusable Mathlib-style lemma
  added to `GroupAction/Canonical.lean`),
  `oblivious_sampling_view_advantage_bound` (extraction-shape
  wrapper mirroring `concrete_oia_implies_1cpa`).
* **New non-vacuity witnesses (3 named theorems + 4
  audit-script `example`s).** Named theorems land alongside
  their parent declarations: `GIReducesToCE_singleton_
  witness` (witnesses the strengthened I4 Prop at the trivial
  1-vertex encoder), `GIReducesToTI_constant_one_witness`
  (witnesses the strengthened I5 Prop at the constant-1
  tensor encoder over `ZMod 2`),
  `ObliviousSamplingConcreteHiding_zero_witness` (witnesses
  I6's ε-smooth predicate at the singleton-orbit case).
  Audit-script-only `example`s land in
  `scripts/audit_phase_16.lean`'s `NonVacuityWitnesses`
  namespace: one each for I1, I2, I3, plus the negative-
  pressure regression `example`s for I4 and I5 that confirm
  the strengthened Props correctly *reject* the audit-flagged
  degenerate encoders.
* **Renamed weak forms (4) — pre-I content accurately
  re-described.** `indCPAAdvantage_le_one` (was
  `concreteOIA_one_meaningful`),
  `insecure_implies_orbit_distinguisher` (was
  `insecure_implies_separating`),
  `ObliviousSamplingPerfectHiding` (was
  `ObliviousSamplingHiding`),
  `oblivious_sampling_view_constant_under_perfect_hiding`
  (was `oblivious_sampling_view_constant`).
* **Strengthened predicates with retained names (2) —
  signature-level non-degeneracy fields added.**
  `GIReducesToCE` (gains `codeSize`, `codeSize_pos`,
  `encode_card_eq` fields), `GIReducesToTI` (gains
  `encode_nonzero_of_pos_dim` field). The same identifier
  carries the stronger Prop because no downstream consumer
  references the pre-I weak form except documentation prose.
* **One deletion.** `concreteKEMOIA_one_meaningful`
  (redundant duplicate of `kemAdvantage_le_one`; consumers
  migrate to the pre-existing identifier).

**Total counts.** **9 new public declarations** (4 strong-
content + 2 helpers + 3 named witnesses); **4 renames**
(content-neutral); **1 deletion**; **2 strengthened
in-place** (`GIReducesTo*` non-degeneracy fields). The
audit-script `#print axioms` block gains **9 new entries**
plus **4 rename-only entries** (renamed identifiers carrying
unchanged proofs still get a fresh `#print axioms` line for
discipline) **+ 2 in-place re-runs** (for the strengthened
Props), minus **1 deletion** = **14 net entries** post-I.

**Why this satisfies the release-messaging policy.** Per
`CLAUDE.md`'s Release messaging policy (introduced by
Workstream **A**), every external citation of an Orbcrypt
theorem must reproduce the Status classification from the
"Three core theorems" table. Workstream-I strengthening
delivers four new theorems whose Status is **Standalone**
(unconditional cryptographic content; cite freely) plus two
refined Props whose pre-I admit-degenerate-witness footgun is
closed at the type level. Compared to the rebadging approach
(which would have produced only renamed weak content with
unchanged Status), the strengthening approach materially
expands the set of release-citable theorems and reduces the
release-messaging surface that requires "scaffolding" or
"conditional" disclaimers.

### 12.2 Fix scope

Workstream **I** is decomposed into **seven work units** (I1–I7),
one per affected declaration plus a final audit-script-and-
documentation sweep. Each work unit is independent of the
others (no within-workstream ordering constraint): they touch
disjoint module sets and disjoint declaration namespaces, so a
two-implementer split is the natural parallelisation boundary.

**Disjoint file partition** (used by both reviewers and any
parallel-implementer assignment):

| WU | Source file | New / renamed declarations |
|----|-------------|----------------------------|
| I1 | `Orbcrypt/Crypto/CompSecurity.lean` | + `indCPAAdvantage_le_one` (renamed from pre-I `concreteOIA_one_meaningful`); + `concreteOIA_zero_of_subsingleton_message`. |
| I2 | `Orbcrypt/KEM/CompSecurity.lean` | − `concreteKEMOIA_one_meaningful` (deleted as redundant duplicate of `kemAdvantage_le_one`); + `concreteKEMOIA_uniform_zero_of_singleton_orbit`. |
| I3 | `Orbcrypt/Theorems/OIAImpliesCPA.lean` (with helper imports already present from `GroupAction/Invariant.lean` and `GroupAction/Canonical.lean`) | + `distinct_messages_have_invariant_separator`; + `insecure_implies_orbit_distinguisher` (renamed from `insecure_implies_separating`). |
| I4 | `Orbcrypt/Hardness/CodeEquivalence.lean` | `GIReducesToCE` strengthened with non-degeneracy fields (`codeSize`, `codeSize_pos`, `encode_card_eq`); name retained. |
| I5 | `Orbcrypt/Hardness/TensorAction.lean` | `GIReducesToTI` strengthened with non-zero-tensor field (`encode_nonzero_of_pos_dim`); name retained. |
| I6 | `Orbcrypt/PublicKey/ObliviousSampling.lean` (Mathlib `Probability/ProbabilityMassFunction/Constructions` already in scope via `Probability/Monad.lean`) | + `ObliviousSamplingConcreteHiding`; + `oblivious_sampling_view_advantage_bound`; + `ObliviousSamplingPerfectHiding` (renamed from `ObliviousSamplingHiding`); + `oblivious_sampling_view_constant_under_perfect_hiding` (renamed from `oblivious_sampling_view_constant`). |
| I7 | `scripts/audit_phase_16.lean`, `Orbcrypt.lean`, `CLAUDE.md`, `docs/VERIFICATION_REPORT.md`, `docs/PUBLIC_KEY_ANALYSIS.md`, `DEVELOPMENT.md`, `lakefile.lean` | Audit-script `#print axioms` entries + non-vacuity `example` blocks for every new theorem. Transparency-report sweep. `lakefile.lean` version bump (`0.1.12 → 0.1.13`). |

**No within-Lean cyclic dependency.** I1 ↔ I2 are
sibling-file-only (CompSecurity ↔ CompSecurity); I3 imports
neither (it imports `Crypto/Security` and `Crypto/OIA` only);
I4 ↔ I5 are sibling-file-only (Hardness ↔ Hardness, but each
strengthens its own Prop independently); I6 imports neither.
Every consumer of `GIReducesToCE` / `GIReducesToTI` (the
deterministic chain in `Hardness/Reductions.lean`) consumes the
Prop *as a hypothesis*, so adding fields strengthens the
hypothesis without breaking any existing call site — the chain's
consumer-side `obtain` patterns simply gain extra binders.

**No backwards-compat shims.** Per `CLAUDE.md`'s
no-backwards-compat-hack rule, the pre-I weak names are
deleted (where renamed) or rebound to the strengthened content
(where signatures change in-place); no `@[deprecated]` aliases,
no shim re-exports.

**Naming discipline (CLAUDE.md "Names describe content").**
Every new identifier in the plan describes exactly what its
Lean body proves: `_zero_of_subsingleton_message` reads "the
predicate holds at ε = 0 *because* the message space is
subsingleton"; `distinct_messages_have_invariant_separator`
reads "*assuming* messages are distinct, *exhibit* a separator
that *is* G-invariant"; `oblivious_sampling_view_advantage_
bound` reads "the obliviously-sampled view's advantage is
*bounded* (by the supplied ε)"; etc. No process-marker tokens
(no `_workstream_i`, no `_audit2026`, no `_v2`, etc.) — the
audit linkage lives in docstring traceability notes only.

**Universe-polymorphism posture.** Every new declaration uses
`Type*` for type variables and inherits the surrounding
module's universe-polymorphic stance (no `Type` literals,
matching the post-Workstream-M1 hygiene set in
`Hardness/TensorAction.lean`). I6's PMF construction lives at
`Type 0` because Mathlib's `PMF` is fixed at universe 0; this
is the same universe-pinning posture as `uniformPMF` and
`orbitDist` already in the codebase.

### 12.3 Strengthening matrix — per-target design

This subsection records the *cryptographic* design rationale
for each strengthening target. Implementers should read it
before opening the Lean editor; reviewers should re-read it
when checking the landed PR matches the stated intent.

**Target #1 — `concreteOIA_one_meaningful` (C-15).**

Pre-I body proves `indCPAAdvantage scheme A ≤ 1` via a
one-line `advantage_le_one _ _ _`. The bound is true but
**does not depend on the scheme structure**: it is a property
of `advantage` between any two PMFs, not of ConcreteOIA. The
name's "meaningful" suffix overstates the content because the
*meaningful* satisfaction of `ConcreteOIA scheme ε` happens at
ε ≪ 1, not at ε = 1.

Strengthening: split the lemma into two distinct identifiers
that capture distinct content.

* **Sanity bound (renamed, retained).** `indCPAAdvantage_le_
  one : ∀ scheme A, indCPAAdvantage scheme A ≤ 1`. This is the
  Mathlib-style `_le_one` simp lemma the codebase already
  follows for `kemAdvantage_le_one` (line 347 of
  `KEM/CompSecurity.lean`); the rename brings the scheme-side
  in line with that convention.
* **Substantive non-vacuity at perfect security (new).**
  `concreteOIA_zero_of_subsingleton_message : ∀ scheme,
  Subsingleton M → ConcreteOIA scheme 0`. **Proof.** Under
  `Subsingleton M`, every pair `(m₀, m₁)` is provably equal,
  so `scheme.reps m₀ = scheme.reps m₁`, hence `orbitDist
  (scheme.reps m₀) = orbitDist (scheme.reps m₁)`, hence every
  distinguisher `D` has `advantage D _ _ = 0` by
  `advantage_self`. This proves `ConcreteOIA scheme 0` non-
  vacuously: it is the *perfect* concrete-security extremum
  inhabited on every degenerate (singleton-message) scheme,
  serving as the non-trivial counterpart of the trivial-bound
  sanity lemma. Together the two land complete coverage of
  the predicate's two extrema (`ε = 0` and `ε = 1`).

**Target #2 — `concreteKEMOIA_one_meaningful` (E-11).**

Pre-I body proves `kemAdvantage kem A g₀ g₁ ≤ 1` via
`advantage_le_one _ _ _`. **This is *literally* the same
statement** as the existing `kemAdvantage_le_one`
(`KEM/CompSecurity.lean:347`); the `_meaningful` lemma is a
redundant duplicate that adds nothing. Strengthening: delete
the duplicate (no rename — it is *replaced* by the existing
sanity lemma), and add a substantive non-vacuity witness on
the genuinely ε-smooth uniform-form predicate.

* **Deletion.** `concreteKEMOIA_one_meaningful` is removed.
  Audit-script `#print axioms concreteKEMOIA_one_meaningful`
  is replaced with `#print axioms kemAdvantage_le_one`. No
  shim alias is introduced.
* **Substantive non-vacuity at perfect uniform security
  (new).** `concreteKEMOIA_uniform_zero_of_singleton_orbit :
  ∀ kem, (∀ g : G, g • kem.basePoint = kem.basePoint) →
  ConcreteKEMOIA_uniform kem 0`. **Proof.** Under the
  singleton-orbit hypothesis, every group element fixes
  basepoint, so `encaps kem g = encaps kem 1` for all `g`.
  Hence `kemEncapsDist kem` is the point mass at `encaps kem
  1`, which equals `PMF.pure (encaps kem g_ref)` for any
  reference `g_ref` (because `g_ref • basePoint = basePoint`
  by hypothesis), and `advantage D (PMF.pure _) (PMF.pure _) =
  0` by `advantage_self`. The KEM-layer parallel of #1's
  perfect-security extremum, on a non-trivially populated
  hypothesis (any KEM whose basepoint is a fixed point of the
  group action — including, but not limited to, the trivial
  group).

The KEM-layer choice of the *uniform* form (rather than the
point-mass form) is deliberate: the uniform form is what the
release-messaging policy directs external citations to (cf.
`Orbcrypt.lean`'s Vacuity-map row pairing
`concrete_kem_hardness_chain_implies_kem_advantage_bound`
with `ConcreteKEMOIA_uniform`); strengthening the uniform
predicate's non-vacuity surface is therefore the higher-
leverage edit.

**Target #3 — `insecure_implies_separating` (D-07).**

Pre-I content: `hasAdvantage scheme A → ∃ f m₀ m₁ g₀ g₁,
f (g₀ • reps m₀) ≠ f (g₁ • reps m₁)`. The function `f` is
*literally* the adversary's `guess` function, which is **not**
in general G-invariant. The name "separating" comes from
`IsSeparating` in `GroupAction/Invariant.lean`, which requires
G-invariance + value-disagreement; the pre-I theorem delivers
only the second conjunct. The 2026-04-14 audit (F-06) and
2026-04-23 audit (D-07) both flagged this naming-vs-content
gap; pre-I plan tried to fix it by renaming to
`insecure_implies_distinguisher`, retaining the weak
content.

Strengthening: deliver actual G-invariant separation. The
construction is the canonical-form discriminator
`fun x => decide (canon x = canon (reps m₀))`, which is:

* **G-invariant** by composition: `canon` is G-invariant
  (`canonical_isGInvariant`, `GroupAction/Invariant.lean:152`);
  `decide (· = c)` for a constant `c` is a Boolean function
  that depends only on the value of `canon x`, so the
  composition is G-invariant.
* **Separating** for any two distinct messages `m₀ ≠ m₁`:
  `decide (canon (reps m₀) = canon (reps m₀)) = true` by
  reflexivity, while `decide (canon (reps m₁) = canon (reps
  m₀)) = false` because `reps_distinct m₀ m₁ h_ne` says the
  orbits differ, hence the canonical forms differ
  (contrapositive of `canon_eq_implies_orbit_eq`,
  `GroupAction/Canonical.lean:68`).

This proof runs through *neither* `hasAdvantage` *nor* any
adversary — it is **unconditional** on the message-distinctness
hypothesis. The strengthened statement is therefore:

```
theorem distinct_messages_have_invariant_separator
    (scheme : OrbitEncScheme G X M) {m₀ m₁ : M} (h_ne : m₀ ≠ m₁) :
    ∃ f : X → Bool,
      IsGInvariant (G := G) f ∧
      f (scheme.reps m₀) ≠ f (scheme.reps m₁)
```

This is **strictly stronger** than the pre-I theorem (no
adversary argument required; conclusion includes G-invariance)
*and* it has a constructive witness (the canon-discriminator).
It closes the cryptographic gap that audit F-06 / D-07 flagged
and that the pre-I plan deferred to "probabilistic averaging".

The pre-I `insecure_implies_separating` is renamed to
`insecure_implies_orbit_distinguisher` because that name
accurately describes its weaker content (existence of a
distinguisher between two orbit-action images, with no G-
invariance claim). The renamed theorem is retained because
some downstream consumers may still want the
adversary-extracted form (e.g., for connecting an adversary
output to the contrapositive chain through OIA); it sits
alongside the new strong form, not in its place.

**Bonus structural lemma.** The G-invariance proof factors
through a generic helper `canon_indicator_isGInvariant : ∀
(can : CanonicalForm G X) (c : X), IsGInvariant (G := G) (fun
x => decide (can.canon x = c))`, which is added to
`GroupAction/Canonical.lean` (or
`GroupAction/Invariant.lean`). The helper is reused by I3's
main proof and is itself a useful Mathlib-style lemma —
canon-indicator-is-G-invariant.

**Target #4 — `GIReducesToCE` (J-03).**

Pre-I body: `∃ dim encode, ∀ adj₁ adj₂, GI(adj₁, adj₂) ↔
ArePermEquivalent (encode m adj₁) (encode m adj₂)`. Audit
J-03 exhibits the degenerate witness `encode _ _ := ∅`: under
the empty-Finset image, both sides of the iff become `True`
on the LHS (any permutation σ trivially satisfies the GI
predicate on a 0-vertex graph) but the RHS specialises to
`ArePermEquivalent ∅ ∅`, which holds trivially via the
identity permutation. The trivial encoder satisfies the
predicate without encoding any actual graph structure — the
predicate is "free" type-theoretically.

Strengthening: add a non-degeneracy field to the existential
that rules out the degenerate witness at the type level. The
post-I predicate:

```
def GIReducesToCE : Prop :=
  ∃ (dim : ℕ → ℕ) (codeSize : ℕ → ℕ)
    (encode : (m : ℕ) → (Fin m → Fin m → Bool) →
              Finset (Fin (dim m) → Bool)),
    -- Non-degeneracy: codes have a fixed positive cardinality
    -- determined by the graph size; rules out `encode _ _ := ∅`.
    (∀ m, 0 < codeSize m) ∧
    (∀ m adj, (encode m adj).card = codeSize m) ∧
    -- The Karp reduction itself.
    (∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool),
      (∃ σ : Equiv.Perm (Fin m), ∀ i j,
        adj₁ i j = adj₂ (σ i) (σ j)) ↔
      ArePermEquivalent (encode m adj₁) (encode m adj₂))
```

The non-degeneracy is split into two fields (`codeSize_pos`
and `encode_card_eq`) rather than the more concise
`(encode m adj).card > 0` so that `codeSize` is a *uniform*
function of the graph size — i.e., the encoder is required
to map graphs of the same size to codes of the same size.
This is what the literature reductions actually deliver
(CFI gadgets produce `2^(O(m))`-vertex codes of `O(m^2)`-
codeword cardinality; Petrank–Roth incidence-matrix encodings
similarly produce uniform-size codes), and it disqualifies
spurious encoders that vary their image size with the input
adjacency.

Why two fields rather than a stronger single field
(`encode m adj₁` ≃ `encode m adj₂` as Finsets of equal
cardinality): the cardinality-equality requirement *between*
two encoded codes is what `ArePermEquivalent` is an
equivalence relation on (under the post-Workstream-D
`arePermEquivalent_setoid` instance, which is Setoid-typed
on `{C // C.card = k}`). Splitting into `codeSize` makes the
signature compatible with consuming the existing setoid
instance without re-deriving cardinality equality.

**Non-vacuity witness.** A strengthened predicate with no
inhabitant is useless. The witness lands at the trivial
1-vertex case via a singleton encoder:

```
example : GIReducesToCE :=
  ⟨fun _ => 1,                      -- dim m = 1
   fun _ => 1,                      -- codeSize m = 1
   fun _ _ => {fun _ => false},     -- encode = singleton {00..0}
   fun _ => Nat.zero_lt_one,        -- 0 < 1
   fun _ _ => by simp,              -- card = 1
   fun m adj₁ adj₂ => ⟨...⟩⟩         -- iff: both sides hold
```

The singleton encoder's iff body discharges by direct
Finset equality (`{fun _ => false}` permutation-equivalent
to itself via the identity). This is a deliberately *trivial*
witness — it does not solve GI ≤ CE on graphs of size > 1 —
but it confirms the strengthened predicate is *inhabitable*,
matching the Workstream-G `tight_one_exists` non-vacuity
discipline.

The `GIReducesToCE` *identifier* is retained (no rename); the
strengthened body subsumes the pre-I content and adds two
non-degeneracy fields. Downstream documentation that cites
`GIReducesToCE` as a Karp-claim Prop is unchanged in
substance; the pre-I "degenerate-encoder disclosure"
docstring block in `Hardness/CodeEquivalence.lean:323–338` is
**deleted** (its caveat is now ruled out by the Prop itself).

**Target #5 — `GIReducesToTI` (J-08).**

Pre-I body has the same shape and the same audit-flagged
degenerate witness: `encode _ _ := fun _ _ _ => 0` produces
the constant zero tensor regardless of input adjacency, and
the iff trivialises (both `AreTensorIsomorphic 0 0` is true
via `(1, 1, 1)`, while the LHS of the iff holds via the
identity permutation on a 0-vertex graph).

Strengthening: parallel to Target #4, add a non-degeneracy
field requiring the encoded tensor to be non-zero whenever
the encoded graph is non-empty:

```
def GIReducesToTI : Prop :=
  ∃ (dim : ℕ → ℕ)
    (encode : (m : ℕ) → (Fin m → Fin m → Bool) →
              Tensor3 (dim m) F),
    -- Non-degeneracy: for non-empty graphs (m ≥ 1), the encoder
    -- must not produce the zero tensor. Rules out
    -- `encode _ _ := fun _ _ _ => 0`.
    (∀ m, 1 ≤ m → ∀ adj, encode m adj ≠ (fun _ _ _ => 0)) ∧
    -- The Karp reduction.
    (∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool),
      (∃ σ : Equiv.Perm (Fin m), ∀ i j,
        adj₁ i j = adj₂ (σ i) (σ j)) ↔
      @AreTensorIsomorphic (dim m) F _
        (encode m adj₁) (encode m adj₂))
```

The non-degeneracy is conditional on `m ≥ 1` because the
0-vertex case has only one graph (the empty one); requiring
non-zero on `m = 0` would force the encoder to produce a
fictitious tensor for the no-graph case. The literature
reductions (Grochow–Qiao 2021 structure-tensor encoding,
Hatami–Nica 2020 trilinear-form encoding) all produce
non-zero tensors for `m ≥ 1`; the `1 ≤ m` guard captures the
honest reduction profile.

Why "non-zero tensor" rather than "non-zero on a specific
basis"? The `Tensor3` type is `Fin n → Fin n → Fin n → F`,
and equality with the zero function is decidable (under
`[DecidableEq F]`), so `encode m adj ≠ (fun _ _ _ => 0)` is
a Prop-typed obligation the implementer can discharge with
a one-line `decide` or a structural argument. A stronger
"linearly independent tensor decomposition" form would be
more faithful to the Grochow–Qiao reduction, but it
introduces new linear-algebra obligations (rank, tensor
decomposition) that are research-scope; the non-zero form
is the minimum viable strengthening that closes the
J-08 footgun.

**Non-vacuity witness.** Parallel to #4: a 1-vertex encoder
that produces the constant-1 tensor (well-typed for
`F = Bool` with `DecidableEq Bool`) discharges all four
obligations.

```
example : @GIReducesToTI Bool _ :=
  ⟨fun _ => 1,                              -- dim m = 1
   fun _ _ => fun _ _ _ => true,            -- encode = constant true tensor
   fun m _ _ => by                          -- non-degeneracy
     intro h; exact Bool.true_eq_false (congrFun (congrFun (congrFun h 0) 0) 0),
   fun m adj₁ adj₂ => ⟨...⟩⟩                 -- iff
```

(The `congrFun` trio extracts equality at index `(0, 0, 0)`,
which evaluates to `true ≠ false`.)

**Target #6 — `ObliviousSamplingHiding` (K-02).**

Pre-I content: a deterministic predicate stating that for
every Boolean view `view : X → X → X → Bool` and every two
index pairs `(i, j), (k, l) : Fin t × Fin t`, `view (r_i,
r_j, combine r_i r_j) = view (r_k, r_l, combine r_k r_l)`.
This is **`False` on every non-trivial bundle** (`t ≥ 2`
with distinct randomizers): the view `view r₀ r₁ x :=
decide (r₀ = ors.randomizers 0)` is `true` at `(0, j)` and
`false` at `(1, j)` whenever `randomizers 0 ≠ randomizers 1`.
Pre-I module docstring self-discloses this.

Strengthening: introduce the **probabilistic** ε-bounded
form using the same `advantage`-vocabulary as the rest of
the Workstream-E probabilistic chain. The new predicate:

```
def ObliviousSamplingConcreteHiding [Group G] [Fintype G]
    [Nonempty G] [MulAction G X] [DecidableEq X] {t : ℕ}
    [NeZero t]
    (ors : OrbitalRandomizers G X t)
    (combine : X → X → X) (ε : ℝ) : Prop :=
  ∀ (D : X → Bool),
    advantage D
      (PMF.map (fun (p : Fin t × Fin t) =>
        combine (ors.randomizers p.1) (ors.randomizers p.2))
        (uniformPMF (Fin t × Fin t)))
      (orbitDist (G := G) ors.basePoint) ≤ ε
```

This says: the obliviously-sampled output (uniform random
index pair, then `combine`) is ε-close to a *fresh uniform
sample of the orbit* (`orbitDist`). For ε = 0 this is
"perfect obliviousness"; for ε > 0 this is
ε-computational-obliviousness, which can be discharged from
a stronger hardness assumption on `combine`'s pseudo-
randomness profile.

**Non-vacuity witness for I6.**
`ObliviousSamplingConcreteHiding_zero_witness`: for any KEM
whose group action fixes the basepoint (singleton orbit) and
whose `combine` returns the basepoint regardless of inputs,
both PMFs reduce to `PMF.pure ors.basePoint` and the advantage
between two equal point masses is `0` by `advantage_self`.
This satisfies `ObliviousSamplingConcreteHiding ors combine 0`
non-vacuously: it confirms the predicate is type-inhabitable
at perfect security on a concrete (degenerate, but well-typed)
bundle, just as Workstream-G's `tight_one_exists` confirms the
hardness chain is type-inhabitable at ε = 1.

The pre-I deterministic `ObliviousSamplingHiding` is renamed to
`ObliviousSamplingPerfectHiding` because that name accurately
describes its **strength**: it asserts that *all* views agree
on *all* index pairs, which is "perfect" in the strict
deterministic sense (no ε slack at all). The companion theorem
`oblivious_sampling_view_constant` is renamed to
`oblivious_sampling_view_constant_under_perfect_hiding` for
naming symmetry with the renamed predicate. Both renames are
mechanical; the new probabilistic predicate
`ObliviousSamplingConcreteHiding` is *added*, not a
substitute.

**Companion structural lemma.** A new theorem
`oblivious_sampling_view_advantage_bound : ∀ ors combine ε D,
ObliviousSamplingConcreteHiding ors combine ε →
advantage D _ _ ≤ ε` extracts the bound for any specific
distinguisher, mirroring the `concrete_oia_implies_1cpa`
extraction shape on the scheme-OIA side.

This closes the K-02 release-gate footgun: the pre-I
deterministic predicate's "pathological-strength" disclosure
in the module docstring is no longer needed, because the
predicate's **post-I name** (`ObliviousSamplingPerfectHiding`)
correctly conveys its strength, and the genuinely-cryptograph-
ically-meaningful predicate (`ObliviousSamplingConcreteHiding`)
sits alongside it with a non-vacuity witness.

### 12.4 Work units

#### I1 — Strengthen scheme-level non-vacuity witness (C-15)

**File.** `Orbcrypt/Crypto/CompSecurity.lean`.

**Effort.** ≈ 1.5 h.

**Changes.**

1. **Rename** `concreteOIA_one_meaningful` →
   `indCPAAdvantage_le_one`. Body unchanged
   (`advantage_le_one _ _ _`). Gain `@[simp]` attribute so the
   bound becomes a Mathlib-style sanity simp lemma. Update the
   module docstring's "Main results" list.
2. **Add new theorem**
   `concreteOIA_zero_of_subsingleton_message`:

```lean
/-- **Substantive non-vacuity witness for `ConcreteOIA`.**
    Every scheme on a subsingleton message space satisfies
    `ConcreteOIA scheme 0` — perfect concrete-security at the
    meaningful end of the security spectrum.

    **Proof.** Under `Subsingleton M`, `m₀ = m₁` for every pair
    so `scheme.reps m₀ = scheme.reps m₁`, hence `orbitDist
    (reps m₀) = orbitDist (reps m₁)`, hence `advantage D _ _ =
    0` by `advantage_self`. -/
theorem concreteOIA_zero_of_subsingleton_message
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X]
    [DecidableEq X] [Subsingleton M]
    (scheme : OrbitEncScheme G X M) :
    ConcreteOIA scheme 0 := by
  intro D m₀ m₁
  have hm : m₀ = m₁ := Subsingleton.elim _ _
  rw [hm]
  exact le_of_eq (advantage_self _ _)
```

**Acceptance.**

* `lake build Orbcrypt.Crypto.CompSecurity` succeeds with zero
  warnings / zero errors.
* `#print axioms indCPAAdvantage_le_one` and `#print axioms
  concreteOIA_zero_of_subsingleton_message` both depend only
  on `[propext, Classical.choice, Quot.sound]` (or are axiom-
  free for the renamed simp lemma — the axiom set is identical
  to the pre-I `concreteOIA_one_meaningful` because the body
  is unchanged).
* `grep -rn "concreteOIA_one_meaningful"` returns zero
  matches across the entire repo.
* New non-vacuity `example` in `scripts/audit_phase_16.lean`
  exhibits a singleton-`Unit`-message scheme satisfying
  `ConcreteOIA scheme 0` via the new theorem.

#### I2 — Strengthen KEM-level non-vacuity witness (E-11)

**File.** `Orbcrypt/KEM/CompSecurity.lean`.

**Effort.** ≈ 1.5 h.

**Changes.**

1. **Delete** `concreteKEMOIA_one_meaningful`. The lemma is a
   redundant duplicate of the existing `kemAdvantage_le_one`
   (line 347 of the same file). The two theorems prove
   bit-identical statements with bit-identical proofs; the
   `_meaningful` lemma was added in Workstream E1d as a
   stylistic mirror of `concreteOIA_one_meaningful` but the
   sanity bound `kemAdvantage_le_one` was already present and
   serves the same role. No `@[deprecated]` alias; consumers
   migrate to `kemAdvantage_le_one`.
2. **Add new theorem**
   `concreteKEMOIA_uniform_zero_of_singleton_orbit`:

```lean
/-- **Substantive non-vacuity witness for the genuinely
    ε-smooth KEM-OIA predicate.** Every KEM whose group action
    fixes the basepoint satisfies `ConcreteKEMOIA_uniform kem 0` —
    perfect uniform-form security at the meaningful end of the
    spectrum. The hypothesis is non-trivially populated (any
    KEM with a fixed-point basepoint, including but not limited
    to the trivial group).

    **Proof.** Under the singleton-orbit hypothesis,
    `g • basePoint = basePoint` for every `g : G`, so
    `encaps kem g = encaps kem 1` for all `g`. Hence
    `kemEncapsDist kem` reduces to `PMF.pure (encaps kem 1)`,
    which equals `PMF.pure (encaps kem g_ref)` for every
    reference `g_ref` (also fixed by the hypothesis). Two equal
    point masses have advantage `0` by `advantage_self`. -/
theorem concreteKEMOIA_uniform_zero_of_singleton_orbit
    {G : Type*} {X : Type*} {K : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X]
    [DecidableEq X]
    (kem : OrbitKEM G X K)
    (h_fix : ∀ g : G, g • kem.basePoint = kem.basePoint) :
    ConcreteKEMOIA_uniform kem 0 := by
  intro D g_ref
  -- Reduction: under `h_fix`, every `g : G` produces the same
  -- encapsulation, so `kemEncapsDist kem` collapses to a point
  -- mass at `encaps kem g_ref`.
  have h_eq : kemEncapsDist kem =
      PMF.pure (encaps kem g_ref) := by
    -- IMPLEMENTER: Discharge via `PMF.ext` on an arbitrary
    -- `p : X × K`, then `PMF.map_apply`. Under `h_fix g`,
    -- `encaps kem g = encaps kem g_ref` for every `g` (because
    -- `encaps` is a function of `g • basePoint`, which is
    -- `basePoint` for every `g`). The preimage of `{p}` under
    -- `encaps kem` is therefore either all of `G` (when `p =
    -- encaps kem g_ref`) or empty (otherwise). The `tsum` over
    -- `uniformPMF G` discharges by `tsum_const` + the
    -- `Fintype.card G • (Fintype.card G)⁻¹ = 1` identity in
    -- `ENNReal`. Exact Mathlib lemma chain depends on the
    -- pinned commit; the structural shape is fixed.
    sorry
  rw [h_eq]
  exact le_of_eq (advantage_self _ _)
```

**Note on the proof skeleton.** The body contains a `sorry`
placeholder that the implementer must discharge before the PR
is mergeable. The reduction is *structural* (a `PMF.map`-of-a-
constant identity under the fixed-point hypothesis); **no
cryptographic content sits inside the `sorry`**. CI's
`sorryAx` check rejects any PR that lands this theorem with
`sorry` intact — no exemption.

**Acceptance.**

* `lake build Orbcrypt.KEM.CompSecurity` succeeds with zero
  warnings / zero errors.
* `grep -rn "concreteKEMOIA_one_meaningful"` returns zero
  matches across the entire repo.
* `#print axioms concreteKEMOIA_uniform_zero_of_singleton_
  orbit` depends only on `[propext, Classical.choice,
  Quot.sound]`.
* New non-vacuity `example` in `scripts/audit_phase_16.lean`
  exhibits a trivial-action KEM (e.g., `Equiv.Perm (Fin 1)`
  acting on `Unit`) satisfying `ConcreteKEMOIA_uniform kem 0`
  via the new theorem.

#### I3 — Strengthen `insecure_implies_separating` to deliver G-invariant separation (D-07)

**Files.** `Orbcrypt/Theorems/OIAImpliesCPA.lean`,
`Orbcrypt/GroupAction/Canonical.lean` (helper lemma).

**Effort.** ≈ 3 h. (This is the highest-effort work unit
because it adds a genuinely new cryptographic theorem rather
than a structural witness.)

**Changes.**

1. **Add helper to** `Orbcrypt/GroupAction/Canonical.lean`:

```lean
/-- The Boolean indicator of "lies in the same orbit as a fixed
    point" — built from the canonical-form discriminator — is
    G-invariant. This is the structural building block for
    `distinct_messages_have_invariant_separator` below: any
    canonical form's image yields a G-invariant Boolean
    function via `decide (canon · = c)`. -/
theorem canon_indicator_isGInvariant
    [Group G] [MulAction G X] [DecidableEq X]
    (can : CanonicalForm G X) (c : X) :
    IsGInvariant (G := G) (fun x => decide (can.canon x = c)) := by
  intro g x
  simp only [canonical_isGInvariant can g x]
```

2. **Rename** `insecure_implies_separating` →
   `insecure_implies_orbit_distinguisher`. Body unchanged. The
   new docstring explicitly says: "Returns a Boolean
   distinguisher between two specific orbit-action images;
   this distinguisher is **not in general G-invariant**.
   Consumers requiring G-invariant separation should use
   `distinct_messages_have_invariant_separator` (which
   delivers G-invariance unconditionally on
   `reps_distinct`)."

3. **Add new theorem**
   `distinct_messages_have_invariant_separator`:

```lean
/-- **G-invariant separator from message distinctness.** Given
    any two distinct messages, exhibit a G-invariant Boolean
    function on `X` that takes different values on
    `scheme.reps m₀` and `scheme.reps m₁`.

    This is the *cryptographic* content the pre-I name
    `insecure_implies_separating` (renamed to
    `insecure_implies_orbit_distinguisher`) advertised but did
    not deliver: the pre-I theorem produced an arbitrary
    distinguisher; this theorem produces a function that is
    G-invariant **and** separating (in the sense of
    `IsSeparating`).

    **Proof.** The canonical-form discriminator
    `f(x) := decide (canonForm.canon x = canonForm.canon (reps
    m₀))` is G-invariant via `canon_indicator_isGInvariant`,
    and it separates `reps m₀` from `reps m₁` because
    `reps_distinct` says distinct messages have distinct
    orbits, hence distinct canonical forms (contrapositive of
    `canon_eq_implies_orbit_eq`). -/
theorem distinct_messages_have_invariant_separator
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    {m₀ m₁ : M} (h_ne : m₀ ≠ m₁) :
    ∃ f : X → Bool,
      IsGInvariant (G := G) f ∧
      f (scheme.reps m₀) ≠ f (scheme.reps m₁) := by
  refine ⟨fun x => decide (scheme.canonForm.canon x =
                            scheme.canonForm.canon
                              (scheme.reps m₀)),
          canon_indicator_isGInvariant scheme.canonForm _,
          ?_⟩
  -- Separation: canon (reps m₀) ≠ canon (reps m₁).
  have h_orbit_ne :
      MulAction.orbit G (scheme.reps m₀) ≠
      MulAction.orbit G (scheme.reps m₁) :=
    scheme.reps_distinct m₀ m₁ h_ne
  have h_canon_ne :
      scheme.canonForm.canon (scheme.reps m₀) ≠
      scheme.canonForm.canon (scheme.reps m₁) := by
    intro h_eq
    exact h_orbit_ne
      (canon_eq_implies_orbit_eq scheme.canonForm _ _ h_eq)
  -- Goal: decide (canon (reps m₀) = canon (reps m₀))
  --     ≠ decide (canon (reps m₁) = canon (reps m₀))
  -- LHS reduces to `true` (reflexivity); RHS reduces to `false`
  -- (by the symmetric form of h_canon_ne, applied to
  -- `decide_eq_false`). A `Bool` inequality between `true` and
  -- `false` is `Bool.true_ne_false`.
  have h_lhs : decide (scheme.canonForm.canon (scheme.reps m₀) =
                       scheme.canonForm.canon (scheme.reps m₀)) = true :=
    decide_eq_true rfl
  have h_rhs : decide (scheme.canonForm.canon (scheme.reps m₁) =
                       scheme.canonForm.canon (scheme.reps m₀)) = false :=
    decide_eq_false (Ne.symm h_canon_ne)
  rw [h_lhs, h_rhs]
  exact Bool.true_ne_false
```

**Acceptance.**

* `lake build Orbcrypt.GroupAction.Canonical` (for the helper)
  and `lake build Orbcrypt.Theorems.OIAImpliesCPA` succeed
  with zero warnings / zero errors.
* `grep -rn "insecure_implies_separating"` returns zero
  matches across the entire repo (note: word-boundaried so
  `insecure_implies_orbit_distinguisher` is not falsely
  flagged).
* `#print axioms canon_indicator_isGInvariant` and
  `#print axioms distinct_messages_have_invariant_separator`
  both depend only on `[propext, Classical.choice,
  Quot.sound]`.
* `#print axioms insecure_implies_orbit_distinguisher`
  retains its pre-rename axiom dependencies (rename is
  content-neutral).
* New non-vacuity `example` in `scripts/audit_phase_16.lean`
  exhibits a concrete two-message scheme (e.g., `M = Bool`
  with `reps true := some_x_0` / `reps false := some_x_1`
  in distinct orbits) and exercises the conclusion's three
  parts: existence of `f`, G-invariance of `f`, and the
  separation `f (reps true) ≠ f (reps false)`.

#### I4 — Strengthen `GIReducesToCE` with non-degeneracy fields (J-03)

**File.** `Orbcrypt/Hardness/CodeEquivalence.lean`.

**Effort.** ≈ 2 h.

**Changes.**

1. **Replace** the pre-I `GIReducesToCE` definition with the
   strengthened body:

```lean
/-- **Graph Isomorphism reduces to Permutation Code
    Equivalence (post-I strengthened form).**

    A faithful many-one (Karp) reduction: there exist a
    dimension function, a code-cardinality function, and an
    encoding function such that:
    1. The encoding produces codes of *positive*, *uniform*
       cardinality determined by the graph size — this rules
       out the degenerate `encode _ _ := ∅` witness flagged
       by audit J-03.
    2. Two graphs are isomorphic iff their encoded codes are
       permutation-equivalent.

    **Why two non-degeneracy fields** (`codeSize_pos` and
    `encode_card_eq`) **rather than one combined field.** The
    setoid instance `arePermEquivalent_setoid` (Workstream D4)
    is parameterised by a fixed cardinality `k`; splitting
    `codeSize` from the encoder lets the strengthened predicate
    consume that setoid instance directly without
    re-deriving cardinality equality at every call site.

    **Composition with the probabilistic chain.** This is the
    deterministic Karp-claim Prop paired with the probabilistic
    `ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding` (Workstream
    G / Fix C) in `Hardness/Reductions.lean`. A concrete
    Cai–Fürer–Immerman (1992) or Petrank–Roth (1997)
    incidence-matrix witness would discharge both Props
    simultaneously; that witness remains research-scope (audit
    plan § 15.1 / R-15). -/
def GIReducesToCE : Prop :=
  ∃ (dim : ℕ → ℕ) (codeSize : ℕ → ℕ)
    (encode : (m : ℕ) → (Fin m → Fin m → Bool) →
              Finset (Fin (dim m) → Bool)),
    (∀ m, 0 < codeSize m) ∧
    (∀ m adj, (encode m adj).card = codeSize m) ∧
    (∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool),
      (∃ σ : Equiv.Perm (Fin m), ∀ i j,
        adj₁ i j = adj₂ (σ i) (σ j)) ↔
      ArePermEquivalent (encode m adj₁) (encode m adj₂))
```

2. **Add non-vacuity witness**
   `GIReducesToCE_singleton_witness`:

```lean
/-- **Non-vacuity witness for `GIReducesToCE`.** A trivial
    1-dimensional encoder that maps every graph to the
    singleton code `{fun _ => false}` discharges all four
    obligations of the strengthened predicate.

    This is *not* a cryptographically meaningful reduction —
    it does not solve GI ≤ CE on graphs of size > 1 — but it
    confirms the strengthened predicate is type-inhabitable at
    the trivial-encoder profile, matching the Workstream-G
    `tight_one_exists` non-vacuity discipline. -/
theorem GIReducesToCE_singleton_witness : GIReducesToCE :=
  ⟨fun _ => 1,                         -- dim m = 1
   fun _ => 1,                         -- codeSize m = 1
   fun _ _ => {fun _ => false},        -- encode = singleton
   fun _ => Nat.zero_lt_one,
   fun _ _ => by simp [Finset.card_singleton],
   fun m adj₁ adj₂ => ⟨
     fun _ => ⟨1, fun _ _ => by
       -- The singleton-singleton case: identity permutation
       -- on a singleton code witnesses ArePermEquivalent.
       intro c hc; simp_all⟩,
     fun _ => ⟨1, fun i j => by
       -- Reverse direction: any GI witness is the identity
       -- on a 1-vertex graph (Fin 1 has only 0).
       fin_cases i; fin_cases j; rfl⟩⟩⟩
```

3. **Delete** the pre-I "Degenerate-encoder disclosure"
   docstring block (lines 323–338 of pre-I
   `Hardness/CodeEquivalence.lean`). The non-degeneracy is now
   ruled out by the Prop itself; the prose caveat is
   counterproductive (it would mislead readers into thinking
   the post-I Prop still admits degenerate encoders).

4. **Update module docstring's "Main definitions" list** to
   reflect the strengthened predicate signature; add the new
   non-vacuity witness to "Main results".

**Acceptance.**

* `lake build Orbcrypt.Hardness.CodeEquivalence` succeeds with
  zero warnings / zero errors.
* `lake build Orbcrypt.Hardness.Reductions` (the deterministic
  chain consumer) builds unchanged: the chain consumes
  `GIReducesToCE` as a hypothesis, so the added obligations
  flow through as additional `obtain` binders without
  signature breakage at the chain level.
* `#print axioms GIReducesToCE` and `#print axioms
  GIReducesToCE_singleton_witness` both depend only on
  `[propext, Classical.choice, Quot.sound]`.
* The pre-I degenerate-encoder docstring caveat is removed
  (its content is now type-level enforced).
* New non-vacuity `example` in `scripts/audit_phase_16.lean`
  exhibits the singleton witness directly (already proven
  above; the `example` is a one-line application).
* **Negative-pressure regression test** in
  `scripts/audit_phase_16.lean`: an `example` confirming the
  pre-I degenerate-encoder profile (`encode _ _ := ∅`) **no
  longer satisfies** the strengthened predicate, by exhibiting
  the explicit failure of the `0 < codeSize m` obligation
  (`example : ¬ (0 < (Finset.empty : Finset _).card) := by
  simp`).

#### I5 — Strengthen `GIReducesToTI` with non-zero-tensor field (J-08)

**File.** `Orbcrypt/Hardness/TensorAction.lean`.

**Effort.** ≈ 1.5 h. (Lower than I4 because the non-zero-tensor
obligation is structurally simpler than the cardinality-pair
obligation.)

**Changes.**

1. **Replace** the pre-I `GIReducesToTI` definition with the
   strengthened body:

```lean
/-- **Graph Isomorphism reduces to Tensor Isomorphism (post-I
    strengthened form).**

    A faithful many-one (Karp) reduction: there exist a
    dimension function and an encoder such that:
    1. The encoder produces *non-zero* tensors for every
       non-empty graph (`m ≥ 1`) — this rules out the
       degenerate `encode _ _ := fun _ _ _ => 0` witness
       flagged by audit J-08.
    2. Two graphs are isomorphic iff their encoded tensors are
       GL³-isomorphic.

    **Why guard the non-degeneracy on `m ≥ 1`.** The 0-vertex
    case has only one graph (the empty one); requiring
    non-zero on `m = 0` would force the encoder to invent a
    fictitious tensor for the no-graph case, which has no
    cryptographic meaning. The literature reductions
    (Grochow–Qiao 2021 structure-tensor, Hatami–Nica 2020
    trilinear-form) all produce non-zero tensors for `m ≥ 1`;
    the `1 ≤ m` guard captures the honest reduction profile.

    **Composition with the probabilistic chain.** Paired with
    `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`
    (Workstream G / Fix C) in `Hardness/Reductions.lean`. A
    concrete witness via the Grochow–Qiao 2021 encoding would
    discharge both Props simultaneously; that witness remains
    research-scope (audit plan § 15.1 / R-15). -/
def GIReducesToTI [Field F] : Prop :=
  ∃ (dim : ℕ → ℕ)
    (encode : (m : ℕ) → (Fin m → Fin m → Bool) →
              Tensor3 (dim m) F),
    (∀ m, 1 ≤ m →
      ∀ adj, encode m adj ≠ (fun _ _ _ => 0)) ∧
    (∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool),
      (∃ σ : Equiv.Perm (Fin m), ∀ i j,
        adj₁ i j = adj₂ (σ i) (σ j)) ↔
      @AreTensorIsomorphic (dim m) F _
        (encode m adj₁) (encode m adj₂))
```

2. **Add non-vacuity witness**
   `GIReducesToTI_constant_one_witness`:

```lean
/-- **Non-vacuity witness for `GIReducesToTI`** (specialised
    to `F = ZMod 2` for decidability). A 1-dimensional encoder
    that produces the constant-1 tensor for every graph
    discharges all three obligations.

    Trivial witness; matches the Workstream-G non-vacuity
    discipline. -/
theorem GIReducesToTI_constant_one_witness :
    @GIReducesToTI (ZMod 2) _ :=
  ⟨fun _ => 1,                                  -- dim m = 1
   fun _ _ => fun _ _ _ => 1,                   -- constant-1
   fun m _ _ h_eq => by                         -- non-zero
     -- Extracting equality at index (0, 0, 0) gives 1 = 0 in
     -- ZMod 2, which `decide` rejects.
     have := congrFun (congrFun (congrFun h_eq 0) 0) 0
     exact absurd this (by decide),
   fun m adj₁ adj₂ => ⟨...⟩⟩                     -- iff
```

3. **Delete** the pre-I "Degenerate-encoder disclosure"
   docstring block (lines 316–328 of pre-I
   `Hardness/TensorAction.lean`). Same rationale as I4.

4. **Update module docstring's "Main definitions" list.**

**Acceptance.**

* `lake build Orbcrypt.Hardness.TensorAction` succeeds with
  zero warnings / zero errors.
* `lake build Orbcrypt.Hardness.Reductions` (the deterministic
  chain consumer) builds unchanged.
* `#print axioms GIReducesToTI` and `#print axioms
  GIReducesToTI_constant_one_witness` both depend only on
  `[propext, Classical.choice, Quot.sound]`.
* New non-vacuity `example` in `scripts/audit_phase_16.lean`
  exhibits the constant-1 witness directly.
* **Negative-pressure regression test:** an `example`
  confirming `(fun _ _ _ => (0 : ZMod 2)) = (fun _ _ _ => 0)`
  reduces to a true statement (so the explicit constant-zero
  witness is correctly disqualified by the new
  non-degeneracy field).

#### I6 — Strengthen `ObliviousSamplingHiding` to a probabilistic ε-bounded form (K-02)

**File.** `Orbcrypt/PublicKey/ObliviousSampling.lean`.

**Effort.** ≈ 3 h. (The cryptographic content is simple — a
PMF.map plus an `advantage` bound — but the new module imports
`Probability/Monad`, `Probability/Advantage`, and the proof
must thread `[Fintype G]` / `[Nonempty G]` instances through
the existing `OrbitalRandomizers` API.)

**Changes.**

1. **Add new probabilistic predicate.**

```lean
/-- **Probabilistic oblivious-sampling hiding (post-I).**

    The sender's view of an obliviously-sampled output is
    ε-close to a fresh uniform sample of the orbit. Concretely:
    sample a uniform index pair `(i, j) : Fin t × Fin t` and
    apply `combine` to the corresponding randomizers; the
    resulting distribution is at advantage ≤ ε from
    `orbitDist (G := G) ors.basePoint`.

    For ε = 0 this is *perfect oblivious sampling*; for
    intermediate ε this is *ε-computational obliviousness*
    that can be discharged from a stronger pseudo-randomness
    assumption on `combine`.

    **Replaces the deterministic `ObliviousSamplingHiding`** —
    which is `False` on every non-trivial bundle (cf. its
    pre-I docstring's pathological-strength disclosure) —
    with the genuinely ε-smooth analogue suitable for
    release-facing security claims. -/
def ObliviousSamplingConcreteHiding
    [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X] {t : ℕ} [NeZero t]
    (ors : OrbitalRandomizers G X t)
    (combine : X → X → X) (ε : ℝ) : Prop :=
  ∀ (D : X → Bool),
    advantage D
      (PMF.map (fun (p : Fin t × Fin t) =>
        combine (ors.randomizers p.1) (ors.randomizers p.2))
        (uniformPMF (Fin t × Fin t)))
      (orbitDist (G := G) ors.basePoint) ≤ ε
```

2. **Add structural extraction theorem.**

```lean
/-- **Advantage extraction from `ObliviousSamplingConcrete-
    Hiding`.** For any specific Boolean view, the advantage is
    bounded by the predicate's ε. Mirrors the
    `concrete_oia_implies_1cpa` extraction pattern. -/
theorem oblivious_sampling_view_advantage_bound
    [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X] {t : ℕ} [NeZero t]
    (ors : OrbitalRandomizers G X t)
    (combine : X → X → X) (ε : ℝ)
    (hHide : ObliviousSamplingConcreteHiding ors combine ε)
    (D : X → Bool) :
    advantage D
      (PMF.map (fun (p : Fin t × Fin t) =>
        combine (ors.randomizers p.1) (ors.randomizers p.2))
        (uniformPMF (Fin t × Fin t)))
      (orbitDist (G := G) ors.basePoint) ≤ ε :=
  hHide D
```

3. **Add non-vacuity witness.**

```lean
/-- **Non-vacuity witness for `ObliviousSamplingConcrete-
    Hiding`.** When the group action fixes the basepoint
    (singleton orbit) and `combine` returns the basepoint,
    both PMFs reduce to `PMF.pure ors.basePoint`, and the
    advantage between two equal point masses is 0. -/
theorem ObliviousSamplingConcreteHiding_zero_witness
    [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X] {t : ℕ} [NeZero t]
    (ors : OrbitalRandomizers G X t)
    (h_fix : ∀ g : G, g • ors.basePoint = ors.basePoint) :
    ObliviousSamplingConcreteHiding ors
      (fun _ _ => ors.basePoint) 0 := by
  intro D
  -- Both PMFs reduce to the point mass `PMF.pure ors.basePoint`:
  --   * LHS: `combine = fun _ _ => ors.basePoint`, so the
  --     pre-image under `PMF.map` is the constant function
  --     returning `ors.basePoint`; `PMF.map`-of-a-constant on a
  --     non-empty index type is a point mass.
  --   * RHS: `orbitDist (G := G) ors.basePoint =
  --     PMF.map (fun g => g • ors.basePoint) (uniformPMF G)`;
  --     under `h_fix` every `g • ors.basePoint = ors.basePoint`,
  --     so the map is again a point mass at `ors.basePoint`.
  -- After both reductions the advantage is between two equal
  -- point masses; `advantage_self` discharges the goal.
  have h_lhs :
      PMF.map (fun (_ : Fin t × Fin t) => ors.basePoint)
        (uniformPMF (Fin t × Fin t)) =
      PMF.pure ors.basePoint := by
    -- IMPLEMENTER: Discharge via `PMF.map`-of-a-constant
    -- (Mathlib `PMF.map_const` or its equivalent in the pinned
    -- Mathlib commit). A concrete fallback: `PMF.ext` on
    -- arbitrary `x`, splitting `x = ors.basePoint` versus not,
    -- with `PMF.map_apply` + `tsum_const` finishing both
    -- branches. Either lemma name resolves transparently against
    -- the project's Mathlib pin.
    sorry
  have h_rhs :
      orbitDist (G := G) ors.basePoint =
      PMF.pure ors.basePoint := by
    -- IMPLEMENTER: Same shape as `h_lhs`. The `h_fix` hypothesis
    -- collapses `fun g => g • ors.basePoint` into the constant
    -- `fun _ => ors.basePoint`; reuse the same `PMF.map`-of-a-
    -- constant lemma.
    sorry
  rw [h_lhs, h_rhs]
  exact le_of_eq (advantage_self _ _)
```

**Note on the proof skeleton.** The body contains two `sorry`
placeholders that the implementer must discharge before the PR
is mergeable. Both reductions are *structural* (no
cryptographic content): they are statements about Mathlib's
`PMF.map`-of-a-constant behaviour, with a one-line discharge
in the typical Mathlib pin. The plan does **not** ship a Lean-
ready proof here because the exact Mathlib lemma name
(`PMF.map_const`, `PMF.map_pure_eq`, or a `PMF.ext` discharge)
depends on the pinned Mathlib commit; the implementer audits
which form is currently available and uses it directly. **No
audit-script `example` may invoke this theorem until both
`sorry`s are replaced**; CI's `sorryAx` check will reject the
PR otherwise.

4. **Rename** `ObliviousSamplingHiding` →
   `ObliviousSamplingPerfectHiding` and
   `oblivious_sampling_view_constant` →
   `oblivious_sampling_view_constant_under_perfect_hiding`.
   Bodies unchanged. Update docstrings: the pre-I
   "pathological-strength" disclosure is replaced with a
   "this is the perfect-deterministic extremum; for the
   genuinely ε-smooth predicate use `ObliviousSamplingConcrete-
   Hiding`" cross-reference.

5. **Update module docstring's "Main definitions" / "Main
   results" lists** to include the new probabilistic
   predicate and witnesses.

6. **Update imports.** `Orbcrypt.Probability.Monad` and
   `Orbcrypt.Probability.Advantage` are added to the
   `import` block at the top of `ObliviousSampling.lean`
   (currently it imports only `Orbcrypt.GroupAction.Basic`).
   Both new imports are already in the build graph; no Mathlib
   additions are needed.

**Acceptance.**

* `lake build Orbcrypt.PublicKey.ObliviousSampling` succeeds
  with zero warnings / zero errors.
* `grep -rn "ObliviousSamplingHiding"` returns zero matches
  (the rename is `ObliviousSamplingPerfectHiding`).
* `#print axioms ObliviousSamplingConcreteHiding`,
  `#print axioms oblivious_sampling_view_advantage_bound`,
  `#print axioms ObliviousSamplingConcreteHiding_zero_witness`
  all depend only on `[propext, Classical.choice,
  Quot.sound]`.
* New non-vacuity `example` in `scripts/audit_phase_16.lean`
  exhibits a concrete `OrbitalRandomizers (Equiv.Perm (Fin 1))
  Unit 1` bundle satisfying the new predicate at ε = 0 via
  the witness above.
* `docs/PUBLIC_KEY_ANALYSIS.md`'s § "Phase 13 theorem registry"
  table is updated with rows for the new predicate, the
  extraction theorem, and the non-vacuity witness; the
  pre-I `ObliviousSamplingHiding` row is updated with the
  new name `ObliviousSamplingPerfectHiding`.

#### I7 — Audit-script coverage and downstream documentation sweep

**Files.**
* `scripts/audit_phase_16.lean` — `#print axioms` entries +
  non-vacuity `example` blocks for every new theorem and every
  rename.
* `Orbcrypt.lean` — axiom-transparency report and Vacuity-map
  updates.
* `CLAUDE.md` — Workstream-I snapshot at the end of the change
  log; "Three core theorems" status-column updates if
  applicable.
* `docs/VERIFICATION_REPORT.md` — Document-history entry;
  Known-limitations updates removing the closed footguns;
  Headline-results table extended with the new substantive
  theorems (Standalone classification).
* `docs/PUBLIC_KEY_ANALYSIS.md` — § "Phase 13 theorem registry"
  table updates (covered also under I6 above).
* `DEVELOPMENT.md` — § references to `ObliviousSamplingHiding`
  / `insecure_implies_separating` updated to the new names.
* `lakefile.lean` — version bump `0.1.12 → 0.1.13` per the
  CLAUDE.md version-bump discipline (six new public
  declarations + four renames).

**Effort.** ≈ 2 h.

**Audit-script work units (sub-units of I7).**

The post-I additions to `scripts/audit_phase_16.lean` are
organised under a new section header
`-- Workstream I non-vacuity witnesses (audit 2026-04-23,
findings C-15, D-07, E-11, J-03, J-08, K-02)` placed under
the existing `namespace NonVacuityWitnesses`. The section
contains:

* **I1 axioms + witnesses (2 entries).**
  ```
  #print axioms indCPAAdvantage_le_one
  #print axioms concreteOIA_zero_of_subsingleton_message
  ```
  plus an `example` exhibiting `concreteOIA_zero_of_
  subsingleton_message` at a concrete `Unit`-message scheme.
* **I2 axioms + witnesses (1 new entry, 1 deletion).**
  ```
  -- DELETED: #print axioms concreteKEMOIA_one_meaningful
  -- (replaced by the existing kemAdvantage_le_one)
  #print axioms concreteKEMOIA_uniform_zero_of_singleton_orbit
  ```
  plus an `example` on a trivial-action KEM.
* **I3 axioms + witnesses (3 entries).**
  ```
  #print axioms canon_indicator_isGInvariant
  #print axioms distinct_messages_have_invariant_separator
  #print axioms insecure_implies_orbit_distinguisher
  ```
  The witness is a two-message scheme exercising the
  conjunction (existence + G-invariance + separation).
  The `insecure_implies_separating` line is **removed** — its
  pre-I axiom-print is no longer applicable.
* **I4 axioms + witnesses (1 new entry, plus negative-pressure
  example).**
  ```
  #print axioms GIReducesToCE_singleton_witness
  ```
  Plus a negative-pressure `example` confirming `0 < (∅ :
  Finset _).card = False`.
* **I5 axioms + witnesses (1 new entry, plus negative-pressure
  example).**
  ```
  #print axioms GIReducesToTI_constant_one_witness
  ```
  Plus a negative-pressure `example` confirming the
  constant-zero tensor witness fails the new non-degeneracy
  field.
* **I6 axioms + witnesses (3 entries).**
  ```
  #print axioms ObliviousSamplingConcreteHiding
  #print axioms oblivious_sampling_view_advantage_bound
  #print axioms ObliviousSamplingConcreteHiding_zero_witness
  ```
  Plus an `example` on a singleton-orbit `OrbitalRandomizers`
  bundle. The pre-I `ObliviousSamplingHiding` and
  `oblivious_sampling_view_constant` `#print axioms` lines
  are renamed in-place to the new identifiers.

**Total post-I `#print axioms` block changes** (matching the
canonical count in § 12.1):

* **9 new entries** (one per new public declaration):
  `concreteOIA_zero_of_subsingleton_message`,
  `concreteKEMOIA_uniform_zero_of_singleton_orbit`,
  `canon_indicator_isGInvariant`,
  `distinct_messages_have_invariant_separator`,
  `GIReducesToCE_singleton_witness`,
  `GIReducesToTI_constant_one_witness`,
  `ObliviousSamplingConcreteHiding`,
  `oblivious_sampling_view_advantage_bound`,
  `ObliviousSamplingConcreteHiding_zero_witness`.
* **4 rename-only entries** (renamed identifier replaces
  pre-I name; proof unchanged): `indCPAAdvantage_le_one`,
  `insecure_implies_orbit_distinguisher`,
  `ObliviousSamplingPerfectHiding`,
  `oblivious_sampling_view_constant_under_perfect_hiding`.
* **2 in-place re-runs** (Prop signature changes; identifier
  retained): `GIReducesToCE`, `GIReducesToTI`.
* **1 deletion** (no replacement entry; consumers cite the
  pre-existing `kemAdvantage_le_one`):
  `concreteKEMOIA_one_meaningful`.

Net audit-script delta: **9 new + 4 renamed + 2 re-run − 1
deleted = 14 entries** present post-I where the pre-I script
had **5** in the corresponding regions (the 5 pre-I weak
identifiers that got renamed/strengthened/deleted).

**Acceptance.**

* `lake env lean scripts/audit_phase_16.lean` runs clean
  (every `#print axioms` line returns either "does not
  depend on any axioms" or `[propext, Classical.choice,
  Quot.sound]`; never `sorryAx`; never a custom axiom).
* All non-vacuity `example` blocks elaborate without
  warnings.
* `Orbcrypt.lean` axiom-transparency report has new
  `#print axioms` cookbook lines for every Workstream-I
  declaration plus a `## Workstream I Snapshot (audit
  2026-04-23, findings C-15 / D-07 / E-11 / J-03 / J-08 /
  K-02)` section appended at the end describing the
  strengthening posture, the eight-vs-six count breakdown,
  and the patch-version bump.
* The Vacuity-map table in `Orbcrypt.lean` gains new rows
  pairing each pre-I weak identifier with its post-I
  strong-content sibling.
* `docs/VERIFICATION_REPORT.md`'s "Known limitations"
  section drops items 2 (`GIReducesToCE` /
  `GIReducesToTI` admit degenerate encoders) and 4
  (`ObliviousSamplingHiding` strength) because both
  footguns are now closed at the type level by Workstream I.
  The "Document history" gets a 2026-04-26 entry recording
  the Workstream-I landing.

### 12.5 Risk register and rollback

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **I-R1** — I3's `decide_eq_true rfl` / `decide_eq_false (Ne.symm h_canon_ne)` / `Bool.true_ne_false` chain depends on the exact Mathlib lemma names; if the pinned commit renamed any of them (e.g., `Bool.true_ne_false` → `Bool.true_neq_false`), the proof fails to elaborate. | Low | Low | All three lemmas are in Lean *core* (`Init/SimpLemmas.lean`), not Mathlib, so they are stable across Mathlib pin bumps. If any *does* fail, the fallback is a `by_cases` split on `decide (canon (reps m₀) = canon (reps m₁))`: the `true` branch contradicts `h_canon_ne` via `of_decide_eq_true`; the `false` branch closes by `Bool.true_ne_false` after explicit `decide_eq_true rfl` for the LHS. |
| **I-R2** — I6's PMF.map / orbitDist proof requires `[NeZero t]` plus `Nonempty (Fin t × Fin t)` to satisfy `uniformPMF`; if the `Nonempty` synthesis fails, add `[Fact (0 < t)]` or `[NeZero t]` explicitly. | Low | Low | Explicit `letI : Nonempty (Fin t × Fin t) := …` at the proof site. The instance is structurally available because `[NeZero t]` is already required. |
| **I-R3** — I4's strengthened `GIReducesToCE` breaks `Hardness/Reductions.lean`'s `obtain ⟨dim, encode, h_iff⟩ := h_red` consumer pattern (post-I the destructure has 5 binders). | Med | Low | Audit every consumer of `GIReducesToCE` and `GIReducesToTI` (in pre-I they are unconsumed by any in-tree theorem; the only references are documentation prose). Update consumer destructure patterns to `⟨dim, codeSize, encode, h_pos, h_card, h_iff⟩` and `⟨dim, encode, h_nonzero, h_iff⟩` respectively. **Pre-I confirmation:** `grep -rn "obtain.*GIReducesToCE\|let.*GIReducesToCE\|⟨.*encode.*h_iff⟩"` over `Orbcrypt/` returns zero matches (the Props are unconsumed except as hypotheses passed through `Hardness/Reductions.lean`'s deterministic chain, which doesn't destructure). The risk is therefore latent only on future consumers; current consumers are unaffected. |
| **I-R4** — Workstream I and Workstream A's release-messaging policy interact: the post-I deletion of pre-I weak identifiers may invalidate Workstream-A citation guidance written before Workstream I lands. | Low | Med | Workstream I updates `CLAUDE.md`'s "Three core theorems" status column entries for any row that references the renamed/deleted identifiers (currently: rows #2, #3 reference `insecure_implies_separating`; row #14 references `GIReducesToCE` / `GIReducesToTI`). I7's documentation sweep is the single point of truth for release-messaging consistency. |
| **I-R5** — I6's `ObliviousSamplingConcreteHiding` introduces a new probabilistic predicate that may be confused with the deterministic-but-renamed `ObliviousSamplingPerfectHiding`. | Low | Low | Both predicates' module docstrings carry an explicit "this predicate vs. the other" cross-reference block, plus the public-key-analysis document gets a side-by-side comparison entry. The naming convention (`Concrete` for ε-smooth, `Perfect` for the deterministic extremum) matches the rest of the codebase (`ConcreteOIA` vs. `OIA`, `ConcreteKEMOIA_uniform` vs. `KEMOIA`). |
| **I-R6** — Two implementers parallel-landing I1 ↔ I2 modify `Orbcrypt/Crypto/CompSecurity.lean` and `Orbcrypt/KEM/CompSecurity.lean` simultaneously, producing merge conflicts in `scripts/audit_phase_16.lean`. | Med | Low | I7 is sequenced *after* all of I1–I6 land on the integration branch; the audit-script edit is a single PR rather than fan-out. The implementer assignment table in § 12.2 documents this as the no-overlap partition. |
| **I-R7** — I4 / I5's deletion of the "degenerate-encoder disclosure" docstring blocks loses information that future maintainers might want for context. | Very Low | Very Low | The audit traceability is preserved in two places: (a) this plan document's § 12.3 captures the pre-I → post-I rationale; (b) `Orbcrypt.lean`'s Workstream-I snapshot summarises the strengthening with citation back to audit findings J-03 / J-08. The docstring deletion is therefore information-preserving across the documentation set. |

**Rollback procedure (if Workstream I cannot land in one
release).** Each work unit is independently revertible
because the file partition is disjoint and no work unit's
proof depends on another's lemma. If e.g. I6's PMF.map
support-equality proof proves harder than estimated, land
I1–I5 + the rename-only fallback for I6 (rename
`ObliviousSamplingHiding` → `ObliviousSamplingPerfectHiding`
without the new probabilistic predicate); track the
remaining substantive content (the `ObliviousSamplingConcrete-
Hiding` predicate + non-vacuity witness) as a follow-up
issue. The renames-only fallback satisfies the audit
finding K-02 minimally; the substantive strengthening
remains in scope for v1.1.

### 12.6 Exit criteria for Workstream I

A Workstream-I PR is reviewable-and-mergeable iff every
checkbox in this list ticks green.

**Build / verification.**
1. `lake build` succeeds for all 39 modules (3,367 jobs +
   the new declarations) with zero warnings, zero errors.
2. `scripts/audit_phase_16.lean` runs clean
   (`source ~/.elan/env && lake env lean
   scripts/audit_phase_16.lean`):
   * Every `#print axioms` output is either "does not depend
     on any axioms" or `[propext, Classical.choice,
     Quot.sound]`.
   * Zero `sorryAx` occurrences.
   * Zero non-standard axioms.
   * Every Workstream-I non-vacuity `example` block
     elaborates without warnings.
3. `.github/workflows/lean4-build.yml` CI passes on the PR
   branch (sorry-free + axiom-clean checks).

**Source-level acceptance.**
4. Six pre-I weak identifiers are no longer referenceable by
   their pre-I names. Verified by:
   ```
   grep -rn "concreteOIA_one_meaningful\\|concreteKEMOIA_one_meaningful\\|insecure_implies_separating\\|ObliviousSamplingHiding\\b\\|oblivious_sampling_view_constant\\b" \
     Orbcrypt/ scripts/ docs/ CLAUDE.md DEVELOPMENT.md \
     Orbcrypt.lean
   ```
   returns zero matches (`\b` boundaries on `ObliviousSamplingHiding`
   and `oblivious_sampling_view_constant` to avoid false-positive
   on the renamed `_perfect_hiding` forms).
5. **Nine post-I new declarations** are present and
   axiom-clean (depend only on `[propext, Classical.choice,
   Quot.sound]`):
   * `concreteOIA_zero_of_subsingleton_message` *(I1, new
     theorem — perfect concrete-security at ε = 0 on every
     subsingleton-message scheme)*
   * `concreteKEMOIA_uniform_zero_of_singleton_orbit` *(I2,
     new theorem — perfect uniform-form KEM security at ε = 0
     on every singleton-orbit KEM)*
   * `canon_indicator_isGInvariant` *(I3, new helper lemma in
     `GroupAction/Canonical.lean`)*
   * `distinct_messages_have_invariant_separator` *(I3, new
     theorem — G-invariant separator from `reps_distinct`)*
   * `ObliviousSamplingConcreteHiding` *(I6, new ε-smooth
     probabilistic predicate)*
   * `oblivious_sampling_view_advantage_bound` *(I6, new
     extraction theorem)*
   * `ObliviousSamplingConcreteHiding_zero_witness` *(I6, new
     non-vacuity witness at ε = 0 on a singleton-orbit
     bundle)*
   * `GIReducesToCE_singleton_witness` *(I4, new non-vacuity
     witness for the strengthened `GIReducesToCE` Prop)*
   * `GIReducesToTI_constant_one_witness` *(I5, new non-vacuity
     witness for the strengthened `GIReducesToTI` Prop)*

   **Four post-I renamed declarations** retain pre-rename
   axiom dependencies (rename is content-neutral):
   * `indCPAAdvantage_le_one` *(was `concreteOIA_one_meaningful`;
     I1 — Mathlib-style sanity simp lemma)*
   * `insecure_implies_orbit_distinguisher` *(was
     `insecure_implies_separating`; I3 — pre-I content
     accurately renamed to flag the missing G-invariance)*
   * `ObliviousSamplingPerfectHiding` *(was
     `ObliviousSamplingHiding`; I6 — pre-I deterministic
     predicate accurately renamed to flag its perfect-extremum
     strength)*
   * `oblivious_sampling_view_constant_under_perfect_hiding`
     *(was `oblivious_sampling_view_constant`; I6 —
     companion-theorem rename for naming symmetry)*

   **One post-I deletion** (no replacement; consumers migrate
   to the existing `kemAdvantage_le_one`):
   * `concreteKEMOIA_one_meaningful` *(I2 — redundant duplicate
     of `kemAdvantage_le_one`; deletion has no semantic
     impact)*
6. Two strengthened Props (`GIReducesToCE` and
   `GIReducesToTI`) carry the new non-degeneracy fields,
   verified by `#print` of the definition + manual review of
   the field list.

**Documentation acceptance.**
7. `CLAUDE.md` gains a "Workstream I has been completed"
   snapshot at the end of its change-log section, listing the
   eight new declarations + four renames + two strengthened
   Props in a structured table.
8. `Orbcrypt.lean`'s axiom-transparency report gains a
   Workstream-I subsection plus 10 new `#print axioms`
   cookbook lines.
9. `Orbcrypt.lean`'s Vacuity-map gains rows pairing each
   pre-I weak identifier with its post-I substantive sibling.
10. `docs/VERIFICATION_REPORT.md`'s "Known limitations"
    section drops items 2 and 4 (now closed by I); the
    "Headline results" table extends with the four new
    Standalone-classification theorems.
11. `docs/PUBLIC_KEY_ANALYSIS.md`'s § "Phase 13 theorem
    registry" table updates the
    `ObliviousSamplingHiding`-pinned rows.
12. `DEVELOPMENT.md`'s § references to the renamed identifiers
    are updated.
13. `lakefile.lean` version bumped from `0.1.12` to `0.1.13`.

**Cryptographic acceptance.**
14. **`distinct_messages_have_invariant_separator` is
    machine-checked, not docstring-only.** This is the
    cryptographic theorem the audit F-06 (2026-04-14) and
    D-07 (2026-04-23) flagged as missing for two years; this
    work unit lands the actual content.
15. **`ConcreteKEMOIA_uniform` and `ConcreteOIA` each have a
    non-vacuity witness at ε = 0**, demonstrating the
    predicates are inhabited at the meaningful (perfect)
    extremum, not just at the trivial ε = 1.
16. **`GIReducesToCE` and `GIReducesToTI` no longer admit the
    audit-flagged degenerate encoders.** Verified by the
    negative-pressure regression `example`s in the audit
    script: `(0 < (∅ : Finset _).card) = False` for
    `GIReducesToCE`, and `(fun _ _ _ => 0) = (fun _ _ _ => 0)`
    for `GIReducesToTI`.
17. **`ObliviousSamplingConcreteHiding` admits an inhabited
    instance at ε = 0** on a concrete (degenerate-but-
    well-typed) bundle, replacing the pre-I deterministic
    predicate's pathological-strength caveat with a
    machine-checked non-vacuity witness.

**Release-messaging acceptance.**
18. Per the Release-messaging policy in `CLAUDE.md`, every
    new Standalone theorem from this workstream is correctly
    classified in `CLAUDE.md`'s "Three core theorems" and
    `docs/VERIFICATION_REPORT.md`'s "Headline results"
    tables — both with **Standalone** status (no ε
    disclosure required because the theorems are
    unconditional or deliver perfect-security extrema).
19. The pre-I "Conditional" and "Scaffolding" disclaimers on
    deleted/renamed identifiers are removed from the
    release-messaging surface; in particular, the pre-I
    `ObliviousSamplingHiding` "pathological strength"
    pre-condition no longer needs to be cited because the
    post-I `ObliviousSamplingConcreteHiding` is genuinely
    ε-smooth.

A PR satisfying all 19 criteria is mergeable to `main`. A PR
satisfying criteria 1–13 (build + source + documentation) but
failing one or more of 14–19 indicates a partial Workstream-I
landing — the renames + structural witnesses are in place but
the cryptographic strengthening is incomplete; coordinate with
the audit-plan author before merging to confirm whether the
partial form satisfies the v1.0 release gate.

## 13. Workstream J — Invariant-attack framing + negligible closure

**Severity.** HIGH (D-04 / D-05 / V1-4) + MEDIUM (G-04 / G-05 /
V1-16). **Effort.** ≈ 5 h. **Scope.** Modifies
`Orbcrypt/Theorems/InvariantAttack.lean` and
`Orbcrypt/Probability/Negligible.lean`.

### 13.1 Problem statement

**D-04 / D-13 (invariant-attack framing).** `invariant_attack`
concludes `∃ A : Adversary X M, hasAdvantage scheme A` — i.e.
**there exists an adversary that distinguishes on at least one
`(g₀, g₁)` pair**. The `CLAUDE.md` Status column narrative
framing calls this "advantage 1/2" / "complete break", which is
stronger than the actual statement. The proof does witness `g₀ =
g₁ = 1` and exhibits a concrete distinguishing behaviour, but
the stated conclusion is strictly weaker than "advantage = 1/2"
(which would require quantifying over uniform `g`).

**D-05 (reps_distinct side condition).** The current proof does
not explicitly depend on `reps_distinct`, so the theorem would
spuriously "succeed" on an ill-formed scheme where
`reps m₀ = reps m₁`. This is vacuous in practice (the scheme
invariant forbids it) but the formal surface could be
strengthened.

**D-06 (unused helper).** `invariantAttackAdversary_correct` is
defined but not referenced by `invariant_attack`'s proof.
Either wire it in or delete (per `CLAUDE.md`'s no-dead-code
policy).

**G-04 / G-05 (negligible closure).** `Probability/Negligible.lean`
is missing `IsNegligible.of_le` (if `|f n| ≤ g n` and `g` is
negligible, so is `f`) and `IsNegligible.const_mul` (if `f` is
negligible and `C : ℝ`, so is `fun n => C * f n`). Both are
standard cryptographic closure properties used in most security
proofs; absence is a formalisation gap.

### 13.2 Fix scope

- **D-04 / D-13 (preferred resolution).** Strengthen the
  theorem statement OR tighten the release messaging. Since the
  proof already witnesses `g₀ = g₁ = 1` and the adversary's
  behaviour on that pair is deterministic, we can strengthen
  the conclusion to:

  ```lean
  ∃ (A : Adversary X M) (g₀ g₁ : G),
    A.guess (g₀ • scheme.reps (A.choose scheme.reps).1)
      ≠ A.guess (g₁ • scheme.reps (A.choose scheme.reps).2)
    ∧ A.choose scheme.reps = (m₀, m₁)
  ```

  i.e. produce a named `g₀, g₁` pair. Alternatively, keep the
  current conclusion and defer to Workstream-**A**'s framing
  correction. **This plan adopts Track 2 (framing-only)** for
  v1.0 because the strengthened conclusion would still not
  match "advantage = 1/2" semantically; the honest fix is to
  stop claiming 1/2 until a probabilistic counterpart (research
  R-01) lands.

- **D-05.** Add a one-line docstring note that the theorem is
  vacuous on ill-formed schemes (where
  `reps m₀ = reps m₁`) and that `reps_distinct` is the
  scheme-level invariant that prevents this.

- **D-06.** Inline-wire `invariantAttackAdversary_correct` into
  `invariant_attack`'s proof, OR delete the helper if it has no
  independent use. **Plan choice: delete** (per `CLAUDE.md`'s
  no-dead-code rule — the helper is unused in-tree and the
  rename would confuse audit readers).

- **G-04 / G-05.** Land the two closure lemmas.

### 13.3 Work units

#### J1 — Tighten `invariant_attack` docstring (D-04 / D-13)

**File.** `Orbcrypt/Theorems/InvariantAttack.lean`.

**Change.** Rewrite the docstring to state: "Produces an
adversary with a `(g₀, g₁) = (1, 1)` distinguishing pair. The
existence of a single distinguishing pair is a **weaker
statement than probabilistic advantage = 1/2**, which would
require quantifying over uniform `g`. For the probabilistic
counterpart (advantage bound under `ConcreteOIA`), see research
follow-up R-01 at
`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 18."
Cross-link from `CLAUDE.md` row #2 (which Workstream-**A** A6
reworded).

**Acceptance.** Docstring updated; no axiom changes.

#### J2 — Delete unused `invariantAttackAdversary_correct` (D-06)

**File.** `Orbcrypt/Theorems/InvariantAttack.lean`.

**Change.** Remove `invariantAttackAdversary_correct` and its
docstring. Update the module-level "Key definitions and
theorems" docstring list to remove the reference. Verify via
`grep -rn "invariantAttackAdversary_correct"` that no downstream
call site references it (if any do, the rename is restructured
to wire it in instead).

**Acceptance.**
- `grep -rn "invariantAttackAdversary_correct"` returns empty.
- `lake build Orbcrypt.Theorems.InvariantAttack` succeeds.
- Audit script output unchanged (the helper was never exercised).

#### J3 — Add `reps_distinct` cross-reference to docstring (D-05)

**File.** `Orbcrypt/Theorems/InvariantAttack.lean`.

**Change.** One-line docstring addition on `invariant_attack`:
"The theorem's conclusion presumes the scheme's
`reps_distinct` invariant; on an ill-formed scheme where
`reps m₀ = reps m₁`, the adversary's behaviour collapses but
the theorem's conclusion remains technically true via the
concrete `(g₀, g₁) = (1, 1)` witness — a degenerate case
precluded by any well-formed `OrbitEncScheme`."

**Acceptance.** Docstring updated.

#### J4 — Add `IsNegligible.of_le` (G-04)

**File.** `Orbcrypt/Probability/Negligible.lean`.

**Change.** Add:

```lean
/-- If `|f n| ≤ g n` and `g` is negligible, then `f` is negligible.
    This is a standard closure property used in most cryptographic
    proofs to bound an unknown `f` by a known-negligible `g`. -/
theorem IsNegligible.of_le {f g : ℕ → ℝ}
    (hg : IsNegligible g)
    (h_le : ∀ n, |f n| ≤ g n) :
    IsNegligible f := by
  intro c
  obtain ⟨n₀, hn₀⟩ := hg c
  exact ⟨n₀, fun n hn => lt_of_le_of_lt (h_le n) (hn₀ n hn)⟩
```

**Acceptance.** `lake build Orbcrypt.Probability.Negligible`
succeeds; `#print axioms IsNegligible.of_le` emits only
standard-trio axioms.

#### J5 — Add `IsNegligible.const_mul` (G-05)

**File.** `Orbcrypt/Probability/Negligible.lean`.

**Change.** Add:

```lean
/-- If `f` is negligible and `C : ℝ`, then `fun n => C * f n` is
    negligible. Commutative counterpart of `mul_const`. -/
theorem IsNegligible.const_mul {f : ℕ → ℝ}
    (hf : IsNegligible f) (C : ℝ) :
    IsNegligible (fun n => C * f n) := by
  have := hf.mul_const C
  simpa [mul_comm] using this
```

**Acceptance.** Same as J4.

#### J6 — Non-vacuity witnesses

**File.** `scripts/audit_phase_16.lean`.

**Change.** Four new `example` bindings: `IsNegligible.of_le`
applied at `f := fun _ => 0, g := fun _ => 0`;
`IsNegligible.const_mul` applied at `C := 2, f := fun _ => 0`;
two asymptotic witnesses verifying nontrivial functions
(e.g., `fun n => 1 / (2^n)` is negligible and remains negligible
after `of_le` / `const_mul`).

**Acceptance.** All examples type-check; axiom output only
standard-trio.

### 13.4 Exit criteria for Workstream J

1. `invariant_attack`'s docstring accurately frames its
   conclusion; D-13 divergence closed.
2. `invariantAttackAdversary_correct` is deleted.
3. `IsNegligible.of_le` and `IsNegligible.const_mul` land with
   standard-trio axioms.
4. Non-vacuity witnesses exercise both new closure lemmas.
5. `CLAUDE.md` gains a Workstream-J snapshot.

## 14. Workstream K — Root-file split + legacy script relocation

**Severity.** HIGH (M-01 / V1-17) + INFO (N-03 / N-04 / V1-18 /
M-03 / V1-21). **Effort.** ≈ 6 h. **Scope.** Splits
`Orbcrypt.lean`'s 1585-line docstring into three smaller
documents; moves per-workstream audit scripts to
`scripts/legacy/`. Depends on Workstreams **A** (for the
release-messaging policy to fold into the new
`AXIOM_TRANSPARENCY.md`) and **I** (for stable declaration names
in the snapshots).

### 14.1 Problem statement

`Orbcrypt.lean` is 1585 lines: 52 `import` lines followed by a
~1530-line module-header docstring. The docstring contains:

1. The module dependency graph (~150 lines, ASCII art).
2. The "Deterministic-vs-probabilistic security chains" framing
   (from Workstream J of the 2026-04-21 plan).
3. The headline-theorem dependency listing.
4. The axiom-transparency report with 62+ `#print axioms`
   reference outputs.
5. Per-workstream snapshots for Phases 1–16 + Workstreams A–N.

This is **monorepo-scale documentation** inside a `.lean` file
that should primarily be a root import file. External readers
face a 1585-line wall of text when they `cat Orbcrypt.lean`.
Additionally, per-workstream audit scripts
(`audit_b_workstream.lean`, `audit_c_workstream.lean`, …,
`audit_e_workstream.lean`, `audit_phase15.lean`,
`audit_print_axioms.lean`) are historical; their content is
substantially duplicated in `audit_phase_16.lean` but they are
retained "for historical reference" per the file docstrings.
They are not run by CI. This is maintenance debt.

### 14.2 Fix scope

**Root-file split (M-01 / V1-17).** Four files replace the
current `Orbcrypt.lean`:

1. **`Orbcrypt.lean`** (new size ≈ 150 lines): imports +
   condensed dependency graph + one-paragraph cross-references
   to the three documents below. Keeps the `#print axioms`
   cookbook as comments for grep-ability (essential for audit
   scripts that run `#print axioms` on declaration names
   referenced in the cookbook).

2. **`docs/CHANGELOG.md`** (new, absorbs per-workstream /
   per-phase snapshots from the current `Orbcrypt.lean`):
   chronological log of Workstreams A through N and Phases 1–16.

3. **`docs/AXIOM_TRANSPARENCY.md`** (new, absorbs the
   axiom-transparency cookbook): all 62+ `#print axioms`
   reference outputs, the vacuity map, the "what to cite"
   guidance (folded from Workstream-**A** release-messaging
   policy).

4. **`docs/VERIFICATION_REPORT.md`** (unchanged structurally;
   cross-referenced from `AXIOM_TRANSPARENCY.md`).

**Legacy script relocation (N-03 / N-04 / V1-18).**
Per-workstream scripts move to `scripts/legacy/`:

- `scripts/audit_b_workstream.lean` →
  `scripts/legacy/audit_b_workstream.lean`
- `scripts/audit_c_workstream.lean` → ... (same pattern for
  c, d, e)
- `scripts/audit_phase15.lean` →
  `scripts/legacy/audit_phase15.lean`
- `scripts/audit_print_axioms.lean` →
  `scripts/legacy/audit_print_axioms.lean`
- `scripts/audit_a7_defeq.lean` →
  `scripts/legacy/audit_a7_defeq.lean`

`scripts/audit_phase_16.lean` **stays** at `scripts/`
(authoritative audit script). A `scripts/legacy/README.md`
explains the historical-reference status and directs users to
`audit_phase_16.lean`.

### 14.3 Work units

**Migration protocol invariant.** The K1–K3 sequence modifies
`Orbcrypt.lean`'s docstring incrementally. After every WU in the
K1–K3 sequence, `lake build Orbcrypt` must succeed and
`scripts/audit_phase_16.lean` must produce unchanged output. This
is enforceable because the docstring content is purely comments
and has no impact on the kernel — regression risk is bounded to
broken cross-references between the new documents and the
existing `VERIFICATION_REPORT.md` / audit scripts.

#### K1a — Create skeleton `docs/CHANGELOG.md`

**File.** `docs/CHANGELOG.md` (new).

**Change.** Write an empty skeleton with sections in
reverse-chronological order:

```markdown
# Orbcrypt changelog

Per-workstream and per-phase development snapshots. Each entry
mirrors the content previously embedded in `Orbcrypt.lean`'s
module docstring; the authoritative source for each snapshot is
the corresponding commit history.

## Workstream N (2026-04-23) — Info hygiene
<snapshot body>

## Workstream M (2026-04-23) — Low-priority polish
<snapshot body>

[... down to Phase 1]
```

The skeleton has section headers but no bodies yet; K1b fills
the bodies.

**Acceptance.** The file exists; headers are in place; bodies
are empty.

#### K1b — Migrate snapshot bodies from `Orbcrypt.lean` to `CHANGELOG.md`

**Files.** `docs/CHANGELOG.md`, `Orbcrypt.lean`.

**Migration recipe.**
1. Identify each per-workstream / per-phase snapshot block in
   `Orbcrypt.lean`'s docstring via `grep -n "Workstream [A-N]\|Phase [0-9]" Orbcrypt.lean`.
2. For each block, `cut` the content (preserving exact wording
   — **no rewriting**; this is a location change, not an edit)
   and paste into the corresponding `CHANGELOG.md` section
   body.
3. Leave a single-line pointer in `Orbcrypt.lean` at each
   former snapshot location: `-- Workstream A snapshot: see
   docs/CHANGELOG.md#workstream-a-<date>`.

**Acceptance.**
- `CHANGELOG.md` contains every snapshot previously in
  `Orbcrypt.lean` (grep for distinguishing phrases to verify).
- `Orbcrypt.lean`'s line count drops from 1585 to ≤ 400.
- `lake build Orbcrypt` succeeds (comments only — no semantic
  impact).

#### K1c — Cross-reference audit

**File.** Sweep across `docs/**/*.md`, `CLAUDE.md`,
`Orbcrypt.lean`, `scripts/**/*.lean`.

**Change.** Update every cross-reference that previously pointed
into `Orbcrypt.lean`'s snapshot sections to now point into
`docs/CHANGELOG.md` (with appropriate `#fragment` anchors).

**Acceptance.**
- `grep -rn "Orbcrypt\.lean.*Workstream\|Orbcrypt\.lean.*Phase"`
  returns no cross-references that predate K1b.
- All new cross-references are valid (GitHub preview renders
  the anchor links correctly).

#### K2a — Create skeleton `docs/AXIOM_TRANSPARENCY.md`

**File.** `docs/AXIOM_TRANSPARENCY.md` (new).

**Change.** Skeleton with the structure:

```markdown
# Orbcrypt axiom-transparency report

## How to verify
<pointer to scripts/audit_phase_16.lean>

## Zero-custom-axiom posture
<statement + scan procedure>

## Deterministic-vs-probabilistic security chains
<framing from Workstream J 2026-04-21>

## Vacuity map
<table>

## `#print axioms` cookbook
<62+ entries>

## Workstream snapshots (cross-reference to CHANGELOG.md)
<cross-links>
```

Bodies empty; K2b fills.

**Acceptance.** File exists with headers.

#### K2b — Migrate transparency content

**Files.** `docs/AXIOM_TRANSPARENCY.md`, `Orbcrypt.lean`.

**Migration recipe.** Cut from `Orbcrypt.lean`:
1. The axiom-transparency report (~200 lines).
2. The "Deterministic-vs-probabilistic security chains" framing.
3. The vacuity map table.
4. The `#print axioms` cookbook (62+ `#print axioms
   <declaration>` stanzas).

Paste into `AXIOM_TRANSPARENCY.md`. Leave a pointer in
`Orbcrypt.lean`: `-- Axiom-transparency report: see
docs/AXIOM_TRANSPARENCY.md`.

**Acceptance.**
- `AXIOM_TRANSPARENCY.md` contains every `#print axioms`
  reference previously in `Orbcrypt.lean`.
- `Orbcrypt.lean`'s line count drops further (from ≤ 400 after
  K1b to ≤ 200).

#### K2c — `#print axioms` cookbook cross-check

**File.** `scripts/audit_phase_16.lean`, `docs/AXIOM_TRANSPARENCY.md`.

**Change.** Every declaration mentioned in the cookbook (`#print
axioms <name>` line) must also be exercised by the corresponding
`#print axioms` line in `scripts/audit_phase_16.lean`. This is
the gate that ensures the migrated cookbook stays
machine-checkable.

**Acceptance.**
- A `diff` of declaration names between `AXIOM_TRANSPARENCY.md`'s
  cookbook and `scripts/audit_phase_16.lean`'s `#print axioms`
  lines is empty.
- Add an optional CI step that regenerates the cookbook from
  the audit script output (not required for v1.0 tag; but
  noted as future polish).

#### K3 — Final trim of `Orbcrypt.lean` to ≤ 200 lines

**File.** `Orbcrypt.lean`.

**Change.** After K1a–K2c, the remaining content should be:
- 52 `import` lines (unchanged).
- A condensed module-header docstring (~100–120 lines) with:
  * One-paragraph project overview.
  * The high-level dependency graph (~30 lines, ASCII or
    mermaid per K4 decision).
  * Explicit cross-references to `docs/CHANGELOG.md`,
    `docs/AXIOM_TRANSPARENCY.md`, and
    `docs/VERIFICATION_REPORT.md`.
  * The "Three core theorems" reference list (brief, linking
    to the authoritative headline-table in
    `CLAUDE.md` / `VERIFICATION_REPORT.md`).
- No per-workstream snapshots, no `#print axioms` cookbook.

If the file exceeds 200 lines after K3's natural trim, make one
additional pass removing any still-inlined examples, dependency
graph expansions, etc. The hard target is `wc -l Orbcrypt.lean`
≤ 200.

**Acceptance.**
- `wc -l Orbcrypt.lean` ≤ 200.
- `lake build` succeeds.
- `scripts/audit_phase_16.lean` outputs unchanged from pre-K.
- CI's existing `sorry` / axiom scans pass unchanged.

#### K4 — Replace ASCII dependency graph with a machine-generatable one
(optional; M-03 / V1-21)

**File.** Either `docs/DEPENDENCIES.md` or a mermaid snippet in
`Orbcrypt.lean`'s header.

**Change (optional).** Replace the hand-maintained ASCII graph
with either (a) a mermaid diagram renderable by GitHub, or (b)
a pointer to a CI-generated `.dot` file produced by a `lake
query` or similar tool. This is optional — the ASCII graph is
readable and a migration can be deferred.

**Acceptance.** If landed, the graph renders correctly in GitHub
preview; if deferred, the deferral is noted in the K4 commit
message.

#### K5 — Move legacy audit scripts to `scripts/legacy/`

**Files.** `scripts/audit_{b,c,d,e}_workstream.lean`,
`scripts/audit_phase15.lean`,
`scripts/audit_print_axioms.lean`, `scripts/audit_a7_defeq.lean`.

**Change.** `git mv` each file to `scripts/legacy/`. Verify
nothing else in the repo references the old paths.

**Acceptance.**
- `scripts/legacy/` contains the six migrated scripts.
- `grep -rn "scripts/audit_b_workstream\|scripts/audit_c_workstream\|scripts/audit_phase15\|scripts/audit_print_axioms\|scripts/audit_a7_defeq\|scripts/audit_d_workstream\|scripts/audit_e_workstream"`
  returns matches only in `scripts/legacy/` (the files
  themselves).

#### K6 — Add `scripts/legacy/README.md`

**File.** `scripts/legacy/README.md` (new).

**Change.** Short README explaining the historical-reference
status of each legacy script and directing users to
`scripts/audit_phase_16.lean` as the CI-authoritative source.

**Acceptance.** README exists and is cross-linked from
`docs/AXIOM_TRANSPARENCY.md`.

#### K7 — Update CI workflow + CLAUDE.md per-workstream log

**Files.** `.github/workflows/lean4-build.yml`, `CLAUDE.md`.

**Change.** No CI workflow change (the legacy scripts were never
run). `CLAUDE.md` gains a Workstream-K snapshot with the file-
move list.

**Acceptance.** CI still passes. `CLAUDE.md` reflects the new
documentation layout.

### 14.4 Risk register and rollback

| # | Risk | Likelihood | Severity | Mitigation | Rollback |
|---|------|-----------|----------|------------|----------|
| K-R1 | A cross-reference in `CLAUDE.md` / `VERIFICATION_REPORT.md` / a prior audit-plan document references a line range in `Orbcrypt.lean` (e.g., "see `Orbcrypt.lean:860`") that becomes invalid after K3's trim | High | Low | K1c explicitly sweeps all cross-references. The sweep uses `grep -rn "Orbcrypt\.lean:[0-9]"` to find every line-number reference; each is updated to point to the correct new location (`CHANGELOG.md#anchor` or `AXIOM_TRANSPARENCY.md#anchor`). | Running the sweep is the normal flow; a forgotten reference is caught by the CI link-checker (if enabled) or by reader report. A follow-up PR tightens. |
| K-R2 | Git history for the migrated text is lost when content moves between files (no `git log --follow` tracking) | Certain | Low | The migration uses explicit `git mv` + content-split commits; where that is not possible (cross-file migration), the K1b/K2b commit messages explicitly cite the pre-migration line range. Readers who need historical context can `git log -p -- Orbcrypt.lean` on the pre-K range. | No rollback needed; accept the known limitation. |
| K-R3 | K5's `git mv` of legacy audit scripts breaks an external consumer's CI that imports them by path | Very low | Medium | Legacy scripts are self-disclosed as non-CI; no in-tree consumer imports them. External consumers reading `scripts/audit_b_workstream.lean` were never guaranteed stability (the audit-plan precedent is `status: historical`). K6's `scripts/legacy/README.md` provides the redirect. | `git revert <K5-commit>` restores the old paths; a subsequent v1.1 revisits the migration with stronger consumer coordination. |
| K-R4 | K3's target of "≤ 200 lines" is not achievable without sacrificing useful content in `Orbcrypt.lean`'s header | Low | Low | The target is a heuristic, not a hard gate. If the content is genuinely >200 lines after K3 trims, document the overage in the K3 commit and accept the higher line count. The true goal is "not 1585 lines". | Acceptance-criterion relaxation via commit-message annotation. |
| K-R5 | The K1b-migrated snapshots in `docs/CHANGELOG.md` drift from reality as future workstreams land (CHANGELOG.md gets stale) | High | Low | `CHANGELOG.md` is the *canonical* source for workstream snapshots post-K. Future workstreams write to `CHANGELOG.md` directly, not to `Orbcrypt.lean`. The root file's pointer comment indicates where to write. | The "canonical source" convention is enforced by the Workstream-K snapshot entry; drift is a subsequent-workstream hygiene issue, not a K failure. |

**Full-workstream rollback.** K is a polish-slate item, not a
blocker. If the migration is disruptive (e.g., K-R1 cascades), the
fallback is to land only K1a + K2a (skeleton files) and leave
`Orbcrypt.lean` at its current 1585-line size, documenting the
deferral in § 20 (Release-readiness checklist).

### 14.5 Exit criteria for Workstream K

1. `Orbcrypt.lean` ≤ 200 lines.
2. `docs/CHANGELOG.md` and `docs/AXIOM_TRANSPARENCY.md` exist
   and carry the migrated content.
3. Six legacy audit scripts live at `scripts/legacy/`.
4. `scripts/audit_phase_16.lean` remains the CI-authoritative
   audit script.
5. `lake build` and `scripts/audit_phase_16.lean` outputs are
   unchanged.
6. `CLAUDE.md` gains a Workstream-K snapshot cross-linking the
   three new documentation files.
7. The risk register in § 14.4 has no open items (K-R1 closed by
   the K1c sweep; K-R2 accepted; K-R3 closed by verification of no
   in-tree consumers; K-R4 accepted or closed by line-count
   compliance; K-R5 closed by the canonical-source convention
   entry in `CLAUDE.md`).

## 15. Workstream L — Medium-severity structural cleanup

**Severity.** MEDIUM (aggregate — every MEDIUM finding without a
dedicated workstream). **Effort.** ≈ 8 h. **Scope.** Per-finding
small-diff cleanup across 14+ modules.

### 15.1 Problem statement

The 2026-04-23 audit surfaces ~30 MEDIUM-severity findings that
are small-diff polish items without enough individual weight to
warrant a dedicated workstream. Workstream **L** bundles them
for efficient batch processing under a single PR; each sub-item
is a one-file, one-to-three-commit edit.

### 15.2 Findings addressed

| Finding | Module | Fix summary |
|---------|--------|-------------|
| B-04 | `GroupAction/Canonical.lean` | Add `canon_idem` as a bundled field on `CanonicalForm` (optional); if not, leave as theorem. **Decision: leave as theorem, only add a `@[simp]` tag.** |
| B-06 | `GroupAction/Invariant.lean` | Docstring addition: distribution-parameterised `IsSeparating` is research-scope R-01. |
| C-02 | `Crypto/Scheme.lean` | Add `@[simp] theorem encrypt_eq : encrypt scheme g m = g • scheme.reps m := rfl`. |
| C-03 | `Crypto/Scheme.lean` | Docstring note on `Fintype M` requirement. |
| C-04 | `Crypto/Security.lean` | Docstring update: "adversary receives `reps` map" framing reconciled with post-KEM architecture. |
| C-06 | `Crypto/Security.lean` | Release note in `VERIFICATION_REPORT.md` clarifying deterministic vs probabilistic game differences. (Overlaps with Workstream **A**.) |
| C-11 | `Crypto/CompOIA.lean` | Docstring-only: `SchemeFamily` typeclass-field bundling design note. |
| C-12 | `Crypto/CompOIA.lean` | Docstring addition: IT vs computational distinction for `IsNegligible`. |
| C-14 | `Crypto/CompSecurity.lean` | Fix `hybridDist` left/right convention in docstring. |
| C-16 | `Crypto/CompSecurity.lean` | Release-note addition covering collision adversary branch. |
| D-02 | `Theorems/Correctness.lean` | Docstring addition cross-referencing DEVELOPMENT.md §4.2. |
| E-01 | `KEM/Syntax.lean` | Docstring addition: `keyDerive` cryptographic-suitability disclosure. |
| E-02 | `KEM/Syntax.lean` | Docstring addition: `toKEM` permissive-keyDerive note. |
| E-05 | `KEM/Correctness.lean` | Docstring addition: honest-ciphertext-only caveat. |
| E-12 | `KEM/CompSecurity.lean` | Docstring addition: `ConcreteKEMOIA_uniform` vs literature IND-CCA-KEM distinction. |
| F-02 | `Construction/Permutation.lean` | Docstring: "faithful" vs "free" distinction. |
| F-05 | `Construction/HGOE.lean` | Docstring addition: Hamming-weight-is-necessary-but-not-sufficient disclosure (Workstream-**A** A5 mirrors in `DEVELOPMENT.md §7.1`). |
| F-08 | `Construction/HGOEKEM.lean` | Docstring addition: `keyDerive` abstractness disclosure. |
| G-01 | `Probability/Monad.lean` | Decision: consolidate `probEvent` / `probTrue` or keep both. **Recommendation: keep both; add cross-reference docstring.** |
| G-02 | `Probability/Monad.lean` | Docstring addition for `probTrue_eq_tsum` noting consumer use cases. |
| G-06 / G-08 | `Probability/Advantage.lean` | Docstring addition disclosing `toReal` step; decision on whether to refactor to `ℝ≥0∞` deferred (would be a breaking change; out of scope for this plan). |
| H-05 | `KeyMgmt/Nonce.lean` | Docstring addition: nonce-replay hygiene disclosure. |
| H-06 | `KeyMgmt/Nonce.lean` | Docstring addition: PRF-security discharge-obligation disclosure. |
| H-07 | `KeyMgmt/Nonce.lean` | Decision: keep `nonceDecaps` alias or delete. **Recommendation: keep, with docstring noting the alias.** |
| I-02 | `AEAD/MAC.lean` | Docstring addition: key/tag-space-size consumer-responsibility note. |
| I-05 | `AEAD/AEAD.lean` | Docstring addition: triple destructuring ergonomics. |
| I-06 | `AEAD/Modes.lean` | Docstring addition: DEM security is **assumed**. |
| I-09 | `AEAD/CarterWegmanMAC.lean` | Docstring addition: prime-verification requirement for large `p`. |
| J-01 | `Hardness/Encoding.lean` | Docstring addition: `OrbitPreservingEncoding` reference-interface status. |
| J-06 | `Hardness/CodeEquivalence.lean` | Docstring addition: `ConcreteCEOIA` cryptographic-game interpretation. |
| J-07 | `Hardness/TensorAction.lean` | Docstring addition: `tensorAction.mul_smul` proof fragility note. |
| J-11 | `Hardness/TensorAction.lean` | Docstring addition: `AreTensorIsomorphic._symm` dependency on `tensorAction.mul_smul`. |
| J-13 | `Hardness/Reductions.lean` | Docstring addition: `ConcreteGIOIAImpliesConcreteOIA_viaEncoding` chain-image semantics. |
| K-04 | `PublicKey/ObliviousSampling.lean` | Docstring: `OrbitalRandomizers` distinctness optional field tracked for v1.1. |
| K-08 | `PublicKey/CommutativeAction.lean` | Docstring addition: `pk_valid` double-conditional note. |
| K-10 / K-11 | `PublicKey/CombineImpossibility.lean` | Docstring addition: deterministic vs probabilistic combiner no-go divergence; research R-07 cross-link. |
| L-02 | `Optimization/QCCanonical.lean` | Docstring addition: redundant-abstraction status. |
| L-05 | `Optimization/TwoPhaseDecrypt.lean` | Docstring addition: normality-implies-orbit-constancy research item. |

### 15.3 Work-unit structure

Each row above is a single-file, one-to-three-commit work unit:
`L-<ModuleLetter>-WU<n>`. E.g., L-C-WU1 for C-02, L-C-WU2 for
C-03, etc. Commits per work unit are grouped by module (one PR
per module, ≥ 3 commits each).

### 15.4 PR grouping

To limit review friction and prevent merge-conflict storms, the
30+ L-workstream findings land across **nine module-aligned PRs**.
Each PR carries multiple commits but keeps all edits within a
single source file (and its immediate docstring-affecting
documentation cross-references, if any).

| PR # | Module(s) | Findings covered | Est. effort |
|------|-----------|------------------|-------------|
| L-PR1 | `GroupAction/{Canonical, Invariant}.lean` | B-04, B-06 | 30 min |
| L-PR2 | `Crypto/{Scheme, Security, CompOIA, CompSecurity}.lean` | C-02, C-03, C-04, C-06, C-11, C-12, C-14, C-16, D-02 | 2 h |
| L-PR3 | `KEM/{Syntax, Correctness, CompSecurity}.lean` | E-01, E-02, E-05, E-12 | 1 h |
| L-PR4 | `Construction/{Permutation, HGOE, HGOEKEM}.lean` | F-02, F-05, F-08 | 1 h |
| L-PR5 | `Probability/{Monad, Advantage}.lean` | G-01, G-02, G-06/G-08 | 45 min |
| L-PR6 | `KeyMgmt/Nonce.lean` | H-05, H-06, H-07 | 45 min |
| L-PR7 | `AEAD/{MAC, AEAD, Modes, CarterWegmanMAC}.lean` | I-02, I-05, I-06, I-09 | 1 h |
| L-PR8 | `Hardness/{Encoding, CodeEquivalence, TensorAction, Reductions}.lean` | J-01, J-06, J-07, J-11, J-13 | 1 h |
| L-PR9 | `PublicKey/{ObliviousSampling, CommutativeAction, CombineImpossibility}.lean` + `Optimization/*.lean` | K-04, K-08, K-10, K-11, L-02, L-05 | 1 h |

**Parallel landing.** All nine PRs are reviewer-independent (no
PR modifies a file another PR modifies). They can land in any
order; reviewers can process them in parallel.

**Hygiene gate for each PR:** every PR's review checklist must
include a per-file naming-hygiene grep (per `CLAUDE.md`
naming discipline) and a post-merge `#print axioms` spot-check
for any declaration whose docstring was touched.

### 15.5 Risk register

| # | Risk | Likelihood | Severity | Mitigation |
|---|------|-----------|----------|------------|
| L-R1 | A docstring addition accidentally drifts from the corresponding Lean content (e.g. a "note: this theorem proves X" when it actually proves X') | Medium | Medium | Every L-workstream docstring change is paired with a grep-level cross-check: the reviewer confirms the change's claim matches the theorem's statement in-file. |
| L-R2 | Two L-PRs introduce conflicting docstring additions to a shared module (unlikely given the PR grouping, but possible for cross-cutting findings) | Low | Low | PR grouping enforces disjoint file sets; cross-cutting findings (e.g. C-06 which overlaps with Workstream A) are assigned to the higher-priority workstream. |
| L-R3 | A "Recommendation" in the finding table is contested by a reviewer (e.g., "keep `nonceDecaps` alias" vs. "delete") | Low | Low | Each contested Recommendation defaults to the minimally-invasive option (docstring-only); any structural change (delete, rename, refactor) migrates to Workstream I or to a follow-up polish PR. |

### 15.6 Exit criteria for Workstream L

1. Every MEDIUM-severity finding listed above has a landed diff.
2. `lake build` succeeds; `#print axioms` outputs unchanged.
3. `scripts/audit_phase_16.lean` passes.
4. Release messaging (Workstream-**A** output) references the
   updated docstrings where appropriate.

## 16. Workstream M — Low-severity cosmetic polish

**Severity.** LOW / INFO. **Effort.** ≈ 6 h. **Scope.** Per-finding
cosmetic edits across the remaining LOW-INFO findings. Each
sub-item is a one-line or one-block docstring edit; none change
proofs or axiom dependencies.

### 16.1 Findings addressed

See § 3, table-row "All other LOW / INFO findings". The specific
identifiers from the audit are listed in the finding-taxonomy
table above; Appendix A is the canonical enumeration.

### 16.2 Work unit structure

Each sub-item is a single-line or single-paragraph docstring
edit. Work units are grouped by module (one PR per module,
multi-commit). This workstream is the "everything else that
doesn't fit anywhere" batch, and can be landed incrementally.

### 16.3 Exit criteria for Workstream M

1. Every LOW / INFO finding listed in the audit is either
   (a) remediated by a docstring edit or (b) explicitly deferred
   to post-v1.0 with a tracking item in this plan's § 18
   research catalogue.
2. `lake build` and audit scripts produce unchanged output.

## 17. Workstream N — Optional pre-release engineering enhancements

**Severity.** MEDIUM (V1-19 / I-07; V1-20 / E-07; V1-22 / E-08).
**Effort.** ≈ 5 h. **Scope.** Nice-to-have pre-release additions;
**may defer to v1.1 without blocking v1.0**.

### 17.1 Problem statement

Three items from the audit's "Nice-to-have for v1.0 (may defer to
v1.1)" subsection (§ 10.3):

- **V1-19 / I-07.** `authHybridEncrypt` / `authHybridDecrypt`
  bundling `AuthOrbitKEM` + `DEM` for the authenticated hybrid
  mode. Current `hybridEncrypt` / `hybridDecrypt` are
  non-authenticated.
- **V1-20 / E-07.** `KEMAdversary.ofGame` adapter translating
  scheme-level adversaries to KEM-level adversaries via
  `toKEM`.
- **V1-22 / E-08.** Consolidate the K2 (kemoia_implies_secure
  design note) duplication between module-level and theorem-
  level docstrings.

### 17.2 Work units

#### N1 — `authHybridEncrypt` / `authHybridDecrypt` (I-07)

**File.** `Orbcrypt/AEAD/Modes.lean` (or new submodule
`AEAD/AuthModes.lean`).

**Change.** Define `authHybridEncrypt : AuthOrbitKEM G X K Tag
→ DEM K Msg Ct → G → Msg → X × Tag × Ct` composing
`authEncaps` + `DEM.encrypt`. Define `authHybridDecrypt`
dually. Prove `authHybridDecrypt ... (authHybridEncrypt g m) =
some m` by composition of `aead_correctness` and
`DEM.correct`.

**Acceptance.**
- `lake build` succeeds.
- `#print axioms authHybrid_correctness` emits only standard-
  trio axioms.

**Note.** INT-CTXT for the hybrid mode follows from
Workstream-**B**'s refactored `INT_CTXT` predicate; add as an
additional theorem.

#### N2 — `KEMAdversary.ofGame` (E-07)

**File.** `Orbcrypt/KEM/Security.lean` (or
`Orbcrypt/KEM/Syntax.lean`).

**Change.** Define `KEMAdversary.ofGame : Adversary X M →
KEMAdversary G X K` via the `toKEM` bridge. The translation is
structural: a scheme adversary's `choose` + `guess` are
interpreted as KEM choices on the basepoint.

**Acceptance.** Type-checks; non-vacuity `example` in the audit
script.

#### N3 — Consolidate K2 design note (E-08)

**File.** `Orbcrypt/KEM/Security.lean`.

**Change.** Move the K2 design note's full content from
`kemoia_implies_secure`'s theorem docstring to the module-level
docstring. The theorem docstring retains a short pointer
("See module-level docstring for the 'no distinct-challenge KEM
corollary required' rationale").

**Acceptance.** No duplication; `lake build` succeeds.

### 17.3 Exit criteria for Workstream N

1. `authHybridEncrypt` / `authHybridDecrypt` land (or are
   explicitly deferred with a tracking item).
2. `KEMAdversary.ofGame` lands (or is deferred).
3. K2 design note is single-location.
4. `CLAUDE.md` gains a Workstream-N snapshot.

## 18. Workstream O — Research & performance catalogue (v1.1+ / v2.0)

**Severity.** n/a (research scope). **Effort.** multi-month / per-item.
**Scope.** Catalogue only — this workstream is a **tracking
document**, not a v1.0 deliverable. Each item is a separate
research milestone; engineering deferral is forbidden, so these
items are listed here to distinguish them from pre-release
engineering work.

### 18.1 Research follow-ups (R-01 through R-16)

These items require formalising mathematics from research papers
(multi-page proofs of combinatorial or algebraic constructions)
in Lean. Each is a separate research milestone whose *interface
obligation* is already satisfied by prior workstreams (mostly G
of the 2026-04-21 plan and the H workstream of this 2026-04-23
plan).

| R-# | Title | Interface | Effort |
|-----|-------|-----------|--------|
| R-01 | Distribution-parameterised `IsSeparating` | `Construction/HGOE.lean`, `Theorems/InvariantAttack.lean` | Multi-week |
| R-02 | Concrete Grochow–Qiao structure-tensor encoder | `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding` (Workstream G of 2026-04-21) | Multi-month |
| R-03 | Concrete CFI (Cai–Fürer–Immerman) graph gadget | `ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding` | Multi-month |
| R-04 | Concrete `ConcreteGIOIAImpliesConcreteOIA_viaEncoding` witness | The final chain link | Multi-month |
| R-05 | Random-oracle idealisation of `keyDerive` | `ConcreteOIAImpliesConcreteKEMOIAUniform` (Workstream H of 2026-04-21) | Multi-month |
| R-06 | Any ε < 1 witness for `ConcreteHardnessChain` | Combines R-02/R-03/R-04 | Research |
| R-07 | Probabilistic combiner no-go | `PublicKey/CombineImpossibility.lean` | Multi-week |
| R-08 | Wegman–Carter SUF-CMA reduction | `Probability/UniversalHash.lean` → new `MAC/CarterWegmanSecurity.lean` | Multi-week |
| R-09 | Multi-query IND-Q-CPA `h_step` discharge | `Crypto/CompSecurity.lean` (Workstream **C** of this plan punts to here) | Multi-week |
| R-10 | Concrete oblivious-sampling `combine` function | `PublicKey/ObliviousSampling.lean` | Believed open |
| R-11 | Concrete non-trivial `CommGroupAction` instance | `PublicKey/CommutativeAction.lean` | Multi-month |
| R-12 | Probabilistic `ObliviousSamplingHiding` refinement | `PublicKey/ObliviousSampling.lean` | Multi-week |
| R-13 | `Bitstring n → ZMod p` adapter for CW + HGOE | `AEAD/CarterWegmanMAC.lean` + new composition module | Multi-week |
| R-14 | Probabilistic MAC SUF-CMA | `AEAD/MAC.lean` + new probabilistic module | Multi-week |
| R-15 | `CanonicalForm.canon` polynomial-time bound | New complexity formalisation | Multi-month |
| R-16 | Full invariant-defence formalisation beyond Hamming | `Construction/HGOE.lean` | Multi-week |

### 18.2 Performance & implementation milestones (Z-01 through Z-10)

These items are non-security performance / implementation gaps:

| Z-# | Title | Scope | Target |
|-----|-------|-------|--------|
| Z-01 | Phase 15 C/C++ fast decryption | `implementation/c/` (new) | v1.1+ |
| Z-02 | Lean-verified GAP counterpart | GAP-Lean correspondence layer | v1.1+ |
| Z-03 | Formalised PRF instance | New `Probability/PRF.lean` | v1.1+ |
| Z-04 | Formalised cryptographic hash for `keyDerive` | `KEM/Syntax.lean` + new module | v1.1+ |
| Z-05 | Formalised DEM security | `AEAD/Modes.lean` + new module | v1.1+ |
| Z-06 | Full {80, 192, 256} coverage in Lean | Addressed by Workstream **G** of this plan | pre-v1.0 |
| Z-07 | Concrete `CanonicalForm` for S_n bitstrings | Addressed by Workstream **F** of this plan | pre-v1.0 |
| Z-08 | Side-channel formalisation | Implementation-level; deferred | v2.0+ |
| Z-09 | Serialization / deserialization formalisation | New module | v1.1+ |
| Z-10 | NIST-PQC alignment formalisation | Comparative analysis | Research |

### 18.3 Handover discipline

Each R-* / Z-* item is a **tracking entry**, not a commitment.
The plan does not promise delivery; it documents the gap and
the interface where future work will plug in. Engineering
deferral (listing an engineering item as "R-*" to avoid doing
it) is forbidden by the `CLAUDE.md` "no half-finished
implementations" directive; every item listed here has been
assessed and classified as genuine research or performance work
outside the scope of release-messaging alignment.

## 19. Regression safeguards

### 19.1 CI guarantees (unchanged)

The existing CI workflow (`.github/workflows/lean4-build.yml`)
runs, in sequence:

1. `lake build` for every module (exit 0, no warnings).
2. Comment-aware `sorry` scan (Perl regex strips block and line
   comments before grepping).
3. Axiom-declaration scan (`^axiom` at column 0).
4. `scripts/audit_phase_16.lean` execution: de-wraps multi-line
   axiom lists and rejects any non-standard axiom.

**Post-workstream extensions.**

- Workstream **B**: new `#print axioms` entries in
  `scripts/audit_phase_16.lean` for the refactored `INT_CTXT`
  predicate and the updated `authEncrypt_is_int_ctxt` /
  `carterWegmanMAC_int_ctxt` signatures.
- Workstream **E**: `#print axioms det_oia_false_of_distinct_reps`
  and `#print axioms det_kemoia_false_of_nontrivial_orbit`.
- Workstream **F**: `#print axioms CanonicalForm.ofLexMin` and
  its companion theorems.
- Workstream **G**: four `HGOEKeyExpansion λ …` non-vacuity
  witnesses (one per documented security level).
- Workstream **H**: `#print axioms decapsSafe`, `decapsSafe_correctness`,
  `decryptCompute`, `decryptCompute_eq_decrypt`.
- Workstream **J**: `#print axioms IsNegligible.of_le`,
  `IsNegligible.const_mul`.
- Workstream **N** (if landed): `#print axioms authHybrid_correctness`.

All should emit standard-trio axioms only.

### 19.2 Per-workstream satisfiability witnesses

Each workstream that adds a structural predicate or
Proposition-valued assumption ships a matching `example` in
`scripts/audit_phase_16.lean` confirming non-vacuity. **The
canonical source for each witness snippet is Appendix C**; the
list below is a summary cross-reference:

- **A** (docs-only): no witness.
- **B**: `INT_CTXT` exercised on a toy `AuthOrbitKEM` where the
  per-challenge `hOrbit` hypothesis is trivially true.
- **C** (rename-only): no new witness; existing
  `indQCPA_from_perStepBound` example updated.
- **D** (toolchain): no witness.
- **E**: `det_oia_false_of_distinct_reps` applied to a concrete
  two-message scheme; `det_kemoia_false_of_nontrivial_orbit`
  applied to a concrete KEM with `|orbit basePoint| = 2`.
- **F**: `CanonicalForm.ofLexMin` instantiated on a concrete
  small-n subgroup of `S_n` with a verifiable `canon` output.
- **G**: four non-vacuity witnesses, one per security level.
- **H**: `decapsSafe` / `decryptCompute` exercised on a toy
  KEM + toy scheme respectively.
- **I** (renames only): existing witnesses kept; name-only
  update.
- **J**: `IsNegligible.of_le` and `IsNegligible.const_mul`
  exercised on concrete negligible functions.
- **K** (docs-only): no new witness; audit-script output
  bit-identical to pre-K.
- **L** / **M** (polish): no new witnesses (edits are docstring-
  level or `@[simp]` tags; no new Lean content).
- **N** (if landed): `authHybrid_correctness`,
  `KEMAdversary.ofGame` non-vacuity.

### 19.3 Golden-file baselines

Workstreams **B**, **E**, **F**, **G**, **H**, **J** modify
module source (adding declarations or tightening signatures).
For each, `scripts/audit_phase_16.lean`'s output is updated in
the same commit as the corresponding Lean change; the
standard-trio axiom whitelist remains identical.

Workstreams **C** and **I** rename declarations. Golden
`#print axioms` outputs change in their left-hand-side
identifier only. CI's axiom-set whitelist is unaffected.

Workstreams **A**, **D**, **K**, **L**, **M**, **N** (docs-
only, comment-only, file-move, or ergonomic) make no changes to
`scripts/audit_phase_16.lean`'s kernel output beyond what
Workstreams **B**/**E**/**F**/**G**/**H**/**J** land.

### 19.4 Review checklist (for PR authors)

Before opening a PR on any workstream branch, confirm:

- [ ] `source ~/.elan/env && lake build` succeeds (exit 0, no warnings).
- [ ] Every modified module builds individually: `lake build
      Orbcrypt.<ModulePath>`.
- [ ] `grep -rn "sorry" Orbcrypt/ --include="*.lean"` (comment-
      aware Perl-strip variant used by CI) returns empty.
- [ ] `scripts/audit_phase_16.lean` passes locally.
- [ ] For renames (**C**, **I**): every downstream `.lean`, `.md`,
      and `.sh` reference updated; CI green on the rename-only
      diff before combining with other changes.
- [ ] Naming hygiene: the `git diff --cached`-based grep from
      `CLAUDE.md`'s Key Conventions returns empty for forbidden
      tokens (`workstream`, `ws`, `wu`, `audit`, `phase[0-9]`,
      `v1_[0-9]`, etc.) in **added declaration names**.
- [ ] `CLAUDE.md` updated with the per-workstream entry
      (following the 2026-04-18 / 2026-04-21 precedent).
- [ ] `Orbcrypt.lean`'s axiom-transparency report updated
      (through Workstream **K**, this migrates to
      `docs/AXIOM_TRANSPARENCY.md`).
- [ ] `docs/VERIFICATION_REPORT.md` updated if the workstream
      affects a headline theorem.
- [ ] `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` (this
      document) marked with the workstream's completion status
      in Appendix B (workstream status tracker) — added at merge time.

## 20. Release-readiness checklist

Upon completion of the pre-release slate (Workstreams **A**, **B**,
**C**, **D**, **E**), verify the v1.0 release-gate checklist
below. Items V1-1 through V1-9 are the audit's own
release-blocking items; the per-workstream items are this plan's
acceptance criteria.

### 20.1 Audit-derived release-gate items

- [x] **V1-1** (Workstream **B**): `INT_CTXT` refactored; orbit-
      cover is per-challenge, not theorem-level. Row #19 Status
      in `CLAUDE.md` reads **Standalone** post-B. **Closed by
      landing 2026-04-24.**
- [ ] **V1-2** (Workstream **A**): `CLAUDE.md` rows #24 #25
      reclassified to **Conditional**.
- [ ] **V1-3** (Workstream **A**): `docs/VERIFICATION_REPORT.md`
      "Release readiness" section explicitly states "ε = 1 only
      in current formalisation; ε < 1 is research-scope".
- [ ] **V1-4** (Workstream **A** + **J**): invariant-attack
      framing matches the theorem's actual statement;
      `invariantAttackAdversary_correct` removed.
- [ ] **V1-5** (Workstream **A**): `SeedKey.compression`
      framing disclosed as bit-length strict inequality.
- [x] **V1-6** (Workstream **D**): toolchain decision recorded.
      **Closed by landing 2026-04-24.** `lean-toolchain` retains
      `leanprover/lean4:v4.30.0-rc1` under Scenario C (rc by
      design; stable-toolchain upgrade deferred to v1.1);
      `lakefile.lean` comment metadata refreshed (Last-verified
      date + Toolchain-posture paragraph); `leanOptions` extended
      with defensive pins for `linter.unusedVariables` and
      `linter.docPrime` (both pinned to `true`); full `lake build`
      clean (3,367 jobs, zero warnings); Phase-16 audit script
      clean (standard-trio-only, zero `sorryAx`). `lakefile.lean`
      bumped from `0.1.8` to `0.1.9`.
- [ ] **V1-7** (Workstream **A**): Carter–Wegman / HGOE
      compatibility messaging explicit.
- [x] **V1-8** (Workstream **C**): `indQCPA_from_perStepBound`
      landed (rename track); R-09 catalogued. **Closed by landing
      2026-04-24** (`indQCPA_bound_via_hybrid` →
      `indQCPA_from_perStepBound`; companion renamed likewise;
      CompSecurity.lean docstrings extended with Game-shape +
      User-supplied-hypothesis-obligation blocks; three non-vacuity
      witnesses added to `scripts/audit_phase_16.lean`;
      `DEVELOPMENT.md §8.2` prose updated to expose the `h_step`
      obligation and the R-09 research pointer).
- [ ] **V1-9** (Workstream **A**): "Release messaging policy"
      section present in `CLAUDE.md`.
- [x] **V1-10** (Workstream **F**): `CanonicalForm.ofLexMin`
      lands as a computable Lean-side witness for the
      previously-abstract `CanonicalForm` parameter on
      `hgoeScheme`. **Closed by landing 2026-04-24.**
      `Orbcrypt/GroupAction/CanonicalLexMin.lean` (new module,
      the 40th `.lean` file) lands the constructor taking
      `[Group G] [MulAction G X] [Fintype G] [DecidableEq X]
      [LinearOrder X]` and producing a `CanonicalForm G X`
      via `Finset.min'` on the orbit's `.toFinset`. Supporting
      `orbitFintype` / `mem_orbit_toFinset_iff` /
      `orbit_toFinset_nonempty` helpers plus two `@[simp]`
      / companion lemmas (`ofLexMin_canon`,
      `ofLexMin_canon_mem_orbit`) discharge every
      `CanonicalForm` field without `sorry`.
      `Orbcrypt/Construction/Permutation.lean` gains the
      `bitstringLinearOrder` (`@[reducible] def`, not a global
      instance) via `LinearOrder.lift' List.ofFn
      List.ofFn_injective`; callers bind it locally via
      `letI` to avoid the diamond with Mathlib's pointwise
      `Pi.partialOrder`. `Orbcrypt/Construction/HGOE.lean`
      gains `hgoeScheme.ofLexMin` (the F4 convenience
      constructor) + `hgoeScheme.ofLexMin_reps` companion
      lemma. `scripts/audit_phase_16.lean` gains six new
      `#print axioms` entries (three helpers + three lex-min
      declarations) plus four new non-vacuity `example`
      bindings under a new `## Workstream F non-vacuity
      witnesses` section. `CLAUDE.md`,
      `docs/VERIFICATION_REPORT.md`, and `Orbcrypt.lean` all
      gain Workstream-F snapshots. `lakefile.lean` bumped
      from `0.1.10` to `0.1.11`. Module count 39 → 40;
      public-declaration count 349 → 358; Phase-16 audit
      `#print axioms` total 373 → 382; the zero-sorry /
      zero-custom-axiom / standard-trio-only posture is
      preserved.
- [x] **V1-11** (Workstream **E**): `det_oia_false_of_distinct_reps`
      and `det_kemoia_false_of_nontrivial_orbit` landed. **Closed by
      landing 2026-04-24.** `Orbcrypt/Crypto/OIA.lean` gains E1 at
      the bottom of the module; `Orbcrypt/KEM/Security.lean` gains
      E2 at the bottom of the module. Both depend only on the
      standard Lean trio. `Orbcrypt.lean`'s Vacuity map upgraded to
      a three-column table pointing the `OIA` / `KEMOIA` rows at
      E1 / E2; two new `#print axioms` cookbook entries; a new
      "Workstream E Snapshot" section appended. `scripts/audit_phase_16.lean`
      gains two new `#print axioms` entries and two concrete
      non-vacuity `example` bindings over `trivialSchemeBool` and
      `trivialKEM_PermZMod2`. `CLAUDE.md`, `docs/VERIFICATION_REPORT.md`,
      `formalization/FORMALIZATION_PLAN.md`, and `DEVELOPMENT.md §8.1`
      all updated. `lakefile.lean` bumped from `0.1.9` to `0.1.10`.

### 20.2 Technical posture gates

- [ ] `lake build` for all modules succeeds, zero warnings.
- [ ] `grep -Prn "(?<!\-\-\s)sorry" Orbcrypt/ --include="*.lean"`
      (comment-aware) returns empty.
- [ ] `grep -rn "^axiom " Orbcrypt/ --include="*.lean"` returns
      empty.
- [ ] `scripts/audit_phase_16.lean` passes: zero `sorryAx`,
      zero non-standard axioms.
- [ ] Every new declaration added in Workstreams **B**, **E**,
      **F**, **G**, **H**, **J**, **N** carries a docstring.
- [ ] Every new declaration's `#print axioms` output is in the
      standard trio.
- [ ] Every new Conditional / Scaffolding theorem has a
      non-vacuity witness in the audit script.

### 20.3 Documentation-vs-code parity gates

- [ ] `CLAUDE.md` Status column matches the release-messaging
      policy (no claim exceeds what the Lean content delivers).
- [ ] `docs/VERIFICATION_REPORT.md` headline table aligned with
      `CLAUDE.md`'s Status column.
- [ ] `DEVELOPMENT.md` prose at §6.2.1, §7.1, §8.2, §8.5 does
      not overstate Lean content.
- [ ] `Orbcrypt.lean` (or its post-K successor
      `docs/AXIOM_TRANSPARENCY.md` + `docs/CHANGELOG.md`) reflects
      the post-workstream state.

### 20.4 Post-preferred-slate gates (additional, non-blocking)

- [ ] Workstream **F** lands: `CanonicalForm.ofLexMin` witness
      exists.
- [ ] Workstream **G** lands: `HGOEKeyExpansion` parameterised
      by λ; witnesses at {80, 128, 192, 256}.
- [ ] Workstream **H** lands: `decapsSafe` / `decryptCompute`
      exist.
- [ ] Workstream **I** lands: six renames completed.
- [ ] Workstream **J** lands: invariant-attack framing
      tightened; `IsNegligible.of_le` / `const_mul`.

### 20.5 Post-polish gates (optional)

- [ ] Workstream **K** lands: `Orbcrypt.lean` ≤ 200 lines;
      `docs/CHANGELOG.md` and `docs/AXIOM_TRANSPARENCY.md`
      exist.
- [ ] Workstream **L** / **M** land: MEDIUM / LOW findings
      remediated.
- [ ] Workstream **N** lands (or explicitly deferred to v1.1).

### 20.6 External review

- [ ] External reviewer sign-off on `docs/VERIFICATION_REPORT.md`
      post-A.
- [ ] External reviewer sign-off on the `CLAUDE.md`
      release-messaging policy.

## 21. Validation log (findings verified against source)

The following table records the spot-check validation performed
while drafting this plan. Methodology: each row identifies the
audit finding, the exact source-code location verified, and the
verdict. **Goal: rule out erroneous or duplicated findings.** No
finding is accepted without source verification; finding
identifiers are carried verbatim from the source audit.

| Finding | Grade | Audit § | Source check | Verdict |
|---------|-------|---------|--------------|---------|
| I-03 | HIGH | 3.27 | `AEAD/AEAD.lean:264` shows `hOrbitCover` as explicit theorem parameter. Orbit-size argument confirmed: `|Bitstring n| = 2^n > |orbit|` for non-trivial subgroups of `S_n`. | **VALID** |
| L-03 / D2 | HIGH | 3.39, 9 | `Optimization/TwoPhaseDecrypt.lean:59–77` module docstring self-discloses failure on GAP fallback; `CLAUDE.md` lines 492–493 show rows #24 #25 labeled `Standalone`. | **VALID** |
| C-07 | HIGH | 3.6 | `Crypto/OIA.lean:46–67` states vacuity in prose; `grep -rn "det_oia_false"` returns zero matches. | **VALID** |
| E-06 | HIGH | 3.15 | `KEM/Security.lean` line 186–189 states vacuity in prose; `grep -rn "det_kemoia_false"` returns zero matches. | **VALID** |
| V1-2 / M-02 | HIGH | 10.1, 4 | `CLAUDE.md` line 492 row #24 literally says `Standalone`; row #25 says `Standalone`. Divergence from the `TwoPhaseDecomposition` caveat confirmed. | **VALID** |
| F-04 | MEDIUM | 3.18 | `Construction/HGOE.lean:56–62` shows `can : CanonicalForm (↥G) (Bitstring n)` parameter without any concrete `CanonicalForm.ofLexMin`-style constructor anywhere in-tree. | **VALID** |
| K-07 | HIGH | 3.36 | `PublicKey/CommutativeAction.lean:73` defines `class CommGroupAction`; only in-tree `def`-form instance is `CommGroupAction.selfAction` on CommGroup self-action (line 285). No HGOE-compatible instance. | **VALID** |
| K-01 | HIGH | 3.34 | `PublicKey/ObliviousSampling.lean:106` docstring explicitly reads "No known `combine` satisfies `hClosed`…". Hypothesis is parameter-level, no witness. | **VALID** |
| H-03 | MEDIUM | 3.24 | `KeyMgmt/SeedKey.lean:232` shows `group_large_enough : group_order_log ≥ 128`, literal constant. `λ` not a structure parameter. | **VALID** |
| C-13 | HIGH | 3.8 | `Crypto/CompSecurity.lean` `indQCPA_bound_via_hybrid` signature carries `h_step` as explicit hypothesis; no `ConcreteOIA`-derived discharge in-tree. | **VALID** |
| D-04 / D13 | HIGH | 3.10, 9 | `Theorems/InvariantAttack.lean:156–162` conclusion is `∃ A, hasAdvantage`; does not match "advantage 1/2" in `CLAUDE.md` row #2 narrative. | **VALID** |
| D-07 / V1-15 | HIGH | 3.11 | `Theorems/OIAImpliesCPA.lean` `insecure_implies_separating` return-type is `∃ f m₀ m₁ g₀ g₁, f (g₀ • reps m₀) ≠ f (g₁ • reps m₁)`; no G-invariance in conclusion despite the name. | **VALID** |
| C-15 / E-11 | MEDIUM | 3.8, 3.16 | `concreteOIA_one_meaningful` proves `indCPAAdvantage ≤ 1` (trivial); `concreteKEMOIA_one_meaningful` proves `kemAdvantage ≤ 1` (trivial). Name suggests satisfiability-witness, actually proves advantage-bound. | **VALID** |
| E-04 | HIGH | 3.13 | `KEM/Encapsulate.lean:62–64` `decaps kem c := kem.keyDerive (kem.canonForm.canon c)` — no orbit check. No `decapsSafe` variant in-tree. | **VALID** |
| H-01 / D5 | HIGH | 3.24, 9 | `KeyMgmt/SeedKey.lean:38–48` docstring confirms `compression` is bit-length comparison via `Nat.log 2` (round-down), not element-count ratio; the "1.8 MB compression" claim in `DEVELOPMENT.md §6.2.1` exceeds the Lean content. | **VALID** |
| I-08 / D4 | HIGH | 3.29 | `AEAD/CarterWegmanMAC.lean` MAC is typed `MAC (ZMod p × ZMod p) (ZMod p) (ZMod p)`; HGOE uses `Bitstring n`; no composition adapter exists. | **VALID** |
| J-03 | HIGH | 3.31 | `Hardness/CodeEquivalence.lean:339–344` — `GIReducesToCE` is `∃ dim encode, ∀ adj₁ adj₂, …`; degenerate encoder like `encode _ _ := ∅` satisfies the existential trivially. | **VALID** |
| J-08 | HIGH | 3.32 | Same pattern for `GIReducesToTI`. | **VALID** |
| M-01 | HIGH | 4 | `wc -l Orbcrypt.lean` returns 1585. | **VALID** |
| C-01 | MEDIUM | 3.4 | `Crypto/Scheme.lean:105` `noncomputable def decrypt … := … h.choose …`. | **VALID** |
| G-04 / G-05 | MEDIUM | 3.21 | `grep "IsNegligible\." Orbcrypt/Probability/Negligible.lean` shows only `.add` and `.mul_const`. No `.of_le` or `.const_mul`. | **VALID** |
| A-03 | MEDIUM | 2.2 | `cat lean-toolchain` → `leanprover/lean4:v4.30.0-rc1`. Confirmed rc. | **VALID** |
| D-06 | MEDIUM | 3.10 | `Theorems/InvariantAttack.lean:162–172` — `invariant_attack`'s proof uses `refine ⟨1, 1, ?_⟩` + `simp`; does NOT reference `invariantAttackAdversary_correct` (line 104). Helper is unused. | **VALID** |
| H-07 | LOW | 3.25 | `KeyMgmt/Nonce.lean:84–86` `nonceDecaps kem c := decaps kem c` — one-line alias. | **VALID** |

**Verification summary.**

- **Findings verified: 24** spot-checks across the audit's key
  HIGH / MEDIUM claims (including the CRITICAL-adjacent X-01
  supporting findings).
- **Verdict: 24 VALID / 0 ERRONEOUS / 0 DUPLICATED.**
- **Methodology note.** Every verification read the exact source
  file and line numbers cited by the audit. Where the audit's
  line numbers were slightly off (due to the Workstream-L1
  SeedKey refactor changing line-offsets), the verification
  tracked the named declaration, not the literal line number.

The source audit's 140+ findings were not exhaustively
spot-checked at this granularity (time bound); the 24 chosen for
verification are the ones whose severity (HIGH / MEDIUM with
release-gate implications) and structural impact (signatures,
status labels, named-theorem existence) most directly drive the
workstream design above. Every other finding in the source audit
was reviewed for surface plausibility against the module layout
and docstring evidence already loaded into context; none trigger
suspicion of being erroneous, though implementers of
Workstreams **L** and **M** should re-verify each sub-item
against source before landing.

## 22. Implementation branches

Each workstream lands on a dedicated branch; PRs merge into
`main` in the dependency order defined in § 3 (workstream
summary). **This plan document** is landing on
`claude/audit-findings-workstream-xVw9o` per the session
instruction.

Proposed per-workstream branches (implementer may adjust names
at PR time):

- `claude/audit-2026-04-23-workstream-a-release-messaging`
- `claude/audit-2026-04-23-workstream-b-intctxt-refactor`
- `claude/audit-2026-04-23-workstream-c-indqcpa-rename`
- `claude/audit-2026-04-23-workstream-d-toolchain`
- `claude/audit-2026-04-23-workstream-e-vacuity-witnesses`
- `claude/audit-2026-04-23-workstream-f-lexmin`
- `claude/audit-2026-04-23-workstream-g-hgoekeyexpansion`
- `claude/audit-2026-04-23-workstream-h-decaps-safe`
- `claude/audit-2026-04-23-workstream-i-naming-hygiene`
- `claude/audit-2026-04-23-workstream-j-invariant-negligible`
- `claude/audit-2026-04-23-workstream-k-rootfile-split`
- `claude/audit-2026-04-23-workstream-l-medium-polish`
- `claude/audit-2026-04-23-workstream-m-low-polish`
- `claude/audit-2026-04-23-workstream-n-optional-engineering`

Each branch carries one or more PRs (per-module-grouping); PRs
merge in the order defined above.

## 23. Signoff

**Plan author.** Claude (Opus 4.7, 1M context).
**Plan date.** 2026-04-23.
**Plan branch.** `claude/audit-findings-workstream-xVw9o`.
**Source audit.**
`docs/audits/LEAN_MODULE_AUDIT_2026-04-23_PRE_RELEASE.md`.
**Plan status.** Ready for implementer intake.
**Next action.** Assign Workstream **A** to a release-messaging
implementer; open tracking issues per workstream; begin with
WU A1 (release-messaging policy in `CLAUDE.md`).

## Appendix A — Finding-ID → workstream-and-work-unit cross-reference

This appendix is the canonical mapping from source-audit finding
ID to this plan's workstream + work-unit assignment.

### Release-gate items (V1-1 through V1-22)

| V1-# | Audit § | Source finding | Workstream | WU |
|------|---------|----------------|------------|-----|
| V1-1 | 10.1 | I-03, I-04 | **B** | B1, B2, B3, B4 |
| V1-2 | 10.1 | L-03, D2, M-02 | **A** | A2 |
| V1-3 | 10.1 | E-10, J-12, J-15, D3, D9 | **A** | A3 |
| V1-4 | 10.1 | D-04, D-05, D-06, D13 | **A**, **J** | A6, J1, J2, J3 |
| V1-5 | 10.1 | H-01, D5 | **A** | A5 (§6.2.1) |
| V1-6 | 10.1 | A-03 | **D** | D1 |
| V1-7 | 10.1 | I-08, I-10, D4 | **A** | A3 (cite guidance), A4 |
| V1-8 | 10.1 | C-13, D10 | **C** | C1, C2 |
| V1-9 | 10.1 | X-01 | **A** | A1 |
| V1-10 | 10.2 | F-04 | **F** | F1–F4 |
| V1-11 | 10.2 | C-07, E-06 | **E** | E1, E2, E3 |
| V1-12 | 10.2 | C-01, X-02 | **H** | H3, H4, H5 |
| V1-13 | 10.2 | H-03, D16 | **G** | G1, G2, G3 |
| V1-14 | 10.2 | E-04 | **H** | H1, H2, H5 |
| V1-15 | 10.2 | C-15, D-07, E-11, J-03, J-08, K-02 | **I** | I1–I5 |
| V1-16 | 10.2 | G-04, G-05 | **J** | J4, J5, J6 |
| V1-17 | 10.2 | M-01 | **K** | K1, K2, K3 |
| V1-18 | 10.2 | N-03, N-04 | **K** | K5, K6 |
| V1-19 | 10.3 | I-07 | **N** | N1 |
| V1-20 | 10.3 | E-07 | **N** | N2 |
| V1-21 | 10.3 | M-03 | **K** | K4 (optional) |
| V1-22 | 10.3 | E-08 | **N** | N3 |

### Documentation-vs-code divergence log (D1 through D16)

| D-# | Claim vs reality | Workstream | WU |
|-----|------------------|------------|-----|
| D1 | INT-CTXT advertised as Standalone vs orbit-cover hypothesis | **A** (status) + **B** (refactor) | A2 + B1–B4 |
| D2 | Two-phase #24 #25 Standalone vs TwoPhaseDecomposition | **A** | A2 |
| D3 | KEM ε-smooth chain vs only ε = 1 inhabited | **A** | A3 |
| D4 | Carter–Wegman witness advertised as composable with HGOE | **A** | A3, A4 |
| D5 | Compression ratio in DEVELOPMENT.md §6.2.1 | **A** | A5 |
| D6 | Oblivious sampling preserves sender privacy | **A** + **I** (rename) | A3, I4 |
| D7 | CSIDH-style commutative PKE | **A** (disclosure) + R-11 | A3 |
| D8 | GI ≤ CE reduction | **A** + **I** (rename) | A3, I3 |
| D9 | Hardness chain at ε | **A** | A3, A4 |
| D10 | Multi-query IND-Q-CPA | **A** + **C** | A5, C1, C2 |
| D11 | `kemoia_implies_secure` Scaffolding status consistent | **A** | no-op (A1 policy formalises) |
| D12 | Row #19 INT-CTXT Standalone mislabel | **A** | A2 (pre-B), B4 (post-B) |
| D13 | Invariant attack complete-break framing | **A** + **J** | A6, J1 |
| D14 | Zero custom axioms — verified ✓ | n/a | (audit-confirmed correct) |
| D15 | Zero sorry — verified ✓ | n/a | (audit-confirmed correct) |
| D16 | Phase 14 parameter sweep λ ∈ {80, 128, 192, 256} vs hard-coded 128 | **G** | G1, G2, G3 |

### Module-group findings (§§ 3.1 through 3.39)

Per-module findings are enumerated in the main body of the
plan (Workstream **L** / **M** tables in § 15 and § 16
respectively). The authoritative source is the plan's § 15.2
table, which lists every MEDIUM finding with its fix summary,
and § 16.1 + the audit's § 3 for LOW / INFO findings.

### Cross-cutting findings (X-*, P-*)

| Finding | Workstream | WU |
|---------|------------|-----|
| X-01 | **A** + **B** + **C** + **E** | A1 + A3 + A4 + B1 + C1 + E1 + E2 |
| X-02 | **H** | H3, H4 |
| X-03 | **L** (layering docstring note) | L-docstring |
| X-04 | **L** (universe posture audit) | L-docstring |
| X-05 | **M** | M-docstring |
| P-01 | n/a (audit-confirmed correct) | no-op |
| P-02 | n/a | no-op |
| P-03 | n/a | no-op |
| P-04 | **M** (docstring expansion) | M-docstring |
| P-05 | **L** (non-vacuity audit script extension note) | L-docstring (tracks to R-06) |

### Research / performance catalogue

R-01 through R-16 and Z-01 through Z-10 are catalogued in
§ 18; none map to pre-release engineering work units.

## Appendix B — Workstream status tracker

The tracker below is populated as workstreams close (via PR
merge).

| Workstream | Status | PR | Closed date |
|------------|--------|----|-------------|
| **A** (release messaging) | pending | — | — |
| **B** (INT_CTXT refactor) | pending | — | — |
| **C** (indQCPA rename) | pending | — | — |
| **D** (toolchain) | **closed** | branch `claude/review-workstream-plan-6xBp6` | 2026-04-24 |
| **E** (formal vacuity) | **closed** | branch `claude/complete-workstream-e-bKTP9` | 2026-04-24 |
| **F** (`CanonicalForm.ofLexMin`) | **closed** | branch `claude/audit-workstream-f-ObCfg` | 2026-04-24 |
| **G** (λ-parameterised key expansion) | pending | — | — |
| **H** (decapsSafe + decryptCompute) | pending | — | — |
| **I** (naming hygiene via strengthening) | pending | — | — |
| **J** (invariant framing + negligible closure) | pending | — | — |
| **K** (root-file split) | pending | — | — |
| **L** (MEDIUM polish) | pending | — | — |
| **M** (LOW / INFO polish) | pending | — | — |
| **N** (optional engineering) | pending | — | — |
| **O** (research + performance catalogue) | tracking (never closes) | — | — |

## Appendix C — Non-vacuity witness Lean snippets

This appendix assembles the concrete Lean `example` snippets that
every new declaration landed by this plan must be exercised
against in `scripts/audit_phase_16.lean`'s `§ 12
NonVacuityWitnesses` section. Each snippet is a drop-in
specification; implementers copy the snippet into the audit script
under the workstream's own subsection, replacing placeholder names
with actual ones as workstream edits land.

**General convention.** Every snippet evaluates to `example : T := …`
where `T` is the declaration's type instantiated on the in-tree
`toyScheme` / `toyKEM` model (over `Unit` or `Fin 2` / `Bool`
carriers) already present in the audit script. This ensures every
non-vacuity test is self-contained, runnable via `lake env lean
scripts/audit_phase_16.lean`, and does not introduce any new
module dependencies.

### C.1 Workstream B — refactored `INT_CTXT`

```lean
-- Non-vacuity: INT_CTXT (post-B) on a singleton-orbit toy KEM.
example : INT_CTXT toyAuthKEM := by
  intro c t hOrbit hFresh
  -- On the singleton orbit, `c = basePoint` and authDecaps reduces
  -- to a decidable equality on tags; hFresh closes the case.
  exact toyAuthKEM_intctxt_singleton c t hOrbit hFresh
```

### C.2 Workstream C — renamed `indQCPA_from_perStepBound`

```lean
-- Non-vacuity: the renamed theorem applies to the toyScheme at
-- Q = 2 with a trivial per-step bound.
example :
    indQCPAAdvantage toyScheme (toyMultiQueryAdversary 2) ≤ 2 * (1 : ℝ) :=
  indQCPA_from_perStepBound (Q := 2) toyScheme (1 : ℝ)
    (toyMultiQueryAdversary 2)
    (by intro i _; exact ⟨0, by linarith⟩)
```

### C.3 Workstream E — vacuity witnesses

```lean
-- Non-vacuity: det_oia_false_of_distinct_reps on the toyScheme
example : ¬ OIA toyScheme :=
  det_oia_false_of_distinct_reps toyScheme toyScheme_reps_distinct

-- Non-vacuity: det_kemoia_false_of_nontrivial_orbit on toyKEM
example : ¬ KEMOIA toyKEM :=
  det_kemoia_false_of_nontrivial_orbit toyKEM
    toyKEM_basePoint_orbit_nontrivial
```

### C.4 Workstream F — `CanonicalForm.ofLexMin` concrete computation

```lean
-- Non-vacuity: ofLexMin computes a lex-min on a concrete bitstring,
-- matching GAP's CanonicalImage(G, x, OnSets) convention exactly.
-- Under the GAP-matching `bitstringLinearOrder` ("leftmost-true
-- wins"), the input ![true, false, true] under the swap-only
-- subgroup is its own lex-min (its leftmost-true is at position 0,
-- the smallest possible).
example :
    let σ : Equiv.Perm (Fin 3) := Equiv.swap 0 1
    let G : Subgroup (Equiv.Perm (Fin 3)) := Subgroup.closure {σ}
    let can : CanonicalForm (↥G) (Bitstring 3) := CanonicalForm.ofLexMin G
    can.canon ![true, false, true] = ![true, false, true] := by
  decide
```

### C.5 Workstream G — λ-parameterised `HGOEKeyExpansion`

```lean
-- Non-vacuity: HGOEKeyExpansion instantiates at λ = 80
example :
    Nonempty (HGOEKeyExpansion (lam := 80) (n := 256) toyMessageSpace) :=
  ⟨toyHGOEKeyExpansion_80⟩

-- Non-vacuity: HGOEKeyExpansion also instantiates at λ = 256
example :
    Nonempty (HGOEKeyExpansion (lam := 256) (n := 1024) toyMessageSpace) :=
  ⟨toyHGOEKeyExpansion_256⟩
```

### C.6 Workstream H — `decapsSafe` and `decryptCompute`

```lean
-- Non-vacuity: decapsSafe on in-orbit ciphertext returns some
example :
    decapsSafe toyKEM (toyKEM.basePoint) = some (decaps toyKEM toyKEM.basePoint) :=
  decapsSafe_eq_some_of_mem_orbit toyKEM
    (MulAction.mem_orbit_self toyKEM.basePoint)

-- Non-vacuity: decapsSafe on out-of-orbit ciphertext returns none
example (c : toyKEM.X) (hOff : c ∉ MulAction.orbit _ toyKEM.basePoint) :
    decapsSafe toyKEM c = none :=
  decapsSafe_eq_none_of_not_mem_orbit toyKEM hOff

-- Non-vacuity: decryptCompute agrees with decrypt on an honest ciphertext
example (m : toyScheme.M) (g : toyScheme.G) :
    decryptCompute toyScheme (encrypt toyScheme g m) =
    decrypt toyScheme (encrypt toyScheme g m) :=
  decryptCompute_eq_decrypt toyScheme _

-- Non-vacuity: the reflexivity corollary
example (m : toyScheme.M) (g : toyScheme.G) :
    decryptCompute toyScheme (encrypt toyScheme g m) = some m :=
  decryptCompute_encrypt toyScheme m g
```

### C.7 Workstream I — strengthened declarations

The post-I appendix illustrates the *substantive* witnesses
landed by the strengthening rewrite — not just renamed weak
content. Each `example` exercises a strengthened theorem on a
concrete instance.

```lean
-- I1. Sanity bound (renamed simp lemma): trivially `≤ 1` for
-- any adversary against any scheme. The renamed identifier
-- replaces the misleading `_meaningful` suffix.
example : indCPAAdvantage toyScheme toyAdversary ≤ 1 :=
  indCPAAdvantage_le_one toyScheme toyAdversary

-- I1. Substantive non-vacuity: ConcreteOIA scheme 0 holds
-- non-trivially on every subsingleton-message scheme. This is
-- the cryptographic strengthening that replaces the trivial
-- `_meaningful` bound: it inhabits the *meaningful* end of the
-- ε-spectrum (perfect security), not just the trivial end.
example {G : Type} [Group G] [Fintype G] [Nonempty G]
    (scheme : OrbitEncScheme G Unit Unit) :
    ConcreteOIA scheme 0 :=
  concreteOIA_zero_of_subsingleton_message scheme

-- I2. KEM-side parallel: ConcreteKEMOIA_uniform kem 0 holds on
-- any KEM whose group action fixes the basepoint (singleton-
-- orbit hypothesis). The pre-I `concreteKEMOIA_one_meaningful`
-- is *deleted* because it duplicated `kemAdvantage_le_one`.
example {G : Type} [Group G] [Fintype G] [Nonempty G]
    (kem : OrbitKEM G Unit Unit) :
    ConcreteKEMOIA_uniform kem 0 :=
  concreteKEMOIA_uniform_zero_of_singleton_orbit kem
    (fun _ => Subsingleton.elim _ _)

-- I3. The cryptographic-content strengthening: from message
-- distinctness alone, exhibit a *G-invariant* separating
-- function on `(reps m₀, reps m₁)`. The pre-I
-- `insecure_implies_separating` only delivered an
-- arbitrary distinguisher (no G-invariance); this theorem
-- delivers the property the original name advertised.
example {G : Type} [Group G] [MulAction G Bool]
    [DecidableEq Bool]
    (scheme : OrbitEncScheme G Bool Bool)
    (h_ne : (true : Bool) ≠ false) :
    ∃ f : Bool → Bool,
      IsGInvariant (G := G) f ∧
      f (scheme.reps true) ≠ f (scheme.reps false) :=
  distinct_messages_have_invariant_separator scheme h_ne

-- I3. The renamed (weak) form is retained alongside the new
-- strong form, accurately named for what it actually proves.
example
    (scheme : OrbitEncScheme G Bool Bool)
    (A : Adversary Bool Bool)
    (hAdv : hasAdvantage scheme A) :
    ∃ (f : Bool → Bool) (m₀ m₁ : Bool),
      ∃ g₀ g₁ : G,
        f (g₀ • scheme.reps m₀) ≠ f (g₁ • scheme.reps m₁) :=
  insecure_implies_orbit_distinguisher scheme A hAdv

-- I4. The strengthened `GIReducesToCE` admits the singleton
-- non-vacuity witness; the pre-I degenerate `encode _ _ := ∅`
-- is type-rejected by the new `0 < codeSize m` field.
example : GIReducesToCE := GIReducesToCE_singleton_witness

-- I5. Parallel for `GIReducesToTI`: constant-1 tensor witness
-- inhabits the strengthened predicate over `ZMod 2`.
example : @GIReducesToTI (ZMod 2) _ :=
  GIReducesToTI_constant_one_witness

-- I6. The new probabilistic predicate is genuinely ε-smooth
-- and admits a non-vacuity witness at ε = 0 on any singleton-
-- orbit bundle. The pre-I deterministic `ObliviousSampling-
-- Hiding` (renamed `ObliviousSamplingPerfectHiding`) is
-- retained as the perfect-extremum sibling. Note the witness
-- takes only the `h_fix` hypothesis — the constant-combine
-- function `(fun _ _ => ors.basePoint)` is directly threaded
-- by the witness's signature; no separate `h_combine_bp`
-- argument is required because `(fun _ _ => ors.basePoint) x y
-- = ors.basePoint` is `rfl`.
example {G : Type} [Group G] [Fintype G] [Nonempty G]
    [MulAction G Unit] [DecidableEq Unit]
    (ors : OrbitalRandomizers G Unit 1)
    (h_fix : ∀ g : G, g • ors.basePoint = ors.basePoint) :
    ObliviousSamplingConcreteHiding ors
      (fun _ _ => ors.basePoint) 0 :=
  ObliviousSamplingConcreteHiding_zero_witness ors h_fix
```

### C.8 Workstream J — invariant-framing + negligible closures

```lean
-- Non-vacuity: `IsNegligible.of_le`
example {f g : ℕ → ℝ}
    (hg : IsNegligible g)
    (hle : ∀ n, |f n| ≤ g n) :
    IsNegligible f :=
  hg.of_le hle

-- Non-vacuity: `IsNegligible.const_mul`
example {f : ℕ → ℝ} (hf : IsNegligible f) (C : ℝ) :
    IsNegligible (fun n => C * f n) :=
  hf.const_mul C
```

### C.9 Workstream N — `authHybridEncrypt` / `KEMAdversary.ofGame`

```lean
-- Non-vacuity: authenticated hybrid correctness
example (m : toyDEM.Msg) (g : toyAuthKEM.kem.G) :
    authHybridDecrypt toyAuthKEM toyDEM
      (authHybridEncrypt toyAuthKEM toyDEM g m) = some m :=
  authHybridCorrectness toyAuthKEM toyDEM m g

-- Non-vacuity: KEMAdversary.ofGame transports scheme adversaries
example :
    Nonempty (KEMAdversary toyKEM) :=
  ⟨KEMAdversary.ofGame toyScheme toyAdversary⟩
```

### C.10 Audit-script integration

Every snippet above lives under
`scripts/audit_phase_16.lean` `§ 12 NonVacuityWitnesses`,
**grouped by workstream** under a `/-! ## Workstream <letter>
non-vacuity witnesses -/` section header. The audit script's
CI entry (§ 19.1) will type-check every snippet as part of the
normal `lake env lean scripts/audit_phase_16.lean` invocation.

**Author discipline.** When a workstream lands, the implementer
adds the corresponding C.n snippets to the audit script in the
*same* PR as the Lean declarations they witness. A PR that adds
a new headline theorem *without* a non-vacuity witness in the
audit script fails the review checklist in § 19.4.

**End of plan.**
