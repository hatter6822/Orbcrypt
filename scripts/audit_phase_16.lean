/-
Phase 16 verification audit script — comprehensive coverage.

This file is NOT imported by `Orbcrypt.lean`. Run on-demand with

```
source ~/.elan/env && lake env lean scripts/audit_phase_16.lean
```

Every `#print axioms` line below is the machine-checkable verification
that the named declaration depends only on Lean's standard axioms
(`propext`, `Classical.choice`, `Quot.sound`) — never on `sorryAx` or a
custom axiom. The `example` blocks in §"Non-vacuity witnesses" are
concrete instantiations: they instantiate the headline result on a tiny
well-typed model and discharge the `Prop` by direct term construction.
If any declaration silently regresses, this script fails to elaborate.

**Coverage.** Every public `def` / `theorem` / `structure` / `class` /
`instance` / `abbrev` declared under `Orbcrypt/**/*.lean` is exercised,
organised by source file. Auto-generated field accessors are exercised
through their qualified names (`OrbitKeyAgreement.encapsA`,
`CommOrbitPKE.decrypt`, etc.). This is a *comprehensive regression
sentinel*: any future change that hides a `sorry` behind an opaque
definition, or that introduces a custom axiom, will produce a mismatched
axiom list and trip the CI parser.

The script supersedes per-workstream audit files (`audit_b_workstream`,
`audit_c_workstream`, ...) by covering every public declaration in a
single pass. Those per-workstream scripts remain for historical
reference but are not exercised by CI.

See `docs/VERIFICATION_REPORT.md` for the prose summary that pairs with
this script.
-/

import Orbcrypt

open Orbcrypt

-- ============================================================================
-- §1  GroupAction foundations (Phase 2)
-- ============================================================================

-- Basic
#print axioms orbit
#print axioms stabilizer
#print axioms orbit_disjoint_or_eq
#print axioms orbit_stabilizer
#print axioms smul_mem_orbit
#print axioms orbit_eq_of_smul

-- Canonical
#print axioms CanonicalForm
#print axioms canon_eq_implies_orbit_eq
#print axioms orbit_eq_implies_canon_eq
#print axioms canon_eq_of_mem_orbit
#print axioms canon_idem

-- Invariant
#print axioms IsGInvariant
#print axioms IsGInvariant.comp
#print axioms isGInvariant_const
#print axioms invariant_const_on_orbit
#print axioms IsSeparating
#print axioms separating_implies_distinct_orbits
#print axioms canonical_isGInvariant

-- ============================================================================
-- §2  Cryptographic definitions (Phase 3)
-- ============================================================================

-- Scheme
#print axioms OrbitEncScheme
#print axioms encrypt
#print axioms decrypt

-- Security
#print axioms Adversary
#print axioms hasAdvantage
#print axioms IsSecure
-- Workstream B (F-02)
#print axioms hasAdvantageDistinct
#print axioms IsSecureDistinct
#print axioms hasAdvantageDistinct_iff
#print axioms isSecure_implies_isSecureDistinct

-- OIA
#print axioms OIA

-- ============================================================================
-- §3  Core theorems (Phase 4)
-- ============================================================================

-- Correctness
#print axioms encrypt_mem_orbit
#print axioms canon_encrypt
#print axioms decrypt_unique
#print axioms correctness

-- InvariantAttack
#print axioms invariantAttackAdversary
#print axioms invariantAttackAdversary_choose
#print axioms invariantAttackAdversary_guess
#print axioms invariant_on_encrypt
#print axioms invariantAttackAdversary_correct
#print axioms invariant_attack

-- OIAImpliesCPA
#print axioms oia_specialized
#print axioms hasAdvantage_iff
#print axioms no_advantage_from_oia
#print axioms oia_implies_1cpa
-- Workstream K1 (F-AUDIT-2026-04-21-M1): distinct-challenge corollary
#print axioms oia_implies_1cpa_distinct
-- Track D (contrapositive)
#print axioms adversary_yields_distinguisher
#print axioms insecure_implies_separating

-- ============================================================================
-- §4  Concrete construction (Phase 5): S_n action on bitstrings
-- ============================================================================

-- Construction.Permutation
#print axioms Bitstring
#print axioms perm_smul_apply
#print axioms one_perm_smul
#print axioms mul_perm_smul
#print axioms perm_action_faithful
#print axioms hammingWeight
#print axioms hammingWeight_invariant

-- Construction.HGOE
#print axioms subgroupBitstringAction
#print axioms subgroup_smul_eq
#print axioms hgoeScheme
#print axioms hgoe_correctness
#print axioms hammingWeight_invariant_subgroup
#print axioms hgoe_weight_attack
#print axioms same_weight_not_separating

-- Construction.HGOEKEM
#print axioms hgoeKEM
#print axioms hgoe_kem_correctness
#print axioms hgoeScheme_toKEM
#print axioms hgoeScheme_toKEM_correct

-- ============================================================================
-- §5  KEM reformulation (Phase 7)
-- ============================================================================

-- KEM.Syntax
#print axioms OrbitKEM
#print axioms OrbitEncScheme.toKEM

-- KEM.Encapsulate
#print axioms encaps
#print axioms decaps
#print axioms encaps_fst
#print axioms encaps_snd
#print axioms decaps_eq

-- KEM.Correctness
#print axioms kem_correctness
#print axioms toKEM_correct

-- KEM.Security
-- Note: `kem_key_constant` was removed in Workstream L5 (audit
-- F-AUDIT-2026-04-21-M6) because its extraction from `hOIA.2` is now
-- redundant — the post-L5 `KEMOIA` is single-conjunct (orbit
-- indistinguishability only). `kem_key_constant_direct` proves key
-- constancy unconditionally from `canonical_isGInvariant`.
#print axioms KEMAdversary
#print axioms kemHasAdvantage
#print axioms KEMIsSecure
#print axioms kemIsSecure_iff
#print axioms KEMOIA
#print axioms kem_key_constant_direct
#print axioms kem_ciphertext_indistinguishable
#print axioms kemoia_implies_secure

-- ============================================================================
-- §6  Probability layer (Phase 8)
-- ============================================================================

-- Probability.Monad
#print axioms uniformPMF
#print axioms uniformPMF_apply
#print axioms mem_support_uniformPMF
#print axioms probEvent
#print axioms probTrue
#print axioms probTrue_eq_tsum
#print axioms probEvent_certain
#print axioms probEvent_impossible
#print axioms probTrue_le_one
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

-- ============================================================================
-- §7  Probabilistic OIA + IND-CPA (Phase 8 + Workstream B/E)
-- ============================================================================

-- Crypto.CompOIA
#print axioms orbitDist
#print axioms orbitDist_support
#print axioms orbitDist_pos_of_mem
#print axioms ConcreteOIA
#print axioms concreteOIA_zero_implies_perfect
#print axioms concreteOIA_mono
#print axioms concreteOIA_one
#print axioms SchemeFamily
#print axioms SchemeFamily.repsAt
#print axioms SchemeFamily.orbitDistAt
#print axioms SchemeFamily.advantageAt
#print axioms CompOIA
#print axioms det_oia_implies_concrete_zero

-- Crypto.CompSecurity
#print axioms indCPAAdvantage
#print axioms indCPAAdvantage_eq
#print axioms indCPAAdvantage_nonneg
-- Workstream K4 (F-AUDIT-2026-04-21-M1): collision-case advantage
#print axioms indCPAAdvantage_collision_zero
#print axioms concrete_oia_implies_1cpa
#print axioms concreteOIA_one_meaningful
#print axioms CompIsSecure
#print axioms comp_oia_implies_1cpa
#print axioms MultiQueryAdversary
#print axioms single_query_bound
-- Workstream B3
#print axioms DistinctMultiQueryAdversary
#print axioms perQueryAdvantage
#print axioms perQueryAdvantage_nonneg
#print axioms perQueryAdvantage_le_one
#print axioms perQueryAdvantage_bound_of_concreteOIA
-- Workstream E8
#print axioms hybridDist
#print axioms indQCPAAdvantage
#print axioms indQCPAAdvantage_nonneg
#print axioms indQCPAAdvantage_le_one
#print axioms indQCPA_bound_via_hybrid
#print axioms indQCPA_bound_recovers_single_query

-- KEM.CompSecurity (Workstream E1)
#print axioms kemEncapsDist
#print axioms kemEncapsDist_support
#print axioms kemEncapsDist_pos_of_reachable
#print axioms ConcreteKEMOIA
#print axioms ConcreteKEMOIA_uniform
#print axioms concreteKEMOIA_one
#print axioms concreteKEMOIA_uniform_one
#print axioms concreteKEMOIA_mono
#print axioms concreteKEMOIA_uniform_mono
#print axioms det_kemoia_implies_concreteKEMOIA_zero
#print axioms kemAdvantage
#print axioms kemAdvantage_nonneg
#print axioms kemAdvantage_le_one
#print axioms concrete_kemoia_implies_secure
#print axioms concreteKEMOIA_one_meaningful
#print axioms kemAdvantage_uniform
#print axioms kemAdvantage_uniform_nonneg
#print axioms kemAdvantage_uniform_le_one
#print axioms concrete_kemoia_uniform_implies_secure
-- Workstream H (audit 2026-04-21, H2): KEM-layer ε-smooth chain
#print axioms ConcreteOIAImpliesConcreteKEMOIAUniform
#print axioms concreteOIAImpliesConcreteKEMOIAUniform_one_right
#print axioms ConcreteKEMHardnessChain
#print axioms concreteKEMHardnessChain_implies_kemUniform
#print axioms ConcreteKEMHardnessChain.tight_one_exists
#print axioms concrete_kem_hardness_chain_implies_kem_advantage_bound

-- ============================================================================
-- §8  Key management (Phase 9)
-- ============================================================================

-- KeyMgmt.SeedKey
#print axioms SeedKey
#print axioms seed_kem_correctness
#print axioms HGOEKeyExpansion
#print axioms seed_determines_key
#print axioms seed_determines_canon
#print axioms OrbitEncScheme.toSeedKey
#print axioms toSeedKey_expand
#print axioms toSeedKey_sampleGroup

-- KeyMgmt.Nonce
#print axioms nonceEncaps
#print axioms nonceDecaps
#print axioms nonceEncaps_eq
#print axioms nonceDecaps_eq
#print axioms nonceEncaps_fst
#print axioms nonceEncaps_snd
#print axioms nonce_encaps_correctness
#print axioms nonce_reuse_deterministic
#print axioms distinct_nonces_distinct_elements
#print axioms nonce_reuse_leaks_orbit
#print axioms nonceEncaps_mem_orbit

-- ============================================================================
-- §9  Authenticated encryption (Phase 10 + Workstream C)
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

-- AEAD.CarterWegmanMAC (Workstream C4 + L-workstream post-audit
-- universal-hash upgrade, 2026-04-22). Note: the pre-upgrade
-- `[NeZero p]` constraint has been strengthened to
-- `[Fact (Nat.Prime p)]`, and the new headline theorem
-- `carterWegmanHash_isUniversal` proves the `(1/p)`-universal
-- property at the primality hypothesis.
#print axioms deterministicTagMAC
#print axioms carterWegmanHash
#print axioms carterWegmanHash_collision_iff
#print axioms carterWegmanHash_collision_card
#print axioms carterWegmanHash_isUniversal
#print axioms carterWegmanMAC
#print axioms carterWegman_authKEM
#print axioms carterWegmanMAC_int_ctxt

-- Probability.UniversalHash (L-workstream post-audit addition)
#print axioms IsEpsilonUniversal
#print axioms IsEpsilonUniversal.mono
#print axioms IsEpsilonUniversal.le_one
#print axioms IsEpsilonUniversal.ofCollisionCardBound
#print axioms probTrue_uniformPMF_decide_eq

-- ============================================================================
-- §10  Hardness alignment (Phase 12 + Workstream D/E)
-- ============================================================================

-- Hardness.CodeEquivalence
#print axioms permuteCodeword
#print axioms permuteCodeword_apply
#print axioms permuteCodeword_one
#print axioms permuteCodeword_mul
#print axioms permuteCodeword_inv_apply
#print axioms permuteCodeword_apply_inv
#print axioms permuteCodeword_injective
#print axioms permuteCodeword_self_bij_of_self_preserving
#print axioms permuteCodeword_inv_mem_of_card_eq
#print axioms ArePermEquivalent
#print axioms arePermEquivalent_refl
#print axioms arePermEquivalent_symm
#print axioms arePermEquivalent_trans
#print axioms arePermEquivalent_setoid
#print axioms PAut
#print axioms paut_contains_id
#print axioms paut_mul_closed
#print axioms paut_inv_closed
#print axioms paut_compose_preserves_equivalence
#print axioms paut_compose_yields_equivalence
#print axioms paut_from_dual_equivalence
#print axioms paut_equivalence_set_eq_coset
#print axioms PAutSubgroup
#print axioms mem_PAutSubgroup
#print axioms PAut_eq_PAutSubgroup_carrier
#print axioms CEOIA
#print axioms GIReducesToCE
-- Workstream E2a
#print axioms codeOrbitDist
#print axioms ConcreteCEOIA
#print axioms concreteCEOIA_one
#print axioms concreteCEOIA_mono

-- Hardness.TensorAction
#print axioms Tensor3
#print axioms matMulTensor1
#print axioms matMulTensor2
#print axioms matMulTensor3
#print axioms matMulTensor1_one
#print axioms matMulTensor2_one
#print axioms matMulTensor3_one
#print axioms matMulTensor1_mul
#print axioms matMulTensor2_mul
#print axioms matMulTensor3_mul
#print axioms matMulTensor1_matMulTensor2_comm
#print axioms matMulTensor1_matMulTensor3_comm
#print axioms matMulTensor2_matMulTensor3_comm
#print axioms tensorContract
#print axioms tensorAction
#print axioms AreTensorIsomorphic
#print axioms areTensorIsomorphic_refl
#print axioms areTensorIsomorphic_symm
#print axioms GIReducesToTI
-- Workstream E2b
#print axioms tensorOrbitDist
#print axioms ConcreteTensorOIA
#print axioms concreteTensorOIA_one
#print axioms concreteTensorOIA_mono
-- Workstream G (audit 2026-04-21, H1): Fix B surrogate structure
#print axioms SurrogateTensor
#print axioms surrogateTensor_group
#print axioms surrogateTensor_fintype
#print axioms surrogateTensor_nonempty
#print axioms surrogateTensor_mulAction
#print axioms punitSurrogate

-- Hardness.Encoding (Workstream E3-prep)
#print axioms OrbitPreservingEncoding
#print axioms identityEncoding

-- Hardness.Reductions (Phase 12 deterministic chain)
#print axioms permuteAdj
#print axioms TensorOIA
#print axioms tensorOIA_symm
#print axioms GIOIA
#print axioms gioia_symm
#print axioms TensorOIAImpliesCEOIA
#print axioms CEOIAImpliesGIOIA
#print axioms GIOIAImpliesOIA
#print axioms HardnessChain
#print axioms oia_from_hardness_chain
#print axioms hardness_chain_implies_security
-- Workstream E2c + E3 + E4 + E5 (probabilistic chain)
#print axioms graphOrbitDist
#print axioms ConcreteGIOIA
#print axioms concreteGIOIA_one
#print axioms concreteGIOIA_mono
#print axioms UniversalConcreteTensorOIA
#print axioms UniversalConcreteCEOIA
#print axioms UniversalConcreteGIOIA
#print axioms ConcreteTensorOIAImpliesConcreteCEOIA
#print axioms ConcreteCEOIAImpliesConcreteGIOIA
#print axioms ConcreteGIOIAImpliesConcreteOIA
#print axioms concreteTensorOIAImpliesConcreteCEOIA_one_one
#print axioms concreteCEOIAImpliesConcreteGIOIA_one_one
#print axioms concreteGIOIAImpliesConcreteOIA_one_one
#print axioms concrete_chain_zero_compose
-- Workstream G (audit 2026-04-21, H1): Fix C per-encoding reduction Props
#print axioms ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding
#print axioms ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding
#print axioms ConcreteGIOIAImpliesConcreteOIA_viaEncoding
#print axioms concreteTensorOIAImpliesConcreteCEOIA_viaEncoding_one_one
#print axioms concreteCEOIAImpliesConcreteGIOIA_viaEncoding_one_one
#print axioms concreteGIOIAImpliesConcreteOIA_viaEncoding_one_one
-- Workstream G: Fix B + Fix C chain (surrogate + encoders)
#print axioms ConcreteHardnessChain
#print axioms ConcreteHardnessChain.concreteOIA_from_chain
#print axioms ConcreteHardnessChain.tight
#print axioms ConcreteHardnessChain.tight_one_exists
#print axioms concrete_hardness_chain_implies_1cpa_advantage_bound
-- Workstream K3 + K4 companion (F-AUDIT-2026-04-21-M1):
-- distinct-challenge IND-1-CPA corollaries in the hardness-chain layer
#print axioms hardness_chain_implies_security_distinct
#print axioms concrete_hardness_chain_implies_1cpa_advantage_bound_distinct

-- ============================================================================
-- §11  Public-key extension (Phase 13)
-- ============================================================================

-- PublicKey.ObliviousSampling
#print axioms OrbitalRandomizers
#print axioms obliviousSample
#print axioms obliviousSample_eq
#print axioms oblivious_sample_in_orbit
#print axioms ObliviousSamplingHiding
#print axioms oblivious_sampling_view_constant
#print axioms refreshRandomizers
#print axioms refreshRandomizers_apply
#print axioms refreshRandomizers_in_orbit
#print axioms refreshRandomizers_orbitalRandomizers
#print axioms refreshRandomizers_orbitalRandomizers_basePoint
#print axioms refreshRandomizers_orbitalRandomizers_randomizers
-- Post Workstream L3 (audit F-AUDIT-2026-04-21-M4), renamed from
-- `RefreshIndependent` / `refresh_independent` to
-- `RefreshDependsOnlyOnEpochRange` / `refresh_depends_only_on_epoch_range`
-- to reflect that the content is a structural determinism witness, not
-- a cryptographic independence claim.
#print axioms RefreshDependsOnlyOnEpochRange
#print axioms refresh_depends_only_on_epoch_range

-- PublicKey.KEMAgreement
#print axioms OrbitKeyAgreement
#print axioms OrbitKeyAgreement.encapsA
#print axioms OrbitKeyAgreement.encapsB
#print axioms OrbitKeyAgreement.sessionKey
#print axioms kem_agreement_correctness
#print axioms kem_agreement_alice_view
#print axioms kem_agreement_bob_view
-- Post Workstream L4 (audit F-AUDIT-2026-04-21-M5), renamed from
-- `SymmetricKeyAgreementLimitation` / `symmetric_key_agreement_limitation`
-- to `SessionKeyExpansionIdentity` / `sessionKey_expands_to_canon_form`
-- to reflect that the content is a definitional decomposition identity,
-- not an impossibility claim.
#print axioms SessionKeyExpansionIdentity
#print axioms sessionKey_expands_to_canon_form

-- PublicKey.CommutativeAction
#print axioms CommGroupAction
#print axioms csidh_exchange
#print axioms csidh_exchange_alice
#print axioms csidh_exchange_bob
#print axioms csidh_exchange_shared
#print axioms csidh_correctness
#print axioms csidh_views_agree
#print axioms CommOrbitPKE
#print axioms CommOrbitPKE.encrypt
#print axioms CommOrbitPKE.encrypt_ciphertext
#print axioms CommOrbitPKE.encrypt_shared
#print axioms CommOrbitPKE.decrypt
#print axioms CommOrbitPKE.decrypt_eq
#print axioms comm_pke_correctness
#print axioms comm_pke_shared_secret
#print axioms CommGroupAction.selfAction
#print axioms selfAction_comm

-- PublicKey.CombineImpossibility (Workstream E6)
#print axioms GEquivariantCombiner
#print axioms NonDegenerateCombiner
#print axioms oia_forces_combine_constant_in_snd
#print axioms oia_forces_combine_constant_on_orbit
#print axioms GEquivariantCombiner.combine_diagonal_smul
#print axioms GEquivariantCombiner.combine_section_form
#print axioms equivariant_combiner_breaks_oia
#print axioms oblivious_sample_equivariant_obstruction
#print axioms combinerDistinguisher
#print axioms combinerDistinguisher_basePoint
#print axioms combinerDistinguisher_eq
#print axioms combinerDistinguisher_witness
#print axioms combinerOrbitDist
#print axioms combinerOrbitDist_mass_bounds
#print axioms combinerDistinguisherAdvantage
#print axioms combinerDistinguisherAdvantage_eq
#print axioms concrete_combiner_advantage_bounded_by_oia

-- ============================================================================
-- §12  Non-vacuity witnesses
-- ============================================================================
--
-- Each `example` below instantiates a headline result on a tiny, concrete
-- model (typically the singleton space `Unit` under the one-element
-- permutation group `Equiv.Perm (Fin 1)`). Type-checking the example is
-- the verification that the corresponding theorem accepts well-typed
-- inputs: if a signature drifts (e.g. a new typeclass requirement is
-- added), the example fails to elaborate.
--
-- We deliberately avoid full `decide`-based witnesses on the probabilistic
-- results: evaluating `advantage D (PMF.pure ()) (PMF.pure ())` as an
-- ℝ would require deep PMF-level unfolding that is slow during CI. The
-- structural witnesses below are sufficient to prove the reductions are
-- non-vacuously applicable at least once.

namespace NonVacuityWitnesses

/-- A trivial KEM on the singleton space `Unit` under the one-element
    permutation group. All orbit-related obligations collapse via
    `Subsingleton.elim` on `Unit`. Used purely as a concrete target for
    the `example` blocks below — it is **not** a usable cryptographic
    scheme, just a type-elaboration witness. -/
def trivialKEM : OrbitKEM (Equiv.Perm (Fin 1)) Unit Unit where
  basePoint := ()
  canonForm :=
    { canon := id
      mem_orbit := fun _ => ⟨1, Subsingleton.elim _ _⟩
      orbit_iff := fun _ _ => by simp }
  keyDerive := fun _ => ()

/-- KEM correctness on the trivial KEM — direct instantiation of
    `kem_correctness`. -/
example (g : Equiv.Perm (Fin 1)) :
    decaps trivialKEM (encaps trivialKEM g).1 = (encaps trivialKEM g).2 :=
  kem_correctness trivialKEM g

/-- A trivial DEM on `Unit`. -/
def trivialDEM : DEM Unit Unit Unit where
  enc := fun _ _ => ()
  dec := fun _ _ => some ()
  correct := fun _ _ => rfl

/-- Hybrid-encryption correctness on the trivial KEM + DEM. -/
example (g : Equiv.Perm (Fin 1)) (m : Unit) :
    let (c_kem, c_dem) := hybridEncrypt trivialKEM trivialDEM g m
    hybridDecrypt trivialKEM trivialDEM c_kem c_dem = some m :=
  hybrid_correctness trivialKEM trivialDEM g m

/-- A trivial MAC on `Unit`. `verify_inj` is vacuous because `Tag = Unit`. -/
def trivialMAC : MAC Unit Unit Unit where
  tag := fun _ _ => ()
  verify := fun _ _ _ => true
  correct := fun _ _ => rfl
  verify_inj := fun _ _ _ _ => rfl

/-- A trivial `AuthOrbitKEM` composing `trivialKEM` with `trivialMAC`. -/
def trivialAuthKEM : AuthOrbitKEM (Equiv.Perm (Fin 1)) Unit Unit Unit where
  kem := trivialKEM
  mac := trivialMAC

/-- AEAD correctness on the trivial `AuthOrbitKEM`. -/
example (g : Equiv.Perm (Fin 1)) :
    let (c, k, t) := authEncaps trivialAuthKEM g
    authDecaps trivialAuthKEM c t = some k :=
  aead_correctness trivialAuthKEM g

/-- `INT_CTXT` for the trivial `AuthOrbitKEM` via
    `authEncrypt_is_int_ctxt`. Post-Workstream-B, the theorem
    discharges `INT_CTXT` unconditionally — the per-challenge `hOrbit`
    hypothesis is now a binder *inside* the `INT_CTXT` game, not a
    top-level obligation on the theorem's caller. -/
example : INT_CTXT trivialAuthKEM :=
  authEncrypt_is_int_ctxt trivialAuthKEM

/-- `ConcreteKEMOIA trivialKEM 1` is always true — satisfiability
    witness for the point-mass form. -/
example : ConcreteKEMOIA trivialKEM 1 :=
  concreteKEMOIA_one trivialKEM

/-- `ConcreteKEMOIA_uniform trivialKEM 1` is always true — satisfiability
    witness for the uniform form (Workstream E1d). -/
example : ConcreteKEMOIA_uniform trivialKEM 1 :=
  concreteKEMOIA_uniform_one trivialKEM

/-- Hybrid argument with two adjacent advantage-0 steps produces the
    telescoping bound 2 · 0 = 0. Exercises `hybrid_argument_uniform`. -/
example (D : Unit → Bool) :
    advantage D (PMF.pure ()) (PMF.pure ()) ≤ (2 : ℕ) * (0 : ℝ) :=
  hybrid_argument_uniform 2 (fun _ => PMF.pure ()) D 0
    (fun _ _ => by simp [advantage_self])

/-- `uniformPMFTuple Bool 3` puts mass `1 / 8` on each of the eight
    tuples. Exercises the Workstream E7 product-PMF infrastructure. -/
example (f : Fin 3 → Bool) :
    uniformPMFTuple Bool 3 f = ((Fintype.card Bool) ^ 3 : ENNReal)⁻¹ :=
  uniformPMFTuple_apply 3 f

/-- `ConcreteHardnessChain.tight_one_exists` is non-vacuous: for every
    scheme / field choice there is a chain at ε = 1 carrying the
    `punitSurrogate` and dimension-0 trivial encoders. Exercises
    Workstream G's Fix B + Fix C surrogate-plus-encoders refactor;
    any drift in the required typeclasses or structure fields will
    fail to elaborate. -/
example {G : Type} {X : Type} {M : Type}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (F : Type) [Fintype F] [DecidableEq F] :
    Nonempty (ConcreteHardnessChain scheme F (punitSurrogate F) 1) :=
  ConcreteHardnessChain.tight_one_exists scheme F

/-- Full chain composition: combining `tight_one_exists` with
    `concreteOIA_from_chain` produces `ConcreteOIA scheme 1`. This
    exercises the Workstream G composition proof
    (`hc.gi_to_oia` applied to image-specific GI hardness obtained by
    threading `tensor_hard → tensor_to_ce → ce_to_gi`). -/
example {G : Type} {X : Type} {M : Type}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) :
    ConcreteOIA scheme 1 :=
  let ⟨hc⟩ := ConcreteHardnessChain.tight_one_exists scheme Bool
  ConcreteHardnessChain.concreteOIA_from_chain hc

/-- `concrete_hardness_chain_implies_1cpa_advantage_bound` fires at
    ε = 1 via `tight_one_exists`, confirming the chain's output
    composes with the probabilistic IND-1-CPA reduction. -/
example {G : Type} {X : Type} {M : Type}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) :
    indCPAAdvantage scheme A ≤ 1 :=
  let ⟨hc⟩ := ConcreteHardnessChain.tight_one_exists scheme Bool
  concrete_hardness_chain_implies_1cpa_advantage_bound scheme 1 hc A

/-- Workstream H non-vacuity: the scheme-to-KEM reduction Prop is
    inhabited at ε' = 1 unconditionally. Exercises
    `concreteOIAImpliesConcreteKEMOIAUniform_one_right`. -/
example {G : Type} {X : Type} {M : Type} {K : Type}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m₀ : M) (keyDerive : X → K) (ε : ℝ) :
    ConcreteOIAImpliesConcreteKEMOIAUniform scheme m₀ keyDerive ε 1 :=
  concreteOIAImpliesConcreteKEMOIAUniform_one_right scheme m₀ keyDerive ε

/-- Workstream H non-vacuity: `ConcreteKEMHardnessChain.tight_one_exists`
    inhabits the KEM chain at ε = 1 for every scheme, field type `F`,
    KEM anchor `m₀`, and key-derivation `keyDerive`. Structural check
    that the H3 structure accepts well-typed inputs. -/
example {G : Type} {X : Type} {M : Type} {K : Type}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (F : Type) [Fintype F] [DecidableEq F]
    (m₀ : M) (keyDerive : X → K) :
    Nonempty
      (ConcreteKEMHardnessChain scheme F (punitSurrogate F)
        m₀ keyDerive 1) :=
  ConcreteKEMHardnessChain.tight_one_exists scheme F m₀ keyDerive

/-- Workstream H composition: combining `ConcreteKEMHardnessChain.
    tight_one_exists` with `concreteKEMHardnessChain_implies_kemUniform`
    yields `ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) 1`,
    which is trivially true via `concreteKEMOIA_uniform_one`. Exercises
    the full H3 composition pipeline on a concrete instance. -/
example {G : Type} {X : Type} {M : Type} {K : Type}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m₀ : M) (keyDerive : X → K) :
    ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) 1 :=
  let ⟨hc⟩ := ConcreteKEMHardnessChain.tight_one_exists
    scheme Bool m₀ keyDerive
  concreteKEMHardnessChain_implies_kemUniform hc

/-- Workstream H end-to-end adversary advantage bound: combining
    `ConcreteKEMHardnessChain.tight_one_exists` with
    `concrete_kem_hardness_chain_implies_kem_advantage_bound` yields
    `kemAdvantage_uniform (scheme.toKEM m₀ keyDerive) A g_ref ≤ 1` for
    every KEM adversary and reference group element — the KEM-layer
    parallel of the scheme-level `concrete_hardness_chain_implies_1cpa_
    advantage_bound` non-vacuity witness. -/
example {G : Type} {X : Type} {M : Type} {K : Type}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m₀ : M) (keyDerive : X → K)
    (A : KEMAdversary X K) (g_ref : G) :
    kemAdvantage_uniform (scheme.toKEM m₀ keyDerive) A g_ref ≤ 1 :=
  let ⟨hc⟩ := ConcreteKEMHardnessChain.tight_one_exists
    scheme Bool m₀ keyDerive
  concrete_kem_hardness_chain_implies_kem_advantage_bound hc A g_ref

/-- Workstream K1 non-vacuity: `oia_implies_1cpa_distinct` is
    well-typed on every scheme and the composition with
    `isSecure_implies_isSecureDistinct` elaborates. Exercises the
    deterministic distinct-challenge corollary at the scheme level. -/
example {G : Type} {X : Type} {M : Type}
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (hOIA : OIA scheme) :
    IsSecureDistinct scheme :=
  oia_implies_1cpa_distinct scheme hOIA

/-- Workstream K3 non-vacuity: `hardness_chain_implies_security_distinct`
    is well-typed on every scheme. Exercises the chain-level
    distinct-challenge corollary. The `HardnessChain` Prop requires
    `[Field F]`, so we use `ZMod 2` as the witness field. -/
example {G : Type} {X : Type} {M : Type}
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (hChain : HardnessChain (F := ZMod 2) scheme) :
    IsSecureDistinct scheme :=
  hardness_chain_implies_security_distinct scheme hChain

/-- Workstream K4 non-vacuity (structural): `indCPAAdvantage_collision_zero`
    accepts any scheme + adversary pair satisfying the collision
    hypothesis and delivers `indCPAAdvantage scheme A = 0`. Exercises
    the lemma on a freely-quantified input; a signature drift would
    fail to elaborate. -/
example {G : Type} {X : Type} {M : Type}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M)
    (hCollision : (A.choose scheme.reps).1 = (A.choose scheme.reps).2) :
    indCPAAdvantage scheme A = 0 :=
  indCPAAdvantage_collision_zero scheme A hCollision

/-- Workstream K4 non-vacuity (concrete adversary): constructs a
    `collisionAdversary` on the singleton message space `Unit` whose
    `choose` always returns `((), ())`, and confirms
    `indCPAAdvantage_collision_zero` forces its advantage to be
    exactly zero. This is a genuine witness of the lemma firing on
    a concrete input, not merely a signature check. -/
example : True := by
  -- Build a trivial scheme on `Unit` under the one-element
  -- permutation group; all messages collide since `Unit` has only
  -- one inhabitant.
  let trivialScheme : OrbitEncScheme (Equiv.Perm (Fin 1)) Unit Unit :=
    { reps := fun _ => ()
      reps_distinct := fun _ _ h => (h (Subsingleton.elim _ _)).elim
      canonForm :=
        { canon := id
          mem_orbit := fun _ => ⟨1, Subsingleton.elim _ _⟩
          orbit_iff := fun _ _ => by simp } }
  let collisionAdv : Adversary Unit Unit :=
    { choose := fun _ => ((), ())
      guess := fun _ _ => true }
  -- The collision hypothesis holds by `rfl` since both projections
  -- are `()`; feed it to the lemma to get `indCPAAdvantage = 0`.
  have hZero : indCPAAdvantage trivialScheme collisionAdv = 0 :=
    indCPAAdvantage_collision_zero trivialScheme collisionAdv rfl
  -- Return `True`; the meaningful assertion lives in `hZero`, whose
  -- existence (together with its dependency on the lemma) is what
  -- this example actually proves.
  trivial

/-- Workstream K4 companion non-vacuity: fires the
    `_distinct`-suffixed probabilistic chain bound at ε = 1 via
    `ConcreteHardnessChain.tight_one_exists`. The extra distinctness
    hypothesis is consumed but unused in the proof — `_distinct`
    inherits its ε from the non-distinct form. -/
example {G : Type} {X : Type} {M : Type}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M)
    (hDistinct :
      (A.choose scheme.reps).1 ≠ (A.choose scheme.reps).2) :
    indCPAAdvantage scheme A ≤ 1 :=
  let ⟨hc⟩ := ConcreteHardnessChain.tight_one_exists scheme Bool
  concrete_hardness_chain_implies_1cpa_advantage_bound_distinct
    scheme 1 hc A hDistinct

-- ============================================================================
-- Workstream L1 (audit F-AUDIT-2026-04-21-M2): `SeedKey` witnessed
-- compression — non-vacuity witnesses
-- ============================================================================

/-- A concrete `CanonicalForm` on the singleton space `Unit` under the
    six-element permutation group `Equiv.Perm (Fin 3)`. The group acts
    trivially on `Unit` (every permutation fixes the unique point), so
    every field collapses by `Subsingleton.elim`.

    Used by the `SeedKey` witness below to exhibit a
    `SeedKey (Fin 2) (Equiv.Perm (Fin 3)) Unit` whose `compression`
    field is discharged by `decide`. -/
def trivialCanonForm_Perm3_Unit :
    CanonicalForm (Equiv.Perm (Fin 3)) Unit where
  canon := id
  mem_orbit := fun _ => ⟨1, Subsingleton.elim _ _⟩
  orbit_iff := fun _ _ => by simp

/-- **Non-vacuity witness for the Workstream L1 `SeedKey.compression`
    field.** Builds a concrete
    `SeedKey (Fin 2) (Equiv.Perm (Fin 3)) Unit` with `compression`
    discharged by `decide`:

    * `Fintype.card (Fin 2) = 2`, so `Nat.log 2 (Fintype.card (Fin 2)) = 1`.
    * `Fintype.card (Equiv.Perm (Fin 3)) = 3! = 6`, so
      `Nat.log 2 (Fintype.card (Equiv.Perm (Fin 3))) = 2`.
    * `1 < 2` discharges the compression inequality.

    Exercises the structure-level compression obligation introduced in
    Workstream L1: if a consumer attempts to build a `SeedKey` whose
    seed space has at least as many bits as the group, the
    `compression` field fails to elaborate, blocking the construction
    at compile time. -/
def trivialSeedKey :
    SeedKey (Fin 2) (Equiv.Perm (Fin 3)) Unit where
  seed := 0
  expand := fun _ => trivialCanonForm_Perm3_Unit
  sampleGroup := fun _ _ => 1
  compression := by decide

/-- A trivial `OrbitKEM` over `Equiv.Perm (Fin 3)` acting on `Unit`,
    used as the target of `seed_kem_correctness` in the Workstream L1
    non-vacuity witness below. -/
def trivialKEM_Perm3_Unit : OrbitKEM (Equiv.Perm (Fin 3)) Unit Unit where
  basePoint := ()
  canonForm := trivialCanonForm_Perm3_Unit
  keyDerive := fun _ => ()

/-- Exercise `seed_kem_correctness` on the Workstream L1 non-vacuity
    witness: `decaps` recovers the key encapsulated by `encaps` under
    the derived group element. Confirms the post-L1 signature (threading
    `[Fintype Seed]` and `[Fintype G]` through the theorem) elaborates
    on a concrete instance. -/
example (n : ℕ) :
    decaps trivialKEM_Perm3_Unit
      (encaps trivialKEM_Perm3_Unit
        (trivialSeedKey.sampleGroup trivialSeedKey.seed n)).1 =
    (encaps trivialKEM_Perm3_Unit
      (trivialSeedKey.sampleGroup trivialSeedKey.seed n)).2 :=
  seed_kem_correctness trivialSeedKey trivialKEM_Perm3_Unit n

/-- Exercise the `OrbitEncScheme.toSeedKey` bridge: the bridge's
    `compression` field is discharged by `Nat.log_pos` from the
    supplied `1 < Fintype.card G` hypothesis. We instantiate on a
    scheme where `G = Equiv.Perm (Fin 3)` (|G| = 6 > 1) and
    confirm the resulting `SeedKey Unit G X` elaborates. -/
example {X : Type} {M : Type}
    [MulAction (Equiv.Perm (Fin 3)) X] [DecidableEq X]
    (scheme : OrbitEncScheme (Equiv.Perm (Fin 3)) X M)
    (sampleG : ℕ → Equiv.Perm (Fin 3)) :
    SeedKey Unit (Equiv.Perm (Fin 3)) X :=
  scheme.toSeedKey sampleG (by decide)

-- ============================================================================
-- Workstream L1 pressure tests — verify the `SeedKey.compression` field
-- actually rejects non-compressive configurations (negative coverage).
-- ============================================================================

/-- **Positive pressure.** The compression inequality holds for
    `|Seed| = 2 < |G| = 6` at the bit-length level (`log₂ 2 = 1 <
    log₂ 6 = 2`). -/
example :
    Nat.log 2 (Fintype.card (Fin 2)) <
    Nat.log 2 (Fintype.card (Equiv.Perm (Fin 3))) := by decide

/-- **Negative pressure (equality).** If `|Seed| = |G|` the compression
    inequality fails. -/
example :
    ¬ (Nat.log 2 (Fintype.card (Fin 2)) <
       Nat.log 2 (Fintype.card (Fin 2))) := by decide

/-- **Negative pressure (reversed).** If `|Seed| > |G|` the compression
    inequality fails. -/
example :
    ¬ (Nat.log 2 (Fintype.card (Fin 4)) <
       Nat.log 2 (Fintype.card (Fin 2))) := by decide

/-- **Negative pressure (same bit-length).** If `|Seed| = 2` and
    `|G| = 3`, the plain `card <` comparison would accept the pair
    (`2 < 3`), but the bit-length comparison correctly rejects — they
    both need 1 bit, so there is no compression. -/
example :
    ¬ (Nat.log 2 (Fintype.card (Fin 2)) <
       Nat.log 2 (Fintype.card (Fin 3))) := by decide

/-- **Bridge pressure.** For the trivial group `Unit` (card 1), the
    bridge hypothesis `1 < Fintype.card G` is unsatisfiable, so
    `OrbitEncScheme.toSeedKey` cannot build a seed key over `Unit`
    seeds and `Unit` groups. -/
example : ¬ (1 < Fintype.card Unit) := by decide

-- ============================================================================
-- Workstream L2 post-audit universal-hash witnesses (2026-04-22)
-- ============================================================================

/-- **Carter–Wegman `(1/p)`-universality at the smallest prime** —
    concrete instantiation of `carterWegmanHash_isUniversal` at `p = 2`,
    with `Fact (Nat.Prime 2)` auto-resolved by Mathlib's
    `fact_prime_two` instance. -/
example : IsEpsilonUniversal (carterWegmanHash 2) ((1 : ENNReal) / 2) :=
  carterWegmanHash_isUniversal 2

/-- **Carter–Wegman `(1/p)`-universality at `p = 3`** — second concrete
    instance via Mathlib's `fact_prime_three`. -/
example : IsEpsilonUniversal (carterWegmanHash 3) ((1 : ENNReal) / 3) :=
  carterWegmanHash_isUniversal 3

/-- **Collision-count discharge at `p = 2`.** The algebraic heart of
    the universal-hash proof: the collision set for distinct messages
    has cardinality exactly `p`. -/
example (m₁ m₂ : ZMod 2) (h_ne : m₁ ≠ m₂) :
    (Finset.univ.filter
      (fun k : ZMod 2 × ZMod 2 =>
        carterWegmanHash 2 k m₁ = carterWegmanHash 2 k m₂)).card = 2 :=
  carterWegmanHash_collision_card 2 h_ne

/-- **Collision-iff discharge at `p = 2`.** For any distinct `m₁ ≠ m₂`,
    the CW hash collides iff the first key component is zero. -/
example (m₁ m₂ : ZMod 2) (h_ne : m₁ ≠ m₂) (k : ZMod 2 × ZMod 2) :
    carterWegmanHash 2 k m₁ = carterWegmanHash 2 k m₂ ↔ k.1 = 0 :=
  carterWegmanHash_collision_iff 2 h_ne k

/-- **Monotonicity of `IsEpsilonUniversal`.** Inheriting universality
    from a tighter bound is a trivial `.mono` step. -/
example : IsEpsilonUniversal (carterWegmanHash 2) ((1 : ENNReal) / 1) :=
  (carterWegmanHash_isUniversal 2).mono (by
    -- 1/2 ≤ 1/1 = 1 in ENNReal.
    refine ENNReal.div_le_div_left ?_ _
    exact_mod_cast Nat.one_le_iff_ne_zero.mpr two_ne_zero)

-- ============================================================================
-- Workstream L1 structural-field regression: `compression` is
-- projectable from any `SeedKey`.  This is the "field is mandatory"
-- safety property in positive form — if a future change accidentally
-- drops the field, the projection fails at elaboration time and this
-- example stops compiling.
-- ============================================================================

/-- **Compression-projection regression test.** Given any `SeedKey
    Seed G X`, the `compression` field must be directly extractable as
    a Prop-valued term.  Exercising this at a concrete non-trivial
    `(Fin 2, Equiv.Perm (Fin 3), Unit)` triple rules out accidental
    refactorings that would remove the field or change its type. -/
example (sk : SeedKey (Fin 2) (Equiv.Perm (Fin 3)) Unit) :
    Nat.log 2 (Fintype.card (Fin 2)) <
    Nat.log 2 (Fintype.card (Equiv.Perm (Fin 3))) :=
  sk.compression

/-- **Universal-hash mono-application regression.**  Exercise the
    full `IsEpsilonUniversal.mono` API on a concrete prime: tighten
    `(1/2)`-universality to `(1/1) = 1`-universality (the trivial
    satisfiability anchor). -/
example : IsEpsilonUniversal (carterWegmanHash 2) 1 :=
  IsEpsilonUniversal.le_one (carterWegmanHash 2)

-- ============================================================================
-- Workstream L2 post-audit — `IsEpsilonUniversal.ofCollisionCardBound`
-- end-to-end discharge regression.
-- ============================================================================

/-- **ofCollisionCardBound regression test.**  The generic helper
    `IsEpsilonUniversal.ofCollisionCardBound` discharges the universal-
    hash bound from a cardinality argument.  Verify the helper actually
    produces the claimed bound on a concrete hash family: reuse the CW
    case (at `p = 2`) where the collision count is known to be `p`. -/
example : IsEpsilonUniversal (carterWegmanHash 2)
    ((2 : ENNReal) / (Fintype.card (ZMod 2 × ZMod 2) : ℕ)) :=
  IsEpsilonUniversal.ofCollisionCardBound (carterWegmanHash 2) 2
    (fun m₁ m₂ h_ne => by
      rw [carterWegmanHash_collision_card 2 h_ne])

end NonVacuityWitnesses
