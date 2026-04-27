# R-TI Research-Scope Discharge Plan

**Eliminating `GL3PreservesPartitionCardinalities` and
`GL3InducesArrowPreservingPerm` to deliver unconditional
`grochowQiaoRigidity` and `grochowQiao_isInhabitedKarpReduction`.**

Date: 2026-04-27
Author: post-Stage-5 R-TI rigidity discharge planning
Tracking: research milestone **R-15-residual-TI-reverse**
Status: planned (not yet started)

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

This plan discharges both unconditionally. The total LOC budget is
**~6,200 LOC** of new Lean across **11 new modules**, plus ~500
LOC of documentation refresh and audit-script extensions, for a
grand total of ~6,700 LOC across the 7 phases. The dedicated
effort estimate is **~6–10 months** for a single focused
implementer.

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

| Phase | Layers | Title | LOC | Risk |
|-------|--------|-------|-----|------|
| A | T-API-A1, A2 | Slab-rank multiset invariance | ~900 | Med |
| B | T-API-B1, B2 | Diagonal-value invariance under GL³ | ~600 | Low–Med |
| C | T-API-C1, C2 | Slot-classification rigidity (Prop 1 discharge) | ~700 | Low–Med |
| D | T-API-D1, D2, D3 | Path-block extraction + restriction theorem | ~1,400 | **Research** |
| E | T-API-E1, E2 | AlgEquiv construction from path-block GL³ | ~1,100 | High |
| F | T-API-F1, F2 | σ extraction + arrow-action analysis | ~900 | Med–High |
| G | T-API-G1, G2 | Final discharge + composition (Prop 2) | ~600 | Med |
| | | **Total** | **~6,200** | |

Plus ~500 LOC for documentation refresh, audit-script extensions,
and Vacuity-map / VERIFICATION_REPORT updates across the seven
phases.

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

**Sub-lemma decomposition (each ≤ 80 LOC):**

* `unfold₁_smul_row_eq` — `(unfold₁ (g • T)) i =
  ((g₁.val i) ⬝ (unfold₁ T)) * (g₂.valᵀ ⊗ₖ g₃.valᵀ)` (where
  `(g₁.val i) ⬝ M` is the linear combination of rows of `M`).
  Direct from `unfold₁_tensorContract`.
* `slabRank₁_smul_row_invariant` — at the row index `g₁⁻¹.val a`,
  the inner-product collapse via `g₁ * g₁⁻¹ = 1` gives
  `(unfold₁ (g • T)) (g₁⁻¹.val a) = (unfold₁ T a) * (g₂.valᵀ ⊗ₖ
  g₃.valᵀ)`. Composes with `slab₁_unfold₁_row` and the slab-rank
  identification.
* `slabRank₁_kronecker_right_mul_invariant` — slab rank is
  invariant under right multiplication by an invertible matrix.
  Direct from `rank_mul_eq_left_of_isUnit_det` (Mathlib
  `LinearAlgebra/Matrix/Rank.lean`).
* `slabRankMultiset₁_smul` — composes the three sub-lemmas via
  `Multiset.map_eq_map_of_bijective` (where the bijection is
  `g₁⁻¹.val`).

**Mathlib anchors verified at `fa6418a8`.**
`Multiset.map_eq_map_of_bijective` (or the equivalent
`Multiset.map_eq_map_iff_of_inj`),
`Matrix.rank_mul_eq_left_of_isUnit_det` (Rank.lean:205),
`Matrix.kronecker_apply`, `Matrix.mul_kronecker_mul` (T-API-1.5 +
1.6 from prior plan).

**Hidden gap.** None identified. `Multiset.map`-bijection
arithmetic is well-established Mathlib; the Kronecker
right-multiplication invariance is a one-line composition with
the existing `rank_mul_eq_left_of_isUnit_det` from the
`RankInvariance.lean` toolkit.

**Risk.** Medium. The technical core is the per-slab rank
identity, which involves an inner-product collapse argument that
must be carefully formalised. ~150 LOC reserve for the
collapse-via-`g₁ * g₁⁻¹ = 1` lemma.

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
  (Stage 2 + Stage 0). Specifically, vertex slots have signature
  `(1 + deg(v), 1)`, present-arrow slots `(2, 0)`, padding slots
  `(1, 2)`. The slab-rank multiset alone does not distinguish
  vertex slots with `deg = 0` (rank 1) from padding slots
  (rank 1). The diagonal-value multiset alone might also collide
  for non-encoder tensors. **Together** they form a refined
  multiset that *is* preserved under GL³ for the encoder family.

**Sub-lemma decomposition (each ≤ 80 LOC):**

* `slabDiagonalSignature T i : ℕ × F := (slabRank₁ T i, T.diagonal i)`
  — the joint signature.
* `slabDiagonalSignatureMultiset` — multiset of joint signatures.
* `slabDiagonalSignatureMultiset_smul` — joint multiset is
  GL³-invariant for the encoder family. *Proof*: combines
  `slabRankMultiset₁_smul` with a parallel argument for the
  diagonal multiset that uses the encoder's piecewise structure
  + `unfold₁_tensorContract` to track how diagonal entries
  transform under GL³.

**Mathlib anchors.** `Multiset.map`, `Multiset.count`,
`Multiset.card`. Combined with the Phase A toolkit.

**Risk.** Medium. The "joint multiset" approach is novel content
that does not directly mirror existing Mathlib API. ~200 LOC
reserve for the inner-product-collapse arguments analogous to
Phase A's `slabRank₁_smul_row_invariant`.

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

## Phase C — Slot-classification rigidity (Prop 1 discharge, ~700 LOC)

**Goal.** Discharge `GL3PreservesPartitionCardinalities` from
Phase A and Phase B. This is the **first headline theorem** of
the workstream: it eliminates one of the two research-scope
`Prop`s and lets `partitionPreservingPermFromEqualCardinalities`
(Stage 3 of the prior plan) become unconditional.

### Layer T-API-C1 — Slot-kind cardinalities from joint multiset (~400 LOC)

**File (new):** `Orbcrypt/Hardness/GrochowQiao/SlotCardinality.lean`.

**Public surface:**

| Declaration | Signature | Role |
|-------------|-----------|------|
| `vertexSlotSignature m adj v : ℕ × ℚ := (1 + outDegree m adj v, 1)` | Joint signature of a vertex slot. |
| `presentArrowSlotSignature : ℕ × ℚ := (2, 0)` | Joint signature of a present-arrow slot. |
| `paddingSlotSignature : ℕ × ℚ := (1, 2)` | Joint signature of a padding slot. |
| `grochowQiaoEncode_slabDiagonal_at_vertex` | `slabDiagonalSignature (encode m adj) (slotEquiv.symm (.vertex v)) = vertexSlotSignature m adj v` | Per-slot computation. |
| `grochowQiaoEncode_slabDiagonal_at_presentArrow`, `_at_padding` | symmetric | |
| `grochowQiaoEncode_slabDiagonalSignatureMultiset` | Explicit form of the multiset for the encoder. |
| `grochowQiao_present_arrow_count_eq_via_signature_multiset` | `g • encode m adj₁ = encode m adj₂ → (presentArrowSlotIndices m adj₁).card = (presentArrowSlotIndices m adj₂).card` | The Phase 1 discharge claim. |

**Mathematical content.**

The joint signature multiset is structurally informative:

* `m` copies of `vertexSlotSignature m adj v` for each `v`.
* `|presentArrows m adj|` copies of `(2, 0)`.
* `m² - |presentArrows m adj|` copies of `(1, 2)`.

By Phase B's `slabDiagonalSignatureMultiset_smul`, this multiset
is preserved under any GL³ tensor isomorphism between
`(encode m adj₁, encode m adj₂)`. Hence:

* The number of `(2, 0)`-signature slots is preserved →
  `|presentArrows m adj₁| = |presentArrows m adj₂|`.

**Sub-lemma decomposition (each ≤ 80 LOC):**

* Per-slot signature computations (vertex / present-arrow /
  padding) — each is direct from the encoder definition + Stage 2
  diagonal-value lemmas + slab-rank computation.
* `slab₁ (encode m adj) (vertexSlot v) (i, j) = ...` — explicit
  slab evaluation at a vertex slot. Uses `pathSlotStructureConstant`
  cases.
* `slabRank₁_at_vertexSlot = 1 + outDegree m adj v` — slab-rank
  computation at vertex slots. Uses
  `vertexIdempotent_mul_arrowElement`-style cases from
  `AlgebraWrapper.lean`.
* Symmetric per-slot rank computations for present-arrow (rank 2
  via `pathMul (.id u) (.edge u v) = some` and
  `pathMul (.edge u v) (.id v) = some`) and padding (rank 1 via
  ambient diagonal only).
* `Multiset.count_eq_card_filter` to extract the (2, 0)-signature
  count.

**Mathlib anchors.** `Multiset.count`, `Multiset.count_eq_card_filter`,
`Finset.card_eq_of_bijective`, `outDegree` defined locally as
`(presentArrowSlotIndices m adj).filter (fun s => slotEquiv s = .arrow v _)`.

**Risk.** Low–Medium. The slab-rank computations at the encoder
slot kinds are technical but follow a uniform pattern from
Stage 2's diagonal-value classification.

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

## Phase D — Path-block extraction + restriction theorem (~1,400 LOC, **research-grade**)

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

**Sub-lemma decomposition (each ≤ 100 LOC):**

* `unfold₁_path_support` — for `i ∈ pathSlotIndices m adj`, the
  row `unfold₁ T i` is supported on path-slot column pairs
  (i.e., `(j, k)` such that both `j` and `k` lie in
  `pathSlotIndices m adj`). *Proof*: case split on whether
  `T(i, j, k) = 0` using
  `grochowQiaoEncode_padding_distinguishable`.
* `unfold₁_padding_support` — symmetric for padding slots.
* `pathBlockMatrix_path_to_padding_zero` — the contradiction
  argument above. *Mitigation*: ~150 LOC reserve for the
  Kronecker-product factor manipulation.
* `pathBlockMatrix_padding_to_path_zero` — symmetric.
* `pathBlockMatrix_blockDiagonal_decomposition` — package via
  `Matrix.fromBlocks` after `Equiv.sumCompl`-reindexing.

**Mathlib anchors.** `Matrix.fromBlocks`, `Matrix.fromBlocks_zero₁₂`
/ `_zero₂₁`, `Equiv.sumCompl`, `Matrix.reindex`,
`Matrix.kroneckerMap_apply`, the Phase A
`unfold₁_smul_row_eq` lemma.

**Hidden gap.** `Matrix.fromBlocks` operates on `Sum`-typed
indices, but `Fin (dimGQ m)` partitions are `Finset`-based. The
bridge is `Equiv.sumCompl` plus `Matrix.reindex`. ~80 LOC reserve
for this index-management bookkeeping (already budgeted in the
sub-lemma decomposition above).

**Risk.** **High (research-grade).** The off-diagonal-vanishing
argument is novel formalisation content that does not directly
mirror existing Mathlib API. The argument's success depends on
the encoder's distinguished-padding structure (post-Stage-0)
combined with the unfolding/Kronecker bridge from T-API-1.

**Verification gate.** Module builds (set
`set_option maxHeartbeats 800000` per declaration if needed —
profile with `set_option trace.profiler true`);
`pathBlockMatrix_blockDiagonal_decomposition` proven; non-vacuity
at `m = 2` (empty graph identity case).

**Consumer.** Layer T-API-D2.

### Layer T-API-D2 — Symmetric block decompositions on axes 2, 3 (~500 LOC)

**File (new):** `Orbcrypt/Hardness/GrochowQiao/BlockExtractionAxes23.lean`.

**Public surface:**

* `pathBlockMatrix₂`, `pathBlockMatrix_offDiag_eq_zero₂`, etc. —
  symmetric to D1 on axis-2 (uses `unfold₂_tensorContract` analog
  to be lifted from T-API-1, currently research-scope per Stage 1's
  documentation note).
* `pathBlockMatrix₃`, `pathBlockMatrix_offDiag_eq_zero₃` —
  symmetric on axis-3.
* `gl3_block_diagonal_triple` — combines D1 + D2 into the
  consumer-facing theorem.

**Pre-requisite.** This phase requires `unfold₂_tensorContract`
and `unfold₃_tensorContract`, which are documented as research-
scope follow-ups in the Stage 1 R-TI landing. **Sub-task D2.0
(~150 LOC reserve)** discharges these as a pre-requisite, lifting
the axis-1 proof technique to axes 2 and 3 via symmetric Kronecker
identities.

**Risk.** Medium–High. Mostly pattern-matching on D1's argument,
but D2.0 is a non-trivial extension of T-API-1.

**Verification gate.** Module builds; symmetric decompositions
proven; `gl3_block_diagonal_triple` packages all three.

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

* `pathBlockToLin_basis_basis_mul_eq` — for two basis elements
  `a = arrowElement u v`, `b = arrowElement w x`,
  `gl3OnPathBlock_to_lin (a * b) = (gl3OnPathBlock_to_lin a) *
  (gl3OnPathBlock_to_lin b)`.
* *Proof technique.* Case on `pathMul m (.edge u v) (.edge w x)`
  (always `none`, by L1.4 `arrowElement_mul_arrowElement_eq_zero`)
  versus `pathMul m (.id v) ...` (zero / vertex / arrow cases).
  Use `pathSlotStructureConstant_equivariant`-style arguments
  combined with the structure-tensor pull-back from E2.1.
* Symmetric cases: `vertexIdempotent · vertexIdempotent`,
  `vertexIdempotent · arrowElement`, `arrowElement ·
  vertexIdempotent`.
* `pathBlockToLin_mul_bilinear` — extend to general
  `a, b ∈ pathAlgebraQuotient m` via
  `pathAlgebra_decompose` (Layer 5 of `AlgebraWrapper.lean`)
  + bilinearity.

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

* `inner_aut_radical_fixes_pathAlgebra` — extension of Stage 5's
  `inner_aut_radical_fixes_arrow` to all of
  `pathAlgebraQuotient m` via `pathAlgebra_decompose_radical`
  (`WedderburnMalcev.lean`).
* *Proof technique.* Decompose `c = vertexPart c + arrowPart c`.
  Inner-conjugation fixes vertex idempotents up to themselves
  modulo radical (since vertex idempotents commute with the
  conjugating radical element via Phase F1's WM extraction).
  The arrow part is fixed by Stage 5's
  `inner_aut_radical_fixes_arrow` extended linearly via
  `pathAlgebra_sum_mul`.

#### Sub-layer F2.3 — Arrow image is scalar (~250 LOC)

* `gl3OnPathBlock_to_algEquiv_arrowElement_sandwich_eq` — apply
  `gl3OnPathBlock_to_algEquiv` (an `AlgHom`) to the sandwich
  identity from F2.1.
* `gl3OnPathBlock_arrowElement_collapse_via_radical` — combine
  with F1's vertex-idempotent radical-conjugation form: each
  `gl3OnPathBlock_to_algEquiv (vertexIdempotent v) = (1+j) *
  vertexIdempotent (σ v) * (1-j)`. The ambient
  `(1+j) e_{σu} (1-j) * φ(arrow uv) * (1+j) e_{σv} (1-j)`
  simplifies via F2.2.
* `gl3OnPathBlock_arrowElement_eq_scalar` — conclude
  `gl3OnPathBlock_to_algEquiv (arrowElement m u v) = c •
  arrowElement m (σ u) (σ v)` via the sandwich identity at
  basis-level.
* `gl3OnPathBlock_arrowElement_scalar_nonzero` — `c ≠ 0` by
  AlgEquiv injectivity + `arrowElement m u v ≠ 0`.

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

| File | Phase | LOC |
|------|-------|-----|
| `SlabRank.lean` | A | ~400 |
| `SlabRankInvariance.lean` | A | ~500 |
| `DiagonalValues.lean` | B | ~600 |
| `SlotCardinality.lean` | C | ~400 |
| `BlockExtractionAxis1.lean` | D | ~600 |
| `BlockExtractionAxes23.lean` | D | ~500 |
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

| Phase | LOC | Risk | Estimated dedicated effort |
|-------|-----|------|----------------------------|
| A | ~900 | Med | 3–5 weeks |
| B | ~600 | Low–Med | 2–4 weeks |
| C | ~700 | Low–Med | 2–3 weeks |
| D | ~1,400 | **Research** | 8–14 weeks |
| E | ~1,100 | High | 4–7 weeks |
| F | ~900 | Med–High | 3–5 weeks |
| G | ~600 | Med | 2–3 weeks |
| **Total** | **~6,200** | | **~6–10 months** dedicated effort |

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

| Phase | Commit count |
|-------|--------------|
| A | 2 commits (A1, A2 separately) |
| B | 2 commits (B1, B2 separately) |
| C | 2 commits (C1, C2 separately) |
| D | 4 commits (D1, D2.0 pre-requisite, D2 main, D3) |
| E | 6 commits (E1, then 5 sub-layers of E2 separately) |
| F | 5 commits (F1, then 4 sub-layers of F2 separately) |
| G | 2 commits (G1, G2 separately + documentation roll-up) |
| **Total** | **23 commits** across 7 phases |

23 commits across ~6–10 months is a sustainable cadence for
review-friendly incremental landing.

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
