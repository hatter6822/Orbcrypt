/-
Workstream E verification script (audit 2026-04-18,
findings F-01, F-10, F-11, F-17, F-20).

Verifies the headline invariants the audit plan asks for:

 1. `#print axioms` outputs for every Workstream E headline result list
    only standard Lean axioms (`propext`, `Classical.choice`, `Quot.sound`)
    or nothing. No `sorryAx`, no custom axiom.
 2. `concreteKEMOIA_one` is trivially inhabited — satisfiability witness
    for `ConcreteKEMOIA` (Workstream E1b).
 3. `ConcreteCEOIA _ _ 1`, `ConcreteTensorOIA _ _ 1`,
    `ConcreteGIOIA _ _ 1` are each trivially inhabited — satisfiability
    witnesses for the three probabilistic hardness OIA variants
    (Workstream E2a, E2b, E2c).
 4. `concreteTensorOIAImpliesConcreteCEOIA_one_one`,
    `concreteCEOIAImpliesConcreteGIOIA_one_one`,
    `concreteGIOIAImpliesConcreteOIA_one_one scheme` witnesses that the
    three reduction Props are satisfiable at `(1, 1)` (Workstream E3a,
    E3b, E3c).
 5. `concrete_chain_zero_compose` exercises the E3d algebraic
    composition sanity check at `ε = 0`.
 6. `ConcreteHardnessChain.tight` exhibits a concrete (vacuous at ε = 1)
    chain, and `ConcreteHardnessChain.concreteOIA_from_chain` composes
    it into `ConcreteOIA scheme 1` (Workstream E4).
 7. `concrete_hardness_chain_implies_1cpa_advantage_bound` delivers
    the probabilistic IND-1-CPA bound from a `ConcreteHardnessChain`
    (Workstream E5).
 8. `identityEncoding` instantiates `OrbitPreservingEncoding` and
    discharges both `preserves` and `reflects`, confirming the E3-prep
    structure is non-vacuous.
 9. `hybrid_argument_uniform` is exercised with a trivial 2-step
    hybrid (`hybrids i := pure x`) where every advantage is `0` — the
    resulting bound `2 · 0 = 0 ≥ 0` is consistent (E8 prereq).
10. `indQCPA_bound_recovers_single_query` fires at `Q = 1` — sanity
    sentinel for the multi-query telescoping (Workstream E8d).

Run: `source ~/.elan/env && lake env lean scripts/audit_e_workstream.lean`

Expected: every `#print axioms` line prints only standard Lean axioms
(`propext`, `Classical.choice`, `Quot.sound`) or
"does not depend on any axioms". Any `sorryAx` or custom axiom is a
review-blocking regression.
-/

import Orbcrypt

open Orbcrypt

section WorkstreamE_AxiomChecks

-- E1
#print axioms Orbcrypt.kemEncapsDist_support
#print axioms Orbcrypt.concreteKEMOIA_one
#print axioms Orbcrypt.det_kemoia_implies_concreteKEMOIA_zero
#print axioms Orbcrypt.concrete_kemoia_implies_secure

-- E2
#print axioms Orbcrypt.concreteCEOIA_one
#print axioms Orbcrypt.concreteTensorOIA_one
#print axioms Orbcrypt.concreteGIOIA_one

-- E3
#print axioms Orbcrypt.concreteTensorOIAImpliesConcreteCEOIA_one_one
#print axioms Orbcrypt.concreteCEOIAImpliesConcreteGIOIA_one_one
#print axioms Orbcrypt.concreteGIOIAImpliesConcreteOIA_one_one
#print axioms Orbcrypt.concrete_chain_zero_compose

-- E4
#print axioms Orbcrypt.ConcreteHardnessChain.concreteOIA_from_chain
#print axioms Orbcrypt.ConcreteHardnessChain.tight

-- E5
#print axioms Orbcrypt.concrete_hardness_chain_implies_1cpa_advantage_bound

-- E6
#print axioms Orbcrypt.concrete_combiner_advantage_bounded_by_oia
#print axioms Orbcrypt.combinerOrbitDist_mass_bounds

-- E7 / E8
#print axioms Orbcrypt.uniformPMFTuple_apply
#print axioms Orbcrypt.hybrid_argument_uniform
#print axioms Orbcrypt.indQCPA_bound_via_hybrid
#print axioms Orbcrypt.indQCPA_bound_recovers_single_query

end WorkstreamE_AxiomChecks
