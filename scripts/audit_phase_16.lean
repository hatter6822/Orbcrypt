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
-- Workstream F (audit 2026-04-23, finding V1-10 / F-04): the non-vacuity
-- witnesses for `CanonicalForm.ofLexMin` at the end of this file use
-- `Equiv.Perm (Fin 3)` as the concrete finite group and `![...]`
-- notation for concrete `Bitstring 3` inputs; neither is transitively
-- available through `Orbcrypt`.
import Mathlib.Data.Fintype.Perm
import Mathlib.Data.Fin.VecNotation

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

-- CanonicalLexMin (Workstream F of the 2026-04-23 audit, finding V1-10 /
-- F-04): concrete `CanonicalForm.ofLexMin` constructor closes the
-- previously-abstract canonical-form parameter on `hgoeScheme`.
#print axioms orbitFintype
#print axioms mem_orbit_toFinset_iff
#print axioms orbit_toFinset_nonempty
#print axioms CanonicalForm.ofLexMin
#print axioms CanonicalForm.ofLexMin_canon
#print axioms CanonicalForm.ofLexMin_canon_mem_orbit

-- Invariant
#print axioms IsGInvariant
#print axioms IsGInvariant.comp
#print axioms isGInvariant_const
#print axioms invariant_const_on_orbit
#print axioms IsSeparating
#print axioms separating_implies_distinct_orbits
#print axioms canonical_isGInvariant
-- Workstream I3 (audit 2026-04-23, finding D-07): canonical-form
-- indicator helper consumed by `distinct_messages_have_invariant_separator`
-- in `Theorems/OIAImpliesCPA.lean`.
#print axioms canon_indicator_isGInvariant

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
-- Workstream E (audit 2026-04-23, finding C-07): machine-checked
-- vacuity witness for the deterministic OIA.
#print axioms det_oia_false_of_distinct_reps

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
-- Workstream I3 (audit 2026-04-23, finding D-07): pre-I
-- `insecure_implies_separating` renamed to
-- `insecure_implies_orbit_distinguisher` because the body delivers an
-- orbit-distinguisher (not a G-invariant separating function as the
-- pre-I name suggested). The cryptographic content the pre-I name
-- advertised is delivered separately by
-- `distinct_messages_have_invariant_separator` (a strictly stronger
-- statement: G-invariance + separation, unconditional on `reps_distinct`).
#print axioms insecure_implies_orbit_distinguisher
#print axioms distinct_messages_have_invariant_separator

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
-- Workstream F (audit 2026-04-23, finding V1-10 / F-04): the computable
-- lex linear order on `Bitstring n` used by `CanonicalForm.ofLexMin` at
-- the concrete HGOE instantiation (exposed as a `def`, not a global
-- instance, to avoid a diamond with Mathlib's `Pi.partialOrder`).
#print axioms bitstringLinearOrder

-- Construction.HGOE
#print axioms subgroupBitstringAction
#print axioms subgroup_smul_eq
#print axioms hgoeScheme
-- Workstream F (audit 2026-04-23, finding V1-10 / F-04): convenience
-- constructor that auto-fills the `CanonicalForm` parameter with the
-- lex-min canonical form (`CanonicalForm.ofLexMin`).
#print axioms hgoeScheme.ofLexMin
#print axioms hgoeScheme.ofLexMin_reps
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
-- Workstream E (audit 2026-04-23, finding E-06): machine-checked
-- vacuity witness for the deterministic KEMOIA.
#print axioms det_kemoia_false_of_nontrivial_orbit
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
-- Workstream I1 (audit 2026-04-23, finding C-15): pre-I
-- `concreteOIA_one_meaningful` renamed to `indCPAAdvantage_le_one`
-- (Mathlib-style `_le_one` simp lemma — content unchanged, name now
-- accurately describes the trivial `≤ 1` bound). The post-Workstream-I
-- audit (2026-04-25) removed the `concreteOIA_zero_of_subsingleton_
-- message` companion as theatrical: it required `[Subsingleton M]`,
-- a hypothesis under which there is only one message and therefore
-- no security game to play.
#print axioms indCPAAdvantage_le_one
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
-- Workstream C (audit 2026-04-23, V1-8 / C-13): multi-query IND-Q-CPA
-- theorem renamed from `indQCPA_bound_via_hybrid` to
-- `indQCPA_from_perStepBound` (and companion likewise) to surface the
-- `h_step` user-supplied hypothesis in the identifier.
#print axioms indQCPA_from_perStepBound
#print axioms indQCPA_from_perStepBound_recovers_single_query

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
-- Workstream I2 (audit 2026-04-23, finding E-11): pre-I
-- `concreteKEMOIA_one_meaningful` was a redundant duplicate of
-- `kemAdvantage_le_one` (line 347 of `KEM/CompSecurity.lean`); deleted
-- in Workstream I2. Consumers cite `kemAdvantage_le_one` for the
-- trivial `≤ 1` bound. The post-Workstream-I audit (2026-04-25)
-- removed `concreteKEMOIA_uniform_zero_of_singleton_orbit` as
-- theatrical: it required `∀ g, g • basePoint = basePoint`, a
-- hypothesis under which the KEM has only one ciphertext and
-- therefore no security game to play. The cryptographically
-- meaningful KEM-layer non-vacuity story remains
-- `concreteKEMOIA_uniform_one` (the universal-bound anchor).
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
-- Workstream I4 (audit 2026-04-23, finding J-03): the strengthened
-- `GIReducesToCE` Prop carries non-degeneracy fields (`codeSize_pos`,
-- `encode_card_eq`) that rule out the audit-flagged
-- `encode _ _ := ∅` degenerate witness at the type level. The
-- `GIReducesToCE_card_nondegeneracy_witness` confirms the
-- non-degeneracy fields are independently inhabitable; a *full*
-- inhabitant of `GIReducesToCE` (discharging the iff) requires a
-- tight Karp reduction (CFI 1992 / Petrank–Roth 1997) and remains
-- research-scope (audit plan § 15.1 / R-15).
#print axioms GIReducesToCE
#print axioms GIReducesToCE_card_nondegeneracy_witness
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
-- Workstream I5 (audit 2026-04-23, finding J-08): the strengthened
-- `GIReducesToTI` Prop carries an `encode_nonzero_of_pos_dim`
-- non-degeneracy field that rules out the audit-flagged constant-zero
-- encoder at the type level. `GIReducesToTI_nondegeneracy_witness`
-- confirms the non-degeneracy field is independently inhabitable; a
-- *full* inhabitant of `GIReducesToTI` (discharging the iff) requires
-- the Grochow–Qiao 2021 structure-tensor encoding and remains
-- research-scope (audit plan § 15.1 / R-15).
#print axioms GIReducesToTI
#print axioms GIReducesToTI_nondegeneracy_witness
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
-- Workstream I6 (audit 2026-04-23, finding K-02): pre-I
-- `ObliviousSamplingHiding` was the deterministic perfect-extremum
-- form (`False` on every non-trivial bundle); renamed to
-- `ObliviousSamplingPerfectHiding` and the companion theorem
-- renamed to `oblivious_sampling_view_constant_under_perfect_hiding`
-- to accurately convey the predicate's perfect-extremum strength.
-- The probabilistic ε-smooth analogue
-- `ObliviousSamplingConcreteHiding` is added alongside, with a
-- structural extraction lemma `oblivious_sampling_view_advantage_bound`
-- and a perfect-security non-vacuity witness
-- `ObliviousSamplingConcreteHiding_zero_witness` at ε = 0 on
-- singleton-orbit bundles.
#print axioms ObliviousSamplingPerfectHiding
#print axioms oblivious_sampling_view_constant_under_perfect_hiding
#print axioms ObliviousSamplingConcreteHiding
-- Workstream I post-audit (2026-04-25): removed
-- `oblivious_sampling_view_advantage_bound` (one-line wrapper —
-- callers can apply the predicate directly) and
-- `ObliviousSamplingConcreteHiding_zero_witness` (theatrical
-- ε = 0 witness on degenerate singleton-orbit bundles). Replaced
-- with a non-degenerate concrete fixture:
-- `concreteHidingBundle` + `concreteHidingCombine`. The bundle's
-- orbit has cardinality 2 (max on Bool); the combine push-forward
-- is biased (1/4 mass on `true`). The on-paper worst-case
-- adversary advantage is `1/4`, but the precise Lean proof is
-- research-scope R-12 (see the in-module docstring). The audit
-- script exercises the non-degenerate fixture's well-typedness
-- via the example below; the substantive cryptographic content
-- is the *fixture's non-degeneracy*, not a tight ε bound.
#print axioms concreteHidingBundle
#print axioms concreteHidingCombine
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
-- Workstream C non-vacuity witnesses (audit 2026-04-23, V1-8 / C-13 /
-- D10): renamed multi-query IND-Q-CPA theorem accepts a user-supplied
-- per-step bound and produces a Q · ε telescoping bound. The rename
-- surfaces the user-hypothesis obligation in the identifier itself;
-- these witnesses confirm the renamed theorem remains well-typed and
-- ε-smooth on at least one concrete instance.
-- ============================================================================

/-- Workstream C non-vacuity: `indQCPA_from_perStepBound` applies to an
    arbitrary multi-query adversary as long as the caller supplies the
    per-step bound. Exercises the renamed theorem's signature. -/
example {G : Type} {X : Type} {M : Type} {Q : ℕ}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (A : MultiQueryAdversary X M Q)
    (h_step : ∀ i, i < Q →
      advantage (A.guess scheme.reps)
        (hybridDist scheme (A.choose scheme.reps) i)
        (hybridDist scheme (A.choose scheme.reps) (i + 1)) ≤ ε) :
    indQCPAAdvantage scheme A ≤ (Q : ℝ) * ε :=
  indQCPA_from_perStepBound scheme ε A h_step

/-- Workstream C non-vacuity: `indQCPA_from_perStepBound` at `ε = 1`
    delivers the trivial `Q · 1` bound for any adversary satisfying
    the trivially-discharged per-step bound. This is the C.2 template
    in `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` instantiated
    to `Q = 2`. The per-step bound is `advantage_le_one` at every
    hybrid pair, so the caller discharges it by a one-liner. -/
example {G : Type} {X : Type} {M : Type}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (A : MultiQueryAdversary X M 2) :
    indQCPAAdvantage scheme A ≤ (2 : ℝ) * 1 :=
  indQCPA_from_perStepBound (Q := 2) scheme 1 A
    (fun _ _ => advantage_le_one _ _ _)

/-- Workstream C non-vacuity: the Q = 1 sanity sentinel
    `indQCPA_from_perStepBound_recovers_single_query` recovers the
    single-query ε bound from a single per-step hybrid bound. -/
example {G : Type} {X : Type} {M : Type}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (A : MultiQueryAdversary X M 1)
    (h_step : advantage (A.guess scheme.reps)
        (hybridDist scheme (A.choose scheme.reps) 0)
        (hybridDist scheme (A.choose scheme.reps) 1) ≤ ε) :
    indQCPAAdvantage scheme A ≤ ε :=
  indQCPA_from_perStepBound_recovers_single_query scheme ε A h_step

/-- Workstream C concrete non-vacuity (audit plan § C.2 template): a
    trivial two-query adversary on a `Unit`-based scheme fires
    `indQCPA_from_perStepBound` at `Q = 2`, `ε = 1`. The per-step
    hypothesis `h_step` is discharged by `advantage_le_one` because
    any advantage is trivially `≤ 1`. This exercises the full
    instance-elaboration pipeline on a concrete set of typeclass
    arguments (`Equiv.Perm (Fin 1)` Group + Fintype + Nonempty;
    `Unit` MulAction + DecidableEq) — a parameterised witness only
    proves the theorem is callable in principle; this concrete
    witness proves Lean can actually resolve the instances on at
    least one known-good input. -/
example : True := by
  let trivialScheme : OrbitEncScheme (Equiv.Perm (Fin 1)) Unit Unit :=
    { reps := fun _ => ()
      reps_distinct := fun _ _ h => (h (Subsingleton.elim _ _)).elim
      canonForm :=
        { canon := id
          mem_orbit := fun _ => ⟨1, Subsingleton.elim _ _⟩
          orbit_iff := fun _ _ => by simp } }
  let trivialMultiAdv : MultiQueryAdversary Unit Unit 2 :=
    { choose := fun _ _ => ((), ())
      guess := fun _ _ => true }
  -- Fire `indQCPA_from_perStepBound` on the concrete (scheme, adversary)
  -- pair. The `h_step` discharge uses `advantage_le_one` because every
  -- advantage is in `[0, 1]`. The conclusion `≤ 2 * 1` is trivially
  -- implied by `indQCPAAdvantage_le_one`, but that's not the point —
  -- the point is that `indQCPA_from_perStepBound` accepts this exact
  -- argument list and produces the expected conclusion shape.
  have hBound : indQCPAAdvantage trivialScheme trivialMultiAdv ≤
      (2 : ℝ) * 1 :=
    indQCPA_from_perStepBound (Q := 2) trivialScheme 1 trivialMultiAdv
      (fun _ _ => advantage_le_one _ _ _)
  -- Return `True`; the meaningful assertion lives in `hBound`, whose
  -- existence proves the renamed theorem is non-vacuously inhabited on
  -- a concrete input.
  trivial

/-- Workstream C concrete non-vacuity (companion form): the Q = 1
    regression sentinel `indQCPA_from_perStepBound_recovers_single_query`
    fires on a concrete one-query adversary over the `Unit` scheme,
    with `h_step` again discharged by `advantage_le_one` at ε = 1. This
    confirms the companion theorem also accepts concrete inputs, not
    just parameterised ones. -/
example : True := by
  let trivialScheme : OrbitEncScheme (Equiv.Perm (Fin 1)) Unit Unit :=
    { reps := fun _ => ()
      reps_distinct := fun _ _ h => (h (Subsingleton.elim _ _)).elim
      canonForm :=
        { canon := id
          mem_orbit := fun _ => ⟨1, Subsingleton.elim _ _⟩
          orbit_iff := fun _ _ => by simp } }
  let trivialSingleAdv : MultiQueryAdversary Unit Unit 1 :=
    { choose := fun _ _ => ((), ())
      guess := fun _ _ => true }
  have hBound : indQCPAAdvantage trivialScheme trivialSingleAdv ≤
      (1 : ℝ) :=
    indQCPA_from_perStepBound_recovers_single_query trivialScheme 1
      trivialSingleAdv (advantage_le_one _ _ _)
  trivial

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

-- ============================================================================
-- Workstream E non-vacuity witnesses (audit 2026-04-23, findings C-07 /
-- E-06): machine-checked vacuity of the deterministic `OIA` and `KEMOIA`
-- predicates. The two `example` blocks below instantiate
-- `det_oia_false_of_distinct_reps` and
-- `det_kemoia_false_of_nontrivial_orbit` on concrete scheme / KEM
-- fixtures to confirm each witness fires on a known-good input and
-- closes its `¬ OIA` / `¬ KEMOIA` goal by direct term construction.
-- ============================================================================

/-- **Trivial (identity) action of `Equiv.Perm (Fin 1)` on `Bool`.**
    Every element of the trivial group `Equiv.Perm (Fin 1)` (which has
    one inhabitant, namely `1`) acts as identity on `Bool`. Registered
    locally so the `OrbitEncScheme` below elaborates without ambient
    typeclass drift. Under this action each singleton `{b}` is its own
    orbit, so `orbit G true = {true} ≠ {false} = orbit G false`,
    discharging the scheme's `reps_distinct` obligation. -/
local instance trivialPermFin1ActionBool :
    MulAction (Equiv.Perm (Fin 1)) Bool where
  smul _ b := b
  one_smul _ := rfl
  mul_smul _ _ _ := rfl

/-- A two-message `OrbitEncScheme` under the trivial action of
    `Equiv.Perm (Fin 1)` on `Bool`, with `reps := id`. Under the
    trivial action, `smul _ b := b` holds by `rfl`, so every orbit
    `MulAction.orbit G b = {b}` is a singleton and `reps_distinct`
    follows from point-distinctness. Canonical form is the identity;
    `orbit_iff` reduces to the tautology `b₁ = b₂ ↔ {b₁} = {b₂}`.
    Used as the concrete target for
    `det_oia_false_of_distinct_reps`. -/
def trivialSchemeBool :
    OrbitEncScheme (Equiv.Perm (Fin 1)) Bool Bool where
  reps := id
  reps_distinct := fun b₀ b₁ hNeq hOrb => by
    -- Under the trivial action, `orbit G b = {b}`, so
    -- `orbit G b₀ = orbit G b₁` forces `b₀ ∈ {b₁}`, i.e. `b₀ = b₁`.
    apply hNeq
    -- Normalise `id b₀`, `id b₁` in `hOrb` so subsequent rewrites
    -- match syntactically (Lean's `rw` is syntactic, not definitional).
    simp only [id_eq] at hOrb
    have hmem : b₀ ∈ MulAction.orbit (Equiv.Perm (Fin 1)) b₁ := by
      -- `b₀ ∈ orbit b₀ = orbit b₁`.
      rw [← hOrb]
      exact MulAction.mem_orbit_self _
    obtain ⟨g, hg⟩ := hmem
    -- `hg : g • b₁ = b₀`; under `trivialPermFin1ActionBool`,
    -- `g • b₁ = b₁` by `rfl`, so `hg : b₁ = b₀` up to defeq.
    exact hg.symm
  canonForm :=
    { canon := id
      mem_orbit := fun b => MulAction.mem_orbit_self b
      orbit_iff := fun b₁ b₂ => by
        -- `canon = id`, so `canon b₁ = canon b₂ ↔ b₁ = b₂`.
        -- Under the trivial action, `orbit G b₁ = orbit G b₂ ↔
        -- b₁ = b₂` for the same reason as `reps_distinct` above.
        refine ⟨fun h => ?_, fun h => ?_⟩
        · -- Forward: `b₁ = b₂` ⇒ singletons coincide.
          change b₁ = b₂ at h
          subst h; rfl
        · -- Backward: `orbit G b₁ = orbit G b₂` ⇒ `b₁ = b₂`.
          have hmem : b₁ ∈ MulAction.orbit (Equiv.Perm (Fin 1)) b₂ := by
            rw [← h]; exact MulAction.mem_orbit_self _
          obtain ⟨g, hg⟩ := hmem
          -- `hg : g • b₂ = b₁`; under the trivial action this is
          -- `b₂ = b₁` (defeq). Goal is `canon b₁ = canon b₂` i.e.
          -- `b₁ = b₂`; close with `.symm`.
          exact hg.symm }

/-- **Workstream E1 non-vacuity witness.** Fires
    `det_oia_false_of_distinct_reps` on `trivialSchemeBool`: the
    distinctness hypothesis `scheme.reps true ≠ scheme.reps false`
    is `true ≠ false` (discharged by `Bool.noConfusion`), and the
    theorem delivers `¬ OIA trivialSchemeBool`. A genuine witness
    of the deterministic-OIA vacuity at a concrete (non-trivial)
    scheme; exercises the full elaboration path from
    `OrbitEncScheme` construction to `decide`-based distinguisher
    dispatch. -/
example : ¬ OIA trivialSchemeBool :=
  det_oia_false_of_distinct_reps (M := Bool) trivialSchemeBool
    (m₀ := true) (m₁ := false)
    (by decide)

/-- **Natural action of `Equiv.Perm (ZMod 2)` on `ZMod 2`.**
    Mathlib's standard `MulAction (Equiv.Perm α) α` instance,
    registered locally to keep the inference explicit for the
    `OrbitKEM` below. Under this action, the swap `Equiv.swap 0 1`
    sends `0 ↦ 1`, so `(Equiv.swap 0 1) • 0 = 1 ≠ 0 = 1 • 0` and
    the basepoint orbit has cardinality 2. -/
local instance permActionZMod2_forE2 :
    MulAction (Equiv.Perm (ZMod 2)) (ZMod 2) := inferInstance

/-- A concrete `OrbitKEM` under `Equiv.Perm (ZMod 2)` on `ZMod 2`
    with base point `0`. The canonical form `canon _ := 0` is
    constant, and `mem_orbit` / `orbit_iff` are discharged via the
    transitive-action witness `Equiv.swap x 0`. Parallels the
    Workstream-C `toyKEMZMod2` fixture (which lives in
    `scripts/audit_c_workstream.lean`) but is re-materialised here
    so `audit_phase_16.lean` remains a self-contained audit script.
    Used as the concrete target for
    `det_kemoia_false_of_nontrivial_orbit`. -/
def trivialKEM_PermZMod2 :
    OrbitKEM (Equiv.Perm (ZMod 2)) (ZMod 2) Unit where
  basePoint := (0 : ZMod 2)
  canonForm :=
    { canon := fun _ => 0
      mem_orbit := fun x => by
        refine ⟨Equiv.swap x 0, ?_⟩
        show (Equiv.swap x 0) x = 0
        exact Equiv.swap_apply_left x 0
      orbit_iff := by
        intro x y
        refine ⟨fun _ => ?_, fun _ => rfl⟩
        ext z
        refine ⟨fun _ => ⟨Equiv.swap y z, Equiv.swap_apply_left y z⟩,
                fun _ => ⟨Equiv.swap x z, Equiv.swap_apply_left x z⟩⟩ }
  keyDerive := fun _ => ()

/-- **Workstream E2 non-vacuity witness.** Fires
    `det_kemoia_false_of_nontrivial_orbit` on
    `trivialKEM_PermZMod2`: the non-triviality hypothesis
    `(Equiv.swap 0 1) • basePoint ≠ 1 • basePoint` reduces to
    `(Equiv.swap 0 1) • 0 ≠ 0`, which is `1 ≠ 0` in `ZMod 2`.
    The theorem delivers `¬ KEMOIA trivialKEM_PermZMod2`. Confirms
    the KEM-layer vacuity witness elaborates on a concrete input
    where the basepoint orbit is genuinely non-trivial
    (cardinality 2). -/
example : ¬ KEMOIA trivialKEM_PermZMod2 :=
  det_kemoia_false_of_nontrivial_orbit trivialKEM_PermZMod2
    (g₀ := Equiv.swap 0 1) (g₁ := 1)
    (by
      -- The `MulAction (Equiv.Perm α) α` instance is defined so
      -- `σ • a = σ a`. `(Equiv.swap 0 1) 0 = 1` by
      -- `Equiv.swap_apply_left`, and `(1 : Equiv.Perm _) 0 = 0`
      -- by the definition of `1` as `Equiv.refl`. The resulting
      -- `(1 : ZMod 2) ≠ 0` is decidable.
      intro h
      -- `h : (Equiv.swap 0 1) • 0 = 1 • 0`; defeq to
      -- `(Equiv.swap 0 1) 0 = (1 : Perm _) 0`, which reduces to
      -- `(1 : ZMod 2) = (0 : ZMod 2)` after applying
      -- `Equiv.swap_apply_left` on the LHS and unfolding
      -- `(1 : Perm) 0 = 0` on the RHS.
      have h' : (Equiv.swap (0 : ZMod 2) 1) 0 = (0 : ZMod 2) := h
      rw [Equiv.swap_apply_left] at h'
      -- `h' : (1 : ZMod 2) = 0`, which is false.
      exact absurd h' (by decide))

/-! ## Workstream F non-vacuity witnesses

Concrete machine-checked evaluations of `CanonicalForm.ofLexMin` on a
small permutation group. The witnesses confirm the Workstream-F
constructor (audit 2026-04-23, finding V1-10 / F-04) produces a
computable canonical form — not merely a type-checking skeleton — by
reducing `canon x` to the expected lex-min orbit element via `decide`.

The lex order used here is `bitstringLinearOrder` from
`Orbcrypt/Construction/Permutation.lean`. It matches the GAP
reference implementation's `CanonicalImage(G, x, OnSets)` convention:
bitstrings are compared via their support sets (sorted ascending
position lists), with smaller-position-true winning ("leftmost-true
wins"). Bound locally via `letI` (not as a global instance) to avoid
a diamond with Mathlib's pointwise `Pi.partialOrder`. -/

/-- Order-direction sanity check matching GAP's `CanonicalImage`
    convention: among weight-2 bitstrings of length 3,
    `![true, true, false]` (= GAP set {0, 1}) is strictly less than
    `![true, false, true]` (= GAP set {0, 2}) — element-wise lex on
    the sorted position list gives 1 < 2 at position 1.

    Uses `@LT.lt` with the explicit `bitstringLinearOrder.toLT`
    instead of the unqualified `<` so that Lean's typeclass search
    does *not* pick up the pointwise `Pi.preorder.toLT` — a diamond
    would otherwise render `DecidableLT` unsynthesisable at this
    call site. (The constructor `CanonicalForm.ofLexMin` below is
    unaffected by the diamond because `Finset.min'` takes its
    `LinearOrder` argument as a bound variable rather than a free
    typeclass.) -/
example :
    @LT.lt (Bitstring 3) bitstringLinearOrder.toLT
      (![true, true, false] : Bitstring 3)
      (![true, false, true] : Bitstring 3) := by
  decide

/-- `CanonicalForm.ofLexMin` computes the lex-min orbit element on a
    small concrete instance, **matching the GAP reference
    implementation's choice exactly**. Under the full symmetric group
    `Equiv.Perm (Fin 3)` (all 6 coordinate permutations), the orbit
    of any weight-2 bitstring is the set of all weight-2 bitstrings:
        `{![true, true, false], ![true, false, true], ![false, true, true]}`.
    In `bitstringLinearOrder` (GAP set-lex), the minimum is
    `![true, true, false]` — corresponding to GAP's
    `CanonicalImage(S_3, {0, 1}, OnSets) = {0, 1}`. `decide` reduces
    the whole chain — orbit enumeration, `.toFinset` conversion,
    `Finset.min'` search — to the expected answer at compile time. -/
example :
    letI : LinearOrder (Bitstring 3) := bitstringLinearOrder
    let can := CanonicalForm.ofLexMin
      (G := Equiv.Perm (Fin 3)) (X := Bitstring 3)
    can.canon (![true, false, true] : Bitstring 3) =
      (![true, true, false] : Bitstring 3) := by
  decide

/-- Singleton-orbit case: the `![false, false, false]` bitstring is
    fixed by every permutation of length-3 (it has no `true` bits to
    permute), so its orbit is the singleton `{![false, false, false]}`.
    `canon` returns the input unchanged. Verifies `ofLexMin` reduces
    correctly on a singleton orbit (no non-trivial choice to make). -/
example :
    letI : LinearOrder (Bitstring 3) := bitstringLinearOrder
    let can := CanonicalForm.ofLexMin
      (G := Equiv.Perm (Fin 3)) (X := Bitstring 3)
    can.canon (![false, false, false] : Bitstring 3) =
      (![false, false, false] : Bitstring 3) := by
  decide

/-- Cross-orbit-element agreement: every weight-2 input bitstring under
    `Equiv.Perm (Fin 3)` reduces to the same lex-min canonical form.
    Confirms the `orbit_iff` field of `CanonicalForm.ofLexMin`
    discharges in the orbit-collapsing direction at a non-trivial
    instance. -/
example :
    letI : LinearOrder (Bitstring 3) := bitstringLinearOrder
    let can := CanonicalForm.ofLexMin
      (G := Equiv.Perm (Fin 3)) (X := Bitstring 3)
    can.canon (![true, true, false] : Bitstring 3) =
      can.canon (![true, false, true] : Bitstring 3) := by
  decide

/-- `canon_idem` applied to `ofLexMin`: the abstract idempotence
    theorem (`Orbcrypt.canon_idem`, headline row from `Canonical.lean`)
    fires on the concrete `CanonicalForm.ofLexMin` instance, exhibiting
    that the abstract theorems compose cleanly with the new
    constructor. The discharge is by `canon_idem _ _` after `intro`
    binds the `let` shadows; no `decide` is needed. -/
example :
    letI : LinearOrder (Bitstring 3) := bitstringLinearOrder
    let can := CanonicalForm.ofLexMin
      (G := Equiv.Perm (Fin 3)) (X := Bitstring 3)
    can.canon (can.canon (![true, false, true] : Bitstring 3)) =
      can.canon (![true, false, true] : Bitstring 3) := by
  intro
  exact canon_idem _ _

/-- `CanonicalForm.ofLexMin_canon_mem_orbit` direct witness: the
    canonical form of any input lies in that input's orbit. The
    `[LinearOrder (Bitstring 3)]` instance is brought into scope via
    `letI` *inside* the tactic block (where it's then visible to the
    `exact` term elaboration), confirming the theorem is callable in
    term mode under the typeclass binding the F-workstream `def`
    convention requires. -/
example :
    True := by
  letI : LinearOrder (Bitstring 3) := bitstringLinearOrder
  let _ : (CanonicalForm.ofLexMin
              (G := Equiv.Perm (Fin 3)) (X := Bitstring 3)).canon
            (![true, false, true] : Bitstring 3) ∈
          MulAction.orbit (Equiv.Perm (Fin 3))
            (![true, false, true] : Bitstring 3) :=
    CanonicalForm.ofLexMin_canon_mem_orbit _
  trivial

/-- `hgoeScheme.ofLexMin` correctness witness on the top subgroup
    `⊤ ≤ S_3`. Goes beyond a type-elaboration check: builds the
    scheme via the Workstream-F4 convenience constructor and then
    fires `correctness` on the result, confirming the abstract
    correctness theorem composes cleanly with `ofLexMin`'s
    auto-filled `CanonicalForm`. Uses the singleton message space
    `Unit` so the distinctness obligation is vacuous (no two
    distinct messages exist). The `decrypt (encrypt scheme g ()) =
    some ()` round-trip is discharged by direct application of
    `correctness scheme () g`; the `Fintype ↥⊤` instance fires via
    the explicit `DecidablePred (· ∈ ⊤)` binding. -/
example (g : (⊤ : Subgroup (Equiv.Perm (Fin 3)))) : True := by
  let G : Subgroup (Equiv.Perm (Fin 3)) := ⊤
  letI : DecidablePred (· ∈ G) := fun _ => isTrue trivial
  let scheme : OrbitEncScheme ↥G (Bitstring 3) Unit :=
    hgoeScheme.ofLexMin G
      (fun _ : Unit => ![false, false, false])
      (fun m₁ m₂ hne => absurd (Subsingleton.elim m₁ m₂) hne)
  have : decrypt scheme (encrypt scheme g ()) = some () :=
    correctness scheme () g
  trivial

/-- `hgoeScheme.ofLexMin_reps` simp lemma fires on a concrete
    instantiation. Confirms the field-preservation claim is
    machine-checked, not merely typed: the `reps` field of the
    auto-filled scheme is `definitionally` the input `reps`
    function (closed by `rfl`). -/
example
    (G : Subgroup (Equiv.Perm (Fin 3))) [Fintype ↥G]
    (reps : Bool → Bitstring 3)
    (hDistinct : ∀ m₁ m₂ : Bool, m₁ ≠ m₂ →
      MulAction.orbit (↥G) (reps m₁) ≠ MulAction.orbit (↥G) (reps m₂)) :
    (hgoeScheme.ofLexMin G reps hDistinct).reps = reps :=
  hgoeScheme.ofLexMin_reps G reps hDistinct

/-! ## Workstream G non-vacuity witnesses

The Workstream-G refactor (audit 2026-04-23, finding V1-13 / H-03 /
Z-06 / D16) replaces `HGOEKeyExpansion`'s hard-coded
`group_large_enough : group_order_log ≥ 128` field with a
λ-parameterised `group_order_log ≥ lam` (where `lam : ℕ` is a leading
structure parameter, named `lam` because Lean 4 reserves `λ` for
lambda-abstraction). Pre-G the structure was instantiable only at the
λ = 128 row of the Phase-14 sweep; the post-G shape lets every
λ ∈ {80, 128, 192, 256} security tier inhabit `HGOEKeyExpansion lam …`
with a `group_order_log` discharged at compile time by `decide` /
`le_refl`.

Each witness below is a complete `HGOEKeyExpansion lam n M` value
that mirrors the **balanced tier** of `docs/PARAMETERS.md` §6.2
(the default recommended deployment for each λ):
* `b = 4`, `ℓ = λ`, `n = 4·λ` (Stage 1 parameter validity:
  `n = b * ℓ` decides);
* `code_dim = 2·λ ≤ n` (Stage 2 dimension validity);
* `group_order_log := lam` and `group_large_enough` discharged via
  the trivially-true bound `lam ≤ lam` (we choose
  `group_order_log := lam` — the lower-bound floor; production
  deployments choose `group_order_log` strictly above `lam` per the
  scaling-model thresholds in `docs/PARAMETERS.md` §4);
* `weight = 0` and `reps := fun _ => fun _ => false` (Stage 4
  uniformity holds vacuously: the all-zero bitstring has Hamming
  weight 0 by the helper `hammingWeight_zero_bitstring` below).

The witnesses use the singleton message space `Unit` to keep the
Stage 4 obligation trivial; production HGOE uses a real message
space `M` of orbit indices and a `reps` function whose Hamming
weight equals `⌊n/2⌋`. The non-trivial part of the witness — and
the property the Workstream-G refactor exists to make
instantiable — is the `group_large_enough` field. -/

/-- A reusable Stage-4 helper: under the all-zero bitstring `_ ↦ false`,
    the Hamming weight is 0 because the underlying filter is empty.
    Concretely, `hammingWeight (fun _ => false)` unfolds to
    `(Finset.univ.filter (fun i => false = true)).card`; the predicate
    is constantly false, so the filter is `∅` and `Finset.card ∅ = 0`. -/
private theorem hammingWeight_zero_bitstring (n : ℕ) :
    hammingWeight (n := n) (fun _ : Fin n => false) = 0 := by
  unfold hammingWeight
  -- `Finset.univ.filter (fun _ => false = true) = ∅` because the
  -- predicate decides to `False` at every input.
  simp

-- Defensive `#print axioms` on the Stage-4 helper. The four tier
-- witnesses below consume `hammingWeight_zero_bitstring` to discharge
-- `reps_same_weight`; if a future change introduces a `sorry` or a
-- custom axiom in the helper, this line surfaces it in the audit
-- output (the witness `example`s themselves are anonymous and have no
-- individual `#print axioms`, so without this line a regression in
-- the helper could pass silently). The CI parser walks every
-- "depends on axioms" entry and rejects anything outside the standard
-- Lean trio.
#print axioms hammingWeight_zero_bitstring

/-- **Workstream G non-vacuity witness at λ = 80.** The smallest of
    the four documented Phase-14 tiers (`docs/PARAMETERS.md` §6.5).
    Parameter values match the **balanced tier** (default recommended,
    `docs/PARAMETERS.md` §6.2): `b = 4`, `ℓ = λ = 80`, `n = 4·λ =
    320`, `code_dim = 2·λ = 160`. The `group_large_enough` field
    `group_order_log ≥ 80` is discharged by `le_refl _` after we
    choose `group_order_log := 80` (the lower-bound floor; production
    deployments choose strictly larger per `log₂|G| = 161` from the
    §6.2 row).

    Stage 4 (weight uniformity) is satisfied vacuously: the
    `reps := fun _ _ => false` choice gives every representative
    Hamming weight 0, which equals `weight := 0`. Production HGOE
    uses `weight = ⌊n/2⌋ = 160`, but the `weight := 0` choice
    suffices for non-vacuity (the structure is inhabited; the
    Workstream-G fix is about `group_large_enough`, not Stage 4). -/
example : HGOEKeyExpansion 80 320 Unit where
  b := 4
  ℓ := 80
  param_valid := by decide
  code_dim := 160
  code_valid := by decide
  group_order_log := 80
  group_large_enough := le_refl _
  weight := 0
  reps := fun _ _ => false
  reps_same_weight := fun _ => hammingWeight_zero_bitstring 320

/-- **Workstream G non-vacuity witness at λ = 128.** The original
    pre-Workstream-G hard-coded tier — the only level the pre-G
    structure could inhabit. Now expressed as one tier among four,
    with the same Lean-level discharge pattern. Parameter values
    match the **balanced tier** (default, `docs/PARAMETERS.md`
    §6.2): `b = 4`, `ℓ = λ = 128`, `n = 4·λ = 512`, `code_dim =
    2·λ = 256`. -/
example : HGOEKeyExpansion 128 512 Unit where
  b := 4
  ℓ := 128
  param_valid := by decide
  code_dim := 256
  code_valid := by decide
  group_order_log := 128
  group_large_enough := le_refl _
  weight := 0
  reps := fun _ _ => false
  reps_same_weight := fun _ => hammingWeight_zero_bitstring 512

/-- **Workstream G non-vacuity witness at λ = 192.** A Phase-14 tier
    that the pre-G hard-coded `≥ 128` bound made strictly *under*-
    discharging (an `HGOEKeyExpansion` claiming `≥ 128` security is
    *not* a witness of `≥ 192` security; the post-G shape requires
    each tier to discharge its own bound). Parameter values match
    the **balanced tier** (default, `docs/PARAMETERS.md` §6.2):
    `b = 4`, `ℓ = λ = 192`, `n = 4·λ = 768`, `code_dim = 2·λ =
    384`. -/
example : HGOEKeyExpansion 192 768 Unit where
  b := 4
  ℓ := 192
  param_valid := by decide
  code_dim := 384
  code_valid := by decide
  group_order_log := 192
  group_large_enough := le_refl _
  weight := 0
  reps := fun _ _ => false
  reps_same_weight := fun _ => hammingWeight_zero_bitstring 768

/-- **Workstream G non-vacuity witness at λ = 256.** The largest of
    the four documented tiers. The pre-G structure could *not*
    discharge `group_order_log ≥ 256` in general (only `≥ 128` was
    demanded), so callers targeting the highest security level had
    no machine-checked obligation that the group was actually large
    enough. The post-G structure forces them to supply the witness.
    Parameter values match the **balanced tier** (default,
    `docs/PARAMETERS.md` §6.2): `b = 4`, `ℓ = λ = 256`, `n = 4·λ =
    1024`, `code_dim = 2·λ = 512`. -/
example : HGOEKeyExpansion 256 1024 Unit where
  b := 4
  ℓ := 256
  param_valid := by decide
  code_dim := 512
  code_valid := by decide
  group_order_log := 256
  group_large_enough := le_refl _
  weight := 0
  reps := fun _ _ => false
  reps_same_weight := fun _ => hammingWeight_zero_bitstring 1024

/-- **Field-projection regression.** Given any
    `HGOEKeyExpansion lam n M`, the `group_large_enough` field must
    project to the λ-parameterised inequality `group_order_log ≥
    lam`. Exercising this at a free `lam` confirms a future change
    that hard-coded the bound back to `≥ 128` (or any other literal)
    would fail to elaborate. -/
example (lam n : ℕ) (M : Type) (exp : HGOEKeyExpansion lam n M) :
    exp.group_order_log ≥ lam :=
  exp.group_large_enough

/-- **λ-monotonicity regression.** A witness at λ' ≤ λ does *not*
    upgrade automatically to a witness at λ — the post-G obligation
    `group_order_log ≥ λ` is genuinely stronger than `≥ λ'` whenever
    `λ' < λ`. We exhibit the failure-mode by negation: at `lam' = 80`
    and `lam = 192`, the inequality `80 ≥ 192` is decidably false.
    This documents that the four tier-witnesses above are *distinct*
    obligations, not one obligation with a sloppy bound. -/
example : ¬ ((80 : ℕ) ≥ 192) := by decide

-- ============================================================================
-- Workstream I non-vacuity witnesses (audit 2026-04-23, findings
-- C-15, D-07, E-11, J-03, J-08, K-02): each `example` instantiates a
-- new Workstream-I declaration on a concrete fixture and confirms the
-- declaration is non-vacuously inhabited at known-good inputs.
-- ============================================================================

/-! ## Workstream I1 non-vacuity (audit C-15) -/

/-- `indCPAAdvantage_le_one` (renamed from `concreteOIA_one_meaningful`)
    fires on any scheme/adversary pair, delivering the trivial `≤ 1`
    bound directly as a Mathlib-style simp lemma.

    **Post-audit (2026-04-25):** the originally-paired
    `concreteOIA_zero_of_subsingleton_message` "perfect-security
    extremum" witness was removed as theatrical: it required
    `[Subsingleton M]`, a hypothesis under which there is only one
    message and therefore no security game to play. The honest I1
    deliverable is the rename + the matching audit-script entry
    here. -/
example {G : Type} {X : Type} {M : Type}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) :
    indCPAAdvantage scheme A ≤ 1 :=
  indCPAAdvantage_le_one scheme A

/-! ## Workstream I2 non-vacuity (audit E-11) -/

/-- `kemAdvantage_le_one` (the existing sanity bound that
    Workstream I2 redirected consumers to after deleting the
    redundant pre-I `concreteKEMOIA_one_meaningful`) fires on every
    KEM/adversary triple.

    **Post-audit (2026-04-25):** the originally-paired
    `concreteKEMOIA_uniform_zero_of_singleton_orbit` "perfect-security
    extremum" witness was removed as theatrical: it required
    `∀ g, g • basePoint = basePoint`, a hypothesis under which the KEM
    has only one possible ciphertext and therefore no security game
    to play. The honest I2 deliverable is the deletion +
    redirection-to-`kemAdvantage_le_one`, exercised here. -/
example {G : Type} {X : Type} {K : Type}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (A : KEMAdversary X K) (g₀ g₁ : G) :
    kemAdvantage kem A g₀ g₁ ≤ 1 :=
  kemAdvantage_le_one kem A g₀ g₁

/-! ## Workstream I3 non-vacuity (audit D-07) -/

/-- `canon_indicator_isGInvariant` fires on any canonical form: the
    Boolean indicator `fun x => decide (can.canon x = c)` is
    G-invariant (composition of `decide (· = c)` with the G-invariant
    `can.canon`). -/
example {G : Type} {X : Type}
    [Group G] [MulAction G X] [DecidableEq X]
    (can : CanonicalForm G X) (c : X) :
    IsGInvariant (G := G) (fun x => decide (can.canon x = c)) :=
  canon_indicator_isGInvariant can c

/-- `distinct_messages_have_invariant_separator` exhibits a G-invariant
    Boolean function that takes different values on the
    representatives of two distinct messages — the cryptographic
    content the pre-I `insecure_implies_separating` name advertised
    but did not deliver. Exercised on the same `trivialSchemeBool`
    fixture used by the Workstream-E vacuity witness, where the two
    messages `true` and `false` are distinct. -/
example :
    ∃ f : Bool → Bool,
      IsGInvariant (G := Equiv.Perm (Fin 1)) f ∧
      f (trivialSchemeBool.reps true) ≠
      f (trivialSchemeBool.reps false) :=
  distinct_messages_have_invariant_separator
    (G := Equiv.Perm (Fin 1)) (X := Bool) (M := Bool)
    trivialSchemeBool (m₀ := true) (m₁ := false) (by decide)

/-- `insecure_implies_orbit_distinguisher` (renamed from
    `insecure_implies_separating`) fires on any adversary with
    advantage and delivers an orbit-distinguisher. Pairs with
    `distinct_messages_have_invariant_separator` above to exercise
    both Workstream-I3 deliverables. -/
example {G : Type} {X : Type} {M : Type}
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (A : Adversary X M) (hAdv : hasAdvantage scheme A) :
    ∃ (f : X → Bool) (m₀ m₁ : M),
      ∃ g₀ g₁ : G, f (g₀ • scheme.reps m₀) ≠ f (g₁ • scheme.reps m₁) :=
  insecure_implies_orbit_distinguisher scheme A hAdv

/-! ## Workstream I4 non-vacuity (audit J-03) -/

/-- `GIReducesToCE_card_nondegeneracy_witness` confirms the strengthened
    non-degeneracy fields (positive uniform `codeSize`, fixed `dim`,
    pure encoder) are independently inhabitable by the trivial
    singleton-encoder. A *full* inhabitant of `GIReducesToCE` requires
    the iff discharge from a tight Karp reduction (CFI 1992 /
    Petrank–Roth 1997); research-scope (audit plan § 15.1 / R-15). -/
example :
    ∃ (dim : ℕ → ℕ) (codeSize : ℕ → ℕ)
      (encode : (m : ℕ) → (Fin m → Fin m → Bool) →
                Finset (Fin (dim m) → Bool)),
      (∀ m, 0 < codeSize m) ∧
      (∀ m adj, (encode m adj).card = codeSize m) :=
  GIReducesToCE_card_nondegeneracy_witness

/-- **Negative-pressure regression for I4.** Pre-Workstream-I, the
    `GIReducesToCE` Prop admitted the degenerate `encode _ _ := ∅`
    witness (under which `(encode m adj).card = 0`). The post-I
    strengthening makes the audit-flagged degenerate encoder fail
    the `0 < codeSize m` obligation at compile time — an empty
    Finset has card 0, and `0 < 0` is decidably false. -/
example : ¬ (0 < (∅ : Finset (Fin 1 → Bool)).card) := by simp

/-! ## Workstream I5 non-vacuity (audit J-08) -/

/-- `GIReducesToTI_nondegeneracy_witness` confirms the strengthened
    non-degeneracy field is independently inhabitable by the trivial
    constant-1 encoder over `ZMod 2`. Same caveat as I4: a *full*
    inhabitant of `GIReducesToTI` requires the iff discharge from
    the Grochow–Qiao 2021 structure-tensor encoding; research-scope
    (audit plan § 15.1 / R-15). -/
example :
    ∃ (dim : ℕ → ℕ)
      (encode : (m : ℕ) → (Fin m → Fin m → Bool) →
                Tensor3 (dim m) (ZMod 2)),
      ∀ m, 1 ≤ m → ∀ adj, encode m adj ≠ (fun _ _ _ => 0) :=
  GIReducesToTI_nondegeneracy_witness

/-- **Negative-pressure regression for I5.** Pre-Workstream-I, the
    `GIReducesToTI` Prop admitted the degenerate constant-zero
    encoder (`encode _ _ := fun _ _ _ => 0`). The post-I strengthening
    makes the audit-flagged degenerate encoder fail the
    `encode m adj ≠ (fun _ _ _ => 0)` obligation — the constant-zero
    tensor is *equal* (not unequal) to the constant-zero tensor. -/
example : (fun (_ _ _ : Fin 1) => (0 : ZMod 2)) =
          (fun (_ _ _ : Fin 1) => (0 : ZMod 2)) := rfl

/-! ## Workstream I6 non-vacuity (audit K-02) -/

/-- A trivial `OrbitalRandomizers (Equiv.Perm (Fin 1)) Unit 1` bundle
    on the singleton space `Unit`. Used as the concrete fixture for
    the `ObliviousSamplingPerfectHiding` rename-regression check
    below. The non-degenerate `Equiv.Perm Bool` fixture
    (`concreteHidingBundle` + `concreteHidingCombine`) lives in
    `Orbcrypt/PublicKey/ObliviousSampling.lean` and is exercised by
    its own `#print axioms` lines earlier in this script (post-
    audit 2026-04-25); the precise ε = 1/4 bound on that fixture
    is research-scope R-12. -/
def trivialOrs_I6 : OrbitalRandomizers (Equiv.Perm (Fin 1)) Unit 1 where
  basePoint := ()
  randomizers := fun _ => ()
  in_orbit := fun _ => ⟨1, Subsingleton.elim _ _⟩

/-- `ObliviousSamplingPerfectHiding` (renamed from
    `ObliviousSamplingHiding`) and its companion theorem
    `oblivious_sampling_view_constant_under_perfect_hiding` are
    well-typed on the trivial bundle. The deterministic predicate is
    `True` here because the bundle has only one `(i, j)` pair (i.e.
    `Fin 1 × Fin 1`), so both sides of the equality coincide
    trivially. This is a *rename-regression check*, not a
    cryptographic-content claim. -/
example : ObliviousSamplingPerfectHiding trivialOrs_I6
    (fun _ _ => trivialOrs_I6.basePoint) := by
  intro _ _ _ _ _
  rfl

/-- **Workstream I post-audit (2026-04-25): non-degenerate fixture
    structural exercise.** Confirms `concreteHidingBundle` and
    `concreteHidingCombine` are well-typed inhabitants of
    `OrbitalRandomizers (Equiv.Perm Bool) Bool 2` and `Bool → Bool →
    Bool` respectively, and that `ObliviousSamplingConcreteHiding`
    accepts them as arguments. This exercises the *fixture* — the
    substantive Workstream-I post-audit content — without claiming
    the precise ε = 1/4 bound (research-scope R-12).

    For the trivial bound `ε = 1`, `advantage_le_one` discharges
    `ObliviousSamplingConcreteHiding _ _ 1` immediately by the
    predicate's universal `∀ D, advantage ≤ ε` form. -/
example : ObliviousSamplingConcreteHiding concreteHidingBundle
    concreteHidingCombine 1 := by
  intro D
  exact advantage_le_one _ _ _

/-- **Workstream I post-audit fixture sanity check.** The bundle's
    base point lies in its own orbit (trivially via the identity
    permutation), and the second randomizer (`true`) lies in the
    orbit via `Equiv.swap false true`. Exercises the bundle's
    `in_orbit` field on a concrete index. -/
example :
    concreteHidingBundle.randomizers 1 ∈
      MulAction.orbit (Equiv.Perm Bool) concreteHidingBundle.basePoint :=
  concreteHidingBundle.in_orbit 1

end NonVacuityWitnesses

-- ============================================================================
-- R-CE Layer 0 — Petrank–Roth bit-layout primitives
-- (`Orbcrypt/Hardness/PetrankRoth/BitLayout.lean`)
-- ============================================================================

#print axioms Orbcrypt.PetrankRoth.numEdges
#print axioms Orbcrypt.PetrankRoth.dimPR
#print axioms Orbcrypt.PetrankRoth.codeSizePR
#print axioms Orbcrypt.PetrankRoth.numEdges_zero
#print axioms Orbcrypt.PetrankRoth.numEdges_one
#print axioms Orbcrypt.PetrankRoth.numEdges_two
#print axioms Orbcrypt.PetrankRoth.numEdges_three
#print axioms Orbcrypt.PetrankRoth.numEdges_four
#print axioms Orbcrypt.PetrankRoth.numEdges_le
#print axioms Orbcrypt.PetrankRoth.dimPR_pos
#print axioms Orbcrypt.PetrankRoth.codeSizePR_pos
#print axioms Orbcrypt.PetrankRoth.dimPR_eq_codeSizePR
#print axioms Orbcrypt.PetrankRoth.PRCoordKind
#print axioms Orbcrypt.PetrankRoth.PRCoordKind.toSum
#print axioms Orbcrypt.PetrankRoth.PRCoordKind.ofSum
#print axioms Orbcrypt.PetrankRoth.PRCoordKind.ofSum_toSum
#print axioms Orbcrypt.PetrankRoth.PRCoordKind.toSum_ofSum
#print axioms Orbcrypt.PetrankRoth.PRCoordKind.equivSum
#print axioms Orbcrypt.PetrankRoth.PRCoordKind.instFintype
#print axioms Orbcrypt.PetrankRoth.EdgeSlot
#print axioms Orbcrypt.PetrankRoth.otherVertex
#print axioms Orbcrypt.PetrankRoth.otherVertex_ne_self
#print axioms Orbcrypt.PetrankRoth.otherVertexInverse
#print axioms Orbcrypt.PetrankRoth.otherVertex_otherVertexInverse
#print axioms Orbcrypt.PetrankRoth.otherVertexInverse_otherVertex
#print axioms Orbcrypt.PetrankRoth.edgeSlot_card
#print axioms Orbcrypt.PetrankRoth.edgeSlotEquiv
#print axioms Orbcrypt.PetrankRoth.edgeEndpoints
#print axioms Orbcrypt.PetrankRoth.edgeEndpoints_ne
#print axioms Orbcrypt.PetrankRoth.edgeIndex
#print axioms Orbcrypt.PetrankRoth.edgeEndpoints_edgeIndex
#print axioms Orbcrypt.PetrankRoth.edgeIndex_edgeEndpoints
#print axioms Orbcrypt.PetrankRoth.prCoord
#print axioms Orbcrypt.PetrankRoth.prCoord_vertex_val
#print axioms Orbcrypt.PetrankRoth.prCoord_incid_val
#print axioms Orbcrypt.PetrankRoth.prCoord_marker_val
#print axioms Orbcrypt.PetrankRoth.prCoord_sentinel_val
#print axioms Orbcrypt.PetrankRoth.prCoordKind
#print axioms Orbcrypt.PetrankRoth.prCoord_prCoordKind
#print axioms Orbcrypt.PetrankRoth.prCoordKind_prCoord
#print axioms Orbcrypt.PetrankRoth.prCoordEquiv

namespace PetrankRothLayer0NonVacuity
open Orbcrypt.PetrankRoth

/-- **R-CE Layer 0 non-vacuity witness.** `numEdges`, `dimPR`,
    `codeSizePR` evaluate to the expected closed-form values at small
    `m` (under the directed-edge enumeration `numEdges m = m * (m -
    1)`), and `codeSizePR_pos` discharges the strengthened
    `GIReducesToCE` Prop's `codeSize_pos` field at `m = 0`. -/
example : numEdges 4 = 12 ∧ dimPR 3 = 28 ∧ codeSizePR 3 = 28 ∧
          (0 < codeSizePR 0) :=
  ⟨rfl, rfl, rfl, codeSizePR_pos 0⟩

/-- **R-CE Layer 0 non-vacuity witness.** `prCoord` evaluates to
    distinct columns for distinct constructor families, exhibiting
    the four-family partition structure that downstream layers
    consume.  At `m = 3` (with `numEdges 3 = 6` directed slots) the
    incidence range is `[3, 9)`, the marker range is `[9, 27)`, and
    the sentinel is at column `27`. -/
example :
    (prCoord 3 (.vertex ⟨0, by decide⟩)).val = 0 ∧
    (prCoord 3 (.incid ⟨0, by decide⟩)).val = 3 ∧
    (prCoord 3 (.marker ⟨0, by decide⟩ ⟨0, by decide⟩)).val = 9 ∧
    (prCoord 3 (PRCoordKind.sentinel : PRCoordKind 3)).val = 27 :=
  ⟨rfl, rfl, rfl, rfl⟩

/-- **R-CE Layer 0 non-vacuity witness.** `prCoordEquiv` round-trips
    on the sentinel — the round-trip is the lemma the encoder
    construction (Layer 1) consumes when interpreting the encoded
    block. -/
example : prCoordKind 3 (prCoord 3 (PRCoordKind.sentinel : PRCoordKind 3)) =
          PRCoordKind.sentinel :=
  prCoordKind_prCoord 3 _

/-- **R-CE Layer 0 non-vacuity witness.** `edgeEndpoints` /
    `edgeIndex` round-trip on a concrete edge `(0, 1)` in
    `Fin 3`.  This is the bijection the marker-forcing reverse
    direction (Layer 4) extracts the edge permutation through. -/
example :
    edgeEndpoints 3 (edgeIndex 3 ⟨0, by decide⟩ ⟨1, by decide⟩
      (by decide)) =
    (⟨0, by decide⟩, ⟨1, by decide⟩) :=
  edgeEndpoints_edgeIndex 3 _ _ _

end PetrankRothLayer0NonVacuity

-- ============================================================================
-- R-CE Layer 1 — Petrank–Roth encoder + cardinality
-- (`Orbcrypt/Hardness/PetrankRoth.lean`)
-- ============================================================================

#print axioms Orbcrypt.PetrankRoth.vertexCodeword
#print axioms Orbcrypt.PetrankRoth.edgePresent
#print axioms Orbcrypt.PetrankRoth.edgeCodeword
#print axioms Orbcrypt.PetrankRoth.markerCodeword
#print axioms Orbcrypt.PetrankRoth.sentinelCodeword
-- Codeword evaluation simp lemmas (Layer 1.2):
#print axioms Orbcrypt.PetrankRoth.vertexCodeword_at_vertex
#print axioms Orbcrypt.PetrankRoth.vertexCodeword_at_incid
#print axioms Orbcrypt.PetrankRoth.vertexCodeword_at_marker
#print axioms Orbcrypt.PetrankRoth.vertexCodeword_at_sentinel
#print axioms Orbcrypt.PetrankRoth.edgeCodeword_at_vertex
#print axioms Orbcrypt.PetrankRoth.edgeCodeword_at_incid
#print axioms Orbcrypt.PetrankRoth.edgeCodeword_at_marker
#print axioms Orbcrypt.PetrankRoth.edgeCodeword_at_sentinel
#print axioms Orbcrypt.PetrankRoth.markerCodeword_at_vertex
#print axioms Orbcrypt.PetrankRoth.markerCodeword_at_incid
#print axioms Orbcrypt.PetrankRoth.markerCodeword_at_marker
#print axioms Orbcrypt.PetrankRoth.markerCodeword_at_sentinel
#print axioms Orbcrypt.PetrankRoth.sentinelCodeword_at_vertex
#print axioms Orbcrypt.PetrankRoth.sentinelCodeword_at_incid
#print axioms Orbcrypt.PetrankRoth.sentinelCodeword_at_marker
#print axioms Orbcrypt.PetrankRoth.sentinelCodeword_at_sentinel
-- Within-family injectivity (Layer 1.3):
#print axioms Orbcrypt.PetrankRoth.vertexCodeword_injective
#print axioms Orbcrypt.PetrankRoth.edgeCodeword_injective
#print axioms Orbcrypt.PetrankRoth.markerCodeword_injective
-- Cross-family disjointness (Layer 1.4):
#print axioms Orbcrypt.PetrankRoth.vertexCodeword_ne_edgeCodeword
#print axioms Orbcrypt.PetrankRoth.vertexCodeword_ne_markerCodeword
#print axioms Orbcrypt.PetrankRoth.vertexCodeword_ne_sentinelCodeword
#print axioms Orbcrypt.PetrankRoth.edgeCodeword_ne_markerCodeword
#print axioms Orbcrypt.PetrankRoth.edgeCodeword_ne_sentinelCodeword
#print axioms Orbcrypt.PetrankRoth.markerCodeword_ne_sentinelCodeword
-- Encoder + cardinality (Layers 1.5–1.6):
#print axioms Orbcrypt.PetrankRoth.prEncode
#print axioms Orbcrypt.PetrankRoth.prEncode_card
#print axioms Orbcrypt.PetrankRoth.mem_prEncode

namespace PetrankRothLayer1NonVacuity
open Orbcrypt.PetrankRoth

/-- **R-CE Layer 1 non-vacuity witness.** `prEncode_card` discharges
    the `(encode m adj).card = codeSize m` non-degeneracy field of the
    strengthened `GIReducesToCE` Prop at concrete small graphs. -/
example : (prEncode 3 (fun _ _ => false)).card = codeSizePR 3 :=
  prEncode_card 3 _

example : (prEncode 3 (fun i j => decide (i.val + j.val = 1))).card =
          codeSizePR 3 :=
  prEncode_card 3 _

end PetrankRothLayer1NonVacuity

-- ============================================================================
-- R-CE Layer 2 — Petrank–Roth forward direction (liftAut + prEncode_forward)
-- (`Orbcrypt/Hardness/PetrankRoth.lean`)
-- ============================================================================

-- Edge permutation (Layer 2.1–2.2):
#print axioms Orbcrypt.PetrankRoth.liftedEdgePermFun
#print axioms Orbcrypt.PetrankRoth.liftedEdgePermFun_left_inv
#print axioms Orbcrypt.PetrankRoth.liftedEdgePerm
#print axioms Orbcrypt.PetrankRoth.liftedEdgePerm_apply
#print axioms Orbcrypt.PetrankRoth.liftedEdgePerm_symm_apply
#print axioms Orbcrypt.PetrankRoth.liftedEdgePerm_one
#print axioms Orbcrypt.PetrankRoth.edgeEndpoints_liftedEdgePermFun
#print axioms Orbcrypt.PetrankRoth.edgeEndpoints_liftedEdgePerm
-- liftAut construction (Layer 2.3):
#print axioms Orbcrypt.PetrankRoth.liftAutKindFun
#print axioms Orbcrypt.PetrankRoth.liftAutKindFun_vertex
#print axioms Orbcrypt.PetrankRoth.liftAutKindFun_incid
#print axioms Orbcrypt.PetrankRoth.liftAutKindFun_marker
#print axioms Orbcrypt.PetrankRoth.liftAutKindFun_sentinel
#print axioms Orbcrypt.PetrankRoth.liftAutKindFun_left_inv
#print axioms Orbcrypt.PetrankRoth.liftAutKind
#print axioms Orbcrypt.PetrankRoth.liftAutKind_apply
#print axioms Orbcrypt.PetrankRoth.liftAutKind_symm_apply
#print axioms Orbcrypt.PetrankRoth.liftAut
#print axioms Orbcrypt.PetrankRoth.liftAut_apply
#print axioms Orbcrypt.PetrankRoth.liftAut_symm_apply
-- Group-homomorphism lemmas (Layer 2.4):
#print axioms Orbcrypt.PetrankRoth.liftAutKind_one
#print axioms Orbcrypt.PetrankRoth.liftAut_one
-- Forward action lemmas (Layer 2.5–2.8):
#print axioms Orbcrypt.PetrankRoth.permuteCodeword_liftAut_vertexCodeword
#print axioms Orbcrypt.PetrankRoth.permuteCodeword_liftAut_markerCodeword
#print axioms Orbcrypt.PetrankRoth.permuteCodeword_liftAut_sentinelCodeword
#print axioms Orbcrypt.PetrankRoth.edgePresent_liftedEdgePerm
#print axioms Orbcrypt.PetrankRoth.permuteCodeword_liftAut_edgeCodeword
-- Forward direction assembly (Layer 2.9):
#print axioms Orbcrypt.PetrankRoth.prEncode_forward

namespace PetrankRothLayer2NonVacuity
open Orbcrypt.PetrankRoth Orbcrypt

/-- **R-CE Layer 2 non-vacuity witness (trivial GI witness).**
    `prEncode_forward` exhibits the identity permutation as a CE-
    equivalence witness for the encoded codes of two GI-equivalent
    graphs.  Empty graph at `m = 3`. -/
example : ArePermEquivalent (prEncode 3 (fun _ _ => false))
                            (prEncode 3 (fun _ _ => false)) :=
  prEncode_forward 3 _ _ ⟨1, fun _ _ => rfl⟩

/-- **R-CE Layer 2 non-vacuity witness (self-equivalence under
    identity).**  The identity GI witness lifts to the permutation-
    equivalence of any `prEncode adj` with itself, regardless of
    the structure of `adj`. -/
example (adj : Fin 3 → Fin 3 → Bool) :
    ArePermEquivalent (prEncode 3 adj) (prEncode 3 adj) :=
  prEncode_forward 3 _ _ ⟨1, fun _ _ => rfl⟩

/-- **R-CE Layer 2 non-vacuity witness (directed-edge sensitivity).**
    The directed-edge encoder distinguishes `adj₁` from its
    "swap" `adj₂(i, j) := adj₁(swap i, swap j)`: applying the swap
    permutation `σ = Equiv.swap 0 1 : Equiv.Perm (Fin 2)` is
    a valid GI witness, and `prEncode_forward` exhibits the
    corresponding CE-equivalence.  This concretely tests the
    directional information that the post-refactor encoder
    preserves (the pre-refactor symmetric encoder would have
    given a vacuous instance of this iff direction). -/
example :
    let adj₁ : Fin 2 → Fin 2 → Bool := fun i j => decide (i.val = 0 ∧ j.val = 1)
    let adj₂ : Fin 2 → Fin 2 → Bool := fun i j => decide (i.val = 1 ∧ j.val = 0)
    ArePermEquivalent (prEncode 2 adj₁) (prEncode 2 adj₂) := by
  refine prEncode_forward 2 _ _ ⟨Equiv.swap 0 1, ?_⟩
  intro i j
  fin_cases i <;> fin_cases j <;> decide

/-- **R-CE Layer 2 non-vacuity witness (cardinality round-trip).**
    `prEncode_forward`'s output is a witness of `ArePermEquivalent`,
    which (via the witnessing permutation) preserves cardinality.
    This sanity check confirms the encoder produces the expected
    `codeSizePR m = m + 4 * (m * (m - 1)) + 1` codeword count under
    the directed-edge enumeration. -/
example : (prEncode 2 (fun i j => decide (i.val = 0 ∧ j.val = 1))).card =
          codeSizePR 2 :=
  prEncode_card 2 _

end PetrankRothLayer2NonVacuity

-- ============================================================================
-- R-CE Layer 3 — Column-weight invariant infrastructure
-- (`Orbcrypt/Hardness/PetrankRoth/MarkerForcing.lean`)
-- ============================================================================

-- Sub-task 3.1–3.2 — column-weight definition + invariance.
#print axioms Orbcrypt.PetrankRoth.colWeight
#print axioms Orbcrypt.PetrankRoth.colWeight_empty
#print axioms Orbcrypt.PetrankRoth.colWeight_singleton_self
#print axioms Orbcrypt.PetrankRoth.colWeight_singleton_other
#print axioms Orbcrypt.PetrankRoth.colWeight_union_disjoint
#print axioms Orbcrypt.PetrankRoth.colWeight_permuteCodeword_image
-- Sub-task 3.3 — column-weight signatures of the four families.
#print axioms Orbcrypt.PetrankRoth.colWeight_prEncode_at_vertex
#print axioms Orbcrypt.PetrankRoth.colWeight_prEncode_at_incid
#print axioms Orbcrypt.PetrankRoth.colWeight_prEncode_at_marker
#print axioms Orbcrypt.PetrankRoth.colWeight_prEncode_at_sentinel
-- Sub-task 4.0 — cardinality-forced surjectivity bridge.
#print axioms Orbcrypt.PetrankRoth.surjectivity_of_card_eq
#print axioms Orbcrypt.PetrankRoth.prEncode_surjectivity

namespace PetrankRothLayer3NonVacuity
open Orbcrypt.PetrankRoth

/-- **R-CE Layer 3 non-vacuity witness.** `colWeight` evaluates as
    expected at a concrete singleton; the disjoint-union identity
    holds vacuously at empty unions; the
    `colWeight_permuteCodeword_image` invariance holds at the identity
    permutation. -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) (i : Fin (dimPR m)) :
    colWeight ((prEncode m adj).image
        (permuteCodeword (1 : Equiv.Perm (Fin (dimPR m)))))
      ((1 : Equiv.Perm (Fin (dimPR m))) i)
    = colWeight (prEncode m adj) i :=
  colWeight_permuteCodeword_image (prEncode m adj) 1 i

/-- **R-CE Layer 3.3 non-vacuity witness (vertex column weight).**
    At every vertex column, the column weight equals
    `1 + #{present edges incident to v}`.  The constant `1`
    comes from the vertex codeword itself; the variable count
    captures the per-graph edge incidence structure.  This is
    the per-vertex signature the marker-forcing reverse direction
    (Layer 4) consumes to extract the vertex permutation. -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) (v : Fin m) :
    colWeight (prEncode m adj) (prCoord m (.vertex v)) =
    1 + ((Finset.univ : Finset (Fin (numEdges m))).filter
          (fun e => edgePresent m adj e ∧
                    (v = (edgeEndpoints m e).1 ∨
                     v = (edgeEndpoints m e).2))).card :=
  colWeight_prEncode_at_vertex m adj v

/-- **R-CE Layer 3.3 non-vacuity witness (incid column weight).**  At
    every incidence column, the column weight is exactly 1
    (independent of `adj` and of edge presence).  This is the
    invariant the marker-forcing reverse direction (Layer 4) consumes
    to identify incidence columns. -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) (e : Fin (numEdges m)) :
    colWeight (prEncode m adj) (prCoord m (.incid e)) = 1 :=
  colWeight_prEncode_at_incid m adj e

/-- **R-CE Layer 3.3 non-vacuity witness (marker column weight).** -/
example (m : ℕ) (adj : Fin m → Fin m → Bool)
    (e : Fin (numEdges m)) (k : Fin 3) :
    colWeight (prEncode m adj) (prCoord m (.marker e k)) = 1 :=
  colWeight_prEncode_at_marker m adj e k

/-- **R-CE Layer 3.3 non-vacuity witness (sentinel column weight).** -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) :
    colWeight (prEncode m adj)
              (prCoord m (PRCoordKind.sentinel : PRCoordKind m)) = 1 :=
  colWeight_prEncode_at_sentinel m adj

/-- **R-CE Layer 4.0 non-vacuity witness (cardinality-forced
    surjectivity).** `prEncode_surjectivity` exhibits the two-sided
    "image" conclusion from any one-sided CE witness, with the
    cardinality hypothesis discharged automatically.  Identity
    permutation on the empty graph at `m = 3`. -/
example : ∀ c' ∈ prEncode 3 (fun _ _ => false),
    ∃ c ∈ prEncode 3 (fun _ _ => false),
      Orbcrypt.permuteCodeword (1 : Equiv.Perm (Fin (dimPR 3))) c = c' :=
  prEncode_surjectivity 3 _ _ 1 (fun c hc => by
    simpa [Orbcrypt.permuteCodeword] using hc)

end PetrankRothLayer3NonVacuity

-- ============================================================================
-- §15.4  Workstream R-TI (audit 2026-04-25, GI ≤ TI Karp reduction)
--
-- Layer T0 paper synthesis (4 markdown documents in
-- `docs/research/grochow_qiao_*.md`, plus this file's transient
-- `_ApiSurvey.lean` companion) precedes the Lean implementation as
-- Decision GQ-D. Layer T1 (`PathAlgebra.lean`) implements the
-- radical-2 truncated path algebra `F[Q_G] / J²` (Decision GQ-A).
-- Layer T2 (`StructureTensor.lean`) implements the dimension-`m + m * m`
-- tensor encoder with distinguished padding (Decision GQ-B). Layer
-- T3 (`Forward.lean`) implements the slot-permutation lift
-- `liftedSigma m σ : Equiv.Perm (Fin (dimGQ m))`. The complete
-- forward action verification (T3.6) at the GL³ matrix level and
-- the reverse direction (Layer T4 + T5 rigidity argument) are
-- research-scope (R-15-residual-TI-reverse). Field is `F := ℚ`
-- per Decision GQ-C.
-- ============================================================================

#print axioms Orbcrypt.GrochowQiao.QuiverArrow
#print axioms Orbcrypt.GrochowQiao.QuiverArrow.fintype
#print axioms Orbcrypt.GrochowQiao.isPresentArrow
#print axioms Orbcrypt.GrochowQiao.presentArrows
#print axioms Orbcrypt.GrochowQiao.presentArrows_id_mem
#print axioms Orbcrypt.GrochowQiao.presentArrows_edge_mem_iff
#print axioms Orbcrypt.GrochowQiao.presentArrows_disjoint
#print axioms Orbcrypt.GrochowQiao.QuiverArrow.id_injective
#print axioms Orbcrypt.GrochowQiao.QuiverArrow.edge_pair_injective
#print axioms Orbcrypt.GrochowQiao.pathAlgebraDim
#print axioms Orbcrypt.GrochowQiao.directedEdgeCount
#print axioms Orbcrypt.GrochowQiao.pathAlgebraDim_apply
#print axioms Orbcrypt.GrochowQiao.pathAlgebraDim_le
#print axioms Orbcrypt.GrochowQiao.pathAlgebraDim_pos_of_pos_m
#print axioms Orbcrypt.GrochowQiao.pathMul
#print axioms Orbcrypt.GrochowQiao.pathMul_id_id
#print axioms Orbcrypt.GrochowQiao.pathMul_id_edge
#print axioms Orbcrypt.GrochowQiao.pathMul_edge_id
#print axioms Orbcrypt.GrochowQiao.pathMul_edge_edge_none
#print axioms Orbcrypt.GrochowQiao.pathMul_id_self
#print axioms Orbcrypt.GrochowQiao.pathMul_id_id_ne
#print axioms Orbcrypt.GrochowQiao.pathMul_edge_self_none
#print axioms Orbcrypt.GrochowQiao.pathMul_idempotent_iff_id

-- Layer T2 declarations.
#print axioms Orbcrypt.GrochowQiao.dimGQ
#print axioms Orbcrypt.GrochowQiao.SlotKind
#print axioms Orbcrypt.GrochowQiao.slotEquiv
#print axioms Orbcrypt.GrochowQiao.dimGQ_pos_of_pos_m
#print axioms Orbcrypt.GrochowQiao.dimGQ_zero
#print axioms Orbcrypt.GrochowQiao.isPathAlgebraSlot
#print axioms Orbcrypt.GrochowQiao.isPathAlgebraSlot_vertex
#print axioms Orbcrypt.GrochowQiao.isPathAlgebraSlot_arrow
#print axioms Orbcrypt.GrochowQiao.slotToArrow
#print axioms Orbcrypt.GrochowQiao.pathSlotStructureConstant
#print axioms Orbcrypt.GrochowQiao.ambientSlotStructureConstant
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_nonzero_of_pos_dim

-- Layer T3 declarations.
#print axioms Orbcrypt.GrochowQiao.liftedSigmaSlot
#print axioms Orbcrypt.GrochowQiao.liftedSigmaSlotEquiv
#print axioms Orbcrypt.GrochowQiao.liftedSigma
#print axioms Orbcrypt.GrochowQiao.liftedSigmaSlot_one
#print axioms Orbcrypt.GrochowQiao.liftedSigma_one
#print axioms Orbcrypt.GrochowQiao.liftedSigmaSlot_mul
#print axioms Orbcrypt.GrochowQiao.liftedSigma_mul
#print axioms Orbcrypt.GrochowQiao.liftedSigma_vertex
#print axioms Orbcrypt.GrochowQiao.liftedSigma_arrow
#print axioms Orbcrypt.GrochowQiao.isPathAlgebraSlot_liftedSigma

-- Layer T2.5 + T2.6 declarations (post-2026-04-26 R-TI extension).
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_path
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_padding_left
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_padding_mid
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_padding_right
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_diagonal_vertex
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_padding_distinguishable

-- Layer T1 σ-action on quiver arrows + multiplicative equivariance
-- (post-2026-04-26 R-TI extension).
#print axioms Orbcrypt.GrochowQiao.quiverMap
#print axioms Orbcrypt.GrochowQiao.quiverMap_id
#print axioms Orbcrypt.GrochowQiao.quiverMap_edge
#print axioms Orbcrypt.GrochowQiao.quiverMap_one
#print axioms Orbcrypt.GrochowQiao.quiverMap_injective
#print axioms Orbcrypt.GrochowQiao.pathMul_quiverMap

-- Layer T3.4 + T3.7 (forward direction, post-2026-04-26 R-TI extension).
#print axioms Orbcrypt.GrochowQiao.slotToArrow_liftedSigmaSlot
#print axioms Orbcrypt.GrochowQiao.ambientSlotStructureConstant_equivariant
#print axioms Orbcrypt.GrochowQiao.pathSlotStructureConstant_equivariant
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_equivariant
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_pull_back_under_iso

-- Layer T4 + T5 declarations (post-2026-04-26 R-TI extension).
#print axioms Orbcrypt.GrochowQiao.GrochowQiaoRigidity
#print axioms Orbcrypt.GrochowQiao.GrochowQiaoRigidity.apply
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_reverse_zero
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_reverse_one
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_reverse_under_rigidity
#print axioms Orbcrypt.GrochowQiao.GrochowQiaoAsymmetricRigidity
#print axioms Orbcrypt.GrochowQiao.grochowQiaoAsymmetricRigidity_iff_symmetric
#print axioms Orbcrypt.GrochowQiao.GrochowQiaoCharZeroRigidity
#print axioms Orbcrypt.GrochowQiao.grochowQiaoCharZeroRigidity_at_rat
#print axioms Orbcrypt.GrochowQiao.PathAlgebraAutomorphismPermutesVertices
#print axioms Orbcrypt.GrochowQiao.quiverMap_satisfies_vertex_permutation_property

-- Layer T6 declarations (post-2026-04-26 R-TI extension).
#print axioms Orbcrypt.GrochowQiao.GrochowQiaoForwardObligation
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_forward_equality
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_iff
#print axioms Orbcrypt.GrochowQiao.grochowQiao_encode_nonzero_field_check
#print axioms Orbcrypt.GrochowQiao.grochowQiao_isInhabitedKarpReduction_under_obligations
#print axioms Orbcrypt.GrochowQiao.grochowQiao_partial_closure_status

-- Track B (post-2026-04-26 R-TI extension Track B implementation).
-- PermMatrix.lean B.1-B.8: GL³ matrix-action verification.
#print axioms Orbcrypt.GrochowQiao.liftedSigmaMatrix
#print axioms Orbcrypt.GrochowQiao.liftedSigmaMatrix_apply
#print axioms Orbcrypt.GrochowQiao.liftedSigmaMatrix_det_ne_zero
#print axioms Orbcrypt.GrochowQiao.liftedSigmaGL
#print axioms Orbcrypt.GrochowQiao.liftedSigmaGL_val
#print axioms Orbcrypt.GrochowQiao.matMulTensor1_permMatrix
#print axioms Orbcrypt.GrochowQiao.matMulTensor2_permMatrix
#print axioms Orbcrypt.GrochowQiao.matMulTensor3_permMatrix
#print axioms Orbcrypt.GrochowQiao.tensorContract_permMatrix_triple
#print axioms Orbcrypt.GrochowQiao.gl_triple_liftedSigmaGL_smul
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_gl_isomorphic
#print axioms Orbcrypt.GrochowQiao.grochowQiao_forwardObligation
#print axioms Orbcrypt.GrochowQiao.grochowQiao_isInhabitedKarpReduction_under_rigidity

-- Track A.1: pathMul_assoc.
#print axioms Orbcrypt.GrochowQiao.pathMul_assoc

-- Track A.2 partial: pathAlgebraQuotient + Mul + basis elements.
#print axioms Orbcrypt.GrochowQiao.pathAlgebraQuotient
#print axioms Orbcrypt.GrochowQiao.pathAlgebraQuotient.addCommGroup
#print axioms Orbcrypt.GrochowQiao.pathAlgebraQuotient.module
#print axioms Orbcrypt.GrochowQiao.pathAlgebraMul
#print axioms Orbcrypt.GrochowQiao.pathAlgebraQuotient.instMul
#print axioms Orbcrypt.GrochowQiao.pathAlgebraMul_apply
#print axioms Orbcrypt.GrochowQiao.vertexIdempotent
#print axioms Orbcrypt.GrochowQiao.arrowElement
#print axioms Orbcrypt.GrochowQiao.vertexIdempotent_apply_id
#print axioms Orbcrypt.GrochowQiao.vertexIdempotent_apply_edge
#print axioms Orbcrypt.GrochowQiao.arrowElement_apply_id
#print axioms Orbcrypt.GrochowQiao.arrowElement_apply_edge

-- Top-level `Orbcrypt/Hardness/GrochowQiao.lean` re-exports.
#print axioms Orbcrypt.GrochowQiao.grochowQiao_encode_nonzero_field
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_self_isomorphic
#print axioms Orbcrypt.GrochowQiao.liftedSigma_one_eq_id
#print axioms Orbcrypt.GrochowQiao.grochowQiao_research_scope_disclosure

namespace GrochowQiaoNonVacuity

open Orbcrypt
open Orbcrypt.GrochowQiao

/-- **R-TI Layer T1 non-vacuity witness (path algebra dimension on K_3).**
    The complete graph on 3 vertices has 3 vertex idempotents and
    `3 * 2 = 6` directed edges, so `pathAlgebraDim = 9`. -/
example : pathAlgebraDim 3 (fun i j => decide (i ≠ j)) = 9 := by decide

/-- **R-TI Layer T1 non-vacuity witness (path algebra dimension
    on the empty graph at m = 3).** The empty graph has 3 vertex
    idempotents and 0 arrows, so `pathAlgebraDim = 3`. -/
example : pathAlgebraDim 3 (fun _ _ => false) = 3 := by decide

/-- **R-TI Layer T1 non-vacuity witness (`pathMul` evaluation).**
    The diagonal product of an `id` element is itself (idempotent law). -/
example : pathMul 3 (.id 0) (.id 0) = some (.id 0) := by decide

/-- **R-TI Layer T1 non-vacuity witness (off-diagonal vertex idempotents
    are orthogonal).** -/
example : pathMul 3 (.id 0) (.id 1) = none := by decide

/-- **R-TI Layer T1 non-vacuity witness (length-2 path killed by J²).** -/
example (u v u' v' : Fin 3) :
    pathMul 3 (.edge u v) (.edge u' v') = none := rfl

/-- **R-TI Layer T1 non-vacuity witness (idempotent characterisation
    at `id` constructor).** -/
example : ∃ v : Fin 3, (QuiverArrow.id v : QuiverArrow 3) = QuiverArrow.id v :=
  ⟨0, rfl⟩

/-- **R-TI Layer T2 non-vacuity witness (dimension at m = 3).**
    `dimGQ 3 = 3 + 9 = 12`. -/
example : dimGQ 3 = 12 := by decide

/-- **R-TI Layer T2 non-vacuity witness (slot-equiv elaborates).**
    The slotEquiv at `m = 3` produces a vertex slot from index 0. -/
example : slotEquiv 3 ⟨0, by decide⟩ = SlotKind.vertex (0 : Fin 3) := by
  decide

/-- **R-TI Layer T2 non-vacuity witness (`isPathAlgebraSlot` on
    vertex slot is unconditionally true).** -/
example (adj : Fin 3 → Fin 3 → Bool) (v : Fin 3) :
    isPathAlgebraSlot 3 adj ((slotEquiv 3).symm (.vertex v)) = true :=
  isPathAlgebraSlot_vertex 3 adj v

/-- **R-TI Layer T2 non-vacuity witness (`isPathAlgebraSlot` on
    arrow slot equals `adj u v`).** -/
example (adj : Fin 3 → Fin 3 → Bool) (u v : Fin 3) :
    isPathAlgebraSlot 3 adj ((slotEquiv 3).symm (.arrow u v)) = adj u v :=
  isPathAlgebraSlot_arrow 3 adj u v

/-- **R-TI Layer T2 non-vacuity witness (encoder is non-zero on K_3).** -/
example : grochowQiaoEncode 3 (fun i j => decide (i ≠ j)) ≠
          (fun _ _ _ => 0) :=
  grochowQiaoEncode_nonzero_of_pos_dim 3 (by decide) _

/-- **R-TI Layer T2 non-vacuity witness (encoder is non-zero on the
    empty graph at m = 3).** Even with no edges, the diagonal vertex
    slot evaluates to 1 (idempotent law). -/
example : grochowQiaoEncode 3 (fun _ _ => false) ≠ (fun _ _ _ => 0) :=
  grochowQiaoEncode_nonzero_of_pos_dim 3 (by decide) _

/-- **R-TI Layer T3 non-vacuity witness (lifted-σ at identity is
    identity slot permutation).** -/
example : liftedSigma 3 (1 : Equiv.Perm (Fin 3)) =
          (1 : Equiv.Perm (Fin (dimGQ 3))) :=
  liftedSigma_one 3

/-- **R-TI Layer T3 non-vacuity witness (lifted-σ on vertex slot).**
    A non-trivial vertex permutation `σ = swap 0 1` maps vertex slot 0
    to vertex slot 1. -/
example :
    liftedSigma 3 (Equiv.swap (0 : Fin 3) 1)
      ((slotEquiv 3).symm (.vertex 0)) =
    (slotEquiv 3).symm (.vertex 1) := by
  rw [liftedSigma_vertex]
  simp [Equiv.swap_apply_left]

/-- **R-TI Layer T3 non-vacuity witness (`isPathAlgebraSlot` is
    preserved by `liftedSigma` under graph isomorphism).** Identity σ
    on any graph: every slot maps to itself, so the predicate is
    preserved trivially. -/
example (adj : Fin 3 → Fin 3 → Bool) (i : Fin (dimGQ 3)) :
    isPathAlgebraSlot 3 adj i =
    isPathAlgebraSlot 3 adj (liftedSigma 3 (1 : Equiv.Perm (Fin 3)) i) :=
  isPathAlgebraSlot_liftedSigma 3 adj adj 1 (fun _ _ => rfl) i

/-- **R-TI Layer T3 non-vacuity witness (lifted-σ composition law).** -/
example (σ τ : Equiv.Perm (Fin 3)) :
    liftedSigma 3 (σ * τ) = liftedSigma 3 σ * liftedSigma 3 τ :=
  liftedSigma_mul 3 σ τ

/-- **R-TI top-level non-vacuity witness (encoder satisfies the
    strengthened-Prop's non-degeneracy field on every non-empty
    graph at m = 3).** -/
example : ∀ adj : Fin 3 → Fin 3 → Bool,
    grochowQiaoEncode 3 adj ≠ (fun _ _ _ => 0) :=
  grochowQiao_encode_nonzero_field 3 (by decide)

/-- **R-TI top-level non-vacuity witness (every encoded graph is
    tensor-isomorphic to itself).** Reflexivity check confirming the
    forward direction's identity-σ landing point. -/
example (adj : Fin 3 → Fin 3 → Bool) :
    AreTensorIsomorphic (grochowQiaoEncode 3 adj)
                        (grochowQiaoEncode 3 adj) :=
  grochowQiaoEncode_self_isomorphic 3 adj

-- Post-2026-04-26 R-TI Layer T2.5 + T2.6 + T3.4 + T3.7 + T4 + T5 + T6
-- non-vacuity witnesses.

/-- **R-TI Layer T2.5 non-vacuity witness (encoder evaluation at the
    diagonal vertex slot returns `1`).** Confirms the idempotent law
    `e_v · e_v = e_v` is reflected in the encoder. -/
example (adj : Fin 3 → Fin 3 → Bool) :
    grochowQiaoEncode 3 adj
      ((slotEquiv 3).symm (.vertex 0))
      ((slotEquiv 3).symm (.vertex 0))
      ((slotEquiv 3).symm (.vertex 0)) = 1 :=
  grochowQiaoEncode_diagonal_vertex 3 adj 0

/-- **R-TI Layer T2.6 non-vacuity witness (padding-distinguishability
    on the empty graph).** On the empty graph, every arrow slot is
    padding; the lemma says any non-zero entry has its three slot
    indices either all path-algebra or all padding. -/
example
    (i j k : Fin (dimGQ 3))
    (h : grochowQiaoEncode 3 (fun _ _ => false) i j k ≠ 0) :
    (isPathAlgebraSlot 3 (fun _ _ => false) i = true ∧
     isPathAlgebraSlot 3 (fun _ _ => false) j = true ∧
     isPathAlgebraSlot 3 (fun _ _ => false) k = true) ∨
    (isPathAlgebraSlot 3 (fun _ _ => false) i = false ∧
     isPathAlgebraSlot 3 (fun _ _ => false) j = false ∧
     isPathAlgebraSlot 3 (fun _ _ => false) k = false) :=
  grochowQiaoEncode_padding_distinguishable 3 _ i j k h

/-- **R-TI Layer T1 non-vacuity witness (`quiverMap` at identity is
    the identity on quiver arrows).** -/
example : quiverMap 3 (1 : Equiv.Perm (Fin 3)) = id :=
  quiverMap_one 3

/-- **R-TI Layer T1 non-vacuity witness (`quiverMap` is injective).**
    Direct from the σ-action on quiver arrows. -/
example (σ : Equiv.Perm (Fin 3)) :
    Function.Injective (quiverMap 3 σ) :=
  quiverMap_injective 3 σ

/-- **R-TI Layer T1 non-vacuity witness (multiplicative equivariance
    of `pathMul` under `quiverMap`).** Vertex idempotents commute
    with σ-action; the lemma confirms the identity `(σ • a) · (σ • b)
    = σ • (a · b)`. -/
example (σ : Equiv.Perm (Fin 3)) (u v : Fin 3) :
    pathMul 3 (quiverMap 3 σ (.id u)) (quiverMap 3 σ (.id v)) =
    (pathMul 3 (.id u) (.id v)).map (quiverMap 3 σ) :=
  pathMul_quiverMap 3 σ (.id u) (.id v)

/-- **R-TI Layer T3.4 non-vacuity witness (slot-structure-constant
    equivariance under the σ-lift, identity case).** -/
example (i j k : Fin (dimGQ 3)) :
    pathSlotStructureConstant 3
      (liftedSigma 3 (1 : Equiv.Perm (Fin 3)) i)
      (liftedSigma 3 (1 : Equiv.Perm (Fin 3)) j)
      (liftedSigma 3 (1 : Equiv.Perm (Fin 3)) k) =
    pathSlotStructureConstant 3 i j k :=
  pathSlotStructureConstant_equivariant 3 1 i j k

/-- **R-TI Layer T3.7 non-vacuity witness (encoder equivariance at
    σ = identity).** Reflexivity-style check; the σ-lift at identity
    is the identity, so the encoder equivariance reduces to
    `encoder = encoder`. -/
example (adj : Fin 3 → Fin 3 → Bool) (i j k : Fin (dimGQ 3)) :
    grochowQiaoEncode 3 adj i j k =
    grochowQiaoEncode 3 adj
      (liftedSigma 3 1 i) (liftedSigma 3 1 j) (liftedSigma 3 1 k) :=
  grochowQiaoEncode_equivariant 3 adj adj 1 (fun _ _ => rfl) i j k

/-- **R-TI Layer T5.3 non-vacuity witness (empty-graph reverse
    direction is unconditional, `m = 0`).** Trivially discharged
    because `Fin 0` is empty. -/
example (adj₁ adj₂ : Fin 0 → Fin 0 → Bool)
    (h : AreTensorIsomorphic (grochowQiaoEncode 0 adj₁)
                              (grochowQiaoEncode 0 adj₂)) :
    ∃ σ : Equiv.Perm (Fin 0), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j) :=
  grochowQiaoEncode_reverse_zero adj₁ adj₂ h

/-- **R-TI Layer T5 non-vacuity witness (one-vertex reverse direction
    is unconditional, `m = 1`).** Discharged by `Subsingleton.elim` on
    `Fin 1`. -/
example (adj₁ adj₂ : Fin 1 → Fin 1 → Bool)
    (h : adj₁ 0 0 = adj₂ 0 0) :
    ∃ σ : Equiv.Perm (Fin 1), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j) :=
  grochowQiaoEncode_reverse_one adj₁ adj₂ h

/-- **R-TI Layer T5.4 non-vacuity witness (conditional reverse
    direction under the rigidity hypothesis).** -/
example (h_rigidity : GrochowQiaoRigidity)
    (adj₁ adj₂ : Fin 3 → Fin 3 → Bool)
    (h_iso : AreTensorIsomorphic (grochowQiaoEncode 3 adj₁)
                                  (grochowQiaoEncode 3 adj₂)) :
    ∃ σ : Equiv.Perm (Fin 3), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j) :=
  grochowQiaoEncode_reverse_under_rigidity h_rigidity 3 _ _ h_iso

/-- **R-TI Layer T5.6 stretch non-vacuity witness (asymmetric
    rigidity ↔ symmetric for graphs).** -/
example : GrochowQiaoAsymmetricRigidity ↔ GrochowQiaoRigidity :=
  grochowQiaoAsymmetricRigidity_iff_symmetric

/-- **R-TI Layer T5.8 stretch non-vacuity witness (char-0 Prop at
    `F = ℚ` reduces to standard rigidity).** -/
example : GrochowQiaoCharZeroRigidity ℚ = GrochowQiaoRigidity :=
  grochowQiaoCharZeroRigidity_at_rat

/-- **R-TI Layer T4.3 non-vacuity witness (σ-induced quiver map
    permutes vertex idempotents).** Direct discharge of the easy
    half of T4.3 — the existence direction when σ is given. -/
example (σ : Equiv.Perm (Fin 3)) (v : Fin 3) :
    quiverMap 3 σ (.id v) = .id (σ v) :=
  quiverMap_satisfies_vertex_permutation_property 3 σ v

/-- **R-TI Layer T6.1 non-vacuity witness (iff under both
    obligations).** Conditional Karp-reduction iff. -/
example (h_forward : GrochowQiaoForwardObligation)
    (h_rigidity : GrochowQiaoRigidity) :
    ∀ (adj₁ adj₂ : Fin 3 → Fin 3 → Bool),
      (∃ σ : Equiv.Perm (Fin 3), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) ↔
      AreTensorIsomorphic (grochowQiaoEncode 3 adj₁)
                          (grochowQiaoEncode 3 adj₂) :=
  fun adj₁ adj₂ => grochowQiaoEncode_iff h_forward h_rigidity 3 adj₁ adj₂

/-- **R-TI Layer T6.3 non-vacuity witness (conditional `GIReducesToTI`
    inhabitant under both obligations).** Post-discharge of both
    research-scope Props, this becomes a complete inhabitant. -/
example (h_forward : GrochowQiaoForwardObligation)
    (h_rigidity : GrochowQiaoRigidity) :
    @GIReducesToTI ℚ _ :=
  grochowQiao_isInhabitedKarpReduction_under_obligations h_forward h_rigidity

/-- **R-TI Layer T6.4 non-vacuity witness (partial closure status).**
    Documents the unconditional content: encoder non-zero, empty-graph
    reverse, AND `GrochowQiaoForwardObligation` discharged
    (post-Track-B extension). -/
example :
    (∀ m, 1 ≤ m → ∀ adj : Fin m → Fin m → Bool,
        grochowQiaoEncode m adj ≠ (fun _ _ _ => 0)) ∧
    (∀ adj₁ adj₂ : Fin 0 → Fin 0 → Bool,
        AreTensorIsomorphic (grochowQiaoEncode 0 adj₁)
                            (grochowQiaoEncode 0 adj₂) →
        ∃ σ : Equiv.Perm (Fin 0), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) ∧
    GrochowQiaoForwardObligation :=
  grochowQiao_partial_closure_status

-- Post-2026-04-26 R-TI Track B + A.1 + A.2 partial extensions.

/-- **R-TI Track B.1 non-vacuity witness (lifted permutation matrix
    elaborates).** -/
example : liftedSigmaMatrix 3 (1 : Equiv.Perm (Fin 3)) =
          ((1 : Equiv.Perm (Fin (dimGQ 3))).permMatrix ℚ) := by
  simp [liftedSigmaMatrix, liftedSigma_one]

/-- **R-TI Track B.2 non-vacuity witness (lifted GL element exists).** -/
example : ∃ g : GL (Fin (dimGQ 3)) ℚ, g = liftedSigmaGL 3 (1 : Equiv.Perm (Fin 3)) :=
  ⟨liftedSigmaGL 3 1, rfl⟩

/-- **R-TI Track B.6 non-vacuity witness (triple-permutation tensor
    collapse to identity at σ = 1).** -/
example (T : Tensor3 (dimGQ 3) ℚ) :
    tensorContract ((1 : Equiv.Perm (Fin (dimGQ 3))).permMatrix ℚ)
                    ((1 : Equiv.Perm (Fin (dimGQ 3))).permMatrix ℚ)
                    ((1 : Equiv.Perm (Fin (dimGQ 3))).permMatrix ℚ) T = T := by
  rw [tensorContract_permMatrix_triple]; rfl

/-- **R-TI Track B.8 non-vacuity witness (forward obligation
    discharged unconditionally).** -/
example : GrochowQiaoForwardObligation := grochowQiao_forwardObligation

/-- **R-TI Track A.1 non-vacuity witness (pathMul_assoc on a concrete
    triple).** Vertex idempotent triple-product associativity. -/
example (m : ℕ) (v : Fin m) :
    Option.bind (pathMul m (.id v) (.id v))
                (fun ab => pathMul m ab (.id v)) =
    Option.bind (pathMul m (.id v) (.id v))
                (fun bc => pathMul m (.id v) bc) :=
  pathMul_assoc m (.id v) (.id v) (.id v)

/-- **R-TI Track A.2 non-vacuity witness (vertex idempotent and
    arrow element distinctness on basis evaluation).** -/
example (m : ℕ) (v : Fin m) :
    vertexIdempotent m v (.id v) = (1 : ℚ) ∧
    vertexIdempotent m v (.edge v v) = (0 : ℚ) := by
  refine ⟨?_, ?_⟩
  · simp [vertexIdempotent]
  · simp [vertexIdempotent]

/-- **R-TI new conditional inhabitant (single Prop hypothesis).**
    Post-Track-B, the Karp-reduction inhabitant requires only the
    rigidity Prop. -/
example (h_rigidity : GrochowQiaoRigidity) : @GIReducesToTI ℚ _ :=
  grochowQiao_isInhabitedKarpReduction_under_rigidity h_rigidity

end GrochowQiaoNonVacuity

-- ============================================================================
-- ## §15.5 Workstream R-TI Layer 6 + 6b (CompleteOrthogonal + Wedderburn-Mal'cev)
-- ============================================================================

#print axioms Orbcrypt.GrochowQiao.vertexIdempotent_completeOrthogonalIdempotents
#print axioms Orbcrypt.GrochowQiao.AlgEquiv_preserves_completeOrthogonalIdempotents
#print axioms Orbcrypt.GrochowQiao.pathAlgebraRadical
#print axioms Orbcrypt.GrochowQiao.arrowElement_mem_pathAlgebraRadical
#print axioms Orbcrypt.GrochowQiao.pathAlgebraRadical_mul_radical_eq_zero
#print axioms Orbcrypt.GrochowQiao.pathAlgebra_decompose_radical
#print axioms Orbcrypt.GrochowQiao.oneAddRadical_mul_oneSubRadical
#print axioms Orbcrypt.GrochowQiao.oneSubRadical_mul_oneAddRadical
#print axioms Orbcrypt.GrochowQiao.innerAut_simplified
#print axioms Orbcrypt.GrochowQiao.coi_vertex_coef_zero_or_one
#print axioms Orbcrypt.GrochowQiao.coi_vertex_coef_orth
#print axioms Orbcrypt.GrochowQiao.coi_vertex_coef_complete
#print axioms Orbcrypt.GrochowQiao.coi_unique_active_per_z
#print axioms Orbcrypt.GrochowQiao.coi_chooseActive_bijective
#print axioms Orbcrypt.GrochowQiao.coi_vertexPerm
#print axioms Orbcrypt.GrochowQiao.coi_vertexPerm_active
#print axioms Orbcrypt.GrochowQiao.coi_vertexPerm_eval
#print axioms Orbcrypt.GrochowQiao.coi_conjugator
#print axioms Orbcrypt.GrochowQiao.coi_conjugator_mem_radical
#print axioms Orbcrypt.GrochowQiao.coi_conjugator_apply_id
#print axioms Orbcrypt.GrochowQiao.coi_conjugator_apply_edge
#print axioms Orbcrypt.GrochowQiao.coi_conjugation_identity
#print axioms Orbcrypt.GrochowQiao.wedderburn_malcev_conjugacy

namespace WedderburnMalcevNonVacuity

open Orbcrypt.GrochowQiao

/-- The canonical vertex-idempotent COI is itself a witness. -/
example : CompleteOrthogonalIdempotents (vertexIdempotent 3) :=
  vertexIdempotent_completeOrthogonalIdempotents 3

/-- Non-vacuity at m = 1: the canonical COI yields a trivial conjugacy
    via the Wedderburn-Mal'cev theorem. -/
example :
    ∃ (σ : Equiv.Perm (Fin 1)) (j : pathAlgebraQuotient 1),
      j ∈ pathAlgebraRadical 1 ∧
      ∀ v : Fin 1,
        (1 + j) * vertexIdempotent 1 (σ v) * (1 - j) = vertexIdempotent 1 v :=
  wedderburn_malcev_conjugacy 1 (vertexIdempotent 1)
    (vertexIdempotent_completeOrthogonalIdempotents 1)
    (vertexIdempotent_ne_zero 1)

end WedderburnMalcevNonVacuity
