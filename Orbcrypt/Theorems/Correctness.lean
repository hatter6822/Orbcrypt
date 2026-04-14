import Orbcrypt.Crypto.Scheme
import Orbcrypt.GroupAction.Invariant

/-!
# Orbcrypt.Theorems.Correctness

Correctness theorem: `decrypt(encrypt(g, m)) = some m` for all messages `m`
and group elements `g` used in encryption. Formalizes DEVELOPMENT.md §4.2.

## Overview

This module proves Headline Result #1 of the Orbcrypt formalization:
decryption perfectly inverts encryption. The proof proceeds in four steps:

1. **Encrypt-in-orbit** (4.1): the ciphertext `g • reps(m)` lies in the orbit
   of `reps(m)`.
2. **Canon-of-encrypt** (4.2): canonical form is preserved by encryption,
   i.e., `canon(g • reps(m)) = canon(reps(m))`.
3. **Decrypt uniqueness** (4.3–4.4): exactly one message satisfies the decrypt
   predicate for an honestly generated ciphertext.
4. **Assembly** (4.5): combining the above into the headline theorem.

## Main results

* `Orbcrypt.encrypt_mem_orbit` — ciphertext lies in the orbit of the representative
* `Orbcrypt.canon_encrypt` — canonical form of ciphertext equals canonical form
  of representative
* `Orbcrypt.decrypt_unique` — the message matching a ciphertext's canonical form
  is unique
* `Orbcrypt.correctness` — `decrypt(encrypt(g, m)) = some m`

## References

* DEVELOPMENT.md §4.2 — correctness proof
* formalization/phases/PHASE_4_CORE_THEOREMS.md — work units 4.1–4.5
-/

namespace Orbcrypt

variable {G : Type*} {X : Type*} {M : Type*}

-- ============================================================================
-- Work Unit 4.1: Encrypt-in-Orbit Lemma
-- ============================================================================

/-- The ciphertext lies in the orbit of the representative.
    Since `encrypt scheme g m = g • reps(m)`, applying a group element
    to a point yields a member of that point's orbit. -/
theorem encrypt_mem_orbit [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (g : G) (m : M) :
    encrypt scheme g m ∈ MulAction.orbit G (scheme.reps m) := by
  -- encrypt = g • reps m, which is in orbit G (reps m) by smul_mem_orbit
  unfold encrypt
  exact smul_mem_orbit g (scheme.reps m)

-- ============================================================================
-- Work Unit 4.2: Canon-of-Encrypt Lemma
-- ============================================================================

/-- Canonical form of a ciphertext equals canonical form of the representative.
    This follows from the G-invariance of canonical forms: since
    `encrypt scheme g m = g • reps(m)`, and canonical form satisfies
    `canon(g • x) = canon(x)`, we get `canon(encrypt g m) = canon(reps m)`.

    Two proof approaches are available:
    - Via `canon_eq_of_mem_orbit` (unit 2.6): since encrypt is in the orbit,
      elements in the same orbit have the same canonical form.
    - Via `canonical_isGInvariant` (unit 2.11): canonical form is G-invariant,
      so `canon(g • x) = canon(x)` directly. (Used here as it is more direct.) -/
theorem canon_encrypt [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (g : G) (m : M) :
    scheme.canonForm.canon (encrypt scheme g m) =
    scheme.canonForm.canon (scheme.reps m) := by
  -- Strategy: unfold encrypt and apply G-invariance of canonical form
  unfold encrypt
  exact canonical_isGInvariant scheme.canonForm g (scheme.reps m)

-- ============================================================================
-- Work Unit 4.3–4.4: Decrypt Uniqueness Infrastructure
-- ============================================================================

/-- If a message m' has the same canonical form as an honestly generated
    ciphertext for message m, then m' must equal m.

    **Proof strategy:**
    1. From the hypothesis, `canon(reps m') = canon(reps m)` (via canon_encrypt).
    2. By `canon_eq_implies_orbit_eq`, the orbits of `reps m'` and `reps m` are equal.
    3. By contrapositive of `reps_distinct`, equal orbits imply equal messages. -/
theorem decrypt_unique [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (g : G) (m m' : M)
    (h : scheme.canonForm.canon (encrypt scheme g m) =
         scheme.canonForm.canon (scheme.reps m')) :
    m' = m := by
  -- Step 1: Derive canon(reps m') = canon(reps m)
  have h_canons : scheme.canonForm.canon (scheme.reps m') =
      scheme.canonForm.canon (scheme.reps m) := by
    rw [← h]; exact canon_encrypt scheme g m
  -- Step 2: Same canonical form implies same orbit
  have h_orbits := canon_eq_implies_orbit_eq scheme.canonForm _ _ h_canons
  -- Step 3: Contrapositive of reps_distinct — equal orbits imply equal messages
  by_contra h_ne
  exact absurd h_orbits (scheme.reps_distinct m' m h_ne)

-- ============================================================================
-- Work Unit 4.5: Decrypt-of-Encrypt Theorem (Headline Result #1)
-- ============================================================================

/--
**Correctness Theorem.** Decryption perfectly inverts encryption.
Formalizes DEVELOPMENT.md §4.2: `Pr[Dec(Enc(m)) = m] = 1`.

For any message `m` and any group element `g`, decrypting the ciphertext
`encrypt scheme g m` recovers the original message `m`.

**Proof strategy:**
1. Unfold `decrypt` and `encrypt` to expose the `dite` (dependent if-then-else).
2. Show the existence condition holds (message `m` itself witnesses it).
3. Use `dif_pos` to enter the `then` branch.
4. Show the chosen witness equals `m` by uniqueness (via `decrypt_unique`). -/
theorem correctness [Group G] [MulAction G X] [DecidableEq X]
    [Fintype M] [DecidableEq M]
    (scheme : OrbitEncScheme G X M) (m : M) (g : G) :
    decrypt scheme (encrypt scheme g m) = some m := by
  -- Step 1: Unfold to expose the dite structure
  unfold decrypt encrypt
  -- Step 2: The existence condition is satisfied by m itself
  have h_exists : ∃ m', scheme.canonForm.canon (g • scheme.reps m) =
      scheme.canonForm.canon (scheme.reps m') :=
    ⟨m, canonical_isGInvariant scheme.canonForm g (scheme.reps m)⟩
  -- Step 3: Enter the then-branch via dif_pos
  rw [dif_pos h_exists]
  -- Goal: some h_exists.choose = some m
  congr 1
  -- Step 4: Show the chosen witness equals m via decrypt_unique (4.3–4.4)
  exact decrypt_unique scheme g m h_exists.choose h_exists.choose_spec

end Orbcrypt
