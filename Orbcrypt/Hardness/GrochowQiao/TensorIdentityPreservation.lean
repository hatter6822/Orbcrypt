/-
GL³-invariance of polynomial tensor identities (R-TI Phase 3 /
Sub-task A.2).

Establishes the **associativity polynomial identity** as a `Prop`-valued
predicate `IsAssociativeTensor T` and shows the Grochow–Qiao encoder
satisfies it on full-adjacency graphs.  The general statement that the
GL³ action preserves the predicate is captured as a research-scope
`Prop` `IsAssociativeTensorPreservedByGL3` and discharged unconditionally
in the identity case.  The general (non-identity) discharge of this
`Prop` is part of the bundled research-scope content
`GL3InducesAlgEquivOnPathSubspace` (Sub-task A.5 / Manin's tensor-
stabilizer theorem) and is consumed by `AlgEquivFromGL3.lean`.

See `docs/planning/R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md`
§ "Sub-task A.2 — GL³ action preserves polynomial identities" for the
work-unit decomposition.
-/

import Orbcrypt.Hardness.TensorAction
import Orbcrypt.Hardness.GrochowQiao.EncoderPolynomialIdentities
import Mathlib.Algebra.BigOperators.Group.Finset.Basic

/-!
# GL³-invariance of the associativity polynomial identity (Sub-task A.2)

## Mathematical content

A 3-tensor `T : Fin n → Fin n → Fin n → F` over a commutative semiring
is **associative** if its entries satisfy
```
∀ i j k l, ∑ a, T(i, j, a) · T(a, k, l) = ∑ a, T(j, k, a) · T(i, a, l).
```

When `F` is a field and `g = (A, B, C) : GL n F × GL n F × GL n F`, the
GL³ action `g • T = tensorContract A B C T` produces a new tensor
satisfying an associativity identity *with the same indices* —
provided the original tensor's identity holds and we account for the
matrix-multiplication structure correctly.

**Caveat (research-scope content not landed in this file).** The full
proof of GL³ preservation for arbitrary GL³ requires a substantial
sum-arithmetic argument (~150 LOC of `Finset.sum_comm`, `Finset.mul_sum`,
and multilinearity manipulations).  In Sub-task A.2.2's detailed plan,
the identity threads through every axis of the contraction.  For the
partial-discharge path of Phase 3, the `IsAssociativeTensor` predicate
and the trivial GL³-preservation case (identity GL³) are the pieces
consumed by `AlgEquivFromGL3.lean`'s research-scope `Prop`; the deeper
preservation content lives inside that `Prop`'s discharge obligation.

## Public surface

* `IsAssociativeTensor T` (`Prop`-valued predicate).
* `encoder_isAssociativeTensor_full_path`: the Grochow–Qiao encoder
  satisfies the associativity identity on full-adjacency graphs.
* `IsAssociativeTensorPreservedByGL3 n F` (research-scope `Prop`).
* `isAssociativeTensorPreservedByGL3_identity_case`: identity GL³
  preserves the predicate (unconditional witness).

## Status

Lands the **associativity-tensor predicate** + the **encoder-is-
associative-on-full-adjacency theorem** + the **identity-GL³ case** of
the GL³-preservation Prop.  The general GL³-invariance is part of the
research-scope content captured by `GL3InducesAlgEquivOnPathSubspace`
and is not landed here directly.

## Naming

Identifiers describe content (associativity tensor, encoder is
associative, identity preservation), not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt
open scoped BigOperators

-- ============================================================================
-- Sub-task A.2.1 — IsAssociativeTensor predicate.
-- ============================================================================

/-- **Sub-task A.2.1 — Associative-tensor predicate.**

A 3-tensor `T : Tensor3 n F` over a commutative semiring is
*associative* if its entries satisfy the associativity polynomial
identity
```
∀ i j k l, ∑ a, T(i, j, a) · T(a, k, l) = ∑ a, T(j, k, a) · T(i, a, l).
```

When `T = grochowQiaoEncode m adj` restricted to path-algebra slots,
this is the structure-tensor associativity inherited from
`pathAlgebraQuotient m`'s associativity (`pathAlgebraMul_assoc`). -/
def IsAssociativeTensor {n : ℕ} {F : Type*} [CommSemiring F]
    (T : Tensor3 n F) : Prop :=
  ∀ i j k l : Fin n,
    (∑ a : Fin n, T i j a * T a k l) =
    (∑ a : Fin n, T j k a * T i a l)

-- ============================================================================
-- Sub-task A.2.3 — The Grochow–Qiao encoder is associative.
-- ============================================================================

/-- **Sub-task A.2.3 — The encoder satisfies the associativity identity
on full-adjacency graphs.**

The Grochow–Qiao encoder's associativity identity holds **on path-
algebra quadruples** — see `encoder_assoc_path` (Sub-task A.1.0).  When
the adjacency `adj` makes every slot path-algebra (e.g., the complete
directed graph `adj := fun _ _ => true`), the restricted-to-path identity
becomes the unrestricted one and the predicate `IsAssociativeTensor`
applies.

For arbitrary `adj` the encoder is associative on path-algebra
quadruples and zero on mixed quadruples (Sub-task A.1.3); the full
predicate-statement lift requires checking that mixed quadruples
contribute zero on both sides — that follow-up is the Sub-task A.2.3
"extension" content which is part of the research-scope `Prop` bundle. -/
theorem encoder_isAssociativeTensor_full_path
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (h_full : ∀ i : Fin (dimGQ m), isPathAlgebraSlot m adj i = true) :
    IsAssociativeTensor (grochowQiaoEncode m adj) := by
  intro i j k l
  exact encoder_assoc_path m adj i j k l (h_full i) (h_full j)
                            (h_full k) (h_full l)

-- ============================================================================
-- Sub-task A.2.2 — GL³ preservation as a research-scope Prop.
-- ============================================================================

/-- **Sub-task A.2.2 — GL³ preservation as a research-scope Prop.**

The general statement that GL³ preserves `IsAssociativeTensor` is
captured here as a `Prop`-valued obligation.  Its full proof (Sub-task
A.2.2 in the plan, ~150 LOC of `Finset.sum_comm` manipulation) is
research-scope and is part of the `GL3InducesAlgEquivOnPathSubspace`
discharge bundle landed in `AlgEquivFromGL3.lean`.

Discharging this `Prop` *unconditionally* would deliver the
multilinear-algebra core of the Manin tensor-stabilizer theorem at the
polynomial-identity level. -/
def IsAssociativeTensorPreservedByGL3 (n : ℕ) (F : Type*) [Field F] : Prop :=
  ∀ (T : Tensor3 n F)
    (g : GL (Fin n) F × GL (Fin n) F × GL (Fin n) F),
    IsAssociativeTensor T → IsAssociativeTensor (g • T)

/-- **Identity-GL³ case witness.**

At `g = 1`, `g • T = T` (`one_smul` on the `tensorAction`), so
`IsAssociativeTensor T → IsAssociativeTensor (g • T)` holds by
reflexivity.  This is the **unconditional witness** that the
research-scope `Prop` `IsAssociativeTensorPreservedByGL3` is
inhabitable on at least the identity case. -/
theorem isAssociativeTensorPreservedByGL3_identity_case
    {n : ℕ} {F : Type*} [Field F]
    (T : Tensor3 n F) (h : IsAssociativeTensor T) :
    IsAssociativeTensor
      ((1 : GL (Fin n) F × GL (Fin n) F × GL (Fin n) F) • T) := by
  rw [one_smul]
  exact h

end GrochowQiao
end Orbcrypt
