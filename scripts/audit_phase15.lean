import Orbcrypt.Optimization.QCCanonical
import Orbcrypt.Optimization.TwoPhaseDecrypt

/-!
Phase 15 axiom-transparency audit: every headline Phase 15 theorem must
depend only on Lean's standard axioms (propext, Classical.choice,
Quot.sound). Running `lake env lean scripts/audit_phase15.lean` prints
the axiom sets.
-/

open Orbcrypt
open Orbcrypt.Optimization

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
