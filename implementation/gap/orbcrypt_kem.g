##############################################################################
##
## orbcrypt_kem.g — KEM Encapsulation / Decapsulation
##
## Implements the Orbit KEM from Lean formalization (KEM/Encapsulate.lean):
##   encaps(kem, g) = (g . x0, keyDerive(canon(g . x0)))
##   decaps(kem, c) = keyDerive(canon(c))
##
## Also implements the original AOE scheme encrypt/decrypt for testing.
##
## Bitstring representation: support sets (sorted lists of 1-positions).
## Group action: OnSets — g . S = {g(i) : i in S}.
##
## Requires: orbcrypt_keygen.g (must be loaded first)
##
##############################################################################

LoadPackage("images");;

##############################################################################
## Bitstring Permutation Action
##############################################################################

#' PermuteBitstring(x, sigma) — Apply permutation sigma to support-set
#' bitstring x. Uses GAP's OnSets: g . S = {g(i) : i in S}.
#'
#' This matches the Lean left-action convention. In Lean, (sigma . x)(i) =
#' x(sigma^{-1}(i)), which for support sets means the new support is
#' {sigma(j) : j in old support} = OnSets(support, sigma).
#'
PermuteBitstring := function(x, sigma)
    return OnSets(x, sigma);
end;;

##############################################################################
## KEM Encapsulation
##############################################################################

#' HGOEEncaps(sk, basePoint) — KEM encapsulation.
#'
#' Samples g from G, computes ciphertext c = g . basePoint,
#' derives shared key from canonical image of c.
#'
#' Mirrors Lean: encaps(kem, g) = (g . x0, keyDerive(canon(g . x0)))
#'
HGOEEncaps := function(sk, basePoint)
    local g, c, canon_c, k;

    g := PseudoRandom(sk.G);
    c := PermuteBitstring(basePoint, g);
    canon_c := CanonicalImage(sk.G, c, OnSets);
    k := sk.keyDerive(canon_c);

    return rec(
        ciphertext   := c,
        key          := k,
        groupElement := g,
        canonImage   := canon_c
    );
end;;

##############################################################################
## KEM Decapsulation
##############################################################################

#' HGOEDecaps(sk, c) — KEM decapsulation.
#'
#' Recovers shared key from ciphertext by computing canonical image.
#'
#' Mirrors Lean: decaps(kem, c) = keyDerive(canon(c))
#'
HGOEDecaps := function(sk, c)
    local canon_c;
    canon_c := CanonicalImage(sk.G, c, OnSets);
    return sk.keyDerive(canon_c);
end;;

##############################################################################
## AOE Scheme Encrypt / Decrypt (for testing multi-message scheme)
##############################################################################

#' HGOEEncrypt(sk, g, messageIdx, reps) — Encrypt message under AOE scheme.
HGOEEncrypt := function(sk, g, messageIdx, reps)
    return PermuteBitstring(reps[messageIdx], g);
end;;

#' HGOEDecrypt(sk, c) — Decrypt ciphertext under AOE scheme.
#' Returns message index, or fail if canonical image not in lookup table.
HGOEDecrypt := function(sk, c)
    local canon_c;
    canon_c := CanonicalImage(sk.G, c, OnSets);
    return LookupDictionary(sk.lookupTable, canon_c);
end;;

##############################################################################
## Verification Helpers
##############################################################################

#' VerifyRoundTrip(sk, basePoint) — Verify encaps/decaps round-trip.
VerifyRoundTrip := function(sk, basePoint)
    local encResult, decKey;
    encResult := HGOEEncaps(sk, basePoint);
    decKey := HGOEDecaps(sk, encResult.ciphertext);
    return encResult.key = decKey;
end;;

#' VerifyOrbitMembership(G, basePoint, ciphertext) — Check ciphertext
#' is in the same orbit as basePoint (canonical images match).
VerifyOrbitMembership := function(G, basePoint, ciphertext)
    return CanonicalImage(G, basePoint, OnSets)
         = CanonicalImage(G, ciphertext, OnSets);
end;;

#' VerifyWeightPreservation(basePoint, ciphertext) — Check Hamming weight
#' is preserved. For support sets, weight = Length(set).
VerifyWeightPreservation := function(basePoint, ciphertext)
    return Length(basePoint) = Length(ciphertext);
end;;

Print("orbcrypt_kem.g loaded successfully.\n");;
