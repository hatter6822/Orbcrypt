# Orbcrypt for an Anonymous Software Development Platform

**Status:** exploratory design notes — last updated 2026-04-18.

This document applies the primitives catalogued in `docs/USE_CASES.md` to
the specific setting of an **anonymous software development platform**
that integrates cryptocurrency rails and LLM-based tooling. It does not
re-derive the Orbcrypt primitives; readers should first skim `POE.md`
(concept), `docs/USE_CASES.md` §0 (the four primitives), and
`docs/PUBLIC_KEY_ANALYSIS.md` (feasibility) so that references to
`canon`, `encaps`, `OrbitalRandomizers`, and the `CombineImpossibility`
no-go are familiar. Theorem numbers below match `CLAUDE.md`'s registry.

The focus is the three-way intersection:

* **Anonymity** — pseudonymous contributors, unlinkable artifacts,
  disclosure-controlled releases.
* **Cryptocurrency** — escrow, bounty, subscription, and streaming
  payment rails that must bind to on-chain state.
* **LLMs** — code generation, review, triage, and summarization, where
  prompts and outputs can themselves be disclosure-sensitive.

Orbcrypt is a confidentiality + equivalence-labelling primitive, not a
network-anonymity system, not FHE, and not a signature scheme. The
designs below identify where it adds value that AES-GCM + lattice KEMs
would not, and where other layers (mixnets, ring signatures, TEEs,
ZK proofs) must sit alongside it. The honesty discipline of
`docs/USE_CASES.md` §9 applies throughout.

---

## 0. Why a dev platform is different

Four features distinguish software development from the applications
already catalogued in `USE_CASES.md`:

1. **Artifacts are large and content-bearing.** A commit diff, a build
   log, or a bug-report PoC is arbitrarily long plaintext. Orbcrypt's
   AOE layer encrypts a *message index* `m ∈ M` from a finite message
   space; long payloads must ride the KEM+DEM hybrid
   (`AEAD/Modes.lean:hybridEncrypt`), with orbit structure applied to
   the KEM, not the DEM payload.
2. **The unit of privacy is often the *category*, not the content.**
   Which project a contributor is working on, which severity class a
   bug report is in, or which access tier a reviewer holds is often
   more sensitive than the content itself. Category privacy is exactly
   what the orbit primitive gives (`canonical_isGInvariant`,
   `concrete_oia_implies_1cpa`).
3. **Identity is long-lived and reputationally loaded.** A pseudonym
   that accumulates many contributions must stay unlinkable to the
   real identity *and* to other pseudonyms of the same person, while
   still letting the platform accrue reputation. This is the
   bundle-mediated rotation pattern from `USE_CASES.md` §2.2 applied
   to contributors rather than DAO members.
4. **LLMs break the encryption envelope.** Any party that sees
   plaintext prompts or plaintext generations can profile a developer.
   Orbcrypt cannot make an LLM operate on ciphertext; it can only gate
   which parties *get* plaintext, and make traffic patterns reveal as
   little as possible. This is a strict design constraint, addressed
   explicitly in §5.

---

## 1. Mapping dev-platform primitives onto orbit primitives

The table below matches platform-layer concepts to Orbcrypt primitives
from `USE_CASES.md` §0, and names the Lean 4 definitions and theorems
that certify correctness or hiding for each.

| Platform concept | Orbit primitive | Lean handle |
|------------------|-----------------|-------------|
| Per-project access tier | Subgroup action `G_P ≤ S_n` | `subgroupBitstringAction` |
| Project identifier (what project a commit belongs to) | Orbit class `canon_{G_P}` | `canon_eq_of_mem_orbit`, Theorem 1 |
| Pseudonymous contributor token | Bundle element from `OrbitalRandomizers G_C t` issued by the project | `oblivious_sample_in_orbit`, `refresh_independent` |
| Session / ephemeral key for a DEM payload | KEM key `encaps(g).2` | Theorem 4 (`kem_correctness`) |
| Coordinated vulnerability embargo | Batch-openable commitment (reveal `G_E`) | `canon_eq_implies_orbit_eq`, Theorem 6 |
| Severity-class-private bug report | Orbit label under a triage-secret group | `concrete_oia_implies_1cpa`, Theorem 6 |
| Reviewer capability (role) | Chain of nested subgroups | `subgroupBitstringAction` composed |
| Per-hop LLM session key | CSIDH-style shared secret | Theorem 17, gated on open §1.3 instantiation |
| Sybil-resistance stake-binding | Seed-derived KEM from wallet HD path | Theorem 9 (`seed_kem_correctness`) |
| Audit log entry (deterministic) | Nonce-based encapsulation | Theorem 10 + §1 caveat below |
| Integrity of published artefact | AEAD with MAC | Theorem 12 (`aead_correctness`) |

Two caveats recur and must be stated once:

* **Nonce reuse is a disclosure-class leak**, not a content leak.
  `KeyMgmt/Nonce.lean:nonce_reuse_leaks_orbit` (Theorem 11) is the
  formal warning. For an audit log where entries are *intended* to be
  deterministic (content-addressed, cross-referenced), this is a
  feature. For an audit log that also aims at unlinkability across
  rotations, it is a disaster. Pick one.
* **The bundle-mediated rotation pattern (`USE_CASES.md` §2.2) is the
  default for contributor-side operations.** A contributor holding
  only one orbit element cannot mint fresh representatives under the
  symmetric scheme; `CombineImpossibility` is the Lean-proved no-go.
  The project server (which holds `G_P`) must issue bundles and
  refresh them on schedule. CSIDH-style key agreement (§1.3 of
  `PUBLIC_KEY_ANALYSIS.md`) is the only known bypass and depends on a
  concrete `CommGroupAction` instantiation that is still open.

---

## 2. Developer identity layer

### 2.1 Pseudonym issuance

A contributor joins the platform by obtaining — from a project
maintainer, DAO, or automated issuer — a signed `OrbitalRandomizers
G_C t` bundle. `G_C` is the contributor's personal identity group,
known only to the issuer; `t` is the bundle size (how many distinct
orbit representatives the contributor can present before requesting a
refresh). To post any action, the contributor presents the next
bundle element. The platform canonicalizes under `G_C`: the canonical
form is the contributor's stable pseudonym; the presented element is
unlinkable across actions.

* **Linkability for the platform, unlinkability for observers.** The
  platform sees `canon_{G_C}(·)` and thus tracks the contributor
  across actions, accumulating reputation under a stable key. An
  external observer (including a compromised mirror or an
  adversarial read-replica) sees only orbit elements, which are
  `ConcreteOIA(ε)`-indistinguishable.
* **Revocation without rotation.** Removing a contributor is a
  set-membership check on their canonical form — no global key
  rotation is needed. This is the same pattern as DAO pseudonyms in
  `USE_CASES.md` §2.2.
* **Formalization handle.** `canon_idem` (stability of the canonical
  form), `canon_eq_of_mem_orbit` (all bundle elements canonicalize
  equally), `refresh_independent` (epoch-rotation gives structural
  independence).

### 2.2 Cross-project unlinkability

If a contributor works on two projects with distinct `G_{C,1}` and
`G_{C,2}` (issued by different maintainers), posts under the two
pseudonyms are unlinkable by any third party: the two orbit elements
are samples from distinct orbit structures, and no efficient function
separates them without one of the groups (by OIA). This is the
natural defence against cross-project behavioural fingerprinting.

Caveat: it does *not* defend against *stylometric* linkage of the
plaintext content. An LLM-assisted attacker who sees plaintext
contributions can cluster by writing style regardless of the
encryption layer. Mitigations — stylometric-neutralization
pre-processing, LLM-generated style rewrites, or enforced templated
output — are application-layer concerns that orbit cryptography does
not address.

### 2.3 Sybil resistance via wallet-bound seeds

The contributor's `G_C` is derived from a wallet HD path via
`KeyMgmt/SeedKey.lean:sampleGroup`. A Sybil attempt requires either
(a) a fresh wallet funded with a minimum stake, or (b) proof of a
signed delegation from an existing staked wallet. Seed derivation is
deterministic (Theorem 9), so a contributor recovering their wallet
recovers all their pseudonyms; no side-channel key-backup is
required. Slashing an abusive contributor is a one-line contract
action on the stake plus a canonical-form delist.

### 2.4 What this does not give

* **No network-level anonymity.** Orbcrypt does not hide IP, timing,
  or traffic shape. A Tor / I2P / mixnet layer is assumed. Without it,
  pseudonyms are linkable by metadata regardless of any orbit
  guarantee.
* **No authorship unforgeability.** The bundle element proves
  possession of a valid bundle entry, not authorship of the
  referenced content. Every post must be wrapped in a PQ signature
  under the pseudonym's signing key (SPHINCS+, Dilithium, or the AEAD
  MAC layer with a PQ MAC instantiation). The orbit layer provides
  the pseudonym label; the signature layer provides authorship.

---

## 3. Code and artifact layer

### 3.1 Encrypted commit storage (hybrid encryption)

A commit's full diff is arbitrary plaintext; it rides the KEM+DEM
hybrid (`AEAD/Modes.lean:hybridEncrypt`). The project-scoped
`hgoeKEM G_P` wraps a fresh symmetric key; a standard DEM (ChaCha20-
Poly1305 or AES-GCM, both NIST-accepted and simple to formally bound)
encrypts the diff. On push, the server stores `(c_KEM, c_DEM, MAC)`
where `c_KEM = g • bp_P` and the orbit structure of `c_KEM`
communicates "this payload belongs to project P" to a `G_P` holder.

* **Observer view:** ciphertext blob whose KEM half is OIA-
  indistinguishable from any other project's KEM. A compromised
  storage backend cannot tell which project a given blob belongs to,
  which already defeats "exfiltrate the interesting projects" as a
  strategy.
* **G_P-holder view:** canonicalize `c_KEM` under `G_P`, derive the
  DEM key via `keyDerive`, decrypt. `hybrid_correctness` (Theorem 13)
  certifies round-trip correctness.
* **Formalization handles:** Theorem 4 (KEM correctness), Theorem 12
  (AEAD), Theorem 13 (hybrid). The DEM's security is orthogonal and
  imported as a hypothesis on `DEM.correct`.

### 3.2 Project-category privacy for the index

The repository index — the map from commit hashes to project IDs —
is itself disclosure-sensitive on a multi-project host (the fact that
"this account pushes to both project A and project B" is often
what an attacker wants). Store index entries as orbit elements under
a host-wide `G_H` whose orbits partition project IDs. A host
operator holds `G_H` and can route (canonicalize to identify
project); observers see no partition structure. This is `USE_CASES.md`
§1.4 (confidential asset tags) re-cast as "confidential project
tags".

### 3.3 Branch and release disclosure via batch reveal

A release branch is held as a sequence of commits encrypted under a
release-specific subgroup `G_R ≤ G_P`. During development, the
branch is readable only by maintainers holding `G_R`. At release
time, `G_R` is published on-chain (or via a timelock VDF composed
with a threshold share — the composability noted in `USE_CASES.md`
§1.2). Every commit in the branch then canonicalizes atomically; the
branch becomes public in a single event. This is
**coordinated-disclosure-ready by construction**, without requiring
a separate CVE embargo infrastructure.

* **Why orbit-based wins.** Hash commit-reveal requires per-commit
  openings transmitted at reveal time; a branch-sized release would
  need a transmitted opening per commit. Orbit reveal is a single
  subgroup reveal; the branch opens atomically.
* **Formalization handles:** `canon_idem`, `canon_eq_implies_orbit_eq`,
  Theorem 6.

### 3.4 Build and CI artifact binding

Build artifacts (compiled binaries, package archives) are `AEAD`-
encrypted under a per-build key derived from the build's commit-set
KEM. The build manifest records the list of commit canonical forms
that went into the build; a verifier holding `G_P` can recompute the
canonical forms of the commits and cross-check. An attacker who
substitutes a binary without access to `G_P` cannot forge a
canonicalization match — this is the `INT_CTXT` property (Theorem 12)
applied to the supply chain.

### 3.5 Dependency-graph privacy

Each dependency edge (`my-lib` depends on `their-crypto`) is a
potential disclosure: it reveals what a project *uses*, which
narrows an attacker's search. Encode the SBOM as a per-edge orbit
element under a project-wide `G_P`; the resolver (which holds `G_P`)
canonicalizes to recover the dependency graph. Observers see only
opaque edge ciphertexts. This is application of `USE_CASES.md` §4.1
(orbit-follow graphs) to the dependency graph rather than the social
graph.

Caveat: if the dependency is a public package on a public registry,
the registry can observe *download* patterns from the resolver and
reconstruct the graph from access logs. Dependency-graph privacy is
real only end-to-end; the registry side must also be orbit-aware, or
the resolution step must be batched/padded.

---

## 4. Review, bounty, and disclosure workflows

### 4.1 Sealed bug bounty submissions

The classic front-running problem: a submitter discloses a severity
class ("this is a remote-code-execution") while the patch is still in
flight, and an adversary who reads the bug tracker races to exploit
the still-live version.

**Construction.** The bounty board's triage group `G_T` has orbits
keyed to severity / category pairs — `(severity, subsystem)` for
instance. A submitter encodes their submission as a message `m =
(severity, subsystem, PoC_pointer)` and posts `c = g • reps m`. The
triager (who holds `G_T`) canonicalizes to recover the severity /
subsystem routing label; the PoC itself is hybrid-encrypted under a
submitter-chosen KEM to a triager public key (classical PQ KEM — not
orbit-based, because the submitter doesn't hold `G_T`).

Observers see only orbit elements of uniformly distributed appearance
(`ConcreteOIA(ε)`-bounded), so a public mirror of the bounty board
reveals *volume* (how many submissions in a window) but not *severity
distribution*. Economic incentives to front-run high-severity
disclosures collapse.

* **Formalization handles:** Theorem 6 for severity-label hiding,
  Theorem 12 for the PoC KEM's integrity, `invariant_const_on_orbit`
  for the triage-time routing function.
* **Honest caveat.** Public non-separating invariants (e.g. the
  Hamming weight of `c` on bitstring HGOE) remain observable; the
  submission encoding must be designed so severity is *not* a public
  invariant. This is the `same_weight_not_separating` discipline
  from `Construction/HGOE.lean` applied to the bounty encoding.

### 4.2 Coordinated multi-project vulnerability disclosure

A vulnerability affects multiple downstream projects. Each affected
project files an encrypted advisory under a coordination-authority
group `G_D`. During the embargo, advisories are opaque orbit
elements on the public tracker. At embargo lift, `G_D` is released
(threshold-share, timelock, or CA signature); every advisory
canonicalizes atomically, no one project publishes ahead of the
others, and no observer pre-embargo can tell which projects even
*have* advisories filed.

This is the §3.3 batch-reveal pattern re-cast for security
disclosure. Compared to today's practice (manual embargo list, email
chains, CVE-reservation dance), the cryptographic primitive enforces
simultaneity by construction.

### 4.3 Encrypted code review comments

A reviewer's comments on a pull request can themselves be
disclosure-sensitive ("this crypto is totally broken"). Each comment
rides hybrid encryption: `c_comment = AEAD_{k}(text)` where `k` is
derived from the PR's KEM session. Only the PR participants
(author and assigned reviewers, who all hold derived access bundles
from `G_P`) can decrypt. Observers see comment counts and timing
but no content.

**Encrypted approvals.** A review approval is a signed message under
the reviewer's pseudonym; the signature is verifiable against the
pseudonym's registered signing key. Review pseudonym-unlinkability
across PRs follows from bundle-mediated rotation (§2.1).

### 4.4 Quadratic or conviction-weighted bounty voting

Who decides which bounties to fund? The same glass-ballot voting from
`USE_CASES.md` §2.1 applies, with each token-weighted voter casting a
sealed orbit ballot. At close, the funding group `G_V` is revealed
and the tallies become public. For a contributor-run bounty DAO this
collapses "vote privately, tally publicly" into one key-reveal.

### 4.5 Reputation without deanonymization

A contributor's reputation score is a function of their canonical
pseudonym, not their real identity. The platform computes reputation
internally (it holds `G_C`) and publishes a *reputation ciphertext*:
`c_R = g_R • reps(score_bucket)` under a reputation-display group
`G_R`. Viewers holding `G_R` (e.g. project maintainers checking
applicants) canonicalize to see the bucket; uncredentialed observers
see nothing. This avoids the "reputation is a deanonymization
oracle" trap that plain scoreboards fall into.

Caveat: *granularity leaks rank*. If the reputation bucket is too
fine-grained (e.g. exact integer score), then reps form a
near-injective map from score to canonical class, and an adversary
who compromises any one `G_R` viewer can rank everybody. Use a
coarse bucketing (categorical tiers) and rotate `G_R` on a schedule.

---

## 5. LLM integration patterns

Orbcrypt is **not** homomorphic. An LLM — whether it does
code-completion, review, triage, or summarization — must ingest
plaintext prompts and emit plaintext completions. The honest design
problem is: *which parties see the plaintext, and what does orbit
structure add beyond what a plain TLS + KMS setup gives?*

Five patterns are useful; each explicitly states its trust
assumption.

### 5.1 TEE-hosted LLM with orbit-gated access

The LLM runs inside a remote-attested TEE (SGX, TDX, SEV-SNP, Nitro
Enclave, or equivalent). The TEE holds `G_P` (or a derived
per-session group), provisioned via a remote-attested key-release.
Prompts and completions transit the orbit KEM between user and TEE;
outside the TEE, all traffic is orbit-elements + DEM ciphertext.

* **What orbit adds over plain TEE.** The *metadata* of which project
  or which severity class a prompt belongs to is hidden from the TEE
  operator's billing / routing substrate — because routing happens
  after canonicalization inside the TEE, not at the edge. Compare:
  with plain TLS + TEE, the TEE operator sees routing headers before
  attestation decrypts the payload.
* **Trust assumption.** TEE attestation is a trust anchor. Orbcrypt
  does not weaken this — if the TEE is broken, the prompts leak.
* **Formalization handle.** Theorem 4 (KEM correctness), Theorem 13
  (hybrid correctness). The attestation layer is outside the Lean
  model.

### 5.2 Prompt category sealing without TEE

Not every operation needs an LLM. A developer-submitted "query" may
be a tooling request ("run tests", "build") or a help request
("explain this file"). The *category* of the query can be concealed
from the router even when the content is not. Encode the query type
as an orbit label under a platform group `G_Q`; the router
canonicalizes to dispatch to the appropriate backend (LLM, CI, or
static-analysis service) but sees no content differentiator beyond
the class. This is `USE_CASES.md` §1.4 applied to job routing.

* **Trust assumption.** The chosen backend service holds the
  plaintext under its own plain-TLS session. Orbit structure hides
  *which* backend a request is destined for from observers and from
  the front-door router's logs.

### 5.3 Canonical-form prompt caches

LLM providers deduplicate identical prompts in their cache for
efficiency. Under orbit-sealed prompts, the cache key is `canon(c)`
rather than `c`: two semantically equivalent prompts (under the
chosen `G`) hit the same cache row. For a style-neutralizing `G`
(e.g. whitespace and identifier-renaming equivalences), this
collapses the "my prompt vs. your prompt" privacy gap while
preserving cache-hit rate.

* **Caveat.** If `G` is chosen so that inequivalent prompts
  canonicalize to the same form (collisions), the cache returns
  wrong answers. `reps_distinct` in `OrbitEncScheme` is exactly the
  no-collision requirement; extending it from the finite message
  space `M` to a free-form prompt space is parameter selection, not
  a property the Lean layer guarantees.

### 5.4 LLM watermarking as an orbit invariant

An LLM provider can bias its sampler so that outputs lie in a
particular orbit under a watermark group `G_W`. Users who know `G_W`
can canonicalize an output and check the class to detect
provider-origin. Pirates who strip overt watermarks but do not know
`G_W` cannot efficiently decide class membership — this is OIA
applied to an output-watermarking setting.

* **Trust assumption.** The LLM sampler is cooperative. This is a
  provider-side attestation problem, not a cryptographic one.
* **Open.** Whether a practical biased sampler preserves generation
  quality is an ML engineering problem, not an Orbcrypt one.

### 5.5 Agent-to-agent private messaging via CSIDH session keys

Multi-agent tooling — planner, coder, reviewer, scorekeeper — often
involves agents operated by different trust principals. Pair-wise
CSIDH-style key agreement (`PublicKey/CommutativeAction.lean`,
Theorem 17) gives each agent-pair a shared session key without a
central KDC. Orbit-element session keys double as access tokens for
cached intermediate state.

* **Gated on:** a concrete `CommGroupAction` instantiation. This is
  the `PUBLIC_KEY_ANALYSIS.md` §3 open problem. Until it lands,
  agent-pair session keys must come from a classical PQ KEM
  (Kyber/ML-KEM) and Orbcrypt handles only the orbit-labelling part.

---

## 6. Cryptocurrency integration

### 6.1 Escrowed bounty release via threshold-`G`

A bounty poster locks a reward in an escrow contract. The contract
holds a threshold share of `G_B` — the bounty-specific group. When
the submission is verified, the contract's participants sign a
release transaction; on quorum, `G_B` is reconstructed on-chain and
the submission's canonical form becomes publicly computable. The
reward is released to the canonical-form-matching pseudonym.

* **Why orbit-based wins over a plain smart-contract escrow.** The
  escrow's *existence* and *payout class* are visible in plain
  Solidity. With orbit-sealed escrow, observers see only that a
  vault exists; the category / severity of the bounty is
  indistinguishable across escrows. This matters for preventing
  targeted attacks on high-value bounty categories.
* **Formalization handles:** Theorem 6, Theorem 4, plus a threshold-
  sharing primitive on `G_B` — an open work unit (`USE_CASES.md`
  §6 bullet 2).

### 6.2 Streaming subscriptions via bundle-paced access tokens

A subscription to a private repository is a signed `OrbitalRandomizers
G_P t` bundle with an on-chain payment schedule. Each period, the
subscriber's wallet streams the period's fee; in return, the project
contract signs the next epoch's bundle refresh via
`refreshRandomizers`. If the payment lapses, the refresh is denied
and the subscriber exhausts their current bundle.

* **Why this is cleaner than a token-gated ACL.** The subscriber's
  accesses within a period are unlinkable (one bundle element per
  access), and the server-side check is a single `canon` call, not
  a signature verification plus a membership lookup.
* **Formalization handle:** `refresh_independent` (Phase 13), plus
  `seed_kem_correctness` for the wallet-derived KEM.

### 6.3 Pay-per-LLM-call with sealed query metering

Each LLM call is billed per token. A naïve metering scheme reveals
"which user made which call at which time"; a metered-but-private
scheme conceals this from the billing substrate while still letting
the provider reconcile with the wallet.

The call's billing metadata — `(user_pseudonym, token_count,
model_class)` — is encoded as a message `m` under a metering group
`G_M`. The call itself transits §5.1's TEE. Periodically, the
provider's billing contract batch-reveals `G_M` and the pseudonyms
settle on-chain; between reveals, observers see only sealed metering
entries. This is the §1.2 batch-commitment pattern re-cast for
metered API usage.

### 6.4 Anti-Sybil staking bound to seed keys

A pseudonym is accepted by the platform only if its wallet has
staked a minimum amount. The wallet's HD path deterministically
derives the `G_C` seed (Theorem 9). Slashing an abusive pseudonym
burns the stake and removes the canonical form from the membership
set; the contributor must restake from a fresh wallet to regain
access. The canonical-form-set membership check is a single
`canon_eq_implies_orbit_eq` equation at the platform side.

### 6.5 On-chain dispute resolution over sealed artifacts

Disputes (bounty payment contested, license violation claim, etc.)
reference sealed artifacts. A resolver appointed by the DAO is
issued a scoped delegation of `G_P` (or a subgroup) for the duration
of the dispute; they canonicalize the relevant artefacts, render a
judgement, and the delegation expires by the end of the refresh
epoch (`refresh_independent` structural bound). Orbit-level
capability scoping matches the natural legal scoping: the resolver
sees only what the dispute requires, not the whole repo.

---

## 7. Three concrete architectures

### Architecture A — Encrypted Forge

A git-hosting service (GitHub / GitLab analogue) where projects are
orbit-keyed and storage is opaque to the host.

* **Identity:** pseudonyms via §2.1 bundles, wallet-derived seeds.
* **Code:** §3.1 hybrid encryption for commits, §3.2 index tags for
  project routing, §3.3 batch-reveal for release branches.
* **Review:** §4.3 encrypted comments, §4.4 bounty voting if the
  project funds via bounties.
* **LLM:** §5.1 TEE-hosted Copilot analogue; §5.2 router sealing for
  non-LLM actions.
* **Payments:** §6.2 streaming subscriptions, §6.4 anti-Sybil
  staking.
* **Best for:** small-to-medium teams wanting a private
  collaboration forge with post-quantum data-at-rest guarantees.
* **Weakest link:** the TEE attestation chain for §5.1; network-
  metadata leakage outside the orbit layer.

### Architecture B — Anonymous Bounty Board

A cross-project vulnerability / feature bounty marketplace with
severity-class privacy and coordinated disclosure.

* **Identity:** §2.1 for both submitters and triagers; §2.2 cross-
  project unlinkability is critical.
* **Submissions:** §4.1 sealed bug bounty, §3.1 hybrid-encrypted PoC
  artefacts.
* **Disclosure:** §4.2 coordinated multi-project release; the
  coordination authority is a threshold-held `G_D`.
* **Payments:** §6.1 escrowed bounty release, §6.5 sealed-artefact
  dispute resolution.
* **LLM:** §5.2 category-sealed prompt routing for LLM-assisted
  triage; §5.4 watermarking of LLM-generated PoCs (policy control).
* **Best for:** an open bounty platform where front-running
  disclosure is the primary threat.
* **Weakest link:** submitter anonymity at network layer; invariant
  hygiene on the triage encoding (§4.1 caveat).

### Architecture C — Coordinated-Disclosure Consortium

A consortium of projects (e.g. OSS package maintainers) pre-sharing
a vulnerability-coordination infrastructure.

* **Identity:** §2.1, issued by the consortium rather than a single
  project.
* **Advisories:** §4.2 multi-project disclosure is the core flow.
* **Escrow:** §6.1 funds a per-CVE pool that pays researchers,
  maintainers, and reviewers.
* **LLM:** §5.1 TEE-hosted AI triage shared across the consortium;
  §5.5 CSIDH agent messaging for inter-agent coordination (gated on
  the open §3 instantiation problem).
* **Best for:** a successor-organization to projects like the
  distros mailing list, with cryptographic enforcement of the
  embargo window.
* **Weakest link:** threshold-sharing `G_D` across many consortium
  members requires the threshold-`G` primitive that is not yet
  formalized.

---

## 8. Anonymity stack — what sits above and below Orbcrypt

Orbcrypt is one layer of a stack. For a dev platform, the realistic
stack is:

| Layer | Purpose | Primitive(s) |
|-------|---------|--------------|
| Network | Hide IP, timing, traffic patterns | Tor / I2P / Nym / Loopix mixnet |
| Session | Establish forward-secret pairwise keys | Classical PQ KEM (ML-KEM) + Noise; CSIDH-style (§5.5) when instantiated |
| Authorship | Bind actions to a pseudonym; pseudonym-unlinkability across actions | Orbcrypt bundles (§2.1) + PQ signatures (SPHINCS+/ML-DSA) |
| Content | Confidentiality of artefact payloads | AEAD hybrid (Orbcrypt KEM + ChaCha20-Poly1305 DEM; Theorem 13) |
| Category | Hide which project / severity / role an action concerns | Orbcrypt orbit structure on the KEM (§§3.2, 4.1) |
| Disclosure | Batch-reveal many commitments atomically | Orbcrypt batch reveal (§§3.3, 4.2); threshold-`G` (open work) |
| Payment | Bind identity and stake to on-chain collateral | Wallet HD seed → Orbcrypt seed key (§6.4, Theorem 9) |

The explicit division of labour makes the "what breaks if X is
broken?" analysis tractable.

* Tor/mixnet compromise: network-level correlation attacks regain
  traction; category privacy still holds.
* PQ signature break: authorship forgery becomes possible; orbit
  unlinkability holds, but the platform-level trust model collapses
  separately.
* Orbcrypt / OIA break: category privacy collapses; content
  confidentiality (of the DEM payload) still holds if the DEM key
  escapes the KEM via secure seed derivation (§2.3).
* DEM break (e.g. ChaCha20-Poly1305): artefact content leaks;
  category privacy holds; authorship holds.
* TEE break: §5.1's plaintext prompts leak; all other
  decryption-at-rest properties hold.

No single layer's failure is catastrophic across the whole stack;
that is the design goal.

---

## 9. Threat model

Four adversary classes, in increasing capability:

1. **Passive network observer.** Sees encrypted traffic + wall-clock
   timing. Orbit + network-layer anonymity together defeat this;
   Orbcrypt alone defeats the *content* but not the *metadata*.
2. **Compromised read-only mirror.** Sees the encrypted repo state
   at rest. OIA-bounded; no project, no pseudonym, no category
   leakage up to public non-separating invariants.
3. **Compromised front-door router.** Sees request headers and can
   correlate across users. Orbit-sealed routing (§5.2) mitigates
   category leakage; network-layer mixnet mitigates timing.
4. **Compromised maintainer key.** Holds `G_P` for one project. All
   §§3.1, 3.3, 4.3 guarantees for that project collapse; other
   projects' `G_{P'}` remain independent. Rotation via subgroup
   rotation (§2.4) re-establishes privacy for future actions but
   does not retroactively seal past actions. No cryptographic layer
   recovers from this kind of compromise; the mitigation is
   capability-scoping and prompt revocation.

A fifth adversary class, **a CRQC (quantum)**, is the reason the
platform chose Orbcrypt in the first place. All orbit-layer
guarantees reduce to TI / GI / CE hardness (Theorems 1, 6, 14); the
PQ signature and DEM choices are assumed also PQ-hard.

---

## 10. Open problems specific to this domain

1. **Threshold-sharing `G`.** Required for §§3.3, 4.2, 6.1, and the
   consortium architecture. Shamir over a permutation
   representation is the natural approach; no Lean development yet.
2. **Concrete `CommGroupAction`.** Required for §5.5 CSIDH agent
   messaging and §6 cross-hop privacy. Open per
   `PUBLIC_KEY_ANALYSIS.md` §3.
3. **Invariant-hygiene linter.** A static check that every
   ciphertext operation on the server factors through `canon`, not
   through any other function of the ciphertext. Without it, §§4.1
   and 4.5 are a design-review trap.
4. **Canonicalization cost.** Current GAP benchmarks give
   `canon ≈ 320 ms` at λ=128 (`docs/USE_CASES.md` §1.1). A request-
   routing path that runs `canon` on every inbound request is
   impractical at platform scale; either view-tag pre-filtering
   (borrowed from CryptoNote) or parameter reduction (Phase 14) is
   needed before §§3.2, 5.2 deploy at scale.
5. **Stylometric linkage.** Orbit unlinkability does not defeat
   stylometric linkage of the plaintext. This is not an Orbcrypt
   problem to solve, but deployments must document the limitation.
6. **Seed-key backup without deanonymization.** Standard crypto-
   wallet recovery (§6.4) exposes the recovery path to the wallet
   vendor. A disclosure-aware recovery scheme (Shamir over the seed
   with a custom share distribution) is a specific open work unit.

---

## 11. Recommended incremental path

An implementation team that wants to stand up a real version of
Architecture A or B should proceed in this order, each step
gated on Lean-formalized theorems:

1. **Deploy hybrid at-rest storage (§§3.1, 3.4).** Theorems 12, 13.
   Independent of every open problem. This is the single biggest
   practical win from Orbcrypt in a dev-platform setting.
2. **Deploy wallet-derived pseudonyms (§§2.1, 2.3, 6.4).** Theorem 9
   plus classical PQ signing. `refresh_independent` bounds bundle
   rotation semantics.
3. **Deploy category-sealed routing (§3.2, §5.2).** Theorems 4, 6.
   Requires invariant-hygiene discipline in routing code; defer
   until a linter exists.
4. **Deploy batch-reveal release and disclosure (§§3.3, 4.2).**
   Needs threshold-`G`; that is the open-problem dependency.
5. **Deploy agent CSIDH session keys (§5.5) and escrow (§6.1).**
   Both depend on open problems; sequence them last.

The key operational discipline throughout is: **every server-side
function of a ciphertext must factor through `canon`, every
contributor-side rotation must go through a bundle, and every
plaintext that touches an LLM must be inside a TEE or inside the
contributor's own browser**. When any one of those disciplines is
broken, a subsequent design review should catch it; until the
invariant-hygiene linter exists, reviewers are the linter.

---

## 12. Summary

The designs above do not invent new Orbcrypt primitives; they
re-apply the three families from `docs/USE_CASES.md` §5
(commit-batch-open, bundle-mediated rotation, canonicalize-as-query)
to the dev-platform domain. The novelty is the stack layering:
network-anonymity + PQ signatures + AEAD hybrid + orbit-structured
KEM + wallet-bound seed keys, with LLM operations constrained to
TEE-hosted plaintext zones. Orbcrypt's earn-its-keep claim in this
setting is concrete: **it hides which project a contributor works
on, which severity class a submission is in, which reviewer has
access to what, and when a coordinated release opens — all under a
GI / TI hardness assumption that survives a CRQC**.

The five unresolved Phase-13+ questions (threshold-`G`, concrete
`CommGroupAction`, invariant-hygiene linter, canonicalization cost,
disclosure-aware seed backup) are the concrete next-step work units
for any deployment team, and each maps cleanly to either the
`PRACTICAL_IMPROVEMENTS_PLAN.md` backlog or the `PHASE_14+` planning
documents.
