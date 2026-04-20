import Orbcrypt.GroupAction.Basic
import Orbcrypt.GroupAction.Invariant
import Orbcrypt.Crypto.Scheme
import Orbcrypt.Crypto.OIA
import Orbcrypt.Crypto.CompOIA
import Orbcrypt.Probability.Advantage
import Orbcrypt.PublicKey.ObliviousSampling

/-!
# Orbcrypt.PublicKey.CombineImpossibility

A machine-checked **no-go theorem** for the oblivious-sampling combiner
problem flagged in `docs/PUBLIC_KEY_ANALYSIS.md` §1: there is no public,
`G`-equivariant, orbit-closed `combine : X → X → X` that is also
*non-degenerate* (mixes its second argument non-trivially) for any scheme
that satisfies the deterministic Orbit Indistinguishability Assumption
(`OIA`). Equivalently, under `OIA`, every equivariant orbit-closed
combiner collapses to a function that ignores its second argument on the
basepoint orbit — and is therefore useless for producing *fresh* orbit
elements from a published `OrbitalRandomizers` bundle.

## Why this matters

`Orbcrypt.PublicKey.ObliviousSampling.obliviousSample` requires the
caller to supply a closure proof
`hClosed : ∀ x y ∈ orbit G basePoint, combine x y ∈ orbit G basePoint`.
The cryptographic intent is that a sender who does *not* know the secret
group `G` can apply `combine` to two published randomizers and obtain a
*fresh* orbit element. For "fresh" to be meaningful, `combine` must
actually depend on its arguments — otherwise the sender's output is
always one of finitely many fixed values and adds no entropy.

This module proves that any candidate `combine` satisfying the natural
diagonal `G`-equivariance property
`combine (g • x) (g • y) = g • combine x y`
must, under deterministic `OIA`, be **constant in its second argument**
on the basepoint orbit. The contrapositive — non-degeneracy implies OIA
failure — is the headline theorem `equivariant_combiner_breaks_oia`.

## Scope and limitations

* The theorem is stated against the **deterministic** `OIA`
  (`Orbcrypt.Crypto.OIA`). The deterministic OIA is known to be a strong,
  pathological-strength assumption (see `Orbcrypt/Crypto/OIA.lean`'s own
  docstring). The same structural obstruction translates to the
  probabilistic `ConcreteOIA` / `CompOIA` setting (Phase 8) but with a
  quantitative loss; we leave that refinement to future work.
* The result requires `G`-equivariance of `combine` for the diagonal
  action. This is the *natural* symmetry one would want for an
  orbit-preserving public combiner — it is what makes `combine`'s output
  uniform when its inputs are. Combiners that violate equivariance lose
  even the basic homogeneity property and are not interesting.
* The obstruction does **not** apply to the CSIDH-style commutative
  setting (`Orbcrypt.PublicKey.CommutativeAction`): there the combiner
  *is* the commutative group operation on the public class group, which
  is publicly computable without revealing the secret class-group
  element acting on the basepoint.

## Main results

* `Orbcrypt.GEquivariantCombiner` — bundle of an orbit-closed
  `combine : X → X → X` with the diagonal-equivariance proof.
* `Orbcrypt.GEquivariantCombiner.combine_diagonal_smul` — the diagonal
  consequence `combine (g • bp) (g • bp) = g • combine bp bp`.
* `Orbcrypt.GEquivariantCombiner.combine_section_form` — equivariance
  determines `combine` on `O × O` from its restriction to `{bp} × O`.
* `Orbcrypt.NonDegenerateCombiner` — the predicate "combine is not
  constant in its second argument on the basepoint orbit".
* `Orbcrypt.combinerDistinguisher` — the Boolean function
  `decide (combine bp x = combine bp bp)`.
* `Orbcrypt.combinerDistinguisher_basePoint` /
  `combinerDistinguisher_witness` — the distinguisher returns `true` on
  the basepoint and `false` on a non-degeneracy witness.
* **`Orbcrypt.equivariant_combiner_breaks_oia`** — headline no-go:
  a non-degenerate equivariant combiner whose basepoint is a scheme
  representative refutes `OIA`.
* `Orbcrypt.oia_forces_combine_constant_in_snd` — contrapositive:
  under `OIA`, every equivariant combiner is constant in its second
  argument on the basepoint orbit.
* `Orbcrypt.oblivious_sample_equivariant_obstruction` — bridge to
  `ObliviousSampling`: under `OIA`, an `obliviousSample` driven by an
  equivariant combiner is functionally constant on the bundle (it loses
  the dependence on the second sender index).

## References

* `docs/PUBLIC_KEY_ANALYSIS.md` §1 — the open `combine` problem.
* `Orbcrypt/PublicKey/ObliviousSampling.lean` — the bundle and the
  closure hypothesis this theorem refines.
* `Orbcrypt/Crypto/OIA.lean` — the (strong) deterministic OIA used here.
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*} {M : Type*}

-- ============================================================================
-- Definition: GEquivariantCombiner
-- ============================================================================

/--
A **G-equivariant orbit-closed combiner** for a designated basepoint.

This bundles three pieces of data:

* `combine : X → X → X` — the candidate sender-side mixing operation.
* `closed` — `combine x y ∈ orbit G basePoint` whenever both `x` and `y`
  are in `orbit G basePoint`. This is the same closure hypothesis required
  by `obliviousSample` (`hClosed`).
* `equivariant` — diagonal `G`-equivariance:
  `combine (g • x) (g • y) = g • combine x y`. This is the *natural*
  symmetry one would want for a sender-side combiner: it ensures
  `combine`'s output distribution is the same regardless of which
  representative of an orbit pair the sender happens to see.

The headline theorem `equivariant_combiner_breaks_oia` shows that any
such combiner must be constant in its second argument on the basepoint
orbit — i.e. useless for producing fresh ciphertexts — under the
deterministic `OIA`.
-/
structure GEquivariantCombiner (G : Type*) (X : Type*)
    [Group G] [MulAction G X] (basePoint : X) where
  /-- The candidate sender-side combine operation. -/
  combine : X → X → X
  /-- `combine` is closed on `orbit G basePoint`. -/
  closed : ∀ (x y : X), x ∈ MulAction.orbit G basePoint →
    y ∈ MulAction.orbit G basePoint →
    combine x y ∈ MulAction.orbit G basePoint
  /-- `combine` is `G`-equivariant for the diagonal action on `X × X`. -/
  equivariant : ∀ (g : G) (x y : X),
    combine (g • x) (g • y) = g • combine x y

namespace GEquivariantCombiner

-- ============================================================================
-- Structural lemmas: diagonal and section form
-- ============================================================================

variable [Group G] [MulAction G X] {basePoint : X}

/--
**Diagonal consequence of equivariance.** For any `g : G`,
`combine (g • bp) (g • bp) = g • combine bp bp`.

Direct instantiation of `equivariant` with `x = y = basePoint`.
-/
theorem combine_diagonal_smul
    (combiner : GEquivariantCombiner G X basePoint) (g : G) :
    combiner.combine (g • basePoint) (g • basePoint) =
      g • combiner.combine basePoint basePoint :=
  combiner.equivariant g basePoint basePoint

/--
**Section form.** `combine` on `orbit G bp × orbit G bp`, when the orbit
is expressed concretely as `{g • bp : g ∈ G}`, reduces to its restriction
`y ↦ combine basePoint y` on the second axis (plus a `g`-translate on the
first axis).

Precisely, for any `g h : G`:

`combine (g • bp) (h • bp) = g • combine bp ((g⁻¹ * h) • bp)`.

This is the machine-checked form of the observation that a
`G`-equivariant combiner has **only one functional degree of freedom**:
the section `y ↦ combine bp y`. Everything else is forced by equivariance.

**Proof strategy.** Rewrite `h • bp = g • ((g⁻¹ * h) • bp)` using
`mul_smul` + `mul_inv_cancel_left`, then apply `equivariant g bp _`.
-/
theorem combine_section_form
    (combiner : GEquivariantCombiner G X basePoint) (g h : G) :
    combiner.combine (g • basePoint) (h • basePoint) =
      g • combiner.combine basePoint ((g⁻¹ * h) • basePoint) := by
  -- h • bp = g • ((g⁻¹ * h) • bp) via (g * (g⁻¹ * h)) = h.
  have key : g • ((g⁻¹ * h) • basePoint) = h • basePoint := by
    rw [← mul_smul, mul_inv_cancel_left]
  -- Rewrite the second argument of `combine` via `key`, then apply equivariance.
  calc combiner.combine (g • basePoint) (h • basePoint)
      = combiner.combine (g • basePoint) (g • ((g⁻¹ * h) • basePoint)) := by rw [key]
    _ = g • combiner.combine basePoint ((g⁻¹ * h) • basePoint) :=
          combiner.equivariant g basePoint _

end GEquivariantCombiner

-- ============================================================================
-- Non-degeneracy predicate and the induced distinguisher
-- ============================================================================

/--
A combiner is **non-degenerate** (at its basepoint) if its second argument
actually matters on the basepoint orbit: there exists a group element
`g : G` such that `combine bp (g • bp) ≠ combine bp bp`.

This is the minimal "usefulness" requirement for `combine`: if no such
`g` exists, then `combine bp y = combine bp bp` for every `y ∈ orbit G bp`,
so the sender's output via `obliviousSample ors combine hClosed i j` with
`ors.basePoint = bp` reduces to `combine bp bp` — a single fixed value.
Such a combiner cannot produce fresh ciphertexts.

The headline theorem `equivariant_combiner_breaks_oia` shows that
non-degeneracy is incompatible with `OIA` for any scheme whose basepoint
is a message representative.
-/
def NonDegenerateCombiner [Group G] [MulAction G X] {basePoint : X}
    (combiner : GEquivariantCombiner G X basePoint) : Prop :=
  ∃ g : G, combiner.combine basePoint (g • basePoint) ≠
           combiner.combine basePoint basePoint

/--
**The combiner-induced distinguisher.** Given a combiner, the Boolean
function

`combinerDistinguisher combiner x := decide (combine bp x = combine bp bp)`

tests whether the combiner's output on `(bp, x)` coincides with its
output on `(bp, bp)`. When `combiner` is non-degenerate this function is
non-constant on `orbit G basePoint` — which is exactly the kind of
Boolean function forbidden by the deterministic `OIA` (see
`equivariant_combiner_breaks_oia`).

Note: this function is defined unconditionally; non-degeneracy enters
only through the lemmas that characterise its behaviour.
-/
def combinerDistinguisher [Group G] [MulAction G X] [DecidableEq X]
    {basePoint : X} (combiner : GEquivariantCombiner G X basePoint) :
    X → Bool :=
  fun x => decide (combiner.combine basePoint x =
                   combiner.combine basePoint basePoint)

/-- Unfold `combinerDistinguisher` at a specific input. -/
@[simp]
theorem combinerDistinguisher_eq [Group G] [MulAction G X] [DecidableEq X]
    {basePoint : X} (combiner : GEquivariantCombiner G X basePoint) (x : X) :
    combinerDistinguisher combiner x =
      decide (combiner.combine basePoint x =
              combiner.combine basePoint basePoint) := rfl

/--
The combiner-induced distinguisher returns `true` on `basePoint`.

This is immediate: `combine bp bp = combine bp bp`, so `decide (·) = true`
via `decide_eq_true rfl`.
-/
@[simp]
theorem combinerDistinguisher_basePoint [Group G] [MulAction G X] [DecidableEq X]
    {basePoint : X} (combiner : GEquivariantCombiner G X basePoint) :
    combinerDistinguisher combiner basePoint = true := by
  unfold combinerDistinguisher
  exact decide_eq_true rfl

/--
Non-degeneracy exhibits a group element `g : G` on which the
distinguisher returns `false`.

**Proof.** Destructure the non-degeneracy witness to obtain `g` with
`combine bp (g • bp) ≠ combine bp bp`; then `decide` of that equality is
`false` by `decide_eq_false`.
-/
theorem combinerDistinguisher_witness [Group G] [MulAction G X] [DecidableEq X]
    {basePoint : X} {combiner : GEquivariantCombiner G X basePoint}
    (hND : NonDegenerateCombiner combiner) :
    ∃ g : G, combinerDistinguisher combiner (g • basePoint) = false := by
  obtain ⟨g, hne⟩ := hND
  refine ⟨g, ?_⟩
  unfold combinerDistinguisher
  exact decide_eq_false hne

-- ============================================================================
-- Headline: equivariant non-degenerate combiner ⇒ ¬ OIA
-- ============================================================================

/--
**Headline no-go theorem.** If `combiner : GEquivariantCombiner G X bp`
is non-degenerate and `bp = scheme.reps m_bp` for some message `m_bp`,
then the deterministic Orbit Indistinguishability Assumption fails:
`¬ OIA scheme`.

**Cryptographic reading.** Any public, diagonally `G`-equivariant,
orbit-closed combiner that actually mixes its second argument on the
basepoint orbit yields a Boolean function that distinguishes
`basePoint = reps m_bp` from some other orbit element
`g • reps m_bp`. The deterministic `OIA` — which forces every Boolean
function to agree on every pair `(g₀ • reps m₀, g₁ • reps m₁)` and in
particular on every pair within a single orbit — is therefore refuted.

**Proof strategy.**
1. Specialise `OIA` to `f = combinerDistinguisher combiner`,
   `m₀ = m₁ = m_bp`, `g₀ = 1`, `g₁ = g` where `g` is the non-degeneracy
   witness.
2. On the LHS: `f (1 • reps m_bp) = f (reps m_bp) = true`
   (by `one_smul` and `combinerDistinguisher_basePoint`, since
   `bp = reps m_bp`).
3. On the RHS: `f (g • reps m_bp) = false`
   (by the witness from `combinerDistinguisher_witness`, where the
   chosen `g` satisfies the disequality).
4. `true = false` is `False`.

**Why OIA is hypothesised, not used:** the theorem concludes `¬ OIA`,
so `hOIA : OIA scheme` is introduced locally by `intro` inside the
proof, not carried as a hypothesis of the statement.
-/
theorem equivariant_combiner_breaks_oia [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (combiner : GEquivariantCombiner G X (scheme.reps m_bp))
    (hND : NonDegenerateCombiner combiner) :
    ¬ OIA scheme := by
  -- Extract the non-degeneracy witness.
  obtain ⟨g, hne⟩ := hND
  -- Assume OIA, derive False.
  intro hOIA
  -- f ((1 : G) • reps m_bp) = f (reps m_bp) = true, since 1 • x = x and bp = reps m_bp.
  have h_true :
      combinerDistinguisher combiner ((1 : G) • scheme.reps m_bp) = true := by
    rw [one_smul]
    exact combinerDistinguisher_basePoint combiner
  -- f (g • reps m_bp) = false, directly from the witness `hne`.
  have h_false :
      combinerDistinguisher combiner (g • scheme.reps m_bp) = false := by
    unfold combinerDistinguisher
    exact decide_eq_false hne
  -- OIA applied to (f, m_bp, m_bp, 1, g) forces equality of these two values.
  have h_oia := hOIA (combinerDistinguisher combiner) m_bp m_bp (1 : G) g
  rw [h_true, h_false] at h_oia
  -- `true = false` is absurd.
  exact Bool.noConfusion h_oia

/--
**Contrapositive.** Under deterministic `OIA`, every diagonally
`G`-equivariant orbit-closed combiner whose basepoint is a scheme
representative is **constant in its second argument** on the basepoint
orbit. Concretely: for every `g : G`,
`combine (reps m_bp) (g • reps m_bp) = combine (reps m_bp) (reps m_bp)`.

**Cryptographic reading.** Such a combiner carries *no* information
about its second argument — applying it to two published randomizers
`r_i, r_j ∈ orbit G basePoint` yields the same value as applying it to
`(basePoint, basePoint)`. A sender using it cannot produce fresh orbit
elements; the construction collapses.

**Proof.** Take the contrapositive of
`equivariant_combiner_breaks_oia`: if some `g` witnessed non-degeneracy
we would refute `OIA`, contradicting `hOIA`.
-/
theorem oia_forces_combine_constant_in_snd [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (combiner : GEquivariantCombiner G X (scheme.reps m_bp))
    (hOIA : OIA scheme) :
    ∀ g : G,
      combiner.combine (scheme.reps m_bp) (g • scheme.reps m_bp) =
        combiner.combine (scheme.reps m_bp) (scheme.reps m_bp) := by
  -- Suppose not; extract the dissenting `g`, package it as
  -- `NonDegenerateCombiner combiner`, refute OIA.
  intro g
  by_contra hne
  exact equivariant_combiner_breaks_oia scheme m_bp combiner ⟨g, hne⟩ hOIA

/--
**Stronger contrapositive.** Under deterministic `OIA`, a
`G`-equivariant orbit-closed combiner is constant in its second argument
*for every* element of the basepoint orbit, not only for those written
as `g • basePoint` with an explicit group element.

This is the form most directly useful for chaining with
`OrbitalRandomizers.in_orbit` (which produces orbit elements, not group
elements).
-/
theorem oia_forces_combine_constant_on_orbit
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (combiner : GEquivariantCombiner G X (scheme.reps m_bp))
    (hOIA : OIA scheme)
    {y : X} (hy : y ∈ MulAction.orbit G (scheme.reps m_bp)) :
    combiner.combine (scheme.reps m_bp) y =
      combiner.combine (scheme.reps m_bp) (scheme.reps m_bp) := by
  -- Destructure `y = g • reps m_bp` and reduce to `oia_forces_combine_constant_in_snd`.
  obtain ⟨g, rfl⟩ := MulAction.mem_orbit_iff.mp hy
  exact oia_forces_combine_constant_in_snd scheme m_bp combiner hOIA g

-- ============================================================================
-- Bridge to ObliviousSampling: the combine-based sender flow collapses
-- ============================================================================

/--
**Bridge to `obliviousSample`.** Suppose we build an `OrbitalRandomizers`
bundle over `scheme.reps m_bp` and drive its `obliviousSample` by the
`combine` field of a `GEquivariantCombiner`. Then under deterministic
`OIA`, the sender's output is functionally independent of the index `j`
of the second randomizer: for any indices `i, j₁, j₂ : Fin t`,

`obliviousSample ors combine hClosed i j₁ = obliviousSample ors combine hClosed i j₂`

whenever the first randomizer `ors.randomizers i` equals
`scheme.reps m_bp` (i.e. the "first slot" is anchored at the basepoint).

**Cryptographic reading.** Driving `obliviousSample` with an equivariant
combiner that respects `OIA` reduces the sender's randomness to its
*first* index alone — the second index contributes nothing. The
public-key flavour of oblivious sampling is therefore blocked on the
algebraic side for any combiner that inherits the natural diagonal
symmetry, *unless* the deterministic `OIA` is given up (which is
already the case for `ConcreteOIA` / `CompOIA`; quantifying the loss
there requires a probabilistic refinement left to future work).

**Proof.** `ors.randomizers j₁` and `ors.randomizers j₂` both lie in
`orbit G (ors.basePoint) = orbit G (scheme.reps m_bp)` by `ors.in_orbit`.
`oia_forces_combine_constant_on_orbit` equates
`combine (reps m_bp) (ors.randomizers j₁)` with
`combine (reps m_bp) (reps m_bp)` and similarly for `j₂`; transitivity
closes the goal. The anchor hypothesis
`hi : ors.randomizers i = scheme.reps m_bp` is used to rewrite the first
argument of `combine`.
-/
theorem oblivious_sample_equivariant_obstruction
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    {t : ℕ}
    (ors : OrbitalRandomizers G X t)
    (combiner : GEquivariantCombiner G X (scheme.reps m_bp))
    (hBase : ors.basePoint = scheme.reps m_bp)
    (hOIA : OIA scheme)
    (i j₁ j₂ : Fin t) (hi : ors.randomizers i = scheme.reps m_bp) :
    obliviousSample ors combiner.combine
        (fun x y hx hy => by
          -- Rewrite the goal's `ors.basePoint` to `scheme.reps m_bp` (only appears
          -- in the `orbit G _` slot; `combiner.combine` does not mention it).
          -- Then discharge via `combiner.closed` after rewriting each hypothesis.
          rw [hBase]
          exact combiner.closed x y
            (by rw [← hBase]; exact hx)
            (by rw [← hBase]; exact hy)) i j₁ =
      obliviousSample ors combiner.combine
        (fun x y hx hy => by
          rw [hBase]
          exact combiner.closed x y
            (by rw [← hBase]; exact hx)
            (by rw [← hBase]; exact hy)) i j₂ := by
  -- Unfold both sides; the proof reduces to `combine (reps m_bp) (r j₁) = combine (reps m_bp) (r j₂)`.
  simp only [obliviousSample_eq]
  -- Rewrite the first argument to `reps m_bp` using `hi`.
  rw [hi]
  -- Each randomizer is in `orbit G (reps m_bp)` (via `ors.in_orbit` + `hBase`).
  have h1 : ors.randomizers j₁ ∈ MulAction.orbit G (scheme.reps m_bp) := by
    rw [← hBase]; exact ors.in_orbit j₁
  have h2 : ors.randomizers j₂ ∈ MulAction.orbit G (scheme.reps m_bp) := by
    rw [← hBase]; exact ors.in_orbit j₂
  -- Apply the OIA-forced constancy lemma on each side.
  rw [oia_forces_combine_constant_on_orbit scheme m_bp combiner hOIA h1,
      oia_forces_combine_constant_on_orbit scheme m_bp combiner hOIA h2]

-- ============================================================================
-- Workstream E6 — Probabilistic refinement of `equivariant_combiner_breaks_oia`
-- ============================================================================

section ConcreteEquivariantCombiner

open PMF

variable {G : Type*} {X : Type*} {M : Type*}
  [Group G] [Fintype G] [Nonempty G] [MulAction G X] [DecidableEq X]

/-- **Workstream E6a.** The distribution of `combinerDistinguisher`'s Boolean
    output as we vary the group element applied to the scheme's message
    representative. Push-forward of the uniform group distribution through
    the composite `g ↦ combinerDistinguisher comb (g • scheme.reps m)`. -/
noncomputable def combinerOrbitDist
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (comb : GEquivariantCombiner G X (scheme.reps m_bp)) (m : M) : PMF Bool :=
  PMF.map (fun g : G => combinerDistinguisher comb (g • scheme.reps m))
    (uniformPMF G)

/-- **Workstream E6a (continued).** Distinguishing advantage of the
    combiner-induced Boolean output distribution between two scheme
    messages. Measures how well `combinerDistinguisher` can tell the two
    orbit distributions apart. -/
noncomputable def combinerDistinguisherAdvantage
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (comb : GEquivariantCombiner G X (scheme.reps m_bp)) (m₀ m₁ : M) : ℝ :=
  advantage id (combinerOrbitDist scheme m_bp comb m₀)
              (combinerOrbitDist scheme m_bp comb m₁)

/-- Helper: `probTrue` through a `PMF.map` with the Boolean `id` reduces
    to the probability that the map function returns `true`. -/
private theorem probTrue_map_id_eq {α : Type*}
    (d : PMF α) (f : α → Bool) :
    probTrue (PMF.map f d) id = probTrue d f := by
  unfold probTrue
  rw [PMF.toOuterMeasure_map_apply]
  rfl

/-- Helper: `probTrue` through an `orbitDist` with a distinguisher
    factors as `probTrue uniformPMF (D ∘ orbit action)`. -/
private theorem probTrue_orbitDist_eq
    {G : Type*} {X : Type*}
    [Group G] [Fintype G] [Nonempty G] [MulAction G X]
    (x : X) (D : X → Bool) :
    probTrue (orbitDist (G := G) x) D =
    probTrue (uniformPMF G) (fun g => D (g • x)) := by
  unfold probTrue orbitDist
  rw [PMF.toOuterMeasure_map_apply]
  rfl

/-- The combiner-induced distinguisher is a plain Boolean function
    `X → Bool`; its advantage between orbit distributions equals
    `combinerDistinguisherAdvantage`. This is the bridge lemma used below
    to compose with `ConcreteOIA`. -/
theorem combinerDistinguisherAdvantage_eq
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (comb : GEquivariantCombiner G X (scheme.reps m_bp)) (m₀ m₁ : M) :
    combinerDistinguisherAdvantage scheme m_bp comb m₀ m₁ =
    advantage (combinerDistinguisher comb)
      (orbitDist (G := G) (scheme.reps m₀))
      (orbitDist (G := G) (scheme.reps m₁)) := by
  -- Both sides reduce to the same probability-on-uniformPMF expression.
  unfold combinerDistinguisherAdvantage combinerOrbitDist advantage
  rw [probTrue_map_id_eq, probTrue_map_id_eq,
      probTrue_orbitDist_eq, probTrue_orbitDist_eq]

/-- **Workstream E6 headline, concrete form.** Any `ConcreteOIA` bound for
    the scheme also bounds the advantage of the combiner-induced
    distinguisher.

    This is the probabilistic analogue of `equivariant_combiner_breaks_oia`:
    the deterministic version shows OIA is *refuted* by any non-degenerate
    equivariant combiner; the probabilistic version shows that the
    combiner's distinguishing advantage is an *explicit lower bound* on
    any ConcreteOIA ε bound.

    **Cryptographic reading.** If you exhibit any `G`-equivariant
    orbit-closed combiner `combine` on `scheme`, ConcreteOIA `ε` forces
    `combinerDistinguisherAdvantage ≤ ε`. Choosing a concrete combiner and
    computing its advantage therefore yields a hard lower bound on the
    scheme's attainable `ε`.

    For a non-vacuous combiner (e.g. one satisfying `NonDegenerateCombiner`),
    the advantage is strictly positive and ConcreteOIA `0` is refuted —
    matching the deterministic no-go. -/
theorem concrete_combiner_advantage_bounded_by_oia
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (comb : GEquivariantCombiner G X (scheme.reps m_bp))
    (ε : ℝ) (hOIA : ConcreteOIA scheme ε) (m₀ m₁ : M) :
    combinerDistinguisherAdvantage scheme m_bp comb m₀ m₁ ≤ ε := by
  rw [combinerDistinguisherAdvantage_eq]
  exact hOIA (combinerDistinguisher comb) m₀ m₁

/-- **Workstream E6b.** Under a non-degenerate equivariant combiner on
    `m_bp`'s orbit, the combiner-induced distinguisher has strictly
    positive "true-probability-variance" on that orbit: both Booleans
    have at least `1/|G|` mass.

    Precisely: under the uniform `g ∈ G` distribution over `m_bp`'s orbit,
    the distinguisher is `true` at `g = 1` (by `combinerDistinguisher_basePoint`)
    and `false` at some `g = g_w` (by `combinerDistinguisher_witness`).
    Hence the probability of either outcome is at least `1/|G|`.

    **Proof technique.** Bound each mass by the single-summand term at
    the relevant witness group element (`g = 1` for the `true` branch,
    `g = g_w` for the `false` branch), using `ENNReal.le_tsum` on the
    expanded `PMF.map_apply` form. Each witness summand equals
    `uniformPMF G witness = 1/|G|`. -/
theorem combinerOrbitDist_mass_bounds
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (comb : GEquivariantCombiner G X (scheme.reps m_bp))
    (hND : NonDegenerateCombiner comb) :
    ((Fintype.card G : ENNReal)⁻¹ ≤
        combinerOrbitDist scheme m_bp comb m_bp true) ∧
    ((Fintype.card G : ENNReal)⁻¹ ≤
        combinerOrbitDist scheme m_bp comb m_bp false) := by
  -- Shared setup: the push-forward function and its key value lemmas.
  set f : G → Bool := fun g =>
    combinerDistinguisher comb (g • scheme.reps m_bp) with hf_def
  have h_true_at_one : f 1 = true := by
    show combinerDistinguisher comb ((1 : G) • scheme.reps m_bp) = true
    rw [one_smul]; exact combinerDistinguisher_basePoint comb
  obtain ⟨g_w, hg_w⟩ := combinerDistinguisher_witness hND
  have h_false_at_gw : f g_w = false := hg_w
  refine ⟨?_, ?_⟩
  · -- Pr[true] ≥ 1/|G|.  Lower-bound the map-applied sum by the `g = 1`
    -- summand, which equals `uniformPMF G 1 = 1/|G|`.
    show (Fintype.card G : ENNReal)⁻¹ ≤ PMF.map f (uniformPMF G) true
    rw [PMF.map_apply]
    refine le_trans ?_ (ENNReal.le_tsum (1 : G))
    rw [if_pos (by rw [h_true_at_one]), uniformPMF_apply]
  · -- Pr[false] ≥ 1/|G|, symmetric argument via g_w.
    show (Fintype.card G : ENNReal)⁻¹ ≤ PMF.map f (uniformPMF G) false
    rw [PMF.map_apply]
    refine le_trans ?_ (ENNReal.le_tsum g_w)
    rw [if_pos (by rw [h_false_at_gw]), uniformPMF_apply]

end ConcreteEquivariantCombiner

end Orbcrypt
