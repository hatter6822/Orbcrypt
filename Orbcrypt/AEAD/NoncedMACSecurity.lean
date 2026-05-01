/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Field.ZMod
import Mathlib.Data.Nat.Prime.Basic
import Orbcrypt.AEAD.NoncedMAC
import Orbcrypt.AEAD.CarterWegmanMAC
import Orbcrypt.AEAD.BitstringPolynomialMAC
import Orbcrypt.Probability.UniversalHash

/-!
# Orbcrypt.AEAD.NoncedMACSecurity

Wegman–Carter 1981 §3 nonce-MAC: concrete specialisations and the
Q-time SUF-CMA security framework.

## Overview

This module specialises the abstract `NoncedMAC` framework (from
`Orbcrypt/AEAD/NoncedMAC.lean`) to two concrete hash families:
* `nonceCarterWegmanMAC p` — Carter–Wegman linear hash over `ZMod p`
  with a truly-random oracle PRF.
* `nonceBitstringPolynomialMAC p n` — bitstring polynomial-evaluation
  hash with a truly-random oracle PRF.

Both specialisations use the **truly-random oracle PRF**
(`idealRandomOraclePRF`), which is provably `0`-PRF
(`idealRandomOraclePRF_isPRF`). The hash families inherit their
ε-AXU bounds from the existing R-08 / R-13⁺ landings:
* `carterWegmanHash_isEpsilonAXU` — `(1/p)`-AXU.
* `bitstringPolynomialHash_isEpsilonAXU` — `(n/p)`-AXU.

## Main definitions

* `Orbcrypt.nonceCarterWegmanMAC` — the Carter–Wegman nonced MAC
  over `ZMod p × Nonce → ZMod p`.
* `Orbcrypt.nonceBitstringPolynomialMAC` — the bitstring-polynomial
  nonced MAC over `ZMod p × Nonce → ZMod p`.
* `Orbcrypt.IsNoncedQtimeSUFCMABoundShape` — the standard Wegman–
  Carter 1981 §3 SUF-CMA bound shape, captured as a research-scope
  predicate. Inhabited at `ε = 1` by the trivial
  `IsNoncedQtimeSUFCMASecure.le_one` bound; the substantive
  `Q · ε_h + ε_p + 1/|Tag|` shape is research-scope (R-05⁺).

## Main results

* `Orbcrypt.nonceCarterWegmanMAC_hash` /
  `Orbcrypt.nonceCarterWegmanMAC_prf` — structural simp lemmas.
* `Orbcrypt.nonceCarterWegmanMAC_isPRF` — the truly-random oracle
  composed with the Carter–Wegman hash is `0`-PRF.
* `Orbcrypt.nonceCarterWegmanMAC_isEpsilonAXU` — the hash is
  `(1/p)`-AXU.
* `Orbcrypt.nonceBitstringPolynomialMAC_isPRF` — `0`-PRF.
* `Orbcrypt.nonceBitstringPolynomialMAC_isEpsilonAXU` — `(n/p)`-AXU.
* `Orbcrypt.r05_research_scope_disclosure` — the explicit status
  disclosure: what is and is not proved unconditionally for R-05.

## Cryptographic content (Wegman–Carter 1981 §3)

Let `mac : NoncedMAC K_h K_p Nonce Msg Tag` with hash family
ε_h-AXU and PRF family ε_p-PRF. Then for every Q-time non-adaptive
nonce-respecting adversary `A`:
```
noncedForgeryAdvantage_Qtime mac A ≤ Q · ε_h + ε_p + 1/|Tag|
```

**Proof sketch (Wegman–Carter 1981 §3; formalisation tracked as
R-05⁺).**
1. **PRF→RO substitution (cost ε_p).** Replace `prf k_p` by a
   uniformly-random function `f : Nonce → Tag`. By IsPRF, the
   adversary's view changes by at most ε_p.
2. **Random-oracle analysis (cost Q · ε_h + 1/|Tag|).** In the
   ideal-oracle game, the win event decomposes by forge-nonce
   category:
   * **Fresh nonce branch:** `f(n_*)` is uniformly independent of
     the adversary's view; `Pr[t_* = h(k_h, m_*) + f(n_*)] =
     1/|Tag|`.
   * **Reused-nonce branch (n_* = n_i):** The win condition
     reduces to `h(k_h, m_*) − h(k_h, m_i) = t_* − tag_i` with
     `m_* ≠ m_i` (by SUF-CMA freshness). By ε_h-AXU at distinct
     messages, the probability is at most ε_h. Sum over Q
     possible reuse indices: `Q · ε_h`.
3. **Total: `Q · ε_h + ε_p + 1/|Tag|`.**

## Cryptographic interpretation at the truly-random oracle

At `prf := idealRandomOraclePRF`, the IsPRF advantage is `0` (the two
distributions coincide; cf. `idealRandomOraclePRF_isPRF`). The
Q-time SUF-CMA bound therefore simplifies to `Q · ε_h + 1/|Tag|`.

For `nonceCarterWegmanMAC p` (with ε_h = 1/p) at the ideal oracle,
this is `Q/p + 1/p = (Q+1)/p` — quantitatively *better* than the
nonce-free MAC's Q-time NEGATIVE result (which has advantage `1`
at `Q ≥ 2`).

## Research-scope status (R-05⁺)

The headline reduction theorem `noncedMAC_isQtimeSUFCMASecure_of_isAXU_and_isPRF`
is a **research-scope obligation** (R-05⁺) at the time of this
landing. The cryptographic content is the standard Wegman–Carter
1981 §3 analysis (well-established in the cryptographic literature);
the Lean formalisation is a multi-day undertaking (per
`docs/planning/PLAN_R_05_11_15.md` § R-05 Phase 3, budgeted at 9
sub-units / ~280 LOC / ~4.5 days). This module provides the
**framework structures** (concrete `NoncedMAC` instances, IsPRF +
IsEpsilonAXU non-vacuity witnesses, structural simp lemmas) so that
when the formal proof of the bound lands as a follow-up workstream,
its consumer-facing API is already in place.

In the interim, consumers requiring a Q-time SUF-CMA bound can use:
* `IsNoncedQtimeSUFCMASecure.le_one mac` — the trivial `≤ 1` bound,
  unconditionally true; matches the `IsEpsilonUniversal.le_one`
  satisfiability anchor pattern.
* `nonceCarterWegmanMAC_isPRF` + `nonceCarterWegmanMAC_isEpsilonAXU`
  — the *hypotheses* for the headline reduction; once the headline
  reduction theorem lands, callers can compose these to derive the
  concrete bound.

## Compatibility note (post-Workstream-A finding V1-7 / D4 / I-08)

Like the underlying `carterWegmanMAC`, the `nonceCarterWegmanMAC` /
`nonceBitstringPolynomialMAC` constructions are typed at message
spaces `ZMod p` and `Bitstring n` respectively, and tag space
`ZMod p`. Composing with HGOE's `Bitstring n` ciphertext-as-message
pipeline requires the same `Bitstring n → ZMod p` adapter discussed
in `Orbcrypt/AEAD/CarterWegmanMAC.lean` (research milestone R-13).

## References

* Wegman, M. N. & Carter, J. L. (1981). "New hash functions and their
  use in authentication and set equality." J. Comput. Syst. Sci. 22:
  265–279. (§3 introduces the nonce-MAC construction.)
* Bellare, M. & Rogaway, P. (2005). "Random Oracles in a Universe
  with Imperfect Hash Functions." (Random-oracle analysis.)
* docs/planning/PLAN_R_05_11_15.md § R-05 — research-scope
  discharge plan.
-/

set_option autoImplicit false

namespace Orbcrypt

open PMF ENNReal

-- ============================================================================
-- Layer 1 — Concrete specialisations of NoncedMAC
-- ============================================================================

/--
**Carter–Wegman nonced MAC.** Composes `carterWegmanHash p` with the
truly-random-oracle PRF on `Nonce → ZMod p`-valued keys. The hash
inherits its `(1/p)`-AXU bound from `carterWegmanHash_isEpsilonAXU`;
the truly-random oracle is `0`-PRF (`idealRandomOraclePRF_isPRF`).

**Type signature.**
* Hash key type: `ZMod p × ZMod p` (the standard Carter–Wegman key
  space).
* PRF key type: `Nonce → ZMod p` (the truly-random oracle's "key"
  is the function itself).
* Nonce type: arbitrary `Nonce` parameter (must be `[Fintype]
  [DecidableEq]` for the IsPRF / IsNoncedQtimeSUFCMASecure proofs).
* Message type: `ZMod p`.
* Tag type: `ZMod p`.

The Q-time SUF-CMA bound at the truly-random oracle (per the
research-scope-tracked headline reduction) is `(Q + 1) / p`.
-/
def nonceCarterWegmanMAC (p : ℕ) [Fact (Nat.Prime p)] (Nonce : Type*) :
    NoncedMAC (ZMod p × ZMod p) (Nonce → ZMod p) Nonce (ZMod p) (ZMod p) where
  hash := carterWegmanHash p
  prf  := idealRandomOraclePRF Nonce (ZMod p)

/--
**Bitstring-polynomial nonced MAC.** Composes
`bitstringPolynomialHash p n` (a polynomial-evaluation hash on
`Bitstring n`) with the truly-random-oracle PRF on `Nonce →
ZMod p`-valued keys. The hash inherits its `(n/p)`-AXU bound from
`bitstringPolynomialHash_isEpsilonAXU`; the truly-random oracle is
`0`-PRF.

**Type signature.**
* Hash key type: `ZMod p × ZMod p`.
* PRF key type: `Nonce → ZMod p`.
* Nonce type: `Nonce`.
* Message type: `Bitstring n`.
* Tag type: `ZMod p`.

The Q-time SUF-CMA bound at the truly-random oracle is
`(Q · n + 1) / p`.
-/
def nonceBitstringPolynomialMAC (p n : ℕ) [Fact (Nat.Prime p)]
    (Nonce : Type*) :
    NoncedMAC (ZMod p × ZMod p) (Nonce → ZMod p) Nonce (Bitstring n) (ZMod p) where
  hash := bitstringPolynomialHash p n
  prf  := idealRandomOraclePRF Nonce (ZMod p)

-- ============================================================================
-- Layer 2 — Structural simp lemmas
-- ============================================================================

/-- The hash field of `nonceCarterWegmanMAC` is `carterWegmanHash p`.
Reduction lemma for downstream proofs that need to expose the
underlying hash family. -/
@[simp] theorem nonceCarterWegmanMAC_hash (p : ℕ) [Fact (Nat.Prime p)]
    (Nonce : Type*) :
    (nonceCarterWegmanMAC p Nonce).hash = carterWegmanHash p := rfl

/-- The PRF field of `nonceCarterWegmanMAC` is the truly-random-
oracle `idealRandomOraclePRF`. -/
@[simp] theorem nonceCarterWegmanMAC_prf (p : ℕ) [Fact (Nat.Prime p)]
    (Nonce : Type*) :
    (nonceCarterWegmanMAC p Nonce).prf = idealRandomOraclePRF Nonce (ZMod p) :=
  rfl

/-- The hash field of `nonceBitstringPolynomialMAC` is
`bitstringPolynomialHash p n`. -/
@[simp] theorem nonceBitstringPolynomialMAC_hash (p n : ℕ)
    [Fact (Nat.Prime p)] (Nonce : Type*) :
    (nonceBitstringPolynomialMAC p n Nonce).hash =
      bitstringPolynomialHash p n := rfl

/-- The PRF field of `nonceBitstringPolynomialMAC` is
`idealRandomOraclePRF`. -/
@[simp] theorem nonceBitstringPolynomialMAC_prf (p n : ℕ)
    [Fact (Nat.Prime p)] (Nonce : Type*) :
    (nonceBitstringPolynomialMAC p n Nonce).prf =
      idealRandomOraclePRF Nonce (ZMod p) := rfl

-- ============================================================================
-- Layer 3 — IsPRF non-vacuity (truly-random oracle composed with hash)
-- ============================================================================

/--
The PRF component of `nonceCarterWegmanMAC` is a `0`-PRF. Direct
application of `idealRandomOraclePRF_isPRF` to the truly-random
oracle on `Nonce → ZMod p`.

**Cryptographic interpretation.** The truly-random-oracle PRF is
the canonical idealisation: each query returns an independent
uniform tag. Concrete cryptographic PRFs (HMAC, AES-CTR) are
conjectured to be indistinguishable from this with negligible ε,
but their concrete bounds are not provable inside Lean (research-
scope follow-ups R-05⁺-2 in `docs/planning/PLAN_R_05_11_15.md`).
-/
theorem nonceCarterWegmanMAC_isPRF (p : ℕ) [Fact (Nat.Prime p)]
    (Nonce : Type*) [Fintype Nonce] [DecidableEq Nonce] :
    IsPRF (nonceCarterWegmanMAC p Nonce).prf 0 := by
  rw [nonceCarterWegmanMAC_prf]
  exact idealRandomOraclePRF_isPRF

/--
The PRF component of `nonceBitstringPolynomialMAC` is a `0`-PRF.
Same proof as `nonceCarterWegmanMAC_isPRF` — both specialisations
use the truly-random oracle on `Nonce → ZMod p`.
-/
theorem nonceBitstringPolynomialMAC_isPRF (p n : ℕ) [Fact (Nat.Prime p)]
    (Nonce : Type*) [Fintype Nonce] [DecidableEq Nonce] :
    IsPRF (nonceBitstringPolynomialMAC p n Nonce).prf 0 := by
  rw [nonceBitstringPolynomialMAC_prf]
  exact idealRandomOraclePRF_isPRF

-- ============================================================================
-- Layer 4 — IsEpsilonAXU non-vacuity (concrete hash families)
-- ============================================================================

/--
The hash component of `nonceCarterWegmanMAC` is `(1/p)`-AXU.
Direct re-export of `carterWegmanHash_isEpsilonAXU` from the
existing R-08 landing.
-/
theorem nonceCarterWegmanMAC_isEpsilonAXU (p : ℕ) [Fact (Nat.Prime p)]
    (Nonce : Type*) :
    IsEpsilonAXU (nonceCarterWegmanMAC p Nonce).hash
      ((1 : ℝ≥0∞) / (p : ℝ≥0∞)) := by
  rw [nonceCarterWegmanMAC_hash]
  exact carterWegmanHash_isEpsilonAXU p

/--
The hash component of `nonceBitstringPolynomialMAC` is `(n/p)`-AXU.
Direct re-export of `bitstringPolynomialHash_isEpsilonAXU` from the
existing R-13⁺ landing.
-/
theorem nonceBitstringPolynomialMAC_isEpsilonAXU (p n : ℕ)
    [Fact (Nat.Prime p)] (Nonce : Type*) :
    IsEpsilonAXU (nonceBitstringPolynomialMAC p n Nonce).hash
      ((n : ℝ≥0∞) / (p : ℝ≥0∞)) := by
  rw [nonceBitstringPolynomialMAC_hash]
  exact bitstringPolynomialHash_isEpsilonAXU p n

-- ============================================================================
-- Layer 5 — Trivial Q-time SUF-CMA bound (sentinel)
-- ============================================================================

/--
**Trivial Q-time SUF-CMA bound for `nonceCarterWegmanMAC`.** The
nonced Carter–Wegman MAC is `1`-Q-time-SUF-CMA-secure for every Q
and every nonce type — matching the universal `_le_one` satisfiability
anchor pattern (cf. `IsEpsilonUniversal.le_one`,
`IsNoncedQtimeSUFCMASecure.le_one`). The substantive bound
`(Q + 1)/p` (or, more generally, `Q · ε_h + ε_p + 1/|Tag|`) is
research-scope follow-up R-05⁺.
-/
theorem nonceCarterWegmanMAC_isNoncedQtimeSUFCMASecure_le_one
    (p : ℕ) [Fact (Nat.Prime p)] (Nonce : Type*)
    [Fintype Nonce] [Nonempty Nonce]
    [DecidableEq Nonce] {Q : ℕ} :
    IsNoncedQtimeSUFCMASecure (Q := Q) (nonceCarterWegmanMAC p Nonce) 1 :=
  IsNoncedQtimeSUFCMASecure.le_one _

/--
**Trivial Q-time SUF-CMA bound for `nonceBitstringPolynomialMAC`.**
Same structural sentinel as `nonceCarterWegmanMAC_isNoncedQtimeSUFCMASecure_le_one`.
The substantive bound `(Q · n + 1)/p` is research-scope.
-/
theorem nonceBitstringPolynomialMAC_isNoncedQtimeSUFCMASecure_le_one
    (p n : ℕ) [Fact (Nat.Prime p)] (Nonce : Type*)
    [Fintype Nonce] [Nonempty Nonce]
    [DecidableEq Nonce] {Q : ℕ} :
    IsNoncedQtimeSUFCMASecure (Q := Q)
      (nonceBitstringPolynomialMAC p n Nonce) 1 :=
  IsNoncedQtimeSUFCMASecure.le_one _

-- ============================================================================
-- Layer 6 — R-05 status disclosure
-- ============================================================================

/--
**R-05 research-scope status disclosure.** The R-05 framework
captures the Wegman–Carter 1981 §3 nonced-MAC construction in Lean
4 with the following posture:

**Unconditional (machine-checked).**
* `NoncedMAC` structure + `tag` / `verify` definitions.
* `NoncedMultiQueryMACAdversary` structure + `forges` Bool function.
* `noncedForgeryAdvantage_Qtime` PMF wrapper.
* `IsNoncedQtimeSUFCMASecure` Prop predicate.
* `IsPRF` Prop predicate (function-level formulation).
* `idealRandomOraclePRF` definition.
* `idealRandomOraclePRF_isPRF` — the truly-random oracle is `0`-PRF.
* `nonceCarterWegmanMAC` and `nonceBitstringPolynomialMAC`
  definitions.
* `nonceCarterWegmanMAC_isPRF` /
  `nonceBitstringPolynomialMAC_isPRF` — both specialisations have
  `0`-PRF prf components (the truly-random oracle).
* `nonceCarterWegmanMAC_isEpsilonAXU` /
  `nonceBitstringPolynomialMAC_isEpsilonAXU` — `(1/p)`-AXU and
  `(n/p)`-AXU respectively.
* Trivial `_le_one` bounds for both specialisations.

**Research-scope (R-05⁺).**
* `noncedMAC_isQtimeSUFCMASecure_of_isAXU_and_isPRF` — the
  headline reduction theorem `IsNoncedQtimeSUFCMASecure mac
  (Q · ε_h + ε_p + 1/|Tag|)` under (a) ε_h-AXU on hash and
  (b) ε_p-PRF on prf. The cryptographic content is the standard
  Wegman–Carter 1981 §3 analysis (well-established in the
  cryptographic literature); the Lean formalisation is a multi-
  day undertaking budgeted at 9 sub-units / ~280 LOC / ~4.5 days
  (per `docs/planning/PLAN_R_05_11_15.md` § R-05 Phase 3).
* `ideal_nonceCarterWegmanMAC_isQtimeSUFCMASecure` — the concrete
  `(Q + 1)/p` bound at the truly-random oracle. Conditional on
  the headline reduction; ε_p = 0 by `nonceCarterWegmanMAC_isPRF`.
* Concrete instantiations with non-ideal PRFs (HMAC, AES-CTR as
  PRF). Discharging `IsPRF` for these requires the corresponding
  cryptographic assumption (HMAC-PRF, AES-PRF) which is not
  provable inside Lean.
* Adaptive Q-time queries (full SUF-CMA-2 / oracle access).
  Requires Lean-level oracle-game abstractions.

The structural framework is sufficient for downstream consumers
to *state* the SUF-CMA bound (via the framework Props). When the
headline reduction lands as R-05⁺, its API will already be in
place at the consumer-facing types declared in this module.

The witness here is the conjunction of the unconditional pieces:
the `nonceCarterWegmanMAC` and `nonceBitstringPolynomialMAC`
constructions are inhabited (as Lean values), their PRF / AXU
hypotheses are met (with explicit ε), and the trivial `_le_one`
SUF-CMA bound is proved. -/
theorem r05_research_scope_disclosure (p : ℕ) [Fact (Nat.Prime p)] :
    IsPRF (nonceCarterWegmanMAC p (ZMod p)).prf 0 ∧
    IsEpsilonAXU (nonceCarterWegmanMAC p (ZMod p)).hash
      ((1 : ℝ≥0∞) / (p : ℝ≥0∞)) ∧
    IsNoncedQtimeSUFCMASecure (Q := 0) (nonceCarterWegmanMAC p (ZMod p)) 1 :=
  ⟨nonceCarterWegmanMAC_isPRF p (ZMod p),
   nonceCarterWegmanMAC_isEpsilonAXU p (ZMod p),
   nonceCarterWegmanMAC_isNoncedQtimeSUFCMASecure_le_one p (ZMod p)⟩

end Orbcrypt
