<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Orbcrypt API surface

This document is the canonical reference for "what does the Orbcrypt
formalization deliver". It is **regenerable** from `lake build` +
`scripts/audit_phase_16.lean` output; treat it as a living artefact
that mirrors the source tree's current state, not as historical
record.

For the historical changelog of how the API surface evolved, see
[`docs/dev_history/WORKSTREAM_CHANGELOG.md`](dev_history/WORKSTREAM_CHANGELOG.md).
For development guidance and project conventions, see
[`CLAUDE.md`](../CLAUDE.md). For the master scheme specification, see
[`DEVELOPMENT.md`](DEVELOPMENT.md).

## Table of contents

1. **[How to read this document](#how-to-read-this-document)**
2. **[Three core theorems, by cluster](#three-core-theorems-by-cluster)**
   1. [Symmetric scheme correctness & security (PRIMARY)](#21-symmetric-scheme-correctness--security-primary)
   2. [Hardness chain (Quantitative)](#22-hardness-chain-quantitative)
   3. [Public-key extension (RESEARCH SCAFFOLDING)](#23-public-key-extension-research-scaffolding)
   4. [Structural / integrity API (Mathlib-grade)](#24-structural--integrity-api-mathlib-grade)
   5. [Distinct-challenge corollaries](#25-distinct-challenge-corollaries)
   6. [Vacuity witnesses + scaffolding (deterministic chain)](#26-vacuity-witnesses--scaffolding-deterministic-chain)
3. **[Module dependency graph](#module-dependency-graph)**
4. **[Formalization roadmap](#formalization-roadmap)**
5. **[Module inventory](#module-inventory)**
6. **[Axiom transparency report](#axiom-transparency-report)**
7. **[Headline metric anchor](#headline-metric-anchor)**

## How to read this document

Every claim here is independently verifiable by reading the source
files under `Orbcrypt/` or by re-running the audit script
(`scripts/audit_phase_16.lean`). Theorem names match the Lean source
exactly; clicking through to a referenced module file will land on
the actual `theorem` declaration.

The **Status** column on each headline-theorem row classifies the
result for **release messaging** — see [`CLAUDE.md` § "Release messaging
policy"](../CLAUDE.md#release-messaging-policy-absolute) for the absolute
rule that governs how each status may be cited externally:

- **Standalone** — unconditional / algebraic / structural result that
  holds for every scheme. Safe to cite directly.
- **Quantitative** — probabilistic-chain theorem whose ε-bounded
  `Concrete*` hypothesis is genuinely ε-smooth. Cite with an explicit
  ε and an explicit surrogate / encoder / keyDerive profile.
- **Conditional** — theorem whose hypothesis fails on production
  HGOE. Cite only with the hypothesis disclosed.
- **Scaffolding** — deterministic-chain theorem whose OIA-variant
  hypothesis is `False` on every non-trivial scheme; the conclusion
  holds vacuously. Cite only to explain type-theoretic structure.
- **Structural** — Mathlib-style API lemma supporting downstream
  proofs; not a security claim but unconditionally true.

## Three core theorems, by cluster

The 32 entries below partition into six clusters by cryptographic
role. Row numbers match the canonical numbering used by other
documents (`docs/VERIFICATION_REPORT.md`, the workstream changelog,
the audit plans). Numbering is preserved across the clusters even
when adjacent rows live in different clusters.

### 2.1 Symmetric scheme correctness & security (PRIMARY)

> **These are the production-grade results.** Symmetric-key
> correctness, IND-1-CPA security (probabilistic), AEAD correctness,
> INT-CTXT integrity, key-management correctness, and the fast-
> decryption pipeline correctness. External citations should land
> here unless the citation explicitly concerns the public-key
> extension or the hardness-chain hypothesis.

| # | Name | Statement | File | Status | Significance |
|---|------|-----------|------|--------|--------------|
| 1 | **Correctness** | `decrypt(encrypt(g, m)) = some m` for all messages m and group elements g | `Theorems/Correctness.lean` | Standalone | The scheme faithfully recovers encrypted messages |
| 2 | **Invariant Attack** | If a G-invariant function separates two message orbits, there exists an adversary `A` with `hasAdvantage scheme A` (i.e. a specific `(g₀, g₁)` pair on which the adversary's two guesses disagree) | `Theorems/InvariantAttack.lean` | Standalone | Machine-checked proof of the vulnerability from `docs/COUNTEREXAMPLE.md`. The theorem's **formal conclusion** is `∃ A : Adversary X M, hasAdvantage scheme A` — existence of one distinguishing adversary — **not** a quantitative "advantage = 1/2" claim in either the two-distribution or centred conventions (see `Probability/Advantage.lean` and the `invariant_attack` docstring for the three-convention catalogue: under a separating G-invariant, deterministic advantage = 1, two-distribution advantage = 1, centred advantage = 1/2). Informal shorthand: "complete break under a separating G-invariant". The quantitative probabilistic strengthening — IND-1-CPA advantage *exactly* `1` for the invariant-attack adversary — is delivered by `indCPAAdvantage_invariantAttackAdversary_eq_one` (Workstream R-01) |
| 4 | **KEM Correctness** | `decaps(encaps(g).1) = encaps(g).2` for all group elements g | `KEM/Correctness.lean` | Standalone | The KEM correctly recovers the shared secret (proof by `rfl`) |
| 6 | **Probabilistic Security** | ConcreteOIA(ε) implies IND-1-CPA advantage ≤ ε | `Crypto/CompSecurity.lean` | Quantitative | Non-vacuous security: ConcreteOIA is satisfiable (unlike deterministic OIA) |
| 7 | **Asymptotic Security** | CompOIA implies negligible IND-1-CPA advantage | `Crypto/CompSecurity.lean` | Quantitative | Standard asymptotic formulation with negligible functions |
| 9 | **Seed-Key Correctness** | `decaps(encaps(sampleGroup(seed, n)).1) = encaps(sampleGroup(seed, n)).2` | `KeyMgmt/SeedKey.lean` | Standalone | Seed-based key expansion preserves KEM correctness |
| 10 | **Nonce Correctness** | `nonceDecaps(nonceEncaps(sk, kem, nonce).1) = nonceEncaps(sk, kem, nonce).2` | `KeyMgmt/Nonce.lean` | Standalone | Nonce-based encryption preserves KEM correctness |
| 11 | **Nonce Orbit Leakage** | Cross-KEM nonce reuse leaks orbit membership | `KeyMgmt/Nonce.lean` | Standalone | Formal warning: nonce misuse breaks orbit indistinguishability |
| 12 | **AEAD Correctness** | `authDecaps(authEncaps(g)) = some k` for honest pairs | `AEAD/AEAD.lean` | Standalone | Authenticated KEM correctly recovers keys |
| 13 | **Hybrid Correctness** | `hybridDecrypt(hybridEncrypt(m)) = some m` | `AEAD/Modes.lean` | Standalone | KEM+DEM hybrid encryption preserves messages |
| 19 | **INT-CTXT for AuthOrbitKEM** | `authEncrypt_is_int_ctxt : INT_CTXT akem` | `AEAD/AEAD.lean` | Standalone | Ciphertext integrity: no adversary can forge a `(c, t)` pair that decapsulates. Post-Workstream-B, the `INT_CTXT` game carries a per-challenge `hOrbit : c ∈ orbit G basePoint` binder rejecting out-of-orbit ciphertexts as ill-formed; the theorem discharges **unconditionally** on every `AuthOrbitKEM`. Consumers wanting INT-CTXT-on-arbitrary-ciphertexts pair this with an explicit orbit-check at decapsulation (`decapsSafe` helper, planned). Non-vacuous sibling: `keyDerive_canon_eq_of_mem_orbit` (orbit-restricted key uniqueness) |
| 20 | **Carter–Wegman INT-CTXT witness** | `carterWegmanMAC_int_ctxt : INT_CTXT (carterWegman_authKEM …)` | `AEAD/CarterWegmanMAC.lean` | Conditional | Concrete instance showing `verify_inj` is satisfiable. **Requires `X = ZMod p × ZMod p`** — the MAC is typed over `(ZMod p × ZMod p) → ZMod p → ZMod p` and is **incompatible with HGOE's `Bitstring n`** without a `Bitstring n → ZMod p` adapter (research tracked as R-13). The companion theorem `carterWegmanHash_isUniversal` is the standalone `(1/p)`-universal hash proof — cite that when a standalone universal-hash statement is wanted |
| 24 | **Two-Phase Correctness** | `canonical_agreement_under_two_phase_decomposition : can_full.canon (g • x) = can_residual.canon (can_cyclic.canon (g • x))` (given `TwoPhaseDecomposition`) | `Optimization/TwoPhaseDecrypt.lean` | Conditional | The fast (cyclic ∘ residual) canonical form agrees with the full canonical form on every ciphertext `g • x` **when** `TwoPhaseDecomposition` holds. **Empirically False on the default GAP fallback group** (lex-min and the residual transversal action don't commute). Non-vacuous sibling: `fast_kem_round_trip` (#26) |
| 25 | **Two-Phase KEM Correctness** | `kem_round_trip_under_two_phase_decomposition : kem.keyDerive (can_residual.canon (can_cyclic.canon (encaps kem g).1)) = (encaps kem g).2` | `Optimization/TwoPhaseDecrypt.lean` | Conditional | Decapsulation via the fast path recovers the encapsulated key WHEN `TwoPhaseDecomposition` holds. **Same hypothesis as #24**: the GAP implementation does NOT discharge it. Non-vacuous sibling: `fast_kem_round_trip` (#26) |
| 26 | **Fast-KEM Round-Trip (orbit-constancy)** | `fast_kem_round_trip : keyDerive (fastCanon (g • basePoint)) = keyDerive (fastCanon basePoint)` (given `IsOrbitConstant G fastCanon`) | `Optimization/TwoPhaseDecrypt.lean` | Standalone | The actual correctness theorem for the GAP `(FastEncaps, FastDecaps)` pair. Orbit-constancy of the fast canonical form is sufficient for round-trip correctness, and orbit-constancy IS satisfied by `FastCanonicalImage` whenever the cyclic subgroup is normal in G (Phase 15.3 post-landing audit) |

### 2.2 Hardness chain (Quantitative)

> **Non-vacuous probabilistic security reductions, parametric in
> caller-supplied surrogate + encoders.** ε-bounds rely on caller-
> supplied research-scope discharges. ε = 1 is inhabited
> unconditionally via the `tight_one_exists` family (PUnit
> surrogate) or `tight_one_exists_at_s2Surrogate` (S_2 surrogate, W4
> of structural review 2026-05-06); ε < 1 requires concrete encoder
> witnesses that remain research-scope (Petrank–Roth reverse
> direction, Grochow–Qiao rigidity).

| # | Name | Statement | File | Status | Significance |
|---|------|-----------|------|--------|--------------|
| 27 | **Surrogate-Bound Hardness Chain** | `ConcreteHardnessChain.concreteOIA_from_chain hc : ConcreteOIA scheme ε` for `hc : ConcreteHardnessChain scheme F S ε` with explicit `S : SurrogateTensor F` and encoder fields `encTC, encCG`; `tight_one_exists` and `tight_one_exists_at_s2Surrogate` witness inhabitation at ε = 1 | `Hardness/Reductions.lean` | Quantitative | The chain is honestly ε-parametric in both the surrogate choice and the encoder witnesses. The end-to-end bound `concrete_hardness_chain_implies_1cpa_advantage_bound : ConcreteHardnessChain … → IND-1-CPA advantage ≤ ε` is the **primary public-release citation** for scheme-level quantitative security |
| 28 | **Per-Encoding Reduction Props (Fix C)** | `ConcreteTensorOIAImpliesConcreteCEOIA_viaEncoding S enc εT εC`, `ConcreteCEOIAImpliesConcreteGIOIA_viaEncoding enc εC εG`, `ConcreteGIOIAImpliesConcreteOIA_viaEncoding scheme encTC encCG εG ε` | `Hardness/Reductions.lean` | Quantitative | Each reduction Prop names an explicit encoder function and asserts hardness transfer *through* that encoder. Satisfiable at ε = 1 via the `*_one_one` witnesses; non-trivial ε < 1 requires concrete encoder witnesses (CFI, Grochow–Qiao — research-scope) |
| 29 | **KEM-Layer ε-Smooth Hardness Chain** | `concreteKEMHardnessChain_implies_kemUniform : ConcreteKEMHardnessChain scheme F S m₀ keyDerive ε → ConcreteKEMOIA_uniform (scheme.toKEM m₀ keyDerive) ε`; `concrete_kem_hardness_chain_implies_kem_advantage_bound : ConcreteKEMHardnessChain … → kemAdvantage_uniform … ≤ ε` (end-to-end adversary bound) | `KEM/CompSecurity.lean` | Quantitative | The KEM-layer parallel of #27. Inhabited at ε = 1 via `ConcreteKEMHardnessChain.tight_one_exists`. The `kem_advantage_bound` form is the **primary public-release citation** for KEM-layer quantitative security |

### 2.3 Public-key extension (RESEARCH SCAFFOLDING)

> **These four results provide algebraic scaffolding for three
> candidate public-key paths** (oblivious sampling, KEM agreement,
> CSIDH-style commutative action). **None has a concrete
> cryptographic instantiation in v1.0.** Citations should explicitly
> demarcate this status. See [`docs/PUBLIC_KEY_ANALYSIS.md`](PUBLIC_KEY_ANALYSIS.md)
> for the feasibility analysis (which paths are viable, bounded, or
> open).
>
> The symmetric scheme is the production-grade content; these rows
> are the algebraic scaffolding for future research workstreams.

| # | Name | Statement | File | Status | Significance |
|---|------|-----------|------|--------|--------------|
| 15 | **Oblivious Sample Correctness** | `obliviousSample ors combine hClosed i j ∈ orbit G ors.basePoint` | `PublicKey/ObliviousSampling.lean` | Standalone | Oblivious sampling preserves orbit membership (Phase 13.2). Algebraic scaffolding only — concrete cryptographic discharge of the `combine` problem remains open per `PUBLIC_KEY_ANALYSIS.md` |
| 16 | **KEM Agreement Correctness** | Alice's post-decap view equals Bob's post-decap view (`= sessionKey a b`) | `PublicKey/KEMAgreement.lean` | Standalone | Two-party KEM agreement recovers the same session key (Phase 13.4). The agreement's two-party setup is symmetric, not a public-key system — the formal framework is ready but the public-key instantiation is open |
| 17 | **CSIDH Correctness** | `a • (b • x₀) = b • (a • x₀)` under `CommGroupAction` | `PublicKey/CommutativeAction.lean` | Standalone | Commutative action supports Diffie–Hellman-style exchange (Phase 13.5). Algebraic scaffolding — no concrete `CommGroupAction` cryptographic instantiation in-tree |
| 18 | **Commutative PKE Correctness** | `decrypt(encrypt(r).1) = encrypt(r).2` | `PublicKey/CommutativeAction.lean` | Standalone | CSIDH-style public-key orbit encryption is correct (Phase 13.6). Standalone correctness; non-vacuous content depends on a concrete `CommGroupAction` instance, which is research-scope |

### 2.4 Structural / integrity API (Mathlib-grade)

> **Mathlib-style API for downstream signature-scheme work.** These
> are not security claims — they are equivalence-relation,
> subgroup, and coset identities that promote `ArePermEquivalent`
> and `PAut` to first-class Mathlib citizens. The LESS signature
> scheme's effective-search-space reduction depends on row #23.

| # | Name | Statement | File | Status | Significance |
|---|------|-----------|------|--------|--------------|
| 21 | **Code Equivalence is an `Equivalence`** | `arePermEquivalent_setoid : Setoid {C : Finset (Fin n → F) // C.card = k}` (built from `arePermEquivalent_refl` / `_symm` / `_trans`) | `Hardness/CodeEquivalence.lean` | Structural | Permutation code equivalence is now a Mathlib-grade equivalence relation; `_symm` carries `C₁.card = C₂.card`, `_trans` is unconditional |
| 22 | **PAut is a `Subgroup`** | `PAutSubgroup C : Subgroup (Equiv.Perm (Fin n))` with `PAut_eq_PAutSubgroup_carrier C : PAut C = (PAutSubgroup C : Set _)` | `Hardness/CodeEquivalence.lean` | Structural | Permutation Automorphism group has full Mathlib `Subgroup` API (cosets, Lagrange, quotient); the Set-valued `PAut` and Subgroup-packaged `PAutSubgroup` agree definitionally |
| 23 | **CE coset set identity** | `paut_equivalence_set_eq_coset : {ρ \| ρ : C₁ → C₂} = σ · PAut C₁` (given a witness σ and `C₁.card = C₂.card`) | `Hardness/CodeEquivalence.lean` | Structural | The set of all CE-witnessing permutations is *exactly* a left coset of PAut; this is the algebraic statement underlying the LESS signature scheme's effective-search-space reduction |

### 2.5 Distinct-challenge corollaries

> **Classical IND-1-CPA literature-game-shape corollaries.** Cite
> these when matching the standard literature game-form. Composes
> the deterministic-chain Scaffolding theorems (rows #3, #14) with
> `isSecure_implies_isSecureDistinct` (Workstream B1) for the
> `_distinct` shape, and the probabilistic chain (#27) with
> `indCPAAdvantage_collision_zero` for the probabilistic distinct-
> challenge bound.

| # | Name | Statement | File | Status | Significance |
|---|------|-----------|------|--------|--------------|
| 30 | **Distinct-challenge IND-1-CPA (classical game)** | `oia_implies_1cpa_distinct : OIA scheme → IsSecureDistinct scheme`; `hardness_chain_implies_security_distinct : HardnessChain scheme → IsSecureDistinct scheme`; `concrete_hardness_chain_implies_1cpa_advantage_bound_distinct : ConcreteHardnessChain … → _ ≠ _ → indCPAAdvantage ≤ ε`; `indCPAAdvantage_collision_zero : (A.choose).1 = (A.choose).2 → indCPAAdvantage = 0` | `Theorems/OIAImpliesCPA.lean`, `Hardness/Reductions.lean`, `Crypto/CompSecurity.lean` | Scaffolding (K1, K3) + Quantitative (K4) + Standalone (collision lemma) | `IsSecure` (uniform game) is strictly stronger than the classical IND-1-CPA game `IsSecureDistinct` (rejects `(m, m)` challenges). Workstream K threads this through the deterministic chain and the probabilistic chain. Release-facing citations should prefer the `_distinct` forms because they match the literature's IND-1-CPA game shape |

### 2.6 Vacuity witnesses + scaffolding (deterministic chain)

> **Deterministic-chain theorems whose hypothesis is `False` on every
> non-trivial scheme** — the conclusions hold vacuously on production
> instances. Cite **only** to explain the type-theoretic structure
> of the OIA-style argument, never as standalone security claims.
>
> The vacuity is itself machine-checked by rows #31 / #32 (the
> deterministic-OIA / deterministic-KEMOIA refutations on every
> scheme that admits two distinct-rep messages or a non-trivial
> base-point orbit). The substantive security content is the
> probabilistic chain in §2.2.
>
> **NOTE (W6 of structural review 2026-05-06):** All rows in this
> cluster are scheduled for deletion in v0.4.0. The probabilistic
> chain (§2.2) is the sole security chain post-deletion.

| # | Name | Statement | File | Status | Significance |
|---|------|-----------|------|--------|--------------|
| 3 | **Conditional Security** | OIA implies IND-1-CPA | `Theorems/OIAImpliesCPA.lean` | Scaffolding | Deterministic OIA is `False` on every non-trivial scheme (witness: row #31). Vacuously true on production instances |
| 5 | **KEM Security** | KEMOIA implies KEM security | `KEM/Security.lean` | Scaffolding | Deterministic KEMOIA is vacuous on every non-trivial KEM (witness: row #32). Cite the probabilistic counterpart (`concrete_kemoia_*_implies_secure` family) |
| 8 | **Bridge** | Deterministic OIA implies ConcreteOIA(0) | `Crypto/CompOIA.lean` | Scaffolding | Backward compatibility: probabilistic framework generalizes deterministic. Vacuous in practice; exists to anchor the definitional link between the two chains |
| 14 | **Hardness Chain (deterministic)** | HardnessChain(scheme) → IsSecure(scheme) | `Hardness/Reductions.lean` | Scaffolding | Deterministic `HardnessChain` is composed from deterministic `TensorOIA`/`CEOIA`/`GIOIA` and is vacuous on production instances; the non-vacuous counterpart is #27 |
| 31 | **Deterministic OIA Vacuity Witness** | `det_oia_false_of_distinct_reps : scheme.reps m₀ ≠ scheme.reps m₁ → ¬ OIA scheme` | `Crypto/OIA.lean` | Standalone | Machine-checks that the deterministic `OIA` predicate is `False` on every scheme that admits two messages with distinct representatives. The distinguisher is the Boolean membership test `fun x => decide (x = reps m₀)` evaluated at identity group elements |
| 32 | **Deterministic KEMOIA Vacuity Witness** | `det_kemoia_false_of_nontrivial_orbit : g₀ • kem.basePoint ≠ g₁ • kem.basePoint → ¬ KEMOIA kem` | `KEM/Security.lean` | Standalone | KEM-layer parallel of #31. `KEMOIA` collapses whenever two group elements produce distinct ciphertexts, i.e. whenever the base-point orbit is non-trivial (production HGOE has `\|orbit\| ≫ 2`) |

## Module dependency graph

```
              GroupAction.Basic
             /       |        \
            /        |         \
 GroupAction.   GroupAction.   (orbit lemmas
  Canonical      Invariant     feed both)
     |       \        |         /
     |        \       |        /
     v
 GroupAction.CanonicalLexMin (Workstream F: ofLexMin constructor
   consumes Canonical + Finset.min' + Fintype orbit)
            \       |        /
             Crypto.Scheme ─────────── KEM.Syntax
            /              \               |
           /                \         KEM.Encapsulate
  Crypto.Security        Crypto.OIA    /          \
     |        \            /      KEM.Correctness  KEM.Security
     |         \          /
     |    Theorems.OIAImpliesCPA
     |
  Theorems.Correctness
  Theorems.InvariantAttack
              |
              v
  Construction.Permutation
              |
              v
  Construction.HGOE ──── Construction.HGOEKEM

  Mathlib.Probability.PMF ──── Mathlib.Distributions.Uniform
              |
              v
  Probability.Monad ─────── Probability.Negligible
              |                       |
              v                       v
  Probability.Advantage ◄────────────┘
              |
              v
  Crypto.CompOIA ◄── Crypto.OIA
              |
              v
  Crypto.CompSecurity ◄── Crypto.Security

  KEM.Encapsulate + Construction.Permutation
              |
              v
  KeyMgmt.SeedKey ──── (SeedKey, HGOEKeyExpansion)
              |
              v
  KeyMgmt.Nonce ────── (nonceEncaps, nonce-misuse properties)

  AEAD.MAC ◄── Mathlib.Tactic
              |
              v
  AEAD.AEAD ◄── AEAD.MAC, KEM.Syntax, KEM.Encapsulate, KEM.Correctness
  (AuthOrbitKEM, authEncaps, authDecaps, aead_correctness, INT_CTXT)

  AEAD.Modes ◄── KEM.Syntax, KEM.Encapsulate
  (DEM, hybridEncrypt, hybridDecrypt, hybrid_correctness)

  Mathlib.GroupTheory.Perm.Basic ──── Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup.Defs
              |                                       |
              v                                       v
  Hardness.CodeEquivalence            Hardness.TensorAction
  (ArePermEquivalent, PAut,           (Tensor3, tensorAction GL³,
   CEOIA, GIReducesToCE)               AreTensorIsomorphic, GIReducesToTI,
                                       SurrogateTensor, punitSurrogate,
                                       s2Surrogate — Workstream G / Fix B
                                       + W4 of structural review 2026-05-06)
              \                                      /
               \               Hardness.Encoding    /
                \              (OrbitPreservingEncoding,
                 \              identityEncoding — reference target)
                  v                                v
              Hardness.Reductions ◄── Crypto.OIA, Theorems.OIAImpliesCPA
              (TensorOIA, GIOIA, HardnessChain,
               hardness_chain_implies_security,
               ConcreteHardnessChain (surrogate + encoder fields),
               *_viaEncoding per-encoding Props — Workstream G / Fix C,
               tight_one_exists_at_s2Surrogate — W4)

  KEM.{Syntax, Encapsulate, Correctness} + GroupAction.{Basic, Canonical}
              |
              v
  PublicKey.ObliviousSampling ◄── KEM.Syntax, GroupAction.Basic
  (OrbitalRandomizers, obliviousSample, oblivious_sample_in_orbit,
   refreshRandomizers, refresh_depends_only_on_epoch_range)

  PublicKey.KEMAgreement ◄── KEM.Encapsulate, KEM.Correctness
  (OrbitKeyAgreement, sessionKey, kem_agreement_correctness,
   SessionKeyExpansionIdentity)

  PublicKey.CommutativeAction ◄── GroupAction.Basic, GroupAction.Canonical
  (CommGroupAction class, csidh_exchange, csidh_correctness,
   CommOrbitPKE, comm_pke_correctness)

  GroupAction.Canonical + Construction.Permutation
              |
              v
  Optimization.QCCanonical ◄── GroupAction.Canonical, Construction.Permutation
  (QCCyclicCanonical abbrev for CanonicalForm under cyclic subgroup,
   qc_invariant_under_cyclic, qc_canon_idem)

  Optimization.TwoPhaseDecrypt ◄── Optimization.QCCanonical, KEM.Correctness
  (TwoPhaseDecomposition predicate,
   canonical_agreement_under_two_phase_decomposition,
   full_canon_invariant, two_phase_invariant_under_G,
   two_phase_kem_decaps,
   kem_round_trip_under_two_phase_decomposition,
   IsOrbitConstant, orbit_constant_encaps_eq_basePoint)
```

For the full Hardness/GrochowQiao subtree dependency layout (Phases 1, 2, 3 partial discharge + Manin tensor-stabilizer + Path B chain), see the head of `Orbcrypt/Hardness/GrochowQiao.lean` and `docs/planning/R_TI_RESEARCH_SCOPE_DISCHARGE_PLAN.md`.

## Formalization roadmap

The Lean 4 formalization proceeds in nine completed phases plus
planned extensions. Each phase document is in `docs/dev_history/`
or `docs/dev_history/formalization/phases/`.

| Phase | Title | Weeks | Units | Effort | Status |
|-------|-------|-------|-------|--------|--------|
| 1 | Project Scaffolding | 1 | 4 | 4.5h | Complete |
| 2 | Group Action Foundations | 2-4 | 11 | 28h | Complete |
| 3 | Cryptographic Definitions | 5-6 | 8 | 18h | Complete |
| 4 | Core Theorems | 7-10 | 16 | 33h | Complete |
| 5 | Concrete Construction | 11-14 | 12 | 26h | Complete |
| 6 | Polish & Documentation | 15-16 | 13 | 22.5h | Complete |
| 7 | KEM Reformulation | 17-19 | 8 | ~24h | Complete |
| 8 | Probabilistic Foundations | 18-22 | 10 | ~40h | Complete |
| 9 | Key Compression & Nonce-Based Enc | 20-22 | 7 | ~18h | Complete |
| 10 | Authenticated Encryption & Modes | 22-24 | 6 | ~16h | Complete |
| 11 | Reference Implementation (GAP) | 24-26 | 9 | ~36h | Complete |
| 12 | Hardness Alignment (LESS/MEDS/TI) | 26-28 | 8 | ~32h | Complete |
| 13 | Public-Key Extension | 26-30 | 7 | ~28h | Complete |
| 14 | Parameter Selection & Benchmarks | 28-31 | 6 | ~20h | Complete |
| 15 | Decryption Optimisation (Lean) | 30+ | 7 | ~20h | Complete (formalisation; C/C++ Phase 15 itself is research-scope) |
| 16 | Formal Verification of New Components | 30-36 | 10 | ~36h | Complete |
| | **Total (1–16)** | **37** | **142** | **~402h** | |

**Critical path:** Chain A (Correctness) was the longest sequential
path at ~32 hours of focused work, all complete.

Read the individual phase documents for detailed implementation
guidance, work unit breakdowns, risk analysis, and verification
criteria before starting any phase. Phase docs are now historical
record; updates are rare.

## Module inventory

The current `Orbcrypt/` source tree is regenerable via
`find Orbcrypt -name '*.lean' | sort`. For the canonical
file-by-file description, see [`CLAUDE.md` § "Source layout"](../CLAUDE.md#source-layout).

The post-W4 (structural review 2026-05-06) module count is
**81** modules (`find Orbcrypt -name '*.lean' | wc -l`); see
§7 (Headline metric anchor) for the live values.

## Axiom transparency report

Every theorem in `Orbcrypt/` depends only on the **standard Lean
trio**:
- `propext` (propositional extensionality)
- `Classical.choice` (the axiom of choice)
- `Quot.sound` (quotient soundness)

There are **zero custom axioms** and **zero `sorry`** in the
source tree. `OIA`, `KEMOIA`, `ConcreteOIA`, `CompOIA`,
`HardnessChain`, etc. are `Prop`-valued *definitions* (hypotheses
that consumers thread explicitly), **not** Lean `axiom`
declarations.

The Phase-16 audit script (`scripts/audit_phase_16.lean`) runs
`#print axioms` on every public declaration plus non-vacuity
witnesses; CI rejects any deviation from the standard trio.

For the prose verification report (axiom audit + sorry audit +
documentation parity audit), see
[`docs/VERIFICATION_REPORT.md`](VERIFICATION_REPORT.md).

For the cookbook of `#print axioms` invocations on every
headline declaration, see the corresponding section in
[`Orbcrypt.lean`](../Orbcrypt.lean)'s module-header docstring.

## Headline metric anchor

Snapshot of post-W4 (structural review 2026-05-06) state, refreshed
by W7 (Final consolidation). Live values are recomputable via the
recipes in the rightmost column.

| Metric | Value | Recipe |
|--------|-------|--------|
| Lean modules under `Orbcrypt/` | 81 | `find Orbcrypt -name '*.lean' \| wc -l` |
| Public declarations (decl-prefix lines) | ≈ 1,083 | `find Orbcrypt -name '*.lean' -exec grep -cE '^(theorem\|def\|structure\|class\|instance\|abbrev\|lemma)\b' {} \; \| awk '{s+=$1} END {print s}'` |
| Audit-script `#print axioms` entries | 1,163 | `grep -c '^#print axioms' scripts/audit_phase_16.lean` |
| Lake build jobs | 3,424 | `lake build Orbcrypt 2>&1 \| tail -1` |
| Sorry / custom-axiom count | 0 / 0 | `grep -rn '\bsorry\b' Orbcrypt/` + `grep -rEn '^axiom\s+\w+\s*[\[({:]' Orbcrypt/` |
| `lakefile.lean` version | `0.3.7` | `grep '^  version' lakefile.lean` |
| Last verified | 2026-05-06 | (W4 of structural review 2026-05-06; this anchor is refreshed by W7 Final consolidation post-W6 deletion) |

**Expected post-W6 deletion (deterministic-OIA chain removal):**
module count `81 → 79`, audit-script `#print axioms` count drops
by ≈ 17, public-declaration count drops by ≈ 17, version
`0.3.7 → 0.4.0` (minor bump for major API removal).
