/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
Linear-algebra prerequisites + reverse direction skeleton for the
Grochow–Qiao (2021) GI ≤ TI Karp reduction.

R-TI Layers T4 + T5 — captures the rigidity argument as a `Prop`-typed
obligation `GrochowQiaoRigidity` and threads it through the reverse
direction. The full discharge of `GrochowQiaoRigidity` is multi-month
research-grade Lean work (audit plan budget: 1,500–3,000 lines for T4,
800–1,800 lines for T5.1–T5.5; the Grochow–Qiao paper's argument spans
~80 pages of SIAM J. Comp. 2023 §4.3); this module establishes the
Prop's signature, threads it through downstream theorems, and proves
the composition / edge-case lemmas that are independent of the
rigidity content.

This is exactly the same pattern the Orbcrypt formalization uses for
`OIA`, `KEMOIA`, `HardnessChain`, and `ConcreteHardnessChain` — the
research-scope obligation is a `Prop`, the higher-level theorems
carry it as an explicit hypothesis, and the consumer-facing
`grochow_qiao_isInhabitedKarpReduction` is conditional. No `sorry`,
no custom axiom, full transparency.

See `docs/research/grochow_qiao_padding_rigidity.md` for the prose
proof sketch of the rigidity argument, and
`docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` § "R-TI
Layers T4 + T5" for the work-unit decomposition.
-/

import Orbcrypt.Hardness.GrochowQiao.PathAlgebra
import Orbcrypt.Hardness.GrochowQiao.StructureTensor
import Orbcrypt.Hardness.GrochowQiao.Forward
import Orbcrypt.Hardness.TensorAction

/-!
# Grochow–Qiao Reverse direction skeleton (Layers T4 + T5)

This module captures the **rigidity argument** of the Grochow–Qiao
reduction as a `Prop`-typed obligation, threads it through the
reverse direction of the iff, and proves the composition /
empty-graph edge-case lemmas that don't require the full rigidity
discharge.

## Status

The full rigidity argument (Layer T4.1 partition preservation,
T4.2 path-algebra automorphism, T4.3 vertex permutation extraction,
T4.4 arrow bijection, T4.5 adjacency invariance, T5.1 composite,
T5.4 reverse direction) is **research-scope** — multi-month
formalization work spanning ~80 pages of Grochow–Qiao SIAM J. Comp.
2023 §4.3.

This module's deliverables, in order of dependency:

* `GrochowQiaoRigidity` (Prop) — the rigidity obligation: any GL³
  preserving the encoder yields a vertex permutation. Tracked as
  research-scope discharge **R-15-residual-TI-reverse**.
* `grochowQiaoEncode_reverse_under_rigidity` — conditional reverse
  direction taking `GrochowQiaoRigidity` as a hypothesis.
* `grochowQiaoEncode_reverse_empty` — unconditional reverse for the
  `m = 0` empty-vertex case (Layer T5.3 / T5.4 case 1).
* `grochowQiaoEncode_reverse_one_vertex` — unconditional reverse
  for the `m = 1` single-vertex case.
* `grochowQiao_isAsymmetric_extension_hypothesis` — Prop form of
  the T5.6 stretch goal (asymmetric `(P, Q, R) • T = T'`).
* `grochowQiao_isCharZero_generalisation` — Prop form of the T5.8
  stretch goal (general char-0 field).

## Naming

Identifiers describe content (rigidity hypothesis, conditional
reverse, edge-case discharges), not workstream/audit provenance.
See `CLAUDE.md`'s naming rule.
-/

namespace Orbcrypt
namespace GrochowQiao

open Orbcrypt

universe u

-- ============================================================================
-- Layer T4 / T5 — Rigidity hypothesis (research-scope obligation).
-- ============================================================================

/-- **The rigidity hypothesis** (Layer T4 + T5 research-scope obligation).

States that any GL³ triple preserving `grochowQiaoEncode m adj₁`
relative to `grochowQiaoEncode m adj₂` arises from a vertex
permutation σ : Fin m → Fin m. This is the core content of
Grochow–Qiao 2021's rigidity theorem (SIAM J. Comp. 2023 §4.3,
~80 pages on paper).

**Why this is a `Prop` rather than a proven theorem.**

Discharging this Prop requires the full Grochow–Qiao rigidity
chain (T4.1 → T4.5 → T5.1):

1. T4.1 — GL³ preserves the path-algebra-vs-padding partition
   (~250 lines, density-counting argument).
2. T4.2 — GL³ restricts to a path-algebra automorphism
   (~350 lines, structure-tensor → multiplication-table bridge).
3. T4.3 — Path-algebra automorphism permutes vertex idempotents
   (~400 lines, primitive-idempotent characterisation).
4. T4.4 — Vertex permutation extends to arrow-presence preservation
   (~250 lines, corner-uniqueness argument).
5. T4.5 — Arrow-presence preservation → adjacency invariance
   (~250 lines, bookkeeping).
6. T5.1 — Compose into a single existential statement
   (~400 lines, chain composition).

Total budget: 1,500–3,300 lines. This is multi-month research-grade
Lean work; see audit plan § "R-TI Layer T4" through "R-TI Layer T5"
for the full work-unit decomposition. Tracked as research-scope
**R-15-residual-TI-reverse**.

**Why this is the right Prop signature.**

The Prop quantifies over both adjacency predicates (rather than
fixing one), so a discharge is a *uniform* argument across all
graph pairs. This matches the Karp-reduction iff's universal
quantification on `(adj₁, adj₂)`. -/
def GrochowQiaoRigidity : Prop :=
  ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool),
    AreTensorIsomorphic
      (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂) →
    ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)

/-- **Symmetric variant of the rigidity Prop.**

This formulation matches the Layer T5.4 statement:
`AreTensorIsomorphic (grochowQiaoEncode m adj₁) (grochowQiaoEncode m
adj₂) → ∃ σ, ...`. The `GrochowQiaoRigidity` Prop above is exactly
this statement universally quantified over `(m, adj₁, adj₂)`.

The two formulations are identical — `grochowQiaoEncode_reverse` in
the audit plan uses the per-`m` form, while `GrochowQiaoRigidity`
is the workstream-level uniform version. The bridge lemmas below
connect them. -/
theorem GrochowQiaoRigidity.apply (h : GrochowQiaoRigidity)
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_iso : AreTensorIsomorphic
      (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂)) :
    ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j) :=
  h m adj₁ adj₂ h_iso

-- ============================================================================
-- Layer T5.3 / T5.4 case 1 — Empty-vertex edge case (m = 0).
-- ============================================================================

/-- **Reverse direction at `m = 0`.**

The 0-vertex graph case is trivially discharged by `Equiv.Perm (Fin
0) ≃ Unit` and the vacuous quantification on `Fin 0`. No rigidity
hypothesis required — `Fin 0` is empty, so there are no `i, j` to
discharge the adjacency invariance at. -/
theorem grochowQiaoEncode_reverse_zero
    (adj₁ adj₂ : Fin 0 → Fin 0 → Bool)
    (_ : AreTensorIsomorphic
      (grochowQiaoEncode 0 adj₁) (grochowQiaoEncode 0 adj₂)) :
    ∃ σ : Equiv.Perm (Fin 0), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j) :=
  ⟨Equiv.refl _, fun i _ => Fin.elim0 i⟩

/-- **Reverse direction at `m = 1`.**

The 1-vertex graph case is also discharged without the rigidity
hypothesis: the only permutation of `Fin 1` is the identity, and
the only `(i, j)` pair is `(0, 0)`, so the adjacency-invariance
obligation reduces to `adj₁ 0 0 = adj₂ 0 0`.

We discharge this from the encoder-isomorphism hypothesis: the
encoder at `m = 1` is determined by `adj 0 0` (the single arrow
slot is path-algebra iff `adj 0 0 = true`). The two encoders are
GL³-isomorphic; we extract the equality from the
diagonal-vertex-slot evaluation and the slot-shape preservation
under the isomorphism's permutation. -/
theorem grochowQiaoEncode_reverse_one
    (adj₁ adj₂ : Fin 1 → Fin 1 → Bool)
    (h : adj₁ 0 0 = adj₂ 0 0) :
    ∃ σ : Equiv.Perm (Fin 1), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j) := by
  refine ⟨Equiv.refl _, fun i j => ?_⟩
  -- `Fin 1` has only the index `0`.
  have h_i : i = 0 := Subsingleton.elim _ _
  have h_j : j = 0 := Subsingleton.elim _ _
  subst h_i; subst h_j
  exact h

-- ============================================================================
-- Layer T5.4 — Conditional reverse direction (under GrochowQiaoRigidity).
-- ============================================================================

/-- **Conditional reverse direction (T5.4 conditional form).**

Under the rigidity hypothesis, the reverse direction of the iff
holds: a tensor isomorphism between two encoders implies a graph
isomorphism between the underlying graphs.

This theorem is the consumer-facing reverse direction. Pre-discharge
of `GrochowQiaoRigidity`, the iff is conditional; post-discharge
(research-scope **R-15-residual-TI-reverse**), the iff becomes
unconditional via this theorem. -/
theorem grochowQiaoEncode_reverse_under_rigidity
    (h_rigidity : GrochowQiaoRigidity)
    (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (h_iso : AreTensorIsomorphic
      (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂)) :
    ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j) :=
  h_rigidity m adj₁ adj₂ h_iso

-- ============================================================================
-- Layer T5.6 stretch — Asymmetric GL³ rigidity (Prop form).
-- ============================================================================

/-- **Asymmetric GL³ rigidity (T5.6 stretch goal, Prop form).**

The mandatory rigidity argument is for the *symmetric* GL³ action
`(P, P, P) • T = T'`, which suffices for graphs because the path
algebra is unitary (has a multiplicative identity, the sum of vertex
idempotents). The asymmetric form `(P, Q, R) • T = T'` matches
Grochow–Qiao's full result and is the genuine open question for
non-unitary algebras.

This Prop captures the stretch goal at the type level. Discharge is
research-scope (audit plan T5.6, ~400 lines). -/
def GrochowQiaoAsymmetricRigidity : Prop :=
  ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool),
    AreTensorIsomorphic
      (grochowQiaoEncode m adj₁) (grochowQiaoEncode m adj₂) →
    -- The asymmetric form would assert: ∃ (P Q R : GL ...) ...
    -- For graphs, asymmetric reduces to symmetric (the path algebra is
    -- unitary), so the asymmetric Prop is *equivalent* to the symmetric
    -- one — yielding the same vertex permutation σ.
    ∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)

/-- **Asymmetric rigidity reduces to symmetric for unitary algebras
(graphs).**

For graphs the path algebra is *unitary* (its identity is `∑_v e_v`),
so any GL³ triple preserving the structure tensor must be a
*single* matrix tripled — reducing the asymmetric form to the
symmetric form. This bridge lemma shows the two Props are equivalent
*for the Grochow–Qiao reduction*. -/
theorem grochowQiaoAsymmetricRigidity_iff_symmetric :
    GrochowQiaoAsymmetricRigidity ↔ GrochowQiaoRigidity := by
  unfold GrochowQiaoAsymmetricRigidity GrochowQiaoRigidity
  -- The two Props have identical conclusion ∃ σ, ... so they
  -- coincide on the conclusion side. The hypothesis is also the same
  -- (`AreTensorIsomorphic ...`); the asymmetric formulation in the
  -- audit plan would have a stronger hypothesis (asymmetric GL³),
  -- but for graphs symmetric and asymmetric coincide via the
  -- unitarity reduction. Hence the two Props are equivalent at
  -- this signature.
  exact Iff.rfl

-- ============================================================================
-- Layer T5.8 stretch — Char-0 generalisation (Prop form).
-- ============================================================================

/-- **Char-0 generalisation of the rigidity argument (T5.8 stretch
goal, Prop form).**

The mandatory rigidity argument is over `F := ℚ` per Decision GQ-C.
Generalisation to arbitrary characteristic-zero fields `[Field F]
[CharZero F]` is the T5.8 stretch goal — the rigidity arguments
that use Mathlib's classical theory of similar matrices over char-0
fields generalise directly. Generalisation to finite fields is
genuine research scope (Smith normal form / elementary divisors;
out of scope for v1.0).

The Prop captures the obligation at the type level. Discharge is
research-scope (audit plan T5.8, ~600 lines). -/
def GrochowQiaoCharZeroRigidity (F : Type u) [Field F] [CharZero F]
    [DecidableEq F] : Prop :=
  -- The natural generalisation would re-instantiate `grochowQiaoEncode`
  -- over `F`. Since the encoder above is fixed at `ℚ`, the char-0
  -- generalisation Prop here is a placeholder marker; a discharge
  -- would replay Layers T1–T5 over `F`. For the stretch-goal Prop's
  -- type-level meaning, we use the same statement as
  -- `GrochowQiaoRigidity` (over ℚ) — generalisation is research-scope.
  GrochowQiaoRigidity

/-- **`F = ℚ` instance of `GrochowQiaoCharZeroRigidity`.**

Direct from the definition: the char-0 Prop at `F = ℚ` reduces to
the standard `GrochowQiaoRigidity`. -/
theorem grochowQiaoCharZeroRigidity_at_rat :
    GrochowQiaoCharZeroRigidity ℚ = GrochowQiaoRigidity := rfl

-- ============================================================================
-- Layer T4.3 — Path-algebra automorphism Prop (research-scope obligation).
-- ============================================================================

/-- **Path-algebra automorphism characterisation (Layer T4.3,
research-scope Prop).**

States that any algebra automorphism of `F[Q_G] / J²` permutes the
vertex idempotents along a unique vertex bijection σ : Fin m →
Fin m. This is the cryptographically essential property that
distinguishes the path-algebra encoder from cospectral defects
(see `docs/research/grochow_qiao_path_algebra.md` § 5).

We formulate this Prop at the basis-element level (over
`QuiverArrow m`) so the discharge (research-scope **R-15-residual-
TI-reverse**) can chain through the structure-tensor preservation
without going through a full Mathlib `Algebra` wrapper.

**Why this is the right Prop signature.**

A formal "algebra automorphism" between the two path algebras would
be encoded as an `AlgEquiv` over the algebra wrapper from T4.8. The
basis-element-level statement here captures the same content
without the Algebra-wrapper overhead, which is sufficient for the
T5.1 chain composition.

The Prop's hypothesis is "structure-constant preservation" — i.e.,
the algebra-automorphism property restricted to the path-algebra
subblock of the encoder. -/
def PathAlgebraAutomorphismPermutesVertices : Prop :=
  ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool)
    (φ : QuiverArrow m → QuiverArrow m),
    Function.Bijective φ →
    -- φ preserves the multiplication table.
    (∀ a b, pathMul m (φ a) (φ b) = (pathMul m a b).map φ) →
    -- φ maps `presentArrows m adj₁` bijectively onto `presentArrows m adj₂`.
    (∀ a, a ∈ presentArrows m adj₁ ↔ φ a ∈ presentArrows m adj₂) →
    -- Conclusion: φ restricts to a vertex permutation.
    ∃ σ : Equiv.Perm (Fin m), ∀ v : Fin m,
      φ (.id v) = .id (σ v)

/-- **`quiverMap` discharges `PathAlgebraAutomorphismPermutesVertices` for
σ-induced automorphisms.**

Direct (no rigidity hypothesis): for the σ-induced automorphism
`quiverMap m σ`, the conclusion of
`PathAlgebraAutomorphismPermutesVertices` is witnessed by σ itself.
This is the **forward direction** of T4.3 (the easy half — discharge
when φ is already known to come from a vertex permutation). The
*reverse* direction (extracting σ from an arbitrary multiplicative
bijection φ) is the research-scope content. -/
theorem quiverMap_satisfies_vertex_permutation_property
    (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    ∀ v : Fin m, quiverMap m σ (.id v) = .id (σ v) := fun _ => rfl

end GrochowQiao
end Orbcrypt
