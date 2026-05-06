/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Lake
open Lake DSL

package "orbcrypt" where
  version := v!"0.3.5"
  leanOptions := #[
    ⟨`autoImplicit, false⟩,           -- Enforce explicit universe/variable declarations
    ⟨`linter.unusedVariables, true⟩,  -- Default-true in Lean core; pinned defensively (Workstream D / audit 2026-04-23, A-01)
    ⟨`linter.docPrime, true⟩          -- Mathlib linter (default-false): warn on declarations whose name ends in ' but lack a docstring (Workstream D / A-01)
  ]

-- Pinned to Mathlib4 commit fa6418a8 (matches lake-manifest.json)
-- Compatible with lean4:v4.30.0-rc1 (see lean-toolchain)
-- Last verified: 2026-05-01 (Workstream R-05 landing
-- + Workstream C of audit 2026-04-29
-- + post-landing audit-pass fixes:
-- explicit globs + defense-in-depth checks + GAP/Lean equivalence
-- + C2 set-e robustness + C2 missing-entry-as-mismatch + C4 explicit
-- file/JSON-validity checks; audit-pass #2 fixed CRITICAL CI workflow
-- YAML malformation + C2 concurrency safety via mktemp + 11-point
-- audit-plan reclassification + 11 doc-parity refs in
-- VERIFICATION_REPORT.md / README.md;
-- Workstream R-01 (audit 2026-04-29 § 8.1, plan
-- `docs/dev_history/PLAN_R_01_07_08_14_16.md` § R-01): three new public
-- declarations under `Orbcrypt/Theorems/InvariantAttack.lean`
-- (`probTrue_orbitDist_invariant_eq_one`,
--  `probTrue_orbitDist_invariant_eq_zero`,
--  `indCPAAdvantage_invariantAttackAdversary_eq_one`) deliver the
-- quantitative cross-orbit advantage lower bound: under a separating
-- G-invariant, the IND-1-CPA advantage of the invariant-attack
-- adversary is exactly `1`. Patch bump 0.2.2 → 0.2.3.
-- Workstream R-07 (audit 2026-04-29 § 8.1, plan
-- `docs/dev_history/PLAN_R_01_07_08_14_16.md` § R-07): six new public
-- declarations under `Orbcrypt/PublicKey/CombineImpossibility.lean`
-- (`combinerOrbitDist_apply_true_eq_probTrue`,
--  `CrossOrbitNonDegenerateCombiner`,
--  `probTrue_combinerDistinguisher_basePoint_ge_inv_card`,
--  `probTrue_combinerDistinguisher_target_eq_zero`,
--  `combinerDistinguisherAdvantage_ge_inv_card`,
--  `no_concreteOIA_below_inv_card_of_combiner`) close the cross-
-- orbit advantage lower-bound gap from the Workstream-E6 disclosure:
-- under `CrossOrbitNonDegenerateCombiner` the cross-orbit advantage
-- is at least `1/|G|`, refuting `ConcreteOIA scheme ε` for ε <
-- 1/|G|. Concrete `S_2 ⤳ Bitstring 2` fixture witnesses the
-- structure is genuinely inhabited. Patch bump 0.2.3 → 0.2.4.)
-- Workstream R-05 (audit 2026-04-29 § 8.1, plan
-- `docs/planning/PLAN_R_05_11_15.md` § R-05, 2026-05-01):
-- Wegman–Carter 1981 §3 nonce-MAC framework. Two new modules
-- (`Orbcrypt/AEAD/NoncedMAC.lean` + `Orbcrypt/AEAD/NoncedMACSecurity.lean`)
-- introduce the `NoncedMAC` structure, `IsPRF` Prop predicate
-- (function-level formulation), `idealRandomOraclePRF` non-vacuity
-- witness at ε = 0 (proved via `advantage_self`), and concrete
-- specialisations `nonceCarterWegmanMAC` /
-- `nonceBitstringPolynomialMAC` composing the existing R-08 / R-13⁺
-- ε-AXU hash families with the truly-random oracle. The headline
-- reduction theorem `noncedMAC_isQtimeSUFCMASecure_of_isAXU_and_isPRF`
-- (with bound `Q · ε_h + ε_p + 1/|Tag|`) is captured at the
-- framework level + status disclosure as research-scope R-05⁺ per
-- the plan's Phase 3 budget (~280 LOC / ~4.5 days for the proof).
-- Trivial `_le_one` Q-time SUF-CMA bounds are unconditional. Patch
-- bump 0.3.0 → 0.3.1.
-- Workstream R-05 refinement (2026-05-01, plan
-- `/root/.claude/plans/shiny-squishing-sutton.md`): substantively
-- closes the Q-tuple form `IsPRFAtQueries` of the truly-random-
-- oracle PRF witness via the marginal-uniformity lemma
-- `PMF.map_eval_uniformOfFintype_at_injective_eq` (Pi-type
-- cardinality counting via `constrainedPiEquiv` +
-- `constrainedPiCard` + ENNReal pow arithmetic). Adds the
-- `IsPRF.toIsPRFAtQueries` bridge (function-level → Q-tuple, under
-- finite Nonce). New concrete specialisations
-- `nonceCarterWegmanMAC_isPRFAtQueries`,
-- `nonceBitstringPolynomialMAC_isPRFAtQueries`. Naming fix: rename
-- `r05_research_scope_disclosure` → `noncedMAC_research_scope_disclosure`.
-- Type fix: `IsPRF`'s `ε` is now `ℝ` (matching `ConcreteOIA`
-- convention; eliminates the `⊤`-collapse degeneracy). Patch bump
-- 0.3.1 → 0.3.2.
-- W3 (sub-units 3A + 3B) of structural review 2026-05-06 (plan
-- `docs/dev_history/AUDIT_2026-05-06_STRUCTURAL_REVIEW.md` § 1 row 3):
-- machine-checked GAP–Lean canonical-image correspondence at small
-- parameters. New: `scripts/generate_test_vectors.lean` (Lean #eval
-- generator over `Bitstring n` for n ∈ {3, 4} under full-S_n and
-- trivial subgroups — 48 records); `implementation/gap/lean_test_vectors.txt`
-- (committed deterministic artifact); `TestLeanVectors()` in
-- `implementation/gap/orbcrypt_test.g` reads the file and validates
-- each record via GAP's `CanonicalImage(G, support, OnSets)`. The
-- cyclic-group case `C<n>` was dropped because `Subgroup.zpowers σ`'s
-- `Fintype` instance is noncomputable; tracked as a follow-up. CI
-- integration (sub-unit 3C) is deferred to a follow-up workstream
-- pending Docker / GAP-version-pinning resolution. Patch bump
-- 0.3.4 → 0.3.5.
-- W2 of structural review 2026-05-06 (plan
-- `docs/dev_history/AUDIT_2026-05-06_STRUCTURAL_REVIEW.md` § 1 row 2):
-- pre-merge gate `scripts/audit_hypothesis_consumption.py` catches the
-- "theatrical theorem" pattern (hypothesis bound but never consumed in
-- proof body, conclusion type, or any subsequent binder's type). The
-- gate is integrated as a CI step between manifest-drift and the
-- Phase-16 audit, and a "Pre-merge checks" subsection in CLAUDE.md
-- documents the full set of CI gates. Patch bump 0.3.3 → 0.3.4.
-- W1 of structural review 2026-05-06 (plan
-- `docs/dev_history/AUDIT_2026-05-06_STRUCTURAL_REVIEW.md`): rename
-- `two_phase_correct` → `canonical_agreement_under_two_phase_decomposition`
-- and `two_phase_kem_correctness` → `kem_round_trip_under_two_phase_decomposition`.
-- The new identifiers surface the `TwoPhaseDecomposition` hypothesis in
-- the name itself, paralleling Workstream C of audit 2026-04-23
-- (`indQCPA_bound_via_hybrid` → `indQCPA_from_perStepBound`). API-
-- breaking rename → patch bump 0.3.2 → 0.3.3. Verification posture
-- preserved: 3,424 lake build jobs clean, every `#print axioms` on the
-- standard Lean trio.
-- Toolchain posture: rc by design (Scenario C of
-- docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md § 7); stable-
-- toolchain upgrade deferred to v1.1. See docs/VERIFICATION_REPORT.md
-- "Toolchain decision (Workstream D)" section.
require "leanprover-community" / "mathlib" @ git "fa6418a815fa14843b7f0a19fe5983831c5f870e"

-- Workstream C of audit 2026-04-29 (finding A-03 / C1):
-- Explicit `globs` array bounds the build target to the named root file
-- `Orbcrypt` plus every submodule under `Orbcrypt/`. Pre-C1 we relied on
-- the implicit default `globs := roots.map Glob.one`, which together
-- with `srcDir := "."` would have built every `.lean` file under the
-- workspace root that was reachable through transitive imports. The
-- explicit `andSubmodules` glob (Lake's `Orbcrypt.*` syntax matches
-- both `Orbcrypt` itself and every `Orbcrypt.X.Y.Z`) is a tripwire:
-- a transient stub like the one removed by Workstream B1 of this same
-- audit (`_ApiSurvey.lean`) would still be picked up if it were placed
-- under `Orbcrypt/` (because its name `Orbcrypt.Hardness.GrochowQiao._ApiSurvey`
-- matches `Orbcrypt.*`) — but a stub placed *outside* `Orbcrypt/` (e.g.
-- under `experiments/`, `playground/`, `scratch/`) is now provably
-- excluded from the default-target build by the lakefile's structural
-- declaration alone, not by convention.
-- See `Lake/Config/Glob.lean` (`Glob.andSubmodules`) for the matching
-- semantics and `Lake/Config/LeanLibConfig.lean`'s `isLocalModule` /
-- `isBuildableModule` predicates for how Lake consumes this array.
@[default_target]
lean_lib Orbcrypt where
  srcDir := "."
  globs := #[
    -- `Orbcrypt.*` matches the root module `Orbcrypt` and every submodule
    -- `Orbcrypt.<sub>` reachable under `Orbcrypt/`. The Lake DSL exposes
    -- this glob via the `.andSubmodules` constructor of
    -- `Lake.Glob` (see `Lake/Config/Glob.lean`).
    .andSubmodules `Orbcrypt
  ]
