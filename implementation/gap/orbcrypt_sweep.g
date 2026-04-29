#
# Orbcrypt  - Symmetry Keyed Encryption
# Copyright (C) 2026  Adam Hall
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
#

##############################################################################
##
## orbcrypt_sweep.g — Parameter Space Exploration (Phase 14, Work Unit 14.1)
##
## Systematically varies the HGOE parameter space beyond the default
## b = 8 construction used in Phase 11. For each security level
## lambda in {80, 128, 192, 256} the script sweeps:
##
##   b   in {4, 8, 16, 32}         (block size)
##   k/n in {1/4, 1/3, 1/2}        (code rate — QC generator parameter)
##   w/n in {1/3, 1/2, 2/3}        (target Hamming weight)
##
## ell is derived as Ceil(lambda / Log2(b)) so that the fallback group
## satisfies log2(|G|) >= lambda. n = b * ell.
##
## For each (lambda, b, w/n, k/n) configuration it measures:
##   - log2(|G|) from the fallback group constructor
##   - number of distinct orbits at target weight from `numSamples` draws
##   - mean canonical image computation time (proxy for decryption cost)
##   - mean key generation time (single KEM base point)
##
## Outputs are written to:
##   docs/benchmarks/results_<lambda>.csv     — per-level sweep
##   docs/benchmarks/comparison.csv           — cross-scheme comparison
##
## Requires: orbcrypt_keygen.g, orbcrypt_kem.g, orbcrypt_bench.g
##
## Usage (from project root):
##   echo 'Read("implementation/gap/orbcrypt_keygen.g");; \
##         Read("implementation/gap/orbcrypt_kem.g");; \
##         Read("implementation/gap/orbcrypt_bench.g");; \
##         Read("implementation/gap/orbcrypt_sweep.g");; \
##         RunFullSweep();; QUIT;' | gap -q -b
##
##############################################################################

##############################################################################
## Parameter derivation under a variable block size
##############################################################################

#' SweepParams(lambda, b, wFrac, kFrac) — Derive a parameter record for the
#' sweep. wFrac and kFrac are the target fractions of n (e.g. 1/2).
#'
#' @return  Record with fields lambda, b, ell, n, k, w, log2bFactor.
#'
SweepParams := function(lambda, b, wFrac, kFrac)
    local log2b, ell, n, k, w;

    # ell = Ceil(lambda / Log2(b)); forced to be >= 2 so the fallback
    # group can add a block-swap generator.
    log2b := Log2(Float(b));
    ell := Int(Float(lambda) / log2b);
    if Float(ell) * log2b < Float(lambda) then
        ell := ell + 1;
    fi;
    if ell < 2 then
        ell := 2;
    fi;

    n := b * ell;
    w := Maximum(1, Int(Float(n) * wFrac));
    k := Maximum(1, Int(Float(n) * kFrac));

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
## Per-configuration measurement
##############################################################################

#' MeasureConfiguration(params, numSamples, numTrials) — Time one sweep point.
#'
#' Returns a record with:
#'   log2G, numOrbits, canonMs, keygenMs, passed, numGens.
#'
MeasureConfiguration := function(params, numSamples, numTrials)
    local codeResult, G, n, w, canonSet, x, cx, i,
          canonTime, keygenTime, t0, t1, passed;

    codeResult := HGOEFallbackGroup(params);
    G  := codeResult.G;
    n  := params.n;
    w  := params.w;

    passed := codeResult.log2Order >= Float(params.lambda);

    # Orbit count: sample numSamples weight-w supports and count distinct
    # canonical images.
    canonSet := [];
    canonTime := 0;
    for i in [1..numSamples] do
        x := RandomWeightWSupport(n, w);
        t0 := Runtime();
        cx := CanonicalImage(G, x, OnSets);
        t1 := Runtime();
        canonTime := canonTime + (t1 - t0);
        if not cx in canonSet then
            Add(canonSet, cx);
        fi;
    od;

    # Keygen timing: single KEM base point per trial.
    keygenTime := 0;
    for i in [1..numTrials] do
        t0 := Runtime();
        HGOEKEMKeygen(params);
        t1 := Runtime();
        keygenTime := keygenTime + (t1 - t0);
    od;

    return rec(
        log2G     := codeResult.log2Order,
        groupOrder := codeResult.groupOrder,
        numOrbits := Length(canonSet),
        canonMs   := Float(canonTime) / Float(numSamples),
        keygenMs  := Float(keygenTime) / Float(numTrials),
        passed    := passed,
        numGens   := Length(GeneratorsOfGroup(G))
    );
end;;

##############################################################################
## Recommendation-tier parameter sets (cf. docs/PARAMETERS.md §6)
##############################################################################

#' TierParams(lambda, tier) — Parameter record for a named recommendation
#' tier. `tier` in {"aggressive", "balanced", "conservative"}.
#'
#' - aggressive   : b = 8, ell = ceil(lambda/3)  (Phase 11 baseline).
#' - balanced     : b = 4, n = 4 * lambda, ell = lambda.
#' - conservative : b = 4, n = 8 * lambda, ell = 2 * lambda.
#'
#' Weight and rate are fixed at n/2.
#'
TierParams := function(lambda, tier)
    local b, ell, n, k, w;

    if tier = "aggressive" then
        b := 8;
        ell := Int(lambda / 3);
        if lambda mod 3 <> 0 then ell := ell + 1; fi;
    elif tier = "balanced" then
        b := 4;
        ell := lambda;
    elif tier = "conservative" then
        b := 4;
        ell := 2 * lambda;
    else
        Error("TierParams: unknown tier ", tier);
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
        w      := w,
        tier   := tier
    );
end;;

##############################################################################
## Per-level sweep
##############################################################################

#' SweepLevel(lambda, numSamples, numTrials) — Sweep one security level.
#'
#' Varies b in {4, 8, 16, 32}, w/n in {1/3, 1/2, 2/3}, k/n in {1/4, 1/3, 1/2}
#' (36 configurations per level) plus three tier-pinned rows (aggressive,
#' balanced, conservative) at w = k = n/2.
#'
#' @return  List of per-configuration records.
#'
SweepLevel := function(lambda, numSamples, numTrials)
    local blockSizes, weights, rates, rows, b, wFrac, kFrac,
          params, meas, row, tierName, tierParams, tierMeas;

    blockSizes := [4, 8, 16, 32];
    weights    := [Float(1)/Float(3), Float(1)/Float(2), Float(2)/Float(3)];
    rates      := [Float(1)/Float(4), Float(1)/Float(3), Float(1)/Float(2)];
    rows := [];

    Print("============================================================\n");
    Print("Sweeping lambda = ", lambda, "\n");
    Print("============================================================\n");
    Print(String("b", -4), String("ell", -5),
          String("n", -6), String("k", -6),
          String("w", -6),
          String("log2|G|", -10), String("orbits", -8),
          String("canon", -10), String("keygen", -10),
          String("pass", -6), "\n");
    Print("------------------------------------------------------------\n");

    for b in blockSizes do
        for wFrac in weights do
            for kFrac in rates do
                params := SweepParams(lambda, b, wFrac, kFrac);
                meas := MeasureConfiguration(params, numSamples, numTrials);

                row := rec(
                    lambda     := lambda,
                    b          := params.b,
                    ell        := params.ell,
                    n          := params.n,
                    k          := params.k,
                    w          := params.w,
                    wFrac      := wFrac,
                    kFrac      := kFrac,
                    log2G      := meas.log2G,
                    numOrbits  := meas.numOrbits,
                    canonMs    := meas.canonMs,
                    keygenMs   := meas.keygenMs,
                    passed     := meas.passed,
                    numGens    := meas.numGens
                );
                Add(rows, row);

                Print(String(String(params.b), -4),
                      String(String(params.ell), -5),
                      String(String(params.n), -6),
                      String(String(params.k), -6),
                      String(String(params.w), -6),
                      String(String(Int(meas.log2G)), -10),
                      String(String(meas.numOrbits), -8),
                      String(Concatenation(String(Int(meas.canonMs)), "ms"), -10),
                      String(Concatenation(String(Int(meas.keygenMs)), "ms"), -10),
                      String(String(meas.passed), -6), "\n");
            od;
        od;
    od;

    # Tier-pinned rows for the docs/PARAMETERS.md §6 recommendations.
    for tierName in ["aggressive", "balanced", "conservative"] do
        tierParams := TierParams(lambda, tierName);
        tierMeas := MeasureConfiguration(tierParams, numSamples, numTrials);
        row := rec(
            lambda     := lambda,
            b          := tierParams.b,
            ell        := tierParams.ell,
            n          := tierParams.n,
            k          := tierParams.k,
            w          := tierParams.w,
            wFrac      := Float(1)/Float(2),
            kFrac      := Float(1)/Float(2),
            log2G      := tierMeas.log2G,
            numOrbits  := tierMeas.numOrbits,
            canonMs    := tierMeas.canonMs,
            keygenMs   := tierMeas.keygenMs,
            passed     := tierMeas.passed,
            numGens    := tierMeas.numGens,
            tier       := tierName
        );
        Add(rows, row);
        Print("[tier=", tierName, "] ",
              String(String(tierParams.b), -4),
              String(String(tierParams.ell), -5),
              String(String(tierParams.n), -6),
              String(String(tierParams.k), -6),
              String(String(tierParams.w), -6),
              String(String(Int(tierMeas.log2G)), -10),
              String(String(tierMeas.numOrbits), -8),
              String(Concatenation(String(Int(tierMeas.canonMs)), "ms"), -10),
              String(Concatenation(String(Int(tierMeas.keygenMs)), "ms"), -10),
              String(String(tierMeas.passed), -6), "\n");
    od;

    Print("============================================================\n\n");
    return rows;
end;;

##############################################################################
## CSV writer
##############################################################################

#' FracToString(f) — Render a rational fraction (e.g. 1/3) as "1/3".
FracToString := function(f)
    if f > Float(0.65) then return "2/3"; fi;
    if f > Float(0.45) then return "1/2"; fi;
    if f > Float(0.30) then return "1/3"; fi;
    if f > Float(0.20) then return "1/4"; fi;
    return String(f);
end;;

#' WriteSweepCSV(rows, filename) — Write a per-level sweep CSV.
WriteSweepCSV := function(rows, filename)
    local f, row;

    f := OutputTextFile(filename, false);
    if f = fail then
        Print("ERROR: Cannot open ", filename, " for writing\n");
        return;
    fi;

    # Header
    AppendTo(f, "lambda,b,ell,n,k,w,w_frac,k_frac,log2_G,num_orbits,");
    AppendTo(f, "canon_ms,keygen_ms,num_gens,passed,tier,status\n");

    for row in rows do
        AppendTo(f, String(row.lambda), ",");
        AppendTo(f, String(row.b), ",");
        AppendTo(f, String(row.ell), ",");
        AppendTo(f, String(row.n), ",");
        AppendTo(f, String(row.k), ",");
        AppendTo(f, String(row.w), ",");
        AppendTo(f, FracToString(row.wFrac), ",");
        AppendTo(f, FracToString(row.kFrac), ",");
        AppendTo(f, String(row.log2G), ",");
        AppendTo(f, String(row.numOrbits), ",");
        AppendTo(f, String(row.canonMs), ",");
        AppendTo(f, String(row.keygenMs), ",");
        AppendTo(f, String(row.numGens), ",");
        AppendTo(f, String(row.passed), ",");
        if IsBound(row.tier) then
            AppendTo(f, row.tier, ",");
        else
            AppendTo(f, "sweep,");
        fi;
        AppendTo(f, "measured\n");
    od;

    CloseStream(f);
    Print("CSV written to: ", filename, "\n");
end;;

##############################################################################
## Comparison table (scheme cross-comparison)
##############################################################################

#' WriteComparisonCSV(hgoe128, filename) — Cross-scheme comparison data.
#'
#' The non-HGOE rows are canonical literature values (see
#' docs/PARAMETERS.md §3 for citations). The HGOE row uses the lambda=128
#' measurement from RunFullSweep().
#'
WriteComparisonCSV := function(hgoe128, filename)
    local f;

    f := OutputTextFile(filename, false);
    if f = fail then
        Print("ERROR: Cannot open ", filename, " for writing\n");
        return;
    fi;

    AppendTo(f, "scheme,type,key_bytes,ct_bytes,enc_us,dec_us,");
    AppendTo(f, "pq_secure,assumption,source\n");

    # Literature values — see docs/PARAMETERS.md §3 for citations.
    AppendTo(f, "AES-256-GCM,symmetric,32,n+28,0.05,0.05,no,none,NIST_SP800-38D\n");
    AppendTo(f, "Kyber-768,lattice-KEM,2400,1088,30,25,yes,MLWE,NIST_FIPS203\n");
    AppendTo(f, "BIKE-L3,code-KEM,3114,3114,100,200,yes,QC-MDPC,NIST_Round4\n");
    AppendTo(f, "HQC-256,code-KEM,7245,14469,300,500,yes,QC-HQC,NIST_Round4\n");
    AppendTo(f, "Classic_McEliece_348864,code-KEM,261120,96,100,150,yes,Goppa,NIST_Round4\n");
    AppendTo(f, "LESS-L1,code-sig,13900,5000,N/A,N/A,yes,PermCodeEquiv,NIST_OnRamp\n");

    if hgoe128 <> fail then
        AppendTo(f, "HGOE-128,orbit-KEM,32,");
        AppendTo(f, String(Int(hgoe128.n / 8)), ",");
        AppendTo(f, String(Int(hgoe128.encapsMs * Float(1000))), ",");
        AppendTo(f, String(Int(hgoe128.decapsMs * Float(1000))), ",");
        AppendTo(f, "conjectured,CE-OIA,Orbcrypt_Phase11\n");
    fi;

    CloseStream(f);
    Print("CSV written to: ", filename, "\n");
end;;

##############################################################################
## Top-level driver
##############################################################################

#' RunFullSweep(numSamples, numTrials) — Full sweep across all levels.
#'
#' Default (numSamples=20, numTrials=3) takes ~30 minutes end-to-end on a
#' single core at the largest parameters (b=4 at lambda=256 has n=512 with
#' 128 generators). Use smaller (5, 1) for a fast smoke test.
#'
#' Writes:
#'   docs/benchmarks/results_80.csv
#'   docs/benchmarks/results_128.csv
#'   docs/benchmarks/results_192.csv
#'   docs/benchmarks/results_256.csv
#'   docs/benchmarks/comparison.csv
#'
RunFullSweep := function(arg)
    local numSamples, numTrials, levels, allRows, lambda, rows,
          csvPath, params, kgResult, encResult, decResult, hgoe128;

    if Length(arg) >= 1 then
        numSamples := arg[1];
    else
        numSamples := 20;
    fi;
    if Length(arg) >= 2 then
        numTrials := arg[2];
    else
        numTrials := 3;
    fi;

    levels := [80, 128, 192, 256];
    allRows := [];

    Print("\n");
    Print("################################################################\n");
    Print("##  Orbcrypt HGOE — Phase 14 Parameter Sweep                 ##\n");
    Print("################################################################\n\n");

    for lambda in levels do
        rows := SweepLevel(lambda, numSamples, numTrials);
        Add(allRows, rows);

        csvPath := Concatenation("docs/benchmarks/results_",
                                  String(lambda), ".csv");
        WriteSweepCSV(rows, csvPath);
    od;

    # Comparison CSV: run a full Phase 11 benchmark at lambda=128 to
    # source timings comparable to the AES/Kyber/BIKE rows.
    Print("Measuring HGOE-128 for comparison.csv...\n");
    params := HGOEParams(128);
    kgResult := BenchKeygen(params, Maximum(1, numTrials));
    encResult := BenchEncaps(params, Maximum(1, numTrials));
    decResult := BenchDecaps(params, Maximum(1, numTrials));
    hgoe128 := rec(
        n        := params.n,
        keygenMs := kgResult.timing.mean,
        encapsMs := encResult.timing.mean,
        decapsMs := decResult.timing.mean
    );

    WriteComparisonCSV(hgoe128, "docs/benchmarks/comparison.csv");

    Print("\nSweep complete. See docs/benchmarks/*.csv\n");
    return rec(sweep := allRows, comparison := hgoe128);
end;;

#' RunQuickSweep() — Low-sample smoke test of RunFullSweep for CI.
RunQuickSweep := function()
    return RunFullSweep(5, 1);
end;;

Print("orbcrypt_sweep.g loaded successfully.\n");;
