# R-TI Phase 3 Discharge Plan: Implementing the Two Research-Scope Props

**Tracking:** R-15-residual-TI-reverse (final closure of Phase 3).
**Target deliverables:** Convert `RestrictedGL3OnPathOnlyTensor` and `GL3InducesAlgEquivOnPathSubspace` from `Prop`-typed obligations into fully-proven theorems, dropping the `h_research` hypothesis from all downstream Phase 4/5/6 chains.
**Final output:** `theorem grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _` becomes unconditional.

---

## Context

R-TI Phase 3's partial-discharge landed Sub-tasks A.1, A.2 (corrected), A.4 (with the substantively-proven `pathOnlyStructureTensor_isAssociative`), and A.6's conditional headline + identity case. The two genuinely deep multilinear-algebra Props remain undischarged:

1. **`RestrictedGL3OnPathOnlyTensor (m : ℕ) : Prop`** in `Orbcrypt/Hardness/GrochowQiao/PathOnlyTensor.lean:415` — for arbitrary GL³ `g` and adjacencies `(adj₁, adj₂)`, if `g • encode m adj₁ = encode m adj₂` then `(presentArrowSlotIndices m adj₁).card = (presentArrowSlotIndices m adj₂).card`.

2. **`GL3InducesAlgEquivOnPathSubspace (m : ℕ) : Prop`** in `Orbcrypt/Hardness/GrochowQiao/AlgEquivFromGL3.lean:135` — same hypothesis, conclude existence of an AlgEquiv `pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m` whose action on the `presentArrowsSubspace` matches the GL³ action.

`GL3InducesAlgEquivOnPathSubspace` strictly implies `RestrictedGL3OnPathOnlyTensor` (an AlgEquiv preserves submodule dimension via `LinearEquiv.finrank_eq` ⇒ `presentArrows.card` matches ⇒ `presentArrowSlotIndices.card` matches), so the plan **discharges the second directly**, with the first as a ~50 LOC corollary.

Discharging these Props unconditionally:
* Removes the `h_research` hypothesis from `gl3_induces_algEquiv_on_pathSubspace` (`AlgEquivFromGL3.lean:159`) and its consumers.
* Makes Phase 4/5/6 (Wedderburn–Mal'cev σ extraction, arrow preservation, final discharge) unconditional.
* Delivers **`grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _`** as an unconditional theorem (currently conditional on `GrochowQiaoRigidity` per `Orbcrypt/Hardness/GrochowQiao.lean:289`).

---

## High-Level Strategy: Approach A (Manin Tensor-Stabilizer)

The plan executes **Approach A** of `docs/planning/R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md` (Sub-tasks A.3 + A.5 + A.6 matrix-action upgrade). Key insight: the Grochow–Qiao encoder restricted to path-algebra slots is exactly the **structure tensor of `pathAlgebraQuotient m` in the basis indexed by `pathSlotIndices m adj`**. A GL³ tensor isomorphism between two such structure tensors must preserve the algebra structure (Manin's tensor-stabilizer theorem), forcing an algebra isomorphism between the path algebras.

Mathematical decomposition:
1. **A.1.5 — Encoder unit-compatibility identity** (~120 LOC, prerequisite for A.5).
2. **A.3 — Distinguished-padding rigidity** (~700 LOC, HIGH risk):
   - A.3.1 padding "trivial-algebra" identity.
   - A.3.2 padding-rank polynomial invariant `paddingRankInvariant : Tensor3 n ℚ → ℕ` (research-grade).
   - A.3.3 padding-cardinality preservation under GL³.
   - A.3.4 path-cardinality preservation (subtraction).
   - A.3.5 partition-preserving slot permutation construction.
3. **A.5 — Manin tensor-stabilizer theorem** (~600 LOC, HIGH risk):
   - A.5.1 abstract `Algebra.structureTensor` (hand-rolled; not in Mathlib).
   - A.5.2 basis-change formula for structure tensors.
   - A.5.3 GL³ tensor iso ⟹ algebra hom (the technical core).
   - A.5.4 upgrade to `AlgEquiv` via inverse.
   - A.5.5 specialization to `pathAlgebraQuotient m`.
4. **A.6 — Matrix-action upgrade** (~400 LOC, Med risk):
   - A.6.1 path-only-tensor ↔ `presentArrowsSubspace` AlgEquiv bridge.
   - A.6.2 lift A.5's path-only AlgEquiv to `pathAlgebraQuotient m`.
   - A.6.3 subspace-preservation property + final headline.

**Total:** ~1,625–2,120 LOC across **8 new modules** (with optimization reuse of ~495 LOC of existing infrastructure).

---

## Module Decomposition

All new files live under `Orbcrypt/Hardness/GrochowQiao/`. The `Manin/` sub-folder isolates reusable algebra-general content (potentially upstreamable to Mathlib).

| # | New file | LOC | Sub-task | Purpose |
|---|----------|----:|----------|---------|
| 1 | `EncoderUnitCompatibility.lean` | 120 | A.1.5 | Encoder unit-compatibility identity (prerequisite for A.5). |
| 2 | `Manin/StructureTensor.lean` | 180 | A.5.1 | Hand-rolled `Manin.structureTensor (b : Basis I F A)` + apply lemma + multiplication-recovery. |
| 3 | `Manin/BasisChange.lean` | 140 | A.5.2 | Push-forward basis `g · b`, structure-tensor basis-change formula. |
| 4 | `Manin/TensorStabilizer.lean` | 480 | A.5.3 + A.5.4 | The core: GL³ tensor iso ⟹ algebra hom + upgrade to `AlgEquiv`. |
| 5 | `PaddingInvariant.lean` | 250 | A.3.1 + A.3.2 | Padding trivial-algebra identity + `paddingRankInvariant` + GL³-invariance. |
| 6 | `PartitionRigidity.lean` | 360 | A.3.3 + A.3.4 + A.3.5 | Path/padding cardinality preservation + partition-preserving π construction. |
| 7 | `PathOnlyAlgebra.lean` | 280 | A.5.5 + A.6.1 + A.6.2 | Path-only-tensor ↔ `presentArrowsSubspace` AlgEquiv; specialize Manin to `pathAlgebraQuotient`; lift to full algebra. |
| 8 | `Discharge.lean` | 190 | A.6.3 + corollary | `theorem gl3InducesAlgEquivOnPathSubspace` + corollary `theorem restrictedGL3OnPathOnlyTensor`. |

**Existing-file rewires** (~120 LOC delta, in-place edits):

| File | Edit |
|------|------|
| `Orbcrypt/Hardness/GrochowQiao/AlgEquivFromGL3.lean` | Drop `h_research` arg from `gl3_induces_algEquiv_on_pathSubspace`; reference `Discharge.gl3InducesAlgEquivOnPathSubspace`. |
| `Orbcrypt/Hardness/GrochowQiao/PathOnlyTensor.lean` | Retire `restrictedGL3OnPathOnlyTensor_identity_case` (subsumed by unconditional theorem); keep the `Prop` definition for backward signature compatibility. |
| `Orbcrypt/Hardness/GrochowQiao/Rigidity.lean` | Drop `h_research` chain. |
| `Orbcrypt/Hardness/GrochowQiao.lean` | Make `grochowQiaoRigidity`, `grochowQiao_isInhabitedKarpReduction` unconditional. |
| `Orbcrypt.lean` | Add 8 new module imports. |
| `scripts/audit_phase_16.lean` | Add ~25 `#print axioms` checks + ~20 non-vacuity examples in new section §15.18–§15.25. |

**Dependency graph:**

```
EncoderPolynomialIdentities ─► EncoderUnitCompatibility ─┐
                          ─►   PaddingInvariant          │
                                                         ▼
PaddingInvariant ─► PartitionRigidity ─► PathOnlyTensor (existing)
                                              │
       Manin/StructureTensor ─► Manin/BasisChange ─► Manin/TensorStabilizer
                                                              │
                                                              ▼
                                       PartitionRigidity ────►PathOnlyAlgebra
                                                              │
                                                              ▼
                                                          Discharge
                                                              │
              ┌───────────────────────────────────────────────┘
              ▼
     AlgEquivFromGL3 (rewired) ─► Rigidity (rewired) ─► GrochowQiao (rewired)
```

The Manin sub-stack (files 2–4) and the encoder-specific stack (files 1, 5, 6) are independent and parallelizable.

---

## Sub-Task Breakdown

### A.1.5 — Encoder unit-compatibility (~120 LOC, Low risk)

**File:** `Orbcrypt/Hardness/GrochowQiao/EncoderUnitCompatibility.lean`.

**Headline.**
```lean
theorem encoder_unit_compatibility (m : ℕ) (adj : Fin m → Fin m → Bool)
    (j k : Fin (dimGQ m))
    (hj : isPathAlgebraSlot m adj j = true)
    (hk : isPathAlgebraSlot m adj k = true) :
    (∑ v : Fin m, grochowQiaoEncode m adj
      ((slotEquiv m).symm (.vertex v)) j k) =
        (if slotToArrow m (slotEquiv m j) = slotToArrow m (slotEquiv m k)
         then 1 else 0)
```

**Proof technique.** Case-split `slotEquiv m j` on `vertex v` vs `arrow u w`. In each case the sum has at most one non-zero summand: `Finset.sum_eq_single` collapses at the unique source vertex. Apply `EncoderSlabEval.encoder_at_vertex_*_eq_one` for the non-zero contribution.

**Reused infrastructure.** `EncoderSlabEval.encoder_at_vertex_vertex_vertex_eq_one`, `EncoderSlabEval.encoder_at_vertex_arrow_arrow_eq_one`, `EncoderSlabEval.encoder_zero_at_remaining_path_triples`, `slotEquiv`.

### A.3.1 — Padding trivial-algebra identity (~100 LOC, Low risk)

**File:** `Orbcrypt/Hardness/GrochowQiao/PaddingInvariant.lean` (top half).

**Headline.**
```lean
theorem encoder_padding_trivial_algebra (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j k : Fin (dimGQ m))
    (hi : isPathAlgebraSlot m adj i = false) :
    grochowQiaoEncode m adj i j k =
      (if i = j ∧ j = k then (2 : ℚ) else 0)
```

**Proof technique.** Apply `grochowQiaoEncode_padding_left m adj i j k hi` (already exists) to switch to ambient branch; unfold `ambientSlotStructureConstant`. Already proven structurally as `encoder_padding_diag_only` in A.1.4 — this is a re-statement at the slot-discriminator level.

### A.3.2 — `paddingRankInvariant` (~150 LOC, **HIGH risk** — research-grade)

**File:** `Orbcrypt/Hardness/GrochowQiao/PaddingInvariant.lean` (bottom half).

**Headline.**
```lean
def paddingRankInvariant {n : ℕ} (T : Tensor3 n ℚ) : ℕ :=
  (Finset.univ.filter (fun i =>
     T i i i = 2 ∧
     (∀ j k, T i j k = 0 ∨ (j = i ∧ k = i)) ∧
     (∀ j k, T j i k = 0 ∨ (j = i ∧ k = i)) ∧
     (∀ j k, T j k i = 0 ∨ (j = i ∧ k = i)))).card

theorem paddingRankInvariant_eq_paddingSlotIndices_card
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    paddingRankInvariant (grochowQiaoEncode m adj) =
      (paddingSlotIndices m adj).card

theorem paddingRankInvariant_gl3_invariant
    {n : ℕ} (T₁ T₂ : Tensor3 n ℚ)
    (g : GL (Fin n) ℚ × GL (Fin n) ℚ × GL (Fin n) ℚ)
    (h : g • T₁ = T₂)
    (h_struct : <slab-concentration structural hypothesis>) :
    paddingRankInvariant T₁ = paddingRankInvariant T₂
```

**Proof technique broken into 4 sub-units (~40 LOC each):**

* **A.3.2.1 — Define `paddingRankInvariant` (~30 LOC).** Direct definition above. Add `_eq_card_filter` apply lemma for unfolding.

* **A.3.2.2 — Encoder evaluation (~40 LOC).** Show `paddingRankInvariant (grochowQiaoEncode m adj) = (paddingSlotIndices m adj).card`. Direct from A.3.1's `encoder_padding_trivial_algebra` (which gives the trivial-algebra structure on padding slots) + A.1.1's diagonal classification (which excludes path-algebra slots from the filter via diagonal value `0` or `1`, not `2`).

* **A.3.2.3 — Abstract characterization of "concentrated slot" (~40 LOC).** Define `IsConcentratedSlot (T : Tensor3 n ℚ) (i : Fin n) : Prop` as the slab-support condition + `T i i i = 2`. Prove this is equivalent to the filter predicate in `paddingRankInvariant`. Prove that an index `i` is concentrated iff its three slabs `T(i,·,·)`, `T(·,i,·)`, `T(·,·,i)` (viewed as `n × n` matrices) are all rank-1 with non-zero entry only at `(i, i)` and value `2`.

* **A.3.2.4 — GL³-invariance (~40 LOC, **HIGH-risk core**).** Show that under GL³ action `T₂ = g • T₁`, the count of concentrated slots is preserved. The proof:
  (a) Rank-1 matrices map to rank-1 matrices under GL × GL action (via `Matrix.rank_mul_eq_left_of_isUnit_det`).
  (b) The unique non-zero entry of a rank-1-supported-at-(i,i) matrix transforms to a unique non-zero entry of `T₂`'s slab — the location moves but the **rank-1-supported-at-a-single-point** structural property is preserved.
  (c) The diagonal value transforms as `T₂(σ(i), σ(i), σ(i)) = ?` — this requires careful analysis. **The simpler approach**: show GL³ permutes the set of concentrated indices via a bijection σ, hence preserves cardinality. The bijection σ is implicit in the GL³ action's effect on the support of concentrated slabs.

**Risk mitigation (R1).** If A.3.2.4's `=2` value preservation is intractable for arbitrary GL³ (because generic GL³ scales the entries by a determinant factor):
- **Fallback strategy 1**: Define a **scale-invariant** version `paddingRankInvariantSet (T) : Set ℕ` = the set of `T i i i` values at concentrated slots (without filtering by `=2`). The cardinality of this set is GL³-invariant; the `=2` filter only matches the encoder's specific value.
- **Fallback strategy 2**: Reroute via Manin-as-corollary — A.5+A.6 deliver partition preservation as a side effect (the AlgEquiv preserves `presentArrowsSubspace` dimension, which equals `presentArrowSlotIndices.card`). This eliminates A.3.2/A.3.3/A.3.4 entirely. Cost: +200 LOC added to A.5 to handle the unit-stabilizer subgroup directly. Pre-planned hedge.

### A.3.3 + A.3.4 — Cardinality preservation (~110 LOC, Low risk)

**File:** `Orbcrypt/Hardness/GrochowQiao/PartitionRigidity.lean` (top).

**Headlines.**
```lean
theorem gl3_preserves_padding_card (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (hg : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂) :
    (paddingSlotIndices m adj₁).card = (paddingSlotIndices m adj₂).card

theorem gl3_preserves_path_card : ...    -- subtraction
theorem gl3_preserves_present_arrow_card : ...    -- = path - vertex (vertex card = m always)
```

**Proof technique.** A.3.3: apply `paddingRankInvariant_gl3_invariant` + `paddingRankInvariant_eq_paddingSlotIndices_card` on both encoders. A.3.4: `paddingSlot.card + pathSlot.card = dimGQ m` (already in `BlockDecomp.total_slot_cardinality`). Present-arrow card: `pathSlot.card - m` (vertex slots).

### A.3.5 — Partition-preserving slot permutation (~250 LOC, Med risk)

**File:** `Orbcrypt/Hardness/GrochowQiao/PartitionRigidity.lean` (bottom).

**Headline.**
```lean
noncomputable def gl3PartitionPreservingPerm
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (hg : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂) :
    Equiv.Perm (Fin (dimGQ m))

theorem gl3PartitionPreservingPerm_isThreePartition : ...
```

**Proof technique.** Feed the present-arrow cardinality equality (A.3.3 corollary) into the existing `BlockDecomp.partitionPreservingPermFromEqualCardinalities` (already proven); inherit the `IsThreePartitionPreserving` property from `BlockDecomp.partitionPreservingPermFromEqualCardinalities_isThreePartition`.

### A.5.1 — Abstract structure tensor (~180 LOC, Low risk)

**File:** `Orbcrypt/Hardness/GrochowQiao/Manin/StructureTensor.lean`.

**Headline.**
```lean
namespace Manin
def structureTensor {I F A} [Field F] [Ring A] [Algebra F A]
    [Fintype I] [DecidableEq I] (b : Basis I F A) :
    I → I → I → F :=
  fun i j k => (b.repr (b i * b j)) k

theorem structureTensor_recovers_mul {I F A} [...]
    (b : Basis I F A) (i j : I) :
    b i * b j = ∑ k, structureTensor b i j k • b k
```

**Proof technique.** Definition is direct from `Basis.repr`. Recovery uses `b.repr.symm_apply_apply` followed by `Finsupp.sum_fintype` unfolding. Add `_apply_def`, `_zero_of_orthogonal_basis`, `_eq_iff_basis_repr` for ergonomics.

**Mathlib anchors.** `Basis.repr`, `Basis.sum_repr`, `Finsupp.sum_fintype`, `Finsupp.linearCombination`.

### A.5.2 — Basis-change formula (~140 LOC, Low–Med risk)

**File:** `Orbcrypt/Hardness/GrochowQiao/Manin/BasisChange.lean`.

**Headline.**
```lean
namespace Manin
noncomputable def Basis.glPushforward {I F A} [...]
    (b : Basis I F A) (g : GL I F) : Basis I F A :=
  Basis.ofRepr (b.repr ≪≫ₗ (Matrix.toLin' g.val.toLin'.symm).toLinearEquiv...)
  -- alternative: Basis.constr-based construction

theorem structureTensor_glPushforward {I F A} [...]
    (b : Basis I F A) (g : GL I F) (i j k : I) :
    structureTensor (b.glPushforward g) i j k =
      ∑ a b' c, g.val i a * g.val j b' *
                structureTensor b a b' c * (g⁻¹.val) c k
```

**Proof technique.** Expand `b.glPushforward g i = ∑ a, g(i, a) · b a` via the `Basis.ofRepr` unfolding. Multiply two such sums using `Finset.sum_mul_sum`. Apply `structureTensor_recovers_mul` to `b a · b b'`. Re-expand the result via `b.repr` to extract the new structure tensor entries — this is where `g⁻¹` enters (via `b'_k = ∑_c g⁻¹(c, k) · b c`).

**Risk mitigation.** ~40 LOC reserve for `Finset.sum_comm` / `Finset.mul_sum` shuffles. The exact placement of `g.val` vs `g.val⁻¹` indices must match the `tensorAction` GL³ smul convention from `Orbcrypt/Hardness/TensorAction.lean:235`.

### A.5.3 + A.5.4 — Tensor stabilizer theorem (~480 LOC, **HIGH risk** — the technical core)

**File:** `Orbcrypt/Hardness/GrochowQiao/Manin/TensorStabilizer.lean`.

**Mathematical correctness (verified).** Multiplicativity of `φ : A → B` defined by `φ(b_A i) = ∑_p P(i,p) • b_B p` is equivalent to:
```
∑_l T_A(i,j,l) · P(l,k) = ∑_{p,q} P(i,p) · P(j,q) · T_B(p,q,k)    (for all i, j, k)
```
which is in turn equivalent to:
```
T_A(i,j,k) = ∑_{p,q,r} P(i,p) P(j,q) P⁻¹(r,k) T_B(p,q,r)
```
i.e. `(P, P, P⁻ᵀ) • T_B = T_A` in the `tensorAction` convention from `TensorAction.lean:235`. This is the **structure-tensor-preserving** GL³ action (with `P⁻ᵀ` being inverse-transpose, NOT just `P⁻¹`).

**Headlines.**
```lean
namespace Manin
noncomputable def algHomOfTensorIso
    {I F A B} [Field F] [Ring A] [Ring B] [Algebra F A] [Algebra F B]
    [Fintype I] [DecidableEq I]
    (b_A : Basis I F A) (b_B : Basis I F B)
    (P : GL I F)  -- structure-tensor-preserving (P, P, P⁻ᵀ) form
    (h_action : ∀ i j k, structureTensor b_A i j k =
                ∑ p q r, P i p * P j q * (P⁻¹ : Matrix _ _ _) r k *
                         structureTensor b_B p q r)
    (h_unit_compat : <P maps b_A.repr 1 to b_B.repr 1>) :
    A →ₐ[F] B

noncomputable def algEquivOfTensorIso (...) : A ≃ₐ[F] B
```

**Proof technique (A.5.3, ~280 LOC core), broken into 5 sub-units of ≤120 LOC each:**

* **A.5.3.1 — Definition of φ via `Basis.constr` (~30 LOC).** `φ := Basis.constr b_A (fun i => ∑ p, P(i,p) • b_B p)`. By `Basis.constr_basis`, `φ (b_A i) = ∑_p P(i,p) • b_B p`. φ is automatically linear.

* **A.5.3.2 — Multiplicativity on basis pairs (~120 LOC, index-tracking core).** Show `φ (b_A i * b_A j) = φ (b_A i) * φ (b_A j)`:
  - LHS expansion: `b_A i * b_A j = ∑_l T_A(i,j,l) • b_A l` (via `Manin.structureTensor_recovers_mul`); then `φ (b_A i * b_A j) = ∑_{l,k} T_A(i,j,l) · P(l,k) • b_B k`.
  - RHS expansion: `(∑_p P(i,p) • b_B p) * (∑_q P(j,q) • b_B q) = ∑_{p,q,k} P(i,p) · P(j,q) · T_B(p,q,k) • b_B k` (by bilinearity of `*` + `Manin.structureTensor_recovers_mul` for B).
  - Match coefficient on `b_B k`: need `∑_l T_A(i,j,l) · P(l,k) = ∑_{p,q} P(i,p) · P(j,q) · T_B(p,q,k)`.
  - Multiply `h_action` by `P(l,k)` and sum over l: LHS becomes `∑_l T_A(i,j,l) · P(l,k)`; RHS collapses via `∑_l P⁻¹(r,l) · P(l,k) = δ(r,k)` (matrix inverse, `P⁻¹ * P = 1`) leaving `∑_{p,q,r} P(i,p) P(j,q) δ(r,k) T_B(p,q,r) = ∑_{p,q} P(i,p) P(j,q) T_B(p,q,k)`. ✓
  - Apply `Basis.ext` to extend multiplicativity from basis pairs to all pairs `(x, y) ∈ A × A`.

* **A.5.3.3 — Unit preservation (~50 LOC).** Show `φ(1_A) = 1_B`. Use `h_unit_compat`, which encodes `b_A.repr 1` and `b_B.repr 1` as coefficient vectors related by `P`. Specifically: `1_A = ∑_v c_A(v) · b_A v` and `1_B = ∑_v c_B(v) · b_B v` for coefficient functions `c_A, c_B : I → F`; `h_unit_compat` is `∀ k, c_B(k) = ∑_v c_A(v) P(v, k)`. Then `φ(1_A) = ∑_v c_A(v) φ(b_A v) = ∑_{v,k} c_A(v) P(v,k) b_B k = ∑_k c_B(k) b_B k = 1_B`. ✓

* **A.5.3.4 — Package as AlgHom via `AlgHom.ofLinearMap` (~30 LOC).** Combine the linear φ from A.5.3.1, multiplicativity from A.5.3.2, and unit-preservation from A.5.3.3 using Mathlib's `AlgHom.ofLinearMap φ <unit_pres> <multiplicativity>`.

* **A.5.3.5 — Bijectivity for AlgEquiv upgrade (~50 LOC).** Construct φ': B → A symmetrically with `P⁻¹` (this requires showing `h_action` symmetrically: T_B in terms of T_A with `P⁻¹`, derivable by inverting the original matrix equation). Show `φ' ∘ φ = id_A` on basis: `φ'(φ(b_A i)) = φ'(∑_p P(i,p) b_B p) = ∑_{p,q} P(i,p) P⁻¹(p,q) b_A q = ∑_q δ(i,q) b_A q = b_A i`. Apply `Basis.ext`. Symmetric for `φ ∘ φ' = id_B`. Use `AlgEquiv.ofAlgHom` for A.5.4.

**Proof technique (A.5.4, ~70 LOC).** `algEquivOfTensorIso := AlgEquiv.ofAlgHom (algHomOfTensorIso b_A b_B P h_action h_unit) (algHomOfTensorIso b_B b_A P⁻¹ <inverted_h_action> <inverted_h_unit>) <left_inv> <right_inv>`. The inverted hypotheses come from inverting the matrix equation `P · A = B ⟹ A = P⁻¹ · B`.

**Reserve.** ~80 LOC for `Finset.sum_comm` reorderings + handling the `(P, P, P⁻ᵀ)` reduction (Decision D2) at the call site (in `PathOnlyAlgebra.lean`, not here).

### A.5.5 — Specialization to `pathAlgebraQuotient m` (~80 LOC, Low risk)

**File:** `Orbcrypt/Hardness/GrochowQiao/PathOnlyAlgebra.lean` (top).

**Headline.**
```lean
noncomputable def pathOnlyAlgebraSubalgebra (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Subalgebra ℚ (pathAlgebraQuotient m) where
  carrier := presentArrowsSubspace m adj
  one_mem' := <`1 = ∑_v vertexIdempotent v` ∈ presentArrowsSubspace>
  mul_mem' := <closure under multiplication via J²=0>
  ...

noncomputable def pathOnlyAlgebraBasis (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Basis (Fin (pathSlotIndices m adj).card) ℚ
          ↥(pathOnlyAlgebraSubalgebra m adj)
```

**Proof technique.** Build `Subalgebra` via `Subalgebra.mk'`. Multiplicative closure: `vertexIdempotent · vertexIdempotent → vertexIdempotent or 0` (via `vertexIdempotent_mul_vertexIdempotent`); `vertexIdempotent · arrowElement → arrowElement or 0` (via `vertexIdempotent_mul_arrowElement`); `arrowElement · arrowElement = 0` (via `arrowElement_mul_arrowElement_eq_zero` in J²=0).

The basis is `Finset.equivFin`-indexed by `pathSlotIndices m adj`; build via `Basis.mk` from explicit linear independence (vertex idempotents are pairwise orthogonal; arrow elements are linearly independent of vertex idempotents; J²=0) and spanning (via `pathAlgebra_decompose` from `WedderburnMalcev`).

### A.6.1 — Path-only-tensor ↔ subspace bridge (~130 LOC, Med risk)

**File:** `Orbcrypt/Hardness/GrochowQiao/PathOnlyAlgebra.lean` (middle).

**Headline.**
```lean
theorem pathOnlyAlgebraBasis_structureTensor_eq_pathOnlyStructureTensor
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Manin.structureTensor (pathOnlyAlgebraBasis m adj) =
      pathOnlyStructureTensor m adj
```

**Proof technique.** Funext over `(i, j, k : Fin (pathSlotIndices m adj).card)`. Unfold both sides:
- LHS: coefficient of `pathOnlyAlgebraBasis k` in `pathOnlyAlgebraBasis i * pathOnlyAlgebraBasis j`. Compute via `vertexIdempotent_mul_*` / `arrowElement_mul_*` lemmas, restricted to the path-only subalgebra.
- RHS: `pathOnlyStructureTensor m adj i j k = encode m adj (e i) (e j) (e k)` where `e := equivFin.symm`. Compute via `pathSlotStructureConstant`.

The two sides agree because `pathSlotStructureConstant` is precisely the structure-tensor-form of `pathMul` (the basis multiplication in `pathAlgebraQuotient m`).

### A.6.2 — Lift AlgEquiv to full `pathAlgebraQuotient m` (~70 LOC, Med risk)

**File:** `Orbcrypt/Hardness/GrochowQiao/PathOnlyAlgebra.lean` (bottom).

**Headline.**
```lean
noncomputable def gl3InducedAlgEquivOnPathAlgebraQuotient
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (hg : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂) :
    pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m
```

**Proof technique broken into 4 sub-units (~20 LOC each):**

* **A.6.2.1 — Path-block restriction (~20 LOC).** From the input `(g, hg)`, derive `π := gl3PartitionPreservingPerm m adj₁ adj₂ g hg : Equiv.Perm (Fin (dimGQ m))` via `PartitionRigidity` (A.3.5). Then construct `M := pathBlockMatrix m g π` and `M' := pathBlockMatrix m g⁻¹ π⁻¹` from `PathBlockSubspace.lean`. Verify `M' * M = 1` and `M * M' = 1` via the GL³ inversion `g · g⁻¹ = 1` + `π · π⁻¹ = 1`. Verify `IsPathBlockDiagonal m adj₁ adj₂ M` and `IsPathBlockDiagonal m adj₂ adj₁ M'` from π's partition-preservation.

* **A.6.2.2 — Path-only LinearEquiv (~10 LOC).** Apply `pathBlockEquivOfInverse` from `PathBlockSubspace.lean:611` to get `pathBlockSubspace m adj₁ ≃ₗ[ℚ] pathBlockSubspace m adj₂`. Compose with `pathBlockToPresentArrows` (existing LinearEquiv) on both sides to get `presentArrowsSubspace m adj₁ ≃ₗ[ℚ] presentArrowsSubspace m adj₂`. Equivalently this is the path-only-tensor LinearEquiv; via A.6.1 it preserves the structure tensor.

* **A.6.2.3 — Promote LinearEquiv to AlgEquiv on pathOnlyAlgebra (~20 LOC).** Apply `Manin.algEquivOfTensorIso` (A.5.4) with `b_A := pathOnlyAlgebraBasis m adj₁`, `b_B := pathOnlyAlgebraBasis m adj₂`, the `(P, P, P⁻ᵀ)` form of `M` extracted from path-block restriction (Decision D2 reduction at the call site, ~10 LOC dedicated lemma). The hypothesis `h_action` follows from A.6.1's `pathOnlyAlgebraBasis_structureTensor_eq_pathOnlyStructureTensor` + the GL³-action equation `g • encode adj₁ = encode adj₂` restricted to path-only slots. The hypothesis `h_unit_compat` follows from `encoder_unit_compatibility` (A.1.5) repackaged as the basis-coefficient equation.

* **A.6.2.4 — Extend AlgEquiv from `pathOnlyAlgebra` to `pathAlgebraQuotient` (~20 LOC).** Use the σ-extraction trick: extract `σ := (algEquiv_extractVertexPerm m φ).choose` from the path-only AlgEquiv `φ`, where `algEquiv_extractVertexPerm` is from `WedderburnMalcev.lean:801`. Apply `quiverPermAlgEquiv m σ` from `AlgEquivLift.lean` as the global AlgEquiv on `pathAlgebraQuotient m`. Verify `quiverPermAlgEquiv m σ` agrees with `φ` on `presentArrowsSubspace m adj₁` (basis-element by basis-element check using `quiverPermAlgEquiv_apply_vertexIdempotent` and `quiverPermAlgEquiv_apply_arrowElement` from `AlgEquivLift.lean`). Multiplicativity on the complement is automatic: J²=0 makes products with non-present arrows zero, and `quiverPermAlgEquiv` is multiplicative globally by construction.

**Reserve.** ~10 LOC for σ-extraction housekeeping.

**CAVEAT.** The sub-unit A.6.2.4 uses `quiverPermAlgEquiv m σ` as the **canonical extension** of φ to all of `pathAlgebraQuotient m`. This works because: (i) by Wedderburn–Mal'cev, every AlgEquiv on `pathAlgebraQuotient m` is conjugate (via `(1 + j) · _ · (1 - j)` for some `j ∈ J`) to a `quiverPermAlgEquiv σ` for unique σ; (ii) the inner-conjugation-by-`(1 + j)` action is the identity on `presentArrowsSubspace` (since `(1 + j) · α(u, v) · (1 - j) = α(u, v)` from `inner_aut_radical_fixes_arrow` in `AdjacencyInvariance.lean`). Hence the canonical σ-extension preserves the present-arrows action and is the right global lift.

### A.6.3 + Final discharge (~190 LOC, Low risk after A.6.2 lands)

**File:** `Orbcrypt/Hardness/GrochowQiao/Discharge.lean`.

**Headlines.**
```lean
theorem gl3InducesAlgEquivOnPathSubspace (m : ℕ) :
    GL3InducesAlgEquivOnPathSubspace m := by
  intro adj₁ adj₂ g hg
  refine ⟨gl3InducedAlgEquivOnPathAlgebraQuotient m adj₁ adj₂ g hg, ?_⟩
  -- Subspace-preservation: present-arrows subspace under the AlgEquiv = adj₂'s subspace.
  ...

theorem restrictedGL3OnPathOnlyTensor (m : ℕ) :
    RestrictedGL3OnPathOnlyTensor m := by
  intro adj₁ adj₂ g hg
  obtain ⟨ϕ, hϕ⟩ := gl3InducesAlgEquivOnPathSubspace m adj₁ adj₂ g hg
  -- Dimension counting: AlgEquiv ⟹ LinearEquiv ⟹ finrank equal on subspaces
  -- ⟹ presentArrows.card equal ⟹ presentArrowSlotIndices.card equal.
  ...
```

**Proof technique (A.6.3).** The subspace-preservation property follows directly from the construction: `gl3InducedAlgEquivOnPathAlgebraQuotient` was built so that its restriction to `presentArrowsSubspace m adj₁` produces `presentArrowsSubspace m adj₂` (via the chain of equivs in A.6.2). Use `Set.image_of_subset_image` or directly compute on basis elements.

**Proof technique (corollary).** Chain `LinearEquiv.finrank_eq` on the AlgEquiv's underlying linear equivalence + `Submodule.finrank_eq_card_basis` (with `pathOnlyAlgebraBasis`) + the bridge `presentArrows.card = presentArrowSlotIndices.card` (already in `PathBlockSubspace.lean` via `slotEquiv`).

---

## Critical Decision Points

**D1. `paddingRankInvariant` vs `pathRankInvariant`?** Recommend `paddingRankInvariant` only. The padding portion is a clean direct sum of trivial 1-dim algebras with distinguished diagonal value `2`, making it invariant-friendly. Path cardinality follows from total-dimension subtraction.

**D2. Manin theorem in reduced form (`(P, P, P⁻ᵀ)` form) or general?** Recommend reduced form. The structure-tensor-preserving subgroup of GL³ is the **`(P, P, P⁻ᵀ)`-shaped** triples (NOT `g.1 = g.3` — the third component is `P⁻ᵀ`, the inverse-transpose of the first). Mathematical derivation: φ(b_A i) = ∑_p P(i,p) b_B p is multiplicative iff `T_A(i,j,k) = ∑_{p,q,r} P(i,p) P(j,q) P⁻¹(r,k) T_B(p,q,r)`, which is exactly the `(P, P, P⁻ᵀ) • T_B = T_A` action in the `tensorAction` convention from `TensorAction.lean:235`. Manin's theorem is stated in this reduced form; the general-GL³ → `(P, P, P⁻ᵀ)` reduction is performed at the call site in `PathOnlyAlgebra.lean` as a 50-LOC lemma using `encoder_unit_compatibility`.

**D3. `Basis.constr` or hand-rolled basis machinery?** Recommend `Basis.constr` for the linear part, hand-rolled multiplicativity proof on top. Saves ~80 LOC, mathlib-stable, no `Basis.constr_alg_hom` exists so multiplicativity is hand-rolled regardless.

**D4. `Manin.structureTensor` namespace.** Recommend `Manin` (signalling reusability). When upstreamed to Mathlib, can be renamed `Algebra.structureTensor`. Don't squat on `Algebra` namespace prematurely.

**D5. `pathOnlyAlgebra` as a `Type` or as `Subalgebra`?** Recommend `Subalgebra ℚ (pathAlgebraQuotient m)`. Avoids fresh-type plumbing. Mathlib's `Subalgebra` provides `Algebra ℚ` automatically. The bridge to `pathAlgebraQuotient m` is `Subalgebra.subtype`.

**D6. Where to place `restrictedGL3OnPathOnlyTensor` (corollary)?** Recommend `Discharge.lean`, NOT `PathOnlyTensor.lean`. Keeps `PathOnlyTensor.lean` at ~470 LOC (under the 600-LOC cap). The original `Prop` definition stays put; the discharging theorem lives with the headline.

---

## Risk Register

| # | Risk | Severity | Mitigation |
|---|------|----------|------------|
| R1 | A.3.2 `paddingRankInvariant` GL³-invariance proof has counterexamples | **Critical** | Use slab-support concentration (rank-1 condition), not multiset of diagonal values. **Fallback:** reroute via Manin-as-corollary (~3 weeks added to A.5, eliminates A.3.2/A.3.3/A.3.4). The plan keeps `PaddingInvariant.lean` as a separate module specifically to enable this swap. |
| R2 | A.5.3 multiplicativity proof requires `g.1 = g.3` reduction not delivered cleanly by unit-compatibility | High | Land A.5.3 in `g.1 = g.3` form first; prove the reduction separately as a 50-LOC lemma using `encoder_unit_compatibility` at the call site in `PathOnlyAlgebra.lean`. |
| R3 | `TensorAction` GL³ smul convention disagrees with Manin theorem's convention | Med | Read `Orbcrypt/Hardness/TensorAction.lean:235` first; A.5.2's basis-change formula must match the convention exactly. Add a one-time conversion lemma if needed. |
| R4 | `pathOnlyAlgebraBasis` re-indexing fights `Finset.equivFin` non-canonicity | Med | Use `pathSlotIndices m adj`'s existing `equivFin` (already used by `pathOnlyStructureTensor`); never introduce a fresh `equivFin`. ~30 LOC for index-juggling lemmas. |
| R5 | A.6.2 "extend AlgEquiv to complement" multiplicativity gap | Low–Med | J²=0 covers it: arrow·arrow = 0 in `pathAlgebraQuotient m` (existing `arrowElement_mul_arrowElement_eq_zero`). Extension by `quiverPermAlgEquiv` is multiplicative globally; verify on basis pairs. |
| R6 | Module length ≤ 600 LOC violations (TensorStabilizer.lean budgets 480 LOC) | Low | Pre-planned split point: if A.5.3 swells past 480 LOC, split into `Manin/TensorStabilizerHom.lean` (A.5.3) + `Manin/TensorStabilizerEquiv.lean` (A.5.4). |
| R7 | Mathlib pinned at `fa6418a8` lacks an expected API surface | Med | Plan only depends on `Basis.constr`, `Basis.repr`, `AlgEquiv.ofAlgHom`, `LinearEquiv.ofBijective`, `Submodule.finrank_eq_card_basis`, `LinearMap.toMatrix` — all stable Mathlib for years. Hand-roll missing lemmas as in-file private helpers; do NOT update Mathlib. |
| R8 | Audit script flags new axioms beyond standard trio | Low | Use `propext`, `Classical.choice`, `Quot.sound` only. Replace `by_contra` with `Classical.choice`-flavoured constructions if needed. |

---

## Verification Plan

### Per-stage incremental build gates

The dependency graph supports a 4-stage incremental build. Each stage must `lake build` cleanly with **zero warnings, zero errors, zero `sorry`**.

| Stage | Modules to land + lake-build pass | Target |
|-------|-----------------------------------|--------|
| **B1** | `EncoderUnitCompatibility.lean`, `Manin/StructureTensor.lean`, `Manin/BasisChange.lean` | Manin foundations ready |
| **B2** | `Manin/TensorStabilizer.lean`, `PaddingInvariant.lean` (parallel tracks) | Two parallel tracks merge |
| **B3** | `PartitionRigidity.lean`, `PathOnlyAlgebra.lean` | Encoder-specific bridge ready |
| **B4** | `Discharge.lean` + rewires of `AlgEquivFromGL3.lean`, `Rigidity.lean`, `GrochowQiao.lean` | Headline unconditional |

### `#print axioms` checks (extending `scripts/audit_phase_16.lean`)

Add a new section `§ 15.18 R-TI Phase 3 final discharge — Manin + Padding rigidity` listing ~25 `#print axioms` entries for every new public declaration. Required-trio acceptance: each output must be exactly `[propext, Classical.choice, Quot.sound]` or a strict subset.

Per-headline checks:
* `#print axioms Manin.structureTensor` and `Manin.structureTensor_recovers_mul`.
* `#print axioms Manin.structureTensor_glPushforward`.
* `#print axioms Manin.algEquivOfTensorIso`.
* `#print axioms paddingRankInvariant`, `paddingRankInvariant_eq_paddingSlotIndices_card`, `paddingRankInvariant_gl3_invariant`.
* `#print axioms gl3PartitionPreservingPerm`, `gl3_preserves_padding_card`, `gl3_preserves_path_card`.
* `#print axioms pathOnlyAlgebraSubalgebra`, `pathOnlyAlgebraBasis`, `pathOnlyAlgebraBasis_structureTensor_eq_pathOnlyStructureTensor`.
* `#print axioms gl3InducedAlgEquivOnPathAlgebraQuotient`.
* `#print axioms gl3InducesAlgEquivOnPathSubspace`, `restrictedGL3OnPathOnlyTensor`.
* `#print axioms grochowQiao_isInhabitedKarpReduction` (the headline that becomes unconditional).

### Non-vacuity tests (~20 examples)

Under a new `namespace Phase3DischargeNonVacuity`, exercise each headline at `m ∈ {1, 2, 3}` with concrete adjacencies. Examples:

```lean
example : gl3InducesAlgEquivOnPathSubspace 2 :=
  Discharge.gl3InducesAlgEquivOnPathSubspace 2

example (adj : Fin 2 → Fin 2 → Bool) :
    ∃ ϕ : pathAlgebraQuotient 2 ≃ₐ[ℚ] pathAlgebraQuotient 2,
      ϕ '' (presentArrowsSubspace 2 adj : Set _) =
        (presentArrowsSubspace 2 adj : Set _) :=
  gl3InducesAlgEquivOnPathSubspace 2 adj adj 1 (one_smul _ _)

example (m : ℕ) (adj : Fin m → Fin m → Bool) :
    paddingRankInvariant (grochowQiaoEncode m adj) =
      (paddingSlotIndices m adj).card :=
  paddingRankInvariant_eq_paddingSlotIndices_card m adj

example : grochowQiao_isInhabitedKarpReduction = grochowQiao_isInhabitedKarpReduction := rfl
```

Plus identity-case witnesses on non-trivial graphs (e.g., `m = 3`, `adj := fun u v => decide (u.val ≠ v.val)`) to exercise the substantive proof paths.

### Final acceptance gate

* `lake build` end-to-end clean (3,410+ jobs, zero warnings, zero errors).
* `#print axioms grochowQiao_isInhabitedKarpReduction` reports exactly `[propext, Classical.choice, Quot.sound]`.
* `lakefile.lean` version bumped (e.g., `0.1.24 → 0.2.0` for the milestone).
* `CLAUDE.md` change-log entry recording the discharge.
* `docs/VERIFICATION_REPORT.md` updated to mark `R-15-residual-TI-reverse` as **CLOSED**.
* `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` updated to mark `R-15` as **CLOSED**.
* `docs/planning/R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md` updated to record completion.
* The Vacuity-map row in `Orbcrypt.lean` for these two Props is removed (they're no longer obligations).

---

## Calendar Estimate

Single highly-skilled Lean implementer at ~120 LOC/week of formal-mathematics-grade content:

| Week | Track A (Manin) | Track B (Encoder-specific) | Risk events |
|-----:|-----------------|----------------------------|-------------|
| 1 | A.5.1 | (planning) | — |
| 2 | A.5.2 | A.1.5 | — |
| 3–6 | A.5.3 in flight | A.3.1 + A.3.2 (week 3); A.3.3 + A.3.4 (week 4) | R1 firing window (weeks 3–4) |
| 7 | A.5.3 lands | A.3.5 lands | R2 firing window (week 7) |
| 8 | A.5.4 | (idle, awaits Manin) | — |
| 9 | A.5.5 + A.6.1 | (merged) | — |
| 10 | A.6.2 | — | R5 firing window |
| 11 | A.6.3 + corollary in `Discharge.lean` | — | — |
| 12 | Rewires + audit-script + verification | — | — |

**Single-implementer total:** ~12 weeks (~3 months) wall-clock.

**Two-implementer parallelization:** ~8 weeks. Implementer A on Manin (Track A, weeks 1–8); Implementer B on encoder-specific (Track B, weeks 1–6) then helps Implementer A finish A.5.3 or starts Track C (rewires + audit-script work) early.

**Stall scenarios:**
* R1 fires (paddingRankInvariant intractable): reroute via Manin-as-corollary, **+3 weeks**.
* R2 fires (g.1 = g.3 reduction harder than expected): **+1 week**.
* R3 fires (TensorAction convention mismatch): **+1 week** of conversion-lemma work.

**Realistic upper bound (single implementer, two stalls fire):** ~16 weeks (~4 months).

---

## Optimization Opportunities (Reuse Existing Infrastructure)

| # | Opportunity | Savings |
|---|-------------|--------:|
| O1 | Reuse `pathBlockToPresentArrows` LinearEquiv from `PathBlockSubspace.lean` as the linear core of A.6.1's bridge — no need to re-derive slot/arrow correspondence. | -60 LOC |
| O2 | `pathOnlyStructureTensor_isAssociative` (already in `PathOnlyTensor.lean`) is exactly what A.5.5 needs as input — direct re-export, no reproof. | -40 LOC |
| O3 | Reuse `algEquiv_extractVertexPerm` and `quiverPermAlgEquiv` (existing `WedderburnMalcev`/`AlgEquivLift`) for A.6.2's "extend to complement". | -50 LOC |
| O4 | `BlockDecomp.partitionPreservingPermFromEqualCardinalities` + `_isThreePartition` are exactly A.3.5's target. | -100 LOC |
| O5 | `restrictedGL3OnPathOnlyTensor_identity_case` (existing in `PathOnlyTensor.lean`) is subsumed by the new unconditional theorem — drop it. | -25 LOC |
| O6 | `pathAlgebra_decompose` from `WedderburnMalcev` gives `1 = ∑_v vertexIdempotent m v`, satisfying the unit-existence hypothesis of Manin without new proof. | -20 LOC |
| O7 | The corollary `restrictedGL3OnPathOnlyTensor` is genuinely 30–50 LOC (just dimension counting via `LinearEquiv.finrank_eq` + the existing `slotEquiv` bridge), not the 250 LOC the v4 plan implicitly suggests. | -200 LOC |
| **Total realistic savings** | | **~495 LOC** |

Applying these brings the realistic budget down from ~2,120 LOC to **~1,625 LOC**. The plan banks the savings as additional reserve, raising effective reserve from 530 LOC to ~1,000 LOC — appropriate headroom for stall scenarios R1 and R2.

---

## Critical Files

**To be modified:**
* `/home/user/Orbcrypt/Orbcrypt.lean` — add 8 new module imports.
* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/PathOnlyTensor.lean` — retire `_identity_case`; keep `Prop` def for backward signature compat.
* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/AlgEquivFromGL3.lean` — drop `h_research` arg from headline.
* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao/Rigidity.lean` — drop conditional chain.
* `/home/user/Orbcrypt/Orbcrypt/Hardness/GrochowQiao.lean` — make `grochowQiaoRigidity` and `grochowQiao_isInhabitedKarpReduction` unconditional.
* `/home/user/Orbcrypt/lakefile.lean` — version bump.
* `/home/user/Orbcrypt/scripts/audit_phase_16.lean` — extend §15.18 with new declarations + non-vacuity examples.
* `/home/user/Orbcrypt/CLAUDE.md` — change-log entry.
* `/home/user/Orbcrypt/docs/VERIFICATION_REPORT.md` — close R-15.

**To be created (8 new files):**
* `Orbcrypt/Hardness/GrochowQiao/EncoderUnitCompatibility.lean`
* `Orbcrypt/Hardness/GrochowQiao/Manin/StructureTensor.lean`
* `Orbcrypt/Hardness/GrochowQiao/Manin/BasisChange.lean`
* `Orbcrypt/Hardness/GrochowQiao/Manin/TensorStabilizer.lean`
* `Orbcrypt/Hardness/GrochowQiao/PaddingInvariant.lean`
* `Orbcrypt/Hardness/GrochowQiao/PartitionRigidity.lean`
* `Orbcrypt/Hardness/GrochowQiao/PathOnlyAlgebra.lean`
* `Orbcrypt/Hardness/GrochowQiao/Discharge.lean`

**Read-only references (existing infrastructure to reuse, no edits):**
* `Orbcrypt/Hardness/GrochowQiao/AlgebraWrapper.lean` — `pathAlgebraQuotient`, `vertexIdempotent`, `arrowElement`, all multiplication-table lemmas.
* `Orbcrypt/Hardness/GrochowQiao/WedderburnMalcev.lean` — `pathAlgebraRadical`, J²=0 results, `algEquiv_extractVertexPerm`.
* `Orbcrypt/Hardness/GrochowQiao/AlgEquivLift.lean` — `quiverPermAlgEquiv`.
* `Orbcrypt/Hardness/GrochowQiao/AdjacencyInvariance.lean` — `arrowElement_sandwich`, `inner_aut_radical_fixes_arrow`.
* `Orbcrypt/Hardness/GrochowQiao/EncoderSlabEval.lean` + `EncoderPolynomialIdentities.lean` — encoder polynomial identities.
* `Orbcrypt/Hardness/GrochowQiao/PathBlockSubspace.lean` — `pathBlockMatrix`, `pathBlockEquivOfInverse`, `pathBlockToPresentArrows`.
* `Orbcrypt/Hardness/GrochowQiao/BlockDecomp.lean` — `partitionPreservingPermFromEqualCardinalities`.
* `Orbcrypt/Hardness/TensorAction.lean` — `Tensor3` GL³ smul convention (CRITICAL for A.5.2).

---

## End-to-End Verification (How to Test)

After all 8 new modules + 6 rewires land, run the following from `/home/user/Orbcrypt/`:

1. **Mathlib cache:** `lake exe cache get` (one-time setup; ~7910 oleans).

2. **Full build:** `source ~/.elan/env && lake build 2>&1 | tail -10` — must show `Build completed successfully` with **3,418+ jobs** (3,410 baseline + 8 new modules), **zero warnings**, **zero errors**.

3. **Warning check:** `lake build 2>&1 | grep -iE "warning|⚠"` — must return empty.

4. **Sorry check:** `perl -0777 -pe 's|/-.*?-/||gs; s|--[^\n]*||g' Orbcrypt/Hardness/GrochowQiao/*.lean Orbcrypt/Hardness/GrochowQiao/Manin/*.lean | grep -E "\bsorry\b|^\s*axiom\s"` — must return empty.

5. **Audit script:** `lake env lean scripts/audit_phase_16.lean 2>&1 > /tmp/audit.txt; echo $?` — exit 0; `grep -c sorryAx /tmp/audit.txt` returns `0`; `grep "depends on axioms" /tmp/audit.txt | sed -n 's/.*\[\(.*\)\]/\1/p' | sort -u` returns ONLY `propext`, `Quot.sound`, `propext, Classical.choice, Quot.sound`, `propext, Quot.sound` (subsets of standard trio).

6. **Headline axioms:** `grep "grochowQiao_isInhabitedKarpReduction" /tmp/audit.txt` — output must show the theorem depends only on the standard Lean trio.

7. **Per-module rebuild:** Touch each new module file and rebuild — verifies clean dependencies.

8. **Naming-rule check:** `git diff HEAD~1..HEAD --name-only | grep "\.lean$" | xargs -I{} grep -E "^(def|theorem|structure|class|instance|abbrev|lemma|noncomputable)" "{}" | grep -iE 'workstream|\bws[0-9_a-z]+|\bphase[0-9_]|audit|\bf[0-9]{2}\b|claude_|session_'` — must return empty.

9. **CI workflow:** `.github/workflows/lean4-build.yml` runs (no manual intervention) on `git push`; ensure `lake build` and audit-script step pass.

10. **Git push:** `git push -u origin <branch>` — triggers CI, which must pass green.

---

## Action Plan Summary (Sequence to Follow)

1. **Phase B1 (weeks 1–2):** Land `EncoderUnitCompatibility.lean` (A.1.5), `Manin/StructureTensor.lean` (A.5.1), `Manin/BasisChange.lean` (A.5.2). Each lands as a separate commit. Verify per-stage build + audit-script clean.

2. **Phase B2 (weeks 3–7):** In parallel, land:
   - Track A: `Manin/TensorStabilizer.lean` (A.5.3 + A.5.4) — 4 weeks of careful work.
   - Track B: `PaddingInvariant.lean` (A.3.1 + A.3.2) — 2 weeks. R1 firing window.

3. **Phase B3 (weeks 8–9):** Land `PartitionRigidity.lean` (A.3.3 + A.3.4 + A.3.5), `PathOnlyAlgebra.lean` (A.5.5 + A.6.1 + A.6.2). Rapid sequence after B2 stabilizes.

4. **Phase B4 (weeks 10–12):** Land `Discharge.lean` (A.6.3 + corollary), rewire `AlgEquivFromGL3.lean` / `Rigidity.lean` / `GrochowQiao.lean` to drop `h_research` hypotheses, extend audit script, update CLAUDE.md + VERIFICATION_REPORT.md, bump `lakefile.lean` version, push to remote, verify CI green.

5. **Final commit:** Single squash-merge commit with comprehensive message documenting:
   - Discharge of both research-scope `Prop`s.
   - Closure of `R-15-residual-TI-reverse` research milestone.
   - Unconditional `grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _`.
   - All ~25 new declarations on standard Lean trio.
   - 8 new modules + 6 rewires; LOC count; version bump.

---

## Plan Storage

**Plan-mode constraint:** This plan currently lives at `/root/.claude/plans/create-a-comprehensive-and-bubbly-acorn.md` (the only file plan mode permits editing).

**Upon ExitPlanMode + execution:** Copy this plan to `docs/planning/AUDIT_2026-04-28_PHASE_3_PROP_DISCHARGE_PLAN.md` as the canonical workstream document under the project's planning directory, matching the convention of existing `AUDIT_*_WORKSTREAM_PLAN.md` files.
