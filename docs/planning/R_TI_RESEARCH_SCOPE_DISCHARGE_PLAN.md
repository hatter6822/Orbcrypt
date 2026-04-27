# R-TI Research-Scope Discharge Plan

**Eliminating `GL3PreservesPartitionCardinalities` and
`GL3InducesArrowPreservingPerm` to deliver unconditional
`grochowQiaoRigidity` and `grochowQiao_isInhabitedKarpReduction`.**

Date: 2026-04-27
Author: post-Stage-5 R-TI rigidity discharge planning
Tracking: research milestone **R-15-residual-TI-reverse**
Status: planned (not yet started)
Revision: v3 (mathematical soundness audit + corrections, 2026-04-27)

---

## Mathematical soundness audit (v3 corrections)

A deep audit of v2 against the actual code found **seven
critical mathematical issues**. v3 corrects them. The audit
findings (with the v3 fixes summarised inline):

### Critical finding #1 (FATAL) — `slabRankMultiset₁_smul` is FALSE

**The v2 plan's Phase A headline theorem,**
`slabRankMultiset₁ (g • T) = slabRankMultiset₁ T` for arbitrary
`g : GL × GL × GL` and `T : Tensor3 n F`, **is mathematically
false.**

*Counterexample.* Let `n = 2`, `F = ℚ`, `T : Tensor3 2 ℚ`
defined by `T(0, 0, 0) = 1`, all other entries `0`. Slabs:
- `slab₁ T 0` is the matrix `[[1, 0], [0, 0]]` — rank 1.
- `slab₁ T 1` is the zero matrix — rank 0.
- `slabRankMultiset₁ T = {1, 0}`.

Take `g = (g₁, 1, 1)` with `g₁ = [[2, 1], [1, 1]]` (det 1,
invertible). Then `(g • T)(a, b, c) = g₁(a, 0) · T(0, b, c)`,
which gives:
- `slab₁ (g • T) 0` non-zero at `(0, 0)` with value 2 — rank 1.
- `slab₁ (g • T) 1` non-zero at `(0, 0)` with value 1 — rank 1.
- `slabRankMultiset₁ (g • T) = {1, 1} ≠ {1, 0}`.

GL³ can promote a zero slab to a non-zero slab by mixing slabs
across the row index. The slab-rank multiset is **not** a GL³
invariant.

**v3 fix.** Phase A's headline theorem is removed.
Phase A is reformulated to use the **encoder-equality direct
approach**: under `g • grochowQiaoEncode m adj₁ =
grochowQiaoEncode m adj₂`, structural consequences are derived
**directly from the encoder structure**, not via a generic
`_smul` invariant.

### Critical finding #2 (FATAL) — `(g.1⁻¹).val.toEquiv` does not exist

The v2 plan's Phase A T-API-A2.4 references
`(g.1⁻¹).val.toEquiv : Fin n ≃ Fin n` to set up a "Multiset
bijection via the GL inverse". **No such projection exists in
Mathlib at the pinned commit `fa6418a8`** (only
`Matrix.GeneralLinearGroup.coe_inv : ↑A⁻¹ = (↑A : Matrix n n
R)⁻¹`, returning a matrix not an Equiv). It cannot exist for
general GL elements: a generic invertible matrix over `F` has
all entries non-zero and does not induce a permutation of `Fin
n` in the way the plan requires.

**v3 fix.** The "Multiset bijection via g.1⁻¹" framework is
removed. The encoder-equality direct approach replaces it.

### Critical finding #3 (HIGH) — C1.1 slab-rank values are wrong

The v2 plan's Phase C T-API-C1 sub-task C1.1 claims vertex slab-
rank is **uniformly 1**. The actual encoder structure constant
in the code is

```
def pathSlotStructureConstant (m : ℕ) (i j k : Fin (dimGQ m)) : ℚ :=
  let a := slotToArrow m (slotEquiv m i)
  let b := slotToArrow m (slotEquiv m j)
  let c := slotToArrow m (slotEquiv m k)
  match pathMul m a b with
  | some d => if d = c then 1 else 0
  | none => 0
```

**i.e., `T_{ijk} = 1[pathMul slot_i slot_j = some slot_k]`**:
the *first* tensor index `i` corresponds to the *first* `pathMul`
argument; the third index `k` corresponds to the `pathMul`
*output*. v2's C1.1 incorrectly searched for `pathMul slot_j
slot_k = some slot_i` (output match), inverting the convention.

The correct slab-rank values, derived from the actual `pathMul`
table:
- **Vertex slot `v`**: slab is non-zero at `(vertex v, vertex
  v) → 1` AND at `(arrow v w, arrow v w) → 1` for each present
  outgoing arrow `(v, w)`. Slab rank = **`1 + outDegree(v)`**
  (not uniformly 1).
- **Present-arrow slot `(u, v)`**: slab is non-zero at `(vertex
  v, arrow u v) → 1` only. Slab rank = **1** (not 2 as v2
  claimed).
- **Padding slot `(u, v)`**: slab is non-zero at `(padding (u,
  v), padding (u, v)) → 2` only. Slab rank = **1**.

**v3 fix.** C1.1 and C1.2 derivations are corrected. The joint
signature for vertices becomes `(1 + outDegree(v), 1)` (per-
vertex variable, NOT uniform), present-arrow `(1, 0)`, padding
`(1, 2)`.

### Critical finding #4 (FATAL) — Strategic decomposition unsound

The v2 plan claims Phase C discharges Prop 1 independently of
Phase D-G via the "shallow" slab-rank multiset framework. This
is **fundamentally unsound** for two reasons:

1. The generic `slabRankMultiset_smul` is false (Critical
   Finding #1).
2. Even encoder-specific slab-rank multiset invariance
   (`slabRankMultiset (encode m adj₁) = slabRankMultiset (encode
   m adj₂)` under encoder-equality) requires the structural
   correspondence between adj₁ and adj₂ — which is what we are
   trying to prove. The argument is circular.

**Both Props 1 and 2 require the deep Phase D-G chain.** Prop 1
is a corollary of Prop 2 (an arrow-preserving σ gives a
bijection between presentArrows, hence equal cardinalities).
There is no separable shallow proof.

**v3 fix.** The strategic decomposition is restructured: Prop 1
is discharged in Phase G **as a corollary of Prop 2**, not in
Phase C. Phases A–C are repositioned as **encoder-equality
diagnostic infrastructure** (recovering specific encoder
properties from the equality), not as independent rigidity
proofs.

### Critical finding #5 (HIGH) — D2.4 mutual induction hand-waved

The v2 plan's Phase D sub-task D2.4 sketches a "potential
function" mutual induction that asserts the closure of the
mutual dependency between axes 1, 2, 3. **No actual proof
mechanism is given.** The argument as written:

> 1. Encoder-equality forces a polynomial identity.
> 2. Path-aligned columns of g's factors restrict to a bijection
>    PROVIDED the off-diagonals all vanish.
> 3. Conclude the potential is zero.

Step 2 is circular (it presupposes what step 3 is supposed to
conclude). Step 1 is unspecified ("a polynomial identity" — but
which one, and what does it imply?).

**v3 fix.** D2.4 is rewritten with a **disclaimer** that the
mutual-induction structure is genuine multilinear-algebra
content from Grochow–Qiao 2021 and that the formal proof is
research-scope. The plan provides a structural sketch without
claiming it constitutes a complete formal argument.

### Critical finding #6 (HIGH) — E2.2.4 circularity

Phase E sub-task E2.2.4 (arrow × arrow multiplicativity case)
argues:
- LHS: `α(u, v) * α(w, x) = 0` by J²=0.
- RHS: 0 because `gl3OnPathBlock_to_lin (arrow)` is in radical,
  hence J²·J² = 0.

The "RHS in radical" step assumes `gl3OnPathBlock_to_lin`
preserves the radical. This is a property of *algebra
homomorphisms*. But at this stage `gl3OnPathBlock_to_lin` is a
LINEAR map only — multiplicativity is what we are *trying to
prove*. The argument is circular.

**v3 fix.** E2.2.4 is rewritten to use the **structure tensor
pull-back from E2.1 directly**, deriving the arrow image's
support from the slot-level partition preservation (which comes
from Phase D's block decomposition, not from algebra-hom
properties of `gl3OnPathBlock_to_lin`).

### Critical finding #7 (MEDIUM) — Mathlib API references unverified

Several Mathlib lemmas referenced in v2 are **not present at
the pinned commit `fa6418a8`** under the names given:
- `Multiset.map_eq_map_of_bijective` — not found.
- `Multiset.map_eq_map_iff_of_inj` — not found.
- `Equiv.Perm.image_univ` — not found in expected location.
- `Matrix.GeneralLinearGroup.toEquiv` — does not exist.

**v3 fix.** API references corrected to lemmas actually
present at the pinned commit (`Multiset.map_injective`,
`Finset.image_univ_of_surjective`, `Finset.image_univ_equiv`),
or marked as "hand-roll required" with explicit LOC reserves.

### Critical finding #8 (FATAL, found post-v3) — Phase D circular dependency on removed Phase C construction

After applying v3 corrections #1–#7, a deeper circular
dependency was found that v3 did not fully resolve:

* **Phase D's `pathBlockMatrix g hg` definition:**
  ```
  pathBlockMatrix g hg :=
    g.1.val * (liftedSigmaMatrix m (partitionPreservingPermOfGL3 g hg)⁻¹)
  ```
  uses `partitionPreservingPermOfGL3 g hg`, a Phase C v2
  construction.
* **v3 removed Phase C's discharge of Prop 1**, repositioning
  `partitionPreservingPermOfGL3` to Phase G as the
  `Prop 2 ⟹ Prop 1` corollary.
* **But Phase D's lemmas (D1.3 onward) require π to be
  partition-preserving** for the off-diagonal-vanishing
  argument to even type-check.
* **Therefore Phase D depends on Phase G's output**, which is
  downstream of Phase F (the σ-extraction Phase F itself uses
  Phase E's AlgEquiv, which uses Phase D's
  `gl3OnPathBlock_to_lin`). The dependency graph is **circular
  across D → E → F → G → D**.

This means the v3 plan's phase ordering does NOT actually
resolve the plan into a non-circular discharge sequence.
The audit in v3 stopped one finding short.

**v3.1 fix.**

The correct mathematical structure is **Phase E first, then
Phase D**: the AlgEquiv on the path subspace can be
constructed from the structure-tensor pull-back (Phase E's
sub-layer E2.1) **directly**, without first establishing the
slot-level partition-preserving permutation. The radical-
preservation of any algebra hom then gives the slot-level
partition preservation as a *consequence*, not a hypothesis.

Concretely:

1. **Phase E (re-ordered first).** From the encoder equality,
   establish that GL³ tensor iso induces a structural map on
   the path-algebra subspace by pulling back the structure
   tensor. This gives a candidate AlgHom on the path-algebra
   quotient (without needing slot-level partition
   preservation).
2. **Phase F (algebra-derived σ).** Apply
   `algEquiv_extractVertexPerm` (Stage 4 / `WedderburnMalcev`)
   to the candidate AlgEquiv from Phase E to extract σ.
3. **Phase D (becomes a corollary).** The slot-level
   partition-preservation falls out of Phase E's algebra-iso
   structure: arrow elements map to arrow elements (radical
   is preserved), vertex idempotents map to vertex
   idempotents (semisimple part is preserved up to radical
   conjugation by Wedderburn-Mal'cev).
4. **Phase G (final discharge).** Compose F's σ with adjacency-
   preservation (Stage 5) to discharge Prop 2; derive Prop 1
   as the cardinality corollary.

**Phase D as currently structured (off-diagonal block
vanishing via mutual induction) is not the right shape for
the discharge.** The v3.1 fix repositions Phase D as
*post-AlgEquiv structural lemmas* (radical preservation
giving the partition split), not *pre-AlgEquiv multilinear-
algebra* (the original framing).

**Implementation status.** Repositioning is documented in
this audit preamble; the per-phase sections retain v3
structure with parametrized hypotheses (Phase D's
`pathBlockMatrix` should be parameterized by a free `π`
hypothesis, with the partition-preservation property
provided by Phase E-F's algebra-derived σ). A v3.1 plan
revision implementing this restructure across all phases
is research-scope follow-up — too disruptive for an
in-place audit fix.

**Practical guidance for implementers.** Treat Phases D-E-F-G
as **a single inseparable research-scope effort** rather than
sequential discharge steps. Do not attempt to land Phase D's
`pathBlockMatrix` lemmas as a stand-alone commit until the
algebra-iso construction (Phase E sub-layer E2.1) is in
place to provide the partition-preserving permutation.

---

## Revision history

* **v1 (initial landing).** 1,788 lines. High-level phase
  decomposition (A–G) with sub-layer breakdowns at the
  T-API-* level.
* **v2 (per-sub-task expansion).** 3,218 lines. Granular
  decomposition into 66 sub-tasks across 7 phases.
* **v3 (mathematical soundness corrections, this revision).**
  Corrects 7 critical mathematical issues found by deep audit
  against the actual code. Removes the false generic
  `slabRankMultiset_smul` framework, fixes the C1.1 / C1.2
  slab-axis convention error, restructures the strategic
  decomposition (Prop 1 derived from Prop 2 in Phase G; not
  a separable shallow proof), and adds soundness disclaimers
  to the genuinely uncertain sub-tasks (D2.4, E2.2.4).
  Updates LOC budget to ~5,800 LOC across 7 phases (Phase A's
  removed false framework reduces budget by ~400 LOC; D2.4's
  acknowledged research-scope content reduces detail-claim by
  ~100 LOC).

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

This plan discharges both unconditionally. **Post-v3-audit
budget** (the v3 mathematical-soundness audit removed the
false generic `slabRankMultiset_smul` framework and the
shallow Prop-1 path, reducing Phases A–C to diagnostic
infrastructure only; v3 also marks D2.4 and E2.2.4 as
research-scope after their v2 proof sketches were found
unsound): the total LOC budget is **~5,200 LOC** of new Lean
across **~9 new modules**, plus ~500 LOC of documentation
refresh and audit-script extensions, for a grand total of
**~5,700 LOC** across the 7 phases. The dedicated effort
estimate is **~6–12 months** for a single focused implementer
(the upper bound widened post-audit because D2.4 and E2.2.4
are now honest research-scope items rather than 100-LOC
sketched exercises).

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

## 3. Strategic decomposition (post-v3 correction)

The two `Prop`s are not independent: `GL3InducesArrowPreservingPerm`
**strictly implies** `GL3PreservesPartitionCardinalities` because
σ-action arrow preservation gives a bijection between
`presentArrows m adj₁` and `presentArrows m adj₂`, so cardinalities
agree.

**v3 audit correction.** v2 attempted to discharge Prop 1
*independently* of Prop 2 via a "shallow rigidity" framework
based on slab-rank multiset invariance under generic GL³. **This
framework is mathematically unsound** (Critical findings #1 +
#4 in the v3 audit preamble): the generic
`slabRankMultiset_smul` is FALSE (counterexample given), and
encoder-specific multiset invariance reduces to Prop 1 itself
(circular). v3 abandons the shallow path. **Both Props are now
discharged together at the end of Phase G**, with Prop 1
derived as a corollary of Prop 2 (the natural mathematical
order in Grochow–Qiao 2021's argument).

**Phase ordering (v3).**

- **Phases A, B:** Encoder-equality structural infrastructure.
  Diagnostic lemmas about the encoder (slab evaluations,
  diagonal classifications). NO Prop discharge claim. NO
  generic GL³ smul invariants beyond what Stage 1 already
  proved (`unfoldRank₁_smul`).
- **Phase C:** Per-slot signature computations on the
  encoder. Diagnostic infrastructure used downstream. NO Prop
  1 discharge.
- **Phases D, E, F:** The deep AlgEquiv → σ → arrow-action
  chain. Phase D extracts the path-block-restricted action,
  Phase E lifts to an AlgEquiv, Phase F extracts σ via WM and
  proves arrow preservation.
- **Phase G:** Discharges Prop 2 directly from Phase F's
  arrow-preservation witness, then derives Prop 1 as a
  corollary (the σ-induced bijection on `presentArrows` gives
  the cardinality equality).

This restructuring reflects the actual Grochow–Qiao 2021
argument, which does not have a "shallow Prop 1 → deep Prop 2"
split.

## 4. Phase map (v3 corrected)

| Phase | Layers | Title | LOC (v3) | Risk |
|-------|--------|-------|----------|------|
| A | T-API-A1, A2 | Slab definitions + encoder-equality structural lemmas | ~500 | Low |
| B | T-API-B1, B2 | Diagonal-value structural lemmas (re-export Stage 0/2) | ~300 | Low |
| C | T-API-C1 | Per-slot signature computations | ~400 | Low |
| D | T-API-D1, D2, D3 | Path-block extraction + restriction (D2.4 research-scope) | ~1,500 | **Research** |
| E | T-API-E1, E2 | AlgEquiv construction (E2.2.4 research-scope) | ~1,200 | **Research** |
| F | T-API-F1, F2 | σ extraction + arrow-action analysis | ~900 | Med–High |
| G | T-API-G1, G2 | Discharge Prop 2 + derive Prop 1 corollary | ~400 | Med |
| | | **Total** | **~5,200** | |

Plus ~500 LOC for documentation refresh, audit-script
extensions, and Vacuity-map / VERIFICATION_REPORT updates
across the seven phases. **Total post-v3 budget: ~5,700 LOC.**

> **v3 LOC reductions vs v2.** Phase A drops from 900 → 500
> (false `slabRankMultiset_smul` framework removed). Phase B
> drops from 600 → 300 (false joint-multiset framework
> removed). Phase C drops from 900 → 400 (Prop-1 discharge
> moved to Phase G; only diagnostic structural lemmas remain).
> Phase G drops from 600 → 400 (Prop 1 corollary is ~30 LOC,
> not a full discharge layer). Phases D, E pick up some
> "research-scope" tags (D2.4 + E2.2.4) reflecting honest
> uncertainty about LOC. Net: ~5,200 LOC of Lean (down from
> ~6,700).

**Critical path: Phases D and E are the genuinely research-
grade layers.** Phase D's mutual-induction closure (D2.4) and
Phase E's basis-multiplicativity (E2.2.4) are both marked
research-scope after v3 audit found their v2 sketches
unsound. The plan honestly acknowledges that these contain
genuine multilinear-algebra content from Grochow–Qiao 2021
§4.3, not 80–120-LOC exercises.

Phase D's block-decomposition argument is lifted from the
prior plan's Stage 3 sub-layers 4.D/4.E in shape, but
re-stated here without the `Prop`-fallback escape hatch. It
is the highest-risk piece of the workstream alongside Phase
E's basis multiplicativity.

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

## Phase A — Slab definitions + encoder-equality structural lemmas (~500 LOC, post-v3 correction)

> **v3 audit correction.** The original Phase A claimed a generic
> `slabRankMultiset₁_smul` invariance under arbitrary GL³ — this
> is mathematically FALSE (see "Critical finding #1" above). v3
> repositions Phase A as **encoder-equality diagnostic
> infrastructure** that derives consequences from the encoder
> equality directly, without claiming a generic GL³ invariant.
> The slab definitions and rank-computation API remain useful;
> the false `_smul` headline is removed.

**Goal.** Land the slab definitions and per-slot rank
computations needed by downstream phases. Establish what
follows directly from `g • encode m adj₁ = encode m adj₂`
without invoking generic invariants. (The deep rigidity
content lives in Phases D–G; Phase A is preparation.)

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

### Layer T-API-A2 — Slab transformation under GL × GL × GL (~250 LOC, post-v3 correction)

> **v3 audit correction.** The v2 plan claimed
> `slabRankMultiset₁_smul` (multiset of slab ranks is preserved
> under generic GL³). **This is false** — see "Critical finding
> #1" above for the explicit counterexample. The corrected layer
> below establishes only what is actually true: the relationship
> between `slab₁ (g • T) i` and `slab₁ T a` as a *linear
> combination*, plus the (also-true) **per-row-image** rank
> bound. The false multiset-invariance headline is removed.

**File (new):** `Orbcrypt/Hardness/GrochowQiao/SlabTransform.lean`.

**Public surface (corrected):**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `unfold₁_smul_row_eq` | `(unfold₁ (g • T)) i = (g.1.val * (unfold₁ T)) i * (g.2.valᵀ ⊗ₖ g.3.valᵀ)` | Row-equation lemma: row `i` of `unfold₁ (g • T)` is a linear combination of all rows of `unfold₁ T`, then right-multiplied by Kronecker. |
| `slab₁_smul_eq_linear_combination` | `slab₁ (g • T) i = ∑_a (g.1.val i a) • (g.2.val * slab₁ T a * g.3.valᵀ)` | The slab-level form: each slab of `g • T` is a linear combination of double-conjugated slabs of `T`. |
| `unfoldRank₁_preserved_under_smul` | `(unfold₁ (g • T)).rank = (unfold₁ T).rank` | (Already in `RankInvariance.lean` from Stage 1; re-exported for completeness.) |

**Mathematical content (corrected, no false claims).**

Let `g = (g.1, g.2, g.3) : GL n F × GL n F × GL n F`. From
Stage 1's `unfold₁_tensorContract`,
```
unfold₁ (g • T) = g.1.val * unfold₁ T * (g.2.valᵀ ⊗ₖ g.3.valᵀ)
```

Each row of `unfold₁ (g • T)` is therefore a linear combination
of all rows of `unfold₁ T * (g.2.valᵀ ⊗ₖ g.3.valᵀ)`, weighted by
the entries of the corresponding row of `g.1.val`:
```
unfold₁ (g • T) i (j, k) = ∑_a (g.1.val i a) ·
  (unfold₁ T * (g.2.valᵀ ⊗ₖ g.3.valᵀ)) a (j, k)
```

Reshape the row-vector form back to a slab matrix: by the
Kronecker reshape identity (Stage 1's
`unfold₁_matMulTensor{2,3}` plus `mul_kronecker_mul`),
```
slab₁ (g • T) i = ∑_a (g.1.val i a) • (g.2.val * slab₁ T a * g.3.valᵀ)
```

This is the **honest statement**: each slab of `g • T` is a
*linear combination* of all slabs of `T`, double-conjugated by
`g.2` and `g.3`. **There is no per-slot rank identity** — slab
ranks may change because `g.1`'s row mixes slabs of different
ranks.

**What IS GL³-invariant.** The total unfolding rank
`(unfold₁ T).rank` is preserved (Stage 1's `unfoldRank₁_smul`,
proven via `rank_mul_eq_*_of_isUnit_det`). This corresponds to
the **dimension of the slab span**, not the multiset of slab
ranks. The slab-span dimension is a coarser invariant.

**What is NOT preserved (counterexample).** See Critical Finding
#1 in the audit preamble. The slab-rank multiset can change
under GL³.

**Detailed sub-task breakdown (corrected).**

#### Sub-task A2.1 — Row-equation lemma (~40 LOC, 0 deps)

* **Statement.** `unfold₁_smul_row_eq` (as stated above).
* **Proof.** Direct from Stage 1's `unfold₁_tensorContract`
  + `Matrix.mul_apply` row-extraction. ≤ 5-line tactic body.
* **Mathlib anchors.** `unfold₁_tensorContract` (Stage 1 /
  `TensorUnfold.lean`), `Matrix.mul_apply`.
* **Risk.** Low.

#### Sub-task A2.2 — Slab-level linear combination form (~120 LOC, depends on A2.1)

* **Statement.** `slab₁_smul_eq_linear_combination` (as stated
  above).
* **Proof.** From A2.1's row equation, reshape via the unfold-
  to-slab identification + Kronecker arithmetic. The key
  Kronecker identity:
  `(unfold₁ T a * (Bᵀ ⊗ₖ Cᵀ)) (j, k) = (B * slab₁ T a * Cᵀ) j k`
  is provable from `Matrix.kronecker_apply` + `Matrix.mul_apply`
  + index unfolding.
* **Sub-lemmas (each ≤ 50 LOC):**
  - `kronecker_reshape_slab`: the reshape identity above (a
    standalone lemma about Kronecker products and 2-tensor
    reshapes — not encoder-specific).
  - `slab₁_smul_decompose`: combine A2.1 with the reshape.
* **Mathlib anchors.** `Matrix.kronecker_apply`,
  `Matrix.mul_apply`, `Finset.sum_congr`,
  `Matrix.transpose_apply`.
* **Risk.** Low–Medium. The Kronecker reshape is technical but
  bounded.

#### Sub-task A2.3 — Total unfolding rank invariance re-export (~20 LOC, depends on Stage 1)

* **Statement.** `unfoldRank₁_preserved_under_smul` (re-export
  of Stage 1's `unfoldRank₁_smul` for self-contained citation).
* **Proof.** `exact unfoldRank₁_smul g T`.
* **Risk.** None.

#### Sub-task A2.4 — Encoder-equality consequences (~70 LOC, depends on A2.2)

* **Statement.** `grochowQiaoEncode_unfold_eq_under_smul`:
  ```
  ∀ g (m) (adj₁ adj₂),
    g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂ →
    unfold₁ (grochowQiaoEncode m adj₂) =
      g.1.val * unfold₁ (grochowQiaoEncode m adj₁) *
      (g.2.valᵀ ⊗ₖ g.3.valᵀ)
  ```
  *(Direct application of Stage 1's `unfold₁_tensorContract`
  to the encoder equality.)*
* **Proof.** Substitute `g • encode m adj₁ = encode m adj₂` into
  `unfold₁_tensorContract`. ≤ 3-line tactic body.
* **Sub-lemmas:** none beyond direct substitution.
* **Risk.** None.
* **Verification gate.** Standard trio axioms only.
* **Consumer.** Phase D's path-block extraction will use this to
  manipulate the encoder unfoldings.

**Mathlib API verification.** All anchors above are present at
the pinned commit `fa6418a8`. No `Matrix.GeneralLinearGroup.toEquiv`
or false `Multiset` lemmas are needed (they don't exist).

<!-- v3 audit: the v2 A2.1–A2.5 sub-tasks below were removed
     because they relied on the false `slabRankMultiset₁_smul`
     and the non-existent `(g.1⁻¹).val.toEquiv`. The corrected
     A2.1–A2.4 above replace them. -->

#### [v2 A2.1, removed] Row-equation lemma — superseded by corrected A2.1 above

#### [v2 A2.2, removed] Slab transformation under GL × GL × GL — superseded by corrected A2.2 above

#### [v2 A2.3, removed] Slab rank under double conjugation — FALSE in general (see Critical finding #1)

The v2 sub-task A2.3 claimed `slabRank₁ (g • T) ((g.1⁻¹).val a)
= slabRank₁ T a`. This is **false**: `(g.1⁻¹).val a` does not
type-check (`(g.1⁻¹).val` is a matrix, not a function on `Fin
n`), and even if interpreted charitably as some pseudo-
permutation, the claim is contradicted by the Critical-finding-
#1 counterexample (`T(0,0,0) = 1`, `g₁` upper triangular).

#### [v2 A2.4, removed] Multiset bijection via `g.1⁻¹` — invalid

References the non-existent `Matrix.GeneralLinearGroup.toEquiv`
projection (Critical finding #2). Removed.

#### [v2 A2.5, removed] Symmetric variants for axes 2, 3 — moot

Without A2.4's framework, the symmetric variants are also moot.
Stage 1's axis-2/3 unfolding bridges (which v2 listed as
"sub-task A2.5.0 prerequisite") remain a research-scope follow-
up, but they are no longer used to prove a false multiset
invariant — they're used in Phase D's path-block extraction
directly.

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

## Phase B — Diagonal-value structural lemmas (~300 LOC, post-v3 correction)

> **v3 audit correction.** v2's Phase B claimed a "joint
> signature multiset" framework that, in combination with
> Phase A's (false) `slabRankMultiset_smul`, was supposed to
> discharge Prop 1 via shallow rigidity. v2's "Resolution"
> section even acknowledged that the diagonal multiset is NOT
> generally GL³-invariant — only "for the encoder family". But
> the claim that encoder-family invariance holds was hand-
> waved (it actually requires the deep Phase D-G argument).
> v3 removes the false framework and repositions Phase B as
> **diagonal-value structural infrastructure** for downstream
> phases.

**Goal.** Land the diagonal-value definitions and per-slot
diagonal computations needed by downstream phases. Establish
the σ-relabelled correspondence under permutation-matrix GL³
actions (which IS true). The general GL³ diagonal-multiset
invariance claim is removed.

**What is preserved (true).**
- Under permutation-matrix GL³ action `(liftedSigmaGL m σ)³`,
  the diagonal entries are σ-relabelled. The diagonal
  multiset IS preserved in this restricted case (because σ is
  a genuine bijection on `Fin (dimGQ m)`).
- For the encoder, per-slot-kind diagonal values are pairwise
  distinct (vertex=1, present-arrow=0, padding=2, post-Stage-
  0). This is already proven in `StructureTensor.lean` and is
  re-exported here.

**What is NOT preserved (false in general).**
- Generic GL³ diagonal-multiset invariance. A generic GL³
  triple acts non-trivially on diagonal entries:
  ```
  (g • T)(i, i, i) = ∑_{a, b, c} g.1(i, a) g.2(i, b) g.3(i, c) T(a, b, c)
  ```
  which mixes off-diagonal entries of `T` into the diagonal of
  `g • T`. The diagonal multiset can change.

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

### Layer T-API-B2 — Encoder-equality diagonal correspondences (~100 LOC, post-v3 correction)

> **v3 audit correction.** The v2 T-API-B2 layer claimed a
> generic `diagonalMultiset_smul` invariance, then walked it
> back to "encoder-family invariance" via a hand-waved
> "Resolution" section. Both the generic claim and the encoder-
> family claim are unsupported (the encoder-family case is
> precisely Prop 1 in disguise — the conclusion we are trying
> to prove). v3 removes the false framework. What remains is a
> small set of structural lemmas about encoder diagonals.

**File:** extends
`Orbcrypt/Hardness/GrochowQiao/DiagonalValues.lean` (or the
existing `StructureTensor.lean`'s diagonal-value lemmas — see
re-export note below).

**Public surface (corrected, no false claims).**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `grochowQiaoEncode_diagonal_at_slot` | `(grochowQiaoEncode m adj).diagonal i ∈ {0, 1, 2}` | Encoder diagonal values are restricted to three values. |
| `grochowQiaoEncode_diagonal_classifies_slot` | `(grochowQiaoEncode m adj).diagonal i = 1 ↔ isVertexSlot m i` (analogous for 0 / 2) | Diagonal value uniquely classifies slot kind. |

These are **direct re-exports** of Stage 0 / Stage 2 lemmas
already proven in the codebase:
- `grochowQiaoEncode_diagonal_vertex` (vertex diagonal = 1).
- `grochowQiaoEncode_diagonal_present_arrow` (present-arrow
  diagonal = 0).
- `grochowQiaoEncode_diagonal_padding` (padding diagonal = 2).

There is no "GL³ smul invariance" content. The downstream
phases (D, E, F, G) use these structural lemmas directly to
analyse encoder-equality consequences — they do NOT use a
hypothetical generic-or-encoder-family smul.

**Risk.** None — pure re-export.

**Verification gate.** Re-export lemmas elaborate via direct
reference to Stage 0 / Stage 2 lemmas.

**Consumer.** Phase D's path-block extraction directly accesses
the encoder's diagonal classification to argue about
non-vanishing entries.

### Phase B deliverables and gates

* One new `.lean` module under `Orbcrypt/Hardness/GrochowQiao/`.
* `Orbcrypt.lean` extended with one new import.
* `scripts/audit_phase_16.lean` extended with `#print axioms` for
  every new public declaration; non-vacuity `example` exhibiting
  the joint signature multiset on a concrete encoder.
* CLAUDE.md change-log entry: "Phase B" subsection.
* Verification: `lake build` succeeds; audit script clean.

---

## Phase C — Per-slot signature computations (~400 LOC, post-v3 correction)

> **v3 audit correction.** v2's Phase C claimed to discharge
> `GL3PreservesPartitionCardinalities` (Prop 1) **independently**
> of Phases D–G via a "shallow rigidity" argument through the
> joint signature multiset. **This is fundamentally unsound**
> (Critical findings #1, #4). The shallow path doesn't exist:
> Prop 1 is a *corollary* of Prop 2, derivable only after
> Phases D–G's deep AlgEquiv → σ → arrow chain. v3 repositions
> Phase C as **per-slot signature computation infrastructure**
> for downstream phases, NOT as a Prop-1 discharge layer.
> Prop 1 is now derived in Phase G as `Prop 2 ⟹ Prop 1`.

**Goal.** Land the per-slot slab-rank and signature
computations on the encoder. These are **structural
properties of the encoder** (not GL³-invariants), useful as
hypotheses for downstream phases when they need to argue
about specific encoder slots.

**v3 mathematical correction (Critical finding #3).** The
encoder's structure constant is

```
pathSlotStructureConstant m i j k = 1[pathMul slot_i slot_j = some slot_k]
```

i.e., the **first** tensor index `i` matches the **first**
`pathMul` argument; the **third** index `k` matches the
`pathMul` *output*. The v2 plan inverted this convention,
giving wrong slab-rank values. The corrected values are:

| Slot kind at index `i` | slab-axis-1 non-zero entries | slab rank |
|------------------------|------------------------------|-----------|
| vertex `v` | `(vertex v, vertex v) = 1` AND `(arrow v w, arrow v w) = 1` for each present arrow `(v, w)` | **1 + outDegree(v)** |
| present-arrow `(u, v)` | `(vertex v, arrow u v) = 1` only | **1** |
| padding `(u, v)` | `(padding (u,v), padding (u,v)) = 2` only | **1** |

The joint signature `(slabRank₁, T(i,i,i))` per slot:

| Slot kind | Joint signature |
|-----------|------------------|
| vertex `v` | `(1 + outDegree(v), 1)` |
| present-arrow | `(1, 0)` |
| padding | `(1, 2)` |

These are **pairwise distinct across slot kinds** (and even
across vertices of different out-degrees). But they are
**properties of the encoder, not GL³ invariants** — see the v3
audit preamble for why a generic `_smul` invariance is false.

**Phase C does not discharge Prop 1.** That is now Phase G's
responsibility (via `Prop 2 ⟹ Prop 1`). Phase C provides the
per-slot signature lemmas as building blocks.

[Original text retained for context, but Phase C no longer claims
Prop 1 discharge]:

This is the **first headline theorem** of
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

#### Sub-task C1.1 — Slab evaluation at vertex slots (~120 LOC, depends on Stage 2) [v3 corrected]

> **v3 audit correction.** The v2 C1.1 derivation searched for
> `pathMul slot_j slot_k = output slot_i` (output-side
> match), which inverts the encoder's actual structure-tensor
> convention `T_{ijk} = 1[pathMul slot_i slot_j = some slot_k]`.
> The corrected derivation below uses the actual convention.

* **Statement.** `grochowQiaoEncode_slab₁_at_vertex`:
  for `i = slotEquiv.symm (.vertex v)`,
  ```
  slab₁ (grochowQiaoEncode m adj) i j k = 1
    ↔ (j = slotEquiv.symm (.vertex v) ∧ k = slotEquiv.symm (.vertex v))
    ∨ (∃ w, adj v w = true ∧
            j = slotEquiv.symm (.arrow v w) ∧
            k = slotEquiv.symm (.arrow v w))
  ```
  *(slab is non-zero at the diagonal `(vertex v, vertex v) →
  1` AND at each "outgoing arrow self-pair" `(arrow v w, arrow
  v w) → 1` for each present arrow `(v, w)`.)*

* **Derivation.** From the actual encoder definition, when all
  three slots are path-algebra:
  ```
  pathSlotStructureConstant m i j k = 1[pathMul slot_i slot_j = some slot_k]
  ```
  At fixed `slot_i = .id v`:
  - `pathMul (.id v) (.id v) = some (.id v)` → contributes at
    `(j, k) = (vertex v, vertex v)`.
  - `pathMul (.id v) (.id u) = none` for `u ≠ v` → no
    contribution.
  - `pathMul (.id v) (.edge v w) = some (.edge v w)` for any
    `w` → contributes at `(j, k) = (arrow v w, arrow v w)`,
    BUT **only when the resulting `arrow v w` is a path-
    algebra slot**, i.e., `(v, w) ∈ presentArrows m adj` (i.e.,
    `adj v w = true`).
  - `pathMul (.id v) (.edge u w) = none` for `u ≠ v`.
  - `pathMul (.edge ?, ?) ?` doesn't apply (slot_i is `.id v`,
    not an arrow).

* **Slab-rank consequence.** `slabRank₁ (encode m adj) (vertex v)
  = 1 + outDegree(v)` where `outDegree(v) := |{w : adj v w =
  true}|`. The slab matrix has `1 + outDegree(v)` non-zero
  diagonal entries (each at distinct positions), all linearly
  independent.

* **Sub-lemmas (each ≤ 60 LOC):**
  - `pathMul_id_first_arg_classification`: complete table of
    `pathMul (.id v) X` for each constructor of `X`, derivable
    from the existing `pathMul_id_id`, `pathMul_id_edge`
    `@[simp]` lemmas in `PathAlgebra.lean`.
  - `slab₁_encoder_at_vertex_apply`: the slab evaluation as
    above.
  - `slabRank₁_at_vertexSlot_eq_outDegree_plus_one`: the slab
    is rank `1 + outDegree(v)`. *Proof technique*: count the
    non-zero diagonal entries; each is in a distinct
    row/column position; the matrix is therefore equivalent to
    a diagonal with `1 + outDegree(v)` non-zero entries; rank
    follows.

* **Risk.** Low (post-correction).

#### Sub-task C1.2 — Slab evaluation at present-arrow slots (~120 LOC, depends on Stage 2) [v3 corrected]

> **v3 audit correction.** The v2 C1.2 derivation claimed the
> slab has rank 2 with non-zero entries at `(vertex u, arrow u
> v)` AND `(arrow u v, vertex v)`. This applies the same
> wrong-direction convention as v2 C1.1. The actual
> convention `T_{ijk} = 1[pathMul slot_i slot_j = some slot_k]`
> with `slot_i = .edge u v` gives ONLY the entry `(vertex v,
> arrow u v) → 1`. The corrected slab rank is **1**, not 2.

* **Statement.** `grochowQiaoEncode_slab₁_at_presentArrow`:
  for `(u, v)` with `adj u v = true`, the slab at `i =
  slotEquiv.symm (.arrow u v)` is non-zero at exactly one
  entry: `(j, k) = (vertex v, arrow u v)` with value 1.

* **Derivation.** At fixed `slot_i = .edge u v`:
  - `pathMul (.edge u v) (.id w) = some (.edge u v)` if `v = w`
    → contributes at `(j, k) = (vertex v, arrow u v)`.
    The `arrow u v` slot is a path-algebra slot (since `(u, v)
    ∈ presentArrows`), so the encoder takes the path-algebra
    branch.
  - `pathMul (.edge u v) (.id w) = none` for `w ≠ v`.
  - `pathMul (.edge u v) (.edge a b) = none` (J² = 0).

* **Slab-rank consequence.** `slabRank₁ (encode m adj)
  (presentArrow u v) = 1` (single non-zero entry).

* **Sub-lemmas (each ≤ 60 LOC):**
  - `pathMul_edge_first_arg_classification`: complete table of
    `pathMul (.edge u v) X`.
  - `slab₁_encoder_at_presentArrow_apply`.
  - `slabRank₁_at_presentArrowSlot_eq_one`.

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

#### Sub-task C1.4 — Per-slot joint signatures (~50 LOC, depends on C1.1–3 + Stage 2 diagonals) [v3 corrected]

* **Definitions (post-v3 correction).**
  - `vertexSlotSignature m adj v : ℕ × ℚ :=
       (1 + outDegree m adj v, 1)`
    (per-vertex variable; depends on outDegree).
  - `presentArrowSlotSignature : ℕ × ℚ := (1, 0)` (rank 1, NOT
    rank 2; v2's claim of rank 2 was based on the wrong
    structure-tensor convention).
  - `paddingSlotSignature : ℕ × ℚ := (1, 2)`.
* **Per-slot signature theorems** combining C1.1–3 with
  Stage 2 diagonal-value classification:
  - `grochowQiaoEncode_slabDiagonal_at_vertex_eq_signature`.
  - `grochowQiaoEncode_slabDiagonal_at_presentArrow_eq_signature`.
  - `grochowQiaoEncode_slabDiagonal_at_padding_eq_signature`.
* **Pairwise distinctness across slot kinds.** Using the
  diagonal-value component (vertex=1, present-arrow=0,
  padding=2):
  - vertex (any outDegree) vs present-arrow: distinguished by
    diagonal value 1 vs 0.
  - vertex (any outDegree) vs padding: distinguished by
    diagonal value 1 vs 2.
  - present-arrow vs padding: distinguished by both rank
    component (1 vs 1 — NOT distinguishing) and diagonal value
    (0 vs 2 — distinguishing).
* **Risk.** Low (post-correction).

#### Sub-task C1.5 — Encoder signature multiset (structural lemma only) (~150 LOC, depends on C1.4) [v3 repositioned]

> **v3 audit correction.** v2's C1.5 / C1.6 used the (false)
> Phase B `slabDiagonalSignatureMultiset_smul` to derive Prop 1.
> v3 removes the Prop-1-discharge claim. C1.5 retains the
> **structural signature-multiset description** of the encoder
> (no GL³ smul invariance is asserted); C1.6's count-equality
> argument is removed (the conclusion is now a Phase G
> corollary of Prop 2, not a Phase C theorem).

* **Statement.** `grochowQiaoEncode_slabDiagonalSignatureMultiset`:
  ```
  slabDiagonalSignatureMultiset (grochowQiaoEncode m adj) =
    (Finset.image (fun v => (1 + outDegree m adj v, 1))
      Finset.univ).val.map (...) +
    |presentArrows m adj| • {(1, 0)} +
    |paddingSlotIndices m adj| • {(1, 2)}
  ```
  *(The vertex part is a sum of per-vertex signatures, NOT a
  uniform replicate, because outDegree varies per vertex.)*
* **Proof.** Partition `Finset.univ : Finset (Fin (dimGQ m))`
  into three classes via `slotEquiv` + `isPathAlgebraSlot` +
  `adj` (Stage 2 partition theorem). Apply C1.4 per class.
  Sum via `Multiset.add_def`.
* **Sub-lemmas (each ≤ 50 LOC):**
  - `multiset_disjoint_partition_three_way`.
  - `multiset_replicate_via_constant_map` (applies to present-
    arrow and padding classes only — vertex class is NOT
    constant per the corrected signature).
  - `multiset_per_vertex_outDegree_sum` — vertex class
    contribution.
* **Risk.** Low.
* **No Prop-1 discharge.** This is a *structural description*
  of the encoder's multiset, NOT a claim about GL³-invariance.
  Phase G is responsible for Prop 1 (as a corollary of Prop 2).

#### Sub-task C1.6 — REMOVED [v3 audit]

> **v3 audit correction.** v2's C1.6 attempted to discharge
> Prop 1 via `slabDiagonalSignatureMultiset_smul` (Phase B's
> false framework). With Phase B's framework removed, this
> argument doesn't go through. **C1.6 is removed entirely.**
> Prop 1 is discharged in Phase G as `Prop 2 ⟹ Prop 1`.

**Mathlib anchors.** `Multiset.count`,
`Multiset.count_eq_card_filter`,
`Multiset.replicate`, `Multiset.add_def`,
`Finset.card_disjoint_union`. All present at the pinned commit
`fa6418a8`.

**Risk (overall T-API-C1).** Low. The 5-sub-task decomposition
(C1.1–C1.5; C1.6 removed) turns ~400 LOC of structural
infrastructure into pieces of ≤ 150 LOC each. No Prop-1
discharge is claimed; Phase C is purely diagnostic.

**Verification gate.** Module builds;
`grochowQiao_present_arrow_count_eq_via_signature_multiset`
proven; non-vacuity at `m = 3` exhibiting the count agreement on
two complete graphs `K₃`.

**Consumer.** Layer T-API-C2.

### Layer T-API-C2 — REMOVED [v3 audit]

> **v3 audit correction.** v2's T-API-C2 was a "one-line
> composition" discharging Prop 1
> (`gl3_preserves_partition_cardinalities`) by invoking the
> false `slabDiagonalSignatureMultiset_smul` (Phase B). With
> Phase B's framework removed, this composition does not go
> through. **T-API-C2 is removed entirely.** Prop 1 is now
> discharged in Phase G as a corollary of Prop 2.

**The `partitionPreservingPermOfGL3` constructor and its
`_isThreePartition` proof remain useful** but are repositioned
in **Phase G**: once Prop 2 is discharged (and σ is extracted),
the partition-preserving permutation is built via Stage 3's
existing `partitionPreservingPermFromEqualCardinalities`
applied to the cardinality equality (which is now Phase G's
`Prop 2 ⟹ Prop 1` corollary).

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

**Public surface (post-v3.1 correction — π is now a free
parameter, not a Phase C output).**

> **v3.1 audit correction (Critical finding #8).** v2's
> `pathBlockMatrix` definition referenced `partitionPreservingPermOfGL3`,
> which v3 moved out of Phase C (since Phase C no longer
> discharges Prop 1). To break the resulting circular
> dependency between Phase D and Phase G, `pathBlockMatrix`
> is now parameterised by a **free permutation `π : Equiv.Perm
> (Fin (dimGQ m))` carrying a partition-preservation
> hypothesis**. Downstream phases (E, F, G) supply π once it
> becomes available.

| Declaration | Signature | Role |
|-------------|-----------|------|
| `pathBlockMatrix g π : Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ` | `:= g.1.val * (liftedSigmaMatrix m π⁻¹)` (π is a free parameter). |
| `pathBlockMatrix_offDiag_eq_zero` | Conditional: assuming π preserves the path/padding partition AND `g • encode m adj₁ = encode m adj₂`, the "path → padding" off-diagonal block of `pathBlockMatrix g π` is the zero matrix. |
| `paddingBlockMatrix_offDiag_eq_zero` | Symmetric. |
| `pathBlockMatrix_blockDiagonal_decomposition` | Conditional: assuming the off-diagonal vanishing, `pathBlockMatrix g π = Matrix.fromBlocks pathBlock 0 0 paddingBlock` (after `Equiv.sumCompl`-reindexing). |

**Mathematical content (with π as a parameter).**

For a permutation π that preserves the path/padding partition
between `adj₁` and `adj₂` (i.e., `π '' (pathSlotIndices m adj₁)
= pathSlotIndices m adj₂` and similarly for padding), the
composed matrix `g_X' := g.1.val * liftedSigmaMatrix m π⁻¹`
maps each slot kind to itself (modulo the partition):

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

#### Sub-task D1.3 — Composed-matrix row equation with π⁻¹ (~80 LOC, depends on Phase A A2.1) [v3.1 corrected]

> **v3.1 audit correction.** Removed dependency on Phase C
> C2 (since v3 deleted that layer). `pathBlockMatrix` now
> takes `π` as a free parameter; downstream phases supply π
> after the algebra-iso construction (Phase E first).

* **Definitions.**
  - `pathBlockMatrix g π : Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ
    := g.1.val * (liftedSigmaMatrix m π⁻¹)` — π is a free
    permutation parameter.
  - The "composed matrix" pulls back `g.1.val` via π⁻¹'s
    permutation matrix. The lemmas of D1 are conditional on π
    being a partition-preserving permutation (a hypothesis
    threaded through D1's downstream lemmas).
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
* **Proof outline (the contradiction). [v3.1: π is a parameter]**
  Suppose `(pathBlockMatrix g π) i a ≠ 0` for `i` path,
  `a` padding, with π a partition-preserving permutation
  (hypothesis).

  **Step 1 (transport via the encoder equality).** Let
  `i' := π i`. By the partition-preservation hypothesis on π,
  `i' ∈ pathSlotIndices m adj₂`. From D1.3's row equation,
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

#### Sub-task D2.4 — Simultaneous off-diagonal vanishing (RESEARCH-SCOPE) [v3 corrected]

> **v3 audit correction.** The v2 sub-task D2.4 proposed a
> "potential function" mutual induction with three steps that
> are individually unspecified or circular:
>
> - "Encoder-equality forces a polynomial identity" — but
>   *which* polynomial identity, and what does it imply?
> - "Path-aligned columns... restrict to a bijection
>   PROVIDED the off-diagonals all vanish" — circular (assumes
>   the conclusion).
> - "Conclude the potential is zero" — by what mechanism?
>
> No actual proof argument is provided. The "potential
> function" framing does not break the mutual-induction
> circularity: summing squares of off-diagonal entries gives
> a non-negative real number, and showing it is zero requires
> a separate argument that the v2 plan did not provide.
>
> The honest assessment: **the simultaneous off-diagonal
> vanishing across three axes is genuinely deep multilinear-
> algebra content from Grochow–Qiao 2021 §4.3, NOT a 120-LOC
> exercise.** The formal proof requires either:
>
> 1. A direct algebraic argument from the encoder's piecewise
>    structure that bypasses the mutual-induction loop (e.g.,
>    showing one axis's vanishing without circular reference
>    to the other two).
> 2. The full Grochow–Qiao path-block decomposition theory,
>    which is itself ~80 pages of non-trivial mathematics.
>
> v3 marks D2.4 as **research-scope** with no claim of a
> 120-LOC discharge; the LOC budget is reset to "research-
> scope, multi-month".

* **Statement (target).**
  `gl3_block_offDiag_zero_simultaneous`:
  ```
  ∀ (i ∈ pathSlotIndices m adj₁) (a ∈ paddingSlotIndices m adj₁),
    (pathBlockMatrix g hg) i a = 0 ∧
    (pathBlockMatrix₂ g hg) i a = 0 ∧
    (pathBlockMatrix₃ g hg) i a = 0
  ```

* **Proof status.** **Research-scope.** v2's "potential function"
  approach does NOT close the mutual-induction loop — the
  three-step sketch contains a circular step ("path-aligned
  columns... restrict to a bijection PROVIDED the off-
  diagonals all vanish") and an unspecified step ("encoder-
  equality forces a polynomial identity").

* **Possible approaches (all research-scope).**

  - **Approach 1: Per-axis induction on encoder-equality
    polynomial expansion.** Expand
    `(g • encode m adj₁)(i, j, k) = encode m adj₂(i, j, k)`
    at specific path-padding-mixed slot triples; derive
    one-axis-at-a-time vanishing via degree-reasoning. ≥ 500
    LOC; risk of getting stuck at a single-axis lemma that
    requires the other two.

  - **Approach 2: Direct algebra-iso argument.** Bypass the
    GL³ block decomposition entirely; instead, construct the
    AlgEquiv on the path subspace via the Wedderburn-Mal'cev
    theorem applied directly to the encoded algebra structure.
    The radical-preservation of any algebra iso then gives
    Phase D's content for free. Reorders Phases D-E. ≥ 1000
    LOC; substantial restructure.

  - **Approach 3: Reduce to the literature.** Find an explicit
    formal version of Grochow-Qiao 2021's §4.3 argument and
    transcribe it. ~2000+ LOC; closest to faithful
    reproduction of the paper.

* **Risk.** **Very High (research-scope).** The "120-LOC
  technical heart" estimate in v2 is unsupported by any
  concrete proof outline.

* **Verification gate.** Once an approach is chosen and
  partially landed, intermediate witnesses on `m ∈ {2, 3}`
  with concrete graphs.

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

##### Sub-task E2.2.4 — Arrow × Arrow case (RESEARCH-SCOPE) [v3 corrected]

> **v3 audit correction.** The v2 sub-task E2.2.4 contains a
> **circular argument**: the RHS-vanishing claim
> "`gl3OnPathBlock_to_lin (arrowElement m u v)` is in the
> arrow-element subspace" assumed
> `gl3OnPathBlock_to_lin` preserves the radical, which is
> what we are *trying* to prove (multiplicativity). The "key
> insight" attempted to break the circularity by appealing to
> the partition-preservation of π, but **π preserves the
> path-vs-padding partition only at the cardinality level
> (Phase D)** — not the finer vertex-vs-arrow split within the
> path subspace. Without the finer split preserved, the
> arrow-image could land in any path-subspace element
> (vertex idempotents + arrows), and the J²-closure does not
> apply.
>
> **Honest assessment:** the arrow×arrow multiplicativity case
> is the **central technical lemma of Phase E**, not an 80-LOC
> "deepest case" that closes via a structural shortcut. Its
> formal proof requires either:
>
> 1. Phase D's three-way partition preservation (vertex /
>    present-arrow / padding) at the slot level — a strictly
>    stronger statement than the binary path-vs-padding
>    partition currently in scope. Phase C's
>    `partitionPreservingPermFromEqualCardinalities` produces a
>    three-partition-preserving permutation, but this is
>    conditional on the cardinality equalities **per slot
>    kind**, not just the present-arrow count. Discharging
>    the per-slot-kind cardinalities requires Phase G's
>    Prop-2 corollary chain.
> 2. Or: use the structure-tensor pull-back (E2.1) directly
>    to derive the multiplication-table-preservation property
>    of `gl3OnPathBlock_to_lin` from the encoder-equality —
>    which IS what `pathSlotStructureConstant_eq_pathMul_indicator`
>    + the path-block restriction provide, but the formal
>    chain is non-trivial.

* **Statement (target).** `gl3OnPathBlock_to_lin_arrow_mul_arrow`
  (as in v2).

* **Proof status.** **Research-scope.** v2's "Both sides are
  zero" argument is invalid (RHS vanishing requires
  multiplicativity, which is being proved). Correct proof
  approaches:

  - **Approach A: Three-partition preservation pre-requisite.**
    Establish Phase D + the three-partition-preserving
    extension (vertex slots map to vertex slots, etc.) before
    Phase E. This requires per-slot-kind cardinality
    preservation — itself a Prop-1-strength statement, but
    refined per slot kind. Then the arrow-element subspace IS
    preserved, and J²=0 applies. ~150 LOC for the
    pre-requisite + ~30 LOC for the application.

  - **Approach B: Direct structure-tensor argument.**
    `gl3OnPathBlock_to_lin (a * b)` and
    `gl3OnPathBlock_to_lin a * gl3OnPathBlock_to_lin b` are
    BOTH derived from the encoder's path-slot structure
    constants under the GL³ action. Show they agree directly
    via the structure-constant-equivariance argument
    (E2.1's pull-back applied at the multiplication-table
    level), bypassing radical-preservation entirely. ~150 LOC.

* **Risk.** **High.** The v2 argument is invalid; Approaches A
  and B both require non-trivial new content.

* **LOC reserve.** ~150 LOC (post-correction).

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

#### Sub-layer E2.5 — Apply lemmas on basis elements (~120 LOC) [v3.1 corrected]

> **v3.1 audit correction.** v2 said the explicit formula
> "uses Phase C's `partitionPreservingPermOfGL3`". Since v3
> removed Phase C C2, the σ in the apply lemma must come from
> elsewhere. v3.1 derives σ via Phase F1's
> `gl3_to_vertexPerm` (algebra-derived σ from
> `algEquiv_extractVertexPerm`), which is the natural source.

* `gl3OnPathBlock_to_algEquiv_apply_vertexIdempotent` —
  explicit formula in terms of σ extracted via Phase F1's
  `gl3_to_vertexPerm` (algebra-derived; uses
  `algEquiv_extractVertexPerm` from `WedderburnMalcev.lean`).
* `gl3OnPathBlock_to_algEquiv_apply_arrowElement` — explicit
  formula. Used by Phase F's adjacency invariance.

**Note on phase ordering.** The Phase E ↔ Phase F dependency
is one-directional: E provides the AlgEquiv, F extracts σ via
WM. The apply lemma `_apply_vertexIdempotent` is logically
part of Phase F (it characterizes σ's action), but
syntactically lives near the AlgEquiv definition for
ergonomic reasons.

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

> **v3.1 audit correction.** v2 had a third declaration
> `gl3_to_vertexPerm_eq_partition_descent` claiming
> consistency with Phase C's slot-classification descent.
> Since v3 removed Phase C C2, this consistency claim no
> longer makes sense and is **deleted from the public
> surface**. The σ extracted by Phase F1 IS the canonical σ
> for the workstream; there is no separate "slot-classification
> σ" to check consistency with.

**Mathematical content.** Direct composition of
`algEquiv_extractVertexPerm` (Stage 4 / Phase F starter, in
`WedderburnMalcev.lean`) with the Phase E AlgEquiv. The
extraction yields σ uniquely up to WM radical conjugation; the
σ-output agrees with the algebraic vertex-permutation derived
from primitive idempotent decomposition.

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

## Phase G — Final discharge (Prop 2 + Prop 1 corollary, ~400 LOC post-v3.1)

**Goal.** Discharge `GL3InducesArrowPreservingPerm` (Prop 2)
unconditionally by composing Phase F's `_witness` lemma with
the Prop's quantification structure. Derive
`GL3PreservesPartitionCardinalities` (Prop 1) as a corollary.
Compose with Stage 5's existing infrastructure to deliver
unconditional `GrochowQiaoRigidity` and
`grochowQiao_isInhabitedKarpReduction`.

> **v3 audit correction.** Phase G now discharges BOTH Props
> (was Prop 2 only in v2; v2 expected Phase C to discharge
> Prop 1). The `Prop 2 ⟹ Prop 1` corollary is the
> mathematically natural derivation: σ-arrow-preservation gives
> a bijection between `presentArrows m adj₁` and `presentArrows
> m adj₂`, hence equal cardinalities.

### Layer T-API-G1 — Prop 2 unconditional (~300 LOC)

**File:** extends `Orbcrypt/Hardness/GrochowQiao/Rigidity.lean`
(the existing module already containing
`GL3InducesArrowPreservingPerm` and the conditional
`grochowQiaoRigidity_under_arrowDischarge`).

**Public surface (post-v3.1).**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `gl3_induces_arrow_preserving_perm` | `: GL3InducesArrowPreservingPerm` | The unconditional discharge of Prop 2. |
| `gl3_preserves_partition_cardinalities` | `: GL3PreservesPartitionCardinalities` | Prop 1 derived as corollary of Prop 2 (cardinality from arrow bijection). |
| `partitionPreservingPermOfGL3` | `(g) (hg) → Equiv.Perm (Fin (dimGQ m))` | Previously a v2 Phase C construction; now lives here, built from Phase F's σ + Stage 3's `partitionPreservingPermFromEqualCardinalities` applied to the Prop 1 corollary. |
| `grochowQiaoRigidity` | `: GrochowQiaoRigidity` | Unconditional rigidity (composes G1 with Stage 5's `grochowQiaoRigidity_under_arrowDischarge`). |

**Composition.**

```lean
theorem gl3_induces_arrow_preserving_perm :
    GL3InducesArrowPreservingPerm := by
  intro m adj₁ adj₂ g hg
  exact ⟨gl3_to_vertexPerm g hg, gl3_arrow_preserving_perm_witness g hg⟩

theorem gl3_preserves_partition_cardinalities :
    GL3PreservesPartitionCardinalities := by
  intro m adj₁ adj₂ g hg
  obtain ⟨σ, h_arrow⟩ := gl3_induces_arrow_preserving_perm m adj₁ adj₂ g hg
  -- σ's arrow-preservation gives a bijection
  -- presentArrows m adj₁ ≃ presentArrows m adj₂; cardinalities follow.
  exact card_eq_of_arrow_preserving_perm σ h_arrow

def partitionPreservingPermOfGL3 (g) (hg) : Equiv.Perm (Fin (dimGQ m)) :=
  partitionPreservingPermFromEqualCardinalities
    (gl3_preserves_partition_cardinalities m adj₁ adj₂ g hg)

theorem grochowQiaoRigidity : GrochowQiaoRigidity :=
  grochowQiaoRigidity_under_arrowDischarge gl3_induces_arrow_preserving_perm
```

The Prop-1 corollary (`gl3_preserves_partition_cardinalities`)
derives the cardinality equality from σ's arrow-preservation: σ
restricts to a bijection between `presentArrows m adj₁` and
`presentArrows m adj₂`, hence equal cardinalities. ~30 LOC.

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

### Files modified (post-v3.1 correction)

| File | Phases | Change |
|------|--------|--------|
| `Orbcrypt/Hardness/GrochowQiao/BlockDecomp.lean` | G | Add `partitionPreservingPermOfGL3` (now constructed in Phase G from Phase F's algebra-derived σ + Stage 3's `partitionPreservingPermFromEqualCardinalities`); v3 removed C2's would-be discharge. |
| `Orbcrypt/Hardness/GrochowQiao/Rigidity.lean` | G | Add `gl3_induces_arrow_preserving_perm`, `grochowQiaoRigidity`, and the corollary `gl3_preserves_partition_cardinalities` (Prop 1 derived from Prop 2). |
| `Orbcrypt/Hardness/GrochowQiao.lean` | G | Add `grochowQiao_isInhabitedKarpReduction` (unconditional). |
| `Orbcrypt.lean` | A–G | Add ~9 new imports (post-v3 module-count reduction); extend axiom-transparency report with per-phase subsections; update Vacuity map to mark both Props as discharged. |
| `scripts/audit_phase_16.lean` | A–G | Add ~70 new `#print axioms` entries + ~18 non-vacuity `example`s (post-v3 reductions). |
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

### Phase C (Per-slot signature computations) [v3 corrected — no Prop 1 discharge]

```
[Stage 0: encoder] ─────────┐
[Stage 2: diagonal_values] ─┤
                            ├→ C1.1 (vertex slabs)
                            ├→ C1.2 (present-arrow slabs)
                            ├→ C1.3 (padding slabs)
                            └→ C1.4 (per-slot signatures)
                                ↓
                              C1.5 (encoder signature multiset, structural only)
                                ↓
                          (downstream-phase input — diagnostic; not a discharge)
```

### Phase D (Path-block extraction) [v3.1 corrected — π is a free parameter]

```
[Stage 0: padding_distinguishable] ─→ D1.1, D1.2 ──┐
[Phase A: A2.1, A2.4] ─────────────────────────────┤
                                                   ├→ D1.3 ─→ D1.4, D1.5 ─→ D1.6 ─┐
[π : Equiv.Perm parametric hypothesis] ────────────┘                              │
                                                                                  ├→ D1.7 ─→ D1.8 (axis-1)
[Stage 1: unfold₁_tensorContract] ─→ D2.0 ─→ D2.1 ─→ D2.2 ─→ D2.3 ─→ D2.4 ────────┤
                                                                          (RESEARCH-SCOPE)│
                                                                                          ▼
                                                                                      D2.5 ─→ D3 (subspace)
                                                                                          │
                                                                                          ▼
                                                                                  (Phase E input;
                                                                                   π eventually instantiated by Phase G)
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

### Phase G (Final discharge — both Props) [v3 corrected]

```
[Phase F: F2.4 — arrow witness]
        │
        ├→ G1.1 (Prop 2 discharge: gl3_induces_arrow_preserving_perm)
        ├→ G1.2 (Prop 1 corollary: gl3_preserves_partition_cardinalities)
        ├→ G1.3 (partitionPreservingPermOfGL3 construction — was Phase C v2)
        ├→ G1.4 (grochowQiaoRigidity)
        └→ G2.1 (grochowQiao_isInhabitedKarpReduction)
```

### Critical-path summary [v3.1 corrected]

The **longest sequential path** is:
```
Stage-1 → A1.1 → A2.1 → A2.2 → A2.4 → C1.1 → C1.4 → C1.5
       → D1.1 → D1.3 → D1.4 → D1.6 → D2.4 (RESEARCH)
       → D3 → E1.1 → E2.1 → E2.2.4 (RESEARCH) → E2.5
       → F1.1 → F1.2 → F2.2.1 → F2.3.3 → F2.4
       → G1.1 → G1.2 → G1.4 → G2.1
```
This is approximately 26 sequential sub-tasks (down from v2's
33 because v3's removal of false shallow-rigidity sub-tasks
shortened the path). Many parallelisation
opportunities exist (especially within phases — e.g., axis-2/3
unfolding bridges can land in parallel with axis-1 work),
but the critical path bounds the calendar time.

---

## Appendix C — Per-phase Gantt-style timeline (v3.1 corrected)

| Calendar week | Phase | Sub-tasks landing | Gating dependency |
|---------------|-------|-------------------|-------------------|
| 1–3 | A | A1.1 → A2.1 → A2.2 → A2.3 → A2.4 (encoder-equality structural lemmas only) | Stage 1 |
| 4–5 | B | B1.1 → B1.2 → B2 (re-export of Stage 0/2 diagonal lemmas) | A2.4 |
| 6–8 | C | C1.1 → C1.2 → C1.3 → C1.4 → C1.5 (per-slot signatures, structural only — NO Prop 1 discharge) | B |
| 9–11 | D (early, parametric in π) | D2.0 → D2.1 → D2.2 → D1.1 → D1.2 → D1.3 → D1.4 | C |
| 12–22 | D + E (interleaved, RESEARCH-SCOPE) | D1.5 → D1.6 → D2.3 → D2.4 (RESEARCH) → D1.7 → D1.8 → D2.5 → D3; in parallel E1.1 → E1.5 → E2.1 | D1.4, D2.2 |
| 23–32 | E (deep) → F | E2.2.1 → E2.2.2 → E2.2.3 → E2.2.4 (RESEARCH) → E2.2.5 → E2.3 → E2.4 → E2.5 → F1.1 → F1.2 → F1.3 | E2.1 |
| 33–35 | F (arrow) | F2.1 → F2.2.1 → F2.2.2 → F2.2.3 → F2.3.1 → F2.3.2 → F2.3.3 → F2.3.4 → F2.3.5 → F2.4 | F1.3 |
| 36–38 | G | G1.1 (Prop 2) → G1.2 (Prop 1 corollary) → G1.3 (π construction) → G1.4 → G2.1 (**workstream complete**) | F2.4 |

Total calendar time: **38 weeks (~9 months)** for the full
workstream at sustained focused effort. **No half-way Prop-1
milestone** in v3.1 — Prop 1 is now derived from Prop 2 in
Phase G, so the only milestone is the final workstream
completion.

> **v3.1 calendar caveat.** D2.4 and E2.2.4 are research-
> scope; the timeline above assumes both are dischargeable in
> ~10 weeks combined, but this is uncertain. If either of
> them stalls, the calendar extends accordingly.

---

## Appendix D — Deferred-discharge contingency planning

If Phases D, E, or F stall mid-discharge, the workstream can
land **partial closures** at well-defined boundaries:

### Option D-stall (fall-back if Phase D's mutual-induction stalls) [v3.1 corrected]

> **v3.1 audit correction.** v2's Option D-stall claimed that
> stalling at Phase D would still deliver "Prop 1 discharged
> unconditionally" because Phase C was supposed to discharge
> it. Since v3 removed Phase C's Prop-1 discharge (the slab-
> rank multiset framework was false), **stalling at Phase D
> means BOTH Props remain research-scope**. There is no
> partial Prop-1 discharge available.

* **Delivered.** Phases A, B, C complete (~1,200 LOC, post-v3
  reductions). Encoder-equality structural infrastructure
  (slab definitions, signature computations) is publicly
  usable. **No Prop discharge.**
* **Not delivered.** Both Prop 1 and Prop 2 remain research-
  scope.
* **Cryptographic value.** The structural infrastructure
  (`slab₁`, joint-signature computations, encoder-equality
  consequences) is publicly useful for future Lean
  formalizations of related multilinear-algebra problems, but
  does NOT discharge the R-15-residual-TI-reverse milestone.
* **Patch version.** `lakefile.lean` not bumped (no headline
  Prop discharged).
* **Documentation.** `CLAUDE.md`'s headline table classifications
  are unchanged — Stage 3 / Stage 5 theorems remain
  **Conditional** on both Props.

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
| A | `§ R-TI-Phase-A` | ~10 (slab definitions, encoder-equality consequence — post-v3 reductions) | 3 |
| B | `§ R-TI-Phase-B` | ~5 (diagonal classification re-exports — post-v3 reductions) | 2 |
| C | `§ R-TI-Phase-C` | ~12 (per-slot signatures; NO Prop 1 discharge — post-v3) | 3 (per-slot non-vacuity) |
| D | `§ R-TI-Phase-D` | ~20 (off-diagonal vanishing, block decomposition; conditional on π parameter) | 4 |
| E | `§ R-TI-Phase-E` | ~20 (subspace identification, AlgEquiv) | 4 |
| F | `§ R-TI-Phase-F` | ~15 (sigma extraction, arrow scalar) | 3 |
| G | `§ R-TI-Phase-G` | ~10 (final Prop discharges, π construction, Karp reduction) | 3 (final non-vacuity) |
| **Total** | | **~92** | **~22** |

Total audit-script growth: from current 770 declarations to
~862 (post-Phase-G; v3 reductions in Phases A, B, C).

Each entry is parsed by the CI's de-wrapping Perl regex; per
CLAUDE.md the standard-trio constraint is enforced
(`propext`, `Classical.choice`, `Quot.sound` only; no
`sorryAx`, no custom axioms).
