# Orbcrypt — Master Development Document

## Permutation-Orbit Encryption with Formal Verification in Lean 4

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Background and Design Principles](#2-background-and-design-principles)
3. [Mathematical Preliminaries](#3-mathematical-preliminaries)
4. [Abstract Orbit Encryption (AOE)](#4-abstract-orbit-encryption-aoe)
    - 4.1 Scheme Syntax | 4.2 Correctness | 4.3 IND-CPA | 4.4 Invariant Attack Theorem
5. [The Orbit Indistinguishability Assumption (OIA)](#5-the-orbit-indistinguishability-assumption-oia)
    - 5.1 Informal Statement | 5.2 Formal Definition | 5.3 Candidate A: GI-OIA (CFI) | 5.4 Candidate B: CE-OIA
6. [The Orbcrypt Construction](#6-the-orbcrypt-construction)
    - 6.1 Parameters | 6.2 Full Specification (7-stage pipeline) | 6.3 Correctness | 6.4 Efficiency
7. [Addressing the Counterexample](#7-addressing-the-counterexample)
    - 7.1 Hamming Weight | 7.2 Graph Statistics | 7.3 Partial Invariants | 7.4 True Collapse
8. [Security Analysis](#8-security-analysis)
    - 8.1 OIA ⟹ IND-1-CPA | 8.2 Multi-Query (hybrid) | 8.3 Noisy Variant | 8.4 Attack Sub-Analyses
9. [Lean 4 Formalization Plan](#9-lean-4-formalization-plan) *(see [formalization/](formalization/FORMALIZATION_PLAN.md))*
10. [Open Problems and Future Directions](#10-open-problems-and-future-directions)
- [Appendix A: Notation Reference](#appendix-a-notation-reference)
- [Appendix B: Document Lineage](#appendix-b-document-lineage)

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
through the following step-by-step procedure:

**Step 1 — Choose a base graph H.**
H must be connected. For our purposes H is 3-regular (every vertex has degree
3). The number of edges is |E(H)| = 3n₀/2.

**Step 2 — Fix an edge ordering at each vertex.**
For every vertex v ∈ V(H), fix an arbitrary total order on the edges incident
to v. Write these edges as e\_1^v, e\_2^v, …, e\_{d\_v}^v where d\_v = deg(v).

**Step 3 — Build vertex fibers.**
Replace each vertex v by a set F(v) of 2^{d\_v − 1} fiber vertices. Each
fiber vertex corresponds to a binary vector (b\_1, …, b\_{d\_v}) ∈ {0,1}^{d\_v}
with **even parity** (∑b\_i ≡ 0 mod 2). The bit b\_i records which "side" of
edge e\_i^v this fiber vertex represents.

For 3-regular H: each fiber has 2^{3−1} = 4 vertices, so |V(CFI(H,t))| = 4n₀.

**Step 4 — Wire the edge gadgets using the twist vector.**
For each edge e = {u, v} ∈ E(H) with twist bit t\_e:
- Let i = position of e in the ordering at u, j = position of e at v.
- Connect fiber vertex (…, b\_i, …) at u to fiber vertex (…, b\_j, …) at v
  whenever b\_i ⊕ b\_j = t\_e.
  - t\_e = 0 ("straight"): match fibers where the edge-bits agree.
  - t\_e = 1 ("crossed"): match fibers where the edge-bits disagree.

**Step 5 — Output.**
The resulting graph CFI(H, t) has 4n₀ vertices and a regular structure
inherited from H.

**Key properties of CFI graphs:**

| Property | Statement |
|----------|-----------|
| Isomorphism criterion | CFI(H, t₁) ≅ CFI(H, t₂) **iff** ∑t₁ ≡ ∑t₂ (mod 2) |
| WL resistance | For all fixed k, k-dim Weisfeiler–Leman cannot distinguish CFI(H, t₁) from CFI(H, t₂) when ∑t₁ ≢ ∑t₂, provided H has minimum degree > k |
| GI-completeness | GI on CFI instances is polynomial-time equivalent to general GI |
| Size | For d-regular H: CFI(H, t) has 2^{d−1} · n₀ vertices |
| Regularity | If H is d-regular, CFI(H, t) is (d · 2^{d−2})-regular |
| Edge count | All CFI graphs from the same H have the same number of edges, regardless of t |

**Why WL resistance matters for us.** The Weisfeiler–Leman hierarchy is the
most powerful known family of polynomial-time graph-distinguishing algorithms.
The k-WL algorithm iteratively refines colorings of k-tuples of vertices. It
subsumes:
- Degree sequence (k = 1)
- Counting cycles of length ≤ k (k-WL detects these)
- Spectral methods on regular graphs (subsumed by 2-WL)
- All first-order definable invariants (subsumed by finite k)

CFI graphs from 3-regular base graphs resist k-WL for all k ≤ 3. By using
d-regular base graphs with d > k for any desired k, resistance can be pushed
to arbitrary depth. This **provably eliminates all polynomial-time invariant
attacks known in the literature**, directly defeating every attack vector from
COUNTEREXAMPLE.md.

#### 5.3.2 GI-OIA Construction

**Setup\_{GI}(1^λ):**

The setup decomposes into five subtasks with explicit preconditions:

**Subtask 1 — Base graph generation.**
- Input: security parameter λ.
- Procedure: choose n₀ = Θ(λ). Sample a uniformly random connected 3-regular
  graph H on n₀ vertices using the configuration model with rejection sampling
  for connectivity.
- Output: H with |V(H)| = n₀, |E(H)| = 3n₀/2.
- Precondition: n₀ must be even (for 3-regular graphs to exist).

**Subtask 2 — Twist vector sampling.**
- Input: H from Subtask 1.
- Procedure:
  a. Sample t₀ ← {0,1}^{|E(H)|} conditioned on ∑t₀ ≡ 0 (mod 2).
     (Sample |E(H)|−1 bits uniformly; set the last bit to make parity even.)
  b. Sample t₁ ← {0,1}^{|E(H)|} conditioned on ∑t₁ ≡ 1 (mod 2).
     (Same procedure, but set the last bit to make parity odd.)
- Output: t₀, t₁ with distinct parities.
- Postcondition: CFI(H, t₀) ≇ CFI(H, t₁) (guaranteed by the parity criterion).

**Subtask 3 — CFI graph construction.**
- Input: H, t₀, t₁ from Subtasks 1–2.
- Procedure: apply the 5-step CFI construction (§5.3.1) to produce Γ₀ = CFI(H, t₀)
  and Γ₁ = CFI(H, t₁).
- Output: two graphs on n = 4n₀ vertices.
- Postcondition: Γ₀ ≇ Γ₁, both share all k-WL invariants for k ≤ 3.

**Subtask 4 — Adjacency encoding.**
- Input: Γ₀, Γ₁ on n vertices.
- Procedure: encode each as an adjacency vector in {0,1}^{N} where N = n(n−1)/2,
  using a fixed canonical vertex-pair ordering (lexicographic on pairs (i,j) with
  i < j).
- Output: x₀, x₁ ∈ {0,1}^N.

**Subtask 5 — Key assembly.**
- G = S\_n acting on {0,1}^N via induced edge-permutation.
- params = (N, {0,1}, {x₀, x₁}).
- sk = (H, t₀, t₁) — the structural knowledge enabling efficient decryption by
  "unrolling" CFI gadgets. The key holder recognizes the fiber/gadget structure
  in a relabeled graph by leveraging knowledge of H, then reads off the twist
  parity to determine which orbit the ciphertext belongs to.

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

**Setup\_{CE}(1^λ)** decomposes into four subtasks:

**Subtask 1 — Code family selection.**

The code C₀ must satisfy three competing constraints:

| Constraint | Reason | Quantitative target |
|------------|--------|---------------------|
| |PAut(C₀)| ≥ 2^λ | Mixing entropy for ciphertext randomization | log₂\|PAut\| ≥ 128 |
| PAut(C₀) hard to recover | Security against group-recovery attacks | No known poly-time algorithm for the chosen family |
| Efficient canonical image under PAut(C₀) | Decryption speed | O(n^c) via partition backtracking |

**Recommended family: Quasi-cyclic (QC) codes.**

A QC code of index ℓ and block length b has length n = ℓ · b and is invariant
under cyclic shifts within each of the ℓ blocks. This guarantees:
- PAut(C₀) ≥ (Z/bZ)^ℓ (cyclic shift in each block), giving |PAut| ≥ b^ℓ.
- For b = 2, ℓ = λ: |PAut| ≥ 2^λ with n = 2λ.
- For b = 8, ℓ = λ/3: |PAut| ≥ 8^{λ/3} = 2^λ with n = 8λ/3.

QC codes are well-studied in post-quantum cryptography (e.g., BIKE, HQC) and
their equivalence problem is believed hard. They are the recommended choice.

**Alternative families (with tradeoffs):**
- **Generalized Reed–Muller codes RM(r, m):** |PAut| = |GL(m, F\_2)| ≈ 2^{m²},
  very large. But the automorphism group structure is well-known (affine group),
  so recovery may be easier. Use only if the code is further scrambled.
- **Random self-dual codes:** |PAut| is non-trivial on average but unpredictable;
  may require rejection sampling to ensure |PAut| ≥ 2^λ.
- **Quasi-dyadic codes:** similar to QC but using dyadic structure; studied in
  the context of McEliece variants.

**Subtask 2 — Code generation and automorphism computation.**

- Input: family choice from Subtask 1, parameters n, k, b, ℓ.
- Procedure:
  a. Generate a random QC [n, k]-code C₀ over F\_2 by sampling ℓ circulant
     blocks of size b × b for the generator matrix.
  b. Compute PAut(C₀) using the **support splitting algorithm** (Sendrier, 2000)
     or Leon's algorithm adapted for code automorphisms.
  c. Store the result as a strong generating set (SGS) for G = PAut(C₀).
  d. Verify |G| ≥ 2^λ using Schreier–Sims. If not, resample C₀ and retry.
- Output: code C₀, group G with SGS, verified |G| ≥ 2^λ.

**Subtask 3 — Orbit representative selection.**

This is the most delicate step. Representatives must satisfy:

1. **Equal weight:** wt(x\_m) = w for all m, where w = ⌊n/2⌋.
2. **Distinct orbits:** G · x\_{m\_i} ∩ G · x\_{m\_j} = ∅ for i ≠ j.
3. **Same S\_n-orbit:** all x\_m are binary strings of weight w (automatic from
   constraint 1), so they share all S\_n-invariants.

Procedure:
  a. Fix target weight w = ⌊n/2⌋.
  b. Initialize representative set R = ∅ and canonical set C = ∅.
  c. Repeat until |R| = |M|:
     i.   Sample x ← {0,1}^n with wt(x) = w uniformly at random.
     ii.  Compute can\_G(x) using partition backtracking.
     iii. If can\_G(x) ∉ C: add x\_m := can\_G(x) to R, add can\_G(x) to C.
     iv.  Else: discard x and retry.
  d. Output {x\_m}\_{m ∈ M}.

Expected sampling cost: the number of weight-w orbits under G is approximately
C(n,w)/|G|. For n = 1024, w = 512, |G| = 2^{128}: there are roughly
2^{1024}/2^{128} = 2^{896} distinct orbits, so collisions are negligible and
each sample produces a new orbit with overwhelming probability.

**Subtask 4 — Key assembly.**

- params = (n, w, M, {x\_m}\_{m ∈ M}).
- sk = (SGS for G, canonical image oracle can\_G).
- The code C₀ itself need not be stored after G is computed (G is the
  operational secret; C₀ is only needed during key generation).

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

The specification follows a pipeline of seven stages. Each stage has explicit
inputs, outputs, and validation checks.

#### 6.2.1 HGOE.Setup(1^λ) — Detailed Pipeline

**Stage 1 — Parameter derivation.**
- Input: security parameter λ.
- Compute: block length b = 8, index ℓ = ⌈λ / log₂ b⌉ = ⌈λ/3⌉, n = b · ℓ,
  k = ⌊n/2⌋, w = ⌊n/2⌋.
- Validate: log₂(b^ℓ) ≥ λ (ensures |PAut| ≥ 2^λ from the QC structure alone).
- Output: (n, k, b, ℓ, w).

**Stage 2 — Quasi-cyclic code generation.**
- Input: (n, k, b, ℓ) from Stage 1.
- Procedure:
  a. For each of the ℓ blocks, sample a random circulant b × b matrix over F\_2
     as a generator block.
  b. Assemble these into a k × n generator matrix G\_mat in systematic form
     [I\_k | P] where P is quasi-cyclic.
  c. Let C₀ = rowspace(G\_mat).
- Validate: C₀ has dimension k (the rows are linearly independent). If not,
  resample the circulant blocks.
- Output: generator matrix G\_mat, code C₀.

**Stage 3 — Automorphism group computation.**
- Input: C₀ from Stage 2.
- Procedure:
  a. Run the support splitting algorithm (Sendrier, 2000) to find generators
     of PAut(C₀). This algorithm exploits the structure of the code's weight
     distribution to identify automorphisms.
  b. Alternatively, use Leon's algorithm for permutation group computation on
     the column-action of the code.
  c. Build a Schreier–Sims strong generating set (SGS) for G = PAut(C₀).
  d. Compute |G| from the SGS.
- Validate: |G| ≥ 2^λ. If not, return to Stage 2 with fresh random circulants.
  For QC codes, the QC structure guarantees (Z/bZ)^ℓ ≤ PAut(C₀), so this
  check should pass on the first attempt. Additional automorphisms beyond the
  cyclic structure only increase |G|.
- Output: SGS for G, verified |G|.

**Stage 4 — Orbit representative harvesting.**
- Input: G (via SGS), parameters (n, w, |M|) from Stages 1 and 3.
- Procedure:
  a. Initialize hash table T mapping canonical images to message indices.
  b. Set counter m = 0.
  c. While m < |M|:
     i.   Sample x ← Uniform({y ∈ {0,1}^n : wt(y) = w}) using a Fisher–Yates
          shuffle on the position set.
     ii.  Compute c = can\_G(x) via partition backtracking.
     iii. If c ∉ T: set x\_m := c, insert T[c] := m, increment m.
     iv.  If c ∈ T: discard (orbit collision, negligible probability).
  d. Output representative array [x₀, x₁, …, x\_{|M|−1}].
- Validate: all x\_m have weight w, and all can\_G(x\_m) are distinct (both hold
  by construction).
- Expected cost: |M| canonical image computations, each O(n^c). The collision
  probability per sample is |M| / (number of orbits) ≈ |M| · |G| / C(n,w),
  which is negligible for practical parameters.

**Stage 5 — Lookup table construction.**
- Input: representative array from Stage 4.
- Procedure: build a hash map from canonical image (as a bitstring) to message
  index m. This enables O(1) amortized lookup during decryption.
- Output: lookup table L : {0,1}^n → M ∪ {⊥}.

**Stage 6 — Secret key assembly.**
- sk = (SGS for G, lookup table L, parameters n, w).
- The SGS enables both uniform group sampling (for encryption) and canonical
  image computation (for decryption).

**Stage 7 — Public parameter assembly.**
- params = (n, w, |M|, [x₀, x₁, …, x\_{|M|−1}]).
- The representative array is published. The SGS (equivalently, G) is secret.

#### 6.2.2 HGOE.Enc(sk, m) — Detailed Steps

- Input: secret key sk, message m ∈ M.
- **Step 1 — Group element sampling.**
  Sample g ← G uniformly using one of:
  - *Product Replacement Algorithm (PRA):* maintain a buffer of group elements;
    at each step, multiply two random buffer entries and replace one. After a
    mixing period of O(n log |G|) steps, output the current element. This is
    the standard method in computational group theory (CGGT).
  - *Random subproduct:* express g as a product of random subset of the SGS
    generators with random exponents. Faster but with weaker uniformity
    guarantees.
  The PRA is recommended for cryptographic use due to its stronger mixing
  properties.
- **Step 2 — Permutation application.**
  Compute c = g · x\_m: for each coordinate i ∈ {1,…,n}, set c\_i = (x\_m)\_{g⁻¹(i)}.
  This is a single array permutation, O(n).
- **Step 3 — Output.**
  Return c ∈ {0,1}^n.
- Total cost: O(n log |G|) for sampling + O(n) for permutation = O(n log |G|).

#### 6.2.3 HGOE.Dec(sk, c) — Detailed Steps

- Input: secret key sk, ciphertext c ∈ {0,1}^n.
- **Step 1 — Canonical image computation.**
  Compute x\* = can\_G(c) via partition backtracking (Leon's algorithm):
  a. Initialize the search with the trivial partition of {1,…,n}.
  b. Refine the partition using the action of G (computed from the SGS).
  c. Backtrack through individualization choices, pruning branches using
     automorphism information from the SGS.
  d. Output the lexicographically minimal element of G · c.
  Cost: O(n^c) where c ≈ 3–5 for groups arising from code automorphisms.
- **Step 2 — Table lookup.**
  Query L[x\*]. If L[x\*] = m for some m ∈ M, output m.
  If L[x\*] = ⊥, output ⊥ (decryption failure — should never occur for
  honestly generated ciphertexts).
  Cost: O(1) amortized (hash table lookup).
- Total cost: O(n^c) dominated by the canonical image computation.

### 6.3 Correctness (Instantiated)

By Theorem 4.2 (Correctness of AOE), HGOE is correct: Dec(sk, Enc(sk, m)) = m
with probability 1.

The proof traces through the pipeline:
1. Enc outputs c = g · x\_m for some g ∈ G, so c ∈ G · x\_m.
2. Dec computes can\_G(c). Since c and x\_m are in the same G-orbit,
   can\_G(c) = can\_G(x\_m).
3. The lookup table maps can\_G(x\_m) to m (by Stage 5 of Setup).
4. Therefore Dec returns m. ∎

### 6.4 Efficiency

| Operation | Dominant cost | Justification |
|-----------|---------------|---------------|
| Setup — code generation | O(n² k) | Matrix assembly and row reduction |
| Setup — automorphism computation | O(n² log² \|G\|) | Schreier–Sims on PAut(C₀) |
| Setup — orbit harvesting | O(\|M\| · n^c) | One canonical image per representative |
| Setup — lookup table | O(\|M\| · n) | Hashing each n-bit canonical image |
| Encryption | O(n log \|G\|) | PRA sampling + one permutation |
| Decryption | O(n^c) | Partition backtracking + O(1) lookup |
| Ciphertext size | n bits | One element of {0,1}^n |
| Secret key size | O(n² log \|G\|) bits | SGS storage |
| Public params size | O(\|M\| · n) bits | All orbit representatives |

Here c is a small constant (typically 3–5 in practice for partition
backtracking on groups arising from code automorphisms).

**Concrete example (λ = 128):** n = 344, b = 8, ℓ = 43, k = 172, w = 172.
|G| ≥ 8^{43} = 2^{129}. Ciphertext: 344 bits (43 bytes). Encryption: ~5000
group multiplications. Decryption: partition backtracking on a 344-element
permutation group.

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
weight** w = ⌊n/2⌋ (§6.2.1, Stage 1 and Stage 4). Therefore wt(x\_{m₀}) = wt(x\_{m₁})
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

This is **exactly** the OIA (§5.2). Our construction satisfies this
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

**Note on game asymmetry (audit F-02 / Workstream B1).** The classical
IND-1-CPA game presumed above requires the adversary to submit two
**distinct** challenge messages `m₀ ≠ m₁`. In the Lean formalization
(`Orbcrypt/Crypto/Security.lean`), the `Adversary.choose` field is
structurally unconstrained and may return a collision `(m, m)`. Two
security predicates coexist in the codebase:

- `IsSecure scheme` — quantifies over *all* adversaries, including the
  degenerate ones that return `(m, m)`. This is strictly stronger than
  the literature game.
- `IsSecureDistinct scheme` — quantifies only over adversaries whose
  `choose` yields `m₀ ≠ m₁`. This matches the game described above.

The one-way implication `isSecure_implies_isSecureDistinct : IsSecure
scheme → IsSecureDistinct scheme` is proved unconditionally; the
converse is false in general, since the stronger game accepts
collisions that the classical game rejects. Downstream probabilistic
theorems (Phase 8) use the advantage-bounded formulation
`indCPAAdvantage ≤ ε`, which is independent of this structural choice.

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

**Proof.** We construct a sequence of hybrid experiments. Let A be a PPT
adversary making Q = Q(λ) oracle queries.

**Hybrid H₀ (real game, b = 0).**
A receives params. A adaptively queries Enc(sk, m\_i) for i = 1,…,Q, receiving
c\_i = g\_i · x\_{m\_i} for fresh g\_i ← G. A receives challenge c\* = g\* · x\_{m₀}.
A outputs a bit.

**Hybrid H₁ (real game, b = 1).**
Identical to H₀ except c\* = g\* · x\_{m₁}.

We must show |Pr[A→1 in H₀] − Pr[A→1 in H₁]| ≤ negl(λ).

**Step 1 — Decompose the adversary's view.**
A's view is V = (params, c₁, …, c\_Q, c\*). The oracle responses {c\_i} are
independent uniform samples from G-orbits of A's choosing. The challenge c\*
is an independent uniform sample from G · x\_{m\_b}.

**Step 2 — Argue oracle queries don't help recover G.**
Each oracle response c\_i = g\_i · x\_{m\_i} is a uniform element of G · x\_{m\_i}.
Since x\_{m\_i} is public and has weight w, c\_i is a binary string of weight w
that is a specific (unknown) permutation of x\_{m\_i}.

To extract any element of G from oracle responses, the adversary would need to
solve: given x\_{m\_i} and g\_i · x\_{m\_i} (both weight-w binary strings), find
g\_i ∈ G. But:
- The set of ALL permutations mapping x\_{m\_i} to c\_i has size w! · (n−w)!
  (permutations that independently rearrange 1-positions and 0-positions).
- The adversary must identify which of these belongs to G — without knowing G.
- This is precisely an instance of the **Hidden Subgroup Problem on S\_n**:
  the function f(σ) = σ · x\_{m\_i} is constant on right cosets of Stab(x\_{m\_i}),
  and the adversary seeks to identify which coset lies in G.
- With Q polynomial samples, the HSP on S\_n remains intractable (both
  classically and quantumly for non-abelian groups).

**Step 3 — Reduce to single-query OIA.**
Since the oracle queries provide negligible information about G under the HSP
hardness assumption, the adversary's advantage in distinguishing H₀ from H₁
is bounded by:

```
|Pr[A→1 in H₀] − Pr[A→1 in H₁]|
  ≤ Adv^{OIA}_A(λ) + Q · Adv^{HSP}_{A'}(λ)
  ≤ negl(λ) + Q · negl(λ)
  = negl(λ)
```

where Adv^{HSP}\_{A'} is the advantage of the best HSP solver derived from A.
Since Q is polynomial and negl(λ) is negligible, the sum is negligible. ∎

### 8.3 Strengthening: Noisy Variant

For defense-in-depth against multi-query attacks (in case HSP turns out easier
than expected for specific group families), we define a noisy variant.

#### 8.3.1 Construction

**HGOE-Noisy.Enc(sk, m):**
1. Sample g ← G uniformly.
2. Compute y = g · x\_m.
3. Sample noise vector e ← Ber(η)^n, where each bit is independently flipped
   with probability η. Recommended: η = O(1/√n) to balance security and
   decodability.
4. Output c = y ⊕ e.

**HGOE-Noisy.Dec(sk, c):**
1. **Nearest-orbit decoding.** For each candidate orbit representative x\_m in
   a short list (or all of M if |M| is small):
   a. Compute d\_m = min\_{g ∈ G} d\_H(c, g · x\_m), the minimum Hamming distance
      from c to the orbit G · x\_m.
   b. In practice, approximate this by: compute can\_G(c) and compare to
      can\_G(x\_m), accepting a small error rate.
2. Output m\* = argmin\_m d\_m.

#### 8.3.2 Correctness under Noise

Decryption succeeds when the noise e does not push c closer to the wrong orbit
than the correct one. The probability of decryption error is:

```
Pr[error] ≤ Pr[d_H(c, G · x_{m'}) < d_H(c, G · x_m) for some m' ≠ m]
```

For η = O(1/√n), the expected number of flipped bits is O(√n), and the minimum
inter-orbit Hamming distance grows as Ω(n) for generic representatives. So the
error probability is exponentially small in n — specifically, by a Chernoff
bound, Pr[error] ≤ exp(−Ω(n)).

#### 8.3.3 Security Benefit

The noise prevents exact recovery of orbit elements from ciphertexts, which
blocks the group-element extraction strategy in §8.2 Step 2. Even with
unbounded oracle access, each ciphertext is a *noisy* orbit sample, and
recovering exact group elements from noisy samples requires solving a
lattice-like closest-vector problem in the permutation setting — for which no
efficient algorithm is known.

**Note on practical choice.** The noiseless variant (§6.2.2) is recommended when
the HSP hardness argument is accepted. The noisy variant provides a fallback
with defense-in-depth at the cost of slightly more complex decryption.

### 8.4 Known Attack Vectors — Detailed Sub-Analyses

| # | Attack | Target | Mitigation | Residual risk |
|---|--------|--------|------------|---------------|
| 1 | Hamming weight | All variants | Same-weight representatives (§7.1) | None (eliminated by design) |
| 2 | Higher-order weight statistics | HGOE | All reps in same S\_n-orbit (§7.2) | None for S\_n-invariant statistics |
| 3 | Graph invariants (degree, spectrum, cycles) | GI-OIA | CFI construction (§5.3.1) resists all k-WL | No known poly-time invariant separates CFI pairs |
| 4 | Partial / ad-hoc invariants | All variants | OIA assumption (§5.2) | Assumption-dependent |
| 5 | Group recovery from orbit samples | HGOE (multi-query) | HSP hardness (§8.2) | Dependent on HSP for specific G families |
| 6 | Group recovery from noisy samples | HGOE-Noisy | Noise layer (§8.3) | Requires solving closest-vector in permutation groups |
| 7 | Brute-force orbit enumeration | All variants | \|G\| ≥ 2^λ ⟹ \|G·x\| ≥ 2^λ/\|Stab(x)\| | Infeasible for λ ≥ 128 |
| 8 | Birthday / collision attack | All variants | Orbit size ≥ 2^λ ⟹ birthday bound 2^{λ/2} | Secure for λ ≥ 256 (2^{128} birthday bound) |
| 9 | Algebraic attacks on QC structure | CE-OIA | QC code equivalence believed hard | Active research area; monitor literature |
| 10 | Quantum attacks (Shor-type) | All variants | No known quantum speedup for GI or HSP on S\_n | GI is not known to be in BQP |

#### 8.4.1 Attack #9 in Detail: Algebraic Attacks on QC Codes

Quasi-cyclic codes have additional algebraic structure (circulant blocks) that
might, in principle, be exploitable. Known attack strategies include:

- **Folding attacks:** exploit the cyclic structure to reduce the problem
  dimension by a factor of b. For b = 8, this reduces n = 344 to an effective
  dimension of 43, which is still large enough for security.
- **Distinguishing attacks on code structure:** determine whether a given code
  is QC. These reveal code *type* but not the specific automorphism group, so
  they do not directly break the OIA.
- **Algebraic decoding attacks:** use the cyclic structure to speed up decoding.
  These are relevant for code-based PKE (McEliece) but not directly for our
  orbit-membership problem.

**Mitigation:** choose b small (b = 8 is conservative) and ℓ large. The QC
structure provides the minimum guaranteed |PAut|, but the actual PAut may be
much larger (and less structured) due to "accidental" automorphisms.

#### 8.4.2 Attack #10 in Detail: Quantum Threat Model

The post-quantum security of HGOE rests on three pillars:

1. **GI is not known to be in BQP.** Despite decades of research, no quantum
   polynomial-time algorithm for GI has been found. Babai's 2^{O(√(n log n))}
   algorithm is classical and has not been improved quantumly.
2. **HSP on S\_n is hard quantumly.** The quantum HSP on non-abelian groups
   (including S\_n) is a major open problem. The standard quantum approach
   (coset sampling + Fourier transform over the group) fails for S\_n because
   the representation theory of S\_n does not yield efficient distinguishers.
3. **Code equivalence has no known quantum speedup.** While Shor's algorithm
   breaks RSA/DLP-based systems, no analogous quantum algorithm is known for
   code equivalence or permutation group problems.

### 8.5 AEAD and Ciphertext Integrity (INT-CTXT)

The Phase 10 AEAD layer composes the Orbit-KEM with a Message Authentication
Code (MAC) following the Encrypt-then-MAC paradigm. The `MAC` abstraction
(`Orbcrypt/AEAD/MAC.lean`) carries **four** proof obligations — three
correctness conditions and one tag-uniqueness condition:

| Field | Obligation | Role |
|-------|------------|------|
| `tag : K → Msg → Tag` | — | MAC tagging function |
| `verify : K → Msg → Tag → Bool` | — | decidable verification |
| `correct` | `verify k m (tag k m) = true` | completeness |
| `verify_inj` | `verify k m t = true → t = tag k m` | **tag uniqueness** (Workstream C1, audit F-07) |

The `verify_inj` field is the information-theoretic analogue of strong
unforgeability (SUF-CMA) in the no-query setting: only the honestly
computed tag verifies. Without it, the abstract `INT_CTXT` predicate

```lean
def INT_CTXT (akem : AuthOrbitKEM G X K Tag) : Prop :=
  ∀ (c : X) (t : Tag),
    (∀ g : G, c ≠ (authEncaps akem g).1 ∨ t ≠ (authEncaps akem g).2.2) →
    authDecaps akem c t = none
```

cannot be discharged — an adversary could simply produce a distinct tag
that still verifies.

The Workstream C proof pipeline is:

1. **C2a (easy branch).** `authDecaps_none_of_verify_false`: if `verify`
   fails, `authDecaps` returns `none` by unfolding.
2. **C2b (key uniqueness).** `keyDerive_canon_eq_of_mem_orbit`: the
   decapsulation key depends only on the orbit of the ciphertext
   (unconditional — consequence of `canon_eq_of_mem_orbit`).
3. **C2c (main theorem).** `authEncrypt_is_int_ctxt`: a case split on
   `verify k c t`. The `false` branch uses C2a; the `true` branch uses
   `verify_inj` plus a hypothesis
   `hOrbitCover : ∀ c : X, c ∈ orbit G basePoint` to derive a contradiction
   with `hFresh`.

The orbit-cover hypothesis `hOrbitCover` encodes the semantic requirement
that **the ciphertext space equals a single orbit** — the intended model
throughout this document. It is carried as an explicit hypothesis rather
than a structural field on `AuthOrbitKEM` so that the KEM structure
remains maximally general; concrete instances (e.g. the Carter–Wegman
witness in `Orbcrypt/AEAD/CarterWegmanMAC.lean`) discharge it when their
ciphertext space is naturally transitive.

The concrete `MAC` witness (Workstream C4) is a Carter–Wegman
universal-hash MAC over `ZMod p × ZMod p`: `tag (k₁, k₂) m = k₁ * m + k₂`
with `verify k m t := decide (t = tag k m)`. `verify_inj` holds
by `of_decide_eq_true`. The witness is deliberately the
**simplest-possible** satisfying instance and is not intended for
production use; real-world MACs (HMAC, Poly1305) require a probabilistic
refinement of the MAC interface that is future work.

---

## 9. Lean 4 Formalization Plan

The complete Lean 4 formalization plan has been extracted into a dedicated
document suite for clarity and actionability. The plan covers the formal
verification of three headline results — correctness, the invariant attack
theorem, and the conditional security reduction (OIA ⟹ IND-1-CPA) — across
64 work units in 6 phases spanning 16 weeks (~132 engineer-hours).

### Documents

| Document | Contents |
|----------|----------|
| **[Master Plan](formalization/FORMALIZATION_PLAN.md)** | Vision, goals, scope, project architecture, module overview, Mathlib integration, roadmap summary, critical path analysis, coding conventions |
| [Phase 1 — Project Scaffolding](formalization/phases/PHASE_1_PROJECT_SCAFFOLDING.md) | Lean 4 project initialization, Mathlib dependency, directory structure, build verification (Week 1, 4 units, ~4.5h) |
| [Phase 2 — Group Action Foundations](formalization/phases/PHASE_2_GROUP_ACTION_FOUNDATIONS.md) | Orbit API, canonical forms, G-invariant functions, orbit partition theorem (Weeks 2–4, 11 units, ~28h) |
| [Phase 3 — Cryptographic Definitions](formalization/phases/PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md) | `OrbitEncScheme`, adversary model, IND-CPA game, OIA axiom (Weeks 5–6, 8 units, ~18h) |
| [Phase 4 — Core Theorems](formalization/phases/PHASE_4_CORE_THEOREMS.md) | Correctness proof, invariant attack theorem, OIA ⟹ IND-1-CPA reduction (Weeks 7–10, 16 units, ~33h) |
| [Phase 5 — Concrete Construction](formalization/phases/PHASE_5_CONCRETE_CONSTRUCTION.md) | S\_n action on bitstrings, HGOE instance, Hamming weight defense proof (Weeks 11–14, 12 units, ~26h) |
| [Phase 6 — Polish & Documentation](formalization/phases/PHASE_6_POLISH_AND_DOCUMENTATION.md) | `sorry` audit, docstrings, CI configuration, final verification (Weeks 15–16, 13 units, ~22.5h) |

### Summary

Each phase document includes detailed implementation guidance with Lean 4 code
sketches, internal dependency graphs, parallel execution plans, risk analysis
with mitigations, and precise exit criteria. The master plan provides the
architectural overview, Mathlib dependency map, critical path analysis, and
coding conventions that apply across all phases.

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

**Status (Phase 13 — formalized).** The algebraic scaffolding for all three
candidate paths is now machine-checked in
`Orbcrypt/PublicKey/{ObliviousSampling, KEMAgreement, CommutativeAction}.lean`:

- `OrbitalRandomizers`, `obliviousSample`, `oblivious_sample_in_orbit`,
  `refreshRandomizers`, `refresh_independent` — oblivious sampling with
  per-epoch refresh. The orbit-preserving, G-hiding `combine` operation
  is carried as a parameter with a closure hypothesis — finding a concrete
  instance is an **open problem** (see §10.1 of
  [`docs/PUBLIC_KEY_ANALYSIS.md`](docs/PUBLIC_KEY_ANALYSIS.md)).
- `OrbitKeyAgreement`, `sessionKey`, `kem_agreement_correctness` — two-party
  agreement via combined KEM keys. **Works, but is not true public-key**:
  both parties still require symmetric KEM material
  (`SymmetricKeyAgreementLimitation`).
- `CommGroupAction`, `csidh_exchange`, `csidh_correctness`, `CommOrbitPKE`,
  `comm_pke_correctness` — CSIDH-style framework. Unconditional correctness;
  **concrete hardness requires an isogeny-like commutative action** outside
  the S_n orbit setting.

The **fundamental obstacle** is formalised: non-commutativity of `G ≤ S_n`
is exactly what supports OIA hardness, but prevents DH-style exchange.
See [`docs/PUBLIC_KEY_ANALYSIS.md`](docs/PUBLIC_KEY_ANALYSIS.md) for the
full feasibility discussion and proof registry.

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
