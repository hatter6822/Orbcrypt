import Orbcrypt.AEAD.MAC
import Orbcrypt.KEM.Syntax
import Orbcrypt.KEM.Encapsulate
import Orbcrypt.KEM.Correctness

/-!
# Orbcrypt.AEAD.AEAD

Authenticated Encryption with Associated Data (AEAD) for the Orbit KEM.

## Overview

Composes the `OrbitKEM` (Phase 7) with a `MAC` (work unit 10.1) following the
Encrypt-then-MAC paradigm (Bellare & Namprempre, 2000). Encapsulation produces
a (ciphertext, key, tag) triple; decapsulation verifies the tag before releasing
the key.

## Key definitions

* `Orbcrypt.AuthOrbitKEM` — authenticated KEM extending `OrbitKEM` with a MAC
* `Orbcrypt.authEncaps` — Encrypt-then-MAC encapsulation
* `Orbcrypt.authDecaps` — Verify-then-Decrypt decapsulation
* `Orbcrypt.aead_correctness` — `authDecaps` recovers the key from honest pairs
* `Orbcrypt.INT_CTXT` — ciphertext integrity: forgeries are always rejected

## Composition order

Encrypt-then-MAC (EtM) is the provably secure composition paradigm. The
alternatives (MAC-then-Encrypt, Encrypt-and-MAC) have known vulnerabilities
in certain settings.

## References

* docs/planning/PHASE_10_AUTHENTICATED_ENCRYPTION.md — work units 10.2–10.4
* KEM/Syntax.lean, KEM/Encapsulate.lean — base KEM infrastructure
-/

set_option autoImplicit false

namespace Orbcrypt

-- ============================================================================
-- Work Unit 10.2: AEAD Definition
-- ============================================================================

variable {G : Type*} {X : Type*} {K : Type*} {Tag : Type*}
  [Group G] [MulAction G X] [DecidableEq X]

/--
Authenticated Key Encapsulation Mechanism.

Composes an `OrbitKEM` with a MAC that authenticates ciphertexts under the
encapsulated key. The MAC's key type matches the KEM's key type `K`, and
the MAC's message type matches the ciphertext space `X`.

Uses explicit field inclusion rather than `extends` to avoid Lean 4 structure
inheritance issues with 4+ type parameters (Risk 2 mitigation from Phase 10
planning document).

**Fields:**
- `kem : OrbitKEM G X K` — the underlying (unauthenticated) KEM, providing
  `basePoint`, `canonForm`, and `keyDerive` via `akem.kem`
- `mac : MAC K X Tag` — MAC for ciphertext authentication
-/
structure AuthOrbitKEM (G : Type*) (X : Type*) (K : Type*) (Tag : Type*)
    [Group G] [MulAction G X] [DecidableEq X] where
  /-- The underlying (unauthenticated) KEM. -/
  kem : OrbitKEM G X K
  /-- MAC for authenticating ciphertexts under the encapsulated key. -/
  mac : MAC K X Tag

/--
Authenticated encapsulation (Encrypt-then-MAC).

1. Run `encaps` to get `(ciphertext, key)`.
2. Compute `tag = mac.tag key ciphertext`.
3. Return `(ciphertext, key, tag)`.

The caller uses the key with a DEM for actual message encryption, and
transmits the ciphertext and tag to the receiver.
-/
def authEncaps (akem : AuthOrbitKEM G X K Tag) (g : G) :
    X × K × Tag :=
  let (c, k) := encaps akem.kem g
  (c, k, akem.mac.tag k c)

/--
Authenticated decapsulation (Verify-then-Decrypt).

1. Recover the key via `decaps`.
2. Verify the tag: `mac.verify key ciphertext tag`.
3. If verification passes, return `some key`; otherwise return `none`.

Returning `Option K` forces callers to handle authentication failures
explicitly, preventing accidental use of unauthenticated data.
-/
def authDecaps (akem : AuthOrbitKEM G X K Tag)
    (c : X) (t : Tag) : Option K :=
  let k := decaps akem.kem c
  if akem.mac.verify k c t then some k else none

-- Simp lemmas for unfolding authEncaps/authDecaps in proofs

/-- Unfold the ciphertext component of authenticated encapsulation. -/
@[simp]
theorem authEncaps_fst (akem : AuthOrbitKEM G X K Tag) (g : G) :
    (authEncaps akem g).1 = (encaps akem.kem g).1 := rfl

/-- Unfold the key component of authenticated encapsulation. -/
@[simp]
theorem authEncaps_snd_fst (akem : AuthOrbitKEM G X K Tag) (g : G) :
    (authEncaps akem g).2.1 = (encaps akem.kem g).2 := rfl

/-- Unfold the tag component of authenticated encapsulation. -/
@[simp]
theorem authEncaps_snd_snd (akem : AuthOrbitKEM G X K Tag) (g : G) :
    (authEncaps akem g).2.2 =
      akem.mac.tag (encaps akem.kem g).2 (encaps akem.kem g).1 := rfl

-- ============================================================================
-- Work Unit 10.3: AEAD Correctness
-- ============================================================================

/--
**AEAD Correctness Theorem.** Authenticated decapsulation recovers the key
from honestly generated (ciphertext, tag) pairs.

**Proof strategy:**
1. Unfold `authEncaps` to get `c = g • basePoint`, `k = keyDerive(canon(c))`,
   and `t = mac.tag k c`.
2. In `authDecaps`, `decaps` recomputes `k' = keyDerive(canon(c))`.
3. By `kem_correctness`, `k' = k`.
4. The verification check becomes `mac.verify k c (mac.tag k c)`.
5. By `mac.correct`, this is `true`, so `authDecaps` returns `some k`.

**Axioms:** Only standard Lean axioms. No custom axioms, no placeholders.
-/
theorem aead_correctness (akem : AuthOrbitKEM G X K Tag) (g : G) :
    let (c, k, t) := authEncaps akem g
    authDecaps akem c t = some k := by
  -- Unfold definitions: authEncaps produces (c, k, t) where
  -- c = (encaps akem.kem g).1, k = (encaps akem.kem g).2,
  -- t = mac.tag k c
  simp only [authEncaps, authDecaps, encaps, decaps]
  -- The verify check reduces to mac.verify k c (mac.tag k c)
  -- which is true by mac.correct
  simp [akem.mac.correct]

-- ============================================================================
-- Work Unit 10.4: INT-CTXT Security Definition
-- ============================================================================

/--
**Ciphertext Integrity (INT-CTXT).**

No adversary can produce a valid (ciphertext, tag) pair that was not generated
by an honest encapsulation. Formally: if `(c, t)` does not match any honest
`authEncaps` output, then `authDecaps` rejects it (returns `none`).

**Design rationale:**
- **Single-encapsulation setting.** The adversary must forge without having
  seen any honest encapsulation that matches. This is existential unforgeability.
- **Universal quantifier over `G`.** The condition `∀ g, c ≠ ... ∨ t ≠ ...`
  says no group element produces a matching (ciphertext, tag) pair.
- **`= none` conclusion.** The forgery is rejected — decapsulation refuses
  to release a key for an unauthenticated ciphertext.

**Scope:** This captures integrity in the no-query setting. Multi-query
CCA extensions (with encapsulation/decapsulation oracles and query logs)
are future work (Phase 12+).
-/
def INT_CTXT (akem : AuthOrbitKEM G X K Tag) : Prop :=
  ∀ (c : X) (t : Tag),
    (∀ g : G, c ≠ (authEncaps akem g).1 ∨
              t ≠ (authEncaps akem g).2.2) →
    authDecaps akem c t = none

end Orbcrypt
