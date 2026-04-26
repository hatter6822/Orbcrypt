# Plan: Discharge `pathAlgebraMul_assoc` (Phase A.2.4)

## Context

`pathAlgebraMul_assoc` is the critical Lean theorem proving multiplicative
associativity for the path-algebra carrier `pathAlgebraQuotient m :=
QuiverArrow m → ℚ`. It lifts the basis-element-level
`pathMul_assoc : Option.bind (pathMul m a b) (fun ab => pathMul m ab c) =
Option.bind (pathMul m b c) (fun bc => pathMul m a bc)` (Track A.1, already
proven) up to the algebra-level statement `(f * g) * h = f * (g * h)`.

This unblocks Phase A.2.5–A.2.10 (Ring + Algebra ℚ typeclass instances),
which in turn unblocks Phase E (AlgEquiv lift) and Phase F (vertex-
permutation extraction via algebra automorphism).

## What went wrong on the first attempt

The first attempt was a single monolithic proof that tried to do
"distribute → reorder → collapse → equate" all at once with `simp_rw`,
`Finset.sum_mul`, `Finset.sum_comm` chained together. The failure modes:

1. **`Finset.sum_comm` doesn't compose with `simp_rw` cleanly** when there
   are 4+ nested sums — the reordering rewrites get applied to inner
   contexts but leave the outer ones unchanged, producing partial-progress
   states that the next `rw` can't match.

2. **The `(if … then 1 else 0)` indicators interact badly with the
   non-canonical `mul`/`add` order produced by `Finset.mul_sum`** —
   `mul_assoc/mul_comm` chains of `ring`-style normalization are needed
   between every distribution step.

3. **The two canonical forms (LHS-canonical, RHS-canonical) need a
   *variable rename* to make them syntactically identical**, which a
   single-shot proof can't do without explicitly naming the bound
   variables.

The fix: **decompose into named helper lemmas, with each lemma doing
exactly one well-defined transformation, and a final composition that
threads them together.**

## Strategy: three-step decomposition

The proof is structured as exactly three components, each in a private
helper lemma:

* **C1 — `pathMul_indicator_collapse`** (~20 lines): the algebraic-tensor
  identity `∑_a [pathMul x y = some a] · [pathMul a b = some c] =
  [bind(pathMul x y, λa. pathMul a b) = some c]`. Independent of the
  algebra structure; pure `Option`-monad calculation.

* **C2 — `pathAlgebraMul_assoc_lhs_canonical`** (~80 lines): proves
  `((f * g) * h) c = ∑_x ∑_y ∑_b f(x) · g(y) · h(b) ·
  [bind(pathMul x y, λa. pathMul a b) = some c]`.

* **C3 — `pathAlgebraMul_assoc_rhs_canonical`** (~80 lines): proves
  `(f * (g * h)) c = ∑_x ∑_y ∑_b f(x) · g(y) · h(b) ·
  [bind(pathMul y b, λa. pathMul x a) = some c]`. Note the variable
  renaming: the RHS's outer `∑_a` and inner `∑_x ∑_y` are renamed
  `(a, x, y) → (x, y, b)` so the canonical forms match the LHS.

* **Top-level `pathAlgebraMul_assoc`** (~10 lines): combines C2 + C3 +
  pathMul_assoc by `Finset.sum_congr` × 3.

This factors the work into independent, verifiable units. Each helper is
small enough to debug individually.

## Mathematical derivation (the answer the proof must reach)

Starting from definitions:
```
pathAlgebraMul m f g c = ∑_{a, b} f(a) · g(b) · [pathMul a b = some c]
```

### LHS expansion

```
((f * g) * h) c
  = ∑_{a, b} (f * g)(a) · h(b) · [pathMul a b = some c]            -- def
  = ∑_{a, b} (∑_{x, y} f(x) · g(y) · [pathMul x y = some a]) · h(b) · [pathMul a b = some c]
                                                                   -- def of f*g
  = ∑_{x, y, a, b} f(x) · g(y) · h(b) · [pathMul x y = some a] · [pathMul a b = some c]
                                                                   -- distribute
  = ∑_{x, y, b} f(x) · g(y) · h(b) · ∑_{a} [pathMul x y = some a] · [pathMul a b = some c]
                                                                   -- factor (x, y, b) outside
  = ∑_{x, y, b} f(x) · g(y) · h(b) · [bind(pathMul x y, λa. pathMul a b) = some c]
                                                                   -- C1 collapse
```

### RHS expansion

```
(f * (g * h)) c
  = ∑_{a, b} f(a) · (g * h)(b) · [pathMul a b = some c]
  = ∑_{a, b} f(a) · (∑_{x, y} g(x) · h(y) · [pathMul x y = some b]) · [pathMul a b = some c]
  = ∑_{a, x, y, b} f(a) · g(x) · h(y) · [pathMul x y = some b] · [pathMul a b = some c]
  = ∑_{a, x, y} f(a) · g(x) · h(y) · ∑_{b} [pathMul x y = some b] · [pathMul a b = some c]
  = ∑_{a, x, y} f(a) · g(x) · h(y) · [bind(pathMul x y, λb. pathMul a b) = some c]
                                                                   -- C1 collapse
```

### Matching via variable rename + pathMul_assoc

Rename the RHS's bound variables `(a, x, y) → (x', y', b')`:
```
RHS = ∑_{x', y', b'} f(x') · g(y') · h(b') · [bind(pathMul y' b', λa. pathMul x' a) = some c]
```

So both sides are sums over `(x, y, b)` with the same factor
`f(x) · g(y) · h(b)` and indicator predicates that differ by:

| Side | Indicator |
|------|-----------|
| LHS  | `bind(pathMul x y, λa. pathMul a b) = some c` |
| RHS  | `bind(pathMul y b, λa. pathMul x a) = some c` |

By `pathMul_assoc x y b` (Track A.1), these indicators are *equal*.
Hence LHS = RHS by `Finset.sum_congr rfl` × 3.

## Detailed Lean proof skeleton

### Component C1 — `pathMul_indicator_collapse`

```lean
private lemma pathMul_indicator_collapse (m : ℕ) (x y b c : QuiverArrow m) :
    (∑ a : QuiverArrow m,
      (if pathMul m x y = some a then (1 : ℚ) else 0) *
      (if pathMul m a b = some c then (1 : ℚ) else 0)) =
    (if Option.bind (pathMul m x y) (fun a => pathMul m a b) = some c
     then (1 : ℚ) else 0) := by
  cases h_pxy : pathMul m x y with
  | none =>
    -- LHS: each term has [pathMul x y = some a] = [none = some a] = 0.
    -- So the sum is 0.
    -- RHS: bind none = none, so [none = some c] = 0.
    have h_zero : ∀ a : QuiverArrow m,
        (if pathMul m x y = some a then (1 : ℚ) else 0) = 0 := by
      intro a; rw [h_pxy]; simp
    simp_rw [h_zero, zero_mul, Finset.sum_const_zero]
    -- RHS = 0
    rw [h_pxy]; simp
  | some a₀ =>
    -- LHS: ∑_a [some a₀ = some a] · [pathMul a b = c]
    -- The unique non-zero term is at a = a₀: 1 · [pathMul a₀ b = c].
    -- RHS: bind(some a₀, λa. pathMul a b) = pathMul a₀ b. So [...] = [pathMul a₀ b = c].
    rw [Finset.sum_eq_single a₀]
    · -- main term
      rw [h_pxy]
      simp
    · -- other terms vanish
      intros a _ ha
      rw [h_pxy]
      simp
      intro h_eq
      exact ha (Option.some.inj h_eq).symm
    · -- a₀ ∈ univ
      intro h_not; exact absurd (Finset.mem_univ a₀) h_not
```

**Risk: low.** Standard Mathlib `Finset.sum_eq_single` + `Option.some.inj`
chain. Each branch is ≤ 5 tactic lines.

### Component C2 — `pathAlgebraMul_assoc_lhs_canonical`

```lean
private lemma pathAlgebraMul_assoc_lhs_canonical (m : ℕ)
    (f g h : pathAlgebraQuotient m) (c : QuiverArrow m) :
    (pathAlgebraMul m (pathAlgebraMul m f g) h) c =
    ∑ x : QuiverArrow m, ∑ y : QuiverArrow m, ∑ b : QuiverArrow m,
      f x * g y * h b *
      (if Option.bind (pathMul m x y) (fun a => pathMul m a b) = some c
       then (1 : ℚ) else 0) := by
  -- Step 1: unfold to ∑_{a,b} (∑_{x,y} f x · g y · [pxy=a]) · h b · [pab=c]
  show (∑ a, ∑ b, (∑ x, ∑ y,
          f x * g y * (if pathMul m x y = some a then (1:ℚ) else 0))
        * h b * (if pathMul m a b = some c then (1:ℚ) else 0)) = _
  -- Step 2: distribute the inner sum out via Finset.sum_mul × 2.
  -- Each (∑_x ∑_y E) · h b · I = ∑_x ∑_y (E · h b · I).
  conv_lhs =>
    ext a; ext b
    rw [Finset.sum_mul, Finset.sum_mul]
    -- Now: ∑_a ∑_b ∑_x ∑_y (f x · g y · [pxy=a]) · h b · [pab=c]
    -- which by mul_assoc reorder = ∑_x ∑_y f x · g y · h b · [pxy=a] · [pab=c]
    ext x; ext y
    ring_nf
  -- Step 3: reorder ∑_a, ∑_b, ∑_x, ∑_y so that ∑_a is innermost.
  -- Currently: ∑_a ∑_b ∑_x ∑_y (f x · g y · [pxy=a] · h b · [pab=c])
  -- Goal:      ∑_x ∑_y ∑_b ∑_a (...) — so ∑_a is innermost.
  rw [Finset.sum_comm]               -- swap a ↔ b: ∑_b ∑_a ∑_x ∑_y
  conv_lhs => ext b; rw [Finset.sum_comm]  -- swap a ↔ x: ∑_b ∑_x ∑_a ∑_y
  -- Continue rearranging until ∑_a is innermost...
  -- (Detailed sequence in implementation; uses Finset.sum_comm + conv_lhs ext.)
  -- After full reordering: ∑_x ∑_y ∑_b ∑_a (f x · g y · h b · [pxy=a] · [pab=c])
  --                      = ∑_x ∑_y ∑_b f x · g y · h b · (∑_a [pxy=a] · [pab=c])
  -- Step 4: factor the (x, y, b)-dependent factors outside the ∑_a.
  -- Goal: pull `f x · g y · h b` outside the ∑_a using Finset.mul_sum.
  conv_lhs =>
    ext x; ext y; ext b
    rw [show (∑ a : QuiverArrow m, f x * g y * h b *
              ((if pathMul m x y = some a then (1:ℚ) else 0) *
               (if pathMul m a b = some c then (1:ℚ) else 0))) =
            f x * g y * h b *
            (∑ a : QuiverArrow m,
              (if pathMul m x y = some a then (1:ℚ) else 0) *
              (if pathMul m a b = some c then (1:ℚ) else 0))
       from (Finset.mul_sum _ _ _).symm]
  -- Step 5: apply C1 (pathMul_indicator_collapse) to simplify the inner ∑_a.
  conv_lhs =>
    ext x; ext y; ext b
    rw [pathMul_indicator_collapse m x y b c]
```

**Risk: medium.** The reordering (Step 3) requires multiple sequential
`Finset.sum_comm` invocations under `conv_lhs ext`. Each step is
mechanical but the order matters. Anticipated to take ~80 lines.

**Mitigation if Step 3 stalls:** use `Finset.sum_sigma` to flatten the
∑_a ∑_b ∑_x ∑_y into a single sum over `(a, b, x, y) : Σ Σ Σ Σ`, then
use `Finset.sum_bij` to relabel the index, avoiding direct `sum_comm`
manipulation. Adds ~30 LOC but avoids the conv-tactic plumbing.

### Component C3 — `pathAlgebraMul_assoc_rhs_canonical`

```lean
private lemma pathAlgebraMul_assoc_rhs_canonical (m : ℕ)
    (f g h : pathAlgebraQuotient m) (c : QuiverArrow m) :
    (pathAlgebraMul m f (pathAlgebraMul m g h)) c =
    ∑ x : QuiverArrow m, ∑ y : QuiverArrow m, ∑ b : QuiverArrow m,
      f x * g y * h b *
      (if Option.bind (pathMul m y b) (fun a => pathMul m x a) = some c
       then (1 : ℚ) else 0) := by
  -- Symmetric structure to C2:
  --
  -- Start: (f * (g * h)) c = ∑_{a,b} f a · (g*h)(b) · [pab=c]
  --                       = ∑_{a,b} f a · (∑_{x,y} g x · h y · [pxy=b]) · [pab=c]
  --                       = ∑_{a,x,y,b} f a · g x · h y · [pxy=b] · [pab=c]
  --
  -- Reorder: ∑_a ∑_x ∑_y ∑_b — pull ∑_b innermost.
  -- Factor (a, x, y) outside ∑_b:
  --   = ∑_{a,x,y} f a · g x · h y · (∑_b [pxy=b] · [pab=c])
  -- Apply C1 (with renamed variables):
  --   = ∑_{a,x,y} f a · g x · h y · [bind(pxy, λb. pab) = c]
  --
  -- Final relabel (a, x, y) → (x, y, b) for canonical-form comparison:
  --   = ∑_{x,y,b} f x · g y · h b · [bind(pyb, λa. pxa) = c]
  -- via `Finset.sum_congr rfl (fun ...)` with the dummy variable rename.
  show (∑ a, ∑ b, f a * (∑ x, ∑ y,
          g x * h y * (if pathMul m x y = some b then (1:ℚ) else 0))
        * (if pathMul m a b = some c then (1:ℚ) else 0)) = _
  conv_lhs =>
    ext a; ext b
    rw [Finset.mul_sum, Finset.sum_mul, Finset.mul_sum, Finset.sum_mul]
    ext x; ext y
    ring_nf
  -- Reorder: ∑_a ∑_b ∑_x ∑_y → ∑_a ∑_x ∑_y ∑_b
  conv_lhs =>
    ext a
    rw [show (∑ b, ∑ x, ∑ y, _) = (∑ x, ∑ y, ∑ b, _) from by
      rw [Finset.sum_comm]; ext x
      rw [Finset.sum_comm]]
  -- Factor (a, x, y) outside ∑_b
  conv_lhs =>
    ext a; ext x; ext y
    rw [← Finset.mul_sum]
  -- Apply C1 with renamed vars
  conv_lhs =>
    ext a; ext x; ext y
    rw [pathMul_indicator_collapse m x y a c]
  -- Final variable rename: (a, x, y) → (x, y, b) via Finset.sum_comm
  rw [Finset.sum_comm]               -- swap (a, x): ∑_x ∑_a ∑_y
  conv_lhs => ext x; rw [Finset.sum_comm]  -- swap (a, y): ∑_x ∑_y ∑_a
  -- Now the variable a corresponds to the outer x of canonical form;
  -- rename via Finset.sum_congr with explicit α-substitution.
```

**Risk: medium-high.** The variable rename at the end requires either
implicit α-equivalence (which Lean should handle automatically) or an
explicit `Finset.sum_congr` chain. Anticipated to take ~80 lines.

**Mitigation if α-equivalence isn't automatic:** define the canonical form
explicitly with named variables and use `Finset.sum_bij` with the
identity bijection (renamed). Adds ~20 LOC.

### Top-level `pathAlgebraMul_assoc`

```lean
theorem pathAlgebraMul_assoc (m : ℕ)
    (f g h : pathAlgebraQuotient m) :
    pathAlgebraMul m (pathAlgebraMul m f g) h =
    pathAlgebraMul m f (pathAlgebraMul m g h) := by
  funext c
  rw [pathAlgebraMul_assoc_lhs_canonical m f g h c,
      pathAlgebraMul_assoc_rhs_canonical m f g h c]
  -- Both sides: ∑_x ∑_y ∑_b f x · g y · h b · [indicator]
  -- LHS indicator: bind(pathMul x y, λa. pathMul a b) = some c
  -- RHS indicator: bind(pathMul y b, λa. pathMul x a) = some c
  -- Equal by pathMul_assoc x y b.
  apply Finset.sum_congr rfl; intro x _
  apply Finset.sum_congr rfl; intro y _
  apply Finset.sum_congr rfl; intro b _
  congr 1
  congr 1
  exact pathMul_assoc m x y b
```

**Risk: low** if C2 and C3 land. Pure composition.

## Failure-mode analysis (per step)

### C1 failure modes

| Issue | Mitigation |
|-------|-----------|
| `Option.some.inj` not found | Use `Option.injective_some` or `Option.some_injective` (Mathlib name varies); fallback to `intro h; injection h` |
| `Finset.sum_const_zero` doesn't fire | Replace with `Finset.sum_eq_zero` + per-term zero proof |
| Polymorphic `0 ≠ 0` confusion in ℚ | Add explicit `(0 : ℚ)` annotations |

### C2 failure modes

| Issue | Mitigation |
|-------|-----------|
| `Finset.sum_mul` doesn't distribute under `conv_lhs ext` | Use top-level `simp_rw [Finset.sum_mul]` instead |
| `ring_nf` fails on indicator-times-other terms | Manually call `mul_comm`, `mul_assoc` to reorder |
| `Finset.sum_comm` swaps don't compose | Use `Finset.sum_sigma` to flatten then re-split |
| `conv` tactic state inscrutable | Replace `conv` with explicit `have h_step1 : LHS = ... := by ...; rw [h_step1]` chain |

### C3 failure modes

Same as C2, plus:
- **Variable rename at the end may need explicit `Finset.sum_bij`.** If
  Lean doesn't accept the α-equivalent form directly, define
  ```
  Finset.sum_bij (i := id) (h_inj := ...) (h_surj := ...) (h_eq := ...)
  ```
  This is the canonical Mathlib idiom for "rename bound variables in a sum".

## Implementation order

1. **C1 first.** Compile and verify in isolation. ~20 lines.
2. **C2 second.** Compile and verify; if Step 3 (reordering) stalls,
   pivot to `Finset.sum_sigma` flattening. ~80 lines.
3. **C3 third.** Mirror of C2 with the variable rename. ~80 lines.
4. **Top-level last.** Compose. ~10 lines.

**Total estimated lines: ~190 LOC.**

## Alternative: `Finset.sum_sigma` flattening (backup plan)

If `Finset.sum_comm` chains prove too tangled, switch to flattening via
`Finset.sum_sigma`:

```lean
∑ a, ∑ b, ∑ x, ∑ y, F a b x y
  = ∑ p : Σ a, Σ b, Σ x, Fin _, F p.1 p.2.1 p.2.2.1 p.2.2.2
  = ∑ p' : Σ x, Σ y, Σ b, Fin _, F p'.2.2.1 p'.2.2.2 p'.1 p'.2.1
                                      -- relabeled via Finset.sum_bij
```

The `Finset.sum_bij` invocation rebinds the four sigma-projection
indices, equivalent to a 4-variable rename. This is cleaner than
chained `sum_comm` for ≥ 3 nested sums.

## Risk register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| C1 takes longer than 20 lines | low | low | extra 30 LOC budget |
| Step 3 of C2 (reordering) stalls | medium | high | switch to `Finset.sum_sigma` flattening |
| Variable rename at end of C3 fails | medium | medium | use explicit `Finset.sum_bij` |
| `ring_nf` doesn't normalize indicator products | low | medium | manual `mul_comm`/`mul_assoc` chain |
| Total exceeds 300 LOC | medium | low | acceptable; budget pads to 400 |

## Verification

After all four components land:
1. `lake build Orbcrypt.Hardness.GrochowQiao.AlgebraWrapper` — must succeed
   with zero warnings, zero errors.
2. `#print axioms pathAlgebraMul_assoc` — must return only standard Lean
   trio (`propext`, `Classical.choice`, `Quot.sound`).
3. Concrete non-vacuity test in audit script:
   ```lean
   example (m : ℕ) (v : Fin m) :
     pathAlgebraMul m (pathAlgebraMul m
         (vertexIdempotent m v) (vertexIdempotent m v))
         (vertexIdempotent m v) =
     pathAlgebraMul m (vertexIdempotent m v)
         (pathAlgebraMul m (vertexIdempotent m v) (vertexIdempotent m v)) :=
     pathAlgebraMul_assoc m _ _ _
   ```

## Downstream unblocked work

Once `pathAlgebraMul_assoc` lands:
- A.2.5: `pathAlgebraOne` + One instance.
- A.2.6: `one_mul`, `mul_one`.
- A.2.7: `left_distrib`, `right_distrib`.
- A.2.8: `mul_zero`, `zero_mul`.
- A.2.9: `Ring (pathAlgebraQuotient m)` instance.
- A.2.10: `Algebra ℚ (pathAlgebraQuotient m)` instance.
- A.2.11: `pathAlgebra_decompose`.
- A.2.12: free basis on `QuiverArrow m`.

These are all mechanical follow-ons (~300 LOC total).

## Summary

`pathAlgebraMul_assoc` is structurally hard because of the 4-nested-sum
manipulation, but mathematically straightforward (it's `pathMul_assoc`
lifted to linear combinations). The fix for the previous failure is to
**decompose into 3 named helper lemmas** (C1 + C2 + C3) with a 10-line
top-level composition, rather than attempting a single monolithic proof.
Each helper has explicit failure-mode mitigations.

**Total estimated work: ~200 LOC, single-day implementation.**

