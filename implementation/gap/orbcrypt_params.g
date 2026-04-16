##############################################################################
##
## orbcrypt_params.g — Parameter Generation Utility
##
## Generates and validates HGOE parameter sets for security levels
## lambda in {80, 128, 192, 256}. Computes derived parameters, validates
## group orders, and estimates orbit counts.
##
## Requires: orbcrypt_keygen.g, orbcrypt_kem.g (must be loaded first)
##
##############################################################################

##############################################################################
## 11.6a — Parameter Derivation for All Levels
##############################################################################

#' GenerateAllParams() — Compute parameter tables for all security levels.
#'
#' @return  List of records, one per security level.
#'
GenerateAllParams := function()
    local levels, results, lambda, params;

    levels := [80, 128, 192, 256];
    results := [];

    Print("============================================================\n");
    Print("HGOE Parameter Derivation\n");
    Print("============================================================\n");
    Print(String("lambda", -8), String("n", -6), String("b", -4),
          String("ell", -6), String("k", -6), String("w", -6), "\n");
    Print("------------------------------------------------------------\n");

    for lambda in levels do
        params := HGOEParams(lambda);
        Add(results, params);
        Print(String(String(lambda), -8),
              String(String(params.n), -6),
              String(String(params.b), -4),
              String(String(params.ell), -6),
              String(String(params.k), -6),
              String(String(params.w), -6), "\n");
    od;

    Print("============================================================\n\n");
    return results;
end;;

##############################################################################
## 11.6b — Group Order Validation
##############################################################################

#' ValidateGroupOrders(paramsList) — For each parameter set, generate
#' a group and verify log2(|G|) >= lambda.
#'
#' @param paramsList  List of records from GenerateAllParams.
#' @return  List of records with group metadata.
#'
ValidateGroupOrders := function(paramsList)
    local results, params, codeResult, passed;

    results := [];

    Print("============================================================\n");
    Print("Group Order Validation\n");
    Print("============================================================\n");
    Print(String("lambda", -8), String("n", -6),
          String("log2|G|", -12), String("|G|", -20),
          String("gens", -6), String("pass", -6), "\n");
    Print("------------------------------------------------------------\n");

    for params in paramsList do
        codeResult := HGOEGenerateCode(params);
        passed := codeResult.log2Order >= Float(params.lambda);

        Add(results, rec(
            params     := params,
            groupOrder := codeResult.groupOrder,
            log2Order  := codeResult.log2Order,
            numGens    := Length(GeneratorsOfGroup(codeResult.G)),
            passed     := passed,
            G          := codeResult.G
        ));

        Print(String(String(params.lambda), -8),
              String(String(params.n), -6),
              String(String(codeResult.log2Order), -12),
              String(String(codeResult.groupOrder), -20),
              String(String(Length(GeneratorsOfGroup(codeResult.G))), -6),
              String(String(passed), -6), "\n");
    od;

    Print("============================================================\n\n");
    return results;
end;;

##############################################################################
## 11.6c — Orbit Count Estimation
##############################################################################

#' EstimateOrbitCounts(groupResults, numSamples) — For each parameter set,
#' estimate the number of distinct weight-w orbits by sampling.
#'
#' @param groupResults  List from ValidateGroupOrders.
#' @param numSamples    Number of random samples per parameter set.
#' @return  List of records with orbit count estimates.
#'
EstimateOrbitCounts := function(groupResults, numSamples)
    local results, gr, G, n, w, canonSet, cx, x, i,
          numDistinct, theoretical, ratio;

    results := [];

    Print("============================================================\n");
    Print("Orbit Count Estimation (", numSamples, " samples each)\n");
    Print("============================================================\n");
    Print(String("lambda", -8), String("n", -6),
          String("distinct", -10), String("C(n,w)/|G|", -14),
          String("ratio", -10), "\n");
    Print("------------------------------------------------------------\n");

    for gr in groupResults do
        G := gr.G;
        n := gr.params.n;
        w := gr.params.w;

        canonSet := [];
        for i in [1..numSamples] do
            x := RandomWeightWSupport(n, w);
            cx := CanonicalImage(G, x, OnSets);
            if not cx in canonSet then
                Add(canonSet, cx);
            fi;
        od;
        numDistinct := Length(canonSet);

        # Theoretical estimate: C(n,w) / |G|
        # Use floating point to avoid overflow
        theoretical := Float(Binomial(n, w)) / Float(gr.groupOrder);

        if theoretical > Float(0) then
            ratio := Float(numDistinct) / theoretical;
        else
            ratio := Float(0);
        fi;

        Add(results, rec(
            params      := gr.params,
            numDistinct := numDistinct,
            theoretical := theoretical,
            ratio       := ratio
        ));

        Print(String(String(gr.params.lambda), -8),
              String(String(n), -6),
              String(String(numDistinct), -10),
              String(String(Int(theoretical)), -14),
              String(String(ratio), -10), "\n");
    od;

    Print("============================================================\n\n");
    return results;
end;;

##############################################################################
## Main Entry Point
##############################################################################

#' RunParameterGeneration() — Run the complete parameter generation pipeline.
RunParameterGeneration := function()
    local allParams, groupResults, orbitResults;

    Print("\n");
    Print("################################################################\n");
    Print("##  Orbcrypt HGOE — Parameter Generation                     ##\n");
    Print("################################################################\n\n");

    allParams := GenerateAllParams();
    groupResults := ValidateGroupOrders(allParams);

    # Canonical image is O(n^c) so use fewer samples for large n
    orbitResults := EstimateOrbitCounts(groupResults, 20);

    Print("Parameter generation complete.\n\n");

    return rec(
        params  := allParams,
        groups  := groupResults,
        orbits  := orbitResults
    );
end;;

Print("orbcrypt_params.g loaded successfully.\n");;
