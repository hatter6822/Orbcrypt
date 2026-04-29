/-
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-/

import Orbcrypt.Optimization.QCCanonical
import Orbcrypt.KEM.Correctness

/-!
# Orbcrypt.Optimization.TwoPhaseDecrypt

Two-phase decryption: Lean specification of the Phase 15 decryption
pipeline. The GAP counterpart lives in
`implementation/gap/orbcrypt_fast_dec.g` (Work Unit 15.3).

## Scope (Phase 15 § 15.5)

The core correctness requirement:

> `can_full.canon x = can_residual.canon (can_cyclic.canon x)`

i.e. the full canonical form factors through the cyclic canonical form
followed by the residual canonical form. This file carries that
decomposition as an explicit hypothesis `hDecomp` and proves the
downstream consequences that the Phase 15 plan explicitly calls out:

* `two_phase_correct` — correctness of two-phase decryption on the
  image of the encryption map;
* `two_phase_kem_decaps` — the KEM decapsulation key is the same whether
  computed via the full canonical form or via the cyclic-then-residual
  composition;
* `two_phase_kem_correctness` — the two-phase fast path still satisfies
  `decaps(encaps g).1 = (encaps g).2` when `hDecomp` is assumed.

As with every Phase 15 optimisation, the decomposition hypothesis
`hDecomp` is a PROPERTY OF THE CANONICAL FORMS, not a consequence of
their existence. A concrete witness — the GAP reference — is
constructed so that `hDecomp` holds by construction; verifying that
witness formally is Phase 16 work.

## References

* `docs/planning/PHASE_15_DECRYPTION_OPTIMIZATION.md` § 15.5
* `implementation/gap/orbcrypt_fast_dec.g` (Work Unit 15.3)
* `Orbcrypt.KEM.Correctness` — the full-group correctness theorem we
  specialise.
-/

namespace Orbcrypt

variable {n : ℕ}

-- ============================================================================
-- Work Unit 15.5 (Lean): Two-phase decomposition hypothesis
-- ============================================================================

/-- **Two-phase decomposition predicate.**

    `TwoPhaseDecomposition G C can_full can_cyclic can_residual` holds when
    the full canonical form factors as `can_residual ∘ can_cyclic`:

    > `∀ x, can_full.canon x = can_residual.canon (can_cyclic.canon x)`

    This is the **strong** correctness requirement that the Phase 15
    §15.5 plan suggests. It says that the cheap composition
    `can_residual ∘ can_cyclic` produces *exactly the same* canonical
    representative as the expensive `can_full`.

    **Important caveat: the predicate FAILS in general.** The natural
    interpretation
    * `G`  = `PAut(C)` (the full hidden group)
    * `C`  = `(Z/bZ)^ell` subgroup (known cyclic structure)
    * `can_cyclic`  = block-wise lex-min rotation (`QCCyclicReduce`)
    * `can_residual` = lex-min over the right transversal of `C` in `G`
      (`CanonicalImageUnderTransversal`)
    * `can_full`  = `CanonicalImage(G, ·, OnSets)` (lex-min over G)

    does NOT in general satisfy the predicate, because lex-min does
    not commute with the residual-transversal action: the lex-min of
    `G · x` may come from a non-cyclic-canonical element of `(C ∩ G)·x`.
    A concrete counterexample is given in the GAP audit notes
    (`implementation/gap/orbcrypt_fast_dec.g` §5).

    This predicate is preserved as a HYPOTHESIS for theorems that
    require fast = slow agreement (e.g. when interoperating with a
    legacy slow-canon ciphertext stream). For practical KEM
    correctness, use `fast_kem_round_trip` below instead — it only
    needs orbit-constancy of `can_residual ∘ can_cyclic`, which the
    composition automatically inherits from the `CanonicalForm`
    structure. -/
def TwoPhaseDecomposition
    (G : Subgroup (Equiv.Perm (Fin n)))
    (C : Subgroup (Equiv.Perm (Fin n)))
    (can_full : CanonicalForm (↥G) (Bitstring n))
    (can_cyclic : QCCyclicCanonical C)
    (can_residual : CanonicalForm (↥G) (Bitstring n)) : Prop :=
  ∀ x : Bitstring n,
    can_full.canon x = can_residual.canon (can_cyclic.canon x)

/-- `two_phase_decompose` is definitional unfolding of
    `TwoPhaseDecomposition`. Stated as a named theorem so callers can
    rewrite by it without knowing the predicate's internal shape. -/
theorem two_phase_decompose
    {G C : Subgroup (Equiv.Perm (Fin n))}
    {can_full : CanonicalForm (↥G) (Bitstring n)}
    {can_cyclic : QCCyclicCanonical C}
    {can_residual : CanonicalForm (↥G) (Bitstring n)}
    (hDecomp : TwoPhaseDecomposition G C can_full can_cyclic can_residual)
    (x : Bitstring n) :
    can_full.canon x = can_residual.canon (can_cyclic.canon x) :=
  hDecomp x

-- ============================================================================
-- Work Unit 15.5 (Lean): two_phase_correct on an arbitrary ciphertext
-- ============================================================================

/-- **Phase 15 § 15.5 headline theorem.** The two-phase canonical form
    agrees with the full canonical form on the image `g • x` for every
    group element `g : ↥G` and every bitstring `x`. This is the
    property the GAP `CompareFastVsSlow` harness validates empirically.

    The statement is a consequence of `hDecomp`: the two-phase map is
    `can_residual ∘ can_cyclic`, and by `hDecomp` that composition is
    the full canonical map.

    **Proof strategy.** Apply `hDecomp` at `g • x`. -/
theorem two_phase_correct
    {G C : Subgroup (Equiv.Perm (Fin n))}
    (can_full : CanonicalForm (↥G) (Bitstring n))
    (can_cyclic : QCCyclicCanonical C)
    (can_residual : CanonicalForm (↥G) (Bitstring n))
    (hDecomp : TwoPhaseDecomposition G C can_full can_cyclic can_residual)
    (g : ↥G) (x : Bitstring n) :
    can_full.canon (g • x) =
      can_residual.canon (can_cyclic.canon (g • x)) :=
  hDecomp (g • x)

-- ============================================================================
-- Two-phase correctness is stable under the full-group action
-- ============================================================================

/-- The full canonical form is constant on G-orbits: for any `g : ↥G`,
    `can_full.canon (g • x) = can_full.canon x`. Direct consequence of
    the `CanonicalForm` orbit-characterisation axiom. This is the
    semantic guarantee that makes KEM decapsulation well-defined. -/
theorem full_canon_invariant
    {G : Subgroup (Equiv.Perm (Fin n))}
    (can_full : CanonicalForm (↥G) (Bitstring n))
    (g : ↥G) (x : Bitstring n) :
    can_full.canon (g • x) = can_full.canon x :=
  canon_eq_of_mem_orbit can_full x (g • x) (smul_mem_orbit g x)

/-- **Two-phase invariance under the full action.** Applying any group
    element `g : ↥G` before the two-phase pipeline yields the same
    result as applying the pipeline directly.

    **Proof strategy.** Combine `two_phase_correct` (which rewrites both
    sides as `can_full.canon (g • x)` resp. `can_full.canon x`) with
    `full_canon_invariant` (which collapses those to each other). -/
theorem two_phase_invariant_under_G
    {G C : Subgroup (Equiv.Perm (Fin n))}
    (can_full : CanonicalForm (↥G) (Bitstring n))
    (can_cyclic : QCCyclicCanonical C)
    (can_residual : CanonicalForm (↥G) (Bitstring n))
    (hDecomp : TwoPhaseDecomposition G C can_full can_cyclic can_residual)
    (g : ↥G) (x : Bitstring n) :
    can_residual.canon (can_cyclic.canon (g • x)) =
      can_residual.canon (can_cyclic.canon x) := by
  -- Both sides equal `can_full.canon (g • x)` and `can_full.canon x`
  -- respectively (via `hDecomp`), and those are equal (via invariance).
  rw [← hDecomp, ← hDecomp, full_canon_invariant can_full g x]

-- ============================================================================
-- Work Unit 15.5 (Lean): two-phase KEM correctness
-- ============================================================================

/-- **Two-phase KEM decapsulation.** Given a KEM whose canonical form is
    `can_full` and a matched two-phase decomposition, decapsulation via
    the composite `keyDerive ∘ can_residual.canon ∘ can_cyclic.canon`
    agrees with the usual `decaps` on every ciphertext `c`.

    This is the decapsulation-level statement of `two_phase_correct`:
    since the decapsulation key is computed by applying `keyDerive` to
    the canonical form, and the two canonical forms agree by `hDecomp`,
    the two decapsulation routines return the same key. -/
theorem two_phase_kem_decaps
    {K : Type*}
    {G C : Subgroup (Equiv.Perm (Fin n))}
    (kem : OrbitKEM (↥G) (Bitstring n) K)
    (can_cyclic : QCCyclicCanonical C)
    (can_residual : CanonicalForm (↥G) (Bitstring n))
    (hDecomp :
      TwoPhaseDecomposition G C kem.canonForm can_cyclic can_residual)
    (c : Bitstring n) :
    decaps kem c =
      kem.keyDerive (can_residual.canon (can_cyclic.canon c)) := by
  unfold decaps
  rw [hDecomp c]

/-- **Two-phase KEM correctness.** For any group element `g : ↥G`,
    two-phase decapsulation of `(encaps kem g).1` recovers
    `(encaps kem g).2`.

    **Proof.** Compose `two_phase_kem_decaps` (which rewrites the fast
    path to the full path) with `kem_correctness` (which says the full
    path is correct). -/
theorem two_phase_kem_correctness
    {K : Type*}
    {G C : Subgroup (Equiv.Perm (Fin n))}
    (kem : OrbitKEM (↥G) (Bitstring n) K)
    (can_cyclic : QCCyclicCanonical C)
    (can_residual : CanonicalForm (↥G) (Bitstring n))
    (hDecomp :
      TwoPhaseDecomposition G C kem.canonForm can_cyclic can_residual)
    (g : ↥G) :
    kem.keyDerive
        (can_residual.canon (can_cyclic.canon (encaps kem g).1)) =
      (encaps kem g).2 := by
  rw [← two_phase_kem_decaps kem can_cyclic can_residual hDecomp]
  exact kem_correctness kem g

-- ============================================================================
-- Work Unit 15.5 (Lean): syndrome-based decapsulation
-- ============================================================================

/-- **Orbit-constant function predicate.** `IsOrbitConstant G f` holds
    when `f` is constant on every orbit of `G`. The GAP syndrome
    function (`SyndromeOf`) is orbit-constant on any permutation
    automorphism group of a code; this abstraction lets the Phase 15
    proofs cite that property without fixing a concrete syndrome
    representation. -/
def IsOrbitConstant {K : Type*}
    (G : Subgroup (Equiv.Perm (Fin n)))
    (f : Bitstring n → K) : Prop :=
  ∀ (g : ↥G) (x : Bitstring n), f (g • x) = f x

/-- If `f` is orbit-constant on `G` then `f` applied to a ciphertext
    `(encaps kem g).1` equals `f` applied to the base point. This is
    the correctness statement for the syndrome-based decapsulation
    path: the "syndrome" of any ciphertext sampled from a single
    base-point orbit is the same as the syndrome of the base point. -/
theorem orbit_constant_encaps_eq_basePoint
    {K : Type*}
    {G : Subgroup (Equiv.Perm (Fin n))}
    {K' : Type*}
    (kem : OrbitKEM (↥G) (Bitstring n) K')
    (f : Bitstring n → K)
    (hConst : IsOrbitConstant G f)
    (g : ↥G) :
    f (encaps kem g).1 = f kem.basePoint := by
  -- (encaps kem g).1 = g • basePoint, and f is orbit-constant.
  show f (g • kem.basePoint) = f kem.basePoint
  exact hConst g kem.basePoint

-- ============================================================================
-- Phase 15 (Lean): KEM correctness via orbit-constancy of the fast canon
-- ============================================================================

/-- **Fast-KEM round-trip correctness.** When the fast canonical form
    `fastCanon` is orbit-constant under `G` and the encapsulation /
    decapsulation pair both derive their key via
    `keyDerive ∘ fastCanon`, the two values agree on every
    `g • basePoint`:

    > `keyDerive (fastCanon (g • basePoint)) =
    >   keyDerive (fastCanon basePoint)`.

    This is the actual correctness story for the GAP `FastEncaps` /
    `FastDecaps` pair (`implementation/gap/orbcrypt_fast_dec.g` §5).
    Unlike `two_phase_kem_correctness`, this theorem does NOT require
    the strong `TwoPhaseDecomposition` predicate; it only requires
    the orbit-constancy property that any composition of two
    `CanonicalForm` instances automatically inherits.

    **Proof.** Direct application of `IsOrbitConstant`. -/
theorem fast_kem_round_trip
    {K : Type*}
    {G : Subgroup (Equiv.Perm (Fin n))}
    (basePoint : Bitstring n)
    (fastCanon : Bitstring n → Bitstring n)
    (keyDerive : Bitstring n → K)
    (hConst : IsOrbitConstant G fastCanon)
    (g : ↥G) :
    keyDerive (fastCanon (g • basePoint)) =
      keyDerive (fastCanon basePoint) := by
  rw [hConst g basePoint]

/-- If a fast preprocessor `fastCanon` keeps each input inside its
    own `G`-orbit (so that the slow canonical form is unchanged by
    the preprocessor), then the composite `can_full ∘ fastCanon` is
    G-orbit-constant — even when `fastCanon` itself is not. This is
    a useful template for "in-orbit cleanup followed by slow
    finalisation"; it does NOT cover the GAP `FastCanonicalImage`
    (which uses `lex-min over T-images` rather than `can_full`), but
    it does cover any future fast path that ends in
    `CanonicalImage(G, ., OnSets)`. -/
theorem fast_canon_composition_orbit_constant
    {G : Subgroup (Equiv.Perm (Fin n))}
    (can_full : CanonicalForm (↥G) (Bitstring n))
    (fastCanon : Bitstring n → Bitstring n)
    (hCommutes : ∀ x : Bitstring n,
       can_full.canon (fastCanon x) = can_full.canon x) :
    IsOrbitConstant G (fun x => can_full.canon (fastCanon x)) := by
  intro g x
  show can_full.canon (fastCanon (g • x)) = can_full.canon (fastCanon x)
  rw [hCommutes (g • x), hCommutes x, full_canon_invariant can_full g x]

end Orbcrypt
