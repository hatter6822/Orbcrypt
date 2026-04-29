/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.Crypto.Scheme

/-!
# Orbcrypt.Crypto.Security

IND-CPA security game and advantage definition: `Adversary` structure,
`hasAdvantage`, and `IsSecure` predicate. Formalizes DEVELOPMENT.md §4.3.

## Main definitions

* `Orbcrypt.Adversary` — a deterministic adversary for the IND-1-CPA game,
  consisting of a `choose` function (picks two challenge messages) and a
  `guess` function (outputs a bit given a challenge ciphertext).
* `Orbcrypt.hasAdvantage` — an adversary has advantage if there exist group
  elements producing different guesses on encryptions of the two chosen
  messages.
* `Orbcrypt.IsSecure` — a scheme is IND-1-CPA secure if no adversary has
  advantage.
* `Orbcrypt.hasAdvantageDistinct` — distinct-challenge advantage variant
  (audit F-02): requires `m₀ ≠ m₁` in addition to the guess-separation
  witness. Matches the classical IND-1-CPA game, where the challenger
  rejects a collision choice `(m, m)` before sampling.
* `Orbcrypt.IsSecureDistinct` — classical IND-1-CPA security predicate
  (audit F-02): no adversary has `hasAdvantageDistinct`.

## Main results

* `Orbcrypt.isSecure_implies_isSecureDistinct` — the stronger uniform game
  `IsSecure` implies the classical distinct-challenge game `IsSecureDistinct`
  (audit F-02).
* `Orbcrypt.hasAdvantageDistinct_iff` — decomposition into distinctness
  conjunct and `hasAdvantage`; `Iff.rfl`-trivial but useful for rewriting
  in downstream proofs (audit F-02).

## Design decisions

The adversary is deterministic: its randomness is abstracted by quantifying
over all possible group elements in `hasAdvantage`. The adversary sees the
orbit representatives `reps : M → X` as public parameters but does NOT see
the secret group `G`.

This captures IND-1-CPA (single-query, no oracle). The full IND-CPA with
adaptive oracle queries (DEVELOPMENT.md §8.2) is beyond the current scope.

### Game asymmetry (audit F-02)

`Adversary.choose` is structurally unconstrained: it may return a collision
`(m, m)`. The headline `IsSecure` quantifies over *all* adversaries,
including the degenerate ones, and therefore requires the scheme to resist
even the ill-formed challenges that the classical IND-1-CPA challenger
would reject. `IsSecureDistinct` matches the literature game by quantifying
only over adversaries whose `choose` yields `m₀ ≠ m₁`.

The implication `IsSecure → IsSecureDistinct` is unconditional and proved
below; the reverse direction is false in general, since `IsSecure` can
detect collisions that `IsSecureDistinct` rules out.

## References

* DEVELOPMENT.md §4.3 — adversary model and IND-CPA game
* formalization/phases/PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md — work units 3.4–3.6
* docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md § 5 (Workstream B1) — F-02 resolution
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*} {M : Type*}

-- ============================================================================
-- Work Unit 3.4: Adversary Structure
-- ============================================================================

/--
A deterministic adversary for the IND-1-CPA game. Formalizes the adversary
model from DEVELOPMENT.md §4.3.

Since we work in a deterministic setting (no probability monad), the adversary
is a pair of pure functions:
- `choose`: given the public orbit representatives, select a challenge pair
- `guess`: given the representatives and a challenge ciphertext, output a bit

The probabilistic aspects (random coins for the adversary, random group element
for the challenger) are abstracted by quantifying over all possible values in
the `hasAdvantage` definition.

The adversary is parameterized by `X` (ciphertext space) and `M` (message
space) but NOT by `G` (the secret group). This models the fact that the
adversary does not know the secret key.
-/
structure Adversary (X : Type*) (M : Type*) where
  /-- Choose two challenge messages given the orbit representatives. -/
  choose : (M → X) → M × M
  /-- Guess which message was encrypted, given reps and the challenge ciphertext. -/
  guess : (M → X) → X → Bool

-- ============================================================================
-- Work Unit 3.5: 1-CPA Advantage Definition
-- ============================================================================

/--
An adversary "has advantage" if there exist group elements `g₀, g₁` such that
the adversary's guess differs on encryptions of its two chosen messages.

This is a deterministic abstraction of non-zero advantage in the probabilistic
IND-1-CPA game. In the probabilistic setting, advantage is:
  `|Pr[A(g • x_{m₀}) = 1] - Pr[A(g • x_{m₁}) = 1]| / 2`

The deterministic version captures the key idea: the adversary can produce
*some* distinguishing behavior between the two orbits. If no group elements
produce different guesses, then the adversary's guess function is "orbit-blind"
— it cannot tell which orbit a ciphertext came from, regardless of the specific
group element used. This corresponds to zero advantage in the probabilistic
game.
-/
def hasAdvantage [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) : Prop :=
  ∃ g₀ g₁ : G,
    A.guess scheme.reps (g₀ • scheme.reps (A.choose scheme.reps).1) ≠
    A.guess scheme.reps (g₁ • scheme.reps (A.choose scheme.reps).2)

-- ============================================================================
-- Work Unit 3.6: IND-1-CPA Security Definition
-- ============================================================================

/--
A scheme is IND-1-CPA secure if no adversary has advantage.

This is the deterministic analogue of: for all PPT adversaries `A`,
`Adv^{IND-1-CPA}_A(λ) ≤ negl(λ)`.

The quantification `∀ (A : Adversary X M)` ranges over ALL deterministic
adversaries — not just computationally bounded ones. This makes the definition
information-theoretically secure, which is appropriate for the algebraic setting.
Computational bounds would require a complexity-theoretic framework beyond the
current scope.

## Game asymmetry (audit F-02)

`Adversary.choose` is structurally unconstrained and may return `(m, m)`.
Because `IsSecure` quantifies over *all* adversaries, it demands security
even against the degenerate collision choice that the classical
IND-1-CPA challenger would reject. This makes `IsSecure` strictly stronger
than the classical game, which is captured by `IsSecureDistinct`. The
one-way implication `IsSecure → IsSecureDistinct` is proved by
`isSecure_implies_isSecureDistinct`.
-/
def IsSecure [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) : Prop :=
  ∀ (A : Adversary X M), ¬hasAdvantage scheme A

-- ============================================================================
-- Audit F-02 / Workstream B1: Distinct-challenge IND-1-CPA variant
-- ============================================================================

/--
Distinct-challenge IND-1-CPA advantage (audit F-02).

The classical IND-1-CPA game requires the adversary to submit two
*distinct* challenge messages `m₀ ≠ m₁`; the challenger rejects `(m, m)`
before sampling a bit. This predicate captures that game form by
conjoining a distinctness obligation with the existing guess-separation
witness from `hasAdvantage`.

Concretely: `A` has distinct-challenge advantage iff its `choose` yields
a distinct pair `(m₀, m₁)` with `m₀ ≠ m₁` *and* there exist group
elements `g₀, g₁` on which `A.guess` disagrees between
`g₀ • reps m₀` and `g₁ • reps m₁`.

Note the asymmetry versus `hasAdvantage`: the unconstrained form may
witness "advantage" even when `m₀ = m₁`, whereas this form cannot.
-/
def hasAdvantageDistinct [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) : Prop :=
  (A.choose scheme.reps).1 ≠ (A.choose scheme.reps).2 ∧
    ∃ g₀ g₁ : G,
      A.guess scheme.reps (g₀ • scheme.reps (A.choose scheme.reps).1) ≠
      A.guess scheme.reps (g₁ • scheme.reps (A.choose scheme.reps).2)

/--
Classical IND-1-CPA security predicate (audit F-02).

A scheme is distinct-challenge IND-1-CPA secure if no adversary achieves
`hasAdvantageDistinct`. This matches the game actually studied in the
literature: the challenger enforces `m₀ ≠ m₁` before sampling a random
bit and a random group element.

`IsSecureDistinct` is strictly weaker than `IsSecure`, because the
stronger game accepts the degenerate collision choice `(m, m)`.
`isSecure_implies_isSecureDistinct` proves the unconditional direction.
-/
def IsSecureDistinct [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) : Prop :=
  ∀ (A : Adversary X M), ¬hasAdvantageDistinct scheme A

/--
The stronger uniform-choice game implies the classical distinct-challenge
game (audit F-02).

Proof: a distinct-challenge adversary exhibits, by definition, a
`hasAdvantage` witness (the second conjunct is literally the existential
body of `hasAdvantage`). Hence if no adversary has `hasAdvantage`
(= `IsSecure`), none has `hasAdvantageDistinct` either.

The converse is false in general: `IsSecure` can detect collisions that
`IsSecureDistinct` rules out by its distinctness hypothesis, so a scheme
resisting distinct challenges might still leak on `(m, m)`.
-/
theorem isSecure_implies_isSecureDistinct [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) :
    IsSecure scheme → IsSecureDistinct scheme := by
  intro hSec A hAdv
  -- `hAdv.2` is exactly a `hasAdvantage` witness; feed it to `hSec`.
  exact hSec A hAdv.2

/--
Decomposition lemma: the distinct-challenge advantage is exactly the
conjunction of the distinctness obligation and the standard `hasAdvantage`
predicate (audit F-02 / Workstream B1).

This is `Iff.rfl` because `hasAdvantageDistinct`'s second conjunct
literally repeats `hasAdvantage`'s existential body. The lemma is
provided so consumers can rewrite a `hasAdvantageDistinct` hypothesis
into the cleaner two-part form without unfolding the definition.
-/
theorem hasAdvantageDistinct_iff [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M) :
    hasAdvantageDistinct scheme A ↔
      (A.choose scheme.reps).1 ≠ (A.choose scheme.reps).2 ∧
        hasAdvantage scheme A :=
  Iff.rfl

end Orbcrypt
