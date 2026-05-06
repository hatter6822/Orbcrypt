<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Hardness Analysis — Orbcrypt Alignment with NIST PQC Candidates

## Overview

This document analyzes the relationship between Orbcrypt's Orbit
Indistinguishability Assumption (OIA) and the hardness problems underlying
active NIST Post-Quantum Cryptography (PQC) candidates. By aligning with
these well-studied problems, Orbcrypt inherits the cryptanalytic scrutiny
they receive, strengthening the theoretical foundation beyond informal
GI/CE reductions.

## 1. Problem Definitions

### 1.1 Graph Isomorphism (GI)

**Input:** Two graphs G₁ = (V, E₁) and G₂ = (V, E₂) on n vertices.
**Question:** Does there exist a permutation σ ∈ S_n such that (u,v) ∈ E₁ iff (σ(u), σ(v)) ∈ E₂?

**Best classical complexity:** 2^O(√(n log n)) — Babai (2015), quasi-polynomial.
**Best quantum complexity:** Open. No known quantum speedup beyond classical.

**Orbcrypt relation:** GI-OIA reduces to GI. Orbcrypt's security on CFI graph instances
is grounded in GI hardness. See docs/DEVELOPMENT.md §5.3.

### 1.2 Permutation Code Equivalence (CE)

**Input:** Two linear codes C₁, C₂ ⊆ F_q^n (as generator matrices).
**Question:** Does there exist σ ∈ S_n such that σ(C₁) = C₂ (permuting coordinates)?

**Best classical complexity:** At least as hard as GI (GI ≤_p CE). Believed strictly
harder for specific code families (e.g., random codes over large fields).

**Orbcrypt relation:** CE-OIA reduces to CE. The Permutation Automorphism group PAut(C)
plays the role of the secret key's symmetry group.

**Formalization:** `Orbcrypt/Hardness/CodeEquivalence.lean` defines `ArePermEquivalent`,
`PAut`, `ConcreteCEOIA` (probabilistic), and proves the PAut coset structure theorems.
(The deterministic `CEOIA` Prop was deleted in Workstream W6 of the 2026-05-06
structural review — vacuous on production instances; the probabilistic `ConcreteCEOIA`
is the substantive content.)

### 1.3 Linear Code Equivalence (LE)

**Input:** Two linear codes C₁, C₂ ⊆ F_q^n.
**Question:** Does there exist a monomial transformation M (diagonal × permutation)
such that M(C₁) = C₂?

**Relationship to CE:** Permutation equivalence is a special case of monomial equivalence
(where the diagonal part is the identity). Therefore CE ≤_p LE, and CE-OIA is a
*weaker* assumption than LE-hardness.

**Used by:** **LESS** signature scheme (NIST PQC candidate, Biasse et al., 2020).
LESS's one-wayness relies on the hardness of recovering a secret monomial
transformation from public code pairs.

### 1.4 Matrix Code Equivalence (MCE)

**Input:** Two matrix codes C₁, C₂ ⊆ F_q^{m×n} (sets of matrices).
**Question:** Does there exist (A, B) ∈ GL(m) × GL(n) such that A·C₁·B = C₂?

**Relationship to CE:** MCE generalizes CE to two-sided equivalence. When restricted
to vector codes (m = 1), MCE reduces to monomial equivalence. MCE is at least as
hard as CE and believed harder for general matrix codes.

**Used by:** **MEDS** signature scheme (NIST PQC candidate, Chou et al., 2023).

### 1.5 Alternating Trilinear Form Equivalence (ATFE)

**Input:** Two alternating trilinear forms T₁, T₂ : V³ → F.
**Question:** Does there exist A ∈ GL(V) such that T₂(x,y,z) = T₁(Ax, Ay, Az)?

**Relationship:** ATFE is a special case of Tensor Isomorphism where the three
GL components are constrained to be identical and the tensor is alternating.
Believed strictly harder than GI.

**Used by:** **MEDS** (alternative formulation), connecting to ATFE-based hardness.

### 1.6 Tensor Isomorphism (TI)

**Input:** Two 3-tensors T₁, T₂ : (F^n)^⊗3.
**Question:** Does there exist (A, B, C) ∈ GL(n,F)³ such that (A,B,C) · T₁ = T₂?

**Best classical complexity:** At least as hard as GI. **No quasi-polynomial algorithm
known** — this is the key distinction from GI.

**Best quantum complexity:** Open. Inherits the Hidden Subgroup Problem barrier
from GI, plus additional structural hardness.

**Orbcrypt relation:** `ConcreteTensorOIA` is the strongest assumption in the
probabilistic reduction chain. TI-based hardness provides the most conservative
security margin.

**Formalization:** `Orbcrypt/Hardness/TensorAction.lean` defines `Tensor3`,
the GL(n,F)³ `MulAction` instance (with fully proved `one_smul` and `mul_smul`),
`AreTensorIsomorphic`, and the probabilistic `ConcreteTensorOIA` predicate.
(The deterministic `TensorOIA` Prop was deleted in Workstream W6 of the
2026-05-06 structural review — vacuous on production instances; the
probabilistic `ConcreteTensorOIA` is the substantive content.)

## 2. LESS/MEDS Alignment

### 2.1 LESS Connection

The **LESS** (Linear Equivalence Signature Scheme) signature scheme builds on
the hardness of the Linear Code Equivalence problem. The connection to Orbcrypt:

1. **Permutation equivalence ⊂ Monomial equivalence ⊂ Linear equivalence:**
   Orbcrypt's CE-OIA uses only permutation equivalence, which is the weakest
   case. Therefore, CE-OIA is a *weaker* assumption than LESS's hardness.

2. **Reduction direction:** CE-OIA ≤ LE ≤ ME (monomial equivalence).
   If LESS is secure (LE is hard), then CE is at least as hard, and CE-OIA
   holds for appropriate code families.

3. **PAut structure:** LESS's security relies on the difficulty of recovering
   PAut(C) for random codes. Our `paut_compose_preserves_equivalence` theorem
   formalizes the structural property that PAut knowledge enables CE solving,
   confirming that PAut recovery is necessary and sufficient.

### 2.2 MEDS Connection

The **MEDS** (Matrix Equivalence Digital Signature) scheme uses Matrix Code
Equivalence (MCE) or equivalently the Alternating Trilinear Form Equivalence
(ATFE) problem.

1. **MCE generalizes CE:** Matrix codes are a natural extension of vector codes.
   MCE involves two-sided equivalence (left and right GL actions), which is
   captured by the tensor action framework in our formalization.

2. **ATFE ↔ restricted TI:** ATFE is a special case of Tensor Isomorphism where
   the three GL components are constrained to be identical. Our general TI
   formalization subsumes ATFE.

3. **Security inheritance:** MEDS security (MCE/ATFE hardness) implies
   CE hardness, which implies GI hardness, validating Orbcrypt's security
   under progressively weaker assumptions.

## 3. Reduction Chain

**Probabilistic chain (substantive security content).** The
post-W6 formalisation carries a single ε-smooth reduction chain
threading TI-hardness through CE, GI, and the scheme-level OIA
to IND-1-CPA at quantitative bounds. The chain is satisfiable at
`ε ∈ (0, 1]`; in the current formalisation it is inhabited only
at ε = 1 via `ConcreteHardnessChain.tight_one_exists` (and at
the new W4 entry `tight_one_exists_at_s2Surrogate` exhibiting a
non-trivial `S_2`-shaped surrogate at the same ε = 1). Concrete
ε < 1 discharges via the Cai–Fürer–Immerman graph gadget (R-03)
and the Grochow–Qiao structure-tensor encoding (R-02) are
research-scope follow-ups. See `docs/VERIFICATION_REPORT.md`
§ "Release readiness" for the full citation discipline.

**Historical note.** Pre-2026-05-06, the formalisation also
carried a parallel deterministic chain
(`TensorOIA → CEOIA → GIOIA → OIA → IND-1-CPA` via
`oia_implies_1cpa`, `hardness_chain_implies_security`,
`oia_from_hardness_chain`, `TensorOIAImpliesCEOIA`,
`CEOIAImpliesGIOIA`, `GIOIAImpliesOIA`). Each deterministic
predicate was `False` on every non-trivial scheme (the
orbit-membership oracle `decide (x = reps m₀)` refutes it), so
the deterministic chain's headline theorems were vacuously true
on production instances — encoding the *shape* of an OIA-style
reduction argument without delivering standalone security
content. The deterministic chain plus its supporting Props
(`OIA`, `KEMOIA`, `HardnessChain`, the per-link reduction Props,
the per-layer Props `TensorOIA`/`CEOIA`/`GIOIA`, the vacuity
witnesses `det_oia_false_of_distinct_reps` and
`det_kemoia_false_of_nontrivial_orbit`) was deleted in
Workstream W6 of the 2026-05-06 structural review. The
probabilistic chain (`ConcreteOIA`, `ConcreteHardnessChain`,
`ConcreteKEMOIA_uniform`, `ConcreteKEMHardnessChain`) is the
sole security chain post-W6.

### 3.1 Formal Chain

The probabilistic reduction chain, formalized in
`Orbcrypt/Hardness/Reductions.lean`:

```
ConcreteTensorOIA   (strongest — no quasi-poly algorithm)
    |
    | ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding
    ↓                 (tensor-to-code, per-encoding)
  ConcreteCEOIA       (LESS/MEDS level — NIST PQC candidates)
    |
    | ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding
    ↓                 (code-to-graph, per-encoding)
  ConcreteGIOIA       (2^O(√(n log n)) — Babai 2015)
    |
    | ConcreteGIOIAImpliesConcreteOIA_viaEncoding
    ↓                 (graph-to-orbit, per-encoding)
  ConcreteOIA         (scheme-level ε-smooth predicate)
    |
    | concrete_oia_implies_1cpa (Phase 8 — fully proved in Lean 4)
    ↓
indCPAAdvantage ≤ ε   (Crypto/CompSecurity.lean)
```

The chain is composed by `ConcreteHardnessChain.concreteOIA_from_chain`
(structure inhabitation → `ConcreteOIA scheme ε`); the end-to-end
ε-bound is delivered by
`concrete_hardness_chain_implies_1cpa_advantage_bound :
ConcreteHardnessChain … → indCPAAdvantage ≤ ε`. The KEM-layer
parallel runs through `ConcreteKEMHardnessChain` ending at
`concrete_kem_hardness_chain_implies_kem_advantage_bound :
kemAdvantage_uniform … ≤ ε`.

### 3.2 Chain Properties

1. **Each step weakens the assumption:** Moving down the chain
   uses a *weaker* hardness assumption. `ConcreteTensorOIA` is
   the strongest (most conservative); `ConcreteGIOIA` is the
   weakest.

2. **The bottom step is fully proved:** `concrete_oia_implies_1cpa`
   is a Lean 4 theorem with zero `sorry`, zero custom axioms. It
   is unconditionally correct given its hypothesis.

3. **The top steps are complexity-theoretic:** The reductions
   TI → CE → GI are well-known results in computational
   complexity but require encoding constructions (CFI gadgets,
   incidence matrices, structure tensors) that are beyond the
   scope of this formalization. The Workstream-G per-encoding
   shape (`*_viaEncoding`) names explicit encoder functions so
   that concrete witnesses can land additively (research-scope
   R-02 / R-03).

4. **All reductions are Prop definitions:** Each reduction is a
   `Prop`-valued definition (not an `axiom`). This avoids
   logical inconsistency and enables explicit hypothesis
   tracking.

### 3.3 Theorem: Full Chain Implies Security Bound

```lean
theorem concrete_hardness_chain_implies_1cpa_advantage_bound
    {scheme : OrbitEncScheme G X M} {F : Type*} {S : SurrogateTensor F}
    (hc : ConcreteHardnessChain scheme F S ε)
    (A : Adversary X M) :
    indCPAAdvantage scheme A ≤ ε
```

This composes `ConcreteHardnessChain.concreteOIA_from_chain`
with `concrete_oia_implies_1cpa` to derive a quantitative
IND-1-CPA bound from the full TI-based hardness chain.

## 4. Hardness Comparison Table

| Problem | Best Classical | Best Quantum | Used By | Orbcrypt Relation |
|---------|---------------|-------------|---------|-------------------|
| **Factoring** | L(1/3) (NFS) | Poly (Shor) | RSA, DSA | None |
| **DLP** | L(1/3) (NFS) | Poly (Shor) | ECDH, EdDSA | None |
| **LWE** | 2^(n/log n) | 2^(n/log n) | Kyber, Dilithium | None |
| **GI** | 2^O(√(n log n)) | Open | ZKP systems | GI-OIA reduces to GI |
| **Code Equiv (CE)** | ≥ GI | Open | — | CE-OIA reduces to CE |
| **Linear Equiv (LE)** | ≥ CE | Open | **LESS** | CE-OIA ≤ LE |
| **Matrix Code Equiv** | ≥ CE | Open | **MEDS** | Extension of CE |
| **ATFE** | ≥ GI | Open | **MEDS** | Restricted TI |
| **Tensor Iso (TI)** | ≥ GI, no quasi-poly | Open | Emerging | `ConcreteTensorOIA` (strongest) |
| **HSP on S_n** | Super-poly | Super-poly | Multi-query | HGOE multi-query security |

### 4.1 Key Observations

1. **Post-quantum resilience:** GI, CE, LE, MCE, ATFE, and TI all resist
   known quantum attacks. Unlike factoring/DLP (broken by Shor's algorithm)
   and LWE (with known quantum speedups), these problems have no known
   polynomial quantum algorithms.

2. **No quasi-poly for TI:** While Babai's 2015 breakthrough gave GI a
   quasi-polynomial algorithm, no analogous result exists for TI. This makes
   TI the most conservative hardness basis.

3. **NIST validation:** LESS and MEDS are under active NIST evaluation.
   Their security analysis has been scrutinized by the international
   cryptographic community, providing indirect validation of the CE/MCE
   hardness assumptions that Orbcrypt inherits.

4. **Orbcrypt's position:** By grounding security in TI (strongest) and
   validating through CE/GI (well-studied), Orbcrypt achieves a balanced
   security posture — conservative enough for long-term security,
   connected enough to benefit from ongoing cryptanalysis.

## 5. Literature References

1. **Babai, L.** (2016). Graph Isomorphism in Quasipolynomial Time.
   *Proceedings of the 48th ACM STOC*, pp. 684–697.

2. **Cai, J., Fürer, M., & Immerman, N.** (1992). An Optimal Lower Bound
   on the Number of Variables for Graph Identification. *Combinatorica*,
   12(4), pp. 389–410.

3. **Grochow, J. & Qiao, Y.** (2021). On the Complexity of Isomorphism
   Problems for Tensors, Groups, and Polynomials I: Tensor Isomorphism-
   Completeness. *SIAM Journal on Computing*, 52(2).

4. **Biasse, J.-F., Micheli, G., Persichetti, E., & Santini, P.** (2020).
   LESS is More: Code-Based Signatures Without Syndromes. *AFRICACRYPT 2020*.
   NIST PQC submission.

5. **Chou, T., et al.** (2023). MEDS: Matrix Equivalence Digital Signature.
   NIST PQC Round 1 Additional Signatures.

6. **Agrawal, M. & Saxena, N.** (2006). Automorphisms of Finite Rings and
   Applications to Complexity of Problems. *STACS 2006*.

7. **Goldreich, O.** (2001). *Foundations of Cryptography, Volume I*.
   Cambridge University Press. §2.5 (computational indistinguishability).
