/-
Ephemeral axiom-audit script for Workstream A.

This file is NOT imported by `Orbcrypt.lean` and lives outside the
`Orbcrypt/` source tree (it is under `scripts/` and uses a `.lean`
extension only so Lean can parse it). It is intended to be run
on-demand as:

```
source ~/.elan/env && lake env lean scripts/audit_print_axioms.lean
```

The `#print axioms` output is printed at elaboration time and can be
compared against `Orbcrypt.lean`'s axiom-transparency report.

If the script is removed in a future cleanup, re-add similar checks
in a local Lean repl session.
-/

import Orbcrypt

open Orbcrypt

#print axioms correctness
#print axioms invariant_attack
#print axioms oia_implies_1cpa
#print axioms kem_correctness
#print axioms kemoia_implies_secure
#print axioms concrete_oia_implies_1cpa
#print axioms comp_oia_implies_1cpa
#print axioms det_oia_implies_concrete_zero
#print axioms seed_kem_correctness
#print axioms nonce_encaps_correctness
#print axioms nonce_reuse_leaks_orbit
#print axioms aead_correctness
#print axioms hybrid_correctness
#print axioms hardness_chain_implies_security
#print axioms oblivious_sample_in_orbit
#print axioms refresh_independent
#print axioms kem_agreement_correctness
#print axioms kem_agreement_alice_view
#print axioms kem_agreement_bob_view
#print axioms csidh_correctness
#print axioms comm_pke_correctness
#print axioms paut_compose_yields_equivalence
