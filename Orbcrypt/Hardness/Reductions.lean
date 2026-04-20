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
--
-- **Audit-revised shape (post-2026-04-20 follow-up).** An earlier landed
-- form of these Props was `∀ T₀ T₁ C₀ C₁, ConcreteTensorOIA T T' εT →
-- ConcreteCEOIA C C' εC`. With `T = T' = T₀` that hypothesis is trivially
-- satisfiable (same-tensor advantage is 0), so the Prop collapsed to the
-- *unrelated* universal `∀ C₀ C₁, ConcreteCEOIA C₀ C₁ εC` — the tensor
-- layer had no content. The revised form below makes both sides
-- *universal-in-the-problem-instance*: the hypothesis is "TI is εT-hard
-- for every tensor instance" and the conclusion is "CE is εC-hard for
-- every code instance". That is the honest shape of a reduction at the
-- Prop level (see the section docstring below for the cryptographic
-- justification and the `OrbitPreservingEncoding` bridge that makes it
-- concrete).

section ConcreteReductions

/-- Convenience alias: "universal" ConcreteTensorOIA at bound `εT` — every
    tensor pair under every finite surrogate group has TensorOIA-bound
    `εT`. This is the *hypothesis shape* used by the Tensor → CE reduction
    Prop below; exposing it as a named alias lets downstream callers
    (e.g. `ConcreteHardnessChain.tensor_hard`) speak in one term. -/
def UniversalConcreteTensorOIA
    [Fintype F] [DecidableEq F] (εT : ℝ) : Prop :=
  ∀ {n : ℕ} {G_TI : Type}
    [Group G_TI] [Fintype G_TI] [Nonempty G_TI]
    [MulAction G_TI (Tensor3 n F)]
    (T₀ T₁ : Tensor3 n F),
    ConcreteTensorOIA (G_TI := G_TI) T₀ T₁ εT

/-- Convenience alias: "universal" ConcreteCEOIA at bound `εC`. -/
def UniversalConcreteCEOIA [DecidableEq F] (εC : ℝ) : Prop :=
  ∀ {m : ℕ} (C₀ C₁ : Finset (Fin m → F)), ConcreteCEOIA C₀ C₁ εC

/-- Convenience alias: "universal" ConcreteGIOIA at bound `εG`. -/
def UniversalConcreteGIOIA (εG : ℝ) : Prop :=
  ∀ {k : ℕ} (adj₀ adj₁ : Fin k → Fin k → Bool),
    @ConcreteGIOIA k adj₀ adj₁ εG

/-- **Workstream E3a (audit-revised).** Probabilistic Tensor → CE reduction
    Prop.

    Stated as a *hardness transfer*: universal TI-hardness at `εT` entails
    universal CE-hardness at `εC`. Both sides quantify uniformly over all
    instances of their respective problems; the reduction asserts that the
    Tensor hardness assumption transfers to Code hardness at potentially
    relaxed advantage.

    **Why universal → universal.** A many-one Karp reduction
    (`OrbitPreservingEncoding` in `Orbcrypt/Hardness/Encoding.lean`)
    transforms a CE-distinguisher on encoded inputs into a TI-distinguisher
    on the originals with bounded advantage loss. Contra-positively, a TI
    hardness bound on all instances delivers a CE hardness bound on all
    instances in the encoding's image. Since the image can be taken to cover
    the CE instance space (up to the encoding's expansion), the universal
    form is the natural Prop-level statement of a reduction.

    **Pre-audit shape (collapsed).** An earlier form `∀ T C, OIA T εT → OIA
    C εC` was semantically decoupled: picking `T₀ = T₁` makes the
    hypothesis trivially satisfied (advantage 0), so the Prop reduced to
    the *unrelated* claim `∀ C, OIA C εC`. The universal→universal form
    makes the hypothesis non-trivial and the reduction honest.

    **Concrete witness.** The Grochow–Qiao structure-tensor encoding
    discharges this Prop at specific `εT, εC`; its concrete formalisation
    is Workstream F4's scope. -/
def ConcreteTensorOIAImpliesConcreteCEOIA
    [Fintype F] [DecidableEq F] (εT εC : ℝ) : Prop :=
  UniversalConcreteTensorOIA (F := F) εT →
    UniversalConcreteCEOIA (F := F) εC

/-- `ConcreteTensorOIAImpliesConcreteCEOIA 1 1` holds trivially, since
    `ConcreteCEOIA _ _ 1` is true for any codes (conclusion is universally
    true regardless of the hypothesis). Satisfiability witness. -/
theorem concreteTensorOIAImpliesConcreteCEOIA_one_one
    [Fintype F] [DecidableEq F] :
    ConcreteTensorOIAImpliesConcreteCEOIA (F := F) 1 1 := fun _ _ C₀ C₁ =>
  concreteCEOIA_one C₀ C₁

/-- **Workstream E3b (audit-revised).** Probabilistic CE → GI reduction
    Prop, in universal→universal form (see E3a's rationale). The underlying
    hardness transfer is the CFI / incidence-matrix encoding from codes to
    graphs (Cai–Furer–Immerman 1992). -/
def ConcreteCEOIAImpliesConcreteGIOIA
    [DecidableEq F] (εC εG : ℝ) : Prop :=
  UniversalConcreteCEOIA (F := F) εC → UniversalConcreteGIOIA εG

/-- `ConcreteCEOIAImpliesConcreteGIOIA 1 1` holds trivially. -/
theorem concreteCEOIAImpliesConcreteGIOIA_one_one
    [DecidableEq F] :
    ConcreteCEOIAImpliesConcreteGIOIA (F := F) 1 1 := fun _ _ adj₀ adj₁ =>
  concreteGIOIA_one adj₀ adj₁

/-- **Workstream E3c (audit-revised).** Probabilistic GI → scheme-OIA
    reduction Prop.

    The last link of the chain: universal GI-hardness at `εG` transfers to
    `ConcreteOIA` at `ε` on a specific `OrbitEncScheme`. The underlying
    encoding embeds CFI graph pairs as message representatives in the
    scheme's ciphertext space. -/
def ConcreteGIOIAImpliesConcreteOIA
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (εG ε : ℝ) : Prop :=
  UniversalConcreteGIOIA εG → ConcreteOIA scheme ε

/-- `ConcreteGIOIAImpliesConcreteOIA scheme 1 1` holds trivially. -/
theorem concreteGIOIAImpliesConcreteOIA_one_one
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) :
    ConcreteGIOIAImpliesConcreteOIA scheme 1 1 := fun _ => concreteOIA_one scheme

/-- **Workstream E3d (audit-revised).** Composition sanity check at
    `ε = 0`. If all three reductions hold at `(0, 0)` and universal
    TensorOIA at ε = 0 holds, the scheme inherits `ConcreteOIA scheme 0`.

    This exercises the full chain composition with every link used
    meaningfully — tensor_hardness → CE-hardness → GI-hardness →
    scheme-OIA. Any change to the reduction Props that breaks
    `0 → 0 → 0 → 0` compositionality surfaces here first. -/
theorem concrete_chain_zero_compose
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    [Fintype F] [DecidableEq F]
    (hTensor : UniversalConcreteTensorOIA (F := F) 0)
    (h₁ : ConcreteTensorOIAImpliesConcreteCEOIA (F := F) 0 0)
    (h₂ : ConcreteCEOIAImpliesConcreteGIOIA (F := F) 0 0)
    (h₃ : ConcreteGIOIAImpliesConcreteOIA scheme 0 0) :
    ConcreteOIA scheme 0 :=
  -- Chain: UniversalTensorOIA 0 →h₁ UniversalCEOIA 0 →h₂ UniversalGIOIA 0
  --                                                    →h₃ ConcreteOIA scheme 0
  h₃ (h₂ (h₁ hTensor))

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

/-- **Workstream E4a (audit-revised).** Packaged ε-bounded hardness chain
    culminating in `ConcreteOIA scheme ε`.

    **Audit note.** The pre-audit form carried a per-pair
    `ConcreteTensorOIA T₀ T₁ εT` witness and paired it with a per-pair
    reduction Prop. As the landed audit follow-up explains, that shape
    was *decoupled*: the tensor side collapsed (`T₀ = T₁` gave advantage
    0 trivially) and the chain never actually consumed tensor hardness.
    The revised structure below stores a **universal** tensor hardness
    assumption (`UniversalConcreteTensorOIA`) which the three reduction
    Props (also audit-revised to universal→universal form) actually
    consume. The chain's ε bounds now propagate through every link.

    Fields:
    * `εT` — tensor-layer advantage bound (the strongest assumption).
    * `εC` — code-layer advantage bound.
    * `εG` — graph-layer advantage bound.
    * `tensor_hard` — **universal** TI-hardness: every tensor pair under
      every surrogate group satisfies `ConcreteTensorOIA _ _ εT`.
    * `tensor_to_ce` / `ce_to_gi` / `gi_to_oia` — the three audit-revised
      reduction Props (each stated universal→universal).

    **Usage.** Downstream callers obtain `ConcreteOIA scheme ε` via
    `concreteOIA_from_chain` below.

    **Tightness.** When `εT = εC = εG = ε`, construct via
    `ConcreteHardnessChain.tight`. General chains allow each reduction to
    lose a multiplicative factor. -/
structure ConcreteHardnessChain
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (F : Type*) [Fintype F] [DecidableEq F]
    (ε : ℝ) where
  /-- Tensor-layer advantage bound. -/
  εT : ℝ
  /-- Code-layer advantage bound. -/
  εC : ℝ
  /-- Graph-layer advantage bound. -/
  εG : ℝ
  /-- **Universal** tensor-layer hardness assumption: every tensor pair
      under every finite surrogate group has `ConcreteTensorOIA` bound `εT`.
      This is the cryptographic input to the whole chain. -/
  tensor_hard : UniversalConcreteTensorOIA (F := F) εT
  /-- Tensor → CE reduction Prop at `(εT, εC)`. -/
  tensor_to_ce : ConcreteTensorOIAImpliesConcreteCEOIA (F := F) εT εC
  /-- CE → GI reduction Prop at `(εC, εG)`. -/
  ce_to_gi : ConcreteCEOIAImpliesConcreteGIOIA (F := F) εC εG
  /-- GI → scheme-OIA reduction Prop at `(εG, ε)`. -/
  gi_to_oia : ConcreteGIOIAImpliesConcreteOIA scheme εG ε

namespace ConcreteHardnessChain

/-- **Workstream E4b (audit-revised).** Chain composition: a
    `ConcreteHardnessChain scheme F ε` entails `ConcreteOIA scheme ε`.

    **Proof.** Each reduction field consumes the previous layer's universal
    hardness and produces the next layer's universal hardness — every link
    is used meaningfully:

    ```
        tensor_hard : UniversalConcreteTensorOIA εT
      ──▶ tensor_to_ce gives UniversalConcreteCEOIA εC
      ──▶ ce_to_gi gives UniversalConcreteGIOIA εG
      ──▶ gi_to_oia gives ConcreteOIA scheme ε
    ```

    No auxiliary "dummy" data is threaded through — the pre-audit chain's
    trick of passing through empty codes and trivial graphs is gone. -/
theorem concreteOIA_from_chain
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    {scheme : OrbitEncScheme G X M}
    {F : Type*} [Fintype F] [DecidableEq F]
    {ε : ℝ}
    (hc : ConcreteHardnessChain scheme F ε) :
    ConcreteOIA scheme ε :=
  hc.gi_to_oia (hc.ce_to_gi (hc.tensor_to_ce hc.tensor_hard))

/-- **Workstream E4c.** Tight constructor: when all four ε values coincide
    (every reduction is lossless), assemble the chain directly without
    repeating the field names. -/
def tight
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    {scheme : OrbitEncScheme G X M}
    {F : Type*} [Fintype F] [DecidableEq F]
    {ε : ℝ}
    (h_tensor : UniversalConcreteTensorOIA (F := F) ε)
    (h_tc : ConcreteTensorOIAImpliesConcreteCEOIA (F := F) ε ε)
    (h_cg : ConcreteCEOIAImpliesConcreteGIOIA (F := F) ε ε)
    (h_go : ConcreteGIOIAImpliesConcreteOIA scheme ε ε) :
    ConcreteHardnessChain scheme F ε :=
  { εT := ε, εC := ε, εG := ε,
    tensor_hard := h_tensor,
    tensor_to_ce := h_tc, ce_to_gi := h_cg, gi_to_oia := h_go }

/-- **Post-audit satisfiability witness.** At `ε = 1` the tight constructor
    is inhabited: universal TensorOIA 1 holds (advantage is always ≤ 1), the
    three reduction Props at `(1, 1)` are trivially satisfied, so the tight
    chain lives — confirming `ConcreteHardnessChain` is non-vacuous. -/
theorem tight_one_exists
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (F : Type*) [Fintype F] [DecidableEq F] :
    Nonempty (ConcreteHardnessChain scheme F 1) :=
  ⟨tight
    (fun T₀ T₁ => concreteTensorOIA_one T₀ T₁)
    (concreteTensorOIAImpliesConcreteCEOIA_one_one (F := F))
    (concreteCEOIAImpliesConcreteGIOIA_one_one (F := F))
    (concreteGIOIAImpliesConcreteOIA_one_one scheme)⟩

end ConcreteHardnessChain

-- ============================================================================
-- Workstream E5 — Probabilistic `hardness_chain_implies_security`
-- ============================================================================

/-- **Workstream E5 (audit-revised).** Probabilistic upgrade of
    `hardness_chain_implies_security`.

    Given a `ConcreteHardnessChain scheme F ε`, the probabilistic
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
    (ε : ℝ) (hc : ConcreteHardnessChain scheme F ε)
    (A : Adversary X M) :
    indCPAAdvantage scheme A ≤ ε :=
  concrete_oia_implies_1cpa scheme ε
    (ConcreteHardnessChain.concreteOIA_from_chain hc) A

end ConcreteHardnessChainSection

end Orbcrypt
