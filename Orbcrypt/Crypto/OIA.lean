/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.Crypto.Scheme

/-!
# Orbcrypt.Crypto.OIA

Orbit Indistinguishability Assumption (OIA): formal statement as a
`Prop`-valued definition. This is the sole computational assumption in the
formalization, analogous to "factoring is hard" in RSA.
Formalizes docs/DEVELOPMENT.md §5.2.

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
hypothesis. This matches docs/DEVELOPMENT.md §8.1 ("If the OIA holds for the
setup family Π") and is standard practice in formal cryptography. The
result is STRONGER assurance: `#print axioms oia_implies_1cpa` shows only
Lean's standard axioms, confirming zero custom axioms.

### Strong deterministic formulation

OIA states: for any Boolean function `f : X → Bool`, any two messages
`m₀ m₁ : M`, and any group elements `g₀ g₁ : G`,

  `f (g₀ • reps m₀) = f (g₁ • reps m₁)`

This means `f` cannot distinguish ANY pair of orbit elements — it must return
the same Boolean value on every element of every message orbit. This is the
strongest possible deterministic indistinguishability.

### Strength and limitations of the deterministic formulation

The strong deterministic OIA quantifies over ALL Boolean functions `f : X → Bool`,
including those that can detect membership in a specific orbit (e.g.,
`fun x => decide (x = reps m₀)`). For any scheme with ≥ 2 messages whose
orbit representatives are distinct points, such an `f` witnesses that `OIA`
is unsatisfiable. This means:

- `OIA scheme` is `False` for any non-trivial scheme
- `OIA scheme → IsSecure scheme` is vacuously true (ex falso)
- The theorem captures the ALGEBRAIC STRUCTURE of the security proof, but
  the hypothesis is unrealistically strong

This is a known limitation of the deterministic approach. The probabilistic
OIA (§5.2) restricts to PPT adversaries who cannot efficiently compute
orbit membership without the secret key. Formalizing this requires a
probability monad and computational complexity framework, which are
documented as non-goals for the current scope (see FORMALIZATION_PLAN.md §2).

The formalization still provides value: it machine-checks that the algebraic
argument "OIA-like indistinguishability implies CPA security" is logically
valid. A future probabilistic upgrade would replace the hypothesis with a
meaningful computational assumption while preserving the proof structure.

### Relationship to probabilistic OIA

The probabilistic OIA (docs/DEVELOPMENT.md §5.2) states:

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

### What depends on this assumption

Only `Theorems/OIAImpliesCPA.lean` uses the OIA assumption. The correctness
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

1. **Graph Isomorphism (GI-OIA, docs/DEVELOPMENT.md §5.3):** On Cai-Furer-
   Immerman (CFI) graphs, the group action is constructed so that orbit
   indistinguishability reduces to GI. Best classical algorithm:
   2^O(√(n log n)) (Babai, 2015).

2. **Permutation Code Equivalence (CE-OIA, docs/DEVELOPMENT.md §5.4):** The
   equivalence problem for permutation codes is at least as hard as GI
   (GI ≤_p CE) and believed strictly harder for specific code families.

## References

* docs/DEVELOPMENT.md §5.2 — probabilistic OIA definition
* docs/DEVELOPMENT.md §5.3 — GI-based OIA
* docs/DEVELOPMENT.md §5.4 — CE-based OIA
* docs/COUNTEREXAMPLE.md — invariant attack (what happens when OIA fails)
* docs/dev_history/formalization/phases/PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md — work units 3.7–3.8
-/

namespace Orbcrypt

-- ============================================================================
-- Work Unit 3.7: OIA Definition
-- ============================================================================

/--
The Orbit Indistinguishability Assumption (OIA) for a specific scheme.

The OIA asserts that no Boolean function can distinguish elements drawn
from two different message orbits. Specifically: for any `f : X → Bool`,
any two messages `m₀ m₁`, and any group elements `g₀ g₁ ∈ G`,
`f(g₀ • reps(m₀)) = f(g₁ • reps(m₁))`.

This is the strong deterministic reformulation of the probabilistic OIA
(docs/DEVELOPMENT.md §5.2). When assumed for a specific scheme, it directly
implies IND-1-CPA security (proved in `Theorems/OIAImpliesCPA.lean`).

**Why a `Prop`-valued definition, not an `axiom`:** A Lean `axiom` is
universally quantified over all types, instances, and schemes. An OIA
axiom would assert indistinguishability for ALL group actions — including
trivial ones (e.g., `Unit` acting on `Bool`) where the claim is provably
false (`true ≠ false`). This would introduce logical inconsistency,
making every proposition provable and defeating formal verification.

Instead, OIA is defined as a `Prop` that specific theorems carry as a
hypothesis: `theorem oia_implies_1cpa (hOIA : OIA scheme) : IsSecure scheme`.
This matches docs/DEVELOPMENT.md §8.1, which states *"If the OIA holds for the
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

-- W6.1 of structural review 2026-05-06 (plan
-- `docs/dev_history/AUDIT_2026-05-06_STRUCTURAL_REVIEW.md` § 1 row 7):
-- the deterministic-OIA vacuity witness `det_oia_false_of_distinct_reps`
-- (formerly defined here, audit 2026-04-23 finding C-07) was deleted
-- as part of the deterministic-chain removal scheduled for v0.4.0.
-- The theorem was the leaf of the deterministic chain; later W6
-- commits remove the rest. Historical entry in
-- `docs/dev_history/WORKSTREAM_CHANGELOG.md` under the 2026-04-23
-- Workstream E section.

end Orbcrypt
