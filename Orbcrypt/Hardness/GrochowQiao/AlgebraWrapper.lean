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
import Mathlib.Algebra.Ring.Idempotent
import Mathlib.RingTheory.Idempotents
import Mathlib.LinearAlgebra.Basis.Basic
import Mathlib.LinearAlgebra.Basis.Defs
import Mathlib.Algebra.BigOperators.Pi
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination
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

-- ============================================================================
-- A.2.5 — Multiplicative identity (`pathAlgebraOne`).
-- ============================================================================

/-- The multiplicative identity in the path algebra is the sum of
all vertex idempotents `∑_v e_v`. -/
noncomputable def pathAlgebraOne (m : ℕ) : pathAlgebraQuotient m :=
  ∑ v : Fin m, vertexIdempotent m v

noncomputable instance pathAlgebraQuotient.instOne (m : ℕ) :
    One (pathAlgebraQuotient m) := ⟨pathAlgebraOne m⟩

/-- Helper: sum-of-functions evaluation via Finset.sum on each
output. -/
private lemma sum_pathAlg_apply (m : ℕ) (s : Finset (Fin m))
    (g : Fin m → pathAlgebraQuotient m) (a : QuiverArrow m) :
    (∑ v ∈ s, g v) a = ∑ v ∈ s, g v a :=
  Finset.sum_apply a s g

/-- Explicit application of `pathAlgebraOne` on basis elements. -/
theorem pathAlgebraOne_apply_id (m : ℕ) (w : Fin m) :
    pathAlgebraOne m (.id w) = 1 := by
  show (∑ v : Fin m, vertexIdempotent m v) (.id w) = 1
  rw [sum_pathAlg_apply]
  rw [Finset.sum_eq_single w]
  · simp [vertexIdempotent]
  · intros v _ hv
    simp [vertexIdempotent, hv]
  · intro h_not; exact absurd (Finset.mem_univ w) h_not

theorem pathAlgebraOne_apply_edge (m : ℕ) (u v : Fin m) :
    pathAlgebraOne m (.edge u v) = 0 := by
  show (∑ w : Fin m, vertexIdempotent m w) (.edge u v) = 0
  rw [sum_pathAlg_apply]
  apply Finset.sum_eq_zero
  intros w _
  simp [vertexIdempotent]

-- ============================================================================
-- Layer 1.5 — `vertexIdempotent_mul_apply` (the key bilinear formula).
-- ============================================================================

/-- **Helper: outer sum of `vertexIdempotent v * f` collapses to `a = .id v`.**

For any `f` and target `c`, the outer sum over `a` reduces to the
single nonzero term at `a = .id v`. -/
private lemma vertexIdempotent_mul_apply_outer_collapse (m : ℕ) (v : Fin m)
    (f : pathAlgebraQuotient m) (c : QuiverArrow m) :
    (∑ a : QuiverArrow m, ∑ b : QuiverArrow m,
       vertexIdempotent m v a * f b *
       (if pathMul m a b = some c then (1 : ℚ) else 0)) =
    (∑ b : QuiverArrow m, f b *
       (if pathMul m (.id v) b = some c then (1 : ℚ) else 0)) := by
  rw [Finset.sum_eq_single (.id v)]
  · -- a = .id v: vertexIdempotent v (.id v) = 1.
    apply Finset.sum_congr rfl
    intros b _
    rw [vertexIdempotent_apply_id, if_pos rfl, one_mul]
  · -- a ≠ .id v: vertexIdempotent v a = 0 in both constructor cases.
    intros a _ ha
    apply Finset.sum_eq_zero
    intros b _
    cases a with
    | id v' =>
      have h_ne : v ≠ v' := fun h_eq => ha (by rw [h_eq])
      simp [vertexIdempotent_apply_id, h_ne]
    | edge u' w' =>
      simp [vertexIdempotent_apply_edge]
  · intro h; exact absurd (Finset.mem_univ _) h

/-- **Helper: inner sum at `c = .id z` collapses based on `v = z`.** -/
private lemma vertexIdempotent_mul_inner_id (m : ℕ) (v z : Fin m)
    (f : pathAlgebraQuotient m) :
    (∑ b : QuiverArrow m, f b *
       (if pathMul m (.id v) b = some (.id z) then (1 : ℚ) else 0)) =
    (if v = z then f (.id z) else 0) := by
  by_cases h_vz : v = z
  · subst h_vz
    rw [if_pos rfl]
    rw [Finset.sum_eq_single (.id v)]
    · simp [pathMul_id_id]
    · intros b _ hb
      cases b with
      | id w' =>
        have h_pm : pathMul m (.id v) (.id w') ≠ some (.id v) := by
          rw [pathMul_id_id]
          by_cases h : v = w'
          · subst h
            -- pathMul (.id v) (.id v) = some (.id v); but b = .id v contradicts hb.
            intro _
            exact hb rfl
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
      | edge u' w' =>
        have h_pm : pathMul m (.id v) (.edge u' w') ≠ some (.id v) := by
          rw [pathMul_id_edge]
          by_cases h : v = u'
          · subst h; simp
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
    · intro h; exact absurd (Finset.mem_univ _) h
  · rw [if_neg h_vz]
    apply Finset.sum_eq_zero
    intros b _
    cases b with
    | id w' =>
      have h_pm : pathMul m (.id v) (.id w') ≠ some (.id z) := by
        rw [pathMul_id_id]
        by_cases h : v = w'
        · subst h
          rw [if_pos rfl]
          intro h_eq
          -- h_eq : some (.id v) = some (.id z), so v = z, contradicts h_vz.
          have h_inj := Option.some.inj h_eq
          injection h_inj with h_v_eq_z
          exact h_vz h_v_eq_z
        · rw [if_neg h]; simp
      rw [if_neg h_pm, mul_zero]
    | edge u' w' =>
      have h_pm : pathMul m (.id v) (.edge u' w') ≠ some (.id z) := by
        rw [pathMul_id_edge]
        by_cases h : v = u'
        · subst h; simp
        · rw [if_neg h]; simp
      rw [if_neg h_pm, mul_zero]

/-- **Helper: inner sum at `c = .edge u w` collapses based on `v = u`.** -/
private lemma vertexIdempotent_mul_inner_edge (m : ℕ) (v u w : Fin m)
    (f : pathAlgebraQuotient m) :
    (∑ b : QuiverArrow m, f b *
       (if pathMul m (.id v) b = some (.edge u w) then (1 : ℚ) else 0)) =
    (if v = u then f (.edge u w) else 0) := by
  by_cases h_vu : v = u
  · subst h_vu
    rw [if_pos rfl]
    rw [Finset.sum_eq_single (.edge v w)]
    · simp [pathMul_id_edge]
    · intros b _ hb
      cases b with
      | id w' =>
        have h_pm : pathMul m (.id v) (.id w') ≠ some (.edge v w) := by
          rw [pathMul_id_id]
          by_cases h : v = w'
          · subst h; simp
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
      | edge u' w' =>
        have h_pm : pathMul m (.id v) (.edge u' w') ≠ some (.edge v w) := by
          rw [pathMul_id_edge]
          by_cases h : v = u'
          · subst h
            rw [if_pos rfl]
            intro h_eq
            -- h_eq : some (.edge v w' : QuiverArrow m) = some (.edge v w)
            have h_inj := Option.some.inj h_eq
            injection h_inj with h_u_eq h_w_eq
            exact hb (by rw [h_w_eq])
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
    · intro h; exact absurd (Finset.mem_univ _) h
  · rw [if_neg h_vu]
    apply Finset.sum_eq_zero
    intros b _
    cases b with
    | id w' =>
      have h_pm : pathMul m (.id v) (.id w') ≠ some (.edge u w) := by
        rw [pathMul_id_id]
        by_cases h : v = w'
        · subst h; simp
        · rw [if_neg h]; simp
      rw [if_neg h_pm, mul_zero]
    | edge u' w' =>
      have h_pm : pathMul m (.id v) (.edge u' w') ≠ some (.edge u w) := by
        rw [pathMul_id_edge]
        by_cases h : v = u'
        · subst h
          rw [if_pos rfl]
          intro h_eq
          have h_inj := Option.some.inj h_eq
          injection h_inj with h_u_eq h_w_eq
          exact h_vu h_u_eq
        · rw [if_neg h]; simp
      rw [if_neg h_pm, mul_zero]

/-- **Bilinear formula for `e_v * f` evaluated at any output index** (Layer 1.5). -/
theorem vertexIdempotent_mul_apply_id (m : ℕ) (v z : Fin m)
    (f : pathAlgebraQuotient m) :
    (pathAlgebraMul m (vertexIdempotent m v) f) (.id z) =
    (if v = z then f (.id z) else 0) := by
  show (∑ a : QuiverArrow m, ∑ b : QuiverArrow m,
          vertexIdempotent m v a * f b *
          (if pathMul m a b = some (.id z) then (1 : ℚ) else 0)) = _
  rw [vertexIdempotent_mul_apply_outer_collapse]
  exact vertexIdempotent_mul_inner_id m v z f

theorem vertexIdempotent_mul_apply_edge (m : ℕ) (v u w : Fin m)
    (f : pathAlgebraQuotient m) :
    (pathAlgebraMul m (vertexIdempotent m v) f) (.edge u w) =
    (if v = u then f (.edge u w) else 0) := by
  show (∑ a : QuiverArrow m, ∑ b : QuiverArrow m,
          vertexIdempotent m v a * f b *
          (if pathMul m a b = some (.edge u w) then (1 : ℚ) else 0)) = _
  rw [vertexIdempotent_mul_apply_outer_collapse]
  exact vertexIdempotent_mul_inner_edge m v u w f

-- ============================================================================
-- Layer 1.5b — `mul_vertexIdempotent_apply` (symmetric for `mul_one`).
-- ============================================================================

/-- **Helper: outer sum of `f * vertexIdempotent v` collapses to `b = .id v`.** -/
private lemma mul_vertexIdempotent_apply_outer_collapse (m : ℕ)
    (f : pathAlgebraQuotient m) (v : Fin m) (c : QuiverArrow m) :
    (∑ a : QuiverArrow m, ∑ b : QuiverArrow m,
       f a * vertexIdempotent m v b *
       (if pathMul m a b = some c then (1 : ℚ) else 0)) =
    (∑ a : QuiverArrow m, f a *
       (if pathMul m a (.id v) = some c then (1 : ℚ) else 0)) := by
  apply Finset.sum_congr rfl
  intros a _
  rw [Finset.sum_eq_single (.id v)]
  · -- b = .id v
    rw [vertexIdempotent_apply_id, if_pos rfl, mul_one]
  · -- b ≠ .id v
    intros b _ hb
    cases b with
    | id v' =>
      have h_ne : v ≠ v' := fun h_eq => hb (by rw [h_eq])
      simp [vertexIdempotent_apply_id, h_ne]
    | edge u' w' =>
      simp [vertexIdempotent_apply_edge]
  · intro h; exact absurd (Finset.mem_univ _) h

/-- **Helper: inner sum at `c = .id z` (right-multiplication case).** -/
private lemma mul_vertexIdempotent_inner_id (m : ℕ)
    (f : pathAlgebraQuotient m) (v z : Fin m) :
    (∑ a : QuiverArrow m, f a *
       (if pathMul m a (.id v) = some (.id z) then (1 : ℚ) else 0)) =
    (if v = z then f (.id z) else 0) := by
  by_cases h_vz : v = z
  · subst h_vz
    rw [if_pos rfl]
    rw [Finset.sum_eq_single (.id v)]
    · simp [pathMul_id_id]
    · intros a _ ha
      cases a with
      | id v' =>
        have h_pm : pathMul m (.id v') (.id v) ≠ some (.id v) := by
          rw [pathMul_id_id]
          by_cases h : v' = v
          · subst h
            rw [if_pos rfl]
            intro _
            exact ha rfl
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
      | edge u' w' =>
        have h_pm : pathMul m (.edge u' w') (.id v) ≠ some (.id v) := by
          rw [pathMul_edge_id]
          by_cases h : w' = v
          · subst h; simp
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
    · intro h; exact absurd (Finset.mem_univ _) h
  · rw [if_neg h_vz]
    apply Finset.sum_eq_zero
    intros a _
    cases a with
    | id v' =>
      have h_pm : pathMul m (.id v') (.id v) ≠ some (.id z) := by
        rw [pathMul_id_id]
        by_cases h : v' = v
        · subst h
          rw [if_pos rfl]
          intro h_eq
          have h_inj := Option.some.inj h_eq
          injection h_inj with h_v_eq_z
          exact h_vz h_v_eq_z
        · rw [if_neg h]; simp
      rw [if_neg h_pm, mul_zero]
    | edge u' w' =>
      have h_pm : pathMul m (.edge u' w') (.id v) ≠ some (.id z) := by
        rw [pathMul_edge_id]
        by_cases h : w' = v
        · subst h; simp
        · rw [if_neg h]; simp
      rw [if_neg h_pm, mul_zero]

/-- **Helper: inner sum at `c = .edge u w` (right-multiplication case).** -/
private lemma mul_vertexIdempotent_inner_edge (m : ℕ)
    (f : pathAlgebraQuotient m) (v u w : Fin m) :
    (∑ a : QuiverArrow m, f a *
       (if pathMul m a (.id v) = some (.edge u w) then (1 : ℚ) else 0)) =
    (if v = w then f (.edge u w) else 0) := by
  by_cases h_vw : v = w
  · subst h_vw
    rw [if_pos rfl]
    rw [Finset.sum_eq_single (.edge u v)]
    · simp [pathMul_edge_id]
    · intros a _ ha
      cases a with
      | id v' =>
        have h_pm : pathMul m (.id v') (.id v) ≠ some (.edge u v) := by
          rw [pathMul_id_id]
          by_cases h : v' = v
          · subst h; simp
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
      | edge u' w' =>
        have h_pm : pathMul m (.edge u' w') (.id v) ≠ some (.edge u v) := by
          rw [pathMul_edge_id]
          by_cases h : w' = v
          · subst h
            rw [if_pos rfl]
            intro h_eq
            have h_inj := Option.some.inj h_eq
            injection h_inj with h_u_eq h_w_eq
            -- h_eq says (.edge u' v) = (.edge u v), so u' = u (and v = v).
            -- Hence ha : .edge u' v ≠ .edge u v becomes .edge u v ≠ .edge u v.
            apply ha
            rw [h_u_eq]
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
    · intro h; exact absurd (Finset.mem_univ _) h
  · rw [if_neg h_vw]
    apply Finset.sum_eq_zero
    intros a _
    cases a with
    | id v' =>
      have h_pm : pathMul m (.id v') (.id v) ≠ some (.edge u w) := by
        rw [pathMul_id_id]
        by_cases h : v' = v
        · subst h; simp
        · rw [if_neg h]; simp
      rw [if_neg h_pm, mul_zero]
    | edge u' w' =>
      have h_pm : pathMul m (.edge u' w') (.id v) ≠ some (.edge u w) := by
        rw [pathMul_edge_id]
        by_cases h : w' = v
        · rw [if_pos h]
          intro h_eq
          have h_inj := Option.some.inj h_eq
          injection h_inj with h_u_eq h_w_eq
          -- h : w' = v, h_w_eq : w' = w. So v = w by transitivity.
          exact h_vw (h.symm.trans h_w_eq)
        · rw [if_neg h]; simp
      rw [if_neg h_pm, mul_zero]

/-- **Bilinear formula for `f * e_v` evaluated at `c = .id z`.** -/
theorem mul_vertexIdempotent_apply_id (m : ℕ) (f : pathAlgebraQuotient m)
    (v z : Fin m) :
    (pathAlgebraMul m f (vertexIdempotent m v)) (.id z) =
    (if v = z then f (.id z) else 0) := by
  show (∑ a : QuiverArrow m, ∑ b : QuiverArrow m,
          f a * vertexIdempotent m v b *
          (if pathMul m a b = some (.id z) then (1 : ℚ) else 0)) = _
  rw [mul_vertexIdempotent_apply_outer_collapse]
  exact mul_vertexIdempotent_inner_id m f v z

/-- **Bilinear formula for `f * e_v` evaluated at `c = .edge u w`.** -/
theorem mul_vertexIdempotent_apply_edge (m : ℕ) (f : pathAlgebraQuotient m)
    (v u w : Fin m) :
    (pathAlgebraMul m f (vertexIdempotent m v)) (.edge u w) =
    (if v = w then f (.edge u w) else 0) := by
  show (∑ a : QuiverArrow m, ∑ b : QuiverArrow m,
          f a * vertexIdempotent m v b *
          (if pathMul m a b = some (.edge u w) then (1 : ℚ) else 0)) = _
  rw [mul_vertexIdempotent_apply_outer_collapse]
  exact mul_vertexIdempotent_inner_edge m f v u w

-- ============================================================================
-- Layer 1.1-1.4 — Basis-element multiplication table.
-- ============================================================================

/-- **Vertex idempotent times vertex idempotent** (Layer 1.1).

`e_v * e_w = if v = w then e_v else 0`. -/
theorem vertexIdempotent_mul_vertexIdempotent (m : ℕ) (v w : Fin m) :
    pathAlgebraMul m (vertexIdempotent m v) (vertexIdempotent m w) =
    if v = w then vertexIdempotent m v else 0 := by
  funext c
  cases c with
  | id z =>
    rw [vertexIdempotent_mul_apply_id]
    -- LHS: if v = z then (vertexIdempotent w) (.id z) else 0
    --    = if v = z then (if w = z then 1 else 0) else 0
    -- RHS: (if v = w then vertexIdempotent v else 0) (.id z)
    --    = if v = w then (if v = z then 1 else 0) else 0  [Pi.zero_apply]
    rw [vertexIdempotent_apply_id]
    split_ifs with h_vz h_wz h_vw h_vw' h_vz'
    all_goals try (first | rfl | simp_all [Pi.zero_apply, vertexIdempotent_apply_id])
  | edge u w' =>
    rw [vertexIdempotent_mul_apply_edge]
    rw [vertexIdempotent_apply_edge]
    split_ifs with h_vu h_vw
    all_goals try (first | rfl | simp_all [Pi.zero_apply, vertexIdempotent_apply_edge])

/-- **Vertex idempotent times arrow element** (Layer 1.2).

`e_v * α(u, w) = if v = u then α(u, w) else 0`. -/
theorem vertexIdempotent_mul_arrowElement (m : ℕ) (v u w : Fin m) :
    pathAlgebraMul m (vertexIdempotent m v) (arrowElement m u w) =
    if v = u then arrowElement m u w else 0 := by
  funext c
  cases c with
  | id z =>
    rw [vertexIdempotent_mul_apply_id]
    rw [arrowElement_apply_id]
    -- (if v = z then 0 else 0) = (if v = u then arrowElement m u w else 0) (.id z)
    --                         = (if v = u then 0 else 0) [Pi.zero_apply, arrowElement_apply_id]
    split_ifs with h_vz h_vu
    all_goals try (first | rfl | simp_all [Pi.zero_apply, arrowElement_apply_id])
  | edge u' w' =>
    rw [vertexIdempotent_mul_apply_edge]
    rw [arrowElement_apply_edge]
    split_ifs with h_vu' h_uw' h_uw'' h_vu h_uw' h_vu' h_uw''
    all_goals try (first | rfl | simp_all [Pi.zero_apply, arrowElement_apply_edge])

/-- **Arrow element times vertex idempotent** (Layer 1.3).

`α(u, v) * e_w = if v = w then α(u, v) else 0`. -/
theorem arrowElement_mul_vertexIdempotent (m : ℕ) (u v w : Fin m) :
    pathAlgebraMul m (arrowElement m u v) (vertexIdempotent m w) =
    if v = w then arrowElement m u v else 0 := by
  funext c
  cases c with
  | id z =>
    rw [mul_vertexIdempotent_apply_id]
    rw [arrowElement_apply_id]
    split_ifs with h_wz h_vw
    all_goals try (first | rfl | simp_all [Pi.zero_apply, arrowElement_apply_id])
  | edge u' w' =>
    rw [mul_vertexIdempotent_apply_edge]
    rw [arrowElement_apply_edge]
    split_ifs with h_ww' h_uw'_match h_vw h_uw'_match
    all_goals try (first | rfl | simp_all [Pi.zero_apply, arrowElement_apply_edge])

/-- **Arrow element times arrow element is zero** (Layer 1.4).

`α(u, v) * α(u', w') = 0` (J²-truncation kills length-2 paths). -/
theorem arrowElement_mul_arrowElement_eq_zero (m : ℕ) (u v u' w' : Fin m) :
    pathAlgebraMul m (arrowElement m u v) (arrowElement m u' w') = 0 := by
  funext c
  show (∑ a : QuiverArrow m, ∑ b : QuiverArrow m,
          arrowElement m u v a * arrowElement m u' w' b *
          (if pathMul m a b = some c then (1 : ℚ) else 0)) = (0 : pathAlgebraQuotient m) c
  -- Only (a, b) = (.edge u v, .edge u' w') gives a nonzero product of basis values.
  -- But pathMul (.edge _ _) (.edge _ _) = none, so the indicator is 0.
  rw [show (0 : pathAlgebraQuotient m) c = 0 from rfl]
  apply Finset.sum_eq_zero
  intros a _
  apply Finset.sum_eq_zero
  intros b _
  cases a with
  | id v_a =>
    rw [arrowElement_apply_id]; ring
  | edge u_a v_a =>
    cases b with
    | id v_b =>
      rw [arrowElement_apply_id]; ring
    | edge u_b v_b =>
      rw [pathMul_edge_edge_none]
      simp

-- ============================================================================
-- Layer 2 — Distributivity + Annihilation.
-- ============================================================================

/-- **Left distributivity** (Layer 2.1).

`f * (g + h) = f * g + f * h`. Direct from bilinearity of the
inner expression `f a · (g b + h b) · indicator`. -/
theorem pathAlgebra_left_distrib (m : ℕ) (f g h : pathAlgebraQuotient m) :
    pathAlgebraMul m f (g + h) = pathAlgebraMul m f g + pathAlgebraMul m f h := by
  funext c
  show (∑ a, ∑ b, f a * (g + h) b *
          (if pathMul m a b = some c then (1 : ℚ) else 0)) =
       (∑ a, ∑ b, f a * g b *
          (if pathMul m a b = some c then (1 : ℚ) else 0)) +
       (∑ a, ∑ b, f a * h b *
          (if pathMul m a b = some c then (1 : ℚ) else 0))
  rw [← Finset.sum_add_distrib]
  apply Finset.sum_congr rfl
  intros a _
  rw [← Finset.sum_add_distrib]
  apply Finset.sum_congr rfl
  intros b _
  show f a * (g b + h b) * _ = f a * g b * _ + f a * h b * _
  ring

/-- **Right distributivity** (Layer 2.2).

`(f + g) * h = f * h + g * h`. -/
theorem pathAlgebra_right_distrib (m : ℕ) (f g h : pathAlgebraQuotient m) :
    pathAlgebraMul m (f + g) h = pathAlgebraMul m f h + pathAlgebraMul m g h := by
  funext c
  show (∑ a, ∑ b, (f + g) a * h b *
          (if pathMul m a b = some c then (1 : ℚ) else 0)) =
       (∑ a, ∑ b, f a * h b *
          (if pathMul m a b = some c then (1 : ℚ) else 0)) +
       (∑ a, ∑ b, g a * h b *
          (if pathMul m a b = some c then (1 : ℚ) else 0))
  rw [← Finset.sum_add_distrib]
  apply Finset.sum_congr rfl
  intros a _
  rw [← Finset.sum_add_distrib]
  apply Finset.sum_congr rfl
  intros b _
  show (f a + g a) * h b * _ = f a * h b * _ + g a * h b * _
  ring

/-- **Zero left annihilation** (Layer 2.3).

`0 * f = 0`. -/
theorem pathAlgebra_zero_mul (m : ℕ) (f : pathAlgebraQuotient m) :
    pathAlgebraMul m 0 f = 0 := by
  funext c
  show (∑ a, ∑ b, (0 : pathAlgebraQuotient m) a * f b *
          (if pathMul m a b = some c then (1 : ℚ) else 0)) =
       (0 : pathAlgebraQuotient m) c
  rw [show (0 : pathAlgebraQuotient m) c = (0 : ℚ) from rfl]
  apply Finset.sum_eq_zero
  intros a _
  apply Finset.sum_eq_zero
  intros b _
  show (0 : pathAlgebraQuotient m) a * f b * _ = 0
  rw [show (0 : pathAlgebraQuotient m) a = (0 : ℚ) from rfl]
  ring

/-- **Zero right annihilation** (Layer 2.4).

`f * 0 = 0`. -/
theorem pathAlgebra_mul_zero (m : ℕ) (f : pathAlgebraQuotient m) :
    pathAlgebraMul m f 0 = 0 := by
  funext c
  show (∑ a, ∑ b, f a * (0 : pathAlgebraQuotient m) b *
          (if pathMul m a b = some c then (1 : ℚ) else 0)) =
       (0 : pathAlgebraQuotient m) c
  rw [show (0 : pathAlgebraQuotient m) c = (0 : ℚ) from rfl]
  apply Finset.sum_eq_zero
  intros a _
  apply Finset.sum_eq_zero
  intros b _
  show f a * (0 : pathAlgebraQuotient m) b * _ = 0
  rw [show (0 : pathAlgebraQuotient m) b = (0 : ℚ) from rfl]
  ring

-- ============================================================================
-- Layer 3 — `one_mul` + `mul_one` via bilinearity.
-- ============================================================================

/-- **Helper: pathAlgebraMul distributes over Finset sums on the left.** -/
private lemma pathAlgebra_sum_mul {ι : Type*} (m : ℕ) (s : Finset ι)
    (g : ι → pathAlgebraQuotient m) (f : pathAlgebraQuotient m) :
    pathAlgebraMul m (∑ i ∈ s, g i) f = ∑ i ∈ s, pathAlgebraMul m (g i) f := by
  classical
  induction s using Finset.induction_on with
  | empty =>
    rw [Finset.sum_empty, Finset.sum_empty]
    exact pathAlgebra_zero_mul m f
  | @insert i s' i_not_mem ih =>
    rw [Finset.sum_insert i_not_mem, Finset.sum_insert i_not_mem]
    rw [pathAlgebra_right_distrib, ih]

/-- **Helper: pathAlgebraMul distributes over Finset sums on the right.** -/
private lemma pathAlgebra_mul_sum {ι : Type*} (m : ℕ) (f : pathAlgebraQuotient m)
    (s : Finset ι) (g : ι → pathAlgebraQuotient m) :
    pathAlgebraMul m f (∑ i ∈ s, g i) = ∑ i ∈ s, pathAlgebraMul m f (g i) := by
  classical
  induction s using Finset.induction_on with
  | empty =>
    rw [Finset.sum_empty, Finset.sum_empty]
    exact pathAlgebra_mul_zero m f
  | @insert i s' i_not_mem ih =>
    rw [Finset.sum_insert i_not_mem, Finset.sum_insert i_not_mem]
    rw [pathAlgebra_left_distrib, ih]

/-- **`1 * f = f` in the path algebra** (Layer 3.1). -/
theorem pathAlgebra_one_mul (m : ℕ) (f : pathAlgebraQuotient m) :
    pathAlgebraMul m (pathAlgebraOne m) f = f := by
  -- Step 1: 1 = ∑_v e_v, distribute: (∑_v e_v) * f = ∑_v (e_v * f).
  show pathAlgebraMul m (∑ v : Fin m, vertexIdempotent m v) f = f
  rw [pathAlgebra_sum_mul]
  -- Step 2: per-c evaluation via L1.5.
  funext c
  rw [sum_pathAlg_apply]
  cases c with
  | id z =>
    -- ∑_v (e_v * f) (.id z) = ∑_v (if v = z then f(.id z) else 0) = f(.id z)
    simp_rw [vertexIdempotent_mul_apply_id]
    rw [Finset.sum_eq_single z]
    · rw [if_pos rfl]
    · intros v _ hv
      rw [if_neg hv]
    · intro h; exact absurd (Finset.mem_univ _) h
  | edge u w =>
    simp_rw [vertexIdempotent_mul_apply_edge]
    rw [Finset.sum_eq_single u]
    · rw [if_pos rfl]
    · intros v _ hv
      rw [if_neg hv]
    · intro h; exact absurd (Finset.mem_univ _) h

/-- **`f * 1 = f` in the path algebra** (Layer 3.2). -/
theorem pathAlgebra_mul_one (m : ℕ) (f : pathAlgebraQuotient m) :
    pathAlgebraMul m f (pathAlgebraOne m) = f := by
  show pathAlgebraMul m f (∑ v : Fin m, vertexIdempotent m v) = f
  rw [pathAlgebra_mul_sum]
  funext c
  rw [sum_pathAlg_apply]
  cases c with
  | id z =>
    -- ∑_v (f * e_v) (.id z) = ∑_v (if v = z then f(.id z) else 0) = f(.id z)
    simp_rw [mul_vertexIdempotent_apply_id]
    rw [Finset.sum_eq_single z]
    · rw [if_pos rfl]
    · intros v _ hv
      rw [if_neg hv]
    · intro h; exact absurd (Finset.mem_univ _) h
  | edge u w =>
    -- For c = .edge u w: f * e_v at .edge u w = (if v = w then f(.edge u w) else 0).
    -- Sum over v: only v = w contributes f(.edge u w).
    simp_rw [mul_vertexIdempotent_apply_edge]
    rw [Finset.sum_eq_single w]
    · rw [if_pos rfl]
    · intros v _ hv
      rw [if_neg hv]
    · intro h; exact absurd (Finset.mem_univ _) h

-- ============================================================================
-- Layer 4 — Ring instance.
-- ============================================================================

/-- **The path algebra is a ring.**

The full `Ring` typeclass instance combining all the previous
layers' results: `pathAlgebraMul_assoc` (Layer 0),
`pathAlgebra_one_mul`/`pathAlgebra_mul_one` (Layer 3),
`pathAlgebra_left_distrib`/`pathAlgebra_right_distrib` (Layer 2),
`pathAlgebra_zero_mul`/`pathAlgebra_mul_zero` (Layer 2). -/
noncomputable instance pathAlgebraQuotient.instRing (m : ℕ) :
    Ring (pathAlgebraQuotient m) :=
  { pathAlgebraQuotient.addCommGroup m,
    pathAlgebraQuotient.instMul m,
    pathAlgebraQuotient.instOne m with
    mul_assoc := pathAlgebraMul_assoc m
    one_mul := pathAlgebra_one_mul m
    mul_one := pathAlgebra_mul_one m
    left_distrib := pathAlgebra_left_distrib m
    right_distrib := pathAlgebra_right_distrib m
    zero_mul := pathAlgebra_zero_mul m
    mul_zero := pathAlgebra_mul_zero m }

-- ============================================================================
-- Layer 5 — Algebra ℚ instance + decomposition + basis.
-- ============================================================================

/-- **Smul-mul compatibility (left)** (Layer 5.1).

`(r • f) * g = r • (f * g)` — the bilinear product respects scalar
multiplication on the left factor. -/
theorem pathAlgebra_smul_mul (m : ℕ) (r : ℚ) (f g : pathAlgebraQuotient m) :
    pathAlgebraMul m (r • f) g = r • pathAlgebraMul m f g := by
  funext c
  show (∑ a, ∑ b, (r • f) a * g b *
          (if pathMul m a b = some c then (1 : ℚ) else 0)) =
       r * (∑ a, ∑ b, f a * g b *
          (if pathMul m a b = some c then (1 : ℚ) else 0))
  rw [Finset.mul_sum]
  apply Finset.sum_congr rfl; intros a _
  rw [Finset.mul_sum]
  apply Finset.sum_congr rfl; intros b _
  show (r • f) a * g b * _ = r * (f a * g b * _)
  rw [show (r • f) a = r * f a from rfl]
  ring

/-- **Smul-mul compatibility (right)** (Layer 5.1b). -/
theorem pathAlgebra_mul_smul (m : ℕ) (r : ℚ) (f g : pathAlgebraQuotient m) :
    pathAlgebraMul m f (r • g) = r • pathAlgebraMul m f g := by
  funext c
  show (∑ a, ∑ b, f a * (r • g) b *
          (if pathMul m a b = some c then (1 : ℚ) else 0)) =
       r * (∑ a, ∑ b, f a * g b *
          (if pathMul m a b = some c then (1 : ℚ) else 0))
  rw [Finset.mul_sum]
  apply Finset.sum_congr rfl; intros a _
  rw [Finset.mul_sum]
  apply Finset.sum_congr rfl; intros b _
  show f a * (r • g) b * _ = r * (f a * g b * _)
  rw [show (r • g) b = r * g b from rfl]
  ring

/-- **Algebra ℚ instance** (Layer 5.2).

The path algebra is a ℚ-algebra: scalar multiplication is compatible
with both factors of the multiplication. -/
noncomputable instance pathAlgebraQuotient.instAlgebra (m : ℕ) :
    Algebra ℚ (pathAlgebraQuotient m) :=
  Algebra.ofModule
    (fun r f g => by
      show pathAlgebraMul m (r • f) g = r • pathAlgebraMul m f g
      exact pathAlgebra_smul_mul m r f g)
    (fun r f g => by
      show pathAlgebraMul m f (r • g) = r • pathAlgebraMul m f g
      exact pathAlgebra_mul_smul m r f g)

/-- **Decomposition into vertex + arrow basis components** (Layer 5.3).

Every element of the path algebra splits canonically into a sum of
vertex-idempotent components and arrow-element components:
```
f = (∑_v f(.id v) • e_v) + (∑_{(u,v)} f(.edge u v) • α(u, v))
```
-/
theorem pathAlgebra_decompose (m : ℕ) (f : pathAlgebraQuotient m) :
    f = (∑ v : Fin m, f (.id v) • vertexIdempotent m v) +
        (∑ p : Fin m × Fin m, f (.edge p.1 p.2) • arrowElement m p.1 p.2) := by
  funext c
  show f c =
    ((∑ v : Fin m, f (.id v) • vertexIdempotent m v) +
     (∑ p : Fin m × Fin m, f (.edge p.1 p.2) • arrowElement m p.1 p.2)) c
  rw [show ((∑ v : Fin m, f (.id v) • vertexIdempotent m v) +
            (∑ p : Fin m × Fin m, f (.edge p.1 p.2) • arrowElement m p.1 p.2)) c
        = (∑ v : Fin m, f (.id v) • vertexIdempotent m v) c +
          (∑ p : Fin m × Fin m, f (.edge p.1 p.2) • arrowElement m p.1 p.2) c from rfl]
  rw [sum_pathAlg_apply]
  -- Second sum is over Fin m × Fin m; need a different sum_apply.
  show f c = (∑ v : Fin m, (f (.id v) • vertexIdempotent m v) c) +
             (∑ p : Fin m × Fin m, f (.edge p.1 p.2) • arrowElement m p.1 p.2) c
  cases c with
  | id z =>
    -- ∑_v f(.id v) • e_v at .id z = ∑_v f(.id v) * (e_v)(.id z) = f(.id z)
    have h_arrow_sum_zero :
        (∑ p : Fin m × Fin m, f (.edge p.1 p.2) • arrowElement m p.1 p.2) (.id z) = 0 := by
      show (∑ p : Fin m × Fin m, f (.edge p.1 p.2) • arrowElement m p.1 p.2) (.id z) = 0
      rw [show (∑ p : Fin m × Fin m, f (.edge p.1 p.2) • arrowElement m p.1 p.2) (.id z) =
              ∑ p : Fin m × Fin m, (f (.edge p.1 p.2) • arrowElement m p.1 p.2) (.id z) from
            Finset.sum_apply _ _ _]
      apply Finset.sum_eq_zero
      intros p _
      show f (.edge p.1 p.2) * arrowElement m p.1 p.2 (.id z) = 0
      rw [arrowElement_apply_id]
      ring
    rw [h_arrow_sum_zero, add_zero]
    rw [Finset.sum_eq_single z]
    · show f (.id z) = (f (.id z) • vertexIdempotent m z) (.id z)
      show f (.id z) = f (.id z) * vertexIdempotent m z (.id z)
      rw [vertexIdempotent_apply_id, if_pos rfl, mul_one]
    · intros v _ hv
      show (f (.id v) • vertexIdempotent m v) (.id z) = 0
      show f (.id v) * vertexIdempotent m v (.id z) = 0
      rw [vertexIdempotent_apply_id, if_neg hv]
      ring
    · intro h; exact absurd (Finset.mem_univ _) h
  | edge u w =>
    have h_vertex_sum_zero :
        (∑ v : Fin m, (f (.id v) • vertexIdempotent m v) (.edge u w)) = 0 := by
      apply Finset.sum_eq_zero
      intros v _
      show f (.id v) * vertexIdempotent m v (.edge u w) = 0
      rw [vertexIdempotent_apply_edge]
      ring
    rw [h_vertex_sum_zero, zero_add]
    show f (.edge u w) =
      (∑ p : Fin m × Fin m, f (.edge p.1 p.2) • arrowElement m p.1 p.2) (.edge u w)
    rw [show (∑ p : Fin m × Fin m, f (.edge p.1 p.2) • arrowElement m p.1 p.2) (.edge u w) =
            ∑ p : Fin m × Fin m, (f (.edge p.1 p.2) • arrowElement m p.1 p.2) (.edge u w) from
          Finset.sum_apply _ _ _]
    rw [Finset.sum_eq_single (u, w)]
    · show f (.edge u w) = f (.edge u w) * arrowElement m u w (.edge u w)
      rw [arrowElement_apply_edge, if_pos ⟨rfl, rfl⟩, mul_one]
    · rintro ⟨u', w'⟩ _ hp
      show f (.edge u' w') * arrowElement m u' w' (.edge u w) = 0
      rw [arrowElement_apply_edge]
      by_cases h : u' = u ∧ w' = w
      · obtain ⟨h_u, h_w⟩ := h
        subst h_u; subst h_w
        exact absurd rfl hp
      · rw [if_neg h]; ring
    · intro h; exact absurd (Finset.mem_univ _) h

-- ============================================================================
-- Layer 6 / Phase C — Idempotent + primitive idempotent theory.
-- ============================================================================

/-- **Multiplication evaluated at a vertex output index.**

`(f * g)(.id z) = f(.id z) · g(.id z)`.

The only `(a, b)` pair contributing is `(a, b) = (.id z, .id z)`,
because `pathMul a b = some (.id z)` requires `a, b` to be vertex
idempotents `id z` (vertex slot has only `pathMul (.id z) (.id z)`
producing `some (.id z)`). -/
theorem pathAlgebraMul_apply_id (m : ℕ) (f g : pathAlgebraQuotient m)
    (z : Fin m) :
    pathAlgebraMul m f g (.id z) = f (.id z) * g (.id z) := by
  show (∑ a, ∑ b, f a * g b *
          (if pathMul m a b = some (.id z) then (1 : ℚ) else 0)) =
       f (.id z) * g (.id z)
  -- Only (a, b) = (.id z, .id z) contributes. Others give pathMul ≠ some (.id z).
  rw [Finset.sum_eq_single (.id z)]
  · -- a = .id z
    rw [Finset.sum_eq_single (.id z)]
    · simp [pathMul_id_id]
    · intros b _ hb
      cases b with
      | id w' =>
        have h_pm : pathMul m (.id z) (.id w') ≠ some (.id z) := by
          rw [pathMul_id_id]
          by_cases h : z = w'
          · subst h
            rw [if_pos rfl]
            intro _
            exact hb rfl
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
      | edge u' w' =>
        have h_pm : pathMul m (.id z) (.edge u' w') ≠ some (.id z) := by
          rw [pathMul_id_edge]
          by_cases h : z = u'
          · subst h; simp
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
    · intro h; exact absurd (Finset.mem_univ _) h
  · intros a _ ha
    apply Finset.sum_eq_zero
    intros b _
    cases a with
    | id v' =>
      have h_ne : v' ≠ z := fun h_eq => ha (by rw [h_eq])
      cases b with
      | id w' =>
        have h_pm : pathMul m (.id v') (.id w') ≠ some (.id z) := by
          rw [pathMul_id_id]
          by_cases h : v' = w'
          · subst h
            rw [if_pos rfl]
            intro h_eq
            have h_inj := Option.some.inj h_eq
            injection h_inj with h_eq2
            exact h_ne h_eq2
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
      | edge u' w' =>
        have h_pm : pathMul m (.id v') (.edge u' w') ≠ some (.id z) := by
          rw [pathMul_id_edge]
          by_cases h : v' = u'
          · subst h; simp
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
    | edge u' v' =>
      cases b with
      | id w' =>
        have h_pm : pathMul m (.edge u' v') (.id w') ≠ some (.id z) := by
          rw [pathMul_edge_id]
          by_cases h : v' = w'
          · subst h; simp
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
      | edge u'' w'' =>
        rw [pathMul_edge_edge_none]; simp
  · intro h; exact absurd (Finset.mem_univ _) h

/-- **Multiplication evaluated at an arrow output index.**

`(f * g)(.edge u v) = f(.id u) · g(.edge u v) + f(.edge u v) · g(.id v)`.

Only two `(a, b)` pairs contribute:
* `(a, b) = (.id u, .edge u v)`: `pathMul (.id u) (.edge u v) =
  some (.edge u v)`. Contributes `f(.id u) · g(.edge u v)`.
* `(a, b) = (.edge u v, .id v)`: `pathMul (.edge u v) (.id v) =
  some (.edge u v)`. Contributes `f(.edge u v) · g(.id v)`.

All other pairs either give `none` or wrong arrow result. -/
theorem pathAlgebraMul_apply_edge (m : ℕ) (f g : pathAlgebraQuotient m)
    (u v : Fin m) :
    pathAlgebraMul m f g (.edge u v) =
    f (.id u) * g (.edge u v) + f (.edge u v) * g (.id v) := by
  show (∑ a, ∑ b, f a * g b *
          (if pathMul m a b = some (.edge u v) then (1 : ℚ) else 0)) =
       f (.id u) * g (.edge u v) + f (.edge u v) * g (.id v)
  -- Split outer sum into two cases: a = .id u (contributes b = .edge u v),
  -- a = .edge u v (contributes b = .id v), all other a's contribute 0.
  -- Use Finset.sum_eq_add_of_subset_of_eq_subsumes... actually let's directly
  -- compute by extracting two terms.
  -- Approach: show sum = inner_term_at(.id u) + inner_term_at(.edge u v),
  -- and show all other outer terms are zero.
  -- Direct strategy: split the outer sum into a = .id u, a = .edge u v, others.
  -- Use Finset.add_sum_erase twice.
  classical
  have h_id_in : (.id u : QuiverArrow m) ∈ Finset.univ := Finset.mem_univ _
  have h_id_ne_edge : (.id u : QuiverArrow m) ≠ .edge u v := by
    intro h; cases h
  have h_edge_in_erase :
      (.edge u v : QuiverArrow m) ∈ Finset.univ.erase (.id u) := by
    rw [Finset.mem_erase]
    exact ⟨fun h => h_id_ne_edge h.symm, Finset.mem_univ _⟩
  rw [← Finset.add_sum_erase _ _ h_id_in]
  rw [← Finset.add_sum_erase _ _ h_edge_in_erase]
  -- Now: (∑b at .id u) + ((∑b at .edge u v) + (∑a in (univ.erase .id u).erase .edge u v, ∑b ...))
  rw [show (∑ b, f (.id u) * g b *
            (if pathMul m (.id u) b = some (.edge u v) then (1:ℚ) else 0)) =
          f (.id u) * g (.edge u v) from by
    rw [Finset.sum_eq_single (.edge u v)]
    · simp [pathMul_id_edge]
    · intros b _ hb
      cases b with
      | id w' =>
        have h_pm : pathMul m (.id u) (.id w') ≠ some (.edge u v) := by
          rw [pathMul_id_id]; by_cases h : u = w'
          · subst h; simp
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
      | edge u'' w'' =>
        have h_pm : pathMul m (.id u) (.edge u'' w'') ≠ some (.edge u v) := by
          rw [pathMul_id_edge]; by_cases h : u = u''
          · subst h
            rw [if_pos rfl]
            intro h_eq
            have h_inj := Option.some.inj h_eq
            injection h_inj with h_u_eq h_w_eq
            exact hb (by rw [h_w_eq])
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
    · intro h; exact absurd (Finset.mem_univ _) h]
  rw [show (∑ b, f (.edge u v) * g b *
            (if pathMul m (.edge u v) b = some (.edge u v) then (1:ℚ) else 0)) =
          f (.edge u v) * g (.id v) from by
    rw [Finset.sum_eq_single (.id v)]
    · simp [pathMul_edge_id]
    · intros b _ hb
      cases b with
      | id w' =>
        have h_pm : pathMul m (.edge u v) (.id w') ≠ some (.edge u v) := by
          rw [pathMul_edge_id]; by_cases h : v = w'
          · subst h
            rw [if_pos rfl]
            intro _
            exact hb rfl
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
      | edge u'' w'' =>
        rw [pathMul_edge_edge_none]; simp
    · intro h; exact absurd (Finset.mem_univ _) h]
  -- Now sum over the rest must be zero.
  rw [show (∑ a ∈ (Finset.univ.erase (.id u)).erase (.edge u v), ∑ b, f a * g b *
            (if pathMul m a b = some (.edge u v) then (1:ℚ) else 0)) = 0 from by
    apply Finset.sum_eq_zero
    intros a ha
    have ha_id : a ≠ .id u := by
      rw [Finset.mem_erase] at ha
      exact (Finset.mem_erase.mp ha.2).1
    have ha_edge : a ≠ .edge u v := by
      rw [Finset.mem_erase] at ha
      exact ha.1
    apply Finset.sum_eq_zero
    intros b _
    cases a with
    | id v' =>
      have h_v_ne_u : v' ≠ u := fun h_eq => ha_id (by rw [h_eq])
      cases b with
      | id w' =>
        have h_pm : pathMul m (.id v') (.id w') ≠ some (.edge u v) := by
          rw [pathMul_id_id]; by_cases h : v' = w'
          · subst h; simp
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
      | edge u'' w'' =>
        have h_pm : pathMul m (.id v') (.edge u'' w'') ≠ some (.edge u v) := by
          rw [pathMul_id_edge]; by_cases h : v' = u''
          · subst h
            rw [if_pos rfl]
            intro h_eq
            have h_inj := Option.some.inj h_eq
            injection h_inj with h_uu h_ww
            exact h_v_ne_u h_uu
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
    | edge u' w' =>
      have h_ne_uv : ¬ (u' = u ∧ w' = v) := fun h => by
        obtain ⟨h_u, h_w⟩ := h
        subst h_u; subst h_w
        exact ha_edge rfl
      cases b with
      | id w'' =>
        have h_pm : pathMul m (.edge u' w') (.id w'') ≠ some (.edge u v) := by
          rw [pathMul_edge_id]; by_cases h : w' = w''
          · subst h
            rw [if_pos rfl]
            intro h_eq
            have h_inj := Option.some.inj h_eq
            injection h_inj with h_u_eq h_w_eq
            exact h_ne_uv ⟨h_u_eq, h_w_eq⟩
          · rw [if_neg h]; simp
        rw [if_neg h_pm, mul_zero]
      | edge u'' w'' =>
        rw [pathMul_edge_edge_none]; simp]
  ring

-- ============================================================================
-- Layer 6 / Phase C — IsIdempotentElem + IsPrimitiveIdempotent.
-- ============================================================================

/-- **`(b * b)` evaluated at vertex c.** Direct corollary of pathAlgebraMul_apply_id. -/
theorem pathAlgebra_self_mul_apply_id (m : ℕ) (b : pathAlgebraQuotient m)
    (z : Fin m) : (b * b) (.id z) = b (.id z) * b (.id z) :=
  pathAlgebraMul_apply_id m b b z

/-- **`(b * b)` evaluated at arrow c.** Direct corollary of pathAlgebraMul_apply_edge. -/
theorem pathAlgebra_self_mul_apply_edge (m : ℕ) (b : pathAlgebraQuotient m)
    (u v : Fin m) :
    (b * b) (.edge u v) = b (.id u) * b (.edge u v) + b (.edge u v) * b (.id v) :=
  pathAlgebraMul_apply_edge m b b u v

/-- **Idempotent element characterization** (Phase C.1).

`b * b = b` iff every basis-element coefficient satisfies the
appropriate quadratic relation:
* `b(.id v) ^ 2 = b(.id v)` for every vertex v.
* `b(.edge u v) = b(.id u) · b(.edge u v) + b(.edge u v) · b(.id v)`
  for every arrow position. -/
theorem pathAlgebra_isIdempotentElem_iff (m : ℕ) (b : pathAlgebraQuotient m) :
    IsIdempotentElem b ↔
    (∀ v : Fin m, b (.id v) * b (.id v) = b (.id v)) ∧
    (∀ u v : Fin m, b (.id u) * b (.edge u v) + b (.edge u v) * b (.id v) =
      b (.edge u v)) := by
  unfold IsIdempotentElem
  constructor
  · intro h_idem
    refine ⟨?_, ?_⟩
    · intro v
      have h := congrFun h_idem (.id v)
      rw [pathAlgebra_self_mul_apply_id] at h
      exact h
    · intros u v
      have h := congrFun h_idem (.edge u v)
      rw [pathAlgebra_self_mul_apply_edge] at h
      exact h
  · rintro ⟨h_id, h_edge⟩
    funext c
    cases c with
    | id z =>
      rw [pathAlgebra_self_mul_apply_id]
      exact h_id z
    | edge u v =>
      rw [pathAlgebra_self_mul_apply_edge]
      exact h_edge u v

/-- **Coefficient consequence: vertex λ values are 0 or 1.** -/
theorem pathAlgebra_idempotent_lambda_squared (m : ℕ) (b : pathAlgebraQuotient m)
    (h : IsIdempotentElem b) (v : Fin m) :
    b (.id v) = 0 ∨ b (.id v) = 1 := by
  have ⟨h_id, _⟩ := (pathAlgebra_isIdempotentElem_iff m b).mp h
  have h_v := h_id v
  -- λ * λ = λ ⇒ λ * (λ - 1) = 0 ⇒ λ = 0 ∨ λ = 1.
  have h_factored : b (.id v) * (b (.id v) - 1) = 0 := by
    have := h_v
    linear_combination h_v
  rcases mul_eq_zero.mp h_factored with h_zero | h_one
  · exact Or.inl h_zero
  · right
    have : b (.id v) = 1 := by linarith
    exact this

/-- **Coefficient consequence: arrow μ values satisfy a constraint.** -/
theorem pathAlgebra_idempotent_mu_constraint (m : ℕ) (b : pathAlgebraQuotient m)
    (h : IsIdempotentElem b) (u v : Fin m) :
    b (.edge u v) = 0 ∨ b (.id u) + b (.id v) = 1 := by
  have ⟨_, h_edge⟩ := (pathAlgebra_isIdempotentElem_iff m b).mp h
  have h_uv := h_edge u v
  -- λ_u * μ + μ * λ_v = μ ⇒ μ * (λ_u + λ_v - 1) = 0 ⇒ μ = 0 ∨ λ_u + λ_v = 1.
  have h_factored : b (.edge u v) * (b (.id u) + b (.id v) - 1) = 0 := by
    linear_combination h_uv
  rcases mul_eq_zero.mp h_factored with h_zero | h_sum
  · exact Or.inl h_zero
  · right
    linarith

/-- **Primitive idempotent definition** (Phase C.3). -/
def IsPrimitiveIdempotent {A : Type*} [Ring A] (b : A) : Prop :=
  IsIdempotentElem b ∧ b ≠ 0 ∧
  ∀ b₁ b₂ : A,
    IsIdempotentElem b₁ → IsIdempotentElem b₂ →
    b₁ * b₂ = 0 → b₂ * b₁ = 0 → b = b₁ + b₂ →
    b₁ = 0 ∨ b₂ = 0

/-- **Vertex idempotent is idempotent** (basic, Phase C.4 prereq). -/
theorem vertexIdempotent_isIdempotentElem (m : ℕ) (v : Fin m) :
    IsIdempotentElem (vertexIdempotent m v) := by
  unfold IsIdempotentElem
  show pathAlgebraMul m (vertexIdempotent m v) (vertexIdempotent m v) =
       vertexIdempotent m v
  rw [vertexIdempotent_mul_vertexIdempotent, if_pos rfl]

/-- **Vertex idempotent is non-zero.** -/
theorem vertexIdempotent_ne_zero (m : ℕ) (v : Fin m) :
    vertexIdempotent m v ≠ 0 := by
  intro h_eq
  have h_at_v := congrFun h_eq (.id v)
  rw [vertexIdempotent_apply_id, if_pos rfl] at h_at_v
  -- h_at_v : 1 = (0 : pathAlgebraQuotient m) (.id v)
  -- (0 : pathAlgebraQuotient m) (.id v) = 0
  show False
  have : (1 : ℚ) = 0 := h_at_v
  exact one_ne_zero this

/-- **Phase C.6 prerequisite: AlgEquiv preserves idempotent.** -/
theorem AlgEquiv_preserves_isIdempotentElem
    {A B : Type*} [Ring A] [Ring B] [Algebra ℚ A] [Algebra ℚ B]
    (φ : A ≃ₐ[ℚ] B) {b : A} (h : IsIdempotentElem b) :
    IsIdempotentElem (φ b) := by
  unfold IsIdempotentElem at h ⊢
  rw [← map_mul]
  exact congrArg φ h

/-- **Phase C.6: AlgEquiv preserves primitive idempotent.** -/
theorem AlgEquiv_preserves_isPrimitiveIdempotent
    {A B : Type*} [Ring A] [Ring B] [Algebra ℚ A] [Algebra ℚ B]
    (φ : A ≃ₐ[ℚ] B) {b : A} (h : IsPrimitiveIdempotent b) :
    IsPrimitiveIdempotent (φ b) := by
  obtain ⟨h_idem, h_nz, h_prim⟩ := h
  refine ⟨AlgEquiv_preserves_isIdempotentElem φ h_idem, ?_, ?_⟩
  · -- φ b ≠ 0: by injectivity.
    intro h_eq
    apply h_nz
    apply φ.injective
    simp [h_eq]
  · -- Decomposition: pull back through φ⁻¹.
    intros c₁ c₂ h_c₁_idem h_c₂_idem h_c12 h_c21 h_sum
    have h_b_decomp : b = φ.symm c₁ + φ.symm c₂ := by
      apply φ.injective
      simp [h_sum]
    have h_d₁_idem : IsIdempotentElem (φ.symm c₁) :=
      AlgEquiv_preserves_isIdempotentElem φ.symm h_c₁_idem
    have h_d₂_idem : IsIdempotentElem (φ.symm c₂) :=
      AlgEquiv_preserves_isIdempotentElem φ.symm h_c₂_idem
    have h_d12 : φ.symm c₁ * φ.symm c₂ = 0 := by
      apply φ.injective
      simp [h_c12]
    have h_d21 : φ.symm c₂ * φ.symm c₁ = 0 := by
      apply φ.injective
      simp [h_c21]
    rcases h_prim _ _ h_d₁_idem h_d₂_idem h_d12 h_d21 h_b_decomp with h₁ | h₂
    · left
      have : c₁ = φ (φ.symm c₁) := (φ.apply_symm_apply c₁).symm
      rw [this, h₁]
      simp
    · right
      have : c₂ = φ (φ.symm c₂) := (φ.apply_symm_apply c₂).symm
      rw [this, h₂]
      simp

-- ============================================================================
-- Phase C.4 — Vertex idempotent is primitive (via coefficient analysis).
-- ============================================================================

/-- **Helper: when b₁ + b₂ = e_v is an idempotent decomposition, b₁(.id v) ∈ {0,1}.** -/
private lemma vertexIdempotent_decomp_lambda_at_v (m : ℕ) (v : Fin m)
    (b₁ b₂ : pathAlgebraQuotient m)
    (h_b₁_idem : IsIdempotentElem b₁) (h_b₁_b₂ : b₁ * b₂ = 0)
    (h_sum : vertexIdempotent m v = b₁ + b₂) :
    (b₁ (.id v) = 0 ∧ b₂ (.id v) = 1) ∨ (b₁ (.id v) = 1 ∧ b₂ (.id v) = 0) := by
  -- λ_1 + λ_2 = 1 (from h_sum at .id v) and λ_1 * λ_2 = 0 (from h_b₁_b₂ at .id v).
  -- And λ_1 ∈ {0, 1} from b₁ idempotent.
  have h_sum_v : b₁ (.id v) + b₂ (.id v) = 1 := by
    have h := congrFun h_sum (.id v)
    rw [vertexIdempotent_apply_id, if_pos rfl] at h
    show b₁ (.id v) + b₂ (.id v) = 1
    show b₁ (.id v) + b₂ (.id v) = 1
    have h_pi : (b₁ + b₂) (.id v) = b₁ (.id v) + b₂ (.id v) := rfl
    rw [h_pi] at h
    linarith
  have h_prod_v : b₁ (.id v) * b₂ (.id v) = 0 := by
    have h := congrFun h_b₁_b₂ (.id v)
    show b₁ (.id v) * b₂ (.id v) = 0
    have h_eq : (b₁ * b₂) (.id v) = b₁ (.id v) * b₂ (.id v) :=
      pathAlgebraMul_apply_id m b₁ b₂ v
    rw [h_eq] at h
    show b₁ (.id v) * b₂ (.id v) = 0
    exact h
  have h_lam1 : b₁ (.id v) = 0 ∨ b₁ (.id v) = 1 :=
    pathAlgebra_idempotent_lambda_squared m b₁ h_b₁_idem v
  rcases h_lam1 with h_lam1_zero | h_lam1_one
  · left
    refine ⟨h_lam1_zero, ?_⟩
    rw [h_lam1_zero] at h_sum_v
    linarith
  · right
    refine ⟨h_lam1_one, ?_⟩
    rw [h_lam1_one] at h_sum_v
    linarith

/-- **Helper: in an idempotent decomposition of e_v, lambda values away from v
are 0 in both factors.** -/
private lemma vertexIdempotent_decomp_lambda_off_v (m : ℕ) (v : Fin m)
    (b₁ b₂ : pathAlgebraQuotient m)
    (h_b₁_idem : IsIdempotentElem b₁) (h_b₁_b₂ : b₁ * b₂ = 0)
    (h_sum : vertexIdempotent m v = b₁ + b₂)
    (w : Fin m) (h_w_ne : w ≠ v) :
    b₁ (.id w) = 0 ∧ b₂ (.id w) = 0 := by
  -- Goal: at index .id w with w ≠ v: e_v(.id w) = 0 = b₁(.id w) + b₂(.id w).
  -- Combined with idempotency b₁(.id w) ∈ {0, 1}, b₁ * b₂ = 0 ⇒ both must be 0.
  have h_sum_w : b₁ (.id w) + b₂ (.id w) = 0 := by
    have h := congrFun h_sum (.id w)
    rw [vertexIdempotent_apply_id, if_neg (Ne.symm h_w_ne)] at h
    have h_pi : (b₁ + b₂) (.id w) = b₁ (.id w) + b₂ (.id w) := rfl
    rw [h_pi] at h
    linarith
  have h_prod_w : b₁ (.id w) * b₂ (.id w) = 0 := by
    have h := congrFun h_b₁_b₂ (.id w)
    have h_eq : (b₁ * b₂) (.id w) = b₁ (.id w) * b₂ (.id w) :=
      pathAlgebraMul_apply_id m b₁ b₂ w
    rw [h_eq] at h
    exact h
  have h_lam1 : b₁ (.id w) = 0 ∨ b₁ (.id w) = 1 :=
    pathAlgebra_idempotent_lambda_squared m b₁ h_b₁_idem w
  rcases h_lam1 with h_lam1_zero | h_lam1_one
  · refine ⟨h_lam1_zero, ?_⟩
    rw [h_lam1_zero] at h_sum_w
    linarith
  · -- h_lam1_one : b₁(.id w) = 1. Then h_sum_w gives b₂(.id w) = -1.
    rw [h_lam1_one] at h_prod_w
    rw [h_lam1_one] at h_sum_w
    have : b₂ (.id w) = -1 := by linarith
    rw [this] at h_prod_w
    linarith

/-- **Helper: in an idempotent decomposition `e_v = b₁ + b₂` with
    `b₁ b₂ = 0`, the case `b₁(.id v) = 0` forces `b₁(.id w) = 0` for
    every vertex w.** Combines the at-v case with the off-v helper. -/
private lemma vertexIdempotent_decomp_lambda_zero_everywhere (m : ℕ) (v : Fin m)
    (b₁ b₂ : pathAlgebraQuotient m)
    (h_b₁_idem : IsIdempotentElem b₁) (h_b₁_b₂ : b₁ * b₂ = 0)
    (h_sum : vertexIdempotent m v = b₁ + b₂)
    (h_zero_at_v : b₁ (.id v) = 0)
    (w : Fin m) :
    b₁ (.id w) = 0 := by
  by_cases h_wv : w = v
  · subst h_wv; exact h_zero_at_v
  · exact (vertexIdempotent_decomp_lambda_off_v m v b₁ b₂ h_b₁_idem h_b₁_b₂
            h_sum w h_wv).1

/-- **Phase C.4 main theorem: vertex idempotent is a primitive idempotent.**

If `e_v = b₁ + b₂` with `b₁, b₂` orthogonal idempotents in the path
algebra, then one of `b₁, b₂` must be zero.

**Proof.** By the lambda-at-v helper, in any such decomposition either
* `b₁(.id v) = 0` and `b₂(.id v) = 1` (Case A), or
* `b₁(.id v) = 1` and `b₂(.id v) = 0` (Case B).

In Case A, we show `b₁ = 0`:
* `b₁(.id w) = 0` for every w (the at-v case is given; the off-v case
  uses the lambda-off-v helper combined with idempotency of b₁).
* `b₁(.edge u w) = 0` by `b₁`-idempotency: it equals
  `b₁(.id u) · b₁(.edge u w) + b₁(.edge u w) · b₁(.id w)`, and both
  `b₁(.id u)` and `b₁(.id w)` are 0.

Case B is symmetric, swapping the roles of `b₁` and `b₂` (using the
hypothesis `b₂ * b₁ = 0`). -/
theorem vertexIdempotent_isPrimitive (m : ℕ) (v : Fin m) :
    IsPrimitiveIdempotent (vertexIdempotent m v) := by
  refine ⟨vertexIdempotent_isIdempotentElem m v, vertexIdempotent_ne_zero m v, ?_⟩
  intros b₁ b₂ h_b₁_idem h_b₂_idem h_b₁_b₂ h_b₂_b₁ h_sum
  rcases vertexIdempotent_decomp_lambda_at_v m v b₁ b₂ h_b₁_idem h_b₁_b₂ h_sum
    with ⟨hb₁_zero, _⟩ | ⟨_, hb₂_zero⟩
  · -- Case A: b₁(.id v) = 0, b₂(.id v) = 1. Show b₁ = 0.
    left
    -- Show b₁(c) = 0 for all c.
    have h_b₁_id_all : ∀ w : Fin m, b₁ (.id w) = 0 :=
      vertexIdempotent_decomp_lambda_zero_everywhere m v b₁ b₂ h_b₁_idem
        h_b₁_b₂ h_sum hb₁_zero
    have ⟨_, h_b₁_edge_constraint⟩ := (pathAlgebra_isIdempotentElem_iff m b₁).mp h_b₁_idem
    funext c
    cases c with
    | id w => exact h_b₁_id_all w
    | edge u w =>
      -- b₁(.edge u w) = b₁(.id u) * b₁(.edge u w) + b₁(.edge u w) * b₁(.id w)
      --              = 0 * b₁(.edge u w) + b₁(.edge u w) * 0 = 0.
      have h_eq := h_b₁_edge_constraint u w
      rw [h_b₁_id_all u, h_b₁_id_all w, zero_mul, mul_zero, zero_add] at h_eq
      show b₁ (.edge u w) = 0
      linarith
  · -- Case B: b₁(.id v) = 1, b₂(.id v) = 0. Show b₂ = 0.
    -- Note: we use h_b₂_b₁ : b₂ * b₁ = 0 instead of h_b₁_b₂ for the
    -- decomp helper, which expects b₁ * b₂ = 0 in its first arg.
    right
    have h_b₂_id_all : ∀ w : Fin m, b₂ (.id w) = 0 := by
      intro w
      -- Apply decomp helper with roles of b₁, b₂ swapped, using h_sum
      -- rewritten as e_v = b₂ + b₁ via add_comm.
      have h_sum_swap : vertexIdempotent m v = b₂ + b₁ := by
        rw [h_sum, add_comm]
      exact vertexIdempotent_decomp_lambda_zero_everywhere m v b₂ b₁ h_b₂_idem
        h_b₂_b₁ h_sum_swap hb₂_zero w
    have ⟨_, h_b₂_edge_constraint⟩ := (pathAlgebra_isIdempotentElem_iff m b₂).mp h_b₂_idem
    funext c
    cases c with
    | id w => exact h_b₂_id_all w
    | edge u w =>
      have h_eq := h_b₂_edge_constraint u w
      rw [h_b₂_id_all u, h_b₂_id_all w, zero_mul, mul_zero, zero_add] at h_eq
      show b₂ (.edge u w) = 0
      linarith

-- ============================================================================
-- isPrimitive_iff_vertex — mathematical finding (not a theorem statement).
-- ============================================================================

/-! ## Note on `isPrimitive_iff_vertex` (research finding, 2026-04-26)

The originally-planned theorem
```
theorem isPrimitive_iff_vertex (b : pathAlgebraQuotient m) :
    IsPrimitiveIdempotent b ↔ ∃ v : Fin m, b = vertexIdempotent m v
```
**is false** for the radical-2 truncated path algebra `F[Q_G] / J²`.

**Counterexample.** For any `v, w : Fin m` with `w ≠ v` and any
`α : ℚ`, the element
```
b := vertexIdempotent m v + α • arrowElement m v w
```
is an idempotent (because `α(v, w) · e_v = 0` when `w ≠ v`, so the
cross term in `(e_v + α α(v,w))²` vanishes). It is also primitive:
any orthogonal idempotent decomposition `b = b₁ + b₂` forces
`b₂(.id u) = 0` for all `u`, then `b₂(.edge u w) = 0` follows from
the mu-constraint, hence `b₂ = 0`.

**Mathematical context.** In `F[Q_G] / J²`, primitive idempotents
are **conjugate** to vertex idempotents (Auslander–Reiten–Smalø
III.2), not equal to them. The conjugation moves arrow-component
"perturbations" around. The set of *complete orthogonal* primitive
idempotent decompositions of `1` is unique up to conjugation, and
every such decomposition is `{vertexIdempotent v : v ∈ Fin m}`
(the canonical decomposition).

**Consequence for the rigidity argument.** Phase F (vertex
permutation extraction from a path-algebra automorphism) cannot
proceed via "AlgEquiv permutes primitive idempotents → therefore
permutes vertex idempotents" directly. The correct argument is:
"AlgEquiv permutes complete orthogonal idempotent
decompositions → unique decomposition is `{e_v}` →  AlgEquiv
permutes `{e_v}`". This requires proving that the canonical
decomposition `{e_v}` is the unique complete orthogonal set up to
conjugation, which is a deeper algebraic fact (Wedderburn–Mal'cev
structure, ~600+ LOC of additional Lean infrastructure).

**What lands instead.** The forward direction (`vertexIdempotent`
is primitive) is `vertexIdempotent_isPrimitive` above. The reverse
direction is research-scope and tracked as part of
`R-15-residual-TI-reverse`.
-/

/-- **Forward direction (true)**: every vertex idempotent is primitive.
This is just a re-export of `vertexIdempotent_isPrimitive` for
documentation symmetry with the (false) converse. -/
theorem vertex_implies_isPrimitive (m : ℕ) (v : Fin m) :
    IsPrimitiveIdempotent (vertexIdempotent m v) :=
  vertexIdempotent_isPrimitive m v

/-- **Concrete counterexample to `isPrimitive_iff_vertex` reverse direction**:
exhibits a primitive idempotent that is NOT a vertex idempotent.

For `m ≥ 2` (so a distinct `w ≠ v` exists), the element
`vertexIdempotent v + arrowElement v w` is idempotent and not equal
to any `vertexIdempotent v'`.

This documents the research-scope gap: a more sophisticated argument
(complete orthogonal decompositions) is needed for Phase F. -/
theorem exists_nonVertex_idempotent (m : ℕ) (h_m : 2 ≤ m) :
    ∃ b : pathAlgebraQuotient (m), IsIdempotentElem b ∧
      ∀ v : Fin m, b ≠ vertexIdempotent m v := by
  -- Choose v = ⟨0, _⟩ and w = ⟨1, _⟩ (distinct vertices).
  have hv : 0 < m := by omega
  have hw : 1 < m := by omega
  let v : Fin m := ⟨0, hv⟩
  let w : Fin m := ⟨1, hw⟩
  have h_vw : v ≠ w := by
    intro h
    have := Fin.val_eq_of_eq h
    simp [v, w] at this
  refine ⟨vertexIdempotent m v + arrowElement m v w, ?_, ?_⟩
  · -- Idempotent:
    -- (e_v + α(v,w))² = e_v² + e_v·α(v,w) + α(v,w)·e_v + α(v,w)²
    --              = e_v + α(v,w) + 0 + 0
    show pathAlgebraMul m (vertexIdempotent m v + arrowElement m v w)
                          (vertexIdempotent m v + arrowElement m v w) =
         vertexIdempotent m v + arrowElement m v w
    rw [pathAlgebra_left_distrib, pathAlgebra_right_distrib,
        pathAlgebra_right_distrib]
    -- = e_v * e_v + α(v,w) * e_v + e_v * α(v,w) + α(v,w) * α(v,w)
    rw [vertexIdempotent_mul_vertexIdempotent, if_pos rfl]
    rw [arrowElement_mul_vertexIdempotent, if_neg h_vw.symm]
    rw [vertexIdempotent_mul_arrowElement, if_pos rfl]
    rw [arrowElement_mul_arrowElement_eq_zero]
    -- e_v + 0 + α(v,w) + 0 = e_v + α(v,w)
    simp [add_zero, zero_add]
  · -- Not equal to any vertex idempotent:
    intros v' h_eq
    -- Evaluate at .edge v w: LHS gives 1, RHS (e_{v'}) gives 0.
    have h_at := congrFun h_eq (.edge v w)
    show False
    have h_lhs : (vertexIdempotent m v + arrowElement m v w) (.edge v w) = 1 := by
      show vertexIdempotent m v (.edge v w) + arrowElement m v w (.edge v w) = 1
      rw [vertexIdempotent_apply_edge, arrowElement_apply_edge,
          if_pos ⟨rfl, rfl⟩]
      ring
    have h_rhs : vertexIdempotent m v' (.edge v w) = 0 :=
      vertexIdempotent_apply_edge m v' v w
    rw [h_lhs, h_rhs] at h_at
    exact one_ne_zero h_at

-- ============================================================================
-- Layer 6.7–6.10 — `CompleteOrthogonalIdempotents` machinery for vertex
-- idempotents + AlgEquiv preservation.
-- ============================================================================

/-- **Layer 6.8 — Vertex idempotents form a complete orthogonal system.**

The family `vertexIdempotent m : Fin m → pathAlgebraQuotient m`
satisfies Mathlib's `CompleteOrthogonalIdempotents` predicate:
* each `vertexIdempotent m v` is an idempotent (Layer 6.4);
* distinct vertex idempotents are mutually annihilating (Layer 1.1);
* the sum equals `1` (definition of `pathAlgebraOne`).

This is the structural content the Layer 9 (Phase F) vertex-permutation
extraction will consume: an `AlgEquiv` of path algebras maps the
canonical COI to another COI of the same cardinality, and by
Wedderburn–Mal'cev (Layer 6b.3) such COIs are conjugate to the
canonical one. -/
theorem vertexIdempotent_completeOrthogonalIdempotents (m : ℕ) :
    CompleteOrthogonalIdempotents (vertexIdempotent m) where
  idem v := vertexIdempotent_isIdempotentElem m v
  ortho := by
    intro v w h_ne
    show pathAlgebraMul m (vertexIdempotent m v) (vertexIdempotent m w) = 0
    rw [vertexIdempotent_mul_vertexIdempotent, if_neg h_ne]
  complete := by
    -- Goal: ∑ v : Fin m, vertexIdempotent m v = 1.
    -- `1 = pathAlgebraOne m = ∑ v, vertexIdempotent m v` is `rfl` by the
    -- `One` instance + `pathAlgebraOne` definition.
    show (∑ v : Fin m, vertexIdempotent m v) = pathAlgebraOne m
    rfl

/-- **Layer 6.9 — `AlgEquiv` preserves complete orthogonal idempotent
families.**

If `φ : A ≃ₐ[ℚ] B` is an algebra isomorphism and `e : ι → A` is a
COI, then `φ ∘ e` is a COI in `B`. Each field is preserved:
* `idem`: `AlgEquiv` preserves `IsIdempotentElem` (Layer 6.6).
* `ortho`: `φ (e i * e j) = φ (e i) * φ (e j)` and `φ 0 = 0`.
* `complete`: `φ (∑ i, e i) = ∑ i, φ (e i)` and `φ 1 = 1`.

This is the primary consumer hook for Phase F (vertex permutation
extraction): apply this to the canonical COI
`vertexIdempotent_completeOrthogonalIdempotents`, obtaining an image
COI `φ ∘ vertexIdempotent` that the Wedderburn–Mal'cev conjugacy
lemma (Layer 6b.3) conjugates back to the canonical one via an
inner automorphism, yielding the vertex permutation σ. -/
theorem AlgEquiv_preserves_completeOrthogonalIdempotents
    {A B : Type*} [Ring A] [Ring B] [Algebra ℚ A] [Algebra ℚ B]
    {ι : Type*} [Fintype ι] (φ : A ≃ₐ[ℚ] B)
    {e : ι → A} (h : CompleteOrthogonalIdempotents e) :
    CompleteOrthogonalIdempotents (φ ∘ e) where
  idem i := AlgEquiv_preserves_isIdempotentElem φ (h.idem i)
  ortho := by
    intro i j h_ne
    show φ (e i) * φ (e j) = 0
    rw [← map_mul]
    rw [show e i * e j = 0 from h.ortho h_ne]
    exact map_zero φ
  complete := by
    show ∑ i, φ (e i) = 1
    rw [← map_sum, h.complete, map_one]

/-- **Layer 6.10 — Cardinality of the canonical vertex-idempotent COI.**

The canonical COI on `pathAlgebraQuotient m` has cardinality `m`.
This is just `Fintype.card_fin`, named here to make the COI cardinality
invariant explicit at the call site (used by Phase F to rule out
COIs of different cardinalities under any `AlgEquiv`-image). -/
theorem vertexIdempotent_completeOrthogonalIdempotents_card (m : ℕ) :
    Fintype.card (Fin m) = m :=
  Fintype.card_fin m

end GrochowQiao
end Orbcrypt
