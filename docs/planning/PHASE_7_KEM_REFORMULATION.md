<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Phase 7 — KEM Reformulation

## Weeks 17–19 | 8 Work Units | ~24 Hours

*Part of the [Orbcrypt Practical Improvements Plan](../../formalization/PRACTICAL_IMPROVEMENTS_PLAN.md)*

> **Note (2026-04-22, Workstream L5):** Work Unit 7.6a's original
> `kem_key_constant` theorem (which extracted the second conjunct of
> `KEMOIA`) was deleted by Workstream L5 (audit
> F-AUDIT-2026-04-21-M6). The extraction was redundant because the
> key-constancy fact is provable unconditionally from
> `canonical_isGInvariant`, and `KEMOIA` is now single-conjunct
> (orbit indistinguishability only). The authoritative key-constancy
> lemma is `kem_key_constant_direct`. See `CLAUDE.md`'s Workstream L
> snapshot for the full rationale. This planning doc is retained as
> a point-in-time record of the original Phase 7 design.

---

## Overview

Phase 7 redefines Orbcrypt as a Key Encapsulation Mechanism (KEM) rather than
a direct encryption scheme. This is the single highest-leverage architectural
change: it eliminates the message-space representation problem, fits the
standard hybrid encryption paradigm (KEM + DEM), and simplifies the security
claim to "the KEM output is pseudorandom under OIA."

**Rationale:** The current scheme requires storing |M| orbit representatives
as public parameters. For |M| = 2^128, this is infeasible. A KEM sidesteps
this entirely: the encapsulation produces a random orbit element, and a
symmetric key is derived from it via a hash. The actual message encryption
is delegated to a standard DEM (e.g., AES-GCM).

---

## Objectives

1. Define the `OrbitKEM` structure with a single base point and key derivation.
2. Implement `encaps` and `decaps` functions.
3. Prove KEM correctness: `decaps(encaps(g)) recovers the shared key`.
4. Define KEM security game (IND-CCA style, deterministic formulation).
5. Define KEM-OIA and prove it implies KEM security.
6. Provide backward compatibility bridge from `OrbitEncScheme` to `OrbitKEM`.
7. Instantiate HGOE-KEM for the concrete bitstring construction.

---

## Prerequisites

- Phase 2 complete (`CanonicalForm` structure)
- Phase 3 complete (`OrbitEncScheme` for backward compatibility bridge)
- Phase 4 complete (`canonical_isGInvariant` for correctness proof)
- Phase 5 complete (HGOE construction for concrete instantiation)

---

## New Files

```
Orbcrypt/
  KEM/
    Syntax.lean          — OrbitKEM structure definition
    Encapsulate.lean     — encaps and decaps functions
    Correctness.lean     — decaps(encaps()) recovers the key
    Security.lean        — IND-CCA KEM security definition, KEM-OIA, security theorem
  Construction/
    HGOEKEM.lean         — Concrete HGOE-KEM instantiation
```

**Dependency on existing code:** Builds on `GroupAction/`, `Crypto/Scheme.lean`
(reuses `CanonicalForm`), and `Construction/Permutation.lean`. Does NOT modify
existing files — purely additive.

---

## Work Units

### Track A: Syntax and Correctness (7.1 → 7.2 → 7.3)

Track A builds the KEM data type and proves correctness. It depends only on
Phase 2 (CanonicalForm) and Phase 4 (G-invariance).

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
- **No `reps_distinct` field** — there is only one orbit, so distinctness
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

**Exit criteria:** Both functions type-check; `lake build Orbcrypt.KEM.Encapsulate` succeeds.

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

### Track B: Security (7.4 → 7.5 → 7.6)

Track B defines the KEM security game and proves security from KEM-OIA.
It depends only on 7.1 (OrbitKEM structure).

---

#### 7.4 — KEM Security Definition (IND-CCA)

**Effort:** 4h | **File:** `KEM/Security.lean` | **Deps:** 7.1

Define the IND-CCA security game for KEMs.

**Sub-tasks:**

**7.4a — KEMAdversary structure (1h).** Define the adversary type:

```lean
structure KEMAdversary (X : Type*) (K : Type*) where
  guess : X → X → K → Bool
  -- Args: basePoint, ciphertext, candidate key
```

Exit: structure type-checks.

**7.4b — kemHasAdvantage definition (1.5h).** Define advantage as
distinguishability between real and random keys:

```lean
def kemHasAdvantage (kem : OrbitKEM G X K) (A : KEMAdversary X K) : Prop :=
  ∃ g : G, ∃ k_random : K,
    A.guess kem.basePoint (g • kem.basePoint)
      (kem.keyDerive (kem.canonForm.canon (g • kem.basePoint))) ≠
    A.guess kem.basePoint (g • kem.basePoint) k_random
```

Exit: definition type-checks. Verify the existential correctly captures
"there exists a scenario where the adversary's guess differs."

**7.4c — KEMIsSecure definition and unfolding lemma (1.5h).**

```lean
def KEMIsSecure (kem : OrbitKEM G X K) : Prop :=
  ∀ (A : KEMAdversary X K), ¬ kemHasAdvantage kem A

theorem kemIsSecure_iff (kem : OrbitKEM G X K) :
    KEMIsSecure kem ↔
    ∀ (A : KEMAdversary X K) (g : G) (k_random : K),
      A.guess kem.basePoint (g • kem.basePoint)
        (kem.keyDerive (kem.canonForm.canon (g • kem.basePoint))) =
      A.guess kem.basePoint (g • kem.basePoint) k_random
```

Exit: definition and iff-lemma both compile.

**Design note:** This is a deterministic formulation. The random key
`k_random` is existentially quantified rather than sampled from a distribution.
Phase 8 upgrades this to a probabilistic model.

**Exit criteria:** All three sub-tasks pass `lake build`.

---

#### 7.5 — KEM-OIA Definition

**Effort:** 3h | **File:** `KEM/Security.lean` | **Deps:** 7.4

Define the KEM variant of OIA. Simpler than the encryption OIA because
there is only one orbit:

```lean
/-- KEM-OIA: no Boolean function can distinguish orbit elements,
    AND the key derivation function is orbit-collapsing. -/
def KEMOIA (kem : OrbitKEM G X K) : Prop :=
  (∀ (f : X → Bool) (g₀ g₁ : G),
    f (g₀ • kem.basePoint) = f (g₁ • kem.basePoint)) ∧
  (∀ (g : G), kem.keyDerive (kem.canonForm.canon (g • kem.basePoint)) =
    kem.keyDerive (kem.canonForm.canon kem.basePoint))
```

**The two conjuncts:**

1. **Orbit indistinguishability:** No function distinguishes orbit elements.
2. **Key uniformity:** The derived key is the same for all orbit elements.
   This follows from canonical form G-invariance + deterministic `keyDerive`,
   so the second conjunct is actually provable from `canonical_isGInvariant`
   (defined in `GroupAction/Invariant.lean`, line 146). That theorem has type
   `IsGInvariant (G := G) can.canon`, i.e., `∀ g x, can.canon (g • x) = can.canon x`.
   The KEM module must import `Orbcrypt.GroupAction.Invariant` to access it.

Prove the second conjunct as a standalone lemma:

```lean
theorem kemoia_key_uniform (kem : OrbitKEM G X K) (g : G) :
    kem.keyDerive (kem.canonForm.canon (g • kem.basePoint)) =
    kem.keyDerive (kem.canonForm.canon kem.basePoint) := by
  congr 1
  exact canonical_isGInvariant kem.canonForm g kem.basePoint
```

**Exit criteria:** Definition type-checks. `kemoia_key_uniform` compiles.

---

#### 7.6 — KEM Security Theorem

**Effort:** 4h | **File:** `KEM/Security.lean` | **Deps:** 7.4, 7.5

Prove: KEM-OIA implies KEM security.

**Sub-tasks:**

**7.6a — Key constancy lemma (1.5h).** Prove:

```lean
theorem kem_key_constant (kem : OrbitKEM G X K) (hOIA : KEMOIA kem) (g : G) :
    kem.keyDerive (kem.canonForm.canon (g • kem.basePoint)) =
    kem.keyDerive (kem.canonForm.canon kem.basePoint) :=
  hOIA.2 g
```

Exit: lemma compiles.

**7.6b — Ciphertext indistinguishability lemma (1h).** Prove:

```lean
theorem kem_ciphertext_indistinguishable (kem : OrbitKEM G X K)
    (hOIA : KEMOIA kem) (f : X → Bool) (g₀ g₁ : G) :
    f (g₀ • kem.basePoint) = f (g₁ • kem.basePoint) :=
  hOIA.1 f g₀ g₁
```

Exit: lemma compiles.

**7.6c — Main security theorem assembly (1.5h).** Combine:

```lean
theorem kemoia_implies_secure (kem : OrbitKEM G X K)
    (hOIA : KEMOIA kem) : KEMIsSecure kem
```

Proof strategy:
1. Introduce adversary A, assume `kemHasAdvantage kem A`.
2. Destructure to get `g`, `k_random`, and the inequality.
3. Apply `kem_key_constant`: the real key is a fixed value for all g.
4. Apply `kem_ciphertext_indistinguishable`: the adversary's guess is
   constant across group elements on the ciphertext.
5. Derive contradiction.

Exit: theorem compiles with zero `sorry`.

**Exit criteria:** All three sub-tasks pass `lake build`.

---

### Track C: Bridges and Instantiation (7.7 → 7.8)

Track C connects the KEM to the existing codebase. It depends on both
Track A and Track B.

---

#### 7.7 — Backward Compatibility: OrbitEncScheme → OrbitKEM

**Effort:** 3h | **File:** `KEM/Syntax.lean` | **Deps:** 7.1, Phase 3

Provide a bridge construction showing that any `OrbitEncScheme` can be
converted to an `OrbitKEM` by fixing one message and using its representative
as the base point:

```lean
/-- Convert an OrbitEncScheme to an OrbitKEM by fixing a message m₀. -/
def OrbitEncScheme.toKEM (scheme : OrbitEncScheme G X M)
    (m₀ : M) (kd : X → K) : OrbitKEM G X K where
  basePoint := scheme.reps m₀
  canonForm := scheme.canonForm
  keyDerive := kd
```

Also prove that KEM correctness follows from the bridge:

```lean
theorem toKEM_correct (scheme : OrbitEncScheme G X M)
    (m₀ : M) (kd : X → K) (g : G) :
    decaps (scheme.toKEM m₀ kd) (encaps (scheme.toKEM m₀ kd) g).1 =
    (encaps (scheme.toKEM m₀ kd) g).2 :=
  kem_correctness (scheme.toKEM m₀ kd) g
```

**Exit criteria:** Bridge function and theorem compile.

---

#### 7.8 — HGOE-KEM Instantiation

**Effort:** 3h | **File:** `Construction/HGOEKEM.lean` | **Deps:** 7.7, Phase 5

Instantiate the KEM for the concrete HGOE construction (subgroup of S_n on
bitstrings), producing an `OrbitKEM` with:

- `basePoint` = a fixed weight-w bitstring
- `canonForm` = inherited from HGOE
- `keyDerive` = abstract hash function placeholder

```lean
/-- Concrete HGOE-KEM for subgroup of S_n acting on bitstrings. -/
def hgoeKEM {n : ℕ}
    (G : Subgroup (Equiv.Perm (Fin n)))
    (can : CanonicalForm (↥G) (Bitstring n))
    (basePoint : Bitstring n)
    (kd : Bitstring n → K) : OrbitKEM (↥G) (Bitstring n) K where
  basePoint := basePoint
  canonForm := can
  keyDerive := kd

/-- HGOE-KEM correctness: direct application of kem_correctness. -/
theorem hgoe_kem_correctness {n : ℕ}
    (G : Subgroup (Equiv.Perm (Fin n)))
    (kem : OrbitKEM (↥G) (Bitstring n) K)
    (g : ↥G) :
    decaps kem (encaps kem g).1 = (encaps kem g).2 :=
  kem_correctness kem g
```

**Exit criteria:** Concrete KEM type-checks; correctness compiles.
`lake build` succeeds for all new modules.

---

## Internal Dependency Graph

```
                7.1 (OrbitKEM Structure)
               /          |            \
              /            |             \
         7.2 (encaps)   7.4 (Security)  7.7 (Bridge)
           |               |               |
         7.3 (Correct)  7.5 (KEM-OIA)     |
                           |               |
                        7.6 (Secure)       |
                              \           /
                               7.8 (HGOE-KEM)
```

**Critical path:** 7.1 → 7.4 → 7.5 → 7.6 (12h)

---

## Parallelism Notes

- **Track A** (7.1 → 7.2 → 7.3) and **Track B** (7.1 → 7.4 → 7.5 → 7.6)
  can proceed in parallel once 7.1 is complete.
- **Track C** (7.7 → 7.8) depends on 7.1 only for the structure definition;
  it can start as soon as 7.1 is done.
- Maximum parallelism: 3 tracks simultaneously after 7.1.

---

## Risk Analysis

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| `encaps`/`decaps` not definitionally equal | Low | Medium | Use `simp` or `unfold` to expose equality |
| `kemIsSecure_iff` requires non-trivial push/pull of negation | Low | Low | Use `push_neg` tactic |
| `toKEM` bridge has universe issues | Low | Medium | Use explicit universe annotations |

---

## Phase Exit Criteria

1. `lake build Orbcrypt.KEM.Syntax` succeeds with zero warnings.
2. `lake build Orbcrypt.KEM.Encapsulate` succeeds with zero warnings.
3. `lake build Orbcrypt.KEM.Correctness` succeeds with zero warnings.
4. `lake build Orbcrypt.KEM.Security` succeeds with zero warnings.
5. `lake build Orbcrypt.Construction.HGOEKEM` succeeds with zero warnings.
6. `kem_correctness` has zero `sorry` and zero custom axioms.
7. `kemoia_implies_secure` has zero `sorry` and zero custom axioms.
8. `#print axioms kem_correctness` shows only standard Lean axioms.
9. `#print axioms kemoia_implies_secure` shows only standard Lean axioms.

---

## Summary

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
