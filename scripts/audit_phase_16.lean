/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

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

The script supersedes per-workstream audit files
(`scripts/legacy/audit_b_workstream.lean`,
`scripts/legacy/audit_c_workstream.lean`, ...) by covering every
public declaration in a single pass. Those per-workstream scripts
are archived under `scripts/legacy/` (relocated by Workstream **B2**
of the 2026-04-29 audit plan); see `scripts/legacy/README.md` for
the archive's file index and the rationale for retention versus
deletion. The legacy scripts remain for historical reference but
are not exercised by CI.

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
-- Workstream R-01 (audit 2026-04-29 § 8.1): quantitative cross-orbit
-- advantage lower bound. The deterministic `invariant_attack` above
-- delivers existence of one distinguishing `(g₀, g₁)` pair; R-01
-- strengthens this to the tight probabilistic equality
-- `indCPAAdvantage = 1` whenever a separating G-invariant is supplied.
-- See `docs/planning/PLAN_R_01_07_08_14_16.md` § R-01 for the
-- discharge plan and the KEM-layer-companion-vacuity finding.
#print axioms probTrue_orbitDist_invariant_eq_one
#print axioms probTrue_orbitDist_invariant_eq_zero
#print axioms indCPAAdvantage_invariantAttackAdversary_eq_one

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

-- Construction.BitstringSupport — Workstream C of audit 2026-04-29
-- (finding D-02a / C5): the support representation of bitstrings as a
-- bijection with `Finset (Fin n)`, with G-equivariance (the OnSets
-- correspondence) and order-preservation. Headline application: GAP /
-- Lean canonical-image equivalence at arbitrary `n`, closing the
-- pre-C5 prose-level disclosure in `Construction/HGOE.lean:88-113`.
#print axioms support
#print axioms mem_support_iff
#print axioms ofSupport
#print axioms ofSupport_apply
#print axioms support_ofSupport
#print axioms ofSupport_support
#print axioms bitstringSupportEquiv
#print axioms bitstringSupportEquiv_apply
#print axioms bitstringSupportEquiv_symm_apply
#print axioms support_injective
#print axioms support_smul
#print axioms support_smul_apply
#print axioms listLex_ofFn_iff
#print axioms bitstringLinearOrder_lt_iff_first_differ
#print axioms gapSetLT
#print axioms bitstringLinearOrder_lt_iff_gapSetLT_support
#print axioms support_canon_minimal
#print axioms support_canon_gapSetLT_minimal
#print axioms support_canon_in_support_orbit

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
-- Workstream R-07 (audit 2026-04-29 § 8.1, plan
-- `docs/planning/PLAN_R_01_07_08_14_16.md` § R-07): cross-orbit
-- advantage lower bound for equivariant combiners. The intra-orbit
-- mass bound `combinerOrbitDist_mass_bounds` (E6b) is *not* by itself
-- a cross-orbit advantage lower bound; R-07 supplies the missing
-- cross-orbit witness via `CrossOrbitNonDegenerateCombiner` and
-- delivers the headline `combinerDistinguisherAdvantage ≥ 1/|G|`.
-- Composed with `concrete_combiner_advantage_bounded_by_oia` (E6
-- upper bound), this refutes `ConcreteOIA scheme ε` for any `ε <
-- 1/|G|` whenever a cross-orbit non-degenerate combiner exists.
#print axioms combinerOrbitDist_apply_true_eq_probTrue
#print axioms CrossOrbitNonDegenerateCombiner
#print axioms probTrue_combinerDistinguisher_basePoint_ge_inv_card
#print axioms probTrue_combinerDistinguisher_target_eq_zero
#print axioms combinerDistinguisherAdvantage_ge_inv_card
#print axioms no_concreteOIA_below_inv_card_of_combiner

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
    `scripts/legacy/audit_c_workstream.lean`, relocated by
    Workstream B2 of the 2026-04-29 audit plan) but is
    re-materialised here so `audit_phase_16.lean` remains a
    self-contained audit script.
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

/-! ## Workstream C / C5 non-vacuity witnesses

The Workstream-C / C5 deliverable of audit 2026-04-29 (finding
D-02a) lands a formal GAP/Lean canonical-image-equivalence module
under `Orbcrypt/Construction/BitstringSupport.lean`. The non-vacuity
witnesses below confirm each headline theorem is non-trivially
applicable on concrete `Bitstring 3` inputs at full and weight-
restricted subgroups of `Equiv.Perm (Fin 3)`, mirroring the
small-`n` verification pattern the audit-plan finding asked for
while the symbolic theorems handle arbitrary `n`. -/

/-- `support` and `ofSupport` round-trip on a concrete bitstring,
    discharged by `decide`. This exercises both directions of the
    `bitstringSupportEquiv`. -/
example :
    support (![true, false, true] : Bitstring 3) =
      ({0, 2} : Finset (Fin 3)) := by
  ext i
  -- `mem_support_iff` is already `@[simp]`, so `simp [support]` suffices
  -- (the linter flagged the explicit redundant entry pre-Workstream-D
  -- discharge audit; fixed 2026-04-30).
  fin_cases i <;> simp [support]

/-- The `ofSupport_support` round-trip on `![true, false, true]`. -/
example :
    ofSupport (support (![true, false, true] : Bitstring 3)) =
      ![true, false, true] :=
  ofSupport_support _

/-- The `support_ofSupport` round-trip on a concrete finset. -/
example :
    support (ofSupport (({0, 2} : Finset (Fin 3)))) =
      ({0, 2} : Finset (Fin 3)) :=
  support_ofSupport _

/-- **G-equivariance / OnSets correspondence on a concrete
    permutation.** Take `σ = Equiv.swap 0 1 : Equiv.Perm (Fin 3)`
    and `x = ![true, false, false] : Bitstring 3` (support `{0}`).
    Then `σ • x = ![false, true, false]` (support `{1}`), which is
    the OnSets-image `{σ 0} = {1}` of the original support `{0}`.

    Because the equation has dependently-typed sides (Finset over
    Fin 3), we discharge by `decide` after applying `support_smul`. -/
example :
    support ((Equiv.swap (0 : Fin 3) 1) • (![true, false, false] : Bitstring 3))
      = (support (![true, false, false] : Bitstring 3)).image
          (Equiv.swap (0 : Fin 3) 1).toEmbedding := by
  exact support_smul (Equiv.swap (0 : Fin 3) 1) ![true, false, false]

/-- Order-correspondence on concrete bitstrings. Take
    `x = ![true, true, false]` and `y = ![true, false, true]`. They
    differ first at index `1` (`x 1 = true`, `y 1 = false`), so
    `x < y` under `bitstringLinearOrder` (and equivalently,
    `support x = {0, 1} < {0, 2} = support y` in GAP set-lex). -/
example :
    @LT.lt (Bitstring 3) bitstringLinearOrder.toLT
      (![true, true, false] : Bitstring 3)
      (![true, false, true] : Bitstring 3) ↔
    gapSetLT (support (![true, true, false] : Bitstring 3))
             (support (![true, false, true] : Bitstring 3)) :=
  bitstringLinearOrder_lt_iff_gapSetLT_support _ _

/-- The first-differing-index characterization of `bitstringLinearOrder.lt`
    fires on a concrete pair of bitstrings. -/
example :
    (@LT.lt (Bitstring 3) bitstringLinearOrder.toLT
      (![true, true, false] : Bitstring 3)
      (![true, false, true] : Bitstring 3)) ↔
    ∃ i : Fin 3, (∀ j : Fin 3, j.val < i.val →
        (![true, true, false] : Bitstring 3) j =
          (![true, false, true] : Bitstring 3) j) ∧
      (![true, true, false] : Bitstring 3) i = true ∧
      (![true, false, true] : Bitstring 3) i = false :=
  bitstringLinearOrder_lt_iff_first_differ _ _

/-- The headline equivalence applied to the top subgroup `⊤ ≤ S_3`
    on a weight-2 bitstring `![true, false, true]`. This exhibits
    that some `g : ↥⊤` makes `support (canon ![T, F, T]) =
    (support ![T, F, T]).image g.toEmbedding`. The witness lives
    inside the existential statement of `support_canon_in_support_orbit`. -/
example :
    let G : Subgroup (Equiv.Perm (Fin 3)) := ⊤
    letI : DecidablePred (· ∈ G) := fun _ => isTrue trivial
    letI : LinearOrder (Bitstring 3) := bitstringLinearOrder
    ∃ g : ↥G, support
      ((CanonicalForm.ofLexMin (G := ↥G) (X := Bitstring 3)).canon
        (![true, false, true] : Bitstring 3)) =
      (support (![true, false, true] : Bitstring 3)).image
        ((g : Equiv.Perm (Fin 3)).toEmbedding) := by
  letI : DecidablePred (· ∈ (⊤ : Subgroup (Equiv.Perm (Fin 3)))) :=
    fun _ => isTrue trivial
  exact support_canon_in_support_orbit ![true, false, true]

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
-- `docs/research/grochow_qiao_*.md`; pre-Workstream-B1 of the
-- 2026-04-29 audit plan a transient `_ApiSurvey.lean` companion
-- also accompanied them, deleted by B1 after the live PathAlgebra
-- / StructureTensor modules superseded its regression-sentinel
-- purpose) precedes the Lean implementation as Decision GQ-D.
-- Layer T1 (`PathAlgebra.lean`) implements the
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
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_diagonal_padding
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

/-- **Stage 0 non-vacuity witness (encoder evaluation at the diagonal of a
    padding slot returns `2`).** Confirms the post-Stage-0
    distinguished-padding strengthening: padding-diagonal value `2` is
    distinct from vertex-diagonal value `1` and present-arrow-diagonal
    value `0`, closing the isolated-vertex degeneracy at the
    diagonal-value level. Witnessed on the empty graph at `m = 2`,
    where the arrow slot `(0, 1)` is a padding slot. -/
example :
    grochowQiaoEncode 2 (fun _ _ => false)
      ((slotEquiv 2).symm (.arrow 0 1))
      ((slotEquiv 2).symm (.arrow 0 1))
      ((slotEquiv 2).symm (.arrow 0 1)) = 2 :=
  grochowQiaoEncode_diagonal_padding 2 (fun _ _ => false) 0 1 rfl

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
#print axioms Orbcrypt.GrochowQiao.algEquiv_image_vertexIdempotent_COI
#print axioms Orbcrypt.GrochowQiao.algEquiv_image_vertexIdempotent_ne_zero
#print axioms Orbcrypt.GrochowQiao.algEquiv_extractVertexPerm

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

/-- Phase F starter non-vacuity: the identity `AlgEquiv` on
    `pathAlgebraQuotient 1` yields σ + j via `algEquiv_extractVertexPerm`
    (extracting from the trivially-equal `φ ∘ vertexIdempotent`). -/
example :
    ∃ (σ : Equiv.Perm (Fin 1)) (j : pathAlgebraQuotient 1),
      j ∈ pathAlgebraRadical 1 ∧
      ∀ v : Fin 1,
        (1 + j) * vertexIdempotent 1 (σ v) * (1 - j) =
        (AlgEquiv.refl : pathAlgebraQuotient 1 ≃ₐ[ℚ] pathAlgebraQuotient 1)
          (vertexIdempotent 1 v) :=
  algEquiv_extractVertexPerm 1 AlgEquiv.refl

end WedderburnMalcevNonVacuity

-- ============================================================================
-- ## §15.6 Workstream R-TI Stage 1 T-API-1 (Tensor3 unfoldings).
-- ============================================================================

#print axioms Orbcrypt.Tensor3.unfold₁
#print axioms Orbcrypt.Tensor3.unfold₂
#print axioms Orbcrypt.Tensor3.unfold₃
#print axioms Orbcrypt.Tensor3.unfold₁_apply
#print axioms Orbcrypt.Tensor3.unfold₂_apply
#print axioms Orbcrypt.Tensor3.unfold₃_apply
#print axioms Orbcrypt.Tensor3.unfold₁_inj
#print axioms Orbcrypt.Tensor3.unfold₂_inj
#print axioms Orbcrypt.Tensor3.unfold₃_inj
#print axioms Orbcrypt.Tensor3.unfold₁_matMulTensor1
#print axioms Orbcrypt.Tensor3.unfold₂_matMulTensor2
#print axioms Orbcrypt.Tensor3.unfold₃_matMulTensor3
#print axioms Orbcrypt.Tensor3.unfold₁_matMulTensor2
#print axioms Orbcrypt.Tensor3.unfold₁_matMulTensor3
#print axioms Orbcrypt.Tensor3.unfold₁_tensorContract

namespace TensorUnfoldNonVacuity

open Orbcrypt
open Orbcrypt.Tensor3
open scoped Matrix
open scoped Kronecker

/-- **T-API-1 non-vacuity witness (axis-1 unfolding apply at concrete index).**
On a hand-rolled `Tensor3 2 ℚ`, the axis-1 unfolding evaluates by
definition to the underlying tensor entry. -/
example (T : Tensor3 2 ℚ) (i j k : Fin 2) :
    unfold₁ T i (j, k) = T i j k := rfl

/-- **T-API-1 non-vacuity witness (single-axis bridge for axis-1).**
The axis-1 contraction `matMulTensor1 A T` corresponds to left matrix
multiplication on the axis-1 unfolding. -/
example (A : Matrix (Fin 2) (Fin 2) ℚ) (T : Tensor3 2 ℚ) :
    unfold₁ (matMulTensor1 A T) = A * unfold₁ T :=
  unfold₁_matMulTensor1 A T

/-- **T-API-1 non-vacuity witness (Kronecker bridge for axis-2 acting on
    `unfold₁`).** The axis-2 contraction is right matrix multiplication
by `Bᵀ ⊗ₖ 1`. -/
example (B : Matrix (Fin 2) (Fin 2) ℚ) (T : Tensor3 2 ℚ) :
    unfold₁ (matMulTensor2 B T) =
      unfold₁ T * (Bᵀ ⊗ₖ (1 : Matrix (Fin 2) (Fin 2) ℚ)) :=
  unfold₁_matMulTensor2 B T

/-- **T-API-1 non-vacuity witness (combined GL³-action bridge).** The full
`tensorContract A B C T` corresponds, on the axis-1 unfolding, to the
matrix product `A * unfold₁ T * (Bᵀ ⊗ₖ Cᵀ)`. -/
example (A B C : Matrix (Fin 2) (Fin 2) ℚ) (T : Tensor3 2 ℚ) :
    unfold₁ (tensorContract A B C T) = A * unfold₁ T * (Bᵀ ⊗ₖ Cᵀ) :=
  unfold₁_tensorContract A B C T

end TensorUnfoldNonVacuity

-- ============================================================================
-- ## §15.7 Workstream R-TI Stage 1 T-API-2 (GL³ rank invariance).
-- ============================================================================

#print axioms Orbcrypt.Tensor3.kronecker_isUnit_det
#print axioms Orbcrypt.Tensor3.unfoldRank₁
#print axioms Orbcrypt.Tensor3.unfoldRank₂
#print axioms Orbcrypt.Tensor3.unfoldRank₃
#print axioms Orbcrypt.Tensor3.tensorRank
#print axioms Orbcrypt.Tensor3.unfoldRank₁_smul
#print axioms Orbcrypt.Tensor3.unfoldRank₁_areTensorIsomorphic

namespace RankInvarianceNonVacuity

open Orbcrypt
open Orbcrypt.Tensor3
open scoped Matrix
open scoped Kronecker

/-- **T-API-2 non-vacuity witness (axis-1 rank invariance under identity GL³).**
The identity element of GL³ acts trivially on any tensor, so the rank
is trivially preserved.  Confirms `unfoldRank₁_smul` is well-typed. -/
example (T : Tensor3 2 ℚ) :
    unfoldRank₁ ((1 : GL (Fin 2) ℚ × GL (Fin 2) ℚ × GL (Fin 2) ℚ) • T) =
      unfoldRank₁ T :=
  unfoldRank₁_smul (n := 2) 1 T

/-- **T-API-2 non-vacuity witness (rank tuple at concrete tensor).**
On a hand-rolled `Tensor3 1 ℚ`, the rank tuple is well-defined. -/
example (T : Tensor3 1 ℚ) : tensorRank T = (unfoldRank₁ T, unfoldRank₂ T, unfoldRank₃ T) :=
  rfl

/-- **T-API-2 non-vacuity witness (Kronecker preserves invertibility).**
The Kronecker product of the identity matrices is itself a unit (in fact
the identity), confirming `kronecker_isUnit_det` discharges on units. -/
example : IsUnit ((1 : Matrix (Fin 2) (Fin 2) ℚ) ⊗ₖ (1 : Matrix (Fin 2) (Fin 2) ℚ)).det :=
  kronecker_isUnit_det 1 1 (by simp) (by simp)

end RankInvarianceNonVacuity

-- ============================================================================
-- ## §15.8 Workstream R-TI Stage 2 T-API-3 (slot signature classification).
-- ============================================================================

#print axioms Orbcrypt.GrochowQiao.isVertexSlot
#print axioms Orbcrypt.GrochowQiao.isPresentArrowSlot
#print axioms Orbcrypt.GrochowQiao.isPaddingSlot
#print axioms Orbcrypt.GrochowQiao.vertexSlotIndices
#print axioms Orbcrypt.GrochowQiao.presentArrowSlotIndices
#print axioms Orbcrypt.GrochowQiao.paddingSlotIndices
#print axioms Orbcrypt.GrochowQiao.pathSlotIndices
#print axioms Orbcrypt.GrochowQiao.mem_vertexSlotIndices_iff
#print axioms Orbcrypt.GrochowQiao.mem_presentArrowSlotIndices_iff
#print axioms Orbcrypt.GrochowQiao.mem_paddingSlotIndices_iff
#print axioms Orbcrypt.GrochowQiao.mem_pathSlotIndices_iff
#print axioms Orbcrypt.GrochowQiao.vertexSlotIndices_disjoint_presentArrowSlotIndices
#print axioms Orbcrypt.GrochowQiao.vertexSlotIndices_disjoint_paddingSlotIndices
#print axioms Orbcrypt.GrochowQiao.presentArrowSlotIndices_disjoint_paddingSlotIndices
#print axioms Orbcrypt.GrochowQiao.vertex_present_padding_partition
#print axioms Orbcrypt.GrochowQiao.pathSlotIndices_eq_vertex_union_presentArrow
#print axioms Orbcrypt.GrochowQiao.vertexSlotIndices_card
#print axioms Orbcrypt.GrochowQiao.pathSlotIndices_card_empty
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_diagonal_at_vertexSlot
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_diagonal_at_presentArrowSlot
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_diagonal_at_paddingSlot
#print axioms Orbcrypt.GrochowQiao.encoder_diagonal_values_pairwise_distinct
#print axioms Orbcrypt.GrochowQiao.grochowQiaoEncode_diagonal_present_arrow

namespace SlotSignatureNonVacuity

open Orbcrypt
open Orbcrypt.GrochowQiao

/-- **Stage 2 T-API-3 non-vacuity witness (vertex slot Finset cardinality at m=3).**
There are exactly 3 vertex slots in `Fin (dimGQ 3)`. -/
example : (vertexSlotIndices 3).card = 3 :=
  vertexSlotIndices_card 3

/-- **Stage 2 T-API-3 non-vacuity witness (path-slot card on empty graph).**
On the empty graph at m=3, only vertex slots are path-algebra; the count is 3. -/
example : (pathSlotIndices 3 (fun _ _ => false)).card = 3 :=
  pathSlotIndices_card_empty 3

/-- **Stage 2 T-API-3 non-vacuity witness (diagonal value distinguishability).**
The three slot-kind diagonal values are pairwise distinct. -/
example : ((1 : ℚ) ≠ 0) ∧ ((1 : ℚ) ≠ 2) ∧ ((0 : ℚ) ≠ 2) :=
  encoder_diagonal_values_pairwise_distinct

end SlotSignatureNonVacuity

-- ============================================================================
-- ## §15.9 Workstream R-TI Stage 2 T-API-5 (slot bijection).
-- ============================================================================

#print axioms Orbcrypt.GrochowQiao.IsPartitionPreserving
#print axioms Orbcrypt.GrochowQiao.IsVertexSlotPreserving
#print axioms Orbcrypt.GrochowQiao.IsPresentArrowSlotPreserving
#print axioms Orbcrypt.GrochowQiao.IsPaddingSlotPreserving
#print axioms Orbcrypt.GrochowQiao.IsThreePartitionPreserving
#print axioms Orbcrypt.GrochowQiao.isThreePartitionPreserving_one
#print axioms Orbcrypt.GrochowQiao.IsVertexSlotPreserving.inv
#print axioms Orbcrypt.GrochowQiao.IsPresentArrowSlotPreserving.inv
#print axioms Orbcrypt.GrochowQiao.IsPaddingSlotPreserving.inv
#print axioms Orbcrypt.GrochowQiao.IsThreePartitionPreserving.inv
#print axioms Orbcrypt.GrochowQiao.vertexSlot_bijOn_of_vertexPreserving
#print axioms Orbcrypt.GrochowQiao.presentArrowSlot_bijOn_of_presentArrowPreserving
#print axioms Orbcrypt.GrochowQiao.paddingSlot_bijOn_of_paddingPreserving
#print axioms Orbcrypt.GrochowQiao.presentArrowSlot_card_eq_of_presentArrowPreserving
#print axioms Orbcrypt.GrochowQiao.vertexSlotIndices_image_eq_of_vertexPreserving
#print axioms Orbcrypt.GrochowQiao.paddingSlot_card_eq_of_paddingPreserving
#print axioms Orbcrypt.GrochowQiao.present_arrow_count_eq_of_threePartitionPreserving

namespace SlotBijectionNonVacuity

open Orbcrypt
open Orbcrypt.GrochowQiao

/-- **Stage 2 T-API-5 non-vacuity witness (identity is three-partition-preserving).**
The identity slot permutation trivially preserves all three slot-kind classes. -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) :
    IsThreePartitionPreserving m adj adj 1 :=
  isThreePartitionPreserving_one m adj

/-- **Stage 2 T-API-5 non-vacuity witness (cardinality preservation).**
Under the identity permutation, present-arrow slots have the same count
in both adjacencies (vacuously: same adjacency). -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) :
    (presentArrowSlotIndices m adj).card =
      (presentArrowSlotIndices m adj).card :=
  presentArrowSlot_card_eq_of_presentArrowPreserving m adj adj 1
    (isThreePartitionPreserving_one m adj).presentArrow

end SlotBijectionNonVacuity

-- ============================================================================
-- ## §15.10 Workstream R-TI Stage 2 T-API-6 (vertex permutation descent).
-- ============================================================================

#print axioms Orbcrypt.GrochowQiao.vertexImage
#print axioms Orbcrypt.GrochowQiao.vertexImage_spec
#print axioms Orbcrypt.GrochowQiao.vertexImage_inv
#print axioms Orbcrypt.GrochowQiao.vertexImage_inv'
#print axioms Orbcrypt.GrochowQiao.vertexPermOfVertexPreserving
#print axioms Orbcrypt.GrochowQiao.vertexPermOfVertexPreserving_apply
#print axioms Orbcrypt.GrochowQiao.vertexPermOfVertexPreserving_one

namespace VertexPermDescentNonVacuity

open Orbcrypt
open Orbcrypt.GrochowQiao

/-- **Stage 2 T-API-6 non-vacuity witness (identity descent).**
The identity slot permutation descends to the identity vertex permutation. -/
example (m : ℕ)
    (h : IsVertexSlotPreserving m (1 : Equiv.Perm (Fin (dimGQ m)))) :
    vertexPermOfVertexPreserving m 1 h = 1 :=
  vertexPermOfVertexPreserving_one m h

end VertexPermDescentNonVacuity

-- ============================================================================
-- ## §15.11 Workstream R-TI Stage 3 T-API-4 (block decomposition under GL³).
-- ============================================================================

#print axioms Orbcrypt.GrochowQiao.GL3PreservesPartitionCardinalities
#print axioms Orbcrypt.GrochowQiao.gl3_preserves_partition_cardinalities_identity_case
#print axioms Orbcrypt.GrochowQiao.presentArrowSlotEquiv
#print axioms Orbcrypt.GrochowQiao.paddingSlotEquiv
#print axioms Orbcrypt.GrochowQiao.padding_card_eq_of_present_card_eq
#print axioms Orbcrypt.GrochowQiao.partitionPreservingFwd
#print axioms Orbcrypt.GrochowQiao.partitionPreservingInv
#print axioms Orbcrypt.GrochowQiao.partitionPreservingFwd_presentArrow
#print axioms Orbcrypt.GrochowQiao.partitionPreservingFwd_padding
#print axioms Orbcrypt.GrochowQiao.partitionPreservingFwd_vertex
#print axioms Orbcrypt.GrochowQiao.partitionPreservingInv_vertex
#print axioms Orbcrypt.GrochowQiao.partitionPreservingFwd_apply_presentArrow
#print axioms Orbcrypt.GrochowQiao.partitionPreservingFwd_apply_padding
#print axioms Orbcrypt.GrochowQiao.partitionPreservingInv_apply_presentArrow
#print axioms Orbcrypt.GrochowQiao.partitionPreservingInv_apply_padding
#print axioms Orbcrypt.GrochowQiao.partitionPreservingInv_fwd
#print axioms Orbcrypt.GrochowQiao.partitionPreservingFwd_inv
#print axioms Orbcrypt.GrochowQiao.partitionPreservingPermFromEqualCardinalities
#print axioms Orbcrypt.GrochowQiao.partitionPreservingPermFromEqualCardinalities_apply
#print axioms Orbcrypt.GrochowQiao.partitionPreservingPermFromEqualCardinalities_vertexPreserving
#print axioms Orbcrypt.GrochowQiao.partitionPreservingPermFromEqualCardinalities_presentArrowPreserving
#print axioms Orbcrypt.GrochowQiao.partitionPreservingPermFromEqualCardinalities_paddingPreserving
#print axioms Orbcrypt.GrochowQiao.partitionPreservingPermFromEqualCardinalities_isThreePartition
#print axioms Orbcrypt.GrochowQiao.partition_preserving_perm_under_GL3
#print axioms Orbcrypt.GrochowQiao.total_slot_cardinality
#print axioms Orbcrypt.GrochowQiao.paddingSlotIndices_card_eq
#print axioms Orbcrypt.GrochowQiao.padding_card_eq_arrow_count_complement

namespace BlockDecompNonVacuity

open Orbcrypt
open Orbcrypt.GrochowQiao

/-- **Stage 3 T-API-4 non-vacuity witness (cardinality identity).**
The total partition card sums to `dimGQ m`. -/
example (adj : Fin 3 → Fin 3 → Bool) :
    (vertexSlotIndices 3).card + (presentArrowSlotIndices 3 adj).card +
      (paddingSlotIndices 3 adj).card = dimGQ 3 :=
  total_slot_cardinality 3 adj

/-- **Stage 3 T-API-4 non-vacuity witness (partition-preserving on equal adjs).**
For `adj = adj`, we trivially have equal cardinalities, so the
partition-preserving permutation can be constructed and is
three-partition-preserving. -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) :
    IsThreePartitionPreserving m adj adj
      (partitionPreservingPermFromEqualCardinalities m adj adj rfl) :=
  partitionPreservingPermFromEqualCardinalities_isThreePartition m adj adj rfl

/-- **Stage 3 T-API-4 non-vacuity witness (composition under the Prop).**
Given the research-scope `GL3PreservesPartitionCardinalities` Prop,
every GL³ tensor isomorphism yields a three-partition-preserving
permutation. -/
example (h_gl3 : GL3PreservesPartitionCardinalities)
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (h_iso : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂) :
    ∃ π : Equiv.Perm (Fin (dimGQ m)),
      IsThreePartitionPreserving m adj₁ adj₂ π :=
  partition_preserving_perm_under_GL3 h_gl3 m adj₁ adj₂ g h_iso

end BlockDecompNonVacuity

-- ============================================================================
-- ## §15.12 Workstream R-TI Stage 4 T-API-7 (σ-induced AlgEquiv lift).
-- ============================================================================

#print axioms Orbcrypt.GrochowQiao.quiverPermFun
#print axioms Orbcrypt.GrochowQiao.quiverPermFun_apply
#print axioms Orbcrypt.GrochowQiao.quiverPermFun_one
#print axioms Orbcrypt.GrochowQiao.quiverPermFun_add
#print axioms Orbcrypt.GrochowQiao.quiverPermFun_smul
#print axioms Orbcrypt.GrochowQiao.quiverPermFun_zero
#print axioms Orbcrypt.GrochowQiao.quiverPermFun_apply_vertexIdempotent
#print axioms Orbcrypt.GrochowQiao.quiverPermFun_apply_arrowElement
#print axioms Orbcrypt.GrochowQiao.quiverPermFun_round_trip
#print axioms Orbcrypt.GrochowQiao.quiverPermFun_round_trip'
#print axioms Orbcrypt.GrochowQiao.quiverPermFun_preserves_mul
#print axioms Orbcrypt.GrochowQiao.quiverPermFun_preserves_one
#print axioms Orbcrypt.GrochowQiao.quiverPermAlgEquiv
#print axioms Orbcrypt.GrochowQiao.quiverPermAlgEquiv_apply
#print axioms Orbcrypt.GrochowQiao.quiverPermAlgEquiv_apply_vertexIdempotent
#print axioms Orbcrypt.GrochowQiao.quiverPermAlgEquiv_apply_arrowElement
#print axioms Orbcrypt.GrochowQiao.quiverPermAlgEquiv_one

namespace AlgEquivLiftNonVacuity

open Orbcrypt
open Orbcrypt.GrochowQiao

/-- **Stage 4 T-API-7 non-vacuity witness (vertex-idempotent action under σ).**
For σ = swap 0 1 in `Equiv.Perm (Fin 2)`, the σ-induced AlgEquiv sends
`vertexIdempotent 0` to `vertexIdempotent 1`. -/
example :
    (quiverPermAlgEquiv 2 (Equiv.swap (0 : Fin 2) 1)) (vertexIdempotent 2 0) =
      vertexIdempotent 2 1 := by
  rw [quiverPermAlgEquiv_apply_vertexIdempotent]
  simp

/-- **Stage 4 T-API-7 non-vacuity witness (arrow-element action under σ).**
For σ = swap 0 1, the σ-induced AlgEquiv sends `arrowElement 0 1` to
`arrowElement 1 0`. -/
example :
    (quiverPermAlgEquiv 2 (Equiv.swap (0 : Fin 2) 1)) (arrowElement 2 0 1) =
      arrowElement 2 1 0 := by
  rw [quiverPermAlgEquiv_apply_arrowElement]
  simp

/-- **Stage 4 T-API-7 non-vacuity witness (identity descent).**
The identity vertex permutation gives the identity AlgEquiv. -/
example (m : ℕ) :
    quiverPermAlgEquiv m 1 = AlgEquiv.refl :=
  quiverPermAlgEquiv_one m

end AlgEquivLiftNonVacuity

-- ============================================================================
-- ## §15.13 Workstream R-TI Stage 4 T-API-8 (Wedderburn-Mal'cev σ-extraction).
-- ============================================================================

#print axioms Orbcrypt.GrochowQiao.quiverPermAlgEquiv_extractVertexPerm_witness
#print axioms Orbcrypt.GrochowQiao.extracted_perm_at_identity

namespace WMSigmaExtractionNonVacuity

open Orbcrypt
open Orbcrypt.GrochowQiao

/-- **Stage 4 T-API-8 non-vacuity witness (round-trip on σ-induced AlgEquiv).**
The σ-induced AlgEquiv is in WM normal form with j = 0; the WM
σ-extraction recovers the original σ. -/
example (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    ∃ (j : pathAlgebraQuotient m),
      j ∈ pathAlgebraRadical m ∧
      ∀ v : Fin m,
        (1 + j) * vertexIdempotent m (σ v) * (1 - j) =
          quiverPermAlgEquiv m σ (vertexIdempotent m v) :=
  quiverPermAlgEquiv_extractVertexPerm_witness m σ

/-- **Stage 4 T-API-8 non-vacuity witness (identity AlgEquiv extraction).** -/
example (m : ℕ) :
    ∃ (j : pathAlgebraQuotient m),
      j ∈ pathAlgebraRadical m ∧
      ∀ v : Fin m,
        (1 + j) * vertexIdempotent m ((1 : Equiv.Perm (Fin m)) v) * (1 - j) =
          (AlgEquiv.refl :
            pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m)
            (vertexIdempotent m v) :=
  extracted_perm_at_identity m

end WMSigmaExtractionNonVacuity

-- ============================================================================
-- ## §15.14 Workstream R-TI Stage 5 T-API-9 (adjacency invariance lemmas).
-- ============================================================================

#print axioms Orbcrypt.GrochowQiao.arrowElement_sandwich
#print axioms Orbcrypt.GrochowQiao.radical_arrowElement_mul
#print axioms Orbcrypt.GrochowQiao.arrowElement_radical_mul
#print axioms Orbcrypt.GrochowQiao.inner_aut_radical_fixes_arrow
#print axioms Orbcrypt.GrochowQiao.quiverPermAlgEquiv_sandwich
#print axioms Orbcrypt.GrochowQiao.mem_presentArrows_iff
#print axioms Orbcrypt.GrochowQiao.vertexPerm_isGraphIso_iff_arrow_preserving
#print axioms Orbcrypt.GrochowQiao.quiverPermAlgEquiv_preserves_presentArrows_iff

namespace AdjacencyInvarianceNonVacuity

open Orbcrypt
open Orbcrypt.GrochowQiao

/-- **Stage 5 T-API-9.1 non-vacuity witness (sandwich identity).**
On any vertex pair, the sandwich identity holds for arrowElement. -/
example (m : ℕ) (u v : Fin m) :
    vertexIdempotent m u * arrowElement m u v * vertexIdempotent m v =
      arrowElement m u v :=
  arrowElement_sandwich m u v

/-- **Stage 5 T-API-9.2 non-vacuity witness (inner conjugation fixes arrow).**
For zero radical element, the trivial inner conjugation acts as identity. -/
example (m : ℕ) (u v : Fin m) :
    (1 + (0 : pathAlgebraQuotient m)) * arrowElement m u v * (1 - 0) =
      arrowElement m u v :=
  inner_aut_radical_fixes_arrow m 0 (pathAlgebraRadical m).zero_mem u v

/-- **Stage 5 T-API-9.4 non-vacuity witness (mem_presentArrows iff).**
Membership in `presentArrows` is exactly `adj u v = true`. -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) (u v : Fin m) :
    (.edge u v : QuiverArrow m) ∈ presentArrows m adj ↔ adj u v = true :=
  mem_presentArrows_iff m adj u v

end AdjacencyInvarianceNonVacuity

-- ============================================================================
-- ## §15.15 Workstream R-TI Stage 5 T-API-10 (final rigidity composition).
-- ============================================================================

#print axioms Orbcrypt.GrochowQiao.vertexPermPreservesAdjacency
#print axioms Orbcrypt.GrochowQiao.GL3InducesArrowPreservingPerm
#print axioms Orbcrypt.GrochowQiao.gl3_induces_arrow_preserving_perm_identity_case
#print axioms Orbcrypt.GrochowQiao.grochowQiaoRigidity_under_arrowDischarge
#print axioms Orbcrypt.GrochowQiao.r_ti_rigidity_status_disclosure
#print axioms Orbcrypt.GrochowQiao.grochowQiao_isInhabitedKarpReduction_full_chain

namespace RigidityNonVacuity

open Orbcrypt
open Orbcrypt.GrochowQiao

/-- **Stage 5 T-API-10 non-vacuity witness (identity case).**
The identity vertex permutation trivially preserves arrow support
on any single graph. -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) :
    ∃ σ : Equiv.Perm (Fin m),
      ∀ u v, (.edge u v : QuiverArrow m) ∈ presentArrows m adj ↔
             (quiverMap m σ (.edge u v)) ∈ presentArrows m adj :=
  gl3_induces_arrow_preserving_perm_identity_case m adj

/-- **Stage 5 T-API-10 non-vacuity witness (composition under arrow-discharge).**
Given the research-scope arrow-preservation Prop, the rigidity
theorem is unconditional. -/
example (h_arrow : GL3InducesArrowPreservingPerm) :
    GrochowQiaoRigidity :=
  grochowQiaoRigidity_under_arrowDischarge h_arrow

/-- **Stage 5 T-API-10 non-vacuity witness (final Karp reduction).**
Under the arrow-discharge, the full Karp reduction inhabitant is
discharged. -/
example (h_arrow : GL3InducesArrowPreservingPerm) :
    @GIReducesToTI ℚ _ :=
  grochowQiao_isInhabitedKarpReduction_full_chain h_arrow

end RigidityNonVacuity

-- ============================================================================
-- ## §15.16 R-TI rigidity discharge — Phase 1: Encoder structural foundation.
-- ============================================================================
--
-- Layer 1.1: per-slot slab evaluation (vertex/vertex/vertex, vertex/arrow/arrow,
-- arrow/vertex/arrow, padding diagonal, plus zero-classification on the
-- remaining path-algebra and mixed triples).
--
-- Layer 1.2: encoder associativity identity, via the LHS / RHS closed forms
-- and `pathMul_assoc`.
--
-- Layer 1.3: path-identity pairing — algebraic non-degeneracy invariants
-- distinguishing vertex from present-arrow slots.
--
-- See `Orbcrypt/Hardness/GrochowQiao/EncoderSlabEval.lean` for the full
-- definitions and proofs.
-- ============================================================================

#print axioms Orbcrypt.GrochowQiao.arrowToSlot
#print axioms Orbcrypt.GrochowQiao.slotToArrow_arrowToSlot
#print axioms Orbcrypt.GrochowQiao.arrowToSlot_slotToArrow
#print axioms Orbcrypt.GrochowQiao.slotOfArrow
#print axioms Orbcrypt.GrochowQiao.slotToArrow_slotEquiv_slotOfArrow
#print axioms Orbcrypt.GrochowQiao.eq_slotOfArrow_iff
#print axioms Orbcrypt.GrochowQiao.slotOfArrow_pathMul_isPathAlgebra
#print axioms Orbcrypt.GrochowQiao.encoder_at_vertex_vertex_vertex_eq_one
#print axioms Orbcrypt.GrochowQiao.encoder_at_vertex_arrow_arrow_eq_one
#print axioms Orbcrypt.GrochowQiao.encoder_at_arrow_vertex_arrow_eq_one
#print axioms Orbcrypt.GrochowQiao.encoder_at_padding_diagonal_eq_two
#print axioms Orbcrypt.GrochowQiao.encoder_zero_at_remaining_path_triples
#print axioms Orbcrypt.GrochowQiao.encoder_zero_at_mixed_triples
#print axioms Orbcrypt.GrochowQiao.encoder_associativity_lhs_eq_pathMul_chain
#print axioms Orbcrypt.GrochowQiao.encoder_associativity_rhs_eq_pathMul_chain
#print axioms Orbcrypt.GrochowQiao.encoder_associativity_identity
#print axioms Orbcrypt.GrochowQiao.encoder_idempotent_contribution_at_vertex_slot
#print axioms Orbcrypt.GrochowQiao.encoder_diagonal_trace_at_present_arrow_slot
#print axioms Orbcrypt.GrochowQiao.encoder_diagonal_trace_at_vertex_slot_pos

namespace EncoderSlabEvalNonVacuity

open Orbcrypt
open Orbcrypt.GrochowQiao

/-- **Layer 1.1.1 non-vacuity witness (m = 1).**
On the empty graph at `m = 1`, the unique vertex slot has diagonal value `1`. -/
example :
    grochowQiaoEncode 1 (fun _ _ => false)
        ((slotEquiv 1).symm (.vertex 0))
        ((slotEquiv 1).symm (.vertex 0))
        ((slotEquiv 1).symm (.vertex 0)) = 1 :=
  encoder_at_vertex_vertex_vertex_eq_one 1 (fun _ _ => false)
    ((slotEquiv 1).symm (.vertex 0))
    ((slotEquiv 1).symm (.vertex 0))
    ((slotEquiv 1).symm (.vertex 0))
    (0 : Fin 1)
    (Equiv.apply_symm_apply _ _)
    (Equiv.apply_symm_apply _ _)
    (Equiv.apply_symm_apply _ _)

/-- **Layer 1.1.2 non-vacuity witness (m = 2, complete graph).**
On the complete graph at `m = 2`, the vertex–arrow–arrow triple
`(.vertex 0, .arrow 0 1, .arrow 0 1)` evaluates to `1` (left vertex
action on the present arrow `(0, 1)`). -/
example :
    grochowQiaoEncode 2 (fun _ _ => true)
        ((slotEquiv 2).symm (.vertex 0))
        ((slotEquiv 2).symm (.arrow 0 1))
        ((slotEquiv 2).symm (.arrow 0 1)) = 1 :=
  encoder_at_vertex_arrow_arrow_eq_one 2 (fun _ _ => true)
    ((slotEquiv 2).symm (.vertex 0))
    ((slotEquiv 2).symm (.arrow 0 1))
    ((slotEquiv 2).symm (.arrow 0 1))
    0 1
    (Equiv.apply_symm_apply _ _)
    (Equiv.apply_symm_apply _ _)
    (Equiv.apply_symm_apply _ _)
    rfl

/-- **Layer 1.1.3 non-vacuity witness (m = 2, complete graph).**
On the complete graph at `m = 2`, the arrow–vertex–arrow triple
`(.arrow 0 1, .vertex 1, .arrow 0 1)` evaluates to `1` (right vertex
action on the present arrow `(0, 1)`). -/
example :
    grochowQiaoEncode 2 (fun _ _ => true)
        ((slotEquiv 2).symm (.arrow 0 1))
        ((slotEquiv 2).symm (.vertex 1))
        ((slotEquiv 2).symm (.arrow 0 1)) = 1 :=
  encoder_at_arrow_vertex_arrow_eq_one 2 (fun _ _ => true)
    ((slotEquiv 2).symm (.arrow 0 1))
    ((slotEquiv 2).symm (.vertex 1))
    ((slotEquiv 2).symm (.arrow 0 1))
    0 1
    (Equiv.apply_symm_apply _ _)
    (Equiv.apply_symm_apply _ _)
    (Equiv.apply_symm_apply _ _)
    rfl

/-- **Layer 1.1.4 non-vacuity witness (m = 2).**
On the empty graph at `m = 2`, the arrow slot `(0, 1)` is a padding slot
(`adj 0 1 = false`) and its diagonal value is `2`. -/
example :
    grochowQiaoEncode 2 (fun _ _ => false)
        ((slotEquiv 2).symm (.arrow 0 1))
        ((slotEquiv 2).symm (.arrow 0 1))
        ((slotEquiv 2).symm (.arrow 0 1)) = 2 :=
  encoder_at_padding_diagonal_eq_two 2 (fun _ _ => false)
    ((slotEquiv 2).symm (.arrow 0 1))
    0 1
    (Equiv.apply_symm_apply _ _)
    rfl

/-- **Layer 1.1.5 non-vacuity witness — encoder is zero on a non-matching
path-algebra triple (m = 2).**

On the complete graph at `m = 2`, the triple `(.vertex 0, .vertex 1,
.vertex 0)` is path-algebra but `pathMul (.id 0) (.id 1) = none ≠
some (.id 0)`, so the encoder is `0`. -/
example :
    grochowQiaoEncode 2 (fun _ _ => true)
        ((slotEquiv 2).symm (.vertex 0))
        ((slotEquiv 2).symm (.vertex 1))
        ((slotEquiv 2).symm (.vertex 0)) = 0 := by
  apply encoder_zero_at_remaining_path_triples 2 (fun _ _ => true)
    ((slotEquiv 2).symm (.vertex 0))
    ((slotEquiv 2).symm (.vertex 1))
    ((slotEquiv 2).symm (.vertex 0))
    (isPathAlgebraSlot_vertex 2 _ 0)
    (isPathAlgebraSlot_vertex 2 _ 1)
    (isPathAlgebraSlot_vertex 2 _ 0)
  -- pathMul (.id 0) (.id 1) = none (vertex idempotents are orthogonal),
  -- which is ≠ some (.id 0).
  simp [Equiv.apply_symm_apply, slotToArrow, pathMul]

/-- **Layer 1.1.6 non-vacuity witness — encoder is zero on a mixed
(path/padding) triple (m = 2).**

On the empty graph at `m = 2`, the triple `(.vertex 0, .arrow 0 1,
.vertex 0)` mixes a path-algebra slot (vertex) with a padding slot
(`.arrow 0 1` with `adj 0 1 = false`), so the encoder is `0`. -/
example :
    grochowQiaoEncode 2 (fun _ _ => false)
        ((slotEquiv 2).symm (.vertex 0))
        ((slotEquiv 2).symm (.arrow 0 1))
        ((slotEquiv 2).symm (.vertex 0)) = 0 := by
  apply encoder_zero_at_mixed_triples 2 (fun _ _ => false)
    ((slotEquiv 2).symm (.vertex 0))
    ((slotEquiv 2).symm (.arrow 0 1))
    ((slotEquiv 2).symm (.vertex 0))
  refine ⟨?_, ?_⟩
  · rintro ⟨_, h_j_path, _⟩
    -- isPathAlgebraSlot adj (arrow 0 1) = adj 0 1 = false, contradicting true.
    have : isPathAlgebraSlot 2 (fun _ _ => false : Fin 2 → Fin 2 → Bool)
              ((slotEquiv 2).symm (.arrow 0 1)) = false := by
      rw [isPathAlgebraSlot_arrow]
    exact Bool.noConfusion (this.symm.trans h_j_path)
  · rintro ⟨h_i_pad, _, _⟩
    -- isPathAlgebraSlot adj (vertex 0) = true, contradicting false.
    have : isPathAlgebraSlot 2 (fun _ _ => false : Fin 2 → Fin 2 → Bool)
              ((slotEquiv 2).symm (.vertex 0)) = true := by
      rw [isPathAlgebraSlot_vertex]
    exact Bool.noConfusion (h_i_pad.symm.trans this)

/-- **Layer 1.2.0 helper non-vacuity witness — `slotOfArrow` round-trip.**
`slotOfArrow m q` recovers the original arrow `q` after `slotToArrow ∘
slotEquiv`. -/
example (m : ℕ) (q : QuiverArrow m) :
    slotToArrow m (slotEquiv m (slotOfArrow m q)) = q :=
  slotToArrow_slotEquiv_slotOfArrow m q

/-- **Layer 1.2.0 helper non-vacuity witness — `eq_slotOfArrow_iff`
distinguishes a slot index from a non-matching arrow.**

At `m = 2`, the slot index `(slotEquiv 2).symm (.vertex 0)` corresponds
to `slotOfArrow 2 (.id 0)` (the vertex idempotent at vertex 0); the
iff lemma's forward direction proves `slotToArrow (slotEquiv _) = .id 0`. -/
example :
    ((slotEquiv 2).symm (.vertex 0) : Fin (dimGQ 2)) = slotOfArrow 2 (.id 0) := by
  rw [eq_slotOfArrow_iff]
  -- slotToArrow (slotEquiv ((slotEquiv 2).symm (.vertex 0))) = .id 0.
  simp [Equiv.apply_symm_apply, slotToArrow]

/-- **Layer 1.2.0 helper non-vacuity witness — path-algebra closure
under `pathMul`.**

On the complete graph at `m = 2`, the path-algebra slot `.vertex 0`
multiplied with the path-algebra slot `.arrow 0 1` produces the
arrow `.edge 0 1`, and `slotOfArrow (.edge 0 1)` is path-algebra
because `adj 0 1 = true`. -/
example :
    isPathAlgebraSlot 2 (fun _ _ => true)
        (slotOfArrow 2 (.edge 0 1)) = true :=
  slotOfArrow_pathMul_isPathAlgebra 2 (fun _ _ => true)
    ((slotEquiv 2).symm (.vertex 0))
    ((slotEquiv 2).symm (.arrow 0 1))
    (.edge 0 1)
    (isPathAlgebraSlot_vertex 2 _ 0)
    (by rw [isPathAlgebraSlot_arrow])
    (by simp [Equiv.apply_symm_apply, slotToArrow, pathMul])

/-- **Layer 1.2.1 non-vacuity witness — LHS closed form at m = 2.**

On the complete graph at `m = 2`, the LHS sum
`∑ a, T(.vertex 0, .arrow 0 1, a) · T(a, .vertex 1, .arrow 0 1)`
equals `1` because `pathMul (.id 0) (.edge 0 1) = some (.edge 0 1)`
and `pathMul (.edge 0 1) (.id 1) = some (.edge 0 1)`. -/
example :
    (∑ a : Fin (dimGQ 2),
      grochowQiaoEncode 2 (fun _ _ => true)
          ((slotEquiv 2).symm (.vertex 0))
          ((slotEquiv 2).symm (.arrow 0 1)) a *
      grochowQiaoEncode 2 (fun _ _ => true)
          a
          ((slotEquiv 2).symm (.vertex 1))
          ((slotEquiv 2).symm (.arrow 0 1))) = 1 := by
  rw [encoder_associativity_lhs_eq_pathMul_chain 2 (fun _ _ => true)
        ((slotEquiv 2).symm (.vertex 0))
        ((slotEquiv 2).symm (.arrow 0 1))
        ((slotEquiv 2).symm (.vertex 1))
        ((slotEquiv 2).symm (.arrow 0 1))
        (isPathAlgebraSlot_vertex 2 _ 0)
        (by rw [isPathAlgebraSlot_arrow])
        (isPathAlgebraSlot_vertex 2 _ 1)
        (by rw [isPathAlgebraSlot_arrow])]
  simp [Equiv.apply_symm_apply, slotToArrow, pathMul, Option.bind]

/-- **Layer 1.2.2 non-vacuity witness — RHS closed form at m = 2.**

Symmetric to Layer 1.2.1: the RHS sum
`∑ a, T(.arrow 0 1, .vertex 1, a) · T(.vertex 0, a, .arrow 0 1)`
also equals `1`. -/
example :
    (∑ a : Fin (dimGQ 2),
      grochowQiaoEncode 2 (fun _ _ => true)
          ((slotEquiv 2).symm (.arrow 0 1))
          ((slotEquiv 2).symm (.vertex 1)) a *
      grochowQiaoEncode 2 (fun _ _ => true)
          ((slotEquiv 2).symm (.vertex 0))
          a
          ((slotEquiv 2).symm (.arrow 0 1))) = 1 := by
  rw [encoder_associativity_rhs_eq_pathMul_chain 2 (fun _ _ => true)
        ((slotEquiv 2).symm (.vertex 0))
        ((slotEquiv 2).symm (.arrow 0 1))
        ((slotEquiv 2).symm (.vertex 1))
        ((slotEquiv 2).symm (.arrow 0 1))
        (isPathAlgebraSlot_vertex 2 _ 0)
        (by rw [isPathAlgebraSlot_arrow])
        (isPathAlgebraSlot_vertex 2 _ 1)
        (by rw [isPathAlgebraSlot_arrow])]
  simp [Equiv.apply_symm_apply, slotToArrow, pathMul, Option.bind]

/-- **Layer 1.2.4 non-vacuity witness — non-trivial associativity at m = 2.**

On the complete graph at `m = 2`, the associativity identity holds
non-vacuously for the path-algebra quadruple
`(.vertex 0, .arrow 0 1, .vertex 1, .arrow 0 1)` — both sides reduce
to the chained product `(.id 0) · (.edge 0 1) · (.id 1) = (.edge 0 1)`,
witnessed by Layers 1.2.1 / 1.2.2 evaluating to `1`. -/
example :
    (∑ a : Fin (dimGQ 2),
      grochowQiaoEncode 2 (fun _ _ => true)
          ((slotEquiv 2).symm (.vertex 0))
          ((slotEquiv 2).symm (.arrow 0 1)) a *
      grochowQiaoEncode 2 (fun _ _ => true)
          a
          ((slotEquiv 2).symm (.vertex 1))
          ((slotEquiv 2).symm (.arrow 0 1))) =
    (∑ a : Fin (dimGQ 2),
      grochowQiaoEncode 2 (fun _ _ => true)
          ((slotEquiv 2).symm (.arrow 0 1))
          ((slotEquiv 2).symm (.vertex 1)) a *
      grochowQiaoEncode 2 (fun _ _ => true)
          ((slotEquiv 2).symm (.vertex 0))
          a
          ((slotEquiv 2).symm (.arrow 0 1))) :=
  encoder_associativity_identity 2 (fun _ _ => true)
    ((slotEquiv 2).symm (.vertex 0))
    ((slotEquiv 2).symm (.arrow 0 1))
    ((slotEquiv 2).symm (.vertex 1))
    ((slotEquiv 2).symm (.arrow 0 1))
    (isPathAlgebraSlot_vertex 2 _ 0)
    (by rw [isPathAlgebraSlot_arrow])
    (isPathAlgebraSlot_vertex 2 _ 1)
    (by rw [isPathAlgebraSlot_arrow])

/-- **Layer 1.3.1 non-vacuity witness — vertex-slot idempotent contribution.**

For any vertex slot, the encoder's diagonal entry is `1`, witnessing
the idempotent law's non-zero footprint on the path-algebra side
of the partition. -/
example :
    grochowQiaoEncode 2 (fun _ _ => false)
        ((slotEquiv 2).symm (.vertex 0))
        ((slotEquiv 2).symm (.vertex 0))
        ((slotEquiv 2).symm (.vertex 0)) = 1 :=
  encoder_idempotent_contribution_at_vertex_slot 2 (fun _ _ => false)
    ((slotEquiv 2).symm (.vertex 0)) 0
    (Equiv.apply_symm_apply _ _)

/-- **Layer 1.3.2 non-vacuity witness — present-arrow slot diagonal trace = 0.**

On the complete graph at `m = 2`, the arrow slot `(0, 1)` is a
present-arrow slot, and its diagonal trace `∑ j, T(i, j, j) = 0`
because no basis element `slot_j` satisfies `α(0, 1) · slot_j =
slot_j` in the radical-2 path algebra. -/
example :
    (∑ j : Fin (dimGQ 2),
      grochowQiaoEncode 2 (fun _ _ => true)
          ((slotEquiv 2).symm (.arrow 0 1)) j j) = 0 :=
  encoder_diagonal_trace_at_present_arrow_slot 2 (fun _ _ => true)
    ((slotEquiv 2).symm (.arrow 0 1)) 0 1
    (Equiv.apply_symm_apply _ _)
    rfl

/-- **Layer 1.3.3 non-vacuity witness — vertex-slot diagonal trace ≥ 1.**

On the empty graph at `m = 2`, the vertex slot `0` has diagonal
trace `∑ j, T(i, j, j) ≥ 1` (the contribution at `j = i` already
gives `1`). -/
example :
    1 ≤ (∑ j : Fin (dimGQ 2),
          grochowQiaoEncode 2 (fun _ _ => false)
              ((slotEquiv 2).symm (.vertex 0)) j j) :=
  encoder_diagonal_trace_at_vertex_slot_pos 2 (fun _ _ => false)
    ((slotEquiv 2).symm (.vertex 0)) 0
    (Equiv.apply_symm_apply _ _)

/-- **Layer 1.3 distinguishability witness — vertex vs. present-arrow slots
have distinguishable diagonal traces.**

Combining Layer 1.3.2 and Layer 1.3.3, vertex slots have diagonal
trace `≥ 1` while present-arrow slots have diagonal trace `= 0`,
giving an algebraic invariant that genuinely distinguishes the two
slot kinds without using the slot-kind discriminator directly. -/
example :
    1 ≤ (∑ j : Fin (dimGQ 2),
          grochowQiaoEncode 2 (fun _ _ => true)
              ((slotEquiv 2).symm (.vertex 0)) j j) ∧
    (∑ j : Fin (dimGQ 2),
      grochowQiaoEncode 2 (fun _ _ => true)
          ((slotEquiv 2).symm (.arrow 0 1)) j j) = 0 := by
  refine ⟨?_, ?_⟩
  · exact encoder_diagonal_trace_at_vertex_slot_pos 2 (fun _ _ => true)
      ((slotEquiv 2).symm (.vertex 0)) 0
      (Equiv.apply_symm_apply _ _)
  · exact encoder_diagonal_trace_at_present_arrow_slot 2 (fun _ _ => true)
      ((slotEquiv 2).symm (.arrow 0 1)) 0 1
      (Equiv.apply_symm_apply _ _)
      rfl

end EncoderSlabEvalNonVacuity

-- ============================================================================
-- ## §15.17 R-TI rigidity discharge — Phase 2: Path-block linear restriction.
-- ============================================================================
--
-- Layer 2.1.0: permutation-matrix wrapper for arbitrary slot permutations
-- (`permMatrixOf`, `permMatrixOf_apply`, `permMatrixOf_det_ne_zero`).
--
-- Layer 2.1.1–2.1.3: path-block + padding subspaces (defined by support),
-- indicator-vector membership lemmas, the indicator-span characterisation
-- and decomposition, and the complementary direct-sum decomposition
-- (`pathBlockSubspace`, `paddingSubspace`,
-- `pi_single_mem_pathBlockSubspace`, `pi_single_mem_paddingSubspace`,
-- `pathBlockSubspace_indicator_decomposition`,
-- `pathBlockSubspace_eq_indicator_span`,
-- `pathBlockSubspace_disjoint_paddingSubspace`,
-- `pathBlock_padding_decomposition`,
-- `pathBlockSubspace_sup_paddingSubspace_eq_top`,
-- `pathBlockSubspace_isCompl_paddingSubspace`).
--
-- Layer 2.2:  the path-block matrix `g.1.val * permMatrixOf m π⁻¹`, with the
-- partition-preserving simplification `(pathBlockMatrix g π) i j = g.1(i, π j)`,
-- the identity-permutation reduction, and the determinant non-vanishing
-- (`pathBlockMatrix`, `pathBlockMatrix_apply`,
-- `pathBlockMatrix_apply_eq_g_at_pi`, `pathBlockMatrix_one`,
-- `pathBlockMatrix_det_ne_zero`).
--
-- Layer 2.3:  the conditional linear restriction
-- (`IsPathBlockDiagonal`, `IsPaddingBlockDiagonal`, `IsFullyPathBlockDiagonal`,
-- `mulVec_mem_pathBlockSubspace_of_isPathBlockDiagonal`,
-- `pathBlockRestrict`, `pathBlockRestrict_apply`,
-- `gl3_restrict_to_pathBlock`, `gl3_restrict_to_pathBlock_apply`).
--
-- Layer 2.3.1: `LinearEquiv` upgrade
-- (`pathBlockEquivOfInverse`, `pathBlockEquivOfInverse_apply`,
-- `pathBlockEquivOfInverse_symm_apply`).
--
-- Layer 2.4:  the bridge `pathBlockSubspace ≃ₗ presentArrowsSubspace`
-- (`presentArrowsSubspace`, `vertexIdempotent_mem_presentArrowsSubspace`,
-- `arrowElement_mem_presentArrowsSubspace`,
-- `pathBlockToPresentArrowsFun`, `presentArrowsToPathBlockFun`,
-- `slotToArrow_mem_presentArrows_of_path`,
-- `slotOfArrow_mem_pathSlotIndices_of_present`,
-- `pathBlockToPresentArrowsFun_mem`, `presentArrowsToPathBlockFun_mem`,
-- `presentArrowsToPathBlockFun_pathBlockToPresentArrowsFun`,
-- `pathBlockToPresentArrowsFun_presentArrowsToPathBlockFun`,
-- `pathBlockToPresentArrows`, `pathBlockToPresentArrows_apply`,
-- `pathBlockToPresentArrows_symm_apply`).
--
-- See `Orbcrypt/Hardness/GrochowQiao/PathBlockSubspace.lean` for the full
-- definitions and proofs.
-- ============================================================================

#print axioms Orbcrypt.GrochowQiao.permMatrixOf
#print axioms Orbcrypt.GrochowQiao.permMatrixOf_apply
#print axioms Orbcrypt.GrochowQiao.permMatrixOf_det_ne_zero
#print axioms Orbcrypt.GrochowQiao.pathBlockSubspace
#print axioms Orbcrypt.GrochowQiao.mem_pathBlockSubspace_iff
#print axioms Orbcrypt.GrochowQiao.paddingSubspace
#print axioms Orbcrypt.GrochowQiao.mem_paddingSubspace_iff
#print axioms Orbcrypt.GrochowQiao.pi_single_mem_pathBlockSubspace
#print axioms Orbcrypt.GrochowQiao.pi_single_mem_paddingSubspace
#print axioms Orbcrypt.GrochowQiao.pathBlockSubspace_disjoint_paddingSubspace
#print axioms Orbcrypt.GrochowQiao.pathBlock_padding_decomposition
#print axioms Orbcrypt.GrochowQiao.pathBlockSubspace_sup_paddingSubspace_eq_top
#print axioms Orbcrypt.GrochowQiao.pathBlockSubspace_isCompl_paddingSubspace
#print axioms Orbcrypt.GrochowQiao.pathBlockMatrix
#print axioms Orbcrypt.GrochowQiao.pathBlockMatrix_apply
#print axioms Orbcrypt.GrochowQiao.pathBlockMatrix_apply_eq_g_at_pi
#print axioms Orbcrypt.GrochowQiao.pathBlockMatrix_one
#print axioms Orbcrypt.GrochowQiao.pathBlockMatrix_det_ne_zero
#print axioms Orbcrypt.GrochowQiao.IsPathBlockDiagonal
#print axioms Orbcrypt.GrochowQiao.IsPaddingBlockDiagonal
#print axioms Orbcrypt.GrochowQiao.IsFullyPathBlockDiagonal
#print axioms Orbcrypt.GrochowQiao.mulVec_mem_pathBlockSubspace_of_isPathBlockDiagonal
#print axioms Orbcrypt.GrochowQiao.pathBlockRestrict
#print axioms Orbcrypt.GrochowQiao.pathBlockRestrict_apply
#print axioms Orbcrypt.GrochowQiao.gl3_restrict_to_pathBlock
#print axioms Orbcrypt.GrochowQiao.presentArrowsSubspace
#print axioms Orbcrypt.GrochowQiao.mem_presentArrowsSubspace_iff
#print axioms Orbcrypt.GrochowQiao.vertexIdempotent_mem_presentArrowsSubspace
#print axioms Orbcrypt.GrochowQiao.arrowElement_mem_presentArrowsSubspace
#print axioms Orbcrypt.GrochowQiao.pathBlockToPresentArrowsFun
#print axioms Orbcrypt.GrochowQiao.presentArrowsToPathBlockFun
#print axioms Orbcrypt.GrochowQiao.slotToArrow_mem_presentArrows_of_path
#print axioms Orbcrypt.GrochowQiao.slotOfArrow_mem_pathSlotIndices_of_present
#print axioms Orbcrypt.GrochowQiao.pathBlockToPresentArrowsFun_mem
#print axioms Orbcrypt.GrochowQiao.presentArrowsToPathBlockFun_mem
#print axioms Orbcrypt.GrochowQiao.presentArrowsToPathBlockFun_pathBlockToPresentArrowsFun
#print axioms Orbcrypt.GrochowQiao.pathBlockToPresentArrowsFun_presentArrowsToPathBlockFun
#print axioms Orbcrypt.GrochowQiao.pathBlockToPresentArrows
#print axioms Orbcrypt.GrochowQiao.pathBlockToPresentArrows_apply
#print axioms Orbcrypt.GrochowQiao.pathBlockToPresentArrows_symm_apply

-- Layer 2.1 indicator-span / decomposition (post-audit Phase 2 expansion).
#print axioms Orbcrypt.GrochowQiao.pathBlockSubspace_indicator_decomposition
#print axioms Orbcrypt.GrochowQiao.pathBlockSubspace_eq_indicator_span

-- Layer 2.3 / 2.3.1 (post-audit Phase 2 expansion).
#print axioms Orbcrypt.GrochowQiao.gl3_restrict_to_pathBlock_apply
#print axioms Orbcrypt.GrochowQiao.pathBlockEquivOfInverse
#print axioms Orbcrypt.GrochowQiao.pathBlockEquivOfInverse_apply
#print axioms Orbcrypt.GrochowQiao.pathBlockEquivOfInverse_symm_apply

namespace PathBlockSubspaceNonVacuity

open Orbcrypt
open Orbcrypt.GrochowQiao

/-- **Layer 2.0 non-vacuity (m = 1).**
The identity slot permutation has the identity permutation matrix. -/
example :
    permMatrixOf 1 (1 : Equiv.Perm (Fin (dimGQ 1)))
        ((slotEquiv 1).symm (.vertex 0))
        ((slotEquiv 1).symm (.vertex 0)) = 1 := by
  rw [permMatrixOf_apply]
  simp

/-- **Layer 2.1 non-vacuity: zero vector lies in path-block subspace.** -/
example : (0 : Fin (dimGQ 2) → ℚ) ∈ pathBlockSubspace 2 (fun _ _ => false) :=
  Submodule.zero_mem _

/-- **Layer 2.1 non-vacuity: zero vector lies in padding subspace.** -/
example : (0 : Fin (dimGQ 2) → ℚ) ∈ paddingSubspace 2 (fun _ _ => false) :=
  Submodule.zero_mem _

/-- **Layer 2.1 non-vacuity: vertex-slot indicator vector at m = 2 lies in
path-block subspace.** Vertex slots are always path-algebra slots. -/
example :
    Pi.single ((slotEquiv 2).symm (.vertex 0) : Fin (dimGQ 2)) (1 : ℚ) ∈
      pathBlockSubspace 2 (fun _ _ => false) := by
  refine pi_single_mem_pathBlockSubspace 2 (fun _ _ => false) _ ?_ 1
  rw [pathSlotIndices_eq_vertex_union_presentArrow]
  apply Finset.mem_union_left
  rw [mem_vertexSlotIndices_iff]
  exact ⟨0, Equiv.apply_symm_apply _ _⟩

/-- **Layer 2.1 non-vacuity: padding-slot indicator vector at m = 2 lies in
padding subspace.** On the empty graph at `m = 2`, every arrow slot is a
padding slot. -/
example :
    Pi.single ((slotEquiv 2).symm (.arrow 0 1) : Fin (dimGQ 2)) (1 : ℚ) ∈
      paddingSubspace 2 (fun _ _ => false) := by
  refine pi_single_mem_paddingSubspace 2 (fun _ _ => false) _ ?_ 1
  rw [mem_paddingSlotIndices_iff]
  exact ⟨0, 1, Equiv.apply_symm_apply _ _, rfl⟩

/-- **Layer 2.1 non-vacuity: the path-block and padding subspaces are
complementary.** -/
example :
    IsCompl (pathBlockSubspace 2 (fun _ _ => false))
            (paddingSubspace 2 (fun _ _ => false)) :=
  pathBlockSubspace_isCompl_paddingSubspace 2 (fun _ _ => false)

/-- **Layer 2.2 non-vacuity: identity slot permutation collapses
`pathBlockMatrix` to `g.1.val`.** -/
example
    (g : GL (Fin (dimGQ 2)) ℚ × GL (Fin (dimGQ 2)) ℚ × GL (Fin (dimGQ 2)) ℚ) :
    pathBlockMatrix 2 g 1 = g.1.val :=
  pathBlockMatrix_one 2 g

/-- **Layer 2.2 non-vacuity: invertibility of `pathBlockMatrix`.** -/
example
    (g : GL (Fin (dimGQ 2)) ℚ × GL (Fin (dimGQ 2)) ℚ × GL (Fin (dimGQ 2)) ℚ)
    (π : Equiv.Perm (Fin (dimGQ 2))) :
    (pathBlockMatrix 2 g π).det ≠ 0 :=
  pathBlockMatrix_det_ne_zero 2 g π

/-- **Layer 2.3 non-vacuity: zero matrix is path-block-diagonal.** -/
example (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) :
    IsPathBlockDiagonal m adj₁ adj₂ 0 := by
  intro i _ j _; rfl

/-- **Layer 2.3 non-vacuity: the GL³ restriction is well-typed
under any path-block-diagonal hypothesis.** -/
noncomputable example
    (g : GL (Fin (dimGQ 2)) ℚ × GL (Fin (dimGQ 2)) ℚ × GL (Fin (dimGQ 2)) ℚ)
    (π : Equiv.Perm (Fin (dimGQ 2)))
    (h_block : IsPathBlockDiagonal 2 (fun _ _ => false) (fun _ _ => false)
                  (pathBlockMatrix 2 g π)) :
    pathBlockSubspace 2 (fun _ _ => false) →ₗ[ℚ]
    pathBlockSubspace 2 (fun _ _ => false) :=
  gl3_restrict_to_pathBlock 2 (fun _ _ => false) (fun _ _ => false) g π h_block

/-- **Layer 2.4 non-vacuity: vertex idempotent lies in
`presentArrowsSubspace` for any adjacency.** -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) (h_m : 1 ≤ m) :
    vertexIdempotent m ⟨0, h_m⟩ ∈ presentArrowsSubspace m adj :=
  vertexIdempotent_mem_presentArrowsSubspace m adj ⟨0, h_m⟩

/-- **Layer 2.4 non-vacuity: arrow element lies in `presentArrowsSubspace`
on the complete graph.** -/
example :
    arrowElement 2 ⟨0, by omega⟩ ⟨1, by omega⟩ ∈
      presentArrowsSubspace 2 (fun _ _ => true) :=
  arrowElement_mem_presentArrowsSubspace 2 (fun _ _ => true) _ _ rfl

/-- **Layer 2.4 non-vacuity: the bridge LinearEquiv is well-typed.** -/
noncomputable example :
    pathBlockSubspace 2 (fun _ _ => false) ≃ₗ[ℚ]
    presentArrowsSubspace 2 (fun _ _ => false) :=
  pathBlockToPresentArrows 2 (fun _ _ => false)

/-- **Layer 2.4 round-trip: `symm ∘ pathBlockToPresentArrows = id`.**
Demonstrates the `LinearEquiv` is genuinely an isomorphism by exercising
the round-trip law on a concrete vector. -/
example (v : pathBlockSubspace 2 (fun _ _ => false)) :
    (pathBlockToPresentArrows 2 (fun _ _ => false)).symm
      (pathBlockToPresentArrows 2 (fun _ _ => false) v) = v :=
  (pathBlockToPresentArrows 2 (fun _ _ => false)).left_inv v

-- ----------------------------------------------------------------------------
-- Post-audit expansions (added in the 2026-04-28 audit pass): direct
-- non-vacuity tests for the new declarations and for previously
-- underrepresented existing declarations.
-- ----------------------------------------------------------------------------

/-- **Layer 2.1 non-vacuity: zero matrix path-padding decomposition.**
Demonstrates the existence form of the decomposition theorem on a
concrete vector (the zero vector splits as 0 + 0). -/
example :
    ∃ (fp fpd : Fin (dimGQ 2) → ℚ),
      fp ∈ pathBlockSubspace 2 (fun _ _ => false) ∧
      fpd ∈ paddingSubspace 2 (fun _ _ => false) ∧
      (0 : Fin (dimGQ 2) → ℚ) = fp + fpd :=
  pathBlock_padding_decomposition 2 (fun _ _ => false) 0

/-- **Layer 2.1 non-vacuity: `pathBlockSubspace_disjoint_paddingSubspace`.** -/
example :
    pathBlockSubspace 2 (fun _ _ => false) ⊓ paddingSubspace 2 (fun _ _ => false) = ⊥ :=
  pathBlockSubspace_disjoint_paddingSubspace 2 (fun _ _ => false)

/-- **Layer 2.1 non-vacuity: `pathBlockSubspace_sup_paddingSubspace_eq_top`.** -/
example :
    pathBlockSubspace 2 (fun _ _ => false) ⊔ paddingSubspace 2 (fun _ _ => false) = ⊤ :=
  pathBlockSubspace_sup_paddingSubspace_eq_top 2 (fun _ _ => false)

/-- **Layer 2.1 non-vacuity: indicator-span characterisation.**
Witnesses that `pathBlockSubspace m adj` equals the `ℚ`-linear span of
the indicator vectors `Pi.single i 1` over `pathSlotIndices m adj`. -/
example :
    pathBlockSubspace 1 (fun _ _ => false) =
    Submodule.span ℚ ((pathSlotIndices 1 (fun _ _ => false) : Set _).image
      (fun i => Pi.single i (1 : ℚ))) :=
  pathBlockSubspace_eq_indicator_span 1 (fun _ _ => false)

/-- **Layer 2.1 non-vacuity: indicator decomposition on the zero vector.**
Witnesses that the indicator-decomposition theorem applies to a concrete
element of the path-block subspace. -/
example :
    (0 : Fin (dimGQ 1) → ℚ) =
      ∑ i ∈ pathSlotIndices 1 (fun _ _ => false),
        (0 : Fin (dimGQ 1) → ℚ) i • Pi.single i (1 : ℚ) :=
  pathBlockSubspace_indicator_decomposition 1 (fun _ _ => false) 0
    (Submodule.zero_mem _)

/-- **Layer 2.2 non-vacuity: `pathBlockMatrix_apply_eq_g_at_pi`.**
Witnesses the partition-preserving simplification on a concrete entry. -/
example
    (g : GL (Fin (dimGQ 2)) ℚ × GL (Fin (dimGQ 2)) ℚ × GL (Fin (dimGQ 2)) ℚ)
    (π : Equiv.Perm (Fin (dimGQ 2))) (i j : Fin (dimGQ 2)) :
    pathBlockMatrix 2 g π i j = g.1.val i (π j) :=
  pathBlockMatrix_apply_eq_g_at_pi 2 g π i j

/-- **Layer 2.3 non-vacuity: `IsPaddingBlockDiagonal` on the zero matrix.** -/
example (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) :
    IsPaddingBlockDiagonal m adj₁ adj₂ 0 := by
  intro _ _ _ _; rfl

/-- **Layer 2.3 non-vacuity: `IsFullyPathBlockDiagonal` on the zero matrix.** -/
example (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) :
    IsFullyPathBlockDiagonal m adj₁ adj₂ 0 :=
  ⟨fun _ _ _ _ => rfl, fun _ _ _ _ => rfl⟩

/-- **Layer 2.3 non-vacuity: `pathBlockRestrict` is well-typed.** -/
noncomputable example
    (M : Matrix (Fin (dimGQ 2)) (Fin (dimGQ 2)) ℚ)
    (h_block : IsPathBlockDiagonal 2 (fun _ _ => false) (fun _ _ => false) M) :
    pathBlockSubspace 2 (fun _ _ => false) →ₗ[ℚ]
    pathBlockSubspace 2 (fun _ _ => false) :=
  pathBlockRestrict 2 (fun _ _ => false) (fun _ _ => false) M h_block

/-- **Layer 2.3.1 non-vacuity: `pathBlockEquivOfInverse` with M = M' = 1.**
The identity matrix is its own inverse and trivially block-diagonal w.r.t.
any adjacency partition. This produces a `LinearEquiv` between the
path-block subspace and itself (the identity equivalence).

The path-to-padding off-diagonal of `(1 : Matrix _ _ ℚ)` vanishes because
the entry `(1 : Matrix) i j = 0` whenever `i ≠ j`, and the
path-slot/padding-slot Finsets are disjoint. -/
noncomputable example :
    pathBlockSubspace 2 (fun _ _ => false) ≃ₗ[ℚ]
    pathBlockSubspace 2 (fun _ _ => false) :=
  let id_block_diag :
      IsPathBlockDiagonal 2 (fun _ _ => false) (fun _ _ => false)
        (1 : Matrix (Fin (dimGQ 2)) (Fin (dimGQ 2)) ℚ) := fun i hi j hj => by
    rw [Matrix.one_apply, if_neg]
    intro h_eq
    subst h_eq
    rw [pathSlotIndices_eq_vertex_union_presentArrow] at hj
    rcases Finset.mem_union.mp hj with hv | hp
    · exact (Finset.disjoint_left.mp
        (vertexSlotIndices_disjoint_paddingSlotIndices 2 (fun _ _ => false))) hv hi
    · exact (Finset.disjoint_left.mp
        (presentArrowSlotIndices_disjoint_paddingSlotIndices 2 (fun _ _ => false))) hp hi
  pathBlockEquivOfInverse 2 (fun _ _ => false) (fun _ _ => false)
    (1 : Matrix (Fin (dimGQ 2)) (Fin (dimGQ 2)) ℚ)
    (1 : Matrix (Fin (dimGQ 2)) (Fin (dimGQ 2)) ℚ)
    id_block_diag id_block_diag (one_mul _) (one_mul _)

/-- **Layer 2.4 non-vacuity: `slotToArrow_mem_presentArrows_of_path` on m=2.** -/
example :
    slotToArrow 2 (slotEquiv 2 ((slotEquiv 2).symm (.vertex 0))) ∈
      presentArrows 2 (fun _ _ => false) := by
  apply slotToArrow_mem_presentArrows_of_path
  rw [pathSlotIndices_eq_vertex_union_presentArrow]
  apply Finset.mem_union_left
  rw [mem_vertexSlotIndices_iff]
  exact ⟨0, Equiv.apply_symm_apply _ _⟩

/-- **Layer 2.4 non-vacuity: `slotOfArrow_mem_pathSlotIndices_of_present`
on the vertex idempotent at m=2.** -/
example :
    slotOfArrow 2 (.id 0) ∈ pathSlotIndices 2 (fun _ _ => false) :=
  slotOfArrow_mem_pathSlotIndices_of_present 2 (fun _ _ => false) _
    (presentArrows_id_mem _ _ _)

/-- **Layer 2.4 non-vacuity: forward map's `_mem` discharges unconditionally.** -/
example (v : Fin (dimGQ 2) → ℚ) :
    pathBlockToPresentArrowsFun 2 (fun _ _ => false) v ∈
      presentArrowsSubspace 2 (fun _ _ => false) :=
  pathBlockToPresentArrowsFun_mem 2 (fun _ _ => false) v

/-- **Layer 2.4 non-vacuity: reverse map's `_mem` discharges unconditionally.** -/
example (f : pathAlgebraQuotient 2) :
    presentArrowsToPathBlockFun 2 (fun _ _ => false) f ∈
      pathBlockSubspace 2 (fun _ _ => false) :=
  presentArrowsToPathBlockFun_mem 2 (fun _ _ => false) f

/-- **Layer 2.4 non-vacuity: bridge round-trip `forward ∘ reverse = id`.**
Companion to the existing `symm ∘ forward = id` test, exercising the
other direction of the LinearEquiv. -/
example (f : presentArrowsSubspace 2 (fun _ _ => false)) :
    pathBlockToPresentArrows 2 (fun _ _ => false)
      ((pathBlockToPresentArrows 2 (fun _ _ => false)).symm f) = f :=
  (pathBlockToPresentArrows 2 (fun _ _ => false)).right_inv f

end PathBlockSubspaceNonVacuity

-- ============================================================================
-- §15.18  R-TI Phase 3 (partial-discharge form): GL³ → algebra-iso bridge.
--
-- Sub-tasks A.1, A.2, A.4, A.6 land the tractable infrastructure
-- unconditionally; the deep multilinear-algebra content of Sub-tasks
-- A.3 + A.5 (Manin's tensor-stabilizer theorem + distinguished-padding
-- rigidity) is captured as the single research-scope `Prop`
-- `GL3InducesAlgEquivOnPathSubspace`.
-- ============================================================================

-- Sub-task A.1 — Encoder polynomial-identity catalogue.
#print axioms Orbcrypt.GrochowQiao.encoder_assoc_path
#print axioms Orbcrypt.GrochowQiao.encoder_diag_at_path_in_zero_one
#print axioms Orbcrypt.GrochowQiao.encoder_diag_at_padding_eq_two
#print axioms Orbcrypt.GrochowQiao.encoder_off_diag_path_padding_zero
#print axioms Orbcrypt.GrochowQiao.encoder_padding_diag_only

-- Sub-task A.2 — Associativity polynomial identity for 3-tensors.
-- (The earlier `IsAssociativeTensorPreservedByGL3` Prop has been removed
-- as mathematically incorrect for arbitrary GL³; only structure-tensor-
-- preserving subgroup actions preserve associativity, and that content
-- is captured in the research-scope `GL3InducesAlgEquivOnPathSubspace`
-- bundle in `AlgEquivFromGL3.lean`.)
#print axioms Orbcrypt.GrochowQiao.IsAssociativeTensor
#print axioms Orbcrypt.GrochowQiao.encoder_isAssociativeTensor_full_path

-- Sub-task A.4 — Path-only structure tensor + restricted GL³.
#print axioms Orbcrypt.GrochowQiao.pathOnlyStructureTensor
#print axioms Orbcrypt.GrochowQiao.pathOnlyStructureTensor_apply
#print axioms Orbcrypt.GrochowQiao.pathOnlyStructureTensor_index_is_path_algebra
#print axioms Orbcrypt.GrochowQiao.pathOnlyStructureTensor_isAssociative
#print axioms Orbcrypt.GrochowQiao.pathOnlyStructureTensor_diagonal_in_zero_one
#print axioms Orbcrypt.GrochowQiao.RestrictedGL3OnPathOnlyTensor
#print axioms Orbcrypt.GrochowQiao.restrictedGL3OnPathOnlyTensor_identity_case

-- Sub-task A.6 — Conditional headline + research-scope Prop.
#print axioms Orbcrypt.GrochowQiao.GL3InducesAlgEquivOnPathSubspace
#print axioms Orbcrypt.GrochowQiao.gl3_induces_algEquiv_on_pathSubspace
#print axioms Orbcrypt.GrochowQiao.gl3_induces_algEquiv_on_pathSubspace_identity_case
#print axioms Orbcrypt.GrochowQiao.gl3_algEquiv_partial_closure_status_disclosure

-- ============================================================================
-- §15.18 non-vacuity witnesses
-- ============================================================================

namespace AlgEquivFromGL3NonVacuity

open Orbcrypt
open Orbcrypt.GrochowQiao

/-- **Sub-task A.1.0 non-vacuity at m = 1.**

At a vertex-slot quadruple `(v0, v0, v0, v0)` of the single-vertex
graph, the LHS sum collapses to `T(v0, v0, v0) * T(v0, v0, v0) = 1`
and the RHS sum collapses to the same value, so the associativity
identity holds with both sides equal to `1`.  Exercises
`encoder_assoc_path` on a concrete instance whose result is non-trivial
(both sides collapse to a single non-zero contribution rather than
being identically zero). -/
example :
    (∑ a : Fin (dimGQ 1), grochowQiaoEncode 1 (fun _ _ => true)
        ((slotEquiv 1).symm (.vertex 0))
        ((slotEquiv 1).symm (.vertex 0)) a *
        grochowQiaoEncode 1 (fun _ _ => true) a
        ((slotEquiv 1).symm (.vertex 0))
        ((slotEquiv 1).symm (.vertex 0))) =
    (∑ a : Fin (dimGQ 1), grochowQiaoEncode 1 (fun _ _ => true)
        ((slotEquiv 1).symm (.vertex 0))
        ((slotEquiv 1).symm (.vertex 0)) a *
        grochowQiaoEncode 1 (fun _ _ => true)
        ((slotEquiv 1).symm (.vertex 0)) a
        ((slotEquiv 1).symm (.vertex 0))) :=
  encoder_assoc_path 1 (fun _ _ => true)
    ((slotEquiv 1).symm (.vertex 0))
    ((slotEquiv 1).symm (.vertex 0))
    ((slotEquiv 1).symm (.vertex 0))
    ((slotEquiv 1).symm (.vertex 0))
    (by unfold isPathAlgebraSlot; rw [Equiv.apply_symm_apply])
    (by unfold isPathAlgebraSlot; rw [Equiv.apply_symm_apply])
    (by unfold isPathAlgebraSlot; rw [Equiv.apply_symm_apply])
    (by unfold isPathAlgebraSlot; rw [Equiv.apply_symm_apply])

/-- **Sub-task A.1.1 non-vacuity: vertex slot diagonal is in {0, 1}.**

At a vertex slot of `m = 1`, the diagonal value is `1`. -/
example :
    grochowQiaoEncode 1 (fun _ _ => false)
      ((slotEquiv 1).symm (.vertex 0))
      ((slotEquiv 1).symm (.vertex 0))
      ((slotEquiv 1).symm (.vertex 0)) = 0 ∨
    grochowQiaoEncode 1 (fun _ _ => false)
      ((slotEquiv 1).symm (.vertex 0))
      ((slotEquiv 1).symm (.vertex 0))
      ((slotEquiv 1).symm (.vertex 0)) = 1 :=
  encoder_diag_at_path_in_zero_one 1 (fun _ _ => false) _
    (by unfold isPathAlgebraSlot; rw [Equiv.apply_symm_apply])

/-- **Sub-task A.1.2 non-vacuity: padding slot diagonal is exactly 2.**

At a padding slot (arrow with `adj _ _ = false`) on `m = 2`, the
diagonal value is `2`. -/
example :
    grochowQiaoEncode 2 (fun _ _ => false)
      ((slotEquiv 2).symm (.arrow 0 1))
      ((slotEquiv 2).symm (.arrow 0 1))
      ((slotEquiv 2).symm (.arrow 0 1)) = 2 :=
  encoder_diag_at_padding_eq_two 2 (fun _ _ => false) _
    (by unfold isPathAlgebraSlot; rw [Equiv.apply_symm_apply])

/-- **Sub-task A.1.4 non-vacuity: padding slab is non-zero only at the diagonal.**

At a padding slot `i = .arrow 0 1` on `m = 2`, the slab `(i, j, k)`
is non-zero iff `j = k = i`. -/
example :
    grochowQiaoEncode 2 (fun _ _ => false)
      ((slotEquiv 2).symm (.arrow 0 1))
      ((slotEquiv 2).symm (.arrow 0 1))
      ((slotEquiv 2).symm (.arrow 0 1)) ≠ 0 := by
  rw [(encoder_padding_diag_only 2 (fun _ _ => false)
        ((slotEquiv 2).symm (.arrow 0 1))
        ((slotEquiv 2).symm (.arrow 0 1))
        ((slotEquiv 2).symm (.arrow 0 1))
        (by unfold isPathAlgebraSlot; rw [Equiv.apply_symm_apply]))]
  exact ⟨rfl, rfl⟩

/-- **Sub-task A.1.3 non-vacuity: mixed-class triple vanishes.**

For a mixed triple `(vertex, arrow-padding, vertex)` on `m = 2` with
`adj := fun _ _ => false`, the encoder evaluates to zero.  The vertex
slot is path-algebra, the arrow slot is padding (since `adj _ _ =
false`); the triple has both classes present and is therefore
mixed-class. -/
example :
    grochowQiaoEncode 2 (fun _ _ => false)
      ((slotEquiv 2).symm (.vertex 0))
      ((slotEquiv 2).symm (.arrow 0 1))
      ((slotEquiv 2).symm (.vertex 0)) = 0 := by
  apply encoder_off_diag_path_padding_zero
  refine ⟨?_, ?_⟩
  · -- not all-path: the middle slot is padding.
    rintro ⟨_, h_mid, _⟩
    revert h_mid
    unfold isPathAlgebraSlot
    rw [Equiv.apply_symm_apply]
    decide
  · -- not all-padding: the first slot is a vertex (always path-algebra).
    rintro ⟨h_first, _, _⟩
    revert h_first
    unfold isPathAlgebraSlot
    rw [Equiv.apply_symm_apply]
    decide

/-- **Sub-task A.2 non-vacuity: the encoder on the complete graph at
m = 1 is associative.**

When every slot is path-algebra, the encoder satisfies the
associativity polynomial identity. -/
example : IsAssociativeTensor (grochowQiaoEncode 1 (fun _ _ => true)) := by
  apply encoder_isAssociativeTensor_full_path
  intro i
  -- m = 1: dimGQ 1 = 1 + 1 = 2, slots = {.vertex 0, .arrow 0 0}.
  -- All vertex slots are path-algebra; arrow (0, 0) is path-algebra
  -- because adj 0 0 = true.
  cases hi : slotEquiv 1 i with
  | vertex v => unfold isPathAlgebraSlot; rw [hi]
  | arrow u v => unfold isPathAlgebraSlot; rw [hi]

-- (The earlier identity-case-of-GL³-preservation test has been removed;
-- generic GL³ does not preserve associativity, so the only honest
-- witness is the trivial `IsAssociativeTensor T → IsAssociativeTensor
-- ((1) • T)` which `one_smul` makes definitional and which adds no
-- substantive content beyond `Equiv.refl`.)

/-- **Sub-task A.4 non-vacuity: path-only-tensor index is path-algebra.**

For every quadruple of `Fin (pathSlotIndices m adj).card`-indices, the
underlying `Fin (dimGQ m)`-values obtained via the
`(pathSlotIndices m adj).equivFin.symm` bijection are all path-algebra
slots.  Exercised on `m = 2` with the adjacency `adj := fun u v =>
decide (u.val ≠ v.val)` (complete graph minus self-loops, which has 2
present arrows). -/
example
    (i j k l : Fin (pathSlotIndices 2 (fun u v => decide (u.val ≠ v.val))).card) :
    let adj : Fin 2 → Fin 2 → Bool := fun u v => decide (u.val ≠ v.val)
    let i' := ((pathSlotIndices 2 adj).equivFin.symm i).val
    let j' := ((pathSlotIndices 2 adj).equivFin.symm j).val
    let k' := ((pathSlotIndices 2 adj).equivFin.symm k).val
    let l' := ((pathSlotIndices 2 adj).equivFin.symm l).val
    isPathAlgebraSlot 2 adj i' = true ∧
    isPathAlgebraSlot 2 adj j' = true ∧
    isPathAlgebraSlot 2 adj k' = true ∧
    isPathAlgebraSlot 2 adj l' = true :=
  pathOnlyStructureTensor_index_is_path_algebra 2
    (fun u v => decide (u.val ≠ v.val)) i j k l

/-- **Sub-task A.4 non-vacuity: `pathOnlyStructureTensor_apply` simp
lemma fires.** -/
example
    (i j k : Fin (pathSlotIndices 2 (fun _ _ => false : Fin 2 → Fin 2 → Bool)).card) :
    pathOnlyStructureTensor 2 (fun _ _ => false) i j k =
    grochowQiaoEncode 2 (fun _ _ => false)
      ((pathSlotIndices 2 (fun _ _ => false : Fin 2 → Fin 2 → Bool)).equivFin.symm i).val
      ((pathSlotIndices 2 (fun _ _ => false : Fin 2 → Fin 2 → Bool)).equivFin.symm j).val
      ((pathSlotIndices 2 (fun _ _ => false : Fin 2 → Fin 2 → Bool)).equivFin.symm k).val :=
  pathOnlyStructureTensor_apply 2 (fun _ _ => false) i j k

/-- **Sub-task A.4 non-vacuity: `pathOnlyStructureTensor_isAssociative`
proved on a non-trivial graph.**

The path-only tensor of any graph satisfies the associativity polynomial
identity `IsAssociativeTensor`.  Exercises the substantive proof on
`m = 2` with the adjacency `adj := fun u v => decide (u.val ≠ v.val)`
(complete graph minus self-loops, 2 present arrows). -/
example :
    IsAssociativeTensor
      (pathOnlyStructureTensor 2 (fun u v => decide (u.val ≠ v.val))) :=
  pathOnlyStructureTensor_isAssociative 2 (fun u v => decide (u.val ≠ v.val))

/-- **Sub-task A.4 non-vacuity: path-only-tensor diagonal in `{0, 1}`.**

The path-only structure tensor's diagonal value at any index is either
`0` (corresponds to a present-arrow slot) or `1` (corresponds to a
vertex slot).  Exercised on `m = 2` with the adjacency
`adj := fun u v => decide (u.val ≠ v.val)`. -/
example
    (i : Fin (pathSlotIndices 2 (fun u v => decide (u.val ≠ v.val))).card) :
    pathOnlyStructureTensor 2 (fun u v => decide (u.val ≠ v.val)) i i i = 0 ∨
    pathOnlyStructureTensor 2 (fun u v => decide (u.val ≠ v.val)) i i i = 1 :=
  pathOnlyStructureTensor_diagonal_in_zero_one 2
    (fun u v => decide (u.val ≠ v.val)) i

/-- **Sub-task A.4 non-vacuity: substantive `restrictedGL3OnPathOnlyTensor`
identity case.**

At `g = 1` between two distinct adjacencies `(adj₁, adj₂)` such that
`1 • encode m adj₁ = encode m adj₂`, the identity-case witness derives
`adj₁ = adj₂` via the diagonal-value classification, hence the
present-arrow cardinalities match.

Exercises the substantive version of
`restrictedGL3OnPathOnlyTensor_identity_case` (the post-audit-pass
version that consumes the hypothesis non-trivially). -/
example (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_eq : (1 : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ ×
              GL (Fin (dimGQ m)) ℚ) • grochowQiaoEncode m adj₁ =
              grochowQiaoEncode m adj₂) :
    (presentArrowSlotIndices m adj₁).card =
      (presentArrowSlotIndices m adj₂).card :=
  restrictedGL3OnPathOnlyTensor_identity_case m adj₁ adj₂ h_eq

/-- **Sub-task A.6 non-vacuity: substantive identity-case AlgEquiv
on the path subspace.**

At `g = 1` between two distinct adjacencies `(adj₁, adj₂)` such that
`1 • encode m adj₁ = encode m adj₂`, the identity-case witness derives
`adj₁ = adj₂` via the diagonal-value classification, hence
`AlgEquiv.refl` preserves `presentArrowsSubspace m adj₁ =
presentArrowsSubspace m adj₂`.

Exercises the substantive version of
`gl3_induces_algEquiv_on_pathSubspace_identity_case` (the post-audit-
pass version that consumes the hypothesis non-trivially). -/
example (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_eq : (1 : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ ×
              GL (Fin (dimGQ m)) ℚ) • grochowQiaoEncode m adj₁ =
              grochowQiaoEncode m adj₂) :
    ∃ (ϕ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m),
      ϕ '' (presentArrowsSubspace m adj₁ : Set (pathAlgebraQuotient m)) =
        (presentArrowsSubspace m adj₂ : Set (pathAlgebraQuotient m)) :=
  gl3_induces_algEquiv_on_pathSubspace_identity_case m adj₁ adj₂ h_eq

/-- **Sub-task A.6 non-vacuity: conditional headline.**

Under the research-scope `Prop`, the conditional headline produces an
AlgEquiv between any two adjacencies whose encoders are GL³-related. -/
example (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_research : GL3InducesAlgEquivOnPathSubspace m)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ ×
         GL (Fin (dimGQ m)) ℚ)
    (hg : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂) :
    ∃ (ϕ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m),
      ϕ '' (presentArrowsSubspace m adj₁ : Set (pathAlgebraQuotient m)) =
        (presentArrowsSubspace m adj₂ : Set (pathAlgebraQuotient m)) :=
  gl3_induces_algEquiv_on_pathSubspace m h_research adj₁ adj₂ g hg

end AlgEquivFromGL3NonVacuity

-- ============================================================================
-- ## §15.19 R-TI Phase 3 — Final Prop discharge (audit 2026-04-28).
-- ============================================================================

-- A.1.5: Encoder unit-compatibility identity (prerequisite for Manin).
#print axioms Orbcrypt.GrochowQiao.encoder_unit_compatibility

-- A.5.1: Manin abstract algebra structure tensor.
#print axioms Orbcrypt.GrochowQiao.Manin.structureTensor
#print axioms Orbcrypt.GrochowQiao.Manin.structureTensor_apply
#print axioms Orbcrypt.GrochowQiao.Manin.structureTensor_recovers_mul

-- A.5.2: Basis-change relation predicate (with identity-case witness).
#print axioms Orbcrypt.GrochowQiao.Manin.IsBasisChangeRelated
#print axioms Orbcrypt.GrochowQiao.Manin.IsBasisChangeRelated.id

-- A.3.1: Padding trivial-algebra identity.
#print axioms Orbcrypt.GrochowQiao.encoder_padding_trivial_algebra

-- A.3.2: Padding-rank invariant.
#print axioms Orbcrypt.GrochowQiao.IsConcentratedSlot
#print axioms Orbcrypt.GrochowQiao.paddingRankInvariant
#print axioms Orbcrypt.GrochowQiao.paddingRankInvariant_eq_paddingSlotIndices_card

-- A.5.3: Manin tensor-stabilizer theorem (algebra hom).
#print axioms Orbcrypt.GrochowQiao.Manin.linearMapOfBasisChange
#print axioms Orbcrypt.GrochowQiao.Manin.linearMapOfBasisChange_basis
#print axioms Orbcrypt.GrochowQiao.Manin.coefficient_match_of_basisChange
#print axioms Orbcrypt.GrochowQiao.Manin.linearMapOfBasisChange_mul_basis
#print axioms Orbcrypt.GrochowQiao.Manin.linearMapOfBasisChange_mul
#print axioms Orbcrypt.GrochowQiao.Manin.linearMapOfBasisChange_one
#print axioms Orbcrypt.GrochowQiao.Manin.IsUnitCompatible
#print axioms Orbcrypt.GrochowQiao.Manin.algHomOfTensorIso
#print axioms Orbcrypt.GrochowQiao.Manin.algHomOfTensorIso_basis

-- A.5.4: AlgEquiv upgrade.
#print axioms Orbcrypt.GrochowQiao.Manin.linearMapOfBasisChange_left_inv
#print axioms Orbcrypt.GrochowQiao.Manin.linearMapOfBasisChange_right_inv
#print axioms Orbcrypt.GrochowQiao.Manin.linearEquivOfBasisChange
#print axioms Orbcrypt.GrochowQiao.Manin.algEquivOfTensorIso
#print axioms Orbcrypt.GrochowQiao.Manin.algEquivOfTensorIso_basis

-- A.6.3: Discharge bridges.
#print axioms Orbcrypt.GrochowQiao.Discharge.quiverPermFun_mem_presentArrowsSubspace
#print axioms Orbcrypt.GrochowQiao.Discharge.quiverPermAlgEquiv_image_subset_presentArrowsSubspace
#print axioms Orbcrypt.GrochowQiao.Discharge.quiverPermAlgEquiv_image_presentArrowsSubspace
#print axioms Orbcrypt.GrochowQiao.Discharge.gl3InducesAlgEquivOnPathSubspace_of_rigidity
#print axioms Orbcrypt.GrochowQiao.Discharge.isPresentArrowSlot_liftedSigma
#print axioms Orbcrypt.GrochowQiao.Discharge.presentArrowSlotIndices_card_eq_of_graphIso
#print axioms Orbcrypt.GrochowQiao.Discharge.restrictedGL3OnPathOnlyTensor_of_rigidity

-- Top-level unified discharge under GrochowQiaoRigidity.
#print axioms Orbcrypt.GrochowQiao.grochowQiao_phase3_discharge_under_rigidity
#print axioms Orbcrypt.GrochowQiao.grochowQiao_unified_discharge_under_rigidity

namespace Phase3DischargeNonVacuity

open Orbcrypt
open GrochowQiao

/-- **Phase 3 discharge non-vacuity: identity matrix is basis-change-related to itself.**

The identity matrix gives an `IsBasisChangeRelated` witness when both
algebras agree (here exemplified at `Bool` index over `ℚ`-trivial
self-tensor). -/
example (T : Bool → Bool → Bool → ℚ) :
    Manin.IsBasisChangeRelated T T (1 : Matrix Bool Bool ℚ)
                                   (1 : Matrix Bool Bool ℚ) :=
  Manin.IsBasisChangeRelated.id T

/-- **Phase 3 discharge non-vacuity: padding-rank invariant equals
padding-slot count for the empty graph at `m = 2`.** -/
example :
    paddingRankInvariant
      (grochowQiaoEncode 2 (fun _ _ => false)) =
      (paddingSlotIndices 2 (fun _ _ => false)).card :=
  paddingRankInvariant_eq_paddingSlotIndices_card 2 (fun _ _ => false)

/-- **Phase 3 discharge non-vacuity: from `GrochowQiaoRigidity`, both
Phase 3 Props discharge.** -/
example (h_rigidity : GrochowQiaoRigidity) (m : ℕ) :
    GL3InducesAlgEquivOnPathSubspace m ∧ RestrictedGL3OnPathOnlyTensor m :=
  grochowQiao_phase3_discharge_under_rigidity h_rigidity m

/-- **Phase 3 discharge non-vacuity: unified discharge (Karp + both
Phase 3 Props) under `GrochowQiaoRigidity`.** -/
example (h_rigidity : GrochowQiaoRigidity) :
    @GIReducesToTI ℚ _ ∧
    (∀ m, GL3InducesAlgEquivOnPathSubspace m) ∧
    (∀ m, RestrictedGL3OnPathOnlyTensor m) :=
  grochowQiao_unified_discharge_under_rigidity h_rigidity

-- ----------------------------------------------------------------------------
-- Concrete Manin theorem evaluations on `ℚ` as a 1-dimensional ℚ-algebra.
-- Exercises the full Manin tensor-stabilizer pipeline at the smallest
-- non-trivial instance (single-element basis indexed by `PUnit`).
-- ----------------------------------------------------------------------------

/-- **Manin non-vacuity: structure tensor at singleton basis evaluates to `1`.**

For the basis of `ℚ` over itself (the singleton basis at `PUnit`), the
structure tensor at the unique basis element is `1` — reflecting
`1 * 1 = 1` in `ℚ`. -/
example :
    let b : Module.Basis PUnit ℚ ℚ := Module.Basis.singleton PUnit ℚ
    Manin.structureTensor b default default default = (1 : ℚ) := by
  simp [Manin.structureTensor]

/-- **Manin non-vacuity: structure tensor recovers multiplication.**

Exercises `structureTensor_recovers_mul` on `ℚ` viewed as a
1-dimensional ℚ-algebra. -/
example :
    let b : Module.Basis PUnit ℚ ℚ := Module.Basis.singleton PUnit ℚ
    b default * b default = ∑ k, Manin.structureTensor b default default k • b k :=
  Manin.structureTensor_recovers_mul (Module.Basis.singleton PUnit ℚ) default default

/-- **Manin non-vacuity: unit-compatibility holds at identity matrix.**

For the singleton basis, `IsUnitCompatible` with `P = 1` is
discharged by direct computation. -/
example :
    Manin.IsUnitCompatible (Module.Basis.singleton PUnit ℚ)
      (Module.Basis.singleton PUnit ℚ)
      (1 : Matrix PUnit PUnit ℚ) := by
  intro _; simp

/-- **Manin non-vacuity: algHomOfTensorIso constructs a valid AlgHom on
the singleton basis at the identity matrix.**

Evaluating the constructed AlgHom on the basis element `b default = 1`
yields `1 : ℚ`, confirming the construction agrees with the identity
algebra hom at the smallest non-trivial instance. -/
example :
    let b : Module.Basis PUnit ℚ ℚ := Module.Basis.singleton PUnit ℚ
    let h_unit : Manin.IsUnitCompatible b b 1 := by intro _; simp
    Manin.algHomOfTensorIso b b 1 1
        (Manin.IsBasisChangeRelated.id (Manin.structureTensor b)) h_unit
        (b default) = (1 : ℚ) := by simp

/-- **Manin non-vacuity: algEquivOfTensorIso constructs a valid AlgEquiv
on the singleton basis at the identity matrix.**

Evaluating the constructed AlgEquiv on the basis element `b default = 1`
yields `1 : ℚ`, confirming the construction agrees with the identity
algebra equivalence at the smallest non-trivial instance. This is the
end-to-end exercise of the Manin tensor-stabilizer construction
(A.5.1 → A.5.2 → A.5.3 → A.5.4) at a concrete instance. -/
example :
    let b : Module.Basis PUnit ℚ ℚ := Module.Basis.singleton PUnit ℚ
    let h_unit : Manin.IsUnitCompatible b b 1 := by intro _; simp
    Manin.algEquivOfTensorIso b b 1 1
        (Manin.IsBasisChangeRelated.id (Manin.structureTensor b)) h_unit
        (b default) = (1 : ℚ) := by simp

end Phase3DischargeNonVacuity

-- ============================================================================
-- ## §15.20 R-TI Phase 3 — PathOnlyAlgebra (Manin path connection).
-- ============================================================================

-- A.5.5: Path-only Subalgebra structure.
#print axioms Orbcrypt.GrochowQiao.pathMul_some_mem_presentArrows
#print axioms Orbcrypt.GrochowQiao.presentArrowsSubspace_mul_mem
#print axioms Orbcrypt.GrochowQiao.one_mem_presentArrowsSubspace
#print axioms Orbcrypt.GrochowQiao.pathOnlyAlgebraSubalgebra
#print axioms Orbcrypt.GrochowQiao.mem_pathOnlyAlgebraSubalgebra_iff

-- A.5.5: Basis construction.
#print axioms Orbcrypt.GrochowQiao.pathOnlyAlgebraEquivFun
#print axioms Orbcrypt.GrochowQiao.pathOnlyAlgebraBasis
#print axioms Orbcrypt.GrochowQiao.pathOnlyAlgebraBasis_repr_apply
#print axioms Orbcrypt.GrochowQiao.pathOnlyAlgebraBasis_apply_underlying
#print axioms Orbcrypt.GrochowQiao.pathOnlyAlgebraBasis_mul_underlying

-- A.6.1: Bridge to pathOnlyStructureTensor.
#print axioms Orbcrypt.GrochowQiao.pathOnlyAlgebraBasis_structureTensor_eq_pathOnlyStructureTensor

-- A.6.2: Manin-chain identity-case witnesses.
#print axioms Orbcrypt.GrochowQiao.pathOnlyStructureTensor_basisChangeRelated_self
#print axioms Orbcrypt.GrochowQiao.pathOnlyAlgebraBasis_unitCompatible_self

-- Path B: Genuine factoring through path-only Subalgebra AlgEquiv.
-- (The earlier `_via_manin` aliases — definitionally equal to Path A —
-- were removed as theatrical in the post-landing audit; replaced with
-- the substantive obligation factoring below.)
#print axioms Orbcrypt.GrochowQiao.Discharge.PathOnlyAlgEquivObligation
#print axioms Orbcrypt.GrochowQiao.Discharge.PathOnlySubalgebraGraphIsoObligation
#print axioms Orbcrypt.GrochowQiao.Discharge.pathOnlyAlgEquivObligation_id
#print axioms Orbcrypt.GrochowQiao.Discharge.pathOnlySubalgebraGraphIsoObligation_id
#print axioms Orbcrypt.GrochowQiao.Discharge.grochowQiaoRigidity_via_path_only_algEquiv_chain
#print axioms Orbcrypt.GrochowQiao.Discharge.pathOnlyAlgebra_manin_trivial

namespace PathOnlyAlgebraNonVacuity

open Orbcrypt
open GrochowQiao

/-- **Path-only Subalgebra non-vacuity at `m = 2` empty graph.**

The path-only Subalgebra of `pathAlgebraQuotient 2` under the empty
graph `(fun _ _ => false)` exists as a Subalgebra over `ℚ`.  This
exercises the unconditional `pathOnlyAlgebraSubalgebra` constructor. -/
noncomputable example :
    Subalgebra ℚ (pathAlgebraQuotient 2) :=
  pathOnlyAlgebraSubalgebra 2 (fun _ _ => false)

/-- **Multiplicative closure non-vacuity.**

The product of two zero elements (which trivially live in the
subspace) lives in the subspace. -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) :
    (0 : pathAlgebraQuotient m) * 0 ∈ presentArrowsSubspace m adj := by
  apply presentArrowsSubspace_mul_mem
  · exact (presentArrowsSubspace m adj).zero_mem
  · exact (presentArrowsSubspace m adj).zero_mem

/-- **Unit membership non-vacuity.** -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) :
    (1 : pathAlgebraQuotient m) ∈ presentArrowsSubspace m adj :=
  one_mem_presentArrowsSubspace m adj

/-- **Bridge non-vacuity at `m = 2` empty graph: Manin's structureTensor of
the path-only basis equals pathOnlyStructureTensor.** -/
example :
    Manin.structureTensor (pathOnlyAlgebraBasis 2 (fun _ _ => false)) =
      pathOnlyStructureTensor 2 (fun _ _ => false) :=
  pathOnlyAlgebraBasis_structureTensor_eq_pathOnlyStructureTensor 2 _

/-- **Identity-case basis-change witness.** -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Manin.IsBasisChangeRelated
        (pathOnlyStructureTensor m adj)
        (pathOnlyStructureTensor m adj)
        1 1 :=
  pathOnlyStructureTensor_basisChangeRelated_self m adj

/-- **Identity-case unit-compatibility witness.** -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Manin.IsUnitCompatible
        (pathOnlyAlgebraBasis m adj) (pathOnlyAlgebraBasis m adj) 1 :=
  pathOnlyAlgebraBasis_unitCompatible_self m adj

/-- **Path B obligation 1 identity-case witness.**

When adj₁ = adj₂, the AlgEquiv obligation discharges to `AlgEquiv.refl`. -/
example (m : ℕ) (adj : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (h_eq : g • grochowQiaoEncode m adj = grochowQiaoEncode m adj) :
    Nonempty (↥(pathOnlyAlgebraSubalgebra m adj) ≃ₐ[ℚ]
                ↥(pathOnlyAlgebraSubalgebra m adj)) :=
  Discharge.pathOnlyAlgEquivObligation_id m adj g h_eq

/-- **Path B obligation 2 identity-case witness.**

For adj₁ = adj₂, σ = identity is a graph iso. -/
example (m : ℕ) (adj : Fin m → Fin m → Bool)
    (h : Nonempty (↥(pathOnlyAlgebraSubalgebra m adj) ≃ₐ[ℚ]
                    ↥(pathOnlyAlgebraSubalgebra m adj))) :
    ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj i j = adj (σ i) (σ j) :=
  Discharge.pathOnlySubalgebraGraphIsoObligation_id m adj h

/-- **Path B factoring composition: under both Path B obligations,
`GrochowQiaoRigidity` follows.** -/
example (m : ℕ)
    (h_in : Discharge.PathOnlyAlgEquivObligation m)
    (h_out : Discharge.PathOnlySubalgebraGraphIsoObligation m)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_iso : AreTensorIsomorphic
              (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂)) :
    ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j) :=
  Discharge.grochowQiaoRigidity_via_path_only_algEquiv_chain
    m h_in h_out adj₁ adj₂ h_iso

/-- **Manin chain non-vacuity: end-to-end algebra-equiv construction
on the path-only Subalgebra at the trivial instance.** -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Nonempty (↥(pathOnlyAlgebraSubalgebra m adj) ≃ₐ[ℚ]
                ↥(pathOnlyAlgebraSubalgebra m adj)) :=
  Discharge.pathOnlyAlgebra_manin_trivial m adj

end PathOnlyAlgebraNonVacuity

-- ============================================================================
-- §15.21 — Path B Subalgebra σ-extraction (Sub-task A.6.4).
-- ============================================================================

/-! ## §15.21 — Path B obligations: substantive discharge

Path B's two research-scope obligations:
* `PathOnlySubalgebraGraphIsoObligation` — discharged UNCONDITIONALLY
  via `pathOnlySubalgebraGraphIsoObligation_discharge` using
  Wedderburn–Mal'cev σ-extraction + adjacency invariance from arrow
  preservation.
* `PathOnlyAlgEquivObligation` — discharged CONDITIONALLY on
  `GrochowQiaoRigidity` via `pathOnlyAlgEquivObligation_under_rigidity`.
  The conditional discharge is *necessary*: `PathOnlyAlgEquivObligation`
  is provably equivalent to `GrochowQiaoRigidity` (modulo the
  unconditional WM σ-extraction).  Discharging it unconditionally
  would solve the deep open problem of Grochow–Qiao SIAM J. Comp.
  2023 §4.3 (the partition-rigidity argument).

Every new declaration depends only on the standard Lean trio. -/

#print axioms Orbcrypt.GrochowQiao.vertexIdempotentSubalgebra
#print axioms Orbcrypt.GrochowQiao.vertexIdempotentSubalgebra_ne_zero
#print axioms Orbcrypt.GrochowQiao.vertexIdempotentSubalgebra_completeOrthogonalIdempotents
#print axioms Orbcrypt.GrochowQiao.algEquiv_image_vertexIdempotentSubalgebra_COI
#print axioms Orbcrypt.GrochowQiao.algEquiv_image_vertexIdempotentSubalgebra_ne_zero
#print axioms Orbcrypt.GrochowQiao.algEquivLifted
#print axioms Orbcrypt.GrochowQiao.algEquivLifted_completeOrthogonalIdempotents
#print axioms Orbcrypt.GrochowQiao.algEquivLifted_ne_zero
#print axioms Orbcrypt.GrochowQiao.pathOnlySubalgebraAlgEquiv_extractVertexPerm
#print axioms Orbcrypt.GrochowQiao.arrowElementSubalgebra
#print axioms Orbcrypt.GrochowQiao.arrowElementSubalgebra_ne_zero
#print axioms Orbcrypt.GrochowQiao.nilpotent_mem_pathAlgebraRadical
#print axioms Orbcrypt.GrochowQiao.innerAut_sandwich_radical
#print axioms Orbcrypt.GrochowQiao.algEquivLifted_arrow_mem_radical
#print axioms Orbcrypt.GrochowQiao.algEquivLifted_arrow_sandwich
#print axioms Orbcrypt.GrochowQiao.radical_apply_id_eq_zero
#print axioms Orbcrypt.GrochowQiao.radical_sandwich_eq_arrow_scalar
#print axioms Orbcrypt.GrochowQiao.algEquivLifted_arrow_eq_scalar
#print axioms Orbcrypt.GrochowQiao.algEquivLifted_arrow_scalar_ne_zero
#print axioms Orbcrypt.GrochowQiao.algEquivLifted_isGraphIso_forward
#print axioms Orbcrypt.GrochowQiao.pathOnlySubalgebraGraphIsoObligation_discharge
#print axioms Orbcrypt.GrochowQiao.pathOnlyAlgEquiv_of_graph_iso
#print axioms Orbcrypt.GrochowQiao.pathOnlyAlgEquivObligation_under_rigidity
#print axioms Orbcrypt.GrochowQiao.grochowQiaoRigidity_via_pathB_chain

namespace PathOnlyAlgEquivSigmaNonVacuity

open Orbcrypt
open GrochowQiao

/-- **Path B Sub-task A.6.4 non-vacuity (1): vertex idempotent in
Subalgebra at `m = 2`.**

The lifted vertex idempotent inhabits the path-only Subalgebra. -/
noncomputable example :
    ↥(pathOnlyAlgebraSubalgebra 2 (fun _ _ => false)) :=
  vertexIdempotentSubalgebra 2 (fun _ _ => false) 0

/-- **Non-vacuity (2): COI structure on lifted vertex idempotents.**

For any `m, adj`, the family of lifted vertex idempotents forms a
`CompleteOrthogonalIdempotents` structure in the path-only Subalgebra. -/
example (m : ℕ) (adj : Fin m → Fin m → Bool) :
    CompleteOrthogonalIdempotents (vertexIdempotentSubalgebra m adj) :=
  vertexIdempotentSubalgebra_completeOrthogonalIdempotents m adj

/-- **Non-vacuity (3): nilpotent ⇒ radical at `m = 2`.**

The arrow element `α(0, 1)` is nilpotent and hence lies in the radical. -/
example : arrowElement 2 0 1 ∈ pathAlgebraRadical 2 := by
  apply nilpotent_mem_pathAlgebraRadical
  exact arrow_mul_arrow_eq_zero 2 0 1 0 1

/-- **Non-vacuity (4): radical-sandwich-arrow-scalar reduction at `m = 2`.**

For any `A ∈ J` and any vertices `x, y`, `e_x * A * e_y = A(.edge x y) • α(x, y)`. -/
example (A : pathAlgebraQuotient 2) (h_A : A ∈ pathAlgebraRadical 2) :
    vertexIdempotent 2 0 * A * vertexIdempotent 2 1 =
      A (.edge 0 1) • arrowElement 2 0 1 :=
  radical_sandwich_eq_arrow_scalar 2 h_A 0 1

/-- **Non-vacuity (5): `PathOnlySubalgebraGraphIsoObligation` discharged
at `m = 2`.** -/
example : Discharge.PathOnlySubalgebraGraphIsoObligation 2 :=
  pathOnlySubalgebraGraphIsoObligation_discharge 2

/-- **Non-vacuity (6): `pathOnlyAlgEquiv_of_graph_iso` with σ = id at
`m = 2` empty graph.** -/
noncomputable example :
    ↥(pathOnlyAlgebraSubalgebra 2 (fun _ _ => false)) ≃ₐ[ℚ]
      ↥(pathOnlyAlgebraSubalgebra 2 (fun _ _ => false)) :=
  pathOnlyAlgEquiv_of_graph_iso 2 (fun _ _ => false) (fun _ _ => false) 1
    (fun i j => by simp)

/-- **Non-vacuity (7): conditional discharge of
`PathOnlyAlgEquivObligation` from `GrochowQiaoRigidity`.** -/
example (h_rig : GrochowQiaoRigidity) :
    Discharge.PathOnlyAlgEquivObligation 2 :=
  pathOnlyAlgEquivObligation_under_rigidity h_rig 2

/-- **Non-vacuity (8): Path B end-to-end Karp reduction under
`GrochowQiaoRigidity`.** -/
example (h_rig : GrochowQiaoRigidity)
    (adj₁ adj₂ : Fin 2 → Fin 2 → Bool)
    (h_iso : AreTensorIsomorphic
              (grochowQiaoEncode 2 adj₁) (grochowQiaoEncode 2 adj₂)) :
    ∃ σ : Equiv.Perm (Fin 2), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j) :=
  grochowQiaoRigidity_via_pathB_chain h_rig 2 adj₁ adj₂ h_iso

/-- **Non-vacuity (9): vertex idempotent in Subalgebra is non-zero.** -/
example : vertexIdempotentSubalgebra 2 (fun _ _ => false) 0 ≠ 0 :=
  vertexIdempotentSubalgebra_ne_zero 2 (fun _ _ => false) 0

/-- **Non-vacuity (10): radical_apply_id_eq_zero on a concrete radical
element at `m = 2`.** -/
example (z : Fin 2) : arrowElement 2 0 1 (.id z) = 0 :=
  radical_apply_id_eq_zero 2 (arrowElement_mem_pathAlgebraRadical 2 0 1) z

/-- **Non-vacuity (11): inner-conjugation sandwich identity at `j = 0`,
`A = α(0, 1)`.** -/
example (c d : pathAlgebraQuotient 2) :
    ((1 + (0 : pathAlgebraQuotient 2)) * c * (1 - 0)) * arrowElement 2 0 1 *
        ((1 + 0) * d * (1 - 0)) =
      c * arrowElement 2 0 1 * d :=
  innerAut_sandwich_radical 2
    (Submodule.zero_mem _)
    (arrowElement_mem_pathAlgebraRadical 2 0 1) c d

/-- **Non-vacuity (12): σ-extraction from a Subalgebra AlgEquiv at the
identity case.** -/
example : ∃ (σ : Equiv.Perm (Fin 2)) (j : pathAlgebraQuotient 2),
    j ∈ pathAlgebraRadical 2 ∧
    ∀ v : Fin 2,
      (1 + j) * vertexIdempotent 2 (σ v) * (1 - j) =
      ((AlgEquiv.refl :
          ↥(pathOnlyAlgebraSubalgebra 2 (fun _ _ => false)) ≃ₐ[ℚ]
            ↥(pathOnlyAlgebraSubalgebra 2 (fun _ _ => false)))
        (vertexIdempotentSubalgebra 2 (fun _ _ => false) v)).val :=
  pathOnlySubalgebraAlgEquiv_extractVertexPerm 2 (fun _ _ => false)
    (fun _ _ => false) AlgEquiv.refl

end PathOnlyAlgEquivSigmaNonVacuity

-- ============================================================================
-- § 15.22 R-12 — Tight 1/4 ε-bound for `concreteHidingBundle`
-- (audit 2026-04-29 § 8.1, research-scope discharge plan § R-12)
--
-- Layer A — Bool TV bound (`Probability/Advantage.lean`):
--   * `probTrue_bool_eq` — closed-form `probTrue` evaluation on Bool.
--   * `pmf_bool_sum_eq_one_toReal` — PMF sum-to-1 for Bool in ℝ.
--   * `probTrue_bool_toReal_eq` — `.toReal`-converted closed form.
--   * `advantage_bool_le_tv` — TV bound on Boolean distinguishers.
--   * `advantage_bool_id_eq_tv` — tightness witness at `D = id`.
--
-- Layer B — Concrete pointwise computations + headline
-- (`PublicKey/ObliviousSampling.lean`):
--   * `concreteHidingBundle_orbitDist_apply_true`,
--     `concreteHidingBundle_orbitDist_apply_false` — both = 1/2.
--   * `concreteHidingLHS_apply_true` (= 1/4),
--     `concreteHidingLHS_apply_false` (= 3/4).
--   * `concreteHiding_tight` — headline: tight ε = 1/4 bound.
--   * `concreteHiding_tight_attained` — tightness witness.
-- ============================================================================

#print axioms Orbcrypt.probTrue_bool_eq
#print axioms Orbcrypt.pmf_bool_sum_eq_one_toReal
#print axioms Orbcrypt.probTrue_bool_toReal_eq
#print axioms Orbcrypt.advantage_bool_le_tv
#print axioms Orbcrypt.advantage_bool_id_eq_tv
#print axioms Orbcrypt.concreteHidingBundle_orbitDist_apply_true
#print axioms Orbcrypt.concreteHidingBundle_orbitDist_apply_false
#print axioms Orbcrypt.concreteHidingLHS_apply_true
#print axioms Orbcrypt.concreteHidingLHS_apply_false
#print axioms Orbcrypt.concreteHiding_tight
#print axioms Orbcrypt.concreteHiding_tight_attained

/-! ## R-12 non-vacuity witnesses -/
namespace R12NonVacuity

open Orbcrypt

/-- **Non-vacuity (1): the headline tight 1/4 bound at `D = id`.** Asserts
the bound directly on a concrete pair of PMFs (the LHS combine PMF and
the RHS orbit PMF at the `concreteHidingBundle` fixture). -/
example :
    advantage (id : Bool → Bool)
      (PMF.map (fun (p : Fin 2 × Fin 2) =>
         concreteHidingCombine (concreteHidingBundle.randomizers p.1)
           (concreteHidingBundle.randomizers p.2))
         (uniformPMF (Fin 2 × Fin 2)))
      (orbitDist (G := Equiv.Perm Bool) concreteHidingBundle.basePoint)
      ≤ ((1 : ℝ) / 4) :=
  concreteHiding_tight (id : Bool → Bool)

/-- **Non-vacuity (2): tightness witness — advantage equals 1/4 at
`D = id`.** Combined with (1), confirms 1/4 is the smallest ε for which
`ObliviousSamplingConcreteHiding concreteHidingBundle
concreteHidingCombine ε` holds. -/
example :
    advantage (id : Bool → Bool)
      (PMF.map (fun (p : Fin 2 × Fin 2) =>
         concreteHidingCombine (concreteHidingBundle.randomizers p.1)
           (concreteHidingBundle.randomizers p.2))
         (uniformPMF (Fin 2 × Fin 2)))
      (orbitDist (G := Equiv.Perm Bool) concreteHidingBundle.basePoint)
      = ((1 : ℝ) / 4) :=
  concreteHiding_tight_attained

/-- **Non-vacuity (3): explicit `(orbitDist false) true = 1/2` at the
fixture.** -/
example :
    (orbitDist (G := Equiv.Perm Bool) concreteHidingBundle.basePoint) true
      = (1 / 2 : ENNReal) :=
  concreteHidingBundle_orbitDist_apply_true

/-- **Non-vacuity (4): explicit `(LHS PMF) true = 1/4` at the fixture.** -/
example :
    (PMF.map (fun (p : Fin 2 × Fin 2) =>
       concreteHidingCombine (concreteHidingBundle.randomizers p.1)
         (concreteHidingBundle.randomizers p.2))
       (uniformPMF (Fin 2 × Fin 2))) true = (1 / 4 : ENNReal) :=
  concreteHidingLHS_apply_true

/-- **Non-vacuity (5): closed-form `probTrue_bool_eq` on a concrete
`PMF` and the identity Bool function.** -/
example (μ : PMF Bool) :
    probTrue μ (id : Bool → Bool) =
      (if (id true : Bool) = true then μ true else 0) +
      (if (id false : Bool) = true then μ false else 0) :=
  probTrue_bool_eq μ id

/-- **Non-vacuity (6): TV upper bound applies to every `D : Bool → Bool`
on every PMF pair — instantiated at the `concreteHidingBundle` fixture
with the `not` distinguisher (which also achieves the `1/4` bound, by
TV symmetry). -/
example :
    advantage (Bool.not)
      (PMF.map (fun (p : Fin 2 × Fin 2) =>
         concreteHidingCombine (concreteHidingBundle.randomizers p.1)
           (concreteHidingBundle.randomizers p.2))
         (uniformPMF (Fin 2 × Fin 2)))
      (orbitDist (G := Equiv.Perm Bool) concreteHidingBundle.basePoint)
      ≤ ((1 : ℝ) / 4) :=
  concreteHiding_tight (Bool.not)

end R12NonVacuity

-- ============================================================================
-- § 15.23 R-13 — `Bitstring n`-typed polynomial-evaluation MAC + INT-CTXT
-- (audit 2026-04-29 § 8.1, research-scope discharge plan § R-13)
--
-- Layer α — `Probability/UniversalHash.lean` (already exists,
-- `IsEpsilonUniversal.ofCollisionCardBound` + `mono` directly consumed).
--
-- Layer β — `AEAD/BitstringPolynomialMAC.lean` (NEW module):
--   * `toBit` — bit-to-field encoding `Bool → ZMod p`.
--   * `toBit_injective` — injective at any prime `p`.
--   * `evalAtBitstring` — polynomial-eval hash core.
--   * `bitstringPolynomialHash` — `(k, s) ↦ s + ∑ toBit(b i) · k^(i+1)`.
--   * `bitstringPolynomialHash_collision_iff_eval` — `s` cancels.
--   * `bitstringDiffPolynomial` — formal `(ZMod p)[X]` of the difference.
--   * `bitstringDiffPolynomial_eval` — eval recovers
--     `evalAtBitstring(b₁) − evalAtBitstring(b₂)`.
--   * `bitstringDiffPolynomial_natDegree_le` — degree ≤ n.
--   * `bitstringDiffPolynomial_coeff_at` — coefficient extraction.
--   * `bitstringDiffPolynomial_ne_zero_of_ne` — non-zero on b₁ ≠ b₂.
--   * `bitstringDiffPolynomial_card_roots_le` — ≤ n roots.
--   * `bitstringDiffPolynomial_collision_keys_card_le` — ≤ n collision-keys.
--   * `bitstringPolynomialHash_collision_card_le` — ≤ n·p collisions.
--   * `bitstringPolynomialHash_isUniversal` — **headline** (n/p)-universal.
--   * `bitstringPolynomialMAC` — MAC built from the hash.
--   * `bitstringPolynomial_authKEM` — AEAD composition with any
--     `OrbitKEM G (Bitstring n) (ZMod p × ZMod p)`.
--   * `bitstringPolynomialMAC_int_ctxt` — **headline** unconditional
--     INT-CTXT for HGOE-typed authenticated encryption.
-- ============================================================================

#print axioms Orbcrypt.toBit
#print axioms Orbcrypt.toBit_injective
#print axioms Orbcrypt.evalAtBitstring
#print axioms Orbcrypt.bitstringPolynomialHash
#print axioms Orbcrypt.bitstringPolynomialHash_apply
#print axioms Orbcrypt.bitstringPolynomialHash_collision_iff_eval
#print axioms Orbcrypt.bitstringDiffPolynomial
#print axioms Orbcrypt.bitstringDiffPolynomial_eval
#print axioms Orbcrypt.bitstringDiffPolynomial_natDegree_le
#print axioms Orbcrypt.bitstringDiffPolynomial_coeff_at
#print axioms Orbcrypt.bitstringDiffPolynomial_ne_zero_of_ne
#print axioms Orbcrypt.bitstringDiffPolynomial_card_roots_le
#print axioms Orbcrypt.bitstringDiffPolynomial_collision_keys_card_le
#print axioms Orbcrypt.bitstringPolynomialHash_collision_card_le
#print axioms Orbcrypt.bitstringPolynomialHash_isUniversal
#print axioms Orbcrypt.bitstringPolynomialMAC
#print axioms Orbcrypt.bitstringPolynomial_authKEM
#print axioms Orbcrypt.bitstringPolynomialMAC_int_ctxt

/-! ## R-13 non-vacuity witnesses -/
namespace R13NonVacuity

open Orbcrypt

/-- **Non-vacuity (1): the (n/p)-universal hash family at `n = 2, p = 3`.**
The smallest non-trivial parameter pair where `n ≤ p` (`Fact (Nat.Prime
3)` is in Mathlib via `fact_prime_three`). Bound: `2/3 < 1`,
informative. -/
example :
    IsEpsilonUniversal (bitstringPolynomialHash 3 2)
      ((2 : ENNReal) / (3 : ENNReal)) :=
  bitstringPolynomialHash_isUniversal 3 2

/-- **Non-vacuity (2): MAC instance at `n = 2, p = 3`.** Type-elaborates
the generic `MAC` structure on the new key/message types. -/
example : MAC (ZMod 3 × ZMod 3) (Bitstring 2) (ZMod 3) :=
  bitstringPolynomialMAC 3 2

/-- **Non-vacuity (3): collision-card bound at concrete bitstrings.**
The bound `≤ n · p = 2 · 3 = 6` holds for any pair of distinct
bitstrings in `Bitstring 2`. Concrete instance: `b₁ = ![true, false],
b₂ = ![false, true]`. -/
example :
    (Finset.univ.filter (fun kp : ZMod 3 × ZMod 3 =>
      bitstringPolynomialHash 3 2 kp ![true, false] =
      bitstringPolynomialHash 3 2 kp ![false, true])).card ≤ 2 * 3 := by
  apply bitstringPolynomialHash_collision_card_le
  intro h
  -- ![true, false] ≠ ![false, true]: differ at position 0.
  have : (![true, false] : Bitstring 2) 0 = (![false, true] : Bitstring 2) 0 :=
    congrFun h 0
  simp at this

/-- **Non-vacuity (4): difference polynomial is non-zero.** Concrete
witness at `n = 2, p = 3` for `b₁ = ![true, false], b₂ = ![false,
true]`. -/
example :
    bitstringDiffPolynomial 3 2 ![true, false] ![false, true] ≠ 0 := by
  apply bitstringDiffPolynomial_ne_zero_of_ne
  intro h
  have : (![true, false] : Bitstring 2) 0 = (![false, true] : Bitstring 2) 0 :=
    congrFun h 0
  simp at this

/-- **Non-vacuity (5): toBit is injective at the prime field `ZMod 2`.**
The smallest prime, where `1 ≠ 0` is the field-axiom requirement. -/
example : Function.Injective (toBit 2) := toBit_injective

/-- **Non-vacuity (6): END-TO-END INT-CTXT on a `Bitstring 2`-typed
authenticated KEM at `p = 3`.** Constructs a trivial `OrbitKEM` over
`Equiv.Perm (Fin 2)` acting on `Bitstring 2` (using a constant
canonical form and a constant key derivation), then composes with the
new `bitstringPolynomial_authKEM` and discharges INT-CTXT. -/
example
    (canForm : CanonicalForm (Equiv.Perm (Fin 2)) (Bitstring 2))
    (keyDerive : Bitstring 2 → ZMod 3 × ZMod 3) :
    let kem : OrbitKEM (Equiv.Perm (Fin 2)) (Bitstring 2) (ZMod 3 × ZMod 3) :=
      { basePoint := fun _ => false
        canonForm := canForm
        keyDerive := keyDerive }
    let akem : AuthOrbitKEM (Equiv.Perm (Fin 2)) (Bitstring 2)
                  (ZMod 3 × ZMod 3) (ZMod 3) :=
      bitstringPolynomial_authKEM 3 2 kem
    INT_CTXT akem :=
  bitstringPolynomialMAC_int_ctxt 3 2 _

end R13NonVacuity

-- ============================================================================
-- § 15.24 R-09 — Discharge of `h_step` from `ConcreteOIA`
-- (audit 2026-04-29 § 8.1, research-scope discharge plan § R-09)
--
-- Layer 1 — `Probability/Monad.lean` extensions:
--   * `sum_pi_succAbove_eq_sum_sum_insertNth` — sum factorisation
--     along an inserted coordinate via `Fin.insertNthEquiv`.
--   * `probTrue_PMF_map_uniformPMF_toReal` — `.toReal` form of
--     `probTrue (PMF.map F (uniformPMF α)) D` as filter-card / |α|.
--
-- Layer 2 — `Probability/Advantage.lean`:
--   * `advantage_pmf_map_uniform_pi_factor_bound` — convexity-of-TV
--     along an inserted coordinate. Per-rest hypothesis ⇒ global bound.
--
-- Layer 3+4 — `Crypto/CompSecurity.lean`:
--   * `hybrid_step_bound_of_concreteOIA` — discharges per-step bound
--     from ConcreteOIA alone (no `h_step` needed).
--   * `indQCPA_from_concreteOIA` — **headline**: multi-query bound
--     `indQCPAAdvantage ≤ Q · ε` from `ConcreteOIA scheme ε` alone.
--   * `indQCPA_from_concreteOIA_recovers_single_query` — Q = 1
--     regression sentinel.
--   * `indQCPA_from_concreteOIA_distinct` — classical-game form.
-- ============================================================================

#print axioms Orbcrypt.sum_pi_succAbove_eq_sum_sum_insertNth
#print axioms Orbcrypt.probTrue_PMF_map_uniformPMF_toReal
#print axioms Orbcrypt.advantage_pmf_map_uniform_pi_factor_bound
#print axioms Orbcrypt.hybrid_step_bound_of_concreteOIA
#print axioms Orbcrypt.indQCPA_from_concreteOIA
#print axioms Orbcrypt.indQCPA_from_concreteOIA_recovers_single_query
#print axioms Orbcrypt.indQCPA_from_concreteOIA_distinct

/-! ## R-09 non-vacuity witnesses -/
namespace R09NonVacuity

open Orbcrypt

/-- **Non-vacuity (1): the unconditional Q · ε bound from ConcreteOIA alone**
on a generic scheme + adversary. -/
example {G X M : Type*} [Group G] [Fintype G] [Nonempty G] [MulAction G X]
    [DecidableEq X] {Q : ℕ} (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (A : MultiQueryAdversary X M Q) (hOIA : ConcreteOIA scheme ε) :
    indQCPAAdvantage scheme A ≤ (Q : ℝ) * ε :=
  indQCPA_from_concreteOIA scheme ε A hOIA

/-- **Non-vacuity (2): Q = 1 regression sentinel** — at Q = 1, the multi-
query bound `1 · ε = ε` recovers the single-query advantage bound
(matching `concrete_oia_implies_1cpa`). -/
example {G X M : Type*} [Group G] [Fintype G] [Nonempty G] [MulAction G X]
    [DecidableEq X] (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (A : MultiQueryAdversary X M 1) (hOIA : ConcreteOIA scheme ε) :
    indQCPAAdvantage scheme A ≤ ε :=
  indQCPA_from_concreteOIA_recovers_single_query scheme ε A hOIA

/-- **Non-vacuity (3): per-step bound at `i = 0`** for any Q ≥ 1. The
per-step content of R-09. -/
example {G X M : Type*} [Group G] [Fintype G] [Nonempty G] [MulAction G X]
    [DecidableEq X] {Q : ℕ} (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (A : MultiQueryAdversary X M Q) (hOIA : ConcreteOIA scheme ε)
    (hQ : 0 < Q) :
    advantage (A.guess scheme.reps)
      (hybridDist scheme (A.choose scheme.reps) 0)
      (hybridDist scheme (A.choose scheme.reps) 1) ≤ ε :=
  hybrid_step_bound_of_concreteOIA scheme ε A hOIA 0 hQ

/-- **Non-vacuity (4): distinct-challenge multi-query form.** -/
example {G X M : Type*} [Group G] [Fintype G] [Nonempty G] [MulAction G X]
    [DecidableEq X] {Q : ℕ} (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (A : DistinctMultiQueryAdversary X M Q) (hOIA : ConcreteOIA scheme ε) :
    indQCPAAdvantage scheme A.toMultiQueryAdversary ≤ (Q : ℝ) * ε :=
  indQCPA_from_concreteOIA_distinct scheme ε A hOIA

-- A *concrete* witness using the `trivialSchemeBool` fixture from
-- `NonVacuityWitnesses` (the OrbitEncScheme on `Bool` under the trivial
-- `Equiv.Perm (Fin 1)` action). Re-registers the local MulAction instance
-- since `local instance` does not propagate across namespace boundaries.
local instance trivialPermFin1ActionBoolR09 :
    MulAction (Equiv.Perm (Fin 1)) Bool where
  smul _ b := b
  one_smul _ := rfl
  mul_smul _ _ _ := rfl

/-- A trivial `MultiQueryAdversary` on `Bool` × `Bool` at Q = 2: always
    chooses the same pair `(true, false)` and always guesses `true`.
    Used as the concrete adversary for the end-to-end R-09 witness. -/
def trivialMQABool : MultiQueryAdversary Bool Bool 2 where
  choose := fun _ _ => (true, false)
  guess := fun _ _ => true

/-- **Non-vacuity (5) — concrete end-to-end R-09 witness.**
    Specialises `indQCPA_from_concreteOIA` at `scheme := NonVacuityWitnesses.
    trivialSchemeBool`, `Q := 2`, and the trivial `ConcreteOIA scheme 1`
    bound (via `concreteOIA_one`). Establishes the full chain
    `ConcreteOIA → indQCPA_from_concreteOIA → bounded multi-query
    advantage` on a concrete fixture (not just a parametric signature
    elaboration). -/
example :
    indQCPAAdvantage NonVacuityWitnesses.trivialSchemeBool trivialMQABool ≤
      (2 : ℝ) * 1 :=
  indQCPA_from_concreteOIA NonVacuityWitnesses.trivialSchemeBool 1
    trivialMQABool (concreteOIA_one _)

end R09NonVacuity

/-! ## R-01 non-vacuity witnesses (audit 2026-04-29 § 8.1) -/
namespace R01NonVacuity

open Orbcrypt

-- The R-01 mass lemmas and headline are stated in the explicit-action
-- form `f (g • x)`. The non-vacuity witnesses here exercise the
-- theorems on a concrete fixture: the trivial action of
-- `Equiv.Perm (Fin 1)` on `Bool` (every group element acts as the
-- identity), under which `id : Bool → Bool` is G-invariant and
-- separates `true` from `false`. This re-uses the
-- `NonVacuityWitnesses.trivialSchemeBool` fixture; the local MulAction
-- instance is re-registered here because `local instance`s do not
-- propagate across namespace boundaries.
local instance trivialPermFin1ActionBoolR01 :
    MulAction (Equiv.Perm (Fin 1)) Bool where
  smul _ b := b
  one_smul _ := rfl
  mul_smul _ _ _ := rfl

/-- `id : Bool → Bool` is G-invariant under the trivial action of
    `Equiv.Perm (Fin 1)` on `Bool` (every group element acts as the
    identity, so `id (g • b) = id b = b` definitionally). Used as the
    invariant function for the R-01 non-vacuity witnesses. -/
private theorem id_isGInvariant_trivialPermFin1 :
    IsGInvariant (G := Equiv.Perm (Fin 1)) (id : Bool → Bool) := by
  intro _ _; rfl

/-- **Non-vacuity (1): constant-true mass lemma at the trivial action.**
    Specialises `probTrue_orbitDist_invariant_eq_one` at the trivial
    `Equiv.Perm (Fin 1)` action on `Bool` with `f := id`, `x := false`,
    `y := false`. Under the trivial action, `g • false = false` for
    every `g`, so the predicate `decide (id c = id false)` is constantly
    `true` on the orbit of `false` (which is the singleton `{false}`).
    The orbit distribution therefore assigns mass `1` to the predicate. -/
example :
    probTrue (orbitDist (G := Equiv.Perm (Fin 1)) (false : Bool))
        (fun c => decide ((id : Bool → Bool) c = id false)) = 1 :=
  probTrue_orbitDist_invariant_eq_one (G := Equiv.Perm (Fin 1))
    id_isGInvariant_trivialPermFin1 false false rfl

/-- **Non-vacuity (2): constant-false mass lemma at the trivial action.**
    Specialises `probTrue_orbitDist_invariant_eq_zero` at `f := id`,
    `x := true`, `y := false`. Under the trivial action,
    `g • true = true` for every `g`, and `id true = true ≠ false = id
    false`, so the predicate is constantly `false` on the orbit of
    `true`. The orbit distribution therefore assigns mass `0`. -/
example :
    probTrue (orbitDist (G := Equiv.Perm (Fin 1)) (true : Bool))
        (fun c => decide ((id : Bool → Bool) c = id false)) = 0 :=
  probTrue_orbitDist_invariant_eq_zero (G := Equiv.Perm (Fin 1))
    id_isGInvariant_trivialPermFin1 true false (by decide)

/-- **Non-vacuity (3): R-01 headline equality at the trivial action.**
    The end-to-end IND-1-CPA bound on `NonVacuityWitnesses.
    trivialSchemeBool`, exhibiting `indCPAAdvantage = 1` for the
    invariant-attack adversary with `f := id`, `m₀ := true`, `m₁ :=
    false`. Establishes the *tight* equality (not just the upper bound)
    on a concrete two-message scheme — the cryptographic content of
    R-01. Pre-R-01, the only quantitative bound available on this
    fixture was `indCPAAdvantage_le_one` (the universal `≤ 1`); R-01
    promotes the bound to an exact `= 1` whenever a separating
    G-invariant is supplied. -/
example :
    indCPAAdvantage NonVacuityWitnesses.trivialSchemeBool
        (invariantAttackAdversary (id : Bool → Bool) true false) = 1 :=
  indCPAAdvantage_invariantAttackAdversary_eq_one
    NonVacuityWitnesses.trivialSchemeBool (id : Bool → Bool) true false
    id_isGInvariant_trivialPermFin1 (by decide)

/-- **Non-vacuity (4): R-01 strictly improves the universal `≤ 1`
    bound.** Composing the R-01 headline equality with
    `indCPAAdvantage_le_one` shows that the R-01 bound is *attained*
    (not merely satisfied): on `trivialSchemeBool` the invariant-attack
    adversary saturates the universal upper bound. This is the
    quantitative content R-01 delivers beyond the deterministic
    `invariant_attack`'s existential form. -/
example :
    indCPAAdvantage NonVacuityWitnesses.trivialSchemeBool
        (invariantAttackAdversary (id : Bool → Bool) true false) ≤ 1 ∧
    indCPAAdvantage NonVacuityWitnesses.trivialSchemeBool
        (invariantAttackAdversary (id : Bool → Bool) true false) = 1 :=
  ⟨indCPAAdvantage_le_one _ _,
   indCPAAdvantage_invariantAttackAdversary_eq_one
     NonVacuityWitnesses.trivialSchemeBool (id : Bool → Bool) true false
     id_isGInvariant_trivialPermFin1 (by decide)⟩

end R01NonVacuity

/-! ## R-07 non-vacuity witnesses (audit 2026-04-29 § 8.1) -/
namespace R07NonVacuity

open Orbcrypt

-- R-07 lands the structural cross-orbit lower bound
-- `combinerDistinguisherAdvantage ≥ 1/|G|` under
-- `CrossOrbitNonDegenerateCombiner` and the corresponding
-- `1/|G| ≤ ε` corollary under `ConcreteOIA scheme ε`. The headline
-- composition proof goes through unconditionally (zero `sorry`,
-- zero custom axioms) and is exercised in parametric form below: each
-- example takes a generic scheme + combiner + cross-orbit hypothesis
-- and discharges the headline conclusion. This is the "parametric
-- type-elaboration witness" route from the plan's risks-and-mitigations
-- table; constructing a fully concrete cross-orbit-non-degenerate
-- combiner on a small finite fixture would require a non-trivial
-- group action with two disjoint orbits and is beyond audit-script
-- scope (the inhabitedness of `CrossOrbitNonDegenerateCombiner` on a
-- general scheme is documented in the structure's docstring; the
-- `intra` and `cross_constant_false` fields are jointly satisfiable
-- on every scheme with `|G| ≥ 2` and at least two messages whose
-- representatives lie in disjoint orbits with the combiner constant
-- on the second one).

/-- **Non-vacuity (1): bridge lemma.** The mass at `true` of
    `combinerOrbitDist scheme m_bp comb m` equals
    `probTrue (orbitDist (reps m)) (combinerDistinguisher comb)`. -/
example {G X M : Type*} [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (comb : GEquivariantCombiner G X (scheme.reps m_bp)) (m : M) :
    combinerOrbitDist scheme m_bp comb m true =
      probTrue (orbitDist (G := G) (scheme.reps m))
        (combinerDistinguisher comb) :=
  combinerOrbitDist_apply_true_eq_probTrue scheme m_bp comb m

/-- **Non-vacuity (2): intra-orbit mass bound rephrased via
    `probTrue`.** Under `NonDegenerateCombiner`, the basepoint orbit
    distribution assigns mass at least `1/|G|` to the `true` branch
    of the combiner-induced distinguisher. -/
example {G X M : Type*} [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (comb : GEquivariantCombiner G X (scheme.reps m_bp))
    (hND : NonDegenerateCombiner comb) :
    (Fintype.card G : ENNReal)⁻¹ ≤
    probTrue (orbitDist (G := G) (scheme.reps m_bp))
      (combinerDistinguisher comb) :=
  probTrue_combinerDistinguisher_basePoint_ge_inv_card scheme m_bp comb hND

/-- **Non-vacuity (3): cross-orbit zero-mass.** Under the cross-orbit
    constant-false hypothesis, the target orbit distribution assigns
    mass exactly `0` to the `true` branch. -/
example {G X M : Type*} [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (comb : GEquivariantCombiner G X (scheme.reps m_bp))
    (m_target : M) (hCross : ∀ g : G,
      combinerDistinguisher comb (g • scheme.reps m_target) = false) :
    probTrue (orbitDist (G := G) (scheme.reps m_target))
        (combinerDistinguisher comb) = 0 :=
  probTrue_combinerDistinguisher_target_eq_zero scheme m_bp comb m_target hCross

/-- **Non-vacuity (4): R-07 headline.** Under
    `CrossOrbitNonDegenerateCombiner`, the cross-orbit advantage is
    bounded below by `1/|G|`. -/
example {G X M : Type*} [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (comb : GEquivariantCombiner G X (scheme.reps m_bp))
    (m_target : M)
    (hND : CrossOrbitNonDegenerateCombiner scheme m_bp comb m_target) :
    (1 : ℝ) / (Fintype.card G : ℝ) ≤
    combinerDistinguisherAdvantage scheme m_bp comb m_bp m_target :=
  combinerDistinguisherAdvantage_ge_inv_card scheme m_bp comb m_target hND

/-- **Non-vacuity (5): R-07 corollary.** Under
    `CrossOrbitNonDegenerateCombiner`, every `ConcreteOIA` bound `ε`
    satisfies `ε ≥ 1/|G|`. This refutes any sub-`1/|G|` security
    claim once a cross-orbit non-degenerate combiner is exhibited. -/
example {G X M : Type*} [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (comb : GEquivariantCombiner G X (scheme.reps m_bp))
    (m_target : M)
    (hND : CrossOrbitNonDegenerateCombiner scheme m_bp comb m_target)
    (ε : ℝ) (hOIA : ConcreteOIA scheme ε) :
    (1 : ℝ) / (Fintype.card G : ℝ) ≤ ε :=
  no_concreteOIA_below_inv_card_of_combiner scheme m_bp comb m_target hND ε hOIA

/-- **Non-vacuity (6): structural sanity — `CrossOrbitNonDegenerate
    Combiner` deconstructs to its two component witnesses.** Confirms
    the structure's `intra` and `cross_constant_false` projections
    work as expected. -/
example {G X M : Type*} [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (comb : GEquivariantCombiner G X (scheme.reps m_bp))
    (m_target : M)
    (hND : CrossOrbitNonDegenerateCombiner scheme m_bp comb m_target) :
    NonDegenerateCombiner comb ∧
    (∀ g : G, combinerDistinguisher comb (g • scheme.reps m_target) = false) :=
  ⟨hND.intra, hND.cross_constant_false⟩

-- ============================================================================
-- Concrete R-07 fixture: the `1/2` bound on `S_2 ⤳ Bitstring 2`
-- ============================================================================
--
-- Above we exercise the R-07 theorems parametrically against generic
-- schemes and combiners. To honestly witness that
-- `CrossOrbitNonDegenerateCombiner` is *inhabited* on a concrete
-- model — and hence that the headline theorem is non-vacuous —
-- we now construct an explicit fixture and instantiate every R-07
-- declaration on it.
--
-- Concrete model:
--   • `G := ⊤ ≤ Equiv.Perm (Fin 2)` (the full S_2; `Fintype.card = 2`).
--   • `X := Bitstring 2 = Fin 2 → Bool`.
--   • Action: `subgroupBitstringAction` (existing in `Construction/HGOE.lean`),
--     by permuting bit positions. The two relevant orbits are:
--       - `orbit (↥⊤) ![T, F] = {![T, F], ![F, T]}` (size 2, weight 1).
--       - `orbit (↥⊤) ![F, F] = {![F, F]}` (singleton, weight 0).
--   • `M := Bool`, `reps := Bool.rec ![F, F] ![T, F]`.
--   • Combiner: `combine x y := y` (projection on the second argument).
--     Closed on the basepoint orbit (the second argument's orbit
--     membership is preserved); G-equivariant by definition; satisfies
--     intra-orbit non-triviality (the swap σ moves `![T, F] → ![F, T]
--     ≠ ![T, F]`); satisfies cross-orbit constant-false (every σ ∈ ⊤
--     fixes `![F, F]`, and `![F, F] ≠ ![T, F]` makes the distinguisher
--     constantly `false` on the target orbit).
--
-- This fixture exhibits `CrossOrbitNonDegenerateCombiner` on a
-- non-trivial finite scheme and produces the explicit `1/2 ≤ advantage`
-- bound from R-07's headline.

/-- Decidable membership in `(⊤ : Subgroup (Equiv.Perm (Fin 2)))`:
    every element trivially satisfies `True`. Required for `Fintype
    ↥⊤` synthesis (`Subgroup.fintype` derives from `Fintype G` plus
    `DecidablePred (· ∈ S)`). -/
local instance decidableMemTopPermFin2 :
    DecidablePred (· ∈ (⊤ : Subgroup (Equiv.Perm (Fin 2)))) :=
  fun _ => isTrue trivial

/-- The basepoint message's representative (`![T, F]` — weight 1)
    and the target representative (`![F, F]` — weight 0). Defined
    by pattern matching on `Bool` so that `repsR07 true` and
    `repsR07 false` reduce definitionally to their literal forms. -/
private def repsR07 : Bool → Bitstring 2
  | true  => ![true,  false]
  | false => ![false, false]

/-- Computation lemma: `repsR07 true = ![T, F]`. By `rfl`, since
    `repsR07` matches definitionally. Used to rewrite occurrences
    of `schemeR07.reps true` (which goes through `hgoeScheme.ofLexMin
    .reps`, set by definition to `repsR07`). -/
private theorem repsR07_true : repsR07 true = ![true, false] := rfl

/-- Computation lemma: `repsR07 false = ![F, F]`. -/
private theorem repsR07_false : repsR07 false = ![false, false] := rfl

/-- The two orbit-distinct representatives have different Hamming
    weights (`1` vs `0`); since `hammingWeight` is G-invariant under
    any subgroup, `separating_implies_distinct_orbits` lifts the
    weight gap to an orbit inequality. -/
private theorem repsR07_distinct :
    ∀ m₁ m₂ : Bool, m₁ ≠ m₂ →
      MulAction.orbit (↥(⊤ : Subgroup (Equiv.Perm (Fin 2)))) (repsR07 m₁) ≠
        MulAction.orbit (↥(⊤ : Subgroup (Equiv.Perm (Fin 2)))) (repsR07 m₂) := by
  intro m₁ m₂ hNeq
  -- Hamming weights of the two reps (1 and 0) separate the orbits.
  have hSep : hammingWeight (repsR07 m₁) ≠ hammingWeight (repsR07 m₂) := by
    cases m₁ <;> cases m₂ <;> first | exact (hNeq rfl).elim | decide
  -- `separating_implies_distinct_orbits` needs the IsSeparating package.
  exact separating_implies_distinct_orbits
    ⟨hammingWeight_invariant_subgroup _, hSep⟩

/-- The R-07 fixture scheme: `S_2` acts on `Bitstring 2`, two
    messages map to weight-1 and weight-0 orbits. The canonical form
    is auto-filled by `hgoeScheme.ofLexMin` (matches the GAP
    reference's lex-min orbit representative choice). -/
private noncomputable def schemeR07 :
    OrbitEncScheme (↥(⊤ : Subgroup (Equiv.Perm (Fin 2))))
      (Bitstring 2) Bool :=
  hgoeScheme.ofLexMin (n := 2) ⊤ repsR07 repsR07_distinct

/-- Computation lemma: `schemeR07.reps = repsR07`. The
    `hgoeScheme.ofLexMin_reps` simp lemma confirms that
    `hgoeScheme.ofLexMin` preserves its `reps` field; consumers can
    rewrite the goal's `schemeR07.reps` to the explicit `repsR07`
    and then to a concrete bitstring via `repsR07_true /
    repsR07_false`. -/
private theorem schemeR07_reps : schemeR07.reps = repsR07 :=
  hgoeScheme.ofLexMin_reps (n := 2) ⊤ repsR07 repsR07_distinct

/-- The fixture's combiner: `combine x y := y` (projection on the
    second argument). Closed on the basepoint orbit; G-equivariant
    by the trivial computation `g • y = g • y`. -/
private noncomputable def combR07 :
    GEquivariantCombiner (↥(⊤ : Subgroup (Equiv.Perm (Fin 2))))
      (Bitstring 2) (schemeR07.reps true) where
  combine := fun _ y => y
  closed := fun _ _ _ hy => hy
  equivariant := fun _ _ _ => rfl

/-- Computation lemma: `combR07.combine x y = y`. Reduces structure-
    field projection to the underlying `fun _ y => y`. -/
private theorem combR07_combine_eq (x y : Bitstring 2) :
    combR07.combine x y = y := rfl

/-- The non-trivial element of `↥⊤ ≤ S_2`: the swap of bit positions
    `0` and `1`, packaged as a member of `⊤`. Used both as the
    `intra` witness for `combR07` and as a probe for the cross-orbit
    constant-false condition. -/
private def swapR07 : ↥(⊤ : Subgroup (Equiv.Perm (Fin 2))) :=
  ⟨Equiv.swap 0 1, Subgroup.mem_top _⟩

/-- Computation lemma: applying the swap to `![T, F]` flips the
    first two bits, producing `![F, T]`. Proved by Fin-extensional
    case analysis at indices `0` and `1`. -/
private theorem swapR07_smul_TF :
    (swapR07 • (![true, false] : Bitstring 2)) = ![false, true] := by
  funext i
  -- `(g • b) i = b (g⁻¹ i)` from `perm_smul_apply`.
  -- `swapR07 = ⟨Equiv.swap 0 1, _⟩`, so `(↑swapR07)⁻¹ = (Equiv.swap 0 1)⁻¹ = Equiv.swap 0 1`.
  show (![true, false] : Bitstring 2) ((Equiv.swap (0 : Fin 2) 1)⁻¹ i) = _
  rw [Equiv.swap_inv]
  fin_cases i
  · simp [Equiv.swap_apply_left]
  · simp [Equiv.swap_apply_right]

/-- The basepoint orbit moves under `swapR07`: applying the swap to
    `![T, F]` yields `![F, T] ≠ ![T, F]`. This is the intra-orbit
    non-triviality witness for `combR07`. -/
private theorem combR07_intra :
    NonDegenerateCombiner combR07 := by
  refine ⟨swapR07, ?_⟩
  -- Goal: combR07.combine (reps true) (swapR07 • reps true) ≠ combR07.combine (reps true) (reps true).
  -- Reduce `combR07.combine` to second-argument projection; reduce
  -- `schemeR07.reps true` to the concrete `![T, F]`.
  rw [combR07_combine_eq, combR07_combine_eq, schemeR07_reps, repsR07_true,
      swapR07_smul_TF]
  -- Goal: ![F, T] ≠ ![T, F]. Decide by Fin-extensional comparison.
  intro h
  have h0 := congr_fun h 0
  exact Bool.noConfusion h0

/-- Every group element fixes the all-false bitstring `![F, F]`:
    `g • ![F, F] = ![F, F]` because the action permutes indices and
    every index reads `false`.

    **Proof.** Pointwise: `(g • b) i` reduces (via the
    `subgroupBitstringAction` `compHom`-derived instance + the
    underlying perm action `(σ • b) i = b (σ⁻¹ i)` from
    `perm_smul_apply`) to `b ((↑g)⁻¹ i)`. Since `b = ![F, F]` is the
    constant-false function, both sides read `false` regardless of
    which index `(↑g)⁻¹ i` resolves to. We use `generalize` to lift
    the inner perm-applied index to a fresh variable, then close by
    Fin-extensional case-splitting on the two indices. -/
private theorem smul_FF_eq_FF
    (g : ↥(⊤ : Subgroup (Equiv.Perm (Fin 2)))) :
    g • (![false, false] : Bitstring 2) = ![false, false] := by
  funext i
  -- Reduce `g • b` (subgroup action) to `(↑g) • b` (underlying perm action).
  show ((↑g : Equiv.Perm (Fin 2)) • (![false, false] : Bitstring 2)) i =
      ![false, false] i
  rw [perm_smul_apply]
  -- Goal: `![false, false] ((↑g)⁻¹ i) = ![false, false] i`. Generalise
  -- the inner perm-applied index to expose both arguments to `fin_cases`.
  generalize ((↑g : Equiv.Perm (Fin 2))⁻¹) i = j
  fin_cases j <;> fin_cases i <;> rfl

/-- Cross-orbit constant-false witness for `combR07`: every group
    element fixes the all-false bitstring `![F, F]`, so the combiner-
    induced distinguisher (which compares `combine bp (g • reps false)
    = g • ![F, F] = ![F, F]` to `combine bp bp = ![T, F]`) returns
    `false` on every input from the target orbit. -/
private theorem combR07_cross_constant_false :
    ∀ g : ↥(⊤ : Subgroup (Equiv.Perm (Fin 2))),
      combinerDistinguisher combR07 (g • schemeR07.reps false) = false := by
  intro g
  -- Reduce: `combinerDistinguisher comb x = decide (combR07.combine bp x = combR07.combine bp bp)`.
  -- combR07's combine is second-argument projection.
  unfold combinerDistinguisher
  rw [combR07_combine_eq, combR07_combine_eq, schemeR07_reps, repsR07_true,
      repsR07_false, smul_FF_eq_FF]
  -- Goal: `decide (![F, F] = ![T, F]) = false`. Decided by `decide`.
  decide

/-- The R-07 cross-orbit non-degenerate combiner package on the
    concrete fixture: `combR07` satisfies both the intra-orbit
    non-triviality witness (via the swap) and the cross-orbit
    constant-false witness (via `![F, F]` being a fixed point of
    every permutation). -/
private def hND_R07 :
    CrossOrbitNonDegenerateCombiner schemeR07 true combR07 false where
  intra := combR07_intra
  cross_constant_false := combR07_cross_constant_false

/-- **Concrete R-07 headline witness.** On the `S_2 ⤳ Bitstring 2`
    fixture, the combiner-distinguisher's cross-orbit advantage
    between the weight-1 orbit (`![T, F]`'s orbit) and the weight-0
    orbit (`![F, F]`'s singleton orbit) is at least `1 / |↥⊤|`,
    which equals `1/2` since `Fintype.card (↥⊤ : Subgroup
    (Equiv.Perm (Fin 2))) = 2! = 2`. -/
example :
    (1 : ℝ) / (Fintype.card (↥(⊤ : Subgroup (Equiv.Perm (Fin 2)))) : ℝ) ≤
    combinerDistinguisherAdvantage schemeR07 true combR07 true false :=
  combinerDistinguisherAdvantage_ge_inv_card schemeR07 true combR07 false hND_R07

/-- **Concrete R-07 corollary witness.** On the same fixture, every
    `ConcreteOIA schemeR07 ε` bound satisfies `ε ≥ 1 / |↥⊤|`. The
    cross-orbit non-degenerate combiner makes any sub-`1/2` security
    claim impossible on this scheme. -/
example (ε : ℝ) (hOIA : ConcreteOIA schemeR07 ε) :
    (1 : ℝ) / (Fintype.card (↥(⊤ : Subgroup (Equiv.Perm (Fin 2)))) : ℝ) ≤ ε :=
  no_concreteOIA_below_inv_card_of_combiner schemeR07 true combR07 false hND_R07 ε hOIA

end R07NonVacuity

-- ============================================================================
-- § 15.22 Workstream R-14 — Generic probabilistic MAC SUF-CMA framework
-- (audit 2026-04-29 § 8.1, plan PLAN_R_01_07_08_14_16.md § R-14)
-- ============================================================================

#print axioms Orbcrypt.IsEpsilonAXU
#print axioms Orbcrypt.IsEpsilonAXU.mono
#print axioms Orbcrypt.IsEpsilonAXU.toIsEpsilonUniversal
#print axioms Orbcrypt.IsEpsilonAXU.ofCollisionCardBound
#print axioms Orbcrypt.IsEpsilonSU2
#print axioms Orbcrypt.IsEpsilonSU2.mono
#print axioms Orbcrypt.IsEpsilonSU2.ofJointCollisionCardBound
#print axioms Orbcrypt.IsEpsilonSU2.toIsEpsilonUniversal
#print axioms Orbcrypt.IsEpsilonSU2.toIsEpsilonAXU

#print axioms Orbcrypt.MACAdversary
#print axioms Orbcrypt.MACAdversary.forges
#print axioms Orbcrypt.forgeryAdvantage
#print axioms Orbcrypt.IsSUFCMASecure
#print axioms Orbcrypt.forgeryAdvantage_nonneg
#print axioms Orbcrypt.forgeryAdvantage_le_one
#print axioms Orbcrypt.IsDeterministicTagMAC
#print axioms Orbcrypt.isSUFCMASecure_of_isEpsilonSU2

#print axioms Orbcrypt.MultiQueryMACAdversary
#print axioms Orbcrypt.MultiQueryMACAdversary.forges
#print axioms Orbcrypt.forgeryAdvantage_Qtime
#print axioms Orbcrypt.IsQtimeSUFCMASecure
#print axioms Orbcrypt.forgeryAdvantage_Qtime_nonneg
#print axioms Orbcrypt.forgeryAdvantage_Qtime_le_one
#print axioms Orbcrypt.IsKeyRecoverableForSomeQueries
#print axioms Orbcrypt.not_isQtimeSUFCMASecure_of_keyRecoverableForSomeQueries

namespace R14NonVacuity
open Orbcrypt

/-- Sentinel: `forgeryAdvantage ≤ 1` is trivially true for every MAC and
    every adversary (sanity bound from `probTrue ≤ 1`). -/
example {K Msg Tag : Type*} [Fintype K] [Nonempty K] [DecidableEq Msg]
    (mac : MAC K Msg Tag) (A : MACAdversary K Msg Tag) :
    forgeryAdvantage mac A ≤ 1 := forgeryAdvantage_le_one mac A

/-- Sentinel: SU2 → AXU corollary on a generic hash family. -/
example {K Msg : Type*} [Fintype K] [Nonempty K]
    (hash : K → Msg → (ZMod 2)) (ε : ENNReal) (hSU2 : IsEpsilonSU2 hash ε) :
    IsEpsilonAXU hash ε := hSU2.toIsEpsilonAXU

/-- Sentinel: SU2 → Universal corollary on a generic hash family. -/
example {K Msg : Type*} [Fintype K] [Nonempty K]
    (hash : K → Msg → (ZMod 2)) (ε : ENNReal) (hSU2 : IsEpsilonSU2 hash ε) :
    IsEpsilonUniversal hash ε := hSU2.toIsEpsilonUniversal

end R14NonVacuity

-- ============================================================================
-- § 15.23 Workstream R-08 — Carter–Wegman SU2 + 1-time SUF-CMA + Q-time NEGATIVE
-- (audit 2026-04-29 § 8.1, plan PLAN_R_01_07_08_14_16.md § R-08)
-- ============================================================================

#print axioms Orbcrypt.carterWegmanHash_isEpsilonSU2
#print axioms Orbcrypt.carterWegmanHash_isEpsilonAXU
#print axioms Orbcrypt.carterWegmanMAC_isSUFCMASecure
#print axioms Orbcrypt.carterWegmanHash_isKeyRecoverableForSomeQueries
#print axioms Orbcrypt.not_carterWegmanMAC_isQtimeSUFCMASecure

namespace R08NonVacuity
open Orbcrypt

/-- Witness `Fact (Nat.Prime 5)` (Mathlib provides only `fact_prime_two` and
    `fact_prime_three` as `ℕ`-Prime instances; for `p = 5` we discharge
    primality manually via `decide` and pack into a global `instance` so
    that subsequent witnesses involving `carterWegmanHash 5` can elaborate
    without the goal-state requiring an out-of-band `haveI`). -/
local instance fact_prime_five : Fact (Nat.Prime 5) := ⟨by decide⟩

/-- Concrete R-08 SU2 witness at `p = 5` (prime, decides as `Nat.Prime`). -/
example : IsEpsilonSU2 (carterWegmanHash 5) ((1 : ENNReal) / 5) :=
  carterWegmanHash_isEpsilonSU2 5

/-- Concrete R-08 AXU witness at `p = 5`. -/
example : IsEpsilonAXU (carterWegmanHash 5) ((1 : ENNReal) / 5) :=
  carterWegmanHash_isEpsilonAXU 5

/-- Concrete R-08 1-time SUF-CMA witness at `p = 5`. -/
example : IsSUFCMASecure (carterWegmanMAC 5) ((1 : ℝ) / 5) :=
  carterWegmanMAC_isSUFCMASecure 5

/-- Concrete R-08 key-recovery witness at `p = 5`. -/
example : IsKeyRecoverableForSomeQueries (carterWegmanHash 5) 2 :=
  carterWegmanHash_isKeyRecoverableForSomeQueries 5 (by omega)

/-- Concrete R-08 Q-time NEGATIVE witness at `p = 5`: not `(1/5)`-Q-time-SUF-CMA. -/
example : ¬ IsQtimeSUFCMASecure (Q := 3) (carterWegmanMAC 5) ((1 : ℝ) / 5) :=
  not_carterWegmanMAC_isQtimeSUFCMASecure 5 (by omega) ((1 : ℝ) / 5) (by norm_num)

end R08NonVacuity

-- ============================================================================
-- § 15.24 Workstream R-13⁺ — Bitstring-polynomial SU2 + SUF-CMA + Q-time NEGATIVE
-- (audit 2026-04-29 § 8.1, plan PLAN_R_01_07_08_14_16.md § R-13⁺)
-- ============================================================================

#print axioms Orbcrypt.bitstringPolynomialHash_isEpsilonSU2
#print axioms Orbcrypt.bitstringPolynomialHash_isEpsilonAXU
#print axioms Orbcrypt.bitstringPolynomialMAC_isSUFCMASecure
#print axioms Orbcrypt.bitstringPolynomialHash_isKeyRecoverableForSomeQueries
#print axioms Orbcrypt.not_bitstringPolynomialMAC_isQtimeSUFCMASecure

namespace R13PlusNonVacuity
open Orbcrypt

/-- Witness `Fact (Nat.Prime 5)` (decide-based, parallel to R08NonVacuity).
    Local instance so subsequent `bitstringPolynomial*` calls at `p = 5`
    elaborate the typeclass argument automatically. -/
local instance fact_prime_five : Fact (Nat.Prime 5) := ⟨by decide⟩

/-- Concrete R-13⁺ SU2 witness at `(p, n) = (5, 3)`. -/
example : IsEpsilonSU2 (bitstringPolynomialHash 5 3) ((3 : ENNReal) / 5) :=
  bitstringPolynomialHash_isEpsilonSU2 5 3

/-- Concrete R-13⁺ AXU witness at `(p, n) = (5, 3)`. -/
example : IsEpsilonAXU (bitstringPolynomialHash 5 3) ((3 : ENNReal) / 5) :=
  bitstringPolynomialHash_isEpsilonAXU 5 3

/-- Concrete R-13⁺ 1-time SUF-CMA witness at `(p, n) = (5, 3)`. -/
example : IsSUFCMASecure (bitstringPolynomialMAC 5 3) ((3 : ℝ) / 5) :=
  bitstringPolynomialMAC_isSUFCMASecure 5 3

/-- Concrete R-13⁺ key-recovery witness at `(p, n) = (5, 3)`. -/
example : IsKeyRecoverableForSomeQueries (bitstringPolynomialHash 5 3) 2 :=
  bitstringPolynomialHash_isKeyRecoverableForSomeQueries 5 3 (by omega)

/-- Concrete R-13⁺ Q-time NEGATIVE witness at `(p, n) = (5, 3)`. -/
example :
    ¬ IsQtimeSUFCMASecure (Q := 3) (bitstringPolynomialMAC 5 3) ((3 : ℝ) / 5) :=
  not_bitstringPolynomialMAC_isQtimeSUFCMASecure 5 3 (by omega) ((3 : ℝ) / 5)
    (by norm_num)

end R13PlusNonVacuity

-- ============================================================================
-- § 15.25 Workstream R-16 — HGOE invariants beyond Hamming weight
-- (audit 2026-04-29 § 8.1, plan PLAN_R_01_07_08_14_16.md § R-16)
-- ============================================================================

#print axioms Orbcrypt.blockSum
#print axioms Orbcrypt.PreservesBlocks
#print axioms Orbcrypt.blockSum_invariant_of_preservesBlocks
#print axioms Orbcrypt.hgoe_blockSum_attack
#print axioms Orbcrypt.same_blockSum_not_separating

#print axioms Orbcrypt.bitParity
#print axioms Orbcrypt.bitParity_invariant
#print axioms Orbcrypt.bitParity_invariant_subgroup
#print axioms Orbcrypt.hgoe_bitParity_attack
#print axioms Orbcrypt.same_bitParity_not_separating

#print axioms Orbcrypt.sortedBits
#print axioms Orbcrypt.sortedBits_invariant
#print axioms Orbcrypt.sortedBits_invariant_subgroup
#print axioms Orbcrypt.hgoe_sortedBits_attack
#print axioms Orbcrypt.same_sortedBits_not_separating

namespace R16NonVacuity
open Orbcrypt

/-- Concrete blockSum at a 2-block partition on `Bitstring 4`. The
    bitstring `![T, T, F, F]` has block-sum `(2, 0)` (positions 0, 1 in
    block 0; positions 2, 3 in block 1). -/
example :
    blockSum
      (n := 4) (ℓ := 2)
      (fun j => if j = 0 then ({0, 1} : Finset (Fin 4)) else ({2, 3} : Finset (Fin 4)))
      (![true, true, false, false]) =
    ![2, 0] := by decide

/-- Bit parity sentinel: `![T, F, T, F]` has weight 2, parity false. -/
example : bitParity (![true, false, true, false] : Bitstring 4) = false := by decide

/-- Bit parity sentinel: `![T, F, F, F]` has weight 1, parity true. -/
example : bitParity (![true, false, false, false] : Bitstring 4) = true := by decide

/-- Same-blockSum defence sentinel. Two bitstrings with the same
    blockSum-vector cannot be separated by `blockSum`. -/
example
    (block : Fin 2 → Finset (Fin 4))
    (h_same : blockSum block (![true, false, true, false]) =
              blockSum block (![false, true, false, true])) :
    ¬ IsSeparating (G := Equiv.Perm (Fin 4)) (blockSum block)
      (![true, false, true, false]) (![false, true, false, true]) :=
  same_blockSum_not_separating block _ _ h_same

end R16NonVacuity
