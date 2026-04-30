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
  version := v!"0.2.1"
  leanOptions := #[
    ⟨`autoImplicit, false⟩,           -- Enforce explicit universe/variable declarations
    ⟨`linter.unusedVariables, true⟩,  -- Default-true in Lean core; pinned defensively (Workstream D / audit 2026-04-23, A-01)
    ⟨`linter.docPrime, true⟩          -- Mathlib linter (default-false): warn on declarations whose name ends in ' but lack a docstring (Workstream D / A-01)
  ]

-- Pinned to Mathlib4 commit fa6418a8 (matches lake-manifest.json)
-- Compatible with lean4:v4.30.0-rc1 (see lean-toolchain)
-- Last verified: 2026-04-30 (Workstream C of audit 2026-04-29
-- + post-landing audit-pass fixes:
-- explicit globs + defense-in-depth checks + GAP/Lean equivalence
-- + C2 set-e robustness + C2 missing-entry-as-mismatch + C4 explicit
-- file/JSON-validity checks; audit-pass #2 fixed CRITICAL CI workflow
-- YAML malformation + C2 concurrency safety via mktemp + 11-point
-- audit-plan reclassification + 11 doc-parity refs in
-- VERIFICATION_REPORT.md / README.md)
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
