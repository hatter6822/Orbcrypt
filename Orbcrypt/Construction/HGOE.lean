import Orbcrypt.Construction.Permutation
import Orbcrypt.Crypto.Security
import Orbcrypt.Theorems.Correctness
import Orbcrypt.Theorems.InvariantAttack

/-!
# Orbcrypt.Construction.HGOE

Hidden-Group Orbit Encryption (HGOE): concrete `OrbitEncScheme` instance for a
subgroup of S_n acting on bitstrings, correctness instantiation, and Hamming
weight defense (same-weight representatives defeat weight-based attacks).

## Main definitions and results

* `Orbcrypt.hgoeScheme` — concrete `OrbitEncScheme` for HGOE
* `Orbcrypt.hgoe_correctness` — correctness of HGOE (decryption inverts encryption)
* `Orbcrypt.hammingWeight_invariant_subgroup` — Hamming weight invariant under subgroups
* `Orbcrypt.hgoe_weight_attack` — Hamming weight attack when weights differ
* `Orbcrypt.same_weight_not_separating` — same-weight defense defeats Hamming attack

## References

* DEVELOPMENT.md §7.1 — Hamming weight defense
* COUNTEREXAMPLE.md — Hamming weight attack
* formalization/phases/PHASE_5_CONCRETE_CONSTRUCTION.md — work units 5.7–5.11
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
