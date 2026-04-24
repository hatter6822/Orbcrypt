import Lake
open Lake DSL

package "orbcrypt" where
  version := v!"0.1.10"
  leanOptions := #[
    ⟨`autoImplicit, false⟩,           -- Enforce explicit universe/variable declarations
    ⟨`linter.unusedVariables, true⟩,  -- Default-true in Lean core; pinned defensively (Workstream D / audit 2026-04-23, A-01)
    ⟨`linter.docPrime, true⟩          -- Mathlib linter (default-false): warn on declarations whose name ends in ' but lack a docstring (Workstream D / A-01)
  ]

-- Pinned to Mathlib4 commit fa6418a8 (matches lake-manifest.json)
-- Compatible with lean4:v4.30.0-rc1 (see lean-toolchain)
-- Last verified: 2026-04-24
-- Toolchain posture: rc by design (Scenario C of
-- docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md § 7); stable-
-- toolchain upgrade deferred to v1.1. See docs/VERIFICATION_REPORT.md
-- "Toolchain decision (Workstream D)" section.
require "leanprover-community" / "mathlib" @ git "fa6418a815fa14843b7f0a19fe5983831c5f870e"

@[default_target]
lean_lib Orbcrypt where
  srcDir := "."
