/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Mathlib.Data.Fintype.Pi
import Mathlib.Algebra.Group.Basic
import Orbcrypt.Probability.Monad
import Orbcrypt.Probability.Advantage

/-!
# Orbcrypt.AEAD.NoncedMAC

Wegman–Carter 1981 §3 nonce-MAC framework: a hash family `hash : K_h →
Msg → Tag` composed with a pseudo-random function `prf : K_p → Nonce →
Tag` to produce per-(nonce, message) tags via additive masking
`tag(k_h, k_p, n, m) := hash(k_h, m) + prf(k_p, n)`.

## Overview

The non-nonced Carter–Wegman MAC `tag(k, m) := h(k, m)` is provably
broken at `Q ≥ 2` queries (cf. `not_carterWegmanMAC_isQtimeSUFCMASecure`
in `Orbcrypt/AEAD/CarterWegmanMAC.lean`): the adversary recovers the
key by solving a 2×2 linear system. The Wegman–Carter 1981 §3 fix is
to introduce a fresh nonce per message and an extra PRF mask:
the per-message tag becomes `hash(k_h, m) + prf(k_p, n)` where the
nonce `n` is non-repeating across queries. Under (a) ε_h-AXU on the
hash and (b) ε_p-PRF on the PRF, this construction is Q-time SUF-CMA
secure with advantage at most `Q · ε_h + ε_p + 1/|Tag|`.

This module formalises the construction's *structure* and the *PRF
hypothesis* (`IsPRF` Prop) together with a non-vacuity witness at the
truly-random oracle (`idealRandomOraclePRF`). The Q-time SUF-CMA
reduction itself lives in `Orbcrypt/AEAD/NoncedMACSecurity.lean`.

## Main definitions

* `Orbcrypt.NoncedMAC` — bundles a `hash` family and a `prf` family.
* `Orbcrypt.NoncedMAC.tag` — `(k_h, k_p, n, m) ↦ hash(k_h, m) +
  prf(k_p, n)`.
* `Orbcrypt.NoncedMAC.verify` — `decide`-equality verification.
* `Orbcrypt.NoncedMultiQueryMACAdversary` — non-adaptive Q-time
  adversary structure; pre-commits to Q `(nonce, message)` queries
  and a deterministic forge function over the Q tags.
* `Orbcrypt.NoncedMultiQueryMACAdversary.forges` — Boolean win
  predicate enforcing nonce-distinctness on the queries plus
  fresh-`(nonce, message)` constraint on the forge.
* `Orbcrypt.noncedForgeryAdvantage_Qtime` — probability over uniform
  `(k_h, k_p)` that the adversary's forgery wins.
* `Orbcrypt.IsNoncedQtimeSUFCMASecure` — `mac` is `ε`-Q-time-SUF-CMA-
  secure iff every Q-time non-adaptive adversary's advantage is at
  most `ε`.
* `Orbcrypt.IsPRF` — a function-level PRF predicate: `prf` is `ε`-
  pseudo-random iff every Boolean distinguisher on `Nonce → Tag` has
  advantage at most `ε` between the PMF.map'd PRF outputs and the
  uniform PMF on `Nonce → Tag`. Requires `[Fintype Nonce]`.
* `Orbcrypt.IsPRFAtQueries` — Q-tuple variant of `IsPRF` (matches
  the plan's formulation). Quantifies over injective `Fin Q → Nonce`
  query sequences; works for arbitrary (possibly infinite) nonce
  types.
* `Orbcrypt.idealRandomOraclePRF` — the truly-random-oracle PRF where
  the "key" is the entire function and `prf k n := k n`.

## Main results

* `Orbcrypt.noncedForgeryAdvantage_Qtime_nonneg` /
  `Orbcrypt.noncedForgeryAdvantage_Qtime_le_one` — basic bounds on
  the forgery advantage.
* `Orbcrypt.NoncedMAC.verify_tag` — `verify` accepts honest tags
  (the `correct` field in `MAC` parlance).
* `Orbcrypt.NoncedMAC.verify_iff` — equivalence between `verify =
  true` and `t = tag`.
* `Orbcrypt.IsNoncedQtimeSUFCMASecure.le_one` /
  `Orbcrypt.IsNoncedQtimeSUFCMASecure.mono` — basic bound + ε-
  monotonicity.
* `Orbcrypt.IsPRF.mono` / `Orbcrypt.IsPRFAtQueries.mono` — both
  variants monotone in ε.
* `Orbcrypt.IsPRF.le_one` / `Orbcrypt.IsPRFAtQueries.le_one` —
  trivial `1`-PRF bounds.
* `Orbcrypt.idealRandomOraclePRF_isPRF` — the truly-random oracle is
  a `0`-PRF (the two distributions coincide exactly).
* `Orbcrypt.PMF.map_eval_uniformOfFintype_at_injective_eq` —
  marginal-uniformity headline: pushing a uniform distribution on
  `(Nonce → Tag)` through the projection at an injective Q-tuple of
  nonces yields a uniform distribution on `(Fin Q → Tag)`. Proof
  uses Pi-type cardinality counting via `constrainedPiEquiv` +
  `constrainedPiCard` + ENNReal pow arithmetic.
* `Orbcrypt.idealRandomOraclePRF_isPRFAtQueries` — substantive
  Q-tuple witness: the truly-random oracle is `0`-PRF at every
  finite Q (proved unconditionally via the marginal-uniformity
  headline, not as a research-scope obligation).
* `Orbcrypt.IsPRF.toIsPRFAtQueries` — function-level → Q-tuple
  bridge. Under `[Fintype Nonce]`, `IsPRF prf ε` implies
  `IsPRFAtQueries prf Q ε` for every `Q : ℕ`. Proof composes the
  marginal-uniformity headline with the simulating-distinguisher
  argument (post-compose Q-tuple distinguisher with the projection
  at the supplied nonces).

## Design rationale

* **`NoncedMAC` is *not* a `MAC` instance.** A `MAC` (per
  `AEAD/MAC.lean`) takes `(K, Msg, Tag)` and tags messages directly.
  A `NoncedMAC` takes `(K_h × K_p, Nonce × Msg, Tag)` and tags
  `(nonce, message)` pairs. They are structurally distinct
  abstractions because the SUF-CMA game shape differs: the MAC's
  freshness is on messages, the NoncedMAC's freshness is on the
  `(nonce, message)` pair, and the queries' nonces must be pairwise
  distinct. The two structures live in parallel; no bridging adapter
  is provided because such an adapter would silently break the
  freshness game shape.

* **Function-level IsPRF.** `IsPRF prf ε` quantifies over
  distinguishers on the *full function space* `Nonce → Tag`, not
  over Q-tuples of distinguishers. This is conceptually cleaner
  (a single function-level advantage bound captures all Q-tuple
  bounds via post-composition with projection/evaluation maps), and
  it lets the truly-random oracle's non-vacuity proof reduce to
  `advantage_self`. The downside is that `[Fintype Nonce]` is
  required to make `Nonce → Tag` a Fintype — for production HMAC /
  AES-CTR use-cases, callers would restrict to `Nonce := Fin N` for
  a finite N (cf. § Common pitfalls in `PLAN_R_05_11_15.md`).

* **Adaptive vs. non-adaptive Q-time.** The headline reduction
  (which lives in `NoncedMACSecurity.lean`) is for **non-adaptive**
  Q-time adversaries (the `MultiQueryMACAdversary` shape from
  `MACSecurity.lean`). Adaptive Q-time would require oracle-style
  game machinery; tracked as research-scope follow-up R-05⁺.

## References

* Wegman, M. N. & Carter, J. L. (1981). "New hash functions and their
  use in authentication and set equality." J. Comput. Syst. Sci. 22:
  265–279. (Section 3 introduces the nonce-MAC construction this
  module formalises.)
* Bellare, M. & Rogaway, P. (2005). "Random Oracles in a Universe
  with Imperfect Hash Functions." (The IsPRF Q-tuple form's
  cryptographic interpretation.)
* Goldreich, O., Goldwasser, S., Micali, S. (1986). "How to construct
  random functions." J. ACM 33(4): 792–807. (The truly-random-oracle
  model.)
* docs/planning/PLAN_R_05_11_15.md § R-05 — research-scope discharge
  plan for this workstream.
* docs/dev_history/AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md
  § 8.1 — research-scope catalogue.
-/

set_option autoImplicit false

namespace Orbcrypt

open PMF ENNReal

universe u v w x y

variable {K_h : Type u} {K_p : Type v} {Nonce : Type w} {Msg : Type x} {Tag : Type y}

-- ============================================================================
-- Layer 1 — `NoncedMAC` structure + `tag` / `verify`
-- ============================================================================

/--
A **nonced MAC**: bundles a hash family `hash : K_h → Msg → Tag` and a
pseudo-random function `prf : K_p → Nonce → Tag`.

The per-message tag is `hash(k_h, m) + prf(k_p, n)` (additive masking
on `Tag`); the nonce `n` is a one-time-use value that, when freshly
sampled per query, eliminates the linear-system attack that breaks
nonce-free Carter–Wegman at `Q ≥ 2` queries.

**Fields.**
* `hash : K_h → Msg → Tag` — the universal-hash family.
* `prf : K_p → Nonce → Tag` — the pseudo-random function family.
-/
structure NoncedMAC (K_h : Type u) (K_p : Type v) (Nonce : Type w)
    (Msg : Type x) (Tag : Type y) where
  /-- The keyed universal-hash family. -/
  hash : K_h → Msg → Tag
  /-- The keyed pseudo-random function family. -/
  prf  : K_p → Nonce → Tag

/--
The tag function: `tag(k_h, k_p, n, m) := hash(k_h, m) + prf(k_p, n)`.
The additive masking by the PRF output is the cryptographic content
of the Wegman–Carter 1981 §3 construction.
-/
def NoncedMAC.tag [Add Tag]
    (mac : NoncedMAC K_h K_p Nonce Msg Tag)
    (k_h : K_h) (k_p : K_p) (n : Nonce) (m : Msg) : Tag :=
  mac.hash k_h m + mac.prf k_p n

/--
Verification: `decide`-equality against the regenerated tag.
-/
def NoncedMAC.verify [Add Tag] [DecidableEq Tag]
    (mac : NoncedMAC K_h K_p Nonce Msg Tag)
    (k_h : K_h) (k_p : K_p) (n : Nonce) (m : Msg) (t : Tag) : Bool :=
  decide (t = mac.tag k_h k_p n m)

/-- **Correctness.** `verify` accepts honestly-computed tags. The
proof is `decide_eq_true rfl`, mirroring `deterministicTagMAC.correct`
in `Orbcrypt/AEAD/CarterWegmanMAC.lean`. -/
@[simp] theorem NoncedMAC.verify_tag [Add Tag] [DecidableEq Tag]
    (mac : NoncedMAC K_h K_p Nonce Msg Tag)
    (k_h : K_h) (k_p : K_p) (n : Nonce) (m : Msg) :
    mac.verify k_h k_p n m (mac.tag k_h k_p n m) = true :=
  decide_eq_true rfl

/-- The verify-iff-equality lemma: `verify` returns `true` iff the
tag matches the honestly-computed value. Mirrors the
`IsDeterministicTagMAC` predicate from `MACSecurity.lean`. -/
theorem NoncedMAC.verify_iff [Add Tag] [DecidableEq Tag]
    (mac : NoncedMAC K_h K_p Nonce Msg Tag)
    (k_h : K_h) (k_p : K_p) (n : Nonce) (m : Msg) (t : Tag) :
    mac.verify k_h k_p n m t = true ↔ t = mac.tag k_h k_p n m :=
  decide_eq_true_iff

-- ============================================================================
-- Layer 2 — Q-time non-adaptive nonced-MAC adversary
-- ============================================================================

/--
A **non-adaptive Q-time nonced-MAC adversary**: pre-commits to `Q`
`(nonce, message)` queries upfront, observes the `Q` honest tags, and
produces a forgery `(n_forge, m_forge, t_forge)`.

**Non-adaptive choice.** Mirrors `MultiQueryMACAdversary` in
`MACSecurity.lean`: the adversary commits before observing any tag.
The nonce-respecting + freshness constraints are enforced inside
`forges`.
-/
structure NoncedMultiQueryMACAdversary (K_h : Type u) (K_p : Type v)
    (Nonce : Type w) (Msg : Type x) (Tag : Type y) (Q : ℕ) where
  /-- The `Q` `(nonce, message)` queries. -/
  queries : Fin Q → Nonce × Msg
  /-- Given the `Q` honest tags, produce a forgery
      `(nonce, message, tag)` triple. -/
  forge : (Fin Q → Tag) → Nonce × Msg × Tag

/--
**Forgery event** for a Q-time non-adaptive nonced-MAC adversary.
`true` iff:
1. The queries' nonces are pairwise distinct (the
   "nonce-respecting" convention).
2. The forge's `(nonce, message)` pair is not among the queries
   (SUF-CMA freshness).
3. The forge tag verifies.
-/
def NoncedMultiQueryMACAdversary.forges [Add Tag] [DecidableEq Tag]
    [DecidableEq Nonce] [DecidableEq Msg] {Q : ℕ}
    (mac : NoncedMAC K_h K_p Nonce Msg Tag)
    (A : NoncedMultiQueryMACAdversary K_h K_p Nonce Msg Tag Q)
    (k_h : K_h) (k_p : K_p) : Bool :=
  let tags : Fin Q → Tag :=
    fun i => mac.tag k_h k_p (A.queries i).1 (A.queries i).2
  let (n_forge, m_forge, t_forge) := A.forge tags
  -- Nonce-respecting: queried nonces distinct.
  let queries_distinct : Bool :=
    decide (∀ i j : Fin Q, i ≠ j → (A.queries i).1 ≠ (A.queries j).1)
  -- Fresh-(nonce, message): the forge's pair is not among the queries.
  let fresh : Bool :=
    decide (∀ i : Fin Q, (n_forge, m_forge) ≠ A.queries i)
  queries_distinct && fresh && mac.verify k_h k_p n_forge m_forge t_forge

/--
**Q-time SUF-CMA forgery advantage** for a nonced MAC. Probability
over uniformly-random `(k_h, k_p) ∈ K_h × K_p` that the adversary's
forgery wins.

The two keys are sampled jointly via `uniformPMF (K_h × K_p)`, which
is the canonical Orbcrypt pattern (matching `Probability/Monad.lean`'s
`uniformPMFTuple` and `PublicKey/ObliviousSampling.lean`'s
`uniformPMF (Fin t × Fin t)`). The marginal distributions are
independent uniform on `K_h` and `K_p` respectively.
-/
noncomputable def noncedForgeryAdvantage_Qtime
    [Fintype K_h] [Fintype K_p] [Nonempty K_h] [Nonempty K_p]
    [Add Tag] [DecidableEq Tag] [DecidableEq Nonce] [DecidableEq Msg]
    {Q : ℕ}
    (mac : NoncedMAC K_h K_p Nonce Msg Tag)
    (A : NoncedMultiQueryMACAdversary K_h K_p Nonce Msg Tag Q) : ℝ :=
  (probTrue (uniformPMF (K_h × K_p))
    (fun (k : K_h × K_p) => A.forges mac k.1 k.2)).toReal

/--
A nonced MAC is **ε-Q-time-SUF-CMA-secure** iff every Q-time non-
adaptive adversary's forgery advantage is at most `ε`.

**Game asymmetry note.** When `|Nonce| < Q` the queries-distinct
constraint is unsatisfiable (pigeonhole); `forges` returns `false` for
every adversary, and the advantage is `0`. The predicate then holds
vacuously at any `ε ≥ 0`. For meaningful Q-time analysis, callers
choose `Q ≤ |Nonce|`.
-/
def IsNoncedQtimeSUFCMASecure
    [Fintype K_h] [Fintype K_p] [Nonempty K_h] [Nonempty K_p]
    [Add Tag] [DecidableEq Tag] [DecidableEq Nonce] [DecidableEq Msg]
    {Q : ℕ}
    (mac : NoncedMAC K_h K_p Nonce Msg Tag) (ε : ℝ) : Prop :=
  ∀ A : NoncedMultiQueryMACAdversary K_h K_p Nonce Msg Tag Q,
    noncedForgeryAdvantage_Qtime mac A ≤ ε

/-- `noncedForgeryAdvantage_Qtime ≥ 0`. Direct from
`ENNReal.toReal_nonneg`. -/
theorem noncedForgeryAdvantage_Qtime_nonneg
    [Fintype K_h] [Fintype K_p] [Nonempty K_h] [Nonempty K_p]
    [Add Tag] [DecidableEq Tag] [DecidableEq Nonce] [DecidableEq Msg]
    {Q : ℕ}
    (mac : NoncedMAC K_h K_p Nonce Msg Tag)
    (A : NoncedMultiQueryMACAdversary K_h K_p Nonce Msg Tag Q) :
    0 ≤ noncedForgeryAdvantage_Qtime mac A :=
  ENNReal.toReal_nonneg

/-- `noncedForgeryAdvantage_Qtime ≤ 1`. Same proof shape as
`forgeryAdvantage_Qtime_le_one` in `MACSecurity.lean`. -/
theorem noncedForgeryAdvantage_Qtime_le_one
    [Fintype K_h] [Fintype K_p] [Nonempty K_h] [Nonempty K_p]
    [Add Tag] [DecidableEq Tag] [DecidableEq Nonce] [DecidableEq Msg]
    {Q : ℕ}
    (mac : NoncedMAC K_h K_p Nonce Msg Tag)
    (A : NoncedMultiQueryMACAdversary K_h K_p Nonce Msg Tag Q) :
    noncedForgeryAdvantage_Qtime mac A ≤ 1 := by
  unfold noncedForgeryAdvantage_Qtime
  set μ : PMF (K_h × K_p) := uniformPMF (K_h × K_p)
  have h_le : probTrue μ (fun k => A.forges mac k.1 k.2) ≤ 1 :=
    probTrue_le_one _ _
  have h_ne_top : probTrue μ (fun k => A.forges mac k.1 k.2) ≠ ⊤ :=
    ne_top_of_le_ne_top ENNReal.one_ne_top h_le
  have : (probTrue μ (fun k => A.forges mac k.1 k.2)).toReal ≤ (1 : ℝ≥0∞).toReal :=
    (ENNReal.toReal_le_toReal h_ne_top ENNReal.one_ne_top).mpr h_le
  simpa using this

/-- Trivial bound: every nonced MAC is `1`-Q-time-SUF-CMA-secure. -/
theorem IsNoncedQtimeSUFCMASecure.le_one
    [Fintype K_h] [Fintype K_p] [Nonempty K_h] [Nonempty K_p]
    [Add Tag] [DecidableEq Tag] [DecidableEq Nonce] [DecidableEq Msg]
    {Q : ℕ}
    (mac : NoncedMAC K_h K_p Nonce Msg Tag) :
    IsNoncedQtimeSUFCMASecure (Q := Q) mac 1 :=
  fun A => noncedForgeryAdvantage_Qtime_le_one mac A

/-- Monotonicity in `ε`: if `mac` is `ε₁`-secure and `ε₁ ≤ ε₂`, then
`mac` is `ε₂`-secure. A weaker bound is always implied by a tighter
one. -/
theorem IsNoncedQtimeSUFCMASecure.mono
    [Fintype K_h] [Fintype K_p] [Nonempty K_h] [Nonempty K_p]
    [Add Tag] [DecidableEq Tag] [DecidableEq Nonce] [DecidableEq Msg]
    {Q : ℕ} {mac : NoncedMAC K_h K_p Nonce Msg Tag} {ε₁ ε₂ : ℝ}
    (h : IsNoncedQtimeSUFCMASecure (Q := Q) mac ε₁) (hle : ε₁ ≤ ε₂) :
    IsNoncedQtimeSUFCMASecure (Q := Q) mac ε₂ :=
  fun A => (h A).trans hle

-- ============================================================================
-- Layer 3 — `IsPRF` Prop + `idealRandomOraclePRF` non-vacuity witness
-- ============================================================================

/--
A function `prf : K_p → Nonce → Tag` is an **`ε`-PRF** iff for every
Boolean distinguisher `D : (Nonce → Tag) → Bool`, the advantage
between
* `μ_real := PMF.map (fun k_p : K_p => fun n => prf k_p n) (uniformPMF K_p)`
  — sample `k_p` uniformly, output the entire PRF function.
* `μ_ideal := uniformPMF (Nonce → Tag)` — sample a truly-random
  function uniformly.
is at most `ε`.

**Function-level formulation.** This is the cleanest version of the
PRF predicate: it captures the indistinguishability between sampling
the PRF (parametrised by a key) and sampling a truly-random function
*at the function level*, not at any specific Q-tuple of inputs. A
distinguisher that queries the function at any number of points (with
arbitrary post-processing) is captured by this single predicate.

**Why `[Fintype Nonce]`.** The ideal distribution `uniformPMF (Nonce →
Tag)` requires `(Nonce → Tag)` to be a `Fintype`, which holds when
both `Nonce` and `Tag` are Fintype. For production use cases with
infinite nonce spaces (e.g., `ℕ`-valued counters), callers restrict
to `Nonce := Fin N` for some `N`. A Q-tuple variant `IsPRFAtQueries`
that works for arbitrary nonce types is provided alongside this
function-level version (cf. `IsPRFAtQueries` below).

**Why `ε : ℝ` (not `ℝ≥0∞`).** The codomain of `advantage` is `ℝ` so
the cleanest comparison is in `ℝ`. Matches the `ConcreteOIA` /
`ConcreteKEMOIA_uniform` convention. (An earlier formulation using
`ε : ℝ≥0∞` with `≤ ε.toReal` had a degenerate `⊤`-collapse: at
`ε = ⊤`, `⊤.toReal = 0` would force advantage = 0, the *strongest*
property, inverting expected monotonicity. The `ℝ`-valued
formulation eliminates this corner case.)

**Cryptographic interpretation.** The standard PRF assumption: a PRF
indexed by a finite key family `K_p` is computationally
indistinguishable from a uniformly-random function. Inhabited at
ε = 0 by `idealRandomOraclePRF` (where the "key" is the entire
function and the PRF is just function evaluation). For concrete PRFs
(HMAC, AES-CTR), the predicate at non-zero `ε` is the standard
cryptographic assumption (HMAC-PRF, AES-PRF), provable in the random-
oracle / ideal-cipher model but not provable inside Lean.
-/
def IsPRF [Fintype K_p] [Nonempty K_p]
    [Fintype Nonce] [Fintype Tag] [Nonempty Tag]
    [DecidableEq Nonce] [DecidableEq Tag]
    (prf : K_p → Nonce → Tag) (ε : ℝ) : Prop :=
  ∀ (D : (Nonce → Tag) → Bool),
    advantage D
      (PMF.map (fun k_p : K_p => fun n => prf k_p n) (uniformPMF K_p))
      (uniformPMF (Nonce → Tag)) ≤ ε

/--
Monotonicity in `ε`: if `prf` is `ε₁`-PRF and `ε₁ ≤ ε₂`, then `prf`
is `ε₂`-PRF. Trivial by transitivity in `ℝ`; no finiteness
hypotheses required.
-/
theorem IsPRF.mono [Fintype K_p] [Nonempty K_p]
    [Fintype Nonce] [Fintype Tag] [Nonempty Tag]
    [DecidableEq Nonce] [DecidableEq Tag]
    {prf : K_p → Nonce → Tag} {ε₁ ε₂ : ℝ}
    (h : IsPRF prf ε₁) (hε : ε₁ ≤ ε₂) :
    IsPRF prf ε₂ :=
  fun D => (h D).trans hε

/--
Trivial bound: every prf is `1`-PRF (advantage is always `≤ 1`).
This is a satisfiability anchor; the cryptographic content is in
`ε < 1`.
-/
theorem IsPRF.le_one [Fintype K_p] [Nonempty K_p]
    [Fintype Nonce] [Fintype Tag] [Nonempty Tag]
    [DecidableEq Nonce] [DecidableEq Tag]
    (prf : K_p → Nonce → Tag) :
    IsPRF prf 1 :=
  fun D => advantage_le_one D _ _

/--
**The truly-random-oracle PRF.** The "key" is the entire random
function `Nonce → Tag`, and the PRF is just function evaluation
`prf k n := k n`. This is the canonical non-vacuity witness for
`IsPRF` at `ε = 0`: sampling `k` uniformly from `(Nonce → Tag)` and
evaluating equals sampling `f` uniformly from `(Nonce → Tag)` and
returning `f` — the two distributions are *equal*, not approximately
equal, so the advantage is `0` for every distinguisher.

**Cryptographic interpretation.** The truly-random-oracle PRF
captures the random-oracle model: each query to the PRF returns an
independent uniform tag. Concrete cryptographic PRFs (HMAC, AES-CTR)
are conjectured to be indistinguishable from this idealisation, with
ε determined by the underlying primitive's strength.
-/
def idealRandomOraclePRF (Nonce : Type w) (Tag : Type y) :
    (Nonce → Tag) → Nonce → Tag :=
  fun k n => k n

/-- The truly-random-oracle PRF is a `0`-PRF. Both distributions
coincide exactly: sampling `k` uniformly and projecting via
`fun k => fun n => k n` gives back the same uniform PMF on
`Nonce → Tag` (the projection is the identity, after η-reduction),
so the advantage between the real and ideal distributions is exactly
`0` for every distinguisher (`advantage_self`). -/
theorem idealRandomOraclePRF_isPRF
    [Fintype Nonce] [Fintype Tag] [Nonempty Tag]
    [DecidableEq Nonce] [DecidableEq Tag] :
    IsPRF (idealRandomOraclePRF Nonce Tag) 0 := by
  intro D
  -- The real PMF: PMF.map (fun k => fun n => k n) (uniformPMF (Nonce → Tag))
  -- = PMF.map id (uniformPMF (Nonce → Tag))
  -- = uniformPMF (Nonce → Tag).
  -- After this rewrite, the advantage reduces to advantage_self = 0.
  unfold idealRandomOraclePRF
  -- The function `fun k_p : (Nonce → Tag) => fun n => k_p n` is η-reduced
  -- to the identity, so PMF.map id = id. Cast through PMF.map_id.
  have h_id_eq :
      (fun k_p : (Nonce → Tag) => fun n => k_p n) = id := by
    funext k n; rfl
  rw [h_id_eq, PMF.map_id]
  -- After the rewrite the two distributions coincide; advantage_self closes.
  exact (advantage_self D _).le

-- ============================================================================
-- Layer 4 — `IsPRFAtQueries`: Q-tuple variant of `IsPRF`
-- ============================================================================

/--
**Q-tuple PRF predicate** (matches the standard cryptographic
literature's formulation; cf. `docs/planning/PLAN_R_05_11_15.md`
§ R-05). A function `prf : K_p → Nonce → Tag` is an `ε`-PRF on
`Q`-tuples of distinct nonces iff for every injective Q-tuple
`nonces : Fin Q → Nonce` and every Boolean distinguisher
`D : (Fin Q → Tag) → Bool`, the advantage between the joint
real-PRF distribution and the uniform `Tag^Q` distribution is at
most ε.

**Why this Q-tuple variant in addition to `IsPRF`.**
* `IsPRF` requires `[Fintype Nonce]` (the function space `Nonce →
  Tag` must be `Fintype` for the ideal distribution `uniformPMF (Nonce
  → Tag)` to make sense). Production use-cases with infinite nonce
  spaces (e.g., `Nonce = ℕ`-valued counters) cannot satisfy this.
* `IsPRFAtQueries` quantifies only over **injective Q-tuples** of
  nonces, so it makes sense for *any* nonce type — finite or
  infinite. This matches Bellare-Rogaway 2005 and the standard
  cryptographic literature's PRF security definition.
* The two variants are linked by `IsPRF.toIsPRFAtQueries`: function-
  level PRF security implies Q-tuple security at every Q (under
  finite nonce types).

**Cryptographic interpretation.** Concrete PRFs (HMAC, AES-CTR) have
Q-specific bounds (e.g., AES-CTR's PRF advantage at Q queries is
`Q² / 2^128` under the AES-PRP assumption). The Q-tuple variant
captures these Q-parameterised bounds; the function-level variant is
the universal-over-Q form (less expressive for non-ideal PRFs but
sufficient for the truly-random-oracle case).
-/
def IsPRFAtQueries [Fintype K_p] [Nonempty K_p]
    [Fintype Tag] [Nonempty Tag]
    [DecidableEq Tag]
    (prf : K_p → Nonce → Tag) (Q : ℕ) (ε : ℝ) : Prop :=
  ∀ (nonces : Fin Q → Nonce) (D : (Fin Q → Tag) → Bool),
    Function.Injective nonces →
    advantage D
      (PMF.map (fun k_p : K_p => fun i => prf k_p (nonces i))
        (uniformPMF K_p))
      (uniformPMFTuple Tag Q) ≤ ε

/-- Monotonicity in `ε` for `IsPRFAtQueries`. -/
theorem IsPRFAtQueries.mono [Fintype K_p] [Nonempty K_p]
    [Fintype Tag] [Nonempty Tag] [DecidableEq Tag]
    {prf : K_p → Nonce → Tag} {Q : ℕ} {ε₁ ε₂ : ℝ}
    (h : IsPRFAtQueries prf Q ε₁) (hε : ε₁ ≤ ε₂) :
    IsPRFAtQueries prf Q ε₂ :=
  fun nonces D h_inj => (h nonces D h_inj).trans hε

/-- Trivial: every prf is `1`-PRF on Q-tuples. -/
theorem IsPRFAtQueries.le_one [Fintype K_p] [Nonempty K_p]
    [Fintype Tag] [Nonempty Tag] [DecidableEq Tag]
    (prf : K_p → Nonce → Tag) (Q : ℕ) :
    IsPRFAtQueries prf Q 1 :=
  fun _nonces D _h_inj => advantage_le_one D _ _

-- ============================================================================
-- Layer 5 — Marginal-uniformity infrastructure
-- ----------------------------------------------------------------------------
-- The substantive proof of `idealRandomOraclePRF_isPRFAtQueries` requires
-- the marginal-uniformity lemma: pushing a uniform distribution on
-- `(Nonce → Tag)` through the projection at injective `nonces : Fin Q →
-- Nonce` yields a uniform distribution on `(Fin Q → Tag)`.
--
-- The proof factors into:
--   * **Phase 1** (`constrainedPiEquiv`): bijection between the constrained
--     Pi-set `{f | ∀ i, f (nonces i) = t i}` and the free Pi-set on the
--     complement of `range nonces`.
--   * **Phase 2** (`constrainedPiCard`): cardinality of the constrained
--     Pi-set is `(Fintype.card Tag) ^ (Fintype.card Nonce - Q)`.
--   * **Phase 3** (`PMF.map_eval_uniformOfFintype_at_injective_eq`): the
--     PMF identity `PMF.map proj (uniformPMF (Nonce → Tag)) =
--     uniformPMFTuple Tag Q`.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Phase 1 — Pi-type Equiv (≈ 70 LOC)
-- ----------------------------------------------------------------------------

/-- Decidability of range membership for `nonces : Fin Q → Nonce` under
    `[Fintype Nonce]` + `[DecidableEq Nonce]`. The membership
    `n ∈ Set.range nonces` reduces to `∃ i : Fin Q, nonces i = n`,
    which is decidable when `Fin Q` is Fintype and `Nonce` has
    `DecidableEq`. -/
private instance decidableMemRange [Fintype Nonce] [DecidableEq Nonce]
    {Q : ℕ} (nonces : Fin Q → Nonce) :
    DecidablePred (· ∈ Set.range nonces) := by
  intro n
  exact decidable_of_iff (∃ i, nonces i = n) Set.mem_range.symm

/-- For an injective `nonces : Fin Q → Nonce`, recover the `Fin Q`
    index of any range element. Built from `Equiv.ofInjective`. -/
private noncomputable def nonceIndex
    {Q : ℕ} (nonces : Fin Q → Nonce) (h_inj : Function.Injective nonces)
    (n : Nonce) (h : n ∈ Set.range nonces) : Fin Q :=
  (Equiv.ofInjective nonces h_inj).symm ⟨n, h⟩

/-- Round-trip: applying `nonces` to the recovered index of `nonces i`
    gives back `nonces i`, with the index recovered as `i` itself. -/
private theorem nonces_nonceIndex
    {Q : ℕ} (nonces : Fin Q → Nonce) (h_inj : Function.Injective nonces)
    (i : Fin Q) :
    nonceIndex nonces h_inj (nonces i) ⟨i, rfl⟩ = i := by
  unfold nonceIndex
  exact Equiv.ofInjective_symm_apply h_inj i

/-- **Phase 1 headline.** Bijection between the constrained Pi-set
    `{f : Nonce → Tag // ∀ i, f (nonces i) = t i}` (functions agreeing
    with `t` on `range nonces`) and the free Pi-set on the complement
    `({n : Nonce // n ∉ Set.range nonces} → Tag)`.

    The forward map *restricts* `f` to the complement; the inverse
    map *extends* a function on the complement to all of `Nonce` by
    using `t` (composed with the inverse of `nonces` on its range)
    for the range elements. The bijection is `noncomputable` because
    `Equiv.ofInjective` uses `Function.invFun`. -/
private noncomputable def constrainedPiEquiv
    [Fintype Nonce] [DecidableEq Nonce]
    {Q : ℕ} (nonces : Fin Q → Nonce) (h_inj : Function.Injective nonces)
    (t : Fin Q → Tag) :
    {f : Nonce → Tag // ∀ i, f (nonces i) = t i}
    ≃ ({n : Nonce // n ∉ Set.range nonces} → Tag) where
  toFun := fun ⟨f, _⟩ n => f n.val
  invFun := fun g =>
    ⟨fun n =>
        if h : n ∈ Set.range nonces then
          t (nonceIndex nonces h_inj n h)
        else
          g ⟨n, h⟩,
     fun i => by
       have h_in : nonces i ∈ Set.range nonces := ⟨i, rfl⟩
       simp only [dif_pos h_in]
       congr 1
       exact nonces_nonceIndex nonces h_inj i⟩
  left_inv := fun ⟨f, hf⟩ => by
    apply Subtype.ext
    funext n
    by_cases h : n ∈ Set.range nonces
    · simp only [dif_pos h]
      obtain ⟨i, rfl⟩ := h
      rw [nonces_nonceIndex nonces h_inj i]
      exact (hf i).symm
    · simp only [dif_neg h]
  right_inv := fun g => by
    funext n
    have h : n.val ∉ Set.range nonces := n.property
    simp only [dif_neg h]

-- ----------------------------------------------------------------------------
-- Phase 2 — Cardinality of the constrained Pi-set (≈ 40 LOC)
-- ----------------------------------------------------------------------------

/-- The cardinality of the complement of `range nonces` (as a subtype)
    equals `|Nonce| - Q` for an injective `nonces : Fin Q → Nonce`.
    Combines `Fintype.card_subtype_compl` with the bijection
    `Set.range nonces ≃ Fin Q` (from `Equiv.ofInjective`). -/
private theorem compl_range_card
    [Fintype Nonce] [DecidableEq Nonce]
    {Q : ℕ} (nonces : Fin Q → Nonce) (h_inj : Function.Injective nonces) :
    Fintype.card {n : Nonce // n ∉ Set.range nonces}
    = Fintype.card Nonce - Q := by
  -- Step 1: rewrite `card {n // ¬ p n}` to `card α - card {n // p n}`.
  rw [Fintype.card_subtype_compl]
  -- Step 2: `card {n // n ∈ Set.range nonces} = card (range nonces)` (via
  -- the trivial `{n // n ∈ S} ≃ ↥S` Equiv) `= card (Fin Q) = Q` (via
  -- `Equiv.ofInjective`).
  congr 1
  rw [show Fintype.card {n : Nonce // n ∈ Set.range nonces}
      = Fintype.card (Set.range nonces) from rfl,
      Fintype.card_congr (Equiv.ofInjective nonces h_inj).symm,
      Fintype.card_fin]

/-- **Phase 2 headline.** The cardinality of the constrained Pi-set
    `{f : Nonce → Tag // ∀ i, f (nonces i) = t i}` equals
    `(Fintype.card Tag) ^ (Fintype.card Nonce - Q)`.

    Proof: use the Phase-1 Equiv `constrainedPiEquiv` to swap the
    constrained Pi-set for the free Pi-set on the complement of
    `range nonces`. The free Pi-set has cardinality `(Fintype.card
    Tag) ^ (Fintype.card {n // n ∉ range nonces})` (via
    `Fintype.card_fun`), and the inner cardinality is `|Nonce| - Q`
    (via `compl_range_card`). -/
private theorem constrainedPiCard
    [Fintype Nonce] [Fintype Tag] [DecidableEq Nonce] [DecidableEq Tag]
    {Q : ℕ} (nonces : Fin Q → Nonce) (h_inj : Function.Injective nonces)
    (t : Fin Q → Tag) :
    Fintype.card {f : Nonce → Tag // ∀ i, f (nonces i) = t i}
    = (Fintype.card Tag) ^ (Fintype.card Nonce - Q) := by
  rw [Fintype.card_congr (constrainedPiEquiv nonces h_inj t),
      Fintype.card_fun, compl_range_card nonces h_inj]

-- ----------------------------------------------------------------------------
-- Phase 3 — Marginal-uniformity PMF identity (≈ 80 LOC)
-- ----------------------------------------------------------------------------

/-- **Phase 3 headline.** Pushing the uniform PMF on `(Nonce → Tag)`
    through the projection `fun f => fun i => f (nonces i)` (for
    injective `nonces : Fin Q → Nonce`) yields the uniform PMF on
    `(Fin Q → Tag)`.

    This is the **marginal-uniformity** lemma: the marginal of a
    uniform distribution on a product Pi-type, projected at a fixed
    coordinate set with constant preimage size (which the
    injectivity of `nonces` provides), is uniform on the
    projection's codomain.

    **Proof outline.**
    1. Apply `PMF.ext`. For each `t : Fin Q → Tag`, compute LHS via
       `PMF.toOuterMeasure_map_apply` + `PMF.toOuterMeasure_uniformOfFintype_apply`.
       This gives `Fintype.card (preimage) / Fintype.card (Nonce → Tag)`.
    2. The preimage `proj⁻¹ {t}` (as a Set) bijects with the
       constrained Pi-set `{f // ∀ i, f (nonces i) = t i}` (via
       `Set.preimage` + `funext_iff`); cardinality from Phase 2 is
       `|Tag| ^ (|Nonce| - Q)`.
    3. `Fintype.card (Nonce → Tag) = |Tag| ^ |Nonce|` (by
       `Fintype.card_fun`).
    4. ENNReal arithmetic: `|Tag|^(n-Q) / |Tag|^n = 1 / |Tag|^Q`,
       valid for `|Tag| ≠ 0`, `|Tag| ≠ ⊤`, `Q ≤ n` (from
       `Fintype.card_le_of_injective` on `nonces`).
    5. RHS via `uniformPMFTuple_apply`: `1 / |Tag|^Q`.
    6. Equate. -/
theorem PMF.map_eval_uniformOfFintype_at_injective_eq
    [Fintype Nonce] [Fintype Tag] [Nonempty Tag]
    [DecidableEq Nonce] [DecidableEq Tag]
    {Q : ℕ} (nonces : Fin Q → Nonce) (h_inj : Function.Injective nonces) :
    PMF.map (fun f : Nonce → Tag => fun i : Fin Q => f (nonces i))
            (uniformPMF (Nonce → Tag))
    = uniformPMFTuple Tag Q := by
  classical
  apply PMF.ext
  intro t
  -- Set up positivity / finiteness side conditions.
  have h_tag_pos : 0 < Fintype.card Tag := Fintype.card_pos
  have h_tag_ne_zero : (Fintype.card Tag : ℝ≥0∞) ≠ 0 := by
    exact_mod_cast h_tag_pos.ne'
  have h_tag_ne_top : (Fintype.card Tag : ℝ≥0∞) ≠ ⊤ :=
    ENNReal.natCast_ne_top _
  have hQ_le : Q ≤ Fintype.card Nonce := by
    have := Fintype.card_le_of_injective nonces h_inj
    rw [Fintype.card_fin] at this
    exact this
  -- Step 1: RHS = (Fintype.card Tag)^Q ⁻¹.
  rw [uniformPMFTuple_apply]
  -- Step 2: LHS = uniformPMF.toOuterMeasure (preimage of {t}).
  -- We use the identity (PMF.map f μ) b = (PMF.map f μ).toOuterMeasure {b},
  -- which follows from PMF apply / outer measure consistency.
  -- Then PMF.toOuterMeasure_map_apply identifies this with
  -- μ.toOuterMeasure (f⁻¹ {b}).
  have h_lhs_apply :
      (PMF.map (fun f : Nonce → Tag => fun i : Fin Q => f (nonces i))
              (uniformPMF (Nonce → Tag))) t
      = ((Fintype.card {f : Nonce → Tag //
            ∀ i, f (nonces i) = t i} : ℝ≥0∞) /
        (Fintype.card (Nonce → Tag) : ℝ≥0∞)) := by
    -- Reduce via PMF.map_apply and tsum_fintype.
    rw [PMF.map_apply, tsum_fintype]
    -- Goal: ∑ f, if t = (fun i => f (nonces i)) then (uniformPMF) f else 0 = ...
    -- Each non-zero term has value uniformPMF f = 1/|Nonce → Tag|.
    -- Rewrite all occurrences via simp_rw of PMF.uniformOfFintype_apply.
    simp_rw [show (uniformPMF (Nonce → Tag)) =
        (PMF.uniformOfFintype (Nonce → Tag)) from rfl,
      PMF.uniformOfFintype_apply]
    -- Convert to filter-sum.
    rw [← Finset.sum_filter]
    -- Sum of constant over filter.
    rw [Finset.sum_const, nsmul_eq_mul]
    -- Convert filter cardinality to subtype cardinality.
    have h_filter_card_eq :
        ((Finset.univ.filter
            (fun f : Nonce → Tag => t = (fun i => f (nonces i)))).card : ℝ≥0∞)
        = (Fintype.card {f : Nonce → Tag // ∀ i, f (nonces i) = t i} : ℝ≥0∞) := by
      have h_eq :
          Finset.univ.filter (fun f : Nonce → Tag => t = (fun i => f (nonces i)))
          = Finset.univ.filter (fun f : Nonce → Tag => ∀ i, f (nonces i) = t i) := by
        apply Finset.filter_congr
        intro f _
        constructor
        · intro h i
          have := congr_fun h i
          exact this.symm
        · intro h
          funext i
          exact (h i).symm
      rw [h_eq]
      rw [Fintype.card_subtype]
    rw [h_filter_card_eq]
    -- Goal: card_subtype * |Nonce → Tag|⁻¹ = card_subtype / |Nonce → Tag|.
    rw [ENNReal.div_eq_inv_mul, mul_comm]
  rw [h_lhs_apply]
  -- Step 3: Substitute Phase-2 cardinality.
  rw [constrainedPiCard nonces h_inj t, Fintype.card_fun]
  -- After substitution, the goal has Nat.pow inside the cast (`↑(a^b)`).
  -- Push casts through via `Nat.cast_pow` to get the ENNReal-pow form
  -- (`↑a ^ b`).
  simp only [Nat.cast_pow]
  -- Goal: ((Fintype.card Tag : ℝ≥0∞) ^ (|Nonce|-Q)) / ((Fintype.card Tag : ℝ≥0∞) ^ |Nonce|)
  --       = ((Fintype.card Tag : ℝ≥0∞) ^ Q)⁻¹
  -- Step 4: ENNReal pow arithmetic.
  -- Use |Tag|^|Nonce| = |Tag|^Q * |Tag|^(|Nonce|-Q) (via pow_add + Q + (|Nonce|-Q) = |Nonce|).
  have h_pow_split :
      (Fintype.card Tag : ℝ≥0∞) ^ (Fintype.card Nonce)
      = (Fintype.card Tag : ℝ≥0∞) ^ Q
        * (Fintype.card Tag : ℝ≥0∞) ^ (Fintype.card Nonce - Q) := by
    rw [← pow_add]
    congr 1
    omega
  rw [h_pow_split]
  -- Goal: (|Tag|^(|Nonce|-Q)) / (|Tag|^Q * |Tag|^(|Nonce|-Q)) = (|Tag|^Q)⁻¹
  -- Need: |Tag|^(|Nonce|-Q) ≠ 0, |Tag|^(|Nonce|-Q) ≠ ⊤.
  have h_pow_ne_zero : (Fintype.card Tag : ℝ≥0∞) ^ (Fintype.card Nonce - Q) ≠ 0 :=
    pow_ne_zero _ h_tag_ne_zero
  have h_pow_ne_top : (Fintype.card Tag : ℝ≥0∞) ^ (Fintype.card Nonce - Q) ≠ ⊤ :=
    ENNReal.pow_ne_top h_tag_ne_top
  rw [ENNReal.div_eq_inv_mul, ENNReal.mul_inv (Or.inl (pow_ne_zero _ h_tag_ne_zero))
        (Or.inl (ENNReal.pow_ne_top h_tag_ne_top))]
  -- After the two rewrites the goal is:
  --   ((a^Q)⁻¹ * (a^(n-Q))⁻¹) * a^(n-Q) = (a^Q)⁻¹
  -- Re-associate: (a^Q)⁻¹ * ((a^(n-Q))⁻¹ * a^(n-Q)).
  rw [mul_assoc]
  -- Cancel: (a^(n-Q))⁻¹ * a^(n-Q) = 1.
  rw [ENNReal.inv_mul_cancel h_pow_ne_zero h_pow_ne_top, mul_one]

-- ----------------------------------------------------------------------------
-- Phase 4 — `idealRandomOraclePRF_isPRFAtQueries` witness (≈ 25 LOC)
-- ----------------------------------------------------------------------------

/-- **Phase 4 headline.** The truly-random-oracle PRF is `0`-PRF in
    the **Q-tuple form**, for every `Q : ℕ` and finite `Nonce`.

    This is the substantive Q-tuple analogue of
    `idealRandomOraclePRF_isPRF`: while the function-level form
    follows trivially from `PMF.map_id`, the Q-tuple form requires
    the marginal-uniformity argument from Phase 3.

    **Cryptographic interpretation.** The Q-tuple ideal-oracle PMF
    (sample `k_p ← (Nonce → Tag)` uniformly, evaluate at Q distinct
    nonces) coincides exactly with the `Tag^Q` uniform PMF
    (`uniformPMFTuple Tag Q`). Hence the advantage between the two
    distributions is `0` for every distinguisher.

    **Proof**: Apply Phase 3's marginal-uniformity to identify the
    real and ideal distributions; close with `advantage_self`.
-/
theorem idealRandomOraclePRF_isPRFAtQueries
    [Fintype Nonce] [Fintype Tag] [Nonempty Tag]
    [DecidableEq Nonce] [DecidableEq Tag] (Q : ℕ) :
    IsPRFAtQueries (idealRandomOraclePRF Nonce Tag) Q 0 := by
  intro nonces D h_inj
  -- Goal: advantage D μ_real μ_ideal ≤ 0
  -- where μ_real = PMF.map (fun k_p => fun i => idealRandomOraclePRF k_p (nonces i)) ...
  -- and μ_ideal = uniformPMFTuple Tag Q.
  unfold idealRandomOraclePRF
  -- Goal: advantage D (PMF.map (fun k_p => fun i => k_p (nonces i)) ...)
  --                  (uniformPMFTuple Tag Q) ≤ 0
  rw [PMF.map_eval_uniformOfFintype_at_injective_eq nonces h_inj]
  -- Goal: advantage D (uniformPMFTuple Tag Q) (uniformPMFTuple Tag Q) ≤ 0
  -- Close with advantage_self (= 0, hence ≤ 0).
  exact (advantage_self D _).le

-- ----------------------------------------------------------------------------
-- Phase 5 — `IsPRF.toIsPRFAtQueries` bridge (≈ 50 LOC)
-- ----------------------------------------------------------------------------

/-- **Phase 5 headline.** Function-level PRF security implies Q-tuple
    PRF security (under finite Nonce).

    Any Q-tuple distinguisher `D : (Fin Q → Tag) → Bool` lifts to a
    function-level distinguisher `D' : (Nonce → Tag) → Bool` via
    post-composition with the projection. Their advantages on the
    respective Q-tuple / function-level distributions are equal,
    courtesy of the marginal-uniformity (Phase 3): both the real
    and ideal Q-tuple distributions are pushforwards of their
    function-level counterparts under the same projection.

    **Cryptographic interpretation.** A PRF whose function-level
    output is indistinguishable from a uniformly-random function
    is also indistinguishable when we observe only Q output values
    at distinct nonces. The reverse direction (Q-tuple ⇒
    function-level) does *not* hold in general: function-level
    distinguishers can correlate output values across many nonces,
    whereas Q-tuple distinguishers see only Q observations. -/
theorem IsPRF.toIsPRFAtQueries [Fintype K_p] [Nonempty K_p]
    [Fintype Nonce] [Fintype Tag] [Nonempty Tag]
    [DecidableEq Nonce] [DecidableEq Tag]
    {prf : K_p → Nonce → Tag} {ε : ℝ}
    (h : IsPRF prf ε) (Q : ℕ) :
    IsPRFAtQueries prf Q ε := by
  intro nonces D h_inj
  classical
  -- Define the simulating function-level distinguisher D':
  --   D' f := D (fun i => f (nonces i)).
  set D' : (Nonce → Tag) → Bool := fun f => D (fun i => f (nonces i)) with hD'_def
  -- Step 5.1: real-side factorisation via PMF.map_comp.
  -- The Q-tuple real PMF is the function-level real PMF post-composed with proj.
  have h_real_factor :
      PMF.map (fun k_p : K_p => fun i => prf k_p (nonces i)) (uniformPMF K_p)
      = PMF.map (fun f : Nonce → Tag => fun i => f (nonces i))
          (PMF.map (fun k_p : K_p => fun n => prf k_p n) (uniformPMF K_p)) := by
    rw [PMF.map_comp]
    rfl
  -- Step 5.2: ideal-side factorisation via Phase 3.
  have h_ideal_factor :
      uniformPMFTuple Tag Q
      = PMF.map (fun f : Nonce → Tag => fun i => f (nonces i))
          (uniformPMF (Nonce → Tag)) :=
    (PMF.map_eval_uniformOfFintype_at_injective_eq nonces h_inj).symm
  -- Step 5.3: rewrite the advantage to the function-level shape.
  -- The key identity: advantage D (μ.map f) (ν.map f) = advantage (D ∘ f) μ ν,
  -- because probTrue (μ.map f) D = probTrue μ (D ∘ f) (probTrue_map).
  -- We apply this manually to bridge to the function-level distinguisher D'.
  have h_advantage_eq :
      advantage D
        (PMF.map (fun k_p : K_p => fun i => prf k_p (nonces i)) (uniformPMF K_p))
        (uniformPMFTuple Tag Q)
      = advantage D'
        (PMF.map (fun k_p : K_p => fun n => prf k_p n) (uniformPMF K_p))
        (uniformPMF (Nonce → Tag)) := by
    rw [h_real_factor, h_ideal_factor]
    unfold advantage
    -- Goal: |(probTrue (μ.map proj) D).toReal - (probTrue (ν.map proj) D).toReal|
    --       = |(probTrue μ D').toReal - (probTrue ν D').toReal|
    -- Both probTrue expressions can be pushed through .map via probTrue_map.
    rw [probTrue_map (μ := PMF.map _ (uniformPMF K_p)),
        probTrue_map (μ := uniformPMF (Nonce → Tag))]
    -- The function-composition `D ∘ (fun f => fun i => f (nonces i))`
    -- is definitionally equal to D' = fun f => D (fun i => f (nonces i)).
    rfl
  rw [h_advantage_eq]
  -- Apply the function-level IsPRF hypothesis to D'.
  exact h D'

end Orbcrypt
