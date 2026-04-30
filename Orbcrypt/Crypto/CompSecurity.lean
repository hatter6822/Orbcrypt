/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

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
* `Orbcrypt.comp_oia_implies_1cpa` — CompOIA implies computational security
* `Orbcrypt.single_query_bound` — per-query advantage bounded by ConcreteOIA
* `Orbcrypt.indCPAAdvantage_le_one` — Mathlib-style sanity simp lemma:
  `indCPAAdvantage scheme A ≤ 1` for every scheme and adversary. Renamed
  from the pre-Workstream-I `concreteOIA_one_meaningful` so the
  identifier accurately describes its content (a `_le_one` simp lemma in
  the `kemAdvantage_le_one` mould, not a "meaningful" non-vacuity
  claim). Workstream I of the 2026-04-23 audit, finding C-15.
* `Orbcrypt.indCPAAdvantage_eq` — unfolding lemma for IND-1-CPA advantage
* `Orbcrypt.indCPAAdvantage_collision_zero` — when the adversary's
  challenge pair collides (`m₀ = m₁`), the probabilistic IND-1-CPA
  advantage is exactly `0`. Consequence: the `concrete_oia_implies_1cpa`
  upper bound transfers to the classical distinct-challenge IND-1-CPA
  game unchanged — no separate `_distinct` corollary is required at the
  probabilistic level (Workstream K, audit finding
  F-AUDIT-2026-04-21-M1).
* `Orbcrypt.DistinctMultiQueryAdversary` — multi-query adversary wrapper
  with per-query distinctness obligation (audit F-02 / Workstream B3)
* `Orbcrypt.perQueryAdvantage` — per-query distinguishing advantage for a
  multi-query adversary (Workstream B3, prereq for E8)
* `Orbcrypt.perQueryAdvantage_bound_of_concreteOIA` — per-query
  ConcreteOIA bound: each query's advantage is at most `ε`
* `Orbcrypt.indQCPA_from_perStepBound` — multi-query IND-Q-CPA
  advantage bound `≤ Q · ε` delivered from a **caller-supplied**
  per-step hybrid bound `h_step`. Renamed from the pre-Workstream-C
  `indQCPA_bound_via_hybrid` to surface the user-hypothesis
  obligation in the identifier itself (Workstream C of 2026-04-23
  audit plan, finding V1-8 / C-13 / D10). Discharging `h_step` from
  `ConcreteOIA scheme ε` alone requires a per-coordinate
  marginal-independence proof over `uniformPMFTuple`; that is
  research-scope R-09 and remains future work.
* `Orbcrypt.indQCPA_from_perStepBound_recovers_single_query` — Q = 1
  regression sentinel companion to `indQCPA_from_perStepBound`.

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

/--
**Collision case collapses the probabilistic advantage to zero.**

When the adversary's two challenge messages collide — `(A.choose
scheme.reps).1 = (A.choose scheme.reps).2` — the two orbit distributions
`orbitDist (scheme.reps m)` appearing in `indCPAAdvantage` coincide, so
the advantage of any distinguisher between them is exactly `0` via
`advantage_self`.

**Role in the distinct-challenge story (Workstream K, audit
F-AUDIT-2026-04-21-M1).** The scheme-level security game `IsSecure`
carries a stronger predicate than the classical IND-1-CPA game
(`IsSecureDistinct`) because `Adversary.choose` may return a collision
`(m, m)` that the classical challenger would reject. The
`isSecure_implies_isSecureDistinct` theorem in `Crypto/Security.lean`
bridges the two predicates unconditionally.

At the **probabilistic** level, the analogous concern evaporates: this
lemma shows that the `(m, m)` branch contributes advantage zero, so the
`ConcreteOIA(ε)` upper bound `indCPAAdvantage scheme A ≤ ε` delivered
by `concrete_oia_implies_1cpa` already holds unconditionally over all
adversaries, including collision-choice ones. The classical distinct-
challenge form (`(A.choose reps).1 ≠ (A.choose reps).2 →
indCPAAdvantage scheme A ≤ ε`) is therefore a trivial specialisation
of the existing bound — no new `_distinct` theorem is introduced at the
probabilistic layer; consumers requiring the classical game shape can
conjoin their distinctness hypothesis with the unconditional bound
directly. External summaries may still cite
`concrete_oia_implies_1cpa` as the "distinct-challenge IND-1-CPA"
bound because the collision case adds no additional advantage.

See the module docstring for the full rationale and the
audit plan `docs/planning/AUDIT_2026-04-21_WORKSTREAM_PLAN.md` § 6
(Workstream K4).
-/
theorem indCPAAdvantage_collision_zero {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M)
    (hCollision : (A.choose scheme.reps).1 = (A.choose scheme.reps).2) :
    indCPAAdvantage scheme A = 0 := by
  -- `indCPAAdvantage` unfolds to `advantage (A.guess reps) d₀ d₁` with
  -- `d₀ = orbitDist (reps m₀)` and `d₁ = orbitDist (reps m₁)`. Under
  -- the collision hypothesis `m₀ = m₁`, the two distributions are
  -- definitionally equal, so the result follows from `advantage_self`.
  unfold indCPAAdvantage
  rw [hCollision]
  exact advantage_self _ _

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
    instantiation.

    **Distinct-challenge form (Workstream K, audit
    F-AUDIT-2026-04-21-M1).** This theorem already delivers the bound
    `≤ ε` for *every* adversary, including those whose `choose` returns
    a collision `(m, m)`. The classical IND-1-CPA game
    (`IsSecureDistinct`) restricts to `m₀ ≠ m₁`; the bound transfers to
    that restricted form for free, because
    `indCPAAdvantage_collision_zero` shows the collision branch
    contributes advantage `0`. Release-facing citations of the form
    "ConcreteOIA(ε) ⇒ distinct-challenge IND-1-CPA advantage ≤ ε" may
    therefore cite this theorem directly, without requiring a
    `_distinct` corollary at the probabilistic level. -/
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

/-- **Mathlib-style sanity simp lemma** (Workstream I1, audit
    2026-04-23 finding C-15). `indCPAAdvantage scheme A ≤ 1` for every
    scheme and every adversary — an immediate corollary of
    `advantage_le_one`. The bound is *not* a non-vacuity claim about
    `ConcreteOIA`: the IND-1-CPA advantage is a property of the
    `advantage` function between any two PMFs, independent of the
    scheme structure.

    **Naming corrective.** Renamed from `concreteOIA_one_meaningful`
    to `indCPAAdvantage_le_one` because the pre-I name overstated the
    content. The "meaningful" satisfaction of `ConcreteOIA scheme ε`
    happens at ε ≪ 1, not at ε = 1; the bound proven here is purely a
    triangle-inequality consequence of the `advantage` definition. The
    new name follows the Mathlib convention used by
    `kemAdvantage_le_one` (line 347 of `KEM/CompSecurity.lean`). -/
@[simp]
theorem indCPAAdvantage_le_one {G : Type*} {X : Type*} {M : Type*}
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

/-- Computational security: every adversary family has negligible advantage.

    After F-13 cleanup, this is stated via `sf.advantageAt` / `sf.repsAt`
    helpers rather than a ~20-line inline `@`-threaded expression. The
    unfolded form is definitionally equal; use `simp
    [SchemeFamily.advantageAt, SchemeFamily.orbitDistAt,
    SchemeFamily.repsAt]` to recover it. -/
def CompIsSecure (sf : SchemeFamily) : Prop :=
  ∀ (A : ∀ n, @Adversary (sf.X n) (sf.M n)),
    IsNegligible
      (sf.advantageAt
        (fun n x => (A n).guess (fun m => sf.repsAt n m) x)
        (fun n => ((A n).choose (fun m => sf.repsAt n m)).1)
        (fun n => ((A n).choose (fun m => sf.repsAt n m)).2))

/-- CompOIA implies computational IND-1-CPA security: every adversary family
    has negligible advantage.

    Proof: For each security parameter `λ`, the adversary's advantage is
    bounded by the ConcreteOIA bound. CompOIA makes this bound negligible. -/
theorem comp_oia_implies_1cpa (sf : SchemeFamily)
    (hOIA : CompOIA sf) :
    CompIsSecure sf := by
  intro A
  -- Directly instantiate CompOIA with the adversary's distinguisher and messages.
  exact hOIA
    (fun n x => (A n).guess (fun m => sf.repsAt n m) x)
    (fun n => ((A n).choose (fun m => sf.repsAt n m)).1)
    (fun n => ((A n).choose (fun m => sf.repsAt n m)).2)

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

/-- Single-query advantage bound specialized to a specific adversary:
    if ConcreteOIA holds with bound `ε`, the adversary's advantage on each
    individual query is at most `ε`. This is the building block for
    multi-query security via the hybrid argument.

    A full multi-query IND-Q-CPA theorem would state:
    `indQCPAAdvantage scheme A ≤ Q * ε`
    using the `hybrid_argument` lemma to telescope Q adjacent advantages.
    This requires product distribution infrastructure (`PMF` over `Fin Q → X`)
    which is deferred to a future phase. -/
theorem single_query_bound {G : Type*} {X : Type*} {M : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (hOIA : ConcreteOIA scheme ε)
    (D : X → Bool) (m₀ m₁ : M) :
    advantage D (orbitDist (G := G) (scheme.reps m₀))
      (orbitDist (G := G) (scheme.reps m₁)) ≤ ε :=
  hOIA D m₀ m₁

-- ============================================================================
-- Audit F-02 / Workstream B3: Per-query advantage groundwork (prereq for E8)
-- ============================================================================

/-- Distinct-challenge refinement of `MultiQueryAdversary` (audit F-02 +
    Workstream B3).

    Wraps a `MultiQueryAdversary` with a per-query distinctness obligation:
    for every public representative map `reps : M → X` and every query
    index `i : Fin Q`, the two chosen messages must differ. This matches
    the classical IND-Q-CPA game, where each query's challenge pair must
    satisfy `m₀ ≠ m₁`.

    This is the multi-query analogue of `IsSecureDistinct`'s single-query
    distinctness obligation. Workstream E8 (multi-query security) consumes
    this wrapper so every hybrid step can invoke the single-query
    distinct-challenge game without re-proving per-query distinctness. -/
structure DistinctMultiQueryAdversary (X : Type*) (M : Type*) (Q : ℕ)
    extends MultiQueryAdversary X M Q where
  /-- Every query picks two distinct messages. The quantification runs
      over all public `reps` so the wrapper is usable before the scheme
      fixes a specific representative map. -/
  choose_distinct : ∀ (reps : M → X) (i : Fin Q),
    (choose reps i).1 ≠ (choose reps i).2

/-- Per-query advantage: treating query `i : Fin Q` as a single-query
    game, measure the distinguishing advantage of an arbitrary
    single-query Boolean test `D : X → Bool` between the two orbit
    distributions induced by the adversary's choices at that query
    (audit F-02 + Workstream B3).

    This definition is the unit cell of the hybrid argument. In a full
    multi-query reduction, `D` is constructed by fixing the other Q-1
    ciphertexts (to any hybrid completion) and calling the multi-query
    guess oracle; the per-query advantage is then bounded by the
    single-query `ConcreteOIA` bound (see `single_query_bound` above).
    The product-distribution infrastructure needed to glue the Q per-query
    bounds into a Q·ε multi-query bound is Workstream E7's deliverable. -/
noncomputable def perQueryAdvantage {G : Type*} {X : Type*} {M : Type*} {Q : ℕ}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : MultiQueryAdversary X M Q)
    (D : X → Bool) (i : Fin Q) : ℝ :=
  advantage D
    (orbitDist (G := G) (scheme.reps (A.choose scheme.reps i).1))
    (orbitDist (G := G) (scheme.reps (A.choose scheme.reps i).2))

/-- Per-query advantage is non-negative — immediate from
    `advantage_nonneg` (audit F-02 + Workstream B3). -/
theorem perQueryAdvantage_nonneg {G : Type*} {X : Type*} {M : Type*} {Q : ℕ}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : MultiQueryAdversary X M Q)
    (D : X → Bool) (i : Fin Q) :
    0 ≤ perQueryAdvantage scheme A D i :=
  advantage_nonneg _ _ _

/-- Per-query advantage is at most 1 — immediate from `advantage_le_one`
    (audit F-02 + Workstream B3). -/
theorem perQueryAdvantage_le_one {G : Type*} {X : Type*} {M : Type*} {Q : ℕ}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : MultiQueryAdversary X M Q)
    (D : X → Bool) (i : Fin Q) :
    perQueryAdvantage scheme A D i ≤ 1 :=
  advantage_le_one _ _ _

/-- Per-query bound from `ConcreteOIA`: each query's advantage is at most
    `ε`. Specialises `single_query_bound` at the i-th challenge pair of a
    multi-query adversary — this is the atom that Workstream E8's hybrid
    argument will chain Q times to produce a `Q · ε` multi-query bound
    (audit F-02 + Workstream B3). -/
theorem perQueryAdvantage_bound_of_concreteOIA
    {G : Type*} {X : Type*} {M : Type*} {Q : ℕ}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : MultiQueryAdversary X M Q)
    (ε : ℝ) (hOIA : ConcreteOIA scheme ε)
    (D : X → Bool) (i : Fin Q) :
    perQueryAdvantage scheme A D i ≤ ε :=
  hOIA D (A.choose scheme.reps i).1 (A.choose scheme.reps i).2

-- ============================================================================
-- Workstream E8 — Multi-query IND-Q-CPA via the hybrid argument
-- ============================================================================

section MultiQueryHybrid

variable {G : Type*} {X : Type*} {M : Type*}
  [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]

/-- **Workstream E7c / E8a helper.** Scheme-level hybrid distribution over
    ciphertext tuples.

    Parameters:
    * `scheme` — the target orbit encryption scheme.
    * `choose : Fin Q → M × M` — per-query message pairs (the multi-query
      adversary's `choose` function after fixing the public `reps`).
    * `i : ℕ` — hybrid index. Coordinates with `j.val < i` sample from the
      *left* message's orbit; coordinates with `j.val ≥ i` sample from the
      *right* message's orbit.

    At `i = 0` all coordinates sample from right messages; at `i ≥ Q` all
    coordinates sample from left messages. Adjacent hybrids `(i, i+1)`
    differ only at coordinate `i`.

    **Construction.** Sample a uniform tuple of group elements
    `gs : Fin Q → G` and build the ciphertext tuple pointwise by applying
    the appropriate orbit element. Per-coordinate independence lives in
    the `uniformPMFTuple` push-forward. -/
noncomputable def hybridDist
    (scheme : OrbitEncScheme G X M) {Q : ℕ}
    (choose : Fin Q → M × M) (i : ℕ) : PMF (Fin Q → X) :=
  PMF.map (fun gs : Fin Q → G => fun j : Fin Q =>
    if j.val < i
    then gs j • scheme.reps (choose j).1
    else gs j • scheme.reps (choose j).2)
    (uniformPMFTuple G Q)

/-- **Workstream E8a.** Probabilistic IND-Q-CPA advantage for a distinct
    multi-query adversary.

    The adversary receives `Q` ciphertexts drawn either all from the *left*
    messages of its per-query choices or all from the *right* messages,
    then tries to guess which world it's in. The advantage is the
    absolute difference between its winning probabilities in the two
    worlds.

    Defined as the advantage of the adversary's guess function between
    the all-left hybrid (`hybridDist … Q`) and the all-right hybrid
    (`hybridDist … 0`). -/
noncomputable def indQCPAAdvantage {Q : ℕ}
    (scheme : OrbitEncScheme G X M) (A : MultiQueryAdversary X M Q) : ℝ :=
  advantage (A.guess scheme.reps)
    (hybridDist scheme (A.choose scheme.reps) Q)
    (hybridDist scheme (A.choose scheme.reps) 0)

/-- `indQCPAAdvantage` is non-negative. -/
theorem indQCPAAdvantage_nonneg {Q : ℕ}
    (scheme : OrbitEncScheme G X M) (A : MultiQueryAdversary X M Q) :
    0 ≤ indQCPAAdvantage scheme A :=
  advantage_nonneg _ _ _

/-- `indQCPAAdvantage` is at most 1. -/
theorem indQCPAAdvantage_le_one {Q : ℕ}
    (scheme : OrbitEncScheme G X M) (A : MultiQueryAdversary X M Q) :
    indQCPAAdvantage scheme A ≤ 1 :=
  advantage_le_one _ _ _

/-- **Workstream E8c.** Multi-query IND-Q-CPA advantage bound from a
    user-supplied per-step hybrid bound.

    **Game shape.** This theorem delivers a `Q · ε` bound on the
    multi-query IND-Q-CPA advantage **given** a per-query bound
    `h_step` that the caller must discharge. The caller is responsible
    for supplying `h_step`; the theorem then performs the hybrid
    telescoping via `hybrid_argument_uniform` from
    `Probability/Advantage.lean`.

    **User-supplied hypothesis obligation.** `h_step i hi` is the
    single-query bound for the adjacent hybrid pair `(i, i+1)`. The
    cryptographic content is that when only coordinate `i` differs
    between the two distributions, marginalising over the other
    coordinates yields a single-query distinguisher on `X`, whose
    advantage is bounded by `ConcreteOIA scheme ε` applied to the
    `i`-th challenge pair. Discharging `h_step` from `ConcreteOIA
    scheme ε` alone requires a per-coordinate marginal-independence
    proof over `uniformPMFTuple`; this is **research-scope** work —
    see `docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § 18 /
    research milestone R-09. Until R-09 lands, consumers supply
    `h_step` from custom analysis or from a stronger assumption
    (e.g., a query-adaptive variant of `ConcreteOIA`).

    **Naming discipline (Workstream C of 2026-04-23 audit plan,
    finding V1-8 / C-13).** The `from_perStepBound` suffix surfaces
    the user-supplied obligation in the identifier itself, per
    `CLAUDE.md`'s naming rule that identifiers must describe what
    the code *proves*, not what it *aspires to*. External
    release-facing prose that summarises this theorem must carry
    the `h_step` disclosure. -/
theorem indQCPA_from_perStepBound {Q : ℕ}
    (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (A : MultiQueryAdversary X M Q)
    (h_step : ∀ i, i < Q →
      advantage (A.guess scheme.reps)
        (hybridDist scheme (A.choose scheme.reps) i)
        (hybridDist scheme (A.choose scheme.reps) (i + 1)) ≤ ε) :
    indQCPAAdvantage scheme A ≤ (Q : ℝ) * ε := by
  unfold indQCPAAdvantage
  -- Symmetrise: `advantage` is `|a - b|` which is symmetric.
  rw [advantage_symm]
  -- Apply `hybrid_argument_uniform` with `hybrids i = hybridDist … i`.
  exact hybrid_argument_uniform Q
    (fun i => hybridDist scheme (A.choose scheme.reps) i)
    (A.guess scheme.reps) ε h_step

/-- **Workstream E8d.** Regression check: at `Q = 1`, the multi-query
    bound `Q · ε = ε` recovers the single-query advantage bound —
    provided the single per-step hybrid bound matches
    `concrete_oia_implies_1cpa`. Sanity sentinel.

    Renamed from `indQCPA_bound_recovers_single_query` in Workstream C
    (2026-04-23 audit plan, finding V1-8 / C-13) to keep the
    `from_perStepBound` terminology consistent with the main theorem;
    the shared prefix makes the companion's dependency on a caller-
    supplied per-step bound explicit in the identifier itself. -/
theorem indQCPA_from_perStepBound_recovers_single_query
    (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (A : MultiQueryAdversary X M 1)
    (h_step : advantage (A.guess scheme.reps)
        (hybridDist scheme (A.choose scheme.reps) 0)
        (hybridDist scheme (A.choose scheme.reps) 1) ≤ ε) :
    indQCPAAdvantage scheme A ≤ ε := by
  have h1 :=
    indQCPA_from_perStepBound (Q := 1) scheme ε A
      (fun i hi => by
        interval_cases i
        exact h_step)
  simpa using h1

end MultiQueryHybrid

-- ============================================================================
-- Workstream R-09 — Discharge of `h_step` from `ConcreteOIA`
-- (audit 2026-04-29 § 8.1, research-scope discharge plan § R-09)
-- ============================================================================

section R09

variable {G : Type*} {X : Type*} {M : Type*}
  [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]

/-- **R-09 — Per-step hybrid bound from `ConcreteOIA`.**

    Discharges the user-supplied `h_step` hypothesis of
    `indQCPA_from_perStepBound` from `ConcreteOIA scheme ε` alone:
    for every adjacent hybrid pair `(i, i+1)` with `i < Q`, the
    distinguishing advantage of `A.guess` is at most `ε`.

    **Mathematical content (Workstream R-09 plan).** The two adjacent
    hybrids differ only at coordinate `j₀ := ⟨i, hi⟩ : Fin Q`: at j₀,
    one samples from `orbit (scheme.reps right)` and the other from
    `orbit (scheme.reps left)`. Off j₀, the two distributions agree
    pointwise. Marginalising over the other coordinates (the "rest")
    reduces the global advantage to a per-rest single-coordinate
    advantage, which is bounded by `ConcreteOIA scheme ε`. The
    convexity-of-TV step is encapsulated in
    `advantage_pmf_map_uniform_pi_factor_bound`
    (`Probability/Advantage.lean`).

    **Proof outline.**
    1. Pattern-match Q: at Q = 0, hi : i < 0 is impossible.
    2. At Q = n + 1, set j₀ := ⟨i, hi⟩.
    3. Apply `advantage_pmf_map_uniform_pi_factor_bound` at j₀ and
       the F_i / F_{i+1} push-forwards.
    4. Discharge the per-rest hypothesis: for each `rest`, define
       a single-coord distinguisher `D_rest` that absorbs the rest
       of the tuple, then apply ConcreteOIA at the per-rest pair
       (right, left) of orbit distributions.

    **Closes** the Workstream-D research-scope catalogue's R-09:
    the multi-query bound `indQCPA_from_perStepBound` no longer
    requires a user-supplied per-step hypothesis when
    `ConcreteOIA scheme ε` is available. -/
theorem hybrid_step_bound_of_concreteOIA {Q : ℕ}
    (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (A : MultiQueryAdversary X M Q) (hOIA : ConcreteOIA scheme ε)
    (i : ℕ) (hi : i < Q) :
    advantage (A.guess scheme.reps)
      (hybridDist scheme (A.choose scheme.reps) i)
      (hybridDist scheme (A.choose scheme.reps) (i + 1)) ≤ ε := by
  classical
  -- Pattern-match Q to get the n+1 form needed by the abstract helper.
  match Q, hi, A with
  | 0, hi, _ => exact absurd hi (Nat.not_lt_zero _)
  | n + 1, hi, A =>
    -- Setup: j₀, choose, F_i, F_succ.
    let j₀ : Fin (n + 1) := ⟨i, hi⟩
    let choose := A.choose scheme.reps
    let F_i : (Fin (n + 1) → G) → (Fin (n + 1) → X) :=
      fun gs => fun j => if j.val < i
        then gs j • scheme.reps (choose j).1
        else gs j • scheme.reps (choose j).2
    let F_succ : (Fin (n + 1) → G) → (Fin (n + 1) → X) :=
      fun gs => fun j => if j.val < i + 1
        then gs j • scheme.reps (choose j).1
        else gs j • scheme.reps (choose j).2
    -- The hybridDist's are exactly PMF.map F_i / F_succ over uniformPMFTuple.
    show advantage (A.guess scheme.reps)
        (PMF.map F_i (uniformPMFTuple G (n + 1)))
        (PMF.map F_succ (uniformPMFTuple G (n + 1))) ≤ ε
    unfold uniformPMFTuple
    -- Apply the abstract helper. The per-rest hypothesis remains.
    apply advantage_pmf_map_uniform_pi_factor_bound j₀ F_i F_succ
      (A.guess scheme.reps) ε
    -- Discharge the per-rest hypothesis.
    intro rest
    -- For each rest, build the "rest ciphertext" tuple — the values
    -- at j ≠ j₀ in F_i (insertNth j₀ a rest), which agrees with F_succ
    -- at those positions because the test (j.val < i) ↔ (j.val < i+1)
    -- holds for every j ≠ j₀.
    let restCipher : Fin n → X := fun k =>
      if (j₀.succAbove k).val < i
        then rest k • scheme.reps (choose (j₀.succAbove k)).1
        else rest k • scheme.reps (choose (j₀.succAbove k)).2
    -- Define the per-rest single-coord distinguisher.
    let D_rest : X → Bool := fun x =>
      A.guess scheme.reps (Fin.insertNth j₀ x restCipher)
    -- Key structural identities: F_i (insertNth j₀ a rest) and
    -- F_succ (insertNth j₀ a rest) decompose into "insertNth j₀ (a • reps_?)
    -- restCipher".
    have h_F_i_eq : ∀ a : G,
        F_i (Fin.insertNth j₀ a rest) =
          Fin.insertNth j₀ (a • scheme.reps (choose j₀).2) restCipher := by
      intro a
      ext j
      -- Case-split: j = j₀ or j = j₀.succAbove k for some k.
      by_cases h_j_eq : j = j₀
      · -- j = j₀. F_i evaluates to gs j₀ • reps right; insertNth gives a.
        subst h_j_eq
        simp only [F_i, Fin.insertNth_apply_same]
        -- Goal: (if j₀.val < i then ... else ...) = a • reps right.
        -- j₀.val = i, so j₀.val < i is false.
        have h_not_lt : ¬ j₀.val < i := by
          show ¬ i < i
          exact Nat.lt_irrefl i
        rw [if_neg h_not_lt]
      · -- j = j₀.succAbove k. F_i evaluates via the test on j.val < i.
        -- Need to relate to restCipher k. The two are constructed identically.
        obtain ⟨k, rfl⟩ := Fin.exists_succAbove_eq h_j_eq
        simp only [F_i, Fin.insertNth_apply_succAbove, restCipher]
    have h_F_succ_eq : ∀ a : G,
        F_succ (Fin.insertNth j₀ a rest) =
          Fin.insertNth j₀ (a • scheme.reps (choose j₀).1) restCipher := by
      intro a
      ext j
      by_cases h_j_eq : j = j₀
      · subst h_j_eq
        simp only [F_succ, Fin.insertNth_apply_same]
        -- j₀.val = i < i + 1 is true.
        have h_lt : j₀.val < i + 1 := Nat.lt_succ_self i
        rw [if_pos h_lt]
      · obtain ⟨k, rfl⟩ := Fin.exists_succAbove_eq h_j_eq
        simp only [F_succ, Fin.insertNth_apply_succAbove, restCipher]
        -- The two `if` conditions agree off j₀. Specifically:
        -- (j₀.succAbove k).val < i ↔ (j₀.succAbove k).val < i + 1.
        -- Both reduce to `k.val < i` (= `k.val < j₀.val`).
        by_cases h_k_lt : (j₀.succAbove k).val < i
        · -- Then also < i + 1.
          have : (j₀.succAbove k).val < i + 1 := Nat.lt_succ_of_lt h_k_lt
          rw [if_pos this, if_pos h_k_lt]
        · -- Then also ≥ i + 1 (since (j₀.succAbove k).val ≠ i = j₀.val).
          have h_ne_i : (j₀.succAbove k).val ≠ i := by
            intro h_eq
            apply h_j_eq
            -- (j₀.succAbove k).val = i = j₀.val implies j₀.succAbove k = j₀.
            apply Fin.eq_of_val_eq
            -- Hmm, j is opposite-indexed; we need j₀ = j.
            -- Actually we proved j = j₀.succAbove k, but the variable substitution
            -- in `obtain ⟨k, rfl⟩` made `j` become `j₀.succAbove k`. So
            -- h_j_eq is `¬ j₀.succAbove k = j₀`.
            -- Use Fin.succAbove_ne to conclude.
            exfalso
            exact Fin.succAbove_ne j₀ k (Fin.eq_of_val_eq h_eq)
          have h_ge : i + 1 ≤ (j₀.succAbove k).val :=
            Nat.lt_iff_add_one_le.mp
              (lt_of_le_of_ne (Nat.le_of_not_lt h_k_lt) (Ne.symm h_ne_i))
          have h_not_lt_succ : ¬ (j₀.succAbove k).val < i + 1 := Nat.not_lt.mpr h_ge
          rw [if_neg h_not_lt_succ, if_neg h_k_lt]
    -- Now use the structural identities to rewrite the per-rest sum.
    have h_guess_F_i : ∀ a,
        A.guess scheme.reps (F_i (Fin.insertNth j₀ a rest))
        = D_rest (a • scheme.reps (choose j₀).2) := fun a => by
      rw [h_F_i_eq a]
    have h_guess_F_succ : ∀ a,
        A.guess scheme.reps (F_succ (Fin.insertNth j₀ a rest))
        = D_rest (a • scheme.reps (choose j₀).1) := fun a => by
      rw [h_F_succ_eq a]
    simp_rw [h_guess_F_i, h_guess_F_succ]
    -- Goal: |∑ a, ((D_rest (a • reps right)).indicator
    --             − (D_rest (a • reps left)).indicator)| ≤ |G| * ε
    -- Use the abstract advantage on orbitDist and ConcreteOIA.
    -- Step 1: bridge the indicator-sum to (filter card)-difference.
    rw [Finset.sum_sub_distrib]
    -- Each sum is a filter cardinality (cast to ℝ).
    rw [show (∑ a : G, (if D_rest (a • scheme.reps (choose j₀).2) = true
                          then (1 : ℝ) else 0))
            = ((Finset.univ.filter
                 (fun a : G =>
                   D_rest (a • scheme.reps (choose j₀).2) = true)).card : ℝ)
            from (Finset.natCast_card_filter _ _).symm,
        show (∑ a : G, (if D_rest (a • scheme.reps (choose j₀).1) = true
                          then (1 : ℝ) else 0))
            = ((Finset.univ.filter
                 (fun a : G =>
                   D_rest (a • scheme.reps (choose j₀).1) = true)).card : ℝ)
            from (Finset.natCast_card_filter _ _).symm]
    -- Step 2: convert each (filter card)/|G| to a probTrue value, then
    -- recognise the difference as |G| * advantage. Apply ConcreteOIA.
    -- Use the observation: for any m : M,
    --   (filter (fun a => D_rest (a • reps m)) ).card.toReal
    --     = |G| * (probTrue (orbitDist (reps m)) D_rest).toReal
    have h_filter_to_probTrue : ∀ m : M,
        ((Finset.univ.filter
            (fun a : G => D_rest (a • scheme.reps m) = true)).card : ℝ)
        = (Fintype.card G : ℝ) *
          (probTrue (orbitDist (G := G) (scheme.reps m)) D_rest).toReal := by
      intro m
      -- (filter ...).card / |G| = probTrue (PMF.map (· • reps m) (uniformPMF G)) D_rest = probTrue (orbitDist (reps m)) D_rest.
      have h_pos : 0 < Fintype.card G := Fintype.card_pos
      have h_card_real_pos : (0 : ℝ) < (Fintype.card G : ℝ) := by exact_mod_cast h_pos
      have h_step :
          ((Finset.univ.filter
              (fun a : G => D_rest (a • scheme.reps m) = true)).card : ℝ)
            / (Fintype.card G : ℝ) =
          (probTrue (orbitDist (G := G) (scheme.reps m)) D_rest).toReal := by
        rw [orbitDist]
        rw [probTrue_PMF_map_uniformPMF_toReal]
      field_simp at h_step
      linarith [h_step]
    rw [h_filter_to_probTrue (choose j₀).2, h_filter_to_probTrue (choose j₀).1]
    -- Goal: |(|G| * pt_right) - (|G| * pt_left)| ≤ |G| * ε
    rw [show (Fintype.card G : ℝ) *
            (probTrue (orbitDist (G := G) (scheme.reps (choose j₀).2)) D_rest).toReal
          - (Fintype.card G : ℝ) *
            (probTrue (orbitDist (G := G) (scheme.reps (choose j₀).1)) D_rest).toReal
          = (Fintype.card G : ℝ) *
            ((probTrue (orbitDist (G := G) (scheme.reps (choose j₀).2)) D_rest).toReal
            - (probTrue (orbitDist (G := G) (scheme.reps (choose j₀).1)) D_rest).toReal)
          from by ring]
    rw [abs_mul, abs_of_nonneg (by positivity : (0 : ℝ) ≤ (Fintype.card G : ℝ))]
    -- Goal: |G| * |pt_right - pt_left| ≤ |G| * ε
    -- The right factor is exactly advantage D_rest (orbitDist right) (orbitDist left).
    rw [show |(probTrue (orbitDist (G := G) (scheme.reps (choose j₀).2)) D_rest).toReal
              - (probTrue (orbitDist (G := G) (scheme.reps (choose j₀).1)) D_rest).toReal|
            = advantage D_rest
                (orbitDist (G := G) (scheme.reps (choose j₀).2))
                (orbitDist (G := G) (scheme.reps (choose j₀).1))
          from rfl]
    -- Multiply both sides by |G| and apply ConcreteOIA.
    apply mul_le_mul_of_nonneg_left _ (by positivity : (0 : ℝ) ≤ (Fintype.card G : ℝ))
    exact hOIA D_rest (choose j₀).2 (choose j₀).1

/-- **R-09 headline — Multi-query IND-Q-CPA bound from `ConcreteOIA`.**

    The unconditional discharge of R-09: for every `Q`, the multi-query
    IND-Q-CPA advantage of any adversary `A` against `scheme` is bounded
    by `Q · ε`, given only `ConcreteOIA scheme ε`. This is the
    Mathlib-grade upgrade of `indQCPA_from_perStepBound` (which
    requires a user-supplied `h_step`).

    **Closes Workstream D research-scope catalogue R-09.** Pre-R-09,
    `indQCPA_from_perStepBound` was the consumer-facing entry-point
    but required `h_step` from custom analysis. R-09 discharges
    `h_step` from `ConcreteOIA scheme ε` alone via
    `hybrid_step_bound_of_concreteOIA`, removing the user's hypothesis
    obligation.

    The bound `Q · ε` matches the standard hybrid-argument scaling
    and is achieved by `hybrid_argument_uniform` (linearity of
    advantage along Q adjacent steps).

    See `indQCPA_from_concreteOIA_recovers_single_query` for the
    `Q = 1` regression sentinel and `indQCPA_from_concreteOIA_distinct`
    for the classical-game form (Workstream-K-style). -/
theorem indQCPA_from_concreteOIA {Q : ℕ}
    (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (A : MultiQueryAdversary X M Q) (hOIA : ConcreteOIA scheme ε) :
    indQCPAAdvantage scheme A ≤ (Q : ℝ) * ε := by
  apply indQCPA_from_perStepBound scheme ε A
  intro i hi
  exact hybrid_step_bound_of_concreteOIA scheme ε A hOIA i hi

/-- **R-09 — Q = 1 regression sentinel.** At `Q = 1`, the multi-query
    bound `Q · ε = ε` matches the single-query advantage bound from
    `concrete_oia_implies_1cpa`. Confirms the multi-query result
    specialises correctly. -/
theorem indQCPA_from_concreteOIA_recovers_single_query
    (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (A : MultiQueryAdversary X M 1) (hOIA : ConcreteOIA scheme ε) :
    indQCPAAdvantage scheme A ≤ ε := by
  have h := indQCPA_from_concreteOIA (Q := 1) scheme ε A hOIA
  simpa using h

/-- **R-09 — Distinct-challenge classical-game form.** The classical
    IND-Q-CPA game (parallels `IsSecureDistinct` for single-query)
    rejects per-query `(m, m)` collisions. The probabilistic bound
    transfers to the distinct-challenge form for free because the
    bound holds *uniformly* for all adversaries (collision-choice or
    not). This mirrors Workstream K's `_distinct` corollaries. -/
theorem indQCPA_from_concreteOIA_distinct {Q : ℕ}
    (scheme : OrbitEncScheme G X M) (ε : ℝ)
    (A : DistinctMultiQueryAdversary X M Q) (hOIA : ConcreteOIA scheme ε) :
    indQCPAAdvantage scheme A.toMultiQueryAdversary ≤ (Q : ℝ) * ε :=
  indQCPA_from_concreteOIA scheme ε A.toMultiQueryAdversary hOIA

end R09

end Orbcrypt
