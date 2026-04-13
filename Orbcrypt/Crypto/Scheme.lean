import Orbcrypt.GroupAction.Basic
import Orbcrypt.GroupAction.Canonical

/-!
# Orbcrypt.Crypto.Scheme

Abstract Orbit Encryption (AOE) scheme syntax: `OrbitEncScheme` structure
with `encrypt` and `decrypt` operations. Formalizes DEVELOPMENT.md §4.1.

## Main definitions

* `Orbcrypt.OrbitEncScheme` — parameterized by group `G`, ciphertext space `X`,
  message space `M`. Bundles orbit representatives, distinctness proof, and
  canonical form.
* `Orbcrypt.encrypt` — `Enc(g, m) = g • reps(m)`, applying a group element to
  the orbit representative of the message.
* `Orbcrypt.decrypt` — `Dec(c) = find m such that canon(c) = canon(reps(m))`,
  reversing encryption via canonical form lookup.

## Design decisions

The scheme is deterministic: the group element `g` used for encryption is a
parameter, not sampled. Probabilistic sampling is abstracted by quantifying
over all `g ∈ G` in the security definitions (`Crypto/Security.lean`).

`M` is left abstract in the scheme structure. The `Fintype M` constraint is
added only to `decrypt`, where enumeration over all messages is required.

## References

* DEVELOPMENT.md §4.1 — AOE scheme definition
* formalization/phases/PHASE_3_CRYPTOGRAPHIC_DEFINITIONS.md — work units 3.1–3.3
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*} {M : Type*}

-- ============================================================================
-- Work Unit 3.1: Scheme Structure
-- ============================================================================

/--
An Abstract Orbit Encryption (AOE) scheme. Formalizes DEVELOPMENT.md §4.1.

The scheme is parameterized by:
- `G`: the secret group (key)
- `X`: the ciphertext space
- `M`: the message space

The scheme consists of:
- `reps`: a function mapping each message to its orbit representative
- `reps_distinct`: a proof that distinct messages map to distinct orbits
- `canonForm`: a canonical form function for the group action

The scheme is symmetric-key: `G` (the group) serves as the secret key.
Knowledge of `G` enables both encryption (via group action) and decryption
(via canonical form computation, which requires knowing the orbit structure
induced by `G`).
-/
structure OrbitEncScheme (G : Type*) (X : Type*) (M : Type*)
    [Group G] [MulAction G X] [DecidableEq X] where
  /-- Maps each message to its orbit representative. -/
  reps : M → X
  /-- Distinct messages have representatives in distinct orbits. -/
  reps_distinct : ∀ m₁ m₂ : M, m₁ ≠ m₂ →
    MulAction.orbit G (reps m₁) ≠ MulAction.orbit G (reps m₂)
  /-- The canonical form function used for decryption. -/
  canonForm : CanonicalForm G X

-- ============================================================================
-- Work Unit 3.2: Encrypt Function
-- ============================================================================

/--
Encryption: apply a group element to the orbit representative of the message.
`Enc(sk, m) = g • reps(m)` for a uniformly sampled `g ∈ G`.

In the formalization, `g` is a parameter (not sampled), since we work in a
deterministic setting. The probabilistic sampling is abstracted by quantifying
over all `g ∈ G` in the security definitions.
-/
def encrypt [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (g : G) (m : M) : X :=
  g • scheme.reps m

-- ============================================================================
-- Work Unit 3.3: Decrypt Function
-- ============================================================================

/--
Decryption: find the message whose representative has the same canonical form
as the ciphertext.

Returns `some m` if a matching message is found, `none` otherwise.
For honestly generated ciphertexts, this always returns `some m`
(proved in Phase 4, Theorem `correctness`).

The function searches over all messages in `M` (requiring `Fintype M`) and
compares canonical forms (requiring `DecidableEq X`). It uses `Exists.choose`
to extract the witness, making it `noncomputable` (relies on `Classical.choice`).
This is appropriate for a formalization where computational efficiency is
irrelevant — only logical correctness matters.
-/
noncomputable def decrypt [Group G] [MulAction G X] [DecidableEq X]
    [Fintype M] [DecidableEq M]
    (scheme : OrbitEncScheme G X M) (c : X) : Option M :=
  if h : ∃ m, scheme.canonForm.canon c = scheme.canonForm.canon (scheme.reps m)
  then some h.choose
  else none

end Orbcrypt
