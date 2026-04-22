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
| **Orbit sampling** | `encaps : G → X × K` (takes `g : G`) | Ciphertext is a uniformly random element of a message's orbit when `g` is sampled uniformly from `G`; any orbit member is an equally valid ciphertext. Sampling requires holding `G`. |
| **Canonical form** | `canon : X → X` | Deterministic fingerprint of an orbit. Two ciphertexts carry the same meaning iff their canonical forms match. Computable by anyone who knows `G`. |
| **`G`-holder re-randomization** | `g • c` for any `g ∈ G` | A `G`-holder can freshen a ciphertext trivially; this is a group action, not a new encryption. |
| **Bundle-mediated rotation** | `OrbitalRandomizers G X t` | A `G`-holder issues a non-holder a bounded-size list of orbit elements; the non-holder consumes these one at a time and requests refresh. The only way a non-`G`-holder gets multiple orbit elements in the symmetric scheme. |
| **Invariant-freedom** | (no efficient `f` separating different orbits) | The OIA assumption — without `G`, no efficient function separates messages. Non-*separating* invariants (e.g. Hamming weight on HGOE) may still be publicly computable and must be designed around. |

Three observations drive the designs below:

1. `canon` is a post-quantum *commitment* with unique openings on the
   ambient space: binding comes from idempotence (`canon_idem`), hiding
   comes from OIA and is conditional on the computational assumption.
2. A `G`-holder can refresh ciphertext representatives freely; a
   non-`G`-holder rotates only within a provisioned bundle of size
   `t`, after which a refresh is required.
3. There is a **key-holder / observer asymmetry**: holders of `G` see
   a partition of the ambient space; observers see
   OIA-indistinguishable ciphertexts (up to public non-separating
   invariants). Many blockchain / social designs need exactly this
   split.

Two caveats from Phase 13 recur throughout the sketches:

* **Public re-randomization is blocked.** `CombineImpossibility.lean`
  shows that no `G`-equivariant, orbit-closed, non-degenerate combiner
  exists under deterministic OIA. Designs that need fresh orbit
  elements from a non-`G`-holder must therefore either (i) use the
  commutative CSIDH-style variant (§1.3), or (ii) route randomization
  through a `G`-holder who issues signed `OrbitalRandomizers` bundles
  consumed one element at a time with `refreshRandomizers` rotation.
  A participant holding only *one* orbit element cannot mint fresh
  ones without one of these routes.
* **Sampling from `G` requires holding `G`.** `encaps g` takes
  `g : G` as input; sampling `g` uniformly requires knowing `G`'s
  structure. Anywhere a sketch says "party X presents a fresh orbit
  element", the sketch must specify how: via `G`-possession, a
  bundle, or a commutative action.

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
break under a CRQC. An orbit output is a single element of the ambient
space `X` — on bitstring-HGOE that is `n` bits (e.g. 344 bits at
λ=128 per `implementation/gap/orbcrypt_benchmarks.csv`), which is
substantially smaller than a lattice-KEM ciphertext (Kyber-768 is
≈8.7 kbit). On the scanner side, each candidate UTXO requires one
`canon` call.

**Formalization handle.** `kem_correctness` (Theorem 4) plus
`encrypt_mem_orbit` and `canon_encrypt` (from `Correctness.lean`)
together guarantee that a correctly posted payment canonicalizes to the
recipient's advertised `canon(bp)`. Unlinkability reduces to
`ConcreteOIA(ε)` via `concrete_oia_implies_1cpa` (Theorem 6) for the
bitstring action.

**Open — sender sampling.** Sender-side sampling without knowledge of
`G` is exactly the oblivious-sampling problem. `CombineImpossibility`
rules out public `G`-equivariant orbit-closed combiners under
deterministic OIA, so three workable routes remain: (i) the recipient
issues the sender a signed `OrbitalRandomizers` bundle, rotated via
`refreshRandomizers` every `t` deposits; (ii) the sender holds `G`
(shared-wallet model); (iii) move to the CSIDH-style variant (§1.3),
which sidesteps the impossibility because the commutative public
operation is itself the combiner.

**Open — scanning cost.** At the GAP reference parameters, one `canon`
call costs ≈172 ms (λ=80), ≈320 ms (λ=128), and ≈1.2 s (λ=256). That
makes the naive "scan every chain UTXO" pattern impractical at
anything approaching modern chain throughput. Viable deployments need
either (a) view tags that pre-filter candidates before running `canon`
(standard CryptoNote technique, applies here unchanged), (b) payment
indexing via a delegated canonicalizer, or (c) parameter reduction via
Phase 14's planned parameter-selection work.

### 1.2 Orbit commitments with batched reveal (timelock primitive)

**Construction.** Post `c = g • m` where `m` encodes the committed data
and `g ∈ G` is fresh per commitment. The commitment opens when `G` (or
a threshold share of it) is published; canonicalization then yields
`canon(m)`, which is deterministic and thus binding. Before the reveal,
OIA makes `c` indistinguishable from any other orbit element.

**Why orbit-based wins.** Hash commitments require a per-commitment
opener transmitted at reveal time; time-lock puzzles give only a soft
parallelism-dependent delay. An orbit commitment gives *batch
openability*: one `G` reveal simultaneously opens every commitment
made under it, with no per-commitment opening data. For sealed-bid
auctions, staged DAO budget disclosure, and coordinated on-chain
reveals this is precisely the semantics wanted. VDFs give strong
timing bounds but are a timing primitive, not a batch-opener — the
two are composable (VDF-gate the `G` reveal) rather than substitutes.

**Formalization handle.** Binding follows from `canon_eq_implies_orbit_eq`;
hiding from `concreteOIA_zero_implies_perfect` (perfect at ε=0) and
`concrete_oia_implies_1cpa` (computational at ε>0).

**Open.** Trust-minimizing the reveal authority — threshold-sharing `G`
over the permutation representation — is natural but not yet
formalized. Phase 13's `refresh_depends_only_on_epoch_range` is a partial step.

### 1.3 CSIDH-style pair-keys for post-quantum DH on-chain

**Construction.** Two parties, each with a secret `a`, `b : G`, use the
commutative action on a shared base point: Alice posts `a • x₀`, Bob
posts `b • x₀`, and each applies their own secret to the other's post,
arriving at `a • (b • x₀) = b • (a • x₀)` by `csidh_correctness`
(Theorem 17). The common orbit element is a post-quantum
Diffie–Hellman shared secret; `CommOrbitPKE` (Theorem 18) wraps this
into a KEM-style PKE interface.

**Why orbit-based wins.** Pre-quantum DH is broken by Shor; CSIDH is
an established small-key post-quantum replacement. Orbcrypt's
`CommGroupAction` is an *abstract* interface that admits CSIDH as its
canonical (but not sole) instantiation — any concrete commutative
action satisfying the hardness hypothesis can plug in.

**What this gives and does not give on-chain.** A shared orbit element
is *key agreement*, not *atomic-swap*. The natural blockchain uses are:
(i) deriving a per-pair session key for a private payment channel;
(ii) instantiating the "scalar secret" of an adaptor-signature-style
lock, where an on-chain spend reveals a scalar the counterparty needs
for the other chain. Claims that orbit key agreement by itself replaces
an HTLC are **not** correct: atomic-swap semantics require a further
construction (adaptor signatures, or a dual-locked smart contract that
verifies the algebraic relation). Orbit key agreement is the *DH
analogue*, not the *hashlock analogue*.

**Formalization handle.** `csidh_correctness`, `csidh_views_agree`,
`comm_pke_correctness` are machine-checked. The missing piece is a
concrete `CommGroupAction` with a plausible hardness assumption;
`docs/PUBLIC_KEY_ANALYSIS.md` §3 records the open instantiation. The
OIA/TI hardness chain (Theorem 14) does *not* directly underwrite the
commutative variant — CSIDH-style security is a *separate* hypothesis
on the commutative structure, not a consequence of tensor-isomorphism
hardness.

### 1.4 Confidential asset tags with public equivalence

**Construction.** Each asset class is an orbit. A UTXO carries a random
orbit element of its class. Anyone holding `G` can canonicalize to
*identify the class* (not the per-UTXO history); without `G`, two
UTXOs of the same class look as unrelated as two UTXOs of different
classes. A regulator with `G` computes the class histogram
`(class, count)` directly: group UTXOs by canonical form, count.
Per-UTXO sender/receiver linkages remain private to the holders.

Note that `canon(c)` is a *bitstring*, not a scalar — there is no
meaningful arithmetic "sum of canonical forms". The public aggregate
is a multiset of canonical forms (equivalently: the class-count
histogram), not a sum. Tag-only privacy is weaker than full CT: it
hides class-equality across anonymous outputs but does not hide amount,
sender, or receiver unless additional machinery (payment channels,
ring signatures, etc.) is layered on.

**Why orbit-based wins.** Confidential Transactions use Pedersen
commitments and Bulletproofs — effective but heavy on verifier cost
and discrete-log-broken under a CRQC. Orbit tags give class-equality
comparison at one `canon` call, inherit GI/TI hardness, and add a
scalar's worth of state per output.

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
privacy = `concrete_oia_implies_1cpa`. For `k` options the hybrid chain
has `k − 1` adjacent transitions, each with advantage ≤ ε;
`hybrid_argument` in `Probability/Advantage.lean` bounds the overall
distinguishing advantage by `(k − 1)·ε` (so `2ε` at `k = 3`).

**Open.** Coercion resistance: a voter who later reveals their `g_i` can
prove how they voted. Standard remedies (receipt-freeness via
re-randomization by the ballot box) are exactly the "public combiner"
we lack — so orbit voting is currently fit for settings where
coercion is out of scope (small councils, salary committees, internal
forecasting markets) rather than general retail governance.

### 2.2 Anonymous members with revocable pseudonyms

**Construction.** The DAO's membership roster is the orbit of a base
point under a DAO-secret `G`. Each member is provisioned with a *signed
`OrbitalRandomizers` bundle* — a list of `t` orbit elements
`{g_1 • bp, …, g_t • bp}` along with refresh metadata. To post an
action, the member publishes the next bundle element (or a public
combiner output — subject to the `CombineImpossibility` constraint,
see §0); after exhausting the bundle, the member requests a refresh
via `refreshRandomizers`, which `refresh_depends_only_on_epoch_range` shows is
structurally independent of prior epochs. The DAO contract, which holds
`G`, canonicalizes each post to recover the member's class. "Same user"
is detectable inside the DAO (by canonical form); outside observers
see only uniform orbit elements. A member holding *only one* orbit
element `g_i • bp` cannot produce fresh pseudonyms without such a
bundle; the naive "member rotates their credential" is blocked by the
`CombineImpossibility` no-go.

**Why orbit-based wins.** Compared to BBS+ or anonymous credentials,
this avoids pairing-based machinery and makes the "same user?" check
a single `canon` call rather than a ZK proof. Compared to a plain
hashed pseudonym, the member's posts are unlinkable to outside
observers even after collecting many.

**Formalization handle.** `canon_idem` and `canon_eq_of_mem_orbit`
establish pseudonym consistency on canonical forms;
`invariant_const_on_orbit` ensures any DAO-computed invariant
(e.g. reputation score) is a well-defined function of the pseudonym
class. `refresh_depends_only_on_epoch_range` certifies that refreshed bundles do not
correlate across epochs. Revocation is the DAO contract removing the
member's canonical form from its authorized set — `G` does not need to
rotate.

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
without `G`, orders are uniformly distributed on their orbit and
computationally indistinguishable across different orders by OIA; with
`G`, the sequencer canonicalizes to the exact plaintext tuple. The
batch reveal is one `canon` call per order, vs. one MPC decryption
per order in threshold-decrypt designs. Non-separating invariants on
the ambient space (e.g. Hamming weight on the bitstring HGOE) remain
publicly computable and must be designed around — the scheme's
`same_weight_not_separating` discipline applies here unchanged.

**Formalization handle.** `concreteOIA_zero_implies_perfect` certifies
the perfect-hiding limit (ε = 0); `concrete_oia_implies_1cpa` bounds
the computational gap at ε > 0. `canon_encrypt` certifies post-reveal
plaintext recovery. The clearing algorithm itself is outside the
formal model.

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

**Formalization handle.** Matching is a function of canonical forms —
`invariant_const_on_orbit` certifies it is a well-defined function on
equivalence classes. The subtlety worth being explicit about:
functions computed from `canon` *are* separating invariants of `G_p`
across distinct orbits (they typically take distinct values on
distinct orbits). `IsSeparating` is only a security threat when the
invariant is **efficiently computable without the key**; when it
factors through `canon` and `canon` itself requires `G_p`, the
invariant is intrinsically gated by key possession and OIA is not
violated. This is exactly the operator–adversary split the scheme
provides: operator holds `G_p` and computes match predicates;
observers without `G_p` see OIA-indistinguishable orbit elements.

**Price-ordering embedding — caveat.** For the match predicate to
encode "buy ≥ sell price", `reps` must embed price in a way that
survives canonicalization under a chosen `G_p`. This is not automatic:
a random `G_p` with large orbits can collapse price-distinct orders
into the same canonical class. Designers must choose the subgroup
structure so that the equivalence relation "same (side, price, size)"
is exactly the orbit relation. The scheme's formalization does not
pick this `G_p` for you; `docs/planning/PHASE_14_PARAMETER_SELECTION.md`
is the right place to expand concrete subgroup choices.

### 3.3 Unlinkable LP positions via bundled token rotation

**Construction.** An LP deposits into a pool; the pool contract holds
`G` and issues the LP a *rotation bundle* — a signed
`OrbitalRandomizers` list of `t` position tokens `{g_i • reps(p)}`.
The LP presents the next bundle element on each interaction; after
exhaustion, the LP requests a fresh bundle (one `refreshRandomizers`
call from the pool, which knows `G`). Withdrawal requires producing an
orbit element whose canonical form matches `canon(reps p)`.
Un-bundled "free self-rotation" by an LP holding only one orbit
element is blocked by `CombineImpossibility`.

**Why orbit-based wins.** Uniswap v3 positions are publicly linkable by
position parameters; LPs cannot rotate identifiers without forgoing
fee accrual. Orbit-bundled tokens let the LP present a fresh token
per action; the pool's accounting runs on `canon`, which is invariant
across the bundle. Compared to FHE-based private DeFi, the on-chain
cost is one canonicalization per withdrawal, not one FHE evaluation.

**Formalization handle.** `orbit_eq_of_smul`, `canon_eq_of_mem_orbit`
(rotation preserves orbit and canonical form); `refresh_depends_only_on_epoch_range`
(bundle rotation preserves epoch independence).

### 3.4 CSIDH-style session keys for cross-hop privacy

Chaining §1.3 into a DEX: a router sets up pairwise CSIDH-style
session keys with each hop, allowing intermediate routing instructions
to be protected under per-hop keys rather than shared among the whole
path. This reduces the leakage an intermediate hop sees from "the
whole routing plan" to "the next hop only". It is *not* an atomic
multi-hop swap primitive on its own (see §1.3 caveat); it reduces
metadata leakage along an already-composed swap path. Gated on the
same concrete `CommGroupAction` instantiation problem
(`docs/PUBLIC_KEY_ANALYSIS.md` §3).

---

## 4. Social networks

### 4.1 Orbit-follow graphs

**Construction.** Each user `v` has a secret group `G_v`. To authorise
`u` to follow, `v` hands `u` a signed `OrbitalRandomizers` bundle
under `G_v`. To access `v`'s content, `u` presents the next element
of the bundle; `v`'s server canonicalizes under `G_v` to check
membership. When the bundle is exhausted, `v` issues `u` a fresh one
(epoch-rotated via `refreshRandomizers`). Revocation is removing `u`'s
canonical form from `v`'s authorised set; `G_v` does not need to
change.

**Why orbit-based wins.** Current private-follow systems rely on
capability URLs (unguessable links) which are fragile, or on PKI which
exposes the social graph to any intermediary. Orbit follows give
*post-access unlinkability*: each bundle element is an independent
random-looking orbit point, so an adversarial server that later logs
all access tokens cannot link them to a single follower (by OIA). The
server sees only canonical forms, which are a per-user constant.

**Formalization handle.** The follow relation is the orbit of `bp_v`
under `G_v`; `canon_eq_of_mem_orbit` checks membership; an
adversarial server without `G_v` learns nothing by OIA.

**Caveat.** Without the bundle, the follower would be forced to replay
one orbit element, which an adversarial observer could match across
sessions. `CombineImpossibility` blocks free client-side re-rotation
under the symmetric scheme; the bundle is what buys you unlinkability
across accesses.

### 4.2 Per-message orbit freshness (deniable messaging)

**Construction.** Alice and Bob share `G_{AB}` (both hold `G_{AB}`, so
both can sample and canonicalize). To send, Alice picks a fresh
`g ∈ G_{AB}` and sends `c = g • m`. Bob canonicalizes under `G_{AB}`
to recover `canon(m)`, which is the agreed plaintext. An observer —
or a judge presented with `c` — cannot distinguish `c` from a random
orbit element of *any orbit with the same values on all publicly
computable invariants*. For the bitstring-HGOE instance that means
Alice can later claim `c` was the encryption of any plaintext `m'`
whose representative `reps(m')` shares Hamming weight (and any other
publicly computable non-separating invariant) with the true plaintext.

**Why orbit-based wins.** Signal's deniable deniability relies on MACs
constructed so that either party could have forged them. Orbit
messaging is *structurally* deniable within the public-invariant
equivalence class: the ciphertext carries no plaintext-specific
information beyond invariants an observer could compute. This matters
for whistleblower channels, corporate leak-proofing, and settings
where the mere existence of a ciphertext-to-plaintext mapping is the
liability.

**Scope bound.** Deniability is *not* unbounded over the entire
message space — it is bounded by the public-invariant class of the
ciphertext. If the message encoding is designed so that all messages
share the same public invariants (see
`Construction/HGOE.lean:same_weight_not_separating` for the canonical
example), then deniability is effectively universal; otherwise it is
bounded. Designers must audit public invariants.

**Formalization handle.** Deniability within an orbit follows from
`concreteOIA_zero_implies_perfect` (perfect case); the bound on the
deniability class is the conjunction of publicly computable
non-separating invariants, which is exactly what the
invariant-freedom discipline already catalogues.

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

1. **Commit → batch-open** (§§1.2, 2.1, 2.3, 3.1). Submitter posts an
   orbit element; authority later reveals `G`; everything opens
   atomically via `canon`.
2. **Bundle-mediated rotation** (§§2.2, 3.3, 4.1). A `G`-holder issues
   a non-holder a signed `OrbitalRandomizers` bundle, refreshed per
   epoch, allowing the non-holder to present fresh representatives.
   (§4.2 is distinct: both parties hold `G_{AB}`, so no bundle is
   needed — Alice can sample directly.)
3. **Canonicalize-as-query** (§§1.4, 3.2, 4.1, 4.3, 4.4). The
   `G`-holder operates on canonical forms as a function of
   equivalence class, exposing exactly the orbit structure and
   nothing more to itself, and nothing at all to observers.

This decomposition makes clear what the primitive does and does not
give. It gives *privacy by equivalence*: observers cannot
computationally distinguish ciphertexts encoding different messages
(by OIA), up to any publicly computable non-separating invariants of
the ambient space. It does *not* give arbitrary homomorphic
computation, MPC, or non-interactive zero-knowledge over rich
predicates — those remain the province of FHE, MPC, and SNARKs
respectively. The place Orbcrypt earns its keep is where the needed
functionality is exactly "detect equivalence" or "present a fresh
representative", and where post-quantum hardness matters.

---

## 6. Alignment with the formalization, and what is still open

The table below maps each application to the theorems it rests on and
to the open problems that currently block a full deployment.

| Application | Rests on (theorem #) | Open problem |
|-------------|----------------------|--------------|
| 1.1 stealth addresses | 4, 6 | sender-side sampling without `G` |
| 1.2 batched commitments | `canon_idem`, 6, 7 | threshold share of `G` |
| 1.3 CSIDH pair-keys | 17, 18 | concrete `CommGroupAction` instance; atomic-swap needs adaptor-signature layer |
| 1.4 asset tags | 1, `canon_eq_implies_orbit_eq` | regulator trust model |
| 2.1 glass-ballot voting | `canon_eq_of_mem_orbit`, 6, hybrid arg | coercion resistance |
| 2.2 pseudonyms | `canon_idem`, `canon_eq_of_mem_orbit`, `refresh_depends_only_on_epoch_range` | bundle provisioning discipline |
| 2.3 staged budgets | same as 1.2 | threshold share of `G_p` |
| 2.4 delegation trees | `subgroupBitstringAction`, `canon_eq_of_mem_orbit` | subgroup rotation UX |
| 3.1 MEV-sealed auctions | `concreteOIA_zero_implies_perfect`, `canon_encrypt` | sequencer censorship |
| 3.2 dark pools | `invariant_const_on_orbit`, OIA | operator trust model |
| 3.3 LP rotation | `orbit_eq_of_smul`, `canon_eq_of_mem_orbit`, `refresh_depends_only_on_epoch_range` | bundle provisioning / refresh economics |
| 3.4 swap routing | 17, 18 | same as 1.3 |
| 4.1 orbit follows | `canon_eq_of_mem_orbit`, `refresh_depends_only_on_epoch_range`, OIA | bundle distribution; graph-level metadata |
| 4.2 deniable messaging | `concreteOIA_zero_implies_perfect` | deniability class bounded by public invariants; key distribution out of scope |
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
* **Key exchange between strangers without a trusted setup.** In the
  symmetric-orbit setting, `OrbitKeyAgreement` requires both parties to
  hold their respective KEMs' canonicalization capability; the
  structural identity `sessionKey_expands_to_canon_form` (renamed from
  `symmetric_key_agreement_limitation` in Workstream L4) exhibits this
  dependency as a machine-checked equation. The CSIDH-style variant
  (§1.3) can bypass the limitation *if* a concrete `CommGroupAction`
  with a plausible hardness assumption is
  instantiated — an open problem per `docs/PUBLIC_KEY_ANALYSIS.md` §3.
  This is a structural observation, not a lower bound.
* **Password-equivalent low-entropy secrets.** OIA is a
  computational assumption over a large orbit structure; encoding a
  6-digit PIN leaks it to brute-force canonicalization.

---

## 8. Summary

Orbcrypt's value to cryptocurrency, DAOs, DEXes, and social networks is
not "another encryption scheme" but three specific, composable
capabilities: *batch-openable commitments*, *bundle-mediated
representative rotation*, and *canonical-form-as-query*. The
applications that exploit one or more of these — stealth addresses,
batched sealed-bid auctions, MEV-resistant batch DEXes, orbit-follow
social graphs, deniable messaging, orbit-structured DAO delegation —
give post-quantum security from GI / tensor-isomorphism hardness
(for the base OIA-gated designs) or from CSIDH-style hardness (for the
commutative variant), and in several cases give strictly better
functionality than the existing
primitives. The open questions (sender-side sampling, threshold `G`,
invariant hygiene) are tractable next steps for Phases 14+.

---

## 9. Audit changelog (2026-04-18)

This document was audited against the Lean 4 formalization on
2026-04-18. The following corrections were applied relative to the
initial draft; recording them here so later readers can see what
claims were weakened and why.

* **§0.** Replaced the single "combiner is missing" caveat with two
  explicit caveats that also cover the implicit "sampling from `G`
  requires `G`" dependency. Both arise structurally and affect most
  designs.
* **§1.1 (stealth addresses).** Corrected "single group element" to
  "single orbit element" (the ciphertext lives in `X`, not `G`). Added
  concrete GAP benchmark figures for `canon` cost (172 / 320 / 1186 ms
  at λ=80/128/256), noting that full-chain scanning is impractical
  without view tags or parameter reduction.
* **§1.2 (batched commitments).** Corrected the VDF characterisation:
  VDFs give strong parallelism-bounded timing guarantees (only
  time-lock puzzles give "soft" guarantees). Clarified that VDFs and
  orbit commitments are composable rather than competing.
* **§1.3 (CSIDH).** Renamed from "atomic swaps" to "pair-keys for DH on-
  chain". CSIDH-style actions give key agreement, not an atomic-swap
  primitive by themselves; atomic semantics require adaptor
  signatures or equivalent. Also noted that TI hardness (Theorem 14)
  does *not* directly underwrite the commutative variant — CSIDH-style
  hardness is a separate hypothesis.
* **§1.4 (asset tags).** Replaced "sum of canonical forms" (canon is a
  bitstring, not a scalar) with "histogram of canonical-form classes".
  Added scope note that tag-only privacy is weaker than full CT.
* **§2.1 (glass-ballot voting).** Corrected the hybrid-argument bound
  for `k` options from `3ε` to `(k−1)·ε` (so `2ε` at `k = 3`).
* **§2.2 (pseudonyms).** Replaced the "member owns their `g_i` and
  freely rotates" claim with bundle-mediated rotation: a single orbit
  element cannot be freely re-randomised by its holder, per
  `CombineImpossibility`. Members receive signed
  `OrbitalRandomizers` bundles consumed via `refreshRandomizers`.
* **§3.1 (MEV-sealed auctions).** Replaced "information-theoretically
  close to uniform" with the accurate statement: uniform on the orbit,
  computationally indistinguishable across messages by OIA. Noted
  that non-separating public invariants (e.g. Hamming weight) remain
  public.
* **§3.2 (dark pools).** Rewrote the `IsSeparating` discussion: the
  operator's match predicate *is* a separating invariant across
  orbits, and this is OIA-safe precisely because it factors through
  `canon`, which the adversary cannot compute without `G_p`. Added a
  caveat that embedding order-price ordering into canonical forms is
  a parameter-selection problem the formalization does not solve.
* **§3.3 (LP rotation).** Same fix as §2.2 — client-side rotation
  requires a bundle, not free `h • c` re-randomization.
* **§4.1 (orbit follows).** Same fix — followers consume bundle
  elements; free client rotation is blocked.
* **§4.2 (deniable messaging).** Tightened the deniability scope:
  deniability is bounded to the public-invariant equivalence class of
  the ciphertext, not the whole ambient space. For bitstring HGOE
  this is the Hamming-weight class; the
  `same_weight_not_separating` discipline makes the bound effectively
  universal when respected.
* **§7 (anti-use cases).** Corrected the claim that
  `SymmetricKeyAgreementLimitation` is a formal no-go theorem —
  actually it is a structural identity documenting that `sessionKey`
  references both parties' secrets, not a lower bound. The true no-go
  in Phase 13 is `CombineImpossibility`, which bounds the oblivious
  sampler, not key exchange.
* **Summary table.** Updated rows §1.3, §2.2, §3.3, §4.1, §4.2 to
  reflect the corrections above; removed the misleading "directly
  deployable" tag on §3.3.
* **§8 (summary).** Renamed "free owner-side re-randomization" to
  "bundle-mediated representative rotation" in line with the
  `CombineImpossibility` constraint.

All numbered theorem references (Theorems 1, 2, 4, 6, 14, 17, 18)
were cross-checked against `CLAUDE.md`'s theorem registry and the
corresponding Lean sources; all exist with the stated meanings. Named
lemmas (`canon_idem`, `canon_eq_implies_orbit_eq`,
`canon_eq_of_mem_orbit`, `orbit_eq_of_smul`,
`canonical_isGInvariant`, `invariant_const_on_orbit`,
`concreteOIA_zero_implies_perfect`, `concrete_oia_implies_1cpa`,
`csidh_correctness`, `csidh_views_agree`, `comm_pke_correctness`,
`symmetric_key_agreement_limitation`, `refresh_depends_only_on_epoch_range`,
`oblivious_sample_in_orbit`, `hybrid_argument`,
`subgroupBitstringAction`, `same_weight_not_separating`) are all
present in the sources at the locations cited.
