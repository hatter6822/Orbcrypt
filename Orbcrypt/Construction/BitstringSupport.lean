/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.Construction.Permutation
import Orbcrypt.GroupAction.CanonicalLexMin

/-!
# Orbcrypt.Construction.BitstringSupport

The **support representation** of bitstrings. Every bitstring
`x : Bitstring n` corresponds bijectively to a finset of "true"
indices, `support x : Finset (Fin n)`. This module establishes the
structural properties of `support` — bijection, G-equivariance, and
order-preservation — that make it an *equivariant order-isomorphism*
from the Lean bitstring model to the corresponding finset model.

The headline application is the equivalence between the Lean
canonical image (computed via `CanonicalForm.ofLexMin` on
`Bitstring n` under `bitstringLinearOrder`) and the GAP reference
implementation's `CanonicalImage(G, support x, OnSets)` (the lex-min
support set in the orbit under GAP's set-lex comparison). Both
canonical-image computations pick the *same* orbit representative on
every input — a fact that follows directly from the bijection,
equivariance, and order-preservation lemmas below.

This module is the **Workstream C / C5** deliverable of the 2026-04-29
audit plan (finding D-02a). The pre-C5 disclosure in
`Orbcrypt/Construction/HGOE.lean:88-113` asserted the GAP/Lean
canonical-image correspondence in prose only, verified at small `n`
(m = 2, 3) via `decide`-based audit-script witnesses. The theorems
below prove the correspondence symbolically at *arbitrary* `n`.

## Mathematical content

The bridge between `Bitstring n` and `Finset (Fin n)` rests on three
structural correspondences:

1. **Bijection via `support`.** `support : Bitstring n →
   Finset (Fin n)` (the indicator's true-set) and its inverse
   `ofSupport` (the indicator function of a finset) are mutual
   inverses, packaged as `bitstringSupportEquiv : Bitstring n ≃
   Finset (Fin n)`.

2. **G-equivariance (the OnSets correspondence).** For any
   `σ : Equiv.Perm (Fin n)` and any `x : Bitstring n`,
   `support (σ • x) = (support x).image σ`. The right-hand side is
   GAP's `OnSets(support x, σ) = {σ(i) : i ∈ support x}`. Lean's
   `MulAction (Equiv.Perm (Fin n)) (Bitstring n)` therefore
   corresponds to the standard set-image action on
   `Finset (Fin n)` — and that set-image action is GAP's `OnSets`.

3. **Order correspondence.** The Lean lex order on `Bitstring n`
   (`bitstringLinearOrder`, defined via the inverted-Bool composition
   `List.ofFn ∘ (! ∘ ·)`) corresponds, via `support`, to a "first-
   differing-index" order on `Finset (Fin n)` we call `gapSetLT`
   (matching GAP's set-lex comparison on sorted ascending support
   lists). Both orders agree on the same per-position rule: the
   smaller bitstring has `true` at the smallest index where the two
   bitstrings differ; the smaller support set contains the smallest
   element of the two support sets' symmetric difference.

Combining the three correspondences: `support` is an equivariant
order-isomorphism between the bitstring model `(Bitstring n,
bitstringLinearOrder, MulAction)` and the finset model
`(Finset (Fin n), gapSetLT, OnSets-image)`. Because both
canonical-image operations are defined as the lex-minimum of an
orbit, and `support` preserves both the orbit structure (via
G-equivariance) and the order (via the order correspondence), the
canonical images coincide — the support of the Lean canonical image
is exactly the GAP canonical image of the support.

## Main definitions and results

* `Orbcrypt.support` — the support set of a bitstring.
* `Orbcrypt.ofSupport` — the indicator bitstring of a finset.
* `Orbcrypt.support_ofSupport`, `Orbcrypt.ofSupport_support` —
  mutual inverses.
* `Orbcrypt.bitstringSupportEquiv` — `Bitstring n ≃ Finset (Fin n)`
  packaging the bijection.
* `Orbcrypt.support_smul` — G-equivariance / OnSets correspondence:
  `support (σ • x) = (support x).image σ.toEmbedding`.
* `Orbcrypt.listLex_ofFn_iff` — characterization of `List.Lex` on
  `List.ofFn` via the first-differing-index rule.
* `Orbcrypt.bitstringLinearOrder_lt_iff_first_differ` —
  characterization of `bitstringLinearOrder.lt` via "smallest index
  of disagreement, and the smaller bitstring has `true` there".
* `Orbcrypt.gapSetLT` — first-differing-index order on
  `Finset (Fin n)` matching GAP's set-lex.
* `Orbcrypt.bitstringLinearOrder_lt_iff_gapSetLT_support` — the
  central order-correspondence lemma.
* `Orbcrypt.support_canon_minimal` — the Lean canonical image is
  `Finset.min'`-minimal in the bitstring orbit.
* `Orbcrypt.support_canon_gapSetLT_minimal` — the support of the
  Lean canonical image is `gapSetLT`-minimal across the support orbit.
* `Orbcrypt.support_canon_in_support_orbit` — the support of the
  Lean canonical image lies in the OnSets-orbit of `support x`.

Together, the last three theorems formalize the GAP / Lean
canonical-image equivalence at arbitrary `n`.

## References

* docs/DEVELOPMENT.md §3.2 — canonical forms in the encryption scheme.
* `implementation/gap/orbcrypt_kem.g:39-41` — GAP's
  `PermuteBitstring` defined as `OnSets`, the support-image action.
* `Orbcrypt/Construction/Permutation.lean` — `bitstringLinearOrder`
  and the `MulAction (Equiv.Perm (Fin n)) (Bitstring n)` instance.
* `Orbcrypt/Construction/HGOE.lean:88-113` — pre-C5 prose
  disclosure of the GAP/Lean correspondence; this module replaces
  the prose with a machine-checked theorem.
* `docs/dev_history/AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md`
  § 7.3 (Workstream C / C5) — audit-plan context for D-02a.
-/

namespace Orbcrypt

variable {n : ℕ}

-- ============================================================================
-- §1 — `support` and `ofSupport` (the bijection between bitstrings and
-- finsets of `Fin n`).
-- ============================================================================

/-- The support of a bitstring `x : Bitstring n` is the finset of indices at
    which `x` evaluates to `true`. This is the GAP-side representation:
    GAP's `orbcrypt_kem.g` represents bitstrings as sorted ascending lists of
    1-positions and operates on them via `OnSets`. -/
def support (x : Bitstring n) : Finset (Fin n) :=
  Finset.univ.filter (fun i => x i = true)

/-- `i` is in the support of `x` iff `x i = true`. Direct unfolding of
    `support`. -/
@[simp]
theorem mem_support_iff (x : Bitstring n) (i : Fin n) :
    i ∈ support x ↔ x i = true := by
  unfold support
  simp

/-- The indicator bitstring of a finset: `(ofSupport S) i = decide (i ∈ S)`.
    This is the inverse direction of the `support` bijection — the back-and-
    forth bridge between Lean's `Bitstring n` and the GAP support-set
    representation. -/
def ofSupport (S : Finset (Fin n)) : Bitstring n :=
  fun i => decide (i ∈ S)

/-- `(ofSupport S) i = true` iff `i ∈ S`. -/
@[simp]
theorem ofSupport_apply (S : Finset (Fin n)) (i : Fin n) :
    (ofSupport S) i = decide (i ∈ S) := rfl

/-- `support` and `ofSupport` are mutual inverses: `support (ofSupport S) = S`. -/
@[simp]
theorem support_ofSupport (S : Finset (Fin n)) :
    support (ofSupport S) = S := by
  ext i
  simp [support, ofSupport]

/-- `support` and `ofSupport` are mutual inverses: `ofSupport (support x) = x`. -/
@[simp]
theorem ofSupport_support (x : Bitstring n) :
    ofSupport (support x) = x := by
  funext i
  -- Reduce `decide (i ∈ support x) = x i` by case-split on `x i`.
  cases hx : x i <;> simp [support, ofSupport, hx]

/-- `support : Bitstring n → Finset (Fin n)` is a bijection. -/
def bitstringSupportEquiv : Bitstring n ≃ Finset (Fin n) where
  toFun := support
  invFun := ofSupport
  left_inv := ofSupport_support
  right_inv := support_ofSupport

@[simp]
theorem bitstringSupportEquiv_apply (x : Bitstring n) :
    bitstringSupportEquiv x = support x := rfl

@[simp]
theorem bitstringSupportEquiv_symm_apply (S : Finset (Fin n)) :
    bitstringSupportEquiv.symm S = ofSupport S := rfl

/-- `support` is injective. Direct corollary of the equiv. -/
theorem support_injective : Function.Injective (support : Bitstring n → Finset (Fin n)) :=
  bitstringSupportEquiv.injective

-- ============================================================================
-- §2 — G-equivariance: the OnSets correspondence.
-- ============================================================================

/-- **G-equivariance / OnSets correspondence.** For any permutation
    `σ : Equiv.Perm (Fin n)` and bitstring `x : Bitstring n`, the
    support of the permuted bitstring `σ • x` is the image of the
    original support under `σ`. This is the formal statement that
    Lean's `MulAction (Equiv.Perm (Fin n)) (Bitstring n)` corresponds
    to GAP's `OnSets(S, σ) = {σ(i) : i ∈ S}` action on `Finset (Fin n)`.

    **Proof strategy.** Mirrors the `hammingWeight_invariant` proof in
    `Construction/Permutation.lean`: `i ∈ support (σ • x)` iff
    `(σ • x) i = true` iff `x (σ⁻¹ i) = true` iff `σ⁻¹ i ∈ support x`
    iff `i ∈ (support x).image σ` (since `σ` is a bijection). -/
theorem support_smul (σ : Equiv.Perm (Fin n)) (x : Bitstring n) :
    support (σ • x) = (support x).image σ.toEmbedding := by
  ext i
  simp only [Finset.mem_filter, Finset.mem_univ, true_and, support,
             perm_smul_apply, Finset.mem_image, Equiv.toEmbedding_apply]
  constructor
  · -- Forward: `x (σ⁻¹ i) = true` ⇒ ∃ j ∈ Finset.univ.filter (· = true) ..., σ j = i.
    intro hi
    exact ⟨σ⁻¹ i, hi, Equiv.apply_symm_apply σ i⟩
  · -- Reverse: ∃ j ∈ filter, σ j = i ⇒ x (σ⁻¹ i) = true.
    rintro ⟨j, hj, rfl⟩
    simpa using hj

/-- A more elementary form of `support_smul`: at any fixed permutation
    `σ`, the support of `σ • x` is precisely the set
    `{σ i : i ∈ support x}`. Useful when the consumer wants to view
    the right-hand side as a coercion of `Finset.image` into `Set`. -/
theorem support_smul_apply (σ : Equiv.Perm (Fin n)) (x : Bitstring n)
    (i : Fin n) :
    i ∈ support (σ • x) ↔ ∃ j ∈ support x, σ j = i := by
  rw [support_smul]
  simp [Finset.mem_image]

-- ============================================================================
-- §3 — Order correspondence: `bitstringLinearOrder` matches GAP set-lex.
--
-- Both orders are characterized by the same "first-differing-index" rule.
-- Lean side: at the smallest `i` where `x i ≠ y i`, `x i = true` ⇒ `x < y`.
-- GAP side: at the smallest `j` in the symmetric difference `support x Δ
-- support y`, `j ∈ support x` ⇒ `support x` is "smaller" in GAP set-lex.
-- These rules describe the same condition because `i = j` and "x i = true"
-- iff "i ∈ support x \ support y".
-- ============================================================================

/-- **`List.Lex` on `List.ofFn` characterized by first-differing-index.**

    For functions `f g : Fin n → α` (with `α` a linear order),
    `List.Lex (· < ·) (List.ofFn f) (List.ofFn g)` holds iff there
    exists an index `i : Fin n` such that `f j = g j` for all
    `j : Fin n` with `j.val < i.val` and `f i < g i`. This is the
    structural bridge between Lean's lex order on bitstrings (defined
    via `List.ofFn (! ∘ ·)`) and the per-index "first-differing-
    position" characterization both orders use.

    **Proof strategy.** Induction on `n`. Base case `n = 0`: both lists
    are empty, and `List.Lex` is vacuously false; the existential is
    also vacuously false. Inductive step: split the lists via
    `List.ofFn_succ` (head = value at `Fin 0`, tail = `List.ofFn` of
    the shifted function). `List.Lex` on `head₁ :: tail₁` vs
    `head₂ :: tail₂` is either head-difference (`f 0 < g 0`, witnessed
    by `i = 0`) or head-equality with tail-Lex (recurse on shifted
    functions, lift the witness index by `Fin.succ`). -/
theorem listLex_ofFn_iff {α : Type*} [LinearOrder α] :
    ∀ {n : ℕ} (f g : Fin n → α),
      List.Lex (· < ·) (List.ofFn f) (List.ofFn g) ↔
        ∃ i : Fin n, (∀ j : Fin n, j.val < i.val → f j = g j) ∧ f i < g i
  | 0, _, _ => by
    -- Both lists are `[]`; `List.Lex r [] []` is `False`. The existential
    -- over `Fin 0` is `False` too.
    rw [List.ofFn_zero, List.ofFn_zero]
    constructor
    · intro hLex; cases hLex
    · rintro ⟨i, _, _⟩
      exact i.elim0
  | n + 1, f, g => by
    -- Use `List.ofFn_succ` to expose the head/tail structure, then split
    -- on whether the heads agree (decidable). When equal, apply
    -- `List.lex_cons_iff` to extract a tail-Lex hypothesis and recurse;
    -- when distinct, the only `Lex` constructor that can fire is `rel`,
    -- giving the head order directly.
    constructor
    · -- Forward: `Lex (ofFn f) (ofFn g)` ⇒ ∃ i ...
      intro hLex
      rw [List.ofFn_succ, List.ofFn_succ] at hLex
      by_cases h_heads : f 0 = g 0
      · -- Heads equal: use `lex_cons_iff` to extract the tail Lex, then IH.
        rw [h_heads] at hLex
        rw [List.lex_cons_iff] at hLex
        have ih := (listLex_ofFn_iff (fun i : Fin n => f i.succ)
                      (fun i : Fin n => g i.succ)).mp hLex
        obtain ⟨i', h_eq, h_lt⟩ := ih
        refine ⟨i'.succ, ?_, h_lt⟩
        intro j hj
        rcases Fin.eq_zero_or_eq_succ j with hj0 | ⟨j', hj'⟩
        · -- `j = 0`: heads equal by `h_heads`.
          subst hj0
          exact h_heads
        · -- `j = j'.succ`: prefix-agreement follows from `h_eq`.
          subst hj'
          have hj_lt : j'.val < i'.val := by
            simp [Fin.val_succ] at hj
            omega
          exact h_eq j' hj_lt
      · -- Heads differ. Only the `rel` constructor of `Lex` can match
        -- a `Lex r (a₁ :: l₁) (a₂ :: l₂)` with `a₁ ≠ a₂` (the `cons`
        -- constructor would force `a₁ = a₂`). Extract `f 0 < g 0`
        -- from the `rel` branch.
        --
        -- Lean's `cases` handles this cleanly here because the `cons`
        -- branch's dependent-equation `f 0 = g 0` is in scope of `h_heads`,
        -- which contradicts it; `cases` prunes the `cons` case via
        -- subsumption when the hypothesis context already disproves the
        -- equation.
        --
        -- We use `Decidable`-free reasoning via direct manipulation of
        -- the `List.Lex` constructors: write `hLex` as a chain of
        -- structural cases.
        have h_lt : f 0 < g 0 := by
          -- Mathlib's `List.head_le_of_lt`: `(a' :: l') < (a :: l) → a' ≤ a`.
          -- Apply at our `hLex` (after recognizing `Lex r ... ...` as `<`).
          have h_le : f 0 ≤ g 0 := List.head_le_of_lt hLex
          exact lt_of_le_of_ne h_le h_heads
        refine ⟨⟨0, by omega⟩, ?_, h_lt⟩
        intro j hj
        exact absurd hj (Nat.not_lt_zero _)
    · -- Reverse: ∃ i ... ⇒ `Lex (ofFn f) (ofFn g)`.
      rintro ⟨i, h_eq, h_lt⟩
      rw [List.ofFn_succ, List.ofFn_succ]
      rcases Fin.eq_zero_or_eq_succ i with hi0 | ⟨i', hi'⟩
      · -- `i = 0`: heads differ; use `List.Lex.rel`.
        subst hi0
        exact List.Lex.rel h_lt
      · -- `i = i'.succ`: heads equal (from `h_eq` at `0`), tails Lex via IH.
        subst hi'
        have h_heads : f 0 = g 0 := h_eq 0 (by simp [Fin.val_succ])
        rw [h_heads]
        refine List.Lex.cons ?_
        apply (listLex_ofFn_iff (fun i : Fin n => f i.succ)
                                (fun i : Fin n => g i.succ)).mpr
        refine ⟨i', ?_, h_lt⟩
        intro j' hj'
        have : (j'.succ).val < (i'.succ).val := by
          simp [Fin.val_succ]
          omega
        exact h_eq j'.succ this

/-- **`bitstringLinearOrder.lt` characterized by first-differing-index.**

    For bitstrings `x, y : Bitstring n`, `x < y` (under
    `bitstringLinearOrder`) iff there exists an index `i : Fin n` such
    that `x j = y j` for all `j : Fin n` with `j.val < i.val`,
    `x i = true`, and `y i = false`.

    The condition reads: at the smallest position where `x` and `y`
    differ, `x` has `true` and `y` has `false`. This is the standard
    "leftmost-1-wins" lex order on bitstrings, exactly matching GAP's
    set-lex on the corresponding support sets.

    **Proof strategy.** Unfold `bitstringLinearOrder` to expose the
    `LinearOrder.lift'` structure, then apply `listLex_ofFn_iff` on
    the inverted-Bool composition `! ∘ x`. The Bool comparison
    `! (x i) < ! (y i)` (under `false < true`) reduces to
    `x i = true ∧ y i = false` via `Bool.lt_iff`. The `! ∘ ·`
    inversion is also injective, so the "agree on prefix" clause
    transfers directly. -/
theorem bitstringLinearOrder_lt_iff_first_differ (x y : Bitstring n) :
    @LT.lt (Bitstring n) bitstringLinearOrder.toLT x y ↔
      ∃ i : Fin n, (∀ j : Fin n, j.val < i.val → x j = y j) ∧
        x i = true ∧ y i = false := by
  -- Unfold `bitstringLinearOrder` and `LinearOrder.lift'` to expose the
  -- underlying `List.Lex` on `List.ofFn (! ∘ ·)`. Apply `listLex_ofFn_iff`
  -- to characterize.
  show List.Lex (· < ·) (List.ofFn (fun i => !(x i)))
        (List.ofFn (fun i => !(y i))) ↔ _
  rw [listLex_ofFn_iff (fun i => !(x i)) (fun i => !(y i))]
  refine exists_congr fun i => ?_
  refine and_congr ?_ ?_
  · -- Prefix-agreement: `! (x j) = ! (y j) ↔ x j = y j` (Bool.not is injective).
    constructor
    · intro h_eq j hj
      have := h_eq j hj
      exact Bool.not_inj this
    · intro h_eq j hj
      exact congr_arg Bool.not (h_eq j hj)
  · -- Strict: `! (x i) < ! (y i) ↔ x i = true ∧ y i = false`.
    -- Bool.lt_iff: `a < b ↔ a = false ∧ b = true`.
    -- So `! (x i) < ! (y i) ↔ ! (x i) = false ∧ ! (y i) = true`
    --                       ↔ x i = true ∧ y i = false.
    rw [Bool.lt_iff]
    constructor
    · rintro ⟨h1, h2⟩
      refine ⟨?_, ?_⟩
      · cases hx : x i
        · simp [hx] at h1
        · rfl
      · cases hy : y i
        · rfl
        · simp [hy] at h2
    · rintro ⟨h1, h2⟩
      simp [h1, h2]

-- ============================================================================
-- §4 — GAP set-lex order on `Finset (Fin n)`.
--
-- We define the GAP set-lex order on `Finset (Fin n)` directly via the
-- "first-differing-index" rule: `s < t` iff at the smallest index where
-- they differ in membership, `s` contains the element. This matches GAP's
-- `OnSets`-style set comparison: sorted ascending list, lex compared.
-- ============================================================================

/-- **GAP set-lex order on `Finset (Fin n)`.** `s < t` iff there exists
    `i : Fin n` such that for all `j < i`, `j ∈ s ↔ j ∈ t`, AND `i ∈ s`
    and `i ∉ t`.

    Reading: at the smallest index where `s` and `t` differ in
    membership, `s` contains the element; this is exactly the GAP
    set-lex condition (sorted ascending lists, "smaller list at first
    differing position"). -/
def gapSetLT (s t : Finset (Fin n)) : Prop :=
  ∃ i : Fin n, (∀ j : Fin n, j.val < i.val → (j ∈ s ↔ j ∈ t)) ∧ i ∈ s ∧ i ∉ t

/-- **The GAP set-lex order matches the bitstring lex order via `support`.**

    For any two bitstrings `x, y : Bitstring n`,
    `x < y` (under `bitstringLinearOrder`) iff
    `gapSetLT (support x) (support y)`. This is the central
    order-correspondence lemma of the GAP/Lean equivalence: the Lean
    lex order on bitstrings and the GAP set-lex order on support sets
    are *the same* relation, mediated by the `support` bijection.

    **Proof strategy.** Both orders are characterized by the same
    "first-differing-index" rule
    (`bitstringLinearOrder_lt_iff_first_differ` for the Lean side, the
    `gapSetLT` definition for the GAP side). Membership in `support` is
    exactly `x j = true` (`mem_support_iff`), so the per-index
    conditions translate directly. -/
theorem bitstringLinearOrder_lt_iff_gapSetLT_support (x y : Bitstring n) :
    @LT.lt (Bitstring n) bitstringLinearOrder.toLT x y ↔
      gapSetLT (support x) (support y) := by
  rw [bitstringLinearOrder_lt_iff_first_differ]
  unfold gapSetLT
  refine exists_congr fun i => ?_
  refine and_congr ?_ ?_
  · -- Prefix agreement. `x j = y j` ↔ (`x j = true ↔ y j = true`)
    -- ↔ `j ∈ support x ↔ j ∈ support y`.
    refine forall_congr' fun j => imp_congr_right fun _ => ?_
    simp only [mem_support_iff]
    constructor
    · intro h
      rw [h]
    · intro h
      cases hx : x j
      all_goals cases hy : y j
      all_goals simp [hx, hy] at h
      all_goals rfl
  · -- Strict: `x i = true ∧ y i = false ↔ i ∈ support x ∧ i ∉ support y`.
    simp only [mem_support_iff]
    constructor
    · rintro ⟨hx, hy⟩
      refine ⟨hx, ?_⟩
      simp [hy]
    · rintro ⟨hx, hy⟩
      refine ⟨hx, ?_⟩
      cases hyy : y i
      · rfl
      · simp [hyy] at hy

-- ============================================================================
-- §5 — Final correspondence: GAP-canonical-image = Lean-canonical-image
-- via `support`.
--
-- With the order-correspondence lemma in hand, the canonical-image
-- equivalence reduces to a structural argument: the Lean canonical image
-- (the lex-min of the orbit under `bitstringLinearOrder`) is mapped by
-- `support` to the lex-min of the support-image-orbit under `gapSetLT`.
-- Both lex-min operations pick the unique minimum of a finite nonempty
-- set; since `support` is a bijection that preserves the lex order
-- (theorem above), it preserves lex-min.
-- ============================================================================

/-- **`support_canon_minimal`: the Lean canonical image is `Finset.min'`-
    minimal in the bitstring orbit.**

    For any finite subgroup `G ≤ Equiv.Perm (Fin n)`, any bitstring
    `x : Bitstring n`, and any orbit element `y ∈ orbit ↥G x`, the Lean
    canonical image `(CanonicalForm.ofLexMin (G := ↥G)).canon x` is
    less-than-or-equal to `y` under `bitstringLinearOrder`.

    This is the substantive "lex-minimality" property that
    distinguishes the canonical image from arbitrary orbit elements.
    Composed with `support_smul` (G-equivariance) and the order-
    correspondence lemma, it delivers the GAP/Lean equivalence.

    **Proof strategy.** `(CanonicalForm.ofLexMin).canon x` is *defined*
    as `Finset.min'` of `(orbit ↥G x).toFinset` under
    `bitstringLinearOrder`. `Finset.min'_le` gives the minimality. -/
theorem support_canon_minimal {G : Subgroup (Equiv.Perm (Fin n))}
    [Fintype (↥G)] (x y : Bitstring n)
    (hy : y ∈ MulAction.orbit (↥G) x) :
    @LE.le (Bitstring n) bitstringLinearOrder.toLE
      (letI : LinearOrder (Bitstring n) := bitstringLinearOrder
       (CanonicalForm.ofLexMin (G := ↥G) (X := Bitstring n)).canon x)
      y := by
  letI : LinearOrder (Bitstring n) := bitstringLinearOrder
  have hy_finset : y ∈ (MulAction.orbit (↥G) x).toFinset := by
    simp [Set.mem_toFinset, hy]
  -- `Finset.min'_le` gives `min' ≤ y` for any `y` in the finset.
  exact Finset.min'_le _ y hy_finset

/-- **Support-side restatement: the support of the canon is `gapSetLT`-
    minimal across the support orbit.**

    For any group element `g : ↥G`, the support of the Lean canonical
    image is either equal to the support-orbit element under `g`, or
    strictly less under `gapSetLT`. This is the GAP-side "set-lex-
    minimum" property of `CanonicalImage(↥G, support x, OnSets)`.

    **Proof strategy.** Combine `support_canon_minimal` (giving `≤` in
    bitstring order) with `bitstringLinearOrder_lt_iff_gapSetLT_support`
    (which transports strict `<` to `gapSetLT`) and `support_smul`
    (which identifies the bitstring-orbit element's support with the
    finset-image of the original support). -/
theorem support_canon_gapSetLT_minimal {G : Subgroup (Equiv.Perm (Fin n))}
    [Fintype (↥G)] (x : Bitstring n) (g : ↥G) :
    letI : LinearOrder (Bitstring n) := bitstringLinearOrder
    support ((CanonicalForm.ofLexMin (G := ↥G) (X := Bitstring n)).canon x) =
      (support x).image ((g : Equiv.Perm (Fin n)).toEmbedding) ∨
      gapSetLT
        (support ((CanonicalForm.ofLexMin (G := ↥G) (X := Bitstring n)).canon x))
        ((support x).image ((g : Equiv.Perm (Fin n)).toEmbedding)) := by
  -- Note on instance ambiguity: even with `letI`, the global
  -- `Pi.partialOrder` instance still wins on `Bitstring n = Fin n → Bool`.
  -- We therefore use explicit `@`-syntax to direct the elaborator to
  -- `bitstringLinearOrder.toLE` / `bitstringLinearOrder.toLT` where
  -- needed. The `letI` in the theorem signature still binds the goal's
  -- `≤` and `gapSetLT` to the lex order via the binder.
  letI hLO : LinearOrder (Bitstring n) := bitstringLinearOrder
  have h_orbit : (g : ↥G) • x ∈ MulAction.orbit (↥G) x :=
    MulAction.mem_orbit x g
  have h_le := support_canon_minimal (G := G) x ((g : ↥G) • x) h_orbit
  have h_supp_orbit : support ((g : ↥G) • x) =
      (support x).image ((g : Equiv.Perm (Fin n)).toEmbedding) := by
    show support (((g : ↥G) : Equiv.Perm (Fin n)) • x) = _
    exact support_smul ((g : ↥G) : Equiv.Perm (Fin n)) x
  -- Case-split on `canon x = g • x`. Equality case ⇒ supports equal.
  -- Inequality case ⇒ strict-< via `lt_of_le_of_ne` (with explicit
  -- partial-order instance to bypass `Pi.partialOrder`).
  by_cases h_eq :
      (CanonicalForm.ofLexMin (G := ↥G) (X := Bitstring n)).canon x =
        ((g : ↥G) • x : Bitstring n)
  · -- Equal case: supports are equal.
    left
    rw [h_eq, h_supp_orbit]
  · -- Not equal: combine `h_le` with `≠` to get strict-<.
    right
    have h_lt : @LT.lt (Bitstring n) bitstringLinearOrder.toLT
        ((CanonicalForm.ofLexMin (G := ↥G) (X := Bitstring n)).canon x)
        ((g : ↥G) • x) :=
      @lt_of_le_of_ne (Bitstring n) bitstringLinearOrder.toPartialOrder _ _
        h_le h_eq
    rw [← h_supp_orbit]
    exact (bitstringLinearOrder_lt_iff_gapSetLT_support _ _).mp h_lt

/-- **Headline theorem of Workstream C / C5: GAP/Lean canonical-image
    correspondence (existential form).**

    For any finite subgroup `G ≤ Equiv.Perm (Fin n)` and any bitstring
    `x : Bitstring n`, the support of the Lean canonical image of `x`
    is *some* element of the support-image orbit under `↥G` acting via
    `OnSets`. This certifies that the Lean canonical image and the GAP
    canonical image lie in the same orbit-equivalence class.

    **Proof strategy.** The canonical image lies in the orbit by
    construction (`CanonicalForm.mem_orbit`), so there's some `g : ↥G`
    with `canon x = g • x`. Apply `support_smul`.

    **Together with `support_canon_gapSetLT_minimal`,** this gives the
    full GAP/Lean correspondence:
    1. The support of `canon x` is in the OnSets-orbit of `support x`
       (this theorem).
    2. The support of `canon x` is `gapSetLT`-minimal in that orbit
       (`support_canon_gapSetLT_minimal`).
    Together: the support of `canon x` is the GAP canonical image
    `CanonicalImage(↥G, support x, OnSets)`. -/
theorem support_canon_in_support_orbit {G : Subgroup (Equiv.Perm (Fin n))}
    [Fintype (↥G)] (x : Bitstring n) :
    letI : LinearOrder (Bitstring n) := bitstringLinearOrder
    ∃ g : ↥G, support ((CanonicalForm.ofLexMin (G := ↥G) (X := Bitstring n)).canon x) =
      (support x).image ((g : Equiv.Perm (Fin n)).toEmbedding) := by
  letI : LinearOrder (Bitstring n) := bitstringLinearOrder
  have h_mem : (CanonicalForm.ofLexMin (G := ↥G) (X := Bitstring n)).canon x
      ∈ MulAction.orbit (↥G) x :=
    (CanonicalForm.ofLexMin (G := ↥G) (X := Bitstring n)).mem_orbit x
  obtain ⟨g, hg⟩ := h_mem
  refine ⟨g, ?_⟩
  -- `hg : (fun m => m • x) g = canon x`, i.e., `g • x = canon x` after
  -- beta. Rewrite goal using `hg.symm`, then push through `support_smul`
  -- via the subgroup-action-reduction `subgroup_smul_eq`.
  have hg' : (g : ↥G) • x = (CanonicalForm.ofLexMin (G := ↥G) (X := Bitstring n)).canon x := hg
  rw [← hg']
  -- Goal: `support (g • x) = (support x).image g.toEmbedding`. Reduce the
  -- subgroup action to the parent action and apply `support_smul`.
  show support (((g : ↥G) : Equiv.Perm (Fin n)) • x) = _
  exact support_smul ((g : ↥G) : Equiv.Perm (Fin n)) x

end Orbcrypt
