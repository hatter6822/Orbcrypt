<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# 1. Permutation-Orbit Encryption (POE)

## 1.1. High-Level Picture

* Space ( X = {0,1}^n ) (bitstrings, graphs, etc.)
* Hidden group ( G \leq S_n ) acts by permuting coordinates
* Message = **which orbit** an element belongs to
* Ciphertext = **random element of that orbit**

Without knowing ( G ):

* orbit structure is invisible
* membership testing is hard
  → everything looks like one big “collapsed” space

With ( G ):

* you can canonicalize and recover the message

---

## 1.2. Concrete Construction

### Secret key

* A generating set for a permutation group:
  [
  G = \langle \sigma_1, \dots, \sigma_k \rangle \leq S_n
  ]

* A **canonical labeling function**:
  [
  \text{can}_G(x) = \text{canonical representative of orbit } G \cdot x
  ]

(Think: graph canonicalization à la *nauty*, but keyed by ( G ))

---

### Public parameters

* A family of base representatives:
  [
  {x_m \in X \mid m \in {0,1}^k}
  ]

These define distinct orbits:
[
\mathcal{O}_m = G \cdot x_m
]

---

### Encryption

To encrypt message ( m ):

1. Sample random ( g \in G )
2. Compute:
   [
   y = g \cdot x_m
   ]
3. Add light noise / masking:

   * flip a small number of bits, or
   * apply a public random permutation ( \pi )

Output:
[
c = \pi(y) \oplus \text{noise}
]

---

### Decryption

1. Undo public masking:
   [
   y' = \pi^{-1}(c)
   ]

2. Use secret ( G ) to canonicalize:
   [
   x^* = \text{can}_G(y')
   ]

3. Look up:
   [
   m \text{ such that } x^* = x_m
   ]

---

## 1.3. Security Intuition

Without ( G ), attacker faces:

* **Orbit membership problem**:

  * Given ( y ), which ( x_m ) orbit is it in?

* This reduces to problems like:

  * Graph isomorphism (if ( X ) = graphs)
  * Code equivalence
  * Permutation group equivalence

These are believed hard in general (GI is quasi-poly, but still nontrivial and tunable).

So attacker sees:

> Samples from many orbits that are computationally indistinguishable → apparent collapse.

---

## 1.4. Where Symmetry Lives

* Symmetry = permutation group ( G )
* Collapse = inability to detect orbit structure
* Key = ability to compute canonical representatives

This is almost a literal implementation of your idea.

---

## 1.5. Weaknesses (important)

* Canonical labeling must be efficient for the key holder but hard otherwise
* Need careful design to avoid:

  * statistical leakage between orbits
  * distinguishing invariants (degree sequences, etc.)

So in practice:

* you’d use **highly irregular base objects**
* and possibly compose with hashing / randomness

---

# 2. Isogeny-Orbit Encryption (IOE)

This version is closer to modern post-quantum crypto and arguably deeper.

---

## 2.1. High-Level Picture

* Space ( X ) = set of elliptic curves (over ( \mathbb{F}_p ))
* Group action = **isogenies**
* Structure = isogeny graph

Key fact:

* Graph is highly regular but **navigation is hard without structure**

---

## 2.2. Secret Structure

We pick:

* A starting curve ( E_0 )
* A secret isogeny path:
  [
  \phi = \phi_1 \circ \cdots \circ \phi_k
  ]

This defines:
[
E_s = \phi(E_0)
]

The secret is:

* how to navigate the graph locally (trapdoor structure)

---

## 2.3. Message Encoding

Assign messages to **regions of the graph**:

* Partition nodes via:

  * hash of j-invariant
  * or distance from special subgraph
  * or cosets of an implicit class group action

So:
[
m \leftrightarrow \text{subset } \mathcal{O}_m \subset X
]

---

## 2.4. Encryption

To encrypt ( m ):

1. Start at public curve ( E_0 )

2. Perform a random walk constrained to region ( \mathcal{O}_m ):
   [
   E \xrightarrow{\text{random isogenies}} E_c
   ]

3. Output:
   [
   c = j(E_c)
   ]

---

## 2.5. Decryption

With secret structure:

* You can:

  * efficiently **navigate the graph**
  * compute distances or invariants invisible to attacker

So you:

1. Lift ( j(E_c) \to E_c )
2. Use trapdoor to:

   * determine which region ( \mathcal{O}_m ) it belongs to

---

## 2.6. Security Intuition

Without the key:

* Isogeny graph looks like an expander
* Random walks mix rapidly
* Local structure gives almost no global information

So:

> All ciphertexts look like random curves → “collapsed” space

With the key:

* Hidden structure gives a coordinate system
* You can distinguish regions

---

## 2.7. Relation to Known Systems

This connects to:

* CSIDH (commutative group action)
* SIDH/SIKE (now broken, but conceptually relevant)
* class group actions on elliptic curves

Your twist is:

> Use the action not just for key exchange, but to encode *orbit identity as message*

---

# 3. Unifying View

Both constructions implement:

### Encryption

[
c = \text{random element of orbit } \mathcal{O}_m
]

### Decryption

[
m = \text{identify orbit using hidden symmetry}
]

---

# 4. Why This Matches “State Space Collapse”

From attacker’s view:

* Cannot compute invariants
* Cannot classify orbits
* Cannot navigate structure

So:

* All samples look drawn from the same distribution

→ **effective singularity**

From key holder’s view:

* Orbit structure is clear
* Space has geometry

→ **symmetry restored**

---

# 5. Subtle but Important Insight

This construction reveals something deeper:

> Security does not come from “hiding data” but from **hiding the equivalence relation that makes data meaningful**.

That’s stronger than standard encryption intuition.

---

# 6. Where This Could Become Novel Research

The most interesting unexplored direction here is:

* Designing **orbit families with zero efficiently computable invariants**
* but **fast canonicalization with a trapdoor**

Especially in:

* non-abelian group actions
* expander-like combinatorial structures
* higher-dimensional algebraic objects

---

## Final Synthesis

A clean formulation of your idea in this setting:

> Encryption samples from symmetry orbits in a space where orbit structure is computationally hidden; without the symmetry, the space collapses into an indistinguishable distribution, while the key restores the partition into meaningful equivalence classes.

---
