# R-TI Research-Scope Discharge Plan

**Implementing `GL3PreservesPartitionCardinalities` and
`GL3InducesArrowPreservingPerm` to deliver unconditional
`grochowQiaoRigidity` and `grochowQiao_isInhabitedKarpReduction`.**

Date: 2026-04-27
Author: post-Stage-5 R-TI rigidity discharge planning
Tracking: research milestone **R-15-residual-TI-reverse**
Source: Grochow–Qiao 2021 SIAM J. Comp. 2023 §4.3
Status: planned (not yet started)
Revision: v4 (clean rewrite — 2026-04-27)

---

## Revision history

* **v1–v3.2 (deprecated, 2026-04-27).** Earlier revisions
  attempted to discharge Prop 1 via a "shallow rigidity"
  framework (slab-rank multiset invariance + diagonal-value
  multiset invariance under generic GL³). **Both invariants
  are mathematically false** — counterexamples exist for
  arbitrary tensors. The earlier revisions accumulated
  contradictory corrections and were discarded.

* **v4 (this revision, clean rewrite).** Replaces the earlier
  revisions in full. Built on a mathematically sound
  foundation:
  - The two `Prop`s are discharged together via the
    Grochow–Qiao algebra-isomorphism approach.
  - The genuine deep content is isolated in **one** research-
    scope phase (Phase 3, the GL³ → algebra-iso bridge), not
    spread across multiple phases as in v3.
  - All other phases are concrete and tractable, building on
    the existing path-algebra + Wedderburn–Mal'cev
    infrastructure.
  - No false invariants are claimed.

---

## 1. Context

The Grochow–Qiao GI ≤ TI Karp reduction
(`@GIReducesToTI ℚ _`) is a tier-one cryptographic-hardness
reduction. Stages 0–5 of the prior R-TI workstream
(implemented across 10+ modules under
`Orbcrypt/Hardness/GrochowQiao/`) landed all the **structural
content** of the rigidity argument: the encoder strengthening,
the path algebra `pathAlgebraQuotient m` with full Ring +
Algebra ℚ instances, the Wedderburn–Mal'cev decomposition,
the σ-induced AlgEquiv `quiverPermAlgEquiv m σ`, the WM
σ-extraction `algEquiv_extractVertexPerm`, the adjacency-iff-
arrow-preservation characterisation, and the conditional Karp
reduction inhabitant `grochowQiao_isInhabitedKarpReduction_under_rigidity`.

Two named research-scope `Prop`s remain. Once both are
discharged, every conditional theorem in the chain becomes
unconditional.

## 2. The two `Prop`s (formal statements)

Both `Prop`s are defined in
`Orbcrypt/Hardness/GrochowQiao/BlockDecomp.lean` and
`Orbcrypt/Hardness/GrochowQiao/Rigidity.lean` respectively.
Their statements (verified against the actual code):

```lean
def GL3PreservesPartitionCardinalities : Prop :=
  ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ ×
         GL (Fin (dimGQ m)) ℚ),
    g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂ →
    (presentArrowSlotIndices m adj₁).card =
      (presentArrowSlotIndices m adj₂).card

def GL3InducesArrowPreservingPerm : Prop :=
  ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ ×
         GL (Fin (dimGQ m)) ℚ),
    g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂ →
    ∃ σ : Equiv.Perm (Fin m),
      ∀ u v, (.edge u v : QuiverArrow m) ∈ presentArrows m adj₁ ↔
             (quiverMap m σ (.edge u v)) ∈ presentArrows m adj₂
```

**Logical relationship.** Prop 2 strictly implies Prop 1: a
σ that arrow-preserves gives a bijection between
`presentArrows m adj₁` and `presentArrows m adj₂` (via
`σ × σ` on `Fin m × Fin m`), hence cardinalities match.
**There is no proof of Prop 1 independent of Prop 2** — both
require the deep GL³ → algebra-iso content. v4 discharges
Prop 2 first; Prop 1 follows as a ~50 LOC corollary.

## 3. Mathematical strategy

We follow the **Grochow–Qiao algebra-isomorphism approach**:

1. **The encoder encodes the path algebra's multiplication.**
   For path-algebra slots `(i, j, k)`, the encoder's value
   `grochowQiaoEncode m adj i j k =
   pathSlotStructureConstant m i j k` is the structure
   constant of the multiplication
   `e_{slot_i} · e_{slot_j} = ∑_k T_{ijk} e_{slot_k}` in the
   path algebra `pathAlgebraQuotient m`.

2. **A GL³ tensor iso between two encoders forces an algebra
   iso between the path algebras.** Concretely: given
   `g • encode adj₁ = encode adj₂`, the three GL components
   `(g₁, g₂, g₃)` collectively determine a linear isomorphism
   between the path subspaces of `adj₁` and `adj₂`. The
   structure-tensor preservation (a polynomial identity in the
   encoder entries) forces this linear iso to be
   *multiplicative* — i.e., an algebra iso. **This step is
   the genuinely deep mathematical content from
   Grochow–Qiao 2021 §4.3** (~80 pages of the paper).

3. **Algebra iso preserves the Jacobson radical.** This is a
   standard fact: any algebra hom preserves nilpotent ideals,
   so an algebra iso preserves `J(A) = J(B)` (the Jacobson
   radical). For our path algebra
   `A = pathAlgebraQuotient m`, the radical is exactly the
   span of arrow basis elements (already proven in
   `WedderburnMalcev.lean`).

4. **Wedderburn–Mal'cev extracts σ from the algebra iso.**
   The existing theorem `algEquiv_extractVertexPerm` (in
   `WedderburnMalcev.lean`) takes any AlgEquiv and produces
   `σ : Equiv.Perm (Fin m)` together with `j ∈
   pathAlgebraRadical m` such that
   `(1 + j) * vertexIdempotent (σ v) * (1 - j) =
   ϕ (vertexIdempotent v)` for all `v`. This is the
   primitive-idempotent decomposition uniqueness theorem.

5. **σ preserves arrow membership.** Combining the
   algebra-iso's radical preservation with the WM radical
   witness, the σ-action on `arrowElement m u v` produces a
   non-zero scalar multiple of `arrowElement m (σ u) (σ v)`
   in the radical of `adj₂`'s algebra. Membership in
   `presentArrows m adj₂` is captured by non-vanishing of the
   `arrowElement m (σ u) (σ v)` basis coefficient. This is
   Stage 5's `vertexPermPreservesAdjacency` framework
   (already in the codebase, conditional on the algebra iso
   structure).

6. **Compose to discharge both `Prop`s.** With σ in hand,
   Prop 2's witness is direct. Prop 1 follows as the
   `σ × σ`-bijection corollary on `Fin m × Fin m`.

## 4. Phase map

| Phase | Title | LOC | Risk | Discharges |
|-------|-------|-----|------|------------|
| 1 | Encoder structural foundation | ~600 | Low | — (infrastructure) |
| 2 | Path-block linear restriction (parametric in π) | ~700 | Med | — (infrastructure) |
| 3 | **GL³ → algebra-iso bridge** (Approach A; sub-tasks A.1–A.6) | **~3,200** | **RESEARCH** | The deep step |
| 4 | σ extraction via Wedderburn–Mal'cev | ~250 | Low | — (uses Stage 4 + 6b) |
| 5 | Arrow preservation from σ + radical | ~400 | Med | — (uses Stage 5) |
| 6 | Final discharge (Prop 2 + Prop 1 corollary) | ~250 | Low | **Prop 1** + **Prop 2** |
| | **Total Lean** | **~5,400** | | |

Plus ~400 LOC for documentation refresh, audit-script
extensions, and Vacuity-map / VERIFICATION_REPORT updates.

**Critical observation.** The genuine deep content is
concentrated in **Phase 3 alone**. Phases 1, 2, 4, 5, 6 are
all tractable infrastructure or composition with existing
machinery. **Phase 3's ~3,200 LOC budget reflects honest
analysis of Approach A's six sub-tasks** (A.1 ~250, A.2 ~300,
A.3 ~700, A.4 ~250, A.5 ~600, A.6 ~400, plus ~660 LOC
reserves). This budget is achievable with focused effort
but contains genuine research content (sub-tasks A.3 and
A.5 are both research-grade).

## 5. Outcome

After all six phases land:

* `theorem gl3_induces_arrow_preserving_perm :
    GL3InducesArrowPreservingPerm` — unconditional (Phase 6).
* `theorem gl3_preserves_partition_cardinalities :
    GL3PreservesPartitionCardinalities` — unconditional
  corollary of the above (Phase 6).
* `theorem grochowQiaoRigidity : GrochowQiaoRigidity` —
  unconditional, via `grochowQiaoRigidity_under_arrowDischarge`
  (already in `Rigidity.lean`).
* `theorem grochowQiao_isInhabitedKarpReduction :
    @GIReducesToTI ℚ _` — unconditional, via
  `grochowQiao_isInhabitedKarpReduction_under_rigidity`
  (already in `GrochowQiao.lean`).
* **Reusable infrastructure landed:** path-block linear
  restriction (parametric in π) for arbitrary 3-tensors with
  partition-aligned support; explicit encoder structure-tensor
  evaluation lemmas at every slot kind; GL³ → AlgEquiv bridge
  on the path subspace (when Phase 3 lands).
* Zero `sorry`, zero custom axioms; all `#print axioms` checks
  remain on the standard Lean trio.
* `lakefile.lean` version bumped (final increment reserved
  for Phase 6 landing).

## 6. Conventions (inherited from CLAUDE.md)

* **Naming.** Identifiers describe content, not provenance.
  No `phase3_*`, `r15_*`, etc. Permitted: `encoder_slab_at_vertex`,
  `gl3_induces_algEquiv_on_pathSubspace`, etc.
* **Docstrings.** Every public `def`/`theorem` carries a
  `/-- ... -/` docstring stating content, technique, consumer.
* **`@[simp]` discipline.** Reserved for genuine normalisation
  lemmas.
* **No `sorry`, no custom axioms.** Every public declaration
  depends only on `propext`, `Classical.choice`, `Quot.sound`.
* **Reuse aggressively.** The plan reuses 30+ existing
  declarations from `pathAlgebraQuotient`,
  `WedderburnMalcev`, `quiverPermAlgEquiv`, etc.
* **Mathlib-idiomatic.** `Matrix.rank`, `Matrix.kroneckerMap`,
  `Submodule.span`, `LinearMap.restrict`, `AlgEquiv`,
  `Equiv.Perm`, `Finset.image`.
* **Module length cap.** ≤ 600 LOC per `.lean` file. Split
  into sub-modules when needed.

---

## Phase 1 — Encoder structural foundation (~600 LOC)

**Goal.** Establish per-slot evaluation lemmas for the
encoder, derived from the actual code's structure-tensor
convention. These are pure structural lemmas about the
encoder; no GL³-invariance claims are made here.

**Mathematical foundation.** The encoder's path-algebra
structure constant in
`Orbcrypt/Hardness/GrochowQiao/StructureTensor.lean` is

```
def pathSlotStructureConstant (m : ℕ) (i j k : Fin (dimGQ m)) : ℚ :=
  let a := slotToArrow m (slotEquiv m i)
  let b := slotToArrow m (slotEquiv m j)
  let c := slotToArrow m (slotEquiv m k)
  match pathMul m a b with
  | some d => if d = c then 1 else 0
  | none => 0
```

i.e., **`T_{ijk} = 1[pathMul slot_i slot_j = some slot_k]`**:
the *first* tensor index `i` matches the *first* `pathMul`
argument; the *third* index `k` matches the `pathMul` *output*.
This is the standard structure-tensor convention `T_{ijk} =
⟨e_i · e_j, e_k⟩` (in the basis pairing).

### Layer 1.1 — Per-slot slab evaluation (~250 LOC)

**File:** `Orbcrypt/Hardness/GrochowQiao/EncoderSlabEval.lean` (new).

**Public surface:**

| Declaration | Statement | LOC |
|-------------|-----------|-----|
| `encoder_at_vertex_vertex_vertex_eq_one` | `i = vertex v → j = vertex v → k = vertex v → encode m adj i j k = 1` | ~30 |
| `encoder_at_vertex_arrow_arrow_eq_one` | `i = vertex v → j = arrow v w → k = arrow v w → adj v w = true → encode m adj i j k = 1` | ~30 |
| `encoder_at_arrow_vertex_arrow_eq_one` | `i = arrow u v → j = vertex v → k = arrow u v → adj u v = true → encode m adj i j k = 1` | ~30 |
| `encoder_at_padding_diagonal_eq_two` | for padding slot `i = (slotEquiv).symm (.arrow u v)` with `adj u v = false`, `encode m adj i i i = 2` | ~30 |
| `encoder_zero_at_remaining_path_triples` | classifies all `(i, j, k)` path-algebra triples where the encoder is 0 | ~80 |
| `encoder_zero_at_mixed_triples` | reuses `grochowQiaoEncode_padding_distinguishable` | ~10 |

**Proof technique.** Each lemma unfolds the encoder's
piecewise definition + applies the relevant `pathMul` case
(`pathMul_id_id`, `pathMul_id_edge`, `pathMul_edge_id`,
`pathMul_edge_edge_none`). Simple case-splits.

**Mathlib anchors.** `pathMul_id_id`, `pathMul_id_edge`,
`pathMul_edge_id`, `pathMul_edge_edge_none` (existing in
`PathAlgebra.lean`); `Equiv.apply_symm_apply`.

**Risk.** Low. Pure structural unfolding.

**Verification gate.** Each lemma's `#print axioms` reports
standard Lean trio only.

### Layer 1.2 — Encoder satisfies path-algebra associativity identity (~250 LOC)

**File:** extends `Orbcrypt/Hardness/GrochowQiao/EncoderSlabEval.lean`.

**Goal.** Prove that the encoder's structure tensor satisfies
the polynomial identity that encodes path-algebra
associativity. This is the **first** mathematical content that
will support Phase 3's algebra-iso construction.

**Statement.** `encoder_associativity_identity`:
```
∀ (m : ℕ) (adj : Fin m → Fin m → Bool)
  (i j k l : Fin (dimGQ m))
  (h_path : isPathAlgebraSlot m adj i ∧
            isPathAlgebraSlot m adj j ∧
            isPathAlgebraSlot m adj k ∧
            isPathAlgebraSlot m adj l),
  ∑ a, encode m adj i j a * encode m adj a k l =
  ∑ a, encode m adj j k a * encode m adj i a l
```

*(Derived from `(e_i · e_j) · e_k = e_i · (e_j · e_k)` in the
path algebra; both sides expand to `e_i · e_j · e_k` evaluated
via the structure tensor's chain rule.)*

**Proof technique.**

1. Restrict the sum to path-algebra slots `a` (off-path slots
   contribute zero by `_padding_distinguishable`).
2. Unfold via the `pathSlotStructureConstant` definition: the
   sum becomes `∑_a [pathMul slot_i slot_j = some slot_a] *
   [pathMul slot_a slot_k = some slot_l]`.
3. The sum collapses (via `Finset.sum_eq_single`) to the
   single contribution from
   `slot_a = pathMul slot_i slot_j` (if it exists).
4. Both sides reduce to `1[pathMul (slot_i) (pathMul slot_j
   slot_k) = some slot_l]` (using path-algebra associativity:
   `pathMul (pathMul a b) c = pathMul a (pathMul b c)`).

**Sub-lemmas needed (each ≤ 80 LOC).**

* **1.2.1 `encoder_associativity_lhs_eq_pathMul_chain` (~80 LOC):**
  Closed form of LHS as
  `[pathMul (pathMul slot_i slot_j) slot_k = some slot_l]`.
* **1.2.2 `encoder_associativity_rhs_eq_pathMul_chain` (~80 LOC):**
  Closed form of RHS, symmetric.
* **1.2.3 `pathMul_assoc` (already in `PathAlgebra.lean`):**
  used to bridge the two closed forms.
* **1.2.4 `encoder_associativity_identity` (~30 LOC):**
  composition of the above.

**Mathlib anchors.** `Finset.sum_eq_single`, `Finset.sum_congr`,
`pathMul_assoc` (existing). The path-algebra `Option`-typed
`pathMul`'s associativity flows through `Option.bind`-style
calculation.

**Risk.** Low–Medium. The associativity expansion is technical
but follows a standard pattern (path-algebra associativity →
structure-tensor identity). ~50 LOC reserve for index
management.

**Verification gate.** `encoder_associativity_identity` proven
for all `m`; non-vacuity at `m = 1, 2`.

### Layer 1.3 — Encoder is "non-degenerate" on path slots (~100 LOC)

**File:** extends `EncoderSlabEval.lean`.

**Goal.** Prove a useful corollary: the encoder evaluated at
any path-algebra slot is non-degenerate enough to determine
the slot's identity. Specifically:

* `encoder_path_identity_pairing`: `∀ (i : Fin (dimGQ m))`
  with `i` a path-algebra slot,
  `∑ j, encode m adj i j j = (number of `(j, k)` pairs with
  `pathMul slot_i slot_j = some slot_k`)`.

This gives a way to distinguish vertex slots from
present-arrow slots based on their "path-multiplication
fan-out" count, an algebraic invariant that the algebra-iso
will preserve.

**Risk.** Low. Direct counting argument.

### Phase 1 deliverables and gates

* One new `.lean` module (`EncoderSlabEval.lean`).
* `Orbcrypt.lean` extended with one new import.
* `scripts/audit_phase_16.lean` extended with `#print axioms`
  for every new public declaration; non-vacuity examples on
  `m ∈ {1, 2}`.
* CLAUDE.md change-log entry.
* Verification: `lake build` succeeds; audit script clean.

**Consumer.** Phase 3 (the algebra-iso bridge) consumes the
associativity identity directly. Phases 4-5 use the per-slot
evaluation lemmas to argue about encoder structure.

---

## Phase 2 — Path-block linear restriction (parametric in π) (~700 LOC)

**Goal.** Build the linear-algebra infrastructure needed by
Phase 3: given a permutation `π : Equiv.Perm (Fin (dimGQ m))`
(supplied as a free parameter; Phase 3 fixes it), construct
the path-block subspace, the path-block restriction of `g.1`,
and the linear-equivalence machinery.

**Why parametric in π.** Phase 3 derives π from algebra-iso
structure, but Phase 2's lemmas can be stated and proven
without committing to a specific π. This separates the
"linear-algebra bookkeeping" (Phase 2) from the "algebraic
content" (Phase 3).

### Layer 2.1 — Path-block subspace + basis (~200 LOC)

**File:** `Orbcrypt/Hardness/GrochowQiao/PathBlockSubspace.lean` (new).

**Public surface.**

| Declaration | Statement | Notes |
|-------------|-----------|-------|
| `pathBlockSubspace m adj : Submodule ℚ (Fin (dimGQ m) → ℚ)` | `Submodule.span ℚ (Set.range (fun j : pathSlotIndices m adj => Pi.single j 1))` | The indicator-vector subspace on path slots. |
| `paddingSubspace m adj : Submodule ℚ (Fin (dimGQ m) → ℚ)` | symmetric for padding slots | |
| `pathBlockBasis m adj : Basis (pathSlotIndices m adj) ℚ (pathBlockSubspace m adj)` | Mathlib basis | via `Basis.mk` |
| `pathBlockSubspace_orthogonal_paddingSubspace` | `pathBlockSubspace ⊓ paddingSubspace = ⊥` | direct from disjoint Finsets |
| `pathBlockSubspace_sup_paddingSubspace_eq_top` | `pathBlockSubspace ⊔ paddingSubspace = ⊤` | from partition theorem (Stage 2) |

**Risk.** Low. Pure Mathlib `Submodule.span` + `Basis.mk`
bookkeeping.

### Layer 2.2 — Path-block matrix (parametric in π) (~150 LOC)

**File:** extends `PathBlockSubspace.lean`.

**Definition.**
```
def pathBlockMatrix (m : ℕ)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (π : Equiv.Perm (Fin (dimGQ m))) :
    Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ :=
  g.1.val * (liftedSigmaMatrix m π⁻¹)
```

*(Composes `g.1.val` with the inverse of π's permutation
matrix. When π is partition-preserving, this matrix has
block-diagonal structure aligned to the path/padding partition
of `adj₁`.)*

**Public surface.**

| Declaration | Statement |
|-------------|-----------|
| `pathBlockMatrix_apply` | unfolding lemma `(pathBlockMatrix g π) i j = ∑_a g.1(i, a) * permMatrix(π⁻¹)(a, j)` |
| `pathBlockMatrix_at_partition_preserving_π` | `pathBlockMatrix g π i j` simplifies to `g.1(i, π j)` (using `permMatrix(π⁻¹)(a, j) = δ(a, π j)`) |

**Risk.** Low. `liftedSigmaMatrix_apply` already in `PermMatrix.lean`.

### Layer 2.3 — Conditional linear restriction (~250 LOC)

**File:** extends `PathBlockSubspace.lean`.

**Goal.** Given a hypothesis that `pathBlockMatrix g π` has
block-diagonal structure (i.e., its path-to-padding off-diagonal
block is zero), restrict it to a linear map between
`pathBlockSubspace`s of `adj₁` and `adj₂`.

**Public surface.**

| Declaration | Statement |
|-------------|-----------|
| `pathBlockMatrix_restricts_to_pathBlockSubspace` | conditional: under `(∀ i ∈ pathSlotIndices m adj₁, ∀ j ∈ paddingSlotIndices m adj₂, pathBlockMatrix g π i j = 0)`, the matrix's restriction to vectors supported on `pathSlotIndices m adj₁` lands in `pathBlockSubspace m adj₂` |
| `gl3_restrict_to_pathBlock` | the restricted linear map `pathBlockSubspace m adj₁ →ₗ[ℚ] pathBlockSubspace m adj₂` |
| `gl3_restrict_to_pathBlock_isLinearEquiv` | conditional: when `g` is GL (i.e., invertible) and the symmetric padding-to-path block also vanishes, the restriction is a `LinearEquiv` |

**Mathematical content.** Pure Mathlib `LinearMap.restrict`
+ `Submodule.subtype` bookkeeping. The conditional hypotheses
are what Phase 3 establishes for the specific π it constructs.

**Risk.** Low–Med. Index management is delicate but bounded.

### Layer 2.4 — Path-block subspace ↔ presentArrowsSubspace (~100 LOC)

**File:** extends `PathBlockSubspace.lean`.

**Goal.** Bridge `pathBlockSubspace m adj ≤ Fin (dimGQ m) → ℚ`
to `presentArrowsSubspace m adj ≤ pathAlgebraQuotient m =
QuiverArrow m → ℚ` via `slotEquiv` + `slotToArrow`. This
bridge is needed so Phase 3's algebra-iso lands on the
existing `pathAlgebraQuotient` infrastructure (rather than on
the indicator-subspace where `pathBlockMatrix` naturally
operates).

**Public surface.**

| Declaration | Statement |
|-------------|-----------|
| `presentArrowsSubspace m adj : Submodule ℚ (pathAlgebraQuotient m)` | `Submodule.span ℚ ((vertexIdempotent m '' Set.univ) ∪ (Set.image2 (arrowElement m) <expression for present arrows>))` |
| `pathBlock_to_presentArrows : pathBlockSubspace m adj ≃ₗ[ℚ] presentArrowsSubspace m adj` | bijection via slotEquiv + slotToArrow |

**Risk.** Low–Med. `Equiv.subtypeCongr` + `Basis.constr`-style
lift.

### Phase 2 deliverables and gates

* One new `.lean` module (`PathBlockSubspace.lean`, ~700 LOC).
* `Orbcrypt.lean` extended with one new import.
* `scripts/audit_phase_16.lean` extended with `#print axioms`
  for each public declaration plus non-vacuity examples on
  `m ∈ {1, 2}`.
* CLAUDE.md change-log entry.

**Consumer.** Phase 3 supplies π and the partition-preservation
hypotheses; Phase 2's `gl3_restrict_to_pathBlock` then becomes
a concrete linear map. Phase 3 lifts this further to an
algebra iso.

---

## Phase 3 — GL³ → algebra-iso bridge (~3,200 LOC via Approach A, RESEARCH-SCOPE)

**Goal.** Given `g • encode adj₁ = encode adj₂`, construct an
`AlgEquiv` `pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m`
that captures the algebra-isomorphism content of the GL³ tensor
isomorphism (relative to adj₁ vs adj₂).

**Why this is the deep step.** This is the heart of
Grochow–Qiao 2021 §4.3 — ~80 pages of the paper. There is no
"shallow" approach: every formalization route requires
substantial multilinear-algebra content. The two main approaches
are described below; the plan does not commit to either, since
which is more tractable in Lean is itself a research question.

### Approach A — Tensor stabilizer / Manin-style (RECOMMENDED, ~2,400–2,800 LOC)

**Why recommended.** Approach A is the cleanest formalization
strategy because:

1. It uses the **encoder's polynomial identities** (Phase 1's
   associativity identity) as the central technical lever,
   building cleanly on existing Phase-1 content.
2. Once the polynomial framework is in place, the partition-
   preservation step (sub-task A.3) and the algebra-iso
   construction (sub-tasks A.5–A.6) decompose naturally into
   tractable pieces.
3. The "Manin tensor stabilizer" technique is a standard tool
   in algebraic-tensor-rank theory; the formalization
   prerequisites are well-defined.
4. Approach A's intermediate deliverables (e.g.,
   `encoder_polynomial_identities`, the Manin theorem itself)
   are independently useful — they advance Mathlib's
   tensor-algebra coverage even if the workstream stalls.

**High-level argument.**

The encoder `T = grochowQiaoEncode m adj` satisfies a *family
of polynomial identities* (associativity, distinguished-padding
diagonal, padding orthogonality). These identities are
preserved under GL³ action (because they are multilinear in
T's entries, and GL³ acts by multilinear transformations).
For two encoders `T₁ = encode adj₁` and `T₂ = encode adj₂`
with `g • T₁ = T₂`, both encoders satisfy the same polynomial
identities. Combined with Manin's theorem (which says
"GL³-isomorphic associative-tensor encodings induce
algebra-isomorphic algebras"), this delivers an algebra iso
`A(adj₁) ≃ A(adj₂)`.

The argument decomposes into **6 named sub-tasks** (A.1 → A.6)
with concrete LOC budgets, dependencies, and Mathlib API
verifications. Each sub-task is independently auditable.

| Sub-task | Title | LOC | Risk |
|----------|-------|-----|------|
| A.1 | Encoder polynomial-identity catalogue | ~250 | Low |
| A.2 | GL³ action preserves polynomial identities | ~300 | Low–Med |
| A.3 | Distinguished-padding rigidity (partition preservation) | ~700 | **High** |
| A.4 | Restriction to path-only structure tensor | ~250 | Med |
| A.5 | Manin tensor-stabilizer theorem (prerequisite) | ~600 | **High** |
| A.6 | Algebra-iso construction + AlgEquiv packaging | ~400 | Med |
| | **Approach A total** | **~2,500** | |

Plus ~300 LOC reserve for Mathlib-API hand-roll if needed
(see per-sub-task risk analysis).

#### Sub-task A.1 — Encoder polynomial-identity catalogue (~250 LOC, Low risk)

**Goal.** Catalogue and prove the family of polynomial
identities the encoder satisfies. These identities will be
used by sub-tasks A.2 (preservation under GL³) and A.3
(partition-preservation argument).

**Public surface.**

| Declaration | Statement | LOC |
|-------------|-----------|-----|
| `encoder_assoc_path` | (re-export of Phase 1.2 `encoder_associativity_identity`) | ~5 |
| `encoder_diag_at_path_in_zero_one` | `i path-algebra slot → encode m adj i i i ∈ {0, 1}` | ~30 |
| `encoder_diag_at_padding_eq_two` | `i padding slot → encode m adj i i i = 2` | ~30 |
| `encoder_off_diag_path_padding_zero` | `i path, j padding → encode m adj i j k = 0 ∧ encode m adj i k j = 0 ∧ encode m adj j i k = 0` (re-export of `_padding_distinguishable`) | ~30 |
| `encoder_padding_diag_only` | `i padding slot → encode m adj i j k ≠ 0 ↔ j = i ∧ k = i` | ~50 |
| `encoder_unit_compatibility` | `∑_v encode m adj (vertexSlot v) j k = δ(j, k)` for path-algebra `j, k` (encodes `(∑_v e_v) · e_j = e_j`, the unit identity) | ~80 |

**Mathematical content.**

`encoder_diag_at_path_in_zero_one` follows from Phase 1.1's
per-slot evaluation: vertex slot diagonal = 1, present-arrow
slot diagonal = 0.

`encoder_padding_diag_only` follows from the encoder's
piecewise definition + `_padding_distinguishable`: at padding
slot `i`, the encoder uses `ambientSlotStructureConstant`,
which is `if i = j ∧ j = k then 2 else 0`.

`encoder_unit_compatibility` is the **multiplicative-identity
identity**: in the path algebra `pathAlgebraQuotient m`, the
unit element is `1 = ∑_v vertexIdempotent v`, and `1 · e_j =
e_j` for any `j`. This translates to the structure-tensor
identity `∑_{vertex slots i} T(i, j, k) = δ(j, k)` for path-
algebra `(j, k)`.

**Sub-lemma decomposition (each ≤ 80 LOC).**

* **A.1.1.** `encoder_diag_at_path_in_zero_one` — direct
  case-split on slot kind via `slotEquiv`.
* **A.1.2.** `encoder_diag_at_padding_eq_two` — uses Stage 0
  `grochowQiaoEncode_diagonal_padding`.
* **A.1.3.** `encoder_padding_diag_only` — uses
  `_padding_distinguishable` + `ambientSlotStructureConstant`'s
  `if i = j ∧ j = k` shape.
* **A.1.4.** `encoder_unit_compatibility_at_vertex_slots` —
  case-split: when `j = vertex v`, only `i = vertex v`
  contributes (`pathMul (.id v) (.id v) = some (.id v)`); when
  `j = arrow u v` (present), only `i = vertex u` contributes
  (`pathMul (.id u) (.edge u v) = some (.edge u v)`).

**Mathlib anchors.** `pathMul_id_id`, `pathMul_id_edge`
(existing in `PathAlgebra.lean`); `Finset.sum_eq_single`;
Stage 0 / Stage 2 diagonal-value lemmas.

**Risk.** Low. Pure structural unfolding.

**Verification gate.** Each lemma's `#print axioms` reports
standard Lean trio only; non-vacuity at `m ∈ {1, 2}`.

**Consumer.** Sub-tasks A.2 and A.3.

#### Sub-task A.2 — GL³ action preserves polynomial identities (~300 LOC, Low–Med risk)

**Goal.** For any 3-tensor `T : Tensor3 n F` and any GL³ triple
`g`, certain polynomial identities (associativity, padding
diagonality) are preserved by the GL³ action `g • T`. This is
the **multilinearity preservation** content needed for sub-task
A.3 to apply A.1's identities to `g • T₁ = T₂`.

**Why this is non-trivial.** The associativity identity
`∑_a T(i, j, a) · T(a, k, l) = ∑_a T(j, k, a) · T(i, a, l)` is
a quartic polynomial in T's entries. Under
`(g • T)(i, j, k) = ∑_{a,b,c} g.1(i,a) g.2(j,b) g.3(k,c) T(a,b,c)`,
the identity becomes a degree-8 polynomial in g's entries
times T's entries. Showing this identity holds for `g • T`
when it holds for T requires careful index manipulation.

**Public surface.**

| Declaration | Statement |
|-------------|-----------|
| `tensorContract_assoc_preserved` | If T satisfies the associativity identity (on a subset of indices closed under the multiplicative table), then `g • T` also satisfies it (with the same indices, after left-multiplying by g₁). |
| `tensorContract_diag_preserved_for_invariant_diagonal` | A SPECIAL case: if T's diagonal entries are restricted to a discrete invariant set (e.g., `{0, 1, 2}` for our encoder), this restriction is preserved by GL³ ONLY when g is a permutation matrix triple (NOT general GL³). |

> **Important honest note:** the second claim
> (`_diag_preserved_for_invariant_diagonal`) is NOT preserved
> for general GL³ — it holds only for permutation-matrix
> triples. For arbitrary GL³, diagonal entries change. This
> is a key reason sub-task A.3 (distinguished-padding
> rigidity) is genuinely hard: the discrete-diagonal
> invariance must be DERIVED, not assumed.

**Mathematical content of `tensorContract_assoc_preserved`.**

Let `T' = g • T`. The associativity identity for `T'`:
```
∑_a T'(i, j, a) · T'(a, k, l) = ∑_a T'(j, k, a) · T'(i, a, l)
```

Expand both sides via `unfold₁_tensorContract` (or directly via
`tensorContract` definition), use
`Finset.sum_comm` extensively, and reduce to the original
associativity identity for T (with index relabeling).

The cleanest formalization is probably to:

1. Define a "tensor associativity predicate" as a `Prop`:
   `IsAssociativeTensor T := ∀ i j k l, ∑_a T i j a * T a k l = ∑_a T j k a * T i a l`.

2. Prove `IsAssociativeTensor T → IsAssociativeTensor (g • T)`.
   This takes a few hundred LOC of `Finset.sum`-arithmetic but
   is mechanical.

3. Combine with A.1's `encoder_assoc_path` to conclude:
   `IsAssociativeTensor (g • encode adj₁) ↔ IsAssociativeTensor (encode adj₁)`.

**Sub-lemma decomposition (each ≤ 100 LOC).**

* **A.2.1** `IsAssociativeTensor` definition (~10 LOC).
* **A.2.2** `IsAssociativeTensor.smul` — preservation under
  GL³ action (~150 LOC). The technical core; uses
  `Finset.sum_comm`, `unfold₁_tensorContract`, and three
  applications of multilinearity.
* **A.2.3** `encoder_isAssociativeTensor` — apply A.1's
  `encoder_assoc_path` to derive the predicate for the
  encoder (~50 LOC). Note: A.1's identity is conditional on
  all four indices being path-algebra; A.2.3 must extend to
  ALL indices (the off-path entries contribute zero on both
  sides by `encoder_off_diag_path_padding_zero`).
* **A.2.4** `encoder_unit_compatibility_smul` — GL³ also
  preserves the unit-compatibility identity from A.1.6 (~80 LOC).

**Mathlib anchors.** `Finset.sum_comm`, `Finset.sum_congr`,
`Finset.mul_sum`, `Finset.sum_mul`, `unfold₁_tensorContract`
(Stage 1), `tensorContract` definition (`TensorAction.lean`).

**Risk.** Low–Med. The sum manipulations are mechanical but
require careful index tracking. ~80 LOC reserve for index
bookkeeping.

**Verification gate.** `IsAssociativeTensor.smul` proven for
arbitrary `n`, `F` (CommRing); `encoder_isAssociativeTensor`
proven for the GQ encoder; non-vacuity at `m = 1, 2`
(verify via `decide` on small encoders).

**Consumer.** Sub-task A.3.

#### Sub-task A.3 — Distinguished-padding rigidity (~700 LOC, **High risk**)

**Goal.** Use the polynomial identities from A.1 (preserved
by GL³ via A.2) plus the encoder's distinguished-padding
structure (post-Stage-0) to show that **a GL³ tensor iso
between two encoders preserves the path/padding partition**.

Concretely:
```
g • encode m adj₁ = encode m adj₂ →
  ∃ π : Equiv.Perm (Fin (dimGQ m)),
    π '' (pathSlotIndices m adj₁) = pathSlotIndices m adj₂ ∧
    π '' (paddingSlotIndices m adj₁) = paddingSlotIndices m adj₂
```

This is the **central technical content of Approach A**, and
the genuinely deep step from Grochow–Qiao 2021 §4.3. It IS
solvable (the paper proves it), but the formalization is
substantial.

**Mathematical insight (why this works).**

The padding diagonal is `2`, while path-algebra diagonals are
in `{0, 1}`. Under arbitrary GL³, diagonals don't transform
trivially. BUT: the polynomial-identity framework constrains
the GL³ stabilizers in a way that forces them to act compatibly
with the padding structure.

Specifically, the encoder has **TWO** independent
multiplicative structures within it:

1. The path-algebra multiplication on path-algebra slots
   (associative; satisfies A.1's identity with non-trivial
   structure constants).
2. The padding "multiplication" on padding slots (a
   `δ_{i=j=k}`-only structure, scaled by 2; trivially
   associative — it's essentially a direct sum of trivial
   1-dimensional algebras).

A GL³ iso between two encoders must preserve BOTH structures
(because both are encoded as polynomial identities in the
encoder). Since the two structures have **incompatible
multiplicative behaviour** (path-algebra multiplications
generally produce non-zero off-diagonal entries; padding
"multiplications" only produce diagonal entries), no GL³ iso
can mix them.

**Formalization breakdown — 5 sub-sub-tasks.**

##### A.3.1 — Padding "trivial-algebra" identity (~80 LOC)

* **Statement.** `encoder_padding_trivial_algebra`:
  ```
  ∀ (i j k : Fin (dimGQ m)) padding slots,
    encoder m adj i j k = if i = j ∧ j = k then 2 else 0
  ```
  (i.e., the padding portion is a direct sum of trivial
  1-dim algebras, each spanned by a single padding slot.)

* **Proof.** Direct from A.1.3 + the encoder's piecewise
  definition.

* **Consequence.** The padding portion satisfies the trivial
  associativity identity with a particular non-trivial scalar
  (2), which differs from the path-algebra portion's scalars
  (0 and 1).

##### A.3.2 — Padding-rank polynomial invariant (~150 LOC)

* **Statement.** Define a polynomial invariant
  `padding_rank_invariant : Tensor3 n F → ℕ` such that:
  - For the encoder, `padding_rank_invariant (encode m adj) =
    |paddingSlotIndices m adj|`.
  - For ANY tensor T satisfying A.1's identities + A.3.1's
    padding identity, the invariant is GL³-invariant.

  *Concrete construction:* the invariant could be defined as
  "the number of `i` such that `(T i i i, ∑_a T(i, i, a))`
  takes the value `(2, 2)` and the slab `T(i, ·, ·)` has
  rank 1". Verify this characterizes padding slots and is
  GL³-invariant by combining A.1's identities with A.2's
  preservation.

  *Note: this is non-trivial; the exact form of the
  invariant is part of A.3's research-scope content.*

* **Risk.** **High.** The invariant must satisfy three
  properties simultaneously: (i) it equals
  `|paddingSlotIndices|` on the encoder, (ii) it's GL³-
  invariant, (iii) it's expressible as a polynomial in the
  tensor's entries. Whether ALL three properties can be
  simultaneously satisfied with a single invariant is the
  research question. ~200 LOC reserve if multiple
  invariants must be combined.

##### A.3.3 — Padding-cardinality preservation (~80 LOC)

* **Statement.**
  `g • encode m adj₁ = encode m adj₂ →
    |paddingSlotIndices m adj₁| = |paddingSlotIndices m adj₂|`.

* **Proof.** Direct from A.3.2 (apply the invariant to both
  encoders; the invariance under GL³ + the encoder-equality
  give equality of cardinalities).

##### A.3.4 — Path-cardinality preservation (~30 LOC)

* **Statement.**
  `g • encode m adj₁ = encode m adj₂ →
    |pathSlotIndices m adj₁| = |pathSlotIndices m adj₂|`.

* **Proof.** Total dimension is fixed (`dimGQ m` in both); A.3.3
  gives padding cardinality equality; subtracting:
  `|pathSlotIndices| = dimGQ m - |paddingSlotIndices|`.

##### A.3.5 — Constructing the partition-preserving permutation (~360 LOC)

* **Goal.** Combine A.3.3 + A.3.4 with Stage 3's existing
  `partitionPreservingPermFromEqualCardinalities` to construct:
  ```
  π : Equiv.Perm (Fin (dimGQ m)) such that
    π '' (pathSlotIndices m adj₁) = pathSlotIndices m adj₂ ∧
    π '' (paddingSlotIndices m adj₁) = paddingSlotIndices m adj₂.
  ```

* **Public surface.**

  | Declaration | Statement |
  |-------------|-----------|
  | `gl3_partition_preserving_perm_via_invariant` | the constructed π (uses A.3.3's cardinality result + Stage 3 infrastructure) |
  | `gl3_partition_preserving_perm_isThreePartition` | (further refinement) π also preserves vertex-vs-present-arrow split within path slots — proven via A.1's diagonal-value invariant restricted to path slots |

* **Proof.** A.3.3's cardinality equality is the hypothesis
  of Stage 3's `partitionPreservingPermFromEqualCardinalities`.
  Apply it to obtain π. The "isThreePartition" refinement
  follows from A.1's `encoder_diag_at_path_in_zero_one`:
  within path slots, the diagonal value distinguishes vertex
  (1) from present-arrow (0), and this distinction is
  preserved under the polynomial-identity-respecting GL³
  action.

  Wait — we noted in A.2 that "diagonal value preservation
  is generally false under GL³". So how does `isThreePartition`
  work?

  **Honest answer:** `isThreePartition` is genuinely deeper
  than the binary path/padding split. The vertex-vs-present-
  arrow split depends on subtler invariants (e.g., the
  number of non-zero entries in the slab, weighted by
  associativity-witnesses). Constructing this finer invariant
  is part of A.3.5's content.

  **Risk reserve:** ~150 LOC reserve specifically for the
  `isThreePartition` refinement. If it proves too hard,
  Phase 5's argument can be re-routed through the binary
  partition + radical-preservation (which is enough for
  arrow preservation; the vertex-vs-arrow distinction
  emerges algebraically from the radical structure).

**Sub-task A.3 deliverables.**

* One new `.lean` module:
  `Orbcrypt/Hardness/GrochowQiao/PaddingRigidity.lean`.
* `padding_rank_invariant` definition + GL³-invariance proof.
* `gl3_partition_preserving_perm_via_invariant` headline.
* Audit-script `#print axioms` entries.

**Risk (overall A.3).** **High.** This is the genuinely deep
step. The 5 sub-sub-tasks decompose ~700 LOC into ≤ 360 LOC
pieces. **The biggest unknown is A.3.2's polynomial
invariant** — finding the right one is itself research. If
A.3.2 proves intractable, an alternative is to derive the
partition preservation directly from sub-tasks A.5–A.6
(Manin's theorem implies it as a corollary). This rerouting
adds ~200 LOC to A.5/A.6 but eliminates A.3.2/A.3.3.

**Verification gate.** Each sub-sub-task individually verified;
non-vacuity at `m = 1, 2, 3`; `gl3_partition_preserving_perm_via_invariant`
returns a concrete π for the identity GL³ triple.

**Consumer.** Sub-tasks A.4 and A.5.

#### Sub-task A.4 — Restriction to path-only structure tensor (~250 LOC, Med risk)

**Goal.** Use Phase 2's `pathBlockMatrix` infrastructure
together with A.3's partition-preserving permutation π to
restrict `g.1, g.2, g.3` to the path-algebra subspace,
producing a GL³ triple that acts on the **path-only structure
tensor** (the "restricted encoder").

**Mathematical content.**

A.3 gives π : `Equiv.Perm (Fin (dimGQ m))` preserving the
path/padding partition. Phase 2's `pathBlockMatrix g π` is
then well-defined and (by A.3) has block-diagonal structure.
Specifically, `pathBlockMatrix g π = path-component ⊕
padding-component` (after `Equiv.sumCompl`-style reindexing).

**Define the path-only restricted tensor:**
```
T₁_path : Tensor3 |pathSlotIndices m adj₁| ℚ :=
  fun (i j k : pathSlotIndices m adj₁) =>
    encode m adj₁ i.val j.val k.val
```
(i.e., the encoder restricted to path-algebra slots, viewed
as a smaller tensor).

**Restricted GL³ triple.** Define
`(g.1', g.2', g.3') : GL × GL × GL` (each with index set
`pathSlotIndices m adj₁ → pathSlotIndices m adj₂`) as the
path-block components of `pathBlockMatrix g π`,
`pathBlockMatrix₂ g π`, `pathBlockMatrix₃ g π`.

**Key claim.** `(g.1', g.2', g.3') • T₁_path = T₂_path` (where
`T₂_path` is the path-only restriction of `encode m adj₂`).

This is the structural fact that A.4 establishes: the path-
block restriction of GL³ acts as a GL³ tensor iso between the
path-only structure tensors of the two encoders.

**Public surface.**

| Declaration | Statement | LOC |
|-------------|-----------|-----|
| `pathOnlyStructureTensor m adj : Tensor3 (pathSlotIndices m adj).card ℚ` | path-restricted encoder | ~30 |
| `pathOnlyStructureTensor_apply` | unfolding | ~10 |
| `gl3_path_block_restriction` | the restricted GL³ triple, conditional on A.3's π | ~80 |
| `gl3_path_block_restriction_action` | `(g.1', g.2', g.3') • T₁_path = T₂_path` | ~130 |

**Proof technique.** A.3's `gl3_partition_preserving_perm_via_invariant`
gives π preserving path/padding. The off-diagonal block of
`pathBlockMatrix g π` vanishes (which is what
"partition-preserving" means at the matrix level). Hence
`pathBlockMatrix g π = (path-block) ⊕ (padding-block)` after
sumCompl-reindexing. The path-block component restricts to a
linear map on the indicator subspace. Phase 2's
`gl3_restrict_to_pathBlock` provides the formal `LinearEquiv`.

**Sub-lemma decomposition (each ≤ 100 LOC).**

* **A.4.1** `pathOnlyStructureTensor` — definition + apply
  (~40 LOC).
* **A.4.2** `pathOnlyStructureTensor_isAssociative` — direct
  from A.1's `encoder_assoc_path` (restricted to path-only
  slots). ~30 LOC.
* **A.4.3** `gl3_path_block_restriction` — uses A.3's π +
  Phase 2's `gl3_restrict_to_pathBlock` (~80 LOC).
* **A.4.4** `gl3_path_block_restriction_action` — verify the
  restricted triple acts as required on the restricted tensor
  (~100 LOC). The technical core; uses
  `unfold₁_tensorContract` + index restriction.

**Mathlib anchors.** `Equiv.sumCompl`, `Matrix.fromBlocks`
(used in Phase 2); `LinearMap.restrict`; Phase 2's
`pathBlockMatrix_at_partition_preserving_π`.

**Risk.** Medium. Index management is the main challenge.
Reserve ~50 LOC for sumCompl-reindex bookkeeping.

**Verification gate.** `gl3_path_block_restriction_action`
proven; non-vacuity at `m = 1, 2`.

**Consumer.** Sub-tasks A.5 and A.6.

#### Sub-task A.5 — Manin tensor-stabilizer theorem (~600 LOC, **High risk**, prerequisite)

**Goal.** Formalize the **tensor stabilizer ⟹ algebra
isomorphism** theorem for unital associative algebras.

**Statement (target theorem).**

```
theorem manin_tensor_stabilizer_iso
    {n F} [Field F] (A B : Type*)
    [Ring A] [Ring B] [Algebra F A] [Algebra F B]
    [Module.Finite F A] [Module.Finite F B]
    (b_A : Basis (Fin n) F A) (b_B : Basis (Fin n) F B)
    (T_A := structure tensor of A in basis b_A)
    (T_B := structure tensor of B in basis b_B)
    (g : GL (Fin n) F × GL (Fin n) F × GL (Fin n) F)
    (h_action : g • T_A = T_B)
    -- non-degeneracy: A and B both have a multiplicative
    -- identity expressible via the basis (e.g., 1_A = ∑ c_i b_A i)
    (h_unit_A : ...) (h_unit_B : ...)
    -- compatibility: g₁, g₂, g₃ agree on the unit
    (h_unit_compat : ...) :
  ∃ (φ : A ≃ₐ[F] B), <φ extends g₁ to an algebra iso>
```

The exact form of the unit-compatibility hypothesis depends
on a choice of structure-tensor convention; the precise
statement should be derived in coordination with the existing
`pathAlgebraQuotient` infrastructure.

**Why this is research-scope.** Manin's "quantum tensor
stabilizer" theory is a substantial body of work in
algebraic geometry. The simplified version we need (tensor
iso ⟹ algebra iso) is a known consequence but lacks an
existing Lean formalization at the pinned commit `fa6418a8`.
Hand-rolling it requires:

1. Defining the abstract "structure tensor of an algebra in
   a basis" Mathlib-quality concept (~150 LOC).
2. Proving the `_smul` action equivariance via
   `Basis.constr` (~100 LOC).
3. The core technical content: showing that a GL³ tensor iso
   `g · T_A = T_B` with appropriate unit-compatibility forces
   `g₁` to extend to a multiplicative map (algebra hom). ~300
   LOC.
4. Inverting via `g⁻¹` to upgrade to algebra iso. ~50 LOC.

**Sub-sub-task breakdown.**

##### A.5.1 — Abstract algebra structure-tensor (~150 LOC)

* `Algebra.structureTensor (b : Basis I F A) : Tensor3 |I| F`:
  `T_{ijk} = b.repr (b i * b j) k` (the coefficient of `b k`
  in the product `b i * b j`).
* `Algebra.structureTensor_apply` — unfolding lemma.
* `Algebra.structureTensor_symm` — the symmetric formula
  via `b.smul`.

##### A.5.2 — Algebra structure-tensor under GL action on basis (~100 LOC)

* For `A` a fixed algebra and `g : GL I F`, define a new
  basis `g · b := fun i => ∑_a g(i, a) · b a`. Then
  `Algebra.structureTensor (g · b) = some-GL³-action of g
  on Algebra.structureTensor b`. (The exact GL³-action shape
  is encoded by the Manin theorem.)
* `Algebra.structureTensor_basis_change` — the formula.

##### A.5.3 — Two-algebra tensor iso ⟹ algebra hom existence (~250 LOC)

* The technical core. Given:
  - `b_A : Basis I F A`, `b_B : Basis I F B`.
  - `g · structureTensor(b_A) = structureTensor(b_B)`.
  - Unit-compatibility hypothesis (the encoder satisfies
    A.1.6's `encoder_unit_compatibility`).

  Construct `φ : A → B` as a linear map by `φ (b_A i) =
  ∑_j g.1(i, j) b_B j`. Show `φ` is multiplicative.

  The multiplicativity proof uses A.5.2's structure-tensor
  basis-change formula + the GL³-iso hypothesis. Standard
  manipulation but ~250 LOC of careful index work.

##### A.5.4 — Upgrade to AlgEquiv (~50 LOC)

* Apply `g⁻¹` to construct the inverse `φ⁻¹`. Combine via
  `AlgEquiv.ofBijective` (Mathlib).

##### A.5.5 — Specialization to path algebra (~50 LOC)

* Apply A.5.3–A.5.4 with `A = pathAlgebraQuotient m_1` (with
  `adj₁`'s basis), `B = pathAlgebraQuotient m_2` (with
  `adj₂`'s basis). Get `pathAlgebraQuotient m_1 ≃ₐ[ℚ]
  pathAlgebraQuotient m_2`.

  *Note:* Both algebras are `pathAlgebraQuotient m` (for the
  same `m`), but with different bases (different `adj`
  values). The AlgEquiv produced is genuinely between the
  same underlying ℚ-vector space but with multiplications
  reflecting different graphs. This is the natural Lean
  formalization of "graph-iso encoded as algebra-iso".

**Mathlib API forecast.**

* `Basis.constr`, `Basis.equiv`, `Basis.repr` — present.
* `Algebra.structureTensor` — **not present**; A.5.1 hand-
  rolls it.
* "Manin tensor stabilizer" theorem — **not present**;
  A.5.3–A.5.4 hand-rolls the core specialization we need.
* `AlgEquiv.ofBijective` — present.

**Risk.** **High.** Several Mathlib gaps; A.5.3 is
mathematically deep. **Reserve: ~200 LOC for unforeseen
Mathlib gaps, sum-manipulation index issues, and edge cases
(e.g., handling the unital structure rigorously).**

**Verification gate.** `manin_tensor_stabilizer_iso` proven
in full generality; specialization to path algebra verified
on `m = 1, 2` non-vacuity examples.

**Consumer.** Sub-task A.6.

#### Sub-task A.6 — AlgEquiv construction + pathAlgebraQuotient bridge (~400 LOC, Med risk)

**Goal.** Compose A.4 and A.5 to deliver Phase 3's headline
theorem:

```
theorem gl3_induces_algEquiv_on_pathSubspace
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL × GL × GL)
    (hg : g • grochowQiaoEncode m adj₁ =
          grochowQiaoEncode m adj₂) :
  ∃ (ϕ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m),
    ϕ '' (presentArrowsSubspace m adj₁ : Set _) =
    presentArrowsSubspace m adj₂
```

**Why this is non-trivial (despite being "just composition").**
A.5 produces an AlgEquiv between the **path-only structure
tensors of adj₁ and adj₂**, viewed as restricted algebras on
distinct vector spaces (`pathSlotIndices m adj₁` vs
`pathSlotIndices m adj₂`). The Phase 3 headline requires an
AlgEquiv on `pathAlgebraQuotient m` (a single fixed algebra
type with two distinct presentation bases reflecting `adj₁`
and `adj₂`).

A.6 bridges these by:

1. Showing the path-only structure tensor of `adj` is
   isomorphic to the corresponding restriction of
   `pathAlgebraQuotient m` (essentially what
   `presentArrowsSubspace m adj` is).
2. Translating A.5's AlgEquiv between path-only tensors into
   an AlgEquiv on the full `pathAlgebraQuotient m` algebra
   (extending by zero on the complement, or by trivial
   identity on padding).

**Sub-sub-task breakdown.**

##### A.6.1 — Path-only tensor ↔ presentArrowsSubspace bridge (~150 LOC)

* Define a linear equivalence
  `pathOnlyAlgebra adj ≃ₗ[ℚ] presentArrowsSubspace m adj`
  via the `slotEquiv` + `slotToArrow` correspondence.
* Show the linear equiv is also an algebra equiv (preserves
  multiplication), using A.1's identities and Phase 2's
  `pathBlock_to_presentArrows` (Phase 2 Layer 2.4).

##### A.6.2 — Lift A.5's AlgEquiv to pathAlgebraQuotient (~150 LOC)

* A.5 produces `ϕ' : pathOnlyAlgebra adj₁ ≃ₐ[ℚ]
  pathOnlyAlgebra adj₂`.
* Apply A.6.1's bridge to translate to
  `ϕ'' : presentArrowsSubspace m adj₁ ≃ₐ[ℚ]
  presentArrowsSubspace m adj₂`.

  *(Wait: `presentArrowsSubspace` is a Submodule, not an
  algebra in general. Need to verify it inherits the algebra
  structure when adj's induced subset of present arrows is
  closed under multiplication.)*

* **Important correction.** `presentArrowsSubspace m adj` is
  the span of `vertexIdempotent v` (all `v`) ∪
  `arrowElement u v` (for present `(u, v)`). This subspace
  is closed under the path algebra's multiplication: vertex
  idempotents multiply to vertex idempotents (by
  orthogonality), arrow elements multiply to zero (by J²=0).
  So it IS a sub-algebra.

  Hence `ϕ''` is well-defined as an AlgEquiv between sub-
  algebras of `pathAlgebraQuotient m`.

* Extend `ϕ''` to a full AlgEquiv on `pathAlgebraQuotient m`
  by combining with trivial action on the complement. The
  complement is `Submodule.span ℚ (Set.range arrowElement \
  presentArrows)`-style — basis elements that are NOT in any
  adj. These should map to themselves under the trivial
  extension (or to corresponding elements of adj₂'s
  complement, depending on the formalization choice).

##### A.6.3 — Subspace-preservation property (~100 LOC)

* Show `ϕ '' (presentArrowsSubspace m adj₁ : Set _) =
  presentArrowsSubspace m adj₂` (the explicit subspace-
  preservation that Phase 5 needs).
* Direct from A.6.2's construction: the AlgEquiv was
  constructed precisely to map adj₁'s present-arrow subspace
  to adj₂'s.

**Sub-task A.6 deliverables.**

* New `.lean` module:
  `Orbcrypt/Hardness/GrochowQiao/AlgEquivFromGL3.lean`.
* `gl3_induces_algEquiv_on_pathSubspace` headline.
* `_apply_vertexIdempotent`, `_apply_arrowElement` simp
  lemmas (used by Phases 4, 5).
* Audit-script `#print axioms` entries.

**Mathlib anchors.** `AlgEquiv.ofBijective`, `LinearEquiv.ofBijective`,
`Submodule.subtype`, `Subalgebra` API.

**Risk.** Medium. Most content is Mathlib bookkeeping over
A.5's output. Reserve: ~80 LOC for the "extend AlgEquiv to
the complement" subtlety in A.6.2.

**Verification gate.** `gl3_induces_algEquiv_on_pathSubspace`
proven; subspace-preservation property explicit; non-vacuity
at `m = 1, 2`; identity GL³ produces AlgEquiv.refl.

**Consumer.** Phase 4.

#### Approach A — sub-task dependency graph

```
[Phase 1 lemmas (associativity, padding-distinguishability)]
       │
       ▼
   [A.1 — polynomial identity catalogue]
       │
       ▼
   [A.2 — GL³ preserves polynomial identities]
       │
       ▼
   [A.3 — distinguished-padding rigidity (HIGH)]
       │     produces π preserving partition
       ▼
   [A.4 — path-only structure tensor + restricted GL³]
       │     produces (g.1', g.2', g.3') • T₁_path = T₂_path
       │
       │     ┌────────────────────────────┐
       │     │                            │
       ▼     ▼                            │
   [A.5 — Manin theorem (HIGH)]           │
       │     A.5.1–A.5.5                  │
       │                                  │
       └─────────────────┬────────────────┘
                         ▼
            [A.6 — AlgEquiv on pathAlgebraQuotient]
                         │
                         ▼
       gl3_induces_algEquiv_on_pathSubspace
                         │
                         ▼
                    [Phase 4 input]
```

**Critical-path observations.**

* **A.3 is the bottleneck.** Its 700 LOC budget reflects the
  novel polynomial-invariant content (sub-sub-task A.3.2),
  which has the highest research-content density.
* **A.5 is the second bottleneck.** Manin's theorem (~600
  LOC) is independently substantial and Mathlib-quality
  reusable.
* **Sub-tasks A.1, A.2, A.4, A.6 are tractable** (~250–400
  LOC each, Low–Med risk).
* **Parallelizable.** A.1 and A.5 are largely independent
  (A.1 is encoder-specific; A.5 is general-algebra). They
  can be developed in parallel by two implementers.

#### Approach A — per-sub-task risk register

| Sub-task | Risk | Mitigation |
|----------|------|------------|
| A.1 | Low | Pure structural unfolding. ~50 LOC reserve for index management. |
| A.2 | Low–Med | Sum-arithmetic via `Finset.sum_comm`. ~80 LOC reserve. |
| A.3 | **High** | Polynomial-invariant existence is research-grade. Reroute fall-back: if A.3.2 stalls, derive partition preservation from A.5+A.6 directly (adds ~200 LOC to A.5 but eliminates A.3.2-A.3.4). Reserve: 200 LOC. |
| A.4 | Med | Index management with `Equiv.sumCompl`. ~50 LOC reserve. |
| A.5 | **High** | Manin theorem prerequisites are Mathlib-quality content not currently present. Several Mathlib gaps (e.g., `Algebra.structureTensor` doesn't exist). Reserve: 200 LOC. |
| A.6 | Med | Mostly composition; A.6.2's "extend AlgEquiv to complement" is the subtle step. Reserve: 80 LOC. |

**Total reserves:** ~660 LOC across all sub-tasks.

**Approach A grand total:** ~2,500 LOC (per-sub-task) + ~660
LOC (reserves) = **~3,200 LOC**. This is at the upper end of
Phase 3's overall ~2,000+ LOC budget; the difference reflects
honest acknowledgment that Approach A has substantial
Mathlib-prerequisite content (Manin's theorem).

#### Approach A — calendar estimate

* **Lower bound (team of 2 implementers, parallelizing A.1 +
  A.5 vs A.2/A.3/A.4 + A.6):** 4–6 months wall-clock.
* **Upper bound (single implementer, sequential):** 8–12
  months.
* **Stall scenarios:**
  - If A.3.2's polynomial invariant proves intractable:
    ~3 months to find an alternative or reroute via A.5+A.6.
  - If A.5.3's algebra-hom multiplicativity argument hits an
    unforeseen Mathlib gap: ~2 months extra for hand-roll.

The total **calendar uncertainty is ~6–18 months**, mirroring
Phase 3's overall budget.

### Approach B — Direct path-block algebra construction (alternative, ~2,000 LOC, NOT recommended)

**Brief description.** An alternative to Approach A that
attempts to derive partition preservation via diagonal-value
or associativity-witness invariants directly, without going
through Manin's theorem.

**Why NOT recommended.** Approach B encounters the same
research-grade content as Approach A's sub-task A.3
(deriving partition preservation from polynomial invariants),
but without the cleaner Manin-theorem framework that
Approach A's sub-task A.5 provides. Specifically:

* Approach B's Step 1 ("partition preservation by some
  invariant") is essentially Approach A's A.3 — same
  research challenge, no easier.
* Approach B's Step 3 ("argue the linear iso is
  multiplicative") is essentially Approach A's A.5 — same
  difficulty, but without the abstract Manin-theorem
  packaging that lets the result generalize cleanly.

**When to consider Approach B.** If, during Approach A's
implementation, sub-task A.5 (Manin's theorem) hits an
unexpected Mathlib obstacle that takes longer to resolve
than ~6 weeks, Approach B becomes a valid pivot — its more
"hands-on" path-block algebra construction may bypass the
problematic Mathlib gap.

**Outline (for completeness).**
1. Derive partition preservation directly from a polynomial
   invariant (analogous to A.3.2).
2. Use Phase 2's `gl3_restrict_to_pathBlock` to obtain a
   linear iso between path subspaces (just like Approach A's
   A.4).
3. Manually argue multiplicativity via Phase 1's encoder
   evaluation lemmas and the GL³-action equation expanded
   on basis elements. Hand-rolled, without the abstract
   Manin-theorem packaging.
4. Package as `AlgEquiv` via `AlgEquiv.ofBijective`.

**Status.** Approach B's Step 3 is the cost-driver: ~1,500
LOC of hand-rolled multiplicativity verification, without
the Mathlib-quality reusable content of A.5.

### Headline theorem (both approaches)

Both approaches yield the same Phase 3 deliverable:

```
theorem gl3_induces_algEquiv_on_pathSubspace
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL × GL × GL)
    (hg : g • grochowQiaoEncode m adj₁ =
          grochowQiaoEncode m adj₂) :
  ∃ (ϕ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m),
    ϕ '' (presentArrowsSubspace m adj₁ : Set _) =
    presentArrowsSubspace m adj₂
```

**Recommendation.** Default to Approach A (more
mathematically clean and produces reusable Mathlib content).
Pivot to Approach B only if Approach A's Manin-theorem
prerequisite (A.5) encounters unforeseen Mathlib gaps.

### Phase 3 deliverables and gates (Approach A)

* **5–6 new modules** under
  `Orbcrypt/Hardness/GrochowQiao/`:
  - `EncoderPolynomialIdentities.lean` (sub-task A.1, ~250
    LOC)
  - `TensorIdentityPreservation.lean` (sub-task A.2, ~300
    LOC)
  - `PaddingRigidity.lean` (sub-task A.3, ~700 LOC)
  - `PathOnlyTensor.lean` (sub-task A.4, ~250 LOC)
  - `ManinStabilizerTheorem.lean` (sub-task A.5, ~600 LOC)
    — Mathlib-quality reusable
  - `AlgEquivFromGL3.lean` (sub-task A.6, ~400 LOC)
* **LOC budget: ~2,500 LOC** sub-task content + **~660 LOC**
  reserves = **~3,200 LOC total**.
* **Calendar time: ~6–18 months** of focused effort. Lower
  bound assumes parallel implementation by 2 people; upper
  bound is single-implementer worst case.
* **Risk: Very High (RESEARCH-SCOPE).** Sub-tasks A.3 and
  A.5 are both research-grade.

**Verification gate.** `gl3_induces_algEquiv_on_pathSubspace`
proven for all `m`; `#print axioms` standard trio only;
non-vacuity at `m ∈ {1, 2, 3}` exhibiting the AlgEquiv on
concrete encoder pairs (e.g., adj₁ = adj₂ with identity GL³
yields `AlgEquiv.refl`); subspace-preservation property
explicit (required by Phase 5).

**Consumer.** Phase 4.

### Phase 3 alternative — partial discharge

If Phase 3 stalls beyond the planned calendar window, the
workstream can deliver **partial closure** by:

* Landing Phases 1, 2, 4, 5, 6 conditional on a research-
  scope `Prop` `GL3InducesAlgEquivOnPathSubspace` (a
  parametrized version of Phase 3's headline). This Prop
  becomes the new explicit research-scope obligation,
  replacing the v3-era `GL3PreservesPartitionCardinalities`
  + `GL3InducesArrowPreservingPerm` pair with a single
  cleaner statement.

This partial closure is strictly better than the current
Stage 0–5 state: it identifies the deep content as a single
well-defined `Prop` (rather than two coupled `Prop`s), and
makes all the surrounding plumbing unconditional. The full
discharge is then a future research milestone targeting a
single named obligation.

---

## Phase 4 — Wedderburn–Mal'cev σ extraction (~250 LOC)

**Goal.** Apply the existing `algEquiv_extractVertexPerm`
theorem (`Orbcrypt/Hardness/GrochowQiao/WedderburnMalcev.lean`)
to Phase 3's AlgEquiv to extract σ : Equiv.Perm (Fin m).

### Layer 4.1 — σ extraction from Phase 3 (~150 LOC)

**File:** `Orbcrypt/Hardness/GrochowQiao/SigmaFromGL3.lean` (new).

**Public surface.**

| Declaration | Statement |
|-------------|-----------|
| `gl3_to_vertexPerm` | `(g : GL × GL × GL) (hg : g • encode adj₁ = encode adj₂) → Equiv.Perm (Fin m)` |
| `gl3_to_vertexPerm_radical_witness` | `∃ (j : pathAlgebraQuotient m), j ∈ pathAlgebraRadical m ∧ ∀ v, (1 + j) * vertexIdempotent (gl3_to_vertexPerm v) * (1 - j) = ϕ (vertexIdempotent v)`, where `ϕ` is Phase 3's AlgEquiv |

**Construction.**
```lean
noncomputable def gl3_to_vertexPerm (g : GL × GL × GL)
    (hg : g • encode adj₁ = encode adj₂) :
    Equiv.Perm (Fin m) :=
  (algEquiv_extractVertexPerm m
    (gl3_induces_algEquiv_on_pathSubspace m adj₁ adj₂ g hg).choose).choose
```

(Direct composition: extract Phase 3's AlgEquiv, apply
`algEquiv_extractVertexPerm`, project to the σ component.)

**Risk.** Low. `algEquiv_extractVertexPerm` is fully proven in
the existing codebase; this is pure composition.

**Verification gate.** `#print axioms gl3_to_vertexPerm`
standard trio only; non-vacuity at `m ∈ {1, 2}`.

### Layer 4.2 — σ-action on basis elements (~100 LOC)

**File:** extends `SigmaFromGL3.lean`.

**Goal.** Establish how `gl3_to_vertexPerm` acts on
`vertexIdempotent` and `arrowElement` basis elements via the
WM radical-conjugation form.

**Public surface.**

| Declaration | Statement |
|-------------|-----------|
| `gl3_to_vertexPerm_apply_vertexIdempotent` | `ϕ (vertexIdempotent m v) = (1 + j) * vertexIdempotent m (gl3_to_vertexPerm v) * (1 - j)` for the WM j |
| `gl3_to_vertexPerm_apply_arrowElement` | `ϕ (arrowElement m u v)` is in the path-algebra radical (since `arrowElement ∈ J` and `ϕ` preserves `J`) |

**Mathematical content.** The first lemma is direct from
`algEquiv_extractVertexPerm`'s output specification. The
second lemma uses the algebra-iso radical-preservation
property: any algebra hom preserves the Jacobson radical.

**Sub-lemma needed.**

* `algEquiv_preserves_pathAlgebraRadical (~40 LOC):` for any
  `ϕ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m`,
  `ϕ '' (pathAlgebraRadical m : Set _) = pathAlgebraRadical m`.
  *Proof technique.* The radical is characterized algebraically
  (e.g., as the largest nilpotent ideal, or via primitive
  idempotents). `ϕ` preserves all these characterizations.
  Concretely: J = J² = 0 ⟹ φ(J) ⊆ φ(0) = 0... no wait, J² = 0
  means J*J = 0, NOT J = 0. The radical IS the span of arrow
  elements; `ϕ` of an arrow element is in the algebra; we need
  to show it's in the radical.

  *Better proof technique:* Use the hand-rolled
  `IsPrimitiveIdempotent` from `AlgebraWrapper.lean` +
  `vertexIdempotent_isPrimitive` + `AlgEquiv_preserves_isPrimitiveIdempotent`.
  Vertex idempotents map to primitive idempotents (which are
  conjugate to vertex idempotents by WM). The radical is
  characterized as `{x : x * (∑ vertexIdempotent v) = x ∧ x ≠
  ∑ scalar · vertexIdempotent v}` ... actually this is getting
  complex. Use Mathlib's `Algebra.Jacobson` framework if
  available, or hand-roll via:
  - `J = ⨆ {I : Ideal A | I.IsNilpotent}` (the largest
    nilpotent ideal).
  - `ϕ` preserves nilpotent ideals.
  - Hence `ϕ(J) ⊆ J`. Apply to `ϕ⁻¹` for the reverse.

**Risk.** Medium. The radical preservation is a standard
algebra fact but its formalization may require hand-rolling
~100 LOC if Mathlib's `Jacobson` API doesn't have the exact
form needed. **Reserve: ~100 LOC for hand-roll if needed.**

### Phase 4 deliverables and gates

* One new `.lean` module (`SigmaFromGL3.lean`, ~250 LOC).
* `Orbcrypt.lean` extended with one new import.
* `scripts/audit_phase_16.lean` extended with `#print axioms`
  for each public declaration; non-vacuity at
  `m ∈ {1, 2, 3}`.
* CLAUDE.md change-log entry.

**Consumer.** Phase 5.

---

## Phase 5 — Arrow preservation from σ (~400 LOC)

**Goal.** Prove that the σ extracted in Phase 4 preserves
arrow membership: `(.edge u v ∈ presentArrows m adj₁) ↔
(quiverMap m σ (.edge u v) ∈ presentArrows m adj₂)`.

This gives Prop 2's existential witness directly.

### Layer 5.1 — Arrow-image is non-zero scalar of σ-relabelled arrow (~250 LOC)

**File:** `Orbcrypt/Hardness/GrochowQiao/ArrowFromGL3.lean` (new).

**Mathematical content.** From Phase 4's
`gl3_to_vertexPerm_apply_arrowElement`, the AlgEquiv ϕ sends
each `arrowElement m u v` to **some element of the radical**.
We need to refine this to **a scalar multiple of
`arrowElement m (σ u) (σ v)`**.

**The argument.**

1. **Sandwich identity.** From Stage 5's `arrowElement_sandwich`:
   `arrowElement m u v = vertexIdempotent m u * arrowElement m u v *
   vertexIdempotent m v`.

2. **Apply ϕ (an AlgHom):**
   `ϕ (arrowElement m u v) = ϕ (vertexIdempotent m u) *
   ϕ (arrowElement m u v) * ϕ (vertexIdempotent m v)`.

3. **Substitute the WM form** for vertex idempotents (from
   Phase 4):
   `ϕ (vertexIdempotent m u) = (1 + j) * vertexIdempotent m (σ u) * (1 - j)`.

4. **Inner-conjugation collapse.** The cross-terms involving
   `j` and `arrow`-radical elements vanish via Stage 5's
   `inner_aut_radical_fixes_arrow`-style J²=0 cancellation
   (already in `AdjacencyInvariance.lean`). After collapse:
   `ϕ (arrowElement m u v) = vertexIdempotent m (σ u) *
   ϕ (arrowElement m u v) * vertexIdempotent m (σ v)`.

5. **Sandwich projects onto arrow-line.** From the path
   algebra basis decomposition of `ϕ (arrowElement m u v)`
   (some sum of vertex idempotents and arrow elements), the
   sandwich `vertexIdempotent (σ u) * X * vertexIdempotent (σ v)`
   projects onto the single basis line `arrowElement m (σ u) (σ v)`:
   - `e_{σu} * vertexIdempotent w * e_{σv}` is non-zero only
     if `σu = w = σv`, in which case it equals `e_{σu}`.
     But we need it to land in the arrow line, so this term
     contributes only to the vertex part of the result, which
     **must be zero** because `ϕ (arrowElement)` is in the
     radical (no vertex-idempotent component).
   - `e_{σu} * arrowElement m a b * e_{σv}` is non-zero only
     if `a = σu` AND `b = σv`, in which case it equals
     `arrowElement m (σ u) (σ v)`.

   So the result is `c · arrowElement m (σ u) (σ v)` for
   some scalar `c`.

6. **Non-vanishing.** `c ≠ 0` because:
   - ϕ is injective (an AlgEquiv).
   - `arrowElement m u v ≠ 0` (it's a basis element).
   - Hence `ϕ (arrowElement m u v) ≠ 0`.

**Public surface.**

| Declaration | Statement |
|-------------|-----------|
| `gl3_arrow_image_in_arrow_line` | `∀ u v, ∃ c : ℚ, ϕ (arrowElement m u v) = c • arrowElement m (σ u) (σ v)` |
| `gl3_arrow_image_scalar_nonzero_of_present` | `(.edge u v) ∈ presentArrows m adj₁ → c ≠ 0` |

**Sub-lemmas needed.**

* **5.1.1 `arrowElement_sandwich_via_AlgHom` (~60 LOC).** ϕ
  (an AlgHom) preserves the sandwich identity.
* **5.1.2 `inner_aut_radical_fixes_pathAlgebra` (~80 LOC).**
  Lift Stage 5's `inner_aut_radical_fixes_arrow` from a
  single arrow element to arbitrary
  `pathAlgebraQuotient`-elements, via
  `pathAlgebra_decompose_radical` (already in
  `WedderburnMalcev.lean`).
* **5.1.3 `vertexIdempotent_sandwich_projects_to_arrow_line` (~80 LOC).**
  For `X ∈ pathAlgebraRadical m` and any `a b : Fin m`,
  `vertexIdempotent a * X * vertexIdempotent b = c • arrowElement a b`
  for `c = X-coefficient at arrowElement a b`.
* **5.1.4 `gl3_arrow_image_in_arrow_line` (~30 LOC).**
  composition of the above.

**Risk.** Medium. The inner-conjugation collapse is the
delicate step but follows the established Stage 5 pattern.

### Layer 5.2 — Arrow membership iff (~150 LOC)

**File:** extends `ArrowFromGL3.lean`.

**Goal.** Prove the headline:
`(.edge u v ∈ presentArrows m adj₁) ↔
 (quiverMap m σ (.edge u v) ∈ presentArrows m adj₂)`.

**Approach.**

1. **`presentArrows_edge_mem_iff`** (already in
   `PathAlgebra.lean`): `.edge u v ∈ presentArrows m adj ↔
   adj u v = true`.

2. **Direction (⟹).** Assume `adj₁ u v = true`. Then
   `(.edge u v) ∈ presentArrows m adj₁`, so
   `arrowElement m u v` is a non-zero basis element of
   `presentArrowsSubspace m adj₁`. By Layer 5.1,
   `ϕ (arrowElement m u v) = c · arrowElement m (σ u) (σ v)`
   with `c ≠ 0`. Since ϕ maps `presentArrowsSubspace m adj₁`
   into `presentArrowsSubspace m adj₂` (an algebra-iso
   property; both subspaces equal the *full* radical-with-
   units image, which is the algebra `pathAlgebraQuotient m`
   itself), the result `c · arrowElement m (σ u) (σ v)` lives
   in `presentArrowsSubspace m adj₂`. The Submodule's basis
   characterization forces `arrowElement m (σ u) (σ v)` to
   be a basis element of `presentArrowsSubspace m adj₂`,
   i.e., `(.edge (σ u) (σ v)) ∈ presentArrows m adj₂`.

3. **Direction (⟸).** Apply (⟹) to the inverse algebra
   iso `ϕ⁻¹` (which corresponds to the inverse GL³ action
   `g⁻¹`).

**Public surface.**

| Declaration | Statement |
|-------------|-----------|
| `gl3_to_vertexPerm_preserves_presentArrows_iff` | the headline iff |

**Risk.** Medium. The "ϕ maps presentArrowsSubspace into
itself" step needs care. Mathematically: ϕ is an algebra
endomorphism of `pathAlgebraQuotient m`, and
`presentArrowsSubspace m adj` is the basis-spanned subspace
that equals the *whole* algebra (since the basis spans the
whole quotient). So this step is automatic — `ϕ` lands in
the whole algebra.

Wait, that simplifies things. Let me re-examine.

**Re-examined.** `presentArrowsSubspace m adj` is the
Submodule spanned by the basis elements that are present in
`adj`. For `adj` with no present arrows, this is just the
span of vertex idempotents (= the semisimple part). For
`adj` with all arrows present, this is the whole algebra.

**The membership question** is therefore about whether
`arrowElement m (σ u) (σ v)` lies in the *specific*
present-arrow subspace of `adj₂` (which depends on `adj₂`).
Layer 5.1's `gl3_arrow_image_in_arrow_line` gives the
σ-relabelled arrow, but membership requires it to actually be
a basis element of `adj₂`'s present-arrows.

This is the **core content of Prop 2**: σ is a graph
isomorphism. The question is: is this a direct corollary of
Phase 3's algebra iso, or does it need additional argument?

**Honest answer.** It's a direct corollary IF Phase 3's
AlgEquiv `ϕ` is constructed such that
`ϕ '' presentArrowsSubspace m adj₁ = presentArrowsSubspace m adj₂`.
This subspace-preservation property MUST be part of Phase 3's
deliverable (it's not automatic from "AlgEquiv on
pathAlgebraQuotient m"). v4 adds this as a **required output**
of Phase 3:

```
theorem gl3_induces_algEquiv_on_pathSubspace ... :
  ∃ (ϕ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m),
    ϕ '' (presentArrowsSubspace m adj₁ : Set _) =
    presentArrowsSubspace m adj₂
```

(This is part of "ϕ implements the GL³ action on the path
subspace" — the unspecified detail in Phase 3's headline.)

With this property, Layer 5.2's argument goes through.

**Risk recheck.** Layer 5.2 is then ~50 LOC of composition,
not 150 LOC. Adjusted budget: **Layer 5.2 ~80 LOC** total
(50 LOC main + 30 LOC sub-lemmas).

### Phase 5 deliverables and gates

* One new `.lean` module (`ArrowFromGL3.lean`, ~330 LOC
  post-recheck — Layer 5.1 ~250 LOC + Layer 5.2 ~80 LOC after
  the v4 recheck reduced 5.2 from ~150 to ~80; Phase 5
  header's "~400 LOC" includes ~70 LOC of testing /
  audit-script extension).
* `Orbcrypt.lean` extended with one new import.
* `scripts/audit_phase_16.lean` extended.
* CLAUDE.md change-log entry.
* Verification: `gl3_to_vertexPerm_preserves_presentArrows_iff`
  proven; non-vacuity at `m ∈ {1, 2, 3}`.

**Consumer.** Phase 6.

---

## Phase 6 — Final discharge: Prop 2 + Prop 1 corollary (~250 LOC)

**Goal.** Compose Phase 5's `gl3_to_vertexPerm_preserves_presentArrows_iff`
with the `Prop` definitions to discharge both Props
unconditionally. Then compose with Stage 5's
`grochowQiaoRigidity_under_arrowDischarge` and the existing
Karp reduction inhabitant to deliver
`grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _`.

### Layer 6.1 — Prop 2 unconditional + Prop 1 corollary (~150 LOC)

**File:** extends `Orbcrypt/Hardness/GrochowQiao/Rigidity.lean`.

**Composition.**

```lean
theorem gl3_induces_arrow_preserving_perm :
    GL3InducesArrowPreservingPerm := by
  intro m adj₁ adj₂ g hg
  refine ⟨gl3_to_vertexPerm g hg, ?_⟩
  intro u v
  exact gl3_to_vertexPerm_preserves_presentArrows_iff g hg u v
```

(One-line composition: Phase 4's σ + Phase 5's iff.)

**Prop 1 corollary** (~50 LOC sub-task):

```lean
theorem gl3_preserves_partition_cardinalities :
    GL3PreservesPartitionCardinalities := by
  intro m adj₁ adj₂ g hg
  obtain ⟨σ, h_arrow⟩ :=
    gl3_induces_arrow_preserving_perm m adj₁ adj₂ g hg
  -- σ × σ : Fin m × Fin m ≃ Fin m × Fin m is a bijection
  -- between {(u, v) : adj₁ u v = true} and
  -- {(u, v) : adj₂ u v = true}, hence equal cardinalities.
  exact card_eq_of_arrow_preserving_perm m adj₁ adj₂ σ h_arrow
```

**Sub-lemma** (~50 LOC):

```lean
lemma card_eq_of_arrow_preserving_perm
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (σ : Equiv.Perm (Fin m))
    (h : ∀ u v, (.edge u v) ∈ presentArrows m adj₁ ↔
                (quiverMap m σ (.edge u v)) ∈ presentArrows m adj₂) :
    (presentArrowSlotIndices m adj₁).card =
    (presentArrowSlotIndices m adj₂).card
```

**Proof.** From `presentArrows_edge_mem_iff`, the hypothesis
becomes `∀ u v, adj₁ u v = adj₂ (σ u) (σ v)`. Then
`presentArrowSlotIndices m adj` is in bijection (via
`slotEquiv`) with `Finset.univ.filter (fun (u, v) => adj u v)`,
and the σ × σ bijection on `Fin m × Fin m` restricts to a
bijection between the present-arrow Finsets of `adj₁` and
`adj₂`. Apply `Finset.card_image_of_injective`.

**Public surface.**

| Declaration | Statement |
|-------------|-----------|
| `gl3_induces_arrow_preserving_perm` | `: GL3InducesArrowPreservingPerm` |
| `gl3_preserves_partition_cardinalities` | `: GL3PreservesPartitionCardinalities` |
| `card_eq_of_arrow_preserving_perm` | sub-lemma |
| `grochowQiaoRigidity` | `: GrochowQiaoRigidity` (composes with `_under_arrowDischarge`) |
| `partitionPreservingPermOfGL3` | `(g) (hg) → Equiv.Perm (Fin (dimGQ m))` (constructs π via Stage 3's `partitionPreservingPermFromEqualCardinalities` + Prop 1 corollary; useful for downstream consumers) |

**Risk.** Low — pure composition with existing infrastructure.

### Layer 6.2 — Final Karp reduction inhabitant (~100 LOC)

**File:** extends `Orbcrypt/Hardness/GrochowQiao.lean`.

**Composition.**

```lean
theorem grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _ :=
  grochowQiao_isInhabitedKarpReduction_under_rigidity
    grochowQiaoRigidity
```

(One-line composition with the existing conditional inhabitant.)

**Public surface.**

| Declaration | Statement |
|-------------|-----------|
| `grochowQiao_isInhabitedKarpReduction` | `: @GIReducesToTI ℚ _` (unconditional) |

**Risk.** None — pure composition.

### Phase 6 deliverables and gates

* Extensions to `Rigidity.lean` and `GrochowQiao.lean`. **No
  new `.lean` modules** — all extensions of existing modules.
* `Orbcrypt.lean` axiom-transparency report extended:
  Vacuity map updated to mark **both** Props as discharged
  unconditionally (not via the failed v3 "shallow rigidity"
  path, but via the Phase 3 → 4 → 5 → 6 chain).
* `scripts/audit_phase_16.lean` extended with `#print axioms`
  for both unconditional Prop discharges + the final Karp
  reduction; final non-vacuity exhibiting
  `grochowQiao_isInhabitedKarpReduction` on a concrete pair
  of isomorphic graphs at `m = 3`.
* `CLAUDE.md` change-log entry: comprehensive summary of the
  R-15-residual-TI-reverse closure across Phases 1–6.
  Status-column updates for every previously-Conditional
  Stage 3 / Stage 5 theorem.
* `docs/VERIFICATION_REPORT.md` "Known limitations" item for
  R-15-residual-TI-reverse marked **CLOSED**; "Headline
  results" table extended with `grochowQiaoRigidity` and
  `grochowQiao_isInhabitedKarpReduction` rows (Status:
  **Standalone**).
* `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`
  R-15-residual-TI-reverse marked **CLOSED**.
* `lakefile.lean` version bumped from `0.1.21` to `0.1.22`.
* Verification: full project `lake build` succeeds; audit
  script reports every new declaration on standard trio; the
  headline `grochowQiao_isInhabitedKarpReduction` axiom-prints
  on the standard Lean trio only.

---

## 7. Existing infrastructure reused

The plan builds on the Stage 0–5 R-TI work already in the
codebase. **Nothing in the existing code needs to be
modified** — Phases 1–6 are purely additive.

### Encoder + tensor framework
* `Orbcrypt/Hardness/TensorAction.lean`: `Tensor3`,
  `matMulTensor1/2/3`, `tensorContract`, `tensorAction`,
  `AreTensorIsomorphic`, `GIReducesToTI`.
* `Orbcrypt/Hardness/GrochowQiao/StructureTensor.lean`:
  `dimGQ`, `SlotKind`, `slotEquiv`, `isPathAlgebraSlot`,
  `slotToArrow`, `pathSlotStructureConstant`,
  `ambientSlotStructureConstant`, `grochowQiaoEncode`,
  `grochowQiaoEncode_diagonal_vertex`,
  `grochowQiaoEncode_diagonal_present_arrow`,
  `grochowQiaoEncode_diagonal_padding`,
  `grochowQiaoEncode_padding_distinguishable`.

### Path algebra
* `Orbcrypt/Hardness/GrochowQiao/PathAlgebra.lean`:
  `QuiverArrow`, `presentArrows`,
  `presentArrows_edge_mem_iff`, `pathMul`, `pathMul_id_id`,
  `pathMul_id_edge`, `pathMul_edge_id`,
  `pathMul_edge_edge_none`, `pathMul_assoc`, `quiverMap`,
  `quiverMap_edge`, `pathMul_quiverMap`.
* `Orbcrypt/Hardness/GrochowQiao/AlgebraWrapper.lean`:
  `pathAlgebraQuotient`, `pathAlgebraMul`, `vertexIdempotent`,
  `arrowElement`, full Ring + Algebra ℚ instances,
  `pathAlgebra_decompose`, `vertexIdempotent_isPrimitive`,
  `IsPrimitiveIdempotent`,
  `vertexIdempotent_completeOrthogonalIdempotents`,
  `AlgEquiv_preserves_completeOrthogonalIdempotents`,
  `arrowElement_mul_arrowElement_eq_zero` (J²=0 at basis level),
  `vertexIdempotent_mul_vertexIdempotent`,
  `vertexIdempotent_mul_arrowElement`,
  `arrowElement_mul_vertexIdempotent`.

### Wedderburn–Mal'cev
* `Orbcrypt/Hardness/GrochowQiao/WedderburnMalcev.lean`:
  `pathAlgebraRadical`, `pathAlgebraRadical_mul_radical_eq_zero`
  (J²=0 at radical level), `pathAlgebra_decompose_radical`,
  `oneAddRadical_mul_oneSubRadical`,
  `member_radical_mul_arrowElement`,
  `arrowElement_mul_member_radical`,
  `wedderburn_malcev_conjugacy`, **`algEquiv_extractVertexPerm`**
  (the key theorem Phase 4 consumes).

### Stage 4 σ-induced AlgEquiv
* `Orbcrypt/Hardness/GrochowQiao/AlgEquivLift.lean`:
  `quiverPermFun`, `quiverPermAlgEquiv`,
  `quiverPermAlgEquiv_apply_vertexIdempotent`,
  `quiverPermAlgEquiv_apply_arrowElement`,
  `quiverPermFun_preserves_mul`.
  *(Stage 4 provides σ → AlgEquiv. The plan provides the
  reverse direction GL³ → AlgEquiv via Phase 3 → Phase 4.)*

### Stage 5 adjacency invariance
* `Orbcrypt/Hardness/GrochowQiao/AdjacencyInvariance.lean`:
  `arrowElement_sandwich`, `radical_arrowElement_mul`,
  `arrowElement_radical_mul`, `inner_aut_radical_fixes_arrow`,
  `mem_presentArrows_iff`,
  `vertexPerm_isGraphIso_iff_arrow_preserving`,
  `quiverPermAlgEquiv_preserves_presentArrows_iff`,
  **`vertexPermPreservesAdjacency`** (the theorem Phase 5
  builds on).

### Stage 5 conditional rigidity
* `Orbcrypt/Hardness/GrochowQiao/Rigidity.lean`:
  `GL3InducesArrowPreservingPerm` (Prop 2 definition),
  `gl3_induces_arrow_preserving_perm_identity_case`,
  **`grochowQiaoRigidity_under_arrowDischarge`** (Phase 6
  consumes this).

### Stage 5 conditional Karp reduction
* `Orbcrypt/Hardness/GrochowQiao/Reverse.lean`:
  `GrochowQiaoRigidity` (the original Prop being discharged).
* `Orbcrypt/Hardness/GrochowQiao.lean`:
  **`grochowQiao_isInhabitedKarpReduction_under_rigidity`**
  (Phase 6 consumes this).

### Stage 1 tensor unfoldings
* `Orbcrypt/Hardness/GrochowQiao/TensorUnfold.lean`:
  `unfold₁`, `unfold₂`, `unfold₃`, `unfold₁_tensorContract`,
  `unfold₁_matMulTensor{1,2,3}`. *(Phase 3 may use these for
  multilinear-algebra arguments; Phases 1, 2, 4, 5, 6 mostly
  do not.)*
* `Orbcrypt/Hardness/GrochowQiao/RankInvariance.lean`:
  `unfoldRank₁`, `unfoldRank₁_smul`,
  `kronecker_isUnit_det`. *(Genuine GL³-invariant, used by
  Phase 3 if Approach A is chosen.)*

### Permutation-matrix infrastructure
* `Orbcrypt/Hardness/GrochowQiao/PermMatrix.lean`:
  `liftedSigmaMatrix`, `liftedSigmaGL`,
  `liftedSigmaMatrix_apply`,
  `tensorContract_permMatrix_triple`. *(Used by Phase 2 to
  define `pathBlockMatrix`.)*

### Stage 2 slot classification
* `Orbcrypt/Hardness/GrochowQiao/SlotSignature.lean`:
  `vertexSlotIndices`, `presentArrowSlotIndices`,
  `paddingSlotIndices`, `pathSlotIndices`, partition
  theorems.
* `Orbcrypt/Hardness/GrochowQiao/SlotBijection.lean`:
  `IsThreePartitionPreserving`,
  `vertexSlot_bijOn_of_vertexPreserving`, etc.
* `Orbcrypt/Hardness/GrochowQiao/VertexPermDescent.lean`:
  `vertexPermOfVertexPreserving`. *(Used by Phase 6 if
  the partition-permutation construction is needed.)*

### Stage 3 conditional partition-preserving permutation
* `Orbcrypt/Hardness/GrochowQiao/BlockDecomp.lean`:
  `GL3PreservesPartitionCardinalities` (Prop 1 definition),
  `partitionPreservingPermFromEqualCardinalities` (Phase 6
  uses this to construct π once the cardinality equality is
  known via the Prop 1 corollary).

---

## 8. Risk register

| # | Risk | Phase | Likelihood | Mitigation |
|---|------|-------|------------|------------|
| 1 | Phase 1's `encoder_associativity_identity` requires a sum manipulation that Mathlib doesn't directly support | 1 | Low | The argument uses `Finset.sum_eq_single` + `pathMul_assoc` (both available); ~50 LOC reserve for index management. |
| 2 | Phase 2's `pathBlockMatrix_at_partition_preserving_π` simplification depends on permutation-matrix entry formulas that require careful unfolding | 2 | Low | `liftedSigmaMatrix_apply` already gives the explicit entry formula; the simplification is direct. |
| 3 | Phase 3's algebra-iso construction is genuinely deep (~80 pages of paper) | 3 | **Very High** | This is research-scope. The plan does not commit to Approach A or Approach B; implementers choose based on Mathlib state at start time. **Partial-discharge fall-back available** (see Phase 3 alternative: introduce a single research-scope `Prop` `GL3InducesAlgEquivOnPathSubspace` and land Phases 1, 2, 4, 5, 6 conditional on it). |
| 4 | Phase 3 Approach A requires Manin's tensor-stabilizer theorem, which is not in Mathlib | 3 | High (if Approach A is chosen) | Either formalize Manin's theorem as a prerequisite (~500 LOC) or pivot to Approach B. |
| 5 | Phase 4's `algEquiv_preserves_pathAlgebraRadical` may need hand-rolling if Mathlib's `Jacobson` API is incomplete at the pinned commit | 4 | Med | Hand-roll via primitive-idempotent characterization (~100 LOC reserve). Existing `vertexIdempotent_isPrimitive` + `AlgEquiv_preserves_isPrimitiveIdempotent` cover the essential algebraic content. |
| 6 | Phase 5's "ϕ maps presentArrowsSubspace into itself" depends on Phase 3's deliverable explicitly stating this property | 5 | Low (post-clarification) | v4 makes this an explicit required output of Phase 3 (the "ϕ implements GL³ on path subspace" property). |
| 7 | Phase 6 composition with `grochowQiaoRigidity_under_arrowDischarge` requires the existing infrastructure to type-check exactly as documented | 6 | Low | The existing `Rigidity.lean` was verified during this audit; the composition is direct. |
| 8 | The plan's LOC estimates are too optimistic for any phase | All | Med | The plan's "Total Lean ~4,200+" is a lower bound. Phase 3 alone could exceed this if Mathlib gaps are deep. **Calendar buffer: 6–18 months for Phase 3 specifically**. |
| 9 | Tactic timeout / Lean elaboration time blowup in deep proofs | 3, 5 | Med | Decompose long proofs into named sub-lemmas (≤ 80 LOC each); profile with `set_option trace.profiler true`; raise `maxHeartbeats` only on identified hot-spots with `-- Justification: ...` comments. |
| 10 | The plan's overall architecture is incorrect | All | Low (post-v4 audit) | v4 is built on the **algebra-iso approach**, which is the standard Grochow–Qiao 2021 §4.3 strategy. Cross-checked against the codebase's existing path-algebra + Wedderburn–Mal'cev infrastructure. The two earlier "shallow rigidity" attempts (v1, v2, v3) were mathematically unsound and have been removed. |
| 11 | Phase 3's two approaches both fail in some unanticipated way | 3 | Low (Med if Mathlib stagnates) | Approaches A and B are both established techniques in algebraic-tensor-rank theory; failure of both would require a fundamentally new mathematical insight. **Partial closure (the new single research-scope Prop) is the safety net.** |
| 12 | Audit-script CI extension fails due to standard-trio violation | All | Low | Each phase's verification gate explicitly requires standard-trio compliance; per-declaration `#print axioms` is mandatory before commit. |

---

## 9. Verification protocol

### Per-layer verification gate

Before committing any sub-task within a phase:

1. `source ~/.elan/env && lake build <Module.Path> 2>&1 | tail -10` — exit code 0, zero warnings.
2. `lake env lean scripts/audit_phase_16.lean 2>&1 > /tmp/out.txt` — exit code 0.
3. `grep -cE "sorryAx|^error" /tmp/out.txt` — output `0`.
4. `grep "depends on axioms" /tmp/out.txt` — every line shows
   `[propext, Classical.choice, Quot.sound]` or "does not
   depend on any axioms".

### Per-phase verification

After each phase lands (i.e., all its sub-tasks committed):

1. Full project build: `lake build 2>&1 | tail -10` succeeds.
2. CI green on the push branch.
3. CLAUDE.md change-log entry committed.
4. Audit-script `#print axioms` output for each new public
   declaration is on standard trio.

### End-to-end verification (post-Phase-6)

1. **Headline theorems build:**
   - `gl3_induces_arrow_preserving_perm : GL3InducesArrowPreservingPerm`
   - `gl3_preserves_partition_cardinalities : GL3PreservesPartitionCardinalities`
   - `grochowQiaoRigidity : GrochowQiaoRigidity`
   - `grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _`
   All compile unconditionally; all `#print axioms` outputs
   show only the standard Lean trio.

2. **K₃ self-iso example** in audit script:
   ```lean
   example :
     let adj : Fin 3 → Fin 3 → Bool :=
       fun i j => decide (i ≠ j)
     ∃ σ : Equiv.Perm (Fin 3), ∀ i j, adj i j = adj (σ i) (σ j) := by
     have h_iso := grochowQiaoEncode_self_isomorphic 3 adj
     exact grochowQiaoRigidity 3 adj adj h_iso
   ```

3. **Documentation parity:** `CLAUDE.md`'s "Three core theorems"
   table extended with rows for `grochowQiaoRigidity` and
   `grochowQiao_isInhabitedKarpReduction` (Status:
   **Standalone**); `docs/VERIFICATION_REPORT.md` "Known
   limitations" updated.

4. **Lakefile version bumped** to `0.1.22`.

---

## 10. Scope estimates and effort

| Phase | LOC | Calendar effort | Risk |
|-------|-----|-----------------|------|
| 1 | ~600 | 2–3 weeks | Low |
| 2 | ~700 | 3–4 weeks | Med |
| 3 (Approach A) | ~3,200 | **6–18 months** | **Very High (research)** |
| 4 | ~250 | 1 week | Low |
| 5 | ~400 | 1–2 weeks | Med |
| 6 | ~250 | 1 week | Low |
| **Total Lean** | **~5,400** | **~9–22 months** | |
| Plus docs | ~400 | (concurrent with phases) | — |

**Phase 3 calendar uncertainty.** Phase 3 dominates the
schedule. Per Approach A's sub-task analysis:

* **Lower bound (6 months):** team of 2 implementers,
  parallelizing A.1+A.5 vs A.2/A.3/A.4+A.6.
* **Upper bound (18 months):** single implementer, sequential,
  with both A.3.2 (polynomial-invariant) and A.5.3 (Manin
  algebra-hom) requiring multiple iteration rounds.
* **Stall scenarios:**
  - Sub-task A.3.2's polynomial invariant proves intractable:
    +3 months to find an alternative or reroute via
    A.5+A.6. Reduce risk by starting A.3 and A.5 in parallel
    (the fall-back is then partly already in flight).
  - Sub-task A.5.3 hits an unforeseen Mathlib gap: +2 months
    for hand-roll; pivot to Approach B if gap exceeds 6
    weeks.

**Dedicated effort total:** ~9–22 months for a single focused
implementer. **Smaller team (2–3 people in parallel):** ~6–14
months wall-clock by parallelizing Phases 1 + 2 + Phase 3's
A.5 (Manin theorem prerequisite) at the start, then Phase 3's
A.1–A.4, A.6 sequentially after the prerequisites land.

## 11. Phase dependency graph

```
                       (Stage 0–5 already in codebase)
                              │
                              ▼
   ┌──────────────────────────┼──────────────────────────┐
   │                          │                          │
   ▼                          ▼                          ▼
[Phase 1]              [Phase 2]                  [existing AlgEquiv
encoder structural     path-block linear           +
foundation             restriction (param π)       Wedderburn–Mal'cev
                                                   infrastructure]
   │                          │                          │
   └──────────────────────────┴──────────────────────────┘
                              │
                              ▼
                       [Phase 3 — RESEARCH]
                       GL³ → algebra-iso bridge
                              │
                              ▼
                          [Phase 4]
                       σ extraction via WM
                              │
                              ▼
                          [Phase 5]
                    arrow preservation from σ
                              │
                              ▼
                          [Phase 6]
                  ┌───────────┴───────────┐
                  ▼                       ▼
       Prop 2 discharged           Prop 1 corollary
                  │                       │
                  └───────────┬───────────┘
                              ▼
                  grochowQiaoRigidity unconditional
                              │
                              ▼
              grochowQiao_isInhabitedKarpReduction
                  : @GIReducesToTI ℚ _
```

**Critical observations:**

* **Phase 3 is the single bottleneck.** All other phases are
  tractable.
* **Phases 1, 2 are independent of each other** and of Phase
  3's existence — they can land first as foundational
  infrastructure.
* **Phases 4, 5, 6 are linearly chained** but each is
  small (~250–400 LOC) and tractable once Phase 3 lands.

## 12. Files modified summary

### New `.lean` modules (under `Orbcrypt/Hardness/GrochowQiao/`)

| File | Phase / Sub-task | LOC |
|------|------------------|-----|
| `EncoderSlabEval.lean` | 1 | ~600 |
| `PathBlockSubspace.lean` | 2 | ~700 |
| `EncoderPolynomialIdentities.lean` | 3 / A.1 | ~250 |
| `TensorIdentityPreservation.lean` | 3 / A.2 | ~300 |
| `PaddingRigidity.lean` | 3 / A.3 | ~700 |
| `PathOnlyTensor.lean` | 3 / A.4 | ~250 |
| `ManinStabilizerTheorem.lean` | 3 / A.5 | ~600 |
| `AlgEquivFromGL3.lean` | 3 / A.6 | ~400 |
| `SigmaFromGL3.lean` | 4 | ~250 |
| `ArrowFromGL3.lean` | 5 | ~400 |

**Module organization (Approach A).** Phase 3's six sub-tasks
land as six separate modules under
`Orbcrypt/Hardness/GrochowQiao/`. This decomposition allows
incremental commits, separate code review per sub-task, and
independent debugging if a specific sub-task encounters
elaboration-time issues.

**Approach B alternative.** If implementers pivot to
Approach B mid-stream, the Phase 3 module decomposition would
collapse into ~3–4 modules with different names. The plan
defaults to Approach A's decomposition.

### Existing `.lean` files modified

| File | Phase | Change |
|------|-------|--------|
| `Orbcrypt/Hardness/GrochowQiao/Rigidity.lean` | 6 | Add `gl3_induces_arrow_preserving_perm` (Prop 2 discharge), `gl3_preserves_partition_cardinalities` (Prop 1 corollary), `card_eq_of_arrow_preserving_perm` sub-lemma, `grochowQiaoRigidity` (unconditional), `partitionPreservingPermOfGL3` (now constructed here, not Phase C v2). |
| `Orbcrypt/Hardness/GrochowQiao.lean` | 6 | Add `grochowQiao_isInhabitedKarpReduction` (unconditional). |
| `Orbcrypt.lean` | 1–6 | Add new imports; extend axiom-transparency report; update Vacuity map to mark both Props as discharged. |
| `scripts/audit_phase_16.lean` | 1–6 | Add `#print axioms` entries + non-vacuity examples for each new public declaration. |
| `CLAUDE.md` | 6 | Per-phase change-log entries + Status-column updates for Stage 3 / Stage 5 theorems that become unconditional. |
| `docs/VERIFICATION_REPORT.md` | 6 | Document history + headline-results table + closed-limitation entries. |
| `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` | 6 | Mark R-15-residual-TI-reverse CLOSED. |
| `lakefile.lean` | 6 | Version bump `0.1.21 → 0.1.22`. |

## 13. Cross-references

* **Source paper:** Grochow & Qiao, *On the complexity of
  isomorphism problems for tensors, groups, and polynomials
  I*, SIAM J. Comp. 2023 (arXiv 2103.10293), §4.3.
* **Stage 0–5 master plan (prior, complete):**
  `/root/.claude/plans/create-a-detailed-plan-fizzy-planet.md`.
* **Audit plan tracking R-15:**
  `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`.
* **Original R-TI workstream plan:**
  `docs/planning/R_TI_PHASE_C_THROUGH_H_PLAN.md`.
* **Phase 16 audit script:** `scripts/audit_phase_16.lean`.
* **Verification report:** `docs/VERIFICATION_REPORT.md`.
* **Project conventions:** `CLAUDE.md` (Naming, Release
  messaging policy, Three core theorems).
* **Research notes:**
  - `docs/research/grochow_qiao_path_algebra.md`
  - `docs/research/grochow_qiao_padding_rigidity.md`
  - `docs/research/grochow_qiao_mathlib_api.md`
  - `docs/research/grochow_qiao_reading_log.md`

## 14. Honest assessment

**This plan is a roadmap, not a finished proof.**

* **What v4 delivers if fully executed.** Phases 1, 2, 4, 5,
  6 are concrete, decomposed, and tractable. Their LOC budgets
  are reliable; their proof techniques use existing Mathlib
  and existing R-TI infrastructure.
* **What v4 does NOT deliver.** A complete formalization of
  Phase 3. Phase 3's "GL³ → algebra-iso bridge" is genuinely
  research-scope content — ~80 pages of the source paper that
  has no existing Lean translation. The plan provides two
  sketched approaches (A and B); whichever is chosen will
  require **substantial original mathematical formalization
  effort** (~6–18 months).
* **Honest fall-back.** If Phase 3 stalls, the plan supports
  a **partial closure**: introduce a single research-scope
  `Prop` `GL3InducesAlgEquivOnPathSubspace` capturing Phase
  3's headline, and land Phases 1, 2, 4, 5, 6 conditional on
  it. This is strictly better than the current Stage 0–5
  state because:
  - It reduces the **two** existing research-scope `Prop`s
    (`GL3PreservesPartitionCardinalities` and
    `GL3InducesArrowPreservingPerm`) to **one** cleaner `Prop`.
  - All the surrounding plumbing becomes unconditional.
  - The remaining research milestone is well-defined and
    matches a specific section of the source paper.

The plan's purpose is to make the genuine difficulty of
R-15-residual-TI-reverse **visible** and **actionable**:
visible because it identifies Phase 3 as the single deep
step; actionable because Phases 1, 2, 4, 5, 6 can land
incrementally, each delivering useful infrastructure even
before Phase 3 completes.
