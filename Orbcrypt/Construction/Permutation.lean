import Mathlib.GroupTheory.Perm.Basic
import Mathlib.Data.List.OfFn
import Mathlib.Data.List.Lex
import Mathlib.Data.Bool.Basic
import Orbcrypt.GroupAction.Invariant

/-!
# Orbcrypt.Construction.Permutation

S_n action on bitstrings {0,1}^n: `Bitstring` type alias, `MulAction` instance
for `Equiv.Perm (Fin n)`, Hamming weight definition, and weight-invariance
proof. Also exposes a computable lex-order `LinearOrder` on `Bitstring n`
(earliest-index-first), the natural choice for the concrete
`CanonicalForm.ofLexMin` instantiation on HGOE (Workstream F of the
2026-04-23 audit).

## Main definitions and results

* `Orbcrypt.Bitstring` — bitstrings of length n, as `Fin n → Bool`
* `MulAction (Equiv.Perm (Fin n)) (Bitstring n)` — coordinate permutation action
* `Orbcrypt.perm_smul_apply` — simp lemma: `(σ • x) i = x (σ⁻¹ i)`
* `Orbcrypt.perm_action_faithful` — different permutations act differently
* `Orbcrypt.hammingWeight` — number of 1-bits in a bitstring
* `Orbcrypt.hammingWeight_invariant` — Hamming weight is S_n-invariant
* `Orbcrypt.bitstringLinearOrder` — computable lex `LinearOrder (Bitstring n)`
  transported from `List Bool`'s lex order via `List.ofFn`. With `false < true`
  (Mathlib's `Bool.linearOrder`) this is the standard earliest-index-first
  lex convention: `false ↦ 0`, `true ↦ 1`, and the order agrees with the
  big-endian binary encoding of the bitstring. Concretely, on
  `Bitstring 3`:
    ![false, false, false] < ![false, false, true] < ![false, true, false]
    < ![false, true, true] < ![true, false, false] < ![true, false, true]
    < ![true, true, false] < ![true, true, true].
  `decide` reduces `Finset.min'` of a small concrete orbit by walking this
  order.

## References

* DEVELOPMENT.md §3.2 — S_n action on bitstrings
* DEVELOPMENT.md §7.1 — Hamming weight defense
* COUNTEREXAMPLE.md — Hamming weight attack
* formalization/phases/PHASE_5_CONCRETE_CONSTRUCTION.md — work units 5.1–5.6
* docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md § 9 — Workstream F
  (V1-10 / F-04): the `bitstringLinearOrder` instance below is the
  computable-`LinearOrder` side of the `CanonicalForm.ofLexMin` landing;
  without it, `CanonicalForm.ofLexMin G` on `Bitstring n` would require
  a caller-supplied `LinearOrder (Bitstring n)` at every use site.
-/

namespace Orbcrypt

-- ============================================================================
-- Work Unit 5.1: Bitstring Type
-- ============================================================================

/-- A bitstring of length n, represented as a function from `Fin n` to `Bool`.
    This is the ciphertext space for the concrete HGOE construction.
    The symmetric group S_n acts on bitstrings by permuting coordinates.

    Defined as `abbrev` (not `def`) so that Lean transparently unfolds it
    to `Fin n → Bool`, enabling automatic instance synthesis for `DecidableEq`,
    `Fintype`, and `ext` lemmas without manual registration. -/
abbrev Bitstring (n : ℕ) := Fin n → Bool

variable {n : ℕ}

-- ============================================================================
-- Work Unit 5.2: S_n Action Definition
-- ============================================================================

/-- S_n acts on bitstrings by permuting coordinates: `(σ • x)(i) = x(σ⁻¹(i))`.
    The use of `σ⁻¹` (rather than `σ`) ensures the standard left-action
    convention: `(σ * τ) • x = σ • (τ • x)`. See DEVELOPMENT.md §3.2. -/
instance : MulAction (Equiv.Perm (Fin n)) (Bitstring n) where
  smul σ x := fun i => x (σ⁻¹ i)
  one_smul _ := funext fun _ => rfl
  mul_smul _ _ _ := funext fun _ => rfl

-- ============================================================================
-- Work Unit 5.3: Action Simp Lemmas
-- ============================================================================

/-- Explicit computation rule for the permutation action on bitstrings. -/
@[simp]
theorem perm_smul_apply (σ : Equiv.Perm (Fin n)) (x : Bitstring n)
    (i : Fin n) :
    (σ • x) i = x (σ⁻¹ i) := rfl

/-- The identity permutation acts trivially on bitstrings. -/
@[simp]
theorem one_perm_smul (x : Bitstring n) :
    (1 : Equiv.Perm (Fin n)) • x = x := one_smul _ x

/-- Composing permutation actions equals action by product. -/
theorem mul_perm_smul (σ τ : Equiv.Perm (Fin n)) (x : Bitstring n) :
    σ • (τ • x) = (σ * τ) • x := (mul_smul σ τ x).symm

-- ============================================================================
-- Work Unit 5.4: Faithfulness Proof
-- ============================================================================

/-- The permutation action on bitstrings is faithful: different permutations
    act differently. For any non-identity permutation σ, there exists a
    bitstring that σ moves.

    **Proof strategy:** Since σ ≠ 1, there is some index i with σ i ≠ i.
    The indicator bitstring `x(j) = decide(j = i)` is moved by σ because
    evaluating at σ i gives different values before and after the action. -/
theorem perm_action_faithful
    (σ : Equiv.Perm (Fin n)) (hσ : σ ≠ 1) :
    ∃ x : Bitstring n, σ • x ≠ x := by
  -- σ ≠ 1 means ∃ i with σ i ≠ i
  have ⟨i, hi⟩ : ∃ i, σ i ≠ i := by
    by_contra h
    push Not at h
    exact hσ (Equiv.ext h)
  -- Construct indicator bitstring: x(j) = decide(j = i)
  refine ⟨fun j => decide (j = i), fun heq => hi ?_⟩
  -- If σ • x = x, evaluate at σ i to derive σ i = i
  have h1 := congr_fun heq (σ i)
  simp at h1
  exact h1

-- ============================================================================
-- Work Unit 5.5: Hamming Weight Definition
-- ============================================================================

/-- Hamming weight: the number of `true` (1) bits in a bitstring.
    This is the attack function described in COUNTEREXAMPLE.md:
    permutations preserve Hamming weight, so it leaks orbit information
    when orbit representatives have different weights. -/
def hammingWeight (x : Bitstring n) : ℕ :=
  Finset.card (Finset.univ.filter (fun i => x i = true))

-- ============================================================================
-- Work Unit 5.6: Hamming Weight Invariance Proof
-- ============================================================================

/-- Hamming weight is invariant under any permutation action.
    Permutations merely rearrange coordinates without changing the count of
    1-bits. This connects to COUNTEREXAMPLE.md: Hamming weight is a
    G-invariant function for any G ≤ S_n, making it a potential attack vector.

    **Proof strategy:** The set `{i | x(σ⁻¹ i) = true}` equals the image of
    `{j | x j = true}` under σ. Since σ is a bijection (via `Equiv.toEmbedding`),
    `Finset.card_map` preserves cardinality. -/
theorem hammingWeight_invariant :
    IsGInvariant (G := Equiv.Perm (Fin n)) (hammingWeight (n := n)) := by
  intro σ x
  simp only [hammingWeight, perm_smul_apply]
  -- Show the permuted filter equals the original filter mapped through σ
  have h : Finset.univ.filter (fun i => x (σ⁻¹ i) = true) =
           (Finset.univ.filter (fun i => x i = true)).map σ.toEmbedding := by
    ext i
    simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_map,
               Equiv.toEmbedding_apply]
    constructor
    · intro hi
      exact ⟨σ⁻¹ i, hi, Equiv.apply_symm_apply σ i⟩
    · rintro ⟨j, hj, rfl⟩
      simpa using hj
  rw [h, Finset.card_map]

-- ============================================================================
-- Workstream F (2026-04-23 audit, V1-10 / F-04):
-- computable LinearOrder on Bitstring n via List.ofFn + List.Lex.
-- ============================================================================

/-- Computable lex `LinearOrder` on `Bitstring n` — the natural
    earliest-index-first ordering under `false < true`. Transports
    Mathlib's computable `LinearOrder (List Bool)` (via `List.Lex`)
    through the `List.ofFn` injection, which is injective for fixed
    `n`.

    **Exposed as `def`, not `instance`, to avoid the diamond with
    Mathlib's pointwise `Pi.partialOrder`** (which gives a *different*
    `LT`/`LE` — the pointwise one — and is already registered as a
    global instance for every `Fin n → Bool`). Registering a global
    `LinearOrder (Bitstring n)` would leave Lean with two
    definitionally-distinct `LT (Bitstring n)` instances in scope
    (`Pi.preorder.toLT` vs the lex one), which breaks `decide` on any
    comparison that tries to find `DecidableLT` through the wrong
    path. Callers who want the lex order for `CanonicalForm.ofLexMin`
    bind it locally:

    ```
    letI : LinearOrder (Bitstring n) := bitstringLinearOrder
    let can := CanonicalForm.ofLexMin (G := ↥G) (X := Bitstring n)
    ```

    This keeps `CanonicalForm.ofLexMin` parametric over
    `[LinearOrder X]`; consumers who want a different order (e.g.
    `Lex.linearOrder`, dictionary-style) supply their own `letI` in
    place of this one. The scope-locality matches how Mathlib ships
    `Lex` as a type synonym rather than a global `Pi` linear order.

    Concretely this gives `false ↦ 0`, `true ↦ 1`, and the usual
    earliest-index-first tiebreak: on `Bitstring 3`,

        ![false, false, false] < ![false, false, true] <
        ![false, true, false] < ![false, true, true] <
        ![true, false, false] < ![true, false, true] <
        ![true, true, false] < ![true, true, true].

    `decide` reduces `Finset.min'` under this order on small inputs
    because the underlying `List.Lex`, `List.ofFn`, and
    `Bool.linearOrder` are all fully computable. This is the order
    the Workstream-F non-vacuity witness in
    `scripts/audit_phase_16.lean` binds via `letI` to machine-check
    that `ofLexMin.canon ![true, false, true] = ![false, true, true]`
    on a concrete subgroup of `Equiv.Perm (Fin 3)`.

    Marked `@[reducible]` so that `letI` binders at consumer sites
    preserve definitional transparency when chasing `DecidableLT` /
    `DecidableLE` through `LinearOrder.toDecidableLT` /
    `toDecidableLE`; without the reducibility annotation, Lean's
    instance-search attribute `instance 900` on
    `LinearOrder.toDecidable*` cannot peer through the opaque
    constant. -/
@[reducible]
def bitstringLinearOrder : LinearOrder (Bitstring n) :=
  LinearOrder.lift' (fun x : Bitstring n => List.ofFn x) List.ofFn_injective

end Orbcrypt
