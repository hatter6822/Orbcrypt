# Phase 5 — Concrete Construction

## Weeks 11–14 | 12 Work Units | ~26 Hours

*Part of the [Orbcrypt Lean 4 Formalization Plan](../FORMALIZATION_PLAN.md)*

---

## Overview

Phase 5 bridges theory and practice by instantiating the abstract orbit
encryption framework with the concrete symmetric group S\_n acting on
bitstrings {0,1}^n. It produces a working `OrbitEncScheme` instance and
formally proves that the Hamming weight defense from DEVELOPMENT.md §7.1
defeats the primary attack vector from COUNTEREXAMPLE.md.

The original 8 work units have been decomposed into 12 smaller units.
Key splits: the S\_n action (old 5.2, 4h) is separated from its law proofs
and simp lemmas; Hamming weight (old 5.4, 4h) is separated into definition
and invariance proof; and a new subgroup action unit (5.7) addresses the
most common source of type coercion issues.

**Parallelism note:** Units 5.1–5.6 (Permutation.lean) depend only on Phase 2
and can begin as soon as Phase 2 completes — potentially running in parallel
with Phases 3 and 4. Units 5.7–5.11 (HGOE.lean) require Phase 4 theorems.

---

## Objectives

1. A `Bitstring n` type with a verified `MulAction` instance for S\_n.
2. Proof that Hamming weight is a G-invariant function for any G ≤ S\_n.
3. A concrete `OrbitEncScheme` instance for the Hidden-Group construction.
4. Formal proof that same-weight representatives neutralize the Hamming weight
   attack.

---

## Prerequisites

- Phase 2 complete (for units 5.1–5.6).
- Phase 4 complete (for units 5.7–5.11).

---

## Work Units

### Track A: Permutation.lean (5.1 → 5.2 → 5.3 → 5.4 → 5.5 → 5.6)

Track A builds the concrete `Bitstring` type and the S\_n action on it.
It depends only on Phase 2 and can start as soon as Phase 2 completes.

---

#### 5.1 — Bitstring Type

**Effort:** 1.5h | **Module:** `Construction/Permutation.lean` | **Deps:** Phase 1

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

**Required instances:**
```lean
instance : DecidableEq (Bitstring n) := inferInstance  -- Pi.decidableEq
instance : Fintype (Bitstring n) := Pi.fintype          -- Finite product
```

**Common pitfalls:**
- `inferInstance` may fail for `DecidableEq` if Lean cannot find
  `DecidableEq Bool` or `DecidableEq (Fin n → Bool)` in the instance
  cache. If so, use `Pi.decidableEq` or `Function.decidableEq` explicitly.
- `Fintype (Bitstring n)` requires `Fintype (Fin n)` and `Fintype Bool`,
  both of which Mathlib provides. If `Pi.fintype` is not found, import
  `Mathlib.Data.Fintype.Pi`.

**Definition of Done:**
- `Bitstring n` defined.
- `#check (inferInstance : DecidableEq (Bitstring 8))` succeeds.
- `#check (inferInstance : Fintype (Bitstring 8))` succeeds.

---

#### 5.2 — S\_n Action Definition

**Effort:** 2h | **Module:** `Construction/Permutation.lean` | **Deps:** 5.1

```lean
/-- S_n acts on bitstrings by permuting coordinates: (σ • x)(i) = x(σ⁻¹(i)). -/
instance : MulAction (Equiv.Perm (Fin n)) (Bitstring n) where
  smul σ x := fun i => x (σ⁻¹ i)
  one_smul x := by
    ext i; simp [HSMul.hSMul]
  mul_smul σ τ x := by
    ext i; simp [HSMul.hSMul, mul_inv_rev]
```

**Why `σ⁻¹` not `σ`:** The action uses `σ⁻¹` to match the standard
left-action convention: `(σ • x)_i = x_{σ⁻¹(i)}`. This ensures
`(σ * τ) • x = σ • (τ • x)` holds without reversing composition.
See DEVELOPMENT.md §3.2.

**Proof obligations:**

| Law | Statement | Key Mathlib lemma |
|-----|-----------|-------------------|
| `one_smul` | `(1 • x) i = x i` | `Equiv.Perm.one_apply` or `inv_one` |
| `mul_smul` | `((σ * τ) • x) i = (σ • (τ • x)) i` | `mul_inv_rev` |

**Step-by-step for `one_smul`:**
1. `ext i` reduces to pointwise equality.
2. Goal: `x (1⁻¹ i) = x i`.
3. `1⁻¹ = 1` by `inv_one`, and `(1 : Equiv.Perm _) i = i` by `Equiv.Perm.one_apply`.
4. Close with `simp [inv_one, Equiv.Perm.one_apply]` or `simp`.

**Step-by-step for `mul_smul`:**
1. `ext i` reduces to pointwise equality.
2. LHS: `x ((σ * τ)⁻¹ i)`.
3. RHS: `(τ • x) (σ⁻¹ i) = x (τ⁻¹ (σ⁻¹ i))`.
4. Need: `(σ * τ)⁻¹ = τ⁻¹ * σ⁻¹`. This is `mul_inv_rev`.
5. Then `(τ⁻¹ * σ⁻¹) i = τ⁻¹ (σ⁻¹ i)` by `Equiv.Perm.mul_apply`.
6. Close with `simp [mul_inv_rev, Equiv.Perm.mul_apply]`.

**Common pitfalls:**
- `HSMul.hSMul` may need explicit unfolding. If `simp` does not reduce
  `σ • x` to `fun i => x (σ⁻¹ i)`, add `show ... = ...` or `change`.
- `Equiv.Perm.mul_apply` vs `Equiv.Perm.coe_mul`: these may differ across
  Mathlib versions. Search for the correct name.
- The `Bitstring` type alias may not unfold automatically. If `ext i` fails,
  use `funext i` or `show ∀ i, ... = ...`.

**Definition of Done:**
- `MulAction (Equiv.Perm (Fin n)) (Bitstring n)` instance compiles.
- Both `one_smul` and `mul_smul` proved inline (no `sorry`).

---

#### 5.3 — Action Simp Lemmas

**Effort:** 2h | **Module:** `Construction/Permutation.lean` | **Deps:** 5.2

```lean
/-- Explicit computation rule for the permutation action. -/
@[simp]
theorem perm_smul_apply (σ : Equiv.Perm (Fin n)) (x : Bitstring n)
    (i : Fin n) :
    (σ • x) i = x (σ⁻¹ i) := rfl
```

This `@[simp]` lemma is critical infrastructure. Without it, every proof
involving the action must manually unfold the `MulAction` instance.

**Additional utility lemmas:**
```lean
/-- The identity permutation acts trivially on bitstrings. -/
@[simp]
theorem one_perm_smul (x : Bitstring n) : (1 : Equiv.Perm (Fin n)) • x = x := by
  ext i; simp

/-- Composing actions equals action by product. -/
@[simp]
theorem mul_perm_smul (σ τ : Equiv.Perm (Fin n)) (x : Bitstring n) :
    σ • (τ • x) = (σ * τ) • x := by
  ext i; simp [mul_inv_rev, Equiv.Perm.mul_apply]
```

**Definition of Done:**
- All three simp lemmas compile without `sorry`.
- `simp` can automatically reduce `(σ • x) i` in subsequent proofs.

---

#### 5.4 — Faithfulness Proof

**Effort:** 2h | **Module:** `Construction/Permutation.lean` | **Deps:** 5.2

```lean
/-- The action is faithful: different permutations act differently
    (provided n ≥ 2 and we can construct distinguishing bitstrings). -/
theorem perm_action_faithful (n : ℕ) (hn : 2 ≤ n)
    (σ : Equiv.Perm (Fin n)) (hσ : σ ≠ 1) :
    ∃ x : Bitstring n, σ • x ≠ x := by
  -- Since σ ≠ 1, ∃ i with σ i ≠ i (by Equiv.Perm.ne_one_iff)
  -- Construct indicator x = (fun j => j == i)
  -- Then (σ • x)(σ i) = x(σ⁻¹(σ i)) = x(i) = true
  -- But x(σ i) = (σ i == i) = false (since σ i ≠ i)
  sorry
```

**Strategy:**
1. From `hσ : σ ≠ 1`, obtain `i : Fin n` with `σ i ≠ i`.
   Use `Equiv.Perm.ne_one_iff_exists_ne` or similar Mathlib lemma.
2. Construct `x : Bitstring n := fun j => decide (j = i)`.
3. Show `(σ • x) (σ i) ≠ x (σ i)`:
   - `(σ • x) (σ i) = x (σ⁻¹ (σ i)) = x i = true`.
   - `x (σ i) = decide (σ i = i) = false` (since `σ i ≠ i`).
4. Therefore `σ • x ≠ x` by function extensionality (negated).

**Common pitfalls:**
- `Equiv.Perm.ne_one_iff_exists_ne` may not exist. Alternative: use
  `not_forall.mp` on `hσ` after rewriting `σ = 1 ↔ ∀ i, σ i = i`.
- `decide (j = i)` requires `DecidableEq (Fin n)`, which is available.
- The `n ≥ 2` hypothesis may not be needed if the proof goes through for
  all `n`. Try without it first.

**Definition of Done:**
- `perm_action_faithful` compiles without `sorry`.
- The constructed bitstring is explicit (not an `Exists.choose`).

---

#### 5.5 — Hamming Weight Definition

**Effort:** 1.5h | **Module:** `Construction/Permutation.lean` | **Deps:** 5.1

```lean
/-- Hamming weight: the number of 1-bits in a bitstring. -/
def hammingWeight (x : Bitstring n) : ℕ :=
  Finset.card (Finset.univ.filter (fun i => x i = true))
```

**Alternative definitions:**
```lean
-- Using Finset.sum:
def hammingWeight' (x : Bitstring n) : ℕ :=
  Finset.sum Finset.univ (fun i => if x i then 1 else 0)

-- Using Bool.toNat:
def hammingWeight'' (x : Bitstring n) : ℕ :=
  Finset.sum Finset.univ (fun i => (x i).toNat)
```

All three are equivalent. The `filter + card` version is preferred because
`Finset.card_filter` and `Finset.card_map` lemmas are directly applicable
to the invariance proof (5.6).

**Utility lemma:**
```lean
/-- Hamming weight counts true positions. -/
theorem hammingWeight_eq_card_true (x : Bitstring n) :
    hammingWeight x = (Finset.univ.filter (fun i => x i = true)).card := rfl
```

**Definition of Done:**
- `hammingWeight` defined.
- `#eval hammingWeight (fun i : Fin 4 => i.val % 2 == 0)` returns `2`.

---

#### 5.6 — Hamming Weight Invariance Proof

**Effort:** 3h | **Module:** `Construction/Permutation.lean` | **Deps:** 5.2, 5.5, 2.8

```lean
/-- Hamming weight is invariant under any permutation action.
    Permutation merely rearranges coordinates without changing the
    count of 1-bits. -/
theorem hammingWeight_invariant (n : ℕ) :
    IsGInvariant (G := Equiv.Perm (Fin n)) (hammingWeight (n := n)) := by
  intro σ x
  unfold hammingWeight
  -- Need: card(filter(fun i => (σ • x) i = true)) = card(filter(fun i => x i = true))
  -- (σ • x) i = x (σ⁻¹ i), so the filter set is {i | x(σ⁻¹ i) = true}
  -- This equals σ '' {i | x i = true} (the image under σ of the true-set)
  -- σ is a bijection, so image preserves cardinality
  sorry
```

**Strategy (detailed):**

1. Unfold `hammingWeight` on both sides.
2. The LHS filter is `{i | (σ • x) i = true} = {i | x(σ⁻¹ i) = true}`.
3. The RHS filter is `{i | x i = true}`.
4. Show these two `Finset`s have the same cardinality by constructing a
   bijection between them.

**Approach A — Finset.card_map:**
```lean
  -- The map σ : Fin n → Fin n is an injection (it's a permutation)
  -- σ sends {j | x j = true} to {σ j | x j = true} = {i | x(σ⁻¹ i) = true}
  -- So card is preserved
  apply Finset.card_nbij (fun j => σ j)
  -- ... prove bijection properties
```

**Approach B — Finset.card_congr:**
```lean
  have : (Finset.univ.filter (fun i => (σ • x) i = true)) =
         (Finset.univ.filter (fun i => x i = true)).map σ.toEquiv.toEmbedding := by
    ext i; simp [perm_smul_apply]
  rw [this, Finset.card_map]
```

**Approach C — Direct rewrite via Equiv:**
```lean
  conv_lhs => rw [show (fun i => (σ • x) i = true) = (fun i => x (σ⁻¹ i) = true) from by ext; simp]
  rw [← Finset.card_map σ⁻¹.toEmbedding]
  congr 1
  ext i; simp [Finset.mem_map, Finset.mem_filter]
```

Approach B is cleanest if `Finset.card_map` is available and `σ.toEquiv.toEmbedding`
resolves correctly.

**Common pitfalls:**
- `Equiv.Perm` is an `Equiv`, not a plain function. You may need
  `σ.toEquiv.toEmbedding` or `σ.toEmbedding` to use `Finset.map`.
- `Finset.card_map` requires an `Embedding`, not a plain injection.
  If coercion fails, construct the embedding manually.
- The `filter` predicate must be `Decidable`. Since `x i = true` is
  decidable (Bool has DecidableEq), this is fine.

**This proof connects to COUNTEREXAMPLE.md:** Hamming weight is the exact
attack function described in §§1–4. Proving it is G-invariant for all
G ≤ S\_n is the first half of understanding why same-weight representatives
are necessary.

**Definition of Done:**
- `hammingWeight_invariant` compiles without `sorry`.
- The proof uses Mathlib's `Finset` API (not `decide` or `native_decide`).

---

### Track B: HGOE.lean (5.7 → 5.8 → 5.9 → 5.10 → 5.11)

Track B instantiates the abstract `OrbitEncScheme` with the concrete S\_n
bitstring action and proves the Hamming weight defense. It requires both
Track A (Permutation.lean) and Phase 4 (core theorems).

The new unit 5.7 (subgroup action instance) was extracted because subgroup
coercion issues are the #1 source of Lean 4 pain in this track.

---

#### 5.7 — Subgroup Action Instance

**Effort:** 2.5h | **Module:** `Construction/HGOE.lean` | **Deps:** 5.2

*New unit. The most common blocker in Phase 5 is getting Lean to recognize
that a subgroup G ≤ S\_n acts on `Bitstring n`. This unit isolates that
problem.*

```lean
import Orbcrypt.Construction.Permutation
import Orbcrypt.Crypto.Scheme

/-- A subgroup of S_n inherits the MulAction on Bitstring n.
    Mathlib may provide this automatically via SubgroupClass, but
    if not, we construct it explicitly. -/
instance subgroupBitstringAction (n : ℕ)
    (G : Subgroup (Equiv.Perm (Fin n))) :
    MulAction G (Bitstring n) where
  smul g x := (g : Equiv.Perm (Fin n)) • x
  one_smul x := by
    show (((1 : G) : Equiv.Perm (Fin n)) • x) = x
    simp [Subgroup.coe_one, one_smul]
  mul_smul g₁ g₂ x := by
    show ((g₁ * g₂ : G) : Equiv.Perm (Fin n)) • x =
         (g₁ : Equiv.Perm (Fin n)) • ((g₂ : Equiv.Perm (Fin n)) • x)
    simp [Subgroup.coe_mul, mul_smul]
```

**Strategy:**

1. Check if Mathlib already provides `MulAction ↥H X` when `MulAction G X`
   and `H : Subgroup G`. Search for `Subgroup.mulAction` or
   `SubgroupClass.toMulAction`.
2. If it exists, this unit becomes a one-line `instance := inferInstance`.
3. If not, construct manually by coercing subgroup elements to S\_n and
   applying the parent action.

**Key Mathlib search queries:**
```
#check Subgroup.mulAction
#check MulAction.compHom
#check Subgroup.subtype
```

If `MulAction.compHom` is available, the alternative approach is:
```lean
instance : MulAction G (Bitstring n) :=
  MulAction.compHom (Bitstring n) G.subtype
```
where `G.subtype : G →* Equiv.Perm (Fin n)` is the inclusion homomorphism.

**Common pitfalls:**
- `↥G` (the coercion of a `Subgroup` to a `Type`) vs `G.carrier` vs
  `{ g : Equiv.Perm (Fin n) // g ∈ G }` — these are all the same type
  but Lean may not see them as definitionally equal.
- `Subgroup.coe_one` and `Subgroup.coe_mul` are needed to relate subgroup
  operations to parent group operations. If these names don't exist, try
  `OneMemClass.coe_one` and `MulMemClass.coe_mul`.
- Instance diamonds: if Mathlib *does* provide the instance automatically
  but with a different definitional reduction than our manual one, proofs
  downstream may break. Always check with `#check (inferInstance : MulAction G (Bitstring n))`.

**Definition of Done:**
- `MulAction G (Bitstring n)` instance available for any `G : Subgroup (Equiv.Perm (Fin n))`.
- `(g : G) • (x : Bitstring n)` reduces to `(↑g : Equiv.Perm (Fin n)) • x`.

---

#### 5.8 — HGOE Scheme Instance

**Effort:** 3h | **Module:** `Construction/HGOE.lean` | **Deps:** 5.7, 3.1

```lean
/--
Construct an `OrbitEncScheme` for the Hidden-Group Orbit Encryption (HGOE).
Given a subgroup G ≤ S_n, a canonical form, and distinct orbit representatives,
produce a concrete instance of the abstract scheme.
-/
def hgoeScheme (n : ℕ) {M : Type*}
    (G : Subgroup (Equiv.Perm (Fin n)))
    (can : CanonicalForm G (Bitstring n))
    (reps : M → Bitstring n)
    (hDistinct : ∀ m₁ m₂ : M, m₁ ≠ m₂ →
      MulAction.orbit G (reps m₁) ≠ MulAction.orbit G (reps m₂)) :
    OrbitEncScheme G (Bitstring n) M where
  reps := reps
  reps_distinct := hDistinct
  canonForm := can
```

**Key challenge:** The type of `G` in `OrbitEncScheme G X M` must match the
type used in `MulAction G X`. If `OrbitEncScheme` expects `G : Type*` with
`[Group G]`, but we have `G : Subgroup (Equiv.Perm (Fin n))`, then `G` in
the scheme is the *coerced type* `↥G`, not the subgroup term.

**Approach A — Use `↥G` throughout:**
```lean
def hgoeScheme ... : OrbitEncScheme (↥G) (Bitstring n) M where ...
```

**Approach B — Use abstract group with embedding:**
Work with `G : Type*` equipped with `[Group G]`, `[MulAction G (Bitstring n)]`,
and a group homomorphism `G →* Equiv.Perm (Fin n)`. This avoids subtype
coercion but loses the explicit S\_n connection.

Approach A is recommended for consistency with the concrete construction
narrative.

**Common pitfalls:**
- The `CanonicalForm` must be for the subgroup action, not the full S\_n
  action. Ensure `CanonicalForm (↥G) (Bitstring n)` matches.
- `MulAction.orbit (↥G) x` may not reduce the same way as
  `MulAction.orbit (Equiv.Perm (Fin n)) x`. The orbits are different
  (subgroup orbits ⊆ full group orbits).
- `hDistinct` must quantify over `MulAction.orbit (↥G) ...`, not the
  full symmetric group orbit.

**Definition of Done:**
- `hgoeScheme` compiles with all fields filled (no `sorry`).
- `#check @hgoeScheme` shows the expected type.

---

#### 5.9 — HGOE Correctness Instantiation

**Effort:** 2h | **Module:** `Construction/HGOE.lean` | **Deps:** 5.8, 4.5

```lean
/-- Correctness of HGOE: decryption inverts encryption.
    Direct application of the abstract correctness theorem (4.5). -/
theorem hgoe_correctness (n : ℕ) {M : Type*} [Fintype M] [DecidableEq M]
    (G : Subgroup (Equiv.Perm (Fin n)))
    (scheme : OrbitEncScheme (↥G) (Bitstring n) M)
    (m : M) (g : ↥G) :
    decrypt scheme (encrypt scheme g m) = some m :=
  correctness scheme m g
```

**Strategy:** Direct application of `correctness` from Phase 4 (unit 4.5).
This should be a one-liner if the types align. The value is demonstrating
that the abstract theorem cleanly specializes to the concrete construction.

**Common pitfalls:**
- If `correctness` expects `[Group G]` but `↥G` does not automatically have
  a `Group` instance, you may need `[Group (↥G)]` or `inferInstance`.
  Mathlib's `Subgroup.toGroup` should provide this.
- If the `DecidableEq (Bitstring n)` instance is not found, add it
  explicitly: `haveI : DecidableEq (Bitstring n) := inferInstance`.

**Definition of Done:**
- `hgoe_correctness` compiles as a one-liner (no `sorry`).
- The proof is literally `correctness scheme m g` or similar.

---

#### 5.10 — HGOE Weight Attack Instantiation

**Effort:** 2.5h | **Module:** `Construction/HGOE.lean` | **Deps:** 5.6, 5.8, 4.9

```lean
/-- Hamming weight IS a valid attack when representatives have different weights.
    Formalizes the counterexample: if wt(x_{m₀}) ≠ wt(x_{m₁}), the scheme
    is broken. -/
theorem hgoe_weight_attack (n : ℕ) {M : Type*}
    (G : Subgroup (Equiv.Perm (Fin n)))
    (scheme : OrbitEncScheme (↥G) (Bitstring n) M)
    (m₀ m₁ : M)
    (hDiffWeight : hammingWeight (scheme.reps m₀) ≠
                   hammingWeight (scheme.reps m₁)) :
    ∃ A : Adversary (Bitstring n) M, hasAdvantage scheme A := by
  -- Apply invariant_attack (4.9) with f := hammingWeight
  -- hammingWeight is G-invariant (by hammingWeight_invariant, 5.6)
  -- and separates m₀, m₁ (by hDiffWeight)
  exact invariant_attack scheme (fun x => hammingWeight x)
    m₀ m₁ (hammingWeight_invariant_subgroup G) hDiffWeight
```

**Strategy:** Apply `invariant_attack` (unit 4.9) with:
- `f := hammingWeight`
- `hInv := hammingWeight_invariant` (unit 5.6) — but note this must be for
  the *subgroup* action, not the full S\_n action.
- `hSep := hDiffWeight`

**Key subtlety:** `hammingWeight_invariant` (5.6) proves invariance under
the full S\_n action. For the subgroup action, we need a bridge lemma:

```lean
/-- Hamming weight is invariant under any subgroup of S_n. -/
theorem hammingWeight_invariant_subgroup (n : ℕ)
    (G : Subgroup (Equiv.Perm (Fin n))) :
    IsGInvariant (G := ↥G) (hammingWeight (n := n)) := by
  intro ⟨σ, _⟩ x
  exact hammingWeight_invariant n σ x
```

This follows because the subgroup action is defined via coercion to S\_n.

**Common pitfalls:**
- `invariant_attack` expects `DecidableEq Y` where `Y` is the output type
  of `f`. Here `Y = ℕ`, which has `DecidableEq`. Should resolve automatically.
- The coercion `⟨σ, _⟩` destructures a subgroup element into its underlying
  permutation. If this syntax fails, use `(g : ↥G) => hammingWeight_invariant n (↑g) x`.

**Definition of Done:**
- `hammingWeight_invariant_subgroup` compiles without `sorry`.
- `hgoe_weight_attack` compiles without `sorry`.

---

#### 5.11 — Same-Weight Defense Lemma

**Effort:** 2h | **Module:** `Construction/HGOE.lean` | **Deps:** 5.6, 2.10

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
    ¬ IsSeparating (G := ↥G) (hammingWeight (n := n))
      (reps m₀) (reps m₁) := by
  -- IsSeparating requires hammingWeight(reps m₀) ≠ hammingWeight(reps m₁)
  -- But hSameWeight gives both equal to w.
  intro ⟨_, hSep⟩
  exact hSep (by rw [hSameWeight m₀, hSameWeight m₁])
```

**Strategy:**
1. Unfold `IsSeparating` to get its two conjuncts: G-invariance and
   `f(reps m₀) ≠ f(reps m₁)`.
2. The second conjunct is contradicted by `hSameWeight`:
   `hammingWeight(reps m₀) = w = hammingWeight(reps m₁)`.

**This is the punchline of the defense analysis:** DEVELOPMENT.md §7.1
states that choosing all orbit representatives with the same Hamming weight
`w = ⌊n/2⌋` defeats the Hamming weight attack. This lemma formally proves
that claim.

**Common pitfalls:**
- `IsSeparating` (from 2.10) is `IsGInvariant f ∧ f x₀ ≠ f x₁`. The
  destructuring `⟨_, hSep⟩` discards the invariance and keeps the
  separation. If the definition order is reversed, swap.
- The final step `hSep (by rw [...])` proves `False` from
  `hSep : f(reps m₀) ≠ f(reps m₁)` and the rewrite showing they're equal.
  If `rw` fails, use `calc` or `have`.

**Definition of Done:**
- `same_weight_not_separating` compiles without `sorry`.
- The proof is ≤ 5 lines.

---

### 5.12 — Construction Integration Test

**Effort:** 2h | **Module:** All `Construction/*.lean` | **Deps:** 5.9, 5.10, 5.11

*New unit. Verifies that the entire Construction layer composes correctly.*

**Checklist:**

1. Build both construction modules:
   ```bash
   source ~/.elan/env && lake build Orbcrypt.Construction.Permutation
   source ~/.elan/env && lake build Orbcrypt.Construction.HGOE
   ```

2. Verify no `sorry`:
   ```bash
   grep -rn "sorry" Orbcrypt/Construction/ --include="*.lean"
   ```

3. Verify the concrete construction satisfies the abstract interface:
   ```lean
   -- In a scratch file:
   import Orbcrypt.Construction.HGOE
   #check @hgoeScheme
   #check @hgoe_correctness
   #check @hgoe_weight_attack
   #check @same_weight_not_separating
   ```

4. Verify the abstract theorems compose with concrete construction:
   ```lean
   -- The abstract correctness theorem works with the concrete scheme:
   example (n : ℕ) (G : Subgroup (Equiv.Perm (Fin n)))
       (scheme : OrbitEncScheme (↥G) (Bitstring n) M)
       [Fintype M] [DecidableEq M] (m : M) (g : ↥G) :
       decrypt scheme (encrypt scheme g m) = some m :=
     correctness scheme m g
   ```

**Definition of Done:**
- Both construction modules build without errors.
- Zero `sorry` in `Construction/`.
- Abstract theorems specialize cleanly to the concrete construction.

---

## Parallel Execution Plan

```
Phase 2 complete ──────────────────────────┐
        │                                  │
        ▼                                  │
  Track A: Permutation.lean                │
  ┌──────────────────────────┐             │
  │ 5.1  Bitstring type 1.5h│             │
  │ 5.2  S_n action     2h  │         Phase 4 complete
  │ 5.3  Simp lemmas    2h  │             │
  │ 5.4  Faithfulness   2h  │             │
  │ 5.5  Hamming def    1.5h│             │
  │ 5.6  Hamming inv    3h  │             │
  └──────────────────────────┘             │
        │                                  │
        └──────────────────┬───────────────┘
                           ▼
                  Track B: HGOE.lean
                  ┌──────────────────────────┐
                  │ 5.7  Subgroup action 2.5h│
                  │ 5.8  Scheme instance 3h  │
                  │ 5.9  Correctness     2h  │
                  │ 5.10 Weight attack   2.5h│
                  │ 5.11 Same-weight def 2h  │
                  └──────────────────────────┘
                           │
                           ▼
                  5.12 Integration test (2h)
```

**Key insight:** Track A (5.1–5.6) can start during Phase 3 or even late
Phase 2, since it only depends on the `GroupAction/` modules. This provides
significant schedule compression.

**Optimal schedule for a single contributor:**

| Day | Work | Hours | Running Total |
|-----|------|-------|---------------|
| 1 | 5.1 (Bitstring type) + 5.5 (Hamming def) | 3h | 3h |
| 2 | 5.2 (S_n action definition) | 2h | 5h |
| 3 | 5.3 (simp lemmas) + 5.4 (faithfulness) | 4h | 9h |
| 4 | 5.6 (Hamming invariance proof) | 3h | 12h |
| 5 | 5.7 (subgroup action instance) | 2.5h | 14.5h |
| 6 | 5.8 (HGOE scheme instance) | 3h | 17.5h |
| 7 | 5.9 (correctness) + 5.10 (weight attack) | 4.5h | 22h |
| 8 | 5.11 (same-weight defense) + 5.12 (integration) | 4h | 26h |

---

## Risk Analysis

| Risk | Units | Likelihood | Impact | Mitigation |
|------|-------|-----------|--------|------------|
| `MulAction` instance for subgroups missing in Mathlib | 5.7 | Medium | High | Use `MulAction.compHom` with `Subgroup.subtype`; construct manually if needed |
| `Finset.card_map` / `Finset.card_bij` proof tedious | 5.6 | High | Medium | Try `Finset.card_map` with `σ.toEmbedding` first; fall back to `Fintype.card_congr` with an `Equiv` |
| Type coercion issues with `↥G` vs `Subgroup G` | 5.7–5.11 | High | Medium | Add explicit coercions with `(g : ↥G)` and `(↑g : Equiv.Perm _)`; use `@` for full annotation if needed |
| `mul_inv_rev` name/location changed in Mathlib | 5.2 | Low | Low | Search for equivalent: `inv_mul_rev`, `Equiv.Perm.mul_inv` |
| `hammingWeight_invariant` for subgroups needs bridge | 5.10 | Medium | Medium | Prove `hammingWeight_invariant_subgroup` as explicit lemma in 5.10 |
| Instance diamond between manual and Mathlib-provided subgroup action | 5.7 | Medium | High | Before defining a manual instance, check `inferInstance` first; if both exist, remove the manual one |

---

## Common Lean 4 Pitfalls for Phase 5

1. **`Equiv.Perm` is not `Function`:** `σ : Equiv.Perm (Fin n)` is an
   `Equiv`, not a plain function. Use `σ.toFun` or `⇑σ` (coercion) to
   apply it. `σ i` works via coercion but `σ.invFun i` may be needed for
   the inverse.

2. **`Subgroup` coercion:** `G : Subgroup (Equiv.Perm (Fin n))` means `↥G`
   is the subtype `{ x // x ∈ G }`. An element `g : ↥G` has `↑g : Equiv.Perm (Fin n)`.
   Use `Subtype.val` or `↑` for the coercion.

3. **`Finset.filter` decidability:** `Finset.univ.filter p` requires
   `DecidablePred p`. For `p = fun i => x i = true`, this is automatic
   from `DecidableEq Bool`. If Lean complains, add `[DecidablePred p]`.

4. **`Bitstring` unfolding:** Since `Bitstring n := Fin n → Bool` is a
   `def` (not `abbrev`), Lean may not unfold it automatically. Use
   `show Fin n → Bool` or `change` if needed.

---

## Exit Criteria

- [ ] `Construction/Permutation.lean` compiles without `sorry`
- [ ] `Construction/HGOE.lean` compiles without `sorry`
- [ ] `lake build Orbcrypt.Construction.Permutation` succeeds
- [ ] `lake build Orbcrypt.Construction.HGOE` succeeds
- [ ] `Bitstring n` has `DecidableEq` and `Fintype` instances
- [ ] `MulAction (Equiv.Perm (Fin n)) (Bitstring n)` instance verified
- [ ] `MulAction (↥G) (Bitstring n)` instance available for subgroups
- [ ] `hammingWeight_invariant` proved for full S\_n
- [ ] `hammingWeight_invariant_subgroup` proved for subgroups
- [ ] `hgoeScheme` constructs a valid `OrbitEncScheme`
- [ ] `same_weight_not_separating` proved
- [ ] All definitions and theorems have docstrings
- [ ] `grep -rn "sorry" Orbcrypt/Construction/` returns empty

---

## Transition to Phase 6

With all proofs complete, Phase 6 audits for remaining `sorry`, adds
documentation, configures CI, and performs a final clean build.

See: [Phase 6 — Polish & Documentation](PHASE_6_POLISH_AND_DOCUMENTATION.md)
