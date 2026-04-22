# Public-Key Extension — Feasibility Analysis

**Phase 13 deliverable** — last updated 2026-04-17.

This document synthesises the algebraic scaffolding introduced in
`Orbcrypt/PublicKey/{ObliviousSampling, KEMAgreement, CommutativeAction,
CombineImpossibility}.lean` and answers the question: *how close can
Orbcrypt come to a public-key primitive, and what are the fundamental
obstacles?*

The three tracks explored in Phase 13 correspond to three candidate paths:

1. **Oblivious orbit sampling** — server publishes a bundle of orbit samples;
   senders combine them to produce fresh ciphertexts. An accompanying
   **no-go theorem** (`Orbcrypt/PublicKey/CombineImpossibility.lean`,
   added 2026-04-17) converts the open-combiner question into a
   machine-checked impossibility result under the natural diagonal
   `G`-equivariance hypothesis.
2. **KEM-based key agreement** — each party runs an Orbcrypt KEM and mixes
   the keys.
3. **Commutative group action (CSIDH-style)** — Diffie–Hellman in a
   commutative group action.

Each section states the construction, summarises the machine-checked formal
content, identifies the cryptographic assumption required, and gives a clear
feasibility assessment (Viable / Bounded-use / Open / Infeasible).

---

## 1. Oblivious Orbit Sampling

**Formalised in:** `Orbcrypt/PublicKey/ObliviousSampling.lean`

### Construction

The key holder publishes a bundle `OrbitalRandomizers G X t`:

* `basePoint : X` — the root of the orbit.
* `randomizers : Fin t → X` — `t` points in `orbit G basePoint`.
* `in_orbit` — proof that every randomizer really lies in that orbit.

A sender who does **not** know `G` can then compute fresh orbit elements via
a public combiner `combine : X → X → X`:

```
obliviousSample ors combine hClosed i j = combine (ors.randomizers i) (ors.randomizers j)
```

The `hClosed : ∀ x y, x ∈ orbit ∧ y ∈ orbit → combine x y ∈ orbit` hypothesis
is the *cryptographic crux*. Given such a `combine`, the theorem
`oblivious_sample_in_orbit` (a direct application of `hClosed`) certifies
that the output is a bona fide orbit element — i.e. a valid ciphertext.

### Formal content (what we machine-check)

* `OrbitalRandomizers`, `obliviousSample` — definitions.
* `oblivious_sample_in_orbit` — unconditional theorem given `hClosed`.
* `ObliviousSamplingHiding` — the *sender-privacy* requirement as a `Prop`.
* `oblivious_sampling_view_constant` — immediate corollary: if
  `ObliviousSamplingHiding` holds, any Boolean view of the sample is
  invariant under the sender's index choice.
* `refreshRandomizers`, `refreshRandomizers_in_orbit` — epoch-indexed fresh
  bundles with orbit certificates.
* `refresh_depends_only_on_epoch_range` — structural determinism: the
  refreshed output on an epoch depends only on the sampler's outputs at
  that epoch's index range. (Renamed from `refresh_independent` in
  Workstream L3, audit F-AUDIT-2026-04-21-M4; the theorem is structural,
  not a cryptographic independence claim.)

All proofs go through with zero `sorry` and standard Lean axioms only.

### Open problem (historical framing)

Finding a `combine : X → X → X` that **simultaneously**

* preserves orbit membership, and
* does not leak `G`

is the *cryptographic obstacle*. Two natural candidates fail:

1. **XOR on bitstrings.** For `X = Bitstring n` with the S_n action, XOR is
   orbit-preserving only when the group contains no non-trivial weight
   classes. For the concrete HGOE construction, XOR changes Hamming weight
   and therefore leaves the orbit.
2. **Permutation composition.** If `combine (g₁ • x) (g₂ • y) = (g₁ g₂) • y`
   (or similar), the sender must already know `g₁` and `g₂` — which is the
   exact secret we are trying to hide.

### No-go theorem under equivariance

**Formalised in:** `Orbcrypt/PublicKey/CombineImpossibility.lean`
(added 2026-04-17).

The "open problem" above has been substantially tightened. Any candidate
combiner that satisfies the natural **diagonal `G`-equivariance** property

```
combine (g • x) (g • y) = g • combine x y
```

— which is what makes the sender's output distribution independent of
which orbit representative they happen to see — **cannot actually mix its
second argument on the basepoint orbit** without refuting the
deterministic `OIA`. Formally, the file introduces a bundled

```lean
structure GEquivariantCombiner (G X : Type*) [Group G] [MulAction G X]
    (basePoint : X) where
  combine     : X → X → X
  closed      : ∀ x y, x ∈ orbit G basePoint → y ∈ orbit G basePoint →
                  combine x y ∈ orbit G basePoint
  equivariant : ∀ g x y, combine (g • x) (g • y) = g • combine x y
```

and proves the headline no-go **`equivariant_combiner_breaks_oia`**:

```lean
theorem equivariant_combiner_breaks_oia
    (scheme : OrbitEncScheme G X M) (m_bp : M)
    (combiner : GEquivariantCombiner G X (scheme.reps m_bp))
    (hND : NonDegenerateCombiner combiner) :
    ¬ OIA scheme
```

where `NonDegenerateCombiner combiner` merely asserts
`∃ g, combine bp (g • bp) ≠ combine bp bp` — the *minimal* "actually
mixes" property. The contrapositives

* `oia_forces_combine_constant_in_snd` — under `OIA`, for every `g : G`,
  `combine bp (g • bp) = combine bp bp`;
* `oia_forces_combine_constant_on_orbit` — same statement for arbitrary
  `y ∈ orbit G bp` (not only those presented as `g • bp`);

show that any `OIA`-respecting equivariant combiner is constant in its
second argument on the basepoint orbit. The bridge theorem
**`oblivious_sample_equivariant_obstruction`** then promotes this
into a statement about `obliviousSample`: with an equivariant `combine`,
the second sender index contributes nothing to the output. A *fresh*
ciphertext is impossible by this route.

A further structural lemma, **`combine_section_form`**, records that
equivariance already collapses the functional degrees of freedom of
`combine` on `orbit G basePoint × orbit G basePoint` to the single
section `y ↦ combine basePoint y`:

```lean
combine (g • bp) (h • bp) = g • combine bp ((g⁻¹ * h) • bp)
```

This is the *algebraic reason* the no-go holds: once equivariance forces
combine to be determined by a section, the non-degenerate section
immediately yields a within-orbit Boolean distinguisher, which the
deterministic `OIA` forbids.

**What remains open.** The result is stated against the deterministic
`OIA`. The same structural obstruction is expected to translate to the
probabilistic `ConcreteOIA` / `CompOIA` setting (Phase 8) with a
quantitative loss; that quantitative refinement is deferred to future
work. Combiners that *violate* equivariance (i.e., that behave
differently on orbit-congruent input pairs) are outside the scope of
this theorem — but they also violate the basic symmetry that makes the
sender's output distribution well-defined, so they are of limited
cryptographic interest.

Quotient-space constructions (e.g., working in `X / orbit G basePoint`)
do not evade this obstruction either. Any such construction falls into
one of four cases:

1. **Indicator quotient** (collapse every non-orbit element to a single
   class): the quotient map itself is the `OIA` oracle, so publicly
   computing it already refutes `OIA`.
2. **Orbit-space quotient** `X / G`: the target orbit collapses to a
   single point; lifting back to a concrete `X`-element requires a
   section, which is precisely `CanonicalForm.canon` — the scheme's
   secret.
3. **Public-subgroup quotient** `X / H` for `H ≤ G` or `H ⊇ G`: the
   former leaks partial structure of `G`; the latter (e.g. Hamming-weight
   classes for `S_n`) is too coarse to pin down the `G`-orbit and
   `combine` can slip between `G`-orbits within the same `H`-class.
4. **Torsor quotient** (`O` as a torsor for `G / Stab`, when the
   stabiliser is normal): non-trivial only when `G / Stab` is a
   commutative *and* publicly computable group, which is exactly the
   CSIDH-style instantiation in §3. For generic non-commutative
   `G ≤ S_n`, no torsor structure is publicly available.

In all four cases the quotient either exposes the structure that `OIA`
is meant to hide, or reduces to §3. No new path is opened.

### Feasibility

**Infeasible under equivariance.** The formalisation now machine-checks
that no `G`-equivariant orbit-closed combiner can be non-degenerate for
any scheme that satisfies the deterministic `OIA`. The only way to
retain the bounded-use oblivious-sampling flow is to relax the
equivariance hypothesis — but then the combiner's output distribution
becomes non-uniform in a way that itself leaks information about `G`,
and a quantitative analysis (against `ConcreteOIA`) is required. No
such combiner is known.

| Property | Status |
|----------|--------|
| Algebraic framework formalised | ✅ |
| Orbit-membership theorem | ✅ (`oblivious_sample_in_orbit`) |
| Refresh protocol formalised | ✅ |
| Structural refresh-determinism | ✅ (`refresh_depends_only_on_epoch_range`) |
| No-go for equivariant non-degenerate combiners | ✅ (`equivariant_combiner_breaks_oia`) |
| OIA forces equivariant combiners to be constant in `snd` | ✅ (`oia_forces_combine_constant_on_orbit`) |
| Collapse of the `obliviousSample` sender flow | ✅ (`oblivious_sample_equivariant_obstruction`) |
| Concrete orbit-preserving, G-hiding `combine` (equivariant) | ❌ Infeasible under `OIA` |
| Concrete orbit-preserving, G-hiding `combine` (non-equivariant) | ❓ Open — probabilistic analysis required |
| Cryptographic sender privacy (`ObliviousSamplingHiding`) | ⚠️ Conditional |

---

## 2. KEM-Based Key Agreement

**Formalised in:** `Orbcrypt/PublicKey/KEMAgreement.lean`

### Construction

Each party runs their own Orbcrypt KEM:

* Alice holds `kem_A : OrbitKEM G_A X K`.
* Bob holds `kem_B : OrbitKEM G_B X K`.
* Both know a public `combiner : K → K → K` (e.g. `SHAKE256(k_A ‖ k_B)`).

Session-key derivation:

```
sessionKey agr a b = agr.combiner (encaps agr.kem_A a).2 (encaps agr.kem_B b).2
```

The session key is a function of two per-party KEM keys. Each
`(encaps kem g).2` unfolds to `kem.keyDerive (kem.canonForm.canon (g • kem.basePoint))`
— i.e. an evaluation that requires the KEM's private `keyDerive` and
`canonForm.canon` fields. So computing `sessionKey a b` requires access
to **both** KEMs' secret state. The `kem_agreement_correctness`
theorem establishes that the two obvious "views" of this computation
(starting from either party's ciphertext, applying `decaps` on the
appropriate KEM to recover the other KEM key, and then combining)
agree.

### Formal content

* `OrbitKeyAgreement` — the two-KEM structure.
* `encapsA` / `encapsB` / `sessionKey` — functional API.
* `kem_agreement_correctness` — bi-view identity asserting that
  *both* decapsulation paths (Bob decaps Alice's ciphertext; Alice decaps
  Bob's) reduce to `sessionKey a b`. After Workstream A5 (2026-04-18
  audit, finding F-19), the theorem carries genuine content — previously
  it was a literal tautology whose proof reduced both sides to the same
  term. The new conjunction ties each view to the canonical `sessionKey`,
  and is proved by pairing `kem_agreement_bob_view` with
  `kem_agreement_alice_view`.
* `kem_agreement_alice_view`, `kem_agreement_bob_view` — each party's
  post-decapsulation view equals `sessionKey`.
* `SessionKeyExpansionIdentity` (Prop) + `sessionKey_expands_to_canon_form`
  — an **unconditional structural identity** making explicit that
  `sessionKey a b` factorises as
  `combiner (kem_A.keyDerive (canon (a • bp_A))) (kem_B.keyDerive (canon (b • bp_B)))`.
  Both `keyDerive` and `canonForm.canon` are private fields of the
  respective KEMs, so the formula references *both parties'* secret
  state — the machine-checked handle on the "symmetric setup" limitation.
  (Renamed from `SymmetricKeyAgreementLimitation` /
  `symmetric_key_agreement_limitation` in Workstream L4, audit
  F-AUDIT-2026-04-21-M5; the content is a decomposition identity,
  not an impossibility proof.)

Correctness follows directly from `kem_correctness` applied to each KEM.

### Fundamental limitation

**Neither party can use just a public group element.** Both participants
need the full `OrbitKEM` structure (including the secret group, the
canonical form, and `keyDerive`). Publishing only `basePoint` and a
ciphertext does not enable an arbitrary third party to re-derive the shared
key.

This is a genuine *symmetric-setup* protocol dressed as key agreement: we
end up with a session key because each party runs their own KEM, but the
initial distribution of `kem_A` and `kem_B` still requires an
out-of-band channel.

### Feasibility

**Works, but not public-key.** The protocol is a valid way to combine two
symmetric KEMs into a session key, and the correctness theorem guarantees
both parties agree. It does not solve the public-key problem: it *moves* the
hard step from encryption to setup.

| Property | Status |
|----------|--------|
| Two-party structure formalised | ✅ |
| Correctness (both views reduce to `sessionKey`) | ✅ (`kem_agreement_correctness`) |
| Public-key distribution | ❌ Setup is symmetric |
| Formal decomposition identity | ✅ (`SessionKeyExpansionIdentity`) |

---

## 3. Commutative Group Action (CSIDH-style)

**Formalised in:** `Orbcrypt/PublicKey/CommutativeAction.lean`

### Construction

Upgrade `MulAction G X` with a commutativity axiom:

```lean
class CommGroupAction (G X : Type*) [Group G] extends MulAction G X where
  comm : ∀ (g h : G) (x : X), g • (h • x) = h • (g • x)
```

With commutativity, Diffie–Hellman works directly:

```lean
csidh_exchange a b x₀ = (a • x₀, b • x₀, a • (b • x₀))
```

Alice publishes `a • x₀`, Bob publishes `b • x₀`, the shared secret is
`a • (b • x₀) = b • (a • x₀)`.

A public-key encryption wrapper `CommOrbitPKE` packages this:

```lean
structure CommOrbitPKE (G X : Type*) [Group G] [CommGroupAction G X] where
  basePoint : X
  secretKey : G
  publicKey : X
  pk_valid : publicKey = secretKey • basePoint
```

### Formal content

* `CommGroupAction` — the typeclass.
* `csidh_exchange`, `csidh_exchange_alice`, `csidh_exchange_bob`,
  `csidh_exchange_shared` — functional API + simp lemmas.
* `csidh_correctness` — the commutativity theorem (`a•b•x = b•a•x`).
* `csidh_views_agree` — both parties recover the same element.
* `CommOrbitPKE` — PKE structure.
* `CommOrbitPKE.encrypt` / `.decrypt` — functional API.
* `comm_pke_correctness` — unconditional correctness theorem.
* `comm_pke_shared_secret` — sender and recipient views match.
* `CommGroupAction.selfAction` — instance for `CommGroup G` acting on itself
  (sanity-check example).

All proofs compile with zero `sorry`; no custom axioms are introduced.

### Where the algebra ends and cryptography begins

The framework is sound — the only thing the formalisation needs to *assume*
is `CommGroupAction.comm`, and every concrete instance discharges that
obligation with an actual proof. The **missing piece is a concrete
commutative action with a CSIDH-like hardness assumption**, specifically:

* A commutative group `G`, with efficient sampling.
* A set `X` with an efficient action.
* Hardness of: *given `basePoint` and `publicKey = secretKey • basePoint`,
  recover `secretKey`*.

CSIDH (Castryck–Lange–Martindale–Panny–Renes, 2018) instantiates this with
the ideal class group of a supersingular elliptic curve. Formalising it in
Lean would require:

* Supersingular elliptic curves over `F_p`.
* Class group computations.
* The commutative action on the set of supersingular curves.

This is a substantial research effort beyond Orbcrypt's current scope, and
crucially it *leaves the S_n orbit setting*: the hardness comes from
isogenies, not from hidden permutation groups.

### Non-example: subgroups of S_n

Generic subgroups of `S_n` are **non-commutative**. Registering a
`CommGroupAction` instance for `Equiv.Perm (Fin n)` is provably impossible
for `n ≥ 3`: e.g., for `n = 3`, the 3-cycle and a transposition do not
commute, so their action on `Fin 3 → Bool` cannot satisfy
`g • h • x = h • g • x`.

This is the core observation behind the *fundamental obstacle*: the
non-commutativity that makes the hidden-group problem hard is exactly what
prevents Diffie–Hellman–style public-key construction.

### Feasibility

**Most promising path; requires substantial external machinery.** The
formal scaffolding is in place and minimal. The research challenge is
finding/instantiating a commutative action with good hardness — which
effectively means adopting (or adapting) CSIDH-like isogeny cryptography.

| Property | Status |
|----------|--------|
| `CommGroupAction` typeclass | ✅ |
| CSIDH correctness theorem | ✅ (`csidh_correctness`) |
| `CommOrbitPKE` structure + correctness | ✅ (`comm_pke_correctness`) |
| Self-action instance for `CommGroup` | ✅ |
| Concrete cryptographic instantiation | ❌ Requires CSIDH-like hardness |
| Symmetric `S_n` subgroups satisfy `CommGroupAction` | ❌ Generically not |

---

## 4. Fundamental Obstacle

The three tracks above converge on a single root cause:

> **The non-commutativity that makes `G ≤ S_n` hard to recover is exactly
> what prevents Diffie–Hellman-style public-key operations.**

Stated algebraically:

* Hardness (OIA / GI / CE): requires *rich* non-commutative structure so
  that recovering `G` from orbit samples is computationally infeasible.
* Public-key primitives (DH): require *commutative* structure so that the
  two parties' secret transformations can be applied in either order.

These requirements are nearly orthogonal: commutative subgroups of `S_n`
(e.g., cyclic subgroups) are too structured to support orbit
indistinguishability (the orbit is recoverable by elementary means), and
non-commutative groups resist both `G`-recovery *and* DH-style exchange.

The most plausible paths forward are therefore:

1. **Move to a commutative action with intrinsic hardness** (CSIDH, or a
   future commutative action with a well-understood hard problem). This
   effectively replaces the S_n orbit structure with an isogeny-graph
   structure.
2. **Hybridise:** keep Orbcrypt as the symmetric primitive and use a
   standard post-quantum KEM (Kyber, etc.) for public-key exchange, then
   derive the Orbcrypt secret from the KEM-derived shared secret. This is
   the most practical route and is already compatible with the AEAD layer
   in `Orbcrypt/AEAD/`.
3. **Accept the bounded-use public-key model** via oblivious sampling: the
   server refreshes randomizer bundles per epoch (`refreshRandomizers`),
   and senders combine randomizers via a future orbit-preserving,
   G-hiding combiner. The formal framework is in place for when such a
   combiner is discovered — but the no-go theorem in §1 rules out the
   entire *equivariant* sub-family under `OIA`, so any candidate must
   abandon diagonal equivariance and instead be analysed against the
   probabilistic `ConcreteOIA` / `CompOIA` with a quantitative bound.
   This is a strictly harder open problem than §1 originally admitted.

---

## 5. Summary Table

| Approach | Formal content | Cryptographic status | Verdict |
|----------|----------------|---------------------|---------|
| Oblivious sampling (§1) | `OrbitalRandomizers`, `obliviousSample`, `refreshRandomizers`, all correctness theorems | `combine` is an open problem | Bounded-use / Open (non-equivariant only) |
| No-go for equivariant combiners (§1) | `GEquivariantCombiner`, `equivariant_combiner_breaks_oia`, `oia_forces_combine_constant_on_orbit`, `oblivious_sample_equivariant_obstruction` | Equivariant `combine` ⇒ ¬ `OIA` (machine-checked) | Infeasible under `OIA` |
| KEM key agreement (§2) | `OrbitKeyAgreement`, `sessionKey`, `kem_agreement_correctness` | Requires symmetric keys on both sides | Works, NOT public-key |
| Commutative action (§3) | `CommGroupAction`, `csidh_exchange`, `CommOrbitPKE`, `comm_pke_correctness` | Needs CSIDH-like concrete instantiation | Most promising path |
| Fundamental obstacle (§4) | — | Non-commutativity is essential to hardness | Open research direction |

---

## 6. Machine-Checked Theorems Added in Phase 13

| Theorem | File | Axiom dependency |
|---------|------|------------------|
| `oblivious_sample_in_orbit` | `PublicKey/ObliviousSampling.lean` | Standard Lean only |
| `oblivious_sampling_view_constant` | `PublicKey/ObliviousSampling.lean` | Standard Lean (carries `ObliviousSamplingHiding` as hypothesis) |
| `obliviousSample_eq` (simp) | `PublicKey/ObliviousSampling.lean` | Standard Lean only |
| `refreshRandomizers_apply` (simp) | `PublicKey/ObliviousSampling.lean` | Standard Lean only |
| `refreshRandomizers_in_orbit` | `PublicKey/ObliviousSampling.lean` | Standard Lean only |
| `refreshRandomizers_orbitalRandomizers_basePoint` / `_randomizers` (simp) | `PublicKey/ObliviousSampling.lean` | Standard Lean only |
| `refresh_depends_only_on_epoch_range` | `PublicKey/ObliviousSampling.lean` | Standard Lean only |
| `kem_agreement_correctness` | `PublicKey/KEMAgreement.lean` | Inherits from `kem_correctness` (standard Lean only) |
| `kem_agreement_alice_view` / `..._bob_view` | `PublicKey/KEMAgreement.lean` | Standard Lean only |
| `sessionKey_expands_to_canon_form` | `PublicKey/KEMAgreement.lean` | Standard Lean only (structural identity unfolding `sessionKey` to combiner of `keyDerive ∘ canonForm.canon`) |
| `csidh_exchange_alice` / `csidh_exchange_bob` / `csidh_exchange_shared` (simp) | `PublicKey/CommutativeAction.lean` | Standard Lean only |
| `csidh_correctness` | `PublicKey/CommutativeAction.lean` | Standard Lean (extracts `CommGroupAction.comm` typeclass axiom) |
| `csidh_views_agree` | `PublicKey/CommutativeAction.lean` | Standard Lean only |
| `CommOrbitPKE.encrypt_shared` / `encrypt_ciphertext` / `decrypt_eq` (simp) | `PublicKey/CommutativeAction.lean` | Standard Lean only |
| `comm_pke_correctness` | `PublicKey/CommutativeAction.lean` | Standard Lean (extracts `CommGroupAction.comm` + uses `pk_valid`) |
| `comm_pke_shared_secret` | `PublicKey/CommutativeAction.lean` | Standard Lean only |
| `selfAction_comm` | `PublicKey/CommutativeAction.lean` | Standard Lean only (witnesses that `CommGroupAction` is satisfiable for any `CommGroup`) |
| `GEquivariantCombiner.combine_diagonal_smul` | `PublicKey/CombineImpossibility.lean` | None |
| `GEquivariantCombiner.combine_section_form` | `PublicKey/CombineImpossibility.lean` | `propext` only |
| `combinerDistinguisher_eq` (simp) | `PublicKey/CombineImpossibility.lean` | None |
| `combinerDistinguisher_basePoint` (simp) | `PublicKey/CombineImpossibility.lean` | None |
| `combinerDistinguisher_witness` | `PublicKey/CombineImpossibility.lean` | None |
| **`equivariant_combiner_breaks_oia`** | `PublicKey/CombineImpossibility.lean` | `propext` only (OIA is a hypothesis; theorem concludes `¬ OIA`) |
| `oia_forces_combine_constant_in_snd` | `PublicKey/CombineImpossibility.lean` | `propext` only (carries `OIA` as hypothesis) |
| `oia_forces_combine_constant_on_orbit` | `PublicKey/CombineImpossibility.lean` | `propext` only (carries `OIA` as hypothesis) |
| `oblivious_sample_equivariant_obstruction` | `PublicKey/CombineImpossibility.lean` | `propext` only (carries `OIA` as hypothesis) |

Every Phase 13 theorem either (i) carries its cryptographic assumption
as an explicit `Prop`-typed hypothesis (`ObliviousSamplingHiding`,
`OIA`), (ii) extracts a typeclass axiom (`CommGroupAction.comm` via the
`CommGroupAction` class extending `MulAction`), or (iii) is an
unconditional structural identity (`symmetric_key_agreement_limitation`,
`refresh_independent`, `combine_diagonal_smul`). There are **no Lean
`axiom` declarations** in the Phase 13 surface.

---

## 7. References

* `docs/planning/PHASE_13_PUBLIC_KEY_EXTENSION.md` — phase document.
* `formalization/PRACTICAL_IMPROVEMENTS_PLAN.md` — overall roadmap.
* `Orbcrypt/PublicKey/ObliviousSampling.lean`,
  `Orbcrypt/PublicKey/KEMAgreement.lean`,
  `Orbcrypt/PublicKey/CommutativeAction.lean`,
  `Orbcrypt/PublicKey/CombineImpossibility.lean` — formal content.
* Castryck, Lange, Martindale, Panny, Renes — *CSIDH: An Efficient
  Post-Quantum Commutative Group Action* (ASIACRYPT 2018).
* Babai — *Graph Isomorphism in Quasipolynomial Time* (STOC 2016).
