import Orbcrypt.GroupAction.Canonical
import Orbcrypt.Construction.Permutation

/-!
# Orbcrypt.Optimization.QCCanonical

Quasi-cyclic canonical form: Lean specification of the fast phase of the
Phase 15 decryption-optimisation pipeline. The GAP counterpart lives in
`implementation/gap/orbcrypt_fast_dec.g` (Work Units 15.1a–15.1c).

## Scope

This module introduces an *abstraction* — `QCCyclicCanonical` — for a
canonical form whose action group is contained inside the full
permutation group of `Bitstring n`. It does NOT attempt to re-derive the
concrete per-block minimal-rotation function in Lean; doing so would
require a rich lexicographic/Finset library that adds hundreds of lines
without changing the Phase 15 correctness story.

What this file DOES provide is the interface used by
`Orbcrypt.Optimization.TwoPhaseDecrypt`:

* `QCCyclicCanonical` — a `CanonicalForm` for a cyclic subgroup of S_n
  acting on `Bitstring n`. Any concrete implementation (in Lean or GAP)
  must satisfy the `CanonicalForm` obligations.
* `qc_invariant_under_cyclic` — the cyclic canonical form is constant
  on its own orbits, packaged as a reusable lemma.

The GAP reference code constructs a specific `QCCyclicCanonical` via
block-wise lexicographic minimum, but any other choice (e.g. lex-max)
works equally well — the two-phase correctness theorem is parametric
over the choice of `canon`.

## References

* `docs/planning/PHASE_15_DECRYPTION_OPTIMIZATION.md` § 15.1 / § 15.5
* `implementation/gap/orbcrypt_fast_dec.g` (Work Units 15.1a–15.1c)
-/

namespace Orbcrypt
namespace Optimization

variable {n : ℕ}

-- ============================================================================
-- Work Unit 15.5 (Lean): QCCyclicCanonical abbreviation
-- ============================================================================

/-- A canonical form for a subgroup `C` of `Equiv.Perm (Fin n)` acting on
    `Bitstring n`. The GAP implementation chooses `C = (Z/bZ)^ell` (the
    per-block cyclic shift group) and picks the lexicographically minimal
    block rotation, but this file abstracts over that choice so every
    downstream theorem is independent of the concrete canonicalisation
    strategy.

    This is a thin alias — we reuse `Orbcrypt.CanonicalForm` rather than
    introducing a new structure, so the existing API
    (`canon_eq_of_mem_orbit`, `canon_idem`, `orbit_iff`) is available
    automatically. -/
abbrev QCCyclicCanonical (C : Subgroup (Equiv.Perm (Fin n))) :=
  CanonicalForm (↥C) (Bitstring n)

-- ============================================================================
-- Orbit-constancy repackaging
-- ============================================================================

/-- The QC cyclic canonical form is constant on any orbit of `C` acting
    on `Bitstring n`. This is just `canon_eq_of_mem_orbit` specialised
    to the subgroup action; it is stated separately so that the
    two-phase correctness argument in `TwoPhaseDecrypt.lean` can cite
    it by a descriptive name. -/
theorem qc_invariant_under_cyclic
    (C : Subgroup (Equiv.Perm (Fin n)))
    (qc : QCCyclicCanonical C)
    (g : C) (x : Bitstring n) :
    qc.canon (g • x) = qc.canon x := by
  -- `g • x` is in the orbit of `x` under `C`, so canonical-form-on-orbit
  -- equality applies.
  exact canon_eq_of_mem_orbit qc x (g • x) (smul_mem_orbit g x)

/-- Idempotence (re-exported for ergonomics): applying the cyclic
    canonical form twice is the same as applying it once. -/
theorem qc_canon_idem
    (C : Subgroup (Equiv.Perm (Fin n)))
    (qc : QCCyclicCanonical C) (x : Bitstring n) :
    qc.canon (qc.canon x) = qc.canon x :=
  canon_idem qc x

end Optimization
end Orbcrypt
