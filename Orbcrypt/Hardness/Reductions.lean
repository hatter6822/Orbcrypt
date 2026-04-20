import Orbcrypt.Hardness.CodeEquivalence
import Orbcrypt.Hardness.TensorAction
import Orbcrypt.Hardness.Encoding
import Orbcrypt.Crypto.OIA
import Orbcrypt.Crypto.Security
import Orbcrypt.Theorems.OIAImpliesCPA
import Orbcrypt.Crypto.CompOIA
import Orbcrypt.Crypto.CompSecurity
import Mathlib.Data.Fintype.Perm

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

-- ============================================================================
-- Workstream E2c — `ConcreteGIOIA`: probabilistic Graph-Isomorphism OIA
-- ============================================================================

section ConcreteGI

/-- Orbit distribution on adjacency functions under the `S_n` action by
    simultaneous row/column permutation: sample `σ ← uniformPMF (Equiv.Perm
    (Fin n))`, return `permuteAdj σ adj`.

    Graph-isomorphism analogue of `codeOrbitDist`. Used to make GIOIA
    probabilistic (see `ConcreteGIOIA`). -/
noncomputable def graphOrbitDist (adj : Fin n → Fin n → Bool) :
    PMF (Fin n → Fin n → Bool) :=
  PMF.map (fun σ : Equiv.Perm (Fin n) => permuteAdj σ adj)
    (uniformPMF (Equiv.Perm (Fin n)))

/-- **Probabilistic Graph-Isomorphism OIA** with explicit advantage bound
    `ε`. Every Boolean distinguisher on adjacency functions has advantage
    at most `ε` between the orbit distributions of two candidate graphs
    `adj₀, adj₁` under the `S_n` action by simultaneous row/column
    permutation.

    **Strength.** GI is known to admit a quasi-polynomial algorithm (Babai,
    2015), so `ConcreteGIOIA` is the *weakest* OIA variant in the reduction
    chain: GIOIA-hard implies CEOIA-hard implies TensorOIA-hard (the
    reduction directions in `HardnessChain` flow TensorOIA → CEOIA → GIOIA
    → scheme OIA, so downstream security rests on TensorOIA being hard). -/
def ConcreteGIOIA (adj₀ adj₁ : Fin n → Fin n → Bool) (ε : ℝ) : Prop :=
  ∀ (D : (Fin n → Fin n → Bool) → Bool),
    advantage D (graphOrbitDist adj₀) (graphOrbitDist adj₁) ≤ ε

/-- `ConcreteGIOIA` with `ε = 1` is trivially satisfied. -/
theorem concreteGIOIA_one (adj₀ adj₁ : Fin n → Fin n → Bool) :
    ConcreteGIOIA adj₀ adj₁ 1 :=
  fun D => advantage_le_one D _ _

/-- `ConcreteGIOIA` is monotone in the bound. -/
theorem concreteGIOIA_mono
    (adj₀ adj₁ : Fin n → Fin n → Bool) {ε₁ ε₂ : ℝ}
    (hle : ε₁ ≤ ε₂) (hOIA : ConcreteGIOIA adj₀ adj₁ ε₁) :
    ConcreteGIOIA adj₀ adj₁ ε₂ :=
  fun D => le_trans (hOIA D) hle

end ConcreteGI

-- ============================================================================
-- Workstream E3 — Probabilistic reduction Props (ε-preserving, Prop-valued)
-- ============================================================================
--
-- The reduction Props do *not* need the `[Field F]` instance — they only
-- mention `Tensor3 n F` (a plain function type), `Finset (Fin m → F)` (needs
-- `[DecidableEq F]`), and `Fin k → Fin k → Bool` (no `F` structure). Keeping
-- `[Field F]` out of this section's `variable` block avoids the linter
-- warning about automatically included unused section variables.

section ConcreteReductions

/-- **Workstream E3a.** Probabilistic Tensor → CE reduction Prop.

    Asserts that a `ConcreteTensorOIA` bound on *any* tensor pair at `εT`
    transfers to a `ConcreteCEOIA` bound on *any* code pair at `εC`. This
    is the uniform ("hardness transfer") form: the real cryptographic
    content is that there exists an orbit-preserving encoding (see
    `Orbcrypt/Hardness/Encoding.lean` for the interface) that lets a
    CE-distinguisher be simulated by a TI-distinguisher with at most εT/εC
    multiplicative loss. Beullens–Persichetti (Eurocrypt 2023) give the
    concrete construction.

    Stated as a Prop carried as an explicit hypothesis of
    `ConcreteHardnessChain`. A concrete witness via the Grochow–Qiao
    structure-tensor encoding is tracked as Workstream F4. -/
def ConcreteTensorOIAImpliesConcreteCEOIA
    [Fintype F] [DecidableEq F] (εT εC : ℝ) : Prop :=
  ∀ {n m : ℕ} (T₀ T₁ : Tensor3 n F) (C₀ C₁ : Finset (Fin m → F))
    {G_TI : Type}
    [Group G_TI] [Fintype G_TI] [Nonempty G_TI]
    [MulAction G_TI (Tensor3 n F)],
    ConcreteTensorOIA (G_TI := G_TI) T₀ T₁ εT →
    ConcreteCEOIA C₀ C₁ εC

/-- `ConcreteTensorOIAImpliesConcreteCEOIA 1 1` holds trivially, since
    `ConcreteCEOIA _ _ 1` is true for any codes. Satisfiability witness. -/
theorem concreteTensorOIAImpliesConcreteCEOIA_one_one
    [Fintype F] [DecidableEq F] :
    ConcreteTensorOIAImpliesConcreteCEOIA (F := F) 1 1 := by
  intro _ _ _ _ C₀ C₁ _ _ _ _ _ _hT
  exact concreteCEOIA_one C₀ C₁

/-- **Workstream E3b.** Probabilistic CE → GI reduction Prop.

    Symmetric to E3a: a `ConcreteCEOIA` bound at `εC` transfers to a
    `ConcreteGIOIA` bound at `εG`. The underlying hardness transfer is
    the CFI / incidence-matrix encoding from codes to graphs (Cai–Furer–
    Immerman 1992). -/
def ConcreteCEOIAImpliesConcreteGIOIA
    [DecidableEq F] (εC εG : ℝ) : Prop :=
  ∀ {m k : ℕ} (C₀ C₁ : Finset (Fin m → F))
    (adj₀ adj₁ : Fin k → Fin k → Bool),
    ConcreteCEOIA C₀ C₁ εC →
    ConcreteGIOIA adj₀ adj₁ εG

/-- `ConcreteCEOIAImpliesConcreteGIOIA 1 1` holds trivially. -/
theorem concreteCEOIAImpliesConcreteGIOIA_one_one
    [DecidableEq F] :
    ConcreteCEOIAImpliesConcreteGIOIA (F := F) 1 1 := by
  intro _ _ _ _ adj₀ adj₁ _hC
  exact concreteGIOIA_one adj₀ adj₁

/-- **Workstream E3c.** Probabilistic GI → scheme-OIA reduction Prop.

    The last link of the chain: a `ConcreteGIOIA` bound at `εG` transfers
    to a `ConcreteOIA` bound at `ε` on a specific `OrbitEncScheme`. The
    underlying encoding embeds CFI graph pairs as message representatives
    in the scheme's ciphertext space. -/
def ConcreteGIOIAImpliesConcreteOIA
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (εG ε : ℝ) : Prop :=
  ∀ {k : ℕ} (adj₀ adj₁ : Fin k → Fin k → Bool),
    ConcreteGIOIA adj₀ adj₁ εG →
    ConcreteOIA scheme ε

/-- `ConcreteGIOIAImpliesConcreteOIA scheme 1 1` holds trivially. -/
theorem concreteGIOIAImpliesConcreteOIA_one_one
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) :
    ConcreteGIOIAImpliesConcreteOIA scheme 1 1 := by
  intro _ _ _ _hG
  exact concreteOIA_one scheme

/-- **Workstream E3d.** Composition sanity check at `ε = 0`. If all three
    reductions hold at `(0, 0)` and there exists a ConcreteTensorOIA
    witness at `ε = 0`, then the scheme inherits `ConcreteOIA scheme 0`.

    This is the algebraic sanity sentinel for `concreteOIA_from_chain`:
    any change to the reduction Props that breaks `0 → 0 → 0 → 0`
    compositionality surfaces here first. -/
theorem concrete_chain_zero_compose
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    [Fintype F] [DecidableEq F]
    {n : ℕ} (T₀ T₁ : Tensor3 n F)
    {G_TI : Type} [Group G_TI] [Fintype G_TI] [Nonempty G_TI]
    [MulAction G_TI (Tensor3 n F)]
    (hTensor : ConcreteTensorOIA (G_TI := G_TI) T₀ T₁ 0)
    (h₁ : ConcreteTensorOIAImpliesConcreteCEOIA (F := F) 0 0)
    (h₂ : ConcreteCEOIAImpliesConcreteGIOIA (F := F) 0 0)
    (h₃ : ConcreteGIOIAImpliesConcreteOIA scheme 0 0) :
    ConcreteOIA scheme 0 := by
  -- 1. Tensor → CE at ε=0 (picking an arbitrary 0-dim code pair).
  have hCE : ConcreteCEOIA (∅ : Finset (Fin 0 → F)) ∅ 0 :=
    h₁ T₀ T₁ ∅ ∅ hTensor
  -- 2. CE → GI at ε=0 (picking an arbitrary 0-vertex graph pair).
  have hGI : ConcreteGIOIA (n := 0)
      (fun _ _ => (true : Bool)) (fun _ _ => (true : Bool)) 0 :=
    h₂ ∅ ∅ _ _ hCE
  -- 3. GI → scheme-OIA at ε=0.
  exact h₃ _ _ hGI

end ConcreteReductions

-- ============================================================================
-- Workstream E4 — `ConcreteHardnessChain`: composable ε-bounded hardness chain
-- ============================================================================

section ConcreteHardnessChainSection

-- Only `[Fintype F]` and `[DecidableEq F]` are required by the reduction
-- Props referenced in the chain (`ConcreteTensorOIAImpliesConcreteCEOIA` etc.).
-- `[Field F]` was auto-bound from the outer namespace's `variable` but is
-- unused by any chain content — `Tensor3 n F` is a plain function type and
-- `Finset.image` only needs `[DecidableEq F]`. Scoping the Field requirement
-- out here is cleaner than `omit [Field F] in` at every declaration.
variable [Fintype F] [DecidableEq F]

/-- **Workstream E4a.** Packaged ε-bounded hardness chain culminating in
    `ConcreteOIA scheme ε`.

    The surrogate tensor group `G_TI` and its structure instances are
    threaded through the structure signature (outside the fields), so the
    structure itself only carries the quantitative ε bounds, the witness
    tensor pair, and the four layered hypotheses:

    * `εT` — tensor-layer advantage bound (the strongest assumption).
    * `εC` — code-layer advantage bound.
    * `εG` — graph-layer advantage bound.
    * `tensor_hard` — the tensor-layer hardness hypothesis: a
      `ConcreteTensorOIA` witness on a specific pair `(T₀, T₁)`.
    * `tensor_to_ce` / `ce_to_gi` / `gi_to_oia` — the three reduction
      Props from Workstream E3, each stated at its per-layer ε pair.

    **Usage.** Downstream callers obtain `ConcreteOIA scheme ε` via
    `concreteOIA_from_chain` below. This is the ε-bounded analogue of
    `HardnessChain` / `oia_from_hardness_chain` (which were vacuous under
    the deterministic OIA).

    **Tightness.** When `εT = εC = εG = ε`, construct via
    `ConcreteHardnessChain.tight` (E4c). General chains allow each
    reduction to lose a multiplicative factor. -/
structure ConcreteHardnessChain
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (F : Type*) [Fintype F] [DecidableEq F]
    (n : ℕ) (G_TI : Type)
    [Group G_TI] [Fintype G_TI] [Nonempty G_TI]
    [MulAction G_TI (Tensor3 n F)]
    (ε : ℝ) where
  /-- Tensor-layer advantage bound. -/
  εT : ℝ
  /-- Code-layer advantage bound. -/
  εC : ℝ
  /-- Graph-layer advantage bound. -/
  εG : ℝ
  /-- Concrete tensor serving as the `ConcreteTensorOIA` witness (left). -/
  T₀ : Tensor3 n F
  /-- Concrete tensor serving as the `ConcreteTensorOIA` witness (right). -/
  T₁ : Tensor3 n F
  /-- Tensor-layer hardness assumption at the chain's witness pair. -/
  tensor_hard : ConcreteTensorOIA (G_TI := G_TI) T₀ T₁ εT
  /-- Tensor → CE reduction Prop at `(εT, εC)`. -/
  tensor_to_ce : ConcreteTensorOIAImpliesConcreteCEOIA (F := F) εT εC
  /-- CE → GI reduction Prop at `(εC, εG)`. -/
  ce_to_gi : ConcreteCEOIAImpliesConcreteGIOIA (F := F) εC εG
  /-- GI → scheme-OIA reduction Prop at `(εG, ε)`. -/
  gi_to_oia : ConcreteGIOIAImpliesConcreteOIA scheme εG ε

namespace ConcreteHardnessChain

/-- **Workstream E4b.** Chain composition: a `ConcreteHardnessChain scheme
    F n G_TI ε` entails `ConcreteOIA scheme ε`.

    **Proof.** Compose the three reduction Props through the chain's
    tensor-hardness witness. Starting from `tensor_hard :
    ConcreteTensorOIA T₀ T₁ εT`, apply `tensor_to_ce` to reach CEOIA at
    `εC`, then `ce_to_gi` to reach GIOIA at `εG`, then `gi_to_oia` to
    reach `ConcreteOIA scheme ε`. Arbitrary auxiliary codes / graphs are
    supplied at each step (the reduction Props are quantified over all
    such choices). -/
theorem concreteOIA_from_chain
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    {scheme : OrbitEncScheme G X M}
    {F : Type*} [Fintype F] [DecidableEq F]
    {n : ℕ} {G_TI : Type}
    [Group G_TI] [Fintype G_TI] [Nonempty G_TI]
    [MulAction G_TI (Tensor3 n F)]
    {ε : ℝ}
    (hc : ConcreteHardnessChain scheme F n G_TI ε) :
    ConcreteOIA scheme ε := by
  have hCE : ConcreteCEOIA (∅ : Finset (Fin 0 → F)) ∅ hc.εC :=
    hc.tensor_to_ce hc.T₀ hc.T₁ ∅ ∅ hc.tensor_hard
  have hGI : ConcreteGIOIA (n := 0)
      (fun _ _ => (true : Bool)) (fun _ _ => (true : Bool)) hc.εG :=
    hc.ce_to_gi ∅ ∅ _ _ hCE
  exact hc.gi_to_oia _ _ hGI

/-- **Workstream E4c.** Tight constructor: when all four ε values coincide
    (every reduction is lossless), assemble the chain directly without
    repeating the field names. -/
def tight
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    {scheme : OrbitEncScheme G X M}
    {F : Type*} [Fintype F] [DecidableEq F]
    {n : ℕ} {G_TI : Type}
    [Group G_TI] [Fintype G_TI] [Nonempty G_TI]
    [MulAction G_TI (Tensor3 n F)]
    {ε : ℝ}
    (T₀ T₁ : Tensor3 n F)
    (h_tensor : ConcreteTensorOIA (G_TI := G_TI) T₀ T₁ ε)
    (h_tc : ConcreteTensorOIAImpliesConcreteCEOIA (F := F) ε ε)
    (h_cg : ConcreteCEOIAImpliesConcreteGIOIA (F := F) ε ε)
    (h_go : ConcreteGIOIAImpliesConcreteOIA scheme ε ε) :
    ConcreteHardnessChain scheme F n G_TI ε :=
  { εT := ε, εC := ε, εG := ε, T₀ := T₀, T₁ := T₁,
    tensor_hard := h_tensor,
    tensor_to_ce := h_tc, ce_to_gi := h_cg, gi_to_oia := h_go }

end ConcreteHardnessChain

-- ============================================================================
-- Workstream E5 — Probabilistic `hardness_chain_implies_security`
-- ============================================================================

/-- **Workstream E5.** Probabilistic upgrade of `hardness_chain_implies_security`.

    Given a `ConcreteHardnessChain scheme F n G_TI ε`, the probabilistic
    IND-1-CPA advantage of any adversary on `scheme` is bounded by `ε`.

    Composes Workstream E4b (`concreteOIA_from_chain`) with
    `concrete_oia_implies_1cpa` from `Crypto/CompSecurity.lean`. Unlike the
    deterministic `hardness_chain_implies_security` (which is vacuously
    true because `HardnessChain` extends through the vacuous deterministic
    OIA), this statement bounds the genuine probabilistic advantage.

    **Interpretation.** When the tensor-layer hardness `εT`, the three
    reduction losses `(εT→εC, εC→εG, εG→ε)`, and the scheme's
    IND-1-CPA advantage `ε` are all meaningful ε < 1, this theorem
    delivers non-vacuous concrete security for the scheme. -/
theorem concrete_hardness_chain_implies_1cpa_advantage_bound
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    {F : Type*} [Fintype F] [DecidableEq F]
    {n : ℕ} {G_TI : Type}
    [Group G_TI] [Fintype G_TI] [Nonempty G_TI]
    [MulAction G_TI (Tensor3 n F)]
    (ε : ℝ) (hc : ConcreteHardnessChain scheme F n G_TI ε)
    (A : Adversary X M) :
    indCPAAdvantage scheme A ≤ ε :=
  concrete_oia_implies_1cpa scheme ε
    (ConcreteHardnessChain.concreteOIA_from_chain hc) A

end ConcreteHardnessChainSection

end Orbcrypt
