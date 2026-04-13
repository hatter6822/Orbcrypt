# Phase 4 — Core Theorems

## Weeks 7–10 | 16 Work Units | ~38 Hours

*Part of the [Orbcrypt Lean 4 Formalization Plan](../FORMALIZATION_PLAN.md)*

---

## Overview

Phase 4 is the heart of the formalization. It proves the three headline
results: correctness, the invariant attack theorem, and the conditional
security reduction (OIA ⟹ IND-1-CPA). Each theorem combines Phase 2's
group action lemmas with Phase 3's cryptographic definitions.

This phase has **four tracks** — one per theorem plus an optional
contrapositive — joined only by the final integration verification (unit 4.16).

The original 10 work units have been decomposed into 16 smaller, more
precisely scoped units. Complex proofs (especially the correctness theorem
and advantage elimination) are split so that each sub-unit targets exactly
one proof obligation, reducing the risk of multi-hour debugging sessions.

---

## Objectives

1. Machine-checked proof that decryption inverts encryption (DEVELOPMENT.md §4.2).
2. Machine-checked proof that a separating invariant yields a complete break (§4.4).
3. Machine-checked proof that OIA implies IND-1-CPA security (§8.1).
4. (Optional) Machine-checked proof of the contrapositive: insecurity implies a
   distinguishing function.

---

## Prerequisites

- Phase 2 complete (all `GroupAction/` lemmas, especially `canon_eq_of_mem_orbit`,
  `invariant_const_on_orbit`, and `separating_implies_distinct_orbits`).
- Phase 3 complete (`OrbitEncScheme`, `encrypt`, `decrypt`, `Adversary`,
  `hasAdvantage`, `IsSecure`, `OIA` axiom).

---

## Work Units

### Track A: Correctness (4.1 → 4.2 → 4.3 → 4.4 → 4.5)

Track A proves Headline Result #1: `decrypt(encrypt(g, m)) = some m`. The
original single 5-hour unit (old 4.3) has been split into three focused
pieces: helper infrastructure (4.3), predicate uniqueness (4.4), and the
final assembly (4.5). This isolates the hardest sub-problem —
`Fintype.find?` specification — into its own unit.

---

#### 4.1 — Encrypt-in-Orbit Lemma

**Effort:** 1.5h | **Module:** `Theorems/Correctness.lean` | **Deps:** 3.2, 2.4

```lean
/-- The ciphertext lies in the orbit of the representative. -/
theorem encrypt_mem_orbit [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (g : G) (m : M) :
    encrypt scheme g m ∈ MulAction.orbit G (scheme.reps m) := by
  -- encrypt = g • reps m, which is in orbit G (reps m) by smul_mem_orbit
  unfold encrypt
  exact smul_mem_orbit g (scheme.reps m)
```

**Strategy:**

1. Unfold `encrypt` to expose `g • scheme.reps m`.
2. Apply `smul_mem_orbit` from unit 2.4 (which wraps `MulAction.mem_orbit`).

**Common pitfalls:**

- If `smul_mem_orbit` was defined with explicit `G` argument, you may need
  `@smul_mem_orbit G _ _ g (scheme.reps m)`.
- If Lean cannot unify `encrypt scheme g m` with `g • scheme.reps m` via
  `unfold`, try `show g • scheme.reps m ∈ _` or `change`.

**Fallback approach:** If `unfold encrypt` fails (e.g., because `encrypt` is
defined with `@[irreducible]` or similar), use `simp only [encrypt]` instead.

**Definition of Done:**
- `encrypt_mem_orbit` compiles without `sorry`.
- `#check @encrypt_mem_orbit` shows the expected type.

---

#### 4.2 — Canon-of-Encrypt Lemma

**Effort:** 2h | **Module:** `Theorems/Correctness.lean` | **Deps:** 4.1, 2.6

```lean
/-- Canonical form of a ciphertext equals canonical form of the representative. -/
theorem canon_encrypt [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (g : G) (m : M) :
    scheme.canonForm.canon (encrypt scheme g m) =
    scheme.canonForm.canon (scheme.reps m) := by
  -- Step 1: encrypt is in the orbit of reps m (by 4.1)
  have h_orbit := encrypt_mem_orbit scheme g m
  -- Step 2: Elements in the same orbit have the same canonical form (by 2.6)
  exact canon_eq_of_mem_orbit scheme.canonForm _ _ h_orbit
```

**Strategy (two steps):**

1. Obtain `h_orbit : encrypt scheme g m ∈ orbit G (scheme.reps m)` from 4.1.
2. Apply `canon_eq_of_mem_orbit` (unit 2.6): elements sharing an orbit have
   the same canonical form.

**Common pitfalls:**

- `canon_eq_of_mem_orbit` (from 2.6) returns `canon y = canon x` when
  `y ∈ orbit G x`. Make sure the direction matches. If it returns
  `canon(encrypt ...) = canon(reps m)`, great. If it returns the reverse,
  use `.symm`.
- The proof depends on 2.6's exact signature. If 2.6 was stated with
  `MulAction.orbit G x` vs `Orbcrypt.orbit G x`, adjust the import or
  add a bridge lemma.

**Alternative approach:** Instead of chaining through `canon_eq_of_mem_orbit`,
you can use `canonical_isGInvariant` (unit 2.11) directly:
```lean
  exact canonical_isGInvariant scheme.canonForm g (scheme.reps m)
```
This works because `encrypt scheme g m = g • scheme.reps m` and G-invariance
gives `canon(g • x) = canon(x)`. Choose whichever compiles more cleanly.

**Definition of Done:**
- `canon_encrypt` compiles without `sorry`.
- Both approaches (via 2.6 or via 2.11) are documented as comments.

---

#### 4.3 — Decrypt Helper Infrastructure

**Effort:** 2.5h | **Module:** `Theorems/Correctness.lean` | **Deps:** 3.3

*This is a new unit, extracted from the original 4.3 to isolate the
`Fintype.find?` machinery that was the primary source of difficulty.*

The `decrypt` function uses `Fintype.find?` (or `Finset.univ.find?`) to
search for a message whose canonical form matches the ciphertext's canonical
form. Before proving the main correctness theorem, we need helper lemmas
about this search mechanism.

```lean
/-- The decrypt predicate: does message m' have the same canonical form as ciphertext c? -/
def decryptPred [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (c : X) (m' : M) : Prop :=
  scheme.canonForm.canon c = scheme.canonForm.canon (scheme.reps m')

/-- The decrypt predicate is decidable (since X has DecidableEq). -/
instance decryptPredDecidable [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (c : X) (m' : M) :
    Decidable (decryptPred scheme c m') :=
  inferInstance  -- DecidableEq X gives us this

/-- Rewrite decrypt in terms of decryptPred for easier reasoning. -/
theorem decrypt_eq_find [Group G] [MulAction G X] [DecidableEq X]
    [Fintype M] [DecidableEq M]
    (scheme : OrbitEncScheme G X M) (c : X) :
    decrypt scheme c = Fintype.find? (decryptPred scheme c) := by
  unfold decrypt decryptPred
  rfl  -- or simp [decrypt, decryptPred]
```

**Strategy:**

1. Define `decryptPred` as a named predicate matching the lambda inside
   `decrypt`. This makes proofs cleaner than repeatedly unfolding `decrypt`.
2. Prove `Decidable` for the predicate (needed by `Fintype.find?`).
3. Prove the rewrite lemma linking `decrypt` to `Fintype.find?` applied to
   `decryptPred`.

**Key Mathlib lemma to locate:**

The critical lemma is the specification of `Fintype.find?`:
```
Fintype.find?_some : Fintype.find? p = some a ↔ p a ∧ ∀ b, p b → b = a
```
or equivalently:
```
Fintype.find?_eq_some : Fintype.find? p = some a ↔ p a ∧ ...
```

Search Mathlib for the exact name and signature. If `Fintype.find?` has a
weak specification, **switch to `Finset.univ.find`**:

```lean
-- Alternative: use Finset-based search
def decrypt' ... (c : X) : Option M :=
  (Finset.univ.filter (fun m => decryptPred scheme c m)).toList.head?
```

The `Finset.filter` approach is more verbose but has richer API support.

**Common pitfalls:**

- `Fintype.find?` may not exist in all Mathlib versions. Search for
  `Fintype.choose` or `Fintype.truncRecursor` as alternatives.
- If using `Finset.univ.filter`, the result is a `Finset M`, not `Option M`.
  You need `.min'` or `.toList.head?` to extract a single element.
- Instance resolution for `Decidable (decryptPred ...)` may require
  `DecidableEq X` to be in scope. Make sure the instance is registered.

**Fallback approach (if Fintype.find? is problematic):**

Redesign `decrypt` (back in unit 3.3) to use explicit `Finset` operations:
```lean
def decrypt ... (c : X) : Option M :=
  let matching := Finset.univ.filter (fun m =>
    scheme.canonForm.canon c = scheme.canonForm.canon (scheme.reps m))
  if h : matching.card = 1
  then some (matching.min' (by simp [Finset.card_pos]; omega))
  else none
```
This requires reproving some of the Phase 3 properties but gives better
control over the proof.

**Definition of Done:**
- `decryptPred` defined and `Decidable` instance registered.
- `decrypt_eq_find` compiles (or an equivalent rewrite lemma).
- The critical Mathlib lemma for `Fintype.find?` specification is identified
  and documented in a comment.

---

#### 4.4 — Predicate Uniqueness for Messages

**Effort:** 2h | **Module:** `Theorems/Correctness.lean` | **Deps:** 4.2, 4.3, 2.6

*This is a new unit, extracted from the original 4.3 to isolate the hardest
sub-problem: proving that exactly one message satisfies the decrypt predicate.*

```lean
/-- The decrypt predicate holds for the original message. -/
theorem decryptPred_self [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (g : G) (m : M) :
    decryptPred scheme (encrypt scheme g m) m := by
  -- canon(encrypt g m) = canon(reps m) by canon_encrypt (4.2)
  unfold decryptPred
  exact canon_encrypt scheme g m

/-- No other message satisfies the decrypt predicate. -/
theorem decryptPred_unique [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (g : G) (m m' : M)
    (hPred : decryptPred scheme (encrypt scheme g m) m') :
    m' = m := by
  -- Strategy:
  -- 1. hPred gives canon(encrypt g m) = canon(reps m')
  -- 2. canon_encrypt gives canon(encrypt g m) = canon(reps m)
  -- 3. Therefore canon(reps m') = canon(reps m)
  -- 4. By orbit_iff: orbit G (reps m') = orbit G (reps m)
  -- 5. Contrapositive of reps_distinct: equal orbits imply equal messages
  by_contra h_ne
  have h_canons : scheme.canonForm.canon (scheme.reps m') =
      scheme.canonForm.canon (scheme.reps m) := by
    rw [← hPred]; exact (canon_encrypt scheme g m).symm
  have h_orbits := canon_eq_implies_orbit_eq scheme.canonForm _ _ h_canons
  exact absurd h_orbits (scheme.reps_distinct m' m h_ne)
```

**Strategy (two lemmas):**

1. **Forward direction (`decryptPred_self`):** The predicate holds for `m`
   because `canon(encrypt g m) = canon(reps m)` by `canon_encrypt` (4.2).

2. **Uniqueness (`decryptPred_unique`):** If the predicate holds for `m'`,
   then `canon(reps m') = canon(reps m)`, so their orbits are equal (by
   `canon_eq_implies_orbit_eq` from 2.6). But `reps_distinct` says distinct
   messages have distinct orbits, contradiction.

**Common pitfalls:**

- The direction of `reps_distinct` matters: it says `m₁ ≠ m₂ → orbit(reps m₁) ≠ orbit(reps m₂)`.
  We need the contrapositive: `orbit(reps m₁) = orbit(reps m₂) → m₁ = m₂`.
  Use `by_contra` + `absurd` or prove a separate contrapositive lemma.
- Watch for argument order: `reps_distinct m' m h_ne` vs `reps_distinct m m' h_ne`.
  If the orbit equality direction is wrong, use `.symm`.
- The `h_canons` step chains two equalities. If Lean struggles with the
  rewriting, break it into explicit `have` steps.

**Definition of Done:**
- Both `decryptPred_self` and `decryptPred_unique` compile without `sorry`.
- A quick test: `#check @decryptPred_unique` shows the expected type.

---

#### 4.5 — Decrypt-of-Encrypt Theorem (Headline Result #1)

**Effort:** 2h | **Module:** `Theorems/Correctness.lean` | **Deps:** 4.3, 4.4

```lean
/--
**Correctness Theorem.** Decryption perfectly inverts encryption.
Formalizes DEVELOPMENT.md §4.2: Pr[Dec(Enc(m)) = m] = 1.
-/
theorem correctness [Group G] [MulAction G X] [DecidableEq X]
    [Fintype M] [DecidableEq M]
    (scheme : OrbitEncScheme G X M) (m : M) (g : G) :
    decrypt scheme (encrypt scheme g m) = some m := by
  -- Step 1: Rewrite decrypt in terms of Fintype.find? (4.3)
  rw [decrypt_eq_find]
  -- Step 2: Apply Fintype.find? specification
  --   Need: decryptPred holds for m, and m is unique
  apply Fintype.find?_eq_some.mpr  -- or equivalent
  exact ⟨decryptPred_self scheme g m,
         fun m' hm' => decryptPred_unique scheme g m m' hm'⟩
```

**Strategy:**

1. Rewrite `decrypt` using `decrypt_eq_find` (4.3).
2. Apply the `Fintype.find?` specification lemma (identified in 4.3).
3. Supply the two proof obligations from 4.4:
   - `decryptPred_self`: the predicate holds for `m`.
   - `decryptPred_unique`: `m` is the only element satisfying the predicate.

**Why this is now 2h instead of 5h:** With 4.3 and 4.4 already done, this
proof is essentially just plugging pieces together. The hard work (understanding
`Fintype.find?` and proving uniqueness) is isolated in prior units.

**Common pitfalls:**

- The exact name and signature of `Fintype.find?`'s specification lemma varies
  across Mathlib versions. Common names:
  - `Fintype.find?_eq_some_iff`
  - `Fintype.find?_some`
  - `Finset.find?_eq_some`
  If none exist, prove a custom specification lemma in unit 4.3.

- If using the `Finset.filter` alternative from 4.3, the proof structure
  changes: instead of `Fintype.find?_eq_some`, you show the filter yields
  a singleton `{m}` and extracting from a singleton gives `some m`.

**Alternative assembly (if Fintype.find? spec is weak):**
```lean
  -- Use decidability + uniqueness to construct the proof term directly
  suffices h : ∃! m' : M, decryptPred scheme (encrypt scheme g m) m' from
    ... -- extract from ExistsUnique
  exact ⟨m, decryptPred_self scheme g m,
         fun m' hm' => (decryptPred_unique scheme g m m' hm').symm⟩
```

**Definition of Done:**
- `correctness` compiles without `sorry`.
- `#print axioms correctness` shows only standard Lean axioms (no `OIA`, no `sorry`).
- The proof is ≤ 10 lines of tactic code.

---

### Track B: Invariant Attack (4.6 → 4.7 → 4.8 → 4.9)

Track B proves Headline Result #2: if a G-invariant function separates two
message orbits, an adversary achieves a complete break. The original 4.5
(5 hours) is split into a focused helper (4.7) and the case-split proof (4.8),
isolating the invariance reasoning from the Boolean case analysis.

---

#### 4.6 — Adversary Construction

**Effort:** 2h | **Module:** `Theorems/InvariantAttack.lean` | **Deps:** 3.4, 2.8

```lean
/--
Construct an adversary that uses a separating invariant to break the scheme.
Given f : X → Y with f(x_{m₀}) ≠ f(x_{m₁}) and f G-invariant,
the adversary computes f(c*) and compares to f(x_{m₀}).
-/
def invariantAttackAdversary [DecidableEq Y]
    (f : X → Y) (m₀ m₁ : M) : Adversary X M where
  choose := fun _reps => (m₀, m₁)
  guess := fun reps c => decide (f c = f (reps m₀))
```

**Strategy:**

1. Define the adversary as a simple structure:
   - `choose` always picks the pair `(m₀, m₁)`.
   - `guess` computes `f(c)`, compares to `f(reps m₀)`, returns the Boolean.
2. The `decide` function converts a `Decidable` proposition to `Bool`.
   This requires `DecidableEq Y` so that `f c = f (reps m₀)` is decidable.

**Handling `decide` and `Bool` conversions:**

The `decide` function has type `(p : Prop) → [Decidable p] → Bool`. Key lemmas:

| Lemma | Statement | Use |
|-------|-----------|-----|
| `decide_eq_true_eq` | `decide p = true ↔ p` | Unfold `guess = true` |
| `decide_eq_false_iff_not` | `decide p = false ↔ ¬p` | Unfold `guess = false` |
| `Bool.not_eq_true` | `!b = true ↔ b = false` | Relate `!b` to `b` |

If `decide` causes instance-resolution issues, use an explicit `if-then-else`:
```lean
  guess := fun reps c => if f c = f (reps m₀) then true else false
```
The `if` form is sometimes easier to case-split on in proofs.

**Also define a helper for unfolding the guess:**
```lean
/-- Unfold the guess of the invariant attack adversary. -/
@[simp]
theorem invariantAttackAdversary_guess [DecidableEq Y]
    (f : X → Y) (m₀ m₁ : M) (reps : M → X) (c : X) :
    (invariantAttackAdversary f m₀ m₁).guess reps c =
    decide (f c = f (reps m₀)) := rfl

/-- Unfold the choice of the invariant attack adversary. -/
@[simp]
theorem invariantAttackAdversary_choose [DecidableEq Y]
    (f : X → Y) (m₀ m₁ : M) (reps : M → X) :
    (invariantAttackAdversary f m₀ m₁).choose reps = (m₀, m₁) := rfl
```

**Definition of Done:**
- `invariantAttackAdversary` defined and compiles.
- Both `@[simp]` unfolding lemmas compile.
- `#check invariantAttackAdversary` shows the expected type.

---

#### 4.7 — Invariance Application Helper

**Effort:** 1.5h | **Module:** `Theorems/InvariantAttack.lean` | **Deps:** 2.9

*This is a new unit that isolates the key reasoning step used twice in 4.8.*

```lean
/-- For a G-invariant function, f(g • reps m) = f(reps m).
    This is the bridge between "ciphertext is g • reps m" and
    "the adversary can compute f(reps m) from the ciphertext." -/
theorem invariant_on_encrypt [Group G] [MulAction G X]
    {f : X → Y} (hInv : IsGInvariant (G := G) f)
    (reps : M → X) (g : G) (m : M) :
    f (g • reps m) = f (reps m) :=
  hInv g (reps m)
```

**Strategy:**

This is a direct application of `IsGInvariant` (which says `f(g • x) = f(x)`
for all `g` and `x`). Instantiate with `x := reps m`.

**Why extract this as a separate unit:**

This one-line lemma is used *twice* in unit 4.8 (once for `b = false`, once
for `b = true`). Having it named makes the case-split proof cleaner and
avoids duplicating the invariance argument. It also serves as a useful
"sanity check" that the Phase 2 API works as expected before tackling the
harder proof.

**Common pitfalls:**

- If `IsGInvariant` was defined as `∀ (g : G) (x : X), f (g • x) = f x`,
  then `hInv g (reps m)` is the direct proof. If the argument order differs,
  adjust accordingly.
- Lean may need explicit universe annotations if `Y` is in a different
  universe than `X`. Add `{Y : Type*}` if needed.

**Definition of Done:**
- `invariant_on_encrypt` compiles without `sorry`.
- It is a one-line proof (or `rfl`-like).

---

#### 4.8 — Adversary Correctness by Case Split

**Effort:** 3h | **Module:** `Theorems/InvariantAttack.lean` | **Deps:** 4.6, 4.7

```lean
/-- The invariant attack adversary always guesses correctly.
    When b = false (challenge is m₀), guess = true = !false.
    When b = true (challenge is m₁), guess = false = !true. -/
theorem invariantAttackAdversary_correct [Group G] [MulAction G X]
    [DecidableEq Y]
    (scheme : OrbitEncScheme G X M)
    (f : X → Y) (m₀ m₁ : M)
    (hInv : IsGInvariant (G := G) f)
    (hSep : f (scheme.reps m₀) ≠ f (scheme.reps m₁))
    (g : G) (b : Bool) :
    let A := invariantAttackAdversary f m₀ m₁
    let mb := if b then m₁ else m₀
    A.guess scheme.reps (g • scheme.reps mb) = !b := by
  simp only [invariantAttackAdversary_guess]
  cases b
  case false =>
    -- c = g • reps m₀
    -- f(c) = f(reps m₀) by invariance (4.7)
    -- So decide(f(c) = f(reps m₀)) = decide(True) = true = !false
    simp only [Bool.not_false, ite_false]
    rw [invariant_on_encrypt hInv]
    exact decide_eq_true_eq.mpr rfl
  case true =>
    -- c = g • reps m₁
    -- f(c) = f(reps m₁) by invariance (4.7)
    -- f(reps m₁) ≠ f(reps m₀) by hSep
    -- So decide(f(c) = f(reps m₀)) = decide(False) = false = !true
    simp only [Bool.not_true, ite_true]
    rw [invariant_on_encrypt hInv]
    exact decide_eq_false_iff_not.mpr (Ne.symm hSep)
```

**Strategy (case split on `b`):**

| Case | Ciphertext | f(ciphertext) | Comparison | guess | !b |
|------|-----------|---------------|------------|-------|----|
| `b = false` | `g • reps m₀` | `f(reps m₀)` (by invariance) | `f(reps m₀) = f(reps m₀)` ✓ | `true` | `true` ✓ |
| `b = true` | `g • reps m₁` | `f(reps m₁)` (by invariance) | `f(reps m₁) = f(reps m₀)` ✗ (by `hSep`) | `false` | `false` ✓ |

**Step-by-step for each case:**

1. `cases b` to split.
2. `simp` to unfold the `if b then m₁ else m₀` and the adversary's `guess`.
3. `rw [invariant_on_encrypt hInv]` to replace `f(g • reps m_b)` with `f(reps m_b)`.
4. Close with the appropriate `decide` lemma.

**Common pitfalls:**

- **`simp` over-simplification:** `simp` may rewrite too aggressively and
  produce an unrecognizable goal. Use `simp only [...]` with explicit lemma
  lists instead of bare `simp`.
- **`decide` lemma names:** These vary across Lean/Mathlib versions. Search
  for `decide_eq_true`, `of_decide_eq_true`, `decide_True`, etc.
- **`Ne.symm` direction:** `hSep : f(reps m₀) ≠ f(reps m₁)` but the goal
  needs `f(reps m₁) ≠ f(reps m₀)`. Use `hSep.symm` or `Ne.symm hSep`.
- **`let` in goal:** The `let A := ...` and `let mb := ...` bindings may
  need explicit unfolding. Use `show` or `change` to expose the term.

**Fallback approach (avoid `decide`):**

If `decide` lemmas are hard to use, redefine `guess` without `decide`:
```lean
  guess := fun reps c => if f c = f (reps m₀) then true else false
```
Then the proof uses `if_pos` and `if_neg` instead of `decide_eq_true` and
`decide_eq_false`, which are often easier to work with.

**Definition of Done:**
- `invariantAttackAdversary_correct` compiles without `sorry`.
- Both cases are proved explicitly (not by `decide` on the entire statement).

---

#### 4.9 — Invariant Attack Assembly (Headline Result #2)

**Effort:** 2h | **Module:** `Theorems/InvariantAttack.lean` | **Deps:** 4.6, 4.8

```lean
/--
**Invariant Attack Theorem.** If a G-invariant function separates two message
orbits, an adversary achieves a complete break.
Formalizes DEVELOPMENT.md §4.4 and the lesson of COUNTEREXAMPLE.md.
-/
theorem invariant_attack [Group G] [MulAction G X] [DecidableEq X]
    [DecidableEq Y]
    (scheme : OrbitEncScheme G X M)
    (f : X → Y) (m₀ m₁ : M)
    (hInv : IsGInvariant (G := G) f)
    (hSep : f (scheme.reps m₀) ≠ f (scheme.reps m₁)) :
    ∃ A : Adversary X M, hasAdvantage scheme A := by
  -- Step 1: Exhibit the adversary
  use invariantAttackAdversary f m₀ m₁
  -- Step 2: Show it has advantage
  -- hasAdvantage requires ∃ g₀ g₁ such that guess differs
  -- Use g₀ = g₁ = 1 (identity)
  unfold hasAdvantage
  simp only [invariantAttackAdversary_choose]
  use 1, 1
  -- Now show: guess(reps, 1 • reps m₀) ≠ guess(reps, 1 • reps m₁)
  simp only [one_smul]
  -- guess(reps, reps m₀) = decide(f(reps m₀) = f(reps m₀)) = true
  -- guess(reps, reps m₁) = decide(f(reps m₁) = f(reps m₀)) = false
  simp only [invariantAttackAdversary_guess]
  rw [decide_eq_true_eq.mpr rfl]  -- first guess = true
  -- Second guess: f(reps m₁) ≠ f(reps m₀), so decide gives false
  rw [decide_eq_false_iff_not.mpr (Ne.symm hSep)]
  -- true ≠ false
  exact Bool.noConfusion
```

**Strategy:**

1. Exhibit `invariantAttackAdversary f m₀ m₁`.
2. Unfold `hasAdvantage` and the adversary's `choose`.
3. Witness `g₀ = 1, g₁ = 1` (identity elements). Using the identity
   simplifies the proof since `1 • x = x`.
4. Show the two guesses differ: one is `true` (for `m₀`), the other is
   `false` (for `m₁`, using `hSep`).

**Alternative strategy using 4.8 directly:**
```lean
  -- After use 1, 1 and one_smul simplification:
  have h0 := invariantAttackAdversary_correct scheme f m₀ m₁ hInv hSep 1 false
  have h1 := invariantAttackAdversary_correct scheme f m₀ m₁ hInv hSep 1 true
  simp only [one_smul, Bool.not_false, Bool.not_true, ite_false, ite_true] at h0 h1
  rw [h0, h1]
  exact Bool.noConfusion
```

**Common pitfalls:**

- **`hasAdvantage` unfolding:** `hasAdvantage` uses `let (m₀, m₁) := A.choose reps`.
  This destructuring may not unfold cleanly. If stuck, see unit 4.11 for a
  helper that addresses this pattern. For Track B, the adversary's `choose`
  returns a literal pair `(m₀, m₁)`, so `simp [invariantAttackAdversary_choose]`
  should suffice.
- **`Bool.noConfusion`:** The goal `true ≠ false` is closed by `Bool.noConfusion`
  or `decide` or `trivial`. If none work, try `intro h; exact absurd h (by decide)`.

**Definition of Done:**
- `invariant_attack` compiles without `sorry`.
- `#print axioms invariant_attack` shows only standard Lean axioms (no `OIA`).
