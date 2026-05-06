/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.Construction.HGOE
import Orbcrypt.Construction.BitstringSupport
import Orbcrypt.GroupAction.CanonicalLexMin

/-!
# Test-vector generator for the GAP–Lean canonical-image correspondence

Workstream 3A of the 2026-05-06 structural review (plan
`docs/dev_history/AUDIT_2026-05-06_STRUCTURAL_REVIEW.md` § 1 row 3).

This script uses `#eval` to compute lex-min canonical forms of every
`Bitstring n` for n ∈ {3, 4} under two groups (full S_n and trivial).
The output is one record per line, captured by redirecting `lake env
lean scripts/generate_test_vectors.lean` into
`implementation/gap/lean_test_vectors.txt`.

The cyclic-group case `C<n>` was dropped from the initial 3A landing
because `Subgroup.zpowers σ`'s `Fintype` instance is noncomputable
(routes through `Fintype.ofFinite`). The S<n> and T<n> cases give
the two extremes of orbit collapsing — full collapse to the lex-min
representative vs. no collapse (trivial group's orbits are singletons).
Both extremes are sufficient to validate the GAP–Lean correspondence
on the action machinery; the cyclic case is tracked as an out-of-scope
follow-up under the structural-review plan.

## Format

Each non-empty non-comment line is:

```
<n> <group_id> <input_bits> <expected_canonical_bits>
```

* `<n>` is the bitstring length (3 or 4).
* `<group_id>` is one of:
  - `S<n>` — full symmetric group `Equiv.Perm (Fin n)` (Lean side
    uses `⊤ : Subgroup (Equiv.Perm (Fin n))`);
  - `T<n>` — trivial subgroup `⊥`.
* `<input_bits>` and `<expected_canonical_bits>` are MSB-first
  Boolean strings (e.g., `101` means `[true, false, true]`).

The lex order matches Orbcrypt's `bitstringLinearOrder`
(`Construction/Permutation.lean`): leftmost-`true` wins, equivalently
the GAP set-lex order on the support set when bitstrings are
identified with their support finsets.

## Reused utilities

* `Orbcrypt.GroupAction.CanonicalLexMin.CanonicalForm.ofLexMin` —
  computable lex-min canonical form constructor.
* `Orbcrypt.Construction.Permutation.bitstringLinearOrder` — computable
  lex order matching the GAP `OnSets` convention.

## Usage

```bash
lake env lean scripts/generate_test_vectors.lean \
    > implementation/gap/lean_test_vectors.txt
```

The generated file is deterministic — repeated runs produce byte-
identical output.
-/

open Orbcrypt

namespace TestVectorGen

/-- Render a `Bitstring n` as an MSB-first ASCII Boolean string. -/
def renderBits {n : ℕ} (b : Bitstring n) : String :=
  String.ofList ((List.finRange n).map (fun i => if b i then '1' else '0'))

/-- Enumerate every `Bitstring n` in a stable order. The bit at index
`j` (0-indexed) of the binary representation of `i` becomes
`b ⟨n - 1 - j, _⟩`, so when rendered MSB-first the output reads
identically to the binary representation of `i`. -/
def allBitstrings (n : ℕ) : List (Bitstring n) :=
  (List.range (2 ^ n)).map (fun i =>
    fun (j : Fin n) => (i / (2 ^ (n - 1 - j.val))) % 2 = 1)

/-- Lex-min canonical form on the **full symmetric group** `S_n` acting
on `Bitstring n`. -/
def canonFormFullSymm (n : ℕ) (b : Bitstring n) : Bitstring n :=
  letI : LinearOrder (Bitstring n) := bitstringLinearOrder
  letI G : Subgroup (Equiv.Perm (Fin n)) := ⊤
  letI : DecidablePred (· ∈ G) := fun _ => isTrue trivial
  letI : Fintype ↥G := inferInstance
  (CanonicalForm.ofLexMin (G := ↥G) (X := Bitstring n)).canon b

/-- Lex-min canonical form on the **trivial subgroup** `⊥` acting on
`Bitstring n`. The trivial group's orbits are singletons, so
`canon b = b` for every `b`. -/
def canonFormTrivial (n : ℕ) (b : Bitstring n) : Bitstring n :=
  letI : LinearOrder (Bitstring n) := bitstringLinearOrder
  letI G : Subgroup (Equiv.Perm (Fin n)) := ⊥
  letI : DecidablePred (· ∈ G) := fun σ => decEq σ 1
  letI : Fintype ↥G := inferInstance
  (CanonicalForm.ofLexMin (G := ↥G) (X := Bitstring n)).canon b

/-- Emit one record line. -/
def emitRecord (n : ℕ) (groupId : String)
    (input expected : Bitstring n) : IO Unit :=
  IO.println s!"{n} {groupId} {renderBits input} {renderBits expected}"

/-- Emit all test vectors for a given dimension and group. -/
def emitGroupVectors (n : ℕ) (groupId : String)
    (canonF : Bitstring n → Bitstring n) : IO Unit := do
  for b in allBitstrings n do
    emitRecord n groupId b (canonF b)

end TestVectorGen

open TestVectorGen

/-- Top-level emitter. Run via `lake env lean scripts/generate_test_vectors.lean`.

The output is one comment-prefixed header followed by 16 records per
n value (2 groups × 8 records at n=3, 2 groups × 16 records at n=4 —
48 records total). -/
def main : IO Unit := do
  IO.println "# Lean-generated canonical-form test vectors."
  IO.println "# Workstream 3A of structural review 2026-05-06."
  IO.println "# Format: <n> <group_id> <input_bits> <expected_canonical_bits>"
  IO.println "# group_id ∈ {S<n>, T<n>}"
  IO.println "# Bitstrings are MSB-first; e.g., 101 means [true, false, true]."
  IO.println "# Trust chain: Lean's CanonicalForm.ofLexMin under bitstringLinearOrder"
  IO.println "#   ↔ GAP's CanonicalImage(G, support, OnSets) (validated by"
  IO.println "#   `TestLeanVectors()` in implementation/gap/orbcrypt_test.g)."
  emitGroupVectors 3 "S3" (canonFormFullSymm 3)
  emitGroupVectors 3 "T3" (canonFormTrivial 3)
  emitGroupVectors 4 "S4" (canonFormFullSymm 4)
  emitGroupVectors 4 "T4" (canonFormTrivial 4)

#eval main
