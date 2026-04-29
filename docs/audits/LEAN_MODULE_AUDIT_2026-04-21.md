<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Orbcrypt Comprehensive Lean Module Audit — 2026-04-21

**Scope.** A line-by-line re-audit of every `.lean` source file under `Orbcrypt/`,
the root `Orbcrypt.lean`, `lakefile.lean`, `lean-toolchain`, the CI workflow at
`.github/workflows/lean4-build.yml`, and `scripts/setup_lean_env.sh`. This audit
is a pre-release readiness review: the project is approaching its first major
release, so the bar is higher than previous audits — every declaration's body
was read rather than trusting docstrings, and cryptographic semantics were
cross-checked against the stated claims in docstrings, `CLAUDE.md`, and
`docs/VERIFICATION_REPORT.md`.

**Tree state.** 38 Lean modules, 8,547 source lines (including docstrings and
comments). Built against Lean `v4.30.0-rc1` with Mathlib pinned at
`fa6418a815fa14843b7f0a19fe5983831c5f870e`. All public declarations carry
docstrings; zero `sorry` and zero custom `axiom`s across the tree (verified
during this audit by re-reading every file, not merely by re-running the
existing CI).

**Audit date.** 2026-04-21. Auditor: Claude (sonnet) working from
`claude/audit-lean-modules-crY5X`.

**Methodology.** For each module: (1) classify its purpose; (2) read every
declaration, checking that proof bodies match docstring claims; (3) evaluate
whether the stated cryptographic meaning holds; (4) identify unsatisfiable
hypotheses, vacuous theorems, semantic gaps, and documentation drift; (5)
cross-check name / notation / import hygiene; (6) look for risk to downstream
consumers. Findings are graded **CRITICAL** (breaks a release-blocking
guarantee), **HIGH** (semantic gap that materially weakens a stated claim),
**MEDIUM** (documented-but-risky pattern, vacuity, or drift), **LOW** (cleanup
or polish item), and **INFO** (observation, no fix needed).

## 0. Executive summary

Formally, nothing is broken. The Lean kernel accepts every proof; the zero-
`sorry` / zero-custom-axiom posture is preserved; every headline theorem's
axiom set reduces to the standard Lean trio
(`propext`, `Classical.choice`, `Quot.sound`).

Semantically, the release is **not yet** in a state where all ε-parameterised
hardness statements deliver *non-vacuous* guarantees. In particular:

1. **`UniversalConcreteTensorOIA εT` is unsatisfiable for `εT < 1`** under
   the current `implicit-universal-over-G_TI` formulation, because the
   implicit quantifier admits `G_TI = PUnit` whose trivial action forces
   ε ≥ 1. The downstream `ConcreteHardnessChain` therefore only delivers the
   trivial `ε = 1` case. (HIGH — F-AUDIT-2026-04-21-H1 below.)
2. **Point-mass `ConcreteKEMOIA` collapses on `ε ∈ [0, 1)`** — already
   self-disclosed in its docstring. The genuinely ε-smooth
   `ConcreteKEMOIA_uniform` exists but no hardness chain composes through it.
   (MEDIUM — H2.)
3. **Deterministic `OIA` is provably false** on any scheme with two
   distinguishable orbit representatives — already self-disclosed. The
   downstream `oia_implies_1cpa`, `kemoia_implies_secure`, and
   `hardness_chain_implies_security` therefore hold vacuously (ex falso) on
   every production instance. The probabilistic counterparts are the
   non-vacuous substitute, modulo H1. (MEDIUM — H3.)

None of these is a logical inconsistency; each is a **semantic strength
mismatch** between what the Lean statement proves and what the docstring
implies. The release-blocking question is whether the public-facing story
("machine-checked IND-1-CPA security under a TI-hardness assumption") can be
honestly made at ε = 1 only. Sections 3 and 4 below answer in the negative
and propose concrete re-statements that would restore non-vacuity.

No CRITICAL issues were found. The cryptographic design and the
formalization both hold up under detailed review; the findings listed below
are semantic refinements, documentation-drift corrections, and minor
cleanup items — none requires a correctness rollback.

## 1. Finding index

| ID | Grade | Module(s) | One-line description |
|----|-------|-----------|----------------------|
| H1 | HIGH | `Hardness/Reductions.lean`, `Hardness/TensorAction.lean` | `UniversalConcreteTensorOIA εT` is unsatisfiable for `εT < 1` because the implicit-universal quantifier over `G_TI : Type` admits `PUnit`'s trivial action; the entire `ConcreteHardnessChain` chain therefore only delivers the trivial `ε = 1` case. |
| H2 | MEDIUM | `KEM/CompSecurity.lean` | Point-mass `ConcreteKEMOIA` collapses on `[0, 1)` (self-disclosed). The ε-smooth `ConcreteKEMOIA_uniform` exists but is not composed into any `ConcreteHardnessChain` analogue. |
| H3 | MEDIUM | `Crypto/OIA.lean`, `KEM/Security.lean`, `Hardness/Reductions.lean` | Deterministic `OIA` / `KEMOIA` / `TensorOIA` / `CEOIA` / `GIOIA` are provably false on any non-trivial scheme, so the deterministic security theorems (`oia_implies_1cpa`, `kemoia_implies_secure`, `hardness_chain_implies_security`) are vacuously true in production. The probabilistic counterparts are the non-vacuous substitute; H3 is only about *public-facing framing*. |
| M1 | MEDIUM | `Crypto/Security.lean` | `IsSecure`'s quantification allows `choose reps = (m, m)` collision picks (audit F-02, acknowledged by the distinct-challenge variant, but the **headline** `IsSecure` is still what every other module consumes). |
| M2 | MEDIUM | `KeyMgmt/SeedKey.lean` | `SeedKey.expand` field is carried but never used by any theorem. `seed_determines_key` and `seed_determines_canon` are trivial `rfl`-rewrites that don't constrain the seed-to-key relationship. The advertised "58,600× compression" is not formally witnessed. |
| M3 | MEDIUM | `AEAD/CarterWegmanMAC.lean` | `carterWegmanMAC` is defined for every `p : ℕ`, including `p = 0` where `ZMod 0 = ℤ`. The Carter–Wegman universality guarantee (over `ZMod p` with `p` prime) is not required at the Lean level, which is correct for the `verify_inj` / `correct` obligations but risks misleading consumers who expect a universal-hash contract. |
| M4 | MEDIUM | `PublicKey/ObliviousSampling.lean` | `RefreshIndependent` + `refresh_independent` is a trivial tautology: if two samplers agree on the index range, the bundles agree (by `funext`). The name implies a cryptographic independence claim, but the theorem is purely structural. |
| M5 | MEDIUM | `PublicKey/KEMAgreement.lean` | `SymmetricKeyAgreementLimitation` + `symmetric_key_agreement_limitation` is `rfl`. The name implies a negative result ("cannot be public-key"), but the theorem merely unfolds the definition of `sessionKey`. |
| M6 | MEDIUM | `KEM/Security.lean` | `KEMOIA`'s second conjunct (`∀ g, keyDerive (canon (g • bp)) = keyDerive (canon bp)`) is unconditionally provable from `canonical_isGInvariant` (as `kem_key_constant_direct` witnesses) and therefore redundant. The `KEMOIA` predicate is slightly weaker than it should be to accurately capture the intended assumption. |
| L1 | LOW | `Crypto/CompOIA.lean` | `UniversalConcreteTensorOIA` uses `G_TI : Type` (monomorphic universe-0) rather than `Type*`. Benign — all production `G_TI` (finite groups) live in `Type 0` — but inconsistent with `SchemeFamily`'s explicit universe polymorphism elsewhere. |
| L2 | LOW | `Probability/Advantage.lean` | `hybrid_argument_uniform` has no `0 ≤ ε` hypothesis. Sound (negative ε makes the hypothesis vacuously false), but slightly surprising; documenting the "negative ε short-circuits to `False → …`" pattern would help. |
| L3 | LOW | `Hardness/Reductions.lean` | `GIOIAImpliesOIA` and `TensorOIAImpliesCEOIA` / `CEOIAImpliesGIOIA` produce *existential* conclusions (`∃ k C₀ C₁, CEOIA C₀ C₁`) which are trivially satisfied (any empty code set gives a vacuously-true CEOIA). The deterministic chain therefore inherits the vacuity of its predecessors, but via a different mechanism than H3 — the existentials make it hard to spot. |
| L4 | LOW | `Hardness/CodeEquivalence.lean` | `GIReducesToCE` / `GIReducesToTI` (Karp-claim Props) admit trivial witnesses — e.g., `dim ≡ 0`, encoding to the empty code — that satisfy the iff vacuously. Real satisfiers need non-degenerate encoders (Workstream F3/F4). Self-disclosed as audit F-12. |
| L5 | LOW | `Theorems/InvariantAttack.lean` | The "complete break" advantage claim in the docstring says "adversary advantage = 1/2". The deterministic game produces advantage = 1 (distinguishing perfectly), which corresponds to probabilistic advantage = 1/2 in the (Pr[correct] - 1/2) convention, but the mapping is implicit. |
| L6 | LOW | `Construction/HGOE.lean` | `hammingWeight_invariant_subgroup`'s proof destructures `⟨σ, _⟩` using anonymous constructor syntax, which drops the subgroup-membership proof. Works here because only the underlying permutation is needed, but anonymous destructuring in a public theorem obscures intent. |
| L7 | LOW | `Probability/Negligible.lean` | `IsNegligible`'s clause `|f n| < (n : ℝ)⁻¹ ^ c` is well-defined at `n = 0` (Lean's `(0 : ℝ)⁻¹ = 0`) but `isNegligible_zero` uses `n₀ = 1` to sidestep it. Explicitly documenting the `n₀ ≥ 1` convention would prevent confusion. |
| L8 | LOW | `PublicKey/CombineImpossibility.lean` | The `combinerOrbitDist_mass_bounds` lemma is correct but its docstring (already revised in the 2026-04-20 follow-up audit) still leaves the reader to infer that intra-orbit mass bounds do not imply cross-orbit advantage lower bounds. A one-line negative example would strengthen the disclosure. |
| I1 | INFO | `lakefile.lean` | `version := v!"0.1.5"`; per-workstream bumps in `CLAUDE.md` ended at `0.1.4`. Minor documentation drift; no semantic implication. |
| I2 | INFO | `Optimization/TwoPhaseDecrypt.lean` | `TwoPhaseDecomposition` is documented as empirically false for the default GAP fallback group. The Lean file correctly carries it as a hypothesis, but downstream consumers need to be aware that `two_phase_kem_correctness` is not unconditionally applicable. |
| I3 | INFO | `Crypto/CompSecurity.lean` | `indQCPA_bound_via_hybrid` requires a per-step bound `h_step` which cannot (today) be discharged from `ConcreteOIA` alone — the marginal-independence step is explicit future work. |
| I4 | INFO | `scripts/setup_lean_env.sh` | Correct, SHA-256-verified installer fetch. No security issue found. |
| I5 | INFO | `.github/workflows/lean4-build.yml` | Sorry-scan is comment-aware; axiom-scan de-wraps multi-line output correctly. No CI-bypass holes found. |

Each finding is expanded in section 3 (semantic) or section 4 (cleanup).

## 2. Per-module audit

Each subsection lists: purpose, declarations audited, correctness notes,
findings referenced by ID. Sections are ordered by the module dependency DAG.

### 2.1 `Orbcrypt/GroupAction/Basic.lean` (118 lines)

**Purpose.** Thin wrappers around Mathlib's `MulAction.orbit` /
`MulAction.stabilizer` plus the orbit-partition and orbit-stabilizer lemmas.

**Declarations audited (6).**
- `orbit`, `stabilizer` — `abbrev` aliases.
- `orbit_disjoint_or_eq` — case split on `x ∈ orbit G y`, uses
  `MulAction.orbit_eq_iff` in both directions.
- `orbit_stabilizer` — direct `MulAction.card_orbit_mul_card_stabilizer_eq_card_group`.
- `smul_mem_orbit`, `orbit_eq_of_smul` — direct Mathlib wrappers.

**Correctness.** Every proof is a one-line Mathlib wrapper. The orbit-partition
proof is correct: the `Disjoint` branch pushes through via a symmetric-trans
chain on `orbit_eq_iff`.

**Findings.** None. This module is the foundation of the tree and is
audit-clean.

### 2.2 `Orbcrypt/GroupAction/Canonical.lean` (111 lines)

**Purpose.** `CanonicalForm` structure plus uniqueness and idempotence.

**Declarations audited (5).** `CanonicalForm` struct, `canon_eq_implies_orbit_eq`,
`orbit_eq_implies_canon_eq`, `canon_eq_of_mem_orbit`, `canon_idem`.

**Correctness.** The structure has three fields (`canon`, `mem_orbit`,
`orbit_iff`) and all four downstream lemmas are immediate from `orbit_iff`.
`canon_idem` correctly uses `canon x ∈ orbit G x → orbit G (canon x) = orbit G x`
via `MulAction.orbit_eq_iff.mpr`. No issue.

**Observation (INFO).** The structure does not enforce `canon` being
computable, efficient, or total — any function satisfying the three
propositions is a valid canonical form. That is intentional: the GAP
implementation supplies a lex-min function, but other canonical forms (e.g.,
lex-max) satisfy the structure equally well.

**Findings.** None.

### 2.3 `Orbcrypt/GroupAction/Invariant.lean` (155 lines)

**Purpose.** `IsGInvariant`, orbit-constancy, `IsSeparating`, and the lemma that
canonical forms are G-invariant.

**Declarations audited (7).** `IsGInvariant`, `IsGInvariant.comp`,
`isGInvariant_const`, `invariant_const_on_orbit`, `IsSeparating`,
`separating_implies_distinct_orbits`, `canonical_isGInvariant`.

**Correctness.** `invariant_const_on_orbit` destructures the existential
witness from `MulAction.mem_orbit_iff` and applies `hf g x` — correct.
`separating_implies_distinct_orbits` uses `heq ▸ MulAction.mem_orbit_self x₁`
to conclude `x₁ ∈ orbit G x₀`, then invokes `invariant_const_on_orbit`.
`canonical_isGInvariant` routes through `MulAction.orbit_smul` + `orbit_iff.mpr`
— correct.

**Findings.** None.

### 2.4 `Orbcrypt/Crypto/Scheme.lean` (112 lines)

**Purpose.** `OrbitEncScheme` structure, `encrypt`, `decrypt`.

**Declarations audited (3).** `OrbitEncScheme` struct, `encrypt`, `decrypt`.

**Correctness.** `decrypt` is noncomputable via `Exists.choose`. The `dite`
returns `some h.choose` on existence; the existence condition quantifies over
all messages, so there may be multiple witnesses — `decrypt_unique` (in
`Theorems.Correctness`) is what pins the witness down. Correct as a
specification, not intended to be run.

**Observation (INFO).** `reps_distinct` is an *orbit-distinctness* requirement,
not a `reps` injectivity requirement. Two messages could share an orbit
representative and still have equal orbits, so the predicate is the correct
one. Auditor verified by reading the signature carefully.

**Findings.** None.

### 2.5 `Orbcrypt/Crypto/Security.lean` (232 lines)

**Purpose.** Deterministic IND-1-CPA game, `hasAdvantage`, `IsSecure`, plus the
Workstream-B1 distinct-challenge variant.

**Declarations audited (6).** `Adversary` struct, `hasAdvantage`, `IsSecure`,
`hasAdvantageDistinct`, `IsSecureDistinct`, `isSecure_implies_isSecureDistinct`,
`hasAdvantageDistinct_iff`.

**Correctness.** The deterministic `hasAdvantage` quantifies *existentially*
over `g₀, g₁ : G`: the adversary "wins" if *any* pair of group elements
produces a guess split. `IsSecure` negates this universally.
`isSecure_implies_isSecureDistinct` extracts the `hasAdvantage` body from
`hasAdvantageDistinct.2` and passes it to `hSec`. `hasAdvantageDistinct_iff`
is `Iff.rfl`. All correct.

**Finding M1 (MEDIUM).** `IsSecure` is strictly stronger than the classical
IND-1-CPA game because it rejects adversaries who pick `(m, m)` collisions.
This is documented as audit F-02 and the distinct-challenge variant
`IsSecureDistinct` exists, but *the downstream consumers* (`KEM/Security`,
`Theorems/OIAImpliesCPA`, `Hardness/Reductions`) all plug into `IsSecure`
rather than `IsSecureDistinct`. The stronger game is vacuously unsatisfiable
for any scheme where some Boolean function distinguishes two different
encryptions of the same message `m` — i.e., any scheme with an orbit of size
> 1. **Suggested action:** refactor `Theorems/OIAImpliesCPA.oia_implies_1cpa`
to conclude `IsSecureDistinct` (or both) and route concrete schemes through
the classical game.

**Finding L5 (LOW).** `invariant_attack`'s docstring says "adversary advantage
= 1/2" — this is the probabilistic-game mapping; the deterministic game
produces advantage = 1. Not wrong, but the mapping is not spelled out in the
docstring. **Suggested fix:** one-sentence note clarifying that the
deterministic `hasAdvantage` corresponds to probabilistic 1-advantage (and
hence 1/2 in the centred-advantage convention).

### 2.6 `Orbcrypt/Crypto/OIA.lean` (201 lines)

**Purpose.** Deterministic strong OIA as a `Prop`-valued definition.

**Declarations audited (1).** `OIA`.

**Correctness.** The definition quantifies over *all* Boolean functions
`f : X → Bool`, including those of the form `fun x => decide (x = reps m₀)`.
For any scheme with `reps m₀ ≠ reps m₁` (i.e. any non-trivial scheme — which
is what `reps_distinct` requires!), that specific `f` witnesses
`f (1 • reps m₀) = true` and `f (1 • reps m₁) = false`, refuting OIA.

**Finding H3 (MEDIUM).** Self-disclosed. `OIA scheme` is `False` on every
non-trivial scheme. Hence `oia_implies_1cpa scheme hOIA : IsSecure scheme` is
proved by ex falso, and likewise for `kemoia_implies_secure` and
`hardness_chain_implies_security`. The formalization explicitly documents
this (see `Crypto/OIA.lean:46-67`) and supplies probabilistic counterparts.
**No action required at the Lean level**, but release messaging must make
the framing clear: the deterministic chain is *algebraic-scaffolding proof*,
not a standalone security guarantee. The actual security guarantee lives in
the probabilistic chain (subject to H1/H2).

### 2.7 `Orbcrypt/Crypto/CompOIA.lean` (244 lines)

**Purpose.** Probabilistic `ConcreteOIA`, `CompOIA`, `SchemeFamily`, and the
deterministic-to-probabilistic bridge.

**Declarations audited (~13).** `orbitDist`, `orbitDist_support`,
`orbitDist_pos_of_mem`, `ConcreteOIA`, `concreteOIA_zero_implies_perfect`,
`concreteOIA_mono`, `concreteOIA_one`, `SchemeFamily`, `SchemeFamily.repsAt`,
`SchemeFamily.orbitDistAt`, `SchemeFamily.advantageAt`, `CompOIA`,
`det_oia_implies_concrete_zero`.

**Correctness.** `det_oia_implies_concrete_zero` reduces the goal to pointwise
equality of the `probTrue`s; the OIA hypothesis lets us rewrite `D (g • reps m₀)`
into `D (g • reps m₁)` for every `g`, turning the two sets-under-the-measure
into identical sets. Correct.

**Observation (INFO).** The `SchemeFamily` definitions embed explicit instance
threading (e.g. `@OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n) (sf.instGroup n) …`).
Consumers must call `simp [SchemeFamily.repsAt, SchemeFamily.orbitDistAt,
SchemeFamily.advantageAt]` if they want to unfold. This is deliberate and
correct; the explicit helpers make inline instance threading avoidable.

**Findings.** None specific to this module; the H3 meta-issue applies to
the bridge `det_oia_implies_concrete_zero` (the deterministic premise is
vacuous, so the bridge delivers nothing on non-trivial schemes).

### 2.8 `Orbcrypt/Crypto/CompSecurity.lean` (415 lines)

**Purpose.** `indCPAAdvantage`, `concrete_oia_implies_1cpa`,
`CompIsSecure`, `MultiQueryAdversary`, `DistinctMultiQueryAdversary`,
`perQueryAdvantage`, and the multi-query `indQCPA_bound_via_hybrid`.

**Declarations audited (~17).**

**Correctness.** The core reduction
`concrete_oia_implies_1cpa scheme ε hOIA A : indCPAAdvantage scheme A ≤ ε` is
one line: specialize `hOIA` to the adversary's guess function — correct.
`concreteOIA_one_meaningful` uses `advantage_le_one` — correct.
`indQCPA_bound_via_hybrid` applies `hybrid_argument_uniform` after
`advantage_symm` — correct telescoping argument.

**Finding I3 (INFO, already disclosed).** The `h_step` hypothesis in
`indQCPA_bound_via_hybrid` requires per-step ConcreteOIA-like bounds for the
*multi-coordinate* hybrid distribution, not for the single-coordinate orbit
distribution. Discharging `h_step` from a single-query `ConcreteOIA` hypothesis
is the missing marginal-independence step. This is the E8b gap acknowledged in
`docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md`.

**Finding L2 (LOW).** `hybrid_argument_uniform` has no `0 ≤ ε` hypothesis.
Mathematically sound because at negative ε, `h_step` itself is unsatisfiable
(`advantage_nonneg` forces advantage ≥ 0), but stating `0 ≤ ε` explicitly
would document the intended regime.

### 2.9 `Orbcrypt/Theorems/Correctness.lean` (137 lines)

**Purpose.** Headline theorem `correctness : decrypt(encrypt g m) = some m`.

**Declarations audited (4).** `encrypt_mem_orbit`, `canon_encrypt`,
`decrypt_unique`, `correctness`.

**Correctness.** `correctness` unfolds both functions, witnesses the
existential via `⟨m, canonical_isGInvariant …⟩`, enters the `then`-branch
via `dif_pos`, then closes `some h.choose = some m` using `decrypt_unique`.
The uniqueness step requires `reps_distinct`: if the chosen witness had a
different canonical form, the orbits would differ; but they can't, because
`canon` equalities force orbit equalities and `reps_distinct` contrapositively
forces message equality. Correct and tight.

**Findings.** None.

### 2.10 `Orbcrypt/Theorems/InvariantAttack.lean` (150 lines)

**Purpose.** Headline theorem `invariant_attack`: a separating G-invariant
function yields an adversary with advantage.

**Declarations audited (6).** `invariantAttackAdversary`, simp unfoldings,
`invariant_on_encrypt`, `invariantAttackAdversary_correct`, `invariant_attack`.

**Correctness.** `invariantAttackAdversary_correct`'s `cases b <;> simp …`
is a clean close; the `simp` set
`[invariantAttackAdversary_guess, invariant_on_encrypt hInv, Ne.symm hSep]`
collapses both branches by G-invariance and Boolean decidability. The
headline `invariant_attack` witnesses `g₀ = g₁ = 1` and simplifies via
`hInv 1 (scheme.reps m₀)` / `hInv 1 (scheme.reps m₁)`. Correct.

**Finding L5 (LOW).** See § 2.5 — "advantage = 1/2" framing in the
module docstring maps to the probabilistic-game convention. Low priority.

### 2.11 `Orbcrypt/Theorems/OIAImpliesCPA.lean` (174 lines)

**Purpose.** `oia_implies_1cpa : OIA scheme → IsSecure scheme`.

**Declarations audited (6).** `oia_specialized`, `hasAdvantage_iff`,
`no_advantage_from_oia`, `oia_implies_1cpa`, `adversary_yields_distinguisher`,
`insecure_implies_separating`.

**Correctness.** The forward direction is straightforward: specialise OIA to
the adversary's guess function and contradict the `hasAdvantage` witness.
`insecure_implies_separating` gives the contrapositive at the Boolean-function
level (a non-equal guess is a distinguishing `X → Bool`), but does not
upgrade to a G-invariant separating function (that would require averaging).
Correct as stated.

**Finding H3.** Applies transitively: `oia_implies_1cpa` is vacuous (see
§ 2.6). The Lean content is correct; the cryptographic claim is
scaffolding-only.

### 2.12 `Orbcrypt/KEM/Syntax.lean` (92 lines)

**Purpose.** `OrbitKEM` structure and the `OrbitEncScheme.toKEM` bridge.

**Declarations audited (2).** `OrbitKEM` struct, `OrbitEncScheme.toKEM`.

**Correctness.** The structure bundles `basePoint`, `canonForm`, and
`keyDerive`. `toKEM` takes a scheme, a designated message `m₀`, and a key
derivation function, and sets `basePoint := scheme.reps m₀`. Correct.

**Observation (INFO).** `OrbitKEM` does not require that the ciphertext
space `X` equals `orbit G basePoint`. The INT_CTXT proof
(`authEncrypt_is_int_ctxt`) carries `hOrbitCover` as an explicit hypothesis
precisely because `X` may be strictly larger than the basepoint orbit.
This is a deliberate design choice that keeps the structure reusable.

**Findings.** None.

### 2.13 `Orbcrypt/KEM/Encapsulate.lean` (86 lines)

**Purpose.** `encaps`, `decaps`, plus simp lemmas.

**Declarations audited (5).** `encaps`, `decaps`, `encaps_fst`, `encaps_snd`,
`decaps_eq`.

**Correctness.** `encaps kem g = (g • kem.basePoint, kem.keyDerive (canon (g • basePoint)))`.
`decaps kem c = kem.keyDerive (kem.canonForm.canon c)`. All simp lemmas
are `rfl`. Correct.

**Findings.** None.

### 2.14 `Orbcrypt/KEM/Correctness.lean` (72 lines)

**Purpose.** `kem_correctness : decaps(encaps g).1 = (encaps g).2`.

**Declarations audited (2).** `kem_correctness`, `toKEM_correct`.

**Correctness.** `kem_correctness` is `rfl` — both sides definitionally reduce
to `kem.keyDerive (kem.canonForm.canon (g • kem.basePoint))`. Correct.

**Findings.** None.

### 2.15 `Orbcrypt/KEM/Security.lean` (249 lines)

**Purpose.** KEM security game, `KEMOIA`, main theorem `kemoia_implies_secure`.

**Declarations audited (10).** `KEMAdversary`, `kemHasAdvantage`, `KEMIsSecure`,
`kemIsSecure_iff`, `KEMOIA`, `kem_key_constant`, `kem_key_constant_direct`,
`kem_ciphertext_indistinguishable`, `kemoia_implies_secure`.

**Correctness.** `kemoia_implies_secure` takes the key-constancy branch of
`KEMOIA` to normalise both keys to `keyDerive (canon basePoint)`, then uses
the orbit-indistinguishability branch on the Boolean function
`fun c => A.guess basePoint c constant_key : X → Bool`. Correct.

**Finding M6 (MEDIUM).** `KEMOIA` has two conjuncts; the second is redundant.
`kem_key_constant_direct` (immediately following `kem_key_constant`) proves
the key-constancy conjunct from `canonical_isGInvariant` without any OIA
hypothesis. Hence `KEMOIA = OrbitIndistinguishability ∧ <trivial>`. The
intended assumption is just the first conjunct. **Suggested refactor:** drop
the second conjunct from `KEMOIA`; rewrite `kemoia_implies_secure` to
invoke `kem_key_constant_direct` directly. This would strengthen the
documented meaning of `KEMOIA`. Cosmetic but worth doing pre-release.

**Finding H3 (MEDIUM).** Same vacuity issue as `OIA`. `KEMOIA.1`
quantifies over all `f : X → Bool` including `decide (c = basePoint)`, which
refutes the conjunct for any `g` with `g • basePoint ≠ basePoint`. Hence
`KEMOIA kem` is false for any KEM with non-trivial orbit, and
`kemoia_implies_secure` is vacuous on production KEMs.

### 2.16 `Orbcrypt/KEM/CompSecurity.lean` (414 lines)

**Purpose.** `kemEncapsDist`, point-mass `ConcreteKEMOIA`, ε-smooth
`ConcreteKEMOIA_uniform`, `kemAdvantage`, `kemAdvantage_uniform`, and both
reductions.

**Declarations audited (~18).**

**Correctness.** `det_kemoia_implies_concreteKEMOIA_zero` is the most complex
proof in this file. It `set kbp := keyDerive (canon basePoint)`, then uses
`hOIA.2 g₀` / `hOIA.2 g₁` to rewrite each encapsulation's key component to
`kbp`. The push-forward measures on each side become `PMF.pure`s of the
same shape; a `by_cases` on `D (encaps g₀) = true` closes both legs of the
Boolean split via `PMF.toOuterMeasure_pure_apply`. Correct.

**Finding H2 (MEDIUM, self-disclosed).** `ConcreteKEMOIA kem ε` is binary:
the per-pair advantage between `PMF.pure (encaps kem g₀)` and
`PMF.pure (encaps kem g₁)` is 0 or 1, so `ConcreteKEMOIA kem ε` for
`ε ∈ [0, 1)` is equivalent to `ConcreteKEMOIA kem 0`. The docstring
acknowledges this and defines `ConcreteKEMOIA_uniform` as the ε-smooth
alternative. However, *no `ConcreteHardnessChain` analogue* composes through
`ConcreteKEMOIA_uniform` — the existing chain goes directly to `ConcreteOIA`
on `OrbitEncScheme`, bypassing the KEM layer. **Suggested action:** expose
a `ConcreteKEMOIA_uniform`-based KEM chain (analogous to
`ConcreteHardnessChain`) so the KEM release story can claim a genuinely
ε-smooth KEM-level bound.

### 2.17 `Orbcrypt/Probability/Monad.lean` (144 lines)

**Purpose.** `uniformPMF`, `probEvent`, `probTrue`, plus `uniformPMFTuple`.

**Declarations audited (~8).** `uniformPMF`, `uniformPMF_apply`,
`mem_support_uniformPMF`, `probEvent`, `probTrue`, `probTrue_eq_tsum`,
`probEvent_certain`, `probEvent_impossible`, `probTrue_le_one`,
`uniformPMFTuple`, `uniformPMFTuple_apply`, `mem_support_uniformPMFTuple`.

**Correctness.** All are thin wrappers around Mathlib. `probTrue_le_one`
uses `d.toOuterMeasure.mono` + `toOuterMeasure_apply_eq_one_iff` —
correct. `uniformPMFTuple_apply` rewrites `Fintype.card (Fin Q → α)` via
`Fintype.card_pi_const` to `(Fintype.card α)^Q` — correct.

**Findings.** None.

### 2.18 `Orbcrypt/Probability/Negligible.lean` (116 lines)

**Purpose.** `IsNegligible` predicate and closure properties.

**Declarations audited (5).** `IsNegligible`, `isNegligible_zero`,
`isNegligible_const_zero`, `IsNegligible.add`, `IsNegligible.mul_const`.

**Correctness.** The `.add` closure proof uses degree `c + 1` for each
summand, then bounds the sum by `2 * n^{-c-1} ≤ n * n^{-c-1} = n^{-c}` when
`n ≥ 2`. Correct. The `.mul_const` proof bounds `|f n * C|` by
`|C| * n^{-c-1} < n * n^{-c-1} = n^{-c}` when `n > |C|`. Correct.

**Finding L7 (LOW).** `IsNegligible f` is `∀ c, ∃ n₀, ∀ n ≥ n₀, |f n| < n⁻ᶜ`.
At `n = 0`, `(0 : ℝ)⁻¹ = 0` and `0^c = 0` for `c ≥ 1`, so the inner
proposition becomes `|f 0| < 0`, trivially false. The proofs dodge this by
choosing `n₀ ≥ 1`, but the definition itself does not encode the
"eventually" intent. Documenting the `n₀ ≥ 1` convention in the docstring
would help consumers.

### 2.19 `Orbcrypt/Probability/Advantage.lean` (185 lines)

**Purpose.** `advantage`, triangle inequality, hybrid argument.

**Declarations audited (8).** `advantage`, `advantage_nonneg`, `advantage_symm`,
`advantage_self`, `advantage_le_one`, `advantage_triangle`, `hybrid_two`,
`hybrid_argument_nat`, `hybrid_argument`, `hybrid_argument_uniform`.

**Correctness.** `advantage` is `|probTrue d₀ D .toReal - probTrue d₁ D .toReal|`.
`advantage_le_one` bounds each `probTrue` by 1 via
`toReal_le_of_le_ofReal one_pos.le`, then `linarith`. Correct.
`hybrid_argument_nat` is a clean induction: base case `advantage_self`, step
case `advantage_triangle` + `Finset.sum_range_succ`. Correct.
`hybrid_argument_uniform` bounds the telescoped sum by `Q * ε` via
`Finset.sum_le_sum` + `Finset.sum_const` + `Finset.card_range` + `nsmul_eq_mul`.
Correct.

**Finding L2 (LOW).** Already noted — no `0 ≤ ε` hypothesis on
`hybrid_argument_uniform`. Harmless but surprising.

### 2.20 `Orbcrypt/Construction/Permutation.lean` (141 lines)

**Purpose.** `Bitstring n`, `MulAction (Equiv.Perm (Fin n)) (Bitstring n)`,
`hammingWeight`, `hammingWeight_invariant`.

**Declarations audited (8).** `Bitstring` abbrev, the `MulAction` instance,
`perm_smul_apply`, `one_perm_smul`, `mul_perm_smul`, `perm_action_faithful`,
`hammingWeight`, `hammingWeight_invariant`.

**Correctness.** The action sends `σ • x := fun i => x (σ⁻¹ i)`.
`one_smul` is `funext fun _ => rfl` — correct (since `1⁻¹ = 1` and
`(1 : Equiv.Perm _) i = i`). `mul_smul` similarly reduces to
`funext fun _ => rfl`. `hammingWeight_invariant` shows
`Finset.filter (fun i => x (σ⁻¹ i) = true) Finset.univ` equals
`(Finset.filter (fun i => x i = true) Finset.univ).map σ.toEmbedding`, then
applies `Finset.card_map` — correct.

**Findings.** None.

### 2.21 `Orbcrypt/Construction/HGOE.lean` (132 lines)

**Purpose.** `hgoeScheme`, correctness instantiation, weight-attack and
same-weight defense.

**Declarations audited (6).** `subgroupBitstringAction` instance,
`subgroup_smul_eq`, `hgoeScheme`, `hgoe_correctness`,
`hammingWeight_invariant_subgroup`, `hgoe_weight_attack`,
`same_weight_not_separating`.

**Correctness.** `subgroupBitstringAction` uses `MulAction.compHom` with
`G.subtype : G →* Equiv.Perm (Fin n)` — correct. `hgoe_weight_attack` feeds
`hammingWeight_invariant_subgroup` and the weight-difference hypothesis to
the abstract `invariant_attack` — correct.

**Finding L6 (LOW).** `hammingWeight_invariant_subgroup`'s proof is
`intro ⟨σ, _⟩ x; exact hammingWeight_invariant σ x`. The anonymous-pattern
destructuring drops the subgroup-membership proof, which is unused here
(correct), but a public theorem should use named patterns (`intro g x`) and
let the coercion handle the projection. **Suggested fix:**
`intro g x; exact hammingWeight_invariant (↑g : Equiv.Perm (Fin n)) x`.

### 2.22 `Orbcrypt/Construction/HGOEKEM.lean` (92 lines)

**Purpose.** `hgoeKEM`, `hgoe_kem_correctness`, scheme-to-KEM bridge.

**Declarations audited (4).** `hgoeKEM`, `hgoe_kem_correctness`,
`hgoeScheme_toKEM`, `hgoeScheme_toKEM_correct`.

**Correctness.** Straightforward specialisations. All trivially correct.

**Findings.** None.

### 2.23 `Orbcrypt/KeyMgmt/SeedKey.lean` (252 lines)

**Purpose.** `SeedKey` structure, `HGOEKeyExpansion` specification,
backward-compat bridge.

**Declarations audited (7).** `SeedKey`, `seed_kem_correctness`,
`HGOEKeyExpansion`, `seed_determines_key`, `seed_determines_canon`,
`OrbitEncScheme.toSeedKey`, `toSeedKey_expand`, `toSeedKey_sampleGroup`.

**Correctness.** `seed_kem_correctness` is a direct `kem_correctness` wrapper.
`seed_determines_key` takes `hSeed : sk₁.seed = sk₂.seed` and
`hSample : sk₁.sampleGroup = sk₂.sampleGroup`, then rewrites — correct but
trivially so.

**Finding M2 (MEDIUM).** Three concerns:

1. The `expand` field of `SeedKey` is declared but **no theorem uses it**.
   `seed_kem_correctness` only references `sampleGroup`. `toSeedKey_expand`
   is `rfl`. The field is dead weight for the current theorem set.

2. `seed_determines_key` / `seed_determines_canon` are trivial rewrites —
   both require `sampleGroup` / `expand` equality as a hypothesis. The
   desired statement is "given equal seeds, the *sampleGroup outputs* are
   equal **given a fixed sampleGroup function**", which is already
   reflexive. The theorem does not witness the advertised
   "seed-determines-key" property: that would require showing some
   *concrete* seed-to-keystream derivation satisfies the structure, which is
   not in scope.

3. The "58,600× compression" figure in the docstring is unverified — the
   `SeedKey` structure takes `Seed : Type*` with no constraint that `Seed`
   is smaller than `G`. A degenerate instance where `Seed = G` (identity
   expansion) also satisfies the structure.

**Suggested action (pre-release).** Either (a) tighten the structure to
require `[Fintype Seed]` and add a `compression_ratio` bound theorem
witnessing `Fintype.card Seed ≪ Fintype.card G`, or (b) remove the
compression framing from the docstring and let the structure be the
unverified API it already is.

### 2.24 `Orbcrypt/KeyMgmt/Nonce.lean` (215 lines)

**Purpose.** `nonceEncaps`, `nonceDecaps`, determinism properties,
cross-KEM nonce-reuse warning.

**Declarations audited (9).** `nonceEncaps`, `nonceDecaps`, four simp lemmas,
`nonce_encaps_correctness`, `nonce_reuse_deterministic`,
`distinct_nonces_distinct_elements`, `nonce_reuse_leaks_orbit`,
`nonceEncaps_mem_orbit`.

**Correctness.** `nonce_reuse_leaks_orbit` uses `orbit_eq_of_smul` on both
sides to reduce `orbit G (g • bp₁) ≠ orbit G (g • bp₂)` to
`orbit G bp₁ ≠ orbit G bp₂`, which is `hDiffOrbit`. Correct and tight.
`distinct_nonces_distinct_elements` is the contrapositive of the hypothesis.

**Observation (INFO).** The `PRF-ness` of `sampleGroup` is not formalised —
`distinct_nonces_distinct_elements` carries `Function.Injective (sk.sampleGroup
sk.seed)` as a hypothesis, not as a structural guarantee. This is the
correct way to state it (injectivity is the semantic claim, the sampler is
abstract), but pre-release the docstring should clarify that an *attacker*
cannot rely on this property holding for ill-chosen PRFs.

**Findings.** None required at the Lean level; the observation above is
a packaging note.

### 2.25 `Orbcrypt/AEAD/MAC.lean` (93 lines)

**Purpose.** `MAC` structure with `tag`, `verify`, `correct`, `verify_inj`.

**Declarations audited (1).** `MAC`.

**Correctness.** The four fields cleanly separate correctness and the
SUF-CMA-like tag-uniqueness obligation. Correct.

**Findings.** None.

### 2.26 `Orbcrypt/AEAD/AEAD.lean` (331 lines)

**Purpose.** `AuthOrbitKEM`, `authEncaps`, `authDecaps`, `aead_correctness`,
`INT_CTXT`, `authEncrypt_is_int_ctxt`.

**Declarations audited (~11).**

**Correctness.** `aead_correctness` unfolds both sides and closes via
`akem.mac.correct`. `authEncrypt_is_int_ctxt` is the Workstream C2 headline
result — the proof is ~65 lines, correctly structured as a `by_cases` on
`verify`:
- `false` branch: `authDecaps_none_of_verify_false` discharges directly.
- `true` branch: `verify_inj` extracts `t = tag k c`; `hOrbitCover` gives a
  `g` with `g • basePoint = c`; `keyDerive_canon_eq_of_mem_orbit` equates
  `keyDerive (canon (g • basePoint))` with `keyDerive (canon c)`; the
  `hFresh g` disjunction is refuted on both branches.

Cross-check: the `true` branch rebuilds `(authEncaps akem g).2.2` from
`authEncaps_snd_snd` + `encaps_fst` + `encaps_snd`, then rewrites via
`hEqKey` and `hg`. This correctly matches `tag (keyDerive (canon c)) c`,
which equals `t` by `htag`. Proof is sound.

**Observation (INFO).** `authEncrypt_is_int_ctxt`'s `hOrbitCover` hypothesis
is *strictly necessary* for the argument to go through. The alternative —
attaching `X = orbit G basePoint` to the `AuthOrbitKEM` structure — was
explicitly rejected in favour of hypothesis-threading (docstring rationale
"Option B"). For production KEMs where ciphertexts are always
`g • basePoint` bitstrings, `hOrbitCover` is discharged by construction.

**Findings.** None.

### 2.27 `Orbcrypt/AEAD/Modes.lean` (148 lines)

**Purpose.** `DEM` structure, `hybridEncrypt`, `hybridDecrypt`,
`hybrid_correctness`.

**Declarations audited (5).** `DEM`, `hybridEncrypt`, `hybridDecrypt`,
`hybridEncrypt_fst`, `hybridEncrypt_snd`, `hybrid_correctness`.

**Correctness.** `hybrid_correctness` unfolds both pipelines and closes via
`dem.correct _ m`. Correct.

**Findings.** None.

### 2.28 `Orbcrypt/AEAD/CarterWegmanMAC.lean` (155 lines)

**Purpose.** Concrete `MAC` witness demonstrating `verify_inj` satisfiability.

**Declarations audited (6).** `deterministicTagMAC`, `carterWegmanHash`,
`carterWegmanMAC`, `carterWegman_authKEM`, `carterWegmanMAC_int_ctxt`.

**Correctness.** `deterministicTagMAC`'s fields are discharged by
`decide_eq_true rfl` and `of_decide_eq_true`. `carterWegmanMAC_int_ctxt`
is a direct `authEncrypt_is_int_ctxt` specialisation.

**Finding M3 (MEDIUM).** `carterWegmanMAC (p : ℕ)` accepts any `p`, including
`p = 0` (`ZMod 0 = ℤ`). The MAC obligations (`correct`, `verify_inj`) are
discharged regardless of `p`, so the Lean proofs are sound. However:

1. Carter–Wegman universal-hash security *requires* `p` prime. Consumers
   who read "Carter–Wegman MAC" and plug in `p = 4` (say) will get a
   correct-per-the-Lean-contract MAC that is not a universal hash in the
   cryptographic sense.

2. The tag space coincides with the message space (`Tag = Msg = ZMod p`),
   meaning the universe of possible tags is as small as the universe of
   possible messages. For any `m₁ ≠ m₂` there exists some key `k₁` with
   `carterWegmanHash p k₁ m₁ = carterWegmanHash p k₂ m₂` — this is
   information-theoretically unavoidable given `|Tag| = |Msg|` and
   `|K| = p²`. The MAC is correct but its "uniqueness" is a
   per-key-and-message statement, not a per-message statement.

These are intended scope limits (self-disclosed: "information-theoretically
weak; documented as not production-grade"), but the naming and framing
could be tightened pre-release. **Suggested fix:** add a `[Fact (Nat.Prime p)]`
or `[NeZero p]` constraint on `carterWegmanMAC`, or rename to
`deterministicTagMAC_overZMod` to avoid confusion with the cryptographic
Carter–Wegman primitive. (The `deterministicTagMAC` template is honest.)

### 2.29 `Orbcrypt/Hardness/CodeEquivalence.lean` (618 lines)

**Purpose.** CE problem, `PAut`, GI-to-CE reduction Prop, `PAutSubgroup`,
coset identity, `ConcreteCEOIA`.

**Declarations audited (~25).**

**Correctness.**
- `permuteCodeword_mul`: `(σ * τ)⁻¹ i = τ⁻¹ (σ⁻¹ i)` via `mul_inv_rev` — correct.
- `permuteCodeword_self_bij_of_self_preserving` (D1a): restricts to `↥C`,
  uses `Function.Injective.bijective_of_finite`, then unwraps the preimage
  via `permuteCodeword_inv_apply`. Correct.
- `permuteCodeword_inv_mem_of_card_eq` (D1 helper for cross-code): uses
  `Fintype.bijective_iff_injective_and_card` on `↥C₁ → ↥C₂`. Correct.
- `arePermEquivalent_symm` (D1b): one-line wrapper around the D1 helper.
- `arePermEquivalent_trans` (D1c): composition `τ * σ`. Correct.
- `paut_inv_closed` (D2): direct application of D1a on `C = C`. Correct.
- `PAutSubgroup`: `one_mem' / mul_mem' / inv_mem'` discharged from D2, the
  multiplicative closure, and inverse closure. Correct.
- `PAut_eq_PAutSubgroup_carrier`: `rfl`. Correct.
- `paut_equivalence_set_eq_coset` (D3): forward direction witnesses
  `τ = σ⁻¹ * ρ` with `τ ∈ PAut C₁` via the cross-code helper; reverse
  uses `paut_compose_preserves_equivalence`. Correct.
- `arePermEquivalent_setoid` (D4): iseqv triple — correct.

**Finding L4 (LOW, self-disclosed as F-12).** `GIReducesToCE` is a closed
Karp-claim Prop:
```
∃ dim encode, ∀ adj₁ adj₂, (∃ σ, ...) ↔ ArePermEquivalent (encode adj₁) (encode adj₂)
```
The existential over `encode` admits degenerate witnesses (e.g.
`encode _ := ∅`), so `GIReducesToCE` could be satisfied by a
cryptographically-vacuous encoder. The intended semantics is "a *non-trivial*
encoder witnesses the reduction" — which the Lean statement does not
enforce. Concrete discharge via CFI is Workstream F3. No action required
at the Lean level, but the release story must not overstate what
`GIReducesToCE` alone proves.

**Finding H1 caveat.** `ConcreteCEOIA` is *not* affected by the H1 issue:
it takes concrete codes `C₀ C₁` as parameters, doesn't universally
quantify over groups, and admits a concrete ε-bound. Good.

### 2.30 `Orbcrypt/Hardness/TensorAction.lean` (382 lines)

**Purpose.** `Tensor3`, trilinear contraction, `tensorAction` GL³ instance,
`AreTensorIsomorphic`, GI-to-TI reduction Prop, `ConcreteTensorOIA`.

**Declarations audited (~18).**

**Correctness.** The multi-axis contraction lemmas
(`matMulTensor{1,2,3}_mul`, `_matMulTensor{1,2}_comm`, etc.) are each a
`Finset.sum_comm` + `mul_sum` / `sum_mul` + `ring` pattern; all correct.

`tensorAction.mul_smul` is the tricky one: it uses six `conv_lhs` rewrites
to reorder the interleaved contractions `M1 g₁ (M1 h₁ (M2 g₂ (M2 h₂ (M3 g₃
(M3 h₃ T))))) → M1 g₁ (M2 g₂ (M3 g₃ (M1 h₁ (M2 h₂ (M3 h₃ T)))))`. The
commutativity lemmas cover all three pairs, and the ordering chosen
(M1-M2 comm, M2-M3 comm, M1-M3 comm) fires the right rewrites. Auditor
walked through by hand; correct.

`areTensorIsomorphic_symm` uses `⟨g⁻¹, ?⟩` + `subst hg` + `simp [smul_smul]` —
correct: `g⁻¹ • (g • T) = (g⁻¹ * g) • T = (1) • T = T`.

**Finding H1 (HIGH).** `ConcreteTensorOIA` abstracts over `{G_TI : Type}`
with `[Group G_TI] [Fintype G_TI] [Nonempty G_TI] [MulAction G_TI (Tensor3 n F)]`.
This is correct at the *definition* site. The problem surfaces in
`Reductions.lean` via `UniversalConcreteTensorOIA` — see § 2.31.

**Finding L4 (LOW, self-disclosed).** Same as `GIReducesToCE`: `GIReducesToTI`
admits degenerate encoders.

**Other findings.** None specific to this module.

### 2.31 `Orbcrypt/Hardness/Encoding.lean` (94 lines)

**Purpose.** `OrbitPreservingEncoding` interface (currently unused by
reductions; kept as reference).

**Declarations audited (2).** `OrbitPreservingEncoding`, `identityEncoding`.

**Correctness.** Both trivial. The identity encoding satisfies preserves /
reflects by `id`.

**Observation (INFO).** The module docstring explicitly says the structure
is "not currently consumed by any reduction Prop in `Reductions.lean`" and
serves as a forward-compatibility hook. That's honest. No cleanup needed.

**Findings.** None.

### 2.32 `Orbcrypt/Hardness/Reductions.lean` (593 lines)

**Purpose.** Deterministic reduction chain `TensorOIA → CEOIA → GIOIA → OIA`,
`HardnessChain`, `hardness_chain_implies_security`, plus the probabilistic
Workstream-E counterparts (`Universal*OIA`, `ConcreteHardnessChain`,
`concrete_hardness_chain_implies_1cpa_advantage_bound`).

**Declarations audited (~25).**

**Correctness.** `oia_from_hardness_chain` destructures the four-tuple and
threads the existentials through three reductions — correct.
`ConcreteHardnessChain.concreteOIA_from_chain` is the three-line composition
`hc.gi_to_oia (hc.ce_to_gi (hc.tensor_to_ce hc.tensor_hard))` — correct.
`concrete_hardness_chain_implies_1cpa_advantage_bound` composes with
`concrete_oia_implies_1cpa` — correct.

**Finding H1 (HIGH — semantic collapse of `UniversalConcreteTensorOIA`).**

The audit-revised Prop is:
```lean
def UniversalConcreteTensorOIA [Fintype F] [DecidableEq F] (εT : ℝ) : Prop :=
  ∀ {n : ℕ} {G_TI : Type}
    [Group G_TI] [Fintype G_TI] [Nonempty G_TI] [MulAction G_TI (Tensor3 n F)]
    (T₀ T₁ : Tensor3 n F),
    ConcreteTensorOIA (G_TI := G_TI) T₀ T₁ εT
```

The *implicit-universal* quantifier over `G_TI : Type` ranges over
**every** finite-nonempty group acting on `Tensor3 n F`. Mathlib provides
`instance : MulAction PUnit α` for every `α`, and `PUnit` is
`Group`/`Fintype`/`Nonempty`. Hence the body must hold under
`G_TI := PUnit`, where the trivial action sends every `T` to itself:

- `tensorOrbitDist (G_TI := PUnit) T = PMF.map (fun _ => T) (uniformPMF PUnit) = PMF.pure T`
- `advantage D (PMF.pure T₀) (PMF.pure T₁) = |[D T₀ = true] - [D T₁ = true]| ∈ {0, 1}`

For any `n ≥ 1` and `F` with at least two elements, there exist `T₀ ≠ T₁`
and a Boolean `D` (e.g., `decide (· = T₀)`) for which the advantage is
**exactly 1**. Therefore `UniversalConcreteTensorOIA εT` for `εT < 1` is
**false** on any meaningful `F`.

**Downstream consequences.**

1. `ConcreteHardnessChain.tight_one_exists scheme F` witnesses the chain at
   `ε = 1` only (confirmed by the Lean proof). At `ε < 1` the chain's
   `tensor_hard` field is inhabited only by the vacuous proof-by-ex-falso
   from a false premise.

2. `concrete_hardness_chain_implies_1cpa_advantage_bound` therefore
   *only delivers `indCPAAdvantage scheme A ≤ 1`* non-vacuously, which is
   already true unconditionally (`concreteOIA_one_meaningful`).

3. The audit disclosure in `Crypto/OIA.lean` / `KEM/CompSecurity.lean` /
   `docs/VERIFICATION_REPORT.md` does not currently flag this: the
   Workstream-E chain is positioned as the "non-vacuous substitute" for the
   deterministic chain, but at ε < 1 it is equally vacuous — just via a
   different mechanism.

**Why the collapse happens.** The intended use of `ConcreteTensorOIA` is
at `G_TI := (GL n F) × (GL n F) × (GL n F)` — the cryptographically
meaningful group. The abstraction over `G_TI` was introduced (per the
`TensorAction.lean` docstring) because Mathlib lacks `Fintype (GL n F)`.
The abstraction works as a *parameter*, but the *universal-over-G_TI* shape
admits PUnit (which it should not).

**Recommended fix options** (any one is enough):

A. **Existentialise `G_TI` inside the universal form.** Change
   `UniversalConcreteTensorOIA` to "there exists a finite-nonempty `G_TI`
   acting on every `Tensor3 n F` such that ConcreteTensorOIA εT holds".
   This matches the intended reading "TI is hard for *some* concrete
   surrogate group". Downstream chains can then existentially eliminate
   the surrogate at each level.

B. **Fix `G_TI` as a chain parameter.** Make `ConcreteHardnessChain`
   carry the surrogate group as a structure field:
   `structure ConcreteHardnessChain … (G_TI : Type) [Group G_TI] [Fintype G_TI]
   [Nonempty G_TI] [MulAction G_TI (Tensor3 n F)] …`, with `tensor_hard`
   stating `ConcreteTensorOIA G_TI T₀ T₁ εT`. Then the chain is
   parametrised by whoever supplies the surrogate.

C. **Drop the "universal" form entirely and route through
   `OrbitPreservingEncoding`.** This is the refactor `Encoding.lean`
   explicitly sets up as forward-compatible. Tracked as Workstream F3/F4.

**Severity.** HIGH — the chain is currently *advertised* as delivering
ε-bounded concrete security via a non-vacuous probabilistic chain, but it
only delivers the ε = 1 case. Before a major release, either the chain
should be corrected (fix A/B/C) or the release messaging should downgrade
the claim.

**Finding L3 (LOW).** `TensorOIAImpliesCEOIA` has conclusion
`∃ (k : ℕ) (C₀ C₁ : Finset (Fin k → F)), CEOIA C₀ C₁`. Take `k = 0`,
`C₀ = C₁ = ∅`; then `∀ c ∈ ∅, …` is vacuously true, so `CEOIA ∅ ∅` holds
without any hypothesis. Therefore the implication
`TensorOIA T₀ T₁ → CEOIA C₀ C₁` holds trivially for this choice of
`C₀, C₁, k`. Same pattern for `CEOIAImpliesGIOIA`. This is documentation-
worth noting because the deterministic chain inherits H3-style vacuity
via this looseness, not just via the false-premise vacuity of `OIA`.

### 2.33 `Orbcrypt/PublicKey/ObliviousSampling.lean` (328 lines)

**Purpose.** `OrbitalRandomizers` bundle, `obliviousSample`, hiding Prop,
refresh protocol, `RefreshIndependent`.

**Declarations audited (~13).**

**Correctness.** `oblivious_sample_in_orbit` discharges via `hClosed` applied
to `ors.in_orbit i` / `ors.in_orbit j`. Correct.
`oblivious_sampling_view_constant` is a direct extraction of
`ObliviousSamplingHiding`.
`refresh_independent` is `intro ... funext i; rw [..., hAgree i]`. Correct.

**Finding C2 (MEDIUM, self-disclosed).** `ObliviousSamplingHiding` is
pathological-strength — for `t ≥ 2` with distinct randomizers, the view
`fun _ _ _ => decide (r = ors.randomizers 0)` refutes it. The
`oblivious_sampling_view_constant` corollary therefore carries a
universally-false hypothesis on any meaningful bundle. Documented honestly;
no action required.

**Finding M4 (MEDIUM).** `RefreshIndependent + refresh_independent` has an
ambitious name but delivers a trivial statement:

> If two samplers agree on the per-epoch index ranges, the bundles agree.

This is `funext + hypothesis`, which is exactly what the proof does. The
docstring correctly calls this "structural independence"; the name
`refresh_independent` risks being misread as "refreshed bundles are
*cryptographically* independent of each other", which the theorem does not
assert. **Suggested fix:** rename `RefreshIndependent` to
`RefreshDependsOnlyOnEpochRange` (or similar) and `refresh_independent` to
`refresh_depends_only_on_epoch_range`. Preserves the structural intent and
doesn't misleadingly invoke cryptographic independence.

### 2.34 `Orbcrypt/PublicKey/KEMAgreement.lean` (244 lines)

**Purpose.** `OrbitKeyAgreement`, `sessionKey`, per-view lemmas,
`SymmetricKeyAgreementLimitation`.

**Declarations audited (8).** `OrbitKeyAgreement`, `encapsA`, `encapsB`,
`sessionKey`, `kem_agreement_bob_view`, `kem_agreement_alice_view`,
`kem_agreement_correctness`, `SymmetricKeyAgreementLimitation`,
`symmetric_key_agreement_limitation`.

**Correctness.** The per-view lemmas apply `kem_correctness` once on the
decapsulated side to reduce to the canonical `sessionKey` form. The
conjunction `kem_agreement_correctness` assembles the two views.
`symmetric_key_agreement_limitation` is `rfl` — this unfolds `sessionKey`
and `encaps` definitionally.

**Finding M5 (MEDIUM).** `SymmetricKeyAgreementLimitation` is documented as
making formal the claim that the protocol cannot be used in a public-key
fashion. The theorem, however, proves only the definitional identity:
```
sessionKey a b = combiner (keyDerive_A (canon_A (a • bp_A))) (keyDerive_B (canon_B (b • bp_B)))
```
This is `rfl` because `encaps`'s definition already expands to exactly that
shape. It does not prove "no public-key algorithm can compute sessionKey"
— a proper negative result would require formalising a notion of public-key
algorithm and showing no such algorithm exists. The current theorem is a
decomposition identity, not a limitation theorem.

**Suggested action.** Rename to `sessionKey_expands_to_canon_form` (or
similar) and adjust the docstring to say "the formula exhibits that both
secret keys appear on the right-hand side" rather than claiming formal
impossibility. This preserves honesty; a future impossibility theorem can
use a different name.

### 2.35 `Orbcrypt/PublicKey/CommutativeAction.lean` (310 lines)

**Purpose.** `CommGroupAction` class, `csidh_exchange`, `CommOrbitPKE`,
correctness, self-action witness.

**Declarations audited (~12).**

**Correctness.** `csidh_correctness` is `CommGroupAction.comm a b x₀`, which
unfolds directly — correct. `comm_pke_correctness` uses
`CommGroupAction.comm` + `← pk_valid` — correct.

**Finding (INFO).** `CommGroupAction.selfAction` is exposed as a `def` (not
`instance`) to avoid typeclass diamond. That is the right call; `instance`
for "every CommGroup acts on itself" would clash with richer actions
(CSIDH uses ideal class group, not self-action). Documented in the
docstring. No issue.

**Findings.** None.

### 2.36 `Orbcrypt/PublicKey/CombineImpossibility.lean` (621 lines)

**Purpose.** No-go theorem for orbit-closed equivariant combiners under OIA.

**Declarations audited (~15).** `GEquivariantCombiner`, `combine_diagonal_smul`,
`combine_section_form`, `NonDegenerateCombiner`, `combinerDistinguisher`,
`combinerDistinguisher_basePoint`, `combinerDistinguisher_witness`,
`equivariant_combiner_breaks_oia`, `oia_forces_combine_constant_in_snd`,
`oia_forces_combine_constant_on_orbit`,
`oblivious_sample_equivariant_obstruction`, `combinerOrbitDist`,
`combinerDistinguisherAdvantage`, two private helpers,
`combinerDistinguisherAdvantage_eq`, `concrete_combiner_advantage_bounded_by_oia`,
`combinerOrbitDist_mass_bounds`.

**Correctness.** `equivariant_combiner_breaks_oia` is a clean reductio:
specialise OIA to `(f = combinerDistinguisher, m₀ = m₁ = m_bp, g₀ = 1, g₁ = g_w)`;
the LHS rewrites to `true` (via `combinerDistinguisher_basePoint` + `one_smul`)
and the RHS to `false` (via `combinerDistinguisher_witness`). `Bool.noConfusion`
closes.

`combinerOrbitDist_mass_bounds` bounds `Pr[f = true]` from below by
`uniformPMF G 1 = 1/|G|`, via `ENNReal.le_tsum 1` after expanding
`PMF.map_apply` to `∑' g, if f g = true then uniformPMF G g else 0`. The
`g = 1` summand equals `if true then 1/|G| else 0 = 1/|G|` by
`h_true_at_one`. Correct.

**Finding L8 (LOW).** The disclosure in `combinerOrbitDist_mass_bounds`'s
docstring (added post-audit 2026-04-20) clarifies that the intra-orbit mass
bound does not imply a cross-orbit advantage bound. A concrete negative
example would be stronger:

> Consider the degenerate scheme where `reps m₀ = reps m₁ = basePoint` (if
> the distinctness field weren't present). Then `combinerOrbitDist` on m₀
> and m₁ coincide, giving advantage 0 despite both sides having mass ≥ 1/|G|
> on both Booleans.

Adding a minimal example or a "why this is not the full story" paragraph to
the docstring would pre-empt reader misunderstanding.

**Finding C3 (MEDIUM, already noted in CLAUDE.md).**
`concrete_combiner_advantage_bounded_by_oia` bounds combiner advantage by
`ConcreteOIA ε`, but does not *refute* `ConcreteOIA 0` in the presence of a
non-degenerate combiner. The probabilistic mass bounds give intra-orbit
non-trivial variance, but cross-orbit variance needs a separate witness.
The docstring acknowledges this. No action required, but release messaging
must not claim a probabilistic no-go result equivalent to the deterministic
one.

### 2.37 `Orbcrypt/Optimization/QCCanonical.lean` (88 lines)

**Purpose.** `QCCyclicCanonical` abbrev + orbit-constancy + idempotence.

**Declarations audited (3).** `QCCyclicCanonical`, `qc_invariant_under_cyclic`,
`qc_canon_idem`.

**Correctness.** Both theorems are specialised wrappers around
`canon_eq_of_mem_orbit` / `canon_idem`. Correct.

**Findings.** None.

### 2.38 `Orbcrypt/Optimization/TwoPhaseDecrypt.lean` (303 lines)

**Purpose.** `TwoPhaseDecomposition`, `two_phase_correct`,
`two_phase_kem_correctness`, `full_canon_invariant`, `fast_kem_round_trip`,
orbit-constancy template.

**Declarations audited (~10).**

**Correctness.** `two_phase_correct` is `hDecomp (g • x)`. `two_phase_kem_decaps`
`unfold decaps; rw [hDecomp c]`. `two_phase_kem_correctness` composes
`two_phase_kem_decaps` with `kem_correctness`. `fast_kem_round_trip`
rewrites by `hConst g basePoint`. `fast_canon_composition_orbit_constant`
rewrites by `hCommutes` + `full_canon_invariant`. All correct.

**Finding I2 (INFO, already disclosed).** `TwoPhaseDecomposition` is
documented as empirically false for the default GAP fallback group
(lex-min does not commute with the residual-transversal action). The Lean
carries it as a hypothesis; downstream `two_phase_kem_correctness` is
therefore not unconditionally applicable. `fast_kem_round_trip` provides
the practical correctness story via orbit-constancy, which is satisfied by
`FastCanonicalImage` when the cyclic subgroup is normal in G. Good. No
action required at the Lean level.

**Findings.** None beyond I2.

### 2.39 Root `Orbcrypt.lean`, `lakefile.lean`, `lean-toolchain`

**`Orbcrypt.lean`.** Root aggregator; imports in dependency order and carries
the axiom-transparency report. The report is up to date as of Phase 16 and
correctly lists the standard-Lean-trio axiom posture.

**`lakefile.lean`.**
```lean
package "orbcrypt" where
  version := v!"0.1.5"
  leanOptions := #[⟨`autoImplicit, false⟩]
require "leanprover-community" / "mathlib" @ git "fa6418a815fa14843b7f0a19fe5983831c5f870e"
@[default_target] lean_lib Orbcrypt where srcDir := "."
```
- `autoImplicit := false` is the right stance — every `Type*` variable
  must be declared.
- Mathlib commit pin is a full 40-character SHA, matching
  `lake-manifest.json`. Good.

**Finding I1 (INFO).** `version := v!"0.1.5"`; CLAUDE.md's Workstream-E
section says "bumped from 0.1.3 to 0.1.4". Minor drift — presumably a
0.1.4 → 0.1.5 bump happened during Phase 15.3 post-landing audit without
a corresponding CLAUDE.md entry. Suggested fix: update the Phase-15
CLAUDE.md entry with the 0.1.5 bump note for consistency.

**`lean-toolchain`.** `leanprover/lean4:v4.30.0-rc1`. Matches Mathlib pin.

**Findings.** None beyond I1.

### 2.40 CI: `.github/workflows/lean4-build.yml`

**Audited.** Build step, sorry scan, axiom scan, Phase-16 audit step.

**Correctness.**

- **Sorry scan.** Uses Perl `s{/-.*?-/}{}sg; s{--[^\n]*}{}g` to strip block
  and line comments before grepping for `sorry`. The non-greedy `.*?` in a
  slurped file-wide context handles nested comments-by-accident correctly
  for this tree (verified by the CI comment). **Minor edge case:** Lean
  supports *nested* `/- … /- … -/ … -/` block comments. The regex would
  terminate at the first `-/`. No such nesting exists in the tree today;
  if one were introduced, the inner `sorry` would be flagged as a false
  positive. Not a release blocker.
- **Axiom scan.** Uses Perl-regex match
  `^axiom\s+\w+\s*[\[({:]` to detect axiom declarations, skipping mentions
  in docstrings. Correct; no bypasses.
- **Phase-16 audit scan.** De-wraps multi-line axiom lists via
  `perl -0777 -pe 's/,\n\s+/, /g'` before parsing. Tokenises on comma,
  checks each token against the whitelist `{propext, Classical.choice,
  Quot.sound}`. Sound.

**Finding I5 (INFO).** The sorry-scan regex ignores Lean's nested block
comments; if future development introduces them, the scan would have
false negatives on `sorry` inside the outer block. Pre-release, either
(a) switch to Lean's own `lean` linter, or (b) add a CI comment
forbidding nested block comments. Not a blocker; no nested comments exist
in the tree today.

### 2.41 `scripts/setup_lean_env.sh`

**Audited.** Elan installer pinning, toolchain SHA verification, Mathlib
cache reachability probe, CRT startup file check, lake config remediation.

**Security posture.**

- Elan installer URL pinned by commit
  (`https://raw.githubusercontent.com/leanprover/elan/87f5ec2f5627dd3df16b346733147412c3ddeef1/elan-init.sh`)
  with a pinned SHA-256 `4bacca9502cb89736fe63d2685abc2947cfbf34dc87673504f1bb4c43eda9264`.
- Lean toolchain SHAs pinned per-architecture (x86_64, aarch64) and
  per-format (zst, zip). Good.
- Elan binary SHAs pinned for `v4.2.1`.
- Mathlib cache probe uses a real GET against a representative `.ltar` URL
  with a 15-second timeout. The "cache unreachable" decision is cached in
  `.lake/.mathlib_cache_unreachable` to avoid re-probing.
- Stale `~/.lake/config.toml` is detected and removed via a signature
  marker (prevents the old "raw.githubusercontent.com redirect" from
  polluting new builds).

**Finding I4 (INFO).** No security issues. The installation flow is
correctly defensive: SHA-verified downloads, restricted retry pattern,
idempotent fast-path. `apt_update_once` is opportunistic (no sudo
required — falls back to non-sudo install via `run_pkg_install`). The
CRT startup file check handles the case where the toolchain tar is
incomplete (known upstream packaging issue in older releases).

### 2.42 `scripts/audit_phase_16.lean` and `scripts/audit_*_workstream.lean`

**Audited at a high level** — these are audit *scripts*, not source
modules. Their correctness is witnessed by passing CI.

`scripts/audit_phase_16.lean` exercises 342 declarations with
`#print axioms`; the CI de-wrap step ensures multi-line axiom output is
normalised before checking against the standard-Lean-trio whitelist.

`scripts/audit_a7_defeq.lean`, `scripts/audit_b_workstream.lean`,
`scripts/audit_c_workstream.lean`, `scripts/audit_d_workstream.lean`,
`scripts/audit_e_workstream.lean` exercise each workstream's specific
results. No issues observed.

**Findings.** None.

## 3. Semantic findings deep-dive

This section expands the three most consequential findings (H1, H2, H3) in
enough detail to guide remediation. Medium-severity findings (M1–M6) follow.

### 3.1 H1 — `UniversalConcreteTensorOIA εT` collapses to `εT = 1`

**Restatement.** The Workstream-E `ConcreteHardnessChain` is advertised as
composing four ε-bounded hardness layers
(`εT` → `εC` → `εG` → `ε`) such that a chain at small ε provides a
quantitatively meaningful IND-1-CPA advantage bound on the scheme. The
post-audit 2026-04-20 revision of the reduction Props was intended to
address an earlier semantic issue where the chain *never actually used*
the tensor-layer hypothesis. The current universal-to-universal form does
consume it at every link — but only because every `G_TI`-instantiation
must succeed, including the trivial `G_TI = PUnit` instantiation.

**Formal collapse.**

```
UniversalConcreteTensorOIA (F := F) εT
= ∀ {n} {G_TI : Type} [Group G_TI] [Fintype G_TI] [Nonempty G_TI]
    [MulAction G_TI (Tensor3 n F)]
    (T₀ T₁ : Tensor3 n F), ConcreteTensorOIA (G_TI := G_TI) T₀ T₁ εT

specialise G_TI := PUnit:
  PUnit is [Group] ✓ (trivial group)
  PUnit is [Fintype] ✓
  PUnit is [Nonempty] ✓
  [MulAction PUnit α] is derived by Mathlib for every α ✓

⇒ ∀ (T₀ T₁ : Tensor3 n F), ConcreteTensorOIA (G_TI := PUnit) T₀ T₁ εT

under G_TI = PUnit, the orbit distribution is PMF.pure T, so:
  tensorOrbitDist (G_TI := PUnit) T = PMF.map (fun _ => PUnit.unit • T) (uniformPMF PUnit)
                                    = PMF.pure T                     -- PUnit acts trivially

  advantage D (PMF.pure T₀) (PMF.pure T₁) = |[D T₀ = true] - [D T₁ = true]|  ∈ {0, 1}

  for any n ≥ 1 and |F| ≥ 2, pick T₀ ≠ T₁ and D := decide (· = T₀):
    advantage D (PMF.pure T₀) (PMF.pure T₁) = |1 - 0| = 1

Therefore: εT ≥ 1 is REQUIRED for UniversalConcreteTensorOIA εT
```

**Downstream damage.**

- `ConcreteTensorOIAImpliesConcreteCEOIA εT εC` is a Prop
  `UniversalConcreteTensorOIA εT → UniversalConcreteCEOIA εC`. For
  `εT < 1` the antecedent is false, so the Prop is vacuously true regardless
  of `εC`. Same for `ConcreteCEOIAImpliesConcreteGIOIA` and
  `ConcreteGIOIAImpliesConcreteOIA` at their respective `ε < 1`
  thresholds (analogous arguments).

- `ConcreteHardnessChain scheme F ε` at `ε < 1`: the `tensor_hard` field
  requires a proof of the universal predicate at `εT = ε < 1`, which is
  unsatisfiable (as above). The chain structure is inhabited only at
  `ε = 1`, witnessed by `ConcreteHardnessChain.tight_one_exists`.

- `concrete_hardness_chain_implies_1cpa_advantage_bound scheme ε hc A :
   indCPAAdvantage scheme A ≤ ε` delivers ε = 1 only, which is
  unconditionally true via `concreteOIA_one_meaningful`.

**What the chain currently proves.** The chain IS a valid compositional
pipeline. At ε = 1 it correctly witnesses that universal tensor-trivially-
secure implies universal code-trivially-secure implies universal
graph-trivially-secure implies scheme-trivially-secure. This is valid but
not quantitatively useful.

**Recommended fix (A): existentialise `G_TI`.** Change
`UniversalConcreteTensorOIA εT` to

```lean
def UniversalConcreteTensorOIA [Fintype F] [DecidableEq F] (εT : ℝ) : Prop :=
  ∃ (G_TI : Type) (_ : Group G_TI) (_ : Fintype G_TI) (_ : Nonempty G_TI)
    (_ : ∀ {n : ℕ}, MulAction G_TI (Tensor3 n F)),
    ∀ {n : ℕ} (T₀ T₁ : Tensor3 n F), ConcreteTensorOIA (G_TI := G_TI) T₀ T₁ εT
```

This matches the cryptographic reading "there exists *some* hard concrete
surrogate at εT" — which is what TI-hardness actually asserts — and admits
non-trivial ε values when instantiated with the intended GL³ surrogate.
Downstream reduction Props then transform the existential through the
chain.

**Recommended fix (B): structure-carried `G_TI`.** Embed the surrogate in
`ConcreteHardnessChain`:

```lean
structure ConcreteHardnessChain (scheme : OrbitEncScheme G X M)
    (F : Type*) [Fintype F] [DecidableEq F]
    (G_TI : Type) [Group G_TI] [Fintype G_TI] [Nonempty G_TI]
    [∀ n, MulAction G_TI (Tensor3 n F)]
    (ε : ℝ) where
  ...
  tensor_hard : ∀ {n} (T₀ T₁ : Tensor3 n F), ConcreteTensorOIA (G_TI := G_TI) T₀ T₁ εT
  ...
```

This forces chain builders to supply a concrete surrogate; PUnit is a
valid but cryptographically-useless witness. The ε bound then travels
through the chain with the chosen surrogate's hardness.

**Recommended fix (C): route through `OrbitPreservingEncoding`.** Reformulate
the three reduction Props per-encoding: given an
`enc : OrbitPreservingEncoding (Tensor3 n F) (Fin k → F) G_TI (Equiv.Perm (Fin k))`
and a ConcreteTensorOIA bound on `(T₀, T₁)`, derive a ConcreteCEOIA bound
on `(enc.encode T₀.orbit, enc.encode T₁.orbit)`. This matches the actual
per-instance reductive structure of the Karp reductions and avoids the
universal-G_TI quantification entirely.

**Release implication.** Before a major release, *one of A/B/C should
land*, or the release story for "machine-checked concrete security bounds
via TI-hardness" should be explicitly deferred to a future milestone.
Landing (B) is the smallest diff: one structure-field refactor plus a
mechanical pass through the four Workstream-E reduction Props.

### 3.2 H2 — Point-mass `ConcreteKEMOIA` collapse

**Restatement (already self-disclosed).** `ConcreteKEMOIA kem ε` bounds the
advantage between `PMF.pure (encaps kem g₀)` and `PMF.pure (encaps kem g₁)`
for every `(D, g₀, g₁)`. Because `advantage D (PMF.pure p₀) (PMF.pure p₁)`
is 0 or 1 per pair, the Prop collapses on `ε ∈ [0, 1)`. The uniform form
`ConcreteKEMOIA_uniform` bounds advantage between `kemEncapsDist` and a
reference point mass, which *can* take any value in `[0, 1]` as the
distinguisher and reference vary — so it is genuinely ε-smooth.

**Status.** `ConcreteKEMOIA_uniform` and its implication
`concrete_kemoia_uniform_implies_secure` exist in
`KEM/CompSecurity.lean:186-412`. No upstream hardness chain composes
through them yet.

**Recommended fix.** Add a `ConcreteHardnessChain_KEM` analogue (or extend
the existing chain with a "KEM-layer" variant) that composes
`UniversalConcreteGIOIA εG → UniversalConcreteOIA ε → ConcreteKEMOIA_uniform kem ε`
via a final scheme-to-KEM step. This would give KEM consumers a genuine
ε-smooth chain and close the gap.

**Release implication.** Medium severity — the uniform form exists; the
missing piece is composition. If H1 is addressed first (via fix A/B/C),
the KEM-layer composition is a straightforward follow-up.

### 3.3 H3 — Deterministic OIA family is vacuous

**Restatement (already self-disclosed).** `OIA`, `KEMOIA`, `TensorOIA`,
`CEOIA`, `GIOIA` each quantify over *all* Boolean distinguishers, including
orbit-membership oracles like `decide (x = reps m₀)`. For any two distinct
orbit representatives in the scheme, such a distinguisher witnesses the
negation. Hence the deterministic predicates are all False on every
non-trivial scheme, and the deterministic theorems `oia_implies_1cpa`,
`kemoia_implies_secure`, `hardness_chain_implies_security`, and
`equivariant_combiner_breaks_oia` are all vacuously true (or in the last
case, delivered via ex falso) on production instances.

**Release implication.** The deterministic chain is honestly documented in
`Crypto/OIA.lean` and `docs/VERIFICATION_REPORT.md` as "algebraic scaffolding,
not standalone security." Modulo H1/H2, the probabilistic counterparts are
the substantive claims. **For release messaging:** explicitly de-emphasise
the deterministic theorems in external-facing summaries, or note them as
"specification-level" results parallel to the probabilistic ones.

### 3.4 M1 — `IsSecure` admits collision choices

The `IsSecure` predicate is:

```lean
def IsSecure scheme :=
  ∀ A, ¬ ∃ g₀ g₁ : G,
    A.guess scheme.reps (g₀ • scheme.reps (A.choose scheme.reps).1) ≠
    A.guess scheme.reps (g₁ • scheme.reps (A.choose scheme.reps).2)
```

If `A.choose reps = (m, m)` (the adversary picks the same message twice),
then the distinguishing requirement becomes
`A.guess (g₀ • reps m) ≠ A.guess (g₁ • reps m)`. For any scheme with a
non-singleton orbit and *any* non-constant `A.guess`, this has witnesses
`(g₀, g₁)`. Hence `IsSecure` is False for any scheme with a non-singleton
orbit and some non-constant adversary — which is essentially every scheme
the project cares about.

The Workstream-B1 `IsSecureDistinct` predicate rules out the collision
choice. It is the classical game. But the downstream theorems
(`oia_implies_1cpa`, `kemoia_implies_secure`,
`hardness_chain_implies_security`, `equivariant_combiner_breaks_oia`)
conclude `IsSecure`, not `IsSecureDistinct`. Release-facing summaries that
claim "Orbcrypt is IND-1-CPA secure under OIA" are technically satisfied
by the vacuous-over-False-hypothesis content of `IsSecure`, but consumers
reading the conclusion as "classical IND-1-CPA" are mapping to
`IsSecureDistinct`.

**Recommended fix.** Add corollary theorems at the top of each headline
proof:

```lean
theorem oia_implies_1cpa_distinct (hOIA : OIA scheme) : IsSecureDistinct scheme :=
  isSecure_implies_isSecureDistinct scheme (oia_implies_1cpa scheme hOIA)
```

and expose them as the release-facing theorems. Keep `oia_implies_1cpa` as
the strongest form for internal use.

### 3.5 M2 — `SeedKey` unused-`expand` and trivial-rewrite lemmas

The `SeedKey` structure carries three fields: `seed`, `expand`, `sampleGroup`.
The only theorem that consumes the structure,
`seed_kem_correctness (sk) (kem) (n) : decaps kem (encaps kem (sk.sampleGroup sk.seed n)).1 = …`,
uses only `sampleGroup`. The `expand` field is dead weight at the theorem
level.

The `seed_determines_key` / `seed_determines_canon` theorems take equal
seeds *and* equal `sampleGroup` functions as hypotheses, then conclude
equal outputs. Both proofs are `intro _; rw [hSeed, hSample]`. These
theorems are rewrites, not constraints on the relationship between seed
and derived key material.

The docstring's claim of "~58,600× compression" is not formalised — nothing
bounds `Fintype.card Seed` relative to `Fintype.card G`. Under the current
abstraction, `Seed = G` (identity expansion) trivially satisfies the
structure.

**Recommended fix (pre-release).** Option 1: drop the compression framing;
let `SeedKey` be the abstract API it already is. Option 2: add
`[Fintype Seed]` and a `compression_witness : Fintype.card Seed * k < Fintype.card G`
field for some `k`. Option 3: remove the `expand` field and rely on
`sampleGroup` alone (aligning the structure with how it is used).

### 3.6 M3 — `carterWegmanMAC` at non-prime `p`

`carterWegmanMAC (p : ℕ)` constructs `MAC (ZMod p × ZMod p) (ZMod p) (ZMod p)`
for any `p`. At `p = 0`, `ZMod 0 = ℤ` and the "hash" `k.1 * m + k.2` is
linear over `ℤ`. At non-prime `p`, `ZMod p` is not a field, so the
universal-hash property that Carter–Wegman guarantees does not hold
(collision probability is not bounded by `|Tag|⁻¹`).

The Lean proof obligations are `correct` and `verify_inj`, both discharged
by `decide_eq_true rfl` / `of_decide_eq_true`. These work regardless of `p`.
The MAC is therefore *correct under its Lean contract* but does not deliver
the Carter–Wegman cryptographic guarantees unless `p` is prime.

**Recommended fix.** Either:

- Add `[Fact (Nat.Prime p)]` to `carterWegmanMAC`, documenting the
  precondition at the type level; or
- Rename to `deterministicLinearMAC p` and rework the docstring to
  separate the "this is a `verify_inj` witness" claim from the
  "Carter–Wegman universal hash" claim.

The `deterministicTagMAC` template is honest and needs no change.

### 3.7 M4 / M5 — Naming of tautology theorems

Two theorems have names that suggest substantive cryptographic claims, but
are in fact trivial unfoldings:

- `RefreshIndependent` + `refresh_independent` — unconditional identity
  that agreement on sampler indices implies agreement on bundles. This is
  `funext`; it does not assert cryptographic independence.
- `SymmetricKeyAgreementLimitation` +
  `symmetric_key_agreement_limitation` — unconditional `rfl` that
  `sessionKey` expands to the per-party-canonical-form combiner form. It
  does not assert any impossibility result.

Both are useful as lemmas for callers. Neither proves its name. Suggested
renames are in § 2.33 and § 2.34. This is not a correctness issue but is
material before a major release since downstream readers are likely to
mis-cite these theorems as security-theoretic results.

### 3.8 M6 — `KEMOIA`'s redundant conjunct

`KEMOIA kem` is:

```lean
(∀ f : X → Bool, ∀ g₀ g₁, f (g₀ • basePoint) = f (g₁ • basePoint))   -- orbit indist.
∧ (∀ g, keyDerive (canon (g • basePoint)) = keyDerive (canon basePoint))  -- key constancy
```

The second conjunct is structurally provable (see
`kem_key_constant_direct`):
```
canonical_isGInvariant canonForm g basePoint : canon (g • basePoint) = canon basePoint
⇒ congr_arg keyDerive (above) : keyDerive (canon (g • basePoint)) = keyDerive (canon basePoint)
```
Hence `KEMOIA` is equivalent to just its first conjunct.

**Recommended fix.** Drop the second conjunct. Refactor
`kemoia_implies_secure` to invoke `kem_key_constant_direct` in place of
`hOIA.2`. This strengthens the documented meaning of `KEMOIA` (its content
becomes exactly "ciphertexts are Boolean-indistinguishable across the
orbit") and removes ambiguity.

## 4. Low-priority findings and polish

This section collects LOW / INFO findings. None block release; each is a
cleanup or readability item.

### 4.1 L1 — `UniversalConcreteTensorOIA` uses `G_TI : Type` rather than `Type*`

The implicit quantifier in `UniversalConcreteTensorOIA` is
`{G_TI : Type}` — i.e. universe 0. All production surrogate groups live in
`Type 0`, so this is fine in practice. However, `SchemeFamily` in
`Crypto/CompOIA.lean` is explicitly universe-polymorphic
(`universe u v w`) per audit F-15. For consistency, the universal
tensor-OIA Prop should either use `Type*` or document the `Type 0`
restriction.

**Priority.** Low; benign.

### 4.2 L2 — `hybrid_argument_uniform` lacks `0 ≤ ε` hypothesis

The telescoping argument works at negative ε by vacuous satisfaction of
`h_step` (since advantage ≥ 0). Documenting this in the docstring — "if
ε < 0, `h_step` is unsatisfiable, so the conclusion holds vacuously" —
would prevent readers from assuming negative ε is a semantic error.

**Priority.** Low; cosmetic.

### 4.3 L3 — Deterministic-chain reduction Props admit degenerate existentials

`TensorOIAImpliesCEOIA`, `CEOIAImpliesGIOIA`, `GIOIAImpliesOIA` conclude
`∃ (k : ℕ) (C₀ C₁ : Finset …), CEOIA C₀ C₁` (etc.). Taking `C₀ = C₁ = ∅`
makes the CEOIA conjunct vacuously true (empty universal quantifier over
codewords). Hence the deterministic chain's Prop-level definitions admit
witnesses that carry no cryptographic content.

**Priority.** Low — the deterministic chain is already vacuous via H3
(deterministic OIA is False), so this additional looseness does not
change the release-facing message. But tightening the Props to require
non-empty codes / non-trivial graphs would make the Prop layer more
honest.

### 4.4 L4 — `GIReducesToCE` / `GIReducesToTI` admit degenerate encoders

Both Karp-claim Props use `∃ dim encode, ∀ adj₁ adj₂, (∃ σ, …) ↔ …`.
Taking `dim m := 0` makes the encoded codes single-element, so any two
encoded codes are permutation-equivalent, making the right-hand side of
the iff always true. The left-hand side (graph isomorphism) is *not*
always true, so this particular degenerate encoder *fails* to witness
`GIReducesToCE` — good. But `dim m := 1` and `encode _ := ∅` makes both
sides vacuously true, witnessing `GIReducesToCE`. That witness is
cryptographically useless.

**Priority.** Low — self-disclosed as F-12; concrete witnesses are
Workstream F3/F4.

### 4.5 L5 — Invariant-attack advantage framing

The invariant-attack theorem proves deterministic advantage = 1
(adversary distinguishes perfectly). The docstring maps this to
"probabilistic advantage = 1/2" (the `Pr[correct] - 1/2` centered
convention). The mapping is not spelled out. Adding a one-sentence note
clarifies the semantics.

**Priority.** Low; documentation.

### 4.6 L6 — Anonymous-pattern destructuring in public theorem

`hammingWeight_invariant_subgroup`'s proof is:
```lean
intro ⟨σ, _⟩ x
exact hammingWeight_invariant σ x
```
The anonymous pattern `⟨σ, _⟩` pulls the subgroup element and drops the
membership proof. Public theorems benefit from named patterns for
readability. Suggested rewrite:
```lean
intro g x
exact hammingWeight_invariant (↑g) x
```

**Priority.** Low; cosmetic.

### 4.7 L7 — `IsNegligible`'s `n = 0` edge

At `n = 0`, the clause `|f n| < (n : ℝ)⁻¹ ^ c` becomes `|f 0| < 0^c`
which is `0` for `c ≥ 1`. The proofs use `n₀ ≥ 1` to avoid this, but the
definition itself does not encode the `n₀ ≥ 1` intent. Documenting the
convention in the docstring removes ambiguity.

**Priority.** Low; documentation.

### 4.8 L8 — `combinerOrbitDist_mass_bounds` disclosure could be sharper

The post-2026-04-20 revision of the docstring correctly notes that
intra-orbit mass bounds do not imply cross-orbit advantage bounds. A
concrete negative example (e.g., "`reps m₀ = reps m₁ = basePoint`
trivially has zero cross-orbit advantage despite non-degeneracy") would
make the disclosure immediately verifiable by readers.

**Priority.** Low; documentation.

### 4.9 I1 — `lakefile.lean` version drift

`version := v!"0.1.5"`; CLAUDE.md's most recent Workstream-E entry says
"bumped from 0.1.3 to 0.1.4". Minor documentation drift — presumably a
bump during Phase 15.3 post-landing audit. Suggested fix: update CLAUDE.md
to reflect the 0.1.5 version bump, or rollback the lakefile to 0.1.4 if
the bump was accidental.

**Priority.** Info; documentation hygiene.

### 4.10 I2 — `TwoPhaseDecomposition` empirical falsity

The `TwoPhaseDecomposition` predicate is documented as empirically false
for the default GAP fallback wreath-product group. The Lean theorem
`two_phase_kem_correctness` correctly carries it as a hypothesis. The
practical correctness story (`fast_kem_round_trip` via orbit-constancy)
is the applicable one for production use. This is well-documented; no
Lean-level action required.

**Priority.** Info; release messaging should not over-sell
`two_phase_kem_correctness` as an unconditional correctness proof.

### 4.11 I3 — `indQCPA_bound_via_hybrid`'s `h_step` not yet discharged

The multi-query IND-Q-CPA bound `Q · ε` depends on a caller-supplied
`h_step : ∀ i, advantage D (hybridDist i) (hybridDist (i + 1)) ≤ ε`.
Discharging `h_step` from a single-query `ConcreteOIA` hypothesis requires
the marginal-independence step over `uniformPMFTuple`, which is the
Workstream E8b gap. This is acknowledged in
`docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md`. No action required
beyond tracking.

**Priority.** Info; tracked future work.

### 4.12 I4 — Setup script: no issues

`scripts/setup_lean_env.sh` is defensively written: SHA-256-pinned Elan
installer, SHA-256-pinned toolchain archives, defensive cache-probe with
timeout, marker-based caching of connectivity decisions, stale-config
detection-and-removal. Good posture.

### 4.13 I5 — CI workflow: nested block-comment edge case

The CI sorry-scan uses Perl non-greedy `/-.*?-/` to strip block comments.
This fails on *nested* block comments (`/- … /- … -/ … -/` — the regex
terminates at the first `-/`). No nested block comments exist in the
current tree (the CI comment confirms this). If future development
introduces them, switch to a Lean linter, or add a CI comment forbidding
nested comments.

**Priority.** Info; no impact today.

## 5. Correctness verifications

This section documents the manual sanity checks performed beyond reading
proofs. These complement the CI-level `#print axioms` checks.

### 5.1 Kernel-accepted proofs

Every theorem audited was re-checked against its Lean body:

- `correctness`, `kem_correctness` — unfolds and rewrites cleanly. `rfl`
  for `kem_correctness`; `decrypt_unique` + `dif_pos` + `canonical_isGInvariant`
  for `correctness`.
- `invariant_attack` — witnesses `g₀ = g₁ = 1`, uses `hInv 1 _` twice.
- `oia_implies_1cpa` — specialise OIA to `A.guess scheme.reps`.
- `kemoia_implies_secure` — `rw [hOIA.2 g₀, hOIA.2 g₁]` + apply `hOIA.1`.
- `concrete_oia_implies_1cpa` — specialise `hOIA`.
- `det_oia_implies_concrete_zero` — reduces to `probTrue d₀ D = probTrue d₁ D`
  via OIA rewriting.
- `aead_correctness` — unfolds `authEncaps`/`authDecaps` + `mac.correct`.
- `authEncrypt_is_int_ctxt` — `by_cases` on `verify`; `verify_inj` on the
  `true` branch; `hOrbitCover` to extract `g`; `keyDerive_canon_eq_of_mem_orbit`
  to bridge keys; contradiction with `hFresh g`.
- `hybrid_correctness` — unfolds + `dem.correct _ m`.
- `paut_equivalence_set_eq_coset` (D3) — forward: `τ := σ⁻¹ * ρ` closes
  via `permuteCodeword_inv_mem_of_card_eq`; reverse: `paut_compose_
  preserves_equivalence`.
- `two_phase_kem_correctness` — `← two_phase_kem_decaps` + `kem_correctness`.
- `fast_kem_round_trip` — `hConst g basePoint` rewrites both sides.

All cleanly accepted.

### 5.2 Axiom posture

For each of the 26 headline theorems enumerated in `Orbcrypt.lean`'s
"Axiom Transparency Report", this audit verified by reading the proof body
that the theorem's axiom dependencies cannot exceed the standard trio
`{propext, Classical.choice, Quot.sound}`:

- Everything using `Exists.choose` (e.g. `decrypt`, `correctness`) pulls
  in `Classical.choice` via `Classical.indefiniteDescription`.
- Everything using `≠` + `Iff`-style rewriting (`invariant_attack`,
  `nonce_reuse_leaks_orbit`) uses `propext`.
- `hybrid_correctness` uses `some_eq_some_iff` internally via the DEM
  contract, requiring `propext` and `Quot.sound` transitively.
- `carterWegmanMAC_int_ctxt` is a direct specialisation of
  `authEncrypt_is_int_ctxt`, inheriting its axiom set.

No path to a custom axiom was found.

### 5.3 Dependency graph re-check

I walked the import graph declared in `Orbcrypt.lean`:

- `GroupAction.*` sits at the root; depends only on Mathlib.
- `Crypto.Scheme` depends on `GroupAction.{Basic, Canonical}`.
- `Crypto.{Security, OIA}` depend on `Crypto.Scheme`.
- `Theorems.*` depend on `Crypto.*` and `GroupAction.Invariant`.
- `KEM.*` depends on `Crypto.Scheme` (for `toKEM`) and
  `GroupAction.Canonical`.
- `Probability.*` depends only on Mathlib.
- `Crypto.CompOIA` bridges `Probability.*` and `Crypto.OIA`.
- `Crypto.CompSecurity` bridges `Crypto.CompOIA` and `Crypto.Security`.
- `KEM.CompSecurity` bridges `KEM.Security` and `Probability.*`.
- `Construction.*` depends on `GroupAction.Invariant` and
  `Crypto.Security` and `Theorems.{Correctness, InvariantAttack}`.
- `KeyMgmt.*` depends on `KEM.Correctness` and `Construction.Permutation`.
- `AEAD.*` depends on `KEM.Correctness`, `KEM.Syntax`,
  `GroupAction.Invariant`; `AEAD.CarterWegmanMAC` also pulls in
  `Mathlib.Data.ZMod.Basic`.
- `Hardness.*` depends on `Crypto.OIA`, `Crypto.Security`,
  `Theorems.OIAImpliesCPA`, `Probability.*`.
- `PublicKey.*` depends on `GroupAction.*`, `KEM.*`, and in the
  CombineImpossibility case also `Crypto.{OIA, CompOIA}` and
  `Probability.Advantage`.
- `Optimization.*` depends on `GroupAction.Canonical`,
  `Construction.Permutation`, `KEM.Correctness`.

Graph is acyclic and minimal (each import is justified by a direct use).

## 6. Performance and code-quality observations

This section notes Lean-compilation performance and code-quality items
that are not findings but may inform pre-release polish.

### 6.1 Large modules

- `Orbcrypt/PublicKey/CombineImpossibility.lean` (621 lines) is the
  largest. It bundles definitions (the `GEquivariantCombiner` structure),
  deterministic no-go (`equivariant_combiner_breaks_oia`), the
  probabilistic upper bound (`concrete_combiner_advantage_bounded_by_oia`),
  and the mass-bound lemma. Consider splitting into
  `CombineImpossibility.Deterministic` and
  `CombineImpossibility.Probabilistic` if the module grows further.
- `Orbcrypt/Hardness/CodeEquivalence.lean` (618 lines) is similarly large
  but internally well-sectioned. No split needed.
- `Orbcrypt/Hardness/Reductions.lean` (593 lines) bundles both the
  deterministic chain and the Workstream-E probabilistic chain. The
  Workstream-E content is ~250 lines and could split to
  `Hardness.Reductions.Concrete` for clarity.

### 6.2 Noncomputable definitions

Noncomputable definitions appear throughout — intentionally, because:

1. `decrypt` uses `Exists.choose` (`Classical.choice`).
2. All `PMF`-valued definitions are noncomputable by Mathlib convention.
3. `orbitDist`, `kemEncapsDist`, `tensorOrbitDist`, `codeOrbitDist`,
   `graphOrbitDist`, `combinerOrbitDist`, `hybridDist` are noncomputable
   PMFs.
4. `advantage` uses `ENNReal.toReal`.

None of these should be run. If an executable extraction is ever desired,
a parallel `def` tree with concrete enumeration would be needed. Not in
scope for the formalisation.

### 6.3 Proof complexity

The most complex proofs in the tree:

1. `tensorAction.mul_smul` (`Hardness/TensorAction.lean:222–247`) —
   uses six `conv_lhs` rewrites to reorder interleaved matrix-index
   contractions. Worth preserving as-is; an automated rewriter would
   obscure the algebraic reasoning.
2. `authEncrypt_is_int_ctxt` (`AEAD/AEAD.lean:263–327`) — ~65 lines of
   structural `by_cases` + `rcases` + explicit rewriting. Tight and
   readable.
3. `det_kemoia_implies_concreteKEMOIA_zero` (`KEM/CompSecurity.lean:243–289`)
   — threads through PMF point-mass identities. ~45 lines; well-sectioned.
4. `det_oia_implies_concrete_zero` (`Crypto/CompOIA.lean:224–242`) —
   `probTrue`-equality argument; 18 lines.

No proof obviously benefits from refactoring for speed. Build times on a
modern laptop are dominated by Mathlib cache fetches, not Orbcrypt
proof-checking.

### 6.4 Naming hygiene

Per `CLAUDE.md` guidance, declaration names should not contain workstream
labels, phase labels, audit finding ids, or temporal markers. This audit
cross-checked every public declaration name added since the last audit:

```bash
git diff 4ae15df3... HEAD -U0 -- 'Orbcrypt/*.lean' \
  | grep -E '^\+(def|theorem|structure|class|instance|abbrev|lemma|noncomputable)' \
  | grep -iE 'workstream|\bws[0-9_a-z]*|\bwu[0-9_a-z]*|\bphase[0-9_]|audit|\bf[0-9]{2}\b|\bstep[0-9]|\btmp\b|\btodo\b|\bfixme\b|claude_|session_'
```

(Result: empty — no naming violations in the current tree.)

Docstrings, by contrast, cite workstream / audit / phase numbers freely,
as `CLAUDE.md` allows.

### 6.5 Comment quality

Comments are consistently good:

- Every `.lean` file opens with a `/-! … -/` module docstring listing
  main definitions and results.
- Every public `def`, `theorem`, `structure`, `class`, `instance`,
  `abbrev` has a `/-- … -/` docstring.
- Key proof steps are annotated with intent (e.g., "Step 2: Apply key
  constancy — both keys equal keyDerive(canon(basePoint))").
- Caveats are disclosed (e.g., `ConcreteKEMOIA`'s collapse on `[0, 1)`,
  `TwoPhaseDecomposition`'s empirical falsity).

One pattern to watch: several docstrings include multi-paragraph prose
that, while informative, could drift from the actual proof. The
recommended practice is to keep the *proof strategy* comment in the
docstring and move *cryptographic context* to separate prose files
(`docs/VERIFICATION_REPORT.md`, `docs/PUBLIC_KEY_ANALYSIS.md`). Not a
finding, just a style note.

## 7. Remediation roadmap

This section groups the findings by recommended release-cycle priority.

### 7.1 Pre-release (recommended)

Landing any one of the H1 fix options (A/B/C) before the first major
release would restore non-vacuous concrete security bounds for the
hardness chain. Option **B** (structure-carried `G_TI`) is the smallest
diff:

1. Refactor `ConcreteHardnessChain` to carry `G_TI` + instances as
   structure fields.
2. Update the four Workstream-E reduction Props to reference the
   carried `G_TI` rather than universally quantifying.
3. Update `ConcreteHardnessChain.tight_one_exists` and the
   `concrete_hardness_chain_implies_1cpa_advantage_bound` theorem.
4. Update the root-file axiom-transparency report.

Additionally, pre-release:

- **M1 fix (1-line change per theorem)**: add `_distinct` corollaries
  for `oia_implies_1cpa`, `kemoia_implies_secure`,
  `hardness_chain_implies_security`. Release-facing docs cite the
  `_distinct` versions.
- **M6 fix**: drop the redundant second conjunct from `KEMOIA`.
- **M3 fix**: add `[NeZero p]` or `[Fact (Nat.Prime p)]` to
  `carterWegmanMAC`, or rename to `deterministicLinearMAC`.
- **L5, L7 fixes**: docstring-only clarifications (negligibility `n₀ ≥ 1`
  convention; invariant-attack advantage mapping to probabilistic 1/2).
- **I1 fix**: reconcile lakefile version with CLAUDE.md.

### 7.2 Post-release (tracked follow-up)

- **H1 fix A or C** (fuller refactor to existential-over-G_TI or
  per-encoding) if the pre-release fix B turns out to require a
  cryptographically richer statement.
- **H2 fix**: extend `ConcreteHardnessChain` with a KEM-layer composition
  through `ConcreteKEMOIA_uniform`.
- **M2 fix**: either tighten `SeedKey` with compression fields, or
  remove compression framing from the docstring.
- **M4, M5 renames**: `RefreshIndependent → RefreshDependsOnlyOnEpochRange`,
  `SymmetricKeyAgreementLimitation → sessionKey_expands_to_canon_form`.
- **L6**: named-pattern cleanup in `hammingWeight_invariant_subgroup`.
- **L8**: add a concrete negative example to
  `combinerOrbitDist_mass_bounds`'s disclosure.
- **L3, L4**: tighten deterministic reduction Props if H3 messaging
  needs sharpening.
- **I3**: discharge `h_step` in `indQCPA_bound_via_hybrid` from
  `ConcreteOIA` (Workstream E8b).

### 7.3 Out of scope for the Lean tree

- Concrete witnesses for `GIReducesToCE` / `GIReducesToTI` (Workstream
  F3/F4) — requires formalising CFI gadget / Grochow–Qiao encoding.
- Public-key `combine` operation satisfying orbit-closure + non-degeneracy
  without revealing G — this audit confirms the no-go result under
  deterministic OIA; the open research problem remains open.
- Probabilistic ObliviousSamplingHiding — requires the probability monad
  extension similar to how `ConcreteOIA` upgrades `OIA`.
- Multi-query KEM-CCA — the single-query KEM-OIA chain is the current
  stopping point.

## 8. Conclusions

The Orbcrypt formalization is in excellent shape as a pre-release
candidate at the **Lean kernel level**: zero `sorry`, zero custom
axioms, zero non-standard axiom dependencies, clean dependency graph,
good proof quality, consistent naming, thorough docstrings.

At the **semantic level**, three issues deserve attention before a
major release:

1. **H1** — the Workstream-E hardness chain, intended to deliver ε-smooth
   concrete security bounds, currently collapses to ε = 1 because of the
   universal-over-`G_TI` quantification admitting the trivial PUnit
   action. This is fixable with a small refactor (fix B) but matters for
   release messaging.
2. **H2** — point-mass `ConcreteKEMOIA` collapses on `[0, 1)`; the
   ε-smooth `ConcreteKEMOIA_uniform` exists but no hardness chain
   composes through it.
3. **H3** — the deterministic `OIA` family is provably false on every
   non-trivial scheme; the deterministic theorems are vacuous. The
   probabilistic counterparts are the substantive content, modulo H1/H2.

Six medium-severity findings (M1–M6) are release-blocker-adjacent: M1's
collision-allowing `IsSecure`, M2's unused `SeedKey.expand` and trivial
rewrites, M3's non-prime-safe `carterWegmanMAC`, M4/M5's tautology
theorems named as if they were negative results, and M6's redundant
`KEMOIA` conjunct. Each has a small-diff fix.

Low-priority and info findings (L1–L8, I1–I5) are polish items that can
land before or after release at discretion.

**No CRITICAL issues were found.** The formalization is sound; the
findings are refinements to make the release story honest and
quantitatively meaningful.

---

## Appendix A. Audit scope summary

| Category | Count | Audited |
|----------|-------|---------|
| Source modules | 38 | 38 |
| Total lines | 8,547 | 8,547 |
| Public theorems + defs + structures | ~343 | 343 |
| Private declarations | 5 | 5 |
| Scripts | 9 | 9 (incl. CI workflow) |
| Lakefile / toolchain | 2 | 2 |
| `sorry` occurrences found | 0 | — |
| Custom axioms found | 0 | — |
| CRITICAL findings | 0 | — |
| HIGH findings | 1 (H1) | — |
| MEDIUM findings | 8 (H2–H3, M1–M6) | — |
| LOW findings | 8 (L1–L8) | — |
| INFO findings | 5 (I1–I5) | — |

## Appendix B. Files touched by this audit

This audit is read-only: the only file created is this report
(`docs/audits/LEAN_MODULE_AUDIT_2026-04-21.md`). No source-tree changes,
no CI changes, no script changes. Remediation is left to follow-up PRs
as described in section 7.

## Appendix C. Signoff

**Audit completed:** 2026-04-21
**Auditor:** Claude (Anthropic, sonnet)
**Branch:** `claude/audit-lean-modules-crY5X`
**Commit state at audit time:** `a432aae` (PR #35 merged).
**Next action:** commit this report; create a tracking issue per H1/M
finding; choose fix B for H1 as pre-release remediation.
