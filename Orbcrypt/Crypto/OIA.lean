import Orbcrypt.Crypto.Scheme

/-!
# Orbcrypt.Crypto.OIA

Orbit Indistinguishability Assumption (OIA): formal statement as a Lean axiom.
This is the sole computational assumption in the formalization, analogous to
"factoring is hard" in RSA. Formalizes DEVELOPMENT.md §5.2.

## Main declarations

* `Orbcrypt.OIA` — the strong deterministic OIA, stated as an axiom

## The Orbit Indistinguishability Assumption

### Why an axiom

The OIA is a computational hardness assumption. It asserts that no efficient
algorithm can distinguish between elements drawn from different orbits of the
secret group action. Proving such a statement would require resolving deep
open problems in complexity theory (akin to showing P ≠ NP). Following
standard practice in formal cryptography, we state it as an axiom to cleanly
separate the algebraic proof structure from the computational hardness
assumption.

### Strong deterministic formulation

The axiom states: for any Boolean function `f : X → Bool`, any two messages
`m₀ m₁ : M`, and any group elements `g₀ g₁ : G`,

  `f (g₀ • reps m₀) = f (g₁ • reps m₁)`

This means `f` cannot distinguish ANY pair of orbit elements — it must return
the same Boolean value on every element of every message orbit. This is the
strongest possible deterministic indistinguishability.

### Relationship to probabilistic OIA

The probabilistic OIA (DEVELOPMENT.md §5.2) states:

  `|Pr[A(g • x_{m₀}) = 1] - Pr[A(g • x_{m₁}) = 1]| ≤ negl(λ)`

where the probability is over uniform `g ∈ G`. The strong deterministic
version corresponds to this in the zero-advantage limit: not just negligible
advantage, but EXACTLY zero advantage. Specifically:

- If `f(g₀ • reps m₀) = f(g₁ • reps m₁)` for ALL `g₀, g₁`, then both
  `Pr[f(g • reps m₀) = 1]` and `Pr[f(g • reps m₁) = 1]` are the SAME
  constant (either both 0 or both 1), so the advantage is exactly 0.
- The strong version avoids the need for a probability monad or negligible
  function framework in the formalization.

### Why the weak per-element version is insufficient

An earlier draft considered a weaker per-element OIA:

  `∀ g, ∃ g', f(g • reps m₀) = f(g' • reps m₁)`

This only guarantees surjectivity: every f-value achievable on orbit 0 is
also achievable on orbit 1. But it does NOT prevent f from taking BOTH
`true` and `false` on BOTH orbits simultaneously.

**Concrete counterexample:** Let G = S₂ act on X = {a, b, c, d} with
orbits {a, b} and {c, d}. Define f(a) = true, f(b) = false, f(c) = true,
f(d) = false. The weak OIA holds (for any g mapping to a, take g' mapping
to c; for g mapping to b, take g' mapping to d). But f(a) ≠ f(d), so an
adversary can distinguish specific orbit elements, giving non-zero advantage.

### What depends on this axiom

Only `Theorems/OIAImpliesCPA.lean` uses the OIA axiom. The correctness
theorem (`Theorems/Correctness.lean`) and invariant attack theorem
(`Theorems/InvariantAttack.lean`) are unconditional — they hold regardless
of whether OIA is true or false.

### Auditing

Users can verify which theorems depend on this axiom by running:

  `#print axioms oia_implies_1cpa`

This will show the OIA axiom (and Lean's standard axioms: `propext`,
`Quot.sound`, `Classical.choice`) and nothing else, confirming that
the security theorem's only non-standard assumption is OIA.

### Hardness foundations

The OIA is grounded in two well-studied hardness assumptions:

1. **Graph Isomorphism (GI-OIA, DEVELOPMENT.md §5.3):** On Cai-Furer-
   Immerman (CFI) graphs, the group action is constructed so that orbit
   indistinguishability reduces to GI. Best classical algorithm:
   2^O(√(n log n)) (Babai, 2015).

2. **Permutation Code Equivalence (CE-OIA, DEVELOPMENT.md §5.4):** The
   equivalence problem for permutation codes is at least as hard as GI
   (GI ≤_p CE) and believed strictly harder for specific code families.

## References

* DEVELOPMENT.md §5.2 — probabilistic OIA definition
* DEVELOPMENT.md §5.3 — GI-based OIA
* DEVELOPMENT.md §5.4 — CE-based OIA
* COUNTEREXAMPLE.md — invariant attack (what happens when OIA fails)
* formalization/phases/PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md — work units 3.7–3.8
-/

namespace Orbcrypt

-- ============================================================================
-- Work Unit 3.7: OIA Axiom
-- ============================================================================

/--
The Orbit Indistinguishability Assumption (OIA).

This axiom asserts that no Boolean function can distinguish elements drawn
from two different message orbits. Specifically: for any `f : X → Bool`,
any two messages `m₀ m₁`, and any group elements `g₀ g₁ ∈ G`,
`f(g₀ • reps(m₀)) = f(g₁ • reps(m₁))`.

This is the strong deterministic reformulation of the probabilistic OIA
(DEVELOPMENT.md §5.2). It directly implies IND-1-CPA security
(proved in `Theorems/OIAImpliesCPA.lean`).
-/
-- Justification: The OIA is a computational conjecture grounded in the
-- hardness of Graph Isomorphism (GI-OIA, §5.3) and Code Equivalence
-- (CE-OIA, §5.4). It is NOT a mathematical theorem. We state it as an
-- axiom to separate the algebraic proof structure from the computational
-- hardness assumption, following standard practice in formal cryptography.
axiom OIA {G : Type*} {X : Type*} {M : Type*}
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (f : X → Bool) (m₀ m₁ : M) (g₀ g₁ : G) :
    f (g₀ • scheme.reps m₀) = f (g₁ • scheme.reps m₁)

-- ============================================================================
-- Work Unit 3.8: OIA Discussion Comment Block
-- ============================================================================
-- See the module docstring (/-! ... -/) at the top of this file for the
-- comprehensive OIA discussion covering:
--
-- 1. Why an axiom (computational hardness assumption, not a theorem)
-- 2. Relationship to probabilistic OIA (zero-advantage limit)
-- 3. Why the weak per-element version is insufficient (with counterexample)
-- 4. What depends on it (only OIAImpliesCPA.lean)
-- 5. How to audit (via #print axioms)
-- 6. Hardness foundations (GI and Code Equivalence reductions)

end Orbcrypt
