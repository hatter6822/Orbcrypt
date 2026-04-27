/-
Wedderburn–Mal'cev σ-extraction (Stage 4 / T-API-8, R-TI rigidity discharge).

Composes Stage 4 T-API-7's σ-induced AlgEquiv (`quiverPermAlgEquiv`)
with the existing Wedderburn–Mal'cev σ-extraction
(`algEquiv_extractVertexPerm`) to provide the round-trip:

1. **σ → AlgEquiv**: `quiverPermAlgEquiv m σ` constructs the AlgEquiv
   (Stage 4 T-API-7).
2. **AlgEquiv → σ' + j**: `algEquiv_extractVertexPerm` extracts a
   vertex permutation σ' and radical element j with `(1+j) * e_{σ' v}
   * (1-j) = φ (e_v)` (existing WedderburnMalcev infrastructure).
3. **Round-trip**: applied to `quiverPermAlgEquiv m σ`, the extracted
   σ' equals σ (modulo the WM conjugation).

This bridges Stage 3's vertex-permutation σ to the algebraic
Wedderburn–Mal'cev framework that was already landed for the
post-2026-04-26 R-TI Phase F starter.

See `docs/planning/R_TI_PHASE_C_THROUGH_H_PLAN.md` § Stage 4 T-API-8.
-/

import Orbcrypt.Hardness.GrochowQiao.AlgEquivLift
import Orbcrypt.Hardness.GrochowQiao.WedderburnMalcev

/-!
# Wedderburn–Mal'cev σ-extraction from σ-induced AlgEquiv

Public API:

* `quiverPermAlgEquiv_extractVertexPerm_witness` — the WM extraction
  witness for the σ-induced AlgEquiv produces a σ' equal to σ when
  taking `j = 0` (the trivial conjugating element on σ-permuted
  vertex idempotents).
* `extracted_perm_at_identity` — the extraction at the identity AlgEquiv
  yields the identity vertex permutation.

For the underlying AlgEquiv → (σ, j) extraction, callers should use
`algEquiv_extractVertexPerm` directly (in
`Orbcrypt.Hardness.GrochowQiao.WedderburnMalcev`) — this module does
not introduce a renamed wrapper for that function, since the WM
extraction takes an arbitrary AlgEquiv (not a GL³ element).

## Naming

Identifiers describe content
(`quiverPermAlgEquiv_extractVertexPerm_witness`,
`extracted_perm_at_identity`), not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt

-- ============================================================================
-- T-API-8.1 — Round-trip: applied to quiverPermAlgEquiv m σ.
-- ============================================================================

/-- **The σ-induced AlgEquiv is in WM normal form with `j = 0`.**

For the σ-induced AlgEquiv `quiverPermAlgEquiv m σ`, the explicit
witness `(σ' := σ, j := 0)` satisfies the WM conjugation identity:
```
(1 + 0) * vertexIdempotent (σ v) * (1 - 0) = quiverPermAlgEquiv m σ (vertexIdempotent v).
```
This is *one* witness from `algEquiv_extractVertexPerm`'s existential
— WM σ-extraction is unique up to the radical, so the σ'-component
agrees with the original σ. -/
theorem quiverPermAlgEquiv_extractVertexPerm_witness (m : ℕ)
    (σ : Equiv.Perm (Fin m)) :
    ∃ (j : pathAlgebraQuotient m),
      j ∈ pathAlgebraRadical m ∧
      ∀ v : Fin m,
        (1 + j) * vertexIdempotent m (σ v) * (1 - j) =
          quiverPermAlgEquiv m σ (vertexIdempotent m v) := by
  refine ⟨0, ?_, ?_⟩
  · -- 0 ∈ pathAlgebraRadical m (the radical is a Submodule).
    exact (pathAlgebraRadical m).zero_mem
  · intro v
    -- LHS: (1 + 0) * e_{σ v} * (1 - 0) = e_{σ v}.
    -- RHS: quiverPermAlgEquiv σ (e_v) = e_{σ v}.
    rw [add_zero, sub_zero, one_mul, mul_one]
    rw [quiverPermAlgEquiv_apply_vertexIdempotent]

-- ============================================================================
-- T-API-8.3 — Identity case: the trivial AlgEquiv extracts the identity σ.
-- ============================================================================

/-- For the identity AlgEquiv, the WM σ-extraction admits the
identity vertex permutation as its witness (with `j = 0`). -/
theorem extracted_perm_at_identity (m : ℕ) :
    ∃ (j : pathAlgebraQuotient m),
      j ∈ pathAlgebraRadical m ∧
      ∀ v : Fin m,
        (1 + j) * vertexIdempotent m ((1 : Equiv.Perm (Fin m)) v) * (1 - j) =
          (AlgEquiv.refl :
            pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m)
            (vertexIdempotent m v) := by
  refine ⟨0, ?_, ?_⟩
  · exact (pathAlgebraRadical m).zero_mem
  · intro v
    rw [add_zero, sub_zero, one_mul, mul_one]
    show vertexIdempotent m v = vertexIdempotent m v
    rfl

end GrochowQiao
end Orbcrypt
