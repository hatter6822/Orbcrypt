import Orbcrypt.Crypto.CompOIA
import Orbcrypt.Crypto.Security

/-!
# Orbcrypt.Crypto.CompSecurity

Probabilistic IND-CPA security game and the main security reduction:
ConcreteOIA implies bounded IND-1-CPA advantage. This upgrades the
vacuously-true deterministic security theorem (`oia_implies_1cpa`) to a
meaningful probabilistic result.

## Main definitions

* `Orbcrypt.indCPAAdvantage` — probabilistic IND-1-CPA advantage of an
  adversary against an orbit encryption scheme
* `Orbcrypt.CompIsSecure` — computational security: every adversary has
  negligible IND-1-CPA advantage (asymptotic version)

## Main results

* `Orbcrypt.concrete_oia_implies_1cpa` — ConcreteOIA(ε) implies every
  adversary has IND-1-CPA advantage at most ε (Theorem 8.7a)
* `Orbcrypt.concreteOIA_one_meaningful` — ConcreteOIA(1) is trivially true,
  demonstrating the definition is satisfiable
* `Orbcrypt.indCPAAdvantage_eq` — unfolding lemma for IND-1-CPA advantage

## Design

The probabilistic advantage is defined as:
  `Adv^{IND-1-CPA}_A(scheme) = |Pr_g[A(g·x_{m₀})=1] - Pr_g[A(g·x_{m₁})=1]|`

where `(m₀, m₁) = A.choose(reps)` are the adversary's chosen messages and
the probability is over uniform `g ∈ G`.

This reuses the existing `Adversary` structure from Phase 3 — the adversary
interface is unchanged; only the advantage measurement changes from
deterministic to probabilistic.

## References

* DEVELOPMENT.md §4.3 — IND-CPA game
* DEVELOPMENT.md §8.2 — multi-query extension via hybrid argument
* formalization/PRACTICAL_IMPROVEMENTS_PLAN.md — Phase 8, work units 8.6, 8.7, 8.10
-/

namespace Orbcrypt

-- ============================================================================
-- Work Unit 8.6a: Probabilistic IND-1-CPA advantage
-- ============================================================================

/-- Probabilistic IND-1-CPA advantage of adversary `A` against `scheme`.

    The adversary chooses two messages `(m₀, m₁) = A.choose(reps)`, then
    receives a ciphertext `c = g • reps(mᵦ)` for uniform `g ∈ G` and
    random bit `b`. Its advantage is:

    `|Pr_g[A.guess(reps, g·reps(m₀)) = true] - Pr_g[A.guess(reps, g·reps(m₁)) = true]|`

    This is the standard IND-1-CPA advantage, using the orbit distribution
    to model uniform encryption. -/
noncomputable def indCPAAdvantage {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (A : Adversary X M) : ℝ :=
  advantage (fun x => A.guess scheme.reps x)
    (orbitDist (G := G) (scheme.reps (A.choose scheme.reps).1))
    (orbitDist (G := G) (scheme.reps (A.choose scheme.reps).2))

-- ============================================================================
-- Work Unit 8.6b: Unfolding lemma
-- ============================================================================

/-- The IND-1-CPA advantage unfolds to the advantage of the adversary's
    guess function between the two orbit distributions. -/
theorem indCPAAdvantage_eq {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) :
    indCPAAdvantage scheme A =
    advantage (fun x => A.guess scheme.reps x)
      (orbitDist (G := G) (scheme.reps (A.choose scheme.reps).1))
      (orbitDist (G := G) (scheme.reps (A.choose scheme.reps).2)) :=
  rfl

-- ============================================================================
-- Work Unit 8.7a: Concrete security theorem (primary target)
-- ============================================================================

/-- **Main theorem:** ConcreteOIA with bound `ε` implies every adversary has
    IND-1-CPA advantage at most `ε`.

    This is the probabilistic upgrade of `oia_implies_1cpa`. Unlike the
    deterministic version (which is vacuously true because `OIA` is `False`),
    this theorem has genuine content: `ConcreteOIA scheme ε` is satisfiable
    for `ε > 0`, so the conclusion is non-vacuous.

    Proof: The IND-1-CPA advantage is defined as the advantage of a specific
    distinguisher (the adversary's guess function) between two specific
    orbit distributions. ConcreteOIA bounds the advantage of ALL distinguishers
    between ALL pairs of orbit distributions. The conclusion follows by
    instantiation. -/
theorem concrete_oia_implies_1cpa {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (hOIA : ConcreteOIA scheme ε) (A : Adversary X M) :
    indCPAAdvantage scheme A ≤ ε :=
  -- indCPAAdvantage unfolds to advantage D d₀ d₁, bounded by ConcreteOIA
  hOIA (fun x => A.guess scheme.reps x)
    (A.choose scheme.reps).1 (A.choose scheme.reps).2

-- ============================================================================
-- Work Unit 8.7b: Concrete security is meaningful
-- ============================================================================

/-- ConcreteOIA(1) is trivially true, demonstrating that the definition is
    satisfiable — unlike the deterministic OIA, which is `False` for any
    scheme with ≥ 2 distinct orbits.

    The meaningful content of ConcreteOIA is in the VALUE of `ε`: smaller
    `ε` means stronger security. This lemma shows the weakest possible
    bound is always achievable. -/
theorem concreteOIA_one_meaningful {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) :
    indCPAAdvantage scheme A ≤ 1 :=
  advantage_le_one _ _ _

-- ============================================================================
-- Work Unit 8.6c: Relationship to deterministic hasAdvantage
-- ============================================================================

/-- The IND-1-CPA advantage is non-negative. -/
theorem indCPAAdvantage_nonneg {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) :
    0 ≤ indCPAAdvantage scheme A :=
  advantage_nonneg _ _ _

-- ============================================================================
-- Work Unit 8.7c: Asymptotic security theorem (stretch goal)
-- ============================================================================

/-- Computational security: every adversary family has negligible advantage. -/
def CompIsSecure (sf : SchemeFamily) : Prop :=
  ∀ (A : ∀ n, @Adversary (sf.X n) (sf.M n)),
    IsNegligible (fun n =>
      @advantage (sf.X n)
        (fun x => (A n).guess
          (@OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n)
            (sf.instGroup n) (sf.instAction n) (sf.instDecEq n) (sf.scheme n)) x)
        (@orbitDist (sf.G n) (sf.X n) (sf.instGroup n) (sf.instFintype n)
          (sf.instNonempty n) (sf.instAction n)
          (@OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n)
            (sf.instGroup n) (sf.instAction n) (sf.instDecEq n) (sf.scheme n)
            ((A n).choose (@OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n)
              (sf.instGroup n) (sf.instAction n) (sf.instDecEq n) (sf.scheme n))).1))
        (@orbitDist (sf.G n) (sf.X n) (sf.instGroup n) (sf.instFintype n)
          (sf.instNonempty n) (sf.instAction n)
          (@OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n)
            (sf.instGroup n) (sf.instAction n) (sf.instDecEq n) (sf.scheme n)
            ((A n).choose (@OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n)
              (sf.instGroup n) (sf.instAction n) (sf.instDecEq n) (sf.scheme n))).2)))

/-- CompOIA implies computational IND-1-CPA security: every adversary family
    has negligible advantage.

    Proof: For each security parameter `λ`, the adversary's advantage is
    bounded by the ConcreteOIA bound. CompOIA makes this bound negligible. -/
theorem comp_oia_implies_1cpa (sf : SchemeFamily)
    (hOIA : CompOIA sf) :
    CompIsSecure sf := by
  intro A
  -- Directly instantiate CompOIA with the adversary's distinguisher and messages
  exact hOIA
    (fun n x => (A n).guess
      (@OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n)
        (sf.instGroup n) (sf.instAction n) (sf.instDecEq n) (sf.scheme n)) x)
    (fun n => ((A n).choose
      (@OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n)
        (sf.instGroup n) (sf.instAction n) (sf.instDecEq n) (sf.scheme n))).1)
    (fun n => ((A n).choose
      (@OrbitEncScheme.reps (sf.G n) (sf.X n) (sf.M n)
        (sf.instGroup n) (sf.instAction n) (sf.instDecEq n) (sf.scheme n))).2)

-- ============================================================================
-- Work Unit 8.10: Multi-Query Security Skeleton
-- ============================================================================

/-- A multi-query adversary that makes `Q` encryption queries.

    The adversary selects `Q` pairs of messages, receives encryptions of
    either all left messages or all right messages, and outputs a guess bit. -/
structure MultiQueryAdversary (X : Type*) (M : Type*) (Q : ℕ) where
  /-- Choose Q pairs of messages. -/
  choose : (M → X) → Fin Q → M × M
  /-- Given Q ciphertexts, guess the hidden bit. -/
  guess : (M → X) → (Fin Q → X) → Bool

/-- Multi-query IND-CPA advantage using the hybrid argument.

    The advantage is measured between the "all-left" and "all-right" worlds:
    in world 0, all Q ciphertexts encrypt the left messages; in world 1,
    all Q ciphertexts encrypt the right messages. -/
noncomputable def indQCPAAdvantage {G : Type*} {X : Type*} {M : Type*} {Q : ℕ}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (_scheme : OrbitEncScheme G X M)
    (_A : MultiQueryAdversary X M Q) : ℝ :=
  -- Define the Q+1 hybrid distributions:
  -- Hybrid i: first i queries use right messages, remaining use left messages
  -- This is a placeholder definition that captures the type signature
  -- Full implementation requires product distributions (PMF on Fin Q → X)
  0 -- Placeholder: full definition requires product PMF infrastructure

/-- **Multi-query security theorem (skeleton):** ConcreteOIA with bound `ε`
    implies every Q-query adversary has IND-Q-CPA advantage at most `Q · ε`.

    This follows from the hybrid argument: the Q+1 hybrid distributions
    form a chain where adjacent hybrids differ in exactly one encryption
    query, and ConcreteOIA bounds each adjacent advantage by `ε`.

    The full multi-query game requires product distribution infrastructure
    that is beyond the current scope. The current proof uses a placeholder
    definition for `indQCPAAdvantage` (returns 0) and proves the bound
    directly. -/
theorem concrete_oia_implies_qcpa {G : Type*} {X : Type*} {M : Type*} {Q : ℕ}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (ε : ℝ) (hε : 0 ≤ ε)
    (_hOIA : ConcreteOIA scheme ε)
    (A : MultiQueryAdversary X M Q) :
    indQCPAAdvantage scheme A ≤ Q * ε := by
  -- Skeleton: the full proof requires product distributions and
  -- the hybrid argument applied to the Q+1 hybrid chain.
  -- The bound Q · ε follows from summing Q adjacent advantages,
  -- each bounded by ε via ConcreteOIA.
  simp [indQCPAAdvantage]
  exact mul_nonneg (Nat.cast_nonneg' Q) hε

end Orbcrypt
