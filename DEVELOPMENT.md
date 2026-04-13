# Orbcrypt — Master Development Document

## Permutation-Orbit Encryption with Formal Verification in Lean 4

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Background and Design Principles](#2-background-and-design-principles)
3. [Mathematical Preliminaries](#3-mathematical-preliminaries)
4. [Abstract Orbit Encryption (AOE)](#4-abstract-orbit-encryption-aoe)
5. [The Orbit Indistinguishability Assumption (OIA)](#5-the-orbit-indistinguishability-assumption-oia)
6. [The Orbcrypt Construction](#6-the-orbcrypt-construction)
7. [Addressing the Counterexample](#7-addressing-the-counterexample)
8. [Security Analysis](#8-security-analysis)
9. [Lean 4 Formalization Plan](#9-lean-4-formalization-plan)
10. [Open Problems and Future Directions](#10-open-problems-and-future-directions)

---

## 1. Executive Summary

Orbcrypt is a symmetric-key encryption scheme built on a novel principle:

> **Security arises not from hiding data, but from hiding the equivalence relation
> that makes data meaningful.**

A message is encoded as the *identity* of an orbit under a secret permutation
group G ≤ S\_n. A ciphertext is a uniformly random element of that orbit.
Without knowledge of G, an adversary cannot determine which orbit a ciphertext
belongs to — the structured message space "collapses" into an indistinguishable
distribution. With knowledge of G, the key holder computes a canonical
representative and recovers the message in polynomial time.

We define a concrete hardness assumption — the **Orbit Indistinguishability
Assumption (OIA)** — and show that it reduces to the **Graph Isomorphism (GI)
problem** on provably hard instance families (Cai–Fürer–Immerman graphs). We
further present an alternative reduction to the **Permutation Code Equivalence
problem**. We prove that OIA implies IND-CPA security, and we formalize the
critical vulnerability exposed by invariant attacks (from COUNTEREXAMPLE.md)
as a theorem that precisely characterizes when the scheme fails.

The entire algebraic framework — correctness, the invariant attack theorem, and
the conditional security reduction (OIA ⟹ IND-CPA) — will be formalized in
**Lean 4** using Mathlib's group action library.

---

## 2. Background and Design Principles

### 2.1 The Core Idea (from POE.md)

The Permutation-Orbit Encryption concept rests on three pillars:

| Component       | Role                                           |
|-----------------|------------------------------------------------|
| Space X         | The universe of possible ciphertexts           |
| Hidden group G  | Defines the equivalence relation (orbits)      |
| Message m       | Identified with a specific orbit G · x\_m      |
| Ciphertext c    | A uniformly random element of the orbit G · x\_m |

**Encryption** samples a random element of the orbit corresponding to message m.
**Decryption** identifies which orbit the ciphertext belongs to, using the secret
group G to compute a canonical representative.

The fundamental insight is that the *partition of X into orbits* is the
information-bearing structure. The group G defines this partition. Without G,
the partition is invisible.

### 2.2 The Invariant Attack: A Critical Lesson (from COUNTEREXAMPLE.md)

The counterexample demonstrates that large orbits and perfect mixing are
**necessary but not sufficient** for security. The failure mode is precise:

> If there exists an efficiently computable function f : X → Y that is
> G-invariant (f(g · x) = f(x) for all g ∈ G) and that separates message
> orbits (f(x\_m₀) ≠ f(x\_m₁)), then the scheme is completely broken.

**Example 1 (Bitstrings).** G = S\_n acting on {0,1}^n. Orbits are determined
by Hamming weight. The function f(x) = wt(x) is an efficiently computable
separating invariant. Result: total break.

**Example 2 (Graphs).** G = S\_n acting on graphs by vertex relabeling. Even
though graph isomorphism may be hard, the triangle-count function separates
graphs with different numbers of triangles. Result: total break whenever the
message graphs differ in *any* efficiently computable graph statistic.

**The deeper lesson:** The space only truly "collapses" if **every efficiently
computable invariant that survives the group action is also identical across
message orbits**. Security is not about hiding symmetry; it is about ensuring
that *no observable shadow of orbit identity leaks*.

### 2.3 Design Principles

From this analysis we extract four binding design principles:

1. **No Separating Invariants.** Orbit representatives must be chosen so that
   no polynomial-time computable G-invariant function distinguishes them. This
   is the central constraint.

2. **Hardness Beyond Mixing.** Security requires computational
   indistinguishability of orbit samples, not merely large orbit size or
   statistical mixing properties.

3. **Trapdoor Canonicalization.** The secret key must enable efficient orbit
   identification (canonical image computation), while without it,
   canonicalization is intractable. This asymmetry is the trapdoor.

4. **Reduction to a Known Hard Problem.** The scheme's security assumption
   must be grounded in a well-studied computational problem with decades of
   cryptanalytic evidence.

---

## 3. Mathematical Preliminaries

### 3.1 Group Actions

**Definition (Group Action).** A left action of a group G on a set X is a map
· : G × X → X satisfying:
- (Identity) e · x = x for all x ∈ X
- (Compatibility) (gh) · x = g · (h · x) for all g, h ∈ G and x ∈ X

**Definition (Orbit).** The orbit of x ∈ X under G is
G · x = { g · x : g ∈ G }.

**Definition (Stabilizer).** The stabilizer of x ∈ X in G is
Stab\_G(x) = { g ∈ G : g · x = x }.

**Theorem (Orbit-Stabilizer).** |G · x| · |Stab\_G(x)| = |G|.

**Theorem (Orbit Partition).** The orbits of G on X form a partition of X:
every element belongs to exactly one orbit, and two orbits are either identical
or disjoint.

**Definition (G-Invariant Function).** A function f : X → Y is G-invariant if
f(g · x) = f(x) for all g ∈ G and all x ∈ X. Equivalently, f is constant on
each orbit.

**Definition (Canonical Form).** A canonical form for the action of G on X is a
function can\_G : X → X satisfying:
- can\_G(x) ∈ G · x (the canonical form lies in the same orbit)
- can\_G(x) = can\_G(y) if and only if G · x = G · y (it uniquely identifies orbits)

### 3.2 Permutation Groups

The symmetric group S\_n acts on {0,1}^n by coordinate permutation:
(σ · x)\_i = x\_{σ⁻¹(i)}.

A permutation group G ≤ S\_n is specified by a generating set
{ σ₁, …, σ\_k } with k = O(n). The following computational tasks are
**polynomial in n** when G is given by generators:

| Task                  | Algorithm               | Complexity           |
|-----------------------|-------------------------|----------------------|
| Membership testing    | Schreier–Sims           | O(n² log \|G\|)      |
| Uniform sampling      | Random Schreier product | O(n log \|G\|)       |
| Order computation     | Schreier–Sims           | O(n² log² \|G\|)     |
| Canonical image       | Partition backtracking  | O(n^c) (practical)   |

**Canonical image computation** (Leon's partition backtracking algorithm):
given G by generators and x ∈ {0,1}^n, compute the lexicographically minimal
element of G · x. This is the key subroutine enabling efficient decryption.

### 3.3 Reference Hard Problems

**Graph Isomorphism (GI).** Given two graphs Γ₁, Γ₂ on n vertices, determine
if there exists σ ∈ S\_n with σ(Γ₁) = Γ₂.
- Best known classical: 2^{O(√(n log n))} (Babai, 2015)
- Not known to be NP-complete; not known to be in P
- Hard instance families: strongly regular graphs, CFI constructions

**Permutation Code Equivalence (CE).** Given two linear codes C₁, C₂ ⊆ F\_q^n
(by generator matrices), determine if ∃ σ ∈ S\_n with σ(C₁) = C₂.
- Proved at least as hard as GI (GI ≤\_p CE)
- Believed strictly harder for certain code families
- Basis of McEliece-adjacent cryptographic assumptions

**Hidden Subgroup Problem (HSP) for S\_n.** Given oracle access to a function
f : S\_n → Y constant on left cosets of an unknown H ≤ S\_n, find H.
- Hard even for quantum computers (key barrier for quantum GI algorithms)
- Believed intractable classically with polynomial samples

---

## 4. Abstract Orbit Encryption (AOE)

### 4.1 Scheme Syntax

An Abstract Orbit Encryption scheme is a triple (Setup, Enc, Dec):

**Setup(1^λ) → (sk, params)**
- sk = (G, can\_G) where G ≤ S\_n is a permutation group (by generators) and
  can\_G is its canonical image function
- params = (n, M, {x\_m}\_{m ∈ M}) where n is the dimension, M is the message
  space, and {x\_m} are orbit representatives satisfying:
  - x\_m ∈ {0,1}^n for each m ∈ M
  - G · x\_{m₁} ∩ G · x\_{m₂} = ∅ for m₁ ≠ m₂ (distinct orbits)

**Enc(sk, m) → c**
1. Sample g ← G uniformly at random (via Schreier–Sims)
2. Output c = g · x\_m

**Dec(sk, c) → m**
1. Compute x\* = can\_G(c) (lexicographic minimum of G · c)
2. Output the unique m ∈ M with can\_G(x\_m) = x\*

This is a **symmetric-key** scheme: both encryption and decryption require
knowledge of G.

### 4.2 Correctness

**Theorem (Correctness).** For all (sk, params) produced by Setup and all
m ∈ M:

Pr[ Dec(sk, Enc(sk, m)) = m ] = 1

**Proof.** Let c = Enc(sk, m) = g · x\_m for some g ∈ G. Then c ∈ G · x\_m,
so G · c = G · x\_m (orbits are equivalence classes). Therefore
can\_G(c) = can\_G(x\_m). Since the x\_m lie in pairwise disjoint orbits,
can\_G(x\_m) uniquely determines m. ∎

### 4.3 IND-CPA Security

**Definition (IND-CPA).** The AOE scheme is IND-CPA secure if for all PPT
adversaries A:

Adv^{IND-CPA}\_A(λ) = |Pr[IND-CPA\_A(λ) = 1] − 1/2| ≤ negl(λ)

where the IND-CPA game proceeds as:
1. (sk, params) ← Setup(1^λ)
2. A receives params but **not** sk
3. A may adaptively query an encryption oracle Enc(sk, ·)
4. A selects challenge messages m₀, m₁ ∈ M
5. Challenger samples b ← {0,1} and sends c\* = Enc(sk, m\_b) to A
6. A may continue querying Enc(sk, ·)
7. A outputs b′; A wins if b′ = b

Note: the adversary sees the orbit representatives {x\_m} (they are public
parameters) but does not know G.

### 4.4 The Invariant Attack Theorem

This theorem formalizes the exact failure mode identified in COUNTEREXAMPLE.md.

**Theorem (Invariant Attack).** Let (Setup, Enc, Dec) be an AOE scheme. If
there exists a deterministic polynomial-time function f : {0,1}^n → Y such
that:
1. f is G-invariant: f(g · x) = f(x) for all g ∈ G, x ∈ {0,1}^n
2. f separates two message orbits: f(x\_{m₀}) ≠ f(x\_{m₁}) for some m₀ ≠ m₁

then there exists a PPT adversary A with Adv^{IND-CPA}\_A(λ) = 1/2 (maximum
possible advantage, i.e., a complete break).

**Proof.** Construct adversary A:
1. A receives params = (n, M, {x\_m})
2. A finds m₀, m₁ with f(x\_{m₀}) ≠ f(x\_{m₁}) (by evaluating f on each x\_m)
3. A submits (m₀, m₁) as the challenge pair
4. A receives challenge ciphertext c\*
5. A computes f(c\*)
6. Since c\* = g · x\_{m\_b} for some g ∈ G, and f is G-invariant:
   f(c\*) = f(g · x\_{m\_b}) = f(x\_{m\_b})
7. If f(c\*) = f(x\_{m₀}), A outputs 0; otherwise A outputs 1
8. A is correct with probability 1, so Adv = 1/2. ∎

**Contrapositive (Security Requirement).** For AOE to be IND-CPA secure, the
following must hold for every pair m₀ ≠ m₁ ∈ M:

> For all PPT-computable G-invariant functions f: f(x\_{m₀}) = f(x\_{m₁}).

In other words: **no efficiently computable invariant separates message orbits.**

---

## 5. The Orbit Indistinguishability Assumption (OIA)

### 5.1 Informal Statement

The OIA asserts that random samples from distinct orbits of a properly chosen
permutation group are computationally indistinguishable to any efficient
adversary who does not know the group.

There are two natural flavors:

- **GI-OIA (public group):** G = S\_n acts on graph adjacency vectors. Orbits
  are isomorphism classes. Distinguishing orbits IS the Graph Isomorphism
  problem. The group is public; the hardness is intrinsic to the orbit
  structure.

- **HG-OIA (hidden group):** G < S\_n is a secret proper subgroup. Orbits are
  finer than isomorphism classes. Distinguishing orbits requires determining
  the hidden group — a problem at least as hard as GI and related to the
  Hidden Subgroup Problem on S\_n.

We define GI-OIA as the **primary concrete candidate** because it admits a
clean, direct reduction to Graph Isomorphism. We then use HG-OIA for the
**practical construction**, since it permits efficient decryption.

### 5.2 Formal Definition

**Definition (OIA, General Form).** Let Π = {Setup\_λ}\_λ be a family of setup
algorithms producing (sk\_λ, params\_λ) where sk\_λ = (G\_λ, can\_{G\_λ}) and
params\_λ = (n\_λ, M\_λ, {x\_m}). The OIA for Π states that for all PPT
adversaries A and all distinct m₀, m₁ ∈ M\_λ:

```
Adv^{OIA}_A(λ) = |Pr[A(params, g · x_{m₀}) = 1] − Pr[A(params, g · x_{m₁}) = 1]|
               ≤ negl(λ)
```

where g ← G\_λ uniformly and the probability is over g and A's randomness.

The adversary receives the public parameters (including all orbit
representatives) but **not** the secret key (G and can\_G).

### 5.3 Concrete Candidate A: Reduction to Graph Isomorphism (GI-OIA)

This instantiation reduces OIA directly and tightly to the Graph Isomorphism
problem on a specific hard instance family.

#### 5.3.1 The Cai–Fürer–Immerman (CFI) Construction

Given a connected base graph H on n₀ vertices with edge set E(H), the CFI
construction produces a graph CFI(H, t) for each twist vector t ∈ {0,1}^{|E(H)|}
as follows:

1. **Vertex gadgets.** Replace each vertex v of H (with degree d\_v) by a set
   of 2^{d\_v − 1} "fiber" vertices, representing even-parity selections of
   the edges incident to v.

2. **Edge gadgets.** For each edge {u,v} ∈ E(H), connect fiber vertices of u
   to fiber vertices of v according to a matching determined by the twist bit
   t\_{uv}. If t\_{uv} = 0, use the "straight" matching; if t\_{uv} = 1, use
   the "crossed" matching.

**Key properties of CFI graphs:**

| Property | Statement |
|----------|-----------|
| Isomorphism criterion | CFI(H, t₁) ≅ CFI(H, t₂) **iff** ∑t₁ ≡ ∑t₂ (mod 2) |
| WL resistance | For all fixed k, k-dim Weisfeiler–Leman cannot distinguish CFI(H, t₁) from CFI(H, t₂) when ∑t₁ ≢ ∑t₂, provided H has no vertex of degree ≤ k |
| GI-completeness | GI on CFI instances is polynomial-time equivalent to general GI |
| Size | CFI(H, t) has O(n₀ · 2^{d\_max}) vertices where d\_max = max degree of H |

The WL resistance is the critical property: it means that **all standard
polynomial-time graph invariants** (degree sequence, spectrum, k-cycle counts,
color refinement, etc.) fail to distinguish CFI pairs with different parities.
This directly addresses the counterexample from COUNTEREXAMPLE.md.

#### 5.3.2 GI-OIA Construction

**Setup\_{GI}(1^λ):**
1. Choose n₀ = n₀(λ) and sample a random connected 3-regular base graph
   H on n₀ vertices.
2. Sample t₀ ← {t ∈ {0,1}^{|E(H)|} : ∑t ≡ 0 mod 2} (even parity).
3. Sample t₁ ← {t ∈ {0,1}^{|E(H)|} : ∑t ≡ 1 mod 2} (odd parity).
4. Construct Γ₀ = CFI(H, t₀) and Γ₁ = CFI(H, t₁) on n vertices.
5. Let N = n(n−1)/2. Encode Γ₀, Γ₁ as adjacency vectors x₀, x₁ ∈ {0,1}^N.
6. G = S\_n acting on {0,1}^N via the induced edge-permutation action:
   (σ · x)\_{ij} = x\_{σ⁻¹(i), σ⁻¹(j)}.
7. params = (N, {0,1}, {x₀, x₁}); sk = (G, can\_G) = (S\_n, canonical labeling).

**Note on the secret key:** In this variant, G = S\_n is public. The "secret"
enabling efficient decryption is the structural knowledge of (H, t₀, t₁) —
the base graph and twist vectors from which the CFI graphs were built. This
structural knowledge enables the key holder to perform isomorphism testing
against Γ₀ and Γ₁ far more efficiently than a general-purpose GI solver, by
"unrolling" the CFI gadgets using H.

#### 5.3.3 Reduction Theorem

**Theorem (GI-OIA reduces to GI).** If Graph Isomorphism is hard on CFI
instances derived from random 3-regular base graphs, then GI-OIA holds.

**Proof.** Let A be a PPT adversary with non-negligible advantage against
GI-OIA. Then A, on input a random relabeling of either Γ₀ or Γ₁, determines
which one it is isomorphic to. But a random relabeling σ(Γ\_b) for
σ ← S\_n is a uniformly random graph isomorphic to Γ\_b. So A solves the
following GI decision problem: given a graph Γ promised to be isomorphic to
exactly one of Γ₀, Γ₁ (which are non-isomorphic), determine which one.

This is exactly the Graph Isomorphism search problem on CFI instances (given
two non-isomorphic graphs and a third promised isomorphic to one, identify
which). By the GI-completeness of CFI instances, this is as hard as general
GI. Contradiction. ∎

**Why CFI defeats the counterexample attacks:**

| Attack from COUNTEREXAMPLE.md | Why it fails on CFI |
|-------------------------------|---------------------|
| Hamming weight of adjacency vector | Γ₀, Γ₁ have the same number of edges (CFI preserves edge count for 3-regular H) |
| Degree sequence | Both CFI graphs are regular with the same degree |
| Triangle count / k-cycle count | Identical for CFI pairs from the same H (both are local statistics, and CFI gadgets are locally identical) |
| Spectral invariants (eigenvalues) | CFI pairs from 3-regular H share all eigenvalues of the adjacency matrix |
| k-WL color refinement | Provably fails for all fixed k when H has min degree > k |

### 5.4 Concrete Candidate B: Code Equivalence (CE-OIA)

This candidate provides a **hidden-group** variant with strictly stronger
security guarantees and efficient decryption.

#### 5.4.1 Construction

**Setup\_{CE}(1^λ):**
1. Choose code parameters n = n(λ), k = k(λ), q = 2.
2. Generate a structured binary linear [n, k]-code C₀ with the property that
   |PAut(C₀)| ≥ 2^λ. Candidates:
   - **Quasi-cyclic codes:** codes invariant under cyclic shifts of blocks,
     guaranteeing a cyclic subgroup of prescribed order in PAut(C₀).
   - **Generalized Reed–Muller codes:** well-understood automorphism groups of
     exponential size.
   - **Random self-dual codes:** self-dual codes over F\_2 tend to have
     non-trivial automorphism groups and have been studied extensively.
3. Compute G = PAut(C₀) = {σ ∈ S\_n : σ(C₀) = C₀}, given by generators,
   using standard algorithms for code automorphism computation.
4. Choose orbit representatives x₀, x₁ ∈ {0,1}^n such that:
   - wt(x₀) = wt(x₁) (equal Hamming weight — defeats weight-based invariants)
   - G · x₀ ≠ G · x₁ (distinct G-orbits)
   - x₁ ∈ S\_n · x₀ (same S\_n-orbit, i.e., same weight — see Section 7)
5. params = (n, {0,1}, {x₀, x₁}); sk = (G, can\_G).

#### 5.4.2 Security Evidence

The CE-OIA asserts that for the construction above, no PPT adversary
distinguishes uniform samples from G · x₀ versus G · x₁ with non-negligible
advantage.

**Evidence for hardness:**

1. **The group G is hidden.** Unlike GI-OIA where G = S\_n is public, here the
   adversary does not know G. To determine G, they would need to solve a
   variant of the Hidden Subgroup Problem for S\_n, which is believed
   intractable.

2. **Recovering G solves code equivalence.** If an adversary could recover the
   generators of G = PAut(C₀) from orbit samples, they could test equivalence
   of any code C₁ to C₀ by checking whether the permutation taking C₀ to C₁
   lies in the recovered group. Since CE is at least GI-hard, this provides
   evidence that recovering G is hard.

3. **Immunity to GI breakthroughs.** Even if a polynomial-time GI algorithm
   were discovered, CE-OIA would not automatically fall. The hidden group
   adds an independent layer of hardness beyond graph isomorphism.

#### 5.4.3 GI-OIA vs CE-OIA Comparison

| Property | GI-OIA | CE-OIA |
|----------|--------|--------|
| Reduction | Tight reduction to GI | Evidence from CE + HSP |
| Group | G = S\_n (public) | G = PAut(C) (secret) |
| Decryption cost | Requires GI solver | Polynomial (partition backtracking) |
| Post-GI security | Falls if GI is solved | Survives GI breakthroughs |
| Practical use | Theoretical benchmark | Recommended for implementation |

**Recommendation:** Use CE-OIA for practical implementations and use GI-OIA
as the theoretical foundation establishing that orbit indistinguishability is
at least GI-hard in the graph setting.

---

## 6. The Orbcrypt Construction

We present the full practical construction based on CE-OIA (hidden-group
variant), which we call **HGOE** (Hidden-Group Orbit Encryption).

### 6.1 Parameters

| Parameter | Symbol | Role | Recommended range |
|-----------|--------|------|-------------------|
| Security parameter | λ | Controls all sizes | 128 or 256 |
| String length | n | Dimension of X = {0,1}^n | 1024–4096 |
| Code dimension | k | Dimension of secret code C₀ | n/4 to n/2 |
| Group order (log) | log₂\|G\| | Entropy of randomization | ≥ λ |
| Hamming weight | w | Weight of all orbit reps | n/3 to 2n/3 |
| Message space | \|M\| | Number of messages | ≥ 2^λ |

The requirement |G| ≥ 2^λ ensures that each ciphertext carries at least λ bits
of randomness from the group sampling. The requirement |M| ≥ 2^λ ensures a
message space large enough for practical use.

The number of distinct G-orbits of weight w in {0,1}^n is approximately
C(n, w) / |G| (by Burnside's lemma heuristic). Since C(n, n/2) ≈ 2^n / √n,
this count vastly exceeds 2^λ for the recommended parameter ranges, providing
an abundant supply of orbit representatives.

### 6.2 Full Specification

**HGOE.Setup(1^λ):**
1. Select n, k per the parameter table.
2. Generate a binary linear [n, k]-code C₀ with |PAut(C₀)| ≥ 2^λ:
   - Use a quasi-cyclic construction with block length b, giving a cyclic
     factor of order b in each of n/b blocks, so |PAut(C₀)| ≥ b^{n/b}.
   - Verify the group order via Schreier–Sims.
3. Compute G = PAut(C₀) and store its strong generating set (SGS).
4. Fix target Hamming weight w = ⌊n/2⌋.
5. Select |M| orbit representatives {x\_m}\_{m ∈ M} ⊂ {0,1}^n by:
   a. Sample a random x ∈ {0,1}^n with wt(x) = w.
   b. Compute can\_G(x) to obtain the canonical representative.
   c. If this canonical representative is new (not yet seen), add x\_m := can\_G(x)
      to the representative set.
   d. Repeat until |M| representatives are collected.
6. **Secret key:** sk = (SGS for G, canonicalization oracle can\_G)
7. **Public parameters:** params = (n, w, M, {x\_m}\_{m ∈ M})

**HGOE.Enc(sk, m):**
1. Sample g ← G uniformly using the SGS (Product Replacement Algorithm or
   random Schreier walks).
2. Compute c = g · x\_m (permute coordinates of x\_m by g).
3. Output c ∈ {0,1}^n.

**HGOE.Dec(sk, c):**
1. Compute x\* = can\_G(c) via partition backtracking (Leon's algorithm).
2. Look up x\* in the precomputed table {can\_G(x\_m) : m ∈ M}.
   (Since we stored x\_m = can\_G(x\_m) in step 5 of Setup, this is a direct
   table lookup.)
3. Output the matching m ∈ M.

### 6.3 Correctness (Instantiated)

By Theorem 4.2 (Correctness of AOE), HGOE is correct: Dec(sk, Enc(sk, m)) = m
with probability 1.

The proof is purely algebraic: g · x\_m ∈ G · x\_m, so can\_G(g · x\_m) = can\_G(x\_m),
and the table lookup succeeds because representatives were stored in canonical
form.

### 6.4 Efficiency

| Operation | Cost | Justification |
|-----------|------|---------------|
| Key generation | O(n² log² \|G\|) + O(\|M\| · n^c) | Schreier–Sims + orbit rep sampling |
| Encryption | O(n log \|G\|) | One group element sample + one permutation application |
| Decryption | O(n^c) | One canonical image computation |
| Ciphertext size | n bits | One element of {0,1}^n |
| Key size | O(n² log \|G\|) bits | Strong generating set storage |

Here c is a small constant (typically 3–5 in practice for partition
backtracking on groups arising from code automorphisms).

---

## 7. Addressing the Counterexample

The counterexample from COUNTEREXAMPLE.md identified a precise failure
condition: the existence of an efficiently computable separating G-invariant.
This section explains how the Orbcrypt construction systematically defeats
every attack vector identified in that document.

### 7.1 Hamming Weight Attack (Counterexample §1–4)

**Attack:** f(x) = wt(x) is S\_n-invariant and hence G-invariant for any
G ≤ S\_n. If wt(x\_{m₀}) ≠ wt(x\_{m₁}), the scheme breaks.

**Defense:** All orbit representatives are chosen with **identical Hamming
weight** w = ⌊n/2⌋ (Section 6.2, step 4). Therefore wt(x\_{m₀}) = wt(x\_{m₁})
for all m₀, m₁, and the Hamming weight function is non-separating.

### 7.2 Graph Statistic Attacks (Counterexample §6)

**Attack:** When X consists of graph adjacency matrices, functions like
triangle count, degree sequence, or spectral invariants may separate orbits.

**Defense (GI-OIA):** CFI graph pairs from the same base graph H share **all**
k-dimensional Weisfeiler–Leman invariants for any fixed k. This subsumes:
- Degree sequence (1-WL)
- Triangle and cycle counts (3-WL)
- Eigenvalue spectra (subsumed by 2-WL for regular graphs)

No known polynomial-time graph invariant separates CFI pairs from 3-regular
base graphs.

**Defense (CE-OIA / HGOE):** The hidden-group construction does not use graph
adjacency matrices at all — it operates on raw bitstrings in {0,1}^n. The only
"universal" S\_n-invariant on bitstrings is the Hamming weight (and functions
derived from it, such as the multiset of k-substring weights, which are also
weight-determined for same-weight strings under full S\_n action). Since all
representatives share the same weight, these invariants are non-separating.

### 7.3 Partial Invariant Attacks (Counterexample §7–8)

**Attack principle:** Any efficiently computable G-invariant that takes
different values on x\_{m₀} and x\_{m₁} breaks the scheme. The attacker does
not need to recover the full orbit — one "crack" suffices.

**Defense:** The OIA is precisely the assumption that no such crack exists.
For the GI-OIA variant, this is established by reduction to GI on hard
instances. For the CE-OIA variant, the additional hidden-group layer means
the adversary cannot even determine *which functions are G-invariant* without
recovering G, which requires solving the HSP on S\_n.

More concretely: a function f is G-invariant iff f(σ · x) = f(x) for all
σ ∈ G. To check this, the adversary would need to know G. To construct such an
f, the adversary would need structural information about G (e.g., which
coordinate subsets are invariant under G). The code equivalence assumption
implies that this structural information is computationally inaccessible.

### 7.4 The True Collapse Condition (Counterexample §9–10)

The counterexample concludes that true "collapse" requires:

> For all PPT f: the distributions {f(g · x\_{m₀}) : g ← G} and
> {f(g · x\_{m₁}) : g ← G} are computationally indistinguishable.

This is **exactly** the OIA (Section 5.2). Our construction satisfies this
by assumption, with the assumption grounded in GI-hardness (GI-OIA) or
code-equivalence + HSP hardness (CE-OIA).

---

## 8. Security Analysis

### 8.1 Main Theorem: OIA Implies IND-CPA (Single Query)

We first prove security in a restricted model where the adversary makes no
encryption oracle queries (IND-1-CPA, also called one-shot indistinguishability).
This captures the core hardness and maps directly onto the OIA.

**Theorem (OIA ⟹ IND-1-CPA).** If the OIA holds for the setup family Π, then
the AOE scheme instantiated with Π is IND-1-CPA secure.

**Proof.** The IND-1-CPA game (no oracle queries) proceeds as:
1. (sk, params) ← Setup(1^λ); A receives params
2. A outputs (m₀, m₁)
3. b ← {0,1}; c\* = g · x\_{m\_b} for g ← G; A receives c\*
4. A outputs b′

The adversary's advantage is:

```
Adv^{1-CPA}_A(λ) = |Pr[A(params, g · x_{m₀}) = 1] − Pr[A(params, g · x_{m₁}) = 1]| / 2
```

which is exactly (1/2) · Adv^{OIA}\_A(λ) ≤ negl(λ) by the OIA. ∎

### 8.2 Multi-Query Security (Full IND-CPA)

In the full IND-CPA game, the adversary has adaptive access to an encryption
oracle Enc(sk, ·). Each query on message m returns a fresh random element of
G · x\_m. This potentially leaks information about G.

**Threat model:** Given polynomially many samples from orbits G · x\_{m\_i} for
adversary-chosen m\_i, can the adversary recover enough of G's structure to
break indistinguishability?

**Analysis.** Consider what an oracle query Enc(sk, m) reveals:
- The query returns c = g · x\_m for random g ← G
- Since x\_m is public, the adversary learns one element of G · x\_m
- From two samples c₁ = g₁ · x\_m and c₂ = g₂ · x\_m of the same orbit, the
  adversary knows that g₁ g₂⁻¹ maps c₂ to c₁
- However, recovering this permutation from (c₁, c₂) requires solving the
  **string automorphism problem**: given two binary strings of the same weight
  related by an unknown permutation, find the permutation
- For binary strings of weight w, the number of permutations mapping c₂ to c₁
  is w! · (n−w)! / |Stab\_G(x\_m) ∩ (coset)|, which is exponentially large
- Extracting the specific g₁ g₂⁻¹ ∈ G from this exponential set requires
  knowledge of G itself

**Theorem (Multi-query security, informal).** Under the OIA and the assumption
that the Hidden Subgroup Problem on S\_n is hard with polynomially many coset
samples, the HGOE scheme is IND-CPA secure.

**Proof sketch.** We argue by hybrid. Consider Q oracle queries. Each query
reveals a random element of some G-orbit. The adversary's total view is:

```
(params, c₁, ..., c_Q, c*)
```

where each c\_i ∈ G · x\_{m\_i} and c\* ∈ G · x\_{m\_b}. We must show that
replacing c\* ∈ G · x\_{m₀} with c\* ∈ G · x\_{m₁} is undetectable.

The oracle queries provide samples from known orbits. To exploit these, the
adversary would need to extract group elements from orbit samples (to learn G),
which reduces to the HSP on S\_n with polynomial samples. Under the HSP
hardness assumption, the oracle queries provide negligible additional advantage
beyond the single-query setting. ∎

### 8.3 Strengthening: Noisy Variant

For an extra margin of security against multi-query attacks, we define a noisy
variant that prevents exact orbit sample recovery:

**HGOE-Noisy.Enc(sk, m):**
1. Sample g ← G uniformly
2. Compute y = g · x\_m
3. Sample noise vector e ← Ber(η)^n (each bit flipped independently with
   probability η, where η is a small constant)
4. Output c = y ⊕ e

**HGOE-Noisy.Dec(sk, c):**
1. For each candidate m ∈ M, compute d\_m = min\_{g ∈ G} d\_H(c, g · x\_m)
   (minimum Hamming distance from c to the orbit G · x\_m)
2. Output m\* = argmin\_m d\_m

The noise prevents the adversary from obtaining exact orbit elements, blocking
the group element recovery attack. Decryption succeeds when the noise level η
is small enough that the minimum distance to the correct orbit is smaller than
to any other orbit. This requires the orbits to be sufficiently "separated" in
Hamming distance, which holds when |G| is large and representatives are chosen
generically.

**Note on decryption cost.** The noisy variant's decryption is more expensive
(it requires approximate closest-orbit computation rather than exact canonical
image). For practical efficiency, the noiseless variant (Section 6.2) is
preferred when the HSP hardness argument for multi-query security is accepted.

### 8.4 Known Attack Vectors

| Attack | Applies to | Mitigation |
|--------|-----------|------------|
| Hamming weight | All variants | Same-weight representatives (§7.1) |
| Graph invariants | GI-OIA | CFI construction (§5.3.1) |
| Partial invariants | All variants | OIA assumption (§5.2) |
| Group recovery from samples | HGOE (multi-query) | HSP hardness (§8.2) or noise (§8.3) |
| Brute-force orbit search | All variants | |G| ≥ 2^λ ensures exponential search |
| Birthday attack on orbits | All variants | Orbit size ≥ 2^λ by construction |

---

## 9. Lean 4 Formalization Plan

### 9.1 Goals

The Lean 4 formalization serves three purposes:

1. **Prove correctness** of the abstract orbit encryption scheme (Dec ∘ Enc = id).
2. **Prove the invariant attack theorem** (a separating invariant implies a
   complete break), giving a machine-checked proof of the counterexample's lesson.
3. **Prove the conditional security reduction** (OIA ⟹ IND-1-CPA), with the
   OIA stated as an axiom.

We do **not** attempt to prove that the OIA holds — that is a computational
conjecture, not a mathematical theorem. Instead we formalize the *structure* of
the argument: if the assumption holds, then security follows.

### 9.2 Project Structure

```
Orbcrypt/
├── lakefile.lean                     -- Build configuration (Mathlib dependency)
├── lean-toolchain                    -- Lean 4 version pin
├── Orbcrypt.lean                     -- Root import file
└── Orbcrypt/
    ├── GroupAction/
    │   ├── Basic.lean                -- Orbit, stabilizer, orbit partition
    │   ├── Canonical.lean            -- Canonical forms under group actions
    │   └── Invariant.lean            -- G-invariant functions and properties
    ├── Crypto/
    │   ├── Scheme.lean               -- AOE scheme syntax (Setup, Enc, Dec)
    │   ├── Security.lean             -- IND-CPA game and advantage definition
    │   └── OIA.lean                  -- Orbit Indistinguishability Assumption
    ├── Theorems/
    │   ├── Correctness.lean          -- Dec(Enc(m)) = m
    │   ├── InvariantAttack.lean      -- Separating invariant ⟹ Adv = 1/2
    │   └── OIAImpliesCPA.lean        -- OIA ⟹ IND-1-CPA
    └── Construction/
        ├── HGOE.lean                 -- Hidden-Group Orbit Encryption instance
        └── Permutation.lean          -- S_n action on {0,1}^n
```

### 9.3 Module Descriptions

#### 9.3.1 Orbcrypt.GroupAction.Basic

Wraps Mathlib's `MulAction` framework with orbit-encryption-specific lemmas.

```lean
import Mathlib.GroupTheory.GroupAction.Basic
import Mathlib.GroupTheory.GroupAction.Defs

-- Key definitions (from Mathlib, re-exported for convenience):
-- MulAction.orbit G x : Set X
-- MulAction.stabilizer G x : Subgroup G

-- Key lemma we will need:
-- MulAction.orbit_eq_iff : orbit G x = orbit G y ↔ ∃ g : G, g • x = y

-- Custom lemma: orbits are disjoint or equal
theorem orbit_disjoint_or_eq [Group G] [MulAction G X]
    (x y : X) :
    MulAction.orbit G x = MulAction.orbit G y ∨
    Disjoint (MulAction.orbit G x) (MulAction.orbit G y) := by
  sorry -- proof via equivalence relation on orbits
```

#### 9.3.2 Orbcrypt.GroupAction.Canonical

Defines canonical forms abstractly.

```lean
structure CanonicalForm (G : Type*) (X : Type*) [Group G] [MulAction G X] where
  canon : X → X
  mem_orbit : ∀ x, canon x ∈ MulAction.orbit G x
  orbit_iff : ∀ x y, canon x = canon y ↔
    MulAction.orbit G x = MulAction.orbit G y
```

#### 9.3.3 Orbcrypt.GroupAction.Invariant

Defines G-invariant functions and the separating condition.

```lean
def IsGInvariant [Group G] [MulAction G X] (f : X → Y) : Prop :=
  ∀ (g : G) (x : X), f (g • x) = f x

def IsSeparating [Group G] [MulAction G X] (f : X → Y)
    (x₀ x₁ : X) : Prop :=
  IsGInvariant (G := G) f ∧ f x₀ ≠ f x₁
```

#### 9.3.4 Orbcrypt.Crypto.Scheme

Defines the abstract encryption scheme.

```lean
structure OrbitEncScheme (G : Type*) (X : Type*) (M : Type*)
    [Group G] [MulAction G X] [DecidableEq X] where
  reps : M → X
  reps_distinct : ∀ m₁ m₂, m₁ ≠ m₂ →
    MulAction.orbit G (reps m₁) ≠ MulAction.orbit G (reps m₂)
  canonForm : CanonicalForm G X

def encrypt [Group G] [MulAction G X]
    (scheme : OrbitEncScheme G X M) (g : G) (m : M) : X :=
  g • scheme.reps m

def decrypt [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (c : X) : Option M :=
  -- Find m such that canon(c) = canon(reps m)
  sorry -- implementation depends on M being Fintype
```

#### 9.3.5 Orbcrypt.Crypto.Security

Defines the IND-CPA game and advantage. Since Lean 4 does not natively model
probabilistic computation, we use a simplified deterministic abstraction:

```lean
-- An adversary is a function from (params, ciphertext) to a bit guess
structure Adversary (X : Type*) (M : Type*) where
  choose : (M → X) → M × M           -- choose challenge pair given reps
  guess  : (M → X) → X → Bool        -- guess bit given reps and challenge ct

-- Advantage in the 1-CPA game
-- (Probabilistic aspects abstracted as quantification over all g ∈ G)
def advantage_1cpa [Group G] [MulAction G X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) : Prop :=
  let (m₀, m₁) := A.choose scheme.reps
  ∃ g₀ g₁ : G,
    A.guess scheme.reps (g₀ • scheme.reps m₀) ≠
    A.guess scheme.reps (g₁ • scheme.reps m₁)
```

#### 9.3.6 Orbcrypt.Crypto.OIA

States the OIA as an axiom parameterized by the scheme.

```lean
-- The OIA, stated as: no adversary can distinguish orbits
-- In a deterministic formalization, this becomes:
-- For all deterministic functions f, if f is applied to any element of
-- orbit(x₀), the result is also achievable by some element of orbit(x₁)
axiom OIA [Group G] [MulAction G X]
    (scheme : OrbitEncScheme G X M) :
    ∀ (f : X → Bool) (m₀ m₁ : M),
      (∀ g : G, f (g • scheme.reps m₀) = true) →
      (∀ g : G, f (g • scheme.reps m₁) = true) ∨
      ¬(∀ g : G, f (g • scheme.reps m₀) = true)
```

Note: the full probabilistic OIA requires a probability monad or an external
verification framework (e.g., CryptHOL). The deterministic version above
captures the essential logical structure while remaining tractable in pure
Lean 4.

#### 9.3.7 Orbcrypt.Theorems.Correctness

The central correctness theorem.

```lean
theorem correctness [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m : M) (g : G) :
    decrypt scheme (encrypt scheme g m) = some m := by
  -- encrypt produces g • reps m, which is in orbit G (reps m)
  -- canon(g • reps m) = canon(reps m) by CanonicalForm.orbit_iff
  -- lookup succeeds by reps_distinct
  sorry
```

#### 9.3.8 Orbcrypt.Theorems.InvariantAttack

The machine-checked invariant attack theorem.

```lean
theorem invariant_attack [Group G] [MulAction G X]
    (scheme : OrbitEncScheme G X M)
    (f : X → Y) (m₀ m₁ : M)
    (hInv : IsGInvariant (G := G) f)
    (hSep : f (scheme.reps m₀) ≠ f (scheme.reps m₁)) :
    -- There exists an adversary that always correctly identifies the message
    ∃ (A : Adversary X M),
      ∀ (g : G) (b : Bool),
        let c := if b then g • scheme.reps m₁ else g • scheme.reps m₀
        A.guess scheme.reps c = b := by
  -- Construct A that computes f(c) and compares to f(reps m₀)
  -- By G-invariance: f(g • reps m_b) = f(reps m_b)
  -- By separation: f(reps m₀) ≠ f(reps m₁), so comparison determines b
  sorry
```

#### 9.3.9 Orbcrypt.Theorems.OIAImpliesCPA

The conditional security theorem.

```lean
theorem oia_implies_1cpa [Group G] [MulAction G X]
    (scheme : OrbitEncScheme G X M)
    (hOIA : ∀ (f : X → Bool) (m₀ m₁ : M) (g : G),
      ∃ g' : G, f (g • scheme.reps m₀) = f (g' • scheme.reps m₁)) :
    -- No adversary has advantage: for every adversary and every challenge,
    -- the guess on orbit 0 can be matched by some element of orbit 1
    ∀ (A : Adversary X M),
      let (m₀, m₁) := A.choose scheme.reps
      ∀ g₀ : G, ∃ g₁ : G,
        A.guess scheme.reps (g₀ • scheme.reps m₀) =
        A.guess scheme.reps (g₁ • scheme.reps m₁) := by
  -- Direct application of OIA with f := A.guess scheme.reps
  sorry
```

### 9.4 Mathlib Dependencies

| Mathlib Module | Used For |
|---------------|----------|
| `Mathlib.GroupTheory.GroupAction.Basic` | `MulAction`, `orbit`, `stabilizer` |
| `Mathlib.GroupTheory.GroupAction.Defs` | Core action definitions |
| `Mathlib.GroupTheory.Subgroup.Basic` | `Subgroup` type |
| `Mathlib.GroupTheory.Perm.Basic` | `Equiv.Perm` for S\_n |
| `Mathlib.Data.Fintype.Basic` | Finite types for M |
| `Mathlib.Data.ZMod.Basic` | F\_2 = ZMod 2 for bitstrings |
| `Mathlib.Order.BooleanAlgebra` | Bool operations for adversary output |

### 9.5 Development Roadmap

**Phase 1 — Algebraic Core (Weeks 1–4)**
- Implement `GroupAction/` modules
- Prove orbit partition theorem and canonical form properties
- All proofs are pure algebra; no computational assumptions needed

**Phase 2 — Scheme Definition (Weeks 5–6)**
- Implement `Crypto/Scheme.lean` and `Crypto/Security.lean`
- Define the AOE syntax and IND-CPA game
- These are definitions, not theorems

**Phase 3 — Core Theorems (Weeks 7–10)**
- Prove `Correctness.lean` (straightforward from orbit properties)
- Prove `InvariantAttack.lean` (the key formalized insight from COUNTEREXAMPLE.md)
- Prove `OIAImpliesCPA.lean` (conditional on OIA axiom)

**Phase 4 — Concrete Construction (Weeks 11–14)**
- Implement `Construction/Permutation.lean` (S\_n action on {0,1}^n)
- Implement `Construction/HGOE.lean` (instantiate AOE with HGOE parameters)
- Verify that the concrete construction satisfies the abstract AOE interface

**Phase 5 — Refinement (Weeks 15–16)**
- Replace `sorry` placeholders with complete proofs
- Add documentation and examples
- Verify all files compile cleanly against current Mathlib

---

## 10. Open Problems and Future Directions

### 10.1 Public-Key Extension

The current scheme is symmetric-key: both parties must share G. A major open
question is whether the orbit encryption paradigm can be extended to
public-key encryption. This would require a mechanism for a sender who does
**not** know G to nonetheless sample from a specific G-orbit. Possible
approaches:

- **Commutative group actions** (à la CSIDH): if the group action is
  commutative, key exchange protocols can be built on top, potentially enabling
  public-key orbit encryption.
- **Oblivious orbit sampling:** publish a set of "randomizers" (precomputed
  orbit elements) that the sender can combine to produce fresh orbit samples
  without learning G.

### 10.2 Tighter Reductions

The CE-OIA provides security evidence but not a tight polynomial reduction to a
single named hard problem. Establishing a tight reduction — ideally of the form
"breaking HGOE with advantage ε requires solving code equivalence with
advantage ε − negl(λ)" — would significantly strengthen the theoretical
foundation.

### 10.3 Optimal Group Families

Which permutation groups G ≤ S\_n maximize security for a given n? The ideal
group would have:
- Large order (|G| ≥ 2^λ for mixing)
- Many orbits on weight-w strings (for a large message space)
- No efficiently computable non-trivial invariants (for security)
- Efficient canonical image computation (for decryption speed)

Characterizing such groups — or proving they exist for all n — is a rich
algebraic question connected to computational group theory and combinatorics.

### 10.4 Non-Abelian and Higher-Dimensional Actions

The current framework uses permutation groups acting on bitstrings. Richer
algebraic structures may yield stronger security:

- **Matrix group actions** on tensor spaces (related to tensor isomorphism,
  believed harder than GI)
- **Non-abelian group actions** on combinatorial objects (e.g., braid groups
  acting on configurations)
- **Higher-dimensional objects** such as hypergraphs or simplicial complexes,
  where isomorphism problems are known to be harder than GI

### 10.5 Invariant Complexity Theory

The invariant attack theorem shows that security requires the absence of
efficiently computable separating invariants. This connects to deep questions
in descriptive complexity:

- **Which group actions admit no polynomial-time invariants?** This is related
  to the question of whether k-WL (Weisfeiler–Leman) captures PTIME on all
  graph classes — a major open problem in finite model theory.
- **Can we construct groups with provably no polynomial-circuit invariants?**
  Such a result would give unconditional (rather than assumption-based)
  security, but likely requires circuit lower bound breakthroughs.

### 10.6 Quantum Security

The OIA's resistance to quantum adversaries depends on the quantum hardness of
the underlying problems:

- **GI:** Babai's quasi-polynomial algorithm is classical. No quantum speedup
  beyond this is known. The quantum HSP on S\_n remains open.
- **Code equivalence:** No quantum algorithm significantly outperforms
  classical approaches.
- **HSP on S\_n:** Believed hard even quantumly — this is one of the central
  open problems in quantum computing.

A formal analysis of post-quantum security for HGOE, potentially leveraging
the quantum hardness of HSP on S\_n, is a natural direction.

### 10.7 Formal Verification of Computational Assumptions

While the Lean 4 formalization covers the algebraic structure, formalizing the
computational arguments (probabilistic reductions, advantage calculations)
would require a framework for reasoning about probabilistic polynomial-time
computation. Candidate frameworks include:

- **CryptHOL** (Isabelle/HOL): mature framework for game-based cryptographic
  proofs, potentially portable to Lean 4
- **FCF** (Coq): Foundational Cryptography Framework
- A custom probability monad in Lean 4 with appropriate axioms

Porting or building such a framework would enable end-to-end machine-checked
security proofs for Orbcrypt.

---

## Appendix A: Notation Reference

| Symbol | Meaning |
|--------|---------|
| S\_n | Symmetric group on n elements |
| G ≤ S\_n | Permutation group (subgroup of S\_n) |
| G · x | Orbit of x under G |
| Stab\_G(x) | Stabilizer of x in G |
| can\_G(x) | Canonical representative of the orbit G · x |
| wt(x) | Hamming weight of bitstring x |
| PAut(C) | Permutation automorphism group of code C |
| CFI(H, t) | Cai–Fürer–Immerman graph from base H with twist t |
| k-WL | k-dimensional Weisfeiler–Leman algorithm |
| negl(λ) | Negligible function in security parameter λ |
| PPT | Probabilistic polynomial time |
| IND-CPA | Indistinguishability under chosen-plaintext attack |
| OIA | Orbit Indistinguishability Assumption |
| GI-OIA | OIA instantiated via Graph Isomorphism |
| CE-OIA | OIA instantiated via Code Equivalence |
| HGOE | Hidden-Group Orbit Encryption |

---

## Appendix B: Document Lineage

This document synthesizes and extends two prior documents in this repository:

- **POE.md** — Introduced the Permutation-Orbit Encryption and Isogeny-Orbit
  Encryption concepts, the unifying view of orbit-based encryption, and the
  insight that security comes from hiding equivalence relations.

- **COUNTEREXAMPLE.md** — Identified the invariant attack vulnerability,
  demonstrated it on bitstring and graph instances, and established the
  precise condition for "true collapse" (no efficiently computable separating
  invariants).

This development document addresses the weaknesses identified in both documents
by: (1) defining a concrete OIA grounded in Graph Isomorphism and Code
Equivalence, (2) using CFI graphs to provably resist known invariant attacks,
(3) specifying a practical hidden-group construction with efficient decryption,
and (4) providing a complete Lean 4 formalization plan.

---
