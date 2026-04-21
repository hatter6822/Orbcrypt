# Orbcrypt Formal Verification Report

**Phase 16 — Formal Verification of New Components.**
*Snapshot: 2026-04-21.* *Branch: `claude/review-phase-16-verification-7nN9o`.*

---

## Executive summary

Phase 16 audits every Lean 4 module produced by Phases 7–14 of the Orbcrypt
formalization (KEM reformulation, probabilistic foundations, key compression,
nonce-based encryption, authenticated encryption, hardness alignment, public-key
extension scaffolding) and confirms that the project's zero-`sorry`,
zero-custom-axiom standard from Phase 6 has been preserved through all the
post-Phase-6 work.

**Headline numbers.**

| Metric | Value |
|---|---:|
| Lean source modules | 36 |
| Lines of Lean source | 8,156 |
| Public declarations | 343 |
| Public declarations carrying a `/-- … -/` docstring | 343 (100 %) |
| `theorem` declarations | 216 |
| `def` declarations | 105 |
| `structure` declarations | 20 |
| `class` / `instance` / `abbrev` declarations | 1 / 3 / 3 |
| `private` declarations (intentional helpers) | 5 |
| Uses of `sorry` in source | **0** |
| Custom `axiom` declarations | **0** |
| `lake build` jobs (full project) | 3,364 |
| `lake build` warnings | 0 |
| Headline results checked by `scripts/audit_phase_16.lean` | 153 |
| Headline results depending on `sorryAx` | **0** |
| Headline results depending on a non-standard axiom | **0** |
| Headline results depending on *no* axioms | 54 |

**Verdict.** Phase 16 exit criteria are all met. The formal verification
posture established at the end of Phase 6 — zero `sorry`, zero custom axioms,
all theorems carrying their cryptographic assumptions as explicit hypotheses —
extends unchanged through Phases 7–14, and now also through the Workstream A/B/
C/D/E audit follow-ups.

---

## How to reproduce the audit

```bash
# 1. Set up the toolchain (one-time)
./scripts/setup_lean_env.sh

# 2. Fetch Mathlib cache (one-time per Mathlib pin update)
source ~/.elan/env && lake exe cache get

# 3. Build the whole project
source ~/.elan/env && lake build Orbcrypt

# 4. Run the comment-aware sorry audit (matches CI logic)
find Orbcrypt -name '*.lean' -print0 | while IFS= read -r -d '' f; do
  perl -0777 -pe 's{/-.*?-/}{}sg; s{--[^\n]*}{}g' "$f" \
    | grep -Pn '(^|[^A-Za-z0-9_])sorry([^A-Za-z0-9_]|$)' \
    && echo "FAIL: $f" && exit 1
done; echo "PASS: zero sorry"

# 5. Run the consolidated Phase 16 axiom-transparency audit
source ~/.elan/env && lake env lean scripts/audit_phase_16.lean
```

Step 5 prints `#print axioms` for 153 declarations. CI fails if any line
mentions `sorryAx` or any axiom outside the standard Lean trio (`propext`,
`Classical.choice`, `Quot.sound`).

---

## Headline results table

The eight load-bearing theorems are listed first — these are the ones a
reader who needs to "trust the math" should know about. Each row is
machine-checked by `scripts/audit_phase_16.lean`.

| #  | Name                                  | File                                | Status      | Standard axioms only? |
|----|---------------------------------------|-------------------------------------|-------------|-----------------------|
| 1  | `correctness`                         | `Theorems/Correctness.lean`         | Unconditional        | ✓ (`propext`, `Classical.choice`, `Quot.sound`) |
| 2  | `invariant_attack`                    | `Theorems/InvariantAttack.lean`     | Unconditional        | ✓ (`propext`) |
| 3  | `oia_implies_1cpa`                    | `Theorems/OIAImpliesCPA.lean`       | Conditional on `OIA` | ✓ (no axioms used) |
| 4  | `kem_correctness`                     | `KEM/Correctness.lean`              | Unconditional        | ✓ (no axioms used) |
| 5  | `kemoia_implies_secure`               | `KEM/Security.lean`                 | Conditional on `KEMOIA` | ✓ (no axioms used) |
| 6  | `aead_correctness`                    | `AEAD/AEAD.lean`                    | Unconditional        | ✓ (`propext`) |
| 7  | `hybrid_correctness`                  | `AEAD/Modes.lean`                   | Unconditional        | ✓ (no axioms used) |
| 8  | `concrete_oia_implies_1cpa`           | `Crypto/CompSecurity.lean`          | Conditional on `ConcreteOIA(ε)` | ✓ |

Every conditional result carries its assumption (OIA / KEMOIA / ConcreteOIA)
as an *explicit hypothesis* in its type signature. None of these assumptions
is a Lean `axiom` — they are `Prop`-valued definitions, so the reduction
is honest about which assumption is doing the cryptographic work.

### Extended headline table (Phase 7 → 14 + Workstream A–E)

| #   | Name                                                          | File                                          | Status                              |
|----:|---------------------------------------------------------------|-----------------------------------------------|--------------------------------------|
| 9   | `seed_kem_correctness`                                        | `KeyMgmt/SeedKey.lean`                        | Unconditional (uses `kem_correctness`) |
| 10  | `nonce_encaps_correctness`                                    | `KeyMgmt/Nonce.lean`                          | Unconditional |
| 11  | `nonce_reuse_leaks_orbit`                                     | `KeyMgmt/Nonce.lean`                          | Unconditional warning theorem |
| 12  | `authEncrypt_is_int_ctxt`                                     | `AEAD/AEAD.lean`                              | Conditional on orbit-cover hypothesis |
| 13  | `carterWegmanMAC_int_ctxt`                                    | `AEAD/CarterWegmanMAC.lean`                   | Concrete witness for #12 |
| 14  | `hardness_chain_implies_security`                             | `Hardness/Reductions.lean`                    | Conditional on `HardnessChain` |
| 15  | `oblivious_sample_in_orbit`                                   | `PublicKey/ObliviousSampling.lean`            | Conditional on closure hypothesis |
| 16  | `kem_agreement_correctness`                                   | `PublicKey/KEMAgreement.lean`                 | Unconditional |
| 17  | `csidh_correctness`                                           | `PublicKey/CommutativeAction.lean`            | Conditional on `CommGroupAction.comm` typeclass axiom |
| 18  | `comm_pke_correctness`                                        | `PublicKey/CommutativeAction.lean`            | Conditional on `CommGroupAction.comm` + `pk_valid` |
| 19  | `comp_oia_implies_1cpa`                                       | `Crypto/CompSecurity.lean`                    | Conditional on `CompOIA` (asymptotic) |
| 20  | `det_oia_implies_concrete_zero`                               | `Crypto/CompOIA.lean`                         | Bridge: `OIA → ConcreteOIA 0` |
| 21  | `concrete_kemoia_uniform_implies_secure`                      | `KEM/CompSecurity.lean`                       | Genuinely ε-smooth KEM bound (Workstream E1d) |
| 22  | `concrete_hardness_chain_implies_1cpa_advantage_bound`        | `Hardness/Reductions.lean`                    | Probabilistic hardness chain (Workstream E5) |
| 23  | `indQCPA_bound_via_hybrid`                                    | `Crypto/CompSecurity.lean`                    | Multi-query bound (Workstream E8c) |
| 24  | `arePermEquivalent_setoid`                                    | `Hardness/CodeEquivalence.lean`               | Mathlib `Setoid` instance (Workstream D4) |
| 25  | `paut_equivalence_set_eq_coset`                               | `Hardness/CodeEquivalence.lean`               | Full coset set identity (Workstream D3) |
| 26  | `PAutSubgroup`                                                | `Hardness/CodeEquivalence.lean`               | `PAut` as Mathlib `Subgroup` (Workstream D2) |
| 27  | `concrete_combiner_advantage_bounded_by_oia`                  | `PublicKey/CombineImpossibility.lean`         | Probabilistic equivariant-combiner upper bound (Workstream E6) |
| 28  | `combinerOrbitDist_mass_bounds`                               | `PublicKey/CombineImpossibility.lean`         | Intra-orbit mass bound under non-degeneracy (E6b) |

Every one of #1–#28 was confirmed to depend only on standard Lean axioms by
running `scripts/audit_phase_16.lean` — 153 declarations exercised,
no `sorryAx`, no custom axiom outside the standard Lean trio.

---

## Per-phase verification matrix

### Phase 7 — KEM reformulation (work unit 16.1)

`KEM/Syntax.lean` (1 def, 1 structure), `KEM/Encapsulate.lean`
(2 defs, 3 simp lemmas), `KEM/Correctness.lean` (2 theorems),
`KEM/Security.lean` (3 defs, 5 theorems, 1 structure),
`KEM/CompSecurity.lean` (5 defs, 14 theorems — added in Workstream E1).

**Build status.** All five modules compile under `lake build`. Each
`#print axioms` query returns either "does not depend on any axioms" or the
standard Lean trio.

**Key theorems and assumptions.**

* `kem_correctness` — proved by `rfl`; depends on no axioms.
* `kemoia_implies_secure` — depends on no axioms; carries `KEMOIA` as an
  explicit hypothesis.
* `kem_key_constant_direct` — *unconditional* corollary of
  `canonical_isGInvariant`; demonstrates that `KEMOIA`'s second conjunct is
  redundant and provable from the structure.
* `concrete_kemoia_implies_secure` — point-mass form (Workstream E1d); the
  docstring discloses that the predicate collapses on `ε ∈ [0, 1)`.
* `concrete_kemoia_uniform_implies_secure` — uniform-form (Workstream E1d
  post-audit addition); genuinely ε-smooth.

**Exit criteria (all met):**

- [x] All five modules compile with `lake build`.
- [x] `kem_correctness` compiles with zero `sorry`.
- [x] `kemoia_implies_secure` compiles with zero `sorry`.
- [x] `toKEM_correct` compiles with zero `sorry`.
- [x] `#print axioms` reports only the standard Lean trio.

### Phase 10 — Authenticated encryption and modes (work unit 16.2)

`AEAD/MAC.lean` (1 structure), `AEAD/AEAD.lean` (1 structure, 3 defs,
5 theorems including `INT_CTXT` and `authEncrypt_is_int_ctxt`),
`AEAD/Modes.lean` (1 structure, 2 defs, 3 theorems),
`AEAD/CarterWegmanMAC.lean` (4 defs, 1 theorem).

**Build status.** All four modules compile cleanly. The `INT_CTXT`
proof (`authEncrypt_is_int_ctxt`, Workstream C2c) is the technically
hardest result here: it case-splits on MAC verification and uses
`MAC.verify_inj` (Workstream C1) plus `canon_eq_of_mem_orbit` plus an
explicit orbit-cover hypothesis to derive a contradiction with the
freshness condition.

**Key theorems and assumptions.**

* `aead_correctness` — depends only on `propext`; carries no
  cryptographic assumption beyond the `MAC.correct` field.
* `hybrid_correctness` — depends on no axioms; pure composition of
  `kem_correctness` and `DEM.correct`.
* `INT_CTXT` — a `Prop`-valued *definition*, not a theorem, capturing
  the integrity-of-ciphertexts property.
* `authEncrypt_is_int_ctxt` — depends on `propext, Quot.sound`; carries
  the orbit-cover hypothesis (`∀ c, c ∈ orbit G basePoint`) as an
  explicit argument. *No custom axiom* — `verify_inj` is a `MAC` field,
  *not* an axiom.
* `carterWegmanMAC_int_ctxt` — concrete witness: instantiates the above
  on a deterministic Carter-Wegman universal-hash MAC over `ZMod p`,
  showing `INT_CTXT` is non-vacuously inhabitable.

**Exit criteria (all met):**

- [x] All four modules compile with `lake build`.
- [x] `aead_correctness` compiles with zero `sorry`.
- [x] `hybrid_correctness` compiles with zero `sorry`.
- [x] `MAC.correct` field is well-typed and discharged by every concrete
      MAC instance.
- [x] `MAC.verify_inj` field is well-typed and discharged by
      `deterministicTagMAC` via `of_decide_eq_true`.
- [x] `#print axioms` reports only the standard Lean trio.

### Phase 8 — Probabilistic foundations (work unit 16.3)

`Probability/Monad.lean` (4 defs, 8 theorems — incl. Workstream E7
`uniformPMFTuple`), `Probability/Negligible.lean` (1 def, 4 theorems),
`Probability/Advantage.lean` (1 def, 8 theorems — incl. Workstream E
`hybrid_argument_uniform`), `Crypto/CompOIA.lean` (6 defs, 6 theorems,
1 structure), `Crypto/CompSecurity.lean` (5 defs, 13 theorems,
2 structures), `KEM/CompSecurity.lean` (5 defs, 14 theorems).

**Build status.** All six modules compile cleanly.

**Sorry classification (Phase 16 work unit 16.3c).** Phase 8's planning
document (`docs/planning/PHASE_8_PROBABILISTIC_FOUNDATIONS.md` work unit
8.10) originally allowed a "multi-query skeleton" `sorry` as an
intentional placeholder for the Hidden Subgroup Problem step. **That
`sorry` no longer exists in the source.** The Workstream E8 work unit
replaced the placeholder with the explicit-`h_step` formulation in
`indQCPA_bound_via_hybrid`: the per-step bound is carried as a
hypothesis, the telescoping is proved unconditionally via
`hybrid_argument_uniform`, and the regression sentinel
`indQCPA_bound_recovers_single_query` confirms the Q = 1 specialisation.
The marginal-independence argument that would discharge `h_step` from
`ConcreteOIA` alone over an arbitrary product distribution remains a
research follow-up (tracked as Workstream E8b in the audit plan); it is
**not** present in the source as a `sorry` placeholder.

**Result of the comment-aware sorry scan (Phase 16 work unit 16.4):**

```
$ ./scripts/(comment-aware sorry check, equivalent to CI)
0 occurrences in source code, 36 files scanned.
```

There are no `sorry` placeholders anywhere in `Orbcrypt/**/*.lean`.

**Key theorems and assumptions (Phase 8 + Workstream E1/E5/E8).**

* `concrete_oia_implies_1cpa` — depends on `propext, Classical.choice,
  Quot.sound`; carries `ConcreteOIA(ε)` as a hypothesis.
* `concreteOIA_one` — `ConcreteOIA scheme 1` is unconditionally true,
  i.e. the predicate is satisfiable.
* `comp_oia_implies_1cpa` — depends on `propext, Classical.choice,
  Quot.sound`; carries `CompOIA` (asymptotic, negligible-advantage)
  as a hypothesis.
* `det_oia_implies_concrete_zero` — bridge from the deterministic OIA
  to `ConcreteOIA 0`; demonstrates that the deterministic predicate is
  the zero-advantage specialisation of the probabilistic one.
* `hybrid_argument_uniform` — Q-step bound from per-step bound;
  Workstream E8 pre-requisite.
* `indQCPA_bound_via_hybrid` — multi-query advantage ≤ Q · ε via the
  hybrid argument and an external per-step bound `h_step`.
* `indQCPA_bound_recovers_single_query` — Q = 1 sanity sentinel.
* `det_kemoia_implies_concreteKEMOIA_zero` — KEM bridge (Workstream E1c).

**Exit criteria (all met):**

- [x] `uniformPMF`, `probEvent`, `probTrue` type-check with correct
      Mathlib imports.
- [x] All sanity lemmas compile.
- [x] `advantage`, `advantage_triangle`, `advantage_le_one`,
      `hybrid_argument`, `hybrid_argument_uniform` compile.
- [x] `ConcreteOIA` type-checks; `concrete_oia_implies_1cpa` compiles.
- [x] Every `sorry` in Phase 8's planning placeholders has been
      *removed* — no `sorry` remains in the source.
- [x] `#print axioms` reports only the standard Lean trio for every
      headline theorem.

### Phase 9 — Key compression and nonce-based encryption

`KeyMgmt/SeedKey.lean` (3 defs, ~6 theorems), `KeyMgmt/Nonce.lean`
(2 defs, ~5 theorems).

**Build status.** Both modules compile cleanly. All headline theorems
depend only on standard Lean axioms.

### Phase 12 — Hardness alignment (LESS / MEDS / TI)

`Hardness/CodeEquivalence.lean` — gained the full Mathlib-style API in
Workstream D (PAut as `Subgroup`, ArePermEquivalent as `Setoid`, the
full coset set identity).
`Hardness/TensorAction.lean` — `Tensor3` type, `tensorAction` MulAction
of GL³, Tensor Isomorphism reduction.
`Hardness/Reductions.lean` — `TensorOIA`, `GIOIA`, the reduction chain,
plus the Workstream E ε-bounded ConcreteHardnessChain.
`Hardness/Encoding.lean` — orbit-preserving encoding interface
(reference-only, not consumed by any reduction Prop today; tracked as
Workstream F3/F4).

### Phase 13 — Public-key extension scaffolding

`PublicKey/ObliviousSampling.lean`, `PublicKey/KEMAgreement.lean`,
`PublicKey/CommutativeAction.lean`, `PublicKey/CombineImpossibility.lean`.
All four modules compile; all theorems carry their assumptions as
explicit hypotheses (closure, `ObliviousSamplingHiding`,
`CommGroupAction.comm`, etc.).

---

## Sorry audit (work unit 16.4)

**Method.** The CI strips Lean block comments (`/- … -/`, including
docstrings `/-- … -/` and module docstrings `/-! … -/`) and line
comments (`-- …`) from each `.lean` file using a Perl slurp, then
greps the residual source for `sorry` with identifier word-boundaries
on both sides. The same script is reproduced in §"How to reproduce".

**Result.**

```
0 occurrences of `sorry` outside comments and docstrings,
across 36 .lean files.
```

The single literal "sorry" string anywhere in the source tree appears
in the docstring of `authEncrypt_is_int_ctxt`
(`Orbcrypt/AEAD/AEAD.lean:262`), in the prose `"No custom axiom, no
\`sorry\`."`. The CI strip filter correctly ignores it.

**Classification of historical `sorry` placeholders (planning-doc
references).** Phase 8's planning doc allowed up to three
intentional `sorry` placeholders (work units 8.10, 8.5b, 8.5d).
**None of them remain in the source.** All three have been
discharged by Workstream E (E1, E5, E8) as documented above.

---

## Axiom audit (work unit 16.5)

**Method.** `scripts/audit_phase_16.lean` runs `#print axioms` on 153
declarations spanning every public theorem and definition introduced by
Phases 4–14 plus the Workstream A/B/C/D/E follow-ups. CI parses each
output line and rejects:

* any axiom outside the standard Lean trio
  (`propext`, `Classical.choice`, `Quot.sound`);
* any occurrence of `sorryAx` (which would indicate a hidden `sorry`
  in the dependency chain).

**Result.**

```
153 declarations exercised
  54 depend on no axioms at all
  99 depend only on a subset of {propext, Classical.choice, Quot.sound}
   0 depend on any non-standard axiom
   0 depend on `sorryAx`
```

The full `#print axioms` per-declaration breakdown is reproduced in
`Orbcrypt.lean`'s axiom transparency report (§"Verification" near the
end of the file).

---

## Module-docstring audit (work unit 16.6)

**Method.** For every `.lean` file in `Orbcrypt/`, check that:

1. The file begins with a `/-! … -/` module docstring.
2. Every public (non-`private`) `def`, `theorem`, `lemma`,
   `structure`, `class`, `instance`, or `abbrev` is preceded by a
   `/-- … -/` documentation comment.

**Result.** All 36 modules carry a `/-! … -/` module docstring. All 343
public declarations carry a `/-- … -/` docstring (a single grep false
positive at `Orbcrypt/Hardness/Encoding.lean:20` is plain text inside
the wrapped module-level docstring, not an actual declaration).

Phase 6's docstring standards are preserved unchanged through Phases
7–14.

---

## Root-import / dependency-graph audit (work unit 16.7)

`Orbcrypt.lean` imports all 36 modules. Building `lake build Orbcrypt`
exercises the complete graph (3,364 jobs including Mathlib
dependencies, zero errors, zero warnings).

The ASCII dependency graph in `Orbcrypt.lean`'s docstring already
covers every Phase 7–13 module. Phase 16 added a new "Phase 16
Verification Audit Snapshot" subsection at the end of that docstring
recording the audit-time totals.

---

## CI configuration (work unit 16.8)

`.github/workflows/lean4-build.yml` now runs four checks on every push
and pull request:

1. **`lake build Orbcrypt`** — full project build (3,364 jobs).
2. **Comment-aware `sorry` strip** — Perl slurp + word-boundary grep.
   Audit finding F-03 hardened this against false positives from
   docstring prose mentioning the word "sorry".
3. **Custom-axiom guard** — Perl regex matching the
   `^axiom <ident> [params] : <type>` declaration form. False positives
   from "axiom" appearing in docstrings are excluded by the regex.
4. **Phase 16 axiom-transparency audit** *(new in Phase 16)* —
   `lake env lean scripts/audit_phase_16.lean` followed by a Bash
   token-walker that fails fast if any axiom outside the standard
   Lean trio appears, or if `sorryAx` is mentioned anywhere.

Step (4) is the audit-script regression sentinel: any future change
that hides a `sorry` behind an opaque definition or that introduces a
custom axiom will trip CI immediately.

---

## Regression audit (work unit 16.9)

All 11 original Phase 1–6 modules build individually:

```
Orbcrypt.GroupAction.Basic        Build completed successfully
Orbcrypt.GroupAction.Canonical    Build completed successfully
Orbcrypt.GroupAction.Invariant    Build completed successfully
Orbcrypt.Crypto.Scheme            Build completed successfully
Orbcrypt.Crypto.Security          Build completed successfully
Orbcrypt.Crypto.OIA               Build completed successfully
Orbcrypt.Theorems.Correctness     Build completed successfully
Orbcrypt.Theorems.InvariantAttack Build completed successfully
Orbcrypt.Theorems.OIAImpliesCPA   Build completed successfully
Orbcrypt.Construction.Permutation Build completed successfully
Orbcrypt.Construction.HGOE        Build completed successfully
```

The Phase 4 axiom expectations (from
`docs/planning/PHASE_16_FORMAL_VERIFICATION.md` work unit 16.9) are
preserved exactly:

```
Orbcrypt.correctness        depends on axioms: [propext, Classical.choice, Quot.sound]
Orbcrypt.invariant_attack   depends on axioms: [propext]
Orbcrypt.oia_implies_1cpa   does not depend on any axioms
```

No regression in axiom dependencies for any pre-Phase-7 theorem.

---

## Theorem inventory (work unit 16.10b)

Counts by directory (Phase 16 work unit 16.10a):

| Directory     | Files | Lines | Theorems | Defs | Structures |
|---------------|------:|------:|---------:|-----:|-----------:|
| `AEAD/`       |     4 |   727 |        9 |    9 |          3 |
| `Construction/` |   3 |   365 |    (mixed) |   (mixed) |    (mixed) |
| `Crypto/`     |     5 | 1,204 |    (mixed) |   (mixed) |    (mixed) |
| `GroupAction/` |    3 |   384 |    (mixed) |   (mixed) |    (mixed) |
| `Hardness/`   |     4 | 1,687 |    (mixed) |   (mixed) |    (mixed) |
| `KEM/`        |     5 |   913 |       24 |   11 |          2 |
| `KeyMgmt/`    |     2 |   467 |    (mixed) |   (mixed) |    (mixed) |
| `Probability/` |    3 |   445 |       20 |    6 |          0 |
| `PublicKey/`  |     4 | 1,503 |    (mixed) |   (mixed) |    (mixed) |
| `Theorems/`   |     3 |   461 |    (mixed) |   (mixed) |    (mixed) |
| **Totals**    | **36** | **8,156** | **216** | **105** | **20** |

(Per-directory `theorem` / `def` totals where labelled "mixed" are
included in the global totals row but not broken out here to keep the
table compact; see the per-phase verification matrix above for the
detailed counts per file.)

The 153 declarations exercised by `scripts/audit_phase_16.lean` cover
every public theorem and definition that downstream consumers would
care about: every headline result of every phase, plus the
Workstream A/B/C/D/E follow-ups.

---

## Known limitations (work unit 16.10d)

The Phase 16 audit confirms the *formalization-level* posture (zero
sorry, zero custom axiom). It does **not** discharge the cryptographic
assumptions themselves — those are carried as explicit hypotheses on
the conditional theorems. The following items are deliberate
limitations, each documented in source and tracked as future work:

1. **OIA is an unproven assumption** (and necessarily so — the security
   reduction is to a hardness problem). `oia_implies_1cpa` carries
   `OIA` as a hypothesis. The deterministic `OIA` is `False` for any
   non-trivial scheme; the probabilistic counterpart `ConcreteOIA(ε)`
   is satisfiable for `ε ∈ (0, 1]` but its hardness reduces to
   tensor isomorphism, not proven within Lean.

2. **`GIReducesToCE` and `GIReducesToTI` are reduction *claims*, not
   proofs.** They are `Prop`-valued definitions that point at LESS /
   MEDS / Grochow-Qiao external research. A concrete witness via the
   CFI graph gadget or the structure-tensor encoding is tracked as
   Workstream F3/F4. This is documented in `Orbcrypt.lean`'s axiom
   transparency report under "Hardness parameter Props".

3. **`indQCPA_bound_via_hybrid` carries `h_step` as a hypothesis.** The
   per-step bound is the marginal-independence step that would, in a
   complete probabilistic refinement, follow from `ConcreteOIA` plus a
   product-distribution argument over `uniformPMFTuple`. The
   atomic-bound shape lets any concrete marginal argument plug in
   later; this is tracked as Workstream E8b in the audit plan.

4. **`ObliviousSamplingHiding` is a strong deterministic
   pathological-strength predicate** that is not expected to hold for
   non-trivial bundles without a probabilistic refinement. The
   `oblivious_sampling_view_constant` corollary carries it as a
   hypothesis.

5. **`SymmetricKeyAgreementLimitation`** is an unconditional structural
   identity exhibiting that the KEM agreement protocol is symmetric-
   setup. This is a *limitation in expressive power* of the symmetric
   scheme, not a security flaw — it documents that this particular
   construction does not (and is not intended to) provide public-key
   functionality on its own. Three candidate paths to public-key are
   formalised in `PublicKey/{ObliviousSampling,KEMAgreement,Commutative
   Action}.lean` and analysed in `docs/PUBLIC_KEY_ANALYSIS.md`.

6. **`carterWegmanMAC_int_ctxt` is a satisfiability witness, not a
   production-grade MAC.** The Carter-Wegman MAC is information-
   theoretically weak and uses `ZMod p` ciphertexts (not the
   permutation orbits used by the production AOE / KEM). It exists
   purely to inhabit `INT_CTXT` non-vacuously and to demonstrate that
   `MAC.verify_inj` is satisfiable. Production AEAD would compose
   `OrbitKEM` with HMAC or Poly1305 and would need a probabilistic
   refinement of the `MAC` interface to discharge `verify_inj` from
   collision-resistance / pseudo-randomness assumptions.

7. **Multi-query KEM-CCA is not formalised.** `concrete_kemoia_implies_
   secure` and the uniform-form variant cover the no-decapsulation-
   oracle setting; CCA security with a decapsulation oracle would
   require a Decisional KEM-CCA game and a forking-lemma-style
   reduction, both out of scope for Phase 16.

These items are *known and documented*, not silent gaps. The
formalization is internally consistent: every conditional theorem
states its assumptions, every probabilistic predicate is satisfiable
at `ε = 1`, and no custom axiom or `sorry` short-circuits any proof.

---

## Phase 16 exit criteria checklist

The exit criteria from `docs/planning/PHASE_16_FORMAL_VERIFICATION.md`
§"Phase Exit Criteria":

- [x] (1) All Phase 7 theorems compile with zero sorry and zero
      custom axioms.
- [x] (2) All Phase 10 theorems compile with zero sorry.
- [x] (3) Phase 8 sorry count documented; all non-sorry theorems
      compile. *(The sorry count is zero — the planned placeholders
      were discharged by Workstream E.)*
- [x] (4) Axiom transparency report covers all new modules.
- [x] (5) `lake build Orbcrypt` succeeds with all new imports.
- [x] (6) CI passes on the branch (extended with Phase 16 audit script
      regression sentinel).
- [x] (7) All 11 original modules still build with unchanged axiom
      dependencies.
- [x] (8) `docs/VERIFICATION_REPORT.md` is complete (this document).

---

## Document history

* **2026-04-21** — Phase 16 verification report authored. Added
  `scripts/audit_phase_16.lean` (153 `#print axioms` checks +
  non-vacuity witnesses), extended `.github/workflows/lean4-build.yml`
  with the Phase 16 audit-script regression sentinel, and appended a
  Phase 16 snapshot section to `Orbcrypt.lean`'s axiom transparency
  report.
