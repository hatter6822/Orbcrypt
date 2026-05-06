/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

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

* `Orbcrypt.TensorOIA` — deterministic OIA for tensor isomorphism under GL(n,F)³
* `Orbcrypt.GIOIA` — deterministic OIA for graph isomorphism under S_n



* `Orbcrypt.ConcreteGIOIA` — probabilistic GI-OIA (Workstream E2c)
* `Orbcrypt.UniversalConcreteTensorOIA` — surrogate-bound probabilistic
  tensor-OIA (post-Workstream-G Fix B: carries `SurrogateTensor F`)
* `Orbcrypt.ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`,
  `Orbcrypt.ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding`,
  `Orbcrypt.ConcreteGIOIAImpliesConcreteOIA_viaEncoding` — per-encoding
  probabilistic reduction Props naming explicit encoder functions
  (Workstream G Fix C, primary post-G vocabulary)
* `Orbcrypt.ConcreteHardnessChain` — packaged ε-bounded chain with
  `SurrogateTensor` parameter and two encoder fields (Workstream G)

## Main results

W6.3 / W6.5 of structural review 2026-05-06 deleted the
deterministic-chain results (`hardness_chain_implies_security`,
`_distinct`, `oia_from_hardness_chain`, `HardnessChain`). The
non-vacuous probabilistic chain is the sole hardness-chain
content post-deletion:

* `Orbcrypt.ConcreteHardnessChain.concreteOIA_from_chain` —
  probabilistic chain composition threading advantage through the
  chain-image `encCG ∘ encTC` (Workstream G).
* `Orbcrypt.ConcreteHardnessChain.tight_one_exists` — non-vacuity
  witness at `ε = 1` via `punitSurrogate F` + dimension-0 trivial
  encoders (Workstream G); W4 of the 2026-05-06 structural review
  adds `tight_one_exists_at_s2Surrogate` for the non-trivial
  `S_2`-shaped surrogate.
* `Orbcrypt.concrete_hardness_chain_implies_1cpa_advantage_bound` —
  ε-bounded IND-1-CPA advantage from the probabilistic chain
  (Workstream E5, post-G signature threads `SurrogateTensor`).

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
```

The deterministic-chain composition `OIA → IND-1-CPA secure` and
the chain Prop `HardnessChain` were removed by W6.3 / W6.5 of
structural review 2026-05-06. The non-vacuous probabilistic chain
(`ConcreteHardnessChain.concreteOIA_from_chain` →
`concrete_hardness_chain_implies_1cpa_advantage_bound`) is the
substantive end-to-end security reduction.

## References

* docs/dev_history/PHASE_12_HARDNESS_ALIGNMENT.md — work units 12.6–12.7
* docs/DEVELOPMENT.md §5.3–5.4 — GI-OIA and CE-OIA
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

-- W6.6 of structural review 2026-05-06: the deterministic per-link
-- reduction Props `TensorOIAImpliesCEOIA`, `CEOIAImpliesGIOIA`,
-- `GIOIAImpliesOIA` (Phase 12 § 12.7) were deleted as part of the
-- deterministic-chain removal scheduled for v0.4.0. The non-vacuous
-- per-encoding probabilistic counterparts
-- `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding`,
-- `ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding`, and
-- `ConcreteGIOIAImpliesConcreteOIA_viaEncoding` (Workstream G /
-- Fix C) carry the substantive ε-smooth per-link content.

-- W6.5 of structural review 2026-05-06: the deterministic chain
-- composition `HardnessChain` (the `Prop`-valued composite of
-- `TensorOIA` + per-link Props + GIOIAImpliesOIA) and the chain
-- implication `oia_from_hardness_chain` were deleted as part of
-- the deterministic-chain removal scheduled for v0.4.0. The non-
-- vacuous counterpart `ConcreteHardnessChain` (with its
-- `concreteOIA_from_chain` composition) carries the substantive
-- ε-smooth hardness-chain content.

-- W6.3 of structural review 2026-05-06: the deterministic chain
-- composition `hardness_chain_implies_security` and its distinct-
-- challenge sibling `hardness_chain_implies_security_distinct`
-- (formerly defined here, Workstream K3) were deleted as part of
-- the deterministic-chain removal scheduled for v0.4.0. The non-
-- vacuous probabilistic counterpart
-- `concrete_hardness_chain_implies_1cpa_advantage_bound` (and its
-- `_distinct` companion) carries the substantive ε-smooth content;
-- the deterministic-chain compositions were vacuously true on
-- every non-trivial scheme.

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
-- **History.**
--
-- * *Initial Workstream E3 shape* (2026-04-18): `∀ T₀ T₁ C₀ C₁,
--   ConcreteTensorOIA T T' εT → ConcreteCEOIA C C' εC`. With
--   `T = T' = T₀` the hypothesis is trivially satisfiable (same-tensor
--   advantage is 0), so the Prop collapsed to the *unrelated* universal
--   `∀ C₀ C₁, ConcreteCEOIA C₀ C₁ εC` — the tensor layer had no content.
-- * *Post-2026-04-20 audit follow-up*: rewritten to
--   universal-in-the-problem-instance form
--   (`UniversalConcreteTensorOIA εT → UniversalConcreteCEOIA εC`) so the
--   tensor hypothesis genuinely threads through. But the universal
--   `UniversalConcreteTensorOIA εT` implicitly quantified over every
--   `G_TI : Type` including PUnit, so the Prop again collapsed at εT < 1
--   for a different reason.
-- * *Post-Workstream-G (2026-04-21)*: the universal form now takes
--   `S : SurrogateTensor F` as a named parameter (Fix B), binding the
--   tensor surrogate explicitly and closing the PUnit collapse. The
--   primary reduction vocabulary is the per-encoding
--   `*_viaEncoding` Props (Fix C, below), which name a specific encoder
--   function `enc : α → β` and state hardness transfer through that
--   encoder. The legacy universal→universal Props are retained as
--   derived corollaries. See `Orbcrypt/Hardness/Encoding.lean` for the
--   `OrbitPreservingEncoding` interface that concrete discharges use
--   to prove the per-encoding Props.

section ConcreteReductions

/-- **Universal Concrete Tensor-OIA** at bound `εT`, parameterised by a
    caller-supplied `SurrogateTensor F`.

    **Post-Workstream-G shape.** The `G_TI` surrogate is now *named* in
    `S : SurrogateTensor F` rather than implicitly universally quantified.
    Pre-G, the implicit `{G_TI : Type}` binder allowed Lean's typeclass
    inference (or a caller-supplied local instance) to instantiate
    `G_TI := PUnit` with the trivial `MulAction`, under which the orbit
    distribution is a point mass admitting an advantage-1 distinguisher.
    The Prop collapsed to "true only at εT = 1". After Fix B, the
    surrogate choice is explicit: callers supply the *specific* finite
    surrogate they wish to claim hardness for, and the Prop's ε
    parameter genuinely reflects that surrogate's orbit distribution.

    **Relation to the pre-G `UniversalConcreteTensorOIA`.** The old
    predicate is **removed** (per CLAUDE.md's no-backwards-compat-shim
    policy). Consumers that previously wrote
    `UniversalConcreteTensorOIA εT` now write
    `UniversalConcreteTensorOIA S εT` for their chosen surrogate. -/
def UniversalConcreteTensorOIA
    [Fintype F] [DecidableEq F] (S : SurrogateTensor F) (εT : ℝ) : Prop :=
  ∀ {n : ℕ} (T₀ T₁ : Tensor3 n F),
    ConcreteTensorOIA (G_TI := S.carrier) T₀ T₁ εT

/-- Convenience alias: "universal" ConcreteCEOIA at bound `εC`. -/
def UniversalConcreteCEOIA [DecidableEq F] (εC : ℝ) : Prop :=
  ∀ {m : ℕ} (C₀ C₁ : Finset (Fin m → F)), ConcreteCEOIA C₀ C₁ εC

/-- Convenience alias: "universal" ConcreteGIOIA at bound `εG`. -/
def UniversalConcreteGIOIA (εG : ℝ) : Prop :=
  ∀ {k : ℕ} (adj₀ adj₁ : Fin k → Fin k → Bool),
    @ConcreteGIOIA k adj₀ adj₁ εG

-- ============================================================================
-- Workstream G (audit 2026-04-21, H1) — Fix C: per-encoding reduction Props
-- ============================================================================
--
-- The three per-encoding Props below are the primary reduction vocabulary
-- post-Workstream-G. Each carries:
-- * A `SurrogateTensor F` (for the tensor-layer link) or no surrogate (for
--   the code/graph/scheme layers, which act over concrete value types).
-- * A concrete encoder function (`Tensor3 n F → Finset (Fin m → F)` etc.).
-- * Two advantage bounds `(εA, εB)`.
--
-- The Prop asserts "hardness transfer through this specific encoder" —
-- not "hardness transfer through every possible encoder". This matches
-- the cryptographic literature's per-encoding reduction statements.
--
-- **Design rationale (Fix C).** The `OrbitPreservingEncoding` interface
-- in `Orbcrypt/Hardness/Encoding.lean` captures the generic structure of
-- a Karp reduction (forward encoding + orbit preservation + orbit
-- reflection). The per-encoding Props here consume encoder *functions*
-- rather than the full `OrbitPreservingEncoding` bundle because:
-- (a) the advantage-transfer argument is Prop-level and does not need
--     the reflects/preserves fields at the type level (it needs them at
--     the proof level, inside any future concrete discharge);
-- (b) the encoders at different layers have different type signatures
--     (tensors ↦ codes, codes ↦ adjacency matrices, messages ↦
--     adjacency matrices) that don't share a single MulAction framework;
-- (c) when a `OrbitPreservingEncoding` witness is eventually supplied
--     (via the Grochow–Qiao or CFI research follow-ups), its `.encode`
--     field is exactly the function slot here.

/-- **Workstream G / Fix C.** Per-encoding probabilistic Tensor → CE
    reduction Prop.

    Parameters:
    * `S : SurrogateTensor F` — tensor-layer surrogate.
    * `enc : Tensor3 n F → Finset (Fin m → F)` — explicit encoder.
    * `εT, εC : ℝ` — source (Tensor) and target (CE) advantage bounds.

    The Prop asserts: for every tensor pair `T₀, T₁ : Tensor3 n F`, if
    `ConcreteTensorOIA` holds on that pair at `εT` under surrogate `S`,
    then `ConcreteCEOIA` holds on `(enc T₀, enc T₁)` at `εC`.

    **Honest reduction content.** Unlike the pre-G "universal →
    universal" shape, this Prop names the encoder, so callers who
    discharge it supply the encoder and a proof that the encoder
    transfers advantage (typically via `OrbitPreservingEncoding` and a
    PMF-pushforward argument; see § 15.1 of the audit plan).

    **Trivial satisfiability.** `εC = 1` makes the conclusion
    unconditionally true (via `advantage_le_one`), so the Prop is
    discharged at ε = 1 for any encoder; `concreteTensorOIAImpliesConcreteCEOIA_viaEncoding_one_one`
    is the satisfiability witness.

    **Concrete witnesses at ε < 1.** The Grochow–Qiao structure-tensor
    encoding (2021) is the canonical discharge; its formalisation is a
    research follow-up tracked in the audit plan § 15.1. -/
def ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding
    [Fintype F] [DecidableEq F] (S : SurrogateTensor F)
    {n m : ℕ} (enc : Tensor3 n F → Finset (Fin m → F))
    (εT εC : ℝ) : Prop :=
  ∀ (T₀ T₁ : Tensor3 n F),
    ConcreteTensorOIA (G_TI := S.carrier) T₀ T₁ εT →
    ConcreteCEOIA (enc T₀) (enc T₁) εC

/-- Satisfiability witness for the per-encoding Tensor → CE reduction at
    `(εT, εC) = (1, 1)`: trivially true because `ConcreteCEOIA _ _ 1`
    holds unconditionally. -/
theorem concreteTensorOIAImpliesConcreteCEOIA_viaEncoding_one_one
    [Fintype F] [DecidableEq F] (S : SurrogateTensor F)
    {n m : ℕ} (enc : Tensor3 n F → Finset (Fin m → F)) :
    ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding S enc 1 1 :=
  fun T₀ T₁ _ => concreteCEOIA_one (enc T₀) (enc T₁)

/-- **Workstream G / Fix C.** Per-encoding probabilistic CE → GI
    reduction Prop.

    Parameters:
    * `enc : Finset (Fin m → F) → (Fin k → Fin k → Bool)` — explicit
      encoder from codes to adjacency matrices.
    * `εC, εG : ℝ` — source (CE) and target (GI) advantage bounds.

    **Concrete witness.** The Cai–Fürer–Immerman (1992) graph gadget or
    incidence-matrix encoding is the canonical discharge. Formalising
    the gadget is a research follow-up (audit plan § 15.1). -/
def ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding
    [DecidableEq F] {m k : ℕ}
    (enc : Finset (Fin m → F) → (Fin k → Fin k → Bool))
    (εC εG : ℝ) : Prop :=
  ∀ (C₀ C₁ : Finset (Fin m → F)),
    ConcreteCEOIA C₀ C₁ εC →
    @ConcreteGIOIA k (enc C₀) (enc C₁) εG

/-- Satisfiability witness for the per-encoding CE → GI reduction at
    `(εC, εG) = (1, 1)`. -/
theorem concreteCEOIAImpliesConcreteGIOIA_viaEncoding_one_one
    [DecidableEq F] {m k : ℕ}
    (enc : Finset (Fin m → F) → (Fin k → Fin k → Bool)) :
    ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding (F := F) (m := m) (k := k)
      enc 1 1 :=
  fun C₀ C₁ _ => concreteGIOIA_one (enc C₀) (enc C₁)

/-- **Workstream G / Fix C.** Per-encoding probabilistic GI → scheme-OIA
    reduction Prop.

    The last link of the chain embeds graph-isomorphism hardness into
    the scheme's orbit-indistinguishability advantage bound.

    **Image-specific hypothesis design.** Unlike the pre-G universal→
    universal form (which would be unsound at the composition level
    because per-encoding hardness only covers the encoder's image),
    this Prop's hypothesis is the *chain-image* GI hardness: "for
    every pair of tensors `T₀, T₁`, the adjacency matrices
    `encCG (encTC T₀)`, `encCG (encTC T₁)` satisfy `ConcreteGIOIA` at
    `εG`". This is exactly what the upstream chain links produce, so
    composition is compositional without coverage obligations.

    Parameters:
    * `scheme : OrbitEncScheme G X M` — the scheme whose advantage we
      bound.
    * `encTC : Tensor3 nT F → Finset (Fin mC → F)` — chain's Tensor → CE
      encoder. Named here because the hypothesis references the
      chain-image composition `encCG ∘ encTC`.
    * `encCG : Finset (Fin mC → F) → (Fin kG → Fin kG → Bool)` —
      chain's CE → GI encoder.
    * `εG, ε : ℝ` — source (GI) and target (scheme-OIA) advantage
      bounds.

    Note that this Prop does **not** reference the tensor-layer
    surrogate directly — GI-hardness on the chain image is a
    statement about adjacency matrices, independent of which finite
    group witnesses the upstream tensor hardness.

    **Concrete discharge.** A CFI-indexed `OrbitEncScheme` where each
    message corresponds to a graph via the encoder composition, and the
    scheme's orbit structure mirrors the graph's automorphism group —
    research follow-up, audit plan § 15.1. -/
def ConcreteGIOIAImpliesConcreteOIA_viaEncoding
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    {F : Type*} [DecidableEq F]
    {nT mC kG : ℕ}
    (encTC : Tensor3 nT F → Finset (Fin mC → F))
    (encCG : Finset (Fin mC → F) → (Fin kG → Fin kG → Bool))
    (εG ε : ℝ) : Prop :=
  (∀ T₀ T₁ : Tensor3 nT F,
      @ConcreteGIOIA kG (encCG (encTC T₀)) (encCG (encTC T₁)) εG) →
    ConcreteOIA scheme ε

/-- Satisfiability witness for the per-encoding GI → scheme-OIA
    reduction at `(εG, ε) = (1, 1)`: the conclusion `ConcreteOIA scheme
    1` is always true. -/
theorem concreteGIOIAImpliesConcreteOIA_viaEncoding_one_one
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    {F : Type*} [DecidableEq F]
    {nT mC kG : ℕ}
    (encTC : Tensor3 nT F → Finset (Fin mC → F))
    (encCG : Finset (Fin mC → F) → (Fin kG → Fin kG → Bool)) :
    ConcreteGIOIAImpliesConcreteOIA_viaEncoding scheme encTC encCG 1 1 :=
  fun _ => concreteOIA_one scheme

-- ============================================================================
-- Legacy derived corollaries (universal → universal form)
-- ============================================================================
--
-- The following three Props are the universal→universal form introduced in
-- Workstream E3 (2026-04-18). They are **derivable** from the per-encoding
-- form by abstracting over encoders, but are retained for compatibility
-- with the audit scripts that exercise them. The `_viaEncoding` forms are
-- the post-Workstream-G primary vocabulary.

/-- **Legacy universal→universal** Tensor → CE reduction Prop.

    Retained as a derived shape; see `*_viaEncoding` for the primary
    per-encoding form. Post-Workstream-G, this Prop's input now binds
    the surrogate `S` (Fix B), so the `PUnit` collapse is fixed at the
    source too. -/
def ConcreteTensorOIAImpliesConcreteCEOIA
    [Fintype F] [DecidableEq F] (S : SurrogateTensor F)
    (εT εC : ℝ) : Prop :=
  UniversalConcreteTensorOIA (F := F) S εT →
    UniversalConcreteCEOIA (F := F) εC

/-- `ConcreteTensorOIAImpliesConcreteCEOIA S 1 1` holds trivially, since
    `ConcreteCEOIA _ _ 1` is true for any codes. -/
theorem concreteTensorOIAImpliesConcreteCEOIA_one_one
    [Fintype F] [DecidableEq F] (S : SurrogateTensor F) :
    ConcreteTensorOIAImpliesConcreteCEOIA (F := F) S 1 1 :=
  fun _ => fun C₀ C₁ => concreteCEOIA_one C₀ C₁

/-- **Legacy universal→universal** CE → GI reduction Prop. -/
def ConcreteCEOIAImpliesConcreteGIOIA
    [DecidableEq F] (εC εG : ℝ) : Prop :=
  UniversalConcreteCEOIA (F := F) εC → UniversalConcreteGIOIA εG

/-- `ConcreteCEOIAImpliesConcreteGIOIA 1 1` holds trivially. -/
theorem concreteCEOIAImpliesConcreteGIOIA_one_one
    [DecidableEq F] :
    ConcreteCEOIAImpliesConcreteGIOIA (F := F) 1 1 := fun _ _ adj₀ adj₁ =>
  concreteGIOIA_one adj₀ adj₁

/-- **Legacy universal→universal** GI → scheme-OIA reduction Prop. -/
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

/-- **Workstream E3d** chain composition sanity check at `ε = 0`.

    Post-Workstream-G, threads the surrogate `S` through the tensor-layer
    link. Any change to the reduction Props that breaks `0 → 0 → 0 → 0`
    compositionality surfaces here first. -/
theorem concrete_chain_zero_compose
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    [Fintype F] [DecidableEq F]
    (S : SurrogateTensor F)
    (hTensor : UniversalConcreteTensorOIA (F := F) S 0)
    (h₁ : ConcreteTensorOIAImpliesConcreteCEOIA (F := F) S 0 0)
    (h₂ : ConcreteCEOIAImpliesConcreteGIOIA (F := F) 0 0)
    (h₃ : ConcreteGIOIAImpliesConcreteOIA scheme 0 0) :
    ConcreteOIA scheme 0 :=
  -- Chain: UniversalTensorOIA S 0 →h₁ UniversalCEOIA 0 →h₂ UniversalGIOIA 0
  --                                                     →h₃ ConcreteOIA scheme 0
  h₃ (h₂ (h₁ hTensor))

end ConcreteReductions

-- ============================================================================
-- `ConcreteHardnessChain` — composable ε-bounded hardness chain
--   Initial form: Workstream E4 (2026-04-18, universal→universal reductions)
--   Post-G form:  Workstream G (2026-04-21, Fix B surrogate + Fix C encoders)
-- ============================================================================

section ConcreteHardnessChainSection

-- Only `[Fintype F]` and `[DecidableEq F]` are required by the reduction
-- Props referenced in the chain. `[Field F]` was auto-bound from the outer
-- namespace's `variable` but is unused by any chain content — `Tensor3 n F`
-- is a plain function type and `Finset.image` only needs `[DecidableEq F]`.
variable [Fintype F] [DecidableEq F]

/-- **Workstream G (audit F-AUDIT-2026-04-21-H1) — ε-bounded hardness chain
    with surrogate binding and per-encoding reduction Props.**

    **Post-Workstream-G shape.** This structure now packages both Fix B
    (the `SurrogateTensor F` parameter binds the tensor-layer surrogate
    group, preventing the pre-G PUnit collapse) and Fix C (each of the
    three reduction links carries an *explicit encoder function* plus
    the matching per-encoding reduction Prop, replacing the pre-G
    universal→universal shape).

    **Chain semantics.** Given:
    * A surrogate `S` whose TI-hardness is bounded by `εT` on dimension
      `nT`,
    * Two encoders `encTC : Tensor3 nT F → Finset (Fin mC → F)` and
      `encCG : Finset (Fin mC → F) → (Fin kG → Fin kG → Bool)` at the
      chain's dimensions `(nT, mC, kG)`,
    * Three per-encoding reduction Props, each witnessed at the stated
      encoder and advantage bounds,
    the chain delivers `ConcreteOIA scheme ε` via
    `concreteOIA_from_chain`.

    **Fields (summary).**
    * `nT, mC, kG` — dimension parameters for the three layers.
    * `encTC : Tensor3 nT F → Finset (Fin mC → F)` — Tensor → CE encoder.
    * `encCG : Finset (Fin mC → F) → (Fin kG → Fin kG → Bool)` — CE → GI
      encoder.
    * `εT, εC, εG : ℝ` — per-layer advantage bounds.
    * `tensor_hard` — surrogate-bound universal tensor hardness.
    * `tensor_to_ce` / `ce_to_gi` / `gi_to_oia` — per-encoding reduction
      Props naming the encoders. The `gi_to_oia` field takes a
      chain-image GI-hardness hypothesis (universal over the tensor
      pairs produced by composing `encCG ∘ encTC`) rather than
      universal GI hardness over every adjacency pair; this is what
      makes compositional closure possible without a coverage
      obligation on the encoders.

    **Satisfiability.** `tight_one_exists` inhabits the chain at `ε = 1`
    with `S := punitSurrogate F`, `nT = mC = kG = 0`, and trivial
    encoders. Non-trivial discharges require concrete encoders from the
    cryptographic literature (CFI, Grochow–Qiao) — research follow-ups
    tracked in the audit plan § 15.1. -/
structure ConcreteHardnessChain
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (F : Type*) [Fintype F] [DecidableEq F]
    (S : SurrogateTensor F)
    (ε : ℝ) where
  /-- Tensor dimension at which the chain's tensor-layer surrogate is
      assumed hard. -/
  nT : ℕ
  /-- Code length at which the chain's CE-layer witnesses live. -/
  mC : ℕ
  /-- Graph vertex count at which the chain's GI-layer witnesses live. -/
  kG : ℕ
  /-- Explicit Tensor → Code encoder (Fix C). -/
  encTC : Tensor3 nT F → Finset (Fin mC → F)
  /-- Explicit Code → Graph encoder (Fix C). -/
  encCG : Finset (Fin mC → F) → (Fin kG → Fin kG → Bool)
  /-- Tensor-layer advantage bound. -/
  εT : ℝ
  /-- Code-layer advantage bound. -/
  εC : ℝ
  /-- Graph-layer advantage bound. -/
  εG : ℝ
  /-- Surrogate-bound universal tensor-layer hardness. -/
  tensor_hard : UniversalConcreteTensorOIA (F := F) S εT
  /-- Per-encoding Tensor → CE reduction at encoder `encTC`. -/
  tensor_to_ce :
    ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding S encTC εT εC
  /-- Per-encoding CE → GI reduction at encoder `encCG`. -/
  ce_to_gi :
    ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding (F := F) encCG εC εG
  /-- Per-encoding GI → scheme-OIA reduction consuming the chain's
      image-specific hypothesis through `encTC` and `encCG`. -/
  gi_to_oia :
    ConcreteGIOIAImpliesConcreteOIA_viaEncoding scheme encTC encCG εG ε

namespace ConcreteHardnessChain

/-- **Workstream G chain composition.** A `ConcreteHardnessChain scheme F
    S ε` entails `ConcreteOIA scheme ε`.

    **Proof structure.** The three per-encoding reduction Props thread
    advantage hardness layer by layer, each link consuming the previous
    layer's hardness on specific instances produced by the upstream
    encoders:

    ```
        tensor_hard T₀ T₁ : ConcreteTensorOIA T₀ T₁ εT  for every T₀, T₁
          ↓ tensor_to_ce T₀ T₁ _ : ConcreteCEOIA (encTC T₀) (encTC T₁) εC
          ↓ ce_to_gi (encTC T₀) (encTC T₁) _
              : ConcreteGIOIA (encCG (encTC T₀)) (encCG (encTC T₁)) εG
          ↓ gi_to_oia : ConcreteOIA scheme ε
    ```

    Every reduction layer consumes the previous layer's output
    precisely — no universal-over-all-instances hypothesis is
    manufactured; the chain is strictly per-encoding through the
    upstream image.

    **No `sorry`, no coverage obligation.** The chain's `gi_to_oia`
    field accepts exactly the chain-image GI hardness produced by the
    upstream links, so composition closes without appealing to
    universal GI hardness over all adjacency pairs. -/
theorem concreteOIA_from_chain
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    {scheme : OrbitEncScheme G X M}
    {F : Type*} [Fintype F] [DecidableEq F]
    {S : SurrogateTensor F} {ε : ℝ}
    (hc : ConcreteHardnessChain scheme F S ε) :
    ConcreteOIA scheme ε := by
  -- Apply the GI → scheme-OIA link; its hypothesis is the chain-image
  -- GI hardness, which we construct in the intro below.
  apply hc.gi_to_oia
  intro T₀ T₁
  -- Chain-image GI hardness follows from ce_to_gi applied to the
  -- chain-image CE hardness, which itself follows from tensor_to_ce
  -- applied to the tensor-layer hardness supplied by tensor_hard.
  exact hc.ce_to_gi (hc.encTC T₀) (hc.encTC T₁)
    (hc.tensor_to_ce T₀ T₁ (hc.tensor_hard T₀ T₁))

/-- **Workstream G tight constructor.** Assemble a chain with all three
    per-layer bounds equal to `ε`, with the two encoders named explicitly
    and the tensor surrogate bound.

    The caller supplies:
    * Dimensions `nT, mC, kG`.
    * The two encoders `encTC, encCG`.
    * `ε`.
    * The tensor-hardness hypothesis and three per-encoding reduction
      Props at `(ε, ε)` each. -/
def tight
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    {scheme : OrbitEncScheme G X M}
    {F : Type*} [Fintype F] [DecidableEq F]
    (S : SurrogateTensor F) {ε : ℝ}
    {nT mC kG : ℕ}
    (encTC : Tensor3 nT F → Finset (Fin mC → F))
    (encCG : Finset (Fin mC → F) → (Fin kG → Fin kG → Bool))
    (h_tensor : UniversalConcreteTensorOIA (F := F) S ε)
    (h_tc : ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding S encTC ε ε)
    (h_cg : ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding (F := F) encCG ε ε)
    (h_go :
      ConcreteGIOIAImpliesConcreteOIA_viaEncoding scheme encTC encCG ε ε) :
    ConcreteHardnessChain scheme F S ε :=
  { nT := nT, mC := mC, kG := kG
    encTC := encTC, encCG := encCG
    εT := ε, εC := ε, εG := ε
    tensor_hard := h_tensor
    tensor_to_ce := h_tc, ce_to_gi := h_cg, gi_to_oia := h_go }

/-- **Workstream G non-vacuity witness.** At `ε = 1` with the `PUnit`
    surrogate and dimension-0 trivial encoders, the chain is inhabited.

    **Construction.**
    * Surrogate: `punitSurrogate F` (explicit PUnit witness, bound as
      the structure's `S` parameter).
    * Dimensions: `nT = mC = kG = 0` (degenerate; `Fin 0 → X` types are
      subsingleton).
    * Encoders: at dimension 0 the codomain types are subsingleton-like,
      so constant functions suffice (the empty finset, the false
      adjacency matrix).
    * Tensor hardness at ε = 1: advantage is always ≤ 1 via
      `concreteTensorOIA_one`.
    * Three per-encoding reductions at `(1, 1)`: trivially true via the
      corresponding `_one_one` witnesses.

    This witness **does not** assert quantitative hardness — it only
    exhibits that the chain's type is inhabitable at ε = 1,
    discharging the non-vacuity obligation from the audit plan's
    Exit Criterion #8 (`docs/dev_history/AUDIT_2026-04-21_WORKSTREAM_PLAN.md`
    § 3.6). Concrete quantitative discharges at ε < 1 require
    research-scope encoder witnesses (audit plan § 15.1). -/
theorem tight_one_exists
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (F : Type*) [Fintype F] [DecidableEq F] :
    Nonempty (ConcreteHardnessChain scheme F (punitSurrogate F) 1) :=
  -- Use `nT = mC = kG = 0`; encoders are total functions on
  -- dimension-0 domains.
  let encTC : Tensor3 0 F → Finset (Fin 0 → F) := fun _ => ∅
  let encCG : Finset (Fin 0 → F) → (Fin 0 → Fin 0 → Bool) :=
    fun _ _ _ => false
  ⟨tight (S := punitSurrogate F) (nT := 0) (mC := 0) (kG := 0)
    (encTC := encTC)
    (encCG := encCG)
    (h_tensor := fun T₀ T₁ => concreteTensorOIA_one T₀ T₁)
    (h_tc := concreteTensorOIAImpliesConcreteCEOIA_viaEncoding_one_one
      (punitSurrogate F) encTC)
    (h_cg := concreteCEOIAImpliesConcreteGIOIA_viaEncoding_one_one
      (F := F) encCG)
    (h_go := concreteGIOIAImpliesConcreteOIA_viaEncoding_one_one
      scheme encTC encCG)⟩

/-- **`s2Surrogate` companion non-vacuity witness (W4 of structural
    review 2026-05-06).** The chain is inhabited at `ε = 1` with the
    `S_2`-shaped surrogate `s2Surrogate F` (cardinality 2) and
    dimension-0 trivial encoders. Same content shape as
    `tight_one_exists`, parameterised over `s2Surrogate F` instead of
    `punitSurrogate F`.

    **Why this exists alongside `tight_one_exists`.** A reader
    encountering `tight_one_exists` alone might conclude the chain is
    only inhabitable at `PUnit` (cardinality 1, the trivial group).
    `s2Surrogate` (cardinality 2, the smallest non-trivial finite
    group) breaks that misreading at the type level: the chain
    accepts any `SurrogateTensor F` whose action and encoders satisfy
    the discharge profile, and `s2Surrogate` exhibits a non-trivial
    instance.

    **What this does NOT prove.** Cryptographic ε < 1 hardness
    transfer remains research-scope (R-15-residual-CE-reverse and
    R-15-residual-TI-reverse). The action is trivial (`g • T := T`),
    so the bound is still ε = 1 — only the surrogate cardinality
    moves from 1 to 2. See `docs/dev_history/AUDIT_2026-05-06_STRUCTURAL_REVIEW.md`
    § 1 row 4 for the rationale.

    **Construction.** Identical to `tight_one_exists` except the `S`
    parameter is `s2Surrogate F`. The discharge functions
    (`concreteTensorOIA_one`, the three `*_viaEncoding_one_one`
    discharges) are surrogate-polymorphic, so the same proof
    template applies. -/
theorem tight_one_exists_at_s2Surrogate
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (F : Type*) [Fintype F] [DecidableEq F] :
    Nonempty (ConcreteHardnessChain scheme F (s2Surrogate F) 1) :=
  let encTC : Tensor3 0 F → Finset (Fin 0 → F) := fun _ => ∅
  let encCG : Finset (Fin 0 → F) → (Fin 0 → Fin 0 → Bool) :=
    fun _ _ _ => false
  ⟨tight (S := s2Surrogate F) (nT := 0) (mC := 0) (kG := 0)
    (encTC := encTC)
    (encCG := encCG)
    (h_tensor := fun T₀ T₁ => concreteTensorOIA_one T₀ T₁)
    (h_tc := concreteTensorOIAImpliesConcreteCEOIA_viaEncoding_one_one
      (s2Surrogate F) encTC)
    (h_cg := concreteCEOIAImpliesConcreteGIOIA_viaEncoding_one_one
      (F := F) encCG)
    (h_go := concreteGIOIAImpliesConcreteOIA_viaEncoding_one_one
      scheme encTC encCG)⟩

end ConcreteHardnessChain

-- ============================================================================
-- Probabilistic `hardness_chain_implies_security`
--   Initial form: Workstream E5 (2026-04-18)
--   Post-G form:  threads `{S : SurrogateTensor F}` through the chain
--                 structure (Workstream G, 2026-04-21, finding H1)
-- ============================================================================

/-- **Probabilistic upgrade of `hardness_chain_implies_security`.**

    Given a `ConcreteHardnessChain scheme F S ε` — i.e. a chain with a
    chosen `SurrogateTensor F` (Fix B) and explicit encoder fields
    `encTC, encCG` (Fix C), at per-layer bounds `εT, εC, εG` threading
    through to the target `ε` — the probabilistic IND-1-CPA advantage
    of any adversary on `scheme` is bounded by `ε`.

    Composes `ConcreteHardnessChain.concreteOIA_from_chain` with
    `concrete_oia_implies_1cpa` from `Crypto/CompSecurity.lean`. Unlike
    the deterministic `hardness_chain_implies_security` (which is
    vacuously true because `HardnessChain` extends through the vacuous
    deterministic OIA), this statement bounds the genuine probabilistic
    advantage — subject to the caller supplying a surrogate whose TI
    hardness is genuinely `εT`-bounded (post-Workstream-G, audit
    finding H1).

    **Interpretation.** When the tensor-layer hardness `εT`, the three
    reduction losses `(εT→εC, εC→εG, εG→ε)`, and the scheme's
    IND-1-CPA advantage `ε` are all meaningful `ε < 1`, this theorem
    delivers non-vacuous concrete security for the scheme.

    **History.** The `{S : SurrogateTensor F}` implicit parameter was
    added by Workstream G to fix the pre-G PUnit collapse in
    `UniversalConcreteTensorOIA`; the theorem body is otherwise
    unchanged from the Workstream E5 landing. -/
theorem concrete_hardness_chain_implies_1cpa_advantage_bound
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    {F : Type*} [Fintype F] [DecidableEq F]
    {S : SurrogateTensor F}
    (ε : ℝ) (hc : ConcreteHardnessChain scheme F S ε)
    (A : Adversary X M) :
    indCPAAdvantage scheme A ≤ ε :=
  concrete_oia_implies_1cpa scheme ε
    (ConcreteHardnessChain.concreteOIA_from_chain hc) A

/-- **Probabilistic hardness-chain bound, distinct-challenge framing
    (Workstream K, audit F-AUDIT-2026-04-21-M1).**

    Release-facing restatement of
    `concrete_hardness_chain_implies_1cpa_advantage_bound` matching the
    classical IND-1-CPA game shape (challenger rejects `(m, m)`). Since
    the underlying bound already holds unconditionally on every
    adversary — the collision branch contributes advantage `0` via
    `indCPAAdvantage_collision_zero` — adding a distinctness hypothesis
    yields the same bound for free.

    This is the probabilistic counterpart of
    `hardness_chain_implies_security_distinct` (deterministic K3): it
    pairs the Workstream-K distinct-challenge messaging with the
    non-vacuous ε-smooth content of the probabilistic chain. External
    summaries that cite "TI-hardness ⇒ IND-1-CPA advantage ≤ ε" should
    prefer this corollary because it matches the literature's
    challenger-rejects-`(m, m)` game shape. -/
theorem concrete_hardness_chain_implies_1cpa_advantage_bound_distinct
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    {F : Type*} [Fintype F] [DecidableEq F]
    {S : SurrogateTensor F}
    (ε : ℝ) (hc : ConcreteHardnessChain scheme F S ε)
    (A : Adversary X M)
    (_hDistinct :
      (A.choose scheme.reps).1 ≠ (A.choose scheme.reps).2) :
    indCPAAdvantage scheme A ≤ ε :=
  -- `_hDistinct` is unused: the bound holds unconditionally because
  -- `indCPAAdvantage_collision_zero` shows the collision branch
  -- contributes zero advantage. The hypothesis is retained to make
  -- the classical-IND-1-CPA game shape explicit in the signature.
  concrete_hardness_chain_implies_1cpa_advantage_bound scheme ε hc A

end ConcreteHardnessChainSection

end Orbcrypt
