/-
Path-only Subalgebra of `pathAlgebraQuotient m` (R-TI Phase 3 /
Sub-tasks A.5.5 + A.6.1 + A.6.2).

For each adjacency `adj : Fin m → Fin m → Bool`, builds the
**path-only Subalgebra** of `pathAlgebraQuotient m` whose carrier is
`presentArrowsSubspace m adj` (vectors that vanish outside present
arrows under `adj`), proves multiplicative closure, exhibits a basis
indexed by `Fin (pathSlotIndices m adj).card`, and proves the bridge
between Manin's abstract `structureTensor` (on this basis) and the
encoder's `pathOnlyStructureTensor m adj`.

This module is the missing connection that lets the **Manin tensor-
stabilizer theorem** (`Manin/TensorStabilizer.lean`, Sub-task A.5.3 +
A.5.4) drive the discharge of `GL3InducesAlgEquivOnPathSubspace`
from the **partition-cardinality preservation** Prop instead of the
bundled `GrochowQiaoRigidity`.

See `docs/planning/AUDIT_2026-04-28_PHASE_3_PROP_DISCHARGE_PLAN.md`
§ "A.5.5 — Specialization to pathAlgebraQuotient" + "A.6.1 — Bridge"
+ "A.6.2 — Lift AlgEquiv".
-/

import Orbcrypt.Hardness.GrochowQiao.AlgebraWrapper
import Orbcrypt.Hardness.GrochowQiao.PathBlockSubspace
import Orbcrypt.Hardness.GrochowQiao.PathOnlyTensor
import Orbcrypt.Hardness.GrochowQiao.Manin.StructureTensor
import Orbcrypt.Hardness.GrochowQiao.Manin.BasisChange
import Orbcrypt.Hardness.GrochowQiao.Manin.TensorStabilizer
import Orbcrypt.Hardness.GrochowQiao.EncoderSlabEval

/-!
# Path-only Subalgebra (Sub-tasks A.5.5 + A.6.1 + A.6.2)

## Mathematical content

For an adjacency `adj : Fin m → Fin m → Bool`, the **path-only
subalgebra** of `pathAlgebraQuotient m` (the radical-2 truncated path
algebra `ℚ[Q_G] / J²`) is the set of basis-supported vectors
`f : QuiverArrow m → ℚ` that vanish outside `presentArrows m adj`.
Equivalently, the linear span of the vertex idempotents
`vertexIdempotent v` (for all `v`) and the arrow basis elements
`arrowElement u v` (for `u v` with `adj u v = true`).

The path-only subalgebra IS closed under the convolution
multiplication: products of basis elements either yield another
present-arrow basis element or zero (`J² = 0`).  Combined with the
unit `1 = ∑_v vertexIdempotent v` lying in the subalgebra, this
gives a `Subalgebra ℚ (pathAlgebraQuotient m)` structure.

The path-only subalgebra has dimension `(pathSlotIndices m adj).card`
(vertices + present arrows).  Its basis indexed by `Fin
(pathSlotIndices m adj).card` (via the standard `Finset.equivFin`
enumeration) gives a `Basis (Fin _) ℚ ↥(pathOnlyAlgebraSubalgebra m
adj)` whose Manin structure tensor exactly matches
`pathOnlyStructureTensor m adj`.

## Public surface

* `presentArrowsSubspace_mul_mem` — multiplicative closure of
  `presentArrowsSubspace m adj` under the convolution product.
* `pathOnlyAlgebraSubalgebra m adj` — the path-only Subalgebra built
  via `Submodule.toSubalgebra`.
* `pathOnlyAlgebraBasis m adj` — basis of the path-only Subalgebra
  indexed by `Fin (pathSlotIndices m adj).card`.
* `pathOnlyAlgebraBasis_structureTensor_eq_pathOnlyStructureTensor`
  — bridge theorem connecting Manin's abstract structure tensor to
  the encoder's `pathOnlyStructureTensor m adj`.

## Status

Sub-tasks A.5.5 + A.6.1 + A.6.2 land unconditionally.  The path-only
subalgebra is the cleanest algebra-level reformulation of the
encoder's path-algebra slots; once this bridge lands, Manin's
tensor-stabilizer theorem becomes directly applicable to
`pathOnlyStructureTensor m adj`.

## Naming

Identifiers describe content (path-only Subalgebra, path-only basis,
Manin/encoder bridge), not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt
open Module
open scoped BigOperators

set_option linter.unusedSectionVars false

-- ============================================================================
-- A.5.5.1 — Helper: pathMul preserves `presentArrows` membership.
-- ============================================================================

/-- **Helper:** if both inputs to `pathMul` lie in `presentArrows m
adj` and the result is `some c`, then `c` also lies in `presentArrows
m adj`.

This is the structural fact behind multiplicative closure: the
convolution product of two present-arrow vectors stays inside
`presentArrows m adj`. -/
theorem pathMul_some_mem_presentArrows
    (m : ℕ) (adj : Fin m → Fin m → Bool) {a b c : QuiverArrow m}
    (ha : a ∈ presentArrows m adj) (hb : b ∈ presentArrows m adj)
    (h_eq : pathMul m a b = some c) :
    c ∈ presentArrows m adj := by
  cases a with
  | id u =>
    cases b with
    | id v =>
      -- `.id u, .id v` → some (.id u) iff u = v.
      simp only [pathMul] at h_eq
      split_ifs at h_eq with h
      · -- h_eq : some (.id u) = some c, so c = .id u.
        rw [Option.some.injEq] at h_eq
        rw [← h_eq]
        exact presentArrows_id_mem m adj u
    | edge v w =>
      -- `.id u, .edge v w` → some (.edge v w) iff u = v.
      simp only [pathMul] at h_eq
      split_ifs at h_eq with h
      · rw [Option.some.injEq] at h_eq
        rw [← h_eq]
        -- b = .edge v w ∈ presentArrows ⇒ adj v w = true ⇒ .edge v w ∈ presentArrows.
        exact hb
  | edge u v =>
    cases b with
    | id w =>
      -- `.edge u v, .id w` → some (.edge u v) iff v = w.
      simp only [pathMul] at h_eq
      split_ifs at h_eq with h
      · rw [Option.some.injEq] at h_eq
        rw [← h_eq]
        exact ha
    | edge u' w =>
      -- `.edge _ _, .edge _ _` → none always (J²=0); `h_eq : none = some c`
      -- is a contradiction.
      simp [pathMul] at h_eq

-- ============================================================================
-- A.5.5.2 — Multiplicative closure of `presentArrowsSubspace`.
-- ============================================================================

/-- **Multiplicative closure of `presentArrowsSubspace`.**

For any adjacency `adj`, the present-arrow subspace of
`pathAlgebraQuotient m` is closed under the convolution product:
if `f`, `g` both vanish outside `presentArrows m adj`, then so does
`f * g`.

**Proof.** For `c ∉ presentArrows m adj`, every term in the double
sum `(f * g)(c) = ∑_{a, b} f(a) · g(b) · [pathMul a b = some c]`
vanishes:
* If `pathMul a b ≠ some c`, the indicator is 0.
* If `pathMul a b = some c`, then by `pathMul_some_mem_presentArrows`,
  at least one of `a`, `b` must lie outside `presentArrows m adj`
  (otherwise `c` would be in `presentArrows`); hence `f(a) = 0` or
  `g(b) = 0`. -/
theorem presentArrowsSubspace_mul_mem
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    {f g : pathAlgebraQuotient m}
    (hf : f ∈ presentArrowsSubspace m adj)
    (hg : g ∈ presentArrowsSubspace m adj) :
    f * g ∈ presentArrowsSubspace m adj := by
  intro c hc
  show (f * g) c = 0
  rw [pathAlgebraMul_apply]
  -- (f * g) c = ∑ a b, f a * g b * [pathMul a b = some c]
  apply Finset.sum_eq_zero
  intro a _
  apply Finset.sum_eq_zero
  intro b _
  -- Case-split on whether `pathMul a b = some c`.
  by_cases h_eq : pathMul m a b = some c
  · -- Indicator = 1; need f a = 0 or g b = 0.
    rw [if_pos h_eq, mul_one]
    -- If both a, b ∈ presentArrows, then c ∈ presentArrows by helper —
    -- contradicting hc.
    by_cases ha : a ∈ presentArrows m adj
    · by_cases hb : b ∈ presentArrows m adj
      · exact absurd
          (pathMul_some_mem_presentArrows m adj ha hb h_eq) hc
      · rw [hg b hb, mul_zero]
    · rw [hf a ha, zero_mul]
  · -- Indicator = 0.
    rw [if_neg h_eq, mul_zero]

-- ============================================================================
-- A.5.5.3 — Unit membership: `1 ∈ presentArrowsSubspace`.
-- ============================================================================

/-- **Unit membership.**

The unit `1 : pathAlgebraQuotient m` is `pathAlgebraOne m =
∑_v vertexIdempotent m v` by definition.  Since each vertex
idempotent lies in `presentArrowsSubspace m adj` and the subspace
is closed under addition, so does `1`. -/
theorem one_mem_presentArrowsSubspace
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    (1 : pathAlgebraQuotient m) ∈ presentArrowsSubspace m adj := by
  -- Unfold `1 : pathAlgebraQuotient m` to `pathAlgebraOne m =
  -- ∑ v, vertexIdempotent m v`.
  show pathAlgebraOne m ∈ presentArrowsSubspace m adj
  unfold pathAlgebraOne
  apply Submodule.sum_mem
  intro v _
  exact vertexIdempotent_mem_presentArrowsSubspace m adj v

-- ============================================================================
-- A.5.5.4 — Path-only Subalgebra construction.
-- ============================================================================

/-- **Sub-task A.5.5 — Path-only Subalgebra.**

The subalgebra of `pathAlgebraQuotient m` whose carrier is
`presentArrowsSubspace m adj`.  Built by `Submodule.toSubalgebra`
with `one_mem_presentArrowsSubspace` and
`presentArrowsSubspace_mul_mem`. -/
noncomputable def pathOnlyAlgebraSubalgebra
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Subalgebra ℚ (pathAlgebraQuotient m) :=
  (presentArrowsSubspace m adj).toSubalgebra
    (one_mem_presentArrowsSubspace m adj)
    (fun _ _ hx hy => presentArrowsSubspace_mul_mem m adj hx hy)

/-- Membership characterization for `pathOnlyAlgebraSubalgebra`. -/
@[simp] theorem mem_pathOnlyAlgebraSubalgebra_iff
    (m : ℕ) (adj : Fin m → Fin m → Bool) (f : pathAlgebraQuotient m) :
    f ∈ pathOnlyAlgebraSubalgebra m adj ↔
      ∀ a, a ∉ presentArrows m adj → f a = 0 := Iff.rfl

-- ============================================================================
-- A.5.5.5 — LinearEquiv between subalgebra and `Fin (...).card → ℚ`.
-- ============================================================================

/-- **Helper:** convert a present-arrow `a : QuiverArrow m` to its
`Fin (pathSlotIndices m adj).card`-index via `slotOfArrow` +
`equivFin` enumeration. -/
private noncomputable def arrowToPathSlotIdx
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    {a : QuiverArrow m} (ha : a ∈ presentArrows m adj) :
    Fin (pathSlotIndices m adj).card :=
  (pathSlotIndices m adj).equivFin
    ⟨slotOfArrow m a,
      slotOfArrow_mem_pathSlotIndices_of_present m adj a ha⟩

/-- **Helper:** the round-trip `arrowToPathSlotIdx → equivFin.symm → slotEquiv
→ slotToArrow` recovers the original arrow. -/
private theorem slotToArrow_slotEquiv_arrowToPathSlotIdx
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    {a : QuiverArrow m} (ha : a ∈ presentArrows m adj) :
    slotToArrow m
        (slotEquiv m
          ((pathSlotIndices m adj).equivFin.symm
            (arrowToPathSlotIdx m adj ha)).val) = a := by
  unfold arrowToPathSlotIdx
  rw [Equiv.symm_apply_apply]
  -- Now goal: slotToArrow m (slotEquiv m (slotOfArrow m a)) = a.
  exact slotToArrow_slotEquiv_slotOfArrow m a

/-- **Path-only algebra ≃ Fin → ℚ (LinearEquiv).**

The path-only subalgebra is in linear bijection with
`Fin (pathSlotIndices m adj).card → ℚ`: a subalgebra element `f`
is determined by its values at the (path-slot-many) present arrows,
and any `Fin _ → ℚ` reconstructs a valid subalgebra element by
extending by zero outside `presentArrows m adj`.

This LinearEquiv is the core machinery for `pathOnlyAlgebraBasis`. -/
noncomputable def pathOnlyAlgebraEquivFun
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    ↥(pathOnlyAlgebraSubalgebra m adj) ≃ₗ[ℚ]
      (Fin (pathSlotIndices m adj).card → ℚ) where
  toFun f i :=
    f.val (slotToArrow m (slotEquiv m
      ((pathSlotIndices m adj).equivFin.symm i).val))
  invFun c :=
    ⟨fun a =>
      if h : a ∈ presentArrows m adj then
        c (arrowToPathSlotIdx m adj h)
      else 0,
     by
       intro a ha
       show (if h : a ∈ presentArrows m adj then _ else (0 : ℚ)) = 0
       rw [dif_neg ha]⟩
  left_inv f := by
    -- Forward then backward should give back f.
    apply Subtype.ext
    funext a
    -- (invFun (toFun f)) a = if a ∈ presentArrows then ... else 0
    -- Need to show this equals f.val a.
    show (if h : a ∈ presentArrows m adj then
            f.val (slotToArrow m (slotEquiv m
              ((pathSlotIndices m adj).equivFin.symm
                (arrowToPathSlotIdx m adj h)).val))
          else 0) = f.val a
    by_cases ha : a ∈ presentArrows m adj
    · rw [dif_pos ha, slotToArrow_slotEquiv_arrowToPathSlotIdx m adj ha]
    · rw [dif_neg ha]
      -- f.val a = 0 because f ∈ subalgebra and a ∉ presentArrows.
      have hf := f.property
      rw [mem_pathOnlyAlgebraSubalgebra_iff] at hf
      exact (hf a ha).symm
  right_inv c := by
    -- Backward then forward should give back c.
    funext i
    -- toFun (invFun c) i = (invFun c).val (slotToArrow ...) = c (arrowToPathSlotIdx ha)
    -- where ha is the proof that the arrow is in presentArrows.
    show (if h : slotToArrow m (slotEquiv m
              ((pathSlotIndices m adj).equivFin.symm i).val) ∈
              presentArrows m adj then
            c (arrowToPathSlotIdx m adj h)
          else 0) = c i
    have h_path : ((pathSlotIndices m adj).equivFin.symm i).val ∈
                    pathSlotIndices m adj :=
      ((pathSlotIndices m adj).equivFin.symm i).property
    have h_present := slotToArrow_mem_presentArrows_of_path m adj
        ((pathSlotIndices m adj).equivFin.symm i).val h_path
    rw [dif_pos h_present]
    -- Now need: c (arrowToPathSlotIdx m adj h_present) = c i.
    congr 1
    -- Goal: arrowToPathSlotIdx m adj h_present = i.
    unfold arrowToPathSlotIdx
    -- Strategy: rewrite `i = equivFin (equivFin.symm i)` on the RHS, then
    -- `congr 1` reduces to a Subtype equality whose first component is
    -- the round-trip identity `slotOfArrow ∘ slotToArrow ∘ slotEquiv = id`.
    conv_rhs => rw [← (pathSlotIndices m adj).equivFin.apply_symm_apply i]
    congr 1
    apply Subtype.ext
    show slotOfArrow m
            (slotToArrow m (slotEquiv m
              ((pathSlotIndices m adj).equivFin.symm i).val)) =
          ((pathSlotIndices m adj).equivFin.symm i).val
    unfold slotOfArrow
    rw [arrowToSlot_slotToArrow]
    exact (slotEquiv m).symm_apply_apply _
  map_add' f g := by
    funext i
    rfl
  map_smul' c f := by
    funext i
    rfl

-- ============================================================================
-- A.5.5.6 — pathOnlyAlgebraBasis.
-- ============================================================================

/-- **Sub-task A.5.5 — Path-only algebra basis.**

The basis of `pathOnlyAlgebraSubalgebra m adj` indexed by
`Fin (pathSlotIndices m adj).card` (the standard `Finset.equivFin`
enumeration of `pathSlotIndices m adj`).

Constructed via `Basis.ofEquivFun` from the LinearEquiv
`pathOnlyAlgebraEquivFun`. -/
noncomputable def pathOnlyAlgebraBasis
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Basis (Fin (pathSlotIndices m adj).card) ℚ
          ↥(pathOnlyAlgebraSubalgebra m adj) :=
  Basis.ofEquivFun (pathOnlyAlgebraEquivFun m adj)

/-- **Apply lemma:** `pathOnlyAlgebraBasis` repr matches the LinearEquiv. -/
@[simp] theorem pathOnlyAlgebraBasis_repr_apply
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (f : ↥(pathOnlyAlgebraSubalgebra m adj))
    (i : Fin (pathSlotIndices m adj).card) :
    (pathOnlyAlgebraBasis m adj).repr f i =
      pathOnlyAlgebraEquivFun m adj f i := by
  unfold pathOnlyAlgebraBasis
  rw [Basis.ofEquivFun_repr_apply]

-- ============================================================================
-- A.5.5.7 — Underlying function of a basis vector.
-- ============================================================================

/-- The underlying `pathAlgebraQuotient m`-function of the i-th basis
vector evaluated at any arrow `a`: it's `1` if `a` is the arrow
corresponding to the i-th path slot, else `0`.

This is the characteristic-function presentation of the basis vector. -/
theorem pathOnlyAlgebraBasis_apply_underlying
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i : Fin (pathSlotIndices m adj).card) (a : QuiverArrow m) :
    ((pathOnlyAlgebraBasis m adj) i).val a =
      if a = slotToArrow m (slotEquiv m
                ((pathSlotIndices m adj).equivFin.symm i).val) then 1
      else 0 := by
  classical
  -- Strategy: use `Basis.repr_self` + `Basis.ofEquivFun_repr_apply` to
  -- characterise `(b i).val (slotToArrow (slotEquiv s_j.val))` as
  -- `if j = i then 1 else 0`.  Then case-split on `a ∈ presentArrows m
  -- adj` to either reduce to that characterisation (path-algebra case)
  -- or use subalgebra membership (padding case).
  have h_basis_at_slot :
      ∀ j : Fin (pathSlotIndices m adj).card,
        ((pathOnlyAlgebraBasis m adj) i).val
          (slotToArrow m (slotEquiv m
            ((pathSlotIndices m adj).equivFin.symm j).val)) =
        (if j = i then 1 else 0) := by
    intro j
    -- Apply pathOnlyAlgebraEquivFun's forward direction at the i-th
    -- basis vector — this gives Pi.single i 1 by `Basis.ofEquivFun_repr_apply`
    -- composed with `Basis.repr_self`.
    have h_basis_eq :
        pathOnlyAlgebraEquivFun m adj ((pathOnlyAlgebraBasis m adj) i) j =
        (Finsupp.single i (1 : ℚ)) j := by
      have h_repr_self :
          (pathOnlyAlgebraBasis m adj).repr
            ((pathOnlyAlgebraBasis m adj) i) = Finsupp.single i 1 :=
        Basis.repr_self _ i
      have h_repr_eq :
          (pathOnlyAlgebraBasis m adj).repr
            ((pathOnlyAlgebraBasis m adj) i) j =
          pathOnlyAlgebraEquivFun m adj
            ((pathOnlyAlgebraBasis m adj) i) j := by
        unfold pathOnlyAlgebraBasis
        rw [Basis.ofEquivFun_repr_apply]
      rw [← h_repr_eq, h_repr_self]
    -- The LHS of `h_basis_eq` is by definition (b i).val (slotToArrow ...).
    have h_lhs_eq :
        pathOnlyAlgebraEquivFun m adj ((pathOnlyAlgebraBasis m adj) i) j =
        ((pathOnlyAlgebraBasis m adj) i).val
          (slotToArrow m (slotEquiv m
            ((pathSlotIndices m adj).equivFin.symm j).val)) := rfl
    rw [← h_lhs_eq, h_basis_eq]
    -- Finsupp.single i 1 j = if j = i then 1 else 0.
    by_cases h_j : j = i
    · subst h_j; rw [Finsupp.single_eq_same, if_pos rfl]
    · rw [Finsupp.single_eq_of_ne h_j, if_neg h_j]
  -- Now case-split on `a ∈ presentArrows m adj`.
  by_cases ha : a ∈ presentArrows m adj
  · -- a is a present arrow.  Rewrite `a = slotToArrow (slotEquiv s_j.val)`
    -- where `j := arrowToPathSlotIdx ha`.
    have h_a_eq : a = slotToArrow m (slotEquiv m
                    ((pathSlotIndices m adj).equivFin.symm
                      (arrowToPathSlotIdx m adj ha)).val) :=
      (slotToArrow_slotEquiv_arrowToPathSlotIdx m adj ha).symm
    rw [h_a_eq]
    rw [h_basis_at_slot (arrowToPathSlotIdx m adj ha)]
    -- Goal: (if arrowToPathSlotIdx ha = i then 1 else 0) =
    --       (if slotToArrow (slotEquiv s_idx.val) =
    --           slotToArrow (slotEquiv s_i.val) then 1 else 0).
    -- Rewriting `a` introduces `slotToArrow (slotEquiv s_idx.val)` on the
    -- RHS in place of `a`; the indicator condition is then the same on
    -- both sides up to congruence.
    by_cases h_eq : arrowToPathSlotIdx m adj ha = i
    · -- LHS = 1.  RHS: slotToArrow (slotEquiv s_idx.val) =
      --   slotToArrow (slotEquiv s_i.val); under h_eq, s_idx = s_i, so
      --   the slots agree.
      rw [if_pos h_eq, if_pos]
      rw [h_eq]
    · -- LHS = 0.  RHS: slot_idx ≠ i ⇒ s_idx ≠ s_i ⇒ slotToArrow ≠
      --   slotToArrow.
      rw [if_neg h_eq, if_neg]
      intro h_arr_eq
      apply h_eq
      -- slotToArrow (slotEquiv s_idx.val) = slotToArrow (slotEquiv s_i.val)
      -- slotEquiv is an equiv, slotToArrow is invertible (via arrowToSlot).
      -- Apply arrowToSlot to both sides of h_arr_eq.
      have h_slot_eq : slotEquiv m
            ((pathSlotIndices m adj).equivFin.symm
              (arrowToPathSlotIdx m adj ha)).val =
          slotEquiv m ((pathSlotIndices m adj).equivFin.symm i).val := by
        have := congrArg (arrowToSlot m) h_arr_eq
        rwa [arrowToSlot_slotToArrow, arrowToSlot_slotToArrow] at this
      have h_idx_eq : ((pathSlotIndices m adj).equivFin.symm
                        (arrowToPathSlotIdx m adj ha)).val =
                      ((pathSlotIndices m adj).equivFin.symm i).val :=
        (slotEquiv m).injective h_slot_eq
      have h_subtype : (pathSlotIndices m adj).equivFin.symm
                        (arrowToPathSlotIdx m adj ha) =
                      (pathSlotIndices m adj).equivFin.symm i :=
        Subtype.ext h_idx_eq
      exact (pathSlotIndices m adj).equivFin.symm.injective h_subtype
  · -- a ∉ presentArrows; LHS = 0 by subalgebra membership; RHS = 0.
    have hf := ((pathOnlyAlgebraBasis m adj) i).property
    rw [mem_pathOnlyAlgebraSubalgebra_iff] at hf
    rw [hf a ha]
    have h_path : ((pathSlotIndices m adj).equivFin.symm i).val ∈
                    pathSlotIndices m adj :=
      ((pathSlotIndices m adj).equivFin.symm i).property
    have h_arr_present := slotToArrow_mem_presentArrows_of_path m adj
        ((pathSlotIndices m adj).equivFin.symm i).val h_path
    have h_a_ne : a ≠ slotToArrow m (slotEquiv m
                    ((pathSlotIndices m adj).equivFin.symm i).val) := by
      intro h_eq
      apply ha
      rw [h_eq]
      exact h_arr_present
    rw [if_neg h_a_ne]

-- ============================================================================
-- A.6.1 — Bridge between Manin.structureTensor and pathOnlyStructureTensor.
-- ============================================================================

/-- **Helper:** the product `(pathOnlyAlgebraBasis m adj i) *
(pathOnlyAlgebraBasis m adj j)` (in the Subalgebra) has the indicator
underlying function `[pathMul arrow_i arrow_j = some _]`.

Specifically, evaluated at any arrow `c`, the underlying function
gives the indicator that `pathMul arrow_i arrow_j = some c`.

**Proof.** The Subalgebra multiplication agrees with the convolution
multiplication on `pathAlgebraQuotient m`.  In the double sum
`∑_{a, b} f(a) · g(b) · [pathMul a b = some c]` for the underlying
basis-vector functions, only the unique pair `(a, b) = (arrow_i,
arrow_j)` contributes (every other pair has `f(a) = 0` or `g(b) = 0`),
giving `[pathMul arrow_i arrow_j = some c]`. -/
theorem pathOnlyAlgebraBasis_mul_underlying
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j : Fin (pathSlotIndices m adj).card) (c : QuiverArrow m) :
    ((pathOnlyAlgebraBasis m adj) i *
      (pathOnlyAlgebraBasis m adj) j).val c =
      (if pathMul m
            (slotToArrow m (slotEquiv m
              ((pathSlotIndices m adj).equivFin.symm i).val))
            (slotToArrow m (slotEquiv m
              ((pathSlotIndices m adj).equivFin.symm j).val))
          = some c then 1 else 0) := by
  -- Subalgebra multiplication coerces to underlying multiplication.
  show (((pathOnlyAlgebraBasis m adj) i).val *
          ((pathOnlyAlgebraBasis m adj) j).val) c = _
  rw [pathAlgebraMul_apply]
  -- Simplify the basis-vector evaluations using the apply lemma, then
  -- both sums collapse via `Finset.sum_eq_single`.
  simp only [pathOnlyAlgebraBasis_apply_underlying]
  -- Goal: ∑ a b, (if a = arrow_i then 1 else 0) *
  --              (if b = arrow_j then 1 else 0) *
  --              (if pathMul a b = some c then 1 else 0) = indicator.
  rw [Finset.sum_eq_single
    (slotToArrow m
      (slotEquiv m ((pathSlotIndices m adj).equivFin.symm i).val))]
  · rw [Finset.sum_eq_single
      (slotToArrow m
        (slotEquiv m ((pathSlotIndices m adj).equivFin.symm j).val))]
    · -- Single term: both indicators fire.
      rw [if_pos rfl, if_pos rfl]
      ring
    · -- Off arrow_j: middle indicator vanishes.
      intro b _ h_b_ne
      rw [if_neg h_b_ne]
      ring
    · intro h_not_mem
      exact absurd (Finset.mem_univ _) h_not_mem
  · -- Off arrow_i: outer indicator vanishes.
    intro a _ h_a_ne
    rw [if_neg h_a_ne]
    apply Finset.sum_eq_zero
    intro b _
    ring
  · intro h_not_mem
    exact absurd (Finset.mem_univ _) h_not_mem

-- ============================================================================
-- A.6.1 — pathOnlyAlgebraBasis structure tensor matches pathOnlyStructureTensor.
-- ============================================================================

/-- **Sub-task A.6.1 — Bridge between Manin and the encoder.**

The Manin abstract structure tensor of `pathOnlyAlgebraBasis m adj`
(viewed as a basis of the path-only Subalgebra) equals the encoder's
`pathOnlyStructureTensor m adj`.

This is the **key bridge** that lets Manin's tensor-stabilizer theorem
(`Manin/TensorStabilizer.lean`) be applied to the path-only structure
tensor: when two adjacencies' encoders are GL³-related, the path-only
structure tensors are basis-change-related (in the Manin sense), and
Manin's theorem delivers an algebra equivalence between the two
path-only Subalgebras.

**Proof.** Direct computation:
* `Manin.structureTensor b i j k = (b.repr (b i * b j)) k =
  pathOnlyAlgebraEquivFun (b i * b j) k = (b i * b j).val
  (slotToArrow (slotEquiv s_k.val))`.
* By `pathOnlyAlgebraBasis_mul_underlying`, this equals
  `[pathMul arrow_i arrow_j = some arrow_k]`.
* By `pathOnlyStructureTensor_apply`, the RHS equals `grochowQioEncode
  m adj s_i.val s_j.val s_k.val`, which on path-algebra slots is also
  `[pathMul arrow_i arrow_j = some arrow_k]` (via
  `pathSlotStructureConstant`). -/
theorem pathOnlyAlgebraBasis_structureTensor_eq_pathOnlyStructureTensor
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Manin.structureTensor (pathOnlyAlgebraBasis m adj) =
      pathOnlyStructureTensor m adj := by
  funext i j k
  -- LHS: (b.repr (b i * b j)) k.
  -- RHS: grochowQiaoEncode m adj s_i.val s_j.val s_k.val.
  -- We use the LinearEquiv to transfer (b.repr ...) to its toFun image.
  rw [Manin.structureTensor_apply]
  -- Goal: ((b.repr (b i * b j)) k) = pathOnlyStructureTensor m adj i j k.
  rw [show (pathOnlyAlgebraBasis m adj).repr
              ((pathOnlyAlgebraBasis m adj) i *
                (pathOnlyAlgebraBasis m adj) j) k =
        pathOnlyAlgebraEquivFun m adj
              ((pathOnlyAlgebraBasis m adj) i *
                (pathOnlyAlgebraBasis m adj) j) k from by
    unfold pathOnlyAlgebraBasis
    rw [Basis.ofEquivFun_repr_apply]]
  -- pathOnlyAlgebraEquivFun (b i * b j) k = (b i * b j).val (slotToArrow ...)
  show ((pathOnlyAlgebraBasis m adj) i *
          (pathOnlyAlgebraBasis m adj) j).val
        (slotToArrow m (slotEquiv m
          ((pathSlotIndices m adj).equivFin.symm k).val)) = _
  rw [pathOnlyAlgebraBasis_mul_underlying]
  -- Goal: (if pathMul m arrow_i arrow_j = some arrow_k then 1 else 0) =
  --       pathOnlyStructureTensor m adj i j k
  -- = grochowQiaoEncode m adj s_i.val s_j.val s_k.val
  rw [pathOnlyStructureTensor_apply]
  -- We need the encoder at three path-algebra slots equal to the indicator.
  -- The encoder on path-algebra slot triples uses `pathSlotStructureConstant`.
  have h_si : isPathAlgebraSlot m adj
              ((pathSlotIndices m adj).equivFin.symm i).val = true := by
    have h_mem := ((pathSlotIndices m adj).equivFin.symm i).property
    rw [mem_pathSlotIndices_iff] at h_mem
    exact h_mem
  have h_sj : isPathAlgebraSlot m adj
              ((pathSlotIndices m adj).equivFin.symm j).val = true := by
    have h_mem := ((pathSlotIndices m adj).equivFin.symm j).property
    rw [mem_pathSlotIndices_iff] at h_mem
    exact h_mem
  have h_sk : isPathAlgebraSlot m adj
              ((pathSlotIndices m adj).equivFin.symm k).val = true := by
    have h_mem := ((pathSlotIndices m adj).equivFin.symm k).property
    rw [mem_pathSlotIndices_iff] at h_mem
    exact h_mem
  -- Now apply grochowQiaoEncode_path: encoder = pathSlotStructureConstant.
  rw [grochowQiaoEncode_path m adj _ _ _ h_si h_sj h_sk]
  -- pathSlotStructureConstant uses a match on pathMul; case-split via
  -- `rcases` and substitute into the match.
  unfold pathSlotStructureConstant
  rcases h_pm : pathMul m
              (slotToArrow m (slotEquiv m
                ((pathSlotIndices m adj).equivFin.symm i).val))
              (slotToArrow m (slotEquiv m
                ((pathSlotIndices m adj).equivFin.symm j).val)) with _ | d
  · -- pathMul = none.
    simp [h_pm]
  · -- pathMul = some d.
    simp only [h_pm]
    by_cases h_d_eq : d = slotToArrow m (slotEquiv m
                      ((pathSlotIndices m adj).equivFin.symm k).val)
    · rw [if_pos h_d_eq, if_pos]
      rw [h_d_eq]
    · rw [if_neg h_d_eq, if_neg]
      intro h_eq
      apply h_d_eq
      rw [Option.some.injEq] at h_eq
      exact h_eq

-- ============================================================================
-- A.6.2 — Identity-case witnesses for the Manin-discharge chain.
-- ============================================================================

/-- **Identity-case witness for the GL³-to-basis-change reduction at
matched cardinality.**

For any adjacency `adj`, the path-only structure tensor of `adj` is
`(1, 1, 1)`-basis-change-related to itself via
`Manin.IsBasisChangeRelated.id`.  This is the unconditional starting
point of the discharge chain. -/
theorem pathOnlyStructureTensor_basisChangeRelated_self
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Manin.IsBasisChangeRelated
        (pathOnlyStructureTensor m adj)
        (pathOnlyStructureTensor m adj)
        (1 : Matrix (Fin (pathSlotIndices m adj).card)
                    (Fin (pathSlotIndices m adj).card) ℚ)
        (1 : Matrix (Fin (pathSlotIndices m adj).card)
                    (Fin (pathSlotIndices m adj).card) ℚ) :=
  Manin.IsBasisChangeRelated.id _

/-- **Identity-case unit-compatibility witness.**

For any adjacency `adj`, the unit element `1 : pathAlgebraQuotient m`
under the path-only Subalgebra basis is unit-compatible at `P = 1`
(definitionally: both sides equal the basis representation of `1`). -/
theorem pathOnlyAlgebraBasis_unitCompatible_self
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Manin.IsUnitCompatible
        (pathOnlyAlgebraBasis m adj)
        (pathOnlyAlgebraBasis m adj)
        (1 : Matrix (Fin (pathSlotIndices m adj).card)
                    (Fin (pathSlotIndices m adj).card) ℚ) := by
  intro k
  -- (b.repr 1) k = ∑ v, (b.repr 1) v * (1 : Matrix) v k
  -- where (1 : Matrix) v k = if v = k then 1 else 0.
  -- So the sum collapses to (b.repr 1) k.
  rw [show (∑ v, (pathOnlyAlgebraBasis m adj).repr 1 v *
              (1 : Matrix (Fin (pathSlotIndices m adj).card)
                          (Fin (pathSlotIndices m adj).card) ℚ) v k) =
        ∑ v, (pathOnlyAlgebraBasis m adj).repr 1 v *
              (if v = k then (1 : ℚ) else 0) from by
    apply Finset.sum_congr rfl
    intro v _
    rw [Matrix.one_apply]]
  rw [Finset.sum_eq_single k]
  · simp
  · intro v _ h_v_ne
    rw [if_neg h_v_ne, mul_zero]
  · intro h_not_mem
    exact absurd (Finset.mem_univ k) h_not_mem

end GrochowQiao
end Orbcrypt
