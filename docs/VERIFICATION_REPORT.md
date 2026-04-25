# Orbcrypt Formal Verification Report

**Phase 16 — Formal Verification of New Components.**
*Snapshot: 2026-04-21.* *Branch: `claude/review-phase-16-verification-7nN9o`.*

---

## Executive summary

Phase 16 audits every Lean 4 module produced by Phases 7–14 of the Orbcrypt
formalization (KEM reformulation, probabilistic foundations, key compression,
nonce-based encryption, authenticated encryption, hardness alignment, public-key
extension scaffolding) and confirms that the project's zero-`sorry`,
zero-custom-axiom standard from Phase 6 has been preserved through all the
post-Phase-6 work.

**Headline numbers.**

| Metric | Value |
|---|---:|
| Lean source modules | 38 |
| Lines of Lean source | 8,156+ (Workstream K adds ≈ 130 lines across four existing modules) |
| Public declarations | 347 |
| Public declarations carrying a `/-- … -/` docstring | 347 (100 %) |
| `theorem` declarations | 220 |
| `def` declarations | 105 |
| `structure` declarations | 20 |
| `class` / `instance` / `abbrev` declarations | 1 / 3 / 3 |
| `private` declarations (intentional helpers) | 5 |
| Uses of `sorry` in source | **0** |
| Custom `axiom` declarations | **0** |
| `lake build` jobs (full project) | 3,366 |
| `lake build` warnings | 0 |
| Public declarations checked by `scripts/audit_phase_16.lean` | 346 |
| Declarations depending on `sorryAx` | **0** |
| Declarations depending on a non-standard axiom | **0** |
| Declarations depending on *no* axioms | 133+ (Workstream K4's `indCPAAdvantage_collision_zero` depends only on `propext` / `Classical.choice` / `Quot.sound` via `advantage_self`; other K additions compose standard-trio ancestors) |

**Verdict.** Phase 16 exit criteria are all met. The formal verification
posture established at the end of Phase 6 — zero `sorry`, zero custom axioms,
all theorems carrying their cryptographic assumptions as explicit hypotheses —
extends unchanged through Phases 7–14, and now also through the Workstream A/B/
C/D/E audit follow-ups.

---

## How to reproduce the audit

```bash
# 1. Set up the toolchain (one-time)
./scripts/setup_lean_env.sh

# 2. Fetch Mathlib cache (one-time per Mathlib pin update)
source ~/.elan/env && lake exe cache get

# 3. Build the whole project
source ~/.elan/env && lake build Orbcrypt

# 4. Run the comment-aware sorry audit (matches CI logic)
find Orbcrypt -name '*.lean' -print0 | while IFS= read -r -d '' f; do
  perl -0777 -pe 's{/-.*?-/}{}sg; s{--[^\n]*}{}g' "$f" \
    | grep -Pn '(^|[^A-Za-z0-9_])sorry([^A-Za-z0-9_]|$)' \
    && echo "FAIL: $f" && exit 1
done; echo "PASS: zero sorry"

# 5. Run the consolidated Phase 16 axiom-transparency audit
source ~/.elan/env && lake env lean scripts/audit_phase_16.lean
```

Step 5 prints `#print axioms` for 342 declarations — every public `def`,
`theorem`, `structure`, `class`, `instance`, and `abbrev` in
`Orbcrypt/**/*.lean`. CI fails if any line mentions `sorryAx` or any
axiom outside the standard Lean trio (`propext`, `Classical.choice`,
`Quot.sound`). The CI parser first de-wraps multi-line axiom lists
(Lean wraps long `[propext, Classical.choice, Quot.sound]` outputs
across three lines) so a custom axiom cannot hide on a continuation
line.

---

## Toolchain decision (Workstream D)

**Status.** Closed by landing 2026-04-24 (Workstream D of the
2026-04-23 pre-release audit; audit findings V1-6 / A-01 / A-02 /
A-03).

**Decision.** Orbcrypt v1.0 ships off the release-candidate Lean
toolchain `leanprover/lean4:v4.30.0-rc1` (pinned in
`lean-toolchain`) under **Scenario C** of
`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 7. The
stable-toolchain upgrade is deferred to the v1.1 release cycle.

**Rationale.** The project's Mathlib pin is
`fa6418a815fa14843b7f0a19fe5983831c5f870e`, the commit verified
against this formalisation's API surface. Bumping to a
Mathlib-stable `v4.30.0` or `v4.31.0` commit requires a coordinated
`lake update` + replay of the full Phase-16 audit (3,367 build
jobs) against the post-bump toolchain, including re-validating the
entire 347-declaration public surface for signature compatibility.
That work exceeds the Workstream-D scope and is more naturally
handled in v1.1 as a dedicated toolchain-bump workstream (tracked
in the audit plan's § 7.2 Scenario A guidance for future
reference).

**Posture disclosure.** External release messaging and downstream
consumers should be aware that v1.0's Lean toolchain is a release
candidate. The rc → stable gap is usually cosmetic (bug fixes and
small API additions), but CI-visible behaviour may drift when the
toolchain is upgraded. Consumers requiring a stable-only toolchain
chain should track the v1.1 release milestone.

**Build-configuration linter pins.** Alongside the toolchain
decision, `lakefile.lean`'s `leanOptions` array now pins
`linter.unusedVariables := true` and `linter.docPrime := true`
alongside the pre-existing `autoImplicit := false` (Workstream-D
work unit D3, audit finding A-01). The default posture differs
between the two linters:

* **`linter.unusedVariables`** is a Lean core builtin
  (`register_builtin_option … defValue := true` in
  `<toolchain>/src/lean/Lean/Linter/UnusedVariables.lean`) — the
  pin to `true` is genuinely **defensive** (a no-op in the current
  toolchain, but locks the gate against a future
  `defValue := false` flip).
* **`linter.docPrime`** is a Mathlib linter
  (`register_option linter.docPrime … defValue := false` in
  `Mathlib/Tactic/Linter/DocPrime.lean`) — Mathlib explicitly
  excludes it from its standard linter set
  (`Mathlib/Init.lean:110`, referencing
  https://github.com/leanprover-community/mathlib4/issues/20560),
  so the pin to `true` is a **meaningful enable** that turns ON a
  linter Mathlib leaves OFF. The Orbcrypt source tree currently
  has zero primed declarations, so the linter fires on zero
  existing call sites; it acts as a tripwire that prevents new
  primed identifiers from landing without a docstring.

In both cases the explicit pin keeps the zero-warning gate
enforced by the build configuration itself, not only by the CI's
warning-as-error treatment. **Caveat about `linter.docPrime`**:
because the option is registered by Mathlib (not Lean core), files
that introduce any docstring or non-import command before their
first Mathlib-aware `import` will fail at startup with
`invalid -D parameter, unknown configuration option
'linter.docPrime'`. Every `.lean` file under `Orbcrypt/`
currently starts with `import` as its first non-blank line, so the
constraint is satisfied; new modules must observe the same
convention.

**Verification.** The landing is build-configuration-only (no
Lean source files modified). Full `lake build` succeeds for all
3,367 jobs with zero warnings / zero errors on a forced rebuild
(verified by touching `Orbcrypt/GroupAction/Basic.lean` and
rerunning `lake build`); `scripts/audit_phase_16.lean` emits
unchanged axiom output (every `#print axioms` result is either
"does not depend on any axioms" or the standard-trio
`[propext, Classical.choice, Quot.sound]`; zero `sorryAx`; zero
non-standard axioms). The 38-module total and the 347 public-
declaration count are unchanged.

**Patch version.** `lakefile.lean` bumped from `0.1.8` to `0.1.9`
for the Workstream-D landing. The bump records that the project's
build-surface configuration has changed in a consumer-visible way
(downstream users running `lake env …` against a cloned checkout
experience a different warning surface after this landing).

---

## Headline results table

The eight load-bearing theorems are listed first — these are the ones a
reader who needs to "trust the math" should know about. Each row is
machine-checked by `scripts/audit_phase_16.lean`.

| #  | Name                                  | File                                | Status      | Standard axioms only? |
|----|---------------------------------------|-------------------------------------|-------------|-----------------------|
| 1  | `correctness`                         | `Theorems/Correctness.lean`         | Unconditional        | ✓ (`propext`, `Classical.choice`, `Quot.sound`) |
| 2  | `invariant_attack`                    | `Theorems/InvariantAttack.lean`     | Unconditional        | ✓ (`propext`) |
| 3  | `oia_implies_1cpa`                    | `Theorems/OIAImpliesCPA.lean`       | Conditional on `OIA` | ✓ (no axioms used) |
| 4  | `kem_correctness`                     | `KEM/Correctness.lean`              | Unconditional        | ✓ (no axioms used) |
| 5  | `kemoia_implies_secure`               | `KEM/Security.lean`                 | Conditional on `KEMOIA` | ✓ (no axioms used) |
| 6  | `aead_correctness`                    | `AEAD/AEAD.lean`                    | Unconditional        | ✓ (`propext`) |
| 7  | `hybrid_correctness`                  | `AEAD/Modes.lean`                   | Unconditional        | ✓ (no axioms used) |
| 8  | `concrete_oia_implies_1cpa`           | `Crypto/CompSecurity.lean`          | Conditional on `ConcreteOIA(ε)` | ✓ |

Every conditional result carries its assumption (OIA / KEMOIA / ConcreteOIA)
as an *explicit hypothesis* in its type signature. None of these assumptions
is a Lean `axiom` — they are `Prop`-valued definitions, so the reduction
is honest about which assumption is doing the cryptographic work.

### Extended headline table (Phase 7 → 14 + Workstream A–E)

| #   | Name                                                          | File                                          | Status                              |
|----:|---------------------------------------------------------------|-----------------------------------------------|--------------------------------------|
| 9   | `seed_kem_correctness`                                        | `KeyMgmt/SeedKey.lean`                        | Unconditional (uses `kem_correctness`) |
| 10  | `nonce_encaps_correctness`                                    | `KeyMgmt/Nonce.lean`                          | Unconditional |
| 11  | `nonce_reuse_leaks_orbit`                                     | `KeyMgmt/Nonce.lean`                          | Unconditional warning theorem |
| 12  | `authEncrypt_is_int_ctxt`                                     | `AEAD/AEAD.lean`                              | **Standalone** (post-2026-04-23 Workstream B refactor: orbit condition absorbed into `INT_CTXT` game as a per-challenge well-formedness precondition; theorem discharges unconditionally on every `AuthOrbitKEM`) |
| 13  | `carterWegmanMAC_int_ctxt`                                    | `AEAD/CarterWegmanMAC.lean`                   | **Conditional** (requires `X = ZMod p × ZMod p`; incompatible with HGOE's `Bitstring n` — research R-13; see Known limitations item 12. Post-Workstream-B the orbit content is unconditional; only the HGOE compatibility caveat remains) |
| 13a | `carterWegmanHash_isUniversal`                                | `AEAD/CarterWegmanMAC.lean`                   | **Carter–Wegman 1977 `(1/p)`-universality** (post-audit 2026-04-22) |
| 13b | `IsEpsilonUniversal`                                          | `Probability/UniversalHash.lean`              | ε-universal hash Prop (post-audit 2026-04-22) |
| 14  | `hardness_chain_implies_security`                             | `Hardness/Reductions.lean`                    | Conditional on `HardnessChain` |
| 15  | `oblivious_sample_in_orbit`                                   | `PublicKey/ObliviousSampling.lean`            | Conditional on closure hypothesis |
| 16  | `kem_agreement_correctness`                                   | `PublicKey/KEMAgreement.lean`                 | Unconditional |
| 17  | `csidh_correctness`                                           | `PublicKey/CommutativeAction.lean`            | Conditional on `CommGroupAction.comm` typeclass axiom |
| 18  | `comm_pke_correctness`                                        | `PublicKey/CommutativeAction.lean`            | Conditional on `CommGroupAction.comm` + `pk_valid` |
| 19  | `comp_oia_implies_1cpa`                                       | `Crypto/CompSecurity.lean`                    | Conditional on `CompOIA` (asymptotic) |
| 20  | `det_oia_implies_concrete_zero`                               | `Crypto/CompOIA.lean`                         | Bridge: `OIA → ConcreteOIA 0` |
| 21  | `concrete_kemoia_uniform_implies_secure`                      | `KEM/CompSecurity.lean`                       | Genuinely ε-smooth KEM bound (Workstream E1d) |
| 22  | `concrete_hardness_chain_implies_1cpa_advantage_bound`        | `Hardness/Reductions.lean`                    | **Quantitative** — probabilistic hardness chain (Workstream E5); inhabited only at ε = 1 via `tight_one_exists` in the current formalisation; ε < 1 requires caller-supplied surrogate + encoder witnesses (research-scope R-02 / R-03 / R-04) |
| 23  | `indQCPA_from_perStepBound`                                   | `Crypto/CompSecurity.lean`                    | **Quantitative** — multi-query bound (Workstream E8c) **under caller-supplied `h_step` per-step bound**; discharge from `ConcreteOIA` alone is research-scope R-09. Renamed from `indQCPA_bound_via_hybrid` in Workstream C of 2026-04-23 plan (finding V1-8 / C-13) to surface the `h_step` obligation in the identifier itself |
| 24  | `arePermEquivalent_setoid`                                    | `Hardness/CodeEquivalence.lean`               | Mathlib `Setoid` instance (Workstream D4) |
| 25  | `paut_equivalence_set_eq_coset`                               | `Hardness/CodeEquivalence.lean`               | Full coset set identity (Workstream D3) |
| 26  | `PAutSubgroup`                                                | `Hardness/CodeEquivalence.lean`               | `PAut` as Mathlib `Subgroup` (Workstream D2) |
| 27  | `concrete_combiner_advantage_bounded_by_oia`                  | `PublicKey/CombineImpossibility.lean`         | Probabilistic equivariant-combiner upper bound (Workstream E6) |
| 28  | `combinerOrbitDist_mass_bounds`                               | `PublicKey/CombineImpossibility.lean`         | Intra-orbit mass bound under non-degeneracy (E6b) |
| 29  | `oia_implies_1cpa_distinct`                                   | `Theorems/OIAImpliesCPA.lean`                 | Classical IND-1-CPA corollary, conditional on `OIA` (Workstream K1) |
| 30  | `hardness_chain_implies_security_distinct`                    | `Hardness/Reductions.lean`                    | Classical IND-1-CPA corollary, conditional on `HardnessChain` (Workstream K3) |
| 31  | `indCPAAdvantage_collision_zero`                              | `Crypto/CompSecurity.lean`                    | Unconditional: probabilistic IND-1-CPA advantage vanishes on collision-choice adversaries (Workstream K4) |
| 32  | `concrete_hardness_chain_implies_1cpa_advantage_bound_distinct` | `Hardness/Reductions.lean`                  | **Quantitative** — classical IND-1-CPA form of the probabilistic chain bound (Workstream K4 companion), conditional on `ConcreteHardnessChain`; same ε = 1 inhabitation posture as row #22 |
| 33  | `det_oia_false_of_distinct_reps`                              | `Crypto/OIA.lean`                             | **Standalone** — machine-checked vacuity witness for the deterministic `OIA` under the distinct-representatives hypothesis (Workstream E of 2026-04-23 audit, finding C-07). Closes the prose-only vacuity disclosure that previously lived in `Crypto/OIA.lean`'s module docstring. The distinguisher is `fun x => decide (x = scheme.reps m₀)` at identity group elements; LHS decides `true`, RHS decides `false`, contradiction |
| 34  | `det_kemoia_false_of_nontrivial_orbit`                        | `KEM/Security.lean`                           | **Standalone** — KEM-layer parallel of row #33 (Workstream E of 2026-04-23 audit, finding E-06). Refutes `KEMOIA kem` under the non-trivial base-point-orbit hypothesis `g₀ • basePoint ≠ g₁ • basePoint`; holds on every realistic KEM (production HGOE has `\|orbit\| ≫ 2`). Written against the post-L5 single-conjunct `KEMOIA`; no `.1` / `.2` destructuring |

Every one of #1–#34 was confirmed to depend only on standard Lean axioms by
running `scripts/audit_phase_16.lean` — all declarations exercised
(every public declaration in the source tree), no `sorryAx`, no custom
axiom outside the standard Lean trio.

---

## Per-phase verification matrix

### Phase 7 — KEM reformulation (work unit 16.1)

`KEM/Syntax.lean` (1 def, 1 structure), `KEM/Encapsulate.lean`
(2 defs, 3 simp lemmas), `KEM/Correctness.lean` (2 theorems),
`KEM/Security.lean` (3 defs, 5 theorems, 1 structure),
`KEM/CompSecurity.lean` (5 defs, 14 theorems — added in Workstream E1).

**Build status.** All five modules compile under `lake build`. Each
`#print axioms` query returns either "does not depend on any axioms" or the
standard Lean trio.

**Key theorems and assumptions.**

* `kem_correctness` — proved by `rfl`; depends on no axioms.
* `kemoia_implies_secure` — depends on no axioms; carries `KEMOIA` as an
  explicit hypothesis.
* `kem_key_constant_direct` — *unconditional* corollary of
  `canonical_isGInvariant`; demonstrates that `KEMOIA`'s second conjunct is
  redundant and provable from the structure.
* `concrete_kemoia_implies_secure` — point-mass form (Workstream E1d); the
  docstring discloses that the predicate collapses on `ε ∈ [0, 1)`.
* `concrete_kemoia_uniform_implies_secure` — uniform-form (Workstream E1d
  post-audit addition); genuinely ε-smooth.

**Exit criteria (all met):**

- [x] All five modules compile with `lake build`.
- [x] `kem_correctness` compiles with zero `sorry`.
- [x] `kemoia_implies_secure` compiles with zero `sorry`.
- [x] `toKEM_correct` compiles with zero `sorry`.
- [x] `#print axioms` reports only the standard Lean trio.

### Phase 10 — Authenticated encryption and modes (work unit 16.2)

`AEAD/MAC.lean` (1 structure), `AEAD/AEAD.lean` (1 structure, 3 defs,
5 theorems including `INT_CTXT` and `authEncrypt_is_int_ctxt`),
`AEAD/Modes.lean` (1 structure, 2 defs, 3 theorems),
`AEAD/CarterWegmanMAC.lean` (4 defs, 1 theorem).

**Build status.** All four modules compile cleanly. The `INT_CTXT`
proof (`authEncrypt_is_int_ctxt`, Workstream C2c) is the technically
hardest result here: it case-splits on MAC verification and uses
`MAC.verify_inj` (Workstream C1) plus `canon_eq_of_mem_orbit` plus an
explicit orbit-cover hypothesis to derive a contradiction with the
freshness condition.

**Key theorems and assumptions.**

* `aead_correctness` — depends only on `propext`; carries no
  cryptographic assumption beyond the `MAC.correct` field.
* `hybrid_correctness` — depends on no axioms; pure composition of
  `kem_correctness` and `DEM.correct`.
* `INT_CTXT` — a `Prop`-valued *definition*, not a theorem, capturing
  the integrity-of-ciphertexts property.
* `authEncrypt_is_int_ctxt` — depends on `propext, Quot.sound`. Post-
  2026-04-23 Workstream B, the orbit-cover condition is a per-challenge
  well-formedness precondition on the `INT_CTXT` game itself (not a
  theorem-level argument); the theorem's signature is simply
  `(akem : AuthOrbitKEM G X K Tag) → INT_CTXT akem`. *No custom axiom*
  — `verify_inj` is a `MAC` field, *not* an axiom.
* `carterWegmanMAC_int_ctxt` — concrete witness: instantiates the above
  on a deterministic Carter-Wegman universal-hash MAC over `ZMod p`,
  showing `INT_CTXT` is non-vacuously inhabitable.

**Exit criteria (all met):**

- [x] All four modules compile with `lake build`.
- [x] `aead_correctness` compiles with zero `sorry`.
- [x] `hybrid_correctness` compiles with zero `sorry`.
- [x] `MAC.correct` field is well-typed and discharged by every concrete
      MAC instance.
- [x] `MAC.verify_inj` field is well-typed and discharged by
      `deterministicTagMAC` via `of_decide_eq_true`.
- [x] `#print axioms` reports only the standard Lean trio.

### Phase 8 — Probabilistic foundations (work unit 16.3)

`Probability/Monad.lean` (4 defs, 8 theorems — incl. Workstream E7
`uniformPMFTuple`), `Probability/Negligible.lean` (1 def, 4 theorems),
`Probability/Advantage.lean` (1 def, 8 theorems — incl. Workstream E
`hybrid_argument_uniform`), `Crypto/CompOIA.lean` (6 defs, 6 theorems,
1 structure), `Crypto/CompSecurity.lean` (5 defs, 13 theorems,
2 structures), `KEM/CompSecurity.lean` (5 defs, 14 theorems).

**Build status.** All six modules compile cleanly.

**Sorry classification (Phase 16 work unit 16.3c).** Phase 8's planning
document (`docs/planning/PHASE_8_PROBABILISTIC_FOUNDATIONS.md` work unit
8.10) originally allowed a "multi-query skeleton" `sorry` as an
intentional placeholder for the Hidden Subgroup Problem step. **That
`sorry` no longer exists in the source.** The Workstream E8 work unit
replaced the placeholder with the explicit-`h_step` formulation in
`indQCPA_from_perStepBound` (renamed from `indQCPA_bound_via_hybrid`
in Workstream C of audit 2026-04-23 / finding V1-8 / C-13 to surface
the `h_step` caller-obligation in the identifier itself): the per-step
bound is carried as a hypothesis, the telescoping is proved
unconditionally via `hybrid_argument_uniform`, and the regression
sentinel `indQCPA_from_perStepBound_recovers_single_query` confirms the
Q = 1 specialisation.
The marginal-independence argument that would discharge `h_step` from
`ConcreteOIA` alone over an arbitrary product distribution remains a
research follow-up (tracked as Workstream E8b in the audit plan); it is
**not** present in the source as a `sorry` placeholder.

**Result of the comment-aware sorry scan (Phase 16 work unit 16.4):**

```
$ ./scripts/(comment-aware sorry check, equivalent to CI)
0 occurrences in source code, 36 files scanned.
```

There are no `sorry` placeholders anywhere in `Orbcrypt/**/*.lean`.

**Key theorems and assumptions (Phase 8 + Workstream E1/E5/E8).**

* `concrete_oia_implies_1cpa` — depends on `propext, Classical.choice,
  Quot.sound`; carries `ConcreteOIA(ε)` as a hypothesis.
* `concreteOIA_one` — `ConcreteOIA scheme 1` is unconditionally true,
  i.e. the predicate is satisfiable.
* `comp_oia_implies_1cpa` — depends on `propext, Classical.choice,
  Quot.sound`; carries `CompOIA` (asymptotic, negligible-advantage)
  as a hypothesis.
* `det_oia_implies_concrete_zero` — bridge from the deterministic OIA
  to `ConcreteOIA 0`; demonstrates that the deterministic predicate is
  the zero-advantage specialisation of the probabilistic one.
* `hybrid_argument_uniform` — Q-step bound from per-step bound;
  Workstream E8 pre-requisite.
* `indQCPA_from_perStepBound` — multi-query advantage ≤ Q · ε via the
  hybrid argument and a caller-supplied per-step bound `h_step`
  (renamed from `indQCPA_bound_via_hybrid` in Workstream C of audit
  2026-04-23, finding V1-8 / C-13).
* `indQCPA_from_perStepBound_recovers_single_query` — Q = 1 sanity
  sentinel (renamed from `indQCPA_bound_recovers_single_query` in the
  same workstream).
* `det_kemoia_implies_concreteKEMOIA_zero` — KEM bridge (Workstream E1c).

**Exit criteria (all met):**

- [x] `uniformPMF`, `probEvent`, `probTrue` type-check with correct
      Mathlib imports.
- [x] All sanity lemmas compile.
- [x] `advantage`, `advantage_triangle`, `advantage_le_one`,
      `hybrid_argument`, `hybrid_argument_uniform` compile.
- [x] `ConcreteOIA` type-checks; `concrete_oia_implies_1cpa` compiles.
- [x] Every `sorry` in Phase 8's planning placeholders has been
      *removed* — no `sorry` remains in the source.
- [x] `#print axioms` reports only the standard Lean trio for every
      headline theorem.

### Phase 9 — Key compression and nonce-based encryption

`KeyMgmt/SeedKey.lean` (3 defs, ~6 theorems), `KeyMgmt/Nonce.lean`
(2 defs, ~5 theorems).

**Build status.** Both modules compile cleanly. All headline theorems
depend only on standard Lean axioms.

### Phase 12 — Hardness alignment (LESS / MEDS / TI)

`Hardness/CodeEquivalence.lean` — gained the full Mathlib-style API in
Workstream D (PAut as `Subgroup`, ArePermEquivalent as `Setoid`, the
full coset set identity).
`Hardness/TensorAction.lean` — `Tensor3` type, `tensorAction` MulAction
of GL³, Tensor Isomorphism reduction.
`Hardness/Reductions.lean` — `TensorOIA`, `GIOIA`, the reduction chain,
plus the Workstream E ε-bounded ConcreteHardnessChain.
`Hardness/Encoding.lean` — orbit-preserving encoding interface
(reference target for concrete discharges of Workstream G's per-encoding
reduction Props; see `docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md`
§ 15.1 for the CFI / Grochow–Qiao research-scope discharges).

### Phase 13 — Public-key extension scaffolding

`PublicKey/ObliviousSampling.lean`, `PublicKey/KEMAgreement.lean`,
`PublicKey/CommutativeAction.lean`, `PublicKey/CombineImpossibility.lean`.
All four modules compile; all theorems carry their assumptions as
explicit hypotheses (closure, `ObliviousSamplingHiding`,
`CommGroupAction.comm`, etc.).

---

## Sorry audit (work unit 16.4)

**Method.** The CI strips Lean block comments (`/- … -/`, including
docstrings `/-- … -/` and module docstrings `/-! … -/`) and line
comments (`-- …`) from each `.lean` file using a Perl slurp, then
greps the residual source for `sorry` with identifier word-boundaries
on both sides. The same script is reproduced in §"How to reproduce".

**Result.**

```
0 occurrences of `sorry` outside comments and docstrings,
across 36 .lean files.
```

The single literal "sorry" string anywhere in the source tree appears
in the docstring of `authEncrypt_is_int_ctxt`
(`Orbcrypt/AEAD/AEAD.lean:323` post-Workstream-B refactor), in the
prose `"No custom axiom, no \`sorry\`."`. The CI strip filter
correctly ignores it.

**Classification of historical `sorry` placeholders (planning-doc
references).** Phase 8's planning doc allowed up to three
intentional `sorry` placeholders (work units 8.10, 8.5b, 8.5d).
**None of them remain in the source.** All three have been
discharged by Workstream E (E1, E5, E8) as documented above.

---

## Axiom audit (work unit 16.5)

**Method.** `scripts/audit_phase_16.lean` runs `#print axioms` on 342
declarations — every public `def`, `theorem`, `structure`, `class`,
`instance`, and `abbrev` in `Orbcrypt/**/*.lean`, including all
Phase 2–14 foundations and the Workstream A/B/C/D/E follow-ups. CI
first de-wraps multi-line axiom lists (Lean wraps long
`[propext, Classical.choice, Quot.sound]` outputs across three lines,
so a naive line-oriented scan would miss a custom axiom on a
continuation line), then parses each depends-on line and rejects:

* any axiom outside the standard Lean trio
  (`propext`, `Classical.choice`, `Quot.sound`);
* any occurrence of `sorryAx` (which would indicate a hidden `sorry`
  in the dependency chain).

**Result.**

```
342 declarations exercised (every public declaration in Orbcrypt/**/*.lean)
 133 depend on no axioms at all
 209 depend only on a subset of {propext, Classical.choice, Quot.sound}
   0 depend on any non-standard axiom
   0 depend on `sorryAx`
```

The full `#print axioms` per-declaration breakdown is reproduced in
`Orbcrypt.lean`'s axiom transparency report (§"Verification" near the
end of the file).

---

## Module-docstring audit (work unit 16.6)

**Method.** For every `.lean` file in `Orbcrypt/`, check that:

1. The file begins with a `/-! … -/` module docstring.
2. Every public (non-`private`) `def`, `theorem`, `lemma`,
   `structure`, `class`, `instance`, or `abbrev` is preceded by a
   `/-- … -/` documentation comment.

**Result.** All 36 modules carry a `/-! … -/` module docstring. All 343
public declarations carry a `/-- … -/` docstring (a single grep false
positive at `Orbcrypt/Hardness/Encoding.lean:20` is plain text inside
the wrapped module-level docstring, not an actual declaration).

Phase 6's docstring standards are preserved unchanged through Phases
7–14.

---

## Root-import / dependency-graph audit (work unit 16.7)

`Orbcrypt.lean` imports all 36 modules. Building `lake build Orbcrypt`
exercises the complete graph (3,364 jobs including Mathlib
dependencies, zero errors, zero warnings).

The ASCII dependency graph in `Orbcrypt.lean`'s docstring already
covers every Phase 7–13 module. Phase 16 added a new "Phase 16
Verification Audit Snapshot" subsection at the end of that docstring
recording the audit-time totals.

---

## CI configuration (work unit 16.8)

`.github/workflows/lean4-build.yml` now runs four checks on every push
and pull request:

1. **`lake build Orbcrypt`** — full project build (3,364 jobs).
2. **Comment-aware `sorry` strip** — Perl slurp + word-boundary grep.
   Audit finding F-03 hardened this against false positives from
   docstring prose mentioning the word "sorry".
3. **Custom-axiom guard** — Perl regex matching the
   `^axiom <ident> [params] : <type>` declaration form. False positives
   from "axiom" appearing in docstrings are excluded by the regex.
4. **Phase 16 axiom-transparency audit** *(new in Phase 16)* —
   `lake env lean scripts/audit_phase_16.lean` followed by a Bash
   token-walker that fails fast if any axiom outside the standard
   Lean trio appears, or if `sorryAx` is mentioned anywhere.

Step (4) is the audit-script regression sentinel: any future change
that hides a `sorry` behind an opaque definition or that introduces a
custom axiom will trip CI immediately.

---

## Regression audit (work unit 16.9)

All 11 original Phase 1–6 modules build individually:

```
Orbcrypt.GroupAction.Basic        Build completed successfully
Orbcrypt.GroupAction.Canonical    Build completed successfully
Orbcrypt.GroupAction.Invariant    Build completed successfully
Orbcrypt.Crypto.Scheme            Build completed successfully
Orbcrypt.Crypto.Security          Build completed successfully
Orbcrypt.Crypto.OIA               Build completed successfully
Orbcrypt.Theorems.Correctness     Build completed successfully
Orbcrypt.Theorems.InvariantAttack Build completed successfully
Orbcrypt.Theorems.OIAImpliesCPA   Build completed successfully
Orbcrypt.Construction.Permutation Build completed successfully
Orbcrypt.Construction.HGOE        Build completed successfully
```

The Phase 4 axiom expectations (from
`docs/planning/PHASE_16_FORMAL_VERIFICATION.md` work unit 16.9) are
preserved exactly:

```
Orbcrypt.correctness        depends on axioms: [propext, Classical.choice, Quot.sound]
Orbcrypt.invariant_attack   depends on axioms: [propext]
Orbcrypt.oia_implies_1cpa   does not depend on any axioms
```

No regression in axiom dependencies for any pre-Phase-7 theorem.

---

## Theorem inventory (work unit 16.10b)

Counts by directory (Phase 16 work unit 16.10a):

| Directory     | Files | Lines | Theorems | Defs | Structures |
|---------------|------:|------:|---------:|-----:|-----------:|
| `AEAD/`       |     4 |   727 |        9 |    9 |          3 |
| `Construction/` |   3 |   365 |    (mixed) |   (mixed) |    (mixed) |
| `Crypto/`     |     5 | 1,204 |    (mixed) |   (mixed) |    (mixed) |
| `GroupAction/` |    3 |   384 |    (mixed) |   (mixed) |    (mixed) |
| `Hardness/`   |     4 | 1,687 |    (mixed) |   (mixed) |    (mixed) |
| `KEM/`        |     5 |   913 |       24 |   11 |          2 |
| `KeyMgmt/`    |     2 |   467 |    (mixed) |   (mixed) |    (mixed) |
| `Probability/` |    3 |   445 |       20 |    6 |          0 |
| `PublicKey/`  |     4 | 1,503 |    (mixed) |   (mixed) |    (mixed) |
| `Theorems/`   |     3 |   461 |    (mixed) |   (mixed) |    (mixed) |
| **Totals**    | **36** | **8,156** | **216** | **105** | **20** |

(Per-directory `theorem` / `def` totals where labelled "mixed" are
included in the global totals row but not broken out here to keep the
table compact; see the per-phase verification matrix above for the
detailed counts per file.)

The 342 declarations exercised by `scripts/audit_phase_16.lean` cover
every public `def`, `theorem`, `structure`, `class`, `instance`, and
`abbrev` under `Orbcrypt/**/*.lean`. This includes every headline
result a downstream consumer would care about (every phase, every
workstream) plus every supporting lemma, simp rule, typeclass
instance, and namespace-qualified field accessor.

---

## Known limitations (work unit 16.10d)

The Phase 16 audit confirms the *formalization-level* posture (zero
sorry, zero custom axiom). It does **not** discharge the cryptographic
assumptions themselves — those are carried as explicit hypotheses on
the conditional theorems. The following items are deliberate
limitations, each documented in source and tracked as future work:

1. **Deterministic OIA is vacuous — the deterministic chain is
   scaffolding, not a security claim.** `oia_implies_1cpa`,
   `kemoia_implies_secure`, and `hardness_chain_implies_security`
   carry `OIA`, `KEMOIA`, and `HardnessChain` as hypotheses. Each of
   these hypotheses quantifies over every Boolean distinguisher
   (including orbit-membership oracles like
   `decide (x = reps m₀)`), making the predicate **False on every
   non-trivial scheme** — the premise collapses under any scheme
   with distinct orbit representatives. Hence the deterministic
   headline theorems are vacuously true on production instances
   (proof by ex-falso) and serve as *algebraic scaffolding*:
   type-theoretic templates whose existence we verify, not
   standalone security guarantees. **As of the 2026-04-23 audit
   Workstream E (landed 2026-04-24), the vacuity is itself
   machine-checked**: `det_oia_false_of_distinct_reps` (rows #33
   above) proves `¬ OIA scheme` whenever
   `scheme.reps m₀ ≠ scheme.reps m₁`, and
   `det_kemoia_false_of_nontrivial_orbit` (row #34) proves
   `¬ KEMOIA kem` whenever the base-point orbit has cardinality ≥ 2.
   Both theorems depend only on the standard Lean trio and are
   **Standalone** citations. External prose that previously
   asserted "OIA is vacuous on every non-trivial scheme" as an
   informal claim can now cite the two Lean theorems as formal
   witnesses. The probabilistic counterparts
   (`ConcreteOIA(ε)`, `ConcreteKEMOIA_uniform(ε)`,
   `ConcreteHardnessChain scheme F S ε`) remain the positive
   security content — satisfiable for `ε ∈ (0, 1]` and carrying
   the quantitative bounds. See the "Release readiness" section
   below and `Orbcrypt.lean` § "Deterministic-vs-probabilistic
   security chains" for the release-messaging framing (Workstream
   J, audit finding H3).

2. **`GIReducesToCE` and `GIReducesToTI` are reduction *claims*, not
   proofs.** They are `Prop`-valued definitions that point at LESS /
   MEDS / Grochow-Qiao external research. Concrete discharge of the
   associated per-encoding reduction Props
   (`ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`,
   `ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding`,
   `ConcreteGIOIAImpliesConcreteOIA_viaEncoding`) via the CFI graph
   gadget or the structure-tensor encoding is a research-scope
   follow-up tracked in
   `docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 15.1. This
   is documented in `Orbcrypt.lean`'s axiom transparency report under
   "Hardness parameter Props".

3. **`indQCPA_from_perStepBound` carries `h_step` as a hypothesis.**
   The per-step bound is the marginal-independence step that would, in
   a complete probabilistic refinement, follow from `ConcreteOIA` plus
   a product-distribution argument over `uniformPMFTuple`. The
   atomic-bound shape lets any concrete marginal argument plug in
   later; this is tracked as Workstream E8b in the 2026-04-18 audit
   plan and as research milestone R-09 in the 2026-04-23 plan. The
   theorem was renamed from `indQCPA_bound_via_hybrid` by Workstream C
   of the 2026-04-23 audit (finding V1-8 / C-13 / D10) to surface the
   caller-supplied `h_step` obligation in the identifier itself per
   `CLAUDE.md`'s naming rule that identifiers describe what the code
   *proves*, not what it *aspires to*.

4. **`ObliviousSamplingHiding` is a strong deterministic
   pathological-strength predicate** that is not expected to hold for
   non-trivial bundles without a probabilistic refinement. The
   `oblivious_sampling_view_constant` corollary carries it as a
   hypothesis.

5. **`SessionKeyExpansionIdentity`** (renamed from
   `SymmetricKeyAgreementLimitation` in Workstream L4, audit
   F-AUDIT-2026-04-21-M5) is an unconditional structural identity
   exhibiting that the KEM agreement protocol's session key is a
   combiner applied to each party's secret `keyDerive ∘ canonForm.canon`
   output. This is a *decomposition identity* exposing the
   symmetric-setup dependency on both parties' secret state — *not* a
   standalone impossibility claim against public-key variants. Three
   candidate paths to public-key are formalised in
   `PublicKey/{ObliviousSampling,KEMAgreement,CommutativeAction}.lean`
   and analysed in `docs/PUBLIC_KEY_ANALYSIS.md`.

6. **`carterWegmanMAC_int_ctxt` is a satisfiability witness, not a
   production-grade MAC.** Post the L-workstream post-audit upgrade
   (2026-04-22), the Carter–Wegman MAC carries a machine-checked
   `(1/p)`-universal hash guarantee (`carterWegmanHash_isUniversal`)
   under the `[Fact (Nat.Prime p)]` constraint — the actual Carter–
   Wegman 1977 property.  However, `carterWegmanMAC_int_ctxt` remains
   a *deterministic* witness: it uses a fixed key and
   `decide`-equality verification rather than the probabilistic
   key-sampling required for Wegman–Carter 1981 SUF-CMA.  Producing a
   full SUF-CMA reduction from `IsEpsilonUniversal` is future work;
   the `(1/p)`-universal property proved here is the information-
   theoretic foundation that reduction builds on.  Production AEAD
   would compose `OrbitKEM` with HMAC or Poly1305 (probabilistic MAC
   refinement — future work).

7. **Multi-query KEM-CCA is not formalised.** `concrete_kemoia_implies_
   secure` and the uniform-form variant cover the no-decapsulation-
   oracle setting; CCA security with a decapsulation oracle would
   require a Decisional KEM-CCA game and a forking-lemma-style
   reduction, both out of scope for Phase 16.

8. **`ConcreteHardnessChain` at ε < 1 requires caller-supplied
   cryptographic witnesses.** Post-Workstream-G (audit
   F-AUDIT-2026-04-21-H1), the chain binds a `SurrogateTensor F`
   parameter (Fix B) and carries two explicit encoder fields
   `encTC`, `encCG` plus three per-encoding reduction Prop fields
   (Fix C). Non-vacuity at ε = 1 is witnessed by
   `tight_one_exists` via the `punitSurrogate F` and dimension-0
   trivial encoders. **For ε < 1**, the caller must supply:
   * A surrogate `S` whose TI-hardness is genuinely εT-bounded —
     typically a finite subgroup witness for GL³(F) (once Mathlib
     provides `Fintype (GL (Fin n) F)`).
   * Encoder functions `encTC, encCG` with proven advantage-transfer
     properties — the Cai–Fürer–Immerman graph gadget (1992) and the
     Grochow–Qiao structure-tensor encoding (2021) are the
     canonical candidates.
   Concrete formalisations of these witnesses are genuine research-
   scope items (requiring multi-week Lean proofs of combinatorial
   constructions), tracked in the audit plan § 15.1. They plug into
   the `*_viaEncoding` Props landed by Workstream G without further
   structural refactor.

9. **`ConcreteKEMHardnessChain` at ε < 1 requires a scheme-to-KEM
   reduction witness.** Post-Workstream-H (audit
   F-AUDIT-2026-04-21-H2, MEDIUM), the KEM-layer chain
   `ConcreteKEMHardnessChain scheme F S m₀ keyDerive ε` bundles a
   scheme-level Workstream-G chain with a
   `ConcreteOIAImpliesConcreteKEMOIAUniform scheme m₀ keyDerive ε ε`
   field. The scheme-to-KEM reduction is **not** a free algebraic
   consequence of `ConcreteOIA scheme ε`: the scheme-level predicate
   bounds the advantage between two *orbit distributions*, whereas
   the KEM uniform predicate bounds the advantage between a *uniform
   orbit distribution* and a *point mass on a specific orbit
   element*. Non-vacuity at ε = 1 is witnessed by
   `ConcreteKEMHardnessChain.tight_one_exists` via
   `concreteOIAImpliesConcreteKEMOIAUniform_one_right`. **For ε < 1**,
   the caller must supply a concrete scheme-to-KEM reduction witness
   at the specific `(m₀, keyDerive)` pair — typically under a
   random-oracle idealisation of `keyDerive`. Concrete formalisation
   of this witness is a research-scope follow-up parallel to item 8
   above and tracked in the audit plan § 15.1 alongside the encoder
   follow-ups.

10. **`authEncrypt_is_int_ctxt` orbit-cover — ~~vacuous on
    production HGOE~~ CLOSED.** Pre-2026-04-23 the theorem carried
    `hOrbitCover : ∀ c : X, c ∈ orbit G akem.kem.basePoint` as an
    explicit parameter, which is False on production HGOE where
    `|Bitstring n| = 2^n` strictly exceeds any orbit's cardinality
    by the orbit-stabiliser bound. **Workstream B of the 2026-04-23
    audit plan (landed 2026-04-24)** refactored `INT_CTXT` so the
    orbit condition is a *per-challenge well-formedness precondition*
    (a new `hOrbit` binder on the `INT_CTXT` game itself), not a
    theorem-level obligation. `authEncrypt_is_int_ctxt` now
    discharges `INT_CTXT` **unconditionally** on every
    `AuthOrbitKEM`; `CLAUDE.md`'s row #19 upgrades from
    **Conditional** to **Standalone**. Consumers wanting the
    stronger "INT-CTXT rejects out-of-orbit ciphertexts at
    decapsulation time" model should pair `INT_CTXT` with an
    explicit orbit-check — the canonical shape is Workstream **H**'s
    planned `decapsSafe` helper (audit plan § 9). Closed finding:
    V1-1 / I-03 / I-04 / D1 / D12.

11. **`TwoPhaseDecomposition` is empirically False on the default
    GAP fallback group.** `two_phase_correct` and
    `two_phase_kem_correctness` in
    `Optimization/TwoPhaseDecrypt.lean` carry
    `TwoPhaseDecomposition` as an explicit hypothesis; the module
    docstring self-discloses that on the default GAP fallback group
    (a wreath product of a QC-cyclic subgroup with a residual
    transversal) the hypothesis **does not hold** because lex-min
    and the residual transversal action don't commute. The actual
    GAP correctness story runs through `fast_kem_round_trip`
    (Theorem #26 in `CLAUDE.md`), which uses orbit-constancy of the
    fast canonical form instead of the strong "fast = slow"
    decomposition — orbit-constancy *is* satisfied by
    `FastCanonicalImage` whenever the cyclic subgroup is normal in
    G. Release-facing citations of production fast-decryption
    correctness should use `fast_kem_round_trip`, not
    `two_phase_kem_correctness` (audit 2026-04-23 finding V1-2 /
    L-03 / D2).

12. **`carterWegmanMAC_int_ctxt` is incompatible with HGOE's
    `Bitstring n` ciphertext space.** The Carter–Wegman MAC in
    `AEAD/CarterWegmanMAC.lean` is typed over `K = ZMod p × ZMod p`,
    `Msg = ZMod p`, `Tag = ZMod p`. Composing it with an HGOE
    `OrbitKEM G (Bitstring n) K` requires an `Bitstring n → ZMod p`
    adapter that maps a HGOE ciphertext into a MAC message while
    preserving the orbit structure that the composition theorem
    relies on. No such adapter is formalised in the current
    release. Consequently `carterWegmanMAC_int_ctxt` serves as a
    **satisfiability witness for `MAC.verify_inj` and for
    `INT_CTXT` non-vacuity** on the `ZMod p × ZMod p` toy
    composition; it is **not** a production AEAD construction for
    HGOE. Citations should use `carterWegmanHash_isUniversal` for
    standalone universal-hash claims. The `Bitstring n → ZMod p`
    adapter formalisation is tracked as research-scope R-13 in the
    2026-04-23 plan § 18 (audit 2026-04-23 finding V1-7 / D4 /
    I-08 / I-10).

These items are *known and documented*, not silent gaps. The
formalization is internally consistent: every conditional theorem
states its assumptions, every probabilistic predicate is satisfiable
at `ε = 1`, and no custom axiom or `sorry` short-circuits any proof.

---

## Release readiness (post-Workstream-G, H, J, K, and 2026-04-23 audit)

The 2026-04-21 audit's HIGH-severity finding (H1) is **closed** by
Workstream G; finding H2 (MEDIUM) is **closed** by Workstream H;
finding H3 (MEDIUM, release-messaging alignment) is **closed** by
Workstream J — this section *is* the deliverable for H3, and is
cross-referenced from `Orbcrypt.lean` § "Deterministic-vs-probabilistic
security chains" and from `CLAUDE.md`'s "Three core theorems" table
(which carries a **Status** column marking each theorem as
Standalone / Scaffolding / Quantitative / Structural); and finding
M1 (MEDIUM, distinct-challenge IND-1-CPA corollaries) is **closed**
by Workstream K, which adds four declarations that thread the
classical-game shape (`IsSecureDistinct`) through the downstream
chain — documented in-line on `oia_implies_1cpa_distinct` (K1),
`hardness_chain_implies_security_distinct` (K3),
`indCPAAdvantage_collision_zero` (K4), and
`concrete_hardness_chain_implies_1cpa_advantage_bound_distinct` (K4
companion).

The **2026-04-23 pre-release audit** surfaced eight
documentation-vs-code divergences at the Status-column level, all
remediated by Workstream **A** of that plan (release-messaging
reconciliation — this section is the Workstream-A deliverable for
V1-3 / V1-9 / audit finding X-01). Workstream **A** is
documentation-only and does not change any Lean content: it
reclassifies `CLAUDE.md` rows #19, #20, #24, #25 from **Standalone**
to **Conditional** with explicit hypothesis disclosures, adds a
**Release messaging policy** to `CLAUDE.md`'s Key Conventions
codifying the citation discipline, tightens the invariant-attack
narrative (row #2) to match the theorem's actual `∃ A :
Adversary X M, hasAdvantage scheme A` conclusion, and rewrites this
very "Release readiness" section with the per-citation class
discipline below. See
`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 4 for the
full Workstream-A specification.

**ε = 1 posture disclosure.** In the current formalisation the
probabilistic-chain theorems —
`concrete_hardness_chain_implies_1cpa_advantage_bound` at the
scheme level and
`concrete_kem_hardness_chain_implies_kem_advantage_bound` at the
KEM level — are inhabited **only at ε = 1**, via the trivial
`ConcreteHardnessChain.tight_one_exists` /
`ConcreteKEMHardnessChain.tight_one_exists` witnesses (`punitSurrogate
F` + dimension-0 trivial encoders). **ε < 1 requires caller-supplied
surrogate + encoder witnesses with genuine cryptographic hardness**;
concrete formalisations of these witnesses are research-scope
follow-ups (R-02 / R-03 / R-04 for the scheme-level chain; R-05 for
the KEM-layer chain — see the 2026-04-23 plan § 18 / Workstream O).
Release-facing citations that invoke these theorems **must** include
the phrase "inhabited only at ε = 1 via the trivial `tight_one_exists`
witness in the current formalisation" whenever a non-trivial
ε-bound is not accompanied by a concrete hardness witness. This
discipline is codified in `CLAUDE.md`'s Release messaging policy.

**Summary for external consumers.** Orbcrypt's formalization carries
two parallel chains. The *deterministic* chain's headline theorems
(`oia_implies_1cpa`, `kemoia_implies_secure`,
`hardness_chain_implies_security`) are vacuously true on every
production scheme — they are **scaffolding**, not security claims, and
should be cited only in the context of the type-theoretic structure
that they exemplify. The *probabilistic* chain
(`concrete_oia_implies_1cpa`,
`concrete_hardness_chain_implies_1cpa_advantage_bound`,
`concreteKEMHardnessChain_implies_kemUniform`,
`concrete_kem_hardness_chain_implies_kem_advantage_bound`) carries the
**quantitative** security content, subject to caller-supplied hardness
witnesses (surrogate, encoders, scheme-to-KEM reduction) as enumerated
in "Known limitations" items 8 and 9.

The formalization's public release posture (detailed):

1. **Deterministic chain** (Phases 3, 4, 7, 10, 12). Built from
   `Prop`-valued OIA variants (`OIA`, `KEMOIA`, `TensorOIA`, `CEOIA`,
   `GIOIA`). Each quantifies over every Boolean distinguisher,
   including orbit-membership oracles, and is **False on every
   non-trivial scheme**. Consequently the deterministic headline
   theorems (`oia_implies_1cpa`, `kemoia_implies_secure`,
   `hardness_chain_implies_security`) are vacuously true on
   production instances. They are **algebraic scaffolding** — type-
   theoretic templates whose existence we verify, not standalone
   security claims. External release claims that cite them should be
   framed as "the scheme's type-theoretic structure admits an
   OIA-style reduction argument".

2. **Probabilistic chain** (Phase 8, Workstream E, Workstream G).
   Built from `ConcreteOIA`, `ConcreteKEMOIA_uniform`,
   `ConcreteHardnessChain`, etc. After Workstream G's Fix B + Fix C:
   * `ConcreteHardnessChain scheme F S ε` binds a `SurrogateTensor F`
     parameter explicitly, preventing the pre-G PUnit collapse.
   * Three per-encoding reduction Props name concrete encoder
     functions; the chain's ε-parameter reflects the caller's
     surrogate and encoder choices.
   * At ε = 1 the chain is inhabited via `tight_one_exists` (PUnit
     surrogate + trivial encoders).
   * At ε < 1 the chain is inhabited only by caller-supplied
     surrogate + encoder pairs with genuine hardness — typically
     deriving from research-scope discharges.
   This is the **substantive security content**. External release
   claims of the form "Orbcrypt achieves ε-bounded IND-1-CPA under
   TI-hardness of surrogate S and reductions via encoders (encTC,
   encCG)" should cite `concrete_hardness_chain_implies_1cpa_advantage_bound`.

3. **KEM-layer chain** (Workstream H, finding H2). The chain lifts
   to the KEM layer via `ConcreteKEMHardnessChain scheme F S m₀
   keyDerive ε`, which bundles a scheme-level Workstream-G chain
   with a `ConcreteOIAImpliesConcreteKEMOIAUniform scheme m₀
   keyDerive ε ε` field (the abstract scheme-to-KEM reduction Prop).
   Two composition theorems expose the chain's content:
   * `concreteKEMHardnessChain_implies_kemUniform` delivers the
     probabilistic KEM-OIA predicate `ConcreteKEMOIA_uniform
     (scheme.toKEM m₀ keyDerive) ε`.
   * `concrete_kem_hardness_chain_implies_kem_advantage_bound`
     composes that further with `concrete_kemoia_uniform_implies_
     secure` to deliver the end-to-end KEM adversary bound
     `kemAdvantage_uniform (scheme.toKEM m₀ keyDerive) A g_ref ≤ ε`
     for every adversary and every reference encapsulation — the
     KEM-layer parallel of the scheme-level
     `concrete_hardness_chain_implies_1cpa_advantage_bound`.
   This replaces the pre-H pattern (where KEM consumers had to
   assemble the scheme-to-KEM step by hand) with a single structure
   parameterised by the KEM's anchor and key-derivation choice. The
   scheme-to-KEM reduction Prop at `ε < 1` is a research-scope
   discharge (typically via random-oracle idealisation of `keyDerive`);
   the chain is inhabited at ε = 1 via
   `ConcreteKEMHardnessChain.tight_one_exists`.

4. **What to cite externally.** The release-messaging policy in
   `CLAUDE.md` groups permitted citations into four Status classes;
   this list maps each class onto concrete theorem citations from
   the extended headline table above.

   **(a) Unconditional / Standalone.** Safe to cite directly;
   carries no hypothesis beyond the obviously-true structural data
   of the scheme / KEM / AEAD / MAC.
   * `correctness` — scheme correctness (`Theorems/Correctness.lean`).
   * `kem_correctness` — KEM correctness (`KEM/Correctness.lean`,
     proof by `rfl`).
   * `aead_correctness` — authenticated KEM correctness
     (`AEAD/AEAD.lean`).
   * `authEncrypt_is_int_ctxt` — INT-CTXT for every `AuthOrbitKEM`
     (`AEAD/AEAD.lean`). Post-2026-04-23 Workstream B, this
     discharges `INT_CTXT` unconditionally: the orbit condition is
     now a per-challenge well-formedness precondition on the game
     itself, not a theorem-level obligation. Safe to cite as
     "Orbcrypt AEAD has machine-checked ciphertext integrity: no
     adversary can forge an in-orbit `(c, t)` pair that both lies
     in `orbit G basePoint` and decapsulates with a fresh tag not
     produced by the challenger". Consumers wanting the stronger
     "out-of-orbit ciphertexts are actively rejected at
     decapsulation" model should pair this with Workstream **H**'s
     planned `decapsSafe` helper.
   * `hybrid_correctness` — KEM+DEM hybrid encryption correctness
     (`AEAD/Modes.lean`).
   * `seed_kem_correctness` — seed-based KEM correctness
     (`KeyMgmt/SeedKey.lean`).
   * `nonce_encaps_correctness` / `nonce_reuse_leaks_orbit` — nonce-
     based encryption correctness plus the formal warning theorem
     (`KeyMgmt/Nonce.lean`).
   * `kem_agreement_correctness` / `csidh_correctness` /
     `comm_pke_correctness` — public-key extension results
     (`PublicKey/*.lean`).
   * `invariant_attack` — vulnerability analysis. The theorem's
     formal conclusion is `∃ A : Adversary X M, hasAdvantage scheme
     A` (existence of **one** distinguishing adversary on a specific
     `(g₀, g₁)` pair); the informal "complete break under a
     separating G-invariant" shorthand is allowed but must be
     accompanied by the formal conclusion when the citation is
     release-facing. Quantitative probabilistic lower bounds on the
     cross-orbit advantage are research-scope R-01.
   * `carterWegmanHash_isUniversal` — the standalone `(1/p)`-universal
     hash theorem over `ZMod p` with `[Fact (Nat.Prime p)]` (post
     Workstream L2 upgrade). This is the Carter–Wegman 1977 property
     and is the correct citation for "universal-hash" claims; do
     **not** cite `carterWegmanMAC_int_ctxt` when the intent is a
     standalone universal-hash claim (that row is Conditional — see
     class (c) below).

   **(b) Quantitative (probabilistic chain).** Cite only with an
   explicit ε bound and the surrogate / encoder / keyDerive
   profile the caller is using. In the current formalisation
   these are inhabited **only at ε = 1** via trivial
   `tight_one_exists` witnesses; concrete ε < 1 discharges are
   research-scope R-02 / R-03 / R-04 / R-05.
   * `concrete_oia_implies_1cpa` (`Crypto/CompSecurity.lean`) —
     `ConcreteOIA(ε) → IND-1-CPA advantage ≤ ε`. Satisfiable at
     ε ∈ [0, 1]; the `ε = 0` form follows from deterministic OIA via
     `det_oia_implies_concrete_zero` but that bridge is itself
     Scaffolding because deterministic OIA is False.
   * `comp_oia_implies_1cpa` — asymptotic variant with negligible
     advantage, conditional on `CompOIA`.
   * `concrete_kemoia_uniform_implies_secure` — KEM-layer ε-smooth
     probabilistic bound (`KEM/CompSecurity.lean`).
   * `concrete_hardness_chain_implies_1cpa_advantage_bound` — the
     **primary scheme-level release citation**. Composes the
     Workstream-G chain with `concrete_oia_implies_1cpa` to deliver
     `IND-1-CPA advantage ≤ ε` under TI-hardness of a caller-supplied
     `SurrogateTensor F` and caller-supplied encoders `encTC, encCG`.
     **ε = 1 disclosure required** (see § "ε = 1 posture
     disclosure" at the top of this section).
   * `concreteKEMHardnessChain_implies_kemUniform` and
     `concrete_kem_hardness_chain_implies_kem_advantage_bound`
     (Workstream H) — **primary KEM-layer release citations**.
     The second composes the chain with
     `concrete_kemoia_uniform_implies_secure` to deliver
     `kemAdvantage_uniform ≤ ε` for every KEM adversary and every
     reference encapsulation. **ε = 1 disclosure required.**
   * `concrete_hardness_chain_implies_1cpa_advantage_bound_distinct`
     (Workstream K4 companion) — classical IND-1-CPA distinct-
     challenge form of the probabilistic chain bound. Retains the
     full Workstream-G / Workstream-A quantitative content; the
     distinctness hypothesis is carried for literature-signature
     parity but unused in the proof (`indCPAAdvantage_collision_zero`
     shows collision branches yield advantage 0). **ε = 1 disclosure
     required.**
   * `indCPAAdvantage_collision_zero` (Workstream K4) — unconditional
     structural lemma: the probabilistic IND-1-CPA advantage
     vanishes on collision-choice adversaries. Cite this to
     justify why the uniform-game bound transfers to the classical
     distinct-challenge game for free. This one is **Standalone**
     in classification; listed here because it composes with the
     Quantitative bounds.

   **(c) Conditional (hypothesis-carrying; cite with the condition
   made explicit).** These theorems are genuine machine-checked
   results but their usefulness on production instances depends on
   discharging a non-trivial hypothesis.
   * ~~`authEncrypt_is_int_ctxt` (class (c) Conditional)~~ **Moved
     to class (a) Standalone by Workstream B of the 2026-04-23 audit
     plan, landed 2026-04-24.** See the (a) entry below.
   * `carterWegmanMAC_int_ctxt` (`AEAD/CarterWegmanMAC.lean`) —
     **requires `X = ZMod p × ZMod p` ciphertext space** and is
     **incompatible with HGOE's `Bitstring n`** without an
     `Bitstring n → ZMod p` adapter (research-scope R-13). This
     theorem is a **satisfiability witness for `MAC.verify_inj`
     and for `INT_CTXT` non-vacuity**; it does not compose directly
     with the concrete HGOE construction. Cite
     `carterWegmanHash_isUniversal` instead for standalone
     universal-hash claims (class (a) above).
   * `two_phase_correct` / `two_phase_kem_correctness`
     (`Optimization/TwoPhaseDecrypt.lean`) — fast-decryption
     conditionals **under `TwoPhaseDecomposition`**, which is
     **empirically false on the default GAP fallback group** (lex-
     min and the residual transversal action don't commute; self-
     disclosed in the module docstring). Cite only for the strong-
     agreement property they document; for production-correctness
     citations use `fast_kem_round_trip` (Theorem #26 in `CLAUDE.md`,
     the orbit-constancy route that IS the actual GAP correctness
     argument).
   * `oblivious_sample_in_orbit` (`PublicKey/ObliviousSampling.lean`)
     — carries a combine-closure hypothesis.
   * `indQCPA_from_perStepBound` (`Crypto/CompSecurity.lean`) —
     carries the per-step bound `h_step` as a **user-supplied
     hypothesis**; discharge from `ConcreteOIA` alone is research-
     scope R-09. Renamed from `indQCPA_bound_via_hybrid` in
     Workstream **C** of the 2026-04-23 audit plan (finding V1-8 /
     C-13) to surface the obligation in the identifier itself;
     citations pre- and post-rename must carry the `h_step`
     disclosure.

   **(d) Scaffolding (deterministic chain; cite only for
   type-theoretic structure, never as security claims).** These
   theorems carry OIA-variant hypotheses that are **False on every
   non-trivial scheme**, so the conclusion is vacuously true on
   production instances.
   * `oia_implies_1cpa` — deterministic scheme-level scaffolding.
   * `kemoia_implies_secure` — deterministic KEM-level scaffolding.
   * `hardness_chain_implies_security` — deterministic chain-level
     scaffolding.
   * `det_oia_implies_concrete_zero` — bridge lemma showing
     deterministic OIA would imply `ConcreteOIA 0`; vacuous in
     practice because the antecedent is False.
   * `oia_implies_1cpa_distinct` (Workstream K1) — classical
     IND-1-CPA signature for `oia_implies_1cpa`; inherits the same
     scaffolding status.
   * `hardness_chain_implies_security_distinct` (Workstream K3) —
     classical IND-1-CPA signature for
     `hardness_chain_implies_security`; inherits scaffolding status.
   Cite any of these to explain that "the scheme's type-theoretic
   structure admits an OIA-style reduction argument", **not** as
   standalone security claims. The Quantitative counterparts in
   class (b) carry the substantive security content.

5. **What NOT to cite externally.** The following citations, even
   when technically well-typed, **misrepresent the Lean content** if
   used as security claims.
   * Any class (d) **Scaffolding** theorem framed as a standalone
     security claim. `oia_implies_1cpa` and its siblings are
     vacuously true on every non-trivial scheme; framing them as
     "Orbcrypt is IND-1-CPA secure under the OIA" overstates the
     Lean content. Use the Quantitative class (b) counterparts
     instead.
   * Any class (b) **Quantitative-at-ε = 1** theorem cited **without
     the ε = 1 disclosure**. E.g., citing
     `concrete_hardness_chain_implies_1cpa_advantage_bound` as
     "Orbcrypt achieves ε-bounded IND-1-CPA under TI-hardness"
     without disclosing that the ε = 1 witness is trivial and
     ε < 1 requires research-scope witnesses is a policy violation.
   * Any class (c) **Conditional** theorem cited **without the
     hypothesis disclosure**. Post-Workstream-B (2026-04-24),
     `authEncrypt_is_int_ctxt` has moved from class (c) to class (a)
     — the orbit condition is now a per-challenge well-formedness
     precondition on the `INT_CTXT` game itself, so citations can
     drop the disclosure. The remaining class (c) theorems
     (`carterWegmanMAC_int_ctxt` HGOE incompatibility;
     `two_phase_correct` / `two_phase_kem_correctness`
     `TwoPhaseDecomposition`; `oblivious_sample_in_orbit` closure
     hypothesis; `indQCPA_from_perStepBound` `h_step` hypothesis)
     still require the hypothesis disclosure when cited.
   * `ConcreteHardnessChain scheme F (punitSurrogate F) 1` /
     `ConcreteKEMHardnessChain scheme F (punitSurrogate F) m₀
     keyDerive 1` — non-vacuity witnesses, not quantitative security
     claims. Citing the `tight_one_exists` inhabitant as evidence
     of "machine-checked TI-hardness" is a policy violation.
   * `ObliviousSamplingHiding` — self-disclosed as pathological-
     strength deterministic predicate (the `Prop`-level form is not
     expected to hold for non-trivial bundles without a
     probabilistic refinement, R-12).
   * `ConcreteKEMOIA` (point-mass form) — collapses on `[0, 1)`
     (advantage is 0 or 1 per pair); use the uniform-form
     `ConcreteKEMOIA_uniform` or
     `concrete_kemoia_uniform_implies_secure` instead.

---

## Phase 16 exit criteria checklist

The exit criteria from `docs/planning/PHASE_16_FORMAL_VERIFICATION.md`
§"Phase Exit Criteria":

- [x] (1) All Phase 7 theorems compile with zero sorry and zero
      custom axioms.
- [x] (2) All Phase 10 theorems compile with zero sorry.
- [x] (3) Phase 8 sorry count documented; all non-sorry theorems
      compile. *(The sorry count is zero — the planned placeholders
      were discharged by Workstream E.)*
- [x] (4) Axiom transparency report covers all new modules.
- [x] (5) `lake build Orbcrypt` succeeds with all new imports.
- [x] (6) CI passes on the branch (extended with Phase 16 audit script
      regression sentinel).
- [x] (7) All 11 original modules still build with unchanged axiom
      dependencies.
- [x] (8) `docs/VERIFICATION_REPORT.md` is complete (this document).

---

## Document history

* **2026-04-21** — Phase 16 verification report authored. Added
  `scripts/audit_phase_16.lean` (342 `#print axioms` checks spanning
  every public declaration in the source tree, plus non-vacuity
  witnesses for `kem_correctness`, `hybrid_correctness`,
  `aead_correctness`, `authEncrypt_is_int_ctxt`, `ConcreteKEMOIA` /
  `ConcreteKEMOIA_uniform` satisfiability, `hybrid_argument_uniform`,
  `uniformPMFTuple_apply`, and `ConcreteHardnessChain.tight_one_exists`).
  Extended `.github/workflows/lean4-build.yml` with the Phase 16
  audit-script regression sentinel (de-wraps Lean's multi-line
  axiom lists before parsing, so a custom axiom cannot hide on a
  continuation line). Appended a Phase 16 snapshot section to
  `Orbcrypt.lean`'s axiom transparency report.

* **2026-04-21 (Workstream G)** — Hardness-chain non-vacuity
  refactor (audit finding H1, HIGH). Landed Fix B (surrogate
  parameter) and Fix C (per-encoding reduction Props) together.
  `ConcreteHardnessChain` now carries a `SurrogateTensor F`
  parameter and two explicit encoder fields; three new
  `*_viaEncoding` per-encoding reduction Props are the primary
  reduction vocabulary. `tight_one_exists` inhabits the chain at
  ε = 1 via `punitSurrogate F` and dimension-0 trivial encoders;
  concrete ε < 1 discharges require caller-supplied hardness
  witnesses (research-scope, tracked at audit plan § 15.1). The
  "Known limitations" section gained item 8 describing the chain's
  ε-parameterisation; a new "Release readiness" section
  distinguishes deterministic-chain scaffolding from the
  substantively-quantitative probabilistic chain. Audit scripts
  extended with `#print axioms` for all new declarations; all
  emit only standard-trio axioms.

* **2026-04-22 (Workstream J)** — Release-messaging alignment
  (audit finding H3, MEDIUM). Documentation-only, no Lean source
  changes. Rewrote "Known limitations" item 1 to make the
  deterministic chain's scaffolding status explicit (previously
  only disclosed via cross-reference to `Crypto/OIA.lean`).
  Rewrote the "Release readiness" header with a one-paragraph
  summary aimed at external consumers, distinguishing
  **Scaffolding** (deterministic chain — `oia_implies_1cpa`,
  `kemoia_implies_secure`, `hardness_chain_implies_security`) from
  **Quantitative** (probabilistic chain —
  `concrete_hardness_chain_implies_1cpa_advantage_bound`,
  `concreteKEMHardnessChain_implies_kemUniform`,
  `concrete_kem_hardness_chain_implies_kem_advantage_bound`).
  Cross-referenced the new `Orbcrypt.lean` §
  "Deterministic-vs-probabilistic security chains" subsection (J1)
  and the new **Status** column in `CLAUDE.md`'s "Three core
  theorems" table (J3). Because the change is comment/markdown-only,
  `lake build` output, `#print axioms` outputs, the Phase 16 audit
  script, and CI posture are all unchanged.

* **2026-04-22 (Workstream K)** — Distinct-challenge IND-1-CPA
  corollaries (audit finding M1, MEDIUM). Added four axiom-free
  declarations closing the game-shape gap between the uniform-
  challenge `IsSecure` predicate used by the pre-K downstream
  theorems and the classical `IsSecureDistinct` game used in the
  literature. The new declarations:
  * `oia_implies_1cpa_distinct` (`Theorems/OIAImpliesCPA.lean`, K1)
    — deterministic scheme-level corollary composing
    `oia_implies_1cpa` with `isSecure_implies_isSecureDistinct`.
  * `hardness_chain_implies_security_distinct`
    (`Hardness/Reductions.lean`, K3) — chain-level parallel from
    `HardnessChain` to `IsSecureDistinct`.
  * `indCPAAdvantage_collision_zero` (`Crypto/CompSecurity.lean`,
    K4) — unconditional structural lemma: the probabilistic IND-1-
    CPA advantage vanishes on collision-choice adversaries.
    Formalises why the `concrete_oia_implies_1cpa` bound transfers
    from `Adversary` to the classical distinct-challenge game for
    free.
  * `concrete_hardness_chain_implies_1cpa_advantage_bound_distinct`
    (`Hardness/Reductions.lean`, K4 companion) — probabilistic
    chain bound restated in classical-game form. The distinctness
    hypothesis is carried as a release-facing signature marker and
    unused in the proof.
  K2 deliberately *omits* a `kemoia_implies_secure_distinct`
  corollary; the KEM game parameterises adversaries by group
  elements rather than messages, so no per-challenge collision gap
  exists at the KEM layer (extended docstring on
  `kemoia_implies_secure`). The transparency report, the vacuity
  map, CLAUDE.md's headline-theorem table (new row #30), and the
  Phase 16 audit script are updated alongside the Lean additions.
  All 38 modules build clean; the full Phase 16 audit script still
  emits only standard-trio axioms; the new declarations are
  axiom-free (K1, K3, K4) or depend only on the standard trio
  (K4 companion via `concrete_oia_implies_1cpa`).

* **2026-04-22 (Workstream L)** — Structural & naming hygiene
  (audit findings M2–M6, MEDIUM). Five sub-workstreams landed in
  a single patch release (`lakefile.lean` `0.1.5` → `0.1.6`):

  * **L1 (M2) — `SeedKey` witnessed compression.** Plan revised
    2026-04-22 to adopt option (b) (was option (a), the
    smallest-diff "honest API" compromise; vacated as leaving the
    compression claim uncertified). `Orbcrypt/KeyMgmt/SeedKey.lean`:
    the `SeedKey` structure now carries `[Fintype Seed]` and
    `[Fintype G]` at the structure level and a new field
    `compression : Nat.log 2 (Fintype.card Seed) <
    Nat.log 2 (Fintype.card G)`. All downstream theorems in
    `SeedKey.lean` and `Nonce.lean` threaded the new typeclasses;
    `OrbitEncScheme.toSeedKey` takes an `hGroupNontrivial :
    1 < Fintype.card G` hypothesis and discharges `compression`
    via `Nat.log_pos`. Non-vacuity witness added to
    `scripts/audit_phase_16.lean`: a concrete
    `SeedKey (Fin 2) (Equiv.Perm (Fin 3)) Unit` with
    `compression` discharged by `decide`, plus a bridge example.
    The plan's one-line option (b) sketch was dimensionally
    incorrect (`8 * Fintype.card Seed < log₂ (...)`); the
    implementation uses the bit-length form, matching the
    docstring's prose framing.

  * **L2 (M3) — Carter–Wegman universal-hash MAC (initial landing
    superseded by post-audit universal-hash upgrade, 2026-04-22).**

    *Initial landing (superseded).* `[NeZero p]` added to
    `carterWegmanHash` / `carterWegmanMAC` / `carterWegman_authKEM` /
    `carterWegmanMAC_int_ctxt` with a docstring "Naming note"
    disclaiming the universal-hash property.  This violated the
    **Security-by-docstring prohibition** (CLAUDE.md Key Conventions):
    an identifier named after a cryptographic primitive must prove
    the property, not disclaim it.

    *Post-audit upgrade (authoritative).* `[Fact (Nat.Prime p)]`
    replaces `[NeZero p]`.  New module
    `Orbcrypt/Probability/UniversalHash.lean` defines
    `IsEpsilonUniversal` (Carter–Wegman 1977 ε-universal
    pair-collision bound).  New theorem
    `carterWegmanHash_isUniversal` proves the CW linear hash family
    is `(1/p)`-universal over the prime field `ZMod p` — the actual
    security property the name promises.  Proof structure:
    `carterWegmanHash_collision_iff` (algebraic characterisation:
    collision ↔ `k.1 = 0`) + `carterWegmanHash_collision_card`
    (counting: collision set has cardinality `p`) +
    `probTrue_uniformPMF_decide_eq` (probability = card / total) =
    `(1/p)` bound.

    `scripts/audit_c_workstream.lean` migrates its INT-CTXT witness
    from (non-prime) `p = 1` to `p = 2`; `scripts/audit_phase_16.lean`
    gains non-vacuity witnesses for the universal-hash theorem at
    `p = 2` and `p = 3` (Fact auto-resolved) and the
    collision-iff / collision-card discharges.

  * **L3 (M4) — `RefreshIndependent` rename.**
    `Orbcrypt/PublicKey/ObliviousSampling.lean`:
    `RefreshIndependent` / `refresh_independent` renamed to
    `RefreshDependsOnlyOnEpochRange` /
    `refresh_depends_only_on_epoch_range`. Content is
    structural determinism, not cryptographic independence —
    rename reflects that.

  * **L4 (M5) — `SymmetricKeyAgreementLimitation` rename.**
    `Orbcrypt/PublicKey/KEMAgreement.lean`:
    `SymmetricKeyAgreementLimitation` /
    `symmetric_key_agreement_limitation` renamed to
    `SessionKeyExpansionIdentity` /
    `sessionKey_expands_to_canon_form`. Content is a `rfl`-level
    decomposition identity, not an impossibility claim — rename
    reflects that.

  * **L5 (M6) — `KEMOIA` redundant-conjunct removal.**
    `Orbcrypt/KEM/Security.lean`: `KEMOIA` now single-conjunct
    (orbit indistinguishability only). The removed second
    conjunct "key uniformity across the orbit" was
    unconditionally provable from `canonical_isGInvariant`, so
    it carried no assumption content. Pre-L5 `kem_key_constant`
    (extracting the second conjunct) **deleted**
    (no backwards-compat shim per CLAUDE.md); `kem_key_constant_
    direct` is the authoritative form. `kemoia_implies_secure`
    and `det_kemoia_implies_concreteKEMOIA_zero` updated to use
    `kem_key_constant_direct` and single-conjunct `hOIA` forward
    application.

  **Traceability.** Findings M2–M6 resolved. See
  `docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 7 for the
  specification; Appendix A for the finding-to-work-unit mapping.
  Every renamed declaration propagated through `Orbcrypt.lean`,
  `CLAUDE.md`, `DEVELOPMENT.md`, `docs/PUBLIC_KEY_ANALYSIS.md`,
  `docs/USE_CASES.md`, `docs/MORE_USE_CASES.md`, this report,
  `formalization/FORMALIZATION_PLAN.md`,
  `docs/planning/PHASE_13_PUBLIC_KEY_EXTENSION.md`, and the two
  audit scripts (`scripts/audit_phase_16.lean`,
  `scripts/audit_print_axioms.lean`).

  **Verification.** All 38 modules build clean post-Workstream-L;
  the Phase 16 audit script emits only standard-trio axioms; every
  new and renamed Workstream-L declaration is axiom-free or
  standard-trio-only; the new L1 non-vacuity witnesses elaborate
  on concrete instances.

* **2026-04-23 (Workstream M)** — Low-priority polish (audit
  findings L1–L8, LOW). Eight sub-items landed in a single
  additive release (no `lakefile.lean` version bump — M1 is a
  backwards-compatible universe generalisation; M2–M8 are
  docstring-only):

  * **M1 (L1) — `SurrogateTensor.carrier` universe polymorphism.**
    `Orbcrypt/Hardness/TensorAction.lean`: `carrier` generalised
    from `Type` (universe 0) to `Type u` via a module-level
    `universe u` declaration. The four typeclass-forwarding
    instances and every downstream consumer inherit the
    generalisation transparently — their existing `Type*`
    signatures already accepted a universe-polymorphic carrier.
    `punitSurrogate F` is explicitly pinned to
    `SurrogateTensor.{0} F` (returning a PUnit-based witness at
    `Type 0`) so the audit-script non-vacuity examples continue
    to elaborate without universe-metavariable errors. Callers
    wanting surrogates at higher universes supply their own
    `SurrogateTensor.{u} F` value.

  * **M2 (L2) — `hybrid_argument_uniform` docstring.**
    `Orbcrypt/Probability/Advantage.lean`: docstring now states
    explicitly that no `0 ≤ ε` hypothesis is carried on the
    signature, and that `ε < 0` makes `h_step` unsatisfiable (via
    `advantage_nonneg`) so the conclusion holds vacuously.
    Intended use case: `ε ∈ [0, 1]`.

  * **M3 (L3) — Deterministic-reduction existentials.**
    `Orbcrypt/Hardness/Reductions.lean`: docstrings of
    `TensorOIAImpliesCEOIA`, `CEOIAImpliesGIOIA`, and
    `GIOIAImpliesOIA` now disclose that their existentials admit
    trivial satisfiers and that the deterministic chain is
    *algebraic scaffolding*, not quantitative hardness transfer.
    Callers are pointed at the Workstream G per-encoding
    probabilistic counterparts (`*_viaEncoding`) for the
    non-vacuous ε-smooth form.

  * **M4 (L4) — Degenerate encoders in `GIReducesToCE` /
    `GIReducesToTI`.** `Orbcrypt/Hardness/CodeEquivalence.lean`
    and `Orbcrypt/Hardness/TensorAction.lean`: docstrings now
    disclose that both deterministic Karp-claim Props admit
    degenerate encoders because they state reductions at the
    *orbit-equivalence level*, not the advantage level.
    Quantitative hardness transfer at ε < 1 lives in the
    Workstream G probabilistic counterparts.

  * **M5 (L5) — Invariant-attack advantage framing.**
    `Orbcrypt/Theorems/InvariantAttack.lean`: `invariant_attack`
    docstring enumerates the three literature conventions
    (two-distribution, centred, deterministic) and documents
    that they agree on "complete break" but differ by a factor
    of 2 on intermediate advantages.

  * **M6 (L6) — `hammingWeight_invariant_subgroup` pattern
    cleanup.** `Orbcrypt/Construction/HGOE.lean`: the anonymous
    destructuring pattern `⟨σ, _⟩` replaced with a named binder
    `g` + explicit coercion `↑g : Equiv.Perm (Fin n)`.
    Proof-equivalent; Mathlib-idiomatic style. `#print axioms`
    unchanged.

  * **M7 (L7) — `IsNegligible` `n = 0` convention.**
    `Orbcrypt/Probability/Negligible.lean`: `IsNegligible`
    docstring now documents Lean's `(0 : ℝ)⁻¹ = 0` convention
    and its effect at `n = 0`. All in-tree proofs choose
    `n₀ ≥ 1` to side-step the edge case.

  * **M8 (L8) — `combinerOrbitDist_mass_bounds` negative
    example.** `Orbcrypt/PublicKey/CombineImpossibility.lean`:
    the docstring now includes a concrete negative example (two
    hypothetical messages sharing an orbit give advantage 0
    despite intra-orbit mass bounds), illustrating the
    information-theoretic gap between intra-orbit mass bounds
    and cross-orbit advantage lower bounds. The example is
    hypothetical because `reps_distinct` prohibits it at the
    scheme level.

  **Traceability.** Findings L1–L8 resolved. See
  `docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 8 for the
  specification; Appendix A for the finding-to-work-unit mapping.

  **Verification.** All 38 modules build clean post-Workstream-M
  (3,367 jobs, zero errors, zero warnings); the Phase 16 audit
  script emits only standard-trio axioms; `Nonempty
  (ConcreteHardnessChain scheme F (punitSurrogate F) 1)`
  continues to elaborate with the new universe-polymorphic
  `SurrogateTensor` via the `SurrogateTensor.{0}`-pinned
  `punitSurrogate`; public-declaration count unchanged
  (347, per Workstream K); no new `.lean` files.

* **2026-04-23 (Workstream N)** — Info hygiene (audit findings I1,
  I5, INFO). Two actionable sub-items landed in a single
  documentation-and-CI-comment-only pass (no `lakefile.lean`
  version bump; no Lean-source, audit-script, or public-API
  changes):

  * **N1 (I1) — Phase 15 version-bump documentation.** The
    Phase 15 landing commit (`540d187`, 2026-04-20) bumped
    `lakefile.lean` from `0.1.4` to `0.1.5` to capture the two
    new `Optimization/` modules (`QCCanonical.lean`,
    `TwoPhaseDecrypt.lean`), the three new headline theorems
    (#24 `two_phase_correct`, #25 `two_phase_kem_correctness`,
    #26 `fast_kem_round_trip`), their supporting declarations,
    and the Phase-15.3 post-landing orbit-constancy refactor
    that delivered theorem #26 and
    `fast_canon_composition_orbit_constant`. This bump was
    undocumented in the CLAUDE.md per-workstream version log,
    which jumped directly from Workstream E's `0.1.3 → 0.1.4`
    entry to Workstream L's `0.1.5 → 0.1.6` entry. N1 closes
    the log gap by adding a "Phase 15 (Decryption Optimisation
    Formalisation) has been completed" subsection between the
    Phase 14 and Phase 16 snapshots in `CLAUDE.md`, whose final
    bullet explicitly records the `0.1.4 → 0.1.5` bump
    rationale. The lakefile's current version (`0.1.6`) is
    unchanged.

  * **N5 (I5) — CI nested-block-comment disclaimer.**
    `.github/workflows/lean4-build.yml` "Verify no sorry" step
    gained an explicit disclaimer directly below the existing
    F-03 comment block. The disclaimer illustrates the
    non-greedy `/-.*?-/` regex's nested-comment failure mode
    with a concrete
    `/- outer /- inner sorry -/ still outer -/` example and
    directs maintainers to `lake build` (which uses Lean's own
    parser) as the ground-truth fallback whenever any future
    `.lean` source requires nested block comments. The optional
    engineering upgrade to a Perl recursive pattern is
    cross-referenced to
    `docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 15.3.

  * **N2 (I2), N3 (I3), N4 (I4) — no-action items.** The audit
    plan identifies three other INFO-class findings as
    self-disclosed and not requiring code changes:
    `TwoPhaseDecomposition`'s empirical-falsity caveat is
    already disclosed at theorem #25's docstring and in the
    Phase 15 section; `indQCPA_from_perStepBound`'s `h_step`
    hypothesis gap (renamed from `indQCPA_bound_via_hybrid` in
    Workstream C of the 2026-04-23 audit) is already tracked in
    `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § E8b and
    as research milestone R-09 of the 2026-04-23 plan;
    `scripts/setup_lean_env.sh` passed its audit with no
    findings.

  **Traceability.** Findings I1 and I5 resolved. See
  `docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 9 for
  the specification; Appendix A for the finding-to-work-unit
  mapping.

  **Verification.** No Lean sources, audit scripts, or public
  declarations are added, removed, or modified by Workstream
  N. All 38 modules continue to build clean; the Phase 16
  audit script output is unchanged; the CI's "Verify no sorry"
  step is unaffected (only its explanatory comment grew — the
  actual `perl -0777 -pe` strip-and-grep command is
  byte-identical); `lake build` is a no-op for comment-level
  edits to `.github/workflows/lean4-build.yml`. Public
  declaration count remains 347 (per Workstream K); no new
  `.lean` files.

* **2026-04-23 (Workstream A of the 2026-04-23 pre-release
  audit)** — Release-messaging reconciliation (audit findings
  V1-1 / V1-2 / V1-3 / V1-4 / V1-5 / V1-7 / V1-9, CRITICAL /
  HIGH via X-01; HIGH via I-03, L-03, E-10, J-12, D13, H-01,
  I-08). Documentation-only, no Lean source changes. Three
  surfaces are aligned with the Lean content:
  * **This report.** "Release readiness" section retitled to
    "Release readiness (post-Workstream-G, H, J, K, and
    2026-04-23 audit)" and extended with (a) a new "ε = 1
    posture disclosure" paragraph making the current-formalisation
    ε = 1 inhabitation posture explicit at the top of the
    section; (b) a rewritten "What to cite externally" subsection
    partitioned into four Status classes (Unconditional,
    Quantitative, Conditional, Scaffolding) with per-class
    citation discipline — the Quantitative class lists the
    `concrete_hardness_chain_implies_*` citations with the
    ε = 1 disclosure, the Conditional class explicitly catalogues
    `authEncrypt_is_int_ctxt`, `carterWegmanMAC_int_ctxt`,
    `two_phase_correct`, `two_phase_kem_correctness`,
    `oblivious_sample_in_orbit`, and `indQCPA_from_perStepBound`
    (renamed from `indQCPA_bound_via_hybrid` in Workstream C of
    the same audit) with their hypothesis disclosures; (c) a
    rewritten "What NOT
    to cite externally" subsection enumerating the specific
    misrepresentation patterns forbidden by the policy (Scaffolding-
    as-security, Quantitative-without-ε-disclosure, Conditional-
    without-hypothesis-disclosure, and `tight_one_exists` witnesses
    as security claims). "Known limitations" section gained
    three new items (10, 11, 12) documenting the
    `authEncrypt_is_int_ctxt` orbit-cover falsity on HGOE, the
    `TwoPhaseDecomposition` empirical failure on the default GAP
    fallback group, and the Carter–Wegman / HGOE incompatibility
    (respectively).
  * **`CLAUDE.md`.** New **"Release messaging policy
    (ABSOLUTE)"** entry in the Key Conventions section immediately
    after "Security-by-docstring prohibition". The policy codifies
    the four citation classes (Allowed Standalone / Allowed
    Quantitative / Conditional-with-disclosure / Scaffolding-for-
    structure-only), mandates the ε = 1 disclosure discipline for
    probabilistic-chain theorems, names the Status column as the
    canonical source of truth, and forbids prose that overclaims
    beyond the Lean content. "Three core theorems" table: rows
    #19 (`authEncrypt_is_int_ctxt`), #20 (`carterWegmanMAC_int_ctxt`),
    #24 (`two_phase_correct`), #25 (`two_phase_kem_correctness`)
    reclassified from **Standalone** to **Conditional** with
    explicit hypothesis / compatibility disclosures in the
    Significance column; row #2 (`invariant_attack`) restated so
    the Statement column matches the theorem's
    `∃ A, hasAdvantage scheme A` existential rather than the
    quantitative "advantage 1/2 / complete break" shorthand (the
    three-convention pointer to `Probability/Advantage.lean` is
    preserved). A new "2026-04-23 Pre-Release Audit" entry in
    Active development status documents the plan's fifteen
    workstreams and the status-tracker checkbox for **A** /
    **B** / ... / **N** / **O**.
  * **`Orbcrypt.lean`.** The "Vacuity map (Workstream E)" table's
    two primary-release-citation rows (for the scheme-level and
    KEM-level chain-implies-advantage-bound theorems) annotated
    with the ε = 1 / research-scope disclosure; four new rows
    added pairing the four reclassified `CLAUDE.md` Conditional
    rows with their hypotheses and their standalone siblings
    (V1-3 / audit finding M-04).
  * **`DEVELOPMENT.md`.** §7.1 (Hamming weight attack) gains an
    explicit necessary-but-not-sufficient statement (audit
    finding F-05); §8.2 (multi-query) gains a "Scope of the Lean
    bound" paragraph on the `h_step` user-hypothesis obligation
    (V1-8 / D10 / audit finding C-13; Workstream **C** of the
    2026-04-23 plan either discharges or renames); §8.5 (INT-CTXT)
    cross-links the planned Workstream **B** orbit-cover refactor
    and discloses the Carter–Wegman `X = ZMod p` / HGOE
    `Bitstring n` incompatibility as R-13 research (V1-7 / D4 /
    D1 / audit findings I-03 / I-08).

  **Traceability.** Pre-release findings V1-2, V1-3, V1-4, V1-5
  (already covered by Workstream L1's
  `SeedKey.compression` field), V1-7, V1-9 are resolved by
  Workstream A; V1-1 enters its interim "Conditional" posture
  pending Workstream B (which will upgrade row #19 to
  **Standalone** at merge). V1-6 (toolchain) and V1-8 (multi-query
  rename) remain open pending Workstreams D and C respectively.
  See `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 4
  for the workstream specification, § 20 for the release-
  readiness checklist, and § 21 for the validation log (zero
  erroneous findings).

  **Verification.** Workstream A is documentation-only. All 38
  modules continue to build clean; `#print axioms` output is
  unchanged; `scripts/audit_phase_16.lean` emits unchanged
  output (342 `#print axioms` checks + non-vacuity witnesses,
  all standard-trio-only — no new Lean declarations added).
  The zero-sorry / zero-custom-axiom posture, the 347 public-
  declaration count, and the module-dependency graph are all
  preserved. Patch version: `lakefile.lean` retains `0.1.6`.

* **2026-04-24 (Workstream B of the 2026-04-23 pre-release
  audit)** — `INT_CTXT` orbit-cover refactor (audit findings
  V1-1 / I-03 / I-04 / D1 / D12, HIGH). Source-level refactor of
  the `INT_CTXT` predicate and the `authEncrypt_is_int_ctxt` /
  `carterWegmanMAC_int_ctxt` theorems; documentation propagation to
  three surfaces; no new Lean modules.

  * **Source refactor (`Orbcrypt/AEAD/AEAD.lean`).** `INT_CTXT`
    acquires a per-challenge `hOrbit : c ∈ MulAction.orbit G
    akem.kem.basePoint` binder as the game's well-formedness
    precondition; out-of-orbit ciphertexts are rejected by the
    game itself rather than by a scheme-level orbit-cover
    assumption. `authEncrypt_is_int_ctxt` refactored to consume
    `hOrbit` from the `INT_CTXT` binder — no top-level
    `hOrbitCover` parameter remains. Private helpers
    `authDecaps_none_of_verify_false` (C2a) and
    `keyDerive_canon_eq_of_mem_orbit` (C2b) are **unchanged**.
    The module docstring gains an "INT_CTXT game-shape refinement"
    subsection.

  * **Source refactor (`Orbcrypt/AEAD/CarterWegmanMAC.lean`).**
    `carterWegmanMAC_int_ctxt` loses its `hOrbitCover` argument;
    the proof body becomes a direct application of
    `authEncrypt_is_int_ctxt (carterWegman_authKEM p kem)` with
    no threading.

  * **Audit-script updates (`scripts/audit_phase_16.lean`,
    `scripts/audit_c_workstream.lean`).** The trivial
    `AuthOrbitKEM` non-vacuity witness in `audit_phase_16.lean`
    now invokes `authEncrypt_is_int_ctxt trivialAuthKEM` with no
    arguments; `toyCarterWegmanMAC_is_int_ctxt` in
    `audit_c_workstream.lean` invokes `carterWegmanMAC_int_ctxt 2
    toyKEMZMod2` with no orbit-cover argument.
    `toyKEMZMod2_orbit_cover` is retained as a transitive-action
    witness but is no longer consumed by the post-B proof.

  * **Documentation surfaces.** This report: (a) headline table
    row #12 (`authEncrypt_is_int_ctxt`) upgraded from
    **Conditional** to **Standalone**; row #13
    (`carterWegmanMAC_int_ctxt`) refreshed (remains
    **Conditional** for the orthogonal HGOE compatibility caveat);
    (b) "Known limitations" item 10 rewritten as CLOSED — the
    orbit-cover falsity is no longer a limitation because the
    theorem no longer carries the falsifiable hypothesis; (c)
    "Release readiness" class (a) Standalone list gains an
    explicit `authEncrypt_is_int_ctxt` bullet; the class (c)
    Conditional bullet for `authEncrypt_is_int_ctxt` is removed
    (redirected to class (a)). `CLAUDE.md`: row #19 Status
    upgraded to **Standalone**; row #20 retains
    **Conditional**. `Orbcrypt.lean`: axiom-transparency report
    updated; Vacuity map row for `authEncrypt_is_int_ctxt`
    rewritten as CLOSED.

  **Traceability.** Audit findings V1-1, I-03, I-04, D1, D12
  resolved. See
  `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 5 for the
  workstream specification and § 5.6 for the exit criteria.

  **Verification.** `lake build` succeeds for all 38 modules post-
  refactor; `scripts/audit_phase_16.lean` emits only standard-trio
  axioms for every Workstream-B-touched declaration; the
  `toyCarterWegmanMAC_is_int_ctxt` end-to-end witness at `p = 2`
  over `ZMod 2` continues to elaborate, confirming the refactor
  preserves non-vacuous inhabitability. Public declaration count
  unchanged (no new or removed declarations; only the signatures of
  `INT_CTXT`, `authEncrypt_is_int_ctxt`, and
  `carterWegmanMAC_int_ctxt` change).

  **Patch version.** `lakefile.lean` bumped from `0.1.6` to
  `0.1.7` for Workstream B. The signature changes are API-breaking
  for downstream consumers — any user of `INT_CTXT` who previously
  introduced `intro c t hFresh` must now introduce
  `intro c t hOrbit hFresh` (one extra binder), and any caller of
  `authEncrypt_is_int_ctxt` / `carterWegmanMAC_int_ctxt` must drop
  their `hOrbitCover` argument.

* **2026-04-24 (Workstream C of the 2026-04-23 pre-release
  audit)** — Multi-query hybrid reconciliation (audit findings
  V1-8 / C-13 / D10, HIGH). Track-1 rename of the multi-query
  IND-Q-CPA theorem pair to surface the caller-supplied `h_step`
  hypothesis in the identifier itself per `CLAUDE.md`'s naming
  rule ("identifiers describe what the code *proves*, not what
  the code *aspires to*"); no content changes.

  * **Source rename (`Orbcrypt/Crypto/CompSecurity.lean`).**
    `indQCPA_bound_via_hybrid` → `indQCPA_from_perStepBound`;
    `indQCPA_bound_recovers_single_query` →
    `indQCPA_from_perStepBound_recovers_single_query`. Theorem
    bodies unchanged (rename is content-neutral). The main
    theorem's docstring gains a "Game shape" paragraph and
    "User-supplied hypothesis obligation" block with explicit
    discharge-template language; the module-docstring "Main
    results" list is extended with a pair of entries disclosing
    the `h_step` obligation and pointing at research milestone
    R-09 (per-coordinate marginal-independence proof over
    `uniformPMFTuple`, tracked in the 2026-04-23 plan's § 18).
    The old names are **not** retained as deprecated aliases
    (per `CLAUDE.md`'s no-backwards-compat rule).

  * **Audit-script updates (`scripts/audit_phase_16.lean`,
    `scripts/audit_e_workstream.lean`).**  `#print axioms`
    entries renamed in both scripts. `audit_phase_16.lean` gains
    five new non-vacuity `example` blocks in the
    `NonVacuityWitnesses` namespace exercising the renamed
    theorem: (1) a general-signature parameterised witness on an
    arbitrary scheme / adversary / per-step bound, (2) the
    audit-plan § C.2 template (parameterised) instantiated to
    Q = 2 / ε = 1 with the per-step bound discharged by
    `advantage_le_one`, (3) a parameterised Q = 1 regression
    sentinel fitting
    `indQCPA_from_perStepBound_recovers_single_query`, (4) a
    concrete Q = 2 / ε = 1 witness on `trivialScheme`
    (`Equiv.Perm (Fin 1)` acting on `Unit`) with a concrete
    `MultiQueryAdversary Unit Unit 2` — this exercises the
    full typeclass instance-elaboration pipeline (Group +
    Fintype + Nonempty + MulAction + DecidableEq) on a
    known-good input, which a parameterised witness does not —
    and (5) a concrete Q = 1 companion witness on the same
    concrete scheme firing
    `indQCPA_from_perStepBound_recovers_single_query`.

  * **Documentation surfaces.** This report: headline-results
    table row #23 renamed; the Phase 8 "Key theorems" bullet list
    renamed; "Known limitations" bullet #3 renamed with a
    Workstream-C cross-reference; "Release readiness" class (c)
    Conditional list and class (c)-citations-required list
    renamed; this Document-history entry added. `CLAUDE.md`:
    Phase 16 "Known limitations" bullet, Phase 8 Workstream-E8
    snapshot, Workstream-A §8.2 cross-reference, Workstream-N
    N3 (I3) callout, and the axiom-transparency exit-criteria
    block all renamed with historical pre-rename names preserved
    in the migration comments. `DEVELOPMENT.md`: §8.2 prose
    renamed throughout. `Orbcrypt.lean`: dependency listing,
    Vacuity map, axiom-transparency `#print axioms` block
    renamed; a new "Workstream C Snapshot" section at the end of
    the transparency report describes the remediation, consumer
    migration guidance, and research follow-up.

  **Traceability.** Audit findings V1-8, C-13, D10 resolved. See
  `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 6 for the
  workstream specification and § 6.5 for the exit criteria.

  **Verification.** `lake build` succeeds for all 38 modules
  post-rename; `scripts/audit_phase_16.lean` emits unchanged
  axiom outputs (only-standard-trio) for the two renamed
  theorems. The five new non-vacuity witnesses (three
  parameterised + two concrete) elaborate in CI. Public
  declaration count unchanged at 347. The zero-sorry /
  zero-custom-axiom posture is preserved; the 38-module total is
  unchanged (no new or removed modules).

  **Patch version.** `lakefile.lean` bumped from `0.1.7` to
  `0.1.8` for Workstream C. The rename is API-breaking (every
  downstream reference to `indQCPA_bound_via_hybrid` /
  `indQCPA_bound_recovers_single_query` must be updated to the
  new identifier); the patch bump is per `CLAUDE.md`'s
  version-bump discipline for API breaks. No new declarations;
  no semantic changes. The discharge of `h_step` from
  `ConcreteOIA scheme ε` alone remains research-scope R-09.

* **2026-04-24 (Workstream D of the 2026-04-23 pre-release
  audit)** — Toolchain decision + `lakefile.lean` hygiene (audit
  findings V1-6 / A-01 / A-02 / A-03, MEDIUM). **Build-
  configuration-only**, no Lean source files modified.

  * **Toolchain decision (D1).** `lean-toolchain` retains
    `leanprover/lean4:v4.30.0-rc1` under **Scenario C** of the
    audit plan — ship v1.0 off the release-candidate toolchain;
    defer stable-toolchain upgrade to v1.1 as a coordinated
    `lake update` + Phase-16 audit replay. No Mathlib-stable
    pairing is currently available against the project's
    `fa6418a8` Mathlib pin. Decision recorded in the new
    "Toolchain decision (Workstream D)" subsection of this
    report (after "How to reproduce the audit") and in
    `CLAUDE.md`'s Workstream-D snapshot.
  * **`lakefile.lean` comment metadata refresh (D2).** Stale
    "Last verified: 2026-04-14" comment updated to
    "Last verified: 2026-04-24"; a new "Toolchain posture"
    paragraph added after the "Compatible with" line recording
    the Scenario-C decision and cross-referencing the audit
    plan § 7 and this report's "Toolchain decision (Workstream
    D)" subsection. Reading `lakefile.lean` is now
    self-sufficient to understand the rc-toolchain choice
    without leaving the build configuration.
  * **`leanOption` pins (D3).** `lakefile.lean`'s
    `leanOptions` array extended from a single-entry
    `autoImplicit := false` to a three-entry array also pinning
    `linter.unusedVariables := true` (Lean core builtin with
    `defValue := true` — pinned defensively against a future
    toolchain default-flip) and `linter.docPrime := true` (Mathlib
    linter with `defValue := false`, explicitly excluded from
    Mathlib's standard linter set per
    `Mathlib/Init.lean:110` → issue #20560 — pinning to `true`
    enables a linter Mathlib leaves off, acting as a tripwire
    that prevents new primed identifiers without docstrings; the
    Orbcrypt source tree currently has zero primed declarations).
    See the "Toolchain decision (Workstream D)" subsection above
    for the per-linter default posture and the "docs/VERIFICATION_
    REPORT.md caveat" about `linter.docPrime` startup
    registration.

  **Documentation surfaces.** This report gains a new "Toolchain
  decision (Workstream D)" subsection (between "How to reproduce
  the audit" and "Headline results table"); Document history
  entry dated 2026-04-24 added here. `CLAUDE.md`: Workstream
  status tracker row for D checked off; Workstream-D snapshot
  appended after the Workstream-C snapshot. `Orbcrypt.lean`:
  axiom-transparency report footer gains a "Workstream D
  Snapshot (audit 2026-04-23, finding V1-6 / A-01 / A-02 / A-03)"
  section recording the build-configuration changes and the
  unchanged axiom-dependency posture.
  `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md`: V1-6
  release-gate checkbox ticked (§ 20.1); Workstream-D tracker
  updated with the landing date (§ 3 / Appendix B).

  **Traceability.** Audit findings V1-6 (toolchain decision
  recorded), A-01 (defensive linter options pinned at package
  level), A-02 (`lakefile.lean` metadata refresh), A-03
  (rc-vs-stable toolchain decision) resolved. See
  `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 7 for
  the workstream specification and § 7.4 for the exit criteria.

  **Verification.** `lake build` succeeds for all 3,367 jobs
  with zero warnings / zero errors on a forced rebuild
  (verified by touching `Orbcrypt/GroupAction/Basic.lean`
  and rerunning `lake build`); `scripts/audit_phase_16.lean`
  emits unchanged axiom output (every `#print axioms` result
  is either "does not depend on any axioms" or the standard-
  trio `[propext, Classical.choice, Quot.sound]`; zero
  `sorryAx`; zero non-standard axioms). The 38-module total is
  unchanged; the 347 public-declaration count is unchanged;
  the zero-sorry / zero-custom-axiom posture is preserved.

  **Patch version.** `lakefile.lean` bumped from `0.1.8` to
  `0.1.9` for Workstream D. Technically a build-configuration
  change does not require a patch bump by `CLAUDE.md`'s
  version-bump discipline (which is triggered by API breaks or
  new public declarations); however, the linter-configuration
  pin is a consumer-visible build setting, so the bump records
  the change in the version log. No Lean source files are
  modified; no new public declarations; the zero-sorry /
  zero-custom-axiom posture is preserved.

* **2026-04-24 (Workstream E of the 2026-04-23 pre-release
  audit)** — Formal vacuity witnesses (audit findings C-07 /
  E-06, HIGH). Two new axiom-free theorems land in existing
  modules, machine-checking vacuity claims that previously lived
  only in module docstrings.

  * **E1 — `det_oia_false_of_distinct_reps`.** Added at the
    bottom of `Orbcrypt/Crypto/OIA.lean`, after the existing
    `OIA` definition and its comprehensive documentation block.
    Refutes `OIA scheme` under the hypothesis
    `scheme.reps m₀ ≠ scheme.reps m₁` via the membership-at-
    `reps m₀` Boolean distinguisher
    (`fun x => decide (x = scheme.reps m₀)`) instantiated at
    identity group elements. The LHS `decide` evaluates to `true`
    by reflexivity; the RHS `decide` evaluates to `false` by the
    distinctness hypothesis; rewriting yields `true = false`,
    discharged by `Bool.true_eq_false_iff`. Typeclass context
    identical to `OIA`; no new imports. Standard-trio axiom
    dependency only.
  * **E2 — `det_kemoia_false_of_nontrivial_orbit`.** Added at
    the bottom of `Orbcrypt/KEM/Security.lean`, after
    `kemoia_implies_secure`. KEM-layer parallel of E1: refutes
    `KEMOIA kem` under `g₀ • kem.basePoint ≠ g₁ • kem.basePoint`
    via `fun c => decide (c = g₀ • kem.basePoint)`. Written
    against the post-Workstream-L5 single-conjunct `KEMOIA` form
    (no `.1` / `.2` destructuring). Standard-trio axiom
    dependency only.
  * **E3 — Vacuity-map upgrade + transparency report.**
    `Orbcrypt.lean`'s Vacuity map table is extended from two
    columns to three by adding "Machine-checked vacuity witness";
    rows #1–#2 (`OIA`, `KEMOIA`) point at E1 and E2, and the
    downstream rows (hardness chain, K-distinct corollaries,
    KEM-layer chain) note that they inherit the same witnesses
    via their upstream antecedents. Two new `#print axioms`
    cookbook entries land under a "Workstream E (audit
    2026-04-23, findings C-07 + E-06)" subsection; a new
    "Workstream E Snapshot" section is appended at the end of
    the transparency report.
  * **Audit script.** `scripts/audit_phase_16.lean` gains two
    new `#print axioms` entries (adjacent to the existing
    `#print axioms OIA` and `#print axioms KEMOIA` lines) and
    two concrete non-vacuity `example` bindings under the
    `NonVacuityWitnesses` namespace: a two-message
    `trivialSchemeBool` with `reps := id : Bool → Bool` under
    the trivial action of `Equiv.Perm (Fin 1)` on `Bool` (each
    orbit is a singleton, so `reps_distinct` holds and distinct
    reps discharge the E1 hypothesis by `decide`), and a
    `trivialKEM_PermZMod2` under the natural `Equiv.Perm (ZMod 2)`
    action on `ZMod 2` (where `Equiv.swap 0 1 • 0 = 1 ≠ 0 =
    1 • 0` discharges the E2 hypothesis). Both `example` blocks
    close their `¬ OIA` / `¬ KEMOIA` goals by direct term
    construction.

  **Documentation surfaces.** This report: headline-results
  table extended with rows #33 (`det_oia_false_of_distinct_reps`)
  and #34 (`det_kemoia_false_of_nontrivial_orbit`); "Known
  limitations" item 1 updated to note the vacuity is now
  machine-checked; this Document-history entry added.
  `CLAUDE.md`: headline-theorems table extended with rows #31
  and #32 (both **Standalone**); `#print axioms` exit-criteria
  list extended with E1 and E2 entries; Workstream status tracker
  row for E checked off; Workstream-E snapshot appended after the
  Workstream-D snapshot. `Orbcrypt.lean`: Vacuity map upgrade;
  new `#print axioms` subsection; Workstream-E Snapshot section
  appended at the end of the transparency report.
  `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 8.5
  Exit criteria section gains a "Closure status (2026-04-24)"
  subsection recording the landing; Appendix B Workstream tracker
  row for E marked **closed**.

  **Traceability.** Audit findings C-07 (HIGH, deterministic-
  OIA vacuity claimed only in prose) and E-06 (HIGH, deterministic-
  KEMOIA parallel) resolved. V1-11 release-gate item (§ 20.1)
  implicitly closed via the two theorem landings. See
  `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 8 for
  the workstream specification and § 8.5 for the closed exit
  criteria.

  **Verification.** `lake build` succeeds for all 38 modules
  (3,369 jobs — two new theorems add two build nodes); zero
  warnings / zero errors. `scripts/audit_phase_16.lean` emits
  only standard-trio or axiom-free outputs for every declaration
  (including the two new theorems and all four supporting fixture
  definitions); the two new `example` blocks elaborate and close
  their goals by direct term construction. The 38-module total is
  unchanged; public declaration count rises from 347 to 349; the
  Phase-16 `#print axioms` audit total rises from 342 to 344;
  the zero-sorry / zero-custom-axiom posture is preserved.

  **Patch version.** `lakefile.lean` bumped from `0.1.9` to
  `0.1.10` for Workstream E, triggered by the two new public
  declarations per `CLAUDE.md`'s version-bump discipline. Four
  supporting fixture declarations (one `MulAction` instance, one
  `OrbitEncScheme`, one `MulAction` alias, one `OrbitKEM`) land
  inside `scripts/audit_phase_16.lean` — the audit script is
  not part of `Orbcrypt.lean`'s public surface, so these do not
  count toward the public-declaration total.

* **2026-04-24 (Workstream F)** — Concrete `CanonicalForm` from
  lex-min (audit finding V1-10 / F-04, MEDIUM). Landed the
  `CanonicalForm.ofLexMin` constructor and the
  `hgoeScheme.ofLexMin` convenience wrapper so every downstream
  theorem that types `{can : CanonicalForm (↥G) (Bitstring n)}`
  now has a concrete Lean-side witness.

  **New module.** `Orbcrypt/GroupAction/CanonicalLexMin.lean`
  (the 40th `.lean` file under `Orbcrypt/`) defining:
  * `CanonicalForm.ofLexMin` — computable lex-min canonical-form
    constructor parametric over `[Group G] [MulAction G X]
    [Fintype G] [DecidableEq X] [LinearOrder X]`;
  * `orbitFintype` (F3a) — the `Fintype (MulAction.orbit G x)`
    instance inherited from `Set.fintypeRange`, since `orbit`
    is definitionally `Set.range`;
  * `mem_orbit_toFinset_iff` (F3a) — named alias for
    `Set.mem_toFinset` (which is already `@[simp]` in Mathlib, so no
    further `@[simp]` annotation is needed; the Orbcrypt-side name
    keeps explicit term-mode references readable);
  * `orbit_toFinset_nonempty` (F3a) — base-point-witness lemma
    for `Finset.min'`'s non-emptiness obligation;
  * `CanonicalForm.ofLexMin_canon` (`@[simp]`, F2) — unfolding
    lemma;
  * `CanonicalForm.ofLexMin_canon_mem_orbit` — restatement of
    `mem_orbit` at the `ofLexMin` level.

  **Supporting changes.**
  * `Orbcrypt/Construction/Permutation.lean` — adds
    `bitstringLinearOrder` (`@[reducible] def`, not a global
    instance) — a computable lex order on `Bitstring n` matching
    the GAP reference implementation's `CanonicalImage(G, x,
    OnSets)` convention exactly: bitstrings are compared via
    their support sets (sorted ascending position lists), with
    smaller-position-true winning. Implemented via
    `LinearOrder.lift' (List.ofFn ∘ (! ∘ ·))`, with
    `Bool.not_inj` discharging injectivity. The inverted-Bool
    composition transports Mathlib's `false < true` list-lex
    order to `true < false` on `Bitstring n`, yielding
    "leftmost-true wins" — definitionally identical to GAP's
    set-lex on sorted ascending support sets. Exposed as a `def`
    to avoid the diamond with Mathlib's pointwise
    `Pi.partialOrder`; callers bind it locally via `letI`.
  * `Orbcrypt/Construction/HGOE.lean` — adds
    `hgoeScheme.ofLexMin` (F4) and the companion `@[simp]`
    lemma `hgoeScheme.ofLexMin_reps`.
  * `Orbcrypt.lean` — imports
    `Orbcrypt.GroupAction.CanonicalLexMin` between the
    existing `Canonical` and `Invariant` entries; adds a
    Workstream-F snapshot section at the end of the axiom-
    transparency report.
  * `scripts/audit_phase_16.lean` — six new `#print axioms`
    entries (three in §1 GroupAction, three in §4 Construction),
    plus four non-vacuity `example` bindings under a new
    `## Workstream F non-vacuity witnesses` section:
    an explicit-LT lex-order direction check (bypassing the
    `Pi.preorder` diamond at the witness site), two
    `decide`-backed `CanonicalForm.ofLexMin.canon` evaluations
    on concrete `Bitstring 3` inputs (weight-2 orbit →
    `![true, true, false]` matching GAP's
    `CanonicalImage(S_3, {0, 1}, OnSets) = {0, 1}`; singleton
    orbit → identity), and a type-elaboration witness for
    `hgoeScheme.ofLexMin` at `G := ⊤ ≤ S_3`. Two new Mathlib
    imports (`Mathlib.Data.Fintype.Perm`,
    `Mathlib.Data.Fin.VecNotation`) supply
    `Fintype (Equiv.Perm (Fin 3))` and the `![...]` syntax at
    the witness sites.
  * `CLAUDE.md` — source-layout tree gains the
    `CanonicalLexMin.lean` entry; module-dependency graph
    extended with the Workstream-F node; Workstream status
    tracker row for F marked closed; Workstream-F snapshot
    appended after the Workstream-E snapshot.
  * `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 9.6
    Exit criteria gain a "Closure status (2026-04-24)"
    subsection; Appendix B Workstream tracker row for F marked
    **closed**.

  **Traceability.** Audit finding V1-10 / F-04 (MEDIUM,
  `hgoeScheme`'s `CanonicalForm` parameter has no constructed
  in-tree witness) is resolved. Every downstream theorem that
  types `{can : CanonicalForm (↥G) …}` now has a concrete
  construction available via `CanonicalForm.ofLexMin` (at any
  finite subgroup + computable linear order) or
  `hgoeScheme.ofLexMin` (specialised to `Bitstring n` under
  `bitstringLinearOrder`). See
  `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 9 for
  the workstream specification and § 9.6 for the closed exit
  criteria.

  **Verification.** `lake build` succeeds for all 40 modules
  (3,368 jobs) with zero warnings / zero errors.
  `scripts/audit_phase_16.lean` emits only standard-trio
  axioms (`propext`, `Classical.choice`, `Quot.sound`) for every
  Workstream-F declaration; none depends on `sorryAx` or a
  custom axiom. The four new non-vacuity `example` bindings
  elaborate and close their goals — three via `decide` and
  one via direct term construction. The module count rises
  from 39 to 40; public declaration count rises from 349 to
  358; the Phase-16 `#print axioms` audit total rises from
  373 to 382; the zero-sorry / zero-custom-axiom posture is
  preserved.

  **Patch version.** `lakefile.lean` bumped from `0.1.10` to
  `0.1.11` for Workstream F, triggered by the nine new public
  declarations per `CLAUDE.md`'s version-bump discipline.

* **2026-04-25 (Workstream G)** — λ-parameterised
  `HGOEKeyExpansion` (audit 2026-04-23 finding V1-13 / H-03 /
  Z-06 / D16, MEDIUM). Closes the pre-G "release-messaging gap
  on λ coverage" — pre-G prose advertised λ ∈ {80, 128, 192,
  256} security tiers per `docs/PARAMETERS.md` §2 and the
  Phase-14 sweep CSVs, but the Lean `HGOEKeyExpansion`
  structure hard-coded `group_large_enough : group_order_log
  ≥ 128` and was therefore instantiable only at λ = 128. The
  pre-G shape *under-constrained* λ ∈ {192, 256} (a λ = 256
  deployment received only the λ = 128 strength guarantee from
  the structure) and was *unsatisfiable* at λ = 80 (the
  literal `≥ 128` was strictly stronger than the λ = 80 group
  order).

  **G1.** `Orbcrypt/KeyMgmt/SeedKey.lean`: `HGOEKeyExpansion`
  gains a leading `lam : ℕ` parameter. The structure signature
  changes from `HGOEKeyExpansion (n : ℕ) (M : Type*)` to
  `HGOEKeyExpansion (lam : ℕ) (n : ℕ) (M : Type*)`; the
  `group_large_enough` field's type changes from the literal
  `group_order_log ≥ 128` to the λ-parameterised
  `group_order_log ≥ lam`. The Lean identifier is spelled `lam`
  rather than `λ` because `λ` is a reserved Lean token; named-
  argument syntax (`HGOEKeyExpansion (lam := 128) (n := 512)
  M`) gives access to the canonical name. Module / structure /
  field docstrings updated to disclose: (a) the spelling
  correspondence; (b) the lower-bound semantics (the Lean-
  verified `≥ lam` is a lower bound, not an exact bound;
  deployment chooses `group_order_log` per the §4 thresholds,
  often strictly above `lam`); (c) the cross-reference to
  `docs/PARAMETERS.md` §2.2.1 and the audit plan §10.

  **G2.** `scripts/audit_phase_16.lean`: a new "Workstream G
  non-vacuity witnesses" section under
  `§ 12 NonVacuityWitnesses` lands four `example` blocks, one
  per documented Phase-14 tier (`HGOEKeyExpansion 80 320 Unit`,
  `HGOEKeyExpansion 128 512 Unit`, `HGOEKeyExpansion 192 768
  Unit`, `HGOEKeyExpansion 256 1024 Unit`). Each witness
  exhibits a complete `HGOEKeyExpansion lam n Unit` value with
  all 11 fields discharged, including the critical
  `group_large_enough` field closed by `le_refl _` after
  choosing `group_order_log := lam`. A private helper
  `hammingWeight_zero_bitstring` (one `simp [hammingWeight]`
  body) is shared across all four witnesses to discharge
  Stage-4 weight-uniformity for the trivial all-zero `reps`
  function. Two regression examples land alongside: a field-
  projection check (`exp.group_large_enough :
  exp.group_order_log ≥ lam` on a free `lam`) and a
  λ-monotonicity negative example (`¬ (80 ≥ 192)`) documenting
  that the four tier-witnesses are **distinct** obligations,
  not one obligation with a sloppy bound.

  **G3.** `DEVELOPMENT.md §6.2.1` gains a paragraph at the top
  of the "HGOE.Setup(1^λ) — Detailed Pipeline" section cross-
  linking the prose specification to the λ-parameterised Lean
  structure and disclosing the spelling correspondence (`lam`
  ↔ `λ`). `docs/PARAMETERS.md §2.2.1` is a new "Lean cross-
  link — λ-parameterised `HGOEKeyExpansion`" subsection
  mapping each row of the §2.2 parameter table to its
  corresponding `HGOEKeyExpansion lam …` Lean witness;
  explicitly disclosing the lower-bound semantics and the
  Workstream-G fix to the pre-G λ-coverage gap.

  **Files touched.** `Orbcrypt/KeyMgmt/SeedKey.lean`,
  `scripts/audit_phase_16.lean`, `DEVELOPMENT.md`,
  `docs/PARAMETERS.md`, `Orbcrypt.lean` (Workstream-G snapshot
  appended at the end of the transparency report), `CLAUDE.md`
  (status-tracker checkbox, module-line note, change-log
  entry), `docs/VERIFICATION_REPORT.md` (this entry), and
  `lakefile.lean` (`version` bumped `0.1.11 → 0.1.12`).

  **Verification.** `lake build` succeeds for all 39 modules
  with zero warnings / zero errors. `scripts/audit_phase_16.
  lean` emits standard-trio-only axiom output for `#print axioms
  HGOEKeyExpansion` and for the new defensive `#print axioms
  hammingWeight_zero_bitstring` (the private helper used to
  discharge Stage-4 weight-uniformity for the four tier
  witnesses). All four non-vacuity `example`s elaborate cleanly
  with field discharges resolving via `le_refl _`, `decide`, or
  `simp`. The module count remains 39; public declaration count
  remains 358 (the structure gains a parameter, not a field);
  the Phase-16 `#print axioms` audit total rises from 382 to
  383 (the new line covers the audit-script-internal
  `hammingWeight_zero_bitstring` helper, ensuring CI surfaces
  any future helper regression that anonymous `example`s would
  otherwise hide); the zero-sorry / zero-custom-axiom posture
  is preserved; the standard-trio-only axiom-dependency posture
  is preserved.

  **Patch version.** `lakefile.lean` bumped from `0.1.11` to
  `0.1.12` for Workstream G — the `HGOEKeyExpansion` signature
  change (gaining a `lam : ℕ` parameter) is an API break
  warranting a patch bump per `CLAUDE.md`'s version-bump
  discipline.
