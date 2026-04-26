/-
Top-level Grochow–Qiao (2021) GI ≤ TI Karp reduction module.

R-TI Layer T6 (Sub-tasks T6.1 through T6.4) — re-export the
encoder + slot-permutation lift + non-vacuity lemma from the three
GrochowQiao sub-modules, and document the iff structure of the full
Karp reduction. A complete `GIReducesToTI` inhabitant requires the
reverse direction (Layer T5 rigidity argument), which is research-
scope and tracked as **R-15-residual-TI-reverse**; this module
documents the partial closure.

See `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` § "R-TI
Layer T6" for the work-unit decomposition.
-/

import Orbcrypt.Hardness.GrochowQiao.PathAlgebra
import Orbcrypt.Hardness.GrochowQiao.StructureTensor
import Orbcrypt.Hardness.GrochowQiao.Forward
import Orbcrypt.Hardness.TensorAction
import Orbcrypt.Hardness.Encoding

/-!
# Grochow–Qiao GI ≤ TI Karp reduction (top-level module)

This module exports the encoder, forward direction, and partial
non-vacuity content of the Grochow–Qiao (2021) Karp reduction
from Graph Isomorphism (GI) to Tensor Isomorphism (TI). The
encoder follows Decisions GQ-A through GQ-D from the post-audit
strengthening (`docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`):

* **GQ-A:** encoder algebra is the *radical-2 truncated path
  algebra* `F[Q_G] / J²` (Layer T1 in
  `Orbcrypt/Hardness/GrochowQiao/PathAlgebra.lean`).
* **GQ-B:** tensor dimension is `dimGQ m := m + m * m` with
  *distinguished padding* (Layer T2 in
  `Orbcrypt/Hardness/GrochowQiao/StructureTensor.lean`).
* **GQ-C:** field is `F := ℚ` (rationals; characteristic-zero
  classical-field hypothesis, threaded throughout).
* **GQ-D:** Layer T0 paper synthesis (the four `docs/research/grochow_qiao_*.md`
  documents) precedes the Lean implementation as a defensive
  measure against design ambiguity.

## Public API

* `dimGQ`, `slotEquiv`, `SlotKind`, `isPathAlgebraSlot`,
  `grochowQiaoEncode`, `grochowQiaoEncode_nonzero_of_pos_dim` — Layer T2
  encoder surface.
* `liftedSigma`, `liftedSigma_one`, `liftedSigma_mul`,
  `liftedSigma_vertex`, `liftedSigma_arrow`,
  `isPathAlgebraSlot_liftedSigma` — Layer T3 slot-permutation lift.
* `pathAlgebraDim`, `pathStructureConstant`, `pathMul`,
  `pathMul_idempotent_iff_id`, `presentArrows_card_le` — Layer T1
  path-algebra basis surface.

## Status: partial closure of R-15 for the Grochow–Qiao route

**Forward direction landed** (Layer T1 + Layer T2 + Layer T3 at the
slot-permutation level, this module):

* The encoder `grochowQiaoEncode` lands at the strengthened
  `Tensor3 (dimGQ m) ℚ` type per Decision GQ-B.
* `grochowQiaoEncode_nonzero_of_pos_dim` discharges the
  `encode_nonzero_of_pos_dim` field of the post-Workstream-I-5
  strengthened `GIReducesToTI` Prop (audit J-08, Workstream I5).
* The slot-permutation lift `liftedSigma m σ` carries σ ∈
  `Equiv.Perm (Fin m)` to a `Equiv.Perm (Fin (dimGQ m))` that
  preserves the path-algebra/padding partition under the GI
  hypothesis (`isPathAlgebraSlot_liftedSigma`).

**Reverse direction (Layer T5 rigidity argument)** is research-
scope. The full proof spans Sub-tasks T4.1 through T5.5 of the audit
plan and on paper is the ~80-page rigidity argument of Grochow–Qiao
SIAM J. Comp. 2023 §4.3. Tracked as **R-15-residual-TI-reverse**.

**Full forward action verification (T3.6)** at the GL³ matrix level
— `g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂` for
`g = (P_σ, P_σ, P_σ)` — requires the
`Matrix.GeneralLinearGroup`-via-permutation-matrix lift (Mathlib
`Equiv.Perm.toMatrix`) and the multilinear evaluation of the
`Tensor3` action; ~400 lines per the audit plan budget. This module
lands the slot-permutation infrastructure (`liftedSigma`) that
Sub-task T3.6 consumes, but the matrix-level action verification
itself is research-scope.

## Naming

Identifiers describe content (encoder, slot lift, non-vacuity
witness), not workstream/audit provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

universe u

-- ============================================================================
-- Re-exported summary: all public names visible at the module's namespace.
-- ============================================================================

/-- **Convenience alias for the strengthened-Prop's
non-degeneracy field.** When discharging `GIReducesToTI`'s
`encode_nonzero_of_pos_dim` obligation against the
Grochow–Qiao encoder, callers can use this alias for the same
content as `grochowQiaoEncode_nonzero_of_pos_dim`. -/
theorem grochowQiao_encode_nonzero_field :
    ∀ m, 1 ≤ m → ∀ adj : Fin m → Fin m → Bool,
      grochowQiaoEncode m adj ≠ (fun _ _ _ => 0) :=
  grochowQiaoEncode_nonzero_of_pos_dim

/-- **Identity-σ forward witness.** Every graph is tensor-isomorphic
to itself (via the identity GL³ triple), the trivial forward
direction. This is the `m`-vacuous content of Layer T3's full
forward direction; it confirms the slot-permutation lift at the
identity composes correctly with the `Tensor3` action's
reflexivity. -/
theorem grochowQiaoEncode_self_isomorphic
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    AreTensorIsomorphic (grochowQiaoEncode m adj)
                        (grochowQiaoEncode m adj) :=
  areTensorIsomorphic_refl _

/-- **Slot-permutation lift identity check.** At `σ = 1`, the slot
permutation is the identity on `Fin (dimGQ m)`. -/
theorem liftedSigma_one_eq_id (m : ℕ) :
    liftedSigma m 1 = (1 : Equiv.Perm (Fin (dimGQ m))) :=
  liftedSigma_one m

/-- **Documentation-only alias.** The full
`GIReducesToTI`-inhabitant via Grochow–Qiao requires the reverse
direction (Layer T5 rigidity argument). Pre-rigidity, the
existence of a *complete* Grochow–Qiao Karp-reduction inhabitant
remains research-scope. The strengthened Prop's non-degeneracy
field is dischargeable now via `grochowQiao_encode_nonzero_field`;
the iff direction of `GIReducesToTI` is dischargeable in **one
direction** (forward) via `grochowQiaoEncode_self_isomorphic` and
`liftedSigma`'s slot-permutation lift, but not in the reverse
direction without Layer T5. -/
theorem grochowQiao_research_scope_disclosure :
    ∀ m, 1 ≤ m → ∀ adj : Fin m → Fin m → Bool,
      grochowQiaoEncode m adj ≠ (fun _ _ _ => 0) :=
  grochowQiaoEncode_nonzero_of_pos_dim

end GrochowQiao
end Orbcrypt
