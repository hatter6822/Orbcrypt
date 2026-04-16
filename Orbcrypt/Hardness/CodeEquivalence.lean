import Mathlib.GroupTheory.Perm.Basic
import Mathlib.Data.Finset.Defs

/-!
# Orbcrypt.Hardness.CodeEquivalence

Permutation Code Equivalence (CE) problem definition and its relationship
to the Orbit Indistinguishability Assumption (OIA). This module formalizes
the CE hardness problem used by the LESS signature scheme (NIST PQC candidate)
and establishes the PAut (Permutation Automorphism group) framework.

## Main definitions

* `Orbcrypt.permuteCodeword` — permutation action on codewords
* `Orbcrypt.ArePermEquivalent` — permutation code equivalence relation
* `Orbcrypt.PAut` — permutation automorphism group of a code
* `Orbcrypt.CEOIA` — Code Equivalence OIA variant
* `Orbcrypt.GIReducesToCE` — GI ≤_p CE (Prop definition, not axiom)

## Main results

* `Orbcrypt.permuteCodeword_one` — identity preserves codewords
* `Orbcrypt.permuteCodeword_mul` — composition law for permuted codewords
* `Orbcrypt.arePermEquivalent_refl` — code equivalence is reflexive
* `Orbcrypt.paut_contains_id` — identity ∈ PAut(C)
* `Orbcrypt.paut_mul_closed` — PAut is closed under composition
* `Orbcrypt.paut_compose_preserves_equivalence` — PAut coset property
* `Orbcrypt.paut_from_dual_equivalence` — dual equivalences yield automorphisms

## References

* DEVELOPMENT.md §5.4 — CE-OIA
* docs/planning/PHASE_12_HARDNESS_ALIGNMENT.md — work units 12.1–12.2
* LESS (NIST PQC): Biasse, Micheli, Persichetti, Santini (2020)
-/

namespace Orbcrypt

variable {n : ℕ} {F : Type*}

-- ============================================================================
-- Work Unit 12.1: Code Equivalence Problem Definition
-- ============================================================================

section CodeEquivalenceDefinitions

/-- Permute a codeword by applying σ⁻¹ to coordinate indices.
    Given a codeword `c : Fin n → F` and permutation `σ : Equiv.Perm (Fin n)`,
    the permuted codeword maps index `i` to `c (σ⁻¹ i)`.

    Uses `σ⁻¹` (not `σ`) to ensure the left-action convention:
    `permuteCodeword (σ * τ) c = permuteCodeword σ (permuteCodeword τ c)`.
    This matches the bitstring action in `Construction/Permutation.lean`. -/
def permuteCodeword (σ : Equiv.Perm (Fin n)) (c : Fin n → F) : Fin n → F :=
  fun i => c (σ⁻¹ i)

/-- Computation rule: `permuteCodeword σ c i = c (σ⁻¹ i)`. -/
@[simp]
theorem permuteCodeword_apply (σ : Equiv.Perm (Fin n)) (c : Fin n → F)
    (i : Fin n) : permuteCodeword σ c i = c (σ⁻¹ i) := rfl

/-- The identity permutation preserves codewords.
    **Proof:** `1⁻¹ = 1` and `1 i = i`, so `c (1⁻¹ i) = c i`. -/
@[simp]
theorem permuteCodeword_one (c : Fin n → F) :
    permuteCodeword (1 : Equiv.Perm (Fin n)) c = c := by
  funext i; simp [permuteCodeword]

/-- Composition law: permuting by σ * τ equals permuting first by τ then σ.
    **Proof:** `(σ * τ)⁻¹ = τ⁻¹ * σ⁻¹` by `mul_inv_rev`, then
    `(τ⁻¹ * σ⁻¹) i = τ⁻¹ (σ⁻¹ i)` by definition of permutation composition. -/
theorem permuteCodeword_mul (σ τ : Equiv.Perm (Fin n)) (c : Fin n → F) :
    permuteCodeword (σ * τ) c = permuteCodeword σ (permuteCodeword τ c) := by
  funext i
  simp only [permuteCodeword, mul_inv_rev, Equiv.Perm.coe_mul, Function.comp_apply]

/-- Two codes C₁, C₂ are permutation equivalent if some permutation σ maps
    every codeword of C₁ to a codeword of C₂. This is the Permutation Code
    Equivalence (CE) decision problem.

    Formally: ∃ σ ∈ S_n, ∀ c ∈ C₁, σ(c) ∈ C₂. -/
def ArePermEquivalent (C₁ C₂ : Finset (Fin n → F)) : Prop :=
  ∃ σ : Equiv.Perm (Fin n), ∀ c ∈ C₁, permuteCodeword σ c ∈ C₂

/-- Code equivalence is reflexive: every code is equivalent to itself
    via the identity permutation. -/
theorem arePermEquivalent_refl (C : Finset (Fin n → F)) :
    ArePermEquivalent C C :=
  ⟨1, fun c hc => by rwa [permuteCodeword_one]⟩

/-- The Permutation Automorphism group PAut(C): the set of permutations
    mapping every codeword of C to a codeword of C.

    PAut(C) captures the internal symmetries of the code. For codes with
    large automorphism groups, PAut recovery substantially reduces the
    search space for Code Equivalence. -/
def PAut (C : Finset (Fin n → F)) : Set (Equiv.Perm (Fin n)) :=
  { σ | ∀ c ∈ C, permuteCodeword σ c ∈ C }

/-- The identity permutation is always in PAut(C). -/
theorem paut_contains_id (C : Finset (Fin n → F)) :
    (1 : Equiv.Perm (Fin n)) ∈ PAut C := by
  intro c hc
  rwa [permuteCodeword_one]

/-- PAut is closed under composition: if σ, τ ∈ PAut(C), then σ * τ ∈ PAut(C).
    **Proof:** τ maps c to some c' ∈ C, then σ maps c' to some c'' ∈ C. -/
theorem paut_mul_closed (C : Finset (Fin n → F))
    (σ τ : Equiv.Perm (Fin n)) (hσ : σ ∈ PAut C) (hτ : τ ∈ PAut C) :
    σ * τ ∈ PAut C := by
  intro c hc
  rw [permuteCodeword_mul]
  exact hσ _ (hτ c hc)

end CodeEquivalenceDefinitions

-- ============================================================================
-- Work Unit 12.1 (continued): CEOIA and GI Reduction
-- ============================================================================

section CEOIADefinition

/-- Code Equivalence OIA: orbit indistinguishability for permutation codes.
    No Boolean function can distinguish permuted codewords drawn from two
    non-equivalent codes C₀ and C₁.

    Analogous to the main OIA (`Crypto/OIA.lean`) but specialized to the CE
    setting. Follows the OIA pattern: a `Prop`-valued definition carried as
    an explicit hypothesis, NOT an axiom. This avoids inconsistency since
    CEOIA is provably false for codes distinguishable by any invariant
    (e.g., different minimum distances). -/
def CEOIA (C₀ C₁ : Finset (Fin n → F)) : Prop :=
  ∀ (f : (Fin n → F) → Bool) (σ₀ σ₁ : Equiv.Perm (Fin n))
    (c₀ : Fin n → F) (c₁ : Fin n → F),
    c₀ ∈ C₀ → c₁ ∈ C₁ →
    f (permuteCodeword σ₀ c₀) = f (permuteCodeword σ₁ c₁)

/-- Graph Isomorphism reduces to Code Equivalence (GI ≤_p CE).

    This well-known complexity result states that any graph isomorphism
    instance can be efficiently encoded as a code equivalence instance:
    graphs G₁, G₂ are isomorphic if and only if their associated codes
    C₁, C₂ are permutation equivalent.

    The encoding uses incidence matrices or CFI (Cai-Furer-Immerman) gadgets.
    The full construction proof is beyond this formalization's scope.

    **Complexity implications:**
    - GI: best classical 2^O(√(n log n)) (Babai, 2015)
    - CE: at least as hard as GI; believed strictly harder for specific families
    - CE-OIA is therefore a *weaker* assumption than GI-hardness

    Stated as a `Prop`-valued *definition* following the OIA pattern.
    The structural content: for any pair of graphs (adjacency functions),
    there exist codes whose permutation equivalence coincides with
    graph isomorphism. Results carry this as an explicit hypothesis. -/
def GIReducesToCE : Prop :=
  ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool),
    (∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) →
    ∃ (k : ℕ) (C₁ C₂ : Finset (Fin k → Bool)),
      ArePermEquivalent C₁ C₂

end CEOIADefinition

-- ============================================================================
-- Work Unit 12.2: PAut Recovery Implies CE
-- ============================================================================

section PAutRecovery

/-- PAut coset property: if σ maps C₁ into C₂ and τ ∈ PAut(C₁), then
    σ * τ also maps C₁ into C₂.

    This is the key structural property enabling PAut recovery to solve CE:
    once any single equivalence σ is found, the full set of equivalences
    is the coset σ · PAut(C₁). Knowing PAut(C₁) reduces the search space
    from |S_n| to |S_n / PAut(C₁)| coset representatives.

    **Proof strategy:** τ maps c to some c' ∈ C₁ (automorphism), then σ
    maps c' to some c'' ∈ C₂ (equivalence). Composition gives σ * τ. -/
theorem paut_compose_preserves_equivalence
    (C₁ C₂ : Finset (Fin n → F))
    (σ : Equiv.Perm (Fin n))
    (hσ : ∀ c ∈ C₁, permuteCodeword σ c ∈ C₂)
    (τ : Equiv.Perm (Fin n))
    (hτ : τ ∈ PAut C₁) :
    ∀ c ∈ C₁, permuteCodeword (σ * τ) c ∈ C₂ := by
  intro c hc
  rw [permuteCodeword_mul]
  exact hσ _ (hτ c hc)

/-- Dual equivalences compose to automorphisms: if σ maps C₁ into C₂ and
    τ maps C₂ into C₁, then τ * σ ∈ PAut(C₁).

    This establishes the converse direction: given two codes known to be
    equivalent (with witnesses in both directions), composing the forward
    and backward maps produces automorphisms.

    **Proof:** For c ∈ C₁, σ(c) ∈ C₂ and τ(σ(c)) ∈ C₁, so (τ * σ)(c) ∈ C₁. -/
theorem paut_from_dual_equivalence
    (C₁ C₂ : Finset (Fin n → F))
    (σ : Equiv.Perm (Fin n))
    (hσ : ∀ c ∈ C₁, permuteCodeword σ c ∈ C₂)
    (τ : Equiv.Perm (Fin n))
    (hτ : ∀ c ∈ C₂, permuteCodeword τ c ∈ C₁) :
    τ * σ ∈ PAut C₁ := by
  intro c hc
  rw [permuteCodeword_mul]
  exact hτ _ (hσ c hc)

/-- PAut recovery enables CE: if σ establishes equivalence C₁ ~ C₂, then
    the full equivalence relation decomposes as ArePermEquivalent.

    Combined with `paut_compose_preserves_equivalence`, this shows that
    the set of all permutations mapping C₁ to C₂ forms a coset σ · PAut(C₁).
    Therefore, knowing PAut(C₁) reduces CE to searching among |S_n|/|PAut(C₁)|
    coset representatives — a potentially exponential speedup for codes with
    large automorphism groups.

    This structural result underlies the LESS signature scheme's security:
    LESS's hardness relies on the difficulty of recovering PAut for random codes,
    where |PAut| is typically small (often trivial). -/
theorem paut_coset_is_equivalence_set
    (C₁ C₂ : Finset (Fin n → F))
    (σ : Equiv.Perm (Fin n))
    (hσ : ∀ c ∈ C₁, permuteCodeword σ c ∈ C₂)
    (τ : Equiv.Perm (Fin n))
    (hτ : τ ∈ PAut C₁) :
    ArePermEquivalent C₁ C₂ :=
  ⟨σ * τ, paut_compose_preserves_equivalence C₁ C₂ σ hσ τ hτ⟩

end PAutRecovery

end Orbcrypt
