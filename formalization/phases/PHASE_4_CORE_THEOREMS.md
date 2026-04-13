# Phase 4 — Core Theorems

## Weeks 7–10 | 10 Work Units | ~36 Hours

*Part of the [Orbcrypt Lean 4 Formalization Plan](../FORMALIZATION_PLAN.md)*

---

## Overview

Phase 4 is the heart of the formalization. It proves the three headline
results: correctness, the invariant attack theorem, and the conditional
security reduction (OIA ⟹ IND-1-CPA). Each theorem combines Phase 2's
group action lemmas with Phase 3's cryptographic definitions.

This phase has **three parallel tracks** — one per theorem — joined only by
the optional contrapositive (unit 4.10).

---

## Objectives

1. Machine-checked proof that decryption inverts encryption (DEVELOPMENT.md §4.2).
2. Machine-checked proof that a separating invariant yields a complete break (§4.4).
3. Machine-checked proof that OIA implies IND-1-CPA security (§8.1).

---

## Prerequisites

- Phase 2 complete (all `GroupAction/` lemmas).
- Phase 3 complete (`OrbitEncScheme`, `Adversary`, `hasAdvantage`, `OIA` axiom).

---

## Work Units

### Track A: Correctness (4.1 → 4.2 → 4.3)

#### 4.1 — Encrypt-in-Orbit Lemma

**Effort:** 2h | **Module:** `Theorems/Correctness.lean` | **Deps:** 3.2, 2.4

```lean
/-- The ciphertext lies in the orbit of the representative. -/
theorem encrypt_mem_orbit [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (g : G) (m : M) :
    encrypt scheme g m ∈ MulAction.orbit G (scheme.reps m) := by
  -- encrypt = g • reps m, which is in orbit G (reps m) by smul_mem_orbit
  sorry
```

**Strategy:** Unfold `encrypt`, apply `smul_mem_orbit` from unit 2.4.

#### 4.2 — Canon-of-Encrypt Lemma

**Effort:** 3h | **Module:** `Theorems/Correctness.lean` | **Deps:** 4.1, 2.6

```lean
/-- Canonical form of a ciphertext equals canonical form of the representative. -/
theorem canon_encrypt [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (g : G) (m : M) :
    scheme.canonForm.canon (encrypt scheme g m) =
    scheme.canonForm.canon (scheme.reps m) := by
  -- encrypt is in the orbit of reps m (by 4.1)
  -- Elements in the same orbit have the same canonical form (by 2.6)
  sorry
```

**Strategy:** Chain `encrypt_mem_orbit` (4.1) with `canon_eq_of_mem_orbit` (2.6).

#### 4.3 — Decrypt-of-Encrypt Theorem (Headline Result #1)

**Effort:** 5h | **Module:** `Theorems/Correctness.lean` | **Deps:** 4.2, 3.3

```lean
/--
**Correctness Theorem.** Decryption perfectly inverts encryption.
Formalizes DEVELOPMENT.md §4.2: Pr[Dec(Enc(m)) = m] = 1.
-/
theorem correctness [Group G] [MulAction G X] [DecidableEq X]
    [Fintype M] [DecidableEq M]
    (scheme : OrbitEncScheme G X M) (m : M) (g : G) :
    decrypt scheme (encrypt scheme g m) = some m := by
  -- 1. canon(encrypt g m) = canon(reps m)          [by canon_encrypt]
  -- 2. decrypt looks for m' with canon(c) = canon(reps m')
  -- 3. m is the unique such m' (by reps_distinct + canon uniqueness)
  sorry
```

**Strategy:**
1. Unfold `decrypt` to expose the `Fintype.find?` (or equivalent).
2. Show the predicate `fun m' => canon(c) = canon(reps m')` is true for `m`
   (by `canon_encrypt`).
3. Show it is false for all `m' ≠ m`: if `canon(reps m) = canon(reps m')`,
   then `orbit G (reps m) = orbit G (reps m')` by `orbit_iff`, contradicting
   `reps_distinct`.
4. Conclude `find?` returns `some m`.

**This is the hardest proof in Track A.** The difficulty lies in working with
`Fintype.find?`'s specification. If the Mathlib lemma is hard to use, consider
switching `decrypt` to use `Finset.univ.filter` and proving the filter yields
a singleton.

---

### Track B: Invariant Attack (4.4 → 4.5 → 4.6)

#### 4.4 — Adversary Construction

**Effort:** 4h | **Module:** `Theorems/InvariantAttack.lean` | **Deps:** 3.4, 2.8

```lean
/--
Construct an adversary that uses a separating invariant to break the scheme.
Given f : X → Y with f(x_{m₀}) ≠ f(x_{m₁}) and f G-invariant,
the adversary computes f(c*) and compares to f(x_{m₀}).
-/
def invariantAttackAdversary [DecidableEq Y]
    (f : X → Y) (m₀ m₁ : M) : Adversary X M where
  choose := fun _reps => (m₀, m₁)
  guess := fun reps c => decide (f c = f (reps m₀))
```

**Key point:** The adversary needs `DecidableEq Y` to compare `f c` with
`f (reps m₀)`. This is a reasonable requirement — the invariant attack from
DEVELOPMENT.md §4.4 explicitly computes `f(c*)` and compares.

We use `decide` (or `BEq`) to produce a `Bool` from the decidable proposition.

#### 4.5 — Adversary Correctness

**Effort:** 5h | **Module:** `Theorems/InvariantAttack.lean` | **Deps:** 4.4, 2.9

```lean
/-- The invariant attack adversary always guesses correctly. -/
theorem invariantAttackAdversary_correct [DecidableEq Y]
    [Group G] [MulAction G X]
    (f : X → Y) (m₀ m₁ : M)
    (hInv : IsGInvariant (G := G) f)
    (hSep : f (scheme.reps m₀) ≠ f (scheme.reps m₁))
    (g : G) (b : Bool) :
    let A := invariantAttackAdversary f m₀ m₁
    let c := if b then g • scheme.reps m₁ else g • scheme.reps m₀
    A.guess scheme.reps c = !b := by
  -- Case split on b:
  -- b = false: c = g • reps m₀, f(c) = f(reps m₀) by invariance, guess = true = !false
  -- b = true:  c = g • reps m₁, f(c) = f(reps m₁) ≠ f(reps m₀), guess = false = !true
  sorry
```

**Strategy:** Case split on `b`, then use `invariant_const_on_orbit` (2.9) to
show `f(g • reps m_b) = f(reps m_b)`, then use `hSep` for the `b = true` case.

#### 4.6 — Invariant Attack Theorem (Headline Result #2)

**Effort:** 2h | **Module:** `Theorems/InvariantAttack.lean` | **Deps:** 4.4, 4.5

```lean
/--
**Invariant Attack Theorem.** If a G-invariant function separates two message
orbits, an adversary achieves a complete break.
Formalizes DEVELOPMENT.md §4.4 and the lesson of COUNTEREXAMPLE.md.
-/
theorem invariant_attack [Group G] [MulAction G X] [DecidableEq X]
    [DecidableEq Y]
    (scheme : OrbitEncScheme G X M)
    (f : X → Y) (m₀ m₁ : M)
    (hInv : IsGInvariant (G := G) f)
    (hSep : f (scheme.reps m₀) ≠ f (scheme.reps m₁)) :
    ∃ A : Adversary X M, hasAdvantage scheme A := by
  -- Exhibit invariantAttackAdversary, show it has advantage using 4.5
  sorry
```

**Strategy:** Use `⟨invariantAttackAdversary f m₀ m₁, ...⟩`. To show
`hasAdvantage`, exhibit `g₀ = g₁ = 1` (identity) and use 4.5 to show the
guess differs.

---

### Track C: OIA ⟹ CPA (4.7 → 4.8 → 4.9)

#### 4.7 — Function Specialization

**Effort:** 3h | **Module:** `Theorems/OIAImpliesCPA.lean` | **Deps:** 3.7, 3.4

```lean
/-- Specialize the OIA axiom to the adversary's guess function. -/
theorem oia_specialized [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M)
    (m₀ m₁ : M) (g₀ : G) :
    ∃ g₁ : G,
      A.guess scheme.reps (g₀ • scheme.reps m₀) =
      A.guess scheme.reps (g₁ • scheme.reps m₁) := by
  -- Apply OIA with f := fun x => A.guess scheme.reps x
  sorry
```

**Strategy:** Instantiate the `OIA` axiom with `f := A.guess scheme.reps`.
The OIA gives `∃ g', f(g₀ • reps m₀) = f(g' • reps m₁)`, which is exactly
what we need (since `f x = A.guess scheme.reps x`).

#### 4.8 — Advantage Elimination

**Effort:** 4h | **Module:** `Theorems/OIAImpliesCPA.lean` | **Deps:** 4.7, 3.5

```lean
/-- OIA specialization contradicts `hasAdvantage`. -/
theorem no_advantage_from_oia [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) (A : Adversary X M)
    (hOIA : ∀ (f : X → Bool) (m₀ m₁ : M) (g : G),
      ∃ g' : G, f (g • scheme.reps m₀) = f (g' • scheme.reps m₁)) :
    ¬ hasAdvantage scheme A := by
  -- Unfold hasAdvantage, negate the ∃ to get ∀
  -- For any g₀, use OIA to find g₁ matching the guess, contradiction
  sorry
```

**Strategy:** Unfold `hasAdvantage` as `∃ g₀ g₁, guess(...g₀...) ≠ guess(...g₁...)`.
Negate to show `∀ g₀ g₁, guess(...g₀...) = guess(...g₁...)`. Use OIA: for any
g₀, ∃ g₁' such that guess on orbit 0 with g₀ = guess on orbit 1 with g₁'.
Then for any other g₁, use OIA again to relate. Transitivity gives equality.

**Note:** The exact proof structure depends on how `hasAdvantage` unfolds with
the `let (m₀, m₁) := ...` binding. May need `Prod.fst`/`Prod.snd` rewriting.

#### 4.9 — OIA ⟹ IND-1-CPA (Headline Result #3)

**Effort:** 2h | **Module:** `Theorems/OIAImpliesCPA.lean` | **Deps:** 4.7, 4.8

```lean
/--
**Security Theorem.** The OIA implies IND-1-CPA security.
Formalizes DEVELOPMENT.md §8.1.
-/
theorem oia_implies_1cpa [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M) :
    IsSecure scheme := by
  -- IsSecure = ∀ A, ¬ hasAdvantage scheme A
  -- For each A, apply no_advantage_from_oia using the OIA axiom
  intro A
  apply no_advantage_from_oia
  exact fun f m₀ m₁ g => OIA scheme f m₀ m₁ g
```

**Strategy:** Unfold `IsSecure`, introduce adversary `A`, delegate to
`no_advantage_from_oia` (4.8), supply the `OIA` axiom. This should be
short once 4.8 is proved.

---

### Optional: Contrapositive (4.10)

#### 4.10 — Insecurity Implies Separating Function

**Effort:** 6h | **Module:** `Theorems/OIAImpliesCPA.lean` | **Deps:** 4.6, 4.9

```lean
/--
**Contrapositive.** If the scheme is insecure (some adversary has advantage),
then a separating function exists (namely, the adversary's guess function
restricted to the relevant orbits).

This is the converse direction of the invariant attack theorem, establishing
a precise equivalence between insecurity and the existence of distinguishers.
-/
theorem insecure_implies_separating [Group G] [MulAction G X] [DecidableEq X]
    (scheme : OrbitEncScheme G X M)
    (A : Adversary X M) (hAdv : hasAdvantage scheme A) :
    ∃ (f : X → Bool) (m₀ m₁ : M),
      ∃ g₀ g₁ : G, f (g₀ • scheme.reps m₀) ≠ f (g₁ • scheme.reps m₁) := by
  sorry
```

**Note:** This is optional but valuable. It shows that the OIA is not just
sufficient but in some sense necessary. The proof extracts the distinguishing
function directly from the adversary. Mark as stretch goal if time is tight.

---

## Parallel Execution Plan

```
Phase 3 complete
     │
     ├─────────────────┬─────────────────┐
     ▼                 ▼                 ▼
  Track A           Track B           Track C
  Correctness       Invariant Attack   OIA ⟹ CPA
  ┌──────────┐      ┌──────────┐      ┌──────────┐
  │ 4.1      │      │ 4.4      │      │ 4.7      │
  │ 4.2      │      │ 4.5      │      │ 4.8      │
  │ 4.3      │      │ 4.6      │      │ 4.9      │
  └──────────┘      └──────────┘      └──────────┘
     │                 │                 │
     └─────────────────┴─────────────────┘
                       │
                       ▼
                 4.10 Contrapositive (optional)
```

All three tracks are fully independent and can execute in parallel.

---

## Risk Analysis

| Risk | Units | Likelihood | Impact | Mitigation |
|------|-------|-----------|--------|------------|
| `Fintype.find?` spec hard to work with | 4.3 | High | High | Try `Finset.univ.filter` approach; redesign `decrypt` if needed |
| `let (m₀, m₁) := ...` awkward in proofs | 4.8 | Medium | Medium | Refactor `hasAdvantage` to use explicit `Prod.fst`/`Prod.snd` |
| `decide` / `BEq` coercion issues in 4.4 | 4.4, 4.5 | Medium | Low | Use explicit `if ... then true else false` pattern |
| OIA axiom too strong (trivially false) | 4.7–4.9 | Low | Critical | Validate by constructing a toy model where OIA holds |
| Proof of 4.3 requires 5+ hours of Lean wrangling | 4.3 | High | Medium | Budget extra time; this is the hardest unit |

---

## Exit Criteria

- [ ] `Theorems/Correctness.lean` compiles without `sorry`
- [ ] `Theorems/InvariantAttack.lean` compiles without `sorry`
- [ ] `Theorems/OIAImpliesCPA.lean` compiles without `sorry` (axiom `OIA` is acceptable)
- [ ] `lake build` succeeds with zero errors
- [ ] `#print axioms correctness` shows only standard Lean axioms (no `OIA`)
- [ ] `#print axioms invariant_attack` shows only standard Lean axioms (no `OIA`)
- [ ] `#print axioms oia_implies_1cpa` shows `OIA` plus standard axioms
- [ ] All three headline theorems have docstrings

---

## Transition to Phase 5

Phase 5 instantiates the abstract framework with the concrete S\_n action on
bitstrings, producing a working `OrbitEncScheme` instance and formally proving
that the Hamming weight defense works.

See: [Phase 5 — Concrete Construction](PHASE_5_CONCRETE_CONSTRUCTION.md)
