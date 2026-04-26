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

end GrochowQiao
end Orbcrypt
