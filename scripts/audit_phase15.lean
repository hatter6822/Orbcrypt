/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.Optimization.QCCanonical
import Orbcrypt.Optimization.TwoPhaseDecrypt

/-!
Phase 15 axiom-transparency audit: every headline Phase 15 theorem must
depend only on Lean's standard axioms (propext, Classical.choice,
Quot.sound). Running `lake env lean scripts/audit_phase15.lean` prints
the axiom sets.
-/

open Orbcrypt

-- Work Unit 15.5: core correctness
#print axioms two_phase_correct
#print axioms two_phase_decompose
#print axioms two_phase_invariant_under_G
#print axioms full_canon_invariant

-- Work Unit 15.3: KEM-level two-phase correctness
#print axioms two_phase_kem_decaps
#print axioms two_phase_kem_correctness

-- Work Unit 15.4 companion: orbit-constant syndrome correctness
#print axioms orbit_constant_encaps_eq_basePoint

-- QC canonical form orbit-invariance and idempotence
#print axioms qc_invariant_under_cyclic
#print axioms qc_canon_idem

-- Phase 15 audit follow-up: orbit-constancy-based KEM correctness
-- (the actual statement that the GAP `FastEncaps` / `FastDecaps`
-- pair satisfies; does NOT require the strong `TwoPhaseDecomposition`
-- predicate, which fails for the default fallback wreath-product G).
#print axioms fast_kem_round_trip
#print axioms fast_canon_composition_orbit_constant
