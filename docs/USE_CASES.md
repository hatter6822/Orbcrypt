# Novel Use Cases for Orbcrypt

**Status:** exploratory design notes — last updated 2026-04-18.

This document catalogues application designs that genuinely exploit
Orbcrypt's distinctive primitives rather than treating it as a drop-in
replacement for AES or Kyber. Each sketch identifies (a) the concrete
Orbcrypt primitive it leans on, (b) why competing primitives are a poor
fit, and (c) how it aligns with the existing Lean 4 formalization — in
particular which Phase-13 limitations bite.

Readers unfamiliar with the scheme should first skim `POE.md` (concept),
`DEVELOPMENT.md` §§4–6 (specification), and `docs/PUBLIC_KEY_ANALYSIS.md`
(public-key feasibility). The Lean theorem numbers referenced here match
`CLAUDE.md`'s theorem registry.

---

## 0. The four primitives that make these designs work

Orbcrypt is a small set of operations, but three of them are unusual
enough to enable applications that are awkward with AEAD or lattice KEMs:

| Primitive | Signature | What makes it unusual |
|-----------|-----------|-----------------------|
| **Orbit sampling** | `encaps : G → X × K` | Ciphertext is a *uniformly random element* of a message's orbit; any orbit member is an equally valid ciphertext. |
| **Canonical form** | `canon : X → X` | Deterministic fingerprint of an orbit. Two ciphertexts carry the same meaning iff their canonical forms match. Computable by anyone who knows `G`. |
| **Owner re-randomization** | `g • c` for any `g ∈ G` | The key holder can freshen a ciphertext trivially; this is a group action, not a new encryption. |
| **Invariant-freedom** | (no efficient `f` constant on orbits) | The OIA assumption — without `G`, no public function separates orbits. |

Three observations drive the designs below:

1. `canon` is a post-quantum *commitment* with unique openings: binding
   comes from idempotence (`canon_idem`), hiding from OIA.
2. Owner re-randomization converts "send the same message twice" from a
   correlation leak into a structural non-event — every resend looks
   independent to observers.
3. There is a **public-verifier / private-structurer asymmetry**: holders
   of `G` see a partition of the universe; non-holders see uniform noise.
   Many blockchain/social designs need exactly this split.

A caveat from Phase 13: *no efficient combiner is known that lets a
non-holder randomize ciphertexts* (`CombineImpossibility.lean`). So
designs that need public re-randomization must either (i) use the
commutative CSIDH-style variant, or (ii) route randomization through an
authorized party. We flag this explicitly in each sketch.

---

## 1. Cryptocurrency

### 1.1 Orbit stealth addresses (post-quantum CryptoNote)

**Construction.** A recipient publishes `(basePoint bp, keyDerive)`
derived from their private `G`. A sender who wants to pay them samples
`g` from a *public subgroup specification* (see §1.4 below — this is the
live open problem) and posts `c = g • bp` on-chain as the output's
commitment. The recipient, scanning the chain, canonicalizes every new
UTXO under their `G`: hits collapse to `canon(bp)`, misses do not.

**Why orbit-based wins.** CryptoNote's stealth addresses rest on ECDH and
break under a CRQC. Lattice-based stealth variants exist but require
each output to carry a full KEM ciphertext. An orbit output is a
*single group element* — on bitstring-HGOE that is `n` bits, matching
the size of the canonical form. Scanning cost is one `canon` call per
candidate, which is the same work the recipient already does to spend.

**Formalization handle.** `kem_correctness` (Theorem 4) plus
`encrypt_mem_orbit` and `canon_encrypt` (from `Correctness.lean`)
together guarantee that a correctly posted payment canonicalizes to the
recipient's advertised `canon(bp)`. Unlinkability is conditional on
`ConcreteOIA(ε)` (Theorem 6) for the bitstring action.

**Open.** Sender-side sampling without knowledge of `G` is exactly the
oblivious-sampling problem. In the symmetric setting this forces the
sender to hold `G` (shared-wallet model) or to rely on the CSIDH-style
variant (§1.3). A viable intermediate: the recipient issues a sender
an `OrbitalRandomizers` bundle signed with a one-time key, used for at
most `t` deposits before rotation — `refreshRandomizers` already models
this epoch discipline.

### 1.2 Orbit commitments with batched reveal (timelock primitive)

**Construction.** Post `c = g • m` where `m` encodes the committed data
and `g ∈ G` is fresh per commitment. The commitment opens when `G` (or
a threshold share of it) is published; canonicalization then yields
`canon(m)`, which is deterministic and thus binding. Before the reveal,
OIA makes `c` indistinguishable from any other orbit element.

**Why orbit-based wins.** Hash commitments need a per-commitment opener;
VDF/time-lock puzzles give only soft timing guarantees. An orbit
commitment gives *batch openability*: one `G` reveal simultaneously
opens every commitment made under it. For sealed-bid auctions, staged
DAO budget disclosure, and coordinated on-chain reveals this is
precisely the semantics wanted.

**Formalization handle.** Binding follows from `canon_eq_implies_orbit_eq`;
hiding from `concreteOIA_zero_implies_perfect` (perfect at ε=0) and
`concrete_oia_implies_1cpa` (computational at ε>0).

**Open.** Trust-minimizing the reveal authority — threshold-sharing `G`
over the permutation representation — is natural but not yet
formalized. Phase 13's `refresh_independent` is a partial step.

### 1.3 CSIDH-style atomic swaps on the commutative variant

**Construction.** Two chains each run `CommOrbitPKE` from
`Orbcrypt/PublicKey/CommutativeAction.lean` with a shared commutative
action `• : H × X → X`. Alice posts `a • x₀`, Bob posts `b • x₀`. Each
applies their secret to the other's post, arriving at
`a • b • x₀ = b • a • x₀` by `csidh_correctness` (Theorem 17). The
shared orbit element keys an HTLC-free atomic swap: the "hash preimage"
is replaced by "know `a` such that you produced `a • x₀`", which both
parties can verify by re-running the action.

**Why orbit-based wins.** HTLCs leak the preimage once claimed, linking
the two legs of a swap across chains. An orbit swap reveals only
`a • b • x₀`, structurally a fresh orbit element — no cross-chain
linkage beyond what the parties voluntarily expose. Post-quantum
security rides on the tensor-isomorphism reduction (Theorem 14).

**Formalization handle.** `csidh_correctness`, `csidh_views_agree`,
`comm_pke_correctness` are machine-checked. What's missing is a
concrete `CommGroupAction` with a plausible hardness assumption;
`docs/PUBLIC_KEY_ANALYSIS.md` §3 records the open instantiation.

### 1.4 Confidential asset tags with public equivalence

**Construction.** Each asset class is an orbit. A UTXO carries a random
orbit element of its class. Anyone holding `G` can canonicalize and
verify "these two UTXOs are the same asset"; without `G`, two UTXOs of
the same class look as unrelated as two UTXOs of different classes. A
regulator with `G` can aggregate class totals without learning
per-UTXO linkages — the sum of canonical forms is a public quantity
while individual histories remain private.

**Why orbit-based wins.** Confidential Transactions use Pedersen
commitments and Bulletproofs — effective but heavy on verifier cost
and discrete-log-broken under a CRQC. Orbit tags give class-equality
comparison at one `canon` call and inherit the GI/TI hardness
argument.

**Formalization handle.** `canon_eq_implies_orbit_eq` gives asset-class
equality; `invariant_const_on_orbit` guarantees class-aggregate
functions are well-defined on canonical representatives.

---

## 2. DAOs and on-chain governance

### 2.1 Glass-ballot voting: secrecy and verifiability in one phase

**Construction.** Each voting option `m ∈ {yes, no, abstain}` corresponds
to a message representative `reps m`. Members cast votes as
`c_i = g_i • reps m_i`, posting to the DAO contract; `g_i` is sampled
per-vote so repeat submissions are independent. At deadline the
governance key `G` — threshold-shared among a council or revealed on a
timelock — is published. Canonicalization of every `c_i` yields
`canon(reps m_i)`, which is one of three distinguished public values;
the tally is then a trivial public sum.

**Why orbit-based wins.** Current private-vote schemes either need
trusted mix servers, homomorphic encryption with expensive zero-
knowledge range proofs, or an interactive MPC. Orbit voting collapses
secrecy and verifiability into one key reveal: until the reveal, OIA
guarantees indistinguishability of ballots; after, tallying is a plain
equality check. No per-voter proof is needed because every valid ballot
is in *some* orbit, and wrong orbits collapse to non-option canonical
forms (rejected as spoiled).

**Formalization handle.** Correctness of tally = `canon_eq_of_mem_orbit`
(any ciphertext canonicalizes to its representative's canonical form);
privacy = `concrete_oia_implies_1cpa`. The three-option case reduces to
three pairwise IND-1-CPA instances with per-pair advantage ≤ ε; a
hybrid argument (`hybrid_argument` in `Probability/Advantage.lean`)
bounds the overall distinguishing advantage by `3ε`.

**Open.** Coercion resistance: a voter who later reveals their `g_i` can
prove how they voted. Standard remedies (receipt-freeness via
re-randomization by the ballot box) are exactly the "public combiner"
we lack — so orbit voting is currently fit for settings where
coercion is out of scope (small councils, salary committees, internal
forecasting markets) rather than general retail governance.

### 2.2 Anonymous members with revocable pseudonyms

**Construction.** The DAO's membership roster is the orbit of a base
point under a DAO-secret `G`. Each member receives an orbit element
`m_i = g_i • bp` as their credential. When a member posts an action,
they publish a fresh `h • m_i` (owner re-randomization — trivially
computable because the member is the owner of `g_i`). The contract,
which holds `G`, canonicalizes the action: all of a member's posts
collapse to the same canonical form, so "same user" is detectable, but
the specific identity behind a pseudonym is not revealed unless the
contract discloses `canon(g_i • bp) ↦ identity`. Revocation is the
partial reveal of the map for a single user.

**Why orbit-based wins.** Compared to BBS+ or anonymous credentials,
this avoids pairing-based machinery and makes the revocation primitive
a single public canonicalization rather than an accumulator proof.

**Formalization handle.** `canon_idem` and `canon_eq_of_mem_orbit`
establish pseudonym consistency; `invariant_const_on_orbit` ensures
any invariant the DAO cares about (e.g. reputation score) is a
well-defined function of the pseudonym.

### 2.3 Staged budget disclosure

**Construction.** A treasury proposal is a vector of allocations
`(a_1, … , a_k)`, encoded as an orbit element under a *proposal-
specific* subgroup `G_p`. The proposal is posted on-chain at proposal
time. At execution time the DAO reveals `G_p`; line items canonicalize
and the payments execute.

**Why orbit-based wins.** Commit-reveal with hashes forces each line
item to be opened individually (and leaks the opening order to
observers). An orbit commitment reveals the entire allocation vector
atomically — critical for avoiding front-running on large DAO
spending events and for removing "which line item paid first"
side-channels.

**Formalization handle.** Same as §1.2; the "vector of line items"
structure is just the ambient space `X` being a product of per-item
spaces, with `G_p` acting diagonally.

### 2.4 Orbit-structured delegation trees

**Construction.** Governance roles form a lattice: `Admin > Treasurer >
Spender > Reviewer`, say. Encode the lattice as a *chain of subgroups*
`G_Reviewer ≤ G_Spender ≤ G_Treasurer ≤ G_Admin`. A role's capability
is the ability to canonicalize under the corresponding subgroup. A
delegation from Admin to Treasurer hands over only `G_Treasurer`; the
delegate can now canonicalize Treasurer-scoped actions but not
Admin-scoped ones. Revocation means rotating the smaller subgroup.

**Why orbit-based wins.** Most capability schemes encode role hierarchy
as signed tokens, which cannot enforce "this action is Treasurer-
scoped" at the cryptographic layer — only at the verification layer.
Orbit-structured delegation moves the enforcement into the primitive
itself: canonicalization under the wrong subgroup yields a wrong
canonical form, and the action is rejected by construction.

**Formalization handle.** Subgroup actions are already formalized via
`MulAction.compHom` in `Construction/HGOE.lean`
(`subgroupBitstringAction`). A role lattice is a chain of such
actions; rotation of a smaller subgroup leaves outer canonical forms
unchanged, which is precisely what `canon_eq_of_mem_orbit` certifies.

---

## 3. Decentralized exchanges

### 3.1 MEV-resistant batch auctions via orbit-sealed orders

**Construction.** Traders submit orders `o = (side, price, size)` as
`c = g • reps o`. During the collection phase the exchange's sequencer
sees only orbit elements; OIA hides everything about the order. At
batch close, a threshold-held `G` is reconstructed (or a pre-committed
`G` is revealed); the sequencer canonicalizes every `c`, recovers the
`(side, price, size)` tuples, and clears the auction.

**Why orbit-based wins.** The central MEV-mitigation strategies today —
Flashbots / SUAVE, encrypted mempools (Shutter Network), Cowswap batch
auctions — all combine an encryption layer with a reveal authority.
Orbit sealing gives a cleaner guarantee at the primitive layer:
without `G`, orders are information-theoretically close to uniform;
with `G`, the sequencer receives *exactly* the plaintext tuple, not a
noisy decryption. Compared to threshold decryption of arbitrary
ciphertexts, orbit batch reveal is one canonicalization per order, not
one MPC decryption per order.

**Formalization handle.** `concreteOIA_zero_implies_perfect` certifies
that without the key the sequencer's view is orbit-distribution
only; `canon_encrypt` certifies post-reveal plaintext recovery. The
clearing algorithm itself is outside the formal model.

**Open.** Coercion by the sequencer (refusing to include a given
order) is orthogonal and standard cryptography cannot solve it —
orbit sealing does not change the picture.

### 3.2 Dark-pool orderbooks with canonical-form matching

**Construction.** An exchange operator holds `G`. Every resting order
is stored as a single orbit element. When a new order arrives, the
operator canonicalizes both and checks whether their canonical forms
*cross* — i.e. whether the buy's canonical form is ≥ the sell's
(a natural invariant once `reps` embeds orders as sorted tuples).
Matching proceeds on canonical forms; un-matched orders remain as
opaque orbit elements visible on-chain but unreadable by observers.

**Why orbit-based wins.** Dark-pool implementations either require the
operator to hold plaintext orders (a trust liability) or use FHE
(cost-prohibitive today). Orbit orderbooks give the operator the
*minimum* capability needed — canonicalization — without further
primitives. Other market participants, observers, and even other
exchanges running their own orbit pool see no structure.

**Formalization handle.** Order-price ordering on canonical forms is an
example of a `G_p`-invariant function — which is precisely what
`IsSeparating` forbids in the *outer* security argument. The design
insight is that the *operator's* ability to compute this invariant is
exactly their holding of `G_p`; an adversary without `G_p` cannot
compute it, which is OIA. `invariant_const_on_orbit` guarantees that
"same canonical form ⇒ same match result" is well-posed.

### 3.3 Unlinkable LP positions with owner-side rotation

**Construction.** An LP deposits into a pool; the pool contract issues
an orbit element `c = g • reps (positionParams)` as the LP token. The
LP rotates `c` at will by producing `h • c` (owner re-randomization).
Each rotation is a fresh on-chain token that settles exactly like the
previous one but cannot be linked to it by observers. Withdrawal
requires producing any orbit element whose canonical form matches the
pool's recorded `canon(reps p)`.

**Why orbit-based wins.** Uniswap v3 positions are publicly linkable by
position parameters; LPs cannot rotate identifiers without forgoing
fee accrual. Orbit-token rotation is free and does not touch the
position's fee state — the pool sees only `canon`, which is invariant
under the rotation.

**Formalization handle.** Trivially from `orbit_eq_of_smul` and
`canon_eq_of_mem_orbit`: rotation stays in the same orbit and
canonicalizes to the same value.

### 3.4 CSIDH-style swap routing

Chaining §1.3 into a DEX: a router contract composes several
`CommOrbitPKE` instances to produce multi-hop swaps where each hop's
intermediate orbit element carries no routing metadata beyond what the
receiving hop can canonicalize. Useful for privacy-preserving
Thorchain-like designs; gated on the same open instantiation problem
in `docs/PUBLIC_KEY_ANALYSIS.md` §3.

---

## 4. Social networks

### 4.1 Orbit-follow graphs

**Construction.** Each user `u` has a secret group `G_u`. Their public
profile advertises `canon_u(bp_u)`. To express "I follow v", user `u`
stores locally a pointer to `bp_v` under `G_v` that `v` has handed out.
When `u` requests `v`'s content, `u` submits a proof of possession —
an orbit element `h • bp_v` — which `v`'s node canonicalizes to
check membership. Revocation is removing one orbit element from `v`'s
list of authorized canonical forms; `G_v` does not need to change.

**Why orbit-based wins.** Current private-follow systems rely on
capability URLs (unguessable links) which are fragile, or on PKI which
exposes the social graph to any intermediary. Orbit follows give
*forward-private* links: once the server canonicalizes, it knows only
that someone authorized accessed the content, not who.

**Formalization handle.** The follow relation is the orbit of `bp_v`
under `G_v`; `canon_eq_of_mem_orbit` checks membership; an
adversarial server without `G_v` learns nothing by OIA.

### 4.2 Per-message orbit freshness (deniable messaging)

**Construction.** Alice and Bob share `G_{AB}`. To send, Alice picks a
fresh `g` and sends `c = g • m`. Bob canonicalizes under `G_{AB}` to
recover `canon(m)`, which is the agreed plaintext. An observer — or
a judge presented with `c` — cannot distinguish `c` from a random
orbit element of *any* orbit in the ambient space. Every `c` is
therefore deniable: Alice can assert any plaintext `m'` and claim `c`
was the corresponding encryption under some alternative `G_{AB}'`.

**Why orbit-based wins.** Signal's deniable deniability relies on MACs
constructed so that either party could have forged them. Orbit
messaging is *structurally* deniable because the ciphertext carries no
plaintext-specific information at all — it is a random point in the
ambient space. This matters for whistleblower channels, corporate
leak-proofing, and any setting where the mere existence of a
ciphertext-to-plaintext mapping is the liability.

**Formalization handle.** Deniability follows from `concreteOIA_zero_
implies_perfect` (perfect case) — the ciphertext distribution is
exactly the orbit distribution, regardless of plaintext.

### 4.3 Private recommendations via orbit proximity

**Construction.** Each user's preference vector is an orbit element
under a platform-wide `G` that encodes permutation symmetries of the
preference lattice (e.g. ranking invariances). The recommendation
service canonicalizes all vectors and clusters on canonical forms.
Users see recommendations based on their canonical cluster; the
service never sees raw preferences — only the class structure.

**Why orbit-based wins.** PSI-based recommendations reveal the
intersection; differential privacy adds noise that hurts utility.
Orbit canonicalization reveals *exactly* what the platform needs (the
class) and no more. The Lean-proved `canonical_isGInvariant` is the
formal statement that the canonical form leaks only orbit-level
information.

**Caveat.** The service must *not* compute any separating invariant of
`G`. If the service can run `hammingWeight` (or any other separating
function), `invariant_attack` (Theorem 2) gives advantage 1/2 and the
privacy collapses. This constrains the kinds of recommendation logic
permissible: clustering on `canon` is safe; clustering on any
non-invariant feature destroys the guarantee. Designers must state
explicitly which invariants the service may compute.

### 4.4 Group PSI via orbit intersection

**Construction.** Two groups each publish `canon_G1(bp_G1)` and
`canon_G2(bp_G2)` computed under their respective secret groups. A
third party, wanting to know whether the two groups have overlapping
membership, is given a set of orbit elements from each group. It
canonicalizes under each `G_i` in turn (if and only if it's been
delegated that capability) and computes set intersection on canonical
forms. Without both keys, the third party sees uniform noise; with
both, it learns only the overlap.

**Why orbit-based wins.** Standard PSI protocols require rounds of
interaction; orbit PSI is non-interactive given delegated
canonicalization capability. The capability can be time-boxed by
bundling it with an epoch-indexed `refreshRandomizers` — after the
epoch, the delegated canonicalizer is of no use.

**Formalization handle.** Intersection correctness is
`canon_eq_implies_orbit_eq`; the hiding property is dual OIA (holds
for each `G_i` independently).

---

## 5. Cross-cutting: orbit as an "equivalence label"

All the designs above reduce to a single abstract primitive: a
*private equivalence relation* with a public label. The relation is
"lies in the same orbit"; the label is `canon`. The design patterns
fall into three families:

1. **Commit → batch-open** (§§1.2, 2.1, 2.3, 3.1). Submitter posts
   orbit element; authority later reveals `G`; everything opens
   atomically.
2. **Owner re-randomize** (§§2.2, 3.3, 4.2). Key holder refreshes
   ciphertexts to obscure repetition, without any impact on semantic
   content.
3. **Canonicalize-as-query** (§§1.4, 3.2, 4.1, 4.3, 4.4). Key holder
   operates on canonical forms as if on plaintexts, exposing exactly
   the equivalence structure and nothing else.

This decomposition makes clear what the primitive does and does not
give. It gives *privacy by equivalence*: observers cannot distinguish
orbit elements. It does *not* give arbitrary homomorphic computation,
MPC, or non-interactive zero-knowledge over rich predicates — those
remain the province of FHE, MPC, and SNARKs respectively. The place
Orbcrypt earns its keep is where the needed functionality is exactly
"detect equivalence" or "rotate representation", and where
post-quantum hardness matters.

---

## 6. Alignment with the formalization, and what is still open

The table below maps each application to the theorems it rests on and
to the open problems that currently block a full deployment.

| Application | Rests on (theorem #) | Open problem |
|-------------|----------------------|--------------|
| 1.1 stealth addresses | 4, 6 | sender-side sampling without `G` |
| 1.2 batched commitments | `canon_idem`, 6, 7 | threshold share of `G` |
| 1.3 CSIDH swaps | 17, 18 | concrete `CommGroupAction` instance |
| 1.4 asset tags | 1, `canon_eq_implies_orbit_eq` | regulator trust model |
| 2.1 glass-ballot voting | `canon_eq_of_mem_orbit`, 6, hybrid arg | coercion resistance |
| 2.2 pseudonyms | `canon_idem`, `canon_eq_of_mem_orbit` | revocation accumulator |
| 2.3 staged budgets | same as 1.2 | threshold share of `G_p` |
| 2.4 delegation trees | `subgroupBitstringAction`, `canon_eq_of_mem_orbit` | subgroup rotation UX |
| 3.1 MEV-sealed auctions | `concreteOIA_zero_implies_perfect`, `canon_encrypt` | sequencer censorship |
| 3.2 dark pools | `invariant_const_on_orbit`, OIA | operator trust model |
| 3.3 LP rotation | `orbit_eq_of_smul`, `canon_eq_of_mem_orbit` | none — directly deployable |
| 3.4 swap routing | 17, 18 | same as 1.3 |
| 4.1 orbit follows | `canon_eq_of_mem_orbit`, OIA | graph-level metadata protection |
| 4.2 deniable messaging | `concreteOIA_zero_implies_perfect` | key-distribution out of scope |
| 4.3 private recs | `canonical_isGInvariant` | service must be invariant-free |
| 4.4 group PSI | `canon_eq_implies_orbit_eq` | delegated canonicalization model |

Three structural gaps recur:

* **Sender-side sampling without `G`.** The `combine` impossibility
  (Phase 13) is the hard bound. Progress depends on either (i)
  instantiating `CommGroupAction` concretely, making §§1.3, 3.4
  deployable and bypassing the impossibility, or (ii) introducing
  a signed-bundle ("randomizer certificate") protocol layer that
  pushes the trust to a rotating issuer, as hinted in `refreshRandomizers`.

* **Threshold-sharing `G`.** Several applications want to reveal `G`
  atomically under a distributed trigger. The natural approach is
  Shamir secret sharing over the permutation representation, but no
  Lean development addresses this yet. This is a concrete next-step
  work unit for a future phase.

* **Invariant hygiene.** Applications that let the service or
  contract compute *anything* about ciphertexts risk introducing a
  separating invariant and collapsing privacy by `invariant_attack`
  (Theorem 2). Design review must verify that every on-chain /
  server-side function factors through `canon`. A linter — a "taint
  tracker" from ciphertext to non-`canon` invocations — would
  substantially reduce this risk.

---

## 7. What not to use Orbcrypt for

For completeness, a few applications *not* to reach for:

* **General-purpose FHE replacement.** Orbcrypt does not give additive
  or multiplicative homomorphism; only the group action.
* **Signatures.** Canonical form gives equivalence but not
  authentication; pair with a standard post-quantum signature (e.g.
  the AEAD layer's MAC, instantiated with a PQ-secure MAC).
* **Key exchange between strangers without a trusted setup.** The
  symmetric-key limitation (`SymmetricKeyAgreementLimitation`) is a
  formal theorem in Phase 13, not a temporary gap.
* **Password-equivalent low-entropy secrets.** OIA is a
  computational assumption over a large orbit structure; encoding a
  6-digit PIN leaks it to brute-force canonicalization.

---

## 8. Summary

Orbcrypt's value to cryptocurrency, DAOs, DEXes, and social networks is
not "another encryption scheme" but three specific, composable
capabilities: *batch-openable commitments*, *free owner-side
re-randomization*, and *canonical-form-as-query*. The applications
that exploit one or more of these — stealth addresses, batched
sealed-bid auctions, MEV-resistant batch DEXes, orbit-follow social
graphs, deniable messaging, orbit-structured DAO delegation — give
post-quantum security from GI / tensor-isomorphism hardness, and in
several cases strictly better functionality than the existing
primitives. The open questions (sender-side sampling, threshold `G`,
invariant hygiene) are tractable next steps for Phases 14+.
