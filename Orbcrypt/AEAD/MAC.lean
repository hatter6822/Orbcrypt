import Mathlib.Tactic

/-!
# Orbcrypt.AEAD.MAC

Message Authentication Code (MAC) abstraction for Orbcrypt's authenticated
encryption layer.

## Overview

A MAC is a triple `(tag, verify, correct)` parameterized by key, message, and
tag types. The `correct` field is a proof obligation: any instantiation must
prove that `verify` accepts tags produced by `tag`. This is the standard MAC
correctness property (also called "completeness").

## Key definitions

* `Orbcrypt.MAC` — generic MAC structure with `tag`, `verify`, and `correct`

## Design rationale

- `verify` returns `Bool` (not `Prop`) because verification must be
  computationally decidable. The `correct` field bridges to `Prop` via `= true`.
- Types `K`, `Msg`, `Tag` are fully abstract. In the AEAD composition, `K` will
  be the KEM's key type, `Msg` will be the ciphertext type `X`, and `Tag` will
  be an opaque authentication tag type.
- No security properties (EUF-CMA, SUF-CMA) are formalized on the MAC itself.
  Security is captured at the AEAD level via `INT_CTXT`, mirroring the project's
  pattern of stating security assumptions as hypotheses.

## References

* DEVELOPMENT.md §8 — authenticated encryption discussion
* docs/planning/PHASE_10_AUTHENTICATED_ENCRYPTION.md — work unit 10.1
-/

set_option autoImplicit false

namespace Orbcrypt

-- ============================================================================
-- Work Unit 10.1: MAC Abstraction
-- ============================================================================

/--
A Message Authentication Code (MAC).

Parameterized by key type `K`, message type `Msg`, and tag type `Tag`.
Bundles a tagging function, a verification function, and a proof that
honestly computed tags always pass verification.

**Fields:**
- `tag : K → Msg → Tag` — compute a MAC tag for a message under a key
- `verify : K → Msg → Tag → Bool` — verify a tag (decidable)
- `correct` — `verify k m (tag k m) = true` for all keys and messages

**Example usage:** In the AEAD composition, `K` is the KEM's symmetric key
type, `Msg` is the ciphertext space `X`, and `Tag` is an opaque tag type.
-/
structure MAC (K : Type*) (Msg : Type*) (Tag : Type*) where
  /-- Compute a tag for a message under a key. -/
  tag : K → Msg → Tag
  /-- Verify a tag against a key and message. Returns `true` iff valid. -/
  verify : K → Msg → Tag → Bool
  /-- Correctness: `verify` accepts tags produced by `tag`.
      This is a proof obligation for any MAC instantiation. -/
  correct : ∀ (k : K) (m : Msg), verify k m (tag k m) = true

end Orbcrypt
