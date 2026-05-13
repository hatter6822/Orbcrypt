<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Outer-automorphism gadgets as a CFI-alternative for GI-hard source instances

**Status.** Research-stage exploratory note. Not a formalisation
deliverable. The construction sketches below are *candidate*
constructions; their k-WL dimension, reduction tightness, and
canonical-form complexity are *not yet established*. Items marked
**(open)** are conjectural; items marked **(known)** are cited to the
literature or proven; items marked **(folklore)** are widely understood
in the relevant community but lack a precise canonical citation in the
sources this author has surveyed.

**Scope.** This note explores a single research direction: whether
Cai–Fürer–Immerman (CFI) graphs — the canonical source of GI-hard
instances used in the OIA → GI reduction of `Hardness.Reductions` and
the Petrank–Roth GI ≤ CE forward chain in `Hardness.PetrankRoth/` —
admit a useful generalisation via "outer-automorphism gadgets" derived
from finite groups with non-trivial outer automorphism group. The
direction was prompted by the observation that S_6's unique outer
automorphism is, structurally, the smallest non-trivial example of the
"locally invisible, globally constrained" symmetry that CFI gadgets
exploit.

**What this note does and does not claim.**

- It surveys the formal structure of CFI and identifies the precise
  point at which the ℤ/2 parity bit enters.
- It defines a candidate generalisation ("OA-gadget framework") that
  replaces ℤ/2 with a richer twist group A derived from Out(H) for
  a local-gadget group H.
- It catalogues candidate group families.
- It analyses three concrete construction sketches.
- It does **not** prove a k-WL lower bound better than CFI's. It does
  **not** claim a tightness improvement in the `ConcreteHardnessChain`
  ε bound. It does **not** claim a canonical-form-computation
  improvement.
- It identifies open problems and a literature-check list. The most
  honest summary is: this is a research thread worth one to two
  focused weeks of literature work and small-case experimentation
  before any Lean-side investment.

**Reading roadmap.** §§ 1–2 are background (motivation; CFI reviewed;
outer automorphisms reviewed). § 3 sets up the OA-gadget framework
abstractly. § 4 catalogues candidate groups. § 5 gives three concrete
construction sketches. § 6 collects analytical considerations. § 7
discusses Orbcrypt integration. § 8 is a comparison table. §§ 9–11 are
open questions, next steps, and references.

## 1. Motivation

### 1.1 Why CFI matters for Orbcrypt

Orbcrypt's headline security claim runs through the chain

```
ConcreteOIA(scheme, ε)
  ◄── concrete_hardness_chain_implies_1cpa_advantage_bound
ConcreteHardnessChain(GI-on-CFI, encoding, …)
  ◄── Hardness.Reductions (CE ≤ surrogate, GI ≤ CE, …)
GraphIsomorphism on Cai–Fürer–Immerman graphs
```

The *source instances* for the chain — the formal objects that we
assume are computationally hard to decide isomorphism for — are CFI
graphs. Two properties make CFI graphs the canonical source:

1. **Provable k-WL dimension lower bound (known).** For every k, there
   is a sequence of pairs (G_n, G_n') of CFI graphs of size O(n)
   such that the k-dimensional Weisfeiler–Leman algorithm fails to
   distinguish G_n from G_n' for all sufficiently large n
   (Cai–Fürer–Immerman 1992). The lower bound matches a wide class of
   refinement-based polynomial-time GI algorithms.
2. **Quasipolynomial tightness against Babai (known).** Babai's
   2^{O((log n)^c)} algorithm (Babai 2015) solves CFI in
   quasipolynomial time, but the constant in the exponent appears to
   be tight for the construction.

Together these make CFI the *largest* family for which we have
unconditional bounded-resource GI lower bounds. For Orbcrypt, the
"GI is hard on CFI" assumption is the conservative, well-studied
choice.

### 1.2 The question this note explores

A natural research question is whether there are *alternative*
GI-hard families with comparable lower-bound properties but
different structural features that might benefit cryptographic use.
Specifically:

- **Different attack surface.** CFI graphs have a known parity
  structure. Cryptanalytic effort focuses on that structure. An
  alternative family with a different algebraic skeleton might
  resist different attack classes.
- **Tighter reductions.** If the GI → CE reduction in
  `Hardness/PetrankRoth.lean` could be tightened for an alternative
  family — e.g., a smaller encoding blowup or a lower-degree
  invariant separation — then `concrete_hardness_chain_implies_*`
  bounds improve correspondingly.
- **Easier canonical-form arithmetic.** Orbcrypt's correctness path
  via `CanonicalForm.ofLexMin` is currently O(|G|) in the orbit size
  for the default fallback group; a gadget family whose canonical
  forms have nicer combinatorial structure could give a fast-path.

The S_6 outer automorphism is the originating example for the
framework: among all symmetric groups it has the unique non-trivial
outer twist (Out(S_6) = ℤ/2), making it the smallest concrete
instance of the "locally invisible, globally constrained" symmetry
that CFI gadgets exploit. The question pursued in this note is
whether scaling this principle to larger H with richer Out(H)
yields a CFI alternative.

### 1.3 What this note does and does not claim

This is a research note, not a result. The honest position is:

- The CFI parity bit is structurally an *abelian (ℤ/2)-twist*. There
  is a well-defined generalisation to richer twist groups, and the
  literature on mod-p CFI variants and "matrix CFI" shows that
  these generalisations are non-trivial.
- Whether richer twist groups *yield genuinely better cryptographic
  parameters* — as opposed to merely existing — is an open question.
- The S_6 outer automorphism specifically is too small to be
  cryptographically useful (Out(S_6) = ℤ/2; the construction collapses
  to a CFI variant). The methodological value is as a teaching
  example for the framework.
- The strongest plausible outcome of this thread is a *family* of
  CFI alternatives parametrised by (group, twist) pairs, with each
  pair potentially yielding a different tradeoff in the
  `ConcreteHardnessChain`.

## 2. Background

### 2.1 The Graph Isomorphism complexity landscape

The Graph Isomorphism (GI) problem is: given two graphs G, H on the
same vertex set, decide whether they are isomorphic. The headline
classical bounds:

- **Polynomial-time algorithms exist for many restricted classes
  (known).** Bounded-degree graphs (Luks 1982), bounded-genus graphs
  (Miller 1980), graphs with bounded eigenvalue multiplicity (Babai,
  Grigoriev, Mount), graphs of bounded treewidth, and many more.
- **Quasipolynomial in general (known).** Babai (2015) proved that GI
  is decidable in 2^{O((log n)^c)} time for some constant c. The
  best previously known bound was 2^{O(√(n log n))}
  (Babai–Luks–Zemlyachenko, 1980s).
- **Not known to be NP-hard, not known to be in P (known).** GI is
  one of a small number of problems in NP that are neither known to
  be in P nor known to be NP-complete; it is in NP ∩ coAM, ruling
  out NP-completeness under standard assumptions.
- **Hard against bounded-WL refinement (known).** The CFI
  construction gives an unconditional lower bound against the
  Weisfeiler–Leman algorithm hierarchy.

For Orbcrypt the relevant subset of this landscape is: we need
*conservative* hardness on a family of graphs, where "conservative"
means we have proven lower bounds against natural algorithm classes
(refinement, individualisation+refinement, low-degree polynomial
methods). CFI provides this; the open question this note explores is
whether richer constructions also do.

### 2.2 The Weisfeiler–Leman hierarchy

The k-dimensional Weisfeiler–Leman algorithm (k-WL) is a refinement
procedure on k-tuples of vertices. Starting from initial colours
that encode atomic relations (vertex equality, adjacency in subsets
of k coordinates), the algorithm iteratively refines colours by the
multiset of colours of "neighbouring" k-tuples (tuples that differ
in one coordinate). Two graphs G, H are *k-WL distinguishable* if at
fixed point the multiset of k-tuple colours differs.

Key facts (known):

- **1-WL = colour refinement.** It captures the multiset of degree
  sequences and iterates.
- **k-WL strictly increasing.** For each k there is a graph pair
  k-WL fails on but (k+1)-WL succeeds on.
- **Pebble-game characterisation.** k-WL distinguishability is
  equivalent to non-equivalence under the (k+1)-pebble bijective
  game, equivalently to inequivalence in (k+1)-variable
  first-order logic with counting (Immerman–Lander 1990,
  Cai–Fürer–Immerman 1992).
- **Capturing constraint:** k-WL invariants are polynomial-time
  computable in n^{O(k)} time. So polynomial-time refinement
  algorithms are roughly "k-WL for k = O(1)" or "k = O(log n)".

The CFI lower bound says: for every k, there are graphs where k-WL
fails. The OA-gadget question is whether *richer twists* also defeat
k-WL, and if so, at what k.

### 2.3 The CFI construction reviewed

Fix a connected base graph X = (V, E). For concreteness we describe
the standard case where X is d-regular with constant d ≥ 3; the
construction generalises to non-regular X by adjusting local gadget
sizes vertex-by-vertex.

**Local vertex-gadget.** For each v ∈ V of degree d, the local
gadget M(v) is the bipartite graph with:

- *Inner vertices:* the set W_v = {w ∈ {0,1}^d : w_1 + ··· + w_d ≡
  0 (mod 2)} of 2^{d-1} even-parity binary strings of length d.
  For d = 3, W_v = {000, 011, 101, 110}.
- *Outer vertices:* for each edge e incident to v, two outer
  vertices (e, 0) and (e, 1). Total 2d outer vertices.
- *Edges:* inner vertex w = (w_1, …, w_d) ∈ W_v is adjacent to outer
  vertex (e_i, w_i) for each i ∈ {1, …, d}, where e_1, …, e_d is a
  fixed enumeration of the edges incident to v.

**Local automorphism group.** Preserving the labelling of outer
vertices by edges (but not by parity), the automorphism group of
M(v) is

  Aut(M(v)) ≅ (ℤ/2)^{d-1},

the *even-parity port-swap group*: each even-cardinality subset
S ⊆ {1, …, d} acts by swapping (e_i, 0) ↔ (e_i, 1) for i ∈ S and
correspondingly relabelling inner vertices via w ↦ w ⊕ 𝟙_S. The
restriction to *even* cardinality is what keeps the action within
W_v (= even-parity strings). The "odd-cardinality" port swap is
**not** a local automorphism because it would map W_v to its
parity-odd complement, which is not part of M(v).

**Edge-twist gluing.** The CFI graph is parametrised by an
*edge-twist function* t : E → ℤ/2. For each edge e = {u, v} ∈ E,
glue the outer vertex (e, b) of M(u) to (e, b ⊕ t(e)) of M(v) — and
*identify* glued outer vertices, so that each edge of X contributes
exactly 2 outer vertices (one per gluing class) to the final graph.

Concretely: t(e) = 0 means "identify same-parity outers" (0 ↔ 0,
1 ↔ 1); t(e) = 1 means "identify opposite-parity outers" (0 ↔ 1,
1 ↔ 0).

For d-regular X with |V| = n, the resulting CFI(X, t) has
n · 2^{d-1} inner vertices and (n d) outer vertices (since
|E| = nd/2 and each edge contributes 2 outers after gluing), for a
total of O(n · 2^d) vertices.

**The CFI theorem (Cai–Fürer–Immerman 1992).** Let X be a connected
graph and t, t' : E(X) → ℤ/2 two edge-twist functions. Then:

- **Sum-parity invariant.** CFI(X, t) ≅ CFI(X, t') as unlabelled
  graphs iff ⊕_{e ∈ E} t(e) = ⊕_{e ∈ E} t'(e) ∈ ℤ/2.
- **Two isomorphism classes.** There are exactly two isomorphism
  classes of CFI graphs over X, distinguished by total parity.
- **k-WL lower bound (separator-number formulation).** For a
  family of base graphs X_n with separator number s(X_n) — the
  minimum size of a vertex cut splitting X_n into parts each of
  size ≤ |V_n|/2 — the twin pair (CFI(X_n, t_0), CFI(X_n, t_1))
  with t_0, t_1 of opposite parity is k-WL indistinguishable for
  k < s(X_n) − O(1).

  For 3-regular spectral expanders X_n, s(X_n) = Θ(|V_n|), yielding
  k-WL indistinguishable graph pairs of size O(n) at WL-dimension
  Ω(n). This is the unbounded-WL-dimension property that makes
  CFI the canonical GI-hard family.

(The separator-number bound is essentially Dawar–Holm–Kopczyński–
Toruńczyk's refinement of the original CFI 1992 treewidth-based
statement; for most natural base-graph families the two parameters
agree up to constants. The precise constant in the O(1) depends on
formalisation conventions.)

**Cohomological reading.** Edge-twists live in C^1(X, ℤ/2) ≅
(ℤ/2)^{|E|}, ℤ/2-valued 1-cochains on X. The local gadget's
automorphism group acts by *vertex-twists*: a function s : V → ℤ/2
acts on t by adding the coboundary ∂s, where (∂s)(e) = s(u) + s(v)
for e = {u, v}. Two edge-twists t, t' yield isomorphic CFI graphs
iff t' − t is in the image of ∂.

The image of ∂ is the *even-total-parity* subspace of C^1: for any
s, the function ∂s satisfies ⊕_e (∂s)(e) = ⊕_e (s(u_e) + s(v_e)) =
2 · ⊕_v deg(v) · s(v) ≡ 0 (mod 2). Conversely, any even-parity
edge-twist is achievable as some ∂s. Therefore

  {edge-twists} / {coboundaries} ≅ ℤ/2

with the isomorphism given by the total-parity map. This single bit
is the CFI isomorphism invariant.

**Structural reading for the OA-gadget framework.** The CFI
construction realises a non-trivial twist by an abelian group
A = ℤ/2 that is:

- *Invisible locally:* every individual gadget M(v) is graph-
  automorphic regardless of which t(e) is in use, because the
  local Aut = (ℤ/2)^{d-1} absorbs all coboundary contributions.
- *Detectable globally:* the total parity is the unique
  isomorphism invariant, computable only by summing across all
  edges of X (a global operation).

The OA-gadget framework (§ 3) asks: what if we replace A = ℤ/2
by a richer twist group?

### 2.4 Outer automorphisms and the symmetric-group exception

For a group G, the *inner automorphisms* are the conjugations
Inn(G) = {g ↦ x g x^{-1} : x ∈ G} ≅ G / Z(G). The *automorphism
group* Aut(G) contains Inn(G) as a normal subgroup; the quotient

  Out(G) := Aut(G) / Inn(G)

is the *outer automorphism group*. Outer automorphism classes
detect symmetries of G that are not implemented by conjugation.

Known facts relevant here:

- **Symmetric groups (Hölder c. 1895).** Aut(S_n) = Inn(S_n) for
  all n ≠ 2, 6. The case n = 6 is exceptional:
  Out(S_6) ≅ ℤ/2.
- **Cyclic groups.** Aut(ℤ/n) ≅ (ℤ/n)^×. Inn is trivial (cyclic
  groups are abelian, so all inner automorphisms are trivial).
  Therefore Out(ℤ/n) = (ℤ/n)^×.
- **Elementary abelian.** For V = (ℤ/p)^n, Aut(V) = GL_n(𝔽_p) and
  Inn(V) is trivial (V is abelian). So Out(V) = GL_n(𝔽_p), which
  has order ∏_{i=0}^{n-1} (p^n − p^i).
- **Simple groups (Schreier conjecture, known).** For every
  non-abelian finite simple group G, Out(G) is solvable. The
  Atlas of Finite Groups (Conway et al. 1985) tabulates Out for
  all 26 sporadic groups: most have |Out| ∈ {1, 2}; none has |Out|
  > 12.
- **Classical Lie-type groups.** For a simple group of Lie type
  G(𝔽_q) with q = p^f, the outer automorphism group decomposes
  schematically as Out = ⟨field⟩ × ⟨diagonal⟩ × ⟨graph⟩ (modulo
  fusion that depends on q). The *graph automorphisms* arise from
  symmetries of the Dynkin diagram and are the most exotic
  contributions.
- **Triality (known).** The Dynkin diagram D_4 is the unique
  simply-laced diagram with a non-trivial graph-automorphism group
  larger than ℤ/2: its automorphism group is S_3, the symmetric
  group on the three outer nodes of the diagram. For the
  associated simple group PΩ_8^+(q) (the orthogonal group of plus
  type in 8 dimensions), this S_3 lifts to S_3 ⊆ Out. Specifically:
  - For q = 2: Out(PΩ_8^+(2)) ≅ S_3 (pure triality; no field or
    diagonal contributions, because the field 𝔽_2 has trivial
    Galois group and PΩ_8^+(2) = Ω_8^+(2) has trivial centre at
    q = 2).
  - For q odd: Out(PΩ_8^+(q)) ≅ S_4 (S_3 triality combined with a
    diagonal automorphism of order 2 — see Atlas notation).
  - For q = 2^f with f > 1: Out includes the cyclic field
    automorphism of order f, multiplicatively contributing to
    |Out| = 6 · f.

  **Important disambiguation.** "D_4" in this note refers
  exclusively to the simply-laced Dynkin diagram of type D in
  rank 4 (associated with the orthogonal group SO_8), *never* to
  the dihedral group of order 8 (sometimes also written D_4 in
  group-theory notation). The dihedral group of order 8 has
  Out ≅ ℤ/2, no triality.

For the OA-gadget framework, the relevant quantity is the *size
and structure of A* — typically a subgroup or quotient of Out(H) —
for a local-gadget group H. Larger A allows encoding more
information per gadget (at the cost of larger local gadgets); the
*structure* of A (abelian vs non-abelian, cyclic vs non-cyclic)
determines what kind of cohomological invariant the global twist
class lives in.

### 2.5 The action-vs-abstract-group distinction

A transitive G-set is determined up to G-equivariant isomorphism by
the conjugacy class of a point stabiliser H ≤ G. Two transitive
G-actions on |X|-element sets are *equivalent* iff their stabilisers
are conjugate; *abstractly isomorphic G-sets* but inequivalent
actions occur when G has multiple non-conjugate subgroups of the
same index.

The S_6 outer automorphism is the unique-in-symmetric-groups
example where an automorphism of the *abstract group* witnesses the
non-conjugacy of two natural-looking subgroups: the natural S_5
(point stabiliser) and the exotic S_5 (transitive on 6 points). The
outer automorphism swaps the conjugacy classes; both classes have
index 6 in S_6, both giving transitive G-sets of size 6.

For larger n, S_n has *many* conjugacy classes of subgroups of any
given index, but they are not in general related by an automorphism
of S_n. The OA-gadget framework is specifically about the case where
some α ∈ Out(G) implements the twist, so that the "two sides" of the
twist are related by an *automorphism*, not merely a relabelling.

## 3. The outer-automorphism gadget framework

### 3.1 Definition: an OA-gadget

**Definition (OA-gadget).** Let H be a finite group and A a finite
group (the *twist group*). A *local OA-gadget for the pair (H, A)*
is data (M, I, ρ_H, ρ_A) where:

1. **Underlying structure.** M = (V_M, E_M) is a finite graph (or,
   more generally, a relational structure such as a labelled
   coloured multigraph, code over a fixed alphabet, etc.).
2. **Interface.** I ⊆ V_M is a non-empty subset of vertices,
   |I| ≥ 2 — the *ports* by which M will be attached to a base
   graph.
3. **Local symmetry action.** ρ_H : H → Aut(M) is a homomorphism
   such that ρ_H(H) acts trivially on I (every h ∈ H fixes every
   interface vertex pointwise). The H-action thus permutes only
   the *internal* vertices V_M \ I.
4. **Twist action on the interface.** ρ_A : A → Sym(I) is a
   homomorphism — the *twist representation* — satisfying the
   crucial outer-extension condition: for every α ≠ e_A in A, the
   permutation ρ_A(α) of I does **not** extend to any element of
   Aut(M).

Equivalently, condition (4) says that no graph automorphism of M
restricts to ρ_A(α) on the interface for α ≠ e_A. The twist class
is "outer to M": it lives in the cokernel

  ρ_A(A) ⊆ Sym(I) / restrict(Aut(M)).

We call (H, A) the *local symmetry data* and (M, I, ρ_H, ρ_A) its
*geometric realisation*. Different gadgets can realise the same
(H, A); the choice influences encoding efficiency but not the
abstract twist class structure.

**Remark on the "outer-extension" condition.** The intuition is
that ρ_A(α) is a "ghost" symmetry of the interface that the local
gadget M does not realise. When we glue together many copies of M
across a base graph, ghosts at neighbouring gadgets may cancel
each other out (yielding a global automorphism), or may compose to
a non-cancelling global obstruction. The CFI parity bit is exactly
this kind of global obstruction.

**Remark on relation to Out(H).** When ρ_A factors as a
homomorphism A → Out(H) followed by a fixed lifting Out(H) →
Sym(I), the OA-gadget is "outer in the strict sense": every
α ∈ A is an outer automorphism class of H. This is the source of
the framework's name. Constructions where A is *not* a quotient
of Out(H) (e.g., A acts via a free generating set) are also
admissible — the definition above is the more general one.

### 3.2 The CFI construction as a (ℤ/2)-twist

The standard CFI gadget fits the framework as follows:

- H = (ℤ/2)^{d-1} (local symmetry group),
- A = ℤ/2 (twist group),
- M = the bipartite gadget of § 2.3, with 2^{d-1} inner vertices
  and 2d outer (interface) vertices,
- I = the 2d outer vertices,
- ρ_H = the even-parity port-swap action (which fixes I pointwise
  in our convention; equivalently, ρ_H acts on inner vertices and
  on the *pairing* of outers, but in the formulation that
  identifies outer vertex pairs across edges, the local Aut fixes
  the global outer set),
- ρ_A = the simultaneous swap (e, 0) ↔ (e, 1) at every port.

**Key fact: local Aut(M) is exactly (ℤ/2)^{d-1}.** The local
automorphism group does *not* contain the parity-flip A: the
global parity swap (which would map all (e_i, 0) to (e_i, 1)) is
not a graph automorphism of M because the inner-vertex set is
constrained to even-parity strings only. An "all-port swap" would
require inner vertex w_1 + ··· + w_d to flip parity, contradicting
the W_v definition. This is precisely the outer-extension
condition (4) of § 3.1.

The CFI graph CFI(X, t) for an edge-twist t : E → ℤ/2 is then
obtained by the standard construction (§ 2.3), and the global
twist class ⊕_e t(e) ∈ ℤ/2 is the cohomological obstruction.

**Common confusion to avoid.** It is sometimes asserted that
Aut(M_CFI) = (ℤ/2)^{d-1} ⋊ ℤ/2 (a semidirect product realising
the parity swap as a local automorphism). This is **incorrect**
for the standard CFI gadget. The semidirect product would describe
the automorphism group of a *different* gadget M̃ in which inner
vertices are *all* of {0, 1}^d (both parities), in which case the
parity-swap is realised as an automorphism. M̃ is non-standard and
loses the CFI lower-bound property because the gadget then has no
"outer" obstruction. The standard CFI gadget keeps only
even-parity inner vertices precisely so that the parity swap
remains outer.

### 3.3 Generalisation to richer twist groups

The natural axes of generalisation are:

- **Abelian non-ℤ/2.** Take A = ℤ/p for primes p > 2, giving
  *mod-p CFI* (Fürer 2001 sketches this direction; Lichter et al.
  have worked on variants — **literature check needed**, see § 11).
  Each gadget encodes log_2 p bits.
- **Abelian, higher-rank.** Take A = (ℤ/p)^k. Each gadget encodes
  k · log_2 p bits, and the global twist class lives in
  H^1(X, (ℤ/p)^k).
- **Non-abelian, finite.** Take A = S_3 (triality), Q_8
  (quaternion), or a small simple group. Cocycle class becomes
  non-abelian Čech 1-cocycle modulo coboundary, valued in A.
- **Non-abelian, linear.** Take A = GL_n(𝔽_p) acting on the
  (ℤ/p)^n-vertex Cayley graph. Each gadget encodes O(n^2) bits.
- **Variable twist action.** A may act non-faithfully on I (some
  α ∈ A invisible at the interface level but visible at
  higher-order multi-gadget level). Useful for constructions where
  the "useful" portion of A is smaller than A itself.

**Construction template (general).** Given:

- a base graph X = (V_X, E_X);
- for each v ∈ V_X, a local OA-gadget (M_v, I_v, ρ_H^v, ρ_A^v);
- a *twist function* t : E_X → A (edge-twist, mirroring CFI);

build the graph OA(X, t) by:

1. For each v ∈ V_X, take a copy of M_v with interface I_v.
2. For each edge e = {u, v} ∈ E_X, partition I_u and I_v into
   "ports facing e" of equal size and glue them: identify port-at-e
   of M_u with ρ_A(t(e))(port-at-e of M_v) via the twist t(e) ∈ A.
3. The resulting graph OA(X, t) is the *gadget-glued realisation*.

**Cohomological reading.** Two twist functions t, t' yield
isomorphic OA(X, t), OA(X, t') iff they represent the same Čech
1-cohomology class in H^1(X, A), where:

- For A abelian, H^1(X, A) is an abelian group of dimension related
  to the cycle space of X.
- For A non-abelian, H^1(X, A) is a pointed set (no group
  structure), classifying *A-torsors* over X up to gauge
  equivalence by vertex-twist functions s : V_X → A acting by
  s(u) · t(e) · s(v)^{-1} on edges.

The "global twist class" controlling the GI distinguishability of
OA(X, t_0) vs OA(X, t_1) is the image in H^1(X, A) modulo any
remaining base-graph-automorphism action.

**When the construction yields a non-trivial family.** OA(X, t)
gives a non-trivial GI-hard family iff:

- H^1(X, A) has at least two distinct gauge-equivalence classes
  *and*
- Distinct classes correspond to non-isomorphic graphs
  (= the OA-gadget framework's defining property is sound for the
  specific gadget).

For CFI (A = ℤ/2, base graph X with non-trivial cycle space), the
first condition is automatic and the second is the CFI 1992
theorem. For richer A, both conditions must be re-verified.

### 3.4 Soundness conditions

For an OA-gadget construction to produce a genuinely new GI-hard
family — rather than reducing to CFI in disguise — the following
soundness conditions should be checked:

**(S1) Non-trivial twist orbit.** The orbit of the trivial twist
t ≡ e under the gauge action (boundary action) should be a
strict subset of all twist functions; otherwise every twist is
equivalent to trivial and the construction is rigid.

**(S2) k-WL indistinguishability.** For some k = k(|V_X|), the
graphs OA(X, t) and OA(X, t') for non-equivalent twist
functions t, t' should be k-WL indistinguishable. The benchmark
to beat: CFI achieves k = Ω(s(X)) for separator number s(X),
which equals Θ(|V_X|) for expander base graphs (see § 2.3).

**(S3) Algorithmic GI hardness.** Distinguishing OA(X, t) from
OA(X, t') should be at least as hard as a problem of known
difficulty (Group Isomorphism, Bilinear Form Equivalence, Tensor
Isomorphism). Without this, the construction might be easier
than CFI rather than harder.

**(S4) Permutation-code reduction friendliness.** For Orbcrypt
specifically, the construction should compose with
`Hardness.PetrankRoth/`'s GI ≤ CE reduction, ideally with a tighter
encoding than the generic CFI case (smaller blowup, fewer auxiliary
markers).

(S1)–(S2) are the analogue of the CFI lower-bound theorem and are
the main technical question. (S3) is a meta-soundness check
preventing self-deception. (S4) is the Orbcrypt-specific
desideratum.

### 3.5 What the framework is not

The framework deliberately does **not** propose:

- *A primitive based directly on guessing α ∈ Out(H).* The "twin
  action distinguishing" assumption (informally: given samples,
  decide whether the action is the natural one or the α-twisted
  one) collapses to low-degree invariant computation in most
  natural cases. The OA-gadget framework hides the twist inside a
  graph isomorphism instance rather than exposing it as a direct
  guess-the-action problem; see § 6.1 below for the k-WL framing.
- *A replacement for Orbcrypt's hidden-group encryption scheme.*
  The OA-gadget construction is a *source-instance* family for the
  GI / CE reductions, not an encryption primitive.
- *A claim that S_6's outer automorphism, in isolation, yields a
  new construction.* S_6 is the pedagogical example; the
  cryptographic question is whether scaling H and A produces useful
  parameters.

## 4. Candidate group families

This section catalogues finite-group families with non-trivial
Out(H), with rough notes on suitability as OA-gadget bases. The
selection criteria are:

1. **|A| = |Out(H)|** — larger encodes more bits per gadget;
2. **A's permutation representation on natural H-sets** — must act
   non-trivially on interface to be detectable globally;
3. **Computability of α-actions** — must be efficiently applicable
   at gadget-construction time;
4. **Reduction friendliness** — H should have efficient invariant
   theory (canonical forms, generating sets) usable by
   `Hardness.PetrankRoth/`.

### 4.1 S_6 (Out ≅ ℤ/2, the prototype)

- **|A| = 2.** One bit per gadget.
- **Interface action.** The natural 6-element set; α swaps the
  natural and exotic S_5 subgroups (point stabilisers).
- **Computability.** Trivial; α is given by a 720-element table or
  by Sylvester's synthematic-totals construction (Sylvester 1844;
  see also Howard–Millson–Snowden–Vakil 2008 for the modern
  algebraic-geometric description).
- **Verdict.** A literal CFI variant with a more elaborate inner
  gadget. Same 1-bit per-gadget capacity as standard CFI; no
  obvious parameter advantage. Useful as a pedagogical worked
  example and for unit-testing the framework, *not* as a
  production source instance.

### 4.2 Triality groups: PΩ_8^+(q) (Out ⊇ S_3)

- **|A| = 6 · |⟨field⟩| · |⟨diagonal⟩|.** For q = 2 the field
  automorphism is trivial and |Out| = 6 (pure triality); for q = p^f
  with f > 1, |Out| grows.
- **Interface action.** The natural 8-dimensional spin
  representation has three "triality-related" 8-dimensional
  representations (vector, half-spin, other half-spin); A = S_3
  permutes these. Each triality automorphism gives a different
  identification of the 8-dim modules.
- **Computability.** Non-trivial but well-understood; the triality
  automorphism is described explicitly in terms of octonion
  multiplication or D_4 Dynkin diagram symmetry. GAP implements
  this for small q.
- **Verdict.** The most algebraically interesting candidate. Yields
  log_2(6) ≈ 2.58 bits per gadget — roughly 2.6× the per-gadget
  capacity of CFI. The non-abelian twist (S_3) introduces a
  non-commutative cocycle, which is *qualitatively* new versus CFI.
  Worth a focused construction sketch (§ 5.2).

### 4.3 Elementary abelian (ℤ/p)^n (Out = GL_n(p))

- **|A| = |GL_n(p)| = ∏_{i=0}^{n-1} (p^n - p^i).** For p = 2, n = 4
  this is 20160 ≈ 2^{14.3}; for n = 8 it is 2^{49}; grows rapidly.
- **Interface action.** Any natural H-action has H acting by
  translation; A = GL_n(p) acts on the lattice of subgroups, so on
  the conjugacy classes of point stabilisers — i.e., on the
  Grassmannian of subspaces of (𝔽_p)^n.
- **Computability.** GL_n(p) is efficiently represented (matrices);
  every α ∈ A is a single matrix.
- **Verdict.** Potentially the largest per-gadget capacity (~n² bits
  for GL_n(p), p constant). The "twist" is the matrix CFI of the
  literature (Schweitzer and others — **literature check needed**).
  *Caveat:* the regular action of (ℤ/p)^n has trivial point
  stabiliser, so the interface action is the full G/{e} = G — every
  α twist is a graph isomorphism, so "twist class" is degenerate.
  To get a non-degenerate construction the gadget must use a
  *non-regular* H-action, where some α ∈ GL_n(p) genuinely fails to
  extend. This corresponds to using a subgroup H' < H and the
  H-set H/H' with non-conjugate-image stabilisers.

### 4.4 Classical groups PSL_n(q)

- **|A|.** For PSL_n(q) with q = p^f, Out has order (n, q-1) · f ·
  ε where ε = 2 if n ≥ 3 (graph automorphism) and 1 otherwise. For
  PSL_3(4), |Out| = (3, 3) · 1 · 2 = 6 = S_3.
- **Interface action.** The natural projective space ℙ^{n-1}(𝔽_q)
  carries the PSL_n(q) action; the graph automorphism g ↦ (g^{-1})^T
  (inverse-transpose) gives a duality between points and hyperplanes
  of ℙ^{n-1}.
- **Computability.** Explicit; matrix-based.
- **Verdict.** A middle ground between (ℤ/p)^n (large A, abelian)
  and PΩ_8^+ (small A = S_3, non-abelian). Worth comparing to
  matrix CFI to determine whether the graph automorphism gives
  additional structure beyond the field automorphism.

### 4.5 Sporadic groups

- **|Out|.** Most sporadics have |Out| ∈ {1, 2}; the largest among
  the 26 sporadic groups is |Out(HS)| = |Out(McL)| = |Out(He)| = 2.
- **Interface action.** Specific to each group; usually arises from
  module/lattice automorphisms.
- **Verdict.** Sporadic groups are too small (largest is the
  Monster at ≈ 8 · 10^{53} elements, but |Out(M)| = 1) and lack
  parametric families. Not promising for OA-gadget construction at
  scale.

### 4.6 Selection table

| Family            | |H|        | |A| = |Out(H)| | A structure | Bits/gadget | Verdict                  |
|-------------------|------------|----------------|-------------|-------------|--------------------------|
| S_6               | 720        | 2              | ℤ/2         | 1           | Pedagogical only         |
| PΩ_8^+(q), q=2    | 174182400  | 6              | S_3         | 2.58        | **Worth a sketch (§5.2)**|
| (ℤ/p)^n, p=2,n=8  | 256        | 20158709760    | GL_8(2)     | ≈ 49        | **Worth a sketch (§5.3)**|
| PSL_3(4)          | 20160      | 6              | S_3         | 2.58        | Possible mid-tier        |
| Sporadic (top)    | varies     | 1 or 2         | ℤ/2 or {e}  | 0–1         | Not promising            |

The two starred families anchor the construction sketches in § 5.

## 5. Concrete construction sketches

Each sketch below specifies (a) the local gadget M, (b) the
attachment pattern to a base graph X, (c) the twist semantics, and
(d) the expected properties. None of these is a fully analysed
construction; they are *candidates* for the focused literature
check and small-case experimentation listed in § 10.

### 5.1 Sketch A: Synthematic S_6 gadgets (CFI-equivalent baseline)

**Local gadget M_A.** Vertices: 6 "point" vertices labelled
{1,…,6}, 15 "duad" vertices labelled by 2-subsets, 15 "syntheme"
vertices labelled by 3-duad partitions, 6 "pentad" vertices
labelled by synthematic totals. Edges:

- point i — duad d iff i ∈ d (a 2:5 bipartite structure);
- duad d — syntheme s iff d ∈ s (each syntheme contains 3 duads);
- syntheme s — pentad p iff s ∈ p (each pentad contains 5
  synthemes).

The graph M_A has 42 vertices, with Aut(M_A) ≅ S_6 ⋊ ℤ/2 = Aut(S_6)
acting via the natural permutation on each layer (points, duads,
synthemes, pentads). The outer automorphism α ∈ Out(S_6) realises as
the graph automorphism swapping the "point layer" with the "pentad
layer" (both 6-element) and the "duad layer" with the "syntheme
layer" (both 15-element).

**Interface I_A.** The 6 point vertices, or alternatively the 6
pentad vertices. The choice of interface "names" the twist class.

**Attachment to base X.** For each vertex v of base X with degree 6
(or padded to degree 6), attach M_A at v identifying v's 6
neighbours with I_A.

**Twist t : V_X → ℤ/2.** Twist t(v) = 1 means "identify M_A's pentad
layer with v's neighbours" rather than "identify the point layer."

**Expected properties.**

- *Capacity:* 1 bit per gadget — *identical* to standard CFI.
- *k-WL behaviour:* Conjecturally identical to CFI (both bounded by
  the cohomology of X with ℤ/2 coefficients).
- *Encoding size:* 42 vertices per base vertex (vs ≈ 4 + 2·d for
  standard CFI of degree d). *Larger than CFI*, not smaller.
- *Verdict:* Useful as a *worked example* and as a sanity check
  that the OA-gadget framework reproduces CFI as a special case. Not
  a candidate for production. **(open)** whether the synthematic
  structure provides any algorithmic distinguishing advantage over
  bare CFI.

### 5.2 Sketch B: Triality gadgets (S_3-twist refinement)

This is the construction the thread should focus on first.

#### 5.2.1 Algebraic data

Let H = PΩ_8^+(2), the simple subquotient of the orthogonal group
of plus type on an 8-dimensional quadratic space V over 𝔽_2.

Concrete numerical data:

- |H| = |PΩ_8^+(2)| = 174,182,400.
- Out(H) ≅ S_3 (pure triality at q = 2; cf. § 2.4).
- V is the *natural module* (8-dim).
- S_+, S_- are the two *half-spin modules*, each 8-dimensional.
- Triality cyclically permutes the three modules.

#### 5.2.2 The triality geometry

Inside the projective geometry of V are three Ω_8^+(2)-orbit
families, each of cardinality 135 (at q = 2):

- **Points** P: 1-dimensional totally singular subspaces of V.
- **α-planes** A_α: one of the two families of 4-dimensional
  maximal totally singular subspaces (Witt index of V is 4).
- **β-planes** A_β: the other such family.

Numerical verification (q = 2): the number of singular 1-spaces in
a non-degenerate 8-dim plus-type quadratic space over 𝔽_q is
(q^4 − 1)(q^3 + 1) / (q − 1); at q = 2, this is 15 · 9 / 1 = 135.
The number of maximal singular 4-spaces is
2 · (q + 1)(q^2 + 1)(q^3 + 1) (the factor 2 for plus type splitting
into α/β), giving 2 · 3 · 5 · 9 = 270 at q = 2, hence 135 per
family.

The triality outer automorphism σ ∈ Out(H) cyclically permutes
P → A_α → A_β → P. The full Out = ⟨σ, τ⟩ ≅ S_3, where τ is an
involution swapping A_α ↔ A_β while fixing P.

#### 5.2.3 Local gadget M_B

Define the vertex set

  V_M_B = P ⊔ A_α ⊔ A_β,

the disjoint union of the three triality classes, of cardinality
3 · 135 = 405.

Edges encode the natural incidence relations:

- **P–A_α edges.** Point p ∈ P is connected to α-plane π ∈ A_α
  iff p ⊂ π (the 1-space is contained in the 4-space).
- **P–A_β edges.** Symmetric: p ∼ π iff p ⊂ π for π ∈ A_β.
- **A_α–A_β edges.** Two maximal isotropic subspaces of opposite
  types π_α ∈ A_α and π_β ∈ A_β intersect in a subspace of
  *odd* dimension (a classical fact about plus-type quadratic
  spaces in characteristic 2). The natural triality-invariant
  edge relation is

    π_α ∼ π_β  ⟺  dim(π_α ∩ π_β) = 3.

This edge relation is preserved by Ω_8^+(2), and the cyclic
relabelling P ↔ A_α ↔ A_β (under triality σ) preserves it as well.

Therefore Aut(M_B) ⊇ Ω_8^+(2) ⋊ S_3, an extension of the local
symmetry by the triality twist. In fact, since the three triality
classes are isomorphic as Ω_8^+(2)-sets only up to outer
automorphism, the full Aut(M_B) equals this extension.

**Combinatorial verification.** Each point p ∈ P lies in
(q^3 + 1)(q + 1)/2 = 9 · 3 / 2 = ... hmm, the count of α-planes
through a point should be q + 1 = 3 for plus type in dimension 8 at
q = 2... actually we have a precise formula: |{π ∈ A_α : p ⊂ π}| =
q^2 + 1 = 5 at q = 2 (the q-analog of the number of lines through
a point in projective 3-space). So each point has degree 5 in
P–A_α and degree 5 in P–A_β, total 10 within those layers.
Edge-counts can be cross-checked in GAP.

#### 5.2.4 Interface I_B

Two natural choices:

- *Minimal interface (|I| = 3):* one representative of each
  triality class, with the S_3 twist permuting them. This is the
  smallest non-trivial interface but allows only |S_3| = 6 distinct
  configurations.
- *Layer-balanced interface (|I| = 3k for some k):* k points from
  each of P, A_α, A_β, with the S_3 twist permuting the three
  k-blocks. More flexible and allows interfacing to base graphs of
  varying degree.

We use the layer-balanced choice with k = 5 (= 15 interface
vertices per gadget), corresponding to "5 distinguished objects of
each triality class." This matches a natural choice driven by the
incidence structure: pick π_α^* ∈ A_α arbitrarily; let I_B^P = the
5 points contained in π_α^*; let I_B^α = the 5 α-planes containing
some fixed line of π_α^*; let I_B^β = the 5 β-planes intersecting
π_α^* in dimension 3. By symmetry the resulting interface is
S_3-invariant.

|I_B| = 15.

#### 5.2.5 Attachment to base X

Each base-graph vertex v of degree d_v is padded to degree 15
(replicate edges with auxiliary marker vertices if d_v < 15;
multi-edge gluing if d_v > 15). The 15 incident edges at v are
partitioned into 3 blocks of 5; block i is identified with
I_B^{class i} of M_B for class i ∈ {P, α, β}.

#### 5.2.6 Twist function t : E_X → S_3

Each edge e = {u, v} ∈ E_X carries a twist t(e) ∈ S_3. The
attachment uses ρ_A(t(e)) ∈ Sym(I_B) when gluing M_u to M_v at e:
i.e., apply the S_3 permutation t(e) to the three blocks before
identifying.

#### 5.2.7 Cocycle structure

Two twist functions t, t' : E_X → S_3 yield isomorphic OA(X, t) ≅
OA(X, t') iff they represent the same class in the *non-abelian
Čech 1-cohomology* H^1(X, S_3) — the pointed set of S_3-torsors
over X modulo gauge equivalence by vertex-twists s : V_X → S_3
acting on edges by s(u) · t(e) · s(v)^{-1}.

|H^1(X, S_3)| depends on X. For X with first Betti number b_1(X) =
|E| − |V| + 1 (assuming X connected), a rough bound is

  |H^1(X, S_3)| ≤ |S_3|^{b_1(X)} = 6^{b_1(X)}.

For X = a 3-regular graph on n vertices, b_1(X) = n/2 + 1, giving
~6^{n/2} twist classes. (The actual count is somewhat smaller due
to non-trivial centraliser orbits, but this is the rough order.)

#### 5.2.8 Expected properties

- **Capacity per gadget.** log_2 |S_3| = log_2 6 ≈ 2.58 bits.
- **k-WL behaviour (open).** Conjecturally Ω(s(X)) by the same
  separator-number argument as CFI, with the S_3 cocycle replacing
  the ℤ/2 parity. The rigorous proof requires a non-abelian
  pebble-game analysis; § 6.1 discusses the heuristic.
- **Encoding size.** |V_{M_B}| = 405 vertices per gadget. For a
  3-regular base graph X with |V_X| = n, the total gadget-glued
  graph has 405 n vertices (ignoring interface identifications,
  which save O(n) vertices). Bits-per-vertex ratio: ~2.58 / 405
  ≈ 0.0064.
  
  *Comparison to CFI:* CFI on the same base X has ~2^{d-1} · n =
  4n vertices for d = 3; bits-per-vertex ratio ~1 / 4 = 0.25.
  CFI wins by ~40× on density.

- **Reduction friendliness (open).** The Petrank–Roth marker-
  forcing argument should adapt to triality gadgets, but the
  forcing pattern needs to be S_3-equivariant. This is a
  potentially substantial rewrite of `Hardness/PetrankRoth/
  MarkerForcing.lean`.

- **Verdict.** Despite the density disadvantage, Sketch B remains
  the most plausible Pareto-improvement on CFI *qualitatively*: it
  introduces a genuinely non-abelian cohomological structure, which
  may resist different algorithmic attacks than CFI's parity.
  Worth one focused week of literature check + small-case
  experiments (§ 10) to validate the k-WL claim.

### 5.3 Sketch C: GL_n-twist (matrix CFI) gadgets

#### 5.3.1 Algebraic data

Take H = (ℤ/p)^n with p a small prime (p = 2 throughout for
concreteness). The local gadget hosts H by translation and admits
a GL_n(𝔽_p)-twist on the interface that does not extend to graph
automorphisms.

|H| = 2^n. Aut(H) = GL_n(𝔽_2). Inn(H) = trivial (H is abelian).
So Out(H) = GL_n(𝔽_2).

|GL_n(𝔽_2)| at small n:
- n = 4: 20,160 ≈ 2^{14.3}
- n = 6: 20,158,709,760 ≈ 2^{34.2}
- n = 8: 5,348,063,769,211,699,200 ≈ 2^{62.2}

#### 5.3.2 Local gadget M_C (labelled Cayley graph)

Define M_C as the *labelled directed Cayley graph*
Cay(H, {e_1, …, e_n}) where e_1, …, e_n is the standard basis of
H = (ℤ/p)^n. Concretely:

- Vertex set V_M_C = H, of cardinality p^n.
- Directed edges: for each v ∈ H and each i ∈ {1, …, n}, a directed
  edge v → v + e_i, *labelled with i*.

**Local automorphism group.** Preserving the edge labelling
(reading "label-i edge ↔ direction along e_i basis vector"):

  Aut(M_C, labels) = H,

acting by translation only. Different translations preserve the
label structure because v ↦ v + h sends a label-i edge (u → u + e_i)
to another label-i edge (u + h → u + h + e_i). No other map
preserves all labels simultaneously.

(For p = 2 and *unlabelled* edges, M_C reduces to the n-cube
graph K_2^n, whose Aut is (ℤ/2)^n ⋊ S_n via translation +
coordinate permutation. The edge labelling breaks the coordinate-
permutation symmetry, leaving just (ℤ/2)^n.)

**Encoding labels in undirected, unlabelled graphs.** Standard
labelled-graph-to-graph reductions: replace each labelled directed
edge (v → u, label i) with a small auxiliary gadget — e.g., a path
v—m_i—u where m_i is a "label-i marker" vertex of unique colour
(or attached to a colour-i ladder graph). This blows up the
vertex count by a factor of O(n) but preserves the labelled
automorphism structure as the unlabelled-graph automorphism
structure.

#### 5.3.3 Interface I_C

Take I_C = V_M_C = H itself (size p^n). The twist will act on the
entire vertex set, which is also the interface.

(Alternatively, take I_C = {e_1, …, e_n} — the "anchor" basis
vectors. This reduces |I_C| from p^n to n at the cost of less
twist flexibility.)

#### 5.3.4 Twist group A and twist action

Take A = GL_n(𝔽_p) acting on I_C = H by linear maps:
ρ_A(g)(v) = g · v for g ∈ A, v ∈ H.

**Verification of the outer-extension condition.** For g ≠ I_n,
the linear map ρ_A(g) does not preserve the label-i edges: if g
sends e_i to ∑_j a_{ji} e_j, then the directed edge v → v + e_i
(labelled i) maps to g·v → g·v + g·e_i = g·v + ∑_j a_{ji} e_j,
which is *not* a label-i edge unless g · e_i = e_i (i.e., g fixes
e_i). Therefore for generic g, ρ_A(g) cannot be lifted to a
labelled-graph automorphism of M_C, satisfying the outer-extension
condition.

The stabilizer of the entire basis {e_1, …, e_n} under GL_n is the
trivial subgroup. So the *effective twist group* (= Aut on I_C
modulo image of Aut(M_C)) is the full GL_n(𝔽_p).

#### 5.3.5 Attachment to base X

Each base-graph vertex v ∈ V_X of degree d_v is padded to degree
p^n. The p^n incident edges are identified bijectively with V_M_C
(= H).

(For small n this can be exponentially demanding on the base
graph's degree; for cryptographic applications n = 4 (degree 16)
or n = 6 (degree 64) is more practical.)

#### 5.3.6 Twist function and cocycle structure

Twist function t : E_X → A = GL_n(𝔽_p). For each edge e = {u, v},
glue M_u and M_v at e by identifying ports with a relative twist
ρ_A(t(e)).

Two twist functions t, t' yield isomorphic OA(X, t) ≅ OA(X, t')
iff they differ by a vertex-twist coboundary in the non-abelian
sense: t'(e) = s(u) · t(e) · s(v)^{-1} for some s : V_X → GL_n.

The "global twist class" lives in the non-abelian Čech cohomology
H^1(X, GL_n(𝔽_p)), which is a pointed set of cardinality bounded
by |GL_n|^{b_1(X)} / |GL_n|^{|V_X| − 1}.

#### 5.3.7 Expected properties

- **Capacity per gadget.** log_2 |GL_n(𝔽_p)| ≈ n^2 log_2 p bits.
  For p = 2, n = 4: ~14 bits; n = 6: ~34 bits; n = 8: ~62 bits.

- **Encoding size.** |V_M_C| = p^n vertices per gadget (after the
  label-stripping reduction, O(n · p^n) per gadget). For p = 2,
  n = 8: 256 inner + auxiliary ≈ 2048 total per gadget. Total
  graph on a base of n_X vertices: ~2048 · n_X = O(n_X) vertices,
  carrying ~62 · n_X bits.

  *Bits-per-vertex ratio at n = 8:* ~62 / 2048 ≈ 0.030. This is
  *worse* than CFI's 0.25 but *better* than Sketch B's 0.0064.

- **k-WL behaviour (open / likely subsumed by literature).** This
  is the "matrix CFI" or "linear CFI" of the descriptive-
  complexity literature; specific authors to check (in priority
  order): Lichter, Pago, Schweitzer, Berkholz, Holm. § 11 lists
  what to read.

- **Reduction friendliness.** O(n^2) bits per gadget allows fewer
  gadgets for the same total information, which translates to
  smaller Petrank–Roth-encoded codes. *Potentially* a real
  cryptographic improvement over CFI — *if* the matrix-CFI
  k-WL lower bound is established and at least matches CFI's.

- **Verdict.** The construction is parameter-efficient but almost
  certainly overlaps with the matrix-CFI literature. Spend Week 1
  on the literature check (§ 11) to determine whether this is a
  novel construction or a re-derivation of known work. If known,
  the OA-gadget framework contribution is the *unification with
  S_3 / triality* and the Orbcrypt-specific Petrank–Roth
  integration, not the construction itself.

### 5.4 What none of these sketches yet establish

For each of A, B, C the *lower bound argument* — "this construction
defeats k-WL up to dimension k(n)" — is the central technical
question and is not addressed by the construction alone. The CFI
lower-bound proof uses a pebble-game argument on the base graph X;
analogous arguments should adapt to S_3 and GL_n twists, but the
non-abelian cocycle structure of B and the linear-algebraic
structure of C introduce genuine new technical content.

The proposed small-case experiments (§ 10) are exactly to *check*
that constructions B and C are k-WL hard for small k on small base
graphs, before committing to a lower-bound proof attempt.

## 6. Analytical considerations

### 6.1 k-WL distinguishability: the central question

#### 6.1.1 What CFI achieves, recap

The CFI lower bound (Cai–Fürer–Immerman 1992, refined by Dawar et
al.): for base graphs X with separator number s(X), the twin pair
(CFI(X, 0), CFI(X, δ_e)) is k-WL indistinguishable for k <
s(X) − O(1). For 3-regular expanders X_n on n vertices,
s(X_n) = Θ(n), giving k-WL indistinguishable graphs of size O(n)
at WL-dimension Ω(n).

The proof structure: characterise k-WL distinguishability via the
*(k+1)-pebble bijective game* (Hella 1996, Immerman–Lander 1990).
The Spoiler tries to detect the difference between G_0 and G_1;
the Duplicator tries to hide it. Distinguishability at the k-WL
level corresponds to the Spoiler having a winning strategy with
≤ k pebbles per side.

For CFI, the Duplicator's winning strategy with k − 1 pebbles
(when k − 1 < s(X)) consists of:

1. Maintaining a *parity bookkeeping* across the pebbled vertices.
2. Using the (ℤ/2)-cocycle structure to absorb any local Spoiler
   probe by a coboundary, leaving the global parity intact.
3. Refusing to commit to the global parity until the Spoiler has
   "pebbled a separator" — which requires k ≥ s(X) pebbles.

The key step is (2): the Duplicator can always reorganise the
parity assignment along *any path* in X that doesn't cross the
pebbled set, because the (ℤ/2) action on the cycle space of
X \ {pebbles} is free.

#### 6.1.2 Generalising to OA-gadgets

For an OA-gadget construction OA_A(X, t) with twist group A, the
analogous Duplicator strategy with k − 1 pebbles consists of:

1. Maintaining an *A-valued bookkeeping* across the pebbled
   vertices.
2. Using the (non-abelian, generally) Čech 1-cocycle structure to
   absorb local Spoiler probes by coboundaries.
3. Refusing to commit to the global twist class until the Spoiler
   has pebbled a separator.

**Critical question:** does step (2) go through for non-abelian A?

For *abelian* A (e.g., A = ℤ/p), the proof is essentially
mechanical: replace "parity sum" with "sum in A," and the rest
follows. The k-WL dimension lower bound generalises to k <
s(X) − O(1), with the implicit constant in O(1) depending mildly
on log |A|.

For *non-abelian* A (e.g., A = S_3), step (2) is more delicate:

- The "coboundary" action is now s(u) · t(e) · s(v)^{-1}, with
  matrix multiplication rather than addition.
- The Duplicator's bookkeeping must reconcile *non-commuting*
  twists along different paths through the same vertex.
- The cycle space of X with A-coefficients is the *non-abelian
  fundamental group* π_1(X), not the abelian H_1(X). Free
  movement of the cocycle along π_1(X)-loops requires A to be
  abelian, in general.

This means: the standard CFI lower-bound proof *might not generalise
directly* to non-abelian twist groups. The genuine open question is
whether a modified pebble-game argument can salvage the lower
bound for non-abelian A.

#### 6.1.3 Heuristic Duplicator strategy for Sketch B (S_3-twist)

For Sketch B (A = S_3), a candidate Duplicator strategy:

1. Fix a spanning tree T ⊆ X (so |T| = |V_X| − 1 edges).
2. Maintain a function s : V_X → S_3 (the "gauge" along T).
3. For pebbled vertex u with assigned s(u) and pebbled vertex v
   with assigned s(v), reconcile t(e_{uv}) = s(u)^{-1} · s(v) for
   any edge e on the tree-path from u to v.
4. Non-tree edges (chords) carry "intrinsic" twist information
   that the Duplicator cannot absorb by gauge transformations —
   these are precisely the cycle-space contributions.

The Spoiler wins iff he can pebble enough vertices to expose a
"non-trivial chord cycle" (= a cycle in X whose total twist is
non-identity in S_3). By a counting argument, the number of
chords needed is at least s(X) − O(1) (analogous to CFI), so the
Duplicator wins with < s(X) pebbles.

**Status.** This argument is *plausible* but not a proof. The
delicate step is whether the gauge function s can always be
extended consistently as the Spoiler reveals more vertices — for
non-abelian S_3, consistency requires checking *all* loops in the
revealed subgraph, not just generators. **(open)**

#### 6.1.4 Heuristic Duplicator strategy for Sketch C (GL_n-twist)

For Sketch C (A = GL_n(𝔽_p)), the Duplicator's bookkeeping is
matrix-valued. The cocycle structure is essentially the same as
S_3 (non-abelian cohomology), but with a much larger group.

**Plausible bound.** k-WL indistinguishable for k ≤ s(X) − O(1),
with the implicit constant depending on log |GL_n| = O(n^2 log p).
For p = 2, n = 8, the constant is ~62, suggesting a "shift" of
~62 in the WL-dimension required to distinguish.

This is the *standard heuristic* for matrix-valued lower bounds —
the abelian (ℤ/p^k) version is essentially solved in the mod-p
CFI literature; the GL_n version is the natural non-abelian
generalisation.

**Status.** Almost certainly settled in the matrix-CFI literature
(Lichter, Pago, Schweitzer). Literature-check is the priority
action.

#### 6.1.5 The pebble-game obstruction to easy generalisation

The fundamental difficulty with non-abelian A is the **failure of
commutativity for path-independent reconciliation**:

- For abelian A, the total twist along a closed loop in X depends
  only on the *sum* of edge-twists, which is path-independent.
- For non-abelian A, the total twist along a loop is the *product*
  in A, which depends on path order. Different orderings of the
  same loop give *conjugate* but not necessarily equal results.

This means a Duplicator strategy based purely on local cycle-space
bookkeeping (sufficient for abelian A) is insufficient for
non-abelian A. The Duplicator must additionally track *which
conjugacy class* the loop-twist lies in.

**Possible resolution.** For non-abelian A with small *commutator
subgroup* [A, A], the conjugacy-class tracking can be quotiented
to abelian information at the cost of |[A, A]| bits per loop. For
S_3, [S_3, S_3] = A_3 ≅ ℤ/3, so the obstruction is 3 conjugacy
classes (the abelianisation is S_3 / A_3 ≅ ℤ/2). For GL_n, [GL_n,
GL_n] = SL_n, which is large.

**Net effect.** Sketch B (S_3) has a small commutator subgroup;
the non-abelian obstruction is mild and the CFI lower bound likely
generalises with a small constant penalty. Sketch C (GL_n) has a
large commutator subgroup; the non-abelian obstruction is more
severe.

**(All of § 6.1.3–6.1.5 is conjectural and would require either a
rigorous pebble-game proof or an experimental verification on
small base graphs to validate.)**

### 6.2 Pebble-game / Counting-logic characterisation

k-WL distinguishability is characterised by inequivalence in the
(k+1)-variable counting logic C^{k+1} (Cai–Fürer–Immerman 1992,
Immerman–Lander 1990). The OA-gadget question can therefore be
phrased model-theoretically: do the OA-gadget twin pairs require
*non-elementary* sentences in C^{k+1} to distinguish?

For non-abelian twist groups A, this connects to the literature on
"counting with non-abelian groups" — e.g., Furst–Saxe–Sipser,
Razborov, Smolensky on AC^0 with non-abelian gates. The connection
is *conjectural* and represents a possibly fruitful angle: lower
bounds in the AC^0 / counting-logic world might transfer to
WL-dimension lower bounds for OA-gadget constructions. (open)

### 6.3 Tightness against Babai's quasipolynomial algorithm

Babai's 2015 algorithm solves GI in 2^{O((log n)^c)} time using
*individualisation and refinement* (I+R): branch on choices of
"pinned" vertices, then refine by k-WL. On CFI graphs, the
branching factor and refinement depth combine to give
quasipolynomial running time.

#### 6.3.1 The two competing effects of richer Aut

For OA-gadget constructions, the I+R analysis has two competing
effects when the local automorphism group |Aut(M_v)| = |H| grows
beyond CFI's (ℤ/2)^{d-1}:

**Effect 1: more branching (slows I+R).** Each individualisation
round must consider |Aut(M_v)|-many distinct ways to identify
vertices. Larger |H| means more branches per round, more total
work.

**Effect 2: more symmetry to quotient by (speeds I+R).** Luks-style
recursive algorithms exploit the *structure* of Aut(M_v) to reduce
the problem to smaller sub-instances. A larger but *well-
structured* H (e.g., a solvable group, or a group with small
nilpotency class) gives the recursive algorithm more leverage. For
non-abelian simple H, the recursive reduction is less effective.

For CFI, H = (ℤ/2)^{d-1} is abelian (in fact elementary abelian),
which is the *most* Luks-exploitable structure. So CFI's local
|H| is small *and* Luks-friendly, giving genuinely tight upper
bounds matching the lower bounds.

For Sketch B, H = PΩ_8^+(2) is a non-abelian simple group. Effect
1 is severe (|H| ≈ 10^8 vs CFI's 4 for d = 3). Effect 2 is mild
(simple groups are not easily quotiented). Net effect: I+R on
Sketch B is *slower* than on CFI per refinement round, but the
refinement round count is similar.

For Sketch C, H = (ℤ/2)^n is elementary abelian like CFI but with
n much larger. Effect 1 is moderate (|H| = 2^n). Effect 2 is high
(elementary abelian — fully Luks-quotientable). Net effect on
matrix CFI per the literature: I+R has known polynomial overhead
versus CFI (Lichter, Pago, et al.).

#### 6.3.2 Worked branching counts

For 3-regular base X with |V_X| = n:

| Construction | per-gadget |Aut(M_v)| | total branching |
|--------------|-----------------------|------------------|
| CFI          | 4                     | 4^n              |
| Sketch A     | 720 · 2 = 1440        | 1440^n           |
| Sketch B     | 1.05 · 10^9           | (10^9)^n         |
| Sketch C     | 2^n                   | 2^{n·n} = 2^{n²} |

The "total branching" column is the naive product over all gadgets;
the actual I+R algorithm exploits cross-gadget structure and pays
much less. But the ratio of (Sketch / CFI) branching factors gives
a rough sense of the additional work I+R must do.

**Interpretation.**

- Sketches A and B impose much more I+R work per gadget than CFI.
  From the attacker's perspective this is *harder* to break, which
  is *good* for cryptographic use.
- However, the *honest* parties (prover and verifier in any
  reduction) pay essentially the same cost. So the cryptographic
  question is whether the I+R cost-ratio is *more favourable to
  the honest party* — i.e., the gap between attacker and honest
  costs is wider. This is what determines reduction tightness.

#### 6.3.3 The honest-party cost

For the OIA → GI → CE → 1-CPA chain, the "honest party" cost is
the reduction's instance-construction time — typically polynomial
in the instance size. The instance size for an OA-gadget family
is O(|V_M_v| · |V_X|) (dominated by total vertex count).

- CFI: |V_M_v| = O(d), so instance size = O(n · d). For d = 3 and
  n = 100, instance size ≈ 300.
- Sketch B: |V_M_v| = 405, so instance size = O(n · 405). For
  n = 100, instance size ≈ 40,500.
- Sketch C (n_inner = 8): |V_M_v| ≈ 2048 with edge labels, so
  instance size = O(n · 2048). For n = 100, instance size ≈ 200,000.

For honest-party time T_honest = poly(instance size), Sketch B
pays ~100× more than CFI, Sketch C ~500× more.

#### 6.3.4 Attacker / honest ratio summary

The *quality* of an OA-gadget construction (in cryptographic
terms) is

  Quality ≈ T_attacker / T_honest.

For CFI this ratio is 2^{O((log n)^c)} / O(n) ≈ 2^{O((log n)^c)}.

For Sketch B *with the same WL-dimension lower bound as CFI*, the
ratio is 2^{O((log n)^c)} (same as CFI) / O(n · 405) ≈ CFI / 400.

So **Sketch B is ~400× *worse* than CFI on the
attacker/honest ratio**, if its WL-dimension is the same. To beat
CFI, Sketch B would need to defeat WL with a *higher* WL-dimension
lower bound, e.g., Ω(n · log_2 6) ≈ 2.58 · Ω(n).

**Status.** The 2.58× WL-dimension boost is the heuristic from
§ 6.1; verifying it rigorously is the central open question. If
it holds, the attacker/honest ratio narrows the gap with CFI but
likely does not close it. **(open)**.

### 6.4 Reduction tightness to CE / PCE

For Orbcrypt, the GI hardness has to survive the GI ≤ CE reduction
(Petrank–Roth, via `Hardness/PetrankRoth.lean`). The Petrank–Roth
reduction is a *Karp reduction* with polynomial blowup in size,
but the *constant* in the polynomial matters for the
`ConcreteHardnessChain` ε bound.

CFI-graph encoding cost in Petrank–Roth: O(n^2) bits per CFI base
vertex (using the bit-layout marker-forcing scheme). Each CFI
gadget of d ports contributes O(d^2) bits with the standard
encoding.

OA-gadget encoding cost in Petrank–Roth: depends on how the
gadget interfaces. For Sketch B (triality), each gadget has
~10^3 vertices and 24 interface points; naive encoding gives
~10^6 bits per gadget, *much* worse than CFI.

**However:** the question is bits-per-encoded-information, not
bits-per-gadget. If Sketch B encodes 2.58 bits/gadget but uses
10^4 vertices/gadget, the bits/vertex ratio is ~2.58 / 10^4 ≈
3 · 10^{-4}. CFI is ~1 / 10 ≈ 0.1. **CFI wins by a factor of
~300.**

This is the central efficiency obstacle for Sketch B. It suggests
the genuine path forward (if any) is either:

1. *Drastically smaller local gadgets* with the same triality
   property — perhaps using smaller-q triality or partial
   triality;
2. *Better encoding of the gadget into a code* — bypassing the
   generic Petrank–Roth and constructing a *direct* OA-CE
   reduction.

Option (2) is genuinely interesting and is the most concrete
research target: design a Karp reduction OA-gadget → CE that
exploits the triality structure directly, rather than going
through GI.

### 6.5 The "individualisation collapses Out" subtlety

#### 6.5.1 What individualisation does

Babai's quasi-poly algorithm uses *individualisation and
refinement* (I+R): at each step, choose a small set S ⊆ V_G of
vertices and *colour each vertex in S uniquely* (with a distinct
"individualised" colour). This breaks every graph automorphism
that doesn't fix S pointwise, since automorphisms must preserve
colour classes.

The refinement step (running k-WL on the individualised graph)
then propagates colour information; the algorithm branches over
all possible "matchings" of individualised vertices between G and
H. After O(log n) individualisation rounds, the residual
automorphism orbit becomes manageable.

#### 6.5.2 How OA-gadgets interact with individualisation

For an OA-gadget construction OA_A(X, t) with interface vertices
I = ⋃_v I_v, an individualisation set S typically includes one or
more interface vertices.

**Key observation.** Individualising a single interface vertex
i_0 ∈ I fixes a *point* in the A-action on I. The residual A-action
is the stabiliser stab_A(i_0). For:

- *A = ℤ/2 transitive on 2-element ports:* stab is trivial; A is
  killed by one individualisation per port.
- *A = S_3 transitive on 3 modules:* stab is S_2; A reduces to S_2.
  Two individualisations (one per module pair) suffice.
- *A = GL_n acting on H = (ℤ/p)^n:* stab of a generic non-zero
  vector v is the affine subgroup fixing v (of order
  p^{n-1} · |GL_{n-1}|). Many individualisations needed to fully
  reduce A.

So *richer* A *requires more individualisations* to fully collapse
the twist symmetry — which is good for resistance, in terms of
I+R *branching*.

#### 6.5.3 But: H-stabiliser remains

Critically, individualising interface vertices typically does
*not* fix the H-action on internal gadget vertices. After all
relevant interface vertices are individualised:

- Residual A becomes trivial (the twist is determined).
- Residual H remains: the local symmetry inside each gadget is
  not affected by interface individualisation.

For **Sketch A (S_6 synthematic with H = S_6):** Individualising
the 6 point-layer vertices kills the S_6 H-action (now each point
is uniquely labelled). The Aut group is reduced to identity.

For **Sketch B (PΩ_8^+(2)-action):** Individualising 15 interface
points within one gadget fixes 15 points of the natural module,
which generates the full module — so the local H-action is also
killed. The Aut group reduces to identity at this gadget.

For **Sketch C ((ℤ/2)^n-action with labelled Cayley):** The
labelled Cayley graph M_C has Aut = (ℤ/2)^n acting freely on V_M_C.
Individualising any single vertex kills the H-action immediately
(no stabiliser).

#### 6.5.4 Numerical example: branching counts

Consider the I+R analysis on a single Sketch B gadget M_B (= 405
vertices, Aut = PΩ_8^+(2) ⋊ S_3):

- **Initial branching factor:** |Aut(M_B)| ≈ 1.05 · 10^9.
- **After individualising 1 interface vertex:** stab in Aut(M_B)
  has size 10^9 / 135 ≈ 7.7 · 10^6 (the point stabiliser in the
  natural-module action has index 135).
- **After individualising 15 interface vertices (= I_B):**
  stab in Aut(M_B) reduces to identity (the 15 points generate
  the natural module).
- **Total branching for one gadget:** ~10^9 / 1 = 10^9
  (= |Aut(M_B)|).

Versus CFI on the same base graph (3-regular, d = 3):

- Each CFI gadget has |Aut| = (ℤ/2)^2 = 4.
- Total branching per gadget: 4.

Sketch B requires ~10^9 / 4 = ~2.5 · 10^8 times more branching per
gadget than CFI. For a base graph with n_X = 100 vertices, the
naive I+R cost ratio is (2.5 · 10^8)^100 ≈ 10^{2500}.

**This is catastrophic for the cryptographic interpretation.** I+R
branching cost is what the *attacker* pays; more branching = more
attacker work = *harder* to break. So Sketch B is *much harder*
against I+R than CFI — but this also means the *honest party* (the
prover, in a hardness reduction) pays the same cost.

For Orbcrypt's hardness chain, the relevant comparison is between
the attacker's I+R cost and the honest party's reduction cost. If
the gap widens with Sketch B vs CFI, the reduction tightness
improves; if it narrows or reverses, the reduction loosens.

#### 6.5.5 The co-design rule

The correct framing for OA-gadget design is:

- **A controls WL-dimension** (the lower-bound side of the
  hardness analysis).
- **H controls I+R-resistance** (the upper-bound side, since I+R
  branching factor is dominated by |Aut(M_v)| = |H|).
- A *and* H must be co-designed: richer A without proportionally
  richer H gives no I+R protection beyond CFI.

The CFI construction balances these naturally: H = (ℤ/2)^{d-1} is
small (= cheap honest-party reduction) and A = ℤ/2 is small
(= mild WL-dimension lower bound). Sketch B has both H and A
larger — net effect is more expensive for both sides, with the
question being whether the *ratio* tightens.

**Concrete recommendation.** Before committing further to Sketch
B, perform an I+R cost-ratio analysis on small base graphs
(§ 10.2) to verify the ratio is at least as good as CFI's.

### 6.6 Compatibility with the `ConcreteHardnessChain` ε

In `Orbcrypt/Hardness/Reductions.lean`, the
`ConcreteHardnessChain` carries a probabilistic ε bound that
propagates through the chain into the
`concrete_hardness_chain_implies_1cpa_advantage_bound` headline
theorem.

The ε bound's tightness has three factors:
1. The base GI advantage on CFI graphs (assumed bound, currently
   inhabited only at ε = 1 via the trivial witness `tight_one_exists`).
2. The reduction-blowup factor from GI to CE.
3. The encoding factor from CE-instances to scheme-orbit instances.

An OA-gadget alternative changes (1) and (2) but not (3). If a
construction tightens (2) (e.g., a direct OA → CE Karp reduction
bypassing GI), the chain ε could improve. **(open)** whether any
of the sketches actually does this.

## 7. Orbcrypt integration

### 7.1 Where in `Hardness.PetrankRoth/` an OA family would slot in

The existing `Hardness/PetrankRoth.lean` re-exports the
forward-direction Karp reduction GI ≤ CE built from sub-modules:

- `Hardness/PetrankRoth/BitLayout.lean` — bit-layout encoding of
  the graph as a code.
- `Hardness/PetrankRoth/MarkerForcing.lean` — marker-vertex
  argument that forces the code's permutation group to act on
  the original graph structure.

An OA-gadget family enters the chain *upstream* of Petrank–Roth:
the source instance changes from "CFI graphs" to "OA(X, t) graphs"
for some base graph X and twist t : V_X → A. The Petrank–Roth
reduction itself is graph-family-agnostic; it accepts any pair of
graphs as input.

**Minimum integration cost.** If the OA family is presented as
"graphs with a hard isomorphism problem," no change to
PetrankRoth is needed. The chain just instantiates `GI-on-OA-family`
instead of `GI-on-CFI` and proceeds.

**Maximum integration cost.** If the OA family supports a *direct*
OA → CE reduction (bypassing GI), then `PetrankRoth.lean` would
gain a *parallel* reduction path: GI ≤ CE (current) and OA ≤ CE
(new). This requires a new sub-module
`Hardness/OAGadgets/Reduction.lean` and an update to
`Hardness/Reductions.lean` to feed the new reduction into the
`ConcreteHardnessChain`.

### 7.2 Impact on the ε bound

The `concrete_hardness_chain_implies_1cpa_advantage_bound` theorem
takes a `ConcreteHardnessChain` hypothesis and emits a 1-CPA
advantage bound. The ε is currently inhabited only at ε = 1 via
`tight_one_exists` (per CLAUDE.md's release-messaging policy).

An OA-gadget alternative *cannot* tighten ε below 1 unless it
provides a *concrete surrogate witness* — i.e., an explicit
encoder and keyDerive profile such that the surrogate orbit
distribution is provably indistinguishable from uniform with bound
ε < 1. This is the R-02 / R-03 / R-04 / R-05 research-scope
milestone listed in the project's audit plan.

The OA-gadget thread therefore does *not* directly produce an
ε < 1 result. It produces a *candidate alternative source family*
that, combined with R-02/03/04/05, *could* eventually contribute
to an ε < 1 witness.

### 7.3 Canonical-form computation in the gadget setting

`Orbcrypt/GroupAction/CanonicalLexMin.lean` provides
`CanonicalForm.ofLexMin` under the project's
`bitstringLinearOrder`. The orbit canonicalisation algorithm is
the O(|G|)-time naïve "iterate over G, pick min" approach.

For OA-gadget *source* instances (= base graphs used in the GI →
CE → OIA chain), canonical-form computation happens at *parameter
generation time*, not at encryption time. So performance is less
critical than for the in-protocol canonical-form computation on
the chosen key group G.

However, the gadget's algebraic structure could *help* with the
in-protocol canonicalisation: if the chosen key group G is derived
from the gadget's Aut(M_v) ⊇ H structure (e.g., G = the permutation
group realised on a gadget-glued construction whose stabiliser
structure is well-understood), canonical forms could exploit the
gadget structure. This is speculative; the global Aut of an
OA-gadget construction is more subtle than the local H factor and
depends on how twist classes interact across base-graph edges.

This is speculative; the right place to develop it is in a separate
research note on "structured key groups derived from OA gadgets,"
which is out of scope for the current note.

### 7.4 Lean formalisation roadmap (sketch)

If the OA-gadget thread eventually produces a Lean-worthy result,
the deliverables would be:

1. **`Orbcrypt/Hardness/OAGadgets/Framework.lean`** — abstract
   definition: `structure OAGadget` carrying a finite group H, an
   automorphism α : H ≃* H with α ∉ Inn(H), an interface set I,
   and an action φ : H →* Equiv.Perm V_M. Includes the
   "local indistinguishability" predicate.

2. **`Orbcrypt/Hardness/OAGadgets/Construction.lean`** — concrete
   construction OA(X, t) for an abstract twist group A, a base
   graph X, and a twist function t. Constructive in Lean — should
   compile to a decidable graph builder.

3. **`Orbcrypt/Hardness/OAGadgets/Triality.lean`** — Sketch B
   instantiation: PΩ_8^+(q) for q = 2, with explicit triality
   automorphism. Depends on Mathlib's classical-group library
   (currently thin for orthogonal groups in characteristic 2).

4. **`Orbcrypt/Hardness/OAGadgets/CFIEquivalence.lean`** — proof
   that Sketch A (the S_6 synthematic gadget with ℤ/2 twist) is
   isomorphic to standard CFI as a GI-hard family. Validates the
   framework recovers the known construction as a special case.

5. **`Orbcrypt/Hardness/OAGadgets/Reduction.lean`** — *only if*
   the literature check yields a direct OA → CE reduction with a
   tighter constant than the generic GI → CE composition. This
   would be the headline-theorem-worthy result.

**Estimated effort.** Items 1–2 are ~600 lines of Lean with
moderate Mathlib dependence. Item 3 requires non-trivial Mathlib
additions (or local definitions of Ω_8^+ in characteristic 2).
Items 4–5 are theorem-proving deliverables in the 200–500 line
range each. *Total:* ~2000 lines of Lean, *conditional* on the
research thread producing a publishable result.

This level of effort is justified only if the literature check and
small-case experiments (§ 10) yield concrete evidence that the
OA-gadget family produces *qualitatively* better parameters than
CFI in some axis Orbcrypt cares about. Without that, the thread
should remain in `docs/research/` and not enter the formalisation.

### 7.5 Risk of redundancy with existing literature

A serious risk: matrix CFI and various mod-p CFI generalisations
already appear in the parameterised-complexity and
descriptive-complexity literatures (Berkholz, Schweitzer, Lichter,
Pago, et al.). If the OA-gadget framework reduces to "matrix CFI"
in disguise, then:

- The cryptographic angle of repackaging matrix CFI for Orbcrypt
  is still potentially valuable;
- The *abstract framework* contribution (the OA-gadget definition
  itself) may be subsumed by existing work.

The literature check (§ 11) is critical for calibrating expected
novelty. Spending more than two weeks on this thread without first
doing the literature check is not advised.

## 8. Comparison table

The following table summarises the four constructions side-by-side
against CFI. Figures are order-of-magnitude estimates unless
sourced; "(open)" means the relevant analysis has not been done.
All "Sketch X" entries use the concrete parameters chosen in § 5
(Sketch B at q = 2, Sketch C at p = 2, n = 8). CFI baseline is for
3-regular base graphs.

### 8.1 Construction parameters

| Property                          | CFI                | Sketch A (S_6)    | Sketch B (PΩ_8^+, q=2) | Sketch C (GL_n, n=8) |
|-----------------------------------|--------------------|-------------------|------------------------|----------------------|
| Local symmetry group H            | (ℤ/2)^{d-1}         | S_6 (acting on 42)| Ω_8^+(2)               | (ℤ/2)^8              |
| Twist group A                     | ℤ/2                 | ℤ/2               | S_3                    | GL_8(𝔽_2)            |
| A abelian?                        | yes                | yes               | no                     | no                   |
| Commutator [A, A]                 | trivial            | trivial           | A_3 ≅ ℤ/3              | SL_8(𝔽_2)            |
| Cohomology type                   | abelian H^1(X,ℤ/2)  | abelian           | non-abelian            | non-abelian          |
| Bits per gadget                   | 1                  | 1                 | log_2 6 ≈ 2.58         | log_2 |GL_8| ≈ 62.2  |
| Local gadget |V_M|                 | O(d) = ~10        | 42                | 405                    | ~2048 (label-stripped)|
| Local Aut(M)                       | (ℤ/2)^{d-1} (= 4 at d=3)| Aut(S_6) ≈ 1440| ≈ Ω_8^+(2) ⋊ S_3 ≈ 10^9 | (ℤ/2)^8 = 256       |

### 8.2 Analytical claims

| Property                          | CFI                | Sketch A (S_6)    | Sketch B (PΩ_8^+, q=2) | Sketch C (GL_n, n=8) |
|-----------------------------------|--------------------|-------------------|------------------------|----------------------|
| k-WL lower bound (proven)         | Ω(s(X))            | (open; ≤ CFI)     | (open)                 | likely known (lit)   |
| k-WL lower bound (heuristic)      | Ω(s(X))            | Ω(s(X))           | Ω(s(X)) − O(log |[A,A]|)| Ω(s(X)) − O(n²)     |
| Babai-tightness                   | tight              | likely tight      | (open)                 | (open)               |
| Direct OA → CE reduction          | n/a                | n/a               | (open) — research target| (open)              |

### 8.3 Practical bookkeeping

| Property                          | CFI                | Sketch A (S_6)    | Sketch B (PΩ_8^+, q=2) | Sketch C (GL_n, n=8) |
|-----------------------------------|--------------------|-------------------|------------------------|----------------------|
| Bits/vertex efficiency             | ~0.25 (d=3)        | ~0.024            | ~0.0064                | ~0.030               |
| Honest reduction cost ratio (vs CFI)| 1× (baseline)    | ~4× (size 42/10)  | ~40× (size 405/10)     | ~200× (size 2048/10)|
| `PetrankRoth` integration         | works              | works             | needs S_3 adaptation   | needs GL_n adaptation|
| Known literature overlap           | baseline           | none (folklore)   | likely partial         | likely substantial   |
| Recommended priority               | n/a (baseline)     | low (pedagogy)    | **highest**            | medium (lit-check)   |

### 8.4 Reading the tables

- **Sketch A** is included as a *worked example* of the framework
  recovering CFI through a less efficient gadget; it has no
  cryptographic advantage. Useful for pedagogy and as a sanity
  check on framework implementations.
- **Sketch B** has the most distinctive structural feature
  (non-abelian S_3 cohomology) but is *less efficient* than CFI
  per vertex. Its case depends on whether the non-abelian structure
  yields algorithmic hardness benefits beyond the WL-dimension
  count.
- **Sketch C** is the most parameter-efficient OA gadget but
  almost certainly overlaps with established matrix-CFI literature.
  The OA-gadget framework's contribution there is unification,
  not novelty.

## 9. Open questions

Numbered for cross-reference. Each item is a concrete research
question; resolving it would either advance the thread or
foreclose it.

**Q1 (priority: high).** Does Sketch B (triality gadgets) defeat
k-WL for k = Ω(s(X)) (separator number)? Specifically: is there a
pebble-game strategy for the Duplicator using S_3-valued
bookkeeping on a tree decomposition of X? *Approach:* Adapt the
CFI pebble-game argument with non-abelian cocycle handling
(§ 6.1.3–6.1.5 outlines the candidate strategy). Reference:
Cai–Fürer–Immerman 1992 § 4; Hella 1996 (k-WL pebble game);
Dawar–Holm–Kopczyński–Toruńczyk 2013 (separator-number refinement).

**Q2 (priority: high).** Is the matrix-CFI construction
(Sketch C, or its established variant) equivalent to a known
construction in the literature? If so, what is its k-WL bound?
*Approach:* Literature check on "matrix CFI," "linear CFI,"
"vectorial CFI." Authors to query: Berkholz, Schweitzer, Lichter,
Pago, Holm.

**Q3 (priority: high).** Does any OA-gadget construction admit a
*direct Karp reduction to CE* that is asymptotically tighter than
the generic GI ≤ CE via Petrank–Roth? *Approach:* analyse the
encoding cost of OA-gadget structure as a code permutation
constraint. Hypothesis: triality structure could be encoded as a
3-fold cover of the code's coordinate set, with Petrank–Roth
marker-forcing adapted to forbid non-S_3-equivariant permutations.

**Q4 (priority: medium).** Is there a Babai-style I+R analysis
that quantitatively compares CFI and Sketch B time complexity?
The naive analysis suggests Sketch B is *easier* for I+R due to
larger local automorphism. Is this analysis tight, or does the
S_3 cocycle introduce additional refinement work?

**Q5 (priority: medium).** Can OA-gadget constructions provide
GI-hard graph families with bounded *vertex degree* (as opposed
to bounded treewidth)? Bounded-degree GI is polynomial-time
solvable (Luks 1982), so this would be a *negative* result —
useful to know.

**Q6 (priority: low).** Does the S_6 outer automorphism, when
viewed through the synthematic-totals lens, give rise to a new
natural hard problem distinct from GI / CE / TI? E.g.,
distinguishing "natural S_5 ⊂ S_6" from "exotic S_5 ⊂ S_6"
in a graph encoding. *Likely answer:* No, because the natural
invariants of S_5 ⊂ S_6 differ at low degree.

**Q7 (priority: medium).** Is there a *probabilistic* version of
the OA-gadget framework — analogous to the deterministic-to-
probabilistic shift from `Crypto.OIA` (deleted in W6) to
`Crypto.CompOIA` — that would feed directly into Orbcrypt's
quantitative chain? *Approach:* analyse the distribution of the
twist function t : V_X → A under uniform sampling and the
distinguishing advantage as a function of |A|.

**Q8 (priority: low).** Does the OA-gadget framework specialise
to other known constructions in algebraic complexity theory,
e.g., Tutte's 8-cage automorphism or Schreier coset graphs of
Mathieu groups? *Approach:* survey small-group constructions in
Babai–Codenotti–Qiao 2012.

**Q9 (priority: open / research-scope).** Does the framework
extend to *quantum* hardness — i.e., are OA-gadget constructions
hard against the quantum hidden subgroup approach to GI?
*Approach:* analyse the hidden subgroup structure of the global
graph's automorphism group (involving both H locally and A
acting on twist classes globally). Triality A = S_3 might be
quantum-hard for non-abelian HSP reasons (since S_3 is one of
the smallest groups where HSP is hard).

**Q10 (priority: open / research-scope).** Is there a *categorical*
description of the OA-gadget framework — e.g., as a fibred category
over groupoids of base graphs — that would clarify the structure?
*Approach:* describe CFI as a sheaf cohomology calculation and
generalise to non-abelian sheaves.

## 10. Recommended next steps

This section is intentionally concrete. The goal is to convert this
research note into a decision: continue the thread, or close it
out as "interesting but subsumed by existing work."

### 10.1 Literature check (estimated: 1 week)

Required reading, in priority order:

1. **Cai–Fürer–Immerman 1992** (the original CFI paper) — confirm
   the lower-bound argument's structure.
2. **Fürer 2001** (deterministic CFI variants and mod-p variants)
   — check whether mod-p CFI subsumes Sketch C.
3. **Berkholz–Nordström** (lower bounds for k-WL) — current
   state-of-the-art on what k-WL can/cannot decide.
4. **Lichter–Pago–Schweitzer** (matrix CFI, linear CFI variants)
   — *critical:* check whether Sketch C is already published.
5. **Babai 2015** (quasi-polynomial GI algorithm) — confirm
   the I+R analysis for OA-gadget families.
6. **Holm–Kiefer–Pago** (recent work on CFI generalisations) —
   most current literature.

Deliverable: a short follow-up note `outer_automorphism_gadgets_litcheck.md`
listing which of Sketches A/B/C are already in the literature, with
explicit citations.

### 10.2 Small-case experiments (estimated: 1 week)

For Sketch B on small base graphs (n = 4–10 vertices), use GAP or
nauty to:

1. Construct the OA-gadget graph OA(X, t) for various X and t.
2. Compute the orbit of OA(X, t) under graph isomorphism.
3. Run k-WL (k = 1, 2, 3) on twin pairs (t ≠ t').
4. Verify that distinct *cohomology classes* of t give distinct
   isomorphism orbits.

This is a *sanity check*, not a publishable result. It either
confirms the framework's basic soundness on small cases (then
move to literature check + larger-scale construction) or
disproves it (then close the thread).

Deliverable: a GAP script `implementation/gap/oa_gadget_experiment.g`
running the experiment, with output logged in
`docs/research/oa_gadget_experiment.csv`.

### 10.3 Lean experiments (estimated: 1–2 weeks, conditional)

*Only if* §§ 10.1–10.2 yield positive results, do the following:

1. Define `Orbcrypt/Hardness/OAGadgets/Framework.lean` as in
   § 7.4 item 1. ~200 lines.
2. Instantiate Sketch A (S_6 synthematic). ~150 lines.
3. Prove that Sketch A is GI-equivalent to standard CFI. ~250
   lines (the main technical content).

This is the minimum Lean-side commitment that demonstrates the
framework's value. If items 1–3 land cleanly, then Sketch B is the
next target.

### 10.4 Stop conditions

Close the thread (move this document to `docs/dev_history/` and
take no further action) if:

- The literature check finds that Sketches B and C are subsumed
  by existing work *and* the cryptographic-repackaging angle
  doesn't yield concretely better Orbcrypt parameters.
- The small-case experiments show that Sketch B is k-WL
  distinguishable for k = 2 (= colour refinement with pairs),
  invalidating the WL-dimension claim.
- Any of Q1, Q2 receive a negative resolution in the literature.

Promote the thread to a workstream (add to
`docs/dev_history/WORKSTREAM_CHANGELOG.md` and create planning
document in `docs/planning/`) if:

- The literature check shows Sketch B is genuinely novel, *and*
- Small-case experiments confirm k-WL ≥ 3 indistinguishability,
  *and*
- The Lean experiments (10.3) compile cleanly.

## 11. References and further reading

### Citation discipline

References are organised by reading priority and confidence level.
Citations marked **[verified]** have been cross-checked against
DOIs or publisher records; citations marked **[approximate]** are
from the author's working knowledge and *must be verified* before
external use (e.g., in a published paper or external slide deck).
Citations marked **[pointer]** identify a researcher or research
direction without committing to a specific publication.

### Primary references (to read in detail)

* **Cai, J., Fürer, M., Immerman, N.** (1992). *An optimal lower
  bound on the number of variables for graph identification.*
  Combinatorica 12(4), pp. 389–410. DOI: 10.1007/BF01305232.
  **[verified]** The original CFI construction and k-WL lower
  bound. The single most important reference for this note;
  understanding the pebble-game argument here is prerequisite to
  any of §§ 6.1 generalisations.

* **Babai, L.** (2015). *Graph Isomorphism in Quasipolynomial Time.*
  arXiv:1512.03547. **[verified]** The current state-of-the-art GI
  algorithm and the framework against which any OA-gadget
  construction must be measured. § 6.3 of this note depends on
  the I+R analysis of this paper.

* **Fürer, M.** (2001). *Weisfeiler–Lehman refinement requires at
  least a linear number of iterations.* ICALP 2001 (LNCS 2076,
  pp. 322–333). **[approximate]** Includes the mod-p CFI
  refinement. *Critical first read* (§ 11.0) to determine whether
  Sketch C is subsumed by the mod-p extension.

* **Dawar, A., Holm, B., Kopczyński, E., Toruńczyk, S.** (2013).
  *Definability of summation problems for abelian groups and
  semigroups.* LICS 2013. **[approximate; year may differ]** The
  separator-number refinement of CFI's treewidth lower bound is
  attributed to this line of work. Source for the
  separator-number statement in § 2.3; verify exact reference.

* **Grochow, J. A., Qiao, Y.** (2023). *Algorithms for Tensor
  Isomorphism with Applications to Cryptography.* SIAM J. Comput.
  52(3), pp. 568–617. DOI: 10.1137/22M1481443. **[verified;
  cross-reference]** Context for the GI ≤ TI side of the hardness
  chain; sister paper to the GI ≤ CE work driving Orbcrypt's
  Hardness chain.

### Secondary references (selective; verify before external use)

* **Hella, L.** (1996). *Logical hierarchies in PTIME.* Inform.
  Comput. 129(1), pp. 1–19. **[approximate]** Pebble-game
  characterisation of k-WL / counting logic; used in § 6.1.

* **Immerman, N., Lander, E.** (1990). *Describing graphs: A
  first-order approach to graph canonization.* In: Selman, A. L.
  (ed.), *Complexity Theory Retrospective.* Springer.
  **[approximate]** The counting-logic / k-WL correspondence cited
  in § 2.2 and § 6.2.

* **Berkholz, C., Nordström, J.** (2016). *Near-optimal lower
  bounds on quantifier depth and Weisfeiler–Leman refinement
  steps.* LICS 2016. **[approximate]** Tightness results for k-WL;
  relevant to § 6.3 Babai-tightness analysis.

* **Lichter, M.** *Matrix CFI / linear CFI* — likely PhD thesis
  (RWTH Aachen or TU Darmstadt, ~2023). **[pointer]** Specific
  citation pending literature check. Sketch C of this note is
  almost certainly substantially subsumed by Lichter's work; this
  is the single most critical citation to nail down before
  pursuing Sketch C further.

* **Pago, B.** Recent work on CFI generalisations and WL hierarchy.
  **[pointer]** Specific citation pending; collaborated with
  Lichter and others on related questions.

* **Holm, B., Kiefer, S., Schweitzer, P.** Recent work on CFI
  variants. **[pointer]** Specific citations pending literature
  check; conference papers 2022–2024 are the most likely target.

* **Schweitzer, P.** *GI canonical-form algorithms and WL-hierarchy
  / I+R survey.* **[pointer]** Schweitzer has authored multiple
  papers in this area; bibliography pending.

### Tertiary references (context and background)

* **Conway, J. H., Curtis, R. T., Norton, S. P., Parker, R. A.,
  Wilson, R. A.** (1985). *Atlas of Finite Groups.* Clarendon
  Press, Oxford. **[verified]** Authoritative source for outer
  automorphism groups, including triality for D_4 / Ω_8^+.
  Required reading for § 4 candidate-group identification.

* **Wilson, R. A.** (2009). *The Finite Simple Groups.* Springer
  GTM 251. **[verified]** Modern companion to the Atlas; chapter 7
  on classical groups covers PΩ_8^+(q) and triality in detail.

* **Sylvester, J. J.** (1844). *Elementary researches in the
  analysis of combinatorial aggregation.* **[approximate; pre-DOI
  historical reference]** The original synthematic totals
  construction for S_6.

* **Howard, B., Millson, J., Snowden, A., Vakil, R.** (2008). *A
  description of the outer automorphism of S_6, and the invariants
  of six points in projective space.* J. Combin. Theory Ser. A
  115(7), pp. 1296–1303. **[approximate; year may differ]** Modern
  algebraic-geometric perspective on the S_6 outer automorphism —
  useful pedagogy.

* **Luks, E. M.** (1982). *Isomorphism of graphs of bounded
  valence can be tested in polynomial time.* J. Comput. Syst. Sci.
  25(1), pp. 42–65. **[approximate]** The foundational paper on
  bounded-degree GI algorithms; relevant to § 6.3 analysis of how
  Aut(M_v)-structure interacts with I+R.

### Orbcrypt-internal cross-references

* `docs/HARDNESS_ANALYSIS.md` — LESS / MEDS alignment; full chain
  Orbcrypt's `ConcreteHardnessChain` realises.
* `docs/research/grochow_qiao_reading_log.md` — sibling paper-
  synthesis note for the GI ≤ TI side.
* `Orbcrypt/Hardness/Reductions.lean` — the formalised hardness
  chain into which OA-gadget source instances would feed.
* `Orbcrypt/Hardness/PetrankRoth.lean` and sub-modules — the
  formalised GI ≤ CE reduction that any OA-gadget family must
  compose with.
* `scripts/audit_phase_16.lean` — axiom-transparency audit; if any
  Lean OA-gadget formalisation lands, every public declaration
  added must be cross-referenced here.

### Status of this note

* **Draft:** This note. No prior versions.
* **Maintainers:** Whoever picks up the thread.
* **Promotion criteria:** Per § 10.4 stop conditions and promotion
  criteria.
* **Naming:** This note's title and identifiers follow the
  "names describe content, never provenance" rule of CLAUDE.md
  § Naming conventions. The phrase "outer-automorphism gadget" is
  content; "Workstream R-OA-1" or similar would not be permissible
  even as a working name.

