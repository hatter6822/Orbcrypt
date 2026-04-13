The following is a *counterexample* that would be unsafe but seems good/secure.


# 1. Setup: A Seemingly Good POE Instance

Let:

* ( X = {0,1}^n )
* ( G = S_n ) (full symmetric group)
* Action: permute coordinates

So:
[
g \cdot x = (x_{g^{-1}(1)}, \dots, x_{g^{-1}(n)})
]

---

## 1.1. Orbits

Under ( S_n ), the orbit of a vector is:

[
\mathcal{O}(x) = { y \in {0,1}^n \mid \text{Hamming weight}(y) = \text{wt}(x) }
]

So orbits are **perfectly mixed**:

* every vector with same weight is reachable
* sampling ( g \cdot x ) gives a **uniform random string of that weight**

This looks excellent:

* huge orbits
* strong mixing
* high entropy

---

## 1.2. Message Encoding

Let messages be bits:

* ( m = 0 ): choose ( x_0 ) with weight ( n/3 )
* ( m = 1 ): choose ( x_1 ) with weight ( 2n/3 )

These define two disjoint orbits:
[
\mathcal{O}_0, \mathcal{O}_1
]

---

## 1.3. Encryption

To encrypt ( m ):

1. Sample ( g \leftarrow S_n )
2. Compute:
   [
   y = g \cdot x_m
   ]

Output:
[
c = y
]

(We can even add a random permutation mask—it won’t help.)

---

# 2. Why It *Looks* Secure

From a high-level view:

* Each ciphertext is a **random element of a large orbit**
* The group action is maximally mixing
* Positions carry no information
* Structure seems destroyed

This matches the intuition:

> “Without symmetry, the space collapses.”

But that intuition is incomplete.

---

# 3. The Subtle Invariant

Define:

[
f(x) = \text{Hamming weight of } x
]

Key properties:

* **Efficiently computable** (linear time)

* **Invariant under ( S_n )**:
  [
  f(g \cdot x) = f(x)
  ]

* **Separates messages**:
  [
  f(x_0) = n/3,\quad f(x_1) = 2n/3
  ]

---

# 4. Attack (Breaks IND-CPA)

Given challenge ciphertext ( c^* ):

1. Compute:
   [
   w = \text{wt}(c^*)
   ]

2. Decide:

* if ( w = n/3 ), output ( m=0 )
* if ( w = 2n/3 ), output ( m=1 )

---

## 4.1. Advantage

[
\Pr[b' = b] = 1
]

So:

[
\text{Adv}^{\text{IND-CPA}} = \frac{1}{2}
]

Maximum possible break.

---

# 5. Why This Is Subtle

You might say: “Well, Hamming weight is obvious.”

But here’s the deeper point:

### The failure is not lack of mixing

* Orbits are maximally large
* Sampling is perfectly uniform
* Entropy is high

### The failure is:

> The quotient map ( X \to X/G ) is *easy to compute*

In this case:
[
X/G \cong {0,1,\dots,n}
]
via Hamming weight.

So the attacker can compute:

[
x \mapsto \mathcal{O}(x)
]

exactly.

---

# 6. Stronger Counterexample (Less Obvious Invariant)

Let’s make it more “subtle”.

---

## 6.1. Use Graphs Instead of Bitstrings

Let:

* ( X ) = adjacency matrices of graphs on ( n ) vertices
* ( G = S_n ) acting by relabeling vertices

Now:

* Orbits = **isomorphism classes of graphs**
* Sampling ( g \cdot x ) = random relabeling

---

## 6.2. Message Encoding

Pick:

* ( x_0 ): graph with a triangle
* ( x_1 ): graph with no triangle

---

## 6.3. Invariant

Define:

[
f(x) = \text{number of triangles in graph}
]

* Invariant under permutations
* Efficiently computable: ( O(n^3) )

---

## 6.4. Attack

* Compute triangle count
* Distinguish immediately

---

### Key Point

Even though:

* Full permutation mixing is used
* Graph isomorphism may be hard

The scheme fails because:

> **You don’t need full orbit recovery—just one separating invariant**

---

# 7. General Failure Pattern

This gives a general theorem-like insight:

---

## Invariant Attack Principle

If there exists an efficiently computable function ( f ) such that:

1. ( f(g \cdot x) = f(x) ) for all ( g \in G )
2. ( f(x_{m_0}) \neq f(x_{m_1}) )

then POE is **not IND-CPA secure**.

---

# 8. Deeper Interpretation

Your original idea:

> Without symmetry ⇒ collapse to a singularity

This counterexample shows:

> Even with hidden symmetry, **partial invariants prevent full collapse**

More precisely:

* The attacker doesn’t need full structure
* Any **residual invariant = crack in the collapse**

So the space doesn’t collapse to a single point—it collapses to:

[
\text{Image}(f)
]

which may still be large enough to encode the message.

---

# 9. What True “Collapse” Requires

For your idea to work cryptographically, you need:

> **No efficiently computable nontrivial invariants**

Formally:

For all PPT ( f ):

[
f(g \cdot x_{m_0}) \approx f(g \cdot x_{m_1})
]

This is *much stronger* than orbit mixing.

---

# 10. Final Insight

This counterexample exposes the exact boundary:

* **Mixing (group action)** gives entropy
* **Security** requires destroying *all accessible invariants*

So:

> Encryption is not just hiding symmetry—it is hiding every efficiently computable shadow of that symmetry.

Or:

> The state space only truly “collapses” if *every observable that survives symmetry is also hidden*.
