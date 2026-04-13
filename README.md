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

**Phase 4 (Core Theorems) — Complete**

All three headline results are machine-checked with zero `sorry`, zero warnings, zero custom axioms:

| # | Theorem | File | Axiom Dependencies |
|---|---------|------|--------------------|
| 1 | `correctness` — `decrypt(encrypt(g, m)) = some m` | `Theorems/Correctness.lean` | Standard Lean only |
| 2 | `invariant_attack` — separating invariant implies complete break | `Theorems/InvariantAttack.lean` | Standard Lean only |
| 3 | `oia_implies_1cpa` — OIA implies IND-1-CPA security | `Theorems/OIAImpliesCPA.lean` | Zero axioms (OIA is a hypothesis) |

Prior phases complete:
- `GroupAction/` — orbit/stabilizer API, canonical forms, G-invariant functions (Phase 2)
- `Crypto/` — `OrbitEncScheme`, `Adversary`, `hasAdvantage`, `IsSecure`, `OIA` (Phase 3)
- `lake build` succeeds (902 jobs, zero errors)

**Next:** Phase 5 — Concrete Construction (S_n action on bitstrings, HGOE instance, Hamming defense)

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
