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
  uniform PMF on `Nonce → Tag`.
* `Orbcrypt.idealRandomOraclePRF` — the truly-random-oracle PRF where
  the "key" is the entire function and `prf k n := k n`.

## Main results

* `Orbcrypt.noncedForgeryAdvantage_Qtime_nonneg` /
  `Orbcrypt.noncedForgeryAdvantage_Qtime_le_one` — basic bounds.
* `Orbcrypt.noncedMAC_tag_correct` — `verify` accepts honest tags
  (the `correct` field in `MAC` parlance).
* `Orbcrypt.IsPRF.mono` — monotonicity in ε.
* `Orbcrypt.IsPRF.le_one` — every prf is trivially `1`-PRF.
* `Orbcrypt.idealRandomOraclePRF_isPRF` — the truly-random oracle is
  a `0`-PRF (the two distributions coincide exactly).

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
* docs/planning/AUDIT_2026-04-29_COMPREHENSIVE_WORKSTREAM_PLAN.md
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
is at most `ε.toReal`.

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
to `Nonce := Fin N` for some `N`.

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
    (prf : K_p → Nonce → Tag) (ε : ℝ≥0∞) : Prop :=
  ∀ (D : (Nonce → Tag) → Bool),
    advantage D
      (PMF.map (fun k_p : K_p => fun n => prf k_p n) (uniformPMF K_p))
      (uniformPMF (Nonce → Tag)) ≤ ε.toReal

/--
Monotonicity in `ε`: if `prf` is `ε₁`-PRF and `ε₁ ≤ ε₂`, then `prf`
is `ε₂`-PRF.
-/
theorem IsPRF.mono [Fintype K_p] [Nonempty K_p]
    [Fintype Nonce] [Fintype Tag] [Nonempty Tag]
    [DecidableEq Nonce] [DecidableEq Tag]
    {prf : K_p → Nonce → Tag} {ε₁ ε₂ : ℝ≥0∞}
    (h : IsPRF prf ε₁) (hε : ε₁ ≤ ε₂) (hε₁_finite : ε₁ ≠ ⊤)
    (hε₂_finite : ε₂ ≠ ⊤) :
    IsPRF prf ε₂ := by
  intro D
  refine (h D).trans ?_
  exact (ENNReal.toReal_le_toReal hε₁_finite hε₂_finite).mpr hε

/--
Trivial bound: every prf is `1`-PRF (advantage is always `≤ 1`).
This is a satisfiability anchor; the cryptographic content is in
`ε < 1`.
-/
theorem IsPRF.le_one [Fintype K_p] [Nonempty K_p]
    [Fintype Nonce] [Fintype Tag] [Nonempty Tag]
    [DecidableEq Nonce] [DecidableEq Tag]
    (prf : K_p → Nonce → Tag) :
    IsPRF prf 1 := by
  intro D
  rw [ENNReal.toReal_one]
  exact advantage_le_one D _ _

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
`Nonce → Tag` (the projection is the identity), so the advantage
between the real and ideal distributions is exactly `0` for every
distinguisher (`advantage_self`). -/
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
  rw [ENNReal.toReal_zero]
  exact (advantage_self D _).le

end Orbcrypt
