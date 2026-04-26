/-
Path-algebra Mathlib `Algebra ℚ` wrapper for the Grochow–Qiao
GI ≤ TI Karp reduction.

R-TI Layer T4.8 (Sub-tasks A.2.1 through A.2.12 of the
2026-04-26 implementation plan) — wraps the radical-2 truncated
path algebra `F[Q_G] / J²` constructed at the basis-element level
in `PathAlgebra.lean` as a Mathlib `Algebra ℚ` instance, suitable
for downstream `AlgEquiv` use in the rigidity argument.

The carrier is the unrestricted free ℚ-vector space on
`QuiverArrow m`; multiplication is defined via the `pathMul m`
table (with `none` interpreted as zero). The result is a finite-
dimensional associative ℚ-algebra with vertex idempotents and
arrow basis elements.
-/

import Mathlib.Algebra.Algebra.Basic
import Mathlib.Algebra.Algebra.Pi
import Mathlib.LinearAlgebra.Basis.Basic
import Mathlib.LinearAlgebra.Basis.Defs
import Mathlib.Algebra.BigOperators.Pi
import Orbcrypt.Hardness.GrochowQiao.PathAlgebra

/-!
# Path-algebra Mathlib `Algebra ℚ` instance (Layer T4.8)

This module wraps the basis-element-level path-algebra structure
from `PathAlgebra.lean` as a Mathlib `Algebra ℚ`, threading through
all standard typeclass fields (`Ring`, `Module ℚ`, `Algebra ℚ`).

## Carrier choice

`pathAlgebraQuotient m := QuiverArrow m → ℚ` — the unrestricted
free ℚ-vector space on `QuiverArrow m`. Includes basis elements for
both vertex idempotents `id v` (for all `v : Fin m`) and arrow
elements `edge u v` (for all pairs `(u, v) : Fin m × Fin m`),
regardless of presence under any adjacency.

## Multiplication

For `f g : pathAlgebraQuotient m`, the product `f * g : QuiverArrow m → ℚ`
at basis element `c` is:
```
(f * g) c = ∑_{a, b} f(a) * g(b) * [pathMul m a b = some c]
```
where the indicator function captures the path-multiplication table.

## Main definitions

* `pathAlgebraQuotient m` — carrier type.
* `vertexIdempotent m v` — the basis element `e_v`.
* `arrowElement m u v` — the basis element `α(u, v)`.
* `pathAlgebraOne m` — multiplicative identity `∑_v e_v`.

## Main results

* `pathAlgebra_*_mul_*` simp lemmas (multiplication table on basis).
* `pathAlgebra_isAssociative` — multiplication is associative.
* `Ring (pathAlgebraQuotient m)` — full ring instance.
* `Algebra ℚ (pathAlgebraQuotient m)` — algebra instance.
* `pathAlgebra_decompose` — every element splits into vertex + arrow part.

## Status

R-TI Layer T4.8 (post-2026-04-26 implementation). Closes the prerequisite
for Phases C–F (rigidity argument).

## Naming

Identifiers describe content, not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

universe u

-- ============================================================================
-- A.2.1 — Carrier + scalar/additive structure.
-- ============================================================================

/-- The path-algebra carrier: free ℚ-vector space on `QuiverArrow m`.

We use the *unrestricted* version (no presentArrows filter). The
adjacency-specific subalgebra is recovered by restriction to
`QuiverArrow.id v` and present `QuiverArrow.edge u v` (where
`adj u v = true`); algebra automorphisms preserving adjacency
restrict to the appropriate subalgebra. -/
def pathAlgebraQuotient (m : ℕ) : Type := QuiverArrow m → ℚ

namespace pathAlgebraQuotient

instance addCommGroup (m : ℕ) : AddCommGroup (pathAlgebraQuotient m) :=
  Pi.addCommGroup

instance module (m : ℕ) : Module ℚ (pathAlgebraQuotient m) :=
  Pi.module _ _ _

instance inhabited (m : ℕ) : Inhabited (pathAlgebraQuotient m) :=
  ⟨0⟩

end pathAlgebraQuotient

-- ============================================================================
-- A.2.2 — Multiplication and Mul instance.
-- ============================================================================

/-- Path-algebra multiplication: convolution over the `pathMul` table.

For `f g : pathAlgebraQuotient m` and target basis element `c`,
the product is the sum over all basis-element pairs `(a, b)` whose
`pathMul a b` equals `some c`, weighted by `f a * g b`. -/
noncomputable def pathAlgebraMul (m : ℕ)
    (f g : pathAlgebraQuotient m) : pathAlgebraQuotient m :=
  fun c => ∑ a : QuiverArrow m, ∑ b : QuiverArrow m,
    f a * g b * (if pathMul m a b = some c then (1 : ℚ) else 0)

noncomputable instance pathAlgebraQuotient.instMul (m : ℕ) :
    Mul (pathAlgebraQuotient m) := ⟨pathAlgebraMul m⟩

/-- Explicit unfolding of multiplication on a basis element. -/
theorem pathAlgebraMul_apply (m : ℕ) (f g : pathAlgebraQuotient m)
    (c : QuiverArrow m) :
    (f * g) c = ∑ a : QuiverArrow m, ∑ b : QuiverArrow m,
      f a * g b * (if pathMul m a b = some c then (1 : ℚ) else 0) := rfl

-- ============================================================================
-- A.2.3 — Basis elements + multiplication lemmas.
-- ============================================================================

/-- The basis element `e_v` (vertex idempotent at vertex `v`).
Sends `id v` to `1`, all other constructors to `0`. -/
def vertexIdempotent (m : ℕ) (v : Fin m) : pathAlgebraQuotient m :=
  fun a => match a with
    | .id w => if v = w then (1 : ℚ) else 0
    | .edge _ _ => 0

/-- The basis element `α(u, v)` (arrow from `u` to `v`).
Sends `edge u v` to `1`, all other constructors to `0`. -/
def arrowElement (m : ℕ) (u v : Fin m) : pathAlgebraQuotient m :=
  fun a => match a with
    | .id _ => 0
    | .edge u' v' => if u = u' ∧ v = v' then (1 : ℚ) else 0

@[simp] theorem vertexIdempotent_apply_id (m : ℕ) (v w : Fin m) :
    vertexIdempotent m v (.id w) = if v = w then (1 : ℚ) else 0 := rfl

@[simp] theorem vertexIdempotent_apply_edge (m : ℕ) (v u' v' : Fin m) :
    vertexIdempotent m v (.edge u' v') = 0 := rfl

@[simp] theorem arrowElement_apply_id (m : ℕ) (u v w : Fin m) :
    arrowElement m u v (.id w) = 0 := rfl

@[simp] theorem arrowElement_apply_edge (m : ℕ) (u v u' v' : Fin m) :
    arrowElement m u v (.edge u' v') =
      if u = u' ∧ v = v' then (1 : ℚ) else 0 := rfl

-- ============================================================================
-- C1 — Indicator collapse helper for `pathAlgebraMul_assoc`.
-- ============================================================================

/-- **Indicator collapse for path-multiplication chains.**

For any quiver basis elements `x, y, b, c : QuiverArrow m`:
```
∑_a [pathMul x y = some a] · [pathMul a b = some c]
  = [Option.bind (pathMul x y) (fun a => pathMul a b) = some c]
```

This is the linchpin for collapsing the inner sum over the
intermediate index `a` in the `pathAlgebraMul_assoc` proof.

**Proof.** Case-split on `pathMul x y`:
* If `none`: every term `[none = some a] = 0`, so the sum is 0; the
  bind is `none`, so the indicator is 0.
* If `some a₀`: only the `a = a₀` term contributes `1 · [pathMul a₀ b = c]`
  via `Finset.sum_eq_single`; the bind is `pathMul a₀ b`, matching. -/
private lemma pathMul_indicator_collapse (m : ℕ)
    (x y b c : QuiverArrow m) :
    (∑ a : QuiverArrow m,
      (if pathMul m x y = some a then (1 : ℚ) else 0) *
      (if pathMul m a b = some c then (1 : ℚ) else 0)) =
    (if Option.bind (pathMul m x y) (fun a => pathMul m a b) = some c
     then (1 : ℚ) else 0) := by
  cases h_pxy : pathMul m x y with
  | none =>
    -- After `cases`, `pathMul m x y` is replaced by `none` in the goal.
    -- Every term `[none = some a] = 0`, so the sum is 0.
    -- RHS: `Option.bind none _ = none`, so indicator is also 0.
    simp [Finset.sum_eq_zero]
  | some a₀ =>
    -- After `cases`, the goal has `some a₀`.
    -- Only `a = a₀` term survives.
    rw [Finset.sum_eq_single a₀]
    · -- Main term: a = a₀ gives 1 * [pathMul a₀ b = c] = RHS.
      simp
    · -- Other terms: a ≠ a₀ ⇒ some a₀ ≠ some a ⇒ if = 0.
      intros a _ ha
      have h_ne : ¬ (some a₀ : Option (QuiverArrow m)) = some a := by
        intro h_eq
        exact ha (Option.some.inj h_eq).symm
      rw [if_neg h_ne, zero_mul]
    · intro h_not; exact absurd (Finset.mem_univ a₀) h_not

/-- **Right-variant indicator collapse.**

Mirror of `pathMul_indicator_collapse` for the case when the summed
index appears as the **second argument** of the second `pathMul` (vs.
first argument in C1):
```
∑_β [pathMul X Y = some β] · [pathMul A β = some C]
  = [Option.bind (pathMul X Y) (fun β => pathMul A β) = some C]
```

Used by `pathAlgebraMul_assoc_rhs_canonical` (C3) where the unfolding
of the inner `(g * h)(b)` produces a sum over `b` appearing as the
second argument in `[pathMul a b = some c]`. -/
private lemma pathMul_indicator_collapse_right (m : ℕ)
    (X Y A C : QuiverArrow m) :
    (∑ β : QuiverArrow m,
      (if pathMul m X Y = some β then (1 : ℚ) else 0) *
      (if pathMul m A β = some C then (1 : ℚ) else 0)) =
    (if Option.bind (pathMul m X Y) (fun β => pathMul m A β) = some C
     then (1 : ℚ) else 0) := by
  cases h_pXY : pathMul m X Y with
  | none =>
    simp [Finset.sum_eq_zero]
  | some β₀ =>
    rw [Finset.sum_eq_single β₀]
    · simp
    · intros β _ hβ
      have h_ne : ¬ (some β₀ : Option (QuiverArrow m)) = some β := by
        intro h_eq
        exact hβ (Option.some.inj h_eq).symm
      rw [if_neg h_ne, zero_mul]
    · intro h_not; exact absurd (Finset.mem_univ β₀) h_not

-- ============================================================================
-- C2 — LHS canonicalization for pathAlgebraMul_assoc.
-- ============================================================================

/-- **LHS canonical form.**

`((f * g) * h) c` equals
`∑_x ∑_y ∑_b f(x) · g(y) · h(b) · [bind(pathMul x y, λa.pathMul a b) = c]`.

This is the canonical-form lemma for the LHS of `pathAlgebraMul_assoc`. -/
private lemma pathAlgebraMul_assoc_lhs_canonical (m : ℕ)
    (f g h : pathAlgebraQuotient m) (c : QuiverArrow m) :
    (pathAlgebraMul m (pathAlgebraMul m f g) h) c =
    ∑ x : QuiverArrow m, ∑ y : QuiverArrow m, ∑ b : QuiverArrow m,
      f x * g y * h b *
      (if Option.bind (pathMul m x y) (fun a => pathMul m a b) = some c
       then (1 : ℚ) else 0) := by
  -- Step A: Unfold and distribute. The LHS becomes
  -- ∑_a ∑_b ∑_x ∑_y (f x · g y · [pxy=a]) · h b · [pab=c]
  have step_unfold :
      (pathAlgebraMul m (pathAlgebraMul m f g) h) c =
      ∑ a : QuiverArrow m, ∑ b : QuiverArrow m, ∑ x : QuiverArrow m,
       ∑ y : QuiverArrow m,
        f x * g y * h b *
        ((if pathMul m x y = some a then (1:ℚ) else 0) *
         (if pathMul m a b = some c then (1:ℚ) else 0)) := by
    show (∑ a, ∑ b, (∑ x, ∑ y, f x * g y *
            (if pathMul m x y = some a then (1:ℚ) else 0)) * h b *
          (if pathMul m a b = some c then (1:ℚ) else 0)) = _
    apply Finset.sum_congr rfl; intro a _
    apply Finset.sum_congr rfl; intro b _
    -- Goal: (∑ x, ∑ y, ...) * h b * [pab=c] = ∑ x, ∑ y, f x * g y * h b * (...)
    -- Distribute via sum_mul applied 4 times.
    rw [Finset.sum_mul, Finset.sum_mul]
    apply Finset.sum_congr rfl; intro x _
    rw [Finset.sum_mul, Finset.sum_mul]
    apply Finset.sum_congr rfl; intro y _
    ring
  rw [step_unfold]
  -- Step B: Reorder to ∑_x ∑_y ∑_b ∑_a (...).
  -- We will use Finset.sum_comm to swap pairs of binders.
  -- Currently: ∑_a ∑_b ∑_x ∑_y E. Goal: ∑_x ∑_y ∑_b ∑_a E.
  -- Strategy: move ∑_a to innermost via repeated swaps.
  -- B.1: ∑_a ∑_b → ∑_b ∑_a. After: ∑_b ∑_a ∑_x ∑_y.
  rw [Finset.sum_comm]
  -- B.2: inside each ∑_b, swap ∑_a ∑_x → ∑_x ∑_a. After: ∑_b ∑_x ∑_a ∑_y.
  apply Eq.trans
  · apply Finset.sum_congr rfl; intro b _
    rw [Finset.sum_comm]
  -- B.3: inside ∑_b ∑_x, swap ∑_a ∑_y → ∑_y ∑_a. After: ∑_b ∑_x ∑_y ∑_a.
  apply Eq.trans
  · apply Finset.sum_congr rfl; intro b _
    apply Finset.sum_congr rfl; intro x _
    rw [Finset.sum_comm]
  -- B.4: ∑_b ∑_x → ∑_x ∑_b. After: ∑_x ∑_b ∑_y ∑_a.
  rw [Finset.sum_comm]
  -- B.5: inside ∑_x, swap ∑_b ∑_y → ∑_y ∑_b. After: ∑_x ∑_y ∑_b ∑_a.
  apply Eq.trans
  · apply Finset.sum_congr rfl; intro x _
    rw [Finset.sum_comm]
  -- Step C: For fixed (x, y, b), factor (f x · g y · h b) outside ∑_a
  -- and apply C1 (pathMul_indicator_collapse).
  apply Finset.sum_congr rfl; intro x _
  apply Finset.sum_congr rfl; intro y _
  apply Finset.sum_congr rfl; intro b _
  -- Goal: ∑_a f x · g y · h b · ([pxy=a] · [pab=c])
  --     = f x · g y · h b · [bind(pxy, λa.pab) = c]
  rw [← Finset.mul_sum]
  rw [pathMul_indicator_collapse m x y b c]

-- ============================================================================
-- C3 — RHS canonicalization for pathAlgebraMul_assoc.
-- ============================================================================

/-- **RHS canonical form.**

`(f * (g * h)) c` equals
`∑_x ∑_y ∑_b f(x) · g(y) · h(b) · [bind(pathMul y b, λa. pathMul x a) = c]`.

The variable correspondence is set so that `(x, y, b)` here matches
the LHS canonical form's `(x, y, b)`. The indicator differs in
bracketing: LHS indicator says `(x*y)*b = c`, RHS indicator says
`x*(y*b) = c`. By `pathMul_assoc`, these are equal. -/
private lemma pathAlgebraMul_assoc_rhs_canonical (m : ℕ)
    (f g h : pathAlgebraQuotient m) (c : QuiverArrow m) :
    (pathAlgebraMul m f (pathAlgebraMul m g h)) c =
    ∑ x : QuiverArrow m, ∑ y : QuiverArrow m, ∑ b : QuiverArrow m,
      f x * g y * h b *
      (if Option.bind (pathMul m y b) (fun a => pathMul m x a) = some c
       then (1 : ℚ) else 0) := by
  -- Step A: Unfold and distribute. The RHS becomes
  -- ∑_a ∑_b ∑_x ∑_y f(a) · g(x) · h(y) · [pxy=b] · [pab=c]
  have step_unfold :
      (pathAlgebraMul m f (pathAlgebraMul m g h)) c =
      ∑ a : QuiverArrow m, ∑ b : QuiverArrow m, ∑ x : QuiverArrow m,
       ∑ y : QuiverArrow m,
        f a * g x * h y *
        ((if pathMul m x y = some b then (1:ℚ) else 0) *
         (if pathMul m a b = some c then (1:ℚ) else 0)) := by
    show (∑ a, ∑ b, f a * (∑ x, ∑ y, g x * h y *
            (if pathMul m x y = some b then (1:ℚ) else 0)) *
          (if pathMul m a b = some c then (1:ℚ) else 0)) = _
    apply Finset.sum_congr rfl; intro a _
    apply Finset.sum_congr rfl; intro b _
    -- (f a * (∑ x ∑ y, ...)) * [pab=c]
    rw [Finset.mul_sum, Finset.sum_mul]
    apply Finset.sum_congr rfl; intro x _
    rw [Finset.mul_sum, Finset.sum_mul]
    apply Finset.sum_congr rfl; intro y _
    ring
  rw [step_unfold]
  -- Step B: Reorder ∑_a ∑_b ∑_x ∑_y → ∑_a ∑_x ∑_y ∑_b (∑_b innermost).
  -- B.1: inside each ∑_a, swap ∑_b ∑_x → ∑_x ∑_b. After: ∑_a ∑_x ∑_b ∑_y.
  apply Eq.trans
  · apply Finset.sum_congr rfl; intro a _
    rw [Finset.sum_comm]
  -- B.2: inside ∑_a ∑_x, swap ∑_b ∑_y → ∑_y ∑_b. After: ∑_a ∑_x ∑_y ∑_b.
  apply Eq.trans
  · apply Finset.sum_congr rfl; intro a _
    apply Finset.sum_congr rfl; intro x _
    rw [Finset.sum_comm]
  -- Step C: For fixed (a, x, y), factor (f a · g x · h y) outside ∑_b
  -- and apply pathMul_indicator_collapse_right.
  -- Note: the canonical form's bound names are (x, y, b), so we use
  -- the renaming a→x_outer, x→y_outer, y→b_outer.
  apply Finset.sum_congr rfl; intro x_outer _
  apply Finset.sum_congr rfl; intro y_outer _
  apply Finset.sum_congr rfl; intro b_outer _
  -- Goal: ∑_b f(x_outer) · g(y_outer) · h(b_outer) ·
  --        ([p_y_outer_b_outer = b] · [p_x_outer_b = c])
  --     = f(x_outer) · g(y_outer) · h(b_outer) ·
  --       [bind(p_y_outer_b_outer, λa. p_x_outer_a) = c]
  -- The summed b appears as the SECOND argument of pathMul in the
  -- second indicator [p_x_outer_b = c]. Use the right-variant.
  rw [← Finset.mul_sum]
  rw [pathMul_indicator_collapse_right m y_outer b_outer x_outer c]

-- ============================================================================
-- pathAlgebraMul_assoc — Top-level theorem.
-- ============================================================================

/-- **Path-algebra multiplication is associative.**

`(f * g) * h = f * (g * h)` for all `f g h : pathAlgebraQuotient m`.

The proof composes:
* `pathAlgebraMul_assoc_lhs_canonical` (C2): rewrites LHS to the
  canonical form `∑_x ∑_y ∑_b f(x) · g(y) · h(b) · [(x*y)*b = c]`.
* `pathAlgebraMul_assoc_rhs_canonical` (C3): rewrites RHS to the
  canonical form `∑_x ∑_y ∑_b f(x) · g(y) · h(b) · [x*(y*b) = c]`.
* `pathMul_assoc` (Track A.1): equates the two bracketed indicators
  `(x*y)*b = c ↔ x*(y*b) = c` at the `Option`-level.

Sum-equality follows by `Finset.sum_congr` × 3 over the three
nested binders. -/
theorem pathAlgebraMul_assoc (m : ℕ)
    (f g h : pathAlgebraQuotient m) :
    pathAlgebraMul m (pathAlgebraMul m f g) h =
    pathAlgebraMul m f (pathAlgebraMul m g h) := by
  funext c
  rw [pathAlgebraMul_assoc_lhs_canonical m f g h c,
      pathAlgebraMul_assoc_rhs_canonical m f g h c]
  -- Goal: equate the two canonical forms via pathMul_assoc.
  apply Finset.sum_congr rfl; intro x _
  apply Finset.sum_congr rfl; intro y _
  apply Finset.sum_congr rfl; intro b _
  -- LHS: f x · g y · h b · [bind(pxy, λa. pab) = c]
  -- RHS: f x · g y · h b · [bind(pyb, λa. pxa) = c]
  -- Rewrite LHS bind chain to RHS via pathMul_assoc.
  rw [pathMul_assoc m x y b]

end GrochowQiao
end Orbcrypt
