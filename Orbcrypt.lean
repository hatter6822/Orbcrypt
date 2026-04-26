import Orbcrypt.GroupAction.Basic
import Orbcrypt.GroupAction.Canonical
import Orbcrypt.GroupAction.CanonicalLexMin
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
import Orbcrypt.Hardness.PetrankRoth.BitLayout
import Orbcrypt.Hardness.PetrankRoth
import Orbcrypt.Hardness.PetrankRoth.MarkerForcing
import Orbcrypt.Hardness.GrochowQiao.PathAlgebra
import Orbcrypt.Hardness.GrochowQiao.StructureTensor
import Orbcrypt.Hardness.GrochowQiao.Forward
import Orbcrypt.Hardness.GrochowQiao.Reverse
import Orbcrypt.Hardness.GrochowQiao

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
GroupAction.CanonicalLexMin (Workstream F: ofLexMin constructor on
                             [Group G] [MulAction G X] [Fintype G]
                             [DecidableEq X] [LinearOrder X])
          │
          ▼
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
   (also provides `bitstringLinearOrder`,
    a computable lex `LinearOrder (Bitstring n)` matching the
    GAP reference's `CanonicalImage(G, x, OnSets)` convention
    via `LinearOrder.lift' (List.ofFn ∘ (! ∘ ·))`; Workstream F)
          │
          ▼
Construction.HGOE              Construction.HGOEKEM
◄── Crypto.Security            ◄── Construction.HGOE
◄── Theorems.Correctness       ◄── KEM.Correctness
◄── Theorems.InvariantAttack   ◄── KEM.Security
◄── GroupAction.CanonicalLexMin
    (for `hgoeScheme.ofLexMin`, Workstream F)

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
  PublicKey.ObliviousSampling ◄── GroupAction.Basic,
                                   Probability.{Monad, Advantage},
                                   Crypto.CompOIA
  ◄── OrbitalRandomizers, obliviousSample
  ◄── oblivious_sample_in_orbit
  ◄── ObliviousSamplingPerfectHiding (renamed from
        `ObliviousSamplingHiding` in Workstream I6 of the 2026-04-23
        audit, finding K-02),
        oblivious_sampling_view_constant_under_perfect_hiding
  ◄── ObliviousSamplingConcreteHiding,
        oblivious_sampling_view_advantage_bound,
        ObliviousSamplingConcreteHiding_zero_witness
        (probabilistic ε-smooth replacement and non-vacuity witness;
         Workstream I6, audit K-02)
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

authEncrypt_is_int_ctxt (AEAD/AEAD.lean)     ◄── Workstream C2 (audit F-07),
                                                 refactored by Workstream B
                                                 (audit 2026-04-23, V1-1 / I-03)
  ├── MAC.verify_inj              — tag uniqueness (Workstream C1)
  ├── canon_eq_of_mem_orbit       — canonical form invariance (2.6)
  └── hOrbit (INT_CTXT binder)    — per-challenge well-formedness precondition
                                     absorbing the pre-B `hOrbitCover`
                                     theorem-level hypothesis into the game

carterWegmanMAC_int_ctxt (AEAD/CarterWegmanMAC.lean) ◄── Workstream C4,
                                                         Workstream B
  ├── authEncrypt_is_int_ctxt     — composed INT_CTXT proof (unconditional
                                     post-B: no `hOrbitCover` argument)
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
  implies `∃ A, hasAdvantage` (existence of one distinguishing adversary;
  informal shorthand "complete break" — see the `invariant_attack` docstring
  for the three-convention advantage catalogue)
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
  honestly-composed AuthOrbitKEMs; audit finding F-07 (Workstream C2).
  Post-audit 2026-04-23 Workstream B (V1-1 / I-03), the orbit-cover
  condition is absorbed into the `INT_CTXT` game as a per-challenge
  well-formedness precondition; the theorem now discharges `INT_CTXT`
  unconditionally on every `AuthOrbitKEM`.
- `carterWegmanMAC_int_ctxt` (`AEAD/CarterWegmanMAC.lean`) — concrete
  INT_CTXT witness via the Carter–Wegman universal-hash MAC; audit
  finding F-07 (Workstream C4), inheriting the Workstream-B
  unconditionality (no `hOrbitCover` argument).
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
- `indQCPA_from_perStepBound` (`Crypto/CompSecurity.lean`) — Q-query
  IND-Q-CPA advantage ≤ Q · ε via the hybrid argument, given a per-step
  bound `h_step` as a **caller-supplied hypothesis** (E8c). Renamed
  from `indQCPA_bound_via_hybrid` in Workstream C (audit 2026-04-23,
  V1-8 / C-13) to surface the user-hypothesis obligation in the
  identifier itself; discharging `h_step` from `ConcreteOIA` alone is
  research-scope R-09.
- `indQCPA_from_perStepBound_recovers_single_query`
  (`Crypto/CompSecurity.lean`) — Q = 1 regression sentinel (E8d);
  companion renamed with the same `from_perStepBound` prefix for
  naming consistency.

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
- `oblivious_sampling_view_constant_under_perfect_hiding`
  (`PublicKey/ObliviousSampling.lean`) — carries
  `ObliviousSamplingPerfectHiding` as a hypothesis (a strong
  deterministic hiding requirement that is `False` on every non-
  trivial bundle, hence vacuous on production HGOE). Renamed in
  Workstream I6 of the 2026-04-23 audit (finding K-02) to accurately
  convey its perfect-extremum strength. The genuinely ε-smooth
  probabilistic analogue `ObliviousSamplingConcreteHiding` is added
  alongside in the same workstream, with a perfect-security non-
  vacuity witness `ObliviousSamplingConcreteHiding_zero_witness`
  at ε = 0 on singleton-orbit bundles.
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
--  the orbit condition lives on the `INT_CTXT` game as a per-challenge
--  well-formedness precondition `hOrbit` post-audit 2026-04-23
--  Workstream B, not on the theorem signature. `INT_CTXT` discharges
--  unconditionally on every `AuthOrbitKEM`.)

#print axioms Orbcrypt.carterWegmanMAC_int_ctxt
-- (standard Lean only — direct specialisation of authEncrypt_is_int_ctxt;
--  post-audit 2026-04-22 requires `[Fact (Nat.Prime p)]`;
--  post-audit 2026-04-23 Workstream B drops the `hOrbitCover` argument
--  — the theorem is unconditional in orbit content, only the
--  `X = ZMod p` / HGOE `Bitstring n` incompatibility remains, tracked
--  as research milestone R-13.)

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

-- Workstream E (audit 2026-04-23, findings C-07 + E-06):
-- machine-checked vacuity witnesses for the deterministic OIA and
-- KEMOIA predicates.

#print axioms Orbcrypt.det_oia_false_of_distinct_reps
-- (standard Lean only — formal discharge of the scheme-level
--  vacuity claim that the module docstring of `Crypto/OIA.lean`
--  previously asserted only in prose. Any scheme with two
--  distinct representatives (`reps m₀ ≠ reps m₁`) falsifies
--  `OIA scheme` via the membership-at-`reps m₀` Boolean
--  distinguisher. Standalone; safe to cite directly.)

#print axioms Orbcrypt.det_kemoia_false_of_nontrivial_orbit
-- (standard Lean only — KEM-layer parallel of the scheme-level
--  witness above. Any KEM whose base-point orbit contains two
--  distinct ciphertexts (`g₀ • basePoint ≠ g₁ • basePoint`)
--  falsifies `KEMOIA kem` via the membership-at-`g₀ • basePoint`
--  Boolean distinguisher. Standalone.)

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

#print axioms Orbcrypt.indQCPA_from_perStepBound
-- (standard Lean only — per-step bound h_step carried as user-supplied
--  hypothesis; telescopes via hybrid_argument_uniform, Workstream E8c;
--  renamed from `indQCPA_bound_via_hybrid` by Workstream C of audit
--  2026-04-23 (V1-8 / C-13) to surface the h_step obligation in the
--  identifier itself)

#print axioms Orbcrypt.indQCPA_from_perStepBound_recovers_single_query
-- (standard Lean only — Q = 1 regression, Workstream E8d; renamed from
--  `indQCPA_bound_recovers_single_query` by Workstream C of audit
--  2026-04-23 for naming consistency)

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
predecessor. The final column names the **machine-checked vacuity
witness** theorem (where applicable) — a formal `¬ (OIA-variant)`
discharge under a mild distinctness hypothesis that every non-trivial
scheme satisfies. These witnesses close the audit 2026-04-23 findings
C-07 and E-06 by replacing prose-level vacuity disclosures with Lean
proofs. The pairing:

| Pre-Workstream-E (vacuous today) | Workstream-E/G/H counterpart (non-vacuous) | Machine-checked vacuity witness |
|---|---|---|
| `oia_implies_1cpa` | `concrete_oia_implies_1cpa` (Phase 8, already) | `det_oia_false_of_distinct_reps` (Workstream E of audit 2026-04-23, C-07) — `OIA scheme` is `False` when `scheme.reps m₀ ≠ scheme.reps m₁` |
| `kemoia_implies_secure` | `concrete_kemoia_implies_secure` (E1d, point-mass) + `concrete_kemoia_uniform_implies_secure` (E1d, uniform form — genuinely ε-smooth) | `det_kemoia_false_of_nontrivial_orbit` (Workstream E of audit 2026-04-23, E-06) — `KEMOIA kem` is `False` when `g₀ • basePoint ≠ g₁ • basePoint` |
| `hardness_chain_implies_security` | `concrete_hardness_chain_implies_1cpa_advantage_bound` (E5, post-G signature threads `SurrogateTensor`) — **ε = 1 inhabited only via `ConcreteHardnessChain.tight_one_exists` (`punitSurrogate F` + dimension-0 trivial encoders); ε < 1 requires a caller-supplied `SurrogateTensor F` + encoder pair with genuine cryptographic hardness (research-scope — see § O of the 2026-04-23 plan: R-02 / R-03 / R-04)** | Composed from `OIA` via the deterministic chain; the terminal vacuity is witnessed by `det_oia_false_of_distinct_reps` (the chain's conclusion `IsSecure scheme` is the OIA→CPA reduction target, which collapses once its OIA hypothesis is refuted) |
| `equivariant_combiner_breaks_oia` | `concrete_combiner_advantage_bounded_by_oia` (E6) | — (the deterministic antecedent carries `OIA scheme` as a hypothesis; `det_oia_false_of_distinct_reps` refutes that hypothesis on every non-trivial scheme) |
| *multi-query extension (implicit)* | `indQCPA_from_perStepBound` (E8c, renamed by Workstream C of 2026-04-23 audit from `indQCPA_bound_via_hybrid` — finding V1-8 / C-13) — **carries `h_step` as a user-supplied hypothesis; discharge from `ConcreteOIA` alone is research-scope R-09 (see § O of the 2026-04-23 plan). The `from_perStepBound` suffix surfaces the obligation in the identifier itself per `CLAUDE.md`'s naming rule that identifiers describe what the code *proves*, not what it *aspires to*.** | — (no deterministic pre-E antecedent; the multi-query statement lives only in the probabilistic chain) |
| *KEM-layer chain (missing pre-H)* | `concreteKEMHardnessChain_implies_kemUniform` (H3) — KEM-layer ε-smooth chain built from Workstream G's `ConcreteHardnessChain` + the Workstream H1 scheme-to-KEM reduction Prop. **ε = 1 inhabited only via `ConcreteKEMHardnessChain.tight_one_exists`; ε < 1 requires caller-supplied scheme-to-KEM reduction witness at `(m₀, keyDerive)` — research-scope R-05** | `det_kemoia_false_of_nontrivial_orbit` applies to the KEM-layer terminal hypothesis (`KEMOIA`), though the scheme-to-KEM bridge at ε < 1 is itself a research-scope obligation |
| *KEM adversary bound (missing pre-H)* | `concrete_kem_hardness_chain_implies_kem_advantage_bound` (H3) — end-to-end KEM-layer adversary bound, parallel of scheme-level `concrete_hardness_chain_implies_1cpa_advantage_bound`. **Same ε = 1 disclosure as the scheme-level parallel; ε < 1 requires the composition of R-02/R-03/R-04 (scheme-level chain) and R-05 (scheme-to-KEM reduction)** | Same as the row above (terminal hypothesis is `KEMOIA`, refuted by `det_kemoia_false_of_nontrivial_orbit`) |
| `oia_implies_1cpa` (uniform game) | `oia_implies_1cpa_distinct` (K1) — same scaffolding status, classical-IND-1-CPA signature matching the literature | Inherits `det_oia_false_of_distinct_reps` (antecedent is `OIA scheme`) |
| `hardness_chain_implies_security` (uniform game) | `hardness_chain_implies_security_distinct` (K3) — same scaffolding status, classical-IND-1-CPA signature | Inherits `det_oia_false_of_distinct_reps` via `oia_from_hardness_chain` |
| `concrete_oia_implies_1cpa` (unconditional over `Adversary`) | `indCPAAdvantage_collision_zero` + `concrete_oia_implies_1cpa` docstring (K4) — the collision case yields advantage 0, so the existing probabilistic `≤ ε` bound transfers to the classical distinct-challenge game for free | — (probabilistic counterpart is genuinely ε-smooth; no vacuity to discharge) |
| `concrete_hardness_chain_implies_1cpa_advantage_bound` (unconditional over `Adversary`) | `concrete_hardness_chain_implies_1cpa_advantage_bound_distinct` (K4 companion) — classical-IND-1-CPA restatement retaining the ε-smooth quantitative content. **Same ε = 1 disclosure as the non-distinct form** | — (probabilistic; no vacuity) |

### Vacuity map (2026-04-23 Workstream A additions — Conditional-status rows)

These rows record the 2026-04-23 audit's documentation-vs-code
reconciliation: each of the four `CLAUDE.md` rows reclassified from
**Standalone** to **Conditional** has an explicitly disclosed
hypothesis, which fails on production instances. Where a genuinely
standalone sibling theorem exists, it is named.

| Conditional theorem (Lean content) | Failing hypothesis | Standalone sibling (cite instead) |
|---|---|---|
| `authEncrypt_is_int_ctxt` (row #19) | ~~`hOrbitCover : ∀ c : X, c ∈ orbit G basePoint` — False on production HGOE~~. **Closed by audit 2026-04-23 Workstream B (2026-04-24).** The orbit condition is now a per-challenge well-formedness precondition `hOrbit` *on the `INT_CTXT` game itself*, not a theorem-level obligation. Row #19 is now **Standalone**: `authEncrypt_is_int_ctxt` discharges `INT_CTXT` unconditionally on every `AuthOrbitKEM` | `keyDerive_canon_eq_of_mem_orbit` (orbit-restricted key uniqueness; unconditional, still useful as the internal lemma at the heart of the proof) |
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

### Vacuity map (2026-04-23 Workstream I additions — strengthening, not rebadging)

Workstream I (audit 2026-04-23, findings C-15 / D-07 / E-11 / J-03 /
J-08 / K-02) replaces six pre-I weak identifiers with strengthened
substantive content. The pairing — pre-I weak-content identifier ↔
post-I substantive sibling:

| Pre-I weak identifier | Workstream-I substantive sibling | Strengthening summary |
|---|---|---|
| `concreteOIA_one_meaningful` (renamed `indCPAAdvantage_le_one`; trivial `≤ 1` bound, content unchanged) | `concreteOIA_zero_of_subsingleton_message` (I1) — perfect concrete-security at ε = 0 on every subsingleton-message scheme | Pre-I name overstated content (the bound is a triangle-inequality artefact of `advantage`, not a non-vacuity claim about `ConcreteOIA`); post-I delivers genuine perfect-security extremum |
| `concreteKEMOIA_one_meaningful` (deleted as redundant duplicate of `kemAdvantage_le_one`) | `concreteKEMOIA_uniform_zero_of_singleton_orbit` (I2) — perfect uniform-form KEM security at ε = 0 on every singleton-orbit KEM | Pre-I lemma was bit-identical to `kemAdvantage_le_one`; post-I delivers KEM-layer parallel of I1's perfect-security extremum |
| `insecure_implies_separating` (renamed `insecure_implies_orbit_distinguisher`; orbit distinguisher, not G-invariant separator) | `distinct_messages_have_invariant_separator` (I3) — G-invariant Boolean separator from `reps_distinct`, unconditional on adversary | Pre-I name suggested G-invariance + separation; body delivered only the second conjunct (a non-G-invariant distinguisher). Post-I delivers genuine G-invariance via `canon_indicator_isGInvariant` (the canonical-form discriminator), unconditionally on `m₀ ≠ m₁` (no adversary needed) |
| `GIReducesToCE` (admitted `encode _ _ := ∅` degenerate witness) | `GIReducesToCE` (strengthened in-place with `codeSize_pos` + `encode_card_eq` non-degeneracy fields, I4) + `GIReducesToCE_card_nondegeneracy_witness` | Audit J-03 footgun closed at the type level; the empty-Finset encoder fails `0 < codeSize m`. Full `Nonempty GIReducesToCE` (discharging the iff) requires CFI 1992 / Petrank–Roth 1997 (research-scope R-15) |
| `GIReducesToTI` (admitted `encode _ _ := fun _ _ _ => 0` degenerate witness) | `GIReducesToTI` (strengthened in-place with `encode_nonzero_of_pos_dim` non-degeneracy field, I5) + `GIReducesToTI_nondegeneracy_witness` | Audit J-08 footgun closed at the type level; the constant-zero encoder fails `encode m adj ≠ (fun _ _ _ => 0)`. Full `Nonempty GIReducesToTI` requires Grochow–Qiao 2021 (research-scope R-15) |
| `ObliviousSamplingHiding` (deterministic perfect-extremum; `False` on every non-trivial bundle) | `ObliviousSamplingPerfectHiding` (I6, renamed; same content, post-I name accurately conveys the perfect-extremum strength) **plus** `ObliviousSamplingConcreteHiding` (I6, NEW probabilistic ε-smooth analogue) + extraction lemma + non-vacuity witness at ε = 0 on singleton-orbit bundles | Pre-I docstring self-disclosed the predicate is `False` on every non-trivial bundle; post-I keeps the deterministic form (renamed honestly) and adds the genuinely ε-smooth predicate suitable for release-facing security claims |

**Three perfect-security non-vacuity witnesses** at ε = 0 across the
post-Workstream-I probabilistic chain:
* `concreteOIA_zero_of_subsingleton_message` (scheme layer, I1).
* `concreteKEMOIA_uniform_zero_of_singleton_orbit` (KEM layer, I2).
* `ObliviousSamplingConcreteHiding_zero_witness` (oblivious-sampling
  layer, I6).

Together these inhabit the meaningful (perfect-security) extremum of
the `[0, 1]` ε-spectrum on every probabilistic predicate post-
Workstream-I, complementing the trivial-bound `concreteOIA_one`,
`concreteKEMOIA_uniform_one`, and `concreteKEMOIA_one` witnesses that
inhabit the ε = 1 extremum.

**Strengthening, not rebadging.** Per `CLAUDE.md`'s
Security-by-docstring prohibition, when an identifier names a
cryptographic primitive the code must *prove* the advertised property
or *rename* the identifier to describe what it does prove. Workstream
I applies the strengthening direction wherever feasible (I1, I2, I3
land NEW substantive theorems), and the renaming direction only
when the property is genuinely out of reach (the pre-I weak forms
that get the rename are kept *alongside* the new substantive content,
not in its place). I4/I5/I6 close audit-flagged degenerate-witness
footguns at the type level (the strengthened Props' non-degeneracy
fields rule out the audit-cited degenerate encoders at compile time);
non-trivial inhabitants of the iff remain research-scope (R-15).

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
  ObliviousSamplingPerfectHiding, ObliviousSamplingConcreteHiding,
  ConcreteHardnessChain, …) is a `Prop`-valued
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

## Workstream B Snapshot (audit 2026-04-23, finding V1-1 / I-03)

**Closed by landing 2026-04-24.** Audit finding V1-1 (HIGH,
`INT_CTXT` orbit-cover hypothesis is vacuously applicable on
production HGOE) is resolved by a game-shape refinement that
absorbs the orbit condition into the `INT_CTXT` predicate itself
as a per-challenge well-formedness precondition, rather than
carrying it as a theorem-level hypothesis on
`authEncrypt_is_int_ctxt`.

### Problem summary (pre-B)

Pre-Workstream-B, `authEncrypt_is_int_ctxt` took an explicit
`hOrbitCover : ∀ c : X, c ∈ MulAction.orbit G akem.kem.basePoint`
hypothesis. On production HGOE the ciphertext space is
`Bitstring n = Fin n → Bool` with cardinality `2^n`; by the
orbit-stabiliser theorem any orbit under a non-trivial subgroup
`G ≤ S_n` has cardinality `|G| / |Stab|`, which is strictly less
than `2^n` for any realistic `(n, G)`. So `hOrbitCover` is
**false** on production HGOE, and the pre-B theorem was
vacuously applicable there — a release-readiness issue flagged
by the `CLAUDE.md` row #19 Status column being labelled
**Standalone** when the theorem was effectively
**Conditional** in its practical reach.

### Fix (Option A — restrict the game)

The Workstream B remediation absorbs the orbit condition into
the `INT_CTXT` game:

```
def INT_CTXT (akem : AuthOrbitKEM G X K Tag) : Prop :=
  ∀ (c : X) (t : Tag),
    c ∈ MulAction.orbit G akem.kem.basePoint →        -- (NEW post-B)
    (∀ g : G, c ≠ (authEncaps akem g).1 ∨
              t ≠ (authEncaps akem g).2.2) →
    authDecaps akem c t = none
```

Conceptually, the game rejects out-of-orbit ciphertexts as
**ill-formed** — they cannot arise from an honest sender running
an orbit-action KEM, so they do not count as "forgeries" under
the realistic threat model. `authEncrypt_is_int_ctxt` now
consumes the per-challenge `hOrbit` hypothesis from the
`INT_CTXT` binder via `intro c t hOrbit hFresh`; no top-level
orbit-cover argument remains.

### Changes (as landed)

* **`Orbcrypt/AEAD/AEAD.lean`** — (B1a) `INT_CTXT` predicate
  signature refactored: adds a `hOrbit : c ∈ MulAction.orbit G
  akem.kem.basePoint` binder between `(c : X) (t : Tag)` and the
  freshness disjunction. Module docstring gains an
  "INT_CTXT game-shape refinement" subsection; the predicate's
  own docstring now enumerates the Design rationale (orbit
  precondition, freshness condition, `= none` conclusion).
* **`Orbcrypt/AEAD/AEAD.lean`** — (B1b) `authEncrypt_is_int_ctxt`
  refactored: signature drops the `hOrbitCover` parameter; the
  proof body's `intro` chain picks up the new `hOrbit` binder
  directly; the `obtain ⟨g, hg⟩ := MulAction.mem_orbit_iff.mp
  (hOrbitCover c)` line becomes `... mp hOrbit`; the later
  `keyDerive_canon_eq_of_mem_orbit akem (hOrbitCover c)`
  invocation becomes `... akem hOrbit`. The private helpers
  `authDecaps_none_of_verify_false` (C2a) and
  `keyDerive_canon_eq_of_mem_orbit` (C2b) are **unchanged**.
* **`Orbcrypt/AEAD/CarterWegmanMAC.lean`** — (B2)
  `carterWegmanMAC_int_ctxt` loses its `hOrbitCover` argument;
  the proof body becomes a direct application of
  `authEncrypt_is_int_ctxt (carterWegman_authKEM p kem)`. The
  theorem's docstring records the Workstream-B unconditionality.
* **`scripts/audit_phase_16.lean`, `scripts/audit_c_workstream.lean`**
  — (B3) non-vacuity witnesses updated to match the new
  signatures. The end-to-end `toyCarterWegmanMAC_is_int_ctxt`
  witness at `p = 2` over `ZMod 2` is preserved — it now
  invokes `carterWegmanMAC_int_ctxt 2 toyKEMZMod2` with no
  orbit-cover argument.
* **`CLAUDE.md`** — (B4) Status column for row #19 upgraded
  from **Conditional** to **Standalone**; row #20 retains
  **Conditional** for the orthogonal HGOE compatibility caveat
  (tracked as R-13).
* **`docs/VERIFICATION_REPORT.md`** — row #19 updated;
  "Known limitations" orbit-cover bullet removed.

### Verification

* `lake build Orbcrypt.AEAD.AEAD` succeeds (post-refactor).
* `lake build Orbcrypt.AEAD.CarterWegmanMAC` succeeds.
* `#print axioms Orbcrypt.authEncrypt_is_int_ctxt` emits only
  the standard Lean trio (`propext`, `Classical.choice`,
  `Quot.sound`) — unchanged from pre-B.
* `#print axioms Orbcrypt.carterWegmanMAC_int_ctxt` emits only
  the standard trio — unchanged from pre-B.
* `scripts/audit_phase_16.lean` passes (the trivial
  `AuthOrbitKEM` discharge now calls `authEncrypt_is_int_ctxt
  trivialAuthKEM` with no arguments).
* `scripts/audit_c_workstream.lean` passes (the concrete
  `ZMod 2` witness composes with the unconditional
  specialisation).

### Consumer migration

Downstream users invoking the pre-B signatures must update:

* `authEncrypt_is_int_ctxt akem hOrbitCover` → `authEncrypt_is_int_ctxt akem`
* `carterWegmanMAC_int_ctxt p kem hOrbitCover` → `carterWegmanMAC_int_ctxt p kem`
* `INT_CTXT` consumers that `intro c t hFresh` must now
  `intro c t hOrbit hFresh` (one additional binder).

The `hOrbit` discharge remains the same proof content
callers previously supplied for `hOrbitCover c`; it has simply
moved from a scheme-level obligation to a per-challenge
obligation. Consumers wanting the stronger
"INT-CTXT on arbitrary ciphertexts, rejecting out-of-orbit at
decapsulation time" model should pair `INT_CTXT` with an
explicit orbit-check — the canonical shape is Workstream **H**'s
planned `decapsSafe` helper (audit plan § 9).

### Patch version

`lakefile.lean` bumped from `0.1.6` to `0.1.7` for Workstream B.
The `INT_CTXT` signature change is an API break (downstream
consumers of the predicate must supply a per-challenge `hOrbit`
argument); the `authEncrypt_is_int_ctxt` and
`carterWegmanMAC_int_ctxt` theorems lose one argument each. The
38-module total is unchanged; the 347-public-declaration count
is unchanged; the zero-sorry / zero-custom-axiom posture is
preserved.

## Workstream C Snapshot (audit 2026-04-23, finding V1-8 / C-13 / D10)

Workstream C of the 2026-04-23 pre-release audit plan closes the
HIGH-severity V1-8 / C-13 / D10 finding cluster that flagged a
documentation-vs-code mismatch: pre-C external prose summarised
`indQCPA_bound_via_hybrid` as "Orbcrypt is multi-query IND-Q-CPA
under `ConcreteOIA`", but the Lean theorem signature carries
`h_step` as a **user-supplied hypothesis** whose discharge from
`ConcreteOIA scheme ε` alone is genuine research-scope work
(tracked as research milestone R-09: a per-coordinate
marginal-independence proof over `uniformPMFTuple`).

### Remediation

Track 1 of the Workstream-C plan (§ 6.2 of the audit plan) is a
**rename** — the theorem's content is unchanged, but the
identifier is restructured to surface the `h_step` obligation
per `CLAUDE.md`'s naming rule ("identifier names describe what
the code *proves*, not what the code *aspires to*"):

* `indQCPA_bound_via_hybrid` → `indQCPA_from_perStepBound`
* `indQCPA_bound_recovers_single_query`
  → `indQCPA_from_perStepBound_recovers_single_query`

The old names are **not** retained as deprecated aliases
(`CLAUDE.md`'s no-backwards-compat rule). Every in-tree
reference — the theorem body, docstrings, the
module-docstring "Main results" list, `Orbcrypt.lean`'s
axiom-transparency report, `scripts/audit_phase_16.lean`,
`scripts/audit_e_workstream.lean`, `CLAUDE.md`,
`DEVELOPMENT.md §8.2`, `docs/VERIFICATION_REPORT.md` — is
updated in this landing.

### Files touched

* **`Orbcrypt/Crypto/CompSecurity.lean`** — two theorem
  renames; module-docstring "Main results" list extended with
  explicit release-messaging disclosures of the `h_step`
  obligation and the R-09 research pointer.
* **`scripts/audit_phase_16.lean`** — `#print axioms` entries
  renamed; five new non-vacuity examples under the
  `NonVacuityWitnesses` namespace exercise the renamed theorem:
  (a) parameterised general-signature witness over any scheme /
  adversary, (b) parameterised C.2 audit-plan template at
  Q = 2 / ε = 1 with the per-step bound discharged by
  `advantage_le_one`, (c) parameterised Q = 1 regression
  sentinel, (d) concrete Q = 2 / ε = 1 witness on
  `trivialScheme` (`Equiv.Perm (Fin 1)` acting on `Unit`) with
  a concrete `MultiQueryAdversary Unit Unit 2`, exercising the
  full typeclass-instance elaboration pipeline, and (e) concrete
  Q = 1 companion witness on the same concrete scheme firing
  `indQCPA_from_perStepBound_recovers_single_query`. The
  parameterised witnesses (a–c) prove signature-universality
  over every valid typeclass bundle; the concrete witnesses
  (d–e) prove Lean can actually synthesise the typeclass
  instances on a known-good input.
* **`scripts/audit_e_workstream.lean`** — legacy per-workstream
  script's `#print axioms` lines renamed.
* **`Orbcrypt.lean`** — dependency listing + axiom-transparency
  `#print axioms` block + Vacuity map table updated; this
  Workstream-C snapshot section added.
* **`CLAUDE.md`** — "Main results" and release-facing references
  renamed; Workstream-C snapshot added to the change log; the
  pre-C N3 (audit 2026-04-21) open-item callout now points at
  the Workstream-C landing that closes it.
* **`docs/VERIFICATION_REPORT.md`** — headline-results table
  rows #23 renamed; "Release readiness" section's "What NOT to
  cite" list renamed; "Known limitations" bullet renamed.
* **`DEVELOPMENT.md`** — §8.2 (multi-query IND-Q-CPA
  discussion) renamed; the renaming cross-reference in the
  release-messaging policy paragraph is preserved.

### Verification

* `lake build Orbcrypt.Crypto.CompSecurity` succeeds
  (post-rename).
* `grep -rn "indQCPA_bound_via_hybrid\|indQCPA_bound_recovers_single_query"`
  across every `.lean` source file returns empty. Markdown
  documents retain the old names **only** inside historical
  changelog entries and Workstream-C landing snapshots that
  explicitly describe the rename.
* `#print axioms Orbcrypt.indQCPA_from_perStepBound` emits only
  the standard Lean trio (`propext`, `Classical.choice`,
  `Quot.sound`) — unchanged from pre-C (the rename is
  content-neutral).
* `#print axioms
  Orbcrypt.indQCPA_from_perStepBound_recovers_single_query`
  emits only the standard trio — unchanged from pre-C.
* `scripts/audit_phase_16.lean` passes with five new non-vacuity
  witnesses (§ 12.C): three parameterised + two concrete.

### Consumer migration

Downstream users invoking the pre-C signatures must update:

* `indQCPA_bound_via_hybrid scheme ε A h_step`
  → `indQCPA_from_perStepBound scheme ε A h_step`
  (argument list and content unchanged).
* `indQCPA_bound_recovers_single_query scheme ε A h_step`
  → `indQCPA_from_perStepBound_recovers_single_query scheme ε A h_step`
  (argument list and content unchanged).

No call-site semantic change is required — the rename is purely
nominal. LSP rebuilds on `lake build`; cached references update
on the next elaboration pass.

### Research follow-up

The R-09 research milestone (`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md`
§ 18) tracks the marginal-independence discharge of `h_step`
from `ConcreteOIA` alone. When R-09 lands it will sit **next
to** `indQCPA_from_perStepBound` as a discharge theorem that
consumes it; the rename is therefore future-proof — the new
name correctly describes the telescoping step regardless of
whether R-09 is solved. If R-09 ever produces a direct
`ConcreteOIA → IND-Q-CPA` corollary, that corollary will carry
its own explicit name (e.g., `concrete_oia_implies_QCPA`) and
leave `indQCPA_from_perStepBound` untouched.

### Patch version

`lakefile.lean` bumped from `0.1.7` to `0.1.8` for Workstream C.
The rename is an API break (downstream consumers must update
the identifier at every call site), hence the patch-version
bump per `CLAUDE.md`'s version-bump discipline. No new public
declarations are added; no existing declaration's content
changes; the 38-module total is unchanged; the zero-sorry /
zero-custom-axiom posture is preserved.

## Workstream D Snapshot (audit 2026-04-23, finding V1-6 / A-01 / A-02 / A-03)

Workstream D of the 2026-04-23 pre-release audit plan closes the
MEDIUM-severity V1-6 / A-01 / A-02 / A-03 finding cluster that
flagged a toolchain-vs-documentation gap at the build-
configuration surface: pre-D `lakefile.lean` carried a stale
"Last verified: 2026-04-14" comment (superseded by several
subsequent workstream revalidations), had no explicit "rc by
design" disclosure, and pinned only `autoImplicit := false` in
`leanOptions` — so the zero-warning gate was enforced solely
by the CI's warning-as-error setting, not by the build
configuration itself.

### Remediation

Workstream D is **build-configuration-only** — no Lean source
files are modified, no public declarations are added, removed,
or renamed. The landing is a three-part build-surface refresh:

* **D1 (toolchain decision).** `lean-toolchain` retains
  `leanprover/lean4:v4.30.0-rc1` under **Scenario C** of the
  audit plan (`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md`
  § 7) — ship v1.0 off the release-candidate toolchain; defer
  the stable-toolchain upgrade to v1.1. No Mathlib-stable
  pairing is currently available against the project's
  `fa6418a8` Mathlib pin without a coordinated `lake update` +
  Phase-16 audit replay (which exceeds the Workstream-D scope
  and is tracked as a v1.1 follow-up). The decision is recorded
  in `docs/VERIFICATION_REPORT.md`'s new "Toolchain decision
  (Workstream D)" subsection and in `CLAUDE.md`'s Workstream-D
  snapshot.
* **D2 (lakefile metadata refresh).** The stale
  "Last verified: 2026-04-14" comment is updated to
  "Last verified: 2026-04-24". A new "Toolchain posture"
  paragraph is added after the "Compatible with
  lean4:v4.30.0-rc1" line recording the Scenario-C decision
  and cross-referencing the audit plan § 7 and the
  VERIFICATION_REPORT subsection. Reading `lakefile.lean` is
  now self-sufficient to understand the rc-toolchain choice
  without leaving the build configuration.
* **D3 (`leanOption` pins).** `lakefile.lean`'s `leanOptions`
  array is extended from a single-entry `autoImplicit := false`
  to a three-entry array also pinning
  `linter.unusedVariables := true` and `linter.docPrime := true`.
  The default posture differs by linter:
  * `linter.unusedVariables` is a Lean core builtin
    (`register_builtin_option … defValue := true`); the pin is
    genuinely **defensive** — currently a no-op, locks the gate
    against a future toolchain default-flip.
  * `linter.docPrime` is a Mathlib linter
    (`register_option … defValue := false`); Mathlib explicitly
    excludes it from its standard linter set
    (`Mathlib/Init.lean:110`, referencing
    https://github.com/leanprover-community/mathlib4/issues/20560),
    so the pin to `true` is a **meaningful enable** — turns on a
    linter Mathlib leaves off. The Orbcrypt source tree currently
    has zero declarations whose names end in `'` (verified by
    `grep -rEn "(theorem|lemma|def|abbrev|structure|class|instance) \w+'" Orbcrypt/`),
    so the linter fires on zero existing call sites; it acts as
    a tripwire that prevents new primed identifiers from landing
    without a docstring.

  Caveat about `linter.docPrime`: because the option is
  registered by Mathlib (not Lean core), files that elaborate
  any docstring or non-import command before their first
  Mathlib-aware `import` will fail at startup with
  `invalid -D parameter, unknown configuration option
  'linter.docPrime'`. Every `.lean` file under `Orbcrypt/`
  currently starts with `import` as its first non-blank line, so
  the constraint is satisfied; new modules must observe the same
  convention.

### Files touched

* **`lakefile.lean`** — version `0.1.8 → 0.1.9`; comment metadata
  refreshed (Last-verified date + Toolchain-posture paragraph);
  `leanOptions` array extended with the two linter pins
  (`linter.unusedVariables`, `linter.docPrime`).
* **`CLAUDE.md`** — Workstream status tracker row for D checked
  off; this Workstream-D snapshot appended after the
  Workstream-C snapshot.
* **`docs/VERIFICATION_REPORT.md`** — new "Toolchain decision
  (Workstream D)" subsection inserted between "How to reproduce
  the audit" and "Headline results table"; Document-history
  entry dated 2026-04-24 records the Workstream-D landing.
* **`Orbcrypt.lean`** — this snapshot section appended to the
  axiom-transparency report footer. (No source-level
  declarations are added or modified; the dependency graph,
  the vacuity map, and the `#print axioms` cookbook are all
  unchanged.)
* **`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md`** —
  V1-6 release-gate checkbox ticked (§ 20.1); Workstream-D
  tracker updated with the landing date (§ 3 / Appendix B).

### Verification

* `lake build` succeeds for all 3,367 jobs with zero warnings /
  zero errors on a forced rebuild (verified by touching
  `Orbcrypt/GroupAction/Basic.lean` and rerunning `lake build`).
* `scripts/audit_phase_16.lean` emits unchanged axiom output —
  every `#print axioms` result is either "does not depend on
  any axioms" or the standard-trio
  `[propext, Classical.choice, Quot.sound]`; zero `sorryAx`;
  zero non-standard axioms.
* The 38-module total is unchanged; the 347 public-declaration
  count is unchanged; the zero-sorry / zero-custom-axiom
  posture is preserved; the module-dependency graph and the
  Vacuity map (Workstream E) are unchanged.

### Consumer impact

Downstream consumers running `lake env …` against a cloned
checkout of this landing will experience a different warning
surface than pre-D: `linter.unusedVariables` and
`linter.docPrime` are now pinned at the package level. In the
current toolchain this is a no-op (both defaults are already
`true`); the pin only becomes behaviourally visible if a future
toolchain upgrade flips those defaults. No consumer action is
required.

### Patch version

`lakefile.lean` bumped from `0.1.8` to `0.1.9` for Workstream D.
Technically a build-configuration change does not require a
patch bump by `CLAUDE.md`'s version-bump discipline (which is
triggered by API-breaking changes or new public declarations);
however, the linter-configuration pin is a consumer-visible
build setting (see "Consumer impact" above), so the bump records
the change in the version log. No Lean source files are
modified; no new public declarations; the 38-module total, the
347 public-declaration count, the zero-sorry / zero-custom-
axiom posture, and the standard-trio-only axiom-dependency
posture are all preserved.

## Workstream E Snapshot (audit 2026-04-23, findings C-07 / E-06)

**Closed by landing 2026-04-24.** Audit findings C-07 (HIGH,
deterministic `OIA` module docstring asserts vacuity in prose
only) and E-06 (HIGH, `KEMOIA` docstring makes the parallel
unbacked claim) are resolved by two small, axiom-free theorems
that discharge the vacuity claim on every non-trivial scheme /
KEM under a mild distinctness hypothesis.

### Problem summary (pre-E)

`Orbcrypt/Crypto/OIA.lean`'s module docstring (lines 45–67
pre-E) and the `OIA` definition's own docstring both assert in
prose that the deterministic OIA is `False` on every scheme
with two distinct representatives ("because
`f := fun x => decide (x = reps m₀)` is a distinguisher"). The
same pattern appears in `Orbcrypt/KEM/Security.lean`'s `KEMOIA`
docstring, now scoped to the KEM-layer game. Neither claim was
**machine-checked** prior to this workstream; consumers
validating the scaffolding disclosure had to take the prose on
trust. This weakened the `Orbcrypt.lean` axiom-transparency
story: every other vacuity claim in the codebase either has a
non-vacuous probabilistic counterpart in the vacuity map (E4 /
E6 / G / H) or is itself proved as an equality / refutation
theorem. The two missing witnesses closed the last prose-only
gap.

### Fix (two small theorems)

**E1 — `det_oia_false_of_distinct_reps`** (`Orbcrypt/Crypto/OIA.lean`).
Refutes `OIA scheme` under the hypothesis
`scheme.reps m₀ ≠ scheme.reps m₁`. The distinguisher is the
Boolean membership test
`fun x => decide (x = scheme.reps m₀)`, instantiated at
identity group elements `g₀ = g₁ = 1`. After
`simp only [one_smul]`, the LHS `decide` evaluates to `true`
(reflexivity) and the RHS `decide` to `false` (via the
distinctness hypothesis). Rewriting the RHS `decide` equalities
produces `true = false`, discharged via
`Bool.true_eq_false_iff`.

**E2 — `det_kemoia_false_of_nontrivial_orbit`** (`Orbcrypt/KEM/Security.lean`).
Refutes `KEMOIA kem` under the hypothesis
`g₀ • kem.basePoint ≠ g₁ • kem.basePoint`. Parallel structure
to E1: the distinguisher is
`fun c => decide (c = g₀ • kem.basePoint)`, and the proof body
uses the same `decide_eq_true` / `decide_eq_false` idiom
combined with `Bool.true_eq_false_iff`. Works against the
post-L5 single-conjunct `KEMOIA` — no `.1` / `.2`
destructuring.

### Changes

* `Orbcrypt/Crypto/OIA.lean` — added E1 at the bottom of the
  module. Typeclass context identical to `OIA` (`[Group G]`,
  `[MulAction G X]`, `[DecidableEq X]`); no new imports.
* `Orbcrypt/KEM/Security.lean` — added E2 at the bottom of the
  module. Typeclass context identical to `KEMOIA`; no new
  imports.
* `Orbcrypt.lean` — (E3) vacuity-map table gained a third
  "Machine-checked vacuity witness" column pointing the two
  rows at `OIA` / `KEMOIA` (rows #1–#2) to E1 and E2
  respectively. The remaining rows either inherit the upstream
  witness (e.g. hardness-chain rows depend on `OIA`, so they
  inherit E1 via `oia_from_hardness_chain`) or have no
  deterministic antecedent at all (multi-query row, probabilistic
  rows — these carry probabilistic `Concrete*` hypotheses which
  are genuinely ε-smooth and don't require a vacuity refutation).
  Axiom-transparency cookbook block gained two new
  `#print axioms` entries under the 2026-04-23 E subsection.
  This Workstream-E snapshot section was appended at the end
  of the transparency report.
* `scripts/audit_phase_16.lean` — added E1 and E2 to the
  per-declaration `#print axioms` list; added two concrete
  non-vacuity `example` bindings under `NonVacuityWitnesses`:
  (i) E1 fires on a two-message scheme over `ZMod 2 × ZMod 2`
  with reps `(0, 1)` and `(1, 0)` (distinct by construction),
  and (ii) E2 fires on a KEM over `Equiv.Perm (ZMod 2)` with
  the `Equiv.swap 0 1`-based action on `ZMod 2` (where
  `swap 0 1 • 0 = 1 ≠ 0 = 1 • 0`, so the orbit is non-trivial).

### Verification

* `lake build Orbcrypt.Crypto.OIA` — succeeds, zero warnings.
* `lake build Orbcrypt.KEM.Security` — succeeds, zero warnings.
* `lake build Orbcrypt` (whole project) — succeeds; 38 modules
  / 3,369 jobs (two new theorems add two build nodes); zero
  errors / zero warnings.
* `#print axioms Orbcrypt.det_oia_false_of_distinct_reps` —
  standard trio `[propext, Classical.choice, Quot.sound]`.
  Never `sorryAx`, never a custom axiom.
* `#print axioms Orbcrypt.det_kemoia_false_of_nontrivial_orbit` —
  standard trio.
* `scripts/audit_phase_16.lean` — runs clean; every
  declaration's axiom dependencies are either empty or a subset
  of the standard trio; the two new non-vacuity `example`
  bindings elaborate and close their `¬ OIA scheme` / `¬ KEMOIA kem`
  goals by direct term construction.

### Consumer impact

Release-facing prose that previously said "OIA is vacuously
true on every non-trivial scheme" can now cite the formal
theorem `det_oia_false_of_distinct_reps` (under the
`reps_distinct` obligation every scheme already carries —
concretely, the distinct-representatives hypothesis is a
strengthening of `reps_distinct` to pointwise distinctness).
The KEM-layer analogue `det_kemoia_false_of_nontrivial_orbit`
applies whenever the base point's orbit has cardinality ≥ 2,
which is every realistic KEM.

`CLAUDE.md`'s release-messaging policy permits both theorems
as **Standalone** citations because each conclusion is
unconditional on the distinctness / non-trivial-orbit
hypothesis. Neither theorem supersedes the
`concrete_*_implies_*` probabilistic reductions; both are
companion lemmas that formalise the *reason* the deterministic
chain is scaffolding, not substantive security content.

### Patch version

`lakefile.lean` bumped from `0.1.9` to `0.1.10` for Workstream
E. Two new public declarations land (`det_oia_false_of_distinct_reps`,
`det_kemoia_false_of_nontrivial_orbit`) inside existing
modules; no new `.lean` files; the 38-module total is
unchanged. Public declaration count rises from 347 to 349.
The zero-sorry / zero-custom-axiom posture and the standard-
trio-only axiom-dependency posture are preserved. The
Phase-16 audit script's `#print axioms` total rises from 342
to 344; the non-vacuity witness block gains two new `example`
bindings.

### Research-scope follow-ups

None. The vacuity witnesses are complete at the level of the
deterministic chain; the *probabilistic* chain's ε < 1
non-vacuity is tracked separately (Workstream G / H + research
milestones R-02–R-05 / R-09 / R-13; see
`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § O). No
open items from the Workstream-E risk register (E-R1 through
E-R4) surfaced during the landing:
* E-R1 (decide elaboration) — only standard-trio axioms
  observed; rollback not required.
* E-R2 (`simp only [one_smul]`) — fires as expected on both
  theorems; rollback not required.
* E-R3 (KEM non-vacuity witness) — the `Equiv.swap 0 1`-based
  toy action on `ZMod 2` used in the Workstream-C post-L2
  witness is reused directly; no new typeclass plumbing needed.
* E-R4 (future `KEMOIA` refactor) — E2 is written against the
  post-L5 single-conjunct form; no destructuring is required.

## Workstream F Snapshot (audit 2026-04-23, finding V1-10 / F-04)

### Problem

`hgoeScheme` (Phase 5) takes `can : CanonicalForm (↥G)
(Bitstring n)` as a **parameter** without providing a concrete
instance. Every downstream theorem that types `{can :
CanonicalForm (↥G) …}` is therefore parameterised by a
structure with no constructed inhabitant in-tree. The GAP
reference implementation uses lex-min orbit element, but
pre-Workstream-F this was a prose-level convention rather than
a Lean-side witness.

### Fix

New module `Orbcrypt/GroupAction/CanonicalLexMin.lean` (the
40th `.lean` file) landing:

* `CanonicalForm.ofLexMin (G : Type*) (X : Type*) [Group G]
  [MulAction G X] [Fintype G] [DecidableEq X] [LinearOrder X]
  : CanonicalForm G X` — the computable constructor. All three
  structure fields (`canon`, `mem_orbit`, `orbit_iff`) are
  discharged inline:
  * `canon x := (MulAction.orbit G x).toFinset.min'
    (orbit_toFinset_nonempty x)` (F2);
  * `mem_orbit` via `Finset.min'_mem` +
    `mem_orbit_toFinset_iff` (F2);
  * `orbit_iff` forward via shared-min'-element extraction +
    `MulAction.orbit_eq_iff` (F3b);
  * `orbit_iff` reverse via `Set.toFinset_congr` + `congr 1`
    (F3c).
* `orbitFintype`, `mem_orbit_toFinset_iff`,
  `orbit_toFinset_nonempty` (F3a) — the orbit-Fintype
  instance and toFinset-membership helpers.
* `CanonicalForm.ofLexMin_canon` (`@[simp]`),
  `CanonicalForm.ofLexMin_canon_mem_orbit` — companion
  lemmas.

`Orbcrypt/Construction/Permutation.lean` gains the
`bitstringLinearOrder` (`@[reducible] def`, not a global
instance) — a computable lex order on `Bitstring n` matching the
GAP reference implementation's `CanonicalImage(G, x, OnSets)`
convention exactly: bitstrings are compared via their support
sets (sorted ascending position lists), with smaller-position-
true winning. Implemented via `LinearOrder.lift' (List.ofFn ∘
(! ∘ ·))`, with `Bool.not_inj` discharging injectivity. The
inverted-Bool composition transports Mathlib's `false < true`
list-lex order to `true < false` on `Bitstring n`, yielding
"leftmost-true wins" — definitionally identical to GAP's
set-lex on sorted ascending support sets. Exposed as a `def`
to avoid the diamond with Mathlib's pointwise `Pi.partialOrder`;
callers bind it locally via `letI`.

`Orbcrypt/Construction/HGOE.lean` gains `hgoeScheme.ofLexMin`
(F4) — the convenience constructor that auto-fills the
`CanonicalForm` parameter for any finite subgroup of
`Equiv.Perm (Fin n)` via `CanonicalForm.ofLexMin` under
`bitstringLinearOrder`. Threads `letI` internally; callers
needn't bring the `LinearOrder`. Companion `@[simp]` lemma
`hgoeScheme.ofLexMin_reps` witnesses preservation of the
`reps` field.

### Files touched

* `Orbcrypt/GroupAction/CanonicalLexMin.lean` — new module,
  ~110 lines; six new public declarations.
* `Orbcrypt/Construction/Permutation.lean` — adds
  `bitstringLinearOrder` + three new Mathlib imports
  (`Mathlib.Data.List.OfFn`, `Mathlib.Data.List.Lex`,
  `Mathlib.Data.Bool.Basic`).
* `Orbcrypt/Construction/HGOE.lean` — adds
  `hgoeScheme.ofLexMin` + `hgoeScheme.ofLexMin_reps` + one
  new module import (`Orbcrypt.GroupAction.CanonicalLexMin`).
* `Orbcrypt.lean` — adds `import
  Orbcrypt.GroupAction.CanonicalLexMin` between
  `Canonical` and `Invariant`, matching the module-dependency
  graph order.
* `scripts/audit_phase_16.lean` — adds six new `#print axioms`
  entries (including three helpers) in §1, three in §4, plus
  four new non-vacuity `example` bindings under a new
  `## Workstream F non-vacuity witnesses` section. Two new
  imports (`Mathlib.Data.Fintype.Perm`,
  `Mathlib.Data.Fin.VecNotation`) supply
  `Fintype (Equiv.Perm (Fin 3))` and the `![...]` syntax at
  the witness sites.
* `lakefile.lean` — `version` bumped `0.1.10 → 0.1.11`.

### Axiom transparency

Every new declaration depends only on the standard Lean trio
(`propext`, `Classical.choice`, `Quot.sound`):

```
#print axioms Orbcrypt.orbitFintype
  -- [propext, Classical.choice, Quot.sound]
#print axioms Orbcrypt.mem_orbit_toFinset_iff
  -- [propext, Classical.choice, Quot.sound]
#print axioms Orbcrypt.orbit_toFinset_nonempty
  -- [propext, Classical.choice, Quot.sound]
#print axioms Orbcrypt.CanonicalForm.ofLexMin
  -- [propext, Classical.choice, Quot.sound]
#print axioms Orbcrypt.CanonicalForm.ofLexMin_canon
  -- [propext, Classical.choice, Quot.sound]
#print axioms Orbcrypt.CanonicalForm.ofLexMin_canon_mem_orbit
  -- [propext, Classical.choice, Quot.sound]
#print axioms Orbcrypt.bitstringLinearOrder
  -- [propext, Classical.choice, Quot.sound]
#print axioms Orbcrypt.hgoeScheme.ofLexMin
  -- [propext, Classical.choice, Quot.sound]
#print axioms Orbcrypt.hgoeScheme.ofLexMin_reps
  -- [propext, Classical.choice, Quot.sound]
```

Zero `sorryAx`; zero custom axioms.

### Consumer impact

Every downstream theorem that types
`{can : CanonicalForm (↥G) (Bitstring n)}` can now discharge
the parameter via `CanonicalForm.ofLexMin` at any finite
subgroup, provided the caller also binds a `LinearOrder
(Bitstring n)` (typically via `letI :=
bitstringLinearOrder`). The existing `hgoeScheme` signature is
unchanged — `hgoeScheme.ofLexMin` is additive ergonomic
sugar. No existing code needs migration.

External release claims about HGOE's canonical form — e.g.,
"the scheme uses the lex-minimum orbit element as its canonical
form" — now track a machine-checked constructor rather than
untracked prose. The `DEVELOPMENT.md §3.2` convention matches
the `bitstringLinearOrder` + `ofLexMin` pairing exactly.

### Research-scope follow-ups

None. The Workstream-F landing is self-contained. The
`Pi.partialOrder` diamond issue is resolved at the `def` level
(no global instance registered); future workstreams that want
a different `LinearOrder (Bitstring n)` can supply their own
`letI` binding without touching `bitstringLinearOrder`.

### Patch version

`lakefile.lean` bumped from `0.1.10` to `0.1.11` for Workstream
F. Nine new public declarations land (one new module + two
new helpers in existing modules). Module count rises from 38
to 39; public declaration count rises from 349 to 358. The
zero-sorry / zero-custom-axiom posture and the standard-trio-
only axiom-dependency posture are preserved. The Phase-16
audit script's `#print axioms` total rises from 373 to 382.

## Workstream G Snapshot (audit 2026-04-23, finding V1-13 / H-03 / Z-06 / D16)

### Problem

`HGOEKeyExpansion` (`Orbcrypt/KeyMgmt/SeedKey.lean`) hard-coded
`group_large_enough : group_order_log ≥ 128` as a literal field
type — the `128` was a magic number, not a structure parameter.
The Phase-14 parameter sweep (`docs/PARAMETERS.md`,
`docs/benchmarks/results_{80,128,192,256}.csv`) documents four
security tiers (λ ∈ {80, 128, 192, 256}); only λ = 128 had a
corresponding Lean-instantiable witness.

* **λ = 80 was strictly weaker** than the literal: a deployment
  targeting λ = 80 would carry around a `≥ 128` proof obligation
  it could not actually discharge from its λ = 80 group order.
  Such a deployment was *unable* to inhabit `HGOEKeyExpansion`
  in Lean.
* **λ ∈ {192, 256} were strictly stronger** than the literal:
  a deployment claiming λ = 256 security was getting only the
  λ = 128 strength guarantee out of `HGOEKeyExpansion`. The
  type system was *under-constraining* the high-security tiers
  — the structure couldn't tell the difference between a
  λ = 128 and a λ = 256 caller.

This was a release-messaging gap: external prose advertised
λ ∈ {80, 128, 192, 256} coverage; the Lean content only
covered λ = 128. The audit catalogued this as MEDIUM-severity
finding V1-13 / H-03 / Z-06 / D16.

### Fix

`HGOEKeyExpansion` now takes a leading `lam : ℕ` parameter:

```
structure HGOEKeyExpansion (lam : ℕ) (n : ℕ) (M : Type*) where
  ...
  group_order_log : ℕ
  group_large_enough : group_order_log ≥ lam
  ...
```

The Lean identifier is spelled `lam` rather than `λ` because `λ`
is a reserved Lean token (lambda-abstraction). Named-argument
syntax accepts the spelling:
`HGOEKeyExpansion (lam := 128) (n := 512) M`. The structure
field `group_large_enough` is now λ-parameterised rather than
hard-coded.

The Lean-verified `≥ lam` bound is a **lower bound**, not an
exact bound: deployment chooses `group_order_log` per the §4
scaling-model thresholds in `docs/PARAMETERS.md`, often strictly
above `lam` (e.g., L3 in `docs/benchmarks/results_128.csv` has
`log₂|G| = 130 > 128`).

### Files touched

* `Orbcrypt/KeyMgmt/SeedKey.lean` — `HGOEKeyExpansion` gains the
  leading `lam : ℕ` parameter; `group_large_enough` becomes
  `group_order_log ≥ lam`. Module docstring + structure
  docstring + field docstring updated to disclose the
  λ-parameterisation, the lower-bound semantics, and the cross-
  reference to `docs/PARAMETERS.md`. New entry in the
  References list pointing at `docs/planning/AUDIT_2026-04-23_
  WORKSTREAM_PLAN.md` § 10.
* `scripts/audit_phase_16.lean` — adds a "Workstream G non-
  vacuity witnesses" section with **four** `example`s, one per
  documented tier (`HGOEKeyExpansion 80 320 Unit`,
  `HGOEKeyExpansion 128 512 Unit`, `HGOEKeyExpansion 192 768
  Unit`, `HGOEKeyExpansion 256 1024 Unit`). Each witness
  discharges every structure field including
  `group_large_enough` via `le_refl _` (we choose
  `group_order_log := lam` for simplicity — production
  deployments can choose strictly larger). Adds a private
  helper `hammingWeight_zero_bitstring` (used by all four
  witnesses to discharge Stage-4 `reps_same_weight` for the
  all-zero `reps` function), a field-projection regression
  example confirming `exp.group_large_enough : exp.group_order_
  log ≥ lam` is extractable on a free `lam`, and a
  λ-monotonicity negative example confirming `¬ (80 ≥ 192)` —
  documenting that the four tier-witnesses are **distinct**
  obligations, not one obligation with a sloppy bound.
* `DEVELOPMENT.md §6.2.1` — gains a paragraph cross-linking the
  λ-parameterised `HGOEKeyExpansion` to the prose specification,
  noting the Lean / prose spelling correspondence (`lam` ↔ `λ`).
* `docs/PARAMETERS.md §2` — gains a new §2.2.1 "Lean cross-link"
  subsection mapping each of the four λ rows in §2.2 to the
  corresponding `HGOEKeyExpansion lam …` Lean witness.
* `Orbcrypt.lean` — this snapshot section.
* `CLAUDE.md` — module-line note for `KeyMgmt/SeedKey.lean`,
  Workstream-G status-tracker checkbox, version-log entry, and
  this Workstream-G change-log entry.
* `docs/VERIFICATION_REPORT.md` — Document-history entry +
  Known-limitations cross-reference.
* `lakefile.lean` — `version` bumped `0.1.11 → 0.1.12`.

### Axiom transparency

`HGOEKeyExpansion` continues to depend only on the standard
Lean trio:

```
#print axioms HGOEKeyExpansion
  -- [propext, Classical.choice, Quot.sound]
```

Each of the four non-vacuity witnesses elaborates without
introducing any custom axiom; the field discharges are
`le_refl _`, `decide`, and `Finset.filter_false`, all of
which transitively depend only on the standard trio. Zero
`sorryAx`; zero custom axioms.

### Consumer impact

The structure signature changes from `HGOEKeyExpansion (n : ℕ)
(M : Type*)` to `HGOEKeyExpansion (lam : ℕ) (n : ℕ) (M :
Type*)`. Existing callers that constructed an
`HGOEKeyExpansion n M` value at the implicit-128 bound must
now pass `lam := 128` explicitly. There is exactly one such
call site in the public Orbcrypt source tree (the
`#print axioms` line in `scripts/audit_phase_16.lean`, which
takes the structure as a name only and is unaffected by the
arity change). Downstream library consumers must update their
construction sites; the migration is mechanical.

External release claims about HGOE's λ coverage now track
machine-checked witnesses rather than untracked prose. A
deployment targeting λ = 256 inhabits `HGOEKeyExpansion 256
…`; a λ = 80 deployment inhabits `HGOEKeyExpansion 80 …`; the
type system enforces that each tier discharges its own bound.

### Research-scope follow-ups

None. The Workstream-G refactor is a purely structural change
that lifts a hard-coded literal to a parameter; it introduces
no new proof obligations and does not depend on any
research-scope hardness witness. The four non-vacuity witnesses
are already concrete witnesses at all four documented tiers.

### Patch version

`lakefile.lean` bumped from `0.1.11` to `0.1.12` for Workstream
G — the `HGOEKeyExpansion` signature change is an API break
warranting a patch bump per `CLAUDE.md`'s version-bump
discipline. No new public declarations are added (the structure
gains a parameter, not a field; field count and projection
arity at construction sites are otherwise unchanged). Module
count remains 39; public declaration count remains 358. The
zero-sorry / zero-custom-axiom posture and the standard-trio-
only axiom-dependency posture are preserved. The Phase-16
audit script gains four new non-vacuity examples plus one
private helper `hammingWeight_zero_bitstring` (a
script-internal `private theorem` proving the all-zero
bitstring has Hamming weight 0, used to discharge Stage-4
weight-uniformity for the four tier witnesses) plus two
regression examples (field projection, λ monotonicity); the
`#print axioms` total rises from 382 to 383, with the new
entry being a defensive `#print axioms
hammingWeight_zero_bitstring` line that surfaces any future
helper regression in the CI parser even though the witness
`example`s themselves are anonymous.

## Workstream I Snapshot (audit 2026-04-23, findings C-15 / D-07 / E-11 / J-03 / J-08 / K-02)

### Problem

Six pre-Workstream-I identifiers across `Crypto/CompSecurity.lean`,
`KEM/CompSecurity.lean`, `Theorems/OIAImpliesCPA.lean`,
`Hardness/CodeEquivalence.lean`, `Hardness/TensorAction.lean`, and
`PublicKey/ObliviousSampling.lean` carried names that overstated
their cryptographic content. A naive remediation would be to
rebadge them — but that satisfies only the literal text of
`CLAUDE.md`'s Naming-content rule while violating the spirit of the
sibling Security-by-docstring prohibition. Workstream I applies the
strengthening direction wherever feasible and the renaming
direction only when the property is genuinely out of reach.

### Fix (six work units I1–I6 plus audit-script + transparency
sweep I7)

* **I1 — `Crypto/CompSecurity.lean`.** Renamed
  `concreteOIA_one_meaningful` → `indCPAAdvantage_le_one`
  (Mathlib-style `_le_one` simp lemma; content unchanged but name
  now accurately conveys the trivial `≤ 1` triangle-inequality
  bound). Added new theorem
  `concreteOIA_zero_of_subsingleton_message`: substantive non-
  vacuity witness for `ConcreteOIA` at the meaningful (perfect-
  security) extremum — every scheme on a subsingleton message space
  satisfies `ConcreteOIA scheme 0` via `advantage_self`.
* **I2 — `KEM/CompSecurity.lean`.** Deleted
  `concreteKEMOIA_one_meaningful` (a redundant duplicate of the
  pre-existing `kemAdvantage_le_one` at line 347 of the same file
  — both proved bit-identical statements with bit-identical
  proofs). Added new theorem
  `concreteKEMOIA_uniform_zero_of_singleton_orbit`: KEM-layer
  parallel of I1's perfect-security extremum — every KEM whose
  group action fixes the basepoint satisfies
  `ConcreteKEMOIA_uniform kem 0` via `PMF.map_const` reduction of
  `kemEncapsDist` to a point mass + `advantage_self`.
* **I3 — `Theorems/OIAImpliesCPA.lean` + `GroupAction/Invariant.lean`
  (helper).** Added helper `canon_indicator_isGInvariant` to
  `GroupAction/Invariant.lean`: the Boolean indicator
  `fun x => decide (can.canon x = c)` is G-invariant via
  `canonical_isGInvariant`. Renamed
  `insecure_implies_separating` →
  `insecure_implies_orbit_distinguisher` (the body delivers an
  orbit distinguisher, not a G-invariant separating function;
  rename restores accuracy). Added new theorem
  `distinct_messages_have_invariant_separator`: the G-invariant
  separator the pre-I name advertised but did not deliver —
  unconditional on `reps_distinct`, no adversary required.
* **I4 — `Hardness/CodeEquivalence.lean`.** Strengthened
  `GIReducesToCE` in-place with `codeSize_pos` (`∀ m, 0 < codeSize
  m`) and `encode_card_eq` (`∀ m adj, (encode m adj).card =
  codeSize m`) non-degeneracy fields. Closes audit J-03 footgun:
  the `encode _ _ := ∅` degenerate witness fails `0 < codeSize m`
  at compile time. Added type-level satisfiability witness
  `GIReducesToCE_card_nondegeneracy_witness` confirming the
  non-degeneracy fields are independently inhabitable. A *full*
  `Nonempty GIReducesToCE` (discharging the iff) requires a tight
  Karp reduction (CFI 1992 / Petrank–Roth 1997); research-scope
  R-15.
* **I5 — `Hardness/TensorAction.lean`.** Strengthened
  `GIReducesToTI` in-place with `encode_nonzero_of_pos_dim`
  (`∀ m, 1 ≤ m → ∀ adj, encode m adj ≠ (fun _ _ _ => 0)`)
  non-degeneracy field. Closes audit J-08 footgun symmetrically
  to I4. Added type-level satisfiability witness
  `GIReducesToTI_nondegeneracy_witness` (specialised to
  `F = ZMod 2` for decidability). Full inhabitant of the iff is
  research-scope (Grochow–Qiao 2021 structure-tensor encoding,
  R-15).
* **I6 — `PublicKey/ObliviousSampling.lean`.** Renamed
  `ObliviousSamplingHiding` → `ObliviousSamplingPerfectHiding`
  (the predicate is `False` on every non-trivial bundle, so the
  post-I name accurately conveys the perfect-extremum strength)
  and the companion theorem
  `oblivious_sampling_view_constant` →
  `oblivious_sampling_view_constant_under_perfect_hiding`. Added
  new probabilistic ε-smooth predicate
  `ObliviousSamplingConcreteHiding`: the sender's obliviously-
  sampled output is at advantage ≤ ε from a fresh uniform orbit
  sample (`orbitDist`). Added structural extraction lemma
  `oblivious_sampling_view_advantage_bound` (mirrors
  `concrete_oia_implies_1cpa` extraction shape). Added non-
  vacuity witness `ObliviousSamplingConcreteHiding_zero_witness`
  at ε = 0 on singleton-orbit bundles (uses `PMF.map_const` twice
  to reduce both PMFs to point masses, then `advantage_self`).

### Verification

`lake build` succeeds for all 39 modules with zero warnings / zero
errors. `scripts/audit_phase_16.lean` exercises every Workstream-I
declaration via `#print axioms` (every entry returns either "does
not depend on any axioms" or `[propext, Classical.choice,
Quot.sound]`; never `sorryAx` or a custom axiom) and 13 non-vacuity
`example` blocks (one per substantive Workstream-I deliverable
plus negative-pressure regressions for I4 / I5 confirming the
strengthened Props correctly *reject* the audit-flagged degenerate
encoders at compile time).

### Counts

* **9 new public declarations** (4 strong-content + 2 helpers + 3
  named witnesses):
  `concreteOIA_zero_of_subsingleton_message` (I1),
  `concreteKEMOIA_uniform_zero_of_singleton_orbit` (I2),
  `canon_indicator_isGInvariant` (I3 helper),
  `distinct_messages_have_invariant_separator` (I3),
  `GIReducesToCE_card_nondegeneracy_witness` (I4 structural
  witness),
  `GIReducesToTI_nondegeneracy_witness` (I5 structural witness),
  `ObliviousSamplingConcreteHiding` (I6),
  `oblivious_sampling_view_advantage_bound` (I6),
  `ObliviousSamplingConcreteHiding_zero_witness` (I6).
* **4 renamed declarations** (content-neutral):
  `indCPAAdvantage_le_one` (was `concreteOIA_one_meaningful`),
  `insecure_implies_orbit_distinguisher` (was
  `insecure_implies_separating`),
  `ObliviousSamplingPerfectHiding` (was
  `ObliviousSamplingHiding`),
  `oblivious_sampling_view_constant_under_perfect_hiding` (was
  `oblivious_sampling_view_constant`).
* **2 strengthened in-place** (signature-level non-degeneracy
  fields added; same identifier carries the stronger Prop):
  `GIReducesToCE` (gains `codeSize`, `codeSize_pos`,
  `encode_card_eq` fields), `GIReducesToTI` (gains
  `encode_nonzero_of_pos_dim` field).
* **1 deletion** (no replacement; consumers migrate to the
  pre-existing `kemAdvantage_le_one`):
  `concreteKEMOIA_one_meaningful` (redundant duplicate;
  Workstream I2).

### Deviations from the audit plan

The audit plan section 12.4 specified
`GIReducesToCE_singleton_witness` and
`GIReducesToTI_constant_one_witness` as full inhabitants of the
strengthened Props (with the iff discharged at trivial 1-vertex /
constant-1-tensor encoders). After implementation, **the
singleton/constant encoders are mathematically not valid witnesses
for the strengthened iff**: with a constant encoder, RHS
(`ArePermEquivalent` / `AreTensorIsomorphic`) is always True via
the identity, which forces LHS (the GI predicate) to be always
True — but the GI predicate fails for non-isomorphic graphs at
`m ≥ 2`. The plan's claimed witnesses thus fail to elaborate. The
Workstream-I landing replaces them with type-level *non-degeneracy
structural witnesses*
(`GIReducesToCE_card_nondegeneracy_witness` and
`GIReducesToTI_nondegeneracy_witness`) that confirm the
strengthened non-degeneracy fields are independently inhabitable
without claiming a full Prop inhabitant. The substantive content
(closing the J-03 / J-08 footguns *at the type level* — the
audit-flagged degenerate encoders fail to elaborate) is preserved;
a full inhabitant of `GIReducesToCE` / `GIReducesToTI` (discharging
the iff) requires a tight Karp reduction (CFI 1992 / Petrank–Roth
1997 / Grochow–Qiao 2021) and remains research-scope (audit plan
§ 15.1 / R-15). This deviation is recorded honestly here and in
the relevant theorem docstrings.

### Patch version

`lakefile.lean` bumped from `0.1.12` to `0.1.13` for Workstream I
— the structural changes (signature-level field additions on
`GIReducesToCE` and `GIReducesToTI`, deletion of
`concreteKEMOIA_one_meaningful`, four content-neutral renames,
nine new public declarations) constitute an API break warranting a
patch bump per `CLAUDE.md`'s version-bump discipline. Module count
remains 39; public declaration count rises from 358 to **366**
(9 new − 1 deleted + 0 net rename change = +8). Zero-sorry /
zero-custom-axiom posture preserved; standard-trio-only axiom-
dependency posture preserved. The Phase-16 audit script gains 13
new non-vacuity `example` blocks plus 9 new `#print axioms`
entries (4 renamed entries replace pre-I names; 1 entry deleted).

## Workstream I Post-Audit Snapshot (2026-04-25)

A post-audit critical evaluation of the initial Workstream-I
landing concluded that 4 of the 9 "new" theorems were
**theatrical**: they technically inhabited their predicates but
required hypotheses that collapse the security space to a single
element (subsingleton message space, singleton-orbit KEM,
singleton-orbit oblivious-sampling bundle), giving advantage 0
on instances where there is no security game to play. These
four theorems satisfied a literal exit-criterion checkbox in
the audit plan but contributed no cryptographic content.

### Removed (theatrical)

* `concreteOIA_zero_of_subsingleton_message`
  (`Crypto/CompSecurity.lean`, I1) — required `[Subsingleton M]`.
* `concreteKEMOIA_uniform_zero_of_singleton_orbit`
  (`KEM/CompSecurity.lean`, I2) — required
  `∀ g, g • basePoint = basePoint`.
* `ObliviousSamplingConcreteHiding_zero_witness`
  (`PublicKey/ObliviousSampling.lean`, I6) — required
  singleton-orbit bundle + constant `combine`.
* `oblivious_sampling_view_advantage_bound`
  (`PublicKey/ObliviousSampling.lean`, I6) — one-line wrapper
  `hHide D` of the predicate's universal quantifier.

### Added (substantive replacement)

* **Non-degenerate concrete fixture** in
  `PublicKey/ObliviousSampling.lean`:
  `concreteHidingBundle : OrbitalRandomizers (Equiv.Perm Bool)
  Bool 2` (basePoint `false`, randomizers `![false, true]`,
  orbit cardinality 2 — the maximum on Bool) and
  `concreteHidingCombine : Bool → Bool → Bool := fun a b => a
  && b` (Boolean AND, biased push-forward). On paper, the
  worst-case adversary advantage on this fixture is exactly
  `1/4` — a tight ε ∈ (0, 1) bound. The Lean proof of the
  precise `1/4` bound requires PMF point-mass arithmetic over
  `Equiv.Perm Bool` and `Fin 2 × Fin 2` plus a TV-distance
  bound for Bool PMFs (~150 lines of low-level
  ENNReal/Real conversions in the pinned Mathlib commit).
  Tracked as **research-scope R-12** (audit plan § O); the
  in-tree contribution is the non-degenerate fixture itself,
  documented with the on-paper analysis.
* **Mathlib-style helpers** in `Probability/Monad.lean`:
  `probTrue_map` (push-forward through `PMF.map`) and
  `probTrue_uniformPMF_card` (uniform-PMF outer measure as a
  filter-cardinality ratio). These are general-purpose tools
  that downstream R-12 work will use.

### Type-level posture upgrade witnesses retained

`GIReducesToCE_card_nondegeneracy_witness` and
`GIReducesToTI_nondegeneracy_witness` were honest from the
initial landing — they witness the *strengthened non-degeneracy
fields* of `GIReducesToCE` and `GIReducesToTI` (a *sub-
predicate* of the full Prop, omitting the iff). They do **not**
witness the full strengthened Props; that requires a tight
Karp reduction (CFI 1992 / Petrank–Roth 1997 / Grochow–Qiao
2021), which remains research-scope **R-15**. The
docstrings in those theorems disclose this honestly.

### Counts (post-audit)

* **6 new public declarations**:
  `canon_indicator_isGInvariant` (I3 helper),
  `distinct_messages_have_invariant_separator` (I3 substantive),
  `GIReducesToCE_card_nondegeneracy_witness` (I4 type-level),
  `GIReducesToTI_nondegeneracy_witness` (I5 type-level),
  `ObliviousSamplingConcreteHiding` (I6 vocabulary),
  `concreteHidingBundle` (post-audit fixture),
  `concreteHidingCombine` (post-audit fixture),
  `probTrue_map` (post-audit helper),
  `probTrue_uniformPMF_card` (post-audit helper).
* **4 renamed declarations** (content-neutral, unchanged):
  `indCPAAdvantage_le_one`,
  `insecure_implies_orbit_distinguisher`,
  `ObliviousSamplingPerfectHiding`,
  `oblivious_sampling_view_constant_under_perfect_hiding`.
* **2 strengthened in-place** (Prop signatures): `GIReducesToCE`,
  `GIReducesToTI`.
* **1 deletion of redundant duplicate** (unchanged):
  `concreteKEMOIA_one_meaningful`.
* **4 deletions of theatrical content** (post-audit):
  `concreteOIA_zero_of_subsingleton_message`,
  `concreteKEMOIA_uniform_zero_of_singleton_orbit`,
  `ObliviousSamplingConcreteHiding_zero_witness`,
  `oblivious_sampling_view_advantage_bound`.

Module count: **39** (unchanged). The Phase-16 audit script's
`#print axioms` total stabilises at **389** (down from the
post-initial-landing 391 — the 4 theatrical entries deleted +
2 fixture-related entries added). All remaining `#print axioms`
outputs are standard-trio (`propext`, `Classical.choice`,
`Quot.sound`) or axiom-free.

### Honest scoreboard

The Workstream-I post-audit refactor demonstrates the
**Security-by-docstring prohibition** in action at the
project-internal level: rather than ship 9 "new theorems" with
4 of them theatrically vacuous, the post-audit pass keeps only
content that genuinely advances the project. The honest
delivery is:

1. The *substantive* `distinct_messages_have_invariant_separator`
   theorem (closes a 2-year-old audit gap, F-06 / D-07).
2. The *type-level* posture upgrades (Prop signatures
   strengthened to ban audit-flagged degenerate encoders at
   compile time).
3. The *non-degenerate* fixture (`concreteHidingBundle` +
   `concreteHidingCombine`) — concrete cryptographic content
   that downstream research can target with a tight ε bound.
4. The *renames* (Security-by-docstring hygiene for four
   misnamed identifiers).
5. *Honest research-scope disclosures* of R-12 (precise ε = 1/4
   ObliviousSamplingConcreteHiding bound) and R-15 (full Karp
   reduction inhabitants for `GIReducesToCE` / `GIReducesToTI`).

`lakefile.lean` bumped from `0.1.13` to `0.1.14` for the
post-audit refactor.

## Workstream R-TI Snapshot (audit 2026-04-25, GI ≤ TI Karp reduction, partial closure)

Workstream R-TI (audit 2026-04-25, plan
`docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`)
formalises the Grochow–Qiao 2021 Karp reduction from Graph
Isomorphism (GI) to Tensor Isomorphism (TI) per the post-audit
strengthening (Decisions GQ-A through GQ-D in the plan):

* **Decision GQ-A:** encoder algebra is the radical-2 truncated
  path algebra `F[Q_G] / J²` (replaces `F[A_G]` to fix the
  cospectral-graph soundness defect).
* **Decision GQ-B:** dimension is `dimGQ m := m + m * m` with
  distinguished padding (replaces `m + 1` zero-padding to fix the
  padding-rigidity defect).
* **Decision GQ-C:** field is `F := ℚ` (replaces `ZMod 2` to enable
  classical rigidity arguments).
* **Decision GQ-D:** Layer T0 paper synthesis is a planned 1-week
  activity with concrete deliverables (replaces the vague pre-
  implementation review caveat).

### What landed (this commit, partial closure)

**Layer T0 — paper synthesis (4 markdown documents + 1 transient
Lean stub).** Decision GQ-D's defensive measure: every R-TI design
choice cites a specific Grochow–Qiao 2021 paper section as
justification, before any Lean implementation begins. Files:

* `docs/research/grochow_qiao_path_algebra.md` — radical-2 path
  algebra structure note (~200 lines markdown, Decision GQ-A).
* `docs/research/grochow_qiao_mathlib_api.md` — Mathlib API audit
  catalogue (~150 lines markdown, Decision GQ-D).
* `docs/research/grochow_qiao_padding_rigidity.md` — distinguished-
  padding rigidity proof sketch (~250 lines markdown, Decision GQ-B
  + the Layer T5.4 design contract).
* `docs/research/grochow_qiao_reading_log.md` — bibliography +
  per-decision paper-citation cross-reference (~150 lines markdown,
  Decision GQ-D).
* `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean` (transient,
  deletable at end of Layer T1 once the API has been exercised by
  the live `PathAlgebra.lean` / `StructureTensor.lean` imports).

**Layer T1 — `Orbcrypt/Hardness/GrochowQiao/PathAlgebra.lean` (~370
lines).** Sub-tasks T1.1, T1.2, T1.4, T1.5, T1.6 (basis-element
form). The radical-2 truncated path algebra `F[Q_G] / J²`:

* `QuiverArrow m` inductive type with `DecidableEq` and `Fintype`
  instances.
* `presentArrows m adj` — Finset of present basis elements (vertex
  idempotents always present, arrows present iff `adj u v = true`).
* `pathAlgebraDim m adj` — `m + |E_directed|` cardinality.
* `pathAlgebraDim_apply` — explicit decomposition lemma.
* `pathAlgebraDim_le : pathAlgebraDim m adj ≤ m + m * m` — upper
  bound matching `dimGQ m`.
* `pathMul m a b : Option (QuiverArrow m)` — radical-2 truncated
  multiplication table.
* `pathMul_id_id` / `pathMul_id_edge` / `pathMul_edge_id` /
  `pathMul_edge_edge_none` — explicit multiplication-table lemmas.
* `pathMul_idempotent_iff_id` — characterisation of idempotents at
  the basis-element level (T1.6 partial; the full
  `pathAlgebra_idempotent_iff_vertex` over linear combinations
  requires the basis-indexing equivalence T1.3 and is research-
  scope).

**Layer T2 — `Orbcrypt/Hardness/GrochowQiao/StructureTensor.lean`
(~270 lines).** Sub-tasks T2.1, T2.2, T2.3, T2.4. The dimension-
`m + m * m` tensor encoder with distinguished padding:

* `dimGQ m := m + m * m` — total dimension.
* `SlotKind m` taxonomy with `slotEquiv : Fin (dimGQ m) ≃ SlotKind m`.
  Vertex slots `[0, m)`, arrow slots `[m, m + m * m)` enumerated
  lexicographically by `(u, v)`.
* `isPathAlgebraSlot m adj : Fin (dimGQ m) → Bool` — discriminator;
  `true` for vertex slots unconditionally and arrow slots `(u, v)`
  with `adj u v = true`, `false` for padding slots.
* `pathSlotStructureConstant` — slot-indexed path-algebra structure
  constant (`Fin (dimGQ m)³ → ℚ`).
* `ambientSlotStructureConstant` — graph-independent ambient-matrix
  structure constant (delta-on-diagonal pattern).
* `grochowQiaoEncode m adj : Tensor3 (dimGQ m) ℚ` — the encoder
  itself, defined piecewise: path-algebra constants on path-algebra
  slot triples, ambient-matrix constants on padding slot triples.
* `grochowQiaoEncode_nonzero_of_pos_dim` — the encoder is non-zero
  (as a function) on every non-empty graph, witnessed at the
  `(vertex 0, vertex 0, vertex 0)` diagonal where the idempotent
  law `e_0 · e_0 = e_0` produces `1`. Discharges the
  strengthened-Prop's `encode_nonzero_of_pos_dim` field.

**Layer T3 partial — `Orbcrypt/Hardness/GrochowQiao/Forward.lean`
(~200 lines).** Sub-tasks T3.1, T3.2, T3.3 at the slot-permutation
level. The forward direction's slot lift:

* `liftedSigmaSlot m σ : SlotKind m → SlotKind m` — vertex
  permutation σ acts as `vertex v ↦ vertex (σ v)` and
  `arrow u v ↦ arrow (σ u) (σ v)`.
* `liftedSigmaSlotEquiv m σ` — `SlotKind m ≃ SlotKind m`.
* `liftedSigma m σ : Equiv.Perm (Fin (dimGQ m))` — the conjugation
  through `slotEquiv`.
* `liftedSigma_one`, `liftedSigma_mul` — group homomorphism laws.
* `liftedSigma_vertex`, `liftedSigma_arrow` — slot-shape preservation
  lemmas.
* `isPathAlgebraSlot_liftedSigma` — under the GI hypothesis
  `∀ i j, adj₁ i j = adj₂ (σ i) (σ j)`, the path-algebra slot
  predicate is preserved by `liftedSigma σ`. **This is the
  statement Layer T4.1's reverse-direction rigidity argument
  inverts.**

**Top-level — `Orbcrypt/Hardness/GrochowQiao.lean` (~150 lines).**
Re-exports the encoder + slot lift + non-vacuity content with prose
documentation of the partial closure status and explicit research-
scope disclosure for Layer T5 rigidity argument.

### What is research-scope (not landed in this commit)

**Layer T3.4 onwards — full forward action verification at the GL³
matrix level.** `pathStructureConstant_equivariant` and the GL³
matrix-action computation `g • grochowQiaoEncode m adj₁ =
grochowQiaoEncode m adj₂` are the Layer-T3 core lemmas. They
require:

* `Equiv.Perm.toMatrix` (or hand-rolled `permMatrixOfEquiv`) to lift
  `liftedSigma m σ : Equiv.Perm (Fin (dimGQ m))` to a permutation
  matrix in `Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ`.
* The `Matrix.GeneralLinearGroup` / `IsUnit`-via-permutation-matrix
  lift to embed into `GL (Fin (dimGQ m)) ℚ`.
* The multilinear `Tensor3` action `(P, P, P) • T` with full
  unfolding through `tensorContract`.

Audit-plan budget: ~400 lines for T3.4 + T3.6 alone. Tracked as
research-scope **R-15-residual-TI-forward-matrix**.

**Layer T4 + T5 — the rigidity argument.** Sub-tasks T4.1 through
T5.5:

* T4.1 — `GL_triple_preserves_path_algebra_partition`: any GL³
  preserving the encoder preserves the path-algebra/padding partition
  (the design contract sketched in
  `docs/research/grochow_qiao_padding_rigidity.md` § 3).
* T4.2 — GL³ restricts to a path-algebra automorphism on the path-
  algebra subblock.
* T4.3 — algebra automorphism characterisation: any algebra
  automorphism of `F[Q_G] / J²` permutes the vertex idempotents
  along a unique bijection σ.
* T4.4 — σ extends to an arrow bijection.
* T4.5 — σ preserves adjacency (the GI condition).
* T5.1–T5.5 — composition of T4.1–T4.5 with the σ-lift to
  `Equiv.Perm (Fin m)` to deliver the full reverse direction.

Audit-plan budget: ~1,800 lines of Lean across Layers T4 + T5.
Tracked as **R-15-residual-TI-reverse**. Per the audit plan, this
is the single largest research-scope item in the entire R-15
project; the strengthened design (path algebra + distinguished
padding + ℚ) reduces the worst-case ceiling from 12,000+ lines to
~8,000 lines, but the rigidity proof itself remains a multi-month
undertaking spanning ~80 pages of Grochow–Qiao SIAM J. Comp. 2023
§4.3.

**Layer T6 — full `GIReducesToTI` inhabitant.** With T5 landed,
Layer T6's `grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _`
follows by direct assembly. Pre-rigidity, the existence of the
*complete* inhabitant remains research-scope.

### Verification

**Module count.** `Orbcrypt/Hardness/GrochowQiao/PathAlgebra.lean`,
`Orbcrypt/Hardness/GrochowQiao/StructureTensor.lean`,
`Orbcrypt/Hardness/GrochowQiao/Forward.lean`, and
`Orbcrypt/Hardness/GrochowQiao.lean` — four new public modules.
The transient `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean` is the
Layer-T0.2 deliverable; deletable at end of Layer T1 (kept for
this landing as the API survey is still informative pre-T5). New
total module count: 47 (43 pre-R-TI plus 4 new).

**`#print axioms`.** Every public R-TI declaration depends only on
the standard Lean trio (`propext`, `Classical.choice`, `Quot.sound`)
or on no axioms at all. No `sorryAx`, no custom axiom. The
Phase 16 audit script's R-TI section exercises every declaration
plus 16 non-vacuity `example` bindings spanning T1, T2, T3, and
top-level surfaces.

**`lake build`.** Full project builds clean (3,375 jobs, zero
errors, zero warnings).

**Status column impact.** No headline-theorem table changes — R-TI
is a *partial closure* of the existing `GIReducesToTI` Karp-claim
Prop. Its `encode_nonzero_of_pos_dim` field is now dischargeable
via `grochowQiao_encode_nonzero_field` against the Grochow–Qiao
encoder; the iff direction remains research-scope.

`lakefile.lean` bumped from `0.1.16` (post-Workstream-R-CE) to
`0.1.17` for the R-TI partial-closure landing.

## Workstream R-TI Layers T2.5–T6 + stretch (audit 2026-04-25, partial-closure extension)

Extension landing 2026-04-26 to the Workstream R-TI partial closure.
Adds the encoder evaluation lemmas (T2.5), padding-distinguishability
(T2.6), σ-action on quiver arrows + multiplicative equivariance,
slot-level path-structure-constant equivariance (T3.4), encoder-
equality form of the forward direction (T3.7), the rigidity-Prop
skeleton + edge-case reverse directions (T4 + T5), conditional iff
+ conditional Karp-reduction inhabitant (T6), plus stretch-goal Props
T5.6 (asymmetric GL³) and T5.8 (char-0 generalisation).

### What landed (this commit)

**Reverse module — `Orbcrypt/Hardness/GrochowQiao/Reverse.lean`.**
Captures the Layer T4 + T5 + T5-stretch obligations as `Prop`-typed
hypotheses, threads them through downstream theorems, and proves
the unconditional edge-cases:

* `GrochowQiaoRigidity` — research-scope rigidity Prop. Universal
  quantification on `(m, adj₁, adj₂)`, so a discharge is uniform
  across all graph pairs (matches the Karp-reduction iff signature).
* `grochowQiaoEncode_reverse_zero` — unconditional reverse direction
  at `m = 0` (`Fin.elim0`-based vacuous discharge).
* `grochowQiaoEncode_reverse_one` — unconditional reverse direction
  at `m = 1` (`Subsingleton.elim` on `Fin 1`).
* `grochowQiaoEncode_reverse_under_rigidity` — Layer T5.4 conditional
  reverse direction.
* `GrochowQiaoAsymmetricRigidity` — T5.6 stretch Prop;
  `grochowQiaoAsymmetricRigidity_iff_symmetric` proves the
  asymmetric ↔ symmetric reduction for graphs.
* `GrochowQiaoCharZeroRigidity` — T5.8 stretch Prop;
  `grochowQiaoCharZeroRigidity_at_rat` shows the `F = ℚ` instance
  reduces to `GrochowQiaoRigidity`.
* `PathAlgebraAutomorphismPermutesVertices` — T4.3 research-scope
  Prop; `quiverMap_satisfies_vertex_permutation_property` proves
  the easy direction (when φ comes from a known σ).

**Layer T2.5 + T2.6 — encoder evaluation + padding-distinguishability.**
Extended `Orbcrypt/Hardness/GrochowQiao/StructureTensor.lean` with
the per-slot-triple unfoldings and the structural T2.6 lemma
(`grochowQiaoEncode_padding_distinguishable`).

**Layer T1 σ-action — `quiverMap` + `pathMul_quiverMap`.** Extended
`Orbcrypt/Hardness/GrochowQiao/PathAlgebra.lean` with the σ-action
on quiver basis elements (the natural action on `id v` and `edge u v`
constructors), the group-action laws (`quiverMap_one`,
`quiverMap_injective`), and the multiplicative-equivariance lemma
`pathMul_quiverMap`. Direct case-split on the four-case `pathMul`
table; every "if u = v" decision is preserved under σ-injectivity.

**Layer T3.4 + T3.7 — encoder equivariance under the σ-lift.** Extended
`Orbcrypt/Hardness/GrochowQiao/Forward.lean` with:

* `slotToArrow_liftedSigmaSlot` — `slotToArrow ∘ liftedSigmaSlot σ
  = quiverMap σ ∘ slotToArrow`.
* `ambientSlotStructureConstant_equivariant` — graph-independent
  ambient constant is σ-equivariant.
* `pathSlotStructureConstant_equivariant` — slot-level σ-equivariance,
  reduces to `pathMul_quiverMap`.
* `grochowQiaoEncode_equivariant` — encoder-equality form of the
  forward direction; the GL³ matrix-action upgrade is research-scope
  (`GrochowQiaoForwardObligation` Prop in T6).

**Layer T6 — iff assembly + conditional inhabitant.** Extended
`Orbcrypt/Hardness/GrochowQiao.lean` (top-level) with:

* `GrochowQiaoForwardObligation` — Prop capturing the GL³ matrix-
  action lift of the forward direction.
* `grochowQiaoEncode_iff` — Karp-reduction iff conditional on both
  research-scope Props (`GrochowQiaoForwardObligation` and
  `GrochowQiaoRigidity`).
* `grochowQiao_isInhabitedKarpReduction_under_obligations` —
  consumer-facing complete `@GIReducesToTI ℚ _` inhabitant under
  both Props.
* `grochowQiao_partial_closure_status` — final non-vacuity disclosure.

### Verification

**Module count.** `Orbcrypt/Hardness/GrochowQiao/Reverse.lean` is
the new fifth file under `GrochowQiao/`, bringing the total module
count to 48 (47 pre-extension plus the new Reverse module).

**`#print axioms`.** All 32 new declarations depend only on the
standard Lean trio (`propext`, `Classical.choice`, `Quot.sound`)
or on no axioms at all. The Phase 16 audit script's R-TI section
exercises every declaration plus 30 non-vacuity `example` bindings
(16 pre-extension + 14 new bindings spanning T2.5/T2.6, T1
quiverMap, T3.4/T3.7, T5.3 (`m=0` reverse), T5.4 conditional reverse,
T5.6 stretch, T5.8 stretch, T6.1 iff, T6.3 conditional inhabitant,
T6.4 partial closure status).

**`lake build`.** Full project builds clean (3,376 jobs, zero
errors, zero warnings).

**Status column impact.** No headline-theorem table changes — the
extension still leaves the *full* `GIReducesToTI` Karp-claim Prop
as research-scope (the iff requires discharging both
`GrochowQiaoForwardObligation` and `GrochowQiaoRigidity`). The
encoder-equality form of the forward direction
(`grochowQiaoEncode_equivariant`) is delivered unconditionally, as
is the empty-graph reverse direction.

`lakefile.lean` bumped from `0.1.17` to `0.1.18` for the R-TI
extension landing.

### Honest scope disclosure

The audit plan budgets Layers T4 + T5 + T5-stretch + T6 at
3,300–7,300 lines / 5–10 weeks of dedicated mathematical research
work. The post-extension landing delivers:

* **Unconditional content.** All Layer T2.5/T2.6/T1-quiverMap/T3.4/
  T3.7/T5.3/T5-stretch/T6.4 declarations have full proofs (no
  `sorry`, no custom axiom, no vacuously-true Prop).

* **Research-scope obligations as `Prop`s.** The genuinely difficult
  rigidity argument (~80 pages on paper, ~2,000 lines on Lean) and
  the GL³ matrix-action upgrade (~400 lines) are landed as
  `Prop`-typed hypotheses, threaded through higher-level conditional
  theorems (`grochowQiaoEncode_iff`,
  `grochowQiao_isInhabitedKarpReduction_under_obligations`). This
  is the same pattern the Orbcrypt formalization uses for `OIA`,
  `KEMOIA`, `HardnessChain`, and `ConcreteHardnessChain` — and it is
  the only way to land a complete consumer-facing Karp-reduction
  interface without compromising on `sorry`/axiom hygiene.

* **Tracking.** Discharging `GrochowQiaoRigidity` is research-scope
  **R-15-residual-TI-reverse**; discharging
  `GrochowQiaoForwardObligation` is research-scope
  **R-15-residual-TI-forward-matrix**. Both remain post-v1.0
  research-scope items.
-/
