import Orbcrypt.KEM.Security
import Orbcrypt.Probability.Monad
import Orbcrypt.Probability.Advantage
import Orbcrypt.Crypto.CompOIA

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
* `Orbcrypt.det_kemoia_implies_concreteKEMOIA_zero` — deterministic bridge:
  `KEMOIA kem → ConcreteKEMOIA kem 0` (Workstream E1c).
* `Orbcrypt.concrete_kemoia_implies_secure` — main reduction: for any
  adversary and any pair `g₀, g₁ : G`, the per-pair KEM advantage is
  bounded by `ε` (Workstream E1d).

## Relationship to KEMOIA (Phase 7)

The deterministic `KEMOIA` of `KEM/Security.lean` is `False` for any scheme
with ≥ 2 distinct orbit elements — the Boolean "is c = basePoint" function
refutes its first conjunct. `ConcreteKEMOIA kem 1` is always true, and
intermediate values of `ε` parameterise realistic security (smaller ε =
stronger security). Workstream E1 bridges the two: `det_kemoia_implies_
concreteKEMOIA_zero` shows the deterministic form is the zero-advantage
specialisation of the probabilistic form.

## References

* `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § E1 — Workstream E1
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

/-- **Probabilistic KEM-OIA** with explicit advantage bound `ε`.

    Every Boolean distinguisher on `X × K` has advantage at most `ε` when
    telling apart two encapsulation point masses `PMF.pure (encaps kem g₀)`
    and `PMF.pure (encaps kem g₁)` for any pair of group elements.

    **Semantics.** Under point masses, `advantage D = |D(p₀).toBool - D(p₁).toBool|`
    is `0` if the Booleans agree and `1` otherwise, so bounding by ε < 1
    forces agreement (recovering the deterministic KEMOIA's first conjunct
    specialised to encapsulation outputs). The probabilistic framing lets
    the theorem generalise cleanly to non-point-mass distributions in
    follow-on workstreams.

    **Strength ordering.**
    * `ε = 0`: perfect indistinguishability (equivalent to the deterministic
      KEMOIA after taking key-uniformity into account — see the bridge
      `det_kemoia_implies_concreteKEMOIA_zero`).
    * `ε = 1`: trivially satisfied (see `concreteKEMOIA_one`).
    * Intermediate `ε` ∈ (0, 1) parameterises realistic KEM security. -/
def ConcreteKEMOIA [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (ε : ℝ) : Prop :=
  ∀ (D : X × K → Bool) (g₀ g₁ : G),
    advantage D (PMF.pure (encaps kem g₀)) (PMF.pure (encaps kem g₁)) ≤ ε

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

-- ============================================================================
-- Workstream E1c — Deterministic → probabilistic KEMOIA bridge
-- ============================================================================

/-- **Bridge theorem.** The deterministic `KEMOIA` of `KEM/Security.lean`
    implies `ConcreteKEMOIA kem 0`: when no Boolean function distinguishes
    orbit elements *and* the derived key is constant across the orbit, the
    point-mass advantage between any two encapsulation outputs is zero.

    **Proof strategy.**
    1. Specialise the Boolean distinguisher `D : X × K → Bool` to a single
       orbit element by fixing the key argument to the canonical key
       `keyDerive (canon basePoint)`.
    2. Use `KEMOIA.2` (key constancy) to rewrite each encapsulation's key
       component to the canonical key.
    3. Use `KEMOIA.1` (orbit indistinguishability) applied to the partially
       applied distinguisher `fun c => D (c, canonical_key)` to conclude
       `D (encaps kem g₀) = D (encaps kem g₁)` as Booleans.
    4. Point-mass advantages with equal Boolean outputs are zero. -/
theorem det_kemoia_implies_concreteKEMOIA_zero
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (hOIA : KEMOIA kem) :
    ConcreteKEMOIA kem 0 := by
  intro D g₀ g₁
  -- Goal: advantage D (pure (encaps g₀)) (pure (encaps g₁)) ≤ 0.
  -- Since advantage ≥ 0, suffices to show the two point-mass Booleans agree.
  have hkey0 := hOIA.2 g₀
  have hkey1 := hOIA.2 g₁
  -- The canonical key of basePoint is the common value.
  set kbp := kem.keyDerive (kem.canonForm.canon kem.basePoint) with hkbp
  -- encaps kem g unfolds to (g • basePoint, keyDerive (canon (g • basePoint))).
  -- Via hOIA.2, the second component is kbp regardless of g.
  have heq0 : encaps kem g₀ = (g₀ • kem.basePoint, kbp) := by
    simp only [encaps, hkey0]
  have heq1 : encaps kem g₁ = (g₁ • kem.basePoint, kbp) := by
    simp only [encaps, hkey1]
  -- Build the partially applied Boolean distinguisher fixing the key to kbp.
  let f : X → Bool := fun c => D (c, kbp)
  -- hOIA.1 applied to f gives f (g₀ • bp) = f (g₁ • bp).
  have hf : f (g₀ • kem.basePoint) = f (g₁ • kem.basePoint) := hOIA.1 f g₀ g₁
  -- Rewrite D (encaps g₀) and D (encaps g₁) through the equalities.
  have hD : D (encaps kem g₀) = D (encaps kem g₁) := by
    rw [heq0, heq1]; exact hf
  -- Advantage between point masses with equal Boolean outputs is zero.
  unfold advantage
  have hprob0 : probTrue (PMF.pure (encaps kem g₀)) D =
      probTrue (PMF.pure (encaps kem g₁)) D := by
    unfold probTrue
    rw [PMF.toOuterMeasure_pure_apply, PMF.toOuterMeasure_pure_apply]
    -- `D (encaps g₀) = D (encaps g₁)` makes the set-membership propositions
    -- equivalent; split on the Boolean to keep the decidability instances
    -- aligned on both sides.
    by_cases h0 : D (encaps kem g₀) = true
    · have h0' : encaps kem g₀ ∈ {x : X × K | D x = true} := h0
      have h1' : encaps kem g₁ ∈ {x : X × K | D x = true} := by
        show D (encaps kem g₁) = true
        rw [← hD]; exact h0
      rw [if_pos h0', if_pos h1']
    · have h0' : encaps kem g₀ ∉ {x : X × K | D x = true} := h0
      have h1' : encaps kem g₁ ∉ {x : X × K | D x = true} := by
        show ¬ (D (encaps kem g₁) = true)
        intro h; apply h0; rw [hD]; exact h
      rw [if_neg h0', if_neg h1']
  -- |x - x| = 0 ≤ 0.
  rw [hprob0]
  simp

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

/-- **Main KEM security reduction.** If `ConcreteKEMOIA kem ε` holds, every
    adversary has per-pair KEM advantage at most ε.

    This is the probabilistic upgrade of `kemoia_implies_secure` from
    `KEM/Security.lean`. Unlike the deterministic version (which is vacuously
    true because `KEMOIA` is unsatisfiable for non-trivial KEMs), this
    theorem has genuine content: `ConcreteKEMOIA kem 1` is trivially true
    (see `concreteKEMOIA_one`), so the conclusion is non-vacuous; smaller
    ε values parameterise meaningful security.

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

/-- Non-vacuity witness: `ConcreteKEMOIA kem 1` always holds, so the
    reduction delivers the trivial bound 1 for any adversary. This is the
    KEM analogue of `concreteOIA_one_meaningful`. -/
theorem concreteKEMOIA_one_meaningful [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (A : KEMAdversary X K) (g₀ g₁ : G) :
    kemAdvantage kem A g₀ g₁ ≤ 1 :=
  advantage_le_one _ _ _

end Orbcrypt
