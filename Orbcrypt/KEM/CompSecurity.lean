/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.KEM.Security
import Orbcrypt.Probability.Monad
import Orbcrypt.Probability.Advantage
import Orbcrypt.Crypto.CompOIA
import Orbcrypt.Hardness.Reductions

/-!
# Orbcrypt.KEM.CompSecurity

Probabilistic (computational) Key Encapsulation Mechanism security. Lifts
`KEMOIA` from the vacuous deterministic Prop to an ε-bounded probabilistic
Prop, then proves a quantitative security reduction (KEM version of
`concrete_oia_implies_1cpa`).

## Main definitions

* `Orbcrypt.kemEncapsDist` — joint distribution of (ciphertext, key) under
  uniform group-element sampling (Workstream E1a).
* `Orbcrypt.ConcreteKEMOIA` — probabilistic KEMOIA with explicit ε bound
  (Workstream E1b).
* `Orbcrypt.kemAdvantage` — per-pair KEM distinguishing advantage of an
  adversary between two encapsulation point masses (Workstream E1d).

## Main results

* `Orbcrypt.kemEncapsDist_support` — support is exactly the image of `encaps`.
* `Orbcrypt.kemEncapsDist_pos_of_reachable` — every reachable pair has
  positive probability.
* `Orbcrypt.concreteKEMOIA_one` — `ConcreteKEMOIA kem 1` is trivially true
  (satisfiability witness).
* `Orbcrypt.concreteKEMOIA_mono` — monotonicity in the bound.
* `Orbcrypt.concrete_kemoia_implies_secure` — main reduction: for any
  adversary and any pair `g₀, g₁ : G`, the per-pair KEM advantage is
  bounded by `ε` (Workstream E1d).

## Workstream H additions (audit 2026-04-21, H2)

* `Orbcrypt.ConcreteOIAImpliesConcreteKEMOIAUniform` — probabilistic
  scheme-to-KEM reduction Prop (H1): transfer a `ConcreteOIA` bound
  to the KEM-layer uniform form `ConcreteKEMOIA_uniform` on a derived
  `scheme.toKEM` KEM.
* `Orbcrypt.concreteOIAImpliesConcreteKEMOIAUniform_one_right` —
  satisfiability witness at the right bound `ε' = 1` (H2), the KEM
  analogue of the `_one_one` witnesses in `Hardness/Reductions.lean`.
* `Orbcrypt.ConcreteKEMHardnessChain` — structure packaging a
  scheme-level `ConcreteHardnessChain` (Workstream G) with the
  scheme-to-KEM reduction Prop, delivering the KEM-layer
  ε-smooth hardness chain (H3).
* `Orbcrypt.concreteKEMHardnessChain_implies_kemUniform` — composition
  theorem: a `ConcreteKEMHardnessChain` entails
  `ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) ε`.
* `Orbcrypt.ConcreteKEMHardnessChain.tight_one_exists` — non-vacuity
  witness at ε = 1 via `punitSurrogate` + dimension-0 trivial
  encoders, matching the scheme-level
  `ConcreteHardnessChain.tight_one_exists`.
* `Orbcrypt.concrete_kem_hardness_chain_implies_kem_advantage_bound` —
  end-to-end KEM-layer adversary bound: composes the KEM chain with
  `concrete_kemoia_uniform_implies_secure` to deliver
  `kemAdvantage_uniform (scheme.toKEM m₀ keyDerive) A g_ref ≤ ε`,
  mirroring the scheme-level
  `concrete_hardness_chain_implies_1cpa_advantage_bound`.

## Relationship to KEMOIA (Phase 7)

The deterministic `KEMOIA` of `KEM/Security.lean` is `False` for any scheme
with ≥ 2 distinct orbit elements — the Boolean "is c = basePoint" function
refutes its first conjunct. `ConcreteKEMOIA kem 1` is always true, and
intermediate values of `ε` parameterise realistic security (smaller ε =
stronger security). Workstream E1 bridges the two: `det_kemoia_implies_
concreteKEMOIA_zero` shows the deterministic form is the zero-advantage
specialisation of the probabilistic form.

## References

* `docs/dev_history/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § E1 — Workstream E1
* `Orbcrypt/Crypto/CompOIA.lean` — the analogue `ConcreteOIA` on
  `OrbitEncScheme`, whose API this module mirrors.
* `Orbcrypt/KEM/Security.lean` — the deterministic `KEMOIA` this module
  refines.
-/

namespace Orbcrypt

open PMF ENNReal

variable {G : Type*} {X : Type*} {K : Type*}

-- ============================================================================
-- Workstream E1a — KEM encapsulation distribution
-- ============================================================================

/-- The joint distribution of the KEM encapsulation output under the uniform
    group law: sample `g ← uniformPMF G`, return `(g • basePoint,
    keyDerive (canon (g • basePoint)))`.

    This is the natural probabilistic counterpart of `encaps kem g`: marginalising
    the secret coin `g` produces a distribution over (ciphertext, key) pairs
    that an adversary sees during the KEM security game.

    The codomain is `PMF (X × K)`; the computation is the composition
    `PMF.map encaps uniformPMF`. -/
noncomputable def kemEncapsDist [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) : PMF (X × K) :=
  PMF.map (fun g => encaps kem g) (uniformPMF G)

/-- Elements with positive probability under `kemEncapsDist` lie in the image
    of `encaps` — i.e. are reachable as `encaps kem g` for some `g : G`. -/
theorem kemEncapsDist_support [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (p : X × K)
    (hp : (kemEncapsDist kem : PMF (X × K)) p ≠ 0) :
    ∃ g : G, encaps kem g = p := by
  -- `hp` says p is in the support of `PMF.map encaps uniformPMF`.
  have hmem : p ∈ (kemEncapsDist kem : PMF (X × K)).support := hp
  rw [kemEncapsDist, PMF.support_map] at hmem
  -- `hmem : p ∈ encaps kem '' (uniformPMF G).support`; destructure the witness.
  obtain ⟨g, _, hg⟩ := hmem
  exact ⟨g, hg⟩

/-- Every reachable encapsulation pair has positive probability under
    `kemEncapsDist`. Dual of `kemEncapsDist_support`. -/
theorem kemEncapsDist_pos_of_reachable [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (g : G) :
    (kemEncapsDist kem : PMF (X × K)) (encaps kem g) ≠ 0 := by
  show encaps kem g ∈ (kemEncapsDist kem : PMF (X × K)).support
  rw [kemEncapsDist, PMF.support_map]
  exact ⟨g, mem_support_uniformPMF g, rfl⟩

-- ============================================================================
-- Workstream E1b — ConcreteKEMOIA: probabilistic KEM indistinguishability
-- ============================================================================

/-- **Probabilistic KEM-OIA (point-mass form)** with explicit advantage
    bound `ε`.

    Every Boolean distinguisher on `X × K` has advantage at most `ε` when
    telling apart two encapsulation point masses `PMF.pure (encaps kem g₀)`
    and `PMF.pure (encaps kem g₁)` for any pair of group elements.

    **Audit disclosure (2026-04-20 post-landing review).** The point-mass
    form is *semantically binary*. For any two `α`-valued point masses
    `PMF.pure p₀`, `PMF.pure p₁` and any `D : α → Bool`:

    * `probTrue (PMF.pure p) D = if D p then 1 else 0`, so
    * `advantage D (PMF.pure p₀) (PMF.pure p₁) ∈ {0, 1}` — it is `0` when
      `D p₀ = D p₁` and `1` otherwise.

    Consequently `ConcreteKEMOIA kem ε` for `ε ∈ [0, 1)` is equivalent to
    `ConcreteKEMOIA kem 0`: any non-zero advantage is exactly `1`, so
    bounding by `ε < 1` forces the 0-advantage (agreement) case. Only
    `ε = 1` is a strictly-weaker predicate (trivially true).

    **What this definition *does* capture.** For `ε < 1` the predicate is
    equivalent to the deterministic "no Boolean `D : X × K → Bool`
    distinguishes `encaps kem g₀` from `encaps kem g₁`" — the first
    conjunct of `KEMOIA` promoted to act on the full `(c, k)` pair. It is
    a genuine refinement of `KEMOIA`'s ciphertext indistinguishability
    conjunct, but it inherits that conjunct's unsatisfiability for schemes
    with ≥ 2 distinct orbit elements (the `decide (c = basePoint)`
    distinguisher refutes it at `ε = 0`).

    **For a genuinely ε-smooth KEM security predicate** see
    `ConcreteKEMOIA_uniform` below, which replaces the point masses with
    the uniform-over-G push-forward `kemEncapsDist` — there the advantage
    can take any value in `[0, 1]` as `g` varies, so intermediate `ε`
    parameterise meaningful security.

    **Why keep the point-mass form.** It is what the audit plan
    (§ E1b) called out as the minimum viable predicate, and the
    natural starting point for `ConcreteKEMOIA_uniform`'s
    quantitative refinement (which see below). The pre-W6.2 link to
    a deterministic-to-probabilistic bridge
    `det_kemoia_implies_concreteKEMOIA_zero` was removed as part of
    the deterministic-chain deletion scheduled for v0.4.0. -/
def ConcreteKEMOIA [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (ε : ℝ) : Prop :=
  ∀ (D : X × K → Bool) (g₀ g₁ : G),
    advantage D (PMF.pure (encaps kem g₀)) (PMF.pure (encaps kem g₁)) ≤ ε

/-- **Probabilistic KEM-OIA (uniform-distribution form)** with explicit
    advantage bound `ε` — the genuinely ε-smooth predicate.

    Every Boolean distinguisher on `X × K` has advantage at most `ε` when
    telling apart the joint encapsulation distribution `kemEncapsDist kem`
    from itself when indexed by two different "reference" encapsulations
    `encaps kem g₀`, `encaps kem g₁`. Concretely:

    * LHS: sample `g ← uniformPMF G`, output `encaps kem g`.
    * RHS: `PMF.pure (encaps kem g_ref)` for a specific `g_ref : G`.

    The advantage can take any real value in `[0, 1]` as the adversary
    picks `g_ref` and `D`, so `ε ∈ (0, 1)` parameterises a non-vacuous
    security spectrum (unlike the point-mass form above).

    **Why this pattern.** A KEM has a *single* orbit (the basepoint's),
    so there is no "left vs. right orbit" indistinguishability game to
    play (as in `ConcreteOIA` on a full `OrbitEncScheme`). The natural
    question is instead: "How close is a freshly-sampled encapsulation
    to any fixed reference encapsulation?" — bounding that closeness by
    ε is the KEM-level analogue of the scheme-level advantage bound.

    **Relation to the point-mass form.** Any `D : X × K → Bool` satisfies
    `advantage D (kemEncapsDist kem) (PMF.pure (encaps kem g_ref)) =
     |Pr_{g ∼ U(G)}[D(encaps kem g)] - [D(encaps kem g_ref) = true]|`,
    which equals the pointwise-averaged distance between
    `probTrue (PMF.pure (encaps g)) D` and `probTrue (PMF.pure
    (encaps g_ref)) D`. The point-mass form bounds individual terms;
    the uniform form bounds their average. For a `KEMOIA`-satisfying
    kem, all individual terms are zero and so is the average; for
    intermediate ε, the uniform form admits quantitative refinements
    the point-mass form cannot express. -/
def ConcreteKEMOIA_uniform [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (ε : ℝ) : Prop :=
  ∀ (D : X × K → Bool) (g_ref : G),
    advantage D (kemEncapsDist kem) (PMF.pure (encaps kem g_ref)) ≤ ε

/-- `ConcreteKEMOIA_uniform kem 1` is trivially true: advantage is always
    bounded by 1. Satisfiability witness for the uniform form. -/
theorem concreteKEMOIA_uniform_one [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) : ConcreteKEMOIA_uniform kem 1 :=
  fun D _ => advantage_le_one D _ _

/-- The uniform form is monotone in the bound. -/
theorem concreteKEMOIA_uniform_mono [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) {ε₁ ε₂ : ℝ}
    (hle : ε₁ ≤ ε₂) (hOIA : ConcreteKEMOIA_uniform kem ε₁) :
    ConcreteKEMOIA_uniform kem ε₂ :=
  fun D g_ref => le_trans (hOIA D g_ref) hle

/-- `ConcreteKEMOIA` with `ε = 1` is trivially true: advantage is bounded
    by 1 for any distinguisher and any pair of distributions. Satisfiability
    witness for the definition, mirroring `concreteOIA_one`. -/
theorem concreteKEMOIA_one [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) : ConcreteKEMOIA kem 1 :=
  fun D _ _ => advantage_le_one D _ _

/-- `ConcreteKEMOIA` is monotone in the bound: a tighter bound implies a
    looser one. -/
theorem concreteKEMOIA_mono [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) {ε₁ ε₂ : ℝ}
    (hle : ε₁ ≤ ε₂) (hOIA : ConcreteKEMOIA kem ε₁) :
    ConcreteKEMOIA kem ε₂ :=
  fun D g₀ g₁ => le_trans (hOIA D g₀ g₁) hle

-- W6.2 of structural review 2026-05-06: the deterministic-to-
-- probabilistic KEM bridge `det_kemoia_implies_concreteKEMOIA_zero`
-- (formerly defined here, Workstream E1c) was deleted as part of
-- the deterministic-chain removal scheduled for v0.4.0. The
-- probabilistic chain (`ConcreteKEMOIA`, `ConcreteKEMOIA_uniform`,
-- `ConcreteKEMHardnessChain`) is the sole security chain post-
-- deletion; the bridge to the deleted deterministic `KEMOIA` is
-- no longer meaningful.

-- ============================================================================
-- Workstream E1d — Probabilistic KEM security reduction
-- ============================================================================

/-- Per-pair KEM advantage of adversary `A` against two encapsulation point
    masses. This is the KEM analogue of `indCPAAdvantage`: the adversary
    sees a single encapsulation and tries to distinguish which group element
    generated it.

    Quantifying over the pair `(g₀, g₁)` outside the definition preserves
    the pointwise nature of the bound delivered by `ConcreteKEMOIA`. -/
noncomputable def kemAdvantage [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (A : KEMAdversary X K) (g₀ g₁ : G) : ℝ :=
  advantage (fun p => A.guess kem.basePoint p.1 p.2)
    (PMF.pure (encaps kem g₀)) (PMF.pure (encaps kem g₁))

/-- `kemAdvantage` is non-negative. -/
theorem kemAdvantage_nonneg [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (A : KEMAdversary X K) (g₀ g₁ : G) :
    0 ≤ kemAdvantage kem A g₀ g₁ :=
  advantage_nonneg _ _ _

/-- `kemAdvantage` is at most 1. -/
theorem kemAdvantage_le_one [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (A : KEMAdversary X K) (g₀ g₁ : G) :
    kemAdvantage kem A g₀ g₁ ≤ 1 :=
  advantage_le_one _ _ _

/-- **Main KEM security reduction (point-mass form).** If `ConcreteKEMOIA
    kem ε` holds, every adversary has per-pair KEM advantage at most ε.

    This is the probabilistic-flavoured upgrade of `kemoia_implies_secure`
    from `KEM/Security.lean`. `ConcreteKEMOIA kem 1` is trivially true (see
    `concreteKEMOIA_one`), so the reduction is non-vacuously applicable at
    ε = 1.

    **Point-mass caveat.** Because `ConcreteKEMOIA` compares two
    `PMF.pure` point masses, its advantage is 0 or 1 per `(g₀, g₁)` pair,
    so `ConcreteKEMOIA kem ε` for `ε ∈ [0, 1)` is equivalent to
    `ConcreteKEMOIA kem 0` (cf. the definition's docstring). Intermediate
    ε in `[0, 1)` therefore do not add content *to this reduction*. For
    a genuinely ε-smooth reduction, see
    `concrete_kemoia_uniform_implies_secure` below, which uses the
    uniform-over-G form `ConcreteKEMOIA_uniform`.

    **Proof.** `kemAdvantage` unfolds to the advantage of a specific
    distinguisher (the adversary's guess function applied to the base point
    and the encapsulation components) between two specific point masses.
    `ConcreteKEMOIA` bounds the advantage of ALL distinguishers between ALL
    encapsulation point-mass pairs; the conclusion is immediate by
    instantiation. -/
theorem concrete_kemoia_implies_secure [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (ε : ℝ)
    (hOIA : ConcreteKEMOIA kem ε) (A : KEMAdversary X K)
    (g₀ g₁ : G) :
    kemAdvantage kem A g₀ g₁ ≤ ε :=
  hOIA (fun p => A.guess kem.basePoint p.1 p.2) g₀ g₁

-- Pre-Workstream-I (audit 2026-04-23 finding E-11): this section
-- held `concreteKEMOIA_one_meaningful` (deleted — duplicated
-- `kemAdvantage_le_one`). The 2026-04-25 follow-up audit further
-- removed `concreteKEMOIA_uniform_zero_of_singleton_orbit` as
-- theatrical (singleton-orbit hypothesis collapses the game).
-- Honest non-vacuity story: `concreteKEMOIA_uniform_one`.

-- ============================================================================
-- Workstream E1d (continued) — Uniform-form KEM security reduction
-- ============================================================================

/-- **Uniform-form KEM advantage.** Distinguishing advantage of adversary
    `A` between the uniform-over-G encapsulation distribution
    `kemEncapsDist kem` and a specific reference encapsulation point mass
    `PMF.pure (encaps kem g_ref)`.

    This is the uniform-form analogue of `kemAdvantage`. Unlike the
    point-mass form (where advantage collapses to 0 or 1 per `(g₀, g₁)`
    pair), the uniform-form advantage can take any real value in `[0, 1]`
    as `D` and `g_ref` vary, so intermediate ε values are genuinely
    expressive.

    The adversary's guess is applied to the (ciphertext, key) pair. -/
noncomputable def kemAdvantage_uniform [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (A : KEMAdversary X K) (g_ref : G) : ℝ :=
  advantage (fun p => A.guess kem.basePoint p.1 p.2)
    (kemEncapsDist kem) (PMF.pure (encaps kem g_ref))

/-- `kemAdvantage_uniform` is non-negative. -/
theorem kemAdvantage_uniform_nonneg [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (A : KEMAdversary X K) (g_ref : G) :
    0 ≤ kemAdvantage_uniform kem A g_ref :=
  advantage_nonneg _ _ _

/-- `kemAdvantage_uniform` is at most 1. -/
theorem kemAdvantage_uniform_le_one [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (A : KEMAdversary X K) (g_ref : G) :
    kemAdvantage_uniform kem A g_ref ≤ 1 :=
  advantage_le_one _ _ _

/-- **Uniform-form KEM security reduction.** If `ConcreteKEMOIA_uniform
    kem ε` holds, every adversary has uniform KEM advantage at most ε,
    at every reference `g_ref`.

    This is the genuinely ε-smooth KEM reduction: unlike
    `concrete_kemoia_implies_secure` (which uses the point-mass
    `ConcreteKEMOIA` that collapses on `[0, 1)`), this reduction admits
    intermediate ε values that bound real-vs-reference advantage. -/
theorem concrete_kemoia_uniform_implies_secure
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (ε : ℝ)
    (hOIA : ConcreteKEMOIA_uniform kem ε) (A : KEMAdversary X K)
    (g_ref : G) :
    kemAdvantage_uniform kem A g_ref ≤ ε :=
  hOIA (fun p => A.guess kem.basePoint p.1 p.2) g_ref

-- ============================================================================
-- Workstream H (audit 2026-04-21, finding H2, MEDIUM) —
-- KEM-layer ε-smooth hardness chain via `ConcreteKEMOIA_uniform`
-- ============================================================================
--
-- ## Scope and motivation
--
-- Workstream G (finding H1, HIGH) closed the scheme-level probabilistic
-- hardness chain: `ConcreteHardnessChain scheme F S ε` bundles a
-- surrogate choice plus three per-encoding reduction Props, and
-- `ConcreteHardnessChain.concreteOIA_from_chain` delivers
-- `ConcreteOIA scheme ε` via `concrete_oia_implies_1cpa`, which yields
-- an `ε`-bounded probabilistic IND-1-CPA advantage for any adversary.
--
-- Finding H2 observes that the KEM-layer analogue is missing:
-- * `kemoia_implies_secure` transports deterministic `KEMOIA` through
--   the (vacuous) deterministic surface;
-- * `concrete_kemoia_implies_secure` transports the point-mass
--   `ConcreteKEMOIA`, which collapses on `ε ∈ [0, 1)` (point-mass
--   advantage is 0 or 1);
-- * the genuinely ε-smooth KEM predicate `ConcreteKEMOIA_uniform` has
--   a security reduction (`concrete_kemoia_uniform_implies_secure`)
--   but **no chain-level entry point** — downstream KEM consumers
--   must assemble a scheme-to-KEM step by hand, and there is no
--   `TI-hardness → KEM-uniform-OIA` pipeline parallel to Workstream G.
--
-- This section closes the gap in three steps (H1 / H2 / H3 per the
-- audit plan `docs/dev_history/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 4):
--
-- * **H1.** `ConcreteOIAImpliesConcreteKEMOIAUniform` — the abstract
--   reduction Prop, stated as a `Prop`-valued definition (matching
--   the Workstream-G pattern of per-encoding reduction Props).
-- * **H2.** `concreteOIAImpliesConcreteKEMOIAUniform_one_right` —
--   trivial satisfiability witness at ε' = 1, the KEM analogue of
--   Workstream G's `_one_one` anchors. This is the non-vacuity
--   foundation for `ConcreteKEMHardnessChain.tight_one_exists`
--   below.
-- * **H3.** `ConcreteKEMHardnessChain` — structure packaging the
--   scheme-level chain with the scheme-to-KEM reduction Prop,
--   plus `concreteKEMHardnessChain_implies_kemUniform` (composition)
--   and `ConcreteKEMHardnessChain.tight_one_exists` (non-vacuity).

-- ============================================================================
-- Workstream H1 — probabilistic scheme-to-KEM reduction Prop
-- ============================================================================

/-- **Workstream H1 — probabilistic scheme-to-KEM reduction Prop.**

    A `ConcreteOIA scheme ε` bound on an `OrbitEncScheme`'s
    orbit-indistinguishability advantage transfers to a
    `ConcreteKEMOIA_uniform kem ε'` bound on the derived KEM
    `scheme.toKEM m₀ keyDerive`, with potentially relaxed `ε'`. The
    predicate is parameterised by the `m₀ : M` that anchors the KEM's
    base point (`(scheme.toKEM m₀ keyDerive).basePoint = scheme.reps
    m₀`) and by the caller's `keyDerive : X → K`.

    **Why `Prop`-valued rather than a proved theorem.** Matching the
    Workstream-G design for the per-encoding reduction Props, this is
    stated as an abstract obligation the caller supplies. The
    scheme-to-KEM reduction is **not** a free algebraic consequence
    of `ConcreteOIA scheme ε`: the scheme-level predicate bounds the
    advantage between two *orbit distributions*, whereas the KEM
    uniform predicate bounds the advantage between a *uniform orbit
    distribution* and a *point mass on a specific orbit element*.
    Translating the former into the latter requires quantitative
    reasoning about how `keyDerive` interacts with the PMF
    push-forward — a `keyDerive`-specific, concrete-mathematics
    obligation. Concrete discharges (e.g. when `keyDerive` is a
    random-oracle idealisation) supply a proof; this predicate makes
    the obligation explicit at the chain's KEM layer.

    **Non-vacuity anchor.** `concreteOIAImpliesConcreteKEMOIAUniform_
    one_right` exhibits the Prop at `ε' = 1` unconditionally, which
    is what the Workstream-H non-vacuity witness
    (`ConcreteKEMHardnessChain.tight_one_exists`) uses.

    **References.**
    * `docs/dev_history/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 4.3 (H1).
    * `Orbcrypt/Hardness/Reductions.lean` for the companion per-encoding
      reduction Props (`*_viaEncoding`) this predicate mirrors at the
      KEM layer. -/
def ConcreteOIAImpliesConcreteKEMOIAUniform
    {G : Type*} {X : Type*} {M : Type*} {K : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (m₀ : M) (keyDerive : X → K)
    (ε ε' : ℝ) : Prop :=
  ConcreteOIA scheme ε →
    ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) ε'

/-- **Workstream H2 — satisfiability witness at `ε' = 1`.**

    The scheme-to-KEM reduction Prop is unconditionally inhabited when
    the target KEM-uniform bound is `1`: the conclusion
    `ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) 1` is a direct
    specialisation of `concreteKEMOIA_uniform_one`.

    **Role.** This lemma is the KEM-layer counterpart of Workstream G's
    `*_one_one` anchors (e.g.
    `concreteTensorOIAImpliesConcreteCEOIA_viaEncoding_one_one`). It
    discharges the scheme-to-KEM field of `ConcreteKEMHardnessChain`
    at ε = 1 without assuming anything about the source ε — hence the
    signature `∀ ε, ... scheme m₀ keyDerive ε 1`.

    **What this does NOT provide.** At `ε' < 1` the Prop requires a
    genuine concrete-mathematics discharge (see the H1 docstring).
    This anchor is the type-level non-vacuity witness only. -/
theorem concreteOIAImpliesConcreteKEMOIAUniform_one_right
    {G : Type*} {X : Type*} {M : Type*} {K : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m₀ : M) (keyDerive : X → K) (ε : ℝ) :
    ConcreteOIAImpliesConcreteKEMOIAUniform scheme m₀ keyDerive ε 1 :=
  fun _ => concreteKEMOIA_uniform_one (scheme.toKEM m₀ keyDerive)

-- ============================================================================
-- Workstream H3 — `ConcreteKEMHardnessChain` + composition
-- ============================================================================

/-- **Workstream H3 — KEM-layer ε-smooth hardness chain.**

    Packages the scheme-level `ConcreteHardnessChain scheme F S ε`
    (Workstream G Fix B + Fix C, surrogate-bound and per-encoding) with
    a scheme-to-KEM reduction Prop witness, delivering the KEM-layer
    hardness chain parallel to the scheme-layer chain.

    **Fields.**
    * `chain : ConcreteHardnessChain scheme F S ε` — the scheme-level
      Workstream-G chain at bound `ε`.
    * `scheme_to_kem : ConcreteOIAImpliesConcreteKEMOIAUniform scheme
      m₀ keyDerive ε ε` — Workstream-H1 reduction Prop at the matched
      source / target advantage bounds.

    **Chain semantics.** Composing the two fields via
    `concreteKEMHardnessChain_implies_kemUniform` yields
    `ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) ε` — the
    genuinely ε-smooth KEM security predicate.

    **Why a separate structure (rather than extending
    `ConcreteHardnessChain`).** The KEM is anchored at a specific
    `m₀ : M` and a specific `keyDerive : X → K`, parameters that the
    scheme-level chain does not carry. Introducing a sibling structure
    keeps both chain flavours clean (scheme-level = every `m`,
    KEM-level = one `m₀` and one `keyDerive`).

    **Satisfiability.** `ConcreteKEMHardnessChain.tight_one_exists`
    inhabits the KEM chain at ε = 1 via `punitSurrogate F` +
    dimension-0 trivial encoders + the `_one_right` discharge — the
    KEM analogue of `ConcreteHardnessChain.tight_one_exists`.

    **References.** Audit plan § 4 (H2 / H3). -/
structure ConcreteKEMHardnessChain
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (F : Type*) [Fintype F] [DecidableEq F]
    (S : SurrogateTensor F)
    {K : Type*}
    (m₀ : M) (keyDerive : X → K)
    (ε : ℝ) where
  /-- Underlying Workstream-G scheme-level hardness chain at bound `ε`. -/
  chain : ConcreteHardnessChain scheme F S ε
  /-- Workstream-H1 reduction Prop at matched source/target bound `(ε, ε)`. -/
  scheme_to_kem :
    ConcreteOIAImpliesConcreteKEMOIAUniform scheme m₀ keyDerive ε ε

/-- **Workstream H3 composition theorem.**

    A `ConcreteKEMHardnessChain scheme F S m₀ keyDerive ε` entails
    `ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) ε`.

    **Proof.** The chain's scheme-to-KEM field is a function
    `ConcreteOIA scheme ε → ConcreteKEMOIA_uniform (scheme.toKEM m₀
    keyDerive) ε`. Feed it the scheme-level `ConcreteOIA scheme ε`
    obtained by composing the four fields of the Workstream-G chain
    via `ConcreteHardnessChain.concreteOIA_from_chain`.

    **Quantitative meaning.** If the caller supplies:
    * a surrogate `S : SurrogateTensor F` whose TI-hardness is
      `εT`-bounded,
    * encoders `encTC`, `encCG` whose per-encoding reduction Props
      hold at the claimed `(εT→εC, εC→εG, εG→ε)` losses,
    * and a scheme-to-KEM reduction witness at `(ε, ε)`,
    the chain's ε reflects genuine, compositionally-threaded
    hardness all the way from TI to the KEM's uniform encapsulation
    advantage.

    **Non-vacuity.** See `ConcreteKEMHardnessChain.tight_one_exists`
    below for the ε = 1 witness via `punitSurrogate` + dimension-0
    trivial encoders. -/
theorem concreteKEMHardnessChain_implies_kemUniform
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    {scheme : OrbitEncScheme G X M}
    {F : Type*} [Fintype F] [DecidableEq F]
    {S : SurrogateTensor F}
    {K : Type*} {m₀ : M} {keyDerive : X → K} {ε : ℝ}
    (hc : ConcreteKEMHardnessChain scheme F S m₀ keyDerive ε) :
    ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) ε :=
  hc.scheme_to_kem (ConcreteHardnessChain.concreteOIA_from_chain hc.chain)

namespace ConcreteKEMHardnessChain

/-- **Workstream H3 non-vacuity witness.**

    For every scheme, field type `F`, KEM anchor `m₀ : M`, and key
    derivation `keyDerive : X → K`, there is an inhabitant of
    `ConcreteKEMHardnessChain scheme F (punitSurrogate F) m₀
    keyDerive 1`.

    **Construction.**
    * `chain` — supplied by `ConcreteHardnessChain.tight_one_exists`
      (Workstream G), which uses `punitSurrogate F`, dimension-0 trivial
      encoders (empty finset + false adjacency), and discharges each
      per-encoding reduction Prop at its `_one_one` witness.
    * `scheme_to_kem` — supplied by
      `concreteOIAImpliesConcreteKEMOIAUniform_one_right`, which is
      trivially true at `ε' = 1` because
      `ConcreteKEMOIA_uniform _ 1` is unconditionally true.

    **Interpretation.** This witness does **not** assert any
    quantitative KEM-level hardness — it only certifies that the
    chain's type is inhabitable at ε = 1, matching Exit Criterion
    #4 in the audit plan (`docs/planning/AUDIT_2026-04-21_WORKSTREAM_
    PLAN.md` § 4.5). Meaningful `ε < 1` witnesses require concrete
    surrogate + encoder + keyDerive discharges (research-scope
    follow-ups, tracked in the audit plan § 15.1). -/
theorem tight_one_exists
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (F : Type*) [Fintype F] [DecidableEq F]
    {K : Type*} (m₀ : M) (keyDerive : X → K) :
    Nonempty
      (ConcreteKEMHardnessChain scheme F (punitSurrogate F)
        m₀ keyDerive 1) :=
  let ⟨chain⟩ := ConcreteHardnessChain.tight_one_exists scheme F
  ⟨{ chain := chain
     scheme_to_kem :=
       concreteOIAImpliesConcreteKEMOIAUniform_one_right
         scheme m₀ keyDerive 1 }⟩

end ConcreteKEMHardnessChain

/-- **Probabilistic KEM-layer security bound from the hardness chain.**

    Given a `ConcreteKEMHardnessChain scheme F S m₀ keyDerive ε`, every
    KEM adversary `A` has uniform-form advantage at most `ε` at every
    reference encapsulation `g_ref`.

    This is the KEM-layer analogue of
    `concrete_hardness_chain_implies_1cpa_advantage_bound`: that
    theorem composes the scheme-level chain with
    `concrete_oia_implies_1cpa` to deliver `indCPAAdvantage ≤ ε`; this
    theorem composes the KEM-level chain with
    `concrete_kemoia_uniform_implies_secure` to deliver
    `kemAdvantage_uniform ≤ ε`.

    **Proof.** Two-step composition. First
    `concreteKEMHardnessChain_implies_kemUniform hc` extracts the
    `ConcreteKEMOIA_uniform` predicate at bound `ε`. Then
    `concrete_kemoia_uniform_implies_secure` applies that predicate to
    any specific adversary + reference group element, delivering the
    pointwise advantage bound.

    **Non-vacuity.** At ε = 1 this is always true (advantage ≤ 1 for
    any adversary), inhabited via `ConcreteKEMHardnessChain.tight_one_
    exists` composed with this theorem. At ε < 1 the bound reflects
    the caller-supplied chain's quantitative hardness. -/
theorem concrete_kem_hardness_chain_implies_kem_advantage_bound
    {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    {scheme : OrbitEncScheme G X M}
    {F : Type*} [Fintype F] [DecidableEq F]
    {S : SurrogateTensor F}
    {K : Type*} {m₀ : M} {keyDerive : X → K} {ε : ℝ}
    (hc : ConcreteKEMHardnessChain scheme F S m₀ keyDerive ε)
    (A : KEMAdversary X K) (g_ref : G) :
    kemAdvantage_uniform (scheme.toKEM m₀ keyDerive) A g_ref ≤ ε :=
  concrete_kemoia_uniform_implies_secure (scheme.toKEM m₀ keyDerive) ε
    (concreteKEMHardnessChain_implies_kemUniform hc) A g_ref

end Orbcrypt
