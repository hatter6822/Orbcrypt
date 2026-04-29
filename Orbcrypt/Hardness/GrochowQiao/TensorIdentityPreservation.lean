/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
Associativity polynomial identity for 3-tensors (R-TI Phase 3 /
Sub-task A.2).

Defines the `IsAssociativeTensor` predicate (the polynomial identity
that any 3-tensor obtained as the structure tensor of an associative
algebra satisfies), and shows the Grochow–Qiao encoder satisfies it on
full-adjacency graphs.

**Mathematical correctness note.**  The plan's Sub-task A.2 originally
described "GL³ preservation of the associativity polynomial identity"
as a `~150 LOC mechanical sum manipulation`.  This is **mathematically
incorrect** for arbitrary GL³: only the structure-tensor-preserving
sub-class of GL³ actions (specifically, `(P, P, P⁻ᵀ)`-shaped triples
that correspond to a basis change of the underlying algebra) preserves
associativity.  Generic GL³ does **not** preserve the identity — see
the `Mathematical correctness` section of this module's docstring.

This file therefore **drops** the misleading
`IsAssociativeTensorPreservedByGL3` claim that an earlier version of
this module carried.  The correct preservation content (basis-change
preservation + the Manin tensor-stabilizer subgroup characterisation)
is part of the research-scope bundle
`GL3InducesAlgEquivOnPathSubspace` consumed by `AlgEquivFromGL3.lean`.

See `docs/planning/R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md`
§ "Sub-task A.2 — GL³ action preserves polynomial identities" for the
plan's original work-unit decomposition.
-/

import Orbcrypt.Hardness.TensorAction
import Orbcrypt.Hardness.GrochowQiao.EncoderPolynomialIdentities
import Mathlib.Algebra.BigOperators.Group.Finset.Basic

/-!
# Associativity polynomial identity for 3-tensors (Sub-task A.2)

## Mathematical content

A 3-tensor `T : Fin n → Fin n → Fin n → F` over a commutative semiring
is **associative** if its entries satisfy
```
∀ i j k l, ∑ a, T(i, j, a) · T(a, k, l) = ∑ a, T(j, k, a) · T(i, a, l).
```

For an associative algebra `A` with basis `(e_i)` and structure tensor
`T_{ij}^k := coefficient of e_k in e_i · e_j`, this identity is
equivalent to the algebra's associativity `(e_i · e_j) · e_k = e_i ·
(e_j · e_k)` expanded in the basis.

## Mathematical correctness — GL³ preservation

The plan's Sub-task A.2.2 originally described "for arbitrary GL³ `g`,
`IsAssociativeTensor T → IsAssociativeTensor (g • T)`" as a
"~150 LOC mechanical sum manipulation".  **This claim is mathematically
incorrect.**

The associativity polynomial is preserved only by the
**structure-tensor-preserving** sub-class of GL³ actions: the diagonal
`(P, P, P⁻ᵀ)`-shaped triples for `P ∈ GL n F`.  This sub-class
corresponds to basis changes of the underlying algebra; under it, the
new structure tensor is the structure tensor of the same algebra in a
different basis, hence remains associative.

For generic `(g.1, g.2, g.3) ∈ GL × GL × GL`, the associativity
identity is **not** preserved.  Counterexample: pick a non-associative
T and find `g` such that `g • T` is associative; reverse `g` to send
an associative tensor to a non-associative one.

The substantive Phase 3 content for "GL³ → algebra-iso" reasoning
relies on the **Manin tensor-stabilizer theorem**, which characterises
the GL³-stabilizer of a structure tensor as a specific algebraic
subgroup.  This is genuinely research-scope (~600 LOC, multi-month);
see `AlgEquivFromGL3.lean`'s `GL3InducesAlgEquivOnPathSubspace` for
the bundled research-scope `Prop` capturing the deep content.

## Public surface

* `IsAssociativeTensor T` (`Prop`-valued predicate over a
  `CommSemiring F`).
* `encoder_isAssociativeTensor_full_path`: the Grochow–Qiao encoder
  satisfies the predicate on graphs where every slot is path-algebra
  (e.g., the complete directed graph).

## Status

Lands the **associativity-tensor predicate** + the **encoder-is-
associative-on-full-adjacency theorem**, both unconditional.

The earlier `IsAssociativeTensorPreservedByGL3` Prop and its identity-
case witness have been **removed** as mathematically incorrect for
arbitrary GL³.  The correct preservation content (under the Manin
stabilizer subgroup) is part of the research-scope bundle in
`AlgEquivFromGL3.lean`.

## Naming

Identifiers describe content (associativity tensor, encoder is
associative on full adjacency), not workstream provenance.
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
-- Sub-task A.2.3 — The Grochow–Qiao encoder is associative on
-- full-adjacency graphs.
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
quadruples and zero on mixed quadruples (Sub-task A.1.3).  The
"path-only" version (the structurally meaningful form) is delivered by
`pathOnlyStructureTensor_isAssociative` in `PathOnlyTensor.lean`. -/
theorem encoder_isAssociativeTensor_full_path
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (h_full : ∀ i : Fin (dimGQ m), isPathAlgebraSlot m adj i = true) :
    IsAssociativeTensor (grochowQiaoEncode m adj) := by
  intro i j k l
  exact encoder_assoc_path m adj i j k l (h_full i) (h_full j)
                            (h_full k) (h_full l)

end GrochowQiao
end Orbcrypt
