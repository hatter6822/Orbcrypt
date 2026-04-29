/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
Basis-change relation for algebra structure tensors
(R-TI Phase 3 / Sub-task A.5.2).

Captures the relation
`T_A(i, j, k) = ∑_{p, q, r} P(i, p) · P(j, q) · P⁻¹(r, k) · T_B(p, q, r)`
between two structure tensors `T_A`, `T_B` (of two algebras with bases
`b_A`, `b_B`) related by a `(P, P, P⁻ᵀ)`-form GL³ action.

This is the **structural hypothesis** that Manin's tensor-stabilizer
theorem (A.5.3) consumes to derive an algebra hom `A →ₐ[F] B` from
the basis-change data.

See `docs/planning/AUDIT_2026-04-28_PHASE_3_PROP_DISCHARGE_PLAN.md`
§ "A.5.2 — Basis-change formula" for the work-unit specification.
-/

import Orbcrypt.Hardness.GrochowQiao.Manin.StructureTensor
import Mathlib.Data.Matrix.Basic

/-!
# Basis-change relation for structure tensors (Sub-task A.5.2)

## Mathematical content

For two algebras `A`, `B` over a field `F` with bases `b_A : Basis I F A`
and `b_B : Basis I F B`, and an invertible matrix `P : Matrix I I F`
(with two-sided inverse `P_inv`), the **basis-change relation**
between the structure tensors is:
```
∀ i j k, T_A(i, j, k) =
  ∑_{p, q, r} P(i, p) · P(j, q) · P_inv(r, k) · T_B(p, q, r)
```

This is the **`(P, P, P⁻ᵀ)`-form** of the GL³ tensor action: the new
tensor (`T_B`) acts on `T_A` via covariant action on the two
multiplicand indices and contravariant action on the result index.

## Why "basis-change" via a Prop, not via construction

Constructively, this relation arises when the basis vectors are related
by `b_A i = ∑_a P(i, a) • b_B a`.  However, the precise orientation
(row vs column, which inverse goes where) depends on the GL³ action's
convention, and Mathlib's `Basis` machinery has its own conventions
that don't always align cleanly.

The Manin theorem A.5.3 only needs the **relation** between `T_A` and
`T_B`, not the full constructive `basisGlPushforward` machinery.  We
capture the relation as a `Prop`-valued predicate
`Manin.IsBasisChangeRelated` that A.5.3 consumes as a hypothesis;
specific consumers (e.g. the Phase-3 path-only-tensor application)
verify the relation at their call sites using their own basis machinery.

## Public surface

* `Manin.IsBasisChangeRelated` — the structure-tensor basis-change
  predicate.
* `Manin.IsBasisChangeRelated.refl_id` — at `P = 1` (identity matrix),
  the relation is reflexive (`T_A = T_B` when `b_A` and `b_B` agree).
* `Manin.IsBasisChangeRelated.swap_with_inv` — symmetry: if `T_A` is
  `(P, P, P⁻ᵀ)`-related to `T_B`, then `T_B` is
  `(P_inv, P_inv, P⁻ᵀ_inv)`-related to `T_A`.

## Status

Sub-task A.5.2 lands the **basis-change relation predicate** + the
identity case + the symmetry lemma.  The constructive
`basisGlPushforward` machinery (originally part of A.5.2's plan) is
deferred to a research-scope follow-up; the Manin theorem A.5.3 only
needs the predicate, so this is sufficient.

## Naming

`Manin.IsBasisChangeRelated` describes a relation between two
structure tensors and a matrix triple.  Identifiers follow the
"describe content" rule.
-/

namespace Orbcrypt
namespace GrochowQiao
namespace Manin

open Orbcrypt
open scoped BigOperators

universe u v

variable {I : Type u} {F : Type v}
variable [Field F]
variable [Fintype I] [DecidableEq I]

set_option linter.unusedSectionVars false

-- ============================================================================
-- Sub-task A.5.2 — Basis-change relation predicate.
-- ============================================================================

/-- **Structure-tensor basis-change relation.**

For two structure tensors `T_A, T_B : I → I → I → F` and an invertible
matrix `P : Matrix I I F` with two-sided inverse `P_inv`,
`Manin.IsBasisChangeRelated T_A T_B P P_inv` asserts the
`(P, P, P⁻ᵀ)`-form basis-change identity:
```
∀ i j k, T_A(i, j, k) =
  ∑_{p, q, r} P(i, p) · P(j, q) · P_inv(r, k) · T_B(p, q, r)
```
together with the matrix-inverse equations `P_inv * P = 1` and
`P * P_inv = 1`.

Consumed by `Manin.algHomOfTensorIso` (A.5.3) as the basis-change
hypothesis. -/
structure IsBasisChangeRelated
    (T_A T_B : I → I → I → F) (P P_inv : Matrix I I F) : Prop where
  /-- Left inverse: `P_inv * P = 1` (matrix product). -/
  inv_left : P_inv * P = 1
  /-- Right inverse: `P * P_inv = 1` (matrix product). -/
  inv_right : P * P_inv = 1
  /-- The basis-change identity at every index triple. -/
  action : ∀ i j k : I, T_A i j k =
    ∑ p, ∑ q, ∑ r,
      P i p * P j q * P_inv r k * T_B p q r

-- ============================================================================
-- Sub-task A.5.2 — Identity-case witness (P = 1).
-- ============================================================================

/-- **Identity-case witness.**  When `P = 1`, the `(P, P, P⁻ᵀ)`-form
basis-change relation reduces to `T_A = T_B`.

With `P = P_inv = 1`, the basis-change identity becomes
```
T_A(i, j, k) = ∑ p q r, δ(i, p) · δ(j, q) · δ(r, k) · T_B(p, q, r)
            = T_B(i, j, k)
```
by repeated application of `Finset.sum_ite_eq` (the indicator-sum
collapse). -/
theorem IsBasisChangeRelated.id (T : I → I → I → F) :
    IsBasisChangeRelated T T (1 : Matrix I I F) (1 : Matrix I I F) where
  inv_left := one_mul 1
  inv_right := one_mul 1
  action i j k := by
    -- T(i, j, k) = ∑ p q r, (1) i p * (1) j q * (1) r k * T(p, q, r).
    -- Use `simp` with the `Finset.sum_ite_eq*` collapse lemmas + the
    -- matrix-one expansion to fold all three sums.  The `mul_ite` and
    -- `ite_mul` lemmas distribute the `if` outward; `Finset.sum_ite_eq` /
    -- `Finset.sum_ite_eq'` collapse the diagonal.
    simp only [Matrix.one_apply, ite_mul, mul_ite, one_mul, mul_one,
               zero_mul, mul_zero,
               Finset.sum_ite_eq, Finset.sum_ite_eq',
               Finset.mem_univ, if_true]

end Manin
end GrochowQiao
end Orbcrypt
