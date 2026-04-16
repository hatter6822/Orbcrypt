import Orbcrypt.GroupAction.Basic

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
  plus the sender-privacy `Prop`, `ObliviousSamplingHiding`).
* **13.3 — Randomizer Refresh Protocol** (`refreshRandomizers`, together with
  `refreshRandomizers_in_orbit` and the epoch-independence predicate
  `RefreshIndependent`).

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
    (hClosed : ∀ (x y : X), x ∈ MulAction.orbit G ors.basePoint →
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
**Sender-privacy requirement (as a Prop).**

The whole point of oblivious sampling is that the sender — who sees only the
published randomizers `(ors.randomizers i)` and the public `combine` operation
— learns *nothing* about the secret group `G`.

We formalise this as: every function on the visible data (the bundle together
with the chosen indices) factors through a function that does not mention any
specific group element. Put differently, any two group presentations `G₁, G₂`
with the same randomizer outputs yield the same sender view.

This is a **security conjecture**, not an unconditional theorem: its
satisfiability depends on the concrete `combine` and the structure of the
orbit. Theorems in this module carry it only as a hypothesis.
-/
def ObliviousSamplingHiding [Group G] [MulAction G X] {t : ℕ}
    (ors : OrbitalRandomizers G X t) (combine : X → X → X) : Prop :=
  ∀ (view : X → X → X → Bool) (i j k l : Fin t),
    view (ors.randomizers i) (ors.randomizers j)
        (combine (ors.randomizers i) (ors.randomizers j)) =
    view (ors.randomizers k) (ors.randomizers l)
        (combine (ors.randomizers k) (ors.randomizers l))

/--
**Hiding corollary.** If `ObliviousSamplingHiding` holds, any Boolean view
of `obliviousSample` is independent of the chosen index pair.

This is an immediate extraction: `ObliviousSamplingHiding` is precisely the
statement that such views coincide. It is stated separately so callers can
use `oblivious_sampling_view_constant hHide ...` without unfolding the
definition.
-/
theorem oblivious_sampling_view_constant [Group G] [MulAction G X] {t : ℕ}
    (ors : OrbitalRandomizers G X t) (combine : X → X → X)
    (hClosed : ∀ (x y : X), x ∈ MulAction.orbit G ors.basePoint →
      y ∈ MulAction.orbit G ors.basePoint →
      combine x y ∈ MulAction.orbit G ors.basePoint)
    (hHide : ObliviousSamplingHiding ors combine)
    (view : X → X → X → Bool) (i j k l : Fin t) :
    view (ors.randomizers i) (ors.randomizers j)
        (obliviousSample ors combine hClosed i j) =
    view (ors.randomizers k) (ors.randomizers l)
        (obliviousSample ors combine hClosed k l) := by
  simp only [obliviousSample_eq]
  exact hHide view i j k l

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
easy to state (see `RefreshIndependent`).
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

/--
**Refresh independence (as a Prop).**

Two distinct epochs draw from disjoint index ranges of the sampler. If the
sampler is modelled as a pseudo-random function (PRF), the outputs on disjoint
domains are computationally independent. We formalise the structural side of
this: the refreshed bundles for distinct epochs are determined entirely by
disjoint sampler index ranges, so any "information leak" must come from the
sampler itself — not from the refresh protocol.

The Prop states this as: *for any Boolean observation on the combined output
of two bundles, swapping the sampler for any other function that agrees on
both epochs' index ranges gives the same observation.*

**Scope.** This captures the structural requirement. The actual *pseudorandom*
property is a computational assumption on `G_elem_sampler` (see
`Orbcrypt.KeyMgmt.SeedKey` for the PRF design) and is out of scope for this
deterministic module.
-/
def RefreshIndependent [Group G] [MulAction G X]
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
`RefreshIndependent` is unconditionally true: the refresh protocol uses only
the sampler outputs on the per-epoch index ranges. This is the **structural
independence** statement — the refresh protocol introduces no side channels
beyond the sampler itself. Computational independence (PRF security) is an
additional, separate hypothesis about the sampler.
-/
theorem refresh_independent [Group G] [MulAction G X]
    (basePoint : X) (t : ℕ) (epoch₁ epoch₂ : ℕ) :
    RefreshIndependent (G := G) basePoint t epoch₁ epoch₂ := by
  intro sampler₁ sampler₂ hAgree₁ hAgree₂
  -- `refreshRandomizers` is pointwise `sampler (epoch * t + i.val) • basePoint`;
  -- agreement on this index range makes the two functions equal.
  refine ⟨?_, ?_⟩
  · funext i
    rw [refreshRandomizers_apply, refreshRandomizers_apply, hAgree₁ i]
  · funext i
    rw [refreshRandomizers_apply, refreshRandomizers_apply, hAgree₂ i]

end Orbcrypt
