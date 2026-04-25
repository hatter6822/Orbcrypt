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
* `Orbcrypt.oblivious_sampling_view_advantage_bound` — extraction
  shape mirroring `concrete_oia_implies_1cpa`: extracts the ε bound
  from the predicate at any specific Boolean view.
* `Orbcrypt.ObliviousSamplingConcreteHiding_zero_witness` —
  non-vacuity witness at ε = 0 on a singleton-orbit bundle, replacing
  the pre-I deterministic predicate's pathological-strength caveat
  with a machine-checked inhabitability proof.

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
`[DecidableEq X]` aligns with the `orbitDist` API (note: `orbitDist`
itself does not strictly require `DecidableEq X`, but the extraction
lemma `oblivious_sampling_view_advantage_bound` is sometimes called
in contexts where `DecidableEq X` is also in scope; we keep it for
uniformity with the rest of the probabilistic chain).

**Non-vacuity.** See `ObliviousSamplingConcreteHiding_zero_witness`
below for the perfect-security witness on singleton-orbit bundles
(parallel to `concreteOIA_zero_of_subsingleton_message` and
`concreteKEMOIA_uniform_zero_of_singleton_orbit` in Workstream I1
and I2 respectively).
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

/--
**Advantage extraction from `ObliviousSamplingConcreteHiding`**
(Workstream I6, audit 2026-04-23 finding K-02). For any specific
Boolean view, the advantage is bounded by the predicate's ε.

Mirrors the `concrete_oia_implies_1cpa` extraction pattern on the
scheme-OIA side: a one-line specialisation of the universal-`D`
predicate to a particular distinguisher.
-/
theorem oblivious_sampling_view_advantage_bound
    [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] {t : ℕ} [NeZero t]
    (ors : OrbitalRandomizers G X t)
    (combine : X → X → X) (ε : ℝ)
    (hHide : ObliviousSamplingConcreteHiding ors combine ε)
    (D : X → Bool) :
    advantage D
      (PMF.map (fun (p : Fin t × Fin t) =>
        combine (ors.randomizers p.1) (ors.randomizers p.2))
        (uniformPMF (Fin t × Fin t)))
      (orbitDist (G := G) ors.basePoint) ≤ ε :=
  hHide D

/--
**Non-vacuity witness for `ObliviousSamplingConcreteHiding` at
ε = 0** (Workstream I6, audit 2026-04-23 finding K-02).

When the group action fixes the basepoint (singleton orbit) and
`combine` returns the basepoint regardless of inputs, both PMFs
reduce to `PMF.pure ors.basePoint`, and the advantage between two
equal point masses is `0` by `advantage_self`.

**Proof.** Two structural reductions composed:
* LHS: `combine := fun _ _ => ors.basePoint` makes the inner
  function in the `PMF.map` constant, so by `PMF.map_const` the
  push-forward is `PMF.pure ors.basePoint`.
* RHS: under `h_fix`, `(fun g => g • ors.basePoint) = (fun _ =>
  ors.basePoint)`, so the `orbitDist` push-forward also reduces
  via `PMF.map_const` to `PMF.pure ors.basePoint`.

After both reductions the goal is `advantage D (PMF.pure x)
(PMF.pure x) ≤ 0`, discharged by `advantage_self`.

**Hypothesis is non-trivially populated.** Any KEM/scheme whose
basepoint is a fixed point of the group action discharges
`h_fix` — including (but not limited to) the trivial group acting
on any space, or any group acting trivially on a singleton.

**Cryptographic interpretation.** The Phase-13 oblivious-sampling
parallel of `concreteOIA_zero_of_subsingleton_message` (scheme
layer) and `concreteKEMOIA_uniform_zero_of_singleton_orbit` (KEM
layer). Together the three witnesses inhabit the meaningful
(perfect-security) extremum across the entire post-Workstream-I
probabilistic chain.
-/
theorem ObliviousSamplingConcreteHiding_zero_witness
    [Group G] [Fintype G] [Nonempty G]
    [MulAction G X] {t : ℕ} [NeZero t]
    (ors : OrbitalRandomizers G X t)
    (h_fix : ∀ g : G, g • ors.basePoint = ors.basePoint) :
    ObliviousSamplingConcreteHiding ors
      (fun _ _ => ors.basePoint) 0 := by
  intro D
  -- Goal: advantage D LHS-PMF RHS-PMF ≤ 0.
  -- Reduce LHS: `combine = fun _ _ => ors.basePoint` is constant in
  -- both arguments, so `PMF.map (fun p => combine (...) (...)) _ =
  -- PMF.map (Function.const _ ors.basePoint) _ = PMF.pure ors.basePoint`.
  have h_lhs :
      PMF.map (fun (_ : Fin t × Fin t) => ors.basePoint)
        (uniformPMF (Fin t × Fin t)) =
      PMF.pure ors.basePoint :=
    PMF.map_const _ _
  -- Reduce RHS: under `h_fix`, `(fun g => g • ors.basePoint) =
  -- (fun _ => ors.basePoint)`, so `orbitDist` is also a point mass.
  have hConst_g : (fun g : G => g • ors.basePoint) =
      Function.const G ors.basePoint := by
    funext g
    exact h_fix g
  have h_rhs :
      orbitDist (G := G) ors.basePoint = PMF.pure ors.basePoint := by
    unfold orbitDist
    rw [hConst_g]
    exact PMF.map_const _ _
  rw [h_lhs, h_rhs]
  exact le_of_eq (advantage_self _ _)

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
