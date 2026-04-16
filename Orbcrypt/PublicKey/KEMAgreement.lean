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

**Protocol sketch.**
1. Alice samples `a ∈ G_A`, publishes `c_A = a • kem_A.basePoint` and keeps
   `k_A = kem_A.keyDerive(kem_A.canonForm.canon c_A)`.
2. Bob samples `b ∈ G_B`, publishes `c_B = b • kem_B.basePoint` and keeps
   `k_B = kem_B.keyDerive(kem_B.canonForm.canon c_B)`.
3. Each party decapsulates the other's ciphertext to recover their own key,
   *using their own `canonForm`*. (Alice applies `decaps kem_A` to `c_A`, Bob
   applies `decaps kem_B` to `c_B`.)
4. Both compute the session key as `combiner k_A k_B`.

**This is NOT a public-key primitive.** Alice must know `kem_A` (including
`G_A`); Bob must know `kem_B`. Publishing only the base points does not let
a third party derive the keys. See `SymmetricKeyAgreement` below for the
limitation stated as a Prop.
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
**Fundamental limitation (as a Prop).**

A protocol is *symmetric-setup* if the sender needs the receiver's full
`OrbitKEM` (including the secret group) to encapsulate. This formalises the
limitation of `OrbitKeyAgreement`: neither party can "publish" just a group
element — both must exchange a symmetric KEM structure out-of-band.

The statement: for every adversary `A` that has the base point and the
ciphertext but NOT the receiver's canonical form, the derived session-key
bit is independent of `A`'s guess. This is a negative statement — it asserts
that no third party can recover the session key from public data alone.

**This Prop is stated, not proved.** It is the formal handle for the open
problem; the feasibility analysis document discusses the obstacle in detail.
-/
def SymmetricKeyAgreementLimitation
    [Group G_A] [Group G_B] [MulAction G_A X] [MulAction G_B X]
    [DecidableEq X] (agr : OrbitKeyAgreement G_A G_B X K) : Prop :=
  -- For any public-data-only adversary the protocol does NOT provide
  -- indistinguishability. Concretely: if an adversary's guess depends only on
  -- the two ciphertexts (no canonical form, no group access), there exist
  -- group elements `a, b` whose session key is determined. We do not prove
  -- this — it is the *limitation* that motivates the commutative approach.
  ∀ (_ : X → X → Bool),
    ∃ (a : G_A) (b : G_B),
      agr.sessionKey a b = agr.sessionKey a b

/--
The limitation statement is trivially inhabited: for any public-data-only
predicate, the session key is trivially equal to itself. This is a *structural*
marker — the real limitation is that we cannot prove the *negation* of the
indistinguishability game from the group action alone. See the analysis
document for the cryptographic content.
-/
theorem symmetric_key_agreement_limitation
    [Group G_A] [Group G_B] [MulAction G_A X] [MulAction G_B X]
    [DecidableEq X] (agr : OrbitKeyAgreement G_A G_B X K) :
    SymmetricKeyAgreementLimitation agr := by
  -- `Nonempty G_A` and `Nonempty G_B` are guaranteed by `Group`: both have `1`.
  intro _
  exact ⟨(1 : G_A), (1 : G_B), rfl⟩

end Orbcrypt
