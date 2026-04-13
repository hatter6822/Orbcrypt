# Phase 3 — Cryptographic Definitions

## Weeks 5–6 | 11 Work Units | ~21 Hours

*Part of the [Orbcrypt Lean 4 Formalization Plan](../FORMALIZATION_PLAN.md)*

---

## Overview

Phase 3 defines the cryptographic layer: the abstract orbit encryption scheme,
the adversary model, and the OIA axiom. A critical addition is the
**pre-validation sprint** (unit 3.9) — a risk-reduction step that sketches
Phase 4 proofs before finalizing definitions, ensuring no costly rework.

This phase has **two parallel tracks** after the scheme core (3.1–3.3b):
the security game track (3.4–3.6) and the OIA track (3.7–3.8).

---

## Objectives

1. `OrbitEncScheme` structure with `encrypt` and `decrypt`.
2. Deterministic adversary model and IND-CPA advantage definition.
3. OIA axiom with documentation.
4. **Validated** that all definitions compose correctly for Phase 4 proofs.

---

## Prerequisites

- Phase 2 complete: all `GroupAction/` modules compile without `sorry`.

---

## Work Units

### 3.1 — Scheme Structure

**Effort:** 2h | **Module:** `Crypto/Scheme.lean` | **Deps:** 2.5

```lean
structure OrbitEncScheme (G : Type*) (X : Type*) (M : Type*)
    [Group G] [MulAction G X] [DecidableEq X] where
  reps : M → X
  reps_distinct : ∀ m₁ m₂ : M, m₁ ≠ m₂ →
    MulAction.orbit G (reps m₁) ≠ MulAction.orbit G (reps m₂)
  canonForm : CanonicalForm G X
```

**Sub-steps:**
1. **(1h)** Define the structure with full docstrings for each field.
2. **(1h)** Verify `#check OrbitEncScheme` and field accessors compile.

---

### 3.2 — Encrypt Function

**Effort:** 1h | **Module:** `Crypto/Scheme.lean` | **Deps:** 3.1

```lean
def encrypt [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (g : G) (m : M) : X :=
  g • scheme.reps m
```

One-liner. Verify `#check @encrypt` shows expected type.

---

### 3.3a — Decrypt: Survey Search Mechanisms

**Effort:** 1.5h | **Module:** scratch file | **Deps:** 3.1

**This is risk reduction.** The `decrypt` function must search a finite type
for a matching canonical form. Multiple Mathlib mechanisms exist, and choosing
the wrong one makes the correctness proof (4.3) much harder.

**Evaluate each candidate in a scratch file:**

| Mechanism | API | Correctness Lemma |
|-----------|-----|-------------------|
| `Fintype.choose` | Returns the element satisfying a decidable predicate (must be unique) | `Fintype.choose_spec` |
| `Finset.univ.find?` | Returns `Option` from a decidable predicate on `Finset.univ` | `Finset.find?_some`, `Finset.find?_none` |
| `Fintype.find?` | Similar but on `Fintype` directly | Check if exists in current Mathlib |
| Manual `Finset.univ.filter` | Filter + extract singleton | `Finset.filter_singleton`, `Finset.card_eq_one` |

**For each candidate, test:**
1. Does it compile with `[Fintype M] [DecidableEq M] [DecidableEq X]`?
2. What specification lemma does it provide?
3. How easy is it to prove "returns `some m`" when a unique match exists?

**Output:** Decision on which mechanism to use, documented in a comment.

### 3.3b — Decrypt: Implementation

**Effort:** 2.5h | **Module:** `Crypto/Scheme.lean` | **Deps:** 3.3a

Implement `decrypt` using the mechanism chosen in 3.3a.

**Recommended implementation (using `Finset.univ.find?`):**
```lean
def decrypt [Group G] [MulAction G X] [DecidableEq X]
    [Fintype M] [DecidableEq M]
    (scheme : OrbitEncScheme G X M) (c : X) : Option M :=
  (Finset.univ : Finset M).find?
    (fun m => decide (scheme.canonForm.canon c = scheme.canonForm.canon (scheme.reps m)))
```

**Sub-steps:**
1. **(1h)** Write the definition using the chosen mechanism.
2. **(30m)** Verify it compiles with correct type class constraints.
3. **(1h)** Write and verify the **decrypt specification lemma** that Phase 4
   will consume:
   ```lean
   /-- Key spec lemma: if the predicate holds for exactly one m, decrypt returns it. -/
   theorem decrypt_spec [Group G] [MulAction G X] [DecidableEq X]
       [Fintype M] [DecidableEq M]
       (scheme : OrbitEncScheme G X M) (c : X) (m : M)
       (hMatch : scheme.canonForm.canon c = scheme.canonForm.canon (scheme.reps m))
       (hUnique : ∀ m', scheme.canonForm.canon c = scheme.canonForm.canon (scheme.reps m') → m' = m) :
       decrypt scheme c = some m := by
     sorry  -- Will be proved here or deferred to Phase 4
   ```
   Even if the proof is deferred (`sorry`), stating this lemma validates that
   the `decrypt` implementation has the right shape for the correctness proof.

---

### 3.4 — Adversary Structure

**Effort:** 1.5h | **Module:** `Crypto/Security.lean` | **Deps:** 3.1

```lean
structure Adversary (X : Type*) (M : Type*) where
  choose : (M → X) → M × M
  guess : (M → X) → X → Bool
```

**Sub-steps:**
1. **(45m)** Define the structure with docstrings.
2. **(45m)** Add accessor convenience lemmas:
   ```lean
   def Adversary.chosenM₀ (A : Adversary X M) (reps : M → X) : M :=
     (A.choose reps).1
   def Adversary.chosenM₁ (A : Adversary X M) (reps : M → X) : M :=
     (A.choose reps).2
   ```
   These avoid the `let (m₀, m₁) := ...` pattern that can cause issues in proofs.

---

### 3.5a — Advantage: Definition

**Effort:** 1.5h | **Module:** `Crypto/Security.lean` | **Deps:** 3.4, 3.2

```lean
def hasAdvantage [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) : Prop :=
  ∃ g₀ g₁ : G,
    A.guess scheme.reps (g₀ • scheme.reps (A.chosenM₀ scheme.reps)) ≠
    A.guess scheme.reps (g₁ • scheme.reps (A.chosenM₁ scheme.reps))
```

**Key change from v1:** Use `A.chosenM₀` / `A.chosenM₁` instead of
`let (m₀, m₁) := A.choose scheme.reps`. This avoids `let`-in-`Prop` issues
that were flagged as a risk in the original plan.

### 3.5b — Advantage: Unfold Lemma

**Effort:** 1h | **Module:** `Crypto/Security.lean` | **Deps:** 3.5a

```lean
/-- Unfold hasAdvantage for use in Phase 4 proofs. -/
theorem hasAdvantage_iff [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) :
    hasAdvantage scheme A ↔
    ∃ g₀ g₁ : G,
      A.guess scheme.reps (g₀ • scheme.reps (A.chosenM₀ scheme.reps)) ≠
      A.guess scheme.reps (g₁ • scheme.reps (A.chosenM₁ scheme.reps)) := by
  rfl
```

Even if this is `rfl`, having it as a named lemma ensures Phase 4 can `rw`
cleanly. Also prove the negation form:

```lean
theorem not_hasAdvantage_iff ... :
    ¬ hasAdvantage scheme A ↔
    ∀ g₀ g₁ : G,
      A.guess scheme.reps (g₀ • scheme.reps (A.chosenM₀ scheme.reps)) =
      A.guess scheme.reps (g₁ • scheme.reps (A.chosenM₁ scheme.reps)) := by
  simp [hasAdvantage_iff, not_exists, not_ne_iff]
```

---

### 3.6 — Security Definition

**Effort:** 1h | **Module:** `Crypto/Security.lean` | **Deps:** 3.5a

```lean
def IsSecure [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) : Prop :=
  ∀ (A : Adversary X M), ¬ hasAdvantage scheme A
```

---

### 3.7 — OIA Axiom

**Effort:** 2h | **Module:** `Crypto/OIA.lean` | **Deps:** 3.1

```lean
axiom OIA [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (f : X → Bool) (m₀ m₁ : M) (g : G) :
    ∃ g' : G, f (g • scheme.reps m₀) = f (g' • scheme.reps m₁)
```

**Sub-steps:**
1. **(1h)** State the axiom. Verify `#check @OIA` shows expected signature.
2. **(1h)** Write the justification comment block documenting:
   - Why it's an axiom (computational conjecture)
   - Relationship to probabilistic OIA (deterministic is stronger)
   - What depends on it (only `OIAImpliesCPA.lean`)
   - How to audit (`#print axioms`)

---

### 3.8 — Pre-Validation Sprint (Risk Reduction)

**Effort:** 2.5h | **Module:** scratch file | **Deps:** 3.1–3.7

**This is the most important risk reduction step in the entire plan.**

Before declaring Phase 3 complete, sketch all three Phase 4 headline proofs
in a scratch file with `sorry` at non-trivial steps. This validates that:
1. The `decrypt` implementation composes with `encrypt` correctly.
2. The `hasAdvantage` definition unfolds cleanly in proofs.
3. The OIA axiom is strong enough to prove the security theorem.
4. The OIA axiom is not so strong as to be trivially false.

**Validation 1 — Correctness sketch (30m):**
```lean
-- Verify this proof structure works:
example (scheme : OrbitEncScheme G X M) (m : M) (g : G) :
    decrypt scheme (encrypt scheme g m) = some m := by
  -- Can we unfold encrypt to g • reps m?
  -- Can we apply canon_eq_of_mem_orbit?
  -- Can we use decrypt_spec?
  sorry
```

**Validation 2 — Invariant attack sketch (30m):**
```lean
-- Verify the adversary construction type-checks:
example (f : X → Y) [DecidableEq Y] (m₀ m₁ : M) :
    Adversary X M :=
  { choose := fun _ => (m₀, m₁)
    guess := fun reps c => decide (f c = f (reps m₀)) }
```

**Validation 3 — OIA sketch (45m):**
```lean
-- Verify OIA can be instantiated with the adversary's guess function:
example (scheme : OrbitEncScheme G X M) (A : Adversary X M) (m₀ m₁ : M) (g : G) :
    ∃ g' : G, A.guess scheme.reps (g • scheme.reps m₀) =
              A.guess scheme.reps (g' • scheme.reps m₁) :=
  OIA scheme (A.guess scheme.reps) m₀ m₁ g
```

**Validation 4 — OIA consistency check (45m):**
Construct a toy model where the OIA holds to verify it's not trivially false:
```lean
-- Trivial model: one-element group, one-element space
-- G = Unit, X = Bool, M = Unit
-- OIA should hold vacuously (only one orbit)
```

**If any validation fails:** Revise the affected definition (decrypt, hasAdvantage,
or OIA) before proceeding. This is why the sprint exists — catching definition
mismatches in Phase 3 costs hours; catching them in Phase 4 costs days.

---

## Parallel Execution Plan

```
    3.1 Scheme → 3.2 Encrypt → 3.3a Survey → 3.3b Decrypt
                                                  │
                          ┌───────────────────────┤
                          ▼                       ▼
                 Track A: Security         Track B: OIA
                 ┌──────────────┐         ┌──────────────┐
                 │ 3.4 Adversary │         │ 3.7 OIA Axiom│
                 │ 3.5a Adv def  │         └──────────────┘
                 │ 3.5b Unfold   │                │
                 │ 3.6 IsSecure  │                │
                 └──────────────┘                │
                          │                       │
                          └───────────┬───────────┘
                                      ▼
                            3.8 Pre-Validation Sprint
```

---

## Risk Analysis

| Risk | Units | Likelihood | Impact | Mitigation |
|------|-------|-----------|--------|------------|
| `decrypt` mechanism has weak spec lemmas | 3.3a/b | High | High | 3.3a surveys all options first; 3.3b includes spec lemma |
| OIA too strong or too weak | 3.7 | Medium | Critical | 3.8 validates with sketch proofs and toy model |
| `let` pattern in `hasAdvantage` causes issues | 3.5a | Medium | Medium | Use explicit `chosenM₀`/`chosenM₁` accessors |
| `Adversary.guess` type doesn't compose with OIA | 3.4 | Low | High | 3.8 validates composition explicitly |
| `DecidableEq` missing for canonical form comparison | 3.3b | Low | Low | Already required on `X` in `OrbitEncScheme` |

---

## Exit Criteria

- [ ] `Crypto/Scheme.lean` compiles without `sorry` (except `decrypt_spec` if deferred)
- [ ] `Crypto/Security.lean` compiles without `sorry`
- [ ] `Crypto/OIA.lean` compiles with only the `OIA` axiom
- [ ] `lake build` succeeds with zero errors
- [ ] Pre-validation sprint (3.8) confirms all Phase 4 proof sketches type-check
- [ ] `not_hasAdvantage_iff` provides clean negation form
- [ ] OIA consistency verified with toy model

---

## Transition to Phase 4

With definitions validated by the pre-validation sprint, Phase 4 fills in the
`sorry` gaps in the headline proofs with confidence that no definitional
rework is needed.

See: [Phase 4 — Core Theorems](PHASE_4_CORE_THEOREMS.md)
