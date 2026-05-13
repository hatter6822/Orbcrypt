<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Quantum-Hardness Firming Plan (audit 2026-05-13)

**Plan ID.** `AUDIT_2026-05-13_QUANTUM_HARDNESS_FIRMING_PLAN`.
**Audit lineage.** Continuation of the 2026-05-06 structural review
(`docs/dev_history/AUDIT_2026-05-06_STRUCTURAL_REVIEW.md`); orthogonal to the
in-flight R-TI Phase 3 discharge (`docs/planning/AUDIT_2026-04-28_PHASE_3_PROP_DISCHARGE_PLAN.md`)
and the R-05/R-11/R-15 streams in `docs/planning/PLAN_R_05_11_15.md`.
**Status.** Drafted 2026-05-13; pending project-lead acceptance.
**Scope.** Five workstreams (W-Q1 … W-Q5) firming the quantum-hardness
posture identified in the cryptographer's read-out of the same date.

---

## Table of contents

- [§0 Executive summary](#0-executive-summary)
- [§1 Context — the five cryptanalyst findings](#1-context--the-five-cryptanalyst-findings)
- [§2 Workstream summary and dependency graph](#2-workstream-summary-and-dependency-graph)
- [§3 Workstream W-Q1 — HSP_{S_n} → decisional OIA reduction](#3-workstream-w-q1--hsp_sn--decisional-oia-reduction)
- [§4 Workstream W-Q2 — concrete ε<1 witnesses (CFI + Grochow–Qiao)](#4-workstream-w-q2--concrete-1-witnesses-cfi--grochowqiao)
- [§5 Workstream W-Q3 — Q2 / superposition-oracle adversary model](#5-workstream-w-q3--q2--superposition-oracle-adversary-model)
- [§6 Workstream W-Q4 — random QC PAut structural fence](#6-workstream-w-q4--random-qc-paut-structural-fence)
- [§7 Workstream W-Q5 — TensorOIA / MEDS MinRank parameter discipline](#7-workstream-w-q5--tensoroia--meds-minrank-parameter-discipline)
- [§8 Cross-cutting concerns](#8-cross-cutting-concerns)
- [§9 Consolidated risk register](#9-consolidated-risk-register)
- [§10 Sequencing and release-gate alignment](#10-sequencing-and-release-gate-alignment)
- [§11 CI and audit-script updates](#11-ci-and-audit-script-updates)
- [§12 Documentation-parity updates](#12-documentation-parity-updates)
- [§13 Acceptance criteria and signoff](#13-acceptance-criteria-and-signoff)
- [Appendix A — Finding ↔ workstream cross-reference](#appendix-a--finding--workstream-cross-reference)
- [Appendix B — Mathematical references](#appendix-b--mathematical-references)
- [Appendix C — Non-vacuity Lean snippet templates](#appendix-c--non-vacuity-lean-snippet-templates)

---

## 0. Executive summary

The 2026-05-13 cryptographer's review of Orbcrypt's quantum-hardness
conjecture (recorded against `docs/HARDNESS_ANALYSIS.md`,
`docs/DEVELOPMENT.md` §§3.3, 5, 8.2, 8.4.2, 10.6, and
`docs/PARAMETERS.md` §3) identified five firming actions that close
the gap between the project's *informal narrative* of post-quantum
security and the *formal content* delivered by the Lean development:

| ID | Title | Designation | Effort | LOC (Lean) | Docs |
|----|-------|-------------|-------:|----------:|-----:|
| W-Q1 | HSP_{S_n} → decisional OIA reduction | Engineering | 5–7 wk | ~1100 | ~70 |
| W-Q2 | ε<1 encoders: CFI (R-03) + Grochow–Qiao (R-02) | Engineering | 9–11 wk | ~2000 | ~120 |
| W-Q3 | Q2 / superposition-oracle adversary model | **Research-scope (R-Q3)** | 7–9 wk | ~1000 | ~650 |
| W-Q4 | Random QC PAut structural fence | Engineering + empirical | 5–7 wk | ~550 | ~580 + 450 GAP |
| W-Q5 | TensorOIA / MEDS parameter discipline | Process + light engineering | 3–4 wk | ~150 | ~500 + 100 Py |

**Totals.** ~4800 LOC of new Lean across ~11 new files (plus the
audit-script extension), ~1900 lines of new canonical
documentation, ~500 lines of new GAP cryptanalysis tooling, ~100
lines of new CI Python, distributed across ~6 months of calendar
time at single-thread pace and ~3.5 months with the parallelisation
laid out in §10.

The "LOC (Lean)" column above is the *core-component* count
(structures, definitions, headline theorems). The per-workstream
tables in §§3.4, 4.6, 5.4, 6.6, 7.6 include audit-script entries,
ε=1 inhabitation witnesses, and small additive corollaries; their
totals are ~10–20% higher than the core figures.

**Headline deliverables on plan completion.**

1. A machine-checked Lean reduction
   `concrete_hsp_sn_implies_concrete_oia` carrying the project's
   quantum-hardness narrative from "informal HSP_{S_n} ⇒ OIA argument"
   to "formal contrapositive reduction with a quantitative ε-transfer".
2. The first ε < 1 witness at any layer of the
   `ConcreteHardnessChain` — a conditional theorem
   `cfi_hardness_implies_concreteGIOIA_eps_lt_one` discharged under
   an explicit `CFIHardness` `Prop` hypothesis (closing R-03's
   formalisation gate, with the hardness assumption itself still
   research-scope).
3. A Lean stub framework for the Q2 (quantum-oracle) adversary model
   plus a canonical analysis document `docs/Q2_MODEL_ANALYSIS.md`
   surfacing the gap between Q1 (classical-oracle) and Q2 security
   for HGOE — tracked as research milestone R-Q3.
4. A structural-soundness fence in the keygen pipeline:
   `IsStructurallyNonAbelian` Lean predicate, GAP keygen rejection
   of abelian-collapse keys, empirical PAut-distribution study in
   `docs/QC_PAUT_DISTRIBUTION.md`, and a Lean
   `abelian_PAut_implies_oia_break_under_shorAbelianHidden` theorem
   (Conditional on a research-scope `ShorAbelianHiddenAttack`
   predicate) that formalises the *necessity* of the fence.
5. A process gate that prevents ε < 1 instantiation of
   `ConcreteTensorOIA` without a documented MinRank / ATFE
   complexity-estimate review — enforced by both CI script and Lean
   `TensorOIAParameterReview` carrier structure.

**Headline non-goals.** This plan does *not* attempt to prove
unconditional quantum hardness of any of the underlying problems
(GI, CE, MCE/ATFE, TI, HSP_{S_n}); those remain open in the
literature and the plan is explicit that the corresponding Lean
content is conditional on Prop-valued hardness hypotheses. The plan
also does *not* add a quantum-computation framework to Lean/Mathlib;
Q2-model formalisation in W-Q3 is structural scaffolding only, with
quantum semantics carried implicitly.

**Release-gate alignment.** The plan deliberately does not block the
2026-05-06 structural review's closure or the R-TI Phase 3 discharge
plan. W-Q5 (TensorOIA parameter discipline) is a *prerequisite* for
any future R-02 / R-15 closure that lands a non-trivial
`ConcreteTensorOIA` ε < 1 witness, but is itself non-blocking on
current `tight_one_exists`-style ε = 1 content. The full plan can
be sequenced after the 2026-05-06 review completes.

---

## 1. Context — the five cryptanalyst findings

The cryptographer's read-out of 2026-05-13 raised five technical
findings against the current quantum-hardness story. Each is named
below with a stable finding ID (QH-01 … QH-05) for cross-referencing
through the rest of this document.

### QH-01 — HSP_{S_n} → OIA reduction is informal

**Source.** `docs/DEVELOPMENT.md` §§5.4.2 (point 1), §8.4.2 (pillar 2),
`docs/HARDNESS_ANALYSIS.md` §4.2.3 Barrier 1, §4.1 item 2 (table row
`HSP on S_n`). The Moore–Russell–Schulman 2008 / Hallgren–
Russell–Ta-Shma 2003 negative results are correctly cited, but the
*reduction* from HSP_{S_n} hardness to the decisional OIA assumption
the scheme actually depends on is articulated in prose only.

**Concrete content gap.** The Lean codebase carries no `ConcreteHSPSn`
predicate, no `HSPToOIAEncoder` construction, and no theorem of the
shape `ConcreteHSPSn H₀ H₁ ε → ConcreteOIA (hspEncoder …) ε'`. The
multi-query analysis in `docs/DEVELOPMENT.md` §8.2 invokes
`Q · Adv^{HSP}` informally without a corresponding Lean definition of
`Adv^{HSP}`.

**Severity.** The narrative pillar (DEVELOPMENT.md §8.4.2 pillar 2)
is one of the three load-bearing claims for the project's
post-quantum posture; failing to formalise the link is a
release-messaging risk.

**Closes via.** Workstream W-Q1 (§3).

### QH-02 — ε < 1 reductions are inhabited only at ε = 1

**Source.** `docs/HARDNESS_ANALYSIS.md` §3 and `Hardness/Reductions.lean`
(`ConcreteHardnessChain.tight_one_exists`,
`tight_one_exists_at_s2Surrogate`). The release-messaging policy in
`CLAUDE.md` correctly fences external claims with the explicit
"inhabited only at ε = 1 via trivial witness; ε < 1 requires
research-scope follow-up R-02 / R-03 / R-04 / R-05" disclosure, but
this is a *messaging* fence — the underlying content gap is that
the ε < 1 satisfiability of `ConcreteHardnessChain` is not
demonstrated anywhere in the Lean tree.

**Concrete content gap.** No CFI graph construction lives in the
codebase. The Grochow–Qiao Karp reduction
(`Hardness/GrochowQiao.lean`) proves
`@GIReducesToTI ℚ _` as a *Karp* reduction at the
graph-isomorphism / tensor-isomorphism set-level, but does **not**
lift that to an OIA-preserving encoder of the shape required by
`ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`.

**Severity.** This is the project's largest release-readiness gap.
Quantitative-at-ε=1 results are technically true but uninformative;
no current Lean content quantitatively rules out an adversary with
advantage 0.999.

**Closes via.** Workstream W-Q2 (§4).

### QH-03 — Q2 / superposition-oracle model unaddressed

**Source.** `docs/DEVELOPMENT.md` §8.4.2 implicit Q1 framing;
`docs/PARAMETERS.md` §3 ‡ correctly distinguishes Q1 vs Q2 for the
GMAC analysis but does not extend the discussion to HGOE itself.
The Moore–Russell–Schulman negative result *as deployed inside
HGOE* targets a specific hidden-subgroup family (single-involution
hidden subgroups arising from GI); the PAut-of-quasi-cyclic-code
hidden-subgroup family relevant to HGOE has a different
representation-theoretic profile that warrants its own analysis.

**Concrete content gap.** No Q2 game shape in Lean; no analysis
document; no Lean predicate for Q2-adversary advantage.

**Severity.** Open in the literature; not actionable as a
"prove quantum hardness" task, but actionable as a "formal-shape
the question and document the gap" task.

**Closes via.** Workstream W-Q3 (§5), designated research-scope R-Q3.

### QH-04 — Random QC PAut may be abelian-degenerate

**Source.** `docs/DEVELOPMENT.md` §6.2 (Stage 2 — QC code generation);
`docs/PARAMETERS.md` §4 (algebraic-folding fence at `n/b ≥ λ`). The
quasi-cyclic structure *guarantees* the cyclic-shift subgroup is in
PAut(C), so `|PAut(C)| ≥ ℓ` is enforced; what is *not* enforced is
that PAut(C) has a non-trivial non-abelian piece beyond the cyclic
shifts. For a "random" QC code generated by sampling random
circulant generator blocks, `PAut(C)` may with high probability
*equal* the cyclic-shift subgroup, in which case the hidden subgroup
is abelian — and Shor's algorithm on the abelian HSP cleanly breaks
the orbit-distinguishing problem.

**Concrete content gap.** The GAP keygen pipeline does not measure
or filter on `|PAut(C)| / ℓ`; no Lean predicate witnesses structural
non-abelianness; no empirical study of the PAut distribution at the
recommended parameters.

**Severity.** If the empirical study shows random QC codes
generically have small PAut (close to the cyclic-shift floor), this
is a *parameter-soundness* finding requiring keygen-pipeline
revision. If it shows PAut is typically large, the finding closes
with a documented empirical fence.

**Closes via.** Workstream W-Q4 (§6).

### QH-05 — TensorOIA needs parameter discipline before ε < 1 lands

**Source.** `docs/HARDNESS_ANALYSIS.md` §4.2.4(c) — the ATFE / MinRank
attack landscape is younger than PEP / CE cryptanalysis and continues
to improve yearly. The current `tight_one_exists` ε = 1 witness is
trivial and unaffected, but any future R-15 follow-on landing a
concrete ε < 1 `ConcreteTensorOIA` instance must be cross-checked
against the latest MEDS Round-2 cryptanalysis state.

**Concrete content gap.** No formal gate, in either CI or Lean,
prevents an ε < 1 `ConcreteTensorOIA` instantiation from landing
without a current parameter review.

**Severity.** Process / governance finding. Low technical risk
*now*, high prospective risk once R-15 closes.

**Closes via.** Workstream W-Q5 (§7).

### Finding-to-narrative-pillar map

| Finding | DEVELOPMENT.md §8.4.2 pillar | Affected canonical doc | Affected Lean module |
|---------|------------------------------|------------------------|----------------------|
| QH-01 | 2 (HSP_{S_n} hard quantumly) | DEVELOPMENT.md §§5.4.2, 8.2, 8.4.2 | `Hardness/HSPSubgroup.lean` (new) |
| QH-02 | 1, 3 (GI not in BQP; CE no quantum speedup) | HARDNESS_ANALYSIS.md §3, API_SURFACE.md headline table | `Hardness/CFI/*.lean` (new), `Hardness/GrochowQiaoOIA.lean` (new) |
| QH-03 | All three pillars (Q2-model lens) | DEVELOPMENT.md §8.4.2 (new sub-section), `docs/Q2_MODEL_ANALYSIS.md` (new) | `Crypto/Q2Game.lean` (new) |
| QH-04 | 2 (HSP_{S_n} hard) — keygen-soundness leg | PARAMETERS.md §4, DEVELOPMENT.md §6.2 | `KeyMgmt/StructuralFence.lean` (new), GAP keygen update |
| QH-05 | 3 (CE / MCE / ATFE no quantum speedup) | HARDNESS_ANALYSIS.md §4.2.4(c), new `docs/TENSOR_OIA_PARAMETER_DISCIPLINE.md` | `Hardness/TensorOIAParameterFence.lean` (new) |

---

## 2. Workstream summary and dependency graph

### 2.1 Summary table

| Workstream | Closes | Designation | Total LOC | New files (Lean) | Effort |
|------------|--------|-------------|----------:|----------------:|-------:|
| W-Q1 | QH-01 | Engineering | ~1100 | 2 | 5–7 wk |
| W-Q2 | QH-02 | Engineering (Conditional theorems) | ~2000 | 5 | 9–11 wk |
| W-Q3 | QH-03 | Research-scope R-Q3 | ~1000 | 2 | 7–9 wk |
| W-Q4 | QH-04 | Engineering + empirical | ~550 | 1 | 5–7 wk |
| W-Q5 | QH-05 | Process + light engineering | ~150 | 1 | 3–4 wk |
| **Total** | | | **~4800** | **11** | |

### 2.2 Dependency graph

```
       ┌────────────────────────────────────────────────────┐
       │  Existing 2026-05-06 structural review baseline    │
       │  (post-W6 probabilistic chain is canonical)        │
       └─────┬────────────────┬────────────────┬────────────┘
             │                │                │
             ▼                ▼                ▼
        W-Q1 (Path B)    W-Q2 (Path A)    W-Q4 (Path B)
       HSP_{S_n}→OIA    ε<1 encoders     PAut fence
             │                │                │
             │   one-way      │                │
             │   import       │                │
             └────────────────│────── W-Q4 ────┘
                              │  (Q4.B.1 must precede
                              │   Q1.4 consumption)
                              ▼
                          W-Q5 (Path A)
                          Tensor param
                          discipline

  W-Q3 (Path C, research-scope) — independent of A and B
```

**Critical paths.**

- **Path A (release-blocking).** W-Q2 → W-Q5 chains the ε < 1
  encoders to the TensorOIA parameter fence. Any future tag that
  ships a non-trivial `ConcreteHardnessChain` ε < 1 witness must
  complete both. Estimated wall-clock with parallel staffing:
  10–12 weeks.
- **Path B (narrative-firming).** W-Q1 and W-Q4 firm the
  HSP_{S_n} narrative pillar and the keygen-soundness leg.
  Mostly parallel; W-Q4.B.1 must land before W-Q1's bundle
  construction consumes
  `structurally_non_abelian_yields_orbit_distinct_pairs`.
  Estimated wall-clock with parallel staffing: 6–8 weeks.
- **Path C (research-scope).** W-Q3 is parallelisable with all of
  A and B; its closure is non-blocking on release.

### 2.3 Workstream-to-finding closure matrix

| Finding | W-Q1 | W-Q2 | W-Q3 | W-Q4 | W-Q5 |
|---------|:----:|:----:|:----:|:----:|:----:|
| QH-01 (HSP→OIA reduction)            | ✅ closes | partial (via §3.3.5 cross-ref) | — | — | — |
| QH-02 (ε<1 witnesses)                | — | ✅ closes | — | — | — |
| QH-03 (Q2 model)                     | — | — | ✅ closes (R-Q3) | — | — |
| QH-04 (PAut abelian-degeneracy)      | partial (via §3.5 cross-ref) | — | — | ✅ closes | — |
| QH-05 (Tensor parameter discipline)  | — | partial (via §4.7) | — | — | ✅ closes |

### 2.4 Naming-rule pre-clearance

All Lean declarations introduced by this plan satisfy the
"Names describe content, never provenance" rule
(`CLAUDE.md` § Naming conventions). The workstream identifiers
(`W-Q1` … `W-Q5`) and finding IDs (`QH-01` … `QH-05`) are used
exclusively in planning documents, changelog entries, commit
messages, and docstring traceability notes — never in the names
of `def` / `theorem` / `structure` / `class` / `instance` /
`abbrev` / `lemma` declarations. See Appendix C for the canonical
declaration-name patterns each workstream introduces.

---

## 3. Workstream W-Q1 — HSP_{S_n} → decisional OIA reduction

### 3.1 Problem statement

The narrative in `docs/DEVELOPMENT.md` §8.4.2 pillar 2 and the
multi-query analysis in §8.2 (the `Q · Adv^{HSP}` term in the
hybrid bound at line 1048) both invoke the conjectured quantum
hardness of the Hidden Subgroup Problem on `S_n` as the
load-bearing assumption underpinning HGOE's resistance to
quantum attacks via group recovery. The Lean codebase, as of
2026-05-13, has no formal counterpart to this assumption: there
is no `HSPInstance` structure, no `hspDecisionalAdvantage`
function, no `ConcreteHSPSn` predicate, and no theorem of the
shape

> `ConcreteHSPSn H₀ H₁ ε  →  ConcreteOIA (hspToOIAEncoder H₀ H₁ x₀ x₁) ε'`

connecting the assumption to the decisional OIA the scheme
actually depends on.

The cryptanalytic gap (§1, finding QH-01) is twofold:

1. **Encoding shape.** The function-version of HSP_{S_n}
   relevant to HGOE is *not* the canonical "function constant on
   left cosets" form. The HGOE-relevant function is
   `f_x : S_n → Bitstring n`, `σ ↦ σ · x`, whose fibres are
   *right* cosets of `Stab(x) ≤ S_n` — not cosets of the secret
   subgroup `G ≤ S_n` that the adversary tries to recover.
   Recovering `G` from samples is a coset-intersection problem
   (find `G` such that the samples lie in `G · x` for known
   public `x`), not a textbook HSP instance. The reduction in
   W-Q1 must commit to a precise encoding.
2. **Direction.** The cryptographically useful direction is
   *contrapositive*: HSP hard ⇒ OIA hard. The Lean-stateable
   theorem is therefore "OIA adversary lifts to HSP solver":
   given an OIA distinguisher of advantage δ, construct an HSP
   decisional algorithm of advantage δ′ = f(δ, n). The
   contrapositive then delivers the prose claim.

### 3.2 Fix selection

**Selected approach: decisional-HSP encoding.** The reduction
formalises the *decisional* variant of HSP_{S_n}:

> **Definition.** `decisional HSP_{S_n}(H₀, H₁)`: given a
> function `f : S_n → Y` promised to be constant on right
> cosets of either `H₀` or `H₁` (both subgroups of `S_n`), and
> given oracle access to `f`, decide which subgroup `f` is
> constant-on-cosets of.

Three reasons for this selection over the search variant:

1. **Probabilistic parity.** `ConcreteOIA scheme ε` is itself a
   decisional advantage bound; the OIA-to-HSP reduction stays
   in the decisional advantage idiom throughout, avoiding the
   structural-search-to-decision conversion as a separate
   obligation.
2. **Existing literature alignment.** Hallgren–Russell–Ta-Shma
   2003 and Moore–Russell–Schulman 2008 both target the
   decisional variant for `S_n`, so the Lean assumption shape
   matches the cited negative results.
3. **Reduction symmetry.** The reduction from a decisional OIA
   distinguisher to a decisional HSP distinguisher is one-shot
   and oracle-free: the OIA-adversary's view *is* a sample from
   one of two coset-induced distributions. The search variant
   requires a self-reducibility argument that adds work without
   tightening the bound.

**Excluded alternatives.**

- Encoding the HSP instance *as an axiom* and proving OIA from
  it: rejected because `CLAUDE.md` enforces zero custom
  `axiom`s; an axiomatic HSP_{S_n} statement is also strictly
  weaker than what the cryptanalytic narrative needs (the
  narrative needs a *concrete reduction*, not an opaque axiom).
- Stating the reduction only at the asymptotic
  `Adv = negl(λ)` level: rejected because the rest of the
  Hardness chain post-W6 is quantitative (`ConcreteOIA … ε`,
  `ConcreteHardnessChain`, the `_advantage_bound` theorems).
  Asymptotic-only content does not compose with the surrounding
  quantitative chain.

### 3.3 Target API shape (post-fix)

Two new Lean modules.

**`Orbcrypt/Hardness/HSPSubgroup.lean`** carries the assumption-shape
content — definitions, advantage notions, sanity lemmas. ~450 LOC.

```lean
/-- A decisional HSP_{S_n} instance: two candidate hidden subgroups
    and a function promised to be constant on right cosets of one
    of them. -/
structure HSPDecisionalInstance
    (n : ℕ) (Y : Type*) [Fintype Y] [DecidableEq Y] where
  H₀ : Subgroup (Equiv.Perm (Fin n))
  H₁ : Subgroup (Equiv.Perm (Fin n))
  decH₀ : DecidablePred (· ∈ H₀)
  decH₁ : DecidablePred (· ∈ H₁)
  /-- The promised function family: index 0 means f constant on
      right cosets of H₀; index 1, on right cosets of H₁. -/
  f₀ : Equiv.Perm (Fin n) → Y
  f₁ : Equiv.Perm (Fin n) → Y
  f₀_const_on_cosets : ∀ σ τ, σ ∈ H₀.carrier.image (· * τ) → f₀ σ = f₀ τ
  f₁_const_on_cosets : ∀ σ τ, σ ∈ H₁.carrier.image (· * τ) → f₁ σ = f₁ τ

/-- Distinguisher type: receives a list of (σ, f(σ)) pairs and
    outputs a bit guessing which of H₀ / H₁ is the hidden subgroup. -/
structure HSPDistinguisher
    (n : ℕ) (Y : Type*) [Fintype Y] [DecidableEq Y] (Q : ℕ) where
  decide :
    (Fin Q → Equiv.Perm (Fin n) × Y) → Bool

/-- Probability-mass advantage of the distinguisher on the two
    hidden-subgroup hypotheses, taken over Q uniform queries. -/
noncomputable def hspDecisionalAdvantage
    {n Q : ℕ} {Y : Type*} [Fintype Y] [DecidableEq Y]
    (inst : HSPDecisionalInstance n Y)
    (D : HSPDistinguisher n Y Q) : ℝ := ...

/-- Concrete decisional HSP_{S_n} hardness predicate at advantage
    bound ε. -/
def ConcreteHSPSn
    {n : ℕ} {Y : Type*} [Fintype Y] [DecidableEq Y]
    (inst : HSPDecisionalInstance n Y) (Q : ℕ) (ε : ℝ) : Prop :=
  ∀ D : HSPDistinguisher n Y Q,
    hspDecisionalAdvantage inst D ≤ ε

/-- ε = 1 is the trivial upper bound (every distinguisher has
    advantage ≤ 1). -/
theorem concreteHSPSn_one
    {n Q : ℕ} {Y : Type*} [Fintype Y] [DecidableEq Y]
    (inst : HSPDecisionalInstance n Y) :
    ConcreteHSPSn inst Q 1 := ...

/-- Monotonicity: if hard at ε, also hard at any larger ε'. -/
theorem concreteHSPSn_mono
    {n Q : ℕ} {Y : Type*} [Fintype Y] [DecidableEq Y]
    (inst : HSPDecisionalInstance n Y)
    {ε ε' : ℝ} (hε : ε ≤ ε') :
    ConcreteHSPSn inst Q ε → ConcreteHSPSn inst Q ε' := ...
```

**`Orbcrypt/Hardness/HSPToOIA.lean`** carries the reduction. ~650
LOC.

```lean
/-- Bundle of data that turns a decisional HSP instance into an
    OIA challenge: a base bitstring whose H₀ and H₁ orbits are
    distinct. -/
structure HSPOIABundle
    (n : ℕ) (Y : Type*) [Fintype Y] [DecidableEq Y] where
  inst : HSPDecisionalInstance n Y
  basePoint : Bitstring n
  /-- Orbit-distinctness: the H₀-orbit and H₁-orbit of basePoint
      differ as sets. Without this hypothesis the OIA distinguisher
      cannot extract any signal. -/
  orbits_distinct :
    MulAction.orbit inst.H₀ basePoint ≠ MulAction.orbit inst.H₁ basePoint

/-- The OIA-encoding of an HSP bundle: produces an `OrbitEncScheme`
    on `(Equiv.Perm (Fin n))`, `Bitstring n`, `Fin 2`, where the
    two message orbits are the H₀- and H₁-orbits of `basePoint`. -/
def hspOIABundleToScheme
    {n : ℕ} {Y : Type*} [Fintype Y] [DecidableEq Y]
    (B : HSPOIABundle n Y) :
    OrbitEncScheme (Equiv.Perm (Fin n)) (Bitstring n) (Fin 2) := ...

/-- The headline reduction. An OIA distinguisher of advantage ≥ δ
    on the HSP-encoded scheme lifts to an HSP decisional
    distinguisher of advantage ≥ δ. The Q (query count) parameter
    matches because the OIA encoding produces a single-query
    instance per HSP query. -/
theorem oia_distinguisher_lifts_to_hsp_distinguisher
    {n : ℕ} {Y : Type*} [Fintype Y] [DecidableEq Y]
    (B : HSPOIABundle n Y)
    (A : Adversary (Bitstring n) (Fin 2))
    {δ : ℝ}
    (h_adv : indCPAAdvantage (hspOIABundleToScheme B) A ≥ δ) :
    ∃ D : HSPDistinguisher n Y 1,
      hspDecisionalAdvantage B.inst D ≥ δ := ...

/-- Contrapositive form: HSP hard ⇒ OIA hard. The cryptographically
    useful direction. -/
theorem concrete_hsp_sn_implies_concrete_oia
    {n : ℕ} {Y : Type*} [Fintype Y] [DecidableEq Y]
    {ε : ℝ}
    (B : HSPOIABundle n Y)
    (h_hsp : ConcreteHSPSn B.inst 1 ε) :
    ConcreteOIA (hspOIABundleToScheme B) ε := ...

/-- Trivial inhabitation: at ε = 1, the chain is trivially
    inhabited (both predicates hold for every instance).
    Parallel to `tight_one_exists` in `Hardness/Reductions.lean`. -/
theorem hsp_to_oia_chain_at_one_exists :
    ∃ (n : ℕ) (Y : Type*) (_ : Fintype Y) (_ : DecidableEq Y)
      (B : HSPOIABundle n Y),
        ConcreteHSPSn B.inst 1 1 ∧
        ConcreteOIA (hspOIABundleToScheme B) 1 := ...
```

**Multi-query integration with `Crypto/CompSecurity.lean`.** The
multi-query hybrid bound at `Crypto/CompSecurity.lean:288–390`
(`MultiQueryAdversary`, `single_query_bound`, `perQueryAdvantage`,
`indQCPA_from_perStepBound`) currently consumes a per-step ε bound
as an explicit hypothesis. W-Q1 leaves the multi-query module
*structurally untouched* but adds an interpretive corollary
`indQCPA_bound_from_hsp_sn_hardness` that exhibits how a caller
who has both `ConcreteHSPSn` at small ε *and* a per-step independence
proof (R-09 follow-on) can discharge the `perQueryAdvantage` bound.

### 3.4 Work units

| ID | Title | Type | LOC | Risk | Depends on |
|----|-------|------|----:|------|------------|
| Q1.1 | `HSPDecisionalInstance` structure + Decidable wiring | Lean def | 120 | Low | — |
| Q1.2 | `HSPDistinguisher` + `hspDecisionalAdvantage` | Lean def | 180 | Low | Q1.1 |
| Q1.3 | `ConcreteHSPSn` predicate + sanity lemmas | Lean def + thm | 150 | Low | Q1.2 |
| Q1.4 | `HSPOIABundle` structure + `orbits_distinct` carrier | Lean def | 100 | Low | Q1.1 |
| Q1.5 | `hspOIABundleToScheme` encoder + scheme correctness | Lean def + thm | 220 | Med | Q1.4 |
| Q1.6 | `oia_distinguisher_lifts_to_hsp_distinguisher` reduction | Lean thm | 260 | Med | Q1.3, Q1.5 |
| Q1.7 | `concrete_hsp_sn_implies_concrete_oia` contrapositive | Lean thm | 80 | Low | Q1.6 |
| Q1.8 | `hsp_to_oia_chain_at_one_exists` ε=1 inhabitation | Lean thm | 90 | Low | Q1.7 |
| Q1.9 | `indQCPA_bound_from_hsp_sn_hardness` interpretive corollary | Lean thm | 90 | Low | Q1.7, existing R-09 stub |
| Q1.10 | Audit script entries (`scripts/audit_phase_16.lean` §15.26) | Lean script | 50 | Low | Q1.7, Q1.8 |
| Q1.11 | Doc-parity: DEVELOPMENT.md §§5.4.2, 8.2, 8.4.2; HARDNESS_ANALYSIS.md §1.6 stub | Doc | 70 | Low | Q1.7 |
| Q1.12 | Doc-parity: API_SURFACE.md headline-table row addition | Doc | 30 | Low | Q1.7 |
| **Q1 total** | | | **~1440** | | |

**Risk-Med notes.**

- *Q1.5 — encoder correctness.* The encoder must produce a
  syntactically valid `OrbitEncScheme` with the two message
  orbits witnessed as disjoint. The disjointness is exactly the
  `orbits_distinct` hypothesis on the bundle; the encoder threads
  it through `hgoeScheme.ofLexMin`-style constructor pattern
  (`Construction/HGOE.lean:114`). Risk: the existing `OrbitEncScheme`
  shape may need a minor refinement to admit two-orbit instances
  cleanly. If so, refactor lives in
  `Crypto/Scheme.lean` and is scoped to ≤ 30 LOC of additive
  changes (no breaking signature changes).
- *Q1.6 — reduction proof.* The proof translates an OIA
  adversary's `choose` + `guess` into an HSP distinguisher by:
  (i) running `choose` to obtain `(0, 1)` (the two HSP indices);
  (ii) sampling a uniform `σ ← S_n`; (iii) computing `σ · basePoint`
  using the bundle's `H₀` or `H₁` (depending on which is hidden);
  (iv) feeding `(σ, σ · basePoint)` to `guess`. The probabilistic
  step is bounding `hspDecisionalAdvantage` from below by
  `indCPAAdvantage`, which follows from `orbits_distinct` plus
  the `concrete_oia_implies_1cpa` (`Crypto/CompSecurity.lean:200`)
  argument structure adapted to the HSP side. The probabilistic
  bookkeeping is the source of the Med risk classification —
  similar in spirit to the `concrete_oia_implies_1cpa` proof but
  with one extra level of conditioning.

### 3.5 Cross-cutting with W-Q4

The `orbits_distinct` hypothesis on `HSPOIABundle` is precisely
the structural-soundness property W-Q4 (§6) operationalises in
the keygen pipeline. The cross-reference:

- W-Q4's `IsStructurallyNonAbelian` predicate (§6.3) implies
  (via a separate lemma `structurally_non_abelian_yields_orbit_distinct_pairs`)
  that the H₀ = {1}, H₁ = PAut(C) case of `HSPOIABundle` is
  inhabitable — i.e., a non-trivially-non-abelian PAut gives the
  reduction a non-vacuous instance.
- Conversely, W-Q4's `abelian_PAut_implies_oia_break_under_shorAbelianHidden`
  theorem (§6.4) uses Q1's `concrete_hsp_sn_implies_concrete_oia`
  in the *negative direction*: if PAut is abelian, the abelian-HSP
  Shor reduction yields δ ≈ 1 advantage, and Q1's reduction
  exhibits this as `ConcreteOIA ≥ 1 - negl`.

These cross-references are encoded as `private` Lean lemmas in
their respective modules and import-cycle-free (Q1 → Q4 is one-way
in Lean; the Q4-side lemma `structurally_non_abelian_yields_orbit_distinct_pairs`
imports Q1's `HSPOIABundle` but Q1 does not import Q4 content).

### 3.6 Risk register and rollback

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| `Subgroup.carrier.image (· * τ)` API friction in coset-constant predicate | Med | Low | Switch to Mathlib's `Subgroup.rightCoset` API directly. |
| Encoder produces vacuous scheme (orbits coincide despite hypothesis) | Low | High | The `orbits_distinct` hypothesis is the explicit witness; vacuity-check via `MulAction.orbit_eq_iff` is automated. |
| Reduction bound is loose by factor of 2 (collision-choice handling) | Med | Low | Adopt `indCPAAdvantage_collision_zero` (`Crypto/CompSecurity.lean:158`) pattern; the factor-of-2 is absorbed in the centered-vs-two-distribution convention. |
| Q1.10 audit script discovers `sorryAx` in transitive dependency | Low | High | Standard `#print axioms` discipline catches this at CI time. |

**Rollback.** Pure additive: deleting all Q1.1–Q1.12 leaves the
codebase byte-identical to its pre-plan state. No existing
declarations are modified destructively. The doc updates in Q1.11,
Q1.12 are additive sections that can be reverted independently.

### 3.7 Exit criteria for Workstream W-Q1

W-Q1 closes when **all** of the following are demonstrably true:

1. `lake build Orbcrypt.Hardness.HSPSubgroup` and
   `lake build Orbcrypt.Hardness.HSPToOIA` succeed clean (zero
   warnings, zero `sorry`, zero new `axiom`).
2. `concrete_hsp_sn_implies_concrete_oia` is declared and proved
   in `Orbcrypt/Hardness/HSPToOIA.lean`.
3. `hsp_to_oia_chain_at_one_exists` is declared, proved, and
   exhibited as a `#print axioms` line in
   `scripts/audit_phase_16.lean` §15.26 yielding the canonical
   `[propext, Classical.choice, Quot.sound]` triple.
4. `indQCPA_bound_from_hsp_sn_hardness` is declared and proved
   in `Orbcrypt/Crypto/CompSecurity.lean` (additive new lemma at
   the end of the file).
5. `docs/DEVELOPMENT.md` §§5.4.2, 8.2, 8.4.2 are updated to cite
   `concrete_hsp_sn_implies_concrete_oia` by name with file
   path, status classification (`Conditional` on
   `ConcreteHSPSn`), and ε-disclosure.
6. `docs/HARDNESS_ANALYSIS.md` adds a new §1.6 row
   "HSP_{S_n} (decisional)" to the problem-definition catalogue
   and a new §3.x sub-section "HSP-to-OIA reduction" tracking
   the new chain entry, with both the definition and the
   contrapositive statement reproduced verbatim.
7. `docs/API_SURFACE.md` adds two new rows to the
   headline-theorem table: one for
   `concrete_hsp_sn_implies_concrete_oia` (Status: **Conditional**
   on `ConcreteHSPSn`), one for `hsp_to_oia_chain_at_one_exists`
   (Status: **Standalone** at ε = 1).
8. `docs/dev_history/WORKSTREAM_CHANGELOG.md` carries a
   W-Q1 entry with per-commit traceability.
9. CI gate #6 (`scripts/audit_phase_16.lean`) passes with the new
   section appended.

---

## 4. Workstream W-Q2 — concrete ε<1 witnesses (CFI + Grochow–Qiao)

### 4.1 Problem statement

The post-W6 probabilistic reduction chain
(`Hardness/Reductions.lean:572` `ConcreteHardnessChain`,
`:707` `tight_one_exists`, `:757` `tight_one_exists_at_s2Surrogate`)
is inhabited only at ε = 1 in the current Lean tree. The
release-messaging policy in `CLAUDE.md` correctly fences external
claims of the headline theorem
`concrete_hardness_chain_implies_1cpa_advantage_bound`
(`Hardness/Reductions.lean:812`) with the explicit ε = 1 disclosure,
but the underlying *content* gap is unchanged: there is no Lean
demonstration that the chain can be inhabited at any non-trivial
ε < 1 for any (surrogate, encoder, scheme) triple.

The two research-scope milestones `R-02` (Grochow–Qiao
structure-tensor ε < 1 witness) and `R-03` (CFI gadget for
GI-OIA ε < 1 witness) are the canonical closure paths. The
2026-04-25 R-15 Karp-reductions plan
(`docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`)
delivered the Grochow–Qiao Karp reduction at the *set-level*
(`@GIReducesToTI ℚ _`); the unfinished step is lifting that to
an *OIA-preserving encoder* of the shape required by
`ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`
(`Hardness/Reductions.lean:334`).

The cryptanalytic gap (§1, finding QH-02) has two distinct
pieces:

1. **CFI (R-03).** No CFI graph construction exists in the
   codebase. The Cai–Fürer–Immerman 1992 construction is named
   in `docs/DEVELOPMENT.md` §5.3.1 but lives only in prose.
2. **Grochow–Qiao OIA-lift (R-02).** The Karp reduction
   `grochowQiao_isInhabitedKarpReduction_under_rigidity`
   (`Hardness/GrochowQiao.lean:298`) proves
   `GI(G₁, G₂) ↔ TI(encode G₁, encode G₂)` at the
   *decision* level (conditional on `GrochowQiaoRigidity`,
   tracked for unconditional closure by
   `docs/planning/AUDIT_2026-04-28_PHASE_3_PROP_DISCHARGE_PLAN.md`),
   but not the orbit-preservation that
   `OrbitPreservingEncoding` (`Hardness/Encoding.lean`)
   requires for the OIA chain.

### 4.2 Fix selection

**Selected approach: parallel CFI + GQ-OIA lift.** Both legs
land independently as additive Lean modules. Each delivers a
*conditional* ε < 1 witness — conditional on a `Prop`-valued
hardness hypothesis (CFI hardness for the CFI leg; GI-OIA
hardness for the GQ-lift leg). Neither attempts to prove the
underlying hardness assumption itself; both reduce the problem
to a Mathlib-checkable algebraic encoder construction plus a
caller-supplied hardness witness.

Three reasons for the conditional approach:

1. **CFI hardness is open.** The Cai–Fürer–Immerman 1992
   construction is *provably* resistant to k-Weisfeiler–Leman
   for any fixed k, but resistance against unbounded-degree
   polynomial-time algorithms is the open GI problem. The Lean
   formalisation cannot prove what the literature has not.
2. **The conditional pattern matches `ConcreteHardnessChain`.**
   Each layer of the chain already has the shape "encoder
   yields ε-bound *if* layer above holds at ε'". The W-Q2
   deliverables slot into that pattern.
3. **Maintains the zero-`axiom` discipline.** Conditional
   theorems with `Prop`-valued hypotheses are not axioms; the
   `audit_phase_16.lean` `#print axioms` discipline applies
   unchanged.

**Excluded alternatives.**

- Direct ε < 1 proof for the existing `s2Surrogate` instance
  (`Hardness/TensorAction.lean:640`): rejected because the
  `s2Surrogate` is a *trivial* surrogate (S₂-shaped, used as a
  non-vacuity placeholder); proving ε < 1 there would be a
  triviality and would not extend to production parameters.
- Unconditional ε < 1 proof for a custom encoder: rejected
  because no such encoder is known to exist; every candidate
  rests on a hardness conjecture for some underlying problem.

### 4.3 Sub-leg 4.A — CFI graph construction (R-03 closure)

Five new files under `Orbcrypt/Hardness/CFI/`.

#### 4.A.1 `Orbcrypt/Hardness/CFI/Basic.lean` — fibre data type and CFI graph

**Headline definitions.**

```lean
/-- A CFI fibre vertex over a base vertex of degree d:
    an even-parity bit vector of length d. -/
structure CFIFibre (d : ℕ) where
  bits : Fin d → Bool
  evenParity : (Finset.univ.filter (fun i => bits i)).card % 2 = 0

/-- The CFI vertex set: a sigma-type over base vertices, each
    fibre indexed by `CFIFibre (degree v)`. -/
def CFIVertex (n₀ : ℕ) (deg : Fin n₀ → ℕ) : Type :=
  Σ v : Fin n₀, CFIFibre (deg v)

/-- The CFI graph as a SimpleGraph on CFIVertex, parameterised
    by a base graph H, the per-vertex edge orderings (encoded
    as a function `edgeIndex : Fin n₀ → SimpleGraph.neighbour → Fin _`),
    and a twist vector `t : edges H → Bool`. -/
def cfiGraph
    {n₀ : ℕ} (H : SimpleGraph (Fin n₀)) [DecidableRel H.Adj]
    (edgeIndex : ∀ v : Fin n₀, H.neighborSet v → Fin (H.degree v))
    (t : Sym2 (Fin n₀) → Bool) :
    SimpleGraph (CFIVertex n₀ H.degree) := ...
```

**Reused infrastructure.** Mathlib's `SimpleGraph`,
`SimpleGraph.neighborSet`, `Sym2`, `Finset.filter`.

**LOC:** ~400. **Risk:** Med (Sym2 and SimpleGraph.neighborSet
plumbing is finicky).

#### 4.A.2 `Orbcrypt/Hardness/CFI/CardinalityLemmas.lean` — basic combinatorics

```lean
/-- The CFI fibre over a degree-d vertex has 2^(d-1) elements
    (the even-parity subset of Fin d → Bool). -/
theorem cfiFibre_card (d : ℕ) (hd : d > 0) :
    Fintype.card (CFIFibre d) = 2 ^ (d - 1) := ...

/-- For 3-regular base H, each fibre has 4 elements. -/
theorem cfiFibre_card_three_regular {n₀ : ℕ}
    (H : SimpleGraph (Fin n₀)) [DecidableRel H.Adj]
    (hreg : ∀ v, H.degree v = 3) (v : Fin n₀) :
    Fintype.card (CFIFibre (H.degree v)) = 4 := ...

/-- |V(CFI(H, _))| = Σ_v 2^(degree v - 1); for 3-regular H,
    this equals 4·n₀. -/
theorem cfiGraph_vertex_count_three_regular {n₀ : ℕ}
    (H : SimpleGraph (Fin n₀)) [DecidableRel H.Adj]
    (hreg : ∀ v, H.degree v = 3) :
    Fintype.card (CFIVertex n₀ H.degree) = 4 * n₀ := ...
```

**LOC:** ~250. **Risk:** Low (pure finset combinatorics).

#### 4.A.3 `Orbcrypt/Hardness/CFI/CycleSpace.lean` — cycle space and twist equivalence

```lean
/-- The cycle space of a graph as an F₂-vector subspace of
    the edge space. An element is the indicator function of an
    edge-disjoint union of cycles. -/
noncomputable def cycleSpace {n₀ : ℕ}
    (H : SimpleGraph (Fin n₀)) [DecidableRel H.Adj] :
    Submodule (ZMod 2) (Sym2 (Fin n₀) → ZMod 2) := ...

/-- The Cai–Fürer–Immerman main theorem (formal-shape statement,
    proved as a Mathlib-checkable consequence of the cycle-space
    framing): two CFI graphs CFI(H, t) and CFI(H, t') are
    isomorphic as graphs iff t ⊕ t' is in the cycle space of H. -/
theorem cfi_iso_iff_twist_diff_in_cycle_space
    {n₀ : ℕ} (H : SimpleGraph (Fin n₀)) [DecidableRel H.Adj]
    (hconn : H.Connected) (edgeIndex : _) (t t' : Sym2 (Fin n₀) → Bool) :
    Nonempty (cfiGraph H edgeIndex t ≃g cfiGraph H edgeIndex t')
      ↔
    (∀ e, (t e).xor (t' e) = true → e ∈ cycleSpace H) := ...
```

**Reused infrastructure.** Mathlib's `Submodule`, `ZMod 2`,
`Sym2`, `SimpleGraph.Iso`. The proof is the substantive piece:
the forward direction (iso ⇒ twist-diff in cycle space) is the
standard CFI gadget analysis; the reverse direction (twist-diff
in cycle space ⇒ iso) is a constructive isomorphism via local
fibre re-labelling at each cycle.

**LOC:** ~550. **Risk:** **High** (the forward direction is
the most algebraically delicate piece of the Cai–Fürer–Immerman
construction; the reverse is more concrete but still ~300 LOC).

**Mitigation.** Two staged sub-units:

- **4.A.3.a** — reverse direction only (constructive isomorphism
  from cycle-space twist-diff). ~250 LOC. Low risk.
- **4.A.3.b** — forward direction. ~300 LOC. High risk. May be
  staged as a `Prop`-valued hypothesis `CFIForwardDirection`
  initially, discharged in a follow-on sub-unit, if the
  algebraic proof proves too deep for the planned LOC budget.

#### 4.A.4 `Orbcrypt/Hardness/CFI/Hardness.lean` — CFI hardness predicate

```lean
/-- A CFI-separated twist pair: twists whose XOR is not in the
    cycle space of the base graph. The non-iso witness. -/
structure CFISeparatedTwistPair {n₀ : ℕ}
    (H : SimpleGraph (Fin n₀)) [DecidableRel H.Adj] where
  t₀ : Sym2 (Fin n₀) → Bool
  t₁ : Sym2 (Fin n₀) → Bool
  separated : ¬ (∀ e, (t₀ e).xor (t₁ e) = true → e ∈ cycleSpace H)

/-- The CFI hardness predicate: no polynomial-circuit
    distinguisher achieves advantage > ε on separated CFI pairs
    over a connected 3-regular base graph H. Formalised as a
    quantitative bound on the `cfiGraph`-induced
    `ConcreteGIOIA`-style advantage. -/
def CFIHardness
    {n₀ : ℕ} (H : SimpleGraph (Fin n₀)) [DecidableRel H.Adj]
    (P : CFISeparatedTwistPair H) (ε : ℝ) : Prop :=
  -- abstracted distinguisher type matches the GIOIA-distinguisher
  -- shape in Hardness/Reductions.lean
  ∀ A : GraphIsoDistinguisher (4 * n₀),
    graphIsoAdvantage A (cfiGraph H _ P.t₀) (cfiGraph H _ P.t₁) ≤ ε

/-- ε = 1 trivial bound. -/
theorem cfiHardness_one {n₀ : ℕ}
    (H : SimpleGraph (Fin n₀)) [DecidableRel H.Adj]
    (P : CFISeparatedTwistPair H) :
    CFIHardness H P 1 := ...
```

**LOC:** ~200. **Risk:** Low (paralleling `ConcreteGIOIA` shape).

#### 4.A.5 `Orbcrypt/Hardness/CFI/OIAEncoder.lean` — the CFI OIA encoder

```lean
/-- The CFI-graph → bitstring encoder. Encodes a CFI graph as
    its adjacency-matrix flattening (upper triangle) into a
    `Bitstring (4n₀ choose 2)`. -/
def cfiGraphToBitstring
    {n₀ : ℕ} (H : SimpleGraph (Fin n₀)) [DecidableRel H.Adj]
    (edgeIndex : _) (t : Sym2 (Fin n₀) → Bool) :
    Bitstring (Nat.choose (4 * n₀) 2) := ...

/-- The CFI scheme: a two-message-orbit `OrbitEncScheme` whose
    orbits are S_{4n₀} · (cfiGraphToBitstring t₀) and
    S_{4n₀} · (cfiGraphToBitstring t₁). -/
def cfiScheme {n₀ : ℕ}
    (H : SimpleGraph (Fin n₀)) [DecidableRel H.Adj]
    (P : CFISeparatedTwistPair H) :
    OrbitEncScheme
      (Equiv.Perm (Fin (4 * n₀)))
      (Bitstring (Nat.choose (4 * n₀) 2))
      (Fin 2) := ...

/-- The headline conditional reduction: CFI hardness at ε
    implies ConcreteGIOIA at ε on the cfiScheme. -/
theorem cfi_hardness_implies_concreteGIOIA_eps_lt_one
    {n₀ : ℕ} (H : SimpleGraph (Fin n₀)) [DecidableRel H.Adj]
    (P : CFISeparatedTwistPair H) {ε : ℝ}
    (h_cfi : CFIHardness H P ε) :
    ConcreteOIA (cfiScheme H P) ε := ...

/-- Inhabitation at ε = 1 via cfiHardness_one. -/
theorem cfi_chain_at_one_exists :
    ∃ (n₀ : ℕ) (_ : n₀ ≥ 2) (H : SimpleGraph (Fin n₀))
      (_ : DecidableRel H.Adj) (P : CFISeparatedTwistPair H),
        CFIHardness H P 1 ∧
        ConcreteOIA (cfiScheme H P) 1 := ...
```

**LOC:** ~350. **Risk:** Med (orbit-preservation of the
adjacency-matrix flattening encoder must be proved against the
S_{4n₀} action).

### 4.4 Sub-leg 4.B — Grochow–Qiao OIA-lift (R-02 closure)

Two new files under `Orbcrypt/Hardness/`.

#### 4.B.1 `Orbcrypt/Hardness/GrochowQiaoOIA.lean` — encoder shape

The existing `Hardness/GrochowQiao.lean` (and its 26
sub-modules under `Hardness/GrochowQiao/`) deliver the Karp
reduction at the *isomorphism-set* level: there is an injective
map `φ : Graph n → Tensor3 (dimGQ n) ℚ` such that
`G₁ ≅ G₂ ↔ φ(G₁) ≅ φ(G₂)` under the corresponding group
action on each side.

W-Q2.B lifts this to an `OrbitPreservingEncoding`:

```lean
/-- The Grochow–Qiao orbit-preserving encoding. Takes
    a graph as a Bitstring (n choose 2) and produces the
    corresponding tensor; orbit equivalence is preserved
    in both directions. -/
def grochowQiaoOrbitEncoding (n : ℕ) :
    OrbitPreservingEncoding
      (Equiv.Perm (Fin n))         -- source group
      (Bitstring (Nat.choose n 2)) -- source space (graph)
      (Matrix (Fin n) (Fin n) ℚ × Matrix (Fin n) (Fin n) ℚ
       × Matrix (Fin n) (Fin n) ℚ) -- target group (GL³)
      (Tensor3 (dimGQ n) ℚ) := ...

/-- Orbit-equivariance: the encoder maps S_n-orbits to
    GL³-orbits. -/
theorem grochowQiaoOrbitEncoding_equivariant {n : ℕ}
    (σ : Equiv.Perm (Fin n)) (G : Bitstring (Nat.choose n 2)) :
    (grochowQiaoOrbitEncoding n).encode (permuteAdj σ G) ∈
      MulAction.orbit
        (Matrix (Fin (dimGQ n)) (Fin (dimGQ n)) ℚ)³
        ((grochowQiaoOrbitEncoding n).encode G) := ...

/-- The headline conditional reduction: GI-OIA hardness at ε
    implies Tensor-OIA hardness at ε under the GQ encoder. -/
theorem grochowQiao_giOIA_implies_concreteTensorOIA
    {n : ℕ} (G₀ G₁ : Bitstring (Nat.choose n 2)) {ε : ℝ}
    (h_gi : ConcreteGIOIA G₀ G₁ ε) :
    ConcreteTensorOIA
      ((grochowQiaoOrbitEncoding n).encode G₀)
      ((grochowQiaoOrbitEncoding n).encode G₁)
      ε := ...
```

**LOC:** ~400. **Risk:** Med (depends on R-TI Phase 3 closing
the `h_research` Props in `AlgEquivFromGL3.lean`; if that closure
slips, the GQ-OIA lift inherits the `h_research` conditional).

#### 4.B.2 `Orbcrypt/Hardness/CFItoGrochowQiaoChain.lean` — chain composition at non-trivial ε

```lean
/-- The chained conditional witness: CFI hardness at ε plus
    the existing CE-to-GI encoder plus the GQ OIA-encoder
    gives a `ConcreteHardnessChain` inhabitation at non-trivial ε. -/
theorem concrete_hardness_chain_at_cfi_grochowQiao
    {n₀ : ℕ} (H : SimpleGraph (Fin n₀)) [DecidableRel H.Adj]
    (P : CFISeparatedTwistPair H) {ε : ℝ}
    (h_cfi : CFIHardness H P ε)
    (scheme : OrbitEncScheme _ _ _)
    (h_scheme_via_cfi : scheme = cfiScheme H P)
    {F : Type*} {S : SurrogateTensor F}
    (h_surrogate_via_gq : S = grochowQiaoSurrogateOf n₀ H P) :
    ConcreteHardnessChain scheme F S ε := ...
```

**LOC:** ~250. **Risk:** Med (composition of the conditional
hypotheses across encoders).

### 4.5 Update to `Hardness/Reductions.lean`

Two additive lemmas at the end of the existing file (no
destructive changes):

```lean
/-- Composing the W-Q2 chained witness with the
    existing `concrete_hardness_chain_implies_1cpa_advantage_bound`
    yields a quantitative IND-1-CPA bound at the CFI-controlled ε. -/
theorem ind1cpa_advantage_bound_via_cfi
    {n₀ : ℕ} (H : SimpleGraph (Fin n₀)) [DecidableRel H.Adj]
    (P : CFISeparatedTwistPair H) {ε : ℝ}
    (h_cfi : CFIHardness H P ε)
    (A : Adversary _ _) :
    indCPAAdvantage (cfiScheme H P) A ≤ ε := ...

/-- Existence of a non-trivial ε < 1 inhabitation (conditional). -/
theorem exists_concreteHardnessChain_with_eps_lt_one :
    ∃ (n₀ : ℕ) (H : SimpleGraph (Fin n₀)) (_ : DecidableRel H.Adj)
      (P : CFISeparatedTwistPair H) (ε : ℝ),
        ε < 1 ∧
        (CFIHardness H P ε →
         ∃ scheme F S, ConcreteHardnessChain scheme F S ε) := ...
```

**LOC:** ~150. **Risk:** Low (additive composition).

### 4.6 Work units

| ID | Title | Type | LOC | Risk | Depends on |
|----|-------|------|----:|------|------------|
| Q2.A.1 | `Orbcrypt/Hardness/CFI/Basic.lean` — CFI vertex / graph data type | Lean def | 400 | Med | — |
| Q2.A.2 | `Orbcrypt/Hardness/CFI/CardinalityLemmas.lean` — vertex / edge counts | Lean thm | 250 | Low | Q2.A.1 |
| Q2.A.3a | `CycleSpace.lean` reverse direction (twist-diff in cycle space ⇒ iso) | Lean thm | 250 | Med | Q2.A.1, Q2.A.2 |
| Q2.A.3b | `CycleSpace.lean` forward direction (iso ⇒ twist-diff) | Lean thm | 300 | **High** | Q2.A.3a |
| Q2.A.4 | `Hardness.lean` — CFISeparatedTwistPair + CFIHardness Prop | Lean def | 200 | Low | Q2.A.3a |
| Q2.A.5 | `OIAEncoder.lean` — cfiScheme + headline reduction | Lean def + thm | 350 | Med | Q2.A.4 |
| Q2.B.1 | `GrochowQiaoOIA.lean` — orbit-preserving GQ encoder | Lean def + thm | 400 | Med | R-TI Phase 3 closure (or h_research carry-over) |
| Q2.B.2 | `CFItoGrochowQiaoChain.lean` — chained ε-bound | Lean thm | 250 | Med | Q2.A.5, Q2.B.1 |
| Q2.C.1 | `Hardness/Reductions.lean` additive lemmas (CFI/GQ chain entries) | Lean thm | 150 | Low | Q2.B.2 |
| Q2.C.2 | Audit script `scripts/audit_phase_16.lean` §15.27 entries | Lean script | 80 | Low | Q2.C.1 |
| Q2.D.1 | `docs/HARDNESS_ANALYSIS.md` §3 update (chain diagram, ε<1 inhabitation) | Doc | 60 | Low | Q2.C.1 |
| Q2.D.2 | `docs/DEVELOPMENT.md` §5.3 CFI sub-section finalisation | Doc | 40 | Low | Q2.C.1 |
| Q2.D.3 | `docs/API_SURFACE.md` — three new headline rows | Doc | 30 | Low | Q2.C.1 |
| Q2.D.4 | `CLAUDE.md` / `AGENTS.md` release-messaging policy update | Doc | 30 | Low | Q2.D.3 |
| **Q2 total** | | | **~2790** | | |

**Note on Q2.A.3b risk mitigation.** If the forward direction of
the CFI iso ⇔ twist-diff-in-cycle-space theorem proves too deep
for the planned ~300 LOC budget, the workstream stages it as a
`Prop`-valued research-scope hypothesis `CFIForwardDirection H`
analogous to `R-TI`'s `RestrictedGL3OnPathOnlyTensor`. Subsequent
work-units (Q2.A.4, Q2.A.5) carry the hypothesis through. The
release-messaging consequences are tracked in Q2.D.1 as an
explicit "Conditional on CFIForwardDirection" Status entry.

### 4.7 Cross-cutting with W-Q5

Q2.B introduces non-trivial `ConcreteTensorOIA` content (the
`grochowQiao_giOIA_implies_concreteTensorOIA` reduction). Every
caller who lands a non-trivial ε < 1 instantiation of this
reduction must satisfy W-Q5's `TensorOIAParameterReview` carrier
(§7). The cross-reference is mechanically enforced by the
audit-script entry `scripts/audit_tensor_oia_parameters.py`
introduced in W-Q5.3.

In particular, the Q2.B.2 `concrete_hardness_chain_at_cfi_grochowQiao`
theorem at any ε < 1 must be paired with a documented
`TensorOIAParameterReview` carrier *at the call-site*. The Lean
type-system enforces this via the
`TensorOIAParameterReview` field on the `ConcreteTensorOIA`-level
hypothesis (introduced in W-Q5.2).

### 4.8 Risk register and rollback

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| CFI forward direction (Q2.A.3b) proves >> 300 LOC | Med | Med | Stage as research-scope hypothesis (Q2.A.3b mitigation above). |
| R-TI Phase 3 (`h_research` discharge) slips | Med | Med | Q2.B inherits `h_research` and stages an additional sub-unit Q2.B.1.alt with the carry-over hypothesis. Tracked in §10. |
| CFI vertex-set choice introduces decidability friction | Med | Low | The `Sigma` / `Subtype` shape of `CFIVertex` may need DecidableEq instances; standard derivation suffices. |
| Encoder orbit-equivariance proof bottlenecks on `permuteAdj` machinery | Low | Med | The `permuteAdj` API in `Hardness/Reductions.lean:116` is already exercised by the existing GI-CE encoder; reuse pattern available. |
| Q2.C.1 chain-composition has loose ε accounting (factor 2 or n) | Med | Low | Probabilistic-side accounting follows `concreteOIA_from_chain` (`Hardness/Reductions.lean:636`); patterns established. |

**Rollback.** Pure additive at the Lean level; the only
non-additive piece is the doc updates (Q2.D.\*), which can be
reverted independently. No existing declarations are modified
destructively.

### 4.9 Exit criteria for Workstream W-Q2

W-Q2 closes when **all** of the following are demonstrably true:

1. `lake build Orbcrypt.Hardness.CFI.Basic` through
   `lake build Orbcrypt.Hardness.CFItoGrochowQiaoChain` all
   succeed clean.
2. `cfi_hardness_implies_concreteGIOIA_eps_lt_one` is declared
   and proved (modulo Q2.A.3b conditional carry-over, if
   staged).
3. `grochowQiao_giOIA_implies_concreteTensorOIA` is declared
   and proved (modulo R-TI Phase 3 carry-over, if staged).
4. `exists_concreteHardnessChain_with_eps_lt_one` exhibits a
   *symbolic* ε < 1 inhabitation (the ε is left as a variable;
   the theorem witnesses that *for some* ε < 1, the chain
   becomes inhabitable under the CFI / GQ hypotheses).
5. `cfi_chain_at_one_exists` and the analogous GQ
   ε = 1 inhabitation are exhibited in
   `scripts/audit_phase_16.lean` §15.27 with canonical
   `#print axioms` triple.
6. `docs/HARDNESS_ANALYSIS.md` §3 carries an updated chain
   diagram showing the CFI and GQ ε-bands. `docs/API_SURFACE.md`
   adds three new headline rows. `CLAUDE.md` / `AGENTS.md`
   release-messaging policy is updated to recognise the new
   conditional citations.
7. `docs/dev_history/WORKSTREAM_CHANGELOG.md` carries a W-Q2
   entry with per-commit traceability.
8. CI gate #6 passes.

---

## 5. Workstream W-Q3 — Q2 / superposition-oracle adversary model

### 5.1 Problem statement

The HGOE security analysis in `docs/DEVELOPMENT.md` §§4.3, 5.2,
8.1, 8.2, 8.4.2 implicitly adopts the **Q1 adversary model**:
the adversary has *classical* oracle access to the encryption
procedure `Enc(sk, ·)`. The post-quantum analysis in §8.4.2
correctly establishes Q1 resistance, but the literature
recognises a strictly stronger model — the **Q2 model**, where
the adversary has *quantum-superposition* oracle access to
encryption, i.e., can query

> `O_Enc : |m⟩|y⟩ ↦ |m⟩|y ⊕ Enc(sk, m)⟩`

on arbitrary superpositions over messages. Q2 attacks have
broken several primitives that are Q1-secure: Simon's algorithm
against GMAC, CBC-MAC, OCB, and similar polynomial-evaluation
MACs in Kaplan–Leurent–Leverrier–Naya-Plasencia (CRYPTO 2016),
correctly cited in `docs/PARAMETERS.md` §3 ‡ but **not** carried
through to the HGOE-specific analysis.

The cryptanalytic concern for HGOE-in-Q2 is concrete: the
natural superposition `Σ_{σ ∈ S_n} |σ⟩ |σ · x_m⟩` collapses
under partial measurement of the second register to a
`Stab(x_m)`-coset state `Σ_{σ ∈ C} |σ⟩` for some coset `C`.
This is exactly the "coset state" object that the
Moore–Russell–Schulman 2008 *negative* result analyses — but
their target subgroup family is single-involutions hidden in
S_n (the GI-encoded case), not the PAut-of-quasi-cyclic-code
family that HGOE actually deploys. The two families have
different representation-theoretic profiles, and the negative
result for one does not transfer for free to the other.

The cryptanalytic gap (§1, finding QH-03) has three pieces:

1. **No Lean Q2 game shape.** `Crypto/Security.lean` and
   `Crypto/CompSecurity.lean` carry only the classical adversary
   type (`Adversary X M`); there is no `Q2Adversary` shape, no
   quantum-superposition-oracle predicate, and no Q2 advantage
   notion.
2. **No analytical document.** The Q1-vs-Q2 distinction
   appears only as a footnote in `docs/PARAMETERS.md` §3 ‡; no
   canonical document analyses Q2-specific threats against
   HGOE.
3. **No PAut-family representation-theory analysis.** The
   Moore–Russell–Schulman negative result targets
   single-involution subgroups; the HGOE-relevant PAut subgroups
   of quasi-cyclic codes include cyclic-shift subgroups,
   block-permutation subgroups, and (depending on QC structure)
   other small non-abelian pieces. The Q2-relevant question
   for HGOE is whether Fourier sampling defeats *this* family —
   a question the literature has not directly answered.

### 5.2 Research-scope designation (R-Q3)

W-Q3 is designated **research-scope (R-Q3)** for the following
reasons:

1. **No Lean quantum-computation framework.** Mathlib 4 (as of
   the pinned commit `fa6418a8`) does not provide a quantum-state
   / quantum-circuit framework. CryptHOL (Isabelle/HOL) and FCF
   (Coq) have partial quantum-game support; neither is
   immediately portable to Lean. Building a Lean quantum
   framework from scratch is a multi-year project unsuited to
   this plan's 3.5-month critical path.
2. **The underlying mathematical question is open.** Whether
   HSP on the PAut-of-quasi-cyclic-code family resists
   superposition-coset-sampling Fourier attacks is an open
   research problem. The Lean content can only formalise the
   *shape* of the question, not its answer.
3. **The deliverable is a documented gap, not a security
   theorem.** W-Q3 produces a canonical analysis document
   `docs/Q2_MODEL_ANALYSIS.md`, a Lean stub framework
   `Orbcrypt/Crypto/Q2Game.lean` carrying structural
   definitions and Prop-valued research hypotheses, and a
   cross-reference catalogue mapping HGOE-specific Q2 threats
   to research-scope follow-ons.

W-Q3 is therefore catalogued as research milestone **R-Q3** in
the project research backlog (`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md`
§18.1 follow-on), parallel to R-09 (per-coordinate marginal
independence proof) and R-13 (Carter–Wegman ↔ HGOE adapter).

### 5.3 Target API shape (post-fix)

**`Orbcrypt/Crypto/Q2Game.lean`** — Lean stub framework. ~600
LOC.

```lean
/-- A Q2 adversary: structurally distinct from the classical
    `Adversary X M` type. Instead of a `choose : params → M × M`
    field and a `guess : X → Bool` field, a Q2 adversary
    carries an abstract `quantumQuery` field whose semantic
    interpretation is research-scope. The Lean type is a
    placeholder that admits no automatic construction; concrete
    Q2 adversaries are introduced as `Prop`-valued hypotheses. -/
structure Q2Adversary
    (G X M : Type*) [Group G] [Fintype G] [MulAction G X] where
  /-- Abstract advantage carrier. The structural definition
      treats the adversary as a black-box producing a
      (params, ε)-indexed real advantage value; concrete
      quantum-circuit instantiation is research-scope. -/
  abstractAdvantage : OrbitEncScheme G X M → ℝ
  /-- Non-negativity (sanity). -/
  abstractAdvantage_nonneg : ∀ scheme, 0 ≤ abstractAdvantage scheme
  /-- Trivial bound (sanity). -/
  abstractAdvantage_le_one : ∀ scheme, abstractAdvantage scheme ≤ 1

/-- The Q2 IND-1-CPA security predicate at advantage bound ε. -/
def IsQ2Secure (scheme : OrbitEncScheme G X M) (ε : ℝ) : Prop :=
  ∀ A : Q2Adversary G X M, A.abstractAdvantage scheme ≤ ε

/-- Q1 ⊆ Q2: every classical adversary embeds as a Q2 adversary
    whose abstractAdvantage equals its classical IND-CPA
    advantage. -/
def classicalToQ2Adversary
    {G X M : Type*} [Group G] [Fintype G] [MulAction G X]
    (A : Adversary X M) : Q2Adversary G X M := ...

/-- Q2 secure ⇒ Q1 secure (the easy direction). -/
theorem q2_secure_implies_q1_secure
    {G X M : Type*} [Group G] [Fintype G] [Nonempty G] [MulAction G X]
    [Fintype X] [DecidableEq X] [Fintype M] [DecidableEq M]
    {scheme : OrbitEncScheme G X M} {ε : ℝ}
    (h : IsQ2Secure scheme ε) :
    ∀ A : Adversary X M, indCPAAdvantage scheme A ≤ ε := ...

/-- Research-scope hypothesis (R-Q3 leg 1): does the
    coset-state Fourier sampling argument transfer from the
    GI-encoded single-involution subgroup family to the
    PAut-of-quasi-cyclic-code family? Formalised as a
    Prop predicate the formalisation does not discharge. -/
def CosetStateFourierResistance
    {n : ℕ} (G : Subgroup (Equiv.Perm (Fin n))) (ε : ℝ) : Prop :=
  -- abstracted predicate; the full Mathlib-checkable
  -- formulation requires Q2-framework definitions that are
  -- research-scope.
  True ∨ False  -- placeholder shape; see docs/Q2_MODEL_ANALYSIS.md

/-- The conditional headline: Q2 security of HGOE follows from
    coset-state Fourier resistance of PAut(C). Stated as a
    research-scope conditional. -/
theorem hgoe_q2_secure_conditional_on_coset_state_resistance
    {n : ℕ} (G : Subgroup (Equiv.Perm (Fin n))) {M : Type*}
    [Fintype M] [DecidableEq M]
    (reps : M → Bitstring n)
    (h_distinct : ∀ m₀ m₁ : M, m₀ ≠ m₁ →
       MulAction.orbit G (reps m₀) ≠ MulAction.orbit G (reps m₁))
    {ε : ℝ}
    (h_coset : CosetStateFourierResistance G ε) :
    IsQ2Secure (hgoeScheme reps) ε := ...
```

**`docs/Q2_MODEL_ANALYSIS.md`** — canonical analysis document.
~650 lines. Structured outline:

- **§1 Background.** Q1 vs Q2 model formal definitions; the
  Boneh–Zhandry framework; the Kaplan–Leurent–Leverrier–
  Naya-Plasencia (KLLN) family of Simon-based attacks.
- **§2 The HGOE encryption oracle in Q2.** The natural
  superposition `Σ_σ |σ⟩ |σ · x_m⟩` and its collapse to a
  coset state. The relationship between Q2 oracle queries and
  the natural hidden-subgroup-state input to a Fourier-sampling
  algorithm.
- **§3 Existing negative results and their reach.**
  Hallgren–Russell–Ta-Shma 2003; Moore–Russell–Schulman 2008;
  the precise hidden-subgroup family these results target;
  the gap to the PAut-of-quasi-cyclic-code family.
- **§4 HGOE-specific Q2 threat catalogue.**
  - §4.1 Simon-style attacks via the additive structure of the
    cyclic-shift subgroup of PAut.
  - §4.2 Coset-state Fourier sampling against the full PAut.
  - §4.3 Quantum walk algorithms (Magniez–Nayak–Roland–Santha-style)
    against permutation-orbit decision problems.
  - §4.4 Hybrid algebraic-quantum attacks (no current
    template; tracked).
- **§5 Conditional Q2-security framework.** The Lean stub
  framework (`Q2Game.lean`) and the conditional reduction
  `hgoe_q2_secure_conditional_on_coset_state_resistance`. The
  research-scope hypothesis `CosetStateFourierResistance` and
  its relationship to known HSP_{S_n} results.
- **§6 Parameter implications.** If R-Q3 closes negatively
  (i.e., Q2 attacks become viable against the PAut family),
  the parameter implications: structural fence on PAut
  abelianness (W-Q4) is necessary but not sufficient; what
  additional parameter constraints would be needed.
- **§7 Open questions and research roadmap.**
- **§8 References.**

### 5.4 Work units

| ID | Title | Type | LOC | Risk | Depends on |
|----|-------|------|----:|------|------------|
| Q3.1 | `Crypto/Q2Game.lean` — Q2Adversary stub + IsQ2Secure | Lean def | 250 | Low | — |
| Q3.2 | `classicalToQ2Adversary` + `q2_secure_implies_q1_secure` | Lean def + thm | 180 | Low | Q3.1 |
| Q3.3 | `CosetStateFourierResistance` research-scope predicate | Lean def | 120 | Low | Q3.1 |
| Q3.4 | `hgoe_q2_secure_conditional_on_coset_state_resistance` | Lean thm | 250 | Med | Q3.3 |
| Q3.5 | `Q2_MODEL_ANALYSIS.md` §§1–3 (background, oracle shape, neg results) | Doc | 200 | Low | Q3.1 |
| Q3.6 | `Q2_MODEL_ANALYSIS.md` §4 (HGOE-specific Q2 threats) | Doc | 200 | Low | Q3.4 |
| Q3.7 | `Q2_MODEL_ANALYSIS.md` §§5–8 (Lean stub map, parameter implications, references) | Doc | 250 | Low | Q3.4 |
| Q3.8 | `docs/DEVELOPMENT.md` §8.4.2 Q2-pillar addition | Doc | 60 | Low | Q3.7 |
| Q3.9 | `docs/HARDNESS_ANALYSIS.md` cross-reference table update | Doc | 30 | Low | Q3.7 |
| Q3.10 | `docs/PARAMETERS.md` §3 ‡ cross-reference to Q2 analysis | Doc | 20 | Low | Q3.7 |
| Q3.11 | Audit script § 15.28 entries | Lean script | 50 | Low | Q3.4 |
| Q3.12 | R-Q3 research-scope catalogue entry in AUDIT_2026-04-23 plan §18 | Doc | 20 | Low | Q3.7 |
| **Q3 total** | | | **~1630** | | |

**Note on Q3.4 risk.** The conditional reduction
`hgoe_q2_secure_conditional_on_coset_state_resistance` proves
"if `CosetStateFourierResistance` holds, then `IsQ2Secure`
holds." Because `CosetStateFourierResistance` is a placeholder
predicate (currently `True ∨ False` semantically, awaiting
Q2-framework definitions), the conditional is mechanically a
tautology in the current Lean. The Med risk reflects the
*design* of the conditional: its hypothesis must be shaped
such that, when a Q2 framework lands in a future plan, the
conditional immediately upgrades to a substantive theorem
without signature changes. Q3.3 must therefore be designed
carefully — the `CosetStateFourierResistance` shape is the
load-bearing API decision of this workstream.

### 5.5 Risk register and rollback

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Future Q2 framework lands with incompatible `CosetStateFourierResistance` shape | Med | Med | Q3.3 carries an explicit "shape contract" docstring listing the assumed quantum-state-vector semantics; future framework imports the contract. |
| `IsQ2Secure` definition shape diverges from Boneh–Zhandry standard | Low | Low | The definition uses an abstract `abstractAdvantage` field deliberately; no quantum semantics are baked in. |
| Document scope creep (Q3.5–Q3.7 overruns 650 lines) | Med | Low | Hard stop at 650 lines; overflow sections move to a follow-on `docs/research/Q2_HGOE_THREAT_CATALOGUE.md`. |
| R-Q3 conflated with Q3 (workstream vs research milestone) in changelog | Low | Low | Strict labeling discipline: `W-Q3` for plan/workstream references; `R-Q3` for the research-scope follow-on. |

**Rollback.** Pure additive. The Q2 stub framework introduces
no consumer in the existing codebase (its `Prop` predicates are
opt-in); deletion leaves the codebase byte-identical to
pre-plan state.

### 5.6 Exit criteria for Workstream W-Q3

W-Q3 closes when **all** of the following are demonstrably
true:

1. `lake build Orbcrypt.Crypto.Q2Game` succeeds clean.
2. `hgoe_q2_secure_conditional_on_coset_state_resistance` is
   declared and proved.
3. `docs/Q2_MODEL_ANALYSIS.md` exists at the planned ≥ 600 /
   ≤ 650 line target, structured per §5.3.
4. `docs/DEVELOPMENT.md` §8.4.2 is updated with a Q2-pillar
   sub-section citing the new module and document.
5. `docs/HARDNESS_ANALYSIS.md` carries a cross-reference row
   to the new Q2 analysis.
6. `docs/PARAMETERS.md` §3 ‡ carries a cross-reference to
   `docs/Q2_MODEL_ANALYSIS.md`.
7. R-Q3 research-scope catalogue entry is added to
   `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` §18.1.
8. CI gate #6 passes with the new audit-script section.
9. `docs/dev_history/WORKSTREAM_CHANGELOG.md` carries a W-Q3
   entry.

---

## 6. Workstream W-Q4 — random QC PAut structural fence

### 6.1 Problem statement

The HGOE keygen pipeline in `docs/DEVELOPMENT.md` §6.2 Stage 2
samples random circulant generator blocks to assemble a
quasi-cyclic (QC) generator matrix `G_mat`, then computes the
secret group `G = PAut(C)` from the resulting code `C`. The
QC structure *guarantees* the cyclic-shift subgroup is in
`PAut(C)` (the QC blocks are themselves circulants, and any
block-aligned cyclic shift preserves the row space), so the
keygen output always satisfies `|PAut(C)| ≥ ℓ`. What the
pipeline does **not** guarantee is that `PAut(C)` has
*non-abelian* structure beyond the cyclic-shift subgroup.

The cryptographic concern is sharp. If, for a random circulant
sample, `PAut(C)` *equals* the cyclic-shift subgroup `Z/ℓZ`
(or any abelian extension of it), then:

1. The hidden subgroup is abelian. Shor's algorithm on abelian
   HSP recovers a cyclic group with `O(poly(log |G|))` quantum
   queries.
2. Once `G` is recovered, the OIA reduces to deciding
   orbit-membership under a known abelian group — solvable in
   polynomial time by reducing modulo the cyclic action.
3. Every layer of the post-W6 probabilistic chain
   (`ConcreteOIA`, `ConcreteHardnessChain`,
   `concrete_hardness_chain_implies_1cpa_advantage_bound`)
   loses substantive content on abelian-degenerate keys: the
   quantitative ε-bound collapses to ε ≈ 1.

The cryptanalytic gap (§1, finding QH-04) is fourfold:

1. **No empirical data.** The distribution of `|PAut(C)|` (and
   in particular `|PAut(C)| / ℓ`) over random circulant QC
   codes at the recommended L1/L3/L5/L7 parameters is not
   measured in the codebase.
2. **No Lean predicate for structural non-abelianness.** The
   formalisation has no `IsStructurallyNonAbelian` predicate
   to gate keygen output on.
3. **No GAP keygen pipeline rejection.** The pipeline does not
   compute `|[PAut(C), PAut(C)]|` (the commutator subgroup
   order) and does not reject keys whose `PAut(C)` is abelian
   or near-abelian.
4. **No conditional theorem demonstrating the necessity.** The
   formalisation has no theorem of the shape
   `IsAbelian PAut(C) → ConcreteOIA scheme 1` (under a
   Shor-abelian-hidden hypothesis), so the keygen-side fence
   has no formal counterpart anchoring its necessity.

### 6.2 Fix selection

**Selected approach: empirical + formal + pipeline.** Three
parallel legs:

- **6.A — Empirical study.** GAP script measuring `|PAut(C)|`,
  `|[PAut(C), PAut(C)]|`, `|Z(PAut(C))|` over a statistically
  significant sample of random QC codes per parameter set.
  Resulting empirical distribution informs the threshold.
- **6.B — Lean formal fence.** A new module
  `Orbcrypt/KeyMgmt/StructuralFence.lean` defining
  `IsStructurallyNonAbelian`, the necessity theorem
  `abelian_PAut_implies_oia_break_under_shorAbelianHidden`
  (conditional on a research-scope Shor-abelian-hidden
  predicate), and the keygen-soundness update to
  `HGOEKeyExpansion`.
- **6.C — GAP keygen pipeline update.** Stage 2.5 (new) inserts
  a `StructuralFenceCheck` step that computes the commutator-
  subgroup metric and rejects keys below threshold.

The three legs are independent of each other (B does not
depend on the empirical 6.A result for its theorem-shape; C is
independent of B at the engineering level), so they can land
in parallel.

**Excluded alternatives.**

- Relying solely on `|PAut(C)| ≥ 2^λ` as a heuristic: rejected
  because the size of `PAut(C)` does not bound its
  abelianness; a large cyclic subgroup is still abelian and
  Shor-vulnerable.
- Reweighting QC code generation (e.g., constraining the
  circulant blocks to be non-commuting): rejected as too
  invasive at this stage; the empirical study determines
  whether reweighting is required.

### 6.3 Sub-leg 6.A — empirical PAut distribution study

#### 6.A.1 GAP study script

**File:** `implementation/gap/orbcrypt_paut_study.g` (new).
**Content:**

```gap
# orbcrypt_paut_study.g
# Samples random QC codes per (lambda, b, ell) parameter triple
# and measures |PAut(C)|, |[PAut, PAut]|, |Z(PAut)|.

PAutStudy := function(lambda, b, ell, nSamples)
  local n, results, i, G_mat, C, PAut, comm, center;
  n := b * ell;
  results := [];
  for i in [1..nSamples] do
    G_mat := RandomCirculantGeneratorMatrix(b, ell);
    C := LinearCodeFromGenerator(G_mat);
    PAut := PermutationAutomorphismGroup(C);
    comm := DerivedSubgroup(PAut);
    center := Centre(PAut);
    Add(results, rec(
      paut_size := Size(PAut),
      cyclic_floor := ell,
      comm_size := Size(comm),
      center_size := Size(center),
      abelian := IsAbelian(PAut),
      ratio_paut_to_floor := Size(PAut) / ell,
      ratio_comm_to_paut := Size(comm) / Size(PAut)));
  od;
  return results;
end;
```

Run protocol: 1000 samples each at L1 (`λ=128, b=4, ℓ=128`),
L3 (`λ=192, b=4, ℓ=192`), L5 (`λ=256, b=4, ℓ=256`),
L7 (`λ=384, b=4, ℓ=384`), plus the balanced-tier
`b=8` variants. Output to
`implementation/gap/orbcrypt_paut_study.csv`.

**LOC:** ~350 lines GAP. **Risk:** Low for the script;
**unknown for the empirical result** (the result could
contradict the operational assumption).

#### 6.A.2 Distribution analysis document

**File:** `docs/QC_PAUT_DISTRIBUTION.md` (new).
**Sections.**

- §1 Methodology — sample size, parameter sets, statistical
  framing.
- §2 Empirical results table per parameter set. Median, p5,
  p95 of `|PAut(C)|`, `|[PAut, PAut]|`, abelian fraction.
- §3 Threshold recommendation: the value `θ` such that the
  keygen fence accepts only `|[PAut(C), PAut(C)]| / |PAut(C)| ≥ θ`.
- §4 If §3's threshold rejects > 5% of random samples:
  parameter-tuning recommendation (e.g., increase `b`, or
  reweight circulant sampling).
- §5 Cross-reference to the W-Q4 Lean theorem necessitating
  the fence.

**LOC:** ~500 lines doc. **Risk:** Low for the document
shape; the *content* depends on §6.A.1's empirical result.

### 6.4 Sub-leg 6.B — Lean formal fence

#### 6.B.1 `Orbcrypt/KeyMgmt/StructuralFence.lean` — predicates

```lean
/-- A subgroup is structurally non-abelian if its commutator
    subgroup has cardinality at least a threshold fraction of
    the parent group's cardinality. Threshold parameterised
    by `θ` (a rational in (0, 1]; in practice θ ≈ 1/4 per
    the W-Q4 empirical study). -/
def IsStructurallyNonAbelian
    {n : ℕ} (G : Subgroup (Equiv.Perm (Fin n))) (θ : ℚ) : Prop :=
  ∃ (hg : Fintype G),
    (θ.num.toNat) * Fintype.card G ≤
      (θ.den) * Fintype.card (commutator G)

/-- A subgroup is abelian iff its commutator subgroup is
    trivial — the standard characterisation. -/
theorem isStructurallyNonAbelian_of_pos_threshold_implies_not_abelian
    {n : ℕ} (G : Subgroup (Equiv.Perm (Fin n)))
    {θ : ℚ} (hθ_pos : 0 < θ)
    (h : IsStructurallyNonAbelian G θ) :
    ¬ ∀ a b ∈ G, a * b = b * a := ...

/-- Decidability of the predicate at concrete arithmetic. -/
instance decidable_isStructurallyNonAbelian
    {n : ℕ} (G : Subgroup (Equiv.Perm (Fin n)))
    [Fintype G] [DecidablePred (· ∈ commutator G)]
    (θ : ℚ) :
    Decidable (IsStructurallyNonAbelian G θ) := ...
```

**LOC:** ~250. **Risk:** Low (standard subgroup arithmetic;
the existing `Mathlib.GroupTheory.Commutator` API is reused).

#### 6.B.2 Necessity theorem under Shor-abelian-hidden hypothesis

```lean
/-- Research-scope predicate: Shor's algorithm on the abelian
    HSP can decide orbit-membership of a target bitstring
    under an abelian subgroup of S_n with overwhelming
    advantage. Formalised as a Prop hypothesis. -/
def ShorAbelianHiddenAttack
    {n : ℕ} (G : Subgroup (Equiv.Perm (Fin n))) (ε : ℝ) : Prop :=
  ∀ (M : Type*) [Fintype M] [DecidableEq M]
    (reps : M → Bitstring n)
    (h_abelian : ∀ a b ∈ G, a * b = b * a),
    -- under abelianness, Shor recovers G and breaks OIA with
    -- advantage ≥ 1 - ε. The Lean predicate captures the
    -- conclusion as the *negation* of `ConcreteOIA … ε`.
    ¬ ConcreteOIA (hgoeScheme reps) ε

/-- The necessity theorem: if PAut is abelian, OIA is broken
    (under Shor-abelian-hidden). -/
theorem abelian_PAut_implies_oia_break_under_shorAbelianHidden
    {n : ℕ} (G : Subgroup (Equiv.Perm (Fin n))) {ε : ℝ}
    (h_abelian : ∀ a b ∈ G, a * b = b * a)
    (h_shor : ShorAbelianHiddenAttack G ε)
    {M : Type*} [Fintype M] [DecidableEq M]
    (reps : M → Bitstring n) :
    ¬ ConcreteOIA (hgoeScheme reps) ε := ...

/-- Contrapositive form: if OIA holds at ε < 1, then PAut is
    non-abelian (under the same Shor-abelian-hidden hypothesis). -/
theorem concreteOIA_lt_one_implies_PAut_not_abelian
    {n : ℕ} (G : Subgroup (Equiv.Perm (Fin n))) {ε : ℝ}
    (h_shor : ShorAbelianHiddenAttack G ε)
    {M : Type*} [Fintype M] [DecidableEq M]
    (reps : M → Bitstring n)
    (h_oia : ConcreteOIA (hgoeScheme reps) ε)
    (h_eps_lt_one : ε < 1) :
    ∃ a b ∈ G, a * b ≠ b * a := ...
```

**LOC:** ~200. **Risk:** Med (the `ShorAbelianHiddenAttack`
predicate is a research-scope hypothesis; the conditional
reduction shape is the load-bearing API choice).

#### 6.B.3 `HGOEKeyExpansion` update

The structure in `Orbcrypt/KeyMgmt/SeedKey.lean` is extended
with a new field:

```lean
structure HGOEKeyExpansion (lam : ℕ) (n : ℕ) (M : Type*)
    extends ... where
  -- existing fields ...
  /-- Witness that the secret group's permutation
      automorphism group is structurally non-abelian at
      threshold θ. The default threshold matches the W-Q4
      empirical-study recommendation. -/
  structurally_non_abelian :
    IsStructurallyNonAbelian secretGroup (1 / 4 : ℚ)
```

Every existing `HGOEKeyExpansion` instance (per security level
L1–L7) is updated with a concrete `structurally_non_abelian`
witness produced by the GAP keygen pipeline (6.C below).

**LOC:** ~100. **Risk:** Low (additive field).

### 6.5 Sub-leg 6.C — GAP keygen pipeline update

Update `implementation/gap/orbcrypt_keygen.g` to insert a new
Stage 2.5 between Stage 2 (QC code generation) and Stage 3
(PAut computation):

```gap
# Stage 2.5 — Structural fence check.
# Reject if [PAut(C), PAut(C)] / PAut(C) < theta.
StructuralFenceCheck := function(C, theta)
  local PAut, comm, ratio;
  PAut := PermutationAutomorphismGroup(C);
  comm := DerivedSubgroup(PAut);
  ratio := Size(comm) / Size(PAut);
  if ratio < theta then
    return rec(accept := false, ratio := ratio);
  fi;
  return rec(accept := true, paut := PAut, ratio := ratio);
end;
```

The pipeline retries Stage 2 (resample circulant blocks) up to
a configurable maximum (default: 100 retries) before
escalating to a parameter-tuning error.

**LOC:** ~150 lines GAP. **Risk:** Low.

### 6.6 Work units

| ID | Title | Type | LOC | Risk | Depends on |
|----|-------|------|----:|------|------------|
| Q4.A.1 | `orbcrypt_paut_study.g` GAP script | GAP | 350 | Low | — |
| Q4.A.2 | Run study, produce CSV (`orbcrypt_paut_study.csv`) | Data | — | Med (result-dependent) | Q4.A.1 |
| Q4.A.3 | `docs/QC_PAUT_DISTRIBUTION.md` analysis document | Doc | 500 | Low | Q4.A.2 |
| Q4.B.1 | `KeyMgmt/StructuralFence.lean` — predicates + decidability | Lean def | 250 | Low | — |
| Q4.B.2 | Necessity theorem under `ShorAbelianHiddenAttack` | Lean thm | 200 | Med | Q4.B.1 |
| Q4.B.3 | `HGOEKeyExpansion` structurally_non_abelian field update | Lean def | 100 | Low | Q4.B.1 |
| Q4.B.4 | Update existing L1–L7 instances with concrete witnesses | Lean def | 80 | Low | Q4.B.3, Q4.C.2 |
| Q4.C.1 | `orbcrypt_keygen.g` Stage 2.5 update | GAP | 150 | Low | Q4.B.1 |
| Q4.C.2 | `orbcrypt_params.g` per-level threshold update | GAP | 50 | Low | Q4.A.3 |
| Q4.D.1 | `docs/PARAMETERS.md` §4 update — structural fence row | Doc | 80 | Low | Q4.A.3 |
| Q4.D.2 | `docs/DEVELOPMENT.md` §6.2 Stage 2.5 insertion | Doc | 50 | Low | Q4.C.1 |
| Q4.D.3 | `docs/HARDNESS_ANALYSIS.md` §4.2 cross-reference | Doc | 30 | Low | Q4.B.2 |
| Q4.D.4 | `docs/API_SURFACE.md` headline row for `concreteOIA_lt_one_implies_PAut_not_abelian` | Doc | 20 | Low | Q4.B.2 |
| Q4.E.1 | Audit script § 15.29 entries | Lean script | 50 | Low | Q4.B.2 |
| Q4.E.2 | CI gate #7 (GAP-Lean) test-vector regeneration | CI | — | Low | Q4.B.4 |
| **Q4 total** | | | **~1860** | | |

### 6.7 Cross-cutting with W-Q1

W-Q4's `IsStructurallyNonAbelian` is the upstream witness for
the `orbits_distinct` field of W-Q1's `HSPOIABundle`. The
cross-reference lemma lives in
`Orbcrypt/KeyMgmt/StructuralFence.lean` (or its companion):

```lean
/-- If a subgroup G is structurally non-abelian at any
    positive threshold, then there exist orbit-distinct pairs:
    bitstrings whose H₀={1}- and H₁=G-orbits differ. -/
theorem structurally_non_abelian_yields_orbit_distinct_pairs
    {n : ℕ} (G : Subgroup (Equiv.Perm (Fin n))) {θ : ℚ}
    (hθ : 0 < θ) (h : IsStructurallyNonAbelian G θ) :
    ∃ x : Bitstring n,
      MulAction.orbit (⊥ : Subgroup (Equiv.Perm (Fin n))) x ≠
        MulAction.orbit G x := ...
```

This theorem feeds W-Q1's bundle construction: a keygen-side
non-abelian witness automatically inhabits the `HSPOIABundle`
shape with H₀ = {1}, H₁ = G — exactly the decisional-HSP
instance W-Q1's reduction targets.

### 6.8 Risk register and rollback

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Empirical study (Q4.A.2) shows random circulant QC codes generically have small / abelian PAut | Med | **High** | Triggers a parameter-tuning sub-workstream W-Q4.X (not in scope here): reweight circulant generation, increase `b`, or constrain block sampling. Recorded in §10 contingency planning. |
| GAP `PermutationAutomorphismGroup` performance at L5 / L7 parameters | Med | Med | Use `nauty` / `bliss` via the `OrbitCryptUseFast` flag if available; fall back to GAP-native if not. |
| `IsStructurallyNonAbelian` decidability instance is slow on large groups | Low | Med | Lean-side decidability is only used for type-class search; runtime decidability is via the GAP keygen side. |
| `ShorAbelianHiddenAttack` predicate shape diverges from future quantum-framework definition | Med | Low | Predicate explicitly documented as research-scope, with shape contract in docstring. |
| Q4.D.1 parameter doc update triggers PARAMETERS.md §4 churn | Low | Low | Single additive table row; standard PR review. |

**Rollback.** Q4.B.\* (Lean fence) is purely additive; deletion
restores the codebase. Q4.A.\* (empirical study) is data and
documentation only, fully independent. Q4.C.\* (GAP pipeline
update) is the only non-trivial behavioural change; rollback
requires re-running the test vector cross-check (CI gate #7).

### 6.9 Exit criteria for Workstream W-Q4

W-Q4 closes when **all** of the following are demonstrably
true:

1. `lake build Orbcrypt.KeyMgmt.StructuralFence` and the
   updated `Orbcrypt.KeyMgmt.SeedKey` succeed clean.
2. `abelian_PAut_implies_oia_break_under_shorAbelianHidden`
   and `concreteOIA_lt_one_implies_PAut_not_abelian` are
   declared and proved.
3. `structurally_non_abelian_yields_orbit_distinct_pairs`
   (cross-cutting with W-Q1) is declared and proved.
4. `implementation/gap/orbcrypt_paut_study.csv` is committed
   with results from ≥ 1000 samples per parameter set.
5. `docs/QC_PAUT_DISTRIBUTION.md` exists at ≥ 450 lines with
   the empirical analysis.
6. `implementation/gap/orbcrypt_keygen.g` carries Stage 2.5
   and the GAP test suite (`orbcrypt_test.g`) exercises the
   fence.
7. The L1/L3/L5/L7 `HGOEKeyExpansion` instances carry concrete
   `structurally_non_abelian` witnesses.
8. `docs/PARAMETERS.md` §4 carries the structural-fence row.
9. `docs/DEVELOPMENT.md` §6.2 documents Stage 2.5.
10. CI gates #6 and #7 pass.
11. `docs/dev_history/WORKSTREAM_CHANGELOG.md` carries a W-Q4
    entry.

---

## 7. Workstream W-Q5 — TensorOIA / MEDS MinRank parameter discipline

### 7.1 Problem statement

The `ConcreteTensorOIA` predicate
(`Hardness/TensorAction.lean:453`) sits at the top of the
post-W6 hardness chain
(`Hardness/Reductions.lean:572` `ConcreteHardnessChain`). The
strongest assumption in the chain — corresponding to the
`docs/HARDNESS_ANALYSIS.md` §4.1 item 2 narrative ("no
quasi-poly algorithm known for TI"). Two `tight_one_exists`-style
ε = 1 witnesses are currently inhabited
(`Hardness/Reductions.lean:707` and `:757`); both are trivial.

The cryptanalytic concern is that the ATFE / MEDS / MinRank
attack literature
(`docs/HARDNESS_ANALYSIS.md` §4.2.4(c), citing
Tang–Duong–Joux–Plantard–Qiao–Susilo 2022 and the MEDS Round-2
analyses) is *younger and more actively evolving* than the
PEP / CE cryptanalysis underpinning the CE-OIA layer. Each new
algebraic-attack result on ATFE — and the broader MinRank /
support-decoding programme — tightens the parameter envelope
within which `ConcreteTensorOIA` at a given ε is satisfiable.
A non-trivial ε < 1 instantiation of `ConcreteTensorOIA` that
lands without a *current* parameter-review checkpoint risks
making release-facing quantitative claims that the latest
cryptanalysis has already invalidated.

The cryptanalytic gap (§1, finding QH-05) is twofold:

1. **No Lean carrier for parameter-review metadata.** The
   `ConcreteTensorOIA` predicate carries no field linking it
   to a documented parameter-review checkpoint. A caller can
   instantiate the predicate at any ε with no formal
   obligation to cite a current cryptanalysis review.
2. **No CI gate enforcing the discipline.** Adding a new
   non-trivial ε < 1 `ConcreteTensorOIA` instance is a
   release-facing change with significant cryptanalytic
   implications, but the project's CI gates do not
   distinguish it from any other Lean addition.

### 7.2 Fix selection

**Selected approach: light Lean carrier + process document +
CI script.** The full picture:

1. **Lean carrier (Q5.1).** Add a `TensorOIAParameterReview`
   structure that bundles parameter-review metadata
   (review-date, reference-document path, MinRank-attack-cost
   estimate). Add a non-binding companion predicate
   `IsParameterReviewed` to the
   `ConcreteTensorOIA`-instantiation API. The carrier is
   *advisory* at the type-system level (it does not block
   construction), but its absence is the signal CI scans for.
2. **Process document (Q5.2).** A canonical
   `docs/TENSOR_OIA_PARAMETER_DISCIPLINE.md` checklist that
   every author must walk before landing a non-trivial ε < 1
   `ConcreteTensorOIA` instance.
3. **CI script (Q5.3).** `scripts/audit_tensor_oia_parameters.py`
   scans the Lean tree for `ConcreteTensorOIA … ε`
   declarations with `ε < 1` and verifies that each is paired
   with a `TensorOIAParameterReview` carrier whose
   `referenceDocument` points to an existing doc.

**Excluded alternatives.**

- Modifying `ConcreteTensorOIA` to *require* the
  parameter-review field at the type-system level: rejected
  because it would force every existing trivial ε = 1
  inhabitation (which is currently unconditional and
  research-scope-friendly) to carry an unnecessary metadata
  carrier. The fence should bind only at the operationally
  significant point — ε < 1.
- Pure process discipline (no Lean carrier): rejected because
  the CI script needs *some* Lean-level field to scan; a
  carrier structure provides a stable target.

### 7.3 Target API shape (post-fix)

**`Orbcrypt/Hardness/TensorOIAParameterFence.lean`** —
~150 LOC.

```lean
/-- A parameter review checkpoint for a `ConcreteTensorOIA`
    instance. Bundles the metadata that a release-facing
    consumer needs to validate the cryptanalytic posture
    of the claimed ε bound. -/
structure TensorOIAParameterReview where
  /-- ISO 8601 date of last cryptanalytic review. -/
  reviewDate : String
  /-- Path (relative to repo root) to the parameter-review
      document the reviewer signed off against. The CI
      script verifies the path exists. -/
  referenceDocument : String
  /-- Claimed MinRank-attack cost, base-2 logarithm. The
      review-document content backs this value. -/
  minRankAttackCostLog2 : ℕ
  /-- Claimed ATFE-attack cost, base-2 logarithm. -/
  atfeAttackCostLog2 : ℕ
  /-- Reviewer name(s). Free-text. -/
  reviewer : String

/-- An attached parameter review accompanying a
    `ConcreteTensorOIA` instance at a specific ε. Advisory
    at the type-system level. -/
structure ConcreteTensorOIAWithReview
    {F : Type*} {n : ℕ} (T₀ T₁ : Tensor3 n F) (ε : ℝ) where
  hardness : ConcreteTensorOIA T₀ T₁ ε
  review : TensorOIAParameterReview
  /-- Soundness obligation: the claimed ε is consistent with
      the review's claimed attack costs. Specifically:
      ε ≥ 2 ^ (-min(minRankAttackCostLog2, atfeAttackCostLog2)).
      The fraction shape avoids `Real.log` /
      `Real.exp` machinery. -/
  ε_consistent_with_review :
    (2 : ℝ) ^ (-((min review.minRankAttackCostLog2
                  review.atfeAttackCostLog2 : ℕ) : ℝ)) ≤ ε

/-- Forgetting the review yields the bare hardness. -/
def ConcreteTensorOIAWithReview.toHardness
    {F : Type*} {n : ℕ} {T₀ T₁ : Tensor3 n F} {ε : ℝ}
    (W : ConcreteTensorOIAWithReview T₀ T₁ ε) :
    ConcreteTensorOIA T₀ T₁ ε := W.hardness

/-- At ε = 1, no review is needed (trivial bound). The
    `tight_one_exists` family of inhabitations remains
    review-free. -/
theorem concreteTensorOIA_one_no_review_needed
    {F : Type*} {n : ℕ} (T₀ T₁ : Tensor3 n F) :
    ConcreteTensorOIA T₀ T₁ 1 :=
  concreteTensorOIA_one T₀ T₁
```

The key API decision: `ConcreteTensorOIAWithReview` is a
*wrapper* around `ConcreteTensorOIA`, not a replacement. Every
existing `concreteTensorOIA_one` / `tight_one_exists` /
`tight_one_exists_at_s2Surrogate` inhabitation continues to
work unchanged.

### 7.4 The `docs/TENSOR_OIA_PARAMETER_DISCIPLINE.md` checklist

**File:** `docs/TENSOR_OIA_PARAMETER_DISCIPLINE.md` (new).
**Sections.**

- §1 Scope and trigger conditions — when this checklist
  applies (any new or modified `ConcreteTensorOIA … ε`
  declaration with ε < 1).
- §2 Review components.
  - §2.1 MinRank-modeling complexity estimate, citing the
    Verbel et al. 2019 / Bardet et al. 2020 framework.
  - §2.2 ATFE attack landscape review, citing
    Tang–Duong–Joux–Plantard–Qiao–Susilo 2022 and the
    most recent MEDS Round-N cryptanalysis state.
  - §2.3 Hybrid algebraic-combinatorial attack survey.
  - §2.4 Surrogate-specific structural attack survey (for
    `SurrogateTensor F` instances beyond
    `punitSurrogate` / `s2Surrogate`).
- §3 Sign-off template.
  - §3.1 Required reviewer roles (cryptanalyst + project lead).
  - §3.2 Sign-off form (date, reviewer name, MinRank cost,
    ATFE cost, recommended ε bound).
- §4 Review-document template (Markdown skeleton for the
  reviewer-produced document the
  `TensorOIAParameterReview.referenceDocument` field points
  to).
- §5 Past reviews catalogue (initially empty; populated as
  reviews land).

**LOC:** ~400 lines doc. **Risk:** Low.

### 7.5 The CI script

**File:** `scripts/audit_tensor_oia_parameters.py` (new).
**Behaviour.**

1. Walk `Orbcrypt/**/*.lean`, grep for declarations of type
   `ConcreteTensorOIA` and `ConcreteTensorOIAWithReview`.
2. For each `ConcreteTensorOIA … ε` declaration with ε < 1,
   verify a matching `ConcreteTensorOIAWithReview` carrier
   exists in the same file (or its sibling) and that the
   `referenceDocument` field's path exists and is non-empty.
3. Exit non-zero on any failure, printing the offending
   declaration and the missing carrier.

```python
#!/usr/bin/env python3
"""Audit ConcreteTensorOIA instances against the parameter-review fence."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LEAN_GLOB = "Orbcrypt/**/*.lean"
PATTERN_TENSOR_OIA = re.compile(
    r"ConcreteTensorOIA\s+[^\n]+?\s+(\d+(?:\.\d+)?)")
PATTERN_REVIEW = re.compile(
    r"referenceDocument\s*:=\s*\"([^\"]+)\"")

def audit() -> int:
    violations = []
    for lean_file in ROOT.glob(LEAN_GLOB):
        text = lean_file.read_text()
        for match in PATTERN_TENSOR_OIA.finditer(text):
            eps = float(match.group(1))
            if eps >= 1.0:
                continue  # trivial; skip
            # search for an accompanying review in same file
            review_match = PATTERN_REVIEW.search(text)
            if not review_match:
                violations.append(
                    (lean_file, eps, "no TensorOIAParameterReview"))
                continue
            ref_doc = ROOT / review_match.group(1)
            if not ref_doc.exists():
                violations.append(
                    (lean_file, eps,
                     f"referenceDocument {ref_doc} missing"))
    for lean_file, eps, reason in violations:
        print(f"VIOLATION: {lean_file} at ε={eps}: {reason}")
    return 1 if violations else 0

if __name__ == "__main__":
    sys.exit(audit())
```

**LOC:** ~100 lines Python. **Risk:** Low.

The script joins the existing CI gates as **gate #9**
(`.github/workflows/lean4-build.yml` step "Tensor-OIA
parameter discipline").

### 7.6 Work units

| ID | Title | Type | LOC | Risk | Depends on |
|----|-------|------|----:|------|------------|
| Q5.1 | `Hardness/TensorOIAParameterFence.lean` — carrier structure | Lean def | 150 | Low | — |
| Q5.2 | `docs/TENSOR_OIA_PARAMETER_DISCIPLINE.md` checklist | Doc | 400 | Low | — |
| Q5.3 | `scripts/audit_tensor_oia_parameters.py` CI script | Py | 100 | Low | Q5.1 |
| Q5.4 | `.github/workflows/lean4-build.yml` — gate #9 wiring | CI | 30 | Low | Q5.3 |
| Q5.5 | `docs/HARDNESS_ANALYSIS.md` §4 update: new attack-cost table column | Doc | 60 | Low | Q5.2 |
| Q5.6 | `docs/HARDNESS_ANALYSIS.md` §4.2.4(c) update: cross-reference to discipline | Doc | 40 | Low | Q5.2 |
| Q5.7 | `CLAUDE.md` / `AGENTS.md` § Pre-merge checks: gate #9 documentation | Doc | 30 | Low | Q5.4 |
| Q5.8 | Audit script § 15.30 entry | Lean script | 30 | Low | Q5.1 |
| **Q5 total** | | | **~840** | | |

### 7.7 Risk register and rollback

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Q5.3 Python script grep-pattern misses Lean syntax variants (e.g., `ConcreteTensorOIA scheme F S ε` vs `ConcreteTensorOIA T₀ T₁ ε`) | Med | Med | Pattern handles both shapes; CI runs on every PR; false negatives surface immediately. |
| `ConcreteTensorOIAWithReview` becomes adoption-inhibiting friction | Low | Low | Only ε < 1 instantiations need it; ε = 1 inhabitations remain unchanged. |
| Review-document template encourages box-checking rather than substantive review | Med | Med | Q5.2 §3 requires named reviewer (two roles) and specific numeric attack-cost estimates with literature citation; box-checking trivially fails CI's syntactic check on `minRankAttackCostLog2` ≥ λ. |
| Discipline drift: reviewers don't re-validate when cryptanalysis advances | Med | Med | Q5.2 §3.2 includes a `reviewExpiresAfter` field (default 12 months); CI emits a warning when the most recent review's date is > 12 months old. |

**Rollback.** Pure additive at every layer. Deletion restores
the codebase to pre-plan state.

### 7.8 Exit criteria for Workstream W-Q5

W-Q5 closes when **all** of the following are demonstrably
true:

1. `lake build Orbcrypt.Hardness.TensorOIAParameterFence`
   succeeds clean.
2. `ConcreteTensorOIAWithReview` and its sanity lemmas are
   declared and proved.
3. `concreteTensorOIA_one_no_review_needed` is declared and
   proved (preserving the ε = 1 review-free baseline).
4. `docs/TENSOR_OIA_PARAMETER_DISCIPLINE.md` exists at ≥ 350
   lines with the per-section structure of §7.4.
5. `scripts/audit_tensor_oia_parameters.py` exists and
   exits 0 on the current codebase (which has no ε < 1
   `ConcreteTensorOIA` instances).
6. `.github/workflows/lean4-build.yml` carries gate #9.
7. `CLAUDE.md` / `AGENTS.md` § Pre-merge checks document
   the new gate.
8. `docs/HARDNESS_ANALYSIS.md` §4 carries the discipline
   cross-reference.
9. CI gates #1–#9 pass.
10. `docs/dev_history/WORKSTREAM_CHANGELOG.md` carries a W-Q5
    entry.

---

## 8. Cross-cutting concerns

### 8.1 Zero-`axiom` discipline

Every Lean module introduced by this plan adheres to the
project-wide zero-custom-`axiom` policy (`CLAUDE.md` §
Absolute policies). The plan introduces **no** `axiom`
declarations. All hardness assumptions — `ConcreteHSPSn`,
`CFIHardness`, `CFIForwardDirection` (if staged),
`ShorAbelianHiddenAttack`, `CosetStateFourierResistance` — are
`Prop`-valued definitions. Theorems carry them as explicit
hypotheses; consumers discharge them at the call-site.

The Phase-16 audit script (`scripts/audit_phase_16.lean`)
extends with five new sections (§§15.26–15.30, one per
workstream) auditing the new declarations via
`#print axioms`. Every declaration must report the canonical
triple `[propext, Classical.choice, Quot.sound]` (or
"does not depend on any axioms"). A `sorryAx` in any
transitive dependency is a release-gate failure.

### 8.2 Naming hygiene — content-describing identifiers only

Every declaration introduced by this plan is content-named.
The plan's stable IDs (`W-Q1` … `W-Q5`, `Q1.1` … `Q5.8`,
`QH-01` … `QH-05`, `R-Q3`) appear **only** in:

- this plan document and its sibling planning docs;
- `docs/dev_history/WORKSTREAM_CHANGELOG.md` entries;
- commit messages, branch names, PR titles;
- docstring traceability notes (e.g.,
  `/-- … (audit 2026-05-13 / W-Q1) -/`);
- section banners in source files (e.g.,
  `-- ==== W-Q1: HSP_{S_n} → OIA reduction ====`).

The grep-recipe at `CLAUDE.md` § Enforcement at review time
must pass on every commit landing W-Q1 … W-Q5 content. See
Appendix C for the canonical declaration-name patterns per
workstream.

### 8.3 Documentation-vs-code parity

The plan modifies five canonical documents per the
ownership matrix in `CLAUDE.md` § Cross-document update
rules:

| Canonical doc | Changes from | Touches |
|---------------|--------------|---------|
| `docs/DEVELOPMENT.md` | W-Q1, W-Q2, W-Q3, W-Q4 | §§5.3, 5.4.2, 6.2, 8.2, 8.4.2 |
| `docs/API_SURFACE.md` | W-Q1, W-Q2, W-Q3, W-Q4 | Headline-theorem table (new rows for each workstream's headline) |
| `docs/VERIFICATION_REPORT.md` | All five | Release-readiness checklist + headline-results table |
| `docs/HARDNESS_ANALYSIS.md` | W-Q1, W-Q2, W-Q4, W-Q5 | §§1.6 (new), 3 (chain diagram), 4.2 (cross-refs), §4 attack-cost table |
| `docs/PARAMETERS.md` | W-Q4, W-Q5 | §§3 ‡ (Q2 cross-ref), 4 (structural fence row) |

Two new canonical documents land:

- `docs/Q2_MODEL_ANALYSIS.md` — owned by W-Q3.
- `docs/TENSOR_OIA_PARAMETER_DISCIPLINE.md` — owned by W-Q5.

One new sub-canonical document:

- `docs/QC_PAUT_DISTRIBUTION.md` — owned by W-Q4, paired with
  `implementation/gap/orbcrypt_paut_study.csv` as data.

`CLAUDE.md` and `AGENTS.md` carry the byte-identical
release-messaging policy. Both update in lockstep when W-Q2
extends the citation discipline with CFI / GQ conditional
status markers and W-Q5 adds CI gate #9 to the pre-merge
checklist.

### 8.4 Audit-script coverage

`scripts/audit_phase_16.lean` extends with five new sections,
one per workstream:

| Section | Workstream | Adds | New `#print axioms` lines |
|---------|------------|------|---------------------------|
| §15.26 | W-Q1 | HSP-to-OIA reduction + ε=1 witness | 6 |
| §15.27 | W-Q2 | CFI + GQ-OIA chained witnesses | 8 |
| §15.28 | W-Q3 | Q2 stub framework + conditional theorem | 4 |
| §15.29 | W-Q4 | Structural fence + necessity theorem | 6 |
| §15.30 | W-Q5 | TensorOIA parameter-review carrier + sanity | 3 |
| **Total** | | | **27** |

Each entry follows the existing `audit_phase_16.lean`
template: `#print axioms` for the declared theorem,
followed by a non-vacuity witness example for any
`Prop`-valued hypothesis introduced.

### 8.5 Lake-manifest hygiene

The plan introduces no new Mathlib dependencies beyond what
the pinned `lean-toolchain` (`v4.30.0-rc1`) and
`lake-manifest.json` already provide. Specifically:

- `Mathlib.GroupTheory.Commutator` — used by W-Q4 (already
  imported by `Hardness/CodeEquivalence.lean` transitively).
- `Mathlib.Combinatorics.SimpleGraph.{Basic, Connectivity}` —
  used by W-Q2 CFI leg (new direct imports).
- `Mathlib.LinearAlgebra.{Matrix, Tensor}` — used by W-Q2 GQ
  leg (already imported by `Hardness/TensorAction.lean`).
- `Mathlib.Probability.ProbabilityMassFunction.Constructions` —
  used by W-Q1 advantage definition (already imported).

CI gate #4 (`lake-manifest.json` drift check) must continue
to pass after each W-Q\* PR. The plan introduces no new
`require ... @ git` directives in `lakefile.lean`.

### 8.6 GAP-Lean cross-check (CI gate #7)

W-Q4's Stage 2.5 keygen-fence update changes the keygen
output distribution (some random samples are rejected). The
committed test-vector file
`implementation/gap/lean_test_vectors.txt` must remain
consistent with the Lean `CanonicalForm.ofLexMin` semantics
under the new pipeline. Two impacts:

1. **Test-vector regeneration.** W-Q4.E.2 re-runs
   `lake env lean scripts/generate_test_vectors.lean >
   implementation/gap/lean_test_vectors.txt` after the keygen
   pipeline update. The resulting file may differ from the
   pre-plan version *only* in which keys appear (the keys
   that survive the new fence are a strict subset).
2. **GAP cross-check regression.** The
   `TestLeanVectors()` call in
   `implementation/gap/orbcrypt_test.g` must continue to
   return `true` on the new test-vector file. Verified by
   CI gate #7.

### 8.7 Performance and resource budgets

| Workstream | New Lean LOC | Build-time impact | Test-suite impact |
|------------|-------------:|-------------------|-------------------|
| W-Q1 | 1100 | +5–8s (cold build); cached after | +0.3s (audit_phase_16) |
| W-Q2 | 2000 | +20–30s (CFI + GQ encoder is the big one) | +1.0s (cardinality lemmas, cycle space) |
| W-Q3 | 1000 | +6–10s | +0.5s |
| W-Q4 | 550 | +3–5s | +1.5s (decidability instances on Subgroup) |
| W-Q5 | 150 | +1–2s | +0.2s |
| **Aggregate** | **4800** | **+35–55s cold; <5s cached** | **+3.5s** |

GAP study (Q4.A.2) wall-clock at L7 with
`PermutationAutomorphismGroup` may exceed 12h per parameter
set on standard hardware; the workstream provides for running
the study on a dedicated cryptanalysis workstation. Output
is committed as the CSV; the study is not run in CI.

### 8.8 Background-agent file-change protection

Several workstreams are parallelisable (per §10), and some
work-units within a workstream can run in parallel. The
plan adheres to `CLAUDE.md` § Background-agent file-change
protection:

- **Partition discipline.** Each W-Q\* workstream owns a
  disjoint set of new files (see §2.1). When a background
  agent is delegated work within a workstream, the prompt
  explicitly names the files the agent owns.
- **Cross-workstream coordination.** W-Q1 and W-Q4 share
  `Orbcrypt/KeyMgmt/StructuralFence.lean` only via a
  *one-way* import: W-Q4 introduces the file; W-Q1
  consumes the
  `structurally_non_abelian_yields_orbit_distinct_pairs`
  lemma. Sequencing ensures W-Q4.B.1 lands before W-Q1.Q1.4.
  When both workstreams run in parallel, W-Q1's HSP bundle
  construction is gated on the W-Q4 lemma being merged.
- **Shared canonical-doc edits.** `docs/DEVELOPMENT.md`,
  `docs/API_SURFACE.md`, and the byte-identical
  `CLAUDE.md` / `AGENTS.md` pair are touched by multiple
  workstreams. The plan §12 lays out a strict landing
  order to avoid concurrent edits; each workstream's
  doc-update PR lands sequentially within its workstream
  ship-cycle.

---

## 9. Consolidated risk register

Aggregating the per-workstream risk registers (§§3.6, 4.8,
5.5, 6.8, 7.7) and the cross-cutting risks (§8). Risks are
classified by likelihood (L / M / H) and impact (L / M / H),
with the product (L\*\*M = Med; M\*\*M = High; etc.) shaping
mitigation aggressiveness.

| ID | Risk | L | I | Workstream | Mitigation reference |
|----|------|:-:|:-:|------------|----------------------|
| R-Q.01 | CFI forward direction (Q2.A.3b) proves > 300 LOC | M | M | W-Q2 | §4.3 (stage as research-scope hypothesis) |
| R-Q.02 | R-TI Phase 3 (`h_research` discharge) slips, blocking W-Q2.B | M | M | W-Q2 | §4.6 alt-sub-unit Q2.B.1.alt |
| R-Q.03 | Empirical PAut distribution (Q4.A.2) shows small / abelian PAut at recommended parameters | M | H | W-Q4 | §6.8 contingency W-Q4.X parameter-tuning sub-stream |
| R-Q.04 | GAP `PermutationAutomorphismGroup` performance bottleneck at L5 / L7 | M | M | W-Q4 | §6.8 (nauty / bliss fallback) |
| R-Q.05 | `ConcreteTensorOIAWithReview` adoption friction | L | L | W-Q5 | §7.7 (only ε<1 needs it) |
| R-Q.06 | `CosetStateFourierResistance` shape diverges from future Q2 framework | M | M | W-Q3 | §5.5 (shape contract in docstring) |
| R-Q.07 | `Subgroup.carrier.image` API friction | M | L | W-Q1 | §3.6 (switch to `Subgroup.rightCoset`) |
| R-Q.08 | Audit-script `sorryAx` surfaces in transitive dependency | L | H | All | §8.4 (CI gate #6 catches at PR time) |
| R-Q.09 | Doc-parity update lag (canonical docs drift from Lean content) | M | M | All | §8.3 (mandated same-PR updates per CLAUDE.md) |
| R-Q.10 | Background agent overwrites foreground file edits | L | H | W-Q2, W-Q4 (largest LOC) | §8.8 (partition discipline) |
| R-Q.11 | Naming-rule violation in late-landing PR | M | L | All | §8.2 (per-PR grep recipe) |
| R-Q.12 | GAP test-vector cross-check (CI #7) regresses after Q4.E.2 | L | H | W-Q4 | §8.6 (regeneration is mechanical; CI catches) |
| R-Q.13 | Discipline drift: TensorOIA review expires without re-review | M | M | W-Q5 | §7.7 (12-month reviewExpiresAfter warning) |
| R-Q.14 | Q4.A.2 wall-clock exceeds budget on standard hardware | M | L | W-Q4 | §8.7 (dedicated cryptanalysis workstation) |
| R-Q.15 | Existing `OrbitEncScheme` shape insufficient for two-orbit instances | L | M | W-Q1 | §3.4 (≤30 LOC additive refactor scoped) |

**Highest-priority follow-on contingency.** R-Q.03 (W-Q4
empirical-result negative) is the only risk that could
escalate beyond this plan's scope. If the PAut empirical
study shows random circulant QC codes have
abelian-degenerate PAut with > 5% probability, the
keygen-pipeline reweighting (W-Q4.X) becomes a release-blocker
and the plan extends. The contingency W-Q4.X is sketched in
§10.4 below.

---

## 10. Sequencing and release-gate alignment

### 10.1 Critical paths

Three parallelisable critical paths, named by their dominant
deliverables.

**Path A — Quantitative chain firming.**

```
  W-Q2 ────────────────► W-Q5
  (9–11 wk)            (3–4 wk)
```

Sequential within the path. Total wall-clock: **12–15 wk**
sequential, or **9–12 wk** with W-Q5 documentation (Q5.2,
Q5.6, Q5.7) starting in parallel with W-Q2 mid-stream.

**Path B — Narrative-pillar firming.**

```
  W-Q1                W-Q4
  (5–7 wk)           (5–7 wk)
       │                  │
       └─── one-way import dependency ──┘
          (W-Q4.B.1 must land before W-Q1.Q1.4 consumes
           structurally_non_abelian_yields_orbit_distinct_pairs)
```

Mostly parallel. Total wall-clock: **6–8 wk** with the
W-Q1 ↔ W-Q4 import sequencing.

**Path C — Research-scope (parallel).**

```
  W-Q3
  (7–9 wk)
```

Fully independent. Total wall-clock: **7–9 wk**.

### 10.2 Recommended sequencing

The recommended sequencing positions Path A as the
release-blocking spine, Path B as the narrative-firming
companion that closes the cryptographic-review findings, and
Path C as a research-scope deliverable that can ship at
release-time or shortly after.

| Phase | Calendar weeks | Workstreams running | Headcount required |
|-------|---------------:|---------------------|-------------------:|
| 1 | wk 1–6 | W-Q1, W-Q4, W-Q3 (all in parallel) | 3 |
| 2 | wk 6–12 | W-Q2 (started after W-Q4 ships), W-Q3 (continuing) | 2 |
| 3 | wk 12–15 | W-Q5 (started after W-Q2 mid-stream), W-Q3 closing | 2 |
| **Total** | **~15 weeks** | | |

With a 2-engineer team the same plan extends to ~18 weeks
(W-Q3 launches at wk 6 instead of wk 1). With a 1-engineer
team, the plan extends to ~26 weeks fully sequential. The
plan does not depend on any specific staffing model — the
critical paths are defined by content, not personnel.

### 10.3 Release-gate alignment

The plan aligns to two release gate categories defined in
`CLAUDE.md` § Pre-merge checks and the headline-status table
in `docs/API_SURFACE.md`.

**Pre-merge gates (CI #1–#9).** All workstreams must pass
gates #1–#7 (existing) and gate #9 (new, from W-Q5).
W-Q1 / W-Q4 cross-cutting integration is gated by gate #6
(`audit_phase_16.lean` exit 0).

**Release messaging.** No workstream changes the Status
classification of an existing headline theorem. New rows
added per workstream:

- W-Q1 → 2 new rows (Conditional, Standalone-at-ε=1).
- W-Q2 → 3 new rows (one Conditional, two Standalone-at-ε=1).
- W-Q3 → 1 new row (Conditional, R-Q3-flagged).
- W-Q4 → 2 new rows (one Conditional, one Standalone).
- W-Q5 → 1 new row (Standalone, advisory-carrier).

**Total new headline-table rows.** 9 new rows in
`docs/API_SURFACE.md`. Each row reproduces the theorem name,
file path, hypothesis chain, ε regime, and Status.

### 10.4 Contingency: W-Q4.X parameter reweighting

If risk R-Q.03 materialises (Q4.A.2 shows abelian-degenerate
PAut at > 5% of random samples), the contingency W-Q4.X
sub-workstream activates. Scope sketch:

- W-Q4.X.1 — Investigate circulant-block reweighting
  strategies (constrained random sampling that biases toward
  non-commuting block pairs).
- W-Q4.X.2 — Empirical study of reweighted samples (paralleling
  Q4.A.2).
- W-Q4.X.3 — Update `docs/PARAMETERS.md` §6 with reweighted
  parameter recommendations.
- W-Q4.X.4 — `implementation/gap/orbcrypt_keygen.g` Stage 2
  refactor to use reweighted sampling.
- W-Q4.X.5 — Re-run W-Q4.A.2 to verify the reweighting
  achieves > 95% acceptance rate at the structural fence.

Estimated W-Q4.X effort: 4–6 weeks. The plan reserves this
as an explicit contingency, scoped but not staffed.

---

## 11. CI and audit-script updates

### 11.1 New CI gate #9 — TensorOIA parameter discipline

Added by W-Q5 to `.github/workflows/lean4-build.yml`:

```yaml
- name: Tensor-OIA parameter discipline
  run: python3 scripts/audit_tensor_oia_parameters.py
```

Failure mode: any `ConcreteTensorOIA … ε` declaration with
ε < 1 lacking a `ConcreteTensorOIAWithReview` carrier whose
`referenceDocument` exists. Failure exits non-zero; PR
cannot merge.

### 11.2 Audit-script extension — §§15.26–15.30

`scripts/audit_phase_16.lean` extends with five new
sections per §8.4 above. The script's existing structure is:

```
-- Section 15.1: <existing section>
#print axioms <theorem>
example : <non-vacuity witness> := ...
```

Each new section follows this template. The script's exit
contract is unchanged: every `#print axioms` line must
report `[propext, Classical.choice, Quot.sound]` or "does
not depend on any axioms".

### 11.3 No other CI changes

The plan deliberately does not modify CI gates #1–#5, #7,
or #8. The existing gate semantics are preserved.

### 11.4 Audit-script per-workstream entries

The full content of the new audit-script entries is
described in Appendix C. Each workstream's exit criteria
explicitly require its audit-script section to be appended
and passing.

---

## 12. Documentation-parity updates

### 12.1 Per-canonical-doc impact

The plan's doc-parity changes, by canonical document, in the
order they land:

**`docs/DEVELOPMENT.md`.**

- §5.3 — W-Q2 finalises the CFI sub-section (currently
  prose-only) with cross-references to the new Lean modules.
- §5.4.2 — W-Q1 adds cross-references to `concrete_hsp_sn_implies_concrete_oia`
  and the HSP-to-OIA chain entry.
- §6.2 — W-Q4 documents Stage 2.5 keygen fence.
- §8.2 — W-Q1 cross-references the `indQCPA_bound_from_hsp_sn_hardness`
  corollary.
- §8.4.2 — W-Q3 adds a Q2-pillar sub-section; W-Q1
  cross-references the formalised HSP reduction.

**`docs/HARDNESS_ANALYSIS.md`.**

- §1.6 (new) — W-Q1 adds "HSP_{S_n} (decisional)" entry to
  the problem-definition catalogue.
- §3 — W-Q2 updates the chain diagram with the new CFI / GQ
  ε-bands and the new Lean theorem cross-references.
- §3.x (new) — W-Q1 adds the HSP-to-OIA reduction
  sub-section.
- §4 — W-Q5 extends the hardness-comparison table with two
  new columns (MinRank-attack cost, ATFE-attack cost).
- §4.2 — W-Q4 cross-references the structural-fence theorem.
- §4.2.4(c) — W-Q5 cross-references the parameter-review
  discipline.

**`docs/API_SURFACE.md`.**

- Headline-theorem table — 9 new rows per §10.3.

**`docs/VERIFICATION_REPORT.md`.**

- Headline-results table — 9 new rows (mirrored from
  `docs/API_SURFACE.md`).
- Release-readiness checklist — five new checkbox items, one
  per workstream.

**`docs/PARAMETERS.md`.**

- §3 ‡ — W-Q3 cross-references the Q2-model analysis.
- §4 — W-Q4 adds the structural-fence row.

**`docs/POE.md`, `docs/COUNTEREXAMPLE.md`, `docs/PUBLIC_KEY_ANALYSIS.md`.**

- No changes. (The plan's content does not affect the
  high-level concept exposition, vulnerability analysis, or
  public-key feasibility story.)

**`CLAUDE.md` / `AGENTS.md`.**

- § Pre-merge checks — W-Q5 documents new gate #9.
- § Absolute policies → Release messaging policy — W-Q2
  extends the citation discipline with CFI / GQ Conditional
  status markers.

**Two new canonical documents.**

- `docs/Q2_MODEL_ANALYSIS.md` — W-Q3.
- `docs/TENSOR_OIA_PARAMETER_DISCIPLINE.md` — W-Q5.

**One new sub-canonical document + data file.**

- `docs/QC_PAUT_DISTRIBUTION.md` + `implementation/gap/orbcrypt_paut_study.csv` —
  W-Q4.

### 12.2 Same-PR rule

Every code-changing PR within the plan **must** land its
corresponding doc-parity updates in the same PR. This is a
hard rule enforced by review-checklist item 19.4 in the
2026-04-23 audit plan (which the plan adopts unchanged). A
PR that lands a Lean theorem without updating
`docs/API_SURFACE.md` and (where applicable) `docs/VERIFICATION_REPORT.md`
is not mergeable.

### 12.3 Cross-document update rule alignment

The plan's doc-parity ownership matrix (§8.3) is consistent
with `CLAUDE.md` § Cross-document update rules. Specifically,
the canonical-ownership pairings:

- `docs/DEVELOPMENT.md` — full scheme spec.
- `docs/API_SURFACE.md` — formalisation inventory.
- `docs/dev_history/formalization/FORMALIZATION_PLAN.md` —
  Lean 4 architecture and conventions (no changes from this
  plan).
- `docs/POE.md` — concept exposition (no changes).
- `docs/COUNTEREXAMPLE.md` — vulnerability analysis (no
  changes).

---

## 13. Acceptance criteria and signoff

### 13.1 Plan-level acceptance criteria

The plan as a whole closes when **all** of the following are
demonstrably true:

1. **All five workstream-level exit criteria are met.** See
   §§3.7, 4.9, 5.6, 6.9, 7.8 for the per-workstream lists.
2. **Aggregate Lean LOC budget held.** Total new LOC across
   `Orbcrypt/**/*.lean` is within +10% / -20% of the planned
   ~4800 LOC. Overshoot beyond +10% triggers a re-planning
   review.
3. **Audit-script extension complete.** Sections §§15.26–15.30
   of `scripts/audit_phase_16.lean` are appended and the
   script exits 0 with all 27 new `#print axioms` lines
   reporting the canonical triple.
4. **CI gates green.** Gates #1–#9 pass on the integrating
   branch. The branch's `main` rebase preserves the green
   state.
5. **Canonical-doc parity.** Every change-log entry in
   `docs/dev_history/WORKSTREAM_CHANGELOG.md` traceable to a
   landed commit; every new headline-theorem row in
   `docs/API_SURFACE.md` matches a row in
   `docs/VERIFICATION_REPORT.md`; every `Conditional`-Status
   citation in the canonical docs names its hypothesis
   inline.
6. **Naming-rule grep clean.** The recipe from `CLAUDE.md`
   § Enforcement at review time, run against the integrating
   branch's diff vs `main`, returns empty.
7. **No new `axiom` declarations.** `grep -rEn '^axiom\s+\w+\s*[\[({:]' Orbcrypt/`
   returns empty.
8. **No new `sorry` declarations.** The CI "Verify no sorry"
   step passes.
9. **Three new canonical documents land.**
   `docs/Q2_MODEL_ANALYSIS.md`,
   `docs/TENSOR_OIA_PARAMETER_DISCIPLINE.md`, and
   `docs/QC_PAUT_DISTRIBUTION.md` exist at their planned
   line counts and structure.

### 13.2 Definition of "shipped"

A workstream is "shipped" when it has individually closed
all of its §3.7 / §4.9 / §5.6 / §6.9 / §7.8 exit criteria
**and** its content has merged to `main` via a single PR (or
a strictly-coupled PR series identified in the PR
description). Per the project's "one commit per completed
work unit" convention, workstream-level merges land as a
series of commits, but the workstream is "shipped" only when
the last commit lands on `main` and CI is green.

### 13.3 Sign-off matrix

| Role | Responsibility |
|------|----------------|
| Project lead | Plan-level acceptance (§13.1 items 1–9), workstream prioritisation, contingency triggering (W-Q4.X) |
| Lean reviewer | Per-PR review (audit-script entries, naming-rule grep, zero-`axiom` discipline) |
| Cryptanalyst | W-Q4 empirical-study interpretation, W-Q5 parameter reviews, R-Q3 closure trajectory |
| GAP engineer | W-Q4.A.\*, W-Q4.C.\* GAP pipeline updates, CI gate #7 cross-check after Q4.E.2 |

The plan does not assume any specific staffing assignments;
the matrix names roles, not people.

### 13.4 Post-completion review

After plan completion, a structural-review checkpoint
parallel to `docs/dev_history/AUDIT_2026-05-06_STRUCTURAL_REVIEW.md`
is recommended (target date: 4–6 weeks post-completion). The
checkpoint:

- Reviews the integrating branch's API surface for any
  process-marker leakage in declaration names.
- Re-runs the cryptographer's review against the firmed
  quantum-hardness narrative.
- Validates the W-Q4 empirical-study results have not been
  invalidated by subsequent parameter changes.
- Re-runs `scripts/audit_tensor_oia_parameters.py` against
  any new `ConcreteTensorOIA` instances landed since
  workstream completion.

---

## Appendix A — Finding ↔ workstream cross-reference

### A.1 Findings closure matrix

Repeats §2.3 with per-work-unit granularity.

| Finding | Closing workstream | Closing work units | Cross-references |
|---------|--------------------|--------------------|-----------------:|
| QH-01 (HSP→OIA informal) | W-Q1 | Q1.1–Q1.12 | W-Q4.cross-cutting (§3.5, §6.7) |
| QH-02 (ε<1 inhabitation) | W-Q2 | Q2.A.1–Q2.D.4 | W-Q5.cross-cutting (§4.7, §7.5) |
| QH-03 (Q2 model) | W-Q3 (R-Q3) | Q3.1–Q3.12 | — |
| QH-04 (PAut abelian-degenerate) | W-Q4 | Q4.A.1–Q4.E.2 | W-Q1.cross-cutting (§3.5, §6.7) |
| QH-05 (TensorOIA parameter discipline) | W-Q5 | Q5.1–Q5.8 | W-Q2.cross-cutting (§4.7, §7.5) |

### A.2 Per-canonical-doc impact summary

| Doc | W-Q1 | W-Q2 | W-Q3 | W-Q4 | W-Q5 |
|-----|:----:|:----:|:----:|:----:|:----:|
| DEVELOPMENT.md | §5.4.2, 8.2, 8.4.2 | §5.3 | §8.4.2 (Q2 sub-section) | §6.2 (Stage 2.5) | — |
| API_SURFACE.md | 2 new rows | 3 new rows | 1 new row | 2 new rows | 1 new row |
| VERIFICATION_REPORT.md | mirror | mirror | mirror | mirror | mirror |
| HARDNESS_ANALYSIS.md | §1.6 (new), §3.x (new) | §3 chain | — | §4.2 cross-ref | §4 attack-cost columns, §4.2.4(c) |
| PARAMETERS.md | — | — | §3 ‡ cross-ref | §4 fence row | — |
| Q2_MODEL_ANALYSIS.md | — | — | New canonical | — | — |
| TENSOR_OIA_PARAMETER_DISCIPLINE.md | — | — | — | — | New canonical |
| QC_PAUT_DISTRIBUTION.md | — | — | — | New canonical | — |
| CLAUDE.md / AGENTS.md | — | release-msg | — | — | pre-merge §, release-msg |

### A.3 Work-unit ID ↔ commit-message tag mapping

For each work-unit ID `QN.X.Y`, the commit-message convention
is `[W-QN][QN.X.Y] <imperative-summary>`. Example:

> `[W-Q1][Q1.5] add hspOIABundleToScheme encoder and orbit-distinctness lemma`

This tag is forbidden in declaration names (per §8.2) but is
expected in the commit message and the
`docs/dev_history/WORKSTREAM_CHANGELOG.md` entry.

---

## Appendix B — Mathematical references

### B.1 Hidden Subgroup Problem on S_n

1. **Hallgren, S., Russell, A., & Ta-Shma, A.** (2003). The
   Hidden Subgroup Problem and Quantum Computation Using
   Group Representations. *SIAM Journal on Computing*, 32(4),
   pp. 916–934. — The weak Fourier sampling negative result
   on S_n.
2. **Moore, C., Russell, A., & Schulman, L.J.** (2008). The
   Symmetric Group Defies Strong Fourier Sampling. *SIAM
   Journal on Computing*, 37(6), pp. 1842–1864. — The strong
   Fourier sampling negative result; the central technical
   wall for HSP_{S_n}-based attacks. Underpins W-Q1's
   `ConcreteHSPSn` predicate.
3. **Kuperberg, G.** (2003). A Subexponential-Time Quantum
   Algorithm for the Dihedral Hidden Subgroup Problem.
   *SIAM Journal on Computing*, 35(1), pp. 170–188. — The
   positive result for *dihedral* HSP; underpins the
   isogeny-cryptography parameter inflation. Cited in W-Q4
   §6.4 to motivate the abelian-Shor concern.

### B.2 Cai–Fürer–Immerman graphs

4. **Cai, J., Fürer, M., & Immerman, N.** (1992). An Optimal
   Lower Bound on the Number of Variables for Graph
   Identification. *Combinatorica*, 12(4), pp. 389–410. —
   The CFI gadget construction. Underpins W-Q2.A.
5. **Otto, M.** (1997). *Bounded Variable Logics and
   Counting: A Study in Finite Models*. Lecture Notes in
   Logic 9, Springer. — The k-WL ↔ counting logic
   correspondence. Cited in W-Q2 §4.3 to motivate
   CFI-resistance against bounded-degree algebraic attacks.
6. **Atserias, A. & Maneva, E.** (2013). Sherali–Adams
   Relaxations and Indistinguishability in Counting Logics.
   *SIAM Journal on Computing*, 42(1), pp. 112–137. — The
   Sherali–Adams ↔ WL correspondence. Cited in W-Q2 §4.3.
7. **Berkholz, C. & Grohe, M.** (2017). Linear Diophantine
   Equations, Group CSPs, and Graph Isomorphism. *SODA 2017*,
   ACM/SIAM, pp. 327–339. — The Lasserre hierarchy
   correspondence. Cited in W-Q2 §4.3.

### B.3 Graph Isomorphism complexity

8. **Babai, L.** (2016). Graph Isomorphism in
   Quasipolynomial Time. *Proceedings of the 48th ACM STOC*,
   pp. 684–697. — The 2^{(log n)^O(1)} algorithm. (The
   2^{O(√(n log n))} Luks–Zemlyachenko bound is
   conventionally cited in `docs/HARDNESS_ANALYSIS.md` §3.3
   alongside this.)
9. **Helfgott, H.A.** (2017). Isomorphismes de graphes en
   temps quasi-polynomial (d'après Babai et Luks, Weisfeiler-
   Leman…). *Astérisque* No. 407. — The Helfgott correction
   to Babai 2015. Plan-doc only.

### B.4 Code Equivalence cryptanalysis

10. **Sendrier, N.** (2000). Finding the permutation between
    equivalent linear codes: The Support Splitting Algorithm.
    *IEEE Transactions on Information Theory*, 46(4),
    pp. 1193–1203.
11. **Beullens, W.** (2020). Not Enough LESS: An Improved
    Algorithm for Solving Code Equivalence Problems over F_q.
    *Selected Areas in Cryptography (SAC) 2020*, LNCS 12804,
    pp. 387–403.
12. **Saeed-Taha, M.A.** (2017). *Algebraic Approach for Code
    Equivalence*. PhD Thesis, Royal Holloway, University of
    London.

### B.5 Tensor / ATFE / MinRank cryptanalysis

13. **Grochow, J. & Qiao, Y.** (2021). On the Complexity of
    Isomorphism Problems for Tensors, Groups, and
    Polynomials I: Tensor Isomorphism-Completeness. *SIAM
    Journal on Computing*, 52(2). — The GI ≤ TI reduction;
    underpins W-Q2.B.
14. **Tang, G., Duong, D.H., Joux, A., Plantard, T., Qiao, Y.,
    & Susilo, W.** (2022). Practical Post-Quantum Signature
    Schemes from Isomorphism Problems of Trilinear Forms.
    *EUROCRYPT 2022*, LNCS 13277, pp. 582–612. — The
    MinRank-style ATFE attack; underpins W-Q5's parameter
    discipline.
15. **Verbel, J., Baena, J., Cabarcas, D., Perlner, R., &
    Smith-Tone, D.** (2019). On the complexity of
    "superdetermined" Minrank instances. *PQCrypto 2019*,
    LNCS 11505, pp. 167–186. — The MinRank complexity
    framework cited by W-Q5.
16. **Bardet, M., Bros, M., Cabarcas, D., Gaborit, P.,
    Perlner, R., Smith-Tone, D., Tillich, J.-P., &
    Verbel, J.** (2020). Improvements of algebraic attacks
    for solving the rank decoding and MinRank problems.
    *ASIACRYPT 2020*, LNCS 12491, pp. 507–536.

### B.6 Q2 model and quantum attacks

17. **Kaplan, M., Leurent, G., Leverrier, A., &
    Naya-Plasencia, M.** (2016). Breaking Symmetric
    Cryptosystems using Quantum Period Finding. *CRYPTO 2016*,
    LNCS 9815, pp. 207–237. — The Simon-algorithm attacks on
    GMAC / CBC-MAC / OCB. Underpins W-Q3's Q1-vs-Q2 framing.
18. **Boneh, D. & Zhandry, M.** (2013). Secure Signatures and
    Chosen Ciphertext Security in a Quantum Computing World.
    *CRYPTO 2013*, LNCS 8043, pp. 361–379. — The Q1 / Q2
    framework definition. Cited in W-Q3 §5.3.
19. **Magniez, F., Nayak, A., Roland, J., & Santha, M.**
    (2011). Search via quantum walk. *SIAM Journal on
    Computing*, 40(1), pp. 142–164. — Quantum walks for
    decision problems; cited in W-Q3 §4.3.

### B.7 Group-theoretic background

20. **Holt, D.F., Eick, B., & O'Brien, E.A.** (2005).
    *Handbook of Computational Group Theory*. CRC Press.
    — The GAP `PermutationAutomorphismGroup` algorithmic
    references used in W-Q4.
21. **Babai, L. & Luks, E.M.** (1983). Canonical labeling of
    graphs. *Proceedings of the 15th ACM STOC*, pp. 171–183.
    — The 2^{O(√(n log n))} bound.
22. **Robinson, D.J.S.** (1996). *A Course in the Theory of
    Groups* (2nd ed.). Springer GTM 80. — Commutator
    subgroup, abelianisation; underpins W-Q4's
    `IsStructurallyNonAbelian` predicate.

### B.8 Plan-doc-only references

23. **Castryck, W., Lange, T., Martindale, C., Panny, L.,
    & Renes, J.** (2018). CSIDH: An Efficient Post-Quantum
    Commutative Group Action. *ASIACRYPT 2018*. — Cited in
    the cryptographer's review's §5 ("fundamental tension")
    but not directly addressed by any W-Q\* workstream;
    parking reference for any future W-Q-CommAction-style
    sub-stream.

---

## Appendix C — Non-vacuity Lean snippet templates

This appendix carries the canonical-shape `#print axioms`
snippets that the audit-script extensions in §11.2 must
exhibit. Templates are filled in by each workstream's
landing PR.

### C.1 W-Q1 — HSP-to-OIA reduction

```lean
-- audit_phase_16.lean §15.26

-- 15.26.1 — concrete_hsp_sn_implies_concrete_oia
#print axioms Orbcrypt.concrete_hsp_sn_implies_concrete_oia
-- Expected: [propext, Classical.choice, Quot.sound]

-- 15.26.2 — ε=1 inhabitation
#print axioms Orbcrypt.hsp_to_oia_chain_at_one_exists
-- Expected: [propext, Classical.choice, Quot.sound]

-- 15.26.3 — Non-vacuity witness: a 4-element bundle inhabiting
-- the chain at ε=1. The S₃-on-bitstring-{0,1,2} setting where
-- H₀ = {id, (01)} and H₁ = {id, (12)} have distinct orbits.
example :
    ∃ (B : HSPOIABundle 3 (Fin 8)),
      ConcreteHSPSn B.inst 1 1 ∧
      ConcreteOIA (hspOIABundleToScheme B) 1 := by
  -- concrete construction omitted; see HSPToOIA.lean for the
  -- inhabitation lemma.
  exact hsp_to_oia_chain_at_one_exists
```

### C.2 W-Q2 — CFI + GQ-OIA chain

```lean
-- audit_phase_16.lean §15.27

-- 15.27.1 — CFI conditional reduction
#print axioms Orbcrypt.cfi_hardness_implies_concreteGIOIA_eps_lt_one

-- 15.27.2 — CFI ε=1 inhabitation
#print axioms Orbcrypt.cfi_chain_at_one_exists

-- 15.27.3 — GQ orbit-equivariance lemma
#print axioms Orbcrypt.grochowQiaoOrbitEncoding_equivariant

-- 15.27.4 — GQ giOIA-to-tensorOIA reduction
#print axioms Orbcrypt.grochowQiao_giOIA_implies_concreteTensorOIA

-- 15.27.5 — chained CFI/GQ witness
#print axioms Orbcrypt.concrete_hardness_chain_at_cfi_grochowQiao

-- 15.27.6 — symbolic ε<1 existence
#print axioms Orbcrypt.exists_concreteHardnessChain_with_eps_lt_one
```

### C.3 W-Q3 — Q2 stub framework

```lean
-- audit_phase_16.lean §15.28

-- 15.28.1 — Q2 ⇒ Q1 implication
#print axioms Orbcrypt.q2_secure_implies_q1_secure

-- 15.28.2 — HGOE Q2-conditional reduction
#print axioms Orbcrypt.hgoe_q2_secure_conditional_on_coset_state_resistance
```

### C.4 W-Q4 — Structural fence

```lean
-- audit_phase_16.lean §15.29

-- 15.29.1 — IsStructurallyNonAbelian implies not abelian
#print axioms
  Orbcrypt.isStructurallyNonAbelian_of_pos_threshold_implies_not_abelian

-- 15.29.2 — necessity theorem
#print axioms Orbcrypt.abelian_PAut_implies_oia_break_under_shorAbelianHidden

-- 15.29.3 — contrapositive
#print axioms Orbcrypt.concreteOIA_lt_one_implies_PAut_not_abelian

-- 15.29.4 — W-Q1 cross-cutting bridge
#print axioms Orbcrypt.structurally_non_abelian_yields_orbit_distinct_pairs

-- 15.29.5 — concrete L1 witness for HGOEKeyExpansion structurally_non_abelian
example : IsStructurallyNonAbelian (hgoeL1Keygen.secretGroup) (1 / 4 : ℚ) :=
  hgoeL1Keygen.structurally_non_abelian
```

### C.5 W-Q5 — TensorOIA parameter fence

```lean
-- audit_phase_16.lean §15.30

-- 15.30.1 — concreteTensorOIA_one_no_review_needed
#print axioms Orbcrypt.concreteTensorOIA_one_no_review_needed

-- 15.30.2 — ConcreteTensorOIAWithReview.toHardness sanity
#print axioms Orbcrypt.ConcreteTensorOIAWithReview.toHardness
```

### C.6 Canonical declaration-name patterns

Per the naming rule (`CLAUDE.md` § Naming conventions), the
plan introduces the following content-named identifiers. None
of these names embed plan IDs, workstream tags, or finding
IDs.

| Workstream | Lean identifier | Type | Content |
|------------|-----------------|------|---------|
| W-Q1 | `HSPDecisionalInstance` | `structure` | HSP_{S_n} decisional instance shape |
| W-Q1 | `HSPDistinguisher` | `structure` | HSP-side distinguisher type |
| W-Q1 | `hspDecisionalAdvantage` | `def` | HSP distinguishing advantage |
| W-Q1 | `ConcreteHSPSn` | `def` | concrete HSP_{S_n} hardness predicate |
| W-Q1 | `concreteHSPSn_one`, `concreteHSPSn_mono` | `theorem` | sanity lemmas |
| W-Q1 | `HSPOIABundle` | `structure` | OIA-encoding bundle |
| W-Q1 | `hspOIABundleToScheme` | `def` | encoder |
| W-Q1 | `oia_distinguisher_lifts_to_hsp_distinguisher` | `theorem` | forward reduction |
| W-Q1 | `concrete_hsp_sn_implies_concrete_oia` | `theorem` | contrapositive (headline) |
| W-Q1 | `hsp_to_oia_chain_at_one_exists` | `theorem` | ε=1 inhabitation |
| W-Q1 | `indQCPA_bound_from_hsp_sn_hardness` | `theorem` | multi-query corollary |
| W-Q2 | `CFIFibre`, `CFIVertex` | `def` | CFI fibre / vertex types |
| W-Q2 | `cfiGraph` | `def` | CFI graph construction |
| W-Q2 | `cfiFibre_card`, `cfiGraph_vertex_count_three_regular` | `theorem` | cardinality lemmas |
| W-Q2 | `cycleSpace` | `def` | cycle-space subspace |
| W-Q2 | `cfi_iso_iff_twist_diff_in_cycle_space` | `theorem` | CFI main theorem |
| W-Q2 | `CFISeparatedTwistPair` | `structure` | non-iso twist pair |
| W-Q2 | `CFIHardness` | `def` | CFI hardness predicate |
| W-Q2 | `cfiGraphToBitstring` | `def` | adjacency-matrix encoder |
| W-Q2 | `cfiScheme` | `def` | CFI OIA scheme |
| W-Q2 | `cfi_hardness_implies_concreteGIOIA_eps_lt_one` | `theorem` | CFI conditional ε<1 reduction |
| W-Q2 | `cfi_chain_at_one_exists` | `theorem` | CFI ε=1 inhabitation |
| W-Q2 | `grochowQiaoOrbitEncoding` | `def` | GQ OIA encoder |
| W-Q2 | `grochowQiaoOrbitEncoding_equivariant` | `theorem` | orbit equivariance |
| W-Q2 | `grochowQiao_giOIA_implies_concreteTensorOIA` | `theorem` | GI-to-TI OIA reduction |
| W-Q2 | `concrete_hardness_chain_at_cfi_grochowQiao` | `theorem` | chained ε-bound |
| W-Q2 | `ind1cpa_advantage_bound_via_cfi` | `theorem` | quantitative IND-1-CPA bound via CFI |
| W-Q2 | `exists_concreteHardnessChain_with_eps_lt_one` | `theorem` | symbolic ε<1 existence |
| W-Q3 | `Q2Adversary` | `structure` | Q2 adversary stub |
| W-Q3 | `IsQ2Secure` | `def` | Q2 security predicate |
| W-Q3 | `classicalToQ2Adversary` | `def` | Q1 → Q2 embedding |
| W-Q3 | `q2_secure_implies_q1_secure` | `theorem` | Q2 ⇒ Q1 |
| W-Q3 | `CosetStateFourierResistance` | `def` | research-scope predicate |
| W-Q3 | `hgoe_q2_secure_conditional_on_coset_state_resistance` | `theorem` | conditional Q2 security |
| W-Q4 | `IsStructurallyNonAbelian` | `def` | structural non-abelian predicate |
| W-Q4 | `isStructurallyNonAbelian_of_pos_threshold_implies_not_abelian` | `theorem` | non-abelianness consequence |
| W-Q4 | `ShorAbelianHiddenAttack` | `def` | research-scope predicate |
| W-Q4 | `abelian_PAut_implies_oia_break_under_shorAbelianHidden` | `theorem` | necessity theorem |
| W-Q4 | `concreteOIA_lt_one_implies_PAut_not_abelian` | `theorem` | contrapositive |
| W-Q4 | `structurally_non_abelian_yields_orbit_distinct_pairs` | `theorem` | W-Q1 cross-cutting bridge |
| W-Q5 | `TensorOIAParameterReview` | `structure` | review-metadata carrier |
| W-Q5 | `ConcreteTensorOIAWithReview` | `structure` | hardness + review pair |
| W-Q5 | `ConcreteTensorOIAWithReview.toHardness` | `def` | forgetful map |
| W-Q5 | `concreteTensorOIA_one_no_review_needed` | `theorem` | ε=1 review-free baseline |

All identifiers are noun-or-verb-phrase descriptions of
their content. None embed `W`, `Q1` / `Q2` / …, `QH`, `R-Q3`,
`audit`, or any temporal marker.

---

**End of plan.**

