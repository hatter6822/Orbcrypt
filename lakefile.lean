import Lake
open Lake DSL

package "orbcrypt" where
  version := v!"0.1.0"
  leanOptions := #[
    ⟨`autoImplicit, false⟩  -- Enforce explicit universe/variable declarations
  ]

require "leanprover-community" / "mathlib" @ git "master"

@[default_target]
lean_lib Orbcrypt where
  srcDir := "."
