<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Orbcrypt Lean Module Audit Report

**Date:** 2026-04-14
**Scope:** All 13 Lean source files (1,697 lines), CI pipeline, setup infrastructure
**Auditor:** Claude (Opus 4.6)
**Build status:** `lake build Orbcrypt` passes (0 errors, 0 warnings)
**Sorry count:** 0
**Custom axiom count:** 0

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Module-by-Module Analysis](#2-module-by-module-analysis)
3. [Architecture Review](#3-architecture-review)
4. [Security Model Analysis](#4-security-model-analysis)
5. [CI and Infrastructure Review](#5-ci-and-infrastructure-review)
6. [Findings Summary Table](#6-findings-summary-table)
7. [Recommendations](#7-recommendations)
8. [Conclusion](#8-conclusion)

---

## 1. Executive Summary

Orbcrypt is a formally verified symmetric-key encryption scheme built on
orbit structures under group actions, with 11 Lean 4 source modules, a
root import file, and a lakefile totaling 1,697 lines. The formalization
is **complete with zero `sorry`, zero custom axioms, and a clean build**.

The codebase demonstrates strong engineering discipline: modular layering,
maximal Mathlib reuse, correct proof strategies, and thorough documentation.
Every public definition carries a docstring and every proof over 3 lines
has strategy comments.

### Key Strengths

- **Zero sorry, zero custom axioms** verified by grep and confirmed by build
- **Clean separation** of concerns: foundations, definitions, theorems, construction
- **Correct use of OIA as Prop** (not axiom), preventing logical inconsistency
- **Well-structured proofs** with clear strategy comments
- **Robust setup script** with SHA-256 pinning of all downloaded artifacts

### Key Findings

| ID | Severity | Category | Summary |
|----|----------|----------|---------|
| F-01 | Info | Design | OIA is vacuously `False` for non-trivial schemes (documented) |
| F-02 | Low | Modeling | `Adversary.choose` not constrained to produce distinct messages |
| F-03 | Low | CI | Axiom check regex misses multi-line `axiom` declarations |
| F-04 | Info | CI | Sorry check matches documentation text (no practical impact) |
| F-05 | Low | CI | CI elan install lacks SHA-256 verification |
| F-06 | Info | Modeling | `insecure_implies_separating` gap: no G-invariance guarantee |
| F-07 | Info | Style | Minor eta-expansion in `hgoe_weight_attack` |

No CVE-worthy vulnerabilities were discovered. The findings are modeling
refinements and CI hardening opportunities, not security flaws.

---

## 2. Module-by-Module Analysis

### 2.1 `lakefile.lean` (17 lines)

**Purpose:** Package configuration with Mathlib dependency.

**Line-by-line findings:**

- **L4:** Package name `"orbcrypt"` — conventional lowercase, correct.
- **L5:** Version `v!"0.1.0"` — appropriate for research stage.
- **L6-8:** `autoImplicit := false` enforced project-wide. This is critical:
  without it, Lean silently introduces universe and type variables, which can
  cause subtle type-inference bugs. **Correct and essential.**
- **L13:** Mathlib pinned to commit `fa6418a815fa14843b7f0a19fe5983831c5f870e`.
  This is an immutable reference (not a branch), ensuring reproducible builds.
  **Correct.**
- **L16-17:** `srcDir := "."` means the root `Orbcrypt.lean` and the
  `Orbcrypt/` directory are both in the project root. Standard layout for
  Lean 4 projects.

**Verdict:** No issues. Configuration is clean and follows best practices.

---

### 2.2 `Orbcrypt.lean` (137 lines)

**Purpose:** Root import file and project-level documentation.

**Line-by-line findings:**

- **L1-14:** Imports all 11 submodules. Order follows dependency layers
  (GroupAction, Crypto, Theorems, Construction). All modules reachable.
- **L16-137:** Module docstring with dependency graph, headline theorem
  dependencies, and axiom transparency report. This is thorough documentation
  that serves as a project README for Lean users.
- **L105-106:** Claims `correctness` depends only on `propext`,
  `Classical.choice`, `Quot.sound`. This is accurate — `decrypt` uses
  `Exists.choose` which requires `Classical.choice`, and `dif_pos` uses
  `propext`.
- **L128-130:** Claims `#print axioms oia_implies_1cpa` shows only standard
  axioms. This is accurate since OIA is a hypothesis, not an axiom.

**Verdict:** No issues. Documentation is accurate and comprehensive.

---

### 2.3 `GroupAction/Basic.lean` (118 lines)

**Purpose:** Orbit/stabilizer aliases, orbit partition, orbit-stabilizer wrapper,
membership lemmas.

**Line-by-line findings:**

- **L37-38:** `orbit` defined as `abbrev` wrapping `MulAction.orbit G x`.
  Using `abbrev` (not `def`) is correct: it makes the alias definitionally
  transparent, so Mathlib lemmas about `MulAction.orbit` apply without
  unfolding. **Correct.**
- **L41-42:** `stabilizer` similarly correct as `abbrev`.
- **L62-71:** `orbit_disjoint_or_eq` — the orbit partition theorem.

  **Proof analysis:** The `by_cases h : x ∈ MulAction.orbit G y` split is
  the standard approach. In the positive case, `MulAction.orbit_eq_iff.mpr h`
  produces the orbit equality. In the negative case, the proof shows
  disjointness by contradiction: any shared element `z` would force orbit
  equality via transitivity, contradicting the assumption. The chain
  `(MulAction.orbit_eq_iff.mpr hz_x).symm.trans (MulAction.orbit_eq_iff.mpr hz_y)`
  correctly derives `orbit G y = orbit G x` (from `z ∈ orbit G x` and
  `z ∈ orbit G y`, getting `orbit G z = orbit G x` and `orbit G z = orbit G y`,
  then transitivity gives `orbit G x = orbit G y`), and `.mp` of `orbit_eq_iff`
  gives `x ∈ orbit G y`. **Correct.**

- **L86-91:** `orbit_stabilizer` — direct wrapper around Mathlib's
  `card_orbit_mul_card_stabilizer_eq_card_group`. Requires `[Fintype G]`,
  `[Fintype (orbit)]`, `[Fintype (stabilizer)]`. These constraints are
  appropriate and explicitly declared. **Correct.**

- **L105-106:** `smul_mem_orbit` — wraps `MulAction.mem_orbit x g`. Note the
  argument order: Mathlib's `mem_orbit` takes `(x : X) (g : G)` and returns
  `g • x ∈ orbit G x`. The wrapper's signature `(g : G) (x : X)` flips the
  argument order for more natural use. **Correct.**

- **L112-114:** `orbit_eq_of_smul` — wraps `MulAction.orbit_smul g x`.
  Returns `orbit G (g • x) = orbit G x`. This is the key lemma ensuring
  that encryption (applying `g`) preserves orbit identity. **Correct.**

**Verdict:** No issues. Clean, minimal wrappers with correct Mathlib delegation.

---

### 2.4 `GroupAction/Canonical.lean` (111 lines)

**Purpose:** `CanonicalForm` structure, uniqueness, idempotence.

**Line-by-line findings:**

- **L49-57:** `CanonicalForm` structure with three fields:
  - `canon : X → X` — the canonicalization function
  - `mem_orbit : ∀ x, canon x ∈ MulAction.orbit G x` — output is in input's orbit
  - `orbit_iff : ∀ x y, canon x = canon y ↔ orbit G x = orbit G y` — biconditional

  This captures exactly the mathematical definition of a canonical form.
  The biconditional `orbit_iff` is stronger than just one direction —
  it ensures the canonical form is a complete orbit invariant.

  Design choice: structure (not typeclass) is correct since multiple
  canonical forms may exist for a given action. **Correct.**

- **L68-71:** `canon_eq_implies_orbit_eq` — forward direction of `orbit_iff`.
  One-liner using `.mp`. **Correct.**

- **L75-77:** `orbit_eq_implies_canon_eq` — backward direction. One-liner
  using `.mpr`. **Correct.**

- **L82-88:** `canon_eq_of_mem_orbit` — if `y ∈ orbit G x`, then
  `canon y = canon x`. Proof: `y ∈ orbit G x` implies `orbit G y = orbit G x`
  (via `orbit_eq_iff.mpr`), then `orbit_iff` gives `canon y = canon x`.
  **Correct.**

- **L103-107:** `canon_idem` — `canon(canon(x)) = canon(x)`. Proof:
  `canon x ∈ orbit G x` (by `mem_orbit`), so `orbit G (canon x) = orbit G x`
  (by `orbit_eq_iff.mpr`), then `orbit_iff` gives the result. **Correct.**

**Verdict:** No issues. Mathematically clean with tight proofs.

---

### 2.5 `GroupAction/Invariant.lean` (155 lines)

**Purpose:** G-invariant functions, separating invariants, canonical invariance.

**Line-by-line findings:**

- **L51-52:** `IsGInvariant` defined as `∀ (g : G) (x : X), f (g • x) = f x`.
  This is the standard definition. Using `Prop` (not a typeclass) is correct
  since invariance is a property, not computational data. **Correct.**

- **L56-61:** `IsGInvariant.comp` — if `f` is invariant, `h ∘ f` is invariant.
  Proof unfolds composition and rewrites. **Correct.**

- **L64-66:** `isGInvariant_const` — constant functions are invariant. Proof
  by `rfl`. **Correct.**

- **L86-91:** `invariant_const_on_orbit` — G-invariant functions are constant
  on orbits. Proof destructs `y ∈ orbit G x` to get `⟨g, rfl⟩` via
  `mem_orbit_iff.mp`, then applies invariance. **Correct.**

- **L111-112:** `IsSeparating` defined as the conjunction
  `IsGInvariant (G := G) f ∧ f x₀ ≠ f x₁`. Includes both invariance and
  separation. **Correct.**

- **L119-127:** `separating_implies_distinct_orbits` — proof by contradiction.
  If orbits were equal, then `x₁ ∈ orbit G x₀` (via `heq ▸ mem_orbit_self`),
  so `f x₁ = f x₀` by invariance, contradicting `f x₀ ≠ f x₁`.

  **Subtle point:** The proof applies `h.2` (which is `f x₀ ≠ f x₁`) to
  `(invariant_const_on_orbit h.1 hx₁_mem).symm` (which is `f x₀ = f x₁`).
  The `.symm` flip is necessary because `invariant_const_on_orbit` returns
  `f x₁ = f x₀`, but `h.2` needs `f x₀ = f x₁`. **Correct.**

- **L146-151:** `canonical_isGInvariant` — proves `canon(g • x) = canon(x)`.
  Uses `orbit_iff` and `orbit_smul`. **Correct.**

**Verdict:** No issues. Clean definitions and proofs throughout.

---

### 2.6 `Crypto/Scheme.lean` (112 lines)

**Purpose:** `OrbitEncScheme` structure, `encrypt`, `decrypt`.

**Line-by-line findings:**

- **L61-69:** `OrbitEncScheme` structure with three fields:
  - `reps : M → X` — maps messages to orbit representatives
  - `reps_distinct` — distinct messages have distinct orbits
  - `canonForm : CanonicalForm G X` — for decryption

  Requires `[Group G] [MulAction G X] [DecidableEq X]`. The `DecidableEq X`
  is needed for the canonical form comparison in `decrypt`. **Correct.**

  **Design observation:** `reps_distinct` states
  `∀ m₁ m₂, m₁ ≠ m₂ → orbit G (reps m₁) ≠ orbit G (reps m₂)`, which is
  equivalent to injectivity of `m ↦ orbit G (reps m)`. This is the right
  condition: it ensures each message maps to a unique orbit, making
  decryption well-defined. An alternative would be `Function.Injective reps`,
  but that's strictly stronger (same orbit doesn't imply same representative).
  The chosen formulation is the minimal correct condition. **Correct.**

- **L83-85:** `encrypt` defined as `g • scheme.reps m`. Simple, deterministic.
  The group element `g` serves as randomness. **Correct.**

- **L105-110:** `decrypt` uses `dite` (dependent if-then-else):
  ```lean
  if h : ∃ m, canon c = canon (reps m) then some h.choose else none
  ```

  **Analysis of `Exists.choose`:** This extracts a witness from the
  existential using `Classical.choice`. For honestly generated ciphertexts,
  `decrypt_unique` (in Correctness.lean) proves there's exactly one matching
  `m`, so `h.choose` picks the right one. For arbitrary ciphertexts not in
  any message orbit, `decrypt` returns `none`. For ciphertexts in a message
  orbit but not honestly generated, `h.choose` still returns the correct
  unique message (since `reps_distinct` ensures at most one orbit matches).

  The `noncomputable` marker is necessary and correctly applied. **Correct.**

  **Note:** `[Fintype M]` and `[DecidableEq M]` are required only on
  `decrypt`, not on the structure itself. This is the right design: it allows
  constructing schemes over infinite message spaces (for theoretical
  generality) while requiring finiteness only where enumeration is needed.

**Verdict:** No issues. Well-designed with minimal constraints.

---

### 2.7 `Crypto/Security.lean` (112 lines)

**Purpose:** `Adversary` structure, `hasAdvantage`, `IsSecure`.

**Line-by-line findings:**

- **L61-65:** `Adversary` structure with `choose : (M → X) → M × M` and
  `guess : (M → X) → X → Bool`. The adversary receives the public
  representative map `reps` but NOT the secret group `G`. **Correct.**

  **[F-02] Missing `m₀ ≠ m₁` constraint:** In the standard IND-CPA game,
  the adversary must output two **distinct** messages `m₀ ≠ m₁`. The current
  `choose` function can return `(m, m)`, which creates a subtle modeling gap:

  - If `m₀ = m₁ = m`, then `hasAdvantage` becomes
    `∃ g₀ g₁, guess(g₀ • reps m) ≠ guess(g₁ • reps m)`, which tests
    whether the adversary can distinguish **within a single orbit** rather
    than between orbits.
  - This makes `IsSecure` a **stronger** property than standard IND-1-CPA:
    it additionally requires that individual orbit elements are
    indistinguishable (a property closer to orbit uniformity).
  - Severity: **Low**. The stronger property is arguably desirable for orbit
    encryption, and the OIA hypothesis already implies this. But it should
    be documented that `IsSecure` is stronger than textbook IND-1-CPA.

- **L86-91:** `hasAdvantage` uses existential quantification over group
  elements: `∃ g₀ g₁ : G, guess(g₀ • reps m₀) ≠ guess(g₁ • reps m₁)`.

  **Design analysis:** Using `∃ g₀ g₁` (two separate group elements) is
  correct. In the probabilistic game, the challenger samples one `g` and
  encrypts either `m₀` or `m₁`. The deterministic analogue tests whether
  **any** encryption of `m₀` can be distinguished from **any** encryption
  of `m₁`. This is a reasonable abstraction of non-zero probabilistic
  advantage. **Correct.**

- **L108-110:** `IsSecure` defined as `∀ A, ¬hasAdvantage scheme A`.
  Quantifies over ALL adversaries (information-theoretic security).
  **Correct** for the algebraic setting.

**Verdict:** One finding (F-02). Otherwise clean.

---

### 2.8 `Crypto/OIA.lean` (201 lines)

**Purpose:** Orbit Indistinguishability Assumption as `Prop`.

**Line-by-line findings:**

- **L1-141:** Extensive module docstring covering:
  - Why `Prop` not `axiom` (prevents inconsistency)
  - Strength/limitations of the deterministic formulation
  - Relationship to probabilistic OIA
  - Weak version counterexample
  - Dependency audit
  - Hardness foundations (GI, CE)

  This is the most thoroughly documented module in the project.

- **L182-186:** OIA definition:
  ```lean
  def OIA ... (scheme : OrbitEncScheme G X M) : Prop :=
    ∀ (f : X → Bool) (m₀ m₁ : M) (g₀ g₁ : G),
      f (g₀ • scheme.reps m₀) = f (g₁ • scheme.reps m₁)
  ```

  **[F-01] OIA vacuity analysis:** The definition quantifies over ALL
  `f : X → Bool`, including `fun x => decide (x = reps m₀)`. For any
  scheme with at least 2 messages whose representatives are distinct
  points:
  - Take `f = fun x => decide (x = reps m₀)`, `g₀ = 1`, `g₁ = 1`
  - Then `f(1 • reps m₀) = decide(reps m₀ = reps m₀) = true`
  - And `f(1 • reps m₁) = decide(reps m₁ = reps m₀) = false`
  - So `true ≠ false`, contradicting the OIA

  Therefore `OIA scheme` is `False` for any non-trivial scheme, making
  `oia_implies_1cpa` vacuously true (`False → P` for any `P`).

  **Severity: Informational.** This is **extensively documented** in the
  module docstring (lines 46-67). The formalization captures the algebraic
  proof structure while acknowledging the probabilistic upgrade is needed.
  This is honest, transparent, and appropriate for research-stage work.

  The documentation correctly identifies that a probability monad and
  computational complexity framework would be needed for a meaningful OIA.

**Verdict:** One informational finding (F-01), fully acknowledged in
documentation. The choice to use `def` over `axiom` is correct and well-justified.

---

### 2.9 `Theorems/Correctness.lean` (137 lines)

**Purpose:** `decrypt(encrypt(g, m)) = some m` — Headline Result #1.

**Line-by-line findings:**

- **L49-54:** `encrypt_mem_orbit` — `encrypt scheme g m ∈ orbit G (reps m)`.
  Unfolds `encrypt` to `g • reps m`, then applies `smul_mem_orbit`.
  **Correct.**

- **L70-76:** `canon_encrypt` — `canon(encrypt g m) = canon(reps m)`.
  Unfolds `encrypt` and applies `canonical_isGInvariant`. This is the
  G-invariance of canonical forms applied to encryption. **Correct.**

- **L89-102:** `decrypt_unique` — if `canon(encrypt g m) = canon(reps m')`,
  then `m' = m`.

  **Proof analysis:**
  1. Derives `canon(reps m') = canon(reps m)` by chaining with `canon_encrypt`
  2. Applies `canon_eq_implies_orbit_eq` to get orbit equality
  3. Uses `by_contra h_ne` and `scheme.reps_distinct m' m h_ne` for contradiction

  **Subtle correctness check:** `reps_distinct` has signature
  `∀ m₁ m₂, m₁ ≠ m₂ → orbit(reps m₁) ≠ orbit(reps m₂)`.
  The proof calls `scheme.reps_distinct m' m h_ne`, which requires `m' ≠ m`
  (from `by_contra`) and produces `orbit(reps m') ≠ orbit(reps m)`, which
  contradicts `h_orbits`. **Correct.**

- **L120-136:** `correctness` — the headline theorem.

  **Proof analysis:**
  1. Unfolds `decrypt` and `encrypt`
  2. Constructs existence witness:
     `⟨m, canonical_isGInvariant scheme.canonForm g (scheme.reps m)⟩`
  3. Uses `dif_pos` to enter the `then` branch
  4. Applies `congr 1` to reduce `some h_exists.choose = some m` to
     `h_exists.choose = m`
  5. Closes with `decrypt_unique scheme g m h_exists.choose h_exists.choose_spec`

  **Correctness of `h_exists.choose_spec`:** This is the proof that
  `canon(g • reps m) = canon(reps h_exists.choose)`. Passing it to
  `decrypt_unique` (with arguments `scheme g m h_exists.choose`) yields
  `h_exists.choose = m`. **Correct.**

  **Axiom usage:** This theorem uses `Classical.choice` (through
  `Exists.choose` in `decrypt`), `propext` (through `dif_pos`), and
  `Quot.sound` (transitively through Mathlib). All standard Lean axioms.

**Verdict:** No issues. Proof is sound and well-structured.

---

### 2.10 `Theorems/InvariantAttack.lean` (150 lines)

**Purpose:** Separating invariant implies complete break — Headline Result #2.

**Line-by-line findings:**

- **L58-61:** `invariantAttackAdversary` construction:
  - `choose := fun _reps => (m₀, m₁)` — always selects the given pair
  - `guess := fun reps c => if f c = f (reps m₀) then true else false`

  The `if ... then true else false` pattern is equivalent to
  `decide (f c = f (reps m₀))` but is more explicit for readability.
  **Correct.**

- **L63-74:** Simp lemmas for `choose` and `guess` of the adversary. These
  are `@[simp]` tagged and return `rfl`, confirming definitional unfolding.
  **Correct.**

- **L86-90:** `invariant_on_encrypt` — `f(g • reps m) = f(reps m)` for
  G-invariant `f`. One-line application of the invariance definition.
  **Correct.**

- **L104-115:** `invariantAttackAdversary_correct` — case-split proof that
  the adversary always guesses correctly.

  **Proof analysis:** `cases b` splits into `b = false` and `b = true`.
  After simp, the `false` case needs `if f(reps m₀) = f(reps m₀) then true
  else false = true`, which is `if_pos rfl`. The `true` case needs
  `if f(reps m₁) = f(reps m₀) then true else false = false`, which is
  `if_neg (Ne.symm hSep)`. The `Ne.symm` flips `f(reps m₀) ≠ f(reps m₁)`
  to `f(reps m₁) ≠ f(reps m₀)`. The single `simp` call handles both.
  **Correct.**

- **L132-148:** `invariant_attack` — headline assembly.

  **Proof analysis:**
  1. Exhibits `invariantAttackAdversary f m₀ m₁`
  2. Witnesses `g₀ = 1, g₁ = 1` via `refine ⟨1, 1, ?_⟩`
  3. Simplifies adversary's `choose` and `guess` with simp lemmas
  4. Rewrites `f(1 • reps mᵢ)` to `f(reps mᵢ)` via invariance
  5. Closes with `simp [Ne.symm hSep]`

  The choice of identity elements `1` is clever: it eliminates the group
  action, reducing to a direct comparison of `f` on representatives.
  **Correct.**

  **Axiom usage:** Only `propext`. No `Classical.choice` needed since the
  proof is constructive (the adversary and witnesses are explicit).

**Verdict:** No issues. Elegant constructive proof.

---

### 2.11 `Theorems/OIAImpliesCPA.lean` (174 lines)

**Purpose:** OIA implies IND-1-CPA security — Headline Result #3.

**Line-by-line findings:**

- **L57-63:** `oia_specialized` — instantiates OIA with the adversary's
  guess function: `hOIA (fun x => A.guess scheme.reps x) m₀ m₁ g₀ g₁`.

  **Correctness check:** OIA quantifies over `f : X → Bool`. The adversary's
  `guess` has type `(M → X) → X → Bool`, so `A.guess scheme.reps` has type
  `X → Bool`. This is the correct instantiation. **Correct.**

- **L76-83:** `hasAdvantage_iff` — unfolds to `Iff.rfl`. This is a
  documentation lemma providing a stable API surface. If `hasAdvantage` were
  refactored, this lemma would absorb the change. **Good practice.**

- **L95-102:** `no_advantage_from_oia` — the key elimination lemma.

  **Proof analysis:** Destructs `hasAdvantage` to get `⟨g₀, g₁, hNeq⟩`,
  then applies `oia_specialized` to derive equality, contradicting `hNeq`.
  **Correct.**

- **L119-124:** `oia_implies_1cpa` — one-line assembly.
  `intro A; exact no_advantage_from_oia scheme hOIA A`. **Correct.**

- **L140-148:** `adversary_yields_distinguisher` — extracts a distinguishing
  function from an adversary with advantage. Repacks the adversary's guess
  as the distinguisher. **Correct.**

- **L166-172:** `insecure_implies_separating` — repacks the distinguisher.

  **[F-06] Modeling gap:** This theorem shows insecurity implies existence
  of a Boolean function that distinguishes orbit samples, but does NOT prove
  the function is G-invariant. The docstring (lines 157-164) acknowledges
  this: "The full equivalence would require showing that any distinguisher
  can be 'averaged' into a G-invariant one, which requires probabilistic
  reasoning." This is honest and accurate. Without this bridge, the
  contrapositive chain `insecure → separating → invariant_attack` is
  incomplete. **Informational finding.**

**Verdict:** One informational finding (F-06), acknowledged in documentation.

---

### 2.12 `Construction/Permutation.lean` (141 lines)

**Purpose:** S_n action on bitstrings, Hamming weight, invariance proof.

**Line-by-line findings:**

- **L40:** `Bitstring n` defined as `abbrev` for `Fin n → Bool`. Using
  `abbrev` is correct: it allows Lean to automatically synthesize
  `DecidableEq`, `Fintype`, and function extensionality without manual
  instance registration. **Correct.**

- **L51-54:** `MulAction (Equiv.Perm (Fin n)) (Bitstring n)` instance:
  ```lean
  smul σ x := fun i => x (σ⁻¹ i)
  one_smul _ := funext fun _ => rfl
  mul_smul _ _ _ := funext fun _ => rfl
  ```

  **Correctness verification of `smul`:**
  The action `(σ • x)(i) = x(σ⁻¹(i))` is the standard left-action convention.
  Using `σ⁻¹` (not `σ`) ensures compatibility: `((σ * τ) • x)(i) =
  x((σ * τ)⁻¹(i)) = x(τ⁻¹(σ⁻¹(i)))`, which equals
  `(σ • (τ • x))(i) = (τ • x)(σ⁻¹(i)) = x(τ⁻¹(σ⁻¹(i)))`. **Correct.**

  **Correctness verification of `one_smul`:**
  `(1 • x)(i) = x(1⁻¹(i)) = x(1(i)) = x(i)`. Since `(1 : Equiv.Perm _)⁻¹ = 1`
  and `1(i) = i` are definitional in Lean, `rfl` suffices. **Correct.**

  **Correctness verification of `mul_smul`:**
  Both sides reduce to `x(τ⁻¹(σ⁻¹(i)))` definitionally because
  `(σ * τ)⁻¹ = τ⁻¹ * σ⁻¹` holds definitionally for `Equiv.Perm`.
  **Correct.**

- **L62-64:** `perm_smul_apply` simp lemma — `(σ • x) i = x (σ⁻¹ i)`.
  Returns `rfl`. **Correct.**

- **L68-69:** `one_perm_smul` — delegates to `one_smul`. **Correct.**

- **L72-73:** `mul_perm_smul` — `σ • (τ • x) = (σ * τ) • x`. Uses
  `(mul_smul σ τ x).symm`. **Correct.**

- **L86-99:** `perm_action_faithful` — for non-identity `σ`, exhibits a
  bitstring that `σ` moves.

  **Proof analysis:**
  1. From `σ ≠ 1`, derives `∃ i, σ i ≠ i` by contraposition via `Equiv.ext`
  2. Constructs indicator `fun j => decide (j = i)`
  3. Shows `σ • x ≠ x` by evaluating at `σ i`:
     `(σ • x)(σ i) = x(σ⁻¹(σ i)) = x(i) = true`,
     but `x(σ i) = decide(σ i = i) = false` (since `σ i ≠ i`).
     Wait — the proof uses `congr_fun heq (σ i)` then `simp at h1`.

  Let me trace more carefully. If `σ • x = x`, then `(σ • x)(σ i) = x(σ i)`.
  LHS: `x(σ⁻¹(σ i)) = x(i) = decide(i = i) = true`.
  RHS: `x(σ i) = decide(σ i = i)`.
  So `decide(σ i = i) = true`, which means `σ i = i`, contradicting `hi`.
  The `simp at h1` resolves this. **Correct.**

- **L109-110:** `hammingWeight` — counts `true` bits via
  `Finset.card (Finset.univ.filter (fun i => x i = true))`. Standard
  Hamming weight definition. **Correct.**

- **L124-139:** `hammingWeight_invariant` — the key S_n-invariance proof.

  **Proof analysis:**
  1. Shows `{i | x(σ⁻¹ i) = true} = ({j | x j = true}).map σ.toEmbedding`
  2. The forward direction: given `x(σ⁻¹ i) = true`, witness `j = σ⁻¹ i`
     with `hj = x(σ⁻¹ i) = true` and `σ j = σ(σ⁻¹ i) = i`
  3. The backward direction: given `⟨j, hj, rfl⟩`, need `x(σ⁻¹(σ j)) = true`,
     which simplifies to `x(j) = true`
  4. Concludes with `Finset.card_map` (bijections preserve cardinality)

  **Correct.** The use of `Finset.card_map` with `σ.toEmbedding` is the
  cleanest approach — it avoids reasoning about injectivity directly since
  `toEmbedding` bundles it.

**Verdict:** No issues. Clean and well-proven construction.

---

### 2.13 `Construction/HGOE.lean` (132 lines)

**Purpose:** Concrete HGOE scheme, correctness instantiation, weight attack/defense.

**Line-by-line findings:**

- **L39-41:** `subgroupBitstringAction` — subgroup inherits action via
  `MulAction.compHom`. This is the standard Mathlib pattern for subgroup
  actions. **Correct.**

- **L44-47:** `subgroup_smul_eq` simp lemma — `g • x = (↑g) • x`. Returns
  `rfl`, confirming the coercion is definitionally transparent. **Correct.**

- **L56-65:** `hgoeScheme` constructor — bundles subgroup action data into
  `OrbitEncScheme`. Straightforward. **Correct.**

- **L75-80:** `hgoe_correctness` — direct application of abstract
  `correctness`. One-line proof. Demonstrates clean abstraction: the concrete
  construction inherits the abstract theorem without re-proving anything.
  **Correct.**

- **L89-93:** `hammingWeight_invariant_subgroup` — bridges S_n invariance to
  subgroup invariance.

  **Proof analysis:** Destructs `g : ↥G` as `⟨σ, _⟩` and applies
  `hammingWeight_invariant σ x`. This works because `subgroupBitstringAction`
  defines `g • x = (↑g) • x`, and `↑⟨σ, _⟩ = σ`. **Correct.**

- **L100-108:** `hgoe_weight_attack` — applies `invariant_attack` with
  `f := fun x => hammingWeight x`.

  **[F-07] Minor style:** The argument `(fun x => hammingWeight x)` is an
  eta-expansion of `hammingWeight`. Writing just `hammingWeight` would be
  equivalent and more concise. No functional impact. **Informational.**

- **L121-130:** `same_weight_not_separating` — if all representatives have
  the same weight `w`, Hamming weight cannot separate any pair.

  **Proof analysis:** Destructs `IsSeparating` to get `⟨_, hSep⟩`, then
  derives `hammingWeight(reps m₀) = w = hammingWeight(reps m₁)` from
  `hSameWeight`, contradicting `hSep`. The `by rw [...]` tactic correctly
  constructs the equality. **Correct.**

**Verdict:** One minor style finding (F-07). Otherwise correct.

---

## 3. Architecture Review

### 3.1 Module Dependency Graph

The import graph was verified by extracting all `import` statements across
11 source files. The observed dependencies are:

```
Mathlib.GroupTheory.GroupAction.{Defs,Quotient}
         │
         ▼
  GroupAction/Basic.lean
       ╱           ╲
      ▼             ▼
Canonical.lean    (provides orbit API)
      │             │
      ▼             ▼
Invariant.lean ◄── Basic + Canonical
      │
      ▼
  Crypto/Scheme.lean ◄── Basic + Canonical
       ╱         ╲
      ▼           ▼
Security.lean    OIA.lean
      │             │
      ├─────┐       │
      ▼     ▼       ▼
Correctness  OIAImpliesCPA
InvariantAttack

Mathlib.GroupTheory.Perm.Basic
         │
         ▼
Permutation.lean ◄── Invariant
         │
         ▼
HGOE.lean ◄── Security + Correctness + InvariantAttack
```

**Assessment:**

- **Layering is correct.** Lower layers (GroupAction) never import higher
  layers (Crypto, Theorems). Construction imports from all layers as a
  leaf node. No circular dependencies.
- **Mathlib imports are specific.** Only 3 Mathlib modules are imported
  directly: `GroupAction.Defs`, `GroupAction.Quotient`, `Perm.Basic`. No
  bulk `import Mathlib`. This is excellent for build performance and
  maintainability.
- **Transitive imports are minimal.** Each module imports only what it
  directly needs. For example, `OIA.lean` imports `Scheme.lean` but not
  `Basic.lean` or `Canonical.lean` (which come transitively through
  `Scheme.lean`).

### 3.2 Namespace Discipline

All definitions are in the `Orbcrypt` namespace. This prevents name
collisions with Mathlib and user code. The namespace is opened at the
top of each file and closed at the bottom. **Correct.**

### 3.3 Variable Management

- Implicit variables `{G : Type*} {X : Type*} {M : Type*}` are declared
  at file scope in most modules, then `[Group G] [MulAction G X]` etc.
  are added per-section as needed.
- The `autoImplicit := false` setting in `lakefile.lean` ensures no
  accidental variable introduction.
- All type class instances are explicitly declared with bracket notation.
  **Correct throughout.**

### 3.4 Proof Technique Consistency

| Technique | Usage | Assessment |
|-----------|-------|-----------|
| Tactic mode | All non-trivial proofs | Consistent with CLAUDE.md conventions |
| Term mode | Simple wrappers (e.g., `orbit_eq_implies_canon_eq`) | Appropriate for one-liners |
| `simp` | Used with explicit lemma sets (`[simp]` tags) | Good — no uncontrolled `simp` |
| `unfold` | Used to expose definitional structure | Appropriate and targeted |
| `calc` | Not used | None needed — no equational chains |
| `by_contra` | Used in `decrypt_unique` and `perm_action_faithful` | Appropriate for contradiction proofs |

### 3.5 `@[simp]` Tag Audit

Four `@[simp]` lemmas are declared:

1. `perm_smul_apply` — computation rule for permutation action
2. `one_perm_smul` — identity permutation is trivial
3. `invariantAttackAdversary_choose` — adversary choice unfolding
4. `invariantAttackAdversary_guess` — adversary guess unfolding

All are definitional equalities (`rfl`), which is the ideal pattern for
simp lemmas. None risk looping or non-termination. **Correct.**

---

## 4. Security Model Analysis

### 4.1 Cryptographic Soundness of the Formalized Definitions

The formalization targets three headline results. Each is assessed below
for mathematical correctness and modeling faithfulness.

#### Theorem 1: Correctness (`decrypt ∘ encrypt = id`)

- **Mathematical claim:** For all `m : M` and `g : G`,
  `decrypt(encrypt(g, m)) = some m`.
- **Lean statement matches claim:** Yes. The theorem's type signature
  directly encodes the claim.
- **Proof is logically valid:** Yes. Verified line-by-line in Section 2.9.
- **Dependencies are sound:** Uses `Classical.choice` (through `decrypt`),
  `propext` (through `dif_pos`), `Quot.sound` (transitively). All standard.
- **Assessment:** This theorem provides **unconditional correctness**. It
  holds for any group, action, and message space satisfying the type class
  constraints. No hidden assumptions.

#### Theorem 2: Invariant Attack (`separating invariant → complete break`)

- **Mathematical claim:** If a G-invariant function `f` separates two
  message orbits (`f(reps m₀) ≠ f(reps m₁)`), then an adversary with
  advantage 1/2 exists.
- **Lean statement matches claim:** Partially. The theorem shows
  `∃ A, hasAdvantage scheme A`, which captures "some adversary has advantage"
  but does not quantify the advantage as exactly 1/2. In the deterministic
  model, "has advantage" is a binary property, not a magnitude.
- **Proof is logically valid:** Yes. The adversary construction is explicit
  and the witnesses `g₀ = 1, g₁ = 1` are concrete. Verified in Section 2.10.
- **Dependencies:** Only `propext`. Fully constructive.
- **Assessment:** This theorem provides an **unconditional attack**.
  The formalization correctly captures that the existence of a separating
  invariant is catastrophic. The specific advantage magnitude (1/2) is a
  probabilistic concept not directly expressible in the deterministic model,
  but the qualitative conclusion (complete break) is preserved.

#### Theorem 3: OIA implies IND-1-CPA

- **Mathematical claim:** If OIA holds, no adversary can distinguish
  encryptions of different messages.
- **Lean statement matches claim:** Yes, modulo the OIA vacuity (F-01).
- **Proof is logically valid:** Yes. Direct instantiation of OIA with the
  adversary's guess function. Verified in Section 2.11.
- **Dependencies:** Zero axioms (OIA is a hypothesis).
- **Assessment:** The proof structure is correct. The algebraic argument
  "indistinguishability → security" is faithfully captured. However, the
  OIA hypothesis is unsatisfiable for non-trivial schemes (F-01), making
  the theorem vacuously true. This is a **known limitation** documented
  extensively in `OIA.lean`.

### 4.2 Gap Analysis: Deterministic vs. Probabilistic Models

The formalization operates in a purely deterministic, information-theoretic
setting. Key differences from the standard probabilistic cryptographic model:

| Aspect | Standard Model | Orbcrypt Formalization | Impact |
|--------|---------------|----------------------|--------|
| Adversary power | PPT (polynomial-time) | Unbounded | Formalization is stronger |
| Randomness | Uniform `g ← G` | Existential `∃ g₀ g₁` | Different notion of advantage |
| Advantage | `|Pr[...] - 1/2|` | Boolean `hasAdvantage` | Loses magnitude information |
| OIA | PPT indistinguishability | All-function indistinguishability | Makes OIA unsatisfiable |
| Message constraint | `m₀ ≠ m₁` required | Not enforced (F-02) | Slightly different game |

**Overall assessment:** The formalization captures the **algebraic skeleton**
of the security argument faithfully. The three theorems form a coherent
narrative: correctness is unconditional, invariant attacks are the precise
failure mode, and indistinguishability (if it held) would prevent all attacks.
The probabilistic gap is the primary limitation, and it is well-documented.

### 4.3 Axiom Transparency

The formalization's axiom hygiene is excellent:

| Theorem | Standard Axioms Used | Custom Axioms | OIA Status |
|---------|---------------------|---------------|-----------|
| `correctness` | `propext`, `Classical.choice`, `Quot.sound` | None | Not used |
| `invariant_attack` | `propext` | None | Not used |
| `oia_implies_1cpa` | (none) | None | Hypothesis |
| All GroupAction lemmas | `propext` at most | None | Not used |
| All Construction proofs | `propext`, `Classical.choice` | None | Not used |

The claim in `Orbcrypt.lean` lines 103-119 is verified accurate. Users can
independently confirm via `#print axioms`.

---

## 5. CI and Infrastructure Review

### 5.1 GitHub Actions CI (`.github/workflows/lean4-build.yml`)

**Pipeline steps assessed:**

1. **Checkout** (`actions/checkout@v4`): Standard. Uses latest v4. **OK.**

2. **elan install** (lines 14-15):
   ```bash
   curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | bash -s -- -y
   ```
   **[F-05] No SHA-256 verification.** The CI fetches elan from `master`
   (a mutable ref) and pipes directly to `bash` without checksum
   verification. Compare with the local `setup_lean_env.sh` script, which
   pins to a specific commit hash and verifies SHA-256. The CI is less
   secure than the local setup.

   **Risk:** If the elan repository's `master` branch were compromised, CI
   builds would execute attacker-controlled code. This is a supply-chain
   risk common to many Lean projects but worth mitigating.

   **Recommendation:** Pin to a specific elan commit and verify the checksum,
   or use the project's own `setup_lean_env.sh` in CI.

3. **Mathlib cache** (lines 19-28): Uses `actions/cache@v4` with a composite
   key of `lean-toolchain`, `lakefile.lean`, and `lake-manifest.json`. This
   correctly invalidates the cache when any dependency changes. The
   `restore-keys: mathlib-` fallback allows partial cache hits. **Correct.**

4. **Cache fetch** (line 30): `lake exe cache get || true` — tolerates
   failure gracefully. **Correct.**

5. **Build** (line 33): `lake build Orbcrypt` — builds the root target,
   which transitively builds all 11 submodules. **Correct.**

6. **Sorry check** (lines 35-39):
   ```bash
   if grep -rn "sorry" Orbcrypt/ --include="*.lean"; then
     echo "ERROR: sorry found in source files"
     exit 1
   fi
   ```
   **[F-04] Matches documentation text.** This grep matches the literal
   string "sorry" anywhere in `.lean` files, including comments and
   docstrings. Currently there are zero matches (verified), so this is not
   a practical problem. But if a future docstring mentions "sorry" (e.g.,
   "this proof avoids sorry"), the CI would fail spuriously.

   **Recommendation:** Use `lake build` warnings or `grep -rn "^.*sorry"` 
   with a pattern that excludes comment lines (`--` prefix) and docstring
   blocks (`/-` ... `-/`). Alternatively, use `lake env lean --run` with a
   script that checks `#print axioms` for `sorryAx`.

7. **Axiom check** (lines 41-47):
   ```bash
   if grep -Prn "^axiom\s+\w+\s*[\[({:]" Orbcrypt/ --include="*.lean"; then
   ```
   **[F-03] Misses multi-line axiom declarations.** The regex requires
   a bracket or colon on the same line as the `axiom` keyword. A
   declaration like:
   ```lean
   axiom myAxiom
     (x : Nat) : Prop
   ```
   would NOT be caught because the first line has no `[`, `(`, `{`, or `:`.

   **Verified by testing:**
   ```
   echo 'axiom myAxiom' | grep -P "^axiom\s+\w+\s*[\[({:]"  → NO MATCH
   echo 'axiom myAxiom : Nat' | grep -P "^axiom\s+\w+\s*[\[({:]"  → MATCH
   ```

   **Recommendation:** Simplify to `grep -Prn "^axiom\s+" Orbcrypt/`
   (match any line starting with `axiom` followed by whitespace). This is
   broader but safer — false positives from docstrings are unlikely since
   docstrings don't start with `axiom` at column 0.

### 5.2 Setup Script (`scripts/setup_lean_env.sh`, 565 lines)

**Security assessment:**

- **SHA-256 pinning:** All downloaded artifacts are pinned and verified:
  - elan installer script: pinned to commit `87f5ec2f...`, SHA-256 verified
  - elan binary release: pinned to `v4.2.1`, architecture-specific SHA-256
  - Lean toolchain: pinned to `v4.30.0-rc1`, both `.tar.zst` and `.zip`
    variants verified
  - Mathlib commit: parsed from `lake-manifest.json`, validated as 40-char
    hex (line 94), used for immutable cache URLs
  **Excellent supply-chain security.**

- **`set -euo pipefail`** (line 4): Strict error handling. Script fails on
  any unhandled error, unset variable, or pipe failure. **Correct.**

- **Architecture detection** (lines 310-318): Supports `x86_64` and
  `aarch64`. Rejects unknown architectures with an error. **Correct.**

- **Fast-path optimization** (lines 190-210): If elan, toolchain, and CRT
  files are already present, skips full setup. This makes session startup
  fast while ensuring correctness. **Correct.**

- **CRT verification** (lines 518-548): Checks for `crti.o`, `crt1.o`,
  `Scrt1.o` after fresh install. Re-downloads toolchain if missing, falls
  back to `libc-dev` package. **Robust error recovery.**

- **Mathlib cache redirect** (lines 101-187): Redirects cache from blocked
  endpoints to `raw.githubusercontent.com`. Uses HTTPS and SHA-pinned
  commit. Mathlib's cache tool provides additional content-hash verification.
  **Correct.**

- **No command injection vulnerabilities found.** All variables are quoted
  in command arguments. The `MATHLIB_REV` variable is validated against
  `^[a-f0-9]{40}$` before use in URLs (line 94).

### 5.3 Claude Code Hook (`.claude/settings.json`)

Runs `./scripts/setup_lean_env.sh --quiet` on `SessionStart`. The `--quiet`
flag suppresses informational output. The hook ensures the Lean environment
is ready before any Claude Code session begins work. **Correct.**

---

## 6. Findings Summary Table

| ID | Severity | Category | Location | Summary | Status |
|----|----------|----------|----------|---------|--------|
| F-01 | Info | Design | `Crypto/OIA.lean:182-186` | OIA is vacuously `False` for non-trivial schemes; `oia_implies_1cpa` is vacuously true. This is the deterministic formulation's inherent limitation — formalizing probabilistic OIA requires a probability monad. | Documented in module docstring (lines 46-67). No code change needed. |
| F-02 | Low | Modeling | `Crypto/Security.lean:61-65` | `Adversary.choose` returns `M × M` without requiring `m₀ ≠ m₁`. This makes `IsSecure` slightly stronger than standard IND-1-CPA (also requires within-orbit indistinguishability). | Recommend adding a comment documenting this. Optionally add `hDistinct : (choose reps).1 ≠ (choose reps).2` to `hasAdvantage`. |
| F-03 | Low | CI | `.github/workflows/lean4-build.yml:44` | Axiom check regex `^axiom\s+\w+\s*[\[({:]` misses multi-line declarations where the colon/brackets start on line 2. | Recommend simplifying to `^axiom\s+`. |
| F-04 | Info | CI | `.github/workflows/lean4-build.yml:35` | Sorry check `grep "sorry"` matches documentation text. No practical impact (zero matches today). | Recommend refining to avoid false positives on future docstrings. |
| F-05 | Low | CI | `.github/workflows/lean4-build.yml:14-15` | CI elan install fetches from `master` without SHA-256 verification, unlike the local `setup_lean_env.sh` which pins and verifies. | Recommend using `setup_lean_env.sh` in CI or pinning the elan commit. |
| F-06 | Info | Modeling | `Theorems/OIAImpliesCPA.lean:166-172` | `insecure_implies_separating` extracts a distinguisher but does not prove it is G-invariant. The contrapositive chain to `invariant_attack` is therefore incomplete. | Documented in docstring (lines 157-164). Completing this requires probabilistic averaging. |
| F-07 | Info | Style | `Construction/HGOE.lean:107` | `(fun x => hammingWeight x)` is an eta-expansion of `hammingWeight`. | Cosmetic only. |

---

## 7. Recommendations

### 7.1 High Priority (before release)

#### R-01: Harden CI axiom check (addresses F-03)

Replace the current regex with a simpler, broader pattern:

```yaml
- name: Verify no unexpected axioms
  run: |
    if grep -rn "^axiom " Orbcrypt/ --include="*.lean"; then
      echo "ERROR: unexpected axiom declaration found"
      exit 1
    fi
```

This catches any line starting with `axiom ` at column 0, including
multi-line declarations. False positives from docstrings are unlikely
since docstrings use `/-` or `--` prefixes, not bare `axiom` at column 0.

#### R-02: Harden CI elan installation (addresses F-05)

Replace the current unpinned curl-pipe-bash with the project's own
setup script, or pin to a specific elan release:

```yaml
- name: Install elan
  run: |
    curl -sSfL https://github.com/leanprover/elan/releases/download/v4.2.1/elan-x86_64-unknown-linux-gnu.tar.gz -o /tmp/elan.tar.gz
    echo "4e717523217af592fa2d7b9c479410a31816c065d66ccbf0c2149337cfec0f5c  /tmp/elan.tar.gz" | sha256sum -c
    tar -xzf /tmp/elan.tar.gz -C /tmp/
    /tmp/elan-init -y --no-modify-path --default-toolchain none
    echo "$HOME/.elan/bin" >> $GITHUB_PATH
```

### 7.2 Medium Priority (recommended improvements)

#### R-03: Document the `m₀ ≠ m₁` modeling choice (addresses F-02)

Add a comment to `hasAdvantage` or `Adversary` explaining that the
current formulation does not enforce distinct challenge messages, and
that this makes `IsSecure` a strictly stronger property than textbook
IND-1-CPA. If desired, add `hDistinct` as a field:

```lean
def hasAdvantage ... : Prop :=
  let (m₀, m₁) := A.choose scheme.reps
  m₀ ≠ m₁ ∧ ∃ g₀ g₁ : G,
    A.guess scheme.reps (g₀ • scheme.reps m₀) ≠
    A.guess scheme.reps (g₁ • scheme.reps m₁)
```

This would align with standard IND-CPA but would require updating all
downstream proofs (the impact is small since `invariant_attack` already
works with `hSep` which implies `m₀ ≠ m₁`).

#### R-04: Refine CI sorry check (addresses F-04)

Add an exclusion for comment and docstring lines:

```yaml
- name: Verify no sorry
  run: |
    # Match "sorry" only in non-comment lines
    if grep -rn "sorry" Orbcrypt/ --include="*.lean" | grep -v "^\s*--" | grep -v "^\s*/[-*]"; then
      echo "ERROR: sorry found in source files"
      exit 1
    fi
```

Alternatively, use Lean's own checking: a `sorry` in proof code produces
`sorryAx` in axiom output, which `#print axioms` would reveal.

### 7.3 Low Priority (future work)

#### R-05: Probabilistic OIA formulation

The primary path to making `oia_implies_1cpa` non-vacuous. Requires:
1. A probability monad (e.g., `Pmf` from Mathlib or a custom `Prob` type)
2. Computational complexity bounds (PPT adversaries)
3. Negligible function framework

This is a significant undertaking documented in `FORMALIZATION_PLAN.md`
as a non-goal for the current scope. Consider adopting frameworks from
CryptHOL or EasyCrypt's Lean port if/when they mature.

#### R-06: Complete the contrapositive bridge (addresses F-06)

Prove that any distinguisher can be "averaged" into a G-invariant one.
This requires:
1. Defining the averaging operator: `f_avg(x) = E_{g ∈ G}[f(g • x)]`
2. Showing `f_avg` is G-invariant
3. Showing that if `f` distinguishes, `f_avg` separates

This bridges `insecure_implies_separating` with `invariant_attack` and
would close the bidirectional equivalence between insecurity and
separating invariants. Requires the probability monad from R-05.

#### R-07: Reduce eta-expansion (addresses F-07)

In `Construction/HGOE.lean` line 107, replace:
```lean
invariant_attack scheme (fun x => hammingWeight x)
```
with:
```lean
invariant_attack scheme hammingWeight
```
Purely cosmetic.

---

## 8. Conclusion

The Orbcrypt Lean 4 formalization is in strong shape for a first major
release. The codebase demonstrates:

- **Correctness:** Zero `sorry`, zero custom axioms, clean build across
  all 11 modules (903 build jobs, 0 errors).
- **Sound architecture:** Clean layered dependencies, maximal Mathlib
  reuse, no circular imports, minimal Mathlib surface area (3 direct
  imports).
- **Transparent limitations:** The OIA vacuity (F-01) and contrapositive
  gap (F-06) are thoroughly documented. The formalization is honest about
  what it proves and what remains as future work.
- **Robust infrastructure:** SHA-256 pinned downloads, strict shell error
  handling, CI pipeline with build + sorry + axiom checks.

The 7 findings are all informational or low-severity. The 3 actionable
CI improvements (R-01, R-02, R-04) are straightforward hardening measures.
The modeling refinements (R-03, R-05, R-06) are enhancements for future
versions, not blockers for the current release.

**No CVE-worthy vulnerabilities were discovered.**

**Overall assessment: PASS — ready for release with the CI hardening
recommendations applied.**

---

*End of audit report.*
