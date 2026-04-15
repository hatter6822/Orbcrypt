import Orbcrypt.GroupAction.Canonical
import Orbcrypt.Crypto.Scheme

/-!
# Orbcrypt.KEM.Syntax

Key Encapsulation Mechanism (KEM) syntax for Orbcrypt: `OrbitKEM` structure
definition and backward-compatibility bridge from `OrbitEncScheme`.

## Motivation

The original `OrbitEncScheme` requires storing |M| orbit representatives as
public parameters. For |M| = 2^128, this is infeasible. A KEM sidesteps this:
encapsulation produces a random orbit element and derives a symmetric key via
a hash. Actual message encryption is delegated to a standard DEM (e.g., AES-GCM).

## Main definitions

* `Orbcrypt.OrbitKEM` — KEM parameterized by group `G`, ciphertext space `X`,
  and key space `K`. Bundles a single base point, canonical form, and key
  derivation function.
* `Orbcrypt.OrbitEncScheme.toKEM` — backward-compatibility bridge converting
  any `OrbitEncScheme` to an `OrbitKEM` by fixing one message.

## References

* DEVELOPMENT.md §4.1 — AOE scheme definition (original architecture)
* formalization/PRACTICAL_IMPROVEMENTS_PLAN.md — Phase 7 (KEM Reformulation)
-/

namespace Orbcrypt

-- ============================================================================
-- Work Unit 7.1: OrbitKEM Structure
-- ============================================================================

/--
A Key Encapsulation Mechanism (KEM) based on orbit encryption.

Unlike `OrbitEncScheme` which stores one representative per message, the KEM
uses a single base point `x₀ ∈ X`. Encapsulation samples `g ∈ G`, computes
the ciphertext `c = g • x₀`, and derives a symmetric key from the canonical
form `keyDerive(canon(c))`. Decapsulation re-derives the key from `c`.

**Parameters:**
- `G`: the secret group (key)
- `X`: the ciphertext space (elements that the group acts on)
- `K`: the symmetric key space (output of key derivation)

**Design decisions:**
- Single base point instead of `reps : M → X` — the KEM produces one key
  per encapsulation; message encryption is handled by the DEM.
- `keyDerive : X → K` abstracts the hash function. In implementation, this
  would be SHA-3 or SHAKE applied to `canon(g • x₀)`.
- No `reps_distinct` field — there is only one orbit, so distinctness is
  trivially satisfied.
-/
structure OrbitKEM (G : Type*) (X : Type*) (K : Type*)
    [Group G] [MulAction G X] [DecidableEq X] where
  /-- A single base point x₀ ∈ X. No message space needed. -/
  basePoint : X
  /-- Canonical form for orbit identification. -/
  canonForm : CanonicalForm G X
  /-- Key derivation: hash the canonical form to produce a symmetric key. -/
  keyDerive : X → K

-- ============================================================================
-- Work Unit 7.7: Backward Compatibility Bridge
-- ============================================================================

/--
Convert an `OrbitEncScheme` to an `OrbitKEM` by fixing a message `m₀` and
using its representative as the base point.

This bridge demonstrates that the KEM architecture generalizes the original
AOE scheme: any orbit encryption scheme can be viewed as a KEM that
encapsulates keys from a single chosen orbit.

**Parameters:**
- `scheme`: the original AOE scheme
- `m₀`: the message whose orbit representative becomes the KEM base point
- `kd`: key derivation function (abstracts the hash)
-/
def OrbitEncScheme.toKEM {G : Type*} {X : Type*} {M : Type*} {K : Type*}
    [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (m₀ : M) (kd : X → K) : OrbitKEM G X K where
  basePoint := scheme.reps m₀
  canonForm := scheme.canonForm
  keyDerive := kd

end Orbcrypt
