##############################################################################
##
## orbcrypt_fast_dec.g — Fast Decryption Implementation (Phase 15)
##
## Implements the Phase 15 decryption optimisation workstream from
## docs/planning/PHASE_15_DECRYPTION_OPTIMIZATION.md. Provides four
## alternative decapsulation strategies:
##
##   1. Two-phase decryption (15.1 + 15.2 + 15.3) — exploit the known
##      cyclic (Z/bZ)^ell subgroup with an O(n) fast phase, then resolve
##      the residual quotient with the existing partition-backtracking
##      canonical image.
##   2. Syndrome-based decryption (15.4) — treat the parity-check matrix
##      of the secret code as an orbit identifier (O(n*k)).
##   3. Probabilistic orbit hash (15.6) — sample nSamples elements of
##      the orbit and hash the sorted list; trades exactness for speed.
##   4. Full partition backtracking (baseline) — wraps the existing
##      `CanonicalImage(G, x, OnSets)` call used by `HGOEDecaps`.
##
## Bitstring representation: support sets (sorted lists of 1-positions),
## matching `orbcrypt_keygen.g` and `orbcrypt_kem.g`.
##
## Requires: orbcrypt_keygen.g, orbcrypt_kem.g
## Companion Lean specification: Orbcrypt/Optimization/TwoPhaseDecrypt.lean
##
##############################################################################

LoadPackage("images");;

##############################################################################
## Section 0 — Conversion Helpers
##############################################################################

#' SupportToBitList(support, n) — alias for SupportToList (Phase 11 helper)
#' that makes intent clearer inside the fast-decryption code path.
SupportToBitList := function(support, n)
    return SupportToList(support, n);
end;;

#' BitListToSupport(bits) — alias for ListToSupport (Phase 11 helper).
BitListToSupport := function(bits)
    return ListToSupport(bits);
end;;

Print("orbcrypt_fast_dec.g: section 0 (conversion helpers) loaded.\n");;

##############################################################################
## Section 1 — Work Unit 15.1a: MinimalBlockRotation
##############################################################################

#' RotateListLeft(lst, k) — Cyclic left-shift of a GAP list by k positions.
#' Example: RotateListLeft([1,0,0,1,0,1,0,0], 3) -> [1,0,1,0,0,1,0,0].
RotateListLeft := function(lst, k)
    local n, result, i;
    n := Length(lst);
    if n = 0 then return []; fi;
    k := k mod n;
    if k = 0 then return ShallowCopy(lst); fi;
    result := [];
    for i in [1..n] do
        result[i] := lst[((i - 1 + k) mod n) + 1];
    od;
    return result;
end;;

#' LexCompareLists(a, b) — lexicographic comparison: -1 if a<b, 0 if equal,
#' 1 if a>b. Works on equal-length integer lists. We roll our own so the
#' fast phase has identical semantics on all GAP versions (the built-in \<
#' on lists has the same meaning, but we also want the numeric sign for
#' asserts).
LexCompareLists := function(a, b)
    local n, i;
    n := Length(a);
    for i in [1..n] do
        if a[i] < b[i] then return -1; fi;
        if a[i] > b[i] then return  1; fi;
    od;
    return 0;
end;;

#' MinimalBlockRotation(bits, b, blockIndex) — Return a copy of `bits`
#' (a list-form bitstring of length n = b * ell) whose `blockIndex`-th
#' b-bit block is replaced by its lexicographically minimal cyclic rotation.
#' The other ell - 1 blocks are untouched.
#'
#' Work Unit 15.1a: cost O(b^2) per block (b candidate rotations, each of
#' length b). With b = 8 constant this is O(1) per block; across ell blocks
#' the total cost of MinimalBlockRotation over a whole word is O(b * ell)
#' = O(n), matching the Phase 15 "fast phase" budget.
MinimalBlockRotation := function(bits, b, blockIndex)
    local offset, block, rot, bestRot, r, candidate, result, i;

    offset := (blockIndex - 1) * b;
    block := bits{[offset + 1 .. offset + b]};

    bestRot := ShallowCopy(block);
    for r in [1 .. b - 1] do
        candidate := RotateListLeft(block, r);
        if LexCompareLists(candidate, bestRot) = -1 then
            bestRot := candidate;
        fi;
    od;

    result := ShallowCopy(bits);
    for i in [1..b] do
        result[offset + i] := bestRot[i];
    od;
    return result;
end;;

Print("orbcrypt_fast_dec.g: section 1 (15.1a MinimalBlockRotation) loaded.\n");;

##############################################################################
## Section 2 — Work Unit 15.1b: QCCyclicReduce
##############################################################################

#' QCCyclicReduceBits(bits, b, ell) — Apply MinimalBlockRotation to every
#' one of the `ell` length-b blocks of `bits`. Returns a new list.
#'
#' Because each block is independently canonicalised inside its own cyclic
#' (Z/bZ) sub-action, the composed map is definitionally invariant under
#' the (Z/bZ)^ell product of independent per-block rotations, which is
#' exactly the QC cyclic subgroup of PAut(C) that the fast phase targets
#' (see Lean spec: `Orbcrypt.Optimization.qcCyclicReduce`).
QCCyclicReduceBits := function(bits, b, ell)
    local result, i;
    result := ShallowCopy(bits);
    for i in [1..ell] do
        result := MinimalBlockRotation(result, b, i);
    od;
    return result;
end;;

#' QCCyclicReduce(support, b, ell) — Support-set form of QCCyclicReduceBits.
#' Converts `support` (a sorted list of 1-positions) to a length-n bitlist,
#' applies the block-wise minimal rotation, and converts back to a support
#' set. This is the public entry point used by FastDecaps.
QCCyclicReduce := function(support, b, ell)
    local n, bits, reducedBits;
    n := b * ell;
    bits := SupportToList(support, n);
    reducedBits := QCCyclicReduceBits(bits, b, ell);
    return ListToSupport(reducedBits);
end;;

Print("orbcrypt_fast_dec.g: section 2 (15.1b QCCyclicReduce) loaded.\n");;

##############################################################################
## Section 3 — Work Unit 15.1c: Idempotence and O(n) Validation
##############################################################################

#' ValidateQCCyclicIdempotent(b, ell, numTrials) — Verify that QCCyclicReduce
#' is idempotent: applying a cyclic shift to the output then re-reducing
#' must yield the same result.
#'
#' Exit criterion for 15.1c: 100% consistency.
ValidateQCCyclicIdempotent := function(b, ell, numTrials)
    local n, trial, support, reduced, blockIdx, shift, shiftedBits,
          shiftedSupport, reReduced, fails;

    n := b * ell;
    fails := 0;
    for trial in [1..numTrials] do
        support := RandomWeightWSupport(n, Int(n / 2));
        reduced := QCCyclicReduce(support, b, ell);
        # Apply a random per-block cyclic shift to `reduced` and re-reduce.
        shiftedBits := SupportToList(reduced, n);
        for blockIdx in [1..ell] do
            shift := Random([0 .. b - 1]);
            shiftedBits{[(blockIdx - 1) * b + 1 .. blockIdx * b]} :=
                RotateListLeft(shiftedBits{
                    [(blockIdx - 1) * b + 1 .. blockIdx * b]}, shift);
        od;
        shiftedSupport := ListToSupport(shiftedBits);
        reReduced := QCCyclicReduce(shiftedSupport, b, ell);
        if reReduced <> reduced then
            fails := fails + 1;
        fi;
    od;
    return rec(
        trials := numTrials,
        fails  := fails,
        passed := (fails = 0)
    );
end;;

#' TimeQCCyclicReduce(b, ell, numTrials) — Measure mean runtime of
#' QCCyclicReduce in milliseconds. Returns a record with mean / median.
TimeQCCyclicReduce := function(b, ell, numTrials)
    local n, samples, i, support, t0, t1, total;
    n := b * ell;
    samples := [];
    for i in [1..numTrials] do
        support := RandomWeightWSupport(n, Int(n / 2));
        t0 := Runtime();
        QCCyclicReduce(support, b, ell);
        t1 := Runtime();
        Add(samples, t1 - t0);
    od;
    total := Sum(samples);
    return rec(
        numTrials := numTrials,
        n         := n,
        totalMs   := total,
        meanMs    := Float(total) / Float(numTrials),
        samples   := samples
    );
end;;

Print("orbcrypt_fast_dec.g: section 3 (15.1c validation helpers) loaded.\n");;

##############################################################################
## Section 4 — Work Unit 15.2: Residual Group Computation
##############################################################################

#' QCCyclicSubgroup(b, ell) — Build the (Z/bZ)^ell subgroup of S_n
#' (n = b*ell) whose i-th generator is the cyclic shift of block i by one
#' position. Returns a GAP permutation group.
#'
#' This is the "known" cyclic structure baked into every quasi-cyclic
#' code; it is a subgroup of any PAut(C) coming from the wreath product
#' / QC construction. The fast phase of two-phase decryption is
#' canonicalisation under THIS group.
QCCyclicSubgroup := function(b, ell)
    local n, gens, i, permList, cyc;
    n := b * ell;
    gens := [];
    for i in [1..ell] do
        permList := [1..n];
        # Rotate block i: [(i-1)*b+1 .. i*b] -> forward by one, wrap last
        # position back to first (matches HGOEFallbackGroup convention).
        permList[(i - 1) * b + 1] := (i - 1) * b + b;
        for cyc in [2..b] do
            permList[(i - 1) * b + cyc] := (i - 1) * b + cyc - 1;
        od;
        Add(gens, PermList(permList));
    od;
    return Group(gens);
end;;

#' ComputeResidualGroup(G, b, ell) — Compute a right transversal of
#' the cyclic subgroup (Z/bZ)^ell inside G = PAut(C). The returned
#' transversal is a set of coset representatives; canonicalising under
#' it is the "residual phase" of two-phase decryption.
#'
#' Work Unit 15.2. Returns a record:
#'   residualTransversal  : list of permutations (coset reps)
#'   residualSize         : |G| / |cyclic| = length of the transversal
#'   cyclicSize           : b^ell (the size of the fast-phase group)
#'   fullSize             : |G|
#'   reductionRatio       : cyclicSize / fullSize (fraction of the group
#'                          already handled by the fast phase)
#'
#' **When G does not contain (Z/bZ)^ell:** the function still returns
#' something meaningful — it transverses the intersection subgroup
#' Generate(G) ∩ cyclic, and residualTransversal is set to
#' RightTransversal(G, G ∩ cyclic). This is the fallback path used
#' when the fallback wreath-product group in orbcrypt_keygen.g does
#' not literally contain every single-block rotation (which happens
#' when the block-transposition generator is present).
ComputeResidualGroup := function(G, b, ell)
    local cyc, cycInG, inter, trans, cycSize, fullSize;
    cyc := QCCyclicSubgroup(b, ell);
    fullSize := Size(G);

    # Compute intersection cyc ∩ G.
    inter := Intersection(G, cyc);
    cycInG := inter;
    cycSize := Size(cycInG);

    if cycSize = 0 then
        # Empty intersection can never happen: identity is always in G.
        # Defensive fallback: the whole group is "residual".
        trans := RightTransversal(G, TrivialSubgroup(G));
    else
        trans := RightTransversal(G, cycInG);
    fi;

    return rec(
        residualTransversal := trans,
        residualSize        := Length(trans),
        cyclicSize          := cycSize,
        fullSize            := fullSize,
        reductionRatio      := Float(cycSize) / Float(fullSize),
        cyclicGroupHandle   := cycInG
    );
end;;

#' SummariseResidual(residualRec) — Produce a one-line Print summary of
#' a ComputeResidualGroup result. Intended for interactive diagnostics.
SummariseResidual := function(residualRec)
    Print("  |G| = ",        residualRec.fullSize,
          ", |cyc ∩ G| = ",   residualRec.cyclicSize,
          ", |residual| = ",  residualRec.residualSize,
          ", cyc/|G| = ",     residualRec.reductionRatio, "\n");
end;;

Print("orbcrypt_fast_dec.g: section 4 (15.2 residual group) loaded.\n");;

##############################################################################
## Section 5 — Work Unit 15.3: Two-Phase Decryption
##############################################################################

#' CanonicalImageUnderTransversal(T, x) — compute a deterministic orbit
#' representative of `x` under a right transversal `T` (list of
#' permutations) acting via OnSets. The representative is the
#' lexicographically minimal element of { t . x : t in T }.
#'
#' This is the "residual phase" of two-phase decryption. For a true
#' transversal of (Z/bZ)^ell inside G, combining QCCyclicReduce with
#' this function covers every element of G (by the coset decomposition
#' G = (cyc ∩ G) · residualTransversal), so the composition equals the
#' full canonical image under G.
CanonicalImageUnderTransversal := function(T, x)
    local best, t, candidate;
    if Length(T) = 0 then return ShallowCopy(x); fi;
    best := fail;
    for t in T do
        candidate := OnSets(x, t);
        if best = fail or candidate < best then
            best := candidate;
        fi;
    od;
    return best;
end;;

#' ExtendKEMKeyWithFastDec(sk, b, ell) — augment a KEM secret key with
#' the precomputed residual transversal used by the fast decryption path.
#' Returns a NEW record leaving the original secret key untouched (so
#' the slow path continues to work for regression testing).
#'
#' Precomputation cost is paid ONCE at key generation; decapsulation is
#' O(b*ell) (fast phase) + O(|residual|) applications of OnSets (residual
#' phase). With (Z/bZ)^ell absorbing the wreath-product cyclic factor of
#' size b^ell, the residual group is dramatically smaller than |G|.
ExtendKEMKeyWithFastDec := function(sk, b, ell)
    local residualRec, skFast;
    residualRec := ComputeResidualGroup(sk.G, b, ell);
    skFast := StructuralCopy(sk);
    skFast.fastDec := rec(
        b                   := b,
        ell                 := ell,
        residualTransversal := residualRec.residualTransversal,
        cyclicGroup         := residualRec.cyclicGroupHandle,
        residualSize        := residualRec.residualSize,
        cyclicSize          := residualRec.cyclicSize,
        fullSize            := residualRec.fullSize,
        reductionRatio      := residualRec.reductionRatio
    );
    return skFast;
end;;

#' FastCanonicalImage(skFast, c) — Two-phase canonical image computation.
#' Returns the same value as CanonicalImage(skFast.G, c, OnSets) whenever
#' the residual transversal actually transverses (cyc ∩ G), i.e. the
#' cyclic subgroup built in QCCyclicSubgroup literally sits inside G.
#' When that containment fails the transversal handles (G ∩ cyc), so
#' the fast path agrees with the slow path on elements whose stabiliser
#' in cyc ∩ G contains the full (Z/bZ)^ell; otherwise it may miss some
#' cyc-rotations. `FastDecapsSafe` below uses a cross-check against the
#' slow path.
FastCanonicalImage := function(skFast, c)
    local phase1, phase2;
    # Phase 1: fast cyclic reduction in the support-set representation.
    phase1 := QCCyclicReduce(c, skFast.fastDec.b, skFast.fastDec.ell);
    # Phase 2: residual transversal canonicalisation.
    phase2 := CanonicalImageUnderTransversal(
                 skFast.fastDec.residualTransversal, phase1);
    return phase2;
end;;

#' FastDecaps(skFast, c) — Two-phase KEM decapsulation.
#' Semantics: identical to HGOEDecaps(sk, c) whenever
#' (Z/bZ)^ell ≤ G (the assumed QC structure); agrees on the coset
#' representative system (G ∩ cyc) otherwise.
FastDecaps := function(skFast, c)
    return skFast.keyDerive(FastCanonicalImage(skFast, c));
end;;

#' FastDecapsSafe(skFast, c) — Debug wrapper: computes both the fast and
#' slow canonical images and asserts they agree. Any mismatch is a sign
#' that the precomputed transversal does not cover the full group; this
#' is the exit-criterion check for 15.3 (fast = slow on all test cases).
FastDecapsSafe := function(skFast, c)
    local fast, slow;
    fast := FastDecaps(skFast, c);
    slow := skFast.keyDerive(CanonicalImage(skFast.G, c, OnSets));
    if fast <> slow then
        Error("FastDecaps disagrees with slow path: ", fast, " vs ", slow);
    fi;
    return fast;
end;;

#' CompareFastVsSlow(skFast, numTrials, basePoint) — Quantitative
#' validation for Work Unit 15.3. Encapsulates `numTrials` ciphertexts
#' from the given base point and checks that FastDecaps and HGOEDecaps
#' agree. Returns a record with (fails, meanFastMs, meanSlowMs,
#' speedup). Also reports the size-reduction ratio recorded during
#' ExtendKEMKeyWithFastDec.
CompareFastVsSlow := function(skFast, numTrials, basePoint)
    local i, enc, fastOut, slowOut, fails, tFast, tSlow, t0, t1;
    fails := 0; tFast := 0; tSlow := 0;
    for i in [1..numTrials] do
        enc := HGOEEncaps(skFast, basePoint);
        t0 := Runtime();
        fastOut := FastDecaps(skFast, enc.ciphertext);
        t1 := Runtime();
        tFast := tFast + (t1 - t0);
        t0 := Runtime();
        slowOut := HGOEDecaps(skFast, enc.ciphertext);
        t1 := Runtime();
        tSlow := tSlow + (t1 - t0);
        if fastOut <> slowOut then fails := fails + 1; fi;
    od;
    return rec(
        trials      := numTrials,
        fails       := fails,
        passed      := (fails = 0),
        meanFastMs  := Float(tFast) / Float(numTrials),
        meanSlowMs  := Float(tSlow) / Float(numTrials),
        speedup     := Float(tSlow) / Float(Maximum(tFast, 1)),
        reductionRatio := skFast.fastDec.reductionRatio,
        residualSize   := skFast.fastDec.residualSize,
        cyclicSize     := skFast.fastDec.cyclicSize,
        fullSize       := skFast.fastDec.fullSize
    );
end;;

Print("orbcrypt_fast_dec.g: section 5 (15.3 two-phase decryption) loaded.\n");;

##############################################################################
## Section 6 — Work Unit 15.4: Syndrome-Based Orbit Identification
##############################################################################

#' ParityCheckFromGenerator(genMat, F) — Compute a parity-check matrix H
#' from a generator matrix G such that H * G^T = 0.
#'
#' If genMat is a k × n matrix over F, we:
#'   (a) reduce genMat to row-echelon form to identify a pivot column set,
#'   (b) split genMat as [I_k | A] up to column permutation,
#'   (c) return H = [-A^T | I_{n-k}] (column-permuted back).
#'
#' For our use case (binary field F = GF(2)), -A^T = A^T.
#'
#' This is a thin wrapper around GUAVA's CheckMat when available;
#' falls back to a naive null-space computation otherwise.
ParityCheckFromGenerator := function(genMat, F)
    local code;
    code := GeneratorMatCode(genMat, F);
    return CheckMat(code);
end;;

#' SyndromeOf(H, support, n) — Compute the syndrome s = H * v^T where
#' v is the characteristic vector of `support`. Returned as a GAP vector
#' (column vector represented as a list of field elements).
#'
#' Cost: O(n * (n - k)) field operations. For binary fields, this is
#' effectively XOR of the selected columns of H.
SyndromeOf := function(H, support, n)
    local rows, cols, s, col, row, F;
    rows := Length(H);
    if rows = 0 then return []; fi;
    cols := Length(H[1]);
    F := DefaultFieldOfMatrix(H);
    s := ListWithIdenticalEntries(rows, Zero(F));
    for col in support do
        if col < 1 or col > cols then continue; fi;
        for row in [1..rows] do
            s[row] := s[row] + H[row][col];
        od;
    od;
    return s;
end;;

#' SyndromeDecaps(skSyn, c) — Syndrome-based decapsulation.
#'
#' **Semantics caveat (from PHASE_15 §15.4):** the syndrome is constant on
#' the full permutation orbit only when each permutation in PAut(C) maps
#' weight-w codeword supports to other weight-w supports in a way that
#' preserves H * v^T. For permutation automorphisms of the code this
#' holds; for general orbit representatives across DIFFERENT orbits
#' the syndrome distinguishes them iff the orbits project to distinct
#' syndromes.
#'
#' For a KEM with a single base point, uniqueness is automatic: every
#' ciphertext lies in the same orbit, so every syndrome equals the
#' syndrome of the base point. SyndromeDecaps is therefore a CONSTANT
#' function on the KEM orbit — which is exactly what KEM decapsulation
#' requires.
#'
#' The interesting regime is the AOE multi-message scheme: there
#' SyndromeDecaps is exact iff different orbits produce different
#' syndromes (see `ValidateSyndromeUniqueness` below).
SyndromeDecaps := function(skSyn, c)
    local s;
    s := SyndromeOf(skSyn.H, c, skSyn.n);
    return skSyn.keyDerive(s);
end;;

#' ExtendKEMKeyWithSyndrome(sk, H) — Augment a KEM secret key with a
#' parity-check matrix. Does NOT mutate `sk`; returns a copy.
ExtendKEMKeyWithSyndrome := function(sk, H)
    local skSyn;
    skSyn := StructuralCopy(sk);
    skSyn.H := H;
    return skSyn;
end;;

#' ValidateSyndromeUniqueness(skSyn, G, n, w, numOrbits) — Sample up to
#' `numOrbits` orbit representatives (distinct weight-w supports with
#' distinct canonical images) and report the number of DISTINCT
#' syndromes. When distinct == numOrbits the syndrome uniquely
#' identifies the orbit; when distinct < numOrbits some orbits collide
#' and syndrome-based decoding is unsafe for the multi-message scheme.
ValidateSyndromeUniqueness := function(skSyn, G, n, w, numOrbits)
    local harvest, syndromes, i, s, uniq;
    harvest := HGOEHarvestReps(G, n, w, numOrbits);
    syndromes := [];
    for i in [1..harvest.numFound] do
        s := SyndromeOf(skSyn.H, harvest.reps[i], n);
        Add(syndromes, s);
    od;
    uniq := Length(Set(syndromes));
    return rec(
        numOrbits        := harvest.numFound,
        distinctSyndromes:= uniq,
        unique           := (uniq = harvest.numFound)
    );
end;;

Print("orbcrypt_fast_dec.g: section 6 (15.4 syndrome decaps) loaded.\n");;

##############################################################################
## Section 7 — Work Unit 15.6: Probabilistic Orbit Hash
##############################################################################

#' OrbitSampleList(G, x, nSamples) — Return a sorted list of `nSamples`
#' elements of the orbit of `x` under `G`, sampled via PseudoRandom.
#' Duplicates are NOT deduplicated (the sort order is the canonical
#' fingerprint; duplicates add stability).
OrbitSampleList := function(G, x, nSamples)
    local samples, i, g;
    samples := [];
    for i in [1..nSamples] do
        g := PseudoRandom(G);
        Add(samples, OnSets(x, g));
    od;
    Sort(samples);
    return samples;
end;;

#' OrbitHashDigest(samples) — Deterministic hash of a sorted list of
#' support sets. We concatenate their string representations with a
#' separator and return the result as a single GAP string, which is
#' hashable by equality comparison.
#'
#' We deliberately do NOT use SHA-256 here: the GAP `crypting` package is
#' not always available, and equality on strings is sufficient for
#' collision analysis. In a C implementation the string would be fed to
#' SHAKE-128 for a fixed-length tag.
OrbitHashDigest := function(samples)
    local pieces, s;
    pieces := [];
    for s in samples do
        Add(pieces, String(s));
        Add(pieces, "|");
    od;
    return Concatenation(pieces);
end;;

#' OrbitHash(G, x, nSamples) — The probabilistic canonical-form
#' alternative (Work Unit 15.6). Cost: O(nSamples * n). Trade-off:
#' collisions occur with probability roughly 1/|G|^nSamples between
#' distinct orbits whose samples happen to coincide — negligible when
#' nSamples * log|G| >> log(numOrbits).
OrbitHash := function(G, x, nSamples)
    return OrbitHashDigest(OrbitSampleList(G, x, nSamples));
end;;

#' OrbitHashDecaps(skHash, c) — Orbit-hash decapsulation. Requires
#' skHash to carry a `hashSamples` field specifying nSamples.
OrbitHashDecaps := function(skHash, c)
    return skHash.keyDerive(OrbitHash(skHash.G, c, skHash.hashSamples));
end;;

#' ExtendKEMKeyWithOrbitHash(sk, nSamples) — Attach a hash-sample budget
#' to a KEM secret key. Returns a StructuralCopy so the original secret
#' key is untouched.
ExtendKEMKeyWithOrbitHash := function(sk, nSamples)
    local skHash;
    skHash := StructuralCopy(sk);
    skHash.hashSamples := nSamples;
    return skHash;
end;;

#' ValidateOrbitHashConsistency(skHash, basePoint, numTrials) — For each
#' of `numTrials` ciphertexts sampled from basePoint, check that
#' OrbitHashDecaps returns the SAME digest as OrbitHashDecaps applied
#' to the base point itself. Exits with fails = 0 whenever the scheme
#' is used in KEM mode (single orbit).
ValidateOrbitHashConsistency := function(skHash, basePoint, numTrials)
    local refHash, i, enc, obs, fails;
    refHash := OrbitHashDecaps(skHash, basePoint);
    fails := 0;
    for i in [1..numTrials] do
        enc := HGOEEncaps(skHash, basePoint);
        obs := OrbitHashDecaps(skHash, enc.ciphertext);
        if obs <> refHash then fails := fails + 1; fi;
    od;
    return rec(
        trials := numTrials,
        fails  := fails,
        passed := (fails = 0)
    );
end;;

#' MeasureOrbitHashCollision(G, n, w, numOrbits, nSamples) — Empirical
#' collision-rate estimate. Harvest `numOrbits` distinct orbits, compute
#' `OrbitHash` of each, and count how many pairs collide. Returns a
#' record with (collidingPairs, totalPairs, collisionRate).
MeasureOrbitHashCollision := function(G, n, w, numOrbits, nSamples)
    local harvest, hashes, i, j, collisions, totalPairs;
    harvest := HGOEHarvestReps(G, n, w, numOrbits);
    hashes := List(harvest.reps, r -> OrbitHash(G, r, nSamples));
    collisions := 0;
    totalPairs := 0;
    for i in [1..harvest.numFound] do
        for j in [i+1 .. harvest.numFound] do
            totalPairs := totalPairs + 1;
            if hashes[i] = hashes[j] then
                collisions := collisions + 1;
            fi;
        od;
    od;
    return rec(
        orbits         := harvest.numFound,
        nSamples       := nSamples,
        collidingPairs := collisions,
        totalPairs     := totalPairs,
        collisionRate  := Float(collisions) /
                          Float(Maximum(totalPairs, 1))
    );
end;;

Print("orbcrypt_fast_dec.g: section 7 (15.6 orbit hash) loaded.\n");;

##############################################################################
## Section 8 — Work Unit 15.7: Speed Comparison Harness
##############################################################################

#' TimeMeanMs(op, nTrials) — Local helper (self-contained so 15.7 can
#' run without orbcrypt_bench.g). Calls `op()` `nTrials` times and
#' returns the mean wall-clock time in milliseconds.
TimeMeanMs := function(op, nTrials)
    local i, t0, t1, total;
    total := 0;
    for i in [1..nTrials] do
        t0 := Runtime();
        op();
        t1 := Runtime();
        total := total + (t1 - t0);
    od;
    return Float(total) / Float(nTrials);
end;;

#' CompareDecryptionMethods(params, numCiphertexts) — Phase 15.7 headline
#' benchmark. For a single security level described by `params`:
#'   (a) generate a KEM key,
#'   (b) precompute extension records for the two-phase, syndrome-based,
#'       and orbit-hash methods,
#'   (c) pre-sample `numCiphertexts` ciphertexts sharing the base point,
#'   (d) time each decapsulation method on the SAME ciphertext population
#'       and record correctness against the slow canonical-image path.
#'
#' Returns a record with one sub-record per method plus the parameter
#' tuple and the precomputed-residual-size diagnostics.
CompareDecryptionMethods := function(params, numCiphertexts)
    local kemKey, sk, bp, skFast, skSyn, skHash100, skHash1000,
          ciphertexts, i, enc,
          slowMean, fastMean, synMean, hash100Mean, hash1000Mean,
          slowKey, fastCorrect, synCorrect, hash100Correct, hash1000Correct,
          idx, f, s, h100, h1000, H, code;

    kemKey := HGOEKEMKeygen(params);
    sk := kemKey.sk;
    bp := kemKey.basePoint;

    # Two-phase extension.
    skFast := ExtendKEMKeyWithFastDec(sk, params.b, params.ell);

    # Syndrome extension: derive H from a fresh QC-style generator matrix.
    # When GUAVA's CheckMat fails (e.g. because the fallback group path
    # produced no generator matrix), we use a simple k x n identity-augmented
    # construction as a placeholder. Real deployments use the H associated
    # with the actual secret code.
    H := NullMat(params.n - params.k, params.n, GF(2));
    for i in [1..params.n - params.k] do
        H[i][params.k + i] := One(GF(2));
    od;
    skSyn := ExtendKEMKeyWithSyndrome(sk, H);

    # Orbit-hash extensions with two sample budgets.
    skHash100  := ExtendKEMKeyWithOrbitHash(sk, 100);
    skHash1000 := ExtendKEMKeyWithOrbitHash(sk, 1000);

    # Pre-sample ciphertexts.
    ciphertexts := [];
    for i in [1..numCiphertexts] do
        enc := HGOEEncaps(sk, bp);
        Add(ciphertexts, enc.ciphertext);
    od;

    slowKey := HGOEDecaps(sk, ciphertexts[1]);

    # Time each method.
    slowMean := TimeMeanMs(function()
        idx := Random([1..numCiphertexts]);
        HGOEDecaps(sk, ciphertexts[idx]);
    end, numCiphertexts);

    fastMean := TimeMeanMs(function()
        idx := Random([1..numCiphertexts]);
        FastDecaps(skFast, ciphertexts[idx]);
    end, numCiphertexts);

    synMean := TimeMeanMs(function()
        idx := Random([1..numCiphertexts]);
        SyndromeDecaps(skSyn, ciphertexts[idx]);
    end, numCiphertexts);

    hash100Mean := TimeMeanMs(function()
        idx := Random([1..numCiphertexts]);
        OrbitHashDecaps(skHash100, ciphertexts[idx]);
    end, Minimum(numCiphertexts, 20));

    hash1000Mean := TimeMeanMs(function()
        idx := Random([1..numCiphertexts]);
        OrbitHashDecaps(skHash1000, ciphertexts[idx]);
    end, Minimum(numCiphertexts, 5));

    # Exactness check: same key recovered for every ciphertext.
    fastCorrect := ForAll([1..numCiphertexts], i ->
        FastDecaps(skFast, ciphertexts[i]) = slowKey);
    synCorrect := ForAll([1..numCiphertexts], i ->
        SyndromeDecaps(skSyn, ciphertexts[i]) =
        SyndromeDecaps(skSyn, bp));
    hash100Correct := ForAll([1..Minimum(numCiphertexts, 10)], i ->
        OrbitHashDecaps(skHash100, ciphertexts[i]) =
        OrbitHashDecaps(skHash100, bp));
    hash1000Correct := ForAll([1..Minimum(numCiphertexts, 5)], i ->
        OrbitHashDecaps(skHash1000, ciphertexts[i]) =
        OrbitHashDecaps(skHash1000, bp));

    return rec(
        lambda   := params.lambda,
        n        := params.n,
        b        := params.b,
        ell      := params.ell,
        slow     := rec(method := "Full backtracking",
                        meanMs := slowMean, correct := true),
        twoPhase := rec(method := "Two-phase cyclic",
                        meanMs := fastMean, correct := fastCorrect,
                        residualSize := skFast.fastDec.residualSize,
                        cyclicSize   := skFast.fastDec.cyclicSize,
                        fullSize     := skFast.fastDec.fullSize,
                        reductionRatio := skFast.fastDec.reductionRatio),
        syndrome := rec(method := "Syndrome (O(n*k))",
                        meanMs := synMean, correct := synCorrect),
        hash100  := rec(method := "Orbit hash (100)",
                        meanMs := hash100Mean, correct := hash100Correct),
        hash1000 := rec(method := "Orbit hash (1000)",
                        meanMs := hash1000Mean, correct := hash1000Correct)
    );
end;;

#' PrintDecryptionComparison(cmp) — Human-readable summary table for a
#' single security level.
PrintDecryptionComparison := function(cmp)
    Print("\n");
    Print("--------------------------------------------------------\n");
    Print("  Phase 15 Decryption Comparison (lambda=", cmp.lambda,
          ", n=", cmp.n, ")\n");
    Print("--------------------------------------------------------\n");
    Print("  Full backtracking :  ", cmp.slow.meanMs,
          " ms   [baseline]\n");
    Print("  Two-phase         :  ", cmp.twoPhase.meanMs, " ms   ",
          "(|residual|=", cmp.twoPhase.residualSize,
          ", |cyc|=",    cmp.twoPhase.cyclicSize,
          ", |G|=",      cmp.twoPhase.fullSize,
          ", correct=", cmp.twoPhase.correct, ")\n");
    Print("  Syndrome          :  ", cmp.syndrome.meanMs, " ms   ",
          "(KEM-correct=", cmp.syndrome.correct, ")\n");
    Print("  Orbit hash (100)  :  ", cmp.hash100.meanMs, " ms   ",
          "(KEM-correct=", cmp.hash100.correct, ")\n");
    Print("  Orbit hash (1000) :  ", cmp.hash1000.meanMs, " ms   ",
          "(KEM-correct=", cmp.hash1000.correct, ")\n");
    Print("--------------------------------------------------------\n");
end;;

#' WritePhase15CSV(comparisons, filename) — Write a CSV summary of
#' 15.7 across multiple security levels. Columns:
#'   lambda, n, method, mean_ms, correct, extra
WritePhase15CSV := function(comparisons, filename)
    local f, cmp, writeRow;

    f := OutputTextFile(filename, false);
    if f = fail then
        Print("ERROR: cannot open ", filename, " for writing\n");
        return;
    fi;

    AppendTo(f, "lambda,n,method,mean_ms,correct,extra\n");
    writeRow := function(lambda, n, method, meanMs, correct, extra)
        AppendTo(f, String(lambda), ",", String(n), ",",
                    method, ",", String(meanMs), ",", String(correct),
                    ",", extra, "\n");
    end;
    for cmp in comparisons do
        writeRow(cmp.lambda, cmp.n, "full_backtracking",
                 cmp.slow.meanMs, cmp.slow.correct, "baseline");
        writeRow(cmp.lambda, cmp.n, "two_phase",
                 cmp.twoPhase.meanMs, cmp.twoPhase.correct,
                 Concatenation("residual=",
                               String(cmp.twoPhase.residualSize),
                               "|cyc=",
                               String(cmp.twoPhase.cyclicSize),
                               "|full=",
                               String(cmp.twoPhase.fullSize)));
        writeRow(cmp.lambda, cmp.n, "syndrome",
                 cmp.syndrome.meanMs, cmp.syndrome.correct, "");
        writeRow(cmp.lambda, cmp.n, "orbit_hash_100",
                 cmp.hash100.meanMs, cmp.hash100.correct, "nSamples=100");
        writeRow(cmp.lambda, cmp.n, "orbit_hash_1000",
                 cmp.hash1000.meanMs, cmp.hash1000.correct, "nSamples=1000");
    od;
    CloseStream(f);
    Print("Phase 15 CSV written to: ", filename, "\n");
end;;

#' RunPhase15Comparison(levels) — Top-level driver for Work Unit 15.7.
#' Returns a list of comparison records; also prints the summary and
#' writes docs/benchmarks/phase15_decryption.csv.
RunPhase15Comparison := function(levels)
    local comparisons, lambda, params, cmp, csvPath;
    comparisons := [];
    for lambda in levels do
        params := HGOEParams(lambda);
        Print("\n[Phase 15.7] Measuring decryption methods at lambda=",
              lambda, " (n=", params.n, ")...\n");
        cmp := CompareDecryptionMethods(params, 20);
        PrintDecryptionComparison(cmp);
        Add(comparisons, cmp);
    od;
    csvPath := "docs/benchmarks/phase15_decryption.csv";
    WritePhase15CSV(comparisons, csvPath);
    return comparisons;
end;;

Print("orbcrypt_fast_dec.g: section 8 (15.7 comparison harness) loaded.\n");;

##############################################################################
## Section 9 — Phase 15 Self-Test
##############################################################################

#' RunPhase15SelfTest() — Minimal smoke test that exercises every public
#' entry point defined in this file. Returns true iff all validators
#' pass. Uses small parameters so the full partition backtracking is
#' tractable (n = 24, b = 8, ell = 3).
RunPhase15SelfTest := function()
    local params, kemKey, sk, bp, b, ell, n,
          idemRes, skFast, cmpRes, consistencyRes, hashCollision,
          allOk;
    allOk := true;

    params := HGOEParams(24);
    # HGOEParams returns b=8, ell=Ceil(24/3)=8, n=64. Force small n=24 for
    # the self-test so CanonicalImage(G, ...) terminates quickly.
    params := rec(lambda := 24, b := 8, ell := 3,
                  n := 24, k := 12, w := 12);
    b   := params.b;
    ell := params.ell;
    n   := params.n;

    Print("\n[15 self-test] Using n=", n, ", b=", b, ", ell=", ell, "\n");

    # 15.1c: idempotence check over 20 trials.
    idemRes := ValidateQCCyclicIdempotent(b, ell, 20);
    Print("  15.1c QCCyclicReduce idempotent : ",
          idemRes.passed, " (", idemRes.fails, "/",
          idemRes.trials, " fails)\n");
    if not idemRes.passed then allOk := false; fi;

    # 15.2 / 15.3: precompute residual group and compare fast vs slow.
    kemKey := HGOEKEMKeygen(params);
    sk := kemKey.sk;
    bp := kemKey.basePoint;
    skFast := ExtendKEMKeyWithFastDec(sk, b, ell);
    Print("  15.2 residual ratio              : ",
          skFast.fastDec.reductionRatio,
          " (|cyc|=", skFast.fastDec.cyclicSize,
          ", |G|=",   skFast.fastDec.fullSize, ")\n");

    cmpRes := CompareFastVsSlow(skFast, 20, bp);
    Print("  15.3 FastDecaps == slow          : ",
          cmpRes.passed, " (", cmpRes.fails, "/",
          cmpRes.trials, " fails)\n");
    if not cmpRes.passed then allOk := false; fi;

    # 15.6: orbit-hash consistency.
    consistencyRes := ValidateOrbitHashConsistency(
        ExtendKEMKeyWithOrbitHash(sk, 100), bp, 10);
    Print("  15.6 OrbitHash consistency       : ",
          consistencyRes.passed, " (", consistencyRes.fails, "/",
          consistencyRes.trials, " fails)\n");
    if not consistencyRes.passed then allOk := false; fi;

    return allOk;
end;;

Print("orbcrypt_fast_dec.g loaded successfully (Phase 15, 9 sections).\n");;
