# Phase 13 — Public-Key Extension

## Weeks 26–30 | 7 Work Units | ~28 Hours | **Status: Complete**

*Part of the [Orbcrypt Practical Improvements Plan](../../formalization/PRACTICAL_IMPROVEMENTS_PLAN.md)*

All seven work units have been implemented across three Lean modules
(`Orbcrypt/PublicKey/{ObliviousSampling, KEMAgreement, CommutativeAction}.lean`)
plus a feasibility-analysis document (`docs/PUBLIC_KEY_ANALYSIS.md`).
Zero `sorry`, zero custom axioms, all theorems machine-checked.

---

## Overview

Phase 13 explores paths from symmetric-key to public-key orbit encryption.
The current scheme requires both parties to share G. This phase investigates
three approaches: oblivious orbit sampling, KEM-based key agreement, and
commutative group action Diffie-Hellman.

**Fundamental obstacle:** Non-commutative groups (like subgroups of S_n)
do not naturally support public-key operations. The non-commutativity that
makes the group harder to recover is exactly what prevents DH-style exchange.

---

## Objectives

1. Define oblivious orbit sampling with published randomizers.
2. Prove orbit membership of oblivious samples.
3. Define randomizer refresh protocol.
4. Define two-party KEM key agreement.
5. Define commutative group action framework (CSIDH-style).
6. Define public-key orbit encryption via commutative action.
7. Write comprehensive public-key feasibility analysis.

---

## Prerequisites

- Phase 2 complete (group action foundations for CommGroupAction)
- Phase 7 complete (OrbitKEM for key agreement)
- Phase 12 complete (hardness alignment for feasibility assessment)

---

## New Files

```
Orbcrypt/
  PublicKey/
    ObliviousSampling.lean  — Randomizer-based public encryption
    KEMAgreement.lean       — KEM-based key agreement protocol
    CommutativeAction.lean  — CSIDH-style commutative action
  docs/
    PUBLIC_KEY_ANALYSIS.md  — Feasibility analysis
```

---

## Work Units

### Track A: Oblivious Sampling (13.1 → 13.2 → 13.3)

---

#### 13.1 — Oblivious Orbit Sampling Definition

**Effort:** 4h | **File:** `PublicKey/ObliviousSampling.lean` | **Deps:** Phase 7

```lean
structure OrbitalRandomizers (G : Type*) (X : Type*) (t : ℕ)
    [Group G] [MulAction G X] where
  basePoint : X
  randomizers : Fin t → X
  in_orbit : ∀ i, randomizers i ∈ MulAction.orbit G basePoint

def obliviousSample (ors : OrbitalRandomizers G X)
    (combine : X → X → X)
    (hClosed : ∀ x y, x ∈ MulAction.orbit G ors.basePoint →
      y ∈ MulAction.orbit G ors.basePoint →
      combine x y ∈ MulAction.orbit G ors.basePoint)
    (i j : Fin t) : X :=
  combine (ors.randomizers i) (ors.randomizers j)
```

**Key challenge (OPEN PROBLEM):** Finding a `combine` operation that
preserves orbit membership without revealing G. XOR does NOT work for
bitstrings (weight changes). Composition of permutations reveals G.

**Exit criteria:** Definitions compile. Open problem documented.

---

#### 13.2 — Oblivious Sampling Correctness

**Effort:** 4h | **File:** `PublicKey/ObliviousSampling.lean` | **Deps:** 13.1

```lean
theorem oblivious_sample_in_orbit (ors : OrbitalRandomizers G X)
    (combine : X → X → X) (hClosed : ...) (i j : Fin t) :
    obliviousSample ors combine hClosed i j ∈
      MulAction.orbit G ors.basePoint :=
  hClosed _ _ (ors.in_orbit i) (ors.in_orbit j)
```

Also state security requirement: sender learns nothing about G from randomizers.

**Exit criteria:** Orbit membership theorem compiles.

---

#### 13.3 — Randomizer Refresh Protocol

**Effort:** 4h | **File:** `PublicKey/ObliviousSampling.lean` | **Deps:** 13.1

```lean
def refreshRandomizers (G_elem_sampler : ℕ → G)
    (basePoint : X) (t : ℕ) (epoch : ℕ) : Fin t → X :=
  fun i => G_elem_sampler (epoch * t + i.val) • basePoint
```

State independence property for fresh randomizers from different epochs.

**Exit criteria:** Definition compiles. Independence property stated.

---

### Track B: Key Agreement (13.4)

---

#### 13.4 — KEM-Based Key Agreement

**Effort:** 4h | **File:** `PublicKey/KEMAgreement.lean` | **Deps:** Phase 7

```lean
structure OrbitKeyAgreement (G_A G_B : Type*) (X K : Type*)
    [Group G_A] [Group G_B] [MulAction G_A X] [MulAction G_B X] where
  kem_A : OrbitKEM G_A X K
  kem_B : OrbitKEM G_B X K
  combiner : K → K → K
```

**Limitation (FUNDAMENTAL):** Both parties need secret groups. Not true
public-key. Documented as open problem.

**Exit criteria:** Structure type-checks. Limitation documented.

---

### Track C: Commutative Actions (13.5 → 13.6)

---

#### 13.5 — Commutative Group Action Framework

**Effort:** 4h | **File:** `PublicKey/CommutativeAction.lean` | **Deps:** Phase 2

```lean
class CommGroupAction (G : Type*) (X : Type*) extends MulAction G X where
  comm : ∀ (g h : G) (x : X), g • (h • x) = h • (g • x)

def csidh_exchange [CommGroupAction G X] (a b : G) (x₀ : X) : X × X × X :=
  (a • x₀, b • x₀, a • (b • x₀))

theorem csidh_correctness [CommGroupAction G X] (a b : G) (x₀ : X) :
    a • (b • x₀) = b • (a • x₀) := CommGroupAction.comm a b x₀
```

**Exit criteria:** Class, function, and correctness theorem compile.

---

#### 13.6 — Commutative Orbit Encryption

**Effort:** 4h | **File:** `PublicKey/CommutativeAction.lean` | **Deps:** 13.5

```lean
structure CommOrbitPKE (G : Type*) (X : Type*) [CommGroupAction G X] where
  basePoint : X
  secretKey : G
  publicKey : X
  pk_valid : publicKey = secretKey • basePoint
```

**Exit criteria:** Structure type-checks.

---

### Synthesis (13.7)

---

#### 13.7 — Public-Key Analysis Document

**Effort:** 4h | **File:** `docs/PUBLIC_KEY_ANALYSIS.md` | **Deps:** 13.1–13.6

Comprehensive feasibility analysis covering:

1. **Oblivious sampling:** Viable for bounded-use. Key challenge: finding
   orbit-preserving `combine`. Status: open problem.
2. **KEM key agreement:** Works but requires both parties to hold symmetric
   keys. Not true public-key.
3. **Commutative actions (CSIDH-style):** Most promising path. Requires
   commutative action satisfying OIA. Open research direction.
4. **Fundamental obstacle:** Non-commutativity prevents DH-style exchange.

**Exit criteria:** Document complete with clear feasibility assessments.

---

## Internal Dependency Graph

```
Track A: 13.1 (Oblivious) → 13.2 (Correct) → 13.3 (Refresh)
Track B: 13.4 (KEM Agreement)                        \
Track C: 13.5 (CommAction) → 13.6 (CommPKE)           → 13.7 (Analysis)
```

---

## Risk Analysis

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| No good `combine` operation exists | High | High | Document as open problem |
| CommGroupAction OIA is trivially broken | High | Medium | Focus on symmetric-key KEM |
| Oblivious sampling security is unclear | Medium | Medium | State as conjecture |

---

## Phase Exit Criteria

1. `PublicKey/ObliviousSampling.lean` compiles with orbit membership proof.
2. `PublicKey/KEMAgreement.lean` compiles with key agreement structure.
3. `PublicKey/CommutativeAction.lean` compiles with CSIDH correctness.
4. `docs/PUBLIC_KEY_ANALYSIS.md` is complete with feasibility assessments.
5. All open problems are clearly documented.

---

## Summary

| Unit | Title | File | Effort | Deps | Status |
|------|-------|------|--------|------|--------|
| 13.1 | Oblivious Sampling Def | `PublicKey/ObliviousSampling.lean` | 4h | Phase 7 | Complete |
| 13.2 | Oblivious Correctness | `PublicKey/ObliviousSampling.lean` | 4h | 13.1 | Complete |
| 13.3 | Randomizer Refresh | `PublicKey/ObliviousSampling.lean` | 4h | 13.1 | Complete |
| 13.4 | KEM Key Agreement | `PublicKey/KEMAgreement.lean` | 4h | Phase 7 | Complete |
| 13.5 | Commutative Framework | `PublicKey/CommutativeAction.lean` | 4h | Phase 2 | Complete |
| 13.6 | Commutative PKE | `PublicKey/CommutativeAction.lean` | 4h | 13.5 | Complete |
| 13.7 | Public-Key Analysis | `docs/PUBLIC_KEY_ANALYSIS.md` | 4h | 13.1–13.6 | Complete |

## Machine-checked deliverables

| Deliverable | Module | Notes |
|------|------|-------|
| `OrbitalRandomizers` structure | `PublicKey/ObliviousSampling.lean` | Bundle of orbit samples with membership certificate |
| `obliviousSample` | `PublicKey/ObliviousSampling.lean` | Client-side combiner, parameterised by closure proof |
| `oblivious_sample_in_orbit` | `PublicKey/ObliviousSampling.lean` | Orbit-membership theorem (direct application of `hClosed`) |
| `ObliviousSamplingHiding`, `oblivious_sampling_view_constant` | `PublicKey/ObliviousSampling.lean` | Sender-privacy predicate + corollary |
| `refreshRandomizers`, `refreshRandomizers_in_orbit` | `PublicKey/ObliviousSampling.lean` | Epoch-indexed bundle with orbit proof |
| `RefreshIndependent`, `refresh_independent` | `PublicKey/ObliviousSampling.lean` | Structural independence of disjoint epochs |
| `OrbitKeyAgreement` structure, `sessionKey` | `PublicKey/KEMAgreement.lean` | Two-party key agreement |
| `kem_agreement_correctness`, `..._alice_view`, `..._bob_view` | `PublicKey/KEMAgreement.lean` | Both parties' views match |
| `SymmetricKeyAgreementLimitation`, `symmetric_key_agreement_limitation` | `PublicKey/KEMAgreement.lean` | Formal marker for the NOT-public-key limitation |
| `CommGroupAction` (typeclass) | `PublicKey/CommutativeAction.lean` | `MulAction` + commutativity |
| `csidh_exchange`, `csidh_correctness`, `csidh_views_agree` | `PublicKey/CommutativeAction.lean` | CSIDH-style DH and correctness |
| `CommOrbitPKE` structure, `encrypt`, `decrypt` | `PublicKey/CommutativeAction.lean` | Public-key encryption structure |
| `comm_pke_correctness`, `comm_pke_shared_secret` | `PublicKey/CommutativeAction.lean` | Sender/recipient views match |
| `CommGroupAction.selfAction` | `PublicKey/CommutativeAction.lean` | Toy self-action witness for `CommGroup` |
| `docs/PUBLIC_KEY_ANALYSIS.md` | — | Feasibility analysis document (Track A/B/C + fundamental obstacle) |
