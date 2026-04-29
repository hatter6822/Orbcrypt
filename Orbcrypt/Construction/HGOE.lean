/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.Construction.Permutation
import Orbcrypt.GroupAction.CanonicalLexMin
import Orbcrypt.Crypto.Security
import Orbcrypt.Theorems.Correctness
import Orbcrypt.Theorems.InvariantAttack

/-!
# Orbcrypt.Construction.HGOE

Hidden-Group Orbit Encryption (HGOE): concrete `OrbitEncScheme` instance for a
subgroup of S_n acting on bitstrings, correctness instantiation, and Hamming
weight defense (same-weight representatives defeat weight-based attacks).

## Main definitions and results

* `Orbcrypt.hgoeScheme` — concrete `OrbitEncScheme` for HGOE (takes a
  `CanonicalForm` parameter)
* `Orbcrypt.hgoeScheme.ofLexMin` — convenience constructor that auto-fills
  the `CanonicalForm` parameter with `CanonicalForm.ofLexMin` under the
  computable `bitstringLinearOrder` lex order (Workstream F / F4)
* `Orbcrypt.hgoe_correctness` — correctness of HGOE (decryption inverts encryption)
* `Orbcrypt.hammingWeight_invariant_subgroup` — Hamming weight invariant under subgroups
* `Orbcrypt.hgoe_weight_attack` — Hamming weight attack when weights differ
* `Orbcrypt.same_weight_not_separating` — same-weight defense defeats Hamming attack

## References

* DEVELOPMENT.md §7.1 — Hamming weight defense
* COUNTEREXAMPLE.md — Hamming weight attack
* formalization/phases/PHASE_5_CONCRETE_CONSTRUCTION.md — work units 5.7–5.11
* docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md § 9 — Workstream F
  (V1-10 / F-04): `hgoeScheme.ofLexMin` closes the concrete-canonical-form
  gap by wiring `CanonicalForm.ofLexMin` into the HGOE constructor.
-/

namespace Orbcrypt

variable {n : ℕ}

-- ============================================================================
-- Work Unit 5.7: Subgroup Action Instance
-- ============================================================================

/-- A subgroup of S_n inherits the MulAction on `Bitstring n`.
    This uses `MulAction.compHom` with the subgroup inclusion homomorphism,
    so that `(g : ↥G) • x = (↑g : Equiv.Perm (Fin n)) • x`. -/
instance subgroupBitstringAction (G : Subgroup (Equiv.Perm (Fin n))) :
    MulAction G (Bitstring n) :=
  MulAction.compHom (Bitstring n) G.subtype

/-- Subgroup action reduces to parent permutation action via coercion. -/
@[simp]
theorem subgroup_smul_eq (G : Subgroup (Equiv.Perm (Fin n)))
    (g : G) (x : Bitstring n) :
    g • x = (↑g : Equiv.Perm (Fin n)) • x := rfl

-- ============================================================================
-- Work Unit 5.8: HGOE Scheme Instance
-- ============================================================================

/-- Construct a concrete HGOE scheme from a subgroup G ≤ S_n, a canonical form,
    and orbit representatives with distinct orbits. This bridges the abstract
    `OrbitEncScheme` framework with the concrete S_n bitstring action. -/
def hgoeScheme {M : Type*}
    (G : Subgroup (Equiv.Perm (Fin n)))
    (can : CanonicalForm (↥G) (Bitstring n))
    (reps : M → Bitstring n)
    (hDistinct : ∀ m₁ m₂ : M, m₁ ≠ m₂ →
      MulAction.orbit (↥G) (reps m₁) ≠ MulAction.orbit (↥G) (reps m₂)) :
    OrbitEncScheme (↥G) (Bitstring n) M where
  reps := reps
  reps_distinct := hDistinct
  canonForm := can

/-- Convenience constructor: HGOE scheme whose `CanonicalForm` is the
    lex-min canonical form under Orbcrypt's `bitstringLinearOrder`,
    **matching the GAP reference implementation's choice of orbit
    representative exactly**.

    The GAP prototype in `implementation/gap/orbcrypt_kem.g` invokes
    `CanonicalImage(G, support_set, OnSets)` from the GAP `images`
    package. That returns the lex-minimum support-set representation
    under GAP's set ordering: sorted ascending element lists compared
    element-wise, with smaller-position-true winning. The Lean
    `bitstringLinearOrder` is constructed (via the inverted-Bool
    composition `List.ofFn ∘ (! ∘ ·)`) to match this convention
    point-for-point: for every orbit `O` under any subgroup
    `G ≤ S_n`, `CanonicalForm.ofLexMin.canon` and GAP's
    `CanonicalImage` pick the *same* element of `O` as the canonical
    representative. This means the Lean specification of HGOE
    encryption / decryption now formally specifies the GAP reference
    implementation's pipeline (modulo abstract layers like
    `keyDerive`), not merely *a* valid HGOE instantiation.

    Requires `[Fintype ↥G]` (the ambient group is finite, so the orbit
    is a `Fintype`) and `[DecidableEq (Bitstring n)]` (automatic for
    `Fin n → Bool`). Registers `bitstringLinearOrder` locally via
    `letI`, so callers needn't bring the `LinearOrder` themselves and
    the global `Pi.partialOrder` diamond is not activated.

    Closes audit finding V1-10 / F-04 (Workstream F of the 2026-04-23
    audit): `hgoeScheme`'s previously-abstract `CanonicalForm`
    parameter now has a concrete in-tree witness at every finite
    subgroup of `Equiv.Perm (Fin n)` — and that witness matches the
    GAP reference implementation's canonical-form choice. -/
def hgoeScheme.ofLexMin {M : Type*}
    (G : Subgroup (Equiv.Perm (Fin n))) [Fintype (↥G)]
    (reps : M → Bitstring n)
    (hDistinct : ∀ m₁ m₂ : M, m₁ ≠ m₂ →
      MulAction.orbit (↥G) (reps m₁) ≠ MulAction.orbit (↥G) (reps m₂)) :
    OrbitEncScheme (↥G) (Bitstring n) M :=
  letI : LinearOrder (Bitstring n) := bitstringLinearOrder
  hgoeScheme G (CanonicalForm.ofLexMin (G := ↥G) (X := Bitstring n))
    reps hDistinct

/-- `hgoeScheme.ofLexMin` preserves the `reps` field of its input — the
    canonical form is auto-filled without altering the representative
    assignment. A structural sanity lemma that consumers can reach
    for when threading `reps` through downstream invariant or attack
    proofs built on top of `ofLexMin`. -/
@[simp]
theorem hgoeScheme.ofLexMin_reps {M : Type*}
    (G : Subgroup (Equiv.Perm (Fin n))) [Fintype (↥G)]
    (reps : M → Bitstring n)
    (hDistinct : ∀ m₁ m₂ : M, m₁ ≠ m₂ →
      MulAction.orbit (↥G) (reps m₁) ≠ MulAction.orbit (↥G) (reps m₂)) :
    (hgoeScheme.ofLexMin G reps hDistinct).reps = reps := rfl

-- ============================================================================
-- Work Unit 5.9: HGOE Correctness Instantiation
-- ============================================================================

/-- Correctness of HGOE: decryption inverts encryption.
    Direct application of the abstract correctness theorem (Phase 4, unit 4.5).
    Demonstrates that the abstract theorem cleanly specializes to the concrete
    S_n bitstring construction. -/
theorem hgoe_correctness {M : Type*} [Fintype M] [DecidableEq M]
    (G : Subgroup (Equiv.Perm (Fin n)))
    (scheme : OrbitEncScheme (↥G) (Bitstring n) M)
    (m : M) (g : ↥G) :
    decrypt scheme (encrypt scheme g m) = some m :=
  correctness scheme m g

-- ============================================================================
-- Work Unit 5.10: Weight Attack Instantiation
-- ============================================================================

/-- Hamming weight is invariant under any subgroup of S_n.
    This follows because the subgroup action is defined via coercion to S_n,
    and Hamming weight is invariant under the full S_n action.

    **Style note (audit 2026-04-21 finding L6 / Workstream M).** The
    subgroup element is introduced with a plain binder `g` and coerced
    to `Equiv.Perm (Fin n)` via `↑g`. The earlier form used the
    anonymous destructuring pattern `⟨σ, _⟩`, which silently discarded
    the membership proof `hσ : σ ∈ G`; the new form names `g`
    explicitly and relies on the `subgroupBitstringAction` instance
    (defined above) to transport the action through the subgroup
    inclusion `G.subtype`. The two forms are proof-equivalent; the
    current form is the Mathlib-idiomatic style. -/
theorem hammingWeight_invariant_subgroup
    (G : Subgroup (Equiv.Perm (Fin n))) :
    IsGInvariant (G := ↥G) (hammingWeight (n := n)) := by
  intro g x
  exact hammingWeight_invariant (↑g : Equiv.Perm (Fin n)) x

/-- Hamming weight IS a valid attack when representatives have different weights.
    Formalizes the counterexample from COUNTEREXAMPLE.md: if
    `wt(x_{m₀}) ≠ wt(x_{m₁})`, the scheme is completely broken.
    Applies the abstract invariant attack theorem (Phase 4, unit 4.9)
    with `f := hammingWeight`. -/
theorem hgoe_weight_attack {M : Type*}
    (G : Subgroup (Equiv.Perm (Fin n)))
    (scheme : OrbitEncScheme (↥G) (Bitstring n) M)
    (m₀ m₁ : M)
    (hDiffWeight : hammingWeight (scheme.reps m₀) ≠
                   hammingWeight (scheme.reps m₁)) :
    ∃ A : Adversary (Bitstring n) M, hasAdvantage scheme A :=
  invariant_attack scheme (fun x => hammingWeight x)
    m₀ m₁ (hammingWeight_invariant_subgroup G) hDiffWeight

-- ============================================================================
-- Work Unit 5.11: Same-Weight Defense Lemma
-- ============================================================================

/-- When all representatives have the same Hamming weight, the weight function
    cannot separate any pair of messages. This is the formal defense from
    DEVELOPMENT.md §7.1: choosing all orbit representatives with the same
    Hamming weight `w = ⌊n/2⌋` defeats the Hamming weight attack.

    **Proof strategy:** `IsSeparating` requires `f(reps m₀) ≠ f(reps m₁)`,
    but `hSameWeight` gives both equal to `w`, yielding a contradiction. -/
theorem same_weight_not_separating {M : Type*}
    (G : Subgroup (Equiv.Perm (Fin n)))
    (reps : M → Bitstring n)
    (w : ℕ)
    (hSameWeight : ∀ m : M, hammingWeight (reps m) = w)
    (m₀ m₁ : M) :
    ¬ IsSeparating (G := ↥G) (hammingWeight (n := n))
      (reps m₀) (reps m₁) := by
  intro ⟨_, hSep⟩
  exact hSep (by rw [hSameWeight m₀, hSameWeight m₁])

end Orbcrypt
