<!--
  Orbcrypt  - Symmetry Keyed Encryption
  Copyright (C) 2026  Adam Hall
  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions. See: https://github.com/hatter6822/Orbcrypt/blob/main/LICENSE
-->

# Novel Use Cases for Orbcrypt

**Status:** exploratory design notes — last updated 2026-05-06.

This document catalogues application designs that genuinely exploit
Orbcrypt's distinctive primitives rather than treating it as a drop-in
replacement for AES or Kyber. Each sketch identifies (a) the concrete
Orbcrypt primitive it leans on, (b) why competing primitives are a poor
fit, and (c) how it aligns with the existing Lean 4 formalization — in
particular which Phase-13 / hardness-chain limitations bite.

Readers unfamiliar with the scheme should first skim `docs/POE.md` (concept),
`docs/DEVELOPMENT.md` §§4–6 (specification), and `docs/PUBLIC_KEY_ANALYSIS.md`
(public-key feasibility). The Lean theorem numbers referenced here match
the canonical numbering in `docs/API_SURFACE.md` § "Three core theorems,
by cluster" (mirrored in `CLAUDE.md`'s theorem registry); theorem
**Status** classifications (`Standalone` / `Quantitative` / `Conditional`
/ `Structural`) follow the release-messaging policy in `CLAUDE.md`'s
Key Conventions and `docs/API_SURFACE.md`'s Status column.
**Quantitative** theorems must be cited with an explicit ε;
**Conditional** theorems must be cited with their hypothesis disclosed;
**Structural** theorems are Mathlib-grade equivalence-relation /
subgroup identities, unconditionally true but not security claims.

---

## 0. The five primitives that make these designs work

Orbcrypt is a small set of operations, all five of which are unusual
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
  bounds any `G`-equivariant, orbit-closed, non-degenerate combiner
  on a non-trivial group action by a quantitative cross-orbit
  distinguisher: `combinerDistinguisherAdvantage_ge_inv_card`
  (**Standalone**) lower-bounds the cross-orbit advantage at `1/|G|`
  under `CrossOrbitNonDegenerateCombiner`, and composing with the
  `concrete_combiner_advantage_bounded_by_oia` upper bound yields
  `no_concreteOIA_below_inv_card_of_combiner` — any such combiner
  forces `ConcreteOIA(ε)` for some `ε ≥ 1/|G|`. Designs that need
  fresh orbit elements from a non-`G`-holder must therefore either
  (i) use the commutative CSIDH-style variant (§1.3), or (ii) route
  randomization through a `G`-holder who issues signed
  `OrbitalRandomizers` bundles consumed one element at a time with
  `refreshRandomizers` rotation. A participant holding only *one*
  orbit element cannot mint fresh ones without one of these routes.
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

**Formalization handle.** `kem_correctness` (Theorem 4, **Standalone**)
plus `encrypt_mem_orbit` and `canon_encrypt` (from `Correctness.lean`)
together guarantee that a correctly posted payment canonicalizes to the
recipient's advertised `canon(bp)`. Unlinkability reduces to
`ConcreteOIA(ε)` via `concrete_oia_implies_1cpa` (Theorem 6,
**Quantitative** — cite with explicit ε) for the bitstring action.

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

**Formalization handle.** Binding follows from `canon_eq_implies_orbit_eq`
(Standalone); hiding from `concreteOIA_zero_implies_perfect` (perfect
limit at ε = 0) and `concrete_oia_implies_1cpa` (Theorem 6,
**Quantitative**: ε > 0 parameterises concrete security).

**Open.** Trust-minimizing the reveal authority — threshold-sharing `G`
over the permutation representation — is natural but not yet
formalized. Phase 13's `refresh_depends_only_on_epoch_range` is a partial step.

### 1.3 CSIDH-style pair-keys for post-quantum DH on-chain

**Construction.** Two parties, each with a secret `a`, `b : G`, use the
commutative action on a shared base point: Alice posts `a • x₀`, Bob
posts `b • x₀`, and each applies their own secret to the other's post,
arriving at `a • (b • x₀) = b • (a • x₀)` by `csidh_correctness`
(Theorem 17, **Standalone**). The common orbit element is a
post-quantum Diffie–Hellman shared secret; `CommOrbitPKE` (Theorem 18,
**Standalone**) wraps this into a KEM-style PKE interface.

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
`comm_pke_correctness` are machine-checked (all **Standalone**). The
missing piece is a concrete `CommGroupAction` with a plausible
hardness assumption; `docs/PUBLIC_KEY_ANALYSIS.md` §3 records the open
instantiation. The probabilistic TI hardness chain
`concrete_hardness_chain_implies_1cpa_advantage_bound` (Theorem 27,
**Quantitative**) delivers an ε-bound from a caller-supplied surrogate
+ encoder profile but does *not* directly underwrite the commutative
variant. CSIDH-style security is a *separate* hypothesis on the
commutative structure, not a consequence of tensor-isomorphism
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

**Open: per-voter coercion-resistance.** A voter who later reveals
their `g_i` can prove how they voted, since `c_i = g_i • reps(m_i)`
becomes a verifier-checkable equation once `G` is published. The
classical remedy — a public ballot-box that re-randomizes each
ciphertext — is bounded both below and above in the orbit setting:
`combinerDistinguisherAdvantage_ge_inv_card`
(`Orbcrypt/PublicKey/CombineImpossibility.lean:750`, **Standalone**)
forces any non-degenerate `G`-equivariant public combiner to leak at
least `1/|G|`, while `concrete_combiner_advantage_bounded_by_oia`
(same file, line 440, **Quantitative** at any `ε` for which
`ConcreteOIA(ε)` holds) caps the leakage at `ε`. The mathematical
gap `[1/|G|, ε]` is non-empty and even narrow at the recommended
parameters (`[2⁻²⁵⁷, 2⁻¹²⁸]` at the **balanced** λ=128 tier of
`docs/PARAMETERS.md` §6.2), but no concrete non-degenerate
`G`-equivariant combiner is known for HGOE's `S_n`-on-bitstrings
action. Receipt-freeness via *public* per-ballot re-randomization
is therefore not currently realisable. Single-key §2.1 voting is
consequently fit for settings where coercion is socially out of
scope — small councils, salary committees, internal forecasting
markets — rather than general retail governance. §2.1.1 below
documents four batching strategies that route around this
constraint and extend the design to substantially larger
electorates.

### 2.1.1 Scaling the voting pool

§2.1's "small councils" framing is a *sociological* bound on
per-voter coercion-resistance, not a cryptographic limit on the
number of ballots. The two ceilings on a single-key election are
quantitatively unrelated:

* **Cryptographic ceiling.** `indQCPA_from_concreteOIA`
  (`Orbcrypt/Crypto/CompSecurity.lean:774`, **Quantitative**)
  delivers `indQCPAAdvantage scheme A ≤ Q · ε` from
  `ConcreteOIA(ε)` alone — so `Q` ballots cost a linear factor in
  the security bound. Combined with the §2.1 hybrid bound
  `(k − 1)·ε` per ballot, total advantage scales as
  `Q · (k − 1) · ε`. At the **balanced** λ=128 tier from
  `docs/PARAMETERS.md` §6.2 (`n = 512`, `log₂|G| = 257`,
  `b = 4`), `docs/PARAMETERS.md` §4.3's birthday-on-orbits
  ceiling is `√|G| ≈ 2¹²⁸`, vastly above any realistic
  electorate. Even `Q = 10⁹` voters with `k = 4` options at
  `ε = 2⁻¹²⁸` leave total advantage at
  `Q · (k − 1) · ε ≤ 2³⁰ · 3 · 2⁻¹²⁸ ≈ 2⁻⁹⁶` — negligible. The
  cryptographic ceiling is *not* the binding constraint for any
  deployment that matches the §6.2 balanced parameters or
  stronger.
* **Coercion-resistance ceiling.** Independent of `Q`, set by the
  §2.1 "Open" caveat: per-voter coercion is governed by the
  `[1/|G|, ε]` combiner-leakage gap and the absence of a known
  concrete equivariant public combiner for HGOE. The four
  strategies below trade trust assumptions for pool size at this
  ceiling.

The four strategies are independent and composable; §2.1.1.7
gives a recommended stack by pool size.

#### 2.1.1.1 Strategy 1 — Threshold-`G` mix-net (receipt-freeness)

**Setup.** The council of `n` members already holds `G` in
`t`-of-`n` threshold form per §2.1's reveal procedure. Each member
`j` holds a subgroup `H_j ≤ G` such that `⟨H_1, …, H_n⟩ = G`.

**Mix protocol.** For ballots `c_1, …, c_Q` posted before the
deadline:

1. **Pre-mix commitment.** Each member `j` samples per-ballot
   randomness `δ_{i,j} ← H_j` uniformly and posts a hiding
   commitment `Com_j(δ_{i,1}, …, δ_{i,Q})` to the public bulletin
   board. Each member also samples a uniform permutation
   `σ_j ∈ S_Q` and commits to it.
2. **Mix application.** In a fixed order, member `j` applies
   `c^{(j)}_i = δ_{i,j} • c^{(j-1)}_{σ_j(i)}` (with
   `c^{(0)} = c`). The final mix output is `c'_i = c^{(n)}_i`.
3. **Reveal.** After the deadline each member opens
   `(δ_{i,j}, σ_j)`. `G` is revealed.
4. **Public audit.** Anyone verifies, for each `(i, j)`: the
   commitment opens correctly; `δ_{i,j} ∈ H_j`; the mix step
   `c^{(j)}_i = δ_{i,j} • c^{(j-1)}_{σ_j(i)}` matches.

**Soundness.** Re-randomization preserves orbits: `c'_i ∈
orbit(c_{σ(i)})` because `∏_j δ_{i,j} ∈ G`, so
`canon_G(c'_i) = canon_G(c_{σ(i)})` by `canon_eq_of_mem_orbit`
(`Orbcrypt/GroupAction/Canonical.lean`, **Standalone**). The
canonical-form tally is therefore unchanged by mixing — only
ballot identity is scrambled. Receipt-freeness against an
`< t`-corrupted council is information-theoretic conditioned on
any honest member: `δ_{i,j}` is uniform over `H_j` and the voter
does not learn it before the deadline.

**Cost.** One commit-reveal round per council member; per-ballot
cost is `n` permutation actions on a 512-bit vector — a few tens
of µs at balanced λ=128. Total mix work is bounded by `Q · n`
such operations and is small relative to ballot-collection
windows in practice.

**Open formalisation.** The threshold sharing and joint-mix
steps sit *above* the orbit primitive and are not currently
formalised in Lean. The cryptographic content of the orbit layer
(orbit-preservation, OIA-bounded distinguishing) is fully
machine-checked; the `t`-of-`n` permutation-MPC content is
research-scope (see §2.1.1.8).

#### 2.1.1.2 Strategy 2 — Cohort partitioning with VRF-based assignment

**Setup.** Split `N` voters into `B` cohorts of size `N/B`, each
with its own `G_b` (independent threshold-shared council per
cohort, or one super-council holding all `G_b`). Cohort
assignment for voter `j` is `H(s ∥ pk_j) mod B`, where `s` is a
fresh public verifiable-randomness-beacon seed (drand / RANDAO /
threshold-BLS) committed *after* voter registration closes and
`pk_j` is the voter's registration key. Both `s` and `pk_j` are
committed before the assignment is computed, so neither side can
grind cohort placement.

**Tally.** Per-cohort canonical-form counts are revealed; the
global tally is the sum. Per-ballot tallies are not revealed.

**Anonymity budget.** The cohort size determines the per-voter
anonymity set, with empirical guidance:

| Coercion adversary       | Cohort size | Anonymity bits |
|--------------------------|-------------|----------------|
| Casual / social          | 16          | 4              |
| Workplace / familial     | 64          | 6              |
| Organised / state-level  | 1 024       | 10             |

Below 16 the cohort can be exhaustively interrogated; above
~1 024 the council overhead per cohort dominates and Strategy 2
should be combined with Strategy 1 hierarchically (§2.1.1.5) or
swapped for delegation (§2.1.1.3).

**Soundness.** Each cohort is an independent §2.1 deployment;
per-cohort tally is correct by `canon_eq_of_mem_orbit`
(**Standalone**). Cross-cohort independence is structural:
`G_1 ⊥ G_2 ⊥ …` is a direct-product ambient, and the VRF beacon
makes assignment uniform conditional on adversary view. The
sender-side property "ε-bounded distinguishing inside a cohort"
follows from `concrete_oia_implies_1cpa` (**Quantitative**)
applied per cohort.

#### 2.1.1.3 Strategy 3 — Delegation tree (representative democracy)

**Setup.** `N` voters elect `E « N` delegates via a
coercion-tolerant primary (any non-orbit method — paper ballots,
in-person voting, signed online ballot under social oversight).
The `E` delegates then run §2.1 + §2.1.1.1 amongst themselves.

**Why this works for scale.** Coercion now operates at the
delegate layer rather than the voter layer. Delegates are a
smaller, more publicly accountable population — well-matched to
the §2.1 "small council" sociological bound. The orbit-layer
voting pool is `E`, which can be tuned independently of `N`.

**Formalisation handle.** §2.4 of this document already
formalises the delegation-tree structure as a chain of subgroups
via `subgroupBitstringAction`
(`Orbcrypt/Construction/HGOE.lean`, **Standalone**); each
delegate level is a separate canonicalization under the
level-appropriate subgroup, with rotation handled by subgroup
refresh.

#### 2.1.1.4 Strategy 4 — Per-epoch `G` rotation (forward secrecy)

**Setup.** A long-running governance system rotates `G_t` per
epoch using `refreshRandomizers`
(`Orbcrypt/PublicKey/ObliviousSampling.lean`, **Standalone** via
`refresh_depends_only_on_epoch_range`). Each epoch is a §2.1
deployment with its own threshold-shared `G_t` and its own
published-after-deadline reveal.

**What this gives.** Forward secrecy across epochs: leak of
`G_t` does not deanonymise epoch-`(t-1)` ballots, because
`refresh_depends_only_on_epoch_range` certifies bundle-element
independence across epoch ranges.

**What this does not give.** Within-epoch coercion-resistance is
unchanged from §2.1 — Strategy 4 is a *temporal* extension, not
a per-epoch coercion fix. Combine with Strategies 1–3 for full
coverage.

**Open formalisation.** Cross-epoch ciphertext indistinguishability
(distinct from bundle-element independence) requires composing two
`ConcreteOIA(ε)` games on independent groups, giving a `2ε`
bound. The composition lemma is straightforward but currently
research-scope (§2.1.1.8).

#### 2.1.1.5 Hierarchical composition

For pool sizes beyond ~50 000, stack Strategies 1 and 2:

* **Level-0 cohorts** of size `B₀` (e.g. 64) under independent
  `G_b`'s, each mixed via Strategy 1.
* **Level-1 super-cohorts** aggregating `B₁` cohorts each, with
  count vectors mixed via a second Strategy-1 protocol on the
  level-1 hidden subgroup of `S_{B₀}` (cohort-label permutation).
* **Global tally** = sum of level-1 super-cohort outputs.

Per-voter anonymity at depth 2 is `log₂(B₀ · B₁)` bits (12 bits
at `B₀ = B₁ = 64`, supporting a 262 144-voter electorate). The
two layers are analytically independent; the total advantage
budget is `Q · (k − 1 + d) · ε` for hierarchy depth `d`, which
remains negligible at the balanced λ=128 tier through `Q ≈ 10⁹`
voters.

#### 2.1.1.6 Best practices for every deployment

* **Spoilage as a fourth option.** Define
  `reps : {yes, no, abstain, spoil} → X` so every ballot
  canonicalizes to a public form. Spoilage stops being a public
  failure mode and becomes a normal vote, eliminating the
  "your-ballot-must-be-valid" coercion vector. The hybrid bound
  becomes `(k − 1)·ε = 3ε` per ballot.
* **Turnout privacy via council chaff.** The council injects `K`
  chaff ballots in publicly committed proportion across the four
  canonical representatives. Total bulletin-board ballot count
  becomes `Q + K`; per-canonical-form chaff share is subtracted
  at tally. `K = √Q` gives `O(1)` bits of leakage on per-voter
  turnout; `K = Q` saturates turnout privacy.
* **Replay protection.** Voter signs `(ballot, epoch_id)` with a
  PQ-secure registration key; bulletin enforces one ballot per
  `(identity, epoch_id)`. Use a hash-based or lattice signature
  to match Orbcrypt's PQ posture (orthogonal to the orbit
  primitive).
* **Per-vote `g_i` derivation.** Derive
  `g_i = PRF(voter_seed_i, ballot_seq, epoch_id)` per
  `Orbcrypt/KeyMgmt/Nonce.lean` discipline. Accidental
  resubmission then produces an identical `c_i`, which the
  bulletin rejects as a duplicate rather than treating as two
  ballots.
* **End-to-end voter verification.** Once `G` is published,
  every voter can verify (a) their `c_i` (or post-mix `c'_i`) is
  in the bulletin, (b) `canon_G(c'_i) = reps(m_i)`, (c) the
  published tally matches the bulletin's canonical-form
  multiset. All three are public computations once `G` is
  revealed; the orbit primitive delivers E2E-verifiability
  without additional machinery.

#### 2.1.1.7 Recommended stack by pool size

| Pool size                          | λ tier                            | Stack                                                                                                          |
|------------------------------------|-----------------------------------|----------------------------------------------------------------------------------------------------------------|
| ≤ 50 (board / committee)           | balanced 128                      | §2.1 + threshold-`G` reveal; spoilage-as-fourth-option; E2E voter verification; no mix needed                  |
| 50 – 5 000 (medium org)            | balanced 128                      | + Strategy 1 (threshold-`G` mix with permuted reveal) for receipt-freeness                                     |
| 5 000 – 100 000 (large org / city) | balanced 128 or 192               | + Strategy 2 (VRF-based cohort partitioning, cohort size 64); per-cohort Strategy 1                            |
| 100 000 – 10 M (subnational)       | balanced 192                      | + §2.1.1.5 hierarchical depth 2; Strategy 4 epoch rotation across multi-day windows                            |
| ≥ 10 M (general retail)            | balanced 192 or conservative 128  | Strategy 3 delegation tree + voter-level orbit voting confined to small primaries with Strategies 1–2          |

The cryptographic ceiling is never tight on this table; every
entry is determined by the coercion-resistance trade-off between
cohort size, mix overhead, and council trust assumptions.

#### 2.1.1.8 Research-scope items needed for full v1.0 alignment

1. **Threshold-permutation MPC formalisation.** Strategy 1's
   joint mix is informal: a Lean formalisation of `t`-of-`n`
   share-and-evaluate over `S_n` (or the wreath-product `G` of
   HGOE) would convert §2.1.1.1 from a protocol sketch to a
   machine-checked construction.
2. **Cross-epoch ciphertext indistinguishability.** Strategy 4
   currently rests on `refresh_depends_only_on_epoch_range`
   (bundle-element independence) plus an informal composition
   step. A single Lean lemma composing two independent
   `ConcreteOIA(ε)` games to a `2ε` bound would close §2.1.1.4's
   open formalisation point.
3. **Cohort-assignment unbiasability.** The VRF beacon in
   Strategy 2 is informal. Formalising "cohort assignment is
   uniform conditional on adversary view" given a public
   verifiable-randomness oracle is a small but currently missing
   Lean lemma.
4. **Concrete equivariant public combiner (or its
   non-existence).** `concrete_combiner_advantage_bounded_by_oia`
   and `combinerDistinguisherAdvantage_ge_inv_card` together
   leave a `[1/|G|, ε]` gap in which a non-trivial equivariant
   public combiner *might* live. A construction would lift §2.1
   to single-phase receipt-freeness without the threshold-MPC of
   Strategy 1; a non-existence proof would close the gap. Either
   resolves §2.1's "Open" entry decisively.

These items are independent. Items (1) and (2) are the most
consequential for the §6 application table's "Open" column on
row 2.1.

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
pick this `G_p` for you; `docs/dev_history/PHASE_14_PARAMETER_SELECTION.md`
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
function), `invariant_attack` (Theorem 2, **Standalone**) witnesses an
adversary with `hasAdvantage` — a specific `(g₀, g₁)` pair on which
the adversary's two guesses disagree. Informal shorthand: "complete
break under a separating G-invariant"; the formal conclusion is
`∃ A, hasAdvantage scheme A` (existence of one distinguishing
adversary), not a quantitative "advantage = 1/2" claim. See
`docs/API_SURFACE.md` row #2 for the full three-convention advantage
catalogue (deterministic = 1, two-distribution = 1, centred = 1/2).
The probabilistic strengthening
`indCPAAdvantage_invariantAttackAdversary_eq_one` (Workstream R-01,
**Standalone**) tightens the existential claim to a *quantitative*
equality: the invariant-attack adversary's IND-1-CPA advantage is
*exactly* `1`, ruling out any `ConcreteOIA(ε)` bound for `ε < 1` once
a separating G-invariant exists. The privacy collapses either way.
This constrains the kinds of recommendation logic permissible:
clustering on `canon` is safe; clustering on any non-invariant feature
destroys the guarantee. Designers must state explicitly which
invariants the service may compute.

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
to the open problems that currently block a full deployment. Theorem
numbers reference the canonical numbering in `docs/API_SURFACE.md`
§ "Three core theorems, by cluster"; statuses follow the
release-messaging policy (Standalone = unconditional; Quantitative =
ε-bounded probabilistic; Conditional = hypothesis must be disclosed;
Structural = Mathlib-grade equivalence-relation / subgroup identity).

| Application | Rests on (theorem # / Lean handle / Status) | Open problem |
|-------------|----------------------------------------------|--------------|
| 1.1 stealth addresses | #4 (Standalone), #6 (Quantitative) | sender-side sampling without `G` |
| 1.2 batched commitments | `canon_idem` (Standalone), #6 (Quantitative), #9 seed-key correctness (Standalone) | threshold share of `G` |
| 1.3 CSIDH pair-keys | #17, #18 (both Standalone) | concrete `CommGroupAction` instance; atomic-swap needs adaptor-signature layer |
| 1.4 asset tags | #1 (Standalone), `canon_eq_implies_orbit_eq` (Standalone) | regulator trust model |
| 2.1 glass-ballot voting | `canon_eq_of_mem_orbit` (Standalone), #6 (Quantitative), `hybrid_argument_uniform`; multi-ballot bound `indQCPA_from_concreteOIA` (Quantitative); combiner gap `[1/|G|, ε]` from `combinerDistinguisherAdvantage_ge_inv_card` (Standalone) + `concrete_combiner_advantage_bounded_by_oia` (Quantitative) | per-voter coercion-resistance (mitigated by §2.1.1.1–§2.1.1.5; see §2.1.1.8 research-scope items) |
| 2.2 pseudonyms | `canon_idem`, `canon_eq_of_mem_orbit`, `refresh_depends_only_on_epoch_range` (all Standalone) | bundle provisioning discipline |
| 2.3 staged budgets | same as 1.2 | threshold share of `G_p` |
| 2.4 delegation trees | `subgroupBitstringAction`, `canon_eq_of_mem_orbit` (Standalone) | subgroup rotation UX |
| 3.1 MEV-sealed auctions | `concreteOIA_zero_implies_perfect`, `canon_encrypt` (Standalone) | sequencer censorship |
| 3.2 dark pools | `invariant_const_on_orbit` (Standalone), OIA-bounded view | operator trust model |
| 3.3 LP rotation | `orbit_eq_of_smul`, `canon_eq_of_mem_orbit`, `refresh_depends_only_on_epoch_range` (Standalone) | bundle provisioning / refresh economics |
| 3.4 swap routing | #17, #18 (Standalone) | same as 1.3 |
| 4.1 orbit follows | `canon_eq_of_mem_orbit`, `refresh_depends_only_on_epoch_range` (Standalone), OIA-bounded view | bundle distribution; graph-level metadata |
| 4.2 deniable messaging | `concreteOIA_zero_implies_perfect` (perfect limit at ε = 0; Standalone) | deniability class bounded by public invariants; key distribution out of scope |
| 4.3 private recs | `canonical_isGInvariant` (Standalone) | service must be invariant-free |
| 4.4 group PSI | `canon_eq_implies_orbit_eq` (Standalone) | delegated canonicalization model |

For *quantitative* security citations, use the probabilistic chain:
`concrete_oia_implies_1cpa` (#6, Quantitative) at the scheme layer,
`concrete_hardness_chain_implies_1cpa_advantage_bound` (#27,
Quantitative) for end-to-end TI-hardness → IND-1-CPA, and
`concrete_kem_hardness_chain_implies_kem_advantage_bound` (#29,
Quantitative) for the KEM layer. Both #27 and #29 are inhabited
unconditionally only at ε = 1 via the trivial `tight_one_exists`
witness (PUnit surrogate) or `tight_one_exists_at_s2Surrogate`
(S₂ surrogate); ε < 1 requires a caller-supplied surrogate +
encoder profile (research-scope per `docs/planning/`'s R-02 / R-03
/ R-04 / R-05 milestones). For multi-query IND-Q-CPA, compose with
`indQCPA_from_concreteOIA` (Workstream R-09, **Quantitative**),
which delivers a `Q · ε` bound from `ConcreteOIA(ε)` alone.

Three structural gaps recur:

* **Sender-side sampling without `G`.** The `combine` impossibility
  (Phase 13) is the hard bound: `combinerDistinguisherAdvantage_ge_inv_card`
  and its corollary `no_concreteOIA_below_inv_card_of_combiner`
  rule out `ConcreteOIA(ε)` for `ε < 1/|G|` whenever a cross-orbit
  non-degenerate combiner exists. Progress depends on either (i)
  instantiating `CommGroupAction` concretely, making §§1.3, 3.4
  deployable and bypassing the impossibility, or (ii) introducing a
  signed-bundle ("randomizer certificate") protocol layer that
  pushes the trust to a rotating issuer, as hinted in
  `refreshRandomizers`.

* **Threshold-sharing `G`.** Several applications want to reveal `G`
  atomically under a distributed trigger. The natural approach is
  Shamir secret sharing over the permutation representation, but no
  Lean development addresses this yet. This is a concrete next-step
  work unit for a future phase.

* **Invariant hygiene.** Applications that let the service or
  contract compute *anything* about ciphertexts risk introducing a
  separating invariant and collapsing privacy by `invariant_attack`
  (Theorem 2, **Standalone**). Design review must verify that every
  on-chain / server-side function factors through `canon`. A linter —
  a "taint tracker" from ciphertext to non-`canon` invocations —
  would substantially reduce this risk.

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
`sessionKey_expands_to_canon_form` (was
`symmetric_key_agreement_limitation` at the time of this 2026-04-18
audit; renamed in Workstream L4 of the 2026-04-21 audit),
`refresh_depends_only_on_epoch_range` (was `refresh_independent` at
the time of this 2026-04-18 audit; renamed in Workstream L3 of the
2026-04-21 audit), `oblivious_sample_in_orbit`, `hybrid_argument`,
`subgroupBitstringAction`, `same_weight_not_separating`) are all
present in the sources at the locations cited (with the renames
disclosed above).

---

## 10. Audit changelog (2026-04-29)

A second pass aligned the document with the release-messaging policy
introduced by Workstream A of the 2026-04-23 pre-release audit
(`docs/planning/AUDIT_2026-04-23_WORKSTREAM_PLAN.md` § "Workstream A"),
and with the renames + Lean theorem additions landed by Workstreams
A–G of that audit and by Workstream R-CE / R-TI.

* **Header.** Cross-references the release-messaging policy and the
  Status taxonomy so readers know how to read the inline tags below.
* **§1.1, §1.2, §1.3.** Theorem citations now carry their Status
  label inline. `concrete_oia_implies_1cpa` and the hardness-chain
  references are explicitly tagged **Quantitative** (cite with
  ε); `csidh_correctness`, `comm_pke_correctness`, and
  `kem_correctness` are tagged **Standalone**. The hardness-chain
  citation is
  `concrete_hardness_chain_implies_1cpa_advantage_bound`
  (Theorem 27).
* **§1.2 (batched commitments).** No cross-reference change in this
  pass. The hiding-at-ε=0 framing cites only
  `concreteOIA_zero_implies_perfect`, which is unconditional.
* **§4.3 (private recommendations).** Tightened the
  `invariant_attack` framing per Workstream A of audit 2026-04-23
  finding D13: the formal conclusion is `∃ A, hasAdvantage scheme A`
  (existence of one distinguishing adversary), not a quantitative
  "advantage = 1/2" claim. The three-convention catalogue (deterministic
  = 1, two-distribution = 1, centred = 1/2) is named explicitly.
* **§6 alignment table.** Each row now carries its Status label;
  added a closing paragraph naming the canonical **Quantitative**
  citations (#6, #27, #29).
* **§7 (anti-use cases).** Already correct as of the 2026-04-18
  audit (it referenced `sessionKey_expands_to_canon_form`, the
  current name post-Workstream-L4 of audit 2026-04-21). No further
  change required in this pass.

No design-level claims were weakened in this pass; the changes are
purely classification + naming alignment with the post-Workstream-A
release-messaging policy.

---

## 11. Audit changelog (2026-05-06)

A third pass aligned the document with the structural-review
workstreams of 2026-05-06 (plan
`docs/dev_history/AUDIT_2026-05-06_STRUCTURAL_REVIEW.md`) and with
research-scope discharges R-01 / R-07 / R-09 / R-13 (audit
2026-04-29 / 2026-04-30 / 2026-05-01 landings).

* **Header.** Theorem-numbering source promoted to
  `docs/API_SURFACE.md` § "Three core theorems, by cluster" —
  the regenerable canonical reference. Status taxonomy now
  surfaces **Structural** (Mathlib-grade equivalence-relation /
  subgroup identities) as a separately-labelled class.
* **§0 (the five primitives).** The "Public re-randomization is
  blocked" caveat now cites the quantitative `combine` no-go:
  `combinerDistinguisherAdvantage_ge_inv_card` (Workstream R-07,
  **Standalone**) with its
  `no_concreteOIA_below_inv_card_of_combiner` corollary forces
  `ConcreteOIA(ε)` for some `ε ≥ 1/|G|` whenever a cross-orbit
  non-degenerate combiner exists.
* **§4.3 (private recommendations).** The `invariant_attack`
  caveat now also cites
  `indCPAAdvantage_invariantAttackAdversary_eq_one` (Workstream
  R-01, **Standalone**) — the probabilistic strengthening that
  pins the invariant-attack adversary's IND-1-CPA advantage to
  *exactly* `1`, ruling out any `ConcreteOIA(ε)` bound for
  `ε < 1` once a separating G-invariant exists.
* **§6 alignment table closing paragraph.** Added the inhabitation
  posture for #27 / #29 (ε = 1 unconditional via
  `tight_one_exists` / `tight_one_exists_at_s2Surrogate`; ε < 1
  research-scope per R-02 / R-03 / R-04 / R-05) and the
  multi-query bound `indQCPA_from_concreteOIA` (Workstream R-09,
  **Quantitative**) for designs that issue many ciphertext
  queries (DEX batch auctions, dark-pool order books, glass-
  ballot voting at scale).
* **§6 third bullet (sender-side sampling).** Updated to cite
  the R-07 quantitative refinement.
* **Theorem-numbering source.** All theorem numbers reference the
  canonical numbering of `docs/API_SURFACE.md` § "Three core
  theorems, by cluster".
* **Naming.** No identifier renames since 2026-04-29; all Lean
  identifier citations remain valid.
* **Benchmark figures.** The §1.1 GAP benchmark figures
  (172 / 320 / ≈1.2s ms canon at λ=80/128/256) are unchanged
  versus the pre-Workstream-A2 anchor. The current
  `implementation/gap/orbcrypt_benchmarks.csv` reports
  canon_ms = 1158 at λ=256 (vs. decaps_ms = 1186 — distinct
  columns).

No design-level claims were weakened in this pass; the changes
are classification + theorem-citation alignment with the
recently-discharged research milestones (R-01, R-07, R-09, R-13).

---

## 12. Audit changelog (2026-05-07)

A fourth pass refined §2.1 (glass-ballot voting) to address the
"how large can the voting pool be?" question that
`docs/USE_CASES.md` was previously silent on. The refinements
distinguish the *cryptographic* multi-query ceiling (set by
`indQCPA_from_concreteOIA`'s `Q · ε` bound and
`docs/PARAMETERS.md` §4.3's birthday-on-orbits ceiling, neither of
which is tight at the §6.2 balanced parameters) from the
*coercion-resistance* ceiling (set by the §2.1 "Open" caveat),
and document four batching strategies that extend the design to
substantially larger electorates.

* **§2.1 "Open" paragraph.** Replaced the "we lack the public
  combiner" framing with the quantitative
  `[1/|G|, ε]` characterisation: the lower bound is
  `combinerDistinguisherAdvantage_ge_inv_card` (Workstream R-07,
  **Standalone**); the upper bound is
  `concrete_combiner_advantage_bounded_by_oia` (Workstream E6,
  **Quantitative** under `ConcreteOIA(ε)`). The gap is non-empty
  and even narrow at the recommended parameters (`[2⁻²⁵⁷, 2⁻¹²⁸]`
  at balanced λ=128), so public re-randomization is not formally
  ruled out — but no concrete non-degenerate `G`-equivariant
  combiner is known for HGOE's `S_n`-on-bitstrings action, so it
  is not currently realisable in practice. Added a forward
  reference to §2.1.1.
* **§2.1.1 (new subsection).** Documents the two distinct
  ceilings on a single-key election, then covers four
  composable batching strategies and their soundness:
  * §2.1.1.1 **threshold-`G` mix-net** with commit-then-reveal
    plus permuted re-randomization (receipt-freeness);
  * §2.1.1.2 **cohort partitioning** with VRF-based assignment
    (per-voter anonymity set bounded by cohort size);
  * §2.1.1.3 **delegation tree** via the §2.4
    `subgroupBitstringAction` chain (representative democracy
    on a smaller orbit-layer pool);
  * §2.1.1.4 **per-epoch `G` rotation** via
    `refresh_depends_only_on_epoch_range` (forward secrecy
    across epochs).
  §2.1.1.5 covers hierarchical composition of Strategies 1–2 for
  electorates beyond ~50 000. §2.1.1.6 lists best practices
  (spoilage-as-fourth-option, turnout chaff, replay protection,
  per-vote PRF-derived `g_i`, E2E voter verification). §2.1.1.7
  gives a recommended-stack-by-pool-size table. §2.1.1.8 lists
  four research-scope items that would close the open
  formalisation points: (1) threshold-permutation MPC, (2)
  cross-epoch ciphertext indistinguishability, (3) cohort-
  assignment unbiasability, (4) concrete equivariant public
  combiner (or a proof of non-existence).
* **§6 alignment-table row 2.1.** Expanded the "Rests on" cell
  to cite `indQCPA_from_concreteOIA` (Workstream R-09,
  **Quantitative**, the `Q · ε` multi-ballot bound) and the
  combiner-gap pair
  `combinerDistinguisherAdvantage_ge_inv_card` /
  `concrete_combiner_advantage_bounded_by_oia` with their Status
  labels. Updated the "Open problem" cell to point at the
  §2.1.1 mitigations and the §2.1.1.8 research-scope items.

No design-level claims were weakened in this pass. The
refinements (a) correct the §2.1 framing of CombineImpossibility
from "we lack" to a quantitatively bounded
`[1/|G|, ε]` characterisation, and (b) extend §2.1's recommended
deployment scope from "small councils" to electorates of
~262 144 voters at depth-2 hierarchical composition, all under
the existing `ConcreteOIA(ε)` assumption and the `docs/PARAMETERS.md`
§6.2 balanced parameter set.

All Lean identifier citations introduced in this pass —
`indQCPA_from_concreteOIA`, `combinerDistinguisherAdvantage_ge_inv_card`,
`concrete_combiner_advantage_bounded_by_oia`,
`canon_eq_of_mem_orbit`, `concrete_oia_implies_1cpa`,
`subgroupBitstringAction`,
`refresh_depends_only_on_epoch_range` — were verified against
the current source files at the line numbers cited.
