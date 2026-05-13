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

The S_6 outer automorphism phenomenon is the conversational seed:
S_6 has the smallest non-trivial "outer twist," and the question is
whether scaling this principle yields a CFI alternative.

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

Fix a 3-regular base graph X = (V, E). The CFI graph CFI(X, t) is
parametrised by a "twist function" t : V → ℤ/2. Construction:

1. **Vertex-gadget.** For each v ∈ V of degree d (= 3 in this
   recap), construct the *gadget* M(v):
   - 2^{d-1} = 4 "inner vertices" labelled by parity-zero binary
     strings of length d, i.e., {000, 011, 101, 110}.
   - 2d = 6 "outer vertices" labelled by (e, b) for e ∈ incident(v),
     b ∈ {0, 1}.
   - Edges: an inner vertex w = (b_1, …, b_d) is connected to outer
     vertex (e_i, b_i) for each i.
2. **Edge-gluing.** For each edge e = {u, v} ∈ E with twist t(v) ∈
   ℤ/2, glue the outer vertex (e, b) of M(u) to (e, b ⊕ t(v)) of
   M(v).

The graph CFI(X, t) has the following properties (known, Cai–Fürer–
Immerman 1992):

- **Isomorphism class depends only on global parity.** CFI(X, t) ≅
  CFI(X, t') iff ∑_{v ∈ V} t(v) = ∑_{v ∈ V} t'(v) (mod 2).
- **Twin pair.** Taking t ≡ 0 and t = δ_{v_0} for some chosen v_0
  gives a *non-isomorphic* pair CFI(X, 0) ≢ CFI(X, δ_{v_0}). This
  is the canonical CFI twin.
- **k-WL fails for k < tw(X) − O(1).** When X has treewidth growing
  with |V|, the twin pair is k-WL indistinguishable for k = Ω(tw).
  Hence k-WL has unbounded WL-dimension on the CFI family.

The structural reading: the twist t lives in C^0(X, ℤ/2) =
ℤ/2-cochains on the base graph; the isomorphism class lives in
H^0(X, ℤ/2) / parity = ℤ/2 (a single global parity bit). The local
gadget is invisible to k-WL because the inner-vertex set is
(ℤ/2)^{d-1}-symmetric; the global twist is detectable only at the
"connectivity scale" of X.

### 2.4 Outer automorphisms and the symmetric-group exception

For a group G, the *inner automorphisms* are the conjugations Inn(G)
= {g ↦ x g x^{-1} : x ∈ G} ≅ G / Z(G). The *outer automorphism
group* is Out(G) = Aut(G) / Inn(G).

Known facts relevant here:

- **Symmetric groups.** Aut(S_n) = Inn(S_n) for all n ≠ 2, 6.
  Out(S_6) ≅ ℤ/2. (Hölder, c. 1895.)
- **Cyclic groups.** Aut(ℤ/n) ≅ (ℤ/n)*. Inn is trivial. So Out =
  (ℤ/n)*.
- **Elementary abelian.** Out((ℤ/p)^n) = Aut((ℤ/p)^n) = GL_n(p).
- **Simple groups (Schreier conjecture, known).** Out(G) is solvable
  for every non-abelian finite simple group. Most sporadics have
  |Out| ∈ {1, 2}; some Lie-type families have richer Out from field
  and graph automorphisms.
- **Triality (known).** The simply-laced rank-4 Lie type D_4 has the
  unique S_3 graph-automorphism group. The finite simple group
  PΩ_8^+(q) has Out containing S_3 (the triality); combined with
  field and diagonal automorphisms, |Out(PΩ_8^+(q))| can reach
  6 · |⟨field⟩| · |⟨diagonal⟩|.

For the OA-gadget framework, the relevant quantity is the *size and
structure of A = Out(H)* for a local-gadget group H. Larger A allows
encoding more information per gadget.

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

**Definition (OA-gadget, working).** Let H be a finite group with a
non-trivial outer automorphism group A = Out(H). A *local OA-gadget
for H* is a tuple (M, ι, φ) where:

1. M = (V_M, E_M) is a finite graph (or, more generally, a relational
   structure such as a code over a fixed alphabet).
2. ι : I → V_M is an injection from a fixed *interface set* I (the
   "ports" by which M will be attached to a base structure) into
   the vertex set of M.
3. φ : H → Aut(M) is a group homomorphism such that φ(H) fixes
   ι(I) pointwise, i.e., the H-action permutes the *non-interface*
   vertices of M.

Additionally we require *local indistinguishability*:

4. There exists an injection ψ : A → Aut(M) (as sets) such that for
   each α ∈ A, the automorphism ψ(α) extends to a graph-automorphism
   of M that *permutes the interface set* I non-trivially according
   to the action of α on H/Stab_H(I).

We call A the *twist group* of the gadget.

In the abelian-twist special case (A abelian, |A| = 2), this
recovers the CFI gadget construction with H = (ℤ/2)^{d-1} and A =
ℤ/2 parity.

### 3.2 The CFI construction as a (ℤ/2)-twist

Concretely, the standard CFI gadget for degree-d vertices is the
OA-gadget given by:

- H = (ℤ/2)^{d-1} (inner-vertex symmetries),
- A = ℤ/2 (parity twist),
- M = the bipartite graph with 2^{d-1} "inner" vertices and 2d
  "outer" interface vertices.

The full Aut(M) is H ⋊ A = (ℤ/2)^{d-1} ⋊ ℤ/2 (the standard
hyperoctahedral construction, equivalently the Weyl group of type
B_{d-1}). The interface action of A is to swap the two interface
vertices at each port (the "outer 0" and "outer 1" vertices).

For the OA-gadget framework the relevant abstraction is that A acts
as a *non-trivial automorphism class on the interface*, hence the
"twist by α" is detectable at the interface (= globally) but not in
the bulk of M (where H absorbs it).

### 3.3 Generalisation to richer twist groups

The natural generalisation is to allow:

- A abelian but non-ℤ/2: e.g., A = ℤ/p for primes p > 2, giving
  *mod-p CFI* (Furer 2001 mentions this; Lichter has worked on
  variants — **literature check needed**, see § 11). This encodes
  log_2(p) bits per gadget rather than 1.
- A non-abelian: e.g., A = S_3 (triality), giving a 6-element
  twist set per gadget; A = GL_n(p) on the regular representation
  of (ℤ/p)^n, giving an exponentially large twist set.
- A acting on the interface via a non-regular action: e.g., A acts
  on I via some sub-permutation-representation, and only that
  sub-action is "visible globally."

**Construction sketch (general).** Given a base graph X = (V_X, E_X)
where each vertex v has degree d_v, a local OA-gadget (M_v, ι_v,
φ_v) for each v, and a *twist function* t : V_X → A:

1. For each vertex v ∈ V_X, take a copy of M_v.
2. For each edge {u, v} ∈ E_X, glue M_u and M_v by identifying the
   port at v in M_u with the port at u in M_v, possibly twisting by
   t(v) ∈ A on one side.
3. The resulting graph CFI_A(X, t) has automorphism group encoding
   the "global cocycle class" of t in some appropriate cohomology
   theory.

For A = ℤ/2 this is the standard CFI. For A non-abelian the
"cohomology class" becomes a non-abelian Čech 1-cocycle modulo
coboundary, valued in A.

### 3.4 Soundness conditions

For an OA-gadget construction to produce a genuinely new GI-hard
family — rather than reducing to CFI in disguise — the following
soundness conditions should be checked:

**(S1) Non-trivial twist orbit.** The orbit of the trivial twist
t ≡ e under the gauge action (boundary action) should be a
strict subset of all twist functions; otherwise every twist is
equivalent to trivial and the construction is rigid.

**(S2) k-WL indistinguishability.** For some k = k(|V_X|), the
graphs CFI_A(X, t) and CFI_A(X, t') for non-equivalent twist
functions t, t' should be k-WL indistinguishable. The benchmark to
beat: CFI achieves k = Ω(tw(X)) for treewidth tw.

**(S3) Algorithmic GI hardness.** Distinguishing CFI_A(X, t) from
CFI_A(X, t') should be at least as hard as a problem of known
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
  natural cases. See § 1.3 of the conversational seed for Orbcrypt
  and § 6.1 below for the k-WL framing.
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
- **Computability.** Trivial; α is given by a 720-element table or by
  the synthematic-totals construction (Sylvester, § 2 of the
  conversational seed).
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

This is the construction I'd push on first if pursuing the thread.

**Local gadget M_B.** Let H = Ω_8^+(q) for some small q (q = 2 for
maximum simplicity). The natural module is the 8-dim quadratic
space V over 𝔽_q; the half-spin modules are S_+ and S_-, each
8-dim. Triality is the outer automorphism cyclically permuting
{V, S_+, S_-}.

Build M_B as the disjoint union of three 8-dim modules with
"linkage" edges encoding the triality bilinear pairings:

- V × S_+ → S_- (the spin-vector pairing);
- and the two cyclic rotations.

The graph structure is the incidence between basis vectors of the
three modules under the trilinear form. Aut(M_B) ⊇ H ⋊ S_3.

**Interface I_B.** Take a maximal totally singular subspace W ⊂ V
of dimension 4. |W| = q^4 = 16 for q = 2. The S_3 twist permutes
W with corresponding subspaces of S_+ and S_-.

**Attachment to base X.** Each vertex v of base X has degree d_v;
pad to a degree d divisible by 3, and partition the d neighbours
into 3 groups of d/3. Attach M_B identifying group i with
"interface in module i" for i ∈ {V, S_+, S_-}.

**Twist t : V_X → S_3.** Twist t(v) = σ ∈ S_3 means "cyclically
permute the three groups of d/3 neighbours by σ" before identifying.

**Expected properties.**

- *Capacity:* log_2(6) ≈ 2.58 bits per gadget — *roughly 2.58× CFI*.
- *Cocycle structure:* Non-abelian. Two twist functions t, t' yield
  isomorphic graphs iff t' = ∂s · t for some s : V_X → S_3 (boundary
  action), but the boundary action is non-trivial because S_3 is
  non-abelian. The "global twist class" is a Čech 1-cohomology
  class with non-abelian coefficients — a *pointed set*, not a group.
- *k-WL behaviour:* **(open).** Conjecturally Ω(tw(X)) by the same
  argument as CFI (local symmetry absorbs t, global cocycle
  detected only at high WL dimension); rigorous proof requires
  analysing the pebble game on M_B. Could be qualitatively stronger
  or weaker than CFI; literature check (§ 11) flags Lichter's work
  on related variants.
- *Encoding size:* Gadget has 3 × 256 + linkage = O(10^3) vertices
  for q = 2. *Substantially larger than CFI* per base vertex but
  carries 2.58× more bits.
- *Reduction friendliness for `Hardness.PetrankRoth/`:* **(open).**
  The Petrank–Roth marker-forcing argument should adapt, but the
  marker pattern needs S_3 sensitivity. Could require a non-trivial
  rewrite of the `MarkerForcing` module.
- *Verdict:* **The thread's most plausible Pareto-improvement on
  CFI.** Spend Week 1 of the proposed exploration here.

### 5.3 Sketch C: GL_n-twist (matrix CFI) gadgets

**Local gadget M_C.** Let H = (ℤ/p)^n acting on V = 𝔽_p^n by
translation. Choose a *partial flag*

  V_0 = {0} ⊂ V_1 ⊂ V_2 ⊂ … ⊂ V_k = V

with dim V_i = i (for simplicity p = 2, k = n). The gadget is a
graph encoding the flag structure: vertices = ⋃_i V_i (with V_i in
"layer i"), edges = inclusions V_i ⊂ V_{i+1} as bipartite incidence.

Aut(M_C) contains GL_n(𝔽_p) acting on the flag stabiliser (the
upper-triangular Borel subgroup B ≤ GL_n).

**Interface I_C.** The "top layer" V (= 𝔽_p^n) of the flag, viewed
as the H-set on which the gadget hooks to the base graph.

**Attachment to base X.** Each base vertex v has degree p^n; attach
M_C identifying v's p^n neighbours with I_C = V.

**Twist t : V_X → GL_n(𝔽_p) / B.** The cosets GL_n / B are points
of the flag variety (= the complete flag variety of 𝔽_p^n). For
p = 2, n = 4: |GL_4(2)/B| = 64 cosets. Twist t(v) = a coset means
"apply matrix a to the flag identification at v."

**Expected properties.**

- *Capacity:* log_2(|GL_n/B|) = log_2(∏_{i=1}^n (p^i - 1) / (p-1))
  ≈ O(n^2) bits per gadget for p constant.
- *k-WL behaviour:* **(open).** This is the "matrix CFI" or "linear
  CFI" of the literature; Berkholz–Schweitzer or Holm–Pago may have
  results — **literature check needed**.
- *Encoding size:* M_C has ∑_{i=0}^n p^i vertices per gadget; for
  p = 2, n = 8, that's 511. Much larger than CFI per gadget but
  carries O(n²) bits.
- *Reduction friendliness:* High capacity per gadget could *reduce*
  total encoding size for fixed information content compared to
  CFI's 1-bit gadgets.
- *Verdict:* Worth a focused look *if* the matrix CFI literature
  does not already exhaust this idea. If it does, then matrix CFI
  is the construction we want, branded as such, with the
  OA-gadget framework documented as the unifying perspective.

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

The CFI lower bound (Cai–Fürer–Immerman 1992) states: for base
graphs X of treewidth tw, the twin CFI(X, 0) ≢ CFI(X, δ_v) is
k-WL indistinguishable for k = Ω(tw). Treewidth-Ω(n) base graphs
(e.g., expanders) then give k-WL indistinguishable graphs of size
O(n) at WL dimension Ω(n).

For OA-gadget constructions B and C of § 5, the analogous question
is whether there is a base-graph parameter (treewidth, vertex
expansion, or a new gadget-dependent parameter) controlling the
k-WL dimension of indistinguishability.

**Heuristic argument for B (triality).** The local automorphism
group is H ⋊ S_3 with H = Ω_8^+(2). The pebble-game on the base
graph X requires the Spoiler to "track" the S_3 twist across X. If
X has treewidth tw, the Duplicator can hide the S_3 twist along
any tree decomposition of X using S_3-valued bookkeeping at each
bag. By the same combinatorial argument as CFI, this should give
k = Ω(tw) k-WL indistinguishability with the implicit constant
depending on log_2 |S_3| / log_2 |ℤ/2| = log_2 6 ≈ 2.58.

**Heuristic argument for C (matrix).** Here the bookkeeping at
each tree-decomposition bag is GL_n-valued. The pebble-game
Duplicator strategy is the "linear algebra version" of the CFI
strategy — track *matrix-valued* twists rather than bit-valued
twists. If this analysis goes through, k = Ω(tw / log p^n) or so,
which is *weaker* per WL-dimension increment but stronger per
bit-encoded.

**Both heuristics are unverified.** They are the standard "this
should work analogously" argument; turning them into proofs is
exactly the literature-check thread. **(open)** until verified.

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

Babai's 2015 algorithm solves GI in 2^{O((log n)^c)} time. The
algorithm uses *individualisation and refinement* (I+R): branch on
choices of "pinned" vertices, then refine by k-WL. On CFI graphs,
the branching factor and refinement depth combine to give
quasipolynomial running time.

For OA-gadget constructions, the I+R analysis is:

- Branching factor depends on the *automorphism orbits* of the
  graph, which are controlled by Aut(M) = H ⋊ A.
- Refinement depth depends on the WL-dimension lower bound.

A construction with the *same* WL-dimension as CFI but a *larger*
local automorphism group (so larger branching) would be *easier*
for I+R. So *bigger A is not automatically better*: it has to be
weighed against the corresponding branching cost.

**Worked CFI calculation.** CFI(X, t) has local automorphism
(ℤ/2)^{d-1} at each gadget (d = degree), so branching factor 2^{d-1}.
For 3-regular X with |V_X| = n, total search space is 2^{n} (after
all branches), refined by k-WL with k = Ω(n).

**Sketch B calculation.** PΩ_8^+(2) has order ≈ 1.7 · 10^8, so
local branching factor is *huge*. Even with k-WL ≈ Ω(tw) lower
bound, the I+R algorithm gets very fat branches. Naive analysis
suggests this is *worse* than CFI for the cryptographer's purpose
(easier to attack, not harder).

**Caveat.** This is a rough analysis. The full I+R algorithm uses
*sophisticated* branching strategies (Luks-type recursion) that
may not actually pay the full local-automorphism cost. The
quantitative comparison is **(open)** and is one of the central
literature-check items.

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

Babai's algorithm branches on individualisations of small vertex
subsets. After enough individualisations, every graph
automorphism that doesn't fix the individualised set is killed.

For an OA-gadget where A acts on the interface, individualising
*one interface vertex* may suffice to fix the twist class:
specifically, if A acts transitively on I, then individualising
one i ∈ I forces A to the stabiliser of i, which may be trivial.

For Sketch A (S_6 with I = 6 points): A = ℤ/2 acts by swapping the
two 6-element layers; individualising any single vertex doesn't
break the swap because both layers have 6 elements indistinguishable
locally. Multiple individualisations needed.

For Sketch B (triality with I = 24 = 3 × 8): A = S_3 acts on the
3 modules; individualising one vertex per module fixes A to a
single conjugacy class, but the *within-module* H-action remains.
So individualisation collapses the *twist* part of Aut, but the
H-part of Aut survives.

This means: against I+R, *the protection is the H part of Aut,
not the A part*. The A part is auxiliary "bonus structure" that
helps with WL-dimension counting but doesn't directly resist I+R.

This is a real concern for the framework. The headline claim "rich
A gives more bits/gadget" is true at the encoding level, but
"more bits/gadget = more I+R resistance" does **not** follow. The
correct framing is: A controls *WL-dimension*, H controls
*I+R-resistance*, and the two need to be co-designed.

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
from the gadget's H ⋊ A structure (e.g., G = the permutation group
realised on a CFI-style construction with H ⋊ A symmetry),
canonical forms could exploit the gadget structure.

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
   construction CFI_A(X, t) for an abstract twist group A, a base
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

The following table summarises the constructions side-by-side
against CFI. All "vs CFI" figures are *order-of-magnitude
estimates*, not proofs. Negative numbers mean "worse than CFI";
"(open)" means the relevant analysis has not been done.

| Property                          | CFI            | Sketch A (S_6)  | Sketch B (PΩ_8^+) | Sketch C (GL_n)  |
|-----------------------------------|----------------|-----------------|-------------------|------------------|
| Twist group A                     | ℤ/2            | ℤ/2             | S_3 (non-ab.)     | GL_n(p)          |
| Bits per gadget                   | 1              | 1               | log_2 6 ≈ 2.58    | O(n²) log_2 p    |
| Local gadget vertices             | O(d)           | 42              | ~10^3 (q=2)       | O(p^n)           |
| Vertices per bit encoded          | O(d)           | 42              | ~400              | O(p^n / n²)      |
| Local Aut(M) size                 | (ℤ/2)^{d-1}⋊ℤ/2 | S_6 ⋊ ℤ/2      | Ω_8^+(q) ⋊ S_3   | (ℤ/p)^n ⋊ GL_n  |
| k-WL lower bound (heuristic)      | Ω(tw(X))       | Ω(tw(X))        | Ω(tw(X)) (open)   | (open)           |
| k-WL lower bound (proved)         | Ω(tw(X))       | (open)          | (open)            | (open)           |
| Babai-tightness                   | tight          | likely same     | (open)            | (open)           |
| Direct OA→CE reduction            | n/a            | n/a             | (open)            | (open)           |
| `PetrankRoth` integration         | works          | works           | needs adaptation  | needs adaptation |
| Concrete novelty                  | baseline       | none            | possibly          | likely=matrix CFI|
| Recommended priority              | n/a            | low (pedagogy)  | **highest**       | medium (lit-check)|

**Reading the table.** Sketch A is included for completeness as a
worked example of the framework recovering CFI. Sketch B is the
recommended focus. Sketch C is included because it likely overlaps
with the existing matrix-CFI literature, which must be checked
before committing effort there.

## 9. Open questions

Numbered for cross-reference. Each item is a concrete research
question; resolving it would either advance the thread or
foreclose it.

**Q1 (priority: high).** Does Sketch B (triality gadgets) defeat
k-WL for k = Ω(tw(X))? Specifically: is there a pebble-game
strategy for the Duplicator using S_3-valued bookkeeping on a
tree decomposition of X? *Approach:* Adapt the CFI pebble-game
argument with non-abelian cocycle handling. Reference:
Cai–Fürer–Immerman 1992 § 4; Hella 1996 (k-WL pebble game).

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
*Approach:* analyse the hidden subgroup structure of the
gadget's automorphism group H ⋊ A. Triality A = S_3 might be
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

1. Construct the OA-gadget graph CFI_A(X, t) for various X and t.
2. Compute the orbit of CFI_A(X, t) under graph isomorphism.
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

### Primary references (to read in detail)

* **Cai, J., Fürer, M., Immerman, N.** (1992). *An optimal lower
  bound on the number of variables for graph identification.*
  Combinatorica 12(4), pp. 389–410. DOI:10.1007/BF01305232. The
  original CFI construction and k-WL lower bound.

* **Babai, L.** (2015). *Graph Isomorphism in Quasipolynomial Time.*
  arXiv:1512.03547. The current state-of-the-art GI algorithm and
  the framework against which any OA-gadget construction must be
  measured.

* **Fürer, M.** (2001). *Weisfeiler-Lehman refinement requires at
  least a linear number of iterations.* ICALP 2001. The mod-p CFI
  refinement; **(read this first)** to determine whether Sketch C
  is subsumed.

* **Grochow, J. A., Qiao, Y.** (2023). *Algorithms for Tensor
  Isomorphism with Applications to Cryptography.* SIAM J. Comput.
  52(3), pp. 568–617. Context for the GI ≤ TI side of the
  hardness chain.

### Secondary references (selective)

* **Hella, L.** (1996). *Logical hierarchies in PTIME.* Inform.
  Comput. 129(1), pp. 1–19. Pebble-game characterisations of k-WL
  / counting logic.

* **Holm, B., Kiefer, S., Pago, B.** Recent work on CFI variants
  and the WL hierarchy (specific citation pending literature
  check — likely conference papers 2022–2024).

* **Lichter, M.** Recent thesis / papers on matrix CFI and linear
  CFI (specific citation pending — German PhD thesis around 2023).

* **Berkholz, C., Nordström, J.** (2016). *Near-optimal lower
  bounds on quantifier depth and Weisfeiler–Leman refinement
  steps.* LICS 2016. Tightness results for k-WL.

* **Schweitzer, P.** Survey work on GI canonical-form algorithms;
  multiple papers in the WL-hierarchy / I+R literature.

### Tertiary references (context)

* **Conway, J. H., Curtis, R. T., Norton, S. P., Parker, R. A.,
  Wilson, R. A.** (1985). *Atlas of Finite Groups.* Clarendon
  Press, Oxford. Authoritative source for outer automorphism
  groups, including triality for D_4 / Ω_8^+.

* **Sylvester, J. J.** (1844). *Elementary researches in the
  analysis of combinatorial aggregation.* The original synthematic
  totals construction for S_6.

* **Howard, B., Millson, J., Snowden, A., Vakil, R.** (2009). *A
  description of the outer automorphism of S_6, and the invariants
  of six points in projective space.* J. Combin. Theory Ser. A
  115(7), pp. 1296–1303. Modern algebraic-geometric perspective on
  the S_6 outer automorphism — useful pedagogy.

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

