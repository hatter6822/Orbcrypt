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

**Phase 1 (Project Scaffolding) — Complete**

- Lean 4 v4.30.0-rc1 project with Mathlib dependency
- 11 module stubs across 4 layers (GroupAction, Crypto, Theorems, Construction)
- `lake build` succeeds with zero errors and zero warnings

**Next:** Phase 2 — Group Action Foundations

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
