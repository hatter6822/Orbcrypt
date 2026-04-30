/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.GroupAction.Basic
-- Workstream I6 (audit 2026-04-23, finding K-02): the new
-- probabilistic predicate `ObliviousSamplingConcreteHiding` consumes
-- `PMF.map`, `uniformPMF`, `advantage`, and `orbitDist` from the
-- probabilistic foundations layer.
import Orbcrypt.Probability.Monad
import Orbcrypt.Probability.Advantage
import Orbcrypt.Crypto.CompOIA

/-!
# Orbcrypt.PublicKey.ObliviousSampling

Oblivious orbit sampling: a candidate building block for a public-key flavour
of Orbcrypt. The key holder publishes a bundle of orbit samples
(`randomizers : Fin t → X`, each lying in the same orbit of the secret group
`G`). A sender — who does NOT know `G` — can then combine two randomizers via
a fixed `combine : X → X → X` to produce a fresh orbit element, assuming
`combine` preserves orbit membership.

## Phase 13 — Work Units 13.1, 13.2, 13.3

This module addresses three units of the public-key extension workstream:

* **13.1 — Oblivious Orbit Sampling Definition** (`OrbitalRandomizers`,
  `obliviousSample`).
* **13.2 — Oblivious Sampling Correctness** (`oblivious_sample_in_orbit`,
  plus the deterministic sender-privacy `Prop`,
  `ObliviousSamplingPerfectHiding` (renamed from
  `ObliviousSamplingHiding` in Workstream I6, audit 2026-04-23 finding
  K-02), and the **probabilistic** `ObliviousSamplingConcreteHiding`
  predicate added by the same workstream as the genuinely ε-smooth
  analogue suitable for release-facing security claims).
* **13.3 — Randomizer Refresh Protocol** (`refreshRandomizers`, together with
  `refreshRandomizers_in_orbit` and the structural
  **epoch-range-determinism** predicate `RefreshDependsOnlyOnEpochRange`).
  The name captures the actual content of the predicate: the refresh
  bundle depends only on the sampler's outputs over the per-epoch
  index range, *not* on any cryptographic independence notion (see
  the naming-corrective audit note in the docstring for
  `RefreshDependsOnlyOnEpochRange`).

## Workstream I6 additions (audit 2026-04-23, finding K-02)

* `Orbcrypt.ObliviousSamplingPerfectHiding` — renamed from
  `ObliviousSamplingHiding`. The pre-I name overstated its
  cryptographic relevance: the predicate is `False` on every non-
  trivial bundle (`t ≥ 2` with distinct randomizers refute it via
  the index-recovery view). The post-I name accurately conveys its
  strength as the *deterministic perfect-extremum*; the genuinely
  ε-smooth probabilistic analogue is `ObliviousSamplingConcrete-
  Hiding` below.
* `Orbcrypt.oblivious_sampling_view_constant_under_perfect_hiding` —
  renamed companion theorem for `ObliviousSamplingPerfectHiding`.
* `Orbcrypt.ObliviousSamplingConcreteHiding` — probabilistic ε-bounded
  hiding predicate. Asserts that the sender's obliviously-sampled
  output is at advantage ≤ ε from a fresh uniform orbit sample
  (`orbitDist`). For ε = 0 this is "perfect oblivious sampling"; for
  ε > 0 this is ε-computational obliviousness.
* `Orbcrypt.concreteHidingBundle`, `Orbcrypt.concreteHidingCombine`
  — Workstream I post-audit (2026-04-25) **non-degenerate concrete
  fixture** for `ObliviousSamplingConcreteHiding`: a two-randomizer
  bundle on `Bool` under `Equiv.Perm Bool` plus the Boolean-AND
  combine. The orbit has cardinality 2 (maximum on Bool) and the
  combine push-forward is biased, giving a tight on-paper
  worst-case advantage of `1/4`. Replaces the post-Workstream-I
  `_zero_witness` (which was theatrical: required a degenerate
  singleton-orbit bundle that collapses the security game). The
  precise Lean proof of the `1/4` bound is research-scope (R-12);
  see the in-module research-scope note for the on-paper argument.

## Open problem

Finding a `combine` operation that preserves orbit membership **without
revealing `G`** is an open research problem. Standard candidates fail:

* Bit-wise XOR on `Bitstring n` does not preserve Hamming weight (and so
  changes the orbit under any S_n subgroup that acts on bitstrings).
* Composition of permutations (`g₁ • g₂ • x`) is orbit-preserving only because
  the sender already knows two group elements — revealing `G`.

We therefore leave `combine` as a *parameter* carrying an orbit-preservation
proof. Callers must supply both the operation and a witness that it is closed
under the orbit of `basePoint`. See `docs/PUBLIC_KEY_ANALYSIS.md` for a full
discussion.

## References

* `docs/planning/PHASE_13_PUBLIC_KEY_EXTENSION.md` — phase document
* `docs/PUBLIC_KEY_ANALYSIS.md` — feasibility analysis
* `Orbcrypt.KEM.Syntax` — underlying `OrbitKEM` structure (not required here,
  but `OrbitalRandomizers` is designed to slot into a KEM-style API)
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*}

-- ============================================================================
-- Work Unit 13.1: Oblivious Orbit Sampling Definition
-- ============================================================================

/--
A bundle of **orbital randomizers** for a fixed base point.

An `OrbitalRandomizers G X t` consists of a `basePoint : X` together with `t`
points (`randomizers : Fin t → X`) all living in the same orbit of `G`. The
group `G` itself is NOT carried by the structure — only the orbit-membership
certificate. This mirrors the public-key flavour of the construction: the
server publishes the bundle, and the client can consume it without knowing `G`.

**Cryptographic intuition.** The sender should be able to derive a *fresh*
orbit element from the bundle without learning `G`. One natural approach is
to combine two randomizers `r_i, r_j` via a closed operation on the orbit
(see `obliviousSample`). The existence of such an operation is an open
problem (§Phase 13).

**Design notes.**
* `G` is `outParam`-free — we want callers to supply it explicitly, since the
  same orbit may be described by multiple groups.
* The orbit-membership proof is stored as a `∀ i, …` field; this makes
  `ors.in_orbit i` a first-class term available to proofs such as
  `oblivious_sample_in_orbit`.
-/
structure OrbitalRandomizers (G : Type*) (X : Type*) (t : ℕ)
    [Group G] [MulAction G X] where
  /-- Base point of the orbit from which randomizers are drawn. -/
  basePoint : X
  /-- `t` published samples, each in the orbit of `basePoint`. -/
  randomizers : Fin t → X
  /-- Every randomizer lies in the orbit of the base point. -/
  in_orbit : ∀ i : Fin t, randomizers i ∈ MulAction.orbit G basePoint

/--
Oblivious sampling: combine two published randomizers via a client-supplied
`combine : X → X → X` into a fresh orbit element.

The sender provides:
* `combine`: a pure function on `X × X`.
* `hClosed`: a proof that `combine` is closed under the orbit of
  `ors.basePoint`. This is the *cryptographic hypothesis* — if the orbit is
  closed under some simple operation that does not reveal `G`, the sender can
  produce fresh ciphertexts without seeing the secret group.

Indexing is by `Fin t`, matching the size of the published bundle. The choice
of `(i, j)` is the sender's randomness.

**Open problem.** No known `combine` satisfies `hClosed` without leaking `G`
for the concrete HGOE construction. See `docs/PUBLIC_KEY_ANALYSIS.md`.
-/
def obliviousSample [Group G] [MulAction G X] {t : ℕ}
    (ors : OrbitalRandomizers G X t) (combine : X → X → X)
    (_hClosed : ∀ (x y : X), x ∈ MulAction.orbit G ors.basePoint →
      y ∈ MulAction.orbit G ors.basePoint →
      combine x y ∈ MulAction.orbit G ors.basePoint)
    (i j : Fin t) : X :=
  combine (ors.randomizers i) (ors.randomizers j)

/-- Unfold `obliviousSample` to its `combine` call. -/
@[simp]
theorem obliviousSample_eq [Group G] [MulAction G X] {t : ℕ}
    (ors : OrbitalRandomizers G X t) (combine : X → X → X)
    (hClosed : ∀ (x y : X), x ∈ MulAction.orbit G ors.basePoint →
      y ∈ MulAction.orbit G ors.basePoint →
      combine x y ∈ MulAction.orbit G ors.basePoint)
    (i j : Fin t) :
    obliviousSample ors combine hClosed i j =
      combine (ors.randomizers i) (ors.randomizers j) := rfl

-- ============================================================================
-- Work Unit 13.2: Oblivious Sampling Correctness
-- ============================================================================

/--
**Oblivious sampling correctness.** The output of `obliviousSample` lies in
the base point's orbit.

This is a direct application of the closure hypothesis `hClosed`, using the
randomizer orbit-membership proofs bundled in `OrbitalRandomizers`.
-/
theorem oblivious_sample_in_orbit [Group G] [MulAction G X] {t : ℕ}
    (ors : OrbitalRandomizers G X t) (combine : X → X → X)
    (hClosed : ∀ (x y : X), x ∈ MulAction.orbit G ors.basePoint →
      y ∈ MulAction.orbit G ors.basePoint →
      combine x y ∈ MulAction.orbit G ors.basePoint)
    (i j : Fin t) :
    obliviousSample ors combine hClosed i j ∈
      MulAction.orbit G ors.basePoint :=
  hClosed _ _ (ors.in_orbit i) (ors.in_orbit j)

/--
**Sender-privacy requirement, deterministic perfect-extremum form**
(renamed from `ObliviousSamplingHiding` in Workstream I6, audit
2026-04-23 finding K-02).

The whole point of oblivious sampling is that the sender — who sees
only the published randomizers `(ors.randomizers i)` and the public
`combine` operation — learns *nothing* about the secret group `G`.

This Prop formalises hiding via *index-indistinguishability* of the
sender's view: for any Boolean observation on `(r_i, r_j, combine
r_i r_j)` and `(r_k, r_l, combine r_k r_l)`, the observations
coincide. Equivalently, the sender's distribution over
`(input_1, input_2, output)` is invariant under the choice of index
pair.

**Naming corrective (Workstream I6, audit K-02).** The pre-I name
`ObliviousSamplingHiding` suggested cryptographic relevance, but the
predicate is **`False` on every non-trivial bundle** (`t ≥ 2` with
distinct randomizers): the view `view r₀ r₁ x := decide (r₀ =
ors.randomizers 0)` is `true` at `(0, j)` and `false` at `(1, j)`
whenever `randomizers 0 ≠ randomizers 1`. The post-I name
`ObliviousSamplingPerfectHiding` accurately conveys its strength as
the *deterministic perfect-extremum* — it asserts that *all* views
agree on *all* index pairs, which is "perfect" in the strict
deterministic sense (no ε slack).

**For genuinely ε-smooth oblivious-sampling hiding**, see
`ObliviousSamplingConcreteHiding` below: the probabilistic analogue
that admits intermediate ε ∈ (0, 1] expressing real cryptographic
hiding under a stronger pseudo-randomness assumption on `combine`.

Theorems in this module carry `ObliviousSamplingPerfectHiding` as
a hypothesis rather than an axiom so no vacuous security claim is
implied.
-/
def ObliviousSamplingPerfectHiding [Group G] [MulAction G X] {t : ℕ}
    (ors : OrbitalRandomizers G X t) (combine : X → X → X) : Prop :=
  ∀ (view : X → X → X → Bool) (i j k l : Fin t),
    view (ors.randomizers i) (ors.randomizers j)
        (combine (ors.randomizers i) (ors.randomizers j)) =
    view (ors.randomizers k) (ors.randomizers l)
        (combine (ors.randomizers k) (ors.randomizers l))

/--
**Hiding corollary** (renamed from `oblivious_sampling_view_constant`
in Workstream I6, audit 2026-04-23 finding K-02). If
`ObliviousSamplingPerfectHiding` holds, any Boolean view of
`obliviousSample` is independent of the chosen index pair.

This is an immediate extraction: `ObliviousSamplingPerfectHiding` is
precisely the statement that such views coincide. It is stated
separately so callers can use
`oblivious_sampling_view_constant_under_perfect_hiding hHide ...`
without unfolding the definition.

**Naming corrective (Workstream I6).** The rename mirrors the
predicate's rename to `ObliviousSamplingPerfectHiding` — the
companion theorem makes the dependency on the perfect-extremum
hypothesis explicit in the identifier itself.
-/
theorem oblivious_sampling_view_constant_under_perfect_hiding
    [Group G] [MulAction G X] {t : ℕ}
    (ors : OrbitalRandomizers G X t) (combine : X → X → X)
    (hClosed : ∀ (x y : X), x ∈ MulAction.orbit G ors.basePoint →
      y ∈ MulAction.orbit G ors.basePoint →
      combine x y ∈ MulAction.orbit G ors.basePoint)
    (hHide : ObliviousSamplingPerfectHiding ors combine)
    (view : X → X → X → Bool) (i j k l : Fin t) :
    view (ors.randomizers i) (ors.randomizers j)
        (obliviousSample ors combine hClosed i j) =
    view (ors.randomizers k) (ors.randomizers l)
        (obliviousSample ors combine hClosed k l) := by
  simp only [obliviousSample_eq]
  exact hHide view i j k l

-- ============================================================================
-- Workstream I6 (audit 2026-04-23, finding K-02): probabilistic
-- ε-smooth oblivious-sampling hiding predicate + non-vacuity witness.
-- ============================================================================

/--
**Probabilistic oblivious-sampling hiding** (Workstream I6, audit
2026-04-23 finding K-02).

The sender's view of an obliviously-sampled output is ε-close to a
fresh uniform sample of the orbit. Concretely: sample a uniform
index pair `(i, j) : Fin t × Fin t` and apply `combine` to the
corresponding randomizers; the resulting distribution is at
advantage ≤ ε from `orbitDist (G := G) ors.basePoint`.

For ε = 0 this is *perfect oblivious sampling*; for intermediate
ε this is *ε-computational obliviousness* that can be discharged
from a stronger pseudo-randomness assumption on `combine`.

**Replaces the deterministic `ObliviousSamplingPerfectHiding`** —
which is `False` on every non-trivial bundle — with the genuinely
ε-smooth analogue suitable for release-facing security claims.

**Type-class context.** `[Fintype G]` and `[Nonempty G]` are needed
to define `orbitDist`; `[NeZero t]` (i.e. `t ≥ 1`) gives `Nonempty
(Fin t × Fin t)`, which `uniformPMF (Fin t × Fin t)` requires.

**Non-vacuity.** A non-degenerate concrete fixture
`concreteHidingBundle` + `concreteHidingCombine` (post-audit,
2026-04-25) lives below; on paper the worst-case advantage on
that fixture is `1/4` (a tight ε ∈ (0, 1) bound). The Lean proof
of the precise `1/4` bound is research-scope R-12; consumers
needing a non-vacuity claim at the trivial bound `ε = 1` can
discharge `ObliviousSamplingConcreteHiding _ _ 1` directly via
`advantage_le_one`.
-/
def ObliviousSamplingConcreteHiding [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] {t : ℕ} [NeZero t]
    (ors : OrbitalRandomizers G X t)
    (combine : X → X → X) (ε : ℝ) : Prop :=
  ∀ (D : X → Bool),
    advantage D
      (PMF.map (fun (p : Fin t × Fin t) =>
        combine (ors.randomizers p.1) (ors.randomizers p.2))
        (uniformPMF (Fin t × Fin t)))
      (orbitDist (G := G) ors.basePoint) ≤ ε

-- ============================================================================
-- Workstream I post-audit (2026-04-25): non-degenerate concrete
-- fixture for `ObliviousSamplingConcreteHiding` + research-scope
-- disclosure.
--
-- The original Workstream-I `_zero_witness` proved the predicate at
-- ε = 0 on a singleton-orbit (degenerate) bundle — vacuous in the
-- cryptographic sense (no security game to play). The trivial
-- `oblivious_sampling_view_advantage_bound` extraction wrapper was
-- a one-line projection of the predicate's universal quantifier
-- (`hHide D`). Both were removed by the post-audit pass as
-- contributing no cryptographic content.
--
-- Replaced here with a non-degenerate fixture (`concreteHidingBundle`
-- + `concreteHidingCombine`) plus an honest research-scope note
-- documenting the on-paper bound and the reason it is not
-- formalised in-tree.
-- ============================================================================

/-- **Concrete two-randomizer hiding bundle on `Bool`.**

    A small, *non-trivial* `OrbitalRandomizers` bundle used as the
    fixture for the cryptographic-content ε ∈ (0, 1) story below
    (see the research-scope note for the precise on-paper bound).

    * Group: `Equiv.Perm Bool` — the symmetric group on Bool, order 2.
    * Carrier: `Bool` itself, with the standard self-action.
    * Base point: `false`.
    * Two randomizers: `![false, true]`. Both lie in the orbit of
      `false` because the action is transitive (the swap permutation
      maps `false` to `true`).

    The bundle is non-trivial in the cryptographically meaningful
    sense: the orbit of `false` has cardinality 2 (the maximum on
    Bool), so an adversary can in principle distinguish ciphertexts.
    The hiding property is *not* vacuous on this bundle. -/
def concreteHidingBundle : OrbitalRandomizers (Equiv.Perm Bool) Bool 2 where
  basePoint := false
  randomizers := ![false, true]
  in_orbit := fun i => by
    fin_cases i
    · exact ⟨1, rfl⟩
    · refine ⟨Equiv.swap false true, ?_⟩
      show (Equiv.swap false true) false = (![false, true] : Fin 2 → Bool) 1
      rw [Equiv.swap_apply_left]
      rfl

/-- **Combine function: Boolean AND.**

    The `combine` function paired with `concreteHidingBundle`. AND
    is a deliberately *non-uniformising* operation: applied to a
    uniform pair `(i, j) ∈ Fin 2 × Fin 2`, the output `randomizers
    i AND randomizers j` puts mass `1/4` on `true` (only the pair
    `(1, 1)`) and mass `3/4` on `false`. This biased output
    distribution gives a non-zero adversary advantage against the
    uniform orbit distribution; the tight on-paper bound is
    `1/4`. -/
def concreteHidingCombine : Bool → Bool → Bool := fun a b => a && b

/-!
### Research-scope note: precise ε = 1/4 bound for `concreteHidingBundle`

The bundle `concreteHidingBundle` and combine `concreteHidingCombine`
above form a **non-degenerate** fixture for
`ObliviousSamplingConcreteHiding`. The precise ε bound — the
worst-case adversary advantage — is `1/4`:

* `LHS PMF` (output of `concreteHidingCombine` on uniform-pair
  randomizers): mass `1/4` on `true`, mass `3/4` on `false`.
* `RHS PMF` (`orbitDist false` under `Equiv.Perm Bool`): mass
  `1/2` on each (transitive action with trivial stabilizer ⇒
  uniform on the orbit).
* Total-variation distance: `|1/4 - 1/2| = 1/4`.
* Standard advantage ≤ TV bound on Bool PMFs: every distinguisher
  achieves at most `1/4` advantage; the distinguisher `D = id`
  achieves exactly `1/4`, so the bound is **tight**.

**Why this is not formalised in Lean.** A clean Lean proof of
`ObliviousSamplingConcreteHiding concreteHidingBundle
concreteHidingCombine (1/4)` requires three pieces of PMF
arithmetic in the pinned Mathlib commit:

1. The pointwise computation `(orbitDist false) true = 1/2`,
   enumerating the two permutations in `Equiv.Perm Bool` (`1` and
   `Equiv.swap false true`).
2. The pointwise computation of the LHS PMF at `true` and `false`,
   enumerating the four pairs in `Fin 2 × Fin 2`.
3. A general TV-distance bound for Bool PMFs:
   `advantage D μ ν ≤ |μ true - ν true|.toReal`,
   factored through `Fintype.sum_bool` and the PMF sum-to-1
   identity.

Each step is doable but the chain involves delicate ENNReal/Real
conversions (≈150 lines of low-level proof) in the pinned Mathlib.
The precise ε = 1/4 witness is therefore tracked as **research-
scope follow-up R-12** (audit plan § O), pending cleaner Mathlib
infrastructure (e.g. a `PMF.bernoulli`-vocabulary TV bound).

**What this module *does* deliver (Workstream I post-audit).** The
`concreteHidingBundle` + `concreteHidingCombine` definitions above
are themselves substantive content: they provide a concrete,
non-degenerate fixture that downstream research can target with a
tight ε bound. They are distinguished from the removed
`_zero_witness` (which required the security space to collapse to
a single element — vacuous in the cryptographic sense). Consumers
needing a non-vacuity claim at the trivial `ε = 1` bound can
discharge it directly via `advantage_le_one`; the predicate's
universal `∀ D, advantage ≤ ε` form makes
`ObliviousSamplingConcreteHiding _ _ 1` immediate.

**Honest scoreboard.** Workstream I post-audit replaces the pre-
audit theatrical `_zero_witness` (vacuous on degenerate bundles)
with an honest non-degenerate fixture plus a research-scope
disclosure of the precise bound. The honest delivery is the
fixture + disclosure, not a Lean proof of a tight ε bound.

**Update — R-12 closure (audit 2026-04-29 § 8.1, Workstream D).**
The research-scope note above is **superseded** by the headline
theorems `concreteHiding_tight` (the precise ε = 1/4 bound) and
`concreteHiding_tight_attained` (tightness at `D = id`) below.
The reasoning runs through `advantage_bool_le_tv`
(`Probability/Advantage.lean`, R-12 Layer A) plus the four
pointwise PMF-evaluation lemmas
`concreteHidingBundle_orbitDist_apply_true/_false` and
`concreteHidingLHS_apply_true/_false`. All five new theorems
depend only on the standard Lean trio.
-/
section ConcreteHidingBundleResearchScopeNote
end ConcreteHidingBundleResearchScopeNote

-- ============================================================================
-- Workstream R-12 Layer B — Concrete pointwise PMF computations + tight 1/4
-- (audit 2026-04-29 § 8.1, research-scope discharge plan § R-12 Layer B)
-- ============================================================================

/-- **R-12 Layer B.1 — `(orbitDist false) true = 1/2`.**

    The orbit distribution of `false` under `Equiv.Perm Bool` puts
    mass `1/2` on `true`. Reasoning:
    * `(orbitDist false) true` = `(orbitDist false).toOuterMeasure
      {true}` = `(uniformPMF G).toOuterMeasure ((· • false) ⁻¹'
      {true})` (PMF.toOuterMeasure_map_apply on the push-forward).
    * The preimage `{g : Equiv.Perm Bool | g • false = true}` is a
      Finset of cardinality `1` (the unique element is `Equiv.swap
      false true`, since the identity sends `false` to `false`).
    * `Fintype.card (Equiv.Perm Bool) = 2! = 2`.
    * Result: `1/2`.

    The cardinality computations both discharge by `decide`. -/
theorem concreteHidingBundle_orbitDist_apply_true :
    (orbitDist (G := Equiv.Perm Bool) concreteHidingBundle.basePoint) true
      = (1 / 2 : ENNReal) := by
  show (orbitDist (G := Equiv.Perm Bool) false) true = (1 / 2 : ENNReal)
  -- Step 1 — singleton outer-measure rewrite.
  rw [← PMF.toOuterMeasure_apply_singleton]
  -- Step 2 — push outer measure through the `PMF.map` (preimage form).
  unfold orbitDist
  rw [PMF.toOuterMeasure_map_apply]
  -- Step 3 — recognise the preimage as a `setOf`.
  have h_preimage :
      ((fun g : Equiv.Perm Bool => g • false) ⁻¹' ({true} : Set Bool)) =
        {g : Equiv.Perm Bool | g • false = true} := by
    ext g; simp
  rw [h_preimage]
  -- Step 4 — recognise as `probTrue` of the uniform PMF.
  show (uniformPMF (Equiv.Perm Bool)).toOuterMeasure
        {g : Equiv.Perm Bool | g • false = true} = (1 / 2 : ENNReal)
  have h_probTrue :
      (uniformPMF (Equiv.Perm Bool)).toOuterMeasure
        {g : Equiv.Perm Bool | g • false = true} =
      probTrue (uniformPMF (Equiv.Perm Bool))
        (fun g : Equiv.Perm Bool => g • false) := rfl
  rw [h_probTrue, probTrue_uniformPMF_card]
  -- Step 5 — discharge the cardinality identities by `decide`.
  have h_filter :
      (Finset.univ.filter (fun g : Equiv.Perm Bool => g • false = true)).card = 1 := by
    decide
  have h_card : Fintype.card (Equiv.Perm Bool) = 2 := by decide
  rw [h_filter, h_card]
  -- Step 6 — `(1 : ℕ → ENNReal) / (2 : ℕ → ENNReal) = 1/2`.
  norm_num

/-- **R-12 Layer B.2 — `(orbitDist false) false = 1/2`.** Parallel
    to `concreteHidingBundle_orbitDist_apply_true`. We derive the
    mass via the PMF sum-to-1 identity:
    `μ false = 1 - μ true = 1 - 1/2 = 1/2`. This bypasses the
    `decide` complication at `!`-Bool predicates that arises when
    using `probTrue_uniformPMF_card` directly. -/
theorem concreteHidingBundle_orbitDist_apply_false :
    (orbitDist (G := Equiv.Perm Bool) concreteHidingBundle.basePoint) false
      = (1 / 2 : ENNReal) := by
  -- PMF sum-to-1 (in ENNReal): μ true + μ false = 1.
  have h_sum :
      (orbitDist (G := Equiv.Perm Bool) concreteHidingBundle.basePoint) true
      + (orbitDist (G := Equiv.Perm Bool) concreteHidingBundle.basePoint) false = 1 := by
    have h := (orbitDist (G := Equiv.Perm Bool) concreteHidingBundle.basePoint).tsum_coe
    rw [tsum_fintype, Fintype.sum_bool] at h
    exact h
  -- μ true = 1/2 by Layer B.1.
  rw [concreteHidingBundle_orbitDist_apply_true] at h_sum
  -- Solve μ false = 1 - 1/2.
  have h_finite_t : (1 / 2 : ENNReal) ≠ ⊤ := by norm_num
  have hX :
      (orbitDist (G := Equiv.Perm Bool) concreteHidingBundle.basePoint) false =
        (1 : ENNReal) - 1 / 2 :=
    (ENNReal.sub_eq_of_eq_add_rev h_finite_t h_sum.symm).symm
  rw [hX]
  -- 1 - 1/2 = 1/2: prove via 1 = 1/2 + 1/2 + ENNReal.sub_eq_of_eq_add.
  have h_one : (1 : ENNReal) = 1 / 2 + 1 / 2 := by
    rw [ENNReal.div_add_div_same, show (1 + 1 : ENNReal) = 2 from by norm_num,
        ENNReal.div_self (by norm_num : (2 : ENNReal) ≠ 0)
          (by norm_num : (2 : ENNReal) ≠ ⊤)]
  exact ENNReal.sub_eq_of_eq_add h_finite_t h_one

/-- **R-12 Layer B.3 — `(LHS PMF) true = 1/4`.**

    The combine-bundle LHS PMF (the push-forward of uniform pairs
    in `Fin 2 × Fin 2` through Boolean-AND on the corresponding
    randomizers) puts mass `1/4` on `true`. Reasoning:
    * Out of the four pairs `(i, j) ∈ Fin 2 × Fin 2`, only `(1, 1)`
      maps to `true` (since `randomizers = ![false, true]` and the
      AND is `true ↔ both inputs `true``).
    * `Fintype.card (Fin 2 × Fin 2) = 4`.
    * Result: `1/4`. -/
theorem concreteHidingLHS_apply_true :
    (PMF.map (fun (p : Fin 2 × Fin 2) =>
       concreteHidingCombine (concreteHidingBundle.randomizers p.1)
         (concreteHidingBundle.randomizers p.2))
       (uniformPMF (Fin 2 × Fin 2))) true = (1 / 4 : ENNReal) := by
  rw [← PMF.toOuterMeasure_apply_singleton]
  rw [PMF.toOuterMeasure_map_apply]
  -- Recognise preimage as `setOf`.
  have h_preimage :
      ((fun (p : Fin 2 × Fin 2) =>
         concreteHidingCombine (concreteHidingBundle.randomizers p.1)
           (concreteHidingBundle.randomizers p.2)) ⁻¹' ({true} : Set Bool)) =
      {p : Fin 2 × Fin 2 |
         concreteHidingCombine (concreteHidingBundle.randomizers p.1)
           (concreteHidingBundle.randomizers p.2) = true} := by
    ext p; simp
  rw [h_preimage]
  show (uniformPMF (Fin 2 × Fin 2)).toOuterMeasure
        {p : Fin 2 × Fin 2 |
           concreteHidingCombine (concreteHidingBundle.randomizers p.1)
             (concreteHidingBundle.randomizers p.2) = true}
       = (1 / 4 : ENNReal)
  have h_probTrue :
      (uniformPMF (Fin 2 × Fin 2)).toOuterMeasure
        {p : Fin 2 × Fin 2 |
          concreteHidingCombine (concreteHidingBundle.randomizers p.1)
            (concreteHidingBundle.randomizers p.2) = true} =
      probTrue (uniformPMF (Fin 2 × Fin 2))
        (fun p => concreteHidingCombine (concreteHidingBundle.randomizers p.1)
          (concreteHidingBundle.randomizers p.2)) := rfl
  rw [h_probTrue, probTrue_uniformPMF_card]
  have h_filter :
      (Finset.univ.filter (fun p : Fin 2 × Fin 2 =>
         (concreteHidingCombine (concreteHidingBundle.randomizers p.1)
                                (concreteHidingBundle.randomizers p.2)) = true)).card = 1 := by
    decide
  have h_card : Fintype.card (Fin 2 × Fin 2) = 4 := by decide
  rw [h_filter, h_card]
  norm_num

/-- **R-12 Layer B.4 — `(LHS PMF) false = 3/4`.** Parallel to B.3.
    Derived from B.3 + PMF sum-to-1: `μ false = 1 - 1/4 = 3/4`. -/
theorem concreteHidingLHS_apply_false :
    (PMF.map (fun (p : Fin 2 × Fin 2) =>
       concreteHidingCombine (concreteHidingBundle.randomizers p.1)
         (concreteHidingBundle.randomizers p.2))
       (uniformPMF (Fin 2 × Fin 2))) false = (3 / 4 : ENNReal) := by
  set μ : PMF Bool := PMF.map (fun (p : Fin 2 × Fin 2) =>
       concreteHidingCombine (concreteHidingBundle.randomizers p.1)
         (concreteHidingBundle.randomizers p.2))
       (uniformPMF (Fin 2 × Fin 2)) with hμ_def
  -- PMF sum-to-1 in ENNReal.
  have h_sum : μ true + μ false = (1 : ENNReal) := by
    have h := μ.tsum_coe
    rw [tsum_fintype, Fintype.sum_bool] at h
    exact h
  -- μ true = 1/4 by B.3.
  have h_t : μ true = (1 / 4 : ENNReal) := concreteHidingLHS_apply_true
  rw [h_t] at h_sum
  -- Solve μ false = 1 - 1/4.
  have h_finite_t : (1 / 4 : ENNReal) ≠ ⊤ := by norm_num
  have hX : μ false = (1 : ENNReal) - 1 / 4 :=
    (ENNReal.sub_eq_of_eq_add_rev h_finite_t h_sum.symm).symm
  rw [hX]
  -- 1 - 1/4 = 3/4: prove via 1 = 3/4 + 1/4 + ENNReal.sub_eq_of_eq_add.
  have h_one : (1 : ENNReal) = 3 / 4 + 1 / 4 := by
    rw [ENNReal.div_add_div_same, show (3 + 1 : ENNReal) = 4 from by norm_num,
        ENNReal.div_self (by norm_num : (4 : ENNReal) ≠ 0)
          (by norm_num : (4 : ENNReal) ≠ ⊤)]
  exact ENNReal.sub_eq_of_eq_add h_finite_t h_one

/-- **R-12 headline — Tight ε = 1/4 bound for `concreteHidingBundle`.**

    Closes the post-Workstream-I research-scope disclosure
    (`Orbcrypt.PublicKey.ObliviousSampling`, lines 380–436):
    machine-checks that the on-paper `1/4` bound holds in Lean.

    **Proof.** Apply `advantage_bool_le_tv` (Workstream R-12 Layer
    A) to bound the advantage above by `|(LHS true).toReal − (RHS
    true).toReal|`; substitute the explicit pointwise values
    `1/4` and `1/2` (Layer B.1, B.3); arithmetic.

    See `concreteHiding_tight_attained` for the tightness witness:
    the bound is *achieved* by `D = id`. -/
theorem concreteHiding_tight :
    ObliviousSamplingConcreteHiding (G := Equiv.Perm Bool) concreteHidingBundle
      concreteHidingCombine ((1 : ℝ) / 4) := by
  intro D
  refine (advantage_bool_le_tv D _ _).trans ?_
  rw [concreteHidingLHS_apply_true, concreteHidingBundle_orbitDist_apply_true]
  -- Goal: |(1/4 : ENNReal).toReal - (1/2 : ENNReal).toReal| ≤ 1/4
  rw [show ((1 / 4 : ENNReal).toReal : ℝ) = 1 / 4 by norm_num,
      show ((1 / 2 : ENNReal).toReal : ℝ) = 1 / 2 by norm_num]
  -- Goal: |1/4 - 1/2| ≤ 1/4
  rw [show ((1 : ℝ) / 4 - 1 / 2) = -(1 / 4) by ring, abs_neg]
  rw [show |(1 : ℝ) / 4| = 1 / 4 by norm_num]

/-- **R-12 tightness witness — `1/4` is exactly attained at `D = id`.**

    Companion to `concreteHiding_tight`: the bound is *not* a loose
    overestimate. The identity Boolean function `D = id` achieves
    advantage exactly `1/4`. Combined with `concreteHiding_tight`,
    this confirms `1/4` is the smallest ε for which
    `ObliviousSamplingConcreteHiding concreteHidingBundle
    concreteHidingCombine ε` holds.

    **Proof.** Apply `advantage_bool_id_eq_tv` to convert advantage
    to total-variation distance; substitute the explicit pointwise
    values `1/4` and `1/2`; arithmetic. -/
theorem concreteHiding_tight_attained :
    advantage (id : Bool → Bool)
      (PMF.map (fun (p : Fin 2 × Fin 2) =>
         concreteHidingCombine (concreteHidingBundle.randomizers p.1)
           (concreteHidingBundle.randomizers p.2))
         (uniformPMF (Fin 2 × Fin 2)))
      (orbitDist (G := Equiv.Perm Bool) concreteHidingBundle.basePoint) = (1 : ℝ) / 4 := by
  rw [advantage_bool_id_eq_tv]
  rw [concreteHidingLHS_apply_true, concreteHidingBundle_orbitDist_apply_true]
  rw [show ((1 / 4 : ENNReal).toReal : ℝ) = 1 / 4 by norm_num,
      show ((1 / 2 : ENNReal).toReal : ℝ) = 1 / 2 by norm_num]
  rw [show ((1 : ℝ) / 4 - 1 / 2) = -(1 / 4) by ring, abs_neg]
  norm_num

-- ============================================================================
-- Work Unit 13.3: Randomizer Refresh Protocol
-- ============================================================================

/--
**Randomizer refresh.**

Given a deterministic group-element sampler `G_elem_sampler : ℕ → G` and a
base point `basePoint : X`, produce a fresh bundle of `t` randomizers for
epoch `epoch : ℕ` by sampling `t` group elements from the sampler indices
`[epoch * t, epoch * t + t)` and applying them to `basePoint`.

Because each randomizer is `g • basePoint` for some `g ∈ G`, membership in
`orbit G basePoint` is immediate (`smul_mem_orbit`). This gives the refresh
bundle an `OrbitalRandomizers` certificate for free
(`refreshRandomizers_orbitalRandomizers` below).

**Why this signature.** The sampler is parameterised by a single `ℕ` index so
it can be backed by a keystream or PRF (see `Orbcrypt.KeyMgmt.SeedKey`). Epochs
are distinct contiguous slices of the index space, which makes independence
easy to state (see `RefreshDependsOnlyOnEpochRange`).
-/
def refreshRandomizers [Group G] [MulAction G X]
    (G_elem_sampler : ℕ → G) (basePoint : X) (t : ℕ) (epoch : ℕ) :
    Fin t → X :=
  fun (i : Fin t) => G_elem_sampler (epoch * t + i.val) • basePoint

/-- Unfold `refreshRandomizers` at a specific index. -/
@[simp]
theorem refreshRandomizers_apply [Group G] [MulAction G X]
    (G_elem_sampler : ℕ → G) (basePoint : X) (t : ℕ) (epoch : ℕ) (i : Fin t) :
    refreshRandomizers G_elem_sampler basePoint t epoch i =
      G_elem_sampler (epoch * t + i.val) • basePoint := rfl

/--
Each refreshed randomizer lies in the orbit of the base point.

**Proof.** Every entry is `g • basePoint`; apply `smul_mem_orbit`.
-/
theorem refreshRandomizers_in_orbit [Group G] [MulAction G X]
    (G_elem_sampler : ℕ → G) (basePoint : X) (t : ℕ) (epoch : ℕ) (i : Fin t) :
    refreshRandomizers G_elem_sampler basePoint t epoch i ∈
      MulAction.orbit G basePoint := by
  simp only [refreshRandomizers_apply]
  exact smul_mem_orbit _ basePoint

/--
Package a refreshed bundle as an `OrbitalRandomizers`.

This is the primary constructor used by callers: they supply a sampler, a base
point, and an epoch, and receive a ready-to-use bundle of randomizers with the
orbit-membership certificate already discharged.
-/
def refreshRandomizers_orbitalRandomizers [Group G] [MulAction G X]
    (G_elem_sampler : ℕ → G) (basePoint : X) (t : ℕ) (epoch : ℕ) :
    OrbitalRandomizers G X t where
  basePoint := basePoint
  randomizers := refreshRandomizers G_elem_sampler basePoint t epoch
  in_orbit := refreshRandomizers_in_orbit G_elem_sampler basePoint t epoch

/-- The bundle's `basePoint` is the input `basePoint` (structural check). -/
@[simp]
theorem refreshRandomizers_orbitalRandomizers_basePoint
    [Group G] [MulAction G X] (G_elem_sampler : ℕ → G) (basePoint : X)
    (t : ℕ) (epoch : ℕ) :
    (refreshRandomizers_orbitalRandomizers G_elem_sampler basePoint t epoch
      : OrbitalRandomizers G X t).basePoint = basePoint := rfl

/-- The bundle's `randomizers` function is the input sampler composed with
`epoch * t + ·` applied to `basePoint`. -/
@[simp]
theorem refreshRandomizers_orbitalRandomizers_randomizers
    [Group G] [MulAction G X] (G_elem_sampler : ℕ → G) (basePoint : X)
    (t : ℕ) (epoch : ℕ) :
    (refreshRandomizers_orbitalRandomizers G_elem_sampler basePoint t epoch
      : OrbitalRandomizers G X t).randomizers =
    refreshRandomizers G_elem_sampler basePoint t epoch := rfl

/--
**Refresh depends only on the per-epoch index range (as a Prop).**

*Naming corrective (audit F-AUDIT-2026-04-21-M4 / Workstream L3,
2026-04-22).* The previous name `RefreshIndependent` (and
`refresh_independent`) suggested a cryptographic independence claim.
The theorem below, however, is a `funext`-structural identity: if two
samplers agree on the per-epoch index ranges, their refresh bundles
for those epochs agree. No cryptographic independence is asserted —
the result is a structural determinism witness, hence the current
name `RefreshDependsOnlyOnEpochRange`.

Two distinct epochs draw from disjoint index ranges of the sampler. If
the sampler is modelled as a pseudo-random function (PRF), the outputs
on disjoint domains are computationally independent. We formalise the
**structural** side of this: the refreshed bundles for distinct
epochs are determined entirely by their disjoint sampler index ranges,
so any "information leak" across epochs must come from the sampler
itself — not from the refresh protocol.

The Prop states this as: *for any two samplers agreeing on both
epochs' index ranges, the refresh bundles for each epoch under either
sampler are pointwise equal.*

**Scope.** This captures the **structural** requirement. The actual
*pseudorandom* property — that distinct-epoch outputs are
computationally independent — is a computational assumption on
`G_elem_sampler` (see `Orbcrypt.KeyMgmt.SeedKey` for the PRF design)
and is out of scope for this deterministic module.
-/
def RefreshDependsOnlyOnEpochRange [Group G] [MulAction G X]
    (basePoint : X) (t : ℕ) (epoch₁ epoch₂ : ℕ) : Prop :=
  ∀ (sampler₁ sampler₂ : ℕ → G),
    (∀ i : Fin t, sampler₁ (epoch₁ * t + i.val) =
                   sampler₂ (epoch₁ * t + i.val)) →
    (∀ i : Fin t, sampler₁ (epoch₂ * t + i.val) =
                   sampler₂ (epoch₂ * t + i.val)) →
    (refreshRandomizers sampler₁ basePoint t epoch₁ =
     refreshRandomizers sampler₂ basePoint t epoch₁) ∧
    (refreshRandomizers sampler₁ basePoint t epoch₂ =
     refreshRandomizers sampler₂ basePoint t epoch₂)

/--
`RefreshDependsOnlyOnEpochRange` is unconditionally true: the refresh
protocol uses only the sampler outputs on the per-epoch index ranges.

This is the **structural determinism** statement — the refresh
protocol introduces no side channels beyond the sampler itself.
Computational independence (PRF security) is an additional, separate
hypothesis about the sampler and is **not** proved here.

*Naming corrective (audit F-AUDIT-2026-04-21-M4 / Workstream L3):* the
previous name `refresh_independent` suggested a cryptographic
independence result. The content is structural, and the name now
reflects that.
-/
theorem refresh_depends_only_on_epoch_range [Group G] [MulAction G X]
    (basePoint : X) (t : ℕ) (epoch₁ epoch₂ : ℕ) :
    RefreshDependsOnlyOnEpochRange (G := G) basePoint t epoch₁ epoch₂ := by
  intro sampler₁ sampler₂ hAgree₁ hAgree₂
  -- `refreshRandomizers` is pointwise `sampler (epoch * t + i.val) • basePoint`;
  -- agreement on this index range makes the two functions equal.
  refine ⟨?_, ?_⟩
  · funext i
    rw [refreshRandomizers_apply, refreshRandomizers_apply, hAgree₁ i]
  · funext i
    rw [refreshRandomizers_apply, refreshRandomizers_apply, hAgree₂ i]

end Orbcrypt
