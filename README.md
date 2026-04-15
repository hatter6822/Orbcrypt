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
probabilistic security foundations, and key compression with nonce-based encryption.

## Status

**Formalization Complete — Phases 1–9 Done**

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
| KEM | `KEM/{Syntax, Encapsulate, Correctness, Security}` | KEM reformulation, KEMOIA, KEM security |
| Probability | `Probability/{Monad, Negligible, Advantage}` | PMF wrappers, negligible functions, hybrid argument |
| Key Management | `KeyMgmt/{SeedKey, Nonce}` | Seed-based key compression, nonce-based encryption |
| Concrete Construction | `Construction/{Permutation, HGOE, HGOEKEM}` | S_n on bitstrings, HGOE instance, HGOE-KEM |

### Build Stats

- 23 Lean source files + root import file
- ~100 public definitions and theorems, all with docstrings
- Zero `sorry`, zero custom axioms, zero warnings
- Mathlib pinned to commit `fa6418a8` (Lean 4 v4.30.0-rc1)
- GitHub Actions CI on every push

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

## License

MIT
