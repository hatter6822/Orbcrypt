/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
Path algebra `F[Q_G] / J²` for the Grochow–Qiao (2021) GI ≤ TI Karp
reduction.

R-TI Layer T1 (Sub-tasks T1.1 through T1.7) — quiver definition,
arrow enumeration, multiplication table, and structure-constant
computation. The radical-2 truncated path algebra `F[Q_G] / J²`
spanned by vertex idempotents `{e_v : v ∈ V}` and present arrows
`{α(u, v) : adj u v = true}`. See
`docs/research/grochow_qiao_path_algebra.md` for the design contract
(Decision GQ-A).

See `docs/planning/AUDIT_2026-04-25_R15_KARP_REDUCTIONS_PLAN.md` § "R-TI
Layer T1" for the work-unit decomposition.
-/

import Mathlib.Data.Fin.Basic
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Image
import Mathlib.Data.Finset.Card
import Mathlib.Logic.Equiv.Basic
import Mathlib.GroupTheory.Perm.Basic

/-!
# Grochow–Qiao path algebra `F[Q_G] / J²` (Layer T1)

This module formalises the **radical-2 truncated path algebra** of
the directed-double quiver `Q_G` of an adjacency predicate `adj :
Fin m → Fin m → Bool`. It is the encoder algebra for the Grochow–Qiao
GI ≤ TI Karp reduction (Decision GQ-A in the audit plan).

## Quiver and basis

The quiver `Q_G` has vertex set `Fin m` and an arrow `α(u, v)` for
each ordered pair `(u, v)` with `adj u v = true`. The radical-2
truncated path algebra `F[Q_G] / J²` has explicit basis

```
{e_v : v ∈ Fin m} ∪ {α(u, v) : adj u v = true}
```

of cardinality `m + |E_directed|`. We represent basis elements by
the inductive type `QuiverArrow m` and enumerate the *present*
basis by the `Finset` `presentArrows m adj`. The "present" subset
filters out arrow constructors `QuiverArrow.edge u v` for which
`adj u v = false`.

## Multiplication

Path composition truncated at length 2 is encoded by
`pathMul m : QuiverArrow m → QuiverArrow m → Option (QuiverArrow m)`.
The four cases:

* `id u · id v` — identity at vertex (idempotent law); returns
  `some (id u)` when `u = v`, `none` otherwise.
* `id u · edge v w` — left vertex action on arrow; returns
  `some (edge v w)` when `u = v`, `none` otherwise.
* `edge u v · id w` — right vertex action on arrow; returns
  `some (edge u v)` when `v = w`, `none` otherwise.
* `edge u v · edge v' w` — length-2 path, killed by `J²`; always
  returns `none`.

Lifting `pathMul`'s `Option`-output into `ℚ`-valued structure
constants (`pathStructureConstant`, Sub-task T1.5) gives the
3-tensor whose GL³ orbit Layer T2's encoder feeds into.

## Main definitions

* `QuiverArrow m` — the basis-element-naming inductive type.
* `presentArrows m adj` — the Finset of basis elements present in
  the path algebra of `adj`.
* `pathAlgebraDim m adj` — dimension of `F[Q_G] / J²`.
* `pathMul m a b` — multiplication table (Option-valued).
* `pathStructureConstant m adj F i j k` — structure constants
  (`F`-valued, where `[Zero F] [One F]`).

## Main results

* `presentArrows_card` — `(presentArrows m adj).card = m + |E_directed|`.
* `presentArrows_id_mem`, `presentArrows_edge_mem_iff` — membership
  characterisations.
* `pathAlgebraDim_le` — upper bound `m + m * m`.
* `pathMul_id_id`, `pathMul_id_edge`, `pathMul_edge_id`,
  `pathMul_edge_edge_none` — explicit multiplication-table lemmas.
* `pathMul_idempotent_iff_id` — characterisation of idempotents in
  the path-algebra basis (Sub-task T1.6 partial — the
  full `pathAlgebra_idempotent_iff_vertex` over the basis-indexing
  equivalence is research-scope; this module proves the
  basis-element-level characterisation that downstream layers
  consume).

## Status

Workstream R-TI Layer T1, post-Decision-GQ-A landing
(2026-04-26). Sub-tasks T1.1, T1.2, T1.4, T1.5, T1.6 (basis-element
form) implemented unconditionally. Sub-task T1.3
(`pathArrowEquiv` — the `Finset.equivFinOfCardEq` plumbing) and
Sub-task T1.7 (associativity / unitality lemmas at the
structure-constant level) are tracked as research-scope
follow-ups; Layer T2's slot taxonomy bypasses them by indexing
the encoder over `Fin (dimGQ m)` directly rather than through
the path-algebra basis.

## Naming

Identifiers describe content (quiver, basis, multiplication,
structure constants), not workstream/audit provenance. See
`CLAUDE.md`'s naming rule.
-/

namespace Orbcrypt
namespace GrochowQiao

universe u

-- ============================================================================
-- Sub-task T1.1 — Quiver arrow inductive type and enumeration.
-- ============================================================================

/-- Basis-element name for the radical-2 truncated path algebra
`F[Q_G] / J²`.

Two constructor families:

* `id v` — the length-zero "lazy" path at vertex `v`, the vertex
  idempotent `e_v`. Always present (every vertex has a vertex
  idempotent regardless of the adjacency).
* `edge u v` — the length-one path / arrow from `u` to `v`. Present
  in the basis only when `adj u v = true`; the `presentArrows`
  Finset filters these.

The radical-2 truncation has no length-≥-2 basis elements — they
are killed by the quotient. -/
inductive QuiverArrow (m : ℕ) where
  | id (v : Fin m) : QuiverArrow m
  | edge (u v : Fin m) : QuiverArrow m
  deriving DecidableEq, Repr

namespace QuiverArrow

instance fintype (m : ℕ) : Fintype (QuiverArrow m) where
  elems :=
    (Finset.univ.image QuiverArrow.id) ∪
    ((Finset.univ : Finset (Fin m × Fin m)).image
      (fun p => QuiverArrow.edge p.1 p.2))
  complete a := by
    cases a with
    | id v => simp
    | edge u v =>
      apply Finset.mem_union_right
      simp only [Finset.mem_image, Finset.mem_univ, true_and]
      exact ⟨(u, v), rfl⟩

end QuiverArrow

/-- Predicate: is the basis element `a` *present* in the path algebra
of `adj`? Vertex idempotents are always present; arrow basis
elements are present iff the corresponding adjacency entry is
`true`. -/
def isPresentArrow (m : ℕ) (adj : Fin m → Fin m → Bool)
    (a : QuiverArrow m) : Bool :=
  match a with
  | .id _ => true
  | .edge u v => adj u v

/-- The Finset of basis elements present in the path algebra of
`adj` — the union of the `m` vertex idempotents and the
present-arrow basis elements (one per `(u, v)` with `adj u v = true`). -/
def presentArrows (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Finset (QuiverArrow m) :=
  (Finset.univ.image QuiverArrow.id) ∪
  (((Finset.univ : Finset (Fin m × Fin m)).filter
      (fun p => adj p.1 p.2 = true)).image
    (fun p => QuiverArrow.edge p.1 p.2))

/-- The `id v` constructor lands in `presentArrows` for every `v`. -/
@[simp] theorem presentArrows_id_mem (m : ℕ)
    (adj : Fin m → Fin m → Bool) (v : Fin m) :
    QuiverArrow.id v ∈ presentArrows m adj := by
  unfold presentArrows
  apply Finset.mem_union_left
  simp

/-- The `edge u v` constructor lands in `presentArrows` exactly when
`adj u v = true`. -/
@[simp] theorem presentArrows_edge_mem_iff (m : ℕ)
    (adj : Fin m → Fin m → Bool) (u v : Fin m) :
    QuiverArrow.edge u v ∈ presentArrows m adj ↔ adj u v = true := by
  unfold presentArrows
  simp only [Finset.mem_union, Finset.mem_image, Finset.mem_univ,
    true_and, Finset.mem_filter]
  constructor
  · rintro (⟨w, h⟩ | ⟨⟨u', v'⟩, h_pair, h_eq⟩)
    · -- `h : QuiverArrow.id w = QuiverArrow.edge u v` — impossible.
      cases h
    · -- `h_eq : QuiverArrow.edge u' v' = QuiverArrow.edge u v`,
      -- so `u' = u` and `v' = v`; combine with `h_pair`.
      injection h_eq with h1 h2
      subst h1; subst h2
      exact h_pair
  · intro h_adj
    right
    exact ⟨(u, v), h_adj, rfl⟩

/-- The two image families in `presentArrows` are disjoint:
`QuiverArrow.id` produces the `id`-constructor only,
`QuiverArrow.edge` produces the `edge`-constructor only, and these
two constructor families never coincide. -/
theorem presentArrows_disjoint (m : ℕ) (adj : Fin m → Fin m → Bool) :
    Disjoint (Finset.univ.image (QuiverArrow.id : Fin m → QuiverArrow m))
      (((Finset.univ : Finset (Fin m × Fin m)).filter
          (fun p => adj p.1 p.2 = true)).image
        (fun p => QuiverArrow.edge p.1 p.2)) := by
  rw [Finset.disjoint_left]
  intro a ha hb
  simp at ha
  simp at hb
  obtain ⟨v, hv⟩ := ha
  obtain ⟨u', v', _, h_eq⟩ := hb
  rw [← hv] at h_eq
  cases h_eq

-- ============================================================================
-- Sub-task T1.2 — Path-algebra dimension.
-- ============================================================================

/-- Dimension of the radical-2 truncated path algebra `F[Q_G] / J²`:
the cardinality of `presentArrows m adj`, equal to `m +
(directedEdgeCount adj)`. -/
def pathAlgebraDim (m : ℕ) (adj : Fin m → Fin m → Bool) : ℕ :=
  (presentArrows m adj).card

/-- The count of present directed arrows in `adj` — the cardinality
of the filtered subset of `Fin m × Fin m` whose pairs `(u, v)`
satisfy `adj u v = true`. -/
def directedEdgeCount (m : ℕ) (adj : Fin m → Fin m → Bool) : ℕ :=
  ((Finset.univ : Finset (Fin m × Fin m)).filter
    (fun p => adj p.1 p.2 = true)).card

/-- Injectivity of the `QuiverArrow.id` constructor as a function
`Fin m → QuiverArrow m`. -/
theorem QuiverArrow.id_injective (m : ℕ) :
    Function.Injective (QuiverArrow.id : Fin m → QuiverArrow m) := by
  intro a b h
  injection h

/-- Injectivity of the `(fun p => QuiverArrow.edge p.1 p.2)` map
on `Fin m × Fin m`. -/
theorem QuiverArrow.edge_pair_injective (m : ℕ) :
    Function.Injective
      (fun p : Fin m × Fin m => QuiverArrow.edge p.1 p.2) := by
  intro p q h
  injection h with h1 h2
  exact Prod.ext h1 h2

/-- Explicit `m + |E_directed|` decomposition of `pathAlgebraDim`. -/
theorem pathAlgebraDim_apply (m : ℕ) (adj : Fin m → Fin m → Bool) :
    pathAlgebraDim m adj = m + directedEdgeCount m adj := by
  unfold pathAlgebraDim presentArrows directedEdgeCount
  rw [Finset.card_union_of_disjoint (presentArrows_disjoint m adj)]
  congr 1
  · rw [Finset.card_image_of_injective _ (QuiverArrow.id_injective m)]
    exact (Finset.card_univ (α := Fin m)).trans (Fintype.card_fin m)
  · exact Finset.card_image_of_injective _ (QuiverArrow.edge_pair_injective m)

/-- Upper bound: dimension is at most `m + m * m`. -/
theorem pathAlgebraDim_le (m : ℕ) (adj : Fin m → Fin m → Bool) :
    pathAlgebraDim m adj ≤ m + m * m := by
  rw [pathAlgebraDim_apply]
  apply Nat.add_le_add_left
  unfold directedEdgeCount
  calc ((Finset.univ : Finset (Fin m × Fin m)).filter
          (fun p => adj p.1 p.2 = true)).card
      ≤ (Finset.univ : Finset (Fin m × Fin m)).card := Finset.card_filter_le _ _
    _ = m * m := by rw [Finset.card_univ, Fintype.card_prod, Fintype.card_fin]

/-- Vertex idempotents alone give at least `m` basis elements; in
particular `pathAlgebraDim` is strictly positive whenever `m ≥ 1`. -/
theorem pathAlgebraDim_pos_of_pos_m (m : ℕ) (h : 1 ≤ m)
    (adj : Fin m → Fin m → Bool) :
    1 ≤ pathAlgebraDim m adj := by
  rw [pathAlgebraDim_apply]
  exact Nat.le_add_right_of_le h

-- ============================================================================
-- Sub-task T1.4 — Path-algebra multiplication table (`pathMul`).
-- ============================================================================

/-- Path composition truncated at length 2.

The `Option`-valued output encodes the J²-quotient: `none` means
"the product is zero in `F[Q_G] / J²`" (because the underlying path
either does not compose or has length ≥ 2). `some c` means "the
product is the basis element `c`".

Four cases:

* `id u · id v = if u = v then id u else 0` (vertex idempotents are
  pairwise orthogonal).
* `id u · edge v w = if u = v then edge v w else 0` (left vertex
  action on arrows).
* `edge u v · id w = if v = w then edge u v else 0` (right vertex
  action on arrows).
* `edge u v · edge _ _ = 0` (length-2 paths killed by `J²`).
-/
def pathMul (m : ℕ) (a b : QuiverArrow m) : Option (QuiverArrow m) :=
  match a, b with
  | .id u, .id v       => if u = v then some (.id u) else none
  | .id u, .edge v w   => if u = v then some (.edge v w) else none
  | .edge u v, .id w   => if v = w then some (.edge u v) else none
  | .edge _ _, .edge _ _ => none

/-- Explicit case for vertex-vertex product. -/
@[simp] theorem pathMul_id_id (m : ℕ) (u v : Fin m) :
    pathMul m (.id u) (.id v) =
      (if u = v then some (.id u) else none) := rfl

/-- Explicit case for left vertex action on arrow. -/
@[simp] theorem pathMul_id_edge (m : ℕ) (u v w : Fin m) :
    pathMul m (.id u) (.edge v w) =
      (if u = v then some (.edge v w) else none) := rfl

/-- Explicit case for right vertex action on arrow. -/
@[simp] theorem pathMul_edge_id (m : ℕ) (u v w : Fin m) :
    pathMul m (.edge u v) (.id w) =
      (if v = w then some (.edge u v) else none) := rfl

/-- Length-2 paths are killed by the radical-2 quotient. -/
@[simp] theorem pathMul_edge_edge_none (m : ℕ) (u v u' v' : Fin m) :
    pathMul m (.edge u v) (.edge u' v') = none := rfl

/-- Vertex idempotent law: `e_u · e_u = e_u`. -/
theorem pathMul_id_self (m : ℕ) (u : Fin m) :
    pathMul m (.id u) (.id u) = some (.id u) := by
  simp

/-- Vertex idempotents are pairwise orthogonal: `e_u · e_v = 0` when
`u ≠ v`. -/
theorem pathMul_id_id_ne (m : ℕ) (u v : Fin m) (h : u ≠ v) :
    pathMul m (.id u) (.id v) = none := by
  simp [pathMul, h]

/-- Diagonal multiplication of an `edge`-type basis element kills
itself in the radical-2 quotient. -/
theorem pathMul_edge_self_none (m : ℕ) (u v : Fin m) :
    pathMul m (.edge u v) (.edge u v) = none := rfl

-- ============================================================================
-- Sub-task T1.6 (basis-element form) — Idempotency characterisation.
-- ============================================================================

/-- **Vertex-idempotent characterisation at the basis-element level.**

A basis element `a : QuiverArrow m` is *idempotent* in `pathMul`
(`pathMul a a = some a`) if and only if `a` is a vertex idempotent
`QuiverArrow.id v` for some `v`. The converse — that diagonal
products of `edge`-type elements always return `none` — captures the
J²-truncation's killing of length-2 paths.

This is the basis-element-level characterisation underlying Layer T5's
rigidity argument: any GL³ preserving the structure tensor must map
idempotent basis triples to idempotent basis triples, hence vertex
idempotents to vertex idempotents.

**Status.** This basis-element form is unconditional. The full
`pathAlgebra_idempotent_iff_vertex` over linear combinations
(audit plan T1.6) requires the basis-indexing equivalence
`pathArrowEquiv` (T1.3); tracked as research-scope. -/
theorem pathMul_idempotent_iff_id (m : ℕ) (a : QuiverArrow m) :
    pathMul m a a = some a ↔ ∃ v : Fin m, a = QuiverArrow.id v := by
  cases a with
  | id v =>
    constructor
    · intro _; exact ⟨v, rfl⟩
    · intro _; exact pathMul_id_self m v
  | edge u v =>
    simp only [pathMul_edge_self_none]
    constructor
    · intro h; cases h
    · rintro ⟨_, h⟩; cases h

-- ============================================================================
-- σ-action on quiver arrows + path-multiplication equivariance.
-- ============================================================================

/-- The natural σ-action on `QuiverArrow m`: a vertex permutation
σ ∈ Equiv.Perm (Fin m) acts on basis elements by permuting the
endpoints. Vertex idempotents `e_v` map to `e_(σ v)`; arrows
`α(u, v)` map to `α(σ u, σ v)`. -/
def quiverMap (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    QuiverArrow m → QuiverArrow m
  | .id v => .id (σ v)
  | .edge u v => .edge (σ u) (σ v)

@[simp] theorem quiverMap_id (m : ℕ) (σ : Equiv.Perm (Fin m)) (v : Fin m) :
    quiverMap m σ (.id v) = .id (σ v) := rfl

@[simp] theorem quiverMap_edge (m : ℕ) (σ : Equiv.Perm (Fin m))
    (u v : Fin m) :
    quiverMap m σ (.edge u v) = .edge (σ u) (σ v) := rfl

/-- The identity permutation acts as the identity on `QuiverArrow m`. -/
@[simp] theorem quiverMap_one (m : ℕ) :
    quiverMap m (1 : Equiv.Perm (Fin m)) = id := by
  funext a
  cases a with
  | id v => show QuiverArrow.id ((1 : Equiv.Perm (Fin m)) v) = .id v; rfl
  | edge u v =>
      show QuiverArrow.edge ((1 : Equiv.Perm (Fin m)) u)
                            ((1 : Equiv.Perm (Fin m)) v) = .edge u v
      rfl

/-- The σ-action on `QuiverArrow m` is injective (since σ is). -/
theorem quiverMap_injective (m : ℕ) (σ : Equiv.Perm (Fin m)) :
    Function.Injective (quiverMap m σ) := by
  intro a b h
  cases a with
  | id va =>
      cases b with
      | id vb =>
          simp only [quiverMap_id] at h
          injection h with h1
          exact congrArg _ (σ.injective h1)
      | edge ub vb =>
          -- `quiverMap σ (id va) = id (σ va)` vs `quiverMap σ (edge ub vb)
          -- = edge (σ ub) (σ vb)`; constructors disagree.
          simp only [quiverMap_id, quiverMap_edge] at h
          cases h
  | edge ua va =>
      cases b with
      | id vb =>
          simp only [quiverMap_id, quiverMap_edge] at h
          cases h
      | edge ub vb =>
          simp only [quiverMap_edge] at h
          injection h with h1 h2
          have h3 : ua = ub := σ.injective h1
          have h4 : va = vb := σ.injective h2
          subst h3; subst h4
          rfl

/-- **Path-multiplication is σ-equivariant.**

Multiplication in the radical-2 truncated path algebra commutes with
the σ-action: `(σ • a) · (σ • b) = σ • (a · b)`. The four-case
`pathMul` table is preserved because every case's `if u = v` test on
`Fin m` is preserved under σ (which is injective). The arrow-arrow
case is uniform (always `none`).

This is the **basis-element-level σ-equivariance** that the
slot-level equivariance lemma `pathSlotStructureConstant_equivariant`
in Layer T3.4 consumes. -/
theorem pathMul_quiverMap (m : ℕ) (σ : Equiv.Perm (Fin m))
    (a b : QuiverArrow m) :
    pathMul m (quiverMap m σ a) (quiverMap m σ b) =
    (pathMul m a b).map (quiverMap m σ) := by
  cases a with
  | id u =>
      cases b with
      | id v =>
          -- pathMul (id u) (id v) = if u = v then some (id u) else none.
          -- After σ-action: pathMul (id (σ u)) (id (σ v)) = if σ u = σ v
          -- then some (id (σ u)) else none. Both branches match via σ
          -- injectivity.
          simp only [quiverMap_id, pathMul_id_id]
          by_cases h : u = v
          · subst h; simp
          · have h' : σ u ≠ σ v := fun heq => h (σ.injective heq)
            rw [if_neg h, if_neg h']
            rfl
      | edge va vb =>
          -- pathMul (id u) (edge va vb) = if u = va then some (edge va vb) else none.
          -- After σ-action: pathMul (id (σ u)) (edge (σ va) (σ vb)) =
          -- if σ u = σ va then some (edge (σ va) (σ vb)) else none.
          simp only [quiverMap_id, quiverMap_edge, pathMul_id_edge]
          by_cases h : u = va
          · subst h; simp
          · have h' : σ u ≠ σ va := fun heq => h (σ.injective heq)
            rw [if_neg h, if_neg h']
            rfl
  | edge ua va =>
      cases b with
      | id w =>
          -- pathMul (edge ua va) (id w) = if va = w then some (edge ua va) else none.
          simp only [quiverMap_id, quiverMap_edge, pathMul_edge_id]
          by_cases h : va = w
          · subst h; simp
          · have h' : σ va ≠ σ w := fun heq => h (σ.injective heq)
            rw [if_neg h, if_neg h']
            rfl
      | edge ub vb =>
          -- pathMul (edge _ _) (edge _ _) = none unconditionally.
          simp only [quiverMap_edge, pathMul_edge_edge_none, Option.map_none]

-- ============================================================================
-- T1.7 — Path multiplication associativity (`pathMul_assoc`).
-- ============================================================================

/-- **Path-multiplication associativity** at the basis-element level.

For any three quiver basis elements `a, b, c`, the two bracketings
of the triple product agree as `Option (QuiverArrow m)`:
```
(a · b) · c = a · (b · c)
```
where `·` is `pathMul m` and `(_ · _) · _` uses `Option.bind` to
short-circuit when the first product is `none`.

**Proof strategy.** Three nested `cases QuiverArrow` produce 8 cases
(2 × 2 × 2 for `id` / `edge` on each position). All cases involving
two consecutive `edge` constructors collapse to `none = none`
unconditionally (length-≥-2 paths are killed by the J²-truncation).
The remaining cases (at most one `edge` in any consecutive pair)
unfold the `pathMul` table, reduce to `if-then-else` chains over
`Fin m` equalities, and close by `split_ifs` + `rfl`.

This lemma underlies the path-algebra multiplication's associativity
at the structure-constant level (see `pathStructureConstant_associative`
in `AlgebraWrapper.lean`). -/
theorem pathMul_assoc (m : ℕ) (a b c : QuiverArrow m) :
    Option.bind (pathMul m a b) (fun ab => pathMul m ab c) =
    Option.bind (pathMul m b c) (fun bc => pathMul m a bc) := by
  cases a with
  | id u =>
    cases b with
    | id v =>
      cases c with
      | id w =>
        -- (id, id, id): both sides reduce to "if u=v=w then some (id u) else none"
        simp only [pathMul_id_id, Option.bind]
        split_ifs <;> simp_all
      | edge w₁ w₂ =>
        -- (id, id, edge): need u=v=w₁ for non-none
        simp only [pathMul_id_id, pathMul_id_edge, Option.bind]
        split_ifs <;> simp_all
    | edge v₁ v₂ =>
      cases c with
      | id w =>
        -- (id, edge, id)
        simp only [pathMul_id_edge, pathMul_edge_id, Option.bind]
        split_ifs <;> simp_all
      | edge w₁ w₂ =>
        -- (id, edge, edge): RHS bc = pathMul (edge v₁ v₂) (edge w₁ w₂) = none.
        -- LHS ab = pathMul (id u) (edge v₁ v₂) = some (edge v₁ v₂) if u=v₁
        -- then pathMul ab c = pathMul (edge v₁ v₂) (edge w₁ w₂) = none.
        simp only [pathMul_id_edge, pathMul_edge_edge_none, Option.bind]
        split_ifs <;> rfl
  | edge u₁ u₂ =>
    cases b with
    | id v =>
      cases c with
      | id w =>
        -- (edge, id, id)
        simp only [pathMul_edge_id, pathMul_id_id, Option.bind]
        split_ifs <;> simp_all
      | edge w₁ w₂ =>
        -- (edge, id, edge)
        simp only [pathMul_edge_id, pathMul_id_edge, Option.bind]
        split_ifs <;> simp_all
    | edge v₁ v₂ =>
      cases c with
      | id w =>
        -- (edge, edge, id): LHS ab = pathMul (edge u₁ u₂) (edge v₁ v₂) = none.
        -- RHS bc = pathMul (edge v₁ v₂) (id w) = some (edge v₁ v₂) if v₂=w.
        -- Then pathMul a bc = pathMul (edge u₁ u₂) (edge v₁ v₂) = none.
        simp only [pathMul_edge_edge_none, pathMul_edge_id, Option.bind]
        split_ifs <;> rfl
      | edge w₁ w₂ =>
        -- (edge, edge, edge): both sides none
        simp only [pathMul_edge_edge_none, Option.bind]

end GrochowQiao
end Orbcrypt
