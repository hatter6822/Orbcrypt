/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.PublicKey.CommutativeAction
import Orbcrypt.Probability.Monad
import Orbcrypt.Probability.Advantage

/-!
# Orbcrypt.PublicKey.CSIDHHardness

Decisional Diffie–Hellman hardness for commutative group actions, plus the
IND-CPA / ROR-CPA reduction for `CommOrbitPKE` conditional on the DDH Prop.

## Workstream R-11 (audit 2026-04-29 § 8.1, plan
`docs/planning/PLAN_R_05_11_15.md` § R-11)

`Orbcrypt.PublicKey.CommutativeAction` provides the abstract `CommGroupAction`
typeclass and the `CommOrbitPKE` structure for CSIDH-style public-key
encryption. Pre-R-11, the only registered instance was `selfAction`
(commutative group acting on itself), which is broken in polynomial time by
discrete log in finite cyclic groups. R-11 closes that gap by introducing:

* `IsCommActionDDHHard` — `Prop`-valued predicate parametrising the standard
  Decisional Diffie–Hellman assumption to the commutative-action setting.
* The IND-CPA / ROR-CPA reduction for `CommOrbitPKE` conditional on the DDH
  Prop, with bound `commPKEIndCPAAdvantage bp A ≤ ε` whenever the action is
  `ε`-DDH-hard at the basepoint.

The DDH Prop itself is not proved; it is the standard cryptographic
assumption underlying ElGamal-style PKE. Trivial inhabitation at `ε = 1`
follows from `advantage_le_one` and is delivered by `IsCommActionDDHHard.le_one`;
non-vacuous ε < 1 discharge for any *concrete* commutative action is
research-scope (CSIDH instantiation requires class field theory + isogeny
infrastructure that Mathlib doesn't yet have).

The companion module `Orbcrypt.PublicKey.MultGroupAction` registers the
multiplicative-group commutative action `(ZMod p)ˣ ↷ ZMod p` as the canonical
non-trivial witness (orbit of `0` is `{0}`, orbit of `1` is `(ZMod p)ˣ`),
plus a toy `(ZMod 7)ˣ` `CommOrbitPKE` non-vacuity instance.

## Main definitions

* `Orbcrypt.ddhRealDist` / `Orbcrypt.ddhRandomDist` — the two PMFs over the
  3-tuple DDH game view `(sk•bp, r•bp, k)`.
* `Orbcrypt.IsCommActionDDHHard` — DDH Prop predicate over a `CommGroupAction
  G X`, parametrised by a basepoint `bp : X` and an advantage bound `ε : ℝ`.
* `Orbcrypt.CommPKEAdversary` — IND-CPA adversary structure for `CommOrbitPKE`.
* `Orbcrypt.commPKEIndCPAAdvantage` — IND-CPA / ROR-CPA advantage of an
  adversary against `CommOrbitPKE` at a given basepoint (averaged over the
  secret key by uniform sampling). Defined as the DDH-distinguishing
  advantage at `A.guess` between `ddhRealDist` and `ddhRandomDist`.

## Main results

* `Orbcrypt.IsCommActionDDHHard.mono` / `.le_one` — basic monotonicity +
  `1`-bound satisfiability anchor.
* `Orbcrypt.commPKEIndCPAAdvantage_eq_ddh_advantage` — the IND-CPA / ROR-CPA
  advantage *equals* (definitionally, by `rfl`) the DDH advantage at the
  adversary's guess function. The algebraic core of the reduction.
* `Orbcrypt.commPKE_indCPA_under_csidh_ddh_hardness` — **headline.** The
  IND-CPA / ROR-CPA advantage of any adversary against the
  commutative-action PKE is at most `ε` whenever the action is
  `ε`-DDH-hard at the basepoint.

## Game shape (ROR-CPA, key-randomization variant)

The IND-CPA game for `CommOrbitPKE` is the standard *real-or-random* shared
key game:

* Setup: secret key `sk : G` (sampled uniformly), public key `pk = sk • bp`.
* Challenge: sample `r ←$ G`; compute ciphertext `c = r • bp` and either
  the *real* shared key `k_real = sk • (r • bp)` or a *random* key
  `k_rand = t • bp` for fresh `t ←$ G`.
* Adversary's view: `(pk, c, k_b)` for `b ∈ {real, random}`.
* Adversary's task: output a Boolean predicting whether the third coordinate
  is the real shared key.

The advantage `commPKEIndCPAAdvantage` is `|Pr[guess returns true | real] −
Pr[guess returns true | random]|`, the standard distinguishing advantage
(see `Orbcrypt.advantage`).

This matches the standard textbook ElGamal IND-CPA game, lifted to the
commutative-action setting (no message embedding; the "ROR" formulation is
chosen because `CommOrbitPKE` outputs a shared *secret* rather than a
plaintext-encrypted ciphertext, mirroring KEM-style security games).

**Why the secret key is marginalised out.** The standard IND-CPA experiment
in the cryptographic literature samples `sk ←$ G` as the first step of the
game; the adversary's advantage is the average over uniform `sk`. Our
`commPKEIndCPAAdvantage` follows this convention: the function takes only
the *basepoint* `bp` (not a `pke : CommOrbitPKE G X` instance with fixed
`sk`), and internally marginalises over uniform `sk`. This is the only
formulation that admits an exact equality with the standard 3-tuple DDH
game; a per-`pke` formulation would require averaging on the DDH side
(or, equivalently, would only bound the worst-case-over-`sk` advantage,
not the per-`pke` advantage).

## DDH game

The standard 3-tuple Decisional Diffie–Hellman game for a commutative action
`G ↷ X` with basepoint `bp ∈ X`:

* Real distribution: sample `sk, r ←$ G`; output `(sk • bp, r • bp,
  sk • (r • bp))`.
* Random distribution: sample `sk, r, t ←$ G`; output `(sk • bp, r • bp,
  t • bp)`.

The DDH adversary's task is to distinguish a sample from the real
distribution from a sample from the random distribution. The
`IsCommActionDDHHard bp ε` predicate states that no such distinguisher
achieves advantage greater than `ε`.

## Reduction

The IND-CPA → DDH reduction is **definitional**: `commPKEIndCPAAdvantage`
is *defined* to be the DDH advantage at the adversary's guess function
on the standard 3-tuple `(pk, c, k)` view (`(sk•bp, r•bp, sk•(r•bp))`
real, `(sk•bp, r•bp, t•bp)` random). Hence the IND-CPA advantage equals
the DDH advantage by `rfl` (witnessed by
`commPKEIndCPAAdvantage_eq_ddh_advantage`), and the headline reduction
follows from `IsCommActionDDHHard bp ε` by direct application of the
hypothesis to `A.guess`.

This is the strongest possible reduction shape: no game hops, no factor
loss, exact equality. The cleanness comes from defining
`commPKEIndCPAAdvantage` to marginalise over the secret key (matching the
standard cryptographic IND-CPA experiment) and from `CommGroupAction.comm`
making the action commutative — Alice's view `sk • (r • bp)` and Bob's
view `r • (sk • bp)` of the shared secret coincide by `csidh_correctness`.

## Status disclosure

* **Unconditional (machine-checked):** the `IsCommActionDDHHard` predicate;
  monotonicity (`.mono`); the trivial `1`-bound (`.le_one`); the
  `CommPKEAdversary` structure; the `commPKEIndCPAAdvantage` definition;
  the `rfl`-level `commPKEIndCPAAdvantage_eq_ddh_advantage`; the headline
  reduction `commPKE_indCPA_under_csidh_ddh_hardness`.
* **Research-scope (R-11⁺):** discharging `IsCommActionDDHHard` for any
  concrete commutative action (e.g., `(ZMod p)ˣ ↷ ZMod p`) is the standard
  DDH cryptographic assumption, not provable inside Lean.
* **Research-scope (R-11⁺ continued):** full CSIDH on supersingular elliptic
  curves over `F_p` requires class field theory + isogeny composition +
  Deuring's theorem in Mathlib (multi-year research-scope).

## References

* Castryck, Lange, Martindale, Panny, Renes — *CSIDH: An Efficient
  Post-Quantum Commutative Group Action* (2018).
* Boneh & Shoup — *A Graduate Course in Applied Cryptography*, Ch. 11
  (DDH-based PKE).
* Katz & Lindell — *Introduction to Modern Cryptography*, §11.4 (DDH and
  ElGamal).
* `docs/PUBLIC_KEY_ANALYSIS.md` — Phase 13 feasibility analysis.
* `docs/planning/PLAN_R_05_11_15.md` § R-11 — workstream plan.
-/

namespace Orbcrypt

open PMF ENNReal

variable {G : Type*} {X : Type*}

-- ============================================================================
-- WU-1.1a — Real and random DDH distributions over commutative actions
-- ============================================================================

/--
**DDH real distribution.** Sample `sk, r ←$ G` uniformly and independently;
output the triple `(sk • bp, r • bp, sk • (r • bp))`. The third coordinate
is the *real* Diffie–Hellman shared secret as Alice would compute it (Bob's
half-key `r • bp` modified by Alice's secret `sk`).

By `CommGroupAction.comm`, the third coordinate also equals `r • (sk • bp)
= r • pk`, the same shared secret as Bob would compute it (Alice's
half-key `sk • bp = pk` modified by Bob's secret `r`). Both views are
witnessed by `csidh_correctness`.
-/
noncomputable def ddhRealDist
    [Group G] [CommGroupAction G X] [Fintype G]
    (bp : X) : PMF (X × X × X) :=
  (uniformPMF G).bind (fun sk =>
    (uniformPMF G).map (fun r => (sk • bp, r • bp, sk • (r • bp))))

/--
**DDH random distribution.** Sample `sk, r, t ←$ G` uniformly and
independently; output the triple `(sk • bp, r • bp, t • bp)`. The third
coordinate is a fresh uniform-random orbit element of `bp`, *independent*
of the first two coordinates.
-/
noncomputable def ddhRandomDist
    [Group G] [CommGroupAction G X] [Fintype G]
    (bp : X) : PMF (X × X × X) :=
  (uniformPMF G).bind (fun sk =>
    (uniformPMF G).bind (fun r =>
      (uniformPMF G).map (fun t => (sk • bp, r • bp, t • bp))))

-- ============================================================================
-- WU-1.1b — IsCommActionDDHHard Prop definition
-- ============================================================================

/--
**Decisional Diffie–Hellman hardness for a commutative group action.**

For a commutative group action `G ↷ X` with basepoint `bp : X`, no Boolean
distinguisher `D : X × X × X → Bool` distinguishes the real DDH triple
distribution from the random DDH triple distribution with advantage greater
than `ε`.

**Cryptographic interpretation.** This is the standard DDH assumption
adapted to commutative actions, the foundational hardness assumption
underlying ElGamal-style PKE. For `(ZMod p)ˣ ↷ ZMod p`, this reduces to
the standard finite-cyclic-group DDH; for the CSIDH ideal-class-group
action on supersingular elliptic curves, this is the "commutative
Supersingular Isogeny DH" assumption (CSIDH security target).

**Why this Prop is research-scope.** DDH is a *believed-hard* problem in
cryptographic theory, not a provable mathematical statement. No
unconditional discharge is possible inside Lean for any concrete
commutative action; R-11 captures the assumption as a `Prop` that
downstream theorems carry as an explicit hypothesis (matching the
`OIA`/`KEMOIA`/`ConcreteOIA`/`IsPRF` patterns established by earlier
workstreams).

**Why a Boolean distinguisher quantifier.** The Prop quantifies over **all**
`D : X × X × X → Bool`, not just PPT-computable ones. This is the standard
"information-theoretic" shape; the cryptographic content is the
unprovable-inside-Lean assumption that no PPT D achieves more than ε.
Inhabited at `ε = 1` by `IsCommActionDDHHard.le_one` (every advantage is
`≤ 1`); ε < 1 discharge for any concrete action is research-scope.

**Bound type `ε : ℝ`.** Matching the `ConcreteOIA` / `IsPRF` convention
(post-Workstream-R-05-refinement). Negative `ε` makes the Prop unsatisfiable
(advantage is non-negative); `ε = 0` corresponds to perfect indistinguishability;
`ε ∈ [0, 1]` is the meaningful range; `ε ≥ 1` is trivially satisfiable via
`advantage_le_one`.
-/
def IsCommActionDDHHard
    [Group G] [CommGroupAction G X] [Fintype G] [DecidableEq X]
    (bp : X) (ε : ℝ) : Prop :=
  ∀ (D : X × X × X → Bool),
    advantage D (ddhRealDist (G := G) bp) (ddhRandomDist (G := G) bp) ≤ ε

-- ============================================================================
-- WU-1.2 — Monotonicity + trivial 1-bound
-- ============================================================================

/--
**Monotonicity in `ε`.** If a basepoint is `ε₁`-DDH-hard and `ε₁ ≤ ε₂`, it is
also `ε₂`-DDH-hard. Trivial transitivity in `ℝ`.
-/
theorem IsCommActionDDHHard.mono
    {G : Type*} [Group G] [CommGroupAction G X] [Fintype G] [DecidableEq X]
    {bp : X} {ε₁ ε₂ : ℝ}
    (h : IsCommActionDDHHard (G := G) bp ε₁) (hε : ε₁ ≤ ε₂) :
    IsCommActionDDHHard (G := G) bp ε₂ :=
  fun D => (h D).trans hε

/--
**Trivial `1`-bound.** Every basepoint is `1`-DDH-hard: distinguishing
advantage is always at most `1` by `advantage_le_one`. This is the
satisfiability anchor for the predicate; meaningful cryptographic content
appears at `ε < 1`.
-/
theorem IsCommActionDDHHard.le_one
    {G : Type*} [Group G] [CommGroupAction G X] [Fintype G] [DecidableEq X]
    (bp : X) :
    IsCommActionDDHHard (G := G) bp 1 :=
  fun _ => advantage_le_one _ _ _

-- ============================================================================
-- WU-1.3 — CommPKEAdversary structure
-- ============================================================================

/--
**IND-CPA / ROR-CPA adversary against `CommOrbitPKE`.**

The adversary is a single Boolean function `guess : X × X × X → Bool` that
takes the IND-CPA challenge view `(publicKey, ciphertext, key)` and returns
a guess for whether the third coordinate is the *real* shared secret
(returns `true`) or a *random* one (returns `false`).

**Why a curried function rather than a structure with multiple fields.**
The minimal IND-CPA adversary against ROR-CPA-CommOrbitPKE only needs to
see the challenge tuple; there is no oracle, no adaptive query, and no
chosen-message attack pool because `CommOrbitPKE` is a KEM (encapsulates
shared secrets, not arbitrary plaintexts). The single-function form
matches the existing `KEMAdversary` shape from `Orbcrypt/KEM/Security.lean`.

**Game asymmetry note.** The advantage `commPKEIndCPAAdvantage` is symmetric
in the convention: `|Pr[guess true | real] − Pr[guess true | random]|` is
invariant under flipping which output ("real"/"random") the adversary
predicts.
-/
structure CommPKEAdversary (G : Type*) (X : Type*)
    [Group G] [CommGroupAction G X] where
  /-- The adversary's Boolean guess function on `(publicKey, ciphertext, key)`
      triples. Returns `true` to guess "real key", `false` for "random". -/
  guess : X × X × X → Bool

-- ============================================================================
-- WU-2.1 — IND-CPA / ROR-CPA advantage definition
-- ============================================================================

/--
**IND-CPA / ROR-CPA advantage of an adversary against `CommOrbitPKE`.**

`commPKEIndCPAAdvantage bp A := advantage A.guess (ddhRealDist bp)
(ddhRandomDist bp)`.

The adversary's distinguishing advantage between the real-key branch
(`ddhRealDist`) and random-key branch (`ddhRandomDist`) of the ROR-CPA
game at basepoint `bp`, averaged over uniform-random secret-key sampling.

The IND-CPA challenge view in the real-key branch is the triple
`(pk, c, k_real) = (sk • bp, r • bp, sk • (r • bp))` for uniformly
sampled `sk, r ∈ G`; in the random-key branch it is
`(pk, c, k_rand) = (sk • bp, r • bp, t • bp)` for uniformly sampled
`sk, r, t ∈ G` (the third coordinate is a fresh uniform orbit element,
independent of `sk` and `r`). These are *literally* the DDH real and
random triple distributions at basepoint `bp`, so the advantage is the
DDH-distinguishing advantage at `A.guess` — see
`commPKEIndCPAAdvantage_eq_ddh_advantage`.

**Why average over `sk`.** Following the standard cryptographic IND-CPA
experiment convention, the secret key is sampled uniformly as part of the
game (the adversary is not given the secret key, only the public key and
challenge view). The advantage is the average over uniform `sk` of
`Pr[adversary outputs correct bit | sk]`. This is the canonical formulation
used in Boneh-Shoup, Katz-Lindell, and other standard references.

**Per-instance vs averaged formulation.** A *per-instance* advantage
formulation `commPKEIndCPAAdvantage_perPKE pke A` (taking a fixed
`pke : CommOrbitPKE G X` rather than just the basepoint) is **strictly
stronger** — it bounds the worst-case adversary advantage over all
choices of `sk`, including bad choices where the adversary may have
auxiliary information about `pke.secretKey`. The standard cryptographic
formulation marginalises over `sk` and is what we adopt here. Per-pke
bounds, when needed, can be derived by averaging arguments combined with
this theorem.

**Why a basepoint argument and not a `CommOrbitPKE`.** Marginalising over
`sk` means the public key `pk = sk • bp` is also random; the only fixed
parameter is the basepoint `bp`. Taking a `CommOrbitPKE pke` argument
would carry a fixed `pke.secretKey` that we then marginalise out, making
the structure data redundant.
-/
noncomputable def commPKEIndCPAAdvantage
    [Group G] [CommGroupAction G X] [Fintype G] [DecidableEq X]
    (bp : X) (A : CommPKEAdversary G X) : ℝ :=
  advantage A.guess (ddhRealDist (G := G) bp) (ddhRandomDist (G := G) bp)

-- ============================================================================
-- WU-2.2 — Advantage equality (IND-CPA = DDH advantage at A.guess)
-- ============================================================================

/--
**The IND-CPA advantage equals the DDH advantage at the adversary's guess
function.** Definitional `rfl` because `commPKEIndCPAAdvantage` is
*defined* to be the DDH advantage at the adversary's guess function on
the standard 3-tuple `(pk, c, k)` view. Exposed as a named theorem to make
the IND-CPA → DDH reduction visible at downstream call sites.

There are no game hops, no factor loss, and no advantage gap; the
reduction is exact equality.
-/
theorem commPKEIndCPAAdvantage_eq_ddh_advantage
    [Group G] [CommGroupAction G X] [Fintype G] [DecidableEq X]
    (bp : X) (A : CommPKEAdversary G X) :
    commPKEIndCPAAdvantage (G := G) bp A =
      advantage A.guess (ddhRealDist (G := G) bp) (ddhRandomDist (G := G) bp) :=
  rfl

-- ============================================================================
-- WU-2.5 — Headline reduction theorem
-- ============================================================================

/--
**Headline R-11 reduction.** The IND-CPA / ROR-CPA advantage of any adversary
against the commutative-action PKE at basepoint `bp` is at most `ε` whenever
the action is `ε`-DDH-hard at `bp`.

**Proof.** By `commPKEIndCPAAdvantage_eq_ddh_advantage`, the IND-CPA
advantage reduces to a DDH advantage with `A.guess` as the distinguisher.
The DDH-hardness hypothesis bounds this by `ε`.

**Cryptographic content.** Under the DDH assumption for the commutative
action `G ↷ X` at basepoint `bp`, the `CommOrbitPKE` construction is
ROR-CPA-secure: no adversary can distinguish a real shared key from a
random one with advantage exceeding `ε`. This is the textbook
ElGamal-IND-CPA-from-DDH reduction adapted to the commutative-action
setting.

**Tightness.** The reduction is tight (no factor loss): the IND-CPA
advantage equals the DDH advantage at `A.guess`. Equivalent to "tight
reduction with reduction factor 1" in cryptographic literature.
-/
theorem commPKE_indCPA_under_csidh_ddh_hardness
    [Group G] [CommGroupAction G X] [Fintype G] [DecidableEq X]
    (bp : X) (ε : ℝ) (hHard : IsCommActionDDHHard (G := G) bp ε)
    (A : CommPKEAdversary G X) :
    commPKEIndCPAAdvantage (G := G) bp A ≤ ε :=
  hHard A.guess

-- ============================================================================
-- WU-2.6 — Status disclosure
-- ============================================================================

/--
**Status disclosure for the framework.**

Returns a conjunction of the *unconditional* substantive content
delivered by this module, witnessed concretely on a parametric
`CommGroupAction G X` with basepoint `bp` and adversary `A`:

1. **DDH-hardness at the trivial bound `ε = 1` is unconditional** — every
   basepoint is `1`-DDH-hard via `IsCommActionDDHHard.le_one` (advantage
   is always `≤ 1` by `advantage_le_one`).
2. **The IND-CPA advantage equals the DDH advantage** at the adversary's
   guess function. This is the algebraic core of the reduction:
   `commPKEIndCPAAdvantage_eq_ddh_advantage` is a `rfl`-level identity
   that exposes the IND-CPA → DDH simulation as a definitional equality
   (no game hops, no factor loss).
3. **The IND-CPA / ROR-CPA reduction is unconditional in shape** — under
   any DDH-hardness `ε` (in particular `ε = 1`), every `CommPKEAdversary`
   has IND-CPA advantage at most `ε`. The trivial witness is the
   `ε = 1` case via `commPKE_indCPA_under_csidh_ddh_hardness`.

**What is *not* in the conjunction (research-scope R-11⁺):**

* Discharging `IsCommActionDDHHard` for any concrete commutative action
  (e.g., `(ZMod p)ˣ ↷ ZMod p`) at non-trivial `ε < 1` is the standard
  DDH cryptographic assumption, not provable inside Lean.
* Full CSIDH on supersingular elliptic curves over `F_p` requires class
  field theory + isogeny composition + Deuring's theorem in Mathlib
  (multi-year research-scope items).
* Active-attacker security (IND-CCA, AEAD-style integrity protection) is
  out of scope for this IND-CPA-only reduction.
* Multi-query / oracle-access security (IND-q-CPA, IND-CCA2) requires
  Lean-level oracle-game abstractions.

**Why a parametric witness over `bp` and `A`.** The conjunction is
quantified over the basepoint `bp : X` and adversary `A : CommPKEAdversary
G X` so the disclosure substantively exercises the framework's universally-
quantified content (`IsCommActionDDHHard.le_one` for *every* `bp`;
`commPKEIndCPAAdvantage_eq_ddh_advantage` and
`commPKE_indCPA_under_csidh_ddh_hardness` for *every* adversary). A
non-parametric `True := trivial` witness was rejected at deep-audit time
(2026-05-02) as theatrical: the named cryptographic content (DDH-hardness
+ algebraic equality + IND-CPA reduction) is the substantive theorem,
not the existence of the predicate.
-/
theorem commActionDDH_research_scope_disclosure
    [Group G] [CommGroupAction G X] [Fintype G] [DecidableEq X]
    (bp : X) (A : CommPKEAdversary G X) :
    IsCommActionDDHHard (G := G) bp 1 ∧
    commPKEIndCPAAdvantage (G := G) bp A =
      advantage A.guess (ddhRealDist (G := G) bp) (ddhRandomDist (G := G) bp) ∧
    commPKEIndCPAAdvantage (G := G) bp A ≤ 1 :=
  ⟨IsCommActionDDHHard.le_one bp,
   commPKEIndCPAAdvantage_eq_ddh_advantage bp A,
   commPKE_indCPA_under_csidh_ddh_hardness bp 1
     (IsCommActionDDHHard.le_one bp) A⟩

end Orbcrypt
