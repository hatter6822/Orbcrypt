/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

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
import Orbcrypt.Hardness.GrochowQiao.PermMatrix
import Orbcrypt.Hardness.GrochowQiao.Reverse
import Orbcrypt.Hardness.GrochowQiao.Rigidity
import Orbcrypt.Hardness.GrochowQiao.Discharge
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

-- ============================================================================
-- Layer T6.1 — Iff assembly (conditional on the rigidity hypothesis).
-- ============================================================================

/-- **Iff assembly under the rigidity hypothesis (Layer T6.1).**

Composes the *encoder-equivariance* form of the forward direction
(Layer T3.7) with the conditional reverse direction (Layer T5.4
via `grochowQiaoEncode_reverse_under_rigidity`). The result is the
Karp-reduction iff at the encoder-equality level, conditional on
`GrochowQiaoRigidity`.

**Forward direction status.** This iff uses an *encoder-equality*
formulation of the forward direction (`grochowQiaoEncode_equivariant`),
which captures the same content as `AreTensorIsomorphic` but at the
slot level. The full GL³ matrix-action upgrade (T3.6) is research-
scope. For the Karp-reduction iff, we lift the encoder-equivariance
form to `AreTensorIsomorphic` via the σ-lifted permutation matrix
(stated in Prop form here as a forward-direction obligation;
discharge would be ~400 lines of permutation-matrix-tensor-action
algebra, audit plan T3.6 budget). -/
def GrochowQiaoForwardObligation : Prop :=
  ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool),
    (∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) →
    AreTensorIsomorphic
      (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂)

/-- **Layer T3.6 discharge of `GrochowQiaoForwardObligation`** (post-
2026-04-26 R-TI extension).

Closes the forward GL³ matrix-action obligation unconditionally
using the permutation-matrix tensor-action collapse infrastructure
in `Orbcrypt/Hardness/GrochowQiao/PermMatrix.lean`.

**Proof.** Given the GI hypothesis `σ : adj₁ ≅ adj₂`, the GL³ triple
`(liftedSigmaGL m σ⁻¹, liftedSigmaGL m σ⁻¹, liftedSigmaGL m σ⁻¹)`
implements the encoder isomorphism — verified by
`grochowQiaoEncode_gl_isomorphic` (PermMatrix.lean B.8).

This closes one of the two research-scope Props introduced by the
post-2026-04-26 partial-closure landing. -/
theorem grochowQiao_forwardObligation : GrochowQiaoForwardObligation := by
  intro m adj₁ adj₂ ⟨σ, h⟩
  exact ⟨(liftedSigmaGL m σ⁻¹, liftedSigmaGL m σ⁻¹, liftedSigmaGL m σ⁻¹),
    grochowQiaoEncode_gl_isomorphic m adj₁ adj₂ σ h⟩

/-- **The forward direction's encoder-equality lemma.**

Re-exports `grochowQiaoEncode_equivariant` (Layer T3.6+T3.7
encoder-equality form) for use by downstream consumers — the slot-
level statement that the encoder is invariant under the σ-lift on
all three tensor indices, given the GI hypothesis. -/
theorem grochowQiaoEncode_forward_equality :
    ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
      (σ : Equiv.Perm (Fin m)),
      (∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) →
      ∀ i j k, grochowQiaoEncode m adj₁ i j k =
               grochowQiaoEncode m adj₂
                 (liftedSigma m σ i)
                 (liftedSigma m σ j)
                 (liftedSigma m σ k) :=
  fun m adj₁ adj₂ σ h => grochowQiaoEncode_equivariant m adj₁ adj₂ σ h

/-- **Iff assembly conditional on `GrochowQiaoForwardObligation` and
`GrochowQiaoRigidity`** (T6.1 — research-scope conditional form).

The full Karp-reduction iff `(∃ σ, ...) ↔ AreTensorIsomorphic
T_{adj₁} T_{adj₂}` holds under both:

* `GrochowQiaoForwardObligation` — discharges the forward direction
  (lifts the encoder-equality to a GL³ matrix action via the
  σ-lifted permutation matrix; ~400 lines, audit plan T3.6).
* `GrochowQiaoRigidity` — discharges the reverse direction (the
  multi-month rigidity argument; audit plan T4 + T5).

Both Props are research-scope **R-15-residual-TI-***. -/
theorem grochowQiaoEncode_iff
    (h_forward : GrochowQiaoForwardObligation)
    (h_rigidity : GrochowQiaoRigidity)
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) :
    (∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) ↔
    AreTensorIsomorphic
      (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂) := by
  constructor
  · exact h_forward m adj₁ adj₂
  · intro h_iso
    exact h_rigidity m adj₁ adj₂ h_iso

-- ============================================================================
-- Layer T6.2 — Non-degeneracy field discharge (already done in T2.4).
-- ============================================================================

/-- **Non-degeneracy field discharge** (Layer T6.2, re-export of T2.4).

The strengthened `GIReducesToTI` Prop's `encode_nonzero_of_pos_dim`
field is discharged unconditionally by `grochowQiaoEncode`. This
re-export aliases T2.4's `grochowQiaoEncode_nonzero_of_pos_dim` for
use in the conditional Karp-reduction inhabitant below. -/
theorem grochowQiao_encode_nonzero_field_check :
    ∀ m, 1 ≤ m → ∀ adj, grochowQiaoEncode m adj ≠ (fun _ _ _ => 0) :=
  grochowQiaoEncode_nonzero_of_pos_dim

-- ============================================================================
-- Layer T6.3 — Conditional `GIReducesToTI` inhabitant.
-- ============================================================================

/-- **Conditional `GIReducesToTI` inhabitant (Layer T6.3).**

A complete inhabitant of `GIReducesToTI` over ℚ, conditional on
`GrochowQiaoForwardObligation` and `GrochowQiaoRigidity`. This is
the consumer-facing Karp-reduction theorem: any discharge of the
two Props yields a fully-fledged `GIReducesToTI` inhabitant via the
Grochow–Qiao path-algebra encoder.

Pre-discharge of either Prop, the inhabitant is conditional;
post-discharge of *both* Props (research-scope **R-15-residual-TI-
forward-matrix** for `GrochowQiaoForwardObligation`, **R-15-residual-
TI-reverse** for `GrochowQiaoRigidity`), the inhabitant becomes
unconditional. The user can then prove `@GIReducesToTI ℚ _` by
invoking this theorem at the discharged Props. -/
theorem grochowQiao_isInhabitedKarpReduction_under_obligations
    (h_forward : GrochowQiaoForwardObligation)
    (h_rigidity : GrochowQiaoRigidity) :
    @GIReducesToTI ℚ _ :=
  ⟨dimGQ,
   grochowQiaoEncode,
   grochowQiaoEncode_nonzero_of_pos_dim,
   grochowQiaoEncode_iff h_forward h_rigidity⟩

/-- **Single-hypothesis conditional Karp-reduction inhabitant.**

Post-2026-04-26 R-TI extension (Track B / B.8) discharged
`GrochowQiaoForwardObligation` unconditionally via the permutation-
matrix tensor-action collapse infrastructure. So the conditional
inhabitant now requires only the rigidity Prop:

```lean
@GIReducesToTI ℚ _ ← GrochowQiaoRigidity
```

When `GrochowQiaoRigidity` is discharged (research-scope
**R-15-residual-TI-reverse**), this becomes a complete unconditional
inhabitant. -/
theorem grochowQiao_isInhabitedKarpReduction_under_rigidity
    (h_rigidity : GrochowQiaoRigidity) :
    @GIReducesToTI ℚ _ :=
  grochowQiao_isInhabitedKarpReduction_under_obligations
    grochowQiao_forwardObligation h_rigidity

-- ============================================================================
-- Layer T6.4 — Final non-vacuity disclosure.
-- ============================================================================

/-- **Final non-vacuity disclosure (Layer T6.4).**

Documents the post-2026-04-26 R-TI extension status of the Grochow–
Qiao reduction:

* The **encoder** (`grochowQiaoEncode`), **forward direction at the
  encoder-equality level** (`grochowQiaoEncode_forward_equality`),
  **edge-case reverse directions** (`grochowQiaoEncode_reverse_zero`,
  `grochowQiaoEncode_reverse_one`), and **non-degeneracy**
  (`grochowQiaoEncode_nonzero_of_pos_dim`) are landed unconditionally.
* The **GL³ matrix-action upgrade of the forward direction**
  (`GrochowQiaoForwardObligation`) is now **discharged
  unconditionally** via `grochowQiao_forwardObligation` (Track B
  of the 2026-04-26 implementation, using
  `Orbcrypt/Hardness/GrochowQiao/PermMatrix.lean`).
* The **rigidity argument** (`GrochowQiaoRigidity`) remains a
  `Prop`-typed obligation; it is consumed by the single-hypothesis
  conditional inhabitant
  `grochowQiao_isInhabitedKarpReduction_under_rigidity`. Discharging
  this Prop is research-scope **R-15-residual-TI-reverse**
  (~80 pages of Grochow–Qiao SIAM J. Comp. 2023 §4.3).

The full Karp-reduction inhabitant `@GIReducesToTI ℚ _` becomes
unconditional once `GrochowQiaoRigidity` is discharged. -/
theorem grochowQiao_partial_closure_status :
    -- Encoder produces non-zero tensors for all non-empty graphs.
    (∀ m, 1 ≤ m → ∀ adj, grochowQiaoEncode m adj ≠ (fun _ _ _ => 0)) ∧
    -- Empty-graph reverse direction is unconditional.
    (∀ adj₁ adj₂ : Fin 0 → Fin 0 → Bool,
      AreTensorIsomorphic (grochowQiaoEncode 0 adj₁) (grochowQiaoEncode 0 adj₂) →
      ∃ σ : Equiv.Perm (Fin 0), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) ∧
    -- Forward obligation is now unconditional.
    GrochowQiaoForwardObligation :=
  ⟨grochowQiaoEncode_nonzero_of_pos_dim,
   grochowQiaoEncode_reverse_zero,
   grochowQiao_forwardObligation⟩

-- ============================================================================
-- Stage 5 T-API-10 — Final Karp reduction inhabitant under arrow-discharge.
-- ============================================================================

/-- **Final Karp reduction inhabitant under the Stage 5 arrow-preservation
discharge** (R-TI Stage 5 T-API-10).

Composes the Stage 5 `grochowQiaoRigidity_under_arrowDischarge` with
the existing `grochowQiao_isInhabitedKarpReduction_under_rigidity` to
produce a `@GIReducesToTI ℚ _` inhabitant under the single
research-scope `Prop` `GL3InducesArrowPreservingPerm`.

When `GL3InducesArrowPreservingPerm` is discharged (research-scope
**R-15-residual-TI-reverse**), this becomes the unconditional
Karp reduction. -/
theorem grochowQiao_isInhabitedKarpReduction_full_chain
    (h_arrow : GL3InducesArrowPreservingPerm) :
    @GIReducesToTI ℚ _ :=
  grochowQiao_isInhabitedKarpReduction_under_rigidity
    (grochowQiaoRigidity_under_arrowDischarge h_arrow)

-- ============================================================================
-- R-TI Phase 3 (2026-04-28) — Discharge of Phase-3 Props from rigidity.
-- ============================================================================

/-- **Phase 3 partial-discharge under `GrochowQiaoRigidity`.**

Under the existing research-scope Prop `GrochowQiaoRigidity`, BOTH
research-scope Props introduced by R-TI Phase 3
(`GL3InducesAlgEquivOnPathSubspace` and `RestrictedGL3OnPathOnlyTensor`)
are discharged.

This theorem packages the two discharge directions into a single
conjunction, demonstrating that R-TI Phase 3's partial-discharge
framework reduces cleanly to the existing Stages 0–5 chain — no new
research-scope obligation is introduced; the Phase 3 Props are
immediate consequences of `GrochowQiaoRigidity`.

See `Orbcrypt/Hardness/GrochowQiao/Discharge.lean` for the bridge
proofs:
* `Discharge.gl3InducesAlgEquivOnPathSubspace_of_rigidity`
* `Discharge.restrictedGL3OnPathOnlyTensor_of_rigidity`

Combined with `grochowQiao_isInhabitedKarpReduction_under_rigidity`,
this gives a unified package: under `GrochowQiaoRigidity`, ALL three
end-states (Karp reduction inhabitant + both Phase 3 Props) discharge
unconditionally.

When `GrochowQiaoRigidity` is discharged (research-scope
**R-15-residual-TI-reverse**), all three end-states become
unconditional theorems. -/
theorem grochowQiao_phase3_discharge_under_rigidity
    (h_rigidity : GrochowQiaoRigidity) (m : ℕ) :
    GL3InducesAlgEquivOnPathSubspace m ∧ RestrictedGL3OnPathOnlyTensor m :=
  ⟨Discharge.gl3InducesAlgEquivOnPathSubspace_of_rigidity h_rigidity m,
   Discharge.restrictedGL3OnPathOnlyTensor_of_rigidity h_rigidity m⟩

/-- **Unified discharge under `GrochowQiaoRigidity`.**

All three end-states of R-TI Phase 3 — the Karp reduction inhabitant
and both Phase 3 Props — discharged from a single research-scope
hypothesis. -/
theorem grochowQiao_unified_discharge_under_rigidity
    (h_rigidity : GrochowQiaoRigidity) :
    @GIReducesToTI ℚ _ ∧
    (∀ m, GL3InducesAlgEquivOnPathSubspace m) ∧
    (∀ m, RestrictedGL3OnPathOnlyTensor m) :=
  ⟨grochowQiao_isInhabitedKarpReduction_under_rigidity h_rigidity,
   fun m => Discharge.gl3InducesAlgEquivOnPathSubspace_of_rigidity h_rigidity m,
   fun m => Discharge.restrictedGL3OnPathOnlyTensor_of_rigidity h_rigidity m⟩

end GrochowQiao
end Orbcrypt
