import Orbcrypt.GroupAction.Basic
import Orbcrypt.GroupAction.Canonical

/-!
# Orbcrypt.PublicKey.CommutativeAction

CSIDH-style commutative group actions as a candidate path to public-key
orbit encryption.

## Phase 13 — Work Units 13.5 and 13.6

* **13.5 — Commutative Group Action Framework.** The `CommGroupAction` class
  upgrades `MulAction` with the commutativity axiom
  `a • (b • x) = b • (a • x)`. With this, the CSIDH-style key exchange
  function `csidh_exchange a b x₀` becomes well-defined and the
  `csidh_correctness` theorem is immediate.
* **13.6 — Commutative Orbit Encryption.** The `CommOrbitPKE` structure
  packages a `basePoint`, secret key `secretKey : G`, and public key
  `publicKey = secretKey • basePoint`, with a validity field enforcing the
  relationship.

## Caveat

The abstract framework is sound, but *concrete* commutative actions with the
required hardness properties are the scarce resource:

* Subgroups of `S_n` are (generically) non-commutative — orbit indistinguish-
  ability on them cannot support Diffie–Hellman.
* CSIDH uses the ideal class group action on supersingular elliptic curves
  over `F_p`. This is commutative, but introduces its own hardness
  assumptions (the "commutative Supersingular Isogeny DH" problem) and sits
  outside the Mathlib coverage needed to formalise it here.
* Integer-action constructions (e.g., `(ℤ/nℤ) ↷ ℤ/nℤ`) are commutative but
  trivially solvable — discrete log in finite cyclic groups is not enough.

This module therefore provides the **algebraic scaffolding** for future
instantiations, with correctness statements that are unconditional on the
scaffolding itself. Hardness is deferred.

## References

* `docs/planning/PHASE_13_PUBLIC_KEY_EXTENSION.md` — phase document.
* `docs/PUBLIC_KEY_ANALYSIS.md` — feasibility analysis.
* Castryck, Lange, Martindale, Panny, Renes — *CSIDH: An Efficient
  Post-Quantum Commutative Group Action* (2018).
-/

namespace Orbcrypt

-- ============================================================================
-- Work Unit 13.5: Commutative Group Action Framework
-- ============================================================================

variable {G : Type*} {X : Type*}

/--
**Commutative group action.**

A group action `G ↷ X` is commutative if elements of `G` commute on `X`:
`a • (b • x) = b • (a • x)` for all `a, b ∈ G, x ∈ X`.

This extends Mathlib's `MulAction` with the `comm` field. For abelian groups
and the natural action on themselves this is automatic; for non-abelian `G`
(e.g., subgroups of `S_n`) it is generally *false*. The class is the
hypothesis underpinning CSIDH-style Diffie–Hellman.

**Design note.** We use `extends MulAction` so any existing `MulAction`
machinery (orbits, stabilizers, canonical forms) is available. The `comm`
field is a plain `Prop`-valued predicate; typeclass search never needs to
prove it, so instances must be registered explicitly when commutativity is
known.
-/
class CommGroupAction (G : Type*) (X : Type*) [Group G] extends MulAction G X where
  /-- Any two group elements commute on `X`. -/
  comm : ∀ (g h : G) (x : X), g • (h • x) = h • (g • x)

/--
**CSIDH-style key exchange (functional layer).**

Given a shared base point `x₀ : X` and two parties' secrets `a b : G`, the
function returns the triple
`(a • x₀, b • x₀, a • (b • x₀))`.

The first two coordinates are the *public* party transmissions (Alice's and
Bob's half-keys); the third is the shared secret from one party's view. By
`csidh_correctness`, the other party's view `b • (a • x₀)` equals the third
coordinate, so both parties agree on the shared secret.

**Why return the triple.** Returning the shared secret together with the
two half-keys keeps the API transparent: tests can assert that the first
two components depend only on their respective party's secret, and the third
is the common derivation that both parties can reproduce.
-/
def csidh_exchange [Group G] [CommGroupAction G X] (a b : G) (x₀ : X) :
    X × X × X :=
  (a • x₀, b • x₀, a • (b • x₀))

/--
Alice's half-key: `a • x₀` (first component of `csidh_exchange`).
-/
@[simp]
theorem csidh_exchange_alice [Group G] [CommGroupAction G X]
    (a b : G) (x₀ : X) :
    (csidh_exchange a b x₀).1 = a • x₀ := rfl

/--
Bob's half-key: `b • x₀` (second component of `csidh_exchange`).
-/
@[simp]
theorem csidh_exchange_bob [Group G] [CommGroupAction G X]
    (a b : G) (x₀ : X) :
    (csidh_exchange a b x₀).2.1 = b • x₀ := rfl

/--
Shared secret as computed by Alice: `a • (b • x₀)` (third component).
-/
@[simp]
theorem csidh_exchange_shared [Group G] [CommGroupAction G X]
    (a b : G) (x₀ : X) :
    (csidh_exchange a b x₀).2.2 = a • (b • x₀) := rfl

/--
**CSIDH correctness.** For commutative group actions, Alice's view
(`a • (b • x₀)`) and Bob's view (`b • (a • x₀)`) of the shared secret agree.

The proof is a direct application of `CommGroupAction.comm`.
-/
theorem csidh_correctness [Group G] [CommGroupAction G X] (a b : G) (x₀ : X) :
    a • (b • x₀) = b • (a • x₀) :=
  CommGroupAction.comm a b x₀

/--
**Both parties recover the same shared element.**

Alice, knowing `a` and having received Bob's public `b • x₀`, computes
`a • (b • x₀)`. Bob, knowing `b` and having received Alice's public
`a • x₀`, computes `b • (a • x₀)`. By `csidh_correctness` these agree.
-/
theorem csidh_views_agree [Group G] [CommGroupAction G X] (a b : G) (x₀ : X) :
    a • ((csidh_exchange a b x₀).2.1) = b • ((csidh_exchange a b x₀).1) := by
  -- a • (b • x₀) = b • (a • x₀)
  simp only [csidh_exchange_alice, csidh_exchange_bob]
  exact csidh_correctness a b x₀

-- ============================================================================
-- Work Unit 13.6: Commutative Orbit Encryption
-- ============================================================================

/--
**Commutative-action public-key encryption (structure).**

A `CommOrbitPKE G X` packages the minimal data for a CSIDH-style public-key
orbit encryption scheme:

* `basePoint : X` — a publicly known starting point of the orbit.
* `secretKey : G` — the private key; `G` must admit a commutative action
  on `X`.
* `publicKey : X` — the public key, which must equal `secretKey • basePoint`.
* `pk_valid` — a proof of the above equation, so that `publicKey` cannot be
  inhabited with anything other than `secretKey • basePoint`.

**How this supports encryption.** A sender with access to `basePoint` and
`publicKey` samples `r : G` and publishes `ciphertext := r • basePoint`. The
shared secret is `r • publicKey = r • (secretKey • basePoint)`; by
commutativity this also equals `secretKey • ciphertext`, which the recipient
can compute. See `comm_pke_shared_secret`.

**Hardness assumption.** Security relies on a CSIDH-like hypothesis: given
`basePoint` and `publicKey = secretKey • basePoint`, recovering `secretKey`
is infeasible. This module does NOT formalise that assumption; it only
provides the algebraic scaffolding.
-/
structure CommOrbitPKE (G : Type*) (X : Type*) [Group G] [CommGroupAction G X]
    where
  /-- Shared public starting point in `X`. -/
  basePoint : X
  /-- Private key — a group element of `G`. -/
  secretKey : G
  /-- Public key derived from `basePoint` and `secretKey`. -/
  publicKey : X
  /-- Validity constraint tying the public key to the secret. -/
  pk_valid : publicKey = secretKey • basePoint

/--
**Encryption (shared-secret derivation).**

Given a public key `publicKey = secretKey • basePoint` and a sender-chosen
`r : G`, the sender computes:

* `ciphertext := r • basePoint` (transmitted to the recipient).
* `shared_secret := r • publicKey = (r * secretKey) • basePoint`.

The recipient, holding `secretKey`, recovers the shared secret by computing
`secretKey • ciphertext`. Correctness follows from
`CommGroupAction.comm`.
-/
def CommOrbitPKE.encrypt [Group G] [CommGroupAction G X]
    (pke : CommOrbitPKE G X) (r : G) : X × X :=
  (r • pke.basePoint, r • pke.publicKey)

/--
Sender's derived shared secret is `r • publicKey`.
-/
@[simp]
theorem CommOrbitPKE.encrypt_shared [Group G] [CommGroupAction G X]
    (pke : CommOrbitPKE G X) (r : G) :
    (pke.encrypt r).2 = r • pke.publicKey := rfl

/--
Transmitted ciphertext is `r • basePoint`.
-/
@[simp]
theorem CommOrbitPKE.encrypt_ciphertext [Group G] [CommGroupAction G X]
    (pke : CommOrbitPKE G X) (r : G) :
    (pke.encrypt r).1 = r • pke.basePoint := rfl

/--
**Decryption.** The recipient applies the secret key to the received
ciphertext to recover the shared secret.
-/
def CommOrbitPKE.decrypt [Group G] [CommGroupAction G X]
    (pke : CommOrbitPKE G X) (ciphertext : X) : X :=
  pke.secretKey • ciphertext

/-- Unfold decryption. -/
@[simp]
theorem CommOrbitPKE.decrypt_eq [Group G] [CommGroupAction G X]
    (pke : CommOrbitPKE G X) (ciphertext : X) :
    pke.decrypt ciphertext = pke.secretKey • ciphertext := rfl

/--
**CSIDH-style correctness for commutative PKE.**

For any sender randomness `r : G`, sender and recipient derive the same
shared secret:

  `decrypt(encrypt(r).1) = encrypt(r).2`.

**Proof.**
```
  secretKey • (r • basePoint)   -- recipient's view
    = r • (secretKey • basePoint) -- by CommGroupAction.comm
    = r • publicKey               -- by pk_valid (rewritten backwards)
```

This parallels `Theorems.Correctness` (for the symmetric scheme) and
`KEM.Correctness` (for the KEM), but leverages commutativity instead of
orbit-invariance of a canonical form.
-/
theorem comm_pke_correctness [Group G] [CommGroupAction G X]
    (pke : CommOrbitPKE G X) (r : G) :
    pke.decrypt (pke.encrypt r).1 = (pke.encrypt r).2 := by
  -- Unfold both sides
  simp only [CommOrbitPKE.encrypt_ciphertext, CommOrbitPKE.encrypt_shared,
             CommOrbitPKE.decrypt_eq]
  -- secretKey • (r • basePoint) = r • (secretKey • basePoint) = r • publicKey
  rw [CommGroupAction.comm, ← pke.pk_valid]

/--
**Shared secret characterisation.** The sender's shared secret
`r • publicKey` equals the expression `(secretKey * …)` would produce, read
via commutativity. This is a convenience restatement of
`comm_pke_correctness`.
-/
theorem comm_pke_shared_secret [Group G] [CommGroupAction G X]
    (pke : CommOrbitPKE G X) (r : G) :
    r • pke.publicKey = pke.secretKey • (r • pke.basePoint) := by
  rw [pke.pk_valid, CommGroupAction.comm]

/--
**Abelian-group witness.** When `G` is commutative and acts on itself by
left multiplication, a `CommGroupAction G G` structure can be constructed
directly.

This is the canonical "toy" commutative group action: `G = X = ℤ/nℤ`, with
`g • x = g + x`. It is commutative (`a + (b + x) = b + (a + x)`) but the
underlying hardness (discrete log in finite cyclic groups) is too weak for
cryptographic use. We expose this as a plain `def` rather than an `instance`
so downstream consumers who instantiate `CommGroupAction` for a richer
action (e.g., CSIDH) are not forced to disambiguate from this default.
Callers wanting the self-action can use `CommGroupAction.selfAction` as
a local instance.
-/
@[reducible]
def CommGroupAction.selfAction {G : Type*} [CommGroup G] :
    CommGroupAction G G where
  comm a b x := by
    -- a • (b • x) = a * (b * x) = (a * b) * x = (b * a) * x = b * (a * x)
    show a * (b * x) = b * (a * x)
    rw [← mul_assoc, ← mul_assoc, mul_comm a b]

/--
**Self-action witness discharges the commutativity axiom.**

For any `CommGroup G`, the `selfAction` witness's `comm` field returns
a proof of `a * (b * x) = b * (a * x)` (the self-action equation read
through the `Mul.toSMul` instance). This shows that `CommGroupAction`
is satisfiable for every commutative group, and gives a concrete
computable witness for sanity-checking downstream constructions.

The statement is phrased directly in terms of multiplication rather
than `•` so it does not depend on how Lean resolves `SMul G G`: it
simply re-exports the commutativity-derivation used inside
`selfAction.comm`.
-/
theorem selfAction_comm {G : Type*} [CommGroup G] (a b x : G) :
    a * (b * x) = b * (a * x) := by
  rw [← mul_assoc, ← mul_assoc, mul_comm a b]

end Orbcrypt
