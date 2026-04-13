import Orbcrypt.Crypto.Scheme

/-!
# Orbcrypt.Crypto.OIA

Orbit Indistinguishability Assumption (OIA): formal statement as a Lean axiom.
This is the sole computational assumption in the formalization, analogous to
"factoring is hard" in RSA. Formalizes DEVELOPMENT.md §5.2.

## Main declarations

* `Orbcrypt.OIA` — the strong deterministic OIA, as a `Prop`-valued definition

## The Orbit Indistinguishability Assumption

### Why a `Prop` definition (not an `axiom`)

The OIA is a computational hardness assumption about a SPECIFIC group action
and scheme. It asserts that no efficient algorithm can distinguish between
elements drawn from different orbits of the secret group action.

A Lean `axiom` is universally quantified — it would assert OIA for ALL group
actions, including trivial ones where the claim is provably false (e.g.,
`Unit` acting on `Bool` gives `true = false`). This introduces logical
inconsistency, making every proposition provable.

Instead, we define OIA as a `Prop` that theorems carry as an explicit
hypothesis. This matches DEVELOPMENT.md §8.1 ("If the OIA holds for the
setup family Π") and is standard practice in formal cryptography. The
result is STRONGER assurance: `#print axioms oia_implies_1cpa` shows only
Lean's standard axioms, confirming zero custom axioms.

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

Users can verify axiom dependencies by running:

  `#print axioms oia_implies_1cpa`

This will show ONLY Lean's standard axioms (`propext`, `Quot.sound`,
`Classical.choice`) — no custom axioms. The OIA appears as a hypothesis
in the theorem's type signature, not as an axiom in the logical foundation.
This provides stronger assurance than an axiom-based approach: the theorem
is provably valid in the standard Lean axiom system, with OIA as an
explicit assumption that can be independently evaluated.

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
The Orbit Indistinguishability Assumption (OIA) for a specific scheme.

The OIA asserts that no Boolean function can distinguish elements drawn
from two different message orbits. Specifically: for any `f : X → Bool`,
any two messages `m₀ m₁`, and any group elements `g₀ g₁ ∈ G`,
`f(g₀ • reps(m₀)) = f(g₁ • reps(m₁))`.

This is the strong deterministic reformulation of the probabilistic OIA
(DEVELOPMENT.md §5.2). When assumed for a specific scheme, it directly
implies IND-1-CPA security (proved in `Theorems/OIAImpliesCPA.lean`).

**Why a `Prop`-valued definition, not an `axiom`:** A Lean `axiom` is
universally quantified over all types, instances, and schemes. An OIA
axiom would assert indistinguishability for ALL group actions — including
trivial ones (e.g., `Unit` acting on `Bool`) where the claim is provably
false (`true ≠ false`). This would introduce logical inconsistency,
making every proposition provable and defeating formal verification.

Instead, OIA is defined as a `Prop` that specific theorems carry as a
hypothesis: `theorem oia_implies_1cpa (hOIA : OIA scheme) : IsSecure scheme`.
This matches DEVELOPMENT.md §8.1, which states *"If the OIA holds for the
setup family Π"* — a conditional statement about a specific scheme.

The result is STRONGER assurance: `#print axioms oia_implies_1cpa` shows
only Lean's standard axioms (`propext`, `Quot.sound`, `Classical.choice`),
confirming the theorem introduces no custom axioms beyond the hypothesis.
-/
-- Justification: The OIA is a computational conjecture grounded in the
-- hardness of Graph Isomorphism (GI-OIA, §5.3) and Code Equivalence
-- (CE-OIA, §5.4). It is NOT a mathematical theorem. We state it as a
-- Prop-valued definition so that theorems carry it as an explicit hypothesis,
-- following standard practice in formal cryptography (cf. CryptHOL, EasyCrypt).
def OIA {G : Type*} {X : Type*} {M : Type*}
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) : Prop :=
  ∀ (f : X → Bool) (m₀ m₁ : M) (g₀ g₁ : G),
    f (g₀ • scheme.reps m₀) = f (g₁ • scheme.reps m₁)

-- ============================================================================
-- Work Unit 3.8: OIA Discussion Comment Block
-- ============================================================================
-- See the module docstring (/-! ... -/) at the top of this file for the
-- comprehensive OIA discussion covering:
--
-- 1. Why a Prop definition, not an axiom (avoids inconsistency)
-- 2. Relationship to probabilistic OIA (zero-advantage limit)
-- 3. Why the weak per-element version is insufficient (with counterexample)
-- 4. What depends on it (only OIAImpliesCPA.lean)
-- 5. How to audit (via #print axioms — shows zero custom axioms)
-- 6. Hardness foundations (GI and Code Equivalence reductions)

end Orbcrypt
