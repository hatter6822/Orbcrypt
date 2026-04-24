/-
Workstream E verification script (audit 2026-04-18 + 2026-04-20 follow-up,
findings F-01, F-10, F-11, F-17, F-20).

This file exercises every Workstream E headline result in two ways:

**Part 1 — Axiom transparency.** `#print axioms <lemma>` for every
headline theorem. The expected output is that every line lists only
the standard Lean axioms (`propext`, `Classical.choice`, `Quot.sound`)
or nothing. Any `sorryAx` or custom axiom is a review-blocking
regression.

**Part 2 — Concrete pressure tests.** Each test exercises a specific
result on a concrete instance to confirm the definition is not only
axiom-clean but also *non-vacuous* and *correctly typed*. Pressure
tests appear as `example :=` bindings below so type-checking the file
is equivalent to exercising each case.

Run: `source ~/.elan/env && lake env lean scripts/audit_e_workstream.lean`
-/

import Orbcrypt

open Orbcrypt PMF ENNReal

-- ============================================================================
-- Part 1: axiom dumps (one line per Workstream-E headline result)
-- ============================================================================

section WorkstreamE_AxiomChecks

-- E1
#print axioms Orbcrypt.kemEncapsDist_support
#print axioms Orbcrypt.kemEncapsDist_pos_of_reachable
#print axioms Orbcrypt.concreteKEMOIA_one
#print axioms Orbcrypt.concreteKEMOIA_mono
#print axioms Orbcrypt.concreteKEMOIA_uniform_one
#print axioms Orbcrypt.concreteKEMOIA_uniform_mono
#print axioms Orbcrypt.det_kemoia_implies_concreteKEMOIA_zero
#print axioms Orbcrypt.concrete_kemoia_implies_secure
#print axioms Orbcrypt.concrete_kemoia_uniform_implies_secure

-- E2
#print axioms Orbcrypt.concreteCEOIA_one
#print axioms Orbcrypt.concreteCEOIA_mono
#print axioms Orbcrypt.concreteTensorOIA_one
#print axioms Orbcrypt.concreteTensorOIA_mono
#print axioms Orbcrypt.concreteGIOIA_one
#print axioms Orbcrypt.concreteGIOIA_mono

-- E3
#print axioms Orbcrypt.concreteTensorOIAImpliesConcreteCEOIA_one_one
#print axioms Orbcrypt.concreteCEOIAImpliesConcreteGIOIA_one_one
#print axioms Orbcrypt.concreteGIOIAImpliesConcreteOIA_one_one
#print axioms Orbcrypt.concrete_chain_zero_compose

-- Workstream G (audit 2026-04-21, H1): Fix B surrogate
#print axioms Orbcrypt.SurrogateTensor
#print axioms Orbcrypt.punitSurrogate

-- Workstream G: Fix C per-encoding reduction Props + _one_one witnesses
#print axioms Orbcrypt.ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding
#print axioms Orbcrypt.ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding
#print axioms Orbcrypt.ConcreteGIOIAImpliesConcreteOIA_viaEncoding
#print axioms Orbcrypt.concreteTensorOIAImpliesConcreteCEOIA_viaEncoding_one_one
#print axioms Orbcrypt.concreteCEOIAImpliesConcreteGIOIA_viaEncoding_one_one
#print axioms Orbcrypt.concreteGIOIAImpliesConcreteOIA_viaEncoding_one_one

-- E4
#print axioms Orbcrypt.ConcreteHardnessChain.concreteOIA_from_chain
#print axioms Orbcrypt.ConcreteHardnessChain.tight
#print axioms Orbcrypt.ConcreteHardnessChain.tight_one_exists

-- E5
#print axioms Orbcrypt.concrete_hardness_chain_implies_1cpa_advantage_bound

-- E6
#print axioms Orbcrypt.concrete_combiner_advantage_bounded_by_oia
#print axioms Orbcrypt.combinerOrbitDist_mass_bounds

-- E7
#print axioms Orbcrypt.uniformPMFTuple_apply
#print axioms Orbcrypt.mem_support_uniformPMFTuple

-- E8
#print axioms Orbcrypt.hybrid_argument_uniform
#print axioms Orbcrypt.indQCPAAdvantage_nonneg
#print axioms Orbcrypt.indQCPAAdvantage_le_one
-- Renamed by Workstream C (audit 2026-04-23, V1-8 / C-13) to surface
-- the `h_step` user-supplied hypothesis in the identifier.
#print axioms Orbcrypt.indQCPA_from_perStepBound
#print axioms Orbcrypt.indQCPA_from_perStepBound_recovers_single_query

-- E3-prep
#print axioms Orbcrypt.identityEncoding

end WorkstreamE_AxiomChecks

-- ============================================================================
-- Part 2: concrete pressure tests
-- ============================================================================

section WorkstreamE_ConcreteTests

-- ----------------------------------------------------------------------------
-- E1 concrete tests: ConcreteKEMOIA (point-mass) trivial cases
-- ----------------------------------------------------------------------------

-- ConcreteKEMOIA_one is discharged on any OrbitKEM; exhibit a trivial KEM.
example : True := trivial  -- placeholder (concrete KEM instance is heavy)

-- The point-mass form is monotone — at ε = 1/2 implies at ε = 1 (trivial).
-- This exercises concreteKEMOIA_mono at the Prop level.
example (G X K : Type*) [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X] (kem : OrbitKEM G X K) :
    ConcreteKEMOIA kem 1 :=
  concreteKEMOIA_one kem

example (G X K : Type*) [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X] (kem : OrbitKEM G X K)
    (hHalf : ConcreteKEMOIA kem (1/2)) :
    ConcreteKEMOIA kem 1 :=
  concreteKEMOIA_mono kem (by norm_num : (1 : ℝ)/2 ≤ 1) hHalf

-- The uniform form is also monotone and inhabited at 1.
example (G X K : Type*) [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X] (kem : OrbitKEM G X K) :
    ConcreteKEMOIA_uniform kem 1 :=
  concreteKEMOIA_uniform_one kem

-- The security reduction fires at ε = 1 (trivial but well-typed).
example (G X K : Type*) [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X] (kem : OrbitKEM G X K)
    (A : KEMAdversary X K) (g₀ g₁ : G) :
    kemAdvantage kem A g₀ g₁ ≤ 1 :=
  concrete_kemoia_implies_secure kem 1 (concreteKEMOIA_one kem) A g₀ g₁

-- Uniform-form KEM security reduction: post-audit addition. Fires at
-- ε = 1 against the genuinely ε-smooth `ConcreteKEMOIA_uniform` hypothesis.
example (G X K : Type*) [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X] (kem : OrbitKEM G X K)
    (A : KEMAdversary X K) (g_ref : G) :
    kemAdvantage_uniform kem A g_ref ≤ 1 :=
  concrete_kemoia_uniform_implies_secure kem 1
    (concreteKEMOIA_uniform_one kem) A g_ref

-- Uniform-form monotonicity chain: ε = 1/3 → ε = 1.
example (G X K : Type*) [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X] (kem : OrbitKEM G X K)
    (hOIA : ConcreteKEMOIA_uniform kem (1/3)) :
    ConcreteKEMOIA_uniform kem 1 :=
  concreteKEMOIA_uniform_mono kem (by norm_num : (1 : ℝ)/3 ≤ 1) hOIA

-- ----------------------------------------------------------------------------
-- E2 concrete tests: each hardness-OIA variant is inhabited at ε = 1 on
-- concrete instances.
-- ----------------------------------------------------------------------------

-- ConcreteCEOIA at ε = 1 over F = Bool on empty 0-codes.
example : ConcreteCEOIA (F := Bool) (∅ : Finset (Fin 0 → Bool)) ∅ 1 :=
  concreteCEOIA_one ∅ ∅

-- ConcreteGIOIA at ε = 1 on trivial 0-vertex graphs.
example : ConcreteGIOIA (n := 0) (fun _ _ => true) (fun _ _ => true) 1 :=
  concreteGIOIA_one _ _

-- ConcreteTensorOIA needs a surrogate finite group. Post-Workstream-G
-- this surrogate is bundled in `SurrogateTensor F`; here we exercise
-- the underlying `ConcreteTensorOIA` directly with the `punitSurrogate`'s
-- carrier. The trivial PUnit action on a tensor type resolves via the
-- surrogate's `action` instance.
example (T₀ T₁ : Tensor3 3 Bool) :
    ConcreteTensorOIA (G_TI := (punitSurrogate Bool).carrier) T₀ T₁ 1 :=
  concreteTensorOIA_one T₀ T₁

-- ----------------------------------------------------------------------------
-- E3 concrete tests: reduction Props at (1, 1)
--
-- **Post-Workstream-G.** The universal→universal Props
-- (`ConcreteTensorOIAImpliesConcreteCEOIA` etc.) are retained as
-- derived corollaries; the primary per-encoding forms
-- (`*_viaEncoding`) are exercised alongside. Both `_one_one` witnesses
-- must be axiom-free.
-- ----------------------------------------------------------------------------

-- Legacy universal→universal form (threaded through the punit surrogate).
example : ConcreteTensorOIAImpliesConcreteCEOIA (F := Bool) (punitSurrogate Bool) 1 1 :=
  concreteTensorOIAImpliesConcreteCEOIA_one_one (punitSurrogate Bool)

example : ConcreteCEOIAImpliesConcreteGIOIA (F := Bool) 1 1 :=
  concreteCEOIAImpliesConcreteGIOIA_one_one

-- Workstream G / Fix C per-encoding forms. Each takes an explicit
-- encoder function as a parameter; the `_one_one` witness fires
-- trivially because the conclusion `Concrete*OIA _ _ 1` is always
-- true.
example {n m : ℕ} (enc : Tensor3 n Bool → Finset (Fin m → Bool)) :
    ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding
      (punitSurrogate Bool) enc 1 1 :=
  concreteTensorOIAImpliesConcreteCEOIA_viaEncoding_one_one
    (punitSurrogate Bool) enc

example {m k : ℕ} (enc : Finset (Fin m → Bool) → (Fin k → Fin k → Bool)) :
    ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding (F := Bool) enc 1 1 :=
  concreteCEOIAImpliesConcreteGIOIA_viaEncoding_one_one (F := Bool) enc

example (G X M : Type*)
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) {nT mC kG : ℕ}
    (encTC : Tensor3 nT Bool → Finset (Fin mC → Bool))
    (encCG : Finset (Fin mC → Bool) → (Fin kG → Fin kG → Bool)) :
    ConcreteGIOIAImpliesConcreteOIA_viaEncoding
      scheme encTC encCG 1 1 :=
  concreteGIOIAImpliesConcreteOIA_viaEncoding_one_one
    scheme encTC encCG

-- `concrete_chain_zero_compose` exercises the full chain composition at
-- ε = 0 under a *universal* TensorOIA hypothesis at 0. Universal
-- TensorOIA S 0 is false in general (distinguisher advantage can be > 0
-- for non-isomorphic tensors), so we can't discharge it here; we
-- instead confirm the theorem type-checks and the three reduction Props
-- at (0, 0) can be abstractly composed under a chosen surrogate.
example (G X M : Type*)
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (S : SurrogateTensor Bool)
    (hT : UniversalConcreteTensorOIA (F := Bool) S 0)
    (h₁ : ConcreteTensorOIAImpliesConcreteCEOIA (F := Bool) S 0 0)
    (h₂ : ConcreteCEOIAImpliesConcreteGIOIA (F := Bool) 0 0)
    (h₃ : ConcreteGIOIAImpliesConcreteOIA scheme 0 0) :
    ConcreteOIA scheme 0 :=
  concrete_chain_zero_compose scheme S hT h₁ h₂ h₃

-- ----------------------------------------------------------------------------
-- E4 / Workstream G concrete tests: ConcreteHardnessChain non-vacuity
-- at ε = 1 with the surrogate + trivial-encoder construction
-- ----------------------------------------------------------------------------

-- Post-Workstream-G, the chain binds `SurrogateTensor` in its signature.
-- `tight_one_exists` inhabits the chain at ε = 1 with the `punitSurrogate`
-- and dimension-0 trivial encoders.
example (G X M : Type*)
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) :
    Nonempty (ConcreteHardnessChain scheme Bool (punitSurrogate Bool) 1) :=
  ConcreteHardnessChain.tight_one_exists scheme Bool

-- From the chain, we obtain ConcreteOIA scheme 1 (trivial but structural).
example (G X M : Type*)
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) :
    ConcreteOIA scheme 1 :=
  let ⟨hc⟩ := ConcreteHardnessChain.tight_one_exists scheme Bool
  ConcreteHardnessChain.concreteOIA_from_chain hc

-- ----------------------------------------------------------------------------
-- Workstream G audit follow-up pressure tests:
-- Exercise the chain with a **non-PUnit surrogate** AND **non-zero
-- dimensions** to ensure the surrogate binding + per-encoding composition
-- work outside the tight_one_exists degenerate case.
-- ----------------------------------------------------------------------------

/-- Custom non-PUnit surrogate: `Equiv.Perm (Fin 2)` (the 2-element
    symmetric group) acting trivially on tensors. This is a
    non-degenerate choice of `SurrogateTensor` — the carrier group
    has 2 elements rather than 1. The action is trivial (identity on
    tensors) so advantage-bound claims still discharge at ε = 1 via
    `concreteTensorOIA_one`, but the surrogate binding is exercised
    with a different carrier type than `punitSurrogate`. -/
private def permTwoSurrogate (F : Type*) : SurrogateTensor F where
  carrier := Equiv.Perm (Fin 2)
  groupInst := inferInstance
  fintypeInst := inferInstance
  nonemptyInst := inferInstance
  action := fun _ =>
    { smul := fun _ T => T
      one_smul := fun _ => rfl
      mul_smul := fun _ _ _ => rfl }

-- Tensor-OIA with the permTwoSurrogate carrier fires at ε = 1.
example (T₀ T₁ : Tensor3 2 Bool) :
    ConcreteTensorOIA (G_TI := (permTwoSurrogate Bool).carrier) T₀ T₁ 1 :=
  concreteTensorOIA_one T₀ T₁

-- `UniversalConcreteTensorOIA` at ε = 1 under the permTwoSurrogate.
example : UniversalConcreteTensorOIA (F := Bool) (permTwoSurrogate Bool) 1 :=
  fun T₀ T₁ => concreteTensorOIA_one T₀ T₁

-- Tight constructor at non-zero dimensions. Use nT = 1, mC = 2, kG = 3
-- with arbitrary encoders; at ε = 1 all per-encoding Props discharge
-- via the _one_one witnesses.
example (G X M : Type*)
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) :
    ConcreteHardnessChain scheme Bool (permTwoSurrogate Bool) 1 :=
  let encTC : Tensor3 1 Bool → Finset (Fin 2 → Bool) := fun _ => ∅
  let encCG : Finset (Fin 2 → Bool) → (Fin 3 → Fin 3 → Bool) :=
    fun _ _ _ => false
  ConcreteHardnessChain.tight (S := permTwoSurrogate Bool)
    (nT := 1) (mC := 2) (kG := 3)
    (encTC := encTC)
    (encCG := encCG)
    (h_tensor := fun T₀ T₁ => concreteTensorOIA_one T₀ T₁)
    (h_tc := concreteTensorOIAImpliesConcreteCEOIA_viaEncoding_one_one
      (permTwoSurrogate Bool) encTC)
    (h_cg := concreteCEOIAImpliesConcreteGIOIA_viaEncoding_one_one
      (F := Bool) encCG)
    (h_go := concreteGIOIAImpliesConcreteOIA_viaEncoding_one_one
      scheme encTC encCG)

-- `concreteOIA_from_chain` composes end-to-end even at non-zero
-- dimensions; the output `ConcreteOIA scheme 1` is still trivial (ε = 1)
-- but the composition itself threads through each of tensor_hard →
-- tensor_to_ce → ce_to_gi → gi_to_oia.
example (G X M : Type*)
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) :
    ConcreteOIA scheme 1 := by
  let encTC : Tensor3 1 Bool → Finset (Fin 2 → Bool) := fun _ => ∅
  let encCG : Finset (Fin 2 → Bool) → (Fin 3 → Fin 3 → Bool) :=
    fun _ _ _ => false
  let hc : ConcreteHardnessChain scheme Bool (permTwoSurrogate Bool) 1 :=
    ConcreteHardnessChain.tight (S := permTwoSurrogate Bool)
      (nT := 1) (mC := 2) (kG := 3)
      (encTC := encTC) (encCG := encCG)
      (h_tensor := fun T₀ T₁ => concreteTensorOIA_one T₀ T₁)
      (h_tc := concreteTensorOIAImpliesConcreteCEOIA_viaEncoding_one_one _ _)
      (h_cg := concreteCEOIAImpliesConcreteGIOIA_viaEncoding_one_one _)
      (h_go := concreteGIOIAImpliesConcreteOIA_viaEncoding_one_one _ _ _)
  exact ConcreteHardnessChain.concreteOIA_from_chain hc

-- `concrete_hardness_chain_implies_1cpa_advantage_bound` with the
-- non-PUnit surrogate at non-zero dimensions still bounds IND-1-CPA
-- advantage by ε = 1.
example (G X M : Type*)
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) :
    indCPAAdvantage scheme A ≤ 1 := by
  let encTC : Tensor3 1 Bool → Finset (Fin 2 → Bool) := fun _ => ∅
  let encCG : Finset (Fin 2 → Bool) → (Fin 3 → Fin 3 → Bool) :=
    fun _ _ _ => false
  let hc : ConcreteHardnessChain scheme Bool (permTwoSurrogate Bool) 1 :=
    ConcreteHardnessChain.tight (S := permTwoSurrogate Bool)
      (nT := 1) (mC := 2) (kG := 3)
      (encTC := encTC) (encCG := encCG)
      (h_tensor := fun T₀ T₁ => concreteTensorOIA_one T₀ T₁)
      (h_tc := concreteTensorOIAImpliesConcreteCEOIA_viaEncoding_one_one _ _)
      (h_cg := concreteCEOIAImpliesConcreteGIOIA_viaEncoding_one_one _)
      (h_go := concreteGIOIAImpliesConcreteOIA_viaEncoding_one_one _ _ _)
  exact concrete_hardness_chain_implies_1cpa_advantage_bound scheme 1 hc A

-- Exercise the per-encoding Props on a non-trivial encoder that
-- actually depends on its input (not a constant). This confirms the
-- Prop's hypothesis-consumption matches its signature and is not
-- inadvertently dropping the encoder argument.
example :
    ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding
      (punitSurrogate Bool)
      (fun T : Tensor3 1 Bool =>
        ({fun _ => T 0 0 0} : Finset (Fin 1 → Bool)))
      1 1 :=
  fun _ _ _ => concreteCEOIA_one _ _

example :
    ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding (F := Bool)
      (fun C : Finset (Fin 1 → Bool) =>
        fun (_ : Fin 2) (_ : Fin 2) => decide (C.card = 0))
      1 1 :=
  fun _ _ _ => concreteGIOIA_one _ _

-- ----------------------------------------------------------------------------
-- E5 concrete test: IND-1-CPA bound from chain at ε = 1
-- ----------------------------------------------------------------------------

example (G X M : Type*)
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) :
    indCPAAdvantage scheme A ≤ 1 :=
  let ⟨hc⟩ := ConcreteHardnessChain.tight_one_exists scheme Bool
  concrete_hardness_chain_implies_1cpa_advantage_bound scheme 1 hc A

-- ----------------------------------------------------------------------------
-- E6 concrete test: combiner advantage bounded by ConcreteOIA at ε = 1
-- ----------------------------------------------------------------------------

example (G X M : Type*)
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (comb : GEquivariantCombiner G X (scheme.reps m_bp))
    (m₀ m₁ : M) :
    combinerDistinguisherAdvantage scheme m_bp comb m₀ m₁ ≤ 1 :=
  concrete_combiner_advantage_bounded_by_oia scheme m_bp comb 1
    (concreteOIA_one scheme) m₀ m₁

-- ----------------------------------------------------------------------------
-- E7 concrete test: uniformPMFTuple mass formula on Fin 3 → Bool (8 tuples)
-- ----------------------------------------------------------------------------

example (f : Fin 3 → Bool) :
    uniformPMFTuple Bool 3 f = ((Fintype.card Bool) ^ 3 : ℝ≥0∞)⁻¹ :=
  uniformPMFTuple_apply 3 f

-- Numerically: Fintype.card Bool = 2, so mass = 1/8. Exhibit the
-- equality at the ENNReal level.
example (f : Fin 3 → Bool) :
    uniformPMFTuple Bool 3 f = (8 : ℝ≥0∞)⁻¹ := by
  rw [uniformPMFTuple_apply]
  norm_num

-- ----------------------------------------------------------------------------
-- E8 concrete test: hybrid_argument_uniform at Q = 0 (vacuous bound)
-- ----------------------------------------------------------------------------

-- At Q = 0, hybrid_argument_uniform gives advantage(H₀, H₀) ≤ 0 * ε = 0,
-- which is trivially true because advantage is zero on any distribution
-- against itself. This exercises the base case of the uniform hybrid.
example {α : Type*} (hybrids : ℕ → PMF α) (D : α → Bool) (ε : ℝ) :
    advantage D (hybrids 0) (hybrids 0) ≤ (0 : ℕ) * ε :=
  hybrid_argument_uniform 0 hybrids D ε (fun i hi => absurd hi (Nat.not_lt_zero i))

-- At Q = 2 with each step ≤ ε, total advantage ≤ 2 * ε.
example {α : Type*} (hybrids : ℕ → PMF α) (D : α → Bool) (ε : ℝ)
    (h₀ : advantage D (hybrids 0) (hybrids 1) ≤ ε)
    (h₁ : advantage D (hybrids 1) (hybrids 2) ≤ ε) :
    advantage D (hybrids 0) (hybrids 2) ≤ (2 : ℕ) * ε :=
  hybrid_argument_uniform 2 hybrids D ε (fun i hi => by
    interval_cases i
    · exact h₀
    · exact h₁)

-- indQCPAAdvantage is bounded by 1 on any adversary (exercising the le_one
-- bound).
example (G X M : Type*)
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    {Q : ℕ}
    (scheme : OrbitEncScheme G X M) (A : MultiQueryAdversary X M Q) :
    indQCPAAdvantage scheme A ≤ 1 :=
  indQCPAAdvantage_le_one scheme A

-- ----------------------------------------------------------------------------
-- E3-prep concrete test: identityEncoding discharges preserves + reflects
-- ----------------------------------------------------------------------------

example {α A : Type*} [Group A] [MulAction A α] :
    OrbitPreservingEncoding α α A A :=
  identityEncoding

-- Exhibit that identityEncoding's `preserves` field is a genuine proof
-- term (not `sorry`): it's just the identity on the hypothesis.
example {α A : Type*} [Group A] [MulAction A α] (x y : α)
    (h : ∃ a : A, a • x = y) :
    ∃ b : A, b • (identityEncoding (α := α) (A := A)).encode x =
      (identityEncoding (α := α) (A := A)).encode y :=
  (identityEncoding (α := α) (A := A)).preserves x y h

end WorkstreamE_ConcreteTests
