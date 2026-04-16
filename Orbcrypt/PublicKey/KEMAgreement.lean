import Orbcrypt.KEM.Encapsulate
import Orbcrypt.KEM.Correctness

/-!
# Orbcrypt.PublicKey.KEMAgreement

KEM-based key agreement for Orbcrypt: each party holds their own secret group
`G_A` / `G_B` acting on a shared ciphertext space `X`, and they combine two
independently-derived KEM keys (one per party) into a joint session key via a
commutative `combiner : K → K → K`.

## Phase 13 — Work Unit 13.4

Implements the two-party key agreement structure `OrbitKeyAgreement` and its
correctness theorem `kem_agreement_correctness`. Also states the fundamental
limitation as a Prop: both parties must already hold symmetric Orbcrypt keys,
so this protocol is NOT a true public-key primitive.

## Fundamental limitation

Both parties need secret groups `G_A` and `G_B`. Unlike Diffie–Hellman (where
each party publishes a single group element derived from a shared generator),
`OrbitKeyAgreement` is really two-way symmetric-key use: each participant
runs a KEM of their own and then mixes the resulting keys. The output has the
flavour of a *session key*, but the setup still distributes secrets
out-of-band.

The non-commutativity of the underlying permutation groups is the root cause:
CSIDH-style Diffie–Hellman requires the group action to commute
(`a • (b • x) = b • (a • x)`), which fails for subgroups of `S_n`. The
`CommutativeAction` module sketches an alternative that *does* commute — see
`Orbcrypt.PublicKey.CommutativeAction`.

## References

* `docs/planning/PHASE_13_PUBLIC_KEY_EXTENSION.md` — phase document.
* `docs/PUBLIC_KEY_ANALYSIS.md` — full feasibility analysis.
-/

namespace Orbcrypt

-- ============================================================================
-- Work Unit 13.4: KEM-Based Key Agreement
-- ============================================================================

variable {G_A G_B : Type*} {X K : Type*}

/--
**Two-party orbit-KEM key agreement.**

`OrbitKeyAgreement` packages:
* `kem_A`: Alice's KEM over her secret group `G_A`.
* `kem_B`: Bob's KEM over his secret group `G_B`.
* `combiner : K → K → K`: a deterministic key mixer (e.g., a hash such as
  `SHAKE256`, or simple XOR when `K = Bool^n`).

Both KEMs must share the **ciphertext space** `X` and the **key space** `K`,
but they may act on `X` via different groups and different canonical forms.

**Mathematical sketch.** The session key is the combiner applied to two
per-party KEM keys:

1. `k_A = (encaps kem_A a).2 = kem_A.keyDerive (canon_A (a • bp_A))`.
2. `k_B = (encaps kem_B b).2 = kem_B.keyDerive (canon_B (b • bp_B))`.
3. `sessionKey a b = combiner k_A k_B`.

Both `k_A` and `k_B` reference the respective KEM's *secret*
`keyDerive` and `canonForm.canon` maps. The
`kem_agreement_correctness` theorem exhibits the equivalent
"decapsulation-round-trip" view — replacing any single `k_x` with
`decaps kem_x (encaps kem_x _).1`, which equals `k_x` by
`kem_correctness` — showing that these views coincide.

**This is NOT a public-key primitive.** Computing `sessionKey a b`
requires access to *both* KEMs' secret state (`keyDerive` and
`canonForm.canon` fields). Publishing only the base points and
ciphertexts does not suffice — this is made formal by
`SymmetricKeyAgreementLimitation` below, which states and proves the
exact structural identity.
-/
structure OrbitKeyAgreement (G_A : Type*) (G_B : Type*) (X : Type*) (K : Type*)
    [Group G_A] [Group G_B] [MulAction G_A X] [MulAction G_B X]
    [DecidableEq X] where
  /-- Alice's KEM (over her secret group `G_A`). -/
  kem_A : OrbitKEM G_A X K
  /-- Bob's KEM (over his secret group `G_B`). -/
  kem_B : OrbitKEM G_B X K
  /-- Deterministic key combiner (e.g., a hash). -/
  combiner : K → K → K

/--
Alice's encapsulation step: sample her group element `a`, publish the
ciphertext, and remember the derived key `k_A`.
-/
def OrbitKeyAgreement.encapsA
    [Group G_A] [Group G_B] [MulAction G_A X] [MulAction G_B X]
    [DecidableEq X] (agr : OrbitKeyAgreement G_A G_B X K) (a : G_A) : X × K :=
  encaps agr.kem_A a

/-- Bob's encapsulation step (mirror of `encapsA`). -/
def OrbitKeyAgreement.encapsB
    [Group G_A] [Group G_B] [MulAction G_A X] [MulAction G_B X]
    [DecidableEq X] (agr : OrbitKeyAgreement G_A G_B X K) (b : G_B) : X × K :=
  encaps agr.kem_B b

/--
**Session key derivation.** Given Alice's `a : G_A` and Bob's `b : G_B`, both
parties produce the same session key by decapsulating the opposite party's
ciphertext with their own KEM and mixing.

In practice, Alice computes `combiner (encapsA a).2 (decaps kem_B (encapsB b).1)`
and Bob computes `combiner (decaps kem_A (encapsA a).1) (encapsB b).2`;
correctness (below) shows these agree.
-/
def OrbitKeyAgreement.sessionKey
    [Group G_A] [Group G_B] [MulAction G_A X] [MulAction G_B X]
    [DecidableEq X] (agr : OrbitKeyAgreement G_A G_B X K)
    (a : G_A) (b : G_B) : K :=
  agr.combiner (encaps agr.kem_A a).2 (encaps agr.kem_B b).2

/--
**KEM agreement correctness.**

Alice's and Bob's views of the session key agree: both parties, after
decapsulating their partner's ciphertext and mixing, obtain
`combiner k_A k_B`.

The proof is definitional: `decaps kem_A (encaps kem_A a).1 = (encaps kem_A a).2`
by `kem_correctness`, and symmetrically for Bob. The combiner is applied to
the same pair of keys in both views.
-/
theorem kem_agreement_correctness
    [Group G_A] [Group G_B] [MulAction G_A X] [MulAction G_B X]
    [DecidableEq X] (agr : OrbitKeyAgreement G_A G_B X K)
    (a : G_A) (b : G_B) :
    agr.combiner (decaps agr.kem_A (encaps agr.kem_A a).1)
                 (encaps agr.kem_B b).2 =
    agr.combiner (encaps agr.kem_A a).2
                 (decaps agr.kem_B (encaps agr.kem_B b).1) := by
  -- Rewrite both sides using KEM correctness on each party's own KEM.
  rw [kem_correctness agr.kem_A a, kem_correctness agr.kem_B b]

/--
**Bob's view equals the canonical session key.** After Bob decapsulates
Alice's ciphertext, mixing with his own `(encaps kem_B b).2` yields exactly
`sessionKey a b`.
-/
theorem kem_agreement_bob_view
    [Group G_A] [Group G_B] [MulAction G_A X] [MulAction G_B X]
    [DecidableEq X] (agr : OrbitKeyAgreement G_A G_B X K)
    (a : G_A) (b : G_B) :
    agr.combiner (decaps agr.kem_A (encaps agr.kem_A a).1)
                 (encaps agr.kem_B b).2 =
    agr.sessionKey a b := by
  -- `sessionKey a b = combiner (encaps kem_A a).2 (encaps kem_B b).2`, so
  -- rewriting the LHS via `kem_correctness` gives the same expression.
  show agr.combiner (decaps agr.kem_A (encaps agr.kem_A a).1)
                    (encaps agr.kem_B b).2 =
       agr.combiner (encaps agr.kem_A a).2 (encaps agr.kem_B b).2
  rw [kem_correctness agr.kem_A a]

/--
**Alice's view equals the canonical session key.**
-/
theorem kem_agreement_alice_view
    [Group G_A] [Group G_B] [MulAction G_A X] [MulAction G_B X]
    [DecidableEq X] (agr : OrbitKeyAgreement G_A G_B X K)
    (a : G_A) (b : G_B) :
    agr.combiner (encaps agr.kem_A a).2
                 (decaps agr.kem_B (encaps agr.kem_B b).1) =
    agr.sessionKey a b := by
  show agr.combiner (encaps agr.kem_A a).2
                    (decaps agr.kem_B (encaps agr.kem_B b).1) =
       agr.combiner (encaps agr.kem_A a).2 (encaps agr.kem_B b).2
  rw [kem_correctness agr.kem_B b]

/--
**Fundamental limitation (as a Prop): session-key computation requires both
parties' full KEM state.**

The session key is *not* a public-key–style derivation from the two parties'
ciphertexts. It decomposes as

  `sessionKey a b = combiner (k_A) (k_B)`

where `k_A = kem_A.keyDerive (kem_A.canonForm.canon (a • kem_A.basePoint))`
(and symmetrically for `k_B`). Computing either key requires the
corresponding KEM's `keyDerive` and `canonForm.canon` — both of which are
secret. Hence an adversary holding only the published base points and
ciphertexts cannot evaluate `sessionKey`.

This Prop exposes that decomposition as a universal equation. It is the
**structural** limitation that motivates the commutative path
(`Orbcrypt.PublicKey.CommutativeAction`), where the equivalent derivation
factors through a commutative action and only one party's secret is
needed to encapsulate.

**Why this is a limitation, not a security claim.** The Prop does not
assert hardness of anything — it asserts that the session-key formula
references secret state on both sides. The absence of a public-key
algorithm that avoids this dependency is what is documented (informally)
in `docs/PUBLIC_KEY_ANALYSIS.md`.
-/
def SymmetricKeyAgreementLimitation
    [Group G_A] [Group G_B] [MulAction G_A X] [MulAction G_B X]
    [DecidableEq X] (agr : OrbitKeyAgreement G_A G_B X K) : Prop :=
  ∀ (a : G_A) (b : G_B),
    agr.sessionKey a b =
      agr.combiner
        (agr.kem_A.keyDerive
          (agr.kem_A.canonForm.canon (a • agr.kem_A.basePoint)))
        (agr.kem_B.keyDerive
          (agr.kem_B.canonForm.canon (b • agr.kem_B.basePoint)))

/--
`SymmetricKeyAgreementLimitation` holds for every `OrbitKeyAgreement`: this
is a structural identity following from the definitions of `sessionKey` and
`encaps`. The identity exhibits both parties' canonical forms inside the
session-key formula, making explicit that the protocol cannot be used in a
public-key fashion.
-/
theorem symmetric_key_agreement_limitation
    [Group G_A] [Group G_B] [MulAction G_A X] [MulAction G_B X]
    [DecidableEq X] (agr : OrbitKeyAgreement G_A G_B X K) :
    SymmetricKeyAgreementLimitation agr := by
  intro a b
  -- Unfold `sessionKey`, then `encaps` on each side.
  show agr.combiner (encaps agr.kem_A a).2 (encaps agr.kem_B b).2 =
       agr.combiner
         (agr.kem_A.keyDerive
           (agr.kem_A.canonForm.canon (a • agr.kem_A.basePoint)))
         (agr.kem_B.keyDerive
           (agr.kem_B.canonForm.canon (b • agr.kem_B.basePoint)))
  rfl

end Orbcrypt
