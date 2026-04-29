/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
σ-induced AlgEquiv lift on `pathAlgebraQuotient m` (Stage 4 / T-API-7,
R-TI rigidity discharge).

Given a vertex permutation `σ : Equiv.Perm (Fin m)`, this module
constructs an `AlgEquiv` on `pathAlgebraQuotient m` that implements
the σ-action on the path algebra.

This is the **σ-construction** half of Stage 4: σ → AlgEquiv. The
*opposite* direction (AlgEquiv → σ via Wedderburn–Mal'cev) is the
existing `algEquiv_extractVertexPerm` in `WedderburnMalcev.lean`.
Stage 4 T-API-8 (`WMSigmaExtraction.lean`) composes the two
directions.

The construction uses the **pull-back** action: for `f :
pathAlgebraQuotient m`, `(σ • f) c := f (quiverMap m σ⁻¹ c)`.
This is multiplicative because `pathMul (qMap σ a) (qMap σ b) =
(pathMul a b).map (qMap σ)` (the basis-level multiplicative
equivariance from `PathAlgebra.lean`).

See `docs/planning/R_TI_PHASE_C_THROUGH_H_PLAN.md` § Stage 4 T-API-7.
-/

import Orbcrypt.Hardness.GrochowQiao.AlgebraWrapper

/-!
# σ-induced AlgEquiv on the path algebra

Public API:

* `quiverPermFun m σ : pathAlgebraQuotient m → pathAlgebraQuotient m`
  — the σ-pull-back action.
* `quiverPermFun_isLinear` — linearity.
* `quiverPermFun_apply_vertexIdempotent` — `σ • e_v = e_{σ v}`.
* `quiverPermFun_apply_arrowElement` — `σ • α(u,v) = α(σ u, σ v)`.
* `quiverPermFun_preserves_mul` — multiplicativity from
  `pathMul_quiverMap`.
* `quiverPermFun_preserves_one` — unit preservation.
* `quiverPermFun_round_trip` — `quiverPermFun σ⁻¹ ∘ quiverPermFun σ = id`.
* `quiverPermAlgEquiv m σ : pathAlgebraQuotient m ≃ₐ[ℚ]
  pathAlgebraQuotient m` — packaged AlgEquiv.
* `quiverPermAlgEquiv_apply_vertexIdempotent` — action on vertex
  idempotents (consumed by Stage 4 T-API-8).

## Naming

Identifiers describe content (`quiverPermFun`,
`quiverPermAlgEquiv`), not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt

-- ============================================================================
-- T-API-7.1 — Subspace identification + σ-pullback action.
-- ============================================================================

/-- The **σ-pullback action** on `pathAlgebraQuotient m`.

For `f : QuiverArrow m → ℚ` and `σ : Equiv.Perm (Fin m)`, the σ-action
is the function obtained by pulling back along `quiverMap m σ⁻¹`:
```
(quiverPermFun m σ f) c := f (quiverMap m σ⁻¹ c).
```
This is the natural σ-action that turns a vertex permutation into a
linear endomorphism of the path algebra. -/
def quiverPermFun (m : ℕ) (σ : Equiv.Perm (Fin m))
    (f : pathAlgebraQuotient m) : pathAlgebraQuotient m :=
  fun c => f (quiverMap m σ⁻¹ c)

/-- Apply lemma for `quiverPermFun`. -/
theorem quiverPermFun_apply (m : ℕ) (σ : Equiv.Perm (Fin m))
    (f : pathAlgebraQuotient m) (c : QuiverArrow m) :
    quiverPermFun m σ f c = f (quiverMap m σ⁻¹ c) := rfl

/-- The identity permutation acts as the identity on `pathAlgebraQuotient m`. -/
theorem quiverPermFun_one (m : ℕ) (f : pathAlgebraQuotient m) :
    quiverPermFun m 1 f = f := by
  funext c
  rw [quiverPermFun_apply]
  simp [quiverMap_one]

-- ============================================================================
-- T-API-7.2 — Linearity of the σ-pullback action.
-- ============================================================================

/-- The σ-action is linear: `σ • (f + g) = σ • f + σ • g`. -/
theorem quiverPermFun_add (m : ℕ) (σ : Equiv.Perm (Fin m))
    (f g : pathAlgebraQuotient m) :
    quiverPermFun m σ (f + g) = quiverPermFun m σ f + quiverPermFun m σ g := by
  funext c
  rw [quiverPermFun_apply]
  rfl

/-- The σ-action commutes with scalar multiplication. -/
theorem quiverPermFun_smul (m : ℕ) (σ : Equiv.Perm (Fin m))
    (r : ℚ) (f : pathAlgebraQuotient m) :
    quiverPermFun m σ (r • f) = r • quiverPermFun m σ f := by
  funext c
  rw [quiverPermFun_apply]
  rfl

/-- The σ-action sends zero to zero. -/
theorem quiverPermFun_zero (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    quiverPermFun m σ (0 : pathAlgebraQuotient m) = 0 := by
  funext c
  rw [quiverPermFun_apply]
  rfl

-- ============================================================================
-- T-API-7.3 — Action on basis elements.
-- ============================================================================

/-- The σ-action sends `vertexIdempotent v` to `vertexIdempotent (σ v)`.

*Proof.* `(σ • e_v) c = e_v (qMap σ⁻¹ c) = 1 iff qMap σ⁻¹ c = .id v`,
i.e., iff `c = qMap σ (.id v) = .id (σ v)`, which is exactly the
condition for `e_{σ v} c = 1`. -/
theorem quiverPermFun_apply_vertexIdempotent (m : ℕ) (σ : Equiv.Perm (Fin m))
    (v : Fin m) :
    quiverPermFun m σ (vertexIdempotent m v) = vertexIdempotent m (σ v) := by
  funext c
  rw [quiverPermFun_apply]
  cases c with
  | id w =>
    -- LHS: vertexIdempotent v (qMap σ⁻¹ (.id w)) = if v = σ⁻¹ w then 1 else 0.
    -- RHS: vertexIdempotent (σ v) (.id w) = if σ v = w then 1 else 0.
    -- Equivalent because v = σ⁻¹ w ↔ σ v = w.
    rw [quiverMap_id, vertexIdempotent_apply_id, vertexIdempotent_apply_id]
    by_cases h : v = σ⁻¹ w
    · have h' : σ v = w := by rw [h]; simp
      rw [if_pos h, if_pos h']
    · have h' : σ v ≠ w := fun heq => h (by rw [← heq]; simp)
      rw [if_neg h, if_neg h']
  | edge u w =>
    rw [quiverMap_edge, vertexIdempotent_apply_edge,
        vertexIdempotent_apply_edge]

/-- The σ-action sends `arrowElement u v` to `arrowElement (σ u) (σ v)`. -/
theorem quiverPermFun_apply_arrowElement (m : ℕ) (σ : Equiv.Perm (Fin m))
    (u v : Fin m) :
    quiverPermFun m σ (arrowElement m u v) =
      arrowElement m (σ u) (σ v) := by
  funext c
  rw [quiverPermFun_apply]
  cases c with
  | id w =>
    rw [quiverMap_id, arrowElement_apply_id, arrowElement_apply_id]
  | edge u' w =>
    rw [quiverMap_edge, arrowElement_apply_edge, arrowElement_apply_edge]
    -- LHS condition: u = σ⁻¹ u' ∧ v = σ⁻¹ w.
    -- RHS condition: σ u = u' ∧ σ v = w.
    by_cases h₁ : u = σ⁻¹ u'
    · by_cases h₂ : v = σ⁻¹ w
      · have h₁' : σ u = u' := by rw [h₁]; simp
        have h₂' : σ v = w := by rw [h₂]; simp
        rw [if_pos ⟨h₁, h₂⟩, if_pos ⟨h₁', h₂'⟩]
      · have h₂' : σ v ≠ w := fun heq => h₂ (by rw [← heq]; simp)
        rw [if_neg (fun ⟨_, h⟩ => h₂ h), if_neg (fun ⟨_, h⟩ => h₂' h)]
    · have h₁' : σ u ≠ u' := fun heq => h₁ (by rw [← heq]; simp)
      rw [if_neg (fun ⟨h, _⟩ => h₁ h), if_neg (fun ⟨h, _⟩ => h₁' h)]

-- ============================================================================
-- T-API-7.4 — Round-trip identity (σ⁻¹ ∘ σ = id).
-- ============================================================================

/-- The σ-action composed with the σ⁻¹-action is the identity. -/
theorem quiverPermFun_round_trip (m : ℕ) (σ : Equiv.Perm (Fin m))
    (f : pathAlgebraQuotient m) :
    quiverPermFun m σ⁻¹ (quiverPermFun m σ f) = f := by
  funext c
  rw [quiverPermFun_apply, quiverPermFun_apply]
  -- Goal: f (qMap σ⁻¹ (qMap (σ⁻¹)⁻¹ c)) = f c
  -- (σ⁻¹)⁻¹ = σ, so qMap (σ⁻¹)⁻¹ c = qMap σ c, and qMap σ⁻¹ (qMap σ c) = c.
  cases c with
  | id w =>
    simp [quiverMap_id]
  | edge u w =>
    simp [quiverMap_edge]

/-- Symmetric round-trip identity. -/
theorem quiverPermFun_round_trip' (m : ℕ) (σ : Equiv.Perm (Fin m))
    (f : pathAlgebraQuotient m) :
    quiverPermFun m σ (quiverPermFun m σ⁻¹ f) = f := by
  -- Apply `quiverPermFun_round_trip` at σ⁻¹: `quiverPermFun (σ⁻¹)⁻¹
  -- (quiverPermFun σ⁻¹ f) = f`. Since (σ⁻¹)⁻¹ = σ, this is what we want.
  have := quiverPermFun_round_trip m σ⁻¹ f
  rwa [inv_inv] at this

-- ============================================================================
-- T-API-7.5 — Multiplicativity (the central technical lemma).
-- ============================================================================

/-- The σ-action preserves multiplication: `σ • (f * g) = (σ • f) * (σ • g)`.

*Proof.* Both sides expand via `pathAlgebraMul_apply`. The key step
uses `pathMul_quiverMap` (basis-element-level multiplicative
equivariance from `PathAlgebra.lean`): `pathMul (qMap σ a) (qMap σ b)
= (pathMul a b).map (qMap σ)`. After change of summation variables
`(a, b) → (qMap σ⁻¹ a', qMap σ⁻¹ b')`, the indicator
`pathMul a' b' = some (qMap σ⁻¹ c)` matches the indicator
`pathMul (qMap σ a') (qMap σ b') = some c` via `pathMul_quiverMap`. -/
theorem quiverPermFun_preserves_mul (m : ℕ) (σ : Equiv.Perm (Fin m))
    (f g : pathAlgebraQuotient m) :
    quiverPermFun m σ (f * g) =
      quiverPermFun m σ f * quiverPermFun m σ g := by
  funext c
  -- Build the change-of-variables equiv on QuiverArrow m: a ↦ qMap σ a.
  let qEquiv : QuiverArrow m ≃ QuiverArrow m :=
    { toFun := quiverMap m σ
      invFun := quiverMap m σ⁻¹
      left_inv := fun a => by cases a <;> simp [quiverMap_id, quiverMap_edge]
      right_inv := fun a => by cases a <;> simp [quiverMap_id, quiverMap_edge] }
  -- Unfold both sides to explicit double sums.
  rw [quiverPermFun_apply, pathAlgebraMul_apply, pathAlgebraMul_apply]
  -- Now: LHS: ∑ a b, f a * g b * [pathMul a b = some (qMap σ⁻¹ c)]
  --      RHS: ∑ a b, qpf(σ,f) a * qpf(σ,g) b * [pathMul a b = some c]
  -- Change of variables on RHS: a → qEquiv a', b → qEquiv b'. Use Equiv.sum_comp.
  symm
  rw [show
      (∑ a : QuiverArrow m, ∑ b : QuiverArrow m,
        quiverPermFun m σ f a * quiverPermFun m σ g b *
          (if pathMul m a b = some c then (1 : ℚ) else 0)) =
      (∑ a' : QuiverArrow m, ∑ b' : QuiverArrow m,
        quiverPermFun m σ f (qEquiv a') * quiverPermFun m σ g (qEquiv b') *
          (if pathMul m (qEquiv a') (qEquiv b') = some c then (1 : ℚ) else 0))
        from ?_]
  · -- Now simplify the body inside the double sum.
    refine Finset.sum_congr rfl (fun a' _ => Finset.sum_congr rfl (fun b' _ => ?_))
    -- Reduce quiverPermFun σ f (qEquiv a') = f a' via round-trip.
    have h_qf : quiverPermFun m σ f (qEquiv a') = f a' := by
      rw [quiverPermFun_apply]
      exact congrArg f (qEquiv.symm_apply_apply a')
    have h_qg : quiverPermFun m σ g (qEquiv b') = g b' := by
      rw [quiverPermFun_apply]
      exact congrArg g (qEquiv.symm_apply_apply b')
    rw [h_qf, h_qg]
    -- Now show indicators match: pathMul (qEquiv a') (qEquiv b') = some c
    -- ↔ pathMul a' b' = some (qMap σ⁻¹ c).
    have h_pm : pathMul m (qEquiv a') (qEquiv b') =
                (pathMul m a' b').map (quiverMap m σ) := pathMul_quiverMap m σ a' b'
    have h_iff : (pathMul m (qEquiv a') (qEquiv b') = some c) ↔
                 (pathMul m a' b' = some (quiverMap m σ⁻¹ c)) := by
      rw [h_pm]
      cases h_p : pathMul m a' b' with
      | none => simp
      | some d =>
        simp only [Option.map_some, Option.some.injEq]
        constructor
        · intro h_eq
          rw [← h_eq]
          cases d <;> simp [quiverMap_id, quiverMap_edge]
        · intro h_eq
          rw [h_eq]
          cases c <;> simp [quiverMap_id, quiverMap_edge]
    rw [if_congr h_iff rfl rfl]
  · -- Change of variables: ∑ a, F a = ∑ a', F (qEquiv a'), via Equiv.sum_comp.
    -- Apply twice (once per axis).
    have h_outer := Equiv.sum_comp qEquiv (M := ℚ) (fun a =>
      ∑ b : QuiverArrow m, quiverPermFun m σ f a * quiverPermFun m σ g b *
        (if pathMul m a b = some c then (1 : ℚ) else 0))
    rw [← h_outer]
    refine Finset.sum_congr rfl (fun a _ => ?_)
    have h_inner := Equiv.sum_comp qEquiv (M := ℚ) (fun b =>
      quiverPermFun m σ f (qEquiv a) * quiverPermFun m σ g b *
        (if pathMul m (qEquiv a) b = some c then (1 : ℚ) else 0))
    rw [← h_inner]

-- ============================================================================
-- T-API-7.6 — Unit preservation.
-- ============================================================================

/-- The σ-action preserves the multiplicative identity `1 = ∑_v vertexIdempotent v`.

*Proof.* `pathAlgebraOne m = ∑_v vertexIdempotent m v`. By linearity
and `quiverPermFun_apply_vertexIdempotent`, σ-action sends each
`vertexIdempotent v` to `vertexIdempotent (σ v)`. The sum
re-indexes via σ as a permutation, leaving `∑_v vertexIdempotent v
= 1` unchanged. -/
theorem quiverPermFun_preserves_one (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    quiverPermFun m σ (1 : pathAlgebraQuotient m) = 1 := by
  funext c
  rw [quiverPermFun_apply]
  -- 1 in pathAlgebraQuotient m is pathAlgebraOne m. Reduce both sides.
  show pathAlgebraOne m (quiverMap m σ⁻¹ c) = pathAlgebraOne m c
  cases c with
  | id w =>
    rw [quiverMap_id, pathAlgebraOne_apply_id, pathAlgebraOne_apply_id]
  | edge u w =>
    rw [quiverMap_edge, pathAlgebraOne_apply_edge,
        pathAlgebraOne_apply_edge]

-- ============================================================================
-- T-API-7.7 — Package as AlgEquiv.
-- ============================================================================

/-- **The σ-induced AlgEquiv on `pathAlgebraQuotient m`** (Stage 4 T-API-7
headline construction).

Given a vertex permutation `σ : Equiv.Perm (Fin m)`, this produces an
algebra automorphism of `pathAlgebraQuotient m` that:
* sends `vertexIdempotent v` to `vertexIdempotent (σ v)`.
* sends `arrowElement u v` to `arrowElement (σ u) (σ v)`.
* preserves the algebra structure (multiplicativity from
  `pathMul_quiverMap`, unit preservation from `pathAlgebraOne`'s
  σ-equivariance).

This is the **σ-construction half** of Stage 4. The opposite
direction (AlgEquiv → σ via Wedderburn–Mal'cev) is the existing
`algEquiv_extractVertexPerm` in `WedderburnMalcev.lean`. Stage 4
T-API-8 (`WMSigmaExtraction.lean`) composes the two directions. -/
noncomputable def quiverPermAlgEquiv (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m where
  toFun := quiverPermFun m σ
  invFun := quiverPermFun m σ⁻¹
  left_inv := quiverPermFun_round_trip m σ
  right_inv := quiverPermFun_round_trip' m σ
  map_mul' := quiverPermFun_preserves_mul m σ
  map_add' := quiverPermFun_add m σ
  commutes' := by
    intro r
    -- algebraMap ℚ (pathAlgebraQuotient m) r = r • 1 in any Algebra.
    rw [show (algebraMap ℚ (pathAlgebraQuotient m)) r =
            r • (1 : pathAlgebraQuotient m) from
      (Algebra.algebraMap_eq_smul_one r)]
    rw [quiverPermFun_smul, quiverPermFun_preserves_one]

/-- The AlgEquiv applied to f equals `quiverPermFun σ f`. -/
@[simp] theorem quiverPermAlgEquiv_apply (m : ℕ) (σ : Equiv.Perm (Fin m))
    (f : pathAlgebraQuotient m) :
    quiverPermAlgEquiv m σ f = quiverPermFun m σ f := rfl

-- ============================================================================
-- T-API-7.8 — Action on vertex idempotents (consumed by T-API-8).
-- ============================================================================

/-- The σ-induced AlgEquiv sends `vertexIdempotent v` to
`vertexIdempotent (σ v)`.

This is the explicit formula consumed by Stage 4 T-API-8 when composing
with `algEquiv_extractVertexPerm` for the σ-extraction round-trip. -/
@[simp] theorem quiverPermAlgEquiv_apply_vertexIdempotent (m : ℕ)
    (σ : Equiv.Perm (Fin m)) (v : Fin m) :
    quiverPermAlgEquiv m σ (vertexIdempotent m v) = vertexIdempotent m (σ v) :=
  quiverPermFun_apply_vertexIdempotent m σ v

/-- The σ-induced AlgEquiv sends `arrowElement u v` to
`arrowElement (σ u) (σ v)`. -/
@[simp] theorem quiverPermAlgEquiv_apply_arrowElement (m : ℕ)
    (σ : Equiv.Perm (Fin m)) (u v : Fin m) :
    quiverPermAlgEquiv m σ (arrowElement m u v) =
      arrowElement m (σ u) (σ v) :=
  quiverPermFun_apply_arrowElement m σ u v

/-- The identity vertex permutation gives the identity AlgEquiv. -/
theorem quiverPermAlgEquiv_one (m : ℕ) :
    quiverPermAlgEquiv m 1 = AlgEquiv.refl := by
  apply AlgEquiv.ext
  intro f
  rw [quiverPermAlgEquiv_apply, quiverPermFun_one]
  rfl

end GrochowQiao
end Orbcrypt
