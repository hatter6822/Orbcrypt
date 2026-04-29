<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Phase 12 — Hardness Alignment (LESS/MEDS/TI)

## Weeks 23–28 | 8 Work Units | ~32 Hours

*Part of the [Orbcrypt Practical Improvements Plan](../../formalization/PRACTICAL_IMPROVEMENTS_PLAN.md)*

---

## Overview

Phase 12 aligns Orbcrypt's security assumptions with hardness problems
underlying active NIST Post-Quantum Cryptography candidates. This inherits
the scrutiny those candidates receive and strengthens the theoretical
foundation beyond the current informal GI/CE reductions.

**Target problems:**

| Problem | Used By | Relationship to Orbcrypt |
|---------|---------|------------------------|
| **Linear Code Equivalence (LE)** | LESS signature scheme | Direct: CE-OIA reduces to LE |
| **Matrix Code Equivalence (MCE)** | MEDS signature scheme | Extension: tensor generalization of CE |
| **Alternating Trilinear Form Equiv (ATFE)** | MEDS | Stronger: believed harder than GI |
| **Tensor Isomorphism (TI)** | Emerging research | Strictly harder than GI (no quasi-poly algorithm known) |

---

## Objectives

1. Formally define the Permutation Code Equivalence problem in Lean 4.
2. State that PAut recovery implies CE solving capability.
3. Write LESS/MEDS alignment analysis document.
4. Define tensor group action on 3-tensors with GL^3 action.
5. Define Tensor Isomorphism decision problem.
6. Define Tensor-OIA variant.
7. Formalize the full reduction chain: TI → CE → GI → OIA → Security.
8. Produce comprehensive hardness comparison table.

---

## Prerequisites

- Phase 2 complete (group action foundations)
- Phase 8 complete (probabilistic OIA definitions, for alignment)

---

## New Files

```
Orbcrypt/
  Hardness/
    CodeEquivalence.lean    — CE problem definition, relation to OIA
    TensorAction.lean       — Tensor group action definition
    Reductions.lean         — Reduction theorems
  docs/
    HARDNESS_ANALYSIS.md    — Detailed hardness comparison document
```

---

## Work Units

### Track A: Code Equivalence (12.1 → 12.2 → 12.3)

---

#### 12.1 — Code Equivalence Problem Definition

**Effort:** 3h | **File:** `Hardness/CodeEquivalence.lean` | **Deps:** Phase 2

```lean
def ArePermEquivalent (C₁ C₂ : Finset (Fin n → F)) : Prop :=
  ∃ σ : Equiv.Perm (Fin n), ∀ c ∈ C₁, (fun i => c (σ⁻¹ i)) ∈ C₂

def CodeEquivalenceProblem (n : ℕ) (F : Type*) [Field F] :=
  Finset (Fin n → F) × Finset (Fin n → F) → Prop

/-- GI reduces to CE (statement only). -/
theorem gi_reduces_to_ce : sorry -- Full proof requires graph-to-code encoding
```

**Exit criteria:** Definitions compile. Reduction stated with documented `sorry`.

---

#### 12.2 — PAut Recovery Implies CE

**Effort:** 4h | **File:** `Hardness/CodeEquivalence.lean` | **Deps:** 12.1

```lean
theorem paut_recovery_solves_ce
    (C : Finset (Fin n → F))
    (recover : (ℕ → Fin n → F) → Subgroup (Equiv.Perm (Fin n)))
    (hRecover : recover (orbitSamples C) = paut C) :
    ∀ C', ArePermEquivalent C C' ↔
      ∃ σ ∈ recover (orbitSamples C), ∀ c ∈ C, (fun i => c (σ⁻¹ i)) ∈ C' :=
  sorry -- Proof requires group-theoretic coset argument
```

**Exit criteria:** Statement type-checks with clear documentation.

---

#### 12.3 — LESS Alignment Document

**Effort:** 5h | **File:** `docs/HARDNESS_ANALYSIS.md` | **Deps:** 12.1

Document the connection between CE-OIA and LESS/MEDS:
- LESS uses Linear Equivalence Problem (monomial transformations)
- Permutation equivalence is a special case of monomial equivalence
- CE-OIA is a *weaker* assumption than LESS's hardness
- Reduction chain: CE-OIA <= LE <= ME (monomial equivalence)

**Exit criteria:** Document with precise reductions and NIST submission references.

---

### Track B: Tensor Isomorphism (12.4 → 12.5 → 12.6)

---

#### 12.4 — Tensor Isomorphism Action

**Effort:** 5h | **File:** `Hardness/TensorAction.lean` | **Deps:** Phase 2

**Sub-tasks:**

**12.4a — Tensor3 type (0.5h).**
```lean
def Tensor3 (n : ℕ) (F : Type*) := Fin n → Fin n → Fin n → F
```

**12.4b — Tensor contraction (1.5h).**
```lean
noncomputable def tensorSmul [Field F] [Fintype (Fin n)]
    (A B C : Matrix (Fin n) (Fin n) F)
    (T : Tensor3 n F) : Tensor3 n F :=
  fun i j k => Finset.sum Finset.univ fun a =>
    Finset.sum Finset.univ fun b =>
      Finset.sum Finset.univ fun c =>
        A i a * B j b * C k c * T a b c
```

**12.4c — MulAction instance (1.5h).**
```lean
instance tensorAction [Field F] [Fintype (Fin n)] :
    MulAction (GL (Fin n) F × GL (Fin n) F × GL (Fin n) F)
              (Tensor3 n F) where
  smul g T := tensorSmul g.1 g.2.1 g.2.2 T
  one_smul T := sorry -- Identity matrices act trivially
  mul_smul g h T := sorry -- Matrix mult distributes through sum
```

**12.4d — Sorry documentation (1.5h).** Document each sorry with:
the mathematical identity, likely Mathlib lemmas, estimated fill effort.

**Exit criteria:** Types correct. Each `sorry` has documented remediation path.

---

#### 12.5 — Tensor Isomorphism Problem

**Effort:** 4h | **File:** `Hardness/TensorAction.lean` | **Deps:** 12.4

```lean
def AreTensorIsomorphic (T₁ T₂ : Tensor3 n F) : Prop :=
  ∃ g : GL (Fin n) F × GL (Fin n) F × GL (Fin n) F, g • T₁ = T₂

/-- TI is at least as hard as GI. Known result: graphs encode as 3-tensors. -/
theorem gi_reduces_to_ti : True := trivial -- Placeholder
```

**Exit criteria:** Definitions compile. GI-to-TI reduction documented.

---

#### 12.6 — Tensor-OIA Definition

**Effort:** 4h | **File:** `Hardness/Reductions.lean` | **Deps:** 12.4, 12.5

```lean
def TensorOIA (T₀ T₁ : Tensor3 n F)
    (hNonIso : ¬ AreTensorIsomorphic T₀ T₁) : Prop :=
  ∀ (f : Tensor3 n F → Bool)
    (g₀ g₁ : GL (Fin n) F × GL (Fin n) F × GL (Fin n) F),
    f (g₀ • T₀) = f (g₁ • T₁)
```

**Exit criteria:** Definition type-checks.

---

### Merge: Reduction Chain (12.7 → 12.8)

---

#### 12.7 — Reduction Chain Documentation

**Effort:** 4h | **File:** `Hardness/Reductions.lean` | **Deps:** 12.1–12.6

```
TI-hard → TensorOIA → CE-OIA → GI-OIA → Orbcrypt IND-1-CPA secure
```

```lean
theorem tensor_oia_implies_ce_oia : TensorOIA → CEOIA := sorry
theorem ce_oia_implies_gi_oia : CEOIA → GIOIA := sorry
-- oia_implies_1cpa already proved in Phase 4
```

**Exit criteria:** Full chain stated with types that type-check.

---

#### 12.8 — Hardness Comparison Table

**Effort:** 3h | **File:** `docs/HARDNESS_ANALYSIS.md` | **Deps:** 12.3, 12.7

| Problem | Best Classical | Best Quantum | Used By | Orbcrypt Relation |
|---------|---------------|-------------|---------|------------------|
| Factoring | L(1/3) (NFS) | Poly (Shor) | RSA | None |
| DLP | L(1/3) | Poly (Shor) | ECDH | None |
| LWE | 2^(n/log n) | 2^(n/log n) | Kyber | None |
| GI | 2^O(sqrt(n log n)) | Open | ZKP | GI-OIA reduces to GI |
| Code Equiv | >= GI | Open | LESS | CE-OIA reduces to CE |
| Matrix Code Equiv | >= CE | Open | MEDS | Extension of CE |
| Tensor Iso | >= GI, no quasi-poly | Open | Emerging | TensorOIA strongest |
| HSP on S_n | Super-poly | Super-poly | Multi-query | HGOE multi-query |

**Exit criteria:** Document complete with literature references.

---

## Internal Dependency Graph

```
Track A: 12.1 (CE def) → 12.2 (PAut) → 12.3 (LESS doc)
                                              \
Track B: 12.4 (Tensor) → 12.5 (TI) → 12.6 (T-OIA)
                                              /
Merge:                                  12.7 (Chain) → 12.8 (Comparison)
```

**Parallelism:** Tracks A and B are fully independent. They merge at 12.7.

---

## Risk Analysis

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Tensor contraction proofs too complex | Medium | Low | Accept sorry; document path |
| GL type in Lean/Mathlib is awkward | Medium | Medium | Use Matrix.GeneralLinearGroup |
| LESS/MEDS connection is weaker than hoped | Low | Medium | Document honestly |

---

## Phase Exit Criteria

1. `Hardness/CodeEquivalence.lean` compiles with CE definitions.
2. `Hardness/TensorAction.lean` compiles with Tensor3 and tensorAction.
3. `Hardness/Reductions.lean` compiles with the full reduction chain.
4. `docs/HARDNESS_ANALYSIS.md` is complete with comparison table.
5. Every `sorry` is documented with remediation path.

---

## Summary

| Unit | Title | File | Effort | Deps |
|------|-------|------|--------|------|
| 12.1 | Code Equivalence Def | `Hardness/CodeEquivalence.lean` | 3h | Phase 2 |
| 12.2 | PAut Recovery | `Hardness/CodeEquivalence.lean` | 4h | 12.1 |
| 12.3 | LESS Alignment Doc | `docs/HARDNESS_ANALYSIS.md` | 5h | 12.1 |
| 12.4 | Tensor Action | `Hardness/TensorAction.lean` | 5h | Phase 2 |
| 12.5 | Tensor Iso Problem | `Hardness/TensorAction.lean` | 4h | 12.4 |
| 12.6 | Tensor-OIA Def | `Hardness/Reductions.lean` | 4h | 12.4, 12.5 |
| 12.7 | Reduction Chain | `Hardness/Reductions.lean` | 4h | 12.1–12.6 |
| 12.8 | Hardness Comparison | `docs/HARDNESS_ANALYSIS.md` | 3h | 12.3, 12.7 |
