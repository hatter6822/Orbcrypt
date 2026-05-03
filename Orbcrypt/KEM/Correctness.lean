/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.KEM.Encapsulate

/-!
# Orbcrypt.KEM.Correctness

KEM correctness theorem: decapsulation recovers the encapsulated key.
`decaps(kem, (encaps kem g).1) = (encaps kem g).2` for all group elements `g`.

## Overview

This is simpler than the original `correctness` theorem in
`Theorems/Correctness.lean` because:
1. There is no `Option` type — the KEM always produces a key.
2. The proof reduces to definitional equality (`rfl`): both sides compute
   `keyDerive(canon(g • x₀))`.

## Main results

* `Orbcrypt.kem_correctness` — `decaps(encaps(g).1) = encaps(g).2`
* `Orbcrypt.toKEM_correct` — backward-compatible: correctness for KEM
  derived from an `OrbitEncScheme`

## References

* docs/dev_history/formalization/PRACTICAL_IMPROVEMENTS_PLAN.md — work unit 7.3
* Theorems/Correctness.lean — original AOE correctness theorem
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*} {K : Type*}

-- ============================================================================
-- Work Unit 7.3: KEM Correctness Theorem
-- ============================================================================

/--
**KEM Correctness Theorem.** Decapsulation recovers the encapsulated key.

For any group element `g`, the key recovered by `decaps` from the ciphertext
produced by `encaps` equals the key output by `encaps`.

**Proof:** Both sides reduce to `keyDerive(canon(g • basePoint))`:
- `decaps kem (encaps kem g).1` unfolds to `keyDerive(canon(g • basePoint))`
- `(encaps kem g).2` unfolds to `keyDerive(canon(g • basePoint))`
So the equality is `rfl` (definitional).

**Axioms:** None beyond standard Lean. `#print axioms kem_correctness` shows
only `propext`, `Quot.sound`, and `Classical.choice` at most.
-/
theorem kem_correctness [Group G] [MulAction G X] [DecidableEq X]
    (kem : OrbitKEM G X K) (g : G) :
    decaps kem (encaps kem g).1 = (encaps kem g).2 := by
  -- Both sides unfold to keyDerive(canon(g • basePoint))
  rfl

-- ============================================================================
-- Work Unit 7.7 (continued): Backward Compatibility Correctness
-- ============================================================================

/--
KEM correctness for a KEM derived from an `OrbitEncScheme`.
Direct application of `kem_correctness` to the bridge construction.
-/
theorem toKEM_correct {M : Type*}
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (m₀ : M) (kd : X → K) (g : G) :
    decaps (scheme.toKEM m₀ kd) (encaps (scheme.toKEM m₀ kd) g).1 =
    (encaps (scheme.toKEM m₀ kd) g).2 :=
  kem_correctness (scheme.toKEM m₀ kd) g

end Orbcrypt
