/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
Mathlib API survey for Grochow–Qiao R-TI Layers T1–T6.

R-TI Layer T0.2 (transient deliverable) — every Mathlib declaration
referenced by the planned R-TI implementation has a 1-line
`example`-form check that confirms the declaration elaborates at
the expected type. This file is **transient**: per Decision GQ-D, it
should be deleted at the end of Layer T1 once the API has been
exercised by the live `PathAlgebra.lean` / `StructureTensor.lean`
imports and the survey is no longer informative. Until then, the
file's `#check` lines serve as a regression sentinel against API
drift on the pinned Mathlib commit `fa6418a8`.

See `docs/research/grochow_qiao_mathlib_api.md` for the prose
catalogue and `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`
§ "Decision GQ-D" / "R-TI Layer T0" for the exit criterion.
-/

import Mathlib.Data.Rat.Defs
import Mathlib.Data.Rat.Cast.CharZero
import Mathlib.Data.Fin.Basic
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Fintype.Card
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Image
import Mathlib.Data.Finset.Card
import Mathlib.Logic.Equiv.Basic
import Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup.Defs
import Mathlib.Algebra.Algebra.Basic
import Mathlib.Algebra.Algebra.Subalgebra.Basic
import Mathlib.Algebra.Algebra.Equiv

namespace Orbcrypt.GrochowQiao.ApiSurvey

universe u

-- ============================================================================
-- Layer T1 API surface — path-algebra construction.
-- ============================================================================

example : ∀ m, Fintype (Fin m × Fin m) := inferInstance
example : ∀ m, DecidableEq (Fin m) := inferInstance
example : ∀ m (S : Finset (Fin m)), S.card ≤ Fintype.card (Fin m) :=
  fun _ S => Finset.card_le_univ S
example (m : ℕ) (S : Finset (Fin m × Fin m))
    (hf : Function.Injective (fun p : Fin m × Fin m => p)) :
    (S.image (fun p : Fin m × Fin m => p)).card = S.card :=
  Finset.card_image_of_injective S hf

-- ============================================================================
-- Layer T2 API surface — tensor encoder + slot taxonomy.
-- ============================================================================

example : Type := Equiv.Perm (Fin 3)
example : Equiv.Perm (Fin 3) := 1
example (σ τ : Equiv.Perm (Fin 3)) : Equiv.Perm (Fin 3) := σ * τ

-- ============================================================================
-- Layer T3 API surface — permutation matrix and GL embedding.
-- ============================================================================

example : Type := Matrix (Fin 3) (Fin 3) ℚ
example : ∀ n, Inhabited (Matrix (Fin n) (Fin n) ℚ) :=
  fun _ => ⟨0⟩
example : ∀ n, GL (Fin n) ℚ → Matrix (Fin n) (Fin n) ℚ :=
  fun _ g => g.val

-- ============================================================================
-- Layer T4–T5 API surface — algebra automorphism and rigidity.
-- ============================================================================

example : Type := ℚ ≃ₐ[ℚ] ℚ
example : ℚ ≃ₐ[ℚ] ℚ := AlgEquiv.refl

example : Subalgebra ℚ (Matrix (Fin 3) (Fin 3) ℚ) :=
  Algebra.adjoin ℚ ({0} : Set (Matrix (Fin 3) (Fin 3) ℚ))

-- ============================================================================
-- Field / decidability API.
-- ============================================================================

example : DecidableEq ℚ := inferInstance
example : Field ℚ := inferInstance
example : CharZero ℚ := inferInstance

-- ============================================================================
-- Equiv / bijection API.
-- ============================================================================

example {α : Type*} : (α ≃ α) → α ≃ α := id
example {α : Type*} : (α ≃ α) → α → α := fun e => e.toFun
example {α β : Type*} (e₁ : α ≃ β) : β ≃ α := e₁.symm

-- ============================================================================
-- Exit criterion: every example above elaborates without error.
-- This file should be deleted at end of Layer T1 once the API
-- has been exercised by the live PathAlgebra.lean / StructureTensor.lean
-- imports.
-- ============================================================================

end Orbcrypt.GrochowQiao.ApiSurvey
