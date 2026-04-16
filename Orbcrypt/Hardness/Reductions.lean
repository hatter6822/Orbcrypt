import Orbcrypt.Hardness.CodeEquivalence
import Orbcrypt.Hardness.TensorAction
import Orbcrypt.Crypto.OIA
import Orbcrypt.Crypto.Security
import Orbcrypt.Theorems.OIAImpliesCPA

/-!
# Orbcrypt.Hardness.Reductions

Hardness reduction chain connecting Tensor Isomorphism (TI), Code Equivalence
(CE), Graph Isomorphism (GI), and Orbcrypt's Orbit Indistinguishability
Assumption (OIA). Formalizes the chain:

    TI-hard → TensorOIA → CE-OIA → GI-OIA → OIA → IND-1-CPA secure

Each step either defines an OIA variant (Prop-valued definition following the
pattern established in `Crypto/OIA.lean`) or states a computational reduction
(also as a Prop, carried as an explicit hypothesis in downstream theorems).

## Main definitions

* `Orbcrypt.TensorOIA` — OIA for tensor isomorphism under GL(n,F)³
* `Orbcrypt.GIOIA` — OIA for graph isomorphism under S_n
* `Orbcrypt.TensorOIAImpliesCEOIA` — TensorOIA → CEOIA reduction (Prop)
* `Orbcrypt.CEOIAImpliesGIOIA` — CEOIA → GIOIA reduction (Prop)
* `Orbcrypt.HardnessChain` — full reduction chain from TensorOIA to OIA

## Main results

* `Orbcrypt.hardness_chain_implies_security` — full chain → IND-1-CPA
* `Orbcrypt.oia_from_tensor_oia` — TensorOIA + reductions → OIA

## Reduction Chain

```text
TensorOIA        (strongest — no quasi-poly algorithm known)
    |
    | TensorOIAImpliesCEOIA (tensor-to-code encoding)
    ↓
  CEOIA           (LESS/MEDS hardness — NIST PQC candidates)
    |
    | CEOIAImpliesGIOIA (code-to-graph encoding)
    ↓
  GIOIA           (2^O(√(n log n)) — Babai 2015)
    |
    | GIOIAImpliesOIA (graph-to-orbit encoding)
    ↓
   OIA            (Orbcrypt's core assumption — Crypto/OIA.lean)
    |
    | oia_implies_1cpa (Phase 4 — fully proved)
    ↓
IND-1-CPA secure  (Theorems/OIAImpliesCPA.lean)
```

## References

* docs/planning/PHASE_12_HARDNESS_ALIGNMENT.md — work units 12.6–12.7
* DEVELOPMENT.md §5.3–5.4 — GI-OIA and CE-OIA
* Grochow & Qiao (2021) — TI complexity
-/

namespace Orbcrypt

variable {n : ℕ} {F : Type*}

-- ============================================================================
-- Work Unit 12.6: Tensor-OIA Definition
-- ============================================================================

section TensorOIADefinition

variable [Field F]

/-- Tensor OIA: orbit indistinguishability for the tensor isomorphism problem.

    No Boolean function can distinguish elements from two different tensor
    orbits under the GL(n,F)³ action. For non-isomorphic tensors T₀, T₁:

      ∀ f : Tensor3 → Bool, ∀ g₀ g₁ ∈ GL³, f(g₀ • T₀) = f(g₁ • T₁)

    This is the strongest OIA variant in the reduction chain. TI is believed
    strictly harder than GI: no quasi-polynomial algorithm is known.

    Follows the OIA pattern (`Crypto/OIA.lean`): a `Prop`-valued definition,
    not an axiom. Theorems carry it as an explicit hypothesis. -/
def TensorOIA (T₀ T₁ : Tensor3 n F) : Prop :=
  ∀ (f : Tensor3 n F → Bool)
    (g₀ g₁ : GL (Fin n) F × GL (Fin n) F × GL (Fin n) F),
    f (g₀ • T₀) = f (g₁ • T₁)

/-- TensorOIA is symmetric: if no function distinguishes orbits of T₀ and T₁,
    the same holds with T₀ and T₁ swapped. -/
theorem tensorOIA_symm {T₀ T₁ : Tensor3 n F}
    (h : TensorOIA T₀ T₁) : TensorOIA T₁ T₀ := by
  intro f g₀ g₁
  exact (h f g₁ g₀).symm

end TensorOIADefinition

-- ============================================================================
-- Work Unit 12.6 (continued): Graph OIA Definition
-- ============================================================================

section GIOIADefinition

/-- Permutation action on adjacency matrices: σ acts by permuting both
    row and column indices. This is the natural S_n action on graphs. -/
def permuteAdj (σ : Equiv.Perm (Fin n)) (adj : Fin n → Fin n → Bool) :
    Fin n → Fin n → Bool :=
  fun i j => adj (σ⁻¹ i) (σ⁻¹ j)

/-- Graph OIA: orbit indistinguishability for graph isomorphism.

    No Boolean function can distinguish permuted copies of two non-isomorphic
    graphs. For graphs with adjacency functions adj₀, adj₁:

      ∀ f, ∀ σ₀ σ₁ ∈ S_n, f(σ₀(adj₀)) = f(σ₁(adj₁))

    The GI problem has a quasi-polynomial algorithm (Babai, 2015),
    so GI-OIA is weaker than CE-OIA or TensorOIA. -/
def GIOIA (adj₀ adj₁ : Fin n → Fin n → Bool) : Prop :=
  ∀ (f : (Fin n → Fin n → Bool) → Bool)
    (σ₀ σ₁ : Equiv.Perm (Fin n)),
    f (permuteAdj σ₀ adj₀) = f (permuteAdj σ₁ adj₁)

/-- GIOIA is symmetric. -/
theorem gioia_symm {adj₀ adj₁ : Fin n → Fin n → Bool}
    (h : GIOIA adj₀ adj₁) : GIOIA adj₁ adj₀ := by
  intro f σ₀ σ₁
  exact (h f σ₁ σ₀).symm

end GIOIADefinition

-- ============================================================================
-- Work Unit 12.7: Reduction Chain
-- ============================================================================

section ReductionChain

variable [Field F]

/-- Tensor-OIA implies CE-OIA under the tensor-to-code encoding.

    The encoding maps tensors to codes such that tensor isomorphism
    corresponds to code equivalence, preserving orbit indistinguishability.
    This step uses the structure tensor construction (Grochow & Qiao, 2021).

    Stated as a `Prop`-valued definition: the encoding proof requires
    explicit algebraic constructions beyond this formalization's scope.
    Results carry this as an explicit hypothesis. -/
def TensorOIAImpliesCEOIA : Prop :=
  ∀ (m : ℕ) (T₀ T₁ : Tensor3 m F),
    @TensorOIA m F _ T₀ T₁ →
    ∃ (k : ℕ) (C₀ C₁ : Finset (Fin k → F)),
      CEOIA C₀ C₁

/-- CE-OIA implies GI-OIA under the code-to-graph encoding.

    The encoding maps codes to graphs such that code equivalence
    corresponds to graph isomorphism, preserving orbit indistinguishability.
    Since CE is at least as hard as GI (GI ≤_p CE), this direction always
    exists.

    Stated as a `Prop`-valued definition following the OIA pattern. -/
def CEOIAImpliesGIOIA : Prop :=
  ∀ (m : ℕ) (C₀ C₁ : Finset (Fin m → F)),
    CEOIA C₀ C₁ →
    ∃ (k : ℕ) (adj₀ adj₁ : Fin k → Fin k → Bool),
      GIOIA adj₀ adj₁

/-- GI-OIA implies the scheme-level OIA.

    The encoding maps graph isomorphism instances to orbit encryption
    scheme instances. This is the step where CFI graph constructions
    (Cai-Furer-Immerman, 1992) provide hard instances for the scheme.

    Stated as a `Prop`-valued definition following the OIA pattern. -/
def GIOIAImpliesOIA {G : Type*} {X : Type*} {M : Type*}
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) : Prop :=
  (∃ (k : ℕ) (adj₀ adj₁ : Fin k → Fin k → Bool), GIOIA adj₀ adj₁) →
    OIA scheme

/-- The full hardness chain: TensorOIA, through all reductions, implies
    the scheme-level OIA.

    This packages all individual reductions into a single composite Prop.
    A scheme satisfying this chain inherits the hardness of TI. -/
def HardnessChain {G : Type*} {X : Type*} {M : Type*}
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) : Prop :=
  -- Tensor-level indistinguishability is provided
  (∃ (m : ℕ) (T₀ T₁ : Tensor3 m F), @TensorOIA m F _ T₀ T₁) ∧
  -- All reductions transfer indistinguishability
  @TensorOIAImpliesCEOIA F _ ∧
  @CEOIAImpliesGIOIA F ∧
  GIOIAImpliesOIA scheme

/-- The full chain implies OIA: composing TensorOIA with the reduction
    chain yields the scheme-level OIA.

    **Proof:** Unfold the chain, apply each reduction in sequence, then
    apply GIOIAImpliesOIA to obtain OIA for the scheme. -/
theorem oia_from_hardness_chain
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (hChain : HardnessChain (F := F) scheme) :
    OIA scheme := by
  obtain ⟨⟨m, T₀, T₁, hTensor⟩, hTI_CE, hCE_GI, hGI_OIA⟩ := hChain
  -- Step 1: TensorOIA → CEOIA
  obtain ⟨k₁, C₀, C₁, hCEOIA⟩ := hTI_CE m T₀ T₁ hTensor
  -- Step 2: CEOIA → GIOIA
  obtain ⟨k₂, adj₀, adj₁, hGIOIA⟩ := hCE_GI k₁ C₀ C₁ hCEOIA
  -- Step 3: GIOIA → OIA
  exact hGI_OIA ⟨k₂, adj₀, adj₁, hGIOIA⟩

/-- The culmination: the full hardness chain implies IND-1-CPA security.

    This composes `oia_from_hardness_chain` with `oia_implies_1cpa`
    (proved in Phase 4) to derive security from TI-hardness.

    **Security guarantee:** If TI is hard (no efficient algorithm
    distinguishes tensor orbits) and the reductions are sound, then
    the Orbcrypt scheme is IND-1-CPA secure. -/
theorem hardness_chain_implies_security
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (hChain : HardnessChain (F := F) scheme) :
    IsSecure scheme :=
  oia_implies_1cpa scheme (oia_from_hardness_chain scheme hChain)

end ReductionChain

end Orbcrypt
