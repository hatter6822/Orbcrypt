/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.KEM.Syntax

/-!
# Orbcrypt.KEM.Encapsulate

Encapsulation and decapsulation functions for the Orbit KEM:
`encaps` samples a group element and produces a (ciphertext, key) pair;
`decaps` recovers the key from a ciphertext using the secret canonical form.

## Main definitions

* `Orbcrypt.encaps` — `encaps(kem, g) = (g • x₀, keyDerive(canon(g • x₀)))`
* `Orbcrypt.decaps` — `decaps(kem, c) = keyDerive(canon(c))`

## Key insight

Both `encaps` and `decaps` derive the key via `keyDerive(canon(·))`. Since
canonical form maps all orbit elements to the same representative, the derived
key is the same regardless of which group element `g` was used. This is what
makes decapsulation possible without knowing `g`.

## References

* docs/dev_history/formalization/PRACTICAL_IMPROVEMENTS_PLAN.md — work unit 7.2
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*} {K : Type*}

-- ============================================================================
-- Work Unit 7.2: Encapsulation and Decapsulation Functions
-- ============================================================================

/--
Encapsulation: sample `g ∈ G`, output `(ciphertext, shared key)`.

The ciphertext is `g • x₀` (a random element of the base point's orbit).
The shared key is derived by hashing the canonical form of the ciphertext:
`keyDerive(canon(g • x₀))`.

In the formalization, `g` is a parameter (not sampled), matching the
deterministic approach of `encrypt` in `Crypto/Scheme.lean`. Probabilistic
sampling is abstracted by quantifying over all `g ∈ G` in security definitions.
-/
def encaps [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (g : G) : X × K :=
  let c := g • kem.basePoint
  (c, kem.keyDerive (kem.canonForm.canon c))

/--
Decapsulation: recover the shared key from the ciphertext.

Applies the canonical form to the ciphertext and derives the key:
`keyDerive(canon(c))`. This recovers the same key as `encaps` because
canonical form is G-invariant: `canon(g • x₀) = canon(x₀)` for all `g`.

Unlike `decrypt` in `Crypto/Scheme.lean`, decapsulation is total (no `Option`)
— it always produces a key. There is no message to recover; the KEM only
establishes a shared secret.
-/
def decaps [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (c : X) : K :=
  kem.keyDerive (kem.canonForm.canon c)

-- Simp lemmas for unfolding encaps/decaps in proofs

/-- Unfold the ciphertext component of encapsulation. -/
@[simp]
theorem encaps_fst [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (g : G) :
    (encaps kem g).1 = g • kem.basePoint := rfl

/-- Unfold the key component of encapsulation. -/
@[simp]
theorem encaps_snd [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (g : G) :
    (encaps kem g).2 = kem.keyDerive (kem.canonForm.canon (g • kem.basePoint)) := rfl

/-- Unfold decapsulation. -/
@[simp]
theorem decaps_eq [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (c : X) :
    decaps kem c = kem.keyDerive (kem.canonForm.canon c) := rfl

end Orbcrypt
