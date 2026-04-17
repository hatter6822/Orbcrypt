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

import Orbcrypt.Crypto.CompOIA
import Orbcrypt.Crypto.CompSecurity

import Orbcrypt.Construction.Permutation
import Orbcrypt.Construction.HGOE
import Orbcrypt.Construction.HGOEKEM

import Orbcrypt.KeyMgmt.SeedKey
import Orbcrypt.KeyMgmt.Nonce

import Orbcrypt.AEAD.MAC
import Orbcrypt.AEAD.AEAD
import Orbcrypt.AEAD.Modes

import Orbcrypt.Hardness.CodeEquivalence
import Orbcrypt.Hardness.TensorAction
import Orbcrypt.Hardness.Reductions

import Orbcrypt.PublicKey.ObliviousSampling
import Orbcrypt.PublicKey.KEMAgreement
import Orbcrypt.PublicKey.CommutativeAction
import Orbcrypt.PublicKey.CombineImpossibility

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
          ├────────────────────────┐
          ▼                        ▼
  Probability.Advantage    Probability.Negligible
  ◄── advantage, triangle  ◄── IsNegligible
  ◄── hybrid_argument      ◄── add closure
          │                        │
          ├────────────────────────┘
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
  ◄── MAC structure (tag, verify, correct)
          │
          ▼
  AEAD.AEAD ◄── AEAD.MAC, KEM.Syntax, KEM.Encapsulate, KEM.Correctness
  ◄── AuthOrbitKEM, authEncaps, authDecaps
  ◄── aead_correctness, INT_CTXT

  AEAD.Modes ◄── KEM.Syntax, KEM.Encapsulate
  ◄── DEM, hybridEncrypt, hybridDecrypt
  ◄── hybrid_correctness

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
  ◄── RefreshIndependent, refresh_independent

  PublicKey.KEMAgreement ◄── KEM.Encapsulate, KEM.Correctness
  ◄── OrbitKeyAgreement, sessionKey
  ◄── kem_agreement_correctness
  ◄── SymmetricKeyAgreementLimitation

  PublicKey.CommutativeAction ◄── GroupAction.Basic, GroupAction.Canonical
  ◄── CommGroupAction (class), csidh_exchange
  ◄── csidh_correctness
  ◄── CommOrbitPKE, comm_pke_correctness
```

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

kem_correctness (KEM/Correctness.lean)
  └── (definitional — rfl)

kemoia_implies_secure (KEM/Security.lean)
  ├── kem_key_constant                — key constancy from KEMOIA.2 (7.6a)
  ├── kem_ciphertext_indistinguishable — orbit indist. from KEMOIA.1 (7.6b)
  └── KEMOIA (hypothesis)             — KEM Orbit Indist. Assumption

concrete_oia_implies_1cpa (Crypto/CompSecurity.lean)
  ├── ConcreteOIA (hypothesis)   — probabilistic orbit indistinguishability
  ├── indCPAAdvantage            — probabilistic IND-1-CPA advantage (8.6)
  ├── advantage                  — distinguishing advantage (8.3)
  └── orbitDist                  — orbit sampling distribution (8.4)

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

hybrid_correctness (AEAD/Modes.lean)
  ├── kem_correctness             — KEM correctness (7.3)
  └── DEM.correct                 — DEM correctness field (10.5)

oblivious_sample_in_orbit (PublicKey/ObliviousSampling.lean)
  └── OrbitalRandomizers.in_orbit — randomizer orbit certificate (13.1)

refresh_independent (PublicKey/ObliviousSampling.lean)
  └── (structural — `funext` + hypothesis)

kem_agreement_correctness (PublicKey/KEMAgreement.lean)
  └── kem_correctness             — KEM correctness (7.3)

csidh_correctness (PublicKey/CommutativeAction.lean)
  └── CommGroupAction.comm        — commutativity axiom of the class (13.5)

comm_pke_correctness (PublicKey/CommutativeAction.lean)
  ├── CommGroupAction.comm        — commutativity axiom of the class (13.5)
  └── CommOrbitPKE.pk_valid       — public-key validity field (13.6)
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
- All `Probability/` lemmas — advantage, negligible, hybrid argument
- `concreteOIA_one` (`Crypto/CompOIA.lean`) — ConcreteOIA(1) is always true
- `seed_kem_correctness` (`KeyMgmt/SeedKey.lean`) — seed-based KEM correctness
- `seed_determines_key` (`KeyMgmt/SeedKey.lean`) — equal seeds → equal key material
- `nonce_encaps_correctness` (`KeyMgmt/Nonce.lean`) — nonce-based KEM correctness
- `nonce_reuse_leaks_orbit` (`KeyMgmt/Nonce.lean`) — cross-KEM nonce reuse leaks
  orbit membership (unconditional warning theorem)
- All `KeyMgmt/` lemmas — seed keys, nonce encapsulation, backward compatibility
- `aead_correctness` (`AEAD/AEAD.lean`) — authenticated KEM correctness
- `hybrid_correctness` (`AEAD/Modes.lean`) — KEM+DEM hybrid correctness
- All `AEAD/` definitions and lemmas — MAC, AuthOrbitKEM, DEM, INT_CTXT
- All `Hardness/` definitions and lemmas — CE, TI, tensor action, reductions
- `areTensorIsomorphic_refl` (`Hardness/TensorAction.lean`) — TI reflexivity
- `areTensorIsomorphic_symm` (`Hardness/TensorAction.lean`) — TI symmetry
- `arePermEquivalent_refl` (`Hardness/CodeEquivalence.lean`) — CE reflexivity
- `paut_compose_preserves_equivalence` (`Hardness/CodeEquivalence.lean`) —
  PAut coset structure

### OIA-dependent results (conditional)

These theorems carry `OIA`, `KEMOIA`, `ConcreteOIA`, or `CompOIA` as an
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
- `refresh_independent` (`PublicKey/ObliviousSampling.lean`) — structural
  independence of epoch-refreshed randomizer bundles (unconditional; PRF
  security remains a separate sampler-level assumption).
- `kem_agreement_correctness` (`PublicKey/KEMAgreement.lean`) — follows
  from `kem_correctness`; establishes that two formulations of the
  session-key computation coincide.
- `symmetric_key_agreement_limitation` (`PublicKey/KEMAgreement.lean`)
  — an unconditional structural identity exhibiting the session-key
  formula in terms of both parties' `keyDerive` and `canonForm.canon`,
  making formal that the protocol is symmetric-setup.
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

#print axioms Orbcrypt.hybrid_correctness
-- (standard Lean only — follows from kem_correctness + DEM.correct)

#print axioms Orbcrypt.hardness_chain_implies_security
-- (standard Lean only — HardnessChain appears as a hypothesis)

#print axioms Orbcrypt.oblivious_sample_in_orbit
-- (standard Lean only — closure proof is a hypothesis)

#print axioms Orbcrypt.refresh_independent
-- (standard Lean only — structural)

#print axioms Orbcrypt.kem_agreement_correctness
-- (standard Lean only — follows from kem_correctness)

#print axioms Orbcrypt.csidh_correctness
-- (standard Lean only — extracts CommGroupAction.comm typeclass axiom)

#print axioms Orbcrypt.comm_pke_correctness
-- (standard Lean only — uses CommGroupAction.comm and pk_valid)
```

No `sorryAx` should appear in any output. If it does, there is a hidden
`sorry` in the dependency chain.
-/
