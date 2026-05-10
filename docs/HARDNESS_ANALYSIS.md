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

### 4.2 Algebraic attacks (PoSSo / Gröbner basis / MQ)

The hardness comparison in §4 covers combinatorial and quantum attack
classes but does not explicitly address **algebraic attacks** — the
family of cryptanalytic techniques that translate a cryptographic
problem into a system of multivariate polynomial equations and solve
it via Gröbner basis (F4 / F5), linearization (XL / MutantXL), or
hybrid guess-and-solve methods. This subsection records why
**Polynomial System Solving (PoSSo) does not break Orbcrypt at the
recommended parameters** of `docs/PARAMETERS.md`, and tracks the
adjacent algebraic threads that an ongoing cryptanalysis programme
should monitor.

#### 4.2.1 Background: when PoSSo wins, when it loses

PoSSo is the search/decision problem

> Given `f₁, …, f_m ∈ F_q[x₁, …, x_n]`, find `a ∈ F_q^n` with
> `f_i(a) = 0` for all `i`.

Standard solvers:

- **F4 / F5** (Faugère 1999, 2002) — Gröbner-basis computation via
  reduction of Macaulay matrices; F5's signature criterion avoids
  reductions to zero on regular sequences.
- **XL / MutantXL** (Courtois–Klimov–Patarin–Shamir 2000;
  Mohamed–Mohamed–Ding–Buchmann 2008) — fix an upper degree `D`,
  expand and linearize.
- **Hybrid F5 + exhaustive search** (Bettale–Faugère–Perret 2009) —
  guess `k` variables, run F5 on the residual; standard against MQ
  over small fields.
- **MinRank modeling + Gröbner** — encode the problem as a low-rank
  constraint on a parameterized matrix (Verbel–Baena–Cabarcas–
  Perlner–Smith-Tone 2019; Bardet–Bros–Cabarcas–Gaborit–Perlner–
  Smith-Tone–Tillich–Verbel 2020).

The dominant complexity parameter is the **degree of regularity**
`d_reg`: F5 / XL terminate in time roughly
`O(\binom{n + d_reg}{d_reg}^ω)` with `ω ≈ 2.37` the linear-algebra
exponent. Schemes broken by PoSSo share a common structural weakness
— a **hidden low-degree algebraic relation** that depresses `d_reg`
far below the `Θ(n)` regime of a generic / random multivariate
system:

- **HFE** (Patarin 1996) was broken by Faugère–Joux 2003 because the
  public quadratic system hides a univariate degree-`D` polynomial
  over an extension field; on the extension, `d_reg = O(log_q D)`.
- **SFLASH** was broken by Dubois–Fouque–Shamir–Stern 2007 via
  differential algebra exposing hidden linearity in the C*- public
  map.
- **Generic random MQ** has `d_reg ≈ Θ(n)` (Bardet–Faugère–Salvy
  2004); PoSSo runs in fully exponential time.

The first lens through which to evaluate Orbcrypt is therefore:
**does HGOE's group-action structure introduce a hidden low-degree
algebraic relation analogous to HFE's univariate trapdoor?** As we
show below, it does not.

#### 4.2.2 Direct PoSSo modeling of HGOE key recovery

HGOE's group action is `(σ • x)(i) = x(σ⁻¹ i)` for `σ ∈ G ≤ S_n`
acting on `Bitstring n` (`Orbcrypt/Construction/Permutation.lean`).
A ciphertext is `c = π · m_b` for `π ←$ G` uniformly. The natural
PoSSo modeling of key recovery — call it **System A** — is:

| Component | Encoding |
|-----------|----------|
| Variables | `p_{ij} ∈ {0,1}` for `i, j ∈ [n]`: permutation-matrix entries (`n²` boolean variables) |
| Boolean | `p_{ij}² − p_{ij} = 0` (`n²` degree-2 equations) |
| Row sums | `Σ_j p_{ij} = 1` for each `i` (lift to `F_p`, `p > n`, to express integer-1) |
| Column sums | `Σ_i p_{ij} = 1` for each `j` |
| Action | `Σ_j p_{ji} c_i = m_j` for `j ∈ [n]` (linear given known `c, m`) |
| **Subgroup** | `π ∈ G` — *the entire cryptanalytic content* |

Without the subgroup-membership constraint, System A is the
**bipartite matching problem** "find any `π ∈ S_n` with
`c = π · m`", solvable in `O(n^{2.5})` by König's theorem and
trivially admitting `weight! · (n − weight)! ≈ 2^Θ(n)` solutions for
balanced strings. The adversary learns nothing about which orbit `c`
lies in — this is the Hamming-weight-only baseline already addressed
by the same-weight defense in `Orbcrypt/Construction/HGOE.lean`. All
cryptanalytic content of System A is therefore concentrated in the
subgroup-membership constraint `π ∈ G`.

#### 4.2.3 Three structural barriers to PoSSo on HGOE

##### Barrier 1 — Encoding `π ∈ G` requires already knowing `G`

Per the OIA model (`docs/DEVELOPMENT.md` §5.2 and
`Orbcrypt/Crypto/CompOIA.lean`), the adversary's `params` does **not**
include `G` or its generators. The structurally cleanest polynomial
encodings of "`π ∈ G`" all require knowing `G`'s presentation:

- **Generator-word encoding:** `π = g_{i₁} g_{i₂} ⋯ g_{i_k}` requires
  word length up to the diameter of `G` (Cayley-graph distance),
  which for parameters with `|G| ≥ 2^λ` is itself super-polynomial.
  Infeasible to substitute back into System A.
- **Invariant-ring encoding:** `π ∈ G ⇔ f_j(π · x) = f_j(x)` for a
  generating set `{f_j}` of `F[x]^G`. But the orbit-separating
  invariants are *exactly* what `docs/COUNTEREXAMPLE.md` warns about
  — if such an `f_j` is efficiently computable and separating, OIA
  is already broken via `Orbcrypt/Theorems/InvariantAttack.lean`
  without any polynomial-system machinery. Conversely, if no such
  invariant exists, the adversary has no relations to write down.
- **Linear-representation encoding:** `π = ρ(g)` with
  `ρ : G ↪ GL(V)` faithful. Requires recovering `G` from samples
  — i.e. solving the **Hidden Subgroup Problem on `S_n`**.

`docs/DEVELOPMENT.md` §5.4 makes the HSP barrier explicit:

> *"To determine `G`, they would need to solve a variant of the
> Hidden Subgroup Problem for `S_n`, which is believed intractable."*

`S_n` is the canonical non-abelian HSP for which Shor-style Fourier
sampling fails; no polynomial classical or quantum algorithm is
known (Hallgren–Russell–Ta-Shma 2003; Moore–Russell–Schulman 2008).
The PoSSo solver therefore cannot even *write down* the
subgroup-membership equations until a more fundamental barrier
falls.

##### Barrier 2 — Solution-count lower bound `|G| ≥ 2^λ`

For a representative `m` with trivial point stabilizer (the generic
case after orbit-separating filtering),

> `#{π ∈ G : π · m = c} = |G| / |Stab_G(m)| = |G| ≥ 2^λ`

at the recommended parameters (`docs/PARAMETERS.md` §2.2: balanced
tier `log₂|G| ≥ 161, 257, 385, 513` for L1, L3, L5, L7). By
elimination theory, the lex-Gröbner basis of the corresponding ideal
`I` has degree at least `|G|` in the eliminated variable, so the GB
output size is `Ω(2^λ)`. Any algorithm that computes the full GB
inherits this lower bound.

The "find one solution, don't enumerate" shortcut (e.g. Magma's
`Variety` via FGLM, or RUR-based solvers) still requires GB
manipulation at degree `d_reg`, and `d_reg` for combinatorial
permutation systems is empirically `Θ(n)`, not the `O(log n)`
regime that makes HFE fall (see §4.2.1). There is no known
*symmetry-aware* GB algorithm (Faugère–Rahmany 2009;
Faugère–Svartz 2013) that drops below `|G|` *when `G` is unknown to
the algorithm* — symmetry-aware F4 takes the symmetry group as
input, which is precisely what Barrier 1 forbids.

##### Barrier 3 — CFI / Weisfeiler–Leman resistance ≈ fixed-degree algebraic-invariant resistance

The hardness reduction `OIA ← GI on CFI graphs`
(`docs/DEVELOPMENT.md` §5.3,
`Orbcrypt/Hardness/CodeEquivalence.lean : GIReducesToCE`) grounds
the project's quantitative security claim. Cai–Fürer–Immerman 1992
proved CFI graphs resist `k`-Weisfeiler–Leman for any fixed `k`,
and the construction extends to `k = poly(n)` by inflating the base
graph's degree. The connection to PoSSo is well-studied in
finite-model theory and proof complexity:

- `k`-WL captures first-order logic with counting and `k`-tuple
  variables (Cai–Fürer–Immerman 1992; Otto 1997).
- `k`-WL is bi-interpretable with bounded-degree polynomial
  invariants over the adjacency matrix (Atserias–Maneva 2013;
  Berkholz–Grohe 2017's analysis of Sherali–Adams hierarchies on
  graph-isomorphism formulations).
- A **degree-`d` Gröbner basis attack** on the GI polynomial system
  `π · A₁ · π^T = A₂` is functionally equivalent to checking
  `2d`-WL color refinement (Grohe 2017, *Descriptive Complexity,
  Canonisation, and Definable Graph Structure Theory*, §11–§13).

Consequently: **CFI-resistance to `k`-WL for unbounded `k` ⟹
resistance to fixed-degree algebraic attacks at the GI level.**
`docs/DEVELOPMENT.md` §5.3 already articulates this defensively
without naming the algebraic-attack class:

> *"This provably eliminates all polynomial-time invariant attacks
> known in the literature."*

Unbounded-degree GB is not formally captured by the WL connection,
but at unbounded degree GB inherits the `|G| ≥ 2^λ` solution-count
lower bound from Barrier 2.

#### 4.2.4 Adjacent algebraic threats to track

The verdict on direct PoSSo against System A is "does not apply",
but cryptanalysts should monitor several adjacent algebraic threads.
These are the places where an algebraic breakthrough on a
neighbouring problem could indirectly affect Orbcrypt's margin.

##### (a) Algebraic attacks on Permutation Equivalence (PEP)

PEP is exactly what underpins HGOE's CE-OIA branch
(`Orbcrypt/Hardness/CodeEquivalence.lean`'s `ArePermEquivalent` and
`PAut`). Algebraic attacks on PEP have been studied since
Saeed-Taha (2017), with the bilinear modeling
`S · G_1 · P = G_2` (where `S ∈ GL_k(F_q)` is the row-space change
of basis and `P ∈ S_n` is the column permutation); raw F4 / F5
empirically clears random PEP instances up to `n ≈ 25–30`. Beullens
(SAC 2020, *Not Enough LESS*) gave a birthday / SSA hybrid that is
sub-exponential but still `2^Ω(n)`; subsequent work in the LESS
NIST PQC Round-2 cryptanalysis effort refines these attacks but
does not produce a polynomial-time PEP solver.

For Orbcrypt's balanced parameters (`n = 4λ`, so `n = 512` at L3,
`n = 1024` at L7 — see `docs/PARAMETERS.md` §6.2), algebraic PEP
attacks are roughly **30+ orders of magnitude beyond practical**
with current techniques, and the empirical `n ≈ 25–30` horizon for
raw GB is on the order of 20 doublings short. This is the most
direct algebraic threat to track — any breakthrough on PEP
cryptanalysis (e.g. a new structural reduction, or a degree-fall on
bilinear PEP systems analogous to HFE's hidden univariate trapdoor)
would be the first place Orbcrypt's margin shrinks.

##### (b) Algebraic folding of the quasi-cyclic structure

Quasi-cyclic (QC) codes admit a **folded representation**: a QC
code over `F_2` of length `n` with `ℓ` blocks of size `b` corresponds
to a code over `F_{2^b}` of length `ℓ`. Algebraic attacks on the
folded code have fewer variables (`ℓ` instead of `n`), and a PoSSo
attempt against the folded representation is qualitatively cheaper
than against the unfolded one. This is the QC-specific analogue of
the folding attacks studied for QC-MDPC / BIKE (Sendrier–Vasseur
2019; Drucker–Gueron–Kostic 2020) and for QC-LDPC structured codes.

This is the **only parameter-level concern** in this subsection,
and `docs/PARAMETERS.md` §4 explicitly fences against it:

> *"algebraic-folding (QC-block structure) requires `n/b ≥ λ`"*

At the **balanced tier** (`b = 4`, `n = 4λ`): `ℓ = λ`, so folding
produces a length-`λ` code over `F_{16}`, and the folded PEP
instance has `λ²` boolean permutation variables — exactly meeting
the target security level. **This is the tightest constraint in
the parameter table.** A `2×` tightening of folded-PEP algebraic
attacks would require re-tuning balanced-tier `b` upward to
`b = 6` or `b = 8`, with corresponding adjustments to `n` and `ℓ`.
Any new algebraic-folding result on QC codes (e.g. coming out of
ongoing BIKE / HQC NIST evaluation) should trigger an Orbcrypt
parameter review.

##### (c) MinRank / algebraic attacks on the tensor branch (ATFE)

The TI hardness branch (`Orbcrypt/Hardness/TensorAction.lean`,
trilinear contraction
`(A,B,C) · T_{ijk} = Σ_{a,b,c} A_{ia} B_{jb} C_{kc} T_{abc}`)
supports the strictest assumption (§4.1 item 2 — "no quasi-poly for
TI"). However, the closely related ATFE problem (§1.5) is under
active algebraic-cryptanalysis pressure:

- **Tang–Duong–Joux–Plantard–Qiao–Susilo** (Eurocrypt 2022,
  *Practical Post-Quantum Signature Schemes from Isomorphism
  Problems of Trilinear Forms*) gave MinRank-style algebraic
  modelings of ATFE with concrete F5 complexity estimates against
  MEDS-class parameters.
- **Subsequent cryptanalytic work** (2023–2025, including the
  algebraic-attack analyses bundled with the MEDS NIST PQC Round-2
  submission and follow-on academic preprints on ATFE / MEDS) has
  refined these into hybrid algebraic-combinatorial attacks; the
  MinRank modeling is now an active analysis line for MEDS
  parameter selection.

These attacks do not currently break ATFE / TI at NIST PQC
parameter sizes, but the field is younger than PEP cryptanalysis
and ε-improvements happen yearly. **If Orbcrypt eventually
instantiates the TI branch with concrete `ε < 1` parameters**
(currently the `ε < 1` instantiation is research-scope per the
Status column in `CLAUDE.md` and the headline-results table in
`docs/VERIFICATION_REPORT.md`; the `tight_one_exists` /
`tight_one_exists_at_s2Surrogate` witnesses are inhabited only at
ε = 1 — see §3 above), the algebraic-attack column on TI / ATFE
becomes the binding security concern, and the parameter review
should incorporate the latest MinRank-modeling complexity
estimates.

##### (d) Hybrid algebraic + lattice / Coppersmith (not currently relevant)

Coppersmith-style small-roots methods combined with Gröbner basis
show up in modular settings (RSA partial-key exposure;
structured-secret LWE). HGOE operates over `F_2` with no modulus
and no lattice structure, so this hybrid does not apply to the
present construction. If a future variant introduces ring or
lattice structure (e.g. a hypothetical lifting of the QC code to
a number-field analogue), this row would require revisiting.

#### 4.2.5 Verdict

| Question | Answer |
|----------|--------|
| Can F5 / F4 directly recover `π` given `c = π · m`? | **No** — System A has `≥ 2^λ` solutions in the worst case; encoding `π ∈ G` requires recovering `G`, which is HSP on `S_n`. |
| Can XL / MutantXL distinguish orbits without recovering `π`? | **No** — same barrier; without `G`, the system collapses to "find any same-Hamming-weight permutation", which has `2^Θ(n)` solutions and zero orbit information. |
| Does HGOE have an HFE-style hidden algebraic structure F5 could exploit? | **No** — the action is purely combinatorial; there is no hidden polynomial extension or low-`d_reg` regime. |
| Could algebraic PEP attacks (Saeed-Taha / Beullens) scale to `n = 4λ`? | **Not with current techniques** — empirical horizon `n ≈ 25–30` for raw GB; HGOE balanced `n ≥ 320`. Worth tracking as the field advances. |
| Is there a parameter-level PoSSo concern? | **Yes — algebraic folding of QC structure**, fenced by `n/b ≥ λ` at the balanced tier. This is the *binding* constraint — any improvement on folded-PEP GB attacks shrinks Orbcrypt's margin first. |
| Is the tensor branch a future concern? | **Yes** — ATFE / MinRank attacks are actively progressing; instantiating TI at `ε < 1` should incorporate the latest complexity estimates at parameter-selection time. |

The verdict is conditional on: (i) HSP on `S_n` remaining hard
classically and quantumly, (ii) CFI WL-resistance constructions
remaining immune to fixed-degree algebraic invariants, (iii) the
`n/b ≥ λ` parameter being enforced, and (iv) the TI branch not
being instantiated at concrete `ε < 1` without an updated parameter
review against ATFE / MinRank complexity estimates. Any change to
one of (i)–(iv) should trigger a refresh of this subsection.

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

#### PoSSo / Gröbner-basis methods (cited in §4.2)

8. **Faugère, J.-C.** (1999). A new efficient algorithm for computing
   Gröbner bases (F4). *Journal of Pure and Applied Algebra*,
   139(1–3), pp. 61–88.

9. **Faugère, J.-C.** (2002). A new efficient algorithm for computing
   Gröbner bases without reduction to zero (F5). *Proceedings of
   ISSAC 2002*, ACM, pp. 75–83.

10. **Courtois, N., Klimov, A., Patarin, J., & Shamir, A.** (2000).
    Efficient algorithms for solving overdefined systems of
    multivariate polynomial equations (XL). *EUROCRYPT 2000*,
    LNCS 1807, pp. 392–407.

11. **Mohamed, M.S.E., Mohamed, W.S.A.E., Ding, J., & Buchmann, J.**
    (2008). MutantXL: Solving multivariate polynomial equations for
    cryptanalytic applications. *Symbolic Computation and
    Cryptography (SCC) 2008*.

12. **Bettale, L., Faugère, J.-C., & Perret, L.** (2009). Hybrid
    approach for solving multivariate systems over finite fields.
    *Journal of Mathematical Cryptology*, 3(3), pp. 177–197.

13. **Bardet, M., Faugère, J.-C., & Salvy, B.** (2004). On the
    complexity of Gröbner basis computation of semi-regular
    overdetermined algebraic equations. *International Conference on
    Polynomial System Solving*, INRIA Research Report.

#### Multivariate cryptanalysis case studies (cited in §4.2.1)

14. **Patarin, J.** (1996). Hidden Field Equations (HFE) and
    Isomorphisms of Polynomials (IP): Two new families of asymmetric
    algorithms. *EUROCRYPT 1996*, LNCS 1070, pp. 33–48.

15. **Faugère, J.-C. & Joux, A.** (2003). Algebraic cryptanalysis of
    Hidden Field Equation (HFE) cryptosystems using Gröbner bases.
    *CRYPTO 2003*, LNCS 2729, pp. 44–60.

16. **Dubois, V., Fouque, P.-A., Shamir, A., & Stern, J.** (2007).
    Practical cryptanalysis of SFLASH. *CRYPTO 2007*, LNCS 4622,
    pp. 1–12.

#### Symmetry-aware Gröbner basis (cited in §4.2.3 Barrier 2)

17. **Faugère, J.-C. & Rahmany, S.** (2009). Solving systems of
    polynomial equations with symmetries using SAGBI–Gröbner bases.
    *Proceedings of ISSAC 2009*, ACM, pp. 151–158.

18. **Faugère, J.-C. & Svartz, J.** (2013). Gröbner bases of ideals
    invariant under a commutative group. *Proceedings of ISSAC 2013*,
    ACM, pp. 347–354.

#### MinRank attacks (cited in §4.2.1 and §4.2.4(c))

19. **Verbel, J., Baena, J., Cabarcas, D., Perlner, R., &
    Smith-Tone, D.** (2019). On the complexity of "superdetermined"
    Minrank instances. *PQCrypto 2019*, LNCS 11505, pp. 167–186.

20. **Bardet, M., Bros, M., Cabarcas, D., Gaborit, P., Perlner, R.,
    Smith-Tone, D., Tillich, J.-P., & Verbel, J.** (2020).
    Improvements of algebraic attacks for solving the rank decoding
    and MinRank problems. *ASIACRYPT 2020*, LNCS 12491,
    pp. 507–536.

#### Permutation Equivalence cryptanalysis (cited in §4.2.4(a))

21. **Sendrier, N.** (2000). Finding the permutation between
    equivalent linear codes: The Support Splitting Algorithm.
    *IEEE Transactions on Information Theory*, 46(4), pp. 1193–1203.

22. **Saeed-Taha, M.A.** (2017). *Algebraic Approach for Code
    Equivalence*. PhD Thesis, Royal Holloway, University of London
    (and follow-on conference work).

23. **Beullens, W.** (2020). Not Enough LESS: An Improved Algorithm
    for Solving Code Equivalence Problems over F_q. *Selected Areas
    in Cryptography (SAC) 2020*, LNCS 12804, pp. 387–403.

#### Tensor / ATFE cryptanalysis (cited in §4.2.4(c))

24. **Tang, G., Duong, D.H., Joux, A., Plantard, T., Qiao, Y., &
    Susilo, W.** (2022). Practical Post-Quantum Signature Schemes
    from Isomorphism Problems of Trilinear Forms. *EUROCRYPT 2022*,
    LNCS 13277, pp. 582–612.

#### Weisfeiler–Leman ↔ proof complexity (cited in §4.2.3 Barrier 3)

25. **Otto, M.** (1997). *Bounded Variable Logics and Counting: A
    Study in Finite Models*. Lecture Notes in Logic 9, Springer.

26. **Atserias, A. & Maneva, E.** (2013). Sherali–Adams Relaxations
    and Indistinguishability in Counting Logics. *SIAM Journal on
    Computing*, 42(1), pp. 112–137.

27. **Berkholz, C. & Grohe, M.** (2017). Linear Diophantine Equations,
    Group CSPs, and Graph Isomorphism. *SODA 2017*, ACM/SIAM,
    pp. 327–339.

28. **Grohe, M.** (2017). *Descriptive Complexity, Canonisation, and
    Definable Graph Structure Theory*. Lecture Notes in Logic 47,
    Cambridge University Press. §11–§13 on the polynomial-invariant
    / WL correspondence.

#### Quasi-cyclic code attacks (cited in §4.2.4(b))

29. **Sendrier, N. & Vasseur, V.** (2019). On the existence of weak
    keys for QC-MDPC decoding. *PQCrypto 2019*, LNCS 11505,
    pp. 459–479.

30. **Drucker, N., Gueron, S., & Kostic, D.** (2020). On constant-time
    QC-MDPC decoding with negligible failure rate. *Code-Based
    Cryptography Workshop (CBCrypto) 2020*, LNCS 12087, pp. 50–79.

#### Hidden Subgroup Problem on S_n (cited in §4.2.3 Barrier 1)

31. **Hallgren, S., Russell, A., & Ta-Shma, A.** (2003). The Hidden
    Subgroup Problem and Quantum Computation Using Group
    Representations. *SIAM Journal on Computing*, 32(4),
    pp. 916–934.

32. **Moore, C., Russell, A., & Schulman, L.J.** (2008). The Symmetric
    Group Defies Strong Fourier Sampling. *SIAM Journal on
    Computing*, 37(6), pp. 1842–1864.
