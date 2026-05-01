/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.Construction.HGOE
import Orbcrypt.Construction.BitstringSupport
import Orbcrypt.GroupAction.Invariant
import Orbcrypt.GroupAction.CanonicalLexMin
import Orbcrypt.Theorems.InvariantAttack

/-!
# Orbcrypt.Construction.HGOEInvariants

Catalogue of G-invariants on `Bitstring n` beyond Hamming weight.

## Overview

Hamming weight (`hammingWeight`) was already known to be an `S_n`-
invariant attack channel (`Orbcrypt/Construction/HGOE.lean`'s
`hammingWeight_invariant_subgroup` + `hgoe_weight_attack`). This
module formalises three additional invariants from the literature
beyond Hamming weight, completing the audit-disclosed
"beyond-Hamming-weight invariants" gap (R-16, audit 2026-04-29
§ 8.1).

## Main definitions

* `Orbcrypt.blockSum` — per-block bit-count vector. Invariant under
  any subgroup of `S_n` that **preserves the block partition**
  (every block is mapped setwise to itself).
* `Orbcrypt.PreservesBlocks` — predicate witnessing that a subgroup
  preserves a block partition.
* `Orbcrypt.bitParity` — XOR-fold of all bits, equivalently
  `hammingWeight % 2 = 1`. `S_n`-invariant by reduction to
  `hammingWeight_invariant`.
* `Orbcrypt.sortedBits` — the lex-min element of the orbit under
  `S_n`, i.e. the canonical form. `S_n`-invariant by construction.

## Main results

For each invariant `f ∈ {blockSum, bitParity, sortedBits}`:

* `f_invariant_subgroup` — `f` is `G`-invariant for the relevant
  subgroup `G ≤ S_n`.
* `hgoe_<f>_attack` — if `f (reps m₀) ≠ f (reps m₁)`, an adversary
  with `hasAdvantage` exists (existential form via the abstract
  `invariant_attack` theorem).
* `same_<f>_not_separating` — defence: choosing reps with the same
  `f`-value rules out `f`-mediated separation.

## Cryptographic significance

These are *necessary* defences: any HGOE deployment using a
subgroup G that respects the block partition must select reps with
matching `blockSum`-vectors (else `hgoe_blockSum_attack` fires).
Bit-parity is automatic for any `S_n`-subgroup (so any
non-`S_n`-fixing scheme must select same-parity reps regardless).
Sorted-bits is the **strongest** `S_n`-invariant: it preserves the
entire orbit identity, so any `S_n`-respecting scheme that admits
distinct sorted-bit reps is broken. The
`OrbitEncScheme.reps_distinct` field already prohibits the same-
sorted-bits case (sorted-bits = canonical form, and distinct orbits
have distinct canonical forms), so this connects to the
deterministic OIA vacuity theorem `det_oia_false_of_distinct_reps`
in `Crypto/OIA.lean`.

## Probabilistic upgrade

The attack proofs here deliver the *existential* form (some
distinguishing `(g₀, g₁)` pair exists). For the quantitative
probabilistic upgrade — `indCPAAdvantage = 1` — compose with R-01's
`indCPAAdvantage_invariantAttackAdversary_eq_one` (in
`Theorems/InvariantAttack.lean`).

## References

* DEVELOPMENT.md §7 — invariant attack discussion.
* COUNTEREXAMPLE.md — Hamming weight invariant.
* docs/planning/PLAN_R_01_07_08_14_16.md § R-16 — beyond-Hamming
  invariant catalogue.
-/

set_option autoImplicit false

namespace Orbcrypt

variable {n : ℕ}

-- ============================================================================
-- Invariant 1 — Block-sum (per-block bit-count vector)
-- ============================================================================

/--
**Block-sum invariant.** For a partition `block : Fin ℓ → Finset (Fin n)`
of the bit positions, `blockSum block b` returns a vector of bit
counts: position `j` holds the number of `true` bits in block
`block j`.

This is a *generalisation* of Hamming weight: the single-block
partition `block := fun _ => Finset.univ` recovers `hammingWeight`
exactly (both count the total number of `true` bits). Multi-block
partitions give a strictly stronger invariant, attacking schemes
that defeat the Hamming-weight defence by per-block bit-count
imbalance.
-/
def blockSum {ℓ : ℕ} (block : Fin ℓ → Finset (Fin n))
    (b : Bitstring n) : Fin ℓ → ℕ :=
  fun j => ((block j).filter (fun i => b i = true)).card

/--
**Block partition preserved by a subgroup.** A subgroup
`G ≤ Equiv.Perm (Fin n)` *preserves* a block partition `block` iff
every group element `g ∈ G` setwise-permutes each block: the image
of block `j` under `g` is block `j` itself.

**Examples.**
* The trivial subgroup `{1}` preserves any partition.
* The full symmetric group `S_n` preserves only the trivial
  partition (single block = `Finset.univ` or empty blocks).
* Block-cyclic wreath-product subgroups (used in HGOE's fallback
  group construction) preserve their block partition by design.
-/
def PreservesBlocks {ℓ : ℕ} (G : Subgroup (Equiv.Perm (Fin n)))
    (block : Fin ℓ → Finset (Fin n)) : Prop :=
  ∀ g : G, ∀ j : Fin ℓ, (block j).image (↑g : Equiv.Perm (Fin n)) = block j

/--
**Block-sum is G-invariant under any subgroup that preserves the
block partition.** For each block `j`, the bit-count of `g • b`
restricted to `block j` equals the bit-count of `b` restricted to
the *preimage* of `block j` under `g`. Since `G` setwise-preserves
each block (so its inverse does too), the preimage is again
`block j`, and the counts agree.

**Proof technique.** For each `j`, rewrite `(g • b) i = b (g⁻¹ i)`
via `perm_smul_apply`. The filter
`{i ∈ block j | b (g⁻¹ i) = true}` is in bijection with
`{i ∈ block j | b i = true}` via `i ↦ g⁻¹ i` (an injection from
`block j` to `block j` by `PreservesBlocks` at `g⁻¹`).
`Finset.card_image_of_injective` (with `Equiv.injective`) closes it.
-/
theorem blockSum_invariant_of_preservesBlocks {ℓ : ℕ}
    (G : Subgroup (Equiv.Perm (Fin n))) (block : Fin ℓ → Finset (Fin n))
    (hPres : PreservesBlocks G block) :
    IsGInvariant (G := ↥G) (blockSum block) := by
  intro g b
  funext j
  -- Goal: blockSum block (g • b) j = blockSum block b j
  unfold blockSum
  -- Reduce subgroup action to parent permutation action.
  simp only [subgroup_smul_eq, perm_smul_apply]
  classical
  set σ : Equiv.Perm (Fin n) := (↑g : Equiv.Perm (Fin n)) with hσ_def
  -- Strategy: show the filter on `i ↦ b (σ⁻¹ i)` over `block j` is the
  -- image under σ of the filter on `i ↦ b i` over `block j`. This works
  -- because σ is a bijection and σ setwise-preserves block j (so does σ⁻¹).
  have h_image_fwd : (block j).image σ = block j := hPres g j
  -- Key observation: `σ⁻¹` (the group-inverse `Equiv.Perm`) coincides
  -- with `σ.symm` definitionally, so we can use the standard `Equiv`
  -- round-trip lemmas `symm_apply_apply` and `apply_symm_apply`.
  have h_inv_apply : ∀ i, σ⁻¹ (σ i) = i := fun i => σ.symm_apply_apply i
  have h_apply_inv : ∀ i, σ (σ⁻¹ i) = i := fun i => σ.apply_symm_apply i
  -- Establish the bijection: i ∈ block j ↔ σ⁻¹ i ∈ block j.
  have h_inv_iff : ∀ i, σ⁻¹ i ∈ block j ↔ i ∈ block j := by
    intro i
    constructor
    · intro h_in
      -- σ⁻¹ i ∈ block j ⇒ σ (σ⁻¹ i) = i ∈ image σ (block j) = block j.
      rw [← h_image_fwd]
      exact Finset.mem_image.mpr ⟨σ⁻¹ i, h_in, h_apply_inv i⟩
    · intro h_in
      rw [← h_image_fwd] at h_in
      obtain ⟨i', h_i'_in, h_eq⟩ := Finset.mem_image.mp h_in
      have : σ⁻¹ i = i' := by rw [← h_eq, h_inv_apply]
      rw [this]
      exact h_i'_in
  -- Now build a bijection between the two filters via σ⁻¹.
  apply Finset.card_bij (fun i _ => σ⁻¹ i)
  · -- Image lands in the target filter.
    intro i h_i
    simp only [Finset.mem_filter] at h_i ⊢
    refine ⟨(h_inv_iff i).mpr h_i.1, h_i.2⟩
  · -- Injective.
    intro i₁ _ i₂ _ h_eq
    -- σ⁻¹ i₁ = σ⁻¹ i₂ ⇒ i₁ = i₂ (apply σ to both sides).
    have : σ (σ⁻¹ i₁) = σ (σ⁻¹ i₂) := by rw [h_eq]
    rwa [h_apply_inv, h_apply_inv] at this
  · -- Surjective.
    intro i' h_i'
    simp only [Finset.mem_filter] at h_i'
    refine ⟨σ i', ?_, h_inv_apply i'⟩
    simp only [Finset.mem_filter]
    refine ⟨?_, ?_⟩
    · -- σ i' ∈ block j: from h_i'.1 : i' ∈ block j and image σ = block j.
      rw [← h_image_fwd]
      exact Finset.mem_image_of_mem _ h_i'.1
    · -- b (σ⁻¹ (σ i')) = true ⇔ b i' = true via h_inv_apply.
      rw [h_inv_apply]
      exact h_i'.2

/--
**Block-sum attack.** If two messages have different `blockSum`-vectors
under a block-preserving subgroup `G`, an adversary with
`hasAdvantage` exists. Direct application of `invariant_attack` with
`f := blockSum block`. -/
theorem hgoe_blockSum_attack {M : Type*} {ℓ : ℕ}
    (G : Subgroup (Equiv.Perm (Fin n))) (block : Fin ℓ → Finset (Fin n))
    (hPres : PreservesBlocks G block)
    (scheme : OrbitEncScheme (↥G) (Bitstring n) M) (m₀ m₁ : M)
    (hDiff : blockSum block (scheme.reps m₀) ≠ blockSum block (scheme.reps m₁)) :
    ∃ A : Adversary (Bitstring n) M, hasAdvantage scheme A :=
  invariant_attack scheme (blockSum block) m₀ m₁
    (blockSum_invariant_of_preservesBlocks G block hPres) hDiff

/--
**Block-sum defence.** If all message representatives have the same
`blockSum`-vector, `blockSum` cannot separate any pair: the
`IsSeparating` predicate (which requires
`blockSum b₀ ≠ blockSum b₁`) fails on coincident `blockSum` values. -/
theorem same_blockSum_not_separating {ℓ : ℕ}
    (block : Fin ℓ → Finset (Fin n))
    (b₀ b₁ : Bitstring n) (hSame : blockSum block b₀ = blockSum block b₁) :
    ¬ IsSeparating (G := Equiv.Perm (Fin n)) (blockSum block) b₀ b₁ := by
  intro ⟨_, hSep⟩
  exact hSep hSame

-- ============================================================================
-- Invariant 2 — Bit parity (XOR of all bits = hammingWeight % 2 = 1)
-- ============================================================================

/--
**Bit parity invariant.** `bitParity b = true` iff the number of `true`
bits in `b` is odd, equivalently iff `hammingWeight b % 2 = 1`. This
is an `S_n`-invariant by reduction to `hammingWeight_invariant`:
permutations preserve Hamming weight, so they preserve its parity.

**Cryptographic significance.** Bit parity is a 1-bit attack channel
that any `S_n`-respecting scheme must defend against. The
`hammingWeight_invariant` defence (selecting same-weight reps)
automatically covers parity, but a scheme that allows different
weights with the same parity defeats Hamming-weight attacks but
fails parity attacks too. Parity is *strictly weaker* than
hammingWeight; same-weight implies same-parity but not conversely.
-/
def bitParity (b : Bitstring n) : Bool :=
  decide (hammingWeight b % 2 = 1)

/--
**Bit parity is `S_n`-invariant.** Direct corollary of
`hammingWeight_invariant`: permutations preserve hammingWeight, so
they preserve any predicate built from hammingWeight (in particular
`hammingWeight % 2 = 1`).
-/
theorem bitParity_invariant :
    IsGInvariant (G := Equiv.Perm (Fin n)) (bitParity (n := n)) := by
  intro σ b
  unfold bitParity
  rw [hammingWeight_invariant σ b]

/--
**Bit parity is invariant under any subgroup of `S_n`.** Since
hammingWeight is `S_n`-invariant, its parity is too; the subgroup
inherits the invariance via the action's coercion to `Equiv.Perm`. -/
theorem bitParity_invariant_subgroup
    (G : Subgroup (Equiv.Perm (Fin n))) :
    IsGInvariant (G := ↥G) (bitParity (n := n)) := by
  intro g b
  show bitParity (g • b) = bitParity b
  rw [subgroup_smul_eq]
  exact bitParity_invariant (↑g : Equiv.Perm (Fin n)) b

/--
**Bit parity attack.** If two messages have different parities, an
adversary with `hasAdvantage` exists. -/
theorem hgoe_bitParity_attack {M : Type*}
    (G : Subgroup (Equiv.Perm (Fin n)))
    (scheme : OrbitEncScheme (↥G) (Bitstring n) M) (m₀ m₁ : M)
    (hDiff : bitParity (scheme.reps m₀) ≠ bitParity (scheme.reps m₁)) :
    ∃ A : Adversary (Bitstring n) M, hasAdvantage scheme A :=
  invariant_attack scheme (bitParity (n := n)) m₀ m₁
    (bitParity_invariant_subgroup G) hDiff

/--
**Bit parity defence.** If all message representatives have the
same parity, `bitParity` cannot separate any pair. -/
theorem same_bitParity_not_separating
    (b₀ b₁ : Bitstring n) (hSame : bitParity b₀ = bitParity b₁) :
    ¬ IsSeparating (G := Equiv.Perm (Fin n)) (bitParity (n := n)) b₀ b₁ := by
  intro ⟨_, hSep⟩
  exact hSep hSame

-- ============================================================================
-- Invariant 3 — Sorted-bits (lex-min element of the orbit, i.e. canonical form)
-- ============================================================================

/--
**Sorted-bits invariant.** The lex-min element of the orbit of `b`
under `Equiv.Perm (Fin n)`, computed via the
`bitstringLinearOrder` (matching the GAP reference implementation's
`CanonicalImage(G, x, OnSets)` convention; see
`Orbcrypt/Construction/Permutation.lean`).

This is the **canonical form** under `Equiv.Perm (Fin n)`. Because
canonical forms are by construction `G`-invariant
(`canonical_isGInvariant`), `sortedBits` is `S_n`-invariant.

**Cryptographic significance.** Sorted-bits is the *strongest*
`S_n`-invariant: it preserves the entire orbit identity. Any pair
of distinct messages whose representatives lie in different orbits
under `S_n` is broken by `sortedBits` (since distinct orbits have
distinct lex-min elements). The
`OrbitEncScheme.reps_distinct` field already prohibits the
shared-orbit case at the scheme level, so any `S_n`-respecting
HGOE scheme is *automatically broken* by the sorted-bits attack.
This is the formal version of the "deterministic OIA is vacuous"
result `det_oia_false_of_distinct_reps` (in `Crypto/OIA.lean`).

**Implementation.** `noncomputable` because `CanonicalForm.ofLexMin`
uses `Finset.min'` which requires classical reasoning to establish
non-emptiness from the orbit's membership of the basepoint. -/
noncomputable def sortedBits (b : Bitstring n) : Bitstring n :=
  letI : LinearOrder (Bitstring n) := bitstringLinearOrder
  (CanonicalForm.ofLexMin (G := Equiv.Perm (Fin n)) (X := Bitstring n)).canon b

/--
**Sorted-bits is `S_n`-invariant.** Direct corollary of
`canonical_isGInvariant`: any canonical form is invariant under
the underlying group action. -/
theorem sortedBits_invariant :
    IsGInvariant (G := Equiv.Perm (Fin n)) (sortedBits (n := n)) := by
  letI : LinearOrder (Bitstring n) := bitstringLinearOrder
  unfold sortedBits
  exact canonical_isGInvariant
    (CanonicalForm.ofLexMin (G := Equiv.Perm (Fin n)) (X := Bitstring n))

/--
**Sorted-bits is invariant under any subgroup.** Same reduction
through `subgroup_smul_eq` as `bitParity_invariant_subgroup`. -/
theorem sortedBits_invariant_subgroup
    (G : Subgroup (Equiv.Perm (Fin n))) :
    IsGInvariant (G := ↥G) (sortedBits (n := n)) := by
  intro g b
  show sortedBits (g • b) = sortedBits b
  rw [subgroup_smul_eq]
  exact sortedBits_invariant (↑g : Equiv.Perm (Fin n)) b

/--
**Sorted-bits attack.** If two messages have different sorted-bits
(lex-min) representatives, an adversary with `hasAdvantage` exists.
By `OrbitEncScheme.reps_distinct`, distinct messages have distinct
orbits, hence distinct sorted-bits — so this attack ALWAYS applies
to `S_n`-respecting schemes. The attack is the cryptographic
content of "deterministic OIA is vacuous on `S_n`-respecting
schemes". -/
theorem hgoe_sortedBits_attack {M : Type*}
    (G : Subgroup (Equiv.Perm (Fin n)))
    (scheme : OrbitEncScheme (↥G) (Bitstring n) M) (m₀ m₁ : M)
    (hDiff : sortedBits (scheme.reps m₀) ≠ sortedBits (scheme.reps m₁)) :
    ∃ A : Adversary (Bitstring n) M, hasAdvantage scheme A :=
  invariant_attack scheme (sortedBits (n := n)) m₀ m₁
    (sortedBits_invariant_subgroup G) hDiff

/--
**Sorted-bits defence.** If two bitstrings have the same sorted-bits
(lex-min) image, sortedBits cannot separate them. By the canonical-
form uniqueness `canon_eq_implies_orbit_eq`, this means they share
an orbit under `S_n`; the `OrbitEncScheme.reps_distinct` field
prohibits this for distinct messages, so any `S_n`-respecting scheme
that satisfies this hypothesis on its `reps` is *trivially*
ill-formed. The lemma exists for completeness in the catalogue
parallel to `same_blockSum_not_separating` and
`same_bitParity_not_separating`. -/
theorem same_sortedBits_not_separating
    (b₀ b₁ : Bitstring n) (hSame : sortedBits b₀ = sortedBits b₁) :
    ¬ IsSeparating (G := Equiv.Perm (Fin n)) (sortedBits (n := n)) b₀ b₁ := by
  intro ⟨_, hSep⟩
  exact hSep hSame

end Orbcrypt
