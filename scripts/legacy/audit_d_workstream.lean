/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

/-
Workstream D verification script (audit 2026-04-18, finding F-08).

Verifies the headline invariants the audit plan asks for:

 1. `#print axioms` outputs for every Workstream D headline result list
    only standard Lean axioms (`propext`, `Classical.choice`, `Quot.sound`).
    No `sorryAx`, no custom axiom.
 2. `arePermEquivalent_refl` / `_symm` / `_trans` discharge the three
    `Equivalence` obligations on a *concrete* finset family — exercising
    that the `Setoid` instance synthesises and is non-vacuous.
 3. `PAutSubgroup` is constructed with all four `Subgroup` fields; we
    exhibit that `1 ∈ PAutSubgroup C` and that the coercion to
    `Set (Equiv.Perm (Fin n))` agrees with the underlying `PAut C`
    (Workstream D2c).
 4. `permuteCodeword_self_bij_of_self_preserving` (D1a) is exercised on
    a singleton code, witnessing that the self-bijection lemma is
    inhabited and `inv_mem'` factors through it correctly (Workstream D2b).
 5. `paut_equivalence_set_eq_coset` (D3) is exercised on a singleton
    code and demonstrates the bidirectional set identity end-to-end.
 6. **Negative cardinality test (post-audit):** a concrete asymmetric
    pair `smallCode ⊊ bigCode` witnesses that the `hcard` hypothesis on
    `arePermEquivalent_symm` (D1b) is *mathematically necessary*, not an
    artefact of the proof technique — a permutation cannot inject the
    2-element `bigCode` into the 1-element `smallCode`.
 7. **`inferInstance` synthesis (post-audit):** the D4 `Setoid` instance
    resolves for multiple concrete card-indexed subtypes, confirming the
    implicit `{n} {F} {k}` signature is typeclass-resolver-friendly.
 8. **`mem_PAutSubgroup` simp firing (post-audit):** `simp only` threads
    between the `Set`-valued `PAut` and the `Subgroup`-packaged
    `PAutSubgroup` in both directions.
 9. **`paut_inv_closed` idempotence (post-audit):** applying the D2
    inverse closure twice (via `inv_inv`) returns the original element.
10. **D3 reverse-direction witness (post-audit):** σ itself (τ = 1) is
    always in its own coset, a non-vacuous test of the reverse inclusion.

Run: `source ~/.elan/env && lake env lean scripts/audit_d_workstream.lean`

Expected output:
```
'Orbcrypt.permuteCodeword_self_bij_of_self_preserving' depends on axioms: [propext, Classical.choice, Quot.sound]
'Orbcrypt.permuteCodeword_inv_mem_of_card_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'Orbcrypt.arePermEquivalent_symm' depends on axioms: [propext, Classical.choice, Quot.sound]
'Orbcrypt.arePermEquivalent_trans' depends on axioms: [propext, Classical.choice, Quot.sound]
'Orbcrypt.paut_inv_closed' depends on axioms: [propext, Classical.choice, Quot.sound]
'Orbcrypt.PAutSubgroup' depends on axioms: [propext, Classical.choice, Quot.sound]
'Orbcrypt.PAut_eq_PAutSubgroup_carrier' depends on axioms: [propext, Classical.choice, Quot.sound]
'Orbcrypt.mem_PAutSubgroup' depends on axioms: [propext, Classical.choice, Quot.sound]
'Orbcrypt.paut_equivalence_set_eq_coset' depends on axioms: [propext, Classical.choice, Quot.sound]
'Orbcrypt.arePermEquivalent_setoid' depends on axioms: [propext, Classical.choice, Quot.sound]
```
(no `sorryAx` anywhere; axiom set never includes a custom `axiom` declaration).
-/

import Orbcrypt.Hardness.CodeEquivalence

open Orbcrypt

-- ============================================================================
-- (1) Axiom transparency on every Workstream D headline result.
-- ============================================================================

#print axioms permuteCodeword_self_bij_of_self_preserving
#print axioms permuteCodeword_inv_mem_of_card_eq
#print axioms arePermEquivalent_symm
#print axioms arePermEquivalent_trans
#print axioms paut_inv_closed
#print axioms PAutSubgroup
#print axioms PAut_eq_PAutSubgroup_carrier
#print axioms mem_PAutSubgroup
#print axioms paut_equivalence_set_eq_coset
#print axioms arePermEquivalent_setoid

-- ============================================================================
-- (2) `Equivalence` obligations exercised on a concrete finset family.
-- ============================================================================
--
-- Take the singleton code `C = {0}` over `Fin 1 → Bool`. Reflexivity,
-- symmetry, and transitivity all collapse to the identity permutation.

section D1Equivalence

abbrev BoolCode (n : ℕ) := Finset (Fin n → Bool)

/-- A concrete singleton code: `{ fun _ => false }`. -/
def singletonCode : BoolCode 1 := { (fun _ : Fin 1 => false) }

example : ArePermEquivalent singletonCode singletonCode :=
  arePermEquivalent_refl _

example (h : ArePermEquivalent singletonCode singletonCode) :
    ArePermEquivalent singletonCode singletonCode :=
  arePermEquivalent_symm _ _ rfl h

example
    (h₁₂ : ArePermEquivalent singletonCode singletonCode)
    (h₂₃ : ArePermEquivalent singletonCode singletonCode) :
    ArePermEquivalent singletonCode singletonCode :=
  arePermEquivalent_trans _ _ _ h₁₂ h₂₃

end D1Equivalence

-- ============================================================================
-- (3) `PAutSubgroup` is a real `Subgroup` and its carrier is `PAut`.
-- ============================================================================

section D2Subgroup

/-- The identity permutation lies in `PAutSubgroup` of any code. -/
example (C : Finset (Fin 3 → Bool)) :
    (1 : Equiv.Perm (Fin 3)) ∈ PAutSubgroup C :=
  (PAutSubgroup C).one_mem'

/-- The carrier coincides with the `Set`-valued `PAut` (D2c). -/
example (C : Finset (Fin 3 → Bool)) :
    PAut C = ((PAutSubgroup C : Subgroup (Equiv.Perm (Fin 3))) :
        Set (Equiv.Perm (Fin 3))) :=
  PAut_eq_PAutSubgroup_carrier C

/-- `PAutSubgroup` is closed under inverses (the field discharged by D1a
    via `paut_inv_closed`). -/
example (C : Finset (Fin 3 → Bool)) (σ : Equiv.Perm (Fin 3))
    (hσ : σ ∈ PAutSubgroup C) : σ⁻¹ ∈ PAutSubgroup C :=
  (PAutSubgroup C).inv_mem' hσ

end D2Subgroup

-- ============================================================================
-- (4) D1a self-bijection lemma exercised on a singleton.
-- ============================================================================

section D1aWitness

/-- Any permutation maps `singletonCode` to itself, and so does its inverse. -/
example (σ : Equiv.Perm (Fin 1)) :
    ∀ c ∈ singletonCode, permuteCodeword σ⁻¹ c ∈ singletonCode := by
  apply permuteCodeword_self_bij_of_self_preserving
  intro c hc
  -- `Fin 1` is singleton, so any permutation acts trivially.
  have hσ : σ = 1 := Subsingleton.elim _ _
  subst hσ
  rwa [permuteCodeword_one]

end D1aWitness

-- ============================================================================
-- (5) Coset set identity (D3) exercised on the singleton code.
-- ============================================================================

section D3CosetIdentity

/-- The forward inclusion of the D3 set identity is non-vacuous: the
    identity permutation lies in the equivalence-witness set, hence in
    the coset `1 · PAut C`. -/
example :
    (1 : Equiv.Perm (Fin 1)) ∈
      ({ρ : Equiv.Perm (Fin 1) | ∃ τ ∈ PAut singletonCode, ρ = (1 : _) * τ}) := by
  -- σ = 1, hcard = rfl, so the identity is a trivial coset element.
  have hσ : ∀ c ∈ singletonCode, permuteCodeword (1 : Equiv.Perm (Fin 1)) c ∈
      singletonCode := by
    intro c hc; rwa [permuteCodeword_one]
  have hSet : {ρ : Equiv.Perm (Fin 1) | ∀ c ∈ singletonCode,
        permuteCodeword ρ c ∈ singletonCode}
      = {ρ : Equiv.Perm (Fin 1) | ∃ τ ∈ PAut singletonCode, ρ = (1 : _) * τ} :=
    paut_equivalence_set_eq_coset singletonCode singletonCode (1 : _) hσ rfl
  -- (1 : Equiv.Perm) clearly maps singletonCode → singletonCode (above).
  have h1Mem : (1 : Equiv.Perm (Fin 1)) ∈
      {ρ : Equiv.Perm (Fin 1) | ∀ c ∈ singletonCode,
        permuteCodeword ρ c ∈ singletonCode} := hσ
  exact hSet ▸ h1Mem

end D3CosetIdentity

-- ============================================================================
-- (6) Negative cardinality test: `arePermEquivalent_symm` *requires* `hcard`.
--     Without it, the relation is genuinely asymmetric.
-- ============================================================================
--
-- Take C₁ = {fun _ => false} (singleton) and C₂ = {(fun _ => false),
-- (fun _ => true)} (two elements) over `Fin 1 → Bool`. The identity
-- permutation maps C₁ into C₂, but *no* permutation maps C₂ into C₁
-- (2 elements cannot inject into 1). This witnesses that the `hcard`
-- hypothesis on `arePermEquivalent_symm` (D1b) is mathematically
-- necessary, not an artefact of the proof technique.

section NegCardTest

def smallCode : Finset (Fin 1 → Bool) := {fun _ => false}
def bigCode : Finset (Fin 1 → Bool) := {(fun _ => false), (fun _ => true)}

/-- Small ⊆ Big is permutation-equivalent via the identity. -/
example : ArePermEquivalent smallCode bigCode := by
  refine ⟨1, ?_⟩
  intro c hc
  rw [permuteCodeword_one]
  simp [smallCode, bigCode] at hc ⊢
  left
  exact hc

/-- But Big ⊇ Small is *not* permutation-equivalent — any map from Big
    to Small would have to collapse 2 distinct codewords onto 1, yet
    `permuteCodeword σ` is globally injective (via the D1 helper). -/
example : ¬ ArePermEquivalent bigCode smallCode := by
  rintro ⟨σ, hσ⟩
  have hf : permuteCodeword σ (fun _ : Fin 1 => false) ∈ smallCode :=
    hσ _ (by simp [bigCode])
  have ht : permuteCodeword σ (fun _ : Fin 1 => true) ∈ smallCode :=
    hσ _ (by simp [bigCode])
  simp [smallCode] at hf ht
  have hinj := permuteCodeword_injective (F := Bool) σ (hf.trans ht.symm)
  have hne : (fun _ : Fin 1 => false) ≠ (fun _ : Fin 1 => true) := by
    intro heq; have := congrFun heq 0; simp at this
  exact hne hinj

end NegCardTest

-- ============================================================================
-- (7) D4 `Setoid` instance synthesises via `inferInstance` on multiple
--     concrete types, confirming the implicit-parameter shape is
--     typeclass-resolver-friendly.
-- ============================================================================

section D4Synthesis

example : Setoid {C : Finset (Fin 1 → Bool) // C.card = 1} := inferInstance
example : Setoid {C : Finset (Fin 3 → Bool) // C.card = 4} := inferInstance
example : Setoid {C : Finset (Fin 10 → Bool) // C.card = 128} := inferInstance

/-- The `Setoid` relation unfolds definitionally to `ArePermEquivalent`. -/
example (C₁ C₂ : {C : Finset (Fin 3 → Bool) // C.card = 2}) :
    (C₁ ≈ C₂) ↔ ArePermEquivalent C₁.val C₂.val := Iff.rfl

end D4Synthesis

-- ============================================================================
-- (8) `mem_PAutSubgroup` simp lemma fires under `simp only`.
-- ============================================================================

section MemSimpTest

example (C : Finset (Fin 3 → Bool)) (σ : Equiv.Perm (Fin 3))
    (hσ : σ ∈ PAutSubgroup C) : σ ∈ PAut C := by
  simp only [mem_PAutSubgroup] at hσ; exact hσ

example (C : Finset (Fin 3 → Bool)) (σ : Equiv.Perm (Fin 3))
    (hσ : σ ∈ PAut C) : σ ∈ PAutSubgroup C := by
  simp only [mem_PAutSubgroup]; exact hσ

end MemSimpTest

-- ============================================================================
-- (9) `paut_inv_closed` idempotence: applying the inverse closure
--     twice (σ ↦ σ⁻¹ ↦ σ⁻¹⁻¹ = σ) returns the original element.
-- ============================================================================

section InvIdempotence

example (C : Finset (Fin 3 → Bool)) (σ : Equiv.Perm (Fin 3))
    (hσ : σ ∈ PAut C) : σ ∈ PAut C := by
  have h1 : σ⁻¹ ∈ PAut C := paut_inv_closed C σ hσ
  have h2 : σ⁻¹⁻¹ ∈ PAut C := paut_inv_closed C σ⁻¹ h1
  rw [inv_inv] at h2
  exact h2

end InvIdempotence

-- ============================================================================
-- (10) D3 reverse-direction witness: σ itself (via τ = 1) is always
--      in its own coset.
-- ============================================================================

section D3ReverseWitness

example (C₁ C₂ : Finset (Fin 3 → Bool))
    (σ : Equiv.Perm (Fin 3))
    (_hσ : ∀ c ∈ C₁, permuteCodeword σ c ∈ C₂) :
    σ ∈ ({ρ : Equiv.Perm (Fin 3) | ∃ τ ∈ PAut C₁, ρ = σ * τ}) :=
  ⟨1, paut_contains_id C₁, by rw [mul_one]⟩

end D3ReverseWitness
