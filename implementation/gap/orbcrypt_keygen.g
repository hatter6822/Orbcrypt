#
# Orbcrypt  - Symmetry Keyed Encryption
# Copyright (C) 2026  Adam Hall
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
#

##############################################################################
##
## orbcrypt_keygen.g — HGOE Key Generation (7-stage pipeline)
##
## Implements the full HGOE.Setup(1^lambda) pipeline from DEVELOPMENT.md §6.2.1:
##   Stage 1: Parameter derivation
##   Stage 2: Quasi-cyclic code generation
##   Stage 3: Automorphism group computation (PAut via GUAVA)
##   Stage 4: Orbit representative harvesting
##   Stage 5: Lookup table construction
##   Stage 6: Secret key assembly
##   Stage 7: Public parameter assembly
##
## Bitstring representation: A bitstring of length n with Hamming weight w is
## stored as a SORTED list of w position indices (the "support set"), i.e. the
## set of positions where the bit is 1. Example: [0,1,0,1,1] -> [2,4,5].
## The permutation group S_n acts on these via OnSets: g . S = {g(i) : i in S}.
##
## Dependencies: GAP 4.12+, packages: images (>=1.3.0), GUAVA (>=3.15), IO
##
##############################################################################

LoadPackage("GUAVA");;
LoadPackage("images");;

##############################################################################
## Bitstring Representation Utilities
##############################################################################

#' SupportToList(support, n) — Convert support set to list representation.
#' E.g., SupportToList([2,4,5], 5) -> [0,1,0,1,1].
SupportToList := function(support, n)
    local bits, pos;
    bits := ListWithIdenticalEntries(n, 0);
    for pos in support do
        bits[pos] := 1;
    od;
    return bits;
end;;

#' ListToSupport(bits) — Convert list representation to support set.
#' E.g., ListToSupport([0,1,0,1,1]) -> [2,4,5].
ListToSupport := function(bits)
    return Filtered([1..Length(bits)], i -> bits[i] = 1);
end;;

#' HammingWeight(x) — Compute Hamming weight of a support-set bitstring.
#' For support sets, the weight is just the length of the set.
HammingWeight := function(x)
    return Length(x);
end;;

#' HammingWeightList(bits) — Compute Hamming weight of a list-form bitstring.
HammingWeightList := function(bits)
    return Number(bits, b -> b = 1);
end;;

##############################################################################
## Stage 1 — Parameter Derivation
##############################################################################

#' HGOEParams(lambda) — Derive HGOE parameters from security parameter.
#'
#' @param lambda  Security parameter (e.g. 80, 128, 192, 256).
#' @return  Record with fields: lambda, b, ell, n, k, w.
#'
#' Uses block length b=8 and ell = Ceil(lambda / Log2(b)) = Ceil(lambda/3).
#' n = b * ell, k = floor(n/2), w = floor(n/2).
#'
HGOEParams := function(lambda)
    local b, ell, n, k, w;

    b   := 8;
    ell := Int(lambda / 3);
    if lambda mod 3 <> 0 then
        ell := ell + 1;
    fi;
    n := b * ell;
    k := Int(n / 2);
    w := Int(n / 2);

    return rec(
        lambda := lambda,
        b      := b,
        ell    := ell,
        n      := n,
        k      := k,
        w      := w
    );
end;;

##############################################################################
## Stage 2 — Quasi-Cyclic Code Generation
##############################################################################

#' RandomCirculantMatrix(b, F) — Generate a random b x b circulant matrix
#' over the field F.
RandomCirculantMatrix := function(b, F)
    local firstRow, mat, i, j;

    firstRow := List([1..b], i -> Random(F));
    mat := NullMat(b, b, F);
    for i in [1..b] do
        for j in [1..b] do
            mat[i][j] := firstRow[((j - i) mod b) + 1];
        od;
    od;

    return mat;
end;;

#' HGOEGenerateCode(params) — Generate a permutation group for HGOE.
#'
#' Stages 2-3 of the HGOE pipeline. Uses the block-cyclic wreath-product
#' construction by default, which provides |G| = b^ell >= 2^lambda with
#' instant computation.
#'
#' The full QC code + PAut approach (DEVELOPMENT.md §6.2.1) is available
#' via HGOEGenerateCodeQC() but is impractically slow in GAP's GUAVA
#' package for n > 20. A production implementation would use optimized
#' C/C++ code for PAut computation (Leon's algorithm or partition
#' backtracking). See Phase 14 for optimization plans.
#'
HGOEGenerateCode := function(params)
    return HGOEFallbackGroup(params);
end;;

#' HGOEGenerateCodeQC(params) — Full QC code approach (slow, for small n only).
#'
#' Tries up to 5 random QC codes; falls back to wreath-product if none
#' achieve |G| >= 2^lambda. WARNING: GUAVA's AutomorphismGroup is very
#' slow for n > 20. Use only for validation at small parameter sizes.
#'
HGOEGenerateCodeQC := function(params)
    local F, b, ell, n, k, genMat, blocks, i, j, bi, bj,
          code, G, groupOrder, log2Order, attempt;

    F := GF(2);
    b := params.b;
    ell := params.ell;
    n := params.n;
    k := params.k;

    for attempt in [1..5] do
        blocks := List([1..ell], i -> RandomCirculantMatrix(b, F));

        genMat := NullMat(k, n, F);
        for i in [1..k] do
            for j in [1..n] do
                bi := Int((i - 1) / b) + 1;
                bj := Int((j - 1) / b) + 1;
                if bi <= ell and bj <= ell then
                    genMat[i][j] := blocks[((bi + bj - 2) mod ell) + 1]
                                    [((i - 1) mod b) + 1]
                                    [((j - 1) mod b) + 1];
                fi;
            od;
        od;

        if RankMat(genMat) < k then
            continue;
        fi;

        code := GeneratorMatCode(genMat, F);
        G := AutomorphismGroup(code);
        groupOrder := Size(G);
        log2Order := Log2(Float(groupOrder));

        if log2Order >= Float(params.lambda) then
            return rec(
                genMat     := genMat,
                code       := code,
                G          := G,
                groupOrder := groupOrder,
                log2Order  := log2Order,
                attempt    := attempt
            );
        fi;
    od;

    return HGOEFallbackGroup(params);
end;;

##############################################################################
## Fallback Group Construction
##############################################################################

#' HGOEFallbackGroup(params) — Fallback when QC codes don't yield large
#' enough automorphism groups. Uses cyclic shifts within blocks.
#' Produces |G| = b^ell >= 2^(3*ell) >= 2^lambda. Acceptable for
#' benchmarking but NOT cryptographically valid.
HGOEFallbackGroup := function(params)
    local n, b, ell, G, gens, i, cyc, perm_list, groupOrder, log2Order;

    n := params.n;
    b := params.b;
    ell := params.ell;
    gens := [];

    for i in [1..ell] do
        # Cyclic shift of block i: positions ((i-1)*b+1) .. (i*b)
        perm_list := [1..n];
        perm_list[(i-1)*b + 1] := (i-1)*b + b;
        for cyc in [2..b] do
            perm_list[(i-1)*b + cyc] := (i-1)*b + cyc - 1;
        od;
        Add(gens, PermList(perm_list));
    od;

    # Add block transposition for extra structure
    if ell >= 2 then
        perm_list := [1..n];
        for cyc in [1..b] do
            perm_list[cyc] := b + cyc;
            perm_list[b + cyc] := cyc;
        od;
        Add(gens, PermList(perm_list));
    fi;

    G := Group(gens);
    groupOrder := Size(G);
    log2Order := Log2(Float(groupOrder));

    return rec(
        genMat     := fail,
        code       := fail,
        G          := G,
        groupOrder := groupOrder,
        log2Order  := log2Order,
        attempt    := -1
    );
end;;

##############################################################################
## Stage 4 — Orbit Representative Harvesting
##############################################################################

#' RandomWeightWSupport(n, w) — Sample a random weight-w support set.
#' Returns a sorted list of w positions from {1..n} chosen uniformly.
RandomWeightWSupport := function(n, w)
    local positions, i, j, tmp;

    # Fisher-Yates partial shuffle
    positions := [1..n];
    for i in [1..w] do
        j := Random([i..n]);
        tmp := positions[i];
        positions[i] := positions[j];
        positions[j] := tmp;
    od;

    return Set(positions{[1..w]});
end;;

#' HGOEHarvestReps(G, n, w, numReps) — Harvest distinct orbit representatives
#' using canonical images under G via the images package.
HGOEHarvestReps := function(G, n, w, numReps)
    local reps, canonImages, canonSet, x, cx, samples, maxSamples;

    reps := [];
    canonImages := [];
    canonSet := [];
    samples := 0;
    maxSamples := numReps * 200;

    while Length(reps) < numReps and samples < maxSamples do
        samples := samples + 1;
        x := RandomWeightWSupport(n, w);
        cx := CanonicalImage(G, x, OnSets);

        if not cx in canonSet then
            Add(reps, x);
            Add(canonImages, cx);
            Add(canonSet, cx);
        fi;
    od;

    if Length(reps) < numReps then
        Print("WARNING: Found ", Length(reps), "/", numReps,
              " distinct orbits (", samples, " samples)\n");
    fi;

    return rec(
        reps        := reps,
        canonImages := canonImages,
        numFound    := Length(reps),
        samples     := samples
    );
end;;

##############################################################################
## Stages 5-7 — Assembly
##############################################################################

#' HGOEKeygen(params, numMessages) — Full HGOE key generation pipeline.
HGOEKeygen := function(params, numMessages)
    local codeResult, G, harvest, lookupTable, i, sk, pk;

    # Stages 2-3: Generate code and compute automorphism group
    codeResult := HGOEGenerateCode(params);
    G := codeResult.G;

    Print("Key generation: |G| = ", codeResult.groupOrder,
          " (log2 = ", codeResult.log2Order, ")\n");

    # Stage 4: Harvest orbit representatives
    harvest := HGOEHarvestReps(G, params.n, params.w, numMessages);

    Print("Harvested ", harvest.numFound, " distinct orbits ",
          "from ", harvest.samples, " samples\n");

    # Stage 5: Build lookup table (canonical image -> message index)
    lookupTable := NewDictionary(harvest.canonImages[1], true);
    for i in [1..harvest.numFound] do
        AddDictionary(lookupTable, harvest.canonImages[i], i);
    od;

    # Stages 6-7: Assemble secret and public keys
    sk := rec(
        G           := G,
        lookupTable := lookupTable,
        canonImages := harvest.canonImages,
        n           := params.n,
        w           := params.w,
        keyDerive   := function(canon) return canon; end
    );

    pk := rec(
        n        := params.n,
        w        := params.w,
        numMsgs  := harvest.numFound,
        reps     := harvest.reps
    );

    return rec(
        sk       := sk,
        pk       := pk,
        params   := params,
        metadata := rec(
            groupOrder  := codeResult.groupOrder,
            log2Order   := codeResult.log2Order,
            numGens     := Length(GeneratorsOfGroup(G)),
            attempt     := codeResult.attempt,
            harvestCost := harvest.samples
        )
    );
end;;

##############################################################################
## KEM Key Generation (single base point)
##############################################################################

#' HGOEKEMKeygen(params) — Generate a KEM key (single base point).
HGOEKEMKeygen := function(params)
    local codeResult, G, x, cx;

    codeResult := HGOEGenerateCode(params);
    G := codeResult.G;

    x := RandomWeightWSupport(params.n, params.w);
    cx := CanonicalImage(G, x, OnSets);

    return rec(
        sk := rec(
            G          := G,
            basePoint  := x,
            canonBase  := cx,
            n          := params.n,
            w          := params.w,
            keyDerive  := function(canon) return canon; end
        ),
        basePoint := x,
        metadata  := rec(
            groupOrder  := codeResult.groupOrder,
            log2Order   := codeResult.log2Order,
            numGens     := Length(GeneratorsOfGroup(G)),
            attempt     := codeResult.attempt
        )
    );
end;;

Print("orbcrypt_keygen.g loaded successfully.\n");;
