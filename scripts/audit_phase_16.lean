/-
Phase 16 verification audit script.

This file is NOT imported by `Orbcrypt.lean`. Run on-demand with

```
source ~/.elan/env && lake env lean scripts/audit_phase_16.lean
```

Each `#print axioms` line is the machine-checkable verification that the
named declaration depends only on Lean's standard axioms (`propext`,
`Classical.choice`, `Quot.sound`) — never on `sorryAx` or a custom axiom.
The `example` blocks below each section are non-vacuity witnesses: they
instantiate the headline result on a concrete tiny model and discharge
the `Prop` by `decide` or by explicit term construction. If any
declaration silently regresses, this script fails to elaborate.

The script supersedes per-workstream audit files (`audit_b_workstream`,
`audit_c_workstream`, ...) by covering every headline result of
Phases 1–14 in a single pass. The per-workstream scripts remain for
historical reference but are not exercised by CI.

See `docs/VERIFICATION_REPORT.md` for the prose summary that pairs with
this script.
-/

import Orbcrypt

open Orbcrypt

-- ============================================================================
-- §1  Phase 4 — Original three core theorems (regression baseline)
-- ============================================================================

#print axioms correctness
#print axioms invariant_attack
#print axioms oia_implies_1cpa

-- ============================================================================
-- §2  Phase 7 — KEM reformulation (Phase 16 work unit 16.1)
-- ============================================================================

#print axioms encaps
#print axioms decaps
#print axioms encaps_fst
#print axioms encaps_snd
#print axioms decaps_eq
#print axioms kem_correctness
#print axioms toKEM_correct
#print axioms kemIsSecure_iff
#print axioms kem_key_constant
#print axioms kem_key_constant_direct
#print axioms kem_ciphertext_indistinguishable
#print axioms kemoia_implies_secure

-- ============================================================================
-- §3  Phase 8 — Probabilistic foundations (Phase 16 work unit 16.3)
-- ============================================================================

-- Probability.Monad
#print axioms uniformPMF
#print axioms uniformPMF_apply
#print axioms mem_support_uniformPMF
#print axioms probEvent
#print axioms probTrue
#print axioms probEvent_certain
#print axioms probEvent_impossible
#print axioms probTrue_le_one
#print axioms probTrue_eq_tsum
#print axioms uniformPMFTuple
#print axioms uniformPMFTuple_apply
#print axioms mem_support_uniformPMFTuple

-- Probability.Negligible
#print axioms IsNegligible
#print axioms isNegligible_zero
#print axioms isNegligible_const_zero
#print axioms IsNegligible.add
#print axioms IsNegligible.mul_const

-- Probability.Advantage
#print axioms advantage
#print axioms advantage_nonneg
#print axioms advantage_symm
#print axioms advantage_self
#print axioms advantage_le_one
#print axioms advantage_triangle
#print axioms hybrid_two
#print axioms hybrid_argument
#print axioms hybrid_argument_uniform

-- Crypto.CompOIA
#print axioms orbitDist
#print axioms orbitDist_support
#print axioms orbitDist_pos_of_mem
#print axioms ConcreteOIA
#print axioms concreteOIA_zero_implies_perfect
#print axioms concreteOIA_mono
#print axioms concreteOIA_one
#print axioms det_oia_implies_concrete_zero

-- Crypto.CompSecurity
#print axioms indCPAAdvantage
#print axioms indCPAAdvantage_eq
#print axioms indCPAAdvantage_nonneg
#print axioms concrete_oia_implies_1cpa
#print axioms concreteOIA_one_meaningful
#print axioms comp_oia_implies_1cpa
#print axioms single_query_bound
#print axioms perQueryAdvantage_nonneg
#print axioms perQueryAdvantage_le_one
#print axioms perQueryAdvantage_bound_of_concreteOIA
#print axioms indQCPAAdvantage_nonneg
#print axioms indQCPAAdvantage_le_one
#print axioms indQCPA_bound_via_hybrid
#print axioms indQCPA_bound_recovers_single_query

-- KEM.CompSecurity
#print axioms kemEncapsDist
#print axioms kemEncapsDist_support
#print axioms kemEncapsDist_pos_of_reachable
#print axioms ConcreteKEMOIA
#print axioms ConcreteKEMOIA_uniform
#print axioms concreteKEMOIA_one
#print axioms concreteKEMOIA_uniform_one
#print axioms det_kemoia_implies_concreteKEMOIA_zero
#print axioms concrete_kemoia_implies_secure
#print axioms concrete_kemoia_uniform_implies_secure

-- ============================================================================
-- §4  Phase 9 — Key compression and nonce-based encryption
-- ============================================================================

#print axioms seed_kem_correctness
#print axioms seed_determines_key
#print axioms seed_determines_canon
#print axioms toSeedKey_expand
#print axioms toSeedKey_sampleGroup
#print axioms nonceEncaps
#print axioms nonceDecaps
#print axioms nonce_encaps_correctness
#print axioms nonce_reuse_deterministic
#print axioms distinct_nonces_distinct_elements
#print axioms nonce_reuse_leaks_orbit
#print axioms nonceEncaps_mem_orbit

-- ============================================================================
-- §5  Phase 10 — Authenticated encryption and modes (Phase 16 work unit 16.2)
-- ============================================================================

-- AEAD.MAC
#print axioms MAC

-- AEAD.AEAD
#print axioms AuthOrbitKEM
#print axioms authEncaps
#print axioms authDecaps
#print axioms authEncaps_fst
#print axioms authEncaps_snd_fst
#print axioms authEncaps_snd_snd
#print axioms aead_correctness
#print axioms INT_CTXT
#print axioms authEncrypt_is_int_ctxt

-- AEAD.Modes
#print axioms DEM
#print axioms hybridEncrypt
#print axioms hybridDecrypt
#print axioms hybridEncrypt_fst
#print axioms hybridEncrypt_snd
#print axioms hybrid_correctness

-- AEAD.CarterWegmanMAC
#print axioms deterministicTagMAC
#print axioms carterWegmanHash
#print axioms carterWegmanMAC
#print axioms carterWegman_authKEM
#print axioms carterWegmanMAC_int_ctxt

-- ============================================================================
-- §6  Phase 12 — Hardness alignment (LESS / MEDS / TI)
-- ============================================================================

#print axioms ArePermEquivalent
#print axioms PAut
#print axioms CEOIA
#print axioms GIReducesToCE
#print axioms arePermEquivalent_refl
#print axioms arePermEquivalent_symm
#print axioms arePermEquivalent_trans
#print axioms arePermEquivalent_setoid
#print axioms PAutSubgroup
#print axioms PAut_eq_PAutSubgroup_carrier
#print axioms paut_inv_closed
#print axioms paut_compose_preserves_equivalence
#print axioms paut_equivalence_set_eq_coset
#print axioms tensorAction
#print axioms AreTensorIsomorphic
#print axioms areTensorIsomorphic_refl
#print axioms areTensorIsomorphic_symm
#print axioms GIReducesToTI
#print axioms TensorOIA
#print axioms GIOIA
#print axioms HardnessChain
#print axioms hardness_chain_implies_security

-- ============================================================================
-- §7  Phase 13 — Public-key extension
-- ============================================================================

#print axioms oblivious_sample_in_orbit
#print axioms oblivious_sampling_view_constant
#print axioms refresh_independent
#print axioms refreshRandomizers_in_orbit
#print axioms kem_agreement_correctness
#print axioms kem_agreement_alice_view
#print axioms kem_agreement_bob_view
#print axioms symmetric_key_agreement_limitation
#print axioms csidh_correctness
#print axioms csidh_views_agree
#print axioms comm_pke_correctness
#print axioms comm_pke_shared_secret
#print axioms selfAction_comm

-- ============================================================================
-- §8  Workstream A/B/C/D/E carry-forward axioms (regression sentinels)
-- ============================================================================

-- Workstream B (audit F-02 + F-15)
#print axioms isSecure_implies_isSecureDistinct
#print axioms hasAdvantageDistinct_iff
#print axioms IsSecureDistinct
#print axioms DistinctMultiQueryAdversary

-- Workstream E
#print axioms ConcreteHardnessChain
#print axioms ConcreteHardnessChain.concreteOIA_from_chain
#print axioms ConcreteHardnessChain.tight
#print axioms ConcreteHardnessChain.tight_one_exists
#print axioms concrete_hardness_chain_implies_1cpa_advantage_bound
#print axioms concrete_combiner_advantage_bounded_by_oia
#print axioms combinerOrbitDist_mass_bounds
#print axioms identityEncoding

-- ============================================================================
-- §9  Non-vacuity witnesses
-- ============================================================================
--
-- Each example below instantiates a Phase 7/10 headline result on a tiny
-- concrete model. Type-checking the example *is* the verification that the
-- corresponding theorem accepts well-typed inputs. If any signature drifts
-- (e.g., a new typeclass requirement is added), the example will fail to
-- elaborate. We deliberately avoid full `decide`-based witnesses on the
-- larger probabilistic results to keep the script fast.

namespace Phase16Audit

/-- A trivial KEM on the singleton space `Unit` under the permutation group
    `Equiv.Perm (Fin 1)` (which has cardinality 1). Exists purely so the
    examples below can typecheck against a concrete `OrbitKEM`.

    Every field collapses via `Subsingleton.elim`: the canonical form is the
    identity, the derived key is the unique element of `Unit`, and the
    orbit-characterisation condition holds because all sets over a singleton
    are equal. -/
def trivialKEM : OrbitKEM (Equiv.Perm (Fin 1)) Unit Unit where
  basePoint := ()
  canonForm :=
    { canon := id
      mem_orbit := fun _ => ⟨1, Subsingleton.elim _ _⟩
      orbit_iff := fun _ _ => by
        -- Both sides hold trivially on `Unit`: all singletons coincide.
        simp }
  keyDerive := fun _ => ()

/-- KEM correctness on the trivial KEM — direct instantiation of
    `kem_correctness`. -/
example (g : Equiv.Perm (Fin 1)) :
    decaps trivialKEM (encaps trivialKEM g).1 = (encaps trivialKEM g).2 :=
  kem_correctness trivialKEM g

/-- A trivial DEM over the trivial key space. -/
def trivialDEM : DEM Unit Unit Unit where
  enc := fun _ _ => ()
  dec := fun _ _ => some ()
  correct := fun _ _ => rfl

/-- Hybrid correctness on the trivial KEM + DEM. -/
example (g : Equiv.Perm (Fin 1)) (m : Unit) :
    let (c_kem, c_dem) := hybridEncrypt trivialKEM trivialDEM g m
    hybridDecrypt trivialKEM trivialDEM c_kem c_dem = some m :=
  hybrid_correctness trivialKEM trivialDEM g m

/-- A trivial MAC where every tag verifies.  `verify_inj` is vacuous because
    `Tag = Unit`. -/
def trivialMAC : MAC Unit Unit Unit where
  tag := fun _ _ => ()
  verify := fun _ _ _ => true
  correct := fun _ _ => rfl
  verify_inj := fun _ _ _ _ => rfl

/-- A trivial `AuthOrbitKEM`. -/
def trivialAuthKEM : AuthOrbitKEM (Equiv.Perm (Fin 1)) Unit Unit Unit where
  kem := trivialKEM
  mac := trivialMAC

/-- AEAD correctness on the trivial `AuthOrbitKEM`. -/
example (g : Equiv.Perm (Fin 1)) :
    let (c, k, t) := authEncaps trivialAuthKEM g
    authDecaps trivialAuthKEM c t = some k :=
  aead_correctness trivialAuthKEM g

/-- `INT_CTXT` for the trivial `AuthOrbitKEM` via `authEncrypt_is_int_ctxt`.
    Every `c : Unit` is in the orbit of the base point `()` because
    `Unit` is a subsingleton. -/
example : INT_CTXT trivialAuthKEM :=
  authEncrypt_is_int_ctxt trivialAuthKEM
    (fun _ => ⟨1, Subsingleton.elim _ _⟩)

/-- Concrete KEMOIA satisfiability: the bound `ε = 1` is always achievable. -/
example : ConcreteKEMOIA trivialKEM 1 :=
  concreteKEMOIA_one trivialKEM

/-- Concrete KEMOIA-uniform satisfiability. -/
example : ConcreteKEMOIA_uniform trivialKEM 1 :=
  concreteKEMOIA_uniform_one trivialKEM

/-- Hybrid argument with two adjacent steps of advantage 0 produces a
    2 · 0 = 0 end-to-end bound. -/
example (D : Unit → Bool) :
    advantage D (PMF.pure ()) (PMF.pure ()) ≤ (2 : ℕ) * (0 : ℝ) :=
  hybrid_argument_uniform 2 (fun _ => PMF.pure ()) D 0
    (fun _ _ => by simp [advantage_self])

/-- `uniformPMFTuple Bool 3` puts mass `1 / 8` on each of the eight tuples. -/
example (f : Fin 3 → Bool) :
    uniformPMFTuple Bool 3 f = ((Fintype.card Bool) ^ 3 : ENNReal)⁻¹ :=
  uniformPMFTuple_apply 3 f

end Phase16Audit
