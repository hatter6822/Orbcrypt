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
matching the GAP reference implementation's `CanonicalImage(G, x, OnSets)`
convention — the canonical-form choice used by the concrete
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
  matching GAP's `CanonicalImage` set-lex convention via the inverted-Bool
  composition `List.ofFn ∘ (! ∘ ·)` (transports `List.Lex` under
  Mathlib's `false < true` to "leftmost-true wins" on bitstrings —
  equivalent to comparing GAP-style support sets element-wise on
  sorted-ascending position lists). Concretely on `Bitstring 3`:
    ![true, true, true] < ![true, true, false] < ![true, false, true]
    < ![true, false, false] < ![false, true, true] < ![false, true, false]
    < ![false, false, true] < ![false, false, false].
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
-- computable LinearOrder on Bitstring n matching GAP's CanonicalImage
-- under `OnSets` (set-lex on sorted ascending support sets).
-- ============================================================================

/-- Computable lex `LinearOrder` on `Bitstring n` matching the GAP
    reference implementation's canonical-form choice. The GAP
    prototype in `implementation/gap/orbcrypt_kem.g` represents
    bitstrings as **support sets** (sorted ascending lists of
    `true`-positions) and computes canonical forms via
    `CanonicalImage(G, x, OnSets)` from the `images` package. The
    `OnSets` canonical image is the lex-min set in the orbit under
    GAP's set comparison, which is element-wise lex on the sorted
    ascending list — equivalent to "leftmost-true-position-wins".

    To match this convention, we lift `LinearOrder (List Bool)` (which
    uses `false < true` per Mathlib's `Bool.linearOrder`) through the
    composition `List.ofFn ∘ (! ∘ ·)`, i.e., we invert each bit
    before comparing. Comparing `(! ∘ x) < (! ∘ y)` under
    `false < true` is *definitionally* the same as comparing `x < y`
    under `true < false`, so the resulting linear order on
    `Bitstring n` puts bitstrings with `true` at earlier positions
    *first* — exactly GAP's convention.

    Concretely for `Bitstring 3` (writing `T = true`, `F = false`):

        ![T, T, T] < ![T, T, F] < ![T, F, T] < ![T, F, F] <
        ![F, T, T] < ![F, T, F] < ![F, F, T] < ![F, F, F].

    The lex-min weight-2 element in `Bitstring 3` is `![T, T, F]` —
    matching GAP's `CanonicalImage(S_3, {0,1}, OnSets) = {0, 1}`.

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

    `decide` reduces `Finset.min'` under this order on small inputs
    because the underlying `List.Lex`, `List.ofFn`, `Bool.linearOrder`,
    and `Bool.not` are all fully computable. This is the order the
    Workstream-F non-vacuity witness in
    `scripts/audit_phase_16.lean` binds via `letI` to machine-check
    that `ofLexMin.canon ![true, false, true] = ![true, true, false]`
    on a concrete subgroup of `Equiv.Perm (Fin 3)` — matching the
    output of GAP's `CanonicalImage(S_3, {0, 2}, OnSets) = {0, 1}`.

    Marked `@[reducible]` so that `letI` binders at consumer sites
    preserve definitional transparency when chasing `DecidableLT` /
    `DecidableLE` through `LinearOrder.toDecidableLT` /
    `toDecidableLE`; without the reducibility annotation, Lean's
    instance-search attribute `instance 900` on
    `LinearOrder.toDecidable*` cannot peer through the opaque
    constant. -/
@[reducible]
def bitstringLinearOrder : LinearOrder (Bitstring n) :=
  LinearOrder.lift'
    (fun x : Bitstring n => List.ofFn (fun i => !(x i)))
    (fun x y h => by
      -- Injectivity: List.ofFn (! ∘ x) = List.ofFn (! ∘ y) ⇒
      --   ! ∘ x = ! ∘ y      (List.ofFn_injective on Fin n → Bool)
      --   x = y              (Bool.not_inj pointwise).
      have h' : (fun i => !(x i)) = (fun i => !(y i)) :=
        List.ofFn_injective h
      funext i
      exact Bool.not_inj (congr_fun h' i))

end Orbcrypt
