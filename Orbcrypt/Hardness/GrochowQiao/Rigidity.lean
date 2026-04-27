/-
Final rigidity composition (Stage 5 / T-API-10, R-TI rigidity discharge).

This module composes the Stage 1–4 infrastructure with Stage 5
T-API-9's adjacency invariance into the consumer-facing rigidity
theorem.  Given the Stage 3 research-scope `Prop`
(`GL3PreservesPartitionCardinalities`) plus an arrow-preservation
hypothesis (which is what the rigidity argument's deep content
provides), the composition delivers
`GrochowQiaoRigidity` (the existing pre-Stage-5 `Prop` from
`Reverse.lean`).

Composition chain:
1. Stage 3 — under `GL3PreservesPartitionCardinalities`:
   GL³ tensor iso → partition-preserving permutation π.
2. Stage 2 — vertex-permutation descent:
   π → σ : Equiv.Perm (Fin m).
3. Stage 5 T-API-9 — adjacency preservation iff:
   σ-induced AlgEquiv preserves arrow support iff σ is graph iso.
4. Compose with `grochowQiao_isInhabitedKarpReduction_under_rigidity`:
   `GrochowQiaoRigidity → @GIReducesToTI ℚ _`.

See `docs/planning/R_TI_PHASE_C_THROUGH_H_PLAN.md` § Stage 5 T-API-10.
-/

import Orbcrypt.Hardness.GrochowQiao.AdjacencyInvariance
import Orbcrypt.Hardness.GrochowQiao.BlockDecomp
import Orbcrypt.Hardness.GrochowQiao.WMSigmaExtraction
import Orbcrypt.Hardness.GrochowQiao.Reverse

/-!
# Final rigidity composition

Public API:

* `vertexPermPreservesAdjacency` — given a vertex permutation
  `σ : Equiv.Perm (Fin m)` and an "arrow-preservation" hypothesis
  (the σ-induced AlgEquiv preserves `presentArrows` between adj₁
  and adj₂), conclude that σ preserves adjacency
  `∀ u v, adj₁ u v = adj₂ (σ u) (σ v)`.
* `grochowQiaoRigidity_under_arrowDischarge` — under
  `GL3PreservesPartitionCardinalities` AND an arrow-preservation
  discharge, every GL³ tensor iso yields a graph iso. This is the
  consumer-facing composition of Stages 1–5.
* `grochowQiao_isInhabitedKarpReduction_full_chain` — final Karp
  reduction inhabitant under the chain.

The arrow-preservation discharge is the genuine GL³ → AlgEquiv content
that Stage 4 sidesteps (research-scope, multi-month). When that lands,
all theorems in this module become unconditional via the chain.

## Naming

Identifiers describe content (`vertexPermPreservesAdjacency`,
`grochowQiaoRigidity_under_arrowDischarge`), not workstream
provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt

-- ============================================================================
-- T-API-10.1 — Adjacency preservation from arrow-preservation hypothesis.
-- ============================================================================

/-- **Adjacency preservation theorem.**

Given a vertex permutation `σ : Equiv.Perm (Fin m)` and the hypothesis
that the σ-induced AlgEquiv preserves the `presentArrows`-support of
basis-element arrows between `(adj₁, adj₂)`, conclude that σ is a
graph isomorphism: `∀ u v, adj₁ u v = adj₂ (σ u) (σ v)`.

This is the **adjacency invariance theorem** that closes the rigidity
argument once the σ-extraction and arrow-preservation are obtained. -/
theorem vertexPermPreservesAdjacency (m : ℕ) (σ : Equiv.Perm (Fin m))
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_arrow : ∀ u v, (.edge u v : QuiverArrow m) ∈ presentArrows m adj₁ ↔
                      (quiverMap m σ (.edge u v)) ∈ presentArrows m adj₂) :
    ∀ u v, adj₁ u v = adj₂ (σ u) (σ v) :=
  (quiverPermAlgEquiv_preserves_presentArrows_iff m σ adj₁ adj₂).mpr h_arrow

-- ============================================================================
-- T-API-10.2 — Final composition under research-scope discharges.
-- ============================================================================

/-- **The arrow-preservation discharge** (research-scope obligation,
parallel to `GL3PreservesPartitionCardinalities`).

States that any GL³ triple `g` with `g • encode₁ = encode₂` not only
preserves the partition cardinalities but also induces a vertex
permutation σ whose σ-action on basis-element arrows preserves the
`presentArrows` support between `(adj₁, adj₂)`.

This is the deep content of the GL³ → AlgEquiv bridge (Stage 4's
research-scope follow-up). Once discharged, combined with Stage 3's
`GL3PreservesPartitionCardinalities`, it delivers the full rigidity
theorem unconditionally. -/
def GL3InducesArrowPreservingPerm : Prop :=
  ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ),
    g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂ →
    ∃ σ : Equiv.Perm (Fin m),
      ∀ u v, (.edge u v : QuiverArrow m) ∈ presentArrows m adj₁ ↔
             (quiverMap m σ (.edge u v)) ∈ presentArrows m adj₂

/-- **Identity case witness** for `GL3InducesArrowPreservingPerm`. -/
theorem gl3_induces_arrow_preserving_perm_identity_case
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    ∃ σ : Equiv.Perm (Fin m),
      ∀ u v, (.edge u v : QuiverArrow m) ∈ presentArrows m adj ↔
             (quiverMap m σ (.edge u v)) ∈ presentArrows m adj :=
  ⟨1, fun u v => by simp [quiverMap_edge]⟩

/-- **`GrochowQiaoRigidity` discharged from the arrow-preservation Prop.**

Under `GL3InducesArrowPreservingPerm`, every GL³ tensor isomorphism
between `(grochowQiaoEncode m adj₁, grochowQiaoEncode m adj₂)`
yields a vertex permutation σ that preserves adjacency.

This is the consumer-facing composition theorem: the Stage 5 T-API-9
adjacency invariance + the research-scope arrow-preservation Prop
together imply `GrochowQiaoRigidity`. -/
theorem grochowQiaoRigidity_under_arrowDischarge
    (h_arrow : GL3InducesArrowPreservingPerm) :
    GrochowQiaoRigidity := by
  intro m adj₁ adj₂ ⟨g, hg⟩
  obtain ⟨σ, h_σ⟩ := h_arrow m adj₁ adj₂ g hg
  exact ⟨σ, vertexPermPreservesAdjacency m σ adj₁ adj₂ h_σ⟩

-- ============================================================================
-- T-API-10.3 — Status disclosure.
--
-- Note: the final Karp reduction inhabitant (composing this Stage 5
-- discharge with `grochowQiao_isInhabitedKarpReduction_under_rigidity`)
-- lives in the top-level `Orbcrypt.Hardness.GrochowQiao` module, since
-- that module imports `Reverse.lean`'s pre-existing `GrochowQiaoRigidity`
-- inhabitant.
-- ============================================================================

/-- **Status disclosure** for the post-Stage-5 R-TI rigidity discharge.

What's unconditional:
* Stage 0 — encoder strengthening (`grochowQiaoEncode_diagonal_padding`).
* Stage 1 T-API-1 — `Tensor3` unfoldings + GL³-action bridges.
* Stage 1 T-API-2 — axis-1 unfolding rank invariance under GL³.
* Stage 2 — slot signature classification + bijection extraction +
  vertex permutation descent.
* Stage 3 — partition-preserving permutation construction *from equal
  cardinalities* (the construction itself is unconditional;
  obtaining the equal cardinalities from GL³ is research-scope).
* Stage 4 T-API-7 — σ-induced AlgEquiv on `pathAlgebraQuotient m`
  (unconditional).
* Stage 4 T-API-8 — Wedderburn–Mal'cev σ-extraction round-trip
  (unconditional).
* Stage 5 T-API-9 — sandwich identity, inner-conjugation fixes
  arrows (J²=0 content), adjacency-iff characterization
  (unconditional).
* Stage 5 T-API-10 — composition theorems
  (`grochowQiaoRigidity_under_arrowDischarge`,
  `grochowQiao_isInhabitedKarpReduction_full_chain`) — unconditional
  *given* the research-scope discharges.

What's research-scope (`R-15-residual-TI-reverse`):
* `GL3PreservesPartitionCardinalities` (Stage 3) — ~80 pages of
  Grochow–Qiao SIAM J. Comp. 2023 §4.3.
* `GL3InducesArrowPreservingPerm` (Stage 5) — the σ-extraction
  with arrow-preservation, requiring the GL³ → AlgEquiv bridge.

Once both Props are discharged, all the conditional theorems above
become unconditional via the composition chain. -/
theorem r_ti_rigidity_status_disclosure :
    -- Identity case for `GL3PreservesPartitionCardinalities`: under
    -- the identity GL³ triple, the present-arrow cardinalities of
    -- adj₁ and adj₂ are equal whenever the encoder values match.
    (∀ m (adj₁ adj₂ : Fin m → Fin m → Bool),
      ((1 : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ ×
         GL (Fin (dimGQ m)) ℚ)) • grochowQiaoEncode m adj₁ =
            grochowQiaoEncode m adj₂ →
      (presentArrowSlotIndices m adj₁).card =
        (presentArrowSlotIndices m adj₂).card) ∧
    -- Identity case for `GL3InducesArrowPreservingPerm`.
    (∀ m adj, ∃ σ : Equiv.Perm (Fin m),
      ∀ u v, (.edge u v : QuiverArrow m) ∈ presentArrows m adj ↔
             (quiverMap m σ (.edge u v)) ∈ presentArrows m adj) := by
  refine ⟨?_, ?_⟩
  · intros m adj₁ adj₂ h
    exact gl3_preserves_partition_cardinalities_identity_case m adj₁ adj₂ h
  · intros m adj
    exact gl3_induces_arrow_preserving_perm_identity_case m adj

end GrochowQiao
end Orbcrypt
