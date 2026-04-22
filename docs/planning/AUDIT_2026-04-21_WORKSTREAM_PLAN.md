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
admitting advantage-1 distinguishers. Workstream **G** lands the full
cryptographic-engineering fix: a `SurrogateTensor F` structure binding
`G_TI` as a chain-level parameter (Fix B), **and** a per-encoding
refactor routing the three reduction layers through explicit encoder
witnesses built on `OrbitPreservingEncoding` (Fix C — the
cryptographically cleanest long-term formulation). The resulting chain
is honestly ε-parametric, with every reduction link consuming both
surrogate-specific TI-hardness *and* a named encoding function, so
intermediate ε values carry quantitative content per surrogate / per
encoder. The only items that remain genuine research-scope follow-ups
are the concrete-mathematics formalisations of specific encoders (CFI
graph gadgets, Grochow–Qiao structure tensors) — but their **interface
discharge obligations** are wired up in this workstream, so those
follow-ups will slot into the existing chain without further structural
refactors.

The remaining HIGH-adjacent findings are medium severity: **H2**
(KEM-layer chain through `ConcreteKEMOIA_uniform` is missing),
**H3** (the deterministic OIA family is self-disclosed-vacuous on any
non-trivial scheme — documentation framing only). Medium findings
**M1–M6** are variously small-diff and structurally substantial:
collision-admitting `IsSecure` (M1, small-diff),
uncertified-compression `SeedKey` (M2, **structurally substantial**:
the 2026-04-22 revision of Workstream L1 lands a machine-checked
`compression : Nat.log 2 |Seed| < Nat.log 2 |G|` witness, threading
`[Fintype Seed]` / `[Fintype G]` through every downstream theorem),
unconstrained `carterWegmanMAC p` (M3, small-diff),
misleadingly-named tautology theorems (M4 `RefreshIndependent`,
M5 `SymmetricKeyAgreementLimitation`, small-diff renames), and a
redundant `KEMOIA` conjunct (M6, small-diff). Low and info findings
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
| L4 | LOW | **M** § 8.4 | docstring pointers at Workstream G's per-encoding Props | preferred |
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
| **G** | Hardness-chain non-vacuity: surrogate + per-encoding refactor | H1 | 16h | none |
| **H** | KEM-layer ε-smooth chain via `ConcreteKEMOIA_uniform` | H2 | 4h | **G** |
| **J** | Release-messaging alignment: deterministic-vacuity framing | H3 | 1.5h | **G**, **K** |
| **K** | Distinct-challenge IND-1-CPA corollaries | M1 | 2h | none |
| **L** | Structural + naming hygiene (five sub-items; L1 revised 2026-04-22 to witnessed-compression scope) | M2–M6 | ~10h | none |
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
`OrbitPreservingEncoding`). This plan adopts **Fix B + Fix C together**
as the single coherent remediation. Rationale:

- **Fix A** (existential over `G_TI`) is semantically equivalent to
  Fix B but requires nested existentials over typeclass instances,
  which Lean 4 elaboration handles poorly. Under-the-hood, Lean
  encodes such existentials via `PSigma`/`Nonempty` bundles — i.e.,
  exactly the structure Fix B uses explicitly. Fix B is therefore the
  Lean-native form of Fix A.
- **Fix B** (structure-carried `G_TI` via `SurrogateTensor F`) is
  necessary to restrict the PUnit-collapse at the tensor quantifier.
  It is the minimum surgical change required to make
  `UniversalConcreteTensorOIA` honestly ε-parametric.
- **Fix C** (route through `OrbitPreservingEncoding`) is the
  cryptographically cleanest long-term formulation: the three reduction
  Props carry concrete encoders `enc : α → β` as parameters and state
  hardness transfer per-encoding, rather than the universal-over-all-
  instances shape that hides the reduction's encoding-specific
  structure. `Orbcrypt/Hardness/Encoding.lean` already exposes the
  `OrbitPreservingEncoding` interface but no Prop consumes it; Fix C
  promotes the interface to an actively-consumed structural
  parameter of `ConcreteHardnessChain`.

**Adopted approach: land Fix B and Fix C together.** Previous drafts of
this plan deferred Fix C to future work on the grounds of being a
"larger refactor", which constitutes unacceptable deferral of
architecturally important work. The refactor touches one module
(`Hardness/Reductions.lean`) plus small adjustments to
`Hardness/TensorAction.lean` and `Hardness/Encoding.lean`; it is
within workstream scope and is landed here.

**What is genuinely out-of-scope research.** The *concrete-mathematics
discharge* of specific reduction Props — specifically, providing a
provable `OrbitPreservingEncoding` witness for the CFI graph gadget
(Cai-Fürer-Immerman 1992) or the Grochow–Qiao structure-tensor encoding
(2021) — requires formalising multi-page research-paper constructions
in Lean. That formalisation is a separate research effort tracked as a
**research follow-up** (not a deferred engineering task). Workstream G's
scope is the **interface** that those formalisations will populate,
plus satisfiability witnesses at ε = 1 that exercise the full chain.

### 3.3 Target API shape (post-fix)

**Fix B — `SurrogateTensor F` parameter.**

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
```

**Fix C — Per-encoding reduction Props.**

Each reduction Prop takes a concrete encoder as an argument and
asserts hardness transfer through that encoder on explicit instances.
The universal-over-all-instances shape is **derivable** but no longer
primary; the primary form names the encoding.

```lean
-- Per-encoding Tensor → CE reduction. `enc : Tensor3 n F → Finset (Fin m → F)`
-- is the encoder; `εT εC : ℝ` the source/target advantage bounds.
def ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding
    {F : Type*} [Fintype F] [DecidableEq F]
    (S : SurrogateTensor F) {n m : ℕ}
    (enc : Tensor3 n F → Finset (Fin m → F))
    (εT εC : ℝ) : Prop :=
  ∀ (T₀ T₁ : Tensor3 n F),
    ConcreteTensorOIA (G_TI := S.carrier) T₀ T₁ εT →
    ConcreteCEOIA (enc T₀) (enc T₁) εC

-- Per-encoding CE → GI reduction.
def ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding
    {F : Type*} [DecidableEq F] {m k : ℕ}
    (enc : Finset (Fin m → F) → (Fin k → Fin k → Bool))
    (εC εG : ℝ) : Prop :=
  ∀ (C₀ C₁ : Finset (Fin m → F)),
    ConcreteCEOIA C₀ C₁ εC →
    @ConcreteGIOIA k (enc C₀) (enc C₁) εG

-- Per-encoding GI → scheme-OIA reduction. The hypothesis is the
-- *chain-image* GI hardness — universal over the graphs produced by
-- composing `encCG ∘ encTC` on any tensor pair — rather than universal
-- GI hardness over every adjacency pair. This makes the chain close
-- compositionally without a coverage obligation: whatever GI pairs the
-- upstream links produce is precisely what the GI → scheme link
-- consumes.
def ConcreteGIOIAImpliesConcreteOIA_viaEncoding
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    {F : Type*} [DecidableEq F]
    {nT mC kG : ℕ}
    (encTC : Tensor3 nT F → Finset (Fin mC → F))
    (encCG : Finset (Fin mC → F) → (Fin kG → Fin kG → Bool))
    (εG ε : ℝ) : Prop :=
  (∀ T₀ T₁ : Tensor3 nT F,
      @ConcreteGIOIA kG (encCG (encTC T₀)) (encCG (encTC T₁)) εG) →
    ConcreteOIA scheme ε
```

**Fix B + Fix C — Encoder-carrying `ConcreteHardnessChain`.**

```lean
-- ConcreteHardnessChain now binds both the surrogate (Fix B) and the
-- three per-encoding Props plus encoder functions (Fix C). Every link
-- is an explicit named function, and every hardness-transfer Prop
-- names that function.
structure ConcreteHardnessChain
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (F : Type*) [Fintype F] [DecidableEq F]
    (S : SurrogateTensor F)   -- Fix B: surrogate parameter
    (ε : ℝ) where
  /-- Tensor dimension on which the chain's tensor layer operates. -/
  nT : ℕ
  /-- Code length on which the chain's CE layer operates. -/
  mC : ℕ
  /-- Graph vertex count on which the chain's GI layer operates. -/
  kG : ℕ
  /-- Tensor → Code encoder (Fix C). -/
  encTC : Tensor3 nT F → Finset (Fin mC → F)
  /-- Code → Graph encoder (Fix C). -/
  encCG : Finset (Fin mC → F) → (Fin kG → Fin kG → Bool)
  /-- Tensor-layer advantage bound. -/
  εT : ℝ
  /-- Code-layer advantage bound. -/
  εC : ℝ
  /-- Graph-layer advantage bound. -/
  εG : ℝ
  /-- Universal TI-hardness at surrogate S and bound εT. -/
  tensor_hard : UniversalConcreteTensorOIA S εT
  /-- Per-encoding Tensor → CE reduction at encoder `encTC`. -/
  tensor_to_ce :
    ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding S encTC εT εC
  /-- Per-encoding CE → GI reduction at encoder `encCG`. -/
  ce_to_gi : ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding encCG εC εG
  /-- Per-encoding GI → scheme-OIA reduction consuming the chain-image
      hardness through `encTC` and `encCG` (no separate `getAdj`
      encoder — the scheme-level reduction closes through the
      composition `encCG ∘ encTC`, which is what makes the chain
      compositional without a coverage obligation). -/
  gi_to_oia :
    ConcreteGIOIAImpliesConcreteOIA_viaEncoding scheme encTC encCG εG ε
```

**Derived corollaries.** The original universal→universal Props
(`ConcreteTensorOIAImpliesConcreteCEOIA`, etc.) are retained as
corollaries, because downstream audit scripts may still reference them
for the "universal-over-all-instances" sanity-check form. Each is
derived by abstracting over the per-encoding form at a specific
encoder family.

**Satisfiability witness at ε = 1.** `ConcreteHardnessChain.tight_one_exists`
instantiates the chain at ε = 1 with:
* `nT = mC = kG = 0` (degenerate dimensions — empty tensors/codes/graphs),
* trivial encoders (any total function into the dimension-0 types works,
  e.g. constant functions),
* `S := punitSurrogate` (the explicit PUnit surrogate witness),
* Each reduction Prop at (1, 1) is trivially satisfied because
  `ConcreteCEOIA _ _ 1`, `ConcreteGIOIA _ _ 1`, `ConcreteOIA _ 1` are
  all true via `advantage_le_one`.

**Cryptographic interpretation.** Any *production* use of the chain
instantiates `S`, `encTC`, `encCG` with cryptographically meaningful
witnesses — concrete finite surrogates for GL³(F), and concrete
encoders from the research literature (CFI gadget, Grochow-Qiao
structure tensor). When those witnesses land, the chain's ε bound
reflects their actual hardness properties.

### 3.4 Work units

Each work unit is atomic (one to three commits) and has a concrete
acceptance test. Ordering is sequential unless noted.

**Workstream G has eight work units** (G1–G8). Units G1–G2 land
Fix B (surrogate binding); G3a–G3c land Fix C's per-encoding Props;
G4–G5 land the encoder-carrying chain structure and composition
theorem; G6 provides the non-vacuity witness; G7 updates audit
scripts; G8 updates documentation.

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

#### G3a — Define per-encoding Tensor → CE reduction Prop (Fix C)

**File.** `Orbcrypt/Hardness/Reductions.lean`, in the
`ConcreteReductions` section alongside the universal forms.

**Change.** Add `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`
as defined in § 3.3. The Prop takes a `SurrogateTensor F`, an explicit
encoder `enc : Tensor3 n F → Finset (Fin m → F)`, and the two advantage
bounds. It asserts: for every tensor pair, if they satisfy
`ConcreteTensorOIA` at `εT` under the surrogate, then their encoded
codes satisfy `ConcreteCEOIA` at `εC`.

Also provide a `_one_one` satisfiability witness (trivially true
because `ConcreteCEOIA _ _ 1` holds unconditionally).

**Acceptance.**
- `lake build Orbcrypt.Hardness.Reductions` succeeds.
- `#check @ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding` shows
  the surrogate and encoder as explicit parameters.
- `concreteTensorOIAImpliesConcreteCEOIA_viaEncoding_one_one` is an
  inhabited value of the `(1, 1)` form for any encoder.

#### G3b — Define per-encoding CE → GI reduction Prop (Fix C)

**File.** `Orbcrypt/Hardness/Reductions.lean`, in the
`ConcreteReductions` section.

**Change.** Add `ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding` as
defined in § 3.3. Encoder is
`enc : Finset (Fin m → F) → (Fin k → Fin k → Bool)`. Provide a
`_one_one` witness.

**Acceptance.**
- `lake build Orbcrypt.Hardness.Reductions` succeeds.
- `#check @ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding` confirms
  the encoder parameter.

#### G3c — Define per-encoding GI → scheme-OIA reduction Prop (Fix C)

**File.** `Orbcrypt/Hardness/Reductions.lean`, in the
`ConcreteReductions` section.

**Change.** Add `ConcreteGIOIAImpliesConcreteOIA_viaEncoding` as
defined in § 3.3. Unlike the Tensor→CE and CE→GI links which carry a
single encoder function, this Prop takes **the chain's two upstream
encoders** (`encTC : Tensor3 nT F → Finset (Fin mC → F)` and
`encCG : Finset (Fin mC → F) → (Fin kG → Fin kG → Bool)`) so that the
hypothesis is universal over the chain image, not over arbitrary
scheme messages. That is what makes composition close without a
coverage obligation on a separate message-to-graph encoder. Provide a
`_one_one` witness.

**Acceptance.**
- `lake build Orbcrypt.Hardness.Reductions` succeeds.
- `#check @ConcreteGIOIAImpliesConcreteOIA_viaEncoding` confirms the
  scheme, `encTC`, and `encCG` parameters.

#### G4 — Refactor `ConcreteHardnessChain` to carry encoders + surrogate

**File.** `Orbcrypt/Hardness/Reductions.lean`, in the
`ConcreteHardnessChainSection`.

**Change.**
1. Add `(S : SurrogateTensor F)` as a structure parameter.
2. Add encoder fields `nT, mC, kG, encTC, encCG` as defined
   in § 3.3. (There is intentionally no `getAdj` field — the final
   GI → scheme-OIA link is universal over the chain image produced
   by composing `encCG ∘ encTC`, not over messages.)
3. Retype `tensor_hard` to `UniversalConcreteTensorOIA S εT`.
4. Retype `tensor_to_ce` to
   `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding S encTC εT εC`.
5. Retype `ce_to_gi` to
   `ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding encCG εC εG`.
6. Retype `gi_to_oia` to
   `ConcreteGIOIAImpliesConcreteOIA_viaEncoding scheme encTC encCG εG ε`.

**Acceptance.**
- `lake build Orbcrypt.Hardness.Reductions` succeeds.
- `#check @ConcreteHardnessChain` confirms the surrogate, encoders,
  and per-encoding Props are all part of the structure shape.

**Regression safeguard.** The existing universal→universal reduction
Props remain in the module as derived corollaries (not deleted) so
audit scripts may still reference them. The old `ConcreteHardnessChain`
shape is replaced (per CLAUDE.md's no-backwards-compat-shim rule);
downstream audit scripts are updated in G7.

#### G5 — Update chain-composition lemmas

**File.** `Orbcrypt/Hardness/Reductions.lean`.

**Change.**
1. `concreteOIA_from_chain` — body threads tensor hardness through the
   three per-encoding reduction Props. The proof picks tensor
   witnesses, applies each per-encoding Prop to transport hardness
   layer by layer, then delivers `ConcreteOIA scheme ε`. Because the
   per-encoding Props quantify over **all** tensor / code / graph
   pairs (not just those in the encoder image), composition preserves
   the universal shape through each link.
2. `ConcreteHardnessChain.tight` — signature gains dimension/encoder
   parameters; body unchanged modulo parameter threading.
3. `concrete_chain_zero_compose` — updated to exercise the per-encoding
   chain at ε = 0. The hypothesis now takes the three per-encoding
   Props at 0 and a universal tensor hardness at 0.
4. `concrete_hardness_chain_implies_1cpa_advantage_bound` — composes
   `concreteOIA_from_chain` with `concrete_oia_implies_1cpa`.

**Acceptance.**
- `lake build Orbcrypt.Hardness.Reductions` succeeds.
- `#print axioms concrete_hardness_chain_implies_1cpa_advantage_bound`
  emits only `[propext, Classical.choice, Quot.sound]`.

#### G6 — Non-vacuity witnesses: `tight_one_exists`

**File.** `Orbcrypt/Hardness/Reductions.lean`.

**Change.** `tight_one_exists` constructs a `ConcreteHardnessChain scheme
F punitSurrogate 1` by picking:
* `punitSurrogate := { carrier := PUnit, action := fun _ => inferInstance }`,
* `nT := 0, mC := 0, kG := 0`,
* `encTC`, `encCG` as arbitrary total functions (the source/target
  types at dimension 0 are inhabited — `Tensor3 0 F = Fin 0 → Fin 0 →
  Fin 0 → F` is `PUnit`-like, `Finset (Fin 0 → F) = {∅, {fun k =>
  absurd k.elim0}}` is inhabited, adjacency matrices at 0 vertices are
  `PUnit`),
* Each reduction Prop at (1, 1) discharged via the `_one_one` witnesses
  from G3a–c.

This is a complete satisfiability witness demonstrating the chain is
non-vacuous; at `ε = 1` every Prop is trivially true via
`advantage_le_one`.

**Acceptance.**
- `tight_one_exists` returns `Nonempty (ConcreteHardnessChain scheme F
  punitSurrogate 1)` for any scheme and field type `F`.
- `#print axioms` on the new declarations emits only the standard trio.

#### G7 — Update audit scripts

**Files.** `scripts/audit_phase_16.lean`, `scripts/audit_e_workstream.lean`.

**Change.**
1. Add `#print axioms` entries for the three new per-encoding reduction
   Props (`_viaEncoding` forms) and their `_one_one` witnesses.
2. Concrete `example` bindings in `audit_e_workstream.lean` must
   supply a surrogate and encoders. Adjust the existing
   `ConcreteHardnessChain` example to thread through `punitSurrogate`
   and the trivial-at-dimension-0 encoders.
3. New `example`s (Workstream G satisfiability): exhibit a
   `ConcreteHardnessChain toyScheme Bool punitSurrogate 1` and extract
   `ConcreteOIA toyScheme 1` via `concreteOIA_from_chain`.

**Acceptance.**
- `lake env lean scripts/audit_phase_16.lean` produces no `sorryAx`,
  no non-standard-trio axioms, and all referenced declarations are
  found (new names: `SurrogateTensor`,
  `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`,
  `ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding`,
  `ConcreteGIOIAImpliesConcreteOIA_viaEncoding`).
- `lake env lean scripts/audit_e_workstream.lean` produces all
  expected examples and no errors.

#### G8 — Update root transparency report & CLAUDE.md

**Files.** `Orbcrypt.lean` (axiom-transparency report section),
`CLAUDE.md` (headline-theorem table + codebase-status section),
`docs/VERIFICATION_REPORT.md`.

**Change.**
1. In `Orbcrypt.lean`, update the "Workstream E4 — `ConcreteHardnessChain`"
   entry: "Chain now carries a `SurrogateTensor F` parameter and two
   explicit encoder fields (`encTC`, `encCG`) plus three per-encoding
   reduction Props (audit F-AUDIT-2026-04-21-H1, Workstream G, Fix B +
   Fix C). Non-vacuous at ε = 1 for the PUnit surrogate via
   `tight_one_exists`; for any caller-supplied surrogate and encoder
   pair, the chain's ε bound reflects genuine hardness. The final
   GI → scheme-OIA reduction Prop consumes the chain-image hardness
   through the composition `encCG ∘ encTC` — no separate
   message-to-graph encoder is needed."
2. In `CLAUDE.md`'s headline theorem table, update the row for the
   hardness chain to reflect the surrogate + encoder parameters.
   Add a Workstream G codebase-status entry at the end of the audit
   log mirroring the precedent used for Workstreams A–E.
3. In `docs/VERIFICATION_REPORT.md`, update "Known limitations": "At
   ε < 1 the chain is non-vacuous if and only if the caller supplies
   (a) a surrogate whose TI-hardness is genuinely εT-bounded and (b)
   encoder witnesses whose per-encoding reduction Props hold at the
   claimed ε-values. The PUnit surrogate + trivial encoders remain a
   satisfiability witness at ε = 1."

**Acceptance.**
- No CI red on docstring checks.
- `scripts/audit_phase_16.lean` still passes.
- `CLAUDE.md`'s codebase status section records Workstream G as
  complete with a link to this plan.

### 3.5 Risks and mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `SurrogateTensor` instance-bundling syntax clashes with existing typeclass search | Medium | Field-based (not typeclass-based) — `[Group S.carrier]` is extracted via `attribute [local instance] S.groupInst` inside the def block that needs it. |
| `ConcreteTensorOIA (G_TI := S.carrier)` fails to elaborate because of instance ordering | Low | Use explicit `@`-threading if necessary; add a `variable` block with `letI` bindings inside the def body. |
| Refactor breaks `audit_e_workstream.lean`'s existing satisfiability tests | Medium | WU **G7** updates the audit script in the same commit as WU **G4**–**G6**; CI runs both. |
| Post-fix, `tight_one_exists` is harder to produce because it needs an explicit surrogate and three encoders | Low | At dimension 0, encoders are trivially defined (constant functions into dimension-0 types); included in the WU **G6** proof body. |
| Per-encoding reduction Props require encoders that may not be trivially constructible for arbitrary dimensions | Low | The per-encoding form is a `Prop`: at ε = 1 the conclusion is always true, so the witness is discharged without needing a non-trivial encoder. Callers who want ε < 1 must supply concrete cryptographically-honest encoders — that's the correct design. |

### 3.6 Exit criteria for Workstream G

All of the following must hold after WUs G1–G8 land:

1. `lake build` for all 38 modules succeeds with exit code 0, zero
   warnings.
2. `grep -rn "sorry" Orbcrypt/ --include="*.lean"` returns empty (via
   the comment-aware CI scan).
3. `grep -rn "^axiom " Orbcrypt/ --include="*.lean"` returns empty.
4. `scripts/audit_phase_16.lean` passes: zero `sorryAx`, zero non-
   standard axioms. New declarations (`SurrogateTensor`,
   `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`,
   `ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding`,
   `ConcreteGIOIAImpliesConcreteOIA_viaEncoding`, and the updated
   `ConcreteHardnessChain` fields) all carry the standard trio.
5. `scripts/audit_e_workstream.lean` passes with the new per-encoding
   examples and surrogate threading.
6. `Orbcrypt.lean`'s transparency report is updated to reflect the
   Fix B + Fix C refactor.
7. `docs/VERIFICATION_REPORT.md` and `CLAUDE.md` document the post-G
   status, including the Workstream G codebase-status entry in
   `CLAUDE.md`.
8. `ConcreteHardnessChain scheme F punitSurrogate 1` is inhabited via
   `tight_one_exists` with the trivial encoder pair; for any
   caller-supplied surrogate `S` and encoders `(encTC, encCG)`, the
   chain's ε bound reflects `S`'s actual TI-hardness AND the encoders'
   per-link advantage transfer — the ε-smoothness is genuinely
   parametric in both.
9. `OrbitPreservingEncoding` is no longer an unused reference-only
   interface; it is either consumed by a per-encoding Prop **or**
   explicitly documented as a higher-level semantic interface
   alternative to the function-valued encoders used by Workstream G.

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

**Decision (revised 2026-04-22).** The plan now adopts option
**(b)** — "witnessed compression" — as the principled resolution.
The earlier preference for option (a) ("honest API") was a
smallest-diff compromise; it leaves the advertised compression claim
as a prose-only assertion with no machine-checkable content.
Under CLAUDE.md's "no half-finished implementations" rule the honest
resolution is to **land the machine-checkable compression witness**
and pay the structural cost: every downstream theorem that carries a
`SeedKey Seed G X` argument must also thread `[Fintype Seed]` and
`[Fintype G]`, and the `OrbitEncScheme.toSeedKey` bridge must carry
a proof that the target group is non-trivial (`1 < Fintype.card G`).

Option **(a)** is vacated; option **(b)** becomes the authoritative
plan for Work Units L1-WU1 through L1-WU6 below.

#### Corrected formulation (was: `8 * Fintype.card Seed < log₂ (...)`)

The original one-line sketch in § 7.1 read

```
compression : 8 * Fintype.card Seed < log₂ (Fintype.card G)
```

This is **dimensionally incorrect**. `Fintype.card Seed` counts the
number of distinct seed values (e.g. `2^256` for a 256-bit seed),
not the number of bits required to encode a seed. The intended
semantics — "the seed occupies fewer bits than a group element
requires to encode" — is captured directly by a **bit-length
comparison** on the two cardinalities:

```lean
compression :
  Nat.log 2 (Fintype.card Seed) < Nat.log 2 (Fintype.card G)
```

For every finite type `T`, `Nat.log 2 (Fintype.card T)` is exactly
`⌊log₂ |T|⌋` — the number of bits needed in the minimum-length
fixed-length encoding of a `T`-valued message (minus one, per Mathlib
convention at powers of two). So `compression` reads "the seed's
bit-length is strictly smaller than the group's bit-length." The
factor of `8` in the original sketch was a bytes→bits unit conversion
that is redundant here because both sides of the inequality are
already expressed in bits.

The revised formulation has four additional virtues over the naive
cardinality comparison `Fintype.card Seed < Fintype.card G`:

1. It matches the prose framing of the module docstring's "Key size
   comparison" table (256 bits vs ~15 M bits), which is a bit-length
   comparison.
2. It is strictly weaker, and therefore easier to discharge for the
   concrete Orbcrypt HGOE instance at λ = 128: we need only
   `Nat.log 2 (2^256) < Nat.log 2 |G|` i.e. `256 < Nat.log 2 |G|`,
   which is a standard group-order bound.
3. It is a *scale-invariant* compression claim: doubling both sides
   by a constant factor leaves the inequality invariant, which is the
   right semantics for "compression ratio."
4. It degrades gracefully to `0 < Nat.log 2 |G|` — i.e. `2 ≤ |G|` —
   on the `Seed = Unit` bridge, which is the weakest possible
   non-triviality hypothesis on `G`.

**Trade-off note.** The alternative formulation
`Fintype.card Seed < Fintype.card G` is mathematically cleaner (no
`Nat.log` machinery) but asserts *elementwise* compression rather
than bit-length compression, and would require a stronger hypothesis
on the bridge (`Fintype.card Unit = 1 < Fintype.card G`, which
happens to coincide here, but the asymmetry grows for non-singleton
`Seed`). We pick the bit-length form because it is the one the
docstring is asserting.

#### L1-WU1 — Introduce `[Fintype Seed]`, `[Fintype G]`, and the `compression` field on `SeedKey`

**Change.** In `Orbcrypt/KeyMgmt/SeedKey.lean`:

```lean
structure SeedKey (Seed : Type*) (G : Type*) (X : Type*)
    [Fintype Seed] [Group G] [Fintype G]
    [MulAction G X] [DecidableEq X] where
  seed : Seed
  expand : Seed → CanonicalForm G X
  sampleGroup : Seed → ℕ → G
  /-- Bit-length compression witness: the seed's minimum bit-length
      is strictly smaller than the group's. -/
  compression :
    Nat.log 2 (Fintype.card Seed) < Nat.log 2 (Fintype.card G)
```

Add the import `Mathlib.Data.Nat.Log` so `Nat.log` is in scope.

**Acceptance.** `lake build Orbcrypt.KeyMgmt.SeedKey` succeeds after
L1-WU2–L1-WU5 are landed jointly (this file's downstream theorems
and bridge cannot compile until they also thread the new typeclasses).

#### L1-WU2 — Thread `[Fintype Seed]` / `[Fintype G]` through every `SeedKey`-consuming theorem

**Change.** Every theorem in `SeedKey.lean` and `Nonce.lean` that
takes a `SeedKey Seed G X` argument must extend its typeclass context:

```lean
-- Before:
theorem seed_kem_correctness [Group G] [MulAction G X] [DecidableEq X]
    (sk : SeedKey Seed G X) ...

-- After:
theorem seed_kem_correctness
    [Fintype Seed] [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (sk : SeedKey Seed G X) ...
```

Target theorems (exhaustive):

* `Orbcrypt/KeyMgmt/SeedKey.lean`:
  `seed_kem_correctness`, `seed_determines_key`, `seed_determines_canon`,
  `toSeedKey_expand`, `toSeedKey_sampleGroup`.
* `Orbcrypt/KeyMgmt/Nonce.lean` (all theorems and defs taking a
  `SeedKey` argument):
  `nonceEncaps`, `nonceEncaps_eq`, `nonceEncaps_fst`, `nonceEncaps_snd`,
  `nonce_encaps_correctness`, `nonce_reuse_deterministic`,
  `distinct_nonces_distinct_elements`, `nonce_reuse_leaks_orbit`,
  `nonceEncaps_mem_orbit`.

**Rationale.** `SeedKey` now takes `[Fintype Seed] [Fintype G]` at the
structure level, so any `sk : SeedKey Seed G X` term inherits those
obligations. Downstream theorems must declare them to construct the
term at all. No proof body changes beyond this signature update.

**Acceptance.** `lake build Orbcrypt.KeyMgmt.SeedKey` and
`lake build Orbcrypt.KeyMgmt.Nonce` both succeed.

#### L1-WU3 — Update the `OrbitEncScheme.toSeedKey` bridge

**Change.** The backward-compat bridge builds a `SeedKey Unit G X`.
`Fintype Unit` is already provided by Mathlib, so we add
`[Fintype G]` plus an explicit non-triviality hypothesis:

```lean
def OrbitEncScheme.toSeedKey
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (sampleG : ℕ → G)
    (hGroupNontrivial : 1 < Fintype.card G) : SeedKey Unit G X where
  seed := ()
  expand := fun () => scheme.canonForm
  sampleGroup := fun () => sampleG
  compression := by
    -- `Fintype.card Unit = 1`, so `Nat.log 2 1 = 0`;
    -- `hGroupNontrivial` gives `2 ≤ Fintype.card G`, so
    -- `0 < Nat.log 2 (Fintype.card G)` by `Nat.log_pos`.
    have hUnit : Nat.log 2 (Fintype.card Unit) = 0 := by
      simp
    rw [hUnit]
    exact Nat.log_pos (by decide) hGroupNontrivial
```

The companion theorems `toSeedKey_expand` and `toSeedKey_sampleGroup`
must thread the new `hGroupNontrivial` through their statements (they
take the bridge's output as input).

**Rationale.** The `Unit`-seed bridge certifies `compression` at the
weakest possible `|G|` hypothesis: `2 ≤ |G|`. Every non-trivial
Orbcrypt deployment satisfies this (|G| is astronomical in practice),
so the hypothesis is free on the critical path.

**Acceptance.** `lake build Orbcrypt.KeyMgmt.SeedKey` succeeds with
the bridge producing a well-typed `SeedKey Unit G X`.

#### L1-WU4 — Rewrite the module docstring to reflect the witnessed compression

**Change.** Replace the "Key size comparison" table in
`Orbcrypt/KeyMgmt/SeedKey.lean` with a self-contained explanation of
the `compression` field:

```text
## Compression semantics

The `compression` field on `SeedKey` formally witnesses a bit-length
strict inequality between the seed space and the group:

    Nat.log 2 (Fintype.card Seed) < Nat.log 2 (Fintype.card G)

Read: "the number of bits required to encode a seed is strictly less
than the number of bits required to encode a group element."

### Key size comparison (with `compression` certifying the inequality)

| Representation | Size (λ = 128) | Bit-length source |
|----------------|---------------|-------------------|
| Full SGS       | ~1.8 MB (~15 M bits) | `Nat.log 2 \|G\|`  |
| Seed key       | 256 bits       | `Nat.log 2 \|Seed\|` |
| Compression    | field-certified | `compression` field |

At λ = 128 the GAP HGOE implementation uses `Seed = Fin 256 → Bool`
(256 bits) and `|G|` a subgroup of `S_n` of order ≥ 2¹²⁸. The
bit-length witness `256 < Nat.log 2 |G|` is discharged by the
concrete group-order bound.

### Why a witness, not just prose

Landing `compression` as a structure field makes the "compression
ratio" claim a first-class, machine-checked obligation on every
`SeedKey` instance, not an untracked prose assertion in this file.
A concrete consumer (the GAP harness) cannot inhabit a `SeedKey`
whose seed space is larger than the group — a class of sloppy
deployments the pre-L1 API tacitly allowed.
```

**Acceptance.** Manual review + module docstring lint.

#### L1-WU5 — Tighten the `seed_determines_*` docstrings

**Change.** Reword the docstrings to reflect the theorems' actual
content: "given equal seeds *and* equal expansion/sampling functions,
outputs agree by pointwise rewrite." Note that these are structural
rewrite lemmas, not constraints on the seed-to-key relationship.
Unlike the `compression` field, `seed_determines_*` is a
decomposition identity, not a security guarantee.

**Acceptance.** Manual review.

#### L1-WU6 — Update audit scripts and transparency report

**Files.** `scripts/audit_phase_16.lean`,
`scripts/audit_print_axioms.lean`, `Orbcrypt.lean`.

**Change.**
1. The `#print axioms SeedKey` output now includes
   `Fintype.card` via `Nat.log`'s standard dependencies; verify the
   axiom set remains the standard trio (`propext`, `Classical.choice`,
   `Quot.sound`).
2. Add a non-vacuity witness in
   `scripts/audit_phase_16.lean`'s `NonVacuityWitnesses` namespace:
   build a concrete `SeedKey (Fin 2) (Equiv.Perm (Fin 2)) Unit` with
   `compression` discharged by `decide`, confirming the witness is
   exercisable.
3. Extend the `Orbcrypt.lean` axiom-transparency report with a
   Workstream-L1 snapshot describing the bit-length compression
   witness.

**Acceptance.** `lake env lean scripts/audit_phase_16.lean` succeeds
with the new witness; axiom-set whitelist unchanged.

#### L1-WU7 — Update CLAUDE.md change log

**File.** `CLAUDE.md`.

**Change.** Append a Workstream-L1 entry under the development-status
block following the Workstream-K precedent. Describe the signature
changes, the corrected formulation, and the non-vacuity witness.
Note that the previously-tracked "post-release Workstream L1-b"
follow-up is subsumed by this workstream — the witness has landed.

#### Implementation order (dependency graph)

L1-WU1 (structure change) → L1-WU2 (downstream signatures) →
L1-WU3 (bridge) → L1-WU5 (docstrings) → L1-WU4 (module docstring) →
L1-WU6 (audit scripts) → L1-WU7 (CLAUDE.md).

L1-WU1 alone breaks the build until L1-WU2 and L1-WU3 land, so these
three must be kept in a single commit. L1-WU4–WU7 are additive and
can land in separate commits if desired.

#### Acceptance for L1 as a whole

1. `lake build` succeeds for every module (zero warnings, zero
   errors).
2. `scripts/audit_phase_16.lean` runs clean: standard-trio axioms
   only on every Workstream-L1 declaration; non-vacuity witness
   elaborates on a concrete instance.
3. `grep -rn "sorry" Orbcrypt/KeyMgmt/` returns empty.
4. Every theorem in `SeedKey.lean` and `Nonce.lean` carries
   `[Fintype Seed]` and `[Fintype G]` in its typeclass context.
5. The `OrbitEncScheme.toSeedKey` bridge requires and consumes an
   explicit `1 < Fintype.card G` hypothesis.
6. The module docstring's "Key size comparison" section cites the
   `compression` field as the machine-checked witness.

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

### 8.4 M4 — Degenerate encoders in deterministic `GIReducesToCE` / `GIReducesToTI` (L4)

**File.** `Orbcrypt/Hardness/CodeEquivalence.lean`,
`Orbcrypt/Hardness/TensorAction.lean` (docstrings only).

**Action.** `GIReducesToCE` / `GIReducesToTI` are the
**deterministic** reduction Props (distinct from Workstream G's
probabilistic per-encoding Props). They admit degenerate encoders
like `encode _ := ∅` because they state the reduction at the
orbit-equivalence level (not at the advantage level). This is an
intentional design: they are *scaffolding* Props expressing
existence of a Karp reduction, paired with external documentation
of which reductions are believed to exist in the research
literature.

The **probabilistic** counterparts (added by Workstream G:
`ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding` and
`ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`) *also* admit
trivial witnesses at ε = 1, but their structure forces callers to
supply concrete encoders at ε < 1.

Research-scope discharges (concrete CFI / Grochow–Qiao
formalisations) plug into both the deterministic and probabilistic
interfaces — see § 15.1 for details.

**Change.** Add a one-paragraph note to `GIReducesToCE` /
`GIReducesToTI` docstrings pointing callers at the Workstream G
per-encoding Props as the place where quantitative hardness actually
transfers.

**Acceptance.** Docstring-only; `lake build` unchanged.

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

Workstream G has expanded from 6 WUs (Fix B only) to 8 WUs (Fix B +
Fix C) to land the per-encoding refactor; the total estimate is now
≈ 16h (2 working days, down-revised from a pessimistic 3).

| Day | Morning | Afternoon |
|-----|---------|-----------|
| 1 | WU G1 + G2 (surrogate + universal-form refactor) | WU G3a + G3b + G3c (per-encoding reduction Props) |
| 2 | WU G4 + G5 (encoder-carrying chain + composition) | WU G6 + G7 + G8 (non-vacuity + audit + docs) |
| 3 | WU K1 + K3 + K5 (distinct-challenge corollaries) | WU H1 + H2 + H3 (KEM-layer chain) |
| 4 | WU H4 + WU J1 + J2 + J3 (docs) | WU L1 + L5 (SeedKey + KEMOIA hygiene) |
| 5 | WU L2 + L3 + L4 (naming) + WU M1–M8 (polish) | Final CI pass + release-readiness check |

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

**Post-workstream extensions.** After Workstream G merges, add new
audit script entries in `scripts/audit_phase_16.lean`:

```text
#print axioms SurrogateTensor          -- Fix B: surrogate structure
#print axioms ConcreteHardnessChain    -- surrogate + encoder fields
#print axioms UniversalConcreteTensorOIA
#print axioms ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding  -- Fix C
#print axioms ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding      -- Fix C
#print axioms ConcreteGIOIAImpliesConcreteOIA_viaEncoding        -- Fix C
```

All should emit standard-trio axioms only.

### 11.2 Per-workstream satisfiability witnesses

Each workstream that modifies a structural predicate ships an
`example` in the relevant audit script confirming non-vacuity:

- **G**: `ConcreteHardnessChain toyScheme Bool punitSurrogate 1` is
  inhabitable (via `tight_one_exists`) with trivial encoder pair
  `(encTC, encCG)`; all three per-encoding reduction Props are
  exercised at ε = 1. (The final GI → scheme-OIA reduction threads
  through the composition `encCG ∘ encTC`; there is no separate
  `getAdj` encoder.)
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

Workstream G modifies the signature of `ConcreteHardnessChain`
(adds `SurrogateTensor` parameter, three encoder fields, three
dimension fields), `UniversalConcreteTensorOIA` (adds `SurrogateTensor`
parameter), and `concrete_hardness_chain_implies_1cpa_advantage_bound`
(threads the new parameters through `hc`). Baseline `#print` outputs in
`scripts/audit_phase_16.lean` and `scripts/audit_e_workstream.lean`
change accordingly; the CI's axiom-set whitelist remains identical.

Workstream G also adds three new declarations to the audit script:
`ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`,
`ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding`,
`ConcreteGIOIAImpliesConcreteOIA_viaEncoding`, plus their `_one_one`
satisfiability witnesses. Each must emit standard-trio axioms only.

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
      parameter plus two encoder fields (`encTC`, `encCG`) and three
      per-encoding reduction Props; `tight_one_exists` witnesses
      inhabitation at ε = 1 with the PUnit surrogate + trivial
      encoders; `concrete_hardness_chain_implies_1cpa_advantage_bound`
      delivers a quantitatively meaningful bound for any
      caller-supplied surrogate and encoder pair.
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

Research follow-ups (see § 15 — these are *not* deferred engineering
tasks; the interfaces they discharge are landed by this plan):

- [ ] Concrete CFI graph gadget discharge of
      `ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding` (replaces
      the ε = 1 witness with an ε < 1 encoding).
- [ ] Concrete Grochow–Qiao structure-tensor discharge of
      `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`.
- [ ] Concrete CFI-indexed `OrbitEncScheme` discharge of
      `ConcreteGIOIAImpliesConcreteOIA_viaEncoding` — the Prop
      consumes chain-image GI hardness (adjacency matrices produced
      by `encCG ∘ encTC`); the concrete discharge therefore embeds
      the CFI graph family into the scheme's orbit structure.

Optional post-release engineering:

- [ ] ~~Workstream L1-b: formal compression-ratio witness on `SeedKey`
      via `[Fintype Seed]` + inequality proof.~~ **Subsumed by the
      revised Workstream L1 (2026-04-22): the `compression` field
      now lives on `SeedKey` directly.**
- [ ] E8b: discharge `h_step` in `indQCPA_bound_via_hybrid` from a
      single-query `ConcreteOIA` (marginal-independence step).

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
| H1 (AUDIT-2026-04-21-H1) | HIGH | G | G1–G8 | `Hardness/TensorAction.lean`, `Hardness/Reductions.lean`, `Hardness/Encoding.lean` |
| H2 | MEDIUM | H | H1–H4 | `KEM/CompSecurity.lean` |
| H3 | MEDIUM | J | J1–J3 | docs only |
| M1 | MEDIUM | K | K1–K5 | `Theorems/OIAImpliesCPA.lean`, `KEM/Security.lean`, `Hardness/Reductions.lean`, `Crypto/CompSecurity.lean` |
| M2 | MEDIUM | L1 | L1-WU1–WU7 | `KeyMgmt/SeedKey.lean`, `KeyMgmt/Nonce.lean` |
| M3 | MEDIUM | L2 | L2-WU1–WU3 | `AEAD/CarterWegmanMAC.lean` |
| M4 | MEDIUM | L3 | L3-WU1–WU3 | `PublicKey/ObliviousSampling.lean` |
| M5 | MEDIUM | L4 | L4-WU1–WU2 | `PublicKey/KEMAgreement.lean` |
| M6 | MEDIUM | L5 | L5-WU1–WU5 | `KEM/Security.lean`, `KEM/CompSecurity.lean` |
| L1 | LOW | M (§ 8.1) | M1 | `Hardness/Reductions.lean` |
| L2 | LOW | M (§ 8.2) | M2 | `Probability/Advantage.lean` |
| L3 | LOW | M (§ 8.3) | M3 | `Hardness/Reductions.lean` |
| L4 | LOW | M (§ 8.4) | M4 | `Hardness/CodeEquivalence.lean`, `Hardness/TensorAction.lean` (docstrings) |
| L5 | LOW | M (§ 8.5) | M5 | `Theorems/InvariantAttack.lean` |
| L6 | LOW | M (§ 8.6) | M6 | `Construction/HGOE.lean` |
| L7 | LOW | M (§ 8.7) | M7 | `Probability/Negligible.lean` |
| L8 | LOW | M (§ 8.8) | M8 | `PublicKey/CombineImpossibility.lean` |
| I1 | INFO | N (§ 9.1) | N1-WU1–WU2 | `CLAUDE.md` (or `lakefile.lean`) |
| I2 | INFO | N (§ 9.2) | no action | — |
| I3 | INFO | N (§ 9.3) | no action (post-release) | — |
| I4 | INFO | N (§ 9.4) | no action | — |
| I5 | INFO | N (§ 9.5) | N5 | `.github/workflows/lean4-build.yml` |

## 15. Appendix B — Research-scope follow-ups (not engineering deferrals)

The following items are **research-scope** items that are explicitly
**not deferred engineering tasks** — they require formalising
mathematics from research papers (multi-page proofs of combinatorial or
algebraic constructions) in Lean. Each is a separate research milestone
whose *interface obligation* is satisfied by this workstream plan or
its predecessors.

**Terminology.** "Out-of-scope research" ≠ "deferred work". The
distinction:
* *Deferred work* is engineering that was pushed to later milestones
  for scope reasons — this is forbidden by the user's "no deferral"
  policy and the CLAUDE.md "no half-finished implementations"
  directive.
* *Research-scope work* is a separate research effort (typically
  multi-month formalisation) whose interface is already in place but
  whose content is a concrete-mathematics discharge of an existing
  Prop. These items are listed here for transparency, not as
  commitments or promises.

### 15.1 Concrete Karp-encoding discharges

The three per-encoding reduction Props added by Workstream G/Fix C are
satisfied trivially at ε = 1 (the conclusion is `ConcreteCEOIA _ _ 1`
etc., which is always true). Non-vacuous ε < 1 discharges require
concrete encoder witnesses:

- **CFI graph gadget** (Cai-Fürer-Immerman 1992). Discharges a
  `ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding` instance with
  `εC = εG`. Formalising the gadget construction and its
  orbit-preservation properties is a multi-week Lean effort.
- **Grochow–Qiao structure-tensor encoding** (2021). Discharges a
  `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding` instance with
  `εT = εC`. Formalising the encoding requires structure-tensor
  algebra from the cited paper.
- **CFI-based GI → scheme-OIA encoder.** Discharges
  `ConcreteGIOIAImpliesConcreteOIA_viaEncoding` with a CFI-indexed
  scheme; the encoding maps graph adjacency matrices to HGOE code
  representatives.

**Interface discharge obligation satisfied.** Each of these
research-scope efforts plugs into an existing per-encoding Prop
(landed by Workstream G). No further structural refactor of
`ConcreteHardnessChain` is required when they land — they just
instantiate the encoder fields and the per-encoding Props with
their research content.

### 15.2 Probabilistic-game refinements (research)

- **E8b** (from the 2026-04-18 plan): marginal-independence step for
  `indQCPA_bound_via_hybrid`'s `h_step` hypothesis over
  `uniformPMFTuple`. Would let the multi-query bound be discharged
  from `ConcreteOIA` alone.
- **Probabilistic `ObliviousSamplingHiding`**: the current
  `ObliviousSamplingHiding` is pathological-strength; a
  probabilistic counterpart (analogous to how `ConcreteOIA` upgrades
  `OIA`) is a research task.
- **Multi-query KEM-CCA**: the current KEM security chain is
  single-query. Multi-query chosen-ciphertext security is a separate
  milestone requiring fresh game-hopping infrastructure.

### 15.3 Optional engineering follow-ups

These items are smaller in scope and could conceivably be folded into
future audit workstreams, but are not covered by the 2026-04-21 audit
findings:

- ~~**Formal `SeedKey` compression witness** (Workstream L1-b): a
  witnessed inequality `|Seed| ≪ |G|` with concrete instance
  exhibits. Listed in CLAUDE.md as L1-b tracking.~~
  **Resolved by the revised Workstream L1 (2026-04-22):** the
  `compression : Nat.log 2 (Fintype.card Seed) < Nat.log 2
  (Fintype.card G)` field is now part of `SeedKey`, with a
  non-vacuity witness exhibited in `scripts/audit_phase_16.lean`.

## 16. Signoff

**Plan author.** Claude (Opus 4.7, 1M context).
**Plan date.** 2026-04-21.
**Plan branch.** `claude/audit-workstream-planning-uXM1Q`.
**Source audit.** `docs/audits/LEAN_MODULE_AUDIT_2026-04-21.md`.
**Plan status.** Ready for implementer intake.
**Next action.** Assign Workstream G to an implementer; open tracking
issue per workstream; begin with WU G1 (introduce `SurrogateTensor`).
