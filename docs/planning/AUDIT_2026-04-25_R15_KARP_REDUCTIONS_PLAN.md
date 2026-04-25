# Plan: R-15 Karp reductions for `GIReducesToCE` and `GIReducesToTI`

> **Document provenance.** This file is the canonical, version-
> controlled copy of the implementation plan that drove the R-CE
> Layer 0 landing (Petrank–Roth bit-layout primitives,
> `Orbcrypt/Hardness/PetrankRoth/BitLayout.lean`, version
> `0.1.14 → 0.1.15`).  It was authored interactively during the
> 2026-04-25 plan-mode session, audited (R-CE returned six findings
> integrated as Refinements R1–R4; R-TI substituted with self-audit +
> definitive Decisions GQ-A through GQ-D), strengthened, and approved
> for execution before Layer 0 began.  All pre-implementation design
> decisions live below; subsequent layer landings reference back to
> this document by filename.  Cross-reference targets:
> `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § O / R-15 (the
> upstream audit-plan entry that scoped this work) and `CLAUDE.md`'s
> Workstream history (where each layer's landing is recorded).

## Context

The Orbcrypt project's strengthened `GIReducesToCE` and `GIReducesToTI`
Props (post-Workstream-I, audit findings J-03 / J-08) are inhabited only
at the type-level non-degeneracy layer. The full Karp-reduction iff has
been research-scope **R-15** (audit plan § 15.1 / § O). The user has
authorised full-scope implementation:

* GI ≤ CE via **Petrank–Roth 1997** (full bidirectional iff).
* GI ≤ TI via **Grochow–Qiao 2021** (full reduction, including the
  multi-month rigidity argument).

**Note on user's "CFI" wording.** Clarified Phase 3: CFI is a graph-
gadget *lower bound* construction, not a Karp reduction. Petrank–Roth
1997 is the canonical Karp reduction GI ≤ CE.

This is the largest single workstream the project has ever undertaken.
It is split into two independent workstreams (**R-CE** and **R-TI**),
each landable independently with version bumps. The plan structures
work into commit-landable sub-tasks with explicit dependency tracking
and risk gates at every sub-layer boundary.

## Combined effort budget (post-strengthening, 2026-04-25)

| Workstream | Lines | Weeks | Sub-tasks |
|-----------|-------|-------|-----------|
| **R-CE** (Petrank–Roth, post-audit refinements R1–R4) | 2,980–3,780 | 4–6 | 43 (across 8 layers) |
| **R-TI** (Grochow–Qiao, post-strengthening Decisions GQ-A–GQ-D, mandatory) | 8,050–17,500 | 10–17 | 44 (across 7 layers including new T0) |
| **R-TI stretch** (T5.6–T5.8, optional) | +700–1,700 | +1–2 | +3 |
| **Chain integration** | 200–500 | 0.5–1 | 4 |
| **TOTAL (mandatory)** | **11,230–21,780** | **16–24 weeks** | **91** |
| **TOTAL (with stretch)** | **11,930–23,480** | **17–26 weeks** | **94** |

Realistic horizon (mandatory): **5 months** at upper bound,
**4 months** at lower bound. R-CE is the prerequisite-free starting
point; R-TI follows. No hard dependency exists between them, but
landing R-CE first is the clean-energy default.

Note: the post-strengthening total is **lower** than the pre-audit
estimate because the path-algebra rigidity argument (T4 + T5)
replaces a Skolem–Noether / Smith-normal-form chain that would have
ballooned at the upper bound. See "Audit summary" near the end of
this plan for the full delta breakdown.

## User decisions (Phase 3, captured)

1. ✅ **GI ≤ CE target:** Petrank–Roth 1997 (incidence-matrix + 3 marker
   columns per edge).
2. ✅ **GI ≤ CE scope:** full bidirectional iff (forward + reverse).
3. ✅ **GI ≤ TI target:** full Grochow–Qiao 2021 (multi-month research-
   grade formalization, including the rigidity argument).

## Project-wide conventions (must obey at every sub-task)

* **Zero `sorry`** in source modules. Zero custom axioms. Every new
  declaration's `#print axioms` must be standard-trio (`propext`,
  `Classical.choice`, `Quot.sound`) or axiom-free.
* **Every public declaration** has a `/-- … -/` docstring. Every module
  has a `/-! … -/` module docstring. Honest disclosure of any
  intermediate-result limitations (no overclaiming).
* **`autoImplicit := false`** is enforced project-wide (lakefile.lean).
  All universe and type variables explicitly declared.
* **Naming convention:** `snake_case` for theorems/lemmas, `CamelCase`
  for structures. Names describe content, never provenance: no
  `_workstream_R`, `_phase_15`, `_audit_2026` tokens in identifiers.
  Process markers may appear in docstring traceability notes only.
* **No `sed`/`awk` mass edits** to source files. Use `Edit` with
  ≤80-line diff blocks per CLAUDE.md's large-file-protection rule.
* **Each commit lands one logical sub-task.** Build-clean and audit-
  clean before committing. Push after every commit.
* **Patch version bump per landing milestone.** R-CE landing →
  `0.1.14 → 0.1.15`. R-TI landing → `0.1.15 → 0.1.16`. Chain integration
  → `0.1.16 → 0.1.17`.
* **Audit-script entry per public declaration.** `scripts/audit_phase_16.lean`
  gets a `#print axioms NewDecl` line for every new public def/theorem/
  structure/instance/abbrev/lemma.
* **Per-layer non-vacuity examples.** At least one concrete-instance
  `example` block per layer in the audit script's `NonVacuityWitnesses`
  namespace.

---

# Workstream R-CE: Petrank–Roth 1997 (GI ≤ CE)

**Total estimate: 3,000–5,000 lines across 38 sub-tasks / 8 layers / 4–6 weeks.**

**Landing status (as of 2026-04-25): Option B — forward-only.**
Layers 0, 1, 2, 3 are landed (`Orbcrypt/Hardness/PetrankRoth/BitLayout.lean`,
`Orbcrypt/Hardness/PetrankRoth.lean`,
`Orbcrypt/Hardness/PetrankRoth/MarkerForcing.lean`) with the headline
`prEncode_forward` proving the easier iff direction.  Layer 3
provides the column-weight invariance infrastructure
(`colWeight_permuteCodeword_image`) underlying the reverse direction.
Layers 4–7 (the marker-forcing endpoint recovery →
`prEncode_reverse` → `prEncode_iff` → headline
`petrankRoth_isInhabitedKarpReduction`) are deferred per the Risk
Gate as **R-15-residual-CE-reverse** (research-scope, ~800–1500
lines, ~7–14 days).  The full inhabitant of `GIReducesToCE` (which
requires both iff directions) therefore remains research-scope; the
type-level `GIReducesToCE_card_nondegeneracy_witness` in
`Orbcrypt/Hardness/CodeEquivalence.lean` is unchanged.

## R-CE module organisation

| File | Purpose | Target lines |
|------|---------|--------------|
| `Orbcrypt/Hardness/PetrankRoth/BitLayout.lean` | Layer 0 helpers | 250–350 |
| `Orbcrypt/Hardness/PetrankRoth.lean` | Top-level encoder + Layers 1, 2, 5, 6, 7 | 1,400–2,200 |
| `Orbcrypt/Hardness/PetrankRoth/MarkerForcing.lean` | Layers 3, 4 (reverse direction) | 1,200–2,400 |

Files modified (documentation/audit-script only): `Hardness/CodeEquivalence.lean`,
`Orbcrypt.lean`, `CLAUDE.md`, `docs/VERIFICATION_REPORT.md`,
`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md`, `lakefile.lean`,
`scripts/audit_phase_16.lean`.

## R-CE design overview

* **Block length** `dimPR m = m + 4 * numEdges m + 1` (m vertex columns,
  4 columns per edge slot — 1 incidence + 3 marker — plus 1 sentinel for
  `codeSize_pos` at `m ≤ 1`).
* **Codeword count** `codeSizePR m = m + 4 * numEdges m + 1`.
* **Encoder** `prEncode m adj` = union of four image families (vertex,
  edge, marker, sentinel), each with a distinct column-weight signature.
* **Forward (Layer 2):** σ ∈ Aut(G) → π = `liftAut σ` ∈ S_{dimPR m}.
* **Reverse (Layers 3+4):** any π witnessing CE-equivalence must respect
  the four-family partition (column-weight invariant), then the vertex
  part of π yields σ ∈ Aut(G).

## R-CE post-audit refinements (Petrank–Roth audit, 2026-04-25)

A mathematical audit of the R-CE construction surfaced **three concerns**
that require explicit handling in the implementation. None is a
soundness bug; all are under-specified spots in the original plan that
would surface as proof obstructions during Lean implementation.

### Refinement R1 — Cardinality-forced surjectivity bridge (NEW Sub-task 4.0, ~30 lines)

`ArePermEquivalent C₁ C₂ := ∃ σ, ∀ c ∈ C₁, σ·c ∈ C₂` is **one-sided**:
σ maps C₁ *into* C₂, not necessarily *onto*. Layer 3 / 4's column-
weight invariance argument requires **two-sided** equivalence (σ(C₁) =
C₂) to invoke codeword-multiset preservation symmetrically.

The bridge: when `|C₁| = |C₂|` (which holds via `prEncode_card`) and
`permuteCodeword σ` is injective (which it is — Equiv), `σ(C₁) ⊆ C₂`
with equal cardinalities and finiteness forces `σ(C₁) = C₂`.

**Add Sub-task 4.0 before 4.1:**
```lean
lemma surj_of_inj_card_eq (σ : Equiv.Perm (Fin n))
    (C₁ C₂ : Finset (Fin n → Bool))
    (h : ∀ c ∈ C₁, permuteCodeword σ c ∈ C₂)
    (hcard : C₁.card = C₂.card) :
    ∀ c' ∈ C₂, ∃ c ∈ C₁, permuteCodeword σ c = c'
```

**Discharge:** `Finset.image (permuteCodeword σ) C₁ ⊆ C₂` (by `h`)
and `(Finset.image ...).card = C₁.card` (by injectivity of
`permuteCodeword`) gives `Finset.image ... = C₂` by `Finset.eq_of_subset_of_card_le`.

**Risk:** none. Pure Finset arithmetic. ~30 lines.

**Used by:** Sub-tasks 4.1, 4.4, 4.7, 4.8.

### Refinement R2 — Isolated-vertex handling in extractVertexPerm (Sub-task 4.1 budget revised: 80 → 150 lines)

The Layer-3 column-weight signature distinguishes vertex columns from
{incidence, marker, sentinel} columns only when the column has weight
≥ 2 — i.e., for **non-isolated** vertices. Isolated vertices (vertices
not incident to any present edge) have column weight exactly 1, the
same as incidence/marker/sentinel.

**Resolution:** Sub-task 4.1's `extractVertexPerm` is well-defined
*only* on non-isolated vertices via the column-weight signature. On
isolated vertices, σ's action is **not uniquely determined** by π —
any bijection between adj₁'s isolated-vertex set and adj₂'s isolated-
vertex set works (both restrict to the all-zeros adjacency).

**Implementation strategy:**
```lean
def extractVertexPermOnNonIsolated (...) : Fin m → Option (Fin m)
def extractVertexPerm (...) : Equiv.Perm (Fin m) :=
  -- Defined on non-isolated by extractVertexPermOnNonIsolated;
  -- extended to isolated vertices via Equiv.Perm.extend or
  -- Finset.bijection_of_eq_card (fixing some canonical bijection
  -- between the two isolated-vertex sets).
```

This is sound — the iff conclusion `∀ i j, adj₁ i j = adj₂ (σ i) (σ j)`
doesn't require σ to be canonical on isolated vertices; the action on
the all-zeros adjacency is automatic.

**Budget revision:** Sub-task 4.1: 80 → **150 lines**. Layer 4 total:
800–1500 → **870–1570 lines**.

### Refinement R3 — Restage 4.4 as adjacency-first / τ-second (Sub-task 4.4 unchanged, but proof outline revised)

The original 4.4 outline derives `τ = liftedEdgePerm σ` first, then
adjacency recovery (4.7). For **absent edges** (adj₁ u w = false), the
edge codeword has support {incidence column for e} only, and the
endpoints of `τ e` in adj₂ are **not directly visible** from the
codeword.

**Restaged proof (contrapositive at 4.4):** prove the iff conclusion
`adj₁ u w = adj₂ (σ u) (σ w)` directly, by contrapositive on each side:
* If `adj₁ u w = true`: edgeCodeword adj₁ e has weight 3, its π-image
  has weight 3, weight-3 codewords in `prEncode m adj₂` are exactly
  edge codewords for present edges, and endpoint-tracking via σ
  forces `adj₂ (σ u) (σ w) = true`.
* If `adj₂ (σ u) (σ w) = true`: by Refinement R1's cardinality-forced
  surjectivity, some c ∈ C₁ has π-image equal to `edgeCodeword adj₂
  (liftedEdgePerm σ e)`. Weight-tracking forces c to be a weight-3
  codeword in C₁, i.e., an edge codeword for a present edge in adj₁.
  Endpoint-tracking forces `adj₁ u w = true`, contradiction.

**Budget unchanged** at ~300 lines, but the proof structure is now
explicit. Update Sub-task 4.4's prose at implementation time.

### Refinement R4 — `liftedEdgePerm` canonicalisation is essential (Sub-task 2.1)

The plan's 2.1 mentions canonicalisation but the Lean skeleton omits
the explicit swap. Without canonicalisation, `liftedEdgePerm σ`'s
output may fail the `u.val < v.val` precondition of `edgeIndex`.

**Pinned implementation:**
```lean
def liftedEdgePerm (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    Equiv.Perm (Fin (numEdges m)) := by
  refine ⟨fun e => ?_, fun e => ?_, ?_, ?_⟩
  · -- toFun
    let (u, v) := edgeEndpoints m e
    let u' := σ u
    let v' := σ v
    refine if h : u'.val < v'.val then
      edgeIndex m u' v' h
    else
      edgeIndex m v' u' (by ...)  -- σ.injective + u ≠ v
  · ...  -- invFun via σ⁻¹, same canonicalisation
  · ...  -- left_inv via permutation round-trip
  · ...  -- right_inv similarly
```

**Risk noted:** if 2.1 forgets canonicalisation, `liftedEdgePerm` is
ill-typed; this is caught at definition time, not as a hidden bug.

### Updated R-CE Layer 4 budget (post-audit)

| Sub-task | Original | Revised | Δ |
|----------|---------:|--------:|---|
| 4.0 (NEW: surjectivity bridge) | — | 30 | +30 |
| 4.1 (extractVertexPerm) | 120 | 150 | +30 |
| 4.4 (marker-forcing core, restaged) | 300 | 300 | 0 |
| Other 4.x | unchanged | unchanged | 0 |
| **Layer 4 total** | 800–1500 | **870–1570** | **+70** |
| **R-CE workstream total** | 2,910–3,710 | **2,980–3,780** | **+70** |

Updated total: **2,980–3,780 lines** for R-CE, **18.75–25.75 days**
unchanged (the +70 lines are formulaic).

## R-CE Layer 0 — Bit-layout primitives (5 sub-tasks, ~250–350 lines, ~1.5 days)

**File:** `Orbcrypt/Hardness/PetrankRoth/BitLayout.lean`. **Imports:**
`Mathlib.Data.Fin.Basic`, `Mathlib.Data.Nat.Basic`,
`Mathlib.Logic.Equiv.Basic`. No Orbcrypt imports — this file is a
foundational helpers module.

### Sub-task 0.1: Dimension and edge-count primitives (~50 lines)

**Declarations:**
```lean
def numEdges (m : ℕ) : ℕ := m * (m - 1) / 2
def dimPR (m : ℕ) : ℕ := m + 4 * numEdges m + 1
def codeSizePR (m : ℕ) : ℕ := m + 4 * numEdges m + 1
```

**Lemmas (with discharge tactics):**
```lean
theorem numEdges_zero : numEdges 0 = 0  -- by `rfl` or `decide`
theorem numEdges_one : numEdges 1 = 0  -- by `rfl`
theorem numEdges_two : numEdges 2 = 1  -- by `rfl`
theorem numEdges_three : numEdges 3 = 3  -- by `rfl`
theorem numEdges_le : numEdges m ≤ m * m  -- by `Nat.div_le_self` chain
theorem dimPR_pos : 0 < dimPR m  -- by `Nat.add_pos_of_pos_right Nat.one_pos`
theorem codeSizePR_pos : 0 < codeSizePR m  -- by same; discharges field
```

**Risk:** none. Pure Nat arithmetic; `decide` handles small cases, `omega`
handles the inequalities.

**Commit-landable:** yes; the rest of Layer 0 builds on these.

### Sub-task 0.2: `PRCoordKind` inductive + Decidable + Fintype (~60 lines)

```lean
inductive PRCoordKind (m : ℕ) where
  | vertex (v : Fin m)
  | incid (e : Fin (numEdges m))
  | marker (e : Fin (numEdges m)) (k : Fin 3)
  | sentinel
  deriving DecidableEq

instance : Fintype (PRCoordKind m) := ...  -- via the four constructors
```

**Implementation note:** the `deriving DecidableEq` clause works because
all constructors take `Fin _` arguments which already have DecidableEq.
The `Fintype` instance is constructed manually as a sum-product over
the four constructor families.

**Risk:** the `Fintype` instance for `PRCoordKind 0` (when `numEdges 0
= 0`) needs the right empty-Fin handling — `Fin 0` has the empty
Fintype, so the `incid`/`marker` constructors contribute zero
elements. Verify with `#eval Fintype.card (PRCoordKind 3) = 3 + 3 + 9 + 1 = 16`.

**Commit-landable:** yes after 0.1 lands.

### Sub-task 0.3: `edgeEndpoints` enumeration with canonicalisation (~80 lines)

**Goal:** establish a bijection between `Fin (numEdges m)` and unordered
edges `{(u, v) : Fin m × Fin m | u < v}`. We use the *canonical
enumeration* of pairs `(u, v)` with `u < v` in lexicographic order.

```lean
def edgeEndpoints (m : ℕ) : Fin (numEdges m) → Fin m × Fin m
def edgeIndex (m : ℕ) (u v : Fin m) (h : u.val < v.val) : Fin (numEdges m)

theorem edgeEndpoints_lt (m : ℕ) (e : Fin (numEdges m)) :
    (edgeEndpoints m e).1.val < (edgeEndpoints m e).2.val
theorem edgeEndpoints_edgeIndex (h : u.val < v.val) :
    edgeEndpoints m (edgeIndex m u v h) = (u, v)
theorem edgeIndex_edgeEndpoints (e : Fin (numEdges m)) :
    edgeIndex m (edgeEndpoints m e).1 (edgeEndpoints m e).2
      (edgeEndpoints_lt m e) = e
```

**Implementation note:** the standard explicit formula is
`edgeEndpoints m e := (u, v)` where `u, v` are computed from `e.val` via
`Nat.find` over the triangular-number sequence
`0, 1, 3, 6, 10, ...`. Concrete formula:
* `v.val := Nat.find (fun v => e.val < v * (v - 1) / 2 + v) - 1`
* `u.val := e.val - v.val * (v.val - 1) / 2`

Or simpler: define a `Finset.Nat.antidiagonal`-style enumeration via
`(Finset.range m).sigma (fun v => Finset.range v)` and pair-up by index.

**Risk:** medium. Triangular-number arithmetic is finicky; budget
~80 lines including `omega`-discharged inequalities. **Mitigation:**
write a brute-force `decide`-tested implementation first for
`m ∈ {0, 1, 2, 3, 4, 5}` and verify the bijection with `#eval`,
then prove the general bijection.

**Commit-landable:** yes after 0.2 lands.

### Sub-task 0.4: `prCoord` / `prCoordKind` bijection (~80 lines)

```lean
def prCoord (m : ℕ) : PRCoordKind m → Fin (dimPR m)
def prCoordKind (m : ℕ) : Fin (dimPR m) → PRCoordKind m

theorem prCoord_prCoordKind (i : Fin (dimPR m)) :
    prCoord m (prCoordKind m i) = i
theorem prCoordKind_prCoord (k : PRCoordKind m) :
    prCoordKind m (prCoord m k) = k
```

**Implementation note:** layout is:
* `[0, m)` — vertex columns. `prCoord m (vertex v) = ⟨v.val, _⟩`.
* `[m, m + numEdges m)` — incidence columns.
  `prCoord m (incid e) = ⟨m + e.val, _⟩`.
* `[m + numEdges m, m + 4 * numEdges m)` — marker columns, in blocks of 3.
  `prCoord m (marker e k) = ⟨m + numEdges m + 3 * e.val + k.val, _⟩`.
* `[m + 4 * numEdges m, m + 4 * numEdges m + 1)` — sentinel.
  `prCoord m sentinel = ⟨m + 4 * numEdges m, _⟩`.

The inverse `prCoordKind` is computed by case-splitting on the value
of `i.val` against the four range boundaries (using `omega` and
`Nat.div`/`Nat.mod` for the marker decomposition).

**Risk:** medium. Case-splitting against four boundaries is verbose
but mechanical. Heavy `omega` use; budget ~80 lines.

**Commit-landable:** yes after 0.3 lands.

### Sub-task 0.5: Layer 0 audit-script entries (~30 lines)

Add to `scripts/audit_phase_16.lean`:
```lean
-- R-CE Layer 0
#print axioms numEdges
#print axioms dimPR
#print axioms codeSizePR
#print axioms PRCoordKind
#print axioms edgeEndpoints
#print axioms edgeIndex
#print axioms prCoord
#print axioms prCoordKind
#print axioms prCoord_prCoordKind
#print axioms prCoordKind_prCoord
#print axioms numEdges_two
#print axioms dimPR_pos
#print axioms codeSizePR_pos
```

Plus a layer-0 non-vacuity example computing `prCoord 3 (vertex ⟨0, _⟩)`,
`prCoord 3 (incid ⟨0, _⟩)`, `prCoord 3 (marker ⟨0, _⟩ ⟨0, _⟩)`,
`prCoord 3 sentinel` and verifying they're distinct via `decide`.

**Commit-landable:** end of Layer 0 milestone. Patch version unchanged
(Layer 0 lands as part of an incomplete R-CE workstream; full version
bump comes at end of Layer 7).

## R-CE Layer 1 — Encoder + cardinality (7 sub-tasks, ~400 lines, ~2 days)

**File:** `Orbcrypt/Hardness/PetrankRoth.lean`. **Imports:**
`Orbcrypt.Hardness.PetrankRoth.BitLayout`,
`Orbcrypt.Hardness.CodeEquivalence` (for `permuteCodeword` /
`ArePermEquivalent`).

### Sub-task 1.1: Codeword constructors (~80 lines)

```lean
def vertexCodeword (m : ℕ) (v : Fin m) : Fin (dimPR m) → Bool :=
  fun i => decide (prCoordKind m i = .vertex v)

def edgeCodeword (m : ℕ) (adj : Fin m → Fin m → Bool)
    (e : Fin (numEdges m)) : Fin (dimPR m) → Bool :=
  fun i =>
    match prCoordKind m i with
    | .vertex v =>
        let (u, w) := edgeEndpoints m e
        adj u w ∧ (v = u ∨ v = w)
    | .incid e' => decide (e = e')
    | _ => false

def markerCodeword (m : ℕ) (e : Fin (numEdges m)) (k : Fin 3) :
    Fin (dimPR m) → Bool :=
  fun i => decide (prCoordKind m i = .marker e k)

def sentinelCodeword (m : ℕ) : Fin (dimPR m) → Bool :=
  fun i => decide (prCoordKind m i = .sentinel)
```

**Risk:** low. Pure case analysis on `prCoordKind`. The
`edgeCodeword` definition's `(v = u ∨ v = w)` clause encodes
"vertex `v` is an endpoint of edge `e`".

**Commit-landable:** yes.

### Sub-task 1.2: Codeword evaluation lemmas (~60 lines)

```lean
@[simp] theorem vertexCodeword_at_vertex (m : ℕ) (v v' : Fin m) :
    vertexCodeword m v (prCoord m (.vertex v')) = decide (v = v')
@[simp] theorem vertexCodeword_at_incid : ... = false
@[simp] theorem vertexCodeword_at_marker : ... = false
@[simp] theorem vertexCodeword_at_sentinel : ... = false
@[simp] theorem edgeCodeword_at_vertex (m adj e v) :
    edgeCodeword m adj e (prCoord m (.vertex v)) =
    (let (u, w) := edgeEndpoints m e; adj u w ∧ (v = u ∨ v = w))
@[simp] theorem edgeCodeword_at_incid (m adj e e') :
    edgeCodeword m adj e (prCoord m (.incid e')) = decide (e = e')
@[simp] theorem edgeCodeword_at_marker : ... = false
@[simp] theorem edgeCodeword_at_sentinel : ... = false
@[simp] theorem markerCodeword_at_marker (m e k e' k') :
    markerCodeword m e k (prCoord m (.marker e' k')) =
    decide (e = e' ∧ k = k')
-- (and zero-result lemmas for other coord-kinds)
@[simp] theorem sentinelCodeword_at_sentinel : ... = true
@[simp] theorem sentinelCodeword_at_other_kinds : ... = false
```

**Discharge:** `simp [..., prCoordKind_prCoord]` reduces each lemma to
`decide ... = ...`, closed by `rfl` after `prCoordKind_prCoord` rewrites
the LHS into a constructor match.

**Risk:** low. Mostly mechanical `simp`. ~10 lemmas × 6 lines each.

**Commit-landable:** yes after 1.1.

### Sub-task 1.3: Pairwise distinctness — within each family (~60 lines)

```lean
theorem vertexCodeword_injective (m : ℕ) :
    Function.Injective (vertexCodeword m)
theorem edgeCodeword_injective (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Function.Injective (edgeCodeword m adj)
theorem markerCodeword_injective (m : ℕ) :
    Function.Injective (Function.uncurry (markerCodeword m))
```

**Discharge:** for each lemma, `intro a b hab; ext; simp` then derive
`a = b` from `decide (a = ?) = decide (b = ?)` evaluated at the
discriminating coordinate (the `vertex a`/`incid a`/`marker a _`
column).

**Risk:** low. Each proof ~20 lines.

**Commit-landable:** yes after 1.2.

### Sub-task 1.4: Cross-family disjointness (~60 lines)

```lean
theorem vertexCodeword_ne_edgeCodeword (m : ℕ) (adj : ...)
    (v : Fin m) (e : Fin (numEdges m)) :
    vertexCodeword m v ≠ edgeCodeword m adj e
theorem vertexCodeword_ne_markerCodeword : ...
theorem vertexCodeword_ne_sentinelCodeword : ...
theorem edgeCodeword_ne_markerCodeword : ...
theorem edgeCodeword_ne_sentinelCodeword : ...
theorem markerCodeword_ne_sentinelCodeword : ...
```

**Discharge:** evaluate at `prCoord m sentinel` (or another
discriminating coordinate); the two codewords disagree there.
Each proof ~10 lines.

**Edge case:** `vertexCodeword_ne_edgeCodeword` evaluated at `vertex v`
needs care because `edgeCodeword` is `true` at vertex columns when
`adj u w = true ∧ v ∈ {u, w}`. To distinguish, evaluate at the
edge's `incid e` column, where `vertexCodeword v` is `false` and
`edgeCodeword e` is `true`.

**Risk:** low–medium. Six pair-disjointness lemmas. Budget ~60 lines.

**Commit-landable:** yes after 1.3.

### Sub-task 1.5: `prEncode` definition (~40 lines)

```lean
def prEncode (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Finset (Fin (dimPR m) → Bool) :=
  (Finset.univ.image (vertexCodeword m)) ∪
  (Finset.univ.image (edgeCodeword m adj)) ∪
  (Finset.univ.image (Function.uncurry (markerCodeword m))) ∪
  {sentinelCodeword m}
```

**Risk:** none. Direct constructor.

**Commit-landable:** yes after 1.4.

### Sub-task 1.6: `prEncode_card` proof (~80 lines)

```lean
theorem prEncode_card (m : ℕ) (adj : Fin m → Fin m → Bool) :
    (prEncode m adj).card = codeSizePR m
```

**Discharge:**
1. Apply `Finset.card_union_of_disjoint` four times using 1.4 lemmas.
2. Each `Finset.image` reduces via `Finset.card_image_of_injective`.
3. Compute the four Fintype cardinalities (`m`, `numEdges m`,
   `3 * numEdges m`, `1`).
4. Sum: `m + numEdges m + 3 * numEdges m + 1 = m + 4 * numEdges m + 1
   = codeSizePR m`. Discharge by `omega`.

**Risk:** medium. The `Finset.card_union_of_disjoint` chain is finicky
because of left-associativity. Budget ~80 lines.

**Commit-landable:** yes after 1.5.

### Sub-task 1.7: Layer 1 audit-script + non-vacuity example (~30 lines)

```lean
-- R-CE Layer 1
#print axioms vertexCodeword
#print axioms edgeCodeword
#print axioms markerCodeword
#print axioms sentinelCodeword
#print axioms prEncode
#print axioms prEncode_card

example : (prEncode 3 (fun _ _ => false)).card = codeSizePR 3 :=
  prEncode_card 3 _
example : (prEncode 3 (fun i j => decide (i ≠ j))).card = codeSizePR 3 :=
  prEncode_card 3 _
```

**Commit-landable:** end of Layer 1 milestone.

## R-CE Layer 2 — Forward direction (10 sub-tasks, ~600 lines, ~3 days)

**File:** `Orbcrypt/Hardness/PetrankRoth.lean`, mid section.

### Sub-task 2.1: Vertex-permutation-induced edge permutation (~80 lines)

```lean
def liftedEdgePerm (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    Equiv.Perm (Fin (numEdges m))
```

**Definition strategy:** for each edge `e` with endpoints `(u, w) :=
edgeEndpoints m e`, the σ-induced edge has endpoints `(σ u, σ w)`
canonicalised to `(min, max)` order. Define via:
```lean
def liftedEdgePermFun (σ : Equiv.Perm (Fin m)) (e : Fin (numEdges m)) :
    Fin (numEdges m) :=
  let (u, w) := edgeEndpoints m e
  let (u', w') := if (σ u).val < (σ w).val then (σ u, σ w) else (σ w, σ u)
  edgeIndex m u' w' (by ...)  -- uses (σ u).val ≠ (σ w).val from σ.injective
```

Then package as `Equiv.Perm` by exhibiting an inverse via `liftedEdgePermFun
σ⁻¹` and proving the round-trips by `Function.LeftInverse.equiv`.

**Risk:** medium. Canonicalisation + `omega`-discharged orderings. Budget ~80 lines.

**Commit-landable:** yes.

### Sub-task 2.2: `liftedEdgePerm` group-homomorphism lemmas (~80 lines)

```lean
@[simp] theorem liftedEdgePerm_one (m : ℕ) :
    liftedEdgePerm m (1 : Equiv.Perm (Fin m)) = 1
@[simp] theorem liftedEdgePerm_mul (σ τ : Equiv.Perm (Fin m)) :
    liftedEdgePerm m (σ * τ) = liftedEdgePerm m σ * liftedEdgePerm m τ
```

**Discharge:** `Equiv.ext`, then for each edge `e` evaluate
`(σ * τ) u`, `(σ * τ) w`, canonicalise, and verify the result equals
`liftedEdgePerm m σ (liftedEdgePerm m τ e)`. Heavy `simp` use; the
`Equiv.Perm.coe_mul` rewrite reduces the multiplication.

**Risk:** medium. Each proof ~40 lines. The `liftedEdgePerm_mul` proof
needs careful canonicalisation arithmetic.

**Commit-landable:** yes after 2.1.

### Sub-task 2.3: `liftAut` construction (~60 lines)

```lean
def liftAut (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    Equiv.Perm (Fin (dimPR m))
```

**Definition strategy:**
```lean
def liftAutKind (σ : Equiv.Perm (Fin m)) :
    PRCoordKind m → PRCoordKind m
  | .vertex v => .vertex (σ v)
  | .incid e => .incid (liftedEdgePerm m σ e)
  | .marker e k => .marker (liftedEdgePerm m σ e) k
  | .sentinel => .sentinel
```

Then `liftAut σ : Equiv.Perm (Fin (dimPR m))` is constructed by:
* `toFun i := prCoord m (liftAutKind σ (prCoordKind m i))`
* `invFun i := prCoord m (liftAutKind σ⁻¹ (prCoordKind m i))`
* with `left_inv`, `right_inv` via `prCoord_prCoordKind` chain plus
  the σ → σ⁻¹ inverse property.

**Risk:** low–medium. Routine `Equiv` construction. Budget ~60 lines.

**Commit-landable:** yes after 2.2.

### Sub-task 2.4: `liftAut` group-homomorphism lemmas (~50 lines)

```lean
@[simp] theorem liftAut_one (m : ℕ) :
    liftAut m (1 : Equiv.Perm (Fin m)) = 1
@[simp] theorem liftAut_mul (σ τ : Equiv.Perm (Fin m)) :
    liftAut m (σ * τ) = liftAut m σ * liftAut m τ
@[simp] theorem liftAut_inv (σ : Equiv.Perm (Fin m)) :
    liftAut m σ⁻¹ = (liftAut m σ)⁻¹
```

**Discharge:** `Equiv.ext`, case-split on `prCoordKind`, then use 2.2
lemmas. Each proof ~15 lines.

**Risk:** low. Mechanical.

**Commit-landable:** yes after 2.3.

### Sub-task 2.5: Forward action on vertex codewords (~60 lines)

```lean
theorem liftAut_vertexCodeword (m : ℕ) (σ : Equiv.Perm (Fin m)) (v : Fin m) :
    permuteCodeword (liftAut m σ) (vertexCodeword m (σ v)) =
    vertexCodeword m v
```

**Wait — direction matters.** Recall `permuteCodeword σ c i = c (σ⁻¹ i)`.
So we want: applying `liftAut σ` (via `permuteCodeword`) to the encoded
G_2 ought to give the encoded G_1 (where G_2 = σ · G_1). Spell out:

For the forward iff, we need:
```
∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)
   ⇒
∃ ρ : Equiv.Perm (Fin (dimPR m)),
   ∀ c ∈ prEncode m adj₁, permuteCodeword ρ c ∈ prEncode m adj₂
```

So `ρ = liftAut σ⁻¹` (or some specific direction depending on action
convention). The action lemma takes shape:
```lean
theorem permuteCodeword_liftAut_vertexCodeword
    (σ : Equiv.Perm (Fin m)) (v : Fin m) :
    permuteCodeword (liftAut m σ) (vertexCodeword m v) =
    vertexCodeword m (σ v)
```

(or possibly with `σ⁻¹` on the RHS depending on the chosen convention).

**Discharge:** `funext i`, case-split on `prCoordKind m i`, evaluate
both sides via Layer-1.2 lemmas + `prCoordKind_prCoord`. ~60 lines.

**Risk:** medium — the direction-of-action chase is subtle and easy
to get backwards. Budget extra time + a `decide`-driven sanity check
at `m = 3`.

**Commit-landable:** yes after 2.4.

### Sub-task 2.6: Forward action on edge codewords (~120 lines)

```lean
theorem permuteCodeword_liftAut_edgeCodeword
    (σ : Equiv.Perm (Fin m))
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : ∀ i j, adj₁ i j = adj₂ (σ i) (σ j))
    (e : Fin (numEdges m)) :
    permuteCodeword (liftAut m σ) (edgeCodeword m adj₁ e) =
    edgeCodeword m adj₂ (liftedEdgePerm m σ e)
```

**Discharge:** `funext i`, case-split on `prCoordKind m i`, use
`liftedEdgePerm` definition + `h` to translate `adj₁` to `adj₂`. The
hard sub-case is the vertex-column case where both codewords are
non-zero and the σ → σ correspondence must be verified. ~120 lines
because edge codewords have non-trivial structure on vertex columns.

**Risk:** medium–high. The most intricate Layer-2 sub-task. Budget
extra time + concrete `m = 3, adj = K_3` test cases.

**Commit-landable:** yes after 2.5.

### Sub-task 2.7: Forward action on marker codewords (~50 lines)

```lean
theorem permuteCodeword_liftAut_markerCodeword
    (σ : Equiv.Perm (Fin m)) (e : Fin (numEdges m)) (k : Fin 3) :
    permuteCodeword (liftAut m σ) (markerCodeword m e k) =
    markerCodeword m (liftedEdgePerm m σ e) k
```

**Discharge:** `funext i`, case-split, use `liftAut`'s marker-branch
definition. Each marker stays at its position-within-block while the
edge index permutes. ~50 lines.

**Risk:** low.

**Commit-landable:** yes after 2.6.

### Sub-task 2.8: Forward action on sentinel (~20 lines)

```lean
theorem permuteCodeword_liftAut_sentinelCodeword
    (σ : Equiv.Perm (Fin m)) :
    permuteCodeword (liftAut m σ) (sentinelCodeword m) = sentinelCodeword m
```

**Discharge:** `funext i`, case-split on `prCoordKind`. Sentinel is
fixed by `liftAut` (the `liftAutKind .sentinel = .sentinel` clause).

**Risk:** none.

**Commit-landable:** yes after 2.7.

### Sub-task 2.9: `prEncode_forward` assembly (~80 lines)

```lean
theorem prEncode_forward (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) :
    ArePermEquivalent (prEncode m adj₁) (prEncode m adj₂)
```

**Discharge:**
1. `obtain ⟨σ, hσ⟩ := h`.
2. Use `liftAut m σ` as the witnessing permutation.
3. `intro c hc` (where `hc : c ∈ prEncode m adj₁`).
4. Unfold `prEncode` to four-way union, case-split on which family
   `c` belongs to.
5. In each branch use the corresponding action lemma (2.5–2.8) to
   compute `permuteCodeword (liftAut σ) c` and show it lies in the
   matching family of `prEncode m adj₂`.

~80 lines. Mostly bookkeeping after 2.5–2.8 are done.

**Risk:** low–medium. Long but mechanical case split.

**Commit-landable:** yes after 2.8.

### Sub-task 2.10: Layer 2 audit-script + non-vacuity (~30 lines)

```lean
-- R-CE Layer 2
#print axioms liftedEdgePerm
#print axioms liftedEdgePerm_one
#print axioms liftedEdgePerm_mul
#print axioms liftAut
#print axioms liftAut_one
#print axioms liftAut_mul
#print axioms liftAut_inv
#print axioms permuteCodeword_liftAut_vertexCodeword
#print axioms permuteCodeword_liftAut_edgeCodeword
#print axioms permuteCodeword_liftAut_markerCodeword
#print axioms permuteCodeword_liftAut_sentinelCodeword
#print axioms prEncode_forward

example : ArePermEquivalent (prEncode 3 (fun _ _ => false))
                            (prEncode 3 (fun _ _ => false)) :=
  prEncode_forward 3 _ _ ⟨1, fun _ _ => rfl⟩
```

**Commit-landable:** end of Layer 2 milestone. **Forward direction
complete.** This is the natural fallback (Option B) landing point if
Layer 4 stalls.

## R-CE Layer 3 — Column-weight invariant (6 sub-tasks, ~400 lines, ~3 days)

**File:** `Orbcrypt/Hardness/PetrankRoth/MarkerForcing.lean`. **Imports:**
`Orbcrypt.Hardness.PetrankRoth` (depends on Layer 1's `prEncode`).

This layer proves: **any π : Equiv.Perm (Fin (dimPR m)) witnessing
`ArePermEquivalent (prEncode m adj₁) (prEncode m adj₂)` must respect
the four-family column partition.** This is the entry to the reverse
direction.

### Sub-task 3.1: Column-weight definition (~40 lines)

```lean
def colWeight (C : Finset (Fin n → Bool)) (i : Fin n) : ℕ :=
  (C.filter (fun c => c i = true)).card

@[simp] theorem colWeight_empty (i : Fin n) : colWeight ∅ i = 0
@[simp] theorem colWeight_singleton_self (c : Fin n → Bool) (i : Fin n)
    (h : c i = true) : colWeight {c} i = 1
@[simp] theorem colWeight_singleton_other (c : Fin n → Bool) (i : Fin n)
    (h : c i = false) : colWeight {c} i = 0
theorem colWeight_union_disjoint
    (C₁ C₂ : Finset (Fin n → Bool)) (h : Disjoint C₁ C₂) (i : Fin n) :
    colWeight (C₁ ∪ C₂) i = colWeight C₁ i + colWeight C₂ i
```

**Risk:** low. Standard `Finset.filter`/`card`/`union` algebra.

**Commit-landable:** yes.

### Sub-task 3.2: `colWeight` invariance under `permuteCodeword` (~80 lines)

```lean
theorem colWeight_permuteCodeword_image (C : Finset (Fin n → Bool))
    (π : Equiv.Perm (Fin n)) (i : Fin n) :
    colWeight (C.image (permuteCodeword π)) (π i) = colWeight C i
```

**Discharge:** unfold `colWeight`, push the filter through `Finset.image`
(injective via `permuteCodeword_injective`), align indices via
`permuteCodeword_apply` and `Equiv.Perm.symm_apply_apply`.

**Implication for reverse direction:** if `π` is the permutation
witnessing CE-equivalence (i.e., `C.image (permuteCodeword π) ⊆ C'`)
then column weights are preserved up to π's coordinate relabelling.

**Risk:** medium. The Finset.image-of-filter / filter-of-image
arithmetic in Mathlib needs careful selection of lemmas. Budget ~80 lines.

**Commit-landable:** yes after 3.1.

### Sub-task 3.3: Column-weight signatures of the four families (~120 lines)

```lean
theorem colWeight_prEncode_at_vertex (m : ℕ) (adj : ...) (v : Fin m) :
    colWeight (prEncode m adj) (prCoord m (.vertex v))
    = 1 + (Finset.univ.filter (fun e =>
            let (u, w) := edgeEndpoints m e
            adj u w ∧ (v = u ∨ v = w))).card

theorem colWeight_prEncode_at_incid (m : ℕ) (adj : ...)
    (e : Fin (numEdges m)) :
    colWeight (prEncode m adj) (prCoord m (.incid e)) = 1

theorem colWeight_prEncode_at_marker (m : ℕ) (adj : ...)
    (e : Fin (numEdges m)) (k : Fin 3) :
    colWeight (prEncode m adj) (prCoord m (.marker e k)) = 1

theorem colWeight_prEncode_at_sentinel (m : ℕ) (adj : ...) :
    colWeight (prEncode m adj) (prCoord m .sentinel) = 1
```

**Discharge:** apply `colWeight_union_disjoint` four times, then
evaluate each family's contribution using Layer-1.2 lemmas.

**Risk:** medium. Long but mechanical. Budget ~120 lines (30 per
column-kind).

**Commit-landable:** yes after 3.2.

### Sub-task 3.4: Column-kind discriminator (~80 lines)

```lean
inductive ColKind | vertex | incid | marker | sentinel deriving DecidableEq

def colKindOfWeight (C : Finset (Fin n → Bool)) (i : Fin n) : ColKind ⊕ Unit
  -- Sum so we can express "no determination possible"; the marker-
  -- forcing argument requires distinguishing four classes plus
  -- handling degenerate graphs.
```

**Implementation strategy:** the column-kind is determined by:
* Vertex: `colWeight ≥ 1` AND there exists a weight-1 codeword in `C`
  whose support contains exactly this column AND this column's
  (unique) weight-1-codeword is a vertex codeword (distinguishable
  from sentinel by uniqueness — sentinel codeword is unique in its
  weight-1 family).
* Incidence: `colWeight = 1` AND the unique codeword at this column
  is an edge codeword (distinguishable by having weight ≥ 1 + 0 to 2
  on vertex columns).
* Marker: `colWeight = 1` AND the unique codeword has weight 1 (the
  marker codewords are characterised by being singletons on their
  marker column).
* Sentinel: `colWeight = 1` AND the unique codeword is the all-zeros-
  except-sentinel function (distinguishable from markers by *which*
  column has weight 1 in the codeword — sentinel codeword's only
  true bit is on the sentinel column at index `m + 4 * numEdges m`).

**Note:** the cleanest implementation uses a *signature* — the
multiset of weights of codewords containing column `i` — rather than
a complex case-split. Define
```lean
def colSignature (C : Finset (Fin n → Bool)) (i : Fin n) :
    Multiset ℕ :=
  (C.filter (fun c => c i = true)).val.map
    (fun c => (Finset.univ.filter (fun j => c j = true)).card)
```
and show that distinct column kinds have distinct signatures *on
non-degenerate graphs* (i.e. graphs with at least one edge present).

**Risk:** medium. The signature-based discriminator needs careful
non-collision analysis. Budget ~80 lines.

**Commit-landable:** yes after 3.3.

### Sub-task 3.5: Permutation preserves column-kind (~80 lines)

```lean
theorem permuteCodeword_preserves_colKind
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_nondeg : ∃ u v, adj₁ u v = true)  -- non-degenerate graph
    (π : Equiv.Perm (Fin (dimPR m)))
    (h : ∀ c ∈ prEncode m adj₁, permuteCodeword π c ∈ prEncode m adj₂) :
    ∀ i, colKindOfWeight (prEncode m adj₂) (π i) =
         colKindOfWeight (prEncode m adj₁) i
```

**Discharge:** use 3.2 (colWeight invariance) + 3.4 (signature
discrimination) to push the column kind through π's coordinate
relabelling.

**Risk:** medium. The hypothesis on `h_nondeg` (graph has at least
one edge) is essential — at the empty graph all edge codewords
collapse to weight-1 incidence-only codewords and the
incidence/marker discrimination fails. Need a separate
`prEncode_reverse_empty_graph` for the all-zeros adjacency.

**Commit-landable:** yes after 3.4.

### Sub-task 3.6: Layer 3 audit-script + non-vacuity (~30 lines)

```lean
-- R-CE Layer 3
#print axioms colWeight
#print axioms colWeight_permuteCodeword_image
#print axioms colWeight_prEncode_at_vertex
#print axioms colWeight_prEncode_at_incid
#print axioms colWeight_prEncode_at_marker
#print axioms colWeight_prEncode_at_sentinel
#print axioms ColKind
#print axioms colKindOfWeight
#print axioms permuteCodeword_preserves_colKind
```

Plus a non-vacuity example computing `colWeight (prEncode 3 adj) (vertex
v)` for a concrete `K_3` adjacency and checking it equals the expected
1 + 2 = 3.

**Commit-landable:** end of Layer 3 milestone.

## R-CE Layer 4 — Marker-forcing reverse direction (10 sub-tasks, ~800–1500 lines, ~7–14 days)

**File:** `Orbcrypt/Hardness/PetrankRoth/MarkerForcing.lean`,
second half. **The hardest layer; budget extra time.**

**Goal:** given any π witnessing CE-equivalence between
`prEncode m adj₁` and `prEncode m adj₂`, extract σ ∈ Equiv.Perm (Fin m)
such that `∀ i j, adj₁ i j = adj₂ (σ i) (σ j)`.

**Risk gate:** at end of Sub-task 4.4 (week 4 of R-CE), reassess. If
4.4 isn't 50% complete by week-4 end, switch to Option B (forward-only
landing — already complete after Layer 2) and track Layers 4–7 as
**R-15-residual-CE-reverse**.

### Sub-task 4.1: Vertex-column sub-permutation extraction (~120 lines)

```lean
def extractVertexPerm
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_nondeg : ∃ u v, adj₁ u v = true)
    (π : Equiv.Perm (Fin (dimPR m)))
    (h : ∀ c ∈ prEncode m adj₁, permuteCodeword π c ∈ prEncode m adj₂) :
    Fin m → Fin m
```

**Strategy:** use Layer-3.5 to know π maps vertex columns to vertex
columns. Define `extractVertexPerm v := the unique v' such that
π (prCoord m (.vertex v)) = prCoord m (.vertex v')`.

```lean
theorem extractVertexPerm_spec :
    π (prCoord m (.vertex v)) = prCoord m (.vertex (extractVertexPerm ... v))
```

**Risk:** medium. The "unique v'" requires `prCoord` to be injective
+ vertex-column-respect from Layer 3.5. Budget ~120 lines.

**Commit-landable:** yes.

### Sub-task 4.2: `extractVertexPerm` is bijective → `Equiv.Perm (Fin m)` (~80 lines)

```lean
def extractVertexPermAsEquiv (...) : Equiv.Perm (Fin m)
```

**Strategy:** σ is bijective because π is bijective and π restricted
to vertex columns is itself a bijection (by Layer-3.5 column-kind
preservation + injectivity of `prCoord`). Construct the inverse
similarly via π⁻¹.

**Risk:** low–medium. Standard `Function.Bijective.of_*` chasing. ~80 lines.

**Commit-landable:** yes after 4.1.

### Sub-task 4.3: Edge-column sub-permutation extraction (~80 lines)

```lean
def extractEdgePerm (...) : Equiv.Perm (Fin (numEdges m))
```

Symmetric to 4.1+4.2. By Layer 3, π maps incid columns to incid
columns; extract the edge permutation τ.

**Risk:** low–medium. Same shape as 4.1+4.2 combined. Budget ~80 lines.

**Commit-landable:** yes after 4.2.

### Sub-task 4.4: τ = liftedEdgePerm σ (the marker-forcing core, ~300 lines)

```lean
theorem extractEdgePerm_eq_liftedEdgePerm_extractVertexPerm
    (...) :
    extractEdgePerm ... = liftedEdgePerm m (extractVertexPermAsEquiv ...)
```

**This is the hardest single sub-task.** The argument:

1. For each edge `e` with endpoints `(u, w) := edgeEndpoints m e`,
   the edge codeword `edgeCodeword m adj₁ e` has support
   on incidence column `e` (always true) and on vertex columns
   `u, w` (true iff `adj₁ u w`).
2. Under π, this codeword maps to some `edgeCodeword m adj₂ e'`
   where `e' = extractEdgePerm e`.
3. The image's vertex-column support determines the endpoints of
   `e'` in `adj₂`: they are exactly `(π(u), π(w))` (using
   Layer-4.1's σ).
4. So the endpoints of `e'` in adj₂'s edge enumeration must be
   `(σ u, σ w)` (canonicalised).
5. By definition of `liftedEdgePerm σ`, this means `e' =
   liftedEdgePerm σ e`. Conclude `extractEdgePerm = liftedEdgePerm σ`.

**Risk:** **HIGH.** The chain "edge codeword's support → endpoints
of σ-shifted edge" requires careful interpretation when `adj₁ u w =
false` (the edge codeword has *no* vertex-column support and its
identification by π depends only on the marker columns within its
block). Mitigation: case-split on whether `adj₁ u w` is true or
false; the false-case proof is harder and may need a sub-lemma
about marker-column block preservation. Budget ~300 lines (but
could expand to 600).

**Commit-landable:** yes after 4.3, but watch the risk gate here.

### Sub-task 4.5: Marker-block-position freedom analysis (~80 lines)

```lean
theorem extractMarkerPerm_within_block (...) :
    ∀ e : Fin (numEdges m), ∃ ρ : Equiv.Perm (Fin 3),
      ∀ k : Fin 3,
        π (prCoord m (.marker e k)) =
        prCoord m (.marker (liftedEdgePerm m σ e) (ρ k))
```

**Strategy:** by 4.4, π maps `marker e k` to `marker (lifted σ e) k'`
for some `k' : Fin 3`. The map `k ↦ k'` defines a permutation
within each edge-block. We don't need to identify this permutation —
just confirm it exists. The marker-block freedom is *harmless* for
the iff conclusion because adj₁ → adj₂ correspondence depends only on
vertex columns, not marker columns.

**Risk:** low. Existential extraction.

**Commit-landable:** yes after 4.4.

### Sub-task 4.6: π = liftAut σ (canonical-form argument, ~120 lines)

```lean
theorem extracted_perm_eq_liftAut_canonical (...) :
    ∃ ρ_marker : Fin (numEdges m) → Equiv.Perm (Fin 3),
      ∀ i : Fin (dimPR m),
        π i = (liftAut m σ).trans (markerBlockPerm ρ_marker) i
```

Where `markerBlockPerm` is a within-block-only marker-relabelling
permutation. This decomposition isn't strictly needed for the iff
but cleanly separates "vertex-determined behaviour" from "harmless
marker freedom". Skip if Layer 4's budget is tight.

**Risk:** medium — uses 4.4 + 4.5 to cover all four column kinds.
Budget ~120 lines. **Optional sub-task.**

**Commit-landable:** yes after 4.5; can be skipped if Layer 4 budget
is exhausted.

### Sub-task 4.7: Adjacency recovery from edge-codeword image (~120 lines)

```lean
theorem adj_recovery_from_edgeCodeword
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_nondeg : ∃ u v, adj₁ u v = true)
    (π : Equiv.Perm (Fin (dimPR m)))
    (h : ∀ c ∈ prEncode m adj₁, permuteCodeword π c ∈ prEncode m adj₂)
    (i j : Fin m) :
    adj₁ i j = adj₂ (extractVertexPermAsEquiv ... i)
                    (extractVertexPermAsEquiv ... j)
```

**Strategy:**
1. For `i = j`: both sides false (no self-loops in our graph model
   per `edgeCodeword`'s `(v = u ∨ v = w)` structure assuming u ≠ w
   in canonical edge enumeration). Discharge by `decide` or
   case-split.
2. For `i ≠ j`: identify the unique edge `e := edgeIndex i j _`.
   By 4.4, π maps `edgeCodeword m adj₁ e` to `edgeCodeword m adj₂
   (liftedEdgePerm σ e)`. The image's vertex-column support equals
   the source's vertex-column support permuted by σ, which means
   `adj₁ i j = true ↔ adj₂ (σ i) (σ j) = true`.

**Risk:** medium–high. The `i = j` and `i ≠ j` case-split needs
careful canonicalisation. Budget ~120 lines.

**Commit-landable:** yes after 4.4 (4.5–4.6 not strictly required).

### Sub-task 4.8: Empty-graph edge case (~80 lines)

```lean
theorem prEncode_reverse_empty_graph
    (m : ℕ) (adj₂ : Fin m → Fin m → Bool)
    (h_empty : ∀ u v, ¬ ((fun _ _ => false : Fin m → Fin m → Bool) u v))
      -- (this is `True` for the all-false adj₁ = empty graph)
    (π : Equiv.Perm (Fin (dimPR m)))
    (h : ∀ c ∈ prEncode m (fun _ _ => false),
         permuteCodeword π c ∈ prEncode m adj₂) :
    ∃ σ : Equiv.Perm (Fin m), ∀ i j,
      (fun _ _ => false : Fin m → Fin m → Bool) i j = adj₂ (σ i) (σ j)
```

**Strategy:** for the all-false adj₁, all "i j" cases of the conclusion
collapse to `false = adj₂ (σ i) (σ j)`. So we need σ such that
`adj₂ ∘ σ` is the all-false graph — i.e., `adj₂` itself must be the
all-false graph (because σ is bijective). Argue this via cardinality:
`prEncode_card` is the same for adj₁ and adj₂, so π preserves all
column-weight signatures, which forces adj₂ to also be all-false.
Then σ = identity works.

**Risk:** medium. Specialised proof for the degenerate case. ~80 lines.

**Commit-landable:** yes after 4.7.

### Sub-task 4.9: `prEncode_reverse` assembly (~50 lines)

```lean
theorem prEncode_reverse (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) :
    ArePermEquivalent (prEncode m adj₁) (prEncode m adj₂) →
    ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)
```

**Discharge:**
1. `obtain ⟨π, h⟩ := h_eqv`.
2. Case-split: does `adj₁` have any edges?
   * If yes (∃ u v, adj₁ u v): use 4.7 with σ = `extractVertexPermAsEquiv`.
   * If no: use 4.8 with σ = identity.

**Risk:** low. Pure assembly. ~50 lines.

**Commit-landable:** yes after 4.8. **Reverse direction complete.**

### Sub-task 4.10: Layer 4 audit-script + non-vacuity (~30 lines)

```lean
-- R-CE Layer 4
#print axioms extractVertexPerm
#print axioms extractVertexPermAsEquiv
#print axioms extractVertexPerm_spec
#print axioms extractEdgePerm
#print axioms extractEdgePerm_eq_liftedEdgePerm_extractVertexPerm
#print axioms extractMarkerPerm_within_block
#print axioms adj_recovery_from_edgeCodeword
#print axioms prEncode_reverse_empty_graph
#print axioms prEncode_reverse

-- Non-vacuity at m = 3 with K_3 ↔ K_3 (use forward direction to
-- construct the witness, then reverse-extract σ).
```

**Commit-landable:** end of Layer 4 milestone. **Reverse direction
complete; full Petrank–Roth iff is now achievable.**

## R-CE Layer 5 — Iff assembled (1 sub-task, ~150 lines, ~0.5 days)

**File:** `Orbcrypt/Hardness/PetrankRoth.lean`, late section.

### Sub-task 5.1: `prEncode_iff` (~50 lines)

```lean
theorem prEncode_iff (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) :
    (∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) ↔
    ArePermEquivalent (prEncode m adj₁) (prEncode m adj₂) := by
  refine ⟨prEncode_forward m adj₁ adj₂, prEncode_reverse m adj₁ adj₂⟩
```

**Risk:** none. Trivial assembly given Layers 2 and 4.

**Commit-landable:** yes.

## R-CE Layer 6 — Non-degeneracy field discharge (1 sub-task, ~30 lines)

### Sub-task 6.1: Non-degeneracy bridge (~30 lines)

```lean
theorem prEncode_codeSize_pos (m : ℕ) : 0 < codeSizePR m :=
  codeSizePR_pos m

theorem prEncode_card_eq (m : ℕ) (adj : Fin m → Fin m → Bool) :
    (prEncode m adj).card = codeSizePR m :=
  prEncode_card m adj
```

These are direct re-exports. **Commit-landable:** yes.

## R-CE Layer 7 — `GIReducesToCE` inhabitant (2 sub-tasks, ~80 lines)

### Sub-task 7.1: Headline theorem (~40 lines)

```lean
/-- **R-15 closure for GI ≤ CE: Petrank–Roth (1997) Karp-reduction
    inhabitant.**

    Closes the strengthened-Workstream-I `GIReducesToCE` Prop with a
    full bidirectional iff. The encoder is the Petrank–Roth (1997)
    transposed-incidence-matrix construction with 3 marker columns
    per edge, recast in Orbcrypt's Bool/Finset model with one
    additional sentinel codeword for `codeSize_pos` at `m ≤ 1`.

    See `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § O / R-15
    for the audit-plan reference and the post-Workstream-I status note. -/
theorem petrankRoth_isInhabitedKarpReduction : GIReducesToCE :=
  ⟨dimPR, codeSizePR, prEncode,
   fun m => prEncode_codeSize_pos m,
   fun m adj => prEncode_card_eq m adj,
   fun m adj₁ adj₂ => prEncode_iff m adj₁ adj₂⟩
```

**Commit-landable:** yes.

### Sub-task 7.2: Layer 5–7 audit-script entries + final non-vacuity (~40 lines)

```lean
-- R-CE Layers 5–7
#print axioms prEncode_iff
#print axioms prEncode_codeSize_pos
#print axioms prEncode_card_eq
#print axioms petrankRoth_isInhabitedKarpReduction

-- Headline non-vacuity: Petrank–Roth inhabits GIReducesToCE.
example : GIReducesToCE := petrankRoth_isInhabitedKarpReduction

-- Concrete forward + reverse round-trip at m = 3.
example (σ : Equiv.Perm (Fin 3)) (adj : Fin 3 → Fin 3 → Bool) :
    ∃ τ : Equiv.Perm (Fin 3), ∀ i j,
      adj i j = (fun i j => adj (σ.symm i) (σ.symm j)) (τ i) (τ j) := by
  have h := prEncode_forward 3 adj _ ⟨σ, fun i j => by simp⟩
  exact prEncode_reverse 3 _ _ h
```

**Commit-landable:** **End of R-CE workstream.** Patch version bump
`0.1.14 → 0.1.15`. Full documentation sweep (see § "R-CE
documentation surface" below).

## R-CE documentation surface

Updates required at end of R-CE landing:

* **`Orbcrypt/Hardness/CodeEquivalence.lean`** — module-docstring
  "Main results" line: add cross-reference to
  `Hardness/PetrankRoth.lean`'s `petrankRoth_isInhabitedKarpReduction`.
  Note: the strengthened Prop's research-scope note (lines 351–360 in
  current file) should be revised to "post-Workstream-R-CE: closed
  via Petrank–Roth, see `Hardness/PetrankRoth.lean`".

* **`Orbcrypt.lean`** — Vacuity map row for `GIReducesToCE` flips from
  "research-scope R-15" → "inhabited via
  `petrankRoth_isInhabitedKarpReduction` (`Hardness/PetrankRoth.lean`);
  R-15 closed for the GI → CE direction." Plus a new
  "Workstream R-CE Snapshot" section detailing the 38 sub-tasks across
  8 layers, citing `Petrank–Roth 1997` as the canonical reference.

* **`CLAUDE.md`** — single Workstream-R-CE entry in the Workstream
  history section, mirroring the post-audit Workstream-I entry pattern.

* **`docs/VERIFICATION_REPORT.md`** — Document-history entry with
  date, line-count metrics, axiom-clean confirmation, R-15 closure
  for GI → CE.

* **`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md`** — § O / R-15
  marked "closed for GI → CE direction; GI → TI tracked under R-15-TI
  in Workstream R-TI".

* **`lakefile.lean`** — `version := v!"0.1.14"` → `v!"0.1.15"`.

* **`scripts/audit_phase_16.lean`** — 26 new `#print axioms` entries
  across Layers 0–7; 4 non-vacuity `example` blocks. Section-header
  comment "R-CE: Petrank–Roth GI ≤ CE Karp reduction".

## R-CE risk register

| Risk | Severity | Mitigation |
|------|----------|------------|
| Layer 4.4 (τ = liftedEdgePerm σ) blows up to 600+ lines | High | Risk gate at end of week 4: if Layer 4.4 < 50% complete, switch to Option B (forward-only). |
| `Equiv.Perm` decomposition for marker-block freedom (4.5–4.6) too verbose | Medium | Sub-task 4.6 is optional; 4.5 alone suffices for the iff. |
| `edgeEndpoints` triangular-number arithmetic (0.3) takes longer than 80 lines | Medium | Brute-force `decide`-tested implementation first for `m ≤ 5`, then prove the general bijection. |
| `Finset.card_union_of_disjoint` chain in Layer 1.6 finicky | Low | Use explicit four-step decomposition with helper Disjoint lemmas. |
| Empty-graph case (4.8) is a separate proof | Low | Already accounted for in Layer 4 budget. |
| Compile time — combinatorial Lean over `Equiv.Perm (Fin n)` | Medium | Three-file split keeps each subfile ≤ 1500 lines. |
| Mathlib API drift (pinned commit `fa6418a8`) | Low | No drift during the project. New lemmas (e.g. `Fintype.card_subtype` variants) may need to be proven in-tree if not in pin; +200 lines reserve. |

## R-CE total budget

| Layer | Sub-tasks | Lines | Days |
|-------|-----------|-------|------|
| 0 | 5 | 250–350 | 1.5 |
| 1 | 7 | 400 | 2 |
| 2 | 10 | 600 | 3 |
| 3 | 6 | 400 | 3 |
| 4 | 10 | 800–1500 | 7–14 |
| 5 | 1 | 150 | 0.5 |
| 6 | 1 | 30 | 0.25 |
| 7 | 2 | 80 | 0.5 |
| Docs | — | 200 prose | 1 |
| **R-CE total (pre-audit)** | **42** | **2,910–3,710** | **18.75–25.75** (~4–6 weeks) |
| **R-CE total (post-audit, with R1+R2)** | **43** | **2,980–3,780** | **19–26** (~4–6 weeks) |

---

# Workstream R-TI: Grochow–Qiao 2021 (GI ≤ TI)

**Total estimate: 8,000–20,000 lines across 56 sub-tasks / 6 layers / 14–22 weeks.**

The user has authorised the multi-month research-grade Lean
formalization of the Grochow–Qiao reduction. This workstream is
substantially larger and riskier than R-CE; the rigidity argument
(Layer T5) is the single largest technical undertaking.

## R-TI module organisation

| File | Purpose | Target lines |
|------|---------|--------------|
| `docs/research/grochow_qiao_*.md` | Layer T0 paper synthesis (4 docs) | 450 markdown |
| `Orbcrypt/Hardness/GrochowQiao/PathAlgebra.lean` | Path algebra `F[Q_G] / J²`: quiver definition, basis, idempotents, structure constants | 2,500–5,500 |
| `Orbcrypt/Hardness/GrochowQiao/StructureTensor.lean` | 3-tensor encoding with distinguished padding; `isPathAlgebraSlot` discriminator | 1,200–2,200 |
| `Orbcrypt/Hardness/GrochowQiao/Forward.lean` | σ → GL³ triple construction via vertex-idempotent permutation | 1,500–3,500 |
| `Orbcrypt/Hardness/GrochowQiao/Reverse.lean` | Rigidity argument: padding-respect + idempotent-permutation extraction | 3,000–8,000 |
| `Orbcrypt/Hardness/GrochowQiao.lean` | Top-level encoder + iff + inhabitant | 800–2,000 |

**Field choice (post-Decision-GQ-C): `F := ℚ`.** The path-algebra
rigidity argument (Layer T5) requires similar matrices to be
conjugate via a GL element — a property that holds over fields of
characteristic zero (such as ℚ) but fails over finite fields due to
elementary-divisor invariants. The pre-audit plan's `F := ZMod 2`
choice is rejected by Decision GQ-C (see "R-TI strengthened design"
section below). `ℚ` retains decidability (`DecidableEq ℚ`) so the
iff conclusion is computationally meaningful at concrete graphs,
matches the published Grochow–Qiao reduction's field hypotheses, and
has full Mathlib API at the pinned commit.

**Encoder choice (post-Decision-GQ-A): radical-2 path algebra
`F[Q_G] / J²`.** Replaces the pre-audit plan's `F[A_G]`
(adjacency-algebra) choice. See Decision GQ-A below for the
soundness rationale (cospectral graphs).

**Dimension choice (post-Decision-GQ-B): `dimGQ m := m + m * m`
with distinguished padding.** Replaces the pre-audit plan's
`dimGQ m := m + 1` choice. See Decision GQ-B for the rigidity
rationale.

Files modified (documentation/audit-script only): `Hardness/TensorAction.lean`,
`Orbcrypt.lean`, `CLAUDE.md`, `docs/VERIFICATION_REPORT.md`,
`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md`, `lakefile.lean`,
`scripts/audit_phase_16.lean`.

## R-TI design overview

The Grochow–Qiao reduction encodes graph G's path-algebra structure
tensor as a 3-tensor `T_G ∈ F^{d×d×d}` whose GL³-isomorphism class
determines G's iso-class. Key components (all four pinned by the
post-audit Decisions GQ-A through GQ-D below):

* **Quiver `Q_G`:** vertex set `V = {0, …, m-1}`, arrows
  `α(u, v)` for each ordered pair `(u, v)` with `adj u v = true`.
  For undirected graphs, `Q_G` carries arrows in both directions.
* **Path algebra `F[Q_G] / J²`** (Decision GQ-A): the F-vector
  space spanned by length-zero paths `{e_v : v ∈ V}` (vertex
  idempotents) and length-one paths `{α(u, v) : adj u v = true}`
  (arrows), with multiplication as path composition truncated at
  length 2 (where `J = rad(F[Q_G])` is the Jacobson radical, the
  span of length ≥ 1 paths). Dimension = `m + |E_directed|`. This
  is non-commutative when `m ≥ 1` and **distinguishes vertex
  positions** via the primitive idempotents `{e_v}`, solving the
  cospectral-graph defect of the pre-audit `F[A_G]` choice.
* **Basis:** the explicit ordered basis `{e_0, …, e_{m-1}} ∪
  {α(u_1, v_1), α(u_2, v_2), …}` enumerated by
  lexicographic ordering on `(u, v)`. This is computable; no
  `Basis.mk`-style indirection is required.
* **Structure tensor** `T_G[i, j, k]`: structure constants under
  the path-algebra multiplication, satisfying `b_i · b_j = ∑_k
  T_G[i, j, k] b_k`. Over the chosen basis the constants are
  explicit (in `{0, 1}` for radical-2 truncation): `e_v · e_v =
  e_v` (idempotent law), `e_v · α(v, w) = α(v, w)` (left vertex
  action), `α(u, v) · e_v = α(u, v)` (right vertex action),
  `α(u, v) · α(v, w) = 0` (length-2 paths killed by quotient),
  zero otherwise.
* **Distinguished padding** (Decision GQ-B): pad to dimension
  `dimGQ m := m + m * m` by filling unused arrow slots (those
  where `adj u v = false`) with the *ambient `Mat(m + m², F)`
  structure constants*. The ambient pattern is graph-independent;
  the path-algebra pattern carries the graph information. Any
  GL³ preserving the encoded tensor must respect the
  path-algebra-slot vs ambient-slot partition (because the two
  patterns are distinguishable by their density of zero entries).
* **Field `F := ℚ`** (Decision GQ-C): the rigidity argument runs
  over a characteristic-zero field; ℚ is decidable, classical, and
  fully Mathlib-supported.
* **Forward direction (σ → GL³):** σ ∈ Aut(G) induces a permutation
  of the path-algebra basis (`e_v ↦ e_{σv}`, `α(u, v) ↦ α(σu, σv)`)
  plus the identity on the ambient padding. This basis permutation
  encodes as a triple of permutation matrices `(P_σ, P_σ, P_σ) ∈
  GL³`.
* **Reverse direction (rigidity):** any GL³ triple preserving
  `T_G` (i) maps path-algebra slots to path-algebra slots
  (distinguished-padding rigidity), (ii) restricts to a
  path-algebra automorphism on the path-algebra subblock, (iii)
  permutes the vertex idempotents by some bijection `σ : V → V`,
  (iv) extends uniquely to a vertex permutation σ ∈ Aut(G_1, G_2).

## R-TI risk profile

The single largest unknown is **Layer T5 (rigidity argument)**, which
on paper spans ~80 pages of Grochow–Qiao SIAM J. Comp. 2023.
Estimated 3,000–8,000 lines of Lean. The strengthened design (path
algebra + distinguished padding + ℚ) **reduces** the worst-case
ceiling: the path-algebra rigidity argument bypasses the Wedderburn
decomposition the pre-audit `F[A_G]` plan would have needed, and the
characteristic-zero field eliminates Smith-normal-form complications.
Worst-case post-strengthening estimate: 8,000 lines (was 12,000+).

**Mitigation hard gate:** at end of Sub-task T5.5 (week 22 with the
new Layer T0 lead-in), reassess. If T5 isn't 50% complete, switch to
**forward-only fallback**: ship T0–T3 as a partial closure of R-15
for GI → TI, with the rigidity argument tracked as **R-15-residual-
TI-reverse**. Forward-only landing is ~3,000 lines / 3 weeks on top
of T0–T3.

## R-TI strengthened design (post-audit, 2026-04-25)

The Grochow–Qiao soundness audit surfaced four under-specified spots
in the original plan that, on careful analysis, *forced* a design
pivot. This section makes each pivot **definitive**: every spot now
carries a single chosen approach with full type signatures, the
mathematical justification for the choice, and the concrete Lean
infrastructure required to discharge it. There are no remaining open
choices in R-TI's design surface.

### Decision GQ-A — Encoder algebra is the **path algebra `F[Q_G]`**

**Choice.** The R-TI encoder is the *structure tensor of the path
algebra of G's directed double*: viewed as a quiver `Q_G` with vertex
set `{0, …, m-1}` and an arrow `α(u,v)` for each ordered pair `(u, v)`
with `adj u v = true`, the path algebra `F[Q_G]` is the F-vector
space spanned by paths in `Q_G` (including length-zero paths `e_v`,
one per vertex), with composition as multiplication.

The pre-audit plan proposed `F[A_G]` (the *commutative* algebra
generated by the adjacency matrix). That choice is rejected because
of a **proven soundness defect**: cospectral non-isomorphic graphs
(e.g., the Saltire pair on 5 vertices) have isomorphic `F[A_G]` but
non-isomorphic Aut groups, so the iff conclusion fails in the reverse
direction. Path algebras solve this because:

* `F[Q_G]`'s **vertex idempotents** `{e_v : v ∈ V}` are individually
  recoverable from the algebra structure (each `e_v` is a primitive
  central idempotent of the vertex-block); a graph automorphism σ
  acts on `F[Q_G]` by permuting these idempotents in lockstep with σ
  on V. Distinct vertices ⇒ distinct idempotents ⇒ vertex positions
  are *distinguishable from algebra structure alone*.
* Any algebra automorphism of `F[Q_G]` permutes the primitive
  idempotents, hence induces a unique vertex permutation σ; conversely
  every σ ∈ Aut(G) lifts to an algebra iso. The algebra-Aut group
  equals the graph-Aut group **for every graph**, with no spectral
  restriction.
* Path algebras are well-supported in Mathlib via `Quiver` /
  `CategoryTheory.Quiver.Path` plus `Polynomial`-style basis
  enumeration; no novel category-theoretic infrastructure is needed.

**Lean type signature (Layer T1).**
```lean
inductive QuiverArrow (m : ℕ) (adj : Fin m → Fin m → Bool) where
  | id (v : Fin m)                             -- length-0 path e_v
  | edge (u v : Fin m) (h : adj u v = true)    -- length-1 path α(u,v)
  -- (longer paths are not basis elements; the Layer-T1 quotient
  --  identifies products with their compositions, kept finite via
  --  the radical truncation `path_length ≤ 2` discussed below)

def pathBasis (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Finset (QuiverArrow m adj) := ...

def pathAlgebraDim (m : ℕ) (adj : Fin m → Fin m → Bool) : ℕ :=
  m + (numDirectedEdges m adj)  -- m vertex idempotents + arrows
```

**Radical-truncation note.** The path algebra `F[Q_G]` is
infinite-dimensional in general (paths of any length). For the GI ≤
TI reduction we *do not* need the full path algebra; we use the
**radical-2 quotient** `F[Q_G] / J²` where `J = rad(F[Q_G])` is the
Jacobson radical (the span of length ≥ 1 paths). This quotient has
basis `{e_v} ∪ {α(u,v)}`, dimension `m + |E|`, is finite-dimensional,
and retains the vertex-distinguishability property. Grochow–Qiao
2021 § 4 (Proposition 4.3 in arXiv 1907.00309) uses precisely this
truncation.

**Effort impact, finalised.** Layer T1 (path algebra construction +
basis enumeration + structure constants) is budgeted at
**2,500–5,500 lines** post-pivot (was 1,500–3,500 for `F[A_G]`).
The +1,000–2,000 line delta is the price of (i) defining the
truncated path algebra explicitly (no off-the-shelf Mathlib
construction), (ii) discharging non-commutativity in associativity
and structure-constant computations, (iii) proving
vertex-idempotent uniqueness.

### Decision GQ-B — Tensor dimension is **`dimGQ m := m + numDirectedEdges_max m`** with **distinguished padding**

**Choice.** `dimGQ m := m + (m * m)` — sized to fit the maximum
possible path algebra dimension at vertex count m (every ordered
pair `(u, v)` could be an arrow). Concretely:

```lean
def dimGQ (m : ℕ) : ℕ := m + m * m
```

For graphs with fewer edges than the maximum, the unused arrow slots
are filled with **distinguished padding**: a fixed structure-tensor
pattern derived from the Mat(m+m², F) ambient algebra's
multiplication table on the corresponding rows/columns. Specifically:

```lean
def grochowQiaoEncode (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Tensor3 (dimGQ m) F :=
  fun i j k =>
    if isPathAlgebraSlot m adj i ∧ isPathAlgebraSlot m adj j ∧
       isPathAlgebraSlot m adj k then
      pathStructureConstant m adj i j k
    else
      ambientMatrixStructureConstant m i j k
```

The **distinguished-padding rigidity argument** (Layer T5.4) shows
that any GL³ preserving `grochowQiaoEncode m adj` must:

1. Map path-algebra-slot indices to path-algebra-slot indices
   (because the structure-constant pattern on path-algebra slots is
   distinct from the ambient-matrix pattern — the ambient pattern
   has *every* slot filled, while the path-algebra pattern has gaps
   where the graph has non-edges).
2. Restrict to a path-algebra automorphism on the path-algebra
   subblock and to an Mat(m+m², F)-automorphism on the padding
   subblock.

The first constraint **forces the GL³ to respect the path-algebra
substructure**, which is exactly the rigidity Layer T5 needs.

The pre-audit plan's `dimGQ m := m + 1` is rejected because (a) it
required variable dim or zero-padding-rigidity, both of which the
audit flagged; (b) the proposed fix `dimGQ m := m * m` lost
tightness without solving padding rigidity. The `m + m * m`
distinguished-padding choice has both: tight upper bound *and*
rigidity by construction.

**`isPathAlgebraSlot` definition.**
```lean
def isPathAlgebraSlot (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i : Fin (dimGQ m)) : Bool :=
  match Fin.toLayerKind m i with
  | .vertex _ => true                          -- always in path algebra
  | .arrow u v => adj u v                      -- in iff edge present
```

**Effort impact, finalised.** Layer T2 (structure tensor encoder
+ distinguished-padding rigidity helpers) is budgeted at
**1,200–2,200 lines** (was 800–1,800). The +400 line delta covers
the `isPathAlgebraSlot` infrastructure and the
ambient-vs-path-algebra discriminator lemmas.

### Decision GQ-C — Field is **`F := ℚ`** (rationals)

**Choice.** R-TI is formalised over `F := ℚ`. Mathlib's
`Mathlib.Data.Rat.Defs` + `Mathlib.LinearAlgebra.*` + `Mathlib.RingTheory.*`
provide a complete classical-field infrastructure: `Polynomial`,
`minpoly`, `Module.finrank`, `Algebra.adjoin`, `Subalgebra`,
`AlgEquiv`, plus `Matrix.IsAlgebraic` and the `CharZero` instance.

The pre-audit plan proposed `F := ZMod 2`. That choice is rejected
because:

* The path-algebra rigidity argument (Layer T5.4) uses the
  **density of conjugacy classes** in the GL action on the path
  algebra. Over finite fields the conjugacy-class structure is
  governed by *Smith normal form / elementary divisors*, which
  introduces extra invariants beyond similarity (i.e., similar
  matrices with the same characteristic polynomial may not be
  conjugate). The rigidity argument breaks.
* Over `ℚ` (characteristic 0, infinite, classical-field), similar
  matrices ARE conjugate (`Mathlib.LinearAlgebra.Matrix.Charpoly.Coeff`'s
  classical theory), so the rigidity argument is straight-line.
* `ℚ` is **decidable** (`DecidableEq ℚ`), so the iff conclusion is
  computationally meaningful. We do *not* need the algebraic closure;
  the path-algebra rigidity argument works directly over the rational
  base field because the path algebra's multiplicative structure is
  already integral (no eigenvalue computation required).
* The **Tensor3** type carries no field-specific assumptions, so the
  switch from `ZMod 2` to `ℚ` is local to the encoder + rigidity
  modules; downstream `AreTensorIsomorphic` / `GIReducesToTI` Props
  don't need refactor.

**Mathlib API used (catalogued before T1 begins).**
* `Polynomial ℚ`, `Polynomial.aeval`, `Polynomial.minpoly`
* `Subalgebra ℚ (Matrix (Fin n) (Fin n) ℚ)`,
  `Algebra.adjoin ℚ {…}`
* `Module.finrank ℚ`, `Module.Finite ℚ`, `Basis (Fin d) ℚ`
* `AlgEquiv`, `LinearMap.toMatrix`,
  `Matrix.GeneralLinearGroup ℚ`
* `Matrix.charpoly`, `Matrix.IsConj`,
  `Matrix.charpoly_conj`

All of these are present in Mathlib at the pinned commit
`fa6418a8` and have stable API.

**Effort impact, finalised.** Layers T4–T5 (linear-algebra
prerequisites + rigidity) net to **4,500–11,000 lines** (was
4,500–11,000 for `ZMod 2`; switching to `ℚ` is *neutral* in line
count because the Mathlib API is comparably mature in characteristic
0 and the rigidity argument simplifies in compensation for the
encoder-side complexity). The change is in *which* lemmas we cite,
not how many lines we write.

### Decision GQ-D — **Layer T0: Paper synthesis** lands as the first work week of R-TI

The "1–2 week paper-reading caveat" is now **Layer T0**, a planned
first layer of R-TI with concrete Lean/markdown deliverables that
land *before* T1 begins. This converts a scheduling caveat into a
budgeted activity with measurable exit criteria.

#### Sub-task T0.1: Path-algebra structure note (~80 lines markdown + 0 Lean)

**File:** `docs/research/grochow_qiao_path_algebra.md` (new). 1
page summarising:
1. The `Quiver` / `Path` definition of `F[Q_G]`.
2. The radical-2 truncation `F[Q_G] / J²` and its dimension `m + |E|`.
3. The vertex-idempotent uniqueness lemma (with citation: Auslander–
   Reiten–Smalø *Representation Theory of Artin Algebras* §III.2).
4. The Grochow–Qiao 2021 reference (arXiv 1907.00309 §4) for the
   path-algebra → 3-tensor encoding.

**Exit:** 1-page summary committed; reviewers (= self) confirm the
truncation is finite-dimensional and retains the vertex-idempotent
property.

#### Sub-task T0.2: Mathlib API audit (~120 lines markdown + 50 Lean stubs)

**Files:** `docs/research/grochow_qiao_mathlib_api.md` (new),
`Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean` (new, deleted at T1
landing).

Catalogue every Mathlib declaration referenced by Layers T1–T6,
with a 1-line `example` checking the declaration elaborates at the
expected type. Concretely:

```lean
-- _ApiSurvey.lean
example : ∀ (n : ℕ) (M : Matrix (Fin n) (Fin n) ℚ),
    Polynomial.minpoly ℚ M = Polynomial.minpoly ℚ M := fun _ _ => rfl
example : ∀ (n : ℕ), Module.Finite ℚ (Matrix (Fin n) (Fin n) ℚ) :=
  inferInstance
example (n : ℕ) (M : Matrix (Fin n) (Fin n) ℚ) :
    Subalgebra ℚ (Matrix (Fin n) (Fin n) ℚ) := Algebra.adjoin ℚ {M}
-- ... 30+ such declarations
```

**Exit:** every Mathlib API call planned for T1–T6 elaborates in
the survey file. Missing-API gaps are recorded with explicit
"in-tree replacement" budget allocations.

#### Sub-task T0.3: Distinguished-padding rigidity sketch (~200 lines markdown)

**File:** `docs/research/grochow_qiao_padding_rigidity.md` (new).
3-page proof sketch of the Layer T5.4 distinguished-padding rigidity
lemma — written in mathematical English with explicit
`F[Q_G] / J²`-vs-`Mat(m+m², ℚ)` invariants. Confirms the GL³
rigidity argument runs as designed without further refactor.

**Exit:** the padding rigidity argument has an English-prose proof
sketch that survives self-audit. Layer T5 implementation references
this document.

#### Sub-task T0.4: Pre-T1 reading log (~50 lines markdown)

**File:** `docs/research/grochow_qiao_reading_log.md` (new).
Bibliography + reading notes for Grochow–Qiao 2021/2023, with
explicit cross-references from each plan section to the corresponding
paper section.

**Exit:** every R-TI design choice (GQ-A, GQ-B, GQ-C) cites a
specific paper section as justification.

#### Layer T0 total

| Sub-task | Lines | Days |
|----------|-------|------|
| T0.1 path-algebra note | 80 markdown | 0.5 |
| T0.2 Mathlib API audit | 120 markdown + 50 Lean | 1 |
| T0.3 padding-rigidity sketch | 200 markdown | 1.5 |
| T0.4 reading log | 50 markdown | 0.5 |
| **T0 total** | **450 markdown + 50 Lean** | **3.5 days (~1 week)** |

**Layer T0 lands as a single commit** with all four documents and
the (transient) `_ApiSurvey.lean` file. Patch version unchanged
during T0; the first patch bump comes at end of Layer T1.

### Updated R-TI risk gates (post-strengthening)

The original T5.5 hard gate (week 18 + 4 weeks for T0, so **week
22**, 50% completion of rigidity argument) is unchanged. A new
**week-3 path-algebra basis gate** is added:

* End of week 3 (T0 + T1.1–T1.4 landed): confirm the path-algebra
  basis enumerates correctly at concrete graphs (`m = 3`, K_3, P_3,
  C_4) via `decide`. If basis enumeration fails or is non-canonical,
  the structure-constant computation in T1.6 cannot proceed.

**No further pivot is required.** Layer T0's deliverables make the
encoder choice, padding strategy, field choice, and rigidity argument
concrete *before* a single line of Layer-T1 Lean is written. Pivot
risk is now **bounded by T0 itself**: if T0.3 (padding-rigidity
sketch) fails self-audit, the plan is revised at T0 end, before
T1 sub-tasks consume budget.

**Post-strengthening R-TI estimate:** 12–22 weeks (was the pre-audit
14–22; the strengthened plan is *not slower* than the pre-audit
plan because T0's 1-week investment is offset by reduced T1 / T5
risk premiums and by eliminated late-stage pivot scenarios).

## R-TI Layer T1 — Path algebra `F[Q_G] / J²` (8 sub-tasks, ~2,500–5,500 lines, ~2–4 weeks)

**File:** `Orbcrypt/Hardness/GrochowQiao/PathAlgebra.lean`.
**Imports:** `Mathlib.Data.Rat.Defs`, `Mathlib.LinearAlgebra.Matrix.Basic`,
`Mathlib.LinearAlgebra.FiniteDimensional`, `Mathlib.Algebra.Algebra.Basic`,
`Mathlib.Algebra.Algebra.Subalgebra.Basic`, `Mathlib.Data.Finset.Sigma`.

**Field convention:** `F := ℚ` per Decision GQ-C. All algebraic
constructions in this layer are over ℚ.

### Sub-task T1.1: Quiver `Q_G` definition + arrow enumeration (~250 lines)

```lean
inductive QuiverArrow (m : ℕ) where
  | id (v : Fin m)
  | edge (u v : Fin m)
  deriving DecidableEq, Repr

def isPresentArrow (m : ℕ) (adj : Fin m → Fin m → Bool)
    (a : QuiverArrow m) : Bool :=
  match a with
  | .id _ => true
  | .edge u v => adj u v

def presentArrows (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Finset (QuiverArrow m) :=
  (Finset.univ.image QuiverArrow.id) ∪
  ((Finset.univ.product Finset.univ).filter
    (fun p => adj p.1 p.2)).image
    (fun p => QuiverArrow.edge p.1 p.2)
```

**Lemmas:**
* `presentArrows_card` — `(presentArrows m adj).card = m + |E_directed|`
  where `|E_directed| = (Finset.univ.filter (fun p : Fin m × Fin m =>
  adj p.1 p.2)).card`.
* `presentArrows_id_mem` — `QuiverArrow.id v ∈ presentArrows m adj`
  for every `v`.
* `presentArrows_edge_mem_iff` — `QuiverArrow.edge u v ∈
  presentArrows m adj ↔ adj u v = true`.

**Risk:** low. Pure inductive enumeration. ~250 lines for the
`Finset` plumbing + decidability instances.

### Sub-task T1.2: Path-algebra dimension `pathAlgebraDim` (~80 lines)

```lean
def pathAlgebraDim (m : ℕ) (adj : Fin m → Fin m → Bool) : ℕ :=
  (presentArrows m adj).card
```

**Lemmas:**
* `pathAlgebraDim_le` — `pathAlgebraDim m adj ≤ m + m * m` (vertex
  idempotents + at-most-m² arrows).
* `pathAlgebraDim_pos_of_pos_m` — `1 ≤ m → 1 ≤ pathAlgebraDim m adj`
  (at least one vertex idempotent).
* `pathAlgebraDim_apply` — explicit `m + |E|` decomposition.

**Risk:** low. ~80 lines, mostly `Finset.card_union_of_disjoint`.

### Sub-task T1.3: Path-algebra basis indexing equivalence (~250 lines)

**Goal:** establish a computable bijection between `Fin (pathAlgebraDim m adj)`
and `presentArrows m adj` (as a subtype). This is the basis-indexing
equivalence that downstream sub-tasks consume.

```lean
def pathArrowEquiv (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Fin (pathAlgebraDim m adj) ≃ {a : QuiverArrow m // a ∈ presentArrows m adj}
```

**Implementation:** use `Finset.equivFinOfCardEq` paired with
`Finset.attach` to convert the finset into a Fin-indexed family.
The equivalence is computable; `decide`-tested at `m ≤ 4`.

**Risk:** medium. Mathlib's `Finset.equivFin` API takes some
plumbing to thread through `Subtype`. Budget ~250 lines.

### Sub-task T1.4: Path-algebra multiplication table (~600 lines)

**Goal:** define multiplication on `QuiverArrow m` (truncated at
length 2, i.e., `α(u, v) · α(v, w) = 0` since the result is a
length-2 path which is killed by the radical-2 quotient).

```lean
def pathMul (m : ℕ) (a b : QuiverArrow m) : Option (QuiverArrow m) :=
  match a, b with
  | .id u, .id v       => if u = v then some (.id u) else none
  | .id u, .edge v w   => if u = v then some (.edge v w) else none
  | .edge u v, .id w   => if v = w then some (.edge u v) else none
  | .edge _ _, .edge _ _ => none  -- length-2 paths killed by J²
```

**Lemmas:**
* `pathMul_id_id` — `pathMul (.id u) (.id v) = if u = v then some (.id u) else none`.
* `pathMul_id_edge` — left-action of vertex idempotent on arrow.
* `pathMul_edge_id` — right-action of vertex idempotent on arrow.
* `pathMul_edge_edge_none` — `pathMul (.edge _ _) (.edge _ _) = none`.
* `pathMul_assoc` — associativity of `pathMul` (in the
  `Option`-monad-with-zero sense): for `a, b, c : QuiverArrow m`,
  `(pathMul a b).bind (fun ab => pathMul ab c) =
   (pathMul b c).bind (fun bc => pathMul a bc)`.
  Discharge: 4 × 4 × 4 = 64 case match, all reducing to either
  `none` or matching `if`-decompositions; mostly `decide` (or `rfl`
  after `simp`).

**Risk:** medium–high. Associativity case-split is tedious but
mechanical. Budget ~600 lines (8 lemmas × ~75 lines each, with
the associativity proof itself being ~250 lines).

### Sub-task T1.5: Structure-constants definition (~300 lines)

**Goal:** lift `pathMul` to a structure-constant function over
`Fin (pathAlgebraDim m adj)`.

```lean
def pathStructureConstant
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i j k : Fin (pathAlgebraDim m adj)) : ℚ :=
  let a := (pathArrowEquiv m adj i).val
  let b := (pathArrowEquiv m adj j).val
  let c := (pathArrowEquiv m adj k).val
  match pathMul m a b with
  | some d => if d = c then 1 else 0
  | none => 0
```

The `ℚ`-valued output uses `0` and `1` only (path multiplication
is set-valued in radical-2 quotient); this is the radical-2
truncated structure tensor.

**Risk:** medium. `Option`-to-`ℚ` extraction is straightforward;
the only subtlety is ensuring `pathArrowEquiv`'s subtype output
has its `Subtype.val` accessed correctly. ~300 lines including
the unfolding lemma `pathStructureConstant_apply`.

### Sub-task T1.6: Vertex-idempotent uniqueness (~400 lines)

**Goal:** prove the cryptographically essential property that
**vertex idempotents are recoverable from the algebra structure
alone**.

```lean
theorem pathAlgebra_idempotent_iff_vertex
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i : Fin (pathAlgebraDim m adj)) :
    (∀ j, pathStructureConstant m adj i i j =
          if (pathArrowEquiv m adj i).val =
             (pathArrowEquiv m adj j).val then 1 else 0) ↔
    ∃ v : Fin m, (pathArrowEquiv m adj i).val = QuiverArrow.id v
```

**Strategy:** an element `b_i` is idempotent (`b_i · b_i = b_i`)
iff its arrow representation is `QuiverArrow.id v` for some `v`.
This follows from the multiplication table: `id u · id u = id u`
(idempotent), `edge u v · edge u v = none = 0` (not idempotent),
all other diagonal products give `none`. Forward: case-split on
the arrow shape and rule out `edge` by the diagonal product
contradiction. Reverse: direct computation.

**Risk:** medium. The strategy is clear; the proof is ~400 lines
because the `pathArrowEquiv` indirection requires careful manual
case analysis.

**Why this matters:** Layer T5's rigidity argument (T5.1 → T5.4)
extracts a vertex permutation σ from a GL³ that preserves the
structure tensor. T1.6 is the lemma that lets the rigidity
argument identify vertex idempotents from the GL³ image; without
T1.6, the rigidity argument cannot start.

### Sub-task T1.7: Path-algebra associativity / unitality lemmas (~400 lines)

```lean
theorem pathStructureConstant_associative (m : ℕ) (adj : ...)
    (i j k l : Fin _) :
    ∑ p, pathStructureConstant m adj i j p *
         pathStructureConstant m adj p k l =
    ∑ p, pathStructureConstant m adj j k p *
         pathStructureConstant m adj i p l

theorem pathStructureConstant_unital (m : ℕ) (adj : ...) :
    -- the sum of vertex idempotents is the multiplicative identity
    ∀ i k, ∑ v : Fin m, pathStructureConstant m adj
                          (vertexIdempotentIndex m adj v) i k =
           if i = k then 1 else 0
```

**Discharge:** lift `pathMul_assoc` (T1.4) through the
`pathStructureConstant` unfolding via `Finset.sum`-pushing.
Unitality is the explicit formula
`(∑_v e_v) · b = b` for any `b ∈ F[Q_G] / J²`.

**Risk:** medium. ~400 lines combined.

### Sub-task T1.8: Layer T1 audit-script + non-vacuity (~80 lines)

```lean
#print axioms QuiverArrow
#print axioms presentArrows
#print axioms pathAlgebraDim
#print axioms pathArrowEquiv
#print axioms pathMul
#print axioms pathMul_assoc
#print axioms pathStructureConstant
#print axioms pathAlgebra_idempotent_iff_vertex
#print axioms pathStructureConstant_associative
#print axioms pathStructureConstant_unital

-- Non-vacuity at K_3 (3-vertex complete graph, 6 directed edges):
-- pathAlgebraDim = 3 + 6 = 9.
example : pathAlgebraDim 3 (fun i j => decide (i ≠ j)) = 9 := by
  decide

-- Non-vacuity at empty graph on 3 vertices: pathAlgebraDim = 3
-- (vertex idempotents only).
example : pathAlgebraDim 3 (fun _ _ => false) = 3 := by decide

-- Non-vacuity for vertex-idempotent characterisation:
-- the first 3 indices of pathArrowEquiv at K_3 correspond to
-- the vertex idempotents.
example : ∃ v : Fin 3, (pathArrowEquiv 3 (fun i j => decide (i ≠ j))
            ⟨0, by decide⟩).val = QuiverArrow.id v := by
  decide
```

**Commit-landable:** end of Layer T1 milestone. **Path algebra
foundation laid; vertex idempotents recoverable from algebra
structure alone.**

## R-TI Layer T2 — Structure tensor encoder with distinguished padding (7 sub-tasks, ~1,200–2,200 lines, ~1.5–2 weeks)

**File:** `Orbcrypt/Hardness/GrochowQiao/StructureTensor.lean`.
**Imports:** `Orbcrypt.Hardness.GrochowQiao.PathAlgebra`,
`Orbcrypt.Hardness.TensorAction`.

**Choices pinned (per Decisions GQ-A, GQ-B, GQ-C):**
* Encoder algebra: radical-2 path algebra `F[Q_G] / J²` (Layer T1).
* Tensor dimension: `dimGQ m := m + m * m` with distinguished padding.
* Field: `F := ℚ`.

### Sub-task T2.1: `dimGQ` + slot-kind taxonomy (~200 lines)

```lean
def dimGQ (m : ℕ) : ℕ := m + m * m

inductive SlotKind (m : ℕ) where
  | vertex (v : Fin m)
  | arrow (u v : Fin m)
  deriving DecidableEq, Repr

def slotEquiv (m : ℕ) : Fin (dimGQ m) ≃ SlotKind m
```

The `slotEquiv` indexes `dimGQ m`'s coordinates: vertex slots
`[0, m)`, arrow slots `[m, m + m * m)` enumerated lexicographically
by `(u, v)`.

**Lemmas:**
* `slotEquiv_vertex_apply`, `slotEquiv_arrow_apply` —
  computational evaluation.
* `dimGQ_pos_of_pos_m` — `1 ≤ m → 1 ≤ dimGQ m`.

**Risk:** low–medium. Standard `Fin (a + b)`-to-disjoint-union
equivalence, similar to the R-CE Layer-0.4 work. ~200 lines.

### Sub-task T2.2: `isPathAlgebraSlot` discriminator (~150 lines)

```lean
def isPathAlgebraSlot (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i : Fin (dimGQ m)) : Bool :=
  match slotEquiv m i with
  | .vertex _ => true
  | .arrow u v => adj u v

def slotToArrow (m : ℕ) (adj : Fin m → Fin m → Bool)
    (i : Fin (dimGQ m)) (h : isPathAlgebraSlot m adj i = true) :
    {a : QuiverArrow m // a ∈ presentArrows m adj}
```

`slotToArrow` is the bridge from `Fin (dimGQ m)` (T2's coordinate
type) to `presentArrows m adj` (T1's path-algebra basis indexing).
Defined by case-splitting on `slotEquiv` and using `h` to discharge
the membership obligation in the `arrow` case.

**Risk:** medium. The dependent-type chase across `slotEquiv` /
`pathArrowEquiv` requires careful elaboration. Budget ~150 lines.

### Sub-task T2.3: Encoder definition with distinguished padding (~300 lines)

```lean
def ambientMatrixStructureConstant (m : ℕ)
    (i j k : Fin (dimGQ m)) : ℚ :=
  -- Mat(dimGQ m, ℚ) structure constants on the standard basis.
  -- This pattern is graph-independent: every coordinate triple has
  -- a well-defined value computed from the matrix-multiplication law.
  -- Concretely: identifying `Fin (dimGQ m)` with rectangular indices
  -- (i = (a, b), j = (c, d), k = (e, f)), the constant is
  -- `if b = c ∧ a = e ∧ d = f then 1 else 0`.
  ...

def grochowQiaoEncode (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Tensor3 (dimGQ m) ℚ := fun i j k =>
  if isPathAlgebraSlot m adj i ∧
     isPathAlgebraSlot m adj j ∧
     isPathAlgebraSlot m adj k then
    -- Path-algebra slot: use T1's structure constants.
    pathStructureConstant m adj
      (pathArrowEquiv m adj |>.symm (slotToArrow m adj i (by ...)))
      ...
  else
    -- Padding slot: use ambient matrix structure constants.
    ambientMatrixStructureConstant m i j k
```

**Risk:** medium–high. The pattern-match between path-algebra slots
and ambient-matrix slots is intricate; `slotToArrow`'s membership
obligations require explicit `decide`-or-`omega` discharges. Budget
~300 lines.

**Why distinguished padding (not zero padding):** the audit
flagged that zero-padding leaves the GL³ unconstrained on the
padding subblock, which would let an adversarial GL³ map vertex
slots to padding slots and break the iff. Distinguished padding
uses the ambient-matrix multiplication table — a graph-independent
*non-zero* pattern — so the GL³ is forced to preserve the
"path-algebra-vs-ambient" partition by the structure-constant
density.

### Sub-task T2.4: Encoder non-zero on positive m (~80 lines)

```lean
theorem grochowQiaoEncode_nonzero_of_pos_dim (m : ℕ) (h_m : 1 ≤ m)
    (adj : Fin m → Fin m → Bool) :
    grochowQiaoEncode m adj ≠ (fun _ _ _ => 0)
```

**Discharge:** at `i = j = k = vertex 0` (the first vertex
idempotent slot), `isPathAlgebraSlot` is `true` and the structure
constant is `1` (idempotent law `e_0 · e_0 = e_0`). So
`grochowQiaoEncode m adj (vertex 0) (vertex 0) (vertex 0) = 1 ≠ 0`.

**Risk:** low. ~80 lines. Discharges the strengthened-Prop's
`encode_nonzero_of_pos_dim` field directly.

### Sub-task T2.5: Encoder evaluation lemmas (~250 lines)

```lean
@[simp] theorem grochowQiaoEncode_at_vertex_vertex_vertex
    (m : ℕ) (adj : ...) (u v w : Fin m) :
    grochowQiaoEncode m adj
      (slotEquiv m |>.symm (.vertex u))
      (slotEquiv m |>.symm (.vertex v))
      (slotEquiv m |>.symm (.vertex w)) =
    if u = v ∧ u = w then 1 else 0

@[simp] theorem grochowQiaoEncode_at_vertex_arrow_arrow
    (m : ℕ) (adj : ...)
    (h_present : adj u v = true) (...)
    (u v_a v_b w_a w_b : Fin m) : ...
-- ... (one lemma per slot-kind triple, ~10 lemmas total)
```

Each lemma reduces `grochowQiaoEncode` at a specific slot-kind
triple to either the path-algebra structure constant (when all
three slots are path-algebra) or the ambient-matrix constant.

**Risk:** medium. ~250 lines. Mostly mechanical case-splits.

### Sub-task T2.6: Padding-respect lemma (~150 lines)

```lean
theorem grochowQiaoEncode_padding_distinguishable
    (m : ℕ) (adj : Fin m → Fin m → Bool) (h_m : 1 ≤ m) :
    -- The set of (i, j, k) where grochowQiaoEncode is non-zero
    -- partitions into "all path-algebra slots" and "all padding
    -- slots" — there is no "mixed" non-zero entry.
    ∀ i j k, grochowQiaoEncode m adj i j k ≠ 0 →
      (isPathAlgebraSlot m adj i ∧
       isPathAlgebraSlot m adj j ∧
       isPathAlgebraSlot m adj k) ∨
      (¬ isPathAlgebraSlot m adj i ∧
       ¬ isPathAlgebraSlot m adj j ∧
       ¬ isPathAlgebraSlot m adj k)
```

This is the lemma the rigidity argument (Layer T5.4) consumes: any
GL³ preserving the encoder's non-zero pattern *must* preserve the
path-algebra-vs-padding partition.

**Risk:** medium. The proof is by direct case analysis on the
`if-then-else` in `grochowQiaoEncode`'s definition. ~150 lines.

### Sub-task T2.7: Layer T2 audit-script + non-vacuity (~70 lines)

```lean
#print axioms dimGQ
#print axioms slotEquiv
#print axioms SlotKind
#print axioms isPathAlgebraSlot
#print axioms slotToArrow
#print axioms grochowQiaoEncode
#print axioms grochowQiaoEncode_nonzero_of_pos_dim
#print axioms grochowQiaoEncode_padding_distinguishable

-- Non-vacuity at K_3: dimGQ 3 = 3 + 9 = 12.
example : dimGQ 3 = 12 := by decide

-- Non-vacuity: at K_3, the (vertex 0, vertex 0, vertex 0) slot
-- evaluates to 1 (idempotent law).
example : grochowQiaoEncode 3 (fun i j => decide (i ≠ j))
            (slotEquiv 3 |>.symm (.vertex 0))
            (slotEquiv 3 |>.symm (.vertex 0))
            (slotEquiv 3 |>.symm (.vertex 0)) = 1 := by
  decide
```

**Commit-landable:** end of Layer T2 milestone. **Encoder defined;
distinguished padding in place; ready for forward direction.**

## R-TI Layer T3 — Forward direction (8 sub-tasks, ~1,500–4,000 lines, ~1.5–3 weeks)

**File:** `Orbcrypt/Hardness/GrochowQiao/Forward.lean`.
**Imports:** `Orbcrypt.Hardness.GrochowQiao.StructureTensor`.

**Goal:** σ ∈ Aut(G) → GL³ triple `(P_σ, P_σ, P_σ) ∈ GL(dimGQ m, ℚ)³`
such that `(P_σ, P_σ, P_σ) • T_{G_1} = T_{G_2}` where G_2 is the
σ-image of G_1.

**Strategy (post-Decision-GQ-A):** σ acts on the path-algebra basis
by `e_v ↦ e_{σv}`, `α(u, v) ↦ α(σu, σv)`. On the ambient padding
slots σ acts in the corresponding `Mat(m + m², ℚ)` index pattern.
Both actions are encoded as the same permutation matrix `liftedSigma
σ : Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ`, applied identically
on all three tensor axes.

### Sub-task T3.1: σ-induced slot permutation (~250 lines)

```lean
def liftedSigmaSlot (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    SlotKind m → SlotKind m
  | .vertex v => .vertex (σ v)
  | .arrow u v => .arrow (σ u) (σ v)

def liftedSigma (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    Equiv.Perm (Fin (dimGQ m)) := by
  refine ⟨fun i => slotEquiv m |>.symm (liftedSigmaSlot m σ
                     (slotEquiv m i)),
          fun i => slotEquiv m |>.symm (liftedSigmaSlot m σ⁻¹
                     (slotEquiv m i)), ?_, ?_⟩
  · intro i; simp [liftedSigmaSlot]; cases slotEquiv m i <;> simp
  · intro i; simp [liftedSigmaSlot]; cases slotEquiv m i <;> simp
```

**Lemmas:**
* `liftedSigma_one : liftedSigma m 1 = 1`
* `liftedSigma_mul : liftedSigma m (σ * τ) = liftedSigma m σ * liftedSigma m τ`
* `liftedSigma_inv : liftedSigma m σ⁻¹ = (liftedSigma m σ)⁻¹`

**Risk:** medium. `Equiv.Perm` construction with a 2-case slot kind
is mechanical. Budget ~250 lines.

### Sub-task T3.2: Permutation matrix construction (~200 lines)

```lean
def permMatrixOfEquiv (m : ℕ) (π : Equiv.Perm (Fin (dimGQ m))) :
    Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ :=
  fun i j => if π i = j then 1 else 0

def liftedSigmaMatrix (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    Matrix (Fin (dimGQ m)) (Fin (dimGQ m)) ℚ :=
  permMatrixOfEquiv m (liftedSigma m σ)
```

**Lemmas:**
* `permMatrixOfEquiv_one`, `permMatrixOfEquiv_mul`,
  `permMatrixOfEquiv_inv` — group homomorphism from `Equiv.Perm`
  to permutation matrices.
* `liftedSigmaMatrix_apply` — explicit formula.

**Risk:** low–medium. Standard permutation-matrix theory; Mathlib's
`Equiv.Perm.toMatrix` may already provide this in an even more
convenient form. Budget ~200 lines (could be less with Mathlib reuse).

### Sub-task T3.3: Invertibility + GL embedding (~150 lines)

```lean
theorem liftedSigmaMatrix_invertible (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    IsUnit (liftedSigmaMatrix m σ) := by
  refine ⟨⟨liftedSigmaMatrix m σ, liftedSigmaMatrix m σ⁻¹, ?_, ?_⟩, rfl⟩
  · simp [liftedSigmaMatrix, ← permMatrixOfEquiv_mul, ← liftedSigma_mul,
          mul_inv_cancel]
  · simp [liftedSigmaMatrix, ← permMatrixOfEquiv_mul, ← liftedSigma_mul,
          inv_mul_cancel]

def liftedSigmaGL (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    GL (Fin (dimGQ m)) ℚ :=
  ⟨liftedSigmaMatrix m σ, liftedSigmaMatrix m σ⁻¹, ..., ...⟩
```

**Risk:** low. ~150 lines. Once `liftedSigma` is a group hom, GL
construction is direct.

### Sub-task T3.4: Path-structure-constant equivariance (~400 lines)

**The key Layer-T3 lemma.** Show that the path-algebra structure
constants are equivariant under σ-acting-on-vertices.

```lean
theorem pathStructureConstant_equivariant
    (m : ℕ) (σ : Equiv.Perm (Fin m))
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : ∀ i j, adj₁ i j = adj₂ (σ i) (σ j))
    (i j k : Fin (pathAlgebraDim m adj₁)) :
    pathStructureConstant m adj₁ i j k =
    pathStructureConstant m adj₂
      (transportArrowIndex σ i) (transportArrowIndex σ j) (transportArrowIndex σ k)
```

where `transportArrowIndex σ` maps `adj₁`-arrows to `adj₂`-arrows
via `σ` on endpoints. Discharge by case-splitting on the arrow
kinds and using `pathMul`'s explicit table + the equivariance
hypothesis `h`.

**Risk:** medium–high. The transport-of-indexing across distinct
graphs (`adj₁` vs `adj₂`) requires careful equiv chasing. Budget
~400 lines.

### Sub-task T3.5: GL³ triple construction (~150 lines)

```lean
def grochowQiaoForwardTriple (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    GL (Fin (dimGQ m)) ℚ ×
    GL (Fin (dimGQ m)) ℚ ×
    GL (Fin (dimGQ m)) ℚ :=
  (liftedSigmaGL m σ, liftedSigmaGL m σ, liftedSigmaGL m σ)
```

Three copies of `liftedSigmaGL`. The structure tensor under
multiplication respects basis transformations on all three indices;
for a basis permutation, the same matrix serves all three (this is
the **symmetric** GL³ action — `(P, P, P) • T = T'` rather than the
asymmetric `(P, Q, R) • T = T'` that Grochow–Qiao's full result uses).
The symmetric action suffices for graphs because the path algebra is
**unitary** (has a multiplicative identity, the sum of vertex
idempotents), and a unitary algebra's structure tensor is preserved
only by symmetric basis transformations.

**Risk:** low. ~150 lines.

### Sub-task T3.6: Forward action verification (~400 lines)

```lean
theorem grochowQiaoEncode_forward_action
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (σ : Equiv.Perm (Fin m))
    (h : ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) :
    let triple := grochowQiaoForwardTriple m σ
    triple • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂
```

**The Layer-T3 core lemma.** Argument:
1. Unfold `grochowQiaoEncode` on both sides at each `(i, j, k)`
   index triple.
2. Case-split on whether `(i, j, k)` are all path-algebra slots,
   all padding slots, or mixed (mixed: T2.6 padding-respect implies
   the encoder is 0 on both sides).
3. Path-algebra case: invoke `pathStructureConstant_equivariant`
   (T3.4).
4. Padding case: ambient-matrix structure constants are
   graph-independent, so both sides equal trivially.

**Risk:** medium–high. ~400 lines including the case-splits.

### Sub-task T3.7: Forward iff direction assembly (~80 lines)

```lean
theorem grochowQiaoEncode_forward (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h : ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) :
    AreTensorIsomorphic (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂)
```

**Risk:** low after T3.6. ~80 lines.

### Sub-task T3.8: Layer T3 audit-script + non-vacuity (~80 lines)

```lean
#print axioms liftedSigma
#print axioms liftedSigmaMatrix
#print axioms liftedSigmaGL
#print axioms pathStructureConstant_equivariant
#print axioms grochowQiaoForwardTriple
#print axioms grochowQiaoEncode_forward_action
#print axioms grochowQiaoEncode_forward

-- Non-vacuity at K_3 with σ = identity (forward action is a no-op).
example (adj : Fin 3 → Fin 3 → Bool) :
    AreTensorIsomorphic (grochowQiaoEncode 3 adj) (grochowQiaoEncode 3 adj) :=
  grochowQiaoEncode_forward 3 adj adj ⟨1, fun _ _ => by simp⟩
```

**Commit-landable:** end of Layer T3 milestone. **Forward direction
of GI ≤ TI complete.** This is the natural fallback (Option B for TI)
landing point if T5 stalls.

## R-TI Layer T4 — Linear-algebra prerequisites for rigidity (8 sub-tasks, ~1,500–3,000 lines, ~1.5–3 weeks)

**File:** `Orbcrypt/Hardness/GrochowQiao/Reverse.lean`, first half.
**Imports:** Layer T1 (`PathAlgebra.lean`), Layer T2 (`StructureTensor.lean`),
`Mathlib.LinearAlgebra.*`, `Mathlib.RingTheory.SimpleModule`,
`Mathlib.Algebra.Algebra.Subalgebra.*`. Field is `ℚ`.

This layer builds the linear-algebra machinery the rigidity argument
needs but Mathlib doesn't supply directly.

### Sub-task T4.1: GL³ action preserves the path-algebra-vs-padding partition (~250 lines)

```lean
theorem GL_triple_preserves_path_algebra_partition
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) (h_m : 1 ≤ m)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (h : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂) :
    ∃ π : Equiv.Perm (Fin (dimGQ m)),
      (∀ i, isPathAlgebraSlot m adj₁ i = isPathAlgebraSlot m adj₂ (π i))
      ∧ g corresponds to π on permutation-matrix layer
```

**Strategy:** apply T2.6 `grochowQiaoEncode_padding_distinguishable`
to the encoder before and after GL³ action. The non-zero pattern
of `grochowQiaoEncode m adj₁` is the disjoint union of "all three
indices in path-algebra slots" and "all three indices in padding
slots". The GL³ action is invertible, so it maps non-zero pattern
to non-zero pattern bijectively. Because the path-algebra and
padding patterns are *distinguishable* (different density), the GL³
must preserve the partition.

**Risk:** medium–high. ~250 lines.

### Sub-task T4.2: GL³ action restricts to path-algebra automorphism (~350 lines)

```lean
theorem GL_triple_yields_path_algebra_automorphism
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) (h_m : 1 ≤ m)
    (g : ...) (h : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂) :
    -- g restricted to the path-algebra subblock is an algebra
    -- automorphism F[Q_{adj₁}] / J² ≅ F[Q_{adj₂}] / J².
    ∃ φ : pathAlgebraQuotient m adj₁ ≃ₐ[ℚ] pathAlgebraQuotient m adj₂,
      ...
```

where `pathAlgebraQuotient m adj : Type` is the quotient
`F[Q_G] / J²` constructed in Layer T1 as a Mathlib `Algebra` — added
in T4.2 as a "wrapper" type to match the Layer-T1 structure
constants.

**Strategy:** structure-tensor preservation on the path-algebra
subblock = multiplication-table preservation = algebra automorphism.
The padding subblock contributes nothing to this restriction.

**Risk:** **high.** ~350 lines. One of the central technical lemmas
of Grochow–Qiao.

### Sub-task T4.3: Path-algebra automorphism characterisation (~400 lines)

```lean
theorem pathAlgebra_auto_characterisation
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (φ : pathAlgebraQuotient m adj₁ ≃ₐ[ℚ] pathAlgebraQuotient m adj₂) :
    -- φ permutes the vertex idempotents along some bijection σ : V_1 → V_2.
    ∃ σ : Fin m → Fin m, Function.Bijective σ ∧
      ∀ v, φ (vertexIdempotent m adj₁ v) =
           vertexIdempotent m adj₂ (σ v)
```

**Strategy:** the *vertex idempotents* `{e_v}` are the **primitive
idempotents** of the path algebra (each `e_v` is idempotent and not
a sum of two non-zero orthogonal idempotents). Any algebra
automorphism permutes primitive idempotents. T1.6
(`pathAlgebra_idempotent_iff_vertex`) characterises which elements
are idempotents, and Mathlib's `IsAtom` API on the lattice of
idempotents identifies the primitive ones. The induced σ is a
bijection because φ is.

**Why this is much simpler than the F[A_G] version:** the pre-audit
plan needed Skolem–Noether for `F[A_G]`'s commutative algebra
characterisation. Path algebras have **explicit primitive
idempotents** (the vertex idempotents themselves), so the
characterisation is a direct case-split on the structure-constant
table — no Skolem–Noether needed.

**Risk:** medium. ~400 lines (was 400 for F[A_G] but with much
higher Skolem–Noether risk; the path-algebra version trades
complexity for line count).

### Sub-task T4.4: σ-bijection extends to arrow-bijection (~250 lines)

```lean
theorem pathAlgebra_auto_arrow_bijection
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (φ : pathAlgebraQuotient m adj₁ ≃ₐ[ℚ] pathAlgebraQuotient m adj₂)
    (σ : Fin m → Fin m) (hσ : Function.Bijective σ)
    (h_idem : ∀ v, φ (vertexIdempotent m adj₁ v) =
                   vertexIdempotent m adj₂ (σ v)) :
    -- φ also maps each present arrow α(u, v) to a scalar multiple
    -- of α(σ u, σ v). Combined with h_idem, this fixes σ uniquely.
    ∀ u v (h : adj₁ u v = true),
      ∃ c : ℚˣ, φ (arrowElement m adj₁ u v h) =
                c • arrowElement m adj₂ (σ u) (σ v) (by ...)
```

**Strategy:** `e_u · α(u, v) · e_v = α(u, v)` (in the radical-2
quotient); φ is multiplicative, so `φ(α(u, v)) = e_{σu} · φ(α(u, v))
· e_{σv}`. The right-hand side is a scalar multiple of `α(σu, σv)`
in the path algebra (the only non-zero element with that left/right
idempotent action).

**Risk:** medium. ~250 lines.

### Sub-task T4.5: Adjacency-matrix conjugation lift (~250 lines)

Bridge from path-algebra automorphism to adjacency-matrix
permutation:

```lean
theorem adjacency_invariant_under_pathAlgebra_iso
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (σ : Fin m → Fin m) (hσ : Function.Bijective σ)
    (h_idem : ∀ v, ...) (h_arrow : ∀ u v h, ∃ c, ...) :
    ∀ u v, adj₁ u v = adj₂ (σ u) (σ v)
```

The arrow-bijection from T4.4 says: σ preserves the *presence*
of an arrow, i.e., `adj₁ u v = true ↔ adj₂ (σ u) (σ v) = true`.
This is the GI condition.

**Risk:** low–medium. ~250 lines (mostly bookkeeping after T4.4).

### Sub-task T4.6: Permutation-vs-general-GL on padding (~200 lines)

```lean
theorem GL_padding_action_uniquely_determined
    (m : ℕ) (g : ...) (h : ...) :
    -- g restricted to the padding subblock is uniquely determined
    -- by its restriction to the path-algebra subblock plus the
    -- ambient-matrix structure constants (which are graph-independent).
    ...
```

**Strategy:** the ambient-matrix structure constants completely
determine `Mat(m + m², ℚ)`'s multiplication; any GL³ preserving them
must be a triple of permutation matrices on the standard basis (this
is a classical fact about matrix-algebra GL-rigidity). Combined with
the path-algebra side, the GL³ on the entire tensor is a single
permutation matrix tripled.

**Risk:** medium. ~200 lines. Uses Mathlib's matrix-algebra theory.

### Sub-task T4.7: Layer T4 audit-script + non-vacuity (~80 lines)

```lean
#print axioms GL_triple_preserves_path_algebra_partition
#print axioms GL_triple_yields_path_algebra_automorphism
#print axioms pathAlgebra_auto_characterisation
#print axioms pathAlgebra_auto_arrow_bijection
#print axioms adjacency_invariant_under_pathAlgebra_iso
#print axioms GL_padding_action_uniquely_determined

-- Non-vacuity at K_3 + identity GL: each prerequisite holds
-- trivially when the tensor is fixed and σ = id.
example : ... := ...
```

### Sub-task T4.8: `pathAlgebraQuotient` Mathlib-Algebra wrapper (~150 lines)

```lean
def pathAlgebraQuotient (m : ℕ) (adj : Fin m → Fin m → Bool) : Type :=
  Fin (pathAlgebraDim m adj) → ℚ
-- (As a vector space; the algebra structure comes from
--  `pathStructureConstant` lifted via `Finset.sum`.)

instance : Algebra ℚ (pathAlgebraQuotient m adj) := ...
```

This sub-task produces the Mathlib `Algebra` instance that
T4.2-T4.4's algebra-automorphism statements consume. Lifted from
T1's structure-constant tensor via the standard "structure-constant
algebra" construction (Mathlib's `Algebra.ofModule` or hand-rolled).

**Risk:** medium. ~150 lines. Could expand to 250 if Mathlib's
structure-constant API needs glue.

**Commit-landable:** end of Layer T4 milestone. **Linear algebra
prerequisites in place; ready for the rigidity argument.**

## R-TI Layer T5 — Rigidity argument via path algebra (8 sub-tasks, ~2,500–6,000 lines, ~3–5 weeks)

**File:** `Orbcrypt/Hardness/GrochowQiao/Reverse.lean`, second half.
**The largest single layer in either workstream.**

**Goal:** prove `grochowQiaoEncode_reverse` — any tensor isomorphism
between `T_{G_1}` and `T_{G_2}` arises from a vertex permutation σ ∈
Aut(G_1, G_2).

**Strategy (post-Decision-GQ-A simplification):** the path-algebra
choice eliminates the spectral / minimal-polynomial chain that
plagued the pre-audit `F[A_G]` plan. The new chain is:

```
GL³ preserves tensor
  → (T4.1) GL³ preserves path-algebra-vs-padding partition
  → (T4.2) GL³ restricts to path-algebra automorphism φ
  → (T4.3) φ permutes vertex idempotents along a bijection σ
  → (T4.4) φ maps each present arrow α(u, v) to a scalar multiple
           of α(σu, σv)
  → (T4.5) σ preserves adjacency: adj₁ u v = adj₂ (σ u) (σ v)
  → (T5.x) Lift σ to Equiv.Perm (Fin m); discharge the iff conclusion
```

Compared to the pre-audit `F[A_G]` rigidity (which needed
Skolem–Noether, Smith normal form, and characteristic-2 spectral
analysis), the path-algebra rigidity is **straight-line algebra**.
The line-count savings are absorbed by Layer T1's larger encoder
construction; the *risk* savings are pure win.

### Sub-task T5.1: Compose T4.1–T4.5 into a single statement (~400 lines)

Combine the Layer-T4 prerequisites into a single composite theorem:

```lean
theorem GL_triple_yields_vertex_permutation
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) (h_m : 1 ≤ m)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (h : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂) :
    ∃ σ : Fin m → Fin m, Function.Bijective σ ∧
      ∀ u v, adj₁ u v = adj₂ (σ u) (σ v)
```

**Discharge:** apply T4.1 → T4.2 → T4.3 → T4.4 → T4.5 in sequence;
each step's conclusion feeds the next step's hypothesis directly.

**Risk:** medium. ~400 lines (mostly bookkeeping).

### Sub-task T5.2: Bijection → `Equiv.Perm` (~80 lines)

```lean
theorem bijective_finMap_to_equivPerm
    (m : ℕ) (σ : Fin m → Fin m) (hσ : Function.Bijective σ) :
    ∃ τ : Equiv.Perm (Fin m), ∀ v, τ v = σ v
```

**Discharge:** Mathlib's `Equiv.ofBijective` (or
`Equiv.Perm.ofBijective`). Direct application; ~80 lines including
the `simp`-friendly extensionality lemmas.

**Risk:** none.

### Sub-task T5.3: Empty-graph edge case (~150 lines)

```lean
theorem grochowQiaoEncode_reverse_empty_graph
    (m : ℕ) (adj₂ : Fin m → Fin m → Bool)
    (h : AreTensorIsomorphic (grochowQiaoEncode m (fun _ _ => false))
                              (grochowQiaoEncode m adj₂)) :
    ∃ σ : Equiv.Perm (Fin m), ∀ i j,
      (false : Bool) = adj₂ (σ i) (σ j)
```

**Discharge:** the empty graph has `pathAlgebraDim = m` (only vertex
idempotents, no arrows). The encoded tensor's non-zero pattern on
vertex slots fixes σ as the unique idempotent permutation; the
arrow slots are all in the padding subblock for adj₁ but
selectively path-algebra for adj₂. By T4.1
(`partition_preserved`), `adj₂` must also have all arrow slots in
padding — i.e., `adj₂` is also the empty graph. σ = identity
suffices.

**Risk:** medium. ~150 lines.

### Sub-task T5.4: Reverse direction assembly (~120 lines)

```lean
theorem grochowQiaoEncode_reverse (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) :
    AreTensorIsomorphic (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂) →
    ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)
```

**Discharge:**
1. Case `m = 0`: trivial (Fin 0 is empty, `Equiv.Perm (Fin 0) = 1`,
   conclusion is vacuous).
2. Case `m ≥ 1` with empty `adj₁`: T5.3.
3. Case `m ≥ 1` with non-empty `adj₁`: extract `g` from the tensor
   isomorphism, apply T5.1 to get σ, lift via T5.2.

**Risk:** low–medium. ~120 lines.

### Sub-task T5.5: Audit-script + non-vacuity (~80 lines)

Standard `#print axioms` block plus a non-vacuity round-trip:
forward direction at K_3 + identity σ produces a tensor
isomorphism; reverse direction extracts σ = identity.

```lean
example : ∃ σ : Equiv.Perm (Fin 3), ∀ i j,
    (fun i j => decide (i ≠ j)) i j =
    (fun i j => decide (i ≠ j)) (σ i) (σ j) := by
  apply grochowQiaoEncode_reverse
  exact grochowQiaoEncode_forward 3 _ _ ⟨1, fun _ _ => by simp⟩
```

### Sub-task T5.6–T5.8: Stretch goals (~700–1700 lines, optional)

These are kept as labelled-but-deferable sub-tasks so the layer can
land at the end of T5.5 if the overall budget tightens:

* **T5.6:** Strengthen the rigidity to **arbitrary GL³ triples**
  (asymmetric `(P, Q, R) • T = T'` instead of just `(P, P, P)`).
  The symmetric case suffices for graphs (the path algebra is
  unitary), but the asymmetric case matches Grochow–Qiao's full
  result. ~400 lines.
* **T5.7:** Multi-block optimization for the rigidity argument
  (pre-compute T4.1's partition-preservation per block to speed
  up `decide` evaluations on small graphs). ~300 lines.
* **T5.8:** Generalise from `F = ℚ` to `F` of characteristic 0
  arbitrary, packaged as `[Field F] [CharZero F]`. ~600 lines.

**Risk gate at T5.5 (week 22):** if T5.1–T5.5 aren't all landed by
end of week 22, ship the forward-only fallback (Option B for TI)
and track T5 as `R-15-residual-TI-reverse`. Stretch goals T5.6–T5.8
are deferred regardless.

**Commit-landable:** end of Layer T5 milestone. **Reverse direction
of GI ≤ TI complete.** Patch version still 0.1.15 → bumped to
0.1.16 only after Layer T6.

## R-TI Layer T6 — Iff + non-degeneracy + inhabitant (4 sub-tasks, ~300–800 lines, ~0.5 weeks)

**File:** `Orbcrypt/Hardness/GrochowQiao.lean`.

### Sub-task T6.1: Iff assembly (~80 lines)

```lean
theorem grochowQiaoEncode_iff (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool) :
    (∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) ↔
    AreTensorIsomorphic (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂) :=
  ⟨grochowQiaoEncode_forward m adj₁ adj₂, grochowQiaoEncode_reverse m adj₁ adj₂⟩
```

### Sub-task T6.2: Non-degeneracy field discharge (~30 lines)

Direct re-export of T2.3. `grochowQiaoEncode_nonzero_of_pos_dim`
discharges the strengthened-Prop's `encode_nonzero_of_pos_dim` field.

### Sub-task T6.3: `GIReducesToTI` inhabitant (~50 lines)

```lean
theorem grochowQiao_isInhabitedKarpReduction :
    @GIReducesToTI ℚ _ :=
  ⟨dimGQ, grochowQiaoEncode,
   grochowQiaoEncode_nonzero_of_pos_dim,
   grochowQiaoEncode_iff⟩
```

### Sub-task T6.4: Layer T6 audit-script + final non-vacuity (~50 lines)

```lean
#print axioms grochowQiaoEncode_iff
#print axioms grochowQiao_isInhabitedKarpReduction

example : @GIReducesToTI ℚ _ := grochowQiao_isInhabitedKarpReduction
```

**Commit-landable:** **End of R-TI workstream.** Patch version bump
`0.1.15 → 0.1.16`.

## R-TI documentation surface

Mirrors R-CE's pattern: update Vacuity map row for `GIReducesToTI`,
add Workstream R-TI snapshot section in `Orbcrypt.lean`, add R-TI
entries in CLAUDE.md and VERIFICATION_REPORT.md.

## R-TI total budget (post-strengthening)

| Layer | Sub-tasks | Lines | Days |
|-------|-----------|-------|------|
| T0 (paper synthesis) | 4 | 50 Lean + 450 markdown | 3.5 |
| T1 (path algebra) | 8 | 2,500–5,500 | 10–18 |
| T2 (structure tensor + padding) | 7 | 1,200–2,200 | 7–10 |
| T3 (forward direction) | 8 | 1,500–4,000 | 8–15 |
| T4 (linear-algebra prerequisites) | 8 | 1,500–3,000 | 8–15 |
| T5 (rigidity, mandatory T5.1–T5.5) | 5 | 800–1,800 | 8–13 |
| T5 stretch (T5.6–T5.8, optional) | 3 | 700–1,700 | 5–10 |
| T6 (iff + inhabitant) | 4 | 300–800 | 2–3 |
| Docs | — | 200 prose | 1 |
| **R-TI total (mandatory)** | **44** | **8,050–17,500** | **47–78 days** (~10–17 weeks) |
| **R-TI total (with stretch)** | **47** | **8,750–19,200** | **52–88 days** (~11–19 weeks) |

The post-strengthening total is **lower** than the pre-audit
estimate (8,400–20,800) at the upper bound because:
1. The path-algebra rigidity (T4 + T5) is straight-line algebra
   instead of needing Skolem–Noether (saves ~1,500 lines).
2. The characteristic-zero field (ℚ) eliminates Smith-normal-form
   reasoning (saves ~800 lines).
3. The distinguished-padding rigidity argument is direct
   (no spectral-eigenvalue chain; saves ~1,200 lines).

Layer T1's larger budget (2,500–5,500 vs pre-audit 1,500–3,500)
absorbs the path-algebra construction overhead but is more than
compensated by T4/T5 simplifications.

---

# Cross-cutting: chain integration (post-R-CE + post-R-TI)

After both R-CE and R-TI land, integrate with the per-encoding
probabilistic Props in `Hardness/Reductions.lean`.

## Sub-task X.1: PetrankRoth-derived CE → GI Prop discharge (~150 lines)

```lean
theorem petrankRoth_dischargesConcreteCEOIAImpliesConcreteGIOIA :
    ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding
      (m := dimPR _) (k := _) prDecode εC εG
```

Where `prDecode : Finset (Fin (dimPR m) → Bool) → Fin m → Fin m → Bool`
recovers the adjacency matrix from the encoded code. Uses the
forward-direction iff to translate CE-equivalence to GI.

**Risk:** medium. ~150 lines.

## Sub-task X.2: GrochowQiao-derived Tensor → CE Prop discharge (~150 lines)

```lean
theorem grochowQiao_dischargesConcreteTensorOIAImpliesConcreteCEOIA :
    ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding S enc εT εC
```

Composes Grochow–Qiao + Petrank–Roth: tensor → graph → code. ~150 lines.

## Sub-task X.3: Full ConcreteHardnessChain inhabitant at concrete ε (~100 lines)

```lean
def concreteChainAtPetrankRothGrochowQiao (scheme : ...) (ε : ℝ) :
    ConcreteHardnessChain scheme ℚ S _ ε
```

Assembles a chain inhabitant at a concrete ε < 1 for the first time.
Field is `ℚ` per Decision GQ-C; the surrogate `S : SurrogateTensor ℚ`
is supplied by Grochow–Qiao's `grochowQiao_isInhabitedKarpReduction`
witness.

**Risk:** low after X.1 + X.2. ~100 lines.

## Sub-task X.4: Chain audit-script + non-vacuity (~50 lines)

**Commit-landable:** **End of cross-cutting integration.** Patch
version bump `0.1.16 → 0.1.17`.

---

# Verification plan (cross-workstream)

## After each sub-task

1. `lake build` for the touched module — must succeed with zero
   warnings, zero errors.
2. `lake env lean scripts/audit_phase_16.lean` — every new
   `#print axioms` line must return either "does not depend on any
   axioms" or `[propext, Classical.choice, Quot.sound]`. Zero
   `sorryAx`. Zero custom axioms.
3. Local sanity `decide`-discharged regression test in the audit
   script for the new content (when applicable).
4. Commit with descriptive message; push to branch.

## After each layer

1. Full `lake build` — zero warnings, zero errors.
2. `audit_phase_16.lean` exits 0; tally of new entries documented.
3. All five legacy per-workstream audit scripts (`audit_b/c/d/e_workstream.lean`,
   `audit_print_axioms.lean`) continue to elaborate cleanly.
4. CLAUDE.md "Workstream R-CE/R-TI in progress" status block updated.

## After each workstream landing (R-CE, then R-TI)

1. **Build clean across the whole project** (3,000+ jobs).
2. **All non-vacuity examples elaborate.** Forward, reverse, full
   iff, GIReducesToCE/TI inhabitant, plus negative-pressure regression
   exercising at least one non-isomorphic graph pair at small `m`.
3. **Documentation sweep complete.** Vacuity map updated, Workstream
   snapshot added, CLAUDE.md history entry added,
   docs/VERIFICATION_REPORT.md history entry added.
4. **Patch version bump.** `lakefile.lean` updated.
5. **Commit, push, await CI.**

## After cross-cutting integration

1. The full `ConcreteHardnessChain` is **inhabited at a concrete ε <
   1** for the first time in the project's history.
2. The headline theorems
   `concrete_hardness_chain_implies_1cpa_advantage_bound` and
   `concrete_kem_hardness_chain_implies_kem_advantage_bound` have
   *non-vacuity instantiations at ε < 1* alongside the existing
   `tight_one_exists` ε = 1 witnesses.
3. Patch version bump `0.1.16 → 0.1.17`.

# Execution order (week-by-week, post-strengthening)

| Week | Workstream | Layers | Milestones |
|------|-----------|--------|------------|
| 1 | R-CE | Layer 0 | BitLayout helpers complete |
| 2 | R-CE | Layers 1, 2 | Encoder + forward direction complete |
| 3 | R-CE | Layer 3 | Column-weight invariant complete |
| 4 | R-CE | Layer 4.1–4.4 | Vertex/edge perm extraction; **risk gate at end of week** |
| 5 | R-CE | Layer 4.5–4.9 | Reverse direction complete |
| 6 | R-CE | Layers 5, 6, 7 + docs | **R-CE landing**, version 0.1.15 |
| 7 | R-TI | Layer T0 | Paper synthesis (Decisions GQ-A–GQ-D documents) |
| 8–11 | R-TI | Layer T1 | Path algebra + basis + structure constants; **week-9 path-algebra basis gate** |
| 12–13 | R-TI | Layer T2 | Structure tensor + distinguished padding |
| 14–16 | R-TI | Layer T3 | Forward direction (GI ≤ TI) |
| 17–19 | R-TI | Layer T4 | Linear-algebra prerequisites (path-algebra automorphism) |
| 20–22 | R-TI | Layer T5.1–T5.5 | Rigidity argument; **risk gate at end of week 22** |
| 23 | R-TI | Layer T6 + docs | **R-TI landing**, version 0.1.16 |
| 24 | Chain | X.1–X.4 + docs | **Chain integration**, version 0.1.17 |
| 25–26 | R-TI (optional) | Stretch T5.6–T5.8 | Asymmetric GL³, multi-block opt, char-0 generality |

**Total horizon: 24 weeks (6 months) mandatory, 26 weeks (6.5
months) with stretch goals.** R-TI is one week shorter than the
pre-strengthening estimate because the path-algebra rigidity
argument (T4 + T5.1–T5.5) is more compact than the F[A_G]
spectral-eigenvalue chain it replaces.

# Cross-cutting risk register

| Risk | Workstream | Layer | Severity | Mitigation |
|------|-----------|-------|----------|------------|
| Petrank–Roth marker-forcing reverse direction (4.4) blows up to 600+ lines | R-CE | 4.4 | High | Risk gate at end of week 4; switch to forward-only Option B |
| Path-algebra basis enumeration (T1.3) doesn't elaborate at concrete graphs | R-TI | T1.3 | Medium | Week-9 gate: `decide`-test at `m ∈ {0, 1, 2, 3, 4}`; if it fails, fall back to `Mat(m + m², ℚ)` ambient basis (loses tightness, +200 lines) |
| `pathMul_assoc` (T1.4) 64-case split takes >600 lines | R-TI | T1.4 | Medium | Pre-budget 250 lines for the proof; if it overruns, factor into per-arrow-shape lemmas |
| Distinguished-padding rigidity (T4.1) doesn't discharge cleanly | R-TI | T4.1 | Medium | T0.3 paper-synthesis sketch reviews this proof in advance; if it fails, fall back to zero-padding + variable-dim (Decision GQ-B Option 1, breaks Prop signature, requires Prop refactor) |
| Path-algebra automorphism characterisation (T4.3) needs Mathlib's `IsAtom` API | R-TI | T4.3 | Low–Medium | T0.2 Mathlib-API audit verifies `IsAtom` API is present at pinned commit; if not, hand-roll the primitive-idempotent lemma (~200 extra lines) |
| Grochow–Qiao rigidity (T5) is the largest Lean step in either workstream | R-TI | T5 | High | Risk gate at end of week 22 (T5.5); switch to forward-only Option B for TI |
| Compile time of combinatorial Lean over `Equiv.Perm (Fin n)` | R-CE | 4 | Medium | Three-file split keeps subfiles ≤ 1500 lines |
| Compile time of `Tensor3` operations over `ℚ` | R-TI | T2–T5 | Medium | Five-file split for R-TI; `decide` only at `m ≤ 4` |
| Mathlib API drift on pinned commit `fa6418a8` | Both | All | Low | T0.2 verifies API presence before T1; +200 lines reserve per workstream for missing-lemma in-tree proofs |
| Documentation discipline drift (7+ files per landing) | Both | Docs | Medium | CLAUDE.md "Documentation rules" checklist enforced at each landing |
| Triangular-number arithmetic for edge enumeration (R-CE 0.3) | R-CE | 0.3 | Medium | Brute-force `decide`-tested for `m ≤ 5` first |
| `Finset.card_union_of_disjoint` chain finickiness (R-CE 1.6) | R-CE | 1.6 | Low | Explicit four-step decomposition |
| `Equiv.ext` / `Equiv.Perm.coe_mul` simp confusion (R-CE 2) | R-CE | 2 | Low | Heavy `simp` discipline + small-m sanity tests |
| Empty-graph degenerate case (R-CE 4.8) | R-CE | 4.8 | Low | Already accounted for in Layer 4 budget |

# Fallback strategies (if risk gates trigger)

**R-CE risk gate triggers at week 4 (Sub-task 4.4 < 50% complete):**

* Switch to **Option B (forward-only)**. Layers 0–2 are already
  landable as a real strengthening: `prEncode_forward` discharges
  the easy direction of the iff at the encoder level. Define a
  weaker Prop `GIReducesToCE_forward : ∃ encoder, ∀ adj₁ adj₂,
  AutPredicate adj₁ adj₂ → ArePermEquivalent (encoder adj₁) (encoder
  adj₂)` and inhabit it with `prEncode_forward`. Keep
  `petrankRoth_isInhabitedKarpReduction` deferred. Track Layers 3–7
  as **R-15-residual-CE-reverse**.
* Total forward-only landing: ~1,500 lines / 1.5–2 weeks. Patch
  version `0.1.14 → 0.1.14a` (or distinct minor identifier per
  CLAUDE.md's versioning convention).

**R-TI risk gate triggers at week 22 (Sub-task T5.5 < 50% complete):**

* Switch to **Option B (forward-only)** for TI. Layers T0–T3 land
  as a real strengthening of `GIReducesToTI`'s forward direction.
  Define `GIReducesToTI_forward` and inhabit with
  `grochowQiaoEncode_forward`. Track Layers T4–T6 as **R-15-residual-
  TI-reverse**.
* Total forward-only landing: ~3,000 lines / 3 weeks added on top
  of Layers T0–T3 (which landed in weeks 7–16). Patch version
  `0.1.15 → 0.1.15a`.

**R-TI week-9 path-algebra basis gate triggers (T1.3 doesn't elaborate at `m ≤ 4`):**

* Fall back to ambient `Mat(m + m², ℚ)` basis (Decision GQ-B
  Option 3 from the strengthened-design section). The
  characterisation lemmas in T4.3 still apply (the path algebra is
  a sub-algebra of `Mat(m + m², ℚ)`); only the basis selection
  changes. Net effect: +200 lines on T1, identical conclusion.
* No version-bump change required.

**Combined catastrophic risk gate:** if both R-CE Layer 4 and R-TI
Layer T5 stall, ship forward-only versions of both. The honest
posture for this case: "R-15 closed for the forward direction of
both reductions; reverse directions tracked as research-scope
follow-ups." This is **strictly more substantive** than the
post-Workstream-I baseline (which had no Karp-reduction inhabitants
of any kind).

# What this plan does NOT cover

* **Polynomial-time complexity bounds.** The strengthened Props don't
  require the encoder to be polynomial-time; they only require the
  iff. Polynomial-time bounds would be a separate audit-plan item
  (call it R-15-poly).
* **The CFI graph gadget itself.** CFI is not the right canonical
  construction (clarified Phase 3). If a future workstream wants CFI
  as a hardness-amplification gadget feeding into Petrank–Roth,
  that's a separate project.
* **Asymmetric/directed graph variants.** Petrank–Roth and
  Grochow–Qiao both work for directed graphs with minor changes;
  this plan targets the symmetric (undirected) case via the
  `Fin m → Fin m → Bool` model (which is general enough to encode
  both, but the iff equivalence we prove is for the standard
  σ-on-vertices action). Asymmetric versions are out of scope.
* **General field versions.** We fix `F := ℚ` per Decision GQ-C (R-TI
  rigidity argument is straight-line over characteristic-zero
  fields). Generalisation to arbitrary characteristic-zero fields
  `[Field F] [CharZero F]` is tracked as stretch goal T5.8;
  generalisation to finite fields is genuine research scope (Smith
  normal form / Wedderburn decomposition required) and out of scope
  for v1.0.
* **Per-workstream audit scripts** (`audit_b/c/d/e_workstream.lean`).
  These remain unchanged; the consolidated `audit_phase_16.lean` is
  the one that gets new R-15 entries.
* **Probabilistic chain reuse beyond the three `*_viaEncoding`
  Props.** Cross-cutting integration X.1–X.3 is in scope, but
  further chain refinements (e.g., proving ε < 1 strictly tight
  bounds via TV-distance arguments on the encoded distributions)
  is out of scope.

# Overall plan summary

* **Scope:** full bidirectional Petrank–Roth (R-CE) + full
  Grochow–Qiao (R-TI), with chain integration, per the user's Phase
  3 decisions and post-audit Decisions GQ-A through GQ-D.
* **Total deliverable (mandatory):** **11,230–21,780 lines of Lean
  across 91 sub-tasks / 15 layers (including R-TI Layer T0
  paper-synthesis) / 3 workstreams (R-CE, R-TI, chain integration).**
* **Total deliverable (with stretch):** **11,930–23,480 lines /
  94 sub-tasks** if R-TI stretch goals T5.6–T5.8 land.
* **Total horizon:** **16–24 weeks (4–6 months)** mandatory;
  **17–26 weeks (4.5–6.5 months)** with stretch.
* **Commit cadence:** every sub-task lands as its own commit; every
  layer ends with a milestone commit; each of the three workstreams
  ends with a patch-version bump and full documentation sweep.
* **Risk gates:** two hard gates (R-CE end-of-week-4 on sub-task
  4.4; R-TI end-of-week-22 on sub-task T5.5, post-T0) plus a new
  R-TI end-of-week-3 gate on path-algebra basis enumeration. All
  gates have explicit forward-only fallbacks.
* **Documentation discipline:** CLAUDE.md, Orbcrypt.lean,
  VERIFICATION_REPORT.md, audit-plan files, lakefile.lean,
  audit-script all updated at each landing.
* **Honest scope disclosure:** if either risk gate triggers, the
  forward-only landing is documented as "R-15 closure (forward
  direction)" with the reverse direction tracked as research-scope
  residual.
* **Post-audit strengthening posture:** every audit finding has been
  converted into a definitive design decision (R-CE Refinements R1–R4;
  R-TI Decisions GQ-A through GQ-D) rather than left as a deferred
  caveat. The plan is *more* concrete, not less, after the audit.

# Audit summary (2026-04-25, post-strengthening)

Two parallel audits ran on this plan; outcomes:

* **Petrank–Roth (R-CE) audit:** ✅ **completed.** Returned 6
  findings (3 confirmed from prompt + 3 new findings F/G/H). All
  classified "no soundness bug; plan needs strengthening".
  Integrated as Refinements R1–R4 (cardinality-forced surjectivity
  bridge, isolated-vertex handling, restaged 4.4 proof,
  canonicalisation pinning). **R-CE post-audit budget: 2,980–3,780
  lines / 4–6 weeks.**

* **Grochow–Qiao (R-TI) audit:** ⚙️ **substituted with self-audit
  + plan strengthening.** The agent-driven audit timed out, so a
  self-audit was conducted in its place. The four design points
  flagged (algebra choice, padding strategy, field choice,
  pre-implementation paper review) have all been **converted from
  caveats into definitive design decisions** (Decisions GQ-A
  through GQ-D, see "R-TI strengthened design" section). Each
  decision is fully specified with type signatures, mathematical
  justification, and downstream Layer-T1–T6 specs updated to match.
  **R-TI post-strengthening budget: 8,050–17,500 lines /
  10–17 weeks (mandatory) or 8,750–19,200 lines / 11–19 weeks
  (with stretch goals T5.6–T5.8).**

  Key strengthening summary:
  * **Decision GQ-A:** encoder = radical-2 path algebra
    `F[Q_G] / J²` (replaces `F[A_G]` to fix the cospectral-graph
    soundness defect).
  * **Decision GQ-B:** dimension = `m + m * m` with distinguished
    padding (replaces `m + 1` zero-padding to fix the padding-
    rigidity defect).
  * **Decision GQ-C:** field = `ℚ` (replaces `ZMod 2` to enable
    classical rigidity arguments).
  * **Decision GQ-D:** Layer T0 paper-synthesis is a planned 1-week
    activity with concrete deliverables (replaces the vague
    "1–2 week pre-implementation review" caveat).

## R-TI Layer T0 deliverables (post-strengthening)

The pre-T1 paper-reading activity is now Layer T0 with four
explicit deliverables:

1. `docs/research/grochow_qiao_path_algebra.md` — 1-page
   summary of `F[Q_G] / J²` and vertex-idempotent uniqueness.
2. `docs/research/grochow_qiao_mathlib_api.md` +
   `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean` (transient) —
   API-surface check that every Mathlib decl T1–T6 cites
   elaborates as expected.
3. `docs/research/grochow_qiao_padding_rigidity.md` — 3-page
   English-prose proof sketch of T5.4 distinguished-padding
   rigidity.
4. `docs/research/grochow_qiao_reading_log.md` — Bibliography +
   per-section paper-citation cross-reference.

Layer T0 is **part of the R-TI budget** (3.5 days, ~1 week),
not an external prerequisite.

## Updated combined budget (post-strengthening)

| Workstream | Pre-audit | Post-audit (post-strengthening) | Δ |
|-----------|----------|------------------------------|---|
| R-CE (Petrank–Roth) | 2,910–3,710 / 4–6 weeks | 2,980–3,780 / 4–6 weeks | +70 lines |
| R-TI Layer T0 (paper synthesis) | — | 50 Lean + 450 markdown / 1 week | NEW (within R-TI total) |
| R-TI Layers T1–T6 (mandatory) | 8,400–20,800 / 10–18 weeks | 8,050–17,500 / 10–17 weeks | **−350 to −3,300 lines** (path-algebra simplification) |
| R-TI stretch (T5.6–T5.8) | — | +700–1,700 lines / +1–2 weeks | NEW (optional) |
| Chain integration | 200–500 / 0.5–1 week | 200–500 / 0.5–1 week | unchanged |
| **TOTAL (mandatory)** | 11,510–25,010 / 16–24 weeks | **11,230–21,780 / 16–24 weeks** | **−280 to −3,230 lines, no week change** |
| **TOTAL (with stretch)** | — | **11,930–23,480 / 17–26 weeks** | NEW |

The strengthened plan is **strictly better** at the upper bound
(reduced by ~3,000 lines through path-algebra simplification of
the rigidity argument) while landing the same exit criteria and
inheriting the audit-found defect fixes. The lower-bound estimate
is unchanged.

Realistic horizon (post-strengthening): **4–6 months** mandatory;
**4.5–6.5 months** with stretch goals.

# Critical files (final, post-strengthening)

**New Lean source files (target line counts):**

* `Orbcrypt/Hardness/PetrankRoth/BitLayout.lean` — 250–350 lines
* `Orbcrypt/Hardness/PetrankRoth.lean` — 1,400–2,200 lines
* `Orbcrypt/Hardness/PetrankRoth/MarkerForcing.lean` — 1,200–2,400 lines
* `Orbcrypt/Hardness/GrochowQiao/PathAlgebra.lean` — 2,500–5,500 lines (Decision GQ-A)
* `Orbcrypt/Hardness/GrochowQiao/StructureTensor.lean` — 1,200–2,200 lines (Decision GQ-B)
* `Orbcrypt/Hardness/GrochowQiao/Forward.lean` — 1,500–4,000 lines
* `Orbcrypt/Hardness/GrochowQiao/Reverse.lean` — 2,300–4,800 lines mandatory (T4 + T5.1–T5.5); +700–1,700 lines if stretch goals T5.6–T5.8 land
* `Orbcrypt/Hardness/GrochowQiao.lean` — 800–2,000 lines

**New documentation files (Layer T0 paper-synthesis deliverables):**

* `docs/research/grochow_qiao_path_algebra.md` — ~80 lines markdown
* `docs/research/grochow_qiao_mathlib_api.md` — ~120 lines markdown
* `docs/research/grochow_qiao_padding_rigidity.md` — ~200 lines markdown
* `docs/research/grochow_qiao_reading_log.md` — ~50 lines markdown
* `Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean` — ~50 lines (transient,
  deleted at T1 landing once API-surface check is no longer informative)

**Modified files (documentation/audit-script only, no signature
changes to existing declarations):**

* `Orbcrypt/Hardness/CodeEquivalence.lean`
* `Orbcrypt/Hardness/TensorAction.lean`
* `Orbcrypt/Hardness/Reductions.lean` (chain integration)
* `Orbcrypt.lean` (Vacuity map, Workstream snapshots, audit-cookbook entries)
* `CLAUDE.md` (Workstream history entries × 3)
* `docs/VERIFICATION_REPORT.md` (Document-history entries × 3)
* `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` (R-15 marked closed)
* `lakefile.lean` (version bumps × 3: `0.1.14 → 0.1.15 → 0.1.16 → 0.1.17`)
* `scripts/audit_phase_16.lean` (≥ 100 new `#print axioms` entries +
  ≥ 12 non-vacuity examples)
