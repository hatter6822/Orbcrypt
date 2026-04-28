/-
GL³ → AlgEquiv bridge on the path subspace
(R-TI Phase 3 / Sub-task A.6, partial-discharge form).

Captures the **deep multilinear-algebra content** of Phase 3 — the
combination of Sub-tasks A.3 (distinguished-padding rigidity), A.5
(Manin tensor-stabilizer theorem), and A.6 (algebra-iso construction)
— as a **single named research-scope `Prop`**
`GL3InducesAlgEquivOnPathSubspace`.  Discharging this `Prop`
unconditionally would deliver the v3-era pair
`GL3PreservesPartitionCardinalities` + `GL3InducesArrowPreservingPerm`
together; the partial-discharge path of Phase 3 lands the surrounding
plumbing unconditional and identifies the deep content as one clean
obligation.

See `docs/planning/R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md`
§ "Phase 3 alternative — partial discharge" for the rationale and
§ "Sub-task A.6 — AlgEquiv construction + pathAlgebraQuotient bridge"
for the headline-theorem statement.
-/

import Orbcrypt.Hardness.GrochowQiao.PathOnlyTensor
import Orbcrypt.Hardness.GrochowQiao.AlgEquivLift

/-!
# GL³ → AlgEquiv on the path subspace (Sub-task A.6, partial-discharge)

## Mathematical content

For two graphs `adj₁`, `adj₂ : Fin m → Fin m → Bool` and a GL³ tensor
isomorphism `g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂`,
Phase 3's headline theorem (Approach A) constructs an algebra
isomorphism
```
ϕ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m
```
whose action on the present-arrows subspaces matches the GL³ action:
```
ϕ '' (presentArrowsSubspace m adj₁ : Set _) =
  (presentArrowsSubspace m adj₂ : Set _).
```

The construction proceeds via:

* **Sub-task A.3** — partition preservation: the GL³ tensor iso, combined
  with the post-Stage-0 distinguished-padding structure of the encoder,
  forces a slot permutation `π : Equiv.Perm (Fin (dimGQ m))` preserving
  the path/padding partition.
* **Sub-task A.4** — restriction: π and the partition decomposition let
  us restrict the GL³ triple to the path-only subspace
  (`pathOnlyStructureTensor m adj`).
* **Sub-task A.5** — Manin's tensor-stabilizer theorem: the restricted
  GL³ tensor iso forces a multiplicative isomorphism between the
  path-algebra structure tensors of `adj₁` and `adj₂`.
* **Sub-task A.6** — packaging: lift the path-only AlgEquiv to a full
  AlgEquiv on `pathAlgebraQuotient m`, with the present-arrow subspace
  preservation property.

## Partial-discharge `Prop`

The genuinely deep multilinear-algebra content of Sub-tasks A.3 + A.5 +
A.6 is captured here as the single research-scope `Prop`
`GL3InducesAlgEquivOnPathSubspace`.  Discharging this `Prop`
unconditionally requires implementing:

* The **distinguished-padding rigidity** argument
  (Grochow–Qiao 2021 §4.3, ~700 LOC of polynomial-invariant content).
* **Manin's tensor-stabilizer theorem** for unital associative
  algebras (~600 LOC of Mathlib-quality reusable content).
* The **AlgEquiv-on-pathAlgebraQuotient** packaging (~400 LOC of
  bookkeeping).

For the partial-discharge path, this `Prop` becomes the **single
research-scope obligation** replacing the v3-era pair
`GL3PreservesPartitionCardinalities` + `GL3InducesArrowPreservingPerm`.

## Public surface

* `GL3InducesAlgEquivOnPathSubspace m` (research-scope `Prop`).
* `gl3_induces_algEquiv_on_pathSubspace` — conditional headline
  (consumes the `Prop` and produces the AlgEquiv).
* `gl3_induces_algEquiv_on_pathSubspace_identity_case` — unconditional
  identity witness (`g = 1` → `AlgEquiv.refl`).
* `gl3_induces_algEquiv_on_pathSubspace_self` — unconditional witness
  for `adj₁ = adj₂` and `g = 1` (the AlgEquiv is `AlgEquiv.refl`).

## Status

Sub-task A.6 lands the **conditional headline** (`Prop` consumer) +
**identity case** + **same-graph self case** unconditionally.  The
research-scope `Prop`'s discharge is multi-month research effort and
is tracked at `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md`
§ R-15-residual-TI-reverse.

## Naming

Identifiers describe content (GL³ induces AlgEquiv, identity case),
not workstream provenance.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt
open scoped BigOperators

-- ============================================================================
-- Sub-task A.6 — Partial-discharge `Prop`.
-- ============================================================================

/-- **Research-scope `Prop`: GL³ tensor iso induces AlgEquiv on the path
subspace.**

For every pair of graphs `(adj₁, adj₂)` and every GL³ triple `g` such
that `g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂`, there
exists an algebra isomorphism `ϕ : pathAlgebraQuotient m ≃ₐ[ℚ]
pathAlgebraQuotient m` whose action on the present-arrows subspaces
matches the GL³ action on the path subspaces.

This `Prop` captures the genuinely deep content of Sub-tasks A.3, A.5,
and A.6 in a single named obligation.  Discharging it unconditionally
requires a multi-month research effort spanning ~80 pages of the
Grochow–Qiao paper (SIAM J. Comp. 2023 §4.3) and ~1,800 LOC of Lean
formalisation.

For the partial-discharge path of R-TI Phase 3, this `Prop` becomes
the **single research-scope obligation** consumed by Phases 4, 5, 6 to
deliver the unconditional Karp reduction
`grochowQiao_isInhabitedKarpReduction : @GIReducesToTI ℚ _`. -/
def GL3InducesAlgEquivOnPathSubspace (m : ℕ) : Prop :=
  ∀ (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ),
    g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂ →
    ∃ (ϕ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m),
      ϕ '' (presentArrowsSubspace m adj₁ : Set (pathAlgebraQuotient m)) =
        (presentArrowsSubspace m adj₂ : Set (pathAlgebraQuotient m))

-- ============================================================================
-- Sub-task A.6 — Conditional headline theorem.
-- ============================================================================

/-- **Phase 3 conditional headline (Sub-task A.6, partial-discharge).**

Under the research-scope `Prop` `GL3InducesAlgEquivOnPathSubspace`, every
GL³ tensor isomorphism `g • encode m adj₁ = encode m adj₂` induces an
algebra isomorphism on the path subspace.

The structure of this theorem matches the v4-plan headline
`gl3_induces_algEquiv_on_pathSubspace` in
`docs/planning/R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md` § "Sub-task A.6".
The `Prop` hypothesis encodes the entire deep mathematical content of
Sub-tasks A.3 + A.5 + A.6; the rest of the chain (Phases 4, 5, 6) is
unconditional. -/
theorem gl3_induces_algEquiv_on_pathSubspace
    (m : ℕ)
    (h_research : GL3InducesAlgEquivOnPathSubspace m)
    (adj₁ adj₂ : Fin m → Fin m → Bool)
    (g : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ)
    (hg : g • grochowQiaoEncode m adj₁ = grochowQiaoEncode m adj₂) :
    ∃ (ϕ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m),
      ϕ '' (presentArrowsSubspace m adj₁ : Set (pathAlgebraQuotient m)) =
        (presentArrowsSubspace m adj₂ : Set (pathAlgebraQuotient m)) :=
  h_research adj₁ adj₂ g hg

-- ============================================================================
-- Sub-task A.6 — Identity-case witness (unconditional).
-- ============================================================================

/-- **Identity-case witness for `GL3InducesAlgEquivOnPathSubspace`.**

When `g = 1` and `adj₁ = adj₂ = adj`, the AlgEquiv is the **reflexive**
`AlgEquiv.refl` and the present-arrows-subspace preservation is trivial.

This unconditional witness shows the research-scope `Prop` is
inhabitable on at least the identity case (i.e., `Nonempty` per
`Equiv.Perm (Fin m)`-quotient).  It is the same pattern Stage 5's
`gl3_induces_arrow_preserving_perm_identity_case` uses: identity GL³
trivially induces the identity vertex permutation. -/
theorem gl3_induces_algEquiv_on_pathSubspace_identity_case
    (m : ℕ) (adj : Fin m → Fin m → Bool)
    (_h_eq : (1 : GL (Fin (dimGQ m)) ℚ × GL (Fin (dimGQ m)) ℚ ×
              GL (Fin (dimGQ m)) ℚ) •
              grochowQiaoEncode m adj = grochowQiaoEncode m adj) :
    ∃ (ϕ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m),
      ϕ '' (presentArrowsSubspace m adj : Set (pathAlgebraQuotient m)) =
        (presentArrowsSubspace m adj : Set (pathAlgebraQuotient m)) := by
  refine ⟨AlgEquiv.refl, ?_⟩
  -- AlgEquiv.refl maps each subspace to itself.
  ext x
  simp

/-- **Self-case witness for `adj₁ = adj₂` and arbitrary `g = 1`.**

The trivial case `(g = 1, adj₁ = adj₂)`: the GL³ action is the
identity, the encoder agrees with itself, and the AlgEquiv is
reflexive. -/
theorem gl3_induces_algEquiv_on_pathSubspace_self
    (m : ℕ) (adj : Fin m → Fin m → Bool) :
    ∃ (ϕ : pathAlgebraQuotient m ≃ₐ[ℚ] pathAlgebraQuotient m),
      ϕ '' (presentArrowsSubspace m adj : Set (pathAlgebraQuotient m)) =
        (presentArrowsSubspace m adj : Set (pathAlgebraQuotient m)) := by
  refine ⟨AlgEquiv.refl, ?_⟩
  ext x
  simp

-- ============================================================================
-- Sub-task A.6 — Status disclosure.
-- ============================================================================

/-- **Status disclosure for the partial-discharge form of Phase 3.**

This statement is a documentation-only theorem documenting the
partial-closure status of R-TI Phase 3 in the codebase:

* The **research-scope `Prop`** `GL3InducesAlgEquivOnPathSubspace`
  captures the full deep multilinear-algebra content of Sub-tasks
  A.3 + A.5 + A.6 (Grochow–Qiao 2021 §4.3, ~80 pages on paper, ~1,800
  LOC of Lean).

* The **partial-discharge content** delivered:
  - Sub-task A.1 (encoder polynomial-identity catalogue) — unconditional.
  - Sub-task A.2 (associative-tensor predicate + identity-GL³ case) —
    unconditional.
  - Sub-task A.4 (path-only structure tensor + restricted-GL³ Prop +
    identity case) — unconditional + research-scope sub-Prop.
  - Sub-task A.6 (conditional headline + identity case + self case) —
    conditional on the research-scope `Prop`.

* The **research-scope discharge** of `GL3InducesAlgEquivOnPathSubspace`
  is multi-month research effort tracked at
  `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` §
  R-15-residual-TI-reverse.

Once `GL3InducesAlgEquivOnPathSubspace` is discharged, Phases 4, 5, 6
of the v4 plan deliver `grochowQiaoRigidity` and
`grochowQiao_isInhabitedKarpReduction` unconditionally.

The `True` proposition below is a verification anchor: as long as this
theorem type-checks, the partial-closure framework lands cleanly. -/
theorem gl3_algEquiv_partial_closure_status_disclosure : True := trivial

end GrochowQiao
end Orbcrypt
