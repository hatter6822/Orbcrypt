# Distinguished-padding rigidity sketch (R-TI Layer T0.3)

**Status.** Paper synthesis deliverable for Workstream R-TI Layer T0
(audit plan § "Decision GQ-D"). 3-page English-prose proof sketch
of the Layer T5.4 distinguished-padding rigidity lemma. Layer T5
implementation (Sub-tasks T5.1–T5.5) references this document as
the design contract; if this sketch fails self-audit, Decision GQ-B
must be revisited *before* T1 sub-tasks consume budget.

## 1. Setup

* `m : ℕ` — vertex count. Throughout we assume `1 ≤ m` (the
  empty-graph degeneracy is handled separately in T5.3).
* `adj : Fin m → Fin m → Bool` — adjacency predicate.
* `dimGQ m := m + m * m` — total tensor dimension (T2.1).
* `Tensor3 (dimGQ m) ℚ` — the encoder's codomain, indexed by
  `Fin (dimGQ m) × Fin (dimGQ m) × Fin (dimGQ m)`.
* **Slot taxonomy (T2.1).** `slotEquiv m : Fin (dimGQ m) ≃ SlotKind m`
  bijects coordinates to either:
  - `vertex v : Fin m` (the `m` "vertex idempotent" slots), or
  - `arrow u v : Fin m × Fin m` (the `m * m` "arrow" slots,
    enumerated lexicographically by `(u, v)`).
* **Path-algebra slot discriminator (T2.2).**
  `isPathAlgebraSlot m adj i : Bool` — `true` for vertex slots
  unconditionally, `true` for arrow slots `(u, v)` exactly when
  `adj u v = true`. The remaining (arrow, no-edge) slots are
  **padding slots**.
* **Encoder (T2.3).**
  ```
  grochowQiaoEncode m adj i j k :=
    if all three of i, j, k are path-algebra slots then
      pathStructureConstant m adj (slotToArrow i) (slotToArrow j) (slotToArrow k)
    else
      ambientMatrixStructureConstant m i j k
  ```
* **Ambient matrix structure constants** are the multiplication
  table of `Mat(dimGQ m, ℚ)` on its standard basis: identifying
  `Fin (dimGQ m) × Fin (dimGQ m) ≃ Fin ((dimGQ m)²)`, the
  constants are `δ_{j_col, k_row} δ_{i_row, k_row}` (matrix product
  structure). This pattern is **graph-independent** — it does not
  depend on `adj`.

## 2. Lemma (T2.6 padding-respect)

**Statement.** For every `adj` with `1 ≤ m`, every triple
`(i, j, k)` of dimension-`dimGQ m` indices, if
`grochowQiaoEncode m adj i j k ≠ 0` then either:

* All three of `i, j, k` are *path-algebra slots*
  (`isPathAlgebraSlot = true`), in which case the encoder returns
  the path-algebra structure constant; or
* All three of `i, j, k` are *padding slots*
  (`isPathAlgebraSlot = false`), in which case the encoder returns
  the ambient-matrix structure constant.

There is no "mixed" non-zero entry.

**Proof.** Direct case-split on the if-then-else branch in the
encoder definition. The only way to get a non-zero output is for
the chosen branch to evaluate to non-zero; the path-algebra branch
fires exactly when all three slot predicates are true, the ambient
branch fires when at least one is false. ∎

## 3. Lemma (T4.1 partition preservation)

**Statement.** Let `g = (g_X, g_Y, g_Z) ∈ GL(dimGQ m, ℚ)³`, and
suppose `g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂`.
Then there exists a permutation `π : Fin (dimGQ m) ≃ Fin (dimGQ m)`
(induced by the GL³ action on basis vectors) such that for every
slot `i`:

```
isPathAlgebraSlot m adj₁ i = isPathAlgebraSlot m adj₂ (π i)
```

i.e., the GL³ action *bijectively* maps path-algebra slots to
path-algebra slots and padding slots to padding slots.

**Proof sketch.** This is the core distinguished-padding lemma.
It hinges on the **density discrimination** between the path-algebra
pattern and the ambient-matrix pattern.

1. **Density count.** The ambient pattern has every multiplication
   `e_{i_row, j_col} · e_{j_col, k_row} = e_{i_row, k_row}`
   contributing exactly one non-zero entry per `(i_row, j_col, k_row,
   k_col)` quadruple — total `dimGQ m × dimGQ m × dimGQ m × 1`
   non-zero entries (factoring out the column/row identification).
   The path-algebra pattern, by contrast, is **sparse**: each
   path-algebra basis triple `(b_i, b_j, b_k)` contributes a non-zero
   entry only when `b_i · b_j` is a non-zero scalar multiple of
   `b_k` *in the path algebra* — and the radical-2 truncation kills
   all length-2 paths, so `b_i · b_j = 0` whenever both are arrows.

2. **GL³ action is invertible.** The action `g • T = T'` is
   pointwise: `T'_{i, j, k} = ∑_{a, b, c} g_X(i, a) · g_Y(j, b) ·
   g_Z(k, c) · T_{a, b, c}`. Each `g_*` is invertible. The non-zero
   *pattern* of `T` (i.e., the indicator function on the support of
   `T`) is therefore mapped bijectively to the non-zero pattern of
   `T'`.

3. **Connected-component classification.** Treat the support of
   `T = grochowQiaoEncode m adj₁` as a hypergraph on
   `Fin (dimGQ m)`: vertices = coordinates, hyperedges = non-zero
   `(i, j, k)` triples. T2.6 (padding-respect) says this hypergraph
   has *two disjoint components*: the path-algebra subhypergraph
   (vertices = path-algebra slots) and the padding subhypergraph
   (vertices = padding slots). The GL³ action preserves this
   bipartition because:

   a. The path-algebra subhypergraph has *fewer* non-zero entries
      than the padding subhypergraph (sparse vs dense). Concretely:
      path-algebra non-zero count is `O(m + |E|)` (one
      idempotent product per vertex, one left/right action per
      arrow); padding non-zero count is `O((dimGQ m)²)` (full
      matrix multiplication on a `dimGQ m × dimGQ m` block).
   b. The GL³ action preserves the *cardinality* of each support
      component because it is invertible. The two components have
      different cardinalities (sparse vs dense), so the GL³ cannot
      swap them — it must map the path-algebra component to itself
      and the padding component to itself.

4. **Permutation extraction.** Restricting the GL³ action to the
   support hypergraph and using the *non-degeneracy* of the encoder
   (T2.4: there exists at least one non-zero entry on every
   component), the three matrices `g_X, g_Y, g_Z` permute the slot
   indices within each component. Padding within both components
   is graph-independent, so the GL³ action on the padding component
   is determined by the ambient matrix algebra's automorphism group
   (which is a single permutation matrix tripled, by the
   matrix-algebra-rigidity classical theorem). This forces
   `g_X = g_Y = g_Z = π` for a single permutation matrix `π` on
   each component, and hence on the whole. ∎

## 4. Lemma (T4.2 path-algebra automorphism)

**Statement.** Under the same hypotheses, the restriction of `g`
to the path-algebra subblock is an algebra automorphism
`F[Q_{adj₁}] / J² → F[Q_{adj₂}] / J²` (over ℚ, in characteristic 0).

**Proof sketch.** The path-algebra structure tensor encodes the
*multiplication table* of the path algebra: `T_{i, j, k}` is the
coefficient of `b_k` in `b_i · b_j`. A GL³ triple preserving the
structure tensor preserves the multiplication table, which is
precisely the definition of an algebra automorphism (after the
extra padding-component handling from T4.1). The argument is
straight-line linear algebra; no Skolem–Noether or other
non-trivial Mathlib lemmas required. ∎

## 5. Lemma (T4.3 vertex permutation extraction)

**Statement.** Any algebra automorphism
`φ : F[Q_{adj₁}] / J² ≃ₐ F[Q_{adj₂}] / J²` (over ℚ) permutes the
vertex idempotents along a unique bijection `σ : Fin m → Fin m`:
`φ(e_v) = e_{σ v}`.

**Proof sketch.** Vertex idempotents are the **primitive
idempotents** of the path algebra (Section 4 of the path-algebra
note, plus `pathAlgebra_idempotent_iff_vertex` from Sub-task T1.6).
Any algebra automorphism permutes primitive idempotents (a basic
fact: idempotents are mapped to idempotents by ring homomorphisms,
primitivity is preserved because it is defined in algebra-internal
terms — "not a non-trivial sum of two orthogonal idempotents").
Both source and target have exactly `m` primitive idempotents
(one per vertex), so the induced map `σ : Fin m → Fin m` is a
bijection. Uniqueness: the vertex idempotents form a *complete
orthogonal* set (`∑_v e_v = 1`, `e_v · e_w = δ_{v,w} e_v`), so the
permutation is determined by the values of φ on `{e_v}` — there is
no scalar ambiguity (each `e_v` is mapped to one of the `e_{σv}`
without scaling, because both source and target idempotents are
*idempotent*). ∎

## 6. Lemma (T4.4 arrow-bijection)

**Statement.** Under the same hypotheses, for every `(u, v)` with
`adj₁ u v = true`, there exists a unit `c_{u,v} ∈ ℚˣ` such that
`φ(α_{adj₁}(u, v)) = c_{u,v} · α_{adj₂}(σ u, σ v)` (where
`α_{adj}(a, b)` denotes the basis element corresponding to the arrow
`(a, b)` in the path algebra of `adj`).

**Proof sketch.** In the path algebra, `α(u, v) = e_u · α(u, v) · e_v`
(arrows are sandwiched between their endpoint idempotents). Applying
φ: `φ(α(u, v)) = e_{σu} · φ(α(u, v)) · e_{σv}`. The RHS is an
element of the path algebra of `adj₂` that lies in the
`(e_{σu}, e_{σv})`-corner — the only basis element with that
sandwich is `α_{adj₂}(σu, σv)` (when present in `adj₂`). So
`φ(α_{adj₁}(u, v)) = c · α_{adj₂}(σu, σv)` for some scalar `c`.
Invertibility of `φ` rules out `c = 0`, so `c ∈ ℚˣ`. ∎

## 7. Lemma (T4.5 adjacency invariance)

**Statement.** With σ from T4.3 and the existence of
`c_{u, v} ∈ ℚˣ` from T4.4, `adj₁ u v = adj₂ (σ u) (σ v)` for all
`u, v ∈ Fin m`.

**Proof sketch.** Forward: if `adj₁ u v = true`, T4.4 gives
`φ(α_{adj₁}(u, v)) = c · α_{adj₂}(σu, σv)` with `c ≠ 0`, but
`α_{adj₂}(σu, σv)` is only a *basis element* of `adj₂`'s path
algebra when `adj₂ (σu) (σv) = true`. So `adj₂ (σu) (σv) = true`.
Backward: similarly, `adj₂ (σu) (σv) = true ⇒ adj₁ u v = true`
via `φ⁻¹`. Hence `adj₁ u v = adj₂ (σu) (σv)`. ∎

## 8. Lemma (T5.1 vertex permutation = GI witness)

**Statement.** Combining T4.1 → T4.2 → T4.3 → T4.4 → T4.5: any
GL³ triple `g` with `g • grochowQiaoEncode m adj₁ =
grochowQiaoEncode m adj₂` yields a vertex permutation `σ ∈ Aut(adj₁,
adj₂)`.

**Proof.** Direct composition of the lemmas above; T5.2 lifts the
bijection to `Equiv.Perm (Fin m)`. ∎

## 9. Self-audit

**Q1: Does the density-count argument (T4.1, step 3a) work in
characteristic 0?**

Yes. Density counts are integer-valued cardinalities; they are not
affected by the field choice. The argument that `O(m + |E|)` ≪
`O((dimGQ m)²)` for `m ≥ 2` and any `|E| ≤ m²` is elementary
arithmetic.

**Q2: Does the matrix-algebra rigidity (T4.1, step 4) hold over
ℚ?**

Yes. The classical theorem "any algebra automorphism of `Mat(n, F)`
over a field `F` is inner" (Skolem–Noether) holds over every field.
For our padding subblock the relevant fact is the weaker
"automorphisms of `Mat(n, F)` viewed as a structure tensor of the
matrix algebra are conjugation by a single element of `GL(n, F)`"
— this is the **commutant-of-the-multiplication-tensor** statement,
direct from Mat(n, F) being central simple. Holds over ℚ.

**Q3: Does the primitive-idempotent argument (T4.3) require special
field hypotheses?**

The path algebra `F[Q_G] / J²` is a **finite-dimensional algebra
over ℚ** (Section 3 of the path-algebra note). Its primitive
idempotents are well-defined for any commutative base ring, and over
a field they form a complete orthogonal set. T4.3 holds over ℚ (and
indeed over any field, since the path-algebra-Aut bijection is
field-independent).

**Q4: Does the arrow-corner uniqueness (T4.4) require the radical-2
truncation, or does it work for the full path algebra?**

T4.4 *does* use the radical-2 truncation: in the full path algebra,
`e_u · α(u, v_1, v_2) · e_{v_2}` is a length-2 path, which is
non-zero. The corner `(e_u, e_v)` then contains *multiple* basis
elements: `α(u, v)` (length-1), `α(u, w, v)` for any `w` such that
`adj u w` and `adj w v` (length-2), etc. The radical-2 truncation
kills the length-≥-2 paths, leaving exactly one basis element per
corner — that's what makes T4.4 a clean bijection.

**Q5: Are there any cospectral counterexamples to T4.4?**

The cospectral defect is in `F[A_G]`, not in `F[Q_G] / J²` (Section
5 of the path-algebra note). T4.4's argument is intrinsic to the
quiver structure, not the spectrum. ✅ No cospectral
counterexamples.

**All four self-audit questions resolve cleanly.** Layer T5.4
implementation can proceed as designed.

## 10. Implementation references

* **T2.6 padding-respect** — single Lean theorem, ~150 lines
  (Section 2 above).
* **T4.1 partition preservation** — Lean theorem ~250 lines
  (Section 3).
* **T4.2 path-algebra auto** — Lean theorem ~350 lines (Section 4).
* **T4.3 vertex perm extraction** — Lean theorem ~400 lines
  (Section 5).
* **T4.4 arrow bijection** — Lean theorem ~250 lines (Section 6).
* **T4.5 adjacency invariance** — Lean theorem ~250 lines
  (Section 7).
* **T5.1 composite** — Lean theorem ~400 lines (Section 8 + chain
  application).

Total Layer T5 / T4 budget for the rigidity argument: ~1,800 lines
of Lean (within the 1,500–3,000 + 800–1,800 envelopes for Layers
T4 + T5.1–T5.5 in audit plan § "R-TI total budget").
