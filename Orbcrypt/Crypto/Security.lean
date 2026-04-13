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

## Design decisions

The adversary is deterministic: its randomness is abstracted by quantifying
over all possible group elements in `hasAdvantage`. The adversary sees the
orbit representatives `reps : M → X` as public parameters but does NOT see
the secret group `G`.

This captures IND-1-CPA (single-query, no oracle). The full IND-CPA with
adaptive oracle queries (DEVELOPMENT.md §8.2) is beyond the current scope.

## References

* DEVELOPMENT.md §4.3 — adversary model and IND-CPA game
* formalization/phases/PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md — work units 3.4–3.6
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
-/
def IsSecure [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) : Prop :=
  ∀ (A : Adversary X M), ¬hasAdvantage scheme A

end Orbcrypt
