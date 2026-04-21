# Audit 2026-04-21 — Workstream Plan

**Source audit.** `docs/audits/LEAN_MODULE_AUDIT_2026-04-21.md` (22
findings: 1 HIGH, 8 MEDIUM, 8 LOW, 5 INFO; zero CRITICAL).

**Scope.** Pre-release remediation plan for the Orbcrypt Lean 4
formalization. Organises the 22 findings into eight letter-coded
workstreams (**G** through **N**, skipping **I** to avoid ambiguity
with the `I#` info-finding identifiers). Each workstream is further
decomposed into atomic work units with acceptance criteria, test
obligations, and regression safeguards.

**Branch.** `claude/audit-workstream-planning-uXM1Q` (this document only);
per-workstream implementation branches are listed in § 10.

**Author.** Claude (Opus 4.7 [1M]). **Date.** 2026-04-21.

**Conventions.** Work-unit names in this document use process markers
(`G1`, `H3a`, etc.) — these are document identifiers only. Per
`CLAUDE.md`'s naming discipline, Lean declarations added during
implementation must **not** carry workstream or work-unit tokens in
their identifiers; process references belong in docstrings and commit
messages, never in `def`/`theorem`/`structure` names.

**Reading guide — notation overload.** This document uses **letter
codes** `G`, `H`, `J`, `K`, `L`, `M`, `N` as *workstream* identifiers,
and *also* uses `H1–H3`, `M1–M6`, `L1–L8`, `I1–I5` as *finding*
identifiers carried over from the source audit. The two namespaces
overlap on letters `H`, `M`, and `L`. To disambiguate:

- **Workstream letters** appear bold-faced (**G**, **H**, **J** …) and
  usually near the words "Workstream", "WS", or "§ 3".
- **Finding IDs** appear as `H1`, `M2`, `L3`, `I1` (no workstream
  prefix) and always with grade context ("H1, HIGH", "M2, MEDIUM",
  etc.).
- Work-unit identifiers inside a workstream concatenate letter and
  number: `G1`, `G2`, `H3`, `L1-WU1`, `L2-WU2`, etc. Where a
  collision with a finding-ID would be ambiguous, the work-unit is
  cross-referenced by its section number (e.g., "§ 8.3" rather than
  "M3"), which is the unambiguous form used in the Appendix-A
  cross-reference.

When in doubt, the Appendix-A table (§ 14) is the canonical mapping
from finding-ID to workstream-and-section.

## 0. Executive summary

The 2026-04-21 audit found **no critical, logical, or kernel-level
defects**. The zero-`sorry` / zero-custom-axiom / standard-Lean-trio
posture is preserved across all 38 modules (8,547 source lines). The
findings are **semantic refinements, naming corrections, and
documentation drift** — every one is a pre-release polish item rather
than a correctness rollback.

The most consequential finding is **H1**: the Workstream-E probabilistic
hardness chain (`ConcreteHardnessChain`), which is publicly advertised
as delivering `ε`-smooth IND-1-CPA bounds from TI-hardness, *formally
collapses to `ε = 1`* because its `UniversalConcreteTensorOIA`
hypothesis implicitly quantifies over every `G_TI : Type` — including
the trivial `PUnit` action whose orbit distribution is a point mass
admitting advantage-1 distinguishers. A small structural refactor
(Workstream **G**) binds `G_TI` as a chain-level parameter, making the
chain honestly ε-parametric for the intended `GL³` (or any concrete)
surrogate.

The remaining HIGH-adjacent findings are medium severity: **H2**
(KEM-layer chain through `ConcreteKEMOIA_uniform` is missing),
**H3** (the deterministic OIA family is self-disclosed-vacuous on any
non-trivial scheme — documentation framing only). Medium findings
**M1–M6** are each small-diff: collision-admitting `IsSecure`, dead
`SeedKey.expand`, unconstrained `carterWegmanMAC p`, misleadingly-named
tautology theorems (`RefreshIndependent`, `SymmetricKeyAgreement-
Limitation`), and a redundant `KEMOIA` conjunct. Low and info findings
are polish.

**Release-readiness commitment.** After Workstreams **G** (pre-release
critical) and **K** (distinct-challenge corollaries) land, the release
narrative "Orbcrypt is machine-checked IND-1-CPA secure under TI-
hardness, with concrete ε-bounds" becomes quantitatively honest. The
remaining workstreams (**H**, **J**, **L**, **M**, **N**) are
pre-release-preferred polish but not blockers.

## 1. Finding → workstream mapping

| Finding | Grade | Workstream | Module(s) touched | Pre-release? |
|---------|-------|------------|-------------------|--------------|
| H1 | HIGH | **G** | `Hardness/Reductions.lean`, `Hardness/TensorAction.lean` | **yes** |
| H2 | MEDIUM | **H** | `KEM/CompSecurity.lean` | preferred |
| H3 | MEDIUM | **J** | docs only (`CLAUDE.md`, `VERIFICATION_REPORT.md`, `Orbcrypt.lean`) | **yes** |
| M1 | MEDIUM | **K** | `Theorems/OIAImpliesCPA.lean`, `KEM/Security.lean`, `Hardness/Reductions.lean` | **yes** |
| M2 | MEDIUM | **L1** | `KeyMgmt/SeedKey.lean` | preferred |
| M3 | MEDIUM | **L2** | `AEAD/CarterWegmanMAC.lean` | preferred |
| M4 | MEDIUM | **L3** | `PublicKey/ObliviousSampling.lean` | preferred |
| M5 | MEDIUM | **L4** | `PublicKey/KEMAgreement.lean` | preferred |
| M6 | MEDIUM | **L5** | `KEM/Security.lean`, `KEM/CompSecurity.lean` | preferred |
| L1 | LOW | **M** § 8.1 | `Hardness/Reductions.lean` | optional |
| L2 | LOW | **M** § 8.2 | `Probability/Advantage.lean` | optional |
| L3 | LOW | **M** § 8.3 | `Hardness/Reductions.lean` | optional |
| L4 | LOW | **M** § 8.4 | (tracked to future Workstreams F3/F4 — no action) | n/a |
| L5 | LOW | **M** § 8.5 | `Theorems/InvariantAttack.lean` | optional |
| L6 | LOW | **M** § 8.6 | `Construction/HGOE.lean` | optional |
| L7 | LOW | **M** § 8.7 | `Probability/Negligible.lean` | optional |
| L8 | LOW | **M** § 8.8 | `PublicKey/CombineImpossibility.lean` | optional |
| I1 | INFO | **N** § 9.1 | `lakefile.lean`, `CLAUDE.md` | optional |
| I2 | INFO | **N** § 9.2 | (self-disclosed — docstring only) | n/a |
| I3 | INFO | **N** § 9.3 | (tracked to Workstream E8b — no action) | n/a |
| I4 | INFO | **N** § 9.4 | (self-disclosed — no action) | n/a |
| I5 | INFO | **N** § 9.5 | `.github/workflows/lean4-build.yml` (comment only) | optional |

**Total pre-release work:** Workstream G (critical) + J (docs) + K
(distinct-challenge corollaries) = the minimal honest-release slate.
**Total preferred pre-release:** add H + L. **Total with polish:** add M + N.

## 2. Workstream summary

| Workstream | Scope | Findings | Est. effort | Dep. |
|------------|-------|----------|-------------|------|
| **G** | Hardness-chain non-vacuity: structure-carried `G_TI` | H1 | 8h | none |
| **H** | KEM-layer ε-smooth chain via `ConcreteKEMOIA_uniform` | H2 | 4h | **G** |
| **J** | Release-messaging alignment: deterministic-vacuity framing | H3 | 1.5h | **G**, **K** |
| **K** | Distinct-challenge IND-1-CPA corollaries | M1 | 2h | none |
| **L** | Structural + naming hygiene (five sub-items) | M2–M6 | 5h | none |
| **M** | Low-priority polish (eight sub-items) | L1–L8 | 3h | none |
| **N** | Info hygiene (lakefile version, CI comment) | I1, I5 | 0.5h | none |
| — | Total | 22 findings | ≈ 24h | — |

Effort estimates exclude review and merge time. Parallelism: **G** is
the critical-path precondition for **H** and **J**; **K**, **L**,
**M**, **N** run independently. A single dedicated implementer can
land the pre-release slate (**G** + **J** + **K**) in one working day.

## 3. Workstream G — hardness-chain non-vacuity (H1, HIGH)

### 3.1 Problem statement

The audit-revised (post-2026-04-20) form of
`UniversalConcreteTensorOIA εT` in `Orbcrypt/Hardness/Reductions.lean`
lines 316–322 reads:

```lean
def UniversalConcreteTensorOIA [Fintype F] [DecidableEq F] (εT : ℝ) : Prop :=
  ∀ {n : ℕ} {G_TI : Type}
    [Group G_TI] [Fintype G_TI] [Nonempty G_TI]
    [MulAction G_TI (Tensor3 n F)]
    (T₀ T₁ : Tensor3 n F),
    ConcreteTensorOIA (G_TI := G_TI) T₀ T₁ εT
```

`{G_TI : Type}` is an **implicit universal** quantifier: any proof must
work for every finite-nonempty group with any `MulAction` on
`Tensor3 n F`. The `Group`, `Fintype`, and `Nonempty` instances are
satisfied by `PUnit`; a trivial `MulAction PUnit α` is readily
constructible for any `α` (`{ smul := fun _ x => x }` is a two-line
definition whose `one_smul` and `mul_smul` obligations both close by
`rfl`). Whether or not Mathlib ships such an instance as a global, a
caller wishing to refute
`UniversalConcreteTensorOIA εT` with `εT < 1` can supply one locally
at the refutation site — the Prop universally quantifies over every
instance reachable by normal typeclass search *plus* any the caller
elaborates. Under `G_TI := PUnit` the orbit distribution is
`PMF.map (fun _ => unit • T) (uniformPMF PUnit) = PMF.pure T`, so
`advantage D (PMF.pure T₀) (PMF.pure T₁) ∈ {0, 1}`. For any
`|F| ≥ 2` and `n ≥ 1`, `T₀ ≠ T₁` together with
`D := decide (· = T₀)` yields advantage `1`. Hence
`UniversalConcreteTensorOIA εT` for `εT < 1` is **provably false**.

**Downstream collapse.** The three Workstream-E reduction Props
(`ConcreteTensorOIAImpliesConcreteCEOIA`,
`ConcreteCEOIAImpliesConcreteGIOIA`,
`ConcreteGIOIAImpliesConcreteOIA`) each take `Universal*OIA` as
antecedent; at `ε < 1` the antecedent is false, so the Prop is
vacuously true. `ConcreteHardnessChain.concreteOIA_from_chain` (the
headline Workstream-E theorem) therefore non-vacuously delivers only
`ConcreteOIA scheme 1` — which is already true unconditionally via
`concreteOIA_one_meaningful`. **The chain provides no quantitative
security bound.**

### 3.2 Fix selection rationale

The audit proposes three fix options (A: existential `G_TI` inside the
universal form; B: structure-carried `G_TI`; C: per-encoding via
`OrbitPreservingEncoding`). This plan adopts **Fix B** as the
pre-release remediation. Rationale:

- **Fix A** (existential over `G_TI`) is semantically equivalent to
  Fix B but requires nested existentials over typeclass instances,
  which Lean 4 elaboration handles poorly. Under-the-hood, Lean
  encodes such existentials via `PSigma`/`Nonempty` bundles — i.e.,
  exactly the structure Fix B uses explicitly. Fix B is therefore the
  Lean-native form of Fix A.
- **Fix C** (route through `OrbitPreservingEncoding`) is the
  cryptographically cleanest long-term formulation but is a larger
  refactor. `Orbcrypt/Hardness/Encoding.lean` already exposes the
  interface; Fix C is deferred to Workstream F3/F4 (concrete Karp
  encodings via CFI / Grochow–Qiao) so that the encoding interface and
  its consumers land together.
- **Fix B** is surgical: one structure-field addition in
  `ConcreteHardnessChain`, symmetric adjustments to the four
  reduction Props, and one-line updates to
  `ConcreteHardnessChain.tight`, `tight_one_exists`,
  `concrete_chain_zero_compose`, and
  `concrete_hardness_chain_implies_1cpa_advantage_bound`. No downstream
  consumers beyond the audit scripts and the root transparency report.

### 3.3 Target API shape (post-fix)

```lean
-- `SurrogateTensor F` bundles the cryptographically meaningful tensor-
-- action surrogate. It is the chain-level parameter that commits
-- to a specific group (e.g., GL³(F) when Fintype instances land, or
-- a finite subgroup witness for the pre-release).
structure SurrogateTensor (F : Type*) where
  carrier : Type
  [groupInst : Group carrier]
  [fintypeInst : Fintype carrier]
  [nonemptyInst : Nonempty carrier]
  action : ∀ n : ℕ, MulAction carrier (Tensor3 n F)

-- Universal-over-tensor-pairs hardness, parameterised by a specific
-- surrogate. PUnit is a legal surrogate only if the caller explicitly
-- supplies it; then the chain's ε bound reflects the (trivial) hardness
-- of that surrogate, which is the correct cryptographic reading.
def UniversalConcreteTensorOIA
    {F : Type*} [Fintype F] [DecidableEq F]
    (S : SurrogateTensor F) (εT : ℝ) : Prop :=
  ∀ {n : ℕ} (T₀ T₁ : Tensor3 n F),
    ConcreteTensorOIA (G_TI := S.carrier) T₀ T₁ εT

-- Corresponding reduction Prop: TI-hardness for this surrogate
-- transfers to CE-hardness.
def ConcreteTensorOIAImpliesConcreteCEOIA
    {F : Type*} [Fintype F] [DecidableEq F]
    (S : SurrogateTensor F) (εT εC : ℝ) : Prop :=
  UniversalConcreteTensorOIA S εT → UniversalConcreteCEOIA (F := F) εC

-- ConcreteHardnessChain now binds the surrogate in its signature.
structure ConcreteHardnessChain
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (F : Type*) [Fintype F] [DecidableEq F]
    (S : SurrogateTensor F)    -- ← new field
    (ε : ℝ) where
  εT : ℝ
  εC : ℝ
  εG : ℝ
  tensor_hard : UniversalConcreteTensorOIA S εT
  tensor_to_ce : ConcreteTensorOIAImpliesConcreteCEOIA S εT εC
  ce_to_gi : ConcreteCEOIAImpliesConcreteGIOIA (F := F) εC εG
  gi_to_oia : ConcreteGIOIAImpliesConcreteOIA scheme εG ε
```

Note that `ce_to_gi` and `gi_to_oia` are **unchanged** by this fix —
the `PUnit` collapse only affects the tensor-layer quantifier.
`UniversalConcreteCEOIA` and `UniversalConcreteGIOIA` quantify over
*instance types* (codes / adjacency matrices) that are non-empty
value types rather than arbitrary-MulAction groups, so their
universal forms remain honest.

### 3.4 Work units

Each work unit is atomic (one to three commits) and has a concrete
acceptance test. Ordering is sequential unless noted.

#### G1 — Introduce `SurrogateTensor F` structure

**File.** `Orbcrypt/Hardness/TensorAction.lean` (append after the
`ConcreteTensor` section, before `end Orbcrypt`).

**Change.** Add the `SurrogateTensor` structure as shown in § 3.3.
The field types and instance bindings must match the existing
`ConcreteTensorOIA` signature so that `ConcreteTensorOIA (G_TI :=
S.carrier) T₀ T₁ εT` elaborates without additional instance threading.

**Rationale for landing in `TensorAction.lean`.** The structure is
about tensor-action surrogates; `Reductions.lean` consumes it but does
not define it. Keeping the structure next to `ConcreteTensorOIA` puts
the surrogate bundle next to the predicate it bundles hardness for.

**Acceptance.**
- `lake build Orbcrypt.Hardness.TensorAction` succeeds.
- `#check @SurrogateTensor` shows the expected signature.
- A trivial witness `SurrogateTensor.ofPUnit : SurrogateTensor F` is
  *not* defined in this WU — we want callers to be explicit about
  choosing PUnit if they ever do, so the surrogate choice is visible
  at the call site.

**Regression safeguard.** Existing `ConcreteTensorOIA` API is
unchanged; all current `tensorOrbitDist` / `concreteTensorOIA_one` /
`concreteTensorOIA_mono` theorems still compile without edits.

#### G2 — Refactor `UniversalConcreteTensorOIA` to take `SurrogateTensor`

**File.** `Orbcrypt/Hardness/Reductions.lean`, lines 309–362 (the
`ConcreteReductions` section).

**Change.**
1. Retire the `{G_TI : Type}` implicit-universal form.
2. Add the new surrogate-parameterised form as defined in § 3.3.
3. Update `UniversalConcreteCEOIA` and `UniversalConcreteGIOIA` —
   these do *not* need surrogate parameters (their universes are
   already over concrete value types), but their definitions use an
   implicit `{m}` / `{k}` that should stay implicit.
4. Update `ConcreteTensorOIAImpliesConcreteCEOIA` to accept the
   surrogate parameter and flow through the corresponding
   `UniversalConcreteTensorOIA` shape.

**Acceptance.**
- `lake build Orbcrypt.Hardness.Reductions` succeeds.
- `#check @UniversalConcreteTensorOIA` confirms the surrogate is a
  named argument, not an implicit typeclass.
- The old signature is *deleted* (not deprecated) — per `CLAUDE.md`
  conventions, backwards-compatibility shims for internal APIs are
  not introduced.

**Regression safeguard.** `concreteTensorOIAImpliesConcreteCEOIA_one_one`
and `concrete_chain_zero_compose` must still type-check after the
refactor; the surrogate parameter propagates through but the proofs
are unchanged modulo explicit surrogate threading.

#### G3 — Refactor `ConcreteHardnessChain` structure

**File.** `Orbcrypt/Hardness/Reductions.lean`, lines 473–494 (the
`ConcreteHardnessChainSection`).

**Change.**
1. Add `(S : SurrogateTensor F)` as a structure parameter (not field
   — the surrogate binds the whole structure's typing).
2. Retype `tensor_hard` to `UniversalConcreteTensorOIA S εT`.
3. Retype `tensor_to_ce` to `ConcreteTensorOIAImpliesConcreteCEOIA S εT εC`.

**Acceptance.**
- `lake build Orbcrypt.Hardness.Reductions` succeeds.
- `#check @ConcreteHardnessChain` confirms the surrogate in the
  structure signature before `(ε : ℝ)`.

**Regression safeguard.** `ConcreteHardnessChain.concreteOIA_from_chain`
and `.tight` still compose: each field projection types the same way,
only the instance binding changes from implicit universe-0 to
explicit structure-carried.

#### G4 — Update chain-composition lemmas

**File.** `Orbcrypt/Hardness/Reductions.lean`, lines 496–591.

**Change.**
1. `concreteOIA_from_chain` — body unchanged, signature now implicit
   in `S`. The proof is still `hc.gi_to_oia (hc.ce_to_gi
   (hc.tensor_to_ce hc.tensor_hard))` — each link consumes the
   previous layer's hardness meaningfully, and the surrogate is
   threaded via structure projection.
2. `ConcreteHardnessChain.tight` — signature gains `(S :
   SurrogateTensor F)`; body unchanged.
3. `tight_one_exists` — existence witness must now construct a
   concrete `SurrogateTensor F`. **Decision:** the witness uses
   `PUnit` explicitly to avoid requiring a `Fintype (GL (Fin n) F)`
   instance (which Mathlib lacks). This is exactly the audit's
   "trivial surrogate" case: at `ε = 1` it witnesses that the chain
   is inhabited for the trivial surrogate, which is the honest
   cryptographic reading.
4. `concrete_chain_zero_compose` — signature gains `(S :
   SurrogateTensor F)` (or kept as caller-supplied).
5. `concrete_hardness_chain_implies_1cpa_advantage_bound` — signature
   gains `(S : SurrogateTensor F)` implicit through `hc` (it's a
   structure parameter, not an extra argument).

**Acceptance.**
- `lake build Orbcrypt.Hardness.Reductions` succeeds.
- `#print axioms concrete_hardness_chain_implies_1cpa_advantage_bound`
  emits only `[propext, Classical.choice, Quot.sound]`.
- `tight_one_exists` returns `Nonempty (ConcreteHardnessChain scheme F
  punitSurrogate 1)` where `punitSurrogate : SurrogateTensor F` is
  the explicit PUnit witness constructed in the proof.

**Regression safeguard.** Every existing consumer of the chain API —
which as of this audit is limited to `scripts/audit_phase_16.lean`
and `scripts/audit_e_workstream.lean` — is updated in WU **G5**.

#### G5 — Update audit scripts

**Files.** `scripts/audit_phase_16.lean`, `scripts/audit_e_workstream.lean`.

**Change.**
1. Any `#print axioms ConcreteHardnessChain.*` — no change to output
   (surrogate parameter does not affect axiom dependencies).
2. Concrete `example` bindings in `audit_e_workstream.lean` must
   supply a surrogate. Add a shared `private def punitSurrogate :
   SurrogateTensor (ZMod 2) := { carrier := PUnit, action := fun _ =>
   inferInstance }` (or similar — defined once at the top of the
   pressure-test section).
3. New `example` (Workstream G satisfiability test): construct a
   `ConcreteHardnessChain toyScheme (ZMod 2) punitSurrogate 1` and
   extract `ConcreteOIA toyScheme 1` via `concreteOIA_from_chain`.

**Acceptance.**
- `lake env lean scripts/audit_phase_16.lean` produces no `sorryAx`,
  no non-standard-trio axioms, and all referenced declarations are
  found (the name set is unchanged).
- `lake env lean scripts/audit_e_workstream.lean` produces all
  expected examples and no errors.

#### G6 — Update root transparency report & CLAUDE.md

**Files.** `Orbcrypt.lean` (axiom-transparency report section),
`CLAUDE.md` (headline-theorem table), `docs/VERIFICATION_REPORT.md`.

**Change.**
1. In `Orbcrypt.lean`, replace the "Workstream E4 — `Concrete-
   HardnessChain`" entry to note: "Chain now carries a
   `SurrogateTensor F` parameter (audit F-AUDIT-2026-04-21-H1,
   Workstream G). Non-vacuous for any surrogate whose tensor-
   isomorphism advantage is bounded by `εT < 1`; vacuous (i.e.,
   `ε = 1`) for the PUnit surrogate."
2. In `CLAUDE.md`'s headline theorem table, update the row for the
   hardness chain (there is currently an entry under Phase 12
   outputs) to reflect the surrogate parameter.
3. In `docs/VERIFICATION_REPORT.md`, the "Known limitations" section
   already discusses the chain's ε-vacuity; replace that text with
   the post-G status: "At `ε < 1` the chain is non-vacuous if and
   only if the caller supplies a surrogate whose TI-hardness is
   genuinely εT-bounded. The PUnit surrogate remains a satisfiability
   witness at ε = 1."

**Acceptance.**
- No CI red on docstring checks.
- `scripts/audit_phase_16.lean` still passes.

### 3.5 Risks and mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `SurrogateTensor` instance-bundling syntax clashes with existing typeclass search | Medium | Field-based (not typeclass-based) — `[Group S.carrier]` is extracted via `attribute [local instance] S.groupInst` inside the def block that needs it. |
| `ConcreteTensorOIA (G_TI := S.carrier)` fails to elaborate because of instance ordering | Low | Use explicit `@`-threading if necessary; add a `variable` block with `letI` bindings inside the def body. |
| Refactor breaks `audit_e_workstream.lean`'s existing satisfiability tests | Medium | WU **G5** updates the audit script in the same commit as WU **G4**; CI runs both. |
| Post-fix, `tight_one_exists` is harder to produce because it needs an explicit surrogate | Low | The PUnit surrogate is 4 lines; included in the WU **G4** proof body. |

### 3.6 Exit criteria for Workstream G

All of the following must hold after WUs G1–G6 land:

1. `lake build` for all 38 modules succeeds with exit code 0.
2. `grep -rn "sorry" Orbcrypt/ --include="*.lean"` returns empty (via
   the comment-aware CI scan).
3. `grep -rn "^axiom " Orbcrypt/ --include="*.lean"` returns empty.
4. `scripts/audit_phase_16.lean` passes: zero `sorryAx`, zero non-
   standard axioms.
5. `scripts/audit_e_workstream.lean` passes with the new surrogate
   example.
6. `Orbcrypt.lean`'s transparency report is updated.
7. A new section in `docs/VERIFICATION_REPORT.md` documents the
   post-G status.
8. `ConcreteHardnessChain ... punitSurrogate ε` is inhabited only at
   `ε = 1`; for any caller-supplied surrogate `S`, the chain's ε
   bound reflects `S`'s actual TI-hardness — the ε-smoothness is
   restored up to the surrogate-dependent bound.

## 4. Workstream H — KEM-layer ε-smooth chain (H2, MEDIUM)

### 4.1 Problem statement

`Orbcrypt/KEM/CompSecurity.lean` defines two probabilistic KEM-OIA
predicates:

- `ConcreteKEMOIA kem ε` — **point-mass form.** Bounds
  `advantage D (PMF.pure (encaps kem g₀)) (PMF.pure (encaps kem g₁))`.
  Because point-mass advantage is always `0` or `1`, this Prop
  collapses on `ε ∈ [0, 1)`: any non-zero advantage is exactly `1`.
- `ConcreteKEMOIA_uniform kem ε` — **uniform form.** Bounds
  `advantage D (kemEncapsDist kem) (PMF.pure (encaps kem g_ref))`.
  This advantage can take any value in `[0, 1]` as `g_ref` and `D`
  vary, so intermediate `ε` are non-vacuous.

The deterministic-to-probabilistic bridge
(`det_kemoia_implies_concreteKEMOIA_zero`) and the security reduction
(`concrete_kemoia_implies_secure`) only thread through the point-mass
form. **No `ConcreteHardnessChain` analogue composes through
`ConcreteKEMOIA_uniform`.** Consequently, downstream KEM consumers
have no honest ε-smooth security chain — they must either accept the
point-mass collapse or assemble the chain by hand.

### 4.2 Fix scope

A parallel KEM-layer chain structure `ConcreteKEMHardnessChain` that
composes `UniversalConcreteGIOIA εG → ConcreteOIA scheme ε →
ConcreteKEMOIA_uniform kem ε` via a final scheme-to-KEM step. The
scheme-to-KEM step requires a new Prop asserting that ε-smooth
scheme-level orbit indistinguishability transfers to ε-smooth KEM-
level encapsulation indistinguishability; this is the standard
reduction "scheme IND-1-CPA implies KEM IND-CPA (single query)" but
expressed probabilistically.

Throughout this section, the structure is named
`ConcreteKEMHardnessChain` (CamelCase with the KEM qualifier
adjectival). No `ConcreteHardnessChain_KEM`-style underscore variants
are introduced, to keep the identifier style consistent with the
existing `ConcreteHardnessChain`.

### 4.3 Work units

#### H1 — State `ConcreteOIAImpliesConcreteKEMOIAUniform` reduction Prop

**File.** `Orbcrypt/KEM/CompSecurity.lean`, new section after the
existing `ConcreteKEMOIA_uniform` block.

**Change.** Add the reduction Prop:

```lean
/-- **Workstream H1.** Probabilistic scheme-to-KEM reduction Prop.

    A `ConcreteOIA scheme ε` bound on an `OrbitEncScheme`'s advantage
    transfers to a `ConcreteKEMOIA_uniform kem ε'` bound on a KEM
    derived from the scheme (via `OrbitEncScheme.toKEM`), with
    potentially relaxed ε'. The transfer is not free: the KEM's
    `keyDerive` function must not introduce additional statistical
    distance, which is a deterministic-algebra obligation on
    `keyDerive`.

    Stated as a `Prop`-valued definition; the concrete discharge
    (for any `keyDerive` that is a deterministic function of its
    canonical-form input, which all production KEMs are) is a
    downstream theorem (see `H2` below). -/
def ConcreteOIAImpliesConcreteKEMOIAUniform
    {G : Type*} {X : Type*} {M : Type*} {K : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (m₀ : M) (keyDerive : X → K)
    (ε ε' : ℝ) : Prop :=
  ConcreteOIA scheme ε →
    ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) ε'
```

**Acceptance.**
- `lake build Orbcrypt.KEM.CompSecurity` succeeds.
- `#check @ConcreteOIAImpliesConcreteKEMOIAUniform` shows the signature.

#### H2 — Discharge the reduction at `ε = ε'`

**File.** `Orbcrypt/KEM/CompSecurity.lean`, continuing the H1 section.

**Change.** Prove that the reduction Prop holds with ε = ε' under a
weak deterministic-keyDerive hypothesis. The proof strategy:
1. Unfold `ConcreteKEMOIA_uniform`, obtain `D : X × K → Bool` and
   `g_ref : G`.
2. Reduce the advantage against `kemEncapsDist` to advantage against
   `orbitDist scheme.canonForm (scheme.reps m₀)` by factoring out the
   deterministic `keyDerive`.
3. Apply `ConcreteOIA scheme ε` with the Boolean distinguisher
   `D'(c) := D (c, keyDerive (canon c))`.

**Acceptance.**
- `#print axioms concreteOIA_to_concreteKEMOIA_uniform` shows only
  `[propext, Classical.choice, Quot.sound]`.

**Risk.** If step 2 requires a non-trivial lemma about PMF pushforward
along deterministic maps, that lemma lands as a helper in
`Probability/Monad.lean` or as a private helper in `KEM/CompSecurity.lean`.

#### H3 — `ConcreteKEMHardnessChain` structure and composition

**File.** `Orbcrypt/KEM/CompSecurity.lean`, new section at the
bottom.

**Change.** Define `ConcreteKEMHardnessChain scheme F S m₀ keyDerive
ε` as a structure whose fields are:
- A `ConcreteHardnessChain scheme F S ε_scheme` (for some
  `ε_scheme ≤ ε`).
- A `ConcreteOIAImpliesConcreteKEMOIAUniform scheme m₀ keyDerive
  ε_scheme ε` witness.

Plus the composition theorem:

```lean
theorem concreteKEMHardnessChain_implies_kemUniform
    ...
    (hc : ConcreteKEMHardnessChain scheme F S m₀ keyDerive ε) :
    ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) ε :=
  hc.scheme_to_kem (ConcreteHardnessChain.concreteOIA_from_chain
    hc.chain)
```

**Acceptance.**
- `lake build Orbcrypt.KEM.CompSecurity` succeeds.
- A satisfiability witness at `ε = 1` exists (composing
  `tight_one_exists` with the trivial ε=1 scheme-to-KEM reduction).

#### H4 — Update root transparency report & documentation

**Files.** `Orbcrypt.lean`, `CLAUDE.md`, `docs/VERIFICATION_REPORT.md`.

**Change.** Add Workstream H1–H3 theorems to the axiom-transparency
report; update the "Vacuity map" table in `Orbcrypt.lean` to add a
row mapping the deterministic `kemoia_implies_secure` to the new
`concreteKEMHardnessChain_implies_kemUniform`.

**Acceptance.** Same as G6's acceptance criteria, restricted to the
new KEM-layer artefacts.

### 4.4 Risks and mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| H2's PMF-pushforward step (factoring `keyDerive` out of the advantage) requires a lemma not in Mathlib | Medium | Add a local helper in `KEM/CompSecurity.lean` (or `Probability/Monad.lean` if general-purpose): `advantage_map_det : advantage (D ∘ f) p₀ p₁ = advantage D (PMF.map f p₀) (PMF.map f p₁)`. Proof is a one-line `PMF.toOuterMeasure` rewrite. |
| `scheme.toKEM m₀ keyDerive` currently lives in `KEM/Syntax.lean`; threading the correct `keyDerive` through the KEM chain requires care about definitional unfolding | Low | Use `simp only [OrbitEncScheme.toKEM]` in the proof body; the definition is transparent. |
| A downstream consumer expects the point-mass `ConcreteKEMOIA` (not the new uniform chain), breaking builds | Low | The point-mass form is preserved; the new `ConcreteKEMHardnessChain` is additive. No existing API is removed. |

### 4.5 Exit criteria for Workstream H

1. Workstream G is merged (H2 has the chain-structure precondition).
2. `lake build` succeeds for all modules.
3. The full Phase-16 audit script (`scripts/audit_phase_16.lean`)
   emits only standard-trio axioms for all new declarations.
4. `concreteKEMHardnessChain_implies_kemUniform` is inhabited at `ε
   = 1` for a trivial (PUnit-surrogate) chain — the KEM-layer
   satisfiability witness.

## 5. Workstream J — release-messaging alignment (H3, MEDIUM)

### 5.1 Problem statement

The deterministic OIA family (`OIA`, `KEMOIA`, `TensorOIA`, `CEOIA`,
`GIOIA`) quantifies over every Boolean function. For any scheme with
distinct orbit representatives, `decide (x = reps m₀)` refutes the
predicate. Hence the deterministic security theorems
(`oia_implies_1cpa`, `kemoia_implies_secure`,
`hardness_chain_implies_security`) are vacuously true (proof-by-ex-
falso on a false premise) on every production instance. This is
**self-disclosed** in `Crypto/OIA.lean:46–67` and in
`docs/VERIFICATION_REPORT.md`'s "Known limitations" section.

The remaining risk is **release messaging**: an external reader may
interpret "Orbcrypt is IND-1-CPA secure under OIA" as a standalone
guarantee, rather than as scaffolding for the probabilistic chain.
Workstream J is **documentation-only** — no Lean changes.

### 5.2 Work units

#### J1 — Add "Deterministic vs probabilistic" release framing in `Orbcrypt.lean`

**File.** `Orbcrypt.lean`, in the module-header comment and the
transparency report.

**Change.** Before the headline theorem table, insert a new subsection:

```text
## Deterministic-vs-probabilistic security chains

Orbcrypt's formalization carries *two* parallel security chains:

1. **Deterministic chain** (Phases 3, 4, 7, 10, 12). Built from
   `Prop`-valued OIA variants (`OIA`, `KEMOIA`, `TensorOIA`, `CEOIA`,
   `GIOIA`). Each quantifies over every Boolean distinguisher,
   including orbit-membership oracles. These predicates are
   **False on every non-trivial scheme** (as documented in
   `Crypto/OIA.lean`); consequently the downstream theorems
   `oia_implies_1cpa`, `kemoia_implies_secure`,
   `hardness_chain_implies_security` are vacuously true on
   production instances. They are **algebraic scaffolding** —
   type-theoretic templates whose existence we verify, not
   standalone security claims.

2. **Probabilistic chain** (Phases 8, Workstream E). Built from
   `ConcreteOIA`, `ConcreteKEMOIA_uniform`,
   `ConcreteHardnessChain`, etc. These are ε-bounded on the PMF-
   valued orbit distributions and admit genuinely ε-smooth values.
   The probabilistic chain is the **substantive security
   content**, subject to a caller-supplied `SurrogateTensor`
   (Workstream G) or explicit GI/CE hardness assumption.

External release claims of the form "Orbcrypt is IND-1-CPA secure
under TI-hardness" should cite the probabilistic chain
(`concrete_hardness_chain_implies_1cpa_advantage_bound`), not the
deterministic one. See `docs/VERIFICATION_REPORT.md` § "Release
readiness" for the exact citations.
```

**Acceptance.** Documentation-only change; `lake build` is a no-op
for this WU (comments do not affect kernel output).

#### J2 — Rewrite "Known limitations" + add "Release readiness" in `docs/VERIFICATION_REPORT.md`

**File.** `docs/VERIFICATION_REPORT.md`.

**Change.**
1. Update the existing "Known limitations" subsection (it already
   discusses OIA/CompOIA vacuity; extend to cover Workstream G's H1
   resolution explicitly).
2. Add a new **"Release readiness"** section at the end of the
   report with three paragraphs:
   - The deterministic chain's vacuity (framed as a *feature* of the
     `Prop`-valued formulation, not a bug).
   - The probabilistic chain's ε-smoothness (modulo Workstream G's
     surrogate binding, which becomes a caller obligation to supply
     a `SurrogateTensor` with quantitatively meaningful εT).
   - Release-facing summary recommendations: what to cite
     (`concrete_hardness_chain_implies_1cpa_advantage_bound`,
     `oia_implies_1cpa_distinct`), what not to cite
     (the deterministic headline theorems, which serve as
     scaffolding only).

**Acceptance.** Manual review; no CI hook.

#### J3 — Tighten `CLAUDE.md`'s headline-theorem table

**File.** `CLAUDE.md`, the "Three core theorems" and downstream
tables.

**Change.** Add a "Status" column that marks theorems as either
**Standalone** (e.g., `correctness`, `invariant_attack`,
`kem_correctness`), **Scaffolding** (deterministic chain pieces
— `oia_implies_1cpa`, `kemoia_implies_secure`,
`hardness_chain_implies_security`), or **Quantitative**
(probabilistic chain —
`concrete_hardness_chain_implies_1cpa_advantage_bound`,
`concrete_oia_implies_1cpa`, `concrete_kemoia_implies_secure`).

**Acceptance.** Manual review.

### 5.3 Exit criteria for Workstream J

1. `Orbcrypt.lean` carries the deterministic-vs-probabilistic framing.
2. `docs/VERIFICATION_REPORT.md` and `CLAUDE.md` are aligned.
3. No Lean source changes — `lake build` and axiom audit are
   unaffected.

## 6. Workstream K — distinct-challenge IND-1-CPA corollaries (M1, MEDIUM)

### 6.1 Problem statement

`Crypto/Security.lean` carries two security predicates:

- `IsSecure scheme` — the "uniform" game, accepting every
  `Adversary`, including ones whose `choose` returns a collision
  `(m, m)`. This predicate is **strictly stronger** than the classical
  IND-1-CPA game.
- `IsSecureDistinct scheme` — the "classical" game, restricted to
  adversaries with `m₀ ≠ m₁`. Audit F-02 (Workstream B1)
  acknowledges the gap.

`isSecure_implies_isSecureDistinct` proves the one-way implication,
but **every downstream security theorem concludes `IsSecure`, not
`IsSecureDistinct`**:

- `Theorems/OIAImpliesCPA.oia_implies_1cpa` — `OIA → IsSecure`.
- `Hardness/Reductions.hardness_chain_implies_security` —
  `HardnessChain → IsSecure`.
- `KEM/Security.kemoia_implies_secure` — `KEMOIA → KEMIsSecure` (the
  KEM analogue of `IsSecure`, not `IsSecureDistinct`).

Consumers reading "IND-1-CPA" through the lens of the literature
expect `IsSecureDistinct`. Workstream K closes the gap with thin
corollaries.

### 6.2 Work units

#### K1 — Add `oia_implies_1cpa_distinct` corollary

**File.** `Orbcrypt/Theorems/OIAImpliesCPA.lean`, appended.

**Change.**
```lean
/-- **Distinct-challenge IND-1-CPA (audit F-AUDIT-2026-04-21-M1).**

    Classical IND-1-CPA formulation of `oia_implies_1cpa`: the OIA
    hypothesis implies `IsSecureDistinct`. Derived by composing the
    strong `oia_implies_1cpa` with `isSecure_implies_isSecureDistinct`.

    This is the release-facing form — downstream documentation and
    external summaries should cite this theorem rather than
    `oia_implies_1cpa`, because it matches the literature's
    IND-1-CPA game (challenger rejects `(m, m)` before sampling). -/
theorem oia_implies_1cpa_distinct ... (hOIA : OIA scheme) :
    IsSecureDistinct scheme :=
  isSecure_implies_isSecureDistinct scheme (oia_implies_1cpa scheme hOIA)
```

**Acceptance.**
- `lake build Orbcrypt.Theorems.OIAImpliesCPA` succeeds.
- `#print axioms oia_implies_1cpa_distinct` shows only standard trio.

#### K2 — Add `kemoia_implies_secure_distinct` corollary

**File.** `Orbcrypt/KEM/Security.lean`.

**Change.** The KEM security game does not currently have a
`distinct`-challenge variant — `kemHasAdvantage` is defined over two
arbitrary group elements rather than two messages. Carefully examining
the KEM game: the adversary picks `g₀, g₁` and tries to distinguish
the two encapsulations; there is no per-message collision risk
analogous to the scheme-level `(m, m)` issue. Therefore **no
`_distinct` KEM corollary is required**; M1's KEM concern is already
addressed by the structure of `kemHasAdvantage`.

**Action.** Add a docstring note to `kemoia_implies_secure`
clarifying that the KEM game has a single base-point orbit and
therefore does not admit the scheme-level collision-choice gap — no
new theorem is introduced.

**Acceptance.** Documentation-only; `lake build` is unaffected.

#### K3 — Add `hardness_chain_implies_security_distinct` corollary

**File.** `Orbcrypt/Hardness/Reductions.lean`, appended to the
deterministic chain section.

**Change.** Parallel to K1:
```lean
theorem hardness_chain_implies_security_distinct
    ... (hChain : HardnessChain (F := F) scheme) :
    IsSecureDistinct scheme :=
  isSecure_implies_isSecureDistinct scheme
    (hardness_chain_implies_security scheme hChain)
```

**Acceptance.** Same as K1.

#### K4 — Add probabilistic distinct-challenge variants

**File.** `Orbcrypt/Crypto/CompSecurity.lean` and/or
`Orbcrypt/Hardness/Reductions.lean`.

**Change.** `concrete_oia_implies_1cpa` concludes a quantitative bound
on `indCPAAdvantage`; the distinct-challenge form requires
`indCPAAdvantageDistinct` (a new definition that conjoins the
distinctness witness). Decision:
- **If** `indCPAAdvantage` already uses `Adversary` (not
  `AdversaryDistinct`), *and* the probabilistic distinguishing sum
  collapses to zero on collision choices (which it does, because
  `g₀ • reps m = g₀ • reps m`), then the existing `indCPAAdvantage`
  upper bound `≤ ε` transfers to the distinct-challenge form for
  free; no new statement is needed.
- **Else**, add a distinct-challenge version that filters on
  `(A.choose).1 ≠ (A.choose).2` and repeat the reduction.

**Pre-implementation check.** Audit `indCPAAdvantage` in
`Crypto/CompSecurity.lean` to determine whether the collision case
trivially gives advantage 0 (via PMF.pure's symmetric advantage
identity). If yes, document this in a new one-line lemma
`indCPAAdvantage_eq_distinct_on_distinct`; if no, a full distinct
variant is required.

**Acceptance.** `#print axioms` on the new declarations shows only
standard trio.

#### K5 — Update transparency report and headline tables

**Files.** `Orbcrypt.lean`, `CLAUDE.md`, `docs/VERIFICATION_REPORT.md`.

**Change.** Add the new `_distinct` corollaries to the axiom-
transparency report and to CLAUDE.md's headline-theorem table
(marked as "Standalone — classical IND-1-CPA"). Release-facing
citations in `docs/VERIFICATION_REPORT.md` are updated to prefer the
`_distinct` corollaries.

**Acceptance.** Manual review + `scripts/audit_phase_16.lean` pass.

### 6.3 Exit criteria for Workstream K

1. `lake build` succeeds.
2. `oia_implies_1cpa_distinct`, `hardness_chain_implies_security_distinct`
   exist and carry standard-trio axioms only.
3. The probabilistic distinct-challenge variant either exists as a
   new theorem or is documented as definitionally equivalent via K4.
4. Root transparency report and CLAUDE.md are updated.

## 7. Workstream L — structural & naming hygiene (M2–M6, MEDIUM)

Five independent sub-workstreams, each a small-diff refactor. They
may be landed in any order.

### 7.1 L1 — `SeedKey` structural tightening (M2)

**File.** `Orbcrypt/KeyMgmt/SeedKey.lean`.

**Problem.**
1. The `expand` field is declared but never consumed by any theorem.
2. `seed_determines_key` / `seed_determines_canon` require equal
   `sampleGroup` / `expand` functions as hypotheses — both proofs are
   trivial rewrites with no semantic constraint on the seed-to-key
   relationship.
3. The docstring's "~58,600× compression" figure is not formally
   witnessed by any Lean statement; the structure's `Seed` is
   unconstrained in size.

**Decision.** Two acceptable resolutions; the plan adopts option
**(a)** — "honest API" — as the smallest diff:

- **(a) Honest API.** Drop the compression-ratio framing from the
  docstring; keep `expand` as a dead field but annotate with "used
  by downstream consumers (e.g., the GAP implementation) for
  canonical-form reconstruction; not referenced by any in-tree Lean
  theorem".
- **(b) Witnessed compression.** Add `[Fintype Seed]` and a
  `compression : 8 * Fintype.card Seed < log₂ (Fintype.card G)` proof
  field. This would add semantic weight but requires inequality
  lemmas and a Fintype instance for `G` — considerably more scope.

Option **(a)** leaves the API unchanged; option **(b)** is a
follow-up (post-release).

#### L1-WU1 — Rewrite `SeedKey` docstring for option (a)

**Change.** In `Orbcrypt/KeyMgmt/SeedKey.lean`'s module docstring,
replace the "Key size comparison" table with:

```text
## Compression semantics

This module specifies the **seed-key API** but does not formally
witness compression. A concrete instance whose `Seed` is
significantly smaller than `G` — e.g., the GAP HGOE implementation
where `Seed = Fin 256 → Bool` (256 bits) and `G` is a subgroup of
`S_n` of order ≥ 2¹²⁸ — realises the advertised compression, but
the Lean level only asserts that seed-based key expansion preserves
KEM correctness (`seed_kem_correctness`).

The `expand` field carries the deterministic seed-to-canonical-form
map for downstream consumers; no in-tree theorem references it
beyond the backward-compat bridge `toSeedKey_expand`.
```

**Acceptance.** `lake build Orbcrypt.KeyMgmt.SeedKey` succeeds.

#### L1-WU2 — Tighten `seed_determines_*` docstrings

**Change.** Reword the docstrings to reflect the theorems' actual
content: "given equal seeds *and* equal expansion/sampling functions,
outputs agree by pointwise rewrite". Note that these are rewrite
lemmas, not constraints on the seed-to-key relationship.

**Acceptance.** Manual review.

#### L1-WU3 — Add compression-bound tracking note

**File.** `CLAUDE.md`.

**Change.** Add a one-paragraph tracking note under Phase 9: "Formal
compression-ratio witness via `[Fintype Seed]` is tracked as
post-release Workstream L1-b; the current module asserts only
`seed_kem_correctness`, not a quantitative size bound."

### 7.2 L2 — `carterWegmanMAC` primality hygiene (M3)

**File.** `Orbcrypt/AEAD/CarterWegmanMAC.lean`.

**Problem.** `carterWegmanMAC (p : ℕ)` accepts `p = 0` (`ZMod 0 = ℤ`,
which is not a finite field; universal-hash semantics break).
`[Fact (Nat.Prime p)]` would be the cryptographically correct
constraint but is over-restrictive — the Lean `correct` and
`verify_inj` obligations hold for any `p`. The audit proposes two
options: (a) add a typeclass constraint, or (b) rename.

**Decision.** Adopt the **minimal-diff option (c)** — add `[NeZero p]`
and tighten the docstring:

- `[NeZero p]` rules out `p = 0` (so `ZMod p` is a proper finite
  type) without demanding primality.
- The docstring is explicit: the identifier `carterWegmanMAC` names
  the *linear hash shape* `k₁ · m + k₂`, which is the Carter–Wegman
  universal hash when `p` is prime *and* the MAC key is sampled
  uniformly. In the deterministic setting here, it serves as a
  `verify_inj`-witness template — not a cryptographic CW primitive.
- If primality is required for a downstream security argument, that
  argument adds its own `[Fact (Nat.Prime p)]`; the MAC API does not
  bake it in.

#### L2-WU1 — Add `[NeZero p]` to `carterWegmanMAC` and `carterWegman_authKEM`

**Change.** In `Orbcrypt/AEAD/CarterWegmanMAC.lean`:
- `def carterWegmanHash (p : ℕ) [NeZero p] ... := ...`
- `def carterWegmanMAC (p : ℕ) [NeZero p] : MAC ... := ...`
- `def carterWegman_authKEM (p : ℕ) [NeZero p] ...`
- `theorem carterWegmanMAC_int_ctxt (p : ℕ) [NeZero p] ...`

**Acceptance.** `lake build Orbcrypt.AEAD.CarterWegmanMAC` succeeds.

**Regression safeguard.** `scripts/audit_c_workstream.lean` currently
instantiates at `p = 1`; Mathlib provides `instance : NeZero (n+1)`
for every `n : ℕ`, so `NeZero 1` resolves automatically (as does any
other positive literal). Verify the audit script still type-checks;
no manual `haveI : NeZero 1 := ⟨one_ne_zero⟩` should be needed.

**Note on `ZMod 1`.** `ZMod 1` is the trivial ring (all elements
equal 0), so `carterWegmanMAC 1` is still cryptographically trivial
— but it is a *consistent* `MAC` instance, which is all the audit
script needs. Post-change, a constructor at `p = 0` (previously
admitted) is rejected at elaboration time, which is the desired
behaviour.

#### L2-WU2 — Rewrite docstring to separate hash-shape from CW primitive

**Change.** In the module docstring and the `carterWegmanMAC`
docstring, insert a clarifying paragraph:

```text
## Naming note (audit F-AUDIT-2026-04-21-M3)

The identifier `carterWegmanMAC` names the **linear hash shape**
`k₁ · m + k₂` over `ZMod p`. The Carter–Wegman universal-hash
security guarantee requires `p` prime *and* probabilistic key
sampling; in this deterministic formalization, `carterWegmanMAC`
serves as a `MAC`-abstraction witness demonstrating that
`verify_inj` is satisfiable. Consumers who want the CW universal-
hash property must add `[Fact (Nat.Prime p)]` and a
probabilistic-key-sampling argument on top of this MAC; the base
construction is the deterministic linear-hash MAC, not the
cryptographic primitive.
```

**Acceptance.** Manual review.

#### L2-WU3 — Update audit script and transparency report

**Files.** `scripts/audit_c_workstream.lean`, `Orbcrypt.lean`.

**Change.** Confirm `[NeZero p]` does not change the axiom dependencies
of `carterWegmanMAC_int_ctxt`; update the transparency-report entry
to note the `[NeZero p]` addition.

### 7.3 L3 — `RefreshIndependent` rename (M4)

**File.** `Orbcrypt/PublicKey/ObliviousSampling.lean`.

**Problem.** The names `RefreshIndependent` and `refresh_independent`
imply a cryptographic independence claim, but the theorem is
`funext`-structural: if two samplers agree on the per-epoch index
ranges, the refresh bundles agree. No cryptographic independence is
asserted.

**Decision.** Rename to `RefreshDependsOnlyOnEpochRange` /
`refresh_depends_only_on_epoch_range`. This preserves the structural
meaning and removes the misleading cryptographic framing. Downstream
consumers (currently only `Orbcrypt.lean`, `scripts/audit_phase_16.lean`,
`scripts/audit_print_axioms.lean`) are updated in the same commit.

#### L3-WU1 — Rename declarations

**Change.**
- `def RefreshIndependent` → `def RefreshDependsOnlyOnEpochRange`
- `theorem refresh_independent` → `theorem refresh_depends_only_on_epoch_range`

Update internal self-references (module docstring, `RefreshIndependent`
docstring cross-references).

**Acceptance.** `lake build Orbcrypt.PublicKey.ObliviousSampling`
succeeds.

#### L3-WU2 — Update downstream references

**Files.** `Orbcrypt.lean` (both module dependency graph and axiom
transparency report), `scripts/audit_phase_16.lean`,
`scripts/audit_print_axioms.lean`, `docs/VERIFICATION_REPORT.md` if
it cites the old names.

**Change.** Mechanical find-and-replace across these files.

**Acceptance.**
- `lake env lean scripts/audit_phase_16.lean` succeeds.
- `lake env lean scripts/audit_print_axioms.lean` succeeds.

#### L3-WU3 — Update prose documentation

**Files.** `CLAUDE.md`, `DEVELOPMENT.md`, `docs/PUBLIC_KEY_ANALYSIS.md`,
`docs/USE_CASES.md`, `docs/MORE_USE_CASES.md`,
`formalization/FORMALIZATION_PLAN.md`,
`docs/planning/PHASE_13_PUBLIC_KEY_EXTENSION.md`.

**Change.** Mechanical rename where the old identifier appears; keep
the prose explanation of "structural independence vs. cryptographic
independence" intact.

### 7.4 L4 — `SymmetricKeyAgreementLimitation` rename (M5)

**File.** `Orbcrypt/PublicKey/KEMAgreement.lean`.

**Problem.** The name implies a negative impossibility result; the
theorem is `rfl` (definitional unfolding of `sessionKey` and
`encaps`).

**Decision.** Rename to `sessionKey_expands_to_canon_form` /
`SessionKeyExpansionIdentity`. The rename signals that the theorem
is a decomposition identity exhibiting both parties' canonical forms,
not an impossibility proof.

#### L4-WU1 — Rename declarations

**Change.**
- `def SymmetricKeyAgreementLimitation` →
  `def SessionKeyExpansionIdentity`
- `theorem symmetric_key_agreement_limitation` →
  `theorem sessionKey_expands_to_canon_form`

Update module docstring, internal cross-references, and the
rationale paragraph (now: "This identity exhibits both parties'
canonical forms inside the session-key formula; a **separate**
impossibility theorem for public-key orbit encryption is tracked in
`docs/PUBLIC_KEY_ANALYSIS.md` but is out of scope for this module").

**Acceptance.** `lake build Orbcrypt.PublicKey.KEMAgreement` succeeds.

#### L4-WU2 — Update downstream references

Same as L3-WU2 but for the new names. Touch the same set of files.

### 7.5 L5 — `KEMOIA` redundant-conjunct removal (M6)

**File.** `Orbcrypt/KEM/Security.lean`, `Orbcrypt/KEM/CompSecurity.lean`.

**Problem.** `KEMOIA kem` is the conjunction of:
1. **Orbit indistinguishability** (quantified Boolean distinguisher
   on orbit elements).
2. **Key uniformity** (the derived key is constant across the orbit).

The second conjunct is **unconditionally provable** from
`canonical_isGInvariant` (witnessed by
`kem_key_constant_direct`), so it carries no additional assumption
content. `KEMOIA` is equivalent to its first conjunct.

**Decision.** Drop the second conjunct. Update `kemoia_implies_secure`
to invoke `kem_key_constant_direct` where it currently uses `hOIA.2`.
Update `det_kemoia_implies_concreteKEMOIA_zero` similarly.

#### L5-WU1 — Simplify the `KEMOIA` definition

**Change.** In `Orbcrypt/KEM/Security.lean`:

```lean
def KEMOIA [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) : Prop :=
  ∀ (f : X → Bool) (g₀ g₁ : G),
    f (g₀ • kem.basePoint) = f (g₁ • kem.basePoint)
```

(Drop the key-uniformity conjunct.)

**Acceptance.** The definition compiles; `#check KEMOIA` shows the
simpler form.

#### L5-WU2 — Adjust `kemoia_implies_secure`

**Change.** Replace `hOIA.1` with `hOIA`, and `hOIA.2 g` with
`kem_key_constant_direct kem g`. The proof body becomes:

```lean
theorem kemoia_implies_secure ... : KEMIsSecure kem := by
  intro A ⟨g₀, g₁, hNeq⟩
  apply hNeq
  rw [kem_key_constant_direct kem g₀, kem_key_constant_direct kem g₁]
  exact hOIA (fun c => A.guess kem.basePoint c
    (kem.keyDerive (kem.canonForm.canon kem.basePoint))) g₀ g₁
```

**Acceptance.** `lake build Orbcrypt.KEM.Security` succeeds.

#### L5-WU3 — Adjust `kem_key_constant` and `kem_ciphertext_indistinguishable`

**Change.**
- `kem_key_constant` (which currently extracts `hOIA.2 g`) is now
  identical to `kem_key_constant_direct`; mark it deprecated and
  route it to `kem_key_constant_direct`. Or, per CLAUDE.md "no
  backwards-compat shims", **delete** `kem_key_constant` outright
  and rename `kem_key_constant_direct` to `kem_key_constant` if
  the name freedom up. **Decision: delete the redundant
  `kem_key_constant` and keep `kem_key_constant_direct` as the
  authoritative form** (clearer about its origin).
- `kem_ciphertext_indistinguishable` — unchanged (extracts the first
  conjunct, which is now the whole `KEMOIA`). Change `hOIA.1` to
  `hOIA`.

**Acceptance.** `lake build` succeeds; all `#print axioms` on the
affected theorems are unchanged.

#### L5-WU4 — Adjust `det_kemoia_implies_concreteKEMOIA_zero`

**File.** `Orbcrypt/KEM/CompSecurity.lean`.

**Change.** The proof currently uses `hOIA.2 g₀` and `hOIA.2 g₁`;
replace with `kem_key_constant_direct kem g₀` and `...
kem g₁`. The rest of the proof is unchanged.

**Acceptance.** `lake build Orbcrypt.KEM.CompSecurity` succeeds.

#### L5-WU5 — Update transparency report and headline tables

**Files.** `Orbcrypt.lean`, `CLAUDE.md`, `docs/VERIFICATION_REPORT.md`.

**Change.** Update the `KEMOIA` description: "Now single-conjunct
(orbit indistinguishability only). Key uniformity is unconditionally
provable from `canonical_isGInvariant` via
`kem_key_constant_direct`; the old second conjunct was redundant
(audit F-AUDIT-2026-04-21-M6 / Workstream L5)."

### 7.6 Exit criteria for Workstream L

1. All five sub-workstreams (L1–L5) either land or are explicitly
   deferred with a tracking note in CLAUDE.md.
2. `lake build` succeeds for all modules.
3. `scripts/audit_phase_16.lean` passes (note: the renamed
   declarations in L3 and L4 require script updates in the same
   commit).
4. No custom axioms introduced; all new declarations carry only the
   standard Lean trio.

## 8. Workstream M — low-priority polish (L1–L8, LOW)

Eight sub-items, each a small or documentation-only diff. Landing
order is immaterial; grouping into a single commit-per-sub-item is
fine.

### 8.1 M1 — `UniversalConcreteTensorOIA` universe polymorphism (L1)

**File.** `Orbcrypt/Hardness/Reductions.lean`.

**Action.** After Workstream G lands, the audit's original concern
(`{G_TI : Type}` vs `{G_TI : Type*}`) is moot because `G_TI` is no
longer implicit. If the post-G `SurrogateTensor F` structure has
`carrier : Type` (universe 0), optionally generalise to
`carrier : Type*` with a `universe u` declaration in the module
header. Not required for the pre-release.

**Acceptance.** Optional.

### 8.2 M2 — `hybrid_argument_uniform` docstring (L2)

**File.** `Orbcrypt/Probability/Advantage.lean`.

**Change.** Add a one-sentence note to the `hybrid_argument_uniform`
docstring:

```text
Note: no `0 ≤ ε` hypothesis is carried. For `ε < 0`, the per-step
bound `h_step` is unsatisfiable (advantage is always `≥ 0` via
`advantage_nonneg`), so the conclusion holds vacuously. The
intended use case is `ε ∈ [0, 1]`.
```

**Acceptance.** Docstring-only; `lake build` unchanged.

### 8.3 M3 — deterministic-reduction existentials (L3)

**File.** `Orbcrypt/Hardness/Reductions.lean`.

**Problem.** `TensorOIAImpliesCEOIA` concludes `∃ k C₀ C₁, CEOIA C₀
C₁`. Taking `C₀ = C₁ = ∅, k = 0` makes the body vacuously true, so
the Prop admits trivial satisfiers.

**Action.** Tighten the existentials to require `k ≥ 1` and
`C₀.Nonempty ∧ C₁.Nonempty`, OR document explicitly that the
deterministic chain is an *algebraic-scaffolding* Prop and admit the
looseness.

**Decision.** Documentation-only. The deterministic chain is already
vacuous via H3 (deterministic OIA is False on non-trivial schemes),
and tightening the existentials would require parallel proofs in
`Hardness/Reductions.lean` to carry non-empty witnesses through
three reduction layers — work disproportionate to the gain given
that the deterministic chain is explicitly framed as scaffolding by
Workstream J's release messaging. Add a paragraph to each
reduction Prop's docstring noting that the existential form admits
trivial satisfiers and that the probabilistic `Concrete*` chain is
the non-vacuous counterpart.

**Acceptance.** Docstring-only; `lake build` unchanged.

### 8.4 M4 — (deferred, tracked as Workstream F3/F4)

**File.** n/a — no in-tree action.

**Action.** `GIReducesToCE` / `GIReducesToTI` admit degenerate
encoders (e.g., `encode _ := ∅`). Concrete Karp reductions via
CFI / Grochow–Qiao are Workstream F3/F4 scope; the current plan
only notes the limitation in
`docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` (this file,
§ 12) as a post-release follow-up.

### 8.5 M5 — invariant-attack advantage framing (L5)

**File.** `Orbcrypt/Theorems/InvariantAttack.lean`.

**Change.** Add a one-sentence clarification to the
`invariant_attack` docstring:

```text
Advantage mapping note. This theorem proves deterministic advantage
= 1 (the adversary distinguishes perfectly on at least one pair of
group elements). In the probabilistic-game convention where
advantage is `|Pr[A=1|b=0] - Pr[A=1|b=1]|`, deterministic
advantage 1 corresponds to probabilistic advantage 1, which in the
centred `Pr[correct] - 1/2` convention is `1/2`. The three
conventions agree on "complete break"; this module uses the
deterministic shape.
```

**Acceptance.** Docstring-only.

### 8.6 M6 — `hammingWeight_invariant_subgroup` named-pattern cleanup (L6)

**File.** `Orbcrypt/Construction/HGOE.lean`.

**Change.** Replace
```lean
theorem hammingWeight_invariant_subgroup ... := by
  intro ⟨σ, _⟩ x
  exact hammingWeight_invariant σ x
```
with
```lean
theorem hammingWeight_invariant_subgroup ... := by
  intro g x
  exact hammingWeight_invariant (↑g : Equiv.Perm (Fin n)) x
```

**Acceptance.** `lake build Orbcrypt.Construction.HGOE` succeeds;
`#print axioms hammingWeight_invariant_subgroup` is unchanged.

### 8.7 M7 — `IsNegligible` n₀ ≥ 1 convention docstring (L7)

**File.** `Orbcrypt/Probability/Negligible.lean`.

**Change.** Add to the `IsNegligible` docstring:

```text
Convention. At `n = 0`, `(0 : ℝ)⁻¹ = 0` (Lean's convention), so the
clause `|f n| < (n : ℝ)⁻¹ ^ c` reduces to `|f 0| < 0` (for
`c ≥ 1`), which is trivially false. All in-tree proofs of
`IsNegligible f` choose `n₀ ≥ 1` to side-step this edge case; the
intended semantics is "eventually", and the n = 0 case carries no
content.
```

**Acceptance.** Docstring-only.

### 8.8 M8 — `combinerOrbitDist_mass_bounds` disclosure (L8)

**File.** `Orbcrypt/PublicKey/CombineImpossibility.lean`.

**Change.** Add a concrete negative example to the
`combinerOrbitDist_mass_bounds` docstring:

```text
Negative example. Consider a scheme where two distinct messages
`m₀, m₁` share an orbit — i.e., `orbit G (reps m₀) = orbit G
(reps m₁)`. Then `combinerOrbitDist m₀ = combinerOrbitDist m₁` as
PMFs; any distinguisher has advantage 0 despite
`combinerOrbitDist_mass_bounds` delivering `≥ 1/|G|` mass on both
Booleans for each orbit. This illustrates that intra-orbit mass
bounds do not imply cross-orbit advantage lower bounds.
```

(Note: the `reps_distinct` field of `OrbitEncScheme` prohibits the
shared-orbit case at the scheme level, so the example is
hypothetical. The docstring should note this.)

**Acceptance.** Docstring-only.

### 8.9 Exit criteria for Workstream M

1. All sub-items either land or are explicitly deferred.
2. No source-level behaviour changes (all items are docstring or
   named-pattern refactors).
3. `lake build` and audit scripts continue to pass.

## 9. Workstream N — info hygiene (I1, I5)

### 9.1 N1 — lakefile version reconciliation (I1)

**Problem.** `lakefile.lean` carries `version := v!"0.1.5"`; the
CLAUDE.md per-workstream version log ends at `0.1.4`. There is no
CLAUDE.md entry documenting the `0.1.4 → 0.1.5` bump.

**Decision.** Add a Phase 15 CLAUDE.md entry noting the version
bump ("`lakefile.lean` bumped from 0.1.4 to 0.1.5 during Phase 15.3
post-landing audit to capture the orbit-constancy refactor of
`fast_kem_round_trip`"). If no such Phase-15 workstream event
actually justifies the bump, instead rollback the lakefile to
`0.1.4` to restore monotonicity.

**Acceptance.** Either option is acceptable; the plan recommends
the CLAUDE.md addition as the lower-risk choice (avoids modifying
an already-published lakefile version).

**Action items.**
- **N1-WU1.** Audit the git log between the Phase-14 merge and HEAD
  for the commit that bumped `lakefile.lean`.
- **N1-WU2.** Add a Phase-15 subsection in CLAUDE.md capturing the
  bump rationale.

### 9.2 N2 — `TwoPhaseDecomposition` empirical falsity (I2)

Self-disclosed in `Optimization/TwoPhaseDecrypt.lean` and in
CLAUDE.md's Phase 15 section. No action required beyond periodic
re-verification during release-messaging passes.

### 9.3 N3 — `indQCPA_bound_via_hybrid` `h_step` gap (I3)

Self-disclosed in `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md`
§ E8b. Tracked as post-release Workstream. No action this plan.

### 9.4 N4 — `scripts/setup_lean_env.sh` (I4)

Self-disclosed clean audit result — no vulnerability, no action.

### 9.5 N5 — CI nested-block-comment note (I5)

**File.** `.github/workflows/lean4-build.yml`.

**Change.** Add a CI-level comment:

```yaml
# Note: the sorry-scan regex (/-.*?-/) does not handle Lean's nested
# block comments. If you introduce a nested `/- … /- … -/ … -/`
# block, the inner `sorry` could be missed by this scan. Run
# `lake build` locally (which uses Lean's own parser) to confirm.
```

**Acceptance.** CI passes; the comment is informational.

### 9.6 Exit criteria for Workstream N

1. Lakefile version history is coherent.
2. CI YAML carries the nested-comment disclaimer.
3. No behaviour changes.

## 10. Dependency graph & execution schedule

### 10.1 Workstream dependency DAG

```text
              ┌─────────────────┐
              │  Workstream G   │   HIGH — hardness-chain fix
              │  (H1 resolution)│   (pre-release critical)
              └────────┬────────┘
                       │
           ┌───────────┼────────────┐
           │           │            │
           ▼           ▼            ▼
    ┌──────────┐  ┌──────────┐ ┌──────────┐
    │   WS H   │  │   WS J   │ │   WS K   │
    │ (H2)     │  │ (H3 docs)│ │ (M1)     │
    │ KEM chain│  │ framing  │ │ distinct │
    └──────────┘  └──────────┘ └──────────┘
           (all three can run in parallel after G merges)

  Independent of G (any time):
    ┌──────────┐  ┌──────────┐  ┌──────────┐
    │ WS L1–L5 │  │ WS M1–M8 │  │ WS N1–N5 │
    │ M2–M6    │  │ L1–L8    │  │ I1–I5    │
    └──────────┘  └──────────┘  └──────────┘
```

**Critical path.** `G → J → release`. **Preferred path.**
`G → {H, J, K, L} → release`.

### 10.2 Execution schedule (single-implementer, sequential)

| Day | Morning | Afternoon |
|-----|---------|-----------|
| 1 | WU G1 + G2 (surrogate + universal-form refactor) | WU G3 + G4 (chain structure + composition) |
| 2 | WU G5 + G6 (audit scripts + transparency) | WU K1 + K3 + K5 (distinct-challenge corollaries) |
| 3 | WU H1 + H2 + H3 (KEM-layer chain) | WU H4 + WU J1 + J2 + J3 (docs) |
| 4 | WU L1 + L5 (SeedKey + KEMOIA hygiene) | WU L2 + L3 + L4 (naming) |
| 5 | WU M1–M8 (polish) + WU N1 + N5 | Final CI pass + release-readiness check |

### 10.3 Parallel execution (two implementers)

**Implementer A** owns the pre-release critical path: G → H → K.
**Implementer B** owns polish and docs: J, L, M, N in parallel.
Merge ordering: A's branches merge first; B rebases on A's merges
before landing.

### 10.4 Branch naming

Per the session context, the planning document lives on
`claude/audit-workstream-planning-uXM1Q`. Per-workstream
implementation branches follow the Orbcrypt convention
`claude/audit-2026-04-21-workstream-{letter}`:

- `claude/audit-2026-04-21-workstream-g`
- `claude/audit-2026-04-21-workstream-h`
- `claude/audit-2026-04-21-workstream-j`
- `claude/audit-2026-04-21-workstream-k`
- `claude/audit-2026-04-21-workstream-l` (omnibus; subdivide only if
  review feedback demands)
- `claude/audit-2026-04-21-workstream-m`
- `claude/audit-2026-04-21-workstream-n`

Each branch carries one PR; PRs are merged in the dependency order
defined above.

## 11. Regression safeguards

### 11.1 CI guarantees

The existing CI workflow (`.github/workflows/lean4-build.yml`) runs:

1. `lake build` for every module.
2. Comment-aware `sorry` scan (Perl regex strips block and line
   comments before grepping).
3. Axiom-declaration scan (`^axiom` at column 0).
4. `scripts/audit_phase_16.lean` execution: de-wraps multi-line
   axiom lists and rejects any non-standard axiom.

**Post-workstream extensions.** After Workstream G merges, add a
new audit script entry in `scripts/audit_phase_16.lean`:

```text
#print axioms ConcreteHardnessChain  -- surrogate parameter now bound
#print axioms UniversalConcreteTensorOIA
```

Both should emit standard-trio axioms only.

### 11.2 Per-workstream satisfiability witnesses

Each workstream that modifies a structural predicate ships an
`example` in the relevant audit script confirming non-vacuity:

- **G**: `ConcreteHardnessChain toyScheme (ZMod 2) punitSurrogate 1`
  is inhabitable (via `tight_one_exists`).
- **H**: `ConcreteKEMHardnessChain` at `ε = 1` is inhabitable.
- **K**: `oia_implies_1cpa_distinct scheme hOIA` is exercisable on
  the scheme constructed in `audit_b_workstream.lean`.
- **L1** (SeedKey): docstring-only, no witness.
- **L2** (CarterWegmanMAC): `carterWegmanMAC_int_ctxt` at `p = 1` is
  exercisable (with the new `[NeZero 1]` instance, which Mathlib
  provides).
- **L3** (RefreshIndependent rename): the old
  `scripts/audit_print_axioms.lean` example is updated to the new
  name; the `#print axioms` output is unchanged.
- **L4** (SessionKeyExpansionIdentity rename): same as L3.
- **L5** (KEMOIA refactor): `kemoia_implies_secure` still
  demonstrably produces `KEMIsSecure` for a toy KEM; the audit
  script's existing KEM example is extended.

### 11.3 Golden-file baselines

Workstream G modifies the signature of
`concrete_hardness_chain_implies_1cpa_advantage_bound` (adds an
implicit `SurrogateTensor` parameter). Baseline `#print` outputs in
`scripts/audit_phase_16.lean` and `scripts/audit_e_workstream.lean`
change accordingly; the CI's axiom-set whitelist remains identical.

Workstream L3 and L4 change declaration names; golden `#print
axioms` outputs change in their left-hand-side identifier only. CI's
axiom-set whitelist is unaffected.

### 11.4 Review checklist (for PR authors)

Before opening a PR on any workstream branch, confirm:

- [ ] `source ~/.elan/env && lake build` succeeds (exit code 0, no
      warnings).
- [ ] Every modified module builds individually: `lake build
      Orbcrypt.<ModulePath>`.
- [ ] `grep -rn "sorry" Orbcrypt/ --include="*.lean"` (comment-aware
      variant) returns empty.
- [ ] `scripts/audit_phase_16.lean` passes locally.
- [ ] For renames (L3, L4): all downstream `.lean`, `.md`, and `.sh`
      references updated; CI green on the rename-only diff before
      combining with other changes.
- [ ] Naming hygiene: `git diff --cached -U0 -- '*.lean' | grep -E
      '^\+(def|theorem|structure|class|instance|abbrev|lemma)'
      | grep -iE 'workstream|\bws[0-9]|\bwu[0-9]|\bphase[0-9_]|audit|
      \bf[0-9]{2}\b|\bstep[0-9]|\btmp\b|\btodo\b|claude_'` returns
      empty (per CLAUDE.md's naming discipline).
- [ ] CLAUDE.md updated with a per-workstream entry (following the
      2026-04-18 precedent).
- [ ] `Orbcrypt.lean`'s axiom-transparency report updated.
- [ ] `docs/VERIFICATION_REPORT.md` updated if the workstream
      affects a headline theorem.

## 12. Release-readiness checklist

Upon completion of the pre-release slate (Workstreams **G**, **J**,
**K**), verify:

- [ ] `ConcreteHardnessChain` accepts a `SurrogateTensor F`
      parameter; `tight_one_exists` witnesses inhabitation at
      `ε = 1`; `concrete_hardness_chain_implies_1cpa_advantage_bound`
      delivers a quantitatively meaningful bound for any
      caller-supplied surrogate.
- [ ] `IsSecureDistinct`-concluding corollaries exist for the three
      deterministic-chain headline theorems; release-facing docs
      cite them.
- [ ] `docs/VERIFICATION_REPORT.md`'s "Known limitations" section
      distinguishes the deterministic and probabilistic chains and
      explicitly recommends the probabilistic form for external
      claims.
- [ ] `CLAUDE.md`'s headline-theorem table carries a "Status" column
      (Standalone / Scaffolding / Quantitative).
- [ ] `lakefile.lean`'s version and CLAUDE.md's version log agree.
- [ ] All 38 modules build clean; audit scripts emit standard-trio
      axioms only; zero `sorry`; zero custom axioms.

After the preferred-pre-release slate (**H**, **L**) lands:

- [ ] `ConcreteKEMOIA_uniform` is composable via
      `ConcreteKEMHardnessChain` — KEM consumers have an ε-smooth
      chain.
- [ ] `SeedKey`, `carterWegmanMAC`, `RefreshIndependent`,
      `SymmetricKeyAgreementLimitation`, `KEMOIA` all carry their
      tightened definitions / renames.

Post-release (tracked as follow-up):

- [ ] Workstream F3/F4: concrete Karp reductions via CFI graph
      gadget / Grochow–Qiao structure-tensor encoding.
- [ ] Workstream L1-b: formal compression-ratio witness on `SeedKey`
      via `[Fintype Seed]` + inequality proof.
- [ ] Workstream E8b: discharge `h_step` in
      `indQCPA_bound_via_hybrid` from a single-query `ConcreteOIA`
      (marginal-independence step).

## 13. Non-findings confirmed as valid (spot-checked during planning)

The audit reports 22 findings; each was spot-checked during this
planning pass against the actual source code to rule out erroneous
findings. Summary:

| Finding | Validation method | Result |
|---------|------------------|--------|
| H1 | Read `Hardness/Reductions.lean:316–322`, confirmed `{G_TI : Type}` implicit universal quantifier. Confirmed PUnit is `Group`/`Fintype`/`Nonempty` and admits trivial MulAction. | Valid |
| H2 | Read `KEM/CompSecurity.lean:109–152`, confirmed point-mass advantage collapses `∈ {0, 1}`. `ConcreteKEMOIA_uniform` exists at line 186; no chain composes through it. | Valid (self-disclosed) |
| H3 | Read `Crypto/OIA.lean` module docstring and definition; confirmed `∀ f : X → Bool` quantifier admits `decide (x = reps m₀)` distinguisher. | Valid (self-disclosed) |
| M1 | Read `Crypto/Security.lean`, confirmed `hasAdvantage` lacks distinctness requirement; `IsSecureDistinct` exists but downstream theorems target `IsSecure`. | Valid |
| M2 | Read `KeyMgmt/SeedKey.lean`; confirmed `expand` field has no theorem consumer other than the trivial `toSeedKey_expand : rfl`. | Valid |
| M3 | Read `AEAD/CarterWegmanMAC.lean`; confirmed `def carterWegmanMAC (p : ℕ)` with no `[Fact Nat.Prime p]` or `[NeZero p]`. | Valid |
| M4 | Read `PublicKey/ObliviousSampling.lean:297–327`; confirmed `refresh_independent` proof is `funext + hypothesis`. | Valid |
| M5 | Read `PublicKey/KEMAgreement.lean:230–242`; confirmed `symmetric_key_agreement_limitation` proof is `show ... ; rfl`. | Valid |
| M6 | Read `KEM/Security.lean:165–197`; confirmed `kem_key_constant_direct` proves the second conjunct of `KEMOIA` without using `hOIA`. | Valid |
| L1 | Read `Hardness/Reductions.lean:317`; confirmed `{G_TI : Type}` is universe 0. | Valid (subsumed by G) |
| L2 | Read `Probability/Advantage.lean`, confirmed no `0 ≤ ε` on `hybrid_argument_uniform`. | Valid |
| L3 | Read `Hardness/Reductions.lean:155–173`; confirmed `∃ k C₀ C₁, CEOIA C₀ C₁` form, confirmed `C₀ = C₁ = ∅` gives vacuous `CEOIA`. | Valid |
| L4 | Reviewed `GIReducesToCE` / `GIReducesToTI` definitions; confirmed `encode _ := ∅` gives trivial witnesses. | Valid (self-disclosed as F-12) |
| L5 | Read `Theorems/InvariantAttack.lean` docstring; confirmed "advantage = 1/2" framing and deterministic-advantage-1 proof body. | Valid |
| L6 | Read `Construction/HGOE.lean:89–93`; confirmed anonymous pattern `⟨σ, _⟩`. | Valid |
| L7 | Read `Probability/Negligible.lean:36–37`; confirmed no `n₀ ≥ 1` constraint in the definition. | Valid |
| L8 | Read `PublicKey/CombineImpossibility.lean`'s `combinerOrbitDist_mass_bounds` docstring. | Valid |
| I1 | Read `lakefile.lean:5`; confirmed `version := v!"0.1.5"`; cross-referenced CLAUDE.md's per-workstream version log (last entry `0.1.4`). | Valid |
| I2 | Read `Optimization/TwoPhaseDecrypt.lean` docstring and CLAUDE.md Phase 15 section; self-disclosed. | Valid |
| I3 | Read `Crypto/CompSecurity.lean` `indQCPA_bound_via_hybrid` signature; confirmed `h_step` is a hypothesis. | Valid (self-disclosed) |
| I4 | Read `scripts/setup_lean_env.sh` header and SHA-pinned blocks. | Valid |
| I5 | Read `.github/workflows/lean4-build.yml` sorry-scan and axiom-scan regexes. | Valid |

**Conclusion.** All 22 findings are valid and map cleanly to the
letter-coded workstreams above. No finding was erroneously raised or
duplicated.

## 14. Appendix A — Finding-ID → work-unit cross-reference

| Finding ID | Grade | Workstream | Work unit(s) | Artefact |
|------------|-------|------------|--------------|----------|
| H1 (AUDIT-2026-04-21-H1) | HIGH | G | G1–G6 | `Hardness/TensorAction.lean`, `Hardness/Reductions.lean` |
| H2 | MEDIUM | H | H1–H4 | `KEM/CompSecurity.lean` |
| H3 | MEDIUM | J | J1–J3 | docs only |
| M1 | MEDIUM | K | K1–K5 | `Theorems/OIAImpliesCPA.lean`, `KEM/Security.lean`, `Hardness/Reductions.lean`, `Crypto/CompSecurity.lean` |
| M2 | MEDIUM | L1 | L1-WU1–WU3 | `KeyMgmt/SeedKey.lean` |
| M3 | MEDIUM | L2 | L2-WU1–WU3 | `AEAD/CarterWegmanMAC.lean` |
| M4 | MEDIUM | L3 | L3-WU1–WU3 | `PublicKey/ObliviousSampling.lean` |
| M5 | MEDIUM | L4 | L4-WU1–WU2 | `PublicKey/KEMAgreement.lean` |
| M6 | MEDIUM | L5 | L5-WU1–WU5 | `KEM/Security.lean`, `KEM/CompSecurity.lean` |
| L1 | LOW | M (§ 8.1) | M1 | `Hardness/Reductions.lean` |
| L2 | LOW | M (§ 8.2) | M2 | `Probability/Advantage.lean` |
| L3 | LOW | M (§ 8.3) | M3 | `Hardness/Reductions.lean` |
| L4 | LOW | M (§ 8.4) | deferred | — |
| L5 | LOW | M (§ 8.5) | M5 | `Theorems/InvariantAttack.lean` |
| L6 | LOW | M (§ 8.6) | M6 | `Construction/HGOE.lean` |
| L7 | LOW | M (§ 8.7) | M7 | `Probability/Negligible.lean` |
| L8 | LOW | M (§ 8.8) | M8 | `PublicKey/CombineImpossibility.lean` |
| I1 | INFO | N (§ 9.1) | N1-WU1–WU2 | `CLAUDE.md` (or `lakefile.lean`) |
| I2 | INFO | N (§ 9.2) | no action | — |
| I3 | INFO | N (§ 9.3) | no action (post-release) | — |
| I4 | INFO | N (§ 9.4) | no action | — |
| I5 | INFO | N (§ 9.5) | N5 | `.github/workflows/lean4-build.yml` |

## 15. Appendix B — Out-of-scope items (tracked as future work)

The following items are explicitly **out of scope** for this
workstream plan; they are tracked as future work (or were already
tracked in prior plans):

- **F3/F4** (from the 2026-04-18 plan): concrete CFI graph-gadget
  reduction (F3) and Grochow–Qiao structure-tensor encoding (F4).
  These would discharge the `GIReducesToCE` / `GIReducesToTI`
  Karp-claim Props with cryptographically non-degenerate encoders,
  and would allow Workstream G's `SurrogateTensor` to be replaced
  with an encoding-derived surrogate.
- **E8b** (from the 2026-04-18 plan): marginal-independence step for
  `indQCPA_bound_via_hybrid`'s `h_step` hypothesis over
  `uniformPMFTuple`. Would let the multi-query bound be discharged
  from `ConcreteOIA` alone.
- **Probabilistic `ObliviousSamplingHiding`**: the current
  `ObliviousSamplingHiding` is pathological-strength; a
  probabilistic counterpart (analogous to how `ConcreteOIA` upgrades
  `OIA`) is future work.
- **Multi-query KEM-CCA**: the current KEM security chain is
  single-query. Multi-query chosen-ciphertext security is a separate
  milestone.
- **Formal `SeedKey` compression witness** (Workstream L1-b): a
  witnessed inequality `|Seed| ≪ |G|` with concrete instance
  exhibits.

## 16. Signoff

**Plan author.** Claude (Opus 4.7, 1M context).
**Plan date.** 2026-04-21.
**Plan branch.** `claude/audit-workstream-planning-uXM1Q`.
**Source audit.** `docs/audits/LEAN_MODULE_AUDIT_2026-04-21.md`.
**Plan status.** Ready for implementer intake.
**Next action.** Assign Workstream G to an implementer; open tracking
issue per workstream; begin with WU G1 (introduce `SurrogateTensor`).
