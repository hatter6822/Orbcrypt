/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

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

* `Orbcrypt.MAC` — generic MAC structure with `tag`, `verify`, `correct`, and
  the `verify_inj` tag-uniqueness obligation

## Design rationale

- `verify` returns `Bool` (not `Prop`) because verification must be
  computationally decidable. The `correct` field bridges to `Prop` via `= true`.
- Types `K`, `Msg`, `Tag` are fully abstract. In the AEAD composition, `K` will
  be the KEM's key type, `Msg` will be the ciphertext type `X`, and `Tag` will
  be an opaque authentication tag type.
- `verify_inj` is the algebraic analogue of strong unforgeability (SUF-CMA) in
  the no-query setting: only the honestly-computed tag verifies. Without this
  property, `INT_CTXT` for the composed AuthOrbitKEM is unprovable (audit
  finding F-07).

## References

* DEVELOPMENT.md §8 — authenticated encryption discussion
* docs/planning/PHASE_10_AUTHENTICATED_ENCRYPTION.md — work unit 10.1
* docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md § 6 — Workstream C (F-07)
-/

set_option autoImplicit false

namespace Orbcrypt

-- ============================================================================
-- Work Unit 10.1: MAC Abstraction
-- ============================================================================

/--
A Message Authentication Code (MAC).

Parameterized by key type `K`, message type `Msg`, and tag type `Tag`.
Bundles a tagging function, a verification function, a proof that honestly
computed tags always pass verification, and a tag-uniqueness obligation
(the algebraic analogue of strong unforgeability).

**Fields:**
- `tag : K → Msg → Tag` — compute a MAC tag for a message under a key
- `verify : K → Msg → Tag → Bool` — verify a tag (decidable)
- `correct` — `verify k m (tag k m) = true` for all keys and messages
- `verify_inj` — only the honestly-computed tag verifies; this is the
  SUF-CMA-like uniqueness requirement that enables `INT_CTXT` proofs
  (audit finding F-07, Workstream C1).

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
  /-- Tag uniqueness: only the honestly-computed tag verifies.

      This is the algebraic analogue of strong unforgeability (SUF-CMA) in
      the no-query (information-theoretic) setting: whenever `verify k m t`
      accepts, `t` must be the honestly-computed tag `tag k m`. A MAC
      without this property cannot discharge `INT_CTXT` — an adversary
      could forge arbitrary distinct tags that still verify.

      **Satisfiability.** Any MAC whose `verify` is definitionally
      `decide (t = tag k m)` (e.g., the deterministic universal-hash-style
      witness in `AEAD/CarterWegmanMAC.lean`) satisfies this by
      `of_decide_eq_true`. Randomised / MAC-then-hash constructions
      (HMAC, Poly1305) satisfy it information-theoretically once their
      collision probability is ruled out; modelling that correctly
      requires a probabilistic refinement (future work). -/
  verify_inj : ∀ (k : K) (m : Msg) (t : Tag),
    verify k m t = true → t = tag k m

-- ============================================================================
-- Generic `decide`-equality MAC template (relocated from CarterWegmanMAC
-- so MACSecurity can use it without a circular import).
-- ============================================================================

variable {K : Type*} {Msg : Type*} {Tag : Type*}

/--
A deterministic MAC constructed from any tagging function
`f : K → Msg → Tag`. Verification tests `t = f k m` by `decide`, which
discharges both the `correct` and `verify_inj` fields of `MAC`.

This is the canonical "simplest non-trivial MAC" and the template on
which `carterWegmanMAC` and `bitstringPolynomialMAC` are built: supply
a universal-hash function as `f`, and the ε-universal property of the
family (proved separately against `IsEpsilonUniversal`) is preserved
by the template.
-/
def deterministicTagMAC [DecidableEq Tag] (f : K → Msg → Tag) :
    MAC K Msg Tag where
  tag := f
  verify := fun k m t => decide (t = f k m)
  -- `decide (f k m = f k m) = true` holds by reflexivity of equality.
  correct := fun _ _ => decide_eq_true rfl
  -- `decide (t = f k m) = true` unfolds to `t = f k m`.
  verify_inj := fun _ _ _ hv => of_decide_eq_true hv

end Orbcrypt
