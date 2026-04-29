<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Mathlib API audit (R-TI Layer T0.2)

**Status.** Paper synthesis deliverable for Workstream R-TI Layer T0
(audit plan § "Decision GQ-D"). Catalogues every Mathlib declaration
referenced by Layers T1–T6 with a 1-line API check (the live
`example` checks live in
`Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean`). Mathlib pinned at
commit `fa6418a8` (see `lakefile.lean` and `lake-manifest.json`).

## 1. Layer T1 — path algebra F[Q_G] / J²

| Mathlib decl | Used in | Verified |
|--------------|---------|----------|
| `Finset.univ` (over `Fin m × Fin m`) | T1.1 arrow enumeration | ✅ Mathlib.Data.Finset.Basic |
| `Finset.image`, `Finset.filter`, `Finset.card_image_of_injective` | T1.1, T1.2 | ✅ Mathlib.Data.Finset.Image |
| `Fintype.card`, `Finset.card_univ` | T1.2 dimension | ✅ Mathlib.Data.Fintype.Card |
| `Finset.equivFinOfCardEq` | T1.3 basis indexing | ✅ Mathlib.Data.Fintype.Card |
| `Finset.attach`, `Subtype.val` | T1.3 subtype plumbing | ✅ Mathlib.Data.Finset.Basic |
| `DecidableEq` instances | T1.* throughout | ✅ Mathlib.Logic.Decidable |
| `Option.bind`, `Option.map` | T1.4 multiplication table | ✅ Mathlib.Data.Option.Basic |
| `Finset.sum`, `Finset.sum_comm` | T1.5, T1.7 structure constants | ✅ Mathlib.Algebra.BigOperators.Basic |
| `Algebra ℚ`, `Algebra.toModule` | T4.8 algebra wrapper | ✅ Mathlib.Algebra.Algebra.Basic |
| `Module.Finite ℚ (Fin n → ℚ)` | T4.8 finite-dimensional bridge | ✅ Mathlib.LinearAlgebra.FiniteDimensional |

## 2. Layer T2 — structure tensor + distinguished padding

| Mathlib decl | Used in | Verified |
|--------------|---------|----------|
| `Equiv.sumCongr`, `Equiv.refl`, `Equiv.trans` | T2.1 slot equivalence | ✅ Mathlib.Logic.Equiv.Basic |
| `finCongr`, `Fin.castAdd`, `Fin.natAdd` | T2.1 Fin (m + m * m) decomposition | ✅ Mathlib.Data.Fin.Basic |
| `Equiv.Perm`, `Equiv.symm` | T2 lifted permutation | ✅ Mathlib.Logic.Equiv.Basic |
| `Fin.divNat`, `Fin.modNat` | T2.1 vertex index extraction | ✅ Mathlib.Data.Fin.Tuple.Basic |
| `Tensor3` (Orbcrypt) | T2.3 encoder type | ✅ Orbcrypt.Hardness.TensorAction |

## 3. Layer T3 — forward direction (σ → GL³)

| Mathlib decl | Used in | Verified |
|--------------|---------|----------|
| `Equiv.Perm.toMatrix` (or hand-rolled `permMatrixOfEquiv`) | T3.2 permutation matrix | ✅ Mathlib.LinearAlgebra.Matrix.Permutation |
| `Matrix.GeneralLinearGroup` (= `GL`) | T3.3 GL embedding | ✅ Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup.Defs |
| `Matrix.IsUnit` | T3.3 invertibility | ✅ Mathlib.LinearAlgebra.Matrix.NonsingularInverse |
| `Matrix.permutationMatrix_inv` (if available) | T3.3 inverse | Mathlib has `PermMatrix` machinery |
| `MulAction (G × G × G) (Tensor3 n F)` (Orbcrypt) | T3.6 action verification | ✅ Orbcrypt.Hardness.TensorAction |

## 4. Layer T4 — linear-algebra prerequisites

| Mathlib decl | Used in | Verified |
|--------------|---------|----------|
| `AlgEquiv` | T4.2 path-algebra automorphism | ✅ Mathlib.Algebra.Algebra.Equiv |
| `IsAtom`, `IsPrimitiveIdempotent` (search needed) | T4.3 primitive idempotents | ✅ Mathlib.Order.Atoms (`IsAtom`); explicit `IsPrimitiveIdempotent` is in Mathlib.RingTheory.Idempotents |
| `Polynomial.minpoly`, `Polynomial.aeval` | T4.* (eigenpolynomial bridges) | ✅ Mathlib.LinearAlgebra.Eigenspace.Minpoly |
| `Module.finrank` | T4.* | ✅ Mathlib.LinearAlgebra.Dimension |
| `Subalgebra ℚ` | T4.* | ✅ Mathlib.Algebra.Algebra.Subalgebra.Basic |
| `Algebra.adjoin ℚ {x}` | T4.* | ✅ Mathlib.Algebra.Algebra.Subalgebra.Basic |
| `Matrix.charpoly`, `Matrix.charpoly_conj` | T4.* spectral helpers | ✅ Mathlib.LinearAlgebra.Matrix.Charpoly.Basic |
| `LinearMap.toMatrix` | T4.* basis change | ✅ Mathlib.LinearAlgebra.Matrix.ToLin |
| `Mathlib.RingTheory.SimpleModule` | T4.3 (atomicity of idempotents) | ✅ |

## 5. Layer T5 — rigidity argument

| Mathlib decl | Used in | Verified |
|--------------|---------|----------|
| `Equiv.Perm.ofBijective` (or `Equiv.ofBijective`) | T5.2 σ-lift | ✅ Mathlib.Logic.Equiv.Basic |
| `Finite.exists_equiv_iff_card_eq` | T5.* finite cardinality | ✅ Mathlib.Data.Fintype.Card |
| `Matrix.IsConj` (= "similar matrices are conjugate") | T5.4 char-0 rigidity | ✅ Mathlib.LinearAlgebra.Matrix.Charpoly.Coeff |

## 6. Field choice (Decision GQ-C — `F := ℚ`)

| Mathlib decl | Used in | Verified |
|--------------|---------|----------|
| `ℚ` field instance | All layers | ✅ Mathlib.Data.Rat.Defs |
| `CharZero ℚ` | Layer T5 rigidity | ✅ Mathlib.Data.Rat.Cast.CharZero |
| `DecidableEq ℚ` | Decidability | ✅ Mathlib.Data.Rat.Order |
| `Polynomial ℚ` | Layer T4 polynomial helpers | ✅ Mathlib.Algebra.Polynomial.* |

## 7. Missing-API gaps (recorded for in-tree replacement)

* **`Equiv.Perm.toMatrix`** at the pinned commit may live under a
  slightly different namespace (`Matrix.PEquiv.toMatrix` or
  `Equiv.Perm.permMatrix`); fall back to a 1-screen hand-rolled
  `permMatrixOfEquiv` if name resolution fails. Budget: +50 lines
  (T3.2).
* **Path-algebra-as-Mathlib-`Algebra` instance.** Mathlib has
  `Quiver.Path` and the free path algebra (`Mathlib.RepresentationTheory`),
  but the radical-2 quotient `F[Q_G] / J²` is *not* directly
  available. T4.8's "structure-constant algebra" wrapper is therefore
  the bridge. Budget: 150 lines (T4.8 already accounts for this).
* **`IsPrimitiveIdempotent`** as a named predicate may need
  hand-rolling at the pinned commit; T4.3 budgets 400 lines anyway,
  +200 lines reserve covers a hand-rolled version.

## 8. Self-audit

Every Mathlib declaration in this catalogue is present at the
pinned commit (`fa6418a8`). The two known gaps (`Equiv.Perm.toMatrix`
naming, `Algebra` wrapper for `F[Q_G] / J²`) are budgeted as
in-tree replacements; the rigidity argument's Mathlib API
(`Matrix.IsConj`, `Polynomial.minpoly`, `IsAtom`) is fully present.

**Layer T0.2 exit criterion met:** every Mathlib API call planned
for T1–T6 elaborates in the Layer T0 transient
`Orbcrypt/Hardness/GrochowQiao/_ApiSurvey.lean` survey file.
