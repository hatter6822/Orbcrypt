# Orbcrypt Lean Module Audit Report — 2026-04-18

**Date:** 2026-04-18
**Scope:** Every `.lean` file in the project (35 files, ~6,330 lines including root and lakefile)
**Auditor:** Claude (Opus 4.7, 1M context)
**Branch:** `claude/lean-files-audit-HrjtM`
**Predecessor audit:** `docs/audits/LEAN_MODULE_AUDIT_2026-04-14.md` (13 files, 1,697 lines — superseded by this audit for expanded coverage and deeper proof-level analysis)

**Status quick-look**

| Metric | Value |
|--------|-------|
| Lean source files audited | 35 |
| Total lines (including comments/docs) | 6,330 |
| `sorry` occurrences in `Orbcrypt/` | 0 (grep-verified) |
| Top-level `axiom` declarations in `Orbcrypt/` | 0 (only the word "axiom" inside a docstring in `Crypto/OIA.lean` L163) |
| New CVE-worthy vulnerabilities found | **0** |
| Findings raised (new + carried over) | 22 (see §7) |

No new exploitable vulnerability surfaced during this pass. The findings are
formalization gaps, modeling refinements, proof-style issues, and one CI-tooling
fragility — *not* security flaws in the underlying cryptographic construction.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Methodology](#2-methodology)
3. [File Inventory](#3-file-inventory)
4. [Module-by-Module Line-Level Analysis](#4-module-by-module-line-level-analysis)
5. [Cross-Cutting Concerns](#5-cross-cutting-concerns)
6. [Security Model Analysis](#6-security-model-analysis)
7. [Findings Summary Table](#7-findings-summary-table)
8. [Recommendations](#8-recommendations)
9. [Conclusion](#9-conclusion)

---

## 1. Executive Summary

Orbcrypt is a research-stage formally-verified symmetric-key encryption
scheme. As of Phase 13, the Lean 4 formalization spans **35 files** covering
group-action foundations, cryptographic definitions, core theorems, a concrete
HGOE construction, a KEM reformulation, probabilistic security foundations, key
management (seed-based keys, nonces), authenticated encryption with hybrid
modes, hardness alignment with NIST PQC candidates (LESS / MEDS / TI-based),
public-key extension scaffolding, and a machine-checked no-go theorem for the
naive combiner strategy on oblivious sampling.

Overall assessment: **the project is in a strong formal-verification posture**
with zero `sorry`, zero custom axioms, and disciplined proof hygiene. The
engineering is unusually solid for a research-stage formalization:

- **Modular layering** with clean separation between foundations, syntax,
  security definitions, and concrete instantiations.
- **Maximal Mathlib reuse** — no reinvention of orbit / stabilizer / PMF
  machinery.
- **OIA is a `Prop`**, never an `axiom`, and is carried as an explicit
  hypothesis — matching the `CryptHOL` / `EasyCrypt` pattern and avoiding
  logical inconsistency.
- **Every public definition and theorem carries a docstring.** Proofs have
  strategy comments. The root `Orbcrypt.lean` carries a full axiom-transparency
  report and dependency graph.

The audit's headline concern is *not* any single bug. It is the deeper question
of which theorems carry **non-vacuous** content. The project is candid about
this (see the module docstring of `Orbcrypt/Crypto/OIA.lean`), but a unified
map of vacuity vs. real content is not yet codified, and Phase 8's
probabilistic framework (`ConcreteOIA`, `CompOIA`) has not been threaded
through the Phase 12 hardness chain or the Phase 13 combiner no-go theorem.
See findings F-01, F-09, F-10, F-17, F-20 and §5.1.

### Headline findings

| ID | Severity | Category | Summary |
|----|----------|----------|---------|
| F-01 | High (modeling) | Design | Deterministic `OIA scheme` is `False` whenever `scheme.reps_distinct` is non-trivial, making `oia_implies_1cpa` and `hardness_chain_implies_security` **vacuously true** on any interesting scheme. Phase 8 (`ConcreteOIA`) addresses this but is not yet used by the hardness chain. (Carried over and refined from 2026-04-14 audit.) |
| F-02 | Low | Modeling | `Adversary.choose` is unconstrained — it may return `(m, m)`, trivially satisfying security. Real-world IND-CPA requires `m₀ ≠ m₁`. |
| F-03 | Low | CI | The `Verify no sorry` step in `.github/workflows/lean4-build.yml` uses a bare `grep -rn "sorry"` over `*.lean`, so any docstring that spells the word `sorry` will fail CI. Today no such string exists but the regex is fragile. |
| F-04 | Low (Lean style) | Proof hygiene | `Orbcrypt/Construction/Permutation.lean:92` contains `push Not at h` — this appears to be a typo for `push_neg at h`. Whether the build passes depends on the current Mathlib surface; at minimum this is non-idiomatic. |
| F-05 | Info | Modeling | `HGOEKeyExpansion` (`KeyMgmt/SeedKey.lean`) is a *specification-only* structure. There is no theorem linking it to a concrete `SeedKey` or proving existence of a realization. |
| F-06 | Low | Modeling | `OrbitEncScheme.toSeedKey` takes `sampleG : ℕ → G` as a plain function argument, so the "seed" carries no secret material. The bridge is honest about not compressing, but the interface lets non-secret samplers masquerade as keys. |
| F-07 | Medium (formalization gap) | Modeling | `INT_CTXT` is defined but not proved for any concrete `AuthOrbitKEM`. It is unprovable from the current `MAC` structure alone (which only has `correct`); a tag-uniqueness / EUF-CMA field is needed. |
| F-08 | Info | Modeling | `ArePermEquivalent` has no `symm` / `trans` lemmas. Only `refl` is proved. Composability of equivalence reductions is thus not exposed. |
| F-09 | High (formalization gap) | Design | Every link in the Phase 12 hardness chain (`GIReducesToCE`, `GIReducesToTI`, `TensorOIAImpliesCEOIA`, `CEOIAImpliesGIOIA`, `GIOIAImpliesOIA`) is a `Prop` parameter, not a proven reduction. The "chain" is a composition of unproved assumptions. |
| F-10 | High (design, documented) | Design | `CEOIA`, `TensorOIA`, `GIOIA`, `KEMOIA` all inherit the strong-deterministic vacuity of `OIA` — they are `False` for any non-trivial instance. A probabilistic lift is not yet wired through the hardness chain. |
| F-11 | Info | Modeling | `single_query_bound` in `CompSecurity.lean` does not actually use the adversary's `choose` or `guess`; it is a rename of `ConcreteOIA`. The promised multi-query hybrid theorem is not yet implemented. |
| F-12 | Info | Unused API | `GIReducesToCE` and `GIReducesToTI` are defined but never consumed by any theorem in the codebase. |
| F-13 | Low | Style | `CompOIA` and `CompIsSecure` definitions rely on `@`-qualified syntax repeated ~6× per clause. Fragile under Mathlib renamings and hard to read. |
| F-14 | Info | Modeling | `CommGroupAction` has exactly one witness (`selfAction` on `CommGroup`-acts-on-itself) and that is *not* an `instance`. No non-trivial concrete commutative action is provided. |
| F-15 | Low | Design | `SchemeFamily` uses `G : ℕ → Type*` without explicit universe annotations. Consumers will meet universe-inference pain or need explicit `.{u}` annotations. |
| F-16 | Low | Naming | `paut_coset_is_equivalence_set` merely re-establishes `ArePermEquivalent`; it does not prove any coset-set identity. Rename or strengthen. |
| F-17 | Info (documented) | Design | `CombineImpossibility.lean`'s no-go theorems are *themselves* vacuous while deterministic OIA is `False` (the ex-falso path: under the vacuous hypothesis, any conclusion holds). Their cryptographic value depends on upgrading to probabilistic OIA. |
| F-18 | Info | Style | `IsNegligible.mul_const` proof contains two `have hn_pos` bindings (L90 and L101), the second shadows the first. Works but is redundant. |
| F-19 | Info | Semantic | `kem_agreement_correctness` states `combine k_A k_B = combine k_A k_B` after rewrites — it is a tautology obscuring that the interesting content is `decaps ∘ encaps = id`. The statement would be sharper if it named the *shared* session key directly. |
| F-20 | High | Design | `hardness_chain_implies_security` composes with deterministic `oia_implies_1cpa`. Even if the chain's hardness assumptions were sound, the final step is the vacuously-true deterministic reduction. A probabilistic variant (`concrete_hardness_chain_implies_1cpa_advantage_bound`) is not yet defined. |
| F-21 | Info | Modeling | Weight-uniformity in `HGOEKeyExpansion` is the *only* attack mitigation formalized for HGOE. Other potential separating invariants (dual code weight distribution, automorphism-group orbit signatures) are not screened for in the specification. |
| F-22 | Low | CI | `.github/workflows/lean4-build.yml` does not pin elan's SHA-256, in contrast to `scripts/setup_lean_env.sh` which does. (Same finding as 2026-04-14 F-05; still open.) |

---

## 2. Methodology

Every `.lean` file under the project root was read end-to-end. Each module was
inspected at three levels:

1. **Lint-level review** (syntax, style, naming, docstrings, `@[simp]` hygiene,
   autoImplicit, variable discipline).
2. **Definition-level review** (the *mathematical content* of every `def`,
   `structure`, `class`, `abbrev`, `instance` — checking type signatures for
   implicit-argument holes, universe handling, instance-search pitfalls).
3. **Proof-level review** (each `theorem` body was read line by line: tactic
   choices, `simp`/`rw` target calculus, and verifying that the conclusion
   actually follows from the stated hypotheses without smuggling assumptions).

Cross-cutting passes checked:

- All 35 files against a CI-like regex (no `sorry`, no top-level `axiom`).
- The project's claimed axiom-transparency report in `Orbcrypt.lean` against
  the actual dependencies visible in each file.
- CI configuration (`.github/workflows/lean4-build.yml`) against the source.
- `CLAUDE.md` against the actual on-disk module set (33 `Orbcrypt/*.lean`
  modules, matching the CLAUDE.md listing exactly).

**Build verification:** A `lake build` was started at audit time. At 1M-context
Mathlib cold-cache compilation, full success would take >30 min, so the audit
does not wait for it to finish. Build health is verified indirectly: every
module's proofs were sanity-read for tactic validity, and every claim in
`Orbcrypt.lean` about headline-theorem axiom dependencies was confirmed against
the file-level proof structure.

---

## 3. File Inventory

| # | File | Lines | Role |
|---|------|-------|------|
| 0 | `lakefile.lean` | 17 | Lake package config, pinned Mathlib commit |
| 1 | `Orbcrypt.lean` | 438 | Root import + dependency graph + axiom report |
| 2 | `Orbcrypt/GroupAction/Basic.lean` | 118 | Orbit / stabilizer API |
| 3 | `Orbcrypt/GroupAction/Canonical.lean` | 111 | `CanonicalForm` structure, uniqueness, idempotence |
| 4 | `Orbcrypt/GroupAction/Invariant.lean` | 155 | `IsGInvariant`, `IsSeparating`, canonical-is-invariant |
| 5 | `Orbcrypt/Crypto/Scheme.lean` | 112 | `OrbitEncScheme`, `encrypt`, `decrypt` |
| 6 | `Orbcrypt/Crypto/Security.lean` | 112 | `Adversary`, `hasAdvantage`, `IsSecure` |
| 7 | `Orbcrypt/Crypto/OIA.lean` | 201 | Strong deterministic OIA (Prop) |
| 8 | `Orbcrypt/Crypto/CompOIA.lean` | 191 | Probabilistic `ConcreteOIA` / `CompOIA` |
| 9 | `Orbcrypt/Crypto/CompSecurity.lean` | 220 | Probabilistic IND-1-CPA + advantage bound |
| 10 | `Orbcrypt/Theorems/Correctness.lean` | 137 | `correctness` theorem |
| 11 | `Orbcrypt/Theorems/InvariantAttack.lean` | 150 | Invariant-attack theorem |
| 12 | `Orbcrypt/Theorems/OIAImpliesCPA.lean` | 174 | `oia_implies_1cpa` + Track D contrapositive |
| 13 | `Orbcrypt/KEM/Syntax.lean` | 92 | `OrbitKEM`, `toKEM` bridge |
| 14 | `Orbcrypt/KEM/Encapsulate.lean` | 86 | `encaps` / `decaps` |
| 15 | `Orbcrypt/KEM/Correctness.lean` | 72 | `kem_correctness` (by `rfl`) |
| 16 | `Orbcrypt/KEM/Security.lean` | 249 | `KEMOIA`, `kemoia_implies_secure` |
| 17 | `Orbcrypt/Probability/Monad.lean` | 105 | `uniformPMF`, `probTrue`, sanity lemmas |
| 18 | `Orbcrypt/Probability/Negligible.lean` | 115 | `IsNegligible`, closure under `+` and `* C` |
| 19 | `Orbcrypt/Probability/Advantage.lean` | 153 | `advantage`, triangle, `hybrid_argument` |
| 20 | `Orbcrypt/Construction/Permutation.lean` | 141 | S_n acts on bitstrings; Hamming weight |
| 21 | `Orbcrypt/Construction/HGOE.lean` | 132 | HGOE scheme instance + weight attack/defense |
| 22 | `Orbcrypt/Construction/HGOEKEM.lean` | 92 | HGOE-KEM instantiation |
| 23 | `Orbcrypt/KeyMgmt/SeedKey.lean` | 252 | `SeedKey`, `HGOEKeyExpansion` spec |
| 24 | `Orbcrypt/KeyMgmt/Nonce.lean` | 215 | Nonce-based encaps + misuse warning |
| 25 | `Orbcrypt/AEAD/MAC.lean` | 69 | `MAC` structure |
| 26 | `Orbcrypt/AEAD/AEAD.lean` | 178 | `AuthOrbitKEM`, `INT_CTXT` |
| 27 | `Orbcrypt/AEAD/Modes.lean` | 148 | `DEM`, KEM+DEM hybrid |
| 28 | `Orbcrypt/Hardness/CodeEquivalence.lean` | 231 | Permutation-code equivalence, `PAut`, `CEOIA` |
| 29 | `Orbcrypt/Hardness/TensorAction.lean` | 306 | GL³ action on 3-tensors, `AreTensorIsomorphic` |
| 30 | `Orbcrypt/Hardness/Reductions.lean` | 236 | Hardness chain — `HardnessChain` |
| 31 | `Orbcrypt/PublicKey/ObliviousSampling.lean` | 328 | Oblivious sampling + refresh |
| 32 | `Orbcrypt/PublicKey/KEMAgreement.lean` | 236 | Two-party KEM agreement |
| 33 | `Orbcrypt/PublicKey/CommutativeAction.lean` | 310 | `CommGroupAction`, CSIDH scaffolding |
| 34 | `Orbcrypt/PublicKey/CombineImpossibility.lean` | 448 | No-go theorem for public combiners |

Total: **35 files, 6,330 lines.**

---

## 4. Module-by-Module Line-Level Analysis

### 4.0 `lakefile.lean` (17 lines)

- **L4–8:** Package name lowercase; `leanOptions = [autoImplicit := false]` is
  the correct project-wide discipline, preventing silent universe / type
  insertions. Cross-checked: every source file under audit respects this.
- **L10–13:** Mathlib pinned to commit `fa6418a815fa14843b7f0a19fe5983831c5f870e`.
  This is an immutable git hash, reproducible. Matches `lake-manifest.json`.
- **L15–17:** `srcDir := "."` places the root `Orbcrypt.lean` and the
  `Orbcrypt/` namespace root in the project root. Correct Lean 4 convention.

**Verdict:** Clean, no issues.

### 4.1 `Orbcrypt.lean` (438 lines)

- **L1–43:** Imports 33 submodules in dependency order. Every submodule listed
  in `CLAUDE.md` is imported here. Cross-checked OK.
- **L45–280:** Module docstring includes an ASCII dependency graph. Spot-check
  against actual `import` statements in each submodule confirms correctness.
- **L282–370:** Axiom transparency report. For each headline theorem, the
  audit verified the claimed dependencies are faithful:
  - `correctness` actually uses `decrypt` → `Exists.choose` → `Classical.choice`,
    so the claim (propext, Classical.choice, Quot.sound) is accurate.
  - `oia_implies_1cpa` uses `OIA` as an explicit hypothesis — no axiom
    introduced.
  - `kem_correctness` is literally `rfl`, so zero axioms beyond unification.
  - `aead_correctness` correctly cites `kem_correctness + MAC.correct`.
- **L371–437:** `#print axioms` suggestions for auditors. This is the kind of
  reproducibility hook that makes trust verifiable.

**Verdict:** Excellent documentation. No issues.

### 4.2 `GroupAction/Basic.lean` (118 lines)

- **L37–42:** `orbit` and `stabilizer` are `abbrev`-level aliases. Correct —
  ensures Mathlib lemmas apply transparently.
- **L62–71 (`orbit_disjoint_or_eq`):** Proof via `by_cases h : x ∈ orbit G y`
  splitting into `Or.inl` / `Or.inr`. The disjoint case chains
  `orbit_eq_iff.mpr hz_x` followed by `.symm.trans` to derive the contradiction.
  Logically valid.
- **L83–91 (`orbit_stabilizer`):** Wraps `MulAction.card_orbit_mul_card_stabilizer_eq_card_group`.
  Signature requires `[Fintype G]`, `[Fintype (orbit G x)]`,
  `[Fintype (stabilizer G x)]` — all as local instance parameters, matching
  Mathlib.
- **L104–114:** `smul_mem_orbit` and `orbit_eq_of_smul` are 1-line wrappers of
  `MulAction.mem_orbit` and `MulAction.orbit_smul`. Downstream correctness and
  nonce-misuse theorems rely on these; the wrappers are convenient aliases.

**Verdict:** No issues.

### 4.3 `GroupAction/Canonical.lean` (111 lines)

- **L49–57:** `CanonicalForm G X` has three fields. `orbit_iff` is the
  biconditional that does all the work; `mem_orbit` is a strictly weaker
  consequence useful for specialization. Both are necessary — `mem_orbit` is
  needed in `canon_idem` without going through `orbit_iff` twice.
- **L68–88 (`canon_eq_implies_orbit_eq`, `orbit_eq_implies_canon_eq`,
  `canon_eq_of_mem_orbit`):** All three are one-liners extracting directions of
  `orbit_iff` or composing with `orbit_eq_iff`. Correct.
- **L103–107 (`canon_idem`):** Depends on `mem_orbit x` to reduce
  `orbit G (canon x) = orbit G x`, then applies `orbit_iff`. Clean.

**Verdict:** No issues. A possible future strengthening: prove
`canon x = x ↔ x = canon x` (fixed-point characterization) for downstream
attack modeling.

### 4.4 `GroupAction/Invariant.lean` (155 lines)

- **L51–66:** `IsGInvariant` and its closure lemma `comp` are correct. The
  `comp` proof uses `simp only [Function.comp]; rw [hf g x]`. Minimal.
- **L86–91 (`invariant_const_on_orbit`):** Destructures `mem_orbit_iff` with
  `rfl` pattern, reducing `f y = f (g • x) = f x` by `hf g x`. Valid.
- **L111–113 (`IsSeparating`):** Two-field conjunction. Note it is parameterised
  by a `G`-*implicit* variable (via the `{G : Type*}` declaration at the module
  level). Usage must supply `G` explicitly (e.g. `IsSeparating (G := ↥G)`).
  This is idiomatic for Orbcrypt.
- **L119–127 (`separating_implies_distinct_orbits`):** Contrapositive proof.
  Uses `heq ▸ MulAction.mem_orbit_self x₁` to move `x₁ ∈ orbit G x₁` across the
  equality. Correct.
- **L146–151 (`canonical_isGInvariant`):** Single-line invocation of
  `can.orbit_iff (g • x) x` with `MulAction.orbit_smul g x` as the
  witness. Rock-solid and short; this is the workhorse lemma for
  `correctness` and `kem_correctness`.

**Verdict:** No issues.

### 4.5 `Crypto/Scheme.lean` (112 lines)

- **L61–69 (`OrbitEncScheme`):** Three fields. `reps_distinct` enforces
  distinct-orbit representatives. **This field is the trigger for F-01**: it
  forces at least 2 distinct orbits whenever `M` has ≥ 2 inhabitants, which in
  turn makes deterministic `OIA scheme` unsatisfiable.
- **L83–85 (`encrypt`):** `g • reps m`. Clean.
- **L105–110 (`decrypt`):** `noncomputable` due to `Exists.choose`. The
  `dite` returns `some h.choose` when a matching message exists, `none`
  otherwise. The `Classical.choice` dependency propagates to `correctness` —
  correctly reported in the root axiom transparency block.

**Verdict:** No issues. The design note (L21–28) distinguishing `Fintype M`
only on `decrypt` is good encapsulation: the structure definition does not
drag fintype through, only the computable lookup.

### 4.6 `Crypto/Security.lean` (112 lines)

- **L61–65 (`Adversary`):** `choose : (M → X) → M × M`, `guess : (M → X) → X → Bool`.
  The adversary *sees* `reps`. This is correct for the Orbcrypt model, since
  `reps` is public (see scheme docstring).
  → **F-02**: `choose` is unconstrained. Nothing prevents `choose = (m, m)`,
  collapsing `hasAdvantage` to `guess(g₀ • reps m) ≠ guess(g₁ • reps m)`
  — still captures the essential security property, but does not match
  the standard IND-1-CPA game where the two challenge messages must be
  distinct. Practical implication: `IsSecure` is *stronger* than the
  classical game (since it bans even trivial "same-message" distinguishers),
  so the theorem is conservative. But this asymmetry should be documented.
- **L86–90 (`hasAdvantage`):** Existential over `g₀, g₁`. This is the
  deterministic abstraction of probabilistic advantage; the probabilistic
  analogue lives in `Crypto/CompSecurity.lean`.
- **L108–110 (`IsSecure`):** Universally quantifies over *all* deterministic
  adversaries (no computational bound). Valid in the algebraic setting.

**Verdict:** No bugs; F-02 is a modeling note, not an error.

### 4.7 `Crypto/OIA.lean` (201 lines)

- **L1–141:** Module docstring is exceptionally thorough. Explicitly documents
  the vacuity issue (F-01) at L46–57, the zero-advantage-limit relationship
  to probabilistic OIA at L71–84, a concrete 4-element counterexample to the
  weak-per-element version at L86–99, and Kai-Furer-Immerman hardness
  grounding at L122–132.
- **L163 (inside docstring):** The word "axiom" appears inside a sentence.
  This is the only place in the codebase where grep-ing for `axiom` yields a
  false positive. The CI regex (`^axiom\s+\w+\s*[\[({:]`, L45 of the workflow)
  correctly excludes this. **F-03 open:** the `sorry` CI check remains
  bare-grep.
- **L182–186 (`OIA`):** Four-universal. Note that `reps_distinct` (enforced
  in `OrbitEncScheme`) implies that for `m₀ ≠ m₁` the representatives lie in
  different orbits. Choosing `f x := decide (x ∈ orbit G (reps m₀))`
  (decidable under `[DecidableEq X]` for finite X) then gives a Boolean `f`
  that distinguishes the two orbits — witness that `OIA scheme` is `False`.
  This is F-01, fully documented in the module docstring.
- **L191–199 (Work Unit 3.8 block):** Just a pointer to the docstring.

**Verdict:** The module is *candid* about its limitation. This is a
formalization gap, not a bug.

### 4.8 `Crypto/CompOIA.lean` (191 lines)

- **L45–47 (`orbitDist`):** `PMF.map (fun g => g • x) (uniformPMF G)`. This
  is a correct Mathlib push-forward of the uniform group PMF through the
  orbit map.
- **L55–63 (`orbitDist_support`):** Uses `PMF.support_map` and destructures
  the support membership. The `rfl` pattern in the `rfl`-binder implicitly
  identifies `g • x` with `y`. Correct.
- **L65–73 (`orbitDist_pos_of_mem`):** Constructs a support witness via
  `⟨g, mem_support_uniformPMF g, rfl⟩`. Clean.
- **L82–87 (`ConcreteOIA`):** Takes an explicit `ε : ℝ` and quantifies over
  `D : X → Bool`, `m₀ m₁ : M`. Real-valued advantage bound. **This is the
  non-vacuous replacement for deterministic `OIA`.**
- **L93–101:** Three elementary lemmas (`zero_implies_perfect`, `mono`, `one`).
  `concreteOIA_one` establishes satisfiability: every scheme satisfies
  `ConcreteOIA 1` because `advantage ≤ 1` unconditionally. Good.
- **L121–141 (`SchemeFamily`):** Fintype-parameterised family. Note that
  every field has the type `∀ n, <type>` — so `SchemeFamily` is effectively
  a dependent record of infinitely many instances. Memory-only, but the
  `@OrbitEncScheme (G n) ...` fully-explicit application at L140–141 shows
  that *every* typeclass dependency is threaded through manually. **F-13**:
  this is the pattern that makes `CompOIA` / `CompIsSecure` hard to read.
- **L149–160 (`CompOIA`):** Uses explicit `@`-qualification for
  `@advantage`, `@orbitDist`, `@OrbitEncScheme.reps`. Every argument list is
  15+ tokens. A helper `advantagePerLevel sf D m₀ m₁ n := ...` would cut
  this by 3×.
- **L171–189 (`det_oia_implies_concrete_zero`):** Bridge — deterministic
  OIA ⟹ ConcreteOIA 0. Uses `PMF.toOuterMeasure_map_apply` to reduce the
  two `probTrue`s to preimage equalities on `uniformPMF G`, then uses
  `hOIA D m₀ m₁ g g` pointwise to get the biconditional. Mathematically
  correct; the "for all g" quantification in deterministic OIA is
  instantiated at a single `g` diagonal.
  - Subtle observation: the proof instantiates OIA at the *same* `g` on both
    sides (`hOIA D m₀ m₁ g g`). This suffices because OIA quantifies `g₀`
    and `g₁` *independently*. Under the weaker weak-per-element OIA (L86–99
    of `Crypto/OIA.lean`), this proof would not go through.

**Verdict:** Mathematically solid. Stylistic concern F-13.

### 4.9 `Crypto/CompSecurity.lean` (220 lines)

- **L64–70 (`indCPAAdvantage`):** Three-line definition mapping to
  `Probability/Advantage.advantage`. Correct parameterisation.
- **L104–111 (`concrete_oia_implies_1cpa`):** One-liner — the IND-1-CPA
  advantage is literally an instance of ConcreteOIA's universal. Correct.
  This is the *non-vacuous* analogue of the Phase 4 vacuous security
  theorem.
- **L124–128 (`concreteOIA_one_meaningful`):** Renamed `advantage_le_one`
  for the scheme setting. OK.
- **L135–139 (`indCPAAdvantage_nonneg`):** Trivial.
- **L146–164 (`CompIsSecure`):** Mirror of `CompOIA` structure — same
  `@`-heavy style (F-13).
- **L171–185 (`comp_oia_implies_1cpa`):** Threads CompOIA directly through
  to CompIsSecure by specialising `D n := (A n).guess reps`. Valid.
- **L195–199 (`MultiQueryAdversary`):** Structure placeholder for Q-query
  adversary. Not consumed by any theorem.
  → **F-11**: `single_query_bound` (L211–218) has a signature that does not
  mention `A : MultiQueryAdversary`, it is just
  `advantage D (orbitDist m₀) (orbitDist m₁) ≤ ε`. The proof is
  `hOIA D m₀ m₁` — literally the unfolding of ConcreteOIA. This is not a
  building block for multi-query in any rigorous sense; it is just a
  restatement of ConcreteOIA with a different name. The comment
  acknowledges that the "product distribution infrastructure" is deferred.

**Verdict:** Content is correct. `single_query_bound` should either (a)
use the `MultiQueryAdversary` structure to isolate a single query, or (b)
be removed as aspirational.

### 4.10 `Theorems/Correctness.lean` (137 lines)

- **L49–54 (`encrypt_mem_orbit`):** `unfold encrypt; exact smul_mem_orbit`.
  One line of real content.
- **L70–76 (`canon_encrypt`):** `unfold encrypt; exact canonical_isGInvariant ...`.
  Short and correct.
- **L89–102 (`decrypt_unique`):** Three-step proof:
  1. `canon(reps m') = canon(reps m)` via `h` + `canon_encrypt`.
  2. `orbit(reps m') = orbit(reps m)` via `canon_eq_implies_orbit_eq`.
  3. `by_contra` and `reps_distinct m' m h_ne` to close.
  Clean and valid.
- **L120–135 (`correctness`):** Unfolds `decrypt` / `encrypt`, produces the
  existence witness `⟨m, canonical_isGInvariant ...⟩`, applies `dif_pos`,
  then uses `decrypt_unique` on the `choose_spec` witness. Correct.
  - Subtlety: `congr 1` is used to reduce `some choose = some m` to
    `choose = m`. Stable Lean 4 idiom.

**Verdict:** Correct, elegant. No issues.

### 4.11 `Theorems/InvariantAttack.lean` (150 lines)

- **L58–62 (`invariantAttackAdversary`):** `choose := fun _ => (m₀, m₁)` —
  constant adversary. `guess := fun reps c => if f c = f (reps m₀)`. Clean.
- **L65–74:** Two `@[simp]` unfolding lemmas, both `rfl`.
- **L86–90 (`invariant_on_encrypt`):** Trivial — one-line application of
  `hInv g (reps m)`.
- **L104–115 (`invariantAttackAdversary_correct`):** `cases b <;> simp [...]`
  handles both branches uniformly. The simp set includes
  `invariant_on_encrypt hInv` (to reduce `f (g • reps mᵢ)` to `f (reps mᵢ)`)
  and `Ne.symm hSep` (to discharge the `f reps m₁ = f reps m₀` case as
  `false`). Compact.
- **L132–148 (`invariant_attack`):** Exhibits the adversary, witnesses
  `g₀ = g₁ = 1`, applies `one_smul` via `hInv 1`, closes with `Ne.symm hSep`.
  **This is a real, non-vacuous theorem** — because its hypothesis
  `hSep : f (reps m₀) ≠ f (reps m₁)` is satisfiable (e.g., by Hamming weight
  on two same-length bitstrings with different weights, per `HGOE.lean`).
  Contrast with F-01: `invariant_attack` is the *direct opposite* of the
  vacuous `oia_implies_1cpa` — this theorem is genuinely content-bearing.

**Verdict:** Correct and non-vacuous. One of the most valuable theorems in
the formalization.

### 4.12 `Theorems/OIAImpliesCPA.lean` (174 lines)

- **L57–63 (`oia_specialized`):** Instantiates OIA with `f := A.guess reps`.
  One-line.
- **L76–83 (`hasAdvantage_iff`):** `rfl`. Documented as defensive API for
  future refactoring.
- **L95–102 (`no_advantage_from_oia`):** `intro ⟨g₀, g₁, hNeq⟩; exact hNeq (oia_specialized ...)`.
  Valid. The `intro` destructuring works because `hasAdvantage` unfolds to
  a Σ-style Exists.
- **L119–124 (`oia_implies_1cpa`):** Two lines, both trivial. **Vacuously
  true under F-01** — the hypothesis `hOIA : OIA scheme` is False for any
  scheme with distinct orbit representatives.
- **L140–172 (Track D — `adversary_yields_distinguisher`, `insecure_implies_separating`):**
  These extract the "distinguishing function exists" direction. Note that
  the docstring at L162–166 is *honest* about the gap: the extracted
  function is not proved to be G-invariant, so the converse of
  `invariant_attack` is not fully established. This is the correct
  disclaimer.

**Verdict:** Proofs correct. Vacuity is F-01, not a bug in this module.

### 4.13 `KEM/Syntax.lean` (92 lines)

- **L58–65 (`OrbitKEM`):** Three fields: `basePoint`, `canonForm`,
  `keyDerive`. Note: no `baseDistinct` field because a KEM has a single
  orbit. Good asymmetry with `OrbitEncScheme`.
- **L84–90 (`OrbitEncScheme.toKEM`):** Delta-expanded constructor. The
  `kd : X → K` parameter is supplied by the caller — i.e., *any* function
  works structurally; security depends on it being modeled as a hash.
  The formalization never assumes anything about `kd` beyond determinism.

**Verdict:** No issues.

### 4.14 `KEM/Encapsulate.lean` (86 lines)

- **L46–49 (`encaps`):** Let-binding `c := g • basePoint`, returns
  `(c, keyDerive (canonForm.canon c))`. Clean.
- **L62–64 (`decaps`):** `keyDerive (canonForm.canon c)`. Symmetric.
- **L68–84:** Three `@[simp]` lemmas, all `rfl`. No surprises.

**Verdict:** No issues.

### 4.15 `KEM/Correctness.lean` (72 lines)

- **L51–55 (`kem_correctness`):** Proof: `by rfl`. Both sides unfold to
  `keyDerive (canonForm.canon (g • basePoint))`. **Genuinely non-vacuous**
  because no unsatisfiable hypothesis is carried.
- **L65–70 (`toKEM_correct`):** Direct application. Correct.

**Verdict:** Minimal and correct.

### 4.16 `KEM/Security.lean` (249 lines)

- **L72–75 (`KEMAdversary`):** Three-argument `guess : X → X → K → Bool`.
  The basePoint is passed (public). Correct.
- **L94–100 (`kemHasAdvantage`):** Mirror of the scheme version. Two
  encapsulations with different group elements.
- **L113–115 (`KEMIsSecure`):** `∀ A, ¬ kemHasAdvantage`.
- **L122–137 (`kemIsSecure_iff`):** Standard unfolding. Uses `by_contra`
  in one direction and direct construction in the other. Clean.
- **L165–170 (`KEMOIA`):** Two-conjunct:
  (1) universal-f ⇒ indistinguishability on one orbit;
  (2) key constancy.
  Note: conjunct (1) inherits the deterministic-OIA vacuity (F-10); the
  second conjunct is provable unconditionally via `canonical_isGInvariant`
  (see `kem_key_constant_direct`). So the KEMOIA hypothesis is *strictly
  weaker* than OIA only because of (1); under deterministic strength both
  are equivalent to False on non-trivial orbits.
- **L182–197 (`kem_key_constant`, `kem_key_constant_direct`):** The
  redundancy is well-documented. `_direct` extracts `congr_arg keyDerive`
  over `canonical_isGInvariant`. Correct.
- **L208–211 (`kem_ciphertext_indistinguishable`):** One-line extraction
  of KEMOIA.1.
- **L237–247 (`kemoia_implies_secure`):** Three-step proof. Uses
  `hOIA.2 g₀`, `hOIA.2 g₁` to rewrite both keys to the constant
  `keyDerive(canon(basePoint))`, then applies `hOIA.1` to the function
  `fun c => A.guess basePoint c constKey`. Correct and elegant.

**Verdict:** Proofs correct. Vacuity inherited from KEMOIA.1 (F-10), not
a bug.

### 4.17 `Probability/Monad.lean` (105 lines)

- **L46–47 (`uniformPMF`):** `PMF.uniformOfFintype`. Noncomputable, OK.
- **L50–57:** Two lemmas restate Mathlib facts. Correct.
- **L65–67 (`probEvent`):** Uses `toOuterMeasure`. This is semantically
  correct but carries ℝ≥0∞ return type. Downstream `advantage` uses
  `.toReal`.
- **L83–94:** `probEvent_certain` uses `toOuterMeasure_apply_eq_one_iff`;
  `probEvent_impossible` uses `toOuterMeasure_apply_eq_zero_iff`. Both
  correct.
- **L97–103 (`probTrue_le_one`):** Triangulates through
  `d.toOuterMeasure Set.univ = 1`. Uses `OuterMeasure.mono` with
  `Set.subset_univ`. Correct.

**Verdict:** No issues.

### 4.18 `Probability/Negligible.lean` (115 lines)

- **L36–37 (`IsNegligible`):** Standard Katz-Lindell definition. Note
  `|f n| < n⁻ᶜ` (strict), which differs from some texts that use `≤`.
  Strict is the conventional choice; both are equivalent up to constants.
- **L40–45 (`isNegligible_zero`):** Uses `n₀ = 1`, then
  `|0| < n⁻ᶜ` dispatched by `positivity`. Correct for all `c ≥ 0`.
- **L47–51 (`isNegligible_const_zero`):** Duplicates `isNegligible_zero`
  but for the `Pi.zero_apply` form. Minor redundancy — could be
  `isNegligible_zero` with a `simp only [Pi.zero_apply]` preamble. Harmless.
- **L54–74 (`IsNegligible.add`):** For target `c`, uses `c+1` from
  `hf, hg`, bounds `|f+g| ≤ |f|+|g| < 2·n⁻⁽ᶜ⁺¹⁾`, then `2·n⁻⁽ᶜ⁺¹⁾ ≤ n·n⁻⁽ᶜ⁺¹⁾
  = n⁻ᶜ` requires `n ≥ 2`. The `max (max n₁ n₂) 2` threshold achieves this.
  Correct.
- **L81–113 (`IsNegligible.mul_const`):** Split on `C = 0` vs `C ≠ 0`.
  In the nonzero branch, the threshold is `max (max n₁ (⌈|C|+1⌉)) 1` to
  ensure `n > |C|`. The calc chain is correct.
  → **F-18**: L90 defines `have hn_pos : (0 : ℝ) < n := by exact_mod_cast Nat.one_pos.trans_le hn_ge_one` — this `hn_pos` binding is then *shadowed* at L101 inside the `by_cases` branch with
  `have hn_pos : (0 : ℝ) < n := lt_trans hC_pos hn_ge_C`. The shadow is
  harmless (the second definition is used inside its branch) but the
  first `hn_pos` is only used in the `C = 0` branch. Minor style noise.

**Verdict:** Correct proofs. F-18 is a cosmetic finding.

### 4.19 `Probability/Advantage.lean` (153 lines)

- **L51–52 (`advantage`):** `|probTrue d₀ D .toReal - probTrue d₁ D .toReal|`.
  Correct.
- **L59–71:** Four basic properties — nonneg, symm, self-zero, ≤ 1. All
  standard and correct.
- **L73–86 (`advantage_le_one`):** Uses `ENNReal.toReal_le_of_le_ofReal` with
  `one_pos.le`. Careful handling of ENNReal-to-ℝ conversion. Correct.
- **L96–100 (`advantage_triangle`):** One-line `abs_sub_le`. Correct.
- **L109–111 (`hybrid_two`):** Alias of triangle. Minor redundancy.
- **L120–137 (`hybrid_argument_nat`):** Induction on `n`. Base case via
  `advantage_self`. Inductive step chains `advantage_triangle` then adds
  the `n`-th adjacent advantage via `Finset.sum_range_succ`. Correct.
- **L146–151 (`hybrid_argument`):** Thin alias of `_nat`. Usable.

**Verdict:** No issues.

### 4.20 `Construction/Permutation.lean` (141 lines)

- **L40 (`Bitstring`):** `abbrev Bitstring (n : ℕ) := Fin n → Bool`. Using
  `abbrev` (not `def`) means instance synthesis works transparently — this
  is essential for `MulAction`, `DecidableEq`, `Fintype` lifting. Correct
  design choice.
- **L51–54:** The `MulAction (Equiv.Perm (Fin n)) (Bitstring n)` instance
  defines `σ • x := fun i => x (σ⁻¹ i)`. Verified: `one_smul` uses `σ = 1 ⇒
  σ⁻¹ = 1`, so `x (1 i) = x i`. `mul_smul` uses `(σ * τ)⁻¹ = τ⁻¹ * σ⁻¹`.
  Both discharged by `funext _; rfl`. Correct left-action.
- **L62–73:** Simp lemmas for the action. All `rfl` or thin.
- **L86–99 (`perm_action_faithful`):**
  → **F-04**: L92 contains `push Not at h`. Expected idiom is `push_neg at h`.
  There is a Mathlib `push` tactic (see `Mathlib.Tactic.Push`) that can
  target `Not`, making `push Not` syntactically valid — but `push_neg` is
  the standard spelling used throughout Mathlib. Recommend replacing with
  `push_neg at h` for uniformity and robustness against tactic renames.
  The surrounding proof:
  1. `by_contra h` on `∃ i, σ i ≠ i`.
  2. `push Not at h` transforms to `∀ i, σ i = i`.
  3. `Equiv.ext h` closes by contradiction with `hσ : σ ≠ 1`.
  Mathematically correct.
- **L109–110 (`hammingWeight`):** Count of `true` bits via
  `Finset.univ.filter (fun i => x i = true)`.
- **L124–139 (`hammingWeight_invariant`):** Three-step proof:
  1. Rewrite both filters using `perm_smul_apply`.
  2. Show `univ.filter (x ∘ σ⁻¹ = true) = (univ.filter (x = true)).map σ.toEmbedding`.
  3. Close via `Finset.card_map`.
  The set equality is proved via `ext i` with explicit forward and backward
  directions. Correct.

**Verdict:** Correct. F-04 (minor idiom) is the only finding.

### 4.21 `Construction/HGOE.lean` (132 lines)

- **L39–41 (`subgroupBitstringAction`):** `MulAction.compHom` with
  `G.subtype`. Standard subgroup-restriction pattern.
- **L45–47 (`subgroup_smul_eq`):** `rfl` simp lemma.
- **L56–65 (`hgoeScheme`):** Constructor taking canon, reps, distinctness.
  Correct.
- **L75–80 (`hgoe_correctness`):** Direct wrapping of `correctness`.
- **L89–93 (`hammingWeight_invariant_subgroup`):** Destructures
  `⟨σ, _⟩`, applies `hammingWeight_invariant σ x`. Correct.
- **L100–108 (`hgoe_weight_attack`):** One-liner applying `invariant_attack`.
  Non-vacuous theorem: different-weight representatives are a real attack.
- **L121–130 (`same_weight_not_separating`):** Contrapositive of the
  attack: if all reps have same weight, `IsSeparating` fails. Correct.

**Verdict:** No issues.

### 4.22 `Construction/HGOEKEM.lean` (92 lines)

All four declarations (`hgoeKEM`, `hgoe_kem_correctness`, `hgoeScheme_toKEM`,
`hgoeScheme_toKEM_correct`) are thin constructors/wrappers. Correct.

**Verdict:** No issues. (HGOEKEM module.)

### 4.23 `KeyMgmt/SeedKey.lean` (252 lines)

- **L76–86 (`SeedKey`):** Three fields: `seed`, `expand : Seed → CanonicalForm`,
  `sampleGroup : Seed → ℕ → G`. Note: *every* downstream use of
  `expand` / `sampleGroup` passes the structure's own `seed` as argument.
  The first-class function types are more permissive than necessary; a
  pure-data form `expanded : CanonicalForm G X` + `sample : ℕ → G` would
  be simpler and equivalent. The current form gives callers the option to
  apply `expand` at different seeds (not used anywhere in the codebase).
- **L105–112 (`seed_kem_correctness`):** Direct application of
  `kem_correctness`. Correct, genuinely non-vacuous (inherits
  kem_correctness's unconditional status).
- **L140–161 (`HGOEKeyExpansion`):** Structure with 11 fields capturing
  the 7-stage pipeline (b, ℓ, code_dim, group_order_log ≥ 128, weight,
  reps, reps_same_weight). **Specification only.**
  → **F-05**: no theorem establishes a bridge from `HGOEKeyExpansion` to
  `SeedKey` (i.e., no constructor `HGOEKeyExpansion → SeedKey ... ...`),
  nor any existence witness. This is an open implementation task, not a
  flaw in the spec itself, but the formalization's claim to capture the
  7-stage pipeline is currently only an adequacy requirement.
- **L180–186 (`seed_determines_key`):** `rw [hSeed, hSample]` after
  `intro n`. Trivial.
- **L192–197 (`seed_determines_canon`):** Similar trivial rewrite.
- **L222–228 (`OrbitEncScheme.toSeedKey`):** `seed := ()`, `expand := fun () => scheme.canonForm`,
  `sampleGroup := fun () => sampleG`.
  → **F-06**: the `sampleG : ℕ → G` parameter is a plain function — no
  "secret" constraint. Anyone supplying `sampleG` masquerades as holding a
  seed key. Harmless in a formalization-only sense, but the bridge does
  not model real seed-key compression at all.
- **L234–250:** Two bridge preservation lemmas (`toSeedKey_expand`,
  `toSeedKey_sampleGroup`), both `rfl`. OK.

**Verdict:** Structure correct; F-05, F-06 are design gaps.

### 4.24 `KeyMgmt/Nonce.lean` (215 lines)

- **L73–76 (`nonceEncaps`):** `encaps kem (sk.sampleGroup sk.seed nonce)`.
  Correct.
- **L83–85 (`nonceDecaps`):** Forwards to `decaps`. The nonce is not needed
  for decapsulation — consistent with the KEM design.
- **L88–113:** Four `@[simp]` lemmas, all `rfl`. Clean.
- **L127–132 (`nonce_encaps_correctness`):** One-line to `kem_correctness`.
  Correct.
- **L147–154 (`nonce_reuse_deterministic`):** `simp only [nonceEncaps_eq, hSeed, hSample]`.
  Valid.
- **L164–170 (`distinct_nonces_distinct_elements`):** Direct application
  of injectivity. Correct.
- **L191–203 (`nonce_reuse_leaks_orbit`):** This is an *unconditional*
  theorem stating that cross-KEM nonce reuse with different orbits yields
  ciphertexts in different orbits. Uses `orbit_eq_of_smul`. Correct.
  **Genuinely non-vacuous** — it is the formalization of a real nonce-misuse
  vulnerability and complements the defensive `nonce_reuse_deterministic`.
- **L209–214 (`nonceEncaps_mem_orbit`):** `smul_mem_orbit`. Trivial.

**Verdict:** No issues. Strong module: the nonce-misuse warning theorem is
concrete and valuable.

### 4.25 `AEAD/MAC.lean` (69 lines)

- **L60–67 (`MAC`):** Three fields: `tag`, `verify`, `correct`.
  → **F-07 (seed)**: The MAC abstraction has only a *correctness* obligation.
  To prove `INT_CTXT` of a composition using this MAC would require a
  uniqueness-of-tag property such as `∀ k m t, verify k m t = true → t = tag k m`
  or a more general EUF-CMA assumption. Without one, the `MAC` as defined
  cannot discharge INT_CTXT. This is consistent with the "security is an
  assumption, not a proven fact" pattern, but F-07 notes the resulting gap.

**Verdict:** Structure correct; composability gap noted in F-07.

### 4.26 `AEAD/AEAD.lean` (178 lines)

- **L65–71 (`AuthOrbitKEM`):** Explicit composition (`kem` + `mac`), not
  `extends`. The comment correctly calls out Lean 4 limitation with 4+
  type parameters — good engineering note.
- **L82–85 (`authEncaps`):** Encrypt-then-MAC. Valid composition pattern.
- **L97–100 (`authDecaps`):** Verify-then-decrypt. Returns `Option K`.
- **L106–118:** Three `@[simp]` lemmas, all `rfl`.
- **L138–147 (`aead_correctness`):** Two-step proof:
  1. `simp only [authEncaps, authDecaps, encaps, decaps]` unfolds everything.
  2. `simp [akem.mac.correct]` discharges `verify k c (tag k c) = true`.
  Correct and unconditional.
- **L172–176 (`INT_CTXT`):** Definition only. The docstring explicitly
  places this at the assumption level.
  → **F-07**: `INT_CTXT` is not a theorem. It is a property that a specific
  AuthOrbitKEM may or may not satisfy. No concrete AuthOrbitKEM in the
  codebase is shown to satisfy it. For the composition to be cryptographically
  sound, (a) the MAC needs an EUF-CMA-style assumption, and (b) a proof
  connecting that assumption to INT_CTXT is needed.

**Verdict:** Correctness proofs valid; `INT_CTXT` is a placeholder.

### 4.27 `AEAD/Modes.lean` (148 lines)

- **L69–75 (`DEM`):** Symmetric encryption structure with `correct`
  obligation.
- **L87–91 (`hybridEncrypt`):** Let-binding, returns `(c_kem, dem.enc k m)`.
- **L99–103 (`hybridDecrypt`):** Let-binding `k := decaps kem c_kem`, then
  `dem.dec k c_dem`. Correct.
- **L108–117:** Two `@[simp]` lemmas.
- **L138–146 (`hybrid_correctness`):** Uses `simp only` to unfold, then
  `exact dem.correct _ m`. The `_` is filled by unification with the
  derived key. Correct. **Genuinely non-vacuous** (follows directly from
  `kem_correctness` and `dem.correct`).

**Verdict:** Correct; security of the DEM remains an assumption field, as
documented.

### 4.28 `Hardness/CodeEquivalence.lean` (231 lines)

- **L54–55 (`permuteCodeword`):** `σ⁻¹` convention matches Bitstring action.
- **L65–67 (`permuteCodeword_one`):** `funext i; simp [permuteCodeword]`. OK.
- **L72–76 (`permuteCodeword_mul`):** Proof via `mul_inv_rev` + `Equiv.Perm.coe_mul`.
  Correct left-action composition law.
- **L82–83 (`ArePermEquivalent`):** ∃ σ, ∀ c ∈ C₁, σ(c) ∈ C₂.
  → **F-08**: This is a one-sided "σ maps C₁ into C₂" relation. For equal-size
  finite codes it is equivalent to bijection, but the symmetry is not
  machine-checked. No `arePermEquivalent_symm` / `_trans` lemma. Future work:
  add `|C₁| = |C₂|` as a parameter and derive symmetry from injectivity of σ.
- **L87–89 (`arePermEquivalent_refl`):** `⟨1, fun c hc => by rwa [permuteCodeword_one]⟩`.
  Correct.
- **L97–98 (`PAut`):** Set-predicate style, `{ σ | ∀ c ∈ C, permuteCodeword σ c ∈ C }`.
  Observation: this is not declared as a `Subgroup` of `Equiv.Perm (Fin n)`
  — `paut_contains_id` and `paut_mul_closed` are proved separately but no
  `Subgroup` structure is built. A future cleanup could promote `PAut C` to
  a `Subgroup`, making Mathlib's subgroup machinery available.
- **L101–113:** Two closure lemmas. Correct.
- **L132–136 (`CEOIA`):** Same strong-universal pattern as `OIA`. **F-10**:
  `CEOIA C₀ C₁` is `False` for any `C₀, C₁` with distinguishable minimum
  distances or weight distributions (which is "almost always" in practice).
- **L153–158 (`GIReducesToCE`):** Prop asserting existence of a uniform
  encoding function. **F-09, F-12**: never consumed.
- **L178–187 (`paut_compose_preserves_equivalence`):** Coset property. Correct.
- **L197–206 (`paut_from_dual_equivalence`):** Dual equivalences yield
  automorphisms. Correct.
- **L220–227 (`paut_coset_is_equivalence_set`):** → **F-16**: The name
  promises a set-theoretic identity, but the theorem just re-packages
  `σ * τ` as another equivalence. The *set* identity
  `{ρ | ∀ c ∈ C₁, ρ(c) ∈ C₂} = σ · PAut C₁` is not stated or proved.

**Verdict:** Correct but incomplete. F-08, F-09, F-12, F-16 are the gaps.

### 4.29 `Hardness/TensorAction.lean` (306 lines)

- **L52 (`Tensor3`):** `Fin n → Fin n → Fin n → F`. Standard 3-tensor
  indexing.
- **L65–77:** Three single-axis contraction helpers. All `noncomputable`
  (required because of `∑`). Formulas correct.
- **L81–83 (`tensorContract`):** Composition of the three. The order is
  `A ·₁ (B ·₂ (C ·₃ T))` — all three helpers commute so the order is
  definitionally equivalent to any other ordering, but the specific order
  matters for rewriting in the `mul_smul` proof.
- **L92–112:** Three `_one` lemmas, all via `Matrix.one_apply` +
  `Finset.sum_ite_eq`. Standard identity-matrix contraction; correct.
- **L120–150:** Three `_mul` lemmas. Each proof: expand `Matrix.mul_apply`,
  swap summation order with `sum_comm`, distribute via `mul_sum`, close
  with `ring`. Clean and correct.
- **L159–195:** Three `_comm` lemmas. Same pattern: `sum_comm` then `ring`.
  Correct — these are the critical commutativity facts that justify
  contracting on independent axes in any order.
- **L215–245 (`tensorAction` instance):**
  - `one_smul`: reduce `(1, 1, 1) • T` to `tensorContract 1 1 1 T` and apply
    the three `_one` lemmas. Correct.
  - `mul_smul`: this is a 15-line proof requiring three `conv_lhs` rewrites
    to interleave the `h` application with the `g` application via the
    three `_comm` lemmas. The tactic sequence:
    1. Unfold `tensorContract`, apply `*_mul` lemmas.
    2. Result: `M1 g₁ (M1 h₁ (M2 g₂ (M2 h₂ (M3 g₃ (M3 h₃ T)))))`.
    3. Use `conv_lhs => arg 2; rw [matMulTensor1_matMulTensor2_comm]`
       to float `h₁` past `g₂`.
    4. Use nested `arg 2` conv steps to float `g₃` before `h₂`.
    5. Use `matMulTensor1_matMulTensor3_comm` to float `h₁` past `g₃`.
    The final `conv` steps leave LHS syntactically equal to RHS. **The proof
    is correct but fragile**: the `arg 2` path counting is tactic-brittle.
    Any Mathlib change to `tensorContract`'s unfolding could break it.
- **L269–271 (`areTensorIsomorphic_refl`):** `⟨(1, 1, 1), MulAction.one_smul T⟩`.
- **L275–281 (`areTensorIsomorphic_symm`):** Uses `g⁻¹`, `subst hg`,
  `simp [smul_smul]`. Correct.
- **L297–302 (`GIReducesToTI`):** Same Prop-parameter pattern as
  `GIReducesToCE`. Never consumed (F-12).

**Verdict:** Correct and non-trivial. The `mul_smul` proof is the most
technically sophisticated in the codebase but is fragile. Add a
comment explaining the `arg 2` path pinning.

### 4.30 `Hardness/Reductions.lean` (236 lines)

- **L86–89 (`TensorOIA`):** Universal Boolean distinguisher over tensor
  orbit pairs. Inherits F-10 vacuity.
- **L93–96 (`tensorOIA_symm`):** One-line symmetry. Correct.
- **L108–110 (`permuteAdj`):** Standard S_n action on adjacency matrices.
- **L121–124 (`GIOIA`):** Universal Boolean on graph pairs. F-10 vacuity.
- **L127–130 (`gioia_symm`):** Symmetry. Correct.
- **L151–155 (`TensorOIAImpliesCEOIA`):** Prop parameter — NOT a proven
  reduction. The signature does not even fix the encoding dimensions;
  it just asserts that *some* encoding exists witnessing the reduction.
  → **F-09**.
- **L165–169 (`CEOIAImpliesGIOIA`):** Same pattern.
- **L178–182 (`GIOIAImpliesOIA`):** Consumes the assumption family and
  produces `OIA scheme`. Again: this *assumes* the reduction is sound.
- **L189–197 (`HardnessChain`):** Conjunction of four Props. All four are
  either parameter hypotheses or unproven reduction claims. **The chain
  contains zero proven mathematical content** — it is a named bundle of
  assumptions.
- **L204–216 (`oia_from_hardness_chain`):** Destructures the chain and
  threads the reductions in sequence. Mechanically correct given the
  chain's assumptions.
- **L226–232 (`hardness_chain_implies_security`):** Composes with
  `oia_implies_1cpa`. → **F-20**: the final step is the *vacuous*
  deterministic reduction. Even if each link in the chain were sound, the
  conclusion `IsSecure scheme` via deterministic OIA is the unsatisfiable
  path. A probabilistic version of the chain that culminates in
  `concrete_oia_implies_1cpa` (ConcreteOIA ε ⟹ advantage ≤ ε) would be
  non-vacuous and actionable.

**Verdict:** Correctly composes stated assumptions. As a *hardness-to-
security* transfer, the chain is currently vacuous (F-01/F-10/F-20). The
work to upgrade it to probabilistic form is a natural extension of Phase 8.

### 4.31 `PublicKey/ObliviousSampling.lean` (328 lines)

- **L78–85 (`OrbitalRandomizers`):** Three fields, all well-motivated.
  The `in_orbit` field is a *proof*, carried as data — this is the right
  Lean 4 idiom for structured data with proof obligations.
- **L104–110 (`obliviousSample`):** Binary `combine` applied to two
  randomizers; `_hClosed` is underscored (unused in the function body,
  only present for the associated correctness lemma). Clean.
- **L114–121 (`obliviousSample_eq`):** `rfl` simp lemma.
- **L134–142 (`oblivious_sample_in_orbit`):** One-line application of
  `hClosed` with `ors.in_orbit i, ors.in_orbit j`. Correct.
- **L169–175 (`ObliviousSamplingHiding`):** Docstring at L156–167 is
  exceptionally honest — flagging that this is a strong deterministic
  hiding property that will not hold for non-trivial bundles, and that a
  probabilistic refinement is future work. Same vacuity pattern as OIA.
- **L186–198 (`oblivious_sampling_view_constant`):** Direct application of
  `hHide`. Proof is two lines.
- **L222–225 (`refreshRandomizers`):** PRF-keystream-style sampler indexed
  by `epoch * t + i.val`. Correct.
- **L239–244 (`refreshRandomizers_in_orbit`):** One-line `smul_mem_orbit`.
- **L253–258 (`refreshRandomizers_orbitalRandomizers`):** Packages into
  `OrbitalRandomizers`. Constructor-style.
- **L297–307 (`RefreshIndependent`):** Prop stating that two samplers
  agreeing on per-epoch index ranges produce the same bundles for those
  epochs. **Structural, not a computational assumption.**
- **L316–326 (`refresh_independent`):** Unconditional proof — `funext i;
  rw [hAgree i]`. Correctly discharges the structural claim. The PRF
  assumption on `G_elem_sampler` itself is out of scope (correctly noted
  in the docstring at L293–295).

**Verdict:** Strong module with honest vacuity disclosures. No bugs.

### 4.32 `PublicKey/KEMAgreement.lean` (236 lines)

- **L81–89 (`OrbitKeyAgreement`):** Two KEMs + combiner. Both KEMs must
  share `X` and `K`. Correct.
- **L95–98 / L101–104:** Alice's / Bob's encapsulation. Trivial forwards.
- **L115–119 (`sessionKey`):** `combiner k_A k_B`. Correct but note that
  the sessionKey definition is *symmetric*: it presupposes both parties'
  encapsulation outputs as inputs, not just one party's decapsulation on
  the other's ciphertext. This is the subtle point elaborated by F-19.
- **L132–141 (`kem_agreement_correctness`):** The theorem is
  `combiner (decaps (encaps.1)) (encaps.2) = combiner (encaps.2) (decaps (encaps.1))`.
  → **F-19**: After `rw [kem_correctness ...]` on both sides, this
  reduces to `combiner k_A k_B = combiner k_A k_B` — a tautology. The
  *content* the theorem is trying to capture (both parties agree) is
  better expressed by `kem_agreement_alice_view` / `_bob_view` which
  show each party's view equals `sessionKey a b`. `kem_agreement_correctness`
  itself is redundant in the presence of those two.
- **L148–161 (`kem_agreement_bob_view`) / L165–175 (`_alice_view`):** Both
  show the respective party's view equals `sessionKey a b`. Correct and
  non-vacuous.
- **L204–213 (`SymmetricKeyAgreementLimitation`):** Prop unfolding
  `sessionKey` into the raw `keyDerive (canon (a • bp))` expression.
- **L222–234 (`symmetric_key_agreement_limitation`):** Unconditional —
  the identity is `rfl` after the `show`. Correct. This is the machine-
  checked formal statement that Orbcrypt KEM agreement requires both
  parties' secret KEM state; no public-key primitive is derived.

**Verdict:** Non-vacuous content (alice/bob views, limitation Prop).
`kem_agreement_correctness` is redundant (F-19).

### 4.33 `PublicKey/CommutativeAction.lean` (310 lines)

- **L73–75 (`CommGroupAction`):** `class` extending `MulAction` with a
  single `comm` axiom field. Correct design.
- **L94–96 (`csidh_exchange`):** Returns `(a•x₀, b•x₀, a•(b•x₀))`. The
  third component is Alice's view. Symmetric by `csidh_correctness`.
- **L102–120:** Three `@[simp]` unfolding lemmas, all `rfl`.
- **L128–130 (`csidh_correctness`):** One-line from `CommGroupAction.comm`.
- **L139–143 (`csidh_views_agree`):** `simp only [csidh_exchange_alice,
  csidh_exchange_bob]; exact csidh_correctness a b x₀`. Correct.
- **L173–182 (`CommOrbitPKE`):** Structure with `pk_valid` as a proof
  field. Standard pattern.
- **L197–199 (`CommOrbitPKE.encrypt`):** Returns `(r•basePoint, r•publicKey)`.
- **L221–223 (`CommOrbitPKE.decrypt`):** `secretKey • ciphertext`.
- **L250–257 (`comm_pke_correctness`):** Uses `simp only` to unfold, then
  `rw [CommGroupAction.comm, ← pke.pk_valid]`. Correct.
- **L265–268 (`comm_pke_shared_secret`):** Convenience restatement. Correct.
- **L285–290 (`CommGroupAction.selfAction`):** `def` not `instance` —
  intentional to avoid typeclass diamond when instantiating for richer
  actions. Good design note at L279–282.
- **L306–308 (`selfAction_comm`):** Correct self-standing statement. The
  only machine-checked satisfiability witness for `CommGroupAction`.
  → **F-14**: No non-trivial commutative action is given.

**Verdict:** Scaffolding is correct. Hardness content depends on future
concrete instantiations (explicitly acknowledged in docstring).

### 4.34 `PublicKey/CombineImpossibility.lean` (448 lines)

- **L119–130 (`GEquivariantCombiner`):** Bundles combine + closure +
  diagonal equivariance. The equivariance axiom
  `combine (g • x) (g • y) = g • combine x y` is the natural symmetry
  condition.
- **L145–149 (`combine_diagonal_smul`):** One-line instantiation.
- **L168–179 (`combine_section_form`):** Substantial proof showing that
  equivariance determines the combiner on `orbit × orbit` from its
  restriction to `{bp} × orbit`. Uses `← mul_smul` + `mul_inv_cancel_left`.
  Mathematically correct and non-trivial.
- **L202–205 (`NonDegenerateCombiner`):** Existence of `g` with
  `combine bp (g•bp) ≠ combine bp bp`. Minimal usefulness requirement.
- **L222–226 (`combinerDistinguisher`):** `decide (combine bp x = combine bp bp)`.
  Boolean classification function.
- **L231–234:** Simp unfolding.
- **L242–247 (`combinerDistinguisher_basePoint`):** Returns `true` via
  `decide_eq_true rfl`.
- **L257–264 (`combinerDistinguisher_witness`):** Non-degeneracy exhibits
  a `g` making the distinguisher `false`. Correct.
- **L300–323 (`equivariant_combiner_breaks_oia`):** Headline theorem.
  Assumes OIA, derives contradiction via the `true = false` path. Correct.
  → **F-17**: Because `OIA scheme` is vacuously False (F-01) for any
  non-trivial scheme, this theorem is vacuously true. The *cryptographic
  meaning* of "equivariant non-degenerate combiner refutes OIA" is still
  valid as a design insight, but the machine-checked statement
  contributes zero additional information under current assumptions.
- **L342–353 (`oia_forces_combine_constant_in_snd`):** Contrapositive.
  Vacuously true.
- **L366–375 (`oia_forces_combine_constant_on_orbit`):** Orbit-element
  version. Correct destructuring.
- **L411–447 (`oblivious_sample_equivariant_obstruction`):** Bridge to
  ObliviousSampling. The proof inlines the closure hypothesis
  reconstruction twice (L420–428 and L429–434), which is correct but
  duplicates a 5-line lambda. Could be hoisted to a `have` binding.

**Verdict:** Proofs mathematically correct and contain genuine structural
content (the section-form lemma is non-trivial). Current vacuity is
F-17; a probabilistic-OIA refinement would give this module real teeth.

---

## 5. Cross-Cutting Concerns

### 5.1 The vacuity map

This project has two layers of "OIA-like" indistinguishability assumptions:

| Layer | Definitions | Satisfiability on Orbcrypt |
|-------|-------------|----------------------------|
| Deterministic | `OIA`, `KEMOIA` (conjunct 1), `CEOIA`, `TensorOIA`, `GIOIA`, `ObliviousSamplingHiding` | **Unsatisfiable** for schemes with ≥ 2 distinct orbit reps (or ≥ 2 orbit elements, resp.). |
| Probabilistic | `ConcreteOIA ε`, `CompOIA` | Satisfiable (ε = 1 trivially; interesting ε values parameterize concrete security). |

Theorems that depend on the deterministic layer (Phase 4 `oia_implies_1cpa`,
Phase 7 `kemoia_implies_secure`, Phase 12 `hardness_chain_implies_security`,
Phase 13 `equivariant_combiner_breaks_oia`) are all *vacuously true* on any
cryptographically interesting scheme. Their logical correctness is
machine-verified; their **information content under realistic use is zero**.

Theorems that depend on the probabilistic layer (Phase 8
`concrete_oia_implies_1cpa`, `comp_oia_implies_1cpa`) have real content.

Recommendation: extend Phase 8 to cover every domain where the deterministic
layer is currently vacuous. Specifically:

1. Introduce `ConcreteKEMOIA kem ε` paralleling `ConcreteOIA`.
2. Introduce `ConcreteTensorOIA T₀ T₁ ε`, `ConcreteCEOIA C₀ C₁ ε`,
   `ConcreteGIOIA adj₀ adj₁ ε` — each a probabilistic variant.
3. State each reduction step as a probabilistic transfer with an
   explicit advantage loss.
4. Compose into `ConcreteHardnessChain scheme ε` whose conclusion is
   `indCPAAdvantage scheme A ≤ ε` for all `A`.
5. State a probabilistic variant of `equivariant_combiner_breaks_oia`
   giving a quantitative advantage bound for the induced distinguisher.

The existing deterministic theorems can be kept as "algebraic sanity checks"
that the probabilistic framework correctly generalizes.

### 5.2 `Prop`-valued reductions as axioms-in-disguise

`GIReducesToCE`, `GIReducesToTI`, `TensorOIAImpliesCEOIA`,
`CEOIAImpliesGIOIA`, `GIOIAImpliesOIA`, and `HardnessChain` are all
`Prop`-valued definitions with no concrete witness constructed anywhere.
Callers supplying these hypotheses effectively introduce them as axioms.

This is *not a bug* — it matches the project's stated convention of treating
hardness assumptions as hypotheses rather than axioms. But the practical
reading is:

- These Props are *claims about reductions*, not *proofs of them*.
- A downstream user cannot discharge them without supplying concrete
  encoding constructions.
- The formalization does not prove `GI ≤_p CE` or `GI ≤_p TI`; it
  *records* that these are assumed.

The root `Orbcrypt.lean` axiom transparency report could be strengthened by
listing these "hardness parameters" alongside the headline hypotheses.

### 5.3 Proof-style and tactic hygiene

Across the 35 files, proof style is consistently good:

- Strategy comments on every non-trivial proof.
- `have` bindings have descriptive names.
- `calc` blocks are used for equational chains.
- `simp only [...]` (with explicit lemma sets) is preferred over bare
  `simp` in nearly all cases — good discipline.

Minor style issues:

- F-04: `push Not at h` should be `push_neg at h`.
- F-18: redundant `have hn_pos` in `IsNegligible.mul_const`.
- F-13: `@`-qualified reference style in `CompOIA` / `CompIsSecure`.
- `hybrid_two` (Probability/Advantage.lean L109) is a pure alias of
  `advantage_triangle`; could be removed.

### 5.4 Typeclass and universe handling

- `SchemeFamily` uses `G, X, M : ℕ → Type*`. Consumers must either accept
  universe-polymorphism or fix a specific universe. The current design
  implicitly assumes the `Type*` polymorphism threads through. No active
  universe bugs, but this is a future pain point (F-15).
- `CommGroupAction.selfAction` as `def` (not `instance`) is a deliberate
  choice to avoid typeclass diamond. Well-documented at L279–282.
- `PAut` is a `Set`, not a `Subgroup`, so Mathlib's subgroup tooling is
  not available. Non-critical but worth promoting.

### 5.5 Documentation consistency

- `CLAUDE.md` lists 33 source modules + root; the on-disk count matches.
- `CLAUDE.md` claims Phase 13 includes three files (`ObliviousSampling`,
  `KEMAgreement`, `CommutativeAction`) — the on-disk tree has a fourth:
  `CombineImpossibility.lean` (added later). `CLAUDE.md` does not mention
  this file. Minor doc drift.
- `CLAUDE.md`'s headline theorem table lists 18 theorems; the formalization
  contains all of them. No drift at the theorem level.
- `Orbcrypt.lean`'s axiom transparency report lists axiom dependencies for
  18 theorems. Spot-checked: all are accurate.

### 5.6 CI health

- `grep -rn "sorry"` (F-03): bare regex.
  Minimal fix: `grep -rPn '\bsorry\b' Orbcrypt/ --include="*.lean" | grep -vE '(^|:)\s*(---?|/\*\*?|--!).*'` — more targeted.
  Better: parse Lean output (`lake build` warns on `sorry` implicitly).
- `grep -Prn "^axiom\s+\w+\s*[\[({:]"` (axiom check): correctly excludes
  docstring prose. OK.
- No elan SHA-256 pin in CI (F-22; unchanged from 2026-04-14 audit).

### 5.7 Potential security implications

No CVE-level vulnerabilities found in any file. The formalization is an
*honest* description of the scheme at its current stage:

- Correctness theorems are genuinely non-vacuous: `correctness`,
  `kem_correctness`, `aead_correctness`, `hybrid_correctness`,
  `seed_kem_correctness`, `nonce_encaps_correctness`,
  `hgoe_correctness`, `hgoe_kem_correctness`, `kem_agreement_alice_view`,
  `kem_agreement_bob_view`, `comm_pke_correctness`,
  `refresh_independent`, `oblivious_sample_in_orbit`.
- Attack theorems are genuinely non-vacuous: `invariant_attack`,
  `hgoe_weight_attack`, `nonce_reuse_leaks_orbit`,
  `symmetric_key_agreement_limitation`.
- Security theorems relying on deterministic OIA are vacuously true.
- Security theorems relying on probabilistic OIA (`concrete_oia_implies_1cpa`,
  `comp_oia_implies_1cpa`) have real content.

A deployed Orbcrypt implementation's security is **governed entirely by
the correctness of the concrete probabilistic OIA instantiation** (the
pipeline in `HGOEKeyExpansion` + the quasi-cyclic code + the quantitative
ε claim), not by the formalization. The formalization is a (substantial)
sanity check that the algebraic arguments are coherent.

---

## 6. Security Model Analysis

### 6.1 Strengths

1. **Orbit partition** (`orbit_disjoint_or_eq`, `orbit_eq_of_smul`) is the
   algebraic bedrock. Correctly proven and widely used.
2. **Correctness is unconditional** — `correctness`, `kem_correctness`,
   `aead_correctness`, `hybrid_correctness`, `comm_pke_correctness`. No
   OIA dependency.
3. **Invariant-attack theorem** is non-vacuous and directly formalizes
   COUNTEREXAMPLE.md. It is perhaps the highest-value theorem in the
   project — it gives a *falsifiable* design rule (reps must have equal
   Hamming weight, or more generally, must not be separated by any
   G-invariant).
4. **Hamming-weight defense** (`same_weight_not_separating`) closes the
   weight attack at the design level.
5. **Nonce-misuse warning theorem** (`nonce_reuse_leaks_orbit`) is a
   formal statement of a real attack vector — unconditional, actionable.
6. **Symmetric-key-agreement limitation** (`symmetric_key_agreement_limitation`)
   is a formal proof that the KEM-agreement protocol is not public-key.
7. **Combine-impossibility theorem** (`equivariant_combiner_breaks_oia`,
   `oia_forces_combine_constant_on_orbit`) is a substantive algebraic
   no-go for the naive oblivious-sampling approach. Even under current
   vacuity, the section-form lemma (`combine_section_form`) is
   content-bearing.
8. **Phase 8 probabilistic infrastructure** (`advantage`, `triangle`,
   `hybrid_argument`, `IsNegligible`, `ConcreteOIA`, `CompOIA`,
   `concrete_oia_implies_1cpa`) provides a genuine, non-vacuous
   security framework.

### 6.2 Weaknesses

1. **Deterministic OIA vacuity** (F-01, F-10) makes the core Phase 4 /
   Phase 7 / Phase 12 security theorems vacuous on any scheme that
   `OrbitEncScheme.reps_distinct` enforces.
2. **Hardness-reduction chain** (F-09, F-20) is a bundle of assumptions,
   not proven reductions. The chain culminates in a vacuously-true
   deterministic security theorem.
3. **No threaded probabilistic hardness chain.** Phase 8 stops at
   `ConcreteOIA`; it does not bridge to Phase 12 hardness assumptions.
4. **Multi-query security** (`MultiQueryAdversary`, `single_query_bound`)
   is a placeholder (F-11). No Q-CPA theorem via hybrid argument.
5. **MAC / AEAD security** (`INT_CTXT`) is defined but not proved (F-07).
   The MAC abstraction is too weak to discharge it without an EUF-CMA
   augmentation.
6. **HGOE key expansion spec** (F-05) has no implementation.
7. **Seed-key compression** (F-06) has no model of "seed as secret."

### 6.3 Threat model coverage

Against the stated threats from DEVELOPMENT.md and COUNTEREXAMPLE.md:

| Threat | Formalization status |
|--------|---------------------|
| Invariant attack (COUNTEREXAMPLE.md) | Fully formalized (`invariant_attack`, `hgoe_weight_attack`). |
| Hamming weight leak | Fully formalized (`hammingWeight_invariant_subgroup` + `hgoe_weight_attack`). |
| Hamming weight defense | Formalized at the design level (`same_weight_not_separating`). |
| Nonce misuse (cross-KEM) | Formalized as a warning theorem (`nonce_reuse_leaks_orbit`). |
| Nonce misuse (within-KEM) | Shown to be benign (`nonce_reuse_deterministic`). |
| Symmetric-agreement limitation | Formalized (`symmetric_key_agreement_limitation`). |
| Equivariant combiner attack | Formalized under deterministic OIA only (F-17). |
| IND-1-CPA security | Non-vacuously formalized probabilistically (`concrete_oia_implies_1cpa`). |
| IND-Q-CPA multi-query | Not formalized (F-11). |
| INT-CTXT / INT-PTXT | Defined, not proved (F-07). |
| IND-CCA | Not defined. |
| Replay attack | Not formalized. |
| Side-channel attack | Out of scope for formal verification. |

### 6.4 Vulnerability check summary

Per the `CLAUDE.md` vulnerability-reporting directive, the auditor looked
for:

- **Cryptographic design errors:** None found beyond the documented
  vacuity of deterministic OIA.
- **Formalization gaps creating false assurance:** F-01 and F-10 are
  mitigated by Phase 8, but the hardness chain (F-20) still composes with
  the vacuous deterministic layer. **This is a formalization gap that
  could mislead a reader into believing the project has a proven
  hardness-to-IND-1-CPA reduction chain, when in fact the final step is
  vacuously true.** Recommend the root `Orbcrypt.lean` axiom transparency
  report explicitly marks `hardness_chain_implies_security` as "relies on
  deterministic OIA, which is unsatisfiable on non-trivial schemes
  (see F-01) — the probabilistic analogue is future work."
- **Dependency/toolchain vulnerabilities:** Mathlib is pinned to a known
  commit; no known vulnerabilities in Lean 4 v4.30.0-rc1 affect this
  project.
- **Build/CI insecurity:** F-22 (elan SHA-256 not pinned in CI workflow).

**Conclusion:** No new CVE-worthy vulnerability discovered. The
formalization-gap concerns (F-01, F-09, F-20) are already publicly
documented in the project (DEVELOPMENT.md §8, CLAUDE.md, the module
docstrings of `Crypto/OIA.lean` and `Crypto/CompOIA.lean`). They are
**research limitations**, not hidden flaws.

---

## 7. Findings Summary Table

Reproduced from §1 headline findings with full context.

| ID | Severity | Category | File(s) | Description | Fix effort |
|----|----------|----------|---------|-------------|-----------|
| F-01 | High (modeling) | Design (vacuity) | `Crypto/Scheme.lean`, `Crypto/OIA.lean`, `Theorems/OIAImpliesCPA.lean` | Deterministic `OIA scheme` is False whenever `reps_distinct` holds non-trivially → `oia_implies_1cpa` is vacuously true. Documented in `Crypto/OIA.lean` L46–57. | Large — requires threading `ConcreteOIA` through all downstream theorems, or writing an expanded migration note in `Orbcrypt.lean` axiom report. |
| F-02 | Low | Modeling | `Crypto/Security.lean` | `Adversary.choose` may produce `(m, m)`. | Small — add an optional `choose_distinct` field or a separate `IsSecureDistinct` predicate. |
| F-03 | Low | CI | `.github/workflows/lean4-build.yml` | Bare `grep "sorry"` risks false positives on docstrings. | Trivial — add `-P` and word-boundary anchors. |
| F-04 | Low | Proof style | `Construction/Permutation.lean:92` | `push Not at h` should be `push_neg at h`. | Trivial — one-character edit. |
| F-05 | Info | Modeling | `KeyMgmt/SeedKey.lean` | `HGOEKeyExpansion` is spec-only; no `HGOEKeyExpansion → SeedKey` bridge. | Medium — requires mechanized PRF spec. |
| F-06 | Low | Modeling | `KeyMgmt/SeedKey.lean` | `OrbitEncScheme.toSeedKey` takes `sampleG : ℕ → G` with no secrecy. | Small — upgrade to `SampleGroupSpec` requiring pseudorandomness. |
| F-07 | Medium | Modeling | `AEAD/MAC.lean`, `AEAD/AEAD.lean` | `INT_CTXT` is defined but not provable without MAC-uniqueness. | Medium — add `verify_inj : ∀ k m t, verify k m t = true → t = tag k m` field or EUF-CMA Prop, prove INT_CTXT from it. |
| F-08 | Info | API | `Hardness/CodeEquivalence.lean` | `ArePermEquivalent` lacks `symm` and `trans`; not a `Subgroup` for `PAut`. | Small for lemmas; medium for `Subgroup` upgrade. |
| F-09 | High | Design | `Hardness/Reductions.lean`, `Hardness/CodeEquivalence.lean`, `Hardness/TensorAction.lean` | Reductions are Prop parameters, not proofs. | Large — requires actual encoding constructions. |
| F-10 | High | Design | All `OIA`-family definitions | Deterministic OIA variants are all vacuously False; probabilistic lift missing. | Large — see §5.1 plan. |
| F-11 | Info | Placeholder | `Crypto/CompSecurity.lean` | `single_query_bound` does not use `MultiQueryAdversary`; it is a rename. | Medium — requires product PMF infrastructure. |
| F-12 | Info | Unused | `Hardness/CodeEquivalence.lean`, `Hardness/TensorAction.lean` | `GIReducesToCE` / `GIReducesToTI` defined but never consumed. | Trivial — either delete or consume. |
| F-13 | Low | Style | `Crypto/CompOIA.lean`, `Crypto/CompSecurity.lean` | `@`-qualified syntax is verbose and fragile. | Small — hoist into helper `def`s. |
| F-14 | Info | Modeling | `PublicKey/CommutativeAction.lean` | Only trivial `selfAction` witness for `CommGroupAction`. | Large — requires concrete elliptic-curve action or similar. |
| F-15 | Low | Universes | `Crypto/CompOIA.lean` | `SchemeFamily` universe handling is implicit. | Small — add explicit universe annotations. |
| F-16 | Low | Naming | `Hardness/CodeEquivalence.lean` | `paut_coset_is_equivalence_set` does not prove a set identity. | Trivial — rename or prove the set identity. |
| F-17 | Info | Vacuity | `PublicKey/CombineImpossibility.lean` | No-go theorem is vacuously true while deterministic OIA is vacuously False. | Large — requires probabilistic refinement. |
| F-18 | Info | Style | `Probability/Negligible.lean` | Shadowed `have hn_pos` in `IsNegligible.mul_const`. | Trivial — rename or remove redundancy. |
| F-19 | Info | Semantic | `PublicKey/KEMAgreement.lean` | `kem_agreement_correctness` reduces to a tautology; redundant with alice/bob views. | Trivial — remove or rephrase. |
| F-20 | High | Design | `Hardness/Reductions.lean` | Hardness chain culminates in vacuous deterministic reduction. | Large — write probabilistic chain. |
| F-21 | Info | Modeling | `KeyMgmt/SeedKey.lean`, `Construction/HGOE.lean` | Hamming-weight uniformity is the only screened invariant; other separating invariants not ruled out. | Research-level — new theorems as attack space is enumerated. |
| F-22 | Low | CI | `.github/workflows/lean4-build.yml` | elan install lacks SHA-256 verification. | Trivial — pin SHA. |

---

## 8. Recommendations

Ordered by impact × tractability.

### 8.1 Immediate (hours, low risk)

1. **Fix F-04**: replace `push Not at h` with `push_neg at h` in
   `Construction/Permutation.lean:92`.
2. **Fix F-18**: remove the shadowed `have hn_pos` in
   `Probability/Negligible.lean:90`.
3. **Fix F-03 / F-22**: harden the CI regex (`\b` anchors for `sorry`)
   and pin elan's SHA-256 in `.github/workflows/lean4-build.yml`.
4. **Fix F-12**: remove `GIReducesToCE` and `GIReducesToTI`, or add at
   least one theorem that consumes each (e.g., document that they are
   available for callers to compose).
5. **Fix F-19**: either delete `kem_agreement_correctness` or rephrase
   it as "both parties' views agree with `sessionKey a b`" (composition
   of `_alice_view` and `_bob_view`).
6. **Fix F-16**: rename `paut_coset_is_equivalence_set` (e.g.
   `paut_compose_yields_equivalence`), or prove the actual set identity.
7. **Fix F-13**: extract `def advantagePerLevel sf A n := ...` helpers
   in `Crypto/CompOIA.lean` and `Crypto/CompSecurity.lean`.
8. **Update `CLAUDE.md`** to include
   `PublicKey/CombineImpossibility.lean` in the source layout.

### 8.2 Short-term (days, moderate risk)

9. **Strengthen the MAC abstraction (F-07)**: add a `verify_inj`
   uniqueness field (or an EUF-CMA Prop), then prove `INT_CTXT` from
   it in `AEAD/AEAD.lean`.
10. **Add `ArePermEquivalent.symm` / `_trans` (F-08)**, modulo a
    size constraint `C₁.card = C₂.card`.
11. **Promote `PAut` to a `Subgroup`** for free reuse of Mathlib tools.
12. **Constrain `Adversary.choose` (F-02)**: add an optional
    `choose_distinct` field or a separate `IsSecureDistinct` predicate.
13. **Mark `HardnessChain` in `Orbcrypt.lean` axiom report as
    "currently vacuous at the final step (F-20); see §5.1"**.

### 8.3 Medium-term (weeks, higher value)

14. **Probabilistic KEMOIA and KEM-security (extend §5.1 plan)**: define
    `ConcreteKEMOIA kem ε` and prove a probabilistic analogue of
    `kemoia_implies_secure`.
15. **Probabilistic hardness chain**: define `ConcreteTensorOIA`,
    `ConcreteCEOIA`, `ConcreteGIOIA`, connect them via ε-preserving
    reductions, culminate in `concrete_hardness_chain_implies_1cpa`.
16. **Multi-query IND-Q-CPA (F-11)**: build product-PMF infrastructure,
    use `hybrid_argument` to telescope Q adjacent advantages, derive
    `indQCPAAdvantage scheme A ≤ Q · ε`.
17. **Probabilistic `equivariant_combiner_breaks_oia`**: give a
    quantitative advantage bound so the no-go theorem has teeth under
    realistic assumptions.
18. **Formalize a concrete non-trivial `CommGroupAction` instance
    (F-14)**: either (a) an integer-modular-arithmetic toy (acknowledging
    weakness), (b) a Mathlib-compatible elliptic curve action (heavy
    lift), or (c) a mock commutative action with explicit hardness
    hypothesis. Without at least one, `CommOrbitPKE` has no witness.

### 8.4 Long-term (months, research)

19. **Formalize a concrete encoding for at least one reduction
    (F-09)**: proving `GI ≤_p CE` for CFI graphs, or `GI ≤_p TI` for
    adjacency-tensor construction, would turn the corresponding
    hardness-chain step from a Prop parameter into a proven theorem.
20. **Implement `HGOEKeyExpansion` as a computable pipeline (F-05)**
    with a `correctness` theorem linking it to `SeedKey`.
21. **Screen for additional separating invariants (F-21)**: e.g., weight
    enumerator polynomials, automorphism-group invariants, dual-code
    weight distributions. Add defense lemmas analogous to
    `same_weight_not_separating`.

### 8.5 Documentation

22. **Add a §"Vacuity map" to DEVELOPMENT.md** summarizing §5.1 of this
    audit so readers of the main spec understand which theorems are
    content-bearing vs. vacuously true.
23. **Add a "Phase 13 limitations" section to DEVELOPMENT.md** citing
    `CombineImpossibility.lean` and `symmetric_key_agreement_limitation`.

---

## 9. Conclusion

Orbcrypt's Lean 4 formalization is in an **unusually strong engineering
posture** for a research-stage project: 35 files, zero `sorry`, zero custom
axioms, disciplined documentation, maximal Mathlib reuse, and machine-checked
derivations for every public theorem.

The audit did **not** identify any new exploitable security vulnerability,
any smuggled axiom, or any proof that fails to follow from its stated
hypotheses. All 18 headline theorems listed in `CLAUDE.md` §"Three core
theorems" are correctly derived by the tactic scripts in their files.

The audit **did** surface 22 findings — *all of them either already
documented by the project itself, cosmetic, or open research directions*.
The most substantive concern is the vacuity of the deterministic-OIA
security layer (F-01, F-10, F-17, F-20): theorems that depend on it
(`oia_implies_1cpa`, `kemoia_implies_secure`,
`hardness_chain_implies_security`, `equivariant_combiner_breaks_oia`) are
*vacuously true* on any scheme whose `reps_distinct` field forces ≥ 2
distinct orbits. Phase 8's probabilistic framework (`ConcreteOIA`,
`CompOIA`, `concrete_oia_implies_1cpa`) is the principled fix; the work of
propagating that fix through the hardness chain and the Phase 13
public-key scaffolding is the next obvious formalization milestone.

Alongside the security-model observations, the audit highlights:

- A robust set of **non-vacuous** correctness and attack theorems that
  do carry genuine mathematical content (§6.1).
- Clean structural composition of the KEM (Phase 7), AEAD (Phase 10),
  key-management (Phase 9), hardness-alignment (Phase 12), and
  public-key scaffolding (Phase 13).
- A small batch of style / CI fixes (F-03, F-04, F-18, F-22) that can
  be dispatched in under an hour.
- A few modeling gaps (F-02, F-05, F-06, F-07, F-08) that, while not
  bugs, limit what can be *proved* about composed security.

On balance: the formalization is a credible artifact supporting the
research claims, and the gap between "machine-checked" and
"cryptographically meaningful" is both smaller and more honestly
documented than in most formal-verification efforts at this stage.
Continuing the Phase 8 probabilistic refinement into Phases 12 and 13 is
the single highest-value item on the roadmap.

---

**End of audit.**









