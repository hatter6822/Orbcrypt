import Orbcrypt.GroupAction.Basic
import Orbcrypt.GroupAction.Canonical
import Orbcrypt.GroupAction.Invariant

import Orbcrypt.Crypto.Scheme
import Orbcrypt.Crypto.Security
import Orbcrypt.Crypto.OIA

import Orbcrypt.Theorems.Correctness
import Orbcrypt.Theorems.InvariantAttack
import Orbcrypt.Theorems.OIAImpliesCPA

import Orbcrypt.KEM.Syntax
import Orbcrypt.KEM.Encapsulate
import Orbcrypt.KEM.Correctness
import Orbcrypt.KEM.Security

import Orbcrypt.Probability.Monad
import Orbcrypt.Probability.Negligible
import Orbcrypt.Probability.Advantage
import Orbcrypt.Probability.UniversalHash

import Orbcrypt.Crypto.CompOIA
import Orbcrypt.Crypto.CompSecurity

import Orbcrypt.KEM.CompSecurity

import Orbcrypt.Construction.Permutation
import Orbcrypt.Construction.HGOE
import Orbcrypt.Construction.HGOEKEM

import Orbcrypt.KeyMgmt.SeedKey
import Orbcrypt.KeyMgmt.Nonce

import Orbcrypt.AEAD.MAC
import Orbcrypt.AEAD.AEAD
import Orbcrypt.AEAD.Modes
import Orbcrypt.AEAD.CarterWegmanMAC

import Orbcrypt.Hardness.CodeEquivalence
import Orbcrypt.Hardness.TensorAction
import Orbcrypt.Hardness.Encoding
import Orbcrypt.Hardness.Reductions

import Orbcrypt.PublicKey.ObliviousSampling
import Orbcrypt.PublicKey.KEMAgreement
import Orbcrypt.PublicKey.CommutativeAction
import Orbcrypt.PublicKey.CombineImpossibility

import Orbcrypt.Optimization.QCCanonical
import Orbcrypt.Optimization.TwoPhaseDecrypt

/-!
# Orbcrypt — Formal Verification of Permutation-Orbit Encryption

This is the root import file. Importing `Orbcrypt` gives access to the
complete formalization: group action foundations, cryptographic definitions,
core theorems, the concrete HGOE construction, the KEM reformulation,
the probabilistic security foundations (Phase 8), the key compression
and nonce-based encryption module (Phase 9), the authenticated
encryption and hybrid modes layer (Phase 10), the hardness
alignment with NIST PQC candidates (Phase 12), and the public-key
extension scaffolding (Phase 13).

## Module Dependency Graph

External dependencies (Mathlib):
- `Mathlib.GroupTheory.GroupAction.Defs` — `MulAction`, `orbit`, `stabilizer`
- `Mathlib.GroupTheory.GroupAction.Quotient` — orbit equivalence relation
- `Mathlib.GroupTheory.Perm.Basic` — `Equiv.Perm` (symmetric group)
- `Mathlib.Probability.ProbabilityMassFunction.*` — `PMF` type (Phase 8)
- `Mathlib.Probability.Distributions.Uniform` — `PMF.uniformOfFintype` (Phase 8)
- `Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup.Defs` — `GL` type (Phase 12)
- `Mathlib.Analysis.SpecificLimits.Basic` — negligible function bounds (Phase 8)

Internal module imports:

```text
Mathlib.GroupTheory.GroupAction.{Defs, Quotient}
                    │
                    ▼
          GroupAction.Basic
           ╱             ╲
          ▼               ▼
GroupAction.Canonical   (provides orbit API)
          │               │
          ▼               ▼
GroupAction.Invariant ◄── GroupAction.{Basic, Canonical}
          │
          ▼
     Crypto.Scheme ◄── GroupAction.{Basic, Canonical}
       ╱       ╲               ╲
      ▼         ▼               ▼
Crypto.Security  Crypto.OIA   KEM.Syntax ◄── GroupAction.Canonical
      │               │         │
      ├───────────┐   │         ▼
      ▼           ▼   ▼      KEM.Encapsulate
Theorems.       Theorems.       │
Correctness     OIAImpliesCPA   ├─────────────────┐
◄── Crypto.Scheme               ▼                 ▼
◄── GroupAction.Invariant   KEM.Correctness    KEM.Security
      │                                        ◄── GroupAction.
      ▼                                            Invariant
Theorems.InvariantAttack
◄── Crypto.Security
◄── GroupAction.Invariant

Mathlib.GroupTheory.Perm.Basic
          │
          ▼
Construction.Permutation ◄── GroupAction.Invariant
          │
          ▼
Construction.HGOE              Construction.HGOEKEM
◄── Crypto.Security            ◄── Construction.HGOE
◄── Theorems.Correctness       ◄── KEM.Correctness
◄── Theorems.InvariantAttack   ◄── KEM.Security

Mathlib.Probability.ProbabilityMassFunction.*
Mathlib.Probability.Distributions.Uniform
          │
          ▼
  Probability.Monad ◄── PMF wrappers (uniformPMF, probTrue)
          │
          ├──────────────────┬────────────────────┐
          ▼                  ▼                    ▼
  Probability.Advantage  Probability.Negligible  Probability.UniversalHash
  ◄── advantage, triangle  ◄── IsNegligible      ◄── IsEpsilonUniversal
  ◄── hybrid_argument      ◄── add closure       ◄── probTrue_uniformPMF_decide_eq
          │                  │                    │
          ├──────────────────┘                    │
          │                                       │
          │                                       └─── AEAD.CarterWegmanMAC
          │                                            (post-audit universal-hash)
          ▼
  Crypto.CompOIA ◄── Crypto.OIA
  ◄── orbitDist, ConcreteOIA, CompOIA
  ◄── det_oia_implies_concrete_zero
          │
          ▼
  Crypto.CompSecurity ◄── Crypto.Security
  ◄── indCPAAdvantage
  ◄── concrete_oia_implies_1cpa
  ◄── comp_oia_implies_1cpa

KEM.Encapsulate + Construction.Permutation
          │
          ▼
  KeyMgmt.SeedKey ◄── SeedKey, HGOEKeyExpansion
  ◄── seed_kem_correctness
  ◄── seed_determines_key
  ◄── OrbitEncScheme.toSeedKey
          │
          ▼
  KeyMgmt.Nonce ◄── KeyMgmt.SeedKey
  ◄── nonceEncaps, nonceDecaps
  ◄── nonce_encaps_correctness
  ◄── nonce_reuse_leaks_orbit

AEAD.MAC ◄── Mathlib.Tactic
  ◄── MAC structure (tag, verify, correct, verify_inj)
          │
          ▼
  AEAD.AEAD ◄── AEAD.MAC, KEM.Syntax, KEM.Encapsulate, KEM.Correctness
  ◄── AuthOrbitKEM, authEncaps, authDecaps
  ◄── aead_correctness, INT_CTXT
  ◄── authEncrypt_is_int_ctxt (Workstream C2)

  AEAD.Modes ◄── KEM.Syntax, KEM.Encapsulate
  ◄── DEM, hybridEncrypt, hybridDecrypt
  ◄── hybrid_correctness

  AEAD.CarterWegmanMAC ◄── AEAD.MAC, AEAD.AEAD, Mathlib.Data.ZMod.Basic
                       ◄── Probability.UniversalHash (post-audit)
  ◄── deterministicTagMAC, carterWegmanHash, carterWegmanMAC
  ◄── carterWegmanHash_collision_iff, carterWegmanHash_collision_card
  ◄── carterWegmanHash_isUniversal [Fact (Nat.Prime p)]
      (headline: CW is `(1/p)`-universal over the prime field `ZMod p`,
       L-workstream post-audit, 2026-04-22)
  ◄── carterWegman_authKEM, carterWegmanMAC_int_ctxt (Workstream C4)

  Mathlib.GroupTheory.Perm.Basic
  Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup.Defs
          │
          ▼
  Hardness.CodeEquivalence ◄── Perm.Basic
  ◄── ArePermEquivalent, PAut, CEOIA, GIReducesToCE

  Hardness.TensorAction ◄── GeneralLinearGroup.Defs
  ◄── Tensor3, tensorAction (MulAction GL³), AreTensorIsomorphic

  Hardness.Reductions ◄── CodeEquivalence, TensorAction, Crypto.OIA
  ◄── TensorOIA, GIOIA, HardnessChain
  ◄── hardness_chain_implies_security

  KEM.{Syntax, Encapsulate, Correctness} + GroupAction.{Basic, Canonical}
          │
          ▼
  PublicKey.ObliviousSampling ◄── GroupAction.Basic
  ◄── OrbitalRandomizers, obliviousSample
  ◄── oblivious_sample_in_orbit
  ◄── ObliviousSamplingHiding, oblivious_sampling_view_constant
  ◄── refreshRandomizers, refreshRandomizers_in_orbit
  ◄── RefreshDependsOnlyOnEpochRange, refresh_depends_only_on_epoch_range

  PublicKey.KEMAgreement ◄── KEM.Encapsulate, KEM.Correctness
  ◄── OrbitKeyAgreement, sessionKey
  ◄── kem_agreement_correctness
  ◄── SessionKeyExpansionIdentity, sessionKey_expands_to_canon_form

  PublicKey.CommutativeAction ◄── GroupAction.Basic, GroupAction.Canonical
  ◄── CommGroupAction (class), csidh_exchange
  ◄── csidh_correctness
  ◄── CommOrbitPKE, comm_pke_correctness

  GroupAction.Canonical + Construction.Permutation
          │
          ▼
  Optimization.QCCanonical ◄── GroupAction.Canonical, Construction.Permutation
  ◄── QCCyclicCanonical (abbrev for CanonicalForm on a cyclic subgroup)
  ◄── qc_invariant_under_cyclic, qc_canon_idem

  Optimization.TwoPhaseDecrypt ◄── Optimization.QCCanonical, KEM.Correctness
  ◄── TwoPhaseDecomposition (correctness predicate)
  ◄── two_phase_correct, full_canon_invariant
  ◄── two_phase_invariant_under_G
  ◄── two_phase_kem_decaps, two_phase_kem_correctness
  ◄── IsOrbitConstant, orbit_constant_encaps_eq_basePoint
```

## Deterministic-vs-probabilistic security chains

Orbcrypt's formalization carries *two* parallel security chains. Knowing
which chain a headline theorem belongs to is essential for reading the
results correctly — the deterministic chain is algebraic scaffolding, the
probabilistic chain is the substantive security content.

1. **Deterministic chain** (Phases 3, 4, 7, 10, 12). Built from
   `Prop`-valued OIA variants (`OIA`, `KEMOIA`, `TensorOIA`, `CEOIA`,
   `GIOIA`). Each quantifies over every Boolean distinguisher,
   including orbit-membership oracles. These predicates are
   **False on every non-trivial scheme** (as documented in
   `Crypto/OIA.lean`); consequently the downstream theorems
   `oia_implies_1cpa`, `kemoia_implies_secure`,
   `hardness_chain_implies_security` are vacuously true on
   production instances. They are **algebraic scaffolding** —
   type-theoretic templates whose existence we verify, not
   standalone security claims. Their role in the formalization is to
   fix the *shape* of an OIA-style reduction argument and to serve as
   reference types that the probabilistic predicates refine.

2. **Probabilistic chain** (Phase 8, Workstream E, Workstream G,
   Workstream H). Built from `ConcreteOIA`,
   `ConcreteKEMOIA_uniform`, `ConcreteHardnessChain`,
   `ConcreteKEMHardnessChain`, and related ε-bounded predicates on
   the PMF-valued orbit distributions. These admit genuinely
   ε-smooth values (at ε = 0 they collapse to the deterministic
   form; at ε = 1 they are trivially inhabited; intermediate ε ∈
   (0, 1) parameterises concrete security). The probabilistic chain
   is the **substantive security content**, subject to a
   caller-supplied `SurrogateTensor` (Workstream G) or explicit
   GI/CE hardness assumption (plus, for the KEM layer, a caller-
   supplied scheme-to-KEM reduction witness at the chosen
   `(m₀, keyDerive)` pair — Workstream H).

External release claims of the form "Orbcrypt is IND-1-CPA secure
under TI-hardness" should cite the probabilistic chain
(`concrete_hardness_chain_implies_1cpa_advantage_bound` at the
scheme level, `concrete_kem_hardness_chain_implies_kem_advantage_bound`
at the KEM level), not the deterministic one. See
`docs/VERIFICATION_REPORT.md` § "Release readiness" for the exact
citations and the `CLAUDE.md` "Three core theorems" table's
**Status** column (Standalone / Scaffolding / Quantitative) for the
per-theorem classification.

## Headline Theorem Dependencies

```text
correctness (Theorems/Correctness.lean)
  ├── encrypt_mem_orbit    — ciphertext ∈ orbit (4.1)
  ├── canon_encrypt        — canon preserves encryption (4.2)
  ├── decrypt_unique       — unique decryption (4.3–4.4)
  ├── canonical_isGInvariant — canon is G-invariant (2.11)
  └── canon_eq_implies_orbit_eq — canon equality → orbit equality (2.6)

invariant_attack (Theorems/InvariantAttack.lean)
  ├── invariantAttackAdversary       — adversary construction (4.6)
  ├── invariant_on_encrypt           — f(g • reps m) = f(reps m) (4.7)
  └── invariantAttackAdversary_correct — case-split correctness (4.8)

oia_implies_1cpa (Theorems/OIAImpliesCPA.lean)
  ├── no_advantage_from_oia — advantage elimination (4.12)
  ├── oia_specialized       — OIA instantiation (4.10)
  └── OIA (hypothesis)      — Orbit Indistinguishability Assumption

oia_implies_1cpa_distinct (Theorems/OIAImpliesCPA.lean)  ◄── Workstream K1
  ├── oia_implies_1cpa                — uniform-game security
  └── isSecure_implies_isSecureDistinct — distinct-challenge bridge (B1)

kem_correctness (KEM/Correctness.lean)
  └── (definitional — rfl)

kemoia_implies_secure (KEM/Security.lean)
  ├── kem_key_constant_direct         — key constancy unconditionally from
  │                                     `canonical_isGInvariant` (post-L5;
  │                                     pre-L5 this step extracted `KEMOIA.2`)
  ├── kem_ciphertext_indistinguishable — orbit indist. from `KEMOIA`
  │                                     (single-conjunct form post-L5)
  └── KEMOIA (hypothesis)             — KEM Orbit Indist. Assumption
                                        (single-conjunct form post Workstream
                                        L5 / audit F-AUDIT-2026-04-21-M6)

concrete_oia_implies_1cpa (Crypto/CompSecurity.lean)
  ├── ConcreteOIA (hypothesis)   — probabilistic orbit indistinguishability
  ├── indCPAAdvantage            — probabilistic IND-1-CPA advantage (8.6)
  ├── advantage                  — distinguishing advantage (8.3)
  └── orbitDist                  — orbit sampling distribution (8.4)

indCPAAdvantage_collision_zero (Crypto/CompSecurity.lean) ◄── Workstream K4
  └── advantage_self             — advantage between coincident PMFs is 0 (8.3)

hardness_chain_implies_security_distinct (Hardness/Reductions.lean)  ◄── K3
  ├── hardness_chain_implies_security   — uniform-game security
  └── isSecure_implies_isSecureDistinct — distinct-challenge bridge (B1)

concrete_hardness_chain_implies_1cpa_advantage_bound_distinct
                                    (Hardness/Reductions.lean)  ◄── K4 companion
  └── concrete_hardness_chain_implies_1cpa_advantage_bound (Workstream G)
      — the distinctness hypothesis is carried as a signature marker only

det_oia_implies_concrete_zero (Crypto/CompOIA.lean)
  ├── OIA (hypothesis)           — deterministic OIA
  └── ConcreteOIA                — probabilistic ConcreteOIA (bridge)

comp_oia_implies_1cpa (Crypto/CompSecurity.lean)
  ├── CompOIA (hypothesis)       — asymptotic computational OIA
  ├── CompIsSecure               — computational security (8.7c)
  └── IsNegligible               — negligible function framework (8.2)

single_query_bound (Crypto/CompSecurity.lean)
  └── ConcreteOIA (hypothesis)   — per-query advantage ≤ ε (building block for Q-CPA)

hybrid_argument (Probability/Advantage.lean)
  └── advantage_triangle          — triangle inequality for advantage (8.3c)

seed_kem_correctness (KeyMgmt/SeedKey.lean)
  └── kem_correctness             — KEM correctness (7.3)

nonce_encaps_correctness (KeyMgmt/Nonce.lean)
  └── kem_correctness             — KEM correctness (7.3)

nonce_reuse_leaks_orbit (KeyMgmt/Nonce.lean)
  └── orbit_eq_of_smul            — group action preserves orbits (2.4)

seed_determines_key (KeyMgmt/SeedKey.lean)
  └── (definitional — rw)

aead_correctness (AEAD/AEAD.lean)
  ├── kem_correctness             — KEM correctness (7.3)
  └── MAC.correct                 — MAC correctness field (10.1)

authEncrypt_is_int_ctxt (AEAD/AEAD.lean)     ◄── Workstream C2 (audit F-07)
  ├── MAC.verify_inj              — tag uniqueness (Workstream C1)
  ├── canon_eq_of_mem_orbit       — canonical form invariance (2.6)
  └── hOrbitCover (hypothesis)    — ciphertext space = orbit G basePoint

carterWegmanMAC_int_ctxt (AEAD/CarterWegmanMAC.lean) ◄── Workstream C4
  ├── authEncrypt_is_int_ctxt     — composed INT_CTXT proof
  └── carterWegmanMAC             — concrete `verify_inj` witness

hybrid_correctness (AEAD/Modes.lean)
  ├── kem_correctness             — KEM correctness (7.3)
  └── DEM.correct                 — DEM correctness field (10.5)

oblivious_sample_in_orbit (PublicKey/ObliviousSampling.lean)
  └── OrbitalRandomizers.in_orbit — randomizer orbit certificate (13.1)

refresh_depends_only_on_epoch_range (PublicKey/ObliviousSampling.lean)
  └── (structural — `funext` + hypothesis)
  ── renamed from `refresh_independent` in Workstream L3 (audit
     F-AUDIT-2026-04-21-M4) to reflect that the content is structural
     determinism, not cryptographic independence.

kem_agreement_correctness (PublicKey/KEMAgreement.lean)
  └── kem_correctness             — KEM correctness (7.3)

csidh_correctness (PublicKey/CommutativeAction.lean)
  └── CommGroupAction.comm        — commutativity axiom of the class (13.5)

comm_pke_correctness (PublicKey/CommutativeAction.lean)
  ├── CommGroupAction.comm        — commutativity axiom of the class (13.5)
  └── CommOrbitPKE.pk_valid       — public-key validity field (13.6)

two_phase_correct (Optimization/TwoPhaseDecrypt.lean)           ◄── Phase 15.5
  └── hDecomp (hypothesis)        — TwoPhaseDecomposition predicate

two_phase_kem_correctness (Optimization/TwoPhaseDecrypt.lean)   ◄── Phase 15.3
  ├── two_phase_kem_decaps        — decapsulation-level rewrite (15.5)
  └── kem_correctness             — full-group KEM correctness (7.3)

full_canon_invariant (Optimization/TwoPhaseDecrypt.lean)        ◄── Phase 15.5
  ├── canon_eq_of_mem_orbit       — orbit-constancy of canonical form (2.6)
  └── smul_mem_orbit              — g • x ∈ orbit G x (2.4)

orbit_constant_encaps_eq_basePoint (Optimization/TwoPhaseDecrypt.lean) ◄── 15.4
  └── IsOrbitConstant (hypothesis) — predicate for orbit-constant functions

fast_kem_round_trip (Optimization/TwoPhaseDecrypt.lean)         ◄── Phase 15.3
                                                                    (audit follow-up)
  └── IsOrbitConstant (hypothesis) — true for the GAP `FastCanonicalImage`
      whenever the cyclic subgroup is normal in G; this is the actual
      KEM-correctness theorem for the GAP `(FastEncaps, FastDecaps)` pair,
      not the stronger `two_phase_kem_correctness` (which requires the
      `TwoPhaseDecomposition` predicate, empirically false for the
      default fallback wreath-product G).

fast_canon_composition_orbit_constant (Optimization/TwoPhaseDecrypt.lean) ◄── 15.3
  ├── full_canon_invariant — orbit constancy of slow canon (15.5)
  └── hCommutes (hypothesis) — fast preprocessor stays in-orbit
```

## Axiom Transparency Report

This formalization introduces **zero custom axioms** beyond Lean's standard axioms.

The Orbit Indistinguishability Assumption (OIA) is a `Prop`-valued *definition*
(declared in `Orbcrypt.Crypto.OIA`), NOT a Lean `axiom`. Theorems that depend
on the OIA carry it as an explicit hypothesis in their type signatures.

### Axiom-free results (unconditional)

These theorems depend only on Lean's standard axioms (`propext`,
`Classical.choice`, `Quot.sound`):

- `correctness` (`Theorems/Correctness.lean`) — decrypt inverts encrypt
- `invariant_attack` (`Theorems/InvariantAttack.lean`) — separating invariant
  implies complete break
- `kem_correctness` (`KEM/Correctness.lean`) — decaps recovers encapsulated key
- `kem_key_constant_direct` (`KEM/Security.lean`) — key constancy from
  canonical form G-invariance (no KEMOIA needed)
- All `GroupAction/` lemmas — orbit API, canonical forms, invariant functions
- All `Construction/` proofs — S_n action, HGOE, HGOE-KEM, Hamming weight
- `isSecure_implies_isSecureDistinct` (`Crypto/Security.lean`) — the
  stronger uniform IND-1-CPA game implies the classical distinct-challenge
  game (audit F-02, Workstream B1)
- `indCPAAdvantage_collision_zero` (`Crypto/CompSecurity.lean`) — the
  probabilistic IND-1-CPA advantage vanishes on collision-choice
  adversaries (audit finding F-AUDIT-2026-04-21-M1, Workstream K4);
  this is the structural reason the `concrete_oia_implies_1cpa` bound
  transfers to the classical distinct-challenge game for free.
- `perQueryAdvantage_nonneg`, `perQueryAdvantage_le_one`,
  `perQueryAdvantage_bound_of_concreteOIA` (`Crypto/CompSecurity.lean`) —
  per-query advantage properties; the `ConcreteOIA` bound is carried as
  a hypothesis on the last theorem (audit F-02, Workstream B3)
- All `Probability/` lemmas — advantage, negligible, hybrid argument
- `concreteOIA_one` (`Crypto/CompOIA.lean`) — ConcreteOIA(1) is always true
- `seed_kem_correctness` (`KeyMgmt/SeedKey.lean`) — seed-based KEM correctness
- `seed_determines_key` (`KeyMgmt/SeedKey.lean`) — equal seeds → equal key material
- `nonce_encaps_correctness` (`KeyMgmt/Nonce.lean`) — nonce-based KEM correctness
- `nonce_reuse_leaks_orbit` (`KeyMgmt/Nonce.lean`) — cross-KEM nonce reuse leaks
  orbit membership (unconditional warning theorem)
- All `KeyMgmt/` lemmas — seed keys, nonce encapsulation, backward compatibility
- `aead_correctness` (`AEAD/AEAD.lean`) — authenticated KEM correctness
- `authEncrypt_is_int_ctxt` (`AEAD/AEAD.lean`) — INT_CTXT proof for
  honestly-composed AuthOrbitKEMs; carries the orbit-cover hypothesis
  (`∀ c, c ∈ orbit G basePoint`) as an explicit hypothesis on the
  ciphertext space (audit finding F-07, Workstream C2).
- `carterWegmanMAC_int_ctxt` (`AEAD/CarterWegmanMAC.lean`) — concrete
  INT_CTXT witness via the Carter–Wegman universal-hash MAC; carries the
  orbit-cover hypothesis identically (audit finding F-07, Workstream C4).
- `hybrid_correctness` (`AEAD/Modes.lean`) — KEM+DEM hybrid correctness
- All `AEAD/` definitions and lemmas — MAC, AuthOrbitKEM, DEM, INT_CTXT
- All `Hardness/` definitions and lemmas — CE, TI, tensor action, reductions
- `areTensorIsomorphic_refl` (`Hardness/TensorAction.lean`) — TI reflexivity
- `areTensorIsomorphic_symm` (`Hardness/TensorAction.lean`) — TI symmetry
- `arePermEquivalent_refl` (`Hardness/CodeEquivalence.lean`) — CE reflexivity
- `arePermEquivalent_symm` (`Hardness/CodeEquivalence.lean`) — CE symmetry
  (audit F-08, Workstream D1b; carries `C₁.card = C₂.card` as a hypothesis)
- `arePermEquivalent_trans` (`Hardness/CodeEquivalence.lean`) — CE
  transitivity (audit F-08, Workstream D1c; unconditional)
- `arePermEquivalent_setoid` (`Hardness/CodeEquivalence.lean`) — Mathlib
  `Setoid` instance bundling refl/symm/trans on the card-indexed
  subtype (audit F-08, Workstream D4; parameters `{n} {F} {k}` are
  implicit so `inferInstance` at concrete subtypes resolves without
  `@`-threading — verified by `scripts/audit_d_workstream.lean` § 7)
- `paut_compose_preserves_equivalence` (`Hardness/CodeEquivalence.lean`) —
  PAut coset structure
- `paut_inv_closed` (`Hardness/CodeEquivalence.lean`) — `PAut C` is
  closed under inverses (audit F-08, Workstream D2; corollary of D1a)
- `PAutSubgroup` (`Hardness/CodeEquivalence.lean`) — `PAut` packaged as a
  Mathlib `Subgroup (Equiv.Perm (Fin n))` (audit F-08, Workstream D2)
- `PAut_eq_PAutSubgroup_carrier` (`Hardness/CodeEquivalence.lean`) — `rfl`
  bridge between the `Set`-valued and `Subgroup`-valued formulations
  (audit F-08, Workstream D2c)
- `paut_equivalence_set_eq_coset` (`Hardness/CodeEquivalence.lean`) — full
  set identity `{ρ | ρ : C₁ → C₂} = σ · PAut C₁` (audit F-16 extended,
  Workstream D3; the algebraic statement underlying LESS-style search-space
  reduction)
- `qc_invariant_under_cyclic` and `qc_canon_idem`
  (`Optimization/QCCanonical.lean`) — the QC cyclic canonical form is
  constant on its own orbits and idempotent (Phase 15.1 / 15.5)
- `full_canon_invariant` (`Optimization/TwoPhaseDecrypt.lean`) — the
  full canonical form is constant on G-orbits; direct application of
  `canon_eq_of_mem_orbit` (Phase 15.5)

### OIA-dependent results (conditional)

These theorems carry `OIA`, `KEMOIA`, `ConcreteOIA`, `ConcreteKEMOIA`,
`ConcreteTensorOIA`, `ConcreteCEOIA`, `ConcreteGIOIA`, or `CompOIA` as an
explicit hypothesis:

- `oia_implies_1cpa` (`Theorems/OIAImpliesCPA.lean`) — OIA implies IND-1-CPA
- `kemoia_implies_secure` (`KEM/Security.lean`) — KEMOIA implies KEM security
- `concrete_oia_implies_1cpa` (`Crypto/CompSecurity.lean`) — ConcreteOIA(ε)
  implies IND-1-CPA advantage ≤ ε (Phase 8, non-vacuous)
- `comp_oia_implies_1cpa` (`Crypto/CompSecurity.lean`) — CompOIA implies
  negligible IND-1-CPA advantage (Phase 8, asymptotic)
- `det_oia_implies_concrete_zero` (`Crypto/CompOIA.lean`) — deterministic OIA
  implies ConcreteOIA(0) (Phase 8, bridge/compatibility)
- `hardness_chain_implies_security` (`Hardness/Reductions.lean`) —
  TensorOIA + reduction chain → IND-1-CPA (Phase 12, carries
  HardnessChain as hypothesis)

**Workstream K (audit 2026-04-21, F-AUDIT-2026-04-21-M1):
distinct-challenge IND-1-CPA corollaries.**

`IsSecure` (uniform game, `Crypto/Security.lean`) is strictly stronger
than the classical IND-1-CPA game `IsSecureDistinct` (which rejects
the degenerate collision choice `(m, m)` before sampling). Workstream K
threads that distinction through the downstream chain:

- `oia_implies_1cpa_distinct` (`Theorems/OIAImpliesCPA.lean`, K1) —
  `OIA → IsSecureDistinct`; classical distinct-challenge IND-1-CPA
  from the deterministic OIA. Composition of `oia_implies_1cpa` with
  `isSecure_implies_isSecureDistinct`.
- `hardness_chain_implies_security_distinct` (`Hardness/Reductions.lean`,
  K3) — `HardnessChain scheme → IsSecureDistinct scheme`; chain-level
  parallel, composition with the same bridge.
- `concrete_hardness_chain_implies_1cpa_advantage_bound_distinct`
  (`Hardness/Reductions.lean`, K4 companion) — probabilistic
  chain-level bound restated in the classical distinct-challenge
  framing. Since the bound already holds unconditionally, the
  distinctness hypothesis is carried as a release-facing signature
  marker — not used in the proof.

Each of the three `_distinct` corollaries inherits the deterministic-
chain scaffolding status: the `OIA` / `HardnessChain` hypothesis is
`False` on every non-trivial scheme, so the conclusion is vacuously
true on production instances. Cite the probabilistic chain
(`concrete_oia_implies_1cpa` +
`indCPAAdvantage_collision_zero`, or the dedicated
`concrete_hardness_chain_implies_1cpa_advantage_bound` /
`_distinct`) for non-vacuous quantitative content.

**K2 design note — no KEM `_distinct` corollary.** The
`kemoia_implies_secure` theorem does *not* get a `_distinct` corollary.
`kemHasAdvantage` quantifies over two *group elements* `g₀, g₁ : G`
(drawn by the challenger from `G`), not two messages chosen by the
adversary. All ciphertexts lie in the single orbit of the base point,
so there is no per-message collision risk and no scheme-level
challenger rejection. The extended docstring on `kemoia_implies_secure`
documents this.

**Workstream E (audit 2026-04-18 + 2026-04-20 follow-up,
F-01 + F-10 + F-11 + F-17 + F-20):**

- `det_kemoia_implies_concreteKEMOIA_zero` (`KEM/CompSecurity.lean`) —
  deterministic KEMOIA → ConcreteKEMOIA 0 (E1c).
- `concrete_kemoia_implies_secure` (`KEM/CompSecurity.lean`) —
  ConcreteKEMOIA ε bounds per-pair KEM advantage by ε (E1d). Note the
  docstring's disclosure that `ConcreteKEMOIA` is point-mass and collapses
  on `ε ∈ [0, 1)`; the genuinely ε-smooth `ConcreteKEMOIA_uniform` is
  defined alongside.
- `ConcreteHardnessChain.concreteOIA_from_chain` (`Hardness/Reductions.lean`)
  — packaged ε-bounded hardness chain → ConcreteOIA ε. Post-Workstream-G
  (audit F-AUDIT-2026-04-21-H1, Fix B + Fix C), the chain carries a
  `SurrogateTensor F` parameter plus two explicit encoder fields
  (`encTC`, `encCG`) and consumes three per-encoding reduction Props
  (`*_viaEncoding`). Composition threads advantage through the chain
  image without relying on universal-over-all-instances hypotheses.
- `ConcreteHardnessChain.tight_one_exists` (`Hardness/Reductions.lean`) —
  satisfiability witness for the post-Workstream-G chain at ε = 1, using
  `punitSurrogate F` and dimension-0 trivial encoders.
- `concrete_hardness_chain_implies_1cpa_advantage_bound`
  (`Hardness/Reductions.lean`) — ConcreteHardnessChain ε →
  IND-1-CPA advantage ≤ ε (E5; signature now threads `SurrogateTensor` via
  the chain structure).
- `concrete_combiner_advantage_bounded_by_oia`
  (`PublicKey/CombineImpossibility.lean`) — ConcreteOIA scheme ε bounds
  the combiner-induced distinguisher's advantage by ε (E6).
- `combinerOrbitDist_mass_bounds` (`PublicKey/CombineImpossibility.lean`) —
  intra-orbit mass bound (Pr[true] ≥ 1/|G| AND Pr[false] ≥ 1/|G|) on the
  basepoint orbit under non-degeneracy (E6b). *This is a one-orbit
  witness, not a cross-orbit advantage bound* — see the lemma's
  docstring for the distinction.
- `indQCPA_bound_via_hybrid` (`Crypto/CompSecurity.lean`) — Q-query
  IND-Q-CPA advantage ≤ Q · ε via the hybrid argument, given a per-step
  bound as hypothesis (E8c).
- `indQCPA_bound_recovers_single_query` (`Crypto/CompSecurity.lean`) —
  Q = 1 regression sentinel (E8d).

**Phase 15 (Decryption Optimisation):**

- `two_phase_correct` (`Optimization/TwoPhaseDecrypt.lean`) — the
  two-phase (cyclic ∘ residual) canonical form agrees with the full
  canonical form on `g • x`, *given* a `TwoPhaseDecomposition`
  hypothesis `hDecomp` (15.5).
- `two_phase_decompose` (`Optimization/TwoPhaseDecrypt.lean`) —
  definitional unfolding of `TwoPhaseDecomposition` for direct
  rewriting in client proofs (15.5).
- `two_phase_invariant_under_G`
  (`Optimization/TwoPhaseDecrypt.lean`) — the two-phase pipeline is
  invariant under the full-group action, given `hDecomp` (15.5).
- `two_phase_kem_decaps` (`Optimization/TwoPhaseDecrypt.lean`) —
  decapsulation-level rewrite of the fast path, given `hDecomp` (15.3).
- `two_phase_kem_correctness`
  (`Optimization/TwoPhaseDecrypt.lean`) — the two-phase fast path
  correctly recovers the KEM key on `(encaps g).1`, given `hDecomp`
  (15.3).
- `orbit_constant_encaps_eq_basePoint`
  (`Optimization/TwoPhaseDecrypt.lean`) — an orbit-constant function
  (such as the syndrome) applied to an encapsulation ciphertext equals
  its value on the base point, given `IsOrbitConstant` as a hypothesis
  (15.4).
- `fast_kem_round_trip`
  (`Optimization/TwoPhaseDecrypt.lean`) — the actual fast-KEM
  correctness theorem for the GAP `(FastEncaps, FastDecaps)` pair:
  given `IsOrbitConstant G fastCanon`, decapsulation via the fast
  canonical form recovers the encapsulated key. This is the
  practical correctness story (orbit-constancy is satisfied by
  `FastCanonicalImage`); the stronger `two_phase_*` theorems
  require `TwoPhaseDecomposition`, which is empirically false for
  the default wreath-product G. Post-landing audit addition
  (Phase 15.3).
- `fast_canon_composition_orbit_constant`
  (`Optimization/TwoPhaseDecrypt.lean`) — template lemma: if a
  fast preprocessor keeps each input inside its own G-orbit
  (`hCommutes`), the composite `can_full ∘ fastCanon` is
  G-orbit-constant. Useful for "fast preprocess + slow finalise"
  pipelines.

### Hardness parameter Props (reduction claims, not proofs)

The following `Prop`-valued definitions state many-one (Karp) reductions
between hardness problems. They are carried as *hypotheses* by downstream
theorems (currently only by the Workstream E hardness-chain theorems, to
be populated per `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md`
§ E3–E5). They are NOT proven within this formalization — a concrete
witness would require formalising the CFI graph gadget (for `GIReducesToCE`)
or the triangle-indicator tensor encoding (for `GIReducesToTI`). See
`docs/HARDNESS_ANALYSIS.md` for the literature context and Phase 12
scope note.

- `GIReducesToCE` (`Hardness/CodeEquivalence.lean`) — Graph Isomorphism
  reduces to Permutation Code Equivalence. (Consumer: Workstream E4
  `ConcreteHardnessChain`; audit finding F-12.)
- `GIReducesToTI` (`Hardness/TensorAction.lean`) — Graph Isomorphism
  reduces to Tensor Isomorphism. (Consumer: Workstream E4
  `ConcreteHardnessChain`; audit finding F-12.)

Both are reduction *claims* that point at external research (LESS / MEDS
/ Grochow–Qiao). Their function in the formalization is to document the
intended hardness foundation and to give Workstream E's probabilistic
hardness chain a Prop to attach to. They are audit-tracked rather than
deleted; see audit finding F-12 for the rationale.

### Phase 13 Public-Key Extension results (conditional on their own hypotheses)

Phase 13 introduces three candidate paths from symmetric to public-key orbit
encryption; each carries its assumption as an explicit hypothesis or
typeclass axiom rather than a Lean `axiom`:

- `oblivious_sample_in_orbit` (`PublicKey/ObliviousSampling.lean`) —
  oblivious sampling preserves orbit membership, given the client-supplied
  closure hypothesis `hClosed`.
- `oblivious_sampling_view_constant` (`PublicKey/ObliviousSampling.lean`)
  — carries `ObliviousSamplingHiding` as a hypothesis (a strong
  deterministic hiding requirement; documented as pathological-strength
  and not expected to hold for non-trivial bundles without a
  probabilistic refinement).
- `refresh_depends_only_on_epoch_range`
  (`PublicKey/ObliviousSampling.lean`) — structural
  determinism of epoch-refreshed randomizer bundles (unconditional; PRF
  security remains a separate sampler-level assumption). Renamed from
  `refresh_independent` in Workstream L3 (audit
  F-AUDIT-2026-04-21-M4) to reflect that the content is structural,
  not cryptographic.
- `kem_agreement_correctness` (`PublicKey/KEMAgreement.lean`) — follows
  from `kem_correctness`; establishes that two formulations of the
  session-key computation coincide.
- `sessionKey_expands_to_canon_form` (`PublicKey/KEMAgreement.lean`)
  — an unconditional structural identity exhibiting the session-key
  formula in terms of both parties' `keyDerive` and `canonForm.canon`.
  Renamed from `symmetric_key_agreement_limitation` in Workstream L4
  (audit F-AUDIT-2026-04-21-M5) because the content is a
  decomposition identity, not an impossibility claim.
- `csidh_correctness` and `comm_pke_correctness`
  (`PublicKey/CommutativeAction.lean`) — extract the `CommGroupAction.comm`
  typeclass axiom (not a Lean `axiom`; each concrete instance discharges it
  with a proof).
- `selfAction_comm` (`PublicKey/CommutativeAction.lean`) — machine-checked
  example witnessing that `CommGroupAction` is satisfiable for any
  `CommGroup` acting on itself.

### Verification

Users can verify axiom dependencies by running in a Lean file:

```lean
#print axioms Orbcrypt.correctness
-- propext, Classical.choice, Quot.sound (standard Lean only)

#print axioms Orbcrypt.invariant_attack
-- propext (standard Lean only)

#print axioms Orbcrypt.oia_implies_1cpa
-- (empty — zero axioms; OIA appears as a hypothesis, not an axiom)

#print axioms Orbcrypt.kem_correctness
-- (standard Lean only — definitional equality)

#print axioms Orbcrypt.kemoia_implies_secure
-- (standard Lean only — KEMOIA appears as a hypothesis, not an axiom)

#print axioms Orbcrypt.concrete_oia_implies_1cpa
-- (standard Lean only — ConcreteOIA appears as a hypothesis)

#print axioms Orbcrypt.comp_oia_implies_1cpa
-- (standard Lean only — CompOIA appears as a hypothesis)

#print axioms Orbcrypt.det_oia_implies_concrete_zero
-- (standard Lean only — OIA appears as a hypothesis)

#print axioms Orbcrypt.seed_kem_correctness
-- (standard Lean only — follows from kem_correctness)

#print axioms Orbcrypt.nonce_encaps_correctness
-- (standard Lean only — follows from kem_correctness)

#print axioms Orbcrypt.nonce_reuse_leaks_orbit
-- (standard Lean only — follows from orbit_eq_of_smul)

#print axioms Orbcrypt.seed_determines_key
-- (standard Lean only — definitional rewriting)

#print axioms Orbcrypt.aead_correctness
-- (standard Lean only — follows from kem_correctness + MAC.correct)

#print axioms Orbcrypt.authEncrypt_is_int_ctxt
-- (standard Lean only — uses MAC.verify_inj + canon_eq_of_mem_orbit;
--  the `hOrbitCover` orbit-cover condition is carried as a hypothesis)

#print axioms Orbcrypt.carterWegmanMAC_int_ctxt
-- (standard Lean only — direct specialisation of authEncrypt_is_int_ctxt;
--  post-audit now requires `[Fact (Nat.Prime p)]`)

#print axioms Orbcrypt.carterWegmanHash_isUniversal
-- (standard Lean only — Carter–Wegman 1977 `(1/p)`-universality;
--  L-workstream post-audit headline, 2026-04-22)

#print axioms Orbcrypt.IsEpsilonUniversal
-- (standard Lean only — Prop-valued ε-universality definition)

#print axioms Orbcrypt.probTrue_uniformPMF_decide_eq
-- (standard Lean only — counting form of uniform probability)

#print axioms Orbcrypt.hybrid_correctness
-- (standard Lean only — follows from kem_correctness + DEM.correct)

#print axioms Orbcrypt.hardness_chain_implies_security
-- (standard Lean only — HardnessChain appears as a hypothesis)

#print axioms Orbcrypt.oblivious_sample_in_orbit
-- (standard Lean only — closure proof is a hypothesis)

#print axioms Orbcrypt.refresh_depends_only_on_epoch_range
-- (standard Lean only — structural)

#print axioms Orbcrypt.kem_agreement_correctness
-- (standard Lean only — follows from kem_correctness)

#print axioms Orbcrypt.csidh_correctness
-- (standard Lean only — extracts CommGroupAction.comm typeclass axiom)

#print axioms Orbcrypt.comm_pke_correctness
-- (standard Lean only — uses CommGroupAction.comm and pk_valid)

-- Workstream B (audit 2026-04-18, F-02 + F-15):

#print axioms Orbcrypt.isSecure_implies_isSecureDistinct
-- (does not depend on any axioms — strictly axiom-free direction
--  of the distinct-challenge implication)

#print axioms Orbcrypt.hasAdvantageDistinct_iff
-- (does not depend on any axioms — `Iff.rfl`-trivial decomposition)

#print axioms Orbcrypt.perQueryAdvantage_nonneg
-- (standard Lean only — one-line `advantage_nonneg` corollary)

#print axioms Orbcrypt.perQueryAdvantage_le_one
-- (standard Lean only — one-line `advantage_le_one` corollary)

#print axioms Orbcrypt.perQueryAdvantage_bound_of_concreteOIA
-- (standard Lean only — `ConcreteOIA` carried as a hypothesis)

-- Workstream D (audit 2026-04-18, F-08 + F-16 extended):

#print axioms Orbcrypt.permuteCodeword_self_bij_of_self_preserving
-- (standard Lean only — finite-bijection helper, Workstream D1a)

#print axioms Orbcrypt.permuteCodeword_inv_mem_of_card_eq
-- (standard Lean only — cross-code helper used by D1b and D3)

#print axioms Orbcrypt.arePermEquivalent_symm
-- (standard Lean only — one-line wrapper, Workstream D1b;
--  carries `C₁.card = C₂.card` as a hypothesis)

#print axioms Orbcrypt.arePermEquivalent_trans
-- (standard Lean only — composition of witnesses, Workstream D1c)

#print axioms Orbcrypt.paut_inv_closed
-- (standard Lean only — corollary of D1a, Workstream D2)

#print axioms Orbcrypt.PAutSubgroup
-- (standard Lean only — `Subgroup` packaging, Workstream D2)

#print axioms Orbcrypt.PAut_eq_PAutSubgroup_carrier
-- (standard Lean only — `rfl` proof through transitive standard imports,
--  Workstream D2c)

#print axioms Orbcrypt.paut_equivalence_set_eq_coset
-- (standard Lean only — full coset set identity, Workstream D3;
--  carries `C₁.card = C₂.card` as a hypothesis)

#print axioms Orbcrypt.arePermEquivalent_setoid
-- (standard Lean only — Mathlib `Setoid` instance over the
--  card-indexed subtype, Workstream D4)

-- Workstream E (audit 2026-04-18, F-01 + F-10 + F-11 + F-17 + F-20):

#print axioms Orbcrypt.kemEncapsDist_support
-- (standard Lean only — support characterisation, Workstream E1a)

#print axioms Orbcrypt.concreteKEMOIA_one
-- (does not depend on any axioms — one-line corollary of advantage_le_one,
--  Workstream E1b)

#print axioms Orbcrypt.det_kemoia_implies_concreteKEMOIA_zero
-- (standard Lean only — KEMOIA appears as a hypothesis, Workstream E1c)

#print axioms Orbcrypt.concrete_kemoia_implies_secure
-- (standard Lean only — ConcreteKEMOIA appears as a hypothesis, Workstream E1d)

#print axioms Orbcrypt.concrete_kemoia_uniform_implies_secure
-- (standard Lean only — ConcreteKEMOIA_uniform appears as a hypothesis,
--  Workstream E1d post-audit addition: the genuinely ε-smooth reduction)

#print axioms Orbcrypt.concreteCEOIA_one
-- (standard Lean only — one-line corollary of advantage_le_one, Workstream E2a)

#print axioms Orbcrypt.concreteTensorOIA_one
-- (standard Lean only — Workstream E2b)

#print axioms Orbcrypt.concreteGIOIA_one
-- (standard Lean only — Workstream E2c)

#print axioms Orbcrypt.concreteTensorOIAImpliesConcreteCEOIA_one_one
-- (standard Lean only — vacuously-true reduction witness, Workstream E3a)

#print axioms Orbcrypt.concreteCEOIAImpliesConcreteGIOIA_one_one
-- (standard Lean only — vacuously-true reduction witness, Workstream E3b)

#print axioms Orbcrypt.concreteGIOIAImpliesConcreteOIA_one_one
-- (standard Lean only — vacuously-true reduction witness, Workstream E3c)

#print axioms Orbcrypt.concrete_chain_zero_compose
-- (standard Lean only — algebraic composition, Workstream E3d)

#print axioms Orbcrypt.ConcreteHardnessChain.concreteOIA_from_chain
-- (standard Lean only — chain composition, Workstream E4b)

#print axioms Orbcrypt.concrete_hardness_chain_implies_1cpa_advantage_bound
-- (standard Lean only — composes E4b with concrete_oia_implies_1cpa,
--  Workstream E5)

#print axioms Orbcrypt.concrete_combiner_advantage_bounded_by_oia
-- (standard Lean only — ConcreteOIA bound applied via combinerDistinguisher,
--  Workstream E6)

#print axioms Orbcrypt.combinerOrbitDist_mass_bounds
-- (standard Lean only — non-degeneracy witness + ENNReal.le_tsum,
--  Workstream E6b)

#print axioms Orbcrypt.hybrid_argument_uniform
-- (standard Lean only — sum telescoping from hybrid_argument, Workstream E8)

#print axioms Orbcrypt.uniformPMFTuple_apply
-- (standard Lean only — Fintype.card_pi + uniformPMF_apply, Workstream E7a)

#print axioms Orbcrypt.indQCPA_bound_via_hybrid
-- (standard Lean only — per-step bound h_step carried as hypothesis;
--  telescopes via hybrid_argument_uniform, Workstream E8c)

#print axioms Orbcrypt.indQCPA_bound_recovers_single_query
-- (standard Lean only — Q = 1 regression, Workstream E8d)

-- Workstream G (audit 2026-04-21, F-AUDIT-2026-04-21-H1): Fix B + Fix C
--
-- Fix B (SurrogateTensor): the tensor-layer surrogate group is now bound
-- as an explicit structure parameter, preventing the pre-G PUnit collapse
-- of `UniversalConcreteTensorOIA`. Fix C (per-encoding reductions): the
-- three layer-transfer Props carry explicit encoder functions and assert
-- hardness transfer through those encoders (rather than universal-over-
-- every-instance), matching the cryptographic reduction literature's
-- per-encoding shape.

#print axioms Orbcrypt.SurrogateTensor
-- (standard Lean only — structure packaging group + fintype + nonempty
--  + per-dimension MulAction, Workstream G / Fix B)

#print axioms Orbcrypt.punitSurrogate
-- (standard Lean only — trivial PUnit witness, Workstream G / Fix B)

#print axioms Orbcrypt.ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding
-- (standard Lean only — per-encoding Tensor → CE reduction Prop,
--  Workstream G / Fix C)

#print axioms Orbcrypt.ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding
-- (standard Lean only — per-encoding CE → GI reduction Prop,
--  Workstream G / Fix C)

#print axioms Orbcrypt.ConcreteGIOIAImpliesConcreteOIA_viaEncoding
-- (standard Lean only — per-encoding GI → scheme-OIA reduction Prop,
--  Workstream G / Fix C; consumes chain-image GI hardness, not universal)

#print axioms Orbcrypt.concreteTensorOIAImpliesConcreteCEOIA_viaEncoding_one_one
-- (standard Lean only — trivial satisfiability witness at ε = 1,
--  Workstream G / Fix C)

#print axioms Orbcrypt.concreteCEOIAImpliesConcreteGIOIA_viaEncoding_one_one
-- (standard Lean only — trivial satisfiability witness, Workstream G)

#print axioms Orbcrypt.concreteGIOIAImpliesConcreteOIA_viaEncoding_one_one
-- (standard Lean only — trivial satisfiability witness, Workstream G)

#print axioms Orbcrypt.ConcreteHardnessChain.tight_one_exists
-- (standard Lean only — inhabits the chain at ε = 1 via punitSurrogate
--  + dimension-0 trivial encoders, Workstream G post-refactor)

-- Workstream H (audit 2026-04-21, F-AUDIT-2026-04-21-H2): KEM-layer
-- ε-smooth hardness chain
--
-- Workstream H lifts the scheme-level Workstream-G chain to the KEM
-- layer via `ConcreteKEMOIA_uniform`. Three additions: the
-- scheme-to-KEM reduction Prop (H1), its ε' = 1 satisfiability
-- witness (H2), and the `ConcreteKEMHardnessChain` structure with its
-- composition theorem and ε = 1 non-vacuity witness (H3).

#print axioms Orbcrypt.ConcreteOIAImpliesConcreteKEMOIAUniform
-- (standard Lean only — Prop-valued reduction Prop, Workstream H1)

#print axioms Orbcrypt.concreteOIAImpliesConcreteKEMOIAUniform_one_right
-- (standard Lean only — satisfiability witness at ε' = 1 via
--  concreteKEMOIA_uniform_one, Workstream H2)

#print axioms Orbcrypt.ConcreteKEMHardnessChain
-- (standard Lean only — structure packaging scheme-level chain +
--  scheme-to-KEM reduction witness, Workstream H3)

#print axioms Orbcrypt.concreteKEMHardnessChain_implies_kemUniform
-- (standard Lean only — composes ConcreteHardnessChain.concreteOIA_from_chain
--  with the scheme-to-KEM field, Workstream H3)

#print axioms Orbcrypt.ConcreteKEMHardnessChain.tight_one_exists
-- (standard Lean only — inhabits the KEM chain at ε = 1 via
--  ConcreteHardnessChain.tight_one_exists + the _one_right discharge,
--  Workstream H3)

#print axioms Orbcrypt.concrete_kem_hardness_chain_implies_kem_advantage_bound
-- (standard Lean only — end-to-end KEM-layer bound; composes the KEM
--  chain with concrete_kemoia_uniform_implies_secure, Workstream H3,
--  KEM-layer analogue of concrete_hardness_chain_implies_1cpa_advantage_bound)

-- Workstream K (audit 2026-04-21, F-AUDIT-2026-04-21-M1): distinct-
-- challenge IND-1-CPA corollaries threading the classical-game shape
-- through the downstream chain. Each corollary composes its
-- deterministic-chain ancestor with `isSecure_implies_isSecureDistinct`
-- (Workstream B1) and inherits the ancestor's scaffolding status
-- (conclusion vacuously true on every non-trivial scheme, since the
-- OIA / HardnessChain hypothesis is False there). The probabilistic
-- counterparts are axiom-free because the collision branch
-- contributes advantage 0 (`indCPAAdvantage_collision_zero`).

#print axioms Orbcrypt.oia_implies_1cpa_distinct
-- (standard Lean only — OIA appears as a hypothesis; composition of
--  oia_implies_1cpa with isSecure_implies_isSecureDistinct, Workstream K1)

#print axioms Orbcrypt.hardness_chain_implies_security_distinct
-- (standard Lean only — HardnessChain appears as a hypothesis;
--  chain-level parallel of K1, Workstream K3)

#print axioms Orbcrypt.indCPAAdvantage_collision_zero
-- (standard Lean only — one-line consequence of `advantage_self`;
--  formalises the free transfer of the probabilistic bound to the
--  distinct-challenge form, Workstream K4)

#print axioms Orbcrypt.concrete_hardness_chain_implies_1cpa_advantage_bound_distinct
-- (standard Lean only — ConcreteHardnessChain appears as a hypothesis;
--  classical-game-shape restatement of the Workstream-G probabilistic
--  chain bound, Workstream K4 companion)

-- Phase 15 (Decryption Optimisation):

#print axioms Orbcrypt.two_phase_correct
-- (standard Lean only — `hDecomp : TwoPhaseDecomposition G C ...`
--  carried as a hypothesis; Work Unit 15.5)

#print axioms Orbcrypt.two_phase_decompose
-- (standard Lean only — definitional unfolding, Work Unit 15.5)

#print axioms Orbcrypt.full_canon_invariant
-- (standard Lean only — direct application of
--  `canon_eq_of_mem_orbit` and `smul_mem_orbit`, Work Unit 15.5)

#print axioms Orbcrypt.two_phase_invariant_under_G
-- (standard Lean only — combines `two_phase_correct` with
--  `full_canon_invariant`, Work Unit 15.5)

#print axioms Orbcrypt.two_phase_kem_decaps
-- (standard Lean only — unfolds `decaps` and rewrites by `hDecomp`,
--  Work Unit 15.3)

#print axioms Orbcrypt.two_phase_kem_correctness
-- (standard Lean only — composes `two_phase_kem_decaps` with
--  `kem_correctness`, Work Unit 15.3)

#print axioms Orbcrypt.orbit_constant_encaps_eq_basePoint
-- (standard Lean only — `IsOrbitConstant` carried as a hypothesis,
--  Work Unit 15.4)

#print axioms Orbcrypt.qc_invariant_under_cyclic
-- (standard Lean only — direct application of `canon_eq_of_mem_orbit`
--  and `smul_mem_orbit`, Work Unit 15.1 / 15.5)

#print axioms Orbcrypt.qc_canon_idem
-- (standard Lean only — `canon_idem` re-exported, Work Unit 15.1 / 15.5)

#print axioms Orbcrypt.fast_kem_round_trip
-- (standard Lean only — orbit-constancy of `fastCanon` carried as a
--  hypothesis; the actual correctness theorem for the GAP
--  `(FastEncaps, FastDecaps)` pair, Phase 15.3 post-landing audit)

#print axioms Orbcrypt.fast_canon_composition_orbit_constant
-- (standard Lean only — closure-under-orbit hypothesis carried;
--  template for "fast preprocessor + slow finaliser" pipelines,
--  Phase 15.3 post-landing audit)
```

## Vacuity map (Workstream E)

Each Workstream-E theorem carries an ε-parameterised probabilistic
hypothesis (`ConcreteOIA`, `ConcreteKEMOIA`, `ConcreteTensorOIA`, etc.) in
place of the deterministic (vacuous) OIA hypothesis of its Phase-4/7/12
predecessor. The pairing:

| Pre-Workstream-E (vacuous today) | Workstream-E/G/H counterpart (non-vacuous) |
|---|---|
| `oia_implies_1cpa` | `concrete_oia_implies_1cpa` (Phase 8, already) |
| `kemoia_implies_secure` | `concrete_kemoia_implies_secure` (E1d, point-mass) + `concrete_kemoia_uniform_implies_secure` (E1d, uniform form — genuinely ε-smooth) |
| `hardness_chain_implies_security` | `concrete_hardness_chain_implies_1cpa_advantage_bound` (E5, post-G signature threads `SurrogateTensor`) — **ε = 1 inhabited only via `ConcreteHardnessChain.tight_one_exists` (`punitSurrogate F` + dimension-0 trivial encoders); ε < 1 requires a caller-supplied `SurrogateTensor F` + encoder pair with genuine cryptographic hardness (research-scope — see § O of the 2026-04-23 plan: R-02 / R-03 / R-04)** |
| `equivariant_combiner_breaks_oia` | `concrete_combiner_advantage_bounded_by_oia` (E6) |
| *multi-query extension (implicit)* | `indQCPA_bound_via_hybrid` (E8c) — **carries `h_step` as a user-supplied hypothesis; discharge from `ConcreteOIA` alone is research-scope R-09 (see § O of the 2026-04-23 plan). Workstream C of that plan renames the theorem to `indQCPA_from_perStepBound` to surface the obligation in the identifier** |
| *KEM-layer chain (missing pre-H)* | `concreteKEMHardnessChain_implies_kemUniform` (H3) — KEM-layer ε-smooth chain built from Workstream G's `ConcreteHardnessChain` + the Workstream H1 scheme-to-KEM reduction Prop. **ε = 1 inhabited only via `ConcreteKEMHardnessChain.tight_one_exists`; ε < 1 requires caller-supplied scheme-to-KEM reduction witness at `(m₀, keyDerive)` — research-scope R-05** |
| *KEM adversary bound (missing pre-H)* | `concrete_kem_hardness_chain_implies_kem_advantage_bound` (H3) — end-to-end KEM-layer adversary bound, parallel of scheme-level `concrete_hardness_chain_implies_1cpa_advantage_bound`. **Same ε = 1 disclosure as the scheme-level parallel; ε < 1 requires the composition of R-02/R-03/R-04 (scheme-level chain) and R-05 (scheme-to-KEM reduction)** |
| `oia_implies_1cpa` (uniform game) | `oia_implies_1cpa_distinct` (K1) — same scaffolding status, classical-IND-1-CPA signature matching the literature |
| `hardness_chain_implies_security` (uniform game) | `hardness_chain_implies_security_distinct` (K3) — same scaffolding status, classical-IND-1-CPA signature |
| `concrete_oia_implies_1cpa` (unconditional over `Adversary`) | `indCPAAdvantage_collision_zero` + `concrete_oia_implies_1cpa` docstring (K4) — the collision case yields advantage 0, so the existing probabilistic `≤ ε` bound transfers to the classical distinct-challenge game for free |
| `concrete_hardness_chain_implies_1cpa_advantage_bound` (unconditional over `Adversary`) | `concrete_hardness_chain_implies_1cpa_advantage_bound_distinct` (K4 companion) — classical-IND-1-CPA restatement retaining the ε-smooth quantitative content. **Same ε = 1 disclosure as the non-distinct form** |

### Vacuity map (2026-04-23 Workstream A additions — Conditional-status rows)

These rows record the 2026-04-23 audit's documentation-vs-code
reconciliation: each of the four `CLAUDE.md` rows reclassified from
**Standalone** to **Conditional** has an explicitly disclosed
hypothesis, which fails on production instances. Where a genuinely
standalone sibling theorem exists, it is named.

| Conditional theorem (Lean content) | Failing hypothesis | Standalone sibling (cite instead) |
|---|---|---|
| `authEncrypt_is_int_ctxt` (row #19) | `hOrbitCover : ∀ c : X, c ∈ orbit G basePoint` — False on production HGOE (orbit size < `2^n = |Bitstring n|`) | `keyDerive_canon_eq_of_mem_orbit` (orbit-restricted key uniqueness; unconditional). Scheduled Workstream B of 2026-04-23 plan absorbs orbit-cover into the game precondition; post-B the row #19 Status upgrades to **Standalone** |
| `carterWegmanMAC_int_ctxt` (row #20) | Implicit type constraint `X = ZMod p × ZMod p`; **incompatible with HGOE's `Bitstring n` ciphertext space** without a `Bitstring n → ZMod p` adapter | `carterWegmanHash_isUniversal` — the standalone `(1/p)`-universal hash theorem. The adapter is research-scope R-13 |
| `two_phase_correct` (row #24) | `TwoPhaseDecomposition` — empirically False on the default GAP fallback group (lex-min and the residual transversal action don't commute) | `fast_kem_round_trip` (row #26) — orbit-constancy of the fast canonical form; IS satisfied by `FastCanonicalImage` whenever the cyclic subgroup is normal in G |
| `two_phase_kem_correctness` (row #25) | Same `TwoPhaseDecomposition` as row #24 | Same `fast_kem_round_trip` (row #26) |

Each counterpart reduces to its deterministic predecessor at `ε = 0`
(perfect indistinguishability) and is trivially true at `ε = 1`
(advantage ≤ 1 always), so the definitions are satisfiable. For
scheme-level `ConcreteOIA` and the uniform-form `ConcreteKEMOIA_uniform`,
intermediate `ε` values genuinely parameterise realistic concrete
security. The point-mass `ConcreteKEMOIA` collapses on `ε ∈ [0, 1)`
(advantage is 0 or 1 per pair); see its docstring for the disclosure
and the uniform form for the ε-smooth alternative.

No `sorryAx` should appear in any output. If it does, there is a hidden
`sorry` in the dependency chain.

## Phase 16 Verification Audit Snapshot (2026-04-21)

Phase 16 (Formal Verification of New Components) consolidated the
per-workstream `#print axioms` checks into a single comprehensive audit
script (`scripts/audit_phase_16.lean`) and produced a prose verification
report (`docs/VERIFICATION_REPORT.md`).

The Phase 16 snapshot at the time of landing:

* **36** Lean source modules under `Orbcrypt/`, all building successfully
  via `lake build Orbcrypt` (3,364 jobs, zero errors, zero warnings).
* **0** uses of `sorry` anywhere in `Orbcrypt/**/*.lean` (verified by the
  comment-aware Perl strip used by CI).
* **0** custom `axiom` declarations anywhere in `Orbcrypt/`. Every
  `Prop`-valued security assumption (OIA, KEMOIA, ConcreteOIA, ConcreteKEMOIA,
  ConcreteTensorOIA, ConcreteCEOIA, ConcreteGIOIA, CompOIA,
  ObliviousSamplingHiding, ConcreteHardnessChain, …) is a `Prop`-valued
  *definition* carried as an explicit hypothesis on the theorems that
  use it.
* **342** declarations exercised by `scripts/audit_phase_16.lean` via
  `#print axioms` — every public `def`, `theorem`, `structure`,
  `class`, `instance`, and `abbrev` declared under
  `Orbcrypt/**/*.lean`. **All 342** depend only on the standard Lean
  axioms (`propext`, `Classical.choice`, `Quot.sound`); 133 depend on
  *no* axioms at all. **No `sorryAx`** appears in any output. The CI
  parser de-wraps Lean's multi-line axiom lists before scanning, so a
  custom axiom cannot hide on a continuation line.
* **343** public (non-`private`) declarations across the source tree;
  every one carries a `/-- … -/` docstring (Phase 6 standards retained
  through Phases 7–14).
* **5** intentionally `private` helper declarations
  (`Probability.Advantage.hybrid_argument_nat`,
  `AEAD.AEAD.{authDecaps_none_of_verify_false, keyDerive_canon_eq_of_mem_orbit}`,
  `PublicKey.CombineImpossibility.{probTrue_map_id_eq, probTrue_orbitDist_eq}`).
  Private-by-design, deliberately not part of the public API.

See `docs/VERIFICATION_REPORT.md` for the full per-headline breakdown,
the theorem inventory, the Phase 8 `sorry` classification, and the
known-limitations log (HSP / concrete tensor witness / research-scope
concrete Karp-encoding follow-ups).

## Workstream G Snapshot (audit 2026-04-21, finding H1)

Workstream G (Fix B + Fix C) lands the hardness-chain non-vacuity
refactor. The audit finding H1 showed that the pre-G
`UniversalConcreteTensorOIA εT` implicitly quantified over every
`G_TI : Type` and collapsed under `G_TI := PUnit` to "advantage ≤ 1" —
making the whole probabilistic chain vacuous at any εT < 1.

**Fix B: `SurrogateTensor F` parameter.** The chain now binds its
tensor-layer surrogate group explicitly through a structure
parameter. See `Orbcrypt/Hardness/TensorAction.lean`.

**Fix C: per-encoding reduction Props.** The three reduction links
(`*_viaEncoding`) carry explicit encoder functions and state
hardness transfer *through the specific encoder*, matching the
per-encoding shape used in cryptographic reduction literature. See
`Orbcrypt/Hardness/Reductions.lean`.

**Composition.** `concreteOIA_from_chain` threads advantage through
the chain-image — `encCG ∘ encTC` — without needing universal GI
hardness. Every link consumes exactly what the previous link
produces. Zero `sorry`, zero custom axioms.

**Non-vacuity.** `tight_one_exists` inhabits the chain at ε = 1 via
`punitSurrogate F` and dimension-0 trivial encoders.

**Research-scope follow-ups.** Concrete ε < 1 discharges of the
per-encoding reduction Props via (a) the Cai–Fürer–Immerman graph
gadget (1992), (b) the Grochow–Qiao structure-tensor encoding
(2021), and (c) CFI-indexed scheme instantiations are genuine
research-scope items tracked in
`docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 15.1. They
plug directly into the `*_viaEncoding` Props landed here without
further structural refactor.

**Module status post-G.** All 38 modules build clean; the full
Phase 16 audit script still emits only standard-trio axioms; 12
new declarations were added by Workstream G (the surrogate
structure + its four instance registrations + PUnit witness + three
per-encoding Props + three `_one_one` satisfiability witnesses);
the `ConcreteHardnessChain` structure gained a `SurrogateTensor`
parameter and two encoder fields in place of its pre-G implicit
universal quantifiers.

## Workstream H Snapshot (audit 2026-04-21, finding H2)

Workstream H lands the KEM-layer ε-smooth hardness chain, closing
finding H2 (MEDIUM). Pre-H, the KEM surface had two probabilistic
reductions (`concrete_kemoia_implies_secure` over the point-mass form
that collapses on `ε ∈ [0, 1)`, and `concrete_kemoia_uniform_implies_
secure` over the genuinely ε-smooth `ConcreteKEMOIA_uniform`), but no
**chain-level entry point** routing TI-hardness through to the
KEM-layer advantage bound.

**Additions (three new declarations in `Orbcrypt/KEM/CompSecurity.lean`).**

* `ConcreteOIAImpliesConcreteKEMOIAUniform scheme m₀ keyDerive ε ε'` —
  Prop-valued scheme-to-KEM reduction (H1). States "a `ConcreteOIA
  scheme ε` bound transfers to `ConcreteKEMOIA_uniform (scheme.toKEM
  m₀ keyDerive) ε'`". Parameterised by the KEM's anchor message `m₀`
  and its key-derivation function `keyDerive`. Carried as an abstract
  obligation matching the Workstream-G per-encoding-Prop pattern.
* `concreteOIAImpliesConcreteKEMOIAUniform_one_right` (H2) — trivial
  satisfiability witness at `ε' = 1`, discharging the Prop
  unconditionally from `concreteKEMOIA_uniform_one`.
* `ConcreteKEMHardnessChain scheme F S m₀ keyDerive ε` (H3) — KEM-layer
  chain structure bundling a `ConcreteHardnessChain scheme F S ε`
  (Workstream G) with a matched `ConcreteOIAImpliesConcreteKEMOIA-
  Uniform scheme m₀ keyDerive ε ε` field.
* `concreteKEMHardnessChain_implies_kemUniform` — composition theorem
  delivering `ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) ε`.
* `ConcreteKEMHardnessChain.tight_one_exists` — non-vacuity witness at
  ε = 1 via `punitSurrogate F`, dimension-0 trivial encoders, and the
  `_one_right` discharge.
* `concrete_kem_hardness_chain_implies_kem_advantage_bound` —
  end-to-end KEM-layer adversary bound:
  `kemAdvantage_uniform (scheme.toKEM m₀ keyDerive) A g_ref ≤ ε`.
  Composes `concreteKEMHardnessChain_implies_kemUniform` with
  `concrete_kemoia_uniform_implies_secure`. This is the KEM-layer
  parallel of the scheme-level
  `concrete_hardness_chain_implies_1cpa_advantage_bound` (Workstream
  E5).

**Layering.** `Orbcrypt/KEM/CompSecurity.lean` gained a new import
from `Orbcrypt/Hardness/Reductions.lean` (the KEM chain wraps the
scheme-level chain). No cycle is introduced: `Hardness/Reductions`
does not import `KEM/CompSecurity`.

**Cryptographic interpretation.** At ε < 1, the chain's ε bound
reflects the caller's choices of (a) tensor surrogate `S` and its
TI-hardness, (b) encoders `encTC`, `encCG` and their per-encoding
reduction Props, AND (c) the scheme-to-KEM reduction witness for the
specific `(m₀, keyDerive)` pair. At ε = 1 the chain is inhabited
trivially for any scheme / field / KEM anchor via `tight_one_exists`.
Concrete ε < 1 discharges of the scheme-to-KEM Prop (e.g. under a
`keyDerive` modelled as a random oracle) are research-scope items
analogous to Workstream G's encoder discharges.

**Research-scope follow-ups.** Concrete discharges of the
`ConcreteOIAImpliesConcreteKEMOIAUniform` Prop at ε' < 1 require
quantitative reasoning about the statistical behaviour of the
`keyDerive` map's push-forward on orbit samples. A natural setting
is the random-oracle idealisation (`keyDerive` sampled from an
idealised hash family); formalising that is tracked in the audit
plan as a follow-up parallel to § 15.1's Karp-encoding items.

**Module status post-H.** All 38 modules build clean; the full
Phase 16 audit script still emits only standard-trio axioms; 6 new
declarations were added by Workstream H (one Prop definition, one
satisfiability witness, one structure, one chain composition
theorem, one non-vacuity witness, and one end-to-end adversary-
bound composition theorem). The existing KEM-layer API is
unchanged — `ConcreteKEMOIA`, `ConcreteKEMOIA_uniform`,
`concrete_kemoia_implies_secure`, and
`concrete_kemoia_uniform_implies_secure` are all preserved; the
new chain structure and composition theorems are additive.

## Workstream K Snapshot (audit 2026-04-21, finding M1)

Workstream K lands the distinct-challenge IND-1-CPA corollaries,
closing finding M1 (MEDIUM). Pre-K, every downstream security
theorem concluded `IsSecure`, the uniform-challenge game that accepts
the degenerate collision choice `(m, m)` — strictly stronger than the
classical IND-1-CPA game `IsSecureDistinct` which a classical
challenger would enforce by rejecting `(m, m)` before sampling.
`isSecure_implies_isSecureDistinct` (Workstream B1) had the
unconditional bridge, but the downstream chain (OIAImpliesCPA,
HardnessChain, probabilistic chain) had never been rephrased in the
classical form.

**Additions (four new declarations across three modules).**

* `oia_implies_1cpa_distinct` (`Theorems/OIAImpliesCPA.lean`, K1) —
  deterministic scheme-level distinct-challenge corollary, composing
  `oia_implies_1cpa` with `isSecure_implies_isSecureDistinct`.
* `hardness_chain_implies_security_distinct`
  (`Hardness/Reductions.lean`, K3) — chain-level parallel, same
  composition pattern applied to `hardness_chain_implies_security`.
* `indCPAAdvantage_collision_zero` (`Crypto/CompSecurity.lean`, K4) —
  the structural fact that the probabilistic IND-1-CPA advantage
  vanishes on collision-choice adversaries. Proves via
  `advantage_self` on the two coincident orbit distributions. This is
  why the existing `concrete_oia_implies_1cpa` bound transfers to
  the distinct-challenge game for free.
* `concrete_hardness_chain_implies_1cpa_advantage_bound_distinct`
  (`Hardness/Reductions.lean`, K4 companion) — probabilistic
  chain-level bound restated in classical-game form. The
  distinctness hypothesis is carried as a signature marker but
  unused in the proof (bound holds unconditionally).

**K2 design note.** The `KEM/Security.lean` module gained an extended
docstring on `kemoia_implies_secure` documenting why no
`kemoia_implies_secure_distinct` corollary is introduced: the KEM
game parameterises adversaries by *group elements* (not messages),
so there is no challenge-distinctness analogue at the KEM layer.
The module docstring has the full rationale.

**Semantics and release messaging.** The deterministic `_distinct`
corollaries (K1, K3) inherit the scaffolding status of their
ancestors: the underlying `OIA` / `HardnessChain` hypothesis is
`False` on every non-trivial scheme, so the conclusion is vacuously
true on production instances. Cite them only to explain the
type-theoretic game-shape alignment, not as standalone security
claims. The probabilistic-chain K4 companion
(`concrete_hardness_chain_implies_1cpa_advantage_bound_distinct`)
retains the genuinely ε-smooth content of its non-distinct
ancestor (Workstream G); it is the release-facing citation when
external summaries want to match the literature's classical
IND-1-CPA game shape while still carrying quantitative content.

**Layering.** No new imports. The four new declarations land in
three existing modules (`Theorems/OIAImpliesCPA.lean`,
`Hardness/Reductions.lean`, `Crypto/CompSecurity.lean`) without
introducing dependencies. The `_distinct` corollaries are
expressible in terms of already-imported predicates
(`IsSecureDistinct` via `Crypto/Security.lean`, which is a
transitive import of all three files).

**Module status post-K.** All 38 modules build clean; the full
Phase 16 audit script still emits only standard-trio axioms; 4 new
declarations are axiom-free (K1 / K3 / K4 / K4 companion,
classified appropriately in the transparency report above). No
existing declaration is modified — the Workstream-K additions are
purely additive.

## Workstream L Snapshot (audit 2026-04-21, findings M2–M6)

Workstream L is the 2026-04-22 structural & naming hygiene batch,
closing audit findings M2–M6 (MEDIUM). It spans five sub-items
landed atomically in a single patch release (`lakefile.lean`
`0.1.5` → `0.1.6`):

### L1 — `SeedKey` witnessed compression (M2)

The module `Orbcrypt/KeyMgmt/SeedKey.lean` now carries a
machine-checkable compression witness. The `SeedKey` structure
takes `[Fintype Seed]` and `[Fintype G]` at the structure level
and has a new field
`compression : Nat.log 2 (Fintype.card Seed) <
Nat.log 2 (Fintype.card G)`, certifying "fewer bits of seed than
bits of group element." The plan originally contemplated option
(a) ("honest API" — drop the compression claim from the
docstring), but on 2026-04-22 the plan was revised to adopt
option (b) (witnessed compression) because leaving the claim
uncertified violates CLAUDE.md's "no half-finished
implementations" rule. The one-line sketch in the plan
(`8 * Fintype.card Seed < log₂ (Fintype.card G)`) was
dimensionally incorrect; the implementation uses the bit-length
form `Nat.log 2 (Fintype.card Seed) < Nat.log 2
(Fintype.card G)`.

Every downstream theorem in `SeedKey.lean` and `Nonce.lean`
threads `[Fintype Seed]` and `[Fintype G]`. The
`OrbitEncScheme.toSeedKey` bridge takes an `hGroupNontrivial :
1 < Fintype.card G` hypothesis and discharges `compression` at
`Seed = Unit` via `Nat.log_pos`. A concrete
`SeedKey (Fin 2) (Equiv.Perm (Fin 3)) Unit` witness in
`scripts/audit_phase_16.lean` discharges `compression` by
`decide` (`Nat.log 2 2 = 1 < 2 = Nat.log 2 6`).

### L2 — Carter–Wegman universal-hash MAC (M3, upgraded post-audit)

`Orbcrypt/AEAD/CarterWegmanMAC.lean` is the canonical Carter–Wegman
universal-hash MAC.  The L-workstream post-audit pass (2026-04-22)
upgraded the initial landing:

* **Initial landing.** `[NeZero p]` + docstring disclaimer that
  `carterWegmanMAC` names the "linear hash shape, not the
  universal-hash security property."  This failed CLAUDE.md's
  **"Security-by-docstring prohibition"** rule: an identifier that
  names a cryptographic primitive must *prove* the security
  property, not disclaim it.

* **Post-audit upgrade.** `[Fact (Nat.Prime p)]` replaces `[NeZero p]`
  on all `carterWegman*` definitions.  A new module
  `Orbcrypt/Probability/UniversalHash.lean` defines `IsEpsilonUniversal
  (h : K → Msg → Tag) (ε : ℝ≥0∞)`, the Carter–Wegman 1977 ε-universal
  pair-collision bound.  The headline theorem
  `carterWegmanHash_isUniversal` proves the CW linear hash family is
  `(1/p)`-universal over the prime field `ZMod p`.  The proof proceeds
  by counting: the collision set `{k : (ZMod p)² | h k m₁ = h k m₂}`
  for distinct `m₁ ≠ m₂` has cardinality exactly `p`
  (`carterWegmanHash_collision_card`), and the uniform distribution
  over `(ZMod p)²` assigns probability `p/p² = 1/p` to this set.

The primality constraint is **mathematical, not cosmetic**: it is
the precondition for `ZMod p` to be a field, which is required for
the algebraic collision analysis `k₁ · (m₁ - m₂) = 0 → k₁ = 0`
(`mul_eq_zero` in a field + `m₁ - m₂ ≠ 0`).  Dropping primality
would leave the MAC structure without the universal-hash Prop the
name promises.

Mathlib provides `fact_prime_two : Fact (Nat.Prime 2)` and
`fact_prime_three : Fact (Nat.Prime 3)`, so the audit scripts at
`p = 2, p = 3` auto-resolve the Fact.  The former audit script
instantiation at `p = 1` (not prime) is replaced by `p = 2` in
`scripts/audit_c_workstream.lean`.

### L3 — `RefreshIndependent` rename (M4)

`Orbcrypt/PublicKey/ObliviousSampling.lean`: `RefreshIndependent`
/ `refresh_independent` renamed to `RefreshDependsOnlyOnEpochRange`
/ `refresh_depends_only_on_epoch_range`. The content is a
`funext`-structural identity (not a cryptographic independence
claim), and the name now reflects that. Downstream references
updated across source, audit scripts, and docs.

### L4 — `SymmetricKeyAgreementLimitation` rename (M5)

`Orbcrypt/PublicKey/KEMAgreement.lean`:
`SymmetricKeyAgreementLimitation` /
`symmetric_key_agreement_limitation` renamed to
`SessionKeyExpansionIdentity` / `sessionKey_expands_to_canon_form`.
The content is a `rfl`-level decomposition identity exhibiting
`sessionKey a b` as the combiner of both parties' secret
`keyDerive ∘ canonForm.canon` outputs — **not** an impossibility
claim. A separate impossibility discussion lives in
`docs/PUBLIC_KEY_ANALYSIS.md` and is out of scope for this
module.

### L5 — `KEMOIA` redundant-conjunct removal (M6)

`Orbcrypt/KEM/Security.lean`: `KEMOIA` is now **single-conjunct**
(orbit indistinguishability only). The pre-L5 second conjunct
"key uniformity across the orbit" was unconditionally provable
from `canonical_isGInvariant` via the still-present
`kem_key_constant_direct`, so it carried no assumption content.
Pre-L5 `kem_key_constant` (which extracted `hOIA.2 g`) is
**deleted** — CLAUDE.md forbids backwards-compat shims;
`kem_key_constant_direct` is the authoritative form.
`kemoia_implies_secure` and
`det_kemoia_implies_concreteKEMOIA_zero` updated to invoke
`kem_key_constant_direct` where they previously extracted
`hOIA.2`, and to use `hOIA` directly (not `hOIA.1`) for the
single-conjunct orbit indistinguishability.

### Module status post-L

All 38 modules build clean (38-module total unchanged — no new
`.lean` files; Workstream L's changes land inside existing
modules). Every Workstream-L declaration depends only on
standard-trio axioms (`propext`, `Classical.choice`,
`Quot.sound`); none depend on `sorryAx` or a custom axiom. Net
declaration count delta: `kem_key_constant` removed (−1),
`compression` structure field added (+1); zero net change.

### Vacuity map (Workstream L additions)

* `SeedKey.compression` — **unconditional structural field**
  (no hypothesis). Discharged per-instance by `decide` (concrete
  Fintype) or `Nat.log_pos` (bridge).
* `RefreshDependsOnlyOnEpochRange` — **unconditionally true**
  per `refresh_depends_only_on_epoch_range`; structural.
* `SessionKeyExpansionIdentity` — **unconditionally true** per
  `sessionKey_expands_to_canon_form`; a `rfl`-level identity.
* `KEMOIA` (single-conjunct) — inherits the **scaffolding**
  status of the orbit-indistinguishability conjunct; `False` on
  every non-trivial scheme (the `decide (x = basePoint)`
  distinguisher refutes it). Workstream E's `ConcreteKEMOIA` /
  `ConcreteKEMOIA_uniform` remain the quantitative KEM-layer
  predicates.

## Workstream M Snapshot (audit 2026-04-21, findings L1–L8)

Workstream M is the 2026-04-23 low-priority polish batch, closing
eight `LOW`-severity audit findings (`F-AUDIT-2026-04-21-L1` through
`L8`). Seven of the eight sub-items are documentation-only docstring
refinements that disclose the scaffolding / vacuity status of
pre-existing declarations; the eighth (M1) is a source-level universe
polymorphism generalisation of `SurrogateTensor F`. No headline
theorems are added, removed, or restated; no public API surface
changes; every in-tree build, audit script, and CI step continues to
pass with the standard-Lean-trio axiom posture.

### M1 — `SurrogateTensor` universe polymorphism (L1)

`Orbcrypt/Hardness/TensorAction.lean`: the structure's `carrier`
field is generalised from `Type` (universe 0) to `Type u` via a
module-level `universe u` declaration. Downstream code (the
`surrogateTensor_group` / `_fintype` / `_nonempty` / `_mulAction`
instances, `UniversalConcreteTensorOIA`,
`ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`,
`ConcreteHardnessChain`, `ConcreteKEMHardnessChain`) inherits the
generalisation transparently via typeclass inference and
`Type*`-polymorphic downstream signatures. `punitSurrogate` is
explicitly pinned to `SurrogateTensor.{0} F` (PUnit at Type 0) so
non-vacuity witnesses continue to elaborate without manual universe
threading; callers wanting surrogates at higher universes supply
their own `SurrogateTensor.{u} F` value. The audit's original concern
(`{G_TI : Type}` vs `{G_TI : Type*}` on the pre-Workstream-G implicit
binder) was moot post-G because the surrogate became a named
parameter, but this follow-up upgrade lets callers supply
universe-polymorphic carriers (e.g. a subgroup of a matrix group
over a universe-polymorphic field) without universe-mismatch errors.

### M2 — `hybrid_argument_uniform` docstring (L2)

`Orbcrypt/Probability/Advantage.lean`: the docstring now states
explicitly that no `0 ≤ ε` hypothesis is carried at the signature,
and that for `ε < 0` the per-step bound `h_step` is unsatisfiable
(advantage is always `≥ 0` via `advantage_nonneg`), so the
conclusion holds vacuously. Intended use case: `ε ∈ [0, 1]`.

### M3 — Deterministic-reduction existentials (L3)

`Orbcrypt/Hardness/Reductions.lean`: the docstrings of
`TensorOIAImpliesCEOIA`, `CEOIAImpliesGIOIA`, and `GIOIAImpliesOIA`
now document that their existentials admit trivial satisfiers
(`k = 0, C₀ = C₁ = ∅` / `k = 0` on adjacency matrices) and that
these deterministic Props are therefore *algebraic scaffolding*, not
quantitative hardness transfer. Each docstring points callers at the
Workstream G per-encoding probabilistic counterpart
(`*_viaEncoding`) for the non-vacuous ε-smooth form.

### M4 — Degenerate encoders in `GIReducesToCE` / `GIReducesToTI` (L4)

`Orbcrypt/Hardness/CodeEquivalence.lean` and
`Orbcrypt/Hardness/TensorAction.lean`: the docstrings now disclose
that both deterministic Karp-claim Props admit degenerate encoders
(e.g. `encode _ := ∅` / constant 0-dimensional tensors) because they
state reductions at the *orbit-equivalence level*, not the advantage
level. This is intentional: they are scaffolding Props expressing
the *existence* of a Karp reduction. Quantitative hardness transfer
at ε < 1 lives in the Workstream G probabilistic counterparts, which
name explicit encoders.

### M5 — Invariant-attack advantage framing (L5)

`Orbcrypt/Theorems/InvariantAttack.lean`: the `invariant_attack`
docstring now explains that the theorem proves *deterministic
advantage = 1* (the existence of a specific `(g₀, g₁)` pair yielding
disagreeing guesses). Three literature conventions for "adversary
advantage" (two-distribution, centred, deterministic) are catalogued;
all three agree on the "complete break" outcome witnessed here but
differ by a factor of 2 on intermediate advantages. Consumers
computing concrete security parameters should note which convention
their downstream analysis uses.

### M6 — `hammingWeight_invariant_subgroup` pattern cleanup (L6)

`Orbcrypt/Construction/HGOE.lean`: the anonymous destructuring
pattern `⟨σ, _⟩` (which silently discarded the membership proof) is
replaced with a named binder `g` and an explicit coercion
`↑g : Equiv.Perm (Fin n)`. The two forms are proof-equivalent; the
new form is Mathlib-idiomatic style. `#print axioms
hammingWeight_invariant_subgroup` is unchanged
(`[propext, Classical.choice, Quot.sound]`).

### M7 — `IsNegligible` `n = 0` convention (L7)

`Orbcrypt/Probability/Negligible.lean`: the `IsNegligible` docstring
now documents Lean's `(0 : ℝ)⁻¹ = 0` convention and its effect at
`n = 0`: the clause `|f n| < (n : ℝ)⁻¹ ^ c` reduces to `|f 0| < 0`
for `c ≥ 1` (trivially false) or `|f 0| < 1` at `c = 0`. All
in-tree proofs of `IsNegligible f` (`isNegligible_zero`,
`isNegligible_const_zero`, `IsNegligible.add`,
`IsNegligible.mul_const`) choose `n₀ ≥ 1` to side-step the edge
case; the intended semantics is the standard "eventually" form.

### M8 — `combinerOrbitDist_mass_bounds` negative example (L8)

`Orbcrypt/PublicKey/CombineImpossibility.lean`: the docstring now
includes a concrete negative example (two hypothetical messages
sharing an orbit under `G`) demonstrating that intra-orbit mass
bounds do not imply cross-orbit advantage lower bounds. The example
is hypothetical because `OrbitEncScheme.reps_distinct` prohibits the
shared-orbit case at the scheme level, but it illustrates the
information-theoretic gap that any concrete cross-orbit advantage
lower bound must bridge with problem-specific structure.

### Module status post-M

All 38 modules build clean (3,367 jobs, zero errors, zero warnings).
Every Workstream-M declaration and docstring change preserves the
standard-trio axiom posture (`propext`, `Classical.choice`,
`Quot.sound`); zero `sorryAx`, zero custom axioms. Public
declaration count unchanged; net structural change is the
`SurrogateTensor.carrier : Type → Type u` generalisation (no new or
removed declarations, no new modules). The `compression` witness on
`SeedKey` (Workstream L1), the Workstream-G surrogate + encoder
infrastructure, the Workstream-H KEM-layer chain, the Workstream-K
distinct-challenge corollaries, and the Workstream-L structural
renames all continue to elaborate at the new universe polymorphism
without audit-script changes.

### Patch version

`lakefile.lean` retains `0.1.6`; Workstream M is additive
(docstring-only for seven sub-items, source-level universe
polymorphism for M1). The 38-module total is unchanged; the
347-public-declaration count from Workstream K holds; no new
headline theorems.
-/
