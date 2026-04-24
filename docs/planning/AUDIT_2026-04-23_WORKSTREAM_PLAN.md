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
(**F**+**G**+**H**+**I**+**J**) ≈ **28 hours** more. Polish (**K**+**L**+
**M**+**N**) ≈ **15 hours** more. Total pre-v1.0 engineering budget if
every non-research workstream lands: **~75 hours**. The research milestones
(**O**, R-01 through R-16) are multi-month and explicitly scoped to v1.1+ /
v2.0.

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
| **I** | Naming hygiene: rename `_meaningful` suffix theorems, `insecure_implies_separating`, `GIReducesToCE`/`GIReducesToTI`, `ObliviousSamplingHiding`. Per `CLAUDE.md`'s Security-by-docstring prohibition: renames align identifier-name with proved content. | C-15, E-11, D-07, J-03, J-08, K-02, V1-15 | 4 h | none | preferred |
| **J** | Invariant-attack framing + negligible-function closure: tighten `invariant_attack` statement (D-04/D-13); add `IsNegligible.of_le` / `IsNegligible.const_mul` closure lemmas (G-04, G-05). | D-04, D-05, D-06, D13, G-04, G-05, G-06, V1-16 | 5 h | none | preferred |
| **K** | Root-file split + legacy script relocation: split the 1585-line `Orbcrypt.lean` docstring into `CHANGELOG.md` + `AXIOM_TRANSPARENCY.md`; move per-workstream audit scripts to `scripts/legacy/`. | M-01, M-02, M-03, N-03, N-04, V1-17, V1-18, V1-21 | 6 h | **A**, **I** | polish |
| **L** | Medium-severity structural cleanup: findings without dedicated workstreams — `CanonicalForm` bundled idempotence (B-04), `advantage` `toReal` threading (G-06/G-08), `probEvent`/`probTrue` consolidation (G-01/G-02), `hybridDist` left/right convention (C-14), `AuthOrbitKEM.encaps` triple (I-05), `DEM` security note (I-06), `MAC` metadata (I-02), `Tensor3` bundling (J-10), `SurrogateTensor` universe posture audit (X-04), combiner probabilistic lower bound (K-10/K-11), `hgoeKEM` unconstrained `keyDerive` (F-08), `nonceDecaps` aliasing (H-07), `OrbitalRandomizers` distinctness (K-04), `Hardness/Reductions.lean` split (J-14). Each is a single-file docstring or small-diff edit. | 30+ assorted MED findings | 8 h | none | polish |
| **M** | Low-severity cosmetic polish: docstring tightening (B-01, B-02, B-05, B-06, C-02, C-03, C-09, C-11, C-16, D-01, D-02, D-03, D-08, D-09, E-02, E-03, E-05, F-01, F-02, F-03, F-06, F-07, G-03, G-07, G-09, H-04, H-05, H-06, I-01, I-09, J-02, J-05, J-06, J-07, J-09, J-11, J-13, K-03, K-06, K-08, K-09, L-01, L-02, L-04, L-05, L-06, N-01, N-02, N-05, N-06, P-02, P-03, P-04, X-03, X-04, X-05). | 60+ assorted LOW/INFO findings | 6 h | none | polish |
| **N** | Optional pre-release engineering enhancements: authenticated hybrid layer (I-07/V1-19), `KEMAdversary.ofGame` adapter (E-07/V1-20), K2 design-note consolidation (E-08/V1-22). | V1-19, V1-20, V1-22, I-07, E-07, E-08 | 5 h | **B** | nice-to-have |
| **O** | Research & performance catalogue (NOT engineering deliverables): R-01 through R-16 research milestones, Z-01 through Z-10 performance milestones. Tracked for transparency; content assigned to v1.1+ and v2.0 roadmaps. | R-*, Z-* | n/a | n/a | v1.1+ / v2.0 |
| — | **Totals** | 140+ findings | ≈ 70 h | — | — |

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
adds another ~19 h serial or ~7 h parallel.

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
    subgroup `⟨Equiv.swap 0 1⟩` is `![false, true, true]` (swapping
    positions 0 and 1 gives the lex-smaller bit pattern). -/
-- Evaluation test (expected to reduce by `decide` at compile time):
example :
    let σ : Equiv.Perm (Fin 3) := Equiv.swap 0 1
    let G : Subgroup (Equiv.Perm (Fin 3)) := Subgroup.closure {σ}
    let can := CanonicalForm.ofLexMin G
    can.canon ![true, false, true] = ![false, true, true] := by
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

## 12. Workstream I — Naming hygiene

**Severity.** HIGH (D-07 / J-03 / J-08 / K-02 / V1-15) + MEDIUM
(C-15 / E-11 / V1-15). **Effort.** ≈ 4 h. **Scope.** Renames across
six files; no algorithmic changes.

### 12.1 Problem statement

Per `CLAUDE.md`'s **Security-by-docstring prohibition** and
naming-content rule, a declaration's identifier must describe
what the declaration *proves*, not what it *aspires to* or
*names conventionally*. The 2026-04-23 audit identifies six
identifiers whose names are misleading or overstate the content:

| Pre-I name | Actual content | Post-I name (proposed) | Audit |
|------------|----------------|------------------------|-------|
| `concreteOIA_one_meaningful` | `indCPAAdvantage ≤ 1` (trivially true) | `indCPAAdvantage_le_one` | C-15 |
| `concreteKEMOIA_one_meaningful` | `kemAdvantage ≤ 1` (trivially true) | `kemAdvantage_le_one` | E-11 |
| `insecure_implies_separating` | Existence of a distinguishing Boolean function; does **not** prove G-invariance | `insecure_implies_distinguisher` | D-07 |
| `GIReducesToCE` | Scaffolding-only Prop admitting degenerate encoders | `GIReducesToCE_sketch` (or `GIReducesToCE_existsKarpReduction`) | J-03 |
| `GIReducesToTI` | Same shape as above | `GIReducesToTI_sketch` (analogous) | J-08 |
| `ObliviousSamplingHiding` | Pathological-strength (self-disclosed) | `ObliviousSamplingStrongHiding` | K-02 |

### 12.2 Fix scope

Each rename is a targeted `Edit` across the source module and
every downstream reference (`scripts/`, `docs/`, `CLAUDE.md`).
No proofs change; no axiom dependencies change. Per
`CLAUDE.md`'s no-backwards-compat-shim rule, the old names are
**deleted**, not retained as aliases.

### 12.3 Work units

#### I1 — Rename `_meaningful` suffix theorems (C-15, E-11)

**Files.** `Orbcrypt/Crypto/CompSecurity.lean`,
`Orbcrypt/KEM/CompSecurity.lean`.

**Change.** Rename `concreteOIA_one_meaningful` →
`indCPAAdvantage_le_one`; `concreteKEMOIA_one_meaningful` →
`kemAdvantage_le_one`. Docstrings shifted to match.

**Acceptance.**
- `grep -rn "_meaningful"` returns empty across the repo.
- `lake build` succeeds.
- `#print axioms` output is textually identical modulo the
  declaration-name change.

#### I2 — Rename `insecure_implies_separating` (D-07)

**File.** `Orbcrypt/Theorems/OIAImpliesCPA.lean`.

**Change.** Rename to `insecure_implies_distinguisher` (the
actual theorem content: existence of a distinguishing Boolean
function, *without* G-invariance). Docstring updated to make
the "does not prove G-invariance" caveat its *primary* content.

**Acceptance.** Same as I1.

#### I3 — Rename `GIReducesToCE` / `GIReducesToTI` (J-03, J-08)

**Files.** `Orbcrypt/Hardness/CodeEquivalence.lean`,
`Orbcrypt/Hardness/TensorAction.lean`.

**Decision point.** Three naming options:

- **Option A: `GIReducesToCE_sketch`.** Explicit "sketch"
  suffix; clear but slightly awkward.
- **Option B: `GIReducesToCE_existsKarpReduction`.** Verbose but
  accurate: the Prop is "a Karp reduction exists".
- **Option C: `GIReducesToCE_Prop`.** Marks the Prop as a pure
  abstract predicate (analogous to Mathlib's `MulAction` being
  a typeclass, not a witness).

**Recommendation.** Option A (`_sketch` suffix). Clear,
concise, flags the scaffolding nature at the call site.
Downstream probabilistic counterparts (`*_viaEncoding` Props in
`Hardness/Reductions.lean`) are untouched.

**Acceptance.** Same as I1; Workstream-**A** release-messaging
prose in `CLAUDE.md` and `docs/VERIFICATION_REPORT.md` also
updated to reference the new names.

#### I4 — Rename `ObliviousSamplingHiding` (K-02)

**File.** `Orbcrypt/PublicKey/ObliviousSampling.lean`.

**Change.** Rename to `ObliviousSamplingStrongHiding` (the
adjective "strong" explicitly flags that this is a
pathological-strength hiding Prop). The companion theorem
`oblivious_sampling_view_constant` is renamed to
`oblivious_sampling_view_constant_under_strong_hiding` for
symmetry. Docstring updated with the "the weaker probabilistic
form is research-scope R-12" cross-link.

**Acceptance.** Same as I1.

#### I5 — Sweep downstream references

**Files.** `CLAUDE.md`, `docs/VERIFICATION_REPORT.md`,
`docs/PUBLIC_KEY_ANALYSIS.md`, `DEVELOPMENT.md`,
`Orbcrypt.lean`, `scripts/audit_phase_16.lean`,
`scripts/audit_e_workstream.lean`,
`scripts/audit_print_axioms.lean`, any other file that mentions
the old names.

**Change.** Mechanical `grep | xargs sed` (or manual edits) to
replace every reference. Cross-check: `grep -rn` for each old
name post-change returns empty.

**Acceptance.**
- `grep -rn "concreteOIA_one_meaningful\|concreteKEMOIA_one_meaningful\|insecure_implies_separating\|GIReducesToCE\b\|GIReducesToTI\b\|ObliviousSamplingHiding\b"`
  returns empty across the entire repo (note word boundaries on
  the `GIReducesTo*` and `ObliviousSamplingHiding` matches to
  avoid capturing the renamed `_sketch` / `StrongHiding` forms).

### 12.4 Exit criteria for Workstream I

1. All six renames land cleanly; no old-name references survive.
2. `lake build` succeeds; `#print axioms` outputs differ only in
   declaration-name.
3. External documentation (`CLAUDE.md`, `VERIFICATION_REPORT.md`,
   etc.) references the new names exclusively.
4. `CLAUDE.md` gains a Workstream-I snapshot listing the six
   renames in a table.

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
| **F** (`CanonicalForm.ofLexMin`) | pending | — | — |
| **G** (λ-parameterised key expansion) | pending | — | — |
| **H** (decapsSafe + decryptCompute) | pending | — | — |
| **I** (naming hygiene) | pending | — | — |
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
-- Non-vacuity: ofLexMin computes a lex-min on a concrete bitstring
example :
    let σ : Equiv.Perm (Fin 3) := Equiv.swap 0 1
    let G : Subgroup (Equiv.Perm (Fin 3)) := Subgroup.closure {σ}
    let can : CanonicalForm (↥G) (Bitstring 3) := CanonicalForm.ofLexMin G
    can.canon ![true, false, true] = ![false, true, true] := by
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

### C.7 Workstream I — renamed declarations

```lean
-- Non-vacuity: renamed `_meaningful` → `_le_one` theorems
example : indCPAAdvantage toyScheme toyAdversary ≤ 1 :=
  indCPAAdvantage_le_one toyScheme toyAdversary

example (g₀ g₁ : toyKEM.G) :
    kemAdvantage toyKEM toyKEMAdversary g₀ g₁ ≤ 1 :=
  kemAdvantage_le_one toyKEM toyKEMAdversary g₀ g₁

-- Non-vacuity: the renamed GI ≤ CE scaffolding sketch Prop
example (h : GIReducesToCE_Sketch) : GIReducesToCE_Sketch := h
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
