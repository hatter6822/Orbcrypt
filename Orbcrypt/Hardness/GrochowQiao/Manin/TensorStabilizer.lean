/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
Manin tensor-stabilizer theorem (R-TI Phase 3 / Sub-tasks A.5.3 + A.5.4).

Constructs an algebra homomorphism `A →ₐ[F] B` from a basis-change
relation between the structure tensors of `A` and `B`, then upgrades to
an algebra isomorphism `A ≃ₐ[F] B` via the inverse matrix relation.

This is the technical core of Approach A: the (P, P, P⁻ᵀ)-form GL³
tensor isomorphism between two algebra structure tensors forces an
algebra hom, hence an algebra isomorphism (under invertibility).

See `docs/planning/AUDIT_2026-04-28_PHASE_3_PROP_DISCHARGE_PLAN.md`
§ "A.5.3 — Tensor stabilizer theorem" + "A.5.4 — Upgrade to AlgEquiv".
-/

import Orbcrypt.Hardness.GrochowQiao.Manin.BasisChange
import Mathlib.Algebra.Module.BigOperators
import Mathlib.Algebra.Algebra.Hom

/-!
# Manin tensor-stabilizer theorem (Sub-tasks A.5.3 + A.5.4)

## Mathematical content

For two algebras `A`, `B` over a field `F` with bases
`b_A : Basis I F A` and `b_B : Basis I F B`, and an invertible matrix
`P : Matrix I I F` (with two-sided inverse `P_inv`) such that the
structure tensors are `(P, P, P⁻ᵀ)`-related:
```
T_A(i, j, k) = ∑_{p, q, r} P(i, p) · P(j, q) · P_inv(r, k) · T_B(p, q, r)
```
together with a **unit compatibility** condition relating
`b_A.repr 1` and `b_B.repr 1` via `P`, the linear map
```
φ : A →ₗ[F] B,   φ(b_A i) := ∑_p P(i, p) • b_B p
```
is multiplicative and unit-preserving, hence an algebra hom.

If furthermore `P` is invertible (which is automatic from the
`IsBasisChangeRelated` predicate), the symmetric construction yields
an inverse, so `φ` upgrades to an `AlgEquiv`.

## Public surface

* `Manin.algHomOfTensorIso` — the algebra hom constructor from a
  `IsBasisChangeRelated` hypothesis + unit compatibility.
* `Manin.algEquivOfTensorIso` — the algebra equiv upgrade.

## Status

A.5.3 + A.5.4 land unconditionally. The constructions are total
(noncomputable) and the multiplicativity / unit-preservation are
proven by direct calculation using `structureTensor_recovers_mul`
+ the basis-change identity.

## Naming

`Manin.algHomOfTensorIso` and `Manin.algEquivOfTensorIso` describe
content (algebra hom / equiv from a tensor isomorphism), not
provenance. The `Manin` namespace signals reusability — these
constructions could be upstreamed to Mathlib as
`Algebra.algHomOfStructureTensorIso` etc. when the (P, P, P⁻ᵀ)-form
Manin theorem is upstreamed.
-/

namespace Orbcrypt
namespace GrochowQiao
namespace Manin

open Orbcrypt
open Module
open scoped BigOperators

universe u v w

variable {I : Type u} {F : Type v} {A : Type w} {B : Type w}
variable [Field F]
variable [Fintype I] [DecidableEq I]

set_option linter.unusedSectionVars false

-- ============================================================================
-- Sub-task A.5.3 — Algebra hom from tensor iso.
-- ============================================================================

variable [Ring A] [Ring B] [Algebra F A] [Algebra F B]

/-- **Unit-compatibility predicate.**

Asserts that the basis-coefficient representations of `1_A` and `1_B`
are related by `P`:
```
∀ k, b_B.repr 1 k = ∑ v, b_A.repr 1 v * P v k
```

This is the second hypothesis (alongside `IsBasisChangeRelated`)
needed for `Manin.algHomOfTensorIso` to deliver a unit-preserving
algebra hom. -/
def IsUnitCompatible
    (b_A : Basis I F A) (b_B : Basis I F B)
    (P : Matrix I I F) : Prop :=
  ∀ k : I, (b_B.repr 1) k = ∑ v, (b_A.repr 1) v * P v k

/-- **Sub-task A.5.3.1 — Definition of φ via `Basis.constr`.**

The linear map `φ : A →ₗ[F] B` defined on the basis `b_A` by
```
φ(b_A i) := ∑ p, P(i, p) • b_B p
```
extended linearly by `Basis.constr`.

Used internally by `algHomOfTensorIso`; the public surface is the
algebra-hom upgrade. -/
noncomputable def linearMapOfBasisChange
    (b_A : Basis I F A) (b_B : Basis I F B) (P : Matrix I I F) :
    A →ₗ[F] B :=
  b_A.constr F (fun i => ∑ p, P i p • b_B p)

/-- **Apply lemma:** `linearMapOfBasisChange` evaluated at a basis
element equals the prescribed image. -/
@[simp] theorem linearMapOfBasisChange_basis
    (b_A : Basis I F A) (b_B : Basis I F B) (P : Matrix I I F) (i : I) :
    linearMapOfBasisChange b_A b_B P (b_A i) = ∑ p, P i p • b_B p := by
  unfold linearMapOfBasisChange
  exact Basis.constr_basis b_A F _ i

-- ============================================================================
-- Sub-task A.5.3.2 — Multiplicativity on basis pairs.
-- ============================================================================

/-- **Sub-task A.5.3.2 — Coefficient-matching identity (key lemma).**

The basis-change identity, multiplied by `P(l, k)` and summed over `l`,
yields:
```
∑_l T_A(i, j, l) · P(l, k) = ∑_{p, q} P(i, p) · P(j, q) · T_B(p, q, k)
```

This is the **coefficient-matching identity** that drives the
multiplicativity of `φ`. -/
theorem coefficient_match_of_basisChange
    {T_A T_B : I → I → I → F} {P P_inv : Matrix I I F}
    (h_rel : IsBasisChangeRelated T_A T_B P P_inv)
    (i j k : I) :
    (∑ l, T_A i j l * P l k) =
      ∑ p, ∑ q, P i p * P j q * T_B p q k := by
  -- Step 1: substitute T_A using h_rel.action.
  -- After substitution and pushing P(l, k) inside,
  --   LHS = ∑ l p q r, P i p * P j q * P_inv r l * T_B p q r * P l k
  have h_subst : (∑ l, T_A i j l * P l k) =
      ∑ l, ∑ p, ∑ q, ∑ r,
        P i p * P j q * P_inv r l * T_B p q r * P l k := by
    apply Finset.sum_congr rfl
    intro l _
    rw [h_rel.action i j l]
    -- ∑ p q r, ... * P l k → expand multiplications.
    rw [Finset.sum_mul]
    apply Finset.sum_congr rfl
    intro p _
    rw [Finset.sum_mul]
    apply Finset.sum_congr rfl
    intro q _
    rw [Finset.sum_mul]
  rw [h_subst]
  -- Step 2: rearrange the four-fold sum.
  -- ∑ l p q r, X(p, q, r, l) → ∑ p q r l, X.
  rw [Finset.sum_comm]
  -- ∑ p, ∑ l, ∑ q, ∑ r, X
  apply Finset.sum_congr rfl
  intro p _
  -- ∑ l, ∑ q, ∑ r, X → ∑ q, ∑ l, ∑ r, X
  rw [Finset.sum_comm]
  apply Finset.sum_congr rfl
  intro q _
  -- ∑ l, ∑ r, X → ∑ r, ∑ l, X
  rw [Finset.sum_comm]
  -- Goal: ∑ r, ∑ l, P i p * P j q * P_inv r l * T_B p q r * P l k
  --       = P i p * P j q * T_B p q k.
  -- Step 3: factor (P_inv r l * P l k) inside the ∑_l sum.
  have h_factor : (∑ r : I, ∑ l : I,
      P i p * P j q * P_inv r l * T_B p q r * P l k) =
      ∑ r : I, P i p * P j q * T_B p q r *
                (∑ l : I, P_inv r l * P l k) := by
    apply Finset.sum_congr rfl
    intro r _
    rw [Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro l _
    ring
  rw [h_factor]
  -- Step 4: ∑ l, P_inv r l * P l k = (P_inv * P) r k = δ r k (= 1 if r = k).
  have h_inner : ∀ r : I, (∑ l, P_inv r l * P l k) = if r = k then 1 else 0 := by
    intro r
    have h_mul : (P_inv * P) r k = ∑ l, P_inv r l * P l k := by
      simp [Matrix.mul_apply]
    rw [← h_mul, h_rel.inv_left]
    by_cases h : r = k
    · subst h; rfl
    · simp [h]
  -- Step 5: collapse the diagonal.
  have h_collapse : (∑ r : I, P i p * P j q * T_B p q r *
                            (∑ l, P_inv r l * P l k)) =
      P i p * P j q * T_B p q k := by
    rw [show (∑ r : I, P i p * P j q * T_B p q r *
                       (∑ l, P_inv r l * P l k)) =
            ∑ r : I, P i p * P j q * T_B p q r * (if r = k then 1 else 0) by
      apply Finset.sum_congr rfl
      intro r _
      rw [h_inner r]]
    rw [show (∑ r : I, P i p * P j q * T_B p q r * (if r = k then (1 : F) else 0)) =
            ∑ r : I, (if r = k then P i p * P j q * T_B p q r else 0) by
      apply Finset.sum_congr rfl
      intro r _
      split_ifs <;> ring]
    rw [Finset.sum_ite_eq' Finset.univ k
          (fun r => P i p * P j q * T_B p q r)]
    simp
  exact h_collapse

-- ============================================================================
-- Sub-task A.5.3.2 — Multiplicativity on basis pairs.
-- ============================================================================

/-- **Multiplicativity on basis pairs.**

For any two basis elements `b_A i, b_A j`, the linear map
`linearMapOfBasisChange b_A b_B P` preserves their product:
```
linearMapOfBasisChange (b_A i * b_A j) =
  linearMapOfBasisChange (b_A i) * linearMapOfBasisChange (b_A j)
```

Proof: expand both sides using `structureTensor_recovers_mul` (on `A`
and `B`) and the basis-action of `linearMapOfBasisChange`. After
matching coefficients on `b_B k`, the equality follows from
`coefficient_match_of_basisChange`. -/
theorem linearMapOfBasisChange_mul_basis
    (b_A : Basis I F A) (b_B : Basis I F B)
    (P P_inv : Matrix I I F)
    (h_rel : IsBasisChangeRelated (structureTensor b_A) (structureTensor b_B)
              P P_inv)
    (i j : I) :
    linearMapOfBasisChange b_A b_B P (b_A i * b_A j) =
      linearMapOfBasisChange b_A b_B P (b_A i) *
        linearMapOfBasisChange b_A b_B P (b_A j) := by
  -- Compute LHS as a sum over k of the appropriate coefficient on b_B k.
  have h_lhs : linearMapOfBasisChange b_A b_B P (b_A i * b_A j) =
      ∑ k, (∑ l, structureTensor b_A i j l * P l k) • b_B k := by
    rw [structureTensor_recovers_mul b_A i j]
    rw [map_sum]
    -- ∑ l, φ (T_A i j l • b_A l) = ∑ l, T_A i j l • φ (b_A l)
    -- = ∑ l, T_A i j l • ∑ p, P l p • b_B p
    -- = ∑ l ∑ k, (T_A i j l * P l k) • b_B k
    -- = ∑ k ∑ l, (T_A i j l * P l k) • b_B k
    -- = ∑ k, (∑ l, T_A i j l * P l k) • b_B k
    have h_step : (∑ l, linearMapOfBasisChange b_A b_B P
                          (structureTensor b_A i j l • b_A l)) =
        ∑ l, ∑ k, (structureTensor b_A i j l * P l k) • b_B k := by
      apply Finset.sum_congr rfl
      intro l _
      rw [map_smul, linearMapOfBasisChange_basis, Finset.smul_sum]
      apply Finset.sum_congr rfl
      intro k _
      rw [smul_smul]
    rw [h_step, Finset.sum_comm]
    apply Finset.sum_congr rfl
    intro k _
    rw [← Finset.sum_smul]
  -- Compute RHS as a sum over k of the appropriate coefficient on b_B k.
  have h_rhs : linearMapOfBasisChange b_A b_B P (b_A i) *
                  linearMapOfBasisChange b_A b_B P (b_A j) =
      ∑ k, (∑ p, ∑ q, P i p * P j q * structureTensor b_B p q k) • b_B k := by
    rw [linearMapOfBasisChange_basis, linearMapOfBasisChange_basis]
    -- (∑ p, P i p • b_B p) * (∑ q, P j q • b_B q)
    -- = ∑ p ∑ q, (P i p • b_B p) * (P j q • b_B q)
    -- = ∑ p ∑ q, (P i p * P j q) • (b_B p * b_B q)
    -- = ∑ p ∑ q ∑ k, (P i p * P j q * T_B p q k) • b_B k
    -- Reorder to ∑ k ∑ p ∑ q, ... • b_B k.
    rw [Finset.sum_mul]
    -- ∑ p, (P i p • b_B p) * (∑ q, P j q • b_B q)
    have h_step : ∀ p,
        (P i p • b_B p) * (∑ q, P j q • b_B q) =
        ∑ k, (∑ q, P i p * P j q * structureTensor b_B p q k) • b_B k := by
      intro p
      rw [Finset.mul_sum]
      have : (∑ q, (P i p • b_B p) * (P j q • b_B q)) =
              ∑ q, ∑ k, (P i p * P j q * structureTensor b_B p q k) • b_B k := by
        apply Finset.sum_congr rfl
        intro q _
        rw [smul_mul_smul_comm, structureTensor_recovers_mul b_B p q,
            Finset.smul_sum]
        apply Finset.sum_congr rfl
        intro k _
        rw [smul_smul]
      rw [this, Finset.sum_comm]
      apply Finset.sum_congr rfl
      intro k _
      rw [← Finset.sum_smul]
    rw [show (∑ p, (P i p • b_B p) * (∑ q, P j q • b_B q)) =
        ∑ p, ∑ k, (∑ q, P i p * P j q * structureTensor b_B p q k) • b_B k from by
      apply Finset.sum_congr rfl
      intro p _
      exact h_step p]
    rw [Finset.sum_comm]
    apply Finset.sum_congr rfl
    intro k _
    rw [← Finset.sum_smul]
  rw [h_lhs, h_rhs]
  -- Both sides are ∑ k, [coefficient] • b_B k. Match coefficients.
  apply Finset.sum_congr rfl
  intro k _
  congr 1
  exact coefficient_match_of_basisChange h_rel i j k

-- ============================================================================
-- Sub-task A.5.3.2 — Multiplicativity on all elements (extension).
-- ============================================================================

/-- **Helper:** `linearMapOfBasisChange` applied to any element of `A`
expands as a sum over the basis, with coefficients given by the
`b_A`-representation. -/
private theorem linearMapOfBasisChange_apply_eq_sum
    (b_A : Basis I F A) (b_B : Basis I F B) (P : Matrix I I F) (x : A) :
    linearMapOfBasisChange b_A b_B P x =
      ∑ i, (b_A.repr x) i • linearMapOfBasisChange b_A b_B P (b_A i) := by
  conv_lhs => rw [← Basis.sum_repr b_A x]
  rw [map_sum]
  apply Finset.sum_congr rfl
  intro i _
  rw [map_smul]

/-- **Multiplicativity on all elements.**

The linear map `linearMapOfBasisChange b_A b_B P` is multiplicative on
the entire algebra: `φ (x * y) = φ x * φ y` for all `x, y : A`.

Proof: expand `x` and `y` in the basis `b_A` via `Basis.sum_repr`,
distribute `*` and `φ` over the resulting double sum, and apply
`linearMapOfBasisChange_mul_basis` term-wise. -/
theorem linearMapOfBasisChange_mul
    (b_A : Basis I F A) (b_B : Basis I F B)
    (P P_inv : Matrix I I F)
    (h_rel : IsBasisChangeRelated (structureTensor b_A) (structureTensor b_B)
              P P_inv)
    (x y : A) :
    linearMapOfBasisChange b_A b_B P (x * y) =
      linearMapOfBasisChange b_A b_B P x *
        linearMapOfBasisChange b_A b_B P y := by
  set φ := linearMapOfBasisChange b_A b_B P with hφ
  -- We prove both sides equal the canonical double-sum form
  --   ∑ i j, (c_x i * c_y j) • (φ (b_A i) * φ (b_A j))
  -- where c_x = b_A.repr x and c_y = b_A.repr y.
  have h_lhs : φ (x * y) =
      ∑ i, ∑ j, ((b_A.repr x) i * (b_A.repr y) j) •
                  (φ (b_A i) * φ (b_A j)) := by
    -- x * y = (∑ i, c_x i • b_A i) * (∑ j, c_y j • b_A j)
    --       = ∑ i j, (c_x i * c_y j) • (b_A i * b_A j).
    have h_xy : x * y =
        ∑ i, ∑ j, ((b_A.repr x) i * (b_A.repr y) j) • (b_A i * b_A j) := by
      conv_lhs => rw [← Basis.sum_repr b_A x, ← Basis.sum_repr b_A y]
      rw [Finset.sum_mul]
      apply Finset.sum_congr rfl
      intro i _
      rw [Finset.mul_sum]
      apply Finset.sum_congr rfl
      intro j _
      rw [smul_mul_smul_comm]
    rw [h_xy, map_sum]
    apply Finset.sum_congr rfl
    intro i _
    rw [map_sum]
    apply Finset.sum_congr rfl
    intro j _
    rw [map_smul, linearMapOfBasisChange_mul_basis b_A b_B P P_inv h_rel]
  have h_rhs : φ x * φ y =
      ∑ i, ∑ j, ((b_A.repr x) i * (b_A.repr y) j) •
                  (φ (b_A i) * φ (b_A j)) := by
    rw [linearMapOfBasisChange_apply_eq_sum b_A b_B P x,
        linearMapOfBasisChange_apply_eq_sum b_A b_B P y]
    rw [Finset.sum_mul]
    apply Finset.sum_congr rfl
    intro i _
    rw [Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro j _
    rw [smul_mul_smul_comm]
  rw [h_lhs, h_rhs]

-- ============================================================================
-- Sub-task A.5.3.3 — Unit preservation.
-- ============================================================================

/-- **Sub-task A.5.3.3 — Unit preservation.**

Under the unit-compatibility hypothesis, the linear map
`linearMapOfBasisChange b_A b_B P` sends `1_A` to `1_B`.

Proof: expand `1_A = ∑_v c_A(v) • b_A v` via `Basis.sum_repr` (with
`c_A := b_A.repr 1`); apply `linearMapOfBasisChange` to get
`∑_v c_A(v) • (∑_k P(v, k) • b_B k) = ∑_k (∑_v c_A(v) · P(v, k)) • b_B k`;
apply `h_unit` to substitute `c_B(k) := ∑_v c_A(v) · P(v, k)`; conclude
via `Basis.sum_repr` for `b_B` evaluated at `1_B`. -/
theorem linearMapOfBasisChange_one
    (b_A : Basis I F A) (b_B : Basis I F B) (P : Matrix I I F)
    (h_unit : IsUnitCompatible b_A b_B P) :
    linearMapOfBasisChange b_A b_B P 1 = 1 := by
  set φ := linearMapOfBasisChange b_A b_B P with hφ
  -- Expand 1_A = ∑_v c_A(v) • b_A v.
  have h_one_A : (1 : A) = ∑ v, (b_A.repr 1) v • b_A v := (Basis.sum_repr b_A 1).symm
  -- Compute LHS to ∑ k, c_B(k) • b_B k.
  have h_lhs : φ 1 = ∑ k, (b_B.repr 1) k • b_B k := by
    rw [h_one_A, map_sum]
    -- φ (∑ v, c_A v • b_A v) = ∑ v, φ (c_A v • b_A v) = ∑ v, c_A v • φ(b_A v)
    -- = ∑ v, c_A v • ∑ k, P v k • b_B k
    -- = ∑ v ∑ k, (c_A v * P v k) • b_B k
    -- = ∑ k, (∑ v, c_A v * P v k) • b_B k
    -- = ∑ k, c_B k • b_B k (by h_unit).
    have h_step1 : (∑ v, φ ((b_A.repr 1) v • b_A v)) =
        ∑ v, ∑ k, ((b_A.repr 1) v * P v k) • b_B k := by
      apply Finset.sum_congr rfl
      intro v _
      rw [map_smul, linearMapOfBasisChange_basis, Finset.smul_sum]
      apply Finset.sum_congr rfl
      intro k _
      rw [smul_smul]
    rw [h_step1, Finset.sum_comm]
    apply Finset.sum_congr rfl
    intro k _
    rw [← Finset.sum_smul, ← h_unit k]
  rw [h_lhs]
  exact Basis.sum_repr b_B 1

-- ============================================================================
-- Sub-task A.5.3.4 — Package as AlgHom via AlgHom.ofLinearMap.
-- ============================================================================

/-- **Sub-task A.5.3 — Algebra hom from tensor iso.**

From a basis-change relation `IsBasisChangeRelated T_A T_B P P_inv`
between the structure tensors of `A` and `B`, plus a unit-compatibility
hypothesis, produce an algebra hom `A →ₐ[F] B` whose action on the
basis `b_A` is `b_A i ↦ ∑ p, P(i, p) • b_B p`.

This is the **Manin tensor-stabilizer theorem** in `(P, P, P⁻ᵀ)`-form:
the GL³ tensor isomorphism between two algebra structure tensors,
together with unit compatibility, forces an algebra hom. -/
noncomputable def algHomOfTensorIso
    (b_A : Basis I F A) (b_B : Basis I F B)
    (P P_inv : Matrix I I F)
    (h_rel : IsBasisChangeRelated (structureTensor b_A) (structureTensor b_B)
              P P_inv)
    (h_unit : IsUnitCompatible b_A b_B P) :
    A →ₐ[F] B :=
  AlgHom.ofLinearMap (linearMapOfBasisChange b_A b_B P)
    (linearMapOfBasisChange_one b_A b_B P h_unit)
    (linearMapOfBasisChange_mul b_A b_B P P_inv h_rel)

/-- **Apply lemma:** `algHomOfTensorIso` on a basis element. -/
@[simp] theorem algHomOfTensorIso_basis
    (b_A : Basis I F A) (b_B : Basis I F B)
    (P P_inv : Matrix I I F)
    (h_rel : IsBasisChangeRelated (structureTensor b_A) (structureTensor b_B)
              P P_inv)
    (h_unit : IsUnitCompatible b_A b_B P) (i : I) :
    algHomOfTensorIso b_A b_B P P_inv h_rel h_unit (b_A i) =
      ∑ p, P i p • b_B p := by
  unfold algHomOfTensorIso
  exact linearMapOfBasisChange_basis b_A b_B P i

-- ============================================================================
-- Sub-task A.5.4 — Upgrade to AlgEquiv via inverse linear map.
-- ============================================================================

/-- **Inverse identity on basis elements.**

The composition `linearMapOfBasisChange b_B b_A P_inv ∘
linearMapOfBasisChange b_A b_B P` evaluated at `b_A i` equals `b_A i`,
because `(P * P_inv)(i, q) = δ(i, q)` collapses the double sum. -/
private theorem linearMapOfBasisChange_inv_basis
    (b_A : Basis I F A) (b_B : Basis I F B)
    (P P_inv : Matrix I I F)
    (h_inv_right : P * P_inv = 1) (i : I) :
    (linearMapOfBasisChange b_B b_A P_inv)
        (linearMapOfBasisChange b_A b_B P (b_A i)) = b_A i := by
  rw [linearMapOfBasisChange_basis, map_sum]
  -- ∑ p, (linearMapOfBasisChange b_B b_A P_inv) (P i p • b_B p)
  -- = ∑ p, P i p • (∑ q, P_inv p q • b_A q)
  -- = ∑ p ∑ q, (P i p * P_inv p q) • b_A q
  -- = ∑ q, (∑ p, P i p * P_inv p q) • b_A q
  -- = ∑ q, (P * P_inv) i q • b_A q
  -- = ∑ q, (1 : Matrix) i q • b_A q
  -- = b_A i.
  have h_step1 : (∑ p, (linearMapOfBasisChange b_B b_A P_inv) (P i p • b_B p)) =
      ∑ p, ∑ q, (P i p * P_inv p q) • b_A q := by
    apply Finset.sum_congr rfl
    intro p _
    rw [map_smul, linearMapOfBasisChange_basis, Finset.smul_sum]
    apply Finset.sum_congr rfl
    intro q _
    rw [smul_smul]
  rw [h_step1, Finset.sum_comm]
  -- ∑ q, ∑ p, (P i p * P_inv p q) • b_A q
  have h_step2 : (∑ q : I, ∑ p : I, (P i p * P_inv p q) • b_A q) =
      ∑ q : I, (∑ p, P i p * P_inv p q) • b_A q := by
    apply Finset.sum_congr rfl
    intro q _
    rw [← Finset.sum_smul]
  rw [h_step2]
  -- ∑ q, (P * P_inv) i q • b_A q = ∑ q, (1 : Matrix) i q • b_A q = b_A i.
  have h_inner : ∀ q : I, (∑ p, P i p * P_inv p q) =
      if i = q then (1 : F) else 0 := by
    intro q
    have h_mul : (P * P_inv) i q = ∑ p, P i p * P_inv p q := by
      simp [Matrix.mul_apply]
    rw [← h_mul, h_inv_right]
    by_cases h : i = q
    · subst h; rfl
    · simp [h]
  have h_collapse : (∑ q : I, (∑ p, P i p * P_inv p q) • b_A q) =
      ∑ q : I, (if i = q then (1 : F) else 0) • b_A q := by
    apply Finset.sum_congr rfl
    intro q _
    rw [h_inner q]
  rw [h_collapse]
  -- ∑ q, (if i = q then 1 else 0) • b_A q = b_A i.
  rw [show (∑ q : I, (if i = q then (1 : F) else 0) • b_A q) =
          ∑ q : I, (if i = q then b_A q else 0) from by
    apply Finset.sum_congr rfl
    intro q _
    split_ifs <;> simp]
  rw [Finset.sum_ite_eq Finset.univ i (fun q => b_A q)]
  simp

/-- **Inverse identity (left).**

The composition `linearMapOfBasisChange b_B b_A P_inv ∘
linearMapOfBasisChange b_A b_B P` is the identity on `A`. -/
theorem linearMapOfBasisChange_left_inv
    (b_A : Basis I F A) (b_B : Basis I F B)
    (P P_inv : Matrix I I F)
    (h_inv_right : P * P_inv = 1) :
    (linearMapOfBasisChange b_B b_A P_inv).comp
        (linearMapOfBasisChange b_A b_B P) = LinearMap.id := by
  apply Basis.ext b_A
  intro i
  rw [LinearMap.comp_apply, LinearMap.id_apply]
  exact linearMapOfBasisChange_inv_basis b_A b_B P P_inv h_inv_right i

/-- **Inverse identity (right).**

The composition `linearMapOfBasisChange b_A b_B P ∘
linearMapOfBasisChange b_B b_A P_inv` is the identity on `B`. -/
theorem linearMapOfBasisChange_right_inv
    (b_A : Basis I F A) (b_B : Basis I F B)
    (P P_inv : Matrix I I F)
    (h_inv_left : P_inv * P = 1) :
    (linearMapOfBasisChange b_A b_B P).comp
        (linearMapOfBasisChange b_B b_A P_inv) = LinearMap.id := by
  apply Basis.ext b_B
  intro i
  rw [LinearMap.comp_apply, LinearMap.id_apply]
  exact linearMapOfBasisChange_inv_basis b_B b_A P_inv P h_inv_left i

/-- **Linear equiv from basis-change relation.**

The inverse-pair structure of `IsBasisChangeRelated` gives a linear
equivalence between `A` and `B`. -/
noncomputable def linearEquivOfBasisChange
    (b_A : Basis I F A) (b_B : Basis I F B)
    (P P_inv : Matrix I I F)
    (h_rel : IsBasisChangeRelated (structureTensor b_A) (structureTensor b_B)
              P P_inv) :
    A ≃ₗ[F] B :=
  LinearEquiv.ofLinear (linearMapOfBasisChange b_A b_B P)
    (linearMapOfBasisChange b_B b_A P_inv)
    (linearMapOfBasisChange_right_inv b_A b_B P P_inv h_rel.inv_left)
    (linearMapOfBasisChange_left_inv b_A b_B P P_inv h_rel.inv_right)

/-- **Sub-task A.5.4 — Algebra equiv from tensor iso.**

From a basis-change relation `IsBasisChangeRelated T_A T_B P P_inv`
plus a unit-compatibility hypothesis, produce an algebra equivalence
`A ≃ₐ[F] B`.

Built via `AlgEquiv.ofLinearEquiv` on top of `linearEquivOfBasisChange`,
with `linearMapOfBasisChange_one` discharging unit preservation and
`linearMapOfBasisChange_mul` discharging multiplicativity. -/
noncomputable def algEquivOfTensorIso
    (b_A : Basis I F A) (b_B : Basis I F B)
    (P P_inv : Matrix I I F)
    (h_rel : IsBasisChangeRelated (structureTensor b_A) (structureTensor b_B)
              P P_inv)
    (h_unit : IsUnitCompatible b_A b_B P) :
    A ≃ₐ[F] B :=
  AlgEquiv.ofLinearEquiv (linearEquivOfBasisChange b_A b_B P P_inv h_rel)
    (linearMapOfBasisChange_one b_A b_B P h_unit)
    (linearMapOfBasisChange_mul b_A b_B P P_inv h_rel)

/-- **Apply lemma:** `algEquivOfTensorIso` on a basis element. -/
@[simp] theorem algEquivOfTensorIso_basis
    (b_A : Basis I F A) (b_B : Basis I F B)
    (P P_inv : Matrix I I F)
    (h_rel : IsBasisChangeRelated (structureTensor b_A) (structureTensor b_B)
              P P_inv)
    (h_unit : IsUnitCompatible b_A b_B P) (i : I) :
    algEquivOfTensorIso b_A b_B P P_inv h_rel h_unit (b_A i) =
      ∑ p, P i p • b_B p := by
  unfold algEquivOfTensorIso
  show (linearEquivOfBasisChange b_A b_B P P_inv h_rel) (b_A i) = _
  unfold linearEquivOfBasisChange
  exact linearMapOfBasisChange_basis b_A b_B P i

end Manin
end GrochowQiao
end Orbcrypt
