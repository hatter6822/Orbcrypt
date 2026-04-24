import Orbcrypt.AEAD.MAC
import Orbcrypt.GroupAction.Invariant
import Orbcrypt.KEM.Syntax
import Orbcrypt.KEM.Encapsulate
import Orbcrypt.KEM.Correctness

/-!
# Orbcrypt.AEAD.AEAD

Authenticated Encryption with Associated Data (AEAD) for the Orbit KEM.

## Overview

Composes the `OrbitKEM` (Phase 7) with a `MAC` (work unit 10.1) following the
Encrypt-then-MAC paradigm (Bellare & Namprempre, 2000). Encapsulation produces
a (ciphertext, key, tag) triple; decapsulation verifies the tag before releasing
the key.

## Key definitions

* `Orbcrypt.AuthOrbitKEM` — authenticated KEM extending `OrbitKEM` with a MAC
* `Orbcrypt.authEncaps` — Encrypt-then-MAC encapsulation
* `Orbcrypt.authDecaps` — Verify-then-Decrypt decapsulation
* `Orbcrypt.aead_correctness` — `authDecaps` recovers the key from honest pairs
* `Orbcrypt.INT_CTXT` — ciphertext integrity: no adversary forges an
  in-orbit `(c, t)` that decapsulates.  Out-of-orbit ciphertexts are
  rejected by the game's well-formedness precondition `hOrbit`.
* `Orbcrypt.authEncrypt_is_int_ctxt` — INT_CTXT holds unconditionally for
  every honestly composed `AuthOrbitKEM` (audit F-07, Workstream C2 +
  audit 2026-04-23 Workstream B refactor: the orbit-cover hypothesis
  has been absorbed into the game's per-challenge precondition)

## Composition order

Encrypt-then-MAC (EtM) is the provably secure composition paradigm. The
alternatives (MAC-then-Encrypt, Encrypt-and-MAC) have known vulnerabilities
in certain settings.

## INT_CTXT game-shape refinement (audit 2026-04-23 Workstream B)

Pre-Workstream-B, `INT_CTXT` was an unconditional predicate that
`authEncrypt_is_int_ctxt` discharged under the extra top-level hypothesis
`hOrbitCover : ∀ c : X, c ∈ orbit G basePoint`.  That hypothesis is
**false on production HGOE**: `|Bitstring n| = 2^n` strictly exceeds
any orbit's cardinality by the orbit–stabiliser bound, so the pre-B
theorem was vacuously applicable to the production construction.

Workstream B absorbs the orbit condition into `INT_CTXT` itself as a
per-challenge well-formedness precondition `hOrbit`.  Conceptually: the
game **rejects** ciphertexts outside `orbit G basePoint` by convention
— they are not "valid forgeries" in any realistic threat model, because
they cannot arise from an honest sender and an honest KEM.  Consumers
who need INT-CTXT-on-arbitrary-ciphertexts (a stronger real-world
threat model where the KEM's decapsulation routine validates orbit
membership before returning a key) pair this game with an explicit
orbit-check at decapsulation time.

Post-refactor, `authEncrypt_is_int_ctxt` discharges `INT_CTXT`
*unconditionally* on every `AuthOrbitKEM` — no top-level orbit-cover
hypothesis remains at the theorem level.

## References

* docs/planning/PHASE_10_AUTHENTICATED_ENCRYPTION.md — work units 10.2–10.4
* docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md § 6 — Workstream C (F-07)
* docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md § 5 — Workstream B
  (`INT_CTXT` orbit-cover refactor, V1-1 / I-03)
* KEM/Syntax.lean, KEM/Encapsulate.lean — base KEM infrastructure
-/

set_option autoImplicit false

namespace Orbcrypt

-- ============================================================================
-- Work Unit 10.2: AEAD Definition
-- ============================================================================

variable {G : Type*} {X : Type*} {K : Type*} {Tag : Type*}
  [Group G] [MulAction G X] [DecidableEq X]

/--
Authenticated Key Encapsulation Mechanism.

Composes an `OrbitKEM` with a MAC that authenticates ciphertexts under the
encapsulated key. The MAC's key type matches the KEM's key type `K`, and
the MAC's message type matches the ciphertext space `X`.

Uses explicit field inclusion rather than `extends` to avoid Lean 4 structure
inheritance issues with 4+ type parameters (Risk 2 mitigation from Phase 10
planning document).

**Fields:**
- `kem : OrbitKEM G X K` — the underlying (unauthenticated) KEM, providing
  `basePoint`, `canonForm`, and `keyDerive` via `akem.kem`
- `mac : MAC K X Tag` — MAC for ciphertext authentication
-/
structure AuthOrbitKEM (G : Type*) (X : Type*) (K : Type*) (Tag : Type*)
    [Group G] [MulAction G X] [DecidableEq X] where
  /-- The underlying (unauthenticated) KEM. -/
  kem : OrbitKEM G X K
  /-- MAC for authenticating ciphertexts under the encapsulated key. -/
  mac : MAC K X Tag

/--
Authenticated encapsulation (Encrypt-then-MAC).

1. Run `encaps` to get `(ciphertext, key)`.
2. Compute `tag = mac.tag key ciphertext`.
3. Return `(ciphertext, key, tag)`.

The caller uses the key with a DEM for actual message encryption, and
transmits the ciphertext and tag to the receiver.
-/
def authEncaps (akem : AuthOrbitKEM G X K Tag) (g : G) :
    X × K × Tag :=
  let (c, k) := encaps akem.kem g
  (c, k, akem.mac.tag k c)

/--
Authenticated decapsulation (Verify-then-Decrypt).

1. Recover the key via `decaps`.
2. Verify the tag: `mac.verify key ciphertext tag`.
3. If verification passes, return `some key`; otherwise return `none`.

Returning `Option K` forces callers to handle authentication failures
explicitly, preventing accidental use of unauthenticated data.
-/
def authDecaps (akem : AuthOrbitKEM G X K Tag)
    (c : X) (t : Tag) : Option K :=
  let k := decaps akem.kem c
  if akem.mac.verify k c t then some k else none

-- Simp lemmas for unfolding authEncaps/authDecaps in proofs

/-- Unfold the ciphertext component of authenticated encapsulation. -/
@[simp]
theorem authEncaps_fst (akem : AuthOrbitKEM G X K Tag) (g : G) :
    (authEncaps akem g).1 = (encaps akem.kem g).1 := rfl

/-- Unfold the key component of authenticated encapsulation. -/
@[simp]
theorem authEncaps_snd_fst (akem : AuthOrbitKEM G X K Tag) (g : G) :
    (authEncaps akem g).2.1 = (encaps akem.kem g).2 := rfl

/-- Unfold the tag component of authenticated encapsulation. -/
@[simp]
theorem authEncaps_snd_snd (akem : AuthOrbitKEM G X K Tag) (g : G) :
    (authEncaps akem g).2.2 =
      akem.mac.tag (encaps akem.kem g).2 (encaps akem.kem g).1 := rfl

-- ============================================================================
-- Work Unit 10.3: AEAD Correctness
-- ============================================================================

/--
**AEAD Correctness Theorem.** Authenticated decapsulation recovers the key
from honestly generated (ciphertext, tag) pairs.

**Proof strategy:**
1. Unfold `authEncaps` to get `c = g • basePoint`, `k = keyDerive(canon(c))`,
   and `t = mac.tag k c`.
2. In `authDecaps`, `decaps` recomputes `k' = keyDerive(canon(c))`.
3. By `kem_correctness`, `k' = k`.
4. The verification check becomes `mac.verify k c (mac.tag k c)`.
5. By `mac.correct`, this is `true`, so `authDecaps` returns `some k`.

**Axioms:** Only standard Lean axioms. No custom axioms, no placeholders.
-/
theorem aead_correctness (akem : AuthOrbitKEM G X K Tag) (g : G) :
    let (c, k, t) := authEncaps akem g
    authDecaps akem c t = some k := by
  -- Unfold definitions: authEncaps produces (c, k, t) where
  -- c = (encaps akem.kem g).1, k = (encaps akem.kem g).2,
  -- t = mac.tag k c
  simp only [authEncaps, authDecaps, encaps, decaps]
  -- The verify check reduces to mac.verify k c (mac.tag k c)
  -- which is true by mac.correct
  simp [akem.mac.correct]

-- ============================================================================
-- Work Unit 10.4: INT-CTXT Security Definition
-- ============================================================================

/--
**Ciphertext Integrity (INT-CTXT).**

No adversary can produce a valid `(c, t)` forgery under the following
game shape:

1. The adversary presents a ciphertext `c : X` and a tag `t : Tag`.
2. The game's **well-formedness precondition** `hOrbit` requires that
   `c ∈ orbit G basePoint` — out-of-orbit ciphertexts are rejected by
   the game and do not count as forgeries. This matches the intended
   real-world KEM model where decapsulation only operates on
   ciphertexts produced by a transitive action on `basePoint`.
3. The **freshness condition** `hFresh` requires that no honest
   encapsulation `authEncaps akem g` produces the same `(c, t)` pair
   — i.e., the adversary forged without the challenger's cooperation.
4. Under those preconditions, `authDecaps akem c t = none`: the
   forgery is rejected, no key is released.

**Design rationale:**
- **Orbit precondition (`hOrbit`).** Audit 2026-04-23 Workstream B
  moved this condition from a theorem-level `hOrbitCover` hypothesis
  (false on production HGOE, where `|Bitstring n| = 2^n` exceeds any
  orbit) to a per-challenge game-level well-formedness precondition.
  The game is now inhabited unconditionally on every `AuthOrbitKEM`
  (see `authEncrypt_is_int_ctxt`).
- **Freshness condition (`hFresh`).** The disjunction
  `c ≠ ... ∨ t ≠ ...` is Prod inequality expanded for convenient
  destructuring: no group element `g` produces a matching
  `(ciphertext, tag)` pair.
- **`= none` conclusion.** The forgery is rejected — decapsulation
  refuses to release a key for an unauthenticated ciphertext.

**Scope:** This captures integrity in the no-query setting. Multi-query
CCA extensions (with encapsulation/decapsulation oracles and query logs)
are future work (Phase 12+). Consumers wanting INT-CTXT-on-arbitrary-
ciphertexts (stronger threat model) should pair this predicate with an
explicit orbit-check before decapsulation; the decapsulation helper
`decapsSafe` (planned in Workstream H of the 2026-04-23 plan) is the
canonical shape.
-/
def INT_CTXT (akem : AuthOrbitKEM G X K Tag) : Prop :=
  ∀ (c : X) (t : Tag),
    c ∈ MulAction.orbit G akem.kem.basePoint →
    (∀ g : G, c ≠ (authEncaps akem g).1 ∨
              t ≠ (authEncaps akem g).2.2) →
    authDecaps akem c t = none

-- ============================================================================
-- Workstream C (audit F-07) + Workstream B (audit 2026-04-23):
-- INT_CTXT proof for honestly-composed AuthOrbitKEMs.
-- ============================================================================
--
-- The `INT_CTXT` predicate carries two per-challenge hypotheses:
-- `hOrbit` (the ciphertext lies in `orbit G basePoint`, game
-- well-formedness precondition; see the `INT_CTXT` docstring) and
-- `hFresh` (no honest encapsulation produces this `(c, t)` pair).
-- Workstream C1 added `MAC.verify_inj` (tag uniqueness / SUF-CMA in the
-- information-theoretic sense). Workstream C2 produced the first
-- concrete proof; Workstream B (audit 2026-04-23) refactored it so the
-- orbit condition is a per-challenge precondition on the game rather
-- than a theorem-level obligation on the scheme (making the theorem
-- genuinely Standalone on every `AuthOrbitKEM`).
--
-- * C2a — `authDecaps_none_of_verify_false`: the easy `verify = false`
--   branch (unfold + rfl).
-- * C2b — `keyDerive_canon_eq_of_mem_orbit`: keys depend only on the
--   orbit of the ciphertext (unconditional, discharged via
--   `canon_eq_of_mem_orbit` / `canonical_isGInvariant`).
-- * C2c — `authEncrypt_is_int_ctxt`: stitches (a) and (b) together,
--   consuming the per-challenge `hOrbit` from the `INT_CTXT` binder.
--   Post-Workstream-B, the theorem signature is `INT_CTXT akem` —
--   no top-level orbit-cover hypothesis.

section INT_CTXT_Proof

/-- **C2a — easy branch.** If MAC verification fails on `(c, t)` then
    `authDecaps` returns `none` directly. No new hypothesis beyond
    `verify … = false`; used by the main theorem as the `¬ verify` branch
    of a `by_cases`. -/
private theorem authDecaps_none_of_verify_false
    (akem : AuthOrbitKEM G X K Tag) (c : X) (t : Tag)
    (hVerify : akem.mac.verify
        (akem.kem.keyDerive (akem.kem.canonForm.canon c)) c t = false) :
    authDecaps akem c t = none := by
  -- `authDecaps` unfolds to `if verify … then some _ else none`; the false
  -- branch evaluates to `none`.
  simp [authDecaps, decaps, hVerify]

/-- **C2b — key uniqueness.** The decapsulation key
    `keyDerive (canon c)` depends only on the orbit of `c`: if `c` lies in
    the orbit of the base point, both sides reduce to
    `keyDerive (canon basePoint)`.

    This is unconditional — it is an immediate consequence of
    `canon_eq_of_mem_orbit` (which in turn uses `canonical_isGInvariant`).
    We expose it as a private lemma because the `authEncrypt_is_int_ctxt`
    true-branch argument needs to rewrite the honestly-computed MAC key
    against the key produced by `decaps`. -/
private theorem keyDerive_canon_eq_of_mem_orbit
    (akem : AuthOrbitKEM G X K Tag) {c : X}
    (hc : c ∈ MulAction.orbit G akem.kem.basePoint) :
    akem.kem.keyDerive (akem.kem.canonForm.canon c) =
    akem.kem.keyDerive (akem.kem.canonForm.canon akem.kem.basePoint) := by
  -- `canon_eq_of_mem_orbit` : `canon c = canon basePoint` whenever
  -- `c ∈ orbit G basePoint`; lift through `keyDerive`.
  have h : akem.kem.canonForm.canon c =
      akem.kem.canonForm.canon akem.kem.basePoint :=
    canon_eq_of_mem_orbit akem.kem.canonForm _ _ hc
  rw [h]

/-- **C2c — ciphertext integrity for honestly-composed AuthOrbitKEMs.**

    Every `AuthOrbitKEM` satisfies `INT_CTXT` unconditionally. The
    orbit-cover assumption that the pre-Workstream-B formulation
    carried as a theorem-level hypothesis
    (`hOrbitCover : ∀ c : X, c ∈ MulAction.orbit G akem.kem.basePoint`)
    has been absorbed into the `INT_CTXT` game as a per-challenge
    well-formedness precondition `hOrbit` (see the `INT_CTXT`
    docstring above). Out-of-orbit ciphertexts are rejected by the
    game; only in-orbit `(c, t)` pairs count as potential forgeries,
    and for those the proof discharges the `authDecaps = none`
    conclusion from `MAC.verify_inj` + orbit-restricted key
    uniqueness.

    **Proof sketch (audit F-07 Workstream C2c, refined by audit
    2026-04-23 Workstream B).**
    Let `k := keyDerive (canon c)` be the decapsulation key. Case-split
    on `akem.mac.verify k c t`:

    * `false`: `authDecaps` returns `none` directly (C2a).
    * `true`: by `MAC.verify_inj` (Workstream C1), `t = tag k c`. By
      the per-challenge `hOrbit`, some `g : G` witnesses
      `c = g • basePoint`. Then `(authEncaps akem g).1 = c` and, via
      C2b, `(authEncaps akem g).2.2 = tag k c = t` — a contradiction
      with `hFresh g`.

    **Axioms.** Only standard Lean (`propext`, `Classical.choice`,
    `Quot.sound`). No custom axiom, no `sorry`. -/
theorem authEncrypt_is_int_ctxt (akem : AuthOrbitKEM G X K Tag) :
    INT_CTXT akem := by
  intro c t hOrbit hFresh
  -- Case-split on whether MAC verification accepts `(c, t)` under the
  -- decapsulation key `keyDerive (canon c)`.
  by_cases hVerify :
      akem.mac.verify (akem.kem.keyDerive (akem.kem.canonForm.canon c)) c t = true
  case neg =>
    -- `verify` returns `Bool`, so `¬ (verify = true)` forces `verify = false`.
    have hFalse :
        akem.mac.verify
          (akem.kem.keyDerive (akem.kem.canonForm.canon c)) c t = false := by
      cases hv :
          akem.mac.verify
            (akem.kem.keyDerive (akem.kem.canonForm.canon c)) c t with
      | false => rfl
      | true  => exact absurd hv hVerify
    exact authDecaps_none_of_verify_false akem c t hFalse
  case pos =>
    -- `t = tag k c` by MAC tag-uniqueness (`verify_inj`, Workstream C1).
    have htag :
        t = akem.mac.tag
              (akem.kem.keyDerive (akem.kem.canonForm.canon c)) c :=
      akem.mac.verify_inj
        (akem.kem.keyDerive (akem.kem.canonForm.canon c)) c t hVerify
    -- `hOrbit` (the per-challenge precondition) witnesses a `g` with
    -- `g • basePoint = c`.
    obtain ⟨g, hg⟩ := MulAction.mem_orbit_iff.mp hOrbit
    -- The honest-encapsulation equality `(c, t) = (authEncaps akem g).1, .2.2`
    -- will contradict `hFresh g`; flip the goal to `False` before proving either
    -- side of the honest-equality disjunction.
    exfalso
    -- Specialise `hFresh` at that `g` and derive a contradiction.
    rcases hFresh g with hNeCt | hNeTag
    · -- `c ≠ (authEncaps akem g).1 = g • basePoint`, but `hg : g • basePoint = c`.
      apply hNeCt
      -- `(authEncaps akem g).1` reduces to `g • basePoint` by `authEncaps_fst`
      -- (simp lemma) and `encaps_fst`.
      rw [authEncaps_fst, encaps_fst, hg]
    · -- `t ≠ (authEncaps akem g).2.2`; via C2b this equals `tag (keyDerive (canon c)) c`.
      apply hNeTag
      -- Reduce `(authEncaps akem g).2.2` to its canonical form via the existing
      -- simp lemmas on `authEncaps` + `encaps`.
      rw [authEncaps_snd_snd, encaps_fst, encaps_snd]
      -- Bridge: `keyDerive (canon (g • basePoint)) = keyDerive (canon c)`.
      have hgc : g • akem.kem.basePoint ∈
          MulAction.orbit G akem.kem.basePoint :=
        MulAction.mem_orbit _ _
      have hEqKey :
          akem.kem.keyDerive
              (akem.kem.canonForm.canon (g • akem.kem.basePoint)) =
          akem.kem.keyDerive (akem.kem.canonForm.canon c) := by
        -- Both sides reduce to `keyDerive (canon basePoint)` via C2b.
        calc akem.kem.keyDerive
              (akem.kem.canonForm.canon (g • akem.kem.basePoint))
            = akem.kem.keyDerive
                (akem.kem.canonForm.canon akem.kem.basePoint) :=
              keyDerive_canon_eq_of_mem_orbit akem hgc
          _ = akem.kem.keyDerive (akem.kem.canonForm.canon c) :=
              (keyDerive_canon_eq_of_mem_orbit akem hOrbit).symm
      -- Goal: t = mac.tag (keyDerive (canon (g • basePoint))) (g • basePoint)
      -- Rewriting with `hEqKey` and `hg` gives `t = mac.tag (keyDerive (canon c)) c`,
      -- which is exactly `htag`.
      rw [hEqKey, hg]
      exact htag

end INT_CTXT_Proof

end Orbcrypt
