/-
Abstract algebra structure tensor (R-TI Phase 3 / Sub-task A.5.1).

Defines `Manin.structureTensor (b : Basis I F A) : I → I → I → F`, the
hand-rolled abstraction of "the 3-tensor whose `(i, j, k)` entry is the
coefficient of `b k` in the product `b i * b j` (in the basis `b`)".

Mathlib does NOT provide this concept at the pinned commit `fa6418a8`,
so we hand-roll it.  The output of this module is consumed by
`Manin/BasisChange.lean` (A.5.2) for the basis-change formula and by
`Manin/TensorStabilizer.lean` (A.5.3) for the central tensor-stabilizer
theorem.

See `docs/planning/AUDIT_2026-04-28_PHASE_3_PROP_DISCHARGE_PLAN.md`
§ "A.5.1 — Abstract structure tensor" for the work-unit specification.
-/

import Mathlib.LinearAlgebra.Basis.Defs
import Mathlib.Algebra.Algebra.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Fintype.BigOperators

/-!
# Abstract algebra structure tensor (Sub-task A.5.1)

## Mathematical content

For an algebra `A` over a field `F` with a basis `b : Basis I F A`
indexed by a finite type `I`, the **structure tensor** of the algebra
in this basis is the 3-tensor `T : I → I → I → F` defined by
```
T(i, j, k) := (b.repr (b i * b j)) k
```
i.e. `T(i, j, k)` is the coefficient of `b k` in the basis-expansion
of the product `b i * b j`.

The structure tensor encodes the algebra's multiplication: from `T`
together with the basis, we can recover all products via the
`structureTensor_recovers_mul` identity:
```
b i * b j = ∑ k, T(i, j, k) • b k
```

## Public surface

* `Manin.structureTensor b` — the structure tensor of `A` in basis `b`.
* `Manin.structureTensor_apply` — definitional unfolding.
* `Manin.structureTensor_recovers_mul` — the multiplication-recovery
  identity.

## Status

Sub-task A.5.1 lands the **abstract structure-tensor extraction**
unconditionally.  Consumed by `Manin/BasisChange.lean` (A.5.2) and
`Manin/TensorStabilizer.lean` (A.5.3).

## Naming

`Manin.structureTensor` is namespaced under `Manin` (signalling
reusability — could be upstreamed to Mathlib as `Algebra.structureTensor`
when the `(P, P, P⁻ᵀ)`-form Manin theorem is upstreamed).
-/

-- The `linter.unusedSectionVars` linter fires on theorems whose
-- generic-context typeclass arguments (e.g. `[Fintype I] [DecidableEq I]`)
-- aren't strictly needed for the specific theorem's proof.  In this
-- module we declare both at the section level for ergonomics — every
-- consumer of `Manin.structureTensor` works with `[Fintype I]`-indexed
-- bases — and accept the cosmetic warnings on the apply lemma.
set_option linter.unusedSectionVars false

namespace Orbcrypt
namespace GrochowQiao
namespace Manin

open Orbcrypt
open Module
open scoped BigOperators

universe u v w

variable {I : Type u} {F : Type v} {A : Type w}
variable [Field F] [Ring A] [Algebra F A]
variable [Fintype I] [DecidableEq I]

-- ============================================================================
-- Sub-task A.5.1 — Algebra structure-tensor extraction.
-- ============================================================================

/-- **Abstract algebra structure tensor.**

For an algebra `A` over a field `F` with basis `b : Basis I F A`,
`Manin.structureTensor b : I → I → I → F` is the 3-tensor
`T(i, j, k) := (b.repr (b i * b j)) k` — the coefficient of `b k` in
the basis-expansion of the product `b i * b j`.

This encodes the algebra's multiplication: see
`Manin.structureTensor_recovers_mul` for the recovery identity. -/
noncomputable def structureTensor (b : Basis I F A) : I → I → I → F :=
  fun i j k => (b.repr (b i * b j)) k

omit [Fintype I] [DecidableEq I] in
/-- **Apply lemma:** unfolding of `Manin.structureTensor` to its
underlying `Basis.repr` definition. -/
@[simp] theorem structureTensor_apply (b : Basis I F A) (i j k : I) :
    structureTensor b i j k = (b.repr (b i * b j)) k := rfl

-- ============================================================================
-- Sub-task A.5.1 — Multiplication recovery from the structure tensor.
-- ============================================================================

/-- **Multiplication-recovery identity.**

The structure tensor `T = Manin.structureTensor b` together with the
basis `b` determines the algebra's multiplication:
```
b i * b j = ∑ k, T(i, j, k) • b k
```

**Proof technique.** Apply `Basis.sum_repr` (Mathlib) to
`b i * b j : A`, expressing it as the linear combination of basis
elements with coefficients `b.repr (b i * b j)`.  Convert the
`Finsupp.sum` to a `Finset.sum` over `Finset.univ` (since `I` is
`Fintype`) via `Finsupp.sum_fintype` (or by direct unfolding). -/
theorem structureTensor_recovers_mul (b : Basis I F A) (i j : I) :
    b i * b j = ∑ k, structureTensor b i j k • b k := by
  -- `Basis.sum_repr [Fintype ι] (b : Basis ι R M) (u : M) :
  --   ∑ i, b.repr u i • b i = u` is the direct identity we need
  -- (specialised to `u := b i * b j`).  Combined with the definition
  -- `structureTensor b i j k = (b.repr (b i * b j)) k`, this matches
  -- the goal up to definitional equality.
  exact (Basis.sum_repr b (b i * b j)).symm

end Manin
end GrochowQiao
end Orbcrypt
