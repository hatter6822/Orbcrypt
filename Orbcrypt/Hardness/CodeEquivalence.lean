import Mathlib.GroupTheory.Perm.Basic
import Mathlib.Data.Finset.Defs
import Mathlib.Data.Fintype.Card
import Mathlib.Data.Fintype.EquivFin
import Mathlib.Data.Fintype.Sets
import Mathlib.Algebra.Group.Subgroup.Defs

/-!
# Orbcrypt.Hardness.CodeEquivalence

Permutation Code Equivalence (CE) problem definition and its relationship
to the Orbit Indistinguishability Assumption (OIA). This module formalizes
the CE hardness problem used by the LESS signature scheme (NIST PQC candidate)
and establishes the PAut (Permutation Automorphism group) framework.

## Main definitions

* `Orbcrypt.permuteCodeword` — permutation action on codewords
* `Orbcrypt.ArePermEquivalent` — permutation code equivalence relation
* `Orbcrypt.PAut` — permutation automorphism group of a code (`Set`-valued)
* `Orbcrypt.PAutSubgroup` — PAut promoted to a `Subgroup (Equiv.Perm (Fin n))`
  (Workstream D2)
* `Orbcrypt.arePermEquivalent_setoid` — `Setoid` instance making
  `ArePermEquivalent` a Mathlib equivalence (Workstream D4)
* `Orbcrypt.CEOIA` — Code Equivalence OIA variant
* `Orbcrypt.GIReducesToCE` — GI ≤_p CE (Prop definition, not axiom)

## Main results

* `Orbcrypt.permuteCodeword_one` — identity preserves codewords
* `Orbcrypt.permuteCodeword_mul` — composition law for permuted codewords
* `Orbcrypt.permuteCodeword_inv_apply` /
  `Orbcrypt.permuteCodeword_apply_inv` — `permuteCodeword σ⁻¹` is a
  two-sided inverse of `permuteCodeword σ` (Workstream D1 helper)
* `Orbcrypt.permuteCodeword_injective` — `permuteCodeword σ` is globally
  injective on `Fin n → F` (Workstream D1 helper)
* `Orbcrypt.permuteCodeword_self_bij_of_self_preserving` — if `σ` maps
  `C` into itself then so does `σ⁻¹` (finite-bijection helper, Workstream D1a)
* `Orbcrypt.arePermEquivalent_refl` — code equivalence is reflexive
* `Orbcrypt.arePermEquivalent_symm` — code equivalence is symmetric
  (Workstream D1b, requires `C₁.card = C₂.card`)
* `Orbcrypt.arePermEquivalent_trans` — code equivalence is transitive
  (Workstream D1c, unconditional)
* `Orbcrypt.paut_contains_id` — identity ∈ PAut(C)
* `Orbcrypt.paut_mul_closed` — PAut is closed under composition
* `Orbcrypt.paut_inv_closed` — PAut is closed under inverses (Workstream D2)
* `Orbcrypt.paut_compose_preserves_equivalence` — PAut coset property
* `Orbcrypt.paut_from_dual_equivalence` — dual equivalences yield automorphisms
* `Orbcrypt.paut_compose_yields_equivalence` — right-multiplication by PAut
  element preserves a witnessed equivalence (renamed from
  `paut_coset_is_equivalence_set` per audit finding F-16)
* `Orbcrypt.PAut_eq_PAutSubgroup_carrier` — definitional bridge between
  the `Set`-valued and `Subgroup`-valued formulations (Workstream D2c)
* `Orbcrypt.paut_equivalence_set_eq_coset` — full set identity
  `{ρ | ρ maps C₁ → C₂} = σ · PAut C₁` (Workstream D3, audit F-16
  optional strengthening)

## References

* DEVELOPMENT.md §5.4 — CE-OIA
* docs/planning/PHASE_12_HARDNESS_ALIGNMENT.md — work units 12.1–12.2
* docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md § 7 — Workstream D
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

-- ============================================================================
-- Workstream D1 — Inverse and symmetry/transitivity helpers (audit F-08)
-- ============================================================================

/-- `permuteCodeword σ⁻¹` is a left inverse of `permuteCodeword σ`.

    Algebraic proof using the composition law `permuteCodeword_mul` and
    the group identity `σ⁻¹ * σ = 1`. -/
@[simp]
theorem permuteCodeword_inv_apply (σ : Equiv.Perm (Fin n)) (c : Fin n → F) :
    permuteCodeword σ⁻¹ (permuteCodeword σ c) = c := by
  rw [← permuteCodeword_mul, inv_mul_cancel, permuteCodeword_one]

/-- `permuteCodeword σ⁻¹` is a right inverse of `permuteCodeword σ`. -/
@[simp]
theorem permuteCodeword_apply_inv (σ : Equiv.Perm (Fin n)) (c : Fin n → F) :
    permuteCodeword σ (permuteCodeword σ⁻¹ c) = c := by
  rw [← permuteCodeword_mul, mul_inv_cancel, permuteCodeword_one]

/-- `permuteCodeword σ` is globally injective on `Fin n → F`. The argument
    is purely algebraic: it has a left inverse `permuteCodeword σ⁻¹`. -/
theorem permuteCodeword_injective (σ : Equiv.Perm (Fin n)) :
    Function.Injective (permuteCodeword σ : (Fin n → F) → (Fin n → F)) := by
  intro c₁ c₂ h
  have h' : permuteCodeword σ⁻¹ (permuteCodeword σ c₁)
      = permuteCodeword σ⁻¹ (permuteCodeword σ c₂) := by rw [h]
  simpa using h'

/-- **Workstream D1a (audit F-08).** Self-bijection lemma: if a permutation
    `σ` maps a finite code `C` into itself, then so does its inverse `σ⁻¹`.

    **Proof strategy.** The restriction of `permuteCodeword σ` to the
    Fintype subtype `{x // x ∈ C}` is injective (because the global map
    is injective via `permuteCodeword_injective`) and self-mapping; on a
    finite type, an injection is a bijection, so every `c ∈ C` has a
    `σ`-preimage `y ∈ C`, which is exactly `permuteCodeword σ⁻¹ c`.

    **Why this matters.** The lemma underwrites both
    `arePermEquivalent_symm` (D1b) and `paut_inv_closed` (the `inv_mem'`
    field of `PAutSubgroup`, D2b), turning code equivalence into a true
    `Equivalence` and PAut into a true `Subgroup`. -/
theorem permuteCodeword_self_bij_of_self_preserving
    (C : Finset (Fin n → F)) (σ : Equiv.Perm (Fin n))
    (hσ : ∀ c ∈ C, permuteCodeword σ c ∈ C) :
    ∀ c ∈ C, permuteCodeword σ⁻¹ c ∈ C := by
  intro c hc
  -- Restrict `permuteCodeword σ` to the finite Fintype subtype `↥C`.
  -- (The `Fintype` instance comes from `Finset.fintypeCoeSort`.)
  let f : ↥C → ↥C :=
    fun x => ⟨permuteCodeword σ x.1, hσ x.1 x.2⟩
  -- Injective on the subtype, since the global map is injective.
  have hinj : Function.Injective f := by
    intro x y hxy
    apply Subtype.ext
    have hxy' : (f x).1 = (f y).1 := congrArg Subtype.val hxy
    exact permuteCodeword_injective σ hxy'
  -- Injective endo-self of a Fintype is bijective.
  have hbij : Function.Bijective f := hinj.bijective_of_finite
  -- Surjectivity gives a preimage `y ∈ C` of `c`.
  obtain ⟨⟨y, hy⟩, hfy⟩ := hbij.2 ⟨c, hc⟩
  have hyc : permuteCodeword σ y = c := congrArg Subtype.val hfy
  -- That preimage equals `permuteCodeword σ⁻¹ c`, which therefore lies in C.
  have hinv : permuteCodeword σ⁻¹ c = y := by
    rw [← hyc]; exact permuteCodeword_inv_apply σ y
  exact hinv ▸ hy

/-- **Workstream D1 helper (audit F-08).** If `σ` maps `C₁` into `C₂` and
    the codes have equal cardinality, then `σ⁻¹` maps `C₂` into `C₁`.

    This is the cross-code analogue of
    `permuteCodeword_self_bij_of_self_preserving` (D1a). Used by both
    `arePermEquivalent_symm` (D1b) and the forward direction of
    `paut_equivalence_set_eq_coset` (D3). -/
theorem permuteCodeword_inv_mem_of_card_eq
    (C₁ C₂ : Finset (Fin n → F))
    (σ : Equiv.Perm (Fin n))
    (hσ : ∀ c ∈ C₁, permuteCodeword σ c ∈ C₂)
    (hcard : C₁.card = C₂.card) :
    ∀ c ∈ C₂, permuteCodeword σ⁻¹ c ∈ C₁ := by
  intro c₂ hc₂
  -- Restrict permuteCodeword σ to a map ↥C₁ → ↥C₂.
  let f : ↥C₁ → ↥C₂ :=
    fun x => ⟨permuteCodeword σ x.1, hσ x.1 x.2⟩
  have hinj : Function.Injective f := by
    intro x y hxy
    apply Subtype.ext
    have hxy' : (f x).1 = (f y).1 := congrArg Subtype.val hxy
    exact permuteCodeword_injective σ hxy'
  -- Injective C₁ → C₂ between equal-size finite sets is bijective.
  have hcard' : Fintype.card (↥C₁) = Fintype.card (↥C₂) := by
    simpa using hcard
  have hbij : Function.Bijective f :=
    (Fintype.bijective_iff_injective_and_card f).mpr ⟨hinj, hcard'⟩
  obtain ⟨⟨y, hy⟩, hfy⟩ := hbij.2 ⟨c₂, hc₂⟩
  have hyc : permuteCodeword σ y = c₂ := congrArg Subtype.val hfy
  have hinv : permuteCodeword σ⁻¹ c₂ = y := by
    rw [← hyc]; exact permuteCodeword_inv_apply σ y
  exact hinv ▸ hy

/-- **Workstream D1b (audit F-08).** Symmetry of `ArePermEquivalent`.

    Requires the side condition `C₁.card = C₂.card`; this is exactly
    what `permuteCodeword_inv_mem_of_card_eq` (the D1 helper) needs.
    In the cryptographic setting two equivalent codes always have equal
    cardinality (a permuted image preserves cardinality), and exposing
    the hypothesis on the signature lets `arePermEquivalent_setoid`
    (D4) factor through the card-indexed subtype cleanly. -/
theorem arePermEquivalent_symm
    (C₁ C₂ : Finset (Fin n → F))
    (hcard : C₁.card = C₂.card) :
    ArePermEquivalent C₁ C₂ → ArePermEquivalent C₂ C₁ := by
  rintro ⟨σ, hσ⟩
  exact ⟨σ⁻¹, permuteCodeword_inv_mem_of_card_eq C₁ C₂ σ hσ hcard⟩

/-- **Workstream D1c (audit F-08).** Transitivity of `ArePermEquivalent`,
    proved by composing the two witnessing permutations. Unconditional —
    no card hypothesis needed. -/
theorem arePermEquivalent_trans
    (C₁ C₂ C₃ : Finset (Fin n → F)) :
    ArePermEquivalent C₁ C₂ → ArePermEquivalent C₂ C₃ →
    ArePermEquivalent C₁ C₃ := by
  rintro ⟨σ, hσ⟩ ⟨τ, hτ⟩
  refine ⟨τ * σ, ?_⟩
  intro c hc
  rw [permuteCodeword_mul]
  exact hτ _ (hσ c hc)

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

    A many-one (Karp) reduction: there exists a uniform encoding function
    mapping graphs to codes such that graph isomorphism holds if and only if
    the encoded codes are permutation equivalent. The encoding uses incidence
    matrices or CFI (Cai-Furer-Immerman) gadgets.

    **Complexity implications:**
    - GI: best classical 2^O(√(n log n)) (Babai, 2015)
    - CE: at least as hard as GI; believed strictly harder for specific families
    - CE-OIA is therefore a *weaker* assumption than GI-hardness

    Stated as a `Prop`-valued *definition* following the OIA pattern.
    The encoding construction is beyond this formalization's scope.
    Results carry this as an explicit hypothesis.

    **Audit note (F-12).** This definition has no in-tree consumer today;
    Workstream E's probabilistic hardness chain
    (`docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § E3–E5) is
    scheduled to consume it as an input to `ConcreteHardnessChain`. A
    concrete witness (e.g. via the CFI gadget) is tracked as Workstream F3.
    Listed in the root-file "Hardness parameter Props" section for
    transparency. -/
def GIReducesToCE : Prop :=
  ∃ (dim : ℕ → ℕ)
    (encode : (m : ℕ) → (Fin m → Fin m → Bool) → Finset (Fin (dim m) → Bool)),
    ∀ (m : ℕ) (adj₁ adj₂ : Fin m → Fin m → Bool),
      (∃ σ : Equiv.Perm (Fin m), ∀ i j, adj₁ i j = adj₂ (σ i) (σ j)) ↔
      ArePermEquivalent (encode m adj₁) (encode m adj₂)

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

/-- Right-multiplication by a PAut element yields another CE witness:
    if σ establishes equivalence C₁ ~ C₂ and τ ∈ PAut(C₁), then σ·τ also
    witnesses C₁ ~ C₂ via `ArePermEquivalent`.

    **Audit note (F-16).** This theorem was previously named
    `paut_coset_is_equivalence_set`, which promised the stronger *set
    identity* `{ρ | ρ maps C₁ → C₂} = σ · PAut(C₁)`. The body only proves
    the inclusion `σ · PAut(C₁) ⊆ {ρ | ρ maps C₁ → C₂}` (packaged as
    `ArePermEquivalent C₁ C₂`). The rename restores accuracy; the full
    set-identity strengthening is tracked as optional WU A6b
    (→ `paut_equivalence_set_eq_coset`, Workstream D3).

    **Cryptographic interpretation.** Combined with
    `paut_compose_preserves_equivalence`, this shows that the set of all
    permutations mapping C₁ to C₂ *contains* a coset of PAut(C₁). (The
    full set identity — showing this coset is exactly the set — is the
    structural claim underlying the LESS signature scheme's security
    argument; see Workstream D.) Knowing PAut(C₁) reduces the effective
    CE search space by |PAut(C₁)|, and LESS's hardness relies on |PAut|
    being typically small (often trivial) for random codes. -/
theorem paut_compose_yields_equivalence
    (C₁ C₂ : Finset (Fin n → F))
    (σ : Equiv.Perm (Fin n))
    (hσ : ∀ c ∈ C₁, permuteCodeword σ c ∈ C₂)
    (τ : Equiv.Perm (Fin n))
    (hτ : τ ∈ PAut C₁) :
    ArePermEquivalent C₁ C₂ :=
  ⟨σ * τ, paut_compose_preserves_equivalence C₁ C₂ σ hσ τ hτ⟩

end PAutRecovery

-- ============================================================================
-- Workstream D2 — `PAut` as a `Subgroup` (audit F-08 step 2)
-- ============================================================================

section PAutSubgroupStructure

/-- **Workstream D2 (audit F-08).** `PAut C` is closed under inverses.

    Direct corollary of the self-bijection helper
    `permuteCodeword_self_bij_of_self_preserving` (Workstream D1a)
    applied to `C` itself. Together with `paut_contains_id` and
    `paut_mul_closed`, this is the third subgroup axiom; it is exposed
    here as a free-standing theorem so callers do not need to descend
    into the `Subgroup` packaging when they just want the inverse-membership
    fact. -/
theorem paut_inv_closed (C : Finset (Fin n → F))
    (σ : Equiv.Perm (Fin n)) (hσ : σ ∈ PAut C) :
    σ⁻¹ ∈ PAut C := by
  intro c hc
  exact permuteCodeword_self_bij_of_self_preserving C σ hσ c hc

/-- **Workstream D2a + D2b (audit F-08).** Promote `PAut` to a full
    `Subgroup (Equiv.Perm (Fin n))`.

    All three field obligations are discharged from existing lemmas:
    * `one_mem'` ↦ `paut_contains_id`
    * `mul_mem'` ↦ `paut_mul_closed`
    * `inv_mem'` ↦ `paut_inv_closed` (which delegates to D1a)

    Exposing `PAut` as a `Subgroup` unlocks Mathlib's coset / Lagrange /
    quotient API for free — used downstream in the LESS-style search-space
    analysis and in the Workstream D3 set identity below. -/
def PAutSubgroup (C : Finset (Fin n → F)) :
    Subgroup (Equiv.Perm (Fin n)) where
  carrier := PAut C
  one_mem' := paut_contains_id C
  mul_mem' := fun hσ hτ => paut_mul_closed C _ _ hσ hτ
  inv_mem' := fun hσ => paut_inv_closed C _ hσ

/-- **Workstream D2c (audit F-08).** Definitional bridge between the
    `Set`-valued `PAut` and the `Subgroup`-packaged `PAutSubgroup`.

    Useful so existing callers that quantify over `PAut C` can be rewritten
    to use the `Subgroup`-flavoured API without altering proof terms. The
    proof is `rfl` because `Subgroup.carrier` is just a `Set` field and
    we set it to `PAut C` directly. -/
theorem PAut_eq_PAutSubgroup_carrier (C : Finset (Fin n → F)) :
    PAut C = ((PAutSubgroup C : Subgroup (Equiv.Perm (Fin n))) :
      Set (Equiv.Perm (Fin n))) := rfl

/-- The `SetLike`-membership unfold: `σ ∈ PAutSubgroup C ↔ σ ∈ PAut C`.
    Exposed as `simp` so downstream rewrites flow through transparently. -/
@[simp]
theorem mem_PAutSubgroup (C : Finset (Fin n → F))
    (σ : Equiv.Perm (Fin n)) :
    σ ∈ PAutSubgroup C ↔ σ ∈ PAut C := Iff.rfl

end PAutSubgroupStructure

-- ============================================================================
-- Workstream D3 — Coset set identity (audit F-16 optional strengthening)
-- ============================================================================

section PAutCosetIdentity

/-- **Workstream D3 (audit F-16 optional, A6b).** The full set identity:
    the set of all permutations witnessing `C₁ → C₂` equivalence is
    *exactly* a left coset `σ · PAut C₁` of the automorphism group.

    Forward inclusion (subset): every CE witness `ρ` factors as
    `σ * (σ⁻¹ * ρ)`, and `σ⁻¹ * ρ` is a self-map on `C₁` because
    `ρ` maps `C₁ → C₂` and `σ⁻¹` maps `C₂ → C₁` (by D1a applied to `σ`,
    via `arePermEquivalent_symm`-style reasoning).

    Reverse inclusion (superset): direct application of
    `paut_compose_preserves_equivalence`.

    **Cryptographic interpretation.** This is the precise algebraic
    statement underlying the LESS signature scheme's security argument:
    the effective CE search space is `|S_n| / |PAut(C₁)|`, not `|S_n|`.
    For random codes, `|PAut|` is typically trivial, recovering the
    full `|S_n|` hardness; for highly structured codes (cyclic, BCH,
    Reed–Muller), `|PAut|` can be polynomially or exponentially large
    and the effective hardness drops accordingly.

    The card-equality hypothesis matches `arePermEquivalent_symm` (D1b);
    it is needed because the proof passes through `permuteCodeword σ⁻¹`
    on `C₂`, whose self-bijection on `C₂` requires that the image
    `σ.C₁` exhausts `C₂`. -/
theorem paut_equivalence_set_eq_coset
    (C₁ C₂ : Finset (Fin n → F))
    (σ : Equiv.Perm (Fin n))
    (hσ : ∀ c ∈ C₁, permuteCodeword σ c ∈ C₂)
    (hcard : C₁.card = C₂.card) :
    {ρ : Equiv.Perm (Fin n) | ∀ c ∈ C₁, permuteCodeword ρ c ∈ C₂}
      = {ρ : Equiv.Perm (Fin n) | ∃ τ ∈ PAut C₁, ρ = σ * τ} := by
  ext ρ
  simp only [Set.mem_setOf_eq]
  refine ⟨fun hρ => ?_, ?_⟩
  · -- Forward: ρ maps C₁ → C₂. Witness τ := σ⁻¹ * ρ; then ρ = σ * τ
    -- (mul_assoc + mul_inv_cancel) and τ ∈ PAut C₁ because:
    --   permuteCodeword (σ⁻¹ * ρ) c
    --     = permuteCodeword σ⁻¹ (permuteCodeword ρ c)        -- composition
    --     ∈ permuteCodeword σ⁻¹ '' C₂                         -- by hρ
    --     ⊆ C₁                                                -- by D1 helper
    refine ⟨σ⁻¹ * ρ, ?_, ?_⟩
    · -- σ⁻¹ * ρ ∈ PAut C₁
      intro c hc
      rw [permuteCodeword_mul]
      exact permuteCodeword_inv_mem_of_card_eq
        C₁ C₂ σ hσ hcard _ (hρ c hc)
    · -- ρ = σ * (σ⁻¹ * ρ)
      rw [← mul_assoc, mul_inv_cancel, one_mul]
  · -- Reverse: ρ = σ * τ with τ ∈ PAut C₁ → ρ maps C₁ → C₂.
    rintro ⟨τ, hτ, rfl⟩
    exact paut_compose_preserves_equivalence C₁ C₂ σ hσ τ hτ

end PAutCosetIdentity

-- ============================================================================
-- Workstream D4 — `Setoid` instance for `ArePermEquivalent` (audit F-08 step 3)
-- ============================================================================

section ArePermEquivalentSetoid

/-- **Workstream D4 (audit F-08).** `ArePermEquivalent` is a Mathlib
    `Setoid` on the subtype of finsets of fixed cardinality `k`.

    The card-indexed subtype is necessary because `arePermEquivalent_symm`
    (D1b) carries the `C₁.card = C₂.card` side condition; restricting
    to a fixed-cardinality slice eliminates the obligation at the
    instance level. The `iseqv` triple bundles D1c (`refl`), D1b
    (`symm`), and D1c (`trans`).

    Downstream consumers can quotient by this `Setoid` to obtain the
    isomorphism classes of permutation codes of fixed length and
    cardinality — the natural state space for LESS-style equivalence
    enumeration. -/
instance arePermEquivalent_setoid
    (n : ℕ) (F : Type*) (k : ℕ) :
    Setoid {C : Finset (Fin n → F) // C.card = k} where
  r := fun C₁ C₂ => ArePermEquivalent C₁.val C₂.val
  iseqv :=
    { refl := fun C => arePermEquivalent_refl C.val
      symm := fun {C₁ C₂} h =>
        arePermEquivalent_symm C₁.val C₂.val (C₁.property.trans C₂.property.symm) h
      trans := fun {C₁ C₂ C₃} h₁₂ h₂₃ =>
        arePermEquivalent_trans C₁.val C₂.val C₃.val h₁₂ h₂₃ }

end ArePermEquivalentSetoid

end Orbcrypt
