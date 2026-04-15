# Orbcrypt — Practical Improvements Workstream Plan

## From Research Formalization to Viable Cryptographic Primitive

*Extension of the [Orbcrypt Lean 4 Formalization Plan](FORMALIZATION_PLAN.md)*

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Current State Assessment](#2-current-state-assessment)
3. [Improvement Taxonomy](#3-improvement-taxonomy)
4. [Phase 7 — KEM Reformulation](#phase-7--kem-reformulation)
5. [Phase 8 — Probabilistic Foundations](#phase-8--probabilistic-foundations)
6. [Phase 9 — Key Compression & Nonce-Based Encryption](#phase-9--key-compression--nonce-based-encryption)
7. [Phase 10 — Authenticated Encryption & Modes](#phase-10--authenticated-encryption--modes)
8. [Phase 11 — Reference Implementation (GAP Prototype)](#phase-11--reference-implementation-gap-prototype)
9. [Phase 12 — Hardness Alignment (LESS/MEDS/TI)](#phase-12--hardness-alignment-lessmedsti)
10. [Phase 13 — Public-Key Extension](#phase-13--public-key-extension)
11. [Phase 14 — Parameter Selection & Benchmarks](#phase-14--parameter-selection--benchmarks)
12. [Phase 15 — Decryption Optimization](#phase-15--decryption-optimization)
13. [Phase 16 — Formal Verification of New Components](#phase-16--formal-verification-of-new-components)
14. [Cross-Cutting Concerns](#cross-cutting-concerns)
15. [Dependency Graph & Parallelism](#dependency-graph--parallelism)
16. [Risk Analysis](#risk-analysis)
17. [Document Update Checklist](#document-update-checklist)
18. [Success Criteria](#success-criteria)

---

## 1. Executive Summary

The Orbcrypt formalization (Phases 1–6) established the mathematical
foundations: correctness, invariant attack characterization, and conditional
security (OIA → IND-1-CPA), all machine-checked in Lean 4 with zero `sorry`
and zero custom axioms.

This plan defines **ten new phases (7–16)** that transform Orbcrypt from a
research formalization into a viable cryptographic primitive. The improvements
address five structural bottlenecks:

| Bottleneck | Current State | Target State |
|-----------|--------------|-------------|
| **Architecture** | Raw orbit encryption (message = orbit index) | KEM + DEM hybrid (standard modern crypto architecture) |
| **Key size** | O(n² log\|G\|) — ~1.8 MB for λ=128 | 256-bit seed with deterministic key expansion |
| **Decryption cost** | O(n^c) partition backtracking, c ≈ 3–5 | Structured fast-path exploiting QC code structure |
| **Security model** | Deterministic OIA (vacuously true for non-trivial schemes) | Probabilistic OIA with computational adversary model |
| **Hardness story** | Informal reduction to GI/CE | Aligned with NIST PQC candidates (LESS, MEDS) |

Secondary improvements include: authenticated encryption, nonce-based
encryption, a GAP reference implementation with benchmarks, public-key
extension via oblivious orbit sampling, and formal verification of new
components.

### Effort Summary

| Phase | Title | Work Units | Effort | Prerequisites |
|-------|-------|-----------|--------|--------------|
| 7 | KEM Reformulation | 8 | ~24h | Phases 1–6 |
| 8 | Probabilistic Foundations | 10 | ~40h | Phases 1–6 |
| 9 | Key Compression & Nonce-Based Enc | 7 | ~18h | Phase 7 |
| 10 | Authenticated Encryption & Modes | 6 | ~16h | Phase 9 |
| 11 | Reference Implementation (GAP) | 9 | ~36h | Phase 7 |
| 12 | Hardness Alignment | 8 | ~32h | Phase 8 |
| 13 | Public-Key Extension | 7 | ~28h | Phases 7, 12 |
| 14 | Parameter Selection & Benchmarks | 6 | ~20h | Phase 11 |
| 15 | Decryption Optimization | 7 | ~22h | Phases 11, 14 |
| 16 | Formal Verification of New Components | 10 | ~36h | Phases 7–10 |
| | **Total** | **78** | **~272h** | |

### Critical Path

The longest sequential dependency chain is:

```
Phase 7 (KEM) → Phase 9 (Key/Nonce) → Phase 10 (AEAD)
    ↓
Phase 11 (GAP) → Phase 14 (Params) → Phase 15 (Decryption Opt)
```

Estimated critical path length: ~136h of sequential work.

**Maximum parallelism:** Phases 7 and 8 can run concurrently. Phase 11 can
start as soon as Phase 7 completes. Phase 12 can start as soon as Phase 8
completes. Phase 16 can overlap with Phases 11–15.

---

## 2. Current State Assessment

### What Exists (Phases 1–6 Complete)

**11 Lean 4 modules**, ~1,500 lines total, organized in four layers:

```
GroupAction/     (Basic, Canonical, Invariant)     — 387 lines
Crypto/          (Scheme, Security, OIA)            — 428 lines
Theorems/        (Correctness, InvariantAttack,     — 464 lines
                  OIAImpliesCPA)
Construction/    (Permutation, HGOE)                — 275 lines
```

**Three headline theorems**, all machine-checked:

1. `correctness` — decrypt inverts encrypt (unconditional)
2. `invariant_attack` — separating invariant → complete break (unconditional)
3. `oia_implies_1cpa` — OIA → IND-1-CPA security (conditional on OIA hypothesis)

**Key architectural properties:**

- `OrbitEncScheme G X M` — parameterized by group, space, message type
- Deterministic model: group element `g` is a parameter, not sampled
- `OIA` is a `Prop` definition, not an `axiom` (avoids inconsistency)
- The strong deterministic OIA quantifies over ALL Boolean functions, making
  it `False` for non-trivial schemes — the security proof is vacuously true
- `decrypt` is `noncomputable` (uses `Exists.choose`)
- Hamming weight defense: `same_weight_not_separating`

### What's Missing

| Gap | Impact | Addressed By |
|-----|--------|-------------|
| No KEM mode | Message space representation is impractical for large M | Phase 7 |
| Deterministic OIA is vacuous | Security theorem has no real content | Phase 8 |
| Keys are huge | 1.8 MB for λ=128 | Phase 9 |
| No authentication | Ciphertexts malleable | Phase 10 |
| No implementation | Cannot evaluate practical viability | Phase 11 |
| Weak hardness story | No tight reduction to NIST-level problems | Phase 12 |
| Symmetric-key only | Limited deployment scenarios | Phase 13 |
| No parameter tables | Cannot compare to existing schemes | Phase 14 |
| Slow decryption | Partition backtracking is expensive | Phase 15 |
| New components unverified | Lean proofs only cover Phases 1–6 | Phase 16 |

---

## 3. Improvement Taxonomy

The improvements are classified into three tiers:

### Tier 1: Architectural (change the scheme's structure)

These improvements alter what the scheme *is*. They produce new Lean modules,
new definitions, and new theorems. They are foundational — later tiers build
on them.

- **Phase 7** — KEM Reformulation
- **Phase 8** — Probabilistic Foundations
- **Phase 9** — Key Compression & Nonce-Based Encryption
- **Phase 10** — Authenticated Encryption & Modes

### Tier 2: Engineering (build and measure)

These improvements produce artifacts outside Lean: executable code, benchmarks,
parameter tables. They validate whether the Tier 1 architecture is practically
competitive.

- **Phase 11** — GAP Reference Implementation
- **Phase 14** — Parameter Selection & Benchmarks
- **Phase 15** — Decryption Optimization

### Tier 3: Theoretical (strengthen the foundations)

These improvements deepen the security story without changing the scheme's
structure. They produce new theorems, reductions, and connections to external
hardness assumptions.

- **Phase 12** — Hardness Alignment (LESS/MEDS/TI)
- **Phase 13** — Public-Key Extension
- **Phase 16** — Formal Verification of New Components

---

## Phase 7 — KEM Reformulation

### Weeks 17–19 | 8 Work Units | ~24 Hours

**Goal:** Redefine Orbcrypt as a Key Encapsulation Mechanism (KEM) rather than
a direct encryption scheme. This is the single highest-leverage architectural
change: it eliminates the message-space representation problem, fits the
standard hybrid encryption paradigm (KEM + DEM), and simplifies the security
claim to "the KEM output is pseudorandom under OIA."

**Rationale:** The current scheme requires storing |M| orbit representatives
as public parameters. For |M| = 2^128, this is infeasible. A KEM sidesteps
this entirely: the encapsulation produces a random orbit element, and a
symmetric key is derived from it via a hash. The actual message encryption
is delegated to a standard DEM (e.g., AES-GCM).

**New files:**

```
Orbcrypt/
  KEM/
    Syntax.lean          — OrbitKEM structure definition
    Encapsulate.lean     — encaps and decaps functions
    Security.lean        — IND-CCA KEM security definition
    Correctness.lean     — decaps(encaps()) recovers the key
```

**Dependency on existing code:** Builds on `GroupAction/`, `Crypto/Scheme.lean`
(reuses `CanonicalForm`), and `Construction/Permutation.lean`. Does NOT modify
existing files — purely additive.

---

#### 7.1 — OrbitKEM Structure

**Effort:** 2h | **File:** `KEM/Syntax.lean` | **Deps:** Phase 2 (CanonicalForm)

Define the KEM syntax. An OrbitKEM encapsulates a shared secret by sampling
a random orbit element and hashing its canonical form.

```lean
import Orbcrypt.GroupAction.Canonical

structure OrbitKEM (G : Type*) (X : Type*) (K : Type*)
    [Group G] [MulAction G X] [DecidableEq X] where
  /-- A single "base point" x₀ ∈ X. No message space needed. -/
  basePoint : X
  /-- Canonical form for orbit identification. -/
  canonForm : CanonicalForm G X
  /-- Key derivation: hash the canonical form to produce a symmetric key. -/
  keyDerive : X → K
```

**Design decisions:**

- **Single base point** instead of `reps : M → X`. The KEM produces one key
  per encapsulation; message encryption is handled by the DEM.
- **`keyDerive : X → K`** abstracts the hash function. In the formalization,
  this is an arbitrary function; in implementation, it would be SHA-3 or
  SHAKE applied to `can_G(g • x₀)`.
- **No `reps_distinct`** field — there is only one orbit, so distinctness
  is trivially satisfied.

**Exit criteria:** `lake build Orbcrypt.KEM.Syntax` succeeds with zero warnings.

---

#### 7.2 — Encapsulation Function

**Effort:** 2h | **File:** `KEM/Encapsulate.lean` | **Deps:** 7.1

Define `encaps` and `decaps`:

```lean
/-- Encapsulation: sample g ∈ G, output (ciphertext, shared key). -/
def encaps (kem : OrbitKEM G X K) (g : G) : X × K :=
  let c := g • kem.basePoint
  (c, kem.keyDerive (kem.canonForm.canon c))

/-- Decapsulation: recover the shared key from the ciphertext. -/
def decaps (kem : OrbitKEM G X K) (c : X) : K :=
  kem.keyDerive (kem.canonForm.canon c)
```

**Key insight:** `encaps` returns both the ciphertext and the derived key.
The caller uses the key with a DEM. `decaps` re-derives the key from the
ciphertext using the secret canonical form.

**Exit criteria:** Both functions type-check; `lake build` succeeds.

---

#### 7.3 — KEM Correctness Theorem

**Effort:** 3h | **File:** `KEM/Correctness.lean` | **Deps:** 7.2, Phase 4 (canon_encrypt)

Prove that decapsulation recovers the encapsulated key:

```lean
theorem kem_correctness (kem : OrbitKEM G X K) (g : G) :
    decaps kem (encaps kem g).1 = (encaps kem g).2
```

**Proof sketch:**
1. Unfold `encaps` and `decaps`.
2. Both sides reduce to `kem.keyDerive (kem.canonForm.canon (g • kem.basePoint))`.
3. This is `rfl` (definitional equality).

**Note:** This is simpler than the original `correctness` theorem because
there is no `Option` type — the KEM always produces a key. The canonical
form computation is the same in both `encaps` and `decaps`.

**Exit criteria:** Theorem compiles with zero `sorry`. `#print axioms kem_correctness`
shows only standard Lean axioms.

---

#### 7.4 — KEM Security Definition (IND-CCA)

**Effort:** 4h | **File:** `KEM/Security.lean` | **Deps:** 7.1

Define the IND-CCA security game for KEMs. In the real game, the adversary
receives `(c, K)` from an honest encapsulation. In the random game, K is
replaced with a uniformly random key. Security means the adversary cannot
distinguish the two.

```lean
/-- KEM adversary: given the base point, a ciphertext, and a candidate key,
    output a bit guessing whether the key is real or random. -/
structure KEMAdversary (X : Type*) (K : Type*) where
  guess : X → X → K → Bool
  -- Args: basePoint, ciphertext, candidate key

/-- A KEM adversary has advantage if it can distinguish real from random keys. -/
def kemHasAdvantage (kem : OrbitKEM G X K) (A : KEMAdversary X K) : Prop :=
  ∃ g : G, ∃ k_random : K,
    A.guess kem.basePoint (g • kem.basePoint)
      (kem.keyDerive (kem.canonForm.canon (g • kem.basePoint))) ≠
    A.guess kem.basePoint (g • kem.basePoint) k_random

/-- A KEM is IND-CCA secure if no adversary has advantage. -/
def KEMIsSecure (kem : OrbitKEM G X K) : Prop :=
  ∀ (A : KEMAdversary X K), ¬ kemHasAdvantage kem A
```

**Design note:** This is again a deterministic formulation. The random key
`k_random` is existentially quantified rather than sampled from a distribution.
Phase 8 upgrades this to a probabilistic model.

**Exit criteria:** Definitions type-check; `lake build` succeeds.

---

#### 7.5 — KEM-OIA Definition

**Effort:** 3h | **File:** `KEM/Security.lean` | **Deps:** 7.4

Define the KEM variant of OIA. This is simpler than the encryption OIA because
there is only one orbit:

```lean
/-- KEM-OIA: no Boolean function can distinguish orbit elements from each other,
    AND the key derivation function is "orbit-collapsing" (constant on orbits). -/
def KEMOIA (kem : OrbitKEM G X K) : Prop :=
  (∀ (f : X → Bool) (g₀ g₁ : G),
    f (g₀ • kem.basePoint) = f (g₁ • kem.basePoint)) ∧
  (∀ (g : G), kem.keyDerive (kem.canonForm.canon (g • kem.basePoint)) =
    kem.keyDerive (kem.canonForm.canon kem.basePoint))
```

**The two conjuncts:**
1. **Orbit indistinguishability:** No function distinguishes orbit elements.
   (Same as the existing OIA but restricted to a single orbit.)
2. **Key uniformity:** The derived key is the same for all orbit elements.
   This follows from canonical form G-invariance + deterministic `keyDerive`,
   so the second conjunct is actually provable from `canonical_isGInvariant`.

**Exit criteria:** Definition type-checks. The provability of the second
conjunct is confirmed via a lemma.

---

#### 7.6 — KEM Security Theorem

**Effort:** 4h | **File:** `KEM/Security.lean` | **Deps:** 7.4, 7.5

Prove: KEM-OIA implies KEM security.

```lean
theorem kemoia_implies_secure (kem : OrbitKEM G X K)
    (hOIA : KEMOIA kem) : KEMIsSecure kem
```

**Proof sketch:**
1. Introduce adversary A and assume `kemHasAdvantage kem A`.
2. Destructure to get `g`, `k_random`, and the inequality.
3. The real key is `kem.keyDerive (kem.canonForm.canon (g • kem.basePoint))`.
4. By the second conjunct of KEMOIA, this equals
   `kem.keyDerive (kem.canonForm.canon kem.basePoint)` — a fixed value.
5. The adversary's guess on the real key is therefore a fixed Boolean value
   for all g, while k_random varies. The adversary succeeds only if it can
   distinguish this fixed value from random — but the first conjunct of
   KEMOIA says no function can distinguish orbit elements, so the adversary's
   view of the ciphertext carries no information.

**Exit criteria:** Theorem compiles with zero `sorry`.

---

#### 7.7 — Backward Compatibility: OrbitEncScheme → OrbitKEM

**Effort:** 3h | **File:** `KEM/Syntax.lean` | **Deps:** 7.1, Phase 3

Provide a bridge construction showing that any `OrbitEncScheme` can be
converted to an `OrbitKEM` by fixing one message and using its representative
as the base point:

```lean
/-- Convert an OrbitEncScheme to an OrbitKEM by fixing a message m₀. -/
def OrbitEncScheme.toKEM (scheme : OrbitEncScheme G X K)
    (m₀ : M) (kd : X → K) : OrbitKEM G X K where
  basePoint := scheme.reps m₀
  canonForm := scheme.canonForm
  keyDerive := kd
```

Also prove that KEM correctness follows from AOE correctness:

```lean
theorem toKEM_correct (scheme : OrbitEncScheme G X K) (m₀ : M) (kd : X → K) (g : G) :
    decaps (scheme.toKEM m₀ kd) (encaps (scheme.toKEM m₀ kd) g).1 =
    (encaps (scheme.toKEM m₀ kd) g).2
```

**Exit criteria:** Bridge function and theorem compile.

---

#### 7.8 — HGOE-KEM Instantiation

**Effort:** 3h | **File:** `KEM/Encapsulate.lean` or `Construction/HGOEKEM.lean` | **Deps:** 7.7, Phase 5

Instantiate the KEM for the concrete HGOE construction (subgroup of S_n on
bitstrings), producing an `OrbitKEM` with:

- `basePoint` = a fixed weight-w bitstring
- `canonForm` = inherited from HGOE
- `keyDerive` = abstract hash function placeholder

Prove `hgoe_kem_correctness` by applying `kem_correctness`.

**Exit criteria:** Concrete KEM type-checks; correctness instantiation
compiles. `lake build` succeeds for all new modules.

---

### Phase 7 Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 7.1 | OrbitKEM Structure | `KEM/Syntax.lean` | 2h | Phase 2 |
| 7.2 | Encapsulation Functions | `KEM/Encapsulate.lean` | 2h | 7.1 |
| 7.3 | KEM Correctness | `KEM/Correctness.lean` | 3h | 7.2, Phase 4 |
| 7.4 | KEM Security Definition | `KEM/Security.lean` | 4h | 7.1 |
| 7.5 | KEM-OIA Definition | `KEM/Security.lean` | 3h | 7.4 |
| 7.6 | KEM Security Theorem | `KEM/Security.lean` | 4h | 7.4, 7.5 |
| 7.7 | Backward Compatibility | `KEM/Syntax.lean` | 3h | 7.1, Phase 3 |
| 7.8 | HGOE-KEM Instantiation | `Construction/HGOEKEM.lean` | 3h | 7.7, Phase 5 |

**Parallelism:** Units 7.1–7.3 (syntax/correctness) and 7.4–7.6 (security)
can proceed in parallel once 7.1 is complete. Unit 7.7 depends on both tracks.

---

## Phase 8 — Probabilistic Foundations

### Weeks 18–22 | 10 Work Units | ~40 Hours

**Goal:** Replace the deterministic OIA (which is `False` for all non-trivial
schemes) with a probabilistic formulation that captures meaningful
computational indistinguishability. This is the most technically challenging
phase and the most impactful for theoretical credibility.

**The core problem:** The current OIA states:

```lean
def OIA (scheme : OrbitEncScheme G X M) : Prop :=
  ∀ (f : X → Bool) (m₀ m₁ : M) (g₀ g₁ : G),
    f (g₀ • scheme.reps m₀) = f (g₁ • scheme.reps m₁)
```

This quantifies over ALL Boolean functions, including `fun x => decide (x = reps m₀)`,
which trivially separates orbits. Therefore `OIA scheme` is `False` for any
scheme with distinct representatives. The security theorem `oia_implies_1cpa`
is vacuously true (ex falso quodlibet).

**The fix:** Introduce a probability monad and restrict the quantification to
computationally bounded adversaries. The probabilistic OIA states:

> For all PPT adversaries A, the advantage
> |Pr[A(g · x_{m₀}) = 1] - Pr[A(g · x_{m₁}) = 1]|
> is negligible in the security parameter.

**New files:**

```
Orbcrypt/
  Probability/
    Monad.lean           — PMF type, uniform distribution, bind/map
    Negligible.lean      — Negligible function definition
    Advantage.lean       — Statistical distance, advantage definition
  Crypto/
    CompOIA.lean         — Computational (probabilistic) OIA
    CompSecurity.lean    — Probabilistic IND-CPA security game
```

**Approach:** We follow the design of CryptHOL (Isabelle/HOL) and FCF (Coq),
adapted for Lean 4. The key design choice is whether to use:

- **(A) Mathlib's `PMF` type** (`Mathlib.Probability.ProbabilityMassFunction`):
  Already exists, provides `PMF.pure`, `PMF.bind`, `PMF.map`. This is the
  recommended approach — maximal Mathlib reuse.
- **(B) Custom discrete distribution monad:** More control over the API but
  duplicates Mathlib effort. Only if PMF proves inadequate.

We use approach (A) unless blocked.

---

#### 8.1 — Probability Monad Wrapper

**Effort:** 4h | **File:** `Probability/Monad.lean` | **Deps:** Mathlib

Wrap Mathlib's `PMF` type with convenience definitions for cryptographic use:

```lean
import Mathlib.Probability.ProbabilityMassFunction.Basic
import Mathlib.Probability.ProbabilityMassFunction.Monad

/-- Uniform distribution over a finite type. -/
noncomputable def uniformPMF (α : Type*) [Fintype α] [Nonempty α] : PMF α :=
  PMF.uniformOfFintype α

/-- Probability that a predicate holds under a distribution. -/
noncomputable def probEvent (d : PMF α) (p : α → Prop) [DecidablePred p] : ℝ≥0∞ :=
  d.toOuterMeasure {x | p x}
```

**Required Mathlib imports:**
- `Mathlib.Probability.ProbabilityMassFunction.Basic`
- `Mathlib.Probability.ProbabilityMassFunction.Monad`
- `Mathlib.MeasureTheory.Measure.MeasureSpace`

**Risk:** Mathlib's PMF API may not provide all needed lemmas (e.g., for
`bind` distributing over `probEvent`). Mitigation: prove missing lemmas
locally and contribute upstream.

**Exit criteria:** `uniformPMF` and `probEvent` compile. Basic sanity lemma:
`probEvent (uniformPMF (Fin 2)) (· = 0) = 1/2`.

---

#### 8.2 — Negligible Function Definition

**Effort:** 3h | **File:** `Probability/Negligible.lean` | **Deps:** Mathlib

Define negligible functions in the standard cryptographic sense:

```lean
/-- A function f : ℕ → ℝ is negligible if for every polynomial p,
    f(n) < 1/p(n) for sufficiently large n. -/
def IsNegligible (f : ℕ → ℝ) : Prop :=
  ∀ (c : ℕ), ∃ n₀ : ℕ, ∀ n : ℕ, n₀ ≤ n → |f n| < (n : ℝ)⁻¹ ^ c
```

Prove closure properties:
- `IsNegligible.add` — sum of negligible is negligible
- `IsNegligible.mul_poly` — negligible times polynomial is negligible
- `isNegligible_zero` — zero is negligible

**Exit criteria:** Definition and closure lemmas compile.

---

#### 8.3 — Advantage Definition

**Effort:** 4h | **File:** `Probability/Advantage.lean` | **Deps:** 8.1, 8.2

Define the distinguishing advantage of an adversary between two distributions:

```lean
/-- The advantage of a distinguisher D between distributions d₀ and d₁.
    Adv(D) = |Pr[D(x) = 1 | x ← d₀] - Pr[D(x) = 1 | x ← d₁]| -/
noncomputable def advantage (D : α → Bool) (d₀ d₁ : PMF α) : ℝ :=
  |(probEvent d₀ (fun x => D x = true)).toReal -
   (probEvent d₁ (fun x => D x = true)).toReal|
```

Prove key properties:
- `advantage_nonneg` — advantage is non-negative
- `advantage_le_one` — advantage is at most 1
- `advantage_symm` — advantage is symmetric in d₀, d₁
- `advantage_triangle` — triangle inequality for hybrid arguments

**Exit criteria:** All four lemmas compile with zero `sorry`.

---

#### 8.4 — Orbit Distribution Definition

**Effort:** 4h | **File:** `Crypto/CompOIA.lean` | **Deps:** 8.1

Define the distribution of a random orbit element:

```lean
/-- The distribution of g • x for uniform g ∈ G. -/
noncomputable def orbitDist [Fintype G] [Nonempty G]
    [Group G] [MulAction G X]
    (x : X) : PMF X :=
  PMF.map (fun g => g • x) (uniformPMF G)
```

Prove a key structural lemma: if the action is free (trivial stabilizer),
then `orbitDist x` is uniform over the orbit of x.

**Exit criteria:** `orbitDist` type-checks. The free-action uniformity
lemma compiles or is marked as a stretch goal with `sorry`.

---

#### 8.5 — Computational OIA (Probabilistic)

**Effort:** 5h | **File:** `Crypto/CompOIA.lean` | **Deps:** 8.3, 8.4

Define the probabilistic OIA as a family indexed by a security parameter:

```lean
/-- The computational OIA for a family of schemes indexed by security parameter.
    For all efficient distinguishers, the advantage between orbit distributions
    of any two messages is negligible. -/
def CompOIA (schemeFamily : ℕ → OrbitEncScheme G X M)
    [∀ λ, Fintype (G λ)] : Prop :=
  ∀ (D : ℕ → X → Bool) (m₀ m₁ : ℕ → M),
    IsNegligible (fun λ =>
      advantage (D λ) (orbitDist (schemeFamily λ).reps (m₀ λ))
                       (orbitDist (schemeFamily λ).reps (m₁ λ)))
```

**Design note:** The quantification is over ALL distinguishers `D : ℕ → X → Bool`,
not just PPT ones. Modeling PPT requires a complexity-theoretic framework
beyond current scope. This is a known limitation shared by CryptHOL and FCF.
The improvement over the deterministic OIA is that we now work with
*distributions* rather than individual elements, making the assumption
satisfiable for non-trivial schemes.

**Alternative approach (simpler but weaker):** If the full asymptotic framework
proves too complex, define a "concrete security" version:

```lean
/-- Concrete OIA: the advantage of any specific distinguisher is bounded. -/
def ConcreteOIA (scheme : OrbitEncScheme G X M) (ε : ℝ) : Prop :=
  ∀ (D : X → Bool) (m₀ m₁ : M),
    advantage D (orbitDist (scheme.reps m₀)) (orbitDist (scheme.reps m₁)) ≤ ε
```

This is weaker (no negligibility) but sufficient for concrete security
statements like "advantage ≤ 2^{-128}."

**Exit criteria:** At least one OIA variant compiles.

---

#### 8.6 — Probabilistic IND-CPA Game

**Effort:** 5h | **File:** `Crypto/CompSecurity.lean` | **Deps:** 8.1, 8.3

Define the probabilistic IND-1-CPA game:

```lean
/-- The IND-1-CPA advantage of adversary A against scheme S. -/
noncomputable def indCPAAdvantage [Fintype G] [Nonempty G]
    (scheme : OrbitEncScheme G X M)
    (A : Adversary X M) : ℝ :=
  let (m₀, m₁) := A.choose scheme.reps
  advantage (fun x => A.guess scheme.reps x)
    (orbitDist (scheme.reps m₀))
    (orbitDist (scheme.reps m₁))
```

**Exit criteria:** Definition type-checks.

---

#### 8.7 — Probabilistic Security Theorem

**Effort:** 5h | **File:** `Crypto/CompSecurity.lean` | **Deps:** 8.5, 8.6

Prove the probabilistic analogue of `oia_implies_1cpa`:

```lean
/-- CompOIA implies negligible IND-1-CPA advantage for all adversaries. -/
theorem comp_oia_implies_1cpa
    (schemeFamily : ℕ → OrbitEncScheme G X M)
    (hOIA : CompOIA schemeFamily)
    (A : ℕ → Adversary X M) :
    IsNegligible (fun λ => indCPAAdvantage (schemeFamily λ) (A λ))
```

**Proof sketch:**
1. Unfold `indCPAAdvantage` to `advantage`.
2. The adversary's guess function IS a distinguisher.
3. Apply `CompOIA` with `D λ := fun x => (A λ).guess (schemeFamily λ).reps x`.
4. The advantage bound follows directly.

**Risk:** Lean elaboration may struggle with the type-level plumbing of
families indexed by ℕ. Mitigation: simplify to concrete security if needed.

**Exit criteria:** Theorem compiles, or a concrete-security variant compiles.

---

#### 8.8 — Bridge: Deterministic OIA Implies Probabilistic OIA

**Effort:** 3h | **File:** `Crypto/CompOIA.lean` | **Deps:** 8.5, Phase 3

Prove that the existing deterministic OIA (trivially false) implies the
probabilistic OIA (with advantage exactly 0, not merely negligible):

```lean
theorem det_oia_implies_comp_oia (scheme : OrbitEncScheme G X M)
    (hOIA : OIA scheme) (D : X → Bool) (m₀ m₁ : M) :
    advantage D (orbitDist (scheme.reps m₀)) (orbitDist (scheme.reps m₁)) = 0
```

This is a compatibility theorem: it shows the new formulation strictly
generalizes the old one. Since `OIA scheme` is `False` for non-trivial
schemes, this theorem is also vacuously true — but it serves as a sanity
check on the definitions.

**Exit criteria:** Theorem compiles.

---

#### 8.9 — Hybrid Argument Lemma

**Effort:** 4h | **File:** `Probability/Advantage.lean` | **Deps:** 8.3

Prove the standard hybrid argument used for multi-query security:

```lean
/-- Hybrid argument: if each adjacent pair of hybrids has small advantage,
    the overall advantage is bounded by the sum. -/
theorem hybrid_argument (hybrids : Fin (n+1) → PMF α) (D : α → Bool) :
    advantage D (hybrids 0) (hybrids (Fin.last n)) ≤
    Finset.sum Finset.univ (fun i : Fin n =>
      advantage D (hybrids i.castSucc) (hybrids i.succ))
```

**Proof:** By induction on n, using `advantage_triangle`.

**Exit criteria:** Theorem compiles with zero `sorry`.

---

#### 8.10 — Multi-Query Security Skeleton

**Effort:** 3h | **File:** `Crypto/CompSecurity.lean` | **Deps:** 8.7, 8.9

State (but do not fully prove) the multi-query IND-CPA theorem using hybrids:

```lean
/-- Multi-query IND-CPA security: if CompOIA holds and HSP is hard,
    the scheme is IND-Q-CPA secure for polynomial Q. -/
theorem comp_oia_implies_qcpa
    (schemeFamily : ℕ → OrbitEncScheme G X M)
    (hOIA : CompOIA schemeFamily)
    (Q : ℕ → ℕ) -- number of queries
    (hHSP : HSPHard G) -- Hidden Subgroup Problem hardness
    (A : ℕ → MultiQueryAdversary X M) :
    IsNegligible (fun λ => indQCPAAdvantage (schemeFamily λ) (Q λ) (A λ)) :=
  sorry -- Full proof requires HSP formalization (out of scope)
```

**Design note:** This is explicitly a skeleton with `sorry`. The HSP hardness
assumption is beyond current scope. The value is in establishing the correct
*statement* and type signatures so that a future formalization can fill in the
proof. Document the `sorry` in the module docstring.

**Exit criteria:** Statement type-checks. Module docstring explains the `sorry`.

---

### Phase 8 Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 8.1 | Probability Monad Wrapper | `Probability/Monad.lean` | 4h | Mathlib |
| 8.2 | Negligible Functions | `Probability/Negligible.lean` | 3h | Mathlib |
| 8.3 | Advantage Definition | `Probability/Advantage.lean` | 4h | 8.1, 8.2 |
| 8.4 | Orbit Distribution | `Crypto/CompOIA.lean` | 4h | 8.1 |
| 8.5 | Computational OIA | `Crypto/CompOIA.lean` | 5h | 8.3, 8.4 |
| 8.6 | Probabilistic IND-CPA | `Crypto/CompSecurity.lean` | 5h | 8.1, 8.3 |
| 8.7 | Probabilistic Security Thm | `Crypto/CompSecurity.lean` | 5h | 8.5, 8.6 |
| 8.8 | Deterministic→Probabilistic | `Crypto/CompOIA.lean` | 3h | 8.5, Phase 3 |
| 8.9 | Hybrid Argument | `Probability/Advantage.lean` | 4h | 8.3 |
| 8.10 | Multi-Query Skeleton | `Crypto/CompSecurity.lean` | 3h | 8.7, 8.9 |

**Parallelism:** Track A (8.1 → 8.2 → 8.3 → 8.9) and Track B (8.4 → 8.5)
can proceed in parallel. They merge at 8.6–8.7.

**Risk mitigation:** If Mathlib's PMF API proves inadequate, fall back to a
simpler `ConcreteOIA` that avoids the probability monad entirely (define
advantage as a rational number computed by enumeration over finite types).

---

## Phase 9 — Key Compression & Nonce-Based Encryption

### Weeks 20–22 | 7 Work Units | ~18 Hours

**Goal:** Reduce the secret key from ~1.8 MB (SGS storage) to 256 bits (seed),
and replace random group-element sampling with deterministic nonce-based
derivation. These two changes together make Orbcrypt's key management
comparable to AES.

**New files:**

```
Orbcrypt/
  KeyMgmt/
    SeedKey.lean         — Seed-based key expansion definition
    Nonce.lean           — Nonce-based deterministic encryption
```

---

#### 9.1 — Seed-Based Key Definition

**Effort:** 2h | **File:** `KeyMgmt/SeedKey.lean` | **Deps:** Phase 7

Define the seed-based key model:

```lean
/-- A seed-based key: a short seed from which the full group and canonical
    form can be deterministically derived. -/
structure SeedKey (Seed : Type*) (G : Type*) (X : Type*)
    [Group G] [MulAction G X] [DecidableEq X] where
  /-- The compact secret: a short random seed (e.g., 256 bits). -/
  seed : Seed
  /-- Deterministic key expansion: derive group generators from the seed. -/
  expand : Seed → CanonicalForm G X
  /-- Deterministic group-element derivation from seed and a counter. -/
  sampleGroup : Seed → ℕ → G
```

**Design rationale:**
- `expand` captures the one-time key expansion (seed → QC code → PAut(C₀) → SGS → canonical form).
- `sampleGroup` captures the PRF-based group-element derivation for encryption.
- The seed is the minimal secret; everything else is derived.

**Exit criteria:** Structure type-checks.

---

#### 9.2 — Seed-Key Correctness

**Effort:** 3h | **File:** `KeyMgmt/SeedKey.lean` | **Deps:** 9.1, Phase 7

Prove that seed-based encryption is correct when the expansion is faithful:

```lean
/-- If expansion produces a valid canonical form, seed-based encryption
    is correct for the derived KEM. -/
theorem seed_kem_correctness
    (sk : SeedKey Seed G X)
    (kem : OrbitKEM G X K)
    (hExpand : sk.expand sk.seed = kem.canonForm)
    (n : ℕ) :
    decaps kem (encaps kem (sk.sampleGroup sk.seed n)).1 =
    (encaps kem (sk.sampleGroup sk.seed n)).2
```

This follows directly from `kem_correctness` — the seed expansion does not
affect the correctness argument (which depends only on group-action algebra).

**Exit criteria:** Theorem compiles.

---

#### 9.3 — QC Code Key Expansion Specification

**Effort:** 3h | **File:** `KeyMgmt/SeedKey.lean` | **Deps:** 9.1

Specify (but do not implement in executable Lean) the QC code key expansion
pipeline from DEVELOPMENT.md §6.2.1:

```lean
/-- Specification of the 7-stage HGOE key expansion pipeline.
    This is a SPECIFICATION (Prop-valued), not an executable function.
    An implementation must satisfy these properties. -/
structure HGOEKeyExpansion (n b ℓ : ℕ) where
  /-- Stage 1: parameter derivation. -/
  param_valid : n = b * ℓ
  /-- Stage 2: code generation produces a valid [n,k]-code. -/
  code_dim : ℕ
  code_valid : code_dim ≤ n
  /-- Stage 3: automorphism group has sufficient order. -/
  group_order_log : ℕ
  group_large_enough : group_order_log ≥ 128 -- λ = 128
  /-- Stage 4: all representatives have the same weight. -/
  weight : ℕ
  reps_same_weight : ∀ m, hammingWeight (reps m) = weight
```

**Exit criteria:** Specification structure type-checks.

---

#### 9.4 — Nonce-Based Encryption Definition

**Effort:** 3h | **File:** `KeyMgmt/Nonce.lean` | **Deps:** 9.1, Phase 7

Define nonce-based deterministic encryption:

```lean
/-- Nonce-based KEM encapsulation: the group element is derived
    deterministically from the seed and a nonce, eliminating the
    need for runtime randomness. -/
def nonceEncaps (sk : SeedKey Seed G X) (kem : OrbitKEM G X K)
    (nonce : ℕ) : X × K :=
  encaps kem (sk.sampleGroup sk.seed nonce)
```

**Properties to prove:**
- Correctness: `decaps kem (nonceEncaps sk kem nonce).1 = (nonceEncaps sk kem nonce).2`
  (follows from `kem_correctness`)
- Nonce-misuse detection: different nonces produce different ciphertexts
  (requires injectivity of `sampleGroup`, stated as a hypothesis)

**Exit criteria:** Definition and correctness lemma compile.

---

#### 9.5 — Nonce-Misuse Resistance Property

**Effort:** 2h | **File:** `KeyMgmt/Nonce.lean` | **Deps:** 9.4

State the nonce-misuse property: reusing a nonce leaks whether the same
base point was used, but does NOT leak the key beyond what was already
derivable.

```lean
/-- Nonce reuse with the same base point produces identical ciphertexts
    (deterministic — no new information leaks beyond the repeated ciphertext). -/
theorem nonce_reuse_deterministic (sk : SeedKey Seed G X)
    (kem : OrbitKEM G X K) (nonce : ℕ) :
    nonceEncaps sk kem nonce = nonceEncaps sk kem nonce := rfl
```

The interesting property is that nonce reuse with different base points
(different KEMs or different orbit representatives) produces ciphertexts
in the same orbit but potentially different elements, leaking orbit
membership. State this as a warning theorem:

```lean
/-- WARNING: Nonce reuse across different base points leaks whether
    the base points are in the same orbit. -/
theorem nonce_reuse_leaks_orbit (sk : SeedKey Seed G X)
    (kem₁ kem₂ : OrbitKEM G X K) (nonce : ℕ)
    (hDiffOrbit : MulAction.orbit G kem₁.basePoint ≠
                  MulAction.orbit G kem₂.basePoint) :
    (nonceEncaps sk kem₁ nonce).1 ≠ (nonceEncaps sk kem₂ nonce).1 ∨
    MulAction.orbit G (nonceEncaps sk kem₁ nonce).1 ≠
    MulAction.orbit G (nonceEncaps sk kem₂ nonce).1 :=
  sorry -- Requires orbit separation argument
```

**Exit criteria:** Deterministic lemma compiles; leakage warning is stated.

---

#### 9.6 — Key Size Analysis

**Effort:** 2h | **File:** `KeyMgmt/SeedKey.lean` | **Deps:** 9.1

Document and formally state the key size comparison:

```lean
/-- The seed key representation is compact.
    For HGOE with λ=128: seed = 256 bits, versus
    SGS = O(n² log|G|) ≈ 15 million bits.

    This theorem states that the seed determines the full key material. -/
theorem seed_determines_key (sk₁ sk₂ : SeedKey Seed G X)
    (hSeed : sk₁.seed = sk₂.seed)
    (hExpand : sk₁.expand = sk₂.expand)
    (hSample : sk₁.sampleGroup = sk₂.sampleGroup) :
    ∀ n : ℕ, sk₁.sampleGroup sk₁.seed n = sk₂.sampleGroup sk₂.seed n := by
  intro n; rw [hSeed, hSample]
```

**Exit criteria:** Lemma compiles. Module docstring documents the size comparison.

---

#### 9.7 — Backward Compatibility: Unkeyed → Seed-Keyed

**Effort:** 3h | **File:** `KeyMgmt/SeedKey.lean` | **Deps:** 9.1, Phase 3

Show that the existing `OrbitEncScheme` can be wrapped in a `SeedKey`:

```lean
/-- Any OrbitEncScheme can be trivially wrapped in a SeedKey where the
    "seed" is the entire scheme and expansion is the identity. -/
def OrbitEncScheme.toSeedKey (scheme : OrbitEncScheme G X M)
    (sampleG : Unit → ℕ → G) : SeedKey Unit G X where
  seed := ()
  expand := fun () => scheme.canonForm
  sampleGroup := sampleG ()
```

This is a trivial embedding that proves the seed-key model generalizes
the existing model.

**Exit criteria:** Definition type-checks.

---

### Phase 9 Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 9.1 | Seed-Based Key Definition | `KeyMgmt/SeedKey.lean` | 2h | Phase 7 |
| 9.2 | Seed-Key Correctness | `KeyMgmt/SeedKey.lean` | 3h | 9.1, Phase 7 |
| 9.3 | QC Key Expansion Spec | `KeyMgmt/SeedKey.lean` | 3h | 9.1 |
| 9.4 | Nonce-Based Encryption | `KeyMgmt/Nonce.lean` | 3h | 9.1, Phase 7 |
| 9.5 | Nonce-Misuse Properties | `KeyMgmt/Nonce.lean` | 2h | 9.4 |
| 9.6 | Key Size Analysis | `KeyMgmt/SeedKey.lean` | 2h | 9.1 |
| 9.7 | Backward Compatibility | `KeyMgmt/SeedKey.lean` | 3h | 9.1, Phase 3 |

---

## Phase 10 — Authenticated Encryption & Modes

### Weeks 22–24 | 6 Work Units | ~16 Hours

**Goal:** Add integrity protection (authentication) and define block modes
for encrypting data longer than a single orbit element. Without authentication,
Orbcrypt ciphertexts are malleable — an attacker can flip bits undetected.

**New files:**

```
Orbcrypt/
  AEAD/
    MAC.lean             — Message Authentication Code abstraction
    AEAD.lean            — Authenticated Encryption with Associated Data
    Modes.lean           — Block modes (CTR, KEM+DEM composition)
```

---

#### 10.1 — MAC Abstraction

**Effort:** 2h | **File:** `AEAD/MAC.lean` | **Deps:** Mathlib

Define a generic MAC structure:

```lean
/-- A Message Authentication Code. Parameterized by key, message, and tag types. -/
structure MAC (K : Type*) (Msg : Type*) (Tag : Type*) where
  /-- Compute a tag for a message under a key. -/
  tag : K → Msg → Tag
  /-- Verify a tag. -/
  verify : K → Msg → Tag → Bool
  /-- Correctness: verify accepts honestly computed tags. -/
  correct : ∀ k m, verify k m (tag k m) = true
```

**Exit criteria:** Structure type-checks; correctness field is well-typed.

---

#### 10.2 — AEAD Definition

**Effort:** 3h | **File:** `AEAD/AEAD.lean` | **Deps:** 10.1, Phase 7

Define authenticated encryption with associated data, composing the KEM
with a MAC:

```lean
/-- Authenticated KEM: encapsulation produces (ciphertext, tag). -/
structure AuthOrbitKEM (G : Type*) (X : Type*) (K : Type*) (Tag : Type*)
    [Group G] [MulAction G X] [DecidableEq X] extends OrbitKEM G X K where
  /-- MAC for authenticating ciphertexts. -/
  mac : MAC K X Tag

/-- Authenticated encapsulation: encrypt then MAC. -/
def authEncaps (akem : AuthOrbitKEM G X K Tag) (g : G) :
    X × K × Tag :=
  let (c, k) := encaps akem.toOrbitKEM g
  (c, k, akem.mac.tag k c)

/-- Authenticated decapsulation: verify then decrypt. Returns none on
    authentication failure. -/
def authDecaps (akem : AuthOrbitKEM G X K Tag)
    (c : X) (t : Tag) : Option K :=
  let k := decaps akem.toOrbitKEM c
  if akem.mac.verify k c t then some k else none
```

**Exit criteria:** Functions type-check.

---

#### 10.3 — AEAD Correctness

**Effort:** 3h | **File:** `AEAD/AEAD.lean` | **Deps:** 10.2

Prove authenticated correctness:

```lean
/-- Authenticated KEM correctness: authDecaps recovers the key from
    honestly generated (ciphertext, tag) pairs. -/
theorem aead_correctness (akem : AuthOrbitKEM G X K Tag) (g : G) :
    let (c, k, t) := authEncaps akem g
    authDecaps akem c t = some k
```

**Proof sketch:**
1. Unfold to `kem_correctness` for key recovery.
2. The verify check passes because `mac.correct` ensures honestly computed
   tags are accepted.

**Exit criteria:** Theorem compiles with zero `sorry`.

---

#### 10.4 — INT-CTXT Security Definition

**Effort:** 3h | **File:** `AEAD/AEAD.lean` | **Deps:** 10.2

Define ciphertext integrity: no adversary can produce a valid (ciphertext, tag)
pair without knowing the key.

```lean
/-- INT-CTXT: no adversary can forge a valid (ciphertext, tag) pair.
    A (c, t) pair is a forgery if it was not produced by any honest
    encapsulation and yet passes verification. -/
def INT_CTXT (akem : AuthOrbitKEM G X K Tag) : Prop :=
  ∀ (c : X) (t : Tag),
    (∀ g : G, c ≠ (authEncaps akem g).1 ∨
              t ≠ (authEncaps akem g).2.2) →
    authDecaps akem c t = none
```

**Note:** This definition captures existential unforgeability in the
single-encapsulation setting. Extending to multi-query CCA (where the
adversary has access to encapsulation AND decapsulation oracles) requires
additional infrastructure (query logs, excluding queried ciphertexts).
This extension is documented as future work.

**Exit criteria:** A well-typed integrity definition compiles.

---

#### 10.5 — KEM + DEM Composition

**Effort:** 3h | **File:** `AEAD/Modes.lean` | **Deps:** 10.2, Phase 7

Define the standard KEM+DEM composition for encrypting arbitrary-length data:

```lean
/-- A Data Encapsulation Mechanism: symmetric encryption keyed by K. -/
structure DEM (K : Type*) (Plaintext : Type*) (Ciphertext : Type*) where
  enc : K → Plaintext → Ciphertext
  dec : K → Ciphertext → Option Plaintext
  correct : ∀ k m, dec k (enc k m) = some m

/-- Full hybrid encryption: KEM produces a key, DEM encrypts the data. -/
def hybridEncrypt (kem : OrbitKEM G X K)
    (dem : DEM K Plaintext Ciphertext)
    (g : G) (m : Plaintext) : X × Ciphertext :=
  let (c_kem, k) := encaps kem g
  (c_kem, dem.enc k m)

/-- Full hybrid decryption. -/
def hybridDecrypt (kem : OrbitKEM G X K)
    (dem : DEM K Plaintext Ciphertext)
    (c_kem : X) (c_dem : Ciphertext) : Option Plaintext :=
  let k := decaps kem c_kem
  dem.dec k c_dem
```

**Exit criteria:** Functions type-check.

---

#### 10.6 — Hybrid Encryption Correctness

**Effort:** 2h | **File:** `AEAD/Modes.lean` | **Deps:** 10.5

Prove end-to-end correctness of KEM+DEM:

```lean
theorem hybrid_correctness (kem : OrbitKEM G X K)
    (dem : DEM K Plaintext Ciphertext) (g : G) (m : Plaintext) :
    let (c_kem, c_dem) := hybridEncrypt kem dem g m
    hybridDecrypt kem dem c_kem c_dem = some m
```

**Proof:** Unfold; key recovery by `kem_correctness`; message recovery
by `dem.correct`.

**Exit criteria:** Theorem compiles with zero `sorry`.

---

### Phase 10 Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 10.1 | MAC Abstraction | `AEAD/MAC.lean` | 2h | Mathlib |
| 10.2 | AEAD Definition | `AEAD/AEAD.lean` | 3h | 10.1, Phase 7 |
| 10.3 | AEAD Correctness | `AEAD/AEAD.lean` | 3h | 10.2 |
| 10.4 | INT-CTXT Definition | `AEAD/AEAD.lean` | 3h | 10.2 |
| 10.5 | KEM + DEM Composition | `AEAD/Modes.lean` | 3h | 10.2, Phase 7 |
| 10.6 | Hybrid Correctness | `AEAD/Modes.lean` | 2h | 10.5 |

---

## Phase 11 — Reference Implementation (GAP Prototype)

### Weeks 21–26 | 9 Work Units | ~36 Hours

**Goal:** Build an executable reference implementation in GAP (Groups,
Algorithms, Programming) to validate practical viability and produce real
benchmarks. GAP is the natural choice: it has built-in Schreier-Sims,
partition backtracking, canonical images, and permutation group support.

**Why GAP and not another language:**

| Language | Pros | Cons |
|----------|------|------|
| **GAP** | Native permutation groups, canonical images via `images` package, Schreier-Sims built-in | Slow for bit-level operations, limited crypto libraries |
| Python/SageMath | Good ecosystem, `permutation_group` in Sage | Sage's perm group is slower than GAP's C kernel |
| Rust/C++ | Fast execution | Must implement Schreier-Sims and partition backtracking from scratch |
| Magma | Excellent computational algebra | Commercial, not open-source |

GAP provides the fastest path to working benchmarks. Performance-critical
reimplementation in Rust/C++ can follow if benchmarks are promising.

**New files:**

```
implementation/
  gap/
    orbcrypt_kem.g       — KEM encapsulation/decapsulation
    orbcrypt_keygen.g    — Key generation (QC code, PAut, SGS)
    orbcrypt_bench.g     — Benchmark harness
    orbcrypt_test.g      — Correctness test suite
    orbcrypt_params.g    — Parameter generation for multiple security levels
```

**Note:** These are `.g` files (GAP language), not `.lean` files. They live
outside the Lean build system in a separate `implementation/` directory.

---

#### 11.1 — GAP Environment Setup

**Effort:** 2h | **File:** `implementation/gap/README.md` | **Deps:** None

Install GAP 4.12+ with the `images` package (Christopher Jefferson's
canonical image library). Document installation steps, required packages,
and version pins.

Required GAP packages:
- `images` — canonical image computation for permutation groups
- `GUAVA` — error-correcting code support (for QC code generation)
- `IO` — file I/O for benchmark output

**Exit criteria:** `gap --version` reports 4.12+. `LoadPackage("images")`
succeeds. A trivial test (canonical image of a 4-element permutation group)
runs correctly.

---

#### 11.2 — Permutation Group Key Generation

**Effort:** 5h | **File:** `implementation/gap/orbcrypt_keygen.g` | **Deps:** 11.1

Implement the HGOE key generation pipeline from DEVELOPMENT.md Section 6.2.1:

```gap
# Stage 1: Parameter derivation
HGOEParams := function(lambda)
  local b, ell, n, k, w;
  b := 8;
  ell := Int(Ceil(lambda / Log2(b)));
  n := b * ell;
  k := Int(n / 2);
  w := Int(n / 2);
  return rec(b := b, ell := ell, n := n, k := k, w := w);
end;

# Stage 2-3: QC code generation and automorphism computation
HGOEKeygen := function(params)
  # Generate random QC code via circulant blocks
  # Compute PAut(C) using AutomorphismGroup
  # Build Schreier-Sims SGS
  # Return: group G, SGS, canonical image function
end;
```

Implement all 7 stages. Validate:
- `Size(G) >= 2^lambda`
- All orbit representatives have the correct Hamming weight
- `CanonicalImage(G, rep)` is distinct for each representative

**Exit criteria:** `HGOEKeygen(HGOEParams(128))` produces a valid key
in under 60 seconds.

---

#### 11.3 — KEM Encapsulation/Decapsulation

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_kem.g` | **Deps:** 11.2

Implement the KEM operations:

```gap
HGOEEncaps := function(G, basePoint, keyDerive)
  local g, c, canon_c, k;
  g := PseudoRandom(G);          # Uniform group element via PRA
  c := Permuted(basePoint, g);    # g . x_0
  canon_c := CanonicalImage(G, c); # can_G(c)
  k := keyDerive(canon_c);        # Hash to derive key
  return rec(ciphertext := c, key := k);
end;

HGOEDecaps := function(G, c, keyDerive)
  local canon_c, k;
  canon_c := CanonicalImage(G, c);
  k := keyDerive(canon_c);
  return k;
end;
```

**Exit criteria:** For 100 random group elements, `HGOEDecaps(HGOEEncaps(...))`
recovers the same key.

---

#### 11.4 — Correctness Test Suite

**Effort:** 3h | **File:** `implementation/gap/orbcrypt_test.g` | **Deps:** 11.3

Comprehensive correctness tests:

1. **Round-trip test:** For N=1000 random encapsulations, verify decaps
   recovers the encapsulated key.
2. **Orbit membership test:** Verify every ciphertext lies in the correct orbit.
3. **Weight preservation test:** Verify every ciphertext has the correct
   Hamming weight.
4. **Canonical form consistency:** Verify `CanonicalImage(G, g1.x) =
   CanonicalImage(G, g2.x)` for random g1, g2.
5. **Distinct orbit test:** Verify different base points have different
   canonical images.

**Exit criteria:** All tests pass for parameter sets lambda in {80, 128}.

---

#### 11.5 — Benchmark Harness

**Effort:** 5h | **File:** `implementation/gap/orbcrypt_bench.g` | **Deps:** 11.3

Time each operation at multiple parameter levels:

```gap
BenchmarkHGOE := function(lambda, nTrials)
  # Time key generation (average over 5 runs)
  # Time encapsulation (average over nTrials runs)
  # Time decapsulation (average over nTrials runs)
  # Measure: key size, ciphertext size, public param size
  # Output: structured record with all timings
end;
```

Benchmark parameters: lambda in {80, 128, 192, 256}.
Trials: 1000 for enc/dec, 5 for keygen.

Output format: CSV for easy comparison with other schemes.

**Exit criteria:** Benchmarks complete without error. CSV output is generated.

---

#### 11.6 — Parameter Generation Utility

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_params.g` | **Deps:** 11.2

Generate and validate parameter sets for multiple security levels:

| Lambda | n | b | ell | k | w | Expected \|G\| |
|--------|---|---|-----|---|---|---------------|
| 80 | 216 | 8 | 27 | 108 | 108 | >= 2^81 |
| 128 | 344 | 8 | 43 | 172 | 172 | >= 2^129 |
| 192 | 520 | 8 | 65 | 260 | 260 | >= 2^195 |
| 256 | 688 | 8 | 86 | 344 | 344 | >= 2^258 |

For each parameter set, validate all DEVELOPMENT.md Section 6.2.1 constraints.

**Exit criteria:** Parameter table generated with validated group orders.

---

#### 11.7 — Comparison Data Collection

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_bench.g` | **Deps:** 11.5

Collect comparison data against existing schemes at equivalent security levels.
This is a literature exercise (not implementation of other schemes):

| Scheme | Type | Key Size | CT Size | Enc Time | Dec Time |
|--------|------|----------|---------|----------|----------|
| AES-256-GCM | Symmetric | 256 bits | n + 128 bits | ~1 ns/byte | ~1 ns/byte |
| Kyber-768 | KEM | 2400 B | 1088 B | ~30 us | ~25 us |
| BIKE-L3 | Code-KEM | 3114 B | 3114 B | ~100 us | ~200 us |
| HQC-256 | Code-KEM | 7245 B | 14469 B | ~300 us | ~500 us |
| **HGOE-128** | Orbit-KEM | **?** | **344 bits** | **?** | **?** |

Fill in the HGOE-128 row from benchmarks. This data informs Phase 14.

**Exit criteria:** Comparison table populated with HGOE measurements.

---

#### 11.8 — Invariant Attack Verification

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_test.g` | **Deps:** 11.3

Empirically verify the invariant attack and defense:

1. **Attack test:** Create a scheme with different-weight representatives.
   Confirm Hamming weight distinguishes them with advantage 1 (100% accuracy).
2. **Defense test:** Create a scheme with same-weight representatives.
   Confirm Hamming weight gives advantage 0 (50% accuracy, random guessing).
3. **Higher-order invariant test:** Test several candidate invariants on
   same-weight representatives: number of bit-runs, autocorrelation at lag 1,
   parity of specific coordinate subsets. Measure empirical advantage for each.

**Exit criteria:** Attack test confirms 100% accuracy on different-weight reps.
Defense test confirms ~50% accuracy on same-weight reps. Higher-order
invariant tests report their empirical advantages.

---

#### 11.9 — Documentation and Reproducibility

**Effort:** 5h | **File:** `implementation/README.md` | **Deps:** 11.5, 11.6

Write documentation covering:
- Installation instructions (GAP, packages, exact versions)
- How to run tests: `gap orbcrypt_test.g`
- How to run benchmarks: `gap orbcrypt_bench.g`
- How to generate parameters: `gap orbcrypt_params.g`
- Interpretation guide for benchmark output
- Known limitations and caveats

**Exit criteria:** A fresh GAP installation can reproduce all benchmarks
following only the README instructions.

---

### Phase 11 Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 11.1 | GAP Environment Setup | `implementation/gap/README.md` | 2h | None |
| 11.2 | Key Generation | `implementation/gap/orbcrypt_keygen.g` | 5h | 11.1 |
| 11.3 | KEM Enc/Dec | `implementation/gap/orbcrypt_kem.g` | 4h | 11.2 |
| 11.4 | Correctness Tests | `implementation/gap/orbcrypt_test.g` | 3h | 11.3 |
| 11.5 | Benchmark Harness | `implementation/gap/orbcrypt_bench.g` | 5h | 11.3 |
| 11.6 | Parameter Generation | `implementation/gap/orbcrypt_params.g` | 4h | 11.2 |
| 11.7 | Comparison Data | `implementation/gap/orbcrypt_bench.g` | 4h | 11.5 |
| 11.8 | Invariant Attack Verification | `implementation/gap/orbcrypt_test.g` | 4h | 11.3 |
| 11.9 | Documentation | `implementation/README.md` | 5h | 11.5, 11.6 |

**Parallelism:** 11.4 (tests) and 11.5 (benchmarks) can run in parallel
after 11.3. 11.6 (params) depends only on 11.2.

---

## Phase 12 — Hardness Alignment (LESS/MEDS/TI)

### Weeks 23–28 | 8 Work Units | ~32 Hours

**Goal:** Align Orbcrypt's security assumptions with hardness problems
underlying active NIST Post-Quantum Cryptography candidates. This inherits
the scrutiny those candidates receive and strengthens the theoretical
foundation beyond the current informal GI/CE reductions.

**Target problems:**

| Problem | Used By | Relationship to Orbcrypt |
|---------|---------|------------------------|
| **Linear Code Equivalence (LE)** | LESS signature scheme | Direct: CE-OIA reduces to LE |
| **Matrix Code Equivalence (MCE)** | MEDS signature scheme | Extension: tensor generalization of CE |
| **Alternating Trilinear Form Equiv (ATFE)** | MEDS | Stronger: believed harder than GI |
| **Tensor Isomorphism (TI)** | Emerging research | Strictly harder than GI (no quasi-poly algorithm known) |

**New files:**

```
Orbcrypt/
  Hardness/
    CodeEquivalence.lean    — CE problem definition, relation to OIA
    TensorAction.lean       — Tensor group action definition
    Reductions.lean         — Reduction theorems (CE-OIA to LE, etc.)
  docs/
    HARDNESS_ANALYSIS.md    — Detailed hardness comparison document
```

---

#### 12.1 — Code Equivalence Problem Definition

**Effort:** 3h | **File:** `Hardness/CodeEquivalence.lean` | **Deps:** Phase 2

Formally define the Permutation Code Equivalence problem:

```lean
/-- Two codes are permutation-equivalent if a coordinate permutation
    maps one to the other. -/
def ArePermEquivalent (C₁ C₂ : Finset (Fin n → F)) : Prop :=
  ∃ σ : Equiv.Perm (Fin n), ∀ c ∈ C₁,
    (fun i => c (σ⁻¹ i)) ∈ C₂

/-- The Code Equivalence decision problem. -/
def CodeEquivalenceProblem (n : ℕ) (F : Type*) [Field F] :=
  Finset (Fin n → F) × Finset (Fin n → F) → Prop
```

Prove the basic structural result: CE is at least as hard as GI.

```lean
/-- Graph Isomorphism reduces to Code Equivalence.
    (Statement only — the reduction is specified, not computed.) -/
theorem gi_reduces_to_ce : -- specification of the reduction
  sorry -- Full proof requires graph-to-code encoding
```

**Exit criteria:** Definitions compile. Reduction is stated with clear
documentation of what the `sorry` represents.

---

#### 12.2 — PAut Recovery Implies CE

**Effort:** 4h | **File:** `Hardness/CodeEquivalence.lean` | **Deps:** 12.1

Prove that recovering the permutation automorphism group of a code solves CE:

```lean
/-- If an adversary can recover PAut(C) from orbit samples, they can
    solve Code Equivalence for codes with that automorphism group. -/
theorem paut_recovery_solves_ce
    (C : Finset (Fin n → F))
    (recover : (ℕ → Fin n → F) → Subgroup (Equiv.Perm (Fin n)))
    (hRecover : recover (orbitSamples C) = paut C) :
    -- Then CE is solvable for C
    ∀ C', ArePermEquivalent C C' ↔
      ∃ σ ∈ recover (orbitSamples C), ∀ c ∈ C, (fun i => c (σ⁻¹ i)) ∈ C' :=
  sorry -- Proof requires group-theoretic coset argument
```

**Exit criteria:** Statement type-checks with clear documentation.

---

#### 12.3 — LESS Alignment Document

**Effort:** 5h | **File:** `docs/HARDNESS_ANALYSIS.md` | **Deps:** 12.1

Write a detailed analysis document establishing the connection between
CE-OIA and the LESS signature scheme's hardness assumption:

- LESS (Biasse, Micheli, Persichetti, 2020) uses the Linear Equivalence
  Problem: given two linear codes, find a monomial transformation mapping
  one to the other.
- Permutation equivalence is a special case of monomial equivalence
  (monomial matrices with all non-zero entries equal to 1).
- CE-OIA's hardness is therefore a *weaker* assumption than LESS's hardness
  (breaking CE is necessary but not sufficient for breaking LESS).
- Document the reduction chain: CE-OIA <= LE <= ME (monomial equivalence).

**Exit criteria:** Document with precise reduction statements, complexity
comparisons, and references to LESS/MEDS NIST submissions.

---

#### 12.4 — Tensor Isomorphism Action

**Effort:** 5h | **File:** `Hardness/TensorAction.lean` | **Deps:** Phase 2

Define a group action on 3-tensors, which generalizes the permutation action
on bitstrings to a setting believed harder than GI:

```lean
/-- A 3-tensor over a finite field. -/
def Tensor3 (n : ℕ) (F : Type*) := Fin n → Fin n → Fin n → F

/-- GL(n,F)^3 acts on 3-tensors by simultaneous basis change. -/
instance tensorAction (n : ℕ) (F : Type*) [Field F] :
    MulAction (GL (Fin n) F × GL (Fin n) F × GL (Fin n) F)
              (Tensor3 n F) where
  smul := fun ⟨A, B, C⟩ T => fun i j k =>
    -- T'_{ijk} = sum_{a,b,c} A_{ia} B_{jb} C_{kc} T_{abc}
    sorry -- Tensor contraction (complex but standard)
  one_smul := sorry
  mul_smul := sorry
```

**Design note:** The `sorry`s here are for the tensor contraction arithmetic,
which is tedious but standard. The value is in establishing the type-level
framework for tensor-based orbit encryption.

**Exit criteria:** Type signatures are correct. Action law `sorry`s are
clearly documented as arithmetic obligations.

---

#### 12.5 — Tensor Isomorphism Problem

**Effort:** 4h | **File:** `Hardness/TensorAction.lean` | **Deps:** 12.4

Define the Tensor Isomorphism (TI) decision problem and state its
relationship to GI:

```lean
/-- Two tensors are isomorphic if a basis change maps one to the other. -/
def AreTensorIsomorphic (T₁ T₂ : Tensor3 n F) : Prop :=
  ∃ g : GL (Fin n) F × GL (Fin n) F × GL (Fin n) F,
    g • T₁ = T₂

/-- TI is at least as hard as GI (GI reduces to TI).
    This is a known result: graphs can be encoded as 3-tensors
    such that graph isomorphism corresponds to tensor isomorphism. -/
theorem gi_reduces_to_ti : True := trivial -- Placeholder for the reduction
```

**Exit criteria:** Definitions compile. The GI-to-TI reduction is documented
in comments with literature references.

---

#### 12.6 — Tensor-OIA Definition

**Effort:** 4h | **File:** `Hardness/Reductions.lean` | **Deps:** 12.4, 12.5

Define an OIA variant based on tensor isomorphism:

```lean
/-- Tensor-OIA: orbit samples from GL^3 action on 3-tensors are
    computationally indistinguishable. -/
def TensorOIA (T₀ T₁ : Tensor3 n F)
    (hNonIso : ¬ AreTensorIsomorphic T₀ T₁) : Prop :=
  ∀ (f : Tensor3 n F → Bool)
    (g₀ g₁ : GL (Fin n) F × GL (Fin n) F × GL (Fin n) F),
    f (g₀ • T₀) = f (g₁ • T₁)
```

State: TensorOIA implies CE-OIA (tensor isomorphism subsumes code equivalence).

**Exit criteria:** Definition type-checks.

---

#### 12.7 — Reduction Chain Documentation

**Effort:** 4h | **File:** `Hardness/Reductions.lean` | **Deps:** 12.1–12.6

Formalize the reduction chain as a sequence of implication theorems:

```
TI-hard → TensorOIA → CE-OIA → GI-OIA → Orbcrypt IND-1-CPA secure
```

Each implication is either proved or stated with `sorry` and documented:

```lean
-- Proved (or trivially follows from definitions):
theorem tensor_oia_implies_ce_oia : TensorOIA → CEOIA := sorry
theorem ce_oia_implies_gi_oia : CEOIA → GIOIA := sorry

-- Proved in Phase 4:
-- oia_implies_1cpa : OIA → IsSecure
```

**Exit criteria:** The full reduction chain is stated with types that
type-check. Each `sorry` has a comment explaining what proof is needed.

---

#### 12.8 — Hardness Comparison Table

**Effort:** 3h | **File:** `docs/HARDNESS_ANALYSIS.md` | **Deps:** 12.3, 12.7

Complete the hardness analysis document with a comprehensive comparison:

| Problem | Best Classical | Best Quantum | Used By | Orbcrypt Relation |
|---------|---------------|-------------|---------|------------------|
| Factoring | L(1/3) (NFS) | Poly (Shor) | RSA | None |
| DLP | L(1/3) | Poly (Shor) | ECDH | None |
| LWE | 2^(n/log n) | 2^(n/log n) | Kyber, Dilithium | None |
| GI | 2^O(sqrt(n log n)) | Open | ZKP | GI-OIA reduces to GI |
| Code Equiv | >= GI | Open | LESS | CE-OIA reduces to CE |
| Matrix Code Equiv | >= CE | Open | MEDS | Extension of CE |
| Tensor Iso | >= GI, no quasi-poly | Open | Emerging | TensorOIA is strongest |
| HSP on S_n | Super-poly | Super-poly | Multi-query security | HGOE multi-query |

**Exit criteria:** Document is complete, internally consistent, and all
claims have literature references.

---

### Phase 12 Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 12.1 | Code Equivalence Def | `Hardness/CodeEquivalence.lean` | 3h | Phase 2 |
| 12.2 | PAut Recovery Implies CE | `Hardness/CodeEquivalence.lean` | 4h | 12.1 |
| 12.3 | LESS Alignment Document | `docs/HARDNESS_ANALYSIS.md` | 5h | 12.1 |
| 12.4 | Tensor Action | `Hardness/TensorAction.lean` | 5h | Phase 2 |
| 12.5 | Tensor Isomorphism Problem | `Hardness/TensorAction.lean` | 4h | 12.4 |
| 12.6 | Tensor-OIA Definition | `Hardness/Reductions.lean` | 4h | 12.4, 12.5 |
| 12.7 | Reduction Chain | `Hardness/Reductions.lean` | 4h | 12.1–12.6 |
| 12.8 | Hardness Comparison | `docs/HARDNESS_ANALYSIS.md` | 3h | 12.3, 12.7 |

**Parallelism:** Track A (12.1 → 12.2 → 12.3) and Track B (12.4 → 12.5 →
12.6) are fully independent. They merge at 12.7.

---

## Phase 13 — Public-Key Extension

### Weeks 26–30 | 7 Work Units | ~28 Hours

**Goal:** Explore paths from symmetric-key to public-key orbit encryption.
The current scheme requires both parties to share G. This phase investigates
three approaches: oblivious orbit sampling, KEM-based key agreement, and
commutative group action Diffie-Hellman.

**New files:**

```
Orbcrypt/
  PublicKey/
    ObliviousSampling.lean  — Randomizer-based public encryption
    KEMAgreement.lean       — KEM-based key agreement protocol
    CommutativeAction.lean  — CSIDH-style commutative action
  docs/
    PUBLIC_KEY_ANALYSIS.md  — Analysis of public-key extension feasibility
```

---

#### 13.1 — Oblivious Orbit Sampling Definition

**Effort:** 4h | **File:** `PublicKey/ObliviousSampling.lean` | **Deps:** Phase 7

Define oblivious orbit sampling: the key holder publishes a set of
"randomizers" (precomputed orbit elements), and the sender combines them
to produce fresh orbit samples without knowing G.

```lean
/-- A set of published randomizers for a single orbit. -/
structure OrbitalRandomizers (G : Type*) (X : Type*)
    [Group G] [MulAction G X] where
  /-- The base point whose orbit we sample from. -/
  basePoint : X
  /-- Published randomizers: elements of the orbit of basePoint. -/
  randomizers : Fin t → X
  /-- All randomizers lie in the orbit of basePoint. -/
  in_orbit : ∀ i, randomizers i ∈ MulAction.orbit G basePoint

/-- Oblivious sampling: combine two randomizers via a public operation
    to produce a new orbit element. The combination must preserve
    orbit membership. -/
def obliviousSample (ors : OrbitalRandomizers G X)
    (combine : X → X → X)
    (hClosed : ∀ x y, x ∈ MulAction.orbit G ors.basePoint →
      y ∈ MulAction.orbit G ors.basePoint →
      combine x y ∈ MulAction.orbit G ors.basePoint)
    (i j : Fin t) : X :=
  combine (ors.randomizers i) (ors.randomizers j)
```

**Key challenge:** The `combine` operation must preserve orbit membership.
For bitstrings, XOR does NOT preserve orbits in general (XOR of two
weight-w strings may have weight != w). Possible alternatives:
- Composition of the underlying permutations (but this reveals G)
- A "re-randomize" operation specific to the group structure

This challenge is documented as an open problem.

**Exit criteria:** Definitions compile. Open problem is clearly documented.

---

#### 13.2 — Oblivious Sampling Correctness

**Effort:** 4h | **File:** `PublicKey/ObliviousSampling.lean` | **Deps:** 13.1

Prove that oblivious samples lie in the correct orbit:

```lean
theorem oblivious_sample_in_orbit (ors : OrbitalRandomizers G X)
    (combine : X → X → X)
    (hClosed : ∀ x y, x ∈ MulAction.orbit G ors.basePoint →
      y ∈ MulAction.orbit G ors.basePoint →
      combine x y ∈ MulAction.orbit G ors.basePoint)
    (i j : Fin t) :
    obliviousSample ors combine hClosed i j ∈
      MulAction.orbit G ors.basePoint :=
  hClosed _ _ (ors.in_orbit i) (ors.in_orbit j)
```

Also state the security requirement: the sender learns nothing about G
from the randomizers beyond orbit membership.

**Exit criteria:** Orbit membership theorem compiles.

---

#### 13.3 — Randomizer Refresh Protocol

**Effort:** 4h | **File:** `PublicKey/ObliviousSampling.lean` | **Deps:** 13.1

The randomizer set is a bounded resource — once all are used, the key holder
must publish fresh ones. Define the refresh protocol:

```lean
/-- A randomizer refresh: the key holder samples new group elements and
    publishes new orbit elements. -/
def refreshRandomizers (G_elem_sampler : ℕ → G)
    (basePoint : X) (t : ℕ) (epoch : ℕ) : Fin t → X :=
  fun i => G_elem_sampler (epoch * t + i.val) • basePoint
```

State the security property: fresh randomizers from different epochs are
independently distributed (assuming the group element sampler is independent).

**Exit criteria:** Definition compiles. Independence property is stated.

---

#### 13.4 — KEM-Based Key Agreement

**Effort:** 4h | **File:** `PublicKey/KEMAgreement.lean` | **Deps:** Phase 7

Define a two-party key agreement using the OrbitKEM:

```lean
/-- Two-party key agreement using orbit KEMs.
    Alice and Bob each hold a secret group. They exchange KEM ciphertexts
    and derive a shared key via a combiner. -/
structure OrbitKeyAgreement (G_A G_B : Type*) (X K : Type*)
    [Group G_A] [Group G_B] [MulAction G_A X] [MulAction G_B X] where
  /-- Alice's KEM. -/
  kem_A : OrbitKEM G_A X K
  /-- Bob's KEM. -/
  kem_B : OrbitKEM G_B X K
  /-- Key combiner: derives the shared key from both parties' keys. -/
  combiner : K → K → K
```

**Limitation:** This requires both parties to have their own secret group,
which is essentially a symmetric key. A true public-key scheme would allow
Bob to encrypt without ANY secret. This is documented as a fundamental
open problem.

**Exit criteria:** Structure type-checks. Limitation is documented.

---

#### 13.5 — Commutative Group Action Framework

**Effort:** 4h | **File:** `PublicKey/CommutativeAction.lean` | **Deps:** Phase 2

Define the commutative group action framework (CSIDH-style) that enables
true public-key orbit encryption:

```lean
/-- A commutative group action: the group is abelian. -/
class CommGroupAction (G : Type*) (X : Type*)
    extends MulAction G X where
  comm : ∀ (g h : G) (x : X), g • (h • x) = h • (g • x)

/-- CSIDH-style key exchange using a commutative group action. -/
def csidh_exchange [CommGroupAction G X]
    (a b : G) (x₀ : X) : X × X × X :=
  (a • x₀, b • x₀, a • (b • x₀))
  -- Alice publishes a • x₀, Bob publishes b • x₀
  -- Shared secret: a • b • x₀ = b • a • x₀ (by commutativity)
```

Prove the key exchange correctness:

```lean
theorem csidh_correctness [CommGroupAction G X] (a b : G) (x₀ : X) :
    a • (b • x₀) = b • (a • x₀) :=
  CommGroupAction.comm a b x₀
```

**Exit criteria:** CommGroupAction class and CSIDH correctness compile.

---

#### 13.6 — Commutative Orbit Encryption

**Effort:** 4h | **File:** `PublicKey/CommutativeAction.lean` | **Deps:** 13.5

Define public-key orbit encryption using a commutative group action:

```lean
/-- Public-key orbit encryption via commutative group action.
    - Secret key: a ∈ G
    - Public key: a • x₀
    - Encryption of m: (b • x₀, b • (a • x₀) ⊕ m) for random b
    - Decryption: a • (b • x₀) = b • (a • x₀), then recover m

    This is essentially ElGamal over a commutative group action,
    adapted to the orbit encryption setting. -/
structure CommOrbitPKE (G : Type*) (X : Type*)
    [CommGroupAction G X] where
  basePoint : X
  secretKey : G
  publicKey : X  -- = secretKey • basePoint
  pk_valid : publicKey = secretKey • basePoint
```

**Exit criteria:** Structure type-checks.

---

#### 13.7 — Public-Key Analysis Document

**Effort:** 4h | **File:** `docs/PUBLIC_KEY_ANALYSIS.md` | **Deps:** 13.1–13.6

Write a comprehensive analysis of public-key extension feasibility:

1. **Oblivious sampling:** Viable for bounded-use scenarios. Key challenge:
   finding a `combine` operation that preserves orbit membership without
   revealing the group. Status: open problem.

2. **KEM key agreement:** Works but requires both parties to hold symmetric
   keys. Not a true public-key scheme. Useful for session key establishment
   in scenarios where both parties have pre-shared Orbcrypt keys.

3. **Commutative group actions (CSIDH-style):** The most promising path.
   Requires finding a commutative group action that satisfies OIA. The class
   group action on supersingular elliptic curves (CSIDH) is one candidate,
   but its orbit structure differs from the permutation setting. An open
   research direction.

4. **Fundamental obstacle:** Non-commutative groups (like subgroups of S_n)
   do not naturally support public-key operations. The non-commutativity
   that makes the group harder to recover is exactly what prevents
   Diffie-Hellman-style key exchange.

**Exit criteria:** Document is complete with clear feasibility assessments.

---

### Phase 13 Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 13.1 | Oblivious Sampling Def | `PublicKey/ObliviousSampling.lean` | 4h | Phase 7 |
| 13.2 | Oblivious Sampling Correctness | `PublicKey/ObliviousSampling.lean` | 4h | 13.1 |
| 13.3 | Randomizer Refresh | `PublicKey/ObliviousSampling.lean` | 4h | 13.1 |
| 13.4 | KEM Key Agreement | `PublicKey/KEMAgreement.lean` | 4h | Phase 7 |
| 13.5 | Commutative Action Framework | `PublicKey/CommutativeAction.lean` | 4h | Phase 2 |
| 13.6 | Commutative Orbit Encryption | `PublicKey/CommutativeAction.lean` | 4h | 13.5 |
| 13.7 | Public-Key Analysis Document | `docs/PUBLIC_KEY_ANALYSIS.md` | 4h | 13.1–13.6 |

---

## Phase 14 — Parameter Selection & Benchmarks

### Weeks 28–31 | 6 Work Units | ~20 Hours

**Goal:** Produce concrete parameter tables for multiple security levels,
generate comparison data against existing schemes, and publish a parameter
recommendation document. This phase transforms GAP benchmark data (Phase 11)
into actionable parameter guidance.

**New files:**

```
docs/
  PARAMETERS.md          — Parameter recommendation document
  benchmarks/
    results_80.csv       — Benchmark data for lambda=80
    results_128.csv      — Benchmark data for lambda=128
    results_192.csv      — Benchmark data for lambda=192
    results_256.csv      — Benchmark data for lambda=256
    comparison.csv       — Cross-scheme comparison
```

---

#### 14.1 — Parameter Space Exploration

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_params.g` | **Deps:** Phase 11

Systematically explore the parameter space beyond the default QC construction.
For each security level, vary:

- Block size b in {4, 8, 16, 32}
- Index ell (derived from b and lambda)
- Target weight w in {n/3, n/2, 2n/3}
- Code rate k/n in {1/4, 1/3, 1/2}

For each configuration, measure:
- Actual |PAut(C)| (does it meet the 2^lambda threshold?)
- Number of distinct orbits at target weight
- Key generation time
- Canonical image computation time (proxy for decryption)

Output: a CSV with all configurations and their measurements.

**Exit criteria:** Parameter sweep completes for lambda=128 with at least
16 configurations tested.

---

#### 14.2 — Optimal Parameter Selection

**Effort:** 3h | **File:** `docs/PARAMETERS.md` | **Deps:** 14.1

Analyze the parameter sweep data to identify optimal configurations. The
optimization targets (in priority order):

1. **Security:** |PAut(C)| >= 2^lambda (hard constraint)
2. **Decryption speed:** Minimize canonical image computation time
3. **Ciphertext size:** Minimize n (determines ciphertext length)
4. **Key size:** Minimize seed representation

Produce a recommended parameter set for each security level:

```
| Level | Lambda | n   | b  | ell | k   | w   | |G| (log2) | CT size | Dec time |
|-------|--------|-----|----|-----|-----|-----|-------------|---------|----------|
| L1    | 80     | ?   | ?  | ?   | ?   | ?   | >= 80       | ? bits  | ? ms     |
| L3    | 128    | ?   | ?  | ?   | ?   | ?   | >= 128      | ? bits  | ? ms     |
| L5    | 192    | ?   | ?  | ?   | ?   | ?   | >= 192      | ? bits  | ? ms     |
| L7    | 256    | ?   | ?  | ?   | ?   | ?   | >= 256      | ? bits  | ? ms     |
```

**Exit criteria:** Parameter table with concrete numbers for all four levels.

---

#### 14.3 — Comparison Against Existing Schemes

**Effort:** 4h | **File:** `docs/PARAMETERS.md` | **Deps:** 14.2, 11.7

Build the definitive comparison table. For each scheme at NIST Level 3
(~128-bit classical security):

| Metric | AES-256 | Kyber-768 | BIKE-L3 | HQC-256 | **HGOE-128** |
|--------|---------|-----------|---------|---------|-------------|
| Type | Sym | KEM | KEM | KEM | **KEM** |
| Key (bytes) | 32 | 2400 | 3114 | 7245 | **32** (seed) |
| CT (bytes) | 16+tag | 1088 | 3114 | 14469 | **n/8** |
| Enc (ops) | ~100 | ~30K | ~100K | ~300K | **?** |
| Dec (ops) | ~100 | ~25K | ~200K | ~500K | **?** |
| PQ secure? | No | Yes | Yes | Yes | **Conjectured** |
| Assumption | None | MLWE | QC-MDPC | QC-HQC | **CE-OIA** |

Fill in the HGOE columns from benchmarks. Be honest about where Orbcrypt
is competitive and where it is not.

**Exit criteria:** Comparison table with all cells filled. Honest assessment
paragraph for each metric.

---

#### 14.4 — Security Margin Analysis

**Effort:** 3h | **File:** `docs/PARAMETERS.md` | **Deps:** 14.2

Analyze the security margin: how much room is there between the parameter
choices and the best known attacks?

For each parameter set:
- **Brute-force orbit enumeration:** Cost = |orbit| = |G| / |Stab|.
  For |G| >= 2^128 and |Stab| = 1, cost = 2^128.
- **Birthday attack on orbits:** Cost = sqrt(|G|) = 2^64 for lambda=128.
  Recommendation: use lambda=256 for 128-bit birthday security.
- **Babai's GI algorithm:** Cost = 2^O(sqrt(n log n)) where n is the
  number of vertices in the underlying graph (for GI-OIA). Compute for
  each parameter set.
- **Algebraic attacks on QC structure:** Effective dimension after folding
  = n/b. Compute for each parameter set.

**Exit criteria:** Security margin table with concrete bit-security
estimates for each attack vector.

---

#### 14.5 — Ciphertext Expansion Analysis

**Effort:** 3h | **File:** `docs/PARAMETERS.md` | **Deps:** 14.2

Analyze the ciphertext expansion ratio (ciphertext size / key size):

- For KEM mode: ciphertext = n bits (one orbit element).
- For hybrid mode (KEM+DEM): ciphertext = n bits (KEM) + |message| + tag.
- Compare to AES-GCM: ciphertext = |message| + 128 bits (tag) + 96 bits (IV).

The expansion ratio for short messages is dominated by the KEM ciphertext.
For long messages, the DEM dominates and Orbcrypt's overhead is amortized.

Compute the break-even message length: the message size at which Orbcrypt's
total ciphertext size equals that of a pure AES-GCM encryption.

**Exit criteria:** Break-even analysis with concrete numbers.

---

#### 14.6 — Parameter Recommendation Summary

**Effort:** 3h | **File:** `docs/PARAMETERS.md` | **Deps:** 14.1–14.5

Write the final parameter recommendation section:

1. **Conservative recommendation:** Optimized for security margin. Larger
   parameters, slower but with more headroom against future cryptanalysis.

2. **Balanced recommendation:** Best trade-off between security and
   performance. This is the "default" parameter set.

3. **Aggressive recommendation:** Optimized for performance. Minimal
   parameters that still meet the security threshold. Suitable for
   constrained environments.

4. **Not recommended configurations:** Parameter sets that fail validation
   (|G| too small, known invariant attacks, etc.). Document why they fail.

**Exit criteria:** Three concrete parameter sets per security level,
with clear justification for each choice.

---

### Phase 14 Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 14.1 | Parameter Space Exploration | GAP scripts | 4h | Phase 11 |
| 14.2 | Optimal Parameter Selection | `docs/PARAMETERS.md` | 3h | 14.1 |
| 14.3 | Scheme Comparison | `docs/PARAMETERS.md` | 4h | 14.2, 11.7 |
| 14.4 | Security Margin Analysis | `docs/PARAMETERS.md` | 3h | 14.2 |
| 14.5 | Ciphertext Expansion Analysis | `docs/PARAMETERS.md` | 3h | 14.2 |
| 14.6 | Parameter Recommendation | `docs/PARAMETERS.md` | 3h | 14.1–14.5 |

---

## Phase 15 — Decryption Optimization

### Weeks 30–34 | 7 Work Units | ~22 Hours

**Goal:** Reduce decryption cost from O(n^c) with c approx 3-5 (full partition
backtracking) to a fast path exploiting QC code structure. This is the key
engineering challenge for practical competitiveness.

**Core insight:** The automorphism group of a QC code contains a large,
known, structured subgroup: the cyclic-shift group (Z/bZ)^ell. Decryption
can decompose into two phases:
1. **Fast phase:** Reduce modulo the known cyclic structure (O(n) operations).
2. **Residual phase:** Resolve ambiguity from "accidental" automorphisms
   (much smaller group, cheaper backtracking).

**New files:**

```
Orbcrypt/
  Optimization/
    QCCanonical.lean     — QC-structured canonical form (Lean specification)
    TwoPhaseDecrypt.lean — Two-phase decryption specification
implementation/
  gap/
    orbcrypt_fast_dec.g  — Fast decryption implementation in GAP
```

---

#### 15.1 — QC Cyclic Reduction

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_fast_dec.g` | **Deps:** Phase 11

Implement the fast cyclic-reduction phase in GAP:

```gap
# For a QC code with block size b and index ell:
# The cyclic subgroup C = (Z/bZ)^ell acts by shifting within each block.
# Reduction: compute the lexicographic minimum over all C-shifts.

QCCyclicReduce := function(x, b, ell)
  local best, n, i, shift, candidate;
  n := b * ell;
  best := x;
  # For each of b^ell cyclic shifts:
  # (Optimization: process blocks independently)
  for i in [1..ell] do
    # Find the lexicographically minimal cyclic rotation of block i
    best := MinimalBlockRotation(best, b, i);
  od;
  return best;
end;
```

**Optimization:** Process each block independently (O(b * ell) = O(n) total),
rather than iterating over all b^ell combinations.

**Exit criteria:** `QCCyclicReduce` produces the correct cyclic canonical
form. Benchmark shows O(n) scaling.

---

#### 15.2 — Residual Group Computation

**Effort:** 3h | **File:** `implementation/gap/orbcrypt_fast_dec.g` | **Deps:** 15.1, 11.2

After cyclic reduction, the residual group is:

```
G_residual = PAut(C) / (Z/bZ)^ell
```

This quotient group is typically much smaller than PAut(C). Compute it
during key generation and store it as part of the secret key:

```gap
ComputeResidualGroup := function(G, b, ell)
  local cyclicSubgroup, residual;
  cyclicSubgroup := QCCyclicSubgroup(b, ell);
  # G_residual represents automorphisms beyond the cyclic structure
  residual := RightTransversal(G, cyclicSubgroup);
  return residual;
end;
```

**Exit criteria:** Residual group is computed correctly. Its size is
measured and reported (expected: much smaller than |G|).

---

#### 15.3 — Two-Phase Decryption

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_fast_dec.g` | **Deps:** 15.1, 15.2

Combine the two phases into a complete fast decryption:

```gap
FastDecaps := function(sk, c)
  local phase1, phase2, canon;
  # Phase 1: Fast cyclic reduction (O(n))
  phase1 := QCCyclicReduce(c, sk.b, sk.ell);
  # Phase 2: Residual backtracking (O(n^c') with c' << c)
  phase2 := CanonicalImage(sk.residualGroup, phase1);
  # The result is the full canonical form
  canon := phase2;
  return sk.keyDerive(canon);
end;
```

Validate: `FastDecaps(sk, c) = SlowDecaps(sk, c)` for all test cases.

**Exit criteria:** Fast and slow decryption produce identical results
for 10,000 test cases. Speed improvement is measured and reported.

---

#### 15.4 — Syndrome-Based Orbit Identification

**Effort:** 4h | **File:** `implementation/gap/orbcrypt_fast_dec.g` | **Deps:** 11.2

Explore an alternative fast decryption path using syndrome computation:

```gap
# The secret code C has a parity-check matrix H.
# The syndrome of c is s = H * c^T.
# If c = g . x_0 for g in PAut(C), then:
#   s = H * (g . x_0)^T = (H * P_g) * x_0^T
# where P_g is the permutation matrix of g.
# Since g in PAut(C), P_g preserves C, so H * P_g = H * P_g.
# The syndrome therefore depends only on the ORBIT of c.

SyndromeDecaps := function(sk, c)
  local syndrome, key;
  syndrome := sk.H * c;  # Matrix-vector multiply: O(n*k) = O(n^2)
  key := sk.keyDerive(syndrome);
  return key;
end;
```

**Caveat:** This only works if the syndrome uniquely identifies the orbit.
For the KEM (single base point), uniqueness is guaranteed if the parity-check
matrix H is chosen correctly. For the general scheme (multiple representatives),
uniqueness requires that different orbits produce different syndromes.

**Exit criteria:** Syndrome-based decryption is tested. Its correctness
and speed are compared to partition backtracking.

---

#### 15.5 — Lean Specification of Two-Phase Decryption

**Effort:** 3h | **File:** `Optimization/TwoPhaseDecrypt.lean` | **Deps:** 15.3, Phase 5

Formalize the correctness of two-phase decryption in Lean:

```lean
/-- Two-phase decryption is correct if the cyclic reduction followed by
    residual canonicalization equals the full canonical form. -/
theorem two_phase_correct
    (G : Subgroup (Equiv.Perm (Fin n)))
    (C : Subgroup G)  -- cyclic subgroup
    (can_full : CanonicalForm G (Bitstring n))
    (can_cyclic : CanonicalForm C (Bitstring n))
    (can_residual : CanonicalForm (G / C) (Bitstring n)) -- quotient
    (hDecomp : ∀ x, can_full.canon x =
      can_residual.canon (can_cyclic.canon x)) :
    ∀ g : G, ∀ x : Bitstring n,
      can_full.canon (g • x) = can_residual.canon (can_cyclic.canon (g • x)) :=
  fun g x => hDecomp (g • x)
```

**Exit criteria:** Specification compiles. The decomposition hypothesis
`hDecomp` is clearly documented as the key correctness requirement.

---

#### 15.6 — Orbit Hash Function (Probabilistic Canonical Form)

**Effort:** 2h | **File:** `implementation/gap/orbcrypt_fast_dec.g` | **Deps:** 11.3

Implement a probabilistic orbit hash as an alternative to exact canonical forms:

```gap
OrbitHash := function(G, x, nSamples)
  local samples, sorted, hash;
  # Sample nSamples elements of the orbit
  samples := List([1..nSamples], i -> Image(PseudoRandom(G), x));
  # Sort them lexicographically
  sorted := SortedList(samples);
  # Hash the sorted list
  hash := SHA256(Concatenation(List(sorted, String)));
  return hash;
end;
```

This gives O(nSamples * n) decryption instead of O(n^c) backtracking.
The trade-off: probabilistic correctness (hash collisions between different
orbits, negligible for large nSamples).

**Exit criteria:** Orbit hash produces consistent results across calls.
Collision rate is measured empirically.

---

#### 15.7 — Decryption Speed Comparison

**Effort:** 2h | **File:** `implementation/gap/orbcrypt_bench.g` | **Deps:** 15.1–15.6

Benchmark all decryption methods and produce a comparison:

| Method | Time (lambda=128) | Correctness | Notes |
|--------|-------------------|-------------|-------|
| Full partition backtracking | Baseline | Exact | O(n^c) |
| Two-phase (cyclic + residual) | ? | Exact | O(n + n'^c') |
| Syndrome-based | ? | Exact (if valid) | O(n^2) |
| Orbit hash (100 samples) | ? | Probabilistic | O(100n) |
| Orbit hash (1000 samples) | ? | Probabilistic | O(1000n) |

**Exit criteria:** Comparison table filled with measured timings.
Best method identified and documented.

---

### Phase 15 Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 15.1 | QC Cyclic Reduction | GAP | 4h | Phase 11 |
| 15.2 | Residual Group Computation | GAP | 3h | 15.1, 11.2 |
| 15.3 | Two-Phase Decryption | GAP | 4h | 15.1, 15.2 |
| 15.4 | Syndrome-Based Identification | GAP | 4h | 11.2 |
| 15.5 | Lean Specification | `Optimization/TwoPhaseDecrypt.lean` | 3h | 15.3, Phase 5 |
| 15.6 | Orbit Hash Function | GAP | 2h | 11.3 |
| 15.7 | Speed Comparison | GAP | 2h | 15.1–15.6 |

---

## Phase 16 — Formal Verification of New Components

### Weeks 30–36 | 10 Work Units | ~36 Hours

**Goal:** Extend the Lean 4 formalization to cover the new components from
Phases 7–10. Maintain the project's zero-sorry, zero-custom-axiom standard
wherever possible. Components that require probabilistic reasoning may use
documented `sorry`s as placeholders for future work.

**Scope:** Verify KEM correctness, AEAD correctness, hybrid encryption
correctness, and the key structural lemmas from the new modules. Security
theorems involving probability (Phase 8) may remain partially formalized.

---

#### 16.1 — KEM Module Verification

**Effort:** 4h | **File:** `KEM/*.lean` | **Deps:** Phase 7

Audit all Phase 7 modules for correctness:
- Verify `kem_correctness` compiles with zero `sorry`
- Verify `kemoia_implies_secure` compiles with zero `sorry`
- Verify `toKEM_correct` compiles with zero `sorry`
- Run `#print axioms` on each theorem and document results
- Verify CI passes with new modules

**Exit criteria:** All Phase 7 theorems compile. Axiom report updated
in `Orbcrypt.lean`.

---

#### 16.2 — AEAD Module Verification

**Effort:** 4h | **File:** `AEAD/*.lean` | **Deps:** Phase 10

Audit all Phase 10 modules:
- Verify `aead_correctness` compiles with zero `sorry`
- Verify `hybrid_correctness` compiles with zero `sorry`
- Verify MAC correctness field is well-typed
- Run `#print axioms` on each theorem

**Exit criteria:** All Phase 10 theorems compile. Axiom report updated.

---

#### 16.3 — Probability Module Verification

**Effort:** 5h | **File:** `Probability/*.lean` | **Deps:** Phase 8

Audit Phase 8 modules. This is the most challenging verification because
probability reasoning interacts with Mathlib's measure theory stack:

- Verify `uniformPMF` and `probEvent` type-check
- Verify negligible function closure lemmas compile
- Verify `advantage_triangle` (hybrid argument) compiles
- Audit any `sorry` placeholders and document them

**Known `sorry` candidates:**
- `comp_oia_implies_1cpa` may have `sorry` if PMF API is incomplete
- `multi_query_skeleton` has intentional `sorry` (HSP formalization is out of scope)

**Exit criteria:** All non-`sorry` theorems compile. Every `sorry` is
documented with: (a) what it represents, (b) what would be needed to
fill it, (c) whether it affects the soundness of other results.

---

#### 16.4 — Sorry Audit

**Effort:** 3h | **File:** All new `.lean` files | **Deps:** 16.1–16.3

Comprehensive `sorry` audit across all new modules:

```bash
grep -rn "sorry" Orbcrypt/ --include="*.lean"
```

For each `sorry` found:
1. Classify: is it (a) a proof obligation that should be filled,
   (b) an intentional placeholder for out-of-scope work, or
   (c) an accidental leftover?
2. For type (a): fill it or create a tracking issue.
3. For type (b): ensure it is documented in the module docstring.
4. For type (c): fix it immediately.

**Exit criteria:** Zero type-(a) or type-(c) `sorry`s remain. All type-(b)
`sorry`s are documented.

---

#### 16.5 — Axiom Audit

**Effort:** 2h | **File:** All new `.lean` files | **Deps:** 16.1–16.3

Run `#print axioms` on every public theorem in the new modules:

```lean
#print axioms kem_correctness
#print axioms kemoia_implies_secure
#print axioms aead_correctness
#print axioms hybrid_correctness
#print axioms comp_oia_implies_1cpa
```

Verify that:
- No `sorryAx` appears (would indicate hidden `sorry` in dependencies)
- No custom axioms beyond Lean's standard three (`propext`,
  `Classical.choice`, `Quot.sound`)
- OIA/CompOIA appears only as hypotheses, never as axioms

**Exit criteria:** Axiom transparency report updated in `Orbcrypt.lean`
covering all new modules.

---

#### 16.6 — Module Docstring Audit

**Effort:** 3h | **File:** All new `.lean` files | **Deps:** 16.1–16.3

Ensure every new `.lean` file has:
- A `/-! ... -/` module docstring with: purpose, main definitions/results,
  design decisions, references
- Every public `def`, `theorem`, `structure`, `instance`, and `abbrev`
  has a `/-- ... -/` docstring
- Proof strategy comments on every proof longer than 3 lines

**Exit criteria:** Docstring coverage matches Phase 6 standards.

---

#### 16.7 — Dependency Graph Update

**Effort:** 3h | **File:** `Orbcrypt.lean` | **Deps:** 16.1–16.3

Update the root import file and dependency graph to include all new modules:

```lean
-- New imports (Phases 7-10)
import Orbcrypt.KEM.Syntax
import Orbcrypt.KEM.Encapsulate
import Orbcrypt.KEM.Correctness
import Orbcrypt.KEM.Security
import Orbcrypt.Probability.Monad
import Orbcrypt.Probability.Negligible
import Orbcrypt.Probability.Advantage
import Orbcrypt.Crypto.CompOIA
import Orbcrypt.Crypto.CompSecurity
import Orbcrypt.KeyMgmt.SeedKey
import Orbcrypt.KeyMgmt.Nonce
import Orbcrypt.AEAD.MAC
import Orbcrypt.AEAD.AEAD
import Orbcrypt.AEAD.Modes
-- Phase 12-13 (conditional on completion)
import Orbcrypt.Hardness.CodeEquivalence
import Orbcrypt.Hardness.TensorAction
import Orbcrypt.Hardness.Reductions
import Orbcrypt.PublicKey.ObliviousSampling
import Orbcrypt.PublicKey.CommutativeAction
import Orbcrypt.Optimization.TwoPhaseDecrypt
```

Update the ASCII dependency graph in the module docstring.

**Exit criteria:** `lake build Orbcrypt` succeeds with all new imports.

---

#### 16.8 — CI Update

**Effort:** 3h | **File:** `.github/workflows/lean4-build.yml` | **Deps:** 16.7

Update the CI configuration to:
- Build all new modules
- Check for `sorry` (with explicit allowlist for Phase 8 placeholders)
- Check for custom axioms
- Run `#print axioms` on headline theorems

**Exit criteria:** CI passes on the branch with all new modules.

---

#### 16.9 — Regression Testing

**Effort:** 3h | **File:** All `.lean` files | **Deps:** 16.7

Verify that Phases 1–6 are not broken by the new additions:

```bash
# Build all original modules individually
lake build Orbcrypt.GroupAction.Basic
lake build Orbcrypt.GroupAction.Canonical
lake build Orbcrypt.GroupAction.Invariant
lake build Orbcrypt.Crypto.Scheme
lake build Orbcrypt.Crypto.Security
lake build Orbcrypt.Crypto.OIA
lake build Orbcrypt.Theorems.Correctness
lake build Orbcrypt.Theorems.InvariantAttack
lake build Orbcrypt.Theorems.OIAImpliesCPA
lake build Orbcrypt.Construction.Permutation
lake build Orbcrypt.Construction.HGOE
```

Verify that the original three headline theorems still have the same
axiom dependencies:

```lean
#print axioms Orbcrypt.correctness         -- propext, Classical.choice, Quot.sound
#print axioms Orbcrypt.invariant_attack    -- propext
#print axioms Orbcrypt.oia_implies_1cpa    -- (empty)
```

**Exit criteria:** All 11 original modules build. All original axiom
dependencies are unchanged.

---

#### 16.10 — Final Verification Report

**Effort:** 6h | **File:** `docs/VERIFICATION_REPORT.md` | **Deps:** 16.1–16.9

Write a comprehensive verification report covering:

1. **Summary statistics:**
   - Total .lean files (original + new)
   - Total lines of code
   - Total theorems/lemmas
   - Total `sorry` count (with justification for each)
   - Total custom axiom count (should be zero)

2. **Theorem inventory:** Every public theorem, its file, its axiom
   dependencies, and whether it has any `sorry` in its dependency chain.

3. **Headline results update:** The original three plus new headline results:
   - `kem_correctness` — KEM decapsulation recovers key
   - `aead_correctness` — AEAD decryption recovers key on honest inputs
   - `hybrid_correctness` — KEM+DEM composition is correct
   - `kemoia_implies_secure` — KEM-OIA implies KEM security
   - (conditional) `comp_oia_implies_1cpa` — probabilistic security

4. **Known limitations:** Explicitly list what is NOT verified and why.

**Exit criteria:** Report is complete and internally consistent.

---

### Phase 16 Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 16.1 | KEM Verification | `KEM/*.lean` | 4h | Phase 7 |
| 16.2 | AEAD Verification | `AEAD/*.lean` | 4h | Phase 10 |
| 16.3 | Probability Verification | `Probability/*.lean` | 5h | Phase 8 |
| 16.4 | Sorry Audit | All new `.lean` | 3h | 16.1–16.3 |
| 16.5 | Axiom Audit | All new `.lean` | 2h | 16.1–16.3 |
| 16.6 | Docstring Audit | All new `.lean` | 3h | 16.1–16.3 |
| 16.7 | Dependency Graph Update | `Orbcrypt.lean` | 3h | 16.1–16.3 |
| 16.8 | CI Update | `.github/workflows/` | 3h | 16.7 |
| 16.9 | Regression Testing | All `.lean` | 3h | 16.7 |
| 16.10 | Final Verification Report | `docs/VERIFICATION_REPORT.md` | 6h | 16.1–16.9 |

---

## Cross-Cutting Concerns

### Naming Conventions for New Modules

All new modules follow the conventions established in CLAUDE.md Section
"Key conventions":

- **Theorems:** `snake_case` (e.g., `kem_correctness`, `aead_correctness`)
- **Structures:** `CamelCase` (e.g., `OrbitKEM`, `AuthOrbitKEM`, `SeedKey`)
- **Type variables:** Capital letters by role — `G` (groups), `X` (spaces),
  `K` (keys), `Tag` (authentication tags)
- **Hypothesis names:** `h`-prefixed (e.g., `hOIA`, `hDecomp`, `hClosed`)
- **Module paths:** `Orbcrypt.KEM.Syntax`, `Orbcrypt.AEAD.MAC`, etc.

### Import Discipline for New Modules

New modules import by full path within the project:
```lean
import Orbcrypt.KEM.Syntax
import Orbcrypt.Probability.Monad
```

They do NOT import `Mathlib` wholesale. Each file imports only the specific
Mathlib modules needed.

### Build Verification Rule

Before committing ANY new `.lean` file, verify with:
```bash
source ~/.elan/env && lake build Orbcrypt.<Module.Path>
```

The default `lake build` target is NOT sufficient — see CLAUDE.md for details.

### Commit Convention

Commits reference work unit numbers:
```
7.3: Prove KEM correctness theorem
11.5: Add benchmark harness for GAP prototype
```

All commits must pass `lake build` for affected modules.

### Documentation Rule

When changing behavior or adding modules, update (in the same PR):
1. `DEVELOPMENT.md` — if scheme design changes
2. `CLAUDE.md` — if module structure or development guidance changes
3. `Orbcrypt.lean` — if new modules are added (dependency graph, imports)
4. `formalization/FORMALIZATION_PLAN.md` — if architecture changes
5. This document — if work unit status changes

---

## Dependency Graph & Parallelism

### Phase Dependencies

```
Phase 7 (KEM)          Phase 8 (Probability)
    │                       │
    ├───────────┐          │
    ▼           ▼          ▼
Phase 9       Phase 11   Phase 12
(Key/Nonce)   (GAP)      (Hardness)
    │           │           │
    ▼           │          ▼
Phase 10       │       Phase 13
(AEAD)         │       (Public Key)
    │           │
    │           ▼
    │       Phase 14
    │       (Params)
    │           │
    │           ▼
    │       Phase 15
    │       (Decrypt Opt)
    │           │
    ▼           ▼
    Phase 16 (Verification)
```

### Maximum Parallelism Schedule

**Wave 1 (Weeks 17–22):** Phases 7 and 8 in parallel.
- Phase 7: KEM reformulation (Lean)
- Phase 8: Probabilistic foundations (Lean)

**Wave 2 (Weeks 20–26):** Phases 9, 11, 12 in parallel (after Phase 7 or 8).
- Phase 9: Key compression (Lean, depends on Phase 7)
- Phase 11: GAP prototype (implementation, depends on Phase 7)
- Phase 12: Hardness alignment (Lean + docs, depends on Phase 8)

**Wave 3 (Weeks 22–30):** Phases 10, 13, 14 in parallel.
- Phase 10: AEAD (Lean, depends on Phase 9)
- Phase 13: Public-key extension (Lean, depends on Phases 7 + 12)
- Phase 14: Parameters (docs, depends on Phase 11)

**Wave 4 (Weeks 30–34):** Phase 15 (depends on Phases 11 + 14).
- Phase 15: Decryption optimization (GAP + Lean)

**Wave 5 (Weeks 30–36):** Phase 16 overlaps with Wave 4.
- Phase 16: Formal verification of all new components

### Estimated Calendar

With a single engineer at 10 hours/week:

| Month | Weeks | Phases | Cumulative Hours |
|-------|-------|--------|-----------------|
| 1 | 17–20 | 7, 8 (parallel) | ~64h |
| 2 | 21–24 | 9, 11, 12 (parallel) | ~150h |
| 3 | 25–28 | 10, 13, 14 (parallel) | ~214h |
| 4 | 29–32 | 15, 16 (parallel) | ~272h |

**Total wall-clock time:** ~4 months at 10h/week, or ~7 months at 5h/week.

---

## Risk Analysis

### High-Risk Items

| Risk | Phase | Impact | Probability | Mitigation |
|------|-------|--------|-------------|------------|
| Mathlib PMF API inadequate | 8 | Blocks probabilistic OIA | Medium | Fall back to ConcreteOIA (finite enumeration) |
| GAP `images` package too slow for n>500 | 11, 15 | Benchmarks show impractical decryption | Medium | Use nauty/Traces for canonical labeling; consider C++ reimplementation |
| QC code PAut sometimes too small | 11 | Key generation fails validation | Low | Rejection sample; increase b or ell |
| Tensor action proofs too complex | 12 | Phase 12 Track B stalls | Medium | Defer tensor work; focus on CE alignment |
| Two-phase decryption speedup insufficient | 15 | Core practical improvement fails | Medium | Fall back to syndrome-based or orbit hash approaches |
| Lean build times exceed CI timeout | 16 | CI fails on new modules | Low | Increase timeout; add module-level caching |

### Medium-Risk Items

| Risk | Phase | Impact | Probability | Mitigation |
|------|-------|--------|-------------|------------|
| Commutative action OIA is trivially broken | 13 | Public-key extension infeasible | High | Document as open problem; focus on symmetric-key KEM |
| Oblivious sampling has no good `combine` op | 13 | Oblivious sampling infeasible | High | Document as open problem; pivot to KEM key agreement |
| Benchmarks show Orbcrypt non-competitive | 14 | Project viability questioned | Medium | Focus on theoretical contributions (formal verification, invariant attack theorem) |
| Nonce-misuse leaks orbit membership | 9 | Security degradation under nonce reuse | Low | Document clearly; recommend against nonce reuse across base points |

### Low-Risk Items

| Risk | Phase | Impact | Probability | Mitigation |
|------|-------|--------|-------------|------------|
| New modules break existing proofs | 16 | Regression | Very Low | New modules are additive (no modification of existing files) |
| MAC correctness field causes Lean issues | 10 | Minor type-checking difficulty | Low | Use a separate proof term |

### Go/No-Go Decision Points

After certain phases, the project should evaluate whether to continue:

1. **After Phase 11 (benchmarks):** If decryption takes > 1 second at
   lambda=128, the scheme is not competitive for any real-time application.
   Decision: continue with theoretical contributions only, or pivot to
   decryption optimization (Phase 15) before proceeding.

2. **After Phase 14 (parameters):** If ciphertext expansion exceeds 100x
   compared to AES-GCM for typical message sizes, the scheme is only
   viable as a KEM (not for bulk encryption). Decision: narrow scope to
   KEM-only operation.

3. **After Phase 8 (probabilistic OIA):** If the probabilistic OIA cannot
   be stated in a satisfiable way within Lean, the theoretical improvement
   over Phases 1–6 is minimal. Decision: publish with deterministic
   formalization and note the probabilistic gap as future work.

---

## Document Update Checklist

When a phase is completed, update the following:

| Document | What to Update |
|----------|---------------|
| `CLAUDE.md` | Active development status, module layout, source layout, key conventions |
| `DEVELOPMENT.md` | Sections 6 (construction), 8 (security), 10 (future work) if applicable |
| `formalization/FORMALIZATION_PLAN.md` | Module overview, project architecture if new modules added |
| `Orbcrypt.lean` | Import list, dependency graph, axiom transparency report |
| `README.md` | Project status, feature list |
| This document | Mark work units as complete, update effort actuals |
| `.github/workflows/lean4-build.yml` | Add new modules to build/check targets |

---

## Success Criteria

### Minimum Viable Outcome (Phases 7 + 11 + 14)

The project succeeds at a minimum level if:

- [ ] KEM reformulation is formalized with proven correctness in Lean 4
- [ ] GAP prototype produces valid benchmarks for lambda=128
- [ ] Parameter table is published with honest comparison to existing schemes
- [ ] The project has a clear answer to "how fast is Orbcrypt?"

### Target Outcome (+ Phases 8 + 9 + 10 + 16)

The project achieves its target if additionally:

- [ ] Probabilistic OIA is formalized (even if some lemmas use `sorry`)
- [ ] Key size is reduced to 256-bit seed
- [ ] Authenticated encryption mode is defined and proven correct
- [ ] Formal verification report covers all new components
- [ ] `lake build Orbcrypt` succeeds with zero warnings

### Stretch Outcome (+ Phases 12 + 13 + 15)

The project exceeds expectations if additionally:

- [ ] CE-OIA is formally connected to LESS/MEDS hardness assumptions
- [ ] Tensor isomorphism OIA is defined (even if partially formalized)
- [ ] Public-key extension feasibility is thoroughly analyzed
- [ ] Decryption is optimized with measured speedup over baseline
- [ ] The project is publishable at a formal methods or crypto venue

### Non-Goals

- Competing with AES on symmetric-key performance (unrealistic)
- Standardization submission to NIST (premature)
- Production deployment (this is a research prototype)
- Complete formalization of probabilistic/computational complexity
  aspects (requires years of foundational work beyond this project)

---

## Appendix: New File Inventory

### Lean 4 Modules (Phases 7–10, 12–13, 15–16)

```
Orbcrypt/
  KEM/
    Syntax.lean              — OrbitKEM structure, backward compatibility
    Encapsulate.lean         — encaps, decaps functions
    Correctness.lean         — KEM correctness theorem
    Security.lean            — KEM security game, KEM-OIA, security theorem
  Probability/
    Monad.lean               — PMF wrapper, uniform distribution
    Negligible.lean          — Negligible function definition and closure
    Advantage.lean           — Distinguishing advantage, hybrid argument
  Crypto/
    CompOIA.lean             — Probabilistic OIA, orbit distribution
    CompSecurity.lean        — Probabilistic IND-CPA, security theorem
  KeyMgmt/
    SeedKey.lean             — Seed-based key, QC expansion spec
    Nonce.lean               — Nonce-based encryption
  AEAD/
    MAC.lean                 — MAC abstraction
    AEAD.lean                — Authenticated KEM, INT-CTXT
    Modes.lean               — KEM+DEM composition, hybrid encryption
  Hardness/
    CodeEquivalence.lean     — CE problem, PAut recovery
    TensorAction.lean        — Tensor group action, TI problem
    Reductions.lean          — Reduction chain, Tensor-OIA
  PublicKey/
    ObliviousSampling.lean   — Randomizer-based sampling
    KEMAgreement.lean        — Two-party key agreement
    CommutativeAction.lean   — CSIDH-style commutative action
  Optimization/
    TwoPhaseDecrypt.lean     — Two-phase decryption specification
```

**Total new Lean files:** 21
**Estimated new lines of Lean code:** ~3,000–4,000

### GAP Implementation Files (Phases 11, 14, 15)

```
implementation/
  gap/
    orbcrypt_keygen.g        — Key generation
    orbcrypt_kem.g           — KEM enc/dec
    orbcrypt_bench.g         — Benchmarks
    orbcrypt_test.g          — Correctness tests
    orbcrypt_params.g        — Parameter generation
    orbcrypt_fast_dec.g      — Optimized decryption
    README.md                — Installation and usage
```

**Total new GAP files:** 6 + README

### Documentation (Phases 12–14, 16)

```
docs/
  HARDNESS_ANALYSIS.md       — Hardness comparison
  PUBLIC_KEY_ANALYSIS.md     — Public-key feasibility
  PARAMETERS.md              — Parameter recommendations
  VERIFICATION_REPORT.md     — Formal verification report
  benchmarks/
    results_*.csv            — Benchmark data
    comparison.csv           — Cross-scheme comparison
```

**Total new documents:** 4 + CSV data files
