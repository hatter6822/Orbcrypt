# Orbcrypt

Symmetry-Keyed Encryption with Formal Verification in Lean 4

## Overview

Orbcrypt is a research-stage symmetric-key encryption scheme where security
arises from hiding the equivalence relation (orbit structure) that makes data
meaningful. A message is the identity of an orbit under a secret permutation
group G <= S_n; a ciphertext is a uniformly random element of that orbit.

The project includes machine-checked proofs in Lean 4 (using Mathlib) of
correctness, the invariant attack theorem, conditional IND-1-CPA security
under the Orbit Indistinguishability Assumption (OIA), KEM reformulation,
probabilistic security foundations, key compression with nonce-based
encryption, authenticated encryption (AEAD + KEM/DEM), hardness-chain
alignment with NIST PQC candidates (LESS/MEDS/TI), and public-key extension
scaffolding (oblivious sampling, KEM agreement, CSIDH-style commutative
actions).

## Status

**Formalization Complete — Phases 1–14 and Phase 16 Done**

Phase 14 (Parameter Selection & Benchmarks) published concrete
parameter tables, a security-margin analysis against four attack
vectors, a cross-scheme comparison, and three-tier parameter
recommendations (`conservative`, `balanced`, `aggressive`) across
λ ∈ {80, 128, 192, 256}. See [`docs/PARAMETERS.md`](docs/PARAMETERS.md)
and the raw data under [`docs/benchmarks/`](docs/benchmarks/).

Phase 16 (Formal Verification of New Components) published the
consolidated end-to-end verification report in
[`docs/VERIFICATION_REPORT.md`](docs/VERIFICATION_REPORT.md), the
comprehensive `#print axioms` audit script in
[`scripts/audit_phase_16.lean`](scripts/audit_phase_16.lean) exercising
every public declaration (342 total, zero `sorryAx`, zero custom
axioms), and a CI regression sentinel that de-wraps Lean's multi-line
axiom lists before scanning so a custom axiom cannot hide on a
continuation line.

All headline results are machine-checked with zero `sorry`, zero warnings, zero custom axioms:

| # | Theorem | File | Axiom Dependencies |
|---|---------|------|--------------------|
| 1 | `correctness` — `decrypt(encrypt(g, m)) = some m` | `Theorems/Correctness.lean` | Standard Lean only |
| 2 | `invariant_attack` — separating invariant implies complete break | `Theorems/InvariantAttack.lean` | Standard Lean only |
| 3 | `oia_implies_1cpa` — OIA implies IND-1-CPA security | `Theorems/OIAImpliesCPA.lean` | Zero custom axioms (OIA is a hypothesis) |
| 4 | `kem_correctness` — KEM decaps recovers encapsulated key | `KEM/Correctness.lean` | Standard Lean only (rfl) |
| 5 | `kemoia_implies_secure` — KEMOIA implies KEM security | `KEM/Security.lean` | Zero custom axioms (KEMOIA is a hypothesis) |
| 6 | `concrete_oia_implies_1cpa` — ConcreteOIA(ε) implies advantage ≤ ε | `Crypto/CompSecurity.lean` | Zero custom axioms |
| 7 | `seed_kem_correctness` — seed-based KEM is correct | `KeyMgmt/SeedKey.lean` | Standard Lean only |
| 8 | `nonce_reuse_leaks_orbit` — cross-KEM nonce reuse leaks orbits | `KeyMgmt/Nonce.lean` | Standard Lean only |
| 9 | `aead_correctness` — authenticated KEM correctness | `AEAD/AEAD.lean` | Standard Lean only |
| 10 | `hybrid_correctness` — KEM+DEM hybrid correctness | `AEAD/Modes.lean` | Standard Lean only |
| 11 | `hardness_chain_implies_security` — TI-hardness → IND-1-CPA | `Hardness/Reductions.lean` | Zero custom axioms (HardnessChain is a hypothesis) |
| 12 | `oblivious_sample_in_orbit` — oblivious sampling preserves orbits | `PublicKey/ObliviousSampling.lean` | Standard Lean only |
| 13 | `kem_agreement_correctness` — two-party orbit-KEM agreement | `PublicKey/KEMAgreement.lean` | Standard Lean only |
| 14 | `csidh_correctness` — `a • b • x = b • a • x` under `CommGroupAction` | `PublicKey/CommutativeAction.lean` | `CommGroupAction.comm` (typeclass axiom) |
| 15 | `comm_pke_correctness` — CSIDH-style public-key encryption correctness | `PublicKey/CommutativeAction.lean` | `CommGroupAction.comm` + `pk_valid` |

### Axiom Transparency

This formalization introduces **zero custom axioms**. The Orbit Indistinguishability
Assumption (OIA) is a `Prop`-valued definition carried as an explicit hypothesis,
not a Lean `axiom`. Verify with `#print axioms Orbcrypt.<theorem_name>`.

### Module Summary

| Layer | Modules | Content |
|-------|---------|---------|
| Group Actions | `GroupAction/{Basic, Canonical, Invariant}` | Orbit/stabilizer API, canonical forms, G-invariant functions |
| Crypto Framework | `Crypto/{Scheme, Security, OIA, CompOIA, CompSecurity}` | Scheme, adversary, OIA, probabilistic security |
| Core Theorems | `Theorems/{Correctness, InvariantAttack, OIAImpliesCPA}` | Three headline results + contrapositive direction |
| KEM | `KEM/{Syntax, Encapsulate, Correctness, Security, CompSecurity}` | KEM reformulation, KEMOIA, KEM security, probabilistic KEM security (Workstream E1) |
| Probability | `Probability/{Monad, Negligible, Advantage}` | PMF wrappers, negligible functions, hybrid argument |
| Key Management | `KeyMgmt/{SeedKey, Nonce}` | Seed-based key compression, nonce-based encryption |
| Concrete Construction | `Construction/{Permutation, HGOE, HGOEKEM}` | S_n on bitstrings, HGOE instance, HGOE-KEM |
| AEAD | `AEAD/{MAC, AEAD, Modes, CarterWegmanMAC}` | MAC, Encrypt-then-MAC authenticated KEM, KEM+DEM hybrid, concrete `verify_inj` witness (Workstream C4) |
| Hardness | `Hardness/{CodeEquivalence, TensorAction, Encoding, Reductions}` | CE/TI problems, orbit-preserving encoding interface, reduction chain to IND-1-CPA |
| Public-Key Extension | `PublicKey/{ObliviousSampling, KEMAgreement, CommutativeAction, CombineImpossibility}` | Orbital randomizers, two-party KEM agreement, CSIDH-style `CommGroupAction` and `CommOrbitPKE`, equivariant-combiner obstruction (Workstream E6) |

### Build Stats

- 36 Lean source files + root import file
- 343 public declarations (def / theorem / structure / class / instance / abbrev), all with docstrings
- 342 declarations exercised by `scripts/audit_phase_16.lean` with `#print axioms` (every public declaration; 133 depend on *no* axioms, 209 depend only on the standard Lean trio)
- Zero `sorry`, zero custom axioms, zero warnings
- `lake build Orbcrypt` runs 3,364 jobs successfully
- Mathlib pinned to commit `fa6418a8` (Lean 4 v4.30.0-rc1)
- GitHub Actions CI on every push (build + sorry scan + axiom-decl scan + Phase 16 audit regression sentinel)
- Package version: `0.1.4` (see `lakefile.lean`)

## Build

```bash
# Automated setup (installs elan + Lean toolchain)
./scripts/setup_lean_env.sh

# Or if Lean is already installed:
source ~/.elan/env && lake build
```

## Documentation

| Document | Purpose |
|----------|---------|
| [DEVELOPMENT.md](DEVELOPMENT.md) | Full scheme specification and security analysis |
| [COUNTEREXAMPLE.md](COUNTEREXAMPLE.md) | Invariant attack vulnerability analysis |
| [POE.md](POE.md) | High-level concept exposition |
| [formalization/FORMALIZATION_PLAN.md](formalization/FORMALIZATION_PLAN.md) | Lean 4 formalization roadmap |
| [docs/HARDNESS_ANALYSIS.md](docs/HARDNESS_ANALYSIS.md) | Phase 12 — hardness reduction chain and NIST PQC alignment |
| [docs/PUBLIC_KEY_ANALYSIS.md](docs/PUBLIC_KEY_ANALYSIS.md) | Phase 13 — public-key feasibility analysis |
| [docs/PARAMETERS.md](docs/PARAMETERS.md) | Phase 14 — parameter recommendations (3 tiers × 4 security levels) |
| [docs/VERIFICATION_REPORT.md](docs/VERIFICATION_REPORT.md) | Phase 16 — end-to-end verification report (sorry audit, axiom audit, headline results table, exit-criteria checklist) |

## License

MIT
