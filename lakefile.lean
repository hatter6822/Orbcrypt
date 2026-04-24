import Lake
open Lake DSL

package "orbcrypt" where
  version := v!"0.1.7"
  leanOptions := #[
    ⟨`autoImplicit, false⟩  -- Enforce explicit universe/variable declarations
  ]

-- Pinned to Mathlib4 commit fa6418a8 (matches lake-manifest.json)
-- Compatible with lean4:v4.30.0-rc1
-- Last verified: 2026-04-14
require "leanprover-community" / "mathlib" @ git "fa6418a815fa14843b7f0a19fe5983831c5f870e"

@[default_target]
lean_lib Orbcrypt where
  srcDir := "."
