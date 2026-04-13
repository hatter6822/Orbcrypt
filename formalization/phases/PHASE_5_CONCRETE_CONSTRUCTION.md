# Phase 5 — Concrete Construction

## Weeks 11–14 | 8 Work Units | ~28 Hours

*Part of the [Orbcrypt Lean 4 Formalization Plan](../FORMALIZATION_PLAN.md)*

---

## Overview

Phase 5 bridges theory and practice by instantiating the abstract orbit
encryption framework with the concrete symmetric group S\_n acting on
bitstrings {0,1}^n. It produces a working `OrbitEncScheme` instance and
formally proves that the Hamming weight defense from DEVELOPMENT.md §7.1
defeats the primary attack vector from COUNTEREXAMPLE.md.

**Parallelism note:** Units 5.1–5.4 (Permutation.lean) depend only on Phase 2
and can begin as soon as Phase 2 completes — potentially running in parallel
with Phases 3 and 4. Units 5.5–5.8 (HGOE.lean) require Phase 4 theorems.

---

## Objectives

1. A `Bitstring n` type with a verified `MulAction` instance for S\_n.
2. Proof that Hamming weight is a G-invariant function for any G ≤ S\_n.
3. A concrete `OrbitEncScheme` instance for the Hidden-Group construction.
4. Formal proof that same-weight representatives neutralize the Hamming weight
   attack.

---

## Prerequisites

- Phase 2 complete (for units 5.1–5.4).
- Phase 4 complete (for units 5.5–5.8).

---

## Work Units

### 5.1 — Bitstring Type

**Effort:** 2h | **Module:** `Construction/Permutation.lean` | **Deps:** Phase 1

```lean
import Mathlib.GroupTheory.Perm.Basic
import Mathlib.Data.Fintype.Basic

/-- A bitstring of length n, represented as a function from Fin n to Bool. -/
def Bitstring (n : ℕ) := Fin n → Bool
```

**Alternatives considered:**
- `Vector Bool n` — wraps `List Bool` with length proof. More cumbersome API.
- `Fin n → ZMod 2` — algebraically richer but `Bool` is simpler for our needs.
- `Fin n → Bool` (bare) — chosen for its clean Mathlib integration.

Add `DecidableEq` and `Fintype` instances:
```lean
instance : DecidableEq (Bitstring n) := inferInstance  -- Function extensionality
instance : Fintype (Bitstring n) := Pi.fintype          -- Finite product of finite types
```

---

### 5.2 — S\_n Action on Bitstrings

**Effort:** 4h | **Module:** `Construction/Permutation.lean` | **Deps:** 5.1

```lean
/-- S_n acts on bitstrings by permuting coordinates: (σ • x)(i) = x(σ⁻¹(i)). -/
instance : MulAction (Equiv.Perm (Fin n)) (Bitstring n) where
  smul σ x := fun i => x (σ⁻¹ i)
  one_smul x := by
    ext i; simp [HSMul.hSMul]
  mul_smul σ τ x := by
    ext i; simp [HSMul.hSMul, mul_inv_rev]
```

**Key challenge:** The `mul_smul` proof requires showing
`x((σ * τ)⁻¹(i)) = (fun j => x(τ⁻¹(j)))(σ⁻¹(i))`, which reduces to
`(σ * τ)⁻¹ = τ⁻¹ * σ⁻¹`. This is `mul_inv_rev` in Mathlib.

**Important:** The action uses `σ⁻¹` (not `σ`) to match the standard
left-action convention: `(σ • x)_i = x_{σ⁻¹(i)}`. This is consistent with
DEVELOPMENT.md §3.2.

---

### 5.3 — Verify MulAction Laws

**Effort:** 3h | **Module:** `Construction/Permutation.lean` | **Deps:** 5.2

If the `MulAction` instance from 5.2 includes inline proofs of `one_smul` and
`mul_smul`, this unit verifies them and adds supplementary lemmas:

```lean
/-- Explicit computation rule for the permutation action. -/
@[simp]
theorem perm_smul_apply (σ : Equiv.Perm (Fin n)) (x : Bitstring n) (i : Fin n) :
    (σ • x) i = x (σ⁻¹ i) := rfl

/-- The action is faithful: different permutations act differently
    (provided n ≥ 2 and we can construct distinguishing bitstrings). -/
theorem perm_action_faithful (n : ℕ) (hn : 2 ≤ n)
    (σ : Equiv.Perm (Fin n)) (hσ : σ ≠ 1) :
    ∃ x : Bitstring n, σ • x ≠ x := by
  sorry
```

**Strategy for faithfulness:** If `σ ≠ 1`, there exists `i` with `σ i ≠ i`.
Construct `x` as the indicator of `{i}`: `x j = (j == i)`. Then
`(σ • x)(σ i) = x(σ⁻¹(σ i)) = x(i) = true`, but if `σ i ≠ i` then
`x(σ i) = false`, so `σ • x ≠ x`.

---

### 5.4 — Hamming Weight as Invariant

**Effort:** 4h | **Module:** `Construction/Permutation.lean` | **Deps:** 5.2, 2.8

```lean
/-- Hamming weight: the number of 1-bits in a bitstring. -/
def hammingWeight (x : Bitstring n) : ℕ :=
  Finset.card (Finset.univ.filter (fun i => x i = true))

/-- Hamming weight is invariant under any permutation action.
    This is because permutation merely rearranges coordinates
    without changing the count of 1-bits. -/
theorem hammingWeight_invariant (n : ℕ) :
    IsGInvariant (G := Equiv.Perm (Fin n)) (hammingWeight (n := n)) := by
  intro σ x
  unfold hammingWeight
  -- The filter sets {i | (σ • x)(i) = true} and {i | x(i) = true}
  -- are related by the bijection σ⁻¹, hence have the same cardinality.
  sorry
```

**Strategy:** Show that `Finset.univ.filter (fun i => (σ • x) i = true)` and
`Finset.univ.filter (fun i => x i = true)` have the same cardinality.
The map `σ` is a bijection on `Fin n` that transforms one filter into the
other. Use `Finset.card_map` or `Finset.card_bij`.

**This proof connects to COUNTEREXAMPLE.md:** The Hamming weight is the
exact attack function described in §§1–4. Proving it is G-invariant for
all G ≤ S\_n is the first half of understanding why same-weight
representatives are necessary.

---

### 5.5 — HGOE Scheme Instance

**Effort:** 5h | **Module:** `Construction/HGOE.lean` | **Deps:** 5.2, 3.1

```lean
import Orbcrypt.Construction.Permutation
import Orbcrypt.Crypto.Scheme

/--
Construct an `OrbitEncScheme` for the Hidden-Group Orbit Encryption (HGOE).

Given:
- A subgroup G ≤ S_n (the secret key)
- A canonical form for G's action
- Orbit representatives with a proof of distinctness

This produces a concrete instance of the abstract scheme.
-/
def hgoeScheme (n : ℕ)
    (G : Subgroup (Equiv.Perm (Fin n)))
    (can : CanonicalForm G.toGroup (Bitstring n))
    (reps : M → Bitstring n)
    (hDistinct : ∀ m₁ m₂ : M, m₁ ≠ m₂ →
      MulAction.orbit G.toGroup (reps m₁) ≠
      MulAction.orbit G.toGroup (reps m₂)) :
    OrbitEncScheme G.toGroup (Bitstring n) M where
  reps := reps
  reps_distinct := hDistinct
  canonForm := can
```

**Key challenge:** Working with `Subgroup.toGroup`. Mathlib represents
subgroups as subtypes, and the `MulAction` instance for a subgroup acting
on `X` may need to be derived from the parent group's action. Check whether
Mathlib provides `MulAction (↥H) X` given `MulAction G X` and `H : Subgroup G`.
If not, this instance must be constructed manually.

**Alternative approach:** Work with `G : Type*` directly (as an abstract group
with a `MulAction` instance) rather than `Subgroup`. This avoids the subtype
coercion issues but loses the explicit connection to S\_n.

---

### 5.6 — HGOE Correctness Instantiation

**Effort:** 3h | **Module:** `Construction/HGOE.lean` | **Deps:** 5.5, 4.3

```lean
/-- Correctness of HGOE: decryption inverts encryption.
    This is a direct application of the abstract correctness theorem (4.3). -/
theorem hgoe_correctness (n : ℕ)
    (G : Subgroup (Equiv.Perm (Fin n)))
    (scheme : OrbitEncScheme G.toGroup (Bitstring n) M)
    [Fintype M] [DecidableEq M]
    (m : M) (g : G) :
    decrypt scheme (encrypt scheme g m) = some m :=
  correctness scheme m g
```

**Strategy:** Direct application of `correctness` from Phase 4. This should
be a one-liner if the types align. The value is demonstrating that the abstract
theorem cleanly specializes to the concrete construction.

---

### 5.7 — HGOE Invariant Attack Instantiation

**Effort:** 4h | **Module:** `Construction/HGOE.lean` | **Deps:** 5.4, 5.5, 4.6

```lean
/-- Hamming weight IS a valid attack when representatives have different weights.
    This formalizes the counterexample: if wt(x_{m₀}) ≠ wt(x_{m₁}),
    the scheme is broken. -/
theorem hgoe_weight_attack (n : ℕ)
    (G : Subgroup (Equiv.Perm (Fin n)))
    (scheme : OrbitEncScheme G.toGroup (Bitstring n) M)
    (m₀ m₁ : M)
    (hDiffWeight : hammingWeight (scheme.reps m₀) ≠ hammingWeight (scheme.reps m₁)) :
    ∃ A : Adversary (Bitstring n) M, hasAdvantage scheme A := by
  -- Apply invariant_attack with f := hammingWeight
  -- hammingWeight is G-invariant (by hammingWeight_invariant)
  -- and separates m₀, m₁ (by hDiffWeight)
  sorry
```

**Strategy:** Apply `invariant_attack` (4.6) with `f := hammingWeight`,
`hInv := hammingWeight_invariant`, `hSep := hDiffWeight`. This directly
shows the counterexample attack works in the concrete setting.

---

### 5.8 — Same-Weight Non-Separation Lemma

**Effort:** 3h | **Module:** `Construction/HGOE.lean` | **Deps:** 5.4, 2.10

```lean
/-- When all representatives have the same Hamming weight, the weight function
    cannot separate any pair of messages. This is the formal defense from
    DEVELOPMENT.md §7.1. -/
theorem same_weight_not_separating (n : ℕ)
    (G : Subgroup (Equiv.Perm (Fin n)))
    (reps : M → Bitstring n)
    (w : ℕ)
    (hSameWeight : ∀ m : M, hammingWeight (reps m) = w)
    (m₀ m₁ : M) :
    ¬ IsSeparating (G := G.toGroup) (hammingWeight (n := n)) (reps m₀) (reps m₁) := by
  -- IsSeparating requires hammingWeight(reps m₀) ≠ hammingWeight(reps m₁)
  -- But hSameWeight gives both equal to w.
  intro ⟨_, hSep⟩
  exact hSep (by rw [hSameWeight m₀, hSameWeight m₁])
```

**This is the punchline of the defense analysis:** DEVELOPMENT.md §7.1 states
that choosing all orbit representatives with the same Hamming weight w = ⌊n/2⌋
defeats the Hamming weight attack. This lemma formally proves that claim.

---

## Parallel Execution Plan

```
Phase 2 complete ──────────────────────┐
        │                              │
        ▼                              │
  Track A: Permutation.lean            │
  ┌──────────────────────┐             │
  │ 5.1 Bitstring type   │             │
  │ 5.2 S_n action       │         Phase 4 complete
  │ 5.3 MulAction laws   │             │
  │ 5.4 Hamming weight   │             │
  └──────────────────────┘             │
        │                              │
        └──────────────┬───────────────┘
                       ▼
                Track B: HGOE.lean
                ┌──────────────────────┐
                │ 5.5 Scheme instance  │
                │ 5.6 Correctness inst.│
                │ 5.7 Weight attack    │
                │ 5.8 Same-weight def. │
                └──────────────────────┘
```

**Key insight:** Track A (5.1–5.4) can start during Phase 3 or even late
Phase 2, since it only depends on the `GroupAction/` modules.

---

## Risk Analysis

| Risk | Units | Likelihood | Impact | Mitigation |
|------|-------|-----------|--------|------------|
| `MulAction` instance for subgroups missing in Mathlib | 5.5 | Medium | High | Use abstract group approach; construct instance manually if needed |
| `Finset.card_bij` proof for Hamming weight is tedious | 5.4 | High | Medium | Consider using `Fintype.card_congr` with an `Equiv` instead |
| Type coercion issues with `Subgroup.toGroup` | 5.5–5.8 | High | Medium | Add explicit coercions; use `@` for full annotation if needed |
| `mul_inv_rev` name/location changed in Mathlib | 5.2 | Low | Low | Search for equivalent: `inv_mul_rev`, `Equiv.Perm.mul_inv` |

---

## Exit Criteria

- [ ] `Construction/Permutation.lean` compiles without `sorry`
- [ ] `Construction/HGOE.lean` compiles without `sorry`
- [ ] `lake build` succeeds with zero errors
- [ ] `Bitstring n` has `DecidableEq` and `Fintype` instances
- [ ] `MulAction (Equiv.Perm (Fin n)) (Bitstring n)` instance verified
- [ ] `hammingWeight_invariant` proved
- [ ] `hgoeScheme` constructs a valid `OrbitEncScheme`
- [ ] `same_weight_not_separating` proved
- [ ] All definitions and theorems have docstrings

---

## Transition to Phase 6

With all proofs complete, Phase 6 audits for remaining `sorry`, adds
documentation, configures CI, and performs a final clean build.

See: [Phase 6 — Polish & Documentation](PHASE_6_POLISH_AND_DOCUMENTATION.md)
