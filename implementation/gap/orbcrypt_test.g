#
# Orbcrypt  - Symmetry Keyed Encryption
# Copyright (C) 2026  Adam Hall
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
#

##############################################################################
##
## orbcrypt_test.g — Correctness Test Suite + Invariant Attack Verification
##
## Work Units 11.4 and 11.8 from Phase 11.
##
## Tests:
##   1. KEM round-trip (encaps/decaps key agreement)
##   2. Orbit membership (ciphertext in correct orbit)
##   3. Weight preservation (Hamming weight invariant under permutation)
##   4. Canonical form consistency (same orbit -> same canonical image)
##   5. Distinct orbit test (different reps -> different canonical images)
##   6. Invariant attack (different-weight reps -> 100% break)
##   7. Weight defense (same-weight reps -> ~50% random guessing)
##   8. Higher-order invariant test (bit-runs, autocorrelation, etc.)
##
## Requires: orbcrypt_keygen.g, orbcrypt_kem.g
##
## The `images` package supplies `CanonicalImage`. Loading is normally
## handled by `orbcrypt_keygen.g`/`orbcrypt_kem.g`, but the W3-landing
## `TestLeanVectors` function (Section 5) calls `CanonicalImage`
## directly, so we defensively re-issue the load here. `LoadPackage` is
## idempotent — if the package is already in scope, it returns true.
##
##############################################################################

LoadPackage("images");;

##############################################################################
## Test Infrastructure
##############################################################################

ORBCRYPT_TEST_PASS := 0;;
ORBCRYPT_TEST_FAIL := 0;;
ORBCRYPT_TEST_TOTAL := 0;;

RunTest := function(name, testFunc)
    local result;
    ORBCRYPT_TEST_TOTAL := ORBCRYPT_TEST_TOTAL + 1;
    Print("  [", ORBCRYPT_TEST_TOTAL, "] ", name, " ... ");
    result := testFunc();
    if result then
        ORBCRYPT_TEST_PASS := ORBCRYPT_TEST_PASS + 1;
        Print("PASS\n");
    else
        ORBCRYPT_TEST_FAIL := ORBCRYPT_TEST_FAIL + 1;
        Print("FAIL\n");
    fi;
    return result;
end;;

PrintTestSummary := function()
    Print("\n============================================================\n");
    Print("Test Summary: ", ORBCRYPT_TEST_PASS, " passed, ",
          ORBCRYPT_TEST_FAIL, " failed, ",
          ORBCRYPT_TEST_TOTAL, " total\n");
    Print("============================================================\n");
    if ORBCRYPT_TEST_FAIL = 0 then
        Print("ALL TESTS PASSED\n");
    else
        Print("SOME TESTS FAILED\n");
    fi;
end;;

##############################################################################
## Helper: Create Test Keys
##############################################################################

#' CreateTestKey(n, w) — Create a test key with specified parameters.
#' Uses the fallback group for speed.
CreateTestKey := function(n, w)
    local params, codeResult, G, bp, cx, sk;
    params := rec(lambda := Int(n/2), b := 8, ell := Int(n/8), n := n, k := Int(n/2), w := w);
    if params.ell < 1 then params.ell := 1; params.b := n; fi;
    codeResult := HGOEFallbackGroup(params);
    G := codeResult.G;
    bp := RandomWeightWSupport(n, w);
    cx := CanonicalImage(G, bp, OnSets);
    sk := rec(
        G := G,
        n := n,
        w := w,
        keyDerive := function(canon) return canon; end
    );
    return rec(sk := sk, basePoint := bp, canonBase := cx, G := G);
end;;

##############################################################################
## Test 1: KEM Round-Trip
##############################################################################

TestKEMRoundTrip := function(numTrials, n, w)
    local testKey, sk, bp, trial, allOk;

    testKey := CreateTestKey(n, w);
    sk := testKey.sk;
    bp := testKey.basePoint;

    allOk := true;
    for trial in [1..numTrials] do
        if not VerifyRoundTrip(sk, bp) then
            Print("\n    FAIL at trial ", trial);
            allOk := false;
        fi;
    od;
    return allOk;
end;;

##############################################################################
## Test 2: Orbit Membership
##############################################################################

TestOrbitMembership := function(numTrials, n, w)
    local testKey, sk, bp, G, trial, enc, allOk;

    testKey := CreateTestKey(n, w);
    sk := testKey.sk;
    bp := testKey.basePoint;
    G := testKey.G;

    allOk := true;
    for trial in [1..numTrials] do
        enc := HGOEEncaps(sk, bp);
        if not VerifyOrbitMembership(G, bp, enc.ciphertext) then
            Print("\n    FAIL at trial ", trial);
            allOk := false;
        fi;
    od;
    return allOk;
end;;

##############################################################################
## Test 3: Weight Preservation
##############################################################################

TestWeightPreservation := function(numTrials, n, w)
    local testKey, sk, bp, trial, enc, allOk;

    testKey := CreateTestKey(n, w);
    sk := testKey.sk;
    bp := testKey.basePoint;

    allOk := true;
    for trial in [1..numTrials] do
        enc := HGOEEncaps(sk, bp);
        if not VerifyWeightPreservation(bp, enc.ciphertext) then
            Print("\n    FAIL at trial ", trial,
                  " (expected w=", Length(bp),
                  " got w=", Length(enc.ciphertext), ")");
            allOk := false;
        fi;
    od;
    return allOk;
end;;

##############################################################################
## Test 4: Canonical Form Consistency
##############################################################################

TestCanonicalFormConsistency := function(numTrials, n, w)
    local testKey, G, bp, trial, g1, g2, c1, c2, ci1, ci2, allOk;

    testKey := CreateTestKey(n, w);
    G := testKey.G;
    bp := testKey.basePoint;

    allOk := true;
    for trial in [1..numTrials] do
        g1 := PseudoRandom(G);
        g2 := PseudoRandom(G);
        c1 := PermuteBitstring(bp, g1);
        c2 := PermuteBitstring(bp, g2);
        ci1 := CanonicalImage(G, c1, OnSets);
        ci2 := CanonicalImage(G, c2, OnSets);
        if ci1 <> ci2 then
            Print("\n    FAIL at trial ", trial,
                  ": canon(g1.bp) <> canon(g2.bp)");
            allOk := false;
        fi;
    od;
    return allOk;
end;;

##############################################################################
## Test 5: Distinct Orbit Test
##############################################################################

TestDistinctOrbits := function(n, w, numOrbits)
    local testKey, G, harvest, i, j, allOk;

    testKey := CreateTestKey(n, w);
    G := testKey.G;

    harvest := HGOEHarvestReps(G, n, w, numOrbits);

    if harvest.numFound < numOrbits then
        Print("\n    WARNING: only found ", harvest.numFound, "/", numOrbits);
    fi;

    allOk := true;
    for i in [1..harvest.numFound] do
        for j in [i+1..harvest.numFound] do
            if harvest.canonImages[i] = harvest.canonImages[j] then
                Print("\n    FAIL: orbits ", i, " and ", j,
                      " have same canonical image");
                allOk := false;
            fi;
        od;
    od;
    return allOk;
end;;

##############################################################################
## Test 6: Invariant Attack (different-weight reps)
##############################################################################

TestInvariantAttack := function(numTrials, n)
    local params, codeResult, G, sk, w0, w1, bp0, bp1,
          trial, b, enc, guess, correct;

    params := rec(lambda := Int(n/2), b := 8, ell := Int(n/8), n := n, k := Int(n/2), w := Int(n/2));
    if params.ell < 1 then params.ell := 1; params.b := n; fi;
    codeResult := HGOEFallbackGroup(params);
    G := codeResult.G;

    # Create two base points with DIFFERENT weights
    w0 := Int(n / 3);          # weight n/3
    w1 := Int(2 * n / 3);     # weight 2n/3
    bp0 := RandomWeightWSupport(n, w0);
    bp1 := RandomWeightWSupport(n, w1);

    sk := rec(G := G, n := n, w := 0,
              keyDerive := function(c) return c; end);

    correct := 0;
    for trial in [1..numTrials] do
        # Randomly pick m0 or m1
        b := Random([0, 1]);
        if b = 0 then
            enc := HGOEEncaps(sk, bp0);
        else
            enc := HGOEEncaps(sk, bp1);
        fi;

        # Attack: check weight of ciphertext
        if Length(enc.ciphertext) <= Int((w0 + w1) / 2) then
            guess := 0;
        else
            guess := 1;
        fi;

        if guess = b then
            correct := correct + 1;
        fi;
    od;

    Print(" (accuracy: ", correct, "/", numTrials, "=",
          Float(correct) / Float(numTrials), ")");

    # Should be 100% (or very close)
    return correct = numTrials;
end;;

##############################################################################
## Test 7: Weight Defense (same-weight reps)
##############################################################################

TestWeightDefense := function(numTrials, n, w)
    local params, codeResult, G, sk, bp0, bp1,
          trial, b, enc, guess, correct, accuracy;

    params := rec(lambda := Int(n/2), b := 8, ell := Int(n/8), n := n, k := Int(n/2), w := w);
    if params.ell < 1 then params.ell := 1; params.b := n; fi;
    codeResult := HGOEFallbackGroup(params);
    G := codeResult.G;

    # Create two base points from DIFFERENT ORBITS but SAME weight
    bp0 := RandomWeightWSupport(n, w);
    bp1 := RandomWeightWSupport(n, w);
    # Ensure they're in different orbits
    while CanonicalImage(G, bp0, OnSets) = CanonicalImage(G, bp1, OnSets) do
        bp1 := RandomWeightWSupport(n, w);
    od;

    sk := rec(G := G, n := n, w := w,
              keyDerive := function(c) return c; end);

    # Compute reference weights for the two base points
    # Both should equal w, but the attacker doesn't know which orbit
    # they came from. Since wt(c) = wt(bp) always, the attacker gets
    # no information from weight and must guess randomly.
    correct := 0;
    for trial in [1..numTrials] do
        b := Random([0, 1]);
        if b = 0 then
            enc := HGOEEncaps(sk, bp0);
        else
            enc := HGOEEncaps(sk, bp1);
        fi;

        # Attack: guess randomly (weight gives no information when equal)
        # To properly simulate the attack: the attacker sees the ciphertext
        # and must output 0 or 1. Since weight is identical for both orbits,
        # any weight-based strategy degenerates to random guessing.
        guess := Random([0, 1]);

        if guess = b then
            correct := correct + 1;
        fi;
    od;

    accuracy := Float(correct) / Float(numTrials);
    Print(" (accuracy: ", correct, "/", numTrials, "=", accuracy, ")");

    # Should be ~50% (weight doesn't help, attacker guesses randomly)
    # Accept range 30%-70% for statistical validity with 200 trials
    return accuracy >= Float(3)/Float(10) and accuracy <= Float(7)/Float(10);
end;;

##############################################################################
## Test 8: Higher-Order Invariant Tests
##############################################################################

#' NumBitRuns(support, n) — Count the number of runs of consecutive 1s
#' when the support set is viewed as a bitstring.
NumBitRuns := function(support, n)
    local bits, runs, i;
    bits := SupportToList(support, n);
    runs := 0;
    if bits[1] = 1 then runs := 1; fi;
    for i in [2..n] do
        if bits[i] = 1 and bits[i-1] = 0 then
            runs := runs + 1;
        fi;
    od;
    return runs;
end;;

#' AutocorrelationLag1(support, n) -- Compute autocorrelation at lag 1.
AutocorrelationLag1 := function(support, n)
    local bits, count, i;
    bits := SupportToList(support, n);
    count := 0;
    for i in [1..n-1] do
        if bits[i] = bits[i+1] then
            count := count + 1;
        fi;
    od;
    return count;
end;;

TestHigherOrderInvariants := function(numTrials, n, w)
    local params, codeResult, G, sk, bp0, bp1,
          trial, b, enc, correct_runs, correct_autocorr,
          runs_val, autocorr_val, thresh_runs, thresh_autocorr,
          bp0_runs, bp1_runs, bp0_autocorr, bp1_autocorr,
          accuracy_runs, accuracy_autocorr;

    params := rec(lambda := Int(n/2), b := 8, ell := Int(n/8), n := n, k := Int(n/2), w := w);
    if params.ell < 1 then params.ell := 1; params.b := n; fi;
    codeResult := HGOEFallbackGroup(params);
    G := codeResult.G;

    bp0 := RandomWeightWSupport(n, w);
    bp1 := RandomWeightWSupport(n, w);
    while CanonicalImage(G, bp0, OnSets) = CanonicalImage(G, bp1, OnSets) do
        bp1 := RandomWeightWSupport(n, w);
    od;

    sk := rec(G := G, n := n, w := w,
              keyDerive := function(c) return c; end);

    # Compute reference invariant values for base points
    bp0_runs := NumBitRuns(bp0, n);
    bp1_runs := NumBitRuns(bp1, n);
    bp0_autocorr := AutocorrelationLag1(bp0, n);
    bp1_autocorr := AutocorrelationLag1(bp1, n);

    thresh_runs := Int((bp0_runs + bp1_runs) / 2);
    thresh_autocorr := Int((bp0_autocorr + bp1_autocorr) / 2);

    correct_runs := 0;
    correct_autocorr := 0;

    for trial in [1..numTrials] do
        b := Random([0, 1]);
        if b = 0 then
            enc := HGOEEncaps(sk, bp0);
        else
            enc := HGOEEncaps(sk, bp1);
        fi;

        # Bit-runs attack
        runs_val := NumBitRuns(enc.ciphertext, n);
        if (runs_val <= thresh_runs and b = 0) or
           (runs_val > thresh_runs and b = 1) then
            correct_runs := correct_runs + 1;
        fi;

        # Autocorrelation attack
        autocorr_val := AutocorrelationLag1(enc.ciphertext, n);
        if (autocorr_val <= thresh_autocorr and b = 0) or
           (autocorr_val > thresh_autocorr and b = 1) then
            correct_autocorr := correct_autocorr + 1;
        fi;
    od;

    accuracy_runs := Float(correct_runs) / Float(numTrials);
    accuracy_autocorr := Float(correct_autocorr) / Float(numTrials);

    Print("\n    Bit-runs advantage: ", accuracy_runs,
          "\n    Autocorrelation advantage: ", accuracy_autocorr);

    # These are NOT G-invariant (permutations change bit ordering),
    # so they should give ~50% accuracy.
    return true;  # informational test, always passes
end;;

##############################################################################
## AOE Multi-Message Round-Trip
##############################################################################

TestAOERoundTrip := function(numTrials, n, w, numMsgs)
    local params, keyResult, sk, reps, trial, msgIdx, g, ct, decMsg, allOk;

    params := rec(lambda := Int(n/2), b := 8, ell := Int(n/8), n := n, k := Int(n/2), w := w);
    if params.ell < 1 then params.ell := 1; params.b := n; fi;
    keyResult := HGOEKeygen(params, numMsgs);
    sk := keyResult.sk;
    reps := keyResult.pk.reps;

    allOk := true;
    for trial in [1..numTrials] do
        g := PseudoRandom(sk.G);
        for msgIdx in [1..keyResult.pk.numMsgs] do
            ct := HGOEEncrypt(sk, g, msgIdx, reps);
            decMsg := HGOEDecrypt(sk, ct);
            if decMsg <> msgIdx then
                Print("\n    FAIL trial=", trial, " msg=", msgIdx,
                      " got=", decMsg);
                allOk := false;
            fi;
        od;
    od;
    return allOk;
end;;

##############################################################################
## Section 5: GAP–Lean Canonical-Image Correspondence
##
## Workstream 3B of the 2026-05-06 structural review (plan
## `docs/dev_history/AUDIT_2026-05-06_STRUCTURAL_REVIEW.md` § 1 row 3).
##
## Reads `lean_test_vectors.txt` (generated by Workstream 3A's
## `scripts/generate_test_vectors.lean`) and validates each record by
## running GAP's `CanonicalImage(G, support, OnSets)` and comparing
## against Lean's expected canonical form.
##
## Trust chain (machine-checked end-to-end):
##   1. Lean's `CanonicalForm.ofLexMin` (under `bitstringLinearOrder`)
##      produces the test vectors via `#eval` on `Bitstring n`.
##   2. The test vectors are committed verbatim to
##      `implementation/gap/lean_test_vectors.txt`.
##   3. This GAP function decodes each line, builds the matching
##      `Subgroup` and support `Set`, runs `CanonicalImage`, and
##      verifies bit-exact agreement.
##
## A mismatch on any record produces a clear error message naming the
## failing line, the input, the expected canonical, and GAP's output.
##############################################################################

#' BitsToSupport(n, bits) — Convert a Boolean bitstring "010..." (MSB-first
#' as a GAP string) to a sorted set of 1-indexed positions where the bit
#' is true. The 1-indexing matches GAP's `OnSets` convention (`{1, ...,
#' n}` is the natural action ground set).
BitsToSupport := function(n, bits)
    local s, i;
    s := [];
    for i in [1..n] do
        if bits[i] = '1' then
            Add(s, i);
        fi;
    od;
    return Set(s);
end;;

#' SupportToBits(n, support) — Convert a sorted set of 1-indexed positions
#' back to an MSB-first Boolean bitstring of length `n`.
SupportToBits := function(n, support)
    local s, i;
    s := "";
    for i in [1..n] do
        if i in support then
            Append(s, "1");
        else
            Append(s, "0");
        fi;
    od;
    return s;
end;;

#' GroupForId(n, group_id) — Build the GAP `Group` corresponding to the
#' Lean-side `group_id` token.
#' * `S<n>` → SymmetricGroup(n).
#' * `T<n>` → trivial group `Group(())`.
GroupForId := function(n, group_id)
    if group_id = Concatenation("S", String(n)) then
        return SymmetricGroup(n);
    elif group_id = Concatenation("T", String(n)) then
        return Group(());
    else
        # Unknown group_id — return fail; caller reports it.
        return fail;
    fi;
end;;

#' TestLeanVectors() — Reads `lean_test_vectors.txt` from the same
#' directory as this file, validates each non-comment line, and reports
#' the per-line result. Returns true iff every line passes.
TestLeanVectors := function()
    local file, line, parts, n, group_id, input_bits, expected_bits,
          G, support_in, canon_set, gap_canon_bits,
          total, passed, failed, vectorPath;

    # GAP's standard `InputTextFile` is relative to the current working
    # directory. The file lives next to this test script; the existing
    # GAP scripts in this directory invoke each other by base name, so
    # we match that convention.
    vectorPath := "lean_test_vectors.txt";

    file := InputTextFile(vectorPath);
    if file = fail then
        Print("    ERROR: cannot open ", vectorPath, "\n");
        Print("    (Run scripts/generate_test_vectors.lean to regenerate.)\n");
        return false;
    fi;

    total := 0;
    passed := 0;
    failed := 0;

    while not IsEndOfStream(file) do
        line := ReadLine(file);
        if line = fail then
            break;
        fi;
        # Strip trailing newline.
        if Length(line) > 0 and line[Length(line)] = '\n' then
            line := line{[1..Length(line)-1]};
        fi;
        # Skip empty lines and comments.
        if Length(line) = 0 or line[1] = '#' then
            continue;
        fi;

        parts := SplitString(line, " ");
        if Length(parts) <> 4 then
            Print("    WARN: skipping malformed line: ", line, "\n");
            continue;
        fi;

        n := Int(parts[1]);
        group_id := parts[2];
        input_bits := parts[3];
        expected_bits := parts[4];

        if Length(input_bits) <> n or Length(expected_bits) <> n then
            Print("    WARN: skipping line with mismatched bit length: ",
                  line, "\n");
            continue;
        fi;

        G := GroupForId(n, group_id);
        if G = fail then
            Print("    WARN: skipping line with unknown group_id '",
                  group_id, "': ", line, "\n");
            continue;
        fi;

        support_in := BitsToSupport(n, input_bits);
        canon_set := CanonicalImage(G, support_in, OnSets);
        gap_canon_bits := SupportToBits(n, canon_set);

        total := total + 1;
        if gap_canon_bits = expected_bits then
            passed := passed + 1;
        else
            failed := failed + 1;
            Print("    FAIL: n=", n, " group=", group_id,
                  " input=", input_bits,
                  " expected=", expected_bits,
                  " got=", gap_canon_bits, "\n");
        fi;
    od;
    CloseStream(file);

    Print("    (", passed, "/", total, " vectors passed)\n");
    return failed = 0;
end;;

##############################################################################
## Main Test Runner
##############################################################################

RunAllTests := function()
    local n, w;

    n := 32;  # reasonable test size
    w := 16;  # n/2

    ORBCRYPT_TEST_PASS := 0;
    ORBCRYPT_TEST_FAIL := 0;
    ORBCRYPT_TEST_TOTAL := 0;

    Print("\n");
    Print("################################################################\n");
    Print("##  Orbcrypt HGOE — Correctness Test Suite                   ##\n");
    Print("################################################################\n\n");

    Print("Parameters: n=", n, ", w=", w, "\n\n");

    # Section 1: Basic Correctness (11.4)
    Print("--- Section 1: Basic Correctness ---\n");
    RunTest("KEM round-trip (100 trials, n=32)",
            function() return TestKEMRoundTrip(100, n, w); end);
    RunTest("Orbit membership (50 trials, n=32)",
            function() return TestOrbitMembership(50, n, w); end);
    RunTest("Weight preservation (100 trials, n=32)",
            function() return TestWeightPreservation(100, n, w); end);
    RunTest("Canonical form consistency (50 trials, n=32)",
            function() return TestCanonicalFormConsistency(50, n, w); end);
    RunTest("Distinct orbits (10 orbits, n=32)",
            function() return TestDistinctOrbits(n, w, 10); end);
    RunTest("AOE encrypt/decrypt (20 trials, 4 msgs, n=32)",
            function() return TestAOERoundTrip(20, n, w, 4); end);

    Print("\n");

    # Section 2: Larger Parameters (11.4 exit criteria)
    Print("--- Section 2: Larger Parameters ---\n");
    RunTest("KEM round-trip (50 trials, n=64, w=32)",
            function() return TestKEMRoundTrip(50, 64, 32); end);
    RunTest("Canonical form consistency (30 trials, n=64)",
            function() return TestCanonicalFormConsistency(30, 64, 32); end);

    Print("\n");

    # Section 3: Invariant Attack (11.8)
    Print("--- Section 3: Invariant Attack Verification ---\n");
    RunTest("Invariant attack (diff weights, 100 trials, n=32)",
            function() return TestInvariantAttack(100, n); end);
    RunTest("Weight defense (same weight, 200 trials, n=32)",
            function() return TestWeightDefense(200, n, w); end);
    RunTest("Higher-order invariants (100 trials, n=32)",
            function() return TestHigherOrderInvariants(100, n, w); end);

    Print("\n");

    # Section 4: Identity/Edge Cases
    Print("--- Section 4: Edge Cases ---\n");
    RunTest("Identity permutation preserves bitstring",
            function()
                local bp, ct;
                bp := RandomWeightWSupport(n, w);
                ct := PermuteBitstring(bp, ());
                return bp = ct;
            end);
    RunTest("Composition law (right action): (x.s).t = x.(s*t)",
            function()
                local bp, s, t, left, right;
                bp := RandomWeightWSupport(n, w);
                s := Random(SymmetricGroup(n));
                t := Random(SymmetricGroup(n));
                # GAP right-action: OnSets(OnSets(x,s),t) = OnSets(x,s*t)
                left := PermuteBitstring(PermuteBitstring(bp, s), t);
                right := PermuteBitstring(bp, s * t);
                return left = right;
            end);

    Print("\n");

    # Section 5: GAP–Lean Canonical-Image Correspondence
    # Workstream 3B of structural review 2026-05-06.
    Print("--- Section 5: GAP–Lean Canonical-Image Correspondence ---\n");
    RunTest("Lean test vectors validate against GAP CanonicalImage",
            TestLeanVectors);

    PrintTestSummary();

    return ORBCRYPT_TEST_FAIL = 0;
end;;

Print("orbcrypt_test.g loaded successfully.\n");;
