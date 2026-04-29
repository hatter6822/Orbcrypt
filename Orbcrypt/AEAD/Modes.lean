/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.KEM.Syntax
import Orbcrypt.KEM.Encapsulate

/-!
# Orbcrypt.AEAD.Modes

KEM + DEM hybrid encryption modes for Orbcrypt.

## Overview

Defines the standard KEM+DEM composition paradigm for encrypting
arbitrary-length data. The KEM produces a symmetric key; the DEM uses that
key to encrypt the actual plaintext with a standard symmetric cipher
(e.g., AES-GCM in a real deployment).

This is the construction that bridges Orbcrypt's group-theoretic key generation
with conventional symmetric encryption, making the scheme practical for
real-world message encryption.

## Key definitions

* `Orbcrypt.DEM` — Data Encapsulation Mechanism (symmetric encryption)
* `Orbcrypt.hybridEncrypt` — full hybrid encryption: KEM key + DEM encrypt
* `Orbcrypt.hybridDecrypt` — full hybrid decryption: KEM recover + DEM decrypt
* `Orbcrypt.hybrid_correctness` — `hybridDecrypt(hybridEncrypt(m)) = some m`

## Design decisions

- The DEM is a black-box symmetric primitive whose security is assumed, not
  proven. The formalization establishes that the KEM+DEM *composition* is
  correct (preserves messages).
- `hybridDecrypt` does not verify authenticity. For authenticated hybrid
  encryption, compose with `AuthOrbitKEM` from AEAD.lean.

## References

* docs/planning/PHASE_10_AUTHENTICATED_ENCRYPTION.md — work units 10.5–10.6
* KEM/Encapsulate.lean — `encaps` and `decaps`
* KEM/Correctness.lean — `kem_correctness`
-/

set_option autoImplicit false

namespace Orbcrypt

-- ============================================================================
-- Work Unit 10.5: KEM + DEM Composition
-- ============================================================================

variable {G : Type*} {X : Type*} {K : Type*}
  [Group G] [MulAction G X] [DecidableEq X]
variable {Plaintext : Type*} {Ciphertext : Type*}

/--
A Data Encapsulation Mechanism (DEM): symmetric encryption keyed by `K`.

The DEM is the "second half" of the KEM+DEM paradigm: the KEM establishes
a shared symmetric key, and the DEM uses that key to encrypt actual data.

**Fields:**
- `enc : K → Plaintext → Ciphertext` — symmetric encryption
- `dec : K → Ciphertext → Option Plaintext` — symmetric decryption
- `correct` — `dec k (enc k m) = some m` for all keys and plaintexts

**Design note:** `dec` returns `Option Plaintext` to handle potential
decryption failures (e.g., padding errors). The `correct` field guarantees
that honestly encrypted data always decrypts successfully.
-/
structure DEM (K : Type*) (Plaintext : Type*) (Ciphertext : Type*) where
  /-- Symmetric encryption under key `k`. -/
  enc : K → Plaintext → Ciphertext
  /-- Symmetric decryption under key `k`. Returns `none` on failure. -/
  dec : K → Ciphertext → Option Plaintext
  /-- Correctness: decryption inverts encryption. -/
  correct : ∀ (k : K) (m : Plaintext), dec k (enc k m) = some m

/--
Full hybrid encryption: KEM produces a key, DEM encrypts the data.

1. Run `encaps kem g` to get `(c_kem, k)`.
2. Run `dem.enc k m` to get `c_dem`.
3. Return `(c_kem, c_dem)`.

The receiver needs both the KEM ciphertext (to recover the key via `decaps`)
and the DEM ciphertext (to recover the plaintext via `dem.dec`).
-/
def hybridEncrypt (kem : OrbitKEM G X K)
    (dem : DEM K Plaintext Ciphertext)
    (g : G) (m : Plaintext) : X × Ciphertext :=
  let (c_kem, k) := encaps kem g
  (c_kem, dem.enc k m)

/--
Full hybrid decryption.

1. Recover key `k` via `decaps kem c_kem`.
2. Decrypt `dem.dec k c_dem` to recover the plaintext.
-/
def hybridDecrypt (kem : OrbitKEM G X K)
    (dem : DEM K Plaintext Ciphertext)
    (c_kem : X) (c_dem : Ciphertext) : Option Plaintext :=
  let k := decaps kem c_kem
  dem.dec k c_dem

-- Simp lemmas for unfolding hybrid encrypt/decrypt

/-- Unfold the KEM ciphertext component of hybrid encryption. -/
@[simp]
theorem hybridEncrypt_fst (kem : OrbitKEM G X K)
    (dem : DEM K Plaintext Ciphertext) (g : G) (m : Plaintext) :
    (hybridEncrypt kem dem g m).1 = (encaps kem g).1 := rfl

/-- Unfold the DEM ciphertext component of hybrid encryption. -/
@[simp]
theorem hybridEncrypt_snd (kem : OrbitKEM G X K)
    (dem : DEM K Plaintext Ciphertext) (g : G) (m : Plaintext) :
    (hybridEncrypt kem dem g m).2 = dem.enc (encaps kem g).2 m := rfl

-- ============================================================================
-- Work Unit 10.6: Hybrid Encryption Correctness
-- ============================================================================

/--
**Hybrid Encryption Correctness.** Decrypting an honestly encrypted message
recovers the original plaintext: `hybridDecrypt(hybridEncrypt(m)) = some m`.

**Proof strategy:**
1. Unfold `hybridEncrypt`: `c_kem = (encaps kem g).1`, `c_dem = dem.enc k m`
   where `k = (encaps kem g).2`.
2. Unfold `hybridDecrypt`: recovers `k' = decaps kem c_kem`, then
   computes `dem.dec k' c_dem`.
3. By `kem_correctness`, `k' = k` (KEM correctly recovers the key).
4. Therefore `dem.dec k (dem.enc k m)`.
5. By `dem.correct`, this equals `some m`.

**Axioms:** Only standard Lean axioms. No custom axioms, no placeholders.
-/
theorem hybrid_correctness (kem : OrbitKEM G X K)
    (dem : DEM K Plaintext Ciphertext) (g : G) (m : Plaintext) :
    let (c_kem, c_dem) := hybridEncrypt kem dem g m
    hybridDecrypt kem dem c_kem c_dem = some m := by
  -- Unfold all definitions: hybridEncrypt, hybridDecrypt, encaps, decaps
  simp only [hybridEncrypt, hybridDecrypt, encaps, decaps]
  -- Now the goal reduces to dem.dec k (dem.enc k m) = some m
  -- which follows from dem.correct
  exact dem.correct _ m

end Orbcrypt
