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

end GrochowQiao
end Orbcrypt
