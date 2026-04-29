<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Phase 10 — Authenticated Encryption & Modes

## Weeks 22–24 | 6 Work Units | ~16 Hours

*Part of the [Orbcrypt Practical Improvements Plan](../../formalization/PRACTICAL_IMPROVEMENTS_PLAN.md)*

---

## Overview

Phase 10 adds integrity protection (authentication) and defines block modes
for encrypting data longer than a single orbit element. Without authentication,
Orbcrypt ciphertexts are malleable — an attacker can flip bits undetected.
This phase closes the gap by introducing:

1. **Message Authentication Code (MAC) abstraction.** A generic MAC structure
   parameterized by key, message, and tag types, with a built-in correctness
   field ensuring that honestly computed tags always verify.

2. **Authenticated Encryption with Associated Data (AEAD).** The `AuthOrbitKEM`
   structure composes the KEM from Phase 7 with a MAC, producing
   (ciphertext, key, tag) triples. Decapsulation verifies the tag before
   returning the key, providing ciphertext integrity.

3. **KEM + DEM hybrid composition.** The standard paradigm for encrypting
   arbitrary-length data: the KEM produces a symmetric key, which is then
   used by a Data Encapsulation Mechanism (DEM) to encrypt the actual
   plaintext. This is the construction that makes Orbcrypt practical for
   real-world message encryption.

4. **Security definitions.** INT-CTXT (ciphertext integrity) is formalized
   as a Prop-valued definition capturing existential unforgeability in the
   single-encapsulation setting.

**Architectural significance:** Phases 1–6 proved that the core orbit
encryption scheme is correct, that invariant attacks characterize its failure
mode, and that OIA implies IND-1-CPA security. Phase 7 reformulated the
scheme as a KEM. Phase 10 is the final piece needed for a deployable
cryptosystem: authenticated encryption and support for arbitrary-length
messages via hybrid composition.

---

## Objectives

1. Define a generic `MAC` structure with correctness guarantee.
2. Define `AuthOrbitKEM` composing `OrbitKEM` with a MAC (Encrypt-then-MAC).
3. Prove AEAD correctness: `authDecaps` recovers the key from honestly
   generated (ciphertext, tag) pairs.
4. Define INT-CTXT (ciphertext integrity): no adversary can forge a valid
   (ciphertext, tag) pair without knowing the key.
5. Define `DEM` (Data Encapsulation Mechanism) and the KEM+DEM hybrid
   encryption/decryption functions.
6. Prove hybrid encryption correctness: decrypt(encrypt(m)) = some m.

---

## Prerequisites

- **Phase 9 (Key Compression & Nonce-Based Encryption):** Complete. Phase 10
  builds on the seed-key model and nonce-based encryption from Phase 9.
  The AEAD layer wraps the KEM interface that Phase 9 extends with seed-based
  key management. In particular, `SeedKey` and `nonceEncaps` from Phase 9
  provide the key material and deterministic encapsulation that the
  authenticated scheme protects.

- **Phase 7 (KEM Reformulation):** Complete. Phase 10 directly extends the
  `OrbitKEM` structure, `encaps`/`decaps` functions, and `kem_correctness`
  theorem from Phase 7. The `AuthOrbitKEM` structure uses `OrbitKEM` as its
  base via the `extends` mechanism. The `DEM` composition also builds on the
  KEM's `encaps` and `decaps` for the key-transport layer.

- **Phase 2 (Group Action Foundations):** Complete. `CanonicalForm` is used
  transitively through the KEM.

**Not required:** Phase 8 (Probabilistic Foundations). The AEAD and hybrid
composition definitions are purely algebraic — they do not require probability
monads or computational security definitions. Phase 8 and Phase 10 can
proceed in parallel provided Phase 7 and Phase 9 are complete.

---

## New Files

```
Orbcrypt/
  AEAD/
    MAC.lean             -- Message Authentication Code abstraction (10.1)
    AEAD.lean            -- Authenticated Encryption with Associated Data (10.2, 10.3, 10.4)
    Modes.lean           -- Block modes: KEM+DEM composition (10.5, 10.6)
```

**Dependency on existing code:** Builds on `KEM/Syntax.lean` and
`KEM/Encapsulate.lean` (Phase 7) for the `OrbitKEM`, `encaps`, and `decaps`
definitions. Uses `KEM/Correctness.lean` for `kem_correctness` in the AEAD
and hybrid correctness proofs. Connects to `KeyMgmt/SeedKey.lean` (Phase 9)
for seed-based key management integration. Does NOT modify existing files —
purely additive.

**Module dependency within Phase 10:**

```
AEAD/MAC.lean  <--- Mathlib.Tactic
      |
      v
AEAD/AEAD.lean  <--- KEM/Syntax.lean (Phase 7)
      |               KEM/Encapsulate.lean (Phase 7)
      |               KEM/Correctness.lean (Phase 7)
      |
      (independent)
      |
AEAD/Modes.lean <--- KEM/Syntax.lean (Phase 7)
                      KEM/Encapsulate.lean (Phase 7)
```

**Note:** `AEAD/Modes.lean` is independent of `AEAD/AEAD.lean` at the import
level. It only depends on the KEM modules directly. The conceptual dependency
(Modes extends the AEAD layer) is architectural, not code-level.

---

## Work Units

### Track A: Authentication (10.1 -> 10.2 -> 10.3 -> 10.4)

Track A builds the MAC abstraction, composes it with the KEM into an
authenticated scheme, proves AEAD correctness, and defines ciphertext
integrity. It forms the linear spine of this phase.

---

### 10.1 — MAC Abstraction

**Effort:** 2h | **File:** `AEAD/MAC.lean` | **Deps:** Mathlib

Define a generic Message Authentication Code structure. The MAC is
parameterized by key, message, and tag types, and carries a built-in
correctness field: honestly computed tags always pass verification.

```lean
import Mathlib.Tactic

/-! # Message Authentication Code

Defines a generic MAC structure parameterized by key, message, and tag types.
The correctness field guarantees that tags computed by `tag` always pass
`verify`. This is the standard MAC correctness property.

## Key definitions

- `MAC` — the MAC structure with `tag`, `verify`, and `correct` fields
-/

set_option autoImplicit false

/-- A Message Authentication Code. Parameterized by key, message, and tag types. -/
structure MAC (K : Type*) (Msg : Type*) (Tag : Type*) where
  /-- Compute a tag for a message under a key. -/
  tag : K → Msg → Tag
  /-- Verify a tag. -/
  verify : K → Msg → Tag → Bool
  /-- Correctness: verify accepts honestly computed tags. -/
  correct : ∀ k m, verify k m (tag k m) = true
```

**Design rationale:**

- The `correct` field is a proof obligation, not an axiom. Any instantiation
  of `MAC` must prove that `verify` accepts `tag`'s output. This is standard
  in formalized cryptography.
- The types `K`, `Msg`, and `Tag` are fully abstract. In the AEAD composition,
  `K` will be the KEM's key type, `Msg` will be the ciphertext type `X`, and
  `Tag` will be an opaque tag type.
- `verify` returns `Bool` (not `Prop`) because verification must be
  computationally decidable. The `correct` field bridges to `Prop` via
  `= true`.

**Exit criteria:** Structure type-checks. `lake build Orbcrypt.AEAD.MAC`
succeeds with zero warnings.

---

### 10.2 — AEAD Definition

**Effort:** 3h | **File:** `AEAD/AEAD.lean` | **Deps:** 10.1, Phase 7

Define authenticated encryption with associated data, composing the KEM
with a MAC. The construction follows the Encrypt-then-MAC paradigm: first
encapsulate to get (ciphertext, key), then MAC the ciphertext under the
key to produce a tag. Decapsulation verifies the tag before releasing
the key.

```lean
import Orbcrypt.AEAD.MAC
import Orbcrypt.KEM.Syntax
import Orbcrypt.KEM.Encapsulate

/-! # Authenticated Encryption with Associated Data

Defines the `AuthOrbitKEM` structure composing an `OrbitKEM` with a `MAC`.
Provides `authEncaps` (Encrypt-then-MAC) and `authDecaps` (Verify-then-Decrypt).

## Key definitions

- `AuthOrbitKEM` — authenticated KEM structure extending `OrbitKEM`
- `authEncaps` — authenticated encapsulation: encrypt then MAC
- `authDecaps` — authenticated decapsulation: verify then decrypt
-/

set_option autoImplicit false

variable {G : Type*} {X : Type*} {K : Type*} {Tag : Type*}
  [Group G] [MulAction G X] [DecidableEq X]

/-- Authenticated KEM: encapsulation produces (ciphertext, tag). -/
structure AuthOrbitKEM (G : Type*) (X : Type*) (K : Type*) (Tag : Type*)
    [Group G] [MulAction G X] [DecidableEq X] extends OrbitKEM G X K where
  /-- MAC for authenticating ciphertexts. -/
  mac : MAC K X Tag

/-- Authenticated encapsulation: encrypt then MAC. -/
def authEncaps (akem : AuthOrbitKEM G X K Tag) (g : G) :
    X × K × Tag :=
  let (c, k) := encaps akem.toOrbitKEM g
  (c, k, akem.mac.tag k c)

/-- Authenticated decapsulation: verify then decrypt. Returns none on
    authentication failure. -/
def authDecaps (akem : AuthOrbitKEM G X K Tag)
    (c : X) (t : Tag) : Option K :=
  let k := decaps akem.toOrbitKEM c
  if akem.mac.verify k c t then some k else none
```

**Design decisions:**

- **Encrypt-then-MAC** (EtM) is the composition order. This is the provably
  secure composition paradigm (Bellare & Namprempre, 2000). The alternative
  orders (MAC-then-Encrypt, Encrypt-and-MAC) have known vulnerabilities in
  certain settings.
- **`authEncaps` returns a triple** `(ciphertext, key, tag)`. The caller uses
  the key with a DEM for actual message encryption, and transmits the
  ciphertext and tag to the receiver.
- **`authDecaps` returns `Option K`** — `none` on authentication failure,
  `some k` on success. This forces callers to handle authentication failures
  explicitly, preventing accidental use of unauthenticated data.
- **`extends OrbitKEM G X K`** reuses the KEM structure directly. The
  `toOrbitKEM` projection gives access to `encaps` and `decaps`.

**Exit criteria:** Functions type-check. `lake build Orbcrypt.AEAD.AEAD`
succeeds with zero warnings.

---

### 10.3 — AEAD Correctness

**Effort:** 3h | **File:** `AEAD/AEAD.lean` | **Deps:** 10.2

Prove authenticated correctness: `authDecaps` recovers the key from
honestly generated (ciphertext, tag) pairs. This is the fundamental
soundness property of the authenticated scheme — if Alice encrypts
honestly, Bob always recovers the correct key.

```lean
/-- Authenticated KEM correctness: authDecaps recovers the key from
    honestly generated (ciphertext, tag) pairs. -/
theorem aead_correctness (akem : AuthOrbitKEM G X K Tag) (g : G) :
    let (c, k, t) := authEncaps akem g
    authDecaps akem c t = some k
```

**Proof sketch:**

1. Unfold `authEncaps` and `authDecaps`.
2. The ciphertext `c = g • akem.basePoint` and key `k = keyDerive(canon(c))`.
3. In `authDecaps`, `decaps` recomputes `k' = keyDerive(canon(c))`.
4. By `kem_correctness`, `k' = k`.
5. The tag was computed as `akem.mac.tag k c`.
6. The verify check is `akem.mac.verify k c (akem.mac.tag k c)`.
7. By `akem.mac.correct k c`, this is `true`.
8. Therefore `authDecaps` returns `some k`.

**Key insight:** The proof decomposes into two independent pieces:
- **Key recovery:** follows from `kem_correctness` (Phase 7).
- **Tag verification:** follows from `mac.correct` (the MAC's built-in
  correctness field from 10.1).

The AEAD correctness theorem is a clean composition of these two properties.
No new mathematical content is needed — the proof is purely structural.

**Exit criteria:** Theorem compiles with zero `sorry`. `#print axioms
aead_correctness` shows only standard Lean axioms (no custom axioms, no
`sorryAx`).

---

### 10.4 — INT-CTXT Security Definition

**Effort:** 3h | **File:** `AEAD/AEAD.lean` | **Deps:** 10.2

Define ciphertext integrity (INT-CTXT): no adversary can produce a valid
(ciphertext, tag) pair without knowing the key. This captures the
authentication guarantee — forged ciphertexts are always rejected.

```lean
/-- INT-CTXT: no adversary can forge a valid (ciphertext, tag) pair.
    A (c, t) pair is a forgery if it was not produced by any honest
    encapsulation and yet passes verification. -/
def INT_CTXT (akem : AuthOrbitKEM G X K Tag) : Prop :=
  ∀ (c : X) (t : Tag),
    (∀ g : G, c ≠ (authEncaps akem g).1 ∨
              t ≠ (authEncaps akem g).2.2) →
    authDecaps akem c t = none
```

**Design rationale:**

- **Single-encapsulation setting.** This definition captures existential
  unforgeability where the adversary must forge without having seen any
  honest encapsulations that would provide the same (c, t) pair.
- **Universal quantifier over group elements.** The condition
  `∀ g : G, c ≠ ... ∨ t ≠ ...` says that no honest encapsulation (for
  any group element) could have produced this particular (c, t) pair.
  This is the "no prior queries match" condition from the standard
  INT-CTXT game, stated algebraically.
- **`authDecaps` returns `none`.** The forgery is rejected — the decapsulation
  refuses to release a key for an unauthenticated ciphertext.

**Scope and limitations:**

Extending to multi-query CCA (where the adversary has access to
encapsulation AND decapsulation oracles) requires additional infrastructure:
query logs, excluding queried ciphertexts from the forgery condition, and
adaptive adversary models. This extension is documented as future work and
would naturally belong in a Phase 12+ extension.

The single-encapsulation INT-CTXT is nonetheless valuable: it establishes
the type-level interface for integrity and ensures the MAC composition is
structurally sound.

**Exit criteria:** A well-typed integrity definition compiles.
`lake build Orbcrypt.AEAD.AEAD` succeeds with zero warnings.

---

### Track B: Hybrid Composition (10.5 -> 10.6)

Track B defines the KEM+DEM hybrid encryption paradigm and proves its
correctness. It depends on 10.2 (for the authenticated KEM) and Phase 7
(for the base KEM). Track B can proceed in parallel with 10.3 and 10.4
once 10.2 is complete.

---

### 10.5 — KEM + DEM Composition

**Effort:** 3h | **File:** `AEAD/Modes.lean` | **Deps:** 10.2, Phase 7

Define the standard KEM+DEM composition for encrypting arbitrary-length
data. The KEM produces a symmetric key; the DEM uses that key to encrypt
the actual plaintext with a standard symmetric cipher. This is the
construction that bridges Orbcrypt's group-theoretic key generation with
conventional symmetric encryption (e.g., AES-GCM).

```lean
import Orbcrypt.AEAD.AEAD
import Orbcrypt.KEM.Encapsulate
import Orbcrypt.KEM.Correctness

/-! # KEM + DEM Hybrid Encryption Modes

Defines the Data Encapsulation Mechanism (DEM) and the KEM+DEM hybrid
encryption composition. The KEM produces a symmetric key, the DEM
encrypts the plaintext under that key.

## Key definitions

- `DEM` — Data Encapsulation Mechanism structure
- `hybridEncrypt` — full hybrid encryption (KEM + DEM)
- `hybridDecrypt` — full hybrid decryption (KEM + DEM)
- `hybrid_correctness` — end-to-end correctness theorem
-/

set_option autoImplicit false

variable {G : Type*} {X : Type*} {K : Type*}
  [Group G] [MulAction G X] [DecidableEq X]
variable {Plaintext : Type*} {Ciphertext : Type*}

/-- A Data Encapsulation Mechanism: symmetric encryption keyed by K. -/
structure DEM (K : Type*) (Plaintext : Type*) (Ciphertext : Type*) where
  /-- Symmetric encryption. -/
  enc : K → Plaintext → Ciphertext
  /-- Symmetric decryption. -/
  dec : K → Ciphertext → Option Plaintext
  /-- Correctness: decryption inverts encryption. -/
  correct : ∀ k m, dec k (enc k m) = some m

/-- Full hybrid encryption: KEM produces a key, DEM encrypts the data. -/
def hybridEncrypt (kem : OrbitKEM G X K)
    (dem : DEM K Plaintext Ciphertext)
    (g : G) (m : Plaintext) : X × Ciphertext :=
  let (c_kem, k) := encaps kem g
  (c_kem, dem.enc k m)

/-- Full hybrid decryption. -/
def hybridDecrypt (kem : OrbitKEM G X K)
    (dem : DEM K Plaintext Ciphertext)
    (c_kem : X) (c_dem : Ciphertext) : Option Plaintext :=
  let k := decaps kem c_kem
  dem.dec k c_dem
```

**Design decisions:**

- **`DEM` mirrors `MAC` in structure.** Both have a correctness field as a
  proof obligation. The DEM is a standard symmetric encryption abstraction.
- **`dec` returns `Option Plaintext`** to handle potential decryption failures
  (e.g., padding errors in a real implementation). The `correct` field
  guarantees that honestly encrypted data always decrypts successfully.
- **`hybridEncrypt` returns `(X, Ciphertext)`** — the KEM ciphertext (an orbit
  element) paired with the DEM ciphertext. The receiver needs both to decrypt.
- **`hybridDecrypt` does not verify authenticity.** For authenticated hybrid
  encryption, compose with the `AuthOrbitKEM` from 10.2. The separation
  allows reasoning about hybrid correctness independently of authentication.

**Exit criteria:** Functions type-check. `lake build Orbcrypt.AEAD.Modes`
succeeds with zero warnings.

---

### 10.6 — Hybrid Encryption Correctness

**Effort:** 2h | **File:** `AEAD/Modes.lean` | **Deps:** 10.5

Prove end-to-end correctness of the KEM+DEM hybrid encryption: decrypting
an honestly encrypted message recovers the original plaintext.

```lean
/-- Hybrid encryption correctness: decrypt(encrypt(m)) = some m. -/
theorem hybrid_correctness (kem : OrbitKEM G X K)
    (dem : DEM K Plaintext Ciphertext) (g : G) (m : Plaintext) :
    let (c_kem, c_dem) := hybridEncrypt kem dem g m
    hybridDecrypt kem dem c_kem c_dem = some m
```

**Proof sketch:**

1. Unfold `hybridEncrypt` and `hybridDecrypt`.
2. Let `(c_kem, k) := encaps kem g`. Then `c_dem = dem.enc k m`.
3. In `hybridDecrypt`, `k' := decaps kem c_kem`.
4. By `kem_correctness`, `k' = k` (the KEM correctly recovers the key).
5. Therefore `hybridDecrypt` computes `dem.dec k (dem.enc k m)`.
6. By `dem.correct k m`, this equals `some m`.

**Key insight:** Like `aead_correctness` (10.3), this proof decomposes into
two independent pieces:
- **Key recovery:** `kem_correctness` from Phase 7.
- **Message recovery:** `dem.correct` from the DEM's built-in correctness
  field.

The proof structure is identical to `aead_correctness` — both are
correctness-by-composition results. The mathematical content is trivial;
the value is in establishing the type-level guarantee that the composition
is sound.

**Proof detail:** The core reasoning chain is:

```
hybridDecrypt kem dem c_kem c_dem
  = dem.dec (decaps kem c_kem) c_dem                  -- by definition
  = dem.dec (decaps kem (encaps kem g).1) (dem.enc k m) -- substituting c_kem, c_dem
  = dem.dec (encaps kem g).2 (dem.enc k m)            -- by kem_correctness
  = dem.dec k (dem.enc k m)                           -- k = (encaps kem g).2
  = some m                                            -- by dem.correct
```

**Exit criteria:** Theorem compiles with zero `sorry`. `#print axioms
hybrid_correctness` shows only standard Lean axioms (no custom axioms,
no `sorryAx`).

---

## Internal Dependency Graph

The six work units form two tracks with a shared root:

```
10.1 (MAC Abstraction)
  |
  v
10.2 (AEAD Definition)
  |         \
  |          \
  v           v
10.3        10.4         10.5 (KEM+DEM Composition)
(AEAD       (INT-CTXT      |
Correct-     Security       |
ness)        Defn)          v
                          10.6 (Hybrid Correctness)
```

**Track A (Authentication):** 10.1 -> 10.2 -> 10.3
                                        \-> 10.4

**Track B (Hybrid Composition):** 10.2 -> 10.5 -> 10.6

**Critical path:** 10.1 -> 10.2 -> 10.5 -> 10.6 (10 hours).
Alternatively: 10.1 -> 10.2 -> 10.3 (8 hours).

**Parallelism:** Once 10.2 is complete, the remaining four work units
split into two independent tracks:
- Track A continuation: 10.3 and 10.4 (both depend only on 10.2, and are
  independent of each other — 6 hours combined).
- Track B: 10.5 and 10.6 (sequential, 5 hours combined).

With two parallel workers, the phase can complete in ~10 hours of wall
time (the critical path through 10.1 -> 10.2 -> 10.5 -> 10.6).

**External dependencies:**

```
Phase 7 (KEM)          Phase 9 (Key Compression)
  |                       |
  |  OrbitKEM, encaps,    |  SeedKey, nonceEncaps
  |  decaps,              |  (for integration, not
  |  kem_correctness      |  directly imported)
  |                       |
  v                       v
  +--------> 10.2 <------+
             10.5
```

---

## Risk Analysis

### Risk 1: MAC Formalization Scope Creep

**Risk:** The MAC abstraction could expand into a full formalization of
unforgeability (SUF-CMA, EUF-CMA), requiring probability monads and
oracle access — pulling in Phase 8 as a dependency.

**Mitigation:** Keep the MAC purely algebraic: correctness only, no
security properties on the MAC itself. The INT-CTXT definition (10.4)
captures integrity at the AEAD level, not the MAC level. Security of the
MAC is assumed implicitly through the INT-CTXT hypothesis, just as OIA
is assumed for the KEM. This mirrors the project's established pattern
of stating security assumptions as hypotheses rather than proving them
from lower-level primitives.

**Likelihood:** Low. The work unit descriptions are explicit about scope.

### Risk 2: Type-Level Complexity in AuthOrbitKEM

**Risk:** The `extends OrbitKEM G X K` mechanism in `AuthOrbitKEM` may
cause unification issues or unexpected projections when composing with
`encaps` and `decaps`. Lean 4's structure inheritance can be fragile with
multiple type parameters.

**Mitigation:** If `extends` causes issues, fall back to explicit field
inclusion:

```lean
structure AuthOrbitKEM (G : Type*) (X : Type*) (K : Type*) (Tag : Type*)
    [Group G] [MulAction G X] [DecidableEq X] where
  kem : OrbitKEM G X K
  mac : MAC K X Tag
```

This avoids the `extends` mechanism entirely while preserving the same
interface. The cost is replacing `akem.toOrbitKEM` with `akem.kem`
throughout.

**Likelihood:** Medium. Structure inheritance with 4+ type parameters
is a known friction point in Lean 4.

### Risk 3: kem_correctness Unfolding in AEAD Proof

**Risk:** The `aead_correctness` proof (10.3) requires unfolding through
`authEncaps`, `authDecaps`, `encaps`, and `decaps`. If `kem_correctness`
is opaque (proven by `rfl` at the wrong level of abstraction), the
rewrite may fail.

**Mitigation:** Ensure `kem_correctness` is stated with `simp` or
`unfold`-friendly form. If needed, add intermediate lemmas:

```lean
lemma decaps_encaps_eq (kem : OrbitKEM G X K) (g : G) :
    decaps kem (encaps kem g).1 = (encaps kem g).2 :=
  kem_correctness kem g
```

This provides a named rewrite target that `simp` can use.

**Likelihood:** Low. Phase 7's `kem_correctness` was designed for
composability.

### Risk 4: DEM Abstraction Level

**Risk:** The `DEM` structure is very abstract — it says nothing about
the DEM's security properties (IND-CPA, authenticated encryption, etc.).
This could be seen as a formalization gap.

**Mitigation:** This is by design. The DEM is a black-box symmetric
primitive whose security is assumed, not proven. The formalization
establishes that the KEM+DEM *composition* is correct (preserves
messages), and that the KEM half provides orbit-based key security.
DEM security is orthogonal and would be the subject of a future phase
if needed.

**Likelihood:** Low (this is a design decision, not a risk per se).

---

## Phase Exit Criteria

All of the following must be satisfied before Phase 10 is considered complete:

### Build Verification

- [x] `lake build Orbcrypt.AEAD.MAC` succeeds with exit code 0.
- [x] `lake build Orbcrypt.AEAD.AEAD` succeeds with exit code 0.
- [x] `lake build Orbcrypt.AEAD.Modes` succeeds with exit code 0.
- [x] `lake build` (full project) succeeds with exit code 0.

### Zero Sorry

- [x] `grep -rn "sorry" Orbcrypt/AEAD/ --include="*.lean"` returns empty.

### Zero Custom Axioms

- [x] `grep -rn "^axiom " Orbcrypt/AEAD/ --include="*.lean"` returns empty.
- [x] `#print axioms aead_correctness` — only standard Lean axioms.
- [x] `#print axioms hybrid_correctness` — only standard Lean axioms.

### Theorem Compilation

- [x] `aead_correctness` compiles and type-checks (10.3).
- [x] `hybrid_correctness` compiles and type-checks (10.6).
- [x] `INT_CTXT` definition compiles and is well-typed (10.4).

### Structure Verification

- [x] `MAC` structure type-checks with `correct` field (10.1).
- [x] `AuthOrbitKEM` structure type-checks with `kem : OrbitKEM` field (10.2, Risk 2 mitigation).
- [x] `DEM` structure type-checks with `correct` field (10.5).
- [x] `authEncaps` and `authDecaps` functions type-check (10.2).
- [x] `hybridEncrypt` and `hybridDecrypt` functions type-check (10.5).

### Documentation

- [x] Every `.lean` file has a `/-! ... -/` module docstring.
- [x] Every public definition and theorem has a `/-- ... -/` docstring.
- [x] Proofs longer than 3 lines have strategy comments.

### Integration

- [x] Root import file `Orbcrypt.lean` updated to include:
  - `import Orbcrypt.AEAD.MAC`
  - `import Orbcrypt.AEAD.AEAD`
  - `import Orbcrypt.AEAD.Modes`
- [x] `PRACTICAL_IMPROVEMENTS_PLAN.md` updated with Phase 10 completion status.

---

## Summary Table

| Unit | Title | File | Effort | Deps | Key Deliverable |
|------|-------|------|--------|------|-----------------|
| 10.1 | MAC Abstraction | `AEAD/MAC.lean` | 2h | Mathlib | `MAC` structure with `tag`, `verify`, `correct` |
| 10.2 | AEAD Definition | `AEAD/AEAD.lean` | 3h | 10.1, Phase 7 | `AuthOrbitKEM`, `authEncaps`, `authDecaps` |
| 10.3 | AEAD Correctness | `AEAD/AEAD.lean` | 3h | 10.2 | `aead_correctness` theorem (zero sorry) |
| 10.4 | INT-CTXT Definition | `AEAD/AEAD.lean` | 3h | 10.2 | `INT_CTXT` security definition |
| 10.5 | KEM + DEM Composition | `AEAD/Modes.lean` | 3h | 10.2, Phase 7 | `DEM`, `hybridEncrypt`, `hybridDecrypt` |
| 10.6 | Hybrid Correctness | `AEAD/Modes.lean` | 2h | 10.5 | `hybrid_correctness` theorem (zero sorry) |
| | **Total** | **3 files** | **16h** | | |

**Effort breakdown by file:**

| File | Work Units | Total Effort |
|------|-----------|--------------|
| `AEAD/MAC.lean` | 10.1 | 2h |
| `AEAD/AEAD.lean` | 10.2, 10.3, 10.4 | 9h |
| `AEAD/Modes.lean` | 10.5, 10.6 | 5h |

**Effort breakdown by type:**

| Type | Work Units | Effort |
|------|-----------|--------|
| Structure definitions | 10.1, 10.2, 10.5 | 8h |
| Correctness proofs | 10.3, 10.6 | 5h |
| Security definitions | 10.4 | 3h |

---

*Document generated for Phase 10 of the Orbcrypt Practical Improvements Plan.
See [PRACTICAL_IMPROVEMENTS_PLAN.md](../../formalization/PRACTICAL_IMPROVEMENTS_PLAN.md)
lines 1241–1427 for the master plan source.*
