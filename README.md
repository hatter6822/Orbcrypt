<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Orbcrypt

**Symmetry-Keyed Encryption with Formal Verification in Lean 4**

Orbcrypt is a research-stage symmetric-key encryption scheme whose security
arises from hiding the *equivalence relation* (orbit structure) that makes
data meaningful — not from hiding the data itself. A message is the
identity of an orbit under a secret permutation group `G ≤ S_n`; a
ciphertext is a uniformly random element of that orbit. The hardness
assumption (OIA) reduces to **Graph Isomorphism on Cai–Furer–Immerman
graphs** and to **Permutation Code Equivalence**, both believed
post-quantum hard.

---

## What makes Orbcrypt novel

| Property | Why it matters |
|----------|----------------|
| **Symmetry-keyed structure** | The key *is* the equivalence relation. Without `G`, ciphertexts are computationally indistinguishable; with `G`, recovery is one canonical-form lookup. |
| **Batch-openable commitments** | A single `G` reveal opens *every* commitment ever made under it, atomically. No per-commitment opening data. |
| **Bundle-mediated rotation** | Non-`G`-holders rotate ciphertexts only inside a provisioned bundle (`OrbitalRandomizers`); free public re-randomization is provably blocked (`CombineImpossibility`). |
| **Canonical-form-as-query** | Functional queries (membership, equality, clustering) factor through `canon`, exposing exactly orbit structure and nothing more. |
| **Post-quantum hardness chain** | TI-hardness → CE-hardness → GI-hardness → IND-1-CPA, machine-checked end-to-end (`hardness_chain_implies_security`). |
| **Compact ciphertexts** | At λ = 128 balanced: 32 B keys, 43 B ciphertexts — competitive with AES-GCM, far smaller than Kyber's 2.4 kB / 1.1 kB. |

The cryptographic primitive is small, but three of its operations
(`canon`, bundle-mediated `OrbitalRandomizers`, `commute`-style
`CommGroupAction`) enable applications that are awkward with AEAD or
lattice KEMs — see [`docs/USE_CASES.md`](docs/USE_CASES.md) and
[`docs/MORE_USE_CASES.md`](docs/MORE_USE_CASES.md).

---

## Status

**Phases 1–14 + Phase 16 complete.** Every public declaration is
machine-checked with **zero `sorry`**, **zero custom axioms**, **zero
build warnings**.

| Metric | Value |
|--------|-------|
| Lean source modules | 76 (+ root import file) |
| Public declarations | 358+, all with docstrings |
| Phase-16 audit script | 382+ `#print axioms` checks; standard Lean trio only (`propext`, `Classical.choice`, `Quot.sound`) |
| Build | `lake build` runs ~3,400 jobs successfully |
| Toolchain | Lean 4 v4.30.0-rc1 + Mathlib pinned at commit `fa6418a8` |
| CI | GitHub Actions on every push: build + sorry scan + axiom-decl scan + Phase-16 regression sentinel |
| Package version | `0.2.0` |

The Orbit Indistinguishability Assumption (OIA) is a `Prop`-valued
*hypothesis*, not a Lean `axiom` — verify with
`#print axioms Orbcrypt.<theorem_name>`.

---

## Headline theorems

| Theorem | Statement | Status |
|---------|-----------|--------|
| `correctness` | `decrypt(encrypt(g, m)) = some m` | Standalone |
| `invariant_attack` | A separating G-invariant yields `∃ A, hasAdvantage scheme A` | Standalone |
| `kem_correctness` | `decaps(encaps(g).1) = encaps(g).2` | Standalone |
| `concrete_oia_implies_1cpa` | `ConcreteOIA(ε) → IND-1-CPA advantage ≤ ε` | Quantitative |
| `concrete_hardness_chain_implies_1cpa_advantage_bound` | TI-hardness → IND-1-CPA bound (with explicit surrogate + encoders) | Quantitative |
| `concrete_kem_hardness_chain_implies_kem_advantage_bound` | KEM-layer ε-smooth hardness chain | Quantitative |
| `aead_correctness`, `hybrid_correctness` | AEAD round-trip + KEM+DEM hybrid correctness | Standalone |
| `authEncrypt_is_int_ctxt` | INT-CTXT for `AuthOrbitKEM` (unconditional post-Workstream-B) | Standalone |
| `csidh_correctness`, `comm_pke_correctness` | CSIDH-style commutative action + PKE | Standalone |

The full release-messaging classification (Standalone / Quantitative /
Conditional / Scaffolding) is in
[`docs/VERIFICATION_REPORT.md`](docs/VERIFICATION_REPORT.md) and the
`CLAUDE.md` "Three core theorems" table.

---

## Performance (HGOE GAP reference, λ = 128)

| Metric | Orbcrypt (HGOE) | AES-256-GCM | Kyber-768 |
|--------|-----------------|-------------|-----------|
| Public key / KEM-key size | 32 B | 32 B | **2,400 B** |
| Ciphertext (KEM only) | **43 B** | n + 28 B | 1,088 B |
| Encrypt (μs) | 314,000 | 0.05 | 30 |
| Decrypt (μs) | 348,000 | 0.05 | 25 |
| Post-quantum secure | conjectured (GI/CE/TI) | no | yes (MLWE) |

**Headline take-away.** Orbcrypt wins on key/ciphertext size by 1–2
orders of magnitude over lattice/code-based PQ KEMs, and is competitive
with AES-GCM. It loses by 4–5 orders of magnitude on encrypt/decrypt
time at the current GAP reference parameters — Phase 15 (decryption
optimisation in C/C++) is the next major workstream targeting this gap.

Three parameter tiers across λ ∈ {80, 128, 192, 256} are documented in
[`docs/PARAMETERS.md`](docs/PARAMETERS.md). Raw benchmark CSVs live
under [`docs/benchmarks/`](docs/benchmarks/).

---

## Project layout

```
Orbcrypt/
├── Orbcrypt.lean                 Root import file (axiom-transparency report)
├── Orbcrypt/                     Lean 4 source tree (76 modules)
│   ├── GroupAction/              Orbits, stabilizers, canonical forms (incl. `ofLexMin`)
│   ├── Crypto/                   AOE scheme, IND-CPA game, OIA, ConcreteOIA
│   ├── Theorems/                 Correctness, invariant attack, OIA → IND-1-CPA
│   ├── KEM/                      KEM reformulation + probabilistic security
│   ├── Probability/              PMF wrappers, negligible functions, hybrid arg
│   ├── KeyMgmt/                  Seed-key compression, nonce-based encryption
│   ├── Construction/             S_n on bitstrings, HGOE instance, HGOE-KEM
│   ├── AEAD/                     MAC, Encrypt-then-MAC AEAD, KEM+DEM, Carter–Wegman
│   ├── Hardness/                 CE / TI problems, GI reductions, hardness chain
│   │   ├── PetrankRoth/          Forward direction of GI ≤ CE (Workstream R-CE)
│   │   └── GrochowQiao/          Forward direction of GI ≤ TI + Manin theorem
│   ├── PublicKey/                Oblivious sampling, KEM agreement, CSIDH-style
│   └── Optimization/             Two-phase decryption + orbit-constancy
├── implementation/gap/           GAP reference: keygen, KEM, params, tests, sweep
├── docs/
│   ├── HARDNESS_ANALYSIS.md      LESS / MEDS / TI alignment
│   ├── PUBLIC_KEY_ANALYSIS.md    Public-key feasibility (Phase 13)
│   ├── PARAMETERS.md             Three-tier parameter recommendations (Phase 14)
│   ├── VERIFICATION_REPORT.md    End-to-end verification report (Phase 16)
│   ├── USE_CASES.md              Application catalogue (cryptocurrency, DAOs, DEXes, social)
│   ├── MORE_USE_CASES.md         Anonymous dev-platform architecture
│   ├── benchmarks/               Phase-14 sweep CSVs + cross-scheme comparison
│   ├── audits/                   Per-cycle Lean module audit reports
│   ├── planning/                 Workstream + phase planning documents
│   └── research/                 Mathematical-research reading notes
├── formalization/                Master Lean 4 roadmap + per-phase plans
├── scripts/                      Setup + audit scripts (incl. `audit_phase_16.lean`)
├── lakefile.lean                 Lake build config (Mathlib pin, linter pins)
├── lean-toolchain                Lean version pin (v4.30.0-rc1)
├── DEVELOPMENT.md                Master scheme specification (~56 KB)
├── CLAUDE.md                     Development guidance + per-workstream change log
├── COUNTEREXAMPLE.md             Invariant-attack vulnerability analysis
├── POE.md                        High-level concept exposition
└── LICENSE                       MIT
```

---

## Build

```bash
# Automated setup (installs elan + pinned Lean toolchain, with SHA-256
# verification of elan-init.sh)
./scripts/setup_lean_env.sh

# Or, if Lean is already installed:
source ~/.elan/env && lake build

# Build a specific module
source ~/.elan/env && lake build Orbcrypt.GroupAction.Basic

# Download Mathlib precompiled cache (speeds up first build)
lake exe cache get
```

The CI pipeline runs the same commands plus a comment-aware `sorry`
strip, an `^axiom` declaration scan, and the consolidated
`scripts/audit_phase_16.lean` regression sentinel.

---

## Documentation map

| Audience | Start here |
|----------|-----------|
| **First-time reader** | [`POE.md`](POE.md) — high-level concept exposition (≈ 6 KB) |
| **Cryptographer** | [`DEVELOPMENT.md`](DEVELOPMENT.md) — full scheme specification + security analysis |
| **Vulnerability researcher** | [`COUNTEREXAMPLE.md`](COUNTEREXAMPLE.md) — invariant attack analysis |
| **Application designer** | [`docs/USE_CASES.md`](docs/USE_CASES.md), [`docs/MORE_USE_CASES.md`](docs/MORE_USE_CASES.md) |
| **Implementor** | [`implementation/README.md`](implementation/README.md), [`docs/PARAMETERS.md`](docs/PARAMETERS.md) |
| **Lean developer** | [`formalization/FORMALIZATION_PLAN.md`](formalization/FORMALIZATION_PLAN.md), [`CLAUDE.md`](CLAUDE.md) |
| **Auditor** | [`docs/VERIFICATION_REPORT.md`](docs/VERIFICATION_REPORT.md) — sorry/axiom audit, headline-results table, exit-criteria checklist |
| **Hardness reviewer** | [`docs/HARDNESS_ANALYSIS.md`](docs/HARDNESS_ANALYSIS.md), [`docs/PUBLIC_KEY_ANALYSIS.md`](docs/PUBLIC_KEY_ANALYSIS.md) |

---

## License

MIT — see [LICENSE](LICENSE).

This program comes with **ABSOLUTELY NO WARRANTY**. This is free
software, and you are welcome to redistribute it under certain
conditions.
