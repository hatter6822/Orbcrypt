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
* `Orbcrypt.INT_CTXT` — ciphertext integrity: forgeries are always rejected
* `Orbcrypt.authEncrypt_is_int_ctxt` — INT_CTXT holds for every honestly
  composed `AuthOrbitKEM` with transitive ciphertext space (audit F-07,
  Workstream C2)

## Composition order

Encrypt-then-MAC (EtM) is the provably secure composition paradigm. The
alternatives (MAC-then-Encrypt, Encrypt-and-MAC) have known vulnerabilities
in certain settings.

## References

* docs/planning/PHASE_10_AUTHENTICATED_ENCRYPTION.md — work units 10.2–10.4
* docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md § 6 — Workstream C (F-07)
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

No adversary can produce a valid (ciphertext, tag) pair that was not generated
by an honest encapsulation. Formally: if `(c, t)` does not match any honest
`authEncaps` output, then `authDecaps` rejects it (returns `none`).

**Design rationale:**
- **Single-encapsulation setting.** The adversary must forge without having
  seen any honest encapsulation that matches. This is existential unforgeability.
- **Universal quantifier over `G`.** The condition `∀ g, c ≠ ... ∨ t ≠ ...`
  says no group element produces a matching (ciphertext, tag) pair.
- **`= none` conclusion.** The forgery is rejected — decapsulation refuses
  to release a key for an unauthenticated ciphertext.

**Scope:** This captures integrity in the no-query setting. Multi-query
CCA extensions (with encapsulation/decapsulation oracles and query logs)
are future work (Phase 12+).
-/
def INT_CTXT (akem : AuthOrbitKEM G X K Tag) : Prop :=
  ∀ (c : X) (t : Tag),
    (∀ g : G, c ≠ (authEncaps akem g).1 ∨
              t ≠ (authEncaps akem g).2.2) →
    authDecaps akem c t = none

-- ============================================================================
-- Workstream C (audit F-07): INT_CTXT proof for honestly-composed AuthOrbitKEMs
-- ============================================================================
--
-- The definition of `INT_CTXT` above is an unconditional Prop; without a
-- structural uniqueness property on the MAC it cannot be discharged.
-- Workstream C1 added `MAC.verify_inj` (tag uniqueness / SUF-CMA in the
-- information-theoretic sense). Workstream C2 now produces the first
-- concrete proof, decomposed as:
--
-- * C2a — `authDecaps_none_of_verify_false`: the easy `verify = false`
--   branch (unfold + rfl).
-- * C2b — `keyDerive_canon_eq_of_mem_orbit`: keys depend only on the
--   orbit of the ciphertext (unconditional, discharged via
--   `canon_eq_of_mem_orbit` / `canonical_isGInvariant`).
-- * C2c — `authEncrypt_is_int_ctxt`: stitches (a) and (b) together, using
--   the explicit hypothesis `hOrbitCover` that the ciphertext space equals
--   a single orbit of the base point (the intended model; see the risk
--   note in `docs/planning/AUDIT_2026-04-18_WORKSTREAM_PLAN.md` § 6.C2c).

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

    Every `AuthOrbitKEM` whose ciphertext space is a single orbit of the
    base point satisfies `INT_CTXT`. "Single orbit" is captured by the
    explicit hypothesis
    `hOrbitCover : ∀ c : X, c ∈ MulAction.orbit G akem.kem.basePoint`;
    this matches the intended security model (the ciphertext space equals
    `orbit G basePoint`, DEVELOPMENT.md §7) and makes the proof unconditional
    on any additional cryptographic assumption.

    **Proof sketch (audit F-07, Workstream C2c).**
    Let `k := keyDerive (canon c)` be the decapsulation key. Case-split on
    `akem.mac.verify k c t`:

    * `false`: `authDecaps` returns `none` directly (C2a).
    * `true`: by `MAC.verify_inj` (Workstream C1), `t = tag k c`. By
      `hOrbitCover`, some `g : G` witnesses `c = g • basePoint`. Then
      `(authEncaps akem g).1 = c` and, via C2b,
      `(authEncaps akem g).2.2 = tag k c = t` — a contradiction with
      `hFresh g`.

    **Axioms.** Only standard Lean (`propext`, `Classical.choice`,
    `Quot.sound`). No custom axiom, no `sorry`. -/
theorem authEncrypt_is_int_ctxt (akem : AuthOrbitKEM G X K Tag)
    (hOrbitCover : ∀ c : X, c ∈ MulAction.orbit G akem.kem.basePoint) :
    INT_CTXT akem := by
  intro c t hFresh
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
    -- `hOrbitCover` witnesses a `g` with `g • basePoint = c`.
    obtain ⟨g, hg⟩ := MulAction.mem_orbit_iff.mp (hOrbitCover c)
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
              (keyDerive_canon_eq_of_mem_orbit akem (hOrbitCover c)).symm
      -- Goal: t = mac.tag (keyDerive (canon (g • basePoint))) (g • basePoint)
      -- Rewriting with `hEqKey` and `hg` gives `t = mac.tag (keyDerive (canon c)) c`,
      -- which is exactly `htag`.
      rw [hEqKey, hg]
      exact htag

end INT_CTXT_Proof

end Orbcrypt
