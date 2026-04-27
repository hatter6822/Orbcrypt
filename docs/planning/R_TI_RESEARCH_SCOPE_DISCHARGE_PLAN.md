# R-TI Research-Scope Discharge Plan

**Eliminating `GL3PreservesPartitionCardinalities` and
`GL3InducesArrowPreservingPerm` to deliver unconditional
`grochowQiaoRigidity` and `grochowQiao_isInhabitedKarpReduction`.**

Date: 2026-04-27
Author: post-Stage-5 R-TI rigidity discharge planning
Tracking: research milestone **R-15-residual-TI-reverse**
Status: planned (not yet started)
Revision: v2 (post-expansion + refinement pass, 2026-04-27)

---

## Revision history

* **v1 (initial landing).** 1,788 lines. High-level phase
  decomposition (A–G) with sub-layer breakdowns at the
  T-API-* level. ~6,200 LOC across 11 modules; 23-commit
  cadence; 7-phase structure; risk register; verification
  protocol; mathematical soundness checklist; optimization
  notes; cross-references.
* **v2 (this revision).** ~3,200 lines. **Per-sub-task
  granular decomposition** of the 6 most complex layers:
  - **Phase A T-API-A2** (slab-rank multiset invariance):
    5 sub-tasks (A2.1–A2.5).
  - **Phase B T-API-B2** (joint signature multiset): 4
    sub-tasks (B2.1–B2.4) + formal circularity resolution.
  - **Phase C T-API-C1** (per-slot signatures): 6 sub-tasks
    (C1.1–C1.6) + a mathematical correction (vertex slot
    slab-rank is uniformly 1, not `1 + outDegree(v)`).
  - **Phase D T-API-D1 + D2** (off-diagonal vanishing): 14
    sub-tasks (D1.1–D1.8 + D2.0–D2.5) including the
    mutual-induction packaging at D2.4.
  - **Phase E sub-layer E2.2** (basis multiplicativity): 6
    sub-tasks (E2.2.1–E2.2.6) decomposing the 4-case
    structural argument.
  - **Phase F sub-layers F2.2 + F2.3** (radical conjugation +
    arrow scalar): 8 sub-tasks (F2.2.1–F2.2.3 + F2.3.1–F2.3.5).
  Adds 5 appendices: Notation reference, Sub-task dependency
  graph (with critical-path summary), Per-phase Gantt-style
  timeline (39-week calendar), Deferred-discharge contingency
  planning (3 fall-back scenarios), Audit-script extension
  index. Updates LOC budget from ~6,200 to ~6,700 LOC across
  the 7 phases (the per-sub-task analysis revealed Phases C
  and D need more LOC than originally estimated). Total
  sub-tasks: **66** across 7 phases.

---

## 1. Context

The Grochow–Qiao GI ≤ TI Karp reduction (`@GIReducesToTI ℚ _`) is a
tier-one cryptographic-hardness reduction in Orbcrypt's R-TI
workstream. Stages 0–5 of the prior plan
(`/root/.claude/plans/create-a-detailed-plan-fizzy-planet.md`,
implemented across 10 new modules under
`Orbcrypt/Hardness/GrochowQiao/`) landed all the **structural
content** of the rigidity argument — the encoder strengthening, the
tensor-unfolding API, GL³ rank invariance, slot-classification +
bijection extraction + vertex-permutation descent, the partition-
preserving permutation construction (conditional on equal
cardinalities), the σ-induced AlgEquiv on `pathAlgebraQuotient m`,
the Wedderburn–Mal'cev σ-extraction round-trip, the
adjacency-iff-arrow-preservation characterisation, and the final
composition theorems — all unconditionally, with zero `sorry` and
zero custom axioms.

What remains are **two named research-scope `Prop`s** that capture
the genuinely deep content of Grochow–Qiao SIAM J. Comp. 2023 §4.3:

* **`GL3PreservesPartitionCardinalities`**
  (`Orbcrypt/Hardness/GrochowQiao/BlockDecomp.lean`) — under
  `g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂` for any
  GL³ triple `g`, the present-arrow slot cardinalities of `adj₁`
  and `adj₂` agree.

* **`GL3InducesArrowPreservingPerm`**
  (`Orbcrypt/Hardness/GrochowQiao/Rigidity.lean`) — the same
  hypothesis yields a vertex permutation `σ : Equiv.Perm (Fin m)`
  whose σ-action on basis-element arrows preserves the
  `presentArrows`-support between `(adj₁, adj₂)`.

This plan discharges both unconditionally. **Post-expansion
budget** (the per-sub-task granular analysis revealed Phases C
and D need more LOC than the original high-level estimate): the
total LOC budget is **~6,700 LOC** of new Lean across **11 new
modules**, plus ~500 LOC of documentation refresh and audit-
script extensions, for a grand total of **~7,200 LOC** across
the 7 phases. The dedicated effort estimate is **~6–10 months**
for a single focused implementer.

## 2. Outcome

After all seven phases (A–G) land:

* `theorem gl3_preserves_partition_cardinalities :
    GL3PreservesPartitionCardinalities` — unconditional (Phase C).
* `theorem gl3_induces_arrow_preserving_perm :
    GL3InducesArrowPreservingPerm` — unconditional (Phase G).
* `theorem grochowQiaoRigidity : GrochowQiaoRigidity` —
  unconditional (composes Phase G with Stage 5's
  `grochowQiaoRigidity_under_arrowDischarge`).
* `theorem grochowQiao_isInhabitedKarpReduction :
    @GIReducesToTI ℚ _` — unconditional (composes the above with
  the existing `grochowQiao_isInhabitedKarpReduction_under_rigidity`
  from `Reverse.lean`).
* **Reusable Mathlib-quality infrastructure:**
  - `Tensor3.slabRank₁/₂/₃` + `slabRankSignature` + `slabRankMultiset`
    (3-tensor slab classification, applicable beyond GQ).
  - `slabRankMultiset_smul` (multiset preservation under GL³).
  - `pathBlockSubspace` + `pathBlockBasis` (Mathlib-style basis
    indexing on the path-algebra slot subspace).
  - `gl3OnPathBlock_to_algEquiv` (GL³ block-preserving action →
    `AlgEquiv` on `pathAlgebraQuotient m`).
* Zero `sorry`, zero custom axioms; all 770+ existing
  `#print axioms` checks remain on the standard Lean trio
  (`propext`, `Classical.choice`, `Quot.sound`).
* `lakefile.lean` version bumped from `0.1.21` to `0.1.22` at the
  Phase G landing.
* `CLAUDE.md`, `docs/VERIFICATION_REPORT.md`,
  `Orbcrypt.lean` axiom-transparency report, and
  `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`
  updated to mark R-15-residual-TI-reverse as CLOSED.

## 3. Strategic decomposition

The two `Prop`s are not independent: `GL3InducesArrowPreservingPerm`
**strictly implies** `GL3PreservesPartitionCardinalities` because
σ-action arrow preservation gives a bijection between
`presentArrows m adj₁` and `presentArrows m adj₂`, so cardinalities
agree. A naive plan could therefore prove only Prop 2 and derive
Prop 1 as a corollary.

We reject this approach for two reasons:

1. **Build-graph independence.** Discharging Prop 1 first lets the
   downstream theorems
   (`partitionPreservingPermFromEqualCardinalities`,
   `partition_preserving_perm_under_GL3`) become unconditional
   independently — Phase 4 of the rigidity argument can land months
   ahead of Phase G without blocking on the deep arrow content.

2. **Mathematical decomposition.** Prop 1 follows from a **shallower
   invariant** (slab-rank multiset preservation under GL³) that
   does not require the AlgEquiv → σ → arrow-action chain. Proving
   Prop 1 first lets us validate the slab-rank invariance API on
   its own merits, then build the deeper Prop-2 argument on a
   verified foundation.

The plan therefore proves Prop 1 in **Phases A–C** (slab-rank
multiset invariance + diagonal-value classification), then proves
Prop 2 in **Phases D–G** (path-algebra block extraction → AlgEquiv
→ WM σ-extraction → arrow preservation). Phase G includes the
formal corollary deriving Prop 1 from Prop 2 (a ≤30 LOC
composition), which lets us *also* land Prop 1 unconditionally via
the deeper route — providing redundant verification at the
audit-script level.

## 4. Phase map

| Phase | Layers | Title | LOC (original) | LOC (post-expansion) | Risk |
|-------|--------|-------|----------------|----------------------|------|
| A | T-API-A1, A2 | Slab-rank multiset invariance | ~900 | ~900 | Med |
| B | T-API-B1, B2 | Diagonal-value invariance under GL³ | ~600 | ~600 | Low–Med |
| C | T-API-C1, C2 | Slot-classification rigidity (Prop 1 discharge) | ~700 | ~900 | Low–Med |
| D | T-API-D1, D2, D3 | Path-block extraction + restriction theorem | ~1,400 | ~1,700 | **Research** |
| E | T-API-E1, E2 | AlgEquiv construction from path-block GL³ | ~1,100 | ~1,100 | High |
| F | T-API-F1, F2 | σ extraction + arrow-action analysis | ~900 | ~900 | Med–High |
| G | T-API-G1, G2 | Final discharge + composition (Prop 2) | ~600 | ~600 | Med |
| | | **Total** | **~6,200** | **~6,700** | |

Plus ~500 LOC for documentation refresh, audit-script extensions,
and Vacuity-map / VERIFICATION_REPORT updates across the seven
phases. **The post-expansion LOC growth is concentrated in
Phases C and D**, where the per-sub-task granular budgets
(C1.1–C1.6 and D1.1–D1.8 / D2.0–D2.5) revealed that the
original high-level estimates underestimated the index-management
bookkeeping and the mutual-induction packaging.

**Critical path: Phase D is the genuinely research-grade layer.**
Phases A–C complete the "shallow rigidity" half (Prop 1) on
independent mathematical content; Phases D–G build the AlgEquiv
chain, which is where the genuine novelty lives. Phase D's
block-decomposition argument (lifted from the prior plan's
Stage 3 sub-layers 4.D/4.E in shape, but re-stated here without
the `Prop`-fallback escape hatch) is the highest-risk piece of
the workstream.

## 5. Conventions enforced across all phases

Inherited from CLAUDE.md and the prior R-TI plan:

* **Naming** — identifiers describe content. No `phaseE_*`,
  `tApi7_*`, `propDischarge_*`, `r15_*`. Permitted forms:
  `slabRankMultiset_smul`, `pathBlockSubspace`,
  `gl3OnPathBlock_to_algEquiv`,
  `gl3_preserves_partition_cardinalities`,
  `gl3_induces_arrow_preserving_perm`. Process markers may appear
  in docstrings, never in identifiers.
* **Docstrings** — every public `def`, `theorem`, `structure`,
  `instance`, `abbrev` carries a `/-- ... -/` docstring stating
  the mathematical content, the proof technique, and the
  consumer.
* **`@[simp]` discipline** — reserved for genuine normalisation
  lemmas (apply lemmas on basis elements, identity-action
  reductions). Existential-content theorems are unmarked.
* **No `sorry`, no custom axioms** — every public declaration
  depends only on `propext`, `Classical.choice`, `Quot.sound`.
  Every phase's audit-script extension proves this.
* **Reuse aggressively** — never redefine `Tensor3.unfold₁/₂/₃`,
  `unfoldRank₁`, `tensorRank`, `slotEquiv`,
  `isPathAlgebraSlot`, `vertexSlotIndices`,
  `presentArrowSlotIndices`, `paddingSlotIndices`,
  `pathSlotStructureConstant`, `ambientSlotStructureConstant`,
  `grochowQiaoEncode`, `grochowQiaoEncode_diagonal_*`,
  `grochowQiaoEncode_padding_distinguishable`, `liftedSigma`,
  `liftedSigmaSlot`, `liftedSigmaMatrix`,
  `partitionPreservingPermFromEqualCardinalities`,
  `quiverPermAlgEquiv`, `algEquiv_extractVertexPerm`,
  `wedderburn_malcev_conjugacy`, `pathAlgebraQuotient`,
  `vertexIdempotent`, `arrowElement`, `pathAlgebraRadical`,
  `pathAlgebra_decompose`,
  `vertexIdempotent_completeOrthogonalIdempotents`,
  `AlgEquiv_preserves_completeOrthogonalIdempotents`,
  `arrowElement_sandwich`, `inner_aut_radical_fixes_arrow`,
  `vertexPermPreservesAdjacency`,
  `quiverPermAlgEquiv_preserves_presentArrows_iff`,
  `vertexPermOfVertexPreserving`. The 770-declaration baseline
  established by Stages 0–5 is the reusable surface.
* **Mathlib-idiomatic** — `Matrix.rank`, `Matrix.kroneckerMap`,
  `LinearMap.range`, `Submodule.span`, `Submodule.subtype`,
  `LinearMap.restrict`, `AlgEquiv`, `Equiv.Perm`, `Multiset`,
  `Finset.image`, `Fintype.equivOfCardEq` are the named API
  entry points.
* **Module length cap** — target ≤ 600 LOC per `.lean` file. If
  a sub-layer pushes past this, split into sub-modules
  (e.g., `BlockExtraction/Counts.lean`,
  `BlockExtraction/Restriction.lean`,
  `BlockExtraction/AlgebraStructure.lean`).

---

## Phase A — Slab-rank multiset invariance under GL³ (~900 LOC)

**Goal.** Prove that the multiset of axis-1 unfolding-slab ranks
of a 3-tensor is invariant under the GL³ tensor action. This is
the **shallow rigidity invariant** that drives Phase C's
discharge of Prop 1.

### Layer T-API-A1 — Slab definitions + slab-rank API (~400 LOC)

**File (new):** `Orbcrypt/Hardness/GrochowQiao/SlabRank.lean`.

**Public surface:**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `Tensor3.slab₁` | `Tensor3 n F → Fin n → Matrix (Fin n) (Fin n) F := fun T i j k => T i j k` | Fix axis-1, get a 2-tensor. |
| `Tensor3.slab₂` | symmetric on axis-2 | |
| `Tensor3.slab₃` | symmetric on axis-3 | |
| `Tensor3.slabRank₁ T i : ℕ := (T.slab₁ i).rank` | per-slot axis-1 slab rank | |
| `Tensor3.slabRank₂`, `slabRank₃` | symmetric | |
| `slab₁_unfold₁_row` | `(slab₁ T i) j k = unfold₁ T i (j, k)` | Bridge slab to unfolding row. |
| `slabRank₁_eq_unfold_row_rank` | `slabRank₁ T i = (Matrix.row (Fin (n × n)) (unfold₁ T i)).rank` | Slab rank = single-row matrix rank. |

**Proof technique.**

* `slab₁_unfold₁_row` is `funext + rfl` from the definition of
  `unfold₁` (T-API-1.1 from the prior plan).
* `slabRank₁_eq_unfold_row_rank` uses
  `Matrix.rank_eq_finrank_range_toLin` plus the linear
  identification of `slab₁ T i : Matrix (Fin n) (Fin n) F` with
  the row vector `unfold₁ T i : Fin n × Fin n → F` reshaped via
  `Matrix.curry` / `Matrix.uncurry`.

**Risk.** Low. Pure bookkeeping on top of the existing T-API-1
unfolding bridge.

**Verification gate.** Module builds; `slab₁` evaluation lemmas
fire by `rfl`; `#print axioms slabRank₁` standard trio only.

**Consumer.** Layer T-API-A2.

### Layer T-API-A2 — Slab-rank multiset invariance under GL³ (~500 LOC)

**File (new):** `Orbcrypt/Hardness/GrochowQiao/SlabRankInvariance.lean`.

**Public surface:**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `Tensor3.slabRankMultiset₁ T : Multiset ℕ := (Finset.univ : Finset (Fin n)).val.map (slabRank₁ T)` | Multiset of axis-1 slab ranks. |
| `slabRankMultiset₂`, `slabRankMultiset₃` | symmetric | |
| `slabRankMultiset₁_smul` | `∀ g : GL n F × GL n F × GL n F, slabRankMultiset₁ (g • T) = slabRankMultiset₁ T` | The multiset is GL³-invariant. |
| `slabRankMultiset₂_smul`, `slabRankMultiset₃_smul` | symmetric | |
| `slabRankMultiset_areTensorIsomorphic` | `AreTensorIsomorphic T₁ T₂ → slabRankMultiset₁ T₁ = slabRankMultiset₁ T₂` | Direct corollary. |

**Mathematical content for `slabRankMultiset₁_smul`.**

Let `g = (g₁, g₂, g₃) : GL n F × GL n F × GL n F`. From
`unfold₁_tensorContract`,
```
unfold₁ (g • T) = g₁.val * unfold₁ T * (g₂.valᵀ ⊗ₖ g₃.valᵀ)
```

Each *row* of `unfold₁ (g • T)` is therefore a linear combination
of rows of `unfold₁ T * (g₂.valᵀ ⊗ₖ g₃.valᵀ)`, weighted by the
entries of the corresponding row of `g₁.val`. Specifically:
```
unfold₁ (g • T) i = ∑_a g₁.val i a • (unfold₁ T a * (g₂.valᵀ ⊗ₖ g₃.valᵀ))
```
where `unfold₁ T a` is the `a`-th row, viewed as a row matrix.

The slab `slab₁ (g • T) i` (a `Matrix (Fin n) (Fin n) F`) is
therefore the linear combination of `slab₁ T a * (g₂.valᵀ ⊗ₖ
g₃.valᵀ)`-style 2-tensor expressions, with coefficients from
`g₁.val i`. After identifying via the unfolding-row equivalence
(layer A1), the slab rank
```
slabRank₁ (g • T) i = (∑_a g₁.val i a • slab₁ T a · ...).rank
```

Direct slab-by-slab GL³-invariance fails because `g₁` mixes slabs.
However:

* The map `a ↦ slab₁ (g • T) (g₁⁻¹.val a)` is a row-equivalence
  bijection (because `g₁` is invertible). Applied to the multiset,
  it shows
  ```
  slabRankMultiset₁ (g • T)
    = (Finset.univ).val.map (fun i => slabRank₁ (g • T) i)
    = (Finset.univ).val.map (fun a => slabRank₁ (g • T) (g₁⁻¹.val a))   -- relabel
    = (Finset.univ).val.map (fun a => slabRank₁ T a)                    -- (*)
    = slabRankMultiset₁ T
  ```
  where `(*)` is the per-slab rank identity that needs proof.

* **Per-slab rank identity** (the technical core):
  `slabRank₁ (g • T) (g₁⁻¹.val a) = slabRank₁ T a`. This holds
  because the `a`-th row of `g₁ * unfold₁ T` is
  `(g₁.val (g₁⁻¹.val a) , unfold₁ T -)`, where the inner product
  collapses (via `g₁ * g₁⁻¹ = 1`) to exactly `unfold₁ T a` —
  modulo an invertible right multiplication by the Kronecker
  factor `(g₂.valᵀ ⊗ₖ g₃.valᵀ)`. **Right multiplication by an
  invertible matrix preserves rank** (T-API-2 / RankInvariance.lean
  toolkit, post-Stage-1).

**Detailed sub-task breakdown.**

The argument decomposes into **5 named sub-tasks** with explicit
LOC budgets, Mathlib anchors, and dependencies. Each sub-task
lands as its own commit so reviewers can audit incrementally.

#### Sub-task A2.1 — Row-equation lemma (~40 LOC, 0 deps)

* **Statement.** `unfold₁_smul_row_eq`:
  ```
  ∀ (g : GL n F × GL n F × GL n F) (T : Tensor3 n F) (i : Fin n),
    (unfold₁ (g • T)) i = (g.1.val * (unfold₁ T)) i *
                          (g.2.valᵀ ⊗ₖ g.3.valᵀ)
  ```
  (where the right-hand side reads as a row vector;
  `Matrix.row_apply` reshapes implicitly.)
* **Proof.** Direct from Stage 1's `unfold₁_tensorContract`
  + `Matrix.mul_apply` row-extraction. ≤ 5-line tactic body.
* **Mathlib anchors.** `unfold₁_tensorContract` (Stage 1 /
  TensorUnfold.lean), `Matrix.mul_apply`.
* **Risk.** Low.
* **Verification gate.** `#print axioms unfold₁_smul_row_eq`
  standard trio only.

#### Sub-task A2.2 — Slab transformation under GL × GL × GL (~120 LOC, depends on A2.1)

* **Statement.** `slab_smul_eq_double_conjugation`:
  ```
  ∀ (g : GL n F × GL n F × GL n F) (T : Tensor3 n F) (a : Fin n),
    slab₁ (g • T) ((g.1⁻¹).val.toMatrix a) =
      g.2.val * slab₁ T a * g.3.valᵀ
  ```
  *(In words: at the row-index `(g.1⁻¹) a`, the slab of `g • T`
  equals the slab of `T` at index `a`, conjugated by `g.2` on
  the left and `g.3.valᵀ` on the right.)*
* **Proof outline.**
  1. By A2.1 expanded at `i = (g.1⁻¹).val a₀`:
     `(unfold₁ (g • T)) ((g.1⁻¹).val a₀) (j, k) =
        ∑_a (g.1.val * 1) ((g.1⁻¹).val a₀, a) * (unfold₁ T a) ⋅
        Kronecker action`.
     The factor `(g.1.val * g.1⁻¹.val) (a₀, a) = δ_{a₀, a}`
     collapses the sum to a single term.
  2. The right-multiplication by `(g.2.valᵀ ⊗ₖ g.3.valᵀ)` on
     the row reshapes via the unfolding bridge to
     `g.2.val * slab₁ T a * g.3.valᵀ`. Standard Kronecker
     identity:
     `(unfold₁ T a * (Bᵀ ⊗ₖ Cᵀ)) (j, k) = (B * slab₁ T a * Cᵀ) j k`.
* **Sub-lemmas (each ≤ 60 LOC):**
  - `gl_inv_mul_id`: `(g.1.val * (g.1⁻¹).val) = 1`. Mathlib
    one-liner via `Matrix.GeneralLinearGroup.coe_inv` +
    `Units.mul_inv`.
  - `unfold₁_at_inverse_collapse`: the δ-substitution.
  - `slab_kronecker_reshape`: `(unfold₁ T a * (Bᵀ ⊗ₖ Cᵀ))`
    reshaped as a slab equals `B * slab₁ T a * Cᵀ`. Pure
    Kronecker arithmetic via `Matrix.kronecker_apply`.
* **Mathlib anchors.** `Matrix.GeneralLinearGroup.coe_inv`,
  `Matrix.one_apply`, `Matrix.kronecker_apply`,
  `Matrix.mul_apply`, `Finset.sum_eq_single` (3-arg form).
* **Risk.** Medium. The δ-collapse + Kronecker reshape is the
  technical core. ≤ 30-line tactic body per sub-lemma.
* **Verification gate.** Both directions of the slab
  transformation evaluate via `decide` on `n = 2` identity GL³.

#### Sub-task A2.3 — Slab rank under double conjugation (~100 LOC, depends on A2.2)

* **Statement.** `slabRank₁_smul_eq_at_inv_index`:
  ```
  ∀ (g : GL n F × GL n F × GL n F) (T : Tensor3 n F) (a : Fin n),
    slabRank₁ (g • T) ((g.1⁻¹).val a) = slabRank₁ T a
  ```
* **Proof.** Apply A2.2 to express the LHS slab as
  `g.2.val * slab₁ T a * g.3.valᵀ`. Take rank of both sides:
  - Left multiplication by `g.2.val` (invertible determinant):
    `Matrix.rank_mul_eq_right_of_isUnit_det`.
  - Right multiplication by `g.3.valᵀ` (invertible: transpose
    of a unit determinant matrix is also a unit):
    `Matrix.rank_mul_eq_left_of_isUnit_det` +
    `Matrix.det_transpose`.
  Conclude the LHS rank equals the rank of `slab₁ T a`.
* **Sub-lemmas (each ≤ 40 LOC):**
  - `transpose_isUnit_det`: `IsUnit g.val.det → IsUnit
    (g.val.transpose.det)`. Direct from
    `Matrix.det_transpose`.
  - The two rank-invariance applications.
* **Mathlib anchors.** `Matrix.rank_mul_eq_left_of_isUnit_det`
  (Rank.lean:205), `Matrix.rank_mul_eq_right_of_isUnit_det`
  (Rank.lean:216), `Matrix.det_transpose`.
* **Risk.** Low. Pure Mathlib composition.
* **Verification gate.** Identity-case (`g = 1`) collapses to
  `slabRank₁ T a = slabRank₁ T a`, exhibited as a non-vacuity
  example.

#### Sub-task A2.4 — Multiset bijection via `g.1⁻¹` (~140 LOC, depends on A2.3)

* **Statement.** `slabRankMultiset₁_smul`:
  ```
  ∀ (g : GL n F × GL n F × GL n F) (T : Tensor3 n F),
    slabRankMultiset₁ (g • T) = slabRankMultiset₁ T
  ```
* **Proof outline.**
  1. By definition,
     `slabRankMultiset₁ (g • T) = (Finset.univ.val).map
                                    (fun i => slabRank₁ (g • T) i)`.
  2. **Relabel via the bijection `(g.1⁻¹).val.toEquiv`:**
     - `(g.1⁻¹).val.toEquiv : Fin n ≃ Fin n` is the GL element's
       induced permutation on the row index (Mathlib
       `Matrix.GeneralLinearGroup`).
     - `Finset.univ.val.map f = Finset.univ.val.map (f ∘ σ)` for
       any bijection `σ : Fin n ≃ Fin n` — this is
       `Multiset.map_eq_map_iff_of_inj` applied to a Finset's
       `.val` (after pre-composition with σ as a bijection).
  3. After relabelling, the map's argument is
     `fun a => slabRank₁ (g • T) ((g.1⁻¹).val a)`.
  4. By A2.3, this equals `fun a => slabRank₁ T a`, which is the
     definition of `slabRankMultiset₁ T`.
* **Sub-lemmas (each ≤ 50 LOC):**
  - `Multiset.map_relabel_finset_univ`: `(Finset.univ : Finset
    α).val.map f = (Finset.univ : Finset α).val.map (f ∘ σ)` for
    any `σ : α ≃ α` and `[Fintype α]`. Provable from
    `Equiv.Perm.image_univ` + `Multiset.map_congr` or directly
    from `Multiset.map_eq_map_iff_of_inj`.
  - `slabRankMultiset_smul_via_inv_relabel` — apply the
    relabelling at `σ := (g.1⁻¹).val.toEquiv` and chain with
    A2.3.
* **Mathlib anchors.** `Multiset.map_eq_map_iff_of_inj`,
  `Equiv.Perm.image_univ`, `Multiset.map_congr`,
  `Matrix.GeneralLinearGroup`'s `toEquiv` projection (or
  hand-roll if absent — see the gap analysis below).
* **Risk.** Medium. The Multiset bijection arithmetic uses
  Mathlib idioms that may need verification at `fa6418a8`. ~30
  LOC reserve for hand-rolling `Matrix.GeneralLinearGroup`-to-
  `Equiv.Perm` if `toEquiv` is absent at the pinned commit.
* **Verification gate.** `#print axioms slabRankMultiset₁_smul`
  standard trio only; non-vacuity at `n = 2` exhibiting the
  multiset on a concrete GL³ triple.

#### Sub-task A2.5 — Symmetric variants for axes 2, 3 + corollary (~100 LOC, depends on A2.4)

* **Statement.**
  - `slabRankMultiset₂_smul`: symmetric to A2.4 on axis-2.
  - `slabRankMultiset₃_smul`: symmetric on axis-3.
  - `slabRankMultiset_areTensorIsomorphic` (the `Iff.rfl`-ish
    corollary).
* **Proof.** Pattern-matched from A2.4 by replacing `unfold₁`
  with `unfold₂` / `unfold₃`. **Pre-requisite (sub-task A2.5.0,
  ~40 LOC):** Stage 1's `unfold₂_tensorContract` and
  `unfold₃_tensorContract` (research-scope per Stage 1's
  documentation note) must land first. Pattern-matched from
  Stage 1's `unfold₁_tensorContract` proof; budgeted within
  this phase.
* **Risk.** Low (post-A2.5.0).

**Mathlib API gap forecast.** The most likely gap is
`Matrix.GeneralLinearGroup`'s `toEquiv` projection at the pinned
commit `fa6418a8`. If absent, hand-roll via `Equiv.ofBijective`
applied to the `Matrix.toLin'` bijection. ~50 LOC reserve.

**Risk (overall T-API-A2).** Medium. The 5-sub-task decomposition
turns ~500 LOC into pieces of ≤ 140 LOC each. The deepest single
sub-task is A2.4 (Multiset bijection), bounded at ~140 LOC.

**Verification gate.** Module builds; `slabRankMultiset₁_smul`
proven for all `n`; `#print axioms slabRankMultiset₁_smul`
standard trio only; non-vacuity at `n = 2` exhibiting
`slabRankMultiset₁ (g • grochowQiaoEncode 1 (fun _ _ => false))`
under a hand-rolled `g`.

**Consumer.** Phase C (Prop 1 discharge) and Phase D (block
extraction).

### Phase A deliverables and gates

* Two new `.lean` modules under `Orbcrypt/Hardness/GrochowQiao/`.
* `Orbcrypt.lean` extended with two new imports.
* `scripts/audit_phase_16.lean` extended with `#print axioms` for
  every new public declaration plus a non-vacuity `example` per
  layer.
* CLAUDE.md change-log entry under "Workstream R-TI rigidity
  discharge" — new "Phase A" subsection.
* Verification: `lake build` succeeds; audit script clean; full
  Mathlib trio compliance.

---

## Phase B — Diagonal-value invariance under GL³ (~600 LOC)

**Goal.** Prove that the multiset of triple-diagonal values
`{T(i, i, i) : i}` of a 3-tensor is invariant under the GL³
tensor action (when the encoder's diagonal carries the
distinguished post-Stage-0 values). This is the **second shallow
rigidity invariant** that Phase C combines with Phase A's
slab-rank multiset to discharge Prop 1.

### Layer T-API-B1 — Diagonal multiset definition + permutation invariance (~200 LOC)

**File (new):** `Orbcrypt/Hardness/GrochowQiao/DiagonalValues.lean`.

**Public surface:**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `Tensor3.diagonal T : Fin n → F := fun i => T i i i` | The triple-diagonal as a function. |
| `Tensor3.diagonalMultiset T : Multiset F` | The multiset of diagonal values. |
| `diagonal_eq_iff_permutationLifted` | `T₂ = (P • T₁ where P diagonal-permutation matrix triple) ↔ ∃ σ, ∀ i, T₂.diagonal i = T₁.diagonal (σ⁻¹ i)` | Diagonal under permutation-matrix GL³ action equals σ-relabelled diagonal. |
| `diagonalMultiset_under_permutation` | `T₂ = (liftedSigmaGL m σ)³ • T₁ → T₂.diagonalMultiset = T₁.diagonalMultiset` | Direct corollary. |

**Proof technique.**

* The functional `diagonal_eq_iff_permutationLifted` requires
  expanding `tensorContract A B C T` at `(i, i, i)` for `A = B = C
  := liftedSigmaMatrix`. From the existing
  `tensorContract_permMatrix_triple` (Stage 1 / Phase B of the
  prior plan, in `PermMatrix.lean`), each component evaluates as a
  permutation-matrix delta, and the triple sum collapses to a
  single non-zero entry at `(σ⁻¹ i, σ⁻¹ i, σ⁻¹ i)`.

* `diagonalMultiset_under_permutation` follows by `Multiset.map`
  bijectivity through σ.

**Risk.** Low.

**Verification gate.** Module builds; `diagonal_eq_iff_*` proven;
non-vacuity examples on `n = 3` exhibiting σ-rotation of the
diagonal.

**Consumer.** Layer T-API-B2.

### Layer T-API-B2 — Full GL³ diagonal multiset invariance (~400 LOC)

**Public surface:**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `diagonalMultiset_smul` | `∀ g : GL n F × GL n F × GL n F, (g • T).diagonalMultiset = T.diagonalMultiset` | The diagonal multiset is GL³-invariant. |

**Mathematical content.**

This is **strictly harder than Phase A** because diagonal entries
are NOT invariant under arbitrary GL³ actions in general. The
invariance holds **only when the tensor has the distinguished
diagonal-value structure** of `grochowQiaoEncode` (post-Stage-0):
each diagonal value comes from the structure tensor's piecewise
definition, with three exact values `{1, 0, 2}`.

The argument therefore proceeds:

1. **Diagonal entries determine slot kind (post-Stage-0).** From
   `encoder_diagonal_values_pairwise_distinct` (Stage 2), each
   slot's diagonal value uniquely identifies the slot kind
   (vertex / present-arrow / padding). Hence the diagonal
   multiset is the multiset
   `m × {1} + |E| × {0} + (m² - |E|) × {2}`.

2. **GL³ action preserves total tensor structure.** From
   `g • encode m adj₁ = encode m adj₂` and `unfold₁_tensorContract`
   plus the multilinear-algebra structure, the encoder's
   piecewise structure is preserved up to the GL³-induced row /
   column relabelling.

3. **Per-slot-kind cardinality preservation (the hard part).** The
   number of `1`-valued, `0`-valued, and `2`-valued diagonal
   entries must agree between `T₁ = encode m adj₁` and `T₂ =
   encode m adj₂`. This is what we *want* to prove (it gives Prop
   1 directly), but it is also what makes the diagonal multiset
   invariant — circular if stated naively.

**Resolution.** Phase B's `diagonalMultiset_smul` is **not
unconditional for arbitrary tensors** — it is unconditional **only
when restricted to the encoder's distinguished diagonal
structure**. The correct headline is therefore:

| Declaration | Signature | Role |
|-------------|-----------|------|
| `grochowQiaoEncode_diagonalMultiset_smul` | `g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂ → (grochowQiaoEncode m adj₂).diagonalMultiset = (grochowQiaoEncode m adj₁).diagonalMultiset` | Diagonal multiset of the encoder is GL³-invariant in the encoder family. |

This **does** follow unconditionally, by combining:

* The slab-rank multiset invariance (Phase A's
  `slabRankMultiset₁_smul`).
* A pairing argument: each slot's `(slabRank₁, diagonalValue)`
  pair is determined by the encoder's per-slot evaluation
  (Stage 2 + Stage 0). Specifically (post-C1.1 correction —
  see Phase C below), vertex slots have signature `(1, 1)`,
  present-arrow slots `(2, 0)`, padding slots `(1, 2)`. The
  slab-rank multiset alone does not distinguish vertex slots
  (rank 1) from padding slots (rank 1) — the **diagonal-value
  component** distinguishes them (vertex value 1 vs padding
  value 2). The diagonal-value multiset alone does not
  distinguish vertex from padding either (since both have
  scalar values vs. present-arrow's value 0); the slab-rank
  component distinguishes present-arrow (rank 2) from
  vertex/padding (rank 1). **Together** they form a refined
  multiset that *is* preserved under GL³ for the encoder
  family.

**Resolving the circularity formally.**

The "circularity" concern in step 3 above is only superficial.
The diagonal-value multiset of `g • T` is **not** identical to
`T`'s diagonal multiset for arbitrary tensors `T`, but it **is**
preserved when `T` is itself an encoder image (i.e., `T = encode m
adj`). The reason is that the encoder's diagonal entries are a
*by-product* of its piecewise structure, which is preserved under
GL³ relabelling. We exploit this by **pairing diagonal values with
slab ranks at the same slot index** — the pair `(slabRank₁, T(i,
i, i))` is a finer invariant that determines slot kind exactly,
and its multiset is GL³-invariant by composition with Phase A.

**Detailed sub-task breakdown.**

#### Sub-task B2.1 — Joint signature definition (~50 LOC, 0 deps)

* **Definitions.**
  - `slabDiagonalSignature (T : Tensor3 n F) (i : Fin n) : ℕ × F :=
       (slabRank₁ T i, T.diagonal i)`
  - `slabDiagonalSignatureMultiset (T : Tensor3 n F) : Multiset
       (ℕ × F) := (Finset.univ : Finset (Fin n)).val.map
       (slabDiagonalSignature T)`
* **Apply lemmas (`@[simp]`).**
  - `slabDiagonalSignature_apply`,
  - `slabDiagonalSignatureMultiset_apply`,
  - `slabDiagonalSignatureMultiset_count` (via
    `Multiset.count_eq_card_filter`).
* **Risk.** Low. Pure bookkeeping.

#### Sub-task B2.2 — Joint multiset relabelling under GL × GL × GL (~150 LOC, depends on Phase A + B2.1)

* **Statement.** `slabDiagonalSignatureMultiset_smul`:
  ```
  ∀ (g : GL n F × GL n F × GL n F) (T : Tensor3 n F),
    g • T arbitrary →
    slabDiagonalSignatureMultiset (g • T) =
      (Finset.univ.val).map
        (fun a => ((g.2.val * slab₁ T a * g.3.valᵀ).rank,
                   T.diagonal a))
  ```
  *(In words: the joint multiset of `g • T` is reachable from
  `T`'s slabs via the same `(g.1⁻¹)`-relabelling as Phase A,
  with the slab-rank component picking up the
  `g.2 * - * g.3.valᵀ` conjugation, but the diagonal-value
  component evaluated **at the original index `a`**, not at the
  conjugated index.)*
* **Proof.** Apply Phase A's A2.2 (`slab_smul_eq_double_conjugation`)
  to the slab-rank component and re-inspect the diagonal-value
  component:
  - The diagonal entry of `g • T` at `(g.1⁻¹).val a` is
    `(g • T)((g.1⁻¹) a, (g.1⁻¹) a, (g.1⁻¹) a)`. Expanding via
    `tensorContract` at the triple-diagonal entry:
    ```
    (g • T)(i, i, i) = ∑_{a, b, c} g.1.val i a · g.2.val i b ·
                                     g.3.val i c · T(a, b, c)
    ```
    This **does not** simplify to `T(a, a, a)` for general `T`
    — there is no reason the off-diagonal entries `T(a, b, c)`
    with `a ≠ b ∨ b ≠ c` should vanish.
  - **Key insight: encoder diagonal entries are determined by
    slab-1 row support.** For the encoder
    `T = grochowQiaoEncode m adj`, the diagonal entry `T(i, i,
    i)` is determined by `i`'s slot kind via
    `encoder_diagonal_values_pairwise_distinct` (Stage 2). A
    GL³-equivariant pulled-back encoder must have the same
    diagonal-vs-slot-kind correspondence, by the slot-kind
    discrimination from joint slab-rank (which is GL³-
    invariant by Phase A) plus the encoder's piecewise
    structure.
* **Sub-lemmas (each ≤ 50 LOC):**
  - `tensorContract_diagonal_entry_unfold`: explicit form of
    `(g • T)(i, i, i)` via the `tensorContract` definition.
  - `encoder_diagonal_index_to_slot_kind`: for the encoder,
    `T(i, i, i)`'s value forces a unique slot-kind for `i`.
  - **Key bridge lemma**:
    `gl3_acted_encoder_diagonal_at_inv_index_eq_T_diagonal`
    — for `T = encode m adj₁` and `g • T = encode m adj₂`,
    `(g • T).diagonal ((g.1⁻¹) a) = T.diagonal a`. *Proof
    idea*: combine the slab-rank invariance (Phase A) with
    the encoder diagonal-value table (Stage 2 +
    Stage 0), via the slot-kind correspondence.
* **Risk.** Medium-High. The bridge lemma is the technical
  content; ~80 LOC reserve for the slot-kind correspondence
  argument.

#### Sub-task B2.3 — Encoder-family joint-multiset invariance (~150 LOC, depends on B2.2)

* **Statement.**
  `grochowQiaoEncode_slabDiagonalSignatureMultiset_smul`:
  ```
  ∀ (g) (m) (adj₁ adj₂),
    g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂ →
    slabDiagonalSignatureMultiset (grochowQiaoEncode m adj₂) =
    slabDiagonalSignatureMultiset (grochowQiaoEncode m adj₁)
  ```
* **Proof.** Compose Phase A's `slabRankMultiset₁_smul` with B2.2:
  - The slab-rank component is invariant via A2.4.
  - The diagonal-value component is invariant via the bridge
    lemma at B2.2.
  - The joint pair (rank, value) is invariant because both
    components are evaluated at the **same** index `a` (after
    `(g.1⁻¹)`-relabelling on the LHS and identity on the RHS).
* **Sub-lemmas (each ≤ 60 LOC):**
  - `joint_signature_relabel_eq` — under the `(g.1⁻¹)`-
    relabelling, the joint signatures match component-wise.
  - `Multiset.map_relabel_finset_univ_with_inverse` —
    Multiset.map relabel via `(g.1⁻¹)` (similar to A2.4's
    sub-lemma but for the joint signature function).
* **Risk.** Medium. Composition of A2.4 with B2.2.

#### Sub-task B2.4 — Diagonal-value multiset corollary (~50 LOC, depends on B2.3)

* **Statement.** `grochowQiaoEncode_diagonalMultiset_smul`:
  ```
  g • encode m adj₁ = encode m adj₂ →
  (encode m adj₂).diagonalMultiset = (encode m adj₁).diagonalMultiset
  ```
* **Proof.** Project the joint multiset to its second
  component via `Multiset.map Prod.snd`. The composition
  `Multiset.map Prod.snd ∘ slabDiagonalSignatureMultiset =
  diagonalMultiset` (definitional after a `@[simp]` apply
  lemma). Apply B2.3 + Multiset functoriality.
* **Risk.** Low. Pure projection.

**Note on circularity.** The argument is non-circular because:

1. Phase A's `slabRankMultiset₁_smul` is established **without
   reference to** the diagonal-value multiset.
2. The bridge lemma (B2.2 sub-lemma) uses Phase A's slab-rank
   invariance + the encoder's piecewise structure. It does NOT
   use the conclusion `(encode m adj₂).diagonalMultiset =
   (encode m adj₁).diagonalMultiset`.
3. The joint multiset's invariance (B2.3) is established as a
   theorem, from which the diagonal-value multiset corollary
   (B2.4) follows by Multiset functoriality.

This linearisation shows the circularity is only apparent: at no
point do we invoke step 3's conclusion to prove step 3's
hypothesis. The chain is `A2.4 → B2.2 → B2.3 → B2.4`, with each
arrow a strict logical dependency.

**Mathlib anchors.** `Multiset.map`, `Multiset.count`,
`Multiset.count_eq_card_filter`,
`Multiset.map_eq_map_iff_of_inj`, `Multiset.map_map` (for B2.4
corollary). Combined with the Phase A toolkit.

**Verification gate.** Module builds;
`grochowQiaoEncode_diagonalMultiset_smul` (or the joint-signature
form) proven; non-vacuity at `m = 2` (`adj` empty) exhibiting
the signature multiset is `{(1, 1) × 2, (1, 2) × 4}` —
two vertex slots and four padding slots, no present arrows.

**Consumer.** Phase C (Prop 1 discharge).

### Phase B deliverables and gates

* One new `.lean` module under `Orbcrypt/Hardness/GrochowQiao/`.
* `Orbcrypt.lean` extended with one new import.
* `scripts/audit_phase_16.lean` extended with `#print axioms` for
  every new public declaration; non-vacuity `example` exhibiting
  the joint signature multiset on a concrete encoder.
* CLAUDE.md change-log entry: "Phase B" subsection.
* Verification: `lake build` succeeds; audit script clean.

---

## Phase C — Slot-classification rigidity (Prop 1 discharge, ~900 LOC post-expansion)

**Goal.** Discharge `GL3PreservesPartitionCardinalities` from
Phase A and Phase B. This is the **first headline theorem** of
the workstream: it eliminates one of the two research-scope
`Prop`s and lets `partitionPreservingPermFromEqualCardinalities`
(Stage 3 of the prior plan) become unconditional.

### Layer T-API-C1 — Slot-kind cardinalities from joint multiset (~600 LOC, post-expansion)

**File (new):** `Orbcrypt/Hardness/GrochowQiao/SlotCardinality.lean`.

**Public surface (post-C1.1 correction):**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `vertexSlotSignature : ℕ × ℚ := (1, 1)` | Joint signature of a vertex slot (rank 1, diagonal 1). |
| `presentArrowSlotSignature : ℕ × ℚ := (2, 0)` | Joint signature of a present-arrow slot. |
| `paddingSlotSignature : ℕ × ℚ := (1, 2)` | Joint signature of a padding slot. |
| `grochowQiaoEncode_slabDiagonal_at_vertex` | `slabDiagonalSignature (encode m adj) (slotEquiv.symm (.vertex v)) = vertexSlotSignature` | Per-slot computation. |
| `grochowQiaoEncode_slabDiagonal_at_presentArrow`, `_at_padding` | symmetric | |
| `grochowQiaoEncode_slabDiagonalSignatureMultiset` | Explicit form of the multiset for the encoder. |
| `grochowQiao_present_arrow_count_eq_via_signature_multiset` | `g • encode m adj₁ = encode m adj₂ → (presentArrowSlotIndices m adj₁).card = (presentArrowSlotIndices m adj₂).card` | The Phase 1 discharge claim. |

**Mathematical content.**

The joint signature multiset is structurally informative
(post-C1.1 correction):

* `m` copies of `(1, 1)` (vertex signature, uniform — no
  per-vertex variation).
* `|presentArrows m adj|` copies of `(2, 0)` (present-arrow
  signature).
* `m² - |presentArrows m adj|` copies of `(1, 2)` (padding
  signature).

By Phase B's `slabDiagonalSignatureMultiset_smul`, this multiset
is preserved under any GL³ tensor isomorphism between
`(encode m adj₁, encode m adj₂)`. Hence:

* The number of `(2, 0)`-signature slots is preserved →
  `|presentArrows m adj₁| = |presentArrows m adj₂|`.

**Detailed sub-task breakdown.**

#### Sub-task C1.1 — Slab evaluation at vertex slots (~120 LOC, depends on Stage 2)

* **Statement.** `grochowQiaoEncode_slab₁_at_vertex`:
  for `i = slotEquiv.symm (.vertex v)`,
  ```
  slab₁ (grochowQiaoEncode m adj) i j k = 1
    ↔ (j = i ∧ k = i)
  ```
  *(slab is non-zero **only at the triple-diagonal**, with
  value 1 there).*
* **Derivation.** The encoder's slab `T(i, j, k)` at fixed
  `i = vertex v` returns 1 iff `pathMul m (slotToArrow j)
  (slotToArrow k) = some (slotToArrow i) = some (.id v)` (the
  encoder's `pathSlotStructureConstant` definition). Per
  Layer 1 of `AlgebraWrapper.lean`, the `pathMul` case
  classification at **output `some (.id v)`** is:
  - `pathMul (.id v) (.id v) = some (.id v)` ✓ (idempotent
    law — fires).
  - `pathMul (.id u) (.id v) = none` for `u ≠ v` (orthogonal
    idempotents).
  - `pathMul (.id u) (.edge u' v') = some (.edge u' v')` if
    `u = u'` (vertex-times-arrow yields the arrow, NOT `.id v`).
  - `pathMul (.edge u' v') (.id v) = some (.edge u' v')` if
    `v = v'` (arrow-times-vertex yields the arrow, NOT `.id v`).
  - `pathMul (.edge _ _) (.edge _ _) = none` (J² = 0 in
    radical-2 quotient).
  Only the first case yields output `some (.id v)`, so the
  slab is non-zero **only** at `(j, k) = (vertex v, vertex
  v)`, with value 1.
* **Slab-rank consequence.** `slabRank₁ (encode m adj)
  (vertex v) = 1` for **every** vertex `v`, regardless of
  in/out-degree (the slab matrix has a single non-zero entry
  at the diagonal).
* **Sub-lemmas (each ≤ 60 LOC):**
  - `pathMul_output_id_classification`: complete `pathMul`
    case table for outputs of the form `some (.id v)`.
  - `slab₁_encoder_at_vertex_apply`: the slab evaluation as
    above (case-split via `slotEquiv` apply lemma).
  - `slabRank₁_at_vertexSlot`: the slab is rank-1 (single
    non-zero entry).
* **Risk.** Low (post-derivation correction).

> **Important correction to the prior plan's Stage 2 narrative.**
> The Stage 2 plan documented vertex-slot slab-rank as `1 +
> outDegree(v)` based on a slab-axis-2 / row-vs-column confusion.
> The correct slab-axis-1 vertex-slot slab-rank is **1**
> (uniformly), because the encoder's structure constant
> `pathSlotStructureConstant i j k = 1[pathMul (slotToArrow j)
> (slotToArrow k) = some (slotToArrow i)]` only fires when
> the slot triple `(i, j, k)` matches a path-multiplication
> identity, and at vertex-target slot `i` only the
> idempotent-self-loop produces a structure constant of 1.
> The corrected vertex-slot signature is therefore `(1, 1)`
> (slab-rank 1, diagonal value 1), and the C1 framework
> distinguishes vertex slots from padding slots **purely by
> the diagonal-value component** (vertex = 1, padding = 2),
> not by slab rank. **Phase B's joint multiset framework is
> still required** because slab-rank distinguishes
> present-arrow slots (rank 2) from vertex / padding slots
> (rank 1).

#### Sub-task C1.2 — Slab evaluation at present-arrow slots (~120 LOC, depends on Stage 2)

* **Statement.** `grochowQiaoEncode_slab₁_at_presentArrow`:
  for `(u, v)` with `adj u v = true`, the slab at `i =
  slotEquiv.symm (.arrow u v)` is non-zero at exactly two
  entries:
  - `(j, k) = (vertex u, arrow u v)` with value 1: from
    `pathMul (.id u) (.edge u v) = some (.edge u v)`.
  - `(j, k) = (arrow u v, vertex v)` with value 1: from
    `pathMul (.edge u v) (.id v) = some (.edge u v)`.
* **slab-rank consequence.** `slabRank₁ (encode m adj)
  (presentArrow u v) = 2`. *Proof*: the slab matrix is
  ```
  ⎛ ...    1  ... ⎞   <- row `vertex u`, col `arrow u v` = 1
  ⎜ ...    .  ... ⎟
  ⎜ ...    .  ... ⎟
  ⎝ ...    1  ... ⎠   <- row `arrow u v`, col `vertex v` = 1
  ```
  with all other entries zero. The two non-zero rows are
  linearly independent (they have different non-zero columns
  in the rank-2 framework). Hence rank 2.
* **Sub-lemmas (each ≤ 60 LOC):**
  - `pathMul_output_edge_classification`: complete `pathMul`
    case table for outputs of the form `some (.edge u v)`.
  - `slab₁_encoder_at_presentArrow_apply`.
  - `slabRank₁_at_presentArrowSlot_eq_2`.
* **Risk.** Low.

#### Sub-task C1.3 — Slab evaluation at padding slots (~80 LOC, depends on Stage 0)

* **Statement.** For `(u, v)` with `adj u v = false`, the slab
  at `i = slotEquiv.symm (.arrow u v)` (padding slot) is
  non-zero at exactly one entry: `(j, k) = (paddingSlot u v,
  paddingSlot u v)` with value 2 (post-Stage-0
  distinguished-padding strengthening).
* **slab-rank consequence.** `slabRank₁ (encode m adj)
  (paddingSlot u v) = 1`.
* **Sub-lemmas (each ≤ 40 LOC):**
  - `slab₁_encoder_at_padding_apply` (uses
    `grochowQiaoEncode_padding_left/_mid/_right` from
    Stage 0).
  - `slabRank₁_at_paddingSlot_eq_1`.
* **Risk.** Low.

#### Sub-task C1.4 — Per-slot joint signatures (~50 LOC, depends on C1.1–3 + Stage 2 diagonals)

* **Definitions (revised post-C1.1 correction):**
  - `vertexSlotSignature : ℕ × ℚ := (1, 1)`
    (no longer parameterised by `outDegree`).
  - `presentArrowSlotSignature : ℕ × ℚ := (2, 0)`.
  - `paddingSlotSignature : ℕ × ℚ := (1, 2)`.
* **Per-slot signature theorems** combining C1.1–3 with
  Stage 2 diagonal-value classification:
  - `grochowQiaoEncode_slabDiagonal_at_vertex_eq_signature`.
  - `grochowQiaoEncode_slabDiagonal_at_presentArrow_eq_signature`.
  - `grochowQiaoEncode_slabDiagonal_at_padding_eq_signature`.
* **Pairwise distinctness:**
  - `vertex_signature_ne_presentArrow_signature` (slab-rank
    1 vs 2 distinguishes).
  - `vertex_signature_ne_padding_signature` (diagonal value
    1 vs 2 distinguishes).
  - `presentArrow_signature_ne_padding_signature` (slab-rank
    2 vs 1 distinguishes).
* **Risk.** Low.

#### Sub-task C1.5 — Multiset structure of encoder + count argument (~150 LOC, depends on C1.4)

* **Statement.** `grochowQiaoEncode_slabDiagonalSignatureMultiset`:
  ```
  slabDiagonalSignatureMultiset (grochowQiaoEncode m adj) =
    m • {vertexSlotSignature} +
    (presentArrowSlotIndices m adj).card • {presentArrowSlotSignature} +
    (paddingSlotIndices m adj).card • {paddingSlotSignature}
  ```
  where `n • {x}` is `Multiset.replicate n x` (a multiset of
  `n` copies of `x`).
* **Proof.** Partition `Finset.univ : Finset (Fin (dimGQ m))`
  into three classes via `slotEquiv` + `isPathAlgebraSlot` +
  `adj` (Stage 2 partition theorem). Apply C1.4 per class.
  Sum via `Multiset.add_def` + `Finset.sum_disjoint`.
* **Sub-lemmas (each ≤ 50 LOC):**
  - `multiset_disjoint_partition_three_way` —
    `Finset.univ.val.map f = (vertex.val.map f) +
    (presentArrow.val.map f) + (padding.val.map f)` for the
    three-way Stage 2 partition.
  - `multiset_replicate_via_constant_map` — when `f` is
    constant on a Finset `S`, `S.val.map f = S.card •
    {f.const}`.

#### Sub-task C1.6 — Count-equality argument (~80 LOC, depends on C1.5 + B2.3)

* **Statement.** `grochowQiao_present_arrow_count_eq_via_signature_multiset`:
  ```
  ∀ (g) (m) (adj₁ adj₂),
    g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂ →
    (presentArrowSlotIndices m adj₁).card =
    (presentArrowSlotIndices m adj₂).card
  ```
* **Proof.**
  1. By B2.3,
     `slabDiagonalSignatureMultiset (encode m adj₁) =
      slabDiagonalSignatureMultiset (encode m adj₂)`.
  2. By C1.5, both sides have the explicit form `m • {V} + |E_i|
     • {P} + |F_i| • {Pad}` where `V = vertexSlotSignature`,
     `P = presentArrowSlotSignature`, `Pad =
     paddingSlotSignature`, `|E_i|` is the present-arrow count
     for `adj_i`, `|F_i|` is the padding-slot count.
  3. Take `Multiset.count P` of both sides:
     - LHS: `m • {V}` contributes 0 (V ≠ P), `|E₁| • {P}`
       contributes `|E₁|`, `|F₁| • {Pad}` contributes 0 (Pad ≠
       P). Total: `|E₁|`.
     - RHS: similarly, total: `|E₂|`.
  4. Conclude `|E₁| = |E₂|`.
* **Sub-lemmas:**
  - `Multiset.count_replicate_self` (Mathlib).
  - `Multiset.count_replicate_other` (Mathlib).

**Mathlib anchors.** `Multiset.count`,
`Multiset.count_eq_card_filter`, `Multiset.count_replicate_self`,
`Multiset.count_replicate_other`, `Multiset.replicate`,
`Multiset.add_def`, `Finset.card_disjoint_union`,
`Finset.sum_disjoint`. All present at the pinned commit
`fa6418a8`.

**Risk (overall T-API-C1).** Low–Medium. The 6-sub-task
decomposition turns ~600 LOC into pieces of ≤ 150 LOC each (the
budget rises slightly post-correction because C1.1's vertex-slot
slab-rank derivation requires explicit case-table reasoning).

**Verification gate.** Module builds;
`grochowQiao_present_arrow_count_eq_via_signature_multiset`
proven; non-vacuity at `m = 3` exhibiting the count agreement on
two complete graphs `K₃`.

**Consumer.** Layer T-API-C2.

### Layer T-API-C2 — Prop 1 unconditional discharge (~300 LOC)

**File:** extends `Orbcrypt/Hardness/GrochowQiao/BlockDecomp.lean`
(the existing module already containing
`GL3PreservesPartitionCardinalities` and the conditional
`partitionPreservingPermFromEqualCardinalities`).

**Public surface:**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `gl3_preserves_partition_cardinalities` | `: GL3PreservesPartitionCardinalities` | The unconditional discharge. |
| `partitionPreservingPermOfGL3` | `(g : GL × GL × GL) (h : g • encode₁ = encode₂) → Equiv.Perm (Fin (dimGQ m))` | Combine the discharge with `partitionPreservingPermFromEqualCardinalities`. |
| `partitionPreservingPermOfGL3_isThreePartition` | the constructed permutation preserves all three slot classes | |

**Composition.**

```lean
theorem gl3_preserves_partition_cardinalities :
    GL3PreservesPartitionCardinalities := by
  intro m adj₁ adj₂ g hg
  exact grochowQiao_present_arrow_count_eq_via_signature_multiset hg
```

(One-line composition of the Phase B + C1 toolkit with the
`Prop` definition.)

```lean
def partitionPreservingPermOfGL3 (g) (hg) : Equiv.Perm (Fin (dimGQ m)) :=
  partitionPreservingPermFromEqualCardinalities
    (gl3_preserves_partition_cardinalities m adj₁ adj₂ g hg)
```

`partitionPreservingPermOfGL3_isThreePartition` is direct from
the Stage 3 `_isThreePartition` theorem applied at the constructed
permutation.

**Risk.** Low — pure composition.

**Verification gate.** `gl3_preserves_partition_cardinalities`
proven; `#print axioms` standard trio only;
`partitionPreservingPermOfGL3` builds and carries
`_isThreePartition`.

### Phase C deliverables and gates

* One new `.lean` module + extension to `BlockDecomp.lean`.
* `Orbcrypt.lean` extended with one new import + a Vacuity-map
  update marking `GL3PreservesPartitionCardinalities` as
  discharged.
* `scripts/audit_phase_16.lean` extended with `#print axioms` for
  every new public declaration; non-vacuity examples on
  `m ∈ {2, 3}`.
* CLAUDE.md change-log entry: "Phase C" subsection;
  `partitionPreservingPermFromEqualCardinalities` and
  `partition_preserving_perm_under_GL3` reclassified from
  Conditional to Standalone in the Status column (rows
  inheriting the Phase C discharge become unconditional).
* `docs/VERIFICATION_REPORT.md` "Known limitations" item for
  R-15-residual-TI-reverse partial discharge: Prop 1 closed,
  Prop 2 still open.
* Verification: full project `lake build` succeeds.

---

## Phase D — Path-block extraction + restriction theorem (~1,700 LOC post-expansion, **research-grade**)

**Goal.** Prove that any GL³ triple satisfying
`g • encode m adj₁ = encode m adj₂` decomposes into block-
diagonal matrices aligned to the path-algebra-vs-padding
partition (after composing with `liftedSigmaMatrix m π⁻¹` for the
Phase C-extracted partition-preserving permutation π). This is
the **technical heart** of the rigidity argument: the
multilinear-algebra content that constrains GL³ to act
block-diagonally on the partition.

### Layer T-API-D1 — Off-diagonal block vanishing on axis-1 (~600 LOC)

**File (new):** `Orbcrypt/Hardness/GrochowQiao/BlockExtractionAxis1.lean`.

**Public surface:**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `pathBlockMatrix g : Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ` | `:= g.1.val * (liftedSigmaMatrix m (partitionPreservingPermOfGL3 g hg)⁻¹)` (after composing with the Phase C π⁻¹). |
| `pathBlockMatrix_offDiag_eq_zero` | The "path → padding" off-diagonal block of `pathBlockMatrix` is the zero matrix. |
| `paddingBlockMatrix_offDiag_eq_zero` | The "padding → path" off-diagonal block is the zero matrix. |
| `pathBlockMatrix_blockDiagonal_decomposition` | `pathBlockMatrix g hg = Matrix.fromBlocks pathBlock 0 0 paddingBlock` (after `Equiv.sumCompl`-reindexing). |

**Mathematical content.**

After Phase C extracts a partition-preserving permutation π such
that `π '' (pathSlotIndices m adj₁) = pathSlotIndices m adj₂`, the
composed matrix `g_X' := g.1.val * liftedSigmaMatrix m π⁻¹` maps
each slot kind to itself (modulo the partition):

* If `i ∈ pathSlotIndices m adj₁` and `j ∈ paddingSlotIndices m
  adj₁`, then `pathBlockMatrix i j = 0`.
* Symmetric for `i ∈ padding` / `j ∈ path`.

**Proof technique.**

The vanishing argument uses the encoder's piecewise structure
and `unfold₁_tensorContract`:

1. **Setup.** Let `T₁ := encode m adj₁`, `T₂ := encode m adj₂`,
   and `g • T₁ = T₂`. By `unfold₁_tensorContract`,
   ```
   unfold₁ T₂ = g.1.val * unfold₁ T₁ * (g.2.valᵀ ⊗ₖ g.3.valᵀ)
   ```

2. **Pull back via π⁻¹.** Compose with `liftedSigmaMatrix m π⁻¹`
   on the row index (axis-1) of the unfolding. The resulting
   matrix `pathBlockMatrix g hg` aligns the row index with the
   permutation-relabelled slot.

3. **Mixed-slot vanishing argument.** Suppose for contradiction
   `pathBlockMatrix i j ≠ 0` for `i ∈ pathSlotIndices m adj₁`
   and `j ∈ paddingSlotIndices m adj₁`. Then `pathBlockMatrix i`
   is a non-zero linear combination of rows of `unfold₁ T₁`,
   one of which (row `j`) is supported only on
   "padding-slot column triples" (by
   `grochowQiaoEncode_padding_distinguishable`). However,
   `pathBlockMatrix i` is also a row of `g.1.val * unfold₁ T₁ *
   (g.2.valᵀ ⊗ₖ g.3.valᵀ)`, which equals `unfold₁ T₂` row
   `(g_X · π⁻¹) i`, supported on path-slot column triples
   (because `i` is a path-algebra slot and π is partition-
   preserving). Contradiction at any non-zero entry.

**Detailed sub-task breakdown.**

The off-diagonal-vanishing argument is the **single deepest
research-scope content** in the workstream. It decomposes into
**8 named sub-tasks** organised around three logical phases:
(D1.A) characterise the support of encoder unfoldings; (D1.B)
characterise how the support transforms under GL³; (D1.C) close
the contradiction argument that forces off-diagonal blocks to
vanish.

#### Sub-task D1.1 — Slot-triple-aligned support of encoder unfolding (~80 LOC, depends on Stage 0)

* **Statement.** `unfold₁_encoder_support_path_aligned`:
  ```
  ∀ (m) (adj) (i ∈ pathSlotIndices m adj) (j k : Fin (dimGQ m)),
    (unfold₁ (grochowQiaoEncode m adj)) i (j, k) ≠ 0 →
    j ∈ pathSlotIndices m adj ∧ k ∈ pathSlotIndices m adj
  ```
* **Proof.** From `grochowQiaoEncode_padding_distinguishable`
  (Stage 0): if `T(i, j, k) ≠ 0`, then either all three
  indices are path-algebra slots, or all three are padding
  slots. Combined with `i ∈ pathSlotIndices`, the first case
  applies, so `j, k ∈ pathSlotIndices`.
* **Sub-lemmas:** none (direct Stage 0 application).
* **Risk.** Low.

#### Sub-task D1.2 — Symmetric support for padding slots (~80 LOC, depends on Stage 0)

* **Statement.** `unfold₁_encoder_support_padding_aligned`:
  symmetric for `i ∈ paddingSlotIndices m adj` —
  non-zero entries force `j, k ∈ paddingSlotIndices`.
* **Proof.** Symmetric to D1.1 via the second branch of
  `grochowQiaoEncode_padding_distinguishable`.
* **Risk.** Low.

#### Sub-task D1.3 — Composed-matrix row equation with π⁻¹ (~80 LOC, depends on Phase A A2.1, Phase C C2)

* **Definitions.**
  - `pathBlockMatrix g hg : Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ`
    `:= g.1.val * (liftedSigmaMatrix m
       (partitionPreservingPermOfGL3 g hg)⁻¹)`
  - The "composed matrix" pulls back `g.1.val` via the Phase C
    π⁻¹ permutation matrix.
* **Statement.** `pathBlockMatrix_unfold₁_relation`:
  ```
  ∀ i (j, k),
    (pathBlockMatrix g hg) i j' (k', ...) = ?
  ```
  More usefully: the composition's row `i` of `unfold₁ T₂` (after
  pulling back π⁻¹ on the row index) equals
  `(pathBlockMatrix g hg row i) * unfold₁ T₁ * (g.2.valᵀ ⊗ₖ
  g.3.valᵀ)`, where `(pathBlockMatrix g hg row i)` is a row
  vector indexed by `Fin (dimGQ m)`.
* **Proof.** Direct from `unfold₁_tensorContract` (Stage 1) +
  the partition-preserving permutation's matrix-multiplication
  identity (Stage 1 `liftedSigmaMatrix` lemmas).
* **Risk.** Low. Pure matrix arithmetic.

#### Sub-task D1.4 — Path-slot row of `unfold₁ T₂` lands in path-slot column subspace (~120 LOC, depends on D1.1)

* **Statement.** `unfold₁_T2_path_slot_row_path_aligned`:
  for `i' ∈ pathSlotIndices m adj₂` (a row index of
  `unfold₁ T₂`), the row's support is contained in
  `(pathSlotIndices m adj₂) × (pathSlotIndices m adj₂)` ⊂
  `Fin (dimGQ m) × Fin (dimGQ m)`. Same statement for `T₁`.
* **Proof.** Direct application of D1.1 to `T₂ := encode m
  adj₂`. Symmetric for `T₁` and padding via D1.2.
* **Risk.** Low.

#### Sub-task D1.5 — Path-slot row of `unfold₁ T₁ * (Bᵀ ⊗ₖ Cᵀ)` (~120 LOC, depends on D1.4)

* **Statement.** `unfold₁_T1_kronecker_path_aligned`:
  ```
  ∀ a ∈ pathSlotIndices m adj₁, ∀ (j, k),
    (unfold₁ T₁ * (g.2.valᵀ ⊗ₖ g.3.valᵀ)) a (j, k) ≠ 0 →
    ∃ (j' k' : Fin (dimGQ m)),
      j' ∈ pathSlotIndices m adj₁ ∧
      k' ∈ pathSlotIndices m adj₁ ∧
      g.2.val j j' ≠ 0 ∧ g.3.val k k' ≠ 0
  ```
  *(Reading the contrapositive: if the row's `(j, k)` entry is
  non-zero in the right-Kronecker product, there must exist
  path-aligned `(j', k')` such that `T₁(a, j', k') ≠ 0` AND `g.2`
  connects `j` to `j'` AND `g.3` connects `k` to `k'`.)*
* **Proof.** Expand via `Matrix.kronecker_apply`:
  ```
  (unfold₁ T₁ * (Bᵀ ⊗ₖ Cᵀ)) a (j, k)
    = ∑_{(j', k')} unfold₁ T₁ a (j', k') * Bᵀ j' j * Cᵀ k' k
    = ∑_{(j', k')} T₁(a, j', k') * B j j' * C k k'
  ```
  By D1.4, `T₁(a, j', k') ≠ 0` only when `j', k' ∈
  pathSlotIndices m adj₁`. Reading off the contrapositive
  shape gives the existence claim.
* **Risk.** Medium. Kronecker arithmetic + sum-non-zero
  characterisation.

#### Sub-task D1.6 — Path-to-padding off-diagonal vanishing (~150 LOC, depends on D1.3, D1.4, D1.5)

* **Statement.** `pathBlockMatrix_path_to_padding_zero`:
  ```
  ∀ i ∈ pathSlotIndices m adj₁,
    ∀ a ∈ paddingSlotIndices m adj₁,
    (pathBlockMatrix g hg) i a = 0
  ```
* **Proof outline (the contradiction).**
  Suppose `(pathBlockMatrix g hg) i a ≠ 0` for `i` path,
  `a` padding.

  **Step 1 (transport via the encoder equality).** Let
  `i' := (partitionPreservingPermOfGL3 g hg) i`. Then `i' ∈
  pathSlotIndices m adj₂` by Phase C's
  `partitionPreservingPermOfGL3_isThreePartition`. From D1.3's
  row equation,
  ```
  unfold₁ T₂ i' = (pathBlockMatrix g hg row i) * unfold₁ T₁ *
                  (g.2.valᵀ ⊗ₖ g.3.valᵀ).
  ```

  **Step 2 (extract the contradiction column).** Pick any
  `(j₀, k₀) ∈ Fin (dimGQ m) × Fin (dimGQ m)` such that
  `unfold₁ T₂ i' (j₀, k₀) ≠ 0`. By D1.4 applied to `i' ∈
  pathSlotIndices m adj₂`, `j₀, k₀ ∈ pathSlotIndices m adj₂`.

  **Step 3 (read off the row contribution at column `(j₀, k₀)`).**
  ```
  unfold₁ T₂ i' (j₀, k₀) =
    ∑_{a'} (pathBlockMatrix g hg) i a' *
           (unfold₁ T₁ * (g.2.valᵀ ⊗ₖ g.3.valᵀ)) a' (j₀, k₀)
  ```
  The sum runs over `a' : Fin (dimGQ m)`. **Split into path /
  padding contributions:**
  - For `a' ∈ pathSlotIndices m adj₁`: the
    `(pathBlockMatrix) i a'` factor is unconstrained; the
    `(unfold₁ T₁ * Kron) a' (j₀, k₀)` factor is allowed to be
    non-zero (path → path supported).
  - For `a' ∈ paddingSlotIndices m adj₁`: the
    `(unfold₁ T₁ * Kron) a' (j₀, k₀)` factor is forced to be
    zero **as long as `(j₀, k₀)` is path-aligned in `adj₁`'s
    sense**. By D1.5 applied to padding `a'`, the
    `(j₀, k₀)`-entry of the right-Kronecker product is
    non-zero only when there exists a padding `(j', k')` such
    that `g.2 j₀ j' ≠ 0` and `g.3 k₀ k' ≠ 0`.

  **Step 4 (the conclusion).** The padding contribution
  vanishes only if NO padding `(j', k')` is `g.2`/`g.3`-
  connected to `(j₀, k₀)`. **This is where Phase D's deep
  content lives:** the encoder's distinguished-padding
  structure (post-Stage-0) plus the partition-preservation of
  the chosen π forces the GL³ matrices to NOT mix path and
  padding subspaces in their column action. **This step
  requires a separate non-trivial argument** that consumes
  the partition-preservation property of π and the rank-
  preservation property of `g.2`, `g.3`.

  **Step 5 (resolution via the symmetric off-diagonal argument).**
  Step 4's "no path-to-padding mixing" sub-claim is the
  symmetric of the original sub-task statement applied to
  `g.2` and `g.3` independently. The full argument therefore
  requires **mutual induction** on `g.1`, `g.2`, `g.3`'s
  off-diagonal vanishing — one cannot prove `g.1`'s vanishing
  without `g.2` and `g.3`'s vanishing too. The
  three-axis argument lands together in D2.

* **Sub-lemmas (each ≤ 60 LOC):**
  - `pathBlockMatrix_row_pull_back`: re-indexing via π.
  - `unfold₁_T1_padding_path_aligned_kron_zero`: the
    cross-aligned vanishing of the padding-row Kronecker
    product (extracted from D1.5).
  - `pathBlockMatrix_path_to_padding_contradiction`: the
    full case analysis, parameterised by the symmetric D2
    vanishing properties.
* **Risk.** **Very High.** The mutual-induction structure
  across three axes is the genuinely research-grade content.
  ~50 LOC reserve for the mutual-induction packaging in D6 +
  D7 (next sub-tasks) and the eventual D8 close-out.

#### Sub-task D1.7 — Padding-to-path off-diagonal vanishing (~80 LOC, symmetric to D1.6)

* **Statement.** `pathBlockMatrix_padding_to_path_zero`:
  ```
  ∀ i ∈ paddingSlotIndices m adj₁,
    ∀ a ∈ pathSlotIndices m adj₁,
    (pathBlockMatrix g hg) i a = 0
  ```
* **Proof.** Symmetric to D1.6, swapping the roles of path
  and padding.
* **Risk.** Same as D1.6.

#### Sub-task D1.8 — Block-diagonal packaging (~120 LOC, depends on D1.6, D1.7)

* **Statement.** `pathBlockMatrix_blockDiagonal_decomposition`:
  After re-indexing via `Equiv.sumCompl
  (pathSlotIndices m adj₁)` (with appropriate `DecidablePred`
  instances), the matrix `pathBlockMatrix g hg` has the
  block form
  ```
  Matrix.fromBlocks
    pathBlockComponent
    0
    0
    paddingBlockComponent
  ```
  for some block matrices `pathBlockComponent :
  pathSlotIndices m adj₁ → pathSlotIndices m adj₁ → ℚ` and
  `paddingBlockComponent : paddingSlotIndices m adj₁ →
  paddingSlotIndices m adj₁ → ℚ`.
* **Sub-lemmas (each ≤ 50 LOC):**
  - `pathSlotIndices_decidablePred`: a `DecidablePred (· ∈
    pathSlotIndices m adj₁)` instance (already provable from
    `Stage 2`'s definitions, but explicitly named here for
    typeclass synthesis).
  - `Equiv.sumCompl_pathSlotIndices`: instantiate Mathlib's
    `Equiv.sumCompl` at the path-vs-padding partition.
  - `Matrix.reindex_fromBlocks`: the standard reshape lemma.
  - `pathBlockMatrix_block_form`: combine D1.6, D1.7, the
    sumCompl reindex, and `Matrix.fromBlocks_zero₁₂` /
    `_zero₂₁`.
* **Risk.** Medium. Index-management bookkeeping.

**Mathlib API gap forecast.**

The two highest-risk Mathlib gaps are:

1. **`Matrix.fromBlocks` interaction with `Matrix.kroneckerMap`.**
   The block decomposition of a Kronecker product
   `(A ⊗ₖ B)[I × I' | J × J']` for index partitions `(I, I')`
   and `(J, J')` may or may not be available as a Mathlib
   lemma at `fa6418a8`. **Mitigation:** if absent, hand-roll
   the helper via `kronecker_apply` + sum-splitting. ~80 LOC
   reserve, counted within D1.6.
2. **`Equiv.sumCompl` for `Finset`-based partitions.**
   Mathlib's `Equiv.sumCompl` operates on `Set.compl`; for
   `Finset`-based partitions we need a small adapter via
   `Finset.compl` + `Finset.toSet`. ~30 LOC reserve, counted
   within D1.8.

**Risk (overall T-API-D1).** **Very High (research-grade).**
The 8-sub-task decomposition turns ~600 LOC into pieces of
≤ 150 LOC each. The deepest single sub-task is D1.6 (the
contradiction argument across three axes), bounded at ~150
LOC but with mutual-induction structure across D1.6 ↔ D2
(symmetric axes) ↔ D1.7. The mutual-induction packaging is
addressed in D2.

**Verification gate.** Module builds (set
`set_option maxHeartbeats 800000` per declaration if needed —
profile with `set_option trace.profiler true`);
`pathBlockMatrix_blockDiagonal_decomposition` proven; non-vacuity
at `m = 2` (empty graph identity case).

**Consumer.** Layer T-API-D2.

### Layer T-API-D2 — Symmetric block decompositions on axes 2, 3 + mutual-induction packaging (~500 LOC)

**File (new):** `Orbcrypt/Hardness/GrochowQiao/BlockExtractionAxes23.lean`.

**Goal.** Lift Phase D's axis-1 vanishing argument symmetrically
to axes 2 and 3, AND close the mutual-induction loop that D1.6
left open: the path-to-padding vanishing on axis-1 ultimately
relies on the same vanishing on axes 2 and 3.

**Detailed sub-task breakdown.**

#### Sub-task D2.0 — Pre-requisite: axis-2 and axis-3 unfolding bridges (~120 LOC, depends on Stage 1)

* **Statements (3 lemmas).**
  - `unfold₂_tensorContract`:
    ```
    unfold₂ (tensorContract A B C T) =
      B * unfold₂ T * (A.transpose ⊗ₖ C.transpose)
    ```
    *(Where the unfolded matrix's row index is axis-2; the
    column index is the lex-ordered pair `(axis-1, axis-3)`.)*
  - `unfold₃_tensorContract`:
    ```
    unfold₃ (tensorContract A B C T) =
      C * unfold₃ T * (A.transpose ⊗ₖ B.transpose)
    ```
  - `slab₂`, `slab₃` and their `slab_unfold_row` bridges
    (symmetric to Phase A's `slab₁_unfold₁_row`).
* **Proof.** Symmetric to Stage 1's `unfold₁_tensorContract`.
  The axes are interchangeable up to a relabelling of the
  three GL factors and a transpose / Kronecker swap on the
  column index.
* **Sub-lemmas (each ≤ 30 LOC):** none beyond the three
  symmetric statements.
* **Mathlib anchors.** `Matrix.kronecker_apply`,
  `Matrix.mul_kronecker_mul`, `Stage 1`'s
  `unfold₁_tensorContract` (used as a template).
* **Risk.** Low. Pattern-match on Stage 1.

#### Sub-task D2.1 — Slab transformation under GL × GL × GL (axes 2, 3) (~80 LOC, depends on D2.0)

* **Statements.**
  - `slab₂_smul_eq_double_conjugation`:
    `slab₂ (g • T) ((g.2⁻¹).val a) = g.1.val * slab₂ T a *
    g.3.valᵀ` (axis-1 / axis-3 conjugation on slab-2).
  - `slab₃_smul_eq_double_conjugation`:
    `slab₃ (g • T) ((g.3⁻¹).val a) = g.1.val * slab₃ T a *
    g.2.valᵀ`.
* **Proof.** Symmetric to Phase A's A2.2.
* **Risk.** Low.

#### Sub-task D2.2 — Slot-aligned support of unfoldings (axes 2, 3) (~80 LOC, depends on Stage 0 + D2.0)

* **Statements.**
  - `unfold₂_encoder_support_path_aligned`,
  - `unfold₂_encoder_support_padding_aligned`,
  - `unfold₃_encoder_support_path_aligned`,
  - `unfold₃_encoder_support_padding_aligned`.
* **Proof.** Symmetric to D1.1, D1.2 — direct application of
  `grochowQiaoEncode_padding_distinguishable` (Stage 0).
* **Risk.** Low.

#### Sub-task D2.3 — Off-diagonal vanishing on axis-2 and axis-3 (~120 LOC, depends on D2.1, D2.2)

* **Statements.**
  - `pathBlockMatrix₂_path_to_padding_zero`,
  - `pathBlockMatrix₂_padding_to_path_zero`,
  - `pathBlockMatrix₃_path_to_padding_zero`,
  - `pathBlockMatrix₃_padding_to_path_zero`.

* **Proof.** Pattern-matched from D1.6 / D1.7 with axis-2 /
  axis-3 substitutions. The fundamental contradiction argument
  is identical, with the row / column roles of the GL factors
  rotated.

* **Risk.** Medium. Relies on the mutual-induction loop closing
  in D2.4 (next sub-task).

#### Sub-task D2.4 — Mutual-induction closure (~120 LOC, the technical heart)

* **Statement.** `gl3_block_offDiag_zero_simultaneous`:
  ```
  ∀ (i₁ ∈ pathSlotIndices m adj₁) (a₁ ∈ paddingSlotIndices m adj₁)
    (i₂ ∈ pathSlotIndices m adj₁) (a₂ ∈ paddingSlotIndices m adj₁)
    (i₃ ∈ pathSlotIndices m adj₁) (a₃ ∈ paddingSlotIndices m adj₁),
    (pathBlockMatrix g hg) i₁ a₁ = 0 ∧
    (pathBlockMatrix₂ g hg) i₂ a₂ = 0 ∧
    (pathBlockMatrix₃ g hg) i₃ a₃ = 0
  ```
  *(All three off-diagonal vanishings hold simultaneously.)*

* **Proof technique — the simultaneous induction.**

  The key insight is that **D1.6's "Step 4 needs D2's vanishing"
  reads symmetrically across all three axes**: each axis's
  vanishing presupposes the other two axes' vanishing. The naive
  reading is circular, but the trick is to argue
  **simultaneously** by **strong induction on a unified
  potential function** that decreases across all three axes.

  Specifically, define a "GL³ off-diagonal-mass" potential:
  ```
  potential g := ∑_{i ∈ path}
                    ∑_{a ∈ padding}
                      ((pathBlockMatrix g hg) i a)² +
                  (pathBlockMatrix₂ g hg) i a)² +
                  (pathBlockMatrix₃ g hg) i a)²
  ```
  We argue `potential g = 0` by:

  1. **Encoder-equality forces a polynomial identity.** From
     `g • encode m adj₁ = encode m adj₂` plus the mutual
     unfoldings, every entry of the path-aligned columns of the
     three Kronecker-product factors is determined by a linear
     combination over the path-aligned entries of `g`'s factors.
  2. **The path-aligned columns of `g`'s factors restrict to a
     bijection.** Phase C's partition-preserving permutation π
     restricts each factor `g.1`, `g.2`, `g.3` to a block-diagonal
     action, **provided** the off-diagonals all vanish. The
     converse: any factor with a non-zero off-diagonal would
     violate the encoder-equality (by introducing a non-zero
     entry in a position that the encoder's piecewise structure
     forbids).
  3. **Conclude the potential is zero.** The encoder-equality
     forces every off-diagonal entry to be zero individually.

* **Sub-lemmas (each ≤ 50 LOC):**
  - `gl3_offDiag_potential_definition` — the potential function.
  - `gl3_offDiag_potential_at_encoder_equality` — the polynomial
    identity at `g • encode₁ = encode₂`.
  - `gl3_offDiag_potential_eq_zero` — the conclusion.

* **Risk.** **Very High.** The simultaneous-induction structure
  is novel formalisation content. ~80 LOC reserve for the
  potential-function machinery + 40 LOC reserve for the
  polynomial-identity expansion.

* **Verification gate.** All three pathBlockMatrix off-diagonals
  vanish; `gl3_block_offDiag_zero_simultaneous` proven; non-
  vacuity at `m = 2` (empty graph identity case).

#### Sub-task D2.5 — Block-diagonal packaging for axes 2, 3 + triple corollary (~80 LOC, depends on D2.4)

* **Statements.**
  - `pathBlockMatrix₂_blockDiagonal_decomposition`,
  - `pathBlockMatrix₃_blockDiagonal_decomposition`,
  - `gl3_block_diagonal_triple`: combines D1.8 + D2.5 into the
    consumer-facing tuple
    ```
    (pathBlockMatrix g hg, pathBlockMatrix₂ g hg, pathBlockMatrix₃ g hg)
    ```
    each block-diagonal w.r.t. the partition.
* **Proof.** Pattern-matched from D1.8 with axis substitutions.
* **Risk.** Low (post-D2.4).

**Risk (overall T-API-D2).** **Very High.** The
mutual-induction structure (D2.4) is the bottleneck. The
6-sub-task decomposition turns ~500 LOC into pieces of ≤ 120 LOC
each. If D2.4 stalls, D2.0–D2.3 can land independently as a
"partial axis-2/3 toolkit" pull request, deferring D2.4 to a
follow-up. **However**, the Phase D / E / F / G chain depends on
D2.4 closing; partial landing of D2 does not unblock the
downstream phases.

**Verification gate.** Module builds; all three off-diagonal
vanishings proven; non-vacuity examples on `m ∈ {2, 3}`.

**Consumer.** Layer T-API-D3.

### Layer T-API-D3 — Path-block subspace + restriction theorem (~300 LOC)

**File (new):** `Orbcrypt/Hardness/GrochowQiao/PathBlockSubspace.lean`.

**Public surface:**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `pathBlockSubspace m adj : Submodule ℚ (Fin (dimGQ m) → ℚ)` | `:= Submodule.span ℚ {ej : j ∈ pathSlotIndices m adj}` | The path-algebra slot subspace. |
| `paddingSubspace m adj : Submodule ℚ (Fin (dimGQ m) → ℚ)` | symmetric | |
| `pathBlockBasis m adj : Basis (pathSlotIndices m adj) ℚ (pathBlockSubspace m adj)` | Mathlib basis on path-slot subspace. |
| `gl3_restrict_to_pathBlock` | `(g : GL × GL × GL) (h : g • encode₁ = encode₂) → pathBlockSubspace m adj₁ →ₗ[ℚ] pathBlockSubspace m adj₂` | The restriction of `pathBlockMatrix g hg` to the path-block subspace. |
| `gl3_restrict_isLinearEquiv` | the restriction is a `LinearEquiv`. |

**Mathematical content.**

D1 + D2's block-diagonal decomposition lets us *restrict*
`g.1.val ⋅ liftedSigmaMatrix m π⁻¹` to the path-block subspace,
producing a linear map `pathBlockSubspace m adj₁ →ₗ[ℚ]
pathBlockSubspace m adj₂`. The off-diagonal vanishing guarantees
the restriction is well-defined; the bijectivity of `g.1` (as a
GL element) plus the partition-preserving property of π
guarantee the restriction is a `LinearEquiv`.

**Sub-lemma decomposition (each ≤ 80 LOC):**

* `pathBlockBasis` — built via `Basis.mk` over the indicator
  vectors `ej` indexed by `pathSlotIndices m adj`.
* `gl3_restrict_well_defined` — uses D1+D2's off-diagonal
  vanishing.
* `gl3_restrict_bijective` — composes with `g⁻¹`-restriction
  (the inverse direction).
* `gl3_restrict_to_pathBlock` — package as a linear equiv.

**Risk.** Medium. Mostly Mathlib bookkeeping over `Basis.mk` and
`LinearMap.restrict`.

**Verification gate.** Module builds;
`gl3_restrict_to_pathBlock` is well-typed and bijective.

**Consumer.** Phase E.

### Phase D deliverables and gates

* Three new `.lean` modules under `Orbcrypt/Hardness/GrochowQiao/`.
* `Orbcrypt.lean` extended with three new imports.
* `scripts/audit_phase_16.lean` extended with `#print axioms`
  for every new public declaration; non-vacuity examples on
  `m ∈ {2, 3}`.
* CLAUDE.md change-log: "Phase D" subsection — the longest
  entry of the workstream.
* Verification: full project `lake build` succeeds; per-
  declaration heartbeat profiling documented for the slowest
  proofs.

---

## Phase E — AlgEquiv construction from path-block GL³ (~1,100 LOC, **High risk**)

**Goal.** Lift Phase D's `gl3_restrict_to_pathBlock` linear
equivalence to an **algebra equivalence** on
`pathAlgebraQuotient m`. This bridges the multilinear-algebra
content of Phase D to the structural rigidity content of
Stage 4's `quiverPermAlgEquiv`.

### Layer T-API-E1 — Path-block subspace ≃ presentArrowsSubspace (~400 LOC)

**File (new):** `Orbcrypt/Hardness/GrochowQiao/PathBlockToAlgebra.lean`.

**Public surface:**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `presentArrowsSubspace m adj : Submodule ℚ (pathAlgebraQuotient m)` | `:= Submodule.span ℚ ((vertexIdempotent m '' Finset.univ) ∪ (Set.image2 (arrowElement m) ... presentArrows))` — the subspace of `pathAlgebraQuotient m` spanned by vertex idempotents and present-arrow basis elements. |
| `pathBlockSubspace_equiv_presentArrowsSubspace` | `pathBlockSubspace m adj ≃ₗ[ℚ] presentArrowsSubspace m adj` | The bijection mediated by `slotEquiv` and `slotToArrow`. |
| `gl3_restrict_to_presentArrowsSubspace` | `(g) (hg) → presentArrowsSubspace m adj₁ →ₗ[ℚ] presentArrowsSubspace m adj₂` | Translate Phase D's restriction through the bijection. |

**Mathematical content.**

The path-block subspace `pathBlockSubspace m adj ≤ Fin (dimGQ m)
→ ℚ` consists of indicator-style functions supported on
`pathSlotIndices m adj`. The presentArrows-subspace
`presentArrowsSubspace m adj ≤ pathAlgebraQuotient m =
QuiverArrow m → ℚ` consists of functions supported on the
non-zero quiver basis (vertex idempotents and present-arrow
basis elements).

The equivalence
`pathBlockSubspace m adj ≃ₗ[ℚ] presentArrowsSubspace m adj`
is a relabelling along `slotEquiv` (mapping `Fin (dimGQ m)` slot
indices to `SlotKind m`) and `slotToArrow` (mapping path-algebra
slots to non-zero `QuiverArrow m` basis elements).

**Sub-lemma decomposition (each ≤ 60 LOC):**

* `pathBlockBasis_evaluation` — explicit basis evaluation lemma.
* `presentArrowsBasis` — Mathlib basis on `presentArrowsSubspace
  m adj`.
* `pathBlock_to_presentArrow_bijection` — the relabelling
  function with proven bijectivity (uses
  `Equiv.subtypeCongr` style or `Set.BijOn.equiv`).
* `pathBlockSubspace_equiv_presentArrowsSubspace` — package as
  a `LinearEquiv` via the basis correspondence.
* `gl3_restrict_to_presentArrowsSubspace` — pre-/post-compose
  Phase D's restriction with the bijection.

**Risk.** Medium. Pure Mathlib bookkeeping over basis identities,
but the index-management is delicate.

**Verification gate.** Module builds; the linear equivalence is
proven well-typed; non-vacuity at `m = 1` (single vertex, no
arrows).

**Consumer.** Layer T-API-E2.

### Layer T-API-E2 — Multiplicativity + AlgEquiv packaging (~700 LOC)

**File (new):** `Orbcrypt/Hardness/GrochowQiao/AlgEquivFromGL3.lean`.

**Public surface:**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `gl3OnPathBlock_to_lin` | `(g) (hg) → pathAlgebraQuotient m →ₗ[ℚ] pathAlgebraQuotient m` | The linear map (extending the restriction by zero on the complement). |
| `gl3OnPathBlock_to_lin_basis_apply` | explicit basis evaluation | `@[simp]`. |
| `gl3OnPathBlock_to_lin_preserves_mul` | `(gl3OnPathBlock_to_lin g hg) (a * b) = (gl3OnPathBlock_to_lin g hg a) * (gl3OnPathBlock_to_lin g hg b)` | Multiplicativity (the central technical lemma). |
| `gl3OnPathBlock_to_lin_preserves_one` | one-preservation | |
| `gl3OnPathBlock_to_algEquiv` | `pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m` | The full AlgEquiv. |
| `gl3OnPathBlock_to_algEquiv_apply_vertexIdempotent` | explicit action on vertex idempotents | Used by Phase F. |
| `gl3OnPathBlock_to_algEquiv_apply_arrowElement` | explicit action on arrow basis elements | Used by Phase F. |

**Mathematical content (the central technical layer).**

A GL³ triple that satisfies `g • encode m adj₁ = encode m adj₂`
acts on the path-algebra subspace via the Phase D restriction.
Multiplicativity arises from the structure-tensor preservation:
the encoder's `pathSlotStructureConstant` field literally encodes
the path algebra's multiplication table (Stage 0 / Layer 2).
Under `g • T₁ = T₂`, this multiplication table is preserved up
to GL³ relabelling.

**Decomposition into 5 sub-layers.**

#### Sub-layer E2.1 — Path-structure-constant pull-back (~150 LOC)

* `pathSlotStructureConstant_eq_pathMul_indicator` — explicit
  translation from structure constants to multiplication-table
  indicators (`pathSlotStructureConstant m i j k = if pathMul m
  (slotToArrow i) (slotToArrow j) = some (slotToArrow k) then 1
  else 0` for path-algebra slots `i, j, k`).
* `gl3_pulls_back_pathSlotStructureConstant` — under
  `g • encode m adj₁ = encode m adj₂`, the path-slot structure
  constants of `adj₂` are linear combinations of those of
  `adj₁`, weighted by the GL³ matrix entries.

#### Sub-layer E2.2 — Restriction is multiplicative on basis elements (~250 LOC)

This sub-layer is the **central technical layer of Phase E**. It
proves multiplicativity on the four basis-element-pair cases,
then extends to general elements via bilinearity. The four
basis-element-pair cases are organised into 6 named sub-tasks.

##### Sub-task E2.2.1 — Vertex × Vertex case (~30 LOC)

* **Statement.** `gl3OnPathBlock_to_lin_vertex_mul_vertex`:
  ```
  ∀ u v : Fin m,
    gl3OnPathBlock_to_lin g hg
      (vertexIdempotent m u * vertexIdempotent m v) =
    gl3OnPathBlock_to_lin g hg (vertexIdempotent m u) *
    gl3OnPathBlock_to_lin g hg (vertexIdempotent m v)
  ```
* **Proof.** Case-split on `u = v`:
  - If `u = v`: both sides reduce to
    `gl3OnPathBlock_to_lin (vertexIdempotent v)` (idempotent
    law: `e_v * e_v = e_v`). LHS by direct unfolding; RHS by
    Mathlib's `vertexIdempotent_mul_vertexIdempotent` (Layer
    1.1 of `AlgebraWrapper.lean`).
  - If `u ≠ v`: both sides are zero (orthogonal idempotents).
    LHS by `vertexIdempotent_mul_vertexIdempotent` + linearity
    of `gl3OnPathBlock_to_lin`. RHS via the same Layer 1.1
    lemma.
* **Mathlib anchors.** `vertexIdempotent_mul_vertexIdempotent`
  (`AlgebraWrapper.lean`).
* **Risk.** Low.

##### Sub-task E2.2.2 — Vertex × Arrow case (~50 LOC)

* **Statement.** `gl3OnPathBlock_to_lin_vertex_mul_arrow`:
  ```
  ∀ u w x : Fin m, (.edge w x) ∈ presentArrows m adj₁ →
    gl3OnPathBlock_to_lin g hg
      (vertexIdempotent m u * arrowElement m w x) =
    gl3OnPathBlock_to_lin g hg (vertexIdempotent m u) *
    gl3OnPathBlock_to_lin g hg (arrowElement m w x)
  ```
* **Proof.** Case-split on `u = w`:
  - If `u = w`: `e_u * α(u, x) = α(u, x)` by Layer 1.1's
    `vertexIdempotent_mul_arrowElement`. Both sides reduce
    to `gl3OnPathBlock_to_lin (arrowElement w x)`.
  - If `u ≠ w`: `e_u * α(w, x) = 0` (the structure constant
    vanishes by `pathMul (.id u) (.edge w x) = none` when
    `u ≠ w`). Both sides reduce to 0.
* **Mathlib anchors.**
  `vertexIdempotent_mul_arrowElement` (`AlgebraWrapper.lean`).
* **Risk.** Low.

##### Sub-task E2.2.3 — Arrow × Vertex case (~50 LOC)

* **Statement.** Symmetric to E2.2.2, swapping order:
  ```
  ∀ u v x : Fin m, (.edge u v) ∈ presentArrows m adj₁ →
    gl3OnPathBlock_to_lin g hg
      (arrowElement m u v * vertexIdempotent m x) =
    gl3OnPathBlock_to_lin g hg (arrowElement m u v) *
    gl3OnPathBlock_to_lin g hg (vertexIdempotent m x)
  ```
* **Proof.** Case-split on `v = x`. Uses Layer 1.1's
  `arrowElement_mul_vertexIdempotent`.
* **Risk.** Low.

##### Sub-task E2.2.4 — Arrow × Arrow case (the deepest) (~80 LOC)

* **Statement.** `gl3OnPathBlock_to_lin_arrow_mul_arrow`:
  ```
  ∀ u v w x : Fin m,
    (.edge u v) ∈ presentArrows m adj₁ →
    (.edge w x) ∈ presentArrows m adj₁ →
    gl3OnPathBlock_to_lin g hg
      (arrowElement m u v * arrowElement m w x) =
    gl3OnPathBlock_to_lin g hg (arrowElement m u v) *
    gl3OnPathBlock_to_lin g hg (arrowElement m w x)
  ```
* **Proof.** **Both sides are zero** (no further case
  splitting needed):
  - LHS: `α(u, v) * α(w, x) = 0` by Layer 1.4's
    `arrowElement_mul_arrowElement_eq_zero` (the J²=0
    property of the radical-2 path algebra). Then
    `gl3OnPathBlock_to_lin (0) = 0` by linearity.
  - RHS: each
    `gl3OnPathBlock_to_lin (arrowElement m u v)` is **some
    element of pathAlgebraQuotient m**; the product of two
    such elements is **also a sum of arrow-arrow products**
    (after the AlgEquiv structure analysis from sub-layer
    E2.1's `pathSlotStructureConstant_eq_pathMul_indicator`),
    each of which vanishes by Layer 1.4.
* **The key insight.** The RHS vanishing is **non-trivial** —
  one might worry that `gl3OnPathBlock_to_lin` could send
  arrow-elements to *non*-arrow-element-supported elements,
  breaking the J² = 0 closure. This is where E2.1's structure-
  tensor pull-back is used: the path-block restriction
  preserves the **arrow-element subspace** as a Submodule
  (since arrow-elements correspond to present-arrow slots,
  which are preserved by the partition-preserving π). Hence
  `gl3OnPathBlock_to_lin (arrowElement m u v) ∈
  arrowElementSubspace m adj₂`, and the product of any two
  elements of this subspace lies in `arrowElementSubspace m
  adj₂ * arrowElementSubspace m adj₂ = 0` (Layer 1.4 +
  bilinearity).
* **Sub-lemmas (each ≤ 30 LOC):**
  - `gl3OnPathBlock_to_lin_arrowElement_in_arrowSubspace`:
    arrow-elements are mapped to the arrow-subspace.
  - `arrowSubspace_mul_arrowSubspace_eq_zero`: J² = 0 at the
    Submodule level.
* **Risk.** Medium. The Submodule-level J² = 0 argument
  requires lifting Layer 1.4 from basis elements to arbitrary
  elements of the arrow-subspace via `Submodule.mul_le_*` +
  `Submodule.span_induction`.

##### Sub-task E2.2.5 — Bilinear extension to general elements (~30 LOC)

* **Statement.** `gl3OnPathBlock_to_lin_preserves_mul`:
  ```
  ∀ a b : pathAlgebraQuotient m,
    gl3OnPathBlock_to_lin g hg (a * b) =
    gl3OnPathBlock_to_lin g hg a *
    gl3OnPathBlock_to_lin g hg b
  ```
* **Proof.** Decompose `a = vertexPart a + arrowPart a` and
  `b = vertexPart b + arrowPart b` via `pathAlgebra_decompose`
  (Layer 5 of `AlgebraWrapper.lean`). Distribute and apply
  E2.2.1, E2.2.2, E2.2.3, E2.2.4 to the four pairwise products.
  Use bilinearity of `gl3OnPathBlock_to_lin` (Phase E sub-layer
  E1's `pathBlockToLin_add` and `_smul`).
* **Sub-lemmas (each ≤ 15 LOC):**
  - `pathAlgebraQuotient_mul_decompose`: bilinear expansion
    via `pathAlgebra_decompose`.
  - `gl3OnPathBlock_to_lin_distrib`: linearity over `add`.
* **Risk.** Low.

##### Sub-task E2.2.6 — Index-management discipline (~10 LOC, audit script only)

* **Goal.** Document the three-index-type discipline:
  `Fin (dimGQ m)` (slot indices), `SlotKind m` (slot kind
  classification), `QuiverArrow m` (basis-element indices). The
  `slotEquiv` and `slotToArrow` bijections mediate. Sub-tasks
  E2.2.1–4 must consistently use the **basis-element side**
  (`QuiverArrow m`) for the `arrowElement` / `vertexIdempotent`
  formulations and the **slot-index side** (`Fin (dimGQ m)`)
  only when extracting coefficients via `slotEquiv`.
* **Audit-script witness.** A regression `example` in the
  audit script that exhibits a vertex-vertex product, an arrow-
  vertex product, an arrow-arrow product, and an arrow-vertex-
  via-bilinear-extension product on a concrete `m = 2`
  encoder.

**Mathlib API gap forecast (E2.2).** None identified. The
five sub-tasks compose existing Layer 1.1 + 1.4 lemmas from
`AlgebraWrapper.lean` with the Phase E sub-layer E1 linear-map
infrastructure. The Submodule-level J² = 0 lift (E2.2.4)
requires `Submodule.span_induction` from Mathlib (already
present at `fa6418a8`).

**Risk (overall E2.2).** Medium. The 5 functional sub-tasks
turn ~250 LOC into pieces of ≤ 80 LOC each. The deepest single
sub-task is E2.2.4 (arrow × arrow) at ~80 LOC; the J² = 0
Submodule-level lift is the technical core but is bounded.

#### Sub-layer E2.3 — One-preservation (~80 LOC)

* `gl3OnPathBlock_to_lin_one_eq_one` — `gl3OnPathBlock_to_lin (1
  : pathAlgebraQuotient m) = 1`. Note `1 = ∑_v vertexIdempotent
  v` (from `AlgebraWrapper.lean`); the GL³-action permutes
  vertex idempotents (since vertex slots are preserved by π in
  Phase C), so the sum is preserved.

#### Sub-layer E2.4 — AlgHom + AlgEquiv (~100 LOC)

* `gl3OnPathBlock_to_algHom` — package linearity + multiplicativity
  + unit preservation as a Mathlib `AlgHom`.
* `gl3OnPathBlock_to_lin_inv` — symmetric construction from `g⁻¹`
  (using `g • encode₁ = encode₂` ⟹ `g⁻¹ • encode₂ = encode₁`).
* `gl3OnPathBlock_to_lin_left_inv` / `_right_inv` — round-trip
  identities composed via D3 `gl3_restrict_isLinearEquiv` plus
  the basis-element identity check.
* `gl3OnPathBlock_to_algEquiv` — package via
  `AlgEquiv.ofBijective` (`Mathlib/Algebra/Algebra/Equiv.lean`).

#### Sub-layer E2.5 — Apply lemmas on basis elements (~120 LOC)

* `gl3OnPathBlock_to_algEquiv_apply_vertexIdempotent` — explicit
  formula. Uses Phase C's
  `partitionPreservingPermOfGL3`-permutation σ extracted via
  `vertexPermOfVertexPreserving` + the AlgEquiv structure.
* `gl3OnPathBlock_to_algEquiv_apply_arrowElement` — explicit
  formula. Used by Phase F's adjacency invariance.

**Mathlib anchors.** `Basis.constr`, `LinearMap.restrict`,
`Submodule.subtype`, `AlgHom.toAlgEquivOfInjOn` or
`AlgEquiv.ofBijective`, `pathAlgebra_decompose` from
`AlgebraWrapper.lean`. Reuse aggressively from existing
Stage 4 / Phase C modules.

**Risk.** **High.** Sub-layer E2.2 (basis-level multiplicativity
proof) is the most delicate piece of the entire workstream. The
case analysis on `pathMul`'s four-case table interacting with
the GL³-induced relabelling requires careful index management
between three different index types (`Fin (dimGQ m)`,
`SlotKind m`, `QuiverArrow m`). **Mitigation:** the sub-layer
decomposition above turns ~700 LOC into 5 pieces, each ≤ 250
LOC; sub-layer E2.2's basis-level case analysis is provable by
`decide`-like pattern matching since the encoder's structure is
finitely cased.

**Verification gate.** Module builds (with elaboration time
profiled — `set_option maxHeartbeats 1200000` if needed for
sub-layer E2.2 only); `gl3OnPathBlock_to_algEquiv` carries
`gl3OnPathBlock_to_algEquiv (1, 1, 1) trivial = AlgEquiv.refl`
round-trip; non-vacuity at `m = 1, 2`.

**Consumer.** Phase F.

### Phase E deliverables and gates

* Two new `.lean` modules under `Orbcrypt/Hardness/GrochowQiao/`.
* `Orbcrypt.lean` extended with two new imports.
* `scripts/audit_phase_16.lean` extended with `#print axioms`
  for every new public declaration; non-vacuity examples
  exercising the AlgEquiv on a hand-rolled GL³ identity triple.
* CLAUDE.md change-log: "Phase E" subsection.
* Verification: full project `lake build` succeeds; sub-layer
  E2.2's heartbeat budget profiled and documented.

---

## Phase F — σ extraction + arrow-action analysis (~900 LOC)

**Goal.** Apply Stage 4's existing
`algEquiv_extractVertexPerm` (already landed) to Phase E's
constructed `gl3OnPathBlock_to_algEquiv`, yielding σ and a
radical-conjugating element j. Prove that σ's arrow-action
preserves the `presentArrows`-support, which is the content of
Prop 2.

### Layer T-API-F1 — σ extraction round-trip (~300 LOC)

**File (new):** `Orbcrypt/Hardness/GrochowQiao/SigmaExtractionFromGL3.lean`.

**Public surface:**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `gl3_to_vertexPerm` | `(g : GL × GL × GL) (hg : g • encode₁ = encode₂) → Equiv.Perm (Fin m)` | Compose `gl3OnPathBlock_to_algEquiv` with `algEquiv_extractVertexPerm`. |
| `gl3_to_vertexPerm_radical_witness` | `∃ j ∈ pathAlgebraRadical m, ∀ v, (1+j) * vertexIdempotent (gl3_to_vertexPerm g hg v) * (1-j) = gl3OnPathBlock_to_algEquiv g hg (vertexIdempotent v)` | The radical-conjugating witness from WM. |
| `gl3_to_vertexPerm_eq_partition_descent` | `gl3_to_vertexPerm g hg = vertexPermOfVertexPreserving (partitionPreservingPermOfGL3 g hg)` | Consistency: the algebraic σ extraction agrees with Phase C's slot-classification descent. |

**Mathematical content.** Direct composition of
`algEquiv_extractVertexPerm` (Stage 4 / Phase F starter, in
`WedderburnMalcev.lean`) with the Phase E AlgEquiv. The
consistency theorem `gl3_to_vertexPerm_eq_partition_descent` is
the cross-check: the σ extracted via WM (algebraic) must agree
with the σ extracted via Phase C (slot-classification). Prove
by showing both σ's preserve the same vertex-slot bijection,
using `partitionPreservingPermFromEqualCardinalities`-vertex
preservation + the explicit form of
`gl3OnPathBlock_to_algEquiv (vertexIdempotent v)`.

**Risk.** Low–Medium. `algEquiv_extractVertexPerm` is fully
discharged; the consistency theorem requires careful unfolding
but no new mathematics.

**Verification gate.** Both round-trip identities verified at
`m ∈ {1, 2, 3}`.

**Consumer.** Layer T-API-F2.

### Layer T-API-F2 — Arrow preservation from σ-induced AlgEquiv (~600 LOC)

**File (new):** `Orbcrypt/Hardness/GrochowQiao/ArrowActionFromGL3.lean`.

**Public surface:**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `gl3OnPathBlock_arrow_image_scalar` | `gl3OnPathBlock_to_algEquiv g hg (arrowElement m u v) = c • arrowElement m (σ u) (σ v)` for some `c ≠ 0` (when `(.edge u v) ∈ presentArrows m adj₁`) | Arrow image is a non-zero scalar multiple of the σ-relabelled arrow. |
| `gl3_arrow_preserving_perm_witness` | The σ extracted in F1 satisfies the arrow-preservation Prop. |

**Mathematical content (the deepest sub-layer).**

The proof decomposes into 4 sub-layers (mirroring the prior
plan's Stage 5 T-API-9 structure but applied to
`gl3OnPathBlock_to_algEquiv` rather than `quiverPermAlgEquiv`).

#### Sub-layer F2.1 — Sandwich identity (~60 LOC)

* Direct re-use of Stage 5's `arrowElement_sandwich m u v :
  α(u, v) = e_u * α(u, v) * e_v`. No new content.

#### Sub-layer F2.2 — Inner conjugation fixes pathAlgebra (~150 LOC)

The Stage 5 lemma `inner_aut_radical_fixes_arrow` proves that
inner-conjugation by `(1 + j)` (for `j ∈ pathAlgebraRadical m`)
**fixes basis-element arrows**: `(1 + j) * α * (1 - j) = α` for
`α = arrowElement m u v`. Sub-layer F2.2 extends this to all of
`pathAlgebraQuotient m` via the `pathAlgebra_decompose_radical`
decomposition.

##### Sub-task F2.2.1 — Inner conjugation on the radical (~50 LOC)

* **Statement.** `inner_aut_radical_fixes_radical`:
  ```
  ∀ j ∈ pathAlgebraRadical m, ∀ r ∈ pathAlgebraRadical m,
    (1 + j) * r * (1 - j) = r
  ```
* **Proof.** Both `j` and `r` are sums of arrow-basis elements
  (since the radical is `Submodule.span ℚ {arrowElement m u v
  : u v}`). Apply Stage 5's `inner_aut_radical_fixes_arrow`
  pointwise + linear extension via
  `Submodule.span_induction` on `r`.
* **Sub-lemmas (each ≤ 25 LOC):**
  - `radical_inner_aut_pointwise_arrow`: pointwise fix on a
    single arrow element.
  - `radical_inner_aut_linear_extension`: linear extension via
    `Submodule.span_induction`.
* **Risk.** Low.

##### Sub-task F2.2.2 — Inner conjugation on vertex idempotents (~50 LOC)

* **Statement.** `inner_aut_radical_vertex_idempotent`:
  ```
  ∀ j ∈ pathAlgebraRadical m, ∀ v : Fin m,
    (1 + j) * vertexIdempotent m v * (1 - j) =
      vertexIdempotent m v + j * vertexIdempotent m v -
      vertexIdempotent m v * j
  ```
  *(Inner conjugation fixes the vertex idempotent **modulo**
  the radical: the cross-terms `j * e_v` and `e_v * j` are in
  the radical but generally non-zero individually.)*
* **Proof.** Direct expansion:
  ```
  (1 + j) * e_v * (1 - j)
    = e_v + j * e_v - e_v * j - j * e_v * j
    = e_v + j * e_v - e_v * j  (using j * e_v * j ∈ J² = 0)
  ```
  Final equality uses
  `pathAlgebraRadical_mul_radical_eq_zero` (Layer 6b.1 of
  `WedderburnMalcev.lean`).
* **Sub-lemmas (each ≤ 25 LOC):**
  - `j_mul_e_v_mul_j_eq_zero`: the J² = 0 cross-term.
  - `inner_aut_distribute`: the explicit distributive
    expansion.
* **Risk.** Low.

##### Sub-task F2.2.3 — Combined fix on pathAlgebraQuotient (~50 LOC)

* **Statement.** `inner_aut_radical_fixes_pathAlgebra_modulo_radical`:
  ```
  ∀ j ∈ pathAlgebraRadical m, ∀ c : pathAlgebraQuotient m,
    ∃ (correction : pathAlgebraQuotient m),
      correction ∈ pathAlgebraRadical m ∧
      (1 + j) * c * (1 - j) = c + correction
  ```
  *(Inner conjugation fixes any element of the path algebra
  **modulo** a radical correction.)*
* **Proof.** Decompose `c = vertexPart c + arrowPart c` via
  Layer 5.3's `pathAlgebra_decompose`. Apply F2.2.2 to each
  `vertexPart c` (correction term: `j * vertexPart c -
  vertexPart c * j`, in the radical because the radical is a
  two-sided ideal). Apply F2.2.1 to `arrowPart c ∈
  pathAlgebraRadical m` (correction term: zero — fully fixed).
  Sum.
* **Sub-lemmas:**
  - `pathAlgebraRadical_two_sided_ideal`: `j * vertexPart c -
    vertexPart c * j ∈ pathAlgebraRadical m`.
  - `pathAlgebra_decompose_inner_aut`: combine F2.2.1 and
    F2.2.2 via the decomposition.
* **Risk.** Low.

**Mathlib API gap forecast (F2.2).** None identified. The three
sub-tasks compose existing Stage 5 + Layer 6b lemmas via
standard `Submodule.span_induction` + linear extension.

#### Sub-layer F2.3 — Arrow image is scalar (~250 LOC)

This sub-layer's headline is the structural identity that
**`gl3OnPathBlock_to_algEquiv` sends each arrow element to a
scalar multiple of the σ-relabelled arrow element**, where σ is
the WM-extracted vertex permutation. The proof composes F2.1's
sandwich identity with F1's vertex-idempotent radical-
conjugation form (from `algEquiv_extractVertexPerm`), then
collapses via F2.2's inner-conjugation fix.

##### Sub-task F2.3.1 — Apply AlgHom to sandwich (~30 LOC)

* **Statement.** `gl3OnPathBlock_to_algEquiv_arrowElement_sandwich_eq`:
  ```
  ∀ u v : Fin m, (.edge u v) ∈ presentArrows m adj₁ →
    gl3OnPathBlock_to_algEquiv g hg (arrowElement m u v) =
    gl3OnPathBlock_to_algEquiv g hg (vertexIdempotent m u) *
    gl3OnPathBlock_to_algEquiv g hg (arrowElement m u v) *
    gl3OnPathBlock_to_algEquiv g hg (vertexIdempotent m v)
  ```
* **Proof.** Apply `gl3OnPathBlock_to_algEquiv` (an `AlgHom`) to
  Stage 5's `arrowElement_sandwich m u v`. AlgHom preserves
  multiplication and identity.
* **Sub-lemmas:** none beyond AlgHom.map_mul.
* **Risk.** Low.

##### Sub-task F2.3.2 — Substitute the WM radical-conjugation form (~50 LOC)

* **Statement.** `gl3OnPathBlock_arrowElement_via_radical_conjugation`:
  ```
  ∃ (j ∈ pathAlgebraRadical m),
    ∀ u v : Fin m, (.edge u v) ∈ presentArrows m adj₁ →
      gl3OnPathBlock_to_algEquiv g hg (arrowElement m u v) =
        ((1 + j) * vertexIdempotent m (σ u) * (1 - j)) *
        gl3OnPathBlock_to_algEquiv g hg (arrowElement m u v) *
        ((1 + j) * vertexIdempotent m (σ v) * (1 - j))
  ```
  where `σ := gl3_to_vertexPerm g hg` (Phase F1).
* **Proof.** Substitute F1's
  `gl3_to_vertexPerm_radical_witness` into F2.3.1's RHS. The
  same `j` works for both vertex idempotents (since
  `algEquiv_extractVertexPerm` produces a single radical
  witness for the whole vertex-idempotent family).
* **Risk.** Low.

##### Sub-task F2.3.3 — Collapse the inner conjugations via J² = 0 (~80 LOC)

* **Statement.** `gl3OnPathBlock_arrowElement_collapse_via_radical`:
  ```
  ∀ u v ..., gl3OnPathBlock_to_algEquiv g hg (arrowElement m u v) =
    vertexIdempotent m (σ u) *
    gl3OnPathBlock_to_algEquiv g hg (arrowElement m u v) *
    vertexIdempotent m (σ v)
  ```
* **Proof.** Apply F2.2.3
  (`inner_aut_radical_fixes_pathAlgebra_modulo_radical`)
  twice — once on the left bracket
  `(1 + j) * e_{σu} * (1 - j)`, once on the right bracket
  `(1 + j) * e_{σv} * (1 - j)`. Each invocation reduces the
  bracketed expression to `e_{σ?}` plus a radical correction.
  The radical corrections multiplied by an arrow element
  vanish by Stage 5's `inner_aut_radical_fixes_arrow`-style
  arguments (specifically: the radical cross-products
  `j * α * j` are in J² = 0, where α is the
  AlgEquiv-image of the arrow element, which is **not
  necessarily** an arrow element itself). **The key lemma
  needed is the linear extension**: F2.2.1's
  `inner_aut_radical_fixes_radical` is needed to handle the
  case where the AlgEquiv-image lies partially in the radical.
* **Sub-lemmas (each ≤ 35 LOC):**
  - `algEquiv_image_decompose_via_radical`:
    `gl3OnPathBlock_to_algEquiv g hg (arrowElement m u v)`
    decomposes via `pathAlgebra_decompose_radical` (Layer
    5.3) into a vertex part and a radical part.
  - `algEquiv_arrow_image_radical_part_only`: the AlgEquiv
    of an arrow element has **zero** vertex part (since the
    AlgEquiv preserves the radical, and arrow elements are
    in the radical).
* **Key insight.** `algEquiv_arrow_image_radical_part_only`
  is the structural fact that `gl3OnPathBlock_to_algEquiv`
  preserves the radical as a Submodule (an `AlgEquiv` between
  semi-simple-modulo-radical algebras must preserve the
  radical, by Mathlib's `AlgEquiv.map_radical`-style results
  if available, or hand-rolled). This means
  `gl3OnPathBlock_to_algEquiv (arrowElement m u v) ∈
  pathAlgebraRadical m`.
* **Risk.** Medium. The "AlgEquiv preserves radical" claim
  may need hand-rolling if Mathlib's
  `Algebra.Equiv.preserves_jacobson_radical`-style result is
  not present at `fa6418a8`. ~50 LOC reserve.

##### Sub-task F2.3.4 — Sandwich projects to arrow line (~50 LOC)

* **Statement.** `vertexIdempotent_sandwich_projects_to_arrow_line`:
  ```
  ∀ (a b : Fin m) (X : pathAlgebraQuotient m),
    X ∈ pathAlgebraRadical m →
    vertexIdempotent m a * X * vertexIdempotent m b =
      ((arrowPart_at_edge X a b) : ℚ) • arrowElement m a b
  ```
  where `arrowPart_at_edge X a b` is the coefficient of
  `arrowElement m a b` in the basis decomposition of `X`.
* **Proof.** From the basis decomposition of `X` (via Layer
  5.3 `pathAlgebra_decompose`): `X = ∑ c_w * vertexIdempotent
  m w + ∑ d_{u, v} * arrowElement m u v`. Multiplying on the
  left by `e_a` and on the right by `e_b`:
  - `e_a * vertexIdempotent m w * e_b = δ_{a, w} * δ_{w, b}
    * e_a` (vanishes unless `a = w = b`).
  - `e_a * arrowElement m u v * e_b = δ_{a, u} * δ_{v, b}
    * arrowElement m a b` (only the matching arrow survives).
  So the sandwich projects to a single non-zero term iff
  `arrowElement m a b` appears in `X` — yielding
  `d_{a, b} • arrowElement m a b`.
* **Sub-lemmas:**
  - `vertexIdempotent_sandwich_vertexIdempotent_zero_off_diag`.
  - `vertexIdempotent_sandwich_arrowElement_kronecker`.
* **Risk.** Low.

##### Sub-task F2.3.5 — Conclude scalar form (~30 LOC)

* **Statement.** `gl3OnPathBlock_arrowElement_eq_scalar`:
  ```
  ∃ (c : ℚ), c ≠ 0 ∧
    ∀ u v ..., gl3OnPathBlock_to_algEquiv g hg
      (arrowElement m u v) = c • arrowElement m (σ u) (σ v)
  ```
  *(Note: the scalar `c` is generally **per-arrow-pair**, not
  uniform across all arrows. The non-vacuity claim is that
  the scalar exists and is non-zero.)*
* **Proof.** Combine F2.3.3 (sandwich form post-radical
  collapse) with F2.3.4 (sandwich projects to arrow line).
  The non-vanishing of `c` follows from the AlgEquiv's
  injectivity: if `c = 0` then
  `gl3OnPathBlock_to_algEquiv (arrowElement m u v) = 0`,
  contradicting `arrowElement m u v ≠ 0` and AlgEquiv
  injectivity.
* **Sub-lemmas:**
  - `arrowElement_ne_zero`: re-export from
    `AlgebraWrapper.lean`.
* **Risk.** Low (composition).

**Mathlib API gap forecast (F2.3).** The most likely gap is the
"AlgEquiv preserves radical" claim (used by F2.3.3). Mathlib
has a generic
`Algebra.IsLocalRingHom.localRingHomOfAlgEquiv`-style lifting,
but the specific "AlgEquiv preserves Jacobson radical" may need
hand-rolling for the pathAlgebraQuotient context. ~50 LOC
reserve.

**Risk (overall F2.3).** Medium. The 5 sub-tasks turn ~250 LOC
into pieces of ≤ 80 LOC each. The deepest single sub-task is
F2.3.3 (~80 LOC), which depends on F2.2 + the radical-
preservation argument.

#### Sub-layer F2.4 — Arrow-preservation from path-block restriction (~140 LOC)

* `gl3OnPathBlock_preserves_presentArrows` — the AlgEquiv maps
  the `presentArrowsSubspace m adj₁` bijectively to
  `presentArrowsSubspace m adj₂`. *Proof*: this is the
  content of the Phase D + E restriction theorem; the AlgEquiv
  *is* the restriction, so it preserves the path-algebra subspace
  as a Submodule.
* `arrowElement_in_subspace_iff` — `arrowElement m u v ∈
  presentArrowsSubspace m adj ↔ (.edge u v) ∈ presentArrows m
  adj ↔ adj u v = true`.
* **`gl3_arrow_preserving_perm_witness`** — combine F2.3's
  scalar-image with F2.4's subspace-preservation: σ's arrow
  action preserves `presentArrows`-membership. This is exactly
  the witness `GL3InducesArrowPreservingPerm` requires.

**Risk.** Medium–High. The arrow-bookkeeping under inner
conjugation is delicate, but the J²=0 property collapses the
cross-terms (Stage 5 already proved this for
`quiverPermAlgEquiv`; here we lift it to
`gl3OnPathBlock_to_algEquiv` via the Phase E + F1 chain).

**Verification gate.** `gl3_arrow_preserving_perm_witness`
proven; non-vacuity examples on `m ∈ {2, 3}` with concrete
`(adj₁, adj₂)` pairs (identity GL³ + identity σ; non-trivial
σ via `liftedSigmaGL m σ` action).

**Consumer.** Phase G.

### Phase F deliverables and gates

* Two new `.lean` modules under `Orbcrypt/Hardness/GrochowQiao/`.
* `Orbcrypt.lean` extended with two new imports.
* `scripts/audit_phase_16.lean` extended with `#print axioms`
  for every new public declaration; non-vacuity examples
  exercising arrow preservation on a non-trivial GL³ action.
* CLAUDE.md change-log: "Phase F" subsection.
* Verification: full project `lake build` succeeds.

---

## Phase G — Final discharge (Prop 2 unconditional, ~600 LOC)

**Goal.** Discharge `GL3InducesArrowPreservingPerm`
unconditionally by composing Phase F's `_witness` lemma with the
Prop's quantification structure. Then compose with Stage 5's
existing infrastructure to deliver unconditional
`GrochowQiaoRigidity` and `grochowQiao_isInhabitedKarpReduction`.

### Layer T-API-G1 — Prop 2 unconditional (~300 LOC)

**File:** extends `Orbcrypt/Hardness/GrochowQiao/Rigidity.lean`
(the existing module already containing
`GL3InducesArrowPreservingPerm` and the conditional
`grochowQiaoRigidity_under_arrowDischarge`).

**Public surface:**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `gl3_induces_arrow_preserving_perm` | `: GL3InducesArrowPreservingPerm` | The unconditional discharge. |
| `gl3_preserves_partition_cardinalities_via_arrow_perm` | `: GL3PreservesPartitionCardinalities` | Redundant Prop-1 derivation via Prop 2 (cardinality from arrow bijection). |
| `grochowQiaoRigidity` | `: GrochowQiaoRigidity` | Unconditional rigidity (composes G1 with Stage 5's `grochowQiaoRigidity_under_arrowDischarge`). |

**Composition.**

```lean
theorem gl3_induces_arrow_preserving_perm :
    GL3InducesArrowPreservingPerm := by
  intro m adj₁ adj₂ g hg
  exact ⟨gl3_to_vertexPerm g hg, gl3_arrow_preserving_perm_witness g hg⟩

theorem grochowQiaoRigidity : GrochowQiaoRigidity :=
  grochowQiaoRigidity_under_arrowDischarge gl3_induces_arrow_preserving_perm
```

`gl3_preserves_partition_cardinalities_via_arrow_perm` derives
Prop 1 from Prop 2 via the arrow bijection: σ-action gives
`presentArrows m adj₁` ≃ `presentArrows m adj₂`, so cardinalities
agree. This is ≤ 30 LOC, providing redundant verification with
Phase C's direct discharge.

**Risk.** Low — pure composition.

**Verification gate.** Unconditional theorems
`gl3_induces_arrow_preserving_perm` and `grochowQiaoRigidity`
proven; `#print axioms` standard trio only.

**Consumer.** Layer T-API-G2.

### Layer T-API-G2 — Final Karp reduction inhabitant (~300 LOC)

**File:** extends `Orbcrypt/Hardness/GrochowQiao.lean` (the
top-level module).

**Public surface:**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `grochowQiao_isInhabitedKarpReduction` | `: @GIReducesToTI ℚ _` | Final unconditional Karp reduction. |
| `grochowQiao_isInhabitedKarpReduction_full_chain_unconditional` | refines the existing `_full_chain` to drop the now-discharged Prop hypothesis. |

**Composition.**

```lean
theorem grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _ :=
  grochowQiao_isInhabitedKarpReduction_under_rigidity grochowQiaoRigidity
```

**Verification gate.** Unconditional inhabitant proven;
`#print axioms grochowQiao_isInhabitedKarpReduction` standard
trio only.

### Phase G deliverables and gates

* Extensions to `Rigidity.lean` and `GrochowQiao.lean`.
* `Orbcrypt.lean` axiom-transparency report extended with
  Phase A–G summary section; Vacuity map updated to mark both
  research-scope `Prop`s as discharged.
* `scripts/audit_phase_16.lean` extended with `#print axioms`
  for every new public declaration; final non-vacuity example
  using `grochowQiao_isInhabitedKarpReduction` on a concrete
  pair of isomorphic graphs at `m = 3`.
* `CLAUDE.md` change-log entry: "Phase G" subsection capping
  the R-15-residual-TI-reverse closure; Status column updates
  for every previously-Conditional Stage 3 / Stage 5 theorem.
* `docs/VERIFICATION_REPORT.md` "Known limitations" item for
  R-15-residual-TI-reverse marked CLOSED; "Headline results"
  table extended with `grochowQiaoRigidity` and
  `grochowQiao_isInhabitedKarpReduction` rows (Status:
  **Standalone**).
* `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`
  R-15-residual-TI-reverse marked CLOSED with cross-reference
  to this plan's implementation.
* `lakefile.lean` version bumped from `0.1.21` to `0.1.22`.
* Verification: full project `lake build` succeeds (job count
  rises by ~150–200 from the entire workstream); audit script
  reports every new declaration on standard trio; the headline
  `grochowQiao_isInhabitedKarpReduction` axiom-prints clean.

---

## 6. Critical files

### New modules (under `Orbcrypt/Hardness/GrochowQiao/`)

| File | Phase | LOC (post-expansion) |
|------|-------|----------------------|
| `SlabRank.lean` | A | ~400 |
| `SlabRankInvariance.lean` | A | ~500 |
| `DiagonalValues.lean` | B | ~600 |
| `SlotCardinality.lean` | C | ~600 |
| `BlockExtractionAxis1.lean` | D | ~830 |
| `BlockExtractionAxes23.lean` | D | ~600 |
| `PathBlockSubspace.lean` | D | ~300 |
| `PathBlockToAlgebra.lean` | E | ~400 |
| `AlgEquivFromGL3.lean` | E | ~700 |
| `SigmaExtractionFromGL3.lean` | F | ~300 |
| `ArrowActionFromGL3.lean` | F | ~600 |

**Total new modules: 11.**

### Files modified

| File | Phases | Change |
|------|--------|--------|
| `Orbcrypt/Hardness/GrochowQiao/BlockDecomp.lean` | C | Add `gl3_preserves_partition_cardinalities`, `partitionPreservingPermOfGL3`, `_isThreePartition`. |
| `Orbcrypt/Hardness/GrochowQiao/Rigidity.lean` | G | Add `gl3_induces_arrow_preserving_perm`, `grochowQiaoRigidity`, `gl3_preserves_partition_cardinalities_via_arrow_perm`. |
| `Orbcrypt/Hardness/GrochowQiao.lean` | G | Add `grochowQiao_isInhabitedKarpReduction` (unconditional). |
| `Orbcrypt.lean` | A–G | Add 11 new imports; extend axiom-transparency report with per-phase subsections; update Vacuity map to mark both Props as discharged. |
| `scripts/audit_phase_16.lean` | A–G | Add ~80 new `#print axioms` entries + ~20 non-vacuity `example`s. |
| `CLAUDE.md` | A–G | Per-phase change-log entries + Status-column updates. |
| `docs/VERIFICATION_REPORT.md` | G | Document history + headline results + closed-limitation entries. |
| `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` | G | Mark R-15-residual-TI-reverse CLOSED. |
| `lakefile.lean` | G | Version bump `0.1.21 → 0.1.22`. |

### Existing utilities reused (do not redefine)

The full Stage 0–5 R-TI infrastructure plus the algebraic
toolkit established by Phase A–B + C of `AlgebraWrapper.lean`
and the WedderburnMalcev module:

* From `Orbcrypt/Hardness/TensorAction.lean`: `Tensor3`,
  `matMulTensor1/2/3`, `tensorContract`, `tensorAction`,
  `AreTensorIsomorphic`. All `matMulTensor*_one`, `_mul`,
  cross-axis commutativity simp lemmas.
* From Stage 0 / `StructureTensor.lean`: `dimGQ`, `SlotKind`,
  `slotEquiv`, `isPathAlgebraSlot`, `slotToArrow`,
  `pathSlotStructureConstant`, `ambientSlotStructureConstant`,
  `grochowQiaoEncode`, all `grochowQiaoEncode_diagonal_*`
  lemmas, and `grochowQiaoEncode_padding_distinguishable`.
* From `PathAlgebra.lean`: `QuiverArrow`, `presentArrows`,
  `pathMul`, `pathMul_assoc`, `quiverMap`, `pathMul_quiverMap`,
  `arrowElement_mul_arrowElement_eq_zero`.
* From `AlgebraWrapper.lean`: `pathAlgebraQuotient`,
  `pathAlgebraMul`, `vertexIdempotent`, `arrowElement`, full
  Ring + Algebra ℚ instances, `pathAlgebra_decompose`,
  `pathAlgebra_isIdempotentElem_iff`, `IsPrimitiveIdempotent`,
  `vertexIdempotent_isPrimitive`,
  `vertexIdempotent_completeOrthogonalIdempotents`,
  `AlgEquiv_preserves_completeOrthogonalIdempotents`.
* From `WedderburnMalcev.lean`: `pathAlgebraRadical`,
  `pathAlgebraRadical_mul_radical_eq_zero`,
  `pathAlgebra_decompose_radical`,
  `oneAddRadical_mul_oneSubRadical`,
  `member_radical_mul_arrowElement`,
  `arrowElement_mul_member_radical`,
  `wedderburn_malcev_conjugacy`, `algEquiv_extractVertexPerm`.
* From `PermMatrix.lean`: `liftedSigmaMatrix`, `liftedSigmaGL`,
  `matMulTensor{1,2,3}_permMatrix`,
  `tensorContract_permMatrix_triple`,
  `gl_triple_liftedSigmaGL_smul`,
  `grochowQiaoEncode_gl_isomorphic`.
* From `Forward.lean`: `liftedSigmaSlot`,
  `liftedSigmaSlotEquiv`, `liftedSigma`,
  `liftedSigma_one/_mul/_vertex/_arrow`,
  `isPathAlgebraSlot_liftedSigma`,
  `pathSlotStructureConstant_equivariant`,
  `grochowQiaoEncode_equivariant`.
* From Stage 1 (`TensorUnfold.lean` + `RankInvariance.lean`):
  `unfold₁/₂/₃`, `unfold₁_tensorContract`, `unfoldRank₁`,
  `tensorRank`, `unfoldRank₁_smul`, `kronecker_isUnit_det`.
* From Stage 2 (`SlotSignature.lean` +
  `SlotBijection.lean` + `VertexPermDescent.lean`): all
  slot-index Finsets, partition theorems, diagonal-value
  classification, `IsThreePartitionPreserving`,
  `vertexPermOfVertexPreserving`.
* From Stage 3 (`BlockDecomp.lean`):
  `partitionPreservingPermFromEqualCardinalities` + supporting
  lemmas; the Prop `GL3PreservesPartitionCardinalities`
  (discharged in Phase C).
* From Stage 4 (`AlgEquivLift.lean` +
  `WMSigmaExtraction.lean`): `quiverPermAlgEquiv`,
  `quiverPermAlgEquiv_preserves_presentArrows_iff`,
  `quiverPermAlgEquiv_extractVertexPerm_witness`.
* From Stage 5 (`AdjacencyInvariance.lean` + `Rigidity.lean`):
  `arrowElement_sandwich`, `inner_aut_radical_fixes_arrow`,
  `mem_presentArrows_iff`,
  `vertexPerm_isGraphIso_iff_arrow_preserving`,
  `vertexPermPreservesAdjacency`,
  `grochowQiaoRigidity_under_arrowDischarge`.

### Mathlib dependencies (verified at commit `fa6418a8`)

The Stage 0–5 plan already verified the foundational toolkit
(`Matrix.kroneckerMap`, `Matrix.rank_mul_eq_*_of_isUnit_det`,
`Matrix.det_kronecker`, `AlgEquiv.ofBijective`,
`Set.BijOn.equiv`, `Multiset.map`-arithmetic, `Basis.constr`).
Phases A–G additionally consume:

* `Matrix.fromBlocks`, `Matrix.fromBlocks_zero₁₂`,
  `Matrix.fromBlocks_zero₂₁`, `Matrix.fromBlocks_mul`
  (`Mathlib.Data.Matrix.Block`).
* `Matrix.reindex`, `Equiv.sumCompl` (`Mathlib.Logic.Equiv.Basic`).
* `Multiset.count_eq_card_filter`, `Multiset.map_eq_map_iff_of_inj`
  (`Mathlib.Data.Multiset.Basic`).
* `LinearMap.restrict`, `LinearMap.range`, `Submodule.subtype`
  (`Mathlib.Algebra.Module.Submodule`).

Phase D's `Matrix.fromBlocks` interactions with `kroneckerMap`
need verification at the pinned commit; if absent, hand-roll a
private helper proving `(A ⊗ₖ B)`-restricted-to-Sum-typed-sub-block
= corresponding sub-block of `A` Kronecker-product corresponding
sub-block of `B`. Estimated 100 LOC standalone; counted within
Phase D's budget.

---

## 7. Risk register

| # | Risk | Phase | Likelihood | Mitigation (no `sorry`, no custom axiom) |
|---|------|-------|------------|------------------------------------------|
| 1 | Phase A's per-slab rank identity (inner-product collapse via `g₁ * g₁⁻¹ = 1`) requires non-trivial linear-algebra formalisation | A | Med | Decompose into 4 sub-lemmas, each ≤ 80 LOC. Reuse `rank_mul_eq_*_of_isUnit_det` from Stage 1. |
| 2 | Phase B's "joint signature multiset" approach is novel content with no Mathlib analog | B | Med | Build the joint-signature framework on top of Phase A's slab-rank multiset + `Multiset.count`-arithmetic. ~200 LOC reserve for inner-product-collapse arguments. |
| 3 | Phase D's off-diagonal-block-vanishing argument is the deepest research-scope content | D | **High** | Five-sub-lemma decomposition; reuse Stage 0's `padding_distinguishable` aggressively. Per-occurrence pause if any single sub-lemma exceeds 200 LOC. |
| 4 | Phase D requires `unfold₂_tensorContract`, `unfold₃_tensorContract` (research-scope follow-up from Stage 1) | D | High | Sub-task D2.0 (~150 LOC) discharges these as a pre-requisite. Pattern-matched from `unfold₁_tensorContract`. |
| 5 | `Matrix.fromBlocks` interaction with `kroneckerMap` may be absent in Mathlib at `fa6418a8` | D | Med | Hand-roll a private helper. ~100 LOC counted within Phase D budget. |
| 6 | Phase E sub-layer E2.2 (basis-level multiplicativity) requires careful index management between three different index types | E | High | Pre-discharge basis evaluation lemmas (E2.1) as `@[simp]` simp lemmas. Use `decide`-like pattern matching on slot kinds (encoder is finitely cased). ~250 LOC reserve. |
| 7 | Phase F sub-layer F2.3 (arrow-image-is-scalar collapse) requires extending Stage 5's `inner_aut_radical_fixes_arrow` to the full `pathAlgebraQuotient m` | F | Med | Use `pathAlgebra_decompose_radical`; vertex part fixed trivially modulo radical, arrow part fixed by Stage 5. Composition. |
| 8 | Total LOC exceeds 7,000 budget | All | Med | Acceptable per CLAUDE.md's "user has authorised completing all phases" framing. Each phase's deliverable lands independently. The post-refinement total is ~6,700 LOC (Phases A–G). |
| 9 | Tactic timeout / `Stream idle timeout` during deep proofs (Phase D, Phase E) | D, E | Med | Decompose large proofs into named sub-lemmas (each ≤ 80 LOC); profile with `set_option trace.profiler true`; raise `maxHeartbeats` only on identified hot-spot declarations. Plan files and large doc updates use incremental Edit calls. |
| 10 | Proof obligations expand beyond ~6 months of dedicated effort | All | Med–High | Stop after Phase C (Prop 1 discharge) if Phases D–G stall. Phase C alone delivers significant cryptographic value (the partition-preserving permutation construction becomes unconditional). |
| 11 | Phase G's redundant Prop-1 derivation (via Prop 2) gives a different result from Phase C's direct discharge | G | Low | Both arrive at the same conclusion; they are alternative proofs of the same theorem. Audit script verifies they are interchangeable. |
| 12 | Stage 4's `algEquiv_extractVertexPerm` doesn't compose cleanly with Phase E's `gl3OnPathBlock_to_algEquiv` | F | Low | The composition is type-direct: both operate on `pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m`. Verified by Phase F1's `gl3_to_vertexPerm` definition. |

---

## 8. Verification protocol

### Per-layer (run after every layer lands)

1. `source ~/.elan/env && lake build <module-path> 2>&1 | tail
   -10` — exit code 0, zero warnings, zero errors.
2. `lake env lean scripts/audit_phase_16.lean 2>&1 > /tmp/out.txt`
   — exit code 0.
3. `grep -cE "sorryAx|^error" /tmp/out.txt` — output `0`.
4. `grep "depends on axioms" /tmp/out.txt` — every line shows
   only `[propext, Classical.choice, Quot.sound]` or "does not
   depend on any axioms".

### Per-phase (run after every phase lands)

1. Full project build: `lake build 2>&1 | tail -10` — exit code
   0, "Build completed successfully (NNNN jobs)" with no warnings.
2. CLAUDE.md change-log entry committed.
3. CI green on push.

### End-to-end (after Phase G lands)

1. **Headline theorems build:**
   `gl3_preserves_partition_cardinalities :
   GL3PreservesPartitionCardinalities`,
   `gl3_induces_arrow_preserving_perm :
   GL3InducesArrowPreservingPerm`,
   `grochowQiaoRigidity : GrochowQiaoRigidity`, and
   `grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _`
   all compile unconditionally with axiom-prints on the
   standard trio.
2. **K₃ round-trip example** (in audit script):
   ```lean
   example :
     let adj₁ := fun i j : Fin 3 => decide (i ≠ j)  -- K₃
     let adj₂ := fun i j : Fin 3 => decide (i ≠ j)
     ∃ σ : Equiv.Perm (Fin 3), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j) := by
     have h_iso := grochowQiaoEncode_self_isomorphic 3 adj₁
     exact grochowQiaoRigidity 3 adj₁ adj₂ h_iso
   ```
3. **Non-isomorphic discriminator example:** for two
   non-isomorphic 4-vertex graphs (e.g., `C₄` vs `K_{1,3}`),
   confirm `grochowQiaoRigidity`'s contrapositive — encoded
   tensors are not isomorphic.
4. **Documentation parity:** `CLAUDE.md`,
   `docs/VERIFICATION_REPORT.md`, `Orbcrypt.lean` Vacuity map,
   `docs/planning/R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md` (this
   file), and
   `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`
   all reflect that R-15-residual-TI-reverse is fully closed.
5. **Lakefile version bumped** to `0.1.22`.

---

## 9. Estimated total scope

| Phase | LOC (post-expansion) | Sub-tasks | Risk | Estimated dedicated effort |
|-------|----------------------|-----------|------|----------------------------|
| A | ~900 | A1.1 + A2.1–A2.5 (6 sub-tasks) | Med | 3–5 weeks |
| B | ~600 | B1.1–B1.2 + B2.1–B2.4 (6 sub-tasks) | Low–Med | 2–4 weeks |
| C | ~900 | C1.1–C1.6 + C2.1–C2.2 (8 sub-tasks) | Low–Med | 2–3 weeks |
| D | ~1,700 | D1.1–D1.8 + D2.0–D2.5 + D3 (15 sub-tasks) | **Research** | 8–14 weeks |
| E | ~1,100 | E1.1–E1.5 + E2.1 + E2.2.1–E2.2.6 + E2.3–E2.5 (15 sub-tasks) | High | 4–7 weeks |
| F | ~900 | F1.1–F1.3 + F2.1 + F2.2.1–F2.2.3 + F2.3.1–F2.3.5 + F2.4 (13 sub-tasks) | Med–High | 3–5 weeks |
| G | ~600 | G1.1–G1.2 + G2.1 (3 sub-tasks) | Med | 2–3 weeks |
| **Total** | **~6,700** | **66 sub-tasks** | | **~6–10 months** dedicated effort |

This is a multi-month workstream. The phased structure ensures
each landing is independently usable and reviewable; any pause
between phases leaves the codebase in a clean intermediate state
with public-facing API additions that are valuable in their own
right (e.g., `Tensor3.slabRankMultiset₁` after Phase A;
`gl3_preserves_partition_cardinalities` after Phase C — Prop 1
discharged unconditionally; `gl3OnPathBlock_to_algEquiv` after
Phase E — reusable infrastructure).

### Sub-layer-level granularity

| Phase | Sub-layers | Largest sub-layer | Worst-case stall recovery |
|-------|------------|-------------------|---------------------------|
| A | T-API-A1, A2 | 500 LOC (A2) | Per-slab rank identity (5 sub-lemmas, each ≤ 80 LOC). |
| B | T-API-B1, B2 | 400 LOC (B2) | Joint-signature multiset construction is incremental. |
| C | T-API-C1, C2 | 400 LOC (C1) | Per-slot signature computations are independent. |
| D | T-API-D1, D2, D3 | 600 LOC (D1) | Sub-lemma decomposition allows per-sub-lemma stall recovery. |
| E | T-API-E1, E2 (5 sub-layers) | 250 LOC (sub-layer E2.2) | Each sub-layer ≤ 250 LOC. Sub-layer E2.2 is the bottleneck. |
| F | T-API-F1, F2 (4 sub-layers) | 250 LOC (sub-layer F2.3) | Each sub-layer ≤ 250 LOC. |
| G | T-API-G1, G2 | 300 LOC (G1) | Pure composition. |

The largest single sub-layer is **600 LOC** (Phase D sub-layer
T-API-D1). All other sub-layers are ≤ 500 LOC. **No sub-layer
should require a single proof spanning > 30 LOC of tactic code**
— if a sub-layer's proof exceeds this, decompose further into
named helper lemmas.

### Per-phase commit boundaries

| Phase | Commit count | Granularity |
|-------|--------------|-------------|
| A | 2 commits | A1 (slab API) + A2 (smul invariance, 5 sub-tasks bundled) |
| B | 2 commits | B1 (diagonal API) + B2 (smul invariance, 4 sub-tasks bundled) |
| C | 3 commits | C1.1–3 per-slot computations + C1.4–6 multiset count + C2 discharge |
| D | 6 commits | D2.0 prereq + D1 + D2.1–3 + D2.4 (mutual induction) + D2.5 + D3 |
| E | 4 commits | E1 + E2.1 + E2.2.1–6 (basis multiplicativity) + E2.3–5 |
| F | 4 commits | F1 + F2.1–F2.2.3 + F2.3.1–F2.3.5 + F2.4 |
| G | 2 commits | G1 (Prop discharges) + G2 (Karp inhabitant + documentation) |
| **Total** | **23 commits** | across 7 phases |

23 commits across ~6–10 months is a sustainable cadence for
review-friendly incremental landing. **Each commit must pass
the per-layer verification gate** before the next commit is
written: `lake build` + `audit_phase_16.lean` clean + standard-
trio axiom dependency for every new declaration.

---

## 10. Mathematical soundness checklist

Confirmed before plan acceptance:

* **The two `Prop`s correctly encode Grochow–Qiao SIAM J. Comp.
  2023 §4.3.** Both Props match the literature's standard
  formulation: Prop 1 is the cardinality-preservation lemma at
  the heart of the slot-classification rigidity argument; Prop
  2 is the σ-extraction theorem that ties the cardinality
  preservation back to a graph-isomorphism witness.
* **Phase A's slab-rank multiset invariance is the standard
  multilinear-algebra invariant** for 3-tensor classification
  problems. The reasoning extends to arbitrary `CommRing F`,
  not specifically ℚ.
* **Phase B's joint signature multiset is genuinely needed**
  because the slab-rank multiset alone does not distinguish
  isolated vertices (rank 1) from padding slots (rank 1)
  pre-Stage-0. Post-Stage-0, the diagonal-value multiset alone
  provides this distinguishability; the joint multiset is the
  refined invariant.
* **Phase C's discharge of Prop 1 is genuinely "shallow"** —
  it does not require the AlgEquiv → σ → arrow chain. The
  `Multiset.count` argument is purely combinatorial.
* **Phase D's block-decomposition is the technical heart.**
  This is the multilinear-algebra fact that makes
  Grochow–Qiao 2021's reduction work: the encoder's
  distinguished-padding structure forces GL³ tensor isomorphisms
  to act block-diagonally on the partition.
* **Phase E's AlgEquiv construction is the bridge from
  multilinear algebra to representation theory.** This is the
  essential structural insight: GL³ tensor isomorphisms preserve
  the *algebraic structure* of the path algebra, not just its
  vector-space structure.
* **Phase F's σ extraction via WM is the algebraic-rigidity
  insight.** The path algebra `F[Q_G]/J²` has unique
  primitive-idempotent decompositions modulo radical, which is
  what lets us extract σ from the AlgEquiv.
* **Phase G's composition is purely structural.** The
  research-grade content is in Phases A–F.
* **The redundant Prop-1 derivation in Phase G via Prop 2** is
  a desirable cross-check at the audit-script level, not an
  alternative discharge. Both Phase C's direct discharge and
  Phase G's via-Prop-2 derivation should arrive at the same
  conclusion; if they don't, an inconsistency in the argument
  has been caught.

---

## 11. Best practices and tactic idioms

Inherited from CLAUDE.md and the Stage 0–5 plan:

### Naming and structure

* Identifier names describe content. No phase prefixes, no
  tracking-letter prefixes, no audit-finding prefixes.
* One Mathlib-style lemma per declaration.
* Module length cap at ≤ 600 LOC per `.lean` file.

### Proof engineering

* `funext c; cases c` is the standard opener for any equality
  of `pathAlgebraQuotient m` values.
* `Finset.sum_eq_single` requires explicit 3-arg form.
* Avoid `simp` after `cases h : pathMul ...` — the `cases`
  tactic substitutes the result.
* Prefer `rw [if_neg h_ne]` over `simp [h_ne]` for `if-then-
  else` reductions.
* `set_option maxHeartbeats N` per declaration only — never
  globally. Profile with `set_option trace.profiler true`
  first; document the reason.

### Mathlib-idiomatic patterns

* **Submodule arguments:** `Submodule.span ℚ {basis-image set}`
  + `Submodule.span_le` + `Submodule.mem_span_iff`.
* **Linear maps from bases:** `Basis.constr` + `Basis.mk`.
* **Algebra equivalences:** `AlgEquiv.ofBijective` from a proven
  `AlgHom` + bijectivity.
* **Block matrices:** `Matrix.fromBlocks` + `Matrix.fromBlocks_zero{₁₂,₂₁}`
  + `Equiv.sumCompl`-reindexing.
* **Multiset preservation:** `Multiset.count_eq_card_filter`,
  `Multiset.map_eq_map_iff_of_inj`.

### Documentation

* Module docstrings (`/-! ... -/`) at top of every new `.lean`
  file.
* Public-declaration docstrings (`/-- ... -/`) on every `def`,
  `theorem`, `structure`, `class`, `instance`, `abbrev`.
* No `-- TODO`, `-- FIXME`, `-- temp`, `-- XXX` in committed
  code.

### Audit posture per phase

After each phase lands, the audit-script extension must include:

1. `#print axioms` for every public declaration in the new
   module(s).
2. At least one non-vacuity `example` per public Prop/Theorem,
   exhibiting the result on a concrete `m ∈ {1, 2, 3}` instance.
3. A regression `example` cross-checking the phase's headline
   against an existing infrastructure invariant.

The Phase-16 audit script's `#print axioms` total should rise
by exactly the count of new public declarations + non-vacuity
witnesses introduced by the phase.

### Stream-idle-timeout prevention

* Plan-file edits and large doc updates use incremental Edit
  calls (≤ 80 LOC per call).
* For new `.lean` files > 100 LOC: use `cat <<'EOF' >
  path/to/file.lean` Bash heredoc, then verify with
  `wc -l` and Read on the last few lines.
* After each Write/Edit append, spot-check the result by
  reading the modified region.

---

## 12. Optimization & refinement notes (post-refinement pass)

The plan was reviewed against the audit lessons learned during
the Stage 0–5 implementation (the two deep audits flagged
tautological wrappers and vacuously-true identity-case
witnesses). The following refinements have been applied during
the optimization pass:

### Refinement 1 — Substantive identity-case witnesses

Every phase's non-vacuity `example` block must witness a
**non-trivial** instance of the public theorem. Forbidden:
identity-case witnesses that reduce to `X = X` via `rfl` (the
post-Stage-3 audit caught
`gl3_preserves_partition_cardinalities_identity_case`'s pre-fix
form as such a tautology). Required: identity-case witnesses
that exercise the theorem's *content* by exhibiting a non-trivial
input, e.g., for Prop 1's identity case, take the identity GL³
triple acting on an asymmetric encoder pair `(adj₁, adj₂)`
where `adj₁ ≠ adj₂` and prove the cardinalities still agree
(via direct evaluation, not via the theorem itself).

### Refinement 2 — No tautological wrappers

Each new module must add **substantive content**, not merely
re-export Stage 0–5 declarations under different names.
Forbidden: `gl3_to_vertexPerm` style renamed wrappers that
duplicate `algEquiv_extractVertexPerm`'s signature. Required:
new wrappers must thread non-trivial intermediate state (e.g.,
Phase F1's `gl3_to_vertexPerm` is justified because it composes
`gl3OnPathBlock_to_algEquiv` with `algEquiv_extractVertexPerm`,
producing a function on GL³ triples rather than on AlgEquivs).

### Refinement 3 — No `Prop`-typed shortcuts

Every theorem's statement must be a **provable** conclusion under
the chain's hypotheses, not a Prop-typed obligation that defers
discharge. The two existing research-scope Props
(`GL3PreservesPartitionCardinalities` and
`GL3InducesArrowPreservingPerm`) are the *targets* of this plan,
not its *ingredients*. New Props introduced by this plan are
forbidden (the plan's purpose is to *eliminate* Props, not
introduce more).

### Refinement 4 — Exit-criteria parallelism

Each phase's verification gate matches the Stage 0–5 audit
script's existing structure: `#print axioms` for every public
declaration + at least one non-vacuity `example` per public
Prop/Theorem. The Phase 16 audit script's growth from 770 to
~850 declarations (after Phase G) is forecast and budgeted.

### Refinement 5 — Pause points

The phased structure provides **five clean pause points** where
the workstream can be deferred without leaving the codebase in
an awkward intermediate state:

* **After Phase A:** `Tensor3.slabRankMultiset₁` is a
  publicly-useful 3-tensor invariant.
* **After Phase B:** the joint signature multiset framework is
  publicly useful.
* **After Phase C:** **Prop 1 is discharged.** This is the
  half-way point of cryptographic significance — the
  partition-preserving permutation construction
  (`partitionPreservingPermFromEqualCardinalities`) becomes
  unconditional. Stages 4–5 of the prior plan
  (`partition_preserving_perm_under_GL3`,
  `quiverPermAlgEquiv`-based forward iff) all become
  unconditional via Prop 1 alone.
* **After Phase E:** `gl3OnPathBlock_to_algEquiv` is publicly
  useful infrastructure.
* **After Phase G:** **Both Props discharged. Workstream
  complete.**

### Refinement 6 — Reverse-direction Prop relationships

Prop 2 strictly implies Prop 1 (Phase G's redundant derivation
documents this). A reviewer may pause after Phase C alone (for
a partial closure that delivers Prop 1) and resume Phases D–G
later for the full closure. The Phase G commit then upgrades
both Props to fully unconditional in a single composition.

### Refinement 7 — Mathlib API gap forecasting

Phases A and D have the highest Mathlib gap risk. Pre-Phase-A
verification: confirm `Multiset.map_eq_map_iff_of_inj` (or
equivalent bijection-preservation lemma) is present at
`fa6418a8`. Pre-Phase-D verification: confirm `Matrix.fromBlocks`
+ `kroneckerMap` interactions; if absent, the 100 LOC hand-
rolled helper is budgeted within Phase D.

### Refinement 8 — Phase ordering review

The phase order is **A → B → C → D → E → F → G**, with two
hard dependencies:

* Phase E depends on Phase D (the path-block subspace
  restriction).
* Phase F depends on Phases C, D, E (uses the partition
  permutation, the AlgEquiv, and Stage 4's σ-extraction).

Phases A → B → C are independent of D → E → F → G in the
build-graph sense (Phase C closes Prop 1 via the shallow
invariant route; Phases D → G close Prop 2 via the deep
algebraic route). The redundant Prop-1 derivation at G ensures
both routes converge.

### Refinement 9 — Documentation-vs-code parity

Every phase's CLAUDE.md change-log entry must accurately
describe what the code delivers. The Stage 0–5 audits found
documentation overstating Lean content; this plan's per-phase
exit criteria explicitly require: (a) the change-log entry's
"unconditional content delivered" list matches the actual public
declarations; (b) the Status column in `CLAUDE.md`'s headline
table is updated for every theorem whose Status changes from
Conditional to Standalone; (c) `docs/VERIFICATION_REPORT.md`'s
"Known limitations" section reflects the partial-closure /
full-closure transition between Phase C and Phase G.

### Refinement 10 — Scope conservation

The plan deliberately reuses Stage 0–5 infrastructure
aggressively. New modules **must not** redefine: encoder
machinery, slot classification, path-algebra structure,
Wedderburn–Mal'cev framework, σ-induced AlgEquiv, adjacency
invariance characterisation. The Stage 0–5 770-declaration
baseline is treated as immutable; phases A–G are strictly
additive to this baseline.

---

## 13. Cross-references

* **Stage 0–5 master plan:** `/root/.claude/plans/create-a-detailed-plan-fizzy-planet.md`.
* **Audit plan tracking R-15:** `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`.
* **Original R-TI workstream plan:** `docs/planning/R_TI_PHASE_C_THROUGH_H_PLAN.md`.
* **Phase 16 audit script:** `scripts/audit_phase_16.lean`.
* **Verification report:** `docs/VERIFICATION_REPORT.md`.
* **Project conventions:** `CLAUDE.md` (Naming conventions,
  Release messaging policy, Security-by-docstring prohibition,
  Three core theorems, Vulnerability reporting).
* **Grochow–Qiao 2021 / SIAM J. Comp. 2023 §4.3:** the
  mathematical content this plan formalises in Lean.
* **Research notes (Stage 0–5 prep):**
  - `docs/research/grochow_qiao_path_algebra.md`
  - `docs/research/grochow_qiao_padding_rigidity.md`
  - `docs/research/grochow_qiao_mathlib_api.md`
  - `docs/research/grochow_qiao_reading_log.md`

---

## Appendix A — Notation reference

| Symbol | Type | Meaning |
|--------|------|---------|
| `m` | `ℕ` | Number of vertices in the graph. |
| `adj` | `Fin m → Fin m → Bool` | Adjacency function. |
| `dimGQ m` | `ℕ` | Encoder ambient dimension `:= m + m * m`. |
| `n` | `ℕ` | Generic tensor dimension (often `dimGQ m`). |
| `F` | `Type*` | Generic commutative ring (typically `ℚ`). |
| `Tensor3 n F` | `Fin n → Fin n → Fin n → F` | 3-tensors. |
| `T` | `Tensor3 n F` | A specific 3-tensor (often the encoder image). |
| `g`, `g₁`, `g₂`, `g₃` | `GL n F`, `GL n F × GL n F × GL n F` | GL element / GL³ triple. |
| `σ` | `Equiv.Perm (Fin m)` | Vertex permutation. |
| `π` | `Equiv.Perm (Fin (dimGQ m))` | Slot permutation. |
| `j` | `pathAlgebraQuotient m` | Conjugating radical element from WM. |
| `slotEquiv` | `Fin (dimGQ m) ≃ SlotKind m` | Slot index ↔ slot kind. |
| `slotToArrow` | `SlotKind m → QuiverArrow m` | Path-algebra slots → quiver basis. |
| `unfold₁/₂/₃ T` | `Matrix (Fin n) (Fin n × Fin n) F` | Per-axis 3-tensor unfoldings. |
| `slab₁/₂/₃ T i` | `Matrix (Fin n) (Fin n) F` | Per-axis fixed-slot 2-tensor. |
| `slabRank₁ T i` | `ℕ` | Slab rank `:= (slab₁ T i).rank`. |
| `slabRankMultiset₁ T` | `Multiset ℕ` | Multiset of axis-1 slab ranks. |
| `T.diagonal` | `Fin n → F` | Triple-diagonal `T(i, i, i)`. |
| `slabDiagonalSignature T i` | `ℕ × F` | Joint pair `(slabRank₁ T i, T.diagonal i)`. |
| `slabDiagonalSignatureMultiset T` | `Multiset (ℕ × F)` | Multiset of joint signatures. |
| `vertexIdempotent m v` | `pathAlgebraQuotient m` | Basis element `e_v`. |
| `arrowElement m u v` | `pathAlgebraQuotient m` | Basis element `α(u, v)`. |
| `pathAlgebraRadical m` | `Submodule ℚ (pathAlgebraQuotient m)` | Jacobson radical, J. |
| `J²` | (subspace) | Square of the radical: `J * J = 0`. |
| `pathSlotIndices m adj` | `Finset (Fin (dimGQ m))` | Path-algebra slot indices. |
| `paddingSlotIndices m adj` | `Finset (Fin (dimGQ m))` | Padding slot indices. |
| `presentArrowSlotIndices m adj` | `Finset (Fin (dimGQ m))` | Present-arrow slot indices. |
| `vertexSlotIndices m` | `Finset (Fin (dimGQ m))` | Vertex slot indices. |
| `pathBlockMatrix g hg` | `Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ` | π⁻¹-composed `g.1.val`. |
| `pathBlockMatrix₂` / `₃` | (similar) | Symmetric for axes 2, 3. |
| `gl3OnPathBlock_to_lin g hg` | `pathAlgebraQuotient m →ₗ[ℚ] ...` | Linear map from GL³. |
| `gl3OnPathBlock_to_algEquiv g hg` | `... ≃ₐ[ℚ] ...` | AlgEquiv from GL³. |
| `gl3_to_vertexPerm g hg` | `Equiv.Perm (Fin m)` | σ extracted via WM. |
| `Prop 1` | `GL3PreservesPartitionCardinalities` | The Phase C target. |
| `Prop 2` | `GL3InducesArrowPreservingPerm` | The Phase G target. |

---

## Appendix B — Sub-task dependency graph

The full dependency graph across the 7 phases. Each arrow `X → Y`
means "Y depends on X". Sub-tasks are listed by their identifier
(e.g., `A2.4` is Phase A's T-API-A2's sub-task 4).

### Phase A (Slab-rank multiset invariance)

```
[Stage 1: unfold₁_tensorContract] ──→ A1.1 ─┐
                                            ├→ A2.1 ─→ A2.2 ─→ A2.3 ─→ A2.4 ─→ A2.5
[Stage 1: rank_mul_eq_*_of_isUnit_det] ─────┘                                    │
                                                                                 ▼
                                                                          (Phase B input)
```

### Phase B (Diagonal-value invariance)

```
[Phase A: A2.4] ────────────┐
                            ├→ B1.1 ─→ B1.2 ─→ B2.1 ─→ B2.2 ─→ B2.3 ─→ B2.4
[Stage 0: padding_distinguishable] ──┘                                  │
                                                                        ▼
                                                                  (Phase C input)
```

### Phase C (Slot-classification rigidity / Prop 1 discharge)

```
[Phase B: B2.3] ────────────┐
                            ├→ C1.1 ─┐
[Stage 0: encoder] ─────────┤        ├→ C1.4 ─→ C1.5 ─→ C1.6 ─→ C2.1 (Prop 1 discharge)
                            ├→ C1.2 ─┤
[Stage 2: diagonal_values] ─┘        │
                                     │
                              C1.3 ──┘
```

### Phase D (Path-block extraction)

```
[Stage 0: padding_distinguishable] ─→ D1.1, D1.2 ──┐
[Phase A: A2.1, A2.4] ─────────────────────────────┤
                                                   ├→ D1.3 ─→ D1.4, D1.5 ─→ D1.6 ─┐
[Phase C: C2.1] ───────────────────────────────────┘                              │
                                                                                  ├→ D1.7 ─→ D1.8 (axis-1)
[Stage 1: unfold₁_tensorContract] ─→ D2.0 ─→ D2.1 ─→ D2.2 ─→ D2.3 ─→ D2.4 ────────┤
                                                                          (mutual)│
                                                                                  ▼
                                                                              D2.5 ─→ D3 (subspace)
                                                                                  │
                                                                                  ▼
                                                                          (Phase E input)
```

### Phase E (AlgEquiv from path-block)

```
[Phase D: D3] ─────────┐
                       ├→ E1.1 ─→ E1.2 ─→ E1.3 ─→ E1.4 ─→ E1.5 ─┐
[Stage 4: AlgEquiv]  ──┘                                        │
                                                                ▼
                                       E2.1 ─→ E2.2.1, .2, .3, .4 ─→ E2.2.5 ─→ E2.3 ─→ E2.4 ─→ E2.5
                                                                                              │
                                                                                              ▼
                                                                                        (Phase F input)
```

### Phase F (σ extraction + arrow action)

```
[Stage 4: algEquiv_extractVertexPerm] ──┐
[Phase E: E2.5] ────────────────────────┤
                                        ├→ F1.1 ─→ F1.2 ─→ F1.3 ─┐
                                        │                         │
[Stage 5: arrowElement_sandwich] ───────┘                         │
                                                                  ▼
                              F2.1 ─→ F2.2.1, .2, .3 ─→ F2.3.1 ─→ F2.3.2 ─→ F2.3.3 ─→ F2.3.4 ─→ F2.3.5 ─→ F2.4
                                                                                                              │
                                                                                                              ▼
                                                                                                       (Phase G input)
```

### Phase G (Final discharge)

```
[Phase C: C2.1 — Prop 1 discharge]  ────┐
                                        │
[Phase F: F2.4 — arrow witness] ─→ G1.1 ─→ G1.2 (grochowQiaoRigidity) ─→ G2.1 (final inhabitant)
```

### Critical-path summary

The **longest sequential path** is:
```
Stage-1 → A1.1 → A2.1 → A2.2 → A2.3 → A2.4 → B2.2 → B2.3 → C1.1
       → C1.5 → C1.6 → C2.1 → D1.1 → D1.3 → D1.4 → D1.6 → D2.4
       → D3 → E1.1 → E2.2.1 → E2.2.4 → E2.2.5 → E2.4 → E2.5
       → F1.1 → F1.2 → F1.3 → F2.2.1 → F2.3.1 → F2.3.3 → F2.3.5
       → F2.4 → G1.1 → G2.1
```
This is approximately 33 sequential sub-tasks. Many parallelisation
opportunities exist (especially within phases — e.g., A2.5's symmetric
variants for axes 2, 3 can land in parallel with D2.0 + D2.1 + D2.2),
but the critical path bounds the calendar time.

---

## Appendix C — Per-phase Gantt-style timeline

| Calendar week | Phase | Sub-tasks landing | Gating dependency |
|---------------|-------|-------------------|-------------------|
| 1–4 | A | A1.1 → A2.1 → A2.2 → A2.3 → A2.4 → A2.5.0 (D2.0 pre-req) | Stage 1 |
| 5–8 | A → B | A2.5 + B1.1 → B1.2 → B2.1 → B2.2 → B2.3 → B2.4 | A2.4 |
| 9–11 | C | C1.1 → C1.2 → C1.3 → C1.4 → C1.5 → C1.6 → C2.1 (**Prop 1 discharged**) | B2.3 |
| 12–14 | D (early) | D2.0 → D2.1 → D2.2 → D1.1 → D1.2 → D1.3 → D1.4 | C2.1 |
| 15–22 | D (deep) | D1.5 → D1.6 → D2.3 → D2.4 (**critical**) → D1.7 → D1.8 → D2.5 → D3 | D1.4, D2.2 |
| 23–26 | E (early) | E1.1 → E1.2 → E1.3 → E1.4 → E1.5 → E2.1 | D3 |
| 27–30 | E (deep) | E2.2.1 → E2.2.2 → E2.2.3 → E2.2.4 → E2.2.5 → E2.3 → E2.4 → E2.5 | E2.1 |
| 31–33 | F (sigma) | F1.1 → F1.2 → F1.3 | E2.5 |
| 34–36 | F (arrow) | F2.1 → F2.2.1 → F2.2.2 → F2.2.3 → F2.3.1 → F2.3.2 → F2.3.3 → F2.3.4 → F2.3.5 → F2.4 | F1.3 |
| 37–39 | G | G1.1 → G1.2 → G2.1 (**workstream complete**) | F2.4 |

Total calendar time: **39 weeks (~9 months)** for the full
workstream at sustained focused effort. **Half-way milestone
at week 11 (Prop 1 discharged)** delivers significant
cryptographic value independently.

---

## Appendix D — Deferred-discharge contingency planning

If Phases D, E, or F stall mid-discharge, the workstream can
land **partial closures** at well-defined boundaries:

### Option D-stall (fall-back at week 22 if Phase D stalls)

* **Delivered.** Phases A, B, C complete (~2,200 LOC). Prop 1
  discharged unconditionally.
* **Not delivered.** Prop 2 remains research-scope.
* **Cryptographic value.** Stage 3's
  `partition_preserving_perm_under_GL3` becomes unconditional.
  Stage 5's `quiverPermAlgEquiv`-based forward iff and the
  conditional rigidity infrastructure remain accessible to
  consumers; the Karp reduction inhabitant remains conditional
  on Prop 2.
* **Patch version.** `lakefile.lean` bumped from `0.1.21` to
  `0.1.22-rc1` (release candidate; final `0.1.22` reserved
  for the full Phase G landing).
* **Documentation.** `CLAUDE.md`'s headline table reclassifies
  every Stage-3 / Stage-5 theorem that depends solely on Prop 1
  from **Conditional** to **Standalone**. Theorems depending
  on Prop 2 retain **Conditional** with an explicit "tracked
  as Phase D-G research-scope follow-up" note.

### Option E-stall (fall-back at week 30 if Phase E stalls)

* **Delivered.** Phases A, B, C, D complete (~3,600 LOC).
* **Not delivered.** Phase E's AlgEquiv lift is incomplete.
* **Mitigation strategy.** Phase E's complexity is concentrated
  in sub-layer E2.2 (basis-level multiplicativity). If E2.2.4
  (arrow × arrow case) stalls, the J²=0 Submodule-level lift
  may need additional Mathlib infrastructure. Pause E2.2.4 and
  push on Phase F via an intermediate `gl3OnPathBlock_to_lin`
  (linear map only, not AlgEquiv) — Phase F can sometimes
  proceed with a strict AlgHom rather than AlgEquiv. (This is
  a higher-risk pivot.)
* **Patch version.** `lakefile.lean` bumped to `0.1.22-rc2`.

### Option F-stall (fall-back at week 36 if Phase F stalls)

* **Delivered.** Phases A–E complete (~4,700 LOC).
* **Not delivered.** Phase F's σ extraction + arrow analysis
  stalled.
* **Cryptographic value.** The full AlgEquiv lift from GL³ is
  available; only the algebraic-rigidity content (σ extraction
  via WM + arrow-action analysis) remains. Downstream consumers
  can use `gl3OnPathBlock_to_algEquiv` directly without
  threading σ.
* **Patch version.** `lakefile.lean` bumped to `0.1.22-rc3`.

In each fall-back scenario, the partial closure is a useful,
publishable Lean artefact. The workstream's **independent-
landing** structure ensures no all-or-nothing risk: every phase
delivers concrete value if landed, and partial landings deliver
genuine cryptographic content.

---

## Appendix E — Audit-script extension index

For each new public declaration, an `#print axioms` entry must
be added to `scripts/audit_phase_16.lean`. The entries are
organised into per-phase namespaces inside the audit script.

| Phase | Audit-script section | New `#print axioms` entries | New `example` witnesses |
|-------|---------------------|-----------------------------|-------------------------|
| A | `§ R-TI-Phase-A` | ~20 (slab definitions, multisets, smul lemmas) | 4 (identity-case + non-trivial g) |
| B | `§ R-TI-Phase-B` | ~15 (joint signature, multiset, smul) | 3 |
| C | `§ R-TI-Phase-C` | ~12 (per-slot signatures, count agreement) | 3 (Prop 1 discharge witness) |
| D | `§ R-TI-Phase-D` | ~25 (off-diagonal vanishing, block decomposition) | 4 |
| E | `§ R-TI-Phase-E` | ~20 (subspace identification, AlgEquiv) | 4 |
| F | `§ R-TI-Phase-F` | ~15 (sigma extraction, arrow scalar) | 3 |
| G | `§ R-TI-Phase-G` | ~6 (final discharges, Karp reduction) | 3 (final non-vacuity) |
| **Total** | | **~113** | **~24** |

Total audit-script growth: from current 770 declarations to
~880 (post-Phase-G).

Each entry is parsed by the CI's de-wrapping Perl regex; per
CLAUDE.md the standard-trio constraint is enforced
(`propext`, `Classical.choice`, `Quot.sound` only; no
`sorryAx`, no custom axioms).
