import Orbcrypt.Construction.HGOE
import Orbcrypt.KEM.Correctness
import Orbcrypt.KEM.Security

/-!
# Orbcrypt.Construction.HGOEKEM

Concrete KEM instantiation for the Hidden-Group Orbit Encryption (HGOE)
construction: `OrbitKEM` for a subgroup of S_n acting on bitstrings,
correctness instantiation, and backward-compatibility bridge from scheme to KEM.

## Main definitions and results

* `Orbcrypt.hgoeKEM` — concrete `OrbitKEM` for HGOE
* `Orbcrypt.hgoe_kem_correctness` — KEM correctness for HGOE
* `Orbcrypt.hgoeScheme_toKEM` — bridge from `hgoeScheme` to KEM via `toKEM`
* `Orbcrypt.hgoeScheme_toKEM_correct` — correctness for the bridge construction

## References

* formalization/PRACTICAL_IMPROVEMENTS_PLAN.md — work unit 7.8
* Construction/HGOE.lean — HGOE scheme and Hamming weight defense
-/

namespace Orbcrypt

variable {n : ℕ}

-- ============================================================================
-- Work Unit 7.8: HGOE-KEM Construction
-- ============================================================================

/--
Construct a concrete HGOE-KEM from a subgroup G ≤ S_n, a canonical form, a
base point bitstring, and a key derivation function.

This is the direct KEM construction for HGOE, using a fixed bitstring as the
base point. The ciphertext space is `Bitstring n` and the key space is `K`.
-/
def hgoeKEM {K : Type*}
    (G : Subgroup (Equiv.Perm (Fin n)))
    (can : CanonicalForm (↥G) (Bitstring n))
    (bp : Bitstring n)
    (kd : Bitstring n → K) :
    OrbitKEM (↥G) (Bitstring n) K where
  basePoint := bp
  canonForm := can
  keyDerive := kd

/--
Correctness of the HGOE-KEM: decapsulation recovers the encapsulated key.
Direct application of the abstract `kem_correctness` theorem.
-/
theorem hgoe_kem_correctness {K : Type*}
    (G : Subgroup (Equiv.Perm (Fin n)))
    (can : CanonicalForm (↥G) (Bitstring n))
    (bp : Bitstring n)
    (kd : Bitstring n → K)
    (g : ↥G) :
    decaps (hgoeKEM G can bp kd) (encaps (hgoeKEM G can bp kd) g).1 =
    (encaps (hgoeKEM G can bp kd) g).2 :=
  kem_correctness (hgoeKEM G can bp kd) g

-- ============================================================================
-- Work Unit 7.8 (continued): Bridge from HGOE Scheme to KEM
-- ============================================================================

/--
Convert an existing HGOE scheme to a KEM by fixing a message and providing
a key derivation function. Uses `OrbitEncScheme.toKEM` from KEM/Syntax.lean.
-/
def hgoeScheme_toKEM {M : Type*} {K : Type*}
    (G : Subgroup (Equiv.Perm (Fin n)))
    (scheme : OrbitEncScheme (↥G) (Bitstring n) M)
    (m₀ : M) (kd : Bitstring n → K) :
    OrbitKEM (↥G) (Bitstring n) K :=
  scheme.toKEM m₀ kd

/--
Correctness for the HGOE-to-KEM bridge construction.
Direct application of `toKEM_correct`.
-/
theorem hgoeScheme_toKEM_correct {M : Type*} {K : Type*}
    (G : Subgroup (Equiv.Perm (Fin n)))
    (scheme : OrbitEncScheme (↥G) (Bitstring n) M)
    (m₀ : M) (kd : Bitstring n → K) (g : ↥G) :
    decaps (hgoeScheme_toKEM G scheme m₀ kd)
      (encaps (hgoeScheme_toKEM G scheme m₀ kd) g).1 =
    (encaps (hgoeScheme_toKEM G scheme m₀ kd) g).2 :=
  toKEM_correct scheme m₀ kd g

end Orbcrypt
