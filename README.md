# Orbcrypt

Symmetry-Keyed Encryption with Formal Verification in Lean 4

## Overview

Orbcrypt is a research-stage symmetric-key encryption scheme where security
arises from hiding the equivalence relation (orbit structure) that makes data
meaningful. A message is the identity of an orbit under a secret permutation
group G <= S_n; a ciphertext is a uniformly random element of that orbit.

The project includes machine-checked proofs in Lean 4 (using Mathlib) of three
core results: correctness, the invariant attack theorem, and conditional
IND-1-CPA security under the Orbit Indistinguishability Assumption (OIA).

## Status

**Formalization Complete — All 6 Phases Done**

All three headline results are machine-checked with zero `sorry`, zero warnings, zero custom axioms:

| # | Theorem | File | Axiom Dependencies |
|---|---------|------|--------------------|
| 1 | `correctness` — `decrypt(encrypt(g, m)) = some m` | `Theorems/Correctness.lean` | Standard Lean only (`propext`, `Classical.choice`, `Quot.sound`) |
| 2 | `invariant_attack` — separating invariant implies complete break | `Theorems/InvariantAttack.lean` | Standard Lean only (`propext`) |
| 3 | `oia_implies_1cpa` — OIA implies IND-1-CPA security | `Theorems/OIAImpliesCPA.lean` | Zero custom axioms (OIA is a hypothesis, not an axiom) |

### Axiom Transparency

This formalization introduces **zero custom axioms**. The Orbit Indistinguishability
Assumption (OIA) is a `Prop`-valued definition carried as an explicit hypothesis,
not a Lean `axiom`. Verify with `#print axioms Orbcrypt.<theorem_name>`.

### Module Summary

| Layer | Modules | Content |
|-------|---------|---------|
| Group Actions | `GroupAction/{Basic, Canonical, Invariant}` | Orbit/stabilizer API, canonical forms, G-invariant functions |
| Crypto Framework | `Crypto/{Scheme, Security, OIA}` | `OrbitEncScheme`, `Adversary`, `hasAdvantage`, `IsSecure`, `OIA` |
| Core Theorems | `Theorems/{Correctness, InvariantAttack, OIAImpliesCPA}` | Three headline results + contrapositive direction |
| Concrete Construction | `Construction/{Permutation, HGOE}` | S_n on bitstrings, HGOE instance, Hamming weight defense |

### Build Stats

- 11 Lean source files + root import file
- 56 public definitions and theorems, all with docstrings
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
