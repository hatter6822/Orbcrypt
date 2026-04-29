<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Phase 3 — Cryptographic Definitions

## Weeks 5–6 | 8 Work Units | ~18 Hours

*Part of the [Orbcrypt Lean 4 Formalization Plan](../FORMALIZATION_PLAN.md)*

---

## Overview

Phase 3 defines the cryptographic layer of the formalization: the abstract
orbit encryption scheme, the adversary model, and the Orbit Indistinguishability
Assumption. These definitions bridge the mathematical foundations (Phase 2) and
the theorem proofs (Phase 4).

This phase has **two parallel tracks** after the scheme definition (units
3.1–3.3): the security game track (3.4–3.6) and the OIA track (3.7–3.8).

---

## Objectives

1. A complete `OrbitEncScheme` structure with `encrypt` and `decrypt` functions
   that formally capture DEVELOPMENT.md §4.1.
2. A deterministic adversary model and IND-CPA advantage definition that
   abstracts DEVELOPMENT.md §4.3.
3. The OIA stated as a Lean axiom with clear documentation explaining the
   relationship to the probabilistic definition in DEVELOPMENT.md §5.2.

---

## Prerequisites

- Phase 2 complete: all `GroupAction/` modules compile without `sorry`.
- In particular: `CanonicalForm` structure (2.5) and `IsGInvariant` (2.8) are
  available.

---

## Work Units

### 3.1 — Scheme Structure

**Effort:** 3 hours
**Module:** `Crypto/Scheme.lean`
**Deliverable:** `OrbitEncScheme` structure definition.
**Dependencies:** Phase 2 (specifically 2.5, CanonicalForm)

#### Implementation Guidance

```lean
import Orbcrypt.GroupAction.Basic
import Orbcrypt.GroupAction.Canonical

/--
An Abstract Orbit Encryption (AOE) scheme. Formalizes DEVELOPMENT.md §4.1.

The scheme is parameterized by:
- `G`: the secret group (key)
- `X`: the ciphertext space
- `M`: the message space

The scheme consists of:
- `reps`: a function mapping each message to its orbit representative
- `reps_distinct`: a proof that distinct messages map to distinct orbits
- `canonForm`: a canonical form function for the group action
-/
structure OrbitEncScheme (G : Type*) (X : Type*) (M : Type*)
    [Group G] [MulAction G X] [DecidableEq X] where
  /-- Maps each message to its orbit representative. -/
  reps : M → X
  /-- Distinct messages have representatives in distinct orbits. -/
  reps_distinct : ∀ m₁ m₂ : M, m₁ ≠ m₂ →
    MulAction.orbit G (reps m₁) ≠ MulAction.orbit G (reps m₂)
  /-- The canonical form function used for decryption. -/
  canonForm : CanonicalForm G X
```

**Design decisions:**
- `M` is left abstract (not required to be `Fintype` yet). The `Fintype M`
  constraint is added only where needed (specifically, in `decrypt`).
- `DecidableEq X` is needed for the lookup in `decrypt`.
- The scheme is symmetric-key: `G` (the group) serves as the secret key.

---

### 3.2 — Encrypt Function

**Effort:** 1 hour
**Module:** `Crypto/Scheme.lean`
**Deliverable:** `encrypt` function definition.
**Dependencies:** 3.1

#### Implementation Guidance

```lean
/--
Encryption: apply a group element to the orbit representative of the message.
Enc(sk, m) = g • reps(m) for a uniformly sampled g ∈ G.

In the formalization, `g` is a parameter (not sampled), since we work in a
deterministic setting. The probabilistic sampling is abstracted by quantifying
over all `g ∈ G` in the security definitions.
-/
def encrypt [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (g : G) (m : M) : X :=
  g • scheme.reps m
```

This is a one-liner, but it is important to have it as a named definition so
that the correctness theorem can unfold it cleanly.

---

### 3.3 — Decrypt Function

**Effort:** 4 hours
**Module:** `Crypto/Scheme.lean`
**Deliverable:** `decrypt` function definition using `Fintype.find` or
equivalent.
**Dependencies:** 3.1, 2.5

#### Implementation Guidance

```lean
/--
Decryption: compute the canonical form of the ciphertext, then find the
message whose representative has the same canonical form.

Returns `some m` if a matching message is found, `none` otherwise.
For honestly generated ciphertexts, this always returns `some m`
(proved in Phase 4, Theorem `correctness`).
-/
def decrypt [Group G] [MulAction G X] [DecidableEq X]
    [Fintype M] [DecidableEq M]
    (scheme : OrbitEncScheme G X M) (c : X) : Option M :=
  Fintype.find? (fun m => scheme.canonForm.canon c = scheme.canonForm.canon (scheme.reps m))
```

**Implementation challenges:**

1. **`Fintype M` requirement:** `decrypt` must search over all messages to find
   a match. This requires `M` to be a finite type with decidable equality.
   Add `[Fintype M]` and `[DecidableEq M]` to the context.

2. **`Fintype.find?` vs alternatives:** Lean 4's `Fintype` provides several
   search mechanisms:
   - `Fintype.find?` — returns `Option M`, matching our signature.
   - Manual construction via `Finset.univ.find?`.
   Choose whichever has better lemma support in Mathlib.

3. **`DecidableEq X` for canonical form comparison:** The comparison
   `scheme.canonForm.canon c = scheme.canonForm.canon (scheme.reps m)` requires
   `DecidableEq X`.

4. **Alternative: direct definition via `Option.map`:**
   ```lean
   def decrypt ... (c : X) : Option M :=
     (Finset.univ.filter (fun m =>
       scheme.canonForm.canon c = scheme.canonForm.canon (scheme.reps m)
     )).min'  -- or similar
   ```
   Choose the approach that makes the correctness proof (4.3) cleanest.

#### Risks

| Risk | Mitigation |
|------|------------|
| `Fintype.find?` specification lemmas are weak | Switch to `Finset.univ.find?` which has richer API |
| Performance issues with `DecidableEq` on large types | Not a concern for formalization (proofs, not computation) |
| `sorry` in `DecidableEq` instances | Ensure all types used have proper `DecidableEq` instances |

---

### 3.4 — Adversary Structure

**Effort:** 2 hours
**Module:** `Crypto/Security.lean`
**Deliverable:** `Adversary` structure definition.
**Dependencies:** 3.1

#### Implementation Guidance

```lean
import Orbcrypt.Crypto.Scheme

/--
A deterministic adversary for the IND-1-CPA game. Formalizes the adversary
model from DEVELOPMENT.md §4.3.

Since we work in a deterministic setting (no probability monad), the adversary
is a pair of pure functions:
- `choose`: given the public orbit representatives, select a challenge pair
- `guess`: given the representatives and a challenge ciphertext, output a bit

The probabilistic aspects (random coins for the adversary, random group element
for the challenger) are abstracted by quantifying over all possible values.
-/
structure Adversary (X : Type*) (M : Type*) where
  /-- Choose two challenge messages given the orbit representatives. -/
  choose : (M → X) → M × M
  /-- Guess which message was encrypted, given reps and the challenge ciphertext. -/
  guess : (M → X) → X → Bool
```

**Design note:** The adversary sees the orbit representatives (`reps : M → X`)
as public parameters, but does not see the secret group `G`. This matches the
security model in DEVELOPMENT.md §4.3 where `params` (including {x_m}) is
public but `sk` (including G) is secret.

---

### 3.5 — 1-CPA Advantage Definition

**Effort:** 3 hours
**Module:** `Crypto/Security.lean`
**Deliverable:** `hasAdvantage` predicate.
**Dependencies:** 3.4, 3.2

#### Implementation Guidance

```lean
/--
An adversary "has advantage" if there exist group elements g₀, g₁ such that
the adversary's guess differs on encryptions of its two chosen messages.

This is a deterministic abstraction of non-zero advantage in the probabilistic
IND-1-CPA game. In the probabilistic setting, advantage is:
  |Pr[A(g • x_{m₀}) = 1] - Pr[A(g • x_{m₁}) = 1]| / 2

The deterministic version captures the key idea: the adversary can produce
*some* distinguishing behavior between the two orbits.
-/
def hasAdvantage [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) : Prop :=
  let (m₀, m₁) := A.choose scheme.reps
  ∃ g₀ g₁ : G,
    A.guess scheme.reps (g₀ • scheme.reps m₀) ≠
    A.guess scheme.reps (g₁ • scheme.reps m₁)
```

**Why this formulation works:** If no group elements produce different guesses,
then the adversary's guess function is "orbit-blind" — it cannot tell which
orbit a ciphertext came from, regardless of the specific group element used.
This corresponds to zero advantage in the probabilistic game.

---

### 3.6 — IND-1-CPA Security Definition

**Effort:** 2 hours
**Module:** `Crypto/Security.lean`
**Deliverable:** `IsSecure` predicate.
**Dependencies:** 3.5

#### Implementation Guidance

```lean
/--
A scheme is IND-1-CPA secure if no adversary has advantage.

This is the deterministic analogue of: for all PPT adversaries A,
Adv^{IND-1-CPA}_A(λ) ≤ negl(λ).
-/
def IsSecure [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) : Prop :=
  ∀ (A : Adversary X M), ¬ hasAdvantage scheme A
```

**Relationship to the full definition:** This captures IND-1-CPA (single-query,
no oracle). The full IND-CPA with adaptive oracle queries (DEVELOPMENT.md §8.2)
requires modeling stateful adversaries and sequential oracle interactions,
which is beyond the current scope.

---

### 3.7 — OIA Axiom

**Effort:** 2 hours
**Module:** `Crypto/OIA.lean`
**Deliverable:** OIA stated as a Lean axiom.
**Dependencies:** 3.1

#### Implementation Guidance

```lean
import Orbcrypt.Crypto.Scheme

/--
The Orbit Indistinguishability Assumption (OIA).

This axiom asserts that no Boolean function can distinguish elements drawn
from two different message orbits. Specifically: for any `f : X → Bool`,
any two messages `m₀ m₁`, and any group elements `g₀ g₁ ∈ G`,
`f(g₀ • reps(m₀)) = f(g₁ • reps(m₁))`.

This is the strong deterministic reformulation of the probabilistic OIA
(DEVELOPMENT.md §5.2), which states:

  |Pr[A(g • x_{m₀}) = 1] - Pr[A(g • x_{m₁}) = 1]| ≤ negl(λ)

The probabilistic OIA says the *distributions* of f-values are close when
sampling g uniformly. The strong deterministic version says f gives the
*same value* at every pair of orbit elements — equivalent to saying that
the orbit distributions are identical (not just close). This is the natural
deterministic analogue and directly implies IND-1-CPA security.

**Why not the weaker per-element version?** An earlier draft used:
  `∀ g, ∃ g', f(g • reps m₀) = f(g' • reps m₁)`
This only guarantees surjectivity (every f-value on orbit 0 is achievable
on orbit 1), but does NOT prevent a function from taking both `true` and
`false` on both orbits simultaneously. In that case, `hasAdvantage` holds
even though the weak OIA holds. Concrete counterexample: G = S₂ acting on
two 2-element orbits, f(a)=T, f(b)=F, f(c)=T, f(d)=F — weak OIA holds
but f(a) ≠ f(d) gives advantage. The strong version prevents this.

-- Justification: The OIA is a computational conjecture grounded in the
-- hardness of Graph Isomorphism (GI-OIA, §5.3) and Code Equivalence
-- (CE-OIA, §5.4). It is NOT a mathematical theorem. We state it as an
-- axiom to separate the algebraic proof structure from the computational
-- hardness assumption, following standard practice in formal cryptography.
-/
axiom OIA [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (f : X → Bool) (m₀ m₁ : M) (g₀ g₁ : G) :
    f (g₀ • scheme.reps m₀) = f (g₁ • scheme.reps m₁)
```

**Critical design choice:** The OIA is stated as an `axiom`, not a `theorem`.
This makes explicit that it is an unproven assumption. Lean's `#print axioms`
command will show which theorems depend on it, providing transparency about
what is conditional.

**What the strong OIA implies:** `f` is constant on `orbit(m₀) ∪ orbit(m₁)`
for every Boolean `f`. This is the strongest possible deterministic
indistinguishability — no Boolean test can separate the orbits at *any*
pair of points. It models the probabilistic OIA in the limit where
advantage is exactly zero (not just negligible).

**Alternative formulation (weaker, NOT sufficient):**
```lean
-- DO NOT USE: this version is too weak for the security theorem.
axiom OIA_weak ... (f : X → Bool) (m₀ m₁ : M) (g : G) :
    ∃ g' : G, f (g • scheme.reps m₀) = f (g' • scheme.reps m₁)
```
This per-element surjectivity version only guarantees image equality, not
value equality. See the counterexample above for why it fails.

---

### 3.8 — OIA Discussion Comment Block

**Effort:** 1 hour
**Module:** `Crypto/OIA.lean`
**Deliverable:** Detailed documentation explaining the OIA's role and
limitations.
**Dependencies:** 3.7

#### Implementation Guidance

Add a comprehensive comment block to `OIA.lean` explaining:

1. **Why an axiom:** The OIA is a computational hardness assumption. Proving it
   would require showing P ≠ NP-type separations, which is far beyond current
   mathematics.

2. **Relationship to probabilistic OIA:** The strong deterministic OIA
   (`∀ g₀ g₁, f(g₀•m₀) = f(g₁•m₁)`) corresponds to the probabilistic OIA
   in the zero-advantage limit (identical distributions, not just close).
   It is strictly stronger than the probabilistic "negligible advantage"
   version, but it avoids the need for a probability monad. An earlier
   per-element version (`∀ g, ∃ g', ...`) was found to be insufficient —
   see the counterexample documented in unit 3.7.

3. **What depends on it:** Only `Theorems/OIAImpliesCPA.lean` uses the OIA
   axiom. The correctness theorem and invariant attack theorem are
   unconditional.

4. **Auditing:** Users can run `#print axioms oia_implies_1cpa` to verify that
   this theorem depends on the OIA axiom (and Lean's standard axioms) and
   nothing else.

---

## Parallel Execution Plan

```
         3.1 Scheme Structure
                  │
                  ▼
         3.2 Encrypt Function
                  │
                  ▼
         3.3 Decrypt Function
              /        \
             /          \
            ▼            ▼
   Track A: Security    Track B: OIA
   ┌──────────────┐    ┌──────────────┐
   │ 3.4 Adversary │    │ 3.7 OIA Axiom│
   │ 3.5 Advantage │    │ 3.8 Comments │
   │ 3.6 IsSecure  │    └──────────────┘
   └──────────────┘
```

**Optimal schedule for a single contributor:**

| Day | Work | Hours | Running Total |
|-----|------|-------|---------------|
| 1 | 3.1 (Scheme structure) + 3.2 (encrypt) | 4h | 4h |
| 2 | 3.3 (decrypt) | 4h | 8h |
| 3 | 3.4 (adversary) + 3.7 (OIA axiom) | 4h | 12h |
| 4 | 3.5 (advantage) + 3.8 (OIA comments) | 4h | 16h |
| 5 | 3.6 (IsSecure) | 2h | 18h |

---

## Risk Analysis

| Risk | Units Affected | Likelihood | Impact | Mitigation |
|------|---------------|-----------|--------|------------|
| `decrypt` implementation is tricky with `Fintype.find?` | 3.3 | High | Medium | Prototype multiple approaches; accept a less elegant implementation if needed |
| OIA axiom formulation too strong/weak for Phase 4 proofs | 3.7 | Low (resolved) | High | The strong deterministic OIA (`∀ g₀ g₁, f(g₀•m₀) = f(g₁•m₁)`) was chosen after identifying that the per-element version (`∀ g, ∃ g', ...`) is provably insufficient — see counterexample in 3.7 documentation. Still validate with a toy model where OIA holds (e.g., trivial group). |
| `Adversary` structure doesn't compose well with advantage | 3.4, 3.5 | Low | Medium | The structure is simple enough that refactoring is cheap |
| `let (m₀, m₁) := ...` pattern causes issues in `Prop` | 3.5 | Medium | Low | Replace with explicit `Prod.fst` / `Prod.snd` if needed |

### Pre-Validation Recommendation

Before committing to the OIA axiom formulation (3.7), **sketch the proof of
OIA ⟹ IND-1-CPA** (Phase 4, unit 4.7) on paper or in a scratch file with
`sorry`. This validates that the axiom is:
1. Strong enough to prove the security theorem.
2. Not so strong as to be trivially false or prove unintended results.

---

## Exit Criteria

All of the following must be true before proceeding to Phase 4:

- [x] `Crypto/Scheme.lean` compiles without `sorry`
- [x] `Crypto/Security.lean` compiles without `sorry`
- [x] `Crypto/OIA.lean` compiles (defines `OIA` as `Prop`, not `axiom` — avoids inconsistency)
- [x] `lake build` succeeds with zero errors
- [x] `#check OrbitEncScheme` succeeds
- [x] `#check encrypt` and `#check decrypt` succeed
- [x] `#check Adversary` and `#check hasAdvantage` succeed
- [x] `#check @OIA` shows the expected type signature
- [x] `decrypt` handles the `Fintype M` requirement correctly
- [x] OIA documentation explains the assumption's role, soundness rationale, and limitations

---

## Transition to Phase 4

With the cryptographic definitions in place, Phase 4 proves the three headline
theorems. Each theorem combines definitions from this phase (the scheme,
adversary, OIA) with lemmas from Phase 2 (orbit membership, canonical form
properties, invariant functions).

See: [Phase 4 — Core Theorems](PHASE_4_CORE_THEOREMS.md)
