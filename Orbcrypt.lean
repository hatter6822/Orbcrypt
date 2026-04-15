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

/-!
# Orbcrypt — Formal Verification of Permutation-Orbit Encryption

This is the root import file. Importing `Orbcrypt` gives access to the
complete formalization: group action foundations, cryptographic definitions,
core theorems, the concrete HGOE construction, the KEM reformulation,
and the probabilistic security foundations (Phase 8).

## Module Dependency Graph

External dependencies (Mathlib):
- `Mathlib.GroupTheory.GroupAction.Defs` — `MulAction`, `orbit`, `stabilizer`
- `Mathlib.GroupTheory.GroupAction.Quotient` — orbit equivalence relation
- `Mathlib.GroupTheory.Perm.Basic` — `Equiv.Perm` (symmetric group)
- `Mathlib.Probability.ProbabilityMassFunction.*` — `PMF` type (Phase 8)
- `Mathlib.Probability.Distributions.Uniform` — `PMF.uniformOfFintype` (Phase 8)
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

hybrid_argument (Probability/Advantage.lean)
  └── advantage_triangle          — triangle inequality for advantage (8.3c)
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
```

No `sorryAx` should appear in any output. If it does, there is a hidden
`sorry` in the dependency chain.
-/
