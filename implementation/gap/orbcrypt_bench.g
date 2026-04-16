##############################################################################
##
## orbcrypt_bench.g — Benchmark Harness
##
## Work Units 11.5 and 11.7 from Phase 11.
##
## Measures keygen, encaps, and decaps performance across security levels.
## Outputs structured CSV and a human-readable summary table.
## Includes comparison data against existing schemes.
##
## Requires: orbcrypt_keygen.g, orbcrypt_kem.g
##
##############################################################################

##############################################################################
## 11.5a — Timing Utility
##############################################################################

#' TimeOperation(op, nTrials) — Run op() nTrials times and collect stats.
#'
#' @param op       A zero-argument function to time.
#' @param nTrials  Number of repetitions.
#' @return  Record with: mean, median, min, max, stddev, total, timings.
#'
TimeOperation := function(op, nTrials)
    local timings, i, t0, t1, elapsed, total, mean, sorted,
          median, minVal, maxVal, variance, stddev;

    timings := [];
    for i in [1..nTrials] do
        t0 := Runtime();
        op();
        t1 := Runtime();
        elapsed := t1 - t0;
        Add(timings, elapsed);
    od;

    total := Sum(timings);
    mean := Float(total) / Float(nTrials);
    sorted := ShallowCopy(timings);
    Sort(sorted);
    if nTrials mod 2 = 1 then
        median := Float(sorted[Int((nTrials + 1) / 2)]);
    else
        median := Float(sorted[Int(nTrials / 2)] + sorted[Int(nTrials / 2) + 1])
                  / Float(2);
    fi;
    minVal := sorted[1];
    maxVal := sorted[nTrials];

    if nTrials > 1 then
        variance := Sum(List(timings, t -> (Float(t) - mean)^2))
                    / Float(nTrials - 1);
        stddev := Sqrt(variance);
    else
        stddev := Float(0);
    fi;

    return rec(
        mean    := mean,
        median  := median,
        min     := minVal,
        max     := maxVal,
        stddev  := stddev,
        total   := total,
        timings := timings
    );
end;;

##############################################################################
## 11.5b — Key Generation Benchmark
##############################################################################

#' BenchKeygen(params, nTrials) — Benchmark key generation.
BenchKeygen := function(params, nTrials)
    local result, metadata;

    Print("  Benchmarking keygen (lambda=", params.lambda,
          ", ", nTrials, " trials)...\n");

    metadata := fail;
    result := TimeOperation(function()
        local kr;
        kr := HGOEKEMKeygen(params);
        metadata := kr.metadata;
    end, nTrials);

    return rec(
        timing   := result,
        metadata := metadata
    );
end;;

##############################################################################
## 11.5c — Encapsulation Benchmark
##############################################################################

#' BenchEncaps(params, nTrials) — Benchmark KEM encapsulation.
BenchEncaps := function(params, nTrials)
    local kemKey, sk, bp, result, canonTimings, i, t0, t1, t2, t3,
          g, c, canonResult, permTime, canonTime;

    Print("  Benchmarking encaps (lambda=", params.lambda,
          ", ", nTrials, " trials)...\n");

    # Generate key once
    kemKey := HGOEKEMKeygen(params);
    sk := kemKey.sk;
    bp := kemKey.basePoint;

    # Overall timing
    result := TimeOperation(function()
        HGOEEncaps(sk, bp);
    end, nTrials);

    # Detailed breakdown: sampling vs permutation vs canonical image
    permTime := 0;
    canonTime := 0;
    for i in [1..Minimum(nTrials, 50)] do
        t0 := Runtime();
        g := PseudoRandom(sk.G);
        t1 := Runtime();
        c := PermuteBitstring(bp, g);
        t2 := Runtime();
        canonResult := CanonicalImage(sk.G, c, OnSets);
        t3 := Runtime();
        permTime := permTime + (t2 - t1);
        canonTime := canonTime + (t3 - t2);
    od;

    return rec(
        timing    := result,
        permTime  := Float(permTime) / Float(Minimum(nTrials, 50)),
        canonTime := Float(canonTime) / Float(Minimum(nTrials, 50))
    );
end;;

##############################################################################
## 11.5d — Decapsulation Benchmark
##############################################################################

#' BenchDecaps(params, nTrials) — Benchmark KEM decapsulation.
BenchDecaps := function(params, nTrials)
    local kemKey, sk, bp, ciphertexts, enc, i, result,
          canonOnly, t0, t1;

    Print("  Benchmarking decaps (lambda=", params.lambda,
          ", ", nTrials, " trials)...\n");

    kemKey := HGOEKEMKeygen(params);
    sk := kemKey.sk;
    bp := kemKey.basePoint;

    # Pre-generate ciphertexts
    ciphertexts := [];
    for i in [1..nTrials] do
        enc := HGOEEncaps(sk, bp);
        Add(ciphertexts, enc.ciphertext);
    od;

    # Overall timing
    result := TimeOperation(function()
        local idx;
        idx := Random([1..nTrials]);
        HGOEDecaps(sk, ciphertexts[idx]);
    end, nTrials);

    # Canonical image timing (dominant cost)
    canonOnly := TimeOperation(function()
        local idx;
        idx := Random([1..nTrials]);
        CanonicalImage(sk.G, ciphertexts[idx], OnSets);
    end, Minimum(nTrials, 50));

    return rec(
        timing    := result,
        canonOnly := canonOnly
    );
end;;

##############################################################################
## 11.5e — CSV Output and Summary
##############################################################################

#' BenchmarkAll(levels, keygenTrials, kemTrials) — Run all benchmarks.
#'
#' @param levels        List of lambda values (e.g. [80, 128]).
#' @param keygenTrials  Trials per keygen benchmark.
#' @param kemTrials     Trials per encaps/decaps benchmark.
#' @return  Record with all benchmark data.
#'
BenchmarkAll := function(levels, keygenTrials, kemTrials)
    local results, lambda, params, kgResult, encResult, decResult, row;

    results := [];

    Print("\n");
    Print("################################################################\n");
    Print("##  Orbcrypt HGOE — Benchmark Suite                          ##\n");
    Print("################################################################\n\n");

    for lambda in levels do
        Print("--- lambda = ", lambda, " ---\n");
        params := HGOEParams(lambda);
        Print("  Parameters: n=", params.n, ", w=", params.w,
              ", ell=", params.ell, "\n");

        kgResult := BenchKeygen(params, keygenTrials);
        encResult := BenchEncaps(params, kemTrials);
        decResult := BenchDecaps(params, kemTrials);

        row := rec(
            lambda       := lambda,
            n            := params.n,
            w            := params.w,
            log2G        := kgResult.metadata.log2Order,
            keygenMs     := kgResult.timing.mean,
            encapsMs     := encResult.timing.mean,
            decapsMs     := decResult.timing.mean,
            canonMs      := decResult.canonOnly.mean,
            permMs       := encResult.permTime,
            ctBits       := params.n,
            keyBits      := params.n,
            numGens      := kgResult.metadata.numGens,
            keygenResult := kgResult,
            encapsResult := encResult,
            decapsResult := decResult
        );
        Add(results, row);

        Print("  Keygen: ", kgResult.timing.mean, "ms (mean), ",
              kgResult.timing.median, "ms (median)\n");
        Print("  Encaps: ", encResult.timing.mean, "ms (mean), ",
              "canon=", encResult.canonTime, "ms\n");
        Print("  Decaps: ", decResult.timing.mean, "ms (mean), ",
              "canon=", decResult.canonOnly.mean, "ms\n");
        Print("\n");
    od;

    return results;
end;;

##############################################################################
## CSV Writer
##############################################################################

#' WriteCSV(results, filename) — Write benchmark results to CSV.
WriteCSV := function(results, filename)
    local f, row;

    f := OutputTextFile(filename, false);
    if f = fail then
        Print("ERROR: Cannot open ", filename, " for writing\n");
        return;
    fi;

    # Header
    AppendTo(f, "lambda,n,w,log2_G,keygen_ms,encaps_ms,decaps_ms,");
    AppendTo(f, "canon_ms,perm_ms,ct_bits,key_bits,num_gens\n");

    for row in results do
        AppendTo(f, String(row.lambda), ",");
        AppendTo(f, String(row.n), ",");
        AppendTo(f, String(row.w), ",");
        AppendTo(f, String(row.log2G), ",");
        AppendTo(f, String(row.keygenMs), ",");
        AppendTo(f, String(row.encapsMs), ",");
        AppendTo(f, String(row.decapsMs), ",");
        AppendTo(f, String(row.canonMs), ",");
        AppendTo(f, String(row.permMs), ",");
        AppendTo(f, String(row.ctBits), ",");
        AppendTo(f, String(row.keyBits), ",");
        AppendTo(f, String(row.numGens), "\n");
    od;

    CloseStream(f);
    Print("CSV written to: ", filename, "\n");
end;;

##############################################################################
## Summary Table
##############################################################################

#' PrintSummaryTable(results) — Print human-readable comparison table.
PrintSummaryTable := function(results)
    local row;

    Print("\n============================================================\n");
    Print("HGOE Benchmark Summary\n");
    Print("============================================================\n");
    Print(String("lambda", -8), String("n", -6),
          String("log2|G|", -10),
          String("keygen", -12), String("encaps", -12),
          String("decaps", -12), String("canon", -12), "\n");
    Print("------------------------------------------------------------\n");

    for row in results do
        Print(String(String(row.lambda), -8),
              String(String(row.n), -6),
              String(String(row.log2G), -10),
              String(Concatenation(String(Int(row.keygenMs)), "ms"), -12),
              String(Concatenation(String(Int(row.encapsMs)), "ms"), -12),
              String(Concatenation(String(Int(row.decapsMs)), "ms"), -12),
              String(Concatenation(String(Int(row.canonMs)), "ms"), -12),
              "\n");
    od;
    Print("============================================================\n");
end;;

##############################################################################
## 11.7 — Comparison Data
##############################################################################

#' PrintComparisonTable(results) — Print comparison against existing schemes.
PrintComparisonTable := function(results)
    local hgoe128, hgoe128_enc, hgoe128_dec, hgoe128_kg;

    # Find lambda=128 row (or closest)
    hgoe128 := First(results, r -> r.lambda = 128);
    if hgoe128 = fail then
        if Length(results) > 0 then
            hgoe128 := results[1];
        else
            Print("No benchmark data available for comparison.\n");
            return;
        fi;
    fi;

    hgoe128_enc := Int(hgoe128.encapsMs);
    hgoe128_dec := Int(hgoe128.decapsMs);
    hgoe128_kg  := Int(hgoe128.keygenMs);

    Print("\n============================================================\n");
    Print("Comparison with Existing Schemes (128-bit security)\n");
    Print("============================================================\n");
    Print(String("Scheme", -16), String("Type", -12),
          String("KeySize", -10), String("CTSize", -10),
          String("Enc(us)", -10), String("Dec(us)", -10), "\n");
    Print("------------------------------------------------------------\n");
    Print(String("AES-256-GCM", -16), String("Symmetric", -12),
          String("256b", -10), String("n+128b", -10),
          String("~0.001", -10), String("~0.001", -10), "\n");
    Print(String("Kyber-768", -16), String("KEM", -12),
          String("2400B", -10), String("1088B", -10),
          String("~30", -10), String("~25", -10), "\n");
    Print(String("BIKE-L3", -16), String("Code-KEM", -12),
          String("3114B", -10), String("3114B", -10),
          String("~100", -10), String("~200", -10), "\n");
    Print(String("HQC-256", -16), String("Code-KEM", -12),
          String("7245B", -10), String("14469B", -10),
          String("~300", -10), String("~500", -10), "\n");
    Print(String("HGOE-128", -16), String("Orbit-KEM", -12),
          String(Concatenation(String(hgoe128.n), "b"), -10),
          String(Concatenation(String(hgoe128.ctBits), "b"), -10),
          String(Concatenation(String(hgoe128_enc * 1000), ""), -10),
          String(Concatenation(String(hgoe128_dec * 1000), ""), -10), "\n");
    Print("============================================================\n");
    Print("Note: HGOE timings are from unoptimized GAP prototype.\n");
    Print("Production implementation would use C/C++ with optimized\n");
    Print("partition backtracking (estimated 100-1000x speedup).\n");
    Print("============================================================\n");
end;;

##############################################################################
## Go/No-Go Decision
##############################################################################

#' EvaluateGoNoGo(results) — Evaluate go/no-go criteria from Phase 11 plan.
EvaluateGoNoGo := function(results)
    local row128, row80, go, criteriaList, crit;

    Print("\n============================================================\n");
    Print("Go/No-Go Evaluation\n");
    Print("============================================================\n");

    row128 := First(results, r -> r.lambda = 128);
    row80 := First(results, r -> r.lambda = 80);

    go := true;
    criteriaList := [];

    if row128 <> fail then
        Add(criteriaList, rec(
            name := "Keygen < 300s (lambda=128)",
            value := row128.keygenMs / Float(1000),
            passed := row128.keygenMs < Float(300000)
        ));
        Add(criteriaList, rec(
            name := "Encaps < 10s (lambda=128)",
            value := row128.encapsMs / Float(1000),
            passed := row128.encapsMs < Float(10000)
        ));
        Add(criteriaList, rec(
            name := "Decaps < 10s (lambda=128)",
            value := row128.decapsMs / Float(1000),
            passed := row128.decapsMs < Float(10000)
        ));
    fi;

    # Round-trip correctness is verified by the test suite, not here

    for crit in criteriaList do
        Print("  ", crit.name, ": ",
              crit.value, "s -> ",
              crit.passed, "\n");
        if not crit.passed then
            go := false;
        fi;
    od;

    Print("\n  Decision: ");
    if go then
        Print("GO - All criteria met.\n");
    else
        Print("NO-GO - See failing criteria above.\n");
        Print("  Recommendation: Canonical image computation is the\n");
        Print("  bottleneck. Escalate to Phase 14 (Decryption Optimization)\n");
        Print("  for C/C++ partition backtracking implementation.\n");
    fi;
    Print("============================================================\n");

    return go;
end;;

##############################################################################
## Main Entry Point
##############################################################################

#' RunBenchmarks() — Run the complete benchmark suite.
RunBenchmarks := function()
    local levels, results, goDecision, csvPath;

    levels := [80, 128, 192, 256];

    results := BenchmarkAll(levels, 3, 20);

    PrintSummaryTable(results);
    PrintComparisonTable(results);
    goDecision := EvaluateGoNoGo(results);

    # Write CSV
    csvPath := "implementation/gap/orbcrypt_benchmarks.csv";
    WriteCSV(results, csvPath);

    Print("\nBenchmark suite complete.\n");
    return rec(results := results, go := goDecision);
end;;

Print("orbcrypt_bench.g loaded successfully.\n");;
