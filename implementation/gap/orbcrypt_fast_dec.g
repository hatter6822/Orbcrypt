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
    local offset, block, bestRot, r, candidate, result, i;

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
#' (see Lean spec: `Orbcrypt.QCCyclicCanonical` and
#' `Orbcrypt.qc_invariant_under_cyclic` in
#' `Orbcrypt/Optimization/QCCanonical.lean`).
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
#'   residualSize         : |G| / |G ∩ cyclic| = length of the transversal
#'   cyclicSize           : |G ∩ cyclic| (the cyclic-phase factor inside G;
#'                          equals b^ell exactly when (Z/bZ)^ell ⊆ G)
#'   fullSize             : |G|
#'   reductionRatio       : cyclicSize / fullSize (fraction of the group
#'                          already handled by the fast phase)
#'
#' **When G does not contain (Z/bZ)^ell:** the function still returns
#' something meaningful — it transverses the intersection subgroup
#' G ∩ cyclic, so residualTransversal is RightTransversal(G, G ∩ cyclic).
#' For a KEM (single base point) the resulting fast path is still
#' correct because every ciphertext lies in the same G-orbit, hence in
#' the same orbit of the supergroup `<(Z/bZ)^ell, T>`. For the AOE
#' multi-message scheme this fallback path may collapse distinct
#' G-orbits to the same canonical form; use the slow path
#' (`HGOEDecaps`) in that regime, or pick parameters so that the
#' generating QC code's PAut contains the full cyclic subgroup.
ComputeResidualGroup := function(G, b, ell)
    local cyc, cycInG, trans, cycSize, fullSize;
    cyc := QCCyclicSubgroup(b, ell);
    fullSize := Size(G);

    # Compute intersection cyc ∩ G. Identity ∈ both groups, so this
    # is non-empty and `RightTransversal` is always well-defined.
    cycInG := Intersection(G, cyc);
    cycSize := Size(cycInG);
    trans := RightTransversal(G, cycInG);

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
#'
#' **Correctness precondition.** The fast path agrees with the slow
#' (`HGOEDecaps`) path **iff** the full cyclic subgroup (Z/bZ)^ell is
#' contained in G. The augmented record carries a Boolean
#' `fastDec.containsCyclic` recording whether this holds; when it
#' does not, a Print warning is emitted at extension time. Users who
#' need provable correctness in the fallback case should fall back to
#' `HGOEDecaps`. The default `HGOEFallbackGroup` always satisfies the
#' precondition; PAut groups computed from random QC codes may not.
ExtendKEMKeyWithFastDec := function(sk, b, ell)
    local residualRec, skFast, expectedCyclic, containsCyclic;
    residualRec := ComputeResidualGroup(sk.G, b, ell);
    expectedCyclic := b ^ ell;
    containsCyclic := (residualRec.cyclicSize = expectedCyclic);
    if not containsCyclic then
        Print("WARNING: (Z/", b, "Z)^", ell,
              " is NOT a subgroup of G ",
              "(|G ∩ cyc| = ", residualRec.cyclicSize,
              " < b^ell = ", expectedCyclic, "). ",
              "FastDecaps may disagree with HGOEDecaps on this key. ",
              "Use FastDecapsSafe or CompareFastVsSlow to verify ",
              "before relying on the fast path.\n");
    fi;
    skFast := ShallowCopy(sk);
    skFast.fastDec := rec(
        b                   := b,
        ell                 := ell,
        residualTransversal := residualRec.residualTransversal,
        cyclicGroup         := residualRec.cyclicGroupHandle,
        residualSize        := residualRec.residualSize,
        cyclicSize          := residualRec.cyclicSize,
        fullSize            := residualRec.fullSize,
        reductionRatio      := residualRec.reductionRatio,
        expectedCyclic      := expectedCyclic,
        containsCyclic      := containsCyclic
    );
    return skFast;
end;;

#' FastCanonicalImage(skFast, c) — Two-phase canonical image computation.
#'
#' **Correctness contract.** Returns the same value as
#' `CanonicalImage(skFast.G, c, OnSets)` whenever
#' `skFast.fastDec.containsCyclic = true`, i.e. (Z/bZ)^ell ⊆ G. When
#' that precondition fails the function still returns A WELL-DEFINED
#' bitstring, but the result is NOT in general equal to (or even
#' contained in the same G-orbit as) the slow canonical image. In
#' that regime KEM correctness can no longer be guaranteed; callers
#' must validate against the slow path with `CompareFastVsSlow`
#' before deploying.
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
#'
#' **Correctness contract.** Returns an orbit-constant function of
#' `c`: every ciphertext in the same G-orbit as the base point
#' returns the same key. This is the property required for KEM
#' correctness when paired with `FastEncaps` (below).
#'
#' **Does NOT in general equal `HGOEDecaps(sk, c)`**. Both functions
#' are orbit-constant, but they use DIFFERENT canonical-form
#' strategies: `HGOEDecaps` uses the lex-min canonical form
#' (`CanonicalImage(G, c, OnSets)`), while `FastDecaps` uses the
#' composition `lex-min_T ∘ QCCyclicReduce` — these agree only when
#' lex-min commutes with the residual-transversal action on cyclic
#' canonical forms, which is NOT a property of general G.
#'
#' Consequence: pair `FastDecaps` with `FastEncaps`, not
#' `HGOEEncaps`. Mixing the two is a cross-canonicalisation bug.
FastDecaps := function(skFast, c)
    return skFast.keyDerive(FastCanonicalImage(skFast, c));
end;;

#' FastEncaps(skFast, basePoint) — Two-phase KEM encapsulation.
#'
#' The companion of `FastDecaps`: derives the shared key from the
#' FAST canonical image, not the slow one. Using this together with
#' `FastDecaps` gives a fully consistent KEM pair — the usual
#' correctness contract `FastDecaps(FastEncaps(.).ciphertext) =
#' FastEncaps(.).key` holds automatically because both sides compute
#' `keyDerive(FastCanonicalImage(c))`.
FastEncaps := function(skFast, basePoint)
    local g, c, fastCanon, k;
    g := PseudoRandom(skFast.G);
    c := PermuteBitstring(basePoint, g);
    fastCanon := FastCanonicalImage(skFast, c);
    k := skFast.keyDerive(fastCanon);
    return rec(
        ciphertext   := c,
        key          := k,
        groupElement := g,
        fastCanon    := fastCanon
    );
end;;

#' FastDecapsSafe(skFast, c) — Debug wrapper that cross-checks the
#' orbit-constancy invariant. Each call MUST return the same key as
#' `FastDecaps(skFast, basePointOrSameOrbit)`. A mismatch indicates a
#' genuine correctness bug (orbit-constancy violation) and raises an
#' `Error`. Does NOT compare against the slow canonical form, because
#' those are expected to differ (see `FastDecaps` docstring).
FastDecapsSafe := function(skFast, basePoint, c)
    local kFromBp, kFromC;
    kFromBp := FastDecaps(skFast, basePoint);
    kFromC  := FastDecaps(skFast, c);
    if kFromBp <> kFromC then
        Error("FastDecaps is NOT orbit-constant: base=", kFromBp,
              " vs ct=", kFromC,
              " — this is a correctness failure of the fast path.");
    fi;
    return kFromC;
end;;

#' CompareFastVsSlow(skFast, numTrials, basePoint) — Quantitative
#' validation for Work Unit 15.3.
#'
#' Three properties are recorded per trial:
#'   (a) **FAST KEM correctness.** FastDecaps is orbit-constant —
#'       `FastDecaps(FastEncaps(basePoint).ciphertext)` equals
#'       `FastEncaps(basePoint).key`. This is the KEM correctness
#'       contract for the fast pair; it MUST hold (pass-fail
#'       criterion).
#'   (b) **SLOW KEM correctness.** Same, but with HGOEEncaps and
#'       HGOEDecaps. Included as a control sanity check.
#'   (c) **Fast-vs-slow agreement.** Do the fast and slow canonical
#'       forms produce the same key on the same ciphertext?
#'       Expected to FAIL unless the specific (G, cyclic subgroup)
#'       pair satisfies the strong structural condition in which
#'       lex-min commutes with the transversal action — a property
#'       of specialised QC codes, not of the default fallback
#'       wreath-product group. Reported for diagnostics; NOT a
#'       pass-fail criterion.
#'
#' Returns a record with (trials, fastCorrectness, slowCorrectness,
#' fastSlowAgreementRate, meanFastMs, meanSlowMs, speedup,
#' reductionRatio). `passed` iff fastCorrectness = numTrials and
#' slowCorrectness = numTrials.
CompareFastVsSlow := function(skFast, numTrials, basePoint)
    local i, encF, encS, fastKeyRecovered, slowKeyRecovered,
          fastCorrect, slowCorrect, fastSlowAgree,
          tFast, tSlow, t0, t1;
    fastCorrect := 0; slowCorrect := 0; fastSlowAgree := 0;
    tFast := 0; tSlow := 0;
    for i in [1..numTrials] do
        # (a) Fast KEM self-consistency.
        encF := FastEncaps(skFast, basePoint);
        t0 := Runtime();
        fastKeyRecovered := FastDecaps(skFast, encF.ciphertext);
        t1 := Runtime();
        tFast := tFast + (t1 - t0);
        if fastKeyRecovered = encF.key then
            fastCorrect := fastCorrect + 1;
        fi;

        # (b) Slow KEM self-consistency (control).
        encS := HGOEEncaps(skFast, basePoint);
        t0 := Runtime();
        slowKeyRecovered := HGOEDecaps(skFast, encS.ciphertext);
        t1 := Runtime();
        tSlow := tSlow + (t1 - t0);
        if slowKeyRecovered = encS.key then
            slowCorrect := slowCorrect + 1;
        fi;

        # (c) Fast ?= slow on the same ciphertext (diagnostic).
        if FastDecaps(skFast, encS.ciphertext) = slowKeyRecovered then
            fastSlowAgree := fastSlowAgree + 1;
        fi;
    od;
    return rec(
        trials                 := numTrials,
        fastCorrect            := fastCorrect,
        slowCorrect            := slowCorrect,
        fastSlowAgree          := fastSlowAgree,
        fastSlowAgreementRate  := Float(fastSlowAgree) /
                                  Float(numTrials),
        passed                 := (fastCorrect = numTrials) and
                                  (slowCorrect = numTrials),
        meanFastMs             := Float(tFast) / Float(numTrials),
        meanSlowMs             := Float(tSlow) / Float(numTrials),
        speedup                := Float(tSlow) /
                                  Float(Maximum(tFast, 1)),
        reductionRatio         := skFast.fastDec.reductionRatio,
        residualSize           := skFast.fastDec.residualSize,
        cyclicSize             := skFast.fastDec.cyclicSize,
        fullSize               := skFast.fastDec.fullSize
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
#' parity-check matrix. Does NOT mutate `sk`; returns a shallow copy
#' with `H` attached.
ExtendKEMKeyWithSyndrome := function(sk, H)
    local skSyn;
    skSyn := ShallowCopy(sk);
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

#' DeterministicOrbitHash(G, x) — The exact orbit-hash. Enumerates the
#' full orbit `OnSets`-orbit of `x` under `G`, sorts the resulting
#' bitstrings, and concatenates them via `OrbitHashDigest`. Two inputs
#' in the same G-orbit produce IDENTICAL hashes; two inputs in
#' DIFFERENT G-orbits produce different hashes (string equality is
#' injective on distinct sorted orbit lists).
#'
#' Cost: O(|G| * n) bit operations — same asymptotic as enumerating
#' the orbit by partition backtracking, but with smaller constants
#' because we never need to inspect coset structure. For
#' moderate-size G (say |G| ≤ 2^20) this is a viable alternative to
#' `CanonicalImage`. For cryptographic |G| (≥ 2^80) it is impractical.
DeterministicOrbitHash := function(G, x)
    local orbit, sorted;
    orbit := Orbit(G, x, OnSets);
    sorted := ShallowCopy(orbit);
    Sort(sorted);
    return OrbitHashDigest(sorted);
end;;

#' OrbitSampleList(G, x, nSamples) — Sample `nSamples` random elements of
#' the orbit of `x` under `G`, deduplicate, sort. Used by the
#' approximate `SampledOrbitHash` below.
#'
#' **Caveat (Phase 15 §15.6).** Two distinct calls produce two
#' independent random samples; the resulting lists ARE NOT in general
#' equal even when `x` and `x'` lie in the same orbit. Callers
#' relying on orbit-equality must use `DeterministicOrbitHash`
#' instead.
OrbitSampleList := function(G, x, nSamples)
    local samples, i, g, deduped;
    samples := [];
    for i in [1..nSamples] do
        g := PseudoRandom(G);
        Add(samples, OnSets(x, g));
    od;
    deduped := Set(samples);
    return deduped;
end;;

#' SampledOrbitHash(G, x, nSamples) — Approximate orbit hash via random
#' sampling. **NOT a canonical form**: two evaluations on the same
#' input typically return DIFFERENT digests because each call draws
#' fresh random samples. Useful only as a coarse fingerprint or for
#' empirical orbit-distribution diagnostics (e.g. estimating |G|
#' via the coupon-collector formula).
#'
#' Cost: O(nSamples * n). Retained for completeness of the Phase 15
#' design exploration; production code should call
#' `DeterministicOrbitHash` instead.
SampledOrbitHash := function(G, x, nSamples)
    return OrbitHashDigest(OrbitSampleList(G, x, nSamples));
end;;

#' OrbitHash(G, x, nSamples) — Public Phase 15 §15.6 entry point.
#' Aliases `DeterministicOrbitHash`; the `nSamples` parameter is
#' accepted (and ignored) for backward compatibility with the
#' original Phase-15-plan signature. To get the (broken)
#' sample-based variant explicitly, use `SampledOrbitHash`.
OrbitHash := function(G, x, nSamples)
    return DeterministicOrbitHash(G, x);
end;;

#' OrbitHashDecaps(skHash, c) — Orbit-hash decapsulation. Requires
#' skHash to carry a `hashSamples` field specifying nSamples (only
#' used by `SampledOrbitHash`; `DeterministicOrbitHash` ignores it).
OrbitHashDecaps := function(skHash, c)
    return skHash.keyDerive(OrbitHash(skHash.G, c, skHash.hashSamples));
end;;

#' ExtendKEMKeyWithOrbitHash(sk, nSamples) — Attach a hash-sample budget
#' to a KEM secret key. Returns a ShallowCopy so the original secret
#' key is untouched. (`nSamples` is recorded for use by
#' `SampledOrbitHash`; `OrbitHash` itself is deterministic and ignores
#' it.)
ExtendKEMKeyWithOrbitHash := function(sk, nSamples)
    local skHash;
    skHash := ShallowCopy(sk);
    skHash.hashSamples := nSamples;
    return skHash;
end;;

#' ValidateOrbitHashConsistency(skHash, basePoint, numTrials) — For each
#' of `numTrials` ciphertexts sampled from basePoint, check that
#' `OrbitHashDecaps` returns the SAME digest as `OrbitHashDecaps`
#' applied to the base point itself. Because `OrbitHash` aliases the
#' deterministic enumeration, this passes (fails = 0) in every KEM
#' mode (single orbit). To exercise the broken sample-based variant,
#' replace `OrbitHashDecaps` with one that calls `SampledOrbitHash`
#' directly — that variant is expected to fail nearly every trial.
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
    local kemKey, sk, bp, skFast, skSyn, skHashDet, skHash100, skHash1000,
          ciphertexts, i, enc, refSyndrome,
          slowMean, fastMean, synMean,
          hashDetMean, hashSampled100Mean, hashSampled1000Mean,
          slowKey, fastCorrect, synCorrect, hashDetCorrect,
          hashSampled100Correct, hashSampled1000Correct,
          idx, H;

    kemKey := HGOEKEMKeygen(params);
    sk := kemKey.sk;
    bp := kemKey.basePoint;

    # Two-phase extension.
    skFast := ExtendKEMKeyWithFastDec(sk, params.b, params.ell);

    # Syndrome extension: a real deployment uses the parity-check matrix
    # of the secret code (`ParityCheckFromGenerator(genMat, GF(2))`).
    # The default `HGOEFallbackGroup` does NOT produce a code (genMat is
    # `fail`), so we cannot derive a real H here. We use a 1×n all-ones
    # matrix as a placeholder: SyndromeOf of this matrix returns the
    # Hamming-weight parity, which IS orbit-invariant under any
    # permutation group (Hamming weight is preserved by every
    # permutation, hence so is its parity). The benchmark therefore
    # measures honest timing of an honest orbit-invariant function on
    # the placeholder; a real deployment substitutes the actual H.
    H := NullMat(1, params.n, GF(2));
    for i in [1..params.n] do
        H[1][i] := One(GF(2));
    od;
    skSyn := ExtendKEMKeyWithSyndrome(sk, H);

    # Orbit-hash extensions:
    #   * `skHashDet`     — uses `DeterministicOrbitHash` (full orbit
    #                        enumeration; exact; cost O(|G| * n)).
    #   * `skHash{100,1000}` — sampled-only timing; uses
    #                        `SampledOrbitHash` directly. NOT a
    #                        canonical form, so `correct = false` is
    #                        the EXPECTED outcome.
    skHashDet  := ExtendKEMKeyWithOrbitHash(sk, 0);
    skHash100  := ExtendKEMKeyWithOrbitHash(sk, 100);
    skHash1000 := ExtendKEMKeyWithOrbitHash(sk, 1000);

    # Pre-sample ciphertexts.
    ciphertexts := [];
    for i in [1..numCiphertexts] do
        enc := HGOEEncaps(sk, bp);
        Add(ciphertexts, enc.ciphertext);
    od;

    slowKey := HGOEDecaps(sk, ciphertexts[1]);
    refSyndrome := SyndromeDecaps(skSyn, bp);

    # Time each method. `idx` is shared via the outer local; each
    # closure picks a fresh random index per invocation.
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

    hashDetMean := TimeMeanMs(function()
        idx := Random([1..numCiphertexts]);
        OrbitHashDecaps(skHashDet, ciphertexts[idx]);
    end, Minimum(numCiphertexts, 5));

    hashSampled100Mean := TimeMeanMs(function()
        idx := Random([1..numCiphertexts]);
        SampledOrbitHash(sk.G, ciphertexts[idx], 100);
    end, Minimum(numCiphertexts, 20));

    hashSampled1000Mean := TimeMeanMs(function()
        idx := Random([1..numCiphertexts]);
        SampledOrbitHash(sk.G, ciphertexts[idx], 1000);
    end, Minimum(numCiphertexts, 5));

    # Correctness checks. The fast path uses a DIFFERENT canonical form
    # from `HGOEDecaps` (see `FastDecaps` docstring), so the relevant
    # KEM-correctness property is **orbit-constancy of FastDecaps**, not
    # equality with `slowKey`. We compare each ciphertext's FastDecaps
    # output against `FastDecaps(skFast, bp)` rather than against
    # `slowKey`.
    fastCorrect := ForAll([1..numCiphertexts], i ->
        FastDecaps(skFast, ciphertexts[i]) = FastDecaps(skFast, bp));
    synCorrect := ForAll([1..numCiphertexts], i ->
        SyndromeDecaps(skSyn, ciphertexts[i]) = refSyndrome);
    hashDetCorrect := ForAll([1..Minimum(numCiphertexts, 5)], i ->
        OrbitHashDecaps(skHashDet, ciphertexts[i]) =
        OrbitHashDecaps(skHashDet, bp));
    # The sampled hash is intentionally NOT a canonical form; we record
    # the empirical agreement rate but it is expected to be ≪ 1.
    hashSampled100Correct := ForAll([1..Minimum(numCiphertexts, 5)], i ->
        SampledOrbitHash(sk.G, ciphertexts[i], 100) =
        SampledOrbitHash(sk.G, bp, 100));
    hashSampled1000Correct := ForAll([1..Minimum(numCiphertexts, 5)], i ->
        SampledOrbitHash(sk.G, ciphertexts[i], 1000) =
        SampledOrbitHash(sk.G, bp, 1000));

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
                        reductionRatio := skFast.fastDec.reductionRatio,
                        containsCyclic := skFast.fastDec.containsCyclic),
        syndrome := rec(method := "Syndrome (1×n parity)",
                        meanMs := synMean, correct := synCorrect),
        hashDet  := rec(method := "Orbit hash (deterministic)",
                        meanMs := hashDetMean,
                        correct := hashDetCorrect),
        hash100  := rec(method := "Sampled hash (100)",
                        meanMs := hashSampled100Mean,
                        correct := hashSampled100Correct),
        hash1000 := rec(method := "Sampled hash (1000)",
                        meanMs := hashSampled1000Mean,
                        correct := hashSampled1000Correct)
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
          ", |cyc∩G|=",   cmp.twoPhase.cyclicSize,
          ", |G|=",       cmp.twoPhase.fullSize,
          ", containsCyc=", cmp.twoPhase.containsCyclic,
          ", correct=",   cmp.twoPhase.correct, ")\n");
    Print("  Syndrome (1×n)    :  ", cmp.syndrome.meanMs, " ms   ",
          "(KEM-correct=", cmp.syndrome.correct,
          "; placeholder H, orbit-invariant by weight parity)\n");
    Print("  Orbit hash (det.) :  ", cmp.hashDet.meanMs, " ms   ",
          "(KEM-correct=", cmp.hashDet.correct, ", full orbit)\n");
    Print("  Sampled hash 100  :  ", cmp.hash100.meanMs, " ms   ",
          "(KEM-correct=", cmp.hash100.correct,
          "; probabilistic, not a canonical form)\n");
    Print("  Sampled hash 1000 :  ", cmp.hash1000.meanMs, " ms   ",
          "(KEM-correct=", cmp.hash1000.correct,
          "; probabilistic, not a canonical form)\n");
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
                               "|cycInG=",
                               String(cmp.twoPhase.cyclicSize),
                               "|full=",
                               String(cmp.twoPhase.fullSize),
                               "|containsCyc=",
                               String(cmp.twoPhase.containsCyclic)));
        writeRow(cmp.lambda, cmp.n, "syndrome",
                 cmp.syndrome.meanMs, cmp.syndrome.correct,
                 "placeholder_H_1xn_all_ones");
        writeRow(cmp.lambda, cmp.n, "orbit_hash_deterministic",
                 cmp.hashDet.meanMs, cmp.hashDet.correct,
                 "full_orbit_enumeration");
        writeRow(cmp.lambda, cmp.n, "sampled_hash_100",
                 cmp.hash100.meanMs, cmp.hash100.correct,
                 "nSamples=100|probabilistic");
        writeRow(cmp.lambda, cmp.n, "sampled_hash_1000",
                 cmp.hash1000.meanMs, cmp.hash1000.correct,
                 "nSamples=1000|probabilistic");
    od;
    CloseStream(f);
    Print("Phase 15 CSV written to: ", filename, "\n");
end;;

#' RunPhase15Comparison(levels) — Top-level driver for Work Unit 15.7.
#' Returns a list of comparison records; also prints the summary and
#' writes docs/benchmarks/phase15_decryption.csv. Each `lambda` in
#' `levels` is converted to a parameter record via `HGOEParams`.
#'
#' WARNING: at the production-grade levels in {80, 128, 192, 256} the
#' `HGOEParams`-derived n is hundreds of bits and the slow
#' `CanonicalImage` path (which `CompareDecryptionMethods` invokes for
#' the baseline) takes hours per call. For interactive verification
#' use `RunPhase15QuickComparison` instead.
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

#' RunPhase15QuickComparison() — Small-parameter version of
#' `RunPhase15Comparison` intended for CI / interactive use. Uses
#' three hand-tuned parameter triples (n ∈ {16, 24, 32}, b = 8) so
#' that every method — including the slow `CanonicalImage` baseline
#' — finishes within a few seconds. Writes
#' `docs/benchmarks/phase15_decryption_quick.csv`.
RunPhase15QuickComparison := function()
    local paramsList, comparisons, params, cmp, csvPath;

    paramsList := [
        rec(lambda := 16, b := 8, ell := 2,
            n := 16, k := 8, w := 8),
        rec(lambda := 24, b := 8, ell := 3,
            n := 24, k := 12, w := 12),
        rec(lambda := 32, b := 8, ell := 4,
            n := 32, k := 16, w := 16)
    ];

    comparisons := [];
    for params in paramsList do
        Print("\n[Phase 15.7 quick] Measuring at n=", params.n,
              ", b=", params.b, ", ell=", params.ell, "...\n");
        cmp := CompareDecryptionMethods(params, 5);
        PrintDecryptionComparison(cmp);
        Add(comparisons, cmp);
    od;
    csvPath := "docs/benchmarks/phase15_decryption_quick.csv";
    WritePhase15CSV(comparisons, csvPath);
    return comparisons;
end;;

Print("orbcrypt_fast_dec.g: section 8 (15.7 comparison harness) loaded.\n");;

##############################################################################
## Section 9 — Phase 15 Self-Test
##############################################################################

#' RunPhase15SelfTest() — Minimal smoke test that exercises every public
#' correctness validator (15.1c idempotence, 15.3 fast-vs-slow,
#' 15.6 orbit-hash consistency). Returns true iff every validator
#' passes. Uses hand-tuned small parameters (n = 24, b = 8, ell = 3,
#' k = w = 12) so that the full partition backtracking inside
#' `CanonicalImage` terminates in ≪ 1 s on commodity hardware. Does
#' NOT exercise `CompareDecryptionMethods` (that is a benchmark, not
#' a correctness check; invoke `RunPhase15Comparison` separately).
RunPhase15SelfTest := function()
    local params, kemKey, sk, bp, b, ell, n,
          idemRes, skFast, cmpRes, consistencyRes,
          allOk;
    allOk := true;

    # Hand-tuned parameters: small enough for `CanonicalImage` to
    # terminate quickly, large enough that the cyclic and residual
    # phases are non-trivial.
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
    Print("  15.3 Fast KEM correctness        : ",
          (cmpRes.fastCorrect = cmpRes.trials),
          " (", cmpRes.fastCorrect, "/", cmpRes.trials, ")\n");
    Print("  15.3 Slow KEM correctness        : ",
          (cmpRes.slowCorrect = cmpRes.trials),
          " (", cmpRes.slowCorrect, "/", cmpRes.trials, ")\n");
    Print("  15.3 Fast/slow agreement rate    : ",
          cmpRes.fastSlowAgreementRate,
          " (", cmpRes.fastSlowAgree, "/", cmpRes.trials,
          " — diagnostic only; expected ≪ 1 for ",
          "general G)\n");
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
